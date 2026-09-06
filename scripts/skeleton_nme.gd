extends StaticBody3D

## The first "NME" (enemy) type -- a minion manifesting from the Demon
## King's mirror world (see docs/world_bible.md's Aggros section), rising
## out of the ground in the open wasteland and attacking the player and
## any free-roaming party blorbs with punches. Blorbs are what actually
## fight it off (see blorb.gd's State.COMBAT) -- this script never damages
## a blorb/player back except through its own punch.
##
## Reuses ProceduralFigure.build()'s shared rig (skeleton_mode=true, see
## that file) and npc.gd's walk-cycle animation approach, swapping npc.gd's
## wander target for a live chase target.

const BONE_COLOR := Color(0.92, 0.90, 0.84)

@export var body_scale: float = 1.0
## Per-NME tuning point for the progression system. Future, harder NME
## scenes raise this value without changing the shared participation logic.
@export var xp_reward: int = 24

const MAX_HP := 40.0
const MOVE_SPEED := 2.1
const ROTATION_SPEED := 5.0
const WALK_SWING_SPEED := 6.0
const WALK_SWING_AMOUNT := 0.55
const ATTACK_RANGE := 1.6
const ATTACK_COOLDOWN := 1.4
## Base damage before combat_math.gd's own variance/crit roll -- see
## _process_attacking(). Renamed from ATTACK_DAMAGE now that it's a base
## rather than the literal dealt amount. Skeletons have no Strength stat, so
## unlike a blorb's own attacks this rolls with strength=0 -- flat damage,
## just randomized and occasionally critical.
const ATTACK_BASE_DAMAGE := 6.0
## How long the punch pose holds before returning to the chase -- long enough
## to read as a deliberate swing rather than an instant snap.
const ATTACK_POSE_DURATION := 0.5
const RISE_DURATION := 1.0
const SINK_DURATION := 0.8
## How far below its own rest height this figure starts (RISING) / ends up
## (SINKING) -- tall enough that the whole body is hidden underground.
const BURIAL_DEPTH := 2.2
## How far this skeleton will look for the player/a party blorb to chase.
## Generous -- once risen, a skeleton commits to the encounter that spawned
## it rather than needing the target to stay within a tight leash.
const DETECTION_RADIUS := 30.0
## StaticBody3D collision does not resolve movement when this script updates
## global_position directly. Give every active NME a personal radius and a
## speed-limited separation pass so several chasing the same target form a
## loose ring rather than occupying one collision volume.
const SEPARATION_RADIUS := 0.70
const SEPARATION_PUSH_SPEED := 3.8

enum State { RISING, HUNTING, ATTACKING, SINKING, CONSUMING }
## See start_consuming()'s own doc comment.
const CONSUME_APPROACH_DURATION := 1.0
const CONSUME_HOLD_DURATION := 0.8

var terrain_ref: Node = null
## For combat_math.gd's own damage-variance/crit rolls -- this project's
## established convention (see blorb.gd's own _rng) over the global
## randf()/randi(), so this NME's rolls don't share/consume state with any
## unrelated system's own random draws.
var _rng := RandomNumberGenerator.new()


func set_terrain_reference(world_terrain: Node) -> void:
	terrain_ref = world_terrain


@onready var visuals: Node3D = $Visuals

var current_hp: float = MAX_HP
var _state: State = State.RISING
var _rest_y: float = 0.0
var _rise_elapsed: float = 0.0
var _sink_elapsed: float = 0.0
var _attack_cooldown: float = 0.0
var _attack_pose_elapsed: float = 0.0
var _walk_phase: float = 0.0
var _target: Node3D = null
## Every party Blorb that has dealt at least one point of damage to this NME.
## Keyed by instance ID so repeated stream ticks remain one participation
## entry rather than increasing that Blorb's share.
var _xp_participants: Dictionary = {}

var _consume_elapsed: float = 0.0
var _consume_prey: Node3D = null
var _consume_start_position: Vector3 = Vector3.ZERO

## Electric's own stun / City's own haste-weaken -- see combat_math.gd's own
## STUN_DURATION/HASTE_WEAKEN_DURATION comment. Both count down in _process()
## regardless of state; apply_stun()/apply_haste_weaken() refresh to the max
## of the current remaining time and the new duration rather than adding, so
## a continuous stream re-applying every frame can't stack into a permanent
## effect -- it just stays active until `duration` after the last tick.
var _stun_remaining: float = 0.0
var _haste_weaken_remaining: float = 0.0

