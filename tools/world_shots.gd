extends Node

const VIEWS := {
	"overview": {"camera": Vector3(-130, 270, 470), "at": Vector3(-540, -40, 0)},
	"skyline": {"camera": Vector3(-1030, 10, 40), "at": Vector3(-480, 10, -10)},
	"street": {"camera": Vector3(-468, -58.2, 6), "at": Vector3(-380, -40, 0)},
	"under_high_line": {"camera": Vector3(-540, -61, -12), "at": Vector3(-420, -25, 0)},
}

func _ready() -> void:
	call_deferred("_render_set")

func _render_set() -> void:
	var args := _parse_args(OS.get_cmdline_user_args())
	var package := String(args.get("package", "P0"))
	var date := String(args.get("date", "2026-10-18"))
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
	var camera := Camera3D.new()
	camera.current = true
	camera.fov = 52.0
	root.add_child(camera)
	get_viewport().size = Vector2i(1280, 720)
	var out_dir := "res://docs/diagnostics/images/%s-%s" % [date, package]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	for view_name in VIEWS:
		var view: Dictionary = VIEWS[view_name]
		camera.global_position = view.camera
		camera.look_at(view.at, Vector3.UP)
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

func _set_lighting(root: Node, dusk: bool) -> void:
	for node in _walk(root):
		if node is DirectionalLight3D:
			(node as DirectionalLight3D).light_color = Color(0.66, 0.73, 1.0) if dusk else Color(1.0, 0.95, 0.84)
			(node as DirectionalLight3D).light_energy = 0.32 if dusk else 1.0
		elif node is WorldEnvironment and (node as WorldEnvironment).environment != null:
			var env := (node as WorldEnvironment).environment
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
