extends Node3D

const BAKE := preload("res://scripts/settlement_bake.gd")
const PLAN := preload("res://scripts/chinese_plan.gd")
var errors: Array[String]=[]


func _ready() -> void:
	get_tree().create_timer(90.0).timeout.connect(func() -> void: get_tree().quit(2))
	if not BAKE.valid():
		push_error("China bake is stale. Run tools/bake_chinese_village.tscn in a scratch project and copy assets/generated back.")
		get_tree().quit(1)
		return
	var world := load("res://scenes/chinese_village_qa.tscn").instantiate() as Node3D
	add_child(world)
	await LoadingScreen.wait_for_world_builds()
	for i in 8: await get_tree().process_frame
	var village := world.get_node("ChineseVillage")
	var items: Dictionary=village.get("_plan_items")
	_check(items.size()>=25,"baked plan lost its authored structures")
	for key in ["kitchen","apartments","dining_hall","throne_hall"]:
		var item: Node3D=items.get(key)
		_check(is_instance_valid(item),"missing "+key)
		if not is_instance_valid(item): continue
		var shell := item.get_node("PlanStructure") as StaticBody3D
		var floor_size := Vector2.ZERO
		for collider in shell.get_children():
			if collider is CollisionShape3D and collider.shape is BoxShape3D and collider.shape.size.y<=0.21 and absf(collider.position.y)<0.11:
				var size: Vector3=collider.shape.size
				var basis := shell.global_basis
				floor_size=Vector2(absf(basis.x.x)*size.x+absf(basis.z.x)*size.z,absf(basis.x.z)*size.x+absf(basis.z.z)*size.z)
				break
		var record: Dictionary={}
		for candidate in PLAN.ITEMS:
			if candidate.key==key: record=candidate
		_check(floor_size.distance_to(Vector2(record.rect[2],record.rect[3]))<0.02,"built footprint differs from plan: "+key+" "+str(floor_size))
	var throne := items["throne_hall"].get_node("PlanStructure") as Node3D
	_check(int(throne.get_meta("bay_count",0))==7,"throne hall lost its seven bays")
	_check(is_equal_approx(float(throne.get_meta("column_height",0)),6.6),"throne hall has domestic proportions")
	_check(throne.get_meta("roof_family","")=="wudian2","throne hall lost its double-eave hip roof")
	var apartments := items["apartments"].get_node("PlanStructure") as Node3D
	_check(apartments.find_children("ApartmentDoor*","Node3D",true,false).size()==3,"civic rooms need three independent gallery doors")
	var home := items["lantern_home"].get_node("PlanStructure") as Node3D
	_check(int(home.get_meta("bay_count",0))==3,"household room lost its three bays")
	_check(is_equal_approx(home.position.y,0.45),"household plinth datum differs from the reference")
	var pavilion := items["high_pavilion"].get_node("PlanStructure") as Node3D
	var headroom := PhysicsRayQueryParameters3D.create(pavilion.to_global(Vector3(0,3.45,0)),pavilion.to_global(Vector3(0,5.65,0)),1)
	_check(world.get_world_3d().direct_space_state.intersect_ray(headroom).is_empty(),"lower roof blocks the pavilion's upper storey")
	var geometry := village.get_node("LinyuanPlan/BakedArchitecture")
	_check(geometry.find_children("*","CSGShape3D",true,false).is_empty(),"live CSG survived the bake")
	var batches := geometry.find_children("Crops_*","MultiMeshInstance3D",true,false)
	_check(batches.size()>=12 and batches.size()<=20,"fields are not spatial crop batches")
	for post in village.find_children("LinyuanLanternPost*","StaticBody3D",true,false):
		var lantern := post.get_node("DengLong") as Node3D
		_check(absf(lantern.position.x)<0.001 and absf(lantern.position.z)<0.001,"lantern is not centered on its post")
	var door := throne.get_node("HallDoorFront")
	_check(door.get("_hinges").size()==2,"baked door lost its moving leaves")
	door.set_open_state(true)
	_check(door.is_open(),"baked door cannot open")
	door.set_open_state(false)
	_check(not door.is_open(),"baked door cannot close")
	var ground: float=village.get("_island_surface_y")
	_check_fidelity(world,village,items,ground)
	_check_inn_architecture(world,village.get("_region_inn"))
	_check_household_routes(world,items)
	_check_resident_looks(village)
	_check_pine_clearance(world,geometry)
	await _check_real_ponds(world,ground)
	var mount := get_tree().get_first_node_in_group("manchego") as Manchego
	mount.set_physics_process(false)
	mount.set_process(false)
	for ramp in PLAN.RAMPS:
		for section in ramp.get("segments",[]):
			_check_section(world,ground,section,ramp.name)
			if section.kind=="flight":
				await _drive_mount(mount,ground,section,ramp.name)
	await _check_mount_wall(world,mount,ground)
	# Unloading keeps recruited companions, removes local actors/inn, and then
	# rebuilds the current quest state without duplicated guests or stale doors.
	var panda: Node3D=null
	for actor in village.get("_region_guests"):
		if actor is Pandy: panda=actor
	if panda!=null:
		panda.set("in_party",true)
		WorldState.pandy_joined=true
	WorldState.chinese_village_rule_delegated=true
	var packed_reference: WeakRef = weakref(village.get("_cached_scene"))
	village.call("_unload_region")
	for i in 3: await get_tree().process_frame
	_check(village.get("_plan_root")==null,"detail did not unload")
	_check(village.get("_cached_scene")==null,"unloading retained its PackedScene")
	_check(packed_reference.get_ref()==null,"unloading did not release the baked resource")
	_check(panda==null or is_instance_valid(panda),"unloading deleted a recruited companion")
	village.call("_build_village")
	for i in 5: await get_tree().process_frame
	items=village.get("_plan_items")
	_check(items["throne_hall"].get_node("PlanStructure/HallDoorFront").is_open(),"civic state was lost across reload")
	_check(get_tree().get_nodes_in_group("pandy").size()==1,"region reload duplicated Pandy")
	# Exercise the threaded prefetch path, rather than only direct construction.
	village.call("_unload_region")
	for i in 3: await get_tree().process_frame
	village.set("stream_detail",true)
	for i in 300:
		village.call("_update_region")
		if village.get("_plan_root")!=null: break
		await get_tree().create_timer(0.01).timeout
	_check(village.get("_plan_root")!=null,"threaded region activation failed")
	if errors.is_empty(): print("PASS China runtime: baked footprints, roof rank, centered lanterns, crop batches, doors, ramp surfaces and character clearance, driven mount, unload/reload, party and civic state, threaded activation")
	else:
		for error in errors: push_error(error)
	get_tree().quit(0 if errors.is_empty() else 1)


