class_name DemoWorldTerrain
extends StaticBody3D

## The demo world: one long valley running east (+X) through a biome for every
## blorb suit with a clear traversal power, a real biome simulator. Where a
## biome exists elsewhere in the game, this shows that biome itself through a
## TerrainWindow onto the real kingdom's terrain (its own height and colour
## functions), rather than an imitation:
##   normal    - a flat-floored pit punched into the Crossroads' own clearing,
##               climbed out of by bouncing on blorbs up rock ledges
##   shiny     - the Crossroads' grass plains with its own forest clusters
##   plant     - a patch of the Primate Kingdom's jungle, 1:1
##   ice       - a frozen lake from its portal to the mountain's foot, then
##               the mountain's steep western face up to the summit
##   snow      - an explicit snowboard course winding from the summit down
##               the mountain's long eastern flank to its foot
##   ground    - a strip across the Rock/Ground Kingdom's terraces, washes
##               and halfpipe canyon, climbing as it goes
##   fire      - a full-size Fire Kingdom volcano with its lava-filled mouth
## The long lake and the long frozen lake are NaturalLake channels (the game's
## own lake technique), each running from its biome's portal to the next
## border. Through the ground zone the course climbs
## to cloud height (see _course_elevation()); the sky zone is a cliff edge
## over a deep chasm, flown across through the clouds to the volcanic lowland
## beyond. Between biomes the ground keeps the Crossroads' hills with a slow
## swell, so nowhere is flat except the pit floor, its rim and each gate's pad.
## One heightfield owns rendering, collision and every gameplay height query.
##
## Every zone's length is a constant below, meant to be tuned by feel.

const JUNGLE_KINGDOM_TERRAIN := preload("res://scripts/jungle_kingdom_terrain.gd")
const ROCK_GROUND_KINGDOM_TERRAIN := preload("res://scripts/rock_ground_kingdom_terrain.gd")
const FIRE_KINGDOM_TERRAIN := preload("res://scripts/fire_kingdom_terrain.gd")
const OCEAN_KINGDOM_TERRAIN := preload("res://scripts/ocean_kingdom_terrain.gd")

const X_MIN := -140.0
const X_MAX := 6608.0
const Z_HALF := 300.0
## The valley floor runs VALLEY_HALF_WIDTH either side of the path before its
## walls rise, widening to OCEAN_HALF_WIDTH through the water zone's sea.
const VALLEY_HALF_WIDTH := 115.0
const OCEAN_HALF_WIDTH := 240.0
const VALLEY_WALL_RISE := 50.0
const VALLEY_WALL_HEIGHT := 34.0
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
## The clearing is level out to here: the pit's rim stands on it.
const START_FLATTEN_RADIUS := 60.0
const START_FLATTEN_TRANSITION := 12.0
## Normal: the hero wakes on the flat floor of a pit PIT_DEPTH deep, punched
## into the clearing. Its wall rises from PIT_FLOOR_RADIUS to PIT_RIM_RADIUS,
## too steep to walk. Only two blorb bounces (8x an ordinary jump, about
## 10.9 m) are ever needed to climb out, both on the east side: from the
## floor onto a rock ledge (PIT_FIRST_LEDGE), which sits against a broad
## shelf in the wall itself, a small hop up; then from the shelf onto a
## second ledge PIT_SECOND_LEDGE_RISE higher, from which a stair of small
## rock steps, each an ordinary jump up and jutting from the wall at its own
## height, climbs to the rim. On that side the wall rises beyond the shelf,
## from PIT_SHELF_OUTER_RADIUS to PIT_SHELF_RIM_RADIUS.
const PIT_DEPTH := 24.0
const PIT_FLOOR_RADIUS := 24.0
const PIT_RIM_RADIUS := 30.0
## The shelf: centred due east, PIT_SHELF_HALF_ANGLE either side, rising from
## the floor's edge to its level between the two inner radii.
const PIT_SHELF_HALF_ANGLE := 0.8
const PIT_SHELF_HEIGHT := -17.6
## (The terrain's grid has a vertex every SPACING metres: the shelf reaches
## its level by the vertex ring at 25 m so it is flat right out to its edge.)
const PIT_SHELF_INNER_START := 21.0
const PIT_SHELF_INNER_END := 24.9
const PIT_SHELF_OUTER_RADIUS := 38.0
const PIT_SHELF_RIM_RADIUS := 44.0
## Ledges: angle round the pit from east (radians), distance from the
## centre, and the height of the ledge's top.
const PIT_FIRST_LEDGE := Vector3(-0.26, 22.5, -18.0)
const PIT_SECOND_LEDGE := Vector3(0.05, 37.0, PIT_SHELF_HEIGHT + 8.5)
const PIT_LEDGE_HALF_SIZE := Vector3(2.0, 0.6, 2.0)
## The stair from the second ledge to the rim: each step this much higher
## than the last and this much further round the wall.
const PIT_STAIR_RISE := 1.1
const PIT_STAIR_TURN := 0.075
const PIT_STAIR_HALF_SIZE := Vector3(1.3, 0.35, 1.3)
## A slow, broad swell under the hills outside the clearing, so the ground
## between biomes rolls rather than lying flat.
const SWELL_AMPLITUDE := 4.0
const SWELL_FREQUENCY := 0.004

