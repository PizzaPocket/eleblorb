extends StaticBody3D

## The game's first named, story antagonist -- a false idol posing as
## "Hero of the Village and Savior of Earth" while secretly working against
## the player (see docs/world_bible.md's own Setting/Aggros entries). Talking
## to him in town starts a real boss fight: unlike every other NME, the
## PLAYER fights him directly with their own worn blorb-suit powers (see
## player.gd), and he fights back the same way -- alternating water-leg
## hover, fire-arm hover, and a single-arm flamethrower.
##
## Gated entirely by WorldState.false_hero_should_appear() (see that
## function's own doc comment) -- town_generator.gd only ever spawns him
## once Blorbus has awakened and the party could fill a real blorb suit of
## its own; before that, or after he's been defeated, he simply isn't
## spawned and villagers keep their ordinary, unrelated dialogue. Defeat is
## permanent (WorldState.false_hero_defeated) -- a one-time story beat, not
## a repeatable encounter.
##
## Built on ProceduralFigure directly (the same rig family as the player/
## villagers), not npc.gd -- he needs a combat state machine and a
## dialog-triggered fight that plain npc.gd has no hook for.

## Per direct instruction: every segment skin-colored except the hips,
## which are off-white -- his "hero" getup is entirely the blorb suit worn
## over this base body, so the underlying model already looks like this
## (see _strip_suit()'s own comment for why that pays off at defeat).
const SKIN_COLOR := Color(0.82, 0.62, 0.46)
const UNDERWEAR_COLOR := Color(0.92, 0.9, 0.86)
## Shown as the dialogue speaker name -- per direct correction, "False
## Hero" is this script's own internal/dev-facing name, not something the
## player has any way to know yet at this point in the story. The question
## mark reads as the player's own dawning suspicion of a title he's
## claiming for himself before he's actually earned it -- foreshadowing
## WorldState.player_title, the real version of this same title, which the
## player earns for real once he's exposed (see _process_fleeing()).
const DISPLAY_NAME := "Savior of the Village(?)"
const BOAST_LINE := "Fear not! I am the Hero of the Village, Savior of Earth -- and you, stranger, reek of the Demon King's own mirror world."
const CHALLENGE_ACTION_LABEL := "You're the real villain here."

## Per direct instruction: "way more HP... way more XP" than any existing
## NME (skeleton_ape_nme.gd's own 70/40, itself already above the ordinary
## skeleton's 40/24) -- first-pass numbers, tunable on report.
const MAX_HP := 220.0
const XP_REWARD := 150

const MOVE_SPEED := 2.6
const ROTATION_SPEED := 5.0
const WALK_SWING_SPEED := 6.0
const WALK_SWING_AMOUNT := 0.55
const POSE_SETTLE_SPEED := 8.0
## See player.gd's own SPINE_LEAN_MAX_WALK / npc.gd's own SPINE_LEAN_MAX --
## same forward-lean-while-walking treatment as every other ProceduralFigure
## rig in the game ("leverage the Hero's" own walk cycle, per direct
## instruction), rather than the bare leg-swing-only cycle this used before.
const SPINE_LEAN_MAX := deg_to_rad(3.0)
const ATTACK_RANGE := 7.0
## Base rate before combat_math.gd's own Strength scaling (he has no
## Strength stat, so this passes strength=0 -- see _process_flamethrower_
## phase()) and type-multiplier -- his sustained flamethrower stream is his
## one real damage source, not a discrete swing.
const FLAMETHROWER_DAMAGE_PER_SECOND := 9.0

## Per direct instruction: he "remain[s] in the vicinity of the village,
## not chase you outside the village perimeter." Comfortably past
## town_generator.gd's own scattered-prop radii so he can still chase
## across the whole plaza, but gives up well short of open wasteland.
const TOWN_LEASH_RADIUS := 60.0

enum State { BOASTING, FIGHTING, DEFEATED_FLEEING }
enum CombatPhase { FLAMETHROWER, WATER_HOVER, FIRE_HOVER }

## Randomized ranges rather than fixed durations, and the chain chances
## below -- per direct instruction ("more dynamic and fluid... aggressive"),
## replacing the original fixed-length flamethrower/hover/flamethrower
## metronome with a cycle that varies beat to beat and sometimes strings
## multiple flamethrower or hover beats together in a row.
const FLAMETHROWER_DURATION_MIN := 2.0
const FLAMETHROWER_DURATION_MAX := 3.2
const HOVER_DURATION_MIN := 1.1
const HOVER_DURATION_MAX := 1.8
## Chance a finished flamethrower burst immediately fires again from the
## other arm instead of dropping into a hover -- an aggressive back-to-back
## attack rather than always giving the player a breather.
const CHAIN_FLAMETHROWER_CHANCE := 0.35
## Chance a finished hover beat chains directly into the OTHER hover type
## instead of always returning to the flamethrower -- keeps the reposition
## beats from reading as a fixed single-hop interlude.
const CHAIN_HOVER_CHANCE := 0.3
const HOVER_HEIGHT := 2.4
const HOVER_LERP_SPEED := 2.0
## How aggressively he closes distance while hovering -- a full multiple of
## MOVE_SPEED, applied unconditionally (not just when far), so a hover beat
## reads as a purposeful strike toward the target rather than an idle drift.
const HOVER_APPROACH_SPEED_SCALE := 1.3
const FLEE_SPEED := 3.4
## How far outside town he has to get before the skeleton catches him and
## this instance is done -- see _process_fleeing()'s own comment.
const FLEE_DISTANCE := 24.0