func _check(condition: bool, message: String) -> void:
	if not condition: errors.append(message)


func _drive_mount(mount: Manchego, ground: float, section: Dictionary, label_text: String) -> void:
	var a := Vector2(section.a[0],section.a[1])
	var b := Vector2(section.b[0],section.b[1])
	var direction := (b-a).normalized()
	var start := a.lerp(b,0.20)
	mount.global_position=Vector3(250+start.x,ground+lerpf(float(section.from_y),float(section.to_y),0.20),-650+start.y)
	mount.rotation.y=atan2(direction.x,direction.y)
	var moved := false
	for i in 120:
		mount.drive_from_player(Vector3(direction.x,0,direction.y),1.0/60.0,false)
		await get_tree().physics_frame
		var point := Vector2(mount.global_position.x-250,mount.global_position.z+650)
		if (point-a).dot(direction)>a.distance_to(b)*0.80:
			moved=true
			break
	_check(moved,"ridden mount cannot traverse "+label_text)
	_check(mount.global_position.y>ground-0.2,"ridden mount snapped through the island on "+label_text)


func _check_mount_wall(world: Node3D, mount: Manchego, ground: float) -> void:
	var wall := StaticBody3D.new()
	wall.position=Vector3(240,ground+1.5,-620)
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=Vector3(4,3,0.4)
	collider.shape=box
	wall.add_child(collider)
	world.add_child(wall)
	mount.global_position=Vector3(240,ground,-624)
	mount.rotation.y=0
	await get_tree().physics_frame
	for i in 60:
		mount.drive_from_player(Vector3.BACK,1.0/60.0,false)
		await get_tree().physics_frame
	_check(mount.global_position.z < -620.8,"ramp support weakened the mount's wall collision")
	wall.queue_free()


