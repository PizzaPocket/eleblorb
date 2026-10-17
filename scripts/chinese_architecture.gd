extends RefCounted

## Measured translation of chinese_gorge_3d.html's palaceHall/hipRoof and
## balustrade. Dimensions are building-local; the caller owns the world yaw.
## Flat walls, roof planes and floors meet exactly. Exposed members use the
## settlement's squarish SuperEgg vocabulary, without changing the section.
const DOOR := preload("res://scripts/world_door.gd")
const MARBLE := Color(0.78,0.76,0.71)
const RED := Color(0.62,0.12,0.09)
const LACQUER := Color(0.48,0.10,0.06)
const BLUE := Color(0.13,0.32,0.39)
const GREEN := Color(0.18,0.39,0.29)
const GLAZE := Color(0.76,0.53,0.15)
const PLAN := preload("res://scripts/chinese_plan.gd")
const SPECS: Dictionary = PLAN.PALACE_ARCHITECTURE


static func build_hall(key: String, width: float, depth: float) -> StaticBody3D:
	var spec: Dictionary = SPECS[key]
	var hall := StaticBody3D.new()
	hall.name = "PlanStructure"
	hall.collision_layer = 1
	hall.collision_mask = 0
	hall.set_meta("authored_footprint",Vector2(width,depth))
	hall.set_meta("column_height",spec.column_height)
	hall.set_meta("bay_count",spec.bays)
	hall.set_meta("roof_family",spec.roof)
	# The footprint is the usable floor, including the roofed veranda. Its
	# wall is set back 1.2 m, exactly as in the model's palaceHall.
	block(hall,"HallFloor",Vector3(width,0.16,depth),Vector3(0,-0.08,0),MARBLE,true,false)
	var height := float(spec.column_height)
	var iw := width-2.4
	var id := depth-2.4
	var bays := int(spec.bays)
	for side in [-1.0,1.0]:
		var openings: Array[Dictionary] = []
		for bay in bays:
			var x := -iw*0.5+iw*(float(bay)+0.5)/float(bays)
			var is_door: bool = bay==bays/2 and (side>0 or bool(spec.get("through",false)))
			if key=="apartments" and side>0:
				# Each civic room has its own entrance. Solid bays between doors
				# receive the room partitions instead of bisecting a window.
				if bay in [1,3]: continue
				is_door=true
			openings.append({"kind":"door" if is_door else "window","center":x,"width":4.0 if is_door and bool(spec.get("through",false)) else minf(iw/float(bays)-0.50,3.2),"bottom":0.0 if is_door else 0.8,"top":height if is_door and bool(spec.get("through",false)) else minf(height-0.32,3.4 if is_door else height*0.78),"leaves":2 if is_door else 0,"shutter_style":"lattice"})
		var origin := Vector3(0,0,side*id*0.5)
		TownProps._build_panel_facade(hall,iw,origin,0.0,RED,openings,0.0,height+1.28,0.22)
		for opening in openings:
			if opening.kind=="door":
				if bool(spec.get("through",false)): continue
				var door := DOOR.new()
				door.name = ("ApartmentDoor%d" % roundi(float(opening.center)*10.0)) if key=="apartments" and side>0 else ("HallDoorFront" if side>0 else "HallDoorBack")
				door.position = origin+Vector3(float(opening.center),0,0)
				hall.add_child(door)
				door.configure(float(opening.width)*0.5,float(opening.top),2,LACQUER,false)
			else:
				_window(hall,origin+Vector3(float(opening.center),0,0),float(opening.width),0.8,float(opening.top))
	for side in [-1.0,1.0]:
		var openings: Array[Dictionary] = []
		# Side windows leave the veranda and the east-facing apartment entries
		# readable; state furniture never substitutes for a real shell opening.
		for z in [-id*0.28,id*0.28]:
			openings.append({"kind":"window","center":z,"width":minf(2.1,id*0.24),"bottom":0.8,"top":height*0.74})
		TownProps._build_panel_facade(hall,id,Vector3(side*iw*0.5,0,0),PI*0.5,RED,openings,0.0,height+1.28,0.22)
		for opening in openings:
			var frame := Node3D.new()
			frame.position = Vector3(side*iw*0.5,0,-float(opening.center))
			frame.rotation.y = PI*0.5
			hall.add_child(frame)
			_window(frame,Vector3.ZERO,float(opening.width),0.8,float(opening.top))
	if key=="apartments":
		for x in [-iw/5.0,iw/5.0]:
			TownProps.build_interior_wall(hall,Vector2(x,-id*0.5),Vector2(x,id*0.5),0.0,[id*0.5],RED,LACQUER,height+1.28)
	for i in bays+1:
		var x := lerpf(-width*0.5+0.3,width*0.5-0.3,float(i)/float(bays))
		for side in [-1.0,1.0]:
			var at := Vector3(x,0,side*(depth*0.5-0.3))
			block(hall,"ColumnStoneBase",Vector3(0.72,0.25,0.72),at+Vector3(0,0.125,0),MARBLE,true)
			block(hall,"LacquerColumn",Vector3(0.52,height,0.52),at+Vector3(0,0.25+height*0.5,0),LACQUER,true)
			block(hall,"ColumnCapital",Vector3(0.72,0.25,0.60),at+Vector3(0,height+0.35,0),GREEN,true)
	for side in [-1.0,1.0]:
		for i in [1,2]:
			block(hall,"SideColumn",Vector3(0.52,height,0.52),Vector3(side*(width*0.5-0.3),height*0.5+0.25,-depth*0.5+0.3+(depth-0.6)*float(i)/3.0),LACQUER,true)
			block(hall,"SideCapital",Vector3(0.65,0.60,0.65),Vector3(side*(width*0.5-0.3),height+0.55,-depth*0.5+0.3+(depth-0.6)*float(i)/3.0),GREEN,true)
	var roof_y := height+1.5
	_brackets(hall,width-0.6,depth-0.6,roof_y,bays)
	if spec.roof=="wudian2":
		_roof(hall,width-0.6,depth-0.6,roof_y,1.6,"skirt",GLAZE)
		_clerestory(hall,width-4.0,depth-4.0,roof_y+0.4,1.8)
		_brackets(hall,width-4.2,depth-4.2,roof_y+2.6,bays)
		_roof(hall,width-4.4,depth-4.4,roof_y+2.6,4.8,"wudian",GLAZE)
	elif spec.roof=="cuanjian2":
		# The real upper storey is reached through a physical ramp opening.
		var access := StaticBody3D.new()
		access.name="PavilionUpperAccess"
		# Fit access to the INTERIOR, not the outside veranda footprint. The
		# former west ramp passed straight through the west wall.
		access.scale=Vector3(iw/(2*TownProps.CELL_SIZE),1.0,id/(3*TownProps.CELL_SIZE))
		hall.add_child(access)
		TownProps._build_floor_with_ramp_opening(access,2,3,TownProps.FLOOR_HEIGHT,MARBLE)
		TownProps._build_interior_ramps(access,2,3,2)
		_roof(hall,width-0.6,depth-0.6,roof_y,1.4,"skirt",GLAZE)
		_clerestory(hall,width-3.2,depth-3.2,roof_y+0.3,2.8)
		_brackets(hall,width-3.0,depth-3.0,roof_y+3.6,3)
		_roof(hall,width-3.0,depth-3.0,roof_y+3.6,3.6,"cuanjian",GLAZE)
		block(hall,"GildedFinial",Vector3(0.34,1.6,0.34),Vector3(0,roof_y+8.0,0),Color(0.86,0.67,0.20),true)
	else:
		_roof(hall,width-0.6,depth-0.6,roof_y,minf(4.4,depth*0.42),"xieshan",GLAZE)
	return hall


