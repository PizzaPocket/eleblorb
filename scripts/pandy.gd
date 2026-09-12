class_name Pandy
extends StaticBody3D

## The giant panda companion the Chinese village's farmer hands over once
## the player delegates rule of the village to him -- see chinese_village.
## gd's own _build_farmer_and_pandy_quest(). Ambient and visible near the
## farmer from the start (in_party stays false), not a companion until that
## quest's own dialogue action flips it directly on this live node (the same
## closure-captures-the-live-node pattern jungle_kingdom_village.gd's own
## Manchego/Ossian quest already uses, not a WorldState flag -- Pandy himself
## IS the state).
##
## Uses a compact purpose-built panda silhouette: heavy white barrel body,
## black shoulders and legs, round ears, muzzle, and paired eye patches.
##
## Follows the same simple StaticBody3D-with-manual-position-updates
## pattern as sun_wu_kong.gd/xiao_hou_zi.gd (see either's own class doc
## comment for why), and persists across scene changes the same way both of
## them do -- see party.gd's own capture_from_tree()/_spawn_pandy().

const COAT_COLOR := Color(0.96, 0.96, 0.94)
const MARKING_COLOR := Color(0.08, 0.08, 0.09)
const FOLLOW_DISTANCE := 4.5
const ROTATION_SPEED := 5.0
const LOOK_DISTANCE := 16.0
const HEAD_YAW_LIMIT := 0.65
const HEAD_PITCH_LIMIT := 0.24

## Duplicated from terrain_generator.gd's own CHINESE_VILLAGE_CENTER/
## CHINESE_VILLAGE_ABYSS_RADIUS/CHINESE_VILLAGE_ABYSS_TRANSITION -- see
## sun_wu_kong.gd's own identical consts and _ground_y() for why a companion
## first found on one of chinese_village.gd's own floating islands needs to
## know about this at all (the real ground far below is the Abyss of
## Impending Doom, not anywhere he should walk down onto).
const CHINESE_VILLAGE_CENTER := Vector2(250.0, -650.0)
const CHINESE_VILLAGE_ABYSS_SAFE_RADIUS := 225.0
const CHINESE_VILLAGE_ISLAND_Y := -55.0

var in_party: bool = false
var _player: Node3D
var _terrain: Node
var _follow_speed: float = 5.5
var _visual: Node3D
var _head: Node3D
var _head_rest_position := Vector3.ZERO
var _legs: Array[Node3D] = []
var _eyes: Array[Node3D] = []
var _eye_blink := EyeBlink.new_state()
var _motion_time := 0.0
var _resting := false
var _state_timer := 4.0


func _ready() -> void:
	_visual = Node3D.new()
	_visual.name = "PandyVisual"
	add_child(_visual)
	_build_panda(_visual)
	add_to_group("pandy")
	_player = get_node_or_null("../Player")
	_terrain = get_node_or_null("../Terrain")
	if _player is Player:
		_follow_speed = (_player as Player).move_speed * 0.9
	global_position.y = _ground_y(global_position.x, global_position.z)

	var collision_shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(1.05, 0.85, 1.55)
	collision_shape.shape = collider
	collision_shape.position = Vector3(0, 0.58, 0)
	add_child(collision_shape)
	collision_layer = 1
	collision_mask = 0
	Interactable.attach(self, "Talk to Pandy", 2.2, func(): Hud.show_message("Pandy settles onto his paws and gives a quiet huff."))


