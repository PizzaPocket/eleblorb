extends Node3D

## Isolated specimen review; no world staging required.
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1800,850))
	var environment := WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(0.73,0.82,0.86)
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color(0.8,0.86,0.9)
	environment.environment.ambient_light_energy=0.65
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-42,-28,0)
	sun.shadow_enabled=true
	sun.light_energy=1.2
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size=Vector2(200,200)
	ground.mesh=plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(0.62,0.63,0.53)
	ground.material_override=mat
	add_child(ground)
	for i in 4:
		var pine := NatureProps.build_chinese_pine(4.2,41+i)
		pine.position=Vector3((float(i)-1.5)*5.4,0,0)
		add_child(pine)
	var camera := Camera3D.new()
	camera.position=Vector3(8,6.5,22)
	camera.look_at_from_position(camera.position,Vector3(0,2.1,0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=9.5
	add_child(camera)
	camera.make_current()
	for child in get_tree().root.get_children():
		if child is CanvasLayer: child.visible=false
	for i in 24: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://wip/tree_audit"))
	get_viewport().get_texture().get_image().save_png("res://wip/tree_audit/chinese_pine_variants.png")
	print("Saved four Chinese pine specimens, seeds 41–44")
	get_tree().quit()
