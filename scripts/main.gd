extends Node3D

## Let the persistent loading overlay survive world construction, then give
## the renderer one frame with the completed scene before fading it away.
## Also builds the three kingdom-portal gates (see portal.gd) and, when this
## load is a portal arrival rather than the initial boot (see
## kingdom_travel.gd's pending_gate_id), places the returning player/party
## at the matching gate instead of the scene's baked default spawn.

const CITY_KINGDOM_SCENE := "res://scenes/city_kingdom.tscn"
const PRIMATE_KINGDOM_SCENE := "res://scenes/primate_kingdom.tscn"
const OCEAN_KINGDOM_SCENE := "res://scenes/ocean_kingdom.tscn"
const MANCHEGO_SCENE := "res://scenes/manchego.tscn"
## TEMP debug aid, per direct instruction -- spawns Manchego right next to
## the player at boot so his rig/coloring/gait can be reviewed before the
## real Primate Kingdom curse-quest reward that's actually supposed to grant
## him exists yet (see docs/world_bible.md's own Mounts section). Flip this
## false (or delete _debug_spawn_manchego()'s call site below) once that real
## acquisition flow is built and this placement is no longer needed.
const DEBUG_SPAWN_MANCHEGO_NEAR_PLAYER := true

const XIAO_HOU_ZI_SCENE := "res://scenes/xiao_hou_zi.tscn"
## TEMP debug aid, per direct instruction ("give me xiao hou zi in my party
## too right now for debug") -- spawns him right next to the player at boot,
## already in_party = true, so he's available to test with (switch_blorbus
## cycling, riding Manchego, etc.) without the real Primate Kingdom curse
## quest that's actually supposed to recruit him. Flip this false (or delete
## _debug_spawn_xiao_hou_zi()'s call site below) once that real recruitment
## flow is what's being tested instead.
const DEBUG_SPAWN_XIAO_HOU_ZI_NEAR_PLAYER := true

const APE_TEMPLATE_PREVIEW_SCENE := "res://scenes/ape_template_preview.tscn"
const JUNGLE_VILLAGER_SCENE := "res://scenes/jungle_villager.tscn"
## Same idea as DEBUG_SPAWN_MANCHEGO_NEAR_PLAYER above -- spawns a mix of
## ApeTemplatePreview instances right next to the player at boot, in the
## crossroads rather than the Primate Kingdom, so pose/proportions AND the
## color/scale/body-type variance a future NPC-generation system would
## produce can both be reviewed without a portal trip. Per direct
## instruction, this is specifically ApeTemplate's OWN two classes (apes,
## has_tail=false, and "primate template" monkeys, has_tail=true -- NOT
## the separate "stuffed animal monkey" class jungle_villager.gd builds,
## which an earlier version of this mix used by mistake), half and half,
## PLUS a couple of real stuffed animal monkeys per a further direct
## instruction ("you can drop one or two... in there too") -- see
## docs/world_bible.md's own Primate taxonomy note for why these are three
## distinct things. Flip false (or delete _debug_spawn_primates()'s call
## site below) once real ape/monkey species replace ApeTemplate's own
## template-preview stand-in.
const DEBUG_SPAWN_PRIMATES_NEAR_PLAYER := true
const CAT_TEMPLATE_PREVIEW_SCENE := "res://scenes/cat_template_preview.tscn"
## Four coat variants are placed at boot for template review; alternating
## cats use the fully grounded, chin-down, whole-body curled resting pose.
const DEBUG_SPAWN_CATS_NEAR_PLAYER := true
const CAT_DEBUG_SPAWN_COUNT := 4
const PRIMATE_TEMPLATE_DEBUG_SPAWN_COUNT := 5
const STUFFED_ANIMAL_MONKEY_DEBUG_COUNT := 2
const PRIMATE_DEBUG_SPAWN_SPACING := 1.8
## Smaller than JungleVillager's own default roam_radius (14.0) -- per
## direct instruction this is meant to be a tight debug cluster next to
## the player, not full free-roam wandering.
const PRIMATE_DEBUG_ROAM_RADIUS := 8.0
## Same "dark charcoal to grey to light grey to shades of brown" range
## jungle_villager.gd's own FUR_COLORS uses (and the same dark-face-on-
## light-fur chance logic below), reused here rather than re-derived so
## the debug spread reads like a believable preview of what the real
## NPC-generation system would later produce.
const APE_DEBUG_FUR_COLORS := [
	Color(0.14, 0.13, 0.13),
	Color(0.22, 0.21, 0.21),
	Color(0.42, 0.41, 0.40),
	Color(0.62, 0.61, 0.59),
	Color(0.55, 0.42, 0.28),
	Color(0.40, 0.28, 0.16),
	Color(0.26, 0.18, 0.11),
]
## Per direct instruction: apes have a minimum size, monkeys a maximum,
## without much overlap between the two classes -- ApeTemplate builds
## BOTH now (has_tail toggles which), so this split lives entirely within
## its own display_scale range rather than being a difference between two
## separate rigs' own "scale" units. ApeTemplate is built on
## ProceduralFigure, whose own scale=1.0 reference height comes out to
## roughly 2m (working through build()'s own neck_y/HEAD_SIZE/HEAD_RAISE
## chain). APE_DEBUG_SCALE_MIN reads as roughly 1.7m tall; PRIMATE_
## TEMPLATE_MONKEY_SCALE_MAX reads as roughly 1.4m -- below that, with
## still-real (if narrower) room to spare. Raised from an initial 0.35-0.55
## per direct feedback the monkeys were reading too small. (jungle_
## villager.gd's own stuffed animal monkeys are smaller again, roughly
## 0.6-0.8m at ITS own DISPLAY_SCALE_MAX -- see that constant's own doc
## comment -- but that class isn't part of this same size contract at
## all, just smaller as it happens.)
const APE_DEBUG_SCALE_MIN := 0.85
const APE_DEBUG_SCALE_MAX := 1.25
const PRIMATE_TEMPLATE_MONKEY_SCALE_MIN := 0.5
const PRIMATE_TEMPLATE_MONKEY_SCALE_MAX := 0.7
## Ape-only, per direct instruction ("monkeys should not get the mesomorph
## body type, only apes can") -- ApeTemplate.build() only reads body_type
## into chest_build_scale/abdomen_width_scale, both hardcoded to their own
## neutral 1.0 whenever has_tail is true (see that function's own body),
## so this is enforced structurally rather than left to this file to
## remember not to set. Spread evenly across the ape instances below (not
## drawn independently at random per instance) so a small debug batch
## reliably shows the full range instead of maybe clustering by chance --
## see _debug_spawn_primates()'s own comment.
const APE_DEBUG_BODY_TYPE_MIN := 0.0
const APE_DEBUG_BODY_TYPE_MAX := 1.0
## Range for a variant's own head_height_scale, per direct instruction
## ("allow their heads to grow up into tall heads in some variants, in a
## range") -- 1.0 is ApeTemplate's own established default head
## proportions.
const APE_DEBUG_HEAD_HEIGHT_SCALE_MIN := 1.0
const APE_DEBUG_HEAD_HEIGHT_SCALE_MAX := 1.4

