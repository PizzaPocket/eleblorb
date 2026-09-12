extends StaticBody3D

## One continuous ocean bathymetry: tropical island peaks rise naturally
## through a shallow shelf while the same terrain falls into deep water at
## the perimeter. Camera-local environment switching supplies inexpensive,
## mobile-friendly underwater depth cues.

# Extend slightly beyond the 900-unit gameplay wrap so the rendered floor
# and water fully cover every reachable camera view at the map boundary.
const HALF_SIZE := 930.0
# Visual-only ocean continues far beyond the 900 m wrap. Keeping this
# separate from HALF_SIZE avoids quadrupling the detailed terrain mesh and
# its collision merely to hide the horizon boundary from the camera.
const VISUAL_HALF_SIZE := 3200.0
const OUTER_FLOOR_Y := -111.0
const GRID_STEPS := 180
const WATER_LEVEL := 0.0
const WATER_COLOR := Color(0.11, 0.48, 0.58, 0.76)
const DEEP_FLOOR_COLOR := Color(0.055, 0.17, 0.20)
const SHALLOW_FLOOR_COLOR := Color(0.22, 0.43, 0.39)
const BEACH_COLOR := Color(0.77, 0.67, 0.43)
const GRASS_COLOR := Color(0.11, 0.58, 0.34)
const UNDERWATER_BACKGROUND := Color(0.13, 0.42, 0.48)
const UNDERWATER_FOG := Color(0.20, 0.58, 0.61)
const OCEAN_WATER_SHADER: Shader = preload("res://scripts/ocean_water.gdshader")

# Shared with ocean_kingdom_city.gd's CITY_CENTER. The castle, both home
# rings, paths, and outer kelp gardens fit inside the hard-flat radius; a
# broad transition then rejoins the natural seabed without a shelf wall.
const SEA_FOLK_VILLAGE_CENTER := Vector2(0.0, -540.0)
const SEA_FOLK_VILLAGE_FLOOR_Y := -72.0
const SEA_FOLK_VILLAGE_FLAT_RADIUS := 105.0
const SEA_FOLK_VILLAGE_FLATTEN_TRANSITION := 45.0

# An asymmetric archipelago rather than a regular ring. The broad western
# island is a real exploration space; the smaller peaks form loose chains and
# leave the centre, Kraken route, and outer shipping lanes as open water.
const ISLANDS := [
	{"center": Vector2(-118.0, 72.0), "radius": 116.0, "height": 10.5, "main": true},
	{"center": Vector2(42.0, 138.0), "radius": 43.0, "height": 5.2},
	{"center": Vector2(112.0, 88.0), "radius": 31.0, "height": 3.8},
	{"center": Vector2(151.0, -26.0), "radius": 54.0, "height": 6.0},
	{"center": Vector2(72.0, -118.0), "radius": 35.0, "height": 4.4},
	{"center": Vector2(-34.0, -154.0), "radius": 48.0, "height": 5.5},
	{"center": Vector2(-152.0, -91.0), "radius": 27.0, "height": 3.4},
]

const KELP_COLORS := [Color(0.055, 0.38, 0.25), Color(0.08, 0.52, 0.31), Color(0.19, 0.45, 0.25)]
const REEF_COLORS := [Color(0.88, 0.30, 0.26), Color(0.94, 0.53, 0.25), Color(0.72, 0.30, 0.58), Color(0.24, 0.67, 0.66)]

var _underwater_environment: Environment
var _underwater_camera: Camera3D
var _rng := RandomNumberGenerator.new()


