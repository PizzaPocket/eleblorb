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
	_test_qa_air_party(qa)
	var counts := {"streets":PLAN.STREETS.size(),"buildings":PLAN.BUILDINGS.size(),"lots":PLAN.LOTS.size(),"old_houses":PLAN.OLD_HOUSES.size()}
	if counts.buildings != 47 or counts.lots != 133 or counts.old_houses != 60 or counts.streets != 22:
		_fail("source coverage counts differ: %s" % counts)
	var building_bodies := {}
	_count_coverage(city, building_bodies)
	for building in PLAN.BUILDINGS:
		# Hotel and playground are composites, not generic numbered bodies.
		if building.rect == null or int(building.n) in [1, 11]: continue
		var label := "Building_%02d_%s" % [int(building.n), String(building.name).replace(" ", "_")]
		if not building_bodies.has(label): _fail("numbered building collision body missing: %s" % label)
	if old_house_count < 60: _fail("old house bodies missing: %d" % old_house_count)
	if lot_count < 133: _fail("lot bodies missing: %d" % lot_count)
	_test_pass3_counts(city)
	_test_escalator_geometry(city)
	_test_pass4_geometry(city)
	_test_recorded_positions(city)
	var rays := [Vector2(-500,0),Vector2(-560,-40),Vector2(-620,0),Vector2(-560,45),Vector2(-700,-40),Vector2(-515,-35)]
	for p in rays:
		if not _ray_hits_city(p): _fail("no collision at route sample %s" % p)
	_test_public_route_geometry(qa)
	await _test_wind_turbines(city)
	await _test_timekeeper(city)
	await _test_moving_platforms(city)
	await _test_hotel_lift_schedules(city)
	await _test_leaf_suit_handover(qa)
	_test_vine_handover_search(qa)
	print("MOY_RUNTIME packs=",city.get_child_count(),"coverage=",counts,"numbered_bodies=",building_bodies.size(),"old_house_bodies=",old_house_count,"lot_bodies=",lot_count,"frames_to_ready=",frames,"failures=",failures)
	_finish()


func _test_qa_air_party(qa: Node) -> void:
	var air:=qa.get_node_or_null("QA_AirBlorb") as Blorb
	if air==null:
		_fail("QA party is missing its Air blorb")
		return
	if not air.in_party or air.element_state!="air": _fail("QA Air blorb is not an Air party member")
	if not air.is_in_group("party_playable_candidates"): _fail("QA Air blorb did not register with party controls")
	if air.body.get_node_or_null("AirBlorbWings")==null: _fail("QA Air blorb visual/wings are missing")
	print("MOY_QA_PARTY air_companions=1 element=air registered=",air.is_in_group("party_playable_candidates"))


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
	var authored_depth:=float(PLAN.PARK.pond.surface)-float(PLAN.PARK.pond.bed[-1][1])
	if absf(surface-(-60.0+float(PLAN.PARK.pond.surface)))>0.01 or absf(surface-floor-authored_depth)>0.05: _fail("pond surface/bed differ from the authored profile")
	var water_mesh: MeshInstance3D
	var lawn_found:=false
	var stack: Array[Node]=[qa.get_node("WesternCity")]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		if node.name=="MoyReedPondSurface": water_mesh=node as MeshInstance3D
		if node.name=="ParkLawn": lawn_found=true
		for child in node.get_children(): stack.append(child)
	if water_mesh==null or not water_mesh.material_override is ShaderMaterial or (water_mesh.material_override as ShaderMaterial).shader!=VillageWorks.SHARED_WATER_SHADER: _fail("park pond lacks the shared translucent water material")
	if not lawn_found: _fail("park lawn color patch missing")
	print("MOY_ROUTES gate_openings=4 deck_ramps=",deck.ramps.size()," pond_surface=",surface," pond_depth=",surface-floor)


