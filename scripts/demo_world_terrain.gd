class_name DemoWorldTerrain
extends StaticBody3D

## The demo world: one long valley running east (+X) through a biome for every
## blorb suit with a clear traversal power, each entered through a
## CheckpointPortal that swaps in that suit. One heightfield owns rendering,
## collision and every gameplay height query, the same way the kingdoms'
## terrains do.
##
## West to east: the arrival clearing, the plant grove, the lake (water), the
## dirt track (ground), the lava pool (fire), the frozen lake (ice), the snow
## mountain with its portal on the peak (snow), and the spire field (air).
## Steep ground rises along both sides and both ends to close the valley.

const X_MIN := -140.0
const X_MAX := 1240.0
const Z_HALF := 170.0
const SPACING := 5.0

const START_CENTER := Vector2(0.0, 0.0)
const START_RADIUS := 32.0

const PLANT_ZONE := Vector2(60.0, 175.0)

const LAKE_CENTER := Vector2(265.0, 0.0)
const LAKE_RADIUS := 55.0
const LAKE_FLOOR := -14.0
## Just under the surrounding ground, so the shore reads as a bank rather than
## water lapping at a seam in the grass.
const WATER_LEVEL := -1.2

const DIRT_ZONE := Vector2(350.0, 470.0)

const LAVA_CENTER := Vector2(560.0, 0.0)
const LAVA_RADIUS := 40.0
const LAVA_LEVEL := -0.6
const LAVA_FLOOR := -5.0

const ICE_CENTER := Vector2(700.0, 0.0)
const ICE_RADIUS := 55.0
const ICE_LEVEL := -0.8

const MOUNTAIN_CENTER := Vector2(870.0, 0.0)
const MOUNTAIN_RADIUS := 110.0
## A smoothstep profile peaks in steepness at ~0.75 rise/run (about 37 deg) at
## mid-slope: walkable to the summit without the snow suit, rideable down.
const MOUNTAIN_HEIGHT := 58.0

const AIR_ZONE := Vector2(1020.0, 1190.0)

## Every portal, in the order the valley reaches them. Each stands on the path
## (z = 0) facing east, at the start of its biome.
## The snow portal's x is MOUNTAIN_CENTER.x: it stands on the summit.
const PORTALS := [
	{"element": "plant", "head_item": "", "x": 48.0},
	{"element": "water", "head_item": "Diving Helmet", "x": 190.0},
	{"element": "ground", "head_item": "", "x": 342.0},
	{"element": "fire", "head_item": "Lava Helm", "x": 488.0},
	{"element": "ice", "head_item": "Toboggan", "x": 628.0},
	{"element": "snow", "head_item": "", "x": 870.0},
	{"element": "air", "head_item": "", "x": 1002.0},
]
## Ground portals sit on a small level pad so the ring's base meets the ground.
const PORTAL_PAD_RADIUS := 5.0

const GRASS := Color(0.36, 0.58, 0.28)
const JUNGLE := Color(0.2, 0.45, 0.18)
const LAKEBED := Color(0.62, 0.56, 0.4)
const DIRT := Color(0.42, 0.28, 0.16)
const BASALT := Color(0.18, 0.15, 0.14)
const ICE := Color(0.74, 0.88, 0.96)
const SNOW := Color(0.93, 0.95, 0.98)
const STONE := Color(0.52, 0.5, 0.47)

var _nx: int
var _nz: int
## _raw_height() at every grid vertex, computed once: characters query heights
## many times a frame, and the mesh build samples each vertex's neighbours.
var _heights := PackedFloat32Array()
var _noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_noise.seed = 20260918
	_noise.frequency = 0.02
	_noise.fractal_octaves = 3
	_rng.seed = 20260918
	_nx = int(round((X_MAX - X_MIN) / SPACING)) + 1
	_nz = int(round(Z_HALF * 2.0 / SPACING)) + 1
	_heights.resize(_nx * _nz)
	for iz in _nz:
		for ix in _nx:
			_heights[iz * _nx + ix] = _raw_height(X_MIN + float(ix) * SPACING, -Z_HALF + float(iz) * SPACING)
	_build_mesh_and_collision()
	_build_liquid_surfaces()
	_scatter_scenery()


