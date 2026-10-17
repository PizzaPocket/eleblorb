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
	var body := StaticBody3D.new()
	body.name = "CalderaHighline"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var inner := FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var outer := FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var top := FireCalderaPlan.HIGHLINE_DATUM
	var bottom := top - DECK_THICKNESS
	var dock_polygons := _dock_polygons()
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
		var i0b := i0 - Vector3.UP * DECK_THICKNESS
		var i1b := i1 - Vector3.UP * DECK_THICKNESS
		var o0b := o0 - Vector3.UP * DECK_THICKNESS
		var o1b := o1 - Vector3.UP * DECK_THICKNESS
		var m0b := m0 - Vector3.UP * DECK_THICKNESS
		var m1b := m1 - Vector3.UP * DECK_THICKNESS
		_emit_quad_outside_docks(st, faces, i0, m0, m1, i1, Vector3.UP, dock_polygons)
		_emit_quad_outside_docks(st, faces, i1b, m1b, m0b, i0b, Vector3.DOWN, dock_polygons)
		var inner_midpoint := Vector2((i0.x + i1.x) * 0.5, (i0.z + i1.z) * 0.5)
		if not _inside_any_dock(inner_midpoint, dock_polygons):
			_quad(st, faces, i0, i1, i1b, i0b, Vector3(-cos(a0), 0.0, -sin(a0)))
		_emit_quad_outside_docks(st, faces, m0, o0, o1, m1, Vector3.UP, dock_polygons)
		_emit_quad_outside_docks(st, faces, m1b, o1b, o0b, m0b, Vector3.DOWN, dock_polygons)
		var outer_midpoint := Vector2((o0.x + o1.x) * 0.5, (o0.z + o1.z) * 0.5)
		if not _inside_any_dock(outer_midpoint, dock_polygons):
			_quad(st, faces, o0, o1, o1b, o0b, Vector3(cos(a0), 0.0, sin(a0)))
	_emit_dock_cut_walls(st, faces, dock_polygons, inner, outer, top, bottom)
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
	# Continuous round edge tubes replace the straight, faceted members that
	# previously read as flat bars beneath the glazed walking ribbon.
	for radius: float in [inner + 0.12, outer - 0.12]:
		var edge_pipe := PackedVector3Array()
		for i in SEGMENTS + 1:
			var angle := TAU * float(i) / float(SEGMENTS)
			edge_pipe.append(Vector3(cos(angle) * radius, bottom + 0.05, sin(angle) * radius))
		_tube(body, edge_pipe, 0.08, STEEL, "HighlineLowerEdgePipe")
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
	_build_gate_hotel_junction(body)
	_build_renewal_descent(body)
	_build_oren_terrace_link(body)
	_build_ground_network(body)
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
	_build_platform_guards(body, entry, float(line["datum"]), SocketPlinth.size_key(entry))
	return body


## Raised plinths are outdoor rooms, not unguarded shortcuts. The public face
## stays open only at the shared route landing; the other three edges receive
## a glass balustrade and a continuous top rail.
static func _build_platform_guards(body: StaticBody3D, entry: Dictionary, datum: float, size_key: String) -> void:
	var half: Vector2 = (entry[size_key] as Vector2) * 0.5 + Vector2.ONE * SocketPlinth.REVEAL
	var open_at := FireCalderaPlan.front_point(entry, size_key) + FireCalderaPlan.facing(entry) * SocketPlinth.REVEAL
	var portal_width := FireCalderaPlan.HIGHLINE_WIDTH if str(entry["id"]) == "CIVIC" else 3.0
	var portal_axis := Vector2(-FireCalderaPlan.facing(entry).y, FireCalderaPlan.facing(entry).x)
	if str(entry["id"]) == "GUEST":
		var route := FireCalderaPlan.guest_gate_link()
		open_at = route[-1]
		var direction := (route[-1] - route[-2]).normalized()
		portal_axis = Vector2(direction.y, -direction.x)
	var portal_points := [open_at - portal_axis * portal_width * 0.5, open_at + portal_axis * portal_width * 0.5]
	var deep := FireCalderaPlan.facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var edge := SocketPlinth._loop(entry["centre"], across, deep, half, datum)
	edge.append(edge[0])
	var highline_frontage := str(entry.get("site", "")) == "highline"
	if highline_frontage:
		edge = _insert_platform_ring_intersections(edge, entry["centre"], deep,
			FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5,
			FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5)
	else:
		edge = _insert_guard_portals(edge, portal_points)
	var rail_run := PackedVector3Array()
	for i in edge.size() - 1:
		var a := edge[i]
		var b := edge[i + 1]
		var middle := (a + b) * 0.5
		var midpoint_plan := Vector2(middle.x, middle.z)
		var offset := midpoint_plan - open_at
		var plot_offset := midpoint_plan - (entry["centre"] as Vector2)
		var radial := midpoint_plan.distance_to(entry["centre"] as Vector2)
		var shared_front := highline_frontage and plot_offset.dot(deep) > 0.0 and radial >= FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5 and radial <= FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5
		var open := shared_front or (not highline_frontage and absf(offset.dot(portal_axis)) < portal_width * 0.5 and absf(offset.dot(Vector2(-portal_axis.y, portal_axis.x))) < 0.3)
		if open:
			if rail_run.size() >= 2:
				_tube(body, rail_run, 0.075, STEEL, "%sPorchRail" % entry["id"])
				_rail_cap(body, rail_run[0], 0.075, str(entry["id"]))
				_rail_cap(body, rail_run[-1], 0.075, str(entry["id"]))
			rail_run = PackedVector3Array()
			continue
		var pane := BoxMesh.new()
		pane.size = Vector3(Vector2(b.x - a.x, b.z - a.z).length(), 1.04, 0.04)
		var visual := MeshInstance3D.new()
		visual.name = "%sPorchGuard" % entry["id"]
		visual.mesh = pane
		visual.material_override = SolidModel.material(GUARD_GLASS, 0.12, 0.02)
		var along := (b - a).normalized()
		var pane_across := along.cross(Vector3.UP).normalized()
		visual.transform = Transform3D(Basis(along, Vector3.UP, pane_across), middle + Vector3.UP * 0.57)
		body.add_child(visual)
		CollisionPolicy.add_box(body, visual, pane.size, visual.position, visual.basis, false)
		if rail_run.is_empty():
			rail_run.append(a + Vector3.UP * GUARD_TOP)
		rail_run.append(b + Vector3.UP * GUARD_TOP)
	if rail_run.size() >= 2:
		_tube(body, rail_run, 0.075, STEEL, "%sPorchRail" % entry["id"])
		_rail_cap(body, rail_run[0], 0.075, str(entry["id"]))
		_rail_cap(body, rail_run[-1], 0.075, str(entry["id"]))


static func _insert_platform_ring_intersections(edge: PackedVector3Array, centre: Vector2, facing: Vector2, inner: float, outer: float) -> PackedVector3Array:
	var refined := PackedVector3Array()
	refined.append(edge[0])
	for i in edge.size() - 1:
		var a := Vector2(edge[i].x, edge[i].z)
		var b := Vector2(edge[i + 1].x, edge[i + 1].z)
		var delta := b - a
		var cuts: Array[float] = [0.0, 1.0]
		for radius: float in [inner, outer]:
			var relative := a - centre
			var qa := delta.length_squared()
			var qb := 2.0 * relative.dot(delta)
			var qc: float = relative.length_squared() - radius * radius
			var discriminant: float = qb * qb - 4.0 * qa * qc
			if discriminant >= 0.0 and qa > 0.000001:
				var root := sqrt(discriminant)
				for t in [(-qb - root) / (2.0 * qa), (-qb + root) / (2.0 * qa)]:
					if t > 0.00001 and t < 0.99999:
						cuts.append(t)
		var facing_start := (a - centre).dot(facing)
		var facing_end := (b - centre).dot(facing)
		if facing_start * facing_end < 0.0:
			cuts.append(facing_start / (facing_start - facing_end))
		cuts.sort()
		for j in range(1, cuts.size()):
			var point := a.lerp(b, cuts[j])
			refined.append(Vector3(point.x, edge[i].y, point.y))
	return refined


