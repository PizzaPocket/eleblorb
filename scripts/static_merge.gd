class_name StaticMerge
extends RefCounted

## Bakes a finished, static structure's many small pieces into a few meshes.
##
## Settlements are built from SuperEgg parts: every post, baluster, jar and
## cushion is its own MeshInstance3D with its own material, so one stilt house
## is several hundred draw calls and a village several thousand. Once a
## building is placed and nothing about its pieces will change, this merges
## every plain opaque piece into one mesh per material class (roughness,
## metallic, culling), carrying each piece's colour in its vertices. Colliders
## are untouched: they are separate nodes.
##
## Left alone, because they change or are drawn differently: anything under a
## node with a script (doors, NPCs, interactables), physics bodies that move,
## emissive, translucent or textured materials (lamp shades, glass), meshes
## that already use vertex colour, MultiMesh foliage and planking, and any
## node tagged `no_merge`.
##
## Run it on the placed structure, after every audit that reads pieces (the
## building proof audits unmerged builds).

const NO_MERGE_META := "no_merge"
## Pieces whose longest side is under this cast no sun shadow once merged.
const SMALL_PIECE := 0.5
## Off only to measure the difference (tools/scene_cost_probe.tscn --no-merge).
static var enabled := true
## Counts the physical (solid or parkour) pieces folded into a merged mesh, so
## CollisionPolicy.validate_body still pairs them with their colliders.
const MERGED_PHYSICAL_META := "merged_physical"


## Merges `root`'s static pieces in place; returns how many were merged.
static func merge(root: Node3D) -> int:
	if not enabled:
		return 0
	var groups := {}
	var merged: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var piece := node as MeshInstance3D
		if not _mergeable(root, piece):
			continue
		var material := _material(piece)
		# Small pieces (jars, charms, cushions, pegs) cast no sun shadow: theirs
		# fall indoors or are a few centimetres across, yet every shadow split
		# was drawing them again.
		var extent := piece.mesh.get_aabb().size * _xform_in(root, piece).basis.get_scale()
		var small := maxf(extent.x, maxf(extent.y, extent.z)) < SMALL_PIECE
		var key := "%.2f|%.2f|%d|%s" % [snappedf(material.roughness, 0.05), snappedf(material.metallic, 0.05), material.cull_mode, small]
		if not groups.has(key):
			groups[key] = {"pieces": [], "material": material, "physical": 0, "small": small}
		var group: Dictionary = groups[key]
		(group["pieces"] as Array).append([piece.mesh, _xform_in(root, piece), material.albedo_color])
		var policy := piece.get_meta(CollisionPolicy.POLICY_META, &"") as StringName
		if policy in [CollisionPolicy.SOLID, CollisionPolicy.PARKOUR]:
			group["physical"] = int(group["physical"]) + 1
		merged.append(piece)
	if merged.is_empty():
		return 0
	var index := 0
	for key: String in groups:
		var group: Dictionary = groups[key]
		var mesh := _build_mesh(group["pieces"])
		if mesh == null:
			continue
		var source: StandardMaterial3D = group["material"]
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		# Piece colours are authored in sRGB, like albedo_color.
		material.vertex_color_is_srgb = true
		material.roughness = source.roughness
		material.metallic = source.metallic
		material.metallic_specular = source.metallic_specular
		material.cull_mode = source.cull_mode
		var instance := MeshInstance3D.new()
		instance.name = "Merged%d" % index
		instance.mesh = mesh
		instance.material_override = material
		if bool(group["small"]):
			instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if int(group["physical"]) > 0:
			instance.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
			instance.set_meta(MERGED_PHYSICAL_META, int(group["physical"]))
		else:
			CollisionPolicy.mark_decorative(instance)
		root.add_child(instance)
		index += 1
	for piece in merged:
		piece.get_parent().remove_child(piece)
		piece.free()
	return merged.size()


static func _mergeable(root: Node3D, piece: MeshInstance3D) -> bool:
	if piece.mesh == null or not piece.visible or piece.has_meta(NO_MERGE_META):
		return false
	if piece.get_script() != null or piece.get_child_count() > 0:
		return false
	if piece.mesh.get_surface_count() != 1 or piece.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
		return false
	var material := _material(piece)
	if material == null:
		return false
	if material.emission_enabled or material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or material.albedo_color.a < 0.999:
		return false
	if material.albedo_texture != null or material.vertex_color_use_as_albedo or material.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL:
		return false
	var current: Node = piece.get_parent()
	while current != null and current != root:
		if current.get_script() != null or current is RigidBody3D or current is CharacterBody3D or current is AnimatableBody3D or current is Area3D or current.has_meta(NO_MERGE_META):
			return false
		current = current.get_parent()
	return current == root


static func _material(piece: MeshInstance3D) -> StandardMaterial3D:
	var material: Material = piece.material_override
	if material == null:
		material = piece.get_surface_override_material(0)
	if material == null and piece.mesh != null:
		material = piece.mesh.surface_get_material(0)
	return material as StandardMaterial3D


static func _xform_in(root: Node3D, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform


## One mesh from every [mesh, transform, colour] piece: sizes counted first and
## each array filled once (packed arrays copy on write, so growing them piece
## by piece through a dictionary would copy the whole building every time).
static func _build_mesh(pieces: Array) -> ArrayMesh:
	var sources: Array = []
	var vertex_total := 0
	var index_total := 0
	for entry: Array in pieces:
		var mesh: Mesh = entry[0]
		# Primitive meshes (boxes, cylinders) are always triangles.
		if mesh is ArrayMesh and (mesh as ArrayMesh).surface_get_primitive_type(0) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays := mesh.surface_get_arrays(0)
		var source_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		if source_vertices.is_empty() or source_normals.size() != source_vertices.size():
			continue
		var source_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if source_indices.is_empty():
			source_indices.resize(source_vertices.size() - source_vertices.size() % 3)
			for i in source_indices.size():
				source_indices[i] = i
		sources.append([source_vertices, source_normals, source_indices, entry[1], entry[2]])
		vertex_total += source_vertices.size()
		index_total += source_indices.size()
	if vertex_total == 0:
		return null
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	vertices.resize(vertex_total)
	normals.resize(vertex_total)
	colors.resize(vertex_total)
	indices.resize(index_total)
	var v := 0
	var k := 0
	for source: Array in sources:
		var source_vertices: PackedVector3Array = source[0]
		var source_normals: PackedVector3Array = source[1]
		var source_indices: PackedInt32Array = source[2]
		var xform: Transform3D = source[3]
		var color: Color = source[4]
		var normal_basis := xform.basis.inverse().transposed()
		# A mirrored transform flips the winding; swap two corners to keep
		# faces outward.
		var mirrored := xform.basis.determinant() < 0.0
		for i in source_vertices.size():
			vertices[v + i] = xform * source_vertices[i]
			normals[v + i] = (normal_basis * source_normals[i]).normalized()
			colors[v + i] = color
		for i in range(0, source_indices.size() - 2, 3):
			indices[k + i] = v + source_indices[i]
			indices[k + i + 1] = v + source_indices[i + (2 if mirrored else 1)]
			indices[k + i + 2] = v + source_indices[i + (1 if mirrored else 2)]
		v += source_vertices.size()
		k += source_indices.size()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
