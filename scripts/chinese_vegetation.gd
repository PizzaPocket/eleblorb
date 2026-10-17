extends RefCounted

## Repeated plants share geometry and materials. Each field/clump is a separate
## batch so visibility bounds remain local instead of spanning the settlement.
const BAKE := preload("res://scripts/settlement_bake.gd")
static var _meshes: Dictionary = {}
static var _material: StandardMaterial3D


static func crop_mesh(species: String) -> ArrayMesh:
	if _meshes.has(species):
		return _meshes[species]
	var stem := Color(0.36,0.47,0.22) if species != "wheat" else Color(0.45,0.48,0.22)
	var head := Color(0.72,0.61,0.31) if species == "millet" else (Color(0.79,0.68,0.38) if species == "wheat" else Color(0.43,0.57,0.29))
	var parts: Array = []
	_piece(parts,Vector3(0.025,0.5,0.025),Vector3(0,0.5,0),stem,0.0,2.0)
	if species == "soy":
		for i in 4:
			var angle := float(i)*TAU/4.0
			_piece(parts,Vector3(0.11,0.045,0.21),Vector3(cos(angle)*0.12,0.42,sin(angle)*0.12),head,angle)
	else:
		_piece(parts,Vector3(0.095,0.14,0.095),Vector3(0,0.91,0),head)
		for i in 2:
			_piece(parts,Vector3(0.06,0.035,0.20),Vector3(0,0.38+i*0.17,0),stem.lightened(0.1),-0.5 if i==0 else 0.5)
	_meshes[species] = StaticMerge._build_mesh(parts)
	return _meshes[species]


static func _piece(parts: Array, half: Vector3, at: Vector3, color: Color, yaw: float = 0.0, epsilon: float = 2.7) -> void:
	parts.append([SuperEgg.build_mesh(half,epsilon,epsilon,6,8),Transform3D(Basis(Vector3.UP,yaw),at),color])


static func batch(parent: Node3D, label_text: String, mesh: Mesh, transforms: Array[Transform3D], origin: Vector3, distance: float = 160.0) -> MultiMeshInstance3D:
	var node := MultiMeshInstance3D.new()
	node.name = label_text
	node.position = origin
	var instances := MultiMesh.new()
	instances.transform_format = MultiMesh.TRANSFORM_3D
	instances.mesh = mesh
	instances.instance_count = transforms.size()
	node.multimesh = instances
	BAKE.store_instance_data(node,transforms)
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.92
	node.material_override = _material
	node.visibility_range_end = distance
	node.visibility_range_end_margin = 15.0
	CollisionPolicy.mark_decorative(node)
	parent.add_child(node)
	return node


static func colored_mesh(half: Vector3, color: Color, epsilon: float = 2.0) -> ArrayMesh:
	var key := str(half)+str(color)+str(epsilon)
	if not _meshes.has(key):
		_meshes[key] = StaticMerge._build_mesh([[SuperEgg.build_mesh(half,epsilon,epsilon,8,10),Transform3D.IDENTITY,color]])
	return _meshes[key]