var _leg_left: Node3D
var _leg_right: Node3D
var _arm_left: Node3D
var _arm_right: Node3D
var _knee_left: Node3D
var _knee_right: Node3D
var _elbow_left: Node3D
var _elbow_right: Node3D
var _spine: Node3D
var _hips: Node3D


func _ready() -> void:
	add_to_group("skeletons")
	_rng.randomize()
	if terrain_ref == null:
		terrain_ref = get_node("../../Terrain")
	_build_figure()
	_rest_y = terrain_ref.get_mesh_height(global_position.x, global_position.z)
	global_position.y = _rest_y - BURIAL_DEPTH


func _build_figure() -> void:
	var pivots := ProceduralFigure.build(
		visuals, BONE_COLOR, BONE_COLOR, BONE_COLOR, ProceduralFigure.SLEEVE_STYLE_NONE,
		body_scale, 0.55, 0.55, 1.0,
		Color(0.0, 0.0, 0.0, 0.0),  # chest_emblem_color -- none
		BONE_COLOR, FigureHair.STYLE_BUZZCUT, 0.0, BONE_COLOR,
		true  # skeleton_mode
	)
	_leg_left = pivots["leg_left"]
	_leg_right = pivots["leg_right"]
	_arm_left = pivots["arm_left"]
	_arm_right = pivots["arm_right"]
	_knee_left = pivots["knee_left"]
	_knee_right = pivots["knee_right"]
	_elbow_left = pivots["elbow_left"]
	_elbow_right = pivots["elbow_right"]
	_spine = pivots["spine"]
	_hips = pivots["hips"]


func is_defeated() -> bool:
	return _state == State.SINKING


func take_damage(amount: float, attacker: Blorb = null) -> void:
	if amount <= 0.0 or _state == State.SINKING or _state == State.RISING:
		return
	register_xp_participant(attacker)
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		_award_defeat_xp()
		_start_sinking()


func register_xp_participant(blorb: Blorb) -> void:
	if blorb == null or not is_instance_valid(blorb) or not blorb.in_party or blorb.is_melted:
		return
	_xp_participants[blorb.get_instance_id()] = blorb


## Electric's own arm/combat-stream power -- see combat_math.gd's own
## STUN_DURATION comment. Refresh-to-max, not additive (see _stun_remaining's
## own field comment).
func apply_stun(duration: float) -> void:
	_stun_remaining = maxf(_stun_remaining, duration)


## City's own arm/combat-stream power -- see combat_math.gd's own
## HASTE_WEAKEN_DURATION comment.
func apply_haste_weaken(duration: float) -> void:
	_haste_weaken_remaining = maxf(_haste_weaken_remaining, duration)


## Melting invalidates the whole encounter contribution, even if the Blorb
## reforms before this NME is eventually defeated. A fresh post-reform hit
## can register it again as a new contribution.
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
	if participants.is_empty() or xp_reward <= 0:
		return
	# Divide the NME's pool among everyone who contributed. Any indivisible
	# remainder is distributed deterministically, and a very small reward
	# still grants every participant at least one XP for their contribution.
	participants.sort_custom(func(a: Blorb, b: Blorb): return a.get_instance_id() < b.get_instance_id())
	var base_share := maxi(1, floori(float(xp_reward) / float(participants.size())))
	var remainder := maxi(0, xp_reward - base_share * participants.size())
	for i in participants.size():
		participants[i].gain_experience(base_share + (1 if i < remainder else 0))


func _start_sinking() -> void:
	_state = State.SINKING
	_sink_elapsed = 0.0
	remove_from_group("skeletons")


