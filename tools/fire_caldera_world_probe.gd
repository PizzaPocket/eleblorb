extends Node3D

## Live-scene route probe for the generated surface and Heartworks plans.

var _failures := 0
var _terrain: Node3D
var _world: Node3D
var _player: Player
var _xiao: XiaoHouZi
var _first_frame_marked := false


func _process(_delta: float) -> void:
	if not _first_frame_marked:
		_first_frame_marked = true
		print("FIRE_FIRST_FRAME_OBSERVATION")


func _ready() -> void:
	get_tree().create_timer(180.0).timeout.connect(func() -> void:
		print("FAIL fire_caldera_world_probe watchdog")
		get_tree().quit(2))
	_world = Node3D.new()
	_world.name = "RouteWorld"
	add_child(_world)
	_terrain = (load("res://scripts/fire_kingdom_terrain.gd") as GDScript).new()
	_terrain.name = "Terrain"
	_world.add_child(_terrain)
	var village: Node3D = (load("res://scripts/fire_kingdom_village.gd") as GDScript).new()
	village.name = "CalderaVillage"
	_world.add_child(village)
	_run.call_deferred()


func _run() -> void:
	await LoadingScreen.wait_for_world_builds()
	for _i in 2:
		await get_tree().physics_frame
	var frame := _terrain.get_node_or_null("CalderaCityGround") as Node3D
	_expect(frame != null, "live city frame is built")
	if frame == null:
		_finish()
		return
	var highline := frame.get_node_or_null("CalderaWalkways") as StaticBody3D
	var heart := frame.get_node_or_null("CalderaHeartworks") as StaticBody3D
	_expect(highline != null, "plan-driven surface walks are built")
	_expect(heart != null, "plan-driven Heartworks is built")
	_expect(frame.get_node_or_null("CalderaHeartworks/ReservoirGlassDome") != null, "dome and open oculus are built")
	_expect(frame.get_node_or_null("CalderaHeartworks/ContinuousLavaCascade") != null, "single cascade is built")
	_expect(frame.get_node_or_null("CalderaHeartworks/CollectionPoolLava") != null, "collection pool is built")
	var tongue := highline.get_node_or_null("RenewalImmersionTongueFlight") as MeshInstance3D
	_expect(tongue != null, "Renewal immersion tongue is built from its SITE profile")
	if tongue != null:
		var renewal: Dictionary = FireCalderaPlan.plot("RENEWAL")
		var tongue_plan: Dictionary = FireCalderaWalkwaysPlan.SITE["immersion_tongue"]
		var tongue_start: Array = tongue_plan["start"]
		var tongue_local := FireCalderaPlan.shell_to_plan(renewal, Vector2(float(tongue_start[0]), float(tongue_start[1]) + 0.2))
		var tongue_y := 30.0 - float(tongue_plan["drop"]) * 0.2 / float(tongue_plan["length"]) + 0.3
		var tongue_world := frame.global_transform * Vector3(tongue_local.x, tongue_y, tongue_local.y)
		var tongue_hit := _ray(get_world_3d().direct_space_state, tongue_world, tongue_world - Vector3.UP * 0.65)
		_expect(not tongue_hit.is_empty() and absf(float(tongue_hit["position"].y - tongue_world.y + 0.3)) < 0.24, "Renewal tongue mouth is flush with promenade and has collision")
	var centre_world := FireCalderaPlan.to_world(Vector2.ZERO)
	_expect(_terrain.is_lava_area(centre_world), "cascade column is registered as hazardous lava")
	var section: Dictionary = FireCalderaHeartworksPlan.SECTION
	var volumes: Array = section["lava_volumes"]
	var pool: Dictionary = volumes[2]
	var pool_mid := (float(pool["top"]) + float(pool["bottom"])) * 0.5
	_expect(is_equal_approx(_terrain.get_lava_surface_at(Vector3(centre_world.x, pool_mid, centre_world.y)), float(pool["surface"])), "3D liquid query resolves the collection pool")
	_expect(is_equal_approx(_terrain.get_lava_surface_at(Vector3(centre_world.x, float(section["lava_y"]) - 0.5, centre_world.y)), float(section["lava_y"])), "3D liquid query resolves the reservoir")
	_expect(not _terrain.is_lava_at(Vector3(centre_world.x, float(section["lava_y"]) + 1.0, centre_world.y)), "air above reservoir is not lava")
	var space := get_world_3d().direct_space_state
	var surface_routes := 0
	_spawn_playables()
	_check_cascade_liquid(section, centre_world)
	for flight: Dictionary in FireCalderaWalkwaysPlan.FLIGHTS:
		surface_routes += _check_profile(space, frame, highline, flight, "surface")
		_check_character_support(space, frame, flight)
	var heart_routes := 0
	for flight: Dictionary in FireCalderaHeartworksPlan.FLIGHTS:
		heart_routes += _check_profile(space, frame, heart, flight, "Heartworks")
		_check_character_support(space, frame, flight)
	_expect(surface_routes == FireCalderaWalkwaysPlan.FLIGHTS.size(), "all six surface flights have live physical support")
	_expect(heart_routes == FireCalderaHeartworksPlan.FLIGHTS.size(), "all eight Heartworks flights have live physical support")
	_check_junction(space, frame, "gate", FireCalderaWalkwaysPlan.LEVELS)
	_check_junction(space, frame, "highline", FireCalderaWalkwaysPlan.LEVELS)
	_check_junction(space, frame, "promenade", FireCalderaWalkwaysPlan.LEVELS)
	_check_junction(space, frame, "R3", FireCalderaHeartworksPlan.LEVELS)
	_check_junction(space, frame, "R2", FireCalderaHeartworksPlan.LEVELS)
	_check_junction(space, frame, "R1", FireCalderaHeartworksPlan.LEVELS)
	_check_junction(space, frame, "F", FireCalderaHeartworksPlan.LEVELS)
	var cars := frame.find_child("FunicularCarUp", true, false)
	_expect(cars != null and frame.find_child("FunicularCarDown", true, false) != null, "counterbalanced funicular cars are present")
	_check_funicular_corridor()
	_check_funicular(space, frame, highline)
	_finish()