func _raw_height(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var deep_t := smoothstep(250.0, HALF_SIZE * 0.94, point.length())
	# Even the central open sea is deeper than the Kraken's full idle height;
	# the perimeter descends into a true abyss rather than ending at one
	# nearly level shelf.
	var base := lerpf(-42.0, -110.0, deep_t)
	# Layered long and medium wavelengths create a rolling natural sea floor
	# between authored features rather than a mostly planar radial descent.
	# Amplitudes stay gentle relative to their wavelengths, preserving easy
	# seabed walking and predictable swimming clearance.
	base += sin(x * 0.010) * 3.2
	base += cos(z * 0.012) * 2.5
	base += sin((x + z) * 0.006) * 2.0
	base += sin(x * 0.034) * cos(z * 0.029) * 0.9
	for trench in [Vector3(420.0, 250.0, 150.0), Vector3(-380.0, -330.0, 190.0)]:
		var trench_distance := point.distance_to(Vector2(trench.x, trench.y))
		base -= exp(-pow(trench_distance / trench.z, 2.0)) * 24.0
	var height := base
	for spec in ISLANDS:
		var center: Vector2 = spec["center"]
		var radius: float = spec["radius"]
		var distance := point.distance_to(center)
		if distance < radius:
			# A low exponent turns the old narrow volcanic-looking peak into a
			# broad, gently crowned island while retaining a continuous coast.
			var rise := pow(smoothstep(0.0, 1.0, 1.0 - distance / radius), 0.34)
			height = maxf(height, lerpf(base, float(spec["height"]), rise))
	var village_distance := point.distance_to(SEA_FOLK_VILLAGE_CENTER)
	var natural_amount := smoothstep(
		SEA_FOLK_VILLAGE_FLAT_RADIUS,
		SEA_FOLK_VILLAGE_FLAT_RADIUS + SEA_FOLK_VILLAGE_FLATTEN_TRANSITION,
		village_distance
	)
	height = lerpf(SEA_FOLK_VILLAGE_FLOOR_Y, height, natural_amount)
	return height


func get_mesh_height(x: float, z: float) -> float:
	# Match the actual two triangles rendered in _build_floor(), rather than
	# evaluating the smooth height formula between its 10-metre vertices.
	# Props and actors otherwise follow an imaginary curved surface and can
	# visibly hover above the polygonal beach beneath them.
	var step := HALF_SIZE * 2.0 / float(GRID_STEPS)
	var local_x := clampf(x + HALF_SIZE, 0.0, HALF_SIZE * 2.0 - 0.001)
	var local_z := clampf(z + HALF_SIZE, 0.0, HALF_SIZE * 2.0 - 0.001)
	var ix := floori(local_x / step)
	var iz := floori(local_z / step)
	var x0 := -HALF_SIZE + float(ix) * step
	var z0 := -HALF_SIZE + float(iz) * step
	var tx := (local_x - float(ix) * step) / step
	var tz := (local_z - float(iz) * step) / step
	var h0 := _raw_height(x0, z0)
	var h1 := _raw_height(x0 + step, z0)
	var h2 := _raw_height(x0 + step, z0 + step)
	var h3 := _raw_height(x0, z0 + step)
	if tx >= tz:
		return h0 + (h1 - h0) * tx + (h2 - h1) * tz
	return h0 + (h2 - h3) * tx + (h3 - h0) * tz


func is_lake_area(_world_pos: Vector2) -> bool:
	return true


func get_lake_water_level() -> float:
	return WATER_LEVEL


func get_mesh_normal(x: float, z: float) -> Vector3:
	const SAMPLE := 0.75
	var dx := get_mesh_height(x + SAMPLE, z) - get_mesh_height(x - SAMPLE, z)
	var dz := get_mesh_height(x, z + SAMPLE) - get_mesh_height(x, z - SAMPLE)
	return Vector3(-dx / (SAMPLE * 2.0), 1.0, -dz / (SAMPLE * 2.0)).normalized()


func _raw_normal(x: float, z: float) -> Vector3:
	# Floor construction already samples exact grid vertices. Avoid routing
	# each normal through get_mesh_height(), which interpolates four more
	# vertices per sample and previously multiplied startup work enormously.
	const SAMPLE := 1.5
	var dx: float = _raw_height(x + SAMPLE, z) - _raw_height(x - SAMPLE, z)
	var dz: float = _raw_height(x, z + SAMPLE) - _raw_height(x, z - SAMPLE)
	return Vector3(-dx / (SAMPLE * 2.0), 1.0, -dz / (SAMPLE * 2.0)).normalized()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rng.seed = 20260908
	_build_outer_seabed()
	_build_floor()
	_build_water_surface()
	_build_island_nature()
	_build_ocean_floor_landscape()
	_build_seabed_glints()
	_prepare_underwater_environment.call_deferred()


func _exit_tree() -> void:
	if is_instance_valid(_underwater_camera) and _underwater_camera.environment == _underwater_environment:
		_underwater_camera.environment = null


func _process(_delta: float) -> void:
	if _underwater_environment == null:
		return
	var active_camera := get_viewport().get_camera_3d()
	if active_camera == null:
		return
	if active_camera.global_position.y < WATER_LEVEL - 0.08:
		if active_camera.environment != _underwater_environment:
			active_camera.environment = _underwater_environment
		_underwater_camera = active_camera
	elif active_camera.environment == _underwater_environment:
		active_camera.environment = null
		_underwater_camera = null


func _prepare_underwater_environment() -> void:
	_underwater_environment = Environment.new()
	_underwater_environment.background_mode = Environment.BG_COLOR
	_underwater_environment.background_color = UNDERWATER_BACKGROUND
	_underwater_environment.background_energy_multiplier = 1.12
	_underwater_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_underwater_environment.ambient_light_color = Color(0.36, 0.69, 0.70)
	_underwater_environment.ambient_light_energy = 1.34
	_underwater_environment.fog_enabled = true
	_underwater_environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	_underwater_environment.fog_light_color = UNDERWATER_FOG
	_underwater_environment.fog_light_energy = 1.12
	# Water retains a stronger depth cue than open air, but remains clear
	# enough to navigate between reefs, the village lights, and landmarks.
	# The previous 0.018 density obscured almost everything a few hundred
	# metres away and made the kingdom feel much smaller than its real map.
	_underwater_environment.fog_density = 0.0035
	_underwater_environment.fog_sky_affect = 1.0
	_underwater_environment.adjustment_enabled = true
	_underwater_environment.adjustment_brightness = 1.16
	_underwater_environment.adjustment_saturation = 0.94


func _floor_color(height: float) -> Color:
	if height > 1.0:
		return GRASS_COLOR
	if height > -2.0:
		return BEACH_COLOR
	if height > -14.0:
		return SHALLOW_FLOOR_COLOR
	return DEEP_FLOOR_COLOR


func _build_outer_seabed() -> void:
	# Four visual-only strips begin exactly where the detailed square ends.
	# A single giant plane underneath would cover the intentionally deeper
	# trenches in the playable terrain; this frame fills only the world beyond
	# it and costs four simple quads with no extra physics collision.
	var extension: float = VISUAL_HALF_SIZE - HALF_SIZE
	var outer_span: float = VISUAL_HALF_SIZE * 2.0
	var inner_span: float = HALF_SIZE * 2.0
	var strip_material := StandardMaterial3D.new()
	strip_material.albedo_color = DEEP_FLOOR_COLOR
	strip_material.roughness = 0.9
	var strips: Array[Dictionary] = [
		{"size": Vector2(outer_span, extension), "position": Vector3(0.0, OUTER_FLOOR_Y, HALF_SIZE + extension * 0.5)},
		{"size": Vector2(outer_span, extension), "position": Vector3(0.0, OUTER_FLOOR_Y, -HALF_SIZE - extension * 0.5)},
		{"size": Vector2(extension, inner_span), "position": Vector3(HALF_SIZE + extension * 0.5, OUTER_FLOOR_Y, 0.0)},
		{"size": Vector2(extension, inner_span), "position": Vector3(-HALF_SIZE - extension * 0.5, OUTER_FLOOR_Y, 0.0)},
	]
	for index in strips.size():
		var spec: Dictionary = strips[index]
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.name = "OuterOceanFloor%02d" % index
		var plane := PlaneMesh.new()
		var strip_size: Vector2 = spec["size"]
		var strip_position: Vector3 = spec["position"]
		plane.size = strip_size
		mesh_instance.mesh = plane
		mesh_instance.position = strip_position
		mesh_instance.material_override = strip_material
		add_child(mesh_instance)


func _build_floor() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.86
	surface.set_material(material)
	var step := HALF_SIZE * 2.0 / float(GRID_STEPS)
	var collision_faces := PackedVector3Array()
	for ix in GRID_STEPS:
		for iz in GRID_STEPS:
			var x0 := -HALF_SIZE + float(ix) * step
			var x1 := x0 + step
			var z0 := -HALF_SIZE + float(iz) * step
			var z1 := z0 + step
			var points: Array[Vector3] = [Vector3(x0, _raw_height(x0, z0), z0), Vector3(x1, _raw_height(x1, z0), z0), Vector3(x1, _raw_height(x1, z1), z1), Vector3(x0, _raw_height(x0, z1), z1)]
			# Godot treats clockwise winding as the visible front face. These
			# triangles face upward so beaches and grass render from above.
			for tri in [[0, 1, 2], [0, 2, 3]]:
				for point_index in tri:
					var point: Vector3 = points[point_index]
					surface.set_color(_floor_color(point.y))
					surface.set_normal(_raw_normal(point.x, point.z))
					surface.add_vertex(point)
					collision_faces.append(point)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ContinuousOceanFloor"
	mesh_instance.mesh = surface.commit()
	add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(collision_faces)
	collision.shape = shape
	add_child(collision)


func _build_water_surface() -> void:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "TwoSidedWaterCeiling"
	var plane := PlaneMesh.new()
	plane.size = Vector2(VISUAL_HALF_SIZE * 2.0, VISUAL_HALF_SIZE * 2.0)
	mesh_instance.mesh = plane
	mesh_instance.position.y = WATER_LEVEL
	var material := ShaderMaterial.new()
	material.shader = OCEAN_WATER_SHADER
	material.set_shader_parameter("surface_color", WATER_COLOR)
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)


