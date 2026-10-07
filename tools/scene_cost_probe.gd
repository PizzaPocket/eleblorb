extends Node

## Measures what the world costs to draw from a viewpoint, to find lag before
## guessing at it. Loads the main world, stands a camera at each view, waits
## for frames to settle, and prints the renderer's own counts (draw calls,
## objects, primitives) and the frame time, then what each top-level world
## node holds (meshes, distinct materials, lights, multimesh instances).
## Needs a window: headless has no renderer to count.
##
##   Godot --path . tools/scene_cost_probe.tscn
##   Godot --path . tools/scene_cost_probe.tscn -- --no-merge   (before StaticMerge)

const VIEWS := {
	# Plan points about the fishing village's centre (440, 0): from, to, height.
	"fishing landing, eye level": [Vector2(-33.0, -6.0), Vector2(0.0, -10.0), 1.7],
	"fishing pavilion, eye level": [Vector2(-2.0, 2.0), Vector2(20.0, -6.0), 1.7],
	"fishing from the water, west": [Vector2(-70.0, 10.0), Vector2(0.0, -6.0), 6.0],
}
const CENTRE := Vector2(440.0, 0.0)


func _ready() -> void:
	get_tree().create_timer(300.0).timeout.connect(func() -> void:
		print("FAIL scene_cost_probe watchdog")
		get_tree().quit(2))
	if "--no-merge" in OS.get_cmdline_user_args():
		StaticMerge.enabled = false
	_run.call_deferred()


func _run() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 900))
	WorldState.game_time_hours = 12.0
	var started := Time.get_ticks_msec()
	var world := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	print("world built in %.1f s (merge %s)" % [float(Time.get_ticks_msec() - started) / 1000.0, "on" if StaticMerge.enabled else "off"])
	for child in get_tree().root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	var water: float = world.get_node("Terrain").get_lake_water_level()
	var camera := Camera3D.new()
	camera.far = 1500.0
	camera.fov = 75.0
	add_child(camera)
	camera.current = true
	for view_name: String in VIEWS:
		var view: Array = VIEWS[view_name]
		var from: Vector2 = CENTRE + (view[0] as Vector2)
		var to: Vector2 = CENTRE + (view[1] as Vector2)
		camera.global_position = Vector3(from.x, water + float(view[2]) + 0.5, from.y)
		camera.look_at(Vector3(to.x, water + 1.5, to.y), Vector3.UP)
		for _i in 30:
			await get_tree().process_frame
		var frames := 60
		var t0 := Time.get_ticks_usec()
		for _i in frames:
			await get_tree().process_frame
		var frame_ms := float(Time.get_ticks_usec() - t0) / 1000.0 / float(frames)
		print("%s: %.1f ms/frame, %d draw calls, %d objects, %d primitives" % [
			view_name, frame_ms,
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		])
	# From the first view: what each world node costs, by hiding it.
	var first: Array = VIEWS.values()[0]
	var first_from: Vector2 = CENTRE + (first[0] as Vector2)
	camera.global_position = Vector3(first_from.x, water + float(first[2]) + 0.5, first_from.y)
	camera.look_at(Vector3(CENTRE.x + (first[1] as Vector2).x, water + 1.5, CENTRE.y + (first[1] as Vector2).y), Vector3.UP)
	for _i in 10:
		await get_tree().process_frame
	var total := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	print("---- triangles each world node adds at '%s' (total %d)" % [VIEWS.keys()[0], total])
	for child in world.get_children():
		if not (child is Node3D) or not (child as Node3D).visible:
			continue
		(child as Node3D).visible = false
		for _i in 4:
			await get_tree().process_frame
		var without := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
		(child as Node3D).visible = true
		if total - without > 50000:
			print("  %-28s %9d" % [child.name, total - without])
	var village := world.get_node_or_null("FloatingWaterVillage") as Node3D
	if village != null:
		print("---- inside the fishing village (and the islets' foliage)")
		var parts: Array[Node] = []
		for child in village.get_children():
			parts.append(child)
			if child.name == "FishingIslets":
				parts.append_array(child.get_children())
		for child in parts:
			if not (child is Node3D) or not (child as Node3D).visible:
				continue
			(child as Node3D).visible = false
			for _i in 4:
				await get_tree().process_frame
			var without := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
			(child as Node3D).visible = true
			if total - without > 150000:
				print("  %-28s %9d" % [child.name, total - without])
	for _i in 4:
		await get_tree().process_frame
	print("---- per world node: meshes, materials, lights (shadowed), multimesh instances")
	var rows: Array = []
	for child in world.get_children():
		var meshes := 0
		var materials := {}
		var lights := 0
		var shadowed := 0
		var instances := 0
		for node in child.find_children("*", "", true, false) + [child]:
			if node is MeshInstance3D:
				meshes += 1
				var mesh_node := node as MeshInstance3D
				var material: Material = mesh_node.material_override if mesh_node.material_override != null else mesh_node.get_surface_override_material(0) if mesh_node.mesh != null and mesh_node.mesh.get_surface_count() > 0 else null
				if material != null:
					materials[material.get_rid()] = true
			elif node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null:
				instances += (node as MultiMeshInstance3D).multimesh.instance_count
			elif node is Light3D:
				lights += 1
				if (node as Light3D).shadow_enabled:
					shadowed += 1
		rows.append([meshes, "%-28s %6d meshes %6d materials %4d lights (%d shadowed) %7d multimesh" % [child.name, meshes, materials.size(), lights, shadowed, instances]])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) > int(b[0]))
	for row: Array in rows:
		print(row[1])
	get_tree().quit()
