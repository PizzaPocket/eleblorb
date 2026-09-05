extends Node3D

## The primate kingdom's first village (see kingdom_bootstrap.gd) -- a
## handful of NatureProps.build_emergent_tree() giants near the spawn point,
## each with small treehouses mounted on alternating branch-ramp landings,
## spaced vertically up and down the trunk, per direct instruction. Kept
## inside jungle_kingdom_foliage.gd's own CLEAR_RADIUS (24.0 around the
## origin) so ordinary canopy trees never clip through these.

const TREE_LOCAL_POSITIONS := [
	Vector2(14.0, 12.0),
	Vector2(-16.0, 9.0),
	Vector2(2.0, -18.0),
]
const TREE_HEIGHTS := [56.0, 62.0, 58.0]
const DECK_SIZE := Vector3(3.6, 0.3, 3.6)

const VILLAGER_SCENE: PackedScene = preload("res://scenes/jungle_villager.tscn")
## Ground-level villagers roaming the village clearing itself -- see
## jungle_kingdom_foliage.gd's own CLEAR_RADIUS (24.0), the same footprint
## this stays inside.
const GROUND_VILLAGER_COUNT := 5
const GROUND_ROAM_RADIUS := 22.0

# One entry per villager this file ever spawns (13 anchored on treehouse
# decks -- 4 + 5 + 4 across the three trees' every-third-landing houses, see
# _build_tree_and_houses -- plus GROUND_VILLAGER_COUNT roaming the clearing
# floor -- 18 total). Consumed in spawn order (_assign_villager_identity),
# exactly mirroring town_generator.gd's VILLAGER_IDENTITIES/
# _assign_villager_identity: each villager gets their own name and their own
# lines instead of every instance drawing from one shared pool, which was
# the actual bug behind these reading as generic scenery rather than
# individuals (see jungle_villager.gd's TALK_LINES comment). The last 5
# entries are ground-flavored to match the ground roamers they land on,
# since _ready() spawns all 13 anchored villagers before any ground ones.
const JUNGLE_VILLAGER_IDENTITIES := [
	{
		"name": "Kesh Underbough",
		"lines": [
			"Ramps get slick after rain. Mind your footing, especially past the third landing on any tree, not just this one.",
			"I've climbed every rung on this trunk since I could walk. Still haven't found the top worth the trip.",
		],
	},
	{
		"name": "Tamsin Reedwalker",
		"lines": [
			"The river below wasn't always so wide. It carved that shape in a season nobody living now remembers starting.",
			"Fish don't come this high, but I still watch the water most evenings. Habit, I suppose, more than purpose.",
		],
	},
	{
		"name": "Elden Barrow",
		"lines": [
			"The elders keep to the tallest trees for a reason nobody younger seems to ask about anymore.",
			"A curse doesn't care how careful you are. It only cares whether a cradle gets used.",
		],
	},
	{
		"name": "Nettle Vray",
		"lines": [
			"You're the first outsider I've seen up this high. Most people can't climb this far, or won't.",
			"Is it true you talk to a slime? I'd ask it questions all day if it were mine.",
		],
	},
	{
		"name": "Corvin Ashwake",
		"lines": [
			"Ashwake. Yes, that's the family name, and no, I didn't choose it. Ask my grandmother about the joke.",
			"We don't joke about the ashing where the young ones can hear. Elsewhere, though, someone has to.",
		],
	},
	{
		"name": "Sable Hollow",
		"lines": [
			"A cradle went up two trees over last month. Nobody's said the word since, but everyone's counting the days.",
			"My shadow's the only part of me that isn't afraid of what's coming. Small comfort, but I'll take it.",
		],
	},
	{
		"name": "Rook Bramblewood",
		"lines": [
			"Built half these ramps myself, or repaired what the storms took. Bark doesn't hold a nail the way wood does.",
			"Xiao Hou Zi used to climb up here and pester me about tools. Miss the racket, honestly.",
		],
	},
	{
		"name": "Yarrow Dess",
		"lines": [
			"Something's coming for this world, or so the vines whisper. I've stopped asking which vines. Nobody ever says.",
			"I'd rather not think too hard about the shadows that outlast us. Doesn't change what they are.",
		],
	},
	{
		"name": "Pemberly Cade",
		"lines": [
			"The training grounds down below have gone quiet lately. Whoever's running that dummy business isn't telling anyone how.",
			"Don't wander near the practice dummies after dark. I've heard they don't stay dummies forever.",
		],
	},
	{
		"name": "Tovik Greymoss",
		"lines": [
			"Down in the lowland jungle, that's where you'll find Xiao Hou Zi, if he hasn't wandered off again.",
			"He used to visit before he took up with travelers. Good company, when he sat still long enough.",
		],
	},
	{
		"name": "Wisha Fenlow",
		"lines": [
			"We don't get many visitors up here. Most people can't climb this high, and fewer bother trying.",
			"I like the quiet more than I like company, if I'm honest. Don't take it personally.",
		],
	},
	{
		"name": "Bracken Solt",
		"lines": [
			"Every trunk in this village has its own creak. I could find my way home blind, just by listening.",
			"The wind changes before a storm does, up this high. You learn to read it or you learn to fall.",
		],
	},
	{
		"name": "Marlow Quist",
		"lines": [
			"Watch your step past the third landing on the east tree. That one's been loose for a season now.",
			"I keep telling the carpenters to fix it. They keep telling me it's character.",
		],
	},
	{
		"name": "Sedge Marrow",
		"lines": [
			"The clearing floor's soft after rain. Good for bare feet, bad for anyone in a hurry.",
			"I forage down here most mornings. The canopy villagers say I've gone native. I say they've gone up.",
		],
	},
	{
		"name": "Ilva Bracken",
		"lines": [
			"There used to be more of us down on the ground. The trees got safer, somehow, and everyone climbed.",
			"I like having my feet on something that isn't swaying. Call it a personal failing.",
		],
	},
	{
		"name": "Osmund Reave",
		"lines": [
			"Whatever's cursing this kingdom, it doesn't seem to care whether you're up a tree or down here with me.",
			"My shadow's outlived two of my cousins now. Doesn't make for easy conversation with it.",
		],
	},
	{
		"name": "Linnet Grove",
		"lines": [
			"The clearing gets loud with birdsong an hour before dawn, then goes dead quiet right after. Never figured out why.",
			"You get used to the canopy blocking most of the sky. Then one day you look up and it startles you.",
		],
	},
	{
		"name": "Dune Sarrow",
		"lines": [
			"I've met maybe three outsiders in my life. You're the friendliest looking one so far, for what that's worth.",
			"Ask the elders about the curse if you really want an answer. I just try not to think about it.",
		],
	},
]