## Shiny: the Crossroads' own grass plains, dressed with that world's forest
## clusters (its tree species, undergrowth and pickable meadows) densely
## enough to read as woodland, and home to wild shiny blorbs (see
## demo_world.gd).
const FOREST_ZONE := Vector2(75.0, 182.0)
const FOREST_CLUSTERS := 10

## Plant: the Primate Kingdom around this point, clear of its village and river.
const PLANT_SOURCE := Vector2(-150.0, -170.0)
const PLANT_CENTER := Vector2(250.0, 0.0)
const PLANT_HALF := Vector2(58.0, 110.0)

## Water and ice share WATER_LEVEL: the terrain reports one water level for
## the whole world, and the frozen lake's water lies beneath its ice at that
## same level, exactly as the Ice Kingdom layers them.
const WATER_LEVEL := -7.0
## The water zone is a stretch of the Ocean Kingdom's sea: a channel
## LAKE_RADIUS either side of its centreline whose shore runs from
## LAKE_SHORE_GAP past the water portal to LAKE_SHORE_GAP short of the ice
## portal. It shelves away from sandy beaches over LAKE_SLOPE_WIDTH to deep
## water, deep enough for the Kraken though short of the open ocean's abyss,
## over the Ocean Kingdom's rolling seabed, in its colours, with its palms on
## the shore and its kelp and coral below.
const LAKE_SHORE_GAP := 8.0
const LAKE_RADIUS := 150.0
const LAKE_EDGE_VARIATION := 14.0
const LAKE_DEPTH := 40.0
const LAKE_SLOPE_WIDTH := 70.0
## An open lake's bank levels out just above the water: a narrow beach.
const LAKE_SHELF := WATER_LEVEL + 0.35
const LAKE_FLOOR := LAKE_SHELF - LAKE_DEPTH
## One palm island rising from the sea.
const ISLAND_CENTER := Vector2(1018.0, 70.0)
const ISLAND_RADIUS := 55.0
const ISLAND_HEIGHT := 7.0
## A portal standing on the seabed midway along the sea (see demo_world.gd):
## through it a single water blorb waits to take the head slot, wearing the
## Nautilus Crown.
const NAUTILUS_PORTAL_X := 828.0

## The long frozen lake: from LAKE_SHORE_GAP past the ice portal to the
## mountain's foot.
const ICE_RADIUS := 70.0
const ICE_EAST_SHORE_X := 2418.0
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

## The mountain. Its steep western face (the Ice zone's climb) rises from the
## frozen lake to a summit plateau MOUNTAIN_PEAK_HEIGHT up, where the snow
## portal stands; its long eastern flank descends to its foot at
## MOUNTAIN_END_X. Down that flank winds an explicit snowboard course: a
## smooth groomed trough COURSE_HALF_WIDTH wide either side of its weaving
## centreline, held in by raised berms, with rougher mogul ground and trees
## beyond. The valley's sides rise into a gully so the course stays central.
const MOUNTAIN_FOOT_X := 2433.0
const MOUNTAIN_PEAK_WEST_X := 2780.0
const MOUNTAIN_PEAK_EAST_X := 2818.0
const MOUNTAIN_END_X := 4148.0
const MOUNTAIN_PEAK_HEIGHT := 220.0
const MOUNTAIN_GULLY_HEIGHT := 35.0
const COURSE_HALF_WIDTH := 16.0
const COURSE_TROUGH_DEPTH := 2.5
const COURSE_BERM_HEIGHT := 1.6
const COURSE_WEAVE := 38.0
const COURSE_WEAVE_WAVELENGTH := 380.0
const MOGUL_AMPLITUDE := 5.0

## Ground: an east-west strip across the Rock/Ground Kingdom at z = 150,
## kept inside its border ranges: over terraces, through the town's flat
## shelf, across a wash, and side to side over its western halfpipe canyon.
const DIRT_SOURCE := Vector2(0.0, 150.0)
const DIRT_START_X := 4183.0
const DIRT_LENGTH := 840.0

## The course climbs across the ground zone to SKY_HEIGHT, near the clouds
## (the Clouds node's layer), holds there to the cliff edge, then plunges to
## CHASM_FLOOR. The far wall rises back to 0 at the volcanic lowland.
const SKY_HEIGHT := 110.0
const CLIFF_EDGE_X := 5068.0
const CHASM_FLOOR := -60.0
const CHASM_FAR_WALL_X := 5748.0
const CLIFF_FACE_WIDTH := 25.0

