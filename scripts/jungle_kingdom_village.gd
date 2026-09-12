extends Node3D

## The primate kingdom's first village (see kingdom_bootstrap.gd) -- a
## handful of NatureProps.build_emergent_tree() giants near the spawn point,
## each with small treehouses mounted on alternating branch-ramp landings,
## spaced vertically up and down the trunk, per direct instruction. Kept
## inside jungle_kingdom_foliage.gd's own CLEAR_RADIUS (24.0 around the
## origin) so ordinary canopy trees never clip through these.
##
## Per direct correction ("populate the primate kingdom's village... using a
## variety of the monkeys, apes, and stuffed animal monkeys types") -- the
## treehouse/ground population above was entirely JungleVillager (the
## "stuffed animal monkey" class); _build_ground_primates() below adds a
## further, smaller set of named ApeTemplatePreview instances (both apes,
## has_tail=false, and "primate template" monkeys, has_tail=true -- see
## docs/world_bible.md's own Primate taxonomy note for why these are
## distinct species from JungleVillager's own) roaming the same ground
## clearing, so all three of this project's primate classes are actually
## represented here. Also spawns Manchego and the quest-giving ape seen
## riding him -- see _build_manchego_and_quest_ape()'s own doc comment.

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
## Cut from 5 -- per direct report ("the primate kingdom is extremely laggy
## and takes forever to load... we don't need so many primates to be walking
## around on the village floor at once"). Combined with the same report's
## own spacing ask, GROUND_ROAM_RADIUS below is also widened so the (now
## fewer) roamers still cover a comparable-or-larger area instead of just
## bunching up more tightly in the old footprint.
const GROUND_VILLAGER_COUNT := 3
const GROUND_ROAM_RADIUS := 32.0

const APE_TEMPLATE_SCENE := "res://scenes/ape_template_preview.tscn"
## One entry per ApeTemplatePreview NPC _build_ground_primates() spawns --
## same "own name and own lines, not a shared pool" reasoning
## JUNGLE_VILLAGER_IDENTITIES' own comment gives, kept as its own separate
## roster (not merged into that one) since these are a different species
## with a different rig/scale, spawned by a separate function below.
## has_tail=true is ApeTemplate's own "primate template" monkey variant, NOT
## JungleVillager's stuffed-animal-monkey class -- see this file's own class
## doc comment.
const PRIMATE_TEMPLATE_IDENTITIES := [
	{
		"name": "Torvin Oakjaw",
		"has_tail": false,
		"lines": [
			"The training dummies out past the clearing used to get more use. Whoever's running that business isn't telling anyone how.",
			"Elders say a curse doesn't care how careful you are. I try not to think about it before breakfast.",
		],
	},
	{
		"name": "Maddox Cindertusk",
		"has_tail": false,
		"lines": [
			"Kova Kong's out past the tree line, if you're brave enough to go looking. Hard to miss him, honestly.",
			"I keep my distance from the big one. Doesn't seem to mind either way.",
		],
	},
	{
		"name": "Perrin Vale",
		"has_tail": false,
		"lines": [
			"Xiao Hou Zi used to pass through here before he took up with travelers. Good company, when he sat still.",
			"You get used to the size difference after a while. Mostly.",
		],
	},
	{
		"name": "Wick Thistledown",
		"has_tail": true,
		"lines": [
			"The canopy villagers look down on us, and I mean that literally -- they're all up in the trees.",
			"Something's coming for this world, the vines say. I've stopped asking which vines.",
		],
	},
	{
		"name": "Fable Quickpaw",
		"has_tail": true,
		"lines": [
			"That ape on the horse showed up a few days back. Hasn't said much to the rest of us.",
			"I like the ground just fine. Let the tree-folk have the view.",
		],
	},
	{
		"name": "Doran Mossback",
		"has_tail": true,
		"lines": [
			"Watch where you step near the old roots. They trip up more outsiders than the ramps do.",
			"We don't get many visitors down here on the clearing floor. Fewer still who stick around to talk.",
		],
	},
]
## Same display_scale ranges main.gd's own now-removed debug spawn used to
## pick from at random -- see that file's git history for the full
## APE_DEBUG_SCALE_MIN/MAX and PRIMATE_TEMPLATE_MONKEY_SCALE_MIN/MAX doc
## comments this reproduces, just per-species now rather than per-parity-of-
## index.
const APE_SCALE_MIN := 0.85
const APE_SCALE_MAX := 1.25
const PRIMATE_TEMPLATE_MONKEY_SCALE_MIN := 0.5
const PRIMATE_TEMPLATE_MONKEY_SCALE_MAX := 0.7
## How many of PRIMATE_TEMPLATE_IDENTITIES' own 6 entries actually get
## spawned -- see _build_ground_primates()'s own comment.
const GROUND_PRIMATE_SPAWN_COUNT := 3

