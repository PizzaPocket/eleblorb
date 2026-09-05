extends CanvasLayer

## One loading-state owner for native boot, web boot, and later portal travel.
## The browser overlay owns initial web boot until complete() explicitly says
## that Eleblorb's world is ready; this CanvasLayer owns every other case.

const TIP_INTERVAL := 3.2
const READY_HOLD_DURATION := 0.18
const WEB_WORLD_PROGRESS_START := 0.90
const WEB_WORLD_PROGRESS_END := 0.97

const KEYBOARD_TIPS := [
	"Press F near people, objects, and Blorbs to interact.",
	"Press Tab to open Items, Blorbs, and your Character.",
	"Press T to toggle your Blorb suit.",
	"Bounce off a Blorb and jump as you land to leap higher.",
	"A compass can point you toward wild Blorbs.",
]
const CONTROLLER_TIPS := [
	"Press X near people, objects, and Blorbs to interact.",
	"Use the View button to open Items, Blorbs, and your Character.",
	"Press D-pad Up to toggle your Blorb suit.",
	"Bounce off a Blorb and press Y as you land to leap higher.",
	"A compass can point you toward wild Blorbs.",
]
const TOUCH_TIPS := [
	"Tap an action when you are close enough to interact.",
	"Open your inventory to see Items, Blorbs, and your Character.",
	"Use the Blorb suit action to wear your party Blorbs.",
	"Bounce off a Blorb and jump as you land to leap higher.",
	"A compass can point you toward wild Blorbs.",
]

var _screen: Control
var _content: VBoxContainer
var _phase_label: Label
var _progress_bar: ProgressBar
var _primary_hint_label: Label
var _tip_label: Label
var _tip_index := 0
var _elapsed := 0.0
var _finishing := false
var _completion_requested := false
var _initial_boot := true
var _web_loader_active := false
var _phase := "Preparing Eleblorb…"
var _progress := 0.0
var _owns_modal_lock := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_acquire_modal_lock()
	_web_loader_active = _detect_web_loader()
	if not _web_loader_active:
		_build_ui()


func _process(delta: float) -> void:
	if _finishing or (_screen == null and not _web_loader_active):
		return
	_elapsed += delta
	if _elapsed >= TIP_INTERVAL:
		_elapsed = 0.0
		_tip_index = (_tip_index + 1) % _tips().size()
		_show_tip()


func complete() -> void:
	if _finishing or _completion_requested:
		return
	_completion_requested = true
	set_phase("Ready", 1.0)
	if _initial_boot and _web_loader_active:
		_web_eval("window.eleblorbWorldReady && window.eleblorbWorldReady();")
		_initial_boot = false
		_finishing = true
		var unlock_timer := get_tree().create_timer(0.37, true, false, true)
		unlock_timer.timeout.connect(_release_modal_lock)
		return
	_initial_boot = false
	if _screen == null:
		return
	var ready_hold := create_tween()
	ready_hold.tween_interval(READY_HOLD_DURATION)
	ready_hold.tween_callback(_fade_out)


## Re-shows the overlay for a kingdom_travel.gd portal trip -- the boot
## overlay built in _build_ui() is freed once complete()'s fade finishes, so
## this rebuilds it and resets the same flags complete()/_fade_out() guard
## on, letting a second (or third...) complete() call work normally again.
func begin_transition() -> void:
	_initial_boot = false
	_acquire_modal_lock()
	_finishing = false
	_completion_requested = false
	_elapsed = 0.0
	_phase = "Travelling…"
	_progress = 0.0
	if _screen == null:
		_build_ui()
	else:
		_screen.modulate.a = 1.0
	_refresh_ui()


func set_phase(text: String, progress: float = -1.0) -> void:
	_phase = text
	if progress >= 0.0:
		_progress = clampf(progress, 0.0, 1.0)
	_refresh_ui()
	if _initial_boot and _web_loader_active:
		var encoded_text := JSON.stringify(_phase)
		_web_eval("window.eleblorbLoadingPhase && window.eleblorbLoadingPhase(%s, %.4f);" % [encoded_text, _progress])


