class_name FireCalderaPlanWalks
extends RefCounted

## Shared renderer for the authored Fire Caldera walkway plans. Coordinates stay
## in FireCalderaPlan's local frame and are transformed by the containing frame
## exactly once. Flight profiles and guard rails are consumed verbatim.

const DECK := 0.22
const GLASS := Color(0.62, 0.82, 0.88, 0.20)
const RAIL := Color(0.15, 0.24, 0.42)
const GUARD := Color(0.62, 0.82, 0.88, 0.16)
const BASALT := Color(0.17, 0.16, 0.16)
const POST := Color(0.055, 0.065, 0.07)


static func build(parent: Node3D, levels: Array, flights: Array, label: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	for level: Dictionary in levels:
		if not bool(level.get("build", true)):
			continue
		_build_level(body, level)
	for flight: Dictionary in flights:
		_build_flight(body, flight)
	return body


static func _build_level(body: StaticBody3D, level: Dictionary) -> void:
	var datum := float(level["datum"])
	var material_name := str(level.get("material", "glass"))
	var surface_material := SolidModel.material(BASALT if material_name == "basalt" else GLASS, 0.0, 0.9 if material_name == "basalt" else 0.05)
	surface_material.cull_mode = BaseMaterial3D.CULL_BACK
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for region: Dictionary in level["surface"]:
		var polygon := _polygon_with_holes(region)
		if polygon.size() < 3:
			continue
		var indices := Geometry2D.triangulate_polygon(polygon)
		if indices.is_empty():
			push_error("FireCalderaPlanWalks: could not triangulate level %s" % level["id"])
			continue
		for i in range(0, indices.size(), 3):
			var a := _level_point(polygon[indices[i]], datum)
			var b := _level_point(polygon[indices[i + 1]], datum)
			var c := _level_point(polygon[indices[i + 2]], datum)
			if (b - a).cross(c - a).y < 0.0:
				var swap := b
				b = c
				c = swap
			st.set_normal(Vector3.UP)
			st.add_vertex(a)
			st.add_vertex(b)
			st.add_vertex(c)
			faces.append_array([a, b, c])
			var ab := a - Vector3.UP * DECK
			var bb := b - Vector3.UP * DECK
			var cb := c - Vector3.UP * DECK
			st.set_normal(Vector3.DOWN)
			st.add_vertex(cb)
			st.add_vertex(bb)
			st.add_vertex(ab)
			faces.append_array([cb, bb, ab])
		for raw_loop: Array in [region["outer"]] + region.get("holes", []):
			var loop := PackedVector2Array()
			for raw_point: Array in raw_loop:
				loop.append(Vector2(float(raw_point[0]), float(raw_point[1])))
			if loop.size() > 2 and loop[0].is_equal_approx(loop[-1]):
				loop.remove_at(loop.size() - 1)
			for i in loop.size():
				var p0 := loop[i]
				var p1 := loop[(i + 1) % loop.size()]
				var a := Vector3(p0.x, datum, p0.y)
				var b := Vector3(p1.x, datum, p1.y)
				var ab := a - Vector3.UP * DECK
				var bb := b - Vector3.UP * DECK
				var n := (b - a).cross(ab - a).normalized()
				st.set_normal(n); st.add_vertex(a)
				st.set_normal(n); st.add_vertex(ab)
				st.set_normal(n); st.add_vertex(bb)
				st.set_normal(n); st.add_vertex(a)
				st.set_normal(n); st.add_vertex(bb)
				st.set_normal(n); st.add_vertex(b)
				faces.append_array([a, ab, bb, a, bb, b])
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "%sFloor" % level["id"]
	mesh_node.mesh = st.commit()
	mesh_node.material_override = surface_material
	mesh_node.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(mesh_node)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = "%sFloorCollision" % level["id"]
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)
	for guard_line: Array in level.get("guards", []):
		var points := PackedVector3Array()
		for raw: Array in guard_line:
			points.append(Vector3(float(raw[0]), datum + 1.09, float(raw[1])))
		_build_guard(body, points, "%sLevelGuard" % level["id"])
		# The glass cassette edge gets an opaque blued-steel cap around every
		# authored outer and hole boundary.
	for region: Dictionary in level["surface"]:
		for raw_loop: Array in [region["outer"]] + region.get("holes", []):
			var edge := PackedVector3Array()
			for raw: Array in raw_loop:
				edge.append(Vector3(float(raw[0]), datum - 0.11, float(raw[1])))
			if edge.size() > 2 and edge[0].distance_to(edge[-1]) > 0.001:
				edge.append(edge[0])
			var trim := _tube(edge, 0.025)
			trim.name = "%sDeckEdge" % level["id"]
			trim.material_override = SolidModel.material(RAIL, 0.9, 0.2)
			body.add_child(trim)
			CollisionPolicy.mark_decorative(trim)
