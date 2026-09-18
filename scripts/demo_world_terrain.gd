class_name DemoWorldTerrain
extends StaticBody3D

## The demo world: one long valley running east (+X) through a biome for every
## blorb suit with a clear traversal power, a real biome simulator. Where a
## biome exists elsewhere in the game, this shows that biome itself through a
## TerrainWindow onto the real kingdom's terrain (its own height and colour
## functions), rather than an imitation:
##   clearing  - the Crossroads' own hills, spawn flattening and grass
##   plant     - a patch of the Primate Kingdom's jungle, 1:1
##   snow      - the Ice Kingdom's snowboard mountain, shrunk 2.5x (slopes
##               preserved) and turned so its authored run descends east
##   ground    - the Rock/Ground Kingdom's terraces and halfpipe canyon,
##               turned to run along the valley
## The lake, frozen lake and lava pool are NaturalLake basins (the game's own
## lake technique) punched into undulating ground. Between biomes, the ground
## keeps the Crossroads' hills with a slow swell, so nowhere is flat except
## the clearing and each gate's small pad. One heightfield owns rendering,
## collision and every gameplay height query.

const JUNGLE_KINGDOM_TERRAIN := preload("res://scripts/jungle_kingdom_terrain.gd")
const ICE_KINGDOM_TERRAIN := preload("res://scripts/ice_kingdom_terrain.gd")
const ROCK_GROUND_KINGDOM_TERRAIN := preload("res://scripts/rock_ground_kingdom_terrain.gd")

const X_MIN := -140.0
const X_MAX := 1840.0
const Z_HALF := 170.0
const SPACING := 5.0

## The Crossroads' own ground (terrain_generator.gd): hill noise, amplitude and
## the arrival clearing's flattening, so the clearing is exactly its own.
const CROSSROADS_HILL_SEED := 20260815
const CROSSROADS_HILL_FREQUENCY := 0.015
const CROSSROADS_HILL_AMPLITUDE := 3.0
const CROSSROADS_GRASS := Color(0.07451, 0.63922, 0.40392)
const START_CENTER := Vector2(0.0, 0.0)
const START_FLATTEN_RADIUS := 25.0
const START_FLATTEN_TRANSITION := 12.0
## A slow, broad swell under the hills outside the clearing, so the ground
## between biomes rolls rather than lying flat.
const SWELL_AMPLITUDE := 4.0
const SWELL_FREQUENCY := 0.004

## Plant: the Primate Kingdom around this point, clear of its village and river.
const PLANT_SOURCE := Vector2(-150.0, -170.0)
const PLANT_CENTER := Vector2(230.0, 0.0)
const PLANT_HALF := Vector2(150.0, 110.0)

## Water and ice share WATER_LEVEL: the terrain reports one water level for
## the whole world, and the frozen lake's water lies beneath its ice at that
## same level, exactly as the Ice Kingdom layers them.
const WATER_LEVEL := -7.0
const LAKE_CENTER := Vector2(490.0, 0.0)
const LAKE_RADIUS := 55.0
const LAKE_EDGE_VARIATION := 9.0
const LAKE_DEPTH := 14.0
## An open lake's bank levels out just above the water: a narrow beach.
const LAKE_SHELF := WATER_LEVEL + 0.35
## The Crossroads lake lies in bare wasteland; its banks take that colour.
const WASTELAND := Color(0.565, 0.495, 0.4)

const ICE_CENTER := Vector2(660.0, 0.0)
const ICE_RADIUS := 50.0
const ICE_EDGE_VARIATION := 9.0
const ICE_LAKE_DEPTH := 8.0
## The Ice Kingdom's layering: bank shelf, the ice skin 3 cm beneath it (so the
## shore occludes the ice edge), a 0.38 m sheet, and the water under it.
const ICE_LEVEL := WATER_LEVEL + 0.45
const ICE_SURFACE_LEVEL := ICE_LEVEL - 0.03
const ICE_THICKNESS := 0.38
## The frozen lake's surroundings are snowfield, as in the Ice Kingdom.
const ICE_SNOWFIELD_RADIUS := ICE_RADIUS + 38.0
const FROZEN_LAKEBED := Color(0.48, 0.62, 0.72)
## Canonical snow: the same white as snow blorbs, boards and snowfields.
const SNOW := Color(0.94, 0.96, 0.98)

