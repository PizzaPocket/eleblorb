extends Node3D
class_name WildernessScatter

## Scatters procedural wilderness props (see nature_props.gd's NatureProps
## -- SuperEgg-built trees, rocks, stumps, flowers, grass, mushrooms,
## bushes) across the field in natural clusters (forest patches, meadow
## patches, rocky outcrops) plus a sparse background layer and a few
## solitary wanderers, rather than uniform random spacing. Replaces the
## borrowed Kenney Nature Kit GLB assets this used to prototype with, per
## direct instruction (same process town_generator.gd's own rebuild used).
## Placement follows the terrain surface via Terrain.get_mesh_height().
## Nothing here is saved into the scene; it regenerates fresh
## (deterministically, via rng_seed) every time the game runs.

@export var field_half_size: float = 190.0
## The origin is the player's singular arrival clearing, not ordinary
## wilderness. Keep the same broad, uncluttered buffer settlements receive
## so the first moments are calm and readable before exploration begins.
@export var spawn_exclusion_radius: float = 55.0
@export var town_exclusion_radius: float = 85.0
@export var rng_seed: int = 20260815

@onready var terrain: Node = get_node("../Terrain")
@onready var town_center: Vector2 = terrain.town_center

const NPC_SCENE := "res://scenes/npc.tscn"
const BLORB_SCENE := "res://scenes/blorb.tscn"
const XIAO_HOU_ZI_SCENE := "res://scenes/xiao_hou_zi.tscn"
## Plain (unmerged) wild blorbs scattered across the field at startup --
## "lots," per direct instruction, so the compass hunt has real breadth to
## it rather than a handful of fixed encounters.
const WILD_BLORB_NORMAL_COUNT := 16
## The rare "shiny blorb" wild variant (see blorb.gd's is_shiny) -- "only a
## few," per direct instruction, deliberately much rarer than the plain
## wild population above.
const WILD_BLORB_SHINY_COUNT := 3
## Already-elemental wild finds beyond water, same flavor the old hand-
## placed WildBlorb3/WildBlorb4 nodes used to provide (see docs/world_bible.
## md's "naturally elemental" wild-blorb mention) -- folded into this
## procedural spawn instead of living as fixed scene nodes, so it scatters
## to a fresh spot each run like everything else here. Rock moved out to
## its own dedicated canyon-scoped spawn (_spawn_canyon_rock_blorbs(), same
## pattern as WILD_BLORB_PLANT_COUNT's own jungle-scoped one below) since a
## Rock Gem already lives there too -- only Electric stays scattered
## anywhere in the open field.
const WILD_BLORB_OTHER_ELEMENTS := ["electric"]
## A few naturally-elemental plant wild blorbs live within the jungle
## plateau itself (see docs/world_bible.md's plant-type entry) -- the
## jungle's own counterpart to WILD_BLORB_OTHER_ELEMENTS/the lake's water
## blorbs above, just scoped to the jungle plateau's own footprint (see
## _spawn_jungle_plant_blorbs()) rather than the whole field, since a plant
## blorb found out in open desert wouldn't fit the way an electric one does.
const WILD_BLORB_PLANT_COUNT := 4
## The canyon biome's own naturally-elemental find -- see WILD_BLORB_OTHER_
## ELEMENTS' own comment for why Rock moved here instead of the open field.
const WILD_BLORB_CANYON_ROCK_COUNT := 4
## The outskirts city's own naturally-elemental find -- same "own dedicated
## biome-scoped spawn" pattern as the canyon/jungle/volcano ones, just for
## City/the city itself.
const WILD_BLORB_CITY_COUNT := 4
## A few naturally hovering air blorbs make the sky platforms feel inhabited
## and provide real-world flight-suit finds beyond the temporary starter.
const WILD_BLORB_AIR_COUNT := 3
## Dedicated lake residents use the deep eastern basin rather than the
## ordinary field sampler, whose exploration bounds end before the lake.
const LAKE_WATER_BLORB_COUNT := 4
## A few naturally-elemental fire wild blorbs live on and inside the
## volcano's own crater (see docs/world_bible.md's Volcano entry), per direct
## instruction -- same "own dedicated biome-scoped spawn" pattern
## WILD_BLORB_PLANT_COUNT's own comment describes for the jungle plateau,
## just for fire/the volcano instead. Split roughly evenly between the outer
## cone ("on... the volcano") and the crater's own rocky skirt ("inside" it)
## by _spawn_volcano_fire_blorbs() itself.
const WILD_BLORB_VOLCANO_FIRE_COUNT := 4
## A handful of rock outcroppings around the crater's lava pool -- "rock
## outcropping around the skirts of the lava pool which you can walk on,"
## per direct instruction. The terrain itself already slopes down into the
## crater bowl there (see terrain_generator.gd's own _volcano_height()); these
## are freestanding NatureProps.build_rock() boulders on top of that ground,
## for visual texture the same way _scatter_wasteland_rocks() adds to the
## open desert floor.
const VOLCANO_ROCK_COUNT := 14
## How many fresh wild blorbs appear once the player's found every one
## currently out in the field -- see spawn_replenishment_wave(), called by
## hud.gd instead of just letting the compass hint vanish. Small relative
## to the initial population above; this is a top-up, not a second full wave.
const REPLENISH_COUNT := 3
## The giant rests out in the northern wasteland with a visible buffer
## between its enormous southern edge and the plateau cliff. It remains on
## the real terrain mesh, well before the outer boundary. Playable-world
## verification establishes north as -Z.
const WASTELAND_GIANT_POS := Vector2(0.0, -330.0)
const WASTELAND_GIANT_SIZE := 50.0
const WASTELAND_GIANT_MOVEMENT_SPEED := 0.1
## Far props remain visible to the renderer's normal frustum culling, but
## their collision and shadow work is only useful near the player.
const PROP_COLLISION_RADIUS := 105.0
const PROP_SHADOW_RADIUS := 155.0
const PROP_LOD_UPDATE_INTERVAL := 0.4
## +X is east, so this fixed negative-X coordinate establishes the canyon /
## mesa landmark in the west, opposite the town at positive X.
## Straddles the western plateau rim so the sandstone biome visibly spills
## from the green highland down onto the gorge floor.  Keep this paired with
## CANYON_ZONE_RADIUS below: the inner half remains on the plateau while the
## western half reaches comfortably beyond the noisy 225-265m cliff line.
const CANYON_BIOME_CENTER := Vector2(-215.0, 0.0)
const CANYON_ZONE_RADIUS := 72.0
## Duplicated from city_generator.gd's/terrain_generator.gd's own CITY_CENTER
## and terrain_generator.gd's own CITY_FLAT_RADIUS, matching this file's own
## established convention of keeping its biome-center consts local rather
## than reaching into those other generator scripts (see CANYON_BIOME_CENTER
## above, defined the same standalone way).
const CITY_CENTER := Vector2(-540.0, 0.0)
const CITY_ZONE_RADIUS := 78.0
## Duplicated from main.gd's own ICE_GATE_XZ, same reasoning as CITY_CENTER
## above -- the Ice Kingdom's gate needs no new sculpted landform (see that
## const's own comment), just this cosmetic frost dressing scattered around
## it so the clearing itself reads as snowy.
const ICE_GATE_XZ := Vector2(-450.0, -480.0)
const ICE_GATE_DRESSING_RADIUS := 55.0
## Duplicated from terrain_generator.gd's/chinese_village.gd's own
## CHINESE_VILLAGE_CENTER, same reasoning as CITY_CENTER above -- keeps
## _scatter_wasteland_rocks() (the only scatter pass whose range reaches this
## far out) from dropping loose rocks into the Abyss of Impending Doom
## (harmless, but pointless -- they'd land far below anything visible) or
## through the village's own floating islands.
const CHINESE_VILLAGE_CENTER := Vector2(250.0, -650.0)
## Matches terrain_generator.gd's own CHINESE_VILLAGE_ABYSS_RADIUS +
## CHINESE_VILLAGE_ABYSS_TRANSITION (170 + 50) with a little margin.
const CHINESE_VILLAGE_EXCLUSION_RADIUS := 230.0
## Two wandering NPCs out in the wilderness, per direct instruction --
## "no backstory yet, just make it up for now as placeholder." Hand-set
## appearance (not drawn from town_generator.gd's shuffled pools, which
## are sized/seeded for that file's own 9 named villagers + vendor) since
## there are only two of these and they don't need that guaranteed-
## uniqueness machinery -- just two colors distinct enough from each other.
const WILDERNESS_WANDERER_IDENTITIES := [
	{
		"name": "Fenn Aldric",
		"female": false,
		"skin_color": Color(0.62, 0.45, 0.32),
		"shirt_color": Color(0.32, 0.24, 0.16),
		"hair_color": Color(0.32, 0.18, 0.08),
		"hair_style": FigureHair.STYLE_BUZZCUT,
		"lines": [
			"Lost my way out here years ago. Never really found a reason to go looking for the way back.",
			"You get used to the quiet out here. Mostly.",
		],
	},
	{
		"name": "Bryn Ostler",
		"female": true,
		"skin_color": Color(0.87, 0.68, 0.52),
		"shirt_color": Color(0.4, 0.24, 0.78),
		"hair_color": Color(0.55, 0.32, 0.12),
		"hair_style": FigureHair.STYLE_LONG,
		"lines": [
			"I keep to the open fields these days. Fewer questions out here than in town.",
			"If you're headed toward the village, you can tell them Bryn's still out here. Not that they'll ask.",
		],
	},
]

