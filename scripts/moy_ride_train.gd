extends Node3D
const PLAN := preload("res://scripts/city_plan.gd")

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
@export var schedule_events: Array = []
@export var schedule_offset := 0.0
@export var schedule_headway := 60.0
@export var schedule_circuit := 180.0
@export var schedule_train_index := 0

const CAR_SPACING := float(PLAN.TRAIN.car[0])+float(PLAN.TRAIN.gangway)
const BLOCK_RADIUS := 15.0
var _car_bodies: Array[AnimatableBody3D] = []
var _couplers: Array[MeshInstance3D] = []
var _lengths := PackedFloat32Array()
var _stop_distances := PackedFloat32Array()
var _stop_dwell_times := PackedFloat32Array()
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
	for stop_distance in _stop_distances:
		_stop_dwell_times.append(_dwell_for_distance(float(stop_distance)))
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
	if not schedule_events.is_empty():
		var state:=_scheduled_state_at(float(WorldState.game_time_hours)*60.0)
		_distance=float(state.s); _direction=float(state.direction); _apply_pose()
		return
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
		_dwell_left = _dwell_at(stop_distance)
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
		pose.origin.y += 2.4
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
	var shell_data: Dictionary=PLAN.TRAIN.parts[0]; var shell_semi: Array=shell_data.semi; var shell_eps: Array=shell_data.eps
	var shell_mesh := SuperEgg.build_mesh(Vector3(float(shell_semi[0]),float(shell_semi[1]),float(shell_semi[2])),float(shell_eps[0]),float(shell_eps[1]),16,24)
	for i in cars:
		var car := AnimatableBody3D.new()
		car.name = "Car_%02d" % i
		car.collision_layer = 1
		car.collision_mask = 1
		car.sync_to_physics = false
		add_child(car)
		var shell := MeshInstance3D.new()
		shell.mesh = shell_mesh
		shell.position.y = float(shell_data.c[1])+0.4
		shell.material_override = shell_material
		car.add_child(shell)
		_add_rideable_car_collision(car)
		var window_mesh := BoxMesh.new()
		var glazing: Dictionary=PLAN.TRAIN.parts[1]; var glazing_semi: Array=glazing.semi
		window_mesh.size = Vector3(float(glazing_semi[0])*2.0,float(glazing_semi[1])*2.0,float(glazing_semi[2])*2.0)
		var windows := MeshInstance3D.new()
		windows.mesh = window_mesh
		windows.position.y = float(glazing.c[1])+0.4
		windows.material_override = glass_material
		car.add_child(windows)
		var stripe_mesh := BoxMesh.new()
		var livery: Dictionary=PLAN.TRAIN.parts[2]; var livery_semi: Array=livery.semi
		stripe_mesh.size = Vector3(float(livery_semi[0])*2.0,float(livery_semi[1])*2.0,float(livery_semi[2])*2.0)
		var stripe := MeshInstance3D.new()
		stripe.mesh = stripe_mesh
		stripe.position.y = float(livery.c[1])+0.4
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


