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
		var body: StaticBody3D
		if _needs_spine_portal(r,h):
			# Keep the recorded footprint and roof, but form a real clear tunnel
			# through the mass wherever the elevated Spine runs through a lot.
			body=StaticBody3D.new(); body.name="Lot_%03d"%i; body.collision_layer=1; body.collision_mask=1
			body.position=Vector3(r.get_center().x,DATUM,r.get_center().y)
			var tunnel_half_width:=6.8
			var tunnel_bottom:=10.9
			# Covers the highest +20 m gate approach plus the car's roof and query margin.
			var tunnel_top:=24.0
			var spine_x:float=-557.0
			var left_width:=clampf(spine_x-tunnel_half_width-r.position.x,0.0,r.size.x)
			var right_start:=clampf(spine_x+tunnel_half_width-r.position.x,0.0,r.size.x)
			var right_width:=r.size.x-right_start
			if h>tunnel_bottom:
				_add_building_box_part(body,Vector3(r.size.x,minf(h,tunnel_bottom),r.size.y),Vector3(0.0,minf(h,tunnel_bottom)*0.5,0.0),color)
			if h>tunnel_top:
				_add_building_box_part(body,Vector3(r.size.x,h-tunnel_top,r.size.y),Vector3(0.0,(h+tunnel_top)*0.5,0.0),color.lightened(0.12))
			var tunnel_height:=minf(maxf(0.0,h-tunnel_bottom),tunnel_top-tunnel_bottom)
			if tunnel_height>0.05:
				if left_width>0.05:
					_add_building_box_part(body,Vector3(left_width,tunnel_height,r.size.y),Vector3(-r.size.x*0.5+left_width*0.5,tunnel_bottom+tunnel_height*0.5,0.0),color)
				if right_width>0.05:
					_add_building_box_part(body,Vector3(right_width,tunnel_height,r.size.y),Vector3(r.size.x*0.5-right_width*0.5,tunnel_bottom+tunnel_height*0.5,0.0),color)
		else:
			body = _box_body("Lot_%03d" % i, Vector3(r.size.x, h, r.size.y), Vector3(r.get_center().x, DATUM + h * 0.5, r.get_center().y), color)
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
	_add_deck(packs)
	_add_wall(packs)
	_add_park(packs)
	_add_estate_links(packs)
	_add_transit(packs)
	_add_gate_forms(packs)
	_add_timekeeper(packs)
	_add_turbines(packs)
	return packs


static func build_silhouette() -> Node3D:
	var root := Node3D.new(); root.name="MoyDistantSilhouette"
	var box := BoxMesh.new(); box.size=Vector3.ONE
	var material := StandardMaterial3D.new(); material.albedo_color=Color("#a88f70"); material.roughness=1.0
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo=true
	var lots := MultiMesh.new(); lots.transform_format=MultiMesh.TRANSFORM_3D; lots.use_colors=true; lots.mesh=box
	lots.instance_count=PLAN.LOTS.size()
	for i in PLAN.LOTS.size():
		var l: Array=PLAN.LOTS[i]; var r: Rect2=l[0]; var h:=float(l[1])*float(PLAN.STOREY[l[2]])
		lots.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3(r.size.x,h,r.size.y)),Vector3(r.get_center().x,DATUM+h*0.5,r.get_center().y)))
		lots.set_instance_color(i,Color("#b9a181") if String(l[2])=="fabric" else Color("#a48f73"))
	var li := MultiMeshInstance3D.new(); li.name="LotSilhouettes"; li.multimesh=lots; li.material_override=material; li.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(li)
	var old := MultiMesh.new(); old.transform_format=MultiMesh.TRANSFORM_3D; old.use_colors=true; old.mesh=box
	old.instance_count=PLAN.OLD_HOUSES.size()
	for i in PLAN.OLD_HOUSES.size():
		var h: Dictionary=PLAN.OLD_HOUSES[i]; var pts: Array=h.corners
		var r:=_point_bounds(pts); var height:=float(h.storeys)*3.25
		old.set_instance_transform(i,Transform3D(Basis.from_scale(Vector3(r.size.x,height,r.size.y)),Vector3(r.get_center().x,DATUM+height*0.5,r.get_center().y)))
		old.set_instance_color(i,Color("#c6aa82"))
	var oi := MultiMeshInstance3D.new(); oi.name="OldHouseSilhouettes"; oi.multimesh=old; oi.material_override=material; oi.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(oi)
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
	var multi:=MultiMesh.new(); multi.transform_format=MultiMesh.TRANSFORM_3D; multi.mesh=mesh; multi.instance_count=64
	var r:=float(PLAN.WALL.r)
	for i in 64:
		var a:=TAU*float(i)/64.0; var b:=TAU*float(i+1)/64.0; var mid:Vector2=Vector2(PLAN.CENTER.x+r*cos((a+b)*0.5),r*sin((a+b)*0.5))
		var blocked:=false
		for gate in PLAN.WALL.gates:
			if Vector2(gate.p[0],gate.p[1]).distance_to(mid)<17.0: blocked=true
		var d:=Vector2(PLAN.CENTER.x+r*cos(b),r*sin(b))-Vector2(PLAN.CENTER.x+r*cos(a),r*sin(a))
		var segment_scale:=Vector3.ZERO if blocked else Vector3(d.length(),12.0,12.0)
		var transform:=Transform3D(Basis(Vector3.UP,-atan2(d.y,d.x))*Basis.from_scale(segment_scale),Vector3(mid.x,DATUM+6.0,mid.y))
		multi.set_instance_transform(i,transform)
	var wall:=MultiMeshInstance3D.new(); wall.name="RimWallSilhouette"; wall.multimesh=multi; wall.material_override=material; wall.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; root.add_child(wall)


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


