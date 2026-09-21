class_name SuitPowerFX
extends RefCounted

## Shared presentation factory for any actor that wears a Blorb suit. Input,
## AI and allegiance remain actor concerns; the emitted water/fire language is
## identical for players, enemies and future non-playable suit wearers.
##
## The recipes below were tuned once, against repeated direct reports about
## how they read on screen, and then existed twice: the player kept the tuned
## versions with the reasoning attached and everybody else got a stripped copy
## of the same numbers. They live here now, comments and all, so a stream
## looks the same whoever is throwing it.

## How fast and how long a water hose throws.
const WATER_STREAM_SPEED := 15.0
const WATER_STREAM_LIFETIME := 0.42
## Soft particle texture/ramp tuning -- see particle_fx.gd's own class doc
## comment for the general technique both streams use.
const WATER_PARTICLE_SOFTNESS := 2.2
const FIRE_PARTICLE_SOFTNESS := 1.7
## Lower than it might otherwise be -- with angle_min/max a narrow range
## instead of a full 0-360 spin (see make_fire_stream()'s own comment on
## particle_flag_align_y), each particle's own rotation varies far less, so a
## strong wobble would read as the same asymmetric shape repeating lick to
## lick rather than organic variety.
const FIRE_PARTICLE_WOBBLE := 0.2


static func make_water_stream(parent: Node, stream_name: String) -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = stream_name
	stream.amount = 180
	stream.lifetime = WATER_STREAM_LIFETIME
	stream.randomness = 0.12
	stream.visibility_aabb = AABB(Vector3(-0.6, -0.6, -7.0), Vector3(1.2, 1.2, 7.4))
	# A soft, alpha-blended billboard instead of a solid-colored SphereMesh
	# -- per direct report, the old sphere read as a hard uniform ball
	# regardless of color, not water.
	var texture := ParticleFX.build_soft_gradient_texture(24, WATER_PARTICLE_SOFTNESS)
	var water_material := ParticleFX.build_billboard_material(texture, Color.WHITE, false, 0.35)
	water_material.vertex_color_use_as_albedo = true
	var droplet := QuadMesh.new()
	droplet.size = Vector2(0.16, 0.16)
	droplet.material = water_material
	var process := ParticleProcessMaterial.new()
	# point_stream() below aims local -Z down the character's +Z forward axis.
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 1.0
	# A hose stays almost parallel but has a slight weighty downward arc.
	process.gravity = Vector3(0.0, -1.2, 0.0)
	process.initial_velocity_min = WATER_STREAM_SPEED * 0.9
	process.initial_velocity_max = WATER_STREAM_SPEED * 1.1
	# Water leaves a moving nozzle carrying the nozzle's own speed, so a
	# running hose's stream keeps pace instead of being outrun. A stream
	# simulated in the emitter's own space must not (see
	# set_inherits_velocity()), or the nozzle's motion is counted twice.
	process.inherit_velocity_ratio = 1.0
	process.scale_min = 0.85
	process.scale_max = 1.3
	# A bright near-white highlight right at the nozzle, settling into the
	# same rich blue every fountain/water blorb already uses, fading to
	# transparent as each droplet reaches the end of its short life -- a
	# flat single color (the earlier approach) read as one uniform, opaque
	# ball; this reads as an actual spray of individual droplets catching
	# the light.
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
	# A dense short-lived, broad cone reads as a continuous flamethrower,
	# unlike the long evenly-spaced droplets used by the water hose.
	stream.amount = 260
	stream.lifetime = 0.34
	stream.randomness = 0.35
	stream.visibility_aabb = AABB(Vector3(-1.5, -1.5, -7.0), Vector3(3.0, 3.0, 7.4))
	# Soft, additively-blended billboards instead of a solid-colored
	# SphereMesh -- per direct report ("look like orange bubbles"). See
	# particle_fx.gd's own class doc comment: overlapping additive
	# particles build up glowing brightness the way real flame does,
	# rather than each one just occluding what's behind it like a solid
	# object would.
	var texture := ParticleFX.build_soft_gradient_texture(24, FIRE_PARTICLE_SOFTNESS, FIRE_PARTICLE_WOBBLE)
	var flame_material := ParticleFX.build_billboard_material(texture, Color.WHITE, true, 0.0)
	flame_material.vertex_color_use_as_albedo = true
	# Elongated (taller than wide), not square -- paired with
	# particle_flag_align_y below, this reads as a streak pointed along
	# each particle's own direction of travel rather than a round puff, so
	# the whole spray reads as a directional jet again. Per direct
	# correction: the earlier square, freely-spinning (angle_min/max 0-360)
	# blob looked like fire, but no longer like it was going anywhere in
	# particular.
	var flame := QuadMesh.new()
	flame.size = Vector2(0.22, 0.5)
	flame.material = flame_material
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 6.0
	process.gravity = Vector3(0.0, -1.4, 0.0)
	process.initial_velocity_min = 9.0
	process.initial_velocity_max = 14.0
	process.scale_min = 0.5
	process.scale_max = 1.05
	# Aligns each particle's own local Y (the quad's long axis, see
	# flame.size above) to its own velocity direction while still
	# billboarding around that axis to face the camera -- Godot's own
	# standard technique for a directional streak (rain, sparks, jets),
	# rather than a billboard that only ever reads as a flat round puff
	# regardless of how fast or which way it's actually moving.
	process.particle_flag_align_y = true
	# A small range, not a full random spin -- enough per-particle variety
	# that the reused wobble texture (see build_soft_gradient_texture()'s
	# own comment) doesn't look identical lick to lick, without undoing the
	# velocity alignment just set above.
	process.angle_min = -12.0
	process.angle_max = 12.0
	# A real flame cools as it travels outward: bright pale heat at the
	# nozzle, through orange, settling into the same deep red-orange every
	# fire blorb/Fire Gem already uses, fading to transparent as it dies.
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(1.0, 0.95, 0.75, 1.0)},
		{"offset": 0.25, "color": Color(1.0, 0.55, 0.1, 1.0)},
		{"offset": 0.6, "color": Color(0.85, 0.25, 0.05, 0.9)},
		{"offset": 1.0, "color": Color(0.35, 0.06, 0.02, 0.0)},
	])
	# Visibly forms just past the nozzle, then dissipates -- not a fixed
	# size the whole time.
	process.scale_curve = ParticleFX.build_scale_curve(0.6, 1.15, 0.3, 0.7)
	# Organic flicker, but modest -- per direct correction, the original
	# turbulence strength scattered particles enough sideways motion that
	# the spray stopped reading as a coherent jet at all. Kept low enough
	# now to still flicker without visibly dispersing the cone.
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