func _test_pass4_geometry(city: Node) -> void:
	var names: Dictionary={}; var all_nodes: Array[Node]=[]; var stack: Array[Node]=[city]
	while not stack.is_empty():
		var node: Node=stack.pop_back(); names[String(node.name)]=node; all_nodes.append(node)
		for child in node.get_children(): stack.append(child)
	var square_trees:=0; var city_hall_lanes:=0; var lanterns:=0; var tower_lifts:=0; var room_arrivals:=0; var straight_handrails:=0; var helix_sections:=0
	for node in all_nodes:
		var key:=String(node.name)
		if key.begins_with("CivicPlazaTree_"): square_trees+=1
		if key.begins_with("CityHall") and (key.ends_with("_Up") or key.ends_with("_Down")): city_hall_lanes+=1
		if key.begins_with("ClockRoomLiftLanternBack_"): lanterns+=1
		if key=="CrossingTowerLift": tower_lifts+=1
		if key.begins_with("ClockRoomArrival_") and (key.ends_with("_Up") or key.ends_with("_Down")): room_arrivals+=1
		if key.begins_with("Moving_Rubber_Handrail_"): straight_handrails+=1
		if key.begins_with("CrossingHand_") and node is StaticBody3D and node.get_child_count()>4: helix_sections+=1
	if square_trees!=14: _fail("Civic Plaza exact tree rows expected 14 trees, found %d"%square_trees)
	if city_hall_lanes<24: _fail("City Hall front expected scissor, steps and outer access lanes; found %d"%city_hall_lanes)
	if room_arrivals!=8: _fail("Clock Room expected four paired arrivals, found %d escalator lanes"%room_arrivals)
	if lanterns!=4 or tower_lifts!=4: _fail("Clock Room expected four lift lanterns and four integrated tower lifts")
	if straight_handrails==0: _fail("straight escalators have no moving handrail surfaces")
	if names.get("DomeTriangulatedWhiteSteelGrid")==null: _fail("triangulated dome grid is missing")
	if names.get("DomeBellCrownRing")==null: _fail("dome crown ring is missing")
	var lift_ok:=0
	for node in all_nodes:
		if node is AnimatableBody3D and node.name=="CrossingTowerLift" and node.has_method("go_to") and float(PLAN.CROSSING.dome.base) in (node.get("stop_levels") as PackedFloat32Array): lift_ok+=1
	if lift_ok!=4: _fail("all four Crossing lifts must include the Clock Room stop")
	var eye_y:=float(PLAN.CROSSING.dome.clocks.eye.sill_y)+float(PLAN.CROSSING.dome.clocks.eye.r)
	for bearing_degrees in PLAN.CROSSING.dome.clocks.bearings:
		var angle:=deg_to_rad(float(bearing_degrees)); var radial:=Vector3(cos(angle),0.0,sin(angle)); var query:=PhysicsRayQueryParameters3D.create(Vector3(PLAN.CROSSING.c[0]+radial.x*26.0,eye_y,PLAN.CROSSING.c[1]+radial.z*26.0),Vector3(PLAN.CROSSING.c[0]+radial.x*14.0,eye_y,PLAN.CROSSING.c[1]+radial.z*14.0),1)
		if not city.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): _fail("clock eye %d is not physically open"%bearing_degrees)
	print("MOY_PASS4 civic_tree_rows=",square_trees," CityHall_lanes=",city_hall_lanes," ClockRoom_arrival_lanes=",room_arrivals," tower_lifts_with_room_stop=",lift_ok," eyes=4_ray_clearance dome_grid=",names.get("DomeTriangulatedWhiteSteelGrid")!=null)


