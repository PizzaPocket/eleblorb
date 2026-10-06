extends Node3D

## Sparse pioneer vegetation on the Fire Kingdom's oldest cooled lava. One
## MultiMesh draws all grass colonies and another draws the occasional petals;
## the kingdom therefore gains ecological texture without adding hundreds of
## independently processed scene nodes.

const FIELD_HALF_SIZE := 720.0
const COLONY_ATTEMPTS := 520
const GRASS_COLORS: Array[Color] = [
	Color(0.30, 0.43, 0.17),
	Color(0.42, 0.52, 0.20),
	Color(0.55, 0.57, 0.23),
	Color(0.25, 0.36, 0.15),
]
const FLOWER_COLORS: Array[Color] = [
	Color(0.96, 0.70, 0.19),
	Color(0.93, 0.37, 0.29),
	Color(0.79, 0.53, 0.86),
	Color(0.95, 0.86, 0.48),
]

var _terrain: Node
var _rng := RandomNumberGenerator.new()
var _patch_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()


func _ready() -> void:
	_terrain = get_parent().get_node_or_null("Terrain")
	if _terrain == null:
		return
	_rng.seed = 20261005
	_patch_noise.seed = 20261005
	_patch_noise.frequency = 0.0048
	_patch_noise.fractal_octaves = 3
	_detail_noise.seed = 20261006
	_detail_noise.frequency = 0.028
	_detail_noise.fractal_octaves = 2
	call_deferred("_build_regrowth")


func _build_regrowth() -> void:
	var grass_transforms: Array[Transform3D] = []
	var grass_colors: Array[Color] = []
	var flower_transforms: Array[Transform3D] = []
	var flower_colors: Array[Color] = []

	for _attempt in COLONY_ATTEMPTS:
		var center := Vector2(
			_rng.randf_range(-FIELD_HALF_SIZE, FIELD_HALF_SIZE),
			_rng.randf_range(-FIELD_HALF_SIZE, FIELD_HALF_SIZE)
		)
		var suitability := _site_suitability(center)
		var patch_value := _noise_unit(_patch_noise, center)
		if suitability <= 0.0 or patch_value < 0.38:
			continue

		var colony_radius := _rng.randf_range(4.5, 16.0) * lerpf(0.75, 1.25, patch_value)
		var tuft_count := _rng.randi_range(9, 24)
		for _tuft in tuft_count:
			var angle := _rng.randf_range(0.0, TAU)
			var distance := pow(_rng.randf(), 0.72) * colony_radius
			var point := center + Vector2(cos(angle), sin(angle)) * distance
			var point_suitability := _site_suitability(point)
			var local_density := 0.58 + _noise_unit(_detail_noise, point) * 0.42
			if point_suitability <= 0.0 or _rng.randf() > point_suitability * local_density:
				continue
			var normal: Vector3 = _terrain.get_mesh_normal(point.x, point.y)
			var scale := _rng.randf_range(1.5, 2.7)
			var basis := _surface_basis(normal, _rng.randf_range(0.0, TAU))
			basis = basis.scaled_local(Vector3(scale, scale, scale))
			var ground_y: float = _terrain.get_mesh_height(point.x, point.y)
			grass_transforms.append(Transform3D(basis, Vector3(point.x, ground_y, point.y) + normal * 0.018))
			var base_color := GRASS_COLORS[_rng.randi() % GRASS_COLORS.size()]
			grass_colors.append(base_color.lerp(Color(0.70, 0.58, 0.25), _rng.randf_range(0.0, 0.14)))

		# Flowers are accents inside established grass mats, never an even second
		# scatter laid over the whole map.
		if _rng.randf() < 0.4:
			for flower_index in _rng.randi_range(2, 6):
				var flower_angle := _rng.randf_range(0.0, TAU)
				var flower_distance := sqrt(_rng.randf()) * colony_radius * 0.8
				var flower_point := center + Vector2(cos(flower_angle), sin(flower_angle)) * flower_distance
				if _site_suitability(flower_point) <= 0.0:
					continue
				var flower_normal: Vector3 = _terrain.get_mesh_normal(flower_point.x, flower_point.y)
				var flower_basis := _surface_basis(flower_normal, _rng.randf_range(0.0, TAU))
				# Own-frame scale: a world-axis scale of a turned basis shears the petal.
				flower_basis = flower_basis.scaled_local(Vector3(0.2, 0.03, 0.14) * _rng.randf_range(0.82, 1.24))
				var flower_y: float = _terrain.get_mesh_height(flower_point.x, flower_point.y)
				flower_transforms.append(Transform3D(flower_basis, Vector3(flower_point.x, flower_y, flower_point.y) + flower_normal * 0.024))
				flower_colors.append(FLOWER_COLORS[(flower_index + _attempt) % FLOWER_COLORS.size()])

	_add_multimesh("CooledLavaGrass", _build_grass_tuft_mesh(), grass_transforms, grass_colors)
	_add_multimesh("CooledLavaFlowers", _build_petal_mesh(), flower_transforms, flower_colors)


