extends RefCounted

const WATER := preload("res://scripts/chinese_water.gd")
const PLAN := preload("res://scripts/chinese_plan.gd")
const A := preload("res://scripts/chinese_architecture.gd")
const STONE := Color(0.43,0.44,0.41)
const TIMBER := Color(0.24,0.17,0.11)
const TILE := Color(0.28,0.31,0.29)

## An actual arch barrel, with masonry above its curved intrados. No solid
## lintel crosses the walkable opening; the upper chamber bears on the piers.
static func gatehouse(width: float, depth: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name="PlanStructure"
	body.collision_layer=1
	body.set_meta("passage_width",4.0)
	body.set_meta("passage_crown",3.2)
	A.block(body,"EastMasonryPier",Vector3(4,3.6,depth),Vector3(4,1.8,0),STONE,true,false)
	# West pier is a hollow masonry stair chamber. Its ramp rises northward
	# beside the public passage; a matching floor opening gives real headroom.
	A.block(body,"WestOuterPierWall",Vector3(0.5,3.6,depth),Vector3(-5.75,1.8,0),STONE,true,false)
	A.block(body,"WestInnerPierWall",Vector3(0.5,3.6,depth),Vector3(-2.25,1.8,0),STONE,true,false)
	A.block(body,"WestRearPierWall",Vector3(3.5,3.6,0.5),Vector3(-4,1.8,-depth*0.5+0.25),STONE,true,false)
	var door: Array[Dictionary]=[{"kind":"door","center":0.0,"width":1.6,"bottom":0.0,"top":2.5,"leaves":1,"exponent":5.5,"interior":true}]
	TownProps._build_panel_facade(body,4,Vector3(-4,0,depth*0.5),PI,STONE,door,0.0,3.6,0.5)
	for opening in door: TownProps._build_panel_opening_trim(body,Vector3(-4,0,depth*0.5),PI,opening,0.0,TIMBER,0.5,Color(0.12,0.10,0.09))
	_arch_barrel(body,4.0,depth,1.2,3.6)
	A.block(body,"GatePassagePaving",Vector3(4,0.10,depth+0.4),Vector3(0,0.05,0),Color(0.46,0.45,0.41),true,false)
	var ramp_size := Vector3(1.6,0.18,sqrt(6.2*6.2+3.6*3.6))
	var ramp := A.block(body,"GatekeeperRamp",ramp_size,Vector3(-4,1.8-0.09/cos(atan2(3.6,6.2)),0.9),STONE,false,false)
	ramp.rotation.x=atan2(3.6,6.2)
	CollisionPolicy.add_box(body,ramp,ramp_size,ramp.position,ramp.basis,true)
	ClearZones.add_lane(body,"gatekeeper chamber access",[Vector3(-4,0,depth*0.5+0.65),Vector3(-4,0,4.0),Vector3(-4,3.6,-2.2),Vector3(-4,3.6,-3.1),Vector3(0,3.6,-3.1)])
	for floor_piece in [Vector4(1.25,0,8.5,9),Vector4(-5.25,0,0.5,9),Vector4(-4,-3.35,2,2.3),Vector4(-4,4.25,2,0.5)]:
		A.block(body,"UpperChamberFloor",Vector3(floor_piece.z,0.22,floor_piece.w),Vector3(floor_piece.x,3.49,floor_piece.y),TIMBER,true,false)
	for side in [-1.0,1.0]:
		var front := Vector3(0,3.6,side*4.5)
		var yaw := 0.0 if side<0 else PI
		var windows: Array[Dictionary]=[]
		for x in [-2.4,2.4]: windows.append({"kind":"window","center":x,"width":2.5,"bottom":4.4,"top":5.8,"leaves":0,"exponent":5.5,"lattice":true,"shutter_style":"lattice"})
		TownProps._build_panel_facade(body,11,front,yaw,Color(0.84,0.82,0.75),windows,3.6,2.8,0.25)
		for opening in windows: TownProps._build_panel_opening_trim(body,front,yaw,opening,3.6,TIMBER,0.25,Color(0.12,0.10,0.09))
		A.block(body,"UpperGableWall",Vector3(0.25,2.8,9),Vector3(side*5.5,5,0),Color(0.84,0.82,0.75),true,false)
		for i in 5: A.block(body,"UpperTimberPost",Vector3(0.22,2.8,0.22),Vector3(-5.5+float(i)*2.75,5,side*4.6),TIMBER,true)
	A._frustum(body,5.65,5.3,5.65,0.001,6.4,2,TILE,"GatehouseHardGable",STONE)
	var bed := TownProps.build_bed(Color(0.28,0.37,0.44))
	bed.position=Vector3(3.8,3.6,-2.8)
	body.add_child(bed)
	A.block(body,"GatekeeperStorageChest",Vector3(0.95,0.62,0.65),Vector3(3.8,3.91,-0.8),TIMBER,true)
	# Masonry and timber corners finish the exposed wall ends. The passage is
	# never crossed by a decorative plinth or a horizontal weathering course.
	for sx in [-1.0,1.0]:
		for sz in [-1.0,1.0]:
			A.block(body,"MasonryCornerPier",Vector3(0.52,3.72,0.52),Vector3(sx*5.83,1.82,sz*(depth*0.5-0.12)),STONE.lightened(0.09),true)
			A.block(body,"KeeperCornerPost",Vector3(0.30,2.85,0.30),Vector3(sx*5.5,5.0,sz*4.5),TIMBER,true)
	for side in [-1.0,1.0]:
		A.block(body,"PierFootingSide",Vector3(0.35,0.38,depth+0.18),Vector3(side*5.92,0.11,0),STONE.darkened(0.15),true)
		A.block(body,"PierWeatheringSide",Vector3(0.40,0.20,depth+0.2),Vector3(side*5.90,3.55,0),STONE.lightened(0.13),true)
		A.block(body,"KeeperEaveBeam",Vector3(11.5,0.27,0.30),Vector3(0,6.3,side*4.55),TIMBER,true)
		for edge in [-1.0,1.0]:
			if side>0.0 and edge<0.0:
				# The west chamber has a door here. Its weathering course must
				# stop at the jambs instead of becoming a bar across the threshold.
				for span in [Vector2(-6.0,-4.9),Vector2(-3.1,-2.14)]:
					A.block(body,"ChamberDoorFooting",Vector3(span.y-span.x,0.38,0.38),Vector3((span.x+span.y)*0.5,0.11,side*depth*0.5),STONE.darkened(0.15),true)
			else:
				A.block(body,"PierFootingFront",Vector3(3.86,0.38,0.38),Vector3(edge*4.07,0.11,side*depth*0.5),STONE.darkened(0.15),true)
		A.block(body,"GateWeatheringCourse",Vector3(12.2,0.20,0.42),Vector3(0,3.55,side*depth*0.5),STONE.lightened(0.13),true)
	A.block(body,"GatehouseRidgeCap",Vector3(11.8,0.30,0.40),Vector3(0,8.45,0),TILE,false)
	var arch_outline: Array[Vector2]=[Vector2(-2,-0.1),Vector2(-2,1.2)]
	for i in 65:
		var angle := PI-PI*float(i)/64.0
		arch_outline.append(Vector2(cos(angle)*2,1.2+sin(angle)*2))
	arch_outline.append(Vector2(2,-0.1))
	for side in [-1.0,1.0]:
		var surround := OpeningTrim.piped_frame(arch_outline,0.12,STONE.lightened(0.14),false,Vector2(0,1.2))
		surround.name="GateArchSurround"
		surround.position.z=side*(depth*0.5+0.025)
		body.add_child(surround)
	var reveal := OpeningTrim.reveal_liner(arch_outline,depth*0.5,STONE.lightened(0.06),Vector2(0,1.2),0.998,false)
	reveal.name="GateArchReveal"
	body.add_child(reveal)
	var masonry := A.masonry_material(STONE)
	for visual in body.get_children():
		if visual is MeshInstance3D and (String(visual.name).contains("MasonryPier") or String(visual.name).contains("PierWall") or String(visual.name).begins_with("ArchBarrel")):
			visual.material_override=masonry
	return body


static func _arch_barrel(body: StaticBody3D, passage: float, depth: float, spring: float, top: float) -> void:
	var radius := passage*0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		var x0 := -radius+passage*float(i)/64.0
		var x1 := -radius+passage*float(i+1)/64.0
		var y0 := spring+sqrt(maxf(0,radius*radius-x0*x0))
		var y1 := spring+sqrt(maxf(0,radius*radius-x1*x1))
		var polygon := PackedVector2Array([Vector2(x0,y0),Vector2(x1,y1),Vector2(x1,top),Vector2(x0,top)])
		var vertices := PackedVector3Array()
		for z in [-depth*0.5,depth*0.5]:
			for p in polygon: vertices.append(Vector3(p.x,p.y,z))
		for tri in [[0,2,1],[0,3,2],[4,5,6],[4,6,7],[0,1,5],[0,5,4],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,0,4],[3,4,7]]:
			for index in tri: st.add_vertex(vertices[index])
		var shape := CollisionShape3D.new()
		var hull := ConvexPolygonShape3D.new()
		hull.points=vertices
		shape.shape=hull
		body.add_child(shape)
		shape.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)

	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name="ArchBarrelVoussoirs"
	mesh.mesh=st.commit()
	mesh.material_override=A.masonry_material(STONE)
	body.add_child(mesh)
	mesh.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	mesh.set_meta(StaticMerge.MERGED_PHYSICAL_META,64)


