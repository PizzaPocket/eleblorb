extends Node

## Persistent state for the unique Size blorb. Humongous is never a regular
## party-roster entry: Blorbus either carries him in his core, leaves one live
## body in the current world, or uses that body as a temporary control override.

signal changed

const MODE_RELEASED := "released"
const MODE_CARRIED := "carried"
const MODE_MERGED := "merged"
const OUTSKIRTS_SCENE := "res://scenes/main.tscn"
const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const SIZE_MULTIPLIER := 50.0
const INTERACT_MARGIN := 5.0

var mode: String = MODE_RELEASED
## Humongous begins as a free Crossroads resident. Core carrying is not a
## default party facility: Blorbus must first meet him, then deliberately
## perform the carry action at least once before Humongous can cross a gate.
var interaction_unlocked: bool = false
var has_entered_core: bool = false
var released_scene: String = OUTSKIRTS_SCENE
var _world_body: Blorb
var _interaction_area: Area3D
var _interaction_registered := false
var _transitioning := false


func _ready() -> void:
	_interaction_area = Area3D.new()
	_interaction_area.name = "HumongousInteraction"
	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = 0
	_interaction_area.set_meta("prompt", "Talk to Humongous")
	_interaction_area.set_meta("activate", _show_world_dialog)
	add_child(_interaction_area)


func _process(_delta: float) -> void:
	var should_register := false
	if mode == MODE_RELEASED and is_instance_valid(_world_body):
		_interaction_area.global_position = _world_body.global_position
		var blorbus := PartyControl.active_member()
		if blorbus is Blorb and (blorbus as Blorb).is_blorbus:
			var separation := Vector2(
				blorbus.global_position.x - _world_body.global_position.x,
				blorbus.global_position.z - _world_body.global_position.z
			).length()
			should_register = (
				PartyControl.active_control_body() == blorbus
				and separation <= Blorb.RADIUS * _world_body.size_multiplier + INTERACT_MARGIN
			)
	_set_interaction_registered(should_register)


func is_carried() -> bool:
	return mode == MODE_CARRIED


func can_cross_worlds() -> bool:
	return mode == MODE_CARRIED or (mode == MODE_MERGED and has_entered_core)


func register_world_body(body: Blorb) -> void:
	if body == null:
		return
	if mode == MODE_CARRIED or (is_instance_valid(_world_body) and _world_body != body):
		body.queue_free()
		return
	_world_body = body
	if mode == MODE_RELEASED and body.get_tree().current_scene != null:
		released_scene = body.get_tree().current_scene.scene_file_path
	body.tree_exiting.connect(_on_world_body_exiting.bind(body), CONNECT_ONE_SHOT)
	changed.emit()


func spawn_home_body(parent: Node, position: Vector3) -> Blorb:
	if mode != MODE_RELEASED or released_scene != OUTSKIRTS_SCENE:
		return null
	return _spawn_body(parent, position)


## The holistic demo deliberately stages the resident titan outside the
## Crossroads without implying he has travelled there through Blorbus's core.
## This is presentation-only placement; the ordinary kingdom travel contract
## above remains unchanged.
func spawn_demo_body(parent: Node, position: Vector3) -> Blorb:
	if mode != MODE_RELEASED or is_instance_valid(_world_body):
		return null
	return _spawn_body(parent, position)


func prepare_travel(destination_scene: String) -> void:
	# A Humongous who was never carried simply stays free at his Crossroads
	# home. Only a body deliberately released in a spoke is recalled into the
	# core on the return trip, avoiding cross-scene released-body bookkeeping.
	if (
		destination_scene == OUTSKIRTS_SCENE
		and mode == MODE_RELEASED
		and released_scene != OUTSKIRTS_SCENE
		and has_entered_core
	):
		mode = MODE_CARRIED
		changed.emit()
	_set_interaction_registered(false)
	_world_body = null


func prepare_recovery() -> void:
	# A rest/faint restores awareness to the human. A home-resident Humongous
	# remains free and is rebuilt by WildernessScatter; only a merged body or
	# one deliberately brought to a spoke is recalled during a scene rebuild.
	var current_scene := get_tree().current_scene.scene_file_path if get_tree().current_scene != null else ""
	if mode == MODE_MERGED or (mode == MODE_RELEASED and current_scene != OUTSKIRTS_SCENE and has_entered_core):
		mode = MODE_CARRIED
		changed.emit()
	_set_interaction_registered(false)
	_world_body = null


func finish_arrival(parent: Node, near_position: Vector3, facing: Vector3) -> void:
	if mode != MODE_MERGED:
		return
	var giant := _spawn_body(parent, _release_position(parent, near_position, facing))
	if giant == null:
		mode = MODE_CARRIED
		changed.emit()
		return
	await parent.get_tree().process_frame
	var player := parent.get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.begin_humongous_mind_merge(giant)


func show_carried_actions(player: Player) -> void:
	if mode != MODE_CARRIED or _transitioning:
		return
	var actions: Array[Dictionary] = [
		{"label": "Release Humongous", "callback": _release_action.bind(player)},
		{"label": "Mind merge with Humongous", "callback": _merge_from_core_action.bind(player)},
	]
	DialogUI.show_line(
		"Blorbus", "Humongous rests within the endless space of his core.",
		actions, "Cancel", Callable(), true
	)


