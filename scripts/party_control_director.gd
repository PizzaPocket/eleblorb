extends Node

## Single source of truth for which persistent party actor owns the player's
## point of view. Party membership and playability are deliberately separate:
## ordinary blorbs, companions, mounts, and summons can all belong to the
## party without automatically entering the switch cycle.

signal active_member_changed(previous: Node3D, current: Node3D)
signal control_override_changed(previous: Node3D, current: Node3D, source: Node3D)

const HUMAN_ID := "player"
const BLORBUS_ID := "blorbus"
const XIAO_HOU_ZI_ID := "xiao_hou_zi"

var _active_member_id: String = HUMAN_ID
var _active_member: Node3D
var _control_override: Node3D
var _control_override_source: Node3D


func register_member(member: Node3D) -> void:
	if member == null or not member.has_method("playable_id"):
		return
	if String(member.playable_id()) == _active_member_id:
		_active_member = member


func unregister_member(member: Node3D) -> void:
	if _active_member == member:
		_active_member = null
	if _control_override == member:
		_control_override = null
		_control_override_source = null


func active_member() -> Node3D:
	return _active_member if is_instance_valid(_active_member) else null


func active_member_id() -> String:
	return _active_member_id


func active_control_body() -> Node3D:
	if is_instance_valid(_control_override):
		return _control_override
	return active_member()


func is_active(member_or_id: Variant) -> bool:
	if member_or_id is String:
		return _active_member_id == member_or_id
	return active_member() == member_or_id


func set_active_member(member: Node3D) -> bool:
	if member == null or not member.has_method("playable_id"):
		return false
	if member.has_method("is_playable_available") and not member.is_playable_available():
		return false
	var previous := active_member()
	if previous == member:
		return true
	if previous != null and previous.has_method("end_direct_control"):
		previous.end_direct_control()
	_control_override = null
	_control_override_source = null
	_active_member = member
	_active_member_id = String(member.playable_id())
	if member.has_method("begin_direct_control"):
		member.begin_direct_control()
	active_member_changed.emit(previous, member)
	return true


func control_source() -> Node3D:
	return _control_override_source if is_instance_valid(_control_override_source) else active_member()


func set_control_override(body: Node3D, source: Node3D = null) -> void:
	var previous := _control_override
	_control_override = body
	_control_override_source = source if is_instance_valid(source) else active_member()
	control_override_changed.emit(previous, body, _control_override_source)


func clear_control_override(body: Node3D = null) -> void:
	if body == null or _control_override == body:
		var previous := _control_override
		_control_override = null
		_control_override_source = null
		control_override_changed.emit(previous, null, null)


func member_capability(member: Node, capability: StringName) -> bool:
	return member != null and member.has_method("has_playable_capability") and member.has_playable_capability(capability)


func switchable_members(tree: SceneTree) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for node in tree.get_nodes_in_group("party_playable_candidates"):
		if node is Node3D and node.has_method("is_playable_available") and node.is_playable_available():
			result.append(node)
	result.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		var a_order: int = int(a.playable_switch_order()) if a.has_method("playable_switch_order") else 1000
		var b_order: int = int(b.playable_switch_order()) if b.has_method("playable_switch_order") else 1000
		if a_order == b_order:
			return String(a.playable_id()) < String(b.playable_id())
		return a_order < b_order
	)
	return result


func adjacent_switchable_member(tree: SceneTree, direction: int) -> Node3D:
	var members: Array[Node3D] = switchable_members(tree)
	if members.is_empty():
		return null
	var current_index: int = -1
	for index in members.size():
		if members[index] == active_member():
			current_index = index
			break
	if current_index < 0:
		current_index = 0
	var step: int = -1 if direction < 0 else 1
	return members[posmod(current_index + step, members.size())]