func _build_island_nature() -> void:
	for spec in ISLANDS:
		var center: Vector2 = spec["center"]
		var radius: float = spec["radius"]
		var is_main: bool = bool(spec.get("main", false))
		var tree_count := 24 if is_main else maxi(4, roundi(radius * 0.10))
		var undergrowth_count := 48 if is_main else maxi(7, roundi(radius * 0.17))
		for index in tree_count:
			var angle := _rng.randf_range(0.0, TAU)
			var distance := sqrt(_rng.randf()) * radius * (0.48 if is_main else 0.38)
			var point := center + Vector2(cos(angle), sin(angle)) * distance
			if get_mesh_height(point.x, point.y) <= 1.0:
				continue
			var tree: Node3D
			if is_main and index % 5 == 0:
				tree = NatureProps.build_banana_tree(_rng.randf_range(5.5, 8.0), _rng)
			elif is_main and index % 7 == 0:
				tree = NatureProps.build_flowering_tree(_rng.randf_range(6.0, 9.0), Color(0.12, 0.57, 0.28), Color(0.95, 0.48, 0.63), _rng)
			else:
				tree = NatureProps.build_palm_tree(_rng.randf_range(5.0, 9.5), _rng.randf_range(-0.14, 0.14), _rng)
			tree.position = Vector3(point.x, get_mesh_height(point.x, point.y), point.y)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			_set_visual_range(tree, 340.0, 30.0)
			add_child(tree)
		for index in undergrowth_count:
			var angle := _rng.randf_range(0.0, TAU)
			var distance := sqrt(_rng.randf()) * radius * (0.54 if is_main else 0.42)
			var point := center + Vector2(cos(angle), sin(angle)) * distance
			if get_mesh_height(point.x, point.y) <= 1.0:
				continue
			var plant: Node3D
			if is_main and index % 9 == 0:
				plant = NatureProps.build_flower([Color(0.96, 0.54, 0.26), Color(0.92, 0.35, 0.61), Color(0.92, 0.78, 0.23)][index % 3])
			elif index % 2 == 0:
				plant = NatureProps.build_bush(Color(0.08, 0.62, 0.35))
			else:
				plant = NatureProps.build_grass_tuft(Color(0.18, 0.74, 0.39))
			plant.position = Vector3(point.x, get_mesh_height(point.x, point.y), point.y)
			plant.rotation.y = _rng.randf_range(0.0, TAU)
			_set_visual_range(plant, 185.0, 22.0)
			add_child(plant)


