extends StaticBody3D

## A second "NME" (enemy) type -- a skeletal primate manifesting from the
## Demon King's mirror world (see docs/world_bible.md's Aggros section), the
## Primate Kingdom's own counterpart to the outskirts' human skeleton_nme.gd.
## Same rise-from-the-ground/chase/punch state machine and XP-participant
## contract as that file (see its own class doc comment for the full
## rationale), built on ApeTemplate's shared rig instead of ProceduralFigure's
## human one -- per direct instruction: "skeleton versions of the primates,
## based on their rig... colored like the human skeletons, and with no ears,
## and the thorax... replaced by spinal column in the same way."
##
## Scoped to the ape variant only (variant "has_tail" = false) -- the same
## ApeTemplate rig also builds the tailed "primate template" monkey variant,
## but a skeletal tail isn't part of this request and would need its own
## bespoke bone-chain treatment (MonkeyFigure._build_tail()'s tail is a
## single soft-tissue mesh, not a chain of vertebrae) rather than reusing
## anything already built here.
##
## Deliberately a separate script/scene from skeleton_nme.gd rather than one
## script branching on rig type: the two rigs' pivot dictionaries mostly
## share key names (see ape_template.gd's own doc comment on its returned
## dict), but the ape rig's permanent crouch/lean rest pose means its walk
## cycle has to animate RELATIVE to each pivot's own rest rotation (same
## technique ape_template_preview.gd's own _animate_walk() already uses),
## unlike skeleton_nme.gd's simpler zero-based swing -- different enough
## animation math that sharing one script would need its own rig-type
## branches throughout anyway.
##
## Per direct instruction ("relatively stronger... and should give more XP"):
## every combat number below is a deliberate step up from skeleton_nme.gd's
## own (MAX_HP 40->70, ATTACK_BASE_DAMAGE 6->10, xp_reward 24->40) --
## first-pass multipliers (~1.7x), adjustable on report like every other
## fresh balance number in this project.
##
## Added to BOTH "skeletons" (so blorb.gd's own melee-aggro scan/melt-
## cleanup and player.gd's own elemental-stream damage treat this exactly
## like the human skeleton, matching it purely by group membership and
## take_damage()/register_xp_participant() method contract, not node type --
## no changes needed to any of that shared combat code) and "ape_skeletons"
## (a separate group so jungle_kingdom_ape_skeleton_spawner.gd's own
## population cap counts only its own spawns, not the unrelated -- and, in
## practice, never simultaneously loaded anyway -- outskirts skeleton count).

const BONE_COLOR := Color(0.92, 0.90, 0.84)

@export var body_scale: float = 1.4
## Per-NME tuning point for the progression system, same convention as
## skeleton_nme.gd's own xp_reward -- higher here since this NME is meant to
## read as a tougher encounter.
@export var xp_reward: int = 40

const MAX_HP := 70.0
const MOVE_SPEED := 2.3
const ROTATION_SPEED := 5.0
const WALK_SWING_SPEED := 6.0
const WALK_SWING_AMOUNT := 0.55
const ATTACK_RANGE := 1.9
const ATTACK_COOLDOWN := 1.3
## Base damage before combat_math.gd's own variance/crit roll -- see
## _process_attacking(). Like skeleton_nme.gd's own ATTACK_BASE_DAMAGE, this
## NME has no Strength stat, so it rolls with strength=0 -- flat damage,
## just randomized and occasionally critical.
const ATTACK_BASE_DAMAGE := 10.0
const ATTACK_POSE_DURATION := 0.5
const RISE_DURATION := 1.0
const SINK_DURATION := 0.8
const BURIAL_DEPTH := 2.2
const DETECTION_RADIUS := 34.0

enum State { RISING, HUNTING, ATTACKING, SINKING }

var terrain_ref: Node = null
## For combat_math.gd's own damage-variance/crit rolls -- see
## skeleton_nme.gd's own identically-purposed _rng.
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
## The ape rig's own permanent crouch/lean rest rotations (see ape_template.
## gd's own class doc comment) -- captured once right after the rig is
## built, then animated AROUND rather than replaced, the same technique
## ape_template_preview.gd's own _animate_walk() already uses for this rig.
## Zero for the human rig (skeleton_nme.gd has no equivalent of these), but
## real, nonzero angles here.
var _leg_rest_x := 0.0
var _knee_rest_x := 0.0
var _arm_rest_x := 0.0


