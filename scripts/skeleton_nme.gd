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

const MAX_HP := 40.0
const MOVE_SPEED := 2.1
const ROTATION_SPEED := 5.0
const WALK_SWING_SPEED := 6.0
const WALK_SWING_AMOUNT := 0.55
const ATTACK_RANGE := 1.6
const ATTACK_COOLDOWN := 1.4
const ATTACK_DAMAGE := 6.0
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

enum State { RISING, HUNTING, ATTACKING, SINKING }

var terrain_ref: Node = null


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


func take_damage(amount: float) -> void:
	if amount <= 0.0 or _state == State.SINKING or _state == State.RISING:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		_start_sinking()


func _start_sinking() -> void:
	_state = State.SINKING
	_sink_elapsed = 0.0
	remove_from_group("skeletons")


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

	if to_target.length() <= ATTACK_RANGE:
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
	if to_target.length() > ATTACK_RANGE * 1.3:
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
			_target.take_damage(ATTACK_DAMAGE)
		_attack_cooldown = ATTACK_COOLDOWN
		_attack_pose_elapsed = 0.0