func _build_ocean_floor_landscape() -> void:
	# Broad, irregular plant meadows make the floor read as a landscape. Keep
	# them below the shoreline and away from the deep city footprint, whose
	# own designed kelp gardens remain visually distinct.
	var meadows: Array[Dictionary] = [
		{"center": Vector2(-285.0, 95.0), "radius": 105.0, "count": 24},
		{"center": Vector2(245.0, 125.0), "radius": 120.0, "count": 28},
		{"center": Vector2(170.0, -235.0), "radius": 105.0, "count": 24},
		{"center": Vector2(-235.0, -240.0), "radius": 125.0, "count": 30},
	]
	for meadow in meadows:
		var center: Vector2 = meadow["center"]
		var radius: float = meadow["radius"]
		for index in int(meadow["count"]):
			var offset: Vector2 = _random_disc(radius)
			var point: Vector2 = center + offset
			var floor_y: float = get_mesh_height(point.x, point.y)
			if floor_y < -55.0 or floor_y > -2.5:
				continue
			var flora: Node3D
			if index % 5 == 0:
				flora = _build_fan_seaweed(_rng.randf_range(2.0, 4.8), KELP_COLORS[index % KELP_COLORS.size()])
			else:
				flora = _build_ribbon_kelp(_rng.randf_range(2.8, 8.5), KELP_COLORS[index % KELP_COLORS.size()])
			flora.position = Vector3(point.x, floor_y, point.y)
			flora.rotation.y = _rng.randf_range(0.0, TAU)
			_set_visual_range(flora, 175.0, 25.0)
			add_child(flora)

	# Coral reefs occupy shallow shelves beside, but not directly on, the
	# beaches. Each reef is an uneven constellation rather than a circular
	# stamp, with rock, branching coral, fans, and short weed mixed together.
	var reef_centers: Array[Vector2] = [Vector2(-12.0, 205.0), Vector2(205.0, 34.0), Vector2(108.0, -178.0)]
	for reef_center: Vector2 in reef_centers:
		for index in 20:
			var point: Vector2 = reef_center + _random_disc(_rng.randf_range(22.0, 52.0))
			var floor_y: float = get_mesh_height(point.x, point.y)
			if floor_y < -24.0 or floor_y > -2.0:
				continue
			var reef_piece: Node3D
			if index % 6 == 0:
				reef_piece = NatureProps.build_rock(_rng.randf_range(0.5, 1.5), false)
			elif index % 3 == 0:
				reef_piece = _build_fan_seaweed(_rng.randf_range(1.1, 2.6), REEF_COLORS[index % REEF_COLORS.size()])
			else:
				reef_piece = _build_branching_coral(_rng.randf_range(1.0, 3.0), REEF_COLORS[index % REEF_COLORS.size()])
			reef_piece.position = Vector3(point.x, floor_y, point.y)
			reef_piece.rotation.y = _rng.randf_range(0.0, TAU)
			_set_visual_range(reef_piece, 210.0, 28.0)
			add_child(reef_piece)