func _site_suitability(point: Vector2) -> float:
	if not _terrain.has_method("get_regrowth_suitability"):
		return 0.0
	return float(_terrain.get_regrowth_suitability(point))


func _noise_unit(noise: FastNoiseLite, point: Vector2) -> float:
	return noise.get_noise_2d(point.x, point.y) * 0.5 + 0.5


func _surface_basis(normal: Vector3, yaw: float) -> Basis:
	var up := normal.normalized()
	var x_axis := Vector3.RIGHT.slide(up).normalized()
	if x_axis.length_squared() < 0.001:
		x_axis = Vector3.FORWARD.slide(up).normalized()
	var z_axis := x_axis.cross(up).normalized()
	return Basis(x_axis, up, z_axis).rotated(up, yaw)


func _add_multimesh(
	label: String,
	shared_mesh: Mesh,
	transforms: Array[Transform3D],
	colors: Array[Color]
) -> void:
	if transforms.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = shared_mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
		multimesh.set_instance_color(index, colors[index])
	var instance := MultiMeshInstance3D.new()
	instance.name = label
	instance.multimesh = multimesh
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = 520.0
	instance.visibility_range_end_margin = 70.0
	add_child(instance)
	CollisionPolicy.mark_decorative(instance)


func _build_grass_tuft_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_blade(surface, Vector3(-0.12, 0.0, 0.02), 0.36, 0.11, -0.55)
	_add_blade(surface, Vector3(0.09, 0.0, -0.06), 0.48, 0.095, 0.48)
	_add_blade(surface, Vector3(0.02, 0.0, 0.10), 0.29, 0.12, 1.55)
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.96
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	return surface.commit()


func _add_blade(surface: SurfaceTool, center: Vector3, height: float, width: float, yaw: float) -> void:
	var side := Vector3(cos(yaw), 0.0, sin(yaw)) * width * 0.5
	var lean := Vector3(-sin(yaw), 0.0, cos(yaw)) * height * 0.13
	var left := center - side
	var right := center + side
	var shoulder_left := center + Vector3.UP * height * 0.72 - side * 0.62 + lean * 0.5
	var shoulder_right := center + Vector3.UP * height * 0.72 + side * 0.62 + lean * 0.5
	var tip := center + Vector3.UP * height + lean
	for vertex in [left, shoulder_left, right, right, shoulder_left, shoulder_right, shoulder_left, tip, shoulder_right]:
		surface.add_vertex(vertex)


func _build_petal_mesh() -> SphereMesh:
	var petal := SphereMesh.new()
	petal.radius = 0.5
	petal.height = 1.0
	petal.radial_segments = 8
	petal.rings = 4
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.88
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	petal.material = material
	return petal
