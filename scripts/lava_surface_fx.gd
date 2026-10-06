class_name LavaSurfaceFX
extends Node3D

## Shared living-surface presentation for every exposed body of lava. Lava
## geometry chooses valid points inside its own outline; this component owns
## the universal swell, pop and hot-vapour jet cycle at those points.

const BUBBLE_START_RADIUS := 0.05
const BUBBLE_PEAK_RANGE := Vector2(0.35, 2.0)
const BUBBLE_SPRAY_THRESHOLD := 1.15

var _rng := RandomNumberGenerator.new()
var _vents: Array[Dictionary] = []


static func attach(parent: Node, surface_points: Array, seed_value: int) -> LavaSurfaceFX:
	var effects := LavaSurfaceFX.new()
	effects.name = "LavaSurfaceFX"
	effects._rng.seed = seed_value
	parent.add_child(effects)
	effects._build_vents(surface_points)
	return effects


func _process(delta: float) -> void:
	for vent in _vents:
		var timer: float = float(vent["timer"]) - delta
		vent["timer"] = timer
		var total: float = float(vent["total"])
		var bubble := vent["bubble"] as MeshInstance3D
		var peak: float = float(vent["peak"])
		var progress := smoothstep(0.0, 1.0, clampf(1.0 - timer / total, 0.0, 1.0))
		bubble.scale = Vector3.ONE * lerpf(BUBBLE_START_RADIUS, peak, progress)
		if timer <= 0.0:
			bubble.scale = Vector3.ZERO
			if peak >= BUBBLE_SPRAY_THRESHOLD:
				var jet := vent["jet"] as GPUParticles3D
				jet.restart()
				jet.emitting = true
			var next_cycle := _rng.randf_range(2.4, 8.5)
			vent["timer"] = next_cycle
			vent["total"] = next_cycle
			vent["peak"] = _rng.randf_range(BUBBLE_PEAK_RANGE.x, BUBBLE_PEAK_RANGE.y)


func _build_vents(surface_points: Array) -> void:
	for value in surface_points:
		if not value is Vector3:
			continue
		var point := value as Vector3
		var jet := _build_hot_vapour_jet()
		jet.position = point
		add_child(jet)
		var bubble := _build_bubble()
		bubble.position = point
		add_child(bubble)
		var cycle := _rng.randf_range(0.8, 6.0)
		_vents.append({
			"jet": jet,
			"bubble": bubble,
			"timer": cycle,
			"total": cycle,
			"peak": _rng.randf_range(BUBBLE_PEAK_RANGE.x, BUBBLE_PEAK_RANGE.y),
		})


func _build_bubble() -> MeshInstance3D:
	var bubble := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	sphere.radial_segments = 12
	sphere.rings = 8
	bubble.mesh = sphere
	bubble.material_override = NatureProps.build_lava_material()
	bubble.scale = Vector3.ZERO
	return bubble


func _build_hot_vapour_jet() -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = 90
	particles.lifetime = 0.62
	particles.one_shot = true
	particles.explosiveness = 0.76
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.UP
	process.spread = 18.0
	process.initial_velocity_min = 6.0
	process.initial_velocity_max = 12.0
	process.gravity = Vector3(0.0, 1.5, 0.0)
	process.scale_min = 0.7
	process.scale_max = 1.5
	process.particle_flag_align_y = true
	process.angle_min = -12.0
	process.angle_max = 12.0
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.0
	process.turbulence_noise_scale = 2.0
	process.turbulence_influence_min = 0.04
	process.turbulence_influence_max = 0.15
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(1.0, 0.95, 0.75, 1.0)},
		{"offset": 0.25, "color": Color(1.0, 0.55, 0.1, 1.0)},
		{"offset": 0.6, "color": Color(0.85, 0.25, 0.05, 0.9)},
		{"offset": 1.0, "color": Color(0.35, 0.06, 0.02, 0.0)},
	])
	process.scale_curve = ParticleFX.build_scale_curve(0.2, 1.15, 0.3, 0.12)
	particles.process_material = process
	var material := ParticleFX.build_billboard_material(
		ParticleFX.build_soft_gradient_texture(32, 1.7, 0.2), Color.WHITE, true, 0.0
	)
	material.vertex_color_use_as_albedo = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.8, 1.7)
	quad.material = material
	particles.draw_pass_1 = quad
	particles.visibility_aabb = AABB(Vector3(-12, 0, -12), Vector3(24, 18, 24))
	return particles