const MANCHEGO_SCENE := "res://scenes/manchego.tscn"
## Where the player first sees Manchego and the quest ape -- close enough to
## the village's own spawn/clearing to be seen on arrival (per direct
## instruction, "when entering the primate village, we will see Manchego
## there idling around"), off to one side of the three treehouse giants
## rather than under any of them. First-draft placement, adjustable on
## report.
const MANCHEGO_LOCAL_XZ := Vector2(6.0, -4.0)
## Per direct instruction: "ridden by one ape who is a reddish color."
const QUEST_APE_NAME := "Ossian Redbrow"
const QUEST_APE_FUR_COLOR := Color(0.62, 0.22, 0.14)
## Flavor lines shown every time, regardless of quest progress -- the actual
## quest state (whether the "Give the Special Banana" action appears) is
## handled by _quest_ape_dialog_actions() instead, appended on top by
## ApeTemplatePreview's own dialog_actions_provider hook. Kept deliberately
## generic/placeholder, per direct instruction ("I don't know what the quest
## will be... for now placeholder").
const QUEST_APE_TALK_LINES := [
	"Bring me something special from the top of Kova Kong's head, out past the clearing, and Manchego's yours to ride.",
	"Manchego's a good horse, but he's not going anywhere until I've got what I asked for.",
]
## Must match primate_kingdom_gorilla.gd's own Fruit.fruit_name exactly --
## that's the Inventory item name this quest checks for.
const SPECIAL_BANANA_ITEM_NAME := "Special Banana"

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

## Placement for the abandoned Wood Kingdom reveal -- see
## _build_wood_kingdom_area()'s own doc comment. Well clear of the village
## clearing (r=32 around the origin), Manchego/the quest ape (~(6,-4)), and
## Kova Kong's own roam disk (primate_kingdom_gorilla.gd's GORILLA_LOCAL_XZ
## (400,-280), r=42) -- confirmed via that file's own constants that he has
## no quest state of his own, so this area is safe to place anywhere else in
## the kingdom.
const WOOD_AREA_CENTER := Vector2(-250.0, -300.0)
const WOOD_AREA_RADIUS := 34.0
const WOOD_TREE_LOCAL_OFFSETS := [
	Vector2(-14.0, 10.0),
	Vector2(12.0, 16.0),
	Vector2(6.0, -14.0),
	Vector2(-16.0, -8.0),
]
const WOOD_TREE_HEIGHT_MIN := 32.0
const WOOD_TREE_HEIGHT_MAX := 40.0
## Dull, greyed cedar-brown -- desaturated relative to TownProps.TRIM_WOOD/
## NatureProps' own live-tree palette, so the same tree/treehouse geometry
## reads as long-abandoned rather than as an ordinary occupied home.
const WOOD_WEATHERED_TINT := Color(0.42, 0.36, 0.3)
const WOOD_BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const WOOD_BLORB_COUNT := 8

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
	# Deferred, unlike the two calls above -- these two add their spawned
	# nodes to get_parent() (the kingdom root), not to `self` (see each
	# function's own doc comment for why). Calling that add_child() straight
	# from _ready() crashed hard on arrival ("Parent node is busy setting up
	# children... Condition data.blocked > 0"): the kingdom root is still
	# mid-setup, iterating its OWN children's _ready() calls (this node,
	# "JungleVillage," is one of them) at the exact moment this runs, and
	# Godot locks a node against add_child() for the duration of that
	# cascade. _build_ground_villagers()/_build_tree_and_houses() above never
	# hit this because they add_child() onto `self`, not onto a node that's
	# itself still being set up. Deferring runs these once that whole initial
	# cascade has finished, the same fix the engine's own error message
	# suggests.
	_build_ground_primates.call_deferred()
	_build_manchego_and_quest_ape.call_deferred()
	if WorldState.ice_kingdom_visited:
		_build_wood_kingdom_area.call_deferred()


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
		# treehouse's footprint clear of the ramp climbing past it. Widened
		# to every FOURTH landing (was third) per direct report ("[space
		# primates out] in the treehouses too" -- part of the same lag/load-
		# time report GROUND_VILLAGER_COUNT's own comment addresses) -- fewer
		# treehouses (and so fewer anchored villagers, since
		# _build_treehouse() spawns one per call) spaced further apart
		# vertically, and each tree's own emergent-spiral azimuth step means
		# further apart around the trunk too.
		if i % 4 != 0:
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