static func _insert_guard_portals(edge: PackedVector3Array, portals: Array) -> PackedVector3Array:
	var refined := PackedVector3Array()
	for i in edge.size() - 1:
		var a := edge[i]
		var b := edge[i + 1]
		var a2 := Vector2(a.x, a.z)
		for portal: Vector2 in portals:
			if a2.distance_to(portal) < 0.22:
				a = Vector3(portal.x, a.y, portal.y)
				a2 = portal
		refined.append(a)
		var additions: Array[Dictionary] = []
		for point: Vector2 in portals:
			var b2 := Vector2(b.x, b.z)
			var segment := b2 - a2
			var t := clampf((point - a2).dot(segment) / maxf(segment.length_squared(), 0.0001), 0.0, 1.0)
			if t > 0.001 and t < 0.999 and (a2 + segment * t).distance_to(point) < 0.22:
				additions.append({"t": t, "point": point})
		additions.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["t"]) < float(right["t"]))
		for addition in additions:
			var point: Vector2 = addition["point"]
			refined.append(Vector3(point.x, a.y, point.y))
	var last := edge[-1]
	var last_plan := Vector2(last.x, last.z)
	for portal: Vector2 in portals:
		if last_plan.distance_to(portal) < 0.22:
			last = Vector3(portal.x, last.y, portal.y)
			last_plan = portal
	refined.append(last)
	return refined


## Transparent guards on both drops.  The outer guard opens only where a
## raised building's front actually docks; this converts every opening into a
## deliberate threshold rather than a door onto air.
static func _build_guards(body: StaticBody3D, inner: float, outer: float, top: float) -> void:
	for radius: float in [inner, outer]:
		var angles := _ring_guard_angles(radius)
		var allowed := PackedByteArray()
		allowed.resize(angles.size() - 1)
		for i in allowed.size():
			var a0 := angles[i]
			var a1 := angles[i + 1]
			var middle := wrapf((a0 + a1) * 0.5, -PI, PI)
			allowed[i] = 0 if _is_connection_angle(middle, radius) or (radius == outer and _is_dock_angle(middle)) else 1
		_build_ring_guard_ribbons(body, radius, top, allowed, angles)
		_build_ring_rail_runs(body, radius, top + GUARD_TOP, allowed, angles, "InnerTopRail" if radius == inner else "OuterTopRail")


static func _ring_guard_angles(radius: float) -> PackedFloat32Array:
	var values: Array[float] = []
	for i in SEGMENTS:
		values.append(TAU * float(i) / float(SEGMENTS))
	var openings: Array[Dictionary] = []
	var inner := FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var outer := FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	if is_equal_approx(radius, outer):
		openings.append({"point": _ring_crossing(FireCalderaPlan.arrival_byway(), outer), "width": 3.8})
		for polygon: PackedVector2Array in _dock_polygons():
			for i in polygon.size():
				var a := polygon[i]
				var delta := polygon[(i + 1) % polygon.size()] - a
				var qa := delta.length_squared()
				var qb := 2.0 * a.dot(delta)
				var qc := a.length_squared() - outer * outer
				var discriminant := qb * qb - 4.0 * qa * qc
				if discriminant < 0.0 or qa < 0.000001:
					continue
				var root := sqrt(discriminant)
				for t in [(-qb - root) / (2.0 * qa), (-qb + root) / (2.0 * qa)]:
					if t > 0.00001 and t < 0.99999:
						values.append(fposmod((a + delta * t).angle(), TAU))
	elif is_equal_approx(radius, inner):
		for side: float in [-1.0, 1.0]:
			openings.append({"point": FireCalderaPlan.renewal_byway(side)[0], "width": 3.2})
		openings.append({"point": _ring_crossing(FireCalderaPlan.oren_terrace_link(), inner), "width": 2.4})
	for opening: Dictionary in openings:
		var point: Vector2 = opening["point"]
		var half := asin(clampf(float(opening["width"]) * 0.5 / radius, 0.0, 0.99))
		for angle in [point.angle() - half, point.angle() + half]:
			var normalized := fposmod(angle, TAU)
			if normalized > 0.00001 and normalized < TAU - 0.00001:
				values.append(normalized)
	values.sort()
	var result := PackedFloat32Array()
	for angle in values:
		if result.is_empty() or absf(angle - result[-1]) > 0.00001:
			result.append(angle)
	result.append(TAU)
	return result


static func _build_ring_guard_ribbons(body: StaticBody3D, radius: float, top: float, allowed: PackedByteArray, angles: PackedFloat32Array) -> void:
	var first_gap := allowed.find(0)
	if first_gap < 0:
		var closed := PackedVector3Array()
		for angle in angles:
			closed.append(Vector3(cos(angle) * radius, top, sin(angle) * radius))
		_path_guard_ribbon(body, closed, closed, _up_normals(closed.size()), 0, closed.size() - 1, "HighlineRing")
		return
	var run := PackedVector3Array()
	for step in allowed.size():
		var segment := (first_gap + 1 + step) % allowed.size()
		if allowed[segment] == 1:
			var a := angles[segment]
			var b := angles[segment + 1]
			if run.is_empty():
				run.append(Vector3(cos(a) * radius, top, sin(a) * radius))
			run.append(Vector3(cos(b) * radius, top, sin(b) * radius))
		elif run.size() >= 2:
			_path_guard_ribbon(body, run, run, _up_normals(run.size()), 0, run.size() - 1, "HighlineRing")
			run = PackedVector3Array()
	if run.size() >= 2:
		_path_guard_ribbon(body, run, run, _up_normals(run.size()), 0, run.size() - 1, "HighlineRing")


static func _up_normals(count: int) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(count)
	for i in count:
		normals[i] = Vector3.UP
	return normals


## Fabricate each guarded arc as one bent pipe. Gaps occur only at an authored
## junction or dock; curve tessellation must never read as a row of short bars.
static func _build_ring_rail_runs(body: StaticBody3D, radius: float, y: float, allowed: PackedByteArray, angles: PackedFloat32Array, label: String) -> void:
	var first_gap := allowed.find(0)
	if first_gap < 0:
		var closed := PackedVector3Array()
		for angle in angles:
			closed.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
		_tube(body, closed, 0.08, STEEL, label)
		return
	var run := PackedVector3Array()
	for step in allowed.size():
		var segment := (first_gap + 1 + step) % allowed.size()
		if allowed[segment] == 1:
			var a0 := angles[segment]
			var a1 := angles[segment + 1]
			if run.is_empty():
				run.append(Vector3(cos(a0) * radius, y, sin(a0) * radius))
			run.append(Vector3(cos(a1) * radius, y, sin(a1) * radius))
		elif run.size() >= 2:
			_tube(body, run, 0.08, STEEL, "%sRun" % label)
			_rail_cap(body, run[0], 0.08, label)
			_rail_cap(body, run[-1], 0.08, label)
			run = PackedVector3Array()
	if run.size() >= 2:
		_tube(body, run, 0.08, STEEL, "%sRun" % label)
		_rail_cap(body, run[0], 0.08, label)
		_rail_cap(body, run[-1], 0.08, label)


