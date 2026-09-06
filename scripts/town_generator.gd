@tool
extends Node3D

## Assembles a small fixed town entirely from this project's own procedural
## primitives (see town_props.gd's TownProps -- SuperEgg-built walls,
## corners, doors, windows, roofs, the fountain, stalls, fences, lanterns,
## and the windmill/watermill landmarks), not the Kenney Fantasy Town Kit
## GLB assets this used to prototype with -- per direct instruction,
## phasing every one of those borrowed assets out. Ground floors read as
## stone, upper floors as timber; roofs are genuinely pitched gables in a
## vibrant color cycled per building, matching this project's colorful
## palette. Ground floors have a genuine open doorway (only its jambs/
## lintel collide, not the opening itself) so the player can still walk
## inside.
##
## Layout is authored directly in the editor: Buildings/NPCSpots/
## NPCSmallSpots/LanternSpots/Stalls/GemStallSpot below this node are real,
## draggable Marker3D children (building/stall markers carry a couple of
## extra @export fields, see building_marker.gd/stall_marker.gd) -- this
## script only turns them into the actual assembled geometry, into a
## "Generated" child rebuilt from scratch each time so moving a marker
## never leaves stale copies behind. @tool lets that happen live in the
## editor; toggle "Rebuild Now" below after moving/editing a marker to see
## the result (markers don't auto-trigger a rebuild on their own).
##
## "Generated" is deliberately left without an owner -- still renders in the
## editor viewport, but stays out of main.tscn if it gets saved while the
## editor's built it (see terrain_generator.gd, same reasoning).

const NPC_SCENE := "res://scenes/npc.tscn"
# Visual variety for the procedural figure rig (see npc.gd/
# procedural_figure.gd) -- replaces the old per-instance Kenney figurine
# GLB variant picks now that NPCs are built from scratch rather than loaded
# from an imported asset. A modest height spread reads as natural
# person-to-person variation without anyone looking like a different
# species. Skin tones span a genuinely diverse human range, not a narrow
# band of one or two tones with a couple of shade steps.
#
# Every pool below is sized to at least NPC_TOTAL_COUNT entries, each value
# distinct -- per direct report (Mira and Ivy sharing hair style, hair
# color, AND shirt color). Root cause: _assign_figure_variant() consumes
# each pool via `_next_variant_index % pool.size()`, which only avoids
# repeats for one full pass THROUGH the pool -- with 9 total NPCs (2
# NPCSpots + 7 NPCSmallSpots) but some pools sized 6-8, the later NPCs
# wrapped back around and landed on an earlier NPC's exact slot (Ivy was
# NPC #9 here; 8 % 8 == 0 == Mira's own index, for both the 8-entry hair
# and shirt color pools specifically). Sizing every pool to >= 9 unique
# values means one full shuffled pass never needs to wrap at all.
const NPC_TOTAL_COUNT := 9
# Split by gender (5 female / 4 male entries, matching VILLAGER_IDENTITIES'
# own tally) per direct instruction -- max female height stays below max
# male height. A clean gap (female tops out at 0.99, male starts at 1.0)
# rather than just a lower average, so the requirement holds regardless of
# shuffle order, not merely "on average."
const NPC_FEMALE_BODY_SCALES := [0.85, 0.89, 0.93, 0.96, 0.99]
const NPC_MALE_BODY_SCALES := [1.0, 1.05, 1.1, 1.16]
const NPC_SKIN_COLORS := [
	Color(0.99, 0.89, 0.78),
	Color(0.96, 0.82, 0.69),
	Color(0.87, 0.68, 0.52),
	Color(0.76, 0.58, 0.42),
	Color(0.7, 0.5, 0.36),
	Color(0.62, 0.45, 0.32),
	Color(0.47, 0.33, 0.23),
	Color(0.33, 0.22, 0.16),
	Color(0.25, 0.17, 0.12),
]
# Clothing: shirt, pants, and shoes each have their own color per NPC,
# picked independently from skin tone -- see ProceduralFigure.build()'s
# shirt_color/pants_color/shoe_color/sleeve_style params. The palettes are
# pushed toward more saturated, vibrant colors per direct correction -- the
# old ones read as a bit muted/boring, and pants specifically no longer
# default to exclusively dark/neutral tones (a couple of dark/earthy options
# are kept so not everyone is head-to-toe bright, but vibrant pants are now
# just as likely as a vibrant shirt).
const NPC_SHIRT_COLORS := [
	Color(0.85, 0.16, 0.16),
	Color(0.14, 0.55, 0.85),
	Color(0.95, 0.62, 0.08),
	Color(0.18, 0.68, 0.35),
	Color(0.8, 0.22, 0.62),
	Color(0.92, 0.82, 0.12),
	Color(0.4, 0.24, 0.78),
	Color(0.12, 0.7, 0.68),
	Color(0.95, 0.35, 0.55),
]
const NPC_PANTS_COLORS := [
	Color(0.15, 0.15, 0.18),
	Color(0.32, 0.24, 0.16),
	Color(0.78, 0.2, 0.24),
	Color(0.18, 0.42, 0.8),
	Color(0.88, 0.58, 0.1),
	Color(0.24, 0.62, 0.32),
	Color(0.56, 0.28, 0.68),
	Color(0.15, 0.55, 0.5),
	Color(0.55, 0.5, 0.15),
]
const NPC_SHOE_COLORS := [
	Color(0.72, 0.08, 0.06),
	Color(0.08, 0.28, 0.68),
	Color(0.08, 0.48, 0.24),
	Color(0.62, 0.22, 0.58),
	Color(0.82, 0.42, 0.05),
	Color(0.08, 0.56, 0.56),
	Color(0.52, 0.16, 0.08),
	Color(0.22, 0.16, 0.48),
	Color(0.12, 0.38, 0.34),
]
const NPC_SLEEVELESS_CHANCE := 0.35
## Chance an NPC gets ProceduralFigure.SLEEVE_STYLE_SHORT instead of bare
## arms or long sleeves -- checked after NPC_SLEEVELESS_CHANCE in
## _assign_figure_variant()'s single roll, so the three sleeve styles split
## as NPC_SLEEVELESS_CHANCE / NPC_SHORT_SLEEVE_CHANCE / (the remainder) for
## none/short/long respectively, not three independent rolls.
const NPC_SHORT_SLEEVE_CHANCE := 0.35
## Female villagers can use the shared FigureDress garment. The seeded roll
## keeps town generation reproducible and uses their assigned bottom color as
## the dress color instead of generating another unrelated palette choice.
const NPC_DRESS_CHANCE := 0.32
# Body-shape variety (see ProceduralFigure.build()'s chest_build_scale/
# hip_build_scale/abdomen_width_scale params) -- per direct instruction,
# everyone defaulted to the same skinny build.
#
# Chest and hip build scale are split by gender, per direct instruction:
# "only the males should have the big broad chests" (a clean gap -- female
# chest tops out at 1.0, i.e. never broader than the base build; male
# chest starts at 1.02 -- so no female ever reads as broader-chested than
# any male) and "females can also tend to have a bit wider hips" ("tend
# to," not absolute, so this one keeps a realistic overlap: female hips
# average ~1.08, male hips average ~1.0, but both ranges cross in the
# 0.98-1.06 middle). Both pairs sized 5/4 to match VILLAGER_IDENTITIES'
# own female/male tally exactly, same as NPC_FEMALE_BODY_SCALES/
# NPC_MALE_BODY_SCALES above.
const NPC_FEMALE_CHEST_BUILD_SCALES := [0.88, 0.92, 0.95, 0.98, 1.0]
const NPC_MALE_CHEST_BUILD_SCALES := [1.02, 1.07, 1.12, 1.18]
const NPC_FEMALE_HIP_BUILD_SCALES := [1.0, 1.04, 1.08, 1.12, 1.16]
const NPC_MALE_HIP_BUILD_SCALES := [0.94, 0.98, 1.02, 1.06]
# NPC_ABDOMEN_WIDTH_SCALES is deliberately much wider and one-directional
# -- 1.0 (the figure's own base proportions) is the narrow end, never
# scaled down further, only broadened up from there. Not gender-split
# (no direct instruction called for that); stays a single shared 9-value
# pool.
# Scaled back per direct correction -- the old top end (1.6) read as too
# large even before accounting for procedural_figure.gd's own width/back-
# depth cap (see its ABDOMEN_FRONT_OVERHANG_MAX note), and most of that
# range sat well past where the cap kicks in anyway. 1.32 is chosen so the
# authored top of this range lands right at the geometric cap (abdomen
# width flush with chest width) rather than being clamped down hard from a
# much larger nominal value -- kept as the top of this 9-value spread.
const NPC_ABDOMEN_WIDTH_SCALES := [1.0, 1.04, 1.08, 1.12, 1.16, 1.2, 1.24, 1.28, 1.32]

