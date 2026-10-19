extends Node

const STANDARD_VIEWS := {
	"overview": {"camera": Vector3(-130, 270, 470), "at": Vector3(-540, -40, 0)},
	"street_civic_west": {"camera": Vector3(-430, -58.2, -10), "at": Vector3(-400, -55, 0)},
	"street_civic_east": {"camera": Vector3(-360, -58.2, 10), "at": Vector3(-390, -55, 0)},
	"street_crossing_north": {"camera": Vector3(-555, -58.2, -25), "at": Vector3(-555, -55, -5)},
	"street_crossing_south": {"camera": Vector3(-555, -58.2, 25), "at": Vector3(-555, -55, 5)},
	"under_high_line": {"camera": Vector3(-472, -58.5, -28), "at": Vector3(-477, -54.5, -28)},
	"under_civic_north_flight": {"camera": Vector3(-482, -58.5, -14), "at": Vector3(-487, -54.5, -14)},
	"under_civic_south_flight": {"camera": Vector3(-482, -58.5, 14), "at": Vector3(-487, -54.5, 14)},
}
const P2_BENCHMARK_VIEWS := {
	"old_moy_street": {"camera": Vector3(-704, -54, -24), "at": Vector3(-700, -58, 0)},
	"old_moy_rooftop": {"camera": Vector3(-704, -29, -24), "at": Vector3(-700, -42, 0)},
	"downtown_up": {"camera": Vector3(-462, 5, -40), "at": Vector3(-462, -25, -20)},
	"estate_court": {"camera": Vector3(-535, -38, -125), "at": Vector3(-535, -48, -100)},
	"crossing_east_gate": {"camera": Vector3(-560, 8, 8), "at": Vector3(-560, 13.2, 0)},
	"east_gate_train_hall": {"camera": Vector3(-351, -34, -20), "at": Vector3(-351, -45, 0)},
}

func _ready() -> void:
	call_deferred("_render_set")

func _render_set() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var package := String(args.get("package", "P0"))
	var date := String(args.get("date", Time.get_date_string_from_system()))
	var views := _package_views(package)
	var root := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	if package in ["P2", "P3", "P4"]:
		var city_before_ready := root.get_node_or_null("WesternCity")
		if city_before_ready != null:
			city_before_ready.set_meta("moy_force_all_packs", true)
			city_before_ready.set_meta("moy_force_hotel_pack", true)
	get_tree().root.add_child(root)
	get_tree().current_scene = root
	await get_tree().process_frame
	var player := root.get_node_or_null("Player") as Node3D
	if player != null:
		player.global_position = Vector3(-540, -58, 0)
		player.set_physics_process(false)
	var city := root.get_node_or_null("WesternCity")
	var deadline := Time.get_ticks_msec() + 240000
	while city != null and city.has_method("moy_packs_ready") and not city.moy_packs_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().create_timer(0.25).timeout
	await get_tree().physics_frame
	if package not in ["P2", "P3", "P4"]:
		var reach_helper := _prepare_reach_helper(root, player)
		_add_flight_views(views, city, reach_helper)
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 70.0 if package == "P2" else 52.0
	camera.near = 0.05
	camera.far = 1800.0 if package in ["P2", "P3"] else camera.far
	root.add_child(camera)
	get_viewport().size = Vector2i(1280, 720)
	var out_dir := "res://docs/diagnostics/images/%s-%s" % [date, package]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var manifest := {"schema": 1, "package": package, "date": date,
		"run_id": String(args.get("run-id", "world-shots")), "commit": _git_commit(),
		"source_hashes": _source_hashes(), "godot_version": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "resolution": [1280, 720],
		"lighting_sets": ["noon", "dusk"], "camera_near": camera.near,
		"camera_far": camera.far, "screenshots": []}
	for view_name in views:
		var view: Dictionary = views[view_name]
		camera.global_position = view.camera
		var up := Vector3.UP
		if absf((view.at - view.camera).normalized().dot(up)) > 0.98: up = Vector3.FORWARD
		camera.look_at(view.at, up)
		for lighting in ["noon", "dusk"]:
			_set_lighting(root, lighting == "dusk")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var path := "%s/%s-%s.png" % [out_dir, view_name, lighting]
			print("WORLD_SHOT_SIZE ",path," ",image.get_width(),"x",image.get_height())
			var error := image.save_png(ProjectSettings.globalize_path(path))
			if error != OK:
				push_error("Could not save screenshot %s: %s" % [path, error])
				get_tree().quit(1)
				return
			print("WORLD_SHOT ", path)
			manifest.screenshots.append({"name": view_name, "lighting": lighting,
				"path": path, "camera": [view.camera.x, view.camera.y, view.camera.z],
				"target": [view.at.x, view.at.y, view.at.z], "fov": camera.fov,
				"camera_near": camera.near, "camera_far": camera.far,
				"controlled_body": [player.global_position.x, player.global_position.y, player.global_position.z] if player else null})
	var manifest_file := FileAccess.open("%s/shot-manifest.json" % out_dir, FileAccess.WRITE)
	if manifest_file:
		manifest_file.store_string(JSON.stringify(manifest, "\t"))
		manifest_file.close()
	get_tree().quit(0)