static func anchorage(parent: Node3D, at: Vector3, direction: Vector2, width: float) -> void:
	var portal := StaticBody3D.new()
	portal.name="ChainAnchoragePortal"
	portal.position=at
	portal.rotation.y=atan2(direction.x,direction.y)
	parent.add_child(portal,true)
	for side in [-1.0,1.0]:
		A.block(portal,"AnchoragePier",Vector3(1.6,4.2,5),Vector3(side*(width*0.5+1.1),2.1,0),STONE,true)
		A.block(portal,"ChainAnchorPlate",Vector3(0.30,0.7,0.22),Vector3(side*(width*0.5+0.20),1.05,2.50),Color(0.19,0.20,0.19),false)
		# The bridge rail ends at inner X=(width-.18)/2, Y=1.14. A forged
		# eye and dogleg connect it into the masonry plate rather than leaving
		# a 29 cm air gap between chain and anchorage.
		var iron:=Color(0.19,0.20,0.19)
		var inner_x: float=side*(width-0.18)*0.5
		var plate_x: float=side*(width*0.5+0.20)
		var eye:=MeshInstance3D.new()
		eye.name="ChainTerminalEye"
		eye.mesh=OpeningTrim.piped_mesh(OpeningTrim.window_loop(0.11,0.07,3.2,24),0.027,true)
		var mat:=StandardMaterial3D.new();mat.albedo_color=iron;mat.metallic=0.35
		eye.material_override=mat
		eye.position=Vector3(inner_x,1.14,2.50)
		eye.rotation.y=PI*0.5
		portal.add_child(eye)
		CollisionPolicy.mark_decorative(eye)
		A.block(portal,"ForgedAnchorTail",Vector3(absf(plate_x-inner_x)+0.10,0.075,0.12),Vector3((inner_x+plate_x)*0.5,1.14,2.50),iron,false)
		portal.set_meta("terminal_rail_height",1.14)
	A.block(portal,"AnchorageLintel",Vector3(width+3.8,0.8,5),Vector3(0,3.8,0),STONE,true)
	A._frustum(portal,(width+4.6)*0.5,3.0,(width+4.6)*0.5,0.001,4.2,1.4,TILE,"AnchorageHardGable",STONE)
	portal.set_meta("clear_width",width+0.6)