static func _window(parent: Node3D, origin: Vector3, width: float, bottom: float, top: float) -> void:
	var h := top-bottom
	var at := origin+Vector3.UP*(bottom+h*0.5)
	# The glazing and both surrounds use the facade cutter's exact profile.
	var pane := MeshInstance3D.new()
	pane.name="PaperWindow"
	pane.mesh=SolidModel.extruded_profile_mesh(0.035,Vector2(h*0.5,width*0.5),TownProps.OPENING_EXPONENT,64)
	pane.position=at
	pane.rotation.y=PI*0.5
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(0.81,0.77,0.62)
	pane.material_override=material
	parent.add_child(pane)
	CollisionPolicy.mark_decorative(pane)
	var loop := OpeningTrim.window_loop(width*0.5,h*0.5,TownProps.OPENING_EXPONENT)
	for side in [-1.0,1.0]:
		var frame := OpeningTrim.piped_frame(loop,0.065,LACQUER,true)
		frame.position=at+Vector3(0,0,side*0.12)
		parent.add_child(frame)
		for x in [-width*0.25,0.0,width*0.25]:
			var half_h := h*0.5*pow(1.0-pow(absf(x)/(width*0.5),TownProps.OPENING_EXPONENT),1.0/TownProps.OPENING_EXPONENT)
			block(parent,"LatticeUpright",Vector3(0.045,half_h*2.0,0.045),at+Vector3(x,0,side*0.13),GREEN,false)
		for i in range(1,4):
			var dy := h*(float(i)/4.0-0.5)
			var half_w := width*0.5*pow(1.0-pow(absf(dy)/(h*0.5),TownProps.OPENING_EXPONENT),1.0/TownProps.OPENING_EXPONENT)
			block(parent,"LatticeCrossbar",Vector3(half_w*2.0,0.045,0.045),at+Vector3(0,dy,side*0.13),GREEN,false)
	var reveal := OpeningTrim.reveal_liner(loop,0.11,LACQUER,Vector2.ZERO,0.998,true)
	reveal.position=at
	parent.add_child(reveal)