func _process(delta: float) -> void:
	_stun_remaining = maxf(_stun_remaining - delta, 0.0)
	_haste_weaken_remaining = maxf(_haste_weaken_remaining - delta, 0.0)
	match _state:
		State.RISING:
			_process_rising(delta)
		State.HUNTING:
			_process_hunting(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.SINKING:
			_process_sinking(delta)
		State.CONSUMING:
			_process_consuming(delta)
	if _state == State.HUNTING or _state == State.ATTACKING:
		_apply_nme_separation(delta)


func nme_separation_radius() -> float:
	return SEPARATION_RADIUS * body_scale


func _apply_nme_separation(delta: float) -> void:
	var here := Vector2(global_position.x, global_position.z)
	var correction := Vector2.ZERO
	for node in get_tree().get_nodes_in_group("skeletons"):
		var other := node as Node3D
		if other == null or other == self or not is_instance_valid(other):
			continue
		if other.has_method("is_defeated") and bool(other.call("is_defeated")):
			continue
		var other_radius := SEPARATION_RADIUS
		if other.has_method("nme_separation_radius"):
			other_radius = float(other.call("nme_separation_radius"))
		var away := here - Vector2(other.global_position.x, other.global_position.z)
		var minimum_distance := nme_separation_radius() + other_radius
		var distance := away.length()
		if distance >= minimum_distance:
			continue
		var direction := away / distance if distance > 0.001 else (
			Vector2.RIGHT if get_instance_id() < other.get_instance_id() else Vector2.LEFT
		)
		correction += direction * (minimum_distance - distance)
	if correction.length_squared() <= 0.000001:
		return
	var shift := correction.limit_length(SEPARATION_PUSH_SPEED * delta)
	var separated := here + shift
	global_position.x = separated.x
	global_position.z = separated.y
	global_position.y = terrain_ref.get_mesh_height(separated.x, separated.y)


func _process_rising(delta: float) -> void:
	_rise_elapsed += delta
	var t := clampf(_rise_elapsed / RISE_DURATION, 0.0, 1.0)
	global_position.y = lerp(_rest_y - BURIAL_DEPTH, _rest_y, ease(t, 0.4))
	if t >= 1.0:
		_state = State.HUNTING


func _process_sinking(delta: float) -> void:
	_sink_elapsed += delta
	var t := clampf(_sink_elapsed / SINK_DURATION, 0.0, 1.0)
	global_position.y = lerp(_rest_y, _rest_y - BURIAL_DEPTH, ease(t, 1.8))
	if t >= 1.0:
		queue_free()


## Called by false_hero_nme.gd's own defeat/flee sequence once he's reached
## his own flee point, rather than anything this file initiates on its
## own -- an ordinary skeleton has no reason to single out a specific prey
## otherwise. Takes over this skeleton's state entirely (its ordinary
## HUNTING/ATTACKING loop never runs again): closes the remaining gap to
## `prey` over CONSUME_APPROACH_DURATION, holds briefly, then frees both
## nodes -- the same eased-lerp-into-queue_free() shape _process_sinking()
## above already uses for an ordinary defeat, just closing a real gap
## first instead of sinking in place.
func start_consuming(prey: Node3D) -> void:
	if _state == State.CONSUMING:
		return
	_state = State.CONSUMING
	_consume_elapsed = 0.0
	_consume_prey = prey
	_consume_start_position = global_position
	remove_from_group("skeletons")


func _process_consuming(delta: float) -> void:
	if _consume_prey == null or not is_instance_valid(_consume_prey):
		queue_free()
		return
	_consume_elapsed += delta
	var approach_t := clampf(_consume_elapsed / CONSUME_APPROACH_DURATION, 0.0, 1.0)
	global_position = _consume_start_position.lerp(_consume_prey.global_position, ease(approach_t, 0.6))
	var facing := Vector2(_consume_prey.global_position.x, _consume_prey.global_position.z) - Vector2(global_position.x, global_position.z)
	if facing.length_squared() > 0.01:
		visuals.rotation.y = atan2(facing.x, facing.y)
	if _consume_elapsed >= CONSUME_APPROACH_DURATION + CONSUME_HOLD_DURATION:
		_consume_prey.queue_free()
		queue_free()


## Nearest of the player or an eligible free-roaming party blorb (in_party,
## not worn in the blorb suit, not already melted -- see blorb.gd's own
## is_worn/is_melted) within DETECTION_RADIUS. Re-scanned continuously
## rather than cached, matching this codebase's existing convention of
## proximity checks over event callbacks (see blorb.gd's own
## _find_nearest_skeleton()).
func _find_target() -> Node3D:
	var here := Vector2(global_position.x, global_position.z)
	var best: Node3D = null
	var best_dist := DETECTION_RADIUS
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


func _process_hunting(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or _target_invalid():
		_target = _find_target()
	if _target == null:
		return

	var here := Vector2(global_position.x, global_position.z)
	var target_here := Vector2(_target.global_position.x, _target.global_position.z)
	var to_target := target_here - here

	# True 3D distance, not just horizontal -- per direct correction, a
	# skeleton standing on the ground shouldn't be able to start (or land)
	# an attack on a target floating far above or below it just because
	# their ground positions happen to line up. Movement/facing below still
	# use the horizontal-only `to_target` -- this is a ground-bound
	# creature steering across the ground plane, only the attack gate needs
	# the real 3D check.
	if global_position.distance_to(_target.global_position) <= ATTACK_RANGE:
		_state = State.ATTACKING
		_attack_pose_elapsed = 0.0
		return
	# Electric's own stun -- see combat_math.gd's own STUN_DURATION comment.
	# This is the only place real chase movement happens, so freezing here
	# is enough to stop him closing distance for the stun's duration --
	# placed after (not before) the attack-range check above so a stun
	# doesn't also prevent starting to swing at a target already adjacent
	# when it lands, only the actual approach.
	if _stun_remaining > 0.0:
		return

	var dir := to_target.normalized()
	# City's own haste -- see combat_math.gd's own HASTE_SPEED_MULTIPLIER
	# comment.
	var speed := MOVE_SPEED * (CombatMath.HASTE_SPEED_MULTIPLIER if _haste_weaken_remaining > 0.0 else 1.0)
	var step := dir * speed * delta
	var new_here := here + step
	global_position.x = new_here.x
	global_position.z = new_here.y
	global_position.y = terrain_ref.get_mesh_height(new_here.x, new_here.y)

	var target_angle := atan2(dir.x, dir.y)
	visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, ROTATION_SPEED * delta)

	_walk_phase += delta * WALK_SWING_SPEED
	var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
	_leg_left.rotation.x = swing
	_leg_right.rotation.x = -swing
	_arm_left.rotation.x = -swing
	_arm_right.rotation.x = swing
	_knee_left.rotation.x = maxf(0.0, cos(_walk_phase + PI)) * ProceduralFigure.KNEE_BEND_AMOUNT
	_knee_right.rotation.x = maxf(0.0, cos(_walk_phase)) * ProceduralFigure.KNEE_BEND_AMOUNT

	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)


