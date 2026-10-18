extends Node3D

## Windowed, rendered city measurement. Start without user args for the normal
## Crossroads-to-Moy path, or pass --qa to measure the isolated traversal scene.
const MAIN := preload("res://scenes/main.tscn")
const QA := preload("res://scenes/moy_city_qa.tscn")

func _ready() -> void:
	WorldState.opening_wake_completed=true
	WorldState.game_time_hours=12.0
	var qa_mode: bool="--qa" in OS.get_cmdline_user_args()
	var start_usec:=Time.get_ticks_usec()
	var world: Node3D=(QA if qa_mode else MAIN).instantiate() as Node3D
	add_child(world)
	await LoadingScreen.wait_for_world_builds()
	for i in 8: await get_tree().process_frame
	var player:=world.get_node_or_null("Player") as Player
	var terrain:=world.get_node_or_null("Terrain")
	var city:=world.get_node_or_null("WesternCity")
	var city_start_ms:float=float(Time.get_ticks_usec()-start_usec)/1000.0
	print("MOY_PERF_START mode=",("qa" if qa_mode else "crossroads")," startup_ms=",city_start_ms," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
	for child in get_tree().root.get_children():
		if child is CanvasLayer: child.visible=false
	var camera:=Camera3D.new(); camera.name="MoyPerfCamera"; camera.far=1800.0; add_child(camera); camera.make_current()
	var views:Array[Dictionary]=[]
	if qa_mode:
		if player and terrain:
			var ground:float=terrain.call("get_mesh_height",-704.0,0.0); player.global_position=Vector3(-704.0,ground+0.5,0.0)
			for i in 2400:
				await get_tree().process_frame
				if city and bool(city.call("moy_packs_ready")): break
		await _sample(camera,"qa_dense_old_moy",Vector3(-704.0,-27.0,0.0),Vector3(-700.0,-42.0,0.0),player,terrain,city)
	else:
		await _sample(camera,"crossroads_spawn",Vector3(0,4,12),Vector3(0,2,0),player,terrain,city)
		if player and terrain:
			player.set_physics_process(false)
			var ground:float=terrain.call("get_mesh_height",-600.0,0.0)
			player.global_position=Vector3(-600.0,ground+0.5,0.0)
			var approach_start:=Time.get_ticks_usec()
			for i in 2400:
				await get_tree().process_frame
				if city and bool(city.call("moy_packs_ready")): break
			print("MOY_PERF_APPROACH elapsed_ms=",float(Time.get_ticks_usec()-approach_start)/1000.0," packs_ready=",bool(city.call("moy_packs_ready")) if city else false)
			views=[
				{"name":"old_moy_market","camera":Vector3(-704.0,-29.0,-24.0),"look":Vector3(-704.0,-48.0,0.0),"player":Vector2(-704,0)},
				{"name":"downtown_up","camera":Vector3(-462.0,5.0,-40.0),"look":Vector3(-462.0,-25.0,-20.0),"player":Vector2(-462,-20)},
				{"name":"estate_court","camera":Vector3(-535.0,-38.0,-125.0),"look":Vector3(-535.0,-48.0,-100.0),"player":Vector2(-535,-100)},
				{"name":"train_ride","camera":Vector3(-560.0,-34.0,-12.0),"look":Vector3(-560.0,-45.0,0.0),"player":Vector2(-560,0)},
			]
		for view in views:
			var p:Vector2=view.player; var y:=float(terrain.call("get_mesh_height",p.x,p.y))+0.5
			player.global_position=Vector3(p.x,y,p.y)
			await _sample(camera,String(view.name),view.camera,view.look,player,terrain,city)
		for cycle in 2:
			var away_ground:float=terrain.call("get_mesh_height",-1600.0,0.0); player.global_position=Vector3(-1600.0,away_ground+0.5,0.0)
			var unload_start:=Time.get_ticks_usec()
			for i in 1200:
				await get_tree().process_frame
				if city and int(city.get("_moy_active").size())==0: break
			var after_unload:=int(city.get("_moy_active").size()) if city else -1
			var near_ground:float=terrain.call("get_mesh_height",-600.0,0.0); player.global_position=Vector3(-600.0,near_ground+0.5,0.0)
			for i in 2400:
				await get_tree().process_frame
				if city and bool(city.call("moy_packs_ready")): break
			print("MOY_PERF_RELOAD cycle=",cycle+1," active_after_unload=",after_unload," packs_ready=",bool(city.call("moy_packs_ready")) if city else false," cycle_ms=",float(Time.get_ticks_usec()-unload_start)/1000.0," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	get_tree().quit()

func _sample(camera: Camera3D, label: String, position: Vector3, target: Vector3, player: Player, terrain: Node, city: Node) -> void:
	camera.global_position=position; camera.look_at(target)
	for i in 120: await get_tree().process_frame
	var frames: Array[float]=[]; var started:=Time.get_ticks_usec(); var previous:=started
	while Time.get_ticks_usec()-started<5000000:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec(); frames.append(float(now-previous)/1000.0); previous=now
	frames.sort()
	var sum:=0.0; var worst:=0.0
	for frame_ms in frames: sum+=frame_ms; worst=maxf(worst,frame_ms)
	var fps:=1000.0/(sum/maxf(1.0,float(frames.size())))
	var packs:=int(city.call("get_active_moy_pack_count")) if city and city.has_method("get_active_moy_pack_count") else -1
	print("MOY_PERF_SAMPLE name=",label," frames=",frames.size()," fps_mean=",fps," p50_ms=",_percentile(frames,0.50)," p95_ms=",_percentile(frames,0.95)," p99_ms=",_percentile(frames,0.99)," worst_ms=",worst," draws=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," triangles=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0," video_mib=",Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," active_packs=",packs," physics_objects=",Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))

func _percentile(values: Array[float], quantile: float) -> float:
	if values.is_empty(): return 0.0
	return values[clampi(ceili(float(values.size()-1)*quantile),0,values.size()-1)]