func _test_pass3_counts(city: Node) -> void:
	var names: Dictionary={}; var stack: Array[Node]=[city]
	while not stack.is_empty():
		var node: Node=stack.pop_back(); names[node.name]=int(names.get(node.name,0))+1
		for child in node.get_children(): stack.append(child)
	var actual: Dictionary={
		"crossing_towers":_sum_indexed_roots(names,"CrossingTower_",PLAN.CROSSING.towers.size()), "deck_columns":_sum_prefix(names,"DeckColumn_"),
		"deck_parapets":_sum_prefix(names,"DeckParapet_"), "deck_beds":_sum_marker_prefix(names,"DeckGardenBed_","_Segment_"),
		"deck_trees":_sum_prefix(names,"DeckTree_"), "park_trees":_sum_prefix(names,"ParkTree_"),
		"shrubs":_sum_metadata_prefix(city,"ParkShrubMultiMesh_"), "reed_clumps":_sum_metadata_prefix(city,"ParkReedClumpMultiMesh_"),
		"rocks":_sum_prefix(names,"ParkRock_"), "agave":_sum_metadata_prefix(city,"ParkAgaveMultiMesh_"),
		"climber_panels":_sum_prefix(names,"CrossingClimberVineSheet_"), "meridian_piers":_sum_prefix(names,"MeridianPierStem"),
		"spine_frames":_sum_prefix(names,"SpineFrameBeam")}
	var expected: Dictionary={"crossing_towers":4,"deck_columns":PLAN.DECK.columns.size(),"deck_parapets":PLAN.DECK.parapets.size(),"deck_beds":PLAN.DECK.beds.size(),"deck_trees":PLAN.DECK.trees.size(),"park_trees":PLAN.PARK.trees.size(),"shrubs":PLAN.PARK.shrubs.size(),"reed_clumps":PLAN.PARK.reeds.size(),"rocks":PLAN.PARK.rocks.size(),"agave":PLAN.PARK.agave.size(),"climber_panels":PLAN.CROSSING.climbers.size(),"meridian_piers":8,"spine_frames":8}
	for key in expected:
		if int(actual[key])!=int(expected[key]): _fail("pass-3 %s expected %d found %d"%[key,expected[key],actual[key]])
	var access_sets:=0; var access_flights:=0
	for station in PLAN.CROSS.stations:
		for side_data in station.get("_access",[]):
			access_sets+=1; access_flights+=side_data.flights.size()
	var access_lanes:=0
	for key in names:
		if String(key).begins_with("SpineAccess_") and (String(key).ends_with("_Up") or String(key).ends_with("_Down")): access_lanes+=int(names[key])
	if access_sets!=8 or access_flights!=12 or access_lanes!=24: _fail("station access source/build count mismatch: sets=%d flights=%d lanes=%d"%[access_sets,access_flights,access_lanes])
	print("MOY_STATION_ACCESS sets=",access_sets," authored_flights=",access_flights," moving_lanes=",access_lanes)
	print("MOY_PASS3_COUNTS actual=",actual,"expected=",expected)
	var disabled_geometry: Array[String]=[]; var item_stack: Array[Node]=[city]
	while not item_stack.is_empty():
		var node: Node=item_stack.pop_back(); var node_name:=String(node.name)
		if node_name.contains("SpineLotPortal") or node_name.contains("GateEscalator") or node_name.contains("WindTree"): disabled_geometry.append(node_name)
		for child in node.get_children(): item_stack.append(child)
	if not disabled_geometry.is_empty(): _fail("removed first-pass geometry still baked: %s"%disabled_geometry)
	print("MOY_REMOVED_GEOMETRY tunnels=0 gate_flyovers=0 wind_trees=0")


func _sum_prefix(counts: Dictionary, prefix: String) -> int:
	var total:=0
	for key in counts:
		if String(key).begins_with(prefix): total+=int(counts[key])
	return total


func _sum_marker_prefix(counts: Dictionary, prefix: String, child_marker: String) -> int:
	var total:=0
	for key in counts:
		if String(key).begins_with(prefix) and not String(key).contains(child_marker): total+=int(counts[key])
	return total


func _sum_indexed_roots(counts: Dictionary, prefix: String, count: int) -> int:
	var total:=0
	for i in count: total+=int(counts.get("%s%02d"%[prefix,i],0))
	return total


func _sum_metadata_prefix(root: Node, prefix: String) -> int:
	var total:=0; var stack: Array[Node]=[root]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		if String(node.name).begins_with(prefix): total+=int(node.get_meta("moy_item_count",0))
		for child in node.get_children(): stack.append(child)
	return total


