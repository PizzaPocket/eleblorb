extends Node3D

## A large, sprawling settlement out in the northwest-of-lake wasteland --
## per direct instruction, "just like the city biome... a small village that
## is kinda big to you, that has no portal gate and no kingdom," later
## refined to "large sprawling village" at ordinary human scale, and later
## still rebuilt entirely as a cluster of floating islands over a chasm
## ("everything be on floating islands over a deep deep abyss, the Abyss of
## Impending Doom... connected by bridges"). Mirrors city_generator.gd's own
## top-level placement (a standalone Node3D sibling of Terrain/Player in
## main.tscn) rather than its dense tower-grid/LOD-wake system.
##
## The Abyss itself is terrain_generator.gd's own responsibility (a deep
## dip in the shared analytic heightfield, see that file's own
## chinese_village_abyss_coverage()) -- this file only builds what floats
## above it: a hub-and-spoke layout of four islands (one large Palace
## island at the center, three smaller spokes -- two ordinary village
## islands and one bamboo-forest island) joined by plank bridges, plus one
## longer entry bridge reaching back to solid ordinary wasteland to the
## south. Every island sits at the same fixed ISLAND_SURFACE_Y -- nothing
## on them ever samples real terrain height, since the real ground far
## below is the abyss floor, not anywhere a building or a wandering
## villager should actually settle. NPCs use npc.gd's own fixed_ground_y
## override for this reason (see _spawn_villagers() etc.); Sun Wu Kong and
## Pandy use their own scripts' abyss-aware _ground_y() helpers instead
## (see either file's own doc comment), since they can walk beyond the
## village once they join the party.
##
## Buildings are ordinary TownProps.build_building() shells (real walls,
## door, and a collidable/landable gable roof) topped with a tapering stack
## of thin ornamental SuperEgg eave tiers, using the same "shrink each tier
## as you stack upward" technique NatureProps.build_slab_tower()/
## build_rock_spire() already establish for unrelated stacked landmarks --
## the pagoda silhouette comes from that taper, not new wall/roof code.

const NPC_SCENE: PackedScene = preload("res://scenes/npc.tscn")
const SUN_WU_KONG_SCENE: PackedScene = preload("res://scenes/sun_wu_kong.tscn")
const PANDY_SCENE: PackedScene = preload("res://scenes/pandy.tscn")

## Duplicated from terrain_generator.gd's/wilderness_scatter.gd's own
## CHINESE_VILLAGE_CENTER, matching this project's own established
## convention of keeping each generator's biome-center consts local (see
## wilderness_scatter.gd's own CITY_CENTER comment for why) rather than
## reaching into those other scripts. Shifted west and north (and further
## from the lake) per direct instruction.
const VILLAGE_CENTER := Vector2(250.0, -650.0)
## Every island (and everything on it) sits at this fixed world height --
## no terrain sampling anywhere on/between them. Close to the ordinary
## wasteland floor's own height (-60) so the one entry bridge reaching back
## to solid ground stays close to level.
const ISLAND_SURFACE_Y := -55.0

# ---------------------------------------------------------------------------
# Island layout: a large imperial island surrounded by smaller, genuinely
# separated village islets. Long bridges are now a defining part of the
# traversal rather than tiny seams between nearly touching grass discs.
# ---------------------------------------------------------------------------
const PALACE_LOCAL := Vector2.ZERO
const PALACE_RADIUS := 62.0
const VILLAGE_A_LOCAL := Vector2(-105.0, -58.0)
const VILLAGE_A_RADIUS := 21.0
const VILLAGE_B_LOCAL := Vector2(108.0, -48.0)
const VILLAGE_B_RADIUS := 20.0
const BAMBOO_ISLAND_LOCAL := Vector2(18.0, 116.0)
const BAMBOO_ISLAND_RADIUS := 25.0
const VILLAGE_C_LOCAL := Vector2(-118.0, 42.0)
const VILLAGE_C_RADIUS := 18.0
const VILLAGE_D_LOCAL := Vector2(112.0, 48.0)
const VILLAGE_D_RADIUS := 19.0
const VILLAGE_E_LOCAL := Vector2(-62.0, 124.0)
const VILLAGE_E_RADIUS := 17.0

const ISLAND_GRASS_COLOR := Color(0.07451, 0.63922, 0.40392)  # same grass hex the main/jungle plateaus use, per direct instruction
const ISLAND_ROCK_COLOR := Color(0.34, 0.3, 0.26)
const ISLAND_MESH_SECTORS := 32
const ISLAND_EDGE_VARIATION := 0.08

const BRIDGE_WIDTH := 3.2
const BRIDGE_PLANK_COLOR := Color(0.42, 0.3, 0.18)
const BRIDGE_RAIL_HEIGHT := 0.7
## Where the one entry bridge from ordinary wasteland lands, measured from
## VILLAGE_CENTER -- past terrain_generator.gd's own CHINESE_VILLAGE_ABYSS_
## RADIUS + CHINESE_VILLAGE_ABYSS_TRANSITION (170 + 50 = 220) with margin,
## so its far end rests on genuinely solid, ordinary ground.
const ENTRY_BRIDGE_RIM_DISTANCE := 225.0
const ENTRY_BRIDGE_DIRECTION := Vector2(0.0, 1.0)  # local +Z = south, back toward the main plateau

const BUILDING_MIN_SPACING := 15.0
const BUILDING_CELL_MIN := 1
const BUILDING_CELL_MAX := 3
const VILLAGE_A_BUILDING_COUNT := 2
const VILLAGE_B_BUILDING_COUNT := 2

## Red lacquer + gold trim -- a distinct palette from every other building
## style in the project, so this settlement reads immediately as its own
## place.
const ROOF_COLORS := [
	Color(0.62, 0.12, 0.1),
	Color(0.68, 0.22, 0.08),
	Color(0.55, 0.1, 0.12),
]
const TRIM_COLOR := Color(0.82, 0.64, 0.22)
const EAVE_TIER_COUNT := 2
const EAVE_TIER_HEIGHT := 0.32
const EAVE_TIER_GAP := 0.55
const EAVE_TIER_SHRINK := 0.62
const EAVE_WIDTH_FRACTION := 0.85
const FINIAL_SIZE := Vector3(0.12, 0.4, 0.12)

## The Emperor's palace -- same _build_pagoda() shape as an ordinary house,
## just bigger and with more tiers, per direct instruction ("one largest
## island with the emperor's palace").
const PALACE_LOCAL_POS := Vector2(0.0, -8.0)
const PALACE_CELLS := 12
const PALACE_CELLS_PER_LEVEL_SHRINK := 2
const PALACE_LEVEL_COUNT := 4
const PALACE_STOREY_HEIGHT := 4.2
const PALACE_WALL_THICKNESS := 0.42
const PALACE_EAVE_OVERHANG := 0.75
const PALACE_DOOR_WIDTH := 3.4

const LANTERN_COUNT_PER_ISLAND := 14

# ---------------------------------------------------------------------------
# Bamboo (now its own island, scattered sparsely -- "sporadically" per
# direct instruction, not the earlier single dense grove).
# ---------------------------------------------------------------------------
const BAMBOO_STALK_COUNT := 34
## Small -- just enough to keep a stalk from spawning literally inside the
## island's own collision center, NOT a "farmer's clearing": per direct
## instruction the farmer is found INSIDE the bamboo forest, not next to it.
const BAMBOO_CLEAR_CENTER := 6.0
const BAMBOO_SEGMENT_COUNT := 6
const BAMBOO_SEGMENT_HEIGHT := 0.9
const BAMBOO_RADIUS_MIN := 0.05
const BAMBOO_RADIUS_MAX := 0.09
const BAMBOO_NODE_RADIUS_BOOST := 1.25
const BAMBOO_COLOR := Color(0.42, 0.62, 0.24)
const BAMBOO_NODE_COLOR := Color(0.32, 0.48, 0.18)
const BAMBOO_LEAF_COLOR := Color(0.36, 0.58, 0.22)
const BAMBOO_LEAF_COUNT := 5

# ---------------------------------------------------------------------------
# The kids' own play hut (Village A) -- see _build_play_hut()'s own comment.
# ---------------------------------------------------------------------------
const PLAY_HUT_LOCAL_POS := Vector2(6.0, 6.0)
const PLAY_HUT_POLE_COUNT := 7
const PLAY_HUT_POLE_HEIGHT := 1.3
const PLAY_HUT_POLE_RADIUS := 0.03
const PLAY_HUT_BASE_RADIUS := 0.55
const PLAY_HUT_STICK_COLOR := Color(0.42, 0.3, 0.18)
const LOOSE_STICK_COUNT := 9
const KID_ROAM_JITTER := 6.0

## Sun Wu Kong's sealing rock crowns the Emperor's castle.
const SUN_WU_KONG_LOCAL_POS := PALACE_LOCAL_POS
## Exact top of the crown cap: four storeys, then the cap center offset and
## its half-height (0.35 + 0.35). Sun Wu Kong's feet and the cap collision
## therefore resolve against the same visible surface.
const SUN_WU_KONG_CASTLE_Y := PALACE_LEVEL_COUNT * PALACE_STOREY_HEIGHT + 0.70

## The outdoor merchant's stall (Village B).
const VENDOR_LOCAL_POS := Vector2(-7.0, 6.0)
const VENDOR_NAME := "Chen"
const VENDOR_LINES := [
	"都是竹林后面新鲜采的,信不信由你。",
	"这豆子可不是开玩笑的。种下去看看就知道了,别问我是怎么回事。",
	"灯笼、包子,路上缺什么尽管问我。",
]

