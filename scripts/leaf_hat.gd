class_name LeafHat
extends RefCounted

## A broad living leaf draped over the crown, with a rounded forward tip,
## tapered rear stem, seated veins and one continuous closed securing vine.

const LEAF_COLOR := Color(0.18, 0.62, 0.22)
const VEIN_COLOR := Color(0.11, 0.42, 0.14)
const VINE_COLOR := Color(0.15, 0.36, 0.10)
const WIDTH_SEGMENTS := 24
const LENGTH_SEGMENTS := 36


static func build_visual(item_scale: float = 1.0) -> Node3D:
	return build_fitted(
		0.34 * item_scale, 0.46 * item_scale, 0.11 * item_scale,
		0.38 * item_scale
	)


static func build_fitted(
	half_width: float, half_length: float, curl: float, chin_drop: float = 0.0,
	body_color: Color = LEAF_COLOR
) -> Node3D:
	var root := Node3D.new()
	root.name = "LeafHat"
	var leaf := MeshInstance3D.new()
	leaf.name = "CurvedLeaf"
	leaf.mesh = _leaf_mesh(half_width, half_length, curl)
	leaf.material_override = _material(body_color, 0.78)
	root.add_child(leaf)

	# The midrib follows the actual leaf surface, half embedded in the skin.
	# Its rear extension is the same continuous stem, with a natural bend.
	var rib_points: Array[Vector3] = [
		Vector3(-half_width * 0.09, -curl * 0.62, -half_length * 1.22),
		Vector3(-half_width * 0.035, -curl * 0.48, -half_length * 1.08),
	]
	var rib_radii: Array[float] = [half_width * 0.012, half_width * 0.023]
	for step in 31:
		var v := lerpf(0.015, 0.985, step / 30.0)
		var point := _leaf_point(0.5, v, half_width, half_length, curl)
		var radius := half_width * lerpf(0.028, 0.005, v)
		point.y += radius * 0.25
		rib_points.append(point)
		rib_radii.append(radius)
	_add_tube(root, "MidribAndStem", rib_points, rib_radii, body_color.darkened(0.12))
	# Paired curved veins give the blade a leafy structure rather than the
	# appearance of a cut sheet. Each one is seated in that same skin.
	for station in [0.22, 0.36, 0.50, 0.64, 0.76]:
		for side in [-1.0, 1.0]:
			var points: Array[Vector3] = []
			var radii: Array[float] = []
			for step in 9:
				var t := step / 8.0
				var v: float = station + 0.12 * t
				var point := _leaf_point(0.5 + side * 0.43 * t, v, half_width, half_length, curl)
				var radius := half_width * lerpf(0.009, 0.002, t)
				point.y += radius * 0.25
				points.append(point)
				radii.append(radius)
			_add_tube(root, "LeafVein", points, radii, body_color.darkened(0.08))

	var radius := half_width * 0.035
	var drop := maxf(chin_drop, half_width * 1.2)
	var controls: Array[Vector3] = []
	# Walk clockwise over the crown, around the cheek and under the chin,
	# then back up the other side. Periodic interpolation joins everything
	# into one smooth closed loop, including the two former strap junctions.
	for fraction in [0.0, 0.35, 0.70, 0.88]:
		var point := surface_point(half_width * fraction, 0.0, half_width, half_length, curl)
		point.y += radius * 0.35
		controls.append(point)
	controls.append_array([
		Vector3(half_width * 0.96, -drop * 0.34, half_length * 0.08),
		Vector3(half_width * 0.77, -drop * 0.74, half_length * 0.17),
		Vector3(half_width * 0.40, -drop * 0.96, half_length * 0.21),
		Vector3(0.0, -drop * 1.02, half_length * 0.22),
		Vector3(-half_width * 0.40, -drop * 0.96, half_length * 0.21),
		Vector3(-half_width * 0.77, -drop * 0.74, half_length * 0.17),
		Vector3(-half_width * 0.96, -drop * 0.34, half_length * 0.08),
	])
	for fraction in [-0.88, -0.70, -0.35]:
		var point := surface_point(half_width * fraction, 0.0, half_width, half_length, curl)
		point.y += radius * 0.35
		controls.append(point)
	var vine := MeshInstance3D.new()
	vine.name = "SecuringVine"
	vine.mesh = _closed_vine_mesh(controls, radius)
	vine.material_override = _material(body_color.darkened(0.18), 0.92)
	root.add_child(vine)
	return root