var terrain_ref: Node = null
var town_center: Vector2 = Vector2.ZERO

var _state: State = State.BOASTING
var _combat_phase: CombatPhase = CombatPhase.FLAMETHROWER
var _phase_elapsed: float = 0.0
## Rolled fresh each time a phase begins (see _advance_phase()/_begin_fight())
## rather than a fixed constant -- see FLAMETHROWER_DURATION_MIN's own
## comment on why this varies.
var _phase_duration: float = 0.0
var _hover_arm_side_is_left: bool = true
var _target: Node3D = null
var _rest_y: float = 0.0
var _hover_base_y: float = 0.0
var _walk_phase: float = 0.0
var _flee_direction: Vector2 = Vector2.ZERO
var _flee_traveled: float = 0.0
var _consuming_triggered: bool = false
var current_hp: float = MAX_HP

var _rng := RandomNumberGenerator.new()
var _xp_participants: Dictionary = {}

## Electric's own stun / City's own haste-weaken -- see skeleton_nme.gd's
## identical fields for the full reasoning (same combat_math.gd tuning,
## same refresh-to-max semantics).
var _stun_remaining: float = 0.0
var _haste_weaken_remaining: float = 0.0

var _pivots: Dictionary = {}
var _suit_pieces: Array[Node3D] = []
## The False Hero does not need the player's equip/inventory controller, but
## his multi-joint arm and leg coverings still need that controller's core
## behavior: rebuild their tube from the rig's live joint transforms every
## frame. Each entry retains the cosmetic source Blorb because rebuild_slot()
## reads its current body/element appearance while generating the mesh.
var _dynamic_suit_entries: Array[Dictionary] = []
var _hips_mesh: MeshInstance3D = null

var _leg_left: Node3D
var _leg_right: Node3D
var _arm_left: Node3D
var _arm_right: Node3D
var _elbow_left: Node3D
var _elbow_right: Node3D
var _knee_left: Node3D
var _knee_right: Node3D
var _hand_left: Node3D
var _hand_right: Node3D
var _spine: Node3D
var _hips: Node3D
## Cached rest heights the walk cycle's own body-dip bobs around -- see
## npc.gd's identical _spine_rest_y/_hips_rest_y fields for why this can't
## just assume 0.0 (each pivot's own rest position already includes body-
## scale/build offsets baked in by ProceduralFigure.build()).
var _spine_rest_y: float = 0.0
var _hips_rest_y: float = 0.0

var _flamethrower_stream: GPUParticles3D = null

@onready var visuals: Node3D = $Visuals


func set_terrain_reference(world_terrain: Node) -> void:
	terrain_ref = world_terrain


func _ready() -> void:
	# NOT add_to_group("skeletons") yet -- see _begin_fight()'s own comment.
	# Until the fight actually starts he must read as a friendly to every
	# system that scans that group: free-roaming blorbs' own aggro
	# (_find_nearest_skeleton()) and the player's stream/rock/plant damage
	# scans all key off group membership alone, so simply staying out of the
	# group is what keeps him un-attackable and un-noticed pre-fight (his
	# own take_damage() also independently no-ops outside State.FIGHTING, as
	# a second guard).
	add_to_group("false_hero")
	_rng.randomize()
	if terrain_ref == null:
		terrain_ref = get_node("../../Terrain")
	# terrain_ref is always terrain_generator.gd's own TerrainGenerator --
	# False Hero only ever spawns in the main outskirts town (see this
	# file's own class doc comment on the WorldState gating), never a
	# kingdom scene with a different terrain script, so this direct access
	# matches skeleton_spawner.gd's own identical, unguarded town_center read.
	town_center = terrain_ref.town_center
	_build_figure()
	_build_suit()
	_rest_y = terrain_ref.get_mesh_height(global_position.x, global_position.z)
	Interactable.attach(self, "Talk", 2.2, _on_talk)


