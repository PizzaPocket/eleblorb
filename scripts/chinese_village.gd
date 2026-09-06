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
# Island layout: one large hub (the Palace) + three smaller spokes.
# ---------------------------------------------------------------------------
const PALACE_LOCAL := Vector2.ZERO
const PALACE_RADIUS := 62.0
const VILLAGE_A_LOCAL := Vector2(-95.0, -50.0)
const VILLAGE_A_RADIUS := 42.0
const VILLAGE_B_LOCAL := Vector2(95.0, -45.0)
const VILLAGE_B_RADIUS := 40.0
const BAMBOO_ISLAND_LOCAL := Vector2(10.0, 105.0)
const BAMBOO_ISLAND_RADIUS := 44.0

const ISLAND_GRASS_COLOR := Color(0.07451, 0.63922, 0.40392)  # same grass hex the main/jungle plateaus use, per direct instruction
const ISLAND_ROCK_COLOR := Color(0.34, 0.3, 0.26)
const ISLAND_GRASS_THICKNESS := 1.6

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
const VILLAGE_A_BUILDING_COUNT := 7
const VILLAGE_B_BUILDING_COUNT := 7

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
const PALACE_LOCAL_POS := Vector2(0.0, -15.0)
const PALACE_CELLS := 6
const PALACE_TIER_COUNT := 4

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
const PLAY_HUT_LOCAL_POS := Vector2(18.0, 15.0)
const PLAY_HUT_POLE_COUNT := 7
const PLAY_HUT_POLE_HEIGHT := 1.3
const PLAY_HUT_POLE_RADIUS := 0.03
const PLAY_HUT_BASE_RADIUS := 0.55
const PLAY_HUT_STICK_COLOR := Color(0.42, 0.3, 0.18)
const LOOSE_STICK_COUNT := 9
const KID_ROAM_JITTER := 6.0

## Sun Wu Kong, sealed under a rock in a quiet corner of Village A -- see
## sun_wu_kong.gd's own class doc comment for the "trapped under a
## mountain" myth this nods to.
const SUN_WU_KONG_LOCAL_POS := Vector2(-25.0, -20.0)

## The outdoor merchant's stall (Village B).
const VENDOR_LOCAL_POS := Vector2(-15.0, 10.0)
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
const EMPEROR_LOCAL_POS := Vector2(0.0, 5.0)
const EMPEROR_NAME := "皇帝"
const EMPEROR_LINES := [
	"整个山谷,连脚下的浮岛,都是朕的疆土。",
	"通宝说话比奏折响亮。朕只听得懂这个。",
]
const EMPEROR_LINES_AFTER_DEPOSED := [
	"浮岛还是浮岛,只是如今听你的了。",
]
const EMPEROR_BRIBE_AMOUNT := 150

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
var _village_a_positions: Array[Vector2] = []
var _village_b_positions: Array[Vector2] = []


func _ready() -> void:
	terrain = get_node("../Terrain")
	_rng.seed = 20260906

	_palace = _build_island(PALACE_LOCAL, PALACE_RADIUS)
	_village_a = _build_island(VILLAGE_A_LOCAL, VILLAGE_A_RADIUS)
	_village_b = _build_island(VILLAGE_B_LOCAL, VILLAGE_B_RADIUS)
	_bamboo_island = _build_island(BAMBOO_ISLAND_LOCAL, BAMBOO_ISLAND_RADIUS)

	_build_bridge(PALACE_LOCAL, PALACE_RADIUS, VILLAGE_A_LOCAL, VILLAGE_A_RADIUS)
	_build_bridge(PALACE_LOCAL, PALACE_RADIUS, VILLAGE_B_LOCAL, VILLAGE_B_RADIUS)
	_build_bridge(PALACE_LOCAL, PALACE_RADIUS, BAMBOO_ISLAND_LOCAL, BAMBOO_ISLAND_RADIUS)
	_build_entry_bridge()

	_build_palace()
	_build_emperor()

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
	_spawn_villagers(_village_b, _village_b_positions, VILLAGER_IDENTITIES.size() / 2, VILLAGER_IDENTITIES.size() - VILLAGER_IDENTITIES.size() / 2)

	_build_bamboo_forest()
	_build_farmer_and_pandy_quest.call_deferred()

	_scatter_lanterns(_palace, PALACE_RADIUS)
	_scatter_lanterns(_village_a, VILLAGE_A_RADIUS)
	_scatter_lanterns(_village_b, VILLAGE_B_RADIUS)


