class_name MobileControlsSurface
extends Control

const STICK_RADIUS := 86.0
const KNOB_RADIUS := 38.0
const LOOK_SENSITIVITY := 0.0042
const BUTTON_RADIUS := 42.0
const BUTTONS := [
	{"label": "JUMP", "action": "jump", "offset": Vector2(-78, -118)},
	{"label": "USE", "action": "interact", "offset": Vector2(-172, -68)},
	{"label": "L ARM", "action": "left_arm_power", "offset": Vector2(-254, -150)},
	{"label": "R ARM", "action": "right_arm_power", "offset": Vector2(-145, -184)},
	{"label": "L LEG", "action": "left_leg_power", "offset": Vector2(-260, -250)},
	{"label": "R LEG", "action": "right_leg_power", "offset": Vector2(-150, -282)},
	{"label": "FORM", "action": "transform", "offset": Vector2(-268, -354)},
	{"label": "BAG", "action": "inventory", "offset": Vector2(-158, -386)},
	{"label": "Ⅱ", "action": "pause", "offset": Vector2(-58, -350)},
]

var _move_touch := -1
var _look_touch := -1
var _move_origin := Vector2.ZERO
var _move_knob := Vector2.ZERO
var _pressed_actions: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	queue_redraw()


func _process(_delta: float) -> void:
	# Once a menu/dialog opens, its own touch-sized controls own the screen.
	# Hiding this layer prevents invisible gameplay buttons intercepting taps.
	visible = not UIState.modal_open


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			if _press_button(touch.index, touch.position):
				get_viewport().set_input_as_handled()
				return
			if touch.position.x < size.x * 0.45 and touch.position.y > size.y * 0.42 and _move_touch < 0:
				_move_touch = touch.index
				_move_origin = touch.position
				_move_knob = touch.position
				_apply_move(Vector2.ZERO)
				queue_redraw()
				get_viewport().set_input_as_handled()
			elif _look_touch < 0 and not UIState.modal_open:
				_look_touch = touch.index
		else:
			if touch.index == _move_touch:
				_move_touch = -1
				_apply_move(Vector2.ZERO)
				queue_redraw()
			if touch.index == _look_touch:
				_look_touch = -1
			_release_button(touch.index)
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _move_touch:
			var delta := drag.position - _move_origin
			var limited := delta.limit_length(STICK_RADIUS)
			_move_knob = _move_origin + limited
			_apply_move(limited / STICK_RADIUS)
			queue_redraw()
			get_viewport().set_input_as_handled()
		elif drag.index == _look_touch and not UIState.modal_open:
			var player := get_tree().get_first_node_in_group("player") as Player
			if player != null:
				player._rotate_camera(-drag.relative.x * LOOK_SENSITIVITY, -drag.relative.y * LOOK_SENSITIVITY)
			get_viewport().set_input_as_handled()


func _apply_move(value: Vector2) -> void:
	_set_strength("move_left", maxf(-value.x, 0.0))
	_set_strength("move_right", maxf(value.x, 0.0))
	_set_strength("move_forward", maxf(-value.y, 0.0))
	_set_strength("move_back", maxf(value.y, 0.0))


func _set_strength(action: String, strength: float) -> void:
	if strength > 0.02:
		Input.action_press(action, strength)
	else:
		Input.action_release(action)


func _press_button(touch_id: int, point: Vector2) -> bool:
	for spec in BUTTONS:
		if point.distance_to(size + spec.offset) <= BUTTON_RADIUS * 1.25:
			var action := String(spec.action)
			_pressed_actions[touch_id] = action
			Input.action_press(action)
			return true
	return false


func _release_button(touch_id: int) -> void:
	if not _pressed_actions.has(touch_id):
		return
	Input.action_release(String(_pressed_actions[touch_id]))
	_pressed_actions.erase(touch_id)


func _draw() -> void:
	var base := _move_origin if _move_touch >= 0 else Vector2(120, size.y - 130)
	var knob := _move_knob if _move_touch >= 0 else base
	draw_circle(base, STICK_RADIUS, Color(0.04, 0.04, 0.05, 0.46))
	draw_arc(base, STICK_RADIUS, 0, TAU, 48, Color.WHITE * Color(1, 1, 1, 0.72), 4.0)
	draw_circle(knob, KNOB_RADIUS, Color(0.82, 0.60, 0.62, 0.82))
	var font := ThemeDB.fallback_font
	for spec in BUTTONS:
		var center: Vector2 = size + spec.offset
		draw_circle(center, BUTTON_RADIUS, Color(0.12, 0.08, 0.1, 0.72))
		draw_arc(center, BUTTON_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.75), 3.0)
		var label := String(spec.label)
		var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
		draw_string(font, center - text_size * 0.5 + Vector2(0, text_size.y * 0.76), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.WHITE)