func _check_section(world: Node3D, ground: float, section: Dictionary, label_text: String) -> void:
	var a := Vector2(section.a[0],section.a[1])
	var b := Vector2(section.b[0],section.b[1])
	var ay: float=section.get("from_y",section.get("height",0))
	var by: float=section.get("to_y",section.get("height",0))
	for i in range(1,12):
		var t := float(i)/12.0
		var p := a.lerp(b,t)
		var expected := ground+lerpf(ay,by,t)
		var query := PhysicsRayQueryParameters3D.create(Vector3(250+p.x,expected+0.20,-650+p.y),Vector3(250+p.x,expected-0.20,-650+p.y),1)
		var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
		_check(not hit.is_empty() and absf(float(hit.get("position",Vector3.ZERO).y)-expected)<0.12,"ramp surface gap/datum: "+label_text+" sample "+str(i))
		if section.kind=="flight":
			var slope := absf(by-ay)/maxf(a.distance_to(b),0.01)
			var direction := (b-a).normalized()
			for profile in ["player","Blorbus","Manchego"]:
				var shape_query := PhysicsShapeQueryParameters3D.new()
				var half_height := 0.0
				var clearance := 0.20
				if profile=="player":
					var capsule := CapsuleShape3D.new()
					capsule.radius=0.4
					capsule.height=1.9
					shape_query.shape=capsule
					half_height=0.95
					clearance+=0.4*(sqrt(1.0+slope*slope)-1.0)
				elif profile=="Blorbus":
					var sphere := SphereShape3D.new()
					sphere.radius=Blorb.COLLIDER_RADIUS
					shape_query.shape=sphere
					half_height=sphere.radius
					clearance+=sphere.radius*(sqrt(1.0+slope*slope)-1.0)
				else:
					var box := BoxShape3D.new()
					box.size=Vector3(0.7,1.5,1.7)
					shape_query.shape=box
					half_height=0.75
					clearance+=0.85*slope
				shape_query.transform=Transform3D(Basis(Vector3.UP,atan2(direction.x,direction.y)),Vector3(250+p.x,expected+half_height+clearance,-650+p.y))
				shape_query.collision_mask=1
				_check(world.get_world_3d().direct_space_state.intersect_shape(shape_query).is_empty(),"blocked "+profile+" clearance on "+label_text+" sample "+str(i))