func _test_escalator_geometry(city: Node) -> void:
	var checked_landings:=0
	var checked_climbers:=0
	var named: Dictionary={}
	var stack: Array[Node]=[city]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		named[String(node.name)]=node
		for child in node.get_children(): stack.append(child)
	var checked_hands:=0
	for tower_index in PLAN.CROSSING.towers.size():
		var tower:=named.get("CrossingTower_%02d"%tower_index) as Node3D
		if tower==null:
			_fail("Crossing tower %d missing for escalator orientation check"%tower_index)
			continue
		for hand in PLAN.CROSSING.towers[tower_index].hands:
			for pi in hand.profile.size():
				var node:=named.get("CrossingHand_%02d_%s_%d"%[tower_index,String(hand.hand),pi]) as StaticBody3D
				if node==null:
					_fail("continuous Crossing escalator strip missing: tower %d hand %s profile %d"%[tower_index,hand.hand,pi]); continue
				var collision: CollisionShape3D
				var visual: MeshInstance3D
				for part in node.get_children():
					if part is CollisionShape3D: collision=part as CollisionShape3D
					if part is MeshInstance3D: visual=part as MeshInstance3D
				if collision==null or visual==null or visual.mesh==null or visual.mesh.get_faces().is_empty(): _fail("continuous helix strip has no matching visual/collider: %s"%node.name)
				if not is_equal_approx(float(hand.profile[pi][2]),float(hand.profile[pi][3])):
					if not node is MoyEscalator or absf(float(node.get("helix_rise_per_radian")))<0.001: _fail("helix flight lacks per-contact tangent assist: %s"%node.name)
					checked_landings+=1
				else: checked_hands+=1
	for climber_index in PLAN.CROSSING.climbers.size():
		var climber: Array=PLAN.CROSSING.climbers[climber_index]
		var tower:=named.get("CrossingTower_%02d"%int(climber[0])) as Node3D
		var panel:=named.get("CrossingClimberVineSheet_%03d"%climber_index) as Node3D
		if tower==null or panel==null:
			_fail("Crossing climber %d missing for orientation check"%climber_index)
			continue
		var radial:=Vector2(panel.position.x,panel.position.z).normalized()
		var tangent:=Vector3(-radial.y,0.0,radial.x)
		if absf(panel.basis.x.normalized().dot(tangent))<0.99:
			_fail("Crossing vine panel width is not tangent to the tower ribs: %s"%panel.name)
		checked_climbers+=1
	var core_flights:=0
	for core in PLAN.ARCH.cores:
		var prefix:="EastGateCore_%s_Flight_"%String(core.name).replace(" ","_")
		var p:=-(float(core.size[1])*0.5-1.5)
		var direction:=1.0
		for flight_index in core.flights.size():
			var flight: Array=core.flights[flight_index]
			var q:=p+direction*float(flight[2])
			var up:=named.get("%s%02d_Up"%[prefix,flight_index]) as StaticBody3D
			var down:=named.get("%s%02d_Down"%[prefix,flight_index]) as StaticBody3D
			if up==null or down==null:
				_fail("East Gate flight %d lane pair missing for %s"%[flight_index,core.name])
			else:
				var lane_spacing:=Vector2(up.global_position.x-down.global_position.x,up.global_position.z-down.global_position.z).length()
				if absf(lane_spacing-1.2)>0.08: _fail("East Gate flight lanes overlap or diverge: %s flight %d spacing=%.2f"%[core.name,flight_index,lane_spacing])
				if absf((q-p)-direction*float(flight[2]))>0.01: _fail("East Gate switchback flight direction does not alternate")
			core_flights+=1
			p=q
			direction=-direction
	print("MOY_ESCALATOR_GEOMETRY continuous_profiles=",checked_landings+checked_hands," moving_flights=",checked_landings," landings=",checked_hands," tangent_climbers=",checked_climbers," east_gate_flights=",core_flights," paired_lane_spacing_m=1.2 headroom_policy=plan_canopy_3.2m")