static func _dock_polygons() -> Array[PackedVector2Array]:
	var polygons: Array[PackedVector2Array] = []
	for entry in FireCalderaPlan.PLOTS:
		if str(entry.get("site", "ground")) != "highline":
			continue
		var half: Vector2 = (entry[SocketPlinth.size_key(entry)] as Vector2) * 0.5 + Vector2.ONE * SocketPlinth.REVEAL
		var deep := FireCalderaPlan.facing(entry)
		var across := Vector2(-deep.y, deep.x)
		var outline := SocketPlinth._loop(entry["centre"], across, deep, half, 0.0)
		var polygon := PackedVector2Array()
		for point: Vector3 in outline:
			polygon.append(Vector2(point.x, point.z))
		# SocketPlinth._loop() is parameterized in its local across/deep frame.
		# That frame is reflected in plan (determinant -1), so the resulting
		# polygon is clockwise. _subtract_convex() clips against CCW half-planes;
		# without normalizing here, its “outside” fragments are computed on the
		# wrong side and the Highline deck remains over the private porch.
		if Geometry2D.is_polygon_clockwise(polygon):
			polygon.reverse()
		polygons.append(polygon)
	return polygons


static func _inside_any_dock(point: Vector2, polygons: Array[PackedVector2Array]) -> bool:
	for polygon in polygons:
		if Geometry2D.is_point_in_polygon(point, polygon):
			return true
	return false


## Clip each triangle of the annular dock strip against the actual convex
## terrace outlines. This yields a shaped seam instead of deleting an angular
## wedge of deck that only approximates the building footprint.
static func _emit_quad_outside_docks(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3, docks: Array[PackedVector2Array]) -> void:
	_emit_triangle_outside_docks(st, faces, a, b, c, normal, docks)
	_emit_triangle_outside_docks(st, faces, a, c, d, normal, docks)


static func _emit_dock_cut_walls(st: SurfaceTool, faces: PackedVector3Array, docks: Array[PackedVector2Array], inner: float, outer: float, top: float, bottom: float) -> void:
	for dock in docks:
		for i in dock.size():
			var a := dock[i]
			var b := dock[(i + 1) % dock.size()]
			var delta := b - a
			var qa := delta.dot(delta)
			var qb := 2.0 * a.dot(delta)
			var cuts: Array[float] = [0.0, 1.0]
			for radius: float in [inner, outer]:
				var qc := a.dot(a) - radius * radius
				var discriminant := qb * qb - 4.0 * qa * qc
				if discriminant < 0.0:
					continue
				var root := sqrt(discriminant)
				for t in [(-qb - root) / (2.0 * qa), (-qb + root) / (2.0 * qa)]:
					if t > 0.00001 and t < 0.99999:
						cuts.append(t)
			cuts.sort()
			for cut in cuts.size() - 1:
				var t0: float = cuts[cut]
				var t1: float = cuts[cut + 1]
				var midpoint := a.lerp(b, (t0 + t1) * 0.5)
				if midpoint.length() < inner - 0.0001 or midpoint.length() > outer + 0.0001:
					continue
				var p0 := a.lerp(b, t0)
				var p1 := a.lerp(b, t1)
				var outward := Vector3(delta.y, 0.0, -delta.x).normalized()
				_quad(st, faces,
					Vector3(p0.x, top, p0.y), Vector3(p1.x, top, p1.y),
					Vector3(p1.x, bottom, p1.y), Vector3(p0.x, bottom, p0.y), outward)


static func _emit_triangle_outside_docks(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, docks: Array[PackedVector2Array]) -> void:
	var fragments: Array[PackedVector2Array] = [PackedVector2Array([Vector2(a.x, a.z), Vector2(b.x, b.z), Vector2(c.x, c.z)])]
	for dock in docks:
		var next_fragments: Array[PackedVector2Array] = []
		for fragment in fragments:
			next_fragments.append_array(_subtract_convex(fragment, dock))
		fragments = next_fragments
	var y := a.y
	for fragment in fragments:
		if fragment.size() < 3:
			continue
		for i in range(1, fragment.size() - 1):
			var p0 := Vector3(fragment[0].x, y, fragment[0].y)
			var p1 := Vector3(fragment[i].x, y, fragment[i].y)
			var p2 := Vector3(fragment[i + 1].x, y, fragment[i + 1].y)
			st.set_normal(normal)
			st.add_vertex(p0)
			st.set_normal(normal)
			st.add_vertex(p1)
			st.set_normal(normal)
			st.add_vertex(p2)
			faces.append_array([p0, p1, p2])


static func _subtract_convex(subject: PackedVector2Array, clip: PackedVector2Array) -> Array[PackedVector2Array]:
	var outside: Array[PackedVector2Array] = []
	var remainder := subject
	for i in clip.size():
		if remainder.size() < 3:
			break
		var a := clip[i]
		var b := clip[(i + 1) % clip.size()]
		var out_piece := _clip_half_plane(remainder, a, b, false)
		if out_piece.size() >= 3:
			outside.append(out_piece)
		remainder = _clip_half_plane(remainder, a, b, true)
	return outside


