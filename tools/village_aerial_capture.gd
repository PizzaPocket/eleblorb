extends Node

## Layout-audit tool: loads one world, waits for every build stage, then saves
## a top-down orthographic view and a three-quarter view of a village.
##   Godot --path . --resolution 1600x1600 tools/village_aerial_capture.tscn -- --village=ohio
##   Godot --path . --resolution 1600x1600 tools/village_aerial_capture.tscn -- --village=snow
## Images land in res://wip/village_audit/.

const TARGETS := {
	"ohio": {"scene": "res://scenes/main.tscn", "center": Vector2(150.0, 70.0), "extent": 80.0,
		"eye_from": Vector2(-44.0, -19.0), "eye_to": Vector2(-14.0, -6.0)},
	"snow": {"scene": "res://scenes/ice_kingdom.tscn", "center": Vector2(-135.0, -75.0), "extent": 95.0,
		"eye_from": Vector2(8.0, 38.0), "eye_to": Vector2(0.0, -3.0)},
	# The Chinese Village floats at one fixed height over the abyss: ground is the
	# island surface, not the terrain below.
	"china": {"scene": "res://scenes/main.tscn", "center": Vector2(250.0, -650.0), "extent": 170.0,
		"eye_from": Vector2(0.0, 150.0), "eye_to": Vector2(0.0, 40.0),
		"ground_node": "ChineseVillage", "ground_prop": "_island_surface_y"},
	# The fishing village stands over the lake: ground is the lake surface.
	"fishing": {"scene": "res://scenes/main.tscn", "center": Vector2(440.0, 0.0), "extent": 60.0,
		"eye_from": Vector2(-62.0, 14.0), "eye_to": Vector2(-30.0, -10.0),
		"ground_node": "FloatingWaterVillage", "ground_prop": "_water"},
}
const OUTPUT_DIR := "res://wip/village_audit"

## Optional `--shots=name:fx,fz,tx,tz,height;...`: only these eye-level shots, with
## positions in village-local metres (e.g. to look inside a building).
var _shots_only := ""
## Optional `--cut=H`: hides every visual in the Town above H metres, so a shot
## looks down into the rooms of a building like a plan.
var _cut_height := -1.0
var _ground_override := NAN


func _ready() -> void:
	var name := "ohio"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--village="):
			name = arg.trim_prefix("--village=")
		elif arg.begins_with("--shots="):
			_shots_only = arg.trim_prefix("--shots=")
		elif arg.begins_with("--cut="):
			_cut_height = float(arg.trim_prefix("--cut="))
			# A cutaway hides pieces by height, so they must stay unmerged.
			StaticMerge.enabled = false
	if not TARGETS.has(name):
		push_error("Unknown village %s" % name)
		get_tree().quit(1)
		return
	_run.call_deferred(name)


func _run(name: String) -> void:
	var target: Dictionary = TARGETS[name]
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1600, 1600))
	# Midday, so the audit images are not tinted by dusk or dawn.
	WorldState.game_time_hours = 12.0
	var world := (load(target["scene"]) as PackedScene).instantiate()
	for node in world.find_children("*", "Node", true, false):
		if node.get("initial_time_override") != null:
			node.set("initial_time_override", 12.0)
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 30:
		await get_tree().process_frame
	var town_name := "Town" if world.has_node("Town") else "SnowVillage"
	if _cut_height > 0.0 and world.has_node(town_name):
		var town_node := world.get_node(town_name) as Node3D
		for visual in town_node.find_children("*", "VisualInstance3D", true, false):
			if (visual as Node3D).global_position.y - town_node.global_position.y > _cut_height:
				(visual as Node3D).visible = false
	for child in get_tree().root.get_children():
		if child is CanvasLayer:
			(child as CanvasLayer).visible = false
	for node in world.find_children("*", "WorldEnvironment", true, false):
		var environment := (node as WorldEnvironment).environment
		if environment != null:
			environment.fog_enabled = false
	for node in world.get_children():
		if node.name.to_lower().contains("cloud") and node is Node3D:
			(node as Node3D).visible = false
	var ocean := world.find_child("SphericalWorldOcean", true, false)
	if ocean != null:
		print("Planetary ocean surface_level: ", ocean.get("surface_level"))
	var terrain := world.get_node("Terrain")
	var center2: Vector2 = target["center"]
	_ground_override = NAN
	if target.has("ground_node") and world.has_node(str(target["ground_node"])):
		_ground_override = float(world.get_node(str(target["ground_node"])).get(str(target["ground_prop"])))
	var ground: float = _ground_at(terrain, center2)
	var center := Vector3(center2.x, ground, center2.y)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	var camera := Camera3D.new()
	add_child(camera)
	camera.far = 600.0
	if not _shots_only.is_empty():
		camera.fov = 80.0
		camera.current = true
		for shot in _shots_only.split(";", false):
			var parts := shot.split(":")
			var numbers := parts[1].split(",")
			var from := center2 + Vector2(float(numbers[0]), float(numbers[1]))
			var to := center2 + Vector2(float(numbers[2]), float(numbers[3]))
			var height := float(numbers[4])
			camera.global_position = Vector3(from.x, _ground_at(terrain, from) + height, from.y)
			var target_height := float(numbers[5]) if numbers.size() > 5 else height * 0.8
			camera.look_at(Vector3(to.x, _ground_at(terrain, to) + target_height, to.y), Vector3.UP)
			await _capture("%s/%s_%s.png" % [OUTPUT_DIR, name, parts[0]])
		get_tree().quit()
		return
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(target["extent"]) * 2.0
	camera.far = 600.0
	camera.global_position = center + Vector3(0.0, 150.0, 0.0)
	camera.look_at(center, Vector3(0.0, 0.0, -1.0))
	camera.current = true
	await _capture("%s/%s_topdown.png" % [OUTPUT_DIR, name])

	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 50.0
	camera.global_position = center + Vector3(0.0, 70.0, 80.0)
	camera.look_at(center, Vector3.UP)
	await _capture("%s/%s_oblique_south.png" % [OUTPUT_DIR, name])
	camera.global_position = center + Vector3(-80.0, 70.0, 0.0)
	camera.look_at(center, Vector3.UP)
	await _capture("%s/%s_oblique_west.png" % [OUTPUT_DIR, name])
	# Eye level, as a visitor would see the ground and paths.
	var eye_from: Vector2 = center2 + (target["eye_from"] as Vector2)
	var eye_to: Vector2 = center2 + (target["eye_to"] as Vector2)
	camera.fov = 70.0
	camera.global_position = Vector3(eye_from.x, _ground_at(terrain, eye_from) + 3.2, eye_from.y)
	camera.look_at(Vector3(eye_to.x, _ground_at(terrain, eye_to) + 1.5, eye_to.y), Vector3.UP)
	await _capture("%s/%s_eye.png" % [OUTPUT_DIR, name])
	get_tree().quit()


func _ground_at(terrain: Node, at: Vector2) -> float:
	if not is_nan(_ground_override):
		return _ground_override
	return terrain.get_mesh_height(at.x, at.y)


func _capture(path: String) -> void:
	for _i in 6:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)
	print("Saved ", path)