## Snow: the Ice Kingdom's mountain, peak placed here. Its authored run
## descends from the peak toward (-205, -102); the window turns that direction
## to face east.
const MOUNTAIN_SOURCE_PEAK := Vector2(-790.0, -330.0)
const MOUNTAIN_SOURCE_RUN_END := Vector2(-205.0, -102.0)
const MOUNTAIN_CENTER := Vector2(930.0, 0.0)
const MOUNTAIN_RADIUS := 180.0
const MOUNTAIN_SCALE := 2.5

## Ground: the Rock/Ground Kingdom's western halfpipe canyon and terraces.
## Its canyon runs along the kingdom's z axis; a quarter turn lays it east.
const DIRT_SOURCE := Vector2(-330.0, 155.0)
const DIRT_CENTER := Vector2(1290.0, 0.0)
const DIRT_HALF := Vector2(150.0, 110.0)

const AIR_ZONE := Vector2(1455.0, 1595.0)

## The lava pool is carved as a NaturalLake basin too, filled with lava.
const LAVA_CENTER := Vector2(1690.0, 0.0)
const LAVA_RADIUS := 40.0
const LAVA_EDGE_VARIATION := 6.0
const LAVA_DEPTH := 6.0
const LAVA_LEVEL := -3.0
## The Crossroads volcano's basalt, scorched toward the lava.
const BASALT := Color(0.10, 0.09, 0.09)
const SCORCHED := Color(0.30, 0.14, 0.08)
const STONE := Color(0.52, 0.5, 0.47)

## Every border gate, west to east: the biome on either side of it.
## Each biome's portal stands on the side you enter it from, facing you (see
## demo_world.gd). The first gate's western side is the hero's starting pair
## of Normal blorbs (element ""). Every gate stands on the path (z = 0) on a
## small level pad, clear of lake banks, windows and the lava bank.
const BORDERS := [
	{"x": 70.0, "west": "", "east": "plant"},
	{"x": 400.0, "west": "plant", "east": "water"},
	{"x": 575.0, "west": "water", "east": "ice"},
	{"x": 740.0, "west": "ice", "east": "snow"},
	{"x": 1125.0, "west": "snow", "east": "ground"},
	{"x": 1445.0, "west": "ground", "east": "air"},
	{"x": 1605.0, "west": "air", "east": "fire"},
]
## Ice and Snow bring the Toboggan; Air brings the Bird Helm.
const HEAD_ITEMS := {
	"water": "Diving Helmet",
	"ice": "Toboggan",
	"snow": "Toboggan",
	"air": "Bird Helm",
	"fire": "Lava Helm",
}
const PORTAL_PAD_RADIUS := 5.0
const PORTAL_PAD_BLEND := 12.0

var _nx: int
var _nz: int
## _raw_height() at every grid vertex, computed once: characters query heights
## many times a frame, and the mesh build samples each vertex's neighbours.
var _heights := PackedFloat32Array()
var _hills := FastNoiseLite.new()
var _swell := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _water_lake := NaturalLake.new(LAKE_CENTER, LAKE_RADIUS, LAKE_EDGE_VARIATION, LAKE_DEPTH, LAKE_SHELF, 20260919)
var _frozen_lake := NaturalLake.new(ICE_CENTER, ICE_RADIUS, ICE_EDGE_VARIATION, ICE_LAKE_DEPTH, ICE_LEVEL, 20260920)
var _lava_pool := NaturalLake.new(LAVA_CENTER, LAVA_RADIUS, LAVA_EDGE_VARIATION, LAVA_DEPTH, LAVA_LEVEL + 0.3, 20260921)
## Detached kingdom terrains, sampled only (never added to the tree).
var _jungle_sampler: Node
var _ice_sampler: Node
var _rock_sampler: Node
var _plant_window: TerrainWindow
var _mountain_window: TerrainWindow
var _dirt_window: TerrainWindow


