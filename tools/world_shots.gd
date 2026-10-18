extends Node

const STANDARD_VIEWS := {
	"overview": {"camera": Vector3(-130, 270, 470), "at": Vector3(-540, -40, 0)},
	"street_civic_west": {"camera": Vector3(-430, -58.2, -10), "at": Vector3(-400, -55, 0)},
	"street_civic_east": {"camera": Vector3(-360, -58.2, 10), "at": Vector3(-390, -55, 0)},
	"street_crossing_north": {"camera": Vector3(-555, -58.2, -25), "at": Vector3(-555, -55, -5)},
	"street_crossing_south": {"camera": Vector3(-555, -58.2, 25), "at": Vector3(-555, -55, 5)},
	"under_high_line": {"camera": Vector3(-482, -58.5, -14), "at": Vector3(-487, -54.5, -14)},
	"under_civic_north_flight": {"camera": Vector3(-482, -58.5, -14), "at": Vector3(-487, -54.5, -14)},
	"under_civic_south_flight": {"camera": Vector3(-482, -58.5, 14), "at": Vector3(-487, -54.5, 14)},
}

func _ready() -> void:
	call_deferred("_render_set")

func _render_set() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var package := String(args.get("package", "P0"))
	var date := String(args.get("date", "2026-10-18"))
	var views := _package_views(package)
	var root := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
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
	_add_flight_views(views, city)
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 52.0
	root.add_child(camera)
	get_viewport().size = Vector2i(1280, 720)
	var out_dir := "res://docs/diagnostics/images/%s-%s" % [date, package]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
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
			var error := image.save_png(ProjectSettings.globalize_path(path))
			if error != OK:
				push_error("Could not save screenshot %s: %s" % [path, error])
				get_tree().quit(1)
				return
			print("WORLD_SHOT ", path)
	get_tree().quit(0)

func _package_views(package:String)->Dictionary:
	var available := _read_places()
	var selected:Dictionary = STANDARD_VIEWS.duplicate(true)
	for standard_id in ["overview"]:
		if available.has(standard_id): selected[standard_id] = available[standard_id]
	var brief_path := "res://docs/architecture/moy_pkg_%s.md" % package
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

func _add_flight_views(views:Dictionary, city:Node)->void:
	var runs:Dictionary = {}
	for node in _walk(city):
		if not node is Node3D or not (node as Node3D).has_meta("flight"): continue
		var run_id := String((node as Node3D).get_meta("walk_run_id", node.name))
		var bounds := _world_bounds(node as Node3D)
		if not runs.has(run_id): runs[run_id] = bounds
		else:
			var merged:AABB = runs[run_id]
			runs[run_id] = merged.merge(bounds)
	for run_id in runs:
		var bounds:AABB = runs[run_id]
		var center := bounds.get_center()
		var key := "under_flight_%s" % String(run_id).to_lower().replace(":","_").replace(" ","_")
		views[key] = {"camera": Vector3(center.x,bounds.position.y-1.0,center.z), "at": Vector3(center.x,center.y+1.0,center.z)}

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
