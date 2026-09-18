extends Node

## Owns human fainting and paid-rest recovery across scene replacement.
## Checkpoints are stored per kingdom by stable id; scene-local RestPoint
## nodes register their live transforms whenever their world is built.

signal recovery_started(kind: StringName)
signal recovery_completed(kind: StringName)

const MORNING_HOUR := 7.0
const FAINT_HEALTH_FRACTION := 1.0
const REST_HEALTH_FRACTION := 1.0
const BLACK_HOLD_SECONDS := 0.85

var _registered_points: Dictionary = {}
var _last_rest_by_world: Dictionary = {}
var _pending: Dictionary = {}
var _recovering := false
var _overlay: ColorRect
var _message: Label
## Per direct instruction ("if it takes a while then we should show the
## same loading bar in the loading screen under saying You Fainted") --
## same UIKit.loading_progress_bar() styling the real LoadingScreen uses,
## just living directly on this overlay under the message rather than
## pulling in that whole separate screen (with its own tips/hints etc.),
## since this moment is specifically "you fainted," not an ordinary
## loading transition.
var _progress_bar: ProgressBar
## How long the black hold plays before the progress bar is allowed to
## appear at all -- a load that finishes quickly shouldn't flash a bar
## into view for one frame only to hide it again.
const PROGRESS_BAR_REVEAL_DELAY := 0.6


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()


func register_rest_point(world_id: String, point_id: String, wake: Transform3D, stand: Transform3D, party_origin: Vector3) -> void:
	_registered_points["%s:%s" % [world_id, point_id]] = {
		"wake": wake, "stand": stand, "party_origin": party_origin,
	}


func last_rest_id(world_id: String) -> String:
	return String(_last_rest_by_world.get(world_id, ""))


func rest(world_id: String, point_id: String, fee: int) -> bool:
	if _recovering or fee < 0 or not TokoinWallet.spend(fee):
		return false
	_last_rest_by_world[world_id] = point_id
	_begin_recovery(&"rest", world_id, point_id, false)
	return true


## TransactionInteraction owns payment for dialogue-driven services. This
## entry point keeps recovery concerned only with whether resting can begin.
func can_rest() -> bool:
	return not _recovering


func begin_paid_rest(world_id: String, point_id: String) -> bool:
	if _recovering:
		return false
	_last_rest_by_world[world_id] = point_id
	_begin_recovery(&"rest",world_id,point_id,false)
	return true


func faint_player() -> void:
	if _recovering:
		return
	var world_id := current_world_id()
	var point_id := last_rest_id(world_id)
	# Lose the smaller half, retaining the extra coin for odd balances.
	TokoinWallet.set_value(ceili(float(TokoinWallet.value) * 0.5))
	_begin_recovery(&"faint", world_id, point_id, true)


func _begin_recovery(kind: StringName, world_id: String, point_id: String, show_faint_message: bool) -> void:
	_recovering = true
	recovery_started.emit(kind)
	HumongousState.prepare_recovery()
	Party.capture_from_tree(get_tree())
	Party.force_recovery_resources(FAINT_HEALTH_FRACTION if kind == &"faint" else REST_HEALTH_FRACTION)
	_pending = {
		"kind": kind, "world_id": world_id, "point_id": point_id,
	}
	UIState.push_modal()
	get_tree().paused = true
	_message.text = "You fainted." if show_faint_message else ""
	_message.visible = show_faint_message
	_overlay.visible = true
	_progress_bar.visible = false
	_progress_bar.value = 0.0

	# Per direct instruction ("does the game immediately start loading in
	# the background? we want to minimise the time") -- request the actual
	# scene reload as a threaded load right away, in parallel with the
	# fade-in/hold below, rather than waiting for those to finish first and
	# only then starting a blocking change_scene_to_file() -- the exact
	# same technique loading_bootstrap.gd's own initial boot already uses.
	var scene_path := get_tree().current_scene.scene_file_path
	var threaded := ResourceLoader.load_threaded_request(scene_path) == OK

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_overlay, "modulate:a", 1.0, 0.45)
	await tween.finished
	WorldState.advance_to_morning()

	# Waits for BOTH the minimum black hold (so "You fainted." always gets
	# at least a moment to actually read, even on an instant local load)
	# AND the real load actually finishing -- showing the progress bar
	# underneath the message per direct instruction ("if it takes a while
	# then we should show the same loading bar in the loading screen under
	# saying You Fainted"), but only once it's clear this one is actually
	# taking a while (PROGRESS_BAR_REVEAL_DELAY), not for every routine
	# faint/rest.
	var elapsed := 0.0
	while true:
		var progress: Array = []
		var status := (
			ResourceLoader.load_threaded_get_status(scene_path, progress) if threaded
			else ResourceLoader.THREAD_LOAD_LOADED
		)
		if elapsed >= PROGRESS_BAR_REVEAL_DELAY and not progress.is_empty():
			_progress_bar.visible = true
			_progress_bar.value = float(progress[0])
		if elapsed >= BLACK_HOLD_SECONDS and status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			break
		await get_tree().create_timer(0.05, true).timeout
		elapsed += 0.05

	_progress_bar.visible = false
	get_tree().paused = false
	var world: PackedScene = ResourceLoader.load_threaded_get(scene_path) as PackedScene if threaded else null
	if world != null:
		get_tree().change_scene_to_packed(world)
	else:
		get_tree().change_scene_to_file(scene_path)


