class_name RigAdapter
extends RefCounted

## A character's joints, addressed by the rig-neutral names every rig in this
## project already publishes through its own _blorb_suit_pivot_map()
## (player.gd, xiao_hou_zi.gd): "arm_left_shoulder", "leg_right_ankle",
## "spine", "head" and so on. One vocabulary, several skeletons.
##
## Rigs differ in what they actually have, and MEASURED, not assumed (see the
## comment above MonkeyFigure.build()): on Xiao Hou Zi's rig "hand", "wrist"
## and "fingertip" are all one marker, "ankle" and "toe" are one marker with
## no children, and there is no thorax or neck at all. A pose that writes to
## an aliased or absent joint does nothing, silently, which is exactly how
## the skate, penguin, snowboard and mermaid foot poses came to be no-ops on
## him without anyone noticing.
##
## So this reports the truth about each joint instead of hiding it. A mode
## asks what it has and supplies its own fallback once, rather than every
## mode rediscovering the same gap.

enum Joint { REAL, ALIASED, ABSENT }

## A joint carrying this marks itself as driving geometry that no scene-graph
## inspection can find, because a per-frame rebuild realises it instead.
const DRIVES_GEOMETRY_META := &"rig_drives_geometry"

var _joints: Dictionary = {}
## Aliased names, mapped to the first name that claimed the same node.
var _aliases: Dictionary = {}
## Cached results of articulates(), which measures rather than assumes.
var _measured: Dictionary = {}


func _init(pivot_map: Dictionary = {}) -> void:
	var seen: Dictionary = {}
	for name in pivot_map:
		var node: Node3D = pivot_map[name] as Node3D
		if node == null:
			continue
		var key := String(name)
		_joints[key] = node
		var id := node.get_instance_id()
		if seen.has(id):
			_aliases[key] = seen[id]
		else:
			seen[id] = key


## The node behind a joint name, or null when this rig has no such joint.
func joint(name: String) -> Node3D:
	var node: Node3D = _joints.get(name) as Node3D
	return node if is_instance_valid(node) else null


## REAL: its own node. ALIASED: shares a node with another joint, so writing
## to it moves whatever that other joint moves. ABSENT: not on this rig.
func state(name: String) -> Joint:
	if not _joints.has(name):
		return Joint.ABSENT
	return Joint.ALIASED if _aliases.has(name) else Joint.REAL


## True for a joint that has its own node. Necessary but NOT sufficient for a
## pose to show: see articulates().
func has_real(name: String) -> bool:
	return state(name) == Joint.REAL


## True when rotating this joint actually moves the rig. MEASURED once, by
## turning the joint and watching whether anything downstream moves, because
## structure alone cannot answer it: Xiao Hou Zi's ankle marker is its own
## node yet has nothing hanging off it, while his shoulders drive limb meshes
## that are not their children at all (MonkeyFigure rebuilds those each frame
## under the rig root). Rotating that ankle moves nothing, which is how four
## separate foot poses became silent no-ops on him.
##
## A mode that needs a joint to show should ask this, not has_real().
func articulates(name: String) -> bool:
	if not has_real(name):
		return false
	if _measured.has(name):
		return bool(_measured[name])
	# A rig whose geometry is rebuilt each frame rather than parented to its
	# joints can say so itself, because no amount of watching the scene graph
	# will reveal it: Xiao Hou Zi's foot follows his ankle marker through
	# MonkeyFigure's own limb rebuild, with nothing hanging off that marker at
	# all (see _rebuild_footed_leg()).
	var declared := joint(name)
	if declared != null and bool(declared.get_meta(DRIVES_GEOMETRY_META, false)):
		_measured[name] = true
		return true
	# Either test alone has a blind spot: a joint can drive a mesh of its own
	# with no joint below it (the head), or drive a mesh that is not its child
	# at all through a rebuild (Xiao Hou Zi's whole limbs). A joint needs only
	# one of the two to show.
	var moves := _drives_geometry(joint(name)) or _measure_joint(name)
	_measured[name] = moves
	return moves


## A mesh under the joint necessarily follows it, no measurement needed.
static func _drives_geometry(node: Node3D) -> bool:
	if node == null:
		return false
	for child in node.get_children():
		if child is MeshInstance3D:
			return true
		if child is Node3D and _drives_geometry(child as Node3D):
			return true
	return false


## Turns the joint and looks for movement anywhere else in the rig. Restores
## the joint exactly, and is cached, so this costs one perturbation per joint
## for the lifetime of the body.
func _measure_joint(name: String) -> bool:
	var pivot := joint(name)
	if pivot == null or not pivot.is_inside_tree():
		return false
	var watched: Array[Node3D] = []
	var before: Array[Vector3] = []
	for other in _joints.values():
		var node: Node3D = other as Node3D
		if node == null or node == pivot or not node.is_inside_tree():
			continue
		watched.append(node)
		before.append(node.global_position)
	var rest := pivot.rotation
	pivot.rotation = rest + Vector3(0.25, 0.0, 0.0)
	var moved := false
	for index in watched.size():
		if watched[index].global_position.distance_to(before[index]) > 0.0005:
			moved = true
			break
	pivot.rotation = rest
	return moved


## Every joint that both exists and moves something, which is what the parity
## probe should compare between characters.
func articulated_joints() -> Array[String]:
	var names: Array[String] = []
	for name in _joints:
		if articulates(String(name)):
			names.append(String(name))
	names.sort()
	return names


## The joint this one shares a node with, or "" when it does not share one.
func alias_of(name: String) -> String:
	return String(_aliases.get(name, ""))


## Writes a rotation, and reports whether it landed anywhere. Callers that
## care (an ankle angle, say) check the result and fall back; callers that do
## not can ignore it.
func set_rotation(name: String, rotation: Vector3) -> bool:
	if not has_real(name):
		return false
	(joint(name) as Node3D).rotation = rotation
	return true


func set_rotation_x(name: String, angle: float) -> bool:
	if not has_real(name):
		return false
	(joint(name) as Node3D).rotation.x = angle
	return true


## Every joint this rig genuinely articulates, for reporting and for the
## parity probe.
func real_joints() -> Array[String]:
	var names: Array[String] = []
	for name in _joints:
		if has_real(String(name)):
			names.append(String(name))
	names.sort()
	return names