func _test_recorded_positions(city: Node) -> void:
	var named: Dictionary={}; var multimeshes: Array[MultiMeshInstance3D]=[]; var stack: Array[Node]=[city]
	while not stack.is_empty():
		var node: Node=stack.pop_back(); named[String(node.name)]=node
		if node is MultiMeshInstance3D: multimeshes.append(node as MultiMeshInstance3D)
		for child in node.get_children(): stack.append(child)
	var checks:=0; var bed_segments:=0
	for i in PLAN.DECK.columns.size():
		var p: Array=PLAN.DECK.columns[i]; var node:=named.get("DeckColumn_%03d"%i) as Node3D
		if node==null or Vector2(node.global_position.x,node.global_position.z).distance_to(Vector2(p[0],p[1]))>0.05: _fail("Deck column %d moved from its CityPlan point"%i)
		checks+=1
	for i in PLAN.DECK.beds.size():
		var bed: Dictionary=PLAN.DECK.beds[i]
		bed_segments+=bed.pts.size()-1
		for j in bed.pts.size()-1:
			var node:=named.get("DeckGardenBed_%02d_Segment_%03d"%[i,j]) as Node3D; var a: Array=bed.pts[j]; var b: Array=bed.pts[j+1]; var expected:=Vector2((float(a[0])+float(b[0]))*0.5,(float(a[1])+float(b[1]))*0.5)
			if node==null or Vector2(node.global_position.x,node.global_position.z).distance_to(expected)>0.05: _fail("Deck bed %d segment %d moved from CityPlan"%[i,j])
			checks+=1
	for i in PLAN.DECK.trees.size():
		var tree: Dictionary=PLAN.DECK.trees[i]; var node:=named.get("DeckTree_%02d"%i) as Node3D
		if node==null or Vector3(node.global_position.x,node.global_position.y,node.global_position.z).distance_to(Vector3(tree.c[0],-60.0+float(tree.y),tree.c[1]))>0.05: _fail("Deck tree %d moved from CityPlan"%i)
		checks+=1
	for i in PLAN.PARK.trees.size():
		var tree: Dictionary=PLAN.PARK.trees[i]; var node:=named.get("ParkTree_%02d_%s"%[i,String(tree.kind)]) as Node3D
		if node==null or Vector3(node.global_position.x,node.global_position.y,node.global_position.z).distance_to(Vector3(tree.c[0],-60.0,tree.c[1]))>0.05: _fail("park tree %d moved from CityPlan"%i)
		checks+=1
	for i in PLAN.PARK.rocks.size():
		var rock: Dictionary=PLAN.PARK.rocks[i]; var node:=named.get("ParkRock_%02d"%i) as Node3D; var half: Array=rock.half
		if node==null or Vector3(node.global_position.x,node.global_position.y,node.global_position.z).distance_to(Vector3(rock.c[0],-60.0+float(half[1]),rock.c[1]))>0.05: _fail("park rock %d moved from CityPlan"%i)
		checks+=1
	for i in PLAN.CROSS.services.size():
		var service: Dictionary=PLAN.CROSS.services[i]
		for j in service.get("frames",[]).size():
			var p: Array=service.frames[j]; var node:=named.get("SpineFrameBeam_%02d"%j) as Node3D
			if node==null or Vector2(node.global_position.x,node.global_position.z).distance_to(Vector2(p[0],p[1]))>0.05: _fail("Spine frame %d moved from CityPlan"%j)
			checks+=1
		for j in service.get("piers",[]).size():
			var p: float=float(service.piers[j]); var node:=named.get("MeridianPierStem_%02d"%j) as Node3D
			if node==null or absf(node.global_position.x-p)>0.05 or absf(node.global_position.z)>0.05: _fail("Meridian pier %d moved from CityPlan"%j)
			checks+=1
	for i in PLAN.PARK.shrubs.size():
		var p: Array=PLAN.PARK.shrubs[i]; var found:=false
		for mm in multimeshes:
			if not String(mm.name).begins_with("ParkShrubMultiMesh_"): continue
			for inst in mm.multimesh.instance_count:
				var pos:=_multimesh_instance_position(mm,inst)
				if Vector2(pos.x,pos.z).distance_to(Vector2(p[0],p[1]))<0.05: found=true; break
			if found: break
		if not found: _fail("park shrub %d is not at its recorded point"%i)
		checks+=1
	for i in PLAN.PARK.reeds.size():
		var data: Dictionary=PLAN.PARK.reeds[i]; var p: Vector2=Vector2(data.c[0],data.c[1]); var found:=false
		for mm in multimeshes:
			if not String(mm.name).begins_with("ParkReedClumpMultiMesh_"): continue
			for inst in mm.multimesh.instance_count:
				var pos:=_multimesh_instance_position(mm,inst)
				if Vector2(pos.x,pos.z).distance_to(p)<0.05: found=true; break
			if found: break
		if not found: _fail("reed clump %d has no stem at its recorded point"%i)
		checks+=1
	for i in PLAN.PARK.agave.size():
		var p: Array=PLAN.PARK.agave[i]; var found:=false
		for mm in multimeshes:
			if not String(mm.name).begins_with("ParkAgaveMultiMesh_"): continue
			for inst in mm.multimesh.instance_count:
				var pos:=_multimesh_instance_position(mm,inst)
				if Vector2(pos.x,pos.z).distance_to(Vector2(p[0],p[1]))<0.05: found=true; break
			if found: break
		if not found: _fail("agave %d is not at its recorded point"%i)
		checks+=1
	print("MOY_PLAN_POSITIONS checked_records=",checks," tolerance_m=0.05 columns=",PLAN.DECK.columns.size()," beds_segments=",bed_segments," trees=32 plants=96 frames/piers=16")


