extends Node3D

## Captures the current live Fire Kingdom build at the chamber and key surface
## junctions. Invoke with -- --shots=/absolute/output/directory.

var _output := "/tmp/fire_caldera_captures"


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):
			_output = argument.trim_prefix("--shots=")
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -32.0, 0.0)
	sun.light_energy = 1.8
	add_child(sun)
	var terrain: Node3D = (load("res://scripts/fire_kingdom_terrain.gd") as GDScript).new()
	terrain.name = "Terrain"
	add_child(terrain)
	var village: Node3D = (load("res://scripts/fire_kingdom_village.gd") as GDScript).new()
	village.name = "CalderaVillage"
	add_child(village)
	print("capture: live terrain build started")
	_capture.call_deferred()


func _capture() -> void:
	for _i in 8:
		await get_tree().process_frame
	print("capture: configuring cameras")
	var terrain := get_node("Terrain")
	var frame := terrain.get_node("CalderaCityGround") as Node3D
	var camera := Camera3D.new()
	camera.name = "CalderaProofCamera"
	camera.fov = 72.0
	camera.far = 700.0
	add_child(camera)
	camera.current = true
	DirAccess.make_dir_recursive_absolute(_output)
	var shots := {
		"heartworks_chamber": [Vector3(18.0, -8.0, 28.0), Vector3(0.0, -11.0, 0.0)],
		"gate_arrival_gallery": [Vector3(28.0, 61.0, -132.0), Vector3(8.0, 44.0, -115.0)],
		"renewal_horseshoe_junction": [Vector3(-44.0, 52.0, 9.0), Vector3(-58.7, 39.0, -4.0)],
		"highline_and_promenade": [Vector3(12.0, 68.0, 99.0), Vector3(0.0, 42.5, 68.0)],
	}
	for name: String in shots:
		var pose: Array = shots[name]
		camera.global_position = frame.global_transform * (pose[0] as Vector3)
		camera.look_at(frame.global_transform * (pose[1] as Vector3), Vector3.UP)
		await get_tree().process_frame
		var path := "%s/%s.png" % [_output, name]
		var texture := get_viewport().get_texture()
		if texture == null:
			push_error("capture requires a window renderer; headless mode has no viewport texture")
			get_tree().quit(1)
			return
		var image := texture.get_image()
		var error := image.save_png(path) if image.get_width() > 0 else ERR_CANT_CREATE
		print(("saved " if error == OK else "FAIL ") + path)
	get_tree().quit()
