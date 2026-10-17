class_name FireCalderaHighline
extends RefCounted

## A level civic passage carried above the untouched caldera bowl.  The deck,
## its supports and the building docks are architecture; none of their heights
## are folded into FireCalderaGround's single-valued terrain function.

const SEGMENTS := 360
const DECK_THICKNESS := 0.22
const STEEL := Color(0.10, 0.16, 0.22)
const GLASS := Color(0.32, 0.66, 0.76, 0.34)
const GUARD_GLASS := Color(0.43, 0.73, 0.82, 0.24)
## Shared civic metal is a cool nickel/oxidized-glass alloy. Amber and cobalt
## remain the inn's own identity, not a settlement-wide default.
const JOINT := Color(0.34, 0.50, 0.52)
const PLATFORM_COMPOSITE := Color(0.13, 0.17, 0.19)
const REFRACTORY_EDGE := Color(0.21, 0.18, 0.17)
const GUARD_TOP := 1.09
const GUARD_HEIGHT := 1.04
const RENEWAL_DECK_HALF := Vector2(10.8, 8.8)
const RENEWAL_DECK_EXPONENT := 7.0
const RENEWAL_EDGE_HALF := Vector2(11.18, 9.18)


static func build(parent: Node3D) -> StaticBody3D:
	var planned := FireCalderaPlanWalks.build(parent, FireCalderaWalkwaysPlan.LEVELS, FireCalderaWalkwaysPlan.FLIGHTS, "CalderaWalkways")
	_build_plan_site(planned, FireCalderaWalkwaysPlan.SITE)
	return planned