## One floating island -- a thin grass-topped disc over a tapering rocky
## underside, like a chunk of earth broken clean off. Everything placed on
## it afterward uses LOCAL coordinates relative to this node (whose own
## position already carries the world offset + ISLAND_SURFACE_Y), at
## local y=0 for the top surface -- no terrain sampling involved anywhere.
func _build_island(local_pos: Vector2, radius: float) -> Node3D:
	var world := VILLAGE_CENTER + local_pos
	var island := StaticBody3D.new()
	island.collision_layer = 1
	island.collision_mask = 0
	island.position = Vector3(world.x, ISLAND_SURFACE_Y, world.y)
	add_child(island)

	var grass := SuperEgg.build_part(
		Vector3(radius, ISLAND_GRASS_THICKNESS * 0.5, radius), ISLAND_GRASS_COLOR,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	grass.position = Vector3(0, -ISLAND_GRASS_THICKNESS * 0.5, 0)
	island.add_child(grass)

	var underside_height := radius * 1.6
	var underside := SuperEgg.build_part(
		Vector3(radius * 0.92, underside_height * 0.5, radius * 0.92), ISLAND_ROCK_COLOR,
		SuperEgg.EPSILON_FLAT, 2.2
	)
	underside.position = Vector3(0, -ISLAND_GRASS_THICKNESS - underside_height * 0.5, 0)
	island.add_child(underside)

	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = ISLAND_GRASS_THICKNESS
	collision.shape = shape
	collision.position = Vector3(0, -ISLAND_GRASS_THICKNESS * 0.5, 0)
	island.add_child(collision)

	return island


## A flat plank walkway with simple post-and-rail sides, connecting two
## islands edge-to-edge along the straight line between their centers.
func _build_bridge(from_local: Vector2, from_radius: float, to_local: Vector2, to_radius: float) -> void:
	var direction := (to_local - from_local).normalized()
	var start_local := from_local + direction * from_radius
	var end_local := to_local - direction * to_radius
	var span := start_local.distance_to(end_local)
	if span <= 0.5:
		return
	_build_bridge_segment((start_local + end_local) * 0.5, span, direction)


func _build_entry_bridge() -> void:
	var rim_local := ENTRY_BRIDGE_DIRECTION * ENTRY_BRIDGE_RIM_DISTANCE
	_build_bridge(PALACE_LOCAL, PALACE_RADIUS, rim_local, 0.0)


func _build_bridge_segment(mid_local: Vector2, span: float, direction: Vector2) -> void:
	var world := VILLAGE_CENTER + mid_local
	var bridge := StaticBody3D.new()
	bridge.collision_layer = 1
	bridge.collision_mask = 0
	bridge.position = Vector3(world.x, ISLAND_SURFACE_Y, world.y)
	bridge.rotation.y = atan2(direction.x, direction.y)
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


func _build_pagoda(island: Node3D, local_pos: Vector2, w: int, d: int, tier_count: int = EAVE_TIER_COUNT) -> Node3D:
	var roof_color: Color = ROOF_COLORS[_rng.randi() % ROOF_COLORS.size()]
	var body := TownProps.build_building(w, d, 1, roof_color)
	body.position = Vector3(local_pos.x, 0, local_pos.y)
	body.rotation.y = _rng.randf_range(0.0, TAU)
	island.add_child(body)

	# Stack tapering ornamental eave tiers above the building's own roof
	# peak -- same rise math _build_roof() itself uses (see town_props.gd's
	# own comment on that function), reproduced here rather than exposed as
	# a public helper since only this one caller needs it.
	var half_depth := d * TownProps.CELL_SIZE * 0.5 + TownProps.ROOF_OVERHANG
	var slope_len := half_depth / cos(TownProps.ROOF_PITCH)
	var y := TownProps.FLOOR_HEIGHT + slope_len * sin(TownProps.ROOF_PITCH)
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


## The Emperor's own palace -- the same pagoda shape as an ordinary house,
## just bigger and more tiered, per direct instruction.
func _build_palace() -> void:
	_build_pagoda(_palace, PALACE_LOCAL_POS, PALACE_CELLS, PALACE_CELLS, PALACE_TIER_COUNT)


## Loose rejection sampling, not a rigid grid -- per direct confirmation
## this is meant to feel like a "sprawling" organic settlement.
func _pick_building_position(radius: float, existing: Array[Vector2]) -> Vector2:
	var clear_center := radius * 0.25
	for attempt in 20:
		var angle := _rng.randf_range(0.0, TAU)
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * radius
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
	var local_pos := _pick_building_position(radius, positions)
	if local_pos == Vector2.INF:
		return
	positions.append(local_pos)
	var w := _rng.randi_range(BUILDING_CELL_MIN, BUILDING_CELL_MAX)
	var d := _rng.randi_range(BUILDING_CELL_MIN, BUILDING_CELL_MAX)
	_build_pagoda(island, local_pos, w, d)


func _scatter_lanterns(island: Node3D, radius: float) -> void:
	for i in LANTERN_COUNT_PER_ISLAND:
		var angle := _rng.randf_range(0.0, TAU)
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * radius
		var lantern := TownProps.build_lantern()
		lantern.position = Vector3(cos(angle) * r, 0, sin(angle) * r)
		island.add_child(lantern)


func _spawn_villagers(island: Node3D, positions: Array[Vector2], identity_offset: int, count: int) -> void:
	for i in count:
		var identity_index := identity_offset + i
		var local_pos: Vector2 = positions[i % positions.size()] if not positions.is_empty() else Vector2.ZERO
		var jitter := Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-4.0, 4.0))
		var local := local_pos + jitter
		var npc_inst: Node3D = NPC_SCENE.instantiate()
		npc_inst.set_terrain_reference(terrain)
		npc_inst.fixed_ground_y = ISLAND_SURFACE_Y
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