## Each entry is a zero-argument Callable returning a ready-to-place
## Node3D (a StaticBody3D with its own collision baked in, for the solid
## ones) -- NatureProps owns each species' actual proportions/collision,
## this file only picks which one and where.
var _tree_builders := [
	func(): return NatureProps.build_round_tree(6.5, NatureProps.TREE_LEAF_COLORS[0]),
	func(): return NatureProps.build_round_tree(7.2, NatureProps.TREE_LEAF_COLORS[1]),
	func(): return NatureProps.build_round_tree(5.6, NatureProps.TREE_LEAF_COLORS[2]),
	func(): return NatureProps.build_round_tree(6.9, NatureProps.TREE_LEAF_COLORS[3]),
	func(): return NatureProps.build_pine_tree(7.6, NatureProps.TREE_LEAF_COLORS[1]),
	func(): return NatureProps.build_pine_tree(6.8, NatureProps.TREE_LEAF_COLORS[3]),
]
var _rock_builders := [
	func(): return NatureProps.build_rock(1.3),
	func(): return NatureProps.build_rock(1.05),
	func(): return NatureProps.build_rock(0.85),
	func(): return NatureProps.build_rock(0.7),
	func(): return NatureProps.build_stump(0.42, 0.7),
]
## Tall, genuinely climbable rock formations (see build_rock_spire()'s own
## doc comment) -- a plain build_rock() tops out barely above knee height,
## nowhere near enough for real platforming. Passes this file's own shared
## _rng straight in for the per-tier taper/jitter rather than a separate
## generator -- order doesn't matter here the way it does for
## town_generator.gd's fixed-order NPC variant shuffles, so there's no
## reason not to just reuse the one stream.
var _rock_spire_builders := [
	func(): return NatureProps.build_rock_spire(1.2, 3, _rng),
	func(): return NatureProps.build_rock_spire(1.45, 4, _rng),
	func(): return NatureProps.build_rock_spire(1.0, 3, _rng),
]
## Bigger, taller spires just for _build_canyon_biome() -- 5-6
## tiers instead of 3-4, reaching roughly 5.5-6.5m instead of ~3.7-5m, so
## the dedicated zone's centerpieces read as genuinely more dramatic than
## the ones scattered through ordinary _rocky_cluster()s elsewhere.
var _zone_spire_builders := [
	func(): return NatureProps.build_rock_spire(1.5, 5, _rng),
	func(): return NatureProps.build_rock_spire(1.8, 6, _rng),
	func(): return NatureProps.build_rock_spire(1.3, 5, _rng),
]
var _undergrowth_builders := [
	func(): return _make_mushroom_pickup("Red Mushroom"),
	func(): return _make_mushroom_pickup("Tan Mushroom"),
	func(): return NatureProps.build_bush(),
	func(): return NatureProps.build_grass_tuft(),
]
var _meadow_builders := [
	func(): return _make_flower_pickup("Red Flower"),
	func(): return _make_flower_pickup("Yellow Flower"),
	func(): return _make_flower_pickup("Purple Flower"),
	func(): return NatureProps.build_grass_tuft(),
	func(): return NatureProps.build_grass_tuft(Color(0.1, 0.65, 0.55)),
	func(): return NatureProps.build_bush(),
]
var _rocky_decor_builders := [
	func(): return NatureProps.build_rock(0.3, false),
	func(): return NatureProps.build_rock(0.22, false),
]
var _background_decor_builders := [
	func(): return _make_flower_pickup("Red Flower"),
	func(): return _make_flower_pickup("Yellow Flower"),
	func(): return NatureProps.build_grass_tuft(),
	func(): return NatureProps.build_bush(),
	func(): return _make_mushroom_pickup("Tan Mushroom"),
]
## Jungle-only vegetation -- taller/denser trees plus the jungle's own
## Orchid/Jungle Mushroom pickup variants, scattered only within
## terrain.get_jungle_plateau_center()/_radius()'s own footprint by
## _build_jungle_biome() below, never mixed into the ordinary field arrays
## above.
## Palm trees grow tallest of all -- much taller than every other jungle
## species below, per direct instruction -- and every other jungle species
## here runs much taller/bigger than its own previous size too (banana stays
## at its existing size on purpose -- a banana plant is genuinely short next
## to real jungle canopy trees). Per direct instruction, every species other
## than palm/banana now has an extended cap reaching up to double its
## previous fixed height -- randf_range per instance (rather than just
## doubling the constant outright) so the canopy still has real size
## variety instead of every banyan/baobab/flowering tree being identically
## huge.
var _jungle_tree_builders := [
	func(): return NatureProps.build_palm_tree(15.0, _rng.randf_range(0.12, 0.28), _rng),
	func(): return NatureProps.build_palm_tree(13.0, _rng.randf_range(0.15, 0.32), _rng),
	func(): return NatureProps.build_banyan_tree(_rng.randf_range(15.0, 30.0), _rng),
	func(): return NatureProps.build_baobab_tree(_rng.randf_range(13.5, 27.0), _rng),
	func(): return NatureProps.build_flowering_tree(_rng.randf_range(12.0, 24.0), NatureProps.JUNGLE_LEAF_COLORS[0], Color(0.95, 0.6, 0.8), _rng),
]
var _jungle_undergrowth_builders := [
	func(): return _make_mushroom_pickup("Jungle Mushroom"),
	func(): return _make_flower_pickup("Orchid"),
	func(): return NatureProps.build_bush(NatureProps.JUNGLE_LEAF_COLORS[1]),
	func(): return NatureProps.build_grass_tuft(NatureProps.JUNGLE_LEAF_COLORS[2]),
]
## Jungle fruit tree species, same dict shape _fruit_tree_species above uses
## plus a "tree_builder"/"visual_builder" pair (see _place_fruit_tree()'s own
## species.get() fallback) since Banana/Durian trees and fruit aren't built
## by the plain build_fruit_tree()/build_fruit_visual() every other species
## shares.
var _jungle_fruit_tree_species := [
	{
		"height": 7.0, "leaf": Color(), "fruit_name": "Banana", "fruit_color": NatureProps.FRUIT_COLORS["Banana"],
		"tree_builder": func(height: float, _leaf: Color): return NatureProps.build_banana_tree(height, _rng),
		"visual_builder": func(): return NatureProps.build_banana_fruit(NatureProps.FRUIT_COLORS["Banana"], 0.09),
	},
	{
		# Durian is neither the banana nor the palm exception above, so it
		# gets the same up-to-double height cap -- tree_builder ignores the
		# fixed "height" field below except as the range's own floor.
		"height": 13.0, "leaf": Color(), "fruit_name": "Durian", "fruit_color": NatureProps.FRUIT_COLORS["Durian"],
		"tree_builder": func(height: float, _leaf: Color): return NatureProps.build_durian_tree(_rng.randf_range(height, height * 2.0), _rng),
		"visual_builder": func(): return NatureProps.build_durian_fruit(NatureProps.FRUIT_COLORS["Durian"], 0.16),
	},
]
## Fruit tree species -- dictionaries rather than bare Callables (unlike
## _tree_builders above) since _place_fruit_tree() needs the fruit's own
## name/color too, to spawn matching fallen-fruit pickups (see fruit.gd)
## beneath the tree it builds, not just the tree itself.
var _fruit_tree_species := [
	{"height": 6.0, "leaf": NatureProps.TREE_LEAF_COLORS[0], "fruit_name": "Apple", "fruit_color": NatureProps.FRUIT_COLORS["Apple"]},
	{"height": 6.4, "leaf": NatureProps.TREE_LEAF_COLORS[2], "fruit_name": "Orange", "fruit_color": NatureProps.FRUIT_COLORS["Orange"]},
	{"height": 5.8, "leaf": NatureProps.TREE_LEAF_COLORS[1], "fruit_name": "Lemon", "fruit_color": NatureProps.FRUIT_COLORS["Lemon"]},
	{"height": 6.2, "leaf": NatureProps.TREE_LEAF_COLORS[3], "fruit_name": "Plum", "fruit_color": NatureProps.FRUIT_COLORS["Plum"]},
]

var _rng := RandomNumberGenerator.new()
var _giant_presence_checked: bool = false
var _prop_lod_timer := 0.0
var _wilderness_colliders: Array[CollisionObject3D] = []
var _wilderness_geometry: Array[GeometryInstance3D] = []
var _wilderness_simulations: Array[Node] = []
## World-space tree canopy "blobs" (see NatureProps._add_canopy_blob()) --
## one-way walkable support, same technique CloudScatter.get_support_height_at()
## uses for its own cloud puffs (walkable underneath/through the sides,
## landable only when a falling body settles onto the top from above), just
## fed by tree foliage instead of clouds. Populated once per canopy piece,
## right after each tree is placed (see _register_canopy_blobs()) -- trees
## never move afterward, so there's no need to recompute this per frame.
var _canopy_blobs: Array[Dictionary] = []