static func build_home(width: float, depth: float) -> StaticBody3D:
	var home := StaticBody3D.new()
	home.name="PlanStructure"
	home.collision_layer=1
	home.collision_mask=0
	home.set_meta("bay_count",3)
	home.set_meta("roof_family","hard_gable")
	var brick := Color(0.43,0.42,0.39)
	var plaster := Color(0.84,0.81,0.73)
	var timber := Color(0.24,0.16,0.10)
	block(home,"BrickPlinth",Vector3(width,0.45,depth),Vector3(0,-0.225,0),brick,true,false)
	var front := Vector3(0,0,-depth*0.5)
	var openings: Array[Dictionary]=[{"kind":"door","center":0.0,"width":1.5,"bottom":0.0,"top":2.4,"leaves":1,"exponent":5.5,"interior":true}]
	for side in [-1.0,1.0]:
		openings.append({"kind":"window","center":side*width/3.0,"width":width/3.0-0.6,"bottom":0.9,"top":2.4,"leaves":0,"exponent":5.5,"lattice":true,"shutter_style":"lattice"})
	TownProps._build_panel_facade(home,width,front,0.0,plaster,openings,0.0,3.0,0.22)
	for opening in openings:
		TownProps._build_panel_opening_trim(home,front,0.0,opening,0.0,timber,0.22,Color(0.07,0.07,0.065))
	block(home,"RearPlasterWall",Vector3(width,3.0,0.22),Vector3(0,1.5,depth*0.5),plaster,true,false)
	block(home,"BrickWeatheringBack",Vector3(width,0.9,0.26),Vector3(0,0.45,depth*0.5),brick,true,false)
	for side in [-1.0,1.0]:
		block(home,"GablePlasterWall",Vector3(0.22,3.0,depth),Vector3(side*width*0.5,1.5,0),plaster,true,false)
		block(home,"BrickWeatheringSide",Vector3(0.26,0.9,depth),Vector3(side*width*0.5,0.45,0),brick,true,false)
		var front_length := width*0.5-0.9
		block(home,"BrickWeatheringFront",Vector3(front_length,0.9,0.26),Vector3(side*(0.9+front_length*0.5),0.45,-depth*0.5),brick,true,false)
		block(home,"CoupletPaper",Vector3(0.24,1.5,0.025),Vector3(side*0.94,1.25,-depth*0.5-0.14),Color(0.70,0.13,0.08),false,false)
		# The model's blue curtain is drawn back at both jambs for a real usable
		# opening; its colour and position survive without an opaque fake door.
		block(home,"DrawnBlueCurtain",Vector3(0.11,1.6,0.07),Vector3(side*0.67,1.2,-depth*0.5-0.16),Color(0.17,0.30,0.43),false)
	# Express the frame at the rear corners too; the plaster and brick panels
	# terminate against these posts rather than exposing raw intersecting edges.
	for side in [-1.0,1.0]:
		block(home,"RearCornerTimber",Vector3(0.30,3.04,0.30),Vector3(side*width*0.5,1.5,depth*0.5),timber,true)
		block(home,"GableEaveTie",Vector3(0.24,0.24,depth+0.25),Vector3(side*width*0.5,2.94,0),timber,true)
	for x in [-width*0.5+0.2,-width/6.0,width/6.0,width*0.5-0.2]:
		block(home,"ThreeBayFrontPost",Vector3(0.26,3.0,0.26),Vector3(x,1.5,-depth*0.5-0.04),timber,true)
	for side in [-1.0,1.0]:
		block(home,"TimberEaveBeam",Vector3(width+0.3,0.25,0.25),Vector3(0,2.94,side*(depth*0.5+0.1)),timber,true)
	_frustum(home,width*0.5+0.15,depth*0.5+0.65,width*0.5+0.15,0.001,3.0,1.7,Color(0.34,0.35,0.34),"HardGableRoof",brick)
	block(home,"GreyTileRidge",Vector3(width+0.5,0.30,0.42),Vector3(0,4.82,0),Color(0.27,0.28,0.27),false)
	block(home,"KangFlue",Vector3(0.6,1.6,0.6),Vector3(width*0.5-1.2,4.6,-0.6),brick,true)
	for i in 4:
		block(home,"DryingProduce",Vector3(0.12,0.9,0.12),Vector3(width*0.5-0.6-i*0.25,2.3,-depth*0.5-0.25),Color(0.69,0.22,0.10) if i%2 else Color(0.77,0.63,0.28),false)
	var ramp_size := Vector3(1.5,0.16,sqrt(0.9*0.9+0.45*0.45))
	var angle := atan2(0.45,0.9)
	var ramp := block(home,"LevelThresholdRamp",ramp_size,Vector3(0,-0.225-0.08/cos(angle),-depth*0.5-0.45),brick,false,false)
	ramp.rotation.x=-angle
	CollisionPolicy.add_box(home,ramp,ramp_size,ramp.position,ramp.basis,true)
	return home