func _check_fidelity(world: Node3D, village: Node3D, items: Dictionary, ground: float) -> void:
	var inn := village.get("_region_inn") as Node3D
	_check(absf(absf(inn.rotation.y)-PI)<0.001,"inn hall does not face its front court squarely")
	for bed in inn.find_children("PartyBed*","Node3D",false,false):
		for visual in bed.find_children("*","MeshInstance3D",true,false):
			var mesh: MeshInstance3D=visual
			var bounds := mesh.mesh.get_aabb()
			for corner in 8:
				var at := inn.to_local(mesh.to_global(bounds.get_endpoint(corner)))
				_check(absf(at.x)<8.51 and absf(at.z)<5.51,"inn bed extends outside its finished hall")
		var foot: Vector3=bed.global_position
		var floor_query := PhysicsRayQueryParameters3D.create(foot+Vector3(0,0.18,0),foot-Vector3(0,0.25,0),1)
		floor_query.exclude=[bed.get_rid()]
		var hit := world.get_world_3d().direct_space_state.intersect_ray(floor_query)
		_check(not hit.is_empty(),"inn bed has no supporting floor")
	var gate := items["gatehouse"].get_node("PlanStructure") as Node3D
	for lateral in [-1.2,0.0,1.2]:
		var query := PhysicsRayQueryParameters3D.create(gate.to_global(Vector3(lateral,1.4,-5.5)),gate.to_global(Vector3(lateral,1.4,5.5)),1)
		_check(world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"gatehouse's public arch is obstructed")
	_check(gate.get_meta("passage_width",0)==4.0,"arrival gate is not the authored four-metre passage")
	var geometry := village.get_node("LinyuanPlan/BakedArchitecture")
	_check(geometry.find_children("ChainAnchoragePortal*","StaticBody3D",true,false).size()==4,"chain crossings lack their four masonry anchorage portals")
	for batch in geometry.find_children("*","MultiMeshInstance3D",true,false):
		var data: PackedFloat32Array=batch.get_meta("baked_instance_buffer",PackedFloat32Array())
		_check(data.size()==batch.multimesh.instance_count*12 and data.size()>0,"bake lost crop/bamboo/chain transform data: "+String(batch.name))
	var chains := geometry.find_children("ForgedChainLinks*","MultiMeshInstance3D",true,false)
	_check(chains.size()==2,"chain bridges lost their instanced forged links")
	for chain in chains:
		var buffer: PackedFloat32Array=chain.get_meta("baked_instance_buffer",PackedFloat32Array())
		_check(buffer.size()==chain.multimesh.instance_count*12 and buffer.size()>24,"chain instance transforms were lost during baking")
		if buffer.size()>24:
			_check(absf(buffer[0])+absf(buffer[1])+absf(buffer[2])>0.5,"chain instance has a collapsed basis")
			_check(Vector3(buffer[3],buffer[7],buffer[11]).distance_to(Vector3(buffer[15],buffer[19],buffer[23]))>0.2,"chain links have collapsed to one location")
		_check(chain.get_meta("baked_instance_bounds",AABB()).get_center().length()<6.0,"chain visibility origin is far from its geometry")
	for bridge in PLAN.BRIDGES:
		var a := Vector2(bridge.ends[0][0],bridge.ends[0][1])
		var b := Vector2(bridge.ends[1][0],bridge.ends[1][1])
		var clearance := CapsuleShape3D.new()
		clearance.radius=0.40
		clearance.height=1.9
		for station in 65:
			var t := float(station)/64.0
			var p := a.lerp(b,t)
			var y := ground+preload("res://scripts/chinese_village_plan_builder.gd").bridge_height(bridge,t)
			var shape_query := PhysicsShapeQueryParameters3D.new()
			shape_query.shape=clearance
			shape_query.collision_mask=1
			shape_query.transform=Transform3D(Basis.IDENTITY,Vector3(250+p.x,y+1.0,-650+p.y))
			var hits := world.get_world_3d().direct_space_state.intersect_shape(shape_query)
			var names: Array[String]=[]
			for hit in hits: names.append(str(hit.collider.get_path())+" @ "+str(hit.collider.global_position)+" script="+str(hit.collider.get_script()))
			_check(hits.is_empty(),"bridge aisle blocked: "+bridge.a+"-"+bridge.b+" at "+str(t)+" "+str(names))
		for i in range(1,20):
			var t := float(i)/20.0
			var point := a.lerp(b,t)
			var expected := ground+preload("res://scripts/chinese_village_plan_builder.gd").bridge_height(bridge,t)
			var query := PhysicsRayQueryParameters3D.create(Vector3(250+point.x,expected+0.15,-650+point.y),Vector3(250+point.x,expected-0.15,-650+point.y),1)
			var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
			_check(not hit.is_empty() and absf(float(hit.get("position",Vector3.ZERO).y)-expected)<0.06,"bridge deck and collision disagree: "+bridge.a+"-"+bridge.b)
	for key in ["inn_garden","pond_court"]:
		var garden: Node3D=items[key]
		var pine: Vector3=garden.get_meta("garden_pine")
		var pavilion: Vector3=garden.get_meta("garden_pavilion")
		_check(pine.distance_to(pavilion)>5.0,"garden pine overlaps its pavilion")
		var water := garden.find_child("LotusPondWater",true,false) as MeshInstance3D
		_check(water!=null and water.mesh is ArrayMesh and water.material_override is ShaderMaterial,"garden pond lost its curved rippled-water surface")
		# The joined bridge must support a body through every bend, not merely
		# look connected from the overhead review camera.
		var route: Array[Vector3]=[]
		for point in PLAN.GARDENS[key].crossing: route.append(Vector3(point[0],point[1],point[2]))
		var pond_center := Vector2(1.2,-1.2) if key=="inn_garden" else Vector2(0.5,-0.8)
		var pond_radii: Vector2=garden.get_meta("pond_radii")
		for endpoint in [route[0],route[-1]]:
			_check(((Vector2(endpoint.x,endpoint.z)-pond_center)/pond_radii).length()>1.0,"pond crossing ends in water rather than reaching its bank")
		for segment in route.size()-1:
			for station in 9:
				var p := route[segment].lerp(route[segment+1],float(station)/8.0)
				var query := PhysicsRayQueryParameters3D.create(garden.to_global(p+Vector3.UP*0.3),garden.to_global(p-Vector3.UP*0.1),1)
				var hit := world.get_world_3d().direct_space_state.intersect_ray(query)
				_check(not hit.is_empty(),"pond bridge has unsupported walk surface at a bend")
		if key=="pond_court":
			var structure := garden.find_child("HexagonalOpenPavilion",true,false) as Node3D
			var podium: Node3D=items["high_pavilion"]
			var clips := 0
			for visual in structure.find_children("*","MeshInstance3D",true,false):
				for surface in visual.mesh.get_surface_count():
					var vertices: PackedVector3Array=visual.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
					for vertex in vertices:
						var q := podium.to_local(visual.to_global(vertex))
						if q.y>0.01 or q.y < -9.8: continue
						var half := 6.2+1.8*(-q.y/9.8)
						if absf(q.x)<half+0.03 and absf(q.z)<half+0.03: clips+=1
			_check(clips==0,"garden pavilion intersects the battered tower podium: "+str(clips)+" vertices")
			var approach: Array=PLAN.GARDENS[key].approach
			var a := Vector3(approach[0][0],approach[0][1],approach[0][2])
			var b := Vector3(approach[1][0],approach[1][1],approach[1][2])
			for station in 12:
				var p := a.lerp(b,float(station)/11.0)
				var query := PhysicsRayQueryParameters3D.create(garden.to_global(p+Vector3.UP*0.15),garden.to_global(p-Vector3.UP*0.15),1)
				_check(not world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"pavilion approach has unsupported footing")
			var capsule := CapsuleShape3D.new()
			capsule.radius=0.25
			capsule.height=1.2
			var center: Vector3=garden.get_meta("garden_pavilion")
			for station in 10:
				var p := a.lerp(Vector3(center.x,0.45,center.z),float(station)/9.0)
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape=capsule
				query.collision_mask=1
				query.transform=Transform3D(Basis.IDENTITY,garden.to_global(p+Vector3.UP*0.72))
				_check(world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"pavilion entrance blocked by rail or post")
		var rock := garden.find_child("RockeryAnchor",true,false) as Node3D
		_check(rock!=null,"garden lost its limestone anchor")
		if rock!=null:
			var hole := Vector3(-1.05*0.16,1.48*0.65,0)
			var query := PhysicsRayQueryParameters3D.create(rock.to_global(hole+Vector3(0,0,-1.2)),rock.to_global(hole+Vector3(0,0,1.2)),1)
			_check(world.get_world_3d().direct_space_state.intersect_ray(query).is_empty(),"limestone aperture is visually or physically plugged")
	_check(geometry.find_children("PlanPath_*","MeshInstance3D",true,false).is_empty(),"legacy overlapping path ribbons remain")
	for visual in geometry.find_children("ConstructedWalk_*","MeshInstance3D",true,false):
		_check(visual.material_override is StandardMaterial3D,"printed repeating paving remains in constructed walks")
	_check(geometry.find_children("LinyuanWornGround*","Decal",true,false).size()>=4,"organic ways do not use the shared worn-ground system")
	var posts := village.find_children("LinyuanLanternPost*","StaticBody3D",true,false)
	var authored := 0
	for lamp in PLAN.LANTERNS:
		if lamp.kind=="post": authored+=1
	_check(posts.size()==authored,"runtime lamp posts differ from the explicit model placements: "+str(posts.size())+"/"+str(authored))
	for post in posts:
		var at := Vector2(post.global_position.x-250,post.global_position.z+650)
		var found := false
		for lamp in PLAN.LANTERNS:
			if lamp.kind=="post" and at.distance_to(Vector2(lamp.at[0],lamp.at[1]))<0.01: found=true
		_check(found,"lamp post was heuristically placed outside the authored set")
	var same_a := NatureProps.build_chinese_pine(4.2,41)
	var same_b := NatureProps.build_chinese_pine(4.2,41)
	var different := NatureProps.build_chinese_pine(4.2,42)
	var parts_a := same_a.find_children("PineCloudPad*","MeshInstance3D",true,false)
	var parts_b := same_b.find_children("PineCloudPad*","MeshInstance3D",true,false)
	var parts_c := different.find_children("PineCloudPad*","MeshInstance3D",true,false)
	var varies := false
	for i in parts_a.size():
		_check(parts_a[i].transform==parts_b[i].transform,"pine seed does not reproduce its specimen")
		if parts_a[i].position.distance_to(parts_c[i].position)>0.1: varies=true
	_check(varies,"different pine seeds produce identical silhouettes")
	_check(same_a.find_children("*","CollisionShape3D",true,false).size()>15,"Chinese pine lacks structural/landing collision")
	same_a.free()
	same_b.free()
	different.free()