func _ready() -> void:
	# Lets hud.gd find this node to trigger spawn_replenishment_wave() once
	# every wild blorb currently out in the field has been found -- see
	# that function's own doc comment.
	add_to_group("wilderness_scatter")
	_rng.seed = rng_seed
	_scatter_clusters()
	_scatter_background(140)
	_scatter_wanderers(24, _tree_builders)
	_scatter_wanderers(16, _rock_builders)
	# A handful of standalone spires out in the open field too, not just
	# inside rocky clusters -- landmarks you can spot from a distance and
	# beeline toward to climb.
	_scatter_wanderers(5, _rock_spire_builders)
	_scatter_fruit_trees()
	_build_canyon_biome()
	_build_jungle_biome()
	_build_volcano_rocks()
	_build_plateau_side_ledges()
	_scatter_wasteland_rocks()
	_scatter_lake_gatherables()
	_scatter_ice_gate_dressing()
	# Wild blorbs and the giant must be children of Main for blorb.gd's
	# sibling-relative Terrain/Player lookups. During this node's _ready(),
	# Main is still entering its authored children and rejects add_child().
	# Defer the whole ordered actor phase, including the LOD scan that must run
	# after those actors exist, rather than deferring each insertion separately.
	_finish_dynamic_initialization.call_deferred()


func _finish_dynamic_initialization() -> void:
	_spawn_wilderness_npcs()
	_spawn_wild_blorbs()
	_spawn_jungle_plant_blorbs()
	_spawn_volcano_fire_blorbs()
	_spawn_canyon_rock_blorbs()
	_spawn_city_blorbs()
	_spawn_ice_plateau_blorbs()
	_spawn_wasteland_giant_blorb()
	_spawn_xiao_hou_zi()
	_register_wilderness_lod_nodes(self)


## Xiao Hou Zi (see docs/world_bible.md's jungle biome entry) is the jungle
## plateau's own resident -- a single instance, unlike the "lots" of wild
## blorbs above, since he's a named individual, not a species population.
## Parented to this node's own parent (Main) rather than to this node
## itself, for the same reason _place_wild_blorb() is: xiao_hou_zi.gd uses
## fixed get_node("../Terrain")/get_node("../Player") sibling lookups
## (mirroring blorb.gd's own), which only resolve one level down from Main.
func _spawn_xiao_hou_zi() -> void:
	var packed: PackedScene = load(XIAO_HOU_ZI_SCENE)
	if packed == null:
		push_warning("Missing Xiao Hou Zi scene: " + XIAO_HOU_ZI_SCENE)
		return
	var center: Vector2 = terrain.get_jungle_plateau_center()
	var radius: float = terrain.get_jungle_plateau_radius()
	var pos := _point_in_jungle_disk(center, radius * 0.6, 1.0)
	var inst = packed.instantiate()
	inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(inst)
	_update_wilderness_lod()


func _spawn_ice_plateau_blorbs() -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		return
	for i in 6:
		var angle: float = TAU * float(i) / 6.0 + 0.35
		var radius: float = 24.0 + float(i % 3) * 10.0
		var pos: Vector2 = ICE_GATE_XZ + Vector2(cos(angle), sin(angle)) * radius
		var blorb = packed.instantiate()
		blorb.in_party = false
		blorb.initial_element = "ice" if i % 2 == 0 else "snow"
		blorb.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		get_parent().add_child(blorb)


## Static, mostly non-colliding stones give the broad desert floor scale and
## texture. They join the existing distance-based shadow/collision pass, so
## the count adds negligible per-frame work compared with simulated actors.
func _scatter_wasteland_rocks() -> void:
	const ROCK_COUNT := 72
	for i in ROCK_COUNT:
		for attempt in 16:
			var pos := Vector2(_rng.randf_range(-620.0, 620.0), _rng.randf_range(-610.0, 610.0))
			var angle := atan2(pos.y, pos.x)
			if pos.length() < terrain.get_plateau_edge_radius(angle) + 22.0:
				continue
			if terrain.is_lake_area(pos) or terrain.jungle_coverage(pos.x, pos.y) > 0.02:
				continue
			if terrain.volcano_coverage(pos.x, pos.y) > 0.02:
				continue
			if pos.distance_to(terrain.get_city_center()) < 105.0:
				continue
			if pos.distance_to(CHINESE_VILLAGE_CENTER) < CHINESE_VILLAGE_EXCLUSION_RADIUS:
				continue
			var rock := NatureProps.build_rock(_rng.randf_range(0.18, 0.68), false)
			rock.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
			rock.rotation.y = _rng.randf_range(0.0, TAU)
			rock.scale.y = _rng.randf_range(0.55, 1.15)
			add_child(rock)
			break


## A ring of frost-tinted pines and rocks around the Ice Kingdom's own
## outskirts gate (see main.gd's own ICE_GATE_XZ comment) -- purely cosmetic
## dressing so the clearing reads as snowy without needing a new sculpted
## landform in terrain_generator.gd's own shared height function. Added to
## self directly (not get_parent()), same as _scatter_wasteland_rocks()
## above -- this runs synchronously during the ordinary scatter phase, not
## the deferred actor phase, since decorative props (unlike blorbs) have no
## sibling-lookup requirement of their own.
func _scatter_ice_gate_dressing() -> void:
	const PINE_COUNT := 10
	const ROCK_COUNT := 14
	var frost_leaf := Color(0.82, 0.9, 0.95)
	var frost_rock := Color(0.78, 0.84, 0.9)
	for i in PINE_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(10.0, ICE_GATE_DRESSING_RADIUS)
		var pos := ICE_GATE_XZ + Vector2(cos(angle), sin(angle)) * r
		var pine := NatureProps.build_pine_tree(_rng.randf_range(5.0, 9.0), frost_leaf)
		pine.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		pine.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(pine)
	for i in ROCK_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(6.0, ICE_GATE_DRESSING_RADIUS * 1.2)
		var pos := ICE_GATE_XZ + Vector2(cos(angle), sin(angle)) * r
		var rock := NatureProps.build_rock(_rng.randf_range(0.3, 1.0), false)
		rock.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		rock.rotation.y = _rng.randf_range(0.0, TAU)
		var frost_material := StandardMaterial3D.new()
		frost_material.albedo_color = frost_rock
		frost_material.roughness = 0.85
		for child in rock.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).set_surface_override_material(0, frost_material)
		add_child(rock)


## Shells and clams favor the newly exposed upper bank; lakeweed grows on
## the submerged basin floor. Every instance is a normal inventory pickup
## backed by a sellable ShopCatalog entry.
func _scatter_lake_gatherables() -> void:
	var water_y: float = terrain.get_lake_water_level()
	for i in 30:
		for attempt in 40:
			var pos := Vector2(_rng.randf_range(230.0, 625.0), _rng.randf_range(-335.0, 335.0))
			if terrain.lake_coverage(pos.x, pos.y) < 0.05:
				continue
			var ground_y: float = terrain.get_mesh_height(pos.x, pos.y)
			if ground_y < water_y - 0.35 or ground_y > water_y + 1.8:
				continue
			var item_name := "Lake Shell" if _rng.randf() < 0.58 else "Freshwater Clam"
			_place_lake_pickup(item_name, pos, ground_y)
			break
	for i in 46:
		for attempt in 30:
			var pos := Vector2(_rng.randf_range(315.0, 610.0), _rng.randf_range(-290.0, 290.0))
			if terrain.lake_coverage(pos.x, pos.y) < 0.58:
				continue
			var ground_y: float = terrain.get_mesh_height(pos.x, pos.y)
			if ground_y > water_y - 2.0:
				continue
			_place_lake_pickup("Lakeweed", pos, ground_y)
			break


func _place_lake_pickup(item_name: String, pos: Vector2, ground_y: float) -> void:
	var pickup := LakePickup.new()
	var entry := ShopCatalog.find(item_name)
	pickup.item_name = item_name
	pickup.item_color = entry.get("color", Color.WHITE)
	pickup.visual_scale = _rng.randf_range(0.8, 1.25)
	pickup.position = Vector3(pos.x, ground_y, pos.y)
	pickup.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(pickup)


