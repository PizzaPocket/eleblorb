class_name CatTemplatePreview
extends StaticBody3D

## Standalone start-screen/debug instance for evaluating the cat template.
@export var coat_color: Color = CatFigure.COAT_COLORS[0]
## Per direct instruction -- Yogi is the Primate Kingdom's canonical cat
## (docs/world_bible.md's own Creatures/Cats entry), so his coat/markings
## always come from CatFigure's own YOGI_* consts rather than this
## instance's own coat_color/marking exports, which this flag overrides.
@export var is_yogi: bool = false
@export var resting: bool = false
@export var sitting: bool = false
@export_range(-1.0, 1.0, 2.0) var curl_side: float = 1.0

enum IdlePose { WALKING, CURLED, SITTING }

const ROAM_RADIUS := 4.5
const WALK_SPEED := 0.62
const TURN_SPEED := 4.5
const ARRIVE_DISTANCE := 0.18
const WALK_TARGET_MIN_TIME := 3.0
const WALK_TARGET_MAX_TIME := 7.0
const REST_CHANCE_PER_TARGET := 0.34
const REST_TIME_MIN := 5.0
const REST_TIME_MAX := 10.0
const WALK_CYCLE_SPEED := 8.0
const FRONT_STRIDE_FORWARD := deg_to_rad(28.0)
const FRONT_STRIDE_BACK := deg_to_rad(15.0)
const FRONT_ELBOW_LIFT := deg_to_rad(24.0)
const FRONT_CARPUS_LIFT := deg_to_rad(46.0)
const HIND_STRIDE_FORWARD := deg_to_rad(25.0)
const HIND_STRIDE_BACK := deg_to_rad(14.0)
const HIND_STIFLE_LIFT := deg_to_rad(20.0)
const HIND_HOCK_LIFT := deg_to_rad(52.0)
const WALK_INWARD_LEG_ROLL := deg_to_rad(9.0)
const GROUND_SETTLE_SPEED := 5.0
const POSE_TRANSITION_DURATION := 1.35
const PLAYER_LOOK_DISTANCE := 6.0
const HEAD_YAW_LIMIT := deg_to_rad(50.0)
const HEAD_TURN_SPEED := 7.0
const NECK_LOOK_SHARE := 0.5
const SIT_HIPS_PITCH := deg_to_rad(-38.0)
## Exact vertical support extent of the pitched hip SUPEREGG. A prior pass
## added the rotated Y/Z bounding-box projections; that is correct for a
## rectangle, but overestimates this rounded epsilon=3 superellipse by a
## few centimetres. The support function uses the dual exponent q=e/(e-1)
## and lands the actual curved surface tangent to Y=0.
const SIT_HIP_EPSILON := SuperEgg.EPSILON_SOFT
const SIT_HIP_DUAL_EXPONENT := SIT_HIP_EPSILON / (SIT_HIP_EPSILON - 1.0)
const SIT_BODY_Y := (
	pow(
		pow(CatFigure.BODY_HALF_HEIGHT * cos(absf(SIT_HIPS_PITCH)), SIT_HIP_DUAL_EXPONENT)
		+ pow(CatFigure.HIP_SIZE.z * sin(absf(SIT_HIPS_PITCH)), SIT_HIP_DUAL_EXPONENT),
		1.0 / SIT_HIP_DUAL_EXPONENT
	)
)
const SIT_ABDOMEN_PITCH := deg_to_rad(-8.0)
const SIT_THORAX_PITCH := deg_to_rad(4.0)
const SIT_FRONT_ANGLES := [deg_to_rad(42.0), 0.0, 0.0]
## A visible folded Z at the side of the haunch: the femur rises/advances,
## tibia returns down and back, and the long third segment reaches the paw
## forward to the ground. The previous tighter fold hid the whole chain
## inside the pelvis silhouette.
const SIT_HIND_ANGLES := [deg_to_rad(-70.0), deg_to_rad(145.0), deg_to_rad(-110.0)]
## A small downward adjustment remains fully buried inside the thorax. The
## earlier -17.5 cm value visibly detached the shoulder sockets; most of
## the remaining ground reach now comes from pitching the paws instead.
const SIT_FRONT_SHOULDER_Y := -0.04
const SIT_FRONT_PAW_PITCH := deg_to_rad(55.0)