## Fire: a full-size Fire Kingdom volcano, its lava-filled mouth centred in a
## window of that kingdom's volcanic lowland.
const VOLCANO_SOURCE_POOL := Vector2(-190.0, -145.0)
const VOLCANO_CENTER := Vector2(6170.0, 0.0)
const VOLCANO_HALF_LENGTH := 360.0

const STONE := Color(0.52, 0.5, 0.47)
const CLIFF_ROCK := Color(0.42, 0.4, 0.38)

## Every border gate, west to east: the biome on either side of it.
## Each biome's portal stands on the side you enter it from, facing you (see
## demo_world.gd). The first gate's western side is the hero's starting set
## of Normal blorbs (element ""); "shiny" is a set of shiny Normal blorbs.
## Every gate stands on the path (z = 0) on a level strip as wide as its
## portal. A "pad" sets that strip's height; otherwise it follows the course
## (see _base_level()). A "portal_scale" enlarges that gate's portals (and
## its strip) by that factor in width and height. The lake gates stand down at the beach, so the water
## begins just past the portal; the ice gate's strip sits at the frozen lake's
## bank level, just above the ice sheet tucked beneath it.
const BORDERS := [
	{"x": 62.0, "west": "", "east": "shiny"},
	{"x": 192.0, "west": "shiny", "east": "plant"},
	{"x": 308.0, "west": "plant", "east": "water", "pad": LAKE_SHELF},
	{"x": 1353.0, "west": "water", "east": "ice", "pad": ICE_LEVEL},
	{"x": 2798.0, "west": "ice", "east": "snow"},
	{"x": 4173.0, "west": "snow", "east": "ground"},
	# The air gate is reached flat out on a dirt bike: three times the size.
	{"x": 5038.0, "west": "ground", "east": "air", "portal_scale": 3.0},
	{"x": 5793.0, "west": "air", "east": "fire"},
]
## Ice brings the Penguin Helm, Snow the Toboggan, Air the Bird Helm.
const HEAD_ITEMS := {
	"water": "Diving Helmet",
	"ice": "Penguin Helm",
	"snow": "Toboggan",
	"air": "Bird Helm",
	"fire": "Lava Helm",
}
## Portals span most of the valley floor, impossible to miss.
const PORTAL_HALF_WIDTH := 30.0
const PORTAL_HALF_HEIGHT := 5.0
const PORTAL_PAD_HALF_DEPTH := 5.0
const PORTAL_PAD_BLEND := 12.0

var _nx: int
var _nz: int
## _raw_height() at every grid vertex, computed once: characters query heights
## many times a frame, and the mesh build samples each vertex's neighbours.
var _heights := PackedFloat32Array()
var _hills := FastNoiseLite.new()
var _swell := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()
var _water_lake: NaturalLake
var _frozen_lake: NaturalLake
## Detached kingdom terrains, sampled only (never added to the tree).
var _jungle_sampler: Node
var _rock_sampler: Node
var _fire_sampler: Node
var _plant_window: TerrainWindow
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
	_water_lake = _channel_lake(
		border_x("water") + LAKE_SHORE_GAP, border_x("ice") - LAKE_SHORE_GAP,
		LAKE_RADIUS, LAKE_EDGE_VARIATION, LAKE_DEPTH, LAKE_SHELF, 20260919, LAKE_SLOPE_WIDTH
	)
	_frozen_lake = _channel_lake(
		border_x("ice") + LAKE_SHORE_GAP, ICE_EAST_SHORE_X,
		ICE_RADIUS, ICE_EDGE_VARIATION, ICE_LAKE_DEPTH, ICE_LEVEL, 20260920
	)
	_jungle_sampler = JUNGLE_KINGDOM_TERRAIN.new()
	_rock_sampler = ROCK_GROUND_KINGDOM_TERRAIN.new()
	_fire_sampler = FIRE_KINGDOM_TERRAIN.new()
	_plant_window = TerrainWindow.new(_jungle_sampler, PLANT_SOURCE, PLANT_CENTER, PLANT_HALF)
	_plant_window.level_to_edge()
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
	_windows = [_plant_window, _dirt_window, _volcano_window]


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for sampler in [_jungle_sampler, _rock_sampler, _fire_sampler]:
			if is_instance_valid(sampler):
				(sampler as Node).free()


## The Ocean Kingdom's underwater look, put on the camera while it is under the
## sea (see _process()).
var _underwater_environment: Environment
var _underwater_camera: Camera3D


func _process(_delta: float) -> void:
	var active_camera := get_viewport().get_camera_3d()
	if active_camera == null:
		return
	var at := Vector2(active_camera.global_position.x, active_camera.global_position.z)
	var under_sea := active_camera.global_position.y < WATER_LEVEL - 0.08 and _water_lake.coverage(at) > 0.5
	if under_sea:
		if _underwater_environment == null:
			_underwater_environment = OCEAN_KINGDOM_TERRAIN.build_underwater_environment()
		if active_camera.environment != _underwater_environment:
			active_camera.environment = _underwater_environment
		_underwater_camera = active_camera
	elif is_instance_valid(_underwater_camera) and _underwater_camera.environment == _underwater_environment:
		_underwater_camera.environment = null
		_underwater_camera = null


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