## Uneven shelves interrupt the main plateau's single sheer side wall. Each
## shelf has a rock body, a thin grassy cap, real collision, and occasional
## vegetation rooted on its flat surface.
func _build_plateau_side_ledges() -> void:
	const LEDGE_COUNT := 22
	var grass_color := Color(0.07451, 0.63922, 0.40392)
	for i in LEDGE_COUNT:
		var angle := (float(i) / LEDGE_COUNT) * TAU + _rng.randf_range(-0.1, 0.1)
		# Keep the broad lake descent open and readable.
		if absf(angle) < 0.48 or absf(angle - TAU) < 0.48:
			continue
		var edge_radius: float = terrain.get_plateau_edge_radius(angle)
		var outward := Vector2(cos(angle), sin(angle))
		var width := _rng.randf_range(7.0, 15.0)
		var depth := _rng.randf_range(4.0, 8.0)
		var thickness := _rng.randf_range(1.0, 2.0)
		var center_2d := outward * (edge_radius + depth * 0.28)
		var inside := outward * (edge_radius - 3.0)
		var top_y: float = terrain.get_mesh_height(inside.x, inside.y)
		var ledge_y := top_y - _rng.randf_range(7.0, 43.0)
		var ledge := NatureProps.build_rock_slab(Vector3(width, thickness, depth), NatureProps.ROCK_COLOR.darkened(0.08))
		ledge.position = Vector3(center_2d.x, ledge_y, center_2d.y)
		ledge.rotation.y = PI * 0.5 - angle
		var turf := SuperEgg.build_part(Vector3(width * 0.49, 0.09, depth * 0.49), grass_color, 3.5, 4.0)
		turf.position.y = thickness + 0.04
		ledge.add_child(turf)
		if _rng.randf() < 0.68:
			var vegetation := NatureProps.build_bush(NatureProps.TREE_LEAF_COLORS[_rng.randi() % NatureProps.TREE_LEAF_COLORS.size()])
			vegetation.position = Vector3(_rng.randf_range(-width * 0.3, width * 0.3), thickness + 0.1, _rng.randf_range(-depth * 0.25, depth * 0.25))
			vegetation.scale = Vector3.ONE * _rng.randf_range(0.65, 1.0)
			ledge.add_child(vegetation)
		add_child(ledge)
	_build_jungle_plateau_side_ledges()


## The jungle plateau has a long natural rise instead of the main rim's
## sheer drop, so these shelves step outward along that slope. Sampling the
## real terrain at each radial distance makes them emerge at genuinely
## different elevations while remaining visibly anchored to the hillside.
func _build_jungle_plateau_side_ledges() -> void:
	const LEDGE_COUNT := 15
	var center: Vector2 = terrain.get_jungle_plateau_center()
	var turf_color := Color(0.05098, 0.36078, 0.14902)
	for i in LEDGE_COUNT:
		var angle := (float(i) / LEDGE_COUNT) * TAU + _rng.randf_range(-0.14, 0.14)
		var outward := Vector2(cos(angle), sin(angle))
		var edge_radius: float = terrain.get_jungle_plateau_edge_radius(angle)
		var slope_distance := _rng.randf_range(5.0, 52.0)
		var width := _rng.randf_range(5.5, 11.0)
		var depth := _rng.randf_range(3.8, 7.0)
		var thickness := _rng.randf_range(0.9, 1.6)
		var center_2d := center + outward * (edge_radius + slope_distance)
		var ground_y: float = terrain.get_mesh_height(center_2d.x, center_2d.y)
		var ledge := NatureProps.build_rock_slab(
			Vector3(width, thickness, depth), NatureProps.ROCK_COLOR.darkened(0.14)
		)
		ledge.position = Vector3(center_2d.x, ground_y - thickness * 0.58, center_2d.y)
		ledge.rotation.y = PI * 0.5 - angle
		var turf := SuperEgg.build_part(
			Vector3(width * 0.49, 0.1, depth * 0.49), turf_color, 3.5, 4.0
		)
		turf.position.y = thickness + 0.035
		ledge.add_child(turf)
		var vegetation_count := _rng.randi_range(1, 3)
		for vegetation_index in vegetation_count:
			var builder: Callable = _jungle_undergrowth_builders[
				_rng.randi() % _jungle_undergrowth_builders.size()
			]
			var vegetation: Node3D = builder.call()
			vegetation.position = Vector3(
				_rng.randf_range(-width * 0.32, width * 0.32), thickness + 0.12,
				_rng.randf_range(-depth * 0.28, depth * 0.28)
			)
			vegetation.scale = Vector3.ONE * _rng.randf_range(0.75, 1.25)
			ledge.add_child(vegetation)
		add_child(ledge)


## Supports a live script reload without any debug UI: _ready() does not run
## again in an existing session, so verify once on the next process frame
## that the world still contains its fixed wasteland resident.
func _process(delta: float) -> void:
	if not _giant_presence_checked:
		_giant_presence_checked = true
		var giant_exists := false
		for blorb in get_tree().get_nodes_in_group("blorbs"):
			if blorb is Blorb and (blorb as Blorb).blorb_type == "size":
				giant_exists = true
				break
		if not giant_exists:
			_spawn_wasteland_giant_blorb()
			_register_wilderness_lod_nodes(self)
	_prop_lod_timer -= delta
	if _prop_lod_timer <= 0.0:
		_prop_lod_timer = PROP_LOD_UPDATE_INTERVAL
		_update_wilderness_lod()


## Props stay instantiated, which avoids visible streaming/pop-in, while
## their broadphase collision, dynamic NPC updates, and shadow casters sleep
## outside the local exploration radius.
func _register_wilderness_lod_nodes(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionObject3D and not _wilderness_colliders.has(child):
			var collider := child as CollisionObject3D
			collider.set_meta("wilderness_collision_layer", collider.collision_layer)
			_wilderness_colliders.append(collider)
		if child is GeometryInstance3D and not _wilderness_geometry.has(child):
			var geometry := child as GeometryInstance3D
			geometry.set_meta("wilderness_shadow_mode", geometry.cast_shadow)
			_wilderness_geometry.append(geometry)
		if child is CharacterBody3D and not _wilderness_simulations.has(child):
			_wilderness_simulations.append(child)
		_register_wilderness_lod_nodes(child)


func _update_wilderness_lod() -> void:
	var player := get_node_or_null("../Player") as Node3D
	if player == null:
		return
	for collider in _wilderness_colliders:
		if not is_instance_valid(collider):
			continue
		var active: bool = collider.global_position.distance_to(player.global_position) <= PROP_COLLISION_RADIUS
		collider.collision_layer = int(collider.get_meta("wilderness_collision_layer")) if active else 0
	for geometry in _wilderness_geometry:
		if not is_instance_valid(geometry):
			continue
		var casts_shadow: bool = geometry.global_position.distance_to(player.global_position) <= PROP_SHADOW_RADIUS
		geometry.cast_shadow = int(geometry.get_meta("wilderness_shadow_mode")) if casts_shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for simulation in _wilderness_simulations:
		if not is_instance_valid(simulation):
			continue
		var simulation_3d := simulation as Node3D
		var active: bool = simulation_3d.global_position.distance_to(player.global_position) <= PROP_COLLISION_RADIUS
		simulation.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


## Fruit trees (see NatureProps.build_fruit_tree()) get their own dedicated
## pass rather than joining _tree_builders above -- per direct instruction
## they should be "dispersed throughout, or sometimes the same tree growing
## in an area like an orchard," which needs its own placement logic
## (matching fallen fruit per species, an actual row-planted cluster), not
## just another entry in the ordinary mixed-species tree scatter.
func _scatter_fruit_trees() -> void:
	const SOLITARY_COUNT := 10
	for i in SOLITARY_COUNT:
		var pos := _random_field_pos()
		if pos == Vector2.INF:
			continue
		var species: Dictionary = _fruit_tree_species[_rng.randi() % _fruit_tree_species.size()]
		_place_fruit_tree(pos, species)

	const ORCHARD_COUNT := 2
	for i in ORCHARD_COUNT:
		var center := _random_field_pos()
		if center == Vector2.INF:
			continue
		_fruit_orchard(center)


## Builds one fruit tree of the given species at pos, plus 1-2 already-
## fallen fruit lying on the ground near its base -- the actual pickup (see
## fruit.gd), placed separately from the tree's own decorative canopy fruit
## the same way this project already treats other found collectibles (Rock
## Gem/Ground Gem lying in the world rather than picked directly off
## whatever they're resting on).
func _place_fruit_tree(pos: Vector2, species: Dictionary, disk_sampler: Callable = Callable(self, "_point_in_disk")) -> void:
	var tree: StaticBody3D
	if species.has("tree_builder"):
		var tree_builder: Callable = species["tree_builder"]
		tree = tree_builder.call(species["height"], species["leaf"])
	else:
		tree = NatureProps.build_fruit_tree(species["height"], species["leaf"], species["fruit_color"])
	tree.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	tree.rotation.y = _rng.randf_range(0.0, TAU)
	tree.scale = Vector3.ONE * _rng.randf_range(0.9, 1.1)
	add_child(tree)
	_register_canopy_blobs(tree)

	var fallen_count := _rng.randi_range(1, 2)
	for i in fallen_count:
		var fruit_pos: Vector2 = disk_sampler.call(pos, 1.8, 1.0)
		if fruit_pos == Vector2.INF:
			continue
		var fruit := Fruit.new()
		fruit.fruit_color = species["fruit_color"]
		fruit.fruit_name = species["fruit_name"]
		if species.has("visual_builder"):
			fruit.visual_builder = species["visual_builder"]
		var ground_y: float = terrain.get_mesh_height(fruit_pos.x, fruit_pos.y)
		fruit.position = Vector3(fruit_pos.x, ground_y + 0.09, fruit_pos.y)
		add_child(fruit)


## A tidy grid of the same fruit tree species -- "sometimes the same tree
## growing in an area like an orchard," per direct instruction, distinct
## from the loose, mixed-species solitary placements above.
func _fruit_orchard(center: Vector2) -> void:
	var species: Dictionary = _fruit_tree_species[_rng.randi() % _fruit_tree_species.size()]
	const ROWS := 3
	const COLS := 3
	const SPACING := 5.0
	var origin := center - Vector2(SPACING, SPACING) * (Vector2(COLS, ROWS) - Vector2.ONE) * 0.5
	for row in ROWS:
		for col in COLS:
			var jitter := Vector2(_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6))
			var pos := origin + Vector2(col, row) * SPACING + jitter
			if absf(pos.x) > field_half_size or absf(pos.y) > field_half_size:
				continue
			if _is_excluded(pos):
				continue
			_place_fruit_tree(pos, species)


