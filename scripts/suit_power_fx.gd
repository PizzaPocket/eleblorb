class_name SuitPowerFX
extends RefCounted

## Shared presentation factory for any actor that wears a Blorb suit. Input,
## AI and allegiance remain actor concerns; the emitted water/fire language is
## identical for players, enemies and future non-playable suit wearers.


static func make_water_stream(parent: Node, stream_name: String) -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = stream_name
	stream.amount = 180
	stream.lifetime = 0.42
	stream.randomness = 0.12
	stream.visibility_aabb = AABB(Vector3(-0.6, -0.6, -7.0), Vector3(1.2, 1.2, 7.4))
	var texture := ParticleFX.build_soft_gradient_texture(24, 2.2)
	var material := ParticleFX.build_billboard_material(texture, Color.WHITE, false, 0.35)
	material.vertex_color_use_as_albedo = true
	var droplet := QuadMesh.new()
	droplet.size = Vector2(0.16, 0.16)
	droplet.material = material
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 1.0
	process.gravity = Vector3(0.0, -1.2, 0.0)
	process.initial_velocity_min = 13.5
	process.initial_velocity_max = 16.5
	process.scale_min = 0.85
	process.scale_max = 1.3
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(0.85, 0.95, 1.0, 0.95)},
		{"offset": 0.35, "color": TownProps.WATER_COLOR},
		{"offset": 1.0, "color": Color(TownProps.WATER_COLOR.r, TownProps.WATER_COLOR.g, TownProps.WATER_COLOR.b, 0.0)},
	])
	stream.process_material = process
	stream.draw_pass_1 = droplet
	stream.emitting = false
	stream.top_level = true
	parent.add_child(stream)
	return stream


static func make_fire_stream(parent: Node, stream_name: String) -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = stream_name
	stream.amount = 260
	stream.lifetime = 0.34
	stream.randomness = 0.35
	stream.visibility_aabb = AABB(Vector3(-1.5, -1.5, -7.0), Vector3(3.0, 3.0, 7.4))
	var texture := ParticleFX.build_soft_gradient_texture(24, 1.7, 0.2)
	var material := ParticleFX.build_billboard_material(texture, Color.WHITE, true, 0.0)
	material.vertex_color_use_as_albedo = true
	var flame := QuadMesh.new()
	flame.size = Vector2(0.22, 0.5)
	flame.material = material
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 6.0
	process.gravity = Vector3(0.0, -1.4, 0.0)
	process.initial_velocity_min = 9.0
	process.initial_velocity_max = 14.0
	process.scale_min = 0.5
	process.scale_max = 1.05
	process.particle_flag_align_y = true
	process.angle_min = -12.0
	process.angle_max = 12.0
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(1.0, 0.95, 0.75, 1.0)},
		{"offset": 0.25, "color": Color(1.0, 0.55, 0.1, 1.0)},
		{"offset": 0.6, "color": Color(0.85, 0.25, 0.05, 0.9)},
		{"offset": 1.0, "color": Color(0.35, 0.06, 0.02, 0.0)},
	])
	process.scale_curve = ParticleFX.build_scale_curve(0.6, 1.15, 0.3, 0.7)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.0
	process.turbulence_noise_scale = 2.0
	process.turbulence_influence_min = 0.04
	process.turbulence_influence_max = 0.15
	stream.process_material = process
	stream.draw_pass_1 = flame
	stream.emitting = false
	stream.local_coords = true
	stream.top_level = true
	parent.add_child(stream)
	return stream


static func point_stream(stream: GPUParticles3D, emitter: Node3D, direction: Vector3, active: bool, roll_reference: Vector3 = Vector3.FORWARD) -> void:
	if stream == null or emitter == null:
		return
	stream.emitting = active
	if not active:
		return
	var aim: Vector3 = direction.normalized() if direction.length_squared() > 0.001 else Vector3.DOWN
	stream.global_position = emitter.global_position
	var up_reference := Vector3.UP
	if absf(aim.dot(up_reference)) > 0.98:
		up_reference = roll_reference.normalized() if roll_reference.length_squared() > 0.001 else Vector3.FORWARD
	stream.look_at(stream.global_position + aim, up_reference)