func _init() -> void:
	_hills.seed = CROSSROADS_HILL_SEED
	_hills.frequency = CROSSROADS_HILL_FREQUENCY
	_hills.fractal_octaves = 3
	_swell.seed = 20260922
	_swell.frequency = SWELL_FREQUENCY
	_swell.fractal_octaves = 2
	_jungle_sampler = JUNGLE_KINGDOM_TERRAIN.new()
	_ice_sampler = ICE_KINGDOM_TERRAIN.new()
	_rock_sampler = ROCK_GROUND_KINGDOM_TERRAIN.new()
	_plant_window = TerrainWindow.new(_jungle_sampler, PLANT_SOURCE, PLANT_CENTER, PLANT_HALF)
	var run := MOUNTAIN_SOURCE_RUN_END - MOUNTAIN_SOURCE_PEAK
	_mountain_window = TerrainWindow.new(
		_ice_sampler, MOUNTAIN_SOURCE_PEAK, MOUNTAIN_CENTER, Vector2.ZERO,
		MOUNTAIN_RADIUS, MOUNTAIN_SCALE, atan2(run.y, run.x), 45.0
	)
	_dirt_window = TerrainWindow.new(_rock_sampler, DIRT_SOURCE, DIRT_CENTER, DIRT_HALF, 0.0, 1.0, PI * 0.5)
	for window in [_plant_window, _mountain_window, _dirt_window]:
		(window as TerrainWindow).level_to_edge()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for sampler in [_jungle_sampler, _ice_sampler, _rock_sampler]:
			if is_instance_valid(sampler):
				(sampler as Node).free()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
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
	var start_distance := point.distance_to(START_CENTER)
	var height := _hills.get_noise_2d(x, z) * CROSSROADS_HILL_AMPLITUDE
	height += _swell.get_noise_2d(x, z) * SWELL_AMPLITUDE * smoothstep(START_FLATTEN_RADIUS + 20.0, START_FLATTEN_RADIUS + 80.0, start_distance)
	# The Crossroads' arrival clearing: genuinely level, hills returning only
	# through its soft outer transition.
	height *= smoothstep(START_FLATTEN_RADIUS, START_FLATTEN_RADIUS + START_FLATTEN_TRANSITION, start_distance)
	# Kingdom windows replace the valley ground within them.
	for window in [_plant_window, _mountain_window, _dirt_window]:
		var biome := window as TerrainWindow
		var weight := biome.weight(point)
		if weight > 0.0:
			height = lerpf(height, biome.height(point), weight)
	# Basins punched into the ground (NaturalLake).
	height = _water_lake.carve(height, point)
	height = _frozen_lake.carve(height, point)
	height = _lava_pool.carve(height, point)
	# Each gate's small level pad.
	for border in BORDERS:
		var pad := 1.0 - smoothstep(PORTAL_PAD_RADIUS, PORTAL_PAD_RADIUS + PORTAL_PAD_BLEND, point.distance_to(Vector2(float(border["x"]), 0.0)))
		height = lerpf(height, 0.0, pad)
	# Valley walls along both sides and at both ends.
	height += smoothstep(115.0, 165.0, absf(z)) * 34.0
	height += (1.0 - smoothstep(X_MIN + 20.0, -60.0, x)) * 34.0
	height += smoothstep(X_MAX - 50.0, X_MAX - 20.0, x) * 34.0
	return height


func _height_color(x: float, z: float, _height: float) -> Color:
	var point := Vector2(x, z)
	var color := CROSSROADS_GRASS
	for window in [_plant_window, _mountain_window, _dirt_window]:
		var biome := window as TerrainWindow
		var weight := biome.weight(point)
		if weight > 0.0:
			color = color.lerp(biome.color(point), weight)
	if _frozen_lake.coverage(point) > 0.12:
		return FROZEN_LAKEBED
	if point.distance_to(ICE_CENTER) < ICE_SNOWFIELD_RADIUS:
		color = color.lerp(SNOW, 1.0 - smoothstep(ICE_SNOWFIELD_RADIUS - 12.0, ICE_SNOWFIELD_RADIUS, point.distance_to(ICE_CENTER)))
	var lake_bank := 1.0 - smoothstep(LAKE_RADIUS + NaturalLake.BANK_WIDTH - 4.0, LAKE_RADIUS + NaturalLake.BANK_WIDTH + 8.0, point.distance_to(LAKE_CENTER))
	if lake_bank > 0.0:
		color = color.lerp(WASTELAND, lake_bank)
	var lava_bank := 1.0 - smoothstep(LAVA_RADIUS + NaturalLake.BANK_WIDTH - 4.0, LAVA_RADIUS + NaturalLake.BANK_WIDTH + 8.0, point.distance_to(LAVA_CENTER))
	if lava_bank > 0.0:
		var heat := 1.0 - smoothstep(LAVA_RADIUS, LAVA_RADIUS + NaturalLake.BANK_WIDTH, point.distance_to(LAVA_CENTER))
		color = color.lerp(BASALT.lerp(SCORCHED, heat), lava_bank)
	if x >= AIR_ZONE.x - 10.0 and x <= AIR_ZONE.y + 10.0:
		color = color.lerp(STONE, 0.7)
	if absf(z) > 125.0 or x < -70.0 or x > X_MAX - 60.0:
		color = STONE.lerp(color, 0.35)
	return color


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
	return _water_lake.coverage(pos) > 0.08 or _frozen_lake.coverage(pos) > 0.08


