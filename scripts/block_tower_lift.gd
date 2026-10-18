extends AnimatableBody3D

## The story lift passes every solid storey and stops only at the lobby,
## plant floor and crown. Its choices are directional, so no floor numbers
## become in-world instructions.

var stop_levels := PackedFloat32Array([0.0, 79.0, 150.0])
var _current_stop := 0
var _target_stop := 0
var _travel_speed := 10.0


func _ready() -> void:
	sync_to_physics = true
	var panel := Interactable.attach(self, "Choose a direction", 1.0, _show_menu, Callable(), Callable(), true, 2.0)
	panel.position = Vector3(0, 1.1, 0)
	var platform := BoxMesh.new(); platform.size = Vector3(3.2, 0.28, 3.2)
	var visual := MeshInstance3D.new(); visual.mesh = platform; visual.material_override = _material(Color("#3b424e")); add_child(visual)
	var collision := BoxShape3D.new(); collision.size = platform.size
	var shape := CollisionShape3D.new(); shape.shape = collision; add_child(shape)
	for side in [-1.0, 1.0]:
		var wall_mesh := BoxMesh.new(); wall_mesh.size = Vector3(0.12, 2.2, 3.2)
		var wall := MeshInstance3D.new(); wall.mesh = wall_mesh; wall.position = Vector3(side * 1.54, 1.1, 0); wall.material_override = _material(Color("#242933")); add_child(wall)


func _physics_process(delta: float) -> void:
	if stop_levels.is_empty(): return
	var before := position.y
	position.y = move_toward(position.y, stop_levels[_target_stop], _travel_speed * delta)
	constant_linear_velocity = Vector3.UP * ((position.y - before) / maxf(delta, 0.0001))
	if is_equal_approx(position.y, stop_levels[_target_stop]):
		_current_stop = _target_stop
		constant_linear_velocity = Vector3.ZERO


func go_to(index: int) -> void:
	if index >= 0 and index < stop_levels.size(): _target_stop = index


func initialize_stop(index: int) -> void:
	if index < 0 or index >= stop_levels.size(): return
	_current_stop = index
	_target_stop = index
	position.y = stop_levels[index]


func _show_menu() -> void:
	if _target_stop != _current_stop or stop_levels.is_empty(): return
	var actions: Array[Dictionary] = []
	if _current_stop < stop_levels.size() - 1:
		actions.append({"label": "Up", "callback": func() -> void: DialogUI.hide_dialog(); go_to(_current_stop + 1)})
	if _current_stop > 0:
		actions.append({"label": "Down", "callback": func() -> void: DialogUI.hide_dialog(); go_to(_current_stop - 1)})
	DialogUI.show_line("Lift", "Choose a direction.", actions, "")


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color = color; material.roughness = 0.78; material.metallic = 0.5
	return material