static func _clerestory(parent: StaticBody3D, width: float, depth: float, base: float, height: float) -> void:
	# An upper roof is borne by a complete raised wall ring, not floating slabs.
	for side in [-1.0,1.0]:
		block(parent,"UpperRoofWall",Vector3(width,height,0.20),Vector3(0,base+height*0.5,side*depth*0.5),RED,true,false)
		block(parent,"UpperRoofEndWall",Vector3(0.20,height,depth),Vector3(side*width*0.5,base+height*0.5,0),RED,true,false)


static func _brackets(parent: StaticBody3D, width: float, depth: float, y: float, bays: int) -> void:
	for side in [-1.0,1.0]:
		block(parent,"PaintedBeamBlue",Vector3(width+0.3,0.32,0.28),Vector3(0,y-0.55,side*depth*0.5),BLUE,true)
		block(parent,"PaintedBeamGreen",Vector3(width+0.35,0.30,0.30),Vector3(0,y-0.25,side*depth*0.5),GREEN,true)
		for i in bays+1:
			var x := lerpf(-width*0.5,width*0.5,float(i)/float(bays))
			block(parent,"DougongLower",Vector3(0.35,0.25,0.50),Vector3(x,y-0.95,side*(depth*0.5+0.1)),GREEN,false)
			block(parent,"DougongUpper",Vector3(0.55,0.22,0.80),Vector3(x,y-0.75,side*(depth*0.5+0.25)),BLUE,false)
	for side in [-1.0,1.0]:
		block(parent,"PaintedEndBeam",Vector3(0.30,0.62,depth+0.30),Vector3(side*width*0.5,y-0.4,0),GREEN,true)


static func _roof(parent: StaticBody3D, width: float, depth: float, y: float, rise: float, kind: String, color: Color) -> void:
	var bx := width*0.5+1.1
	var bz := depth*0.5+1.1
	if kind=="xieshan":
		var tx := bx-bz*0.5
		var tz := bz*0.5
		_frustum(parent,bx,bz,tx,tz,y,rise*0.5,color,"HipAndGableLowerRoof")
		_frustum(parent,tx,tz,maxf(0.2,tx),0.001,y+rise*0.5,rise*0.5,color,"HipAndGableUpperRoof")
		block(parent,"GlazedRidge",Vector3(tx*2.0+0.3,0.3,0.4),Vector3(0,y+rise+0.1,0),color,false)
	elif kind=="skirt":
		_frustum(parent,bx,bz,maxf(0.2,bx-2.6),maxf(0.2,bz-2.6),y,rise,color,"LowerDoubleEaveRoof",Color(-1,-1,-1),true)
	else:
		var ridge := maxf(0.5,bx-bz) if kind=="wudian" else 0.001
		_frustum(parent,bx,bz,ridge,0.001,y,rise,color,"UpperImperialRoof")
		if kind=="wudian":
			block(parent,"GlazedRidge",Vector3(ridge*2.0+0.6,0.45,0.5),Vector3(0,y+rise+0.1,0),color,false)


