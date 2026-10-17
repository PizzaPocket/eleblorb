@tool
extends RefCounted
class_name MoyCityBakeBuilder

## Offline-only geometry authoring helper. The live city loads the saved packs;
## it never calls this builder or creates massing at Crossroads startup.
const PLAN := preload("res://scripts/city_plan.gd")
const DATUM := -60.0
const CELL := 64.0
static var _soft_block_unit: ArrayMesh

static func build_packs() -> Dictionary:
	var packs := {}
	var tree_templates: Dictionary={}
	for s in PLAN.STREETS:
		var r: Rect2 = s.rect
		var body := _box_body("Street_%s" % s.name, Vector3(r.size.x, 0.16, r.size.y), Vector3(r.position.x + r.size.x * 0.5, DATUM - 0.05, r.position.y + r.size.y * 0.5), Color("#9c8970"))
		_add(packs, _cell(Vector2(r.get_center().x, r.get_center().y)), body)
	for o in PLAN.OPENS:
		var r: Rect2 = o.rect
		var body := _box_body("Open_%s" % o.name, Vector3(r.size.x, 0.18, r.size.y), Vector3(r.position.x + r.size.x * 0.5, DATUM - 0.02, r.position.y + r.size.y * 0.5), Color("#b9a586"))
		_add(packs, _cell(r.get_center()), body)
	for i in PLAN.OLD_TOWN.lanes.size():
		var lane: Dictionary = PLAN.OLD_TOWN.lanes[i]
		for j in lane.pts.size() - 1:
			var a: Array = lane.pts[j]
			var b: Array = lane.pts[j + 1]
			var p := Vector2(a[0], a[1]); var q := Vector2(b[0], b[1])
			var body := _segment_body("OldLane_%d_%d" % [i, j], p, q, float(lane.w), DATUM - 0.01, 0.08, Color("#947b61"))
			_add(packs, _cell((p + q) * 0.5), body)
	for square in PLAN.OLD_TOWN.squares:
		var pts: Array = square.pts
		var center := Vector2.ZERO
		for v in pts: center += Vector2(v[0], v[1])
		center /= float(pts.size())
		var body := _poly_floor("OldSquare_%s" % square.name, pts, DATUM + 0.03, Color("#c6b38f"))
		_add(packs, _cell(center), body)
	for i in PLAN.LOTS.size():
		var lot: Array = PLAN.LOTS[i]
		var r: Rect2 = lot[0]
		var h := float(lot[1]) * float(PLAN.STOREY[lot[2]])
		var color := _lot_color(i, String(lot[2]))
		var body := _box_body("Lot_%03d" % i, Vector3(r.size.x, h, r.size.y), Vector3(r.get_center().x, DATUM + h * 0.5, r.get_center().y), color)
		_add_roof(body, r.size, h, color.lightened(0.15))
		_add(packs, _cell(r.get_center()), body)
	for i in PLAN.OLD_HOUSES.size():
		var house: Dictionary = PLAN.OLD_HOUSES[i]
		var h := float(house.storeys) * 3.25
		var body := _polygon_building("OldHouse_%02d" % i, house.corners, h, _old_house_color(i))
		_add(packs, _cell(_polygon_center(house.corners)), body)
	for b in PLAN.BUILDINGS:
		if b.rect == null or int(b.n) == 11:
			continue
		var body := _landmark(b)
		_add(packs, _cell(b.rect.get_center()), body)
	_add_deck(packs,tree_templates)
	_add_wall(packs)
	_add_park(packs,tree_templates)
	_add_estate_links(packs)
	_add_transit(packs)
	_add_gate_forms(packs)
	_add_timekeeper(packs)
	_add_turbines(packs)
	for template in tree_templates.values(): (template as StaticBody3D).free()
	return packs


static func build_silhouette() -> Node3D:
	var root := Node3D.new(); root.name="MoyDistantSilhouette"
	var box := BoxMesh.new(); box.size=Vector3.ONE
	var material := StandardMaterial3D.new(); material.albedo_color=Color("#a88f70"); material.roughness=1.0
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo=true
	var lots := MultiMesh.new(); lots.transform_format=MultiMesh.TRANSFORM_3D; lots.use_colors=true; lots.mesh=box
	lots.instance_count=PLAN.LOTS.size()
	var lot_transforms: Array[Transform3D]=[]; var lot_colors: Array[Color]=[]
	for i in PLAN.LOTS.size():
		var l: Array=PLAN.LOTS[i]; var r: Rect2=l[0]; var h:=float(l[1])*float(PLAN.STOREY[l[2]])
		var transform:=Transform3D(Basis.from_scale(Vector3(r.size.x,h,r.size.y)),Vector3(r.get_center().x,DATUM+h*0.5,r.get_center().y)); var tint:=Color("#b9a181") if String(l[2])=="fabric" else Color("#a48f73")
		lots.set_instance_transform(i,transform); lots.set_instance_color(i,tint); lot_transforms.append(transform); lot_colors.append(tint)
	_store_multimesh_buffer(lots,lot_transforms,lot_colors)
	var li := MultiMeshInstance3D.new(); li.name="LotSilhouettes"; li.multimesh=lots; li.custom_aabb=_multimesh_bounds(lots,lot_transforms); li.material_override=material; li.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(li)
	var old := MultiMesh.new(); old.transform_format=MultiMesh.TRANSFORM_3D; old.use_colors=true; old.mesh=box
	old.instance_count=PLAN.OLD_HOUSES.size()
	var old_transforms: Array[Transform3D]=[]; var old_colors: Array[Color]=[]
	for i in PLAN.OLD_HOUSES.size():
		var h: Dictionary=PLAN.OLD_HOUSES[i]; var pts: Array=h.corners
		var r:=_point_bounds(pts); var height:=float(h.storeys)*3.25
		var transform:=Transform3D(Basis.from_scale(Vector3(r.size.x,height,r.size.y)),Vector3(r.get_center().x,DATUM+height*0.5,r.get_center().y)); var tint:=Color("#c6aa82")
		old.set_instance_transform(i,transform); old.set_instance_color(i,tint); old_transforms.append(transform); old_colors.append(tint)
	_store_multimesh_buffer(old,old_transforms,old_colors)
	var oi := MultiMeshInstance3D.new(); oi.name="OldHouseSilhouettes"; oi.multimesh=old; oi.custom_aabb=_multimesh_bounds(old,old_transforms); oi.material_override=material; oi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(oi)
	for b in PLAN.BUILDINGS:
		if b.rect==null: continue
		var r: Rect2=b.rect; var h:=maxf(float(b.height),4.0)
		var n:=int(b.n); var center:=r.get_center()
		if n==1:
			for wing in [Vector4(-26,0,6,60),Vector4(26,0,6,60),Vector4(0,-30,46,6),Vector4(0,30,46,6)]: _silhouette_box(root,"HotelPodium",Vector3(wing.z,44,wing.w),Vector3(center.x+wing.x,DATUM+22,center.y+wing.y),material)
			var hotel_tower:=CylinderMesh.new(); hotel_tower.top_radius=10.5; hotel_tower.bottom_radius=14.0; hotel_tower.height=96; hotel_tower.radial_segments=8
			var ht:=MeshInstance3D.new(); ht.name="HotelTowerSilhouette"; ht.mesh=hotel_tower; ht.position=Vector3(center.x+26,DATUM+48,center.y+14); ht.material_override=material; root.add_child(ht)
			var drum:=CylinderMesh.new(); drum.top_radius=12.0; drum.bottom_radius=12.0; drum.height=12; drum.radial_segments=8
			var hd:=MeshInstance3D.new(); hd.name="HotelDrumSilhouette"; hd.mesh=drum; hd.position=Vector3(center.x+26,DATUM+102,center.y+14); hd.material_override=material; root.add_child(hd)
		elif n==12:
			var shaft:=CylinderMesh.new(); shaft.top_radius=12; shaft.bottom_radius=20; shaft.height=262; shaft.radial_segments=8
			var ws:=MeshInstance3D.new(); ws.name="WindspireSilhouette"; ws.mesh=shaft; ws.position=Vector3(center.x,DATUM+131,center.y); ws.material_override=material; root.add_child(ws)
			for i in 4: _silhouette_box(root,"WindspireCrownPylon",Vector3(2,18,2),Vector3(center.x+(-8.0 if i%2==0 else 8.0),DATUM+271,center.y+(-8.0 if i<2 else 8.0)),material)
		elif n==13:
			_silhouette_box(root,"BLOCKTowerSilhouette",Vector3(r.size.x,150,r.size.y),Vector3(center.x,DATUM+75,center.y),material)
			for sign in [-1.0,1.0]:
				var blade:=MeshInstance3D.new(); blade.name="BLOCKBladeSilhouette"; var bm:=BoxMesh.new(); bm.size=Vector3(5,62,54); blade.mesh=bm; blade.position=Vector3(center.x+sign*8,DATUM+181,center.y); blade.rotation.z=sign*deg_to_rad(12.0); blade.material_override=material; root.add_child(blade)
		else:
			var mesh:=BoxMesh.new(); mesh.size=Vector3(r.size.x,h,r.size.y)
			var vis:=MeshInstance3D.new(); vis.name="Landmark_%02d"%n; vis.mesh=mesh; vis.position=Vector3(center.x,DATUM+h*0.5,center.y); vis.material_override=material; vis.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(vis)
	_add_silhouette_wall(root,material)
	var timekeeper:=TorusMesh.new(); timekeeper.inner_radius=12.0; timekeeper.outer_radius=13.5; timekeeper.rings=24; timekeeper.ring_segments=6
	var time_vis:=MeshInstance3D.new(); time_vis.name="TimekeeperSilhouette"; time_vis.mesh=timekeeper; time_vis.position=Vector3(PLAN.TIMEKEEPER.x,DATUM+PLAN.TIMEKEEPER.y,PLAN.TIMEKEEPER.z); time_vis.rotation.z=PI*0.5; time_vis.material_override=material; root.add_child(time_vis)
	var crossing:=TorusMesh.new(); crossing.inner_radius=14.0; crossing.outer_radius=17.0; crossing.rings=24; crossing.ring_segments=6
	var crossing_vis:=MeshInstance3D.new(); crossing_vis.name="CrossingRingSilhouette"; crossing_vis.mesh=crossing; crossing_vis.position=Vector3(PLAN.CENTER.x,DATUM+6.5,0); crossing_vis.material_override=material; root.add_child(crossing_vis)
	for i in PLAN.TURBINES.size():
		var p: Vector2=PLAN.TURBINES[i]
		var tower_mesh:=CylinderMesh.new(); tower_mesh.top_radius=1.8; tower_mesh.bottom_radius=3.2; tower_mesh.height=95.0; tower_mesh.radial_segments=8
		var tower:=MeshInstance3D.new(); tower.name="TurbineSilhouette_%02d"%i; tower.mesh=tower_mesh; tower.position=Vector3(p.x,DATUM+47.5,p.y); tower.material_override=material; tower.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(tower)
		var hub:=MeshInstance3D.new(); var hub_mesh:=SphereMesh.new(); hub_mesh.radius=2.4; hub.mesh=hub_mesh; hub.position=Vector3(p.x-6.5,DATUM+97.0,p.y); hub.material_override=material; hub.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(hub)
		for blade_index in 3:
			var angle:=TAU*float(blade_index)/3.0
			var blade:=MeshInstance3D.new(); var bm:=BoxMesh.new(); bm.size=Vector3(0.8,64.0,3.2); blade.mesh=bm; blade.position=Vector3(p.x-6.5,DATUM+97.0+cos(angle)*32.0,p.y+sin(angle)*32.0); blade.rotation.x=angle; blade.material_override=material; blade.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(blade)
	return root