static func _leaf_mesh(half_width: float, half_length: float, curl: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in LENGTH_SEGMENTS:
		for ix in WIDTH_SEGMENTS:
			var u0 := float(ix) / WIDTH_SEGMENTS
			var u1 := float(ix + 1) / WIDTH_SEGMENTS
			var v0 := float(iz) / LENGTH_SEGMENTS
			var v1 := float(iz + 1) / LENGTH_SEGMENTS
			var a := _leaf_point(u0, v0, half_width, half_length, curl)
			var b := _leaf_point(u1, v0, half_width, half_length, curl)
			var c := _leaf_point(u1, v1, half_width, half_length, curl)
			var d := _leaf_point(u0, v1, half_width, half_length, curl)
			_add_triangle(surface, a, c, b)
			_add_triangle(surface, a, d, c)
	surface.generate_normals()
	return surface.commit()


static func _leaf_point(u: float, v: float, half_width: float, half_length: float, curl: float) -> Vector3:
	var z := lerpf(-half_length, half_length, v)
	var longitudinal := width_profile(v)
	var x := lerpf(-1.0, 1.0, u) * half_width * longitudinal
	var across := lerpf(-1.0, 1.0, u)
	# A soft crown and gently drooping tip, with a little natural twist.
	var along := z / half_length
	var y := -curl * across * across - curl * 0.35 * along * along
	y += curl * 0.08 * sin(PI * v) + curl * 0.10 * across * sin(PI * along)
	return Vector3(x, y, z)


## Narrow at the rear stem, broad through the blade, with a rounded banana-
## leaf tip at the front. Both ends close rather than ending in cut edges.
static func width_profile(v: float) -> float:
	var peak := 0.7 / (0.7 + 0.45)
	var normalization := pow(peak, 0.7) * pow(1.0 - peak, 0.45)
	return pow(clampf(v, 0.0, 1.0), 0.7) * pow(clampf(1.0 - v, 0.0, 1.0), 0.45) / normalization


## Exact authored leaf surface and numerical normal used to seat the living
## Blorb eyes. This is the same equation _leaf_mesh() samples, so the eyes do
## not rely on a round-hat approximation or float above the taco curve.
static func surface_point(
	x: float, z: float, half_width: float, half_length: float, curl: float
) -> Vector3:
	var v := clampf((z / half_length + 1.0) * 0.5, 0.001, 0.999)
	var longitudinal := maxf(width_profile(v), 0.0001)
	var local_half_width := half_width * longitudinal
	var u := clampf((x / local_half_width + 1.0) * 0.5, 0.001, 0.999)
	return _leaf_point(u, v, half_width, half_length, curl)


static func surface_normal(
	x: float, z: float, half_width: float, half_length: float, curl: float
) -> Vector3:
	var step := minf(half_width, half_length) * 0.004
	var tangent_x := (
		surface_point(x + step, z, half_width, half_length, curl)
		- surface_point(x - step, z, half_width, half_length, curl)
	)
	var tangent_z := (
		surface_point(x, z + step, half_width, half_length, curl)
		- surface_point(x, z - step, half_width, half_length, curl)
	)
	var normal := tangent_z.cross(tangent_x).normalized()
	return normal if normal.y >= 0.0 else -normal


static func _add_tube(root: Node3D, name: String, points: Array[Vector3], radii: Array[float], color: Color) -> void:
	var tube := MeshInstance3D.new()
	tube.name = name
	tube.mesh = BlorbSuit.build_limb_tube(points, radii, 10, 3, 0.0, [], false, Vector3.ZERO, 1.0, false)
	tube.material_override = _material(color, 0.92)
	root.add_child(tube)


static func _closed_vine_mesh(controls: Array[Vector3], radius: float) -> ArrayMesh:
	var rings: Array = []
	var count := controls.size()
	for segment in count:
		for step in 8:
			var t := step / 8.0
			var a := controls[(segment + count - 1) % count]
			var b := controls[segment]
			var c := controls[(segment + 1) % count]
			var d := controls[(segment + 2) % count]
			var center := BlorbSuit._catmull_rom(a, b, c, d, t)
			var tangent := BlorbSuit._catmull_rom_tangent(a, b, c, d, t)
			# This loop runs around the head in XY, so FORWARD never becomes
			# parallel to its tangent. A fresh frame closes without roll drift.
			var right := tangent.cross(Vector3.FORWARD).normalized()
			var up := right.cross(tangent).normalized()
			rings.append(BlorbSuit._build_ring(center, right, up, radius, 10))
	rings.append(rings[0])
	return BlorbBodyShape.build_mesh_from_rings(rings, [], false)


static func _add_triangle(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


static func _material(color: Color, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