static func _build_flight(body: StaticBody3D, flight: Dictionary) -> void:
	var profile: Array = flight.get("deck", flight["profile"])
	if profile.size() < 2:
		return
	var half_width := float(flight["width"]) * 0.5
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	for i in profile.size():
		var p: Array = profile[i]
		var before: Array = profile[maxi(i - 1, 0)]
		var after: Array = profile[mini(i + 1, profile.size() - 1)]
		var tangent := Vector2(float(after[0]) - float(before[0]), float(after[2]) - float(before[2])).normalized()
		var normal := Vector2(-tangent.y, tangent.x) * half_width
		left.append(Vector3(float(p[0]) + normal.x, float(p[1]), float(p[2]) + normal.y))
		right.append(Vector3(float(p[0]) - normal.x, float(p[1]), float(p[2]) - normal.y))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in profile.size() - 1:
		var a := left[i]
		var b := right[i]
		var c := right[i + 1]
		var d := left[i + 1]
		_add_face(st, faces, a, b, c, Vector3.UP)
		_add_face(st, faces, a, c, d, Vector3.UP)
		# Closed 220 mm cassette, following each sampled height and endpoint.
		_add_face(st, faces, a - Vector3.UP * DECK, d - Vector3.UP * DECK, c - Vector3.UP * DECK, Vector3.DOWN)
		_add_face(st, faces, a - Vector3.UP * DECK, c - Vector3.UP * DECK, b - Vector3.UP * DECK, Vector3.DOWN)
		var forward := Vector3(float(profile[i + 1][0]) - float(profile[i][0]), 0.0, float(profile[i + 1][2]) - float(profile[i][2])).normalized()
		var left_out := Vector3(-forward.z, 0.0, forward.x)
		_add_face(st, faces, a, d, d - Vector3.UP * DECK, left_out)
		_add_face(st, faces, a, d - Vector3.UP * DECK, a - Vector3.UP * DECK, left_out)
		_add_face(st, faces, b, b - Vector3.UP * DECK, c - Vector3.UP * DECK, -left_out)
		_add_face(st, faces, b, c - Vector3.UP * DECK, c, -left_out)
	var visual := MeshInstance3D.new()
	visual.name = "%sFlight" % flight["id"]
	visual.mesh = st.commit()
	var is_basalt := str(flight.get("material", "glass")) == "basalt"
	var deck_material := SolidModel.material(BASALT if is_basalt else GLASS, 0.0, 0.9 if is_basalt else 0.05)
	deck_material.cull_mode = BaseMaterial3D.CULL_BACK
	visual.material_override = deck_material
	visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(visual)
	for edge_points: PackedVector3Array in [left, right]:
		var edge_trim := _tube(edge_points, 0.025)
		edge_trim.name = "%sDeckEdge" % flight["id"]
		edge_trim.material_override = SolidModel.material(RAIL, 0.9, 0.2)
		body.add_child(edge_trim)
		CollisionPolicy.mark_decorative(edge_trim)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.name = "%sFlightCollision" % flight["id"]
	collider.shape = shape
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collider)
	for guard_line: Array in flight.get("guards", []):
		var points := PackedVector3Array()
		for raw: Array in guard_line:
			# Plan guard profiles already include the 1.09 m handrail rise.
			points.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
		_build_guard(body, points, "%sFlightGuard" % flight["id"])