static func _silhouette_box(root: Node3D, label: String, size: Vector3, center: Vector3, material: Material) -> void:
	var mesh:=BoxMesh.new(); mesh.size=size; var vis:=MeshInstance3D.new(); vis.name=label; vis.mesh=mesh; vis.position=center; vis.material_override=material; vis.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(vis)


static func _add_silhouette_wall(root: Node3D, material: Material) -> void:
	var mesh:=BoxMesh.new(); mesh.size=Vector3.ONE
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=mesh; multi.instance_count=64; var transforms: Array[Transform3D]=[]
	var r:=float(PLAN.WALL.r)
	for i in 64:
		var a:=TAU*float(i)/64.0; var b:=TAU*float(i+1)/64.0; var mid:Vector2=Vector2(PLAN.CENTER.x+r*cos((a+b)*0.5),r*sin((a+b)*0.5))
		var blocked:=false
		for gate in PLAN.WALL.gates:
			if Vector2(gate.p[0],gate.p[1]).distance_to(mid)<17.0: blocked=true
		var d:=Vector2(PLAN.CENTER.x+r*cos(b),r*sin(b))-Vector2(PLAN.CENTER.x+r*cos(a),r*sin(a))
		var segment_scale:=Vector3.ZERO if blocked else Vector3(d.length(),12.0,12.0)
		var transform:=Transform3D(Basis(Vector3.UP,-atan2(d.y,d.x))*Basis.from_scale(segment_scale),Vector3(mid.x,DATUM+6.0,mid.y))
		multi.set_instance_transform(i,transform); transforms.append(transform)
	_store_multimesh_buffer(multi,transforms)
	var wall:=MultiMeshInstance3D.new(); wall.name="RimWallSilhouette"; wall.multimesh=multi; wall.custom_aabb=_multimesh_bounds(multi,transforms); wall.material_override=material; wall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(wall)


static func _point_bounds(points: Array) -> Rect2:
	var minx:=INF; var maxx:=-INF; var minz:=INF; var maxz:=-INF
	for p in points:
		minx=minf(minx,float(p[0])); maxx=maxf(maxx,float(p[0])); minz=minf(minz,float(p[1])); maxz=maxf(maxz,float(p[1]))
	return Rect2(minx,minz,maxx-minx,maxz-minz)


static func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x + 800.0) / CELL), floori((p.y + 240.0) / CELL))


static func _add(packs: Dictionary, cell: Vector2i, node: Node3D) -> void:
	var key := "%02d_%02d" % [cell.x, cell.y]
	if not packs.has(key):
		var root := Node3D.new(); root.name = "MoyCell_%s" % key; packs[key] = root
	packs[key].add_child(node)


static func _material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = color; m.roughness = 0.92
	return m


static func _box_body(label: String, size: Vector3, center: Vector3, color: Color, softened := false) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; body.collision_layer = 1; body.collision_mask = 1
	body.position = center
	var shape := BoxShape3D.new(); shape.size = size
	var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
	var mesh: Mesh
	var visual := MeshInstance3D.new()
	if softened:
		if _soft_block_unit == null: _soft_block_unit=SuperEgg.build_mesh(Vector3.ONE*0.5,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT,8,12)
		mesh=_soft_block_unit; visual.scale=size
	else:
		var box:=BoxMesh.new(); box.size=size; mesh=box
	visual.mesh = mesh; visual.material_override = _material(color); body.add_child(visual)
	return body


static func _round_column(label: String, radius: float, height: float, center: Vector3, color: Color) -> StaticBody3D:
	var body:=StaticBody3D.new(); body.name=label; body.position=center; body.collision_layer=1; body.collision_mask=1
	var mesh:=CylinderMesh.new(); mesh.top_radius=radius; mesh.bottom_radius=radius; mesh.height=height; mesh.radial_segments=12
	var visual:=MeshInstance3D.new(); visual.mesh=mesh; visual.material_override=_material(color); body.add_child(visual)
	var shape:=CylinderShape3D.new(); shape.radius=radius; shape.height=height; var col:=CollisionShape3D.new(); col.shape=shape; body.add_child(col)
	return body


static func _add_building_box_part(root: StaticBody3D, size: Vector3, center: Vector3, color: Color) -> void:
	var shape:=BoxShape3D.new(); shape.size=size
	var collision:=CollisionShape3D.new(); collision.shape=shape; collision.position=center; root.add_child(collision)
	var mesh:=BoxMesh.new(); mesh.size=size
	var visual:=MeshInstance3D.new(); visual.mesh=mesh; visual.position=center; visual.material_override=_material(color); root.add_child(visual)


static func _segment_body(label: String, a: Vector2, b: Vector2, width: float, bottom: float, height: float, color: Color) -> StaticBody3D:
	var d := b - a
	var body := _box_body(label, Vector3(d.length(), height, width), Vector3((a.x+b.x)*0.5, bottom+height*0.5, (a.y+b.y)*0.5), color)
	body.rotation.y = -atan2(d.y, d.x)
	return body


static func _add_roof(body: StaticBody3D, footprint: Vector2, height: float, color: Color) -> void:
	var mesh := BoxMesh.new(); mesh.size = Vector3(footprint.x, 0.15, footprint.y)
	var roof := MeshInstance3D.new(); roof.name = "WalkableRoof"; roof.mesh = mesh; roof.material_override = _material(color)
	roof.position.y = height * 0.5 - 0.075; body.add_child(roof)


static func _lot_color(index: int, kind: String) -> Color:
	if kind == "midrise": return [Color("#cfc5ad"), Color("#b6c9bd"), Color("#d4b2a7"), Color("#b5c8d3"), Color("#bfc3c3")][index % 5]
	return [Color("#d9c6a6"), Color("#c5a17d"), Color("#d6b2a7"), Color("#b3c4ba"), Color("#b9c7d0"), Color("#c5bdac")][index % 6]


static func _old_house_color(index: int) -> Color:
	return [Color("#d5c09d"), Color("#c8a685"), Color("#d1b2a3"), Color("#b2c4b8"), Color("#c0c6cf")][index % 5]


static func _polygon_center(points: Array) -> Vector2:
	var c := Vector2.ZERO
	for p in points: c += Vector2(p[0], p[1])
	return c / float(points.size())


static func _poly_floor(label: String, points: Array, y: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; body.collision_layer = 1; body.collision_mask = 1
	var center := _polygon_center(points); body.position = Vector3(center.x, y, center.y)
	var vertices := PackedVector2Array()
	for p in points: vertices.append(Vector2(p[0]-center.x, p[1]-center.y))
	var indices := Geometry2D.triangulate_polygon(vertices)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0, indices.size(), 3):
		var a: Vector2 = vertices[indices[t]]; var b: Vector2 = vertices[indices[t+1]]; var c: Vector2 = vertices[indices[t+2]]
		st.set_normal(Vector3.UP); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(c.x,0,c.y)); st.add_vertex(Vector3(b.x,0,b.y))
	var mesh := st.commit(); mesh.surface_set_material(0,_material(color))
	var visual := MeshInstance3D.new(); visual.mesh=mesh; body.add_child(visual)
	var collision := CollisionShape3D.new(); collision.shape=mesh.create_trimesh_shape(); body.add_child(collision)
	return body


static func _polygon_building(label: String, points: Array, height: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; body.collision_layer = 1; body.collision_mask = 1
	var center := _polygon_center(points); body.position = Vector3(center.x, DATUM, center.y)
	var vertices := PackedVector2Array()
	for p in points: vertices.append(Vector2(p[0]-center.x, p[1]-center.y))
	var indices := Geometry2D.triangulate_polygon(vertices)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for t in range(0, indices.size(), 3):
		var a: Vector2 = vertices[indices[t]]; var b: Vector2 = vertices[indices[t+1]]; var c: Vector2 = vertices[indices[t+2]]
		st.set_normal(Vector3.UP); st.add_vertex(Vector3(a.x,height,a.y)); st.add_vertex(Vector3(c.x,height,c.y)); st.add_vertex(Vector3(b.x,height,b.y))
		st.set_normal(Vector3.DOWN); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(b.x,0,b.y)); st.add_vertex(Vector3(c.x,0,c.y))
	for i in vertices.size():
		var a: Vector2 = vertices[i]; var b: Vector2 = vertices[(i+1)%vertices.size()]
		var n := Vector3(b.y-a.y, 0, a.x-b.x).normalized()
		st.set_normal(n); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(a.x,height,a.y)); st.add_vertex(Vector3(b.x,height,b.y))
		st.set_normal(n); st.add_vertex(Vector3(a.x,0,a.y)); st.add_vertex(Vector3(b.x,height,b.y)); st.add_vertex(Vector3(b.x,0,b.y))
	var mesh := st.commit(); mesh.surface_set_material(0, _material(color))
	var visual := MeshInstance3D.new(); visual.mesh = mesh; body.add_child(visual)
	var collision := CollisionShape3D.new(); collision.shape = mesh.create_trimesh_shape(); body.add_child(collision)
	var roof := MeshInstance3D.new(); var cap := BoxMesh.new(); cap.size = Vector3(0.3,0.15,0.3); roof.mesh = cap; roof.position = Vector3(0,height-0.075,0); roof.material_override = _material(color.lightened(0.15)); body.add_child(roof)
	return body