# Same CITY_CENTER city_generator.gd defines for itself, pulled out to its
# own southern edge so the gate doesn't land inside a generated building.
const CITY_GATE_XZ := Vector2(-540.0, 95.0)
# Same JUNGLE_PLATEAU_CENTER terrain_generator.gd defines (plateau radius
# 70), pulled toward the plateau's near edge -- the side a player actually
# climbs up from.
const PRIMATE_GATE_XZ := Vector2(-500.0, 409.0)
# The ocean gate has no XZ/ground-height constant of its own -- it stands on
# the fishing village's own small portal dock (see floating_village.gd's
# get_portal_anchor()), so it reads as part of that settlement rather than
# a lone gate out on the shore.

var _portals_by_gate_id: Dictionary = {}


func _ready() -> void:
	_build_portals()
	call_deferred("_finish_loading")


func _finish_loading() -> void:
	await get_tree().process_frame
	_place_returning_player()
	if DEBUG_SPAWN_MANCHEGO_NEAR_PLAYER:
		_debug_spawn_manchego()
	if DEBUG_SPAWN_XIAO_HOU_ZI_NEAR_PLAYER:
		_debug_spawn_xiao_hou_zi()
	if DEBUG_SPAWN_PRIMATES_NEAR_PLAYER:
		_debug_spawn_primates()
	if DEBUG_SPAWN_CATS_NEAR_PLAYER:
		_debug_spawn_cats()
	LoadingScreen.complete()


## See DEBUG_SPAWN_MANCHEGO_NEAR_PLAYER's own comment above. Placed a couple
## meters off to the player's side rather than directly in front, so he
## isn't blocking the player's own starting-field view on load.
func _debug_spawn_manchego() -> void:
	var packed := load(MANCHEGO_SCENE) as PackedScene
	if packed == null:
		return
	var player := get_node("Player")
	var terrain: Node = get_node("Terrain")
	var manchego: Manchego = packed.instantiate()
	var spawn_pos: Vector3 = player.global_position + Vector3(2.8, 0, -1.4)
	spawn_pos.y = terrain.get_mesh_height(spawn_pos.x, spawn_pos.z)
	# add_child() first -- a freshly instantiated node isn't in the scene
	# tree yet, so setting global_position before this (as an earlier
	# version did) fails: Node3D can't resolve a global transform without a
	# parent to compose against, and Godot logs exactly that
	# ("!is_inside_tree()") rather than silently doing the wrong thing.
	add_child(manchego)
	manchego.global_position = spawn_pos