## Sun Wu Kong, sealed under a rock in a quiet corner of Village A --
## added via get_parent().add_child() (Main's own root, a direct sibling of
## Player/Terrain), NOT island.add_child() -- sun_wu_kong.gd resolves
## "../Player"/"../Terrain" via that exact fixed-sibling lookup (see its
## own class doc comment), and its own _ground_y() helper is already
## abyss-aware, so no fixed_ground_y-style override is needed here the way
## ordinary npc.gd instances need one.
func _build_sun_wu_kong() -> void:
	var sage: SunWuKong = SUN_WU_KONG_SCENE.instantiate()
	var world := VILLAGE_CENTER + VILLAGE_A_LOCAL + SUN_WU_KONG_LOCAL_POS
	get_parent().add_child(sage)
	sage.global_position = Vector3(world.x, ISLAND_SURFACE_Y, world.y)


## A little bamboo forest, scattered sparsely across its own island rather
## than in one dense grove -- per direct instruction ("bamboo populating
## the islands sporadically"). Each stalk is a stack of near-uniform-radius
## SuperEgg segments separated by thin "node" rings, with a handful of
## thin blade-like leaves fanned out near the top.
func _build_bamboo_forest() -> void:
	for i in BAMBOO_STALK_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := BAMBOO_CLEAR_CENTER + sqrt(_rng.randf_range(0.0, 1.0)) * (BAMBOO_ISLAND_RADIUS - BAMBOO_CLEAR_CENTER)
		_build_bamboo_stalk(Vector2(cos(angle) * r, sin(angle) * r))