## True once a previously-picked target has left the party/melted/been worn
## mid-chase -- re-picking immediately rather than continuing to chase a
## target that's no longer a valid combatant.
func _target_invalid() -> bool:
	if _target is Blorb:
		var blorb := _target as Blorb
		return not blorb.in_party or blorb.is_worn or blorb.is_melted
	return false


func _process_attacking(delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or _target_invalid():
		_target = _find_target()
		_state = State.HUNTING
		return

	var here := Vector2(global_position.x, global_position.z)
	var target_here := Vector2(_target.global_position.x, _target.global_position.z)
	var to_target := target_here - here
	# True 3D distance -- see _process_hunting()'s own identical comment.
	if global_position.distance_to(_target.global_position) > ATTACK_RANGE * 1.3:
		_state = State.HUNTING
		return
	if to_target.length() > 0.01:
		var target_angle := atan2(to_target.x, to_target.y)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, ROTATION_SPEED * delta)

	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
		# Ease the swinging arm back to rest between punches.
		_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, 0.0, 6.0 * delta)
		_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, 0.0, 6.0 * delta)
		return

	_attack_pose_elapsed += delta
	var t := clampf(_attack_pose_elapsed / ATTACK_POSE_DURATION, 0.0, 1.0)
	# A quick forward arm swing -- positive rotation.x on this rig's arm
	# pivot is backward (see procedural_figure.gd's own note on that sign),
	# so the punch itself is negative.
	_arm_right.rotation.x = -sin(t * PI) * 2.0
	_elbow_right.rotation.x = -sin(t * PI) * 1.0
	if t >= 1.0:
		if _target.has_method("take_damage"):
			# City's own weaken -- see combat_math.gd's own
			# WEAKEN_DAMAGE_MULTIPLIER comment.
			var base_damage := ATTACK_BASE_DAMAGE
			if _haste_weaken_remaining > 0.0:
				base_damage *= CombatMath.WEAKEN_DAMAGE_MULTIPLIER
			var roll := CombatMath.rolled_attack(base_damage, 0, _rng)
			_target.take_damage(roll["amount"])
		_attack_cooldown = ATTACK_COOLDOWN
		_attack_pose_elapsed = 0.0