var _rng := RandomNumberGenerator.new()
var _terrain: Node
var _next_villager_identity := 0


func _ready() -> void:
	_rng.seed = 20260819
	_terrain = get_node_or_null("../Terrain")
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	for i in TREE_LOCAL_POSITIONS.size():
		_build_tree_and_houses(TREE_LOCAL_POSITIONS[i], TREE_HEIGHTS[i], _terrain, i)
	_build_ground_villagers()


func _build_tree_and_houses(local_pos: Vector2, height: float, terrain: Node, tree_index: int) -> void:
	var base_y: float = terrain.get_mesh_height(local_pos.x, local_pos.y)
	var result := NatureProps.build_emergent_tree(height, _rng)
	var tree_body: StaticBody3D = result["body"]
	var trunk_pos := Vector3(local_pos.x, base_y, local_pos.y)
	tree_body.position = trunk_pos
	add_child(tree_body)

	var platforms: Array = result["platform_positions"]
	for i in platforms.size():
		# Every third landing, not every other -- per direct feedback that
		# ramps were getting physically blocked by the treehouse mounted on
		# the landing just above them. Tripling (rather than doubling) the
		# vertical gap between treehouse levels, combined with
		# build_emergent_tree()'s own golden-angle spiral (each landing lands
		# at a very different azimuth from its neighbors, not the old ~100
		# deg step that nearly re-aligned every few branches), keeps a
		# treehouse's footprint clear of the ramp climbing past it.
		if i % 3 != 0:
			continue
		var platform_local: Vector3 = platforms[i]
		var world_platform := trunk_pos + platform_local
		_build_treehouse(world_platform, tree_index * 7 + i, trunk_pos)