var _pivots: Dictionary
var _blink := EyeBlink.new_state()
var _terrain: Node
var _player: Node3D
var _roam_center := Vector2.ZERO
var _target := Vector2.ZERO
var _has_target := false
var _decision_timer := 0.0
var _rest_timer := 0.0
var _walk_phase := 0.0
var _rng := RandomNumberGenerator.new()
var _leg_rest: Dictionary = {}
var _pose_blend := 0.0
var _pose_target := 0.0
var _idle_pose: IdlePose = IdlePose.WALKING
var _transition_pose: IdlePose = IdlePose.WALKING
var _transitioning := false
var _tail_stand_points: Array[Vector3] = []
var _transition_leg_start: Dictionary = {}
var _current_head_yaw := 0.0
var _neck_pose_pitch := deg_to_rad(65.0)
var _neck_pose_yaw := 0.0
var _head_pose_pitch := deg_to_rad(-45.0)


func _ready() -> void:
	_rng.randomize()
	# Initial debug sleepers need the same independent left/right choice as
	# later curled-rest events; otherwise their exported/default curl_side
	# makes every first pose appear to favor one side.
	if resting:
		curl_side = -1.0 if _rng.randf() < 0.5 else 1.0
	_terrain = get_node_or_null("../Terrain")
	_player = get_node_or_null("../Player") as Node3D
	_roam_center = Vector2(global_position.x, global_position.z)
	_rebuild_figure()
	_idle_pose = IdlePose.SITTING if sitting else (IdlePose.CURLED if resting else IdlePose.WALKING)
	_transition_pose = _idle_pose
	_pose_blend = 1.0 if _idle_pose != IdlePose.WALKING else 0.0
	_pose_target = _pose_blend
	_apply_pose_blend(_pose_blend)
	_decision_timer = _rng.randf_range(WALK_TARGET_MIN_TIME, WALK_TARGET_MAX_TIME)
	if _idle_pose != IdlePose.WALKING:
		_rest_timer = _rng.randf_range(REST_TIME_MIN, REST_TIME_MAX)
	var collision_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.34, 0.22 if resting else 0.48, 0.58)
	collision_shape.shape = shape
	collision_shape.position.y = shape.size.y * 0.5
	add_child(collision_shape)
	collision_layer = 1
	collision_mask = 0


func _process(delta: float) -> void:
	EyeBlink.apply(_blink, delta, _pivots["eyes"])
	MonkeyFigure._rebuild_tail(_pivots["_tail"] as Dictionary, delta)
	if _transitioning:
		_update_pose_transition(delta)
		_update_player_look(delta)
		return
	if _idle_pose != IdlePose.WALKING:
		_rest_timer -= delta
		if _rest_timer <= 0.0:
			_set_idle_pose(IdlePose.WALKING)
		_update_player_look(delta)
		return

	_decision_timer -= delta
	if not _has_target or Vector2(global_position.x, global_position.z).distance_to(_target) <= ARRIVE_DISTANCE:
		_has_target = false
		if _decision_timer <= 0.0 and _rng.randf() < REST_CHANCE_PER_TARGET:
			_set_idle_pose(IdlePose.CURLED if _rng.randf() < 0.5 else IdlePose.SITTING)
			_update_player_look(delta)
			return
		_pick_target()
		_decision_timer = _rng.randf_range(WALK_TARGET_MIN_TIME, WALK_TARGET_MAX_TIME)
	_walk(delta)
	_update_player_look(delta)


