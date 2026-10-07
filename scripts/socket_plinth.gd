class_name SocketPlinth
extends RefCounted

## The Fire caldera's socketed plinth (fire_caldera_layout.md, 1a; buildings
## brief, kit of parts "Foundation"): a tapered cast-basalt base on the same
## superellipse plan as the building above, embedded below the lowest ground
## along its perimeter, its top the floor datum, with a recessed metal control
## joint between base and shell. Its collider is the base itself, and the
## ground leaves a hole under it (FireCalderaGround builds round
## `terrain_exclusion`), so the floor is the only thing anyone stands on.

const BASALT := Color(0.16, 0.15, 0.15)
const JOINT_METAL := Color(0.22, 0.26, 0.32)
## The base steps out this much per metre down: a battered, tapered base.
const BATTER := 0.08
## Superellipse exponent of the plan: squarish, softened corners.
const PLAN_EXPONENT := 6.0
const SEGMENTS := 72
## A walkway of floor-level reveal between the building and the retaining
## wall on its uphill side (the layout's "retaining reveal").
const REVEAL := 0.8
const WALL_THICKNESS := 1.0


## Builds the plinth for a survey line (FireCalderaGround.survey()) of a plot,
## in `parent`'s frame, local plan coordinates. Returns the body.
static func build(parent: Node3D, entry: Dictionary, line: Dictionary, size_key: String = "footprint") -> StaticBody3D:
	var centre: Vector2 = entry["centre"]
	var half := (entry[size_key] as Vector2) * 0.5 + Vector2.ONE * REVEAL
	var deep := FireCalderaPlan.facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var top := float(line["datum"])
	var bottom := float(line["bottom"])
	var body := StaticBody3D.new()
	body.name = "%sPlinth" % entry["id"]
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	# Rings from the bottom up: the battered base, then a short recess for the
	# control joint, then the plinth's top course.
	var height := top - bottom
	var rings: Array = [
		[bottom, height * BATTER], [top - 0.32, 0.0], [top - 0.3, -0.06], [top - 0.14, -0.06], [top - 0.12, 0.0], [top, 0.0],
	]
	var top_course: Color = entry.get("floor_finish", BASALT.lightened(0.06))
	var colours: Array[Color] = [BASALT.darkened(0.15), BASALT, JOINT_METAL, JOINT_METAL, top_course, top_course]
	var loops: Array = []
	for ring: Array in rings:
		loops.append(_loop(centre, across, deep, half + Vector2.ONE * float(ring[1]), float(ring[0])))
	var cap: PackedVector3Array = loops[loops.size() - 1]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var middle := Vector3(centre.x, top, centre.y)
	var pits := FireCalderaPlan.pit_outlines(entry)
	for r in loops.size() - 1:
		var lower: PackedVector3Array = loops[r]
		var upper: PackedVector3Array = loops[r + 1]
		for i in SEGMENTS:
			var j := (i + 1) % SEGMENTS
			# Where a pit runs out past the plinth's edge (a quay's pool open
			# to the reservoir) its side stays open.
			if _in_pit(Vector2(lower[i].x + lower[j].x, lower[i].z + lower[j].z) * 0.5, pits) or _in_pit(Vector2(upper[i].x + upper[j].x, upper[i].z + upper[j].z) * 0.5, pits):
				continue
			_quad(st, lower[i], lower[j], upper[j], upper[i], middle, colours[r + 1])
	var faces := PackedVector3Array()
	# The top course's finish: basalt, or the plot's own floor (a pale sinter
	# for a house of care).
	var finish: Color = entry.get("floor_finish", BASALT.lightened(0.1))
	if pits.is_empty():
		# The top, level: one normal straight up.
		for i in SEGMENTS:
			_triangle(st, middle, cap[(i + 1) % SEGMENTS], cap[i], Vector3.UP, finish)
	else:
		faces = _pitted_top(st, cap, top, pits, finish)
	var mesh := MeshInstance3D.new()
	mesh.name = "PlinthMesh"
	mesh.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	mesh.material_override = material
	body.add_child(mesh)
	# One convex collider: the battered base from its foot to the datum, or,
	# under a pit, to just below the pit's floor, with the pitted top course
	# as one concave collider over it.
	var hull := PackedVector3Array()
	hull.append_array(loops[0])
	if faces.is_empty():
		hull.append_array(cap)
	else:
		for point in cap:
			hull.append(Vector3(point.x, top - _deepest(pits) - 0.05, point.z))
	var shape := ConvexPolygonShape3D.new()
	shape.points = hull
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	if not faces.is_empty():
		var course := ConcavePolygonShape3D.new()
		course.set_faces(faces)
		course.backface_collision = true
		var top_collider := CollisionShape3D.new()
		top_collider.name = "PittedTopCourse"
		top_collider.shape = course
		top_collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
		body.add_child(top_collider)
	_retaining(body, cap, centre, top)
	return body