## The farmer, Pandy, and the Emperor -- see _build_farmer_and_pandy_quest()/
## _build_emperor() for the full quest writeup.
const FARMER_LOCAL_POS := Vector2(0.0, -22.0)
const FARMER_NAME := "田伯"
const FARMER_LINES := [
	"皇帝每年都从我的地里多要一些。再这样下去,我就没地方种豆子了。",
	"潘迪跟着我很多年了。它比我还懂得躲懒。",
]
const FARMER_LINES_AFTER_DEPOSED := [
	"地还给我了。这些年头一回,我不用看皇帝的脸色。",
	"潘迪已经认你了。它跟谁都不亲,除了我们俩。",
]
## Inside the palace's ground-floor hall, beyond its south-facing doorway.
const EMPEROR_LOCAL_POS := Vector2(0.0, -5.0)
const EMPEROR_NAME := "皇帝"
const EMPEROR_LINES := [
	"整个山谷,连脚下的浮岛,都是朕的疆土。",
	"御厨最懂治国。他说严厉一点，百姓才会听话。",
]
const EMPEROR_LINES_AFTER_DEPOSED := [
	"朕像做了一场很长的噩梦。如今这座村庄由你作主。",
]
const LANTERN_LIGHT_ENABLE_DISTANCE := 46.0
const LANTERN_LIGHT_UPDATE_INTERVAL := 0.3

const SKIN_COLORS := [
	Color(0.92, 0.76, 0.62),
	Color(0.86, 0.68, 0.52),
	Color(0.78, 0.58, 0.42),
	Color(0.68, 0.48, 0.34),
]
const HAIR_COLORS := [
	Color(0.08, 0.06, 0.05),
	Color(0.12, 0.09, 0.07),
	Color(0.18, 0.14, 0.1),
]
const SHIRT_COLORS := [
	Color(0.62, 0.12, 0.1),
	Color(0.16, 0.32, 0.28),
	Color(0.2, 0.24, 0.4),
	Color(0.82, 0.64, 0.22),
]
const PANTS_COLORS := [
	Color(0.16, 0.14, 0.14),
	Color(0.24, 0.2, 0.16),
]

## One entry per named villager -- own name, own lines, matching every other
## villager roster in the project. Lines are in Chinese per direct
## instruction ("all the people in the chinese village should literally
## speak Chinese in their dialog") -- display_name stays a Latin
## transliteration. First half spawn on Village A, second half on Village B
## (see _ready()).
const VILLAGER_IDENTITIES := [
	{
		"name": "Mei Lian",
		"lines": [
			"灯笼总是亮到半夜。没人记得这规矩是谁定下的。",
			"你走了这么远来找我们。很少有人是特意来的。",
		],
	},
	{
		"name": "Wen Zhao",
		"lines": [
			"村里每座屋顶的角度都不一样。我爷爷盖了一半,没有一个对得上。",
			"荒地大多时候很安静。我早就不介意走去井边了。",
		],
	},
	{
		"name": "Bo Xiang",
		"lines": [
			"天气好的时候,我们会和南边的镇子做买卖。路很远。",
			"我在村里住过三个不同的屋子,各有各的好。",
		],
	},
	{
		"name": "Hua Chen",
		"lines": [
			"这里没有城门,没有传送门,没有什么会把你吞到别处去。只有我们。",
			"风一转,屋檐就呼啸起来。我花了好多年才不觉得瘆人。",
		],
	},
	{
		"name": "Jin Wei",
		"lines": [
			"我母亲挂起了这一排的第一批灯笼。我只是一直在换纸。",
			"你会渐渐习惯这里地平线有多远。去了热闹的地方,反倒不习惯了。",
		],
	},
	{
		"name": "Lian Fu",
		"lines": [
			"有些晚上家家户户的窗户都亮着。整个村子好像一起醒着。",
			"我不再问旅人从哪里来了。大多数答案早就说不通了。",
		],
	},
	{
		"name": "Yun Tao",
		"lines": [
			"这瓦的颜色是很久以前从别处运来的。现在这附近没人烧得出这颜色了。",
			"我最喜欢黄昏前那段安静时光,灯笼还没亮起的时候。",
		],
	},
	{
		"name": "Shu Mei",
		"lines": [
			"再往西走,荒地就没有尽头了。我们大概是住得最远的人家了。",
			"我数过路边的灯笼柱很多次,从来数不出一样的数字。",
		],
	},
]

## Small roaming children on Village A, per direct instruction. Lines are
## Chinese, same instruction as VILLAGER_IDENTITIES' own comment above.
const KID_HAIR_STYLES := [FigureHair.STYLE_PIGTAILS, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_BUN]
## Per direct correction ("they shouldn't be that much smaller than the
## hero character"), a much narrower gap from adult scale than the first
## pass used.
const KID_BODY_SCALE_MIN := 0.74
const KID_BODY_SCALE_MAX := 0.82
## The "soft" body type, per direct instruction ("their body types should
## be the soft body type") -- npc.gd's own chest/hip/abdomen build-scale
## sliders (1.0 = the skinny/base end, only ever broader) pushed toward
## their rounder, plumper end rather than left at the adult-villager
## default, so kids read as pudgy children instead of shrunk-down adults.
const KID_ABDOMEN_WIDTH_SCALE := 1.32
const KID_CHEST_BUILD_SCALE := 1.12
const KID_HIP_BUILD_SCALE := 1.12
const KID_IDENTITIES := [
	{
		"name": "Ting",
		"lines": [
			"我今早扎辫子扎了好久,不过很值得。",
			"我才不怕竹林呢。才、才不太怕。",
		],
	},
	{
		"name": "Xiu",
		"lines": [
			"我能把灯笼全都数出来。没人信,但我真的可以。",
			"妈妈说不许一个人跑去竹林那边。",
		],
	},
	{
		"name": "Pei",
		"lines": [
			"我们比赛跑去井边吧!",
			"我昨天抓到一只蟋蟀,不过又把它放走了。",
		],
	},
	{
		"name": "Rong",
		"lines": [
			"货郎给我看过他的一根豆子。比我的手臂还长。",
			"大人总说屋檐响只是风声。",
		],
	},
	{
		"name": "Bao",
		"lines": [
			"长大以后我要盖一个像文昭家一样的屋顶。",
			"想看看我的石头收藏吗?真的很不错。",
		],
	},
]

var terrain: Node
var _rng := RandomNumberGenerator.new()
var _palace: Node3D
var _village_a: Node3D
var _village_b: Node3D
var _bamboo_island: Node3D
var _village_c: Node3D
var _village_d: Node3D
var _village_e: Node3D
var _royal_kitchen: StaticBody3D
var _village_a_positions: Array[Vector2] = []
var _village_b_positions: Array[Vector2] = []
var _proximity_lantern_lights: Array[OmniLight3D] = []
var _lantern_light_update_elapsed: float = 0.0
var _captive_blorb_displays: Array[Blorb] = []
var _royal_chef: Node3D


func _ready() -> void:
	terrain = get_node("../Terrain")
	_rng.seed = 20260906

	_palace = _build_island(PALACE_LOCAL, PALACE_RADIUS)
	_village_a = _build_island(VILLAGE_A_LOCAL, VILLAGE_A_RADIUS)
	_village_b = _build_island(VILLAGE_B_LOCAL, VILLAGE_B_RADIUS)
	_bamboo_island = _build_island(BAMBOO_ISLAND_LOCAL, BAMBOO_ISLAND_RADIUS)
	_village_c = _build_island(VILLAGE_C_LOCAL, VILLAGE_C_RADIUS)
	_village_d = _build_island(VILLAGE_D_LOCAL, VILLAGE_D_RADIUS)
	_village_e = _build_island(VILLAGE_E_LOCAL, VILLAGE_E_RADIUS)

	_build_bridge(PALACE_LOCAL, PALACE_RADIUS, VILLAGE_A_LOCAL, VILLAGE_A_RADIUS)
	_build_bridge(PALACE_LOCAL, PALACE_RADIUS, VILLAGE_B_LOCAL, VILLAGE_B_RADIUS)
	# The bamboo island is reached through the residential-island route below;
	# a second near-parallel bridge from the palace made the map read as an
	# accidental duplicate rather than an intentional network.
	_build_bridge(VILLAGE_A_LOCAL, VILLAGE_A_RADIUS, VILLAGE_C_LOCAL, VILLAGE_C_RADIUS)
	_build_bridge(VILLAGE_B_LOCAL, VILLAGE_B_RADIUS, VILLAGE_D_LOCAL, VILLAGE_D_RADIUS)
	_build_bridge(VILLAGE_C_LOCAL, VILLAGE_C_RADIUS, VILLAGE_E_LOCAL, VILLAGE_E_RADIUS)
	_build_bridge(VILLAGE_E_LOCAL, VILLAGE_E_RADIUS, BAMBOO_ISLAND_LOCAL, BAMBOO_ISLAND_RADIUS)
	_build_entry_bridge()

	_build_palace()
	_build_palace_interiors()
	_build_palace_gardens()
	_build_emperor()
	_build_royal_kitchen()
	_apply_blorb_captivity.call_deferred()

	# Play hut reserved first so the ordinary building scatter below (which
	# shares the same BUILDING_MIN_SPACING check) naturally avoids it.
	_build_play_hut()
	_village_a_positions.append(PLAY_HUT_LOCAL_POS)
	for i in VILLAGE_A_BUILDING_COUNT:
		_build_one_village_building(_village_a, VILLAGE_A_RADIUS, _village_a_positions)
	_spawn_kids()
	_spawn_villagers(_village_a, _village_a_positions, 0, VILLAGER_IDENTITIES.size() / 2)
	_build_sun_wu_kong.call_deferred()

	# Vendor stall reserved first, same reasoning as the play hut above.
	_build_vendor_stall()
	_village_b_positions.append(VENDOR_LOCAL_POS)
	for i in VILLAGE_B_BUILDING_COUNT:
		_build_one_village_building(_village_b, VILLAGE_B_RADIUS, _village_b_positions)
	# Each smaller residential island carries only one or two houses, leaving
	# visible grass and making the crossings meaningful.
	_build_pagoda(_village_c, Vector2(-3.0, 1.0), 2, 2)
	_build_pagoda(_village_c, Vector2(6.0, -5.0), 1, 2)
	_build_pagoda(_village_d, Vector2(-4.0, -2.0), 2, 2)
	_build_pagoda(_village_d, Vector2(6.0, 5.0), 1, 2)
	_build_pagoda(_village_e, Vector2.ZERO, 2, 2)
	_spawn_villagers(_village_b, _village_b_positions, VILLAGER_IDENTITIES.size() / 2, VILLAGER_IDENTITIES.size() - VILLAGER_IDENTITIES.size() / 2)

	_build_bamboo_forest()
	_build_farmer_and_pandy_quest.call_deferred()
	_decorate_island_with_trees(_palace, PALACE_RADIUS, 7)
	_decorate_island_with_trees(_village_a, VILLAGE_A_RADIUS, 3)
	_decorate_island_with_trees(_village_b, VILLAGE_B_RADIUS, 3)
	_decorate_island_with_trees(_village_c, VILLAGE_C_RADIUS, 2)
	_decorate_island_with_trees(_village_d, VILLAGE_D_RADIUS, 2)
	_decorate_island_with_trees(_village_e, VILLAGE_E_RADIUS, 2)

	_scatter_lanterns(_palace, PALACE_RADIUS)
	_scatter_lanterns(_village_a, VILLAGE_A_RADIUS)
	_scatter_lanterns(_village_b, VILLAGE_B_RADIUS)
	_scatter_lanterns(_village_c, VILLAGE_C_RADIUS)
	_scatter_lanterns(_village_d, VILLAGE_D_RADIUS)
	_scatter_lanterns(_village_e, VILLAGE_E_RADIUS)
	_update_proximity_lantern_lights()