func _rebuild_figure() -> void:
	var old_rig := get_node_or_null("CatFigure")
	if old_rig != null:
		remove_child(old_rig)
		old_rig.queue_free()
	# Always construct the canonical standing skeleton. Resting is a live
	# interpolation over these same pivots, never a replacement rig.
	if is_yogi:
		_pivots = CatFigure.build(
			self, CatFigure.YOGI_COAT_COLOR, false, curl_side,
			CatFigure.YOGI_MARKING_COLOR, CatFigure.YOGI_MARKED_EAR_SIDE,
			CatFigure.YOGI_FULL_LEG_SIDE, CatFigure.YOGI_LOWER_SOCK_SIDE, true
		)
	else:
		_pivots = CatFigure.build(self, coat_color, false, curl_side)
	_tail_stand_points = ((_pivots["_tail"] as Dictionary)["base_points"] as Array[Vector3]).duplicate()
	_leg_rest.clear()
	for leg_name in ["front_left", "front_right", "hind_left", "hind_right"]:
		var leg: Dictionary = _pivots["legs"][leg_name]
		_leg_rest[leg_name] = Vector3(
			(leg["root"] as Node3D).rotation.x,
			(leg["middle"] as Node3D).rotation.x,
			(leg["distal"] as Node3D).rotation.x
		)


func _set_idle_pose(pose: IdlePose) -> void:
	if _idle_pose == pose and not _transitioning:
		return
	# Idle poses only transition to/from walking, which keeps one clear
	# anatomical source and target for every blend.
	_transition_pose = _idle_pose if pose == IdlePose.WALKING else pose
	_idle_pose = pose
	resting = pose == IdlePose.CURLED
	sitting = pose == IdlePose.SITTING
	_has_target = false
	_walk_phase = 0.0
	_transition_leg_start.clear()
	for leg_name in ["front_left", "front_right", "hind_left", "hind_right"]:
		var leg: Dictionary = _pivots["legs"][leg_name]
		_transition_leg_start[leg_name] = [
			(leg["root"] as Node3D).rotation.x,
			(leg["root"] as Node3D).rotation.z,
			(leg["middle"] as Node3D).rotation.x,
			(leg["distal"] as Node3D).rotation.x,
		]
	if pose == IdlePose.CURLED:
		curl_side = -1.0 if _rng.randf() < 0.5 else 1.0
		_rest_timer = 0.0
	elif pose == IdlePose.SITTING:
		_rest_timer = 0.0
	_pose_target = 0.0 if pose == IdlePose.WALKING else 1.0
	_transitioning = true


func _update_pose_transition(delta: float) -> void:
	_pose_blend = move_toward(_pose_blend, _pose_target, delta / POSE_TRANSITION_DURATION)
	# Smoothstep removes the mechanical constant-speed start and stop while
	# preserving one monotonic blend shared by every part of the animal.
	var eased := _pose_blend * _pose_blend * (3.0 - 2.0 * _pose_blend)
	_apply_pose_blend(eased)
	if is_equal_approx(_pose_blend, _pose_target):
		_transitioning = false
		if _idle_pose != IdlePose.WALKING:
			_rest_timer = _rng.randf_range(REST_TIME_MIN, REST_TIME_MAX)
		else:
			_pick_target()
			_decision_timer = _rng.randf_range(WALK_TARGET_MIN_TIME, WALK_TARGET_MAX_TIME)


func _apply_pose_blend(weight: float) -> void:
	if _transition_pose == IdlePose.SITTING:
		_apply_sitting_blend(weight)
	else:
		_apply_curled_blend(weight)