func _check_profile(space: PhysicsDirectSpaceState3D, frame: Node3D, body: StaticBody3D, flight: Dictionary, label: String) -> int:
	var profile: Array = flight["profile"]
	var tested := 0
	var samples := [0, profile.size() / 4, profile.size() / 2, profile.size() * 3 / 4, profile.size() - 1]
	for index in samples:
		var p: Array = profile[index]
		var world := frame.global_transform * Vector3(float(p[0]), float(p[1]) + 0.30, float(p[2]))
		var hit := _ray(space, world, world - Vector3.UP * 0.65)
		var supported: bool = not hit.is_empty() and absf(float(hit["position"].y - world.y + 0.30)) < 0.24
		_expect(supported, "%s %s profile sample %d retains its authored floor" % [label, flight["id"], index])
		if supported:
			tested += 1
	return 1 if tested == samples.size() else 0


func _check_funicular_corridor() -> void:
	var profile: Array = FireCalderaWalkwaysPlan.SITE["funicular"]["profile"]
	var maximum := 0.0
	var max_index := -1
	var max_world := Vector2.ZERO
	var profile_top: Array = FireCalderaWalkwaysPlan.SITE["funicular"]["top"]
	var final_profile: Array = profile[profile.size() - 1]
	var tangent := (Vector2(float(final_profile[0]), float(final_profile[2])) - Vector2(float(profile_top[0]), float(profile_top[1]))).normalized()
	var normal := Vector2(-tangent.y, tangent.x)
	for i in profile.size():
		var raw: Array = profile[i]
		var world := FireCalderaPlan.to_world(Vector2(float(raw[0]), float(raw[2])))
		var live_ground := -INF
		for offset in [-5.3, 0.0, 5.3]:
			var sample_local: Vector2 = Vector2(float(raw[0]), float(raw[2])) + normal * float(offset)
			var sample_world := FireCalderaPlan.to_world(sample_local)
			live_ground = maxf(live_ground, _terrain.get_mesh_height(sample_world.x, sample_world.y))
		var difference := absf(live_ground - float(raw[3]))
		if difference > maximum:
			maximum = difference
			max_index = i
			max_world = world
	var max_raw: float = _terrain.get_mesh_height(max_world.x, max_world.y)
	var weight: float = _terrain._funicular_corridor_weight(max_world)
	print("FUNicular_CORRIDOR_MAX_HEIGHT_DIFF=%.4f INDEX=%d PLAN=%.4f LIVE=%.4f LEGACY=%.4f WEIGHT=%.3f" % [maximum, max_index, float(profile[max_index][3]), _terrain.get_mesh_height(max_world.x, max_world.y), max_raw, weight])
	_expect(maximum < 0.05, "funicular corridor terrain follows every generated ground sample within five centimetres")