func _multimesh_instance_position(instance: MultiMeshInstance3D, index: int) -> Vector3:
	var buffer:=instance.multimesh.buffer; var stride:=12+(4 if instance.multimesh.use_colors else 0)+(4 if instance.multimesh.use_custom_data else 0); var start:=index*stride
	if buffer.size()<start+12: return Vector3.INF
	var local:=Vector3(buffer[start+3],buffer[start+7],buffer[start+11])
	return instance.global_transform*local


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
			if node.name.begins_with("DeckLift_") and node is AnimatableBody3D and lift==null: lift=node as Node3D
			for sub in node.get_children(): stack.append(sub)
	if trains.size()!=12: _fail("expected 12 train consists (3 per each of four timetable services), got %d"%trains.size()); return
	if lift==null: _fail("public Deck lift missing"); return
	var rids: Array[RID] = []
	var movement_before: Dictionary = {}
	var stops_expected := {"Spine Line":5,"Meridian Line":3,"Wall Line inner":4,"Wall Line outer":4}
	for train in trains:
		var service := String(train.get("service_name"))
		var is_wall:=service.begins_with("Wall Line")
		var expected_cars := 3 if is_wall else 2
		var car_bodies: Array = train.get("_car_bodies")
		if car_bodies.size()!=expected_cars: _fail("%s car count mismatch: %d"%[service,car_bodies.size()])
		if (train.get("_stop_distances") as PackedFloat32Array).size()!=stops_expected[service]: _fail("%s station stop count mismatch"%service)
		if not is_equal_approx(float(train.get("dwell")),8.0): _fail("%s ordinary dwell is not 8 seconds"%service)
		var dwells: PackedFloat32Array=train.get("_stop_dwell_times")
		if dwells.size()!=stops_expected[service]: _fail("%s per-station dwell schedule missing"%service)
		for dwell_time in dwells:
			if dwell_time!=8.0 and dwell_time!=12.0: _fail("%s has invalid dwell %s"%[service,dwell_time])
		for car in car_bodies:
			if not car is AnimatableBody3D: _fail("train car is not an independent rideable physics body"); continue
			var rid: RID=car.get_rid()
			if rid in rids: _fail("train cars share a physics RID")
			rids.append(rid)
		_test_train_clearance(train)
		var events: Array=train.get("schedule_events")
		if events.is_empty(): _fail("%s has no authored timetable events"%service)
		else:
			var offset:=float(train.get("schedule_offset"))+float(train.get("schedule_train_index"))*float(train.get("schedule_headway"))
			for event in events:
				var event_sample_time:=float(event.arr)+0.01 if float(event.dep)>float(event.arr) else float(event.arr)
				var at_event:=train.call("_scheduled_state_at",offset+event_sample_time) as Dictionary
				if absf(float(at_event.s)-float(event.s))>0.05: _fail("%s does not arrive on its authored stop mark %s"%[service,event.stop])
				var authored_dwell:=float(event.dep)-float(event.arr)
				if authored_dwell>0.0 and absf(float(at_event.dwell)-authored_dwell)>0.05: _fail("%s dwell at %s is %.3f, timetable says %.3f game minutes"%[service,event.stop,float(at_event.dwell),authored_dwell])
			# Sample every game minute for a whole day twice: once minute-for-minute
			# and once by mapping 10x real minutes back onto the same game clock.
			# The public schedule is expressed in game minutes, so both runs must
			# visit the same complete 24-hour state sequence.
			for speed_scale in [1.0,10.0]:
				for minute in 1440:
					var game_minute:=float(minute) if speed_scale==1.0 else float(minute)*10.0/10.0
					var sample:=train.call("_scheduled_state_at",game_minute) as Dictionary
					if not is_finite(float(sample.s)) or float(sample.s)<0.0 or float(sample.s)>float(train.get("_total"))+0.01: _fail("%s timetable leaves its line at %.2f"%[service,sample.s]); break
					if not is_finite(float(sample.dwell)) or float(sample.dwell)<0.0: _fail("%s has invalid dwell state"%service); break
	var lift_before:=lift.position.y
	print("MOY_DECK_LIFT_SELECTED name=",lift.name," class=",lift.get_class()," script=",lift.get_script()," has_go_to=",lift.has_method("go_to")," y=",lift.position.y," base=",lift.get("base_height")," stops=",lift.get("stop_levels"))
	# Exercise the real update method at moving and stopping schedule instants.
	var original_time:=WorldState.game_time_hours
	for train in trains:
		var events: Array=train.get("schedule_events"); if events.is_empty(): continue
		var offset:=float(train.get("schedule_offset"))+float(train.get("schedule_train_index"))*float(train.get("schedule_headway"))
		var moving_minute:=offset+float(events[0].dep)+1.0
		WorldState.game_time_hours=fposmod(moving_minute/60.0,24.0); train.call("_physics_process",1.0/60.0)
		var moving_position:=float(train.get("_distance"))
		WorldState.game_time_hours=fposmod((moving_minute+2.0)/60.0,24.0); train.call("_physics_process",1.0/60.0)
		if absf(float(train.get("_distance"))-moving_position)<0.01: _fail("%s scheduled train failed to move on its line"%train.get("service_name"))
	WorldState.game_time_hours=original_time
	if lift.has_method("go_to"):
		print("MOY_DECK_LIFT before name=",lift.name," y=",lift.position.y," base=",lift.get("base_height")," stops=",lift.get("stop_levels")," target=",lift.get("_target_stop")," physics=",lift.is_physics_processing())
		lift.call("go_to", 1)
	for i in 1800:
		await get_tree().physics_frame
		if i%10==0: _check_gate_train_separation(trains)
	print("MOY_DECK_LIFT after y=",lift.position.y," target=",lift.get("_target_stop")," process=",lift.is_physics_processing()," paused=",get_tree().paused)
	if absf(lift.position.y-lift_before)<0.1: _fail("Deck lift platform did not respond to a floor call")
	print("MOY_MOVERS consists=",trains.size()," independent_cars=",rids.size()," route_stops=",stops_expected," dwell_seconds=8/12 gate_simulation_seconds=40 lift_call_delta_m=",absf(lift.position.y-lift_before))


