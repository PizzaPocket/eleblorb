class_name SolidModel
extends RefCounted

## Reusable constructive-solid modeling for procedural game geometry.
## Callers describe closed positive and negative volumes as CSG children, then
## bake the evaluated result through bake_when_ready().  Curved profile cutters
## use equal-distance sampling, and the bake reconstructs normals by crease so
## continuous surfaces remain smooth while Boolean rims stay hard.

const DEFAULT_RINGS := 56
const DEFAULT_SEGMENTS := 72
const DEFAULT_PROFILE_SEGMENTS := 144
const DEFAULT_CREASE_DEGREES := 32.0
const POSITION_WELD_SCALE := 10000.0


static func material(color: Color, roughness: float = 0.38, metallic: float = 0.05) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = roughness
	result.metallic = metallic
	if color.a < 0.999:
		result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result


static func add_super(
	parent: Node, name_text: String, axes: Vector3, operation: CSGShape3D.Operation,
	surface_material: Material, at: Vector3 = Vector3.ZERO,
	epsilon: float = SuperEgg.EPSILON_SOFT,
	rings: int = DEFAULT_RINGS, segments: int = DEFAULT_SEGMENTS
) -> CSGMesh3D:
	var solid := CSGMesh3D.new()
	solid.name = name_text
	solid.mesh = super_mesh(axes, epsilon, rings, segments)
	solid.operation = operation
	solid.material = surface_material
	solid.position = at
	parent.add_child(solid)
	return solid


static func add_profile(
	parent: Node, name_text: String, depth: float, half: Vector2, exponent: float,
	operation: CSGShape3D.Operation, surface_material: Material,
	at: Vector3 = Vector3.ZERO, segments: int = DEFAULT_PROFILE_SEGMENTS
) -> CSGMesh3D:
	var cutter := CSGMesh3D.new()
	cutter.name = name_text
	cutter.mesh = extruded_profile_mesh(depth, half, exponent, segments)
	cutter.operation = operation
	cutter.material = surface_material
	cutter.position = at
	parent.add_child(cutter)
	return cutter


static func add_box(
	parent: Node, name_text: String, size: Vector3, operation: CSGShape3D.Operation,
	surface_material: Material, at: Vector3 = Vector3.ZERO
) -> CSGBox3D:
	var solid := CSGBox3D.new()
	solid.name = name_text
	solid.size = size
	solid.operation = operation
	solid.material = surface_material
	solid.position = at
	parent.add_child(solid)
	return solid


static func super_mesh(
	axes: Vector3, epsilon: float = SuperEgg.EPSILON_SOFT,
	ring_count: int = DEFAULT_RINGS, segment_count: int = DEFAULT_SEGMENTS
) -> ArrayMesh:
	# Use one vertex at each pole and triangle fans into the first/last real
	# rings. Repeating the pole once per segment creates zero-area triangles;
	# CSG discards those inconsistently, which showed up as paired holes on the
	# sides of a rotated spherical Space Helm.
	var rings: Array = []
	for ring_index in range(1, ring_count):
		var eta := -PI * 0.5 + PI * float(ring_index) / float(ring_count)
		var row: Array[Vector3] = []
		for segment in segment_count:
			var omega := TAU * float(segment) / float(segment_count)
			row.append(SuperEgg.surface_point(axes, eta, omega, epsilon, epsilon))
		rings.append(row)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bottom := SuperEgg.surface_point(axes, -PI * 0.5, 0.0, epsilon, epsilon)
	var top := SuperEgg.surface_point(axes, PI * 0.5, 0.0, epsilon, epsilon)
	var first: Array[Vector3] = rings[0]
	var last: Array[Vector3] = rings[rings.size() - 1]
	for segment in segment_count:
		var next := (segment + 1) % segment_count
		tool.add_vertex(bottom)
		tool.add_vertex(first[segment])
		tool.add_vertex(first[next])
		tool.add_vertex(last[segment])
		tool.add_vertex(top)
		tool.add_vertex(last[next])
	for ring_index in rings.size() - 1:
		var here: Array[Vector3] = rings[ring_index]
		var after: Array[Vector3] = rings[ring_index + 1]
		for segment in segment_count:
			var next := (segment + 1) % segment_count
			tool.add_vertex(here[segment])
			tool.add_vertex(after[segment])
			tool.add_vertex(here[next])
			tool.add_vertex(here[next])
			tool.add_vertex(after[segment])
			tool.add_vertex(after[next])
	tool.generate_normals()
	return tool.commit()


static func extruded_profile_mesh(
	depth: float, half: Vector2, exponent: float,
	segment_count: int = DEFAULT_PROFILE_SEGMENTS
) -> ArrayMesh:
	var front_x := depth * 0.5
	var back_x := -front_x
	var outline := equal_distance_superellipse(half, exponent, segment_count)
	var front: Array[Vector3] = []
	var back: Array[Vector3] = []
	var wall_normals: Array[Vector3] = []
	for point in outline:
		var y := point.x
		var z := point.y
		front.append(Vector3(front_x, y, z))
		back.append(Vector3(back_x, y, z))
		var ny := signf(y) * pow(absf(y), exponent - 1.0) / pow(half.x, exponent)
		var nz := signf(z) * pow(absf(z), exponent - 1.0) / pow(half.y, exponent)
		wall_normals.append(Vector3(0.0, ny, nz).normalized())
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in segment_count:
		var after := (index + 1) % segment_count
		for vertex in [Vector3(front_x, 0.0, 0.0), front[after], front[index]]:
			tool.set_normal(Vector3.RIGHT)
			tool.add_vertex(vertex)
		for vertex in [Vector3(back_x, 0.0, 0.0), back[index], back[after]]:
			tool.set_normal(Vector3.LEFT)
			tool.add_vertex(vertex)
		for pair in [
			[front[index], wall_normals[index]], [back[after], wall_normals[after]],
			[back[index], wall_normals[index]], [front[index], wall_normals[index]],
			[front[after], wall_normals[after]], [back[after], wall_normals[after]],
		]:
			tool.set_normal(pair[1])
			tool.add_vertex(pair[0])
	return tool.commit()