# Hair variety per direct instruction ("mix it up... give them a variety
# of interesting hair colors") -- see figure_hair.gd for what each STYLE_*
# actually builds. A few colors lean toward this project's own vibrant,
# stylized palette (already established for clothing above) rather than
# strictly natural human hair tones, matching the request for "interesting"
# over merely realistic.
const NPC_HAIR_COLORS := [
	Color(0.08, 0.06, 0.05),
	Color(0.32, 0.18, 0.08),
	Color(0.55, 0.32, 0.12),
	Color(0.78, 0.58, 0.22),
	Color(0.85, 0.78, 0.7),
	Color(0.62, 0.18, 0.1),
	Color(0.15, 0.42, 0.5),
	Color(0.45, 0.15, 0.55),
	Color(0.14, 0.22, 0.5),
]
# Used for every non-female NPC (see _assign_figure_variant). Per direct
# instruction, STYLE_LONG is female-only now -- dropped from here, which
# leaves only 3 styles for 4 male villagers (see VILLAGER_IDENTITIES' own
# "female" tally). With more consumers than styles, a repeat is now
# unavoidable by simple pigeonhole, not a bug to design around -- 4
# entries with STYLE_BUZZCUT deliberately doubled (rather than an
# accidental collision from an undersized pool) still guarantees AFRO and
# FLAT_TOP each land on exactly one man, via the same shuffled-pool
# technique as everywhere else in this file.
const NPC_HAIR_STYLES := [
	FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_BUZZCUT,
	FigureHair.STYLE_AFRO, FigureHair.STYLE_FLAT_TOP,
]
# Female NPCs draw from this separate pool instead -- exactly 5 entries,
# one of each style including STYLE_BUN, for exactly 5 female villagers.
# Per direct report (STYLE_BUN not showing up anywhere, then separately
# Mira and Ivy sharing a style): an earlier version rolled STYLE_BUN
# independently per female NPC at a flat 40% chance, which had a real
# (~8%) chance of never triggering across 5 NPCs (and this fixed seed hit
# it); the fix after that used a 6-entry pool with STYLE_BUN duplicated
# to guarantee at least one bun, but a duplicate value in the pool can
# still land on two different female NPCs. Since the female villager count
# (5) happens to exactly match the number of styles (5), one-of-each with
# zero duplicates both guarantees the bun AND guarantees no two women
# share a hairstyle -- strictly better now that the counts line up.
const NPC_FEMALE_HAIR_STYLES := [
	FigureHair.STYLE_BUN, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_AFRO,
	FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_LONG,
]
# Extra length (meters) added on top of FigureHair's own LONG_BASE_DROP,
# per direct instruction ("extending downwards a variable length") -- so
# not every STYLE_LONG NPC ends up the same length.
const NPC_LONG_HAIR_LENGTH_RANGE := Vector2(0.0, 0.15)

# One entry per NPCSpots/NPCSmallSpots marker (5 total) -- each villager
# gets their own name and their own lines, not a shared pool every
# villager drew from at random. That sharing was the actual bug behind
# villagers not reading as independent people (not the figure/rig work
# happening alongside this). "female" gates eligibility for FigureHair.
# STYLE_BUN in _assign_figure_variant() -- see that func's own comment.
const VILLAGER_IDENTITIES := [
	{
		"name": "Mira Holt",
		"female": true,
		"lines": [
			"That fountain's had something glinting at the bottom for weeks now. I'm half convinced it's staring back at me.",
			"I scrub these cobblestones every morning and somehow they're dusty again by noon. No idea where it comes from.",
		],
	},
	{
		"name": "Oswin Cray",
		"female": false,
		"lines": [
			"Elemental energy, elemental blorbs -- bah. In my day a slime was just a slime and it minded its business.",
			"Don't let the gruff put you off. I've got a blorb of my own asleep under the porch right now.",
		],
	},
	{
		"name": "Petra Voss",
		"female": true,
		"lines": [
			"You really don't remember anything? Not even your own name? That's the strangest thing I've heard all month.",
			"I keep waiting for something to actually happen around here. No offense, but you waking up confused was the excitement of the season.",
		],
	},
	{
		"name": "Dorran Fask",
		"female": false,
		"lines": [
			"Spent three summers getting that roofline straight. Still isn't quite even, but nobody's mentioned it since the wedding.",
			"Ask me nothing about elemental gems. Ask me about joinery and we'll be here all afternoon.",
		],
	},
	{
		"name": "Wren Sallow",
		"female": true,
		"lines": [
			"Don't go past the hedges after dark. I'm not going to explain why, I'm just telling you.",
			"The quiet out there isn't the same kind of quiet as in here. You'll know it when you hear it.",
		],
	},
	{
		"name": "Tam Ruskin",
		"female": false,
		"lines": [
			"Grew up thinking an hourglass just told you the day was slipping. Never once thought the sand could just stop.",
			"I've heard three different stories about why the fountain's carvings look the way they do. None of them agree, and none of them are mine to settle.",
		],
	},
	{
		"name": "Halda Prewitt",
		"female": true,
		"lines": [
			"You're new around here, and everyone's already decided you're interesting. Don't let it go to your head.",
			"Ask the dealer about that locket sometime. Watch his face when he can't answer you either.",
		],
	},
	{
		"name": "Cob Ferris",
		"female": false,
		"lines": [
			"Grain doesn't grind itself, and neither does patience, from what I've seen of you standing around.",
			"Some mornings the wind picks up before the sky even changes. My grandmother swore that meant something. I just grind flour.",
		],
	},
	{
		"name": "Ivy Thorne",
		"female": true,
		"lines": [
			"I tried naming every blorb in the square once. Gave up around the ninth. They all look at you the same way.",
			"If you ever get one of those elemental gems, don't waste it on just any blorb. I've heard it changes the whole animal, not just the color.",
		],
	},
]