static func _clip_half_plane(polygon: PackedVector2Array, a: Vector2, b: Vector2, keep_inside: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon.is_empty():
		return result
	var edge := b - a
	var previous := polygon[-1]
	var previous_distance := edge.cross(previous - a)
	var previous_inside := previous_distance >= -0.00001 if keep_inside else previous_distance <= 0.00001
	for current in polygon:
		var current_distance := edge.cross(current - a)
		var current_inside := current_distance >= -0.00001 if keep_inside else current_distance <= 0.00001
		if current_inside != previous_inside:
			var t := previous_distance / (previous_distance - current_distance)
			result.append(previous.lerp(current, t))
		if current_inside:
			result.append(current)
		previous = current
		previous_distance = current_distance
		previous_inside = current_inside
	return result


static func _is_dock_angle(angle: float) -> bool:
	# The deck guard opens only where the outer ring line lies within a
	# highline site's actual shaped terrace boundary.
	var point := Vector2(cos(angle), sin(angle)) * (FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5)
	return _inside_any_dock(point, _dock_polygons())


static func _is_connection_angle(angle: float, radius: float) -> bool:
	var inner := FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var outer := FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var openings: Array[Array] = []
	if is_equal_approx(radius, inner):
		for side: float in [-1.0, 1.0]:
			openings.append([FireCalderaPlan.renewal_byway(side)[0], 3.2])
		# Oren's public link approaches from the ring and reaches a separate
		# roof-terrace edge. Its threshold cuts the inner guard only.
		openings.append([_ring_crossing(FireCalderaPlan.oren_terrace_link(), inner), 2.4])
	elif is_equal_approx(radius, outer):
		openings.append([_ring_crossing(FireCalderaPlan.arrival_byway(), outer), 3.8])
		# Kel's sawtooth remains independent of the Highline.
	for opening in openings:
		var point: Vector2 = opening[0]
		var half_angle := asin(clampf(float(opening[1]) * 0.5 / radius, 0.0, 0.99))
		if absf(wrapf(angle - point.angle(), -PI, PI)) <= half_angle:
			return true
	return false

static func _guard_pane(body: StaticBody3D, a: Vector3, b: Vector3) -> void:
	var delta := b - a
	var length := delta.length()
	var pane := BoxMesh.new()
	pane.size = Vector3(length, GUARD_HEIGHT, 0.035)
	var instance := MeshInstance3D.new()
	instance.name = "HighlineGuardGlass"
	instance.mesh = pane
	instance.material_override = SolidModel.material(GUARD_GLASS, 0.12, 0.02)
	var x_axis := delta.normalized()
	var z_axis := x_axis.cross(Vector3.UP).normalized()
	instance.transform = Transform3D(Basis(x_axis, Vector3.UP, z_axis), (a + b) * 0.5 + Vector3.UP * (GUARD_HEIGHT * 0.5 + 0.05))
	body.add_child(instance)
	CollisionPolicy.add_box(body, instance, pane.size, instance.position, instance.basis, false)


## The inn branch is fabricated from the arrival gallery's measured side edge.
## Both ribbons and both pairs of handrail ends reuse those exact sampled
## points, so the parent ramp defines the branch base and the guard opening.
static func _build_gate_hotel_junction(body: StaticBody3D) -> void:
	var arrival_plan := FireCalderaPlan.arrival_byway()
	var arrival := PackedVector3Array()
	var start_y := FireCalderaGround.crater_wall(arrival_plan[0]) + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE
	var ground_y := FireCalderaGround.height(arrival_plan[0])
	for i in arrival_plan.size():
		var t := float(i) / float(arrival_plan.size() - 1)
		var y := ground_y if i == 0 else lerpf(start_y, FireCalderaPlan.HIGHLINE_DATUM, FireCalderaPlan.route_height_t("H0", t))
		if t < 0.08 and i > 0:
			y = lerpf(ground_y, start_y, smoothstep(0.0, 0.08, t))
		arrival.append(Vector3(arrival_plan[i].x, y, arrival_plan[i].y))
	var parent_edges := _path_edges(arrival, 3.8)
	var target := FireCalderaPlan.guest_gate_link()[0]
	var station := _nearest_path_station(arrival, target)
	var frame := FireCalderaPlan.closest_point_and_tangent(target, arrival_plan)
	var frame_centre: Vector2 = frame["point"]
	var frame_tangent: Vector2 = frame["tangent"]
	var frame_across := Vector2(frame_tangent.y, -frame_tangent.x)
	var side := 1 if (target - frame_centre).dot(frame_across) >= 0.0 else -1
	var parent_edge: PackedVector3Array = parent_edges[0] if side == 1 else parent_edges[1]
	# Size the parent opening to the child's full clear width. Using only the
	# adjacent samples made a narrow notch under a 3 m branch, so the branch
	# triangulation flared across the parent deck and its edge members crossed.
	var join_start := station
	var join_end := station
	var start_span := 0.0
	var end_span := 0.0
	while join_start > 0 and start_span < 1.5:
		start_span += parent_edge[join_start].distance_to(parent_edge[join_start - 1])
		join_start -= 1
	while join_end < parent_edge.size() - 1 and end_span < 1.5:
		end_span += parent_edge[join_end].distance_to(parent_edge[join_end + 1])
		join_end += 1
	var parent_outward := frame_across * float(side)
	var shared_edge_centre := (parent_edge[join_start] + parent_edge[join_end]) * 0.5
	# The branch centreline sits half its own width beyond the parent's side
	# edge. Its near edge therefore lands on the exact sampled parent boundary;
	# starting at the parent centreline made the two floors cross over each other.
	var branch_centre := shared_edge_centre + Vector3(parent_outward.x, 0.0, parent_outward.y) * 1.5
	var branch_plan := FireCalderaPlan.guest_gate_link()
	var plan_start := branch_plan[0]
	var plan_delta := Vector2(branch_centre.x, branch_centre.z) - plan_start
	for i in branch_plan.size() - 1:
		var correction := 1.0 - float(i) / float(branch_plan.size() - 2)
		branch_plan[i] += plan_delta * correction
	# At the shared edge, leave square to the parent centerline before easing
	# toward the hotel's own landing. With the corrected edge-offset start this
	# makes the floor seam and both railing pairs meet without crossing.
	var connector_length := branch_plan[0].distance_to(branch_plan[1])
	branch_plan[1] = branch_plan[0] + parent_outward * connector_length
	# The first bay leaves the gate ribbon squarely from its sampled outer edge.
	# Without this short normal landing, the first angled hotel panel can sweep
	# back over the parent deck, layering two translucent floors at the seam.
	var join_left := parent_edge[join_start]
	var join_right := parent_edge[join_end]
	var left_index := join_start
	var right_index := join_end
	var branch_direction := Vector3(branch_plan[1].x - branch_plan[0].x, 0.0, branch_plan[1].y - branch_plan[0].y).normalized()
	var branch_across := Vector3.UP.cross(branch_direction).normalized()
	if (join_right - join_left).dot(branch_across) < 0.0:
		var swap := join_left
		join_left = join_right
		join_right = swap
		var index_swap := left_index
		left_index = right_index
		right_index = index_swap
	var left_rail := join_left + Vector3.UP * GUARD_TOP
	var right_rail := join_right + Vector3.UP * GUARD_TOP
	var join_left_pipe := join_left - Vector3(parent_outward.x, 0.0, parent_outward.y) * 0.12 + Vector3.UP * (-DECK_THICKNESS + 0.05)
	var join_right_pipe := join_right - Vector3(parent_outward.x, 0.0, parent_outward.y) * 0.12 + Vector3.UP * (-DECK_THICKNESS + 0.05)
	# The gate ribbon terminates on the exact outer Highline arc. A straight
	# transverse cap misses the circle by a small but visible chord at each end.
	var ring_outer := FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5
	var end_angle := arrival_plan[-1].angle()
	var end_half_angle := asin(3.8 * 0.5 / ring_outer)
	var end_left := Vector3(cos(end_angle + end_half_angle) * ring_outer, arrival[-1].y, sin(end_angle + end_half_angle) * ring_outer)
	var end_right := Vector3(cos(end_angle - end_half_angle) * ring_outer, arrival[-1].y, sin(end_angle - end_half_angle) * ring_outer)
	var pipe_radius := ring_outer - 0.12
	var pipe_half_angle := asin(3.8 * 0.5 / pipe_radius)
	var pipe_y := arrival[-1].y - DECK_THICKNESS + 0.05
	var end_left_pipe := Vector3(cos(end_angle + pipe_half_angle) * pipe_radius, pipe_y, sin(end_angle + pipe_half_angle) * pipe_radius)
	var end_right_pipe := Vector3(cos(end_angle - pipe_half_angle) * pipe_radius, pipe_y, sin(end_angle - pipe_half_angle) * pipe_radius)
	var branch := {
		"point": branch_centre,
		"side": side,
		"width": 3.0,
		"station": station,
		"join_left": join_left,
		"join_right": join_right,
		"join_left_rail": left_rail,
		"join_right_rail": right_rail,
		"join_left_pipe": join_left_pipe,
		"join_right_pipe": join_right_pipe,
		"end_left": end_left,
		"end_right": end_right,
		"end_left_pipe": end_left_pipe,
		"end_right_pipe": end_right_pipe,
		"join_start_index": mini(left_index, right_index),
		"join_end_index": maxi(left_index, right_index),
		"parent_open": true,
	}
	_build_glass_path(body, arrival, 3.8, "ArrivalByway", "glass", branch)
	var branch_points := PackedVector3Array()
	for i in branch_plan.size():
		var t := float(i) / float(branch_plan.size() - 1)
		var y := lerpf(branch_centre.y, FireCalderaPlan.GUEST_GATE_DATUM, FireCalderaPlan.route_height_t("HG", t))
		branch_points.append(Vector3(branch_plan[i].x, y, branch_plan[i].y))
	branch_points[0] = branch_centre
	var branch_join := {"join_left": join_left, "join_right": join_right, "join_left_rail": left_rail, "join_right_rail": right_rail,
		"join_left_pipe": join_left_pipe, "join_right_pipe": join_right_pipe}
	_build_glass_path(body, branch_points, 3.0, "GuestGateLink", "glass", branch_join)


static func _nearest_path_station(points: PackedVector3Array, target: Vector2) -> int:
	var best := 0
	var distance := INF
	for i in points.size():
		var candidate := Vector2(points[i].x, points[i].z).distance_squared_to(target)
		if candidate < distance:
			distance = candidate
			best = i
	return best


static func _path_normals(points: PackedVector3Array) -> PackedVector3Array:
	var normals := PackedVector3Array()
	for i in points.size():
		var tangent := (points[1] - points[0]).normalized() if i == 0 else ((points[-1] - points[-2]).normalized() if i == points.size() - 1 else (points[i + 1] - points[i - 1]).normalized())
		var across := Vector3.UP.cross(Vector3(tangent.x, 0.0, tangent.z).normalized()).normalized()
		var normal := tangent.cross(across).normalized()
		normals.append(-normal if normal.y < 0.0 else normal)
	return normals


static func _path_edges(points: PackedVector3Array, width: float) -> Array[PackedVector3Array]:
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	for i in points.size():
		var tangent := (points[1] - points[0]).normalized() if i == 0 else ((points[-1] - points[-2]).normalized() if i == points.size() - 1 else (points[i + 1] - points[i - 1]).normalized())
		var across := Vector3.UP.cross(Vector3(tangent.x, 0.0, tangent.z).normalized()).normalized()
		left.append(points[i] + across * width * 0.5)
		right.append(points[i] - across * width * 0.5)
	return [left, right]


## Renewal is public infrastructure, so its descent belongs to the Highline.
## Two curved galleries leave opposite ring sectors and land on the actual
## flanks of the public deck. Neither route is a disguised rear entrance.
static func _build_renewal_descent(body: StaticBody3D) -> void:
	var entry := FireCalderaPlan.plot("RENEWAL")
	var finish_y := float(FireCalderaGround.survey(entry)["datum"])
	for side: float in [-1.0, 1.0]:
		var plan := FireCalderaPlan.renewal_byway(side)
		var cumulative := PackedFloat32Array()
		cumulative.resize(plan.size())
		for i in range(1, plan.size()):
			cumulative[i] = cumulative[i - 1] + plan[i - 1].distance_to(plan[i])
		var total_run := maxf(cumulative[-1], 0.001)
		var points := PackedVector3Array()
		for i in plan.size():
			var t := cumulative[i] / total_run
			var profile := FireCalderaPlan.route_height_t("H2W" if side < 0.0 else "H2E", t)
			# A shallow 3.5 m crown clears the inner bowl ridge while keeping both
			# endpoints exactly level with the Highline and Renewal deck.
			var crown := 3.5 * sin(PI * t)
			points.append(Vector3(plan[i].x, lerpf(FireCalderaPlan.HIGHLINE_DATUM, finish_y, profile) + crown, plan[i].y))
		var inner := FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5
		var centre := plan[0]
		var tangent := (plan[1] - plan[0]).normalized()
		var across := Vector2(tangent.y, -tangent.x)
		var deck_pair := _ring_arc_pair(centre, inner, 3.2, across, FireCalderaPlan.HIGHLINE_DATUM)
		var low_pair := _ring_arc_pair(centre, inner + 0.12, 3.2, across, FireCalderaPlan.HIGHLINE_DATUM - DECK_THICKNESS + 0.05)
		var junction := {
			"join_left": deck_pair[0], "join_right": deck_pair[1],
			"join_left_rail": deck_pair[0] + Vector3.UP * GUARD_TOP,
			"join_right_rail": deck_pair[1] + Vector3.UP * GUARD_TOP,
			"join_left_pipe": low_pair[0], "join_right_pipe": low_pair[1],
		}
		_build_glass_path(body, points, 3.2, "RenewalWest" if side < 0.0 else "RenewalEast", "glass", junction)


static func _ring_arc_pair(centre: Vector2, radius: float, width: float, across: Vector2, y: float) -> Array[Vector3]:
	var half_angle := asin(clampf(width * 0.5 / radius, 0.0, 0.99))
	var angle := centre.angle()
	var candidates := [
		Vector3(cos(angle + half_angle) * radius, y, sin(angle + half_angle) * radius),
		Vector3(cos(angle - half_angle) * radius, y, sin(angle - half_angle) * radius),
	]
	var offset0 := Vector2(candidates[0].x - centre.x, candidates[0].z - centre.y)
	var offset1 := Vector2(candidates[1].x - centre.x, candidates[1].z - centre.y)
	return candidates if offset0.dot(across) >= offset1.dot(across) else [candidates[1], candidates[0]]


static func _build_oren_terrace_link(body: StaticBody3D) -> void:
	var entry := FireCalderaPlan.plot("OREN")
	var line := FireCalderaGround.survey(entry)
	var finish_y := float(line["datum"]) + FireCalderaOren.UPPER + FireCalderaOren.roof_top()
	var points := PackedVector3Array()
	var plan := FireCalderaPlan.oren_terrace_link()
	var cumulative := PackedFloat32Array()
	cumulative.resize(plan.size())
	for i in range(1, plan.size()):
		cumulative[i] = cumulative[i - 1] + plan[i - 1].distance_to(plan[i])
	var total_run := maxf(cumulative[-1], 0.001)
	for i in plan.size():
		# Grading follows actual plan distance, not sample index: the spiral's
		# changing curvature must never turn its final approach into a sudden drop.
		var t := cumulative[i] / total_run
		points.append(Vector3(plan[i].x, lerpf(FireCalderaPlan.HIGHLINE_DATUM, finish_y, FireCalderaPlan.route_height_t("H4", t)), plan[i].y))
	_build_glass_path(body, points, 2.4, "OrenTerraceLink")


## The lava-edge promenade and the rear service walk are the ground-level half
## of the public system. The promenade is level at its civic datum; the rear
## service walk follows surveyed terrain. Only the lava-facing edge of the
## promenade needs a guard.
static func _build_ground_network(body: StaticBody3D) -> void:
	var routes := FireCalderaPlan.routes()
	var promenade_branches: Array[Dictionary] = []
	var service_branches: Array[Dictionary] = []
	for route: Dictionary in routes:
		var id := str(route["id"])
		if id.begins_with("P_"):
			promenade_branches.append(route)
		elif id.begins_with("S_"):
			service_branches.append(route)
	_build_ground_loop(body, FireCalderaPlan.ground_promenade(), 3.5,
		"LavaEdgePromenade", GLASS, false, FireCalderaPlan.GROUND_PROMENADE_DATUM, promenade_branches)
	_build_ground_loop(body, FireCalderaPlan.undercroft_loop(), 3.2, "GroundServiceWalk", PLATFORM_COMPOSITE, false, -1.0, service_branches)
	for route: Dictionary in routes:
		var id := str(route["id"])
		if not id.begins_with("P_") and not id.begins_with("S_"):
			continue
		var plot_id := id.substr(2)
		if plot_id == "RENEWAL":
			continue # Renewal already has two independent public deck landings.
		var entry := FireCalderaPlan.plot(plot_id)
		var line := FireCalderaGround.survey(entry)
		var target_y := float(line["datum"])
		if id == "S_OREN":
			target_y += 1.35
		elif id == "S_KEL":
			target_y += FireCalderaKel.DOCK
		var source_y := FireCalderaPlan.GROUND_PROMENADE_DATUM + 0.035 if id.begins_with("P_") else NAN
		var points := _graded_threshold_points(route["points"], target_y, source_y)
		# Ground-house receiving and front thresholds are compact metal access
		# ramps. Their edge tubes do the work of a low curb; tall glass guards
		# would be out of scale beside a door and visually double the porch rail.
		var parent_loop: PackedVector2Array = FireCalderaPlan.ground_promenade() if id.begins_with("P_") else FireCalderaPlan.undercroft_loop()
		var junction := _ground_branch_junction(points, parent_loop, float(route["width"]))
		_build_glass_path(body, points, float(route["width"]), "%sThreshold" % id, "metal", junction)


static func _graded_threshold_points(plan: PackedVector2Array, target_y: float, source_y: float = NAN) -> PackedVector3Array:
	var result := PackedVector3Array()
	if plan.size() < 2:
		return result
	var total_length := 0.0
	for i in plan.size() - 1:
		total_length += plan[i].distance_to(plan[i + 1])
	var samples := maxi(18, ceili(total_length * 1.4))
	for i in samples + 1:
		var t := float(i) / float(samples)
		var distance := total_length * t
		var segment_index := 0
		while segment_index < plan.size() - 2 and distance > plan[segment_index].distance_to(plan[segment_index + 1]):
			distance -= plan[segment_index].distance_to(plan[segment_index + 1])
			segment_index += 1
		var segment_length := plan[segment_index].distance_to(plan[segment_index + 1])
		var segment_t := clampf(distance / maxf(segment_length, 0.001), 0.0, 1.0)
		var p := plan[segment_index].lerp(plan[segment_index + 1], segment_t)
		# The loop cassette's top edge is +3.5 cm above datum. Start the child
		# surface on that same point so its bottom rail also shares one Z datum.
		var terrain_y := FireCalderaGround.height(p) + 0.035
		var y := lerpf(terrain_y, target_y, smoothstep(0.68, 1.0, t))
		if is_finite(source_y):
			y = lerpf(source_y, target_y, smoothstep(0.0, 1.0, t))
		if i == samples:
			y = target_y
		result.append(Vector3(p.x, y, p.y))
	return result


## Child edge tubes start on the parent loop's edge pipe, inset to its underside
## datum. This makes the ramp mouth share its actual parent stations rather than
## projecting two new endpoints perpendicular from an unrelated centre point.
static func _ground_branch_junction(points: PackedVector3Array, parent: PackedVector2Array, child_width: float) -> Dictionary:
	if points.size() < 2:
		return {}
	var start := Vector2(points[0].x, points[0].z)
	var frame := FireCalderaPlan.closest_point_and_tangent(start, parent)
	var parent_centre: Vector2 = frame["point"]
	var outward := (start - parent_centre).normalized()
	var tangent := (points[1] - points[0]).normalized()
	var across := Vector3.UP.cross(tangent).normalized()
	var pipe_y := points[0].y - DECK_THICKNESS + 0.05
	var half := child_width * 0.5 - 0.12
	var inset := Vector3(outward.x, 0.0, outward.y) * 0.12
	var origin := Vector3(points[0].x, pipe_y, points[0].z) - inset
	return {
		"join_left_pipe": origin + across * half,
		"join_right_pipe": origin - across * half,
	}


static func _build_ground_loop(body: StaticBody3D, plan: PackedVector2Array, width: float, label: String, colour: Color, lava_edge_guard: bool, level_y: float = -1.0, branches: Array[Dictionary] = []) -> void:
	if plan.size() < 3:
		return
	var renewal := FireCalderaPlan.plot("RENEWAL")
	var renewal_foundation := _renewal_platform_outline(renewal, RENEWAL_DECK_HALF, RENEWAL_DECK_EXPONENT)
	if Geometry2D.is_polygon_clockwise(renewal_foundation):
		renewal_foundation.reverse()
	var renewal_datum := float(FireCalderaGround.survey(renewal)["datum"])
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	var left_bottom := PackedVector3Array()
	var right_bottom := PackedVector3Array()
	var exclusions: Array[PackedVector2Array] = [renewal_foundation]
	for i in plan.size():
		var tangent := (plan[mini(i + 1, plan.size() - 1)] - plan[maxi(i - 1, 0)]).normalized()
		var across := Vector2(-tangent.y, tangent.x) * width * 0.5
		var left_plan := plan[i] + across
		var right_plan := plan[i] - across
		var left_y := level_y
		var right_y := level_y
		if level_y < 0.0:
			left_y = renewal_datum if Geometry2D.is_point_in_polygon(left_plan, renewal_foundation) else maxf(FireCalderaGround.height(left_plan), FireCalderaGround.LAVA_Y + 0.2)
			right_y = renewal_datum if Geometry2D.is_point_in_polygon(right_plan, renewal_foundation) else maxf(FireCalderaGround.height(right_plan), FireCalderaGround.LAVA_Y + 0.2)
		left.append(Vector3(left_plan.x, left_y + 0.035, left_plan.y))
		right.append(Vector3(right_plan.x, right_y + 0.035, right_plan.y))
		left_bottom.append(left[-1] - Vector3.UP * DECK_THICKNESS)
		right_bottom.append(right[-1] - Vector3.UP * DECK_THICKNESS)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in plan.size() - 1:
		var midpoint := plan[i].lerp(plan[i + 1], 0.5)
		if is_equal_approx(left[i].y, right[i].y) and is_equal_approx(left[i].y, left[i + 1].y) and is_equal_approx(left[i].y, right[i + 1].y):
			# The level public promenade is cut against the exact terrace polygon,
			# so no coarse loop sample leaves a triangular overlap at its edge.
			_emit_quad_outside_docks(st, faces, right[i], left[i], left[i + 1], right[i + 1], Vector3.UP, exclusions)
			_emit_quad_outside_docks(st, faces, right_bottom[i + 1], left_bottom[i + 1], left_bottom[i], right_bottom[i], Vector3.DOWN, exclusions)
			_emit_loop_edge_wall(st, faces, left[i], left[i + 1], left_bottom[i], left_bottom[i + 1], Vector3.LEFT, renewal_foundation)
			_emit_loop_edge_wall(st, faces, right[i + 1], right[i], right_bottom[i + 1], right_bottom[i], Vector3.RIGHT, renewal_foundation)
		elif not Geometry2D.is_point_in_polygon(midpoint, renewal_foundation):
			# Terrain-following service strips use the surveyed Renewal datum inside
			# the platform and omit any segment wholly owned by its walkable slab.
			_quad(st, faces, right[i], left[i], left[i + 1], right[i + 1], Vector3.UP)
			_quad(st, faces, right_bottom[i + 1], left_bottom[i + 1], left_bottom[i], right_bottom[i], Vector3.DOWN)
			_quad(st, faces, left[i], left_bottom[i], left_bottom[i + 1], left[i + 1], Vector3.LEFT)
			_quad(st, faces, right[i + 1], right_bottom[i + 1], right_bottom[i], right[i], Vector3.RIGHT)
	var mesh := MeshInstance3D.new()
	mesh.name = "%sDeck" % label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(colour, 0.20 if lava_edge_guard else 0.68, 0.06)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.name = "%sWalkableSurface" % label
	collider.shape = shape
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collider)
	# Both edges use the same continuous alloy piping as the upper Highline.
	# Carry it uninterrupted across the Renewal deck: that slab is the bridge
	# surface for this promenade, so the rim joins the platform instead of
	# stopping short at an artificial rectangular cutout.
	for side: int in [-1, 1]:
		var edge_points: PackedVector3Array = left if side == 1 else right
		_build_loop_edge_pipe(body, edge_points, plan, width, side, renewal_foundation, branches, "%s%sEdgePipe" % [label, "Left" if side == 1 else "Right"])
	if lava_edge_guard:
		var hazard_edge := PackedVector3Array()
		for i in left.size():
			var left_radius := Vector2(left[i].x, left[i].z).length()
			var right_radius := Vector2(right[i].x, right[i].z).length()
			hazard_edge.append(left[i] if left_radius < right_radius else right[i])
		var rail := PackedVector3Array()
		for point in hazard_edge:
			rail.append(point + Vector3.UP * 1.08)
		_tube(body, rail, 0.075, STEEL, "%sLavaRail" % label)
		for i in hazard_edge.size() - 1:
			_path_guard(body, hazard_edge[i], hazard_edge[i + 1], Vector3.UP)


