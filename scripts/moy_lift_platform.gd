extends AnimatableBody3D

## Stationary-until-called public lift used by the Deck, station cores and
## Crossing towers. Its call posts and onboard menu share Fire Kingdom lift
## interaction semantics.
@export var base_height := -60.0
@export var stop_levels := PackedFloat32Array([0.0, 6.5])
@export var stop_names := PackedStringArray(["Street", "Deck"])
@export var travel_speed := 2.5
var _current_stop := 0
var _target_stop := 0

func _ready() -> void:
	sync_to_physics = true
	if stop_levels.size() > 0:
		position.y = base_height + stop_levels[0]
	var control := Interactable.attach(self, "Choose a level", 1.0, _show_level_menu, Callable(), Callable(), false, 1.6)
	control.position = Vector3(0.0, 0.45, 0.0)

func _physics_process(delta: float) -> void:
	if stop_levels.is_empty(): return
	var before := position.y
	var target_y := base_height + stop_levels[_target_stop]
	position.y = move_toward(position.y, target_y, travel_speed * delta)
	constant_linear_velocity = Vector3.UP * ((position.y - before) / maxf(delta, 0.0001))
	if is_equal_approx(position.y, target_y):
		_current_stop = _target_stop
		constant_linear_velocity = Vector3.ZERO

func go_to(index: int) -> void:
	if index >= 0 and index < stop_levels.size():
		_target_stop = index

func is_moving() -> bool:
	return stop_levels.is_empty() or not is_equal_approx(position.y, base_height + stop_levels[_target_stop])

func _show_level_menu() -> void:
	if is_moving(): return
	var actions: Array[Dictionary] = []
	for i in range(stop_levels.size() - 1, -1, -1):
		var destination := i
		var label := String(stop_names[i]) if i < stop_names.size() else "Level %.1f" % (base_height + stop_levels[i])
		actions.append({"label": label, "callback": func() -> void:
			DialogUI.hide_dialog()
			go_to(destination)})
	DialogUI.show_line("Lift", "Choose a level", actions, "")

func destination_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for i in range(stop_levels.size() - 1, -1, -1):
		labels.append(String(stop_names[i]) if i < stop_names.size() else "Level %.1f" % (base_height + stop_levels[i]))
	return labels