static func _build_guard(body: StaticBody3D, rail_points: PackedVector3Array, label: String) -> void:
	if rail_points.size() < 2:
		return
	# One combined mesh per authored guard run. Posts are evenly divided so no
	# interval exceeds 1.6 m; every authored endpoint and profile corner gets one.
	var post_st := SurfaceTool.new()
	post_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var post_material := SolidModel.material(RAIL, 0.9, 0.2)
	post_material.cull_mode = BaseMaterial3D.CULL_BACK
	for i in rail_points.size() - 1:
		var a := rail_points[i]
		var b := rail_points[i + 1]
		var segment := b - a
		var horizontal := Vector2(segment.x, segment.z)
		var count := maxi(1, ceili(horizontal.length() / 1.6))
		var across := Vector3(-horizontal.y, 0.0, horizontal.x).normalized() * 0.0075
		for j in count:
			var p := a.lerp(b, float(j) / float(count))
			var along := Vector3(horizontal.x, 0.0, horizontal.y).normalized() * 0.03
			_add_box(post_st, p - Vector3.UP * 0.56, along, across, 0.94)
	# The final endpoint belongs to the final segment (and handles a single segment).
	var last := rail_points[-1]
	var prior := rail_points[-2]
	var last_dir := Vector2(last.x - prior.x, last.z - prior.z).normalized()
	_add_box(post_st, last - Vector3.UP * 0.56, Vector3(last_dir.x, 0.0, last_dir.y) * 0.03,
		Vector3(-last_dir.y, 0.0, last_dir.x) * 0.0075, 0.94)
	var posts := MeshInstance3D.new()
	posts.name = label + "Posts"
	posts.mesh = post_st.commit()
	posts.material_override = post_material
	body.add_child(posts)
	CollisionPolicy.mark_decorative(posts)
	var rail := _tube(rail_points, 0.05)
	rail.name = label + "Handrail"
	rail.material_override = SolidModel.material(RAIL, 0.9, 0.2)
	body.add_child(rail)
	CollisionPolicy.mark_decorative(rail)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in rail_points.size() - 1:
		var a := rail_points[i]
		var b := rail_points[i + 1]
		var lower_a := a - Vector3.UP * 1.03
		var lower_b := b - Vector3.UP * 1.03
		var side := (b - a).cross(Vector3.UP).normalized() * 0.018
		_add_face(st, faces, lower_a + side, lower_b + side, b + side)
		_add_face(st, faces, lower_a + side, b + side, a + side)
		_add_face(st, faces, lower_a - side, a - side, b - side)
		_add_face(st, faces, lower_a - side, b - side, lower_b - side)
	var pane := MeshInstance3D.new()
	pane.name = label + "Glass"
	pane.mesh = st.commit()
	var glass_material := SolidModel.material(GUARD, 0.0, 0.05)
	glass_material.cull_mode = BaseMaterial3D.CULL_BACK
	pane.material_override = glass_material
	pane.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(pane)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = label + "Collision"
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)


static func _add_box(st: SurfaceTool, centre: Vector3, along: Vector3, across: Vector3, height: float) -> void:
	var bottom := centre - Vector3.UP * height * 0.5
	var top := centre + Vector3.UP * height * 0.5
	var p := [bottom - along - across, bottom + along - across, bottom + along + across, bottom - along + across,
		top - along - across, top + along - across, top + along + across, top - along + across]
	for f: Array in [[0,2,1],[0,3,2],[4,5,6],[4,6,7],[0,1,5],[0,5,4],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,0,4],[3,4,7]]:
		var a: Vector3 = p[f[0]]
		var b: Vector3 = p[f[1]]
		var c: Vector3 = p[f[2]]
		st.set_normal((b - a).cross(c - a).normalized())
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(c)