## Split a lower-loop edge member at the exact Renewal platform boundary. The
## platform owns the shared portion of the walking surface, so the loop rim
## must terminate at its perimeter instead of crossing the terrace.
static func _renewal_platform_outline(entry: Dictionary, half: Vector2, exponent: float) -> PackedVector2Array:
	var outline := PackedVector2Array()
	for i in 192:
		var angle := TAU * float(i) / 192.0
		var c := cos(angle)
		var s := sin(angle)
		var local := Vector2(signf(c) * pow(absf(c), 2.0 / exponent) * half.x, signf(s) * pow(absf(s), 2.0 / exponent) * half.y)
		outline.append(FireCalderaPlan.shell_to_plan(entry, local))
	if Geometry2D.is_polygon_clockwise(outline):
		outline.reverse()
	return outline


static func _build_loop_edge_pipe(body: StaticBody3D, edge: PackedVector3Array, plan: PackedVector2Array, width: float, side: int, platform: PackedVector2Array, branches: Array[Dictionary], label: String) -> void:
	var run := PackedVector3Array()
	for i in edge.size() - 1:
		var a := Vector2(edge[i].x, edge[i].z)
		var b := Vector2(edge[i + 1].x, edge[i + 1].z)
		var cuts: Array[float] = [0.0, 1.0]
		for j in platform.size():
			var hit = Geometry2D.segment_intersects_segment(a, b, platform[j], platform[(j + 1) % platform.size()])
			if hit is Vector2:
				cuts.append(clampf(a.distance_to(hit) / maxf(a.distance_to(b), 0.0001), 0.0, 1.0))
		cuts.sort()
		for j in range(cuts.size() - 1):
			var t0 := cuts[j]
			var t1 := cuts[j + 1]
			var midpoint := a.lerp(b, (t0 + t1) * 0.5)
			if Geometry2D.is_point_in_polygon(midpoint, platform) or _loop_branch_opens_pipe(midpoint, plan, width, side, branches):
				if run.size() >= 2:
					_tube(body, run, 0.07, STEEL, label)
				run = PackedVector3Array()
				continue
			var p0 := _lower_loop_pipe_point(edge[i].lerp(edge[i + 1], t0), plan, i, side, width)
			var p1 := _lower_loop_pipe_point(edge[i].lerp(edge[i + 1], t1), plan, i, side, width)
			if run.is_empty():
				run.append(p0)
			elif run[-1].distance_to(p0) > 0.015:
				if run.size() >= 2:
					_tube(body, run, 0.07, STEEL, label)
				run = PackedVector3Array([p0])
			run.append(p1)
	if run.size() >= 2:
		_tube(body, run, 0.07, STEEL, label)


