extends Node3D

## Baked consist controller. Each car has its own physics RID and samples the
## route independently, allowing the couplings to articulate through curves.
@export var service_name := ""
@export var path := PackedVector3Array()
@export var speed := 10.0
@export var cars := 2
@export var loop := false
@export var stops := PackedVector3Array()
@export var dwell := 4.0
@export var initial_phase := 0.0
@export var initial_direction := 1
@export var conflict_points := PackedVector3Array()

const CAR_SPACING := 10.4
const BLOCK_RADIUS := 15.0
var _car_bodies: Array[AnimatableBody3D] = []
var _couplers: Array[MeshInstance3D] = []
var _lengths := PackedFloat32Array()
var _stop_distances := PackedFloat32Array()
var _total := 0.0
var _distance := 0.0
var _direction := 1.0
var _dwell_left := 0.0
var _station_arrivals := 0


func _ready() -> void:
	add_to_group("moy_train_consists")
	for child in get_children():
		if child is AnimatableBody3D and String(child.name).begins_with("Car_"):
			_car_bodies.append(child)
		elif child is MeshInstance3D and String(child.name).begins_with("ArticulatedBellows_"):
			_couplers.append(child)
	_car_bodies.sort_custom(func(a: Node, b: Node) -> bool: return String(a.name) < String(b.name))
	if path.size() < 2 or _car_bodies.size() != cars:
		set_physics_process(false)
		return
	for i in range(path.size() if loop else path.size() - 1):
		var length := path[i].distance_to(path[(i + 1) % path.size()])
		_lengths.append(length)
		_total += length
	for stop in stops:
		_stop_distances.append(_project_stop(stop))
	_stop_distances.sort()
	_direction = -1.0 if initial_direction < 0 else 1.0
	_distance = _total * clampf(initial_phase, 0.0, 0.999999)
	if loop and _stop_distances.size() > 0 and _nearest_stop_distance(_distance) < 8.0:
		_distance = fposmod(_distance + 24.0, _total)
	if not loop and not _stop_distances.is_empty():
		_distance = _stop_distances[0] if _direction > 0.0 else _stop_distances[_stop_distances.size()-1]
		_dwell_left = dwell
		_station_arrivals += 1
	elif not loop and _is_stop(_distance):
		_dwell_left = dwell
		_station_arrivals += 1
	_apply_pose()


func _physics_process(delta: float) -> void:
	if _dwell_left > 0.0:
		_dwell_left = maxf(0.0, _dwell_left - delta)
		return
	var candidate := _distance + speed * delta * _direction
	var stop_distance := _next_stop(candidate)
	if stop_distance >= 0.0:
		candidate = stop_distance
	if _traffic_blocks(candidate):
		return
	_distance = fposmod(candidate, _total) if loop else clampf(candidate, 0.0, _total)
	if stop_distance >= 0.0:
		_dwell_left = dwell
		_station_arrivals += 1
		if not loop and (_distance <= 0.01 or _distance >= _total - 0.01):
			_direction *= -1.0
	elif not loop and (_distance <= 0.01 or _distance >= _total - 0.01):
		_direction *= -1.0
		_dwell_left = dwell
	_apply_pose()


func _project_stop(stop: Vector3) -> float:
	var best_error := INF
	var best_distance := 0.0
	var accumulated := 0.0
	for i in _lengths.size():
		var a := path[i]
		var b := path[(i + 1) % path.size()]
		var segment := b - a
		var t := clampf((stop - a).dot(segment) / maxf(segment.length_squared(), 0.001), 0.0, 1.0)
		var error := a.lerp(b, t).distance_squared_to(stop)
		if error < best_error:
			best_error = error
			best_distance = accumulated + _lengths[i] * t
		accumulated += _lengths[i]
	return best_distance


func _next_stop(candidate: float) -> float:
	var travel := absf(candidate - _distance)
	var best_delta := INF
	var result := -1.0
	for station_distance in _stop_distances:
		var delta_to_stop := 0.0
		if loop:
			delta_to_stop = fposmod(station_distance - _distance, _total) if _direction > 0 else fposmod(_distance - station_distance, _total)
			if delta_to_stop < 0.01:
				continue
		else:
			if _direction > 0 and station_distance <= _distance + 0.001: continue
			if _direction < 0 and station_distance >= _distance - 0.001: continue
			delta_to_stop = absf(station_distance - _distance)
		if delta_to_stop <= travel + 0.001 and delta_to_stop < best_delta:
			best_delta = delta_to_stop
			result = station_distance
	return result


