extends Node3D

## Repeatable fixed-camera render measurements. Run windowed with -- --qa
## for the isolated settlement, or without arguments for Crossroads startup.
func _ready() -> void:
	WorldState.opening_wake_completed=true
	WorldState.game_time_hours=12.0
	var isolated := "--qa" in OS.get_cmdline_user_args()
	var started := Time.get_ticks_msec()
	var world := load("res://scenes/chinese_village_qa.tscn" if isolated else "res://scenes/main.tscn").instantiate() as Node3D
	add_child(world)
	await LoadingScreen.wait_for_world_builds()
	for i in 8: await get_tree().process_frame
	print("CHINA_PERF build_ms=",Time.get_ticks_msec()-started," nodes=",Performance.get_monitor(Performance.OBJECT_NODE_COUNT)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0)
	for child in get_tree().root.get_children():
		if child is CanvasLayer: child.visible=false
	var camera := Camera3D.new()
	camera.far=1800.0
	add_child(camera)
	camera.position=Vector3(0,4,12)
	camera.look_at(Vector3(0,2,0))
	if isolated:
		var ground: float=world.get_node("ChineseVillage").get("_island_surface_y")
		camera.position=Vector3(265,ground+28,-595)
		camera.look_at(Vector3(240,ground+8,-660))
	camera.make_current()
	await _sample("china_qa" if isolated else "crossroads_spawn")
	if isolated:
		var ground: float=world.get_node("ChineseVillage").get("_island_surface_y")
		camera.position=Vector3(385,ground+12,-568)
		camera.look_at(Vector3(363,ground+1,-606))
		await _sample("china_fields")
	if not isolated:
		var village := world.get_node("ChineseVillage")
		var player := world.get_node("Player") as Node3D
		player.set_physics_process(false)
		var ground: float=village.get("_island_surface_y")
		player.position=Vector3(240,ground+0.5,-627)
		var approach := Time.get_ticks_msec()
		var worst := 0
		for frame in 2000:
			var before := Time.get_ticks_msec()
			village.call("_update_region")
			await get_tree().process_frame
			worst=maxi(worst,Time.get_ticks_msec()-before)
			if village.get("_plan_root")!=null: break
		print("CHINA_PERF activation_ms=",Time.get_ticks_msec()-approach," worst_ms=",worst)
		camera.position=Vector3(265,ground+28,-595)
		camera.look_at(Vector3(240,ground+8,-660))
		await _sample("crossroads_china_active")
	get_tree().quit()


func _sample(label_text: String) -> void:
	for i in 8: await get_tree().process_frame
	for sample_index in 2:
		var started := Time.get_ticks_msec()
		var frames := 0
		var worst := 0
		while Time.get_ticks_msec()-started<3000:
			var before := Time.get_ticks_msec()
			await get_tree().process_frame
			worst=maxi(worst,Time.get_ticks_msec()-before)
			frames+=1
		print("CHINA_PERF ",label_text," sample=",sample_index," fps=",1000.0*frames/float(Time.get_ticks_msec()-started)," worst_ms=",worst," draw_calls=",Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)," static_mib=",Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0," video_mib=",Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0)
