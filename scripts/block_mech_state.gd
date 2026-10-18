extends Node

## Persistent owner for P17's unique mech. Its body is a streamed world object
## when released, hidden in Blorbus's core when carried, and temporarily
## controlled through Player.begin_controllable_host() while piloted.

const MODE_RELEASED := "released"
const MODE_CARRIED := "carried"
const MODE_MERGED := "merged"
const MECH_SCENE: PackedScene = preload("res://scenes/block_mech.tscn")

var mode := MODE_RELEASED
var has_entered_core := false
var released_scene := "res://scenes/main.tscn"
var _world_body: Node3D
var _transitioning := false


func reset_for_new_session() -> void:
	mode = MODE_RELEASED
	has_entered_core = false
	released_scene = "res://scenes/main.tscn"
	_world_body = null
	_transitioning = false


func is_carried() -> bool:
	return mode == MODE_CARRIED


func can_cross_worlds() -> bool:
	return mode == MODE_CARRIED


func register_world_body(body: Node3D) -> void:
	if body == null:
		return
	if mode == MODE_CARRIED:
		body.queue_free()
		return
	_world_body = body
	if get_tree().current_scene != null:
		released_scene = get_tree().current_scene.scene_file_path


func show_carried_actions(player: Player) -> void:
	if mode != MODE_CARRIED or _transitioning:
		return
	var actions: Array[Dictionary] = [
		{"label": "Release the mech", "callback": _release_action.bind(player)},
		{"label": "Pilot the mech", "callback": _pilot_from_core.bind(player)},
	]
	DialogUI.show_line("Blorbus", "The mech rests within Blorbus's core.", actions, "Cancel", Callable(), true)


func _show_world_actions(body: Node3D) -> void:
	if mode != MODE_RELEASED or _transitioning or not WorldState.block_tower_mech_defeated:
		return
	var active := PartyControl.active_member()
	if not (active is Blorb and (active as Blorb).is_blorbus and PartyControl.active_control_body() == active):
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	_world_body = body
	var actions: Array[Dictionary] = [
		{"label": "Pilot the mech", "callback": _pilot_world.bind(player, body)},
		{"label": "Carry the mech in Blorbus's core", "callback": _carry_action.bind(player, body)},
	]
	DialogUI.show_line("Mech", "The visor stands open.", actions, "Cancel", Callable(), true)


func _carry_action(player: Player, body: Node3D) -> void:
	DialogUI.hide_dialog()
	if mode != MODE_RELEASED or _transitioning or not is_instance_valid(body):
		return
	_transitioning = true
	has_entered_core = true
	mode = MODE_CARRIED
	_world_body = null
	var tween := create_tween()
	tween.tween_property(body, "scale", Vector3.ONE * 0.01, 0.3)
	await tween.finished
	if is_instance_valid(body):
		body.queue_free()
	_transitioning = false


func _release_action(player: Player) -> void:
	DialogUI.hide_dialog()
	_release_near_blorbus(player)


func _pilot_world(player: Player, body: Node3D) -> void:
	DialogUI.hide_dialog()
	_start_pilot(player, body)


func _pilot_from_core(player: Player) -> void:
	DialogUI.hide_dialog()
	var blorbus := PartyControl.active_member() as Node3D
	if blorbus == null:
		return
	var body := _spawn_world_body(player.get_parent(), blorbus.global_position + blorbus.global_transform.basis.z * 2.5)
	if body != null:
		_start_pilot(player, body)


func _start_pilot(player: Player, body: Node3D) -> void:
	if not is_instance_valid(body) or mode == MODE_MERGED:
		return
	mode = MODE_MERGED
	_world_body = body
	var blorbus := PartyControl.active_member() as Node3D
	if blorbus != null:
		body.global_position = blorbus.global_position
	if player.begin_controllable_host(body, blorbus):
		return
	mode = MODE_RELEASED


func mark_released(body: Node3D = null) -> void:
	mode = MODE_RELEASED
	if is_instance_valid(body):
		_world_body = body
	if get_tree().current_scene != null:
		released_scene = get_tree().current_scene.scene_file_path


func _release_near_blorbus(player: Player) -> void:
	if mode != MODE_CARRIED or _transitioning:
		return
	var blorbus := PartyControl.active_member() as Node3D
	if blorbus == null:
		return
	var parent := player.get_parent()
	var body := _spawn_world_body(parent, blorbus.global_position + blorbus.global_transform.basis.z * 3.0)
	if body == null:
		return
	mode = MODE_RELEASED
	_world_body = body
	_transitioning = false


func _spawn_world_body(parent: Node, at: Vector3) -> Node3D:
	if parent == null:
		return null
	var body := MECH_SCENE.instantiate() as Node3D
	if body == null:
		return null
	if body.has_method("set_boss_mode"):
		body.set_boss_mode(false)
	else:
		body.set("boss_mode", false)
	parent.add_child(body)
	body.global_position = at
	_world_body = body
	return body