func _build_figure() -> void:
	# Tallest + the mesomorph/"hunky" extreme this rig supports -- per
	# direct instruction ("tallest body type and the hunky muscly body
	# type"). chest_build_scale/hip_build_scale both pushed to their own
	# established mesomorph ceiling (see ape_template.gd's own
	# CHEST_BUILD_SCALE_MESOMORPH-style convention; ProceduralFigure takes
	# the raw scale directly rather than a 0-1 body_type dial).
	_pivots = ProceduralFigure.build(
		visuals, SKIN_COLOR, SKIN_COLOR, SKIN_COLOR, ProceduralFigure.SLEEVE_STYLE_NONE,
		1.25, 1.3, 1.15, 1.0,
		Color(0.0, 0.0, 0.0, 0.0),
		# Blonde -- matches town_generator.gd's own NPC_HAIR_COLORS blonde
		# entry, per direct instruction.
		Color(0.78, 0.58, 0.22), FigureHair.STYLE_BUZZCUT, 0.0, SKIN_COLOR
	)
	_leg_left = _pivots["leg_left"]
	_leg_right = _pivots["leg_right"]
	_arm_left = _pivots["arm_left"]
	_arm_right = _pivots["arm_right"]
	_elbow_left = _pivots["elbow_left"]
	_elbow_right = _pivots["elbow_right"]
	_knee_left = _pivots["knee_left"]
	_knee_right = _pivots["knee_right"]
	_hand_left = _pivots["hand_left"] if _pivots.has("hand_left") else _pivots["palm_left"]
	_hand_right = _pivots["hand_right"] if _pivots.has("hand_right") else _pivots["palm_right"]
	_spine = _pivots["spine"]
	_hips = _pivots["hips"]
	_spine_rest_y = _spine.position.y
	_hips_rest_y = _hips.position.y
	# The hip segment is built with the same pants_color as the legs above
	# (skin-toned) so the legs read bare -- recolored here, on just this
	# one mesh, to the off-white "collar" per direct instruction. Duplicated
	# rather than mutated in place so this doesn't also recolor anything
	# else sharing the same material resource.
	_hips_mesh = _pivots["hips"] as MeshInstance3D
	var hips_material := (_hips_mesh.get_active_material(0) as StandardMaterial3D).duplicate() as StandardMaterial3D
	hips_material.albedo_color = UNDERWEAR_COLOR
	_hips_mesh.material_override = hips_material


## Builds the visible suit -- 2 Water legs, 2 Fire arms, 1 Psychic head
## ("Blorbaka," a named individual parallel to Blorbus -- see docs/
## world_bible.md) -- via BlorbSuit.equip_slot() directly rather than the
## full BlorbSuitController (that class's own paper-doll/inventory/hop
## machinery is real-player-only overhead this NPC doesn't need). Limb
## geometry is nevertheless rebuilt from the live joints every frame below;
## a tube spanning several pivots cannot follow animation by parenting alone.
## equip_slot() requires a real, typed Blorb
## for its cosmetic fields (element/body color), so each slot's "source"
## is a throwaway portrait_mode Blorb -- the same technique blorb_portrait.
## gd's own paper-doll captures already use: portrait_mode=true makes
## _ready() build correct visuals then return before ever touching
## add_to_group("blorbs")/get_node("../Player"), so this never pollutes the
## real party or crashes looking for a Player sibling it doesn't have.
## Freed immediately after each slot is built -- equip_slot() only reads
## from it once, synchronously, to build independent geometry on this
## rig's own pivots.
func _build_suit() -> void:
	# blorb.gd's @onready var terrain resolves "../Terrain" unconditionally
	# on entering the tree, before _ready()'s own portrait_mode early-return
	# ever runs (confirmed by direct report: "Node not found: ../Terrain")
	# -- a bare stand-in Node satisfies that the same way blorb_portrait.gd's
	# own paper-doll captures already do (see that file's own identical
	# comment), never actually queried since _equip_cosmetic_slot()'s own
	# source blorb is portrait_mode and returns before touching it. A single
	# stub covers every _equip_cosmetic_slot() call below since all five
	# throwaway source blorbs are parented here, as this same node's own
	# siblings.
	var terrain_stub := Node.new()
	terrain_stub.name = "Terrain"
	add_child(terrain_stub)
	var pivot_map := {
		"arm_left_shoulder": _arm_left, "arm_left_elbow": _elbow_left,
		"arm_right_shoulder": _arm_right, "arm_right_elbow": _elbow_right,
		"leg_left_hip": _leg_left, "leg_left_knee": _knee_left, "leg_left_ankle": _pivots["ankle_left"],
		"leg_right_hip": _leg_right, "leg_right_knee": _knee_right, "leg_right_ankle": _pivots["ankle_right"],
		"spine": _pivots["spine"], "head": _pivots["head"],
		"back_left": _pivots["back_left"], "back_right": _pivots["back_right"],
		"wrist_left": _pivots["wrist_left"], "wrist_right": _pivots["wrist_right"],
		"fingertip_left": _pivots["fingertip_left"], "fingertip_right": _pivots["fingertip_right"],
		"toe_left": _pivots["toe_left"], "toe_right": _pivots["toe_right"],
	}
	_equip_cosmetic_slot("leg_left", "water", pivot_map)
	_equip_cosmetic_slot("leg_right", "water", pivot_map)
	_equip_cosmetic_slot("arm_left", "fire", pivot_map)
	_equip_cosmetic_slot("arm_right", "fire", pivot_map)
	_equip_cosmetic_slot("head", "psychic", pivot_map)