## See DEBUG_SPAWN_XIAO_HOU_ZI_NEAR_PLAYER's own comment above. Straight
## ahead of the player (+Z... actually -Z, this project's own established
## "forward" per every other debug spawn's own -1.4 Z offset) rather than to
## either side, so he doesn't overlap Manchego's (+2.8 x) or the primate
## cluster's (-2.8 x) own debug placements.
func _debug_spawn_xiao_hou_zi() -> void:
	var packed := load(XIAO_HOU_ZI_SCENE) as PackedScene
	if packed == null:
		return
	var player := get_node("Player")
	var terrain: Node = get_node("Terrain")
	var monkey: XiaoHouZi = packed.instantiate()
	var spawn_pos: Vector3 = player.global_position + Vector3(0, 0, -3.5)
	spawn_pos.y = terrain.get_mesh_height(spawn_pos.x, spawn_pos.z)
	# add_child() first -- see _debug_spawn_manchego()'s own identical
	# comment for why (global_position can't resolve before the node is
	# actually in the tree).
	add_child(monkey)
	monkey.global_position = spawn_pos
	monkey.in_party = true


## See DEBUG_SPAWN_PRIMATES_NEAR_PLAYER's own comment above. Opposite side
## from Manchego (-2.8 x rather than +2.8) so the two debug placements
## don't overlap each other; every instance below is then lined up along
## -Z from there in spawn order so none of them overlap each other either.
##
## First PRIMATE_TEMPLATE_DEBUG_SPAWN_COUNT ApeTemplatePreview instances,
## alternating has_tail by index (per direct instruction, "half be apes
## half be monkeys" -- an odd total rounds up to one extra ape; has_tail
## false = ape, true = ApeTemplate's own "primate template" monkey, NOT
## jungle_villager.gd's separate stuffed animal monkey class, per a direct
## correction that an earlier version of this mix used the wrong one).
## Apes get their body_type spread EVENLY across APE_DEBUG_BODY_TYPE_MIN..
## MAX (not drawn independently at random per instance) so a small debug
## batch reliably shows the full ectomorph-to-mesomorph range instead of
## maybe clustering together by chance, per direct instruction ("span a
## variety of the body types"); monkeys never get a body_type at all (see
## that constant's own doc comment -- ApeTemplate.build() enforces this
## itself now, so this function doesn't set body_type for monkey instances
## at all rather than setting-then-having-it-ignored). Monkeys also use
## PRIMATE_TEMPLATE_MONKEY_SCALE_MIN/MAX (smaller, see that constant's own
## doc comment) instead of the ape range.
##
## THEN a further STUFFED_ANIMAL_MONKEY_DEBUG_COUNT real JungleVillager
## instances, continuing the same -Z line, per a further direct
## instruction ("you can drop one or two [stuffed animal monkeys] in there
## too").
##
## Every ApeTemplatePreview @export is set BEFORE add_child() -- its
## _ready() reads them synchronously on entering the tree, so setting them
## after would be too late. JungleVillager instead randomizes its own fur/
## marking/scale entirely internally in ITS _ready() (no external override
## exists for those), but its OWN _ready() also reads global_position.x/z
## synchronously to ground-snap itself -- so THIS file has to set the
## spawn position via the ordinary local `.position` (safe before entering
## the tree, unlike `.global_position`) before add_child instead, the
## opposite order from every other debug spawn in this file.
func _debug_spawn_primates() -> void:
	var packed_ape := load(APE_TEMPLATE_PREVIEW_SCENE) as PackedScene
	var packed_monkey := load(JUNGLE_VILLAGER_SCENE) as PackedScene
	if packed_ape == null or packed_monkey == null:
		return
	var player := get_node("Player")
	var terrain: Node = get_node("Terrain")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var ape_count := int(ceil(float(PRIMATE_TEMPLATE_DEBUG_SPAWN_COUNT) * 0.5))
	var ape_index := 0
	var spawn_index := 0
	for i in PRIMATE_TEMPLATE_DEBUG_SPAWN_COUNT:
		var spawn_pos: Vector3 = player.global_position + Vector3(
			-2.8, 0, -1.4 - float(spawn_index) * PRIMATE_DEBUG_SPAWN_SPACING
		)
		spawn_pos.y = terrain.get_mesh_height(spawn_pos.x, spawn_pos.z)
		spawn_index += 1
		var preview := packed_ape.instantiate() as ApeTemplatePreview
		preview.fur_color = APE_DEBUG_FUR_COLORS[rng.randi() % APE_DEBUG_FUR_COLORS.size()]
		preview.marking_color = MonkeyFigure.MARKING_COLOR_PALETTE[
			rng.randi() % MonkeyFigure.MARKING_COLOR_PALETTE.size()
		]
		preview.head_height_scale = rng.randf_range(
			APE_DEBUG_HEAD_HEIGHT_SCALE_MIN, APE_DEBUG_HEAD_HEIGHT_SCALE_MAX
		)
		if i % 2 == 0:
			preview.has_tail = false
			preview.display_scale = rng.randf_range(APE_DEBUG_SCALE_MIN, APE_DEBUG_SCALE_MAX)
			var body_type_t := float(ape_index) / float(maxi(ape_count - 1, 1))
			preview.body_type = lerpf(APE_DEBUG_BODY_TYPE_MIN, APE_DEBUG_BODY_TYPE_MAX, body_type_t)
			ape_index += 1
		else:
			preview.has_tail = true
			preview.display_scale = rng.randf_range(
				PRIMATE_TEMPLATE_MONKEY_SCALE_MIN, PRIMATE_TEMPLATE_MONKEY_SCALE_MAX
			)
		add_child(preview)
		preview.global_position = spawn_pos
	for _j in STUFFED_ANIMAL_MONKEY_DEBUG_COUNT:
		var spawn_pos: Vector3 = player.global_position + Vector3(
			-2.8, 0, -1.4 - float(spawn_index) * PRIMATE_DEBUG_SPAWN_SPACING
		)
		spawn_pos.y = terrain.get_mesh_height(spawn_pos.x, spawn_pos.z)
		spawn_index += 1
		var villager := packed_monkey.instantiate() as JungleVillager
		villager.position = spawn_pos
		villager.roam_center = Vector2(spawn_pos.x, spawn_pos.z)
		villager.roam_radius = PRIMATE_DEBUG_ROAM_RADIUS
		add_child(villager)