## The x of the gate whose eastern side is `east`.
static func border_x(east: String) -> float:
	for border in BORDERS:
		if border["east"] == east:
			return float(border["x"])
	return 0.0


## A lake whose shore runs from x `west_shore` to x `east_shore` along z = 0.
static func _channel_lake(
	west_shore: float, east_shore: float, lake_radius: float, variation: float,
	lake_depth: float, shelf: float, noise_seed: int, slope_width: float = NaturalLake.SHORE_FEATHER
) -> NaturalLake:
	var half_length := maxf((east_shore - west_shore) * 0.5 - lake_radius, 0.0)
	return NaturalLake.new(
		Vector2((west_shore + east_shore) * 0.5, 0.0), lake_radius, variation, lake_depth, shelf, noise_seed, half_length, slope_width
	)


## How far the valley floor reaches either side of the path at `x` before its
## walls rise: wider through the water zone's sea.
func _valley_half_width(x: float) -> float:
	var ocean := smoothstep(border_x("water") - 90.0, border_x("water") + 10.0, x) * (1.0 - smoothstep(border_x("ice") - 60.0, border_x("ice") + 40.0, x))
	return lerpf(VALLEY_HALF_WIDTH, OCEAN_HALF_WIDTH, ocean)


## 1 across the water zone's sea and shores.
func _ocean_weight(x: float) -> float:
	return smoothstep(border_x("water") - 40.0, border_x("water"), x) * (1.0 - smoothstep(border_x("ice") - 20.0, border_x("ice"), x))


## The Ocean Kingdom's rolling seabed (its _raw_height()'s layered waves).
static func _ocean_seabed_relief(x: float, z: float) -> float:
	return sin(x * 0.010) * 3.2 + cos(z * 0.012) * 2.5 + sin((x + z) * 0.006) * 2.0 + sin(x * 0.034) * cos(z * 0.029) * 0.9


## The island's rise (0..1) at `point`: a broad, gently crowned island, as
## the Ocean Kingdom shapes its own.
static func _island_rise(point: Vector2) -> float:
	var distance := point.distance_to(ISLAND_CENTER)
	if distance >= ISLAND_RADIUS:
		return 0.0
	return pow(smoothstep(0.0, 1.0, 1.0 - distance / ISLAND_RADIUS), 0.34)


## Where the Nautilus portal stands: on the seabed at the path.
func nautilus_portal_point() -> Vector3:
	return Vector3(NAUTILUS_PORTAL_X, LAKE_FLOOR, 0.0)


## The mountain's height along the valley's centre, before its gully sides,
## course and moguls: 0 west of its foot, up the western face (mostly even,
## easing in and out), level across the summit, then down the eastern flank,
## steepest at the top and easing out to 0 at MOUNTAIN_END_X.
func _mountain_profile(x: float) -> float:
	if x <= MOUNTAIN_FOOT_X or x >= MOUNTAIN_END_X:
		return 0.0
	if x < MOUNTAIN_PEAK_WEST_X:
		var t := (x - MOUNTAIN_FOOT_X) / (MOUNTAIN_PEAK_WEST_X - MOUNTAIN_FOOT_X)
		return MOUNTAIN_PEAK_HEIGHT * (0.7 * t + 0.3 * smoothstep(0.0, 1.0, t))
	if x <= MOUNTAIN_PEAK_EAST_X:
		return MOUNTAIN_PEAK_HEIGHT
	var t := (x - MOUNTAIN_PEAK_EAST_X) / (MOUNTAIN_END_X - MOUNTAIN_PEAK_EAST_X)
	return MOUNTAIN_PEAK_HEIGHT * pow(1.0 - t, 1.35)


## 1 across the mountain (foot to foot), easing off just beyond each foot.
func _mountain_weight(x: float) -> float:
	return smoothstep(MOUNTAIN_FOOT_X - 30.0, MOUNTAIN_FOOT_X + 20.0, x) * (1.0 - smoothstep(MOUNTAIN_END_X - 20.0, MOUNTAIN_END_X + 25.0, x))


## The snowboard course's centreline across the valley at `x`, weaving side to
## side down the eastern flank and straight across the summit and the foot.
func course_center_z(x: float) -> float:
	var t := clampf((x - MOUNTAIN_PEAK_EAST_X) / (MOUNTAIN_END_X - MOUNTAIN_PEAK_EAST_X), 0.0, 1.0)
	var taper := smoothstep(0.0, 0.06, t) * (1.0 - smoothstep(0.94, 1.0, t))
	return COURSE_WEAVE * taper * sin((x - MOUNTAIN_PEAK_EAST_X) * TAU / COURSE_WEAVE_WAVELENGTH)