## One ApeTemplatePreview NPC per PRIMATE_TEMPLATE_IDENTITIES entry, roaming
## the same ground clearing _build_ground_villagers() uses -- see this file's
## own class doc comment for why this exists alongside that function rather
## than replacing it. Added via get_parent().add_child(), NOT add_child()
## (unlike every JungleVillager spawn above) -- ApeTemplatePreview's own
## _ready() resolves terrain through a plain get_node_or_null("../Terrain"),
## which only finds it one level under the kingdom root; parented here under
## "JungleVillage" instead, that lookup would silently return null and this
## NPC would never re-settle its own Y as it wanders the clearing's
## undulating ground. See primate_kingdom_gorilla.gd's own identical
## reasoning for its gorilla spawn. Called deferred from _ready() (see that
## function's own comment) -- get_parent().add_child() below would otherwise
## crash on arrival, since the kingdom root is still mid-setup at that point.
func _build_ground_primates() -> void:
	var packed := load(APE_TEMPLATE_SCENE) as PackedScene
	if packed == null:
		return
	var parent := get_parent()
	# Spawns only the first GROUND_PRIMATE_SPAWN_COUNT of PRIMATE_TEMPLATE_
	# IDENTITIES, not the full roster -- per direct report ("we don't need so
	# many primates to be walking around on the village floor at once"). The
	# roster itself stays at its full 6 entries (the written names/dialogue
	# are still worth keeping around for whenever population is raised again
	# later); only how many actually get spawned is cut.
	for i in mini(GROUND_PRIMATE_SPAWN_COUNT, PRIMATE_TEMPLATE_IDENTITIES.size()):
		var identity: Dictionary = PRIMATE_TEMPLATE_IDENTITIES[i]
		var preview := packed.instantiate() as ApeTemplatePreview
		preview.has_tail = identity["has_tail"]
		var lines: Array[String] = []
		lines.assign(identity["lines"])
		preview.display_name = identity["name"]
		preview.talk_lines = lines
		# Same "dark charcoal to grey to light grey to shades of brown" range
		# jungle_villager.gd's own FUR_COLORS already establishes for this
		# project's primates generally -- reused directly rather than
		# duplicated, so a new palette doesn't have to be kept in sync by hand.
		preview.fur_color = JungleVillager.FUR_COLORS[_rng.randi() % JungleVillager.FUR_COLORS.size()]
		preview.marking_color = MonkeyFigure.MARKING_COLOR_PALETTE[
			_rng.randi() % MonkeyFigure.MARKING_COLOR_PALETTE.size()
		]
		if identity["has_tail"]:
			preview.display_scale = _rng.randf_range(
				PRIMATE_TEMPLATE_MONKEY_SCALE_MIN, PRIMATE_TEMPLATE_MONKEY_SCALE_MAX
			)
		else:
			preview.display_scale = _rng.randf_range(APE_SCALE_MIN, APE_SCALE_MAX)
		var angle := _rng.randf_range(0.0, TAU)
		var r := GROUND_ROAM_RADIUS * sqrt(_rng.randf())
		var local := Vector2(cos(angle) * r, sin(angle) * r)
		var spawn_pos := Vector3(local.x, _terrain.get_mesh_height(local.x, local.y), local.y)
		parent.add_child(preview)
		preview.global_position = spawn_pos