## Places each WILDERNESS_WANDERER_IDENTITIES entry at its own random spot
## in the field (same exclusion rules as every other placement here, so
## neither lands right on the player's spawn or inside the town) -- each
## one then wanders on its own via npc.gd's existing behavior (its own
## spawn position becomes its wander center), no special wiring needed
## beyond just placing it.
func _spawn_wilderness_npcs() -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		push_warning("Missing NPC scene: " + NPC_SCENE)
		return
	for identity in WILDERNESS_WANDERER_IDENTITIES:
		var pos := _random_field_pos()
		if pos == Vector2.INF:
			continue
		var inst: Node3D = packed.instantiate()
		inst.set_terrain_reference(terrain)
		inst.display_name = identity["name"]
		inst.is_female = identity["female"]
		inst.skin_color = identity["skin_color"]
		inst.shirt_color = identity["shirt_color"]
		inst.hair_color = identity["hair_color"]
		inst.hair_style = identity["hair_style"]
		var lines: Array[String] = []
		lines.assign(identity["lines"])
		inst.talk_lines = lines
		inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		add_child(inst)


## Scatters the field's initial wild blorb population -- lots of plain
## (unmerged) ones, a few rare shiny ones, and a couple already-elemental
## finds -- each at its own random spot (same exclusion rules as every other
## placement here). Replaces the old hand-placed WildBlorb1-4 scene nodes,
## per direct instruction to have "lots" of wild blorbs rather than a fixed
## handful. Shiny blorbs are always plain (element "") -- see blorb.gd's
## is_shiny doc comment: shiny is a cosmetic rarity, not an element, and
## never carries a gem.
func _spawn_wild_blorbs() -> void:
	for i in WILD_BLORB_NORMAL_COUNT:
		_place_wild_blorb("", false)
	for i in WILD_BLORB_SHINY_COUNT:
		_place_wild_blorb("", true)
	for element in WILD_BLORB_OTHER_ELEMENTS:
		_place_wild_blorb(element, false)
	for i in WILD_BLORB_AIR_COUNT:
		_place_wild_blorb("air", false)
	_spawn_lake_water_blorbs()


## The jungle plateau's own naturally-elemental find -- see
## WILD_BLORB_PLANT_COUNT's own doc comment for why this is a dedicated
## jungle-scoped spawn rather than folded into WILD_BLORB_OTHER_ELEMENTS
## above. Parented to Main the same way _place_wild_blorb() is, for the same
## sibling-lookup reason.
func _spawn_jungle_plant_blorbs() -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	var center: Vector2 = terrain.get_jungle_plateau_center()
	var radius: float = terrain.get_jungle_plateau_radius()
	for i in WILD_BLORB_PLANT_COUNT:
		var pos := _point_in_jungle_disk(center, radius * 0.9, 1.0)
		var inst = packed.instantiate()
		inst.in_party = false
		inst.initial_element = "plant"
		inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		get_parent().add_child(inst)


## The canyon biome's own naturally-elemental find -- mirrors
## _spawn_jungle_plant_blorbs() immediately above, just scoped to the
## canyon zone's own disk sampler instead of the jungle plateau's.
func _spawn_canyon_rock_blorbs() -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	for i in WILD_BLORB_CANYON_ROCK_COUNT:
		var pos := _point_in_canyon_disk(CANYON_BIOME_CENTER, CANYON_ZONE_RADIUS * 0.85, 1.1)
		if pos == Vector2.INF:
			continue
		var inst = packed.instantiate()
		inst.in_party = false
		inst.initial_element = "rock"
		inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		get_parent().add_child(inst)


## The outskirts city's own naturally-elemental find -- mirrors
## _spawn_canyon_rock_blorbs() immediately above, just scoped to the city's
## own disk sampler instead of the canyon's. Also drops one physical City
## Gem pickup somewhere in the same area, matching how the Rock Gem is
## placed directly inside _build_canyon_biome() rather than a separate
## per-element gem-placement pass.
func _spawn_city_blorbs() -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	for i in WILD_BLORB_CITY_COUNT:
		var pos := _point_in_city_disk(CITY_CENTER, CITY_ZONE_RADIUS * 0.85, 1.1)
		if pos == Vector2.INF:
			continue
		var inst = packed.instantiate()
		inst.in_party = false
		inst.initial_element = "city"
		inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		get_parent().add_child(inst)
	var gem_pos := _point_in_city_disk(CITY_CENTER, CITY_ZONE_RADIUS * 0.6, 1.0)
	if gem_pos != Vector2.INF:
		var gem_ground_y: float = terrain.get_mesh_height(gem_pos.x, gem_pos.y)
		_place_gem(
			self, Vector3(gem_pos.x, gem_ground_y + 0.3, gem_pos.y),
			ShopCatalog.CITY_COLOR, "City Gem", true, true
		)


## Same reasoning as _point_in_canyon_disk -- the outskirts city sits well
## outside the ordinary 190m field_half_size square _point_in_disk() covers.
func _point_in_city_disk(center: Vector2, radius: float, bias: float) -> Vector2:
	var r := radius * pow(_rng.randf(), bias)
	var angle := _rng.randf_range(0.0, TAU)
	return center + Vector2(cos(angle), sin(angle)) * r


## The volcano's own naturally-elemental find -- see WILD_BLORB_VOLCANO_
## FIRE_COUNT's own doc comment. Half spawn on the outer cone ("on... the
## volcano"), half inside the crater's own rocky skirt ("inside" it, between
## the lava pool and the rim) -- rejecting any point is_lava_area() itself
## rejects, so none of them end up floating in/under the molten pool.
## Parented to Main the same way _place_wild_blorb()/_spawn_jungle_plant_
## blorbs() are, for the same sibling-lookup reason.
func _spawn_volcano_fire_blorbs() -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	var center: Vector2 = terrain.get_volcano_center()
	var outer_radius: float = terrain.get_volcano_radius()
	var rim_radius: float = terrain.get_volcano_crater_rim_radius()
	var lava_radius: float = terrain.get_volcano_lava_radius()
	for i in WILD_BLORB_VOLCANO_FIRE_COUNT:
		var inside_crater := i % 2 == 0
		var pos: Variant = null
		for attempt in 8:
			var candidate: Vector2
			if inside_crater:
				# Inside the crater's rocky skirt, between the lava and the rim.
				var r := _rng.randf_range(lava_radius * 1.3, rim_radius * 0.9)
				var angle := _rng.randf_range(0.0, TAU)
				candidate = center + Vector2(cos(angle), sin(angle)) * r
			else:
				# On the outer cone's own open flank.
				candidate = _point_in_jungle_disk(center, outer_radius * 0.95, 1.0)
				if candidate.distance_to(center) < rim_radius * 1.05:
					continue
			if terrain.is_lava_area(candidate):
				continue
			pos = candidate
			break
		if pos == null:
			continue
		var placed: Vector2 = pos
		var inst = packed.instantiate()
		inst.in_party = false
		inst.initial_element = "fire"
		inst.position = Vector3(placed.x, terrain.get_mesh_height(placed.x, placed.y), placed.y)
		get_parent().add_child(inst)


## Freestanding boulders around the crater's own lava pool -- see
## VOLCANO_ROCK_COUNT's own doc comment. Added to `self`, not get_parent()
## (unlike the fire blorbs above) -- these are ordinary static props, not
## Terrain/Player-sibling-dependent actors, so they follow the same "add to
## self" rule _scatter_wasteland_rocks() and every other prop scatter in this
## file already uses; called from _ready() rather than the deferred actor
## phase, same as _build_jungle_biome()'s own prop-only half.
func _build_volcano_rocks() -> void:
	var center: Vector2 = terrain.get_volcano_center()
	var rim_radius: float = terrain.get_volcano_crater_rim_radius()
	var lava_radius: float = terrain.get_volcano_lava_radius()
	for i in VOLCANO_ROCK_COUNT:
		for attempt in 8:
			var r := _rng.randf_range(lava_radius * 1.1, rim_radius * 0.98)
			var angle := _rng.randf_range(0.0, TAU)
			var pos := center + Vector2(cos(angle), sin(angle)) * r
			if terrain.is_lava_area(pos):
				continue
			var rock := NatureProps.build_rock(_rng.randf_range(0.35, 1.1), true)
			rock.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
			rock.rotation.y = _rng.randf_range(0.0, TAU)
			rock.scale.y = _rng.randf_range(0.6, 1.3)
			add_child(rock)
			break


