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
	var colours: Array[Color] = [BASALT.darkened(0.15), BASALT, JOINT_METAL, JOINT_METAL, BASALT.lightened(0.06), BASALT.lightened(0.06)]
	var loops: Array = []
	for ring: Array in rings:
		loops.append(_loop(centre, across, deep, half + Vector2.ONE * float(ring[1]), float(ring[0])))
	var cap: PackedVector3Array = loops[loops.size() - 1]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var middle := Vector3(centre.x, top, centre.y)
	for r in loops.size() - 1:
		var lower: PackedVector3Array = loops[r]
		var upper: PackedVector3Array = loops[r + 1]
		for i in SEGMENTS:
			var j := (i + 1) % SEGMENTS
			_quad(st, lower[i], lower[j], upper[j], upper[i], middle, colours[r + 1])
	# The top, level: one normal straight up.
	for i in SEGMENTS:
		_triangle(st, middle, cap[(i + 1) % SEGMENTS], cap[i], Vector3.UP, BASALT.lightened(0.1))
	var mesh := MeshInstance3D.new()
	mesh.name = "PlinthMesh"
	mesh.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	mesh.material_override = material
	body.add_child(mesh)
	# One convex collider: the battered base from its foot to the datum.
	var hull := PackedVector3Array()
	hull.append_array(loops[0])
	hull.append_array(cap)
	var shape := ConvexPolygonShape3D.new()
	shape.points = hull
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	_retaining(body, cap, centre, top)
	return body


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