static func _polygon_with_holes(region: Dictionary) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for p: Array in region["outer"]:
		polygon.append(Vector2(float(p[0]), float(p[1])))
	if polygon.size() > 2 and polygon[0].is_equal_approx(polygon[-1]):
		polygon.remove_at(polygon.size() - 1)
	# Bridge each authored hole into the boundary as a weakly-simple polygon;
	# the duplicate bridge endpoints preserve the exact plan boundary.
	for raw_hole: Array in region.get("holes", []):
		var hole := PackedVector2Array()
		for p: Array in raw_hole:
			hole.append(Vector2(float(p[0]), float(p[1])))
		if hole.size() > 2 and hole[0].is_equal_approx(hole[-1]):
			hole.remove_at(hole.size() - 1)
		if hole.size() < 3:
			continue
		var hi := 0
		for i in hole.size():
			if hole[i].x > hole[hi].x:
				hi = i
		var oi := _visible_bridge_index(polygon, hole, hi)
		if oi < 0:
			push_error("FireCalderaPlanWalks: no visible bridge for a hole")
			return PackedVector2Array()
		var merged := PackedVector2Array()
		for i in range(oi + 1):
			merged.append(polygon[i])
		merged.append(hole[hi])
		for step in range(1, hole.size()):
			merged.append(hole[(hi + step) % hole.size()])
		merged.append(hole[hi])
		merged.append(polygon[oi])
		for i in range(oi + 1, polygon.size()):
			merged.append(polygon[i])
		polygon = merged
	return polygon


static func _visible_bridge_index(outer: PackedVector2Array, hole: PackedVector2Array, hole_index: int) -> int:
	var best_index := -1
	var best_distance := INF
	var h := hole[hole_index]
	for candidate_index in outer.size():
		var o := outer[candidate_index]
		var midpoint := (h + o) * 0.5
		if not Geometry2D.is_point_in_polygon(midpoint, outer) or Geometry2D.is_point_in_polygon(midpoint, hole):
			continue
		var blocked := false
		for i in outer.size():
			var a := outer[i]
			var b := outer[(i + 1) % outer.size()]
			if i == candidate_index or (i + 1) % outer.size() == candidate_index:
				continue
			var hit: Variant = Geometry2D.segment_intersects_segment(h, o, a, b)
			if hit != null:
				blocked = true
				break
		if blocked:
			continue
		for i in hole.size():
			var a := hole[i]
			var b := hole[(i + 1) % hole.size()]
			if i == hole_index or (i + 1) % hole.size() == hole_index:
				continue
			var hit: Variant = Geometry2D.segment_intersects_segment(h, o, a, b)
			if hit != null:
				blocked = true
				break
		if blocked:
			continue
		var distance := h.distance_squared_to(o)
		if distance < best_distance:
			best_distance = distance
			best_index = candidate_index
	return best_index


static func _level_point(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)


static func _add_face(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, expected: Vector3 = Vector3.ZERO) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if expected.length_squared() > 0.0 and normal.dot(expected) < 0.0:
		var swap := b
		b = c
		c = swap
		normal = -normal
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)
	faces.append_array([a, b, c])


static func _tube(points: PackedVector3Array, radius: float) -> MeshInstance3D:
	const SIDES := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in points.size():
		var tangent := (points[1] - points[0]).normalized() if i == 0 else ((points[-1] - points[-2]).normalized() if i == points.size() - 1 else (points[i + 1] - points[i - 1]).normalized())
		var side := tangent.cross(Vector3.UP)
		if side.length_squared() < 0.01:
			side = tangent.cross(Vector3.FORWARD)
		side = side.normalized()
		var up := side.cross(tangent).normalized()
		var ring := PackedVector3Array()
		for j in SIDES:
			var a0 := TAU * float(j) / SIDES
			ring.append(points[i] + (side * cos(a0) + up * sin(a0)) * radius)
		rings.append(ring)
	for i in rings.size() - 1:
		for j in SIDES:
			var next := (j + 1) % SIDES
			st.add_vertex(rings[i][j]); st.add_vertex(rings[i + 1][j]); st.add_vertex(rings[i + 1][next])
			st.add_vertex(rings[i][j]); st.add_vertex(rings[i + 1][next]); st.add_vertex(rings[i][next])
	st.generate_normals()
	var result := MeshInstance3D.new()
	result.mesh = st.commit()
	return result