## A continuous swept roof: all four faces share identical edge samples.
## The lower slope flares gently; the rounded hem covers its exposed cut edge.
## The underside and collision come from the very same closed section.
static func _frustum(parent: StaticBody3D, bx: float, bz: float, tx: float, tz: float, y: float, height: float, color: Color, label_text: String, gable_color: Color = Color(-1,-1,-1), open_center: bool = false) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var bands := 12
	for face in 4:
		var face_color := gable_color if gable_color.r>=0.0 and face%2==1 else color
		for band in bands:
			var t0 := float(band)/bands
			var t1 := float(band+1)/bands
			var a := _roof_ring(bx,bz,tx,tz,y,height,t0)
			var b := _roof_ring(bx,bz,tx,tz,y,height,t1)
			var j := (face+1)%4
			_roof_quad(st,a[face],b[face],b[j],a[j],face_color)
			if open_center:
				_roof_quad(st,a[j]-Vector3.UP*0.22,b[j]-Vector3.UP*0.22,b[face]-Vector3.UP*0.22,a[face]-Vector3.UP*0.22,color.darkened(0.16),Vector3.DOWN)
	var base := _roof_ring(bx,bz,tx,tz,y,height,0.0)
	var top := _roof_ring(bx,bz,tx,tz,y,height,1.0)
	for face in 4:
		var j := (face+1)%4
		_roof_quad(st,base[face],base[j],base[j]-Vector3.UP*0.22,base[face]-Vector3.UP*0.22,color.darkened(0.12),Vector3(base[face].x+base[j].x,0,base[face].z+base[j].z))
		if open_center:
			_roof_quad(st,top[j],top[face],top[face]-Vector3.UP*0.22,top[j]-Vector3.UP*0.22,color,-Vector3(top[face].x+top[j].x,0,top[face].z+top[j].z))
		# A single continuous hem per eave; square-ended corners are buried in
		# the corner bead, so independent rounded members leave no open seam.
		var hem := block(parent,"SweptEaveHem",Vector3(base[face].distance_to(base[j])+0.12,0.25,0.30),(base[face]+base[j])*0.5-Vector3.UP*0.08,color,false)
		hem.rotation.y=atan2(-(base[j]-base[face]).z,(base[j]-base[face]).x)
		block(parent,"EaveCornerCap",Vector3(0.34,0.27,0.34),base[face]-Vector3.UP*0.08,color,false)
	if not open_center:
		_roof_quad(st,top[0],top[1],top[2],top[3],color)
		_roof_quad(st,base[3]-Vector3.UP*0.22,base[2]-Vector3.UP*0.22,base[1]-Vector3.UP*0.22,base[0]-Vector3.UP*0.22,color.darkened(0.20),Vector3.DOWN)
	st.generate_normals()
	var visual := MeshInstance3D.new()
	visual.name=label_text
	visual.mesh=st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo=true
	material.vertex_color_is_srgb=true
	material.roughness=0.64
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	visual.material_override=material
	parent.add_child(visual)
	var shape := CollisionShape3D.new()
	shape.shape=visual.mesh.create_trimesh_shape()
	shape.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	parent.add_child(shape)


static func _roof_ring(bx: float, bz: float, tx: float, tz: float, y: float, height: float, t: float) -> Array[Vector3]:
	var x := lerpf(bx,tx,t)
	var z := lerpf(bz,tz,t)
	# Preserve both structural datums. Flare is limited for shallow skirt roofs.
	var h := y+height*t-minf(height*0.24,0.48)*sin(PI*t)
	return [Vector3(-x,h,z),Vector3(x,h,z),Vector3(x,h,-z),Vector3(-x,h,-z)]


static func _roof_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color, outward: Vector3 = Vector3.UP) -> void:
	# Rendering was double sided and hid inward-facing physics triangles. A
	# player could fall through the top, then be trapped under that same face.
	# Godot uses clockwise winding. Orient each face to its actual exterior.
	var points: Array[Vector3]=[a,b,c,a,c,d]
	if (c-a).cross(b-a).dot(outward)<0.0:
		points=[a,c,b,a,d,c]
	for point in points:
		st.set_color(color)
		st.add_vertex(point)


static func block(parent: Node3D, label_text: String, size: Vector3, at: Vector3, color: Color, solid: bool, rounded: bool = true) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name=label_text
	if rounded:
		visual.mesh=SuperEgg.build_mesh(size*0.5,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT,6,8)
	else:
		var mesh := BoxMesh.new()
		mesh.size=size
		visual.mesh=mesh
	visual.position=at
	var material := StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.82
	visual.material_override=material
	parent.add_child(visual)
	if solid and parent is StaticBody3D:
		CollisionPolicy.add_box(parent,visual,size,at,Basis.IDENTITY,true)
	else:
		CollisionPolicy.mark_decorative(visual)
	return visual


