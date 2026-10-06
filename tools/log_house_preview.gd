extends Node

## Builds sample log houses on a flat snow plane and saves three views.
##   Godot --path . --resolution 1600x1200 tools/log_house_preview.tscn
## Images land in res://wip/village_audit/.

func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.55, 0.72, 0.95)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.8, 0.85, 0.95)
	add_child(env)
	var ground := StaticBody3D.new()
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	mesh.mesh = plane
	mesh.material_override = SolidModel.material(Color(0.9, 0.93, 0.97), 0.9, 0.0)
	ground.add_child(mesh)
	add_child(ground)
	var specs: Array[Dictionary] = [
		{
			"name": "OneStorey", "cells": Vector2(3, 2), "floors": 1,
			"openings": [
				{"wall": "front", "x": 0.0, "width": 1.2, "bottom": 0.0, "top": 2.46, "kind": "door"},
				{"wall": "front", "x": -3.0, "width": 0.9, "bottom": 1.0, "top": 2.1, "kind": "window", "shutters": true},
				{"wall": "front", "x": 3.0, "width": 0.9, "bottom": 1.0, "top": 2.1, "kind": "window", "shutters": true},
				{"wall": "west", "x": 0.0, "width": 0.9, "bottom": 1.0, "top": 2.1, "kind": "window"},
				{"wall": "back", "x": 0.0, "width": 0.9, "bottom": 1.0, "top": 2.1, "kind": "window"},
			],
		},
		{
			"name": "TwoStorey", "cells": Vector2(4, 3), "floors": 2, "bellcast": true,
			"openings": [
				{"wall": "front", "x": -2.0, "width": 1.2, "bottom": 0.0, "top": 2.46, "kind": "door"},
				{"wall": "front", "x": 2.4, "width": 0.9, "bottom": 1.0, "top": 2.1, "kind": "window"},
				{"wall": "front", "x": -2.0, "width": 0.9, "bottom": 4.25, "top": 5.35, "kind": "window", "shutters": true},
				{"wall": "front", "x": 2.4, "width": 0.9, "bottom": 4.25, "top": 5.35, "kind": "window", "shutters": true},
				{"wall": "east", "x": 0.0, "width": 0.9, "bottom": 1.0, "top": 2.1, "kind": "window"},
			],
		},
	]
	var x := -12.0
	for spec in specs:
		var house := LogHouse.build(spec)
		house.position = Vector3(x, 0.0, 0.0)
		add_child(house)
		x += 18.0
	var camera := Camera3D.new()
	camera.fov = 60.0
	add_child(camera)
	camera.current = true
	var shots := {
		"front": [Vector3(-2.0, 2.6, -17.0), Vector3(-2.0, 2.8, 0.0)],
		"corner": [Vector3(-26.0, 6.0, -16.0), Vector3(-4.0, 3.0, 0.0)],
		"back": [Vector3(-4.0, 5.0, 17.0), Vector3(-4.0, 3.0, 0.0)],
	}
	for _frame in 20:
		await get_tree().process_frame
	for key: String in shots:
		camera.global_position = (shots[key] as Array)[0]
		camera.look_at((shots[key] as Array)[1], Vector3.UP)
		for _i in 6:
			await RenderingServer.frame_post_draw
		var path := "res://wip/village_audit/log_%s.png" % key
		get_viewport().get_texture().get_image().save_png(path)
		print("Saved ", path)
	get_tree().quit()
