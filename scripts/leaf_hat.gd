class_name LeafHat
extends RefCounted

## A broad living leaf worn crosswise over the crown. Its width curls upward
## at both sides (a shallow taco section) while its stem-to-tip axis follows
## the head front-to-back. The vine is a separate soft band which physically
## wraps beneath the leaf rather than a painted stripe.

const LEAF_COLOR := Color(0.18, 0.62, 0.22)
const VEIN_COLOR := Color(0.11, 0.42, 0.14)
const VINE_COLOR := Color(0.15, 0.36, 0.10)
const WIDTH_SEGMENTS := 14
const LENGTH_SEGMENTS := 20


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

	# Raised midrib makes the object read as a leaf from above and in profile.
	var midrib := MeshInstance3D.new()
	midrib.name = "Midrib"
	var rib_mesh := CylinderMesh.new()
	rib_mesh.top_radius = half_width * 0.025
	rib_mesh.bottom_radius = half_width * 0.04
	rib_mesh.height = half_length * 1.72
	rib_mesh.radial_segments = 8
	midrib.mesh = rib_mesh
	midrib.rotation.x = PI * 0.5
	midrib.position = Vector3(0.0, curl * 0.16 + half_width * 0.025, 0.04 * half_length)
	midrib.material_override = _material(body_color, 0.85)
	root.add_child(midrib)

	# One continuous tie crosses the leaf, drops down both sides of the head,
	# and meets beneath the chin. This is a hat strap, not a halo sitting above
	# the crown.
	var drop := maxf(chin_drop, half_width * 1.2)
	var strap_points: Array[Vector3] = [
		Vector3(-half_width * 0.82, -curl * 0.66, 0.0),
		Vector3(-half_width * 0.92, -drop * 0.48, half_length * 0.12),
		Vector3(-half_width * 0.38, -drop, half_length * 0.22),
		Vector3(0.0, -drop * 1.08, half_length * 0.24),
		Vector3(half_width * 0.38, -drop, half_length * 0.22),
		Vector3(half_width * 0.92, -drop * 0.48, half_length * 0.12),
		Vector3(half_width * 0.82, -curl * 0.66, 0.0),
	]
	var tie_color := body_color
	_add_vine_path(root, strap_points, half_width * 0.035, tie_color)
	# The section crossing the leaf follows its downward crown rather than
	# floating above it.
	_add_vine_path(root, [
		Vector3(-half_width * 0.82, -curl * 0.66, 0.0),
		Vector3(-half_width * 0.42, -curl * 0.17, 0.0),
		Vector3(0.0, half_width * 0.018, 0.0),
		Vector3(half_width * 0.42, -curl * 0.17, 0.0),
		Vector3(half_width * 0.82, -curl * 0.66, 0.0),
	], half_width * 0.035, tie_color)
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
	# Elliptical leaf outline tapering cleanly to its stem and tip.
	var longitudinal := sqrt(maxf(0.0, 1.0 - pow((z / half_length), 2.0)))
	var x := lerpf(-1.0, 1.0, u) * half_width * longitudinal
	var local_width := maxf(half_width * longitudinal, 0.001)
	var across := x / local_width
	# The centre rides over the crown while both side margins wrap DOWN around
	# it—the inverse of the original bowl/halo curve.
	var y := -curl * across * across
	# A very small front-to-back crown drape keeps it from reading as a tray.
	y -= curl * 0.18 * pow(z / half_length, 2.0)
	return Vector3(x, y, z)


## Exact authored leaf surface and numerical normal used to seat the living
## Blorb eyes. This is the same equation _leaf_mesh() samples, so the eyes do
## not rely on a round-hat approximation or float above the taco curve.
static func surface_point(
	x: float, z: float, half_width: float, half_length: float, curl: float
) -> Vector3:
	var v := clampf((z / half_length + 1.0) * 0.5, 0.001, 0.999)
	var longitudinal := sqrt(maxf(0.0001, 1.0 - pow(z / half_length, 2.0)))
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


static func _add_vine_path(
	root: Node3D, points: Array[Vector3], radius: float, color: Color
) -> void:
	var material := _material(color, 0.92)
	for index in points.size() - 1:
		var from := points[index]
		var to := points[index + 1]
		var direction := to - from
		var segment := MeshInstance3D.new()
		segment.name = "SecuringVine"
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = radius
		cylinder.bottom_radius = radius
		cylinder.height = direction.length()
		cylinder.radial_segments = 7
		segment.mesh = cylinder
		segment.position = (from + to) * 0.5
		segment.basis = Basis(Quaternion(Vector3.UP, direction.normalized()))
		segment.material_override = material
		root.add_child(segment)


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