static func _needs_spine_portal(rect: Rect2, height: float) -> bool:
	if height<=10.9: return false
	for service in PLAN.CROSS.services:
		if String(service.line)!="Spine Line": continue
		var points: Array=service.get("profile",service.pts)
		for i in points.size()-1:
			var a:=Vector2(points[i][0],points[i][1]); var b:=Vector2(points[i+1][0],points[i+1][1])
			var d:=b-a
			if absf(d.y)<=absf(d.x): continue
			var train_z_min:=minf(a.y,b.y)-4.8; var train_z_max:=maxf(a.y,b.y)+4.8
			if rect.position.x<=a.x+6.8 and rect.end.x>=a.x-6.8 and rect.position.y<=train_z_max and rect.end.y>=train_z_min:
					return true
	return false


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
	if n == 37:
		# The authored Spine track passes this shop within 0.3 m of its west
		# wall. Cut a train-sized portal through the edge, including car body
		# clearance below the rail centreline; retain the shop around the portal.
		var body:=StaticBody3D.new(); body.name="Building_37_%s"%String(b.name).replace(" ","_"); body.collision_layer=1; body.collision_mask=1
		body.position=Vector3(center.x,DATUM,center.y)
		_add_building_box_part(body,Vector3(5.5,h,r.size.y),Vector3(1.25,h*0.5,0.0),color)
		_add_building_box_part(body,Vector3(2.5,9.0,r.size.y),Vector3(-2.75,4.5,0.0),color)
		_add_building_box_part(body,Vector3(2.5,0.2,r.size.y),Vector3(-2.75,17.1,0.0),color.lightened(0.12))
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


static func _add_deck(packs: Dictionary) -> void:
	var level := DATUM + float(PLAN.DECK.level)
	# The authored paired columns carry each Deck run from terrain to its soffit.
	for p in PLAN.DECK.columns:
		var column_height:=float(PLAN.DECK.level)-0.9
		var column:=_box_body("DeckColumn",Vector3(0.9,column_height,0.9),Vector3(float(p[0]),DATUM+column_height*0.5,float(p[1])),Color("#978b74"))
		_add(packs,_cell(Vector2(float(p[0]),float(p[1]))),column)
	for run in PLAN.DECK.runs:
		var pts: Array = run.pts
		for j in pts.size()-1:
			var a := Vector2(pts[j][0],pts[j][1]); var b := Vector2(pts[j+1][0],pts[j+1][1])
			var width := float(run.w)
			var bridge := _segment_body("Deck_%s_%d" % [run.name,j],a,b,width,level-0.45,0.9,Color("#b8a782"))
			_add(packs,_cell((a+b)*0.5),bridge)
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
		_add_ramp_guardrails(lower_flight,2.6,bottom.distance_to(mid))
		_add_ramp_guardrails(upper_flight,2.6,mid.distance_to(top))
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
	for p in PLAN.CROSS.stations:
		for escalator in p.get("_esc",[]):
			var foot:=Vector3(escalator.foot[0],DATUM+6.5,escalator.foot[1])
			var head:=Vector3(escalator.head[0],DATUM+13.0,escalator.head[1])
			_add_escalator_pair(packs,"SpinePlatformEscalator_%s"%String(p.name).replace(" ","_"),foot,head,2.6)


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