static func _lower_loop_pipe_point(point: Vector3, plan: PackedVector2Array, index: int, side: int, width: float) -> Vector3:
	var centre := plan[index]
	var tangent := (plan[mini(index + 1, plan.size() - 1)] - plan[maxi(index - 1, 0)]).normalized()
	var across := Vector2(-tangent.y, tangent.x) * float(side)
	var plan_point := Vector2(point.x, point.z) - across * 0.12
	return Vector3(plan_point.x, point.y - DECK_THICKNESS + 0.05, plan_point.y)


static func _loop_branch_opens_pipe(midpoint: Vector2, loop: PackedVector2Array, parent_width: float, edge_side: int, branches: Array[Dictionary]) -> bool:
	for branch in branches:
		var points: PackedVector2Array = branch.get("points", PackedVector2Array())
		if points.size() < 2:
			continue
		var frame := FireCalderaPlan.closest_point_and_tangent(points[0], loop)
		var parent: Vector2 = frame["point"]
		var tangent: Vector2 = frame["tangent"]
		var across := Vector2(-tangent.y, tangent.x)
		var side := 1 if (points[0] - parent).dot(across) >= 0.0 else -1
		if side != edge_side:
			continue
		var delta := midpoint - parent
		if absf(delta.dot(across) - float(side) * (parent_width * 0.5 - 0.12)) < 0.55 and absf(delta.dot(tangent)) < float(branch.get("width", 2.6)) * 0.5 + 0.25:
			return true
	return false