func _apply_curled_blend(weight: float) -> void:
	var rig := _pivots["_rig"] as Node3D
	rig.position.y = lerpf(CatFigure.STANDING_BODY_Y, CatFigure.RESTING_BODY_Y, weight)
	var hips := _pivots["hips"] as Node3D
	var abdomen := _pivots["abdomen"] as Node3D
	var thorax := _pivots["thorax"] as Node3D
	hips.rotation.y = curl_side * deg_to_rad(16.0) * weight
	abdomen.rotation.y = curl_side * deg_to_rad(23.0) * weight
	thorax.rotation.y = curl_side * deg_to_rad(28.0) * weight

	var neck := _pivots["neck"] as Node3D
	neck.position.y = lerpf(0.01, -0.005, weight)
	_neck_pose_pitch = lerpf(deg_to_rad(65.0), deg_to_rad(68.0), weight)
	_neck_pose_yaw = curl_side * deg_to_rad(18.0) * weight
	_head_pose_pitch = lerpf(deg_to_rad(-45.0), deg_to_rad(-43.0), weight)
	neck.rotation.x = _neck_pose_pitch
	neck.rotation.y = _neck_pose_yaw
	(_pivots["head"] as Node3D).rotation.x = _head_pose_pitch

	for leg_name in ["front_left", "front_right", "hind_left", "hind_right"]:
		var front := (leg_name as String).begins_with("front")
		var target_angles: Array = CatFigure.REST_FRONT_ANGLES if front else CatFigure.REST_HIND_ANGLES
		var stand_angles: Array = CatFigure.STAND_FRONT_ANGLES if front else CatFigure.STAND_HIND_ANGLES
		var side := 1.0 if (leg_name as String).ends_with("left") else -1.0
		var leg: Dictionary = _pivots["legs"][leg_name]
		if _transitioning and _idle_pose == IdlePose.CURLED and _transition_leg_start.has(leg_name):
			# Entering rest may begin at any point in the walk cycle. Blend from
			# those exact live joint angles so the first transition frame cannot
			# snap the leg through the canonical standing pose.
			var start: Array = _transition_leg_start[leg_name]
			(leg["root"] as Node3D).rotation.x = lerpf(start[0], target_angles[0], weight)
			(leg["root"] as Node3D).rotation.z = lerpf(start[1], side * deg_to_rad(-38.0), weight)
			(leg["middle"] as Node3D).rotation.x = lerpf(start[2], target_angles[1], weight)
			(leg["distal"] as Node3D).rotation.x = lerpf(start[3], target_angles[2], weight)
		else:
			(leg["root"] as Node3D).rotation.x = lerpf(stand_angles[0], target_angles[0], weight)
			(leg["root"] as Node3D).rotation.z = side * deg_to_rad(-38.0) * weight
			(leg["middle"] as Node3D).rotation.x = lerpf(stand_angles[1], target_angles[1], weight)
			(leg["distal"] as Node3D).rotation.x = lerpf(stand_angles[2], target_angles[2], weight)
		_level_paw(leg)

	var tail: Dictionary = _pivots["_tail"]
	var anchor := _tail_stand_points[0]
	var rest_points: Array[Vector3] = _tail_stand_points.duplicate()
	# Point 1 controls the tangent as the tail exits the rump. Swing it
	# mostly sideways, not merely the later points, so the attachment angle
	# itself participates in the lying-body curl.
	rest_points[1] = anchor + Vector3(curl_side * 0.14, -0.035, -0.045)
	rest_points[2] = anchor + Vector3(curl_side * 0.25, -0.055, -0.12)
	rest_points[3] = anchor + Vector3(curl_side * 0.31, -0.055, -0.02)
	var blended_points: Array[Vector3] = []
	for i in _tail_stand_points.size():
		blended_points.append(_tail_stand_points[i].lerp(rest_points[i], weight))
	tail["base_points"] = blended_points
	MonkeyFigure._rebuild_tail(tail, 0.0)