func _add_rideable_car_collision(car: AnimatableBody3D) -> void:
	# Frame pieces leave the four side-door apertures clear for boarding.
	var parts: Array[Array]=[
		[Vector3(9.6,0.2,3.6),Vector3(0,1.1,0)], [Vector3(9.6,0.2,3.6),Vector3(0,3.65,0)],
		[Vector3(0.2,2.65,3.6),Vector3(-4.7,2.325,0)], [Vector3(0.2,2.65,3.6),Vector3(4.7,2.325,0)],
		[Vector3(1.7,2.65,0.16),Vector3(-3.95,2.325,-1.52)], [Vector3(3.4,2.65,0.16),Vector3(0,2.325,-1.52)], [Vector3(1.7,2.65,0.16),Vector3(3.95,2.325,-1.52)],
		[Vector3(1.7,2.65,0.16),Vector3(-3.95,2.325,1.52)], [Vector3(3.4,2.65,0.16),Vector3(0,2.325,1.52)], [Vector3(1.7,2.65,0.16),Vector3(3.95,2.325,1.52)],
	]
	for i in parts.size():
		var shape:=BoxShape3D.new(); shape.size=parts[i][0]; shape.margin=0.0
		var collision:=CollisionShape3D.new(); collision.name="RideableCarFrame_%02d"%i; collision.shape=shape; collision.position=parts[i][1]; car.add_child(collision)
	for side in [-1.0,1.0]:
		for door_x in [-2.4,2.4]:
			var door_spec: Dictionary=PLAN.TRAIN.doors; var door_mesh:=BoxMesh.new(); door_mesh.size=Vector3(float(door_spec.w),float(door_spec.h),0.08)
			var door:=MeshInstance3D.new(); door.name="TrainDoor"; door.mesh=door_mesh; door.position=Vector3(door_x,1.0+float(door_spec.h)*0.5,side*1.64); door.material_override=_mat(Color("#7b8580")); car.add_child(door)


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


func _dwell_for_distance(distance: float) -> float:
	var nearest_index:=0; var nearest_error:=INF
	for i in _stop_distances.size():
		var error:=absf(_stop_distances[i]-distance)
		if loop: error=minf(error,_total-error)
		if error<nearest_error: nearest_error=error; nearest_index=i
	var pos:=_path_pose(distance).origin
	var terminal:=not loop and (distance<1.0 or distance>_total-1.0)
	var interchange:=String(service_name).begins_with("Wall Line") or pos.distance_to(Vector3(-560.0,pos.y,0.0))<8.0 or (String(service_name)=="Spine Line" and absf(pos.z)>175.0) or (String(service_name)=="Meridian Line" and absf(pos.x+564.0)>200.0)
	if terminal or interchange: return 12.0
	return dwell


func _dwell_at(distance: float) -> float:
	var best:=INF; var value:=dwell
	for i in _stop_distances.size():
		var d:=absf(_stop_distances[i]-distance)
		if loop: d=minf(d,_total-d)
		if d<best: best=d; value=_stop_dwell_times[i]
	return value


func _scheduled_state_at(game_minute: float) -> Dictionary:
	var tau:=fposmod(game_minute-schedule_offset-float(schedule_train_index)*schedule_headway,schedule_circuit)
	for i in schedule_events.size():
		var event: Dictionary=schedule_events[i]
		var next: Dictionary=schedule_events[(i+1)%schedule_events.size()]
		var next_arrival:=float(next.arr) if i+1<schedule_events.size() else schedule_circuit
		var arrival:=float(event.arr); var departure:=float(event.dep); var direction:=_event_direction(String(event.dir))
		if tau>=arrival and tau<=departure:
			return {"s":float(event.s),"direction":direction,"moving":false,"stop":String(event.stop),"dwell":departure-arrival}
		if tau>departure and tau<next_arrival:
			if String(event.kind)=="end" and String(next.kind)=="start":
				return {"s":float(event.s),"direction":direction,"moving":false,"stop":String(event.stop),"dwell":next_arrival-departure}
			var fraction:float=(tau-departure)/maxf(0.001,next_arrival-departure)
			var s0:=float(event.s); var s1:=float(next.s)
			if String(service_name).begins_with("Wall Line"):
				var travel:=fposmod(s1-s0,_total) if direction>0.0 else fposmod(s0-s1,_total)
				return {"s":fposmod(s0+direction*fraction*travel,_total),"direction":direction,"moving":true,"stop":"","dwell":0.0}
			return {"s":lerpf(s0,s1,fraction),"direction":direction,"moving":true,"stop":"","dwell":0.0}
	return {"s":float(schedule_events[0].s),"direction":_event_direction(String(schedule_events[0].dir)),"moving":false,"stop":String(schedule_events[0].stop),"dwell":0.0}


func _event_direction(value: String) -> float:
	return -1.0 if value in ["north","east","outer"] else 1.0


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