static func garden(parent: Node3D, width: float, depth: float, key: String) -> void:
	var court := parent
	var structure := StaticBody3D.new()
	structure.name="GardenLandscape"
	parent.add_child(structure)
	parent=structure
	var inn := key=="inn_garden"
	var pond_center := Vector2(1.2,-1.2) if inn else Vector2(0.5,-0.8)
	var radii := Vector2(PLAN.GARDENS[key].pond_radii[0],PLAN.GARDENS[key].pond_radii[1])
	var layout: Dictionary=PLAN.GARDENS[key]
	var pavilion_at := Vector3(layout.pavilion[0],layout.pavilion[1],layout.pavilion[2])
	var pine_at := Vector3(layout.pine[0],layout.pine[1],layout.pine[2])
	court.set_meta("garden_pavilion",pavilion_at)
	court.set_meta("garden_pine",pine_at)
	court.set_meta("pond_radii",radii)
	var pond := MeshInstance3D.new()
	pond.name="LotusPondWater"
	# One two-sided water surface, like the game's lakes. A closed cylinder
	# composites two translucent caps and makes clear water look opaque.
	var disc := SurfaceTool.new()
	disc.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 64:
		var a := TAU*float(i)/64.0
		var b := TAU*float(i+1)/64.0
		for point in [Vector3.ZERO,Vector3(cos(a),0,sin(a)),Vector3(cos(b),0,sin(b))]:
			disc.set_normal(Vector3.UP)
			disc.set_uv(Vector2(point.x,point.z)*0.5+Vector2.ONE*0.5)
			disc.add_vertex(point)
	pond.mesh=disc.commit()
	pond.scale=Vector3(radii.x,1,radii.y)
	pond.position=Vector3(pond_center.x,WATER.SURFACE,pond_center.y)
	var pond_material := VillageWorks.water_material()
	pond_material.set_shader_parameter("surface_color",Color(0.16,0.39,0.35,0.57))
	pond_material.set_shader_parameter("ripple_frequency",24.0)
	pond_material.set_shader_parameter("ripple_normal",0.055)
	pond.material_override=pond_material
	pond.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(pond)
	CollisionPolicy.mark_hazard(pond)
	pond.set_meta("water_surface_y",WATER.SURFACE)
	pond.set_meta("water_depth",WATER.DEPTH)
	for definition in WATER.definitions():
		if definition.key==key:
			WATER.build_bed(parent,definition,definition.center-pond_center)
	# Unequal shoreline groups leave quiet shelving stretches between them.
	# The west swimming exit is deliberately left unobstructed.
	var shore := [[-2.45,1.05],[-1.84,0.75],[-1.66,0.58],[-0.60,1.15],[-0.37,0.65],[0.40,0.82],[0.58,0.55],[1.42,1.0],[1.68,0.65],[2.10,0.85]]
	for i in shore.size():
		var angle: float=shore[i][0]
		var scale_stone: float=shore[i][1]
		var at := Vector3(pond_center.x+cos(angle)*(radii.x+0.06),-0.06,pond_center.y+sin(angle)*(radii.y+0.06))
		var size := Vector3(1.10*scale_stone,0.34*scale_stone,0.78*scale_stone)
		var stone := A.block(parent,"ShelvingPondStone",size,at,STONE.lightened(float(i%3)*0.025),false)
		stone.rotation.y=-angle+0.15*sin(float(i)*4.1)
		CollisionPolicy.add_box(structure,stone,size,at,stone.basis,true)
	var route: Array[Vector3]=[]
	for point in layout.crossing: route.append(Vector3(point[0],point[1],point[2]))
	for i in (9 if inn else 14):
		var angle := float(i)*2.4
		var d := 0.3+float(i%3)*0.22
		var at := Vector3(pond_center.x+cos(angle)*radii.x*d,WATER.SURFACE+0.035,pond_center.y+sin(angle)*radii.y*d)
		var clear := true
		for segment in route.size()-1:
			if Geometry2D.get_closest_point_to_segment(Vector2(at.x,at.z),Vector2(route[segment].x,route[segment].z),Vector2(route[segment+1].x,route[segment+1].z)).distance_to(Vector2(at.x,at.z))<0.95: clear=false
		if not clear: continue
		var pad := SuperEgg.build_part(Vector3(0.27,0.025,0.23),Color(0.26,0.46,0.27),2.0,2.0,6,20)
		pad.name="LotusPad"
		pad.position=at
		pad.rotation.y=angle
		parent.add_child(pad)
		CollisionPolicy.mark_decorative(pad)
		if i%3==0: A.block(parent,"LotusFlower",Vector3(0.24,0.22,0.22),at+Vector3(0.12,0.14,0),Color(0.89,0.54,0.62),false)
	# Offset the whole route once: bends are mitered/rounded in one footprint,
	# rather than overlapping independent rounded slabs.
	_garden_crossing(structure,layout,pond_center,radii)
	var pine := NatureProps.build_chinese_pine(3.36,1101 if inn else 1102)
	pine.position=pine_at
	parent.add_child(pine)
	# The pavilion itself is built by the caller's shared hexagonal builder.
	var rock_at := Vector3(width*0.5-2.2,0,-depth*0.5+2.2)
	_limestone(parent,rock_at,Vector3(1.05,1.48,0.75),0.18,"RockeryAnchor")
	_limestone(parent,rock_at+Vector3(-0.85,0,0.30),Vector3(0.65,0.72,0.62),-0.35,"RockeryShoulder")
	_limestone(parent,rock_at+Vector3(0.50,0,0.68),Vector3(0.52,0.45,0.62),0.50,"RockeryFoot")
	var mouth := rock_at+Vector3(-0.65,1.55,0.55)
	VillageWorks.build_fall(parent,mouth,Vector2(-0.8,0.6),0.65,0.45,WATER.SURFACE,"GardenWaterfall")
	var scholar := Vector3(-width*0.5+2.2,0,depth*0.5-2.2) if inn else Vector3(width*0.5-1.9,0,depth*0.5-1.6)
	A.block(parent,"ScholarStonePlinth",Vector3(0.95,0.4,0.85),scholar+Vector3(0,0.2,0),STONE,true)
	_limestone(parent,scholar+Vector3(0,0.4,0),Vector3(0.36,0.90,0.31),-0.20,"ScholarsRock")