## 1 on the groomed course, 0 beyond its berms; only down the eastern flank.
func _course_weight(point: Vector2) -> float:
	if point.x < MOUNTAIN_PEAK_EAST_X - 10.0 or point.x > MOUNTAIN_END_X + 10.0:
		return 0.0
	return 1.0 - smoothstep(COURSE_HALF_WIDTH, COURSE_HALF_WIDTH + 10.0, absf(point.y - course_center_z(point.x)))


## The mountain's full relief at `point`: the profile, rising into the gully
## sides, with the course's trough and berms and moguls beyond it.
func _mountain_height(point: Vector2) -> float:
	var weight := _mountain_weight(point.x)
	if weight <= 0.0:
		return 0.0
	var height := _mountain_profile(point.x)
	height += smoothstep(40.0, 115.0, absf(point.y)) * MOUNTAIN_GULLY_HEIGHT
	if point.x > MOUNTAIN_PEAK_EAST_X:
		var across := absf(point.y - course_center_z(point.x))
		var trough := 1.0 - pow(minf(across / COURSE_HALF_WIDTH, 1.0), 2.0)
		var berm := exp(-pow((across - COURSE_HALF_WIDTH - 3.0) / 3.5, 2.0))
		var on_flank := smoothstep(MOUNTAIN_PEAK_EAST_X, MOUNTAIN_PEAK_EAST_X + 40.0, point.x) * (1.0 - smoothstep(MOUNTAIN_END_X - 60.0, MOUNTAIN_END_X, point.x))
		height += (berm * COURSE_BERM_HEIGHT - trough * COURSE_TROUGH_DEPTH) * on_flank
		height += _hills.get_noise_2d(point.x * 2.5, point.y * 2.5) * MOGUL_AMPLITUDE * (1.0 - _course_weight(point)) * on_flank
	return height * weight


## The height a gate's level strip sits at without a "pad": the course's
## elevation plus the mountain along the valley's centre.
func _base_level(x: float) -> float:
	return _course_elevation(x) + _mountain_profile(x)


## The pit's own ground height at `point` (0 on and beyond its rim): the
## floor, the steep wall, and on the east side the shelf and its higher wall.
func _pit_height(point: Vector2) -> float:
	var offset := point - START_CENTER
	var distance := offset.length()
	var plain := -PIT_DEPTH * (1.0 - smoothstep(PIT_FLOOR_RADIUS, PIT_RIM_RADIUS, distance))
	var shelf_side := 1.0 - smoothstep(PIT_SHELF_HALF_ANGLE - 0.25, PIT_SHELF_HALF_ANGLE, absf(atan2(offset.y, offset.x)))
	if shelf_side <= 0.0:
		return plain
	var shelved := (
		-PIT_DEPTH
		+ (PIT_SHELF_HEIGHT + PIT_DEPTH) * smoothstep(PIT_SHELF_INNER_START, PIT_SHELF_INNER_END, distance)
		- PIT_SHELF_HEIGHT * smoothstep(PIT_SHELF_OUTER_RADIUS, PIT_SHELF_RIM_RADIUS, distance)
	)
	return lerpf(plain, shelved, shelf_side)


## The radius on the shelf side where the pit's wall stands `height` high:
## where a stair step at that height meets the wall.
func _pit_wall_radius_at(height: float) -> float:
	var low := PIT_SHELF_OUTER_RADIUS
	var high := PIT_SHELF_RIM_RADIUS
	for step in 24:
		var middle := (low + high) * 0.5
		if _pit_height(START_CENTER + Vector2(middle, 0.0)) < height:
			low = middle
		else:
			high = middle
	return (low + high) * 0.5