func _apply_sitting_blend(weight: float) -> void:
	var rig := _pivots["_rig"] as Node3D
	rig.position.y = lerpf(CatFigure.STANDING_BODY_Y, SIT_BODY_Y, weight)
	var hips := _pivots["hips"] as Node3D
	var abdomen := _pivots["abdomen"] as Node3D
	var thorax := _pivots["thorax"] as Node3D
	hips.rotation.x = SIT_HIPS_PITCH * weight
	abdomen.rotation.x = SIT_ABDOMEN_PITCH * weight
	thorax.rotation.x = SIT_THORAX_PITCH * weight
	hips.rotation.y = 0.0
	abdomen.rotation.y = 0.0
	thorax.rotation.y = 0.0

	# The trunk's accumulated -42-degree pitch raises the chest. Matching
	# neck pitch cancels it, leaving the neck upright and the head level and
	# forward as in the supplied reference.
	var neck := _pivots["neck"] as Node3D
	neck.position.y = lerpf(0.01, 0.018, weight)
	_neck_pose_pitch = lerpf(deg_to_rad(65.0), deg_to_rad(42.0), weight)
	_neck_pose_yaw = 0.0
	_head_pose_pitch = lerpf(deg_to_rad(-45.0), 0.0, weight)
	neck.rotation.x = _neck_pose_pitch
	neck.rotation.y = _neck_pose_yaw
	(_pivots["head"] as Node3D).rotation.x = _head_pose_pitch

	for leg_name in ["front_left", "front_right", "hind_left", "hind_right"]:
		var front := (leg_name as String).begins_with("front")
		var stand_angles: Array = CatFigure.STAND_FRONT_ANGLES if front else CatFigure.STAND_HIND_ANGLES
		var sit_angles: Array = SIT_FRONT_ANGLES if front else SIT_HIND_ANGLES
		var side := 1.0 if (leg_name as String).ends_with("left") else -1.0
		var leg: Dictionary = _pivots["legs"][leg_name]
		var stand_root_y := -0.015 * CatFigure.BODY_SCALE if front else 0.02 * CatFigure.BODY_SCALE
		(leg["root"] as Node3D).position.y = lerpf(
			stand_root_y, SIT_FRONT_SHOULDER_Y if front else stand_root_y, weight
		)
		if _transitioning and _idle_pose == IdlePose.SITTING and _transition_leg_start.has(leg_name):
			var start: Array = _transition_leg_start[leg_name]
			(leg["root"] as Node3D).rotation.x = lerpf(start[0], sit_angles[0], weight)
			(leg["root"] as Node3D).rotation.z = lerpf(start[1], 0.0 if front else side * deg_to_rad(-42.0), weight)
			(leg["middle"] as Node3D).rotation.x = lerpf(start[2], sit_angles[1], weight)
			(leg["distal"] as Node3D).rotation.x = lerpf(start[3], sit_angles[2], weight)
		else:
			(leg["root"] as Node3D).rotation.x = lerpf(stand_angles[0], sit_angles[0], weight)
			(leg["root"] as Node3D).rotation.z = (0.0 if front else side * deg_to_rad(-42.0)) * weight
			(leg["middle"] as Node3D).rotation.x = lerpf(stand_angles[1], sit_angles[1], weight)
			(leg["distal"] as Node3D).rotation.x = lerpf(stand_angles[2], sit_angles[2], weight)
		# Account for the pitched body ancestor too. Front long bones become
		# vertical, then their paws pitch forward/down to finish the ground
		# reach without pulling the shoulder sockets away from the thorax.
		var body_pitch := (SIT_HIPS_PITCH + (SIT_ABDOMEN_PITCH + SIT_THORAX_PITCH if front else 0.0)) * weight
		var desired_world_paw_pitch := SIT_FRONT_PAW_PITCH * weight if front else 0.0
		(leg["paw"] as Node3D).rotation.x = -(
			body_pitch + (leg["root"] as Node3D).rotation.x
			+ (leg["middle"] as Node3D).rotation.x
			+ (leg["distal"] as Node3D).rotation.x
		) + desired_world_paw_pitch
		if not front:
			# Counter the outward folding roll at the paw so its pad, rather
			# than an outer edge, is the seated ground-contact surface.
			(leg["paw"] as Node3D).rotation.z = -(leg["root"] as Node3D).rotation.z
			_ground_seated_hind_paw(leg, weight)

	var tail: Dictionary = _pivots["_tail"]
	var anchor := _tail_stand_points[0]
	var sit_points: Array[Vector3] = _tail_stand_points.duplicate()
	# A seated cat lifts the tail clear of the floor as the pelvis pitches,
	# then carries it sideways before letting it settle. Positive local Y at
	# the first two controls changes the base tangent itself, rather than
	# merely bending an already downward-pointing tail farther along.
	sit_points[1] = anchor + Vector3(curl_side * 0.13, 0.055, -0.035)
	sit_points[2] = anchor + Vector3(curl_side * 0.25, 0.035, -0.09)
	sit_points[3] = anchor + Vector3(curl_side * 0.32, 0.015, 0.01)
	var points: Array[Vector3] = []
	for i in _tail_stand_points.size():
		points.append(_tail_stand_points[i].lerp(sit_points[i], weight))
	tail["base_points"] = points
	MonkeyFigure._rebuild_tail(tail, 0.0)