## Called by hud.gd once every wild blorb currently in the field has been
## found (in_party == true on all of them) -- per direct instruction, the
## compass shouldn't just vanish at that point; a few fresh wild blorbs
## should appear elsewhere instead, so the hunt keeps going. Mostly plain,
## occasionally shiny -- same rough ratio as the initial population, just a
## smaller top-up batch. Shiny stays plain-element here too -- see
## _spawn_wild_blorbs()'s own comment.
func spawn_replenishment_wave() -> void:
	for i in REPLENISH_COUNT:
		var shiny := _rng.randf() < (float(WILD_BLORB_SHINY_COUNT) / float(WILD_BLORB_NORMAL_COUNT))
		_place_wild_blorb("", shiny)
	Hud.show_message("New wild blorbs have appeared somewhere in the field!")


## Parented to this node's own parent (Main), not this node itself -- unlike
## every other prop/NPC placed in this file, blorb.gd's own _ready() finds
## its terrain/player siblings via a fixed get_node("../Terrain")/
## get_node("../Player") relative lookup (an @onready var, so it can't be
## pre-set the way npc.gd's terrain field is), which only resolves
## correctly one level down from Main -- the same level WildBlorb1-4 used
## to live at as hand-placed scene nodes.
func _place_wild_blorb(element: String, shiny: bool) -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	var pos := _random_field_pos()
	if pos == Vector2.INF:
		return
	var inst = packed.instantiate()
	inst.in_party = false
	inst.initial_element = element
	inst.is_shiny = shiny
	inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(inst)


func _spawn_lake_water_blorbs() -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	var spawned := 0
	for attempt in 80:
		if spawned >= LAKE_WATER_BLORB_COUNT:
			return
		# The central/eastern basin is safely deep; lake_coverage still checks
		# the organic shoreline so none spawn on a dry or shallow edge.
		var pos := Vector2(_rng.randf_range(300.0, 590.0), _rng.randf_range(-250.0, 250.0))
		if terrain.lake_coverage(pos.x, pos.y) < 0.7:
			continue
		var inst = packed.instantiate()
		inst.in_party = false
		inst.initial_element = "water"
		# Start at the shared waterline; blorb.gd's existing buoyancy settles
		# it to its natural floating submergence on the next frame.
		inst.position = Vector3(pos.x, terrain.get_lake_water_level(), pos.y)
		get_parent().add_child(inst)
		spawned += 1


## A fixed resident rather than part of the replenishing wild population:
## its scale makes it a northern-wasteland landmark, not a party member.
## It has no hopping phase at all; every deliberate motion is one tenth of
## a normal blorb's speed to sell the immense mass.
func _spawn_wasteland_giant_blorb() -> void:
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	var giant = packed.instantiate()
	giant.blorb_name = "Humongous"
	giant.blorb_type = "size"
	giant.size_multiplier = WASTELAND_GIANT_SIZE
	giant.vertical_scale = 0.72
	giant.movement_speed_multiplier = WASTELAND_GIANT_MOVEMENT_SPEED
	giant.allow_movement_hops = false
	giant.can_join_party = false
	giant.in_party = false
	giant.body_color = Color(0.7, 0.78, 0.72, 0.9)
	var pos := WASTELAND_GIANT_POS
	giant.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(giant)


func _scatter_clusters() -> void:
	var cluster_count := 22
	for i in cluster_count:
		var center := _random_field_pos()
		if center == Vector2.INF:
			continue
		var roll := _rng.randf()
		if roll < 0.45:
			_forest_cluster(center)
		elif roll < 0.75:
			_meadow_cluster(center)
		else:
			_rocky_cluster(center)


func _forest_cluster(center: Vector2) -> void:
	var radius := _rng.randf_range(12.0, 26.0)
	var tree_count := int(_rng.randf_range(8, 18))
	for i in tree_count:
		var pos := _point_in_disk(center, radius, 1.5)
		if pos == Vector2.INF:
			continue
		_place_solid(_tree_builders, pos)
	var under_count := int(_rng.randf_range(4, 10))
	for i in under_count:
		var pos := _point_in_disk(center, radius * 0.8, 1.0)
		if pos == Vector2.INF:
			continue
		_place_decor(_undergrowth_builders, pos)


func _meadow_cluster(center: Vector2) -> void:
	var radius := _rng.randf_range(8.0, 16.0)
	var count := int(_rng.randf_range(12, 26))
	for i in count:
		var pos := _point_in_disk(center, radius, 1.2)
		if pos == Vector2.INF:
			continue
		_place_decor(_meadow_builders, pos)
	if _rng.randf() < 0.5:
		var pos := _point_in_disk(center, radius * 0.6, 1.5)
		if pos != Vector2.INF:
			_place_solid(_tree_builders, pos)


func _rocky_cluster(center: Vector2) -> void:
	var radius := _rng.randf_range(6.0, 13.0)
	# A tall spire as the cluster's centerpiece, close to dead center, about
	# 40% of the time -- something worth actually climbing to, not just a
	# field of knee-high obstacles.
	if _rng.randf() < 0.4:
		var spire_pos := _point_in_disk(center, radius * 0.3, 1.0)
		if spire_pos != Vector2.INF:
			_place_solid(_rock_spire_builders, spire_pos)
	var rock_count := int(_rng.randf_range(4, 10))
	for i in rock_count:
		var pos := _point_in_disk(center, radius, 1.3)
		if pos == Vector2.INF:
			continue
		_place_solid(_rock_builders, pos)
	var decor_count := int(_rng.randf_range(4, 11))
	for i in decor_count:
		var pos := _point_in_disk(center, radius, 1.2)
		if pos == Vector2.INF:
			continue
		_place_decor(_rocky_decor_builders, pos)


## Builds a ready-to-place FlowerPickup for the given NatureProps.
## FLOWER_COLORS name -- used by every builder array above in place of a
## bare decorative NatureProps.build_flower() call, so a flower found in the
## field is a real Inventory/ShopCatalog item instead of just scenery.
func _make_flower_pickup(flower_name: String) -> FlowerPickup:
	var pickup := FlowerPickup.new()
	pickup.flower_name = flower_name
	pickup.petal_color = NatureProps.FLOWER_COLORS[flower_name]
	return pickup


## Same idea as _make_flower_pickup() above, for NatureProps.MUSHROOM_COLORS.
func _make_mushroom_pickup(mushroom_name: String) -> MushroomPickup:
	var pickup := MushroomPickup.new()
	pickup.mushroom_name = mushroom_name
	pickup.cap_color = NatureProps.MUSHROOM_COLORS[mushroom_name]
	return pickup


## The jungle plateau (see terrain_generator.gd's JUNGLE_PLATEAU_CENTER/
## _RADIUS and docs/world_bible.md's jungle biome entry) -- "a lush thick
## varied landscape" distinct from the ordinary field, per direct
## instruction, so this scatters denser/taller jungle-only vegetation within
## the plateau's own footprint rather than reusing _tree_builders/
## _meadow_builders above. Mirrors _build_canyon_biome()'s own
## dedicated-zone pattern.
func _build_jungle_biome() -> void:
	var center: Vector2 = terrain.get_jungle_plateau_center()
	var radius: float = terrain.get_jungle_plateau_radius()

	# Counts bumped well past a flat proportional scale-up of the plateau's
	# own ~2.4x area increase (JUNGLE_PLATEAU_RADIUS 45 -> 70, see
	# terrain_generator.gd) -- per direct instruction the jungle should read
	# as "more densely populated," not just "the same density over a bigger
	# footprint."
	const TREE_COUNT := 55
	for i in TREE_COUNT:
		var pos := _point_in_jungle_disk(center, radius * 0.9, 1.0)
		_place_solid(_jungle_tree_builders, pos)

	const UNDERGROWTH_COUNT := 110
	for i in UNDERGROWTH_COUNT:
		var pos := _point_in_jungle_disk(center, radius * 0.95, 1.0)
		_place_decor(_jungle_undergrowth_builders, pos)

	const FRUIT_TREE_COUNT := 18
	for i in FRUIT_TREE_COUNT:
		var pos := _point_in_jungle_disk(center, radius * 0.85, 1.0)
		var species: Dictionary = _jungle_fruit_tree_species[_rng.randi() % _jungle_fruit_tree_species.size()]
		_place_fruit_tree(pos, species, Callable(self, "_point_in_jungle_disk"))

	_place_plant_gem(center, radius)