func get_lake_water_level() -> float:
	return WATER_LEVEL


func is_lava_area(pos: Vector2) -> bool:
	return _lava_pool.coverage(pos) > 0.08


func get_lava_surface_height(_pos: Vector2) -> float:
	return LAVA_LEVEL


## Up the bank, straight out from wherever the lava was entered.
func get_lava_escape_position(pos: Vector2) -> Vector3:
	var outward := pos - LAVA_CENTER
	if outward.length_squared() < 0.01:
		outward = Vector2(-1.0, 0.0)
	outward = outward.normalized()
	var escape := LAVA_CENTER + outward * (_lava_pool.edge_radius(outward) + 6.0)
	return Vector3(escape.x, get_mesh_height(escape.x, escape.y), escape.y)


## As in the Ice Kingdom: inside the drawn ice, and only where the terrain has
## actually descended to the sheet, so the ice hidden under the bank never
## turns snow into a skating surface.
func is_ice_surface(pos: Vector2) -> bool:
	return _frozen_lake.is_within_surface(pos) and get_mesh_height(pos.x, pos.y) <= ICE_SURFACE_LEVEL + 0.06


func get_ice_level() -> float:
	return ICE_SURFACE_LEVEL


## Snow terrain: the mountain (the Ice Kingdom's own snow), and the snowfield
## around the frozen lake. This is also what the snowboard rides; nothing else
## is snow.
func is_snow_footstep_surface(pos: Vector2) -> bool:
	if _mountain_window.weight(pos) > 0.3:
		return true
	return pos.distance_to(ICE_CENTER) < ICE_SNOWFIELD_RADIUS and not is_ice_surface(pos) and not is_lake_area(pos)


func is_safe_zone(pos: Vector2) -> bool:
	return pos.distance_to(START_CENTER) < START_FLATTEN_RADIUS + 30.0


func is_nme_hazard(pos: Vector2) -> bool:
	return is_lava_area(pos)


func get_start_point() -> Vector3:
	return Vector3(START_CENTER.x, get_mesh_height(START_CENTER.x, START_CENTER.y), START_CENTER.y)


## A point on the ground at `x` along the path, offset `z` across it.
func get_path_point(x: float, z: float = 0.0) -> Vector3:
	return Vector3(x, get_mesh_height(x, z), z)


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


## Liquid surfaces. Water and lava are not solid (swimming and lava contact are
## gameplay queries above); the frozen lake's ice sheet and edge are.
func _build_liquid_surfaces() -> void:
	_water_lake.build_water(self, WATER_LEVEL)
	_frozen_lake.build_frozen(self, ICE_SURFACE_LEVEL, ICE_THICKNESS, WATER_LEVEL)
	_lava_pool.build_surface(self, "Lava", LAVA_LEVEL, NatureProps.build_lava_material())


# ---- Scenery -------------------------------------------------------------------
# The plant grove's jungle is the Primate Kingdom's own foliage scatter in
# window mode (see demo_world.gd's Scatter node), not placed here.

func _scatter_scenery() -> void:
	_scatter_shores()
	_scatter_mountain()
	_scatter_snowfield()
	_scatter_dirt_track()
	_scatter_air_spires()


func _place(node: Node3D, x: float, z: float) -> void:
	node.position = Vector3(x, get_mesh_height(x, z), z)
	add_child(node)


func _scatter_shores() -> void:
	for index in 12:
		var angle := _rng.randf_range(0.0, TAU)
		var radius := LAKE_RADIUS + _rng.randf_range(10.0, 20.0)
		var x := LAKE_CENTER.x + cos(angle) * radius
		var z := LAKE_CENTER.y + sin(angle) * radius
		if absf(z) < 6.0:
			continue
		_place(NatureProps.build_rock(_rng.randf_range(0.6, 1.6)), x, z)
	for index in 16:
		var angle := _rng.randf_range(0.0, TAU)
		var radius := LAVA_RADIUS + _rng.randf_range(8.0, 18.0)
		var x := LAVA_CENTER.x + cos(angle) * radius
		var z := LAVA_CENTER.y + sin(angle) * radius
		if absf(z) < 6.0:
			continue
		_place(NatureProps.build_rock(_rng.randf_range(0.8, 2.2), true, BASALT.lightened(0.15)), x, z)


