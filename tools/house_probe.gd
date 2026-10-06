extends Node

## Prints a building's clear zones and bed poses in its own frame, to debug
## furniture placement. Usage: ... tools/house_probe.tscn -- --house=SallowWardenCottage

func _ready() -> void:
	var name_arg := "SallowWardenCottage"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--house="):
			name_arg = arg.substr(8)
	var world := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 10:
		await get_tree().process_frame
	var house := world.get_node("Town").find_child(name_arg, true, false) as Node3D
	print("house ", name_arg, " rot ", house.rotation.y, " pos ", house.global_position)
	for zone: Dictionary in house.get_meta(ClearZones.ZONES_META, []):
		print("zone ", zone["label"], " kind ", zone["kind"], " centre ", zone["center"], " dir ", zone["dir"], " y ", zone["y0"], "..", zone["y1"])
	for child in house.get_children():
		if child is StaticBody3D and child.has_meta(ClearZones.FURNITURE_META):
			print("bed at local ", child.position, " yaw ", child.rotation.y)
	print("failures ", house.get_meta("layout_failures", []))
	get_tree().quit()