static func _landmark(b: Dictionary) -> Node3D:
	var r: Rect2 = b.rect; var h := float(b.height); var center := r.get_center(); var n := int(b.n)
	var palette := [Color("#d8c9ad"),Color("#b7c9c0"),Color("#d6b0a4"),Color("#b4c8d7"),Color("#bdc2c3")]
	var color: Color = palette[(n*3+1)%palette.size()]
	match n:
		12: color=Color("#e0e2d9") # pale wind-polished metal
		13: color=Color("#aaaead") # BLOCK's quiet windowless concrete
		14: color=Color("#aebfce")
		15: color=Color("#d2a99c")
		18,20,21,49,50,53: color=Color("#c6b99f")
		33,35: color=Color("#d5b188")
		37: color=Color("#d6c7a6")
		_: pass
	if n == 1:
		var body := Node3D.new(); body.name = "Building_1_GrandHotel"
		body.position = Vector3(center.x,DATUM,center.y)
		# Four separate podium wings keep the public atrium open at ground and Deck.
		for wing in [Vector4(-26,0,6,60),Vector4(26,0,6,60),Vector4(0,-30,46,6),Vector4(0,30,46,6)]:
			var wall := _box_body("HotelAtriumWing",Vector3(wing.z,44,wing.w),Vector3(wing.x,22,wing.y),color); body.add_child(wall)
		var tower := CylinderMesh.new(); tower.top_radius=10.5; tower.bottom_radius=14.0; tower.height=96; tower.radial_segments=12
		var tm := MeshInstance3D.new(); tm.mesh=tower; tm.position.y=48; tm.material_override=_material(Color("#d1b78f")); body.add_child(tm)
		var drum := CylinderMesh.new(); drum.top_radius=12.0; drum.bottom_radius=12.0; drum.height=12; drum.radial_segments=12
		var dm := MeshInstance3D.new(); dm.mesh=drum; dm.position.y=102; dm.material_override=_material(Color("#a98a65")); body.add_child(dm)
		var collision := CollisionShape3D.new(); var cs := CylinderShape3D.new(); cs.radius=14; cs.height=96; collision.shape=cs; collision.position.y=48; body.add_child(collision)
		return body
	if String(b.kind) == "estate":
		var body := StaticBody3D.new(); body.name="Building_%02d_%s" % [n,String(b.name).replace(" ","_")]; body.collision_layer=1; body.collision_mask=1
		body.position=Vector3(center.x,DATUM,center.y); body.rotation.y=-deg_to_rad(float(b.angle))
		var open_h := 4.0; var upper_h := h-open_h
		var upper_mesh := BoxMesh.new(); upper_mesh.size=Vector3(r.size.x,upper_h,r.size.y)
		var upper := MeshInstance3D.new(); upper.mesh=upper_mesh; upper.position.y=open_h+upper_h*0.5; upper.material_override=_material(color); body.add_child(upper)
		var upper_shape := BoxShape3D.new(); upper_shape.size=upper_mesh.size
		var upper_collision := CollisionShape3D.new(); upper_collision.shape=upper_shape; upper_collision.position=upper.position; body.add_child(upper_collision)
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var post := BoxMesh.new(); post.size=Vector3(1.1,open_h,1.1)
				var post_vis := MeshInstance3D.new(); post_vis.mesh=post; post_vis.position=Vector3(sx*(r.size.x*0.5-0.7),open_h*0.5,sz*(r.size.y*0.5-0.7)); post_vis.material_override=_material(color.darkened(0.12)); body.add_child(post_vis)
				var post_shape := BoxShape3D.new(); post_shape.size=post.size
				var post_collision := CollisionShape3D.new(); post_collision.shape=post_shape; post_collision.position=post_vis.position; body.add_child(post_collision)
		return body
	var body := _box_body("Building_%02d_%s" % [n,String(b.name).replace(" ","_")],Vector3(r.size.x,h,r.size.y),Vector3(center.x,DATUM+h*0.5,center.y),color)
	body.rotation.y = -deg_to_rad(float(b.angle))
	if String(b.form) == "twist":
		var shaft := CylinderMesh.new(); shaft.top_radius=12; shaft.bottom_radius=20; shaft.height=h; shaft.radial_segments=12
		var visual := MeshInstance3D.new(); visual.mesh=shaft; visual.position=Vector3(0,0,0); visual.rotation.y=body.rotation.y; visual.material_override=_material(Color("#bd9f79")); body.add_child(visual)
	elif String(b.form) == "capsule" or String(b.form) == "dune":
		var shaft := CylinderMesh.new(); shaft.top_radius=14 if String(b.form)=="capsule" else 10; shaft.bottom_radius=16; shaft.height=h; shaft.radial_segments=12
		var visual := MeshInstance3D.new(); visual.mesh=shaft; visual.position=Vector3.ZERO; visual.material_override=_material(Color("#c2a984")); body.add_child(visual)
	if n == 13:
		# Canted folded blades rise to the authored 212 m crown top.
		var crown_h := 62.0
		for sign in [-1.0,1.0]:
			var blade := _box_body("BLOCK_CantedBlade",Vector3(5,crown_h,54),Vector3(sign*8,h*0.5+crown_h*0.5,0),Color("#4e504a")); blade.rotation.z=sign*deg_to_rad(12); body.add_child(blade)
	if n == 12:
		# Windspire's authored 18 m crown rises from the 262 m shaft to +280 m.
		var crown := _box_body("WindspireCrown",Vector3(r.size.x+10,18,r.size.y+10),Vector3(0,h*0.5+9,0),Color("#9f8a6d")); body.add_child(crown)
	var roof_mesh := BoxMesh.new(); roof_mesh.size=Vector3(r.size.x,0.15,r.size.y)
	var roof := MeshInstance3D.new(); roof.mesh=roof_mesh; roof.position=Vector3(0,h*0.5-0.075,0); roof.rotation.y=body.rotation.y; roof.material_override=_material(color.lightened(0.17)); body.add_child(roof)
	return body


static func _add_deck(packs: Dictionary, tree_templates: Dictionary) -> void:
	var level := DATUM + float(PLAN.DECK.level)
	# The authored paired columns carry each Deck run from terrain to its soffit.
	for column_index in PLAN.DECK.columns.size():
		var p: Array=PLAN.DECK.columns[column_index]
		var column_height:=float(PLAN.DECK.level)-float(PLAN.DECK.depth)
		var column:=_round_column("DeckColumn_%03d"%column_index,float(PLAN.DECK.col)*0.5,column_height,Vector3(float(p[0]),DATUM+column_height*0.5,float(p[1])),Color("#978b74"))
		_add(packs,_cell(Vector2(float(p[0]),float(p[1]))),column)
	for run in PLAN.DECK.runs:
		var pts: Array = run.pts
		for j in pts.size()-1:
			var a := Vector2(pts[j][0],pts[j][1]); var b := Vector2(pts[j+1][0],pts[j+1][1])
			var width := float(run.w)
			var depth:=float(PLAN.CROSSING.ring_depth) if String(run.name)=="Crossing Ring" else 0.9
			var bridge := _segment_body("Deck_%s_%d" % [run.name,j],a,b,width,level-depth,depth,Color("#b8a782"))
			_add(packs,_cell((a+b)*0.5),bridge)
	for parapet_index in PLAN.DECK.parapets.size():
		var seg: Array=PLAN.DECK.parapets[parapet_index]
		var a:=Vector2(float(seg[0]),float(seg[1])); var b:=Vector2(float(seg[2]),float(seg[3]))
		var kind:=String(seg[5]); var width:=0.12 if kind=="rail" else 0.08
		var rail:=_segment_body("DeckParapet_%03d_%s"%[parapet_index,kind],a,b,width,level,float(seg[4]),Color("#858c87") if kind=="rail" else Color("#a9c5c6"))
		_add(packs,_cell((a+b)*0.5),rail)
	for bed_i in PLAN.DECK.beds.size():
		var bed: Dictionary=PLAN.DECK.beds[bed_i]; var bed_root:=Node3D.new(); bed_root.name="DeckGardenBed_%02d"%bed_i
		var pts: Array=bed.pts
		bed_root.set_meta("plan_width",float(bed.w))
		for j in pts.size()-1:
			var a:=Vector2(pts[j][0],pts[j][1]); var b:=Vector2(pts[j+1][0],pts[j+1][1])
			var body:=_segment_body("DeckGardenBed_%02d_Segment_%03d"%[bed_i,j],a,b,float(bed.w),level,0.45,Color("#756f55"))
			bed_root.add_child(body)
		var bed_center:=Vector2(float(pts[0][0]),float(pts[0][1])); _add(packs,_cell(bed_center),bed_root)
	for i in PLAN.DECK.trees.size():
		var tree_data: Dictionary=PLAN.DECK.trees[i]; var c: Vector2=Vector2(tree_data.c[0],tree_data.c[1])
		var key:="round|%.2f|%s"%[float(tree_data.h),Color("#839568").to_html()]
		var tree:=_instance_tree(tree_templates,key,"round",float(tree_data.h),Color("#839568"),i); tree.name="DeckTree_%02d"%i; tree.position=Vector3(c.x,DATUM+float(tree_data.y),c.y)
		_add(packs,_cell(c),tree)
	for ramp in PLAN.DECK.ramps:
		var c: Vector2 = Vector2(ramp.c[0],ramp.c[1])
		var directions: Dictionary = {"n":Vector2(0,-1),"s":Vector2(0,1),"e":Vector2(1,0),"w":Vector2(-1,0)}
		var head_dir: Vector2 = directions[String(ramp.head)]
		var foot_dir: Vector2 = directions[String(ramp.foot)]
		var top := Vector3(c.x,DATUM+6.5,c.y)+Vector3(head_dir.x,0,head_dir.y)*5.6
		var mid := Vector3(c.x,DATUM+3.25,c.y)
		var bottom := Vector3(c.x,DATUM,c.y)+Vector3(foot_dir.x,0,foot_dir.y)*5.2
		top = Vector3(c.x,DATUM+6.5,c.y)+Vector3(head_dir.x,0,head_dir.y)*5.2
		var lower_flight := _ramp_body("DeckRamp_%s_lower" % ramp.name,bottom,mid,2.6,0.55,Color("#a99470"))
		var upper_flight := _ramp_body("DeckRamp_%s_upper" % ramp.name,mid,top,2.6,0.55,Color("#a99470"))
		var landing := _box_body("DeckRamp_%s_landing"%ramp.name,Vector3(3.8,0.35,3.8),mid,Color("#b6a17b"))
		var foot_landing:=_box_body("DeckRamp_%s_FootLanding"%ramp.name,Vector3(3.8,0.35,3.8),bottom-Vector3.UP*0.175,Color("#b6a17b"))
		var head_landing:=_box_body("DeckRamp_%s_HeadLanding"%ramp.name,Vector3(3.8,0.35,3.8),top-Vector3.UP*0.175,Color("#b6a17b"))
		for body in [lower_flight,upper_flight,landing,foot_landing,head_landing]: _add(packs,_cell(c),body)
	for escalator in PLAN.DECK.escalators:
		var f: Array=escalator.foot; var h: Array=escalator.head
		var foot:=Vector3(f[0],DATUM,f[1]); var head:=Vector3(h[0],DATUM+6.5,h[1])
		_add_escalator_pair(packs,"DeckEscalator_%s"%String(escalator.name),foot,head,2.6)
	for lift in PLAN.DECK.lifts:
		var c: Vector2=Vector2(lift.c[0],lift.c[1]); var radius:=float(lift.r)
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var post:=_box_body("DeckLiftGuide",Vector3(0.22,6.5,0.22),Vector3(c.x+sx*(radius-0.2),DATUM+3.25,c.y+sz*(radius-0.2)),Color("#9caaac")); _add(packs,_cell(c),post)
		var car:=AnimatableBody3D.new(); car.name="DeckLift_%s"%String(lift.name).replace(" ","_"); car.position=Vector3(c.x,DATUM,c.y); car.set_script(load("res://scripts/moy_lift_platform.gd"));
		var platform:=BoxMesh.new(); platform.size=Vector3(radius*2,0.28,radius*2); var pv:=MeshInstance3D.new(); pv.mesh=platform; pv.material_override=_material(Color("#c7d1ce")); car.add_child(pv)
		var ps:=BoxShape3D.new(); ps.size=platform.size; var pc:=CollisionShape3D.new(); pc.shape=ps; car.add_child(pc); _add(packs,_cell(c),car)
	_add_crossing_towers(packs)


static func _add_wall(packs: Dictionary) -> void:
	var r := float(PLAN.WALL.r); var thick := float(PLAN.WALL.thick)
	for i in 64:
		var a := TAU*float(i)/64.0; var b := TAU*float(i+1)/64.0; var mid := (a+b)*0.5
		var p := Vector2(PLAN.CENTER.x+r*cos(mid),r*sin(mid))
		var open := false
		for gate in PLAN.WALL.gates:
			if Vector2(gate.p[0],gate.p[1]).distance_to(p) < 17.0: open=true
		if open: continue
		var body := _segment_body("RimWall_%02d"%i,Vector2(PLAN.CENTER.x+r*cos(a),r*sin(a)),Vector2(PLAN.CENTER.x+r*cos(b),r*sin(b)),thick,DATUM,12.0,Color("#8f8773"))
		_add(packs,_cell(p),body)


