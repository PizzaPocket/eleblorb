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
## The layout is authored in one data file, OhioPlan (scripts/ohio_plan.gd):
## buildings, ways, yards, stalls, lamps and the water. This script only turns
## that plan into geometry, into a "Generated" child rebuilt from scratch each
## time; tools/validate_village.gd checks what was built against the same data.
## @tool lets that happen live in the editor; toggle "Rebuild Now" below after
## editing the plan to see the result.
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
# repeats for one full pass THROUGH the pool. Ohio now has twelve named
# residents including its three young people, so every shared appearance
# pool carries at least twelve distinct values.
const NPC_TOTAL_COUNT := 12
# Six women and six men, with child-specific scales applied from their identity
# after these adult-diversity pools are assigned.
const NPC_FEMALE_BODY_SCALES := [0.84, 0.87, 0.90, 0.93, 0.96, 0.99]
const NPC_MALE_BODY_SCALES := [0.97, 1.0, 1.04, 1.08, 1.12, 1.16]
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
	Color(0.92, 0.74, 0.58),
	Color(0.56, 0.38, 0.27),
	Color(0.39, 0.27, 0.19),
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
	Color(0.26, 0.64, 0.74),
	Color(0.68, 0.34, 0.16),
	Color(0.36, 0.62, 0.18),
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
	Color(0.31, 0.36, 0.72),
	Color(0.67, 0.31, 0.44),
	Color(0.28, 0.48, 0.18),
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
	Color(0.44, 0.24, 0.12),
	Color(0.18, 0.34, 0.54),
	Color(0.50, 0.16, 0.30),
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
const NPC_FEMALE_CHEST_BUILD_SCALES := [0.86, 0.89, 0.92, 0.95, 0.98, 1.0]
const NPC_MALE_CHEST_BUILD_SCALES := [1.01, 1.04, 1.07, 1.10, 1.14, 1.18]
const NPC_FEMALE_HIP_BUILD_SCALES := [0.98, 1.0, 1.04, 1.08, 1.12, 1.16]
const NPC_MALE_HIP_BUILD_SCALES := [0.92, 0.95, 0.98, 1.01, 1.04, 1.07]
# NPC_ABDOMEN_WIDTH_SCALES is deliberately much wider and one-directional
# -- 1.0 (the figure's own base proportions) is the narrow end, never
# scaled down further, only broadened up from there. Not gender-split
# (no direct instruction called for that); stays a single shared 12-value
# pool.
# Scaled back per direct correction -- the old top end (1.6) read as too
# large even before accounting for procedural_figure.gd's own width/back-
# depth cap (see its ABDOMEN_FRONT_OVERHANG_MAX note), and most of that
# range sat well past where the cap kicks in anyway. 1.32 is chosen so the
# authored top of this range lands right at the geometric cap (abdomen
# width flush with chest width) rather than being clamped down hard from a
# much larger nominal value.
const NPC_ABDOMEN_WIDTH_SCALES := [0.94, 0.98, 1.0, 1.04, 1.08, 1.12, 1.16, 1.2, 1.23, 1.26, 1.29, 1.32]

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
	Color(0.24, 0.12, 0.06),
	Color(0.68, 0.42, 0.16),
	Color(0.10, 0.30, 0.26),
]
# Used for every non-female resident (see _assign_figure_variant). STYLE_LONG
# remains female-only; this six-slot pool provides an authored assignment for
# each of Ohio's men and boys.
const NPC_HAIR_STYLES := [
	FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_AFRO, FigureHair.STYLE_FLAT_TOP,
	FigureHair.STYLE_BALD, FigureHair.STYLE_HERO, FigureHair.STYLE_BUZZCUT,
]
# Female residents draw from this separate six-entry pool, including every
# shared style once. This guarantees a bun without repeating a style.
const NPC_FEMALE_HAIR_STYLES := [
	FigureHair.STYLE_BUN, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_AFRO,
	FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_LONG, FigureHair.STYLE_PONYTAIL,
]
# Extra length (meters) added on top of FigureHair's own LONG_BASE_DROP,
# per direct instruction ("extending downwards a variable length") -- so
# not every STYLE_LONG NPC ends up the same length.
const NPC_LONG_HAIR_LENGTH_RANGE := Vector2(0.0, 0.15)