const GEM_SCENE := "res://scenes/gem.tscn"
# Where each shop's purchasable ShopCatalog entries sit on TownProps' own
# stall counter (local space -- see TownProps.STALL_COUNTER_Y and its
# counter's footprint, x in [-0.6, 0.6], z in [-0.4, 0.4]). Water Gem
# isn't in ANTIQUE_STALL_POSITIONS: it's not purchasable (found free in
# the fountain, see _build_fountain) so _build_one_shop_stall skips it
# automatically.
const ANTIQUE_STALL_POSITIONS := {
	"Fire Gem": Vector3(-0.3, 0.8, 0.0),
	"Electric Gem": Vector3(-0.55, 0.8, -0.15),
	"Corroded Pocket Compass": Vector3(0.0, 0.8, 0.12),
	"Sealed Reliquary Locket": Vector3(0.3, 0.8, -0.08),
	"Cracked Hourglass": Vector3(0.3, 0.8, 0.15),
}
const RED_STALL_POSITIONS := {
	"Notched Shortsword": Vector3(-0.3, 0.8, 0.0),
	"Dented Breastplate": Vector3(0.15, 0.8, 0.1),
	"Pitch Torch": Vector3(0.3, 0.8, -0.15),
}
const GREEN_STALL_POSITIONS := {
	"Rye Loaf": Vector3(-0.3, 0.8, 0.05),
	"Wedge of Cheese": Vector3(0.0, 0.8, -0.1),
	"Dried Berries": Vector3(0.3, 0.8, 0.1),
}

## Toggling this on rebuilds the whole "Generated" subtree from the current
## marker layout -- a plain bool export used as a momentary button rather
## than an @export_tool_button, since that's a newer API this doesn't rely
## on. It always resets itself back off.
@export var rebuild_now: bool = false:
	set(value):
		if value:
			_rebuild()
		rebuild_now = false

@onready var terrain: Node = get_node("../Terrain")

## How often (real ms, matching skeleton_spawner.gd's own CHECK_INTERVAL_MS
## convention) _process() re-checks WorldState.false_hero_should_appear().
## _rebuild() itself only ever runs once per scene load (or from the editor
## rebuild_now toggle) -- the outskirts town is a single persistent area the
## player walks in and out of, not something reloaded per visit, so a
## one-shot check at _ready() would only ever see the party as it existed at
## boot and could never notice Blorbus getting unlocked or the suit filling
## out later in the same session.
const FALSE_HERO_CHECK_INTERVAL_MS := 4000

var town_center: Vector2
var _generated: Node3D
var _next_false_hero_check_ms: int = 0
var _rng := RandomNumberGenerator.new()
var _next_villager_identity: int = 0
## Independently-random picks per attribute (the original approach) collide
## far more often than intuition suggests with only ~6 NPCs drawing from
## 4-6 option pools each -- exactly what produced "half the villagers have
## the same black pants and blue sleeveless shirt." These hold one
## shuffled-once-per-rebuild pass through each pool instead, consumed in
## order, so no combination repeats until every option in that pool has
## actually been used once.
##
## THREE separate counters, not one: attributes shared across every NPC
## regardless of gender (skin/shirt/pants color, abdomen width, hair
## color) consume _next_variant_index, which advances once per NPC
## overall. Gender-specific attributes (body scale, chest/hip build scale,
## hair style) consume _next_female_variant_index or
## _next_male_variant_index instead, which each only advance for NPCs of
## that gender. Using the shared counter for a gender-specific pool was
## itself a real bug caught during this same pass: the 4-entry male hair-
## style pool was being indexed by _next_variant_index % 4, but males only
## occur at overall indices 1/3/5/7 (interleaved with 5 females) -- mod 4
## that's 1/3/1/3, so the 1st and 3rd male NPCs silently collided with
## each other despite the pool having exactly one entry per male. A
## dedicated per-gender counter that only advances for that gender is what
## actually guarantees the "one pass, no repeats" property for a
## gender-specific pool.
var _shuffled_female_body_scales: Array[float] = []
var _shuffled_male_body_scales: Array[float] = []
var _shuffled_skin_colors: Array[Color] = []
var _shuffled_shirt_colors: Array[Color] = []
var _shuffled_pants_colors: Array[Color] = []
var _shuffled_shoe_colors: Array[Color] = []
var _shuffled_female_chest_build_scales: Array[float] = []
var _shuffled_male_chest_build_scales: Array[float] = []
var _shuffled_female_hip_build_scales: Array[float] = []
var _shuffled_male_hip_build_scales: Array[float] = []
var _shuffled_abdomen_width_scales: Array[float] = []
var _shuffled_hair_colors: Array[Color] = []
## Plain Array (not Array[String]) -- assign() below copies from the
## const's own untyped array literal, and there's no need to force a
## typed array just to read it back out by index in _assign_figure_variant.
var _shuffled_hair_styles: Array = []
var _shuffled_female_hair_styles: Array = []
var _next_female_variant_index: int = 0
var _next_male_variant_index: int = 0
var _next_variant_index: int = 0


func _ready() -> void:
	_rebuild()


## Mirrors skeleton_spawner.gd's own throttled _process() re-check rather
## than a per-frame one -- this only ever needs to notice a slow-moving
## state change (the party's own makeup), not react within a frame.
func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _generated == null:
		return
	var now := Time.get_ticks_msec()
	if now < _next_false_hero_check_ms:
		return
	_next_false_hero_check_ms = now + FALSE_HERO_CHECK_INTERVAL_MS
	_build_false_hero(_generated)


func _rebuild() -> void:
	if terrain == null:
		terrain = get_node("../Terrain")
	town_center = terrain.town_center
	position = Vector3(town_center.x, _ground_y(Vector2.ZERO), town_center.y)

	var old := get_node_or_null("Generated")
	if old:
		old.free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	_generated = generated
	_next_false_hero_check_ms = 0

	_rng.seed = 42
	_next_villager_identity = 0
	_next_variant_index = 0
	_next_female_variant_index = 0
	_next_male_variant_index = 0
	_shuffled_female_body_scales.assign(NPC_FEMALE_BODY_SCALES)
	_seeded_shuffle(_shuffled_female_body_scales)
	_shuffled_male_body_scales.assign(NPC_MALE_BODY_SCALES)
	_seeded_shuffle(_shuffled_male_body_scales)
	_shuffled_skin_colors.assign(NPC_SKIN_COLORS)
	_seeded_shuffle(_shuffled_skin_colors)
	_shuffled_shirt_colors.assign(NPC_SHIRT_COLORS)
	_seeded_shuffle(_shuffled_shirt_colors)
	_shuffled_pants_colors.assign(NPC_PANTS_COLORS)
	_seeded_shuffle(_shuffled_pants_colors)
	_shuffled_shoe_colors.assign(NPC_SHOE_COLORS)
	_seeded_shuffle(_shuffled_shoe_colors)
	_shuffled_female_chest_build_scales.assign(NPC_FEMALE_CHEST_BUILD_SCALES)
	_seeded_shuffle(_shuffled_female_chest_build_scales)
	_shuffled_male_chest_build_scales.assign(NPC_MALE_CHEST_BUILD_SCALES)
	_seeded_shuffle(_shuffled_male_chest_build_scales)
	_shuffled_female_hip_build_scales.assign(NPC_FEMALE_HIP_BUILD_SCALES)
	_seeded_shuffle(_shuffled_female_hip_build_scales)
	_shuffled_male_hip_build_scales.assign(NPC_MALE_HIP_BUILD_SCALES)
	_seeded_shuffle(_shuffled_male_hip_build_scales)
	_shuffled_abdomen_width_scales.assign(NPC_ABDOMEN_WIDTH_SCALES)
	_seeded_shuffle(_shuffled_abdomen_width_scales)
	_shuffled_hair_colors.assign(NPC_HAIR_COLORS)
	_seeded_shuffle(_shuffled_hair_colors)
	_shuffled_hair_styles.assign(NPC_HAIR_STYLES)
	_seeded_shuffle(_shuffled_hair_styles)
	_shuffled_female_hair_styles.assign(NPC_FEMALE_HAIR_STYLES)
	_seeded_shuffle(_shuffled_female_hair_styles)

	if has_node("Buildings"):
		var building_index := 0
		for marker in $Buildings.get_children():
			_build_building(generated, marker, building_index)
			building_index += 1

	_build_plaza(generated)
	_build_landmarks(generated)
	_scatter_decorations(generated)
	_scatter_platforming(generated)
	_spawn_npcs(generated)


