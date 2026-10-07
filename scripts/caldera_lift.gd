class_name CalderaLift
extends StaticBody3D

## An open lift platform for the Fire caldera (the brief's vertical
## circulation allows ramps or lifts): a cast platform on a steel mast that
## serves several stations. It waits where it last stopped. On the platform,
## its control offers the other stations; at each station a call post brings
## it there. Moved by hand as a StaticBody3D, its velocity reported so a body
## standing on it is carried.

@export var speed := 0.9

## Heights of the stations above the parent's floor, bottom first, and their
## names for the choice on the platform.
var stations: Array[float] = []
var station_names: Array[String] = []
var _current := 0
var _target := 0


func _physics_process(delta: float) -> void:
	var goal := stations[_target]
	if is_equal_approx(position.y, goal):
		constant_linear_velocity = Vector3.ZERO
		_current = _target
		return
	var step := clampf(goal - position.y, -speed * delta, speed * delta)
	position.y += step
	constant_linear_velocity = Vector3(0.0, step / maxf(delta, 0.0001), 0.0)
	if absf(goal - position.y) < 0.001:
		position.y = goal


## Sends the lift to a station.
func go_to(index: int) -> void:
	_target = clampi(index, 0, stations.size() - 1)


func is_moving() -> bool:
	return not is_equal_approx(position.y, stations[_target])


## The platform's control: the other stations to choose from.
func _ride() -> void:
	if is_moving():
		return
	var actions: Array[Dictionary] = []
	for i in stations.size():
		if i == _current:
			continue
		var index := i
		actions.append({"label": station_names[i], "callback": func() -> void:
			DialogUI.hide_dialog()
			go_to(index)})
	DialogUI.show_line("Lift", "", actions, "Stay.")


## Builds a lift in `parent` at plan point `at` (its platform's centre), its
## platform `size` (x, z), serving `heights` (bottom first) named `names`,
## waiting at `start`; rails on the sides named in `rails` ("east",
## "north", ...), cheeks of `cheek` material. Returns the lift.
static func build(parent: Node3D, at: Vector2, size: Vector2, heights: Array[float], names: Array[String], start: int, rails: Array, cheek: Material) -> CalderaLift:
	var lift := CalderaLift.new()
	lift.name = "Lift"
	lift.stations = heights
	lift.station_names = names
	lift._current = start
	lift._target = start
	lift.collision_layer = 1
	lift.collision_mask = 0
	lift.position = Vector3(at.x, heights[start], at.y)
	parent.add_child(lift)
	var deck := SuperEgg.build_part(Vector3(size.x * 0.5, 0.06, size.y * 0.5), CalderaShell.BASALT.lightened(0.12), 6.0, 6.0)
	deck.position = Vector3(0, -0.06, 0)
	lift.add_child(deck)
	CollisionPolicy.add_box(lift, deck, Vector3(size.x, 0.12, size.y), Vector3(0, -0.06, 0), Basis(), true)
	for side: String in rails:
		var along_x := side == "north" or side == "south"
		var sign := 1.0 if side == "east" or side == "north" else -1.0
		var offset := Vector3(0, 0.55, sign * (size.y * 0.5 - 0.03)) if along_x else Vector3(sign * (size.x * 0.5 - 0.03), 0.55, 0)
		var panel := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(size.x, 1.0, 0.03) if along_x else Vector3(0.03, 1.0, size.y)
		panel.mesh = box
		panel.material_override = cheek
		panel.position = offset
		lift.add_child(panel)
		CollisionPolicy.add_box(lift, panel, box.size, offset, Basis(), false)
		CalderaShell._metal(lift, offset + Vector3(0, 0.52, 0), box.size + Vector3(0.03, 0.04 - box.size.y, 0.03), CalderaShell.STEEL_BLUED, false)
	# The control on the platform: a steel post with a lit stone to touch.
	var control := Vector3(size.x * 0.5 - 0.2, 0.0, size.y * 0.5 - 0.2)
	_control_post(lift, control)
	Interactable.attach(lift, "Ride the lift", 1.1, lift._ride, Callable(), Callable(), false, 1.5).position = control + Vector3(0, 1.0, 0)
	return lift


## A call post at a station: `at` in the lift's parent's frame, on the
## station's floor; it brings `lift` to station `index`.
static func add_call(parent: Node3D, lift: CalderaLift, index: int, at: Vector3) -> void:
	var post := Node3D.new()
	post.name = "LiftCall%d" % index
	post.position = at
	parent.add_child(post)
	_control_post(post, Vector3.ZERO)
	Interactable.attach(post, "Call the lift", 1.2, func() -> void: lift.go_to(index), Callable(), Callable(), false, 1.5).position = Vector3(0, 1.0, 0)


static func _control_post(parent: Node3D, at: Vector3) -> void:
	var stem := SuperEgg.build_part(Vector3(0.04, 0.5, 0.04), CalderaShell.STEEL_BLUED, 6.0, 6.0)
	stem.material_override = SolidModel.material(CalderaShell.STEEL_BLUED, 0.25, 0.85)
	stem.position = at + Vector3(0, 0.5, 0)
	parent.add_child(stem)
	CollisionPolicy.mark_decorative(stem)
	var stone := SuperEgg.build_part(Vector3(0.05, 0.05, 0.05), Color(0.45, 0.70, 0.75), 2.4, 2.4)
	var lit := StandardMaterial3D.new()
	lit.albedo_color = Color(0.45, 0.70, 0.75)
	lit.emission_enabled = true
	lit.emission = Color(0.35, 0.65, 0.75)
	lit.emission_energy_multiplier = 1.6
	stone.material_override = lit
	stone.position = at + Vector3(0, 1.04, 0)
	parent.add_child(stone)
	CollisionPolicy.mark_decorative(stone)