static func _emit_loop_edge_wall(st: SurfaceTool, faces: PackedVector3Array, top_a: Vector3, top_b: Vector3, bottom_a: Vector3, bottom_b: Vector3, normal: Vector3, platform: PackedVector2Array) -> void:
	var a := Vector2(top_a.x, top_a.z)
	var b := Vector2(top_b.x, top_b.z)
	var cuts: Array[float] = [0.0, 1.0]
	for i in platform.size():
		var hit = Geometry2D.segment_intersects_segment(a, b, platform[i], platform[(i + 1) % platform.size()])
		if hit is Vector2:
			cuts.append(clampf(a.distance_to(hit) / maxf(a.distance_to(b), 0.0001), 0.0, 1.0))
	cuts.sort()
	for i in range(cuts.size() - 1):
		var t0 := cuts[i]
		var t1 := cuts[i + 1]
		if Geometry2D.is_point_in_polygon(a.lerp(b, (t0 + t1) * 0.5), platform):
			continue
		_quad(st, faces, top_a.lerp(top_b, t0), bottom_a.lerp(bottom_b, t0), bottom_a.lerp(bottom_b, t1), top_a.lerp(top_b, t1), normal)


static func _ring_crossing(plan: PackedVector2Array, radius: float) -> Vector2:
	for i in plan.size() - 1:
		var a := plan[i]
		var b := plan[i + 1]
		if (a.length() - radius) * (b.length() - radius) <= 0.0 and absf(a.length() - b.length()) > 0.0001:
			var t := clampf((radius - a.length()) / (b.length() - a.length()), 0.0, 1.0)
			return a.lerp(b, t)
	return plan[0]