func _ground_seated_hind_paw(leg: Dictionary, weight: float) -> void:
	# Solve the final few millimetres from the live articulated result rather
	# than guessing another joint angle. At full sit the paw pad's lower face
	# is exactly Y=0 in cat-local space; during transition the correction
	# eases in with the rest of the pose. Dividing by the hip parent's
	# vertical basis component converts the desired world/local-Y correction
	# back into the root pivot's own local-Y coordinate.
	var paw_mesh := leg["paw_mesh"] as MeshInstance3D
	var paw_center_y := to_local(paw_mesh.global_position).y
	var paw_half_height := 0.022 * CatFigure.BODY_SCALE
	var desired_delta_y := (paw_half_height - paw_center_y) * weight
	var parent_vertical := maxf(cos(SIT_HIPS_PITCH * weight), 0.2)
	(leg["root"] as Node3D).position.y += desired_delta_y / parent_vertical


func _pick_target() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var radius := ROAM_RADIUS * sqrt(_rng.randf())
	_target = _roam_center + Vector2(cos(angle), sin(angle)) * radius
	_has_target = true


## Manchego-style look composition: target bearing is measured entirely on
## the world-horizontal plane, then split between the base of the neck and
## base of the skull. Applying each share around true world UP avoids the
## sideways head-roll produced by local Euler yaw on a strongly pitched
## neck. Pose pitch/curl values are cached by the blend functions above and
## reapplied here, so look remains an additive layer over every idle state.
func _update_player_look(delta: float) -> void:
	var target_yaw := 0.0
	# Curled rest is a disengaged lying pose: suppress target acquisition for
	# the descent, the full rest, and the rise back out. `_transition_pose`
	# stays CURLED during that final rise even after `_idle_pose` becomes
	# WALKING, which prevents the eyes/head reacquiring the player too early.
	var curled_pose_active := (
		_idle_pose == IdlePose.CURLED
		or (_transitioning and _transition_pose == IdlePose.CURLED)
	)
	if not curled_pose_active and is_instance_valid(_player):
		var to_player := _player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() <= PLAYER_LOOK_DISTANCE and to_player.length_squared() > 0.0001:
			var world_bearing := atan2(to_player.x, to_player.z)
			target_yaw = clampf(
				angle_difference(rotation.y, world_bearing), -HEAD_YAW_LIMIT, HEAD_YAW_LIMIT
			)
	_current_head_yaw = lerp_angle(_current_head_yaw, target_yaw, HEAD_TURN_SPEED * delta)
	var neck_share := _current_head_yaw * NECK_LOOK_SHARE
	var head_share := _current_head_yaw - neck_share
	var thorax := _pivots["thorax"] as Node3D
	var neck := _pivots["neck"] as Node3D
	var head := _pivots["head"] as Node3D
	var neck_pose := Basis(Vector3.UP, _neck_pose_yaw) * Basis(Vector3.RIGHT, _neck_pose_pitch)
	neck.global_transform.basis = Basis(Vector3.UP, neck_share) * thorax.global_transform.basis * neck_pose
	var head_pose := Basis(Vector3.RIGHT, _head_pose_pitch)
	head.global_transform.basis = Basis(Vector3.UP, head_share) * neck.global_transform.basis * head_pose