static func _add_park(packs: Dictionary, tree_templates: Dictionary) -> void:
	var playground: Dictionary = PLAN.PARK.playground
	for tower in playground.towers:
		var c := Vector2(tower[0],tower[1]); var h := float(tower[2]); var radius := float(tower[3])
		var body := _box_body("Playground_%s" % String(tower[4]),Vector3(radius*2,h,radius*2),Vector3(c.x,DATUM+h*0.5,c.y),Color("#d4ac69"))
		_add(packs,_cell(c),body)
	var lawn: Array=PLAN.PARK.lawn
	var lawn_rect:=Rect2(lawn[0],lawn[1],lawn[2]-lawn[0],lawn[3]-lawn[1])
	# Raise the turf above the plaza/open paving top to prevent z-fighting and
	# make the authored lawn read as grass instead of a pavement-coloured slab.
	var grass:=_box_body("ParkLawn",Vector3(lawn_rect.size.x,0.12,lawn_rect.size.y),Vector3(lawn_rect.get_center().x,DATUM+0.13,lawn_rect.get_center().y),Color("#65a66b"))
	_add(packs,_cell(lawn_rect.get_center()),grass)
	var pond: Dictionary = PLAN.PARK.pond; var c := Vector2(pond.c[0],pond.c[1]); var r: Vector2 = Vector2(pond.r[0],pond.r[1])
	var water := MeshInstance3D.new(); water.name="MoyReedPondSurface"; var mesh := CylinderMesh.new(); mesh.top_radius=1; mesh.bottom_radius=1; mesh.height=0.01; mesh.radial_segments=64; water.mesh=mesh
	water.scale=Vector3(r.x,1,r.y); water.position=Vector3(c.x,DATUM+0.4,c.y)
	var water_material:=ShaderMaterial.new(); water_material.shader=load("res://shaders/moy_pond_water.gdshader"); water.material_override=water_material; water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var root := Node3D.new(); root.name="MoyReedPond"; root.add_child(water); _add(packs,_cell(c),root)
	for i in PLAN.PARK.trees.size():
		var data: Dictionary=PLAN.PARK.trees[i]; var p: Vector2=Vector2(data.c[0],data.c[1]); var h:=float(data.h)
		var leaf_color:=Color("#81936a"); var kind:=String(data.kind); var key:="%s|%.2f|%s"%[kind,h,leaf_color.to_html()]
		var tree:=_instance_tree(tree_templates,key,kind,h,leaf_color,i)
		tree.name="ParkTree_%02d_%s"%[i,String(data.kind)]; tree.position=Vector3(p.x,DATUM,p.y); _add(packs,_cell(p),tree)
	var shrub_mesh_root:=NatureProps.build_bush(Color("#648756")); StaticMerge.merge(shrub_mesh_root)
	var shrub_mesh_instance:=shrub_mesh_root.get_child(0) as MeshInstance3D
	var shrub_mesh: Mesh=shrub_mesh_instance.mesh; var shrub_material: Material=shrub_mesh_instance.material_override
	shrub_mesh_root.free()
	var shrub_transforms: Dictionary={}; var shrub_counts: Dictionary={}
	for p in PLAN.PARK.shrubs:
		var pos:=Vector2(float(p[0]),float(p[1])); var cell:=_cell(pos)
		if not shrub_transforms.has(cell): shrub_transforms[cell]=[]; shrub_counts[cell]=0
		(shrub_transforms[cell] as Array).append(Transform3D(Basis.from_scale(Vector3(6.5,4.7,6.5)),Vector3(pos.x,DATUM,pos.y))); shrub_counts[cell]=int(shrub_counts[cell])+1
	_add_plant_multimeshes(packs,"ParkShrub",shrub_mesh,shrub_material,shrub_transforms,shrub_counts)
	var reed_mesh:=BoxMesh.new(); reed_mesh.size=Vector3(0.09,1.0,0.09); var reed_transforms: Dictionary={}; var reed_counts: Dictionary={}
	for data in PLAN.PARK.reeds:
		var p: Vector2=Vector2(data.c[0],data.c[1]); var cell:=_cell(p)
		if not reed_transforms.has(cell): reed_transforms[cell]=[]; reed_counts[cell]=0
		for stem in int(data.stems):
			var height:=float(data.h); var origin:=Vector3(p.x+(float(stem)-1.0)*0.16,DATUM+height*0.5,p.y)
			(reed_transforms[cell] as Array).append(Transform3D(Basis.from_scale(Vector3.ONE*Vector3(1,height,1)),origin))
		reed_counts[cell]=int(reed_counts[cell])+1
	_add_plant_multimeshes(packs,"ParkReedClump",reed_mesh,_material(Color("#758e58")),reed_transforms,reed_counts)
	for i in PLAN.PARK.rocks.size():
		var data: Dictionary=PLAN.PARK.rocks[i]; var p: Vector2=Vector2(data.c[0],data.c[1]); var half: Array=data.half
		var size:=Vector3(float(half[0])*2,float(half[1])*2,float(half[2])*2); var center:=Vector3(p.x,DATUM+float(half[1]),p.y)
		if float(half[1])>=1.0:
			_add(packs,_cell(p),_box_body("ParkRock_%02d"%i,size,center,Color("#777467")))
		else:
			var rock:=MeshInstance3D.new(); rock.name="ParkRock_%02d"%i; var rockmesh:=BoxMesh.new(); rockmesh.size=size; rock.mesh=rockmesh; rock.position=center; rock.material_override=_material(Color("#777467")); var holder:=Node3D.new(); holder.add_child(rock); _add(packs,_cell(p),holder)
	var agave_root:=Node3D.new()
	for leaf in 5:
		var blade:=MeshInstance3D.new(); var agavemesh:=BoxMesh.new(); agavemesh.size=Vector3(0.18,1.5,0.42); blade.mesh=agavemesh; blade.position=Vector3(0,0.72,0); blade.rotation.z=deg_to_rad(float(leaf-2)*20.0); blade.rotation.y=TAU*float(leaf)/5.0; blade.material_override=_material(Color("#80946c")); agave_root.add_child(blade)
	StaticMerge.merge(agave_root); var agave_instance:=agave_root.get_child(0) as MeshInstance3D; var agave_mesh:Mesh=agave_instance.mesh; var agave_material:Material=agave_instance.material_override; agave_root.free()
	var agave_transforms: Dictionary={}; var agave_counts: Dictionary={}
	for p in PLAN.PARK.agave:
		var pos:=Vector2(float(p[0]),float(p[1])); var cell:=_cell(pos)
		if not agave_transforms.has(cell): agave_transforms[cell]=[]; agave_counts[cell]=0
		(agave_transforms[cell] as Array).append(Transform3D(Basis.IDENTITY,Vector3(pos.x,DATUM,pos.y))); agave_counts[cell]=int(agave_counts[cell])+1
	_add_plant_multimeshes(packs,"ParkAgave",agave_mesh,agave_material,agave_transforms,agave_counts)


static func _add_plant_multimeshes(packs: Dictionary, item_name: String, mesh: Mesh, material: Material, transforms_by_cell: Dictionary, item_counts: Dictionary) -> void:
	for cell in transforms_by_cell:
		var transforms: Array=transforms_by_cell[cell]; var multimesh:=MultiMesh.new(); multimesh.transform_format=MultiMesh.TRANSFORM_3D; multimesh.mesh=mesh; multimesh.instance_count=transforms.size()
		var typed_transforms: Array[Transform3D]=[]
		for i in transforms.size():
			var transform: Transform3D=transforms[i]; multimesh.set_instance_transform(i,transform); typed_transforms.append(transform)
		_store_multimesh_buffer(multimesh,typed_transforms)
		var instance:=MultiMeshInstance3D.new(); instance.name="%sMultiMesh_%s"%[item_name,str(cell)]; instance.multimesh=multimesh; instance.custom_aabb=_multimesh_bounds(multimesh,typed_transforms); instance.material_override=material; instance.set_meta("moy_item_count",int(item_counts[cell])); CollisionPolicy.mark_decorative(instance)
		_add(packs,cell,instance)


static func _store_multimesh_buffer(multimesh: MultiMesh, transforms: Array[Transform3D], colors: Array[Color]=[]) -> void:
	var stride:=12+(4 if multimesh.use_colors else 0)+(4 if multimesh.use_custom_data else 0)
	var buffer:=PackedFloat32Array(); buffer.resize(transforms.size()*stride)
	for i in transforms.size():
		var t:=transforms[i]; var values: Array[float]=[t.basis.x.x,t.basis.y.x,t.basis.z.x,t.origin.x,t.basis.x.y,t.basis.y.y,t.basis.z.y,t.origin.y,t.basis.x.z,t.basis.y.z,t.basis.z.z,t.origin.z]
		for j in 12: buffer[i*stride+j]=values[j]
		var cursor:=i*stride+12
		if multimesh.use_colors:
			var color: Color=colors[i] if i<colors.size() else Color.WHITE
			buffer[cursor]=color.r; buffer[cursor+1]=color.g; buffer[cursor+2]=color.b; buffer[cursor+3]=color.a; cursor+=4
		if multimesh.use_custom_data:
			buffer[cursor]=0.0; buffer[cursor+1]=0.0; buffer[cursor+2]=0.0; buffer[cursor+3]=0.0
	multimesh.buffer=buffer


static func _multimesh_bounds(multimesh: MultiMesh, transforms: Array[Transform3D]) -> AABB:
	var mesh_bounds:=multimesh.mesh.get_aabb(); var bounds:=AABB()
	for i in transforms.size():
		var instance_bounds:=transforms[i]*mesh_bounds
		bounds=instance_bounds if i==0 else bounds.merge(instance_bounds)
	return bounds


static func _instance_tree(cache: Dictionary, key: String, kind: String, height: float, leaf: Color, seed_index: int) -> StaticBody3D:
	if not cache.has(key):
		var rng:=RandomNumberGenerator.new(); rng.seed=seed_index+1
		var template: StaticBody3D
		match kind:
			"round": template=NatureProps.build_round_tree(height,leaf)
			"flowering": template=NatureProps.build_flowering_tree(height,leaf,Color("#d96b45"),rng)
			"palm": template=NatureProps.build_palm_tree(height,0.0,rng)
			_: template=NatureProps.build_banyan_tree(height,rng)
		template.position=Vector3.ZERO; cache[key]=template
	return (cache[key] as StaticBody3D).duplicate() as StaticBody3D


static func _add_estate_links(packs: Dictionary) -> void:
	for i in PLAN.ESTATE.linkways.size():
		var link: Array = PLAN.ESTATE.linkways[i]
		for j in link.size()-1:
			var a := Vector2(link[j][0],link[j][1]); var b := Vector2(link[j+1][0],link[j+1][1])
			var body := _segment_body("EstateLink_%d_%d"%[i,j],a,b,3.0,DATUM+6.5,0.8,Color("#b3a27d"))
			_add(packs,_cell((a+b)*0.5),body)


static func _add_meridian_pier(packs: Dictionary, x: float, rail: float, pier_index: int) -> void:
	var stem_top:=DATUM+28.0; var rail_y:=DATUM+rail
	var stem:=_round_column("MeridianPierStem_%02d"%pier_index,1.2,(stem_top-DATUM),Vector3(x,DATUM+(stem_top-DATUM)*0.5,0),Color("#888173")); _add(packs,_cell(Vector2(x,0)),stem)
	for side_index in 2:
		var side: float=-1.0 if side_index==0 else 1.0
		var arm_foot:=Vector3(x,DATUM+25.5,0); var arm_head:=Vector3(x,DATUM+rail-1.2,side*2.7)
		var arm:=_ramp_body("MeridianPierYArm_%02d_%d"%[pier_index,side_index],arm_foot,arm_head,1.15,1.15,Color("#888173")); _add(packs,_cell(Vector2(x,0)),arm)
		var girder:=_box_body("MeridianBoxGirder_%02d_%d"%[pier_index,side_index],Vector3(36.0,1.2,1.0),Vector3(x,rail_y-1.2,side*1.7),Color("#77766f")); _add(packs,_cell(Vector2(x,0)),girder)
	for vine_index in 2:
		var z: float=-3.0 if vine_index==0 else 3.0
		var vine:=_box_body("MeridianVineSleeve_%02d_%d"%[pier_index,vine_index],Vector3(0.3,21.0,0.3),Vector3(x,DATUM+17.5,z),Color("#66824f")); _add(packs,_cell(Vector2(x,z)),vine)


