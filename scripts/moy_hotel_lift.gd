extends AnimatableBody3D

## Manually operated hotel capsule. Call posts summon it; the in-cab control
## presents every stop in vertical order, matching the Fire Kingdom lift.
@export var stop_levels := PackedFloat32Array([0.0, 6.5, 89.5])
@export var stop_names := PackedStringArray(["Atrium floor", "Mezzanine", "Level 27 — Party suite"])
@export var travel_speed := 2.5
@export var cab_depth := 3.4
var _current_stop := 0
var _target_stop := 0

func _ready() -> void:
	sync_to_physics = true
	if stop_levels.size() > 0:
		_current_stop = clampi(_current_stop, 0, stop_levels.size() - 1)
		_target_stop = _current_stop
		position.y = stop_levels[_current_stop]
	var control := Interactable.attach(self, "Choose a floor", 1.15, _show_floor_menu, Callable(), Callable(), false, 1.6)
	control.position = Vector3(0.0, 1.15, -cab_depth * 0.24)
	var panel := MeshInstance3D.new()
	panel.name = "LiftFloorControl"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.28, 0.42, 0.06)
	panel.mesh = mesh
	panel.position = control.position + Vector3(0.0, 0.0, -0.08)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#d8caa7")
	material.emission_enabled = true
	material.emission = Color("#76c8b4")
	material.emission_energy_multiplier = 0.25
	panel.material_override = material
	add_child(panel)

func _physics_process(delta: float) -> void:
	if stop_levels.is_empty(): return
	var before := position.y
	position.y = move_toward(position.y, stop_levels[_target_stop], travel_speed * delta)
	constant_linear_velocity = Vector3.UP * ((position.y - before) / maxf(delta, 0.0001))
	if is_equal_approx(position.y, stop_levels[_target_stop]):
		_current_stop = _target_stop
		constant_linear_velocity = Vector3.ZERO

func go_to(index: int) -> void:
	if index >= 0 and index < stop_levels.size():
		_target_stop = index

func is_moving() -> bool:
	return not is_equal_approx(position.y, stop_levels[_target_stop])

func _show_floor_menu() -> void:
	if is_moving(): return
	var actions: Array[Dictionary] = []
	for i in range(stop_levels.size() - 1, -1, -1):
		var destination := i
		var label := String(stop_names[i]) if i < stop_names.size() else "Level %.1f" % stop_levels[i]
		actions.append({"label": label, "callback": func() -> void:
			DialogUI.hide_dialog()
			go_to(destination)})
	DialogUI.show_line("Lift", "Choose a floor", actions, "")

func destination_labels() -> PackedStringArray:
	var labels := PackedStringArray()
	for i in range(stop_levels.size() - 1, -1, -1):
		labels.append(String(stop_names[i]) if i < stop_names.size() else "Level %.1f" % stop_levels[i])
	return labels