static func balustrade(parent: Node3D, points: Array[Vector3], gaps: Array[Vector3] = [], height: float = 0.9) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name="MarbleBalustrade"
	body.collision_layer=1
	body.collision_mask=0
	parent.add_child(body)
	for edge in points.size()-1:
		var a := points[edge]
		var b := points[edge+1]
		var length := a.distance_to(b)
		var steps := maxi(1,ceili(length/1.6))
		var last := Vector3.INF
		for i in steps+1:
			var p := a.lerp(b,float(i)/float(steps))
			var open := false
			for gap in gaps:
				if Vector2(p.x-gap.x,p.z-gap.y).length()<gap.z: open=true
			if open:
				last=Vector3.INF
				continue
			block(body,"MarblePost",Vector3(0.24,height+0.15,0.24),p+Vector3.UP*(height+0.15)*0.5,MARBLE,true)
			block(body,"PostCap",Vector3(0.32,0.12,0.32),p+Vector3.UP*(height+0.18),MARBLE,true)
			if last.is_finite():
				for rail_y in [0.2,height]:
					var rail := block(body,"MarbleRail",Vector3(0.17,0.12,last.distance_to(p)),(last+p)*0.5+Vector3.UP*rail_y,MARBLE,false)
					rail.quaternion=Quaternion(Vector3.BACK,(p-last).normalized())
					CollisionPolicy.add_box(body,rail,Vector3(0.17,0.12,last.distance_to(p)),rail.position,rail.basis,true)
				# Continuous guard collision follows the rail span; little gaps in
				# the visible balustrade never allow the party to fall through.
				var guard := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size=Vector3(0.17,height,last.distance_to(p))
				guard.shape=box
				guard.position=(last+p)*0.5+Vector3.UP*height*0.5
				guard.quaternion=Quaternion(Vector3.BACK,(p-last).normalized())
				body.add_child(guard)
			last=p
	return body


## Large masonry reads through courses, not thousands of separate bricks.
## Metre-space coordinates survive scene baking and differing wall rotations.
static func masonry_material(color: Color) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code="""
shader_type spatial;
render_mode specular_disabled;
uniform vec4 stone_color : source_color;
varying vec3 world_at;
varying vec3 world_normal;
void vertex() {
    world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    world_normal=MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
    float along=abs(world_normal.z)>abs(world_normal.x) ? world_at.x : world_at.z;
    float row=floor(world_at.y/0.58);
    vec2 q=vec2(along/1.20+mod(row,2.0)*0.5,world_at.y/0.58);
    vec2 cell=fract(q);
    vec2 edge=min(cell,1.0-cell)*vec2(1.20,0.58);
    float aa=max(fwidth(along),fwidth(world_at.y))*0.6+0.002;
    float joint=1.0-smoothstep(0.004,0.009+aa,min(edge.x,edge.y));
    float tone=sin(dot(floor(q),vec2(27.71,43.13)))*0.008;
    ALBEDO=mix(stone_color.rgb+tone,stone_color.rgb*0.76,joint*0.60);
    ROUGHNESS=0.94;
}
"""
	var material := ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("stone_color",color)
	return material


## Finish exposed tier edges while the internal slab remains exact planar fill.
## The cap top shares the platform datum, so it creates no raised walking lip.
static func platform_edges(parent: Node3D, width: float, depth: float, base: float, height: float, center: Vector2 = Vector2.ZERO) -> void:
	var body := StaticBody3D.new()
	body.name="FinishedPlatformEdges"
	parent.add_child(body)
	for side in [-1.0,1.0]:
		block(body,"MarbleWeathering",Vector3(width+0.18,0.20,0.34),Vector3(center.x,base+height-0.10,center.y+side*depth*0.5),MARBLE,true)
		block(body,"MarbleWeathering",Vector3(0.34,0.20,depth+0.18),Vector3(center.x+side*width*0.5,base+height-0.10,center.y),MARBLE,true)
		for other in [-1.0,1.0]:
			block(body,"MarbleCornerQuoin",Vector3(0.36,height,0.36),Vector3(center.x+side*width*0.5,base+height*0.5,center.y+other*depth*0.5),MARBLE,true)