func _ready() -> void:
	add_to_group("skeletons")
	add_to_group("ape_skeletons")
	_rng.randomize()
	if terrain_ref == null:
		terrain_ref = get_node("../../Terrain")
	_build_figure()
	_rest_y = terrain_ref.get_mesh_height(global_position.x, global_position.z)
	global_position.y = _rest_y - BURIAL_DEPTH


func _build_figure() -> void:
	var variant := {
		"has_tail": false,
		"skeleton_mode": true,
		# Uniform bone coloring -- marking_color would otherwise tint the
		# muzzle/hand/foot "skin" and (were it not skipped) the ear pads a
		# separate color from the rest of the body.
		"marking_color": BONE_COLOR,
	}
	var pivots := ApeTemplate.build(visuals, BONE_COLOR, body_scale, variant)
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
	_leg_rest_x = _leg_left.rotation.x
	_knee_rest_x = _knee_left.rotation.x
	_arm_rest_x = _arm_left.rotation.x


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
	participants.sort_custom(func(a: Blorb, b: Blorb): return a.get_instance_id() < b.get_instance_id())
	var base_share := maxi(1, floori(float(xp_reward) / float(participants.size())))
	var remainder := maxi(0, xp_reward - base_share * participants.size())
	for i in participants.size():
		participants[i].gain_experience(base_share + (1 if i < remainder else 0))


func _start_sinking() -> void:
	_state = State.SINKING
	_sink_elapsed = 0.0
	remove_from_group("skeletons")
	remove_from_group("ape_skeletons")


func _process(delta: float) -> void:
	match _state:
		State.RISING:
			_process_rising(delta)
		State.HUNTING:
			_process_hunting(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.SINKING:
			_process_sinking(delta)


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

	# True 3D distance, not just horizontal -- see skeleton_nme.gd's own
	# identical comment. Movement/facing below still use the horizontal-only
	# `to_target` -- this is a ground-bound creature steering across the
	# ground plane, only the attack gate needs the real 3D check.
	if global_position.distance_to(_target.global_position) <= ATTACK_RANGE:
		_state = State.ATTACKING
		_attack_pose_elapsed = 0.0
		return

	var dir := to_target.normalized()
	var step := dir * MOVE_SPEED * delta
	var new_here := here + step
	global_position.x = new_here.x
	global_position.z = new_here.y
	global_position.y = terrain_ref.get_mesh_height(new_here.x, new_here.y)

	var target_angle := atan2(dir.x, dir.y)
	visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, ROTATION_SPEED * delta)

	# Animated relative to each pivot's own permanent rest rotation (see
	# _leg_rest_x's own comment) -- an absolute zero-based swing, like
	# skeleton_nme.gd's human rig uses, would erase this rig's own crouch.
	_walk_phase += delta * WALK_SWING_SPEED
	var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
	_leg_left.rotation.x = _leg_rest_x + swing
	_leg_right.rotation.x = _leg_rest_x - swing
	_arm_left.rotation.x = _arm_rest_x - swing
	_arm_right.rotation.x = _arm_rest_x + swing
	_knee_left.rotation.x = _knee_rest_x + maxf(0.0, cos(_walk_phase + PI)) * ProceduralFigure.KNEE_BEND_AMOUNT
	_knee_right.rotation.x = _knee_rest_x + maxf(0.0, cos(_walk_phase)) * ProceduralFigure.KNEE_BEND_AMOUNT

	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)


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
		# Ease back toward REST, not zero (see _leg_rest_x's own comment) --
		# skeleton_nme.gd's human rig eases to 0.0 here since its own arm
		# rest already is 0.0, so this reads identically there and only
		# actually differs on this rig.
		_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, _arm_rest_x, 6.0 * delta)
		_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, 0.0, 6.0 * delta)
		return

	_attack_pose_elapsed += delta
	var t := clampf(_attack_pose_elapsed / ATTACK_POSE_DURATION, 0.0, 1.0)
	_arm_right.rotation.x = _arm_rest_x - sin(t * PI) * 2.0
	_elbow_right.rotation.x = -sin(t * PI) * 1.0
	if t >= 1.0:
		if _target.has_method("take_damage"):
			var roll := CombatMath.rolled_attack(ATTACK_BASE_DAMAGE, 0, _rng)
			_target.take_damage(roll["amount"])
		_attack_cooldown = ATTACK_COOLDOWN
		_attack_pose_elapsed = 0.0