func _package_views(package:String)->Dictionary:
	if package == "P2": return P2_BENCHMARK_VIEWS.duplicate(true)
	var available := _read_places()
	var selected:Dictionary = {} if package in ["P3", "P4"] else STANDARD_VIEWS.duplicate(true)
	for standard_id in ([] if package in ["P3", "P4"] else ["overview"]):
		if available.has(standard_id): selected[standard_id] = available[standard_id]
	var brief_package := "P0" if package == "P0.1" else package
	var brief_path := "res://docs/architecture/moy_pkg_%s.md" % brief_package
	if not FileAccess.file_exists(brief_path): return selected
	var text := FileAccess.get_file_as_string(brief_path)
	var heading := RegEx.new(); heading.compile("(?ms)^## \\d+\\. Viewpoints\\s*\\n(.*?)(?=^## |\\z)")
	var heading_match := heading.search(text)
	if heading_match == null: return selected
	var names := RegEx.new(); names.compile("`([a-z0-9_]+)`")
	for match_view in names.search_all(heading_match.get_string(1)):
		var id := match_view.get_string(1)
		if available.has(id): selected[id] = available[id]
	return selected

func _git_commit() -> String:
	var output: Array = []
	var code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	return String(output[0]).strip_edges() if code == 0 and not output.is_empty() else "unavailable"

func _source_hashes() -> Dictionary:
	var result: Dictionary = {}
	for path in ["res://tools/world_shots.gd", "res://tools/moy_performance_probe.gd", "res://scripts/city_generator.gd"]:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			result[path] = "missing"
			continue
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(file.get_buffer(file.get_length()))
		result[path] = hash.finish().hex_encode()
	return result

func _prepare_reach_helper(root:Node3D, player:Node3D)->Node:
	var helper := (load("res://tools/world_checks.gd") as Script).new() as Node
	helper.set_meta("library_mode",true)
	root.add_child(helper)
	helper.set("_world",root)
	helper.set("_area",Vector4(-790.0,-210.0,-330.0,210.0))
	helper.set("_player_start",player.global_position if player != null else Vector3(-540.0,-58.0,0.0))
	if player != null:
		var floor_angle:Variant = player.get("floor_max_angle")
		if floor_angle != null: helper.set("_walkable_slope_dot",cos(float(floor_angle)))
	var meshes:Array[MeshInstance3D] = []
	var shapes:Array[CollisionShape3D] = []
	helper.call("_collect",root,meshes,shapes)
	var body_collision_shapes:Dictionary = {}
	for shape in shapes:
		var owner:CollisionObject3D = helper.call("_collision_owner_for_node",shape)
		if owner == null: continue
		var owner_id := owner.get_instance_id()
		if not body_collision_shapes.has(owner_id): body_collision_shapes[owner_id] = []
		body_collision_shapes[owner_id].append(shape)
	helper.set("_body_collision_shapes",body_collision_shapes)
	var bounds:Vector2 = helper.call("_scene_y_bounds",shapes)
	var grid:Dictionary = helper.call("_build_walk_grid",0.5,bounds.x,bounds.y)
	helper.set("_walk_grid",grid)
	helper.set("_grid_step",0.5)
	helper.call("_build_reach_graph",root)
	return helper