func _check_real_ponds(world: Node3D, ground: float) -> void:
	var terrain := world.get_node("Terrain")
	var player := world.get_node("Player") as Player
	var saved := player.global_transform
	player.set_physics_process(false)
	var monkey := preload("res://scenes/xiao_hou_zi.tscn").instantiate() as XiaoHouZi
	world.add_child(monkey)
	monkey.set_process(false)
	monkey.set_physics_process(false)
	monkey.begin_direct_control()
	var blorb := preload("res://scenes/blorb.tscn").instantiate() as Blorb
	world.add_child(blorb)
	blorb.set_process(false)
	blorb.set_physics_process(false)
	var old_camera := get_viewport().get_camera_3d()
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.make_current()
	for pond in preload("res://scripts/chinese_water.gd").definitions():
		var wet: Vector2=preload("res://scripts/chinese_water.gd").CENTER+pond.center+Vector2(0.5,-1.3)
		var surface: float=terrain.get_water_surface_height(wet)
		var bed: float=terrain.get_water_floor_height(wet)
		_check(terrain.is_water_area(wet),"pond is not registered as real water")
		_check(surface-bed>2.0,"pond has no swimmable depth")
		var ray := PhysicsRayQueryParameters3D.create(Vector3(wet.x,ground+0.2,wet.y),Vector3(wet.x,ground-3,wet.y),1)
		ray.exclude=[player.get_rid(),monkey.get_rid()]
		var hit := world.get_world_3d().direct_space_state.intersect_ray(ray)
		_check(not hit.is_empty() and absf(float(hit.get("position",Vector3.ZERO).y)-bed)<0.06,"pond basin collision mismatch: "+pond.key+" expected "+str(bed)+" hit "+str(hit.get("position",Vector3.ZERO))+" "+str(hit.get("collider",null)))
		var liquid := LiquidEnvironment.new()
		liquid.read(terrain,null,Vector3(wet.x,surface-0.6,wet.y))
		_check(liquid.in_water() and liquid.deep_enough_to_swim(),"shared liquid environment cannot swim in the pond")
		player.global_position=Vector3(wet.x,surface-0.7,wet.y)
		player.call("_update_lake_buoyancy",1.0/60.0)
		_check(bool(player.get("_lake_buoyancy_active")),"human water behavior is inactive in the pond")
		monkey.global_position=Vector3(wet.x+0.25,surface-0.5,wet.y)
		monkey.prepare_direct_control_environment(1.0/60.0)
		_check(bool(monkey.get("_direct_diving")),"controlled companion water behavior is inactive in the pond")
		blorb.global_position=Vector3(wet.x,surface-0.5,wet.y)
		blorb.drive_from_player(Vector3.ZERO,1.0/60.0,false,false)
		_check(blorb.global_position.y>bed+0.3 and blorb.global_position.y<surface,"controlled blorb does not float in the pond")
		camera.global_position=Vector3(wet.x,surface-0.7,wet.y)
		terrain.call("_process",0.0)
		_check(camera.environment!=null,"pond has no underwater camera environment")
		camera.global_position.y=surface+0.3
		terrain.call("_process",0.0)
		_check(camera.environment==null,"pond underwater environment persists above its surface")
		# The west escape slope has a continuous bed and a climbable grade.
		var previous := Vector2(pond.center.x+0.5,pond.center.y)
		var previous_y := preload("res://scripts/chinese_water.gd").bed(pond,previous)
		for step in range(1,25):
			var t := float(step)/24.0
			var at := Vector2(lerpf(pond.center.x+0.5,pond.center.x-pond.radii.x,t),pond.center.y)
			var y := preload("res://scripts/chinese_water.gd").bed(pond,at)
			_check((y-previous_y)/at.distance_to(previous)<tan(deg_to_rad(33)),"pond exit ramp is too steep")
			previous=at
			previous_y=y
	if old_camera!=null: old_camera.make_current()
	camera.queue_free()
	blorb.queue_free()
	player.global_transform=saved
	player.set_physics_process(true)
	monkey.end_direct_control()
	monkey.queue_free()
	await get_tree().physics_frame


