class_name WorldSlidingDoor
extends Node3D

## A paired, surface-mounted glass slider. Each physical leaf moves on a
## horizontal track into the adjacent glazed bay, leaving the clear opening
## unobstructed. The wall owns the opening; this node owns the leaves and action.

const FRAME := Color(0.15, 0.24, 0.42)
const GLASS := Color(0.52, 0.78, 0.84, 0.62)

var _leaves: Array[AnimatableBody3D] = []
var _closed_x: Array[float] = []
var _open := true
var _travel := 0.0
var _moving := false
var _area: Area3D


func configure(clear_width: float, door_height: float, yaw: float = 0.0, initially_open: bool = true, match_aperture: bool = false) -> void:
	rotation.y = yaw
	_open = initially_open
	var half_leaf := clear_width * 0.25
	var glass := SolidModel.material(GLASS, 0.12, 0.08)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for side: float in [-1.0, 1.0]:
		var leaf_body := AnimatableBody3D.new()
		leaf_body.name = "SlidingGlassLeaf"
		leaf_body.collision_layer = 1
		leaf_body.collision_mask = 0
		leaf_body.sync_to_physics = true
		var shut_x := side * half_leaf
		var travel := clear_width * 0.5 + 0.08
		_travel = travel
		leaf_body.position = Vector3(shut_x + (side * travel if initially_open else 0.0), 0.0, 0.13)
		add_child(leaf_body)
		var pane: MeshInstance3D
		if match_aperture:
			# Build one shared SuperEgg aperture and cut it at the meeting stile.
			# Independent rounded leaves left visible two overlapping oval ends.
			var half_space := Plane(Vector3.RIGHT if side < 0.0 else Vector3.LEFT, 0.0)
			pane = MeshInstance3D.new()
			pane.mesh = SuperEgg.build_clipped_mesh(Vector3(clear_width * 0.5, door_height * 0.5, 0.035), [half_space], SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT, 48, 28)
			shut_x = 0.0
		else:
			pane = SuperEgg.build_part(Vector3(half_leaf, door_height * 0.5, 0.035), GLASS, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		pane.name = "GlassLeaf"
		pane.material_override = glass
		pane.position = Vector3(0.0, door_height * 0.5, 0.0)
		leaf_body.add_child(pane)
		var shape := CollisionShape3D.new()
		if match_aperture:
			var convex := ConvexPolygonShape3D.new()
			convex.points = pane.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			shape.shape = convex
		else:
			var box := BoxShape3D.new()
			box.size = Vector3(half_leaf * 2.0 - 0.025, door_height - 0.06, 0.10)
			shape.shape = box
		shape.position = Vector3(0.0, door_height * 0.5, 0.0)
		leaf_body.add_child(shape)
		_leaves.append(leaf_body)
		_closed_x.append(shut_x)
	var track := SuperEgg.build_part(Vector3(clear_width, 0.035, 0.045), FRAME, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	track.name = "PairedSliderTrack"
	track.position = Vector3(0.0, door_height + 0.12, 0.055)
	add_child(track)
	CollisionPolicy.mark_decorative(track)
	_area = Interactable.attach(self, _prompt(), 2.1, _activate, Callable(), Callable(), true, 1.35)


func _prompt() -> String:
	return "Close door" if _open else "Open door"


func _activate() -> void:
	if _moving:
		return
	_open = not _open
	_moving = true
	UISounds.play_foley(&"door_open" if _open else &"door_close", 0.5, get_instance_id())
	for index in _leaves.size():
		var target := _closed_x[index]
		if _open:
			target += (-1.0 if index == 0 else 1.0) * _travel
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(_leaves[index], "position:x", target, 0.42)
		if index == _leaves.size() - 1:
			tween.finished.connect(_finish_motion)
	if is_instance_valid(_area):
		_area.set_meta("prompt", _prompt())


func _finish_motion() -> void:
	_moving = false