## A Plant Gem waits atop one of the jungle plateau's own canopy trees --
## placed as a dedicated tree outside the random TREE_COUNT scatter above so
## its exact canopy-top position is known, the same way _build_mesa_tower()
## places the Ground Gem on its own dedicated hoodoo. A stout baobab reads
## clearly as "a tree with something sitting on top of it" from the ground,
## unlike the narrower palm/banyan silhouettes. Finds the tallest of the
## tree's own registered canopy lobes (see _register_canopy_blobs()) rather
## than assuming the trunk's own XZ, since a baobab's lobes scatter off-
## center around the crown.
func _place_plant_gem(center: Vector2, radius: float) -> void:
	var pos := _point_in_jungle_disk(center, radius * 0.6, 1.0)
	var tree := NatureProps.build_baobab_tree(_rng.randf_range(18.0, 24.0), _rng)
	tree.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	tree.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(tree)
	var blob_start := _canopy_blobs.size()
	_register_canopy_blobs(tree)
	var top_y := -INF
	var top_center := Vector3.ZERO
	for i in range(blob_start, _canopy_blobs.size()):
		var blob: Dictionary = _canopy_blobs[i]
		var peak: float = (blob["center"] as Vector3).y + (blob["axes"] as Vector3).y
		if peak > top_y:
			top_y = peak
			top_center = blob["center"]
	if top_y > -INF:
		_place_gem(
			self, Vector3(top_center.x, top_y + 0.4, top_center.z),
			ShopCatalog.PLANT_COLOR, "Plant Gem", true, true
		)


## One large, dedicated canyon-biome landmark (see docs/world_bible.md's
## own entry for it) -- roughly 5-11x an ordinary _rocky_cluster()'s own
## footprint (radius 6-13m there vs. 72m here), a slab-paved floor,
## towering banded hoodoos, and a couple of simplified natural arches, on
## top of the spire/boulder/rock-ramp mix the smaller clusters already
## use. Per direct instruction to go big -- this doesn't replace the
## smaller scattered rocky clusters/wandering spires elsewhere in the
## field, it's one additional, much bigger focal point layered on top.
func _build_canyon_biome() -> void:
	var center := CANYON_BIOME_CENTER
	var zone_radius := CANYON_ZONE_RADIUS

	# Terrain has no way to know where this biome will land until this exact
	# point -- set_canyon_zone()
	# tints the whole zone's ground color to dirt regardless of the ordinary
	# height-based grass/dirt/rock/snow gradient (see terrain_generator.gd's
	# own _height_color()), so the canyon floor doesn't read as two unrelated
	# colors of ground depending on which patch happens to sit low or high.
	# Safe to call after props below start querying terrain.get_mesh_height()
	# -- only the per-vertex color actually changes, not the height function
	# itself, so nothing placed against it moves.
	terrain.set_canyon_zone(center, zone_radius)

	_pave_canyon_floor(center, zone_radius)
	_build_canyon_cliff_cascade(center)
	_build_mesa_tower(center)

	# A Rock Gem, resting on the canyon floor rather than up on the Mesa
	# Tower -- a find for a player exploring on foot, not gated behind the
	# climb the Ground Gem requires.
	var rock_gem_pos := _point_in_canyon_disk(center, zone_radius * 0.5, 1.0)
	if rock_gem_pos != Vector2.INF:
		var rock_ground_y: float = terrain.get_mesh_height(rock_gem_pos.x, rock_gem_pos.y)
		_place_gem(
			self, Vector3(rock_gem_pos.x, rock_ground_y + 0.3, rock_gem_pos.y),
			ShopCatalog.ROCK_COLOR, "Rock Gem", true, true
		)

	# Towering banded hoodoos -- 6-12 tiers each, roughly 4-12m tall
	# depending on how many tiers and how wide the base roll comes out.
	for i in 8:
		var pos := _point_in_canyon_disk(center, zone_radius * 0.85, 1.1)
		if pos == Vector2.INF:
			continue
		var tower := NatureProps.build_slab_tower(
			_rng.randf_range(2.5, 4.0), _rng.randi_range(6, 12), _rng
		)
		var body: StaticBody3D = tower["body"]
		body.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		add_child(body)

	# A couple of natural rock arches.
	for i in 2:
		var pos := _point_in_canyon_disk(center, zone_radius * 0.6, 1.0)
		if pos == Vector2.INF:
			continue
		var arch := NatureProps.build_rock_arch(_rng.randf_range(6.0, 9.0), _rng)
		arch.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
		arch.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(arch)

	# The same spire/boulder/rock-ramp mix _rocky_cluster() uses, just at
	# this zone's own much larger scale -- layered underneath/among the
	# slabs and hoodoos above, not replaced by them.
	for i in 6:
		var pos := _point_in_canyon_disk(center, zone_radius * 0.85, 1.1)
		if pos != Vector2.INF:
			_place_solid(_zone_spire_builders, pos)
	for i in 30:
		var pos := _point_in_canyon_disk(center, zone_radius, 1.0)
		if pos != Vector2.INF:
			_place_solid(_rock_builders, pos)
	for i in 20:
		var pos := _point_in_canyon_disk(center, zone_radius, 1.0)
		if pos != Vector2.INF:
			_place_decor(_rocky_decor_builders, pos)
	for i in 6:
		var pos := _point_in_canyon_disk(center, zone_radius * 0.7, 1.0)
		if pos != Vector2.INF:
			_place_rock_ramp(pos)


## Canyon placement deliberately ignores the ordinary 190m wilderness
## scatter boundary: this landmark is meant to cross the western cliff.
func _point_in_canyon_disk(center: Vector2, radius: float, bias: float) -> Vector2:
	var r := radius * pow(_rng.randf(), bias)
	var angle := _rng.randf_range(0.0, TAU)
	return center + Vector2(cos(angle), sin(angle)) * r


## Same reasoning as _point_in_canyon_disk above -- the jungle plateau
## (terrain.get_jungle_plateau_center(), far southwest at (-280, 260)) sits
## well outside the ordinary 190m field_half_size square _point_in_disk()
## enforces, so jungle placement needs its own unbounded sampler.
func _point_in_jungle_disk(center: Vector2, radius: float, bias: float) -> Vector2:
	var r := radius * pow(_rng.randf(), bias)
	var angle := _rng.randf_range(0.0, TAU)
	return center + Vector2(cos(angle), sin(angle)) * r


## A continuous ribbon of sandstone ledges down the cliff face.  The raw
## terrain rim is a roughly 60m step, so merely paving both elevations leaves
## the biome visually severed and impossible to climb.  These overlapping
## slabs keep each rise below an ordinary player's jump height and each
## horizontal transfer short enough to traverse in either direction.
func _build_canyon_cliff_cascade(center: Vector2) -> void:
	const SEARCH_START_X := -180.0
	const SEARCH_END_X := -300.0
	const SEARCH_STEP := 1.0
	const LEDGE_RISE := 1.15
	const LEDGE_RUN := 1.05
	const LEDGE_SIZE := Vector3(4.2, 0.65, 4.6)

	var cliff_x := SEARCH_START_X
	var previous_height: float = terrain.get_height(cliff_x, center.y)
	var x := SEARCH_START_X - SEARCH_STEP
	while x >= SEARCH_END_X:
		var sampled_height: float = terrain.get_height(x, center.y)
		if previous_height - sampled_height > 8.0:
			cliff_x = x + SEARCH_STEP * 0.5
			break
		previous_height = sampled_height
		x -= SEARCH_STEP

	var top_y: float = terrain.get_mesh_height(cliff_x + 5.0, center.y)
	var bottom_y: float = terrain.get_mesh_height(cliff_x - 12.0, center.y)
	var ledge_count := maxi(2, int(ceil((top_y - bottom_y) / LEDGE_RISE)))
	for i in ledge_count + 1:
		var progress := float(i) / float(ledge_count)
		var ledge_pos := Vector3(
			cliff_x + 2.0 - float(i) * LEDGE_RUN,
			lerpf(top_y, bottom_y, progress) - LEDGE_SIZE.y * 0.35,
			center.y + sin(float(i) * 0.72) * 1.5
		)
		var color: Color = NatureProps.CANYON_BAND_COLORS[i % NatureProps.CANYON_BAND_COLORS.size()]
		var ledge := NatureProps.build_rock_slab(LEDGE_SIZE, color)
		ledge.position = ledge_pos
		ledge.rotation.y = sin(float(i) * 0.47) * 0.12
		add_child(ledge)


