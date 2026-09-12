class_name MobileControlsSurface
extends Control

## Kueh Machine's proven touch architecture adapted to Eleblorbs: fixed,
## density-normalized Controls; explicit per-finger ownership; canvas-aware
## hit testing; absolute-position camera deltas; and exhaustive release when
## a modal takes control.

const JOYSTICK_NO_TOUCH := -2
const JOYSTICK_OUTER_SIZE := 292.0
const JOYSTICK_KNOB_SIZE := 128.0
const ACTION_SIZE := 138.0
const CONTROL_MARGIN := 54.0
const ACTION_GAP := 18.0
const TABLET_SCALE := 1.25
const TABLET_MARGIN_SCALE := 2.0
const LOOK_SENSITIVITY := 0.0024
const PHONE_ACTION_MIN := 72.0
const PHONE_ACTION_MAX := 112.0
const PHONE_JOYSTICK_MIN := 156.0
const PHONE_JOYSTICK_MAX := 224.0

const ACTION_LAYOUT := [
	["FORM", "transform"], ["SWAP", "switch_blorbus"], ["BAG", "inventory"],
	["L ARM", "left_arm_power"], ["JUMP", "jump"], ["R ARM", "right_arm_power"],
	["L LEG", "left_leg_power"], ["USE", "interact"], ["R LEG", "right_leg_power"],
	["RUN", "run"], ["CALL", "platform_aid"], ["Ⅱ", "pause"],
]

var _joystick_outer: PanelContainer
var _joystick_knob: PanelContainer
var _joystick_touch := JOYSTICK_NO_TOUCH
var _joystick_outer_size := JOYSTICK_OUTER_SIZE
var _joystick_knob_size := JOYSTICK_KNOB_SIZE
var _action_controls: Dictionary = {}
var _active_action_touches: Dictionary = {}
var _look_touch := -1
var _look_position := Vector2.ZERO
var _input_enabled := true


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_controls()


func _process(_delta: float) -> void:
	var should_enable := not UIState.modal_open
	if should_enable == _input_enabled:
		return
	_input_enabled = should_enable
	visible = should_enable
	if not should_enable:
		_release_all_input()


func _build_controls() -> void:
	var tablet := UIKit.is_tablet_touch_viewport()
	var logical_size := UIKit.logical_viewport_size(self)
	var short_side := minf(logical_size.x, logical_size.y)
	var action_size := clampf(short_side * 0.145, PHONE_ACTION_MIN, PHONE_ACTION_MAX)
	var joystick_size := clampf(short_side * 0.30, PHONE_JOYSTICK_MIN, PHONE_JOYSTICK_MAX)
	if tablet:
		action_size *= TABLET_SCALE
		joystick_size *= TABLET_SCALE
	var margin := clampf(short_side * 0.045, 22.0, CONTROL_MARGIN)
	if tablet:
		margin *= TABLET_MARGIN_SCALE
	var scale_factor := action_size / ACTION_SIZE
	_joystick_outer_size = joystick_size
	_joystick_knob_size = joystick_size * (JOYSTICK_KNOB_SIZE / JOYSTICK_OUTER_SIZE)

	_joystick_outer = PanelContainer.new()
	_joystick_outer.name = "MovementJoystickOuter"
	_joystick_outer.custom_minimum_size = Vector2.ONE * _joystick_outer_size
	_joystick_outer.mouse_filter = Control.MOUSE_FILTER_STOP
	_joystick_outer.add_theme_stylebox_override("panel", _joystick_ring_style(_joystick_outer_size))
	UIKit.anchor_to_edge(_joystick_outer, 0.0, 1.0, margin, margin)
	add_child(_joystick_outer)

	_joystick_knob = PanelContainer.new()
	_joystick_knob.name = "MovementJoystickKnob"
	_joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_joystick_knob.anchor_left = 0.5
	_joystick_knob.anchor_right = 0.5
	_joystick_knob.anchor_top = 0.5
	_joystick_knob.anchor_bottom = 0.5
	_joystick_knob.add_theme_stylebox_override("panel", _joystick_knob_style(_joystick_knob_size))
	_set_joystick_knob(Vector2.ZERO)
	_joystick_outer.add_child(_joystick_knob)

	var grid := GridContainer.new()
	grid.name = "MobileActionButtons"
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", int(ACTION_GAP * scale_factor))
	grid.add_theme_constant_override("v_separation", int(ACTION_GAP * scale_factor))
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.anchor_to_edge(grid, 1.0, 1.0, margin, margin)
	add_child(grid)
	for definition in ACTION_LAYOUT:
		var control := _action_control(String(definition[0]), action_size)
		_action_controls[control] = StringName(definition[1])
		grid.add_child(control)


func _action_control(label_text: String, control_size: float) -> PanelContainer:
	var control := PanelContainer.new()
	control.custom_minimum_size = Vector2.ONE * control_size
	control.mouse_filter = Control.MOUSE_FILTER_STOP
	control.add_theme_stylebox_override("panel", _action_style(control_size))
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", UITheme.FONT_BUTTON)
	label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control.add_child(label)
	return control