## Joined crossing with a rounded plan and a bevelled, closed stone section.
static func _garden_crossing(parent: StaticBody3D, layout: Dictionary, pond_center: Vector2, radii: Vector2) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in layout.walk_vertices: st.add_vertex(Vector3(p[0],p[1],p[2]))
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name="LotusPondBridge"
	mesh.mesh=st.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(0.55,0.54,0.49)
	material.roughness=0.90
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=material
	parent.add_child(mesh)
	var shape := CollisionShape3D.new()
	shape.shape=mesh.mesh.create_trimesh_shape()
	shape.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	mesh.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	parent.add_child(shape)
	var supports: Array[Vector3]=[]
	for i in layout.crossing.size():
		var p: Array=layout.crossing[i]
		supports.append(Vector3(p[0],p[1],p[2]))
		if i>0:
			var last: Array=layout.crossing[i-1]
			supports.append(Vector3((p[0]+last[0])*0.5,(p[1]+last[1])*0.5,(p[2]+last[2])*0.5))
	for p in layout.approach: supports.append(Vector3(p[0],p[1],p[2]))
	for p in supports:
		var q := (Vector2(p.x,p.z)-pond_center)/radii
		if q.length()>0.90: continue
		var foot := -2.4
		var bearing_y := p.y-0.11
		A.block(parent,"PondBridgePier",Vector3(0.30,bearing_y-foot,0.40),Vector3(p.x,(foot+bearing_y)*0.5,p.z),STONE,true)
		A.block(parent,"PondBridgeBearing",Vector3(0.48,0.13,0.65),Vector3(p.x,bearing_y-0.02,p.z),STONE.lightened(0.05),true)