func _spawn_npcs(parent: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	if has_node("NPCSpots"):
		_spawn_npc_group(parent, $NPCSpots)
	if has_node("NPCSmallSpots"):
		_spawn_npc_group(parent, $NPCSmallSpots)
	_spawn_yogi.call_deferred()
	_build_false_hero(parent)


## False Hero only ever appears once WorldState.false_hero_should_appear()
## is true (see that function's own doc comment: Blorbus awakened AND
## enough in-party blorbs to fill a real suit) and he hasn't already been
## defeated -- before that, or after, this is simply a no-op and villagers
## keep their own ordinary, unrelated dialogue, per direct instruction.
## Rebuilt fresh into `generated` each _rebuild() (unlike Yogi's own
## create-once placement) specifically so this gate is re-checked every
## time the outskirts scene reloads, in case the party's own makeup
## changed in the meantime.
func _build_false_hero(parent: Node3D) -> void:
	if not has_node("FalseHeroSpot"):
		return
	if not get_tree().get_nodes_in_group("false_hero").is_empty():
		return
	if not WorldState.false_hero_should_appear(get_tree()):
		return
	var spot: Node3D = get_node("FalseHeroSpot")
	var packed: PackedScene = load("res://scenes/false_hero_nme.tscn")
	if packed == null:
		push_warning("Missing False Hero scene: res://scenes/false_hero_nme.tscn")
		return
	var false_hero = packed.instantiate()
	false_hero.set_terrain_reference(terrain)
	var offset := Vector2(spot.position.x, spot.position.z)
	false_hero.position = Vector3(offset.x, _ground_y(offset), offset.y)
	parent.add_child(false_hero)
	# Every facing/movement write in false_hero_nme.gd targets its own
	# `visuals` child directly (world-space atan2 math, matching player.gd/
	# npc.gd's own convention of a never-rotated root) -- rotating the ROOT
	# from the marker instead (the original approach here) silently added a
	# second, compounding rotation on top of that world-space math, which is
	# exactly what made him walk backwards. `visuals` only resolves once
	# _ready() has run, so this has to happen after add_child(), not before.
	false_hero.visuals.rotation.y = spot.rotation.y


## Yogi lives in the first town now rather than appearing beside the player
## at startup. She is parented beside Town under Main because the reusable
## cat controller resolves Main's Terrain and Player as siblings; her roam
## center is seeded at the quiet west edge of the plaza before _ready().
func _spawn_yogi() -> void:
	var world := get_parent()
	if world == null or world.has_node("Yogi"):
		return
	var packed := load("res://scenes/cat_template_preview.tscn") as PackedScene
	if packed == null:
		push_warning("Missing Yogi scene: res://scenes/cat_template_preview.tscn")
		return
	var yogi := packed.instantiate() as CatTemplatePreview
	yogi.name = "Yogi"
	yogi.is_yogi = true
	var local_offset := Vector2(-12.0, 8.0)
	var world_xz := town_center + local_offset
	yogi.position = Vector3(
		world_xz.x, terrain.get_mesh_height(world_xz.x, world_xz.y), world_xz.y
	)
	world.add_child(yogi)


func _spawn_npc_group(parent: Node3D, spots: Node3D) -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		push_warning("Missing NPC scene: " + NPC_SCENE)
		return
	for marker in spots.get_children():
		var offset := Vector2(marker.position.x, marker.position.z)
		var inst: Node3D = packed.instantiate()
		inst.set_terrain_reference(terrain)
		# Identity (sets is_female) has to run before the figure variant --
		# _assign_figure_variant()'s own hair-style pick reads is_female to
		# decide STYLE_BUN eligibility.
		_assign_villager_identity(inst)
		_assign_figure_variant(inst)
		inst.position = Vector3(offset.x, _ground_y(offset), offset.y)
		parent.add_child(inst)


## Reads sequentially from the shuffled-once-per-rebuild pools (see the
## var declarations above) rather than drawing each attribute independently
## at random -- with only ~6 NPCs total, independent random picks from
## 4-6 option pools collide far more than intuition suggests, which is
## what produced "half the villagers have the same black pants and blue
## sleeveless shirt." Each attribute still cycles independently (a body
## scale repeating doesn't imply a shirt color repeats too), just without
## repeating *within* its own pool until every option in it has been used.
func _assign_figure_variant(npc_inst: Node3D) -> void:
	npc_inst.skin_color = _shuffled_skin_colors[_next_variant_index % _shuffled_skin_colors.size()]
	npc_inst.shirt_color = _shuffled_shirt_colors[_next_variant_index % _shuffled_shirt_colors.size()]
	npc_inst.pants_color = _shuffled_pants_colors[_next_variant_index % _shuffled_pants_colors.size()]
	npc_inst.shoe_color = _shuffled_shoe_colors[_next_variant_index % _shuffled_shoe_colors.size()]
	npc_inst.abdomen_width_scale = _shuffled_abdomen_width_scales[_next_variant_index % _shuffled_abdomen_width_scales.size()]
	var sleeve_roll := _rng.randf()
	if sleeve_roll < NPC_SLEEVELESS_CHANCE:
		npc_inst.sleeve_style = ProceduralFigure.SLEEVE_STYLE_NONE
	elif sleeve_roll < NPC_SLEEVELESS_CHANCE + NPC_SHORT_SLEEVE_CHANCE:
		npc_inst.sleeve_style = ProceduralFigure.SLEEVE_STYLE_SHORT
	else:
		npc_inst.sleeve_style = ProceduralFigure.SLEEVE_STYLE_LONG
	npc_inst.hair_color = _shuffled_hair_colors[_next_variant_index % _shuffled_hair_colors.size()]

	# Gender-specific attributes (height, chest/hip build, hair style) draw
	# from their own per-gender pool at their own per-gender cadence (see
	# this file's own var-declaration comment for why a shared counter
	# can't correctly index a gender-specific pool -- that exact bug was
	# caught and fixed here).
	var style: String
	if npc_inst.is_female:
		npc_inst.wears_dress = _rng.randf() < NPC_DRESS_CHANCE
		npc_inst.dress_color = npc_inst.pants_color
		npc_inst.body_scale = _shuffled_female_body_scales[_next_female_variant_index % _shuffled_female_body_scales.size()]
		npc_inst.chest_build_scale = _shuffled_female_chest_build_scales[_next_female_variant_index % _shuffled_female_chest_build_scales.size()]
		npc_inst.hip_build_scale = _shuffled_female_hip_build_scales[_next_female_variant_index % _shuffled_female_hip_build_scales.size()]
		style = _shuffled_female_hair_styles[_next_female_variant_index % _shuffled_female_hair_styles.size()]
		_next_female_variant_index += 1
	else:
		npc_inst.body_scale = _shuffled_male_body_scales[_next_male_variant_index % _shuffled_male_body_scales.size()]
		npc_inst.chest_build_scale = _shuffled_male_chest_build_scales[_next_male_variant_index % _shuffled_male_chest_build_scales.size()]
		npc_inst.hip_build_scale = _shuffled_male_hip_build_scales[_next_male_variant_index % _shuffled_male_hip_build_scales.size()]
		style = _shuffled_hair_styles[_next_male_variant_index % _shuffled_hair_styles.size()]
		_next_male_variant_index += 1
	npc_inst.hair_style = style
	if style == FigureHair.STYLE_LONG:
		npc_inst.hair_length_variance = _rng.randf_range(
			NPC_LONG_HAIR_LENGTH_RANGE.x, NPC_LONG_HAIR_LENGTH_RANGE.y
		)
	_next_variant_index += 1


## Fisher-Yates shuffle using this generator's own seeded _rng (not Array's
## built-in shuffle(), which draws from the engine's global random state
## and would make town layout non-reproducible across rebuilds -- _rng.seed
## is fixed to 42 at the top of _rebuild() specifically so it isn't).
func _seeded_shuffle(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp


## Assigns the next unused entry from VILLAGER_IDENTITIES, in order (not
## randomly) -- with exactly as many identities as there are NPCSpots/
## NPCSmallSpots markers, sequential assignment guarantees no two
## villagers end up sharing a name or lines, which random per-instance
## picking wouldn't. Wraps via modulo only as a safety net if a future
## marker count ever exceeds the identity list.
func _assign_villager_identity(npc_inst: Node3D) -> void:
	var identity: Dictionary = VILLAGER_IDENTITIES[_next_villager_identity % VILLAGER_IDENTITIES.size()]
	_next_villager_identity += 1
	npc_inst.display_name = identity["name"]
	npc_inst.is_female = identity["female"]
	# identity["lines"] is a plain untyped Array (Dictionary values can't be
	# declared Array[String] in a literal), but npc.gd's talk_lines is --
	# assigning the untyped array directly fails at runtime ("Invalid
	# assignment... value of type 'Array'"). assign() copies elements into
	# a properly-typed array instead of a raw reference swap.
	var lines: Array[String] = []
	lines.assign(identity["lines"])
	npc_inst.talk_lines = lines


func _ground_y(local_offset: Vector2) -> float:
	var world_pos := town_center + local_offset
	# get_mesh_height(), not get_height() -- matches the exact rendered/
	# collision surface (see terrain_generator.gd's get_mesh_height() doc
	# comment). Mostly moot inside the flat town zone (both agree exactly
	# on flat ground), but keeps anything placed near its outer edge
	# consistent with everything else that now calls this instead.
	return terrain.get_mesh_height(world_pos.x, world_pos.y)


# ---------------------------------------------------------------------------
# Buildings
# ---------------------------------------------------------------------------


func _build_building(parent: Node3D, marker: Node3D, building_index: int) -> void:
	var offset := Vector2(marker.position.x, marker.position.z)
	var size: Vector2 = marker.size
	var floors: int = marker.floors
	var w := int(size.x)
	var d := int(size.y)
	var roof_color: Color = TownProps.ROOF_COLORS[building_index % TownProps.ROOF_COLORS.size()]

	var building := TownProps.build_building(w, d, floors, roof_color)
	building.position = Vector3(offset.x, _ground_y(offset), offset.y)
	building.rotation.y = marker.rotation.y
	parent.add_child(building)


# ---------------------------------------------------------------------------
# Plaza, decorations, NPCs
# ---------------------------------------------------------------------------


func _build_plaza(parent: Node3D) -> void:
	# A single flat slab plus one path per building, replacing the old
	# stretched "road" GLB slabs with TownProps' own flat paving -- far
	# cheaper than tiling, and the paths double as visible routes to each
	# building. Corners overlap slightly where paths cross; negligible at
	# this scale.
	var plaza_y := _ground_y(Vector2.ZERO) + 0.01
	var plaza_size := 22.0
	var plaza := TownProps.build_flat_slab(Vector2(plaza_size, plaza_size))
	plaza.position = Vector3(0, plaza_y, 0)
	parent.add_child(plaza)

	if has_node("Buildings"):
		for marker in $Buildings.get_children():
			var offset := Vector2(marker.position.x, marker.position.z)
			var mid := offset * 0.5
			var length := offset.length() * 0.6
			var angle := offset.angle()
			var path := TownProps.build_flat_slab(Vector2(3.2, length))
			path.position = Vector3(mid.x, plaza_y, mid.y)
			path.rotation.y = -angle + PI * 0.5
			parent.add_child(path)

	_build_fountain(parent)


func _build_fountain(parent: Node3D) -> void:
	var fountain := TownProps.build_fountain()
	var fountain_body: StaticBody3D = fountain["root"]
	fountain_body.position = Vector3(0, _ground_y(Vector2.ZERO), 0)
	parent.add_child(fountain_body)

	# Resting in the water itself, not floating above it -- TownProps.
	# build_fountain() places gem_y a little below its own water surface
	# (water_y) so the gem reads as submerged, visible through the
	# translucent water, rather than floating loose on top of it (or, per
	# the previous bug, sitting well below ground and invisible entirely).
	_place_gem(fountain_body, Vector3(0, fountain["gem_y"], 0), Color(0.2, 0.55, 1.0), "Water Gem", true, true)


## Larger set-piece landmarks (windmill, watermill) -- placed like the
## fountain (a single prop, collision already baked in by TownProps)
## rather than assembled per-cell like a building, since they're each one
## big module, not a wall/roof kit.
func _build_landmarks(parent: Node3D) -> void:
	if has_node("Windmill"):
		var marker: Node3D = $Windmill
		var offset := Vector2(marker.position.x, marker.position.z)
		var mill := TownProps.build_windmill()
		mill.position = Vector3(offset.x, _ground_y(offset), offset.y)
		mill.rotation.y = marker.rotation.y
		parent.add_child(mill)
	if has_node("Watermill"):
		var marker: Node3D = $Watermill
		var offset := Vector2(marker.position.x, marker.position.z)
		var mill := TownProps.build_watermill()
		mill.position = Vector3(offset.x, _ground_y(offset), offset.y)
		mill.rotation.y = marker.rotation.y
		parent.add_child(mill)


func _scatter_decorations(parent: Node3D) -> void:
	if has_node("LanternSpots"):
		for marker in $LanternSpots.get_children():
			var offset := Vector2(marker.position.x, marker.position.z)
			var lantern := TownProps.build_lantern()
			lantern.position = Vector3(offset.x, _ground_y(offset), offset.y)
			lantern.rotation.y = marker.rotation.y
			parent.add_child(lantern)

	# Vendor stalls ringing the plaza -- stall_marker.gd's stall_scene field
	# is now vestigial (it named a specific Kenney GLB variant); canopy
	# color is cycled from TownProps.ROOF_COLORS by marker index instead, for
	# the same kind of stall-to-stall variety the old scene-name picks gave.
	# The gem stall is built separately below since it needs items and a
	# vendor.
	if has_node("Stalls"):
		var stall_index := 0
		for marker in $Stalls.get_children():
			var offset := Vector2(marker.position.x, marker.position.z)
			var canopy_color: Color = TownProps.ROOF_COLORS[stall_index % TownProps.ROOF_COLORS.size()]
			var stall: Dictionary = TownProps.build_stall(canopy_color)
			var stall_body: StaticBody3D = stall["body"]
			stall_body.position = Vector3(offset.x, _ground_y(offset), offset.y)
			stall_body.rotation.y = marker.rotation.y
			parent.add_child(stall_body)
			stall_index += 1

	# Fence runs marking out a couple of yards/plot edges -- plain Marker3D
	# children (no custom @export fields needed, same pattern as
	# LanternSpots), rotation.y picks which edge the run faces.
	if has_node("FenceSpots"):
		for marker in $FenceSpots.get_children():
			var offset := Vector2(marker.position.x, marker.position.z)
			var fence := TownProps.build_fence_segment()
			fence.position = Vector3(offset.x, _ground_y(offset), offset.y)
			fence.rotation.y = marker.rotation.y
			parent.add_child(fence)

	_build_shop_stall(parent)


# ---------------------------------------------------------------------------
# Platforming
# ---------------------------------------------------------------------------

const PLATFORM_CLUSTER_COUNT := 8
const PLATFORM_MIN_RADIUS := 14.0
const PLATFORM_MAX_RADIUS := 46.0
# Minimum distance from any hand-placed Town marker (building, stall, fence
# run, lantern, NPC spot) and from any other platforming cluster already
# placed -- rejection-sampled rather than hand-picked, so this keeps
# working if the town layout above it ever changes (see this file's own
# doc comment on markers being the real, draggable layout). 10.0, not
# something tighter, because it's measured from a building marker's
# center: the widest buildings (size.x up to 6 cells * CELL_SIZE 2.8m)
# have a half-width around 8.4m, and building markers can face any
# rotation, so anything much under that risks a cluster clipping into a
# rotated building's actual footprint even though it cleared the marker
# point itself.
const PLATFORM_CLEARANCE := 10.0
const PLATFORM_SPACING := 11.0

# The real ceiling on how much a single step can rise and still be
# reachable by an ordinary standing jump -- player.gd's jump reaches height
# v^2 / (2*g*s), v = jump_velocity (11.3), g = ProjectSettings' physics/3d/
# default_gravity (9.8, unmodified in this project), s = player.gd's own
# JUMP_GRAVITY_SCALE (4.8): 11.3^2 / (2*9.8*4.8) =~ 1.36m. Capped noticeably
# below that absolute theoretical ceiling, not right up against it, since
# reaching it at all requires landing at the exact peak of the arc -- real
# input isn't frame-perfect, and covering a step's own horizontal gap in the
# same jump leaves less room for that timing to land short. Per direct
# correction that an earlier 1.0-1.6 range let some steps land above even
# the theoretical ceiling (unreachable no matter how a jump is timed).
const MAX_STEP_RISE := 1.2

# One dedicated, much taller staircase (see _build_sky_stairs()) rather than
# another entry in the small scattered clusters above -- placed further out
# so its base has room to clear both the town markers and every ordinary
# cluster.
const SKY_STAIRS_MIN_RADIUS := 55.0
const SKY_STAIRS_MAX_RADIUS := 85.0
const SKY_STAIRS_CLEARANCE := 8.0
# Fixed per-step turn (not random drift) -- over the ~45-50 steps needed to
# reach cloud altitude, unbounded random drift would wander the tower far
# from its own base; a constant turn instead winds it into a tight spiral
# (see _build_sky_stairs()'s own comment for the resulting radius).
const SKY_STAIRS_TURN := 0.35
# How far below CloudScatter's own altitude_min the crate spiral stops,
# handing off to build_sky_course()'s puff-based continuation -- enough
# clearance that the last crate doesn't visually poke through the ambient
# cloud layer's own lowest puffs.
const SKY_STAIRS_CLOUD_MARGIN := 6.0
# Same grass tone terrain_generator.gd's own ground uses (its "grass" var in
# _height_color()) -- per direct instruction to cap each step in green grass,
# matching the rest of the world's grass rather than inventing a new shade.
const SKY_STAIRS_GRASS_COLOR := Color(0.07451, 0.63922, 0.40392)
const SKY_STAIRS_GRASS_MOUND_HEIGHT := 0.3


## Scatters small parkour clusters -- crate staircases -- around the open
## ground between buildings, and (separately, see _build_roof_ramps())
## attaches a ramp to each two-story building's own eave. Purely optional
## climbing, not required to reach anything. Uses its own
## RandomNumberGenerator rather than this script's shared _rng (seeded
## once in _rebuild() and consumed in a fixed order by the NPC variant
## shuffles below) -- sharing it would shift every draw after this call,
## silently changing which hair/skin/outfit combination each NPC gets.
func _scatter_platforming(parent: Node3D) -> void:
	var occupied: Array[Vector2] = []
	for group_name in ["Buildings", "Stalls", "FenceSpots", "LanternSpots", "NPCSpots", "NPCSmallSpots"]:
		if has_node(group_name):
			for marker in get_node(group_name).get_children():
				occupied.append(Vector2(marker.position.x, marker.position.z))
	for single_name in ["Windmill", "Watermill", "GemStallSpot", "RedShopSpot", "GreenShopSpot", "FalseHeroSpot"]:
		if has_node(single_name):
			var marker: Node3D = get_node(single_name)
			occupied.append(Vector2(marker.position.x, marker.position.z))

	var rng := RandomNumberGenerator.new()
	rng.seed = 5150

	_build_roof_ramps(parent, occupied, rng)

	var placed: Array[Vector2] = []
	var attempts := 0
	while placed.size() < PLATFORM_CLUSTER_COUNT and attempts < PLATFORM_CLUSTER_COUNT * 40:
		attempts += 1
		var angle := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(PLATFORM_MIN_RADIUS, PLATFORM_MAX_RADIUS)
		var candidate := Vector2(cos(angle), sin(angle)) * r
		if not _far_enough(candidate, occupied, PLATFORM_CLEARANCE):
			continue
		if not _far_enough(candidate, placed, PLATFORM_SPACING):
			continue
		placed.append(candidate)
		_build_crate_stack_cluster(parent, candidate, rng, occupied)

	_build_sky_stairs(parent, occupied, placed, rng)


func _far_enough(candidate: Vector2, points: Array[Vector2], min_dist: float) -> bool:
	for p in points:
		if candidate.distance_to(p) < min_dist:
			return false
	return true


## A ramp climbing straight up to the eave of every two-story building's
## roof (the roof itself is already landable, see TownProps._build_roof_
## panel()'s own doc comment) -- replaces an earlier version that scattered
## ramps at random independent of the town layout, per direct correction
## that they should relate to the two-story houses specifically instead.
##
## Tries the building's north eave first, then south, skipping it
## entirely if neither has room -- rather than risk a ~12m ramp clipping
## through a neighboring building/stall that happened to be close on both
## sides. East/west aren't tried: those are the roof's gable ends (where
## it rises straight to the ridge with no low eave shelf to land on), not
## a landing a ramp could actually reach.
func _build_roof_ramps(parent: Node3D, occupied: Array[Vector2], rng: RandomNumberGenerator) -> void:
	if not has_node("Buildings"):
		return
	for marker in $Buildings.get_children():
		var floors: int = marker.floors
		if floors != 2:
			continue
		var offset := Vector2(marker.position.x, marker.position.z)
		# occupied includes this building's own marker point -- excluded
		# here since the ramp is *supposed* to sit right next to it; only
		# other buildings/stalls/etc. should be able to block the ramp.
		var others: Array[Vector2] = []
		for p in occupied:
			if p.distance_to(offset) > 0.01:
				others.append(p)

		var size: Vector2 = marker.size
		var rise := float(floors) * TownProps.FLOOR_HEIGHT
		var run := rise * rng.randf_range(2.1, 2.5)
		var width := rng.randf_range(2.6, 3.2)
		var half_depth := size.y * TownProps.CELL_SIZE * 0.5 + TownProps.ROOF_OVERHANG

		for north in [true, false]:
			# The ramp's own local origin is its ground-level bottom (see
			# build_ramp()'s doc comment) -- placed one full ramp-run
			# beyond the eave, on whichever side is being tried, so its
			# far end (local z = run) lands exactly on that eave.
			var z_sign := 1.0 if north else -1.0
			var bottom_local := Vector2(0.0, z_sign * (half_depth + run))
			var bottom_offset := _rotate_building_offset(bottom_local, marker.rotation.y)
			var bottom_world_offset := offset + bottom_offset
			if not _far_enough(bottom_world_offset, others, PLATFORM_CLEARANCE):
				continue

			var ramp := TownProps.build_ramp(width, run, rise, TownProps.ROAD_COLOR)
			ramp.position = Vector3(
				bottom_world_offset.x, _ground_y(bottom_world_offset), bottom_world_offset.y
			)
			# North's eave sits behind (building-local -z from) the ramp's
			# own bottom, so its local +Z -- the "up the slope" direction --
			# needs to point the opposite way from the building's own local
			# +Z, hence + PI on top of the building's own yaw. South is the
			# mirror: the eave already sits in the direction the bottom-to-
			# building vector points, so no extra flip is needed. (Checked
			# against the unrotated case by hand: north's ramp-top then
			# lands at world (offset.x, floor_top_y, offset.y + half_depth)
			# -- exactly the building's own north eave.)
			ramp.rotation.y = marker.rotation.y + (PI if north else 0.0)
			parent.add_child(ramp)
			break


## Matches build_building()'s own derived Y-rotation formula (see its
## wall-placement comment): x' = cos*x + sin*z, z' = -sin*x + cos*z. Used
## to turn a building-local (x, z) offset into the Town-local offset it
## ends up at once the building's own marker.rotation.y is applied.
func _rotate_building_offset(local: Vector2, yaw: float) -> Vector2:
	var c := cos(yaw)
	var s := sin(yaw)
	return Vector2(c * local.x + s * local.y, -s * local.x + c * local.y)


## A zigzagging sequence of freestanding crates climbing away from the
## ground -- pure jump-to-jump parkour, no ramp, so (unlike
## _build_roof_ramps()'s ramps) this one's player-only. Each step rises at
## most MAX_STEP_RISE (see that constant's own comment for the real jump-
## height derivation this is capped against) and each gap is at most 2.6m.
##
## occupied is re-checked per step (not just once for the cluster's own
## center) -- up to 5 steps of drift at 2.6m each can wander over 10m away
## from a center point that itself cleared PLATFORM_CLEARANCE, which is
## enough to walk back into a building a straight-line check wouldn't have
## caught.
func _build_crate_stack_cluster(
	parent: Node3D, center: Vector2, rng: RandomNumberGenerator, occupied: Array[Vector2]
) -> void:
	var step_count := rng.randi_range(3, 5)
	var base_y := _ground_y(center)
	var pos := center
	var heading := rng.randf_range(0.0, TAU)
	var height := 0.0

	for i in step_count:
		var step_height := rng.randf_range(0.9, MAX_STEP_RISE)
		var gap := rng.randf_range(1.8, 2.6)
		heading += rng.randf_range(-0.6, 0.6)
		var next_pos := pos + Vector2(sin(heading), cos(heading)) * gap
		if not _far_enough(next_pos, occupied, PLATFORM_CLEARANCE):
			break
		pos = next_pos
		height += step_height

		var size := Vector3(rng.randf_range(1.6, 2.4), rng.randf_range(0.4, 0.6), rng.randf_range(1.6, 2.4))
		var crate := TownProps.build_crate(size, TownProps.TRIM_WOOD)
		crate.position = Vector3(pos.x, base_y + height, pos.y)
		crate.rotation.y = rng.randf_range(0.0, TAU)
		parent.add_child(crate)


## One dedicated, much taller version of the crate staircase above -- climbs
## from the ground all the way up into CloudScatter's own ambient layer, then
## hands off to that script's build_sky_course() for a hand-placed run of
## walkable cloud puffs finishing on one landing puff holding the Air Gem.
## Per direct instruction: "the kind of floaty stairs areas around the
## town... make those be parkour all the way up to the clouds, making sure
## the clouds above are a nice parkour course too, and have an air gem be up
## there."
##
## Same per-step rise/gap range _build_crate_stack_cluster() already uses
## (capped at MAX_STEP_RISE, see that constant's own comment) -- only the
## step COUNT differs, since this climbs roughly 15x the vertical distance.
## A constant per-step turn (SKY_STAIRS_TURN), not random drift, winds the
## ~55-65 steps that now takes into a tight spiral instead of a kilometers-
## long wandering line: turning `SKY_STAIRS_TURN` radians every ~2.2m-gap
## step traces a helix of radius roughly
## gap / (2*sin(turn/2)) =~ 2.2 / (2*sin(0.175)) =~ 6m, small enough to read
## as one coherent tower rather than sprawling across the field.
func _build_sky_stairs(
	parent: Node3D, occupied: Array[Vector2], placed: Array[Vector2], rng: RandomNumberGenerator
) -> void:
	var clouds := get_node_or_null("../Clouds") as CloudScatter
	if clouds == null:
		return

	var anchor := Vector2.INF
	for attempt in 60:
		var angle := rng.randf_range(0.0, TAU)
		var r := rng.randf_range(SKY_STAIRS_MIN_RADIUS, SKY_STAIRS_MAX_RADIUS)
		var candidate := Vector2(cos(angle), sin(angle)) * r
		if _far_enough(candidate, occupied, SKY_STAIRS_CLEARANCE) and _far_enough(candidate, placed, SKY_STAIRS_CLEARANCE):
			anchor = candidate
			break
	if anchor == Vector2.INF:
		return

	var pos := Vector3(town_center.x + anchor.x, _ground_y(anchor), town_center.y + anchor.y)
	var heading := rng.randf_range(0.0, TAU)
	var target_y := clouds.altitude_min - SKY_STAIRS_CLOUD_MARGIN
	var crate_colors: Array[Color] = [TownProps.TRIM_WOOD, TownProps.WALL_WOOD, Color(0.52, 0.4, 0.24)]
	var step_index := 0
	# The safety cap only guards against a future altitude_min/margin change
	# making this loop unreasonably long -- at the established rise range it
	# never comes close in practice (~55-65 steps to reach a typical ~65m
	# climb).
	while pos.y < target_y and step_index < 200:
		var rise := rng.randf_range(0.9, MAX_STEP_RISE)
		var gap := rng.randf_range(1.8, 2.6)
		heading += SKY_STAIRS_TURN + rng.randf_range(-0.05, 0.05)
		pos += Vector3(sin(heading) * gap, rise, cos(heading) * gap)
		var size := Vector3(rng.randf_range(1.8, 2.4), rng.randf_range(0.4, 0.55), rng.randf_range(1.8, 2.4))
		var crate := TownProps.build_crate(size, crate_colors[step_index % crate_colors.size()])
		crate.rotation.y = rng.randf_range(0.0, TAU)
		parent.add_child(crate)
		crate.global_position = pos
		# A grass mound on top of every step, per direct instruction. Per
		# direct correction, an earlier flat slab merely balanced on top read
		# as "perched on the convex top... not smoothly emerging," and had no
		# collision of its own, so the player visibly sank into it (its
		# collision stayed at the bare crate's own height, well below the
		# slab's own visible top). This version is its own small SuperEgg
		# mound (a rounded top, not a flat disc) sunk partway INTO the
		# crate's own top volume -- the same overlap-a-flat-seam trick this
		# project's joints already use (see e.g. NECK_OVERLAP in procedural_
		# figure.gd) -- so it reads as emerging from the crate regardless of
		# exactly how the crate's own "flat" superellipsoid top curves,
		# rather than needing to match that curvature exactly. A matching
		# second collision box, stacked on top of build_crate()'s own,
		# extends solid ground up to the mound's real visible top.
		var mound_half_extent := Vector3(size.x * 0.4, SKY_STAIRS_GRASS_MOUND_HEIGHT * 0.5, size.z * 0.4)
		var mound_embed := mound_half_extent.y * 0.7
		var mound_center_y := size.y - mound_embed + mound_half_extent.y
		var grass_mound := SuperEgg.build_part(
			mound_half_extent, SKY_STAIRS_GRASS_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
		)
		grass_mound.position = Vector3(0, mound_center_y, 0)
		crate.add_child(grass_mound)
		# Same center and full height as the mound mesh itself -- covers
		# exactly its own visible span, from its embedded base up to its
		# real peak.
		var mound_collision := CollisionShape3D.new()
		var mound_shape := BoxShape3D.new()
		mound_shape.size = Vector3(mound_half_extent.x * 1.6, mound_half_extent.y * 2.0, mound_half_extent.z * 1.6)
		mound_collision.shape = mound_shape
		mound_collision.position = Vector3(0, mound_center_y, 0)
		crate.add_child(mound_collision)
		step_index += 1

	clouds.build_sky_course(pos)


## One dedicated Marker3D per functional shop (see main.tscn's
## GemStallSpot/RedShopSpot/GreenShopSpot) -- each stall gets its own
## canopy color, pulls its purchasable items from ShopCatalog by "shop"
## category, and spawns its own fixed-look vendor with its own flavor
## lines. Built as a local var (not a top-level const) since several
## fields -- TownProps.ROOF_COLORS[n], FigureHair.STYLE_* -- aren't
## compile-time constant expressions GDScript would accept in a const.
func _build_shop_stall(parent: Node3D) -> void:
	var shop_configs: Array[Dictionary] = [
		{
			"marker": "GemStallSpot",
			"canopy_color": TownProps.ROOF_COLORS[0],
			"category": "antique",
			"item_positions": ANTIQUE_STALL_POSITIONS,
			"vendor_name": "Antique Dealer",
			"vendor_lines": [
				"Welcome, welcome. Everything in here's older than it looks. Myself included.",
				"That fire gem isn't cheap, but it's the real thing. Whatever's cheap on gems around here usually isn't.",
				"The compass hasn't pointed north once since I've owned it. Stopped trying to fix it years ago.",
				"Don't ask me to open the locket. Believe me, I've tried.",
			],
			"vendor_skin": Color(0.7, 0.5, 0.36),
			"vendor_shirt": Color(0.32, 0.24, 0.16),
			"vendor_hair": Color(0.85, 0.78, 0.7),
			"vendor_hair_style": FigureHair.STYLE_BUZZCUT,
		},
		{
			"marker": "RedShopSpot",
			"canopy_color": TownProps.ROOF_COLORS[0],
			"category": "red",
			"item_positions": RED_STALL_POSITIONS,
			"vendor_name": "Armorer",
			"vendor_lines": [
				"Everything here's been swung, worn, or both. Doesn't mean it won't hold.",
				"Take the torch if nothing else. Whatever's out past the fields won't like the light.",
				"That breastplate's already got a dent in it. Previous owner would call that a good sign, if they could.",
			],
			"vendor_skin": Color(0.62, 0.44, 0.3),
			"vendor_shirt": Color(0.3, 0.13, 0.11),
			"vendor_hair": Color(0.15, 0.13, 0.1),
			"vendor_hair_style": FigureHair.STYLE_FLAT_TOP,
		},
		{
			"marker": "GreenShopSpot",
			"canopy_color": TownProps.ROOF_COLORS[1],
			"category": "green",
			"item_positions": GREEN_STALL_POSITIONS,
			"vendor_name": "Provisioner",
			"vendor_lines": [
				"Stock up before you head out. Nothing worse than an empty pack halfway to the canyon.",
				"Cheese keeps. Everything else, eat it before it decides not to.",
				"They're dried, not fresh. Fresh doesn't survive a trip in anyone's pocket.",
			],
			"vendor_skin": Color(0.75, 0.55, 0.4),
			"vendor_shirt": Color(0.2, 0.4, 0.22),
			"vendor_hair": Color(0.4, 0.24, 0.1),
			"vendor_hair_style": FigureHair.STYLE_BUN,
		},
	]
	for config in shop_configs:
		_build_one_shop_stall(parent, config)


func _build_one_shop_stall(parent: Node3D, config: Dictionary) -> void:
	var marker_name: String = config["marker"]
	if not has_node(marker_name):
		return
	var spot_marker: Node3D = get_node(marker_name)
	var offset := Vector2(spot_marker.position.x, spot_marker.position.z)
	var stall: Dictionary = TownProps.build_stall(config["canopy_color"])
	var stall_body: StaticBody3D = stall["body"]
	stall_body.position = Vector3(offset.x, _ground_y(offset), offset.y)
	stall_body.rotation.y = spot_marker.rotation.y
	parent.add_child(stall_body)

	# item_positions sit on TownProps' own stall counter -- placed as the
	# stall body's own children so the items inherit its position/
	# rotation rather than needing to be re-derived in world space. Pure
	# scenery now -- no per-item Interactable/purchase logic (see
	# shop_item.gd, retired). All buying routes through the vendor's
	# "Browse Wares" dialog action into ShopUI, reading the same
	# ShopCatalog this loop does, filtered to this stall's own category.
	var item_positions: Dictionary = config["item_positions"]
	for item in ShopCatalog.get_items_for_shop(config["category"]):
		if not item.get("purchasable", false):
			continue
		var local_pos: Vector3 = item_positions.get(item["name"], Vector3(0, TownProps.STALL_COUNTER_Y + 0.05, 0))
		var visual: Node3D = item["build_visual"].call(1.0)
		visual.position = local_pos
		stall_body.add_child(visual)

	# Vendor stands beside the stall (not on the counter), a bit further
	# out from the plaza along the same direction as the stall, facing
	# back in toward the plaza.
	var vendor_offset := offset + Vector2(0.9, 0.0).rotated(spot_marker.rotation.y)
	var to_center := -vendor_offset.normalized()
	if Engine.is_editor_hint():
		return
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		push_warning("Missing NPC scene: " + NPC_SCENE)
		return
	var vendor = packed.instantiate()
	vendor.set_terrain_reference(terrain)
	# Hand-set, not _assign_figure_variant() -- that function draws from
	# the shuffled pools sized exactly for the 9 named VILLAGER_IDENTITIES
	# (5 female / 4 male), guaranteeing no two of THEM repeat. Routing the
	# vendor through it too would make it a hidden 10th consumer of the
	# same counters, silently colliding with whichever villager it landed
	# on (caught while tracing through this exact system for the gender
	# body-proportion split -- the vendor was landing on the same male
	# pool slot as Cob). The vendor is a single, singular character, not
	# part of the "no two look alike" wandering-villager population, so it
	# doesn't need the shared-pool machinery at all -- just its own
	# reasonable, fixed look.
	vendor.skin_color = config["vendor_skin"]
	vendor.shirt_color = config["vendor_shirt"]
	vendor.hair_color = config["vendor_hair"]
	vendor.hair_style = config["vendor_hair_style"]
	vendor.stationary = true
	vendor.is_vendor = true
	vendor.display_name = config["vendor_name"]
	# config["vendor_lines"] is a plain untyped Array (Dictionary values
	# can't be declared Array[String] in a literal), but npc.gd's
	# vendor_lines is -- assign() copies elements into a properly-typed
	# array instead of a raw reference swap (see _assign_villager_identity
	# above for the same pattern, and the runtime error it avoids).
	var lines: Array[String] = []
	lines.assign(config["vendor_lines"])
	vendor.vendor_lines = lines
	vendor.shop_category = config["category"]
	vendor.facing_degrees = rad_to_deg(atan2(to_center.x, to_center.y))
	vendor.position = Vector3(vendor_offset.x, _ground_y(vendor_offset), vendor_offset.y)
	parent.add_child(vendor)


func _place_gem(
	parent: Node3D,
	local_pos: Vector3,
	color: Color,
	gem_name: String = "",
	collectible: bool = false,
	floats: bool = false
) -> void:
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