func _add_flight_views(views:Dictionary, city:Node, reach_helper:Node)->void:
	var runs:Dictionary = {}
	for node in _walk(city):
		if not node is Node3D or not (node as Node3D).has_meta("flight"): continue
		var run_id := String((node as Node3D).get_meta("walk_run_id", node.name))
		var bounds := _world_bounds(node as Node3D)
		if not runs.has(run_id): runs[run_id] = {"bounds":bounds,"bodies":[]}
		else:
			var current:AABB = runs[run_id].bounds
			runs[run_id].bounds = current.merge(bounds)
		runs[run_id].bodies.append(node as Node3D)
	var reachable:Dictionary = reach_helper.get("_reachable")
	var cells_by_run:Dictionary = {}
	for cell in reach_helper.get("_walk_cells"):
		var body:Node = cell.body
		if not body.has_meta("flight"): continue
		if not reachable.has(String(cell.id)): continue
		var run_id := String(body.get_meta("walk_run_id",body.name))
		if not runs.has(run_id): continue
		if not cells_by_run.has(run_id): cells_by_run[run_id] = []
		cells_by_run[run_id].append(cell)
	for run_id in runs:
		var view := _find_under_flight_view(String(run_id),runs[run_id],cells_by_run.get(run_id,[]),reach_helper,reachable)
		if view.has("skip_reason"):
			print("WORLD_SHOT_SKIP run=",run_id," reason=",view.skip_reason," reached_top_cells=",cells_by_run.get(run_id,[]).size())
			continue
		var key := "under_flight_%s" % String(run_id).to_lower().replace(":","_").replace(" ","_")
		views[key] = view

func _find_under_flight_view(run_id:String, run:Dictionary, top_cells:Array, helper:Node, reachable:Dictionary)->Dictionary:
	if top_cells.is_empty(): return {"skip_reason":"no_reached_top_cell"}
	var bodies:Array = run.bodies
	var body_meshes:Dictionary = {}
	for body in bodies:
		var owned:Array[MeshInstance3D] = []
		for node in _walk(body):
			if node is MeshInstance3D and helper.call("_collision_owner_for_node",node) == body and not helper.call("_is_underside_visual_only",node): owned.append(node as MeshInstance3D)
		body_meshes[body.get_instance_id()] = owned
	var reached_buckets:Dictionary = helper.get("_reached_buckets")
	var state := get_viewport().world_3d.direct_space_state
	var static_mask:int = int(helper.get("_static_mask"))
	var dynamic_excludes:Array = helper.get("_dynamic_excludes")
	var best:Dictionary = {}
	var best_score := INF
	for top_cell in top_cells:
		var body:Node3D = top_cell.body
		var cell_meshes:Array = body_meshes.get(body.get_instance_id(),[])
		if cell_meshes.is_empty(): continue
		var top_point := Vector2(float(top_cell.x),float(top_cell.z))
		var target_mesh:MeshInstance3D = null
		var target_y := NAN
		var underside_y := NAN
		for mesh in cell_meshes:
			var mesh_bounds:AABB = helper.call("_node_world_aabb",mesh)
			if top_point.x < mesh_bounds.position.x-0.01 or top_point.x > mesh_bounds.end.x+0.01 or top_point.y < mesh_bounds.position.z-0.01 or top_point.y > mesh_bounds.end.z+0.01: continue
			var surface_y:float = helper.call("_surface_y_at",mesh,top_point)
			if is_nan(surface_y) or absf(surface_y-float(top_cell.y)) > 0.15: continue
			var body_shapes:Array = helper.get("_body_collision_shapes").get(body.get_instance_id(),[])
			var thickness:float = helper.call("_underside_thickness",mesh,top_point,surface_y,body_shapes)
			var bottom_y:float = helper.call("_underside_y_at",mesh,top_point,surface_y,thickness)
			if is_nan(bottom_y): continue
			if is_nan(target_y) or surface_y > target_y:
				target_mesh=mesh; target_y=surface_y; underside_y=bottom_y
		if target_mesh == null: continue
		var buckets := Vector2i(floori(float(top_cell.x)/16.0),floori(float(top_cell.z)/16.0))
		for dx in range(-1,2):
			for dz in range(-1,2):
				for camera_cell in reached_buckets.get(buckets+Vector2i(dx,dz),[]):
					var horizontal := Vector2(float(camera_cell.x)-top_point.x,float(camera_cell.z)-top_point.y).length()
					if horizontal > 5.0 or float(camera_cell.y) >= underside_y-1.45: continue
					var camera_position:Vector3 = camera_cell.position+Vector3.UP*1.2
					var target := Vector3(top_point.x,underside_y-0.02,top_point.y)
					if target.y <= camera_position.y+0.15: continue
					var query := PhysicsRayQueryParameters3D.create(camera_position,target,static_mask)
					query.exclude = dynamic_excludes.duplicate()
					if camera_cell.body is CollisionObject3D: query.exclude.append((camera_cell.body as CollisionObject3D).get_rid())
					var hit := state.intersect_ray(query)
					if not hit.is_empty():
						var hit_node:Node = hit.get("collider") as Node
						if hit_node != body or Vector3(hit.position).distance_to(target) > 0.35: continue
					var score := absf(horizontal-2.0)+absf((target-camera_position).length()-5.0)*0.02
					if score < best_score:
						best_score=score
						best={"camera":camera_position,"at":target,"source_cell":camera_cell,"run":run_id,"mesh":target_mesh}
						if best_score < 0.05: return best
	if best.is_empty(): return {"skip_reason":"no_clear_ray_from_below"}
	return best