func _equip_cosmetic_slot(slot: String, element: String, pivot_map: Dictionary) -> void:
	const BLORB_SCENE := "res://scenes/blorb.tscn"
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	var source: Blorb = packed.instantiate()
	source.portrait_mode = true
	source.initial_element = element
	add_child(source)
	# ProceduralFigure's tallest build spaces the joints farther apart; the
	# suit's own thickness must scale too or limbs visibly escape its shell.
	var pieces := BlorbSuit.equip_slot(slot, pivot_map, visuals, source, 1.25)
	_suit_pieces.append_array(pieces)
	if BlorbSuit.is_dynamic_slot(slot) and not pieces.is_empty():
		# Keep the portrait source alive but invisible: rebuild_slot() needs its
		# appearance data, while only the generated worn covering should render.
		source.visible = false
		_dynamic_suit_entries.append({
			"slot": slot,
			"mesh": pieces[0],
			"source": source,
			"pivots": pivot_map,
		})
	else:
		source.queue_free()


func _update_dynamic_suit() -> void:
	for entry in _dynamic_suit_entries:
		var mesh := entry["mesh"] as MeshInstance3D
		var source := entry["source"] as Blorb
		if not is_instance_valid(mesh) or not is_instance_valid(source):
			continue
		BlorbSuit.rebuild_slot(
			mesh,
			entry["slot"] as String,
			entry["pivots"] as Dictionary,
			visuals,
			source,
			1.25
		)


## The whole suit "falling off" at defeat -- per direct instruction, this
## reveals the plain skin-toned/underwear base body underneath, which is
## why _build_figure() above already built that body from the start rather
## than needing a separate undressed model swapped in here.
func _strip_suit() -> void:
	for piece in _suit_pieces:
		if is_instance_valid(piece):
			piece.queue_free()
	_suit_pieces.clear()
	for entry in _dynamic_suit_entries:
		var source := entry.get("source") as Blorb
		if is_instance_valid(source):
			source.queue_free()
	_dynamic_suit_entries.clear()


## The suit pieces _strip_suit() frees above are purely cosmetic geometry
## (see _equip_cosmetic_slot()'s own comment -- each one's source Blorb was
## a throwaway portrait_mode instance, freed the instant its geometry was
## captured, never a real party-eligible blorb). Per direct instruction,
## defeat should leave behind real, wild, joinable blorbs the player can
## then befriend -- so this spawns 5 fresh, ordinary Blorb instances (the
## same in_party=false/initial_element setup wilderness_scatter.gd's own
## _place_wild_blorb() uses for every other wild blorb in the game) scattered
## in a small ring around where he stood, matching the suit's own five
## elements. The Psychic one keeps Blorbaka's own name (see docs/
## world_bible.md) -- a named individual, not just a Psychic-type nobody.
const DROPPED_BLORB_ELEMENTS := ["water", "water", "fire", "fire", "psychic"]
const DROPPED_BLORB_SPREAD := 1.4


func _drop_blorbs() -> void:
	const BLORB_SCENE := "res://scenes/blorb.tscn"
	var packed: PackedScene = load(BLORB_SCENE)
	if packed == null:
		push_warning("Missing blorb scene: " + BLORB_SCENE)
		return
	# A real (non-portrait_mode) Blorb's own _ready() unconditionally does
	# _player = get_node("../Player") -- it needs an actual Player sibling,
	# so it must be parented at the same level Player/Terrain themselves
	# live at (Main), not under get_parent() (False Hero's own immediate
	# parent, Town/Generated, several levels too deep -- confirmed by direct
	# report: "Node not found: ../Player", followed by a null-instance crash
	# reading move_speed off it). terrain_ref IS the real Terrain node, so
	# its own parent is exactly that Main-level node.
	var main_root: Node = terrain_ref.get_parent()
	var origin := global_position
	for i in DROPPED_BLORB_ELEMENTS.size():
		var element: String = DROPPED_BLORB_ELEMENTS[i]
		var angle := TAU * float(i) / float(DROPPED_BLORB_ELEMENTS.size())
		var pos := origin + Vector3(cos(angle), 0.0, sin(angle)) * DROPPED_BLORB_SPREAD
		var inst: Blorb = packed.instantiate()
		inst.in_party = false
		inst.initial_element = element
		if element == "psychic":
			inst.blorb_name = "Blorbaka"
		main_root.add_child(inst)
		inst.global_position = Vector3(pos.x, terrain_ref.get_mesh_height(pos.x, pos.z), pos.z)


func is_defeated() -> bool:
	return _state == State.DEFEATED_FLEEING


## Only meaningful while FIGHTING -- see combat_math.gd's own
## type_multiplier() doc comment for how callers use this.
func current_combat_element() -> String:
	if _state != State.FIGHTING:
		return ""
	return "fire" if _combat_phase in [CombatPhase.FLAMETHROWER, CombatPhase.FIRE_HOVER] else "water"


func _on_talk() -> void:
	if _state != State.BOASTING:
		return
	var actions: Array[Dictionary] = [{
		"label": CHALLENGE_ACTION_LABEL,
		"callback": func():
			DialogUI.hide_dialog()
			_begin_fight(),
	}]
	DialogUI.show_line(DISPLAY_NAME, BOAST_LINE, actions)