## A world-space stream inherits its nozzle's velocity; one simulated in the
## emitter's own space must not, or the nozzle's motion is counted twice.
static func set_inherits_velocity(stream: GPUParticles3D, inherits: bool) -> void:
	var process := stream.process_material as ParticleProcessMaterial if stream != null else null
	if process != null:
		process.inherit_velocity_ratio = 1.0 if inherits else 0.0


## How far and how fast an aimed stream drifts off its nominal direction, so
## a held jet reads as a live thing rather than a rigid cone.
const AIM_WOBBLE_ANGLE := deg_to_rad(2.5)
const AIM_WOBBLE_SPEED := 3.2


## Points a particle stream out of `emitter` along `direction`, emitting only
## while `active`. `roll_reference` supplies a stable second axis for a jet
## aimed straight down, where world up is singular.
static func point_stream(
	stream: GPUParticles3D, emitter: Node3D, direction: Vector3, active: bool,
	roll_reference: Vector3 = Vector3.FORWARD
) -> void:
	if stream == null or emitter == null:
		return
	stream.emitting = active
	if not active:
		return
	stream.global_position = emitter.global_position
	stream.look_at(
		stream.global_position + _aimed(stream.get_instance_id(), direction),
		_up_reference(direction, roll_reference)
	)


## The same aiming for a lightning bolt. GDScript has no structural typing, so
## a Node3D-derived LightningBolt cannot be passed to the GPUParticles3D-typed
## function above; the aiming itself is shared below rather than written twice.
static func point_bolt(
	bolt: LightningBolt, emitter: Node3D, direction: Vector3, active: bool,
	roll_reference: Vector3 = Vector3.FORWARD
) -> void:
	if bolt == null or emitter == null:
		return
	bolt.emitting = active
	if not active:
		return
	bolt.global_position = emitter.global_position
	bolt.look_at(
		bolt.global_position + _aimed(bolt.get_instance_id(), direction),
		_up_reference(direction, roll_reference)
	)


## Looking exactly down with world up as the secondary axis is singular, so a
## vertical jet takes its roll from the body's own forward instead.
static func _up_reference(direction: Vector3, roll_reference: Vector3) -> Vector3:
	var aim := direction.normalized() if direction.length_squared() > 0.001 else Vector3.DOWN
	if absf(aim.dot(Vector3.UP)) <= 0.98:
		return Vector3.UP
	return roll_reference.normalized() if roll_reference.length_squared() > 0.001 else Vector3.FORWARD


## The direction with this frame's wobble applied, phased off the emitter's
## own instance id so two hands or two feet do not wobble in an obviously
## mirrored, synced way.
static func _aimed(instance_id: int, direction: Vector3) -> Vector3:
	var aim := direction.normalized() if direction.length_squared() > 0.001 else Vector3.DOWN
	var phase := float(instance_id % 1000) * 0.01
	var t := Time.get_ticks_msec() * 0.001 * AIM_WOBBLE_SPEED + phase
	var wobble := (
		Basis(Vector3.UP, sin(t) * AIM_WOBBLE_ANGLE)
		* Basis(Vector3.RIGHT, cos(t * 1.3) * AIM_WOBBLE_ANGLE)
	)
	return wobble * aim