## The plinth's top with its pits dug in: the level top round the pit
## outlines, each pit's walls and floor, and the outer band of the top course
## down to the pits' depth. Adds the surfaces to `st` and returns them as
## collision faces (triangles).
static func _pitted_top(st: SurfaceTool, cap: PackedVector3Array, top: float, pits: Array[Dictionary], finish: Color) -> PackedVector3Array:
	var faces := PackedVector3Array()
	var outer := PackedVector2Array()
	for point in cap:
		outer.append(Vector2(point.x, point.z))
	# Cut the top along a line through each pit, so each piece is a simple
	# polygon once the pit is clipped from it, then triangulate the pieces.
	var pieces: Array[PackedVector2Array] = [outer]
	for pit in pits:
		var outline: PackedVector2Array = pit["outline"]
		var mid := Vector2.ZERO
		for point in outline:
			mid += point
		mid /= float(outline.size())
		var cut: Array[PackedVector2Array] = []
		for piece in pieces:
			for side: float in [-1.0, 1.0]:
				var half_plane := PackedVector2Array([mid + Vector2(-500, 0), mid + Vector2(500, 0), mid + Vector2(500, side * 500), mid + Vector2(-500, side * 500)])
				for part in Geometry2D.intersect_polygons(piece, half_plane):
					for remainder in Geometry2D.clip_polygons(part, outline):
						if remainder.size() >= 3:
							cut.append(remainder)
		pieces = cut
	var lit := finish
	for piece in pieces:
		var triangles := Geometry2D.triangulate_polygon(piece)
		for t in range(0, triangles.size(), 3):
			var a := piece[triangles[t]]
			var b := piece[triangles[t + 1]]
			var c := piece[triangles[t + 2]]
			_face(st, faces, Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), Vector3(c.x, top, c.y), Vector3.UP, lit)
	var deepest := _deepest(pits)
	var middle := Vector3.ZERO
	for point in cap:
		middle += point
	middle /= float(cap.size())
	# The top course's outer band, for collision only (the mesh has its rings).
	for i in cap.size():
		var j := (i + 1) % cap.size()
		if _in_pit(Vector2(cap[i].x + cap[j].x, cap[i].z + cap[j].z) * 0.5, pits):
			continue
		var low_i := Vector3(cap[i].x, top - deepest - 0.05, cap[i].z)
		var low_j := Vector3(cap[j].x, top - deepest - 0.05, cap[j].z)
		faces.append_array([cap[i], cap[j], low_j, cap[i], low_j, low_i])
	for pit in pits:
		var outline: PackedVector2Array = pit["outline"]
		var floor_y := top - float(pit["depth"])
		var centre := Vector2.ZERO
		for point in outline:
			centre += point
		centre /= float(outline.size())
		var inside := Vector3(centre.x, top - float(pit["depth"]) * 0.5, centre.y)
		# A pit that holds lava is lined with near-black refractory.
		var wall := Color(0.21, 0.18, 0.17) if bool(pit.get("lava", false)) else finish.darkened(0.12)
		for i in outline.size():
			var j := (i + 1) % outline.size()
			var a := outline[i]
			var b := outline[j]
			# Where pits join (a channel into a pool) no wall stands between them.
			var others: Array[Dictionary] = []
			for other in pits:
				if other != pit:
					others.append(other)
			if _in_pit((a + b) * 0.5, others):
				continue
			_quad(st, Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), Vector3(b.x, floor_y, b.y), Vector3(a.x, floor_y, a.y), inside, wall, true)
			faces.append_array([Vector3(a.x, top, a.y), Vector3(b.x, top, b.y), Vector3(b.x, floor_y, b.y), Vector3(a.x, top, a.y), Vector3(b.x, floor_y, b.y), Vector3(a.x, floor_y, a.y)])
			_face(st, faces, Vector3(centre.x, floor_y, centre.y), Vector3(a.x, floor_y, a.y), Vector3(b.x, floor_y, b.y), Vector3.UP, finish.darkened(0.04))
	return faces