func _build_treehouse(platform_pos: Vector3, color_seed: int, trunk_pos: Vector3) -> void:
	var roof_color: Color = TownProps.ROOF_COLORS[color_seed % TownProps.ROOF_COLORS.size()]

	var deck := TownProps.build_crate(DECK_SIZE, TownProps.TRIM_WOOD, true)
	deck.position = Vector3(platform_pos.x, platform_pos.y - DECK_SIZE.y, platform_pos.z)
	add_child(deck)

	var house := TownProps.build_building(1, 1, 1, roof_color)
	house.position = Vector3(platform_pos.x, platform_pos.y, platform_pos.z)
	house.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(house)

	_spawn_anchored_villager(platform_pos, trunk_pos)


## A villager planted on the treehouse's own deck rather than roaming --
## per direct instruction to populate the village "on the ground or in the
## houses." Stood toward the deck's OUTER edge (away from the trunk) rather
## than at a random angle from platform_pos -- per direct feedback that a
## stationary villager must never clip into an object like a ramp. Every
## ramp leading up to a landing approaches from the trunk side (see
## build_emergent_tree()'s own outward-branch geometry: a landing's own
## horizontal offset from the trunk IS the ramp's own approach direction),
## and the house built here is centered on platform_pos too (~1.4-unit
## half-width for a 1-cell building) -- standing further out than that,
## toward the deck's own edge (DECK_SIZE's 1.8-unit half-width), clears
## both without needing the ramp's exact per-landing angle.
func _spawn_anchored_villager(platform_pos: Vector3, trunk_pos: Vector3) -> void:
	var villager: JungleVillager = VILLAGER_SCENE.instantiate()
	villager.roams = false
	_assign_villager_identity(villager)
	var outward := Vector3(platform_pos.x - trunk_pos.x, 0.0, platform_pos.z - trunk_pos.z)
	if outward.length() < 0.01:
		outward = Vector3.FORWARD
	outward = outward.normalized()
	villager.position = platform_pos + outward * 1.6
	add_child(villager)


func _build_ground_villagers() -> void:
	for i in GROUND_VILLAGER_COUNT:
		var villager: JungleVillager = VILLAGER_SCENE.instantiate()
		villager.roams = true
		villager.roam_center = Vector2.ZERO
		villager.roam_radius = GROUND_ROAM_RADIUS
		_assign_villager_identity(villager)
		var angle := _rng.randf_range(0.0, TAU)
		var r := GROUND_ROAM_RADIUS * sqrt(_rng.randf())
		var local := Vector2(cos(angle) * r, sin(angle) * r)
		villager.position = Vector3(local.x, _terrain.get_mesh_height(local.x, local.y), local.y)
		add_child(villager)


## Assigns the next unused entry from JUNGLE_VILLAGER_IDENTITIES, in order --
## see that const's own comment for why sequential (not per-instance random)
## assignment is what actually guarantees no two villagers repeat.
func _assign_villager_identity(villager: JungleVillager) -> void:
	var identity: Dictionary = JUNGLE_VILLAGER_IDENTITIES[_next_villager_identity % JUNGLE_VILLAGER_IDENTITIES.size()]
	_next_villager_identity += 1
	villager.display_name = identity["name"]
	var lines: Array[String] = []
	lines.assign(identity["lines"])
	villager.talk_lines = lines