func _check_junction(space: PhysicsDirectSpaceState3D, frame: Node3D, id: String, levels: Array) -> void:
	for level: Dictionary in levels:
		if str(level["id"]) != id:
			continue
		var region: Dictionary = level["surface"][0]
		var polygon := FireCalderaPlanWalks._polygon_with_holes(region)
		var indices := Geometry2D.triangulate_polygon(polygon)
		var found := false
		for i in range(0, indices.size(), 3):
			var local := (polygon[indices[i]] + polygon[indices[i + 1]] + polygon[indices[i + 2]]) / 3.0
			var world := frame.global_transform * Vector3(local.x, float(level["datum"]) + 0.35, local.y)
			var hit := _ray(space, world, world - Vector3.UP * 0.7)
			if not hit.is_empty() and absf(float(hit["position"].y - world.y + 0.35)) < 0.24:
				found = true
				break
		_expect(found, "%s plan surface contains walkable collision" % id)
		return


func _spawn_playables() -> void:
	_player = (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
	_player.name = "Player"
	_world.add_child(_player)
	_player.set_process(false)
	_player.set_physics_process(false)
	_xiao = (load("res://scenes/xiao_hou_zi.tscn") as PackedScene).instantiate() as XiaoHouZi
	_xiao.name = "XiaoHouZi"
	_world.add_child(_xiao)
	_xiao.set_process(false)
	_xiao.set_physics_process(false)
	_equip_test_lava_suit(_player)
	_equip_test_lava_suit(_xiao)


func _equip_test_lava_suit(actor: Node) -> void:
	var suit := actor.get("_blorb_suit") as BlorbSuitController
	if suit == null:
		_expect(false, "%s has a suit controller" % actor.name)
		return
	var worn: Array[Dictionary] = []
	for slot: String in ["head", "torso", "arm_left", "arm_right", "leg_left", "leg_right"]:
		var blorb := Blorb.new()
		blorb.portrait_mode = true
		blorb.element_state = "fire"
		if slot == "head":
			blorb.core_items = ["Lava Helm"]
		worn.append({"slot": slot, "blorb": blorb})
	suit.set("_worn", worn)
	_expect(suit.has_lava_safe_legs(), "%s wears two landed fire legs for lava traversal" % actor.name)
	_expect(suit.has_full_lava_suit(), "%s wears the full Lava Helm formation for lava immersion" % actor.name)


func _check_cascade_liquid(section: Dictionary, centre: Vector2) -> void:
	var pool: Dictionary = section["lava_volumes"][2]
	var pool_y := float(pool["surface"])
	var pool_mid := (float(pool["top"]) + float(pool["bottom"])) * 0.5
	for actor: Node3D in [_player, _xiao]:
		var suit := actor.get("_blorb_suit") as BlorbSuitController
		var liquid := LiquidEnvironment.new()
		for y: float in [pool_mid, pool_y + 0.5, -10.0, float(section["lava_y"]) - 0.5]:
			var at := Vector3(centre.x, y, centre.y)
			liquid.read(_terrain, suit, at)
			_expect(liquid.in_lava(), "%s swimmer remains in hazardous lava along cascade ascent/descent at Y %.2f" % [actor.name, y])
			if y <= pool_y:
				_expect(is_equal_approx(liquid.surface_height, pool_y), "%s resolves collection-pool surface at Y %.2f" % [actor.name, y])
			else:
				_expect(is_equal_approx(liquid.surface_height, float(section["lava_y"])), "%s resolves reservoir surface at Y %.2f" % [actor.name, y])


func _check_funicular(_space: PhysicsDirectSpaceState3D, _frame: Node3D, highline: StaticBody3D) -> void:
	for station_name in ["funicular-footFloor", "gateFloor"]:
		var station := highline.get_node_or_null(station_name) as MeshInstance3D
		_expect(station != null, "%s boarding platform exists" % station_name)
		if station == null:
			continue
		var collision_name: String = station_name + "Collision"
		var collision := highline.get_node_or_null(collision_name) as CollisionShape3D
		_expect(collision != null and collision.shape != null, "%s boarding platform has live collision" % station_name)
	var lift := highline.get_node_or_null("CounterbalancedFunicular") as Node3D
	var up := lift.get_node_or_null("FunicularCarUp") as Node3D if lift != null else null
	var down := lift.get_node_or_null("FunicularCarDown") as Node3D if lift != null else null
	if lift == null or up == null or down == null:
		_expect(false, "funicular car controller and both moving cars are present")
		return
	var before_up := up.global_position
	var before_down := down.global_position
	var before_player := _player.global_position
	var before_xiao := _xiao.global_position
	_player.global_position = up.global_position + Vector3(-0.45, 0.25, 0.0)
	_xiao.global_position = up.global_position + Vector3(0.45, 0.25, 0.0)
	lift.call("_process", 0.0)
	lift.call("_process", 4.0)
	_expect(up.global_position.distance_to(before_up) > 0.05 and down.global_position.distance_to(before_down) > 0.05, "both funicular cars move along the sampled profile")
	_expect(_player.global_position.distance_to(before_player) > 0.05 and _xiao.global_position.distance_to(before_xiao) > 0.05, "both playable characters are carried when aboard")


func _check_character_support(space: PhysicsDirectSpaceState3D, frame: Node3D, flight: Dictionary) -> void:
	var profile: Array = flight["profile"]
	for character: int in 2:
		var forward := [0, profile.size() / 2, profile.size() - 1]
		for direction: int in 2:
			var samples: Array = forward if direction == 0 else [profile.size() - 1, profile.size() / 2, 0]
			for sample: int in samples:
				var p: Array = profile[sample]
				var y := float(p[1]) + (Player.FOOT_OFFSET if character == 0 else 0.0)
				var position := frame.global_transform * Vector3(float(p[0]), y, float(p[2]))
				if character == 0:
					_player.global_position = position
					var has_support := bool(_player.call("_has_nearby_walkable_support"))
					if not has_support and str(flight["id"]) == "LK":
						var diagnostic := KinematicCollision3D.new()
						_player.test_move(_player.global_transform, Vector3.DOWN * 0.16, diagnostic)
						print("LK threshold diagnostic collisions=%d normal=%s collider=%s" % [diagnostic.get_collision_count(), diagnostic.get_normal(0) if diagnostic.get_collision_count() > 0 else Vector3.ZERO, diagnostic.get_collider(0).name if diagnostic.get_collision_count() > 0 else "none"])
					_expect(has_support, "human has physical support at %s %s sample %d" % [flight["id"], "outbound" if direction == 0 else "return", sample])
				else:
					_xiao.global_position = position
					var result := KinematicCollision3D.new()
					var supported := _xiao.test_move(_xiao.global_transform, Vector3.DOWN * 0.16, result)
					_expect(supported, "Xiao has physical support at %s %s sample %d" % [flight["id"], "outbound" if direction == 0 else "return", sample])


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	return space.intersect_ray(query)


func _expect(condition: bool, message: String) -> void:
	print(("ok   " if condition else "FAIL ") + message)
	_failures += 0 if condition else 1


func _finish() -> void:
	print("---- fire_caldera_world_probe: %d FAIL" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