## A perforated limestone mass with a tapered crown and weathered cavities.
## Holes are genuine subtractions and are baked with their collision.
static func _limestone(parent: Node3D, at: Vector3, half: Vector3, yaw: float, label_text: String) -> void:
	var rock := CSGCombiner3D.new()
	rock.name=label_text
	rock.position=at
	rock.rotation.y=yaw
	rock.use_collision=true
	rock.collision_layer=1
	rock.collision_mask=0
	parent.add_child(rock)
	var material := SolidModel.material(STONE.lightened(0.07),0.90,0.0)
	var mass := SolidModel.add_super(rock,"WeatheredStandingMass",Vector3(half.x*0.86,half.y,half.z*0.80),CSGShape3D.OPERATION_UNION,material,Vector3(0,half.y,0),2.4,24,32)
	mass.rotation.z=-0.12
	SolidModel.add_super(rock,"ShoulderWeathering",Vector3(half.x*0.65,half.y*0.48,half.z*1.6),CSGShape3D.OPERATION_SUBTRACTION,material,Vector3(-half.x*0.85,half.y*1.65,0),2.3,16,24)
	var lower_hole := SolidModel.add_profile(rock,"WeatheredAperture",half.z*3.0,Vector2(half.y*0.27,half.x*0.32),2.7,CSGShape3D.OPERATION_SUBTRACTION,material,Vector3(-half.x*0.16,half.y*0.65,0),40)
	lower_hole.rotation.y=PI*0.5
	var upper_hole := SolidModel.add_profile(rock,"UpperAperture",half.z*3.0,Vector2(half.y*0.17,half.x*0.21),2.4,CSGShape3D.OPERATION_SUBTRACTION,material,Vector3(half.x*0.30,half.y*1.40,0),32)
	upper_hole.rotation.y=PI*0.5
	SolidModel.add_super(rock,"CrownWeathering",Vector3(half.x*0.38,half.y*0.35,half.z*1.5),CSGShape3D.OPERATION_SUBTRACTION,material,Vector3(-half.x*0.70,half.y*1.25,0),2.3,12,16)
	SolidModel.add_super(rock,"FootWeathering",Vector3(half.x*0.32,half.y*0.25,half.z*1.5),CSGShape3D.OPERATION_SUBTRACTION,material,Vector3(half.x*0.90,half.y*0.35,0),2.5,12,16)