func _raw_height(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var start_distance := point.distance_to(START_CENTER)
	# The groomed course is smooth: no hills or swell underfoot.
	var roughness := 1.0 - _course_weight(point) * _mountain_weight(x)
	var height := _hills.get_noise_2d(x, z) * CROSSROADS_HILL_AMPLITUDE * roughness
	height += _swell.get_noise_2d(x, z) * SWELL_AMPLITUDE * roughness * smoothstep(START_FLATTEN_RADIUS + 20.0, START_FLATTEN_RADIUS + 80.0, start_distance)
	# The Crossroads' arrival clearing: genuinely level, hills returning only
	# through its soft outer transition.
	height *= smoothstep(START_FLATTEN_RADIUS, START_FLATTEN_RADIUS + START_FLATTEN_TRANSITION, start_distance)
	# Kingdom windows replace the valley ground within them.
	for biome in _windows:
		var weight := biome.weight(point)
		if weight > 0.0:
			height = lerpf(height, biome.height(point), weight)
	height += _mountain_height(point)
	# Basins punched into the ground (NaturalLake).
	height = _water_lake.carve(height, point)
	height = _frozen_lake.carve(height, point)
	# The sea's floor rolls like the Ocean Kingdom's, a level pad under the
	# Nautilus portal, and the island rising out of it.
	var deep := _water_lake.depth_weight(point) * _water_lake.coverage(point)
	if deep > 0.0:
		height += _ocean_seabed_relief(x, z) * deep
		var pad := (1.0 - smoothstep(PORTAL_PAD_HALF_DEPTH, PORTAL_PAD_HALF_DEPTH + PORTAL_PAD_BLEND, absf(x - NAUTILUS_PORTAL_X))) * (1.0 - smoothstep(PORTAL_HALF_WIDTH + 3.0, PORTAL_HALF_WIDTH + 3.0 + PORTAL_PAD_BLEND, absf(z)))
		height = lerpf(height, LAKE_FLOOR, pad)
	var island := _island_rise(point)
	if island > 0.0:
		height = maxf(height, lerpf(height, WATER_LEVEL + ISLAND_HEIGHT, island))
	height += _course_elevation(x)
	# The starting pit, punched down to a flat floor.
	if start_distance < PIT_SHELF_RIM_RADIUS + 1.0:
		height = minf(height, _pit_height(point))
	# Each gate's level strip, as wide as its portal.
	for border in BORDERS:
		var gate_x: float = border["x"]
		var along := 1.0 - smoothstep(PORTAL_PAD_HALF_DEPTH, PORTAL_PAD_HALF_DEPTH + PORTAL_PAD_BLEND, absf(x - gate_x))
		if along <= 0.0:
			continue
		var gate_half_width := PORTAL_HALF_WIDTH * float(border.get("portal_scale", 1.0))
		var across := 1.0 - smoothstep(gate_half_width + 3.0, gate_half_width + 3.0 + PORTAL_PAD_BLEND, absf(z))
		height = lerpf(height, float(border.get("pad", _base_level(gate_x))), along * across)
	# Valley walls along both sides and at both ends.
	var half_width := _valley_half_width(x)
	height += smoothstep(half_width, half_width + VALLEY_WALL_RISE, absf(z)) * VALLEY_WALL_HEIGHT
	height += (1.0 - smoothstep(X_MIN + 20.0, -60.0, x)) * VALLEY_WALL_HEIGHT
	height += smoothstep(X_MAX - 50.0, X_MAX - 20.0, x) * VALLEY_WALL_HEIGHT
	return height


## 1 on snow: the whole mountain, and the snowfield round the frozen lake.
func _snow_weight(point: Vector2) -> float:
	var snowfield := 1.0 - smoothstep(ICE_RADIUS + ICE_SNOWFIELD_WIDTH - 12.0, ICE_RADIUS + ICE_SNOWFIELD_WIDTH, _frozen_lake.local_distance(point))
	return maxf(snowfield, _mountain_weight(point.x))


func _height_color(x: float, z: float, height: float) -> Color:
	var point := Vector2(x, z)
	var color := CROSSROADS_GRASS.lerp(OCEAN_KINGDOM_TERRAIN.GRASS_COLOR, _ocean_weight(x))
	for biome in _windows:
		var weight := biome.weight(point)
		if weight > 0.0:
			color = color.lerp(biome.color(point), weight)
	if _frozen_lake.coverage(point) > 0.12:
		return FROZEN_LAKEBED
	# Snow is always snow-coloured: the same test decides the colour here and
	# the snow surface in is_snow_footstep_surface().
	var snow := _snow_weight(point)
	if snow > 0.0:
		color = color.lerp(SNOW, snow)
	# The pit's walls are bare rock; its floor and shelf stay grass.
	if point.distance_to(START_CENTER) < PIT_SHELF_RIM_RADIUS + 1.0:
		var pit := _pit_height(point)
		var on_level := pit <= -PIT_DEPTH + 0.3 or absf(pit - PIT_SHELF_HEIGHT) < 0.3 or pit >= -0.2
		if not on_level:
			color = color.lerp(CLIFF_ROCK, 0.85)
	# The sea, in the Ocean Kingdom's colours: sandy beaches and island
	# shores, shallow and deep seabed by depth, island grass above the sand.
	var beach := 1.0 - smoothstep(LAKE_RADIUS + NaturalLake.BANK_WIDTH - 4.0, LAKE_RADIUS + NaturalLake.BANK_WIDTH + 8.0, _water_lake.local_distance(point))
	if beach > 0.0 or _island_rise(point) > 0.0:
		var sea_color := OCEAN_KINGDOM_TERRAIN.BEACH_COLOR
		var above_water := height - WATER_LEVEL
		if above_water > 1.0 and _island_rise(point) > 0.0:
			sea_color = OCEAN_KINGDOM_TERRAIN.GRASS_COLOR
		elif above_water < -2.0:
			sea_color = OCEAN_KINGDOM_TERRAIN.SHALLOW_FLOOR_COLOR.lerp(
				OCEAN_KINGDOM_TERRAIN.DEEP_FLOOR_COLOR, smoothstep(-6.0, -16.0, above_water)
			)
		color = color.lerp(sea_color, maxf(beach, 1.0 if _island_rise(point) > 0.0 else 0.0))
	# The high course before the cliff, the cliff and the chasm: bare rock.
	var rock := smoothstep(DIRT_START_X + DIRT_LENGTH - 20.0, DIRT_START_X + DIRT_LENGTH + 10.0, x) * (1.0 - smoothstep(CHASM_FAR_WALL_X + CLIFF_FACE_WIDTH, CHASM_FAR_WALL_X + CLIFF_FACE_WIDTH + 30.0, x))
	if rock > 0.0:
		color = color.lerp(CLIFF_ROCK, rock)
	if absf(z) > _valley_half_width(x) + 10.0 or x < -70.0 or x > X_MAX - 60.0:
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
	return _snow_weight(pos) > 0.5 and not is_ice_surface(pos) and not is_lake_area(pos)


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
		[X_MIN, _terrain_material(1.0, 1.0)],                  # pit, forest, plant
		[border_x("water"), _terrain_material(0.0, 0.86)],     # the sea
		[border_x("ice"), _terrain_material(0.0, 0.88)],       # ice, snow
		[border_x("ground"), _terrain_material(0.0, 0.94)],    # ground, sky cliff
		[border_x("fire"), _terrain_material(0.0, 0.96)],      # fire
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
			# Clockwise seen from above, so the top is each triangle's front face.
			# The material draws both sides and lights a back face with its
			# normal reversed, so the opposite order lit the ground from below.
			for index in [i0, i0 + 1, i0 + columns, i0 + 1, i0 + columns + 1, i0 + columns]:
				tool.add_index(index)
			var ix := ix0 + local_x
			var a := _grid_vertex(ix, iz)
			var b := _grid_vertex(ix + 1, iz)
			var c := _grid_vertex(ix, iz + 1)
			var d := _grid_vertex(ix + 1, iz + 1)
			for vertex in [a, b, c, b, d, c]:
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
	var sea := ShaderMaterial.new()
	sea.shader = OCEAN_KINGDOM_TERRAIN.OCEAN_WATER_SHADER
	sea.set_shader_parameter("surface_color", OCEAN_KINGDOM_TERRAIN.WATER_COLOR)
	_water_lake.build_surface(self, "SeaWater", WATER_LEVEL, sea)
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
			Vector3(VOLCANO_CENTER.x + cos(a0) * radius, _volcano_lava_level, VOLCANO_CENTER.y + sin(a0) * radius),
			Vector3(VOLCANO_CENTER.x + cos(a1) * radius, _volcano_lava_level, VOLCANO_CENTER.y + sin(a1) * radius),
		]:
			tool.add_vertex(vertex)
	tool.generate_normals()
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
	_build_pit_ledges()
	_scatter_forest()
	_scatter_lake_shore()
	_scatter_mountain()
	_scatter_snowfield()
	_scatter_dirt_track()
	_scatter_volcanic_rocks()