## Fully paves the canyon floor with rock slabs -- a jittered grid, not a
## rejection-sampled random scatter (what an earlier version of this did):
## random placement only ever gives sparse decoration no matter how many
## attempts you throw at it, since nothing stops two rolls landing right on
## top of each other while a third spot goes untouched. A grid guarantees
## coverage by construction instead.
##
## GRID_SPACING and the slab size floor (SLAB_MIN) are tuned together so
## adjacent slabs can never actually gap even in the worst case: two
## neighboring grid points can drift at most GRID_SPACING + 2*JITTER apart
## (both jittered the maximum amount, straight away from each other), and
## SLAB_MIN alone (each slab's own half-size is at least half of SLAB_MIN,
## so two neighbors contribute a full SLAB_MIN between them) is set equal
## to that -- so the two slabs are guaranteed to at least touch, usually
## with real overlap once jitter/size roll below their maximums.
func _pave_canyon_floor(center: Vector2, radius: float) -> void:
	const GRID_SPACING := 9.0
	const JITTER := 1.5
	const SLAB_MIN := 12.0  # GRID_SPACING + 2 * JITTER, see doc comment above
	const SLAB_MAX := 15.0

	var half_extent := radius + GRID_SPACING
	var steps := int(half_extent * 2.0 / GRID_SPACING)
	for gx in steps:
		for gz in steps:
			var grid_pos := center - Vector2(half_extent, half_extent) + Vector2(gx, gz) * GRID_SPACING
			var pos := grid_pos + Vector2(
				_rng.randf_range(-JITTER, JITTER), _rng.randf_range(-JITTER, JITTER)
			)
			if pos.distance_to(center) > radius + SLAB_MAX * 0.5:
				continue
			if _is_excluded(pos):
				continue

			var slab_size := Vector3(
				_rng.randf_range(SLAB_MIN, SLAB_MAX), _rng.randf_range(0.4, 0.9),
				_rng.randf_range(SLAB_MIN, SLAB_MAX)
			)
			var color: Color = (
				NatureProps.CANYON_BAND_COLORS[_rng.randi() % NatureProps.CANYON_BAND_COLORS.size()]
			)
			var slab := NatureProps.build_rock_slab(slab_size, color)
			# Explicit : float, not := -- terrain is typed as plain Node
			# (see this file's @onready var), so GDScript can't infer
			# get_mesh_height()'s return type through type inference alone
			# (same pitfall as blorb.gd's own _ground_height_at()).
			var ground_y: float = terrain.get_mesh_height(pos.x, pos.y)
			# Embedded down (not sitting flush on the terrain sample) so
			# uneven ground never leaves a visible gap under a slab's edge.
			slab.position = Vector3(pos.x, ground_y - slab_size.y * 0.3, pos.y)
			slab.rotation.y = _rng.randf_range(0.0, TAU)
			add_child(slab)


## A natural rock-slab ramp (see NatureProps.build_rock_ramp()'s own doc
## comment) with a small shelf of 2-3 rocks sitting at its own landing --
## something to actually arrive at, not just a slope to a dead end. The
## shelf rocks are parented to the ramp itself (not placed with world-space
## math) so they inherit its random rotation for free, the same trick
## _build_roof_ramps() in town_generator.gd uses for a town ramp's own
## landing.
func _place_rock_ramp(pos: Vector2) -> void:
	var rise := _rng.randf_range(2.5, 4.5)
	var run := rise * _rng.randf_range(1.8, 2.4)
	var width := _rng.randf_range(2.2, 3.2)

	var ramp := NatureProps.build_rock_ramp(width, run, rise)
	ramp.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	ramp.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(ramp)

	var shelf_count := _rng.randi_range(2, 3)
	for i in shelf_count:
		var shelf_rock := NatureProps.build_rock(_rng.randf_range(0.6, 1.0))
		shelf_rock.position = Vector3(
			_rng.randf_range(-width * 0.3, width * 0.3), rise, run + _rng.randf_range(0.0, 1.5)
		)
		shelf_rock.rotation.y = _rng.randf_range(0.0, TAU)
		ramp.add_child(shelf_rock)


## The one dedicated tall landmark at the canyon biome's own center (see
## docs/world_bible.md's canyon biome / Mesa Biome entry) -- taller and more
## tiered than the 8 ordinary hoodoos _build_canyon_biome() scatters around
## it (whose own tiers max out at 12), so it reads as the deliberate climb,
## not just a bigger background prop. Base width fixed at the top of the
## ordinary range (not randomized down) rather than pushed tiers much past
## 12 -- build_slab_tower()'s per-tier width shrink (0.72-0.9x) compounds
## fast, and a much taller tier count tapers the top landing down to
## essentially a pinpoint before it ever reads as "more dramatic." Same
## jump-to-jump tiered platforming as every other slab tower (see
## NatureProps.build_slab_tower()'s own doc comment) -- reaching the Ground
## Gem waiting on top is real parkour, not a cutscene.
const MESA_TOWER_BASE_WIDTH := 4.0
const MESA_TOWER_TIERS := 13


func _build_mesa_tower(center: Vector2) -> void:
	var tower := NatureProps.build_slab_tower(MESA_TOWER_BASE_WIDTH, MESA_TOWER_TIERS, _rng)
	var body: StaticBody3D = tower["body"]
	body.position = Vector3(center.x, terrain.get_mesh_height(center.x, center.y), center.y)
	add_child(body)
	_place_gem(
		body, Vector3(0, tower["top_height"] + 0.4, 0),
		ShopCatalog.GROUND_COLOR, "Ground Gem", true, true
	)


## Same pattern as town_generator.gd's own _place_gem() -- kept as a
## separate copy rather than shared since the two generators don't share a
## base class to hang it on.
func _place_gem(parent: Node3D, local_pos: Vector3, color: Color, gem_name: String, collectible: bool, floats: bool) -> void:
	const GEM_SCENE := "res://scenes/gem.tscn"
	var packed: PackedScene = load(GEM_SCENE)
	if packed == null:
		push_warning("Missing gem scene: " + GEM_SCENE)
		return
	var gem = packed.instantiate()
	gem.gem_color = color
	gem.display_name = gem_name
	gem.collectible = collectible
	gem.floats = floats
	gem.position = local_pos
	parent.add_child(gem)


func _scatter_background(count: int) -> void:
	for i in count:
		var pos := _random_field_pos()
		if pos == Vector2.INF:
			continue
		_place_decor(_background_decor_builders, pos)


func _scatter_wanderers(count: int, builders: Array) -> void:
	for i in count:
		var pos := _random_field_pos()
		if pos == Vector2.INF:
			continue
		_place_solid(builders, pos)


func _place_solid(builders: Array, pos: Vector2) -> void:
	var builder: Callable = builders[_rng.randi() % builders.size()]
	var instance: Node3D = builder.call()
	instance.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	instance.rotation.y = _rng.randf_range(0.0, TAU)
	instance.scale = Vector3.ONE * _rng.randf_range(0.85, 1.2)
	add_child(instance)
	_register_canopy_blobs(instance)


func _place_decor(builders: Array, pos: Vector2) -> void:
	var builder: Callable = builders[_rng.randi() % builders.size()]
	var instance: Node3D = builder.call()
	instance.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	instance.rotation.y = _rng.randf_range(0.0, TAU)
	instance.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
	add_child(instance)


func _is_excluded(pos: Vector2) -> bool:
	if pos.length() < spawn_exclusion_radius:
		return true
	if pos.distance_to(town_center) < town_exclusion_radius:
		return true
	return false


## Resolves `instance`'s own NatureProps-authored canopy blobs (see that
## file's _add_canopy_blob()) to world space and appends them to
## _canopy_blobs, once, right after `instance` is placed/rotated/scaled --
## trees never move again afterward, so there's no per-frame cost the way
## CloudScatter's own puffs would have if they moved. Uniform scale only
## (instance.scale is always Vector3.ONE * a single random factor, see
## _place_solid()/_place_fruit_tree() above), so semi_axes just scale by
## instance.scale.x rather than needing the full basis.
func _register_canopy_blobs(instance: Node3D) -> void:
	if not instance.has_meta("canopy_blobs"):
		return
	var uniform_scale: float = instance.scale.x
	for blob in (instance.get_meta("canopy_blobs") as Array):
		_canopy_blobs.append({
			"center": instance.to_global(blob["local_pos"]),
			"axes": (blob["semi_axes"] as Vector3) * uniform_scale,
		})


## Highest walkable tree-canopy top at this XZ position, no higher than
## max_surface_y -- same one-way math CloudScatter.get_support_height_at()
## uses for its own cloud puffs (see that function's own doc comment), just
## over _canopy_blobs instead. Player/Blorb use this the same way they
## already use the cloud one: walkable underneath/through the sides,
## landable only when a falling body settles onto the top from above.
func get_support_height_at(world_x: float, world_z: float, max_surface_y: float = INF) -> Variant:
	var best: Variant = null
	for blob in _canopy_blobs:
		var center: Vector3 = blob["center"]
		var axes: Vector3 = blob["axes"]
		var horizontal_profile := pow(absf((world_x - center.x) / axes.x), SuperEgg.EPSILON_SOFT) + pow(absf((world_z - center.z) / axes.z), SuperEgg.EPSILON_SOFT)
		if horizontal_profile > 1.0:
			continue
		var top := center.y + axes.y * pow(1.0 - horizontal_profile, 1.0 / SuperEgg.EPSILON_SOFT)
		if top <= max_surface_y and (best == null or top > best):
			best = top
	return best


func _random_field_pos() -> Vector2:
	for attempt in 20:
		var pos := Vector2(
			_rng.randf_range(-field_half_size, field_half_size),
			_rng.randf_range(-field_half_size, field_half_size)
		)
		if not _is_excluded(pos):
			return pos
	return Vector2.INF


func _point_in_disk(center: Vector2, radius: float, bias: float) -> Vector2:
	for attempt in 10:
		var r := radius * pow(_rng.randf(), bias)
		var angle := _rng.randf_range(0.0, TAU)
		var pos := center + Vector2(cos(angle), sin(angle)) * r
		if (
			absf(pos.x) <= field_half_size
			and absf(pos.y) <= field_half_size
			and not _is_excluded(pos)
		):
			return pos
	return Vector2.INF