func has_pending_recovery() -> bool:
	return not _pending.is_empty()


func finish_scene_recovery(scene_root: Node, fallback_transform: Transform3D) -> bool:
	if _pending.is_empty():
		return false
	var world_id := String(_pending.get("world_id", current_world_id()))
	var point_id := String(_pending.get("point_id", ""))
	var data: Dictionary = _registered_points.get("%s:%s" % [world_id, point_id], {})
	var stand: Transform3D = data.get("stand", fallback_transform)
	var wake: Transform3D = data.get("wake", stand)
	var player := scene_root.get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return false
	player.global_transform = wake
	Party.spawn_into(scene_root, data.get("party_origin", stand.origin), -stand.basis.z)
	player.force_human_control(false)
	player.begin_recovery_wake(stand)
	var kind: StringName = _pending.get("kind", &"faint")
	# Per direct report ("it seemed when I died... it reset me at the
	# clearing but left my breath and HP at zero, shouldn't they be
	# refilling to 100%?") -- player.gd's own restore_for_recovery() already
	# existed to do exactly this (Party.force_recovery_resources() above
	# only restores the BLORB party members, via their own
	# restore_for_recovery(), never the human) but nothing ever actually
	# called it. Breath needs no equivalent call: it isn't persisted through
	# WorldState the way HP is, so a freshly reloaded Player already starts
	# at MAX_BREATH on its own.
	player.restore_for_recovery(FAINT_HEALTH_FRACTION if kind == &"faint" else REST_HEALTH_FRACTION)
	_pending.clear()
	_message.visible = false
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_overlay, "modulate:a", 0.0, 0.6)
	await tween.finished
	_overlay.visible = false
	UIState.pop_modal()
	_recovering = false
	recovery_completed.emit(kind)
	return true


func current_world_id() -> String:
	var scene := get_tree().current_scene
	if scene == null:
		return "outskirts"
	if scene.scene_file_path.ends_with("main.tscn"):
		return "outskirts"
	if scene.has_method("_finish_arrival") and String(scene.get("return_gate_id")) != "":
		return String(scene.get("return_gate_id"))
	return scene.scene_file_path.get_file().get_basename()


func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.modulate.a = 0.0
	_overlay.visible = false
	layer.add_child(_overlay)
	_message = UIKit.heading("")
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_message.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(_message)

	# Centered, sitting just under the (vertically centered) message text
	# above -- see this var's own doc comment for why it's a plain sibling
	# Control here rather than the real LoadingScreen.
	_progress_bar = UIKit.loading_progress_bar()
	_progress_bar.custom_minimum_size = Vector2(320, UITheme.SPACE_SM)
	_progress_bar.anchor_left = 0.5
	_progress_bar.anchor_right = 0.5
	_progress_bar.anchor_top = 0.5
	_progress_bar.anchor_bottom = 0.5
	_progress_bar.offset_left = -160
	_progress_bar.offset_right = 160
	_progress_bar.offset_top = 40
	_progress_bar.offset_bottom = 40 + UITheme.SPACE_SM
	_progress_bar.visible = false
	_overlay.add_child(_progress_bar)