## Manchego and the ape seen riding him -- per direct instruction: "when
## entering the primate village, we will see Manchego there idling around,
## not following the player, and being ridden by one ape who is a reddish
## color, and that ape will give you the prompt to do a quest." Both added
## via get_parent().add_child() -- Manchego's own _ready() does a HARD
## get_node("../Player")/get_node("../Terrain") (not the soft get_node_or_
## null ApeTemplatePreview uses), which would throw outright if he ended up
## nested one level too deep under "JungleVillage" instead of directly under
## the kingdom root alongside Player/Terrain. Called deferred from _ready()
## (see that function's own comment) -- get_parent().add_child() below would
## otherwise crash on arrival, since the kingdom root is still mid-setup at
## that point.
func _build_manchego_and_quest_ape() -> void:
	if WorldState.manchego_joined:
		return
	var packed_manchego := load(MANCHEGO_SCENE) as PackedScene
	var packed_ape := load(APE_TEMPLATE_SCENE) as PackedScene
	if packed_manchego == null or packed_ape == null:
		return
	var parent := get_parent()

	var manchego := packed_manchego.instantiate() as Manchego
	# Idling in place, not chasing the player, and not yet rideable -- both
	# flip true once the ape below hands him over. See both vars' own doc
	# comments in manchego.gd.
	manchego.follows_player = false
	manchego.available_to_player = false
	parent.add_child(manchego)
	var manchego_pos := Vector3(MANCHEGO_LOCAL_XZ.x, 0, MANCHEGO_LOCAL_XZ.y)
	manchego_pos.y = _terrain.get_mesh_height(manchego_pos.x, manchego_pos.y)
	manchego.global_position = manchego_pos

	var ape := packed_ape.instantiate() as ApeTemplatePreview
	ape.fur_color = QUEST_APE_FUR_COLOR
	ape.has_tail = false
	ape.display_name = QUEST_APE_NAME
	var talk_lines: Array[String] = []
	talk_lines.assign(QUEST_APE_TALK_LINES)
	ape.talk_lines = talk_lines
	# Matches the player's own established riding-pose lean, same reasoning
	# main.gd's own now-removed debug mount review used (see this file's own
	# git history) -- an ape seated on Manchego for real, not just facing
	# forward on foot, needs the same forward torso intent baked in before
	# ApeTemplate.build() runs.
	ape.spine_forward_bend = Player.RIDE_SPINE_LEAN
	ape.arm_forward_relax_factor = 0.0
	ape.dialog_actions_provider = func() -> Array[Dictionary]:
		return _quest_ape_dialog_actions(ape, manchego)
	parent.add_child(ape)
	ape.mount_on(manchego)


## Returns the "Give the Special Banana" DialogUI action (see npc.gd's own
## {"label", "callback"} shape) only once the player actually has the item --
## otherwise no extra action at all, just QUEST_APE_TALK_LINES' own flavor
## line. Handing it over removes the item, unmounts the ape (see
## ApeTemplatePreview.unmount()'s own doc comment -- he becomes an ordinary
## roaming NPC afterward rather than vanishing), and hands Manchego to the
## player as a real party mount.
func _quest_ape_dialog_actions(ape: ApeTemplatePreview, manchego: Manchego) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if not Inventory.has(SPECIAL_BANANA_ITEM_NAME):
		return actions
	actions.append({
		"label": "Give %s the Special Banana." % ape.display_name,
		"callback": func() -> void:
			Inventory.remove(SPECIAL_BANANA_ITEM_NAME)
			DialogUI.hide_dialog()
			ape.unmount()
			manchego.follows_player = true
			manchego.set_available_to_player(true)
			WorldState.manchego_joined = true
			Hud.show_message("%s hops down. Manchego is yours now." % ape.display_name),
	})
	return actions


