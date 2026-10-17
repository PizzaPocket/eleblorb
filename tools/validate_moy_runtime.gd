extends Node

const QA := preload("res://scenes/moy_city_qa.tscn")
const PLAN := preload("res://scripts/city_plan.gd")
var failures := 0
var old_house_count := 0
var lot_count := 0


func _ready() -> void:
	WorldState.opening_wake_completed = true
	var qa := QA.instantiate()
	add_child(qa)
	await LoadingScreen.wait_for_world_builds()
	var qa_frames := 0
	while not bool(qa.get_meta("qa_ready", false)) and qa_frames < 2400:
		qa_frames += 1
		await get_tree().process_frame
	if not bool(qa.get_meta("qa_ready", false)):
		_fail("QA scene did not expose control after static geometry and complete Leaf Hat suit")
		_finish(); return
	var city := qa.get_node("WesternCity")
	var frames := 0
	while not bool(city.call("moy_packs_ready")) and frames < 2000:
		frames += 1
		await get_tree().process_frame
	if not bool(city.call("moy_packs_ready")):
		_fail("static pack activation did not complete")
		_finish(); return
	var counts := {"streets":PLAN.STREETS.size(),"buildings":PLAN.BUILDINGS.size(),"lots":PLAN.LOTS.size(),"old_houses":PLAN.OLD_HOUSES.size()}
	if counts.buildings != 48 or counts.lots != 133 or counts.old_houses != 60 or counts.streets != 23:
		_fail("source coverage counts differ: %s" % counts)
	var building_bodies := {}
	_count_coverage(city, building_bodies)
	if building_bodies.size() < 46: _fail("numbered building collision bodies missing: %d" % building_bodies.size())
	if old_house_count < 60: _fail("old house bodies missing: %d" % old_house_count)
	if lot_count < 133: _fail("lot bodies missing: %d" % lot_count)
	var rays := [Vector2(-500,0),Vector2(-560,-40),Vector2(-620,0),Vector2(-560,45),Vector2(-700,-40),Vector2(-515,-35)]
	for p in rays:
		if not _ray_hits_city(p): _fail("no collision at route sample %s" % p)
	_test_public_route_geometry(qa)
	await _test_wind_turbines(city)
	await _test_moving_platforms(city)
	await _test_leaf_suit_handover(qa)
	_test_vine_handover_search(qa)
	print("MOY_RUNTIME packs=",city.get_child_count(),"coverage=",counts,"numbered_bodies=",building_bodies.size(),"old_house_bodies=",old_house_count,"lot_bodies=",lot_count,"frames_to_ready=",frames,"failures=",failures)
	_finish()


func _test_leaf_suit_handover(qa: Node) -> void:
	var player := qa.get_node("Player") as Player
	var monkey := qa.get_node("DebugXiaoHouZi") as XiaoHouZi
	var human_suit := player.get_own_blorb_suit()
	var monkey_suit := monkey.get_own_blorb_suit()
	var slots := ["head","torso","arm_left","arm_right","leg_left","leg_right"]
	var carried: Array[Blorb] = []
	for slot in slots:
		var member := human_suit.assigned_blorb_in_slot(slot)
		if member == null or member.element_state != "plant": _fail("human Plant suit missing %s" % slot)
		carried.append(member)
	if not human_suit.has_vine_swing_suit(): _fail("complete Leaf Hat suit did not enable the real vine swing")
	player.restore_active_party_member(PartyControl.XIAO_HOU_ZI_ID)
	for i in 30: await get_tree().process_frame
	for i in slots.size():
		if monkey_suit.assigned_blorb_in_slot(slots[i]) != carried[i]: _fail("Xiao suit handover lost %s" % slots[i])
	if not monkey_suit.has_vine_swing_suit(): _fail("Leaf Hat did not carry vine capability to Xiao")
	player.restore_active_party_member(PartyControl.HUMAN_ID)
	for i in 30: await get_tree().process_frame
	for i in slots.size():
		if human_suit.assigned_blorb_in_slot(slots[i]) != carried[i]: _fail("human suit return lost %s" % slots[i])
	print("MOY_VINE_SUIT_HANDOVER human_to_xiao_and_back=PASS full_plant_slots=6")