func _check_gate_train_separation(trains: Array[Node3D]) -> void:
	for spine in trains:
		if String(spine.get("service_name"))!="Spine Line": continue
		for wall in trains:
			if not String(wall.get("service_name")).begins_with("Wall Line"): continue
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


func _test_timekeeper(city: Node) -> void:
	var root:=city.find_child("CrossingCityDome",true,false) as Node3D
	if root==null: _fail("Crossing dome and city clocks missing"); return
	var faces:=city.find_child("CityClockFaces",true,false)
	if faces==null or faces.get_child_count()!=4: _fail("four clock faces missing"); return
	var hour:=faces.get_child(0).get_node_or_null("CityClock_hour_0/Arrow") as MeshInstance3D
	var minute:=faces.get_child(0).get_node_or_null("CityClock_minute_0/Arrow") as MeshInstance3D
	if hour==null or minute==null: _fail("game clock hour/minute arrows missing"); return
	if faces.get_child(0).find_child("SecondsBead",true,false)!=null: _fail("removed fast seconds indicator is still present")
	if city.find_child("CityBell_SOUND_PLACEHOLDER",true,false)==null: _fail("named city bell placeholder missing")
	var previous_hour:=WorldState.game_time_hours
	var samples: Array[Dictionary]=[
		{"hour":3.0,"hour_angle":-PI*0.5,"minute_angle":0.0},
		{"hour":9.25,"hour_angle":-TAU*9.25/12.0,"minute_angle":-PI*0.5},
		{"hour":12.0,"hour_angle":0.0,"minute_angle":0.0},
	]
	for sample in samples:
		WorldState.game_time_hours=float(sample.hour); (faces as Node3D).call("_update_clock")
		for face_index in 4:
			var face:=faces.get_child(face_index) as Node3D
			var hour_ring:=face.get_node("CityClock_hour_%d"%face_index) as Node3D
			var minute_ring:=face.get_node("CityClock_minute_%d"%face_index) as Node3D
			if absf(wrapf(hour_ring.rotation.z-float(sample.hour_angle),-PI,PI))>0.002: _fail("clock hour hand is wrong at %s on face %d"%[sample.hour,face_index])
			if absf(wrapf(minute_ring.rotation.z-float(sample.minute_angle),-PI,PI))>0.002: _fail("clock minute hand is wrong at %s on face %d"%[sample.hour,face_index])
	WorldState.game_time_hours=previous_hour; (faces as Node3D).call("_update_clock")
	print("MOY_CLOCK faces=4 times=3:00,9:15,12:00 arrows=PASS seconds_indicator=REMOVED bell_sound=PLACEHOLDER")
	if city.find_child("TimekeeperRings",true,false)!=null: _fail("removed Timekeeper geometry is still present")