func _check_pine_clearance(world: Node3D, geometry: Node3D) -> void:
	var count := 0
	for node in geometry.find_children("*","StaticBody3D",true,false):
		if not node.has_meta("pine_seed"): continue
		var crowns: Array=node.get_meta("pine_crown_boxes",[])
		_check(crowns.size()==15,"pine lost its complete crown clearance envelopes")
		for crown in crowns:
			var box := BoxShape3D.new()
			box.size=crown.size
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape=box
			query.transform=Transform3D(node.global_basis,node.to_global(crown.position))
			query.collision_mask=1
			query.exclude=[node.get_rid()]
			var hits := world.get_world_3d().direct_space_state.intersect_shape(query)
			var names: Array[String]=[]
			for hit in hits: names.append(str(hit.collider.get_path())+" @ "+str(hit.collider.global_position)+" script="+str(hit.collider.get_script()))
			_check(hits.is_empty(),"pine crown clips architecture: "+str(node.get_path())+" / "+str(names))
		count+=1
	_check(count>=20,"village lost its planted pine silhouettes")
	print("Pine crown envelopes checked: ",count," trees")


func _mesh_bounds_in(frame: Node3D, visual: MeshInstance3D) -> AABB:
	var bounds := visual.mesh.get_aabb()
	var result := AABB(frame.to_local(visual.to_global(bounds.position)),Vector3.ZERO)
	for corner in 8: result=result.expand(frame.to_local(visual.to_global(bounds.get_endpoint(corner))))
	return result