static func build_platform(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	# The authored tier contains every porch. Keep only the private building
	# floor inside its wall footprint; the public extension is already part of
	# the single generated tier surface.
	var floor_entry := entry.duplicate(true)
	var footprint: Vector2 = entry["footprint"]
	floor_entry["walk_footprint"] = Vector2(footprint.x - SocketPlinth.REVEAL * 2.0,
		footprint.y - SocketPlinth.REVEAL * 2.0)
	var platform_line := line.duplicate(true)
	platform_line["bottom"] = float(line["datum"]) - maxf(0.42, SocketPlinth.sink(entry) + 0.12)
	var body := SocketPlinth.build(parent, floor_entry, platform_line, "walk_footprint")
	var centre: Vector2 = entry["centre"]
	var half := (footprint * 0.5)
	var deep := FireCalderaPlan.facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var pier_half := half
	var ground := FireCalderaGround.height(centre)
	_supertoroidal_pier(body, centre, across, deep, pier_half, ground - 2.4, float(line["datum"]) - 0.42, "%sSupertoroidalServicePier" % entry["id"])
	return body


static func build_ground_plot(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	# The public tier owns forecourts and yard landings; SocketPlinth owns the
	# private floor within the building wall footprint only.
	var floor_entry := entry.duplicate(true)
	var footprint: Vector2 = entry["footprint"]
	floor_entry["walk_footprint"] = Vector2(footprint.x - SocketPlinth.REVEAL * 2.0,
		footprint.y - SocketPlinth.REVEAL * 2.0)
	return SocketPlinth.build(parent, floor_entry, line, "walk_footprint")


static func _build_plan_site(body: StaticBody3D, site: Dictionary) -> void:
	var terrace: Dictionary = site["gate_terrace"]
	var gate: Dictionary = site["tempering_gate"]
	var plinth: Dictionary = site["gate_plinth"]
	for bearing: float in site["frames"]:
		var angle := deg_to_rad(bearing)
		var radial := Vector2(cos(angle), sin(angle))
		var foot_plan := radial * FireCalderaPlan.HIGHLINE_RADIUS
		var terrain_y := FireCalderaGround.height(foot_plan)
		var deck_y := FireCalderaPlan.HIGHLINE_DATUM - DECK_THICKNESS
		_vertical_member(body, Vector3(foot_plan.x, terrain_y, foot_plan.y), Vector3(foot_plan.x, deck_y, foot_plan.y), 0.28, "HighlineFrameColumn")
		var tangent := Vector2(-radial.y, radial.x)
		for side: float in [-1.0, 1.0]:
			var head := Vector3(foot_plan.x, deck_y - 0.55, foot_plan.y)
			var tip := foot_plan + tangent * side * 1.35
			_beam(body, head, Vector3(tip.x, deck_y, tip.y), Vector2(0.18, 0.18), JOINT)
	var centre: Array = terrace["centre"]
	var top := float(plinth["top"])
	var bottom := float(plinth["bottom"])
	var half: Array = terrace["half"]
	var outline := PackedVector2Array()
	var exponent := float(terrace["exponent"])
	const SAMPLES := 128
	for i in SAMPLES:
		var angle := TAU * float(i) / SAMPLES
		var c := cos(angle)
		var s := sin(angle)
		outline.append(Vector2(float(centre[0]) + signf(c) * pow(absf(c), 2.0 / exponent) * float(half[0]),
			float(centre[1]) + signf(s) * pow(absf(s), 2.0 / exponent) * float(half[1])))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in SAMPLES:
		var a2 := outline[i]
		var b2 := outline[(i + 1) % SAMPLES]
		var a := Vector3(a2.x, top, a2.y)
		var b := Vector3(b2.x, top, b2.y)
		var ab := Vector3(a2.x, bottom, a2.y)
		var bb := Vector3(b2.x, bottom, b2.y)
		st.add_vertex(a); st.add_vertex(ab); st.add_vertex(bb)
		st.add_vertex(a); st.add_vertex(bb); st.add_vertex(b)
		faces.append_array([a, ab, bb, a, bb, b])
	var pier := MeshInstance3D.new()
	pier.name = "GateTerraceSocketedPlinth"
	pier.mesh = st.commit()
	pier.material_override = SolidModel.material(PLATFORM_COMPOSITE, 0.82, 0.04)
	pier.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	body.add_child(pier)
	var plinth_shape := ConcavePolygonShape3D.new()
	plinth_shape.backface_collision = true
	plinth_shape.set_faces(faces)
	var plinth_collision := CollisionShape3D.new()
	plinth_collision.shape = plinth_shape
	plinth_collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	body.add_child(plinth_collision)
	var axis: Array = gate["at"]
	var span := float(gate["span"])
	var height := float(gate["height"])
	for side: float in [-1.0, 1.0]:
		var p := Vector3(float(axis[0]) + side * span * 0.5, top + height * 0.5, float(axis[1]))
		var pylon_size := Vector3(float(gate["pylon"]), height, 1.0)
		var pylon := BoxMesh.new()
		pylon.size = pylon_size
		var post := MeshInstance3D.new()
		post.name = "TemperingGatePylon"
		post.mesh = pylon
		post.position = p
		post.material_override = SolidModel.material(REFRACTORY_EDGE, 0.7, 0.03)
		body.add_child(post)
		CollisionPolicy.add_box(body, post, pylon_size, post.position, Basis.IDENTITY, false)
	var lintel := BoxMesh.new()
	lintel.size = Vector3(span + 0.9, 0.72, 0.9)
	var lintel_node := MeshInstance3D.new()
	lintel_node.name = "TemperingGateMineralGlazingLintel"
	lintel_node.mesh = lintel
	lintel_node.position = Vector3(float(axis[0]), top + height - 0.36, float(axis[1]))
	lintel_node.material_override = SolidModel.material(Color(0.48, 0.22, 0.15), 0.25, 0.2)
	body.add_child(lintel_node)
	CollisionPolicy.add_box(body, lintel_node, lintel.size, lintel_node.position, Basis.IDENTITY, false)
	var tongue: Dictionary = site["immersion_tongue"]
	var start: Array = tongue["start"]
	var renewal: Dictionary = FireCalderaPlan.plot("RENEWAL")
	var tongue_origin: Vector2 = FireCalderaPlan.shell_to_plan(renewal, Vector2(float(start[0]), float(start[1])))
	var tongue_end: Vector2 = FireCalderaPlan.shell_to_plan(renewal, Vector2(float(start[0]), float(start[1]) + float(tongue["length"])))
	var datum := float(FireCalderaWalkwaysPlan.LEVELS[2]["datum"])
	var tongue_flight := {
		"id": "RenewalImmersionTongue",
		"width": float(tongue["width"]),
		"profile": [
			[tongue_origin.x, datum, tongue_origin.y],
			[tongue_end.x, datum - float(tongue["drop"]), tongue_end.y],
		],
		"guards": [],
		"material": "glass",
	}
	FireCalderaPlanWalks._build_flight(body, tongue_flight)
	_build_funicular(body, site["funicular"])


static func _build_funicular(body: StaticBody3D, plan: Dictionary) -> void:
	var profile: Array = plan["profile"]
	if profile.size() < 2:
		return
	var centreline := PackedVector3Array()
	for raw: Array in profile:
		centreline.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
	var first := centreline[0]
	var last := centreline[-1]
	var direction := Vector2(last.x - first.x, last.z - first.z).normalized()
	var across := Vector2(-direction.y, direction.x)
	# Socketed track bed, rails, and paired supports follow the sampled section.
	for offset: float in [-float(plan["tracks"]) * 0.5, float(plan["tracks"]) * 0.5]:
		var rail_points := PackedVector3Array()
		for point in centreline:
			rail_points.append(point + Vector3(across.x * offset, 0.18, across.y * offset))
		var rail := _tube(body, rail_points, 0.09, STEEL, "FunicularTrackRail")
		CollisionPolicy.mark_decorative(rail)
	for i in range(0, centreline.size(), 5):
		var point := centreline[i]
		var footing_y := float(profile[i][3])
		if point.y > footing_y + 0.5:
			_vertical_member(body, Vector3(point.x, footing_y, point.z), Vector3(point.x, point.y, point.z), 0.22, "FunicularViaductPier")
	for station_index in [0, centreline.size() - 1]:
		var end := centreline[station_index]
		var tangent := (centreline[mini(station_index + 1, centreline.size() - 1)] - centreline[maxi(station_index - 1, 0)]).normalized()
		var yaw := atan2(tangent.x, tangent.z)
		var platform := BoxMesh.new()
		platform.size = Vector3(5.2, 0.3, 8.0)
		var station := MeshInstance3D.new()
		station.name = "FunicularLowerStation" if station_index == 0 else "FunicularGateStation"
		station.mesh = platform
		station.position = Vector3(end.x, end.y - 0.15, end.z)
		station.rotation.y = yaw
		station.material_override = SolidModel.material(PLATFORM_COMPOSITE, 0.76, 0.04)
		body.add_child(station)
		CollisionPolicy.add_box(body, station, platform.size, station.position, station.basis, true)
	var lift := Node3D.new()
	lift.name = "CounterbalancedFunicular"
	body.add_child(lift)
	lift.set_script(load("res://scripts/fire_caldera_funicular.gd"))
	lift.set("profile", centreline)
	lift.set("car_length", float(plan["car"]["length"]))
	lift.set("car_width", float(plan["car"]["width"]))
	lift.set("step_count", int(plan["car"]["steps"]))
	if lift.has_method("build_cars"):
		lift.call("build_cars", body)


# Retired independent route, junction and guard builders.
# Public walks now come only from FireCalderaWalkwaysPlan.

## Local interior paths in finished buildings still use this compact cassette
## helper. Public walks, flights and their guards are built only from the plan.
static func _build_glass_path(body: StaticBody3D, points: PackedVector3Array, width: float, label: String, guard_style: String = "glass", _branch: Dictionary = {}) -> void:
	if points.size() < 2:
		return
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	for i in points.size():
		var before := points[maxi(i - 1, 0)]
		var after := points[mini(i + 1, points.size() - 1)]
		var tangent := Vector2(after.x - before.x, after.z - before.z).normalized()
		var normal := Vector2(-tangent.y, tangent.x) * width * 0.5
		left.append(points[i] + Vector3(normal.x, 0.0, normal.y))
		right.append(points[i] - Vector3(normal.x, 0.0, normal.y))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in points.size() - 1:
		var a := left[i]
		var b := right[i]
		var c := right[i + 1]
		var d := left[i + 1]
		_quad(st, faces, a, b, c, d, Vector3.UP)
		_quad(st, faces, d - Vector3.UP * DECK_THICKNESS, c - Vector3.UP * DECK_THICKNESS,
			b - Vector3.UP * DECK_THICKNESS, a - Vector3.UP * DECK_THICKNESS, Vector3.DOWN)
		_quad(st, faces, a, a - Vector3.UP * DECK_THICKNESS, d - Vector3.UP * DECK_THICKNESS, d, Vector3(-1, 0, 0))
		_quad(st, faces, b, c, c - Vector3.UP * DECK_THICKNESS, b - Vector3.UP * DECK_THICKNESS, Vector3(1, 0, 0))
	var mesh := MeshInstance3D.new()
	mesh.name = "%sCassette" % label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(STEEL if guard_style == "metal" else GLASS, 0.24, 0.12)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = "%sCassetteCollision" % label
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)
	for side: float in [-1.0, 1.0]:
		var edge := PackedVector3Array()
		for i in points.size():
			edge.append((left[i] if side > 0.0 else right[i]) + Vector3.UP * GUARD_TOP)
		_tube(body, edge, 0.05, STEEL, "%sHandrail" % label)
		if guard_style == "glass":
			for i in edge.size() - 1:
				_path_guard(body, left[i] if side > 0.0 else right[i],
					left[i + 1] if side > 0.0 else right[i + 1], Vector3.UP)


static func _path_guard(body: StaticBody3D, a: Vector3, b: Vector3, normal: Vector3) -> void:
	var delta := b - a
	if delta.length_squared() < 0.001:
		return
	var x_axis := delta.normalized()
	var z_axis := x_axis.cross(normal).normalized()
	var basis := Basis(x_axis, normal, z_axis)
	var size := Vector3(delta.length(), 0.94, 0.035)
	var centre := (a + b) * 0.5 + normal * 0.53
	var visual := MeshInstance3D.new()
	visual.name = "BywayGuardGlass"
	var pane := BoxMesh.new()
	pane.size = size
	visual.mesh = pane
	visual.material_override = SolidModel.material(GUARD_GLASS, 0.12, 0.02)
	visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(visual)
	CollisionPolicy.add_box(body, visual, size, centre, basis, false)


static func _rail_cap(body: StaticBody3D, point: Vector3, radius: float, label: String) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "%sRailTerminal" % label
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	cap.mesh = sphere
	cap.material_override = SolidModel.material(STEEL, 0.55, 0.72)
	cap.position = point
	body.add_child(cap)
	CollisionPolicy.mark_decorative(cap)

## A generalized supertoroidal pier: each horizontal course is a squarish
## SuperEllipse; the courses contract into a deep concave waist, then broaden
## into the buried foot.  The top course is derived from the exact foundation
## outline, so there is no floating edge or mismatched capital.
static func _supertoroidal_pier(body: StaticBody3D, centre: Vector2, across: Vector2, deep: Vector2, half: Vector2, bottom: float, top: float, label: String) -> MeshInstance3D:
	const COURSES := 14
	const SIDES := 64
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices: Array[PackedVector3Array] = []
	for course in COURSES + 1:
		var t := float(course) / float(COURSES)
		var scale := lerpf(0.68, 0.34, smoothstep(0.0, 0.46, t)) if t <= 0.46 else lerpf(0.34, 1.0, smoothstep(0.46, 1.0, t))
		var loop := PackedVector3Array()
		for side in SIDES:
			var angle := TAU * float(side) / float(SIDES)
			var c := cos(angle)
			var s := sin(angle)
			var offset := across * signf(c) * pow(absf(c), 2.0 / 6.0) * half.x * scale + deep * signf(s) * pow(absf(s), 2.0 / 6.0) * half.y * scale
			loop.append(Vector3(centre.x + offset.x, lerpf(bottom, top, t), centre.y + offset.y))
		vertices.append(loop)
	for course in COURSES:
		for side in SIDES:
			var next := (side + 1) % SIDES
			# Outside-facing winding. The previous order generated inward normals,
			# making the support read hollow or disappear from common views.
			for point: Vector3 in [vertices[course][side], vertices[course + 1][next], vertices[course][next], vertices[course][side], vertices[course + 1][side], vertices[course + 1][next]]:
				st.add_vertex(point)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(PLATFORM_COMPOSITE, 0.46, 0.34)
	body.add_child(mesh)
	# The accessible collision is the substantial refractory core; the visual
	# shell remains concave without turning its underside into a climbable maze.
	CollisionPolicy.add_cylinder(body, mesh, minf(half.x, half.y) * 0.34, top - bottom, Vector3(centre.x, (bottom + top) * 0.5, centre.y), false)
	var glow := Color(1.0, 0.22, 0.035)
	for axis: Vector2 in [across, -across, deep, -deep]:
		var span := minf(half.x, half.y) * 0.36
		var p := centre + axis * span
		_beam(body, Vector3(p.x, bottom + 0.7, p.y), Vector3(p.x, top - 0.7, p.y), Vector2(0.09, 0.07), glow)
	return mesh


static func _vertical_member(body: StaticBody3D, foot: Vector3, head: Vector3, radius: float, label: String) -> void:
	var height := maxf(head.y - foot.y, 0.12)
	var at := Vector3(foot.x, foot.y + height * 0.5, foot.z)
	var part := SuperEgg.build_part(Vector3(radius, height * 0.5, radius), STEEL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	part.name = label
	part.position = at
	body.add_child(part)
	CollisionPolicy.add_box(body, part, Vector3(radius * 1.7, height, radius * 1.7), at, Basis(), false)


static func _beam(body: StaticBody3D, from: Vector3, to: Vector3, section: Vector2, colour: Color) -> void:
	var delta := to - from
	if delta.length() < 0.05:
		return
	var part := SuperEgg.build_part(Vector3(delta.length() * 0.5 + section.y * 0.5, section.x * 0.5, section.y * 0.5), colour, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	var x_axis := delta.normalized()
	var helper := Vector3.UP if absf(x_axis.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	var z_axis := x_axis.cross(helper).normalized()
	part.transform = Transform3D(Basis(x_axis, z_axis.cross(x_axis), z_axis), (from + to) * 0.5)
	body.add_child(part)
	CollisionPolicy.mark_decorative(part)


## One smooth pipe mesh following a polyline. Adjacent curve samples share
## vertex rings, so the rail is visually continuous even where its tangent
## changes; this replaces the former chain of overlapping SuperEgg stubs.
static func _tube(body: StaticBody3D, points: PackedVector3Array, radius: float, colour: Color, label: String) -> MeshInstance3D:
	const SIDES := 10
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in points.size():
		var tangent := (points[1] - points[0]).normalized() if i == 0 else ((points[-1] - points[-2]).normalized() if i == points.size() - 1 else (points[i + 1] - points[i - 1]).normalized())
		var side_axis := tangent.cross(Vector3.UP)
		if side_axis.length_squared() < 0.001:
			side_axis = tangent.cross(Vector3.FORWARD)
		side_axis = side_axis.normalized()
		var up_axis := side_axis.cross(tangent).normalized()
		var ring := PackedVector3Array()
		for side in SIDES:
			var angle := TAU * float(side) / float(SIDES)
			ring.append(points[i] + side_axis * cos(angle) * radius + up_axis * sin(angle) * radius)
		rings.append(ring)
	for i in rings.size() - 1:
		for side in SIDES:
			var next := (side + 1) % SIDES
			for point: Vector3 in [rings[i][side], rings[i][next], rings[i + 1][next], rings[i][side], rings[i + 1][next], rings[i + 1][side]]:
				st.add_vertex(point)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(colour, 0.55, 0.72)
	body.add_child(mesh)
	CollisionPolicy.mark_decorative(mesh)
	return mesh


static func _quad(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(normal)
		st.add_vertex(point)
	faces.append_array([a, b, c, a, c, d])