func _walk(delta: float) -> void:
	var here := Vector2(global_position.x, global_position.z)
	var toward := _target - here
	if toward.length() <= 0.001:
		return
	var step := toward.limit_length(WALK_SPEED * delta)
	var next := here + step
	global_position.x = next.x
	global_position.z = next.y
	rotation.y = lerp_angle(rotation.y, atan2(toward.x, toward.y), TURN_SPEED * delta)
	if _terrain != null and _terrain.has_method("get_mesh_height"):
		var ground: float = _terrain.get_mesh_height(global_position.x, global_position.z)
		global_position.y = move_toward(global_position.y, ground, GROUND_SETTLE_SPEED * delta)
	_walk_phase += delta * WALK_CYCLE_SPEED
	_animate_walk_cycle()


func _animate_walk_cycle() -> void:
	# Four distinct beats, following the same front-vs-hind group staggering
	# used by HorseFigure: hind-left -> front-left -> hind-right ->
	# front-right. No front leg shares a phase with a hind leg, and neither
	# diagonal pair moves in lockstep.
	var phase_by_leg := {
		"hind_left": 0.0,
		"front_left": PI * 0.5,
		"hind_right": PI,
		"front_right": PI * 1.5,
	}
	for leg_name in phase_by_leg:
		var phase: float = _walk_phase + (phase_by_leg[leg_name] as float)
		var leg: Dictionary = _pivots["legs"][leg_name]
		var rest: Vector3 = _leg_rest[leg_name]
		# Left-side roots roll negative and right-side roots positive. Since
		# each bone extends down local -Y, those signs carry both feet inward
		# toward X=0 rather than splaying them away from the body.
		var side := 1.0 if (leg_name as String).ends_with("left") else -1.0
		(leg["root"] as Node3D).rotation.z = -side * WALK_INWARD_LEG_ROLL
		if (leg_name as String).begins_with("front"):
			_animate_front_leg(leg, rest, phase)
		else:
			_animate_hind_leg(leg, rest, phase)
		_level_paw(leg)


func _animate_front_leg(leg: Dictionary, rest: Vector3, phase: float) -> void:
	var stride := sin(phase)
	var stride_amount := FRONT_STRIDE_FORWARD if stride > 0.0 else FRONT_STRIDE_BACK
	var lift := maxf(stride, 0.0)
	var support := maxf(-stride, 0.0)
	# Shoulder advances the entire leg. During swing the elbow folds forward
	# and the carpus folds back much more strongly, lifting the paw clear;
	# during support both joints extend slightly to carry the body.
	(leg["root"] as Node3D).rotation.x = rest.x - stride * stride_amount
	(leg["middle"] as Node3D).rotation.x = (
		rest.y - lift * FRONT_ELBOW_LIFT + support * deg_to_rad(5.0)
	)
	(leg["distal"] as Node3D).rotation.x = (
		rest.z + lift * FRONT_CARPUS_LIFT - support * deg_to_rad(4.0)
	)


func _animate_hind_leg(leg: Dictionary, rest: Vector3, phase: float) -> void:
	var stride := sin(phase)
	var stride_amount := HIND_STRIDE_FORWARD if stride > 0.0 else HIND_STRIDE_BACK
	var lift := maxf(stride, 0.0)
	var support := maxf(-stride, 0.0)
	# The longer feline hind chain folds differently: femur advances, stifle
	# closes, and the hock flexes sharply under the body before extending for
	# the planted/rearward part of the step.
	(leg["root"] as Node3D).rotation.x = rest.x - stride * stride_amount
	(leg["middle"] as Node3D).rotation.x = (
		rest.y + lift * HIND_STIFLE_LIFT - support * deg_to_rad(5.0)
	)
	(leg["distal"] as Node3D).rotation.x = (
		rest.z + lift * HIND_HOCK_LIFT - support * deg_to_rad(5.0)
	)


func _level_paw(leg: Dictionary) -> void:
	# The paw is the fourth articulated link, counter-rotating against all
	# three long-bone pivots so its pad stays level through swing and stance.
	(leg["paw"] as Node3D).rotation.x = -(
		(leg["root"] as Node3D).rotation.x
		+ (leg["middle"] as Node3D).rotation.x
		+ (leg["distal"] as Node3D).rotation.x
	)