func _set_visual_range(root: Node, end_distance: float, fade_margin: float) -> void:
	if root is GeometryInstance3D:
		var geometry := root as GeometryInstance3D
		geometry.visibility_range_end = end_distance
		geometry.visibility_range_end_margin = fade_margin
		geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for child in root.get_children():
		_set_visual_range(child, end_distance, fade_margin)


func _random_disc(radius: float) -> Vector2:
	var angle: float = _rng.randf_range(0.0, TAU)
	var distance: float = sqrt(_rng.randf()) * radius
	return Vector2(cos(angle), sin(angle)) * distance


func _build_ribbon_kelp(height: float, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	var segment_count: int = 4
	var segment_height: float = height / float(segment_count)
	var drift: Vector3 = Vector3.ZERO
	for segment in segment_count:
		var progress: float = float(segment) / float(segment_count - 1)
		var pivot: Node3D = Node3D.new()
		pivot.position = drift
		pivot.rotation.z = sin(float(segment) * 1.7 + height) * 0.13
		root.add_child(pivot)
		var blade: MeshInstance3D = SuperEgg.build_part(
			Vector3(lerpf(0.22, 0.10, progress), segment_height * 0.56, 0.055),
			color.lightened(progress * 0.08), SuperEgg.EPSILON_SOFT, 2.8
		)
		blade.position.y = segment_height * 0.5
		pivot.add_child(blade)
		drift += Vector3(sin(float(segment) * 1.31 + height) * height * 0.025, segment_height, cos(float(segment) * 1.07) * height * 0.018)
	return root


func _build_fan_seaweed(height: float, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	for blade_index in 5:
		var blade_height: float = height * _rng.randf_range(0.58, 1.0)
		var pivot: Node3D = Node3D.new()
		pivot.rotation.z = deg_to_rad(float(blade_index - 2) * 11.0)
		pivot.rotation.y = _rng.randf_range(-0.25, 0.25)
		root.add_child(pivot)
		var blade: MeshInstance3D = SuperEgg.build_part(Vector3(0.11, blade_height * 0.5, 0.045), color.lightened(float(blade_index) * 0.025), 2.6, 2.8)
		blade.position.y = blade_height * 0.5
		pivot.add_child(blade)
	return root


func _build_branching_coral(height: float, color: Color) -> Node3D:
	var root: Node3D = Node3D.new()
	var trunk: MeshInstance3D = SuperEgg.build_part(Vector3(0.15, height * 0.5, 0.15), color, 2.6, 2.6)
	trunk.position.y = height * 0.5
	root.add_child(trunk)
	for branch_index in 4:
		var branch_height: float = height * (0.34 + float(branch_index % 2) * 0.12)
		var branch: MeshInstance3D = SuperEgg.build_part(Vector3(0.10, branch_height * 0.5, 0.10), color.lightened(0.04 * branch_index), 2.6, 2.6)
		branch.position = Vector3((1.0 if branch_index % 2 == 0 else -1.0) * height * 0.16, height * (0.30 + float(branch_index) * 0.13), 0.0)
		branch.rotation.z = deg_to_rad(28.0 if branch_index % 2 == 0 else -28.0)
		root.add_child(branch)
	return root


func _build_seabed_glints() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.91, 0.82)
	material.emission_enabled = true
	material.emission = Color(0.12, 0.68, 0.62)
	material.emission_energy_multiplier = 0.85
	material.roughness = 0.28
	for index in 110:
		var angle := _rng.randf_range(0.0, TAU)
		var distance := sqrt(_rng.randf()) * 760.0
		var point := Vector2(cos(angle), sin(angle)) * distance
		var height := get_mesh_height(point.x, point.y)
		if height > -3.0:
			continue
		var glint := MeshInstance3D.new()
		glint.name = "SeabedGlint"
		glint.mesh = SuperEgg.build_mesh(Vector3(_rng.randf_range(0.16, 0.48), 0.035, _rng.randf_range(0.12, 0.38)), 2.2, 2.2)
		glint.material_override = material
		glint.position = Vector3(point.x, height + 0.07, point.y)
		glint.rotation.y = _rng.randf_range(0.0, TAU)
		glint.visibility_range_end = 145.0
		glint.visibility_range_end_margin = 24.0
		glint.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		add_child(glint)