static func _add_park(packs: Dictionary) -> void:
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


static func _add_estate_links(packs: Dictionary) -> void:
	for i in PLAN.ESTATE.linkways.size():
		var link: Array = PLAN.ESTATE.linkways[i]
		for j in link.size()-1:
			var a := Vector2(link[j][0],link[j][1]); var b := Vector2(link[j+1][0],link[j+1][1])
			var body := _segment_body("EstateLink_%d_%d"%[i,j],a,b,3.0,DATUM+6.5,0.8,Color("#b3a27d"))
			_add(packs,_cell((a+b)*0.5),body)


static func _add_transit(packs: Dictionary) -> void:
	for service in PLAN.CROSS.services:
		var line_name := String(service.line)
		var route := PackedVector3Array()
		if line_name == "Spine Line" and service.has("profile"):
			for p in service.profile: route.append(Vector3(p[0],DATUM+float(p[2]),p[1]))
		else:
			for p in service.pts: route.append(Vector3(p[0],DATUM+float(service.rail),p[1]))
		var lane_paths: Array[PackedVector3Array] = [PackedVector3Array(), PackedVector3Array()]
		for lane in 2:
			var offset := -1.7 if lane == 0 else 1.7
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
				var lane_offset:float=-1.7 if lane==0 else 1.7
				for rail_side in [-1.0,1.0]:
					var rail_offset:float=lane_offset+rail_side*0.7175
					var rail:=_ramp_body("%s_Rail_%d_%d_%d"%[line_name,i,lane,int(rail_side)],a+across*rail_offset,b+across*rail_offset,0.16,0.2,Color("#555b5d"))
					_add(packs,_cell(Vector2(mid.x,mid.z)),rail)
		var pier_xs: Array = service.get("piers", [])
		if not pier_xs.is_empty():
			for x in pier_xs:
				var rail_y:=DATUM+float(service.rail)
				var pier := _box_body("MeridianTreePier",Vector3(2.4,rail_y-DATUM-1.2,2.4),Vector3(float(x),DATUM+(rail_y-DATUM-1.2)*0.5,0),Color("#888173"))
				_add(packs,_cell(Vector2(float(x),0)),pier)
		elif line_name == "Spine Line":
			for i in route.size()-1:
				var mid:Vector3=(route[i]+route[i+1])*0.5
				if absf(mid.z+212.0)<18.0 or absf(mid.z-212.0)<18.0: continue
				var top:=maxf(route[i].y,route[i+1].y)-1.2
				for xoff in [-5.0,5.0]:
					var height:=top-DATUM
					if height<=0.5: continue
					var pier:=_box_body("SpinePortalPier",Vector3(1.0,height,1.0),Vector3(mid.x+xoff,DATUM+height*0.5,mid.z),Color("#938a78"))
					_add(packs,_cell(Vector2(mid.x+xoff,mid.z)),pier)
				var beam:=_ramp_body("SpinePortalCrossbeam",Vector3(mid.x-5.5,top,mid.z),Vector3(mid.x+5.5,top,mid.z),0.8,0.8,Color("#938a78"))
				_add(packs,_cell(Vector2(mid.x,mid.z)),beam)
		for station in PLAN.CROSS.stations:
			if not station.lines.has(line_name): continue
			var p: Vector2=Vector2(station.at[0],station.at[1]); var plat := PLAN.CROSS.platform
			var station_y:=DATUM+float(station.get("rail",service.rail))
			var along_z:=line_name=="Spine Line"
			for side in [-1.0,1.0]:
				var platform_size:=Vector3(plat[1],0.3,plat[0]) if along_z else Vector3(plat[0],0.3,plat[1])
				var platform_center:=Vector3(p.x+(side*5.2 if along_z else 0.0),station_y+0.1,p.y+(0.0 if along_z else side*5.2))
				var platform := _box_body("Station_%s_%s_%d"%[line_name,String(station.name).replace(" ","_"),int(side)],platform_size,platform_center,Color("#c4b18b"))
				_add(packs,_cell(p),platform)
		var loop := line_name == "Wall Line"
		var path := PackedVector3Array()
		if loop:
			for i in 64:
				var angle := TAU*float(i)/64.0
				path.append(Vector3(PLAN.CENTER.x+PLAN.WALL.r*cos(angle),DATUM+PLAN.WALL.height+1.2,PLAN.WALL.r*sin(angle)))
		else:
			path=route
		var stops := PackedVector3Array()
		for station in PLAN.CROSS.stations:
			if station.lines.has(line_name): stops.append(Vector3(station.at[0],DATUM+float(station.get("rail",service.rail)),station.at[1]))
		for lane in 2:
			var lane_path := lane_paths[lane] if not loop else path
			var train := _make_train(line_name,lane_path,int(PLAN.TRAIN.consists[line_name].cars),float(PLAN.CROSS.cars.speed),false,stops,float(PLAN.CROSS.cars.dwell),lane,1 if lane == 0 else -1)
			_add(packs,_cell(Vector2(path[0].x,path[0].z)),train)
	# Use the authored flight levels/runs for every open-air station core. Each
	# flight is a paired, directional moving walkway with real landings and lifts.
	for core in PLAN.CROSSING.cores: _add_station_core(packs,core,"CrossingCore")
	for core in PLAN.ARCH.cores: _add_station_core(packs,core,"EastGateCore")
	for core in PLAN.WEST_GATE.cores: _add_station_core(packs,core,"WestGateCore")
	for gate_sign in [-1.0,1.0]:
		var gate_z:float=212.0*gate_sign
		var foot:=Vector3(-585.0,DATUM+PLAN.WALL.height+1.2,gate_z-23.0*gate_sign)
		var head:=Vector3(-585.0,DATUM+20.0,gate_z-10.0*gate_sign)
		_add_escalator_pair(packs,"SpineGateEscalator_%s"%("North" if gate_sign<0 else "South"),foot,head,2.6)
		var access_walk:=_box_body("SpineGateAccessWalk",Vector3(22.5,0.32,4.0),Vector3(-573.75,DATUM+19.84,head.z),Color("#b6a17b"))
		_add(packs,_cell(Vector2(-573.75,head.z)),access_walk)
	_add_wall_transit(packs)