## One continuous softly squared bearer follows the deck section. Shared rings
## avoid the repeated pinched ends of individually rounded short segments.
static func deck_edge(parent: Node3D, points: Array[Vector3], color: Color) -> void:
	var rings: Array[PackedVector3Array]=[]
	for i in points.size():
		var axis := (points[mini(i+1,points.size()-1)]-points[maxi(i-1,0)]).normalized()
		var side := Vector3.UP.cross(axis).normalized()
		var normal := axis.cross(side).normalized()
		var ring := PackedVector3Array()
		for j in 12:
			var angle := TAU*float(j)/12.0
			var x := signf(cos(angle))*pow(absf(cos(angle)),2.0/5.5)*0.08
			var y := signf(sin(angle))*pow(absf(sin(angle)),2.0/5.5)*0.15
			ring.append(points[i]+side*x+normal*y)
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size()-1:
		for j in 12:
			var next := (j+1)%12
			for p in [rings[i][j],rings[i+1][j],rings[i+1][next],rings[i][j],rings[i+1][next],rings[i][next]]: st.add_vertex(p)
	for j in 12:
		for p in [points[0],rings[0][(j+1)%12],rings[0][j],points[-1],rings[-1][j],rings[-1][(j+1)%12]]: st.add_vertex(p)
	st.generate_normals()
	var body := StaticBody3D.new()
	body.name="FinishedDeckEdge"
	parent.add_child(body)
	var mesh := MeshInstance3D.new()
	mesh.mesh=st.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.92
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	mesh.material_override=material
	body.add_child(mesh)
	var collider := CollisionShape3D.new()
	collider.shape=mesh.mesh.create_trimesh_shape()
	collider.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	mesh.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(collider)


## A field bund is a continuous earthen bank with a flat trodden top, grassed
## battered sides and ramped ends. It is never a stretched ellipsoid/slab.
static func raised_bank(parent: Node3D, line: Array[Vector2], width: float, ground: float) -> void:
	if line.size()<2: return
	var points: Array[Vector2]=[line[0]-(line[1]-line[0]).normalized()*0.85]
	points.append_array(line)
	points.append(line[-1]+(line[-1]-line[-2]).normalized()*0.85)
	var half := width*0.5
	var section: Array[Vector2]=[Vector2(-half-0.25,0.015),Vector2(-half-0.18,0.10),Vector2(-half-0.07,0.22),Vector2(-half,0.25),Vector2(half,0.25),Vector2(half+0.07,0.22),Vector2(half+0.18,0.10),Vector2(half+0.25,0.015)]
	var rings: Array[PackedVector3Array]=[]
	for i in points.size():
		var before := (points[i]-points[maxi(i-1,0)]).normalized()
		var after := (points[mini(i+1,points.size()-1)]-points[i]).normalized()
		if i==0: before=after
		if i==points.size()-1: after=before
		var side := (before.orthogonal()+after.orthogonal()).normalized()
		var miter := minf(1.35,1.0/maxf(0.3,side.dot(after.orthogonal())))
		var ramp := 0.03 if i==0 or i==points.size()-1 else 1.0
		var ring := PackedVector3Array()
		for p in section:
			var at := points[i]+side*p.x*miter
			ring.append(Vector3(at.x,ground+p.y*ramp,at.y))
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size()-1:
		for j in section.size()-1:
			st.set_color(Color(0.46,0.40,0.28) if j==3 else Color(0.23,0.40,0.24))
			for p in [rings[i][j],rings[i+1][j],rings[i+1][j+1],rings[i][j],rings[i+1][j+1],rings[i][j+1]]: st.add_vertex(p)
	# Close the soil volume below the walk; ends sink into the island surface.
	st.set_color(Color(0.32,0.32,0.23))
	for i in points.size()-1:
		for p in [rings[i][0],rings[i][-1],rings[i+1][-1],rings[i][0],rings[i+1][-1],rings[i+1][0]]: st.add_vertex(p)
	for end in [0,points.size()-1]:
		var center := Vector3(points[end].x,ground,points[end].y)
		for j in section.size():
			for p in [center,rings[end][j],rings[end][(j+1)%section.size()]]: st.add_vertex(p)
	st.generate_normals()
	var body := StaticBody3D.new()
	body.name="RaisedFieldBund"
	parent.add_child(body)
	var visual := MeshInstance3D.new()
	visual.mesh=st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.vertex_color_is_srgb=true
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.roughness=1.0
	visual.material_override=material
	body.add_child(visual)
	var collider := CollisionShape3D.new()
	collider.shape=visual.mesh.create_trimesh_shape()
	collider.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(collider)