func _world_bounds(node:Node3D)->AABB:
	var found := false
	var bounds := AABB()
	for child in _walk(node):
		if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
			var mesh := child as MeshInstance3D
			var part := mesh.global_transform * mesh.mesh.get_aabb()
			if not found: bounds=part; found=true
			else: bounds=bounds.merge(part)
		elif child is CollisionShape3D and (child as CollisionShape3D).shape != null:
			var shape := child as CollisionShape3D
			var debug_mesh := shape.shape.get_debug_mesh()
			if debug_mesh == null: continue
			var part := shape.global_transform * debug_mesh.get_aabb()
			if not found: bounds=part; found=true
			else: bounds=bounds.merge(part)
	return bounds if found else AABB(node.global_position,Vector3.ZERO)

func _read_places()->Dictionary:
	var result:Dictionary = {}
	var path := "res://docs/drawings/moy_city_3d.html"
	if not FileAccess.file_exists(path): return result
	var html := FileAccess.get_file_as_string(path)
	var marker := html.find("const PLACES = [")
	if marker < 0: return result
	var end := html.find("\n];", marker)
	if end < 0: return result
	var block := html.substr(marker, end-marker)
	var entry := RegEx.new(); entry.compile('\\{ id: "([^"]+)"[^\\n]*?cam: \\[([^]]+)\\], at: \\[([^]]+)\\]')
	for found in entry.search_all(block):
		var camera := _parse_vector(found.get_string(2)); var target := _parse_vector(found.get_string(3))
		if camera.size()!=3 or target.size()!=3: continue
		result[found.get_string(1)] = {"camera": Vector3(camera[0]-560.0,camera[1]-60.0,camera[2]), "at": Vector3(target[0]-560.0,target[1]-60.0,target[2])}
	return result

func _parse_vector(raw:String)->Array[float]:
	var result:Array[float] = []
	for part in raw.split(","):
		result.append(float(part.strip_edges()))
	return result

func _set_lighting(root: Node, dusk: bool) -> void:
	for node in _walk(root):
		if node is DirectionalLight3D:
			(node as DirectionalLight3D).light_color = Color(0.66, 0.73, 1.0) if dusk else Color(1.0, 0.95, 0.84)
			(node as DirectionalLight3D).light_energy = 0.32 if dusk else 1.0
		elif node is WorldEnvironment and (node as WorldEnvironment).environment != null:
			var env := (node as WorldEnvironment).environment
			env.fog_enabled = false
			env.ambient_light_color = Color(0.19, 0.23, 0.4) if dusk else Color(0.7, 0.73, 0.78)

func _walk(node: Node) -> Array[Node]:
	var result: Array[Node] = [node]
	for child in node.get_children(): result.append_array(_walk(child))
	return result

func _parse_args(args: PackedStringArray) -> Dictionary:
	var result := {}
	for arg in args:
		var text := String(arg)
		if text.begins_with("--") and text.contains("="):
			var pair := text.trim_prefix("--").split("=", false, 1)
			result[pair[0]] = pair[1]
	return result
