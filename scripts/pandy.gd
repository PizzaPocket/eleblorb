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


func _ready() -> void:
	var visual := Node3D.new()
	visual.name = "PandyVisual"
	add_child(visual)
	_build_panda(visual)
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
	var head := SuperEgg.build_part(Vector3(0.43, 0.40, 0.40), COAT_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	head.position = Vector3(0, 1.03, -0.70)
	root.add_child(head)
	for side in [-1.0, 1.0]:
		var ear := SuperEgg.build_part(Vector3(0.15, 0.16, 0.10), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		ear.position = Vector3(side * 0.31, 1.32, -0.72)
		root.add_child(ear)
		var patch := SuperEgg.build_part(Vector3(0.13, 0.17, 0.035), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		patch.position = Vector3(side * 0.17, 1.09, -1.045)
		patch.rotation.z = side * 0.18
		root.add_child(patch)
		var eye := SuperEgg.build_part(Vector3(0.038, 0.052, 0.025), Color(0.92, 0.82, 0.38), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		eye.position = Vector3(side * 0.17, 1.10, -1.078)
		root.add_child(eye)
		for z in [-0.42, 0.47]:
			var leg := SuperEgg.build_part(Vector3(0.18, 0.36, 0.20), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
			leg.position = Vector3(side * 0.38, 0.35, z)
			root.add_child(leg)
	var muzzle := SuperEgg.build_part(Vector3(0.23, 0.17, 0.16), COAT_COLOR.darkened(0.06), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	muzzle.position = Vector3(0, 0.94, -1.02)
	root.add_child(muzzle)
	var nose := SuperEgg.build_part(Vector3(0.075, 0.055, 0.045), MARKING_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	nose.position = Vector3(0, 1.01, -1.17)
	root.add_child(nose)


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
	if not in_party or _player == null:
		return
	var here := Vector2(global_position.x, global_position.z)
	var player_here := Vector2(_player.global_position.x, _player.global_position.z)
	var to_player := player_here - here
	if to_player.length() <= FOLLOW_DISTANCE:
		return
	var step := to_player.limit_length(_follow_speed * delta)
	var new_here := here + step
	global_position.x = new_here.x
	global_position.z = new_here.y
	global_position.y = _ground_y(new_here.x, new_here.y)
	if to_player.length() > 0.01:
		var target_angle := atan2(to_player.x, to_player.y)
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)