## The abandoned Wood Kingdom reveal -- per direct instruction, "once you go
## to the ice kingdom, when you go back to the plant kingdom, you're able to
## find an abandoned plant kingdom now called the wood kingdom where you can
## find wood [blorbs]." Gated on WorldState.ice_kingdom_visited (set once by
## ice_kingdom_terrain.gd's own _ready()) -- the first WorldState-gated
## kingdom generator in the project; every kingdom scene otherwise rebuilds
## identically from scratch on every visit. Reuses NatureProps.
## build_emergent_tree()'s own live-treehouse geometry (the same shape
## _build_tree_and_houses() above uses for the ordinary village), recolored
## via the same recursive-mesh-retint technique ice_kingdom_terrain.gd's own
## _tint_meshes_recursive() established this session, so the "abandoned"
## read comes from palette alone rather than needing new geometry of its
## own. No anchored villagers on these decks -- abandoned means empty.
## Called deferred from _ready() for the same reason every other
## get_parent().add_child() call in this file is.
func _build_wood_kingdom_area() -> void:
	var parent := get_parent()
	for offset in WOOD_TREE_LOCAL_OFFSETS:
		var local_pos: Vector2 = WOOD_AREA_CENTER + (offset as Vector2)
		var height := _rng.randf_range(WOOD_TREE_HEIGHT_MIN, WOOD_TREE_HEIGHT_MAX)
		var base_y: float = _terrain.get_mesh_height(local_pos.x, local_pos.y)
		var result := NatureProps.build_emergent_tree(height, _rng)
		var tree_body: StaticBody3D = result["body"]
		_tint_meshes_recursive(tree_body, WOOD_WEATHERED_TINT)
		var trunk_pos := Vector3(local_pos.x, base_y, local_pos.y)
		tree_body.position = trunk_pos
		parent.add_child(tree_body)

		var platforms: Array = result["platform_positions"]
		if platforms.is_empty():
			continue
		var platform_local: Vector3 = platforms[0]
		var platform_pos := trunk_pos + platform_local
		var deck := TownProps.build_crate(DECK_SIZE, TownProps.TRIM_WOOD, true)
		deck.position = Vector3(platform_pos.x, platform_pos.y - DECK_SIZE.y, platform_pos.z)
		_tint_meshes_recursive(deck, WOOD_WEATHERED_TINT)
		parent.add_child(deck)
		var house := TownProps.build_building(1, 1, 1, WOOD_WEATHERED_TINT)
		house.position = platform_pos
		house.rotation.y = _rng.randf_range(0.0, TAU)
		_tint_meshes_recursive(house, WOOD_WEATHERED_TINT)
		parent.add_child(house)

	for i in WOOD_BLORB_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := WOOD_AREA_RADIUS * sqrt(_rng.randf())
		var local := WOOD_AREA_CENTER + Vector2(cos(angle) * r, sin(angle) * r)
		var inst: Blorb = WOOD_BLORB_SCENE.instantiate()
		inst.in_party = false
		inst.initial_element = "wood"
		inst.position = Vector3(local.x, _terrain.get_mesh_height(local.x, local.y), local.y)
		parent.add_child(inst)


## Shared recursive mesh-retint helper -- NatureProps.build_emergent_tree()'s
## own trunk tiers/canopy lobes/branch ramps are nested several levels deep
## through per-tier/per-lobe Node3D wrappers, not direct MeshInstance3D
## children, so a shallow get_children() loop would silently miss most of
## them (the same bug ice_kingdom_terrain.gd's own identical helper was
## written to avoid -- see that file's own comment for the full story).
func _tint_meshes_recursive(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var material := StandardMaterial3D.new()
		material.albedo_color = tint
		(node as MeshInstance3D).set_surface_override_material(0, material)
	for child in node.get_children():
		_tint_meshes_recursive(child, tint)


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
