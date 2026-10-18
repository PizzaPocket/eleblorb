class_name SuitSurface
extends RefCounted

## Actual tube triangles, grouped by ring band for cheap local queries.
## No physics colliders or previous-frame orientation state are involved.
static func cache(mesh: ArrayMesh, rings: Array) -> void:
	var bands: Array = []
	# Query the committed vertices, including any renderer-side position
	# packing. The pre-commit ring values can differ enough on tiny limbs
	# to put an apparently exact anchor just off the rendered triangle.
	var triangles := mesh.get_faces()
	var band_size: int = (rings[0] as Array).size() * 6
	for start in range(0, triangles.size(), band_size):
		var faces := triangles.slice(start, mini(start + band_size, triangles.size()))
		var bounds := AABB(faces[0], Vector3.ZERO)
		for vertex in faces:
			bounds = bounds.expand(vertex)
		bands.append({"bounds": bounds.grow(0.000001), "faces": faces})
	mesh.set_meta("suit_surface", bands)


static func available(mesh: Mesh) -> bool:
	return mesh != null and mesh.has_meta("suit_surface")


static func project(mesh: Mesh, target: Vector3, outward: Vector3, reach: float) -> Dictionary:
	if not available(mesh):
		return {}
	outward = outward.normalized()
	# A thin foot can belong to a very long leg. Start outside the entire
	# piece, not merely a few foot radii away inside its shin or hip cap.
	reach = maxf(reach, mesh.get_aabb().size.length() * 2.0)
	var origin := target + outward * reach
	var nearest := INF
	var result := {}
	for band: Dictionary in mesh.get_meta("suit_surface"):
		if (band["bounds"] as AABB).intersects_ray(origin, -outward) == null:
			continue
		var faces: PackedVector3Array = band["faces"]
		for triangle in range(0, faces.size(), 3):
			var a := faces[triangle]
			var b := faces[triangle + 1]
			var c := faces[triangle + 2]
			# Normalise the local query size: Godot's triangle-ray epsilon
			# otherwise drops tiny monkey triangles that a human-sized ray hits.
			var query_scale := 100.0 / maxf(reach, 0.000001)
			var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3.ZERO, -outward, (a - origin) * query_scale, (b - origin) * query_scale, (c - origin) * query_scale)
			if hit != null:
				hit = origin + (hit as Vector3) / query_scale
			if hit == null:
				continue
			var distance := origin.distance_squared_to(hit as Vector3)
			if distance < nearest:
				nearest = distance
				var normal := (b - a).cross(c - a).normalized()
				if normal.dot(outward) < 0.0:
					normal = -normal
				result = {"point": hit, "normal": normal}
	return result


## Exact point/triangle distance, used to bound the whole core sphere rather
## than only its centre or its forward edge. Band bounds reject distant skin.
static func clearance(mesh: Mesh, point: Vector3, limit: float) -> float:
	var closest_squared := limit * limit
	for band: Dictionary in mesh.get_meta("suit_surface", []):
		if not (band["bounds"] as AABB).grow(sqrt(closest_squared)).has_point(point):
			continue
		var faces: PackedVector3Array = band["faces"]
		for triangle in range(0, faces.size(), 3):
			var closest := _closest_triangle(point, faces[triangle], faces[triangle + 1], faces[triangle + 2])
			closest_squared = minf(closest_squared, point.distance_squared_to(closest))
	return sqrt(closest_squared)


static func _closest_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	# Zero-radius cap rings produce degenerate triangles; test their edges.
	if ab.cross(ac).length_squared() < 1e-20:
		var answer := a
		for pair in [[a, b], [b, c], [c, a]]:
			var edge: Vector3 = pair[1] - pair[0]
			var t := clampf((p - (pair[0] as Vector3)).dot(edge) / maxf(edge.length_squared(), 1e-20), 0.0, 1.0)
			var candidate: Vector3 = pair[0] + edge * t
			if candidate.distance_squared_to(p) < answer.distance_squared_to(p):
				answer = candidate
		return answer
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and d4 - d3 >= 0.0 and d5 - d6 >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var denominator := 1.0 / (va + vb + vc)
	return a + ab * (vb * denominator) + ac * (vc * denominator)