func _check_inn_architecture(world: Node3D, inn: Node3D) -> void:
	var house := inn.get_node("InnBuilding") as Node3D
	var highest := 0.0
	for mesh in house.find_children("*","MeshInstance3D",true,false):
		highest=maxf(highest,_mesh_bounds_in(inn,mesh).end.y)
	_check(highest<10.3,"inn roof retains the oversized compressed prototype section")
	var sign := inn.get_node("InnBedAndMoonSign") as Node3D
	var plaque := _mesh_bounds_in(inn,sign.get_node("SignPlaque"))
	var bracket := _mesh_bounds_in(inn,sign.get_node("SignWallBracket"))
	var shoe := _mesh_bounds_in(inn,inn.get_node("InnSignMountingShoe"))
	_check(plaque.position.y>=2.19,"inn sign hangs below clear headroom")
	_check(bracket.intersects(shoe),"inn sign bracket is detached from its mounting shoe")
	_check(shoe.position.y<3.01 and shoe.end.y>3.01,"inn sign shoe does not engage the gallery underside")
	_check(bracket.end.y<3.25,"inn sign support projects through the gallery floor")
	var floor_query := PhysicsRayQueryParameters3D.create(inn.to_global(Vector3(0,3.45,-6.0)),inn.to_global(Vector3(0,3.0,-6.0)),1)
	var floor_hit := world.get_world_3d().direct_space_state.intersect_ray(floor_query)
	_check(not floor_hit.is_empty() and absf(inn.to_local(floor_hit.get("position",Vector3.ZERO)).y-3.25)<0.03,"inn gallery and upper room floors are not level")
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.30
	capsule.height=1.5
	for station in 12:
		var point := Vector3(0,4.10,lerpf(-4.8,-6.3,float(station)/11.0))
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape=capsule
		query.transform=Transform3D(Basis.IDENTITY,inn.to_global(point))
		query.collision_mask=1
		_check(world.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"inn gallery door or approach is obstructed")