func _begin_fight() -> void:
	# Only now does he become a valid target for anything that scans the
	# "skeletons" group (see _ready()'s own comment) -- talking to him and
	# choosing to fight is what turns him hostile, not merely existing.
	add_to_group("skeletons")
	_state = State.FIGHTING
	_target = _find_target()
	_combat_phase = CombatPhase.FLAMETHROWER
	_phase_elapsed = 0.0
	_phase_duration = _rng.randf_range(FLAMETHROWER_DURATION_MIN, FLAMETHROWER_DURATION_MAX)


func take_damage(amount: float, attacker: Blorb = null) -> void:
	if amount <= 0.0 or _state != State.FIGHTING:
		return
	UISounds.play_foley(&"damage_dealt", clampf(amount / 30.0, 0.25, 0.76), get_instance_id())
	register_xp_participant(attacker)
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		_begin_defeat()


func register_xp_participant(blorb: Blorb) -> void:
	if blorb == null or not is_instance_valid(blorb) or not blorb.in_party or blorb.is_melted:
		return
	_xp_participants[blorb.get_instance_id()] = blorb


func apply_stun(duration: float) -> void:
	_stun_remaining = maxf(_stun_remaining, duration)


func apply_haste_weaken(duration: float) -> void:
	_haste_weaken_remaining = maxf(_haste_weaken_remaining, duration)


func unregister_xp_participant(blorb: Blorb) -> void:
	if blorb == null:
		return
	_xp_participants.erase(blorb.get_instance_id())


func _award_defeat_xp() -> void:
	var participants: Array[Blorb] = []
	for candidate in _xp_participants.values():
		var blorb := candidate as Blorb
		if is_instance_valid(blorb) and blorb.in_party and not blorb.is_melted:
			participants.append(blorb)
	if participants.is_empty() or XP_REWARD <= 0:
		return
	participants.sort_custom(func(a: Blorb, b: Blorb): return a.get_instance_id() < b.get_instance_id())
	var base_share := maxi(1, floori(float(XP_REWARD) / float(participants.size())))
	var remainder := maxi(0, XP_REWARD - base_share * participants.size())
	for i in participants.size():
		participants[i].gain_experience(base_share + (1 if i < remainder else 0))


func _begin_defeat() -> void:
	_award_defeat_xp()
	_state = State.DEFEATED_FLEEING
	remove_from_group("skeletons")
	_set_flamethrower_active(false)
	_strip_suit()
	_drop_blorbs()
	var away := Vector2(global_position.x, global_position.z) - town_center
	_flee_direction = away.normalized() if away.length_squared() > 0.01 else Vector2.DOWN
	_flee_traveled = 0.0
	WorldState.false_hero_defeated = true
	# Plain state description, not an explanation -- see CLAUDE.md's
	# "In-game text and player guidance" rule.
	Hud.show_message("The false hero flees.")


func _process(delta: float) -> void:
	_stun_remaining = maxf(_stun_remaining - delta, 0.0)
	_haste_weaken_remaining = maxf(_haste_weaken_remaining - delta, 0.0)
	match _state:
		State.BOASTING:
			pass
		State.FIGHTING:
			_process_fighting(delta)
		State.DEFEATED_FLEEING:
			_process_fleeing(delta)
	# Run after the state animation has written every joint for this frame.
	# The suit mesh therefore follows the actual final transforms, including
	# attack poses and hover poses, rather than an estimated duplicate pose.
	_update_dynamic_suit()


func _find_target() -> Node3D:
	var here := Vector2(global_position.x, global_position.z)
	var best: Node3D = null
	var best_dist := ATTACK_RANGE * 4.0
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		var dist := here.distance_to(Vector2(player.global_position.x, player.global_position.z))
		if dist < best_dist:
			best_dist = dist
			best = player
	for node in get_tree().get_nodes_in_group("blorbs"):
		var blorb := node as Blorb
		if blorb == null or not blorb.in_party or blorb.is_worn or blorb.is_melted:
			continue
		var dist := here.distance_to(Vector2(blorb.global_position.x, blorb.global_position.z))
		if dist < best_dist:
			best_dist = dist
			best = blorb
	return best