static func equal_distance_superellipse(
	half: Vector2, exponent: float, count: int
) -> Array[Vector2]:
	var dense_count := count * 12
	var dense: Array[Vector2] = []
	var cumulative: Array[float] = [0.0]
	for index in dense_count + 1:
		var angle := TAU * float(index) / float(dense_count)
		var ca := cos(angle)
		var sa := sin(angle)
		var point := Vector2(
			half.x * signf(ca) * pow(absf(ca), 2.0 / exponent),
			half.y * signf(sa) * pow(absf(sa), 2.0 / exponent)
		)
		dense.append(point)
		if index > 0:
			cumulative.append(cumulative[index - 1] + point.distance_to(dense[index - 1]))
	var perimeter := cumulative[cumulative.size() - 1]
	var result: Array[Vector2] = []
	var dense_index := 1
	for index in count:
		var target := perimeter * float(index) / float(count)
		while dense_index < cumulative.size() - 1 and cumulative[dense_index] < target:
			dense_index += 1
		var before_length := cumulative[dense_index - 1]
		var span := maxf(cumulative[dense_index] - before_length, 0.000001)
		result.append(dense[dense_index - 1].lerp(
			dense[dense_index], (target - before_length) / span
		))
	return result


## The live CSG remains hidden for collision if use_collision was enabled;
## callers receive a static, crease-corrected visual on the following frame.
static func bake_when_ready(
	csg: CSGCombiner3D, visual_parent: Node3D,
	crease_degrees: float = DEFAULT_CREASE_DEGREES
) -> void:
	await visual_parent.get_tree().process_frame
	if not is_instance_valid(csg):
		return
	var pieces: Array = csg.get_meshes()
	if pieces.size() < 2:
		return
	var baked_root := Node3D.new()
	baked_root.name = "%s_Baked" % csg.name
	baked_root.transform = csg.transform
	visual_parent.add_child(baked_root)
	for index in range(0, pieces.size() - 1, 2):
		var source := pieces[index + 1] as Mesh
		if source == null:
			continue
		var visual := MeshInstance3D.new()
		visual.name = "Surface%d" % (index / 2)
		visual.transform = pieces[index] as Transform3D
		visual.mesh = rebuild_crease_normals(source, crease_degrees)
		baked_root.add_child(visual)
		CollisionPolicy.mark_decorative(visual)
	csg.visible = false


static func rebuild_crease_normals(source: Mesh, crease_degrees: float) -> ArrayMesh:
	var result := ArrayMesh.new()
	var crease_dot := cos(deg_to_rad(crease_degrees))
	for surface_index in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface_index)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
		var indices := PackedInt32Array()
		if raw_indices != null:
			indices = raw_indices as PackedInt32Array
		var stream_size := indices.size() if not indices.is_empty() else vertices.size()
		var triangles: Array = []
		var neighbours: Dictionary = {}
		for triangle_index in int(stream_size / 3):
			var corners: Array[Vector3] = []
			for corner_index in 3:
				var stream_index := triangle_index * 3 + corner_index
				var vertex_index := indices[stream_index] if not indices.is_empty() else stream_index
				corners.append(vertices[vertex_index])
			var cross := (corners[1] - corners[0]).cross(corners[2] - corners[0])
			if cross.length_squared() < 0.000000001:
				continue
			var kept_index := triangles.size()
			triangles.append({"corners": corners, "normal": cross.normalized(), "area": cross.length() * 0.5})
			for point in corners:
				var key := _position_key(point)
				if not neighbours.has(key):
					neighbours[key] = []
				(neighbours[key] as Array).append(kept_index)
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for triangle in triangles:
			var face_normal: Vector3 = triangle["normal"]
			for point: Vector3 in triangle["corners"]:
				var accumulated := Vector3.ZERO
				for neighbour_index in neighbours[_position_key(point)]:
					var neighbour: Dictionary = triangles[neighbour_index]
					var neighbour_normal: Vector3 = neighbour["normal"]
					if face_normal.dot(neighbour_normal) >= crease_dot:
						accumulated += neighbour_normal * float(neighbour["area"])
				tool.set_normal(accumulated.normalized() if accumulated.length_squared() > 0.0 else face_normal)
				tool.add_vertex(point)
		tool.commit(result)
		var surface_material := source.surface_get_material(surface_index)
		if surface_material != null:
			result.surface_set_material(result.get_surface_count() - 1, surface_material)
	return result


static func _position_key(point: Vector3) -> Vector3i:
	return Vector3i(
		roundi(point.x * POSITION_WELD_SCALE),
		roundi(point.y * POSITION_WELD_SCALE),
		roundi(point.z * POSITION_WELD_SCALE)
	)