func _test_vine_handover_search(qa: Node) -> void:
	var player := qa.get_node("Player") as Player
	var terrain := qa.get_node("Terrain")
	var mode := player.get("_vine_swing") as VineSwingMode
	var routes := {"old_high_street":Vector2(-704.0,0.0),"market_lanes":Vector2(-557.0,120.0),"main_street":Vector2(-557.0,25.0),"estate_court":Vector2(-535.0,-100.0),"downtown":Vector2(-462.0,-20.0),"park":Vector2(-610.0,0.0)}
	var passed := 0
	for route_name in routes:
		var p: Vector2=routes[route_name]
		player.global_position=Vector3(p.x,float(terrain.call("get_mesh_height",p.x,p.y))+0.6,p.y)
		player.velocity=Vector3.ZERO
		var ctx: TraversalContext=player.call("_traversal_context",1.0/60.0)
		var chain_found := false
		for bearing in 16:
			var angle:=TAU*float(bearing)/16.0
			var aim:=Vector3(cos(angle),0.0,sin(angle))
			var first=mode.find_anchor(ctx,aim)
			if first==null: continue
			mode.anchor=first.point; mode.anchor_rid=first.body; mode.swinging=true
			mode.rope_length=player.global_position.distance_to(first.point)
			mode.grip_timer=0.0; mode._peak_carry=10.0
			var old_rid: RID=mode.anchor_rid
			if mode._catch_next(ctx,aim) and mode.anchor_rid!=old_rid:
				chain_found=true; mode.reset(); break
			mode.reset()
		if chain_found: passed+=1
		else: _fail("real VineSwingMode handover search found no distinct body chain at %s" % route_name)
	print("MOY_VINE_ROUTE_HANDOVER chains=",passed,"/",routes.size()," routes=",routes.keys())


func _test_public_route_geometry(qa: Node) -> void:
	for gate in [Vector2(-557.0,-212.0),Vector2(-557.0,212.0),Vector2(-351.0,0.0),Vector2(-771.0,0.0)]:
		if not _ray_corridor_clear(gate): _fail("gate opening blocked at %s" % gate)
	var deck := PLAN.DECK
	for ramp in deck.ramps:
		var c: Vector2=Vector2(ramp.c[0],ramp.c[1]); var head: String=String(ramp.head)
		var d: Vector2={"n":Vector2(0,-1),"s":Vector2(0,1),"e":Vector2(1,0),"w":Vector2(-1,0)}[head]
		if not _ray_hits_level(c+d*5.1,-53.5): _fail("Deck ramp top is disconnected: %s" % ramp.name)
	var terrain:=qa.get_node("Terrain")
	var pond:=Vector2(-516.0,-28.0)
	if not bool(terrain.call("is_water_area",pond)): _fail("pond is not registered with water/swim API")
	var surface:=float(terrain.call("get_water_surface_height",pond)); var floor:=float(terrain.call("get_water_floor_height",pond))
	if surface-floor<3.0: _fail("pond bed is too shallow for its recorded basin")
	var water_mesh: MeshInstance3D
	var lawn_found:=false
	var stack: Array[Node]=[qa.get_node("WesternCity")]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		if node.name=="MoyReedPondSurface": water_mesh=node as MeshInstance3D
		if node.name=="ParkLawn": lawn_found=true
		for child in node.get_children(): stack.append(child)
	if water_mesh==null or not water_mesh.material_override is ShaderMaterial: _fail("park pond lacks its visible animated water surface")
	if not lawn_found: _fail("park lawn color patch missing")
	print("MOY_ROUTES gate_openings=4 deck_ramps=",deck.ramps.size()," pond_surface=",surface," pond_depth=",surface-floor)


func _ray_corridor_clear(p: Vector2) -> bool:
	var query:=PhysicsRayQueryParameters3D.create(Vector3(p.x-6.0,-56.0,p.y),Vector3(p.x+6.0,-56.0,p.y),1)
	if absf(p.y)>100.0: query.from=Vector3(p.x,-56.0,p.y-6.0); query.to=Vector3(p.x,-56.0,p.y+6.0)
	var hit:=get_viewport().world_3d.direct_space_state.intersect_ray(query)
	if not hit.is_empty(): print("MOY_GATE_HIT point=",p," collider=",hit.collider.name," at=",hit.position)
	return hit.is_empty()