func _process_fighting(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = _find_target()
	# Per direct instruction: he stays in town, never chases into the
	# wasteland -- if the fight has drifted this far out, he just stops
	# advancing (and stops attacking) rather than continuing to close in.
	var here := Vector2(global_position.x, global_position.z)
	var leashed := here.distance_to(town_center) < TOWN_LEASH_RADIUS

	_phase_elapsed += delta
	if _phase_elapsed >= _phase_duration:
		_advance_phase()

	match _combat_phase:
		CombatPhase.FLAMETHROWER:
			_process_flamethrower_phase(delta, leashed)
		CombatPhase.WATER_HOVER, CombatPhase.FIRE_HOVER:
			_process_hover_phase(delta)


## Cycles Flamethrower -> Water hover -> Fire hover -> Flamethrower...
## per direct instruction ("alternately"). The two hover phases are pure
## reposition/evade beats -- matches the player's own established "hover
## disables the forward attack" mechanic (see player.gd's own
## _fire_hand_hover_active doc comment) -- so he's only ever actually
## dealing damage during the Flamethrower phase.
func _advance_phase() -> void:
	_phase_elapsed = 0.0
	match _combat_phase:
		CombatPhase.FLAMETHROWER:
			_set_flamethrower_active(false)
			if _rng.randf() < CHAIN_FLAMETHROWER_CHANCE:
				# Back-to-back burst from the other arm, no hover interlude.
				_hover_arm_side_is_left = not _hover_arm_side_is_left
				_phase_duration = _rng.randf_range(FLAMETHROWER_DURATION_MIN, FLAMETHROWER_DURATION_MAX)
				return
			_combat_phase = CombatPhase.WATER_HOVER if _rng.randf() < 0.5 else CombatPhase.FIRE_HOVER
			_hover_base_y = _rest_y
			_phase_duration = _rng.randf_range(HOVER_DURATION_MIN, HOVER_DURATION_MAX)
		CombatPhase.WATER_HOVER, CombatPhase.FIRE_HOVER:
			global_position.y = _rest_y
			_leg_left.rotation.x = 0.0
			_leg_right.rotation.x = 0.0
			_arm_left.rotation.x = 0.0
			_arm_right.rotation.x = 0.0
			if _rng.randf() < CHAIN_HOVER_CHANCE:
				# Straight into the OTHER hover type, still repositioning
				# aggressively rather than settling back to the flamethrower.
				_combat_phase = CombatPhase.FIRE_HOVER if _combat_phase == CombatPhase.WATER_HOVER else CombatPhase.WATER_HOVER
				_hover_base_y = _rest_y
				_phase_duration = _rng.randf_range(HOVER_DURATION_MIN, HOVER_DURATION_MAX)
				return
			_combat_phase = CombatPhase.FLAMETHROWER
			_hover_arm_side_is_left = not _hover_arm_side_is_left
			_phase_duration = _rng.randf_range(FLAMETHROWER_DURATION_MIN, FLAMETHROWER_DURATION_MAX)


func _process_hover_phase(delta: float) -> void:
	# Manual Y animation, not velocity/move_and_slide() -- this is a
	# StaticBody3D, the same reasoning skeleton_nme.gd's own RISING/SINKING
	# already uses for its own vertical motion.
	var target_y := _hover_base_y + HOVER_HEIGHT
	global_position.y = lerp(global_position.y, target_y, HOVER_LERP_SPEED * delta)
	# Legs/arms swing outward into a jet silhouette -- same spread language
	# player.gd's own fire-jet/water-hover pose uses, simplified since this
	# rig has no suit-controller pose helpers of its own to call into.
	var swing_t := clampf(_phase_elapsed / 0.4, 0.0, 1.0)
	if _combat_phase == CombatPhase.WATER_HOVER:
		_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, deg_to_rad(-20.0), swing_t)
		_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, deg_to_rad(-20.0), swing_t)
	else:
		# Fire hover mirrors the player's hands-down jet silhouette. The old
		# 150-degree shoulder rotation was the source of the conspicuous
		# straight-overhead arm pose.
		_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, deg_to_rad(15.0), swing_t)
		_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, deg_to_rad(15.0), swing_t)
	# Closes distance aggressively and unconditionally while hovering (not
	# just when far, and well past the old idle-drift pace) -- per direct
	# instruction, a hover beat should read as a purposeful strike toward
	# the target, not a passive breather. Still eases off once genuinely
	# close so it doesn't overshoot straight through the target.
	# Electric's own stun -- see skeleton_nme.gd's own identical comment on
	# why only the actual position-changing step is gated, not the hover
	# bob/pose above.
	if _target != null and is_instance_valid(_target) and _stun_remaining <= 0.0:
		var here := Vector2(global_position.x, global_position.z)
		var target_here := Vector2(_target.global_position.x, _target.global_position.z)
		var to_target := target_here - here
		if to_target.length() > ATTACK_RANGE * 0.3:
			# City's own haste -- see combat_math.gd's own
			# HASTE_SPEED_MULTIPLIER comment.
			var haste := CombatMath.HASTE_SPEED_MULTIPLIER if _haste_weaken_remaining > 0.0 else 1.0
			var step := to_target.normalized() * MOVE_SPEED * HOVER_APPROACH_SPEED_SCALE * haste * delta
			global_position.x += step.x
			global_position.z += step.y
		if to_target.length() > 0.01:
			var angle := atan2(to_target.x, to_target.y)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, angle, ROTATION_SPEED * delta)


