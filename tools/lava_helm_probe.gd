extends Node3D

## Dense head/hair coverage and rear-fold regression:
## Godot --headless --path . tools/lava_helm_probe.tscn
## Add -- --render for a front/back/side gallery in /tmp/lava_helm_review.png.
## Optional --baseline=res://path/to/renamed_previous_blorb_suit.gd compares
## a previous shell; without it both rows show the current fitted shape.
var checks := 0
var failures := 0
func check(value: bool, label: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(label)
func _ready() -> void:
	call_deferred('run')
func figure(style: String) -> Dictionary:
	var host := Node3D.new()
	add_child(host)
	return ProceduralFigure.build(host, ProceduralFigure.SKIN_COLOR, Color(0.3, 0.48, 0.65), Color(0.28, 0.25, 0.21), ProceduralFigure.SLEEVE_STYLE_SHORT, 1.0, 1.0, 1.0, 1.0, Color.TRANSPARENT, FigureHair.DEFAULT_HAIR_COLOR, style)
func examine(p: Dictionary, label: String) -> void:
	var head: Node3D = p["head"]
	var contents := BlorbSuit._measure_head_contents(head)
	var started := Time.get_ticks_usec()
	var fitted := BlorbSuit._fitted_lava_helm_contents(head, contents)
	print(label, " scale=", fitted.size.x / contents.size.x, " fit_ms=", (Time.get_ticks_usec() - started) / 1000.0)
	check(BlorbSuit._fitted_lava_helm_contents(head, contents) == fitted, label + ": fit cache is stable")
	var center := contents.get_center()
	var query_scale := contents.size.length() * 0.5
	var query_box := AABB((fitted.position - center) / query_scale, fitted.size / query_scale)
	var mesh := BlorbBodyShape.build_mesh_from_rings(BlorbSuit._build_lava_helm_rings(query_box))
	var triangle_mesh := mesh.generate_triangle_mesh()
	var misses := 0
	var samples := 0
	for descendant in head.find_children("*", "MeshInstance3D", true, false):
		var part := descendant as MeshInstance3D
		var faces := part.mesh.get_faces()
		for index in range(0, faces.size(), 3):
			var a := head.to_local(part.to_global(faces[index]))
			var b := head.to_local(part.to_global(faces[index + 1]))
			var c := head.to_local(part.to_global(faces[index + 2]))
			# Independent dense triangle grid, including points not used by
			# the fitter: vertices alone can miss a face crossing the shell.
			for u in 5:
				for v in 5 - u:
					var point := a + (b - a) * (u / 4.0) + (c - a) * (v / 4.0)
					var direction := (point - center) / query_scale
					if direction.length_squared() < 1e-12:
						continue
					var hit := triangle_mesh.intersect_ray(Vector3.ZERO, direction.normalized())
					if hit.is_empty():
						var alternate := triangle_mesh.intersect_ray(Vector3(0.00001, 0, 0), direction.normalized())
						var other := triangle_mesh.intersect_ray(Vector3(-0.00001, 0, 0), direction.normalized())
						if not alternate.is_empty() and not other.is_empty():
							hit = alternate if (alternate["position"] as Vector3).length() < (other["position"] as Vector3).length() else other
					samples += 1
					if hit.is_empty() or (hit["position"] as Vector3).length() < direction.length() * 1.001:
						misses += 1
	check(misses == 0, label + ": all %d head/hair/ear/accessory samples enclosed (%d misses)" % [samples, misses])
	var rings := BlorbSuit._build_lava_helm_rings(fitted)
	var unfolded := true
	# Only the central bend must stay monotone. Rounded lobe caps naturally
	# turn back toward their endpoints as they close.
	for index in range(16, 32):
		for segment in range(9, 24):
			if (rings[index + 1][segment] as Vector3).x < (rings[index][segment] as Vector3).x - 0.000001:
				unfolded = false
	check(unfolded, label + ": rear surface never doubles back across midline")
	var mid := int(rings.size() / 2)
	for segment in [0, 16]:
		var across: Vector3 = rings[mid + 1][segment] - rings[mid - 1][segment]
		var around: Vector3 = rings[mid][(segment + 1) % 32] - rings[mid][(segment + 31) % 32]
		check(across.cross(around).z * (1.0 if segment == 0 else -1.0) > 0.0, label + ": exterior winding")
	if label == "hero":
		check(fitted.size.x < contents.size.x * 0.95, "hero helm measurably tighter")
	p["hips"].get_parent().get_parent().free()

func run() -> void:
	for style in [FigureHair.STYLE_HERO, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_AFRO, FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_BUN, FigureHair.STYLE_PIGTAILS, FigureHair.STYLE_PONYTAIL, FigureHair.STYLE_LONG, FigureHair.STYLE_BALD]:
		examine(figure(style), style)
	for variant in [{}, JungleVillager.body_variant(1.9, 1.3)]:
		var host := Node3D.new()
		add_child(host)
		examine(MonkeyFigure.build(host, MonkeyFigure.MONKEY_FUR_COLOR, MonkeyFigure.REFERENCE_BUILD_SCALE, variant), "monkey")
	print("Lava helm: ", checks, " checks; ", failures, " failures")
	if "--render" in OS.get_cmdline_user_args():
		await gallery()
	get_tree().quit(1 if failures else 0)
func gallery() -> void:
	get_window().size = Vector2i(1500, 1100)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.15, 0.18)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.55
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -30, 0)
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 4.6
	camera.position = Vector3(0, 0, 10)
	add_child(camera)
	var p := figure(FigureHair.STYLE_HERO)
	var head: Node3D = p['head']
	var contents := BlorbSuit._measure_head_contents(head)
	var baseline: Script
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):
			baseline = load(arg.trim_prefix("--baseline="))

	for row in 2:
		for column in 3:
			var pivot := Node3D.new()
			add_child(pivot)
			var mesh := MeshInstance3D.new()
			pivot.add_child(mesh)
			var rings: Array = baseline._build_lava_helm_rings(contents) if row == 0 and baseline != null else BlorbSuit._build_lava_helm_rings(BlorbSuit._fitted_lava_helm_contents(head, contents))
			mesh.mesh = BlorbBodyShape.build_mesh_from_rings(rings)
			var material := StandardMaterial3D.new()
			material.albedo_color = Color(0.9, 0.22, 0.08)
			material.roughness = 0.55
			mesh.material_override = material
			mesh.position = -contents.get_center()
			pivot.rotation.y = [0.0, PI, PI * 0.5][column]
			pivot.position = Vector3((column - 1) * 1.5, 0.8 if row == 0 else -0.8, 0)
			var label := Label3D.new()
			label.text = ('Before' if row == 0 and baseline != null else 'Refined') + ' / ' + ['front', 'back', 'side'][column]
			label.font_size = 32
			label.pixel_size = 0.0015
			label.position = pivot.position + Vector3(0, -0.63, 0.6)
			add_child(label)
	(p["hips"].get_parent().get_parent() as Node3D).visible = false
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png('/tmp/lava_helm_review.png')
