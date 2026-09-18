class_name DemoWorldTerrain
extends StaticBody3D

## The demo world: one long valley running east (+X) through a biome for every
## blorb suit with a clear traversal power, a real biome simulator. Where a
## biome exists elsewhere in the game, this shows that biome itself through a
## TerrainWindow onto the real kingdom's terrain (its own height and colour
## functions), rather than an imitation:
##   clearing  - the Crossroads' own hills, spawn flattening and grass
##   forest    - the Crossroads' grass plains with its own forest clusters
##   plant     - a patch of the Primate Kingdom's jungle, 1:1
##   snow      - the Ice Kingdom's snowboard mountain and the ranges around
##               it, full size, turned so its authored run descends east
##   ground    - a strip across the Rock/Ground Kingdom's terraces, washes
##               and halfpipe canyon, climbing as it goes
##   fire      - a full-size Fire Kingdom volcano with its lava-filled mouth
## The long lake and the long frozen lake are stretched NaturalLake basins
## (the game's own lake technique). Through the ground zone the course climbs
## to cloud height (see _course_elevation()); the sky zone is a cliff edge
## over a deep chasm, flown across through the clouds to the volcanic lowland
## beyond. Between biomes the ground keeps the Crossroads' hills with a slow
## swell, so nowhere is flat except the clearing and each gate's small pad.
## One heightfield owns rendering, collision and every gameplay height query.
##
## Every zone's length is a constant below, meant to be tuned by feel.

const JUNGLE_KINGDOM_TERRAIN := preload("res://scripts/jungle_kingdom_terrain.gd")
const ICE_KINGDOM_TERRAIN := preload("res://scripts/ice_kingdom_terrain.gd")
const ROCK_GROUND_KINGDOM_TERRAIN := preload("res://scripts/rock_ground_kingdom_terrain.gd")
const FIRE_KINGDOM_TERRAIN := preload("res://scripts/fire_kingdom_terrain.gd")

const X_MIN := -140.0
const X_MAX := 7090.0
const Z_HALF := 170.0
const SPACING := 5.0
## Windows that span the valley's full width extend this far across it, so
## their sides stay inside the kingdom and only their ends blend.
const FULL_WIDTH_HALF := 220.0
const WINDOW_END_BLEND := 60.0

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

## Forest: the Crossroads' own grass plains, dressed with that world's forest
## clusters (its tree species, undergrowth and pickable meadows) densely
## enough to read as woodland, and home to wild shiny blorbs (see
## demo_world.gd). Still the Normal suit's ground: shiny blorbs have no suit
## power of their own yet.
const FOREST_ZONE := Vector2(95.0, 440.0)
const FOREST_CLUSTERS := 26

## Plant: the Primate Kingdom around this point, clear of its village and river.
const PLANT_SOURCE := Vector2(-150.0, -170.0)
const PLANT_CENTER := Vector2(620.0, 0.0)
const PLANT_HALF := Vector2(150.0, 110.0)

## Water and ice share WATER_LEVEL: the terrain reports one water level for
## the whole world, and the frozen lake's water lies beneath its ice at that
## same level, exactly as the Ice Kingdom layers them.
const WATER_LEVEL := -7.0
## The long lake: LAKE_RADIUS wide, LAKE_RADIUS * LAKE_STRETCH long each way.
const LAKE_CENTER := Vector2(1311.0, 0.0)
const LAKE_RADIUS := 60.0
const LAKE_STRETCH := 6.0
const LAKE_EDGE_VARIATION := 9.0
const LAKE_DEPTH := 14.0
## An open lake's bank levels out just above the water: a narrow beach.
const LAKE_SHELF := WATER_LEVEL + 0.35
## The Crossroads lake lies in bare wasteland; its banks take that colour.
const WASTELAND := Color(0.565, 0.495, 0.4)

