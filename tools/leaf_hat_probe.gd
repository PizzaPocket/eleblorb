extends Node3D

## Actual worn-head coverage and closed-vine continuity:
## Godot --headless --path . tools/leaf_hat_probe.tscn
## Add -- --render for actual human/monkey portraits and leaf top views,
## saved to /tmp/leaf_hat_review.png.
var checks := 0
var failures := 0
var sample: Blorb
class Sample extends Blorb:
	func body_visual_snapshot() -> Dictionary:
		return {"albedo": Color(0.18, 0.62, 0.22), "roughness": 0.7, "metallic": 0.0, "emission_enabled": false, "emission": Color.BLACK, "emission_energy": 0.0, "core_color": Color(0.2, 0.8, 0.6), "core_emissive": false, "core_emission": Color.BLACK, "core_emission_energy": 0.0, "has_light": false, "light_color": Color.WHITE}
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
	var head: Node3D = p['head']
	var contents := BlorbSuit._measure_head_contents(head)
	var geometry: Array[Dictionary] = []
	for part: MeshInstance3D in head.find_children('*', 'MeshInstance3D', true, false):
		geometry.append({'transform': head.global_transform.affine_inverse() * part.global_transform, 'faces': part.mesh.get_faces()})
	var hat := BlorbSuit._build_leaf_hat(head, contents, head.get_meta("blorb_suit_head_size", ProceduralFigure.HEAD_SIZE), sample.body_visual_snapshot())
	hat.set_meta('blorb_suit_piece', true)
	if label == 'monkey':
		var dimensions: Vector3 = hat.get_meta('leaf_dimensions')
		check(dimensions.x < contents.size.x * 0.72, 'monkey: crown-sized leaf no longer spans the old ear/muzzle envelope')
	var leaf: MeshInstance3D = hat.get_node('CurvedLeaf')
	# Query the actual triangulated underside at unit scale, using a dense
	# grid of points over every real skull/hair/accessory triangle.
	var factor := contents.size.length()
	var faces := leaf.mesh.get_faces()
	for index in faces.size():
		faces[index] /= factor
	var leaf_bottom := leaf.mesh.get_aabb().position.y / factor
	var triangles := TriangleMesh.new()
	triangles.create_from_faces(faces)
	var missed := 0
	var clipped := 0
	var total := 0
	for entry in geometry:
		var raw: PackedVector3Array = entry['faces']
		var transform: Transform3D = entry['transform']
		for triangle in range(0, raw.size(), 3):
			var a := transform * raw[triangle]
			var b := transform * raw[triangle + 1]
			var c := transform * raw[triangle + 2]
			for u in 4:
				for v in 4 - u:
					var point := (a + (b - a) * (u / 3.0) + (c - a) * (v / 3.0) - hat.position) / factor
					var hit := triangles.intersect_ray(Vector3(point.x, -3.0, point.z), Vector3.UP)
					if hit.is_empty():
						# Shared-edge rays can need a tiny horizontal perturbation.
						hit = triangles.intersect_ray(Vector3(point.x + 0.00001, -3.0, point.z + 0.00001), Vector3.UP)
					total += 1
					if hit.is_empty():
						if point.y >= leaf_bottom:
							missed += 1
					elif (hit['position'] as Vector3).y <= point.y:
						clipped += 1
	check(missed == 0, label + ': crown coverage; exposed low ears stay below leaf (%d misses)' % missed)
	check(clipped == 0, label + ': no skull/hair/accessory pokes through leaf (%d clips)' % clipped)
	check(hat.find_children('SecuringVine', 'MeshInstance3D', true, false).size() == 1, label + ': crown and chin strap are one mesh')
	var vine: MeshInstance3D = hat.get_node('SecuringVine')
	var vine_arrays := vine.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = vine_arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = vine_arrays[Mesh.ARRAY_NORMAL]
	var unique: Dictionary = {}
	var continuous := true
	for index in vertices.size():
		if unique.has(vertices[index]) and normals[index].dot(unique[vertices[index]]) < 0.999:
			continuous = false
		unique[vertices[index]] = normals[index]
	check(continuous, label + ': closed vine has continuous seam normals')
	print(label, ': ', total, ' actual head surface samples; ', missed, ' misses; ', clipped, ' clips')
	p['hips'].get_parent().get_parent().free()
func run() -> void:
	sample = Sample.new()
	for style in [FigureHair.STYLE_HERO, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_AFRO, FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_BUN, FigureHair.STYLE_PIGTAILS, FigureHair.STYLE_PONYTAIL, FigureHair.STYLE_LONG, FigureHair.STYLE_BALD]:
		examine(figure(style), style)
	for variant in [{}, JungleVillager.body_variant(1.9, 1.3)]:
		var host := Node3D.new()
		add_child(host)
		examine(MonkeyFigure.build(host, MonkeyFigure.MONKEY_FUR_COLOR, MonkeyFigure.REFERENCE_BUILD_SCALE, variant), 'monkey')
	print('Leaf hat: ', checks, ' checks; ', failures, ' failures')
	if '--render' in OS.get_cmdline_user_args():
		await gallery()
	sample.free()
	get_tree().quit(1 if failures else 0)
func gallery() -> void:
	get_window().size = Vector2i(1800, 1200)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.12, 0.15, 0.18)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -30, 0)
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.2
	camera.position = Vector3(0, 0.1, 6)
	add_child(camera)
	for row in 2:
		for column in 4:
			var p: Dictionary
			var name: String
			if column == 3:
				var host := Node3D.new()
				add_child(host)
				p = MonkeyFigure.build(host)
				name = 'Xiao Hou Zi'
			else:
				var style: String = FigureHair.STYLE_HERO if row == 0 else [FigureHair.STYLE_AFRO, FigureHair.STYLE_BUN, FigureHair.STYLE_PIGTAILS][column]
				p = figure(style)
				name = style.capitalize()
			var head: Node3D = p['head']
			var contents := BlorbSuit._measure_head_contents(head)
			BlorbSuit._build_leaf_hat(head, contents, head.get_meta("blorb_suit_head_size", ProceduralFigure.HEAD_SIZE), sample.body_visual_snapshot())
			var original: Node3D = p['hips'].get_parent().get_parent()
			var portrait := Node3D.new()
			add_child(portrait)
			head.reparent(portrait, false)
			head.position = -contents.get_center()
			original.free()
			portrait.scale = Vector3.ONE * 0.66 / contents.size.y
			portrait.rotation.y = [0.0, PI * 0.25, PI * 0.5, PI * 0.2][column]
			if row == 1:
				portrait.rotation.x = 0.55
			portrait.position = Vector3((column - 1.5) * 1.3, 0.75 if row == 0 else -0.75, 0)
			var label := Label3D.new()
			label.text = name + (' / top detail' if row == 1 else [' / front', ' / angled', ' / side', ' / angled'][column])
			label.font_size = 32
			label.pixel_size = 0.0012
			label.position = portrait.position + Vector3(0, -0.62, 0.4)
			add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png('/tmp/leaf_hat_review.png')