func _process(delta: float) -> void:
	_lantern_light_update_elapsed += delta
	if _lantern_light_update_elapsed < LANTERN_LIGHT_UPDATE_INTERVAL:
		return
	_lantern_light_update_elapsed = 0.0
	_update_proximity_lantern_lights()


func _track_proximity_lantern(lantern: Node3D) -> void:
	var light := lantern.get_node_or_null("Light") as OmniLight3D
	if light != null:
		_proximity_lantern_lights.append(light)


func _update_proximity_lantern_lights() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var max_distance_squared := LANTERN_LIGHT_ENABLE_DISTANCE * LANTERN_LIGHT_ENABLE_DISTANCE
	for light in _proximity_lantern_lights:
		if is_instance_valid(light):
			light.visible = light.global_position.distance_squared_to(player.global_position) <= max_distance_squared


## A closed triangulated landform rather than a SuperEgg: its entire walkable
## crown is one genuinely flat mesh surface, while vertex-coloured rocky side
## walls taper to an irregular hanging-cliff underside. The concave collision
## is built from the exact same triangles, so feet, props and raycasts agree
## with what is rendered.
func _build_island(local_pos: Vector2, radius: float) -> Node3D:
	var world := VILLAGE_CENTER + local_pos
	var island := StaticBody3D.new()
	island.collision_layer = 1
	island.collision_mask = 0
	island.position = Vector3(world.x, ISLAND_SURFACE_Y, world.y)
	island.set_meta("walk_radius", radius * 0.82)
	add_child(island)

	var top_ring := PackedVector3Array()
	var lower_ring := PackedVector3Array()
	for sector in ISLAND_MESH_SECTORS:
		var angle: float = TAU * float(sector) / float(ISLAND_MESH_SECTORS)
		var outline_noise: float = 1.0 + sin(angle * 3.0 + radius) * ISLAND_EDGE_VARIATION * 0.55 + sin(angle * 7.0 - radius) * ISLAND_EDGE_VARIATION * 0.45
		var edge_radius: float = radius * outline_noise
		top_ring.append(Vector3(cos(angle) * edge_radius, 0.0, sin(angle) * edge_radius))
		var lower_radius: float = radius * (0.32 + 0.10 * sin(angle * 5.0 + 1.7))
		var lower_y: float = -radius * (0.72 + 0.12 * sin(angle * 4.0 - 0.8))
		lower_ring.append(Vector3(cos(angle) * lower_radius, lower_y, sin(angle) * lower_radius))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces: Array[Vector3] = []
	var top_center := Vector3.ZERO
	var bottom_center := Vector3(0.0, -radius * 0.94, 0.0)
	for sector in ISLAND_MESH_SECTORS:
		var next: int = (sector + 1) % ISLAND_MESH_SECTORS
		_add_island_triangle(st, faces, top_center, top_ring[sector], top_ring[next], ISLAND_GRASS_COLOR, Vector3.UP)
		_add_island_triangle(st, faces, top_ring[sector], lower_ring[sector], top_ring[next], ISLAND_ROCK_COLOR, Vector3.ZERO)
		_add_island_triangle(st, faces, top_ring[next], lower_ring[sector], lower_ring[next], ISLAND_ROCK_COLOR.darkened(0.08), Vector3.ZERO)
		_add_island_triangle(st, faces, bottom_center, lower_ring[next], lower_ring[sector], ISLAND_ROCK_COLOR.darkened(0.16), Vector3.DOWN)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.95
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	island.add_child(mesh_instance)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(PackedVector3Array(faces))
	shape.backface_collision = true
	var collision := CollisionShape3D.new()
	collision.shape = shape
	island.add_child(collision)

	return island


func _add_island_triangle(st: SurfaceTool, faces: Array[Vector3], a: Vector3, b: Vector3, c: Vector3, color: Color, forced_normal: Vector3) -> void:
	var normal: Vector3 = forced_normal
	if normal == Vector3.ZERO:
		normal = (b - a).cross(c - a).normalized()
	for vertex in [a, b, c]:
		st.set_color(color)
		st.set_normal(normal)
		st.add_vertex(vertex)
		faces.append(vertex)


## A flat plank walkway with simple post-and-rail sides, connecting two
## islands edge-to-edge along the straight line between their centers.
func _build_bridge(from_local: Vector2, from_radius: float, to_local: Vector2, to_radius: float) -> void:
	var direction := (to_local - from_local).normalized()
	var start_local := from_local + direction * from_radius * 0.91
	var end_local := to_local - direction * to_radius * 0.91
	var span := start_local.distance_to(end_local)
	if span <= 0.5:
		return
	_build_bridge_segment((start_local + end_local) * 0.5, span, direction)


func _build_entry_bridge() -> void:
	var rim_local := ENTRY_BRIDGE_DIRECTION * ENTRY_BRIDGE_RIM_DISTANCE
	var direction := (rim_local - PALACE_LOCAL).normalized()
	var start_local := PALACE_LOCAL + direction * PALACE_RADIUS * 0.91
	var end_world := VILLAGE_CENTER + rim_local
	var terrain_y: float = terrain.get_mesh_height(end_world.x, end_world.y)
	_build_bridge_segment_sloped((start_local + rim_local) * 0.5, start_local.distance_to(rim_local), direction, ISLAND_SURFACE_Y, terrain_y)


func _build_bridge_segment(mid_local: Vector2, span: float, direction: Vector2) -> void:
	_build_bridge_segment_sloped(mid_local, span, direction, ISLAND_SURFACE_Y, ISLAND_SURFACE_Y)