static func _make_train(label: String, path: PackedVector3Array, cars: int, speed: float, loop: bool, stops := PackedVector3Array(), dwell := 4.0, lane := 0, direction := 1) -> Node3D:
	var train := Node3D.new(); train.name="MoyTrain_%s_%d"%[label.replace(" ","_"),lane]; train.set_script(load("res://scripts/moy_ride_train.gd"))
	train.set("service_name",label); train.set("path",path); train.set("cars",cars); train.set("speed",speed); train.set("loop",loop); train.set("stops",stops); train.set("dwell",dwell); train.set("initial_direction",direction)
	if label in ["Wall Line","Spine Line"]:
		var conflict_points:=PackedVector3Array()
		for junction in PLAN.CROSS.junctions:
			for gate in PLAN.WALL.gates:
				if gate.name == junction:
					conflict_points.append(Vector3(gate.p[0],DATUM+PLAN.WALL.height+1.2,gate.p[1]))
		train.set("conflict_points",conflict_points)
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
	for lane in 2:
		var side:=(-1.0 if lane==0 else 1.0)*(belt_width*0.5+0.06)
		var offset:=lateral*side
		var a:=foot+offset; var b:=head+offset
		var up:=_ramp_body("%s_Up"%label,a,b,belt_width,0.32,Color("#b3a27e"))
		up.set_script(load("res://scripts/moy_escalator.gd")); up.set("travel_direction",(b-a).normalized()); up.set("travel_speed",0.9)
		_add_ramp_guardrails(up,belt_width,a.distance_to(b))
		_add(packs,_cell(Vector2((a.x+b.x)*0.5,(a.z+b.z)*0.5)),up)
		var down:=_ramp_body("%s_Down"%label,b,a,belt_width,0.32,Color("#a49372"))
		down.set_script(load("res://scripts/moy_escalator.gd")); down.set("travel_direction",(a-b).normalized()); down.set("travel_speed",0.9)
		_add_ramp_guardrails(down,belt_width,a.distance_to(b))
		_add(packs,_cell(Vector2((a.x+b.x)*0.5,(a.z+b.z)*0.5)),down)
	var along_z:=absf(horizontal.z)>absf(horizontal.x)
	var landing_size:=Vector3(total_width+0.6,0.3,2.4) if along_z else Vector3(2.4,0.3,total_width+0.6)
	for endpoint in [foot,head]:
		var landing:=_box_body("%s_Landing"%label,landing_size,endpoint-Vector3.UP*0.15,Color("#b6a17b"))
		_add(packs,_cell(Vector2(endpoint.x,endpoint.z)),landing)