# One entry for every named Ohio resident. Mira is built with the inn; the
# remaining eleven are spawned at their authored work or home anchors. Each
# gets a distinct voice rather than drawing from a shared pool. "body_scale"
# is reserved for young residents and overrides the adult diversity pass.
const VILLAGER_IDENTITIES := [
	{
		"name": "Mira Holt",
		"female": true,
		"lines": [
			"If you need a room, ask before I bank the fire. I won't wake the whole house for late feet.",
			"Nell says visitors remember her bread. They remember the bed they ate it in.",
		],
	},
	{
		"name": "Oswin Cray",
		"female": false,
		"lines": [
			"I don't own the blorb under my porch. It sleeps there when it pleases and leaves without saying goodbye. Sensible creature.",
			"Ivy can tell you what color means what. I can tell you which hedge will survive winter.",
		],
	},
	{
		"name": "Petra Voss",
		"female": true,
		"lines": [
			"Morning is lessons. Afternoon is Halda's records. If history becomes interesting, I hope it waits until I have fresh ink.",
			"You remember nothing, and everyone else has already improved the story. I'm writing down only what you tell me.",
		],
	},
	{
		"name": "Dorran Fask",
		"female": false,
		"lines": [
			"Pip marked the same board twice today. Good eye, poor chalk discipline.",
			"Halda says the roof is straight. That is how I know she loves me.",
		],
	},
	{
		"name": "Wren Sallow",
		"female": true,
		"lines": [
			"The west path went quiet before dawn. No birds, no field mice. I'll walk it again at dusk.",
			"Tam eats at mine on Thursday. He brings opinions about walls; I put herbs in his stew.",
		],
	},
	{
		"name": "Tam Ruskin",
		"female": false,
		"lines": [
			"Stone tells you where the water has been. Stories tell you where people wish it had been.",
			"The fountain can keep its secrets. My job is to keep it from leaking.",
		],
	},
	{
		"name": "Halda Prewitt",
		"female": true,
		"lines": [
			"Brinna wants the east pitch wider. Aldren wants hers narrower. This is why markets need records.",
			"If Aldren says an object is unique, ask whether he means in Ohio or on his table.",
		],
	},
	{
		"name": "Cob Ferris",
		"female": false,
		"lines": [
			"The wind turned before breakfast. My grandmother would have canceled grinding. I merely delayed it until after breakfast.",
			"Wick can lift half a sack and insists on carrying the whole thing. I admire the arithmetic.",
		],
	},
	{
		"name": "Ivy Thorne",
		"female": true,
		"lines": [
			"That one by the fountain blinks twice before it moves. Wick says I imagined it. Wick is wrong.",
			"Oswin calls my notes guesses. He is correct, which is not the same as being helpful.",
		],
	},
	{
		"name": "Pip",
		"female": false,
		"body_scale": 0.76,
		"lines": [
			"Dorran lets me measure twice. If I get two answers, he makes me measure a third time.",
			"The sawmill loft is loud in daylight. At night you can hear the race under the floor.",
		],
	},
	{
		"name": "Tess",
		"female": true,
		"body_scale": 0.70,
		"lines": [
			"Nell gave me six loaves and said not to run. She knows Petra rings the lesson bell early.",
			"I can carry bread or copy sums. Bread gets fewer red marks.",
		],
	},
	{
		"name": "Wick",
		"female": false,
		"body_scale": 0.80,
		"lines": [
			"Cob says a sack is too heavy when it bends your back. Mine only bends my knees.",
			"Ivy writes down every blorb. I remember the important ones.",
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
	"Notched Shortsword": Vector3(-0.88, 1.10, 0.0),
	"Dented Breastplate": Vector3(0.0, 1.24, 0.04),
	"Pitch Torch": Vector3(0.88, 1.08, -0.04),
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
## Sampled aqueduct centreline (Town-local), kept for the scatter exclusions.
var _course: Array[Vector2] = []
var _generated: Node3D
## What was actually built, in Town-local plan coordinates, for the layout
## validator (tools/validate_village.gd): oriented solids, doors, gates, things
## that face somewhere, and the worn-ground strokes and blobs.
var _layout_solids: Array[Dictionary] = []
var _layout_doors: Array[Dictionary] = []
var _layout_gates: Array[Dictionary] = []
var _layout_facing: Array[Dictionary] = []
var _layout_lanterns: Array[Dictionary] = []
var _layout_strokes: Array[Dictionary] = []
var _layout_blobs: Array[Dictionary] = []
var _smoke_rng := RandomNumberGenerator.new()
var _smoke_puffs: Array[ChimneySmoke.Puff] = []
var _water_wheel_visuals: Array[Node3D] = []
var _sawmill_drives: Array[Dictionary] = []
var _mill_animation_time := 0.0
var _next_false_hero_check_ms: int = 0
var _rng := RandomNumberGenerator.new()
var _next_villager_identity: int = 0
## Independently-random picks per attribute (the original approach) collide
## far more often than intuition suggests with a small cast drawing from
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
## used to occur at alternating overall indices, so a shared modulo counter
## silently collided despite the pool having one entry per resident. A
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
	LoadingScreen.enqueue_build_stage("Placing world objects…",0.79,_rebuild)


## Mirrors skeleton_spawner.gd's own throttled _process() re-check rather
## than a per-frame one -- this only ever needs to notice a slow-moving
## state change (the party's own makeup), not react within a frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _generated == null:
		return
	ChimneySmoke.animate(_smoke_puffs, delta, _smoke_rng)
	_mill_animation_time += delta
	for wheel_visual in _water_wheel_visuals:
		if is_instance_valid(wheel_visual):
			# An undershot wheel: the race flows east, the axle runs north-south and
			# local +X is world +Z, so a positive turn about it carries the blades
			# in the water (the bottom of the wheel) east, with the current.
			wheel_visual.rotation.x = _mill_animation_time * 0.62
	for drive in _sawmill_drives:
		_animate_sawmill_drive(drive)
	var now := Time.get_ticks_msec()
	if now < _next_false_hero_check_ms:
		return
	_next_false_hero_check_ms = now + FALSE_HERO_CHECK_INTERVAL_MS
	_build_false_hero(_generated)


## Everything the validator needs, as plain data.
func layout_report() -> Dictionary:
	return {
		"solids": _layout_solids, "doors": _layout_doors, "gates": _layout_gates,
		"facing": _layout_facing, "lanterns": _layout_lanterns, "strokes": _layout_strokes, "blobs": _layout_blobs,
		"course": _course, "bridge": (_plan.get("bridge", Vector2.ZERO) as Vector2),
	}


## Local plan point for a point given in a building's own frame.
func _plan_point(center: Vector2, yaw: float, local: Vector2) -> Vector2:
	return center + Vector2(
		local.x * cos(yaw) + local.y * sin(yaw), -local.x * sin(yaw) + local.y * cos(yaw)
	)


func _plan_direction(yaw: float, local: Vector2) -> Vector2:
	return Vector2(local.x * cos(yaw) + local.y * sin(yaw), -local.x * sin(yaw) + local.y * cos(yaw))


func _record_solid(label: String, kind: String, center: Vector2, half: Vector2, yaw: float) -> void:
	_layout_solids.append({"name": label, "kind": kind, "center": center, "half": half, "yaw": yaw})


func _record_door(
	label: String, center: Vector2, yaw: float, local_pos: Vector2, local_dir: Vector2, width: float, kind: String = "door"
) -> void:
	_layout_doors.append({
		"name": label, "kind": kind, "width": width,
		"pos": _plan_point(center, yaw, local_pos), "dir": _plan_direction(yaw, local_dir),
	})


## The one way a freestanding lantern is placed. Its lit bracket (local -Z)
## always turns toward `serves`, the point on the road, green or terrace it
## lights, and the pair is recorded so the validator can confirm it.
func _place_street_lantern(parent: Node3D, label: String, at: Vector2, serves: Vector2, surface: Callable) -> void:
	var lantern := TownProps.build_ohio_street_lantern()
	lantern.position = Vector3(at.x,float(surface.call(at)),at.y)
	lantern.rotation.y = VillageWorks.yaw_facing(at,serves)
	parent.add_child(lantern)
	_record_solid(label,"yard_prop",at,Vector2(0.32,0.32),lantern.rotation.y)
	_layout_lanterns.append({"name":label,"pos":at,"yaw":lantern.rotation.y,"serves":serves})


func _record_facing(label: String, kind: String, at: Vector2, yaw: float, local_dir: Vector2) -> void:
	_layout_facing.append({"name": label, "kind": kind, "pos": at, "dir": _plan_direction(yaw, local_dir)})


## Doors and bays of a panel building: the front by entry style, plus a back door.
func _record_building_doors(label: String, center: Vector2, yaw: float, w: int, d: int, floors: int, entry: String, back_x: float) -> void:
	var width := float(w) * TownProps.CELL_SIZE
	var depth := float(d) * TownProps.CELL_SIZE
	for opening in TownProps.panel_wall_openings("south", width, 0, floors, entry, back_x):
		if str(opening["kind"]) in ["door", "bay"]:
			_record_door(label, center, yaw, Vector2(float(opening["center"]), -depth * 0.5), Vector2(0, -1), float(opening["width"]), str(opening["kind"]))
	if back_x != TownProps.NO_BACK_DOOR:
		_record_door(label + " (back)", center, yaw, Vector2(back_x, depth * 0.5), Vector2(0, 1), TownProps.DOOR_WIDTH)


func _record_run(kind: String, a: Vector2, b: Vector2, thickness: float = 0.3) -> void:
	var length := a.distance_to(b)
	if length < 0.05:
		return
	var direction := (b - a) / length
	_record_solid(kind, kind, (a + b) * 0.5, Vector2(length * 0.5, thickness * 0.5), atan2(-direction.y, direction.x))


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
	_layout_solids.clear()
	_layout_doors.clear()
	_layout_gates.clear()
	_layout_facing.clear()
	_layout_lanterns.clear()
	_layout_strokes.clear()
	_layout_blobs.clear()

	_rng.seed = 42
	_plan = {}
	_smoke_rng.seed = 7311
	_smoke_puffs.clear()
	_water_wheel_visuals.clear()
	_sawmill_drives.clear()
	_mill_animation_time=0.0
	# Mira Holt now works at and lives in the inn; start ambient placement at
	# Oswin so she is not duplicated as an unrelated plaza wanderer.
	_next_villager_identity = 1
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

	for building_index in OhioPlan.BUILDINGS.size():
		_build_building(generated, OhioPlan.BUILDINGS[building_index], building_index)

	_build_working_landscape(generated)
	_build_ohio_welcome_sign(generated)
	_build_landmarks(generated)
	_scatter_decorations(generated)
	_scatter_platforming(generated)
	_build_village_inn(generated)
	# Worn ground last: it is drawn from the circulation of everything above.
	_build_ground_plan(generated)
	_spawn_npcs(generated)


## The gateway where the arrival road crosses into the village: a pair of
## lantern piers either side of the road (no gate, no walls: the road is the
## most travelled in the village), the welcome sign inside it on
## a small stone-ringed island, and the inn's roadside gable dressed as the
## face the village shows travellers.


func _build_ohio_entrance(parent: Node3D) -> void:
	var ground := Callable(self,"_ground_y")
	var entrance_center: Vector2 = OhioPlan.ENTRANCE["center"]
	var sign_island: Vector2 = OhioPlan.ENTRANCE["sign"]
	var along: Vector2 = OhioPlan.ENTRANCE["along"]
	var across := Vector2(-along.y,along.x)
	var piers: Array[Vector2] = []
	for side: float in [-1.0,1.0]:
		var at: Vector2 = entrance_center + across * float(OhioPlan.ENTRANCE["half_gap"]) * side
		piers.append(at)
		var pier := VillageWorks.build_gate_pier(parent,at,VillageWorks.yaw_along(along),ground)
		var lantern := TownProps.build_ohio_pier_lantern()
		lantern.position = Vector3(0.0,VillageWorks.PIER_HEIGHT,0.0)
		pier.add_child(lantern)
		_record_solid("GatePier","yard_prop",at,Vector2(0.58,0.58),VillageWorks.yaw_along(along))
	VillageWorks.build_verge_island(parent,sign_island,2.3,ground)
	_record_solid("SignIsland","yard_prop",sign_island,Vector2(2.4,2.4),0.0)
	for i in 7:
		var angle := TAU * float(i) / 7.0 + 0.3
		var spot: Vector2 = sign_island + Vector2(cos(angle),sin(angle)) * (1.35 if i % 2 == 0 else 1.75)
		var flower := NatureProps.build_flower([Color(0.94,0.79,0.31),Color(0.72,0.56,0.88),Color(0.88,0.46,0.55)][i % 3])
		flower.position = Vector3(spot.x,_ground_y(spot) + 0.14,spot.y)
		parent.add_child(flower)
	_dress_inn_road_gable(parent,ground)
	_build_main_street_lamps(parent)
	_build_overlook(parent,ground)


## Three lamp posts along the main street, so the way in is lit from the piers
## to the green.
func _build_main_street_lamps(parent: Node3D) -> void:
	for entry: Dictionary in OhioPlan.LAMPS:
		var at: Vector2 = entry["at"]
		_place_street_lantern(parent,"MainStreetLantern",at,OhioPlan.street_point_near(at),Callable(self,"_ground_y"))


## The overlook where the east road meets the rim: a graded flagstone terrace, two
## benches facing the drop, a lantern and one old tree behind them. The village
## goes there to watch the evening over the lake; nothing walls the edge.
func _build_overlook(parent: Node3D,ground: Callable) -> void:
	var at: Vector2 = OhioPlan.OVERLOOK["at"]
	var radius: float = OhioPlan.OVERLOOK["radius"]
	VillageWorks.build_flat_overlook_terrace(
		parent, at, radius, TownProps.FOUNTAIN_STONE.darkened(0.04), ground, "OverlookTerrace"
	)
	_record_solid("OverlookTerrace","yard_prop",at,Vector2(radius,radius),0.0)
	var toward := at + Vector2(10.0,2.0)
	for side in [-1.0,1.0]:
		var bench_at := at + Vector2(radius * 0.55,side * 2.4)
		VillageWorks.build_bench(
			parent, bench_at, toward + Vector2(0,side * 2.4), Callable(self, "_overlook_surface_y")
		)
		_record_solid("OverlookBench","yard_prop",bench_at,Vector2(0.95,0.3),0.0)
	var lamp_at := at + Vector2(-radius * 0.5,3.6)
	_place_street_lantern(parent,"OverlookLantern",lamp_at,at,Callable(self,"_overlook_surface_y"))
	var tree_at: Vector2 = OhioPlan.OVERLOOK["tree"]
	var tree := NatureProps.build_round_tree(6.4,Color(0.15,0.48,0.22))
	tree.name = "OverlookTree"
	tree.position = Vector3(tree_at.x,_ground_y(tree_at),tree_at.y)
	parent.add_child(tree)


func _overlook_surface_y(local_pos: Vector2) -> float:
	# The overlook is intentionally one level deck. Sampling each bench or lamp
	# independently reintroduced the cliff pitch that the terrace removes.
	var centre: Vector2 = OhioPlan.OVERLOOK["at"]
	return _ground_y(centre) + 0.095


## The inn's west gable (the hearth wall) is what a traveller sees first: windows
## either side of the stack (see TownProps), a woodstack and a bench against the
## wall, and a climber on a trellis by the south window.
func _dress_inn_road_gable(parent: Node3D,ground: Callable) -> void:
	# The wall is symmetric about its centre line (the chimney) with a window and
	# its shutters either side at 5.76 m. Between chimney and window, one side
	# keeps the woodstack, the other the trellis and its climber, each well clear
	# of the shutters (which reach 4.9 m out from the centre line).
	var wall_x := INN_LOCAL.x - 9.6
	# Logs lie along the pile's local Z, so yaw 0 keeps them parallel to the wall.
	VillageWorks.build_log_pile(parent,Vector2(wall_x - 1.3,INN_LOCAL.y - 3.4),0.0,ground,3)
	_record_solid("InnWoodstack","yard_prop",Vector2(wall_x - 1.3,INN_LOCAL.y - 3.4),Vector2(0.7,1.6),0.0)
	var trellis_at := Vector2(wall_x - 0.1,INN_LOCAL.y + 3.4)
	VillageWorks.build_trellis(parent,trellis_at,-PI * 0.5,1.3,2.4,ground)
	var climber := NatureProps.build_bush(Color(0.17,0.44,0.22))
	climber.scale = Vector3(0.5,1.5,0.5)
	climber.position = Vector3(trellis_at.x - 0.3,_ground_y(trellis_at),trellis_at.y)
	parent.add_child(climber)


func _build_ohio_welcome_sign(parent: Node3D) -> void:
	_build_ohio_entrance(parent)
	var approach:=(-town_center).normalized()
	var offset: Vector2 = OhioPlan.ENTRANCE["sign"]
	var sign:=StaticBody3D.new()
	sign.name="WelcomeToOhioSign"
	sign.collision_layer=1
	sign.position=Vector3(offset.x,_ground_y(offset) + 0.12,offset.y)
	sign.rotation.y=atan2(approach.x,approach.y)+PI
	for x in [-1.45,1.45]:
		var post:=SuperEgg.build_part(Vector3(0.14,1.35,0.14),TownProps.TRIM_WOOD,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		post.position=Vector3(x,1.35,0)
		sign.add_child(post)
		CollisionPolicy.add_box(sign,post,Vector3(0.24,2.7,0.24),post.position,Basis(),false)
	var board:=SuperEgg.build_part(Vector3(1.85,0.68,0.12),Color(0.48,0.29,0.14),3.8,3.8)
	board.position=Vector3(0,2.05,0)
	sign.add_child(board)
	CollisionPolicy.add_box(sign,board,Vector3(3.7,1.36,0.24),board.position,Basis(),false)
	var emblem:=SuperEgg.build_part(Vector3(0.34,0.22,0.035),Color(0.82,0.67,0.36),2.4,2.4)
	emblem.position=Vector3(0,2.05,-0.14)
	sign.add_child(emblem)
	CollisionPolicy.mark_decorative(emblem)
	parent.add_child(sign)
	Interactable.attach(sign,"Read",2.8,func() -> void:
		DialogUI.show_line("Ohio","Welcome to Ohio. Our village is awesome.")
	)


func _build_village_inn(parent: Node3D) -> void:
	# The Holt Inn stands on the arrival road, its door turned to the road and
	# the bakehouse across it.
	var local_pos := INN_LOCAL
	var keeper_profile:={
		"skin_colors":[Color(0.76,0.58,0.42)],"shirt_colors":[Color(0.18,0.48,0.42)],
		"pants_colors":[Color(0.30,0.18,0.36)],"shoe_colors":[Color(0.22,0.12,0.07)],
		"glove_colors":[Color(0.28,0.16,0.09)],"hair_colors":[Color(0.23,0.12,0.07)],
		"abdomen_scales":[1.08],"female_body_scales":[0.96],"male_body_scales":[1.0],
		"female_chest_scales":[0.96],"male_chest_scales":[1.04],
		"female_hip_scales":[1.10],"male_hip_scales":[1.0],
		"female_hair_styles":[FigureHair.STYLE_BUN],"male_hair_styles":[FigureHair.STYLE_BUZZCUT],
		"long_hair_lengths":[0.0],"sleeve_style":ProceduralFigure.SLEEVE_STYLE_LONG,
	}
	var inn := VillageInn.create(
		parent, terrain, Vector3(town_center.x + local_pos.x, terrain.get_mesh_height(town_center.x + local_pos.x, town_center.y + local_pos.y), town_center.y + local_pos.y),
		"outskirts", "starting_village_inn", 10, "Mira Holt",
		Color(0.52,0.18,0.15),TownProps.WALL_STONE,keeper_profile,false,null,false,"continuous_panel",town_center+INN_ROAD_POINT,[],true
	)
	var inn_yaw := atan2(0.0, -(INN_ROAD_POINT.y - INN_LOCAL.y))
	_record_solid("HoltInn", "building", INN_LOCAL, Vector2(9.6, 8.0), inn_yaw)
	_record_door("HoltInn", INN_LOCAL, inn_yaw, Vector2(0, -8.0), Vector2(0, -1), TownProps.INN_DOOR_WIDTH)
	_record_door("HoltInn (back)", INN_LOCAL, inn_yaw, Vector2(VillageInn.LODGE_BACK_DOOR_X, 8.0), Vector2(0, 1), TownProps.DOOR_WIDTH)
	# The principal public facade gets a legible, civic-scale entrance rather
	# than a shed roof stretched across unrelated windows.
	var inn_house := inn.get_node("InnBuilding") as StaticBody3D
	EntryDressing.gabled_portico(
		inn_house,0.0,5.4,2.4,-8.0,3.2,22.0,Color(0.52,0.18,0.15),
		TownProps.TRIM_WOOD.lightened(0.05),TownProps.WALL_STONE,2,Color(-1.0,-1.0,-1.0),true
	)
	# One pair of wall lanterns belongs to the public entrance itself.  They sit
	# outside the door clearance and light the threshold without adding another
	# pair of freestanding posts to the already substantial portico.
	for x in [-2.05, 2.05]:
		var wall_lamp := TownProps.build_ohio_wall_lantern()
		wall_lamp.position = Vector3(x, 2.35, -8.14)
		inn_house.add_child(wall_lamp)


func _spawn_npcs(parent: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	_spawn_residents(parent)
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
	if not get_tree().get_nodes_in_group("false_hero").is_empty():
		return
	if not WorldState.false_hero_should_appear(get_tree()):
		return
	var packed: PackedScene = load("res://scenes/false_hero_nme.tscn")
	if packed == null:
		push_warning("Missing False Hero scene: res://scenes/false_hero_nme.tscn")
		return
	var false_hero = packed.instantiate()
	false_hero.set_terrain_reference(terrain)
	var offset: Vector2 = OhioPlan.FALSE_HERO_AT
	false_hero.position = Vector3(offset.x, _ground_y(offset), offset.y)
	parent.add_child(false_hero)
	# Every facing/movement write in false_hero_nme.gd targets its own
	# `visuals` child directly (world-space atan2 math, matching player.gd/
	# npc.gd's own convention of a never-rotated root) -- rotating the ROOT
	# from the marker instead (the original approach here) silently added a
	# second, compounding rotation on top of that world-space math, which is
	# exactly what made him walk backwards. `visuals` only resolves once
	# _ready() has run, so this has to happen after add_child(), not before.
	false_hero.visuals.rotation.y = deg_to_rad(OhioPlan.FALSE_HERO_YAW)


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
	var local_offset := OhioPlan.YOGI_AT
	var world_xz := town_center + local_offset
	yogi.position = Vector3(
		world_xz.x, terrain.get_mesh_height(world_xz.x, world_xz.y), world_xz.y
	)
	world.add_child(yogi)


## Where each resident keeps to: a spot at their own door or workplace and how
## far they drift from it (Town-local XZ). Mira Holt is the inn's keeper and the
## three stallholders stand at their counters, so they are not listed.
const RESIDENT_HOMES := OhioPlan.HOMES


## Each resident lives and works where the bible puts them (Oswin at his
## cottage, Cob in the mill yard, Dorran at the sawmill, Ivy among the
## blorbs at the fountain...), rather than being scattered around the green.
func _spawn_residents(parent: Node3D) -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		push_warning("Missing NPC scene: " + NPC_SCENE)
		return
	while _next_villager_identity < VILLAGER_IDENTITIES.size():
		var inst: Node3D = packed.instantiate()
		inst.set_terrain_reference(terrain)
		# Identity (sets is_female) has to run before the figure variant --
		# _assign_figure_variant()'s own hair-style pick reads is_female to
		# decide STYLE_BUN eligibility.
		_assign_villager_identity(inst)
		_assign_figure_variant(inst)
		var home: Dictionary = RESIDENT_HOMES.get(inst.display_name, {"at": Vector2.ZERO, "range": 8.0})
		var offset: Vector2 = home["at"]
		inst.position = Vector3(offset.x, _ground_y(offset), offset.y)
		inst.wander_boundary_center = town_center + offset
		inst.wander_boundary_radius = float(home["range"])
		if OhioPlan.DAILY_SCHEDULES.has(inst.display_name):
			inst.call("configure_daily_schedule", _world_schedule(OhioPlan.DAILY_SCHEDULES[inst.display_name]))
		parent.add_child(inst)


func _world_schedule(local_entries: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for local_entry: Dictionary in local_entries:
		var converted := local_entry.duplicate(true)
		var local_at: Vector2 = local_entry["at"]
		converted["at"] = town_center + local_at
		var route: Array[Vector2] = []
		for local_point in local_entry.get("route", []):
			var local_route_point: Vector2 = local_point
			route.append(town_center + local_route_point)
		converted["route"] = route
		result.append(converted)
	return result


## Reads sequentially from the shuffled-once-per-rebuild pools (see the
## var declarations above) rather than drawing each attribute independently
## at random. With a small cast, independent random picks from
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
	var identity_scale := float(npc_inst.get_meta("ohio_body_scale_override", 0.0))
	if identity_scale > 0.0:
		npc_inst.body_scale = identity_scale
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


## Assigns the next unused entry from VILLAGER_IDENTITIES in order. Sequential
## assignment guarantees no two residents share a name or lines. Wraps via
## modulo only as a safety net if a future authored spawn count exceeds the
## identity list.
func _assign_villager_identity(npc_inst: Node3D) -> void:
	var identity: Dictionary = VILLAGER_IDENTITIES[_next_villager_identity % VILLAGER_IDENTITIES.size()]
	_next_villager_identity += 1
	npc_inst.display_name = identity["name"]
	npc_inst.is_female = identity["female"]
	npc_inst.set_meta("ohio_body_scale_override", float(identity.get("body_scale", 0.0)))
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


func _ground_normal(local_offset: Vector2) -> Vector3:
	var world_pos := town_center + local_offset
	return terrain.get_mesh_normal(world_pos.x, world_pos.y)


# ---------------------------------------------------------------------------
# Buildings
# ---------------------------------------------------------------------------


func _build_building(parent: Node3D, spec: Dictionary, building_index: int) -> void:
	var offset: Vector2 = spec["at"]
	var yaw := deg_to_rad(float(spec["yaw"]))
	var cells: Vector2 = spec["cells"]
	var floors: int = int(spec["floors"])
	var w := int(cells.x)
	var d := int(cells.y)
	var roof_color: Color = TownProps.ROOF_COLORS[building_index % TownProps.ROOF_COLORS.size()]

	var residential:=bool(spec.get("residential",false))
	var building := TownProps.build_building(
		w,d,floors,roof_color,TownProps.WALL_STONE,TownProps.WALL_WOOD,
		TownProps.FLOOR_COLOR,roof_color.darkened(0.12),"continuous_panel",false,str(spec.get("entry","door")),
		float(spec.get("back",TownProps.NO_BACK_DOOR)),
		str(spec.get("shutters","all" if residential else "none")),
		_roof_form_with_gables(spec),
		[],
		_opening_notes(spec)
	)
	building.name=str(spec["name"])
	_dress_ohio_building(building,w,d,floors,roof_color,spec)
	building.position = Vector3(offset.x, _ground_y(offset), offset.y)
	building.rotation.y = yaw
	parent.add_child(building)
	_record_solid(str(spec["name"]), "building", offset, Vector2(float(w), float(d)) * (TownProps.CELL_SIZE * 0.5), yaw)
	_record_building_doors(str(spec["name"]), offset, yaw, w, d, floors, str(spec.get("entry", "door")), float(spec.get("back", TownProps.NO_BACK_DOOR)))


## The oriels and bay windows on a spec's front wall (floor and x), so the wall
## behind each loses its flush shutters.
func _opening_notes(spec: Dictionary) -> Array:
	var notes: Array = []
	for feature in spec.get("features",[]):
		var kind := str(feature["kind"])
		if kind == "oriel":
			notes.append({"floor":int(feature.get("floor",1)),"x":float(feature.get("x",0.0))})
		elif kind == "bay_window":
			notes.append({"floor":0,"x":float(feature.get("x",0.0))})
	return notes


## The roof form of a spec, plus the cross gables its features stand on the front
## slope, so the main roof can be cut away beneath them.
func _roof_form_with_gables(spec: Dictionary) -> Dictionary:
	var form: Dictionary = (spec.get("roof",{}) as Dictionary).duplicate()
	var gables: Array = []
	for feature in spec.get("features",[]):
		if str(feature["kind"]) == "cross_gable":
			gables.append({"x":float(feature.get("x",0.0)),"width":float(feature.get("width",3.8))})
	if not gables.is_empty():
		form["cross_gables"] = gables
	return form


func _dress_ohio_building(
	building: StaticBody3D,w: int,d: int,floors: int,accent: Color,spec: Dictionary
) -> void:
	var half_w:=float(w)*TownProps.CELL_SIZE*0.5
	var half_d:=float(d)*TownProps.CELL_SIZE*0.5
	# The entrance is dressed for what the building is: a pent canopy for a
	# house, a gabled portico for the hall, an awning over the forge, a hooded
	# cart bay for the mills, a shop awning for the bakehouse.
	var entry_style := str(spec.get("entry","door"))
	EntryDressing.dress(
		building,d,floors,str(spec.get("dressing",entry_style)),w,accent,TownProps.TRIM_WOOD,TownProps.WALL_STONE,
		TownProps.WALL_WOOD,entry_style
	)
	FacadeFeatures.apply(
		building,w,d,floors,spec.get("features",[]),entry_style,accent,TownProps.TRIM_WOOD,
		TownProps.WALL_STONE,TownProps.WALL_WOOD,spec.get("roof",{})
	)
	var roof_form: Dictionary = spec.get("roof",{})
	if roof_form.has("catslide"):
		FacadeFeatures.rear_shed(building,w,d,floors,float(roof_form["catslide"]),TownProps.TRIM_WOOD,str(spec.get("stock","sacks")),float(spec.get("back",INF)))
	if floors>1:
		# Projecting joist/fascia line makes the timber upper storey visibly
		# overhang the masonry base without changing its walkable interior.
		for z in [-half_d-0.13,half_d+0.13]:
			var fascia:=SuperEgg.build_part(Vector3(half_w+0.20,0.12,0.13),TownProps.TRIM_WOOD,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
			fascia.position=Vector3(0,TownProps.FLOOR_HEIGHT,z)
			building.add_child(fascia)
	if bool(spec.get("chimney",false)):
		# One chimney built into the gable wall (see Hearth): a single opening by
		# default, or the openings the plan names (a hearth and an oven).
		var fire: Dictionary = spec.get("fire",{})
		var openings: Array = OhioInteriors.openings_for(spec,floors)
		var stack_z := float(fire.get("stack_z",float(spec.get("chimney_z",0.0))))
		Hearth.build_chimney_wall(
			building,w,d,floors,float(spec.get("chimney_side",1.0)),openings,stack_z,_smoke_rng,_smoke_puffs,true,
			TownProps.OHIO_BRICK
		)
	# Public and working entrances receive a single restrained threshold light.
	# Private houses rely on the street standards, so their facades are not
	# peppered with fixtures. The civic hall alone gets a balanced pair.
	var work := str(spec.get("work", ""))
	if work in ["civic", "bakery", "smithy", "grain", "joinery"]:
		var light_xs: Array[float] = []
		if work == "civic":
			light_xs.assign([-2.15, 2.15])
		else:
			light_xs.append(-2.0)
		for light_x in light_xs:
			var wall_lamp := TownProps.build_ohio_wall_lantern()
			wall_lamp.position = Vector3(light_x, 2.35, -half_d - 0.14)
			building.add_child(wall_lamp)
	if spec.has("back") and not (spec.get("roof",{}) as Dictionary).has("catslide"):
		_add_rear_hood(building,half_d,float(spec["back"]),accent)
	if str(spec.get("work","")) == "civic":
		_build_civic_hall_interior(building,half_w,half_d)
	else:
		OhioInteriors.furnish(building,spec,w,d,floors)


## A small pent hood over the rear door, built on a body turned to face the
## back so the same canopy code serves both walls.
func _add_rear_hood(building: StaticBody3D,half_d: float,door_x: float,accent: Color) -> void:
	var rear:=StaticBody3D.new()
	rear.name="RearHood"
	rear.collision_layer=1
	rear.rotation.y=PI
	building.add_child(rear)
	EntryDressing.lean_to(rear,-door_x,2.4,1.0,-half_d,2.9,14.0,accent,TownProps.TRIM_WOOD,TownProps.WALL_STONE,2)


## The meeting house's bell rope: a cord that really runs up through the opening
## in the roof to the bell on its headstock, with a striped sally to pull. Pulling
## it draws the sally down, swings the bell and rings it, so it can be heard across
## the village. The bell and its roof opening are built with the belfry (RoofForms)
## and the roof (TownProps._build_gapped_roof).
func _build_bell_rope(building: StaticBody3D) -> void:
	var pivot := building.get_meta("bell_pivot", null) as Node3D
	if pivot == null:
		return
	var bell_hang_y := float(building.get_meta("bell_hang_y", 6.0))
	var holder := Node3D.new()
	holder.name = "BellRope"
	holder.position = Vector3(pivot.position.x, 1.2, 0.0)
	building.add_child(holder)
	var cord_top := bell_hang_y + 0.2
	var cord_length := cord_top - 1.55
	var cord_colour := Color(0.62, 0.52, 0.34)
	var cord := SuperEgg.build_part(Vector3(0.014, cord_length * 0.5, 0.014), cord_colour, 2.2, SuperEgg.EPSILON_FLAT)
	cord.position = Vector3(0.0, 0.35 + cord_length * 0.5, 0.0)
	holder.add_child(cord)
	CollisionPolicy.mark_decorative(cord)
	# The sally: a wool-covered grip, red and white, with the tail of the rope below.
	var sally := Node3D.new()
	sally.name = "Sally"
	holder.add_child(sally)
	for band in 4:
		var wool := SuperEgg.build_part(
			Vector3(0.042, 0.055, 0.042), Color(0.72, 0.16, 0.14) if band % 2 == 0 else Color(0.9, 0.88, 0.82), 2.2, 2.2
		)
		wool.position = Vector3(0.0, 0.3 - float(band) * 0.11, 0.0)
		sally.add_child(wool)
		CollisionPolicy.mark_decorative(wool)
	var tail := SuperEgg.build_part(Vector3(0.014, 0.5, 0.014), cord_colour, 2.2, SuperEgg.EPSILON_FLAT)
	tail.position = Vector3(0.0, -0.36, 0.0)
	sally.add_child(tail)
	CollisionPolicy.mark_decorative(tail)
	var ringing := false
	var ring := func() -> void:
		if ringing:
			return
		ringing = true
		UISounds.play_foley(&"village_bell", 1.0, pivot.get_instance_id())
		var pull := holder.create_tween()
		pull.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pull.tween_property(sally, "position:y", -0.35, 0.22)
		pull.tween_property(sally, "position:y", 0.0, 0.55)
		var swing := holder.create_tween()
		swing.tween_method(
			func(t: float) -> void:
				pivot.rotation.z = 0.5 * exp(-t * 0.85) * sin(t * TAU * 0.62),
			0.0, 5.0, 5.0
		)
		swing.finished.connect(func() -> void:
			pivot.rotation.z = 0.0
			ringing = false)
	Interactable.attach(holder, "Ring the bell", 1.5, ring, Callable(), Callable(), false, 1.8)


## The meeting house is planned as a civic interior rather than one worktable
## dropped into an empty shell: a west-end dais for Halda, a clear central hall,
## Petra's school group at the rear, and a proper enclosed archive in the quiet
## south-east corner. The archive partitions meet the rafters.
func _build_civic_hall_interior(building: StaticBody3D, half_w: float, half_d: float) -> void:
	var roof := {"floor_top":TownProps.FLOOR_HEIGHT, "run":half_d}
	var archive_x := 3.15
	var archive_z := 1.35
	TownProps.build_interior_wall(
		building, Vector2(archive_x, archive_z), Vector2(archive_x, half_d - 0.18), 0.0,
		[1.65], TownProps.WALL_STONE.lightened(0.1), TownProps.TRIM_WOOD,
		TownProps.FLOOR_HEIGHT, true, [], roof
	)
	TownProps.build_interior_wall(
		building, Vector2(archive_x, archive_z), Vector2(half_w - 0.18, archive_z), 0.0,
		[], TownProps.WALL_STONE.lightened(0.1), TownProps.TRIM_WOOD,
		TownProps.FLOOR_HEIGHT, true, [], roof
	)

	# Reeve's end. The low dais does not block the front-door aisle.
	Furnishings.piece(
		building, Vector3(1.45, 0.12, 2.25), TownProps.FLOOR_COLOR.darkened(0.08),
		Vector3(-half_w + 1.75, 0.12, 0.55), 0.0, true, SuperEgg.EPSILON_SOFT
	)
	Furnishings.desk(building, Vector3(-half_w + 1.75, 0.24, 0.75), PI * 0.5)
	Furnishings.lectern(building, Vector3(-half_w + 3.75, 0.0, -1.5), PI * 0.5)
	Furnishings.strongbox(building, Vector3(-half_w + 0.65, 0.24, 2.9), PI * 0.5)

	# Public seating follows the long walls in groups, leaving the entrance and
	# the centre aisle open for meetings and market arbitration.
	for x in [-3.0, 0.2, 3.0]:
		if x < archive_x - 0.4:
			Furnishings.bench(building, Vector3(x, 0.0, half_d - 0.72), 0.0, 2.25)
	for x in [-3.4, 3.4]:
		Furnishings.bench(building, Vector3(x, 0.0, -half_d + 0.72), 0.0, 2.2)

	# Petra's teaching group occupies the rear middle bay, close to daylight but
	# outside the archive door swing.
	Furnishings.table(building, Vector3(0.0, 0.0, 2.65), 0.0, 2.8, 0.9, "")
	for spot in [Vector3(-1.05, 0, 1.85), Vector3(0, 0, 1.85), Vector3(1.05, 0, 1.85)]:
		Furnishings.stool(building, spot)
	var slate := Furnishings.piece(
		building, Vector3(1.1, 0.48, 0.035), Color(0.15, 0.19, 0.17),
		Vector3(0, 1.55, half_d - 0.24), 0.0, false, SuperEgg.EPSILON_FLAT
	)
	slate.name = "PetraSlate"
	Furnishings.chest(building, Vector3(2.15, 0.0, half_d - 0.75), 0.0, Furnishings.OAK_DARK, 0.8)

	# Archive: Halda's common accounts, Petra's copied histories, and the dry
	# strong storage each form a readable activity group.
	Furnishings.shelf(building, Vector3(half_w - 0.48, 0.0, 3.15), PI * 0.5, 2.6, 4, "boxes")
	Furnishings.shelf(building, Vector3(5.35, 0.0, half_d - 0.38), 0.0, 3.4, 4, "boxes")
	Furnishings.desk(building, Vector3(5.35, 0.0, 2.25), PI)
	Furnishings.strongbox(building, Vector3(half_w - 0.75, 0.0, half_d - 0.75), PI * 0.5)

	_build_bell_rope(building)

	Furnishings.hanging_lamp(building, Vector3(-3.4, 2.65, 0.2), 0.72, 5.5)
	Furnishings.hanging_lamp(building, Vector3(0.4, 2.55, 2.3), 0.62, 4.5)
	Furnishings.hanging_lamp(building, Vector3(5.4, 2.45, 3.1), 0.52, 3.6)


# ---------------------------------------------------------------------------
# Plaza, decorations, NPCs
# ---------------------------------------------------------------------------


## Authored village plan, in Town-local XZ metres. The arrival road enters
## from the welcome sign (WNW), passes the inn and the bakehouse across from
## it, and widens into the green. Buildings, stalls and landmarks are markers
## in main.tscn; everything here is the ground, water and yards between them.
const STREAM_WIDTH := 2.0
## The tarn in the plateau's northern hills (see TerrainGenerator's
## TOWN_POND_*), a long way from the village. Its water leaves over a stone weir
## at the east sill, runs down a chute to the mill bench, past the sawmill wheel,
## and along a level leat to the plateau's edge, where it goes over the cliff.
const POND_CENTER := OhioPlan.POND_CENTER
const POND_RADIUS := OhioPlan.POND_RADIUS
const POND_WEIR_RADIUS := OhioPlan.POND_WEIR_RADIUS
const MILL_CENTER := OhioPlan.MILL_CENTER
const WHEEL_SPOT := OhioPlan.WHEEL_SPOT
const AQUEDUCT_COURSE: Array[Vector2] = OhioPlan.AQUEDUCT_COURSE
const BRIDGE_SPOT := OhioPlan.BRIDGE_SPOT
## Where the footbridge crosses the aqueduct; chosen by the waterworks plan.
var _plan: Dictionary = {}
const INN_LOCAL := OhioPlan.INN_AT
const INN_ROAD_POINT := OhioPlan.INN_ROAD_POINT


func _build_ground_plan(parent: Node3D) -> void:
	# Paths are paint, not paving: worn earth with ragged margins, projected
	# into the terrain (see GroundPaint) so it follows every contour.
	var strokes: Array = [{"points": GroundPaint.smooth(OhioPlan.MAIN_STREET), "width": 4.8}]
	for way in OhioPlan.WAYS:
		var points: Array[Vector2] = []
		points.assign(way["points"])
		strokes.append({"points": GroundPaint.smooth(points), "width": float(way["width"])})
	var connected_ground: Array = OhioPlan.WORN_GROUND.duplicate(true)
	# The civic centre belongs to the same projected ground layer as every
	# path.  Two coplanar decals used to fight over which was visible.
	connected_ground.append({"center":Vector2.ZERO,"radii":Vector2(9.8,9.2)})
	_connect_worn_ground(strokes, connected_ground)
	_layout_strokes.clear()
	for stroke in strokes:
		_layout_strokes.append({"points": stroke["points"], "width": float(stroke["width"])})
	_layout_blobs.assign(connected_ground)
	GroundPaint.paint(
		parent, strokes, connected_ground, _ground_y(Vector2.ZERO), "OhioWornGround",
		GroundPaint.DIRT, GroundPaint.DIRT_PALE, 0.9, 4207,
		Callable(self, "_walkable_ground_paint_weight")
	)
	_build_village_square(parent)


## Ground paint is projected vertically, so without this filter the approach
## to the overlook also colors the cliff face below it. Fade it before the
## ground exceeds a walkable grade; the fitted overlook flagstones then take
## over cleanly at the destination.
func _walkable_ground_paint_weight(local_pos: Vector2) -> float:
	var world := town_center + local_pos
	var normal: Vector3 = terrain.get_mesh_normal(world.x, world.y)
	var gradient := Vector2(normal.x, normal.z).length() / maxf(normal.y, 0.01)
	return 1.0 - smoothstep(0.38, 0.72, gradient)


## Worn ground follows circulation. Everything that people walk to (every door,
## every gate) must stand on worn ground, and no path may stop short of other
## worn ground, so wherever traffic obviously flows between two worn areas this
## adds the strip of trodden earth that joins them.
func _connect_worn_ground(strokes: Array, blobs: Array) -> void:
	var destinations: Array[Vector2] = []
	for door in _layout_doors:
		destinations.append((door["pos"] as Vector2) + (door["dir"] as Vector2) * 0.9)
	for gate in _layout_gates:
		destinations.append((gate["pos"] as Vector2) - (gate["dir"] as Vector2) * 1.5)
	for spot in destinations:
		if _worn_distance(spot, strokes, blobs, -1) > 0.5:
			_join_to_worn(spot, strokes, blobs, -1, 1.9)
	# Path ends that stop a little short of other worn ground: close the gap.
	for index in strokes.size():
		var points: Array = strokes[index]["points"]
		if points.size() < 2:
			continue
		for end_index in [0, points.size() - 1]:
			var end: Vector2 = points[end_index]
			if end.length() > 55.0:
				continue
			var gap := _worn_distance(end, strokes, blobs, index)
			var at_destination := false
			for spot in destinations:
				if spot.distance_to(end) < 2.5:
					at_destination = true
			if gap > 0.5 and gap < 9.0 and not at_destination:
				_join_to_worn(end, strokes, blobs, index, float(strokes[index]["width"]))


func _worn_distance(point: Vector2, strokes: Array, blobs: Array, skip: int) -> float:
	var best := INF
	for other in strokes.size():
		if other == skip:
			continue
		var line: Array = strokes[other]["points"]
		for i in line.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(point, line[i], line[i + 1])
			best = minf(best, maxf(point.distance_to(closest) - float(strokes[other]["width"]) * 0.5, 0.0))
	for blob in blobs:
		var radii: Vector2 = blob["radii"]
		var offset: Vector2 = point - (blob["center"] as Vector2)
		var normalised := Vector2(offset.x / radii.x, offset.y / radii.y).length()
		best = minf(best, 0.0 if normalised <= 1.0 else (normalised - 1.0) * minf(radii.x, radii.y))
	return best


## Adds a short gently curved stroke from `from` to the nearest worn ground.
func _join_to_worn(from: Vector2, strokes: Array, blobs: Array, skip: int, width: float) -> void:
	var best_point := from
	var best := INF
	for other in strokes.size():
		if other == skip:
			continue
		var line: Array = strokes[other]["points"]
		for i in line.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(from, line[i], line[i + 1])
			if from.distance_to(closest) < best:
				best = from.distance_to(closest)
				best_point = closest
	for blob in blobs:
		var radii: Vector2 = blob["radii"]
		var center: Vector2 = blob["center"]
		var offset := from - center
		var normalised := Vector2(offset.x / radii.x, offset.y / radii.y).length()
		if normalised > 1.0:
			var edge := center + offset / normalised * 0.9
			if from.distance_to(edge) < best:
				best = from.distance_to(edge)
				best_point = edge
	if best == INF or best < 0.3:
		return
	var middle := (from + best_point) * 0.5
	var side := Vector2(-(best_point - from).y, (best_point - from).x).normalized()
	var link: Array[Vector2] = [from, middle + side * minf(best * 0.12, 0.9), best_point]
	strokes.append({"points": GroundPaint.smooth(link, 1.6), "width": width})


## The settlement's working landscape: the managed stream and its mill, the
## timber yard, the grain yard, the mason's yard and the garden boundaries.
func _build_working_landscape(parent: Node3D) -> void:
	var ground := Callable(self, "_ground_y")
	_build_waterworks(parent, ground)

	# Timber yard in front of the sawmill: racks of sawn boards, stacked logs.
	for rack: Vector2 in OhioPlan.TIMBER_RACKS:
		VillageWorks.build_timber_rack(parent, rack, 0.0, ground)
		_record_solid("TimberRack", "yard_prop", rack, Vector2(2.1, 0.6), 0.0)
	for pile in OhioPlan.LOG_PILES:
		var pile_at: Vector2 = pile["at"]
		VillageWorks.build_log_pile(parent, pile_at, float(pile["yaw"]), ground, int(pile["rows"]))
		_record_solid("LogPile", "yard_prop", pile_at, Vector2(1.6, 0.7 if int(pile["rows"]) > 2 else 0.5), float(pile["yaw"]))

	# Cob's grain yard: the millhouse's east wall is its west side, so both the
	# door and the cart bay open straight into it; it is gated toward the lane
	# on the east, with a granary and a cart shelter inside.
	var grain_center: Vector2 = OhioPlan.GRAIN_YARD["center"]
	var shelter_at: Vector2 = OhioPlan.CART_SHELTER_AT
	var granary_at: Vector2 = OhioPlan.GRANARY_AT
	_build_fenced_yard(
		parent, grain_center, OhioPlan.GRAIN_YARD["size"], 0.0,
		[{"side":Vector2(1,0),"offset":0.0}], [Vector2(-1,0)]
	)
	VillageWorks.build_cart_shelter(parent,shelter_at,PI*0.5,TownProps.ROOF_COLORS[3],ground)
	VillageWorks.build_granary_shed(parent,granary_at,0.0,TownProps.ROOF_COLORS[3],ground)
	_record_solid("CartShelter", "building", shelter_at, Vector2(2.35, 1.6), PI*0.5)
	_record_solid("Granary", "building", granary_at, Vector2(2.25, 1.48), 0.0)
	_record_door("Granary", granary_at, 0.0, Vector2(0, -1.25), Vector2(0, -1), 1.8)

	# Tam Ruskin's contained rear yard: stone samples and a lime pit.
	var stone_at: Vector2 = OhioPlan.STONE_YARD_AT
	VillageWorks.build_stone_yard(parent, stone_at, 0.0, ground)
	_record_solid("StoneYard", "yard_prop", stone_at, Vector2(3.0, 2.0), 0.0)

	# Aldren Vey's secure storehouse stands immediately behind his house.
	_build_outbuilding(parent, "VeyStorehouse", OhioPlan.VEY_STOREHOUSE_AT, Vector2(0,1), 2, 1, TownProps.ROOF_COLORS[0].darkened(0.1))

	# Oswin and Ivy's kitchen garden is bounded by a woven hedge, gated opposite
	# the cottage's rear door.
	# Behind (west of) the Cray and Thorne cottage; its front door stays on the lane.
	var kitchen: Dictionary = OhioPlan.KITCHEN_GARDEN
	_build_hedged_yard(parent,kitchen["center"],kitchen["size"],Vector2(0,1),Vector2(1,0))
	_build_kitchen_garden(parent,kitchen["center"],kitchen["size"])
	# Wren Sallow's drying shed, and her fenced physic garden behind the cottage,
	# gated toward her rear door.
	var physic: Dictionary = OhioPlan.PHYSIC_GARDEN
	_build_outbuilding(parent, "DryingShed", OhioPlan.DRYING_SHED_AT, Vector2(1,0), 2, 1, TownProps.ROOF_COLORS[2])
	_build_fenced_yard(parent, physic["center"], physic["size"], 0.0, [{"side":Vector2(0,-1),"offset":3.0}], [Vector2(1,0)])
	_build_physic_garden(parent,physic["center"],physic["size"])
	_build_residential_landscaping(parent)

## The village's water: a natural spring pond cut into the hills beyond the
## timber yard, then a constructed aqueduct carrying that water past the
## headgate to the sawmill wheel, beneath the footbridge, and on to the
## plateau rim. Only the small overflow intake is masonry at the pond itself;
## there is no artificial retaining wall around the shoreline.
func _build_waterworks(parent: Node3D, ground: Callable) -> void:
	var plan := _waterworks_plan()
	var samples: Array[Vector2] = []
	samples.assign(plan["samples"])
	var beds := _aqueduct_beds(samples)
	_course = samples
	var pond_level:float=terrain.get_town_pond_water_level()
	# The rendered surface and gameplay liquid query share one exact datum.
	VillageWorks.build_natural_pond(parent,POND_CENTER,POND_RADIUS,pond_level,7319)
	VillageWorks.build_pond_weir(parent,POND_CENTER,POND_WEIR_RADIUS,pond_level,ground)
	_build_pond_flora(parent)
	VillageWorks.build_aqueduct(parent, samples, beds, STREAM_WIDTH, ground)
	for i in samples.size() - 1:
		_record_run("water", samples[i], samples[i + 1], STREAM_WIDTH + 0.9)
	var gate_at: Vector2 = OhioPlan.HEADGATE_AT
	var gate_bed := _bed_near(samples, beds, gate_at)
	VillageWorks.build_headgate(parent, gate_at, _stream_direction_near(samples, gate_at), STREAM_WIDTH, ground, gate_bed)
	_build_sawmill_wheel(parent, _bed_near(samples, beds, WHEEL_SPOT))
	_build_cascade(parent, plan, samples[samples.size() - 1], beds[beds.size() - 1] + VillageWorks.WATER_LEVEL, ground)


## Floor height of the aqueduct at each sample: the highest ground still ahead
## plus a little, so the water only ever runs downhill (a causeway, never a
## cutting) and the channel never sinks into rising ground.
func _aqueduct_beds(samples: Array[Vector2]) -> Array[float]:
	var beds: Array[float] = []
	beds.resize(samples.size())
	var running := 0.0
	for i in range(samples.size() - 1, -1, -1):
		running = maxf(running, _ground_y(samples[i]) + 0.5)
		beds[i] = running
	return beds


func _bed_near(samples: Array[Vector2], beds: Array[float], at: Vector2) -> float:
	var best := 0
	var best_distance := INF
	for i in samples.size():
		var distance := samples[i].distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = i
	return beds[best]


func _waterworks_plan() -> Dictionary:
	if _plan.is_empty():
		_plan = _plan_waterworks()
	return _plan


## The water's route is authored (AQUEDUCT_COURSE): the terrain was sculpted
## for it, so there is nothing to search for. The plan smooths the course into
## samples, sets the footbridge where the road meets the leat, and takes the
## fall's direction from the last stretch of channel, so the water leaves the
## lip travelling the way it was already going.
## Returns {"course", "samples", "rim" (local), "dir", "bridge", "bridge_near"}.
func _plan_waterworks() -> Dictionary:
	var course: Array[Vector2] = []
	course.assign(AQUEDUCT_COURSE)
	var samples := GroundPaint.smooth(course, 2.0)
	var last := samples.size() - 1
	var direction := (samples[last] - samples[last - 3]).normalized()
	return {
		"course": course, "samples": samples, "rim": samples[last], "dir": direction,
		"bridge": BRIDGE_SPOT, "bridge_near": Vector2.ZERO,
	}


## The water going over the edge: a cascade ribbon from the aqueduct's end down
## the slope to the lake's surface.
func _build_cascade(parent: Node3D, plan: Dictionary, start: Vector2, start_y: float, ground: Callable) -> void:
	var direction: Vector2 = plan["dir"]
	var shore_y: float = terrain.get_lake_water_level()
	const STEP := 2.0
	const STEEP_DROP := 1.2
	var width0 := STREAM_WIDTH + 0.6
	# Walk out from the aqueduct's end to the cliff's lip (the first step that falls
	# away steeply) and on to where the ground meets the lake.
	var lip_step := -1
	var lake_step := -1
	var previous_y := _ground_y(start)
	for step in range(1, 140):
		var y := _ground_y(start + direction * STEP * float(step))
		if lip_step < 0 and previous_y - y > STEEP_DROP:
			lip_step = step - 1
		previous_y = y
		if y <= shore_y + 0.3:
			lake_step = step
			break
	if lip_step < 0 or lake_step < 0:
		_build_cascade_on_slope(parent, direction, start, start_y, ground)
		return
	# The water runs down the slope to the lip as before...
	var points: Array[Vector2] = [start]
	var widths: Array[float] = [width0]
	for step in range(1, lip_step + 1):
		points.append(start + direction * STEP * float(step))
		widths.append(width0 + float(step) * 0.07)
	VillageWorks.build_cascade(parent, points, widths, start_y, shore_y, ground)
	_add_cascade_spray(parent, points, widths, start_y, shore_y)
	# ...then leaves the cliff in a free arc, out past its foot until it stands
	# vertically over the lake, and falls into it.
	var lip := start + direction * STEP * float(lip_step)
	var lip_y := maxf(_ground_y(lip) + 0.16, shore_y + 1.0)
	var drop := lip_y - shore_y
	var fall_time := sqrt(2.0 * drop / 9.81)
	var reach := STEP * float(lake_step - lip_step) + 3.0
	while reach < STEP * float(lake_step - lip_step) + 40.0:
		var clear := true
		for k in range(1, 31):
			var t := fall_time * float(k) / 30.0
			var at := lip + direction * (reach / fall_time * t)
			if lip_y - 0.5 * 9.81 * t * t < _ground_y(at) + 0.3 and _ground_y(at) > shore_y:
				clear = false
				break
		if clear:
			break
		reach += 2.0
	var arc_points: Array[Vector2] = []
	var arc_widths: Array[float] = []
	var arc_heights: Array[float] = []
	const ARC_SAMPLES := 40
	for k in range(0, ARC_SAMPLES + 1):
		var t := fall_time * float(k) / float(ARC_SAMPLES)
		arc_points.append(lip + direction * (reach / fall_time * t))
		arc_widths.append(width0 + float(lip_step) * 0.07 + 2.5 * float(k) / float(ARC_SAMPLES))
		arc_heights.append(maxf(lip_y - 0.5 * 9.81 * t * t, shore_y + 0.1))
	VillageWorks.build_cascade(parent, arc_points, arc_widths, lip_y, shore_y, ground, "CascadeFall", arc_heights)
	var landing := arc_points[arc_points.size() - 1]
	_add_mist(parent, Vector3(landing.x, shore_y + 0.3, landing.y), Vector3(5.0, 0.3, 5.0), 70, 2.6, 4.5)
	_add_mist(parent, Vector3(lip.x, lip_y + 0.2, lip.y), Vector3(width0 * 0.5, 0.2, 0.6), 16, 1.2, 1.4)


## Where there is no cliff to leave, the water simply follows the slope to the lake.
func _build_cascade_on_slope(parent: Node3D, direction: Vector2, start: Vector2, start_y: float, ground: Callable) -> void:
	var shore_y: float = terrain.get_lake_water_level()
	var points: Array[Vector2] = [start]
	var widths: Array[float] = [STREAM_WIDTH + 0.6]
	var step_length := 2.0
	var past_shore := 0
	for step in range(1, 140):
		var point := start + direction * step_length * float(step)
		points.append(point)
		widths.append(minf(STREAM_WIDTH + 0.6 + float(step) * 0.07, 9.0))
		if _ground_y(point) <= shore_y + 0.3:
			past_shore += 1
			if past_shore >= 3:
				break
	VillageWorks.build_cascade(parent, points, widths, start_y, shore_y, ground)
	_add_cascade_spray(parent, points, widths, start_y, shore_y)


## Spray where the water spills over the rim and wherever the slope steepens,
## and a heavier mist cloud where it meets the lake.
func _add_cascade_spray(
	parent: Node3D, points: Array[Vector2], widths: Array[float], start_y: float, shore_y: float
) -> void:
	_add_mist(parent, Vector3(points[0].x, start_y + 0.2, points[0].y), Vector3(widths[0] * 0.5, 0.2, 0.6), 16, 1.2, 1.4)
	var last_spray := 0
	for i in range(1, points.size()):
		var drop := _ground_y(points[i - 1]) - _ground_y(points[i])
		if drop > 1.6 and i - last_spray >= 7:
			last_spray = i
			var at := _ground_y(points[i]) + 0.4
			_add_mist(parent, Vector3(points[i].x, at, points[i].y), Vector3(widths[i] * 0.5, 0.2, 1.2), 22, 1.6, 1.8)
	var end := points[points.size() - 1]
	_add_mist(parent, Vector3(end.x, shore_y + 0.3, end.y), Vector3(5.0, 0.3, 5.0), 70, 2.6, 4.5)


func _add_mist(parent: Node3D, at: Vector3, extents: Vector3, amount: int, rise: float, size: float) -> void:
	var mist := ParticleFX.build_mist_particles(amount, extents, rise, size)
	mist.position = at
	parent.add_child(mist)
	CollisionPolicy.mark_decorative(mist)


func _stream_direction_near(samples: Array[Vector2], at: Vector2) -> Vector2:
	var best := 0
	var best_distance := INF
	for i in samples.size() - 1:
		var distance := samples[i].distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = i
	return (samples[best + 1] - samples[best]).normalized()


## The sawmill's own breast of water: the wheel stands in the race against the
## mill's north drive wall and a long axle carries its drive through that wall
## into the saw floor.
func _build_sawmill_wheel(parent: Node3D, bed_y: float) -> void:
	var centre_y := TownProps.WATER_WHEEL_OUTER_RADIUS + VillageWorks.WATER_LEVEL - 0.15
	var wheel := TownProps.build_water_wheel()
	wheel.name = "SawmillWheel"
	wheel.position = Vector3(WHEEL_SPOT.x, bed_y + centre_y, WHEEL_SPOT.y)
	# The race flows east and the mill stands to the south: the wheel's axle runs
	# north-south, into the mill's north wall.
	wheel.rotation.y = -PI * 0.5
	parent.add_child(wheel)
	if wheel.get_child_count()>0 and wheel.get_child(0) is Node3D:
		_water_wheel_visuals.append(wheel.get_child(0) as Node3D)
	var wheel_visual:=wheel.get_child(0) as Node3D
	var spoke_half := Vector3(0.07, 1.12, 0.1)
	for i in 6:
		var spoke := SuperEgg.build_part(spoke_half, TownProps.TRIM_WOOD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		var angle := TAU * float(i) / 6.0
		spoke.position = Vector3.ZERO
		spoke.rotation.x = angle
		wheel_visual.add_child(spoke)
		CollisionPolicy.mark_decorative(spoke)
	var hub:=SuperEgg.build_part(Vector3(0.42,0.42,0.42),TownProps.TRIM_WOOD.lightened(0.08),2.2,2.2)
	wheel_visual.add_child(hub)
	CollisionPolicy.mark_decorative(hub)
	var axle := SuperEgg.build_part(Vector3(1.1, 0.14, 0.14), TownProps.TRIM_WOOD, 2.2, 2.2)
	# In wheel-local space +X becomes world +Z after the assembly's yaw, carrying
	# power south through the sawmill's north wall.
	axle.position = Vector3(1.1, 0, 0)
	wheel.add_child(axle)
	CollisionPolicy.mark_decorative(axle)
	_build_sawmill_drive(parent,bed_y+centre_y)


## The axle visibly enters the sawmill's north wall, where a large gear, crank
## and saw carriage explain what the wheel is doing inside the building: the
## drive runs south from the wall into the saw floor.
func _build_sawmill_drive(parent: Node3D,axle_y: float) -> void:
	var works:=Node3D.new()
	works.name="SawmillDriveMachinery"
	parent.add_child(works)
	var floor_y:=_ground_y(MILL_CENTER)
	var x:=WHEEL_SPOT.x
	var wall_z:=MILL_CENTER.y-4.8
	var shaft:=SuperEgg.build_part(Vector3(0.16,0.16,2.0),TownProps.TRIM_WOOD.darkened(0.12),2.2,2.2)
	shaft.position=Vector3(x,axle_y,wall_z+1.6)
	works.add_child(shaft)
	CollisionPolicy.mark_decorative(shaft)
	var gear_pivot := Node3D.new()
	gear_pivot.name = "CrankGearDrive"
	gear_pivot.position = Vector3(x, axle_y, wall_z + 2.4)
	works.add_child(gear_pivot)
	var gear:=CylinderMesh.new()
	gear.top_radius=0.82
	gear.bottom_radius=0.82
	gear.height=0.18
	gear.radial_segments=16
	gear.material=SolidModel.material(TownProps.TRIM_WOOD.lightened(0.08),0.82,0.0)
	var gear_mesh:=MeshInstance3D.new()
	gear_mesh.mesh=gear
	gear_mesh.rotation.x=PI*0.5
	gear_pivot.add_child(gear_mesh)
	CollisionPolicy.mark_decorative(gear_mesh)
	# A visible offset pin converts the gear's rotation into the frame saw's
	# vertical stroke through one connecting rod.
	var crank_pin := SuperEgg.build_part(Vector3(0.13, 0.13, 0.16), TownProps.TRIM_WOOD.lightened(0.18), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	crank_pin.position = Vector3(0.55, 0, 0)
	gear_pivot.add_child(crank_pin)
	CollisionPolicy.mark_decorative(crank_pin)
	# Two fixed rails establish the log's direction of travel. The collidable
	# carriage sits on them and carries one full, unsawn log into the blade.
	var carriage_x := x - 2.2
	var carriage_z := wall_z + 4.2
	for rail_x in [-0.58, 0.58]:
		var rail := SuperEgg.build_part(Vector3(0.07, 0.08, 2.85), TownProps.TRIM_WOOD.darkened(0.08), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		rail.position = Vector3(carriage_x + rail_x, floor_y + 0.32, carriage_z)
		works.add_child(rail)
		CollisionPolicy.mark_decorative(rail)
	var carriage := TownProps.build_crate(Vector3(1.8, 0.32, 5.0), TownProps.TRIM_WOOD.lightened(0.16), true)
	carriage.name = "LogCarriage"
	carriage.position = Vector3(carriage_x, floor_y + 0.36, carriage_z)
	works.add_child(carriage)
	var log := SuperEgg.build_part(Vector3(0.42, 0.42, 2.12), Color(0.45, 0.27, 0.12), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	log.position = Vector3(0, 0.72, 0.25)
	carriage.add_child(log)
	CollisionPolicy.mark_decorative(log)
	# The complete frame moves as one body. Its two posts and cross-head make it
	# unmistakably a reciprocating frame saw, not an unexplained floating blade.
	var saw_frame := Node3D.new()
	saw_frame.name = "ReciprocatingSawFrame"
	saw_frame.position = Vector3(carriage_x, floor_y + 1.58, carriage_z + 0.25)
	works.add_child(saw_frame)
	for side in [-1.0, 1.0]:
		var post := SuperEgg.build_part(Vector3(0.07, 0.92, 0.07), TownProps.TRIM_WOOD, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		post.position = Vector3(side * 0.68, 0, 0)
		saw_frame.add_child(post)
		CollisionPolicy.mark_decorative(post)
	for frame_y in [-0.82, 0.82]:
		var cross := SuperEgg.build_part(Vector3(0.75, 0.07, 0.07), TownProps.TRIM_WOOD, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		cross.position = Vector3(0, frame_y, 0)
		saw_frame.add_child(cross)
		CollisionPolicy.mark_decorative(cross)
	var blade := SuperEgg.build_part(Vector3(0.035, 0.78, 0.16), Color(0.48,0.50,0.52), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	saw_frame.add_child(blade)
	CollisionPolicy.mark_decorative(blade)
	var rod := SuperEgg.build_part(Vector3(0.065, 1.0, 0.065), TownProps.TRIM_WOOD.lightened(0.05), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	rod.name = "CrankConnectingRod"
	works.add_child(rod)
	CollisionPolicy.mark_decorative(rod)
	# The output side shows the result of the action: squared boards and sawdust
	# sit beyond the frame, while unsawn logs remain in the yard outside.
	for i in 3:
		var board := SuperEgg.build_part(Vector3(0.48, 0.055, 1.45), Color(0.67, 0.47, 0.25).lightened(0.04 * i), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		board.position = Vector3(carriage_x + 1.8, floor_y + 0.18 + float(i) * 0.12, carriage_z + 1.0)
		works.add_child(board)
		CollisionPolicy.mark_decorative(board)
	var sawdust := SuperEgg.build_part(Vector3(0.58, 0.08, 0.72), Color(0.73, 0.57, 0.32), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	sawdust.position = Vector3(carriage_x, floor_y + 0.1, carriage_z + 0.35)
	works.add_child(sawdust)
	CollisionPolicy.mark_decorative(sawdust)
	_sawmill_drives.append({
		"gear": gear_pivot, "pin": crank_pin, "frame": saw_frame, "rod": rod,
		"frame_base_y": saw_frame.position.y, "crank_radius": 0.55,
	})


func _animate_sawmill_drive(drive: Dictionary) -> void:
	var gear: Node3D = drive["gear"]
	var pin: Node3D = drive["pin"]
	var frame: Node3D = drive["frame"]
	var rod: Node3D = drive["rod"]
	if not is_instance_valid(gear) or not is_instance_valid(frame) or not is_instance_valid(rod):
		return
	# The small crank gear turns faster than the outside water wheel. Its offset
	# pin and the saw frame use the same phase, so every visible link agrees.
	var angle := _mill_animation_time * 1.55
	gear.rotation.z = angle
	var radius := float(drive["crank_radius"])
	frame.position.y = float(drive["frame_base_y"]) + sin(angle) * radius
	var pin_world := gear.position + Vector3(cos(angle) * radius, sin(angle) * radius, 0)
	var frame_top := frame.position + Vector3(0, 0.82, 0)
	_set_sawmill_rod(rod, pin_world, frame_top)
	# `pin` is a child of the rotating gear. Keeping the reference in the record
	# also guards against a partially rebuilt assembly during editor refresh.
	if not is_instance_valid(pin):
		rod.visible = false


func _set_sawmill_rod(rod: Node3D, from: Vector3, to: Vector3) -> void:
	var delta := to - from
	var length := maxf(delta.length(), 0.01)
	rod.position = (from + to) * 0.5
	rod.quaternion = Quaternion(Vector3.UP, delta / length)
	rod.scale = Vector3(1, length * 0.5, 1)


func _build_pond_flora(parent: Node3D) -> void:
	# Hill trees stand back on the banks, well clear of the water and the leat.
	var tree_specs: Array[Dictionary]=OhioPlan.POND_TREES
	for i in tree_specs.size():
		var spot:Vector2=tree_specs[i]["at"]
		var tree:=NatureProps.build_round_tree(float(tree_specs[i]["h"]),Color(0.13,0.48+0.025*float(i%3),0.24))
		tree.name="SpringPondTree"
		tree.position=Vector3(spot.x,_pond_bank_y(spot),spot.y)
		parent.add_child(tree)
	for i in 28:
		var angle:=TAU*float(i)/28.0+0.18*sin(float(i)*1.7)
		# Leave the weir's arc open and make clusters, not a complete ring.
		if absf(angle_difference(angle,0.0))<0.7 or i in [4,5,13,20,21]:
			continue
		# On the bank just above the water line (the shore lies near 14 m).
		var radius:=16.6+1.4*sin(float(i)*2.31)
		var spot:=POND_CENTER+Vector2(cos(angle),sin(angle))*radius
		var plant:Node3D
		if i%3==0:
			plant=NatureProps.build_bush(Color(0.14,0.50,0.27))
			plant.scale=Vector3.ONE*0.55
		else:
			plant=NatureProps.build_flower([Color(0.72,0.56,0.88),Color(0.94,0.79,0.31),Color(0.88,0.46,0.55)][i%3])
		plant.position=Vector3(spot.x,_pond_bank_y(spot)+0.015,spot.y)
		parent.add_child(plant)


## Shore vegetation sits directly on the same primary terrain mesh as the rest
## of Ohio. There is deliberately no local bank/skirt mesh around this pond.
func _pond_bank_y(spot: Vector2) -> float:
	return _ground_y(spot)+0.035


## Small gabled outbuilding in the village's own panel language, door toward
## `door_dir` (XZ).
func _build_outbuilding(
	parent: Node3D, label: String, at: Vector2, door_dir: Vector2, w: int, d: int, roof: Color
) -> void:
	var shed := TownProps.build_building(
		w,d,1,roof,TownProps.WALL_STONE,TownProps.WALL_WOOD,TownProps.FLOOR_COLOR,roof.darkened(0.12),"continuous_panel",false,
		"shed",TownProps.NO_BACK_DOOR,"none"
	)
	shed.name = label
	shed.position = Vector3(at.x, _ground_y(at), at.y)
	shed.rotation.y = atan2(-door_dir.x, -door_dir.y)
	parent.add_child(shed)
	_record_solid(label, "building", at, Vector2(float(w), float(d)) * (TownProps.CELL_SIZE * 0.5), shed.rotation.y)
	_record_building_doors(label, at, shed.rotation.y, w, d, 1, "door", TownProps.NO_BACK_DOOR)


## A hedged yard. The side against the house is left open (the hedge ends at the
## wall, the back door opens straight into the yard), and the gate faces the
## path that serves it, never the house door.
func _build_hedged_yard(parent: Node3D, center: Vector2, size: Vector2, gate_side: Vector2, open_side: Vector2 = Vector2.ZERO) -> void:
	var half := size * 0.5
	var corners: Array[Vector2] = [
		center + Vector2(-half.x,-half.y), center + Vector2(half.x,-half.y),
		center + Vector2(half.x,half.y), center + Vector2(-half.x,half.y),
	]
	var ground := Callable(self, "_ground_y")
	for i in 4:
		var a := corners[i]
		var b := corners[(i + 1) % 4]
		var middle := (a + b) * 0.5
		var outward := (middle - center).normalized()
		if open_side != Vector2.ZERO and outward.dot(open_side) > 0.9:
			continue
		if outward.dot(gate_side) > 0.9:
			var along := (b - a).normalized()
			var run_a: Array[Vector2] = [a, middle - along * 1.3]
			var run_b: Array[Vector2] = [middle + along * 1.3, b]
			VillageWorks.build_hedge_run(parent, run_a, ground)
			VillageWorks.build_hedge_run(parent, run_b, ground)
			_record_run("hedge", run_a[0], run_a[1], 0.9)
			_record_run("hedge", run_b[0], run_b[1], 0.9)
		else:
			var run: Array[Vector2] = [a, b]
			VillageWorks.build_hedge_run(parent, run, ground)
			_record_run("hedge", a, b, 0.9)
	# Make the intended entrance unmistakable: two posts and an open leaf align
	# with the cottage service door and the path running through the opening.
	var gate_middle:=center+Vector2(half.x*gate_side.x,half.y*gate_side.y)
	var tangent:=Vector2(-gate_side.y,gate_side.x)
	VillageWorks.build_gate(
		parent,gate_middle-tangent*1.3,gate_middle+tangent*1.3,-gate_side,ground
	)
	_layout_gates.append({"pos": gate_middle, "dir": -gate_side, "width": 2.6})


## A village green rather than a bare traffic circle.  The compact fountain
## apron is durable masonry; the single connected worn-earth layer beneath it
## carries traffic through the green without any coplanar decal overlaps.
func _build_village_square(parent: Node3D) -> void:
	var ground:=Callable(self,"_ground_y")
	VillageWorks.build_disc_platform(parent,Vector2.ZERO,3.95,0.08,TownProps.FOUNTAIN_STONE,ground,"FountainOuterStep")
	VillageWorks.build_disc_platform(parent,Vector2.ZERO,3.3,0.17,TownProps.FOUNTAIN_STONE.lightened(0.04),ground,"FountainInnerStep")
	_build_fountain(parent,0.17)
	for corner in 4:
		var angle:=PI*0.25+PI*0.5*float(corner)
		var spot:=Vector2(cos(angle),sin(angle))*6.4
		VillageWorks.build_bench(parent,spot,Vector2.ZERO,ground)
	var board_at: Vector2 = OhioPlan.NOTICE_BOARD_AT
	VillageWorks.build_notice_board(parent,board_at,PI,TownProps.ROOF_COLORS[0],ground)
	_record_solid("NoticeBoard", "board", board_at, Vector2(0.95, 0.2), PI)
	_record_facing("NoticeBoard", "notice", board_at, PI, Vector2(0, -1))
	var game_table_at: Vector2 = OhioPlan.GREEN_GAME_TABLE_AT
	VillageWorks.build_game_table(parent, game_table_at, ground)
	_record_solid("GreenGameTable", "prop", game_table_at, Vector2(1.25, 1.5), 0.0)
	_record_solid("Fountain", "fountain", Vector2.ZERO, Vector2(4.0, 4.0), 0.0)
	_build_square_planting(parent)


func _build_square_planting(parent: Node3D) -> void:
	var tree_spots: Array[Vector2] = OhioPlan.SQUARE_TREES
	for i in tree_spots.size():
		var spot:=tree_spots[i]
		var tree:=NatureProps.build_round_tree(4.8+0.35*float(i%2),Color(0.18,0.55,0.25).lightened(0.035*float(i)))
		tree.name="VillageGreenShadeTree"
		tree.position=Vector3(spot.x,_ground_y(spot),spot.y)
		parent.add_child(tree)
	var flower_colors: Array[Color] = [Color(0.94,0.68,0.22),Color(0.76,0.35,0.52),Color(0.52,0.62,0.92),Color(0.93,0.88,0.72)]
	var beds: Array[Vector2] = OhioPlan.SQUARE_BEDS
	for bed_index in beds.size():
		# Each bed reads as one massed drift rather than five evenly spaced dots.
		for petal in 9:
			var angle:=TAU*float(petal)/9.0+0.37*float(bed_index)
			var spot:=beds[bed_index]+Vector2(cos(angle),sin(angle))*(0.34+0.13*float((petal*7)%4))
			var flower:=NatureProps.build_flower(flower_colors[(bed_index+petal)%flower_colors.size()])
			flower.position=Vector3(spot.x,_ground_y(spot)+0.015,spot.y)
			parent.add_child(flower)


func _build_kitchen_garden(parent: Node3D,center: Vector2,size: Vector2) -> void:
	var ground := Callable(self, "_ground_y")
	var bed_centres: Array[Vector2] = [
		center + Vector2(-2.05, -2.0), center + Vector2(2.05, -2.0),
		center + Vector2(-2.05, 1.7), center + Vector2(2.05, 1.7),
	]
	var crop_colors: Array[Color] = [
		Color(0.20, 0.52, 0.22), Color(0.30, 0.60, 0.24),
		Color(0.44, 0.62, 0.23), Color(0.18, 0.46, 0.20),
	]
	for bed_index in bed_centres.size():
		var bed_at := bed_centres[bed_index]
		VillageWorks.build_raised_bed(parent, bed_at, Vector2(3.0, 2.25), ground, Color(0.47, 0.31, 0.17), "KitchenCropBed")
		for row in 2:
			for plant in 3:
				var spot := bed_at + Vector2(-0.82 + float(plant) * 0.82, -0.48 + float(row) * 0.96)
				var crop := NatureProps.build_bush(crop_colors[bed_index])
				crop.scale = Vector3.ONE * (0.30 + 0.035 * float((plant + row) % 2))
				crop.position = Vector3(spot.x, _ground_y(spot) + 0.18, spot.y)
				parent.add_child(crop)
	# Water and compost sit in opposite service corners. Ivy's scarecrow watches
	# the outer beds, while a bean trellis gives the northern bed real height.
	VillageWorks.build_garden_barrel(parent, center + Vector2(-4.25, 3.25), ground)
	VillageWorks.build_compost_heap(parent, center + Vector2(4.15, 3.15), ground)
	VillageWorks.build_scarecrow(parent, center + Vector2(4.1, -3.0), ground)
	VillageWorks.build_trellis(parent, center + Vector2(-2.05, 2.65), 0.0, 2.4, 1.8, ground)


func _build_physic_garden(parent: Node3D,center: Vector2,size: Vector2) -> void:
	var ground := Callable(self, "_ground_y")
	var offsets: Array[Vector2] = [Vector2(-2.1, 0), Vector2(2.1, 0), Vector2(0, -2.05), Vector2(0, 2.05)]
	var colors: Array[Color] = [
		Color(0.62,0.42,0.78), Color(0.48,0.64,0.34),
		Color(0.88,0.72,0.24), Color(0.72,0.34,0.42),
	]
	for bed_index in offsets.size():
		var bed_at := center + offsets[bed_index]
		var bed_size := Vector2(2.7, 1.55) if absf(offsets[bed_index].x) > 0.1 else Vector2(1.55, 2.7)
		VillageWorks.build_raised_bed(parent, bed_at, bed_size, ground, Color(0.43, 0.30, 0.18), "PhysicHerbBed")
		for plant in 7:
			var angle := TAU * float(plant) / 7.0 + 0.21 * float(bed_index)
			var spread := Vector2(bed_size.x * 0.30, bed_size.y * 0.30)
			var spot := bed_at + Vector2(cos(angle) * spread.x, sin(angle) * spread.y)
			var flower := NatureProps.build_flower(colors[bed_index])
			flower.position = Vector3(spot.x, _ground_y(spot) + 0.19, spot.y)
			parent.add_child(flower)
	VillageWorks.build_bee_skep(parent, center + Vector2(-4.25, 3.2), ground)


## Trees and foundation planting mediate between buildings and open country.
## These are deliberately authored clear of doors, lanes and work yards; the
## terrain's broad settlement exclusion should not make Ohio look sterilised.
func _build_residential_landscaping(parent: Node3D) -> void:
	var orchard_colors: Array[Color] = [
		NatureProps.FRUIT_COLORS["Apple"],NatureProps.FRUIT_COLORS["Plum"],NatureProps.FRUIT_COLORS["Lemon"]
	]
	var tree_specs: Array[Dictionary] = OhioPlan.TREES
	for i in tree_specs.size():
		var spec:=tree_specs[i]
		var spot:Vector2=spec["at"]
		var tree:StaticBody3D
		if bool(spec["fruit"]):
			tree=NatureProps.build_fruit_tree(float(spec["height"]),Color(0.18,0.53,0.22),orchard_colors[i%orchard_colors.size()])
		else:
			tree=NatureProps.build_round_tree(float(spec["height"]),Color(0.16,0.50,0.23))
		tree.name="OhioGardenTree"
		tree.position=Vector3(spot.x,_ground_y(spot),spot.y)
		parent.add_child(tree)
	var shrub_spots: Array[Vector2] = OhioPlan.SHRUBS
	for i in shrub_spots.size():
		var spot:=shrub_spots[i]
		var shrub:=NatureProps.build_bush(Color(0.17,0.47+0.025*float(i%3),0.22))
		shrub.scale=Vector3.ONE*(0.52+0.05*float(i%2))
		shrub.position=Vector3(spot.x,_ground_y(spot),spot.y)
		parent.add_child(shrub)


func _build_fountain(parent: Node3D,raise: float = 0.0) -> void:
	var fountain := TownProps.build_fountain()
	var fountain_body: StaticBody3D = fountain["root"]
	fountain_body.position = Vector3(0, _ground_y(Vector2.ZERO) + raise, 0)
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
	var windmill_at: Vector2 = OhioPlan.WINDMILL_AT
	var windmill_yaw := deg_to_rad(OhioPlan.WINDMILL_YAW)
	var mill := TownProps.build_windmill()
	mill.position = Vector3(windmill_at.x, _ground_y(windmill_at), windmill_at.y)
	mill.rotation.y = windmill_yaw
	parent.add_child(mill)
	_record_solid("Windmill", "building", windmill_at, Vector2(4.0, 4.0), windmill_yaw)
	_record_door("Windmill", windmill_at, windmill_yaw, Vector2(0, -3.9), Vector2(0, -1), TownProps.DOOR_WIDTH)
	# The water wheel belongs to the sawmill and is built with the stream
	# (see _build_sawmill_wheel).


func _scatter_decorations(parent: Node3D) -> void:
	for entry in OhioPlan.FOUNTAIN_LANTERNS:
		var offset: Vector2 = entry["at"]
		_place_street_lantern(parent,"GreenLantern",offset,entry["toward"] as Vector2,Callable(self,"_ground_y"))

	_build_shop_stall(parent)


## A rectangular post-and-rail yard fence, drawn as continuous runs.
##
## Gate convention: every enclosure has a gate, set in the side that faces the
## way people and carts actually arrive (the lane, or the door it serves), the
## same 3.2 m clear width, hinged on one post and swung open inward, with its
## centre lined up with the opening it serves. A side that is a building's own
## wall is left unfenced (`open_sides`). `gates` entries are
## {"side": outward unit direction, "offset": metres along the side from its
## middle, in the direction the side is drawn (corner to next corner)}.
func _build_fenced_yard(
	parent: Node3D,center: Vector2,size: Vector2,yaw: float,
	gates: Array[Dictionary] = [],open_sides: Array[Vector2] = []
) -> void:
	assert(not gates.is_empty(),"every fenced yard needs a gate")
	var half:=size*0.5
	var ground:=Callable(self,"_ground_y")
	var corners: Array[Vector2]=[]
	for local: Vector2 in [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)]:
		corners.append(center+local.rotated(-yaw))
	for i in 4:
		var a:=corners[i]
		var b:=corners[(i+1)%4]
		var middle:=(a+b)*0.5
		var outward:=(middle-center).normalized()
		if _side_listed(outward,open_sides):
			continue
		var gate:=_gate_for_side(outward,gates)
		if gate.is_empty():
			var run: Array[Vector2]=[a,b]
			VillageWorks.build_fence_run(parent,run,ground)
			_record_run("fence",a,b)
			continue
		var along:=(b-a).normalized()
		var gate_center:=middle+along*float(gate.get("offset",0.0))
		var gate_a:=gate_center-along*1.6
		var gate_b:=gate_center+along*1.6
		var first: Array[Vector2]=[a,gate_a]
		var second: Array[Vector2]=[gate_b,b]
		VillageWorks.build_fence_run(parent,first,ground)
		VillageWorks.build_fence_run(parent,second,ground)
		VillageWorks.build_gate(parent,gate_a,gate_b,-outward,ground)
		_record_run("fence",a,gate_a)
		_record_run("fence",gate_b,b)
		_layout_gates.append({"pos": gate_center, "dir": -outward, "width": 3.2})


func _side_listed(side: Vector2,sides: Array[Vector2]) -> bool:
	for listed in sides:
		if listed.dot(side)>0.9:
			return true
	return false


func _gate_for_side(side: Vector2,gates: Array[Dictionary]) -> Dictionary:
	for gate in gates:
		if (gate["side"] as Vector2).dot(side)>0.9:
			return gate
	return {}


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
# How far below CloudScatter's own altitude_min the cloud-step spiral
# stops, handing off to build_sky_course()'s own puff-based continuation --
# enough clearance that the last step doesn't visually poke through the
# ambient cloud layer's own lowest puffs.
const SKY_STAIRS_CLOUD_MARGIN := 6.0


## Scatters small parkour clusters -- crate staircases -- around the open
## ground between buildings. Purely optional climbing, not required to reach anything. Uses its own
## RandomNumberGenerator rather than this script's shared _rng (seeded
## once in _rebuild() and consumed in a fixed order by the NPC variant
## shuffles below) -- sharing it would shift every draw after this call,
## silently changing which hair/skin/outfit combination each NPC gets.
func _scatter_platforming(parent: Node3D) -> void:
	var occupied: Array[Vector2] = []
	for building in OhioPlan.BUILDINGS:
		occupied.append(building["at"])
	for stall: Dictionary in OhioPlan.STALLS.values():
		occupied.append(stall["at"])
	occupied.append(OhioPlan.WINDMILL_AT)
	occupied.append(OhioPlan.FALSE_HERO_AT)
	for entry in OhioPlan.FOUNTAIN_LANTERNS:
		occupied.append(entry["at"])

	# Authored structures that are not buildings (inn, stream, yards) also keep
	# the scatter clear.
	occupied.append(INN_LOCAL)
	for point in _course:
		occupied.append(point)
	occupied.append(POND_CENTER)
	for point in [
		OhioPlan.GRAIN_YARD["center"], OhioPlan.VEY_STOREHOUSE_AT, OhioPlan.KITCHEN_GARDEN["center"],
		OhioPlan.DRYING_SHED_AT, OhioPlan.PHYSIC_GARDEN["center"], OhioPlan.STONE_YARD_AT, MILL_CENTER,
		OhioPlan.OVERLOOK["at"], OhioPlan.ENTRANCE["center"], OhioPlan.ENTRANCE["sign"],
	]:
		occupied.append(point)
	for point in OhioPlan.TIMBER_RACKS:
		occupied.append(point)
	for pile in OhioPlan.LOG_PILES:
		occupied.append(pile["at"])

	var rng := RandomNumberGenerator.new()
	rng.seed = 5150

	# Upper floors now have real internal ramp wells; the old exterior roof
	# ramps contradicted that circulation and are deliberately retired.

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


## A zigzagging sequence of freestanding crates climbing away from the
## ground -- pure jump-to-jump parkour, no ramp, so (unlike
## the retired roof ramps) this one's player-only. Each step rises at
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
	_parent: Node3D, occupied: Array[Vector2], placed: Array[Vector2], rng: RandomNumberGenerator
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

	# Per direct correction ("shift it back to start at the peak of the
	# nearby hill, not near the bottom") -- the terrain here is naturally
	# undulating rather than flat, and the anchor found above can land
	# partway up a slope. Search a couple of rings around it for the
	# actual local high point instead of just sampling the anchor itself.
	const HILL_SEARCH_RADII: Array[float] = [11.0, 22.0]
	const HILL_SEARCH_SAMPLES := 14
	var peak := anchor
	var peak_height := _ground_y(anchor)
	for sample_index in HILL_SEARCH_SAMPLES:
		var sample_angle := TAU * float(sample_index) / float(HILL_SEARCH_SAMPLES)
		for sample_radius in HILL_SEARCH_RADII:
			var sample_point := anchor + Vector2(cos(sample_angle), sin(sample_angle)) * sample_radius
			var sample_height := _ground_y(sample_point)
			if sample_height > peak_height:
				peak_height = sample_height
				peak = sample_point
	anchor = peak

	var pos := Vector3(town_center.x + anchor.x, peak_height, town_center.y + anchor.y)
	var heading := rng.randf_range(0.0, TAU)
	var target_y := clouds.altitude_min - SKY_STAIRS_CLOUD_MARGIN
	# Per direct correction ("actual cloud material, not solid material the
	# color of clouds... doesn't seem to have the same physics as clouds you
	# can't pass through them from the sides") -- each step used to be its
	# own StaticBody3D box under this scene's own parent, which is ordinary
	# solid Godot physics colliding from every side. Real clouds have NO
	# physics collider at all: CloudScatter.get_support_height_at() is a
	# purely analytic one-way query (see player.gd's own
	# _cloud_stand_height_at()), and only works on puffs actually parented
	# under the CloudScatter node itself. build_stair_step() below hands each
	# step's world position to that sibling node so it's built (and owns
	# its own single shared BirdHelmGate, "SkyStairsGate") the exact same
	# way as every other standable cloud, instead of a lookalike collider
	# living in the wrong part of the tree.
	clouds.reset_stair_steps()
	# The safety cap only guards against a future altitude_min/margin change
	# making this loop unreasonably long -- at the established rise range it
	# never comes close in practice (~55-65 steps to reach a typical ~65m
	# climb).
	var step_index := 0
	while pos.y < target_y and step_index < 200:
		var rise := rng.randf_range(0.9, MAX_STEP_RISE)
		var gap := rng.randf_range(1.8, 2.6)
		heading += SKY_STAIRS_TURN + rng.randf_range(-0.05, 0.05)
		pos += Vector3(sin(heading) * gap, rise, cos(heading) * gap)
		clouds.build_stair_step(pos, rng)
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
			"spot": "gem",
			"canopy_color": TownProps.ROOF_COLORS[0],
			"category": "antique",
			"item_positions": ANTIQUE_STALL_POSITIONS,
			"vendor_name": "Aldren Vey",
			"vendor_lines": [
				"The compass came from a road surveyor. The road no longer exists, and the compass refuses to admit it.",
				"The locket is sealed. That is provenance, not a defect.",
				"Halda records every object I bring through town. She records my account of it separately.",
			],
			"vendor_skin": Color(0.7, 0.5, 0.36),
			"vendor_shirt": Color(0.32, 0.24, 0.16),
			"vendor_hair": Color(0.85, 0.78, 0.7),
			"vendor_hair_style": FigureHair.STYLE_BUZZCUT,
		},
		{
			"spot": "red",
			"canopy_color": TownProps.ROOF_COLORS[0],
			"category": "red",
			"item_positions": RED_STALL_POSITIONS,
			"vendor_name": "Brinna Kest",
			"vendor_lines": [
				"The breastplate is dented, not cracked. I charge for the metal it still has, not the shape it lost.",
				"I tested the sword this morning. It cuts. Your grip is your own responsibility.",
				"Cob pays for mill iron in flour. Flour is harder to stack than coin.",
			],
			"vendor_skin": Color(0.62, 0.44, 0.3),
			"vendor_shirt": Color(0.3, 0.13, 0.11),
			"vendor_hair": Color(0.15, 0.13, 0.1),
			"vendor_hair_style": FigureHair.STYLE_FLAT_TOP,
		},
		{
			"spot": "green",
			"canopy_color": TownProps.ROOF_COLORS[1],
			"category": "green",
			"item_positions": GREEN_STALL_POSITIONS,
			"vendor_name": "Nell Barrow",
			"vendor_lines": [
				"Tess carried the morning loaves without dropping one. She will mention this until supper.",
				"Cheese keeps. Berries keep if you leave the bag tied. Bread keeps if Mira stops serving it warm.",
				"Ivy's slime jars sit at the end of the board. She doesn't pay for the space, so I keep the cut.",
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
	var spot: Dictionary = OhioPlan.STALLS[config["spot"]]
	var offset: Vector2 = spot["at"]
	var stall_yaw := deg_to_rad(float(spot["yaw"]))
	var stall: Dictionary = (
		TownProps.build_armorer_stall(config["canopy_color"])
		if config["category"] == "red"
		else TownProps.build_stall(config["canopy_color"])
	)
	var stall_body: StaticBody3D = stall["body"]
	stall_body.position = Vector3(offset.x, _ground_y(offset), offset.y)
	stall_body.rotation.y = stall_yaw
	parent.add_child(stall_body)
	var stall_half := Vector2(1.5, 0.6) if config["category"] == "red" else Vector2(0.65, 0.5)
	_record_solid(str(config["vendor_name"]) + "'s stall", "stall", offset, stall_half, stall_yaw)
	_record_facing(str(config["vendor_name"]) + "'s stall", "stall", offset, stall_yaw, Vector2(0, 1))

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

	# Shared stall blocking keeps every seller clear of the counter and beside
	# the wares, facing the customer approach. Equipment stalls merely provide
	# their wider physical footprint to the same rule.
	var counter_half_width:=1.45 if config["category"]=="red" else 0.6
	var vendor_layout:=TownProps.vendor_layout(offset,stall_yaw,counter_half_width)
	var vendor_offset:=vendor_layout["position"] as Vector2
	if Engine.is_editor_hint():
		return
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		push_warning("Missing NPC scene: " + NPC_SCENE)
		return
	var vendor = packed.instantiate()
	vendor.set_terrain_reference(terrain)
	# Hand-set, not _assign_figure_variant() -- that function draws from
	# the shuffled resident pools, guaranteeing no two of them repeat during
	# the first pass. Routing the
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
	vendor.facing_degrees = vendor_layout["facing_degrees"] as float
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