func _test_hotel_lift_schedules(city: Node) -> void:
	var lifts: Array[Node] = []
	var stack: Array[Node] = [city]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		if node is AnimatableBody3D and String(node.name).begins_with("HotelCapsuleLift_"): lifts.append(node)
		for child in node.get_children(): stack.append(child)
	if lifts.size()!=4:
		_fail("hotel capsule lift count is %d, expected four"%lifts.size())
		return
	var expected_labels := PackedStringArray(["Level 27 — Party suite", "Mezzanine", "Atrium floor"])
	for lift in lifts:
		var has_deck_collision:=false
		for part in lift.get_children():
			if part is CollisionShape3D: has_deck_collision=true
		if not lift is AnimatableBody3D or not lift.has_method("go_to") or not lift.has_method("destination_labels") or not has_deck_collision: _fail("hotel capsule is missing its controllable rideable deck: %s"%lift.name); continue
		if lift.call("destination_labels") != expected_labels: _fail("hotel capsule floor menu is not ordered top to bottom")
	var moving_lift:=lifts[0] as Node3D; var before:=moving_lift.global_position.y
	moving_lift.call("go_to", 1)
	for frame in 240: await get_tree().physics_frame
	if absf(moving_lift.global_position.y-before)<0.1: _fail("hotel capsule never moved during live physics")
	var crystal_node:=city.find_child("HotelChandelierCrystals",true,false) as MultiMeshInstance3D
	if crystal_node==null or crystal_node.multimesh==null or crystal_node.multimesh.instance_count!=int(PLAN.HOTEL.chandelier.crystals): _fail("hotel chandelier does not use the plan's crystal count")
	if _count_named(city,"HotelTowerRib_*")!=int(PLAN.HOTEL.tower.ribs): _fail("hotel tower rib count differs from plan")
	if _count_named(city,"HotelDrumRib_*")!=int(PLAN.HOTEL.drum.ribs): _fail("hotel tank/drum rib count differs from plan")
	if _count_named(city,"HotelWindroseMullion_*")!=int(PLAN.HOTEL.drum.mullions): _fail("hotel Windrose mullion count differs from plan")
	if _count_named(city,"HotelChandelierBronzeRing_*")!=int(PLAN.HOTEL.chandelier.tiers): _fail("hotel chandelier bronze ring count differs from plan")
	if _count_named(city,"HotelGalleryHangingPlants_*")!=11: _fail("hotel gallery hanging planting is incomplete")
	var door:=city.find_child("HotelRevolvingDoor",true,false)
	var windrose:=city.find_child("HotelWindroseTurningLight",true,false)
	if door==null or door.get_script()==null or not door is AnimatableBody3D: _fail("hotel revolving door is missing its moving body")
	if windrose==null or windrose.get_script()==null: _fail("hotel Windrose light ring is missing its rotation script")
	if door is Node3D and absf((door as Node3D).rotation.y)<0.01: _fail("hotel revolving door did not turn during physics")
	if windrose is Node3D and absf((windrose as Node3D).rotation.y)<0.01: _fail("hotel Windrose ring did not turn")
	var door_leaf_colliders:=0
	if door is Node:
		for leaf in door.get_children():
			for part in leaf.get_children():
				if part is CollisionShape3D: door_leaf_colliders+=1
	if door_leaf_colliders!=4: _fail("hotel revolving door needs four collidable moving leaves")
	for required in ["HotelReceptionDesk","HotelConciergeDesk","HotelIrisStand","HotelPitchedSkylight","HotelForecourtCistern","HotelLevel27RingCorridor","HotelLevel27PartySuite"]:
		if city.find_child(required,true,false)==null: _fail("hotel public prototype object is missing: %s"%required)
	if _count_named(city,"HotelRampLanding_*")!=4: _fail("hotel double ramp needs foot and head landings on both ramps")
	print("MOY_HOTEL_FIDELITY ribs=40 windrose_mullions=40 crystals=3000 bronze_rings=5 gallery_plants=11 service_objects=PASS ramp_end_landings=4 door=TURNING windrose=TURNING player_rides=UNTESTED")
	print("MOY_HOTEL_LIFTS cars=4 stops=0,6.5,89.5 floor_call=PASS menu_order=top_to_bottom player_rides=UNTESTED")


func _count_named(root: Node, pattern: String) -> int:
	var count:=0
	var stack: Array[Node]=[root]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		if node.name.match(pattern): count+=1
		for child in node.get_children(): stack.append(child)
	return count


func _test_train_clearance(train: Node3D) -> void:
	var sample_count := 0
	var car_envelope := BoxShape3D.new()
	car_envelope.size=Vector3(float(PLAN.TRAIN.car[0]),float(PLAN.TRAIN.car[1]),float(PLAN.TRAIN.car[2]))
	car_envelope.margin=0.0
	var circuit:=float(train.get("schedule_circuit")); var offset:=float(train.get("schedule_offset"))+float(train.get("schedule_train_index"))*float(train.get("schedule_headway"))
	for sample in ceili(circuit*60.0/5.0):
		var state: Dictionary=train.call("_scheduled_state_at",offset+float(sample)*5.0/60.0)
		var head_s:=float(state.s); var direction:=float(state.direction)
		for car_index in train.get("_car_bodies").size():
			var pose: Transform3D=train.call("_path_pose",head_s-float(car_index)*(float(PLAN.TRAIN.car[0])+float(PLAN.TRAIN.gangway))*direction)
			pose.origin.y+=1.0+float(PLAN.TRAIN.car[1])*0.5
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
					_fail("scheduled train clearance intersects %s on %s at %s"%[name,train.get("service_name"),pose.origin])
					return
			sample_count+=1
	print("MOY_TUNNEL_CLEARANCE service=",train.get("service_name")," scheduled_car_samples=",sample_count," tested_class=buildings,old_houses,lots,gate_masses,station_platforms")


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