static func _add_station_core(packs: Dictionary, core: Dictionary, prefix: String) -> void:
	var c:=Vector2(core.c[0],core.c[1]); var sx:=float(core.size[0]); var sz:=float(core.size[1])
	var levels: Array=core.levels; var max_level:=float(levels[-1]); var frame_height:=max_level+float(core.canopy)
	for xside in [-1.0,1.0]:
		for zside in [-1.0,1.0]:
			var post:=_box_body("%s_%s_Frame"%[prefix,String(core.name).replace(" ","_")],Vector3(0.45,frame_height,0.45),Vector3(c.x+xside*(sx*0.5-0.25),DATUM+frame_height*0.5,c.y+zside*(sz*0.5-0.25)),Color("#a99a79"))
			_add(packs,_cell(c),post)
	var flights: Array=core.flights
	for i in flights.size():
		var flight: Array=flights[i]; var low:=DATUM+float(flight[0]); var high:=DATUM+float(flight[1]); var run:=float(flight[2])
		var side: float=-1.0 if i%2==0 else 1.0
		# Switchback flights use separate lateral lanes: overlapping centerlines
		# made the prior ramp stack impassable at intermediate landings.
		var lane_x:=c.x+(-1.35 if i%2==0 else 1.35)
		var foot:=Vector3(lane_x,low,c.y+side*run*0.5)
		var head:=Vector3(lane_x,high,c.y-side*run*0.5)
		_add_escalator_pair(packs,"%s_%s_Flight_%02d"%[prefix,String(core.name).replace(" ","_"),i],foot,head,2.6)
		for endpoint in [foot,head]:
			var landing:=_box_body("%s_%s_Landing_%02d"%[prefix,String(core.name).replace(" ","_"),i],Vector3(3.6,0.35,2.6),Vector3(lane_x,endpoint.y-0.175,endpoint.z),Color("#baa781"))
			_add(packs,_cell(Vector2(lane_x,endpoint.z)),landing)
		var canopy:=_ramp_body("%s_%s_Canopy_%02d"%[prefix,String(core.name).replace(" ","_"),i],foot+Vector3.UP*float(core.canopy),head+Vector3.UP*float(core.canopy),2.9,0.16,Color("#9c927d"))
		_add(packs,_cell(Vector2(c.x,c.y)),canopy)
	# Two small public lift platforms share each open-air core with the ramps.
	for side in [-1.0,1.0]:
		var lift_x:float=c.x+side*(sx*0.5-1.0)
		var car:=AnimatableBody3D.new(); car.name="%s_%s_Lift"%[prefix,String(core.name).replace(" ","_")]
		car.position=Vector3(lift_x,DATUM,c.y); car.set_script(load("res://scripts/moy_lift_platform.gd"))
		car.set("travel_height",max_level); car.set("base_height",DATUM); car.set("travel_period",maxf(12.0,max_level*1.2))
		var mesh:=BoxMesh.new(); mesh.size=Vector3(1.5,0.25,1.5); var vis:=MeshInstance3D.new(); vis.mesh=mesh; vis.material_override=_material(Color("#c7d1ce")); car.add_child(vis)
		var shape:=BoxShape3D.new(); shape.size=mesh.size; var col:=CollisionShape3D.new(); col.shape=shape; car.add_child(col)
		_add(packs,_cell(c),car)