func set_world_load_progress(scene_progress: float) -> void:
	var normalized := clampf(scene_progress, 0.0, 1.0)
	set_phase("Loading the world…", lerpf(WEB_WORLD_PROGRESS_START, WEB_WORLD_PROGRESS_END, normalized))


func _fade_out() -> void:
	_finishing = true
	var fade := create_tween()
	fade.set_trans(Tween.TRANS_QUAD)
	fade.set_ease(Tween.EASE_OUT)
	fade.tween_property(_screen, "modulate:a", 0.0, 0.35)
	fade.tween_callback(_release_screen)


func _release_screen() -> void:
	if _screen != null:
		_screen.queue_free()
	_screen = null
	_content = null
	_phase_label = null
	_progress_bar = null
	_primary_hint_label = null
	_tip_label = null
	_release_modal_lock()


func _build_ui() -> void:
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_screen)

	var backdrop := ColorRect.new()
	backdrop.color = UITheme.LOADING_BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(center)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", UITheme.SPACE_MD)
	_content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_content)

	var title := Label.new()
	title.text = "Eleblorb"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", UITheme.FONT_DISPLAY)
	title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	_content.add_child(title)

	_primary_hint_label = UIKit.body_label(_primary_hint())
	_primary_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content.add_child(_primary_hint_label)

	var tip_panel := UIKit.panel()
	tip_panel.custom_minimum_size.y = UITheme.BUTTON_MIN_HEIGHT * 1.5
	_content.add_child(tip_panel)

	_tip_label = UIKit.caption_label("")
	_tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_panel.add_child(_tip_label)

	_phase_label = UIKit.inline_caption(_phase, UITheme.TEXT_SECONDARY)
	_phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(_phase_label)

	_progress_bar = UIKit.loading_progress_bar()
	_content.add_child(_progress_bar)

	if not get_viewport().size_changed.is_connected(_layout):
		get_viewport().size_changed.connect(_layout)
	_layout()
	_show_tip()
	_refresh_ui()


func _show_tip() -> void:
	var available_tips := _tips()
	if _tip_label == null or available_tips.is_empty():
		return
	_tip_label.text = available_tips[_tip_index % available_tips.size()]
	_tip_label.modulate.a = 0.0
	var reveal := create_tween()
	reveal.set_trans(Tween.TRANS_QUAD)
	reveal.set_ease(Tween.EASE_OUT)
	reveal.tween_property(_tip_label, "modulate:a", 1.0, 0.28)


func _refresh_ui() -> void:
	if _phase_label != null:
		_phase_label.text = _phase
	if _progress_bar != null:
		_progress_bar.value = _progress


func _layout() -> void:
	if _content == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var side_margin := UITheme.SPACE_MD if _is_touch_device() else UITheme.SPACE_XL
	_content.custom_minimum_size.x = minf(780.0, maxf(280.0, viewport_size.x - side_margin * 2.0))


func _primary_hint() -> String:
	if _is_touch_device():
		return "Drag the left control to move · Drag the world to look"
	if not Input.get_connected_joypads().is_empty():
		return "Left Stick to move · Right Stick to look · Y to jump"
	return "WASD to move · Mouse to look · Space to jump"


func _tips() -> Array:
	if _is_touch_device():
		return TOUCH_TIPS
	if not Input.get_connected_joypads().is_empty():
		return CONTROLLER_TIPS
	return KEYBOARD_TIPS


func _is_touch_device() -> bool:
	return DisplayServer.is_touchscreen_available()


func _detect_web_loader() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(_web_eval("Boolean(window.eleblorbLoadingPhase && window.eleblorbWorldReady);"))


func _web_eval(source: String) -> Variant:
	if not OS.has_feature("web"):
		return null
	return JavaScriptBridge.eval(source, true)


func _acquire_modal_lock() -> void:
	if _owns_modal_lock:
		return
	UIState.push_modal()
	_owns_modal_lock = true


func _release_modal_lock() -> void:
	if not _owns_modal_lock:
		return
	UIState.pop_modal()
	_owns_modal_lock = false