## The long frozen lake.
const ICE_CENTER := Vector2(2557.0, 0.0)
const ICE_RADIUS := 70.0
const ICE_STRETCH := 7.5
const ICE_EDGE_VARIATION := 9.0
const ICE_LAKE_DEPTH := 8.0
## The Ice Kingdom's layering: bank shelf, the ice skin 3 cm beneath it (so the
## shore occludes the ice edge), a 0.38 m sheet, and the water under it.
const ICE_LEVEL := WATER_LEVEL + 0.45
const ICE_SURFACE_LEVEL := ICE_LEVEL - 0.03
const ICE_THICKNESS := 0.38
## The frozen lake's surroundings are snowfield, as in the Ice Kingdom: a ring
## this far (in the lake's own shape space) beyond its shore.
const ICE_SNOWFIELD_WIDTH := 38.0
const FROZEN_LAKEBED := Color(0.48, 0.62, 0.72)
## Canonical snow: the same white as snow blorbs, boards and snowfields.
const SNOW := Color(0.94, 0.96, 0.98)

## Snow: the Ice Kingdom's mountain at full size. Its authored run descends
## from the peak toward (-205, -102); the window turns that direction east.
## The climb comes from the west, MOUNTAIN_CLIMB before the peak; the run
## goes MOUNTAIN_RUN beyond it. Behind the peak the kingdom rises into its
## border ranges, so the western end blends in over MOUNTAIN_END_BLEND: a long
## climb averaging ~24 degrees rather than a wall.
const MOUNTAIN_SOURCE_PEAK := Vector2(-790.0, -330.0)
const MOUNTAIN_SOURCE_RUN_END := Vector2(-205.0, -102.0)
const MOUNTAIN_START_X := 3290.0
const MOUNTAIN_CLIMB := 650.0
const MOUNTAIN_RUN := 700.0
const MOUNTAIN_END_BLEND := 450.0

## Ground: an east-west strip across the Rock/Ground Kingdom at z = 150,
## kept inside its border ranges: over terraces, through the town's flat
## shelf, across a wash, and side to side over its western halfpipe canyon.
const DIRT_SOURCE := Vector2(0.0, 150.0)
const DIRT_START_X := 4665.0
const DIRT_LENGTH := 840.0

## The course climbs across the ground zone to SKY_HEIGHT, near the clouds
## (the Clouds node's layer), holds there to the cliff edge, then plunges to
## CHASM_FLOOR. The far wall rises back to 0 at the volcanic lowland.
const SKY_HEIGHT := 110.0
const CLIFF_EDGE_X := 5550.0
const CHASM_FLOOR := -60.0
const CHASM_FAR_WALL_X := 6230.0
const CLIFF_FACE_WIDTH := 25.0

## Fire: a full-size Fire Kingdom volcano, its lava-filled mouth centred in a
## window of that kingdom's volcanic lowland.
const VOLCANO_SOURCE_POOL := Vector2(-190.0, -145.0)
const VOLCANO_CENTER := Vector2(6652.0, 0.0)
const VOLCANO_HALF_LENGTH := 360.0

const STONE := Color(0.52, 0.5, 0.47)
const CLIFF_ROCK := Color(0.42, 0.4, 0.38)