func _build_panda(root: Node3D) -> void:
	var body := SuperEgg.build_part(Vector3(0.58, 0.48, 0.82), COAT_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	body.position = Vector3(0, 0.72, 0.08)
	root.add_child(body)
	var shoulder := SuperEgg.build_part(Vector3(0.59, 0.34, 0.38), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	shoulder.position = Vector3(0, 0.73, -0.34)
	root.add_child(shoulder)
	_head = Node3D.new()
	_head.position = Vector3(0, 1.03, -0.70)
	_head_rest_position = _head.position
	root.add_child(_head)
	var head_mesh := SuperEgg.build_part(Vector3(0.43, 0.40, 0.40), COAT_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	_head.add_child(head_mesh)
	for side in [-1.0, 1.0]:
		var ear := SuperEgg.build_part(Vector3(0.15, 0.16, 0.10), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		ear.position = Vector3(side * 0.31, 0.29, -0.02)
		_head.add_child(ear)
		var patch := SuperEgg.build_part(Vector3(0.13, 0.17, 0.035), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		# Project the patches clearly beyond the face and splay them outward;
		# their inner edges no longer disappear into the white head mesh.
		patch.position = Vector3(side * 0.19, 0.06, -0.385)
		patch.rotation.z = side * 0.28
		_head.add_child(patch)
		var eye := SuperEgg.build_part(Vector3(0.038, 0.052, 0.025), Color(0.92, 0.82, 0.38), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		eye.position = Vector3(side * 0.19, 0.07, -0.425)
		_head.add_child(eye)
		_eyes.append(eye)
		for z in [-0.42, 0.47]:
			var leg_pivot := Node3D.new()
			leg_pivot.position = Vector3(side * 0.38, 0.68, z)
			root.add_child(leg_pivot)
			var leg := SuperEgg.build_part(Vector3(0.18, 0.36, 0.20), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
			leg.position = Vector3(0, -0.33, 0)
			leg_pivot.add_child(leg)
			_legs.append(leg_pivot)
	var muzzle := SuperEgg.build_part(Vector3(0.23, 0.17, 0.16), COAT_COLOR.darkened(0.06), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	muzzle.position = Vector3(0, -0.09, -0.35)
	_head.add_child(muzzle)
	var nose := SuperEgg.build_part(Vector3(0.075, 0.055, 0.045), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	nose.position = Vector3(0, -0.02, -0.50)
	_head.add_child(nose)
	var tail := SuperEgg.build_part(Vector3(0.18, 0.18, 0.18), COAT_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	tail.position = Vector3(0, 0.78, 0.88)
	root.add_child(tail)


## See sun_wu_kong.gd's own identical helper -- true ordinary terrain height
## everywhere except within the Chinese village's own floating-island
## footprint.
func _ground_y(x: float, z: float) -> float:
	if Vector2(x, z).distance_to(CHINESE_VILLAGE_CENTER) < CHINESE_VILLAGE_ABYSS_SAFE_RADIUS:
		return CHINESE_VILLAGE_ISLAND_Y
	if _terrain != null and _terrain.has_method("get_mesh_height"):
		return _terrain.get_mesh_height(x, z)
	return global_position.y


func _process(delta: float) -> void:
	EyeBlink.apply(_eye_blink, delta, _eyes)
	_motion_time += delta
	_state_timer -= delta
	if _state_timer <= 0.0:
		_resting = not _resting
		_state_timer = randf_range(2.5, 5.0) if _resting else randf_range(4.0, 8.0)
	_update_head_look(delta)
	var moving: bool = false
	if not in_party or _player == null:
		_update_idle_animation(delta, moving)
		return
	var here := Vector2(global_position.x, global_position.z)
	var player_here := Vector2(_player.global_position.x, _player.global_position.z)
	var to_player := player_here - here
	if to_player.length() <= FOLLOW_DISTANCE:
		_update_idle_animation(delta, moving)
		return
	moving = true
	var step := to_player.limit_length(_follow_speed * delta)
	var new_here := here + step
	global_position.x = new_here.x
	global_position.z = new_here.y
	global_position.y = _ground_y(new_here.x, new_here.y)
	if to_player.length() > 0.01:
		var target_angle: float = atan2(to_player.x, to_player.y)
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)
	_update_idle_animation(delta, moving)


func _update_head_look(delta: float) -> void:
	if _player == null or _head == null:
		return
	var local_target: Vector3 = to_local(_player.global_position + Vector3.UP * 1.0) - _head.position
	var target_yaw: float = 0.0
	var target_pitch: float = 0.0
	if local_target.length() <= LOOK_DISTANCE:
		target_yaw = clampf(atan2(-local_target.x, -local_target.z), -HEAD_YAW_LIMIT, HEAD_YAW_LIMIT)
		var horizontal: float = Vector2(local_target.x, local_target.z).length()
		target_pitch = clampf(-atan2(local_target.y, horizontal), -HEAD_PITCH_LIMIT, HEAD_PITCH_LIMIT)
	_head.rotation.y = lerp_angle(_head.rotation.y, target_yaw, minf(1.0, delta * 4.5))
	_head.rotation.x = lerp_angle(_head.rotation.x, target_pitch, minf(1.0, delta * 4.5))


func _update_idle_animation(delta: float, moving: bool) -> void:
	if _visual == null:
		return
	# Resting settles the head and slows the breathing without lowering the
	# paws through the exact ground plane.
	_visual.position.y = move_toward(_visual.position.y, 0.0, delta * 0.3)
	_visual.scale.y = 1.0 + sin(_motion_time * 1.7) * (0.012 if _resting else 0.006)
	_visual.rotation.z = lerpf(_visual.rotation.z, sin(_motion_time * 0.7) * (0.018 if not moving else 0.0), minf(1.0, delta * 2.0))
	if _head != null:
		var rest_drop: float = -0.08 if _resting and not moving else 0.0
		_head.position.y = move_toward(_head.position.y, _head_rest_position.y + rest_drop, delta * 0.16)
	for index in _legs.size():
		var target_swing := 0.0
		if moving:
			target_swing = sin(_motion_time * 7.0 + (PI if index % 2 == 0 else 0.0)) * 0.34
		_legs[index].rotation.x = lerp_angle(_legs[index].rotation.x, target_swing, minf(1.0, delta * 9.0))