static func _face(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, colour: Color) -> void:
	_triangle(st, a, b, c, normal, colour)
	faces.append_array([a, b, c])


## The depth of the deepest pit dug into a plot's plinth (zero for none), for
## the ground hidden under it.
static func sink(entry: Dictionary) -> float:
	return float(entry.get("sink", _deepest(FireCalderaPlan.pit_outlines(entry))))


static func _in_pit(point: Vector2, pits: Array[Dictionary]) -> bool:
	for pit in pits:
		if Geometry2D.is_point_in_polygon(point, pit["outline"]):
			return true
	return false


static func _deepest(pits: Array[Dictionary]) -> float:
	var deepest := 0.0
	for pit in pits:
		deepest = maxf(deepest, float(pit["depth"]))
	return deepest


## Wherever the ground stands above the datum round the plinth, a retaining
## wall rises from the reveal to just above the ground: the uphill socket. One
## continuous band, its inner face on the plinth's edge and WALL_THICKNESS
## thick, so from the terrace it reads as a basalt kerb flush with the ground
## and from the reveal as a clean cut face. A box collider per segment.
static func _retaining(body: StaticBody3D, cap: PackedVector3Array, centre: Vector2, datum: float) -> void:
	var count := cap.size()
	var tops := PackedFloat32Array()
	var outer := PackedVector2Array()
	for i in count:
		var p := Vector2(cap[i].x, cap[i].z)
		var outward := (p - centre).normalized()
		outer.append(p + outward * WALL_THICKNESS)
		tops.append(FireCalderaGround.height(p + outward * (WALL_THICKNESS + 0.3)) + 0.15)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var any := false
	var middle := Vector3(centre.x, datum, centre.y)
	for i in count:
		var j := (i + 1) % count
		if tops[i] < datum + 0.2 and tops[j] < datum + 0.2:
			continue
		any = true
		var ti := maxf(tops[i], datum + 0.05)
		var tj := maxf(tops[j], datum + 0.05)
		var a := Vector2(cap[i].x, cap[i].z)
		var b := Vector2(cap[j].x, cap[j].z)
		var colour := BASALT.lightened(0.03)
		# Inner face (toward the building), top, outer face.
		_quad(st, Vector3(a.x, datum, a.y), Vector3(b.x, datum, b.y), Vector3(b.x, tj, b.y), Vector3(a.x, ti, a.y), middle, colour, true)
		_quad(st, Vector3(a.x, ti, a.y), Vector3(b.x, tj, b.y), Vector3(outer[j].x, tj, outer[j].y), Vector3(outer[i].x, ti, outer[i].y), middle + Vector3(0, -100, 0), colour.lightened(0.05))
		_quad(st, Vector3(outer[i].x, datum - 0.5, outer[i].y), Vector3(outer[j].x, datum - 0.5, outer[j].y), Vector3(outer[j].x, tj, outer[j].y), Vector3(outer[i].x, ti, outer[i].y), middle, colour)
		var length := a.distance_to(b) + 0.05
		var height := maxf(ti, tj) - datum
		var mid := (a + b) * 0.5 + (outer[i] - a + outer[j] - b) * 0.25
		var holder := MeshInstance3D.new()
		body.add_child(holder)
		CollisionPolicy.add_box(body, holder, Vector3(length, height, WALL_THICKNESS), Vector3(mid.x, datum + height * 0.5, mid.y), Basis(Vector3.UP, atan2(-(b - a).y, (b - a).x)), true)
	if not any:
		return
	var wall := MeshInstance3D.new()
	wall.name = "RetainingWall"
	wall.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	wall.material_override = material
	body.add_child(wall)
	CollisionPolicy.mark_decorative(wall)