func show_merge_exit(player: Player) -> void:
	if mode != MODE_MERGED or _transitioning:
		return
	var actions: Array[Dictionary] = [
		{"label": "Release mind merge", "callback": _end_merge_action.bind(player)},
	]
	DialogUI.show_line(
		"Blorbus", "Their two minds move as one.", actions, "Cancel", Callable(), true
	)


func carry_world_body(player: Player) -> void:
	if mode != MODE_RELEASED or not is_instance_valid(_world_body) or _transitioning:
		return
	_transitioning = true
	_set_interaction_registered(false)
	var body := _world_body
	mode = MODE_CARRIED
	has_entered_core = true
	changed.emit()
	var blorbus := PartyControl.active_member() as Node3D
	body.set_process(false)
	body.set_physics_process(false)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "global_position", blorbus.global_position, 0.35)
	tween.tween_property(body, "scale", Vector3.ONE * 0.01, 0.35)
	await tween.finished
	if is_instance_valid(body):
		body.queue_free()
	_world_body = null
	_transitioning = false
	Hud.show_message("Humongous slipped into Blorbus's core.")


func release_near_blorbus(player: Player) -> void:
	if mode != MODE_CARRIED or _transitioning:
		return
	var blorbus := PartyControl.active_member() as Node3D
	if blorbus == null:
		return
	_transitioning = true
	mode = MODE_RELEASED
	released_scene = player.get_tree().current_scene.scene_file_path
	var body := _spawn_body(player.get_parent(), _release_position(player.get_parent(), blorbus.global_position, blorbus.global_transform.basis.z))
	if body != null:
		var target_scale := body.scale
		body.scale = Vector3.ONE * 0.01
		var tween := create_tween()
		tween.tween_property(body, "scale", target_scale, 0.35)
		await tween.finished
	_transitioning = false
	changed.emit()


func mind_merge_from_core(player: Player) -> void:
	if mode != MODE_CARRIED or _transitioning:
		return
	var blorbus := PartyControl.active_member() as Node3D
	if blorbus == null:
		return
	mode = MODE_MERGED
	var body := _spawn_body(player.get_parent(), _release_position(player.get_parent(), blorbus.global_position, blorbus.global_transform.basis.z))
	changed.emit()
	if body != null:
		player.begin_humongous_mind_merge(body)


func mark_merged() -> void:
	mode = MODE_MERGED
	_set_interaction_registered(false)
	changed.emit()


func mark_released() -> void:
	mode = MODE_RELEASED
	if get_tree().current_scene != null:
		released_scene = get_tree().current_scene.scene_file_path
	changed.emit()


func _show_world_dialog() -> void:
	if mode != MODE_RELEASED or not is_instance_valid(_world_body):
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if not interaction_unlocked:
		interaction_unlocked = true
		changed.emit()
		DialogUI.show_line(
			"Humongous",
			"Blorbus reaches toward the vast mind before him. Humongous answers: quiet, curious, and willing to trust him.",
			[], "Continue", Callable(), true
		)
		return
	var actions: Array[Dictionary] = [
		{"label": "Mind merge with Humongous", "callback": _merge_world_action.bind(player)},
		{"label": "Carry Humongous in Blorbus's core", "callback": _carry_action.bind(player)},
	]
	DialogUI.show_line(
		"Humongous", "A vast, quiet thought meets Blorbus's mind.",
		actions, "Cancel", Callable(), true
	)


func _release_action(player: Player) -> void:
	DialogUI.hide_dialog()
	release_near_blorbus(player)


func _merge_from_core_action(player: Player) -> void:
	DialogUI.hide_dialog()
	mind_merge_from_core(player)


func _end_merge_action(player: Player) -> void:
	DialogUI.hide_dialog()
	player.end_humongous_mind_merge()


func _merge_world_action(player: Player) -> void:
	DialogUI.hide_dialog()
	player.begin_humongous_mind_merge(_world_body)


func _carry_action(player: Player) -> void:
	DialogUI.hide_dialog()
	carry_world_body(player)


func _spawn_body(parent: Node, position: Vector3) -> Blorb:
	if is_instance_valid(_world_body):
		return _world_body
	var giant: Blorb = BLORB_SCENE.instantiate()
	giant.blorb_name = "Humongous"
	giant.blorb_type = "size"
	giant.size_multiplier = SIZE_MULTIPLIER
	giant.vertical_scale = 0.72
	giant.movement_speed_multiplier = 0.1
	giant.allow_movement_hops = false
	giant.can_join_party = false
	giant.in_party = false
	giant.body_color = Color(0.7, 0.78, 0.72, 0.9)
	giant.position = position
	parent.add_child(giant)
	register_world_body(giant)
	return giant


func _release_position(parent: Node, origin: Vector3, facing: Vector3) -> Vector3:
	var flat := Vector3(facing.x, 0.0, facing.z).normalized()
	if flat.length_squared() < 0.01:
		flat = Vector3.FORWARD
	var result := origin + flat * (Blorb.RADIUS * SIZE_MULTIPLIER + 5.0)
	var terrain := parent.get_node_or_null("Terrain")
	if terrain != null and terrain.has_method("get_mesh_height"):
		result.y = terrain.get_mesh_height(result.x, result.z)
	return result


func _set_interaction_registered(value: bool) -> void:
	if value == _interaction_registered:
		return
	_interaction_registered = value
	if value:
		InteractionManager.enter(_interaction_area)
	else:
		InteractionManager.exit(_interaction_area)


func _on_world_body_exiting(body: Blorb) -> void:
	if _world_body == body:
		_set_interaction_registered(false)
		_world_body = null