static func _add_crossing_towers(packs: Dictionary) -> void:
	var cfg: Dictionary=PLAN.CROSSING; var tcfg: Dictionary=cfg.tower
	for ti in cfg.towers.size():
		var data: Dictionary=cfg.towers[ti]; var c: Vector2=Vector2(data.c[0],data.c[1]); var root:=Node3D.new(); root.name="CrossingTower_%02d"%ti; root.position=Vector3(c.x,DATUM,c.y)
		var trunk:=_round_column("CrossingTowerTrunk",float(tcfg.trunk),float(cfg.roof.y),Vector3(0,float(cfg.roof.y)*0.5,0),Color("#8e948d")); root.add_child(trunk)
		# Each authored profile is tessellated into short, walkable moving belt sections.
		for hand in data.hands:
			var is_up:=String(hand.hand)=="up"
			for pi in hand.profile.size():
				var seg: Array=hand.profile[pi]; var a0:=deg_to_rad(float(seg[0])); var a1:=deg_to_rad(float(seg[1])); var y0:=float(seg[2]); var y1:=float(seg[3])
				var count:=maxi(1,ceili(absf(a1-a0)*2.7))
				for si in count:
					var f0:=float(si)/float(count); var f1:=float(si+1)/float(count); var am:float=lerpf(a0,a1,(f0+f1)*0.5)
					var ym:float=lerpf(y0,y1,(f0+f1)*0.5); var da:=absf(a1-a0)/float(count); var len:=maxf(0.16,2.7*da)
					var tangent:=Vector3(-sin(am),0,cos(am)); var center:=Vector3(cos(am)*2.7,ym,sin(am)*2.7)
					if y1==y0:
						# The profile bearing is measured east-to-south around +Y.  A
						# landing's long axis follows the tangent, not the radial axis.
						var landing:=_box_body("CrossingHandLanding_%s_%d_%d"%[String(hand.hand),pi,si],Vector3(len,0.2,2.6),center,Color("#b5a783")); landing.rotation.y=-am-PI*0.5; root.add_child(landing)
					else:
						var p0:=Vector3(cos(lerpf(a0,a1,f0))*2.7,y0,sin(lerpf(a0,a1,f0))*2.7)
						var p1:=Vector3(cos(lerpf(a0,a1,f1))*2.7,y1,sin(lerpf(a0,a1,f1))*2.7)
						var belt:=_ramp_body("CrossingHand_%s_%d_%d"%[String(hand.hand),pi,si],p0,p1,2.6,0.16,Color("#aaa58f")); belt.set_script(load("res://scripts/moy_escalator.gd")); belt.set("travel_direction",(p1-p0).normalized()*(1.0 if is_up else -1.0)); belt.set("travel_speed",0.55); root.add_child(belt)
		for level in [6.5,14.2,37.0]:
			var ann:=_annulus_body("CrossingGallery_%.1f"%level,float(tcfg.gallery_r[0]),float(tcfg.gallery_r[1]),48,1.0,level); root.add_child(ann)
			for rail_i in 36:
				var a_deg:=float(rail_i)*10.0; var b_deg:=float(rail_i+1)*10.0; var mid_deg:float=(a_deg+b_deg)*0.5
				if _crossing_hand_landing_open(data.hands,level,mid_deg): continue
				var a:=Vector2(c.x+cos(deg_to_rad(a_deg))*float(tcfg.gallery_r[0]),c.y+sin(deg_to_rad(a_deg))*float(tcfg.gallery_r[0]))
				var b:=Vector2(c.x+cos(deg_to_rad(b_deg))*float(tcfg.gallery_r[0]),c.y+sin(deg_to_rad(b_deg))*float(tcfg.gallery_r[0]))
				var rail:=_segment_body("CrossingGalleryInnerRail_%02d_%.1f_%02d"%[ti,level,rail_i],a,b,0.12,DATUM+level,1.1,Color("#80908a")); _add(packs,_cell(c),rail)
		for rib_i in int(tcfg.ribs):
			var angle:=TAU*(float(rib_i)+0.5)/float(tcfg.ribs); var rib:=_round_column("CrossingTowerRib_%02d"%rib_i,0.22,float(cfg.roof.y),Vector3(cos(angle)*float(tcfg.drum),float(cfg.roof.y)*0.5,sin(angle)*float(tcfg.drum)),Color("#a4aaa2")); root.add_child(rib)
		for ci in cfg.climbers.size():
			var climber: Array=cfg.climbers[ci]
			if int(climber[0])!=ti: continue
			var angle:=deg_to_rad(float(climber[1])); var y0:=float(climber[2]); var y1:=float(climber[3]); var width:=2.35
			# The plan's bearing is radial.  The panel width lies tangent to the
			# tower; using the bearing directly yawed it 90 degrees around the
			# drum and made the vines project outward instead of following the ribs.
			var panel:=MeshInstance3D.new(); panel.name="CrossingClimberPanel_%03d"%ci; var mesh:=BoxMesh.new(); mesh.size=Vector3(width,y1-y0,0.16); panel.mesh=mesh; panel.position=Vector3(cos(angle)*6.02,(y0+y1)*0.5,sin(angle)*6.02); panel.rotation.y=-angle-PI*0.5; panel.material_override=_material(Color("#678752")); root.add_child(panel)
			if y0>0:
				var planter:=_box_body("CrossingClimberPlanter_%03d"%ci,Vector3(0.55,0.5,0.8),Vector3(cos(angle)*5.55,y0+0.25,sin(angle)*5.55),Color("#746e54")); root.add_child(planter)
		for hoop_i in 10:
			var hoop_level:=float(hoop_i+1)*4.1
			var hoop:=_annulus_visual("CrossingTowerHoop_%02d"%hoop_i,5.85,6.1,48,0.12,hoop_level); root.add_child(hoop)
		var lift_data: Dictionary=data.lift; var lc: Array=lift_data.c; var lift:=AnimatableBody3D.new(); lift.name="CrossingTowerLift"; lift.position=Vector3(float(lc[0])-c.x,0,float(lc[1])-c.y); lift.set_script(load("res://scripts/moy_lift_platform.gd")); lift.set("base_height",0.0); lift.set("travel_height",40.4); lift.set("travel_period",48.0)
		lift.set("stop_levels",PackedFloat32Array(data.levels))
		var liftmesh:=BoxMesh.new(); liftmesh.size=Vector3(2.6,0.22,2.6); var lv:=MeshInstance3D.new(); lv.mesh=liftmesh; lv.material_override=_material(Color("#bfd0ce")); lift.add_child(lv); var ls:=BoxShape3D.new(); ls.size=liftmesh.size; var lcol:=CollisionShape3D.new(); lcol.shape=ls; lift.add_child(lcol); root.add_child(lift)
		# The glazed shaft is visual only; four separate guide posts carry it
		# without sealing the lift or its landings with one tall collider.
		var shaft_center:=Vector3(float(lc[0])-c.x,20.2,float(lc[1])-c.y)
		var glass_material:=StandardMaterial3D.new(); glass_material.albedo_color=Color(0.55,0.72,0.75,0.22); glass_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass_material.roughness=0.18; glass_material.metallic=0.08
		for sx in [-1.0,1.0]:
			for sz in [-1.0,1.0]:
				var guide:=_box_body("CrossingLiftGuide",Vector3(0.12,40.4,0.12),shaft_center+Vector3(sx*1.3,0,sz*1.3),Color("#a6b7b7")); root.add_child(guide)
		for wall_side in 4:
			var pane:=MeshInstance3D.new(); pane.name="CrossingLiftGlass"; var glass:=BoxMesh.new(); glass.size=Vector3(2.5,40.0,0.04) if wall_side<2 else Vector3(0.04,40.0,2.5); pane.mesh=glass; pane.position=shaft_center+([Vector3(0,0,-1.3),Vector3(0,0,1.3),Vector3(-1.3,0,0),Vector3(1.3,0,0)][wall_side]); pane.material_override=glass_material; root.add_child(pane)
		# Data-directed clear connections from the gallery to the ring/bridges,
		# then onward to the exact line platform at each intermediate level.
		var ring_open:=Vector2(c.x-float(cfg.c[0]),c.y-float(cfg.c[1])).normalized()
		var ring_start:=c+ring_open*float(tcfg.gallery_r[1]); var ring_end:=Vector2(float(cfg.c[0]),float(cfg.c[1]))+ring_open*float(cfg.ring[0])
		_add_crossing_walkway(packs,"CrossingTower_%02d_RingLink"%ti,ring_start,ring_end,6.5,2.4,Color("#b6a782"))
		for run in PLAN.DECK.runs:
			if String(run.name)!="Crossing bridge north" and String(run.name)!="Crossing bridge south": continue
			var pts: Array=run.pts; var nearest:=_nearest_point_on_segment(c,Vector2(pts[0][0],pts[0][1]),Vector2(pts[-1][0],pts[-1][1]))
			if c.distance_to(nearest)<=float(tcfg.gallery_r[1])+0.25: _add_crossing_walkway(packs,"CrossingTower_%02d_CrossBridgeLink_%s"%[ti,String(run.name)],c+(nearest-c).normalized()*float(tcfg.gallery_r[1]),nearest,6.5,2.4,Color("#b6a782"))
		var spine_side:=1.0 if String(data.spine_platform)=="east" else -1.0
		var spine_target:=Vector2(float(cfg.c[0])+spine_side*(float(PLAN.PLATFORMS.edge)+float(PLAN.CROSS.track)+float(PLAN.PLATFORMS.width)*0.5),c.y)
		var spine_start:=c+Vector2(cos(deg_to_rad(float(data.opens["14.2"]))),sin(deg_to_rad(float(data.opens["14.2"]))))*float(tcfg.gallery_r[1])
		_add_crossing_walkway(packs,"CrossingTower_%02d_SpinePlatformBridge"%ti,spine_start,spine_target,14.2,2.4,Color("#b6a782"))
		var meridian_side:=1.0 if String(data.high_platform)=="south" else -1.0
		var meridian_target:=Vector2(float(cfg.c[0]),float(cfg.c[1])+meridian_side*(float(PLAN.PLATFORMS.edge)+float(PLAN.CROSS.track)+float(PLAN.PLATFORMS.width)*0.5))
		var meridian_start:=c+Vector2(cos(deg_to_rad(float(data.opens["37.0"]))),sin(deg_to_rad(float(data.opens["37.0"]))))*float(tcfg.gallery_r[1])
		_add_crossing_walkway(packs,"CrossingTower_%02d_MeridianPlatformBridge"%ti,meridian_start,meridian_target,37.0,2.4,Color("#b6a782"))
		var lift_world:=Vector2(float(lc[0]),float(lc[1])); var lift_direction:Vector2=(lift_world-c).normalized()
		for connection_level in [6.5,14.2,37.0]:
			_add_crossing_walkway(packs,"CrossingTower_%02d_LiftGallery_%0.1f"%[ti,connection_level],c+lift_direction*float(tcfg.gallery_r[1]),lift_world,connection_level,1.8,Color("#b6a782"))
		_add_crossing_walkway(packs,"CrossingTower_%02d_LiftSpineLanding"%ti,lift_world,spine_target,14.2,1.8,Color("#b6a782"))
		_add_crossing_walkway(packs,"CrossingTower_%02d_LiftMeridianLanding"%ti,lift_world,meridian_target,37.0,1.8,Color("#b6a782"))
		_add(packs,_cell(c),root)
	var roof_pts: Array=[]; var roof_cfg: Dictionary=cfg.roof; var roof_half:=float(roof_cfg.half); var exp:=float(roof_cfg.n)
	for ri in 64:
		var angle:=TAU*float(ri)/64.0; var cx:=cos(angle); var sz:=sin(angle)
		roof_pts.append([float(cfg.c[0])+roof_half*signf(cx)*pow(absf(cx),2.0/exp),float(cfg.c[1])+roof_half*signf(sz)*pow(absf(sz),2.0/exp)])
	var roof:=_polygon_building("CrossingRoof",roof_pts,float(roof_cfg.th),Color("#d2c7a7")); roof.position.y=DATUM+float(roof_cfg.y); _add(packs,_cell(Vector2(cfg.c[0],cfg.c[1])),roof)
	for beam_index in cfg._beams.spine.z.size():
		var z: float=cfg._beams.spine.z[beam_index]; var spine_y0:=float(cfg._beams.spine.y[0]); var spine_y1:=float(cfg._beams.spine.y[1]); var beam:=_box_body("CrossingSpineHeadBeam_%d"%beam_index,Vector3(26.0,spine_y1-spine_y0,1.6),Vector3(-560,DATUM+(spine_y0+spine_y1)*0.5,z),Color("#8d948b")); _add(packs,_cell(Vector2(-560,z)),beam)
	for beam_index in cfg._beams.high.x.size():
		var x: float=cfg._beams.high.x[beam_index]; var high_y0:=float(cfg._beams.high.y[0]); var high_y1:=float(cfg._beams.high.y[1]); var beam:=_box_body("CrossingMeridianHeadBeam_%d"%beam_index,Vector3(1.6,high_y1-high_y0,26.0),Vector3(x,DATUM+(high_y0+high_y1)*0.5,0),Color("#8d948b")); _add(packs,_cell(Vector2(x,0)),beam)
	for garden_index in cfg.rain_gardens.size():
		var garden: Dictionary=cfg.rain_gardens[garden_index]; var gc:=Vector2(float(garden.c[0]),float(garden.c[1])); var disc:=_round_column("CrossingRainGarden_%02d"%garden_index,float(garden.r),0.22,Vector3(gc.x,DATUM+0.11,gc.y),Color("#648350")); _add(packs,_cell(gc),disc)
		for reed in garden.reeds:
			var rp:=Vector2(float(reed[0]),float(reed[1])); var clump:=Node3D.new(); clump.name="CrossingRainReeds_%0.2f_%0.2f"%[rp.x,rp.y]; clump.position=Vector3(rp.x,DATUM,rp.y)
			for ri in 3:
				var leafmesh:=BoxMesh.new(); leafmesh.size=Vector3(0.08,float(reed[2]),0.08); var leaf:=MeshInstance3D.new(); leaf.mesh=leafmesh; leaf.position.y=float(reed[2])*0.5; leaf.material_override=_material(Color("#7e945e")); clump.add_child(leaf)
			_add(packs,_cell(rp),clump)