func _input(event: InputEvent) -> void:
	if not _input_enabled:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _canvas_point_inside(_joystick_outer, touch.position):
				_begin_joystick(touch.index, touch.position)
				get_viewport().set_input_as_handled()
				return
			var action_control := _action_at(touch.position)
			if action_control != null:
				_press_action_touch(touch.index, action_control)
				get_viewport().set_input_as_handled()
				return
			if _look_touch < 0:
				_look_touch = touch.index
				_look_position = touch.position
		elif touch.index == _joystick_touch:
			_end_joystick()
			get_viewport().set_input_as_handled()
		elif _active_action_touches.has(touch.index):
			_release_action_touch(touch.index)
			get_viewport().set_input_as_handled()
		elif touch.index == _look_touch:
			_cancel_look()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _joystick_touch:
			_update_joystick(drag.position)
			get_viewport().set_input_as_handled()
		elif _active_action_touches.has(drag.index):
			_update_action_touch(drag.index, drag.position)
			get_viewport().set_input_as_handled()
		elif drag.index == _look_touch:
			# Absolute positions avoid the web backend's shared relative stream,
			# which can jump when the joystick finger moves simultaneously.
			var delta := drag.position - _look_position
			_look_position = drag.position
			var player := get_tree().get_first_node_in_group("player") as Player
			if player != null:
				player.rotate_camera_from_touch(
					-delta.x * LOOK_SENSITIVITY, -delta.y * LOOK_SENSITIVITY
				)


func _begin_joystick(index: int, position: Vector2) -> void:
	if _joystick_touch != JOYSTICK_NO_TOUCH:
		return
	_joystick_touch = index
	_update_joystick(position)


func _update_joystick(position: Vector2) -> void:
	var local := _joystick_outer.get_global_transform_with_canvas().affine_inverse() * position
	var center := _joystick_outer.size * 0.5
	var radius := (_joystick_outer_size - _joystick_knob_size) * 0.5
	var offset := (local - center).limit_length(radius)
	_set_joystick_knob(offset)
	var direction := offset / radius
	if direction.length() < 0.12:
		direction = Vector2.ZERO
	_set_strength("move_left", maxf(-direction.x, 0.0))
	_set_strength("move_right", maxf(direction.x, 0.0))
	_set_strength("move_forward", maxf(-direction.y, 0.0))
	_set_strength("move_back", maxf(direction.y, 0.0))


func _end_joystick() -> void:
	_joystick_touch = JOYSTICK_NO_TOUCH
	_set_joystick_knob(Vector2.ZERO)
	for action in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action)


func _set_strength(action: StringName, strength: float) -> void:
	if strength > 0.0:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _set_joystick_knob(offset: Vector2) -> void:
	var half := _joystick_knob_size * 0.5
	_joystick_knob.offset_left = -half + offset.x
	_joystick_knob.offset_right = half + offset.x
	_joystick_knob.offset_top = -half + offset.y
	_joystick_knob.offset_bottom = half + offset.y


func _action_at(position: Vector2) -> Control:
	for control in _action_controls:
		if _canvas_point_inside(control as Control, position):
			return control
	return null


func _press_action_touch(index: int, control: Control) -> void:
	_active_action_touches[index] = control
	control.modulate = Color(1.12, 1.12, 1.12, 1.0)
	_emit_action(_action_controls[control], true)


func _release_action_touch(index: int) -> void:
	var control := _active_action_touches[index] as Control
	control.modulate = Color.WHITE
	_emit_action(_action_controls[control], false)
	_active_action_touches.erase(index)


func _update_action_touch(index: int, position: Vector2) -> void:
	var current := _active_action_touches[index] as Control
	if _canvas_point_inside(current, position):
		return
	current.modulate = Color.WHITE
	_emit_action(_action_controls[current], false)
	var next := _action_at(position)
	if next != null:
		_press_action_touch(index, next)
	else:
		_active_action_touches.erase(index)


func _emit_action(action: StringName, pressed: bool) -> void:
	# Parsing a real event supports both polled actions and event-driven
	# owners such as PauseMenu; Input.action_press alone does not.
	var action_event := InputEventAction.new()
	action_event.action = action
	action_event.pressed = pressed
	Input.parse_input_event(action_event)


func _release_all_input() -> void:
	if _joystick_touch != JOYSTICK_NO_TOUCH:
		_end_joystick()
	for index in _active_action_touches.keys():
		_release_action_touch(int(index))
	_cancel_look()


func _cancel_look() -> void:
	_look_touch = -1
	_look_position = Vector2.ZERO


func _canvas_point_inside(control: Control, point: Vector2) -> bool:
	var local := control.get_global_transform_with_canvas().affine_inverse() * point
	return Rect2(Vector2.ZERO, control.size).has_point(local)


func _joystick_ring_style(control_size: float) -> SuperellipseStyleBox:
	var style := SuperellipseStyleBox.new()
	style.bg_color = Color.TRANSPARENT
	style.border_color = Color(1, 1, 1, 0.42)
	style.border_width = control_size * 0.0513
	style.corner_radius = control_size
	style.corner_ratio = 0.34
	style.exponent = 2.0
	return style


func _joystick_knob_style(control_size: float) -> SuperellipseStyleBox:
	var style := SuperellipseStyleBox.new()
	style.bg_color = Color(UITheme.TEXT_PRIMARY, 0.90)
	style.corner_radius = control_size
	style.corner_ratio = 0.34
	style.exponent = 2.0
	style.shadow_size = 5
	style.shadow_color = Color(0, 0, 0, 0.22)
	return style


func _action_style(control_size: float) -> SuperellipseStyleBox:
	var style := SuperellipseStyleBox.new()
	style.bg_color = Color(UITheme.BLORBUS_PANEL, 0.82)
	style.border_color = Color(UITheme.BUTTON_BORDER, 0.68)
	style.border_width = 3.0
	style.corner_radius = control_size
	style.corner_ratio = 0.34
	style.exponent = 4.0
	style.shadow_size = 5
	style.shadow_color = Color(0, 0, 0, 0.22)
	return style