## The same full walk cycle every other ProceduralFigure rig in the game
## uses (leg/arm swing, knee/elbow bend, spine lean, body dip -- see player.
## gd's own _animate_walk()/npc.gd's own _process_walk() for the shared
## shape this mirrors), rather than the bare leg-swing-and-knee-bend-only
## cycle this file used before. Per direct instruction ("his movement and
## walk cycles should all leverage the Hero's ones"). The blorb suit pieces
## are regenerated from these same live pivots by _update_dynamic_suit()
## after the complete state animation has finished for the frame.
func _apply_walk_cycle(delta: float, speed_scale: float = 1.0) -> void:
	_walk_phase += delta * WALK_SWING_SPEED * speed_scale
	var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
	_leg_left.rotation.x = swing
	_leg_right.rotation.x = -swing
	_arm_left.rotation.x = -swing
	_arm_right.rotation.x = swing
	_knee_left.rotation.x = maxf(0.0, cos(_walk_phase + PI)) * ProceduralFigure.KNEE_BEND_AMOUNT
	_knee_right.rotation.x = maxf(0.0, cos(_walk_phase)) * ProceduralFigure.KNEE_BEND_AMOUNT
	# See npc.gd's own _process_walk() comment for the elbow-bend curve
	# shape/sign derivation -- same rig, same treatment.
	var right_forward_fraction := (1.0 - sin(_walk_phase)) * 0.5
	var left_forward_fraction := 1.0 - right_forward_fraction
	_elbow_right.rotation.x = -right_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT
	_elbow_left.rotation.x = -left_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT
	_spine.rotation.x = lerp_angle(_spine.rotation.x, SPINE_LEAN_MAX, POSE_SETTLE_SPEED * delta)
	var body_dip := -ProceduralFigure.WALK_BODY_DIP_AMOUNT * pow(sin(_walk_phase), 2)
	_spine.position.y = _spine_rest_y + body_dip
	_hips.position.y = _hips_rest_y + body_dip


## Eases every joint the walk cycle above drives back to a neutral rest pose
## -- called whenever he's holding position (attacking, or done fleeing)
## instead of actually walking, so a stationary flamethrower blast doesn't
## leave his legs/spine frozen mid-stride from whichever frame he stopped on.
func _settle_walk_cycle(delta: float) -> void:
	var t := POSE_SETTLE_SPEED * delta
	_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, 0.0, t)
	_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, 0.0, t)
	_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, 0.0, t)
	_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, 0.0, t)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, 0.0, t)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, 0.0, t)
	_spine.rotation.x = lerp_angle(_spine.rotation.x, 0.0, t)
	_spine.position.y = lerpf(_spine.position.y, _spine_rest_y, t)
	_hips.position.y = lerpf(_hips.position.y, _hips_rest_y, t)


func _process_flamethrower_phase(delta: float, leashed: bool) -> void:
	if _target == null or not is_instance_valid(_target) or not leashed:
		_set_flamethrower_active(false)
		return
	var here := Vector2(global_position.x, global_position.z)
	var target_here := Vector2(_target.global_position.x, _target.global_position.z)
	var to_target := target_here - here
	var dist := to_target.length()

	if dist > ATTACK_RANGE:
		_set_flamethrower_active(false)
		# Electric's own stun -- see skeleton_nme.gd's own identical comment.
		if _stun_remaining > 0.0:
			_settle_walk_cycle(delta)
		else:
			var dir := to_target.normalized()
			# City's own haste -- see combat_math.gd's own
			# HASTE_SPEED_MULTIPLIER comment.
			var haste := CombatMath.HASTE_SPEED_MULTIPLIER if _haste_weaken_remaining > 0.0 else 1.0
			var step := dir * MOVE_SPEED * haste * delta
			global_position.x += step.x
			global_position.z += step.y
			global_position.y = terrain_ref.get_mesh_height(global_position.x, global_position.z)
			_apply_walk_cycle(delta)
	else:
		_set_flamethrower_active(true)
		UISounds.pulse_power_loop(&"fire", get_instance_id())
		_settle_walk_cycle(delta)

	if dist > 0.01:
		var angle := atan2(to_target.x, to_target.y)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, angle, ROTATION_SPEED * delta)

	if _flamethrower_stream != null and _flamethrower_stream.emitting and _target.has_method("take_damage"):
		# _target is either the player (no element) or a free-roaming
		# Blorb (real element_state) -- matches skeleton_nme.gd's own
		# `_target is Blorb` check for the same polymorphic target.
		var defender_element := (_target as Blorb).element_state if _target is Blorb else ""
		# rolled_stream_rate(), not rolled_attack() -- this is a continuous
		# per-frame stream like player.gd's own fire jet, not a discrete
		# swing, so it skips the variance/crit roll for the same reason
		# combat_math.gd's own doc comment gives (rolling a crit every
		# single frame would just add DPS noise, not read as "occasional").
		var rate := CombatMath.rolled_stream_rate(FLAMETHROWER_DAMAGE_PER_SECOND, 0)
		rate *= CombatMath.type_multiplier("fire", defender_element)
		# City's own weaken -- see combat_math.gd's own
		# WEAKEN_DAMAGE_MULTIPLIER comment.
		if _haste_weaken_remaining > 0.0:
			rate *= CombatMath.WEAKEN_DAMAGE_MULTIPLIER
		_target.take_damage(rate * delta)