## A quad a-b-c-d with a flat normal facing away from `inside` (or toward it
## when `toward`), wound for Godot's clockwise front face from that side.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3, colour: Color, toward: bool = false) -> void:
	var normal := (b - a).cross(d - a).normalized()
	var centre := (a + b + c + d) * 0.25
	var away := (centre - inside).normalized()
	if (normal.dot(away) < 0.0) != toward:
		normal = -normal
	_triangle(st, a, b, c, normal, colour)
	_triangle(st, a, c, d, normal, colour)


## One triangle with a given normal, its winding set so that normal is its
## front (clockwise seen from the normal's side).
static func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, colour: Color) -> void:
	if (b - a).cross(c - a).dot(normal) > 0.0:
		var swap := b
		b = c
		c = swap
	for v in [a, b, c]:
		st.set_color(colour)
		st.set_normal(normal)
		st.add_vertex(v)


## The plan outline (a superellipse of half-size `half` on the plot's axes)
## at height `y`.
static func _loop(centre: Vector2, across: Vector2, deep: Vector2, half: Vector2, y: float) -> PackedVector3Array:
	var points := PackedVector3Array()
	for i in SEGMENTS:
		var t := TAU * float(i) / float(SEGMENTS)
		var c := cos(t)
		var s := sin(t)
		var u := signf(c) * pow(absf(c), 2.0 / PLAN_EXPONENT) * half.x
		var v := signf(s) * pow(absf(s), 2.0 / PLAN_EXPONENT) * half.y
		var p := centre + across * u + deep * v
		points.append(Vector3(p.x, y, p.y))
	return points


## The plinth's plan outline at the ground, for the ground mesh's hole: the
## footprint grown by the batter it has reached at the lowest ground.
static func exclusion(entry: Dictionary, line: Dictionary, size_key: String = "footprint") -> PackedVector2Array:
	var centre: Vector2 = entry["centre"]
	var deep := FireCalderaPlan.facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var half := (entry[size_key] as Vector2) * 0.5 + Vector2.ONE * REVEAL
	var outline := PackedVector2Array()
	for point in _loop(centre, across, deep, half, 0.0):
		outline.append(Vector2(point.x, point.z))
	return outline


## The outline grown by the retaining wall: the band under which the ground
## lies no higher than the floor.
static func band(entry: Dictionary, size_key: String = "footprint") -> PackedVector2Array:
	var centre: Vector2 = entry["centre"]
	var deep := FireCalderaPlan.facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var half := (entry[size_key] as Vector2) * 0.5 + Vector2.ONE * (REVEAL + WALL_THICKNESS - 0.05)
	var outline := PackedVector2Array()
	for point in _loop(centre, across, deep, half, 0.0):
		outline.append(Vector2(point.x, point.z))
	return outline


## A plot can name a foundation wider than its occupied shell when the same
## socket supports an approved terrace. Keeping this choice here makes the
## ground exclusion, visible plinth and collision use one footprint.
static func size_key(entry: Dictionary) -> String:
	return "foundation" if entry.has("foundation") else "footprint"
