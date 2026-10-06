class_name OpeningTrim
extends RefCounted

## Frames for superellipse wall openings, in the same visual language as the
## demo-world portals (a round pipe swept around a superellipse outline; see
## CheckpointPortal._build_ring). Outlines live in the XY plane with +Z as the
## outward face normal, x horizontal and y vertical.
##
## A window outline is a closed loop. A door outline is open at the bottom: the
## jambs run straight into the ground and only the head is rounded, matching a
## cutter whose lower half is carried below the wall base.

const PIPE_SIDES := 10
const ARCH_SAMPLES := 56
const WINDOW_SAMPLES := 72


## Closed superellipse loop, centred on the origin.
static func window_loop(half_width: float, half_height: float, exponent: float, count: int = WINDOW_SAMPLES) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for index in count:
		points.append(_super_point(half_width, half_height, exponent, TAU * float(index) / float(count)))
	return points


## Open head outline for a doorway of `height` whose bottom is square. The
## underlying superellipse carries on below the wall base (`extension`), exactly
## like the cutter that punched the hole, so the two always agree. Points run
## left jamb to right jamb; the jamb ends sink `sink` below y = 0.
static func door_arch(
	half_width: float, height: float, exponent: float, extension: float = 0.7,
	sink: float = 0.2, count: int = ARCH_SAMPLES
) -> Array[Vector2]:
	var half_height := (height + extension) * 0.5
	var center_y := height - half_height
	# y_rel = -center_y at the base: sin(theta) = -(center_y / half_height)^(n/2).
	var ratio := minf(center_y / half_height, 0.999)
	var start := asin(pow(ratio, exponent * 0.5))
	var points: Array[Vector2] = [Vector2(-half_width, -sink)]
	for index in count + 1:
		var angle := lerpf(PI + start, -start, float(index) / float(count))
		var point := _super_point(half_width, half_height, exponent, angle)
		points.append(Vector2(point.x, point.y + center_y))
	points.append(Vector2(half_width, -sink))
	return points


static func _super_point(half_width: float, half_height: float, exponent: float, angle: float) -> Vector2:
	var ca := cos(angle)
	var sa := sin(angle)
	return Vector2(
		half_width * signf(ca) * pow(absf(ca), 2.0 / exponent),
		half_height * signf(sa) * pow(absf(sa), 2.0 / exponent)
	)


## A round pipe swept along `points`. Open paths are capped by the pipe ends
## simply being buried, so callers sink them into the ground or wall.
static func piped_mesh(points: Array[Vector2], radius: float, closed: bool, inside: Vector2 = Vector2.ZERO) -> ArrayMesh:
	var count := points.size()
	var rings: Array[PackedVector3Array] = []
	var normals: Array[PackedVector3Array] = []
	for index in count:
		var previous: Vector2 = points[(index - 1 + count) % count] if closed else points[maxi(index - 1, 0)]
		var following: Vector2 = points[(index + 1) % count] if closed else points[mini(index + 1, count - 1)]
		var tangent := (following - previous).normalized()
		var outward2 := Vector2(tangent.y, -tangent.x)
		if outward2.dot(points[index] - inside) < 0.0:
			outward2 = -outward2
		var outward := Vector3(outward2.x, outward2.y, 0.0)
		var center := Vector3(points[index].x, points[index].y, 0.0)
		var ring := PackedVector3Array()
		var ring_normals := PackedVector3Array()
		for side in PIPE_SIDES:
			var angle := TAU * float(side) / float(PIPE_SIDES)
			var direction := outward * cos(angle) + Vector3.BACK * sin(angle)
			ring.append(center + direction * radius)
			ring_normals.append(direction)
		rings.append(ring)
		normals.append(ring_normals)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var spans := count if closed else count - 1
	for index in spans:
		var next := (index + 1) % count
		for side in PIPE_SIDES:
			var side_next := (side + 1) % PIPE_SIDES
			for pair in [[index, side], [index, side_next], [next, side], [index, side_next], [next, side_next], [next, side]]:
				tool.set_normal(normals[pair[0]][pair[1]])
				tool.add_vertex(rings[pair[0]][pair[1]])
	return tool.commit()


## Pipe frame as a ready-to-place node, +Z outward, material drawn two-sided.
static func piped_frame(
	points: Array[Vector2], radius: float, color: Color, closed: bool, inside: Vector2 = Vector2.ZERO
) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = piped_mesh(points, radius, closed, inside)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	CollisionPolicy.mark_decorative(instance)
	return instance


## A flat slab of the doorway's own shape (square foot, rounded head), `thickness`
## deep along +/-Z. Used for the door leaf.
static func arch_slab(half_width: float, height: float, exponent: float, thickness: float) -> ArrayMesh:
	var outline := door_arch(half_width, height, exponent, 0.7, 0.0)
	var front := thickness * 0.5
	var back := -front
	var centroid := Vector2(0.0, height * 0.45)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := outline.size()
	for index in count:
		var a := outline[index]
		var b := outline[(index + 1) % count]
		# Front cap (+Z), clockwise seen from +Z.
		for v: Vector2 in [centroid, a, b]:
			tool.set_normal(Vector3.BACK)
			tool.add_vertex(Vector3(v.x, v.y, front))
		for v: Vector2 in [centroid, b, a]:
			tool.set_normal(Vector3.FORWARD)
			tool.add_vertex(Vector3(v.x, v.y, back))
		var edge := (b - a).normalized()
		var side_normal := Vector3(edge.y, -edge.x, 0.0)
		for v: Array in [[a, front], [a, back], [b, front], [b, front], [a, back], [b, back]]:
			var p: Vector2 = v[0]
			tool.set_normal(side_normal)
			tool.add_vertex(Vector3(p.x, p.y, v[1]))
	return tool.commit()


## One leaf of a pair of shutters: the right half of a window's superellipse
## (x from 0 to `half_width`, curved outer margin at +x, straight meeting edge on
## x = 0), `thickness` deep along +/-Z. Mirror it with scale.x = -1 for the left
## leaf. Hinge it at its curved margin so it opens like a book.
static func half_slab(half_width: float, half_height: float, exponent: float, thickness: float, count: int = 40) -> ArrayMesh:
	var outline: Array[Vector2] = []
	# Right half of the loop, bottom to top, then straight back down the cut edge.
	for index in count + 1:
		var angle := lerpf(-PI * 0.5, PI * 0.5, float(index) / float(count))
		outline.append(_super_point(half_width, half_height, exponent, angle))
	var centroid := Vector2(half_width * 0.4, 0.0)
	var front := thickness * 0.5
	var back := -front
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var total := outline.size()
	for index in total:
		var a := outline[index]
		var b := outline[(index + 1) % total]
		for v: Vector2 in [centroid, a, b]:
			tool.set_normal(Vector3.BACK)
			tool.add_vertex(Vector3(v.x, v.y, front))
		for v: Vector2 in [centroid, b, a]:
			tool.set_normal(Vector3.FORWARD)
			tool.add_vertex(Vector3(v.x, v.y, back))
		var edge := (b - a).normalized()
		var side_normal := Vector3(edge.y, -edge.x, 0.0)
		for pair: Array in [[a, front], [a, back], [b, front], [b, front], [a, back], [b, back]]:
			var p: Vector2 = pair[0]
			tool.set_normal(side_normal)
			tool.add_vertex(Vector3(p.x, p.y, pair[1]))
	return tool.commit()