## The pit's two ledges and its stair (see PIT_DEPTH): flat-topped stone
## blocks standing out from the wall, solid and meant to be landed on.
func _build_pit_ledges() -> void:
	_add_pit_block("PitLedge0", PIT_FIRST_LEDGE, PIT_LEDGE_HALF_SIZE)
	_add_pit_block("PitLedge1", PIT_SECOND_LEDGE, PIT_LEDGE_HALF_SIZE)
	var top := PIT_SECOND_LEDGE.z + PIT_STAIR_RISE
	var angle := PIT_SECOND_LEDGE.x
	var index := 0
	while top < -0.1:
		angle += PIT_STAIR_TURN
		# Juts from the wall where the wall stands just below the step's top.
		var radius := _pit_wall_radius_at(top - 0.4) - PIT_STAIR_HALF_SIZE.x * 0.6
		_add_pit_block("PitStair%d" % index, Vector3(angle, radius, top), PIT_STAIR_HALF_SIZE)
		top += PIT_STAIR_RISE
		index += 1


## One pit block: `spec` is (angle from east, distance from the pit's centre,
## height of its top).
func _add_pit_block(block_name: String, spec: Vector3, half_size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = block_name
	body.collision_layer = 1
	body.collision_mask = 0
	var at := START_CENTER + Vector2.from_angle(spec.x) * spec.y
	body.position = Vector3(at.x, spec.z - half_size.y, at.y)
	body.rotation.y = -spec.x
	var block := SuperEgg.build_part(half_size, CLIFF_ROCK.lightened(0.08), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT)
	block.name = "Rock"
	body.add_child(block)
	CollisionPolicy.add_box(body, block, half_size * 2.0)
	add_child(body)


func _place(node: Node3D, x: float, z: float) -> void:
	node.position = Vector3(x, get_mesh_height(x, z), z)
	add_child(node)


func _on_path(point: Vector2) -> bool:
	return absf(point.y) < 8.0 or absf(point.y) > _valley_half_width(point.x) - 7.0


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


## The Ocean Kingdom's shore and seabed life: palms, banana trees, bushes and
## grass along both beaches and over the island; kelp meadows across the
## seabed and coral reefs on the shelving shallows.
func _scatter_lake_shore() -> void:
	var kelp_colors: Array = OCEAN_KINGDOM_TERRAIN.KELP_COLORS
	var reef_colors: Array = OCEAN_KINGDOM_TERRAIN.REEF_COLORS
	for index in 150:
		var point := _water_lake.point_on_ring(_rng.randf_range(0.0, TAU), LAKE_RADIUS + _rng.randf_range(8.0, 70.0))
		if _on_path(point) or absf(point.x - border_x("water")) < 20.0 or absf(point.x - border_x("ice")) < 20.0:
			continue
		if get_mesh_height(point.x, point.y) < WATER_LEVEL + 0.8:
			continue
		_place_shore_plant(point, index)
	for index in 40:
		var point := ISLAND_CENTER + Vector2.from_angle(_rng.randf_range(0.0, TAU)) * sqrt(_rng.randf()) * ISLAND_RADIUS * 0.6
		if get_mesh_height(point.x, point.y) < WATER_LEVEL + 1.0:
			continue
		_place_shore_plant(point, index)
	for index in 220:
		var point := Vector2(
			_rng.randf_range(_water_lake.center.x - _water_lake.half_length - LAKE_RADIUS, _water_lake.center.x + _water_lake.half_length + LAKE_RADIUS),
			_rng.randf_range(-LAKE_RADIUS, LAKE_RADIUS)
		)
		var floor_y := get_mesh_height(point.x, point.y)
		if _water_lake.coverage(point) < 0.9 or floor_y > WATER_LEVEL - 2.5 or absf(point.x - NAUTILUS_PORTAL_X) < 20.0 and absf(point.y) < 40.0:
			continue
		var flora: Node3D
		if floor_y > WATER_LEVEL - 20.0 and index % 2 == 0:
			if index % 6 == 0:
				flora = NatureProps.build_rock(_rng.randf_range(0.5, 1.5), false)
			elif index % 4 == 0:
				flora = NatureProps.build_fan_seaweed(_rng.randf_range(1.1, 2.6), reef_colors[index % reef_colors.size()], _rng)
			else:
				flora = NatureProps.build_branching_coral(_rng.randf_range(1.0, 3.0), reef_colors[index % reef_colors.size()])
		elif index % 5 == 0:
			flora = NatureProps.build_fan_seaweed(_rng.randf_range(2.0, 4.8), kelp_colors[index % kelp_colors.size()], _rng)
		else:
			flora = NatureProps.build_ribbon_kelp(_rng.randf_range(2.8, 8.5), kelp_colors[index % kelp_colors.size()])
		flora.rotation.y = _rng.randf_range(0.0, TAU)
		_place(flora, point.x, point.y)
		_set_visual_range(flora, 175.0, 25.0)


## One shore plant, as the Ocean Kingdom's islands mix them: mostly palms,
## with banana trees, bushes and grass tufts.
func _place_shore_plant(point: Vector2, index: int) -> void:
	var plant: Node3D
	match index % 6:
		0, 1, 2:
			plant = NatureProps.build_palm_tree(_rng.randf_range(5.0, 9.5), _rng.randf_range(-0.14, 0.14), _rng)
		3:
			plant = NatureProps.build_banana_tree(_rng.randf_range(5.5, 8.0), _rng)
		4:
			plant = NatureProps.build_bush(Color(0.08, 0.62, 0.35))
		_:
			plant = NatureProps.build_grass_tuft(Color(0.18, 0.74, 0.39))
	plant.rotation.y = _rng.randf_range(0.0, TAU)
	_place(plant, point.x, point.y)
	_set_visual_range(plant, 340.0, 30.0)


func _set_visual_range(root: Node, end_distance: float, fade_margin: float) -> void:
	if root is GeometryInstance3D:
		var geometry := root as GeometryInstance3D
		geometry.visibility_range_end = end_distance
		geometry.visibility_range_end_margin = fade_margin
		geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for child in root.get_children():
		_set_visual_range(child, end_distance, fade_margin)


## The mountain dressed as the Ice Kingdom dresses its own: rocks (every
## third) and frost-grey snow pines, thick on the rough ground either side of
## the snowboard course and never on it.
func _scatter_mountain() -> void:
	for index in 260:
		var point := Vector2(_rng.randf_range(MOUNTAIN_FOOT_X + 20.0, MOUNTAIN_END_X - 20.0), _rng.randf_range(-110.0, 110.0))
		if point.x > MOUNTAIN_PEAK_EAST_X - 20.0 and absf(point.y - course_center_z(point.x)) < COURSE_HALF_WIDTH + 12.0:
			continue
		if _on_path(point) or absf(point.x - border_x("snow")) < 40.0:
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