## The Ice Kingdom's own mountain scatter rules (its _scatter_snow_mountain()):
## an annulus of rocks (every third) and frost-grey snow pines, never on the
## authored run. Its 160 attempts cover its full-size mountain; shrunk by
## MOUNTAIN_SCALE, the same ground density takes 160 / scale^2 attempts.
func _scatter_mountain() -> void:
	var attempts := int(round(160.0 / (MOUNTAIN_SCALE * MOUNTAIN_SCALE)))
	for index in attempts:
		var angle := _rng.randf_range(0.0, TAU)
		var source_radius := _rng.randf_range(95.0, 560.0 * 0.86)
		var source := MOUNTAIN_SOURCE_PEAK + Vector2(cos(angle), sin(angle)) * source_radius
		if float(_ice_sampler.ski_route_distance(source.x, source.y)) < 42.0:
			continue
		var point := _mountain_window.to_target(source)
		if _mountain_window.weight(point) < 0.8 or absf(point.y) > 105.0:
			continue
		var prop: Node3D
		if index % 3 == 0:
			prop = NatureProps.build_rock(_rng.randf_range(0.7, 2.2), true)
		else:
			prop = NatureProps.build_pine_tree(
				_rng.randf_range(4.5, 9.5), Color(0.67, 0.78, 0.82).lerp(Color(0.88, 0.94, 0.96), _rng.randf())
			)
		prop.rotation.y = _rng.randf_range(0.0, TAU)
		_place(prop, point.x, point.y)


## The frozen lake's snowfield, dressed like the Ice Kingdom's snow forest:
## snow pines with a tall alpine cedar for roughly every five.
func _scatter_snowfield() -> void:
	for index in 24:
		var angle := _rng.randf_range(0.0, TAU)
		var point := ICE_CENTER + Vector2(cos(angle), sin(angle)) * _rng.randf_range(ICE_RADIUS + 12.0, ICE_SNOWFIELD_RADIUS)
		if absf(point.y) < 14.0 or absf(point.y) > 105.0 or is_lake_area(point):
			continue
		var tree: Node3D
		if index % 5 == 0:
			tree = NatureProps.build_alpine_cedar_tree(_rng.randf_range(16.0, 24.0), SNOW)
		else:
			tree = NatureProps.build_pine_tree(_rng.randf_range(5.5, 11.0), SNOW)
		tree.rotation.y = _rng.randf_range(0.0, TAU)
		_place(tree, point.x, point.y)


## The Rock/Ground Kingdom's own tilted-slab rock ramps along the canyon floor
## and beside the path, rising east, for dirtbike launches.
func _scatter_dirt_track() -> void:
	var ramp_x := DIRT_CENTER.x - DIRT_HALF.x + 30.0
	var lanes: Array[float] = [0.0, -18.0, 18.0]
	while ramp_x < DIRT_CENTER.x + DIRT_HALF.x - 30.0:
		var lane: float = lanes[_rng.randi() % lanes.size()]
		var ramp := NatureProps.build_rock_ramp(_rng.randf_range(4.0, 6.0), _rng.randf_range(5.0, 8.0), _rng.randf_range(1.2, 2.4))
		# The ramp rises along its local +Z; aim that east along the track.
		ramp.rotation.y = PI * 0.5
		_place(ramp, ramp_x, lane)
		ramp_x += _rng.randf_range(20.0, 32.0)


## Tall stone spires to fly between and land on.
func _scatter_air_spires() -> void:
	for index in 14:
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var x := _rng.randf_range(AIR_ZONE.x, AIR_ZONE.y)
		var z := side * _rng.randf_range(8.0, 95.0)
		_place(NatureProps.build_rock_spire(_rng.randf_range(2.2, 4.2), _rng.randi_range(4, 8), _rng), x, z)
	for index in 3:
		var x := AIR_ZONE.x + 30.0 + float(index) * 38.0
		_place(NatureProps.build_rock_spire(_rng.randf_range(3.0, 4.5), _rng.randi_range(7, 10), _rng), x, _rng.randf_range(-4.0, 4.0))