static func _annulus_body(label: String, inner: float, outer: float, segments: int, thickness: float, y: float) -> StaticBody3D:
	var body:=StaticBody3D.new(); body.name=label; body.position.y=y-thickness*0.5; body.collision_layer=1; body.collision_mask=1
	var mesh:=TorusMesh.new(); mesh.inner_radius=inner; mesh.outer_radius=outer; mesh.rings=segments; mesh.ring_segments=8; mesh.inner_radius=inner; mesh.outer_radius=outer
	var vis:=MeshInstance3D.new(); vis.mesh=mesh; vis.rotation.x=PI*0.5; vis.material_override=_material(Color("#b6a580")); body.add_child(vis)
	var col:=CollisionShape3D.new(); col.shape=mesh.create_trimesh_shape(); col.rotation.x=PI*0.5; body.add_child(col)
	return body


static func _crossing_hand_landing_open(hands: Array, level: float, bearing: float) -> bool:
	for hand in hands:
		for profile in hand.profile:
			if not is_equal_approx(float(profile[2]),level) or not is_equal_approx(float(profile[3]),level): continue
			var span:=fposmod(float(profile[1])-float(profile[0]),360.0)
			if fposmod(bearing-float(profile[0]),360.0)<=span: return true
	return false


static func _nearest_point_on_segment(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var delta:=b-a; var t:=clampf((p-a).dot(delta)/maxf(delta.length_squared(),0.001),0.0,1.0); return a+delta*t


static func _add_crossing_walkway(packs: Dictionary, label: String, a: Vector2, b: Vector2, level: float, width: float, color: Color) -> void:
	var direction:=b-a
	if direction.length()<0.05: return
	var walk:=_segment_body(label,a,b,width,DATUM+level-0.3,0.3,color)
	_add(packs,_cell((a+b)*0.5),walk)


static func _annulus_visual(label: String, inner: float, outer: float, segments: int, thickness: float, y: float) -> Node3D:
	var mesh:=TorusMesh.new(); mesh.inner_radius=inner; mesh.outer_radius=outer; mesh.rings=segments; mesh.ring_segments=8
	var vis:=MeshInstance3D.new(); vis.name=label; vis.mesh=mesh; vis.rotation.x=PI*0.5; vis.position.y=y; vis.material_override=_material(Color("#a4aaa2")); return vis


static func _add_transit(packs: Dictionary) -> void:
	for service in PLAN.CROSS.services:
		var line_name := String(service.line)
		var route := PackedVector3Array()
		for p in service.path: route.append(Vector3(p[0],DATUM+float(service.rail),p[1]))
		var lane_paths: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
		for lane in 2:
			var offset := -float(PLAN.CROSS.track) if lane == 0 else float(PLAN.CROSS.track)
			for i in route.size():
				var before := route[maxi(0,i-1)]; var after := route[mini(route.size()-1,i+1)]
				var tangent := after-before; tangent.y=0.0
				var across := Vector3(-tangent.z,0.0,tangent.x).normalized()
				lane_paths[lane].append(route[i]+across*offset)
		for i in route.size()-1:
			var a:=route[i]; var b:=route[i+1]; var mid:=(a+b)*0.5
			var bed:=_ramp_body("%s_Track_%d"%[line_name,i],a-Vector3.UP*0.7,b-Vector3.UP*0.7,8.0,1.2,Color("#77766f"))
			_add(packs,_cell(Vector2(mid.x,mid.z)),bed)
			var tangent:=b-a; tangent.y=0.0; var across:=Vector3(-tangent.z,0.0,tangent.x).normalized()
			for lane in 2:
				var lane_offset:float=-float(PLAN.CROSS.track) if lane==0 else float(PLAN.CROSS.track)
				for rail_side in [-1.0,1.0]:
					var rail_offset:float=lane_offset+rail_side*0.7175
					var rail:=_ramp_body("%s_Rail_%d_%d_%d"%[line_name,i,lane,int(rail_side)],a+across*rail_offset,b+across*rail_offset,0.16,0.2,Color("#555b5d"))
					_add(packs,_cell(Vector2(mid.x,mid.z)),rail)
		var pier_xs: Array = service.get("piers", [])
		if not pier_xs.is_empty():
			for pier_index in pier_xs.size():
				_add_meridian_pier(packs,float(pier_xs[pier_index]),float(service.rail),pier_index)
		elif line_name == "Spine Line":
			for frame_index in service.frames.size():
				var frame: Array=service.frames[frame_index]
				var fx:=float(frame[0]); var fz:=float(frame[1]); var top:=DATUM+float(service.rail)-1.2
				if absf(fx-PLAN.CENTER.x)<1.0 and absf(fz)<20.0: continue
				for leg_index in 2:
					var xoff: float=-3.2 if leg_index==0 else 3.2
					var height:=top-DATUM
					var leg:=_box_body("SpineFrameLeg_%02d_%d"%[frame_index,leg_index],Vector3(0.9,height,0.9),Vector3(fx+xoff,DATUM+height*0.5,fz),Color("#938a78")); _add(packs,_cell(Vector2(fx+xoff,fz)),leg)
				var beam:=_box_body("SpineFrameBeam_%02d"%frame_index,Vector3(7.3,0.9,0.9),Vector3(fx,top-0.45,fz),Color("#938a78")); _add(packs,_cell(Vector2(fx,fz)),beam)
		for station in PLAN.CROSS.stations:
			if not station.lines.has(line_name): continue
			var p: Vector2=Vector2(station.at[0],station.at[1]); var plat := PLAN.CROSS.platform
			var station_y:=DATUM+float(station.get("rail",service.rail))+float(PLAN.PLATFORMS.floor)
			var along_z:=line_name=="Spine Line"
			var platform_offset:=float(PLAN.PLATFORMS.edge)+float(PLAN.CROSS.track)+float(PLAN.PLATFORMS.width)*0.5
			for side in [-1.0,1.0]:
				var platform_size:=Vector3(float(PLAN.PLATFORMS.width),0.3,plat[0]) if along_z else Vector3(plat[0],0.3,float(PLAN.PLATFORMS.width))
				var platform_center:=Vector3(p.x+(side*platform_offset if along_z else 0.0),station_y-0.15,p.y+(0.0 if along_z else side*platform_offset))
				var platform := _box_body("Station_%s_%s_%d"%[line_name,String(station.name).replace(" ","_"),int(side)],platform_size,platform_center,Color("#c4b18b"))
				_add(packs,_cell(p),platform)
				var crossing_meridian:=String(station.name)=="The Crossing" and line_name=="Meridian Line"
				if not crossing_meridian:
					var canopy_size:=Vector3(platform_size.x,0.18,platform_size.z)
					var canopy:=_box_body("StationCanopy_%s_%s_%d"%[line_name,String(station.name).replace(" ","_"),int(side)],canopy_size,platform_center+Vector3.UP*(float(PLAN.PLATFORMS.canopy)+0.24),Color("#c0b99f")); _add(packs,_cell(p),canopy)
			if line_name=="Spine Line" and station.has("_interchange"):
				var outward:=signf(float(station.at[1])); var z0:=float(station.at[1])+outward*float(plat[0])*0.5; var gap:=float(station._interchange.gap)+0.3
				var slab_depth:=float(PLAN.PLATFORMS.floor); var slab_width:=2.0*(platform_offset+float(PLAN.PLATFORMS.width)*0.5)
				var slab:=_box_body("SpineWallInterchange",Vector3(slab_width,slab_depth,gap),Vector3(p.x,DATUM+float(service.rail)+slab_depth*0.5,z0+outward*gap*0.5),Color("#b6a17b")); _add(packs,_cell(Vector2(p.x,z0)),slab)
		if line_name=="Spine Line":
			for station in PLAN.CROSS.stations:
				if not station.has("_access"): continue
				for side_data in station._access:
					for flight_index in side_data.flights.size():
						var flight: Dictionary=side_data.flights[flight_index]
						var foot:=Vector3(flight.foot[0],DATUM+float(flight.foot[2]),flight.foot[1]); var head:=Vector3(flight.head[0],DATUM+float(flight.head[2]),flight.head[1])
						_add_escalator_pair(packs,"SpineAccess_%s_%s_%d"%[String(station.name).replace(" ","_"),String(side_data.side),flight_index],foot,head,float(flight.w))
						if side_data.has("runout") and flight_index==0:
							var runout: Dictionary=side_data.runout; var rp: Array=runout.c; var sz: Array=runout.size
							var slab:=_box_body("SpineAccessRunout",Vector3(sz[0],0.3,sz[1]),Vector3(rp[0],DATUM+float(runout.y)-0.15,rp[1]),Color("#b6a17b")); _add(packs,_cell(Vector2(rp[0],rp[1])),slab)
						if side_data.has("apron"):
							var ap: Dictionary=side_data.apron; var ac: Array=ap.c; var az: Array=ap.size
							var slab:=_box_body("SpineAccessApron",Vector3(az[0],0.35,az[1]),Vector3(ac[0],DATUM+float(ap.y)-0.175,ac[1]),Color("#b6a17b")); _add(packs,_cell(Vector2(ac[0],ac[1])),slab)
		var loop := false
		var path := route
		var stops := PackedVector3Array()
		for station in PLAN.CROSS.stations:
			if station.lines.has(line_name): stops.append(Vector3(station.at[0],DATUM+float(station.get("rail",service.rail)),station.at[1]))
		var line_plan: Dictionary=PLAN.TIMETABLE.lines.get(line_name,{})
		for train_index in int(line_plan.get("trains",1)):
			var lane:=mini(train_index,1); var lane_path:=lane_paths[lane]
			var train := _make_train(line_name,lane_path,int(PLAN.TRAIN.consists[line_name].cars),float(PLAN.CROSS.cars.speed),loop,stops,float(PLAN.TIMETABLE.dwell.ordinary),train_index,1 if train_index%2==0 else -1)
			train.set("schedule_events",line_plan.events); train.set("schedule_offset",float(line_plan.offset)); train.set("schedule_headway",float(PLAN.TIMETABLE.headway)); train.set("schedule_circuit",float(line_plan.circuit)); train.set("schedule_train_index",train_index)
			_add(packs,_cell(Vector2(path[0].x,path[0].z)),train)
	for core in PLAN.CROSSING.cores: _add_station_core(packs,core,"CrossingCore")
	for service in PLAN.CROSS.services:
		if String(service.line)=="Spine Line":
			for z in [-200.0,200.0]:
				var stop:=_box_body("SpineBufferStop",Vector3(8.0,0.8,1.0),Vector3(-560.0,DATUM+13.2,z),Color("#9c3428")); _add(packs,_cell(Vector2(-560,z)),stop)
	_add_wall_transit(packs)


static func _make_train(label: String, path: PackedVector3Array, cars: int, speed: float, loop: bool, stops := PackedVector3Array(), dwell := 4.0, lane := 0, direction := 1) -> Node3D:
	var train := Node3D.new(); train.name="MoyTrain_%s_%d"%[label.replace(" ","_"),lane]; train.set_script(load("res://scripts/moy_ride_train.gd"))
	train.set("service_name",label); train.set("path",path); train.set("cars",cars); train.set("speed",speed); train.set("loop",loop); train.set("stops",stops); train.set("dwell",dwell); train.set("initial_direction",direction)
	train.call("_build_consist")
	return train


static func _ramp_body(label: String, foot: Vector3, head: Vector3, width: float, thickness: float, color: Color) -> StaticBody3D:
	var delta := head-foot
	var x_axis := delta.normalized()
	var z_axis := Vector3(-x_axis.z,0.0,x_axis.x).normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	var body := _box_body(label,Vector3(delta.length(),thickness,width),(foot+head)*0.5,color)
	body.basis=Basis(x_axis,y_axis,z_axis)
	return body


static func _add_ramp_guardrails(body: StaticBody3D, width: float, length: float) -> void:
	for side in [-1.0,1.0]:
		_add_building_box_part(body,Vector3(length,0.9,0.12),Vector3(0.0,0.65,side*(width*0.5-0.06)),Color("#806f59"))


static func _add_escalator_pair(packs: Dictionary, label: String, foot: Vector3, head: Vector3, total_width: float) -> void:
	var horizontal:=head-foot; horizontal.y=0.0
	var lateral:=Vector3(-horizontal.z,0.0,horizontal.x).normalized()
	if lateral.length_squared()<0.5: lateral=Vector3.RIGHT
	var belt_width:=minf(1.2,total_width*0.46)
	var a:=foot-lateral*belt_width*0.5; var b:=head-lateral*belt_width*0.5
	var up:=_ramp_body("%s_Up"%label,a,b,belt_width,0.32,Color("#b3a27e"))
	up.set_script(load("res://scripts/moy_escalator.gd")); up.set("travel_direction",(b-a).normalized()); up.set("travel_speed",0.9)
	_add(packs,_cell(Vector2((a.x+b.x)*0.5,(a.z+b.z)*0.5)),up)
	var c:=foot+lateral*belt_width*0.5; var d:=head+lateral*belt_width*0.5
	var down:=_ramp_body("%s_Down"%label,d,c,belt_width,0.32,Color("#a49372"))
	down.set_script(load("res://scripts/moy_escalator.gd")); down.set("travel_direction",(c-d).normalized()); down.set("travel_speed",0.9)
	_add(packs,_cell(Vector2((c.x+d.x)*0.5,(c.z+d.z)*0.5)),down)
	var along_z:=absf(horizontal.z)>absf(horizontal.x)
	var landing_size:=Vector3(total_width+0.6,0.3,2.4) if along_z else Vector3(2.4,0.3,total_width+0.6)
	for endpoint_i in 2:
		var endpoint: Vector3=foot if endpoint_i==0 else head
		var landing:=_box_body("%s_Landing_%d"%[label,endpoint_i],landing_size,endpoint-Vector3.UP*0.15,Color("#b6a17b"))
		_add(packs,_cell(Vector2(endpoint.x,endpoint.z)),landing)


static func _add_station_core(packs: Dictionary, core: Dictionary, prefix: String) -> void:
	var c:=Vector2(core.c[0],core.c[1]); var sx:=float(core.size[0]); var sz:=float(core.size[1])
	var levels: Array=core.levels; var max_level:=float(levels[-1]); var frame_height:=max_level+float(core.canopy)
	var post_index:=0
	for xside in [-1.0,1.0]:
		for zside in [-1.0,1.0]:
			var post:=_box_body("%s_%s_Frame_%d"%[prefix,String(core.name).replace(" ","_"),post_index],Vector3(0.45,frame_height,0.45),Vector3(c.x+xside*(sx*0.5-0.25),DATUM+frame_height*0.5,c.y+zside*(sz*0.5-0.25)),Color("#a99a79")); post_index+=1
			_add(packs,_cell(c),post)
	var flights: Array=core.flights
	var p:=-(sz*0.5-1.5); var direction:=1.0
	for i in flights.size():
		var flight: Array=flights[i]; var low:=DATUM+float(flight[0]); var high:=DATUM+float(flight[1]); var run:=float(flight[2])
		var q:=p+direction*run
		# Match the drawing's accumulating switchback: each flight starts where
		# the previous ended, then reverses direction on the next run.
		var foot:=Vector3(c.x,low,c.y+p)
		var head:=Vector3(c.x,high,c.y+q)
		_add_escalator_pair(packs,"%s_%s_Flight_%02d"%[prefix,String(core.name).replace(" ","_"),i],foot,head,2.6)
		var landing_z:=q+direction*0.75
		var landing:=_box_body("%s_%s_Landing_%02d"%[prefix,String(core.name).replace(" ","_"),i],Vector3(3.6,0.35,1.5),Vector3(c.x,high-0.175,c.y+landing_z),Color("#baa781"))
		_add(packs,_cell(Vector2(c.x,c.y+landing_z)),landing)
		var canopy:=_ramp_body("%s_%s_Canopy_%02d"%[prefix,String(core.name).replace(" ","_"),i],foot+Vector3.UP*float(core.canopy),head+Vector3.UP*float(core.canopy),2.9,0.16,Color("#9c927d"))
		_add(packs,_cell(Vector2(c.x,c.y)),canopy)
		p=q; direction=-direction
	# Two small public lift platforms share each open-air core with the ramps.
	for side_index in 2:
		var side: float=-1.0 if side_index==0 else 1.0
		var lift_x:float=c.x+side*(sx*0.5-1.0)
		var car:=AnimatableBody3D.new(); car.name="%s_%s_Lift_%d"%[prefix,String(core.name).replace(" ","_"),side_index]
		car.position=Vector3(lift_x,DATUM,c.y); car.set_script(load("res://scripts/moy_lift_platform.gd"))
		car.set("travel_height",max_level); car.set("base_height",DATUM); car.set("travel_period",maxf(12.0,max_level*1.2))
		var mesh:=BoxMesh.new(); mesh.size=Vector3(1.5,0.25,1.5); var vis:=MeshInstance3D.new(); vis.mesh=mesh; vis.material_override=_material(Color("#c7d1ce")); car.add_child(vis)
		var shape:=BoxShape3D.new(); shape.size=mesh.size; var col:=CollisionShape3D.new(); col.shape=shape; car.add_child(col)
		_add(packs,_cell(c),car)


static func _add_gate_forms(packs: Dictionary) -> void:
	var color:=Color("#b39b73")
	for leg in PLAN.ARCH.legs:
		var r:=Rect2(float(leg[0]),float(leg[1]),float(leg[2])-float(leg[0]),float(leg[3])-float(leg[1])); var center:=r.get_center()
		_add(packs,_cell(center),_box_body("MeridianArchLegLower",Vector3(r.size.x,12.0,r.size.y),Vector3(center.x,DATUM+6.0,center.y),color))
		_add(packs,_cell(center),_box_body("MeridianArchLegUpper",Vector3(r.size.x,51.0,r.size.y),Vector3(center.x,DATUM+46.5,center.y),color))
		# Plan train_hall.arc defines the actual wall openings; leave the 12–21 m band clear through each data-defined leg.
		var hall: Dictionary=PLAN.ARCH.train_hall; var hall_index:=0 if center.y<0 else 1; var bounds: Array=hall.x[hall_index]
		var left_width:=maxf(0.0,float(bounds[0])-r.position.x); var right_start:=minf(r.size.x,float(bounds[1])-r.position.x)
		for part in [Rect2(r.position.x,r.position.y,left_width,r.size.y),Rect2(r.position.x+right_start,r.position.y,r.size.x-right_start,r.size.y)]:
			if part.size.x>0.1: _add(packs,_cell(center),_box_body("MeridianArchTrainHallPier",Vector3(part.size.x,9.0,part.size.y),Vector3(part.get_center().x,DATUM+16.5,part.get_center().y),color))
	for bridge in [[PLAN.ARCH.lower, "MeridianArchLowerBridge"],[PLAN.ARCH.top,"MeridianArchTopBridge"]]:
		var levels: Array=bridge[0]; var y0:=float(levels[0]); var y1:=float(levels[1]); var body:=_box_body(String(bridge[1]),Vector3(PLAN.ARCH.opening, y1-y0, 6.0),Vector3(-352.5,DATUM+(y0+y1)*0.5,0),color); _add(packs,_cell(Vector2(-352.5,0)),body)
	var west_towers: Array=PLAN.WEST_GATE.towers
	for i in west_towers.size():
		var t: Array=west_towers[i]; var r:=Rect2(float(t[0]),float(t[1]),float(t[2])-float(t[0]),float(t[3])-float(t[1])); var c:=r.get_center(); var hall:=PLAN.WEST_GATE.train_hall; var bounds: Array=hall.x[i]
		_add(packs,_cell(c),_box_body("WestGateTowerLower",Vector3(r.size.x,12.0,r.size.y),Vector3(c.x,DATUM+6,c.y),Color("#a78b64")))
		_add(packs,_cell(c),_box_body("WestGateTowerUpper",Vector3(r.size.x,23.0,r.size.y),Vector3(c.x,DATUM+32.5,c.y),Color("#a78b64")))
		var left_width:=maxf(0.0,float(bounds[0])-r.position.x); var right_start:=minf(r.size.x,float(bounds[1])-r.position.x)
		for part in [Rect2(r.position.x,r.position.y,left_width,r.size.y),Rect2(r.position.x+right_start,r.position.y,r.size.x-right_start,r.size.y)]:
			if part.size.x>0.1: _add(packs,_cell(c),_box_body("WestGateTrainHallPier",Vector3(part.size.x,9.0,part.size.y),Vector3(part.get_center().x,DATUM+16.5,c.y),Color("#a78b64")))
	var west_bridge:=PLAN.WEST_GATE.bridge
	_add(packs,_cell(Vector2(-769.5,0)),_box_body("WestGateBridge",Vector3(25.0,float(west_bridge[1])-float(west_bridge[0]),6.0),Vector3(-769.5,DATUM+(float(west_bridge[0])+float(west_bridge[1]))*0.5,0),Color("#bca37c")))
	for core in PLAN.ARCH.cores: _add_station_core(packs,core,"EastGateCore")
	for core in PLAN.WEST_GATE.cores: _add_station_core(packs,core,"WestGateCore")


static func _add_timekeeper(packs: Dictionary) -> void:
	var cfg: Dictionary = PLAN.TIMEKEEPER; var center := Vector3(cfg.x,DATUM+cfg.y,cfg.z)
	var root := Node3D.new(); root.name="TimekeeperRings"; root.set_script(load("res://scripts/moy_timekeeper.gd"))
	root.position=center
	for ring in cfg.rings:
		var inner := float(ring[1]); var outer := float(ring[2])
		var torus := TorusMesh.new(); torus.inner_radius=inner; torus.outer_radius=outer; torus.rings=48; torus.ring_segments=8
		var body:=AnimatableBody3D.new(); body.name="Timekeeper_%s"%String(ring[0]); body.collision_layer=1; body.collision_mask=1; body.sync_to_physics=true
		var visual := MeshInstance3D.new(); visual.mesh=torus; visual.rotation.z=PI*0.5; visual.material_override=_material(Color("#a88955")); body.add_child(visual)
		var collision:=CollisionShape3D.new(); collision.shape=torus.create_trimesh_shape(); collision.rotation.z=PI*0.5; body.add_child(collision)
		if String(ring[0])!="bezel":
			var marker: Dictionary=cfg.markers[String(ring[0])]; var arrow:=_clock_arrow(inner,outer,float(marker.arc),float(marker.proud)); arrow.name="Timekeeper_%s_Arrow"%String(ring[0]); body.add_child(arrow)
		else:
			for mark_i in 60:
				var is_hour:=mark_i%5==0; var angle:=TAU*float(mark_i)/60.0
				var mark:=MeshInstance3D.new(); var box:=BoxMesh.new(); box.size=Vector3(0.16,0.12,1.2 if is_hour and mark_i%15==0 else 0.5 if is_hour else 0.55)
				mark.mesh=box; mark.position=Vector3(0,cos(angle)*12.75,sin(angle)*12.75); mark.rotation.x=angle; mark.material_override=_material(Color("#45433d")); body.add_child(mark)
		root.add_child(body)
	var seconds:=MeshInstance3D.new(); seconds.name="TimekeeperSecondsBead"; var bead:=SphereMesh.new(); bead.radius=float(cfg.seconds.bead); bead.height=float(cfg.seconds.bead)*2; seconds.mesh=bead; seconds.material_override=_material(Color("#f24d38")); seconds.position=Vector3(0,cos(0.0)*float(cfg.seconds.r),sin(0.0)*float(cfg.seconds.r)); root.add_child(seconds)
	_add(packs,_cell(Vector2(center.x,center.z)),root)


static func _clock_arrow(inner: float, outer: float, arc: float, proud: float) -> MeshInstance3D:
	var half:=deg_to_rad(arc)*0.5; var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a:=Vector3(proud,cos(-half)*inner,sin(-half)*inner); var b:=Vector3(proud,cos(half)*inner,sin(half)*inner); var tip:=Vector3(proud,outer,0)
	for side in [-1.0,1.0]:
		var x: float=proud*side; st.set_normal(Vector3(side,0,0)); st.add_vertex(Vector3(x,a.y,a.z)); st.add_vertex(Vector3(x,b.y,b.z)); st.add_vertex(Vector3(x,tip.y,tip.z))
	var mesh:=st.commit(); var arrow:=MeshInstance3D.new(); arrow.mesh=mesh; var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("#f03f35"); mat.emission_enabled=true; mat.emission=Color("#f03f35"); arrow.material_override=mat; return arrow


static func _add_turbines(packs: Dictionary) -> void:
	for i in PLAN.TURBINES.size():
		var p: Vector2=PLAN.TURBINES[i]
		var root:=Node3D.new(); root.name="WindTurbine_%02d"%i; root.position=Vector3(p.x,DATUM,p.y)
		var tower:=StaticBody3D.new(); tower.name="WindTurbineTower"; tower.collision_layer=1; tower.collision_mask=1
		var shaft:=CylinderMesh.new(); shaft.top_radius=1.8; shaft.bottom_radius=3.2; shaft.height=95.0; shaft.radial_segments=10
		var shaft_vis:=MeshInstance3D.new(); shaft_vis.mesh=shaft; shaft_vis.position.y=47.5; shaft_vis.material_override=_material(Color("#e3ded1")); tower.add_child(shaft_vis)
		var shaft_shape:=CylinderShape3D.new(); shaft_shape.radius=3.2; shaft_shape.height=95.0
		var shaft_col:=CollisionShape3D.new(); shaft_col.shape=shaft_shape; shaft_col.position.y=47.5; tower.add_child(shaft_col); root.add_child(tower)
		# The basin's prevailing wind comes from the west: every rotor points
		# west, including the west pair (which must not face back toward Moy).
		var face:=PI
		var nacelle:=_box_body("WindTurbineNacelle",Vector3(12,4.5,4.5),Vector3(-2.5,97.0,0.0),Color("#e3ded1")); nacelle.rotation.y=PI; root.add_child(nacelle)
		var hub_center:=Vector3(-6.5,97.0,0.0)
		var hub:=StaticBody3D.new(); hub.name="WindTurbineHub"; hub.position=hub_center
		var hub_mesh:=SphereMesh.new(); hub_mesh.radius=2.4; var hub_vis:=MeshInstance3D.new(); hub_vis.mesh=hub_mesh; hub_vis.material_override=_material(Color("#e3ded1")); hub.add_child(hub_vis)
		var hub_shape:=SphereShape3D.new(); hub_shape.radius=2.4; var hub_col:=CollisionShape3D.new(); hub_col.shape=hub_shape; hub.add_child(hub_col); root.add_child(hub)
		var rotor:=Node3D.new(); rotor.name="WindTurbineRotor"; rotor.position=hub_center; rotor.rotation.y=-PI*0.5; rotor.set_script(load("res://scripts/moy_wind_turbine_rotor.gd")); rotor.set("turns_per_minute",2.0); root.add_child(rotor)
		for blade_index in 3:
			var angle:=TAU*float(blade_index)/3.0
			var blade:=AnimatableBody3D.new(); blade.name="WindTurbineBlade_%d"%blade_index; blade.collision_layer=1; blade.collision_mask=1; blade.sync_to_physics=true; blade.rotation.z=angle; rotor.add_child(blade)
			var blade_mesh:=BoxMesh.new(); blade_mesh.size=Vector3(3.2,64.0,0.8)
			var blade_vis:=MeshInstance3D.new(); blade_vis.mesh=blade_mesh; blade_vis.position.y=32.0; blade_vis.material_override=_material(Color("#e3ded1")); blade.add_child(blade_vis)
			var blade_shape:=CapsuleShape3D.new(); blade_shape.radius=1.6; blade_shape.height=64.0
			var blade_col:=CollisionShape3D.new(); blade_col.shape=blade_shape; blade_col.position.y=32.0; blade.add_child(blade_col)
		_add(packs,_cell(p),root)


static func _add_wall_transit(packs: Dictionary) -> void:
	var points: Array = PLAN.WALL.centreline
	var rail_y := DATUM + float(PLAN.WALL.height) + 1.2
	var lane_paths: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
	for p in points:
		for lane in 2:
			var radius := PLAN.WALL.r + float(PLAN.WALL.track_axis) + float(lane)*float(PLAN.WALL.track_spacing)
			var radial := Vector2(p[0]-PLAN.CENTER.x,p[1]-PLAN.CENTER.y).normalized()
			lane_paths[lane].append(Vector3(PLAN.CENTER.x+radial.x*radius,rail_y,PLAN.CENTER.y+radial.y*radius))
	for i in points.size()-1:
		var a := Vector2(points[i][0],points[i][1]); var b := Vector2(points[i+1][0],points[i+1][1])
		var bed := _segment_body("WallLine_Track_%d"%i,a,b,8.0,rail_y-0.7,1.4,Color("#77766f")); _add(packs,_cell((a+b)*0.5),bed)
		for lane in 2:
			var la := Vector2(lane_paths[lane][i].x,lane_paths[lane][i].z); var lb := Vector2(lane_paths[lane][i+1].x,lane_paths[lane][i+1].z)
			var across := Vector2(-(lb-la).y,(lb-la).x).normalized()
			for rail_side in [-1.0,1.0]:
				var rail := _segment_body("WallLine_Rail_%d_%d_%d"%[i,lane,int(rail_side)],la+across*rail_side*0.7175,lb+across*rail_side*0.7175,0.16,rail_y,0.2,Color("#555b5d")); _add(packs,_cell((a+b)*0.5),rail)
	var wall_stops := PackedVector3Array()
	for station in PLAN.WALL.stations:
		wall_stops.append(Vector3(station.p[0],rail_y,station.p[1]))
		var station_point:=Vector2(station.p[0],station.p[1])
		var radial: Vector2=(station_point-Vector2(PLAN.CENTER.x,PLAN.CENTER.y)).normalized()
		var theta:=atan2(radial.y,radial.x)
		for lane in 2:
			var track_radius:=float(PLAN.WALL.r)+float(PLAN.WALL.track_axis)+float(lane)*float(PLAN.WALL.track_spacing)
			var platform_offset:=float(PLAN.PLATFORMS.edge)+float(PLAN.CROSS.track)+float(PLAN.PLATFORMS.width)*0.5
			var platform_radius:=track_radius+(-platform_offset if lane==0 else platform_offset)
			var platform_segments:=10
			var platform_half_length:=float(PLAN.CROSS.platform[0])*0.5
			for segment_index in platform_segments:
				var a_angle:=theta-platform_half_length/track_radius+(platform_half_length*2.0)/track_radius*float(segment_index)/float(platform_segments)
				var b_angle:=theta-platform_half_length/track_radius+(platform_half_length*2.0)/track_radius*float(segment_index+1)/float(platform_segments)
				var a:=Vector2(PLAN.CENTER.x+platform_radius*cos(a_angle),PLAN.CENTER.y+platform_radius*sin(a_angle))
				var b:=Vector2(PLAN.CENTER.x+platform_radius*cos(b_angle),PLAN.CENTER.y+platform_radius*sin(b_angle))
				var platform:=_segment_body("WallLine_Station_%s_Platform_%d_%d"%[String(station.name).replace(" ","_"),lane,segment_index],a,b,float(PLAN.PLATFORMS.width),rail_y+0.7,0.3,Color("#c4b18b"))
				_add(packs,_cell((a+b)*0.5),platform)
				var canopy:=_segment_body("WallLine_Station_%s_Canopy_%d_%d"%[String(station.name).replace(" ","_"),lane,segment_index],a,b,float(PLAN.PLATFORMS.width),rail_y+float(PLAN.PLATFORMS.floor)+float(PLAN.PLATFORMS.canopy),0.18,Color("#bcb49b")); _add(packs,_cell((a+b)*0.5),canopy)
	for lane in 2:
		var line_name: String="Wall Line inner" if lane==0 else "Wall Line outer"
		var line_plan: Dictionary=PLAN.TIMETABLE.lines[line_name]
		for train_index in int(line_plan.trains):
			var train := _make_train(line_name,lane_paths[lane],int(PLAN.TRAIN.consists["Wall Line"].cars),float(line_plan.speed),true,wall_stops,float(PLAN.TIMETABLE.dwell.ordinary),lane*3+train_index,1 if lane==0 else -1)
			train.set("schedule_events",line_plan.events); train.set("schedule_offset",float(line_plan.offset)); train.set("schedule_headway",float(PLAN.TIMETABLE.headway)); train.set("schedule_circuit",float(line_plan.circuit)); train.set("schedule_train_index",train_index)
			_add(packs,_cell(Vector2(lane_paths[lane][0].x,lane_paths[lane][0].z)),train)