func _build_bridge_segment_sloped(mid_local: Vector2, span: float, direction: Vector2, from_y: float, to_y: float) -> void:
	var world := VILLAGE_CENTER + mid_local
	var bridge := StaticBody3D.new()
	bridge.collision_layer = 1
	bridge.collision_mask = 0
	bridge.position = Vector3(world.x, (from_y + to_y) * 0.5, world.y)
	bridge.rotation.y = atan2(direction.x, direction.y)
	bridge.rotation.x = -atan2(to_y - from_y, span)
	add_child(bridge)

	var deck := SuperEgg.build_part(
		Vector3(BRIDGE_WIDTH * 0.5, 0.15, span * 0.5), BRIDGE_PLANK_COLOR,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	deck.position = Vector3(0, -0.15, 0)
	bridge.add_child(deck)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(BRIDGE_WIDTH, 0.3, span)
	collision.shape = shape
	collision.position = Vector3(0, -0.15, 0)
	bridge.add_child(collision)

	for side in [-1.0, 1.0]:
		for t in [0.0, 0.5, 1.0]:
			var post := SuperEgg.build_part(
				Vector3(0.06, BRIDGE_RAIL_HEIGHT * 0.5, 0.06), BRIDGE_PLANK_COLOR,
				SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			post.position = Vector3(side * BRIDGE_WIDTH * 0.5, BRIDGE_RAIL_HEIGHT * 0.5, (t - 0.5) * span)
			bridge.add_child(post)
		var rail := SuperEgg.build_part(
			Vector3(0.04, 0.04, span * 0.5), BRIDGE_PLANK_COLOR,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		rail.position = Vector3(side * BRIDGE_WIDTH * 0.5, BRIDGE_RAIL_HEIGHT, 0)
		bridge.add_child(rail)
		# One continuous simplified guard volume represents the posts and rail
		# together. Leaving collision only on the individual thin visible pieces
		# would preserve large physics gaps that the player and small blorbs can
		# pass through; this fills those gaps without blocking either bridge end.
		var rail_collision := CollisionShape3D.new()
		var rail_shape := BoxShape3D.new()
		rail_shape.size = Vector3(0.14, BRIDGE_RAIL_HEIGHT + 0.08, span)
		rail_collision.shape = rail_shape
		rail_collision.position = Vector3(
			side * BRIDGE_WIDTH * 0.5,
			(BRIDGE_RAIL_HEIGHT + 0.08) * 0.5 - 0.04,
			0.0
		)
		bridge.add_child(rail_collision)


func _build_pagoda(island: Node3D, local_pos: Vector2, w: int, d: int, tier_count: int = EAVE_TIER_COUNT, floors: int = 1, imperial_gold: bool = false) -> Node3D:
	var roof_color: Color = ROOF_COLORS[_rng.randi() % ROOF_COLORS.size()]
	var wall_color := Color(0.88, 0.62, 0.12) if imperial_gold else TownProps.WALL_STONE
	var upper_color := Color(0.96, 0.76, 0.24) if imperial_gold else TownProps.WALL_WOOD
	var floor_color := Color(0.75, 0.47, 0.08) if imperial_gold else TownProps.FLOOR_COLOR
	var body := TownProps.build_building(w, d, floors, TRIM_COLOR if imperial_gold else roof_color, wall_color, upper_color, floor_color)
	body.position = Vector3(local_pos.x, 0, local_pos.y)
	body.rotation.y = 0.0 if imperial_gold else _rng.randf_range(0.0, TAU)
	island.add_child(body)

	# Stack tapering ornamental eave tiers above the building's own roof
	# peak -- same rise math _build_roof() itself uses (see town_props.gd's
	# own comment on that function), reproduced here rather than exposed as
	# a public helper since only this one caller needs it.
	var half_depth := d * TownProps.CELL_SIZE * 0.5 + TownProps.ROOF_OVERHANG
	var slope_len := half_depth / cos(TownProps.ROOF_PITCH)
	var y := TownProps.FLOOR_HEIGHT * floors + slope_len * sin(TownProps.ROOF_PITCH)
	var tier_half_width := maxf(w, d) * TownProps.CELL_SIZE * 0.5 * EAVE_WIDTH_FRACTION
	for i in tier_count:
		var tier := SuperEgg.build_part(
			Vector3(tier_half_width, EAVE_TIER_HEIGHT * 0.5, tier_half_width), TRIM_COLOR,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		tier.position = Vector3(0, y + EAVE_TIER_HEIGHT * 0.5, 0)
		body.add_child(tier)
		y += EAVE_TIER_HEIGHT + EAVE_TIER_GAP
		tier_half_width *= EAVE_TIER_SHRINK
	var finial := SuperEgg.build_part(FINIAL_SIZE, TRIM_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	finial.position = Vector3(0, y + FINIAL_SIZE.y * 0.5, 0)
	body.add_child(finial)
	return body


## Four successively smaller, genuinely traversable storeys. The ramps are
## broad internal stair-ramps arranged as a switchback: each one rises through
## a real rectangular stairwell in the floor above and arrives at an open
## landing. This keeps the circulation legible and prevents the old exterior
## ramps from clipping through walls or terminating beneath a solid floor.
func _build_palace() -> void:
	var gold := Color(0.88, 0.62, 0.12)
	var red := Color(0.66, 0.055, 0.045)
	var floor_color := Color(0.76, 0.48, 0.08)
	for level in PALACE_LEVEL_COUNT:
		var cells: int = PALACE_CELLS - level * PALACE_CELLS_PER_LEVEL_SHRINK
		var width: float = float(cells) * TownProps.CELL_SIZE
		var depth: float = width
		var base_y: float = float(level) * PALACE_STOREY_HEIGHT
		# Only the ground storey supplies a complete base slab. Every higher
		# storey stands on the segmented ceiling built by the level below, so a
		# second full slab cannot accidentally seal its stairwell.
		if level == 0:
			_add_palace_block(Vector3(PALACE_LOCAL_POS.x, base_y, PALACE_LOCAL_POS.y), Vector3(width + PALACE_EAVE_OVERHANG * 2.0, 0.18, depth + PALACE_EAVE_OVERHANG * 2.0), floor_color)
		var wall_y: float = base_y + PALACE_STOREY_HEIGHT * 0.5
		_add_palace_block(Vector3(PALACE_LOCAL_POS.x - width * 0.5, wall_y, PALACE_LOCAL_POS.y), Vector3(PALACE_WALL_THICKNESS, PALACE_STOREY_HEIGHT, depth), gold)
		_add_palace_block(Vector3(PALACE_LOCAL_POS.x + width * 0.5, wall_y, PALACE_LOCAL_POS.y), Vector3(PALACE_WALL_THICKNESS, PALACE_STOREY_HEIGHT, depth), gold)
		var back_z: float = PALACE_LOCAL_POS.y - depth * 0.5
		if level == 0:
			var back_piece_width: float = (width - PALACE_DOOR_WIDTH) * 0.5
			_add_palace_block(Vector3(PALACE_LOCAL_POS.x - (PALACE_DOOR_WIDTH + back_piece_width) * 0.5, wall_y, back_z), Vector3(back_piece_width, PALACE_STOREY_HEIGHT, PALACE_WALL_THICKNESS), gold)
			_add_palace_block(Vector3(PALACE_LOCAL_POS.x + (PALACE_DOOR_WIDTH + back_piece_width) * 0.5, wall_y, back_z), Vector3(back_piece_width, PALACE_STOREY_HEIGHT, PALACE_WALL_THICKNESS), gold)
			_add_palace_block(Vector3(PALACE_LOCAL_POS.x, base_y + PALACE_STOREY_HEIGHT - 0.35, back_z), Vector3(PALACE_DOOR_WIDTH, 0.7, PALACE_WALL_THICKNESS), TRIM_COLOR)
		else:
			_add_palace_block(Vector3(PALACE_LOCAL_POS.x, wall_y, back_z), Vector3(width, PALACE_STOREY_HEIGHT, PALACE_WALL_THICKNESS), gold)
		var front_piece_width: float = (width - PALACE_DOOR_WIDTH) * 0.5
		var front_z: float = PALACE_LOCAL_POS.y + depth * 0.5
		_add_palace_block(Vector3(PALACE_LOCAL_POS.x - (PALACE_DOOR_WIDTH + front_piece_width) * 0.5, wall_y, front_z), Vector3(front_piece_width, PALACE_STOREY_HEIGHT, PALACE_WALL_THICKNESS), red)
		_add_palace_block(Vector3(PALACE_LOCAL_POS.x + (PALACE_DOOR_WIDTH + front_piece_width) * 0.5, wall_y, front_z), Vector3(front_piece_width, PALACE_STOREY_HEIGHT, PALACE_WALL_THICKNESS), red)
		_add_palace_block(Vector3(PALACE_LOCAL_POS.x, base_y + PALACE_STOREY_HEIGHT - 0.35, front_z), Vector3(PALACE_DOOR_WIDTH, 0.7, PALACE_WALL_THICKNESS), TRIM_COLOR)
		if level < PALACE_LEVEL_COUNT - 1:
			var run: float = 8.0
			var ramp_width: float = 2.6
			var side: float = 1.0 if level % 2 == 0 else -1.0
			var next_cells: int = cells - PALACE_CELLS_PER_LEVEL_SHRINK
			var next_width: float = float(next_cells) * TownProps.CELL_SIZE
			# Keep the entire well just inside the smaller storey above. Alternating
			# sides makes a compact, readable switchback without putting a ramp in
			# the throne-room axis or in either doorway.
			var ramp_x: float = PALACE_LOCAL_POS.x + side * (next_width * 0.5 - ramp_width * 0.85)
			var travel_sign: float = 1.0 if level % 2 == 0 else -1.0
			var ramp_z: float = PALACE_LOCAL_POS.y - travel_sign * run * 0.5
			var ramp := TownProps.build_ramp(ramp_width, run, PALACE_STOREY_HEIGHT, red)
			ramp.position = Vector3(ramp_x, base_y, ramp_z)
			ramp.rotation.y = 0.0 if travel_sign > 0.0 else PI
			_palace.add_child(ramp)

			var well_size := Vector2(ramp_width + 0.8, run)
			var well_center := Vector2(ramp_x, PALACE_LOCAL_POS.y)
			_add_palace_floor_with_stairwell(
				base_y + PALACE_STOREY_HEIGHT, width + PALACE_EAVE_OVERHANG * 2.0,
				depth + PALACE_EAVE_OVERHANG * 2.0, well_center, well_size, TRIM_COLOR
			)
			_add_stairwell_guard(well_center, well_size, base_y + PALACE_STOREY_HEIGHT, travel_sign, gold)
		else:
			# The crown roof is the only complete upper slab; there is nowhere
			# further to climb, so it needs no stairwell aperture.
			_add_palace_block(Vector3(PALACE_LOCAL_POS.x, base_y + PALACE_STOREY_HEIGHT, PALACE_LOCAL_POS.y), Vector3(width + PALACE_EAVE_OVERHANG * 2.0, 0.22, depth + PALACE_EAVE_OVERHANG * 2.0), TRIM_COLOR)

	var crown := SuperEgg.build_part(Vector3(4.5, 0.35, 4.5), TRIM_COLOR, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	crown.position = Vector3(PALACE_LOCAL_POS.x, float(PALACE_LEVEL_COUNT) * PALACE_STOREY_HEIGHT + 0.35, PALACE_LOCAL_POS.y)
	_palace.add_child(crown)
	# The crown used to be visual-only, leaving the lower roof slab as the
	# highest collision. Characters consequently stood half inside this cap.
	var crown_collision := CollisionShape3D.new()
	var crown_shape := BoxShape3D.new()
	crown_shape.size = Vector3(9.0, 0.70, 9.0)
	crown_collision.shape = crown_shape
	crown_collision.position = crown.position
	_palace.add_child(crown_collision)


## Build one floor as four non-overlapping slabs around a rectangular opening.
## The opening encloses the full ramp (not merely its upper endpoint), which
## gives the player proper head clearance for the entire ascent.
func _add_palace_floor_with_stairwell(floor_y: float, width: float, depth: float, well_center: Vector2, well_size: Vector2, color: Color) -> void:
	var left: float = PALACE_LOCAL_POS.x - width * 0.5
	var right: float = PALACE_LOCAL_POS.x + width * 0.5
	var back: float = PALACE_LOCAL_POS.y - depth * 0.5
	var front: float = PALACE_LOCAL_POS.y + depth * 0.5
	var well_left: float = well_center.x - well_size.x * 0.5
	var well_right: float = well_center.x + well_size.x * 0.5
	var well_back: float = well_center.y - well_size.y * 0.5
	var well_front: float = well_center.y + well_size.y * 0.5
	var left_width: float = well_left - left
	var right_width: float = right - well_right
	var back_depth: float = well_back - back
	var front_depth: float = front - well_front
	_add_palace_block(Vector3(left + left_width * 0.5, floor_y, PALACE_LOCAL_POS.y), Vector3(left_width, 0.22, depth), color)
	_add_palace_block(Vector3(well_right + right_width * 0.5, floor_y, PALACE_LOCAL_POS.y), Vector3(right_width, 0.22, depth), color)
	_add_palace_block(Vector3(well_center.x, floor_y, back + back_depth * 0.5), Vector3(well_size.x, 0.22, back_depth), color)
	_add_palace_block(Vector3(well_center.x, floor_y, well_front + front_depth * 0.5), Vector3(well_size.x, 0.22, front_depth), color)


## Low guard edges make the aperture readable and prevent accidental side or
## rear falls. The end where that level's ramp emerges stays open onto the
## upper landing; alternating that end completes the switchback circulation.
func _add_stairwell_guard(well_center: Vector2, well_size: Vector2, floor_y: float, egress_sign: float, color: Color) -> void:
	var rail_height: float = 0.82
	var rail_thickness: float = 0.14
	var rail_y: float = floor_y + rail_height * 0.5
	for side in [-1.0, 1.0]:
		_add_palace_block(
			Vector3(well_center.x + side * (well_size.x * 0.5 + rail_thickness * 0.5), rail_y, well_center.y),
			Vector3(rail_thickness, rail_height, well_size.y + rail_thickness * 2.0), color
		)
	_add_palace_block(
		Vector3(well_center.x, rail_y, well_center.y - egress_sign * well_size.y * 0.5 - egress_sign * rail_thickness * 0.5),
		Vector3(well_size.x, rail_height, rail_thickness), color
	)


func _build_palace_interiors() -> void:
	var red := Color(0.58, 0.035, 0.03)
	var dark_wood := Color(0.19, 0.075, 0.035)
	var gold := Color(0.9, 0.66, 0.16)
	# Ground-floor axial carpet and raised throne dais establish a ceremonial
	# sightline immediately through the main entrance.
	_add_palace_block(Vector3(0.0, 0.14, -7.0), Vector3(4.2, 0.08, 18.0), red)
	for step in 3:
		_add_palace_block(Vector3(0.0, 0.18 + float(step) * 0.24, -17.0 - float(step) * 0.42), Vector3(6.8 - float(step) * 0.6, 0.24, 4.6 - float(step) * 0.55), gold.darkened(float(step) * 0.06))
	var throne := SuperEgg.build_part(Vector3(1.25, 1.45, 0.72), gold, 3.4, SuperEgg.EPSILON_FLAT)
	throne.position = Vector3(0.0, 2.0, -18.3)
	_palace.add_child(throne)
	var throne_seat := SuperEgg.build_part(Vector3(1.05, 0.22, 0.85), red, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	throne_seat.position = Vector3(0.0, 0.92, -17.65)
	_palace.add_child(throne_seat)
	# Lacquer columns, low side benches, and symmetrical lantern rows repeat
	# through all four levels without blocking doors or stair terraces.
	for level in PALACE_LEVEL_COUNT:
		var cells: int = PALACE_CELLS - level * PALACE_CELLS_PER_LEVEL_SHRINK
		var half_width: float = float(cells) * TownProps.CELL_SIZE * 0.5
		var base_y: float = float(level) * PALACE_STOREY_HEIGHT
		for side in [-1.0, 1.0]:
			for z_offset in [-half_width * 0.48, 0.0, half_width * 0.48]:
				var column := SuperEgg.build_part(Vector3(0.24, PALACE_STOREY_HEIGHT * 0.43, 0.24), red, 2.6, 2.6)
				column.position = Vector3(side * (half_width - 1.25), base_y + PALACE_STOREY_HEIGHT * 0.5, PALACE_LOCAL_POS.y + z_offset)
				_palace.add_child(column)
			var bench := SuperEgg.build_part(Vector3(1.8, 0.3, 0.48), dark_wood, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
			bench.position = Vector3(side * (half_width - 2.0), base_y + 0.32, PALACE_LOCAL_POS.y + 1.2)
			_palace.add_child(bench)
		for x in [-half_width * 0.48, 0.0, half_width * 0.48]:
			var lantern := _build_deng_long()
			lantern.position = Vector3(x, base_y + PALACE_STOREY_HEIGHT - 0.75, PALACE_LOCAL_POS.y)
			_palace.add_child(lantern)
			_track_proximity_lantern(lantern)


func _build_deng_long() -> Node3D:
	var root := Node3D.new()
	root.name = "DengLong"
	root.add_to_group("lanterns")
	var body := SuperEgg.build_part(Vector3(0.34, 0.43, 0.34), Color(0.86, 0.055, 0.035), 2.2, 2.2)
	body.name = "Head"
	var body_material := body.get_surface_override_material(0) as StandardMaterial3D
	body_material.emission_enabled = true
	body_material.emission = Color(1.0, 0.18, 0.06)
	body_material.emission_energy_multiplier = 1.0
	root.add_child(body)
	for y in [-0.42, 0.42]:
		var rim := SuperEgg.build_part(Vector3(0.3, 0.035, 0.3), TRIM_COLOR, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		rim.position.y = y
		root.add_child(rim)
	var tassel := SuperEgg.build_part(Vector3(0.035, 0.28, 0.035), TRIM_COLOR, 2.0, 2.0)
	tassel.position.y = -0.68
	root.add_child(tassel)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = Color(1.0, 0.4, 0.12)
	light.light_energy = 0.95
	light.omni_range = 8.0
	light.shadow_enabled = false
	root.add_child(light)
	return root


func _build_palace_gardens() -> void:
	# Bilateral stone paths, clipped shrubs, flowering trees and small pools
	# frame the entrance while leaving bridge and doorway circulation clear.
	for side in [-1.0, 1.0]:
		for row in 4:
			var z := 8.0 + float(row) * 6.2
			var tree := NatureProps.build_flowering_tree(
				_rng.randf_range(4.2, 5.8), Color(0.16, 0.44, 0.2),
				Color(0.88, 0.42, 0.58), _rng
			)
			tree.position = Vector3(side * 18.0, 0.0, z)
			_palace.add_child(tree)
			var shrub := SuperEgg.build_part(Vector3(1.35, 0.55, 1.05), Color(0.12, 0.43, 0.19), 3.4, 3.4)
			shrub.position = Vector3(side * 11.0, 0.55, z + 1.7)
			_palace.add_child(shrub)
		for stone_index in 7:
			var stone := SuperEgg.build_part(Vector3(0.72, 0.09, 1.05), Color(0.42, 0.39, 0.34), 3.5, 4.0)
			# The ground-floor front facade is at local Z=10. Start beyond its
			# eave/threshold and continue outward into the garden; the former Z=4
			# origin sent the first half of each path through the throne room.
			stone.position = Vector3(side * 4.0, 0.09, 12.0 + float(stone_index) * 3.0)
			_palace.add_child(stone)


func _add_palace_block(block_position: Vector3, size: Vector3, color: Color) -> void:
	var block := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	block.position = block_position
	_palace.add_child(block)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = block_position
	_palace.add_child(collision)


## Loose rejection sampling, not a rigid grid -- per direct confirmation
## this is meant to feel like a "sprawling" organic settlement.
func _pick_building_position(radius: float, existing: Array[Vector2], footprint_radius: float) -> Vector2:
	var clear_center := radius * 0.25
	var usable_radius: float = maxf(0.0, radius * 0.82 - footprint_radius)
	for attempt in 20:
		var angle := _rng.randf_range(0.0, TAU)
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * usable_radius
		var candidate := Vector2(cos(angle) * r, sin(angle) * r)
		if candidate.length() < clear_center:
			continue
		var ok := true
		for pos in existing:
			if candidate.distance_to(pos) < BUILDING_MIN_SPACING:
				ok = false
				break
		if ok:
			return candidate
	return Vector2.INF


func _build_one_village_building(island: Node3D, radius: float, positions: Array[Vector2]) -> void:
	var w: int = _rng.randi_range(BUILDING_CELL_MIN, BUILDING_CELL_MAX)
	var d: int = _rng.randi_range(BUILDING_CELL_MIN, BUILDING_CELL_MAX)
	var footprint_radius: float = Vector2(float(w), float(d)).length() * TownProps.CELL_SIZE * 0.5 + TownProps.ROOF_OVERHANG
	var local_pos := _pick_building_position(radius, positions, footprint_radius)
	if local_pos == Vector2.INF:
		return
	positions.append(local_pos)
	_build_pagoda(island, local_pos, w, d)


func _scatter_lanterns(island: Node3D, radius: float) -> void:
	for i in LANTERN_COUNT_PER_ISLAND:
		var angle := _rng.randf_range(0.0, TAU)
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * radius
		var lantern := TownProps.build_lantern()
		lantern.position = Vector3(cos(angle) * r, 0, sin(angle) * r)
		island.add_child(lantern)
		_track_proximity_lantern(lantern)


func _spawn_villagers(island: Node3D, positions: Array[Vector2], identity_offset: int, count: int) -> void:
	for i in count:
		var identity_index := identity_offset + i
		var local_pos: Vector2 = positions[i % positions.size()] if not positions.is_empty() else Vector2.ZERO
		var jitter := Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-4.0, 4.0))
		var local := local_pos + jitter
		var npc_inst: Node3D = NPC_SCENE.instantiate()
		npc_inst.set_terrain_reference(terrain)
		npc_inst.fixed_ground_y = ISLAND_SURFACE_Y
		npc_inst.wander_boundary_center = Vector2(island.global_position.x, island.global_position.z)
		npc_inst.wander_boundary_radius = float(island.get_meta("walk_radius", 0.0))
		_assign_villager_identity(npc_inst, identity_index)
		npc_inst.position = Vector3(local.x, 0, local.y)
		island.add_child(npc_inst)


func _assign_villager_identity(npc_inst: Node3D, index: int) -> void:
	var identity: Dictionary = VILLAGER_IDENTITIES[index % VILLAGER_IDENTITIES.size()]
	npc_inst.display_name = identity["name"]
	var lines: Array[String] = []
	lines.assign(identity["lines"])
	npc_inst.talk_lines = lines
	npc_inst.is_female = _rng.randf() < 0.5
	# Fixed default look for ordinary adult villagers, per direct
	# instruction -- not drawn from a random pool the way outfit colors
	# below still are.
	npc_inst.skin_color = SKIN_COLORS[1]
	npc_inst.hair_color = HAIR_COLORS[0]
	npc_inst.hair_style = FigureHair.STYLE_BUN
	npc_inst.shirt_color = SHIRT_COLORS[_rng.randi() % SHIRT_COLORS.size()]
	npc_inst.pants_color = PANTS_COLORS[_rng.randi() % PANTS_COLORS.size()]
	npc_inst.body_scale = _rng.randf_range(0.92, 1.08)


## Small roaming children on Village A, per direct instruction. Reuses the
## villagers' own fixed skin/hair-color default but at a much closer-to-
## adult body_scale (see KID_BODY_SCALE_MIN/MAX's own comment) and the
## "soft" rounded build-scale sliders (KID_ABDOMEN_WIDTH_SCALE/
## KID_CHEST_BUILD_SCALE/KID_HIP_BUILD_SCALE) rather than a plain uniform
## shrink, so they read as pudgy children instead of shrunk-down adults.
## KID_IDENTITIES[0] (Ting) is guaranteed the new STYLE_PIGTAILS.
func _spawn_kids() -> void:
	for i in KID_IDENTITIES.size():
		var jitter := Vector2(_rng.randf_range(-KID_ROAM_JITTER, KID_ROAM_JITTER), _rng.randf_range(-KID_ROAM_JITTER, KID_ROAM_JITTER))
		var local := PLAY_HUT_LOCAL_POS + jitter
		var npc_inst: Node3D = NPC_SCENE.instantiate()
		npc_inst.set_terrain_reference(terrain)
		npc_inst.fixed_ground_y = ISLAND_SURFACE_Y
		npc_inst.wander_boundary_center = Vector2(_village_a.global_position.x, _village_a.global_position.z)
		npc_inst.wander_boundary_radius = float(_village_a.get_meta("walk_radius", 0.0))
		var identity: Dictionary = KID_IDENTITIES[i]
		npc_inst.display_name = identity["name"]
		var lines: Array[String] = []
		lines.assign(identity["lines"])
		npc_inst.talk_lines = lines
		npc_inst.is_female = _rng.randf() < 0.5
		npc_inst.skin_color = SKIN_COLORS[1]
		npc_inst.hair_color = HAIR_COLORS[0]
		npc_inst.hair_style = FigureHair.STYLE_PIGTAILS if i == 0 else KID_HAIR_STYLES[_rng.randi() % KID_HAIR_STYLES.size()]
		npc_inst.shirt_color = SHIRT_COLORS[_rng.randi() % SHIRT_COLORS.size()]
		npc_inst.pants_color = PANTS_COLORS[_rng.randi() % PANTS_COLORS.size()]
		npc_inst.body_scale = _rng.randf_range(KID_BODY_SCALE_MIN, KID_BODY_SCALE_MAX)
		npc_inst.abdomen_width_scale = KID_ABDOMEN_WIDTH_SCALE
		npc_inst.chest_build_scale = KID_CHEST_BUILD_SCALE
		npc_inst.hip_build_scale = KID_HIP_BUILD_SCALE
		npc_inst.position = Vector3(local.x, 0, local.y)
		_village_a.add_child(npc_inst)


## The kids' own play hut -- a rough teepee of leaned stick poles (thin
## SuperEgg cylinders converging toward a shared apex, each oriented along
## its own base-to-apex tangent), plus loose sticks scattered at its base.
## Sun Wu Kong's staff hides among those loose sticks.
func _build_play_hut() -> void:
	var hut := Node3D.new()
	hut.position = Vector3(PLAY_HUT_LOCAL_POS.x, 0, PLAY_HUT_LOCAL_POS.y)
	_village_a.add_child(hut)

	var material := StandardMaterial3D.new()
	material.albedo_color = PLAY_HUT_STICK_COLOR
	material.roughness = 0.85

	var apex := Vector3(0, PLAY_HUT_POLE_HEIGHT, 0)
	for i in PLAY_HUT_POLE_COUNT:
		var angle := TAU * float(i) / float(PLAY_HUT_POLE_COUNT)
		var base_pos := Vector3(cos(angle) * PLAY_HUT_BASE_RADIUS, 0.0, sin(angle) * PLAY_HUT_BASE_RADIUS)
		var to_apex := apex - base_pos
		var pole_length := to_apex.length()
		var y_axis := to_apex.normalized()
		var x_axis := y_axis.cross(Vector3.UP)
		if x_axis.length() < 0.001:
			x_axis = Vector3.RIGHT
		x_axis = x_axis.normalized()
		var z_axis := x_axis.cross(y_axis).normalized()
		var pole := MeshInstance3D.new()
		pole.mesh = SuperEgg.build_mesh(
			Vector3(PLAY_HUT_POLE_RADIUS, pole_length * 0.5, PLAY_HUT_POLE_RADIUS),
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		pole.set_surface_override_material(0, material)
		pole.basis = Basis(x_axis, y_axis, z_axis)
		pole.position = (base_pos + apex) * 0.5
		hut.add_child(pole)

	for i in LOOSE_STICK_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(0.0, PLAY_HUT_BASE_RADIUS * 1.3)
		var stick := MeshInstance3D.new()
		stick.mesh = SuperEgg.build_mesh(
			Vector3(0.02, _rng.randf_range(0.18, 0.32), 0.02), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		stick.set_surface_override_material(0, material)
		stick.rotation.z = deg_to_rad(90.0) + _rng.randf_range(-0.3, 0.3)
		stick.rotation.y = _rng.randf_range(0.0, TAU)
		stick.position = Vector3(cos(angle) * r, 0.02, sin(angle) * r)
		hut.add_child(stick)

	_build_jingu_bang_pickup(hut)


## Sun Wu Kong's staff, hidden among the play hut's own loose sticks. Reuses
## Fruit (a generic proximity pickup that adds a named item to Inventory)
## exactly the way primate_kingdom_gorilla.gd's own Special Banana pickup
## does. The visual itself now lives on ShopCatalog (build_jingu_bang_
## visual()), not here -- it also has to be reachable by name from
## player.gd's own held-item system (see ShopCatalog.find()), so this pickup
## calls the same public builder rather than keeping a separate local copy.
func _build_jingu_bang_pickup(hut: Node3D) -> void:
	if WorldState.sun_wu_kong_has_jingu_bang or Inventory.has(SunWuKong.JINGU_BANG_ITEM_NAME):
		return
	var pickup := Fruit.new()
	pickup.fruit_name = SunWuKong.JINGU_BANG_ITEM_NAME
	pickup.fruit_color = ShopCatalog.JINGU_BANG_RED
	pickup.radius = 0.4
	pickup.visual_builder = func() -> Node3D: return ShopCatalog.build_jingu_bang_visual()
	pickup.position = Vector3(0.15, 0.35, -0.1)
	pickup.rotation.z = deg_to_rad(90.0) + _rng.randf_range(-0.2, 0.2)
	pickup.rotation.y = _rng.randf_range(0.0, TAU)
	hut.add_child(pickup)


## Sun Wu Kong, sealed beneath the rock crowning the Emperor's castle --
## added via get_parent().add_child() (Main's own root, a direct sibling of
## Player/Terrain), NOT island.add_child() -- sun_wu_kong.gd resolves
## "../Player"/"../Terrain" via that exact fixed-sibling lookup (see its
## own class doc comment), and its own _ground_y() helper is already
## abyss-aware, so no fixed_ground_y-style override is needed here the way
## ordinary npc.gd instances need one.
func _build_sun_wu_kong() -> void:
	var sage: SunWuKong = SUN_WU_KONG_SCENE.instantiate()
	var world := VILLAGE_CENTER + PALACE_LOCAL + SUN_WU_KONG_LOCAL_POS
	sage.fixed_ground_y = ISLAND_SURFACE_Y + SUN_WU_KONG_CASTLE_Y
	get_parent().add_child(sage)
	sage.global_position = Vector3(world.x, sage.fixed_ground_y, world.y)


## A little bamboo forest, scattered sparsely across its own island rather
## than in one dense grove -- per direct instruction ("bamboo populating
## the islands sporadically"). Each stalk is a stack of near-uniform-radius
## SuperEgg segments separated by thin "node" rings, with a handful of
## thin blade-like leaves fanned out near the top.
func _build_bamboo_forest() -> void:
	var clusters: Array[Vector2] = [Vector2(-8.0, -3.0), Vector2(7.0, 5.0), Vector2(-2.0, 11.0)]
	var segment_transforms: Array[Transform3D] = []
	var ring_transforms: Array[Transform3D] = []
	var leaf_transforms: Array[Transform3D] = []
	for i in BAMBOO_STALK_COUNT:
		var local_pos: Vector2
		if i % 7 == 0:
			var lone_angle: float = _rng.randf_range(0.0, TAU)
			var lone_radius: float = _rng.randf_range(8.0, BAMBOO_ISLAND_RADIUS * 0.72)
			local_pos = Vector2(cos(lone_angle), sin(lone_angle)) * lone_radius
		else:
			var center: Vector2 = clusters[_rng.randi() % clusters.size()]
			var cluster_angle: float = _rng.randf_range(0.0, TAU)
			var cluster_radius: float = sqrt(_rng.randf()) * _rng.randf_range(2.0, 6.5)
			local_pos = center + Vector2(cos(cluster_angle), sin(cluster_angle)) * cluster_radius
		if local_pos.length() > BAMBOO_ISLAND_RADIUS * 0.76 or local_pos.distance_to(FARMER_LOCAL_POS) < 2.5:
			continue
		_append_bamboo_stalk_instances(local_pos, segment_transforms, ring_transforms, leaf_transforms)
	_add_bamboo_multimesh("BambooSegments", segment_transforms, Vector3.ONE, BAMBOO_COLOR, SuperEgg.EPSILON_FLAT)
	_add_bamboo_multimesh("BambooNodes", ring_transforms, Vector3.ONE, BAMBOO_NODE_COLOR, SuperEgg.EPSILON_FLAT)
	_add_bamboo_multimesh("BambooLeaves", leaf_transforms, Vector3.ONE, BAMBOO_LEAF_COLOR, SuperEgg.EPSILON_SOFT)


func _decorate_island_with_trees(island: Node3D, radius: float, count: int) -> void:
	var leaf_colors: Array[Color] = [Color(0.12, 0.46, 0.22), Color(0.18, 0.55, 0.25), Color(0.24, 0.61, 0.3)]
	for i in count:
		var angle: float = _rng.randf_range(0.0, TAU)
		var distance: float = _rng.randf_range(radius * 0.58, radius * 0.73)
		var local_pos: Vector2 = Vector2(cos(angle), sin(angle)) * distance
		if island == _palace and local_pos.y > radius * 0.45:
			local_pos = local_pos.rotated(0.75)
		var tree := NatureProps.build_round_tree(_rng.randf_range(3.8, 6.2), leaf_colors[_rng.randi() % leaf_colors.size()])
		tree.position = Vector3(local_pos.x, 0.0, local_pos.y)
		island.add_child(tree)


func _append_bamboo_stalk_instances(local_pos: Vector2, segments: Array[Transform3D], rings: Array[Transform3D], leaves: Array[Transform3D]) -> void:
	var root_transform := Transform3D(Basis(Vector3.UP, _rng.randf_range(0.0, TAU)), Vector3(local_pos.x, 0.0, local_pos.y))
	var radius: float = _rng.randf_range(BAMBOO_RADIUS_MIN, BAMBOO_RADIUS_MAX)
	var lean: float = _rng.randf_range(-0.05, 0.05)
	var y: float = 0.0
	for i in BAMBOO_SEGMENT_COUNT:
		var segment_basis := Basis.IDENTITY.scaled(Vector3(radius, BAMBOO_SEGMENT_HEIGHT * 0.5, radius))
		segments.append(root_transform * Transform3D(segment_basis, Vector3(sin(lean) * y, y + BAMBOO_SEGMENT_HEIGHT * 0.5, 0.0)))
		y += BAMBOO_SEGMENT_HEIGHT
		var ring_scale := Vector3(radius * BAMBOO_NODE_RADIUS_BOOST, 0.03, radius * BAMBOO_NODE_RADIUS_BOOST)
		rings.append(root_transform * Transform3D(Basis.IDENTITY.scaled(ring_scale), Vector3(sin(lean) * y, y, 0.0)))

	for i in BAMBOO_LEAF_COUNT:
		var leaf_angle: float = _rng.randf_range(0.0, TAU)
		var leaf_y: float = y - _rng.randf_range(0.0, BAMBOO_SEGMENT_HEIGHT * 1.5)
		var leaf_basis := Basis.from_euler(Vector3(0.0, leaf_angle, _rng.randf_range(-0.6, 0.6))).scaled(Vector3(0.02, 0.18, 0.05))
		var leaf_position := Vector3(cos(leaf_angle) * radius * 1.5, leaf_y, sin(leaf_angle) * radius * 1.5)
		leaves.append(root_transform * Transform3D(leaf_basis, leaf_position))


func _add_bamboo_multimesh(node_name: String, transforms: Array[Transform3D], template_scale: Vector3, color: Color, epsilon: float) -> void:
	if transforms.is_empty():
		return
	var template := SuperEgg.build_part(template_scale, color, epsilon, epsilon)
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = template.mesh
	instances.instance_count = transforms.size()
	for index in transforms.size():
		instances.set_instance_transform(index, transforms[index])
	var batch := MultiMeshInstance3D.new()
	batch.name = node_name
	batch.multimesh = instances
	batch.material_override = template.get_surface_override_material(0)
	_bamboo_island.add_child(batch)
	template.free()


## The outdoor merchant's stall -- selling "some wares, including the bean
## of life." Reuses TownProps.build_stall() and the vendor-NPC pattern
## town_generator.gd's own _build_one_shop_stall() establishes (is_vendor +
## shop_category, opening ShopUI on talk to whatever ShopCatalog.
## get_items_for_shop() returns for that category).
func _build_vendor_stall() -> void:
	var stall: Dictionary = TownProps.build_stall(ROOF_COLORS[0])
	var stall_body: StaticBody3D = stall["body"]
	stall_body.position = Vector3(VENDOR_LOCAL_POS.x, 0, VENDOR_LOCAL_POS.y)
	stall_body.rotation.y = _rng.randf_range(0.0, TAU)
	_village_b.add_child(stall_body)

	var counter_y: float = stall["counter_y"]
	var index := 0
	for item in ShopCatalog.get_items_for_shop("chinese_village"):
		if not item.get("purchasable", false):
			continue
		var visual: Node3D = item["build_visual"].call(1.0)
		visual.position = Vector3((float(index) - 1.0) * 0.3, counter_y + 0.05, 0)
		stall_body.add_child(visual)
		index += 1

	var vendor_local := VENDOR_LOCAL_POS + Vector2(0.9, 0.0).rotated(stall_body.rotation.y)
	var npc_inst: Node3D = NPC_SCENE.instantiate()
	npc_inst.set_terrain_reference(terrain)
	npc_inst.fixed_ground_y = ISLAND_SURFACE_Y
	npc_inst.display_name = VENDOR_NAME
	var lines: Array[String] = []
	lines.assign(VENDOR_LINES)
	npc_inst.vendor_lines = lines
	npc_inst.is_vendor = true
	npc_inst.shop_category = "chinese_village"
	npc_inst.stationary = true
	npc_inst.skin_color = SKIN_COLORS[1]
	npc_inst.hair_color = HAIR_COLORS[0]
	npc_inst.hair_style = FigureHair.STYLE_BUN
	npc_inst.shirt_color = TRIM_COLOR
	npc_inst.pants_color = PANTS_COLORS[0]
	npc_inst.body_scale = 1.0
	npc_inst.position = Vector3(vendor_local.x, 0, vendor_local.y)
	_village_b.add_child(npc_inst)


## The Emperor begins under the Royal Chef's influence. The farmer's account
## unlocks the audience in which the Emperor mistakes the blorbs for rou bao;
## defeating the Chef later breaks that influence and restores this dialogue.
func _build_emperor() -> void:
	var npc_inst: Node3D = NPC_SCENE.instantiate()
	npc_inst.set_terrain_reference(terrain)
	npc_inst.fixed_ground_y = ISLAND_SURFACE_Y + 0.08
	npc_inst.display_name = EMPEROR_NAME
	npc_inst.stationary = true
	npc_inst.is_female = false
	npc_inst.skin_color = SKIN_COLORS[0]
	npc_inst.hair_color = HAIR_COLORS[0]
	npc_inst.hair_style = FigureHair.STYLE_BUN
	npc_inst.shirt_color = Color(0.66, 0.055, 0.045)
	npc_inst.pants_color = Color(0.66, 0.055, 0.045)
	npc_inst.shoe_color = PANTS_COLORS[0]
	npc_inst.wears_full_boots = true
	npc_inst.wears_dress = true
	npc_inst.dress_color = Color(0.66, 0.055, 0.045)
	npc_inst.wears_emperor_regalia = true
	npc_inst.body_scale = 1.08
	npc_inst.talk_override = func() -> bool: return _on_emperor_talk(npc_inst)
	if WorldState.chinese_village_control_granted:
		npc_inst.talk_lines.assign(EMPEROR_LINES_AFTER_DEPOSED)
	npc_inst.position = Vector3(EMPEROR_LOCAL_POS.x, 0.08, EMPEROR_LOCAL_POS.y)
	_palace.add_child(npc_inst)


func _on_emperor_talk(_emperor: Node3D) -> bool:
	if WorldState.chinese_village_chef_defeated and not WorldState.chinese_village_control_granted:
		WorldState.chinese_village_control_granted = true
		WorldState.chinese_village_emperor_deposed = true
		_emperor.talk_lines.assign(EMPEROR_LINES_AFTER_DEPOSED)
		DialogUI.show_line(EMPEROR_NAME, "原来御厨一直在蒙蔽朕。你救了朕和百姓——从今日起，这座村庄由你作主。")
		return true
	if not WorldState.chinese_village_farmer_heard or WorldState.chinese_village_control_granted:
		return false
	if WorldState.chinese_village_blorbs_taken:
		DialogUI.show_line(EMPEROR_NAME, "农人的小事不值得朕费心。朕只等御厨献上最完美的肉包。")
		return true
	WorldState.chinese_village_blorbs_taken = true
	_apply_blorb_captivity()
	DialogUI.show_line(EMPEROR_NAME, "你说什么农田？朕正在寻找天下最完美的肉包……等等，这些圆滚滚的正是！送去御膳房！")
	return true


func _apply_blorb_captivity() -> void:
	if not WorldState.chinese_village_blorbs_taken or WorldState.chinese_village_blorbs_rescued:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.get_blorb_suit().suspend_for_story()
	for node in get_tree().get_nodes_in_group("blorbs"):
		var blorb := node as Blorb
		if blorb == null or not blorb.in_party:
			continue
		blorb.visible = false
		blorb.process_mode = Node.PROCESS_MODE_DISABLED
	_build_captive_blorb_displays()


func _build_captive_blorb_displays() -> void:
	if _royal_kitchen == null or not _captive_blorb_displays.is_empty():
		return
	var party_blorbs: Array[Blorb] = []
	for node in get_tree().get_nodes_in_group("blorbs"):
		var blorb := node as Blorb
		if blorb != null and blorb.in_party:
			party_blorbs.append(blorb)
	for index in party_blorbs.size():
		var source := party_blorbs[index]
		var display := preload("res://scenes/blorb.tscn").instantiate() as Blorb
		display.portrait_mode = true
		display.portrait_blorbus = source.is_blorbus
		display.body_color = source.body_color
		display.initial_element = source.element_state
		display.size_multiplier = 0.24
		display.vertical_scale = source.vertical_scale
		display.blorb_name = source.blorb_name
		_royal_kitchen.add_child(display)
		var spread: float = (float(index) - float(party_blorbs.size() - 1) * 0.5) * 0.38
		display.position = Vector3(spread, 1.08, -1.4)
		_captive_blorb_displays.append(display)


func _clear_captive_blorb_displays() -> void:
	for display in _captive_blorb_displays:
		if is_instance_valid(display):
			display.queue_free()
	_captive_blorb_displays.clear()


func _build_royal_kitchen() -> void:
	_royal_kitchen = StaticBody3D.new()
	_royal_kitchen.name = "RoyalKitchen"
	var ground_width: float = float(PALACE_CELLS) * TownProps.CELL_SIZE
	var palace_back_z: float = PALACE_LOCAL_POS.y - ground_width * 0.5
	var kitchen_center_z: float = palace_back_z - 4.0
	_royal_kitchen.position = Vector3(0.0, 0.0, kitchen_center_z)
	_royal_kitchen.collision_layer = 1
	_royal_kitchen.collision_mask = 0
	_palace.add_child(_royal_kitchen)
	# Original adjoining annex circulation: its front doorway aligns with the
	# throne room's split rear wall, making the kitchen directly accessible.
	var kitchen_width := 10.0
	var kitchen_depth := 8.0
	var kitchen_height := PALACE_STOREY_HEIGHT
	_add_palace_block(Vector3(0.0, 0.09, kitchen_center_z), Vector3(kitchen_width, 0.18, kitchen_depth), Color(0.64, 0.36, 0.09))
	_add_palace_block(Vector3(0.0, kitchen_height, kitchen_center_z), Vector3(kitchen_width + 1.2, 0.24, kitchen_depth + 1.2), TRIM_COLOR)
	_add_palace_block(Vector3(-kitchen_width * 0.5, kitchen_height * 0.5, kitchen_center_z), Vector3(PALACE_WALL_THICKNESS, kitchen_height, kitchen_depth), Color(0.88, 0.62, 0.12))
	_add_palace_block(Vector3(kitchen_width * 0.5, kitchen_height * 0.5, kitchen_center_z), Vector3(PALACE_WALL_THICKNESS, kitchen_height, kitchen_depth), Color(0.88, 0.62, 0.12))
	_add_palace_block(Vector3(0.0, kitchen_height * 0.5, kitchen_center_z - kitchen_depth * 0.5), Vector3(kitchen_width, kitchen_height, PALACE_WALL_THICKNESS), Color(0.88, 0.62, 0.12))
	var front_piece_width := (kitchen_width - PALACE_DOOR_WIDTH) * 0.5
	var front_z := kitchen_center_z + kitchen_depth * 0.5
	for side in [-1.0, 1.0]:
		_add_palace_block(Vector3(side * (PALACE_DOOR_WIDTH + front_piece_width) * 0.5, kitchen_height * 0.5, front_z), Vector3(front_piece_width, kitchen_height, PALACE_WALL_THICKNESS), Color(0.66, 0.055, 0.045))
	_add_palace_block(Vector3(0.0, kitchen_height - 0.35, front_z), Vector3(PALACE_DOOR_WIDTH, 0.7, PALACE_WALL_THICKNESS), TRIM_COLOR)
	var counter := SuperEgg.build_part(Vector3(1.15, 0.48, 0.48), Color(0.48, 0.25, 0.1), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	counter.position = Vector3(0.0, 0.48, -1.4)
	_royal_kitchen.add_child(counter)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.3, 0.96, 0.96)
	collision.shape = shape
	collision.position = counter.position
	_royal_kitchen.add_child(collision)
	for side in [-1.0, 1.0]:
		var lantern := _build_deng_long()
		lantern.position = Vector3(side * 2.8, kitchen_height - 0.75, kitchen_center_z)
		_palace.add_child(lantern)
		_track_proximity_lantern(lantern)
	if WorldState.chinese_village_chef_defeated:
		return
	var chef: Node3D = NPC_SCENE.instantiate()
	chef.set_terrain_reference(terrain)
	chef.fixed_ground_y = ISLAND_SURFACE_Y + 0.08
	chef.display_name = "御厨"
	chef.stationary = true
	chef.is_female = false
	# His demonic identity is a disguise reveal, not his ambient appearance:
	# he begins as a plausible royal cook in clean kitchen whites.
	chef.skin_color = SKIN_COLORS[1]
	chef.hair_color = Color(0.025, 0.018, 0.022)
	chef.hair_style = FigureHair.STYLE_FLAT_TOP
	chef.shirt_color = Color(0.88, 0.85, 0.76)
	chef.pants_color = Color(0.19, 0.17, 0.16)
	chef.shoe_color = Color(0.09, 0.07, 0.065)
	chef.glove_color = Color(0.0, 0.0, 0.0, 0.0)
	chef.wears_chef_hat = true
	chef.chef_hat_color = Color(0.92, 0.89, 0.8)
	chef.chef_hat_band_color = Color(0.62, 0.08, 0.055)
	chef.beard_style = "full"
	chef.beard_color = Color(0.025, 0.018, 0.022)
	chef.beard_scale = 1.18
	chef.body_scale = 1.08
	chef.chest_build_scale = 1.12
	chef.abdomen_width_scale = 1.18
	var chef_lines: Array[String] = [
		"陛下说这些是肉包。等火再旺一些，它们就不会跳了。",
		"御膳房的门一关，外面的人就听不见里面发生什么。",
	]
	chef.talk_lines = chef_lines
	chef.talk_override = func() -> bool: return _on_royal_chef_talk(chef)
	chef.position = Vector3(2.4, 0.08, kitchen_center_z - 0.8)
	_palace.add_child(chef)
	_royal_chef = chef


func _on_royal_chef_talk(chef: Node3D) -> bool:
	if not WorldState.chinese_village_blorbs_taken or WorldState.chinese_village_chef_defeated:
		return false
	var actions: Array[Dictionary] = [{
		"label": "揭穿他。",
		"callback": func() -> void:
			DialogUI.hide_dialog()
			chef.begin_demon_agent_battle(_on_royal_chef_defeated),
	}]
	DialogUI.show_line("御厨", "这些不是肉包。它们是献给魔王的力量——而你来得正好。", actions)
	return true


func _on_royal_chef_defeated() -> void:
	WorldState.chinese_village_chef_defeated = true
	_rescue_kitchen_blorbs()
	Hud.show_message("御厨化作一团黑烟，逃回了魔界。皇宫里的阴影也随之散去。")


func _rescue_kitchen_blorbs() -> void:
	if WorldState.chinese_village_blorbs_rescued:
		return
	WorldState.chinese_village_blorbs_rescued = true
	_clear_captive_blorb_displays()
	for node in get_tree().get_nodes_in_group("blorbs"):
		var blorb := node as Blorb
		if blorb == null or not blorb.in_party:
			continue
		blorb.visible = true
		blorb.process_mode = Node.PROCESS_MODE_INHERIT
		blorb.global_position = _royal_kitchen.global_position + Vector3(_rng.randf_range(-1.5, 1.5), 0.0, 2.0 + _rng.randf_range(0.0, 1.5))
	Hud.show_message("布洛布们恢复了原来的大小，从御膳房的案台上跳了下来。")


## The farmer begins the village storyline by explaining the Emperor's
## injustice. Once the freed Emperor gives the hero control, returning here
## lets the hero appoint the farmer as steward and receive Pandy.
func _build_farmer_and_pandy_quest() -> void:
	var panda: Pandy = null
	if not WorldState.pandy_joined:
		panda = PANDY_SCENE.instantiate()
		var panda_world := VILLAGE_CENTER + BAMBOO_ISLAND_LOCAL + FARMER_LOCAL_POS + Vector2(2.5, 0.0)
		get_parent().add_child(panda)
		panda.global_position = Vector3(panda_world.x, ISLAND_SURFACE_Y, panda_world.y)

	var farmer: Node3D = NPC_SCENE.instantiate()
	farmer.set_terrain_reference(terrain)
	farmer.fixed_ground_y = ISLAND_SURFACE_Y
	farmer.display_name = FARMER_NAME
	farmer.stationary = true
	farmer.is_female = false
	farmer.skin_color = SKIN_COLORS[2]
	farmer.hair_color = HAIR_COLORS[1]
	farmer.hair_style = FigureHair.STYLE_BALD
	farmer.shirt_color = Color(0.35, 0.42, 0.28)
	farmer.pants_color = PANTS_COLORS[1]
	farmer.body_scale = 1.0
	var lines: Array[String] = []
	lines.assign(FARMER_LINES)
	farmer.talk_lines = lines
	farmer.talk_override = func() -> bool: return _on_farmer_talk(farmer, panda)
	farmer.position = Vector3(FARMER_LOCAL_POS.x, 0, FARMER_LOCAL_POS.y)
	_bamboo_island.add_child(farmer)


func _on_farmer_talk(_farmer: Node3D, panda: Pandy) -> bool:
	if not WorldState.chinese_village_farmer_heard:
		WorldState.chinese_village_farmer_heard = true
		DialogUI.show_line(FARMER_NAME, "皇帝听信御厨的话，年年加重征收。再这样下去，我连一小块种豆子的地也保不住。")
		return true
	if WorldState.chinese_village_control_granted and not WorldState.chinese_village_rule_delegated:
		var actions: Array[Dictionary] = [{
			"label": "请田伯代为治理村庄。",
			"callback": func() -> void:
				DialogUI.hide_dialog()
				WorldState.chinese_village_rule_delegated = true
				WorldState.pandy_joined = true
				if is_instance_valid(panda):
					panda.in_party = true
				Hud.show_message("你把村庄托付给了田伯。潘迪走到你身边，决定与你同行。"),
		}]
		DialogUI.show_line(FARMER_NAME, "陛下终于清醒了。你若信得过我，我会替你照看村庄和这里的田地。", actions)
		return true
	if WorldState.chinese_village_rule_delegated:
		_farmer.talk_lines.assign(FARMER_LINES_AFTER_DEPOSED)
		return false
	DialogUI.show_line(FARMER_NAME, "御厨近来寸步不离陛下。皇帝从前并不是这个样子。")
	return true
