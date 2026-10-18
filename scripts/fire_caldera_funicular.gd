extends Node3D

## Two counterbalanced cars follow the generated rail section by arclength.
## Riders standing on either cabin are transported with the moving car.

var plan: Dictionary = {}
var profile: Array = []
var _points := PackedVector3Array()
var _distance := PackedFloat32Array()
var _length := 0.0
var _elapsed := 0.0
var _cars: Array[Node3D] = []
var _riders: Dictionary = {}
const SPEED := 3.5
const DOCK_DWELL := 2.0
const ENAMEL := Color(0.72, 0.18, 0.11)
const ASH := Color(0.72, 0.75, 0.76)
const WINDOW := Color(0.11, 0.15, 0.17, 0.74)


func _ready() -> void:
	if plan.is_empty():
		push_error("Fire Caldera funicular requires SITE.funicular")
		return
	for raw: Array in plan["profile"]:
		_points.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
	_distance.resize(_points.size())
	for i in range(1, _points.size()):
		_distance[i] = _distance[i - 1] + _points[i - 1].distance_to(_points[i])
	_length = _distance[-1] if not _distance.is_empty() else 0.0
	_build_cars()


func _build_cars() -> void:
	var car_plan: Dictionary = plan["car"]
	var semi: Array = car_plan["semi"]
	var eps: Array = car_plan["eps"]
	var names: Array = car_plan["names"]
	for index in 2:
		var car := Node3D.new()
		car.name = "FunicularCarUp" if index == 0 else "FunicularCarDown"
		add_child(car)
		_cars.append(car)
		var cabin := StaticBody3D.new()
		cabin.name = "LevelSuperEggCabin"
		cabin.collision_layer = 1
		cabin.collision_mask = 0
		car.add_child(cabin)
		# SuperEgg axes follow the carriage's local width, height, length frame.
		var axes := Vector3(float(semi[2]), float(semi[1]), float(semi[0]))
		var shell := MeshInstance3D.new()
		shell.name = str(names[index]).replace("the ", "")
		shell.mesh = _super_mesh(axes, float(eps[0]), float(eps[1]), -PI * 0.5, PI * 0.5, true)
		shell.material_override = SolidModel.material(ENAMEL if index == 0 else ASH, 0.28, 0.24)
		cabin.add_child(shell)
		var shell_faces := PackedVector3Array()
		var shell_vertices: PackedVector3Array = shell.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		shell_faces.append_array(shell_vertices)
		var shell_shape := ConcavePolygonShape3D.new()
		shell_shape.backface_collision = true
		shell_shape.set_faces(shell_faces)
		var collider := CollisionShape3D.new()
		collider.shape = shell_shape
		collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
		cabin.add_child(collider)
		var band := MeshInstance3D.new()
		band.name = "SmokedGlassBand"
		band.mesh = _super_mesh(axes * Vector3(1.008, 1.0, 1.008), float(eps[0]), float(eps[1]), -0.22, 0.34, true)
		var glass_mat := SolidModel.material(WINDOW, 0.12, 0.12)
		glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		band.material_override = glass_mat
		cabin.add_child(band)
		CollisionPolicy.mark_decorative(band)
		var floor := BoxMesh.new()
		floor.size = Vector3(float(car_plan["width"]) * 0.88, 0.18, float(car_plan["length"]) * 0.86)
		var deck := MeshInstance3D.new()
		deck.name = "CabinFloor"
		deck.mesh = floor
		deck.position.y = -float(semi[1]) + 0.12
		deck.material_override = SolidModel.material(Color(0.20, 0.18, 0.17), 0.75, 0.1)
		cabin.add_child(deck)
		CollisionPolicy.add_box(cabin, deck, floor.size, deck.position, Basis.IDENTITY, true)
		# A clear outer-side doorway in the shell keeps a walking rider's route
		# through the car physically open.
		var sill := BoxMesh.new()
		sill.size = Vector3(0.14, 0.22, float(car_plan["door"]))
		var sill_node := MeshInstance3D.new()
		sill_node.name = "OuterDoorSill"
		sill_node.mesh = sill
		sill_node.position = Vector3(float(car_plan["width"]) * 0.46, -float(semi[1]) + 0.2, 0.0)
		sill_node.material_override = SolidModel.material(Color(0.15, 0.24, 0.42), 0.9, 0.2)
		cabin.add_child(sill_node)
		CollisionPolicy.add_box(cabin, sill_node, sill.size, sill_node.position, Basis.IDENTITY, false)
		_build_ring_frame(car, axes, float(car_plan["length"]))