func _traffic_blocks(candidate: float) -> bool:
	if conflict_points.is_empty() or service_name not in ["Spine Line", "Wall Line"]:
		return false
	for point in conflict_points:
		var candidate_in_block := false
		for i in _car_bodies.size():
			var pos := _path_pose(candidate - float(i) * CAR_SPACING * _direction).origin
			if absf(pos.y - point.y) < 3.5 and Vector2(pos.x, pos.z).distance_to(Vector2(point.x, point.z)) < BLOCK_RADIUS:
				candidate_in_block = true
		if not candidate_in_block: continue
		for other in get_tree().get_nodes_in_group("moy_train_consists"):
			if other == self or not other is Node3D: continue
			var other_service := String(other.get("service_name"))
			if not ((service_name == "Spine Line" and other_service == "Wall Line") or (service_name == "Wall Line" and other_service == "Spine Line")): continue
			for other_car in other.get("_car_bodies"):
				if is_instance_valid(other_car):
					var pos: Vector3 = other_car.global_position
					if absf(pos.y - point.y) < 3.5 and Vector2(pos.x, pos.z).distance_to(Vector2(point.x, point.z)) < BLOCK_RADIUS:
						return true
	return false


func _apply_pose() -> void:
	for i in _car_bodies.size():
		_car_bodies[i].global_transform = _path_pose(_distance - float(i) * CAR_SPACING * _direction)
	for i in _couplers.size():
		var pose := _path_pose(_distance - (float(i) + 0.5) * CAR_SPACING * _direction)
		pose.origin.y += 1.9
		_couplers[i].global_transform = pose


func _path_pose(distance: float) -> Transform3D:
	var d := fposmod(distance, _total) if loop else clampf(distance, 0.0, _total)
	var index := 0
	while index < _lengths.size() - 1 and d > _lengths[index]:
		d -= _lengths[index]
		index += 1
	var next := (index + 1) % path.size()
	var tangent := (path[next] - path[index]).normalized() * _direction
	var yaw := atan2(-tangent.z, tangent.x)
	var origin := path[index].lerp(path[next], d / maxf(_lengths[index], 0.001))
	return Transform3D(Basis(Vector3.UP, yaw), origin)


func _build_consist() -> void:
	var shell_material := _mat(Color("#e4d4b4"))
	var glass_material := _mat(Color("#273943"))
	var livery_material := _mat(_line_color(service_name))
	var shell_mesh := SuperEgg.build_mesh(Vector3(4.8, 1.3, 1.325), 3.4, 5.5, 16, 24)
	for i in cars:
		var car := AnimatableBody3D.new()
		car.name = "Car_%02d" % i
		car.collision_layer = 1
		car.collision_mask = 1
		car.sync_to_physics = false
		add_child(car)
		var shell := MeshInstance3D.new()
		shell.mesh = shell_mesh
		shell.position.y = 1.9
		shell.material_override = shell_material
		car.add_child(shell)
		var shape := BoxShape3D.new()
		shape.size = Vector3(9.6, 2.65, 3.2)
		var collision := CollisionShape3D.new()
		collision.name = "RideableCarBody"
		collision.shape = shape
		collision.position.y = 1.9
		car.add_child(collision)
		var window_mesh := BoxMesh.new()
		window_mesh.size = Vector3(8.8, 0.72, 2.72)
		var windows := MeshInstance3D.new()
		windows.mesh = window_mesh
		windows.position.y = 2.28
		windows.material_override = glass_material
		car.add_child(windows)
		var stripe_mesh := BoxMesh.new()
		stripe_mesh.size = Vector3(9.0, 0.34, 3.26)
		var stripe := MeshInstance3D.new()
		stripe.mesh = stripe_mesh
		stripe.position.y = 1.32
		stripe.material_override = livery_material
		car.add_child(stripe)
	var bellows_mesh := BoxMesh.new()
	bellows_mesh.size = Vector3(0.8, 2.1, 1.8)
	for i in maxi(cars - 1, 0):
		var bellows := MeshInstance3D.new()
		bellows.name = "ArticulatedBellows_%02d" % i
		bellows.mesh = bellows_mesh
		bellows.material_override = glass_material
		add_child(bellows)


func _is_stop(distance: float) -> bool:
	for station_distance in _stop_distances:
		if absf(station_distance - distance) < 0.5: return true
	return false


func _nearest_stop_distance(distance: float) -> float:
	var nearest := INF
	for station_distance in _stop_distances:
		var d := absf(station_distance - distance)
		if loop: d = minf(d, _total - d)
		nearest = minf(nearest, d)
	return nearest


func _line_color(line: String) -> Color:
	match line:
		"Spine Line": return Color("#438c8a")
		"Meridian Line": return Color("#79588d")
		_: return Color("#b7833d")


func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.48
	return material