func _ray_hits_level(p: Vector2, y: float) -> bool:
	var query:=PhysicsRayQueryParameters3D.create(Vector3(p.x,y+1.5,p.y),Vector3(p.x,y-1.5,p.y),1)
	return not get_viewport().world_3d.direct_space_state.intersect_ray(query).is_empty()


func _test_moving_platforms(city: Node) -> void:
	var trains: Array[Node3D] = []
	var lift: Node3D
	for child in city.get_children():
		var stack: Array[Node]=[child]
		while not stack.is_empty():
			var node: Node=stack.pop_back()
			if node.name.begins_with("MoyTrain_"): trains.append(node as Node3D)
			if node.name.begins_with("DeckLift_") and lift==null: lift=node as Node3D
			for sub in node.get_children(): stack.append(sub)
	if trains.size()!=8: _fail("expected 8 train consists (two per Crossroads route, four Wall Line), got %d"%trains.size()); return
	if lift==null: _fail("public Deck lift missing"); return
	var rids: Array[RID] = []
	var movement_before: Dictionary = {}
	var stops_expected := {"Spine Line":5,"Meridian Line":3,"Wall Line":4}
	for train in trains:
		var service := String(train.get("service_name"))
		var expected_cars := 3 if service=="Wall Line" else 2
		var car_bodies: Array = train.get("_car_bodies")
		if car_bodies.size()!=expected_cars: _fail("%s car count mismatch: %d"%[service,car_bodies.size()])
		if (train.get("_stop_distances") as PackedFloat32Array).size()!=stops_expected[service]: _fail("%s station stop count mismatch"%service)
		if not is_equal_approx(float(train.get("dwell")),4.0): _fail("%s dwell is not the brief 4 second stop"%service)
		if service in ["Spine Line","Meridian Line"]:
			var expected_direction:=1.0 if int(train.get("initial_direction"))>0 else -1.0
			if not is_equal_approx(float(train.get("_direction")),expected_direction): _fail("%s double-track direction assignment is wrong"%service)
		movement_before[train.get_instance_id()]=float(train.get("_distance"))
		for car in car_bodies:
			if not car is AnimatableBody3D: _fail("train car is not an independent rideable physics body"); continue
			var rid: RID=car.get_rid()
			if rid in rids: _fail("train cars share a physics RID")
			rids.append(rid)
		_test_train_clearance(train)
		# Exercise a real stop crossing in the controller and require its dwell timer.
		var stop_distances: PackedFloat32Array=train.get("_stop_distances")
		var saved_conflicts: PackedVector3Array=train.get("conflict_points")
		train.set("conflict_points",PackedVector3Array())
		for target_value in stop_distances:
			var target:=float(target_value)
			train.set("_direction",1.0)
			train.set("_dwell_left",0.0)
			train.set("_distance",target-0.05 if target>0.1 else float(train.get("_total"))-0.05)
			train.call("_physics_process",1.0/60.0)
			if float(train.get("_dwell_left"))<3.9: _fail("%s failed to dwell at station distance %.2f"%[service,target])
		train.set("conflict_points",saved_conflicts)
	var lift_before:=lift.position.y
	for i in 600: await get_tree().physics_frame
	for train in trains:
		if absf(float(train.get("_distance"))-float(movement_before[train.get_instance_id()]))<1.0: _fail("%s train did not move on its path"%train.get("service_name"))
	for i in 1800:
		await get_tree().physics_frame
		if i%10==0: _check_gate_train_separation(trains)
	if absf(lift.position.y-lift_before)<0.1: _fail("Deck lift platform did not move")
	print("MOY_MOVERS consists=",trains.size()," independent_cars=",rids.size()," route_stops=",stops_expected," dwell_seconds=4 gate_simulation_seconds=40 lift_delta_m=",absf(lift.position.y-lift_before))


func _check_gate_train_separation(trains: Array[Node3D]) -> void:
	for spine in trains:
		if String(spine.get("service_name"))!="Spine Line": continue
		for wall in trains:
			if String(wall.get("service_name"))!="Wall Line": continue
			for spine_car in spine.get("_car_bodies"):
				for wall_car in wall.get("_car_bodies"):
					if absf(spine_car.global_position.y-wall_car.global_position.y)<3.5 and spine_car.global_position.distance_to(wall_car.global_position)<5.2:
						_fail("Spine and Wall Line car envelopes overlapped at gate junction")
						return