# ---- Shape -----------------------------------------------------------------

func _raw_height(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var height := _noise.get_noise_2d(x, z) * 1.4
	# Dirt track: rolling mounds across the path for jumps and wheelies.
	var dirt_mask := smoothstep(DIRT_ZONE.x, DIRT_ZONE.x + 15.0, x) * (1.0 - smoothstep(DIRT_ZONE.y - 15.0, DIRT_ZONE.y, x))
	height += dirt_mask * 3.2 * maxf(sin((x - DIRT_ZONE.x) * 0.08), 0.0) * (0.6 + 0.4 * cos(z * 0.05))
	# Lake: a bowl from a wadeable shelf at the rim down to a deep floor.
	var lake_distance := point.distance_to(LAKE_CENTER)
	var lake_target := lerpf(LAKE_FLOOR, WATER_LEVEL - 1.9, smoothstep(LAKE_RADIUS * 0.35, LAKE_RADIUS, lake_distance))
	height = lerpf(height, lake_target, 1.0 - smoothstep(LAKE_RADIUS, LAKE_RADIUS + 14.0, lake_distance))
	# Lava pool: a sunken bowl inside a raised basalt rim.
	var lava_distance := point.distance_to(LAVA_CENTER)
	var rim := smoothstep(LAVA_RADIUS - 2.0, LAVA_RADIUS + 3.0, lava_distance) * (1.0 - smoothstep(LAVA_RADIUS + 3.0, LAVA_RADIUS + 12.0, lava_distance))
	height += rim * 1.6
	var lava_target := lerpf(LAVA_FLOOR, LAVA_LEVEL - 0.5, smoothstep(LAVA_RADIUS * 0.5, LAVA_RADIUS, lava_distance))
	height = lerpf(height, lava_target, 1.0 - smoothstep(LAVA_RADIUS - 2.0, LAVA_RADIUS, lava_distance))
	# Frozen lake: a level sheet of ice with a gentle bank.
	var ice_distance := point.distance_to(ICE_CENTER)
	height = lerpf(height, ICE_LEVEL, 1.0 - smoothstep(ICE_RADIUS, ICE_RADIUS + 10.0, ice_distance))
	# Snow mountain, smooth to its summit.
	var mountain_distance := point.distance_to(MOUNTAIN_CENTER)
	height = maxf(height, MOUNTAIN_HEIGHT * (1.0 - smoothstep(0.0, MOUNTAIN_RADIUS, mountain_distance)))
	# Level arrival clearing and portal pads.
	height = lerpf(height, 0.0, 1.0 - smoothstep(START_RADIUS, START_RADIUS + 16.0, point.distance_to(START_CENTER)))
	for portal in PORTALS:
		var portal_x: float = portal["x"]
		if is_equal_approx(portal_x, MOUNTAIN_CENTER.x):
			continue
		var pad := 1.0 - smoothstep(PORTAL_PAD_RADIUS, PORTAL_PAD_RADIUS + 4.0, point.distance_to(Vector2(portal_x, 0.0)))
		height = lerpf(height, 0.0, pad)
	# Valley walls along both sides and at both ends.
	height += smoothstep(115.0, 165.0, absf(z)) * 34.0
	height += (1.0 - smoothstep(X_MIN + 20.0, -60.0, x)) * 34.0
	height += smoothstep(1190.0, X_MAX - 20.0, x) * 34.0
	return height


func _height_color(x: float, z: float, height: float) -> Color:
	var point := Vector2(x, z)
	if absf(z) > 125.0 or x < -70.0 or x > 1200.0:
		return STONE.lerp(GRASS, 0.35)
	if point.distance_to(MOUNTAIN_CENTER) < MOUNTAIN_RADIUS:
		return SNOW
	if point.distance_to(ICE_CENTER) < ICE_RADIUS + 3.0:
		return ICE
	if point.distance_to(LAVA_CENTER) < LAVA_RADIUS + 14.0:
		return BASALT
	if point.distance_to(LAKE_CENTER) < LAKE_RADIUS + 16.0 and height < WATER_LEVEL + 0.6:
		return LAKEBED
	if x >= DIRT_ZONE.x - 8.0 and x <= DIRT_ZONE.y:
		return DIRT
	if x >= AIR_ZONE.x - 10.0:
		return STONE
	if x >= PLANT_ZONE.x - 6.0 and x <= PLANT_ZONE.y:
		return JUNGLE
	return GRASS


# ---- Gameplay queries (the contract every character reads) -----------------

func get_mesh_height(x: float, z: float) -> float:
	var fx: float = clampf((x - X_MIN) / SPACING, 0.0, float(_nx - 1) - 0.001)
	var fz: float = clampf((z + Z_HALF) / SPACING, 0.0, float(_nz - 1) - 0.001)
	var ix: int = clampi(int(fx), 0, _nx - 2)
	var iz: int = clampi(int(fz), 0, _nz - 2)
	var tx: float = fx - float(ix)
	var tz: float = fz - float(iz)
	var a := _grid_vertex(ix, iz)
	var b := _grid_vertex(ix + 1, iz)
	var c := _grid_vertex(ix, iz + 1)
	var d := _grid_vertex(ix + 1, iz + 1)
	return _plane_height(a, c, b, x, z) if tx + tz <= 1.0 else _plane_height(b, c, d, x, z)


func get_mesh_normal(x: float, z: float) -> Vector3:
	const D := 0.7
	return Vector3(
		get_mesh_height(x - D, z) - get_mesh_height(x + D, z), D * 2.0,
		get_mesh_height(x, z - D) - get_mesh_height(x, z + D)
	).normalized()


func is_lake_area(pos: Vector2) -> bool:
	return pos.distance_to(LAKE_CENTER) < LAKE_RADIUS + 8.0


func get_lake_water_level() -> float:
	return WATER_LEVEL


func is_lava_area(pos: Vector2) -> bool:
	return pos.distance_to(LAVA_CENTER) < LAVA_RADIUS


func get_lava_surface_height(_pos: Vector2) -> float:
	return LAVA_LEVEL


## Just outside the rim, straight out from wherever the lava was entered.
func get_lava_escape_position(pos: Vector2) -> Vector3:
	var outward := pos - LAVA_CENTER
	if outward.length_squared() < 0.01:
		outward = Vector2(-1.0, 0.0)
	var escape := LAVA_CENTER + outward.normalized() * (LAVA_RADIUS + 10.0)
	return Vector3(escape.x, get_mesh_height(escape.x, escape.y), escape.y)


func is_ice_surface(pos: Vector2) -> bool:
	return pos.distance_to(ICE_CENTER) < ICE_RADIUS and get_mesh_height(pos.x, pos.y) <= ICE_LEVEL + 0.06


func get_ice_level() -> float:
	return ICE_LEVEL


func is_snow_footstep_surface(pos: Vector2) -> bool:
	return pos.distance_to(MOUNTAIN_CENTER) < MOUNTAIN_RADIUS


func is_safe_zone(pos: Vector2) -> bool:
	return pos.distance_to(START_CENTER) < START_RADIUS + 16.0


func is_nme_hazard(pos: Vector2) -> bool:
	return is_lava_area(pos)


func get_start_point() -> Vector3:
	return Vector3(START_CENTER.x, get_mesh_height(START_CENTER.x, START_CENTER.y), START_CENTER.y)


## Where each portal stands: on the path at its x, on the summit for snow.
func get_portal_position(portal: Dictionary) -> Vector3:
	var x: float = portal["x"]
	return Vector3(x, get_mesh_height(x, 0.0), 0.0)


# ---- Construction ------------------------------------------------------------

func _grid_vertex(ix: int, iz: int) -> Vector3:
	return Vector3(X_MIN + float(ix) * SPACING, _heights[iz * _nx + ix], -Z_HALF + float(iz) * SPACING)


func _plane_height(a: Vector3, b: Vector3, c: Vector3, x: float, z: float) -> float:
	var denominator: float = (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	var wa: float = ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / denominator
	var wb: float = ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / denominator
	return wa * a.y + wb * b.y + (1.0 - wa - wb) * c.y


func _build_mesh_and_collision() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in _nz:
		for ix in _nx:
			var vertex := _grid_vertex(ix, iz)
			tool.set_color(_height_color(vertex.x, vertex.z, vertex.y))
			tool.set_normal(get_mesh_normal(vertex.x, vertex.z))
			tool.add_vertex(vertex)
	for iz in _nz - 1:
		for ix in _nx - 1:
			var i0: int = iz * _nx + ix
			for index in [i0, i0 + _nx, i0 + 1, i0 + 1, i0 + _nx, i0 + _nx + 1]:
				tool.add_index(index)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tool.set_material(material)
	var terrain_mesh := MeshInstance3D.new()
	terrain_mesh.mesh = tool.commit()
	add_child(terrain_mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(terrain_mesh.mesh.get_faces())
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)


## Visual liquid surfaces. Water and lava are not solid (swimming and lava
## contact are gameplay queries above); the ice sheet is the terrain itself,
## given a glossy skin here.
func _build_liquid_surfaces() -> void:
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.16, 0.42, 0.62, 0.68)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.12
	water.metallic = 0.12
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	_add_disc("Water", LAKE_CENTER, LAKE_RADIUS + 12.0, WATER_LEVEL, water)
	_add_disc("Lava", LAVA_CENTER, LAVA_RADIUS + 1.0, LAVA_LEVEL, NatureProps.build_lava_material())
	var ice := StandardMaterial3D.new()
	ice.albedo_color = Color(0.8, 0.93, 1.0, 0.35)
	ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ice.roughness = 0.05
	ice.metallic = 0.2
	_add_disc("IceSheen", ICE_CENTER, ICE_RADIUS, ICE_LEVEL + 0.02, ice)


func _add_disc(label: String, center: Vector2, radius: float, y: float, material: Material) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SEGMENTS := 72
	for index in SEGMENTS:
		var a0 := TAU * float(index) / float(SEGMENTS)
		var a1 := TAU * float(index + 1) / float(SEGMENTS)
		# Counter-clockwise from above, so the face points up.
		for p in [Vector2.ZERO, Vector2(cos(a1), sin(a1)) * radius, Vector2(cos(a0), sin(a0)) * radius]:
			var offset: Vector2 = p
			tool.set_normal(Vector3.UP)
			tool.add_vertex(Vector3(center.x + offset.x, y, center.y + offset.y))
	tool.set_material(material)
	var disc := MeshInstance3D.new()
	disc.name = label
	disc.mesh = tool.commit()
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(disc)
	CollisionPolicy.mark_decorative(disc)


# ---- Scenery -------------------------------------------------------------------

func _scatter_scenery() -> void:
	_scatter_clearing()
	_scatter_plant_grove()
	_scatter_shores()
	_scatter_dirt_track()
	_scatter_mountain_pines()
	_scatter_air_spires()


func _place(node: Node3D, x: float, z: float) -> void:
	node.position = Vector3(x, get_mesh_height(x, z), z)
	add_child(node)


## A random point in a zone, clear of the path (|z| > path_margin) so the
## walk east through each biome stays open.
func _zone_point(x_range: Vector2, path_margin: float, z_limit: float = 105.0) -> Vector2:
	var side := -1.0 if _rng.randf() < 0.5 else 1.0
	return Vector2(_rng.randf_range(x_range.x, x_range.y), side * _rng.randf_range(path_margin, z_limit))


func _scatter_clearing() -> void:
	for index in 26:
		var angle := TAU * float(index) / 26.0 + _rng.randf_range(-0.08, 0.08)
		var radius := _rng.randf_range(START_RADIUS - 6.0, START_RADIUS + 4.0)
		var flower := NatureProps.build_flower(Color.from_hsv(_rng.randf(), 0.55, 0.95))
		_place(flower, cos(angle) * radius, sin(angle) * radius)
	for index in 30:
		var tuft := NatureProps.build_grass_tuft()
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(4.0, START_RADIUS)
		_place(tuft, cos(angle) * radius, sin(angle) * radius)


func _scatter_plant_grove() -> void:
	for index in 34:
		var point := _zone_point(PLANT_ZONE, 7.0)
		var tree: Node3D
		match index % 4:
			0:
				tree = NatureProps.build_round_tree(_rng.randf_range(6.0, 10.0), JUNGLE.lightened(0.15))
			1:
				tree = NatureProps.build_banana_tree(_rng.randf_range(4.5, 7.0), _rng)
			2:
				tree = NatureProps.build_palm_tree(_rng.randf_range(7.0, 11.0), _rng.randf_range(0.1, 0.35), _rng)
			_:
				tree = NatureProps.build_banyan_tree(_rng.randf_range(9.0, 13.0), _rng)
		tree.rotation.y = _rng.randf_range(0.0, TAU)
		_place(tree, point.x, point.y)
	for index in 40:
		var point := _zone_point(PLANT_ZONE, 4.0)
		var bush := NatureProps.build_bush(JUNGLE.lightened(_rng.randf_range(0.0, 0.25)))
		_place(bush, point.x, point.y)


func _scatter_shores() -> void:
	for index in 12:
		var angle := _rng.randf_range(0.0, TAU)
		var radius := LAKE_RADIUS + _rng.randf_range(10.0, 18.0)
		var x := LAKE_CENTER.x + cos(angle) * radius
		var z := LAKE_CENTER.y + sin(angle) * radius
		if absf(z) < 6.0:
			continue
		_place(NatureProps.build_rock(_rng.randf_range(0.6, 1.6)), x, z)
	for index in 16:
		var angle := _rng.randf_range(0.0, TAU)
		var radius := LAVA_RADIUS + _rng.randf_range(5.0, 12.0)
		var x := LAVA_CENTER.x + cos(angle) * radius
		var z := LAVA_CENTER.y + sin(angle) * radius
		if absf(z) < 6.0:
			continue
		_place(NatureProps.build_rock(_rng.randf_range(0.8, 2.2), true, BASALT.lightened(0.1)), x, z)


## Rock ramps across and beside the path, rising toward the east, for dirtbike
## launches.
func _scatter_dirt_track() -> void:
	var ramp_x := DIRT_ZONE.x + 18.0
	var lanes: Array[float] = [0.0, -14.0, 14.0]
	while ramp_x < DIRT_ZONE.y - 20.0:
		var lane: float = lanes[_rng.randi() % lanes.size()]
		var ramp := NatureProps.build_rock_ramp(_rng.randf_range(4.0, 6.0), _rng.randf_range(5.0, 8.0), _rng.randf_range(1.2, 2.4))
		# The ramp rises along its local +Z; aim that east along the track.
		ramp.rotation.y = PI * 0.5
		_place(ramp, ramp_x, lane)
		ramp_x += _rng.randf_range(16.0, 26.0)


func _scatter_mountain_pines() -> void:
	for index in 40:
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(MOUNTAIN_RADIUS * 0.55, MOUNTAIN_RADIUS * 0.95)
		var x := MOUNTAIN_CENTER.x + cos(angle) * radius
		var z := MOUNTAIN_CENTER.y + sin(angle) * radius
		# Keep the climb and the ride down along the path clear.
		if absf(z) < 12.0:
			continue
		_place(NatureProps.build_pine_tree(_rng.randf_range(6.0, 11.0), Color(0.16, 0.36, 0.26)), x, z)


## Tall stone spires to fly between and land on.
func _scatter_air_spires() -> void:
	for index in 16:
		var point := _zone_point(AIR_ZONE, 8.0, 95.0)
		var spire := NatureProps.build_rock_spire(_rng.randf_range(2.2, 4.2), _rng.randi_range(4, 8), _rng)
		_place(spire, point.x, point.y)
	for index in 4:
		var x := AIR_ZONE.x + 30.0 + float(index) * 38.0
		var spire := NatureProps.build_rock_spire(_rng.randf_range(3.0, 4.5), _rng.randi_range(7, 10), _rng)
		_place(spire, x, _rng.randf_range(-4.0, 4.0))