func _build_bamboo_stalk(local_pos: Vector2) -> void:
	var stalk := Node3D.new()
	stalk.position = Vector3(local_pos.x, 0, local_pos.y)
	stalk.rotation.y = _rng.randf_range(0.0, TAU)
	_bamboo_island.add_child(stalk)

	var radius := _rng.randf_range(BAMBOO_RADIUS_MIN, BAMBOO_RADIUS_MAX)
	var lean := _rng.randf_range(-0.05, 0.05)
	var y := 0.0
	for i in BAMBOO_SEGMENT_COUNT:
		var segment := SuperEgg.build_part(
			Vector3(radius, BAMBOO_SEGMENT_HEIGHT * 0.5, radius), BAMBOO_COLOR,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		segment.position = Vector3(sin(lean) * y, y + BAMBOO_SEGMENT_HEIGHT * 0.5, 0)
		stalk.add_child(segment)
		y += BAMBOO_SEGMENT_HEIGHT
		var node_ring := SuperEgg.build_part(
			Vector3(radius * BAMBOO_NODE_RADIUS_BOOST, 0.03, radius * BAMBOO_NODE_RADIUS_BOOST), BAMBOO_NODE_COLOR,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		node_ring.position = Vector3(sin(lean) * y, y, 0)
		stalk.add_child(node_ring)

	for i in BAMBOO_LEAF_COUNT:
		var leaf := SuperEgg.build_part(
			Vector3(0.02, 0.18, 0.05), BAMBOO_LEAF_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		var leaf_angle := _rng.randf_range(0.0, TAU)
		var leaf_y := y - _rng.randf_range(0.0, BAMBOO_SEGMENT_HEIGHT * 1.5)
		leaf.position = Vector3(cos(leaf_angle) * radius * 1.5, leaf_y, sin(leaf_angle) * radius * 1.5)
		leaf.rotation.y = leaf_angle
		leaf.rotation.z = _rng.randf_range(-0.6, 0.6)
		stalk.add_child(leaf)


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


## The Emperor -- stands near his own palace entrance. Per direct
## instruction: pay him 150 tokoins ("because money is all he can
## understand") and he cedes the valley; see _build_farmer_and_pandy_quest()
## for the follow-up delegation that actually hands over Pandy.
func _build_emperor() -> void:
	var npc_inst: Node3D = NPC_SCENE.instantiate()
	npc_inst.set_terrain_reference(terrain)
	npc_inst.fixed_ground_y = ISLAND_SURFACE_Y
	npc_inst.display_name = EMPEROR_NAME
	npc_inst.stationary = true
	npc_inst.is_female = false
	npc_inst.skin_color = SKIN_COLORS[0]
	npc_inst.hair_color = HAIR_COLORS[0]
	npc_inst.hair_style = FigureHair.STYLE_HERO
	npc_inst.shirt_color = TRIM_COLOR
	npc_inst.pants_color = Color(0.62, 0.12, 0.1)
	npc_inst.body_scale = 1.1
	npc_inst.dialog_actions_provider = func() -> Array[Dictionary]: return _emperor_dialog_actions(npc_inst)
	npc_inst.position = Vector3(EMPEROR_LOCAL_POS.x, 0, EMPEROR_LOCAL_POS.y)
	_palace.add_child(npc_inst)


func _emperor_dialog_actions(emperor: Node3D) -> Array[Dictionary]:
	if WorldState.chinese_village_emperor_deposed:
		emperor.talk_lines.assign(EMPEROR_LINES_AFTER_DEPOSED)
		return []
	emperor.talk_lines.assign(EMPEROR_LINES)
	if TokoinWallet.value < EMPEROR_BRIBE_AMOUNT:
		return []
	var actions: Array[Dictionary] = []
	actions.append({
		"label": "Pay the Emperor %d Tokoins." % EMPEROR_BRIBE_AMOUNT,
		"callback": func() -> void:
			TokoinWallet.spend(EMPEROR_BRIBE_AMOUNT)
			WorldState.chinese_village_emperor_deposed = true
			DialogUI.hide_dialog()
			Hud.show_message("You paid the Emperor %d tokoins. Grumbling, he cedes his claim on the valley -- you're the village's new ruler." % EMPEROR_BRIBE_AMOUNT),
	})
	return actions


## The farmer, on the bamboo island, and Pandy -- ambient beside him from
## the start. Per direct instruction: once the Emperor is deposed (see
## _build_emperor() above), talking to the farmer offers to delegate rule
## of the village to him; he thanks the player by giving them Pandy.
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
	farmer.dialog_actions_provider = func() -> Array[Dictionary]: return _farmer_dialog_actions(farmer, panda)
	farmer.position = Vector3(FARMER_LOCAL_POS.x, 0, FARMER_LOCAL_POS.y)
	_bamboo_island.add_child(farmer)


func _farmer_dialog_actions(farmer: Node3D, panda: Pandy) -> Array[Dictionary]:
	if not WorldState.chinese_village_emperor_deposed or WorldState.chinese_village_rule_delegated:
		return []
	farmer.talk_lines.assign(FARMER_LINES_AFTER_DEPOSED)
	var actions: Array[Dictionary] = []
	actions.append({
		"label": "Delegate rule of the village to %s." % FARMER_NAME,
		"callback": func() -> void:
			DialogUI.hide_dialog()
			WorldState.chinese_village_rule_delegated = true
			WorldState.pandy_joined = true
			if is_instance_valid(panda):
				panda.in_party = true
			Hud.show_message("You delegate rule of the Chinese village to %s. Grateful, he gives you Pandy." % FARMER_NAME),
	})
	return actions