func _super_mesh(axes: Vector3, eps_lat: float, eps_lon: float, eta_min: float, eta_max: float, door_opening: bool = false) -> ArrayMesh:
	const RINGS := 28
	const SECTORS := 56
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rows: Array[PackedVector3Array] = []
	for ri in range(RINGS + 1):
		var eta := lerpf(eta_min, eta_max, float(ri) / RINGS)
		var row := PackedVector3Array()
		for si in SECTORS:
			var omega := TAU * float(si) / SECTORS
			row.append(SuperEgg.surface_point(axes, eta, omega, eps_lat, eps_lon))
		rows.append(row)
	for ri in RINGS:
		for si in SECTORS:
			var eta_mid := lerpf(eta_min, eta_max, (float(ri) + 0.5) / RINGS)
			var omega_mid := TAU * (float(si) + 0.5) / SECTORS
			if door_opening and absf(omega_mid - PI * 0.5) < 0.19 and eta_mid > -0.35 and eta_mid < 0.55:
				continue
			var next := (si + 1) % SECTORS
			var a := rows[ri][si]
			var b := rows[ri + 1][si]
			var c := rows[ri][next]
			var d := rows[ri + 1][next]
			st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)
			st.add_vertex(c); st.add_vertex(b); st.add_vertex(d)
	st.generate_normals()
	return st.commit()


func _build_ring_frame(car: Node3D, axes: Vector3, length: float) -> void:
	for depth_sign: float in [-1.0, 1.0]:
		var points := PackedVector3Array()
		for i in 49:
			var angle := TAU * float(i) / 48.0
			points.append(Vector3(cos(angle) * axes.x * 1.12, axes.y + sin(angle) * axes.y * 1.28, depth_sign * length * 0.34))
		var ring := FireCalderaPlanWalks._tube(points, 0.07)
		ring.name = "TiltingRingFrame"
		ring.material_override = SolidModel.material(Color(0.15, 0.24, 0.42), 0.9, 0.2)
		car.add_child(ring)
		CollisionPolicy.mark_decorative(ring)


func _process(delta: float) -> void:
	if _length <= 0.0 or _cars.size() != 2:
		return
	_elapsed += delta
	var travel_time := _length / SPEED
	var cycle := travel_time * 2.0 + DOCK_DWELL * 2.0
	for i in 2:
		var phase := fposmod(_elapsed + (travel_time + DOCK_DWELL if i == 1 else 0.0), cycle)
		var distance := 0.0
		if phase < DOCK_DWELL:
			distance = 0.0
		elif phase < DOCK_DWELL + travel_time:
			distance = (phase - DOCK_DWELL) * SPEED
		elif phase < DOCK_DWELL * 2.0 + travel_time:
			distance = _length
		else:
			distance = _length - (phase - DOCK_DWELL * 2.0 - travel_time) * SPEED
		_set_car(_cars[i], clampf(distance, 0.0, _length))
	_sync_riders()


func _sample(distance: float) -> Vector3:
	var index := 0
	while index < _distance.size() - 2 and _distance[index + 1] < distance:
		index += 1
	var span := _distance[index + 1] - _distance[index]
	return _points[index].lerp(_points[index + 1], (distance - _distance[index]) / maxf(span, 0.001))


func _set_car(car: Node3D, distance: float) -> void:
	var point := _sample(distance)
	var rail_index := 0
	while rail_index < _distance.size() - 2 and _distance[rail_index + 1] < distance:
		rail_index += 1
	var tangent := (_points[rail_index + 1] - _points[rail_index]).normalized()
	var yaw := atan2(tangent.x, tangent.z)
	var floor_height := float(plan["car"]["floor"])
	car.global_position = point + Vector3.UP * floor_height
	var horizontal := Vector3(tangent.x, 0.0, tangent.z).normalized()
	var lateral := Vector3.UP.cross(horizontal).normalized()
	var grade_up := horizontal.cross(lateral).normalized()
	car.global_basis = Basis(lateral, grade_up, tangent)
	var cabin := car.get_node("LevelSuperEggCabin") as StaticBody3D
	var semi: Array = plan["car"]["semi"]
	cabin.global_transform = Transform3D(Basis(Vector3.UP, yaw), car.global_position + Vector3.UP * float(semi[1]))


func _sync_riders() -> void:
	var car_plan: Dictionary = plan["car"]
	for candidate: Node in get_tree().get_nodes_in_group("party_playable_candidates"):
		var rider := candidate as Node3D
		if rider == null or not is_instance_valid(rider):
			continue
		if _riders.has(rider.get_instance_id()):
			var ride: Dictionary = _riders[rider.get_instance_id()]
			var car: Node3D = ride["car"]
			if not is_instance_valid(car) or not is_instance_valid(rider):
				_riders.erase(rider.get_instance_id())
				continue
			var local := car.global_transform.affine_inverse() * rider.global_position
			if absf(local.x) > float(car_plan["width"]) * 0.56 or absf(local.z) > float(car_plan["length"]) * 0.56 or local.y < -0.2 or local.y > 4.5:
				_riders.erase(rider.get_instance_id())
			else:
				rider.global_position = car.global_transform * (ride["offset"] as Vector3)
			continue
		for car: Node3D in _cars:
			var local := car.global_transform.affine_inverse() * rider.global_position
			if absf(local.x) <= float(car_plan["width"]) * 0.42 and absf(local.z) <= float(car_plan["length"]) * 0.42 and absf(local.y - 0.25) <= 0.5:
				_riders[rider.get_instance_id()] = {"car": car, "offset": local}
				break