## Every border gate, west to east: the biome on either side of it.
## Each biome's portal stands on the side you enter it from, facing you (see
## demo_world.gd). The first gate's western side is the hero's starting pair
## of Normal blorbs (element ""). Every gate stands on the path (z = 0) on a
## small level pad, clear of lake banks and windows.
const BORDERS := [
	{"x": 460.0, "west": "", "east": "plant"},
	{"x": 790.0, "west": "plant", "east": "water"},
	{"x": 1835.0, "west": "water", "east": "ice"},
	{"x": 3280.0, "west": "ice", "east": "snow"},
	{"x": 4655.0, "west": "snow", "east": "ground"},
	{"x": 5520.0, "west": "ground", "east": "air"},
	{"x": 6275.0, "west": "air", "east": "fire"},
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
var _water_lake := NaturalLake.new(LAKE_CENTER, LAKE_RADIUS, LAKE_EDGE_VARIATION, LAKE_DEPTH, LAKE_SHELF, 20260919, LAKE_STRETCH)
var _frozen_lake := NaturalLake.new(ICE_CENTER, ICE_RADIUS, ICE_EDGE_VARIATION, ICE_LAKE_DEPTH, ICE_LEVEL, 20260920, ICE_STRETCH)
## Detached kingdom terrains, sampled only (never added to the tree).
var _jungle_sampler: Node
var _ice_sampler: Node
var _rock_sampler: Node
var _fire_sampler: Node
var _plant_window: TerrainWindow
var _mountain_window: TerrainWindow
var _dirt_window: TerrainWindow
var _volcano_window: TerrainWindow
var _windows: Array[TerrainWindow] = []
## The volcano's lava surface height in this world (its window-levelled mouth).
var _volcano_lava_level := 0.0


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
	_fire_sampler = FIRE_KINGDOM_TERRAIN.new()
	_plant_window = TerrainWindow.new(_jungle_sampler, PLANT_SOURCE, PLANT_CENTER, PLANT_HALF)
	_plant_window.level_to_edge()
	# The mountain window's centre sits partway down the run, so the peak falls
	# MOUNTAIN_CLIMB in from its western end.
	var run := (MOUNTAIN_SOURCE_RUN_END - MOUNTAIN_SOURCE_PEAK).normalized()
	var mountain_half := (MOUNTAIN_CLIMB + MOUNTAIN_RUN) * 0.5
	var peak_to_center := mountain_half - MOUNTAIN_CLIMB
	_mountain_window = TerrainWindow.new(
		_ice_sampler, MOUNTAIN_SOURCE_PEAK + run * peak_to_center,
		Vector2(MOUNTAIN_START_X + mountain_half, 0.0), Vector2(mountain_half, FULL_WIDTH_HALF),
		0.0, 1.0, atan2(run.y, run.x), MOUNTAIN_END_BLEND
	)
	_mountain_window.level_to_x_ends(100.0)
	_dirt_window = TerrainWindow.new(
		_rock_sampler, DIRT_SOURCE, Vector2(DIRT_START_X + DIRT_LENGTH * 0.5, 0.0),
		Vector2(DIRT_LENGTH * 0.5, FULL_WIDTH_HALF), 0.0, 1.0, 0.0, WINDOW_END_BLEND
	)
	_dirt_window.level_to_x_ends(100.0)
	_volcano_window = TerrainWindow.new(
		_fire_sampler, VOLCANO_SOURCE_POOL, VOLCANO_CENTER,
		Vector2(VOLCANO_HALF_LENGTH, FULL_WIDTH_HALF), 0.0, 1.0, 0.0, WINDOW_END_BLEND
	)
	_volcano_window.level_to_x_ends(100.0)
	_volcano_lava_level = FIRE_KINGDOM_TERRAIN.VOLCANO_LAVA_SURFACE_Y - _volcano_window.height_offset
	_windows = [_plant_window, _mountain_window, _dirt_window, _volcano_window]


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for sampler in [_jungle_sampler, _ice_sampler, _rock_sampler, _fire_sampler]:
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

## The course's base elevation along the valley: level to the ground zone,
## climbing through it to SKY_HEIGHT, level to the cliff edge, down the cliff
## face to the chasm floor, and up the far wall to the volcanic lowland.
func _course_elevation(x: float) -> float:
	var dirt_end := DIRT_START_X + DIRT_LENGTH
	var elevation := SKY_HEIGHT * clampf((x - DIRT_START_X) / DIRT_LENGTH, 0.0, 1.0)
	if x > dirt_end:
		elevation = SKY_HEIGHT
	if x > CLIFF_EDGE_X:
		elevation = lerpf(SKY_HEIGHT, CHASM_FLOOR, smoothstep(CLIFF_EDGE_X, CLIFF_EDGE_X + CLIFF_FACE_WIDTH, x))
	if x > CHASM_FAR_WALL_X:
		elevation = lerpf(CHASM_FLOOR, 0.0, smoothstep(CHASM_FAR_WALL_X, CHASM_FAR_WALL_X + CLIFF_FACE_WIDTH, x))
	return elevation


func _raw_height(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var start_distance := point.distance_to(START_CENTER)
	var height := _hills.get_noise_2d(x, z) * CROSSROADS_HILL_AMPLITUDE
	height += _swell.get_noise_2d(x, z) * SWELL_AMPLITUDE * smoothstep(START_FLATTEN_RADIUS + 20.0, START_FLATTEN_RADIUS + 80.0, start_distance)
	# The Crossroads' arrival clearing: genuinely level, hills returning only
	# through its soft outer transition.
	height *= smoothstep(START_FLATTEN_RADIUS, START_FLATTEN_RADIUS + START_FLATTEN_TRANSITION, start_distance)
	# Kingdom windows replace the valley ground within them.
	for biome in _windows:
		var weight := biome.weight(point)
		if weight > 0.0:
			height = lerpf(height, biome.height(point), weight)
	# Basins punched into the ground (NaturalLake).
	height = _water_lake.carve(height, point)
	height = _frozen_lake.carve(height, point)
	var elevation := _course_elevation(x)
	height += elevation
	# Each gate's small level pad, at the course's elevation there.
	for border in BORDERS:
		var border_x: float = border["x"]
		var pad := 1.0 - smoothstep(PORTAL_PAD_RADIUS, PORTAL_PAD_RADIUS + PORTAL_PAD_BLEND, point.distance_to(Vector2(border_x, 0.0)))
		height = lerpf(height, _course_elevation(border_x), pad)
	# Valley walls along both sides and at both ends.
	height += smoothstep(115.0, 165.0, absf(z)) * 34.0
	height += (1.0 - smoothstep(X_MIN + 20.0, -60.0, x)) * 34.0
	height += smoothstep(X_MAX - 50.0, X_MAX - 20.0, x) * 34.0
	return height


func _height_color(x: float, z: float, _height: float) -> Color:
	var point := Vector2(x, z)
	var color := CROSSROADS_GRASS
	for biome in _windows:
		var weight := biome.weight(point)
		if weight > 0.0:
			color = color.lerp(biome.color(point), weight)
	if _frozen_lake.coverage(point) > 0.12:
		return FROZEN_LAKEBED
	var snowfield := 1.0 - smoothstep(ICE_RADIUS + ICE_SNOWFIELD_WIDTH - 12.0, ICE_RADIUS + ICE_SNOWFIELD_WIDTH, _frozen_lake.local_distance(point))
	if snowfield > 0.0:
		color = color.lerp(SNOW, snowfield)
	var lake_bank := 1.0 - smoothstep(LAKE_RADIUS + NaturalLake.BANK_WIDTH - 4.0, LAKE_RADIUS + NaturalLake.BANK_WIDTH + 8.0, _water_lake.local_distance(point))
	if lake_bank > 0.0:
		color = color.lerp(WASTELAND, lake_bank)
	# The high course before the cliff, the cliff and the chasm: bare rock.
	var rock := smoothstep(DIRT_START_X + DIRT_LENGTH - 20.0, DIRT_START_X + DIRT_LENGTH + 10.0, x) * (1.0 - smoothstep(CHASM_FAR_WALL_X + CLIFF_FACE_WIDTH, CHASM_FAR_WALL_X + CLIFF_FACE_WIDTH + 30.0, x))
	if rock > 0.0:
		color = color.lerp(CLIFF_ROCK, rock)
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


## The volcano's lava-filled mouth, as in the Fire Kingdom.
func is_lava_area(pos: Vector2) -> bool:
	return pos.distance_to(VOLCANO_CENTER) < FIRE_KINGDOM_TERRAIN.LAVA_MOUTH_RADIUS


func get_lava_surface_height(_pos: Vector2) -> float:
	return _volcano_lava_level


## Out over the rim, straight out from wherever the lava was entered.
func get_lava_escape_position(pos: Vector2) -> Vector3:
	var outward := pos - VOLCANO_CENTER
	if outward.length_squared() < 0.01:
		outward = Vector2(-1.0, 0.0)
	var escape := VOLCANO_CENTER + outward.normalized() * (FIRE_KINGDOM_TERRAIN.LAVA_MOUTH_RADIUS + 10.0)
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
	return _frozen_lake.local_distance(pos) < ICE_RADIUS + ICE_SNOWFIELD_WIDTH and not is_ice_surface(pos) and not is_lake_area(pos)


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


## Longest stretch of valley one render chunk covers. Chunks let the renderer
## skip whatever is off screen, and let each biome keep its own material.
const CHUNK_LENGTH := 300.0


## Each biome's own terrain material, as its world builds it: the Crossroads
## and Primate Kingdom shade ground like their foliage (fully metallic, fully
## rough); the Ice, Rock/Ground and Fire Kingdoms use plain diffuse ground.
## Keyed by the x at which each takes over, west to east.
func _terrain_materials() -> Array:
	return [
		[X_MIN, _terrain_material(1.0, 1.0)],                      # clearing, forest, plant, lake
		[float(BORDERS[2]["x"]), _terrain_material(0.0, 0.88)],    # ice, snow
		[float(BORDERS[4]["x"]), _terrain_material(0.0, 0.94)],    # ground, sky cliff
		[float(BORDERS[6]["x"]), _terrain_material(0.0, 0.96)],    # fire
	]


func _terrain_material(metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = metallic
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## The terrain renders as chunks along the valley (each sharing its edge
## column with the next, so there are no seams), and collides as one shape.
func _build_mesh_and_collision() -> void:
	var materials := _terrain_materials()
	var cuts: Array[int] = [0]
	for entry in materials.slice(1):
		cuts.append(clampi(int(round((float(entry[0]) - X_MIN) / SPACING)), 1, _nx - 2))
	cuts.append(_nx - 1)
	var faces := PackedVector3Array()
	for material_index in cuts.size() - 1:
		var section_start := cuts[material_index]
		var section_end := cuts[material_index + 1]
		var step := maxi(int(CHUNK_LENGTH / SPACING), 1)
		var chunk_start := section_start
		while chunk_start < section_end:
			var chunk_end := mini(chunk_start + step, section_end)
			faces.append_array(_build_chunk(chunk_start, chunk_end, materials[material_index][1]))
			chunk_start = chunk_end
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)


## One render chunk over grid columns ix0..ix1 (inclusive). Returns its
## triangles for the shared collider.
func _build_chunk(ix0: int, ix1: int, material: Material) -> PackedVector3Array:
	var faces := PackedVector3Array()
	var columns := ix1 - ix0 + 1
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in _nz:
		for ix in range(ix0, ix1 + 1):
			var vertex := _grid_vertex(ix, iz)
			tool.set_color(_height_color(vertex.x, vertex.z, vertex.y))
			tool.set_normal(get_mesh_normal(vertex.x, vertex.z))
			tool.add_vertex(vertex)
	for iz in _nz - 1:
		for local_x in columns - 1:
			var i0: int = iz * columns + local_x
			for index in [i0, i0 + columns, i0 + 1, i0 + 1, i0 + columns, i0 + columns + 1]:
				tool.add_index(index)
			var ix := ix0 + local_x
			var a := _grid_vertex(ix, iz)
			var b := _grid_vertex(ix + 1, iz)
			var c := _grid_vertex(ix, iz + 1)
			var d := _grid_vertex(ix + 1, iz + 1)
			for vertex in [a, c, b, b, c, d]:
				faces.append(vertex)
	tool.set_material(material)
	var chunk := MeshInstance3D.new()
	chunk.name = "TerrainChunk_%d" % ix0
	chunk.mesh = tool.commit()
	add_child(chunk)
	return faces


## Liquid surfaces. Water and lava are not solid (swimming and lava contact are
## gameplay queries above); the frozen lake's ice sheet and edge are.
func _build_liquid_surfaces() -> void:
	_water_lake.build_water(self, WATER_LEVEL)
	_frozen_lake.build_frozen(self, ICE_SURFACE_LEVEL, ICE_THICKNESS, WATER_LEVEL)
	_build_volcano_lava()


## The volcano's mouth filled with lava and lit from within, exactly as the
## Fire Kingdom builds each of its own (its _build_lava_pools()).
func _build_volcano_lava() -> void:
	var radius: float = FIRE_KINGDOM_TERRAIN.LAVA_MOUTH_RADIUS
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in 64:
		var a0 := TAU * float(index) / 64.0
		var a1 := TAU * float(index + 1) / 64.0
		for vertex in [
			Vector3(VOLCANO_CENTER.x, _volcano_lava_level, VOLCANO_CENTER.y),
			Vector3(VOLCANO_CENTER.x + cos(a1) * radius, _volcano_lava_level, VOLCANO_CENTER.y + sin(a1) * radius),
			Vector3(VOLCANO_CENTER.x + cos(a0) * radius, _volcano_lava_level, VOLCANO_CENTER.y + sin(a0) * radius),
		]:
			tool.add_vertex(vertex)
	tool.set_material(NatureProps.build_lava_material())
	var lava := MeshInstance3D.new()
	lava.name = "VolcanoLava"
	lava.mesh = tool.commit()
	add_child(lava)
	CollisionPolicy.mark_hazard(lava)
	var glow := OmniLight3D.new()
	glow.position = Vector3(VOLCANO_CENTER.x, _volcano_lava_level + 2.0, VOLCANO_CENTER.y)
	glow.light_color = Color(1.0, 0.36, 0.08)
	glow.light_energy = 2.2
	glow.omni_range = 65.0
	add_child(glow)


# ---- Scenery -------------------------------------------------------------------
# The plant grove's jungle is the Primate Kingdom's own foliage scatter in
# window mode (see demo_world.gd's Scatter node), not placed here.

func _scatter_scenery() -> void:
	_scatter_forest()
	_scatter_lake_shore()
	_scatter_mountain()
	_scatter_snowfield()
	_scatter_dirt_track()
	_scatter_volcanic_rocks()


func _place(node: Node3D, x: float, z: float) -> void:
	node.position = Vector3(x, get_mesh_height(x, z), z)
	add_child(node)


func _on_path(point: Vector2) -> bool:
	return absf(point.y) < 8.0 or absf(point.y) > 108.0


## The Crossroads' own forest clusters (wilderness_scatter.gd's
## _forest_cluster()/_meadow_cluster() and their builders): round and pine
## trees in that world's leaf colours with mushrooms, bushes and grass tufts
## beneath, and meadows of pickable flowers. Weighted toward forest so the
## plains read as woodland.
func _scatter_forest() -> void:
	var trees := [
		func(): return NatureProps.build_round_tree(6.5, NatureProps.TREE_LEAF_COLORS[0]),
		func(): return NatureProps.build_round_tree(7.2, NatureProps.TREE_LEAF_COLORS[1]),
		func(): return NatureProps.build_round_tree(5.6, NatureProps.TREE_LEAF_COLORS[2]),
		func(): return NatureProps.build_round_tree(6.9, NatureProps.TREE_LEAF_COLORS[3]),
		func(): return NatureProps.build_pine_tree(7.6, NatureProps.TREE_LEAF_COLORS[1]),
		func(): return NatureProps.build_pine_tree(6.8, NatureProps.TREE_LEAF_COLORS[3]),
	]
	var undergrowth := [
		func(): return _mushroom("Red Mushroom"),
		func(): return _mushroom("Tan Mushroom"),
		func(): return NatureProps.build_bush(),
		func(): return NatureProps.build_grass_tuft(),
	]
	var meadow := [
		func(): return _flower("Red Flower"),
		func(): return _flower("Yellow Flower"),
		func(): return _flower("Purple Flower"),
		func(): return NatureProps.build_grass_tuft(),
		func(): return NatureProps.build_grass_tuft(Color(0.1, 0.65, 0.55)),
	]
	for cluster in FOREST_CLUSTERS:
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		var center := Vector2(_rng.randf_range(FOREST_ZONE.x + 15.0, FOREST_ZONE.y - 15.0), side * _rng.randf_range(12.0, 95.0))
		var is_meadow := _rng.randf() < 0.25
		var radius := _rng.randf_range(8.0, 16.0) if is_meadow else _rng.randf_range(12.0, 26.0)
		var count := int(_rng.randf_range(12, 26)) if is_meadow else int(_rng.randf_range(8, 18))
		for index in count:
			var point := center + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * radius * sqrt(_rng.randf())
			if _on_path(point):
				continue
			var builders: Array = meadow if is_meadow else trees
			var prop: Node3D = (builders[_rng.randi() % builders.size()] as Callable).call()
			prop.rotation.y = _rng.randf_range(0.0, TAU)
			_place(prop, point.x, point.y)
		if not is_meadow:
			for index in int(_rng.randf_range(4, 10)):
				var point := center + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * radius * 0.8 * sqrt(_rng.randf())
				if _on_path(point):
					continue
				var decor: Node3D = (undergrowth[_rng.randi() % undergrowth.size()] as Callable).call()
				_place(decor, point.x, point.y)


func _flower(flower_name: String) -> FlowerPickup:
	var pickup := FlowerPickup.new()
	pickup.flower_name = flower_name
	pickup.petal_color = NatureProps.FLOWER_COLORS[flower_name]
	return pickup


func _mushroom(mushroom_name: String) -> MushroomPickup:
	var pickup := MushroomPickup.new()
	pickup.mushroom_name = mushroom_name
	pickup.cap_color = NatureProps.MUSHROOM_COLORS[mushroom_name]
	return pickup


func _scatter_lake_shore() -> void:
	for index in 40:
		var point := _water_lake.point_on_ring(_rng.randf_range(0.0, TAU), LAKE_RADIUS + _rng.randf_range(10.0, 22.0))
		if _on_path(point):
			continue
		_place(NatureProps.build_rock(_rng.randf_range(0.6, 1.6)), point.x, point.y)


## The Ice Kingdom's own mountain scatter rules (its _scatter_snow_mountain()):
## an annulus of rocks (every third) and frost-grey snow pines around the
## peak, never on the authored run, at that kingdom's full-size density.
func _scatter_mountain() -> void:
	for index in 160:
		var angle := _rng.randf_range(0.0, TAU)
		var source := MOUNTAIN_SOURCE_PEAK + Vector2(cos(angle), sin(angle)) * _rng.randf_range(95.0, 560.0 * 0.86)
		if float(_ice_sampler.ski_route_distance(source.x, source.y)) < 42.0:
			continue
		var point := _mountain_window.to_target(source)
		if _mountain_window.weight(point) < 0.8 or _on_path(point):
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
	for index in 80:
		var point := _frozen_lake.point_on_ring(_rng.randf_range(0.0, TAU), ICE_RADIUS + _rng.randf_range(12.0, ICE_SNOWFIELD_WIDTH))
		if _on_path(point) or is_lake_area(point):
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
	var ramp_x := DIRT_START_X + 40.0
	var lanes: Array[float] = [0.0, -18.0, 18.0]
	while ramp_x < DIRT_START_X + DIRT_LENGTH - 40.0:
		var lane: float = lanes[_rng.randi() % lanes.size()]
		var ramp := NatureProps.build_rock_ramp(_rng.randf_range(4.0, 6.0), _rng.randf_range(5.0, 8.0), _rng.randf_range(1.2, 2.4))
		# The ramp rises along its local +Z; aim that east along the track.
		ramp.rotation.y = PI * 0.5
		_place(ramp, ramp_x, lane)
		ramp_x += _rng.randf_range(20.0, 32.0)


## Scattered basalt around the volcano's skirt, in the Fire Kingdom's rock tone.
func _scatter_volcanic_rocks() -> void:
	for index in 40:
		var angle := _rng.randf_range(0.0, TAU)
		var radius := _rng.randf_range(FIRE_KINGDOM_TERRAIN.LAVA_RIM_END_RADIUS * 0.6, VOLCANO_HALF_LENGTH - 40.0)
		var point := VOLCANO_CENTER + Vector2(cos(angle), sin(angle)) * radius
		if _on_path(point):
			continue
		_place(NatureProps.build_rock(_rng.randf_range(0.8, 2.6), true, Color(0.14, 0.12, 0.11)), point.x, point.y)