static func _build_glass_path(body: StaticBody3D, points: PackedVector3Array, width: float, label: String, guard_style: String = "glass", branch: Dictionary = {}) -> void:
	if points.size() < 2:
		return
	var edges := _path_edges(points, width)
	var left: PackedVector3Array = edges[0]
	var right: PackedVector3Array = edges[1]
	var normals := _path_normals(points)
	if branch.has("join_left") and not branch.has("parent_open"):
		left[0] = branch["join_left"]
		right[0] = branch["join_right"]
	if branch.has("end_left") and branch.has("end_right"):
		left[-1] = branch["end_left"]
		right[-1] = branch["end_right"]
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
	mesh.name = "%s%sRibbon" % [label, "Metal" if guard_style == "metal" else "Glass"]
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(STEEL if guard_style == "metal" else GLASS, 0.38 if guard_style == "metal" else 0.18, 0.08)
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
	for i in points.size():
		var lower_offset := -DECK_THICKNESS + 0.05
		left_edge.append(left[i] - (left[i] - points[i]).normalized() * 0.12 + normals[i] * lower_offset)
		right_edge.append(right[i] - (right[i] - points[i]).normalized() * 0.12 + normals[i] * lower_offset)
	if branch.has("join_left_pipe") and not branch.has("parent_open"):
		left_edge[0] = branch["join_left_pipe"]
		right_edge[0] = branch["join_right_pipe"]
	if branch.has("end_left_pipe") and branch.has("end_right_pipe"):
		left_edge[-1] = branch["end_left_pipe"]
		right_edge[-1] = branch["end_right_pipe"]
	for side in [-1, 1]:
		var edge: PackedVector3Array = left_edge if side == 1 else right_edge
		var edge_run := PackedVector3Array()
		for i in edge.size():
			if i > 0 and _branch_opens_edge(points, i - 1, width, branch, side):
				if edge_run.size() >= 2:
					_tube(body, edge_run, 0.07, STEEL, "%s%sEdge" % [label, "Left" if side == 1 else "Right"])
				edge_run = PackedVector3Array()
			if edge_run.is_empty():
				edge_run.append(edge[i])
			else:
				edge_run.append(edge[i])
		if edge_run.size() >= 2:
			_tube(body, edge_run, 0.07, STEEL, "%s%sEdge" % [label, "Left" if side == 1 else "Right"])
	if guard_style == "glass":
		for side in [-1, 1]:
			var edge: PackedVector3Array = left if side == 1 else right
			var rail_run := PackedVector3Array()
			for i in points.size():
				var rail_point := edge[i] + Vector3.UP * GUARD_TOP
				if i == 0 and branch.has("join_left_rail") and not branch.has("parent_open"):
					rail_point = branch["join_left_rail"] if side == 1 else branch["join_right_rail"]
				if i > 0 and _branch_opens_edge(points, i - 1, width, branch, side):
					if rail_run.size() >= 2:
						_tube(body, rail_run, 0.08, STEEL, "%s%sTopRail" % [label, "Left" if side == 1 else "Right"])
					rail_run = PackedVector3Array()
					if branch.is_empty():
						_rail_cap(body, rail_point, 0.08, label)
				if rail_run.is_empty():
					rail_run.append(rail_point)
				else:
					rail_run.append(rail_point)
			if rail_run.size() >= 2:
				_tube(body, rail_run, 0.08, STEEL, "%s%sTopRail" % [label, "Left" if side == 1 else "Right"])
				_rail_cap(body, rail_run[0], 0.08, label)
				_rail_cap(body, rail_run[-1], 0.08, label)
		for side in [-1, 1]:
			var edge: PackedVector3Array = left if side == 1 else right
			var guard_start := -1
			for i in points.size() - 1:
				if _branch_opens_edge(points, i, width, branch, side):
					if guard_start >= 0 and i > guard_start:
						_path_guard_ribbon(body, points, edge, normals, guard_start, i, label)
					guard_start = -1
				elif guard_start < 0:
					guard_start = i
			if guard_start >= 0 and points.size() - 1 > guard_start:
				_path_guard_ribbon(body, points, edge, normals, guard_start, points.size() - 1, label)
	elif guard_style == "lip":
		for i in points.size() - 1:
			var normal := (normals[i] + normals[i + 1]).normalized()
			_path_lip(body, left[i], left[i + 1], normal, "%sLeftLip" % label)
			_path_lip(body, right[i + 1], right[i], normal, "%sRightLip" % label)


static func _branch_opens_edge(points: PackedVector3Array, segment: int, main_width: float, branch: Dictionary, edge_side: int) -> bool:
	if branch.is_empty() or not branch.has("point") or segment < 0 or segment >= points.size() - 1:
		return false
	if int(branch.get("side", 0)) != edge_side:
		return false
	if branch.has("join_start_index") and branch.has("join_end_index"):
		return segment >= int(branch["join_start_index"]) and segment < int(branch["join_end_index"])
	var a := points[segment]
	var b := points[segment + 1]
	var tangent := Vector3(b.x - a.x, 0.0, b.z - a.z).normalized()
	var across := Vector3.UP.cross(tangent).normalized()
	var branch_point: Vector3 = branch["point"]
	var delta := branch_point - (a + b) * 0.5
	var width := float(branch.get("width", 0.0))
	return absf(delta.dot(across) - float(edge_side) * main_width * 0.5) < 0.45 and absf(delta.dot(tangent)) < width * 0.5 + a.distance_to(b) * 0.5


static func _path_guard(body: StaticBody3D, a: Vector3, b: Vector3, normal: Vector3) -> void:
	var delta := b - a
	var length := delta.length()
	var x_axis := delta.normalized()
	var z_axis := x_axis.cross(normal).normalized()
	var pane := BoxMesh.new()
	pane.size = Vector3(length, GUARD_HEIGHT, 0.035)
	var visual := MeshInstance3D.new()
	visual.name = "BywayGuardGlass"
	visual.mesh = pane
	visual.material_override = SolidModel.material(GUARD_GLASS, 0.12, 0.02)
	visual.transform = Transform3D(Basis(x_axis, normal, z_axis), (a + b) * 0.5 + normal * (GUARD_HEIGHT * 0.5 + 0.05))
	body.add_child(visual)
	CollisionPolicy.add_box(body, visual, pane.size, visual.position, visual.basis, false)


## A balustrade is a continuous bent sheet between rail stations, not a row of
## individually boxed glass cassettes. The top rail remains a matching pipe.
static func _path_guard_ribbon(body: StaticBody3D, path: PackedVector3Array, edge: PackedVector3Array, normals: PackedVector3Array, first: int, last: int, label: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in range(first, last):
		var side_a := (path[i + 1] - path[i]).normalized().cross(Vector3.UP).normalized() * 0.018
		var side_b := side_a
		var low_a := edge[i] + Vector3.UP * 0.05
		var low_b := edge[i + 1] + Vector3.UP * 0.05
		var high_a := edge[i] + Vector3.UP * (GUARD_HEIGHT + 0.05)
		var high_b := edge[i + 1] + Vector3.UP * (GUARD_HEIGHT + 0.05)
		var front := PackedVector3Array([low_a + side_a, low_b + side_b, high_b + side_b, high_a + side_a])
		var back := PackedVector3Array([low_a - side_a, high_a - side_a, high_b - side_b, low_b - side_b])
		for quad in [front, back]:
			var face_normal: Vector3 = (quad[1] - quad[0]).cross(quad[2] - quad[0]).normalized()
			_quad(st, faces, quad[0], quad[1], quad[2], quad[3], face_normal)
	var visual := MeshInstance3D.new()
	visual.name = "%sGuardRibbon" % label
	visual.mesh = st.commit()
	var glass := SolidModel.material(GUARD_GLASS, 0.12, 0.02)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual.material_override = glass
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.name = "%sGuardRibbonCollision" % label
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)


## A small rounded terminal makes a deliberate balustrade stop at each
## junction instead of leaving a cut pipe end. The same metal is used for
## rails and their caps so the junction reads as one assembly.
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


static func _path_lip(body: StaticBody3D, a: Vector3, b: Vector3, normal: Vector3, label: String) -> void:
	var delta := b - a
	var x_axis := delta.normalized()
	var y_axis := normal.normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var box := BoxMesh.new()
	box.size = Vector3(delta.length(), 0.18, 0.14)
	var lip := MeshInstance3D.new()
	lip.name = label
	lip.mesh = box
	lip.material_override = SolidModel.material(REFRACTORY_EDGE, 0.72, 0.08)
	lip.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5 + y_axis * 0.09)
	body.add_child(lip)
	CollisionPolicy.add_box(body, lip, box.size, lip.position, lip.basis, false)


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
