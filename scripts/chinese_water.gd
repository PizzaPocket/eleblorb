extends RefCounted

## The two authored garden basins. One definition feeds the visual opening,
## physical bed, shoreline exit and the terrain's position-aware liquid API.
const PLAN := preload("res://scripts/chinese_plan.gd")
const CENTER := Vector2(250,-650)
const SURFACE := -0.18
const DEPTH := 2.20
static var _definitions: Array[Dictionary]=[]


static func definitions() -> Array[Dictionary]:
	if not _definitions.is_empty(): return _definitions
	for item in PLAN.ITEMS:
		if item.key not in ["inn_garden","pond_court"]: continue
		var inn: bool=item.key=="inn_garden"
		var offset := Vector2(1.2,-1.2) if inn else Vector2(0.5,-0.8)
		_definitions.append({"key":item.key,"island":item.island,"center":Vector2(item.centre[0],item.centre[1])+offset,"radii":Vector2(PLAN.GARDENS[item.key].pond_radii[0],PLAN.GARDENS[item.key].pond_radii[1]),"offset":offset})
	return _definitions


static func at(world: Vector2) -> Dictionary:
	for pond in definitions():
		var q: Vector2=(world-CENTER-pond.center)/pond.radii
		if q.length_squared()<1.0: return pond
	return {}


static func bed(pond: Dictionary, local: Vector2) -> float:
	var q: Vector2=(local-pond.center)/pond.radii
	var radius := q.length()
	var bottom := SURFACE-DEPTH
	var bank := lerpf(bottom,0.0,smoothstep(0.72,1.0,radius))
	# A 1.6 m wide submerged ramp leads west, with a gentle blend into the
	# basin. Its rise/run is <= 32 degrees in the smaller inn pond too.
	var dx: float=local.x-pond.center.x
	var dz: float=absf(local.y-pond.center.y)
	var ramp := lerpf(bottom,0.0,clampf((0.70-dx)/(float(pond.radii.x)+0.70),0,1))
	var ramp_weight := 1.0-smoothstep(0.8,1.2,dz)
	return lerpf(bank,maxf(bank,ramp),ramp_weight)


static func cut_floor(parent: Node3D, polygon: PackedVector2Array, ponds: Array[Dictionary], origin: Vector2, color: Color, label_text: String) -> CSGPolygon3D:
	var floor := CSGPolygon3D.new()
	floor.name=label_text
	floor.polygon=polygon
	floor.depth=0.35
	floor.position.y=-0.35 # CSGPolygon extrudes toward local -Z, upward after rotation.
	floor.rotation.x=PI*0.5
	floor.use_collision=true
	floor.collision_layer=1
	floor.collision_mask=0
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=1
	floor.material=material
	parent.add_child(floor)
	for pond in ponds:
		var cutter := CSGCylinder3D.new()
		cutter.name="PondBasinOpening"
		cutter.radius=1
		cutter.height=5
		cutter.sides=64
		cutter.operation=CSGShape3D.OPERATION_SUBTRACTION
		# Children use the polygon's XY plane; extrusion is local +Z.
		var at: Vector2=pond.center-origin
		cutter.position=Vector3(at.x,at.y,1)
		cutter.rotation.x=PI*0.5
		cutter.scale=Vector3(pond.radii.x,1,pond.radii.y)
		floor.add_child(cutter)
	return floor


static func build_bed(parent: Node3D, pond: Dictionary, local_origin: Vector2) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 24
	var sectors := 64
	for ring in rings:
		for sector in sectors:
			var vertices: Array[Vector3]=[]
			for corner in [Vector2(float(ring)/rings,float(sector)/sectors),Vector2(float(ring+1)/rings,float(sector)/sectors),Vector2(float(ring+1)/rings,float(sector+1)/sectors),Vector2(float(ring)/rings,float(sector+1)/sectors)]:
				var angle: float = corner.y*TAU
				var at: Vector2=pond.center+Vector2(cos(angle)*pond.radii.x,sin(angle)*pond.radii.y)*corner.x
				vertices.append(Vector3(at.x-local_origin.x,bed(pond,at),at.y-local_origin.y))
			for triangle in [[0,1,2],[0,2,3]]:
				if (vertices[triangle[1]]-vertices[triangle[0]]).cross(vertices[triangle[2]]-vertices[triangle[0]]).length_squared()<0.00000001: continue
				for index in triangle: st.add_vertex(vertices[index])
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name="PondBasinBed"
	mesh.mesh=st.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(0.33,0.35,0.29)
	material.roughness=0.9
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=material
	parent.add_child(mesh)
	var body := StaticBody3D.new()
	body.name="PondBasinCollision"
	var shape := CollisionShape3D.new()
	shape.shape=mesh.mesh.create_trimesh_shape()
	shape.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(shape)
	parent.add_child(body)
	mesh.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