func _check_household_routes(world: Node3D, items: Dictionary) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius=0.30
	capsule.height=1.4
	for record in PLAN.ITEMS:
		if record.kind!="compound" or record.key=="inn": continue
		var yard: Node3D=items[record.key]
		var side: bool=record.door in ["+x","-x"]
		var width: float=record.rect[3] if side else record.rect[2]
		var depth: float=record.rect[2] if side else record.rect[3]
		var z_low := -depth*0.5+6.1
		var shed_width := minf(5.5,depth-8.7)
		var shed_z := -depth*0.5+5.8+shed_width*0.5
		for route in [[Vector3(0,0.85,z_low),Vector3(0,0.85,depth*0.5-0.8)],[Vector3(0,0.85,shed_z),Vector3(width*0.5-3.0,0.85,shed_z)]]:
			for station in 13:
				var point: Vector3=route[0].lerp(route[1],float(station)/12.0)
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape=capsule
				query.transform=Transform3D(Basis.IDENTITY,yard.to_global(point))
				query.collision_mask=1
				var hits := world.get_world_3d().direct_space_state.intersect_shape(query)
				var names: Array[String]=[]
				for hit in hits: names.append(str(hit.collider.get_path())+" @ "+str(hit.collider.global_position)+" script="+str(hit.collider.get_script()))
				_check(hits.is_empty(),"household circulation blocked: "+record.key+" at "+str(point)+" / "+str(names))


func _check_resident_looks(village: Node3D) -> void:
	var expected := preload("res://scripts/chinese_appearance.gd").LOOKS.keys()
	expected.erase("梁臻") # Story wardrobe of the same resident, not another person.
	var found: Array[String]=[]
	var emperor: Node3D=null
	for actor in get_tree().get_nodes_in_group("npcs"):
		if not village.is_ancestor_of(actor): continue
		_check(actor.has_meta("chinese_appearance"),"China resident lacks authored look: "+str(actor.display_name))
		if not actor.has_meta("chinese_appearance"): continue
		var identity: String=actor.get_meta("chinese_appearance")
		_check(identity not in found,"duplicated appearance identity: "+identity)
		found.append(identity)
		_check(not actor.cultural_outfit.is_empty(),"missing cultural garment kit: "+identity)
		_check(actor.find_children("ContinuousJacket","MeshInstance3D",true,false).is_empty(),"clothing hides canonical torso separation: "+identity)
		_check(not actor.find_children("ThoraxClosure","MeshInstance3D",true,false).is_empty(),"thorax garment missing: "+identity)
		if identity=="皇帝": emperor=actor
	for identity in expected: _check(identity in found,"named look never spawned: "+str(identity))
	if emperor!=null:
		_check(emperor.find_children("JadeStrand*","Node3D",true,false).size()==24,"imperial crown must have twelve bead strands on each side")
		var talk_hook: Callable=emperor.talk_override
		preload("res://scripts/chinese_appearance.gd").apply(emperor,"梁臻")
		emperor.refresh_wardrobe()
		_check(emperor.find_children("CourtCrown","Node3D",true,false).is_empty(),"advisor retained imperial crown")
		_check(emperor.wears_dress and emperor.dress_has_covered_legs,"advisor gown lost covered legs")
		_check(emperor.talk_override==talk_hook,"wardrobe replacement lost quest dialogue hook")
		preload("res://scripts/chinese_appearance.gd").apply(emperor,"皇帝")
		emperor.refresh_wardrobe()
		_check(emperor.find_children("JadeStrand*","Node3D",true,false).size()==24,"regalia rebuild lost crown")