func _test_wind_turbines(city: Node) -> void:
	var rotors: Array[Node3D] = []
	var stack: Array[Node] = [city]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		if node.name=="WindTurbineRotor": rotors.append(node as Node3D)
		for child in node.get_children(): stack.append(child)
	if rotors.size()!=4: _fail("expected four active turbine rotors, found %d"%rotors.size()); return
	var starts: Array[float]=[]
	for rotor in rotors:
		var windward: Vector3=rotor.global_basis.z.normalized()
		if windward.x>-0.99: _fail("turbine rotor is not facing west: %s"%rotor.get_parent().name)
		if rotor.get_child_count()!=3: _fail("turbine rotor does not carry three blades")
		for blade in rotor.get_children():
			if not blade is AnimatableBody3D: _fail("moving turbine blade is not an independent collision body")
		starts.append(rotor.rotation.z)
	for i in 120: await get_tree().physics_frame
	for i in rotors.size():
		if absf(wrapf(rotors[i].rotation.z-starts[i],-PI,PI))<0.05: _fail("turbine blades did not rotate")
	print("MOY_TURBINES count=",rotors.size()," facing=west turns_per_minute=2 moving_collision_blades=12")


func _test_train_clearance(train: Node3D) -> void:
	var route: PackedVector3Array=train.get("path")
	var sample_count := 0
	var car_envelope := BoxShape3D.new()
	car_envelope.size=Vector3(9.6,3.4,3.2)
	for i in route.size()-1:
		var a:=route[i]
		var b:=route[(i+1)%route.size()]
		var count:=maxi(1,ceili(a.distance_to(b)/8.0))
		for sample in count:
			var center:=a.lerp(b,float(sample)/float(count))
			var tangent: Vector3=(b-a).normalized()
			var yaw:=atan2(-tangent.z,tangent.x)
			for lane_offset in [0.0]:
				var lateral:=Vector3(-tangent.z,0,tangent.x)*float(lane_offset)
				var pose:=Transform3D(Basis(Vector3.UP,yaw),center+lateral+Vector3.UP*1.9)
				var query:=PhysicsShapeQueryParameters3D.new()
				query.shape=car_envelope
				query.transform=pose
				query.collision_mask=1
				for car in train.get("_car_bodies"): query.exclude.append(car.get_rid())
				for hit in get_viewport().world_3d.direct_space_state.intersect_shape(query,64):
					var collider: Object=hit.get("collider")
					if collider==null: continue
					var name:=String(collider.get("name"))
					if name.begins_with("Building_") or name.begins_with("OldHouse_") or name.begins_with("Lot_") or name.begins_with("WestGate") or name.begins_with("MeridianArch") or name.begins_with("SpineGate") or name.begins_with("NorthSouthGate") or name.begins_with("WallLine_Station_"):
						_fail("train clearance intersects %s on %s at %s"%[name,train.get("service_name"),center])
						return
			sample_count+=1
	print("MOY_TUNNEL_CLEARANCE service=",train.get("service_name")," route_samples=",sample_count," tested_class=buildings,old_houses,lots,gate_masses,station_platforms")


func _count_coverage(node: Node, found: Dictionary) -> void:
	var label := String(node.name)
	if label.begins_with("OldHouse_"): old_house_count += 1
	if label.begins_with("Lot_"): lot_count += 1
	if node is StaticBody3D:
		if label.begins_with("Building_") and label not in ["Building_1_GrandHotel"]:
			var rid := (node as StaticBody3D).get_rid()
			if found.has(label) and found[label] != rid: _fail("duplicate building body name %s" % label)
			found[label] = rid
	for child in node.get_children(): _count_coverage(child, found)


func _ray_hits_city(p: Vector2) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(p.x,250,p.y),Vector3(p.x,-75,p.y),1)
	var hit := get_viewport().world_3d.direct_space_state.intersect_ray(query)
	return not hit.is_empty()


func _fail(message: String) -> void:
	failures += 1
	push_error("MOY_RUNTIME FAIL " + message)


func _finish() -> void:
	get_tree().quit(1 if failures > 0 else 0)
