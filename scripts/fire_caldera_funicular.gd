extends Node3D

## Counterbalanced pair riding the authored funicular section. Cabins remain
## level while their chassis follows the track profile.

var profile := PackedVector3Array()
var car_length := 9.6
var car_width := 2.5
var step_count := 3
var _elapsed := 0.0
var _cars: Array[Node3D] = []
const SPEED := 0.035 # normalized line position per second
const ENAMEL := Color(0.82, 0.39, 0.12)
const WINDOW := Color(0.11, 0.15, 0.17, 0.74)


func build_cars(parent: Node3D) -> void:
	for index in 2:
		var car := Node3D.new()
		car.name = "FunicularCarUp" if index == 0 else "FunicularCarDown"
		parent.add_child(car)
		_cars.append(car)
		for cabin_index in maxi(step_count, 1):
			var cabin := StaticBody3D.new()
			cabin.collision_layer = 1
			cabin.collision_mask = 0
			cabin.name = "LevelCabin%02d" % cabin_index
			var longitudinal := (float(cabin_index) - float(step_count - 1) * 0.5) * 3.0
			var vertical := (float(cabin_index) - float(step_count - 1) * 0.5) * 1.5
			cabin.position = Vector3(0.0, vertical, longitudinal)
			car.add_child(cabin)
			var shell := BoxMesh.new()
			shell.size = Vector3(2.7, 2.5, minf(car_length / float(step_count), 3.2))
			var body_mesh := MeshInstance3D.new()
			body_mesh.name = "AmberEnamelCabin"
			body_mesh.mesh = shell
			body_mesh.material_override = SolidModel.material(ENAMEL, 0.28, 0.24)
			cabin.add_child(body_mesh)
			CollisionPolicy.add_box(cabin, body_mesh, shell.size, Vector3.ZERO, Basis.IDENTITY, false)
			var glazing := BoxMesh.new()
			glazing.size = Vector3(2.72, 0.55, shell.size.z * 0.72)
			var glass := MeshInstance3D.new()
			glass.name = "SmokedGlassBand"
			glass.mesh = glazing
			glass.position.y = 0.52
			glass.material_override = SolidModel.material(WINDOW, 0.12, 0.12)
			cabin.add_child(glass)
			CollisionPolicy.mark_decorative(glass)


func _process(delta: float) -> void:
	if profile.size() < 2 or _cars.size() != 2:
		return
	_elapsed += delta
	var t := fposmod(_elapsed * SPEED, 2.0)
	var up_t := t if t <= 1.0 else 2.0 - t
	_set_car(_cars[0], up_t)
	_set_car(_cars[1], 1.0 - up_t)


func _set_car(car: Node3D, t: float) -> void:
	var scaled := clampf(t, 0.0, 1.0) * float(profile.size() - 1)
	var index := mini(int(floor(scaled)), profile.size() - 2)
	var point := profile[index].lerp(profile[index + 1], scaled - float(index))
	var tangent := (profile[index + 1] - profile[index]).normalized()
	car.position = point + Vector3.UP * 1.25
	car.rotation.y = atan2(tangent.x, tangent.z)