func _debug_spawn_cats() -> void:
	var packed := load(CAT_TEMPLATE_PREVIEW_SCENE) as PackedScene
	if packed == null:
		return
	var player := get_node("Player")
	var terrain: Node = get_node("Terrain")
	for i in CAT_DEBUG_SPAWN_COUNT:
		var cat := packed.instantiate() as CatTemplatePreview
		cat.coat_color = CatFigure.COAT_COLORS[i % CatFigure.COAT_COLORS.size()]
		cat.resting = i % 2 == 1
		cat.sitting = i == 2
		var spawn_pos: Vector3 = player.global_position + Vector3(
			4.3 + float(i % 2) * 0.9, 0, -1.2 - float(i / 2) * 1.1
		)
		spawn_pos.y = terrain.get_mesh_height(spawn_pos.x, spawn_pos.z)
		# CatTemplatePreview captures its roam center in _ready(), so seed its
		# ordinary local position before it enters the tree.
		cat.position = spawn_pos
		add_child(cat)


func _build_portals() -> void:
	var terrain: Node = get_node("Terrain")
	var city_h: float = terrain.get_mesh_height(CITY_GATE_XZ.x, CITY_GATE_XZ.y)
	var primate_h: float = terrain.get_mesh_height(PRIMATE_GATE_XZ.x, PRIMATE_GATE_XZ.y)
	_add_portal("city_kingdom", CITY_KINGDOM_SCENE, Vector3(CITY_GATE_XZ.x, city_h, CITY_GATE_XZ.y), Color(0.75, 0.68, 0.42))
	_add_portal("primate_kingdom", PRIMATE_KINGDOM_SCENE, Vector3(PRIMATE_GATE_XZ.x, primate_h, PRIMATE_GATE_XZ.y), Color(0.36, 0.6, 0.32))
	var village: Node = get_node("FloatingWaterVillage")
	_add_portal("ocean_kingdom", OCEAN_KINGDOM_SCENE, village.get_portal_anchor(), Color(0.2, 0.56, 0.66))


func _add_portal(gate_id: String, destination_scene: String, world_position: Vector3, accent_color: Color) -> void:
	var portal := Portal.new()
	portal.name = "Portal_%s" % gate_id
	portal.destination_scene = destination_scene
	portal.gate_id = gate_id
	portal.accent_color = accent_color
	portal.position = world_position
	add_child(portal)
	_portals_by_gate_id[gate_id] = portal


## Only does anything on a load that followed a kingdom portal trip (see
## kingdom_travel.gd) -- an ordinary boot leaves pending_gate_id empty and
## the scene's own baked Player/Blorb1-3 transforms are used untouched, same
## as before this system existed.
func _place_returning_player() -> void:
	var gate_id := KingdomTravel.pending_gate_id
	KingdomTravel.pending_gate_id = ""
	if gate_id == "" or not _portals_by_gate_id.has(gate_id):
		return
	var portal: Node3D = _portals_by_gate_id[gate_id]
	var player := get_node("Player")
	var facing := portal.global_transform.basis.z
	player.global_position = portal.global_position - facing * 3.0
	Party.spawn_into(self, player.global_position, facing)
