extends Node3D

## Windowed renderer probe. Run with Godot tools/moy_performance_probe.tscn.
const MAIN := preload("res://scenes/main.tscn")
const CAPTURE_DIR := "res://docs/diagnostics/moy-prototype-captures"
var _deltas: Array[float] = []

func _ready() -> void:
	WorldState.opening_wake_completed = true
	WorldState.game_time_hours = 12.0
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CAPTURE_DIR))
	var build_started := Time.get_ticks_usec()
	var world := MAIN.instantiate() as Node3D
	add_child(world)
	await LoadingScreen.wait_for_world_builds()
	var player := world.get_node("Player") as Node3D
	player.set_physics_process(false)
	var player_camera := player.get_node("CameraRig/CameraPivot/SpringArm3D/Camera3D") as Camera3D
	player_camera.clear_current()
	player_camera.set_process(false)
	player_camera.set_physics_process(false)
	var camera := Camera3D.new(); camera.far = 1800.0; add_child(camera); camera.make_current()
	await _sample("crossroads_sleep",camera,Vector3(0,7,16),Vector3(0,2,0),true)
	print("MOY_PERF startup_world_ms=",(Time.get_ticks_usec()-build_started)/1000.0," renderer=",RenderingServer.get_video_adapter_name()," window=",DisplayServer.window_get_size()," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," bodies=",Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
	var spawn := player.global_position
	var city := world.get_node("WesternCity")
	for cycle in 2:
		player.global_position=Vector3(-600,-59.0,0)
		var ready_started := Time.get_ticks_usec()
		var guard := 0
		while not city.call("moy_packs_ready") and guard < 2400:
			guard+=1; await get_tree().process_frame
		if not city.call("moy_packs_ready"):
			push_error("Moy performance probe timed out waiting for playable packs")
			get_tree().quit(2); return
		var packs_ready_ms := (Time.get_ticks_usec()-ready_started)/1000.0
		guard=0
		while not city.call("moy_actors_ready") and guard<600:
			guard+=1; await get_tree().process_frame
		print("MOY_PERF cycle=",cycle+1," packs_ready_ms=",packs_ready_ms," actors_ready_ms=",(Time.get_ticks_usec()-ready_started)/1000.0," packs=",city.get_child_count()," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," bodies=",city.call("_count_physics_bodies",city)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
		await _sample("old_moy",camera,Vector3(-600,-18,65),Vector3(-600,-32,0),true)
		await _sample("downtown_up",camera,Vector3(-464,10,-15),Vector3(-464,120,-15),true)
		await _sample("estate_court",camera,Vector3(-552,-46,-105),Vector3(-552,-42,-115),true)
		await _sample("train_view",camera,Vector3(-542,5,28),Vector3(-557,-20,10),true)
		player.global_position=spawn
		var unload_started := Time.get_ticks_usec()
		guard=0
		while (city.call("moy_packs_ready") or city.get_child_count()>1) and guard<2400:
			guard+=1; await get_tree().process_frame
		print("MOY_PERF cycle=",cycle+1," unload_ms=",(Time.get_ticks_usec()-unload_started)/1000.0," guards=",guard," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
	await _sample("crossroads_after_unloads",camera,Vector3(0,7,16),Vector3(0,2,0),true)
	get_tree().quit()

func _sample(label: String, camera: Camera3D, position: Vector3, target: Vector3, capture: bool) -> void:
	camera.global_position=position
	var direction := (target-position).normalized()
	var up := Vector3.FORWARD if absf(direction.dot(Vector3.UP)) > 0.98 else Vector3.UP
	camera.look_at(target,up); camera.make_current(); await get_tree().process_frame
	for i in 8: await get_tree().process_frame
	if capture:
		var image := get_viewport().get_texture().get_image()
		var path := "%s/%s.png" % [CAPTURE_DIR,label]
		var err := image.save_png(ProjectSettings.globalize_path(path))
		print("MOY_CAPTURE path=",path," size=",image.get_size()," error=",err)
	_deltas.clear()
	for i in 300:
		await get_tree().process_frame
		_deltas.append(get_process_delta_time()*1000.0)
	_deltas.sort()
	var p50 := _percentile(0.50); var p95 := _percentile(0.95); var p99 := _percentile(0.99); var worst := _deltas[-1] if not _deltas.is_empty() else 0.0
	print("MOY_PERF view=",label," frames=",_deltas.size()," p50_ms=",p50," p95_ms=",p95," p99_ms=",p99," worst_ms=",worst," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," triangles=",Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0," video_mib=",Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0)

func _percentile(p: float) -> float:
	if _deltas.is_empty(): return 0.0
	return _deltas[clampi(ceili(float(_deltas.size()-1)*p),0,_deltas.size()-1)]
