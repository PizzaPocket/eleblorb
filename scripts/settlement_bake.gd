extends RefCounted

## Static settlement authoring happens in tools, never at the player's first
## approach. Moving doors are recreated from their constructor data so their
## interaction callbacks and collision remain live after loading a bake.
const DOOR := preload("res://scripts/world_door.gd")
const CACHE_PATH := "res://assets/generated/chinese_village.scn"
const SOURCES := [
	"chinese_plan.gd","chinese_village_plan_builder.gd","chinese_architecture.gd",
	"chinese_vegetation.gd","chinese_infrastructure.gd","chinese_water.gd","nature_props.gd","ground_paint.gd","village_works.gd","town_props.gd","superegg.gd","solid_model.gd",
	"opening_trim.gd","furnishings.gd","trade_furnishings.gd","static_merge.gd","collision_policy.gd",
	"world_door.gd","ocean_water.gdshader","settlement_bake.gd",
]


static func signature() -> String:
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	for filename in SOURCES:
		hash_context.update(FileAccess.get_file_as_bytes("res://scripts/"+filename))
	return hash_context.finish().hex_encode()


static func valid() -> bool:
	if not FileAccess.file_exists(CACHE_PATH+".sha256"):
		return false
	return FileAccess.get_file_as_string(CACHE_PATH+".sha256").strip_edges()==signature() and ResourceLoader.exists(CACHE_PATH)


static func prepare(root: Node3D) -> void:
	# Call only after CSG has had its deferred construction frames.
	for node in root.find_children("*","CSGShape3D",true,false):
		if not is_instance_valid(node) or not node.is_root_shape():
			continue
		var csg := node as CSGShape3D
		var replacement := Node3D.new()
		replacement.name=csg.name
		replacement.transform=csg.transform
		var visual := MeshInstance3D.new()
		visual.name="BakedSurface"
		visual.mesh=csg.bake_static_mesh()
		visual.layers=csg.layers
		replacement.add_child(visual)
		if csg.use_collision:
			var body := StaticBody3D.new()
			body.collision_layer=csg.collision_layer
			body.collision_mask=csg.collision_mask
			var collider := CollisionShape3D.new()
			collider.shape=csg.bake_collision_shape()
			collider.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
			body.add_child(collider)
			replacement.add_child(body)
			visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
		else:
			CollisionPolicy.mark_decorative(visual)
		var parent := csg.get_parent()
		parent.remove_child(csg)
		csg.free()
		parent.add_child(replacement)
	for node in root.find_children("*","Node3D",true,false):
		if not is_instance_valid(node): continue
		if node.name=="PalaceStateFurniture":
			node.get_parent().remove_child(node)
			node.free()
		elif node.get_script()==DOOR:
			var placeholder := Node3D.new()
			placeholder.name=node.name
			placeholder.transform=node.transform
			placeholder.set_meta("door_configuration",node.get_meta("door_configuration"))
			var parent := node.get_parent()
			parent.remove_child(node)
			node.free()
			parent.add_child(placeholder)
	CollisionPolicy.fit_sheared_static_boxes(root)
	# Merge per authored structure or bridge, retaining useful culling bounds.
	for child in root.get_children():
		if child is Node3D and (String(child.name).begins_with("PlanItem_") or String(child.name).begins_with("Bridge_") or String(child.name).begins_with("MarbleBalustrade")):
			StaticMerge.merge(child)
	var indexed := {}
	for node in root.find_children("*","GeometryInstance3D",true,false):
		var mesh: Mesh=null
		if node is MeshInstance3D: mesh=node.mesh
		elif node is MultiMeshInstance3D: mesh=node.multimesh.mesh
		if not mesh is ArrayMesh: continue
		var key := mesh.get_instance_id()
		if not indexed.has(key):
			var result := ArrayMesh.new()
			for surface in mesh.get_surface_count():
				var st := SurfaceTool.new()
				st.create_from(mesh,surface)
				st.index()
				st.commit(result)
				result.surface_set_material(surface,mesh.surface_get_material(surface))
			indexed[key]=result
		if node is MeshInstance3D: node.mesh=indexed[key]
		else: node.multimesh.mesh=indexed[key]
	_set_owners(root,root)
	root.set_meta("bake_signature",signature())


static func _set_owners(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner=root
		_set_owners(child,root)


static func restore_doors(root: Node3D) -> void:
	for node in root.find_children("*","Node3D",true,false):
		if node.has_meta("door_configuration"):
			var args: Array=node.get_meta("door_configuration")
			node.set_script(DOOR)
			node.callv("configure",args)
			node.fit_to_parent()


## The headless rendering backend does not retain MultiMesh server buffers.
## Preserve CPU-authored data as resource metadata so headless bakes cannot
## silently serialize zero transforms. Also survives mesh reindexing.
static func store_instance_data(node: MultiMeshInstance3D, transforms: Array[Transform3D]) -> void:
	var buffer := PackedFloat32Array()
	buffer.resize(transforms.size()*12)
	var bounds := AABB()
	var mesh_bounds := node.multimesh.mesh.get_aabb()
	for i in transforms.size():
		var t := transforms[i]
		var values := [t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x,t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y,t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z]
		for j in 12: buffer[i*12+j]=values[j]
		var instance_bounds: AABB=t*mesh_bounds
		bounds=instance_bounds if i==0 else bounds.merge(instance_bounds)
	node.set_meta("baked_instance_buffer",buffer)
	node.set_meta("baked_instance_bounds",bounds)
	node.multimesh.buffer=buffer
	node.custom_aabb=bounds


static func restore_instances(root: Node3D) -> void:
	for node in root.find_children("*","MultiMeshInstance3D",true,false):
		if not node.has_meta("baked_instance_buffer"): continue
		node.multimesh.buffer=node.get_meta("baked_instance_buffer")
		node.custom_aabb=node.get_meta("baked_instance_bounds")
