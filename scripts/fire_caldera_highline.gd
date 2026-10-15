class_name FireCalderaHighline
extends RefCounted

## A level civic passage carried above the untouched caldera bowl.  The deck,
## its supports and the building docks are architecture; none of their heights
## are folded into FireCalderaGround's single-valued terrain function.

const SEGMENTS := 96
const DECK_THICKNESS := 0.22
const STEEL := Color(0.10, 0.16, 0.22)
const GLASS := Color(0.32, 0.66, 0.76, 0.34)
const GUARD_GLASS := Color(0.43, 0.73, 0.82, 0.24)
## Shared civic metal is a cool nickel/oxidized-glass alloy. Amber and cobalt
## remain the inn's own identity, not a settlement-wide default.
const JOINT := Color(0.34, 0.50, 0.52)
const PLATFORM_COMPOSITE := Color(0.13, 0.17, 0.19)


static func build(parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CalderaHighline"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var inner := FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var outer := FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var top := FireCalderaPlan.HIGHLINE_DATUM
	var bottom := top - DECK_THICKNESS
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in SEGMENTS:
		var a0 := TAU * float(i) / float(SEGMENTS)
		var a1 := TAU * float(i + 1) / float(SEGMENTS)
		var i0 := Vector3(cos(a0) * inner, top, sin(a0) * inner)
		var i1 := Vector3(cos(a1) * inner, top, sin(a1) * inner)
		var o0 := Vector3(cos(a0) * outer, top, sin(a0) * outer)
		var o1 := Vector3(cos(a1) * outer, top, sin(a1) * outer)
		var m0 := i0.lerp(o0, 0.5)
		var m1 := i1.lerp(o1, 0.5)
		var middle_angle := wrapf((a0 + a1) * 0.5, -PI, PI)
		if not _is_connection_angle(middle_angle):
			_quad(st, faces, i0, m0, m1, i1, Vector3.UP)
		if not _is_connection_angle(middle_angle) and not _is_dock_angle(middle_angle):
			_quad(st, faces, m0, o0, o1, m1, Vector3.UP)
	var mesh := MeshInstance3D.new()
	mesh.name = "HighlineDeck"
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(GLASS, 0.18, 0.08)
	body.add_child(mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.name = "HighlineDeckCollision"
	collider.shape = shape
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collider)
	# Twelve paired-fork frames leave long, unobstructed views into the crater.
	# They land on the real rock at their own bearing rather than on an assumed
	# level ring concealed under the deck.
	for i in 12:
		var angle := TAU * (float(i) + 0.5) / 12.0
		var radial := Vector2(cos(angle), sin(angle))
		var foot_plan := radial * FireCalderaPlan.HIGHLINE_RADIUS
		var ground := FireCalderaGround.height(foot_plan)
		var head := Vector3(foot_plan.x, bottom, foot_plan.y)
		var foot := Vector3(foot_plan.x, ground - 0.18, foot_plan.y)
		_vertical_member(body, foot, head, 0.28, "HighlinePier%02d" % i)
		var tangent := Vector2(-radial.y, radial.x)
		for side: float in [-1.0, 1.0]:
			var tip2 := foot_plan + tangent * side * 1.35
			_beam(body, head - Vector3.UP * 0.85, Vector3(tip2.x, bottom, tip2.y), Vector2(0.18, 0.18), JOINT)
	# Continuous SuperEgg edge members make the annulus read as one fabricated
	# structure while retaining a perfectly flat, snag-free walking collider.
	for i in 48:
		var a0 := TAU * float(i) / 48.0
		var a1 := TAU * float(i + 1) / 48.0
		for radius: float in [inner + 0.12, outer - 0.12]:
			_beam(body,
				Vector3(cos(a0) * radius, bottom + 0.05, sin(a0) * radius),
				Vector3(cos(a1) * radius, bottom + 0.05, sin(a1) * radius),
				Vector2(0.16, 0.16), STEEL)
	# Radial mullions make the transparent floor read as a fabricated civic
	# structure rather than an invisible collision ring.  Glass guards stop at
	# the property docks, so no rail is ever placed across a front door.
	for i in 48:
		var angle := TAU * (float(i) + 0.5) / 48.0
		_beam(body,
			Vector3(cos(angle) * (inner + 0.18), bottom + 0.04, sin(angle) * (inner + 0.18)),
			Vector3(cos(angle) * (outer - 0.18), bottom + 0.04, sin(angle) * (outer - 0.18)),
			Vector2(0.11, 0.11), STEEL)
	_build_guards(body, inner, outer, top)
	_build_arrival_byway(body)
	_build_guest_gate_link(body)
	_build_renewal_descent(body)
	_build_oren_terrace_link(body)
	_build_kel_upper_link(body)
	_build_junctions(body)
	return body


## A flat-datum building's enlarged dock.  SocketPlinth supplies the exact
## superellipse top and walkable collision.  One concave supertoroidal service
## pier carries the platform and encloses its insulated lava riser; its capital
## is the platform's own SuperEllipse and its buried foot disappears through
## the real bowl rather than standing on a second slab.
static func build_platform(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var platform_line := line.duplicate(true)
	platform_line["bottom"] = float(line["datum"]) - maxf(0.42, SocketPlinth.sink(entry) + 0.12)
	var body := SocketPlinth.build(parent, entry, platform_line, SocketPlinth.size_key(entry))
	var centre: Vector2 = entry["centre"]
	var half := (entry[SocketPlinth.size_key(entry)] as Vector2) * 0.5
	var deep := FireCalderaPlan.facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var pier_half := half + Vector2.ONE * (SocketPlinth.REVEAL - 0.12)
	var ground := FireCalderaGround.height(centre)
	_supertoroidal_pier(body, centre, across, deep, pier_half, ground - 2.4, float(line["datum"]) - 0.42, "%sSupertoroidalServicePier" % entry["id"])
	# The cool-alloy strip is the public-private expansion joint: the ring's
	# glass deck ends here and the household or institution owns the platform
	# beyond it. It sits at the platform's public edge; the broad floor between
	# this seam and the facade is the household's arrival porch.
	var footprint_half := (entry["footprint"] as Vector2) * 0.5
	var platform_half := (entry[SocketPlinth.size_key(entry)] as Vector2) * 0.5 + Vector2.ONE * SocketPlinth.REVEAL
	var joint_centre := centre + deep * platform_half.y
	_beam(body,
		Vector3((joint_centre - across * (footprint_half.x + 0.35)).x, float(line["datum"]) + 0.025, (joint_centre - across * (footprint_half.x + 0.35)).y),
		Vector3((joint_centre + across * (footprint_half.x + 0.35)).x, float(line["datum"]) + 0.025, (joint_centre + across * (footprint_half.x + 0.35)).y),
		Vector2(0.07, 0.10), JOINT)
	return body


## Transparent guards on both drops.  The outer guard opens only where a
## raised building's front actually docks; this converts every opening into a
## deliberate threshold rather than a door onto air.
static func _build_guards(body: StaticBody3D, inner: float, outer: float, top: float) -> void:
	for radius: float in [inner, outer]:
		var allowed := PackedByteArray()
		allowed.resize(SEGMENTS)
		for i in SEGMENTS:
			var a0 := TAU * float(i) / float(SEGMENTS)
			var a1 := TAU * float(i + 1) / float(SEGMENTS)
			var middle := wrapf((a0 + a1) * 0.5, -PI, PI)
			allowed[i] = 0 if _is_connection_angle(middle) or (radius == outer and _is_dock_angle(middle)) else 1
			if allowed[i] == 1:
				var p0 := Vector3(cos(a0) * radius, top, sin(a0) * radius)
				var p1 := Vector3(cos(a1) * radius, top, sin(a1) * radius)
				_guard_pane(body, p0, p1)
		_build_ring_rail_runs(body, radius, top + 1.18, allowed, "InnerTopRail" if radius == inner else "OuterTopRail")


## Fabricate each guarded arc as one bent pipe. Gaps occur only at an authored
## junction or dock; curve tessellation must never read as a row of short bars.
static func _build_ring_rail_runs(body: StaticBody3D, radius: float, y: float, allowed: PackedByteArray, label: String) -> void:
	var first_gap := allowed.find(0)
	if first_gap < 0:
		var closed := PackedVector3Array()
		for i in SEGMENTS + 1:
			var angle := TAU * float(i) / float(SEGMENTS)
			closed.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
		_tube(body, closed, 0.08, STEEL, label)
		return
	var run := PackedVector3Array()
	for step in SEGMENTS:
		var segment := (first_gap + 1 + step) % SEGMENTS
		if allowed[segment] == 1:
			var a0 := TAU * float(segment) / float(SEGMENTS)
			var a1 := TAU * float(segment + 1) / float(SEGMENTS)
			if run.is_empty():
				run.append(Vector3(cos(a0) * radius, y, sin(a0) * radius))
			run.append(Vector3(cos(a1) * radius, y, sin(a1) * radius))
		elif run.size() >= 2:
			_tube(body, run, 0.08, STEEL, "%sRun" % label)
			run = PackedVector3Array()
	if run.size() >= 2:
		_tube(body, run, 0.08, STEEL, "%sRun" % label)


static func _is_dock_angle(angle: float) -> bool:
	# The arrival byway enters on the south; building gaps follow their real
	# frontage plus a half-metre tolerance for the rounded platform corner.
	if absf(wrapf(angle - deg_to_rad(-90.0), -PI, PI)) < deg_to_rad(3.0):
		return true
	for entry in FireCalderaPlan.PLOTS:
		if str(entry.get("site", "ground")) != "highline":
			continue
		var centre: Vector2 = entry["centre"]
		var half_angle := atan2((entry["footprint"] as Vector2).x * 0.5 + 0.5, FireCalderaPlan.HIGHLINE_RADIUS)
		if absf(wrapf(angle - centre.angle(), -PI, PI)) < half_angle:
			return true
	return false


static func _is_connection_angle(angle: float) -> bool:
	var starts: Array[Vector2] = [
		FireCalderaPlan.arrival_byway()[-1],
		FireCalderaPlan.renewal_byway(-1.0)[0],
		FireCalderaPlan.renewal_byway(1.0)[0],
		FireCalderaPlan.oren_terrace_link()[0],
		FireCalderaPlan.kel_upper_link()[0],
	]
	for start in starts:
		if absf(wrapf(angle - start.angle(), -PI, PI)) < deg_to_rad(3.4):
			return true
	return false


static func _guard_pane(body: StaticBody3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	var length := delta.length()
	var pane := BoxMesh.new()
	pane.size = Vector3(length, 1.02, 0.035)
	var instance := MeshInstance3D.new()
	instance.name = "HighlineGuardGlass"
	instance.mesh = pane
	instance.material_override = SolidModel.material(GUARD_GLASS, 0.12, 0.02)
	var x_axis := delta.normalized()
	var z_axis := x_axis.cross(Vector3.UP).normalized()
	instance.transform = Transform3D(Basis(x_axis, Vector3.UP, z_axis), (a + b) * 0.5 + Vector3.UP * 0.58)
	body.add_child(instance)
	CollisionPolicy.add_box(body, instance, pane.size, instance.position, instance.basis, false)


## The kingdom gate reaches the raised system by one long curved glass
## gallery.  It begins at the south gate, remains below the ring while it
## climbs, then joins the east side at a shallow grade instead of punching a
## stair through the preserved crater wall.
static func _build_arrival_byway(body: StaticBody3D) -> void:
	var points := PackedVector3Array()
	var plan := FireCalderaPlan.arrival_byway()
	var start_y := FireCalderaGround.crater_wall(plan[0]) + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE
	for i in plan.size():
		var t := float(i) / float(plan.size() - 1)
		# Hold the first gate throat level until the full-width slab is inside
		# the lip, then begin the parabolic-bowl descent.
		var descent_t := FireCalderaPlan.route_height_t("H0", t)
		points.append(Vector3(plan[i].x, lerpf(start_y, FireCalderaPlan.HIGHLINE_DATUM, descent_t), plan[i].y))
	_build_glass_path(body, points, 3.8, "ArrivalByway")


## The inn stands beside the true gate. A short branch from the arrival
## forecourt reaches its door before the main gallery descends to the ring.
static func _build_guest_gate_link(body: StaticBody3D) -> void:
	var plan := FireCalderaPlan.guest_gate_link()
	var points := PackedVector3Array()
	var main_start := FireCalderaGround.crater_wall(FireCalderaPlan.arrival_byway()[0]) + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE
	var radial_t := clampf((FireCalderaPlan.RIM_RADIUS - plan[0].length()) / (FireCalderaPlan.RIM_RADIUS - FireCalderaPlan.HIGHLINE_RADIUS), 0.0, 1.0)
	var start_y := lerpf(main_start, FireCalderaPlan.HIGHLINE_DATUM, FireCalderaPlan.route_height_t("H0", radial_t))
	for i in plan.size():
		var t := float(i) / float(plan.size() - 1)
		points.append(Vector3(plan[i].x, lerpf(start_y, FireCalderaPlan.GUEST_GATE_DATUM, FireCalderaPlan.route_height_t("HG", t)), plan[i].y))
	_build_glass_path(body, points, 3.0, "GuestGateLink")


## Renewal is public infrastructure, so its descent belongs to the Highline.
## Two curved galleries leave opposite ring sectors and land on the actual
## flanks of the public deck. Neither route is a disguised rear entrance.
static func _build_renewal_descent(body: StaticBody3D) -> void:
	var entry := FireCalderaPlan.plot("RENEWAL")
	var finish_y := float(FireCalderaGround.survey(entry)["datum"])
	for side: float in [-1.0, 1.0]:
		var points := PackedVector3Array()
		var plan := FireCalderaPlan.renewal_byway(side)
		for i in plan.size():
			var t := float(i) / float(plan.size() - 1)
			points.append(Vector3(plan[i].x, lerpf(FireCalderaPlan.HIGHLINE_DATUM, finish_y, t), plan[i].y))
		_build_glass_path(body, points, 3.2, "RenewalWest" if side < 0.0 else "RenewalEast")


static func _build_oren_terrace_link(body: StaticBody3D) -> void:
	var entry := FireCalderaPlan.plot("OREN")
	var line := FireCalderaGround.survey(entry)
	var finish_y := float(line["datum"]) + FireCalderaOren.UPPER + FireCalderaOren.roof_top()
	var points := PackedVector3Array()
	var plan := FireCalderaPlan.oren_terrace_link()
	for i in plan.size():
		var t := float(i) / float(plan.size() - 1)
		points.append(Vector3(plan[i].x, lerpf(FireCalderaPlan.HIGHLINE_DATUM, finish_y, FireCalderaPlan.route_height_t("H4", t)), plan[i].y))
	_build_glass_path(body, points, 2.4, "OrenTerraceLink")


static func _build_kel_upper_link(body: StaticBody3D) -> void:
	var entry := FireCalderaPlan.plot("KEL")
	var line := FireCalderaGround.survey(entry)
	var finish_y := float(line["datum"]) + FireCalderaKel.RESIDENCE
	var plan := FireCalderaPlan.kel_upper_link()
	var points := PackedVector3Array()
	for i in plan.size():
		var t := float(i) / float(plan.size() - 1)
		points.append(Vector3(plan[i].x, lerpf(FireCalderaPlan.HIGHLINE_DATUM, finish_y, FireCalderaPlan.route_height_t("H5", t)), plan[i].y))
	_build_glass_path(body, points, 2.4, "KelUpperLink")


## Each branch leaves the ring through one readable organic node rather than
## through overlapping slivers of annulus and ramp. The ring has matching
## openings at these bearings; the node is the civic decision point.
static func _build_junctions(body: StaticBody3D) -> void:
	var starts: Array[Array] = [
		["ArrivalJunction", FireCalderaPlan.arrival_byway()[-1]],
		["RenewalWestJunction", FireCalderaPlan.renewal_byway(-1.0)[0]],
		["RenewalEastJunction", FireCalderaPlan.renewal_byway(1.0)[0]],
		["OrenTerraceJunction", FireCalderaPlan.oren_terrace_link()[0]],
		["KelUpperJunction", FireCalderaPlan.kel_upper_link()[0]],
	]
	for data in starts:
		var at: Vector2 = data[1]
		var radial := at.normalized()
		var tangent := Vector2(-radial.y, radial.x)
		var basis := Basis(Vector3(tangent.x, 0.0, tangent.y), Vector3.UP, Vector3(radial.x, 0.0, radial.y))
		CalderaShell.soft_slab(body, str(data[0]), Vector3(at.x, FireCalderaPlan.HIGHLINE_DATUM - DECK_THICKNESS * 0.5, at.y), Vector3(4.35, DECK_THICKNESS * 0.5, 3.0), Vector2(4.1, 2.75), GLASS, basis)


static func _build_glass_path(body: StaticBody3D, points: PackedVector3Array, width: float, label: String) -> void:
	if points.size() < 2:
		return
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in points.size():
		var tangent := (points[1] - points[0]).normalized() if i == 0 else ((points[-1] - points[-2]).normalized() if i == points.size() - 1 else (points[i + 1] - points[i - 1]).normalized())
		var horizontal := Vector3(tangent.x, 0.0, tangent.z).normalized()
		var across := Vector3.UP.cross(horizontal).normalized()
		var normal := tangent.cross(across).normalized()
		if normal.y < 0.0:
			normal = -normal
		left.append(points[i] + across * width * 0.5)
		right.append(points[i] - across * width * 0.5)
		normals.append(normal)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var visual_only := PackedVector3Array()
	for i in points.size() - 1:
		var normal := (normals[i] + normals[i + 1]).normalized()
		var bl := left[i] - normals[i] * DECK_THICKNESS
		var br := right[i] - normals[i] * DECK_THICKNESS
		var nbl := left[i + 1] - normals[i + 1] * DECK_THICKNESS
		var nbr := right[i + 1] - normals[i + 1] * DECK_THICKNESS
		_quad(st, faces, left[i], right[i], right[i + 1], left[i + 1], normal)
		_quad(st, faces, br, bl, nbl, nbr, -normal)
		var across := (left[i] - right[i]).normalized()
		_quad(st, faces, left[i + 1], nbl, bl, left[i], across)
		_quad(st, faces, right[i], br, nbr, right[i + 1], -across)
	var mesh := MeshInstance3D.new()
	mesh.name = "%sGlassRibbon" % label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(GLASS, 0.18, 0.08)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.name = "%sRibbonCollision" % label
	collider.shape = shape
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collider)
	var left_edge := PackedVector3Array()
	var right_edge := PackedVector3Array()
	var left_rail := PackedVector3Array()
	var right_rail := PackedVector3Array()
	for i in points.size():
		left_edge.append(left[i] + normals[i] * 0.04)
		right_edge.append(right[i] + normals[i] * 0.04)
		if i > 0 and i < points.size() - 1:
			left_rail.append(left[i] + normals[i] * 1.15)
			right_rail.append(right[i] + normals[i] * 1.15)
	_tube(body, left_edge, 0.07, STEEL, "%sLeftEdge" % label)
	_tube(body, right_edge, 0.07, STEEL, "%sRightEdge" % label)
	if left_rail.size() >= 2:
		_tube(body, left_rail, 0.08, STEEL, "%sLeftTopRail" % label)
		_tube(body, right_rail, 0.08, STEEL, "%sRightTopRail" % label)
	for i in range(1, points.size() - 2):
		var normal := (normals[i] + normals[i + 1]).normalized()
		_path_guard(body, left[i], left[i + 1], normal)
		_path_guard(body, right[i + 1], right[i], normal)


static func _path_guard(body: StaticBody3D, a: Vector3, b: Vector3, normal: Vector3) -> void:
	var delta := b - a
	var length := delta.length()
	var x_axis := delta.normalized()
	var z_axis := x_axis.cross(normal).normalized()
	var pane := BoxMesh.new()
	pane.size = Vector3(length, 1.02, 0.035)
	var visual := MeshInstance3D.new()
	visual.name = "BywayGuardGlass"
	visual.mesh = pane
	visual.material_override = SolidModel.material(GUARD_GLASS, 0.12, 0.02)
	visual.transform = Transform3D(Basis(x_axis, normal, z_axis), (a + b) * 0.5 + normal * 0.58)
	body.add_child(visual)
	CollisionPolicy.add_box(body, visual, pane.size, visual.position, visual.basis, false)


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