static func _add_gate_forms(packs: Dictionary) -> void:
	# The East Gate is the open Meridian Arch; the West Gate's pair of towers
	# holds an elevated crossbeam. Openings retain street and track clearance.
	# The East Gate's Wall Line passes through these supports at +12 m. Preserve
	# the authored piers while leaving a 4 m high, 11 m wide train hall through
	# the support band (the cars sweep wider than the two 3.4 m track centres).
	for p in [[-362,-30,-340,-12],[-362,12,-340,30]]:
		var r := Rect2(p[0],p[1],p[2]-p[0],p[3]-p[1]); var h := 72.0
		var opening := Vector2(-357.0,-346.0)
		var low := _box_body("MeridianArchLeg_Lower",Vector3(r.size.x,13.0,r.size.y),Vector3(r.get_center().x,DATUM+6.5,r.get_center().y),Color("#b39b73")); _add(packs,_cell(r.get_center()),low)
		var high := _box_body("MeridianArchLeg_Upper",Vector3(r.size.x,h-17.0,r.size.y),Vector3(r.get_center().x,DATUM+(h+17.0)*0.5,r.get_center().y),Color("#b39b73")); _add(packs,_cell(r.get_center()),high)
		for side in [Vector2(r.position.x,opening.x),Vector2(opening.y,r.end.x)]:
			var width: float = side.y-side.x
			var pier := _box_body("MeridianArchLeg_Pier",Vector3(width,4.0,r.size.y),Vector3((side.x+side.y)*0.5,DATUM+15.0,r.get_center().y),Color("#b39b73")); _add(packs,_cell(r.get_center()),pier)
	for x in [-790.0,-752.0]:
		for z in [-11.0,11.0]:
			var tower := _box_body("WestGateTower",Vector3(10,34,10),Vector3(x,DATUM+17,z),Color("#a78b64")); _add(packs,_cell(Vector2(x,z)),tower)
	var beam := _box_body("WestGateBridge",Vector3(44,7,6),Vector3(-771,DATUM+48,0),Color("#bca37c")); _add(packs,_cell(Vector2(-771,0)),beam)
	for z in [-212.0,212.0]:
		for x in [-605.0,-505.0]:
			# Posts flank both tracks and carry a high lintel above the train sweep.
			var post:=_box_body("NorthSouthGatePost",Vector3(3.0,25.0,6.0),Vector3(x,DATUM+12.5,z),Color("#ad9873")); _add(packs,_cell(Vector2(x,z)),post)
		var lintel:=_box_body("NorthSouthGateLintel",Vector3(26.0,2.0,6.0),Vector3(-557.0,DATUM+26.0,z),Color("#c0aa7d")); _add(packs,_cell(Vector2(-557.0,z)),lintel)
	var east_bridge:=_box_body("MeridianArchHighStationBridge",Vector3(24.0,6.0,30.0),Vector3(-351.0,DATUM+44.0,0.0),Color("#aa936c")); _add(packs,_cell(Vector2(-351.0,0.0)),east_bridge)


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
		root.add_child(body)
	_add(packs,_cell(Vector2(center.x,center.z)),root)


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
			var platform_radius:=track_radius+(-3.6 if lane==0 else 3.6)
			var platform_segments:=10
			for segment_index in platform_segments:
				var a_angle:=theta-20.0/track_radius+40.0/track_radius*float(segment_index)/float(platform_segments)
				var b_angle:=theta-20.0/track_radius+40.0/track_radius*float(segment_index+1)/float(platform_segments)
				var a:=Vector2(PLAN.CENTER.x+platform_radius*cos(a_angle),PLAN.CENTER.y+platform_radius*sin(a_angle))
				var b:=Vector2(PLAN.CENTER.x+platform_radius*cos(b_angle),PLAN.CENTER.y+platform_radius*sin(b_angle))
				var platform:=_segment_body("WallLine_Station_%s_Platform_%d"%[String(station.name).replace(" ","_"),lane],a,b,3.0,rail_y-0.05,0.3,Color("#c4b18b"))
				_add(packs,_cell((a+b)*0.5),platform)
	for lane in 2:
		for set_index in 2:
			var phase := 0.08 if set_index == 0 else 0.58
			var train := _make_train("Wall Line",lane_paths[lane],int(PLAN.WALL.line.cars),float(PLAN.WALL.line.speed),true,wall_stops,float(PLAN.WALL.line.dwell),lane*2+set_index,1 if lane == 0 else -1)
			train.set("initial_phase",phase)
			_add(packs,_cell(Vector2(lane_paths[lane][0].x,lane_paths[lane][0].z)),train)