## One arm (alternating per _advance_phase()) streams fire forward -- per
## direct instruction ("single flamethrower arms"). Reuses player.gd's own
## ParticleFX-based soft-billboard technique rather than a plain SphereMesh
## (see that file's own _make_fire_stream() for the full reasoning).
func _set_flamethrower_active(active: bool) -> void:
	if not active:
		if _flamethrower_stream != null:
			_flamethrower_stream.emitting = false
		return
	if _flamethrower_stream == null:
		_flamethrower_stream = _make_flamethrower_stream()
	_flamethrower_stream.emitting = true
	var hand := _hand_left if _hover_arm_side_is_left else _hand_right
	var arm := _arm_left if _hover_arm_side_is_left else _arm_right
	# The streaming arm itself extends forward while active; the other
	# stays at rest.
	arm.rotation.x = lerp_angle(arm.rotation.x, deg_to_rad(-70.0), 0.15)
	var other_arm := _arm_right if _hover_arm_side_is_left else _arm_left
	other_arm.rotation.x = lerp_angle(other_arm.rotation.x, 0.0, 0.15)
	_flamethrower_stream.global_position = hand.global_position
	if _target != null and is_instance_valid(_target):
		var aim := _target.global_position - hand.global_position
		if aim.length() > 0.01:
			_flamethrower_stream.look_at(hand.global_position + aim, Vector3.UP)


func _make_flamethrower_stream() -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = "FlamethrowerStream"
	stream.amount = 260
	stream.lifetime = 0.34
	stream.randomness = 0.35
	stream.visibility_aabb = AABB(Vector3(-1.5, -1.5, -7.0), Vector3(3.0, 3.0, 7.4))
	var texture := ParticleFX.build_soft_gradient_texture(24, 1.7, 0.2)
	var flame_material := ParticleFX.build_billboard_material(texture, Color.WHITE, true, 0.0)
	flame_material.vertex_color_use_as_albedo = true
	var flame := QuadMesh.new()
	flame.size = Vector2(0.22, 0.5)
	flame.material = flame_material
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 6.0
	process.gravity = Vector3(0.0, -1.4, 0.0)
	process.initial_velocity_min = 9.0
	process.initial_velocity_max = 14.0
	process.scale_min = 0.5
	process.scale_max = 1.05
	process.particle_flag_align_y = true
	process.angle_min = -12.0
	process.angle_max = 12.0
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(1.0, 0.95, 0.75, 1.0)},
		{"offset": 0.25, "color": Color(1.0, 0.55, 0.1, 1.0)},
		{"offset": 0.6, "color": Color(0.85, 0.25, 0.05, 0.9)},
		{"offset": 1.0, "color": Color(0.35, 0.06, 0.02, 0.0)},
	])
	process.scale_curve = ParticleFX.build_scale_curve(0.6, 1.15, 0.3, 0.7)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.0
	process.turbulence_noise_scale = 2.0
	process.turbulence_influence_min = 0.04
	process.turbulence_influence_max = 0.15
	stream.process_material = process
	stream.draw_pass_1 = flame
	stream.emitting = false
	add_child(stream)
	stream.top_level = true
	return stream


## He runs to a point just outside town, where a freshly-risen skeleton
## (see skeleton_nme.gd's own start_consuming()) catches him -- both
## instances free themselves once that beat finishes. FLEE_DISTANCE, not
## TOWN_LEASH_RADIUS, since fleeing should read as a short, deliberate dash
## to the town's edge, not a repeat of the same long chase leash.
func _process_fleeing(delta: float) -> void:
	if _consuming_triggered:
		return
	var step := _flee_direction * FLEE_SPEED * delta
	global_position.x += step.x
	global_position.z += step.y
	global_position.y = terrain_ref.get_mesh_height(global_position.x, global_position.z)
	_flee_traveled += step.length()
	var angle := atan2(_flee_direction.x, _flee_direction.y)
	visuals.rotation.y = lerp_angle(visuals.rotation.y, angle, ROTATION_SPEED * delta)
	_apply_walk_cycle(delta, 1.4)
	if _flee_traveled >= FLEE_DISTANCE:
		_consuming_triggered = true
		_spawn_consuming_skeleton()
		Hud.show_message("The village now calls you its savior.")
		WorldState.player_title = "Savior of the Village"


func _spawn_consuming_skeleton() -> void:
	const SKELETON_SCENE := "res://scenes/skeleton.tscn"
	var packed: PackedScene = load(SKELETON_SCENE)
	if packed == null:
		queue_free()
		return
	var skeleton: Node3D = packed.instantiate()
	skeleton.set_terrain_reference(terrain_ref)
	var behind := global_position - Vector3(_flee_direction.x, 0.0, _flee_direction.y) * 4.0
	skeleton.position = Vector3(behind.x, terrain_ref.get_mesh_height(behind.x, behind.z), behind.z)
	get_parent().add_child(skeleton)
	skeleton.start_consuming(self)
