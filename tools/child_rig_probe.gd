extends Node3D

## Godot --headless --path . tools/child_rig_probe.tscn
## Add -- --render with a graphical driver for the comparison gallery.
var failures := 0
var checks := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func make_figure(parent: Node3D, size: float, chest: float, hip: float, waist: float, child: bool, female: bool = false) -> Dictionary:
	return ProceduralFigure.build(parent, ProceduralFigure.SKIN_COLOR, Color(0.3, 0.48, 0.65), Color(0.28, 0.25, 0.21), ProceduralFigure.SLEEVE_STYLE_SHORT, size, chest, hip, waist, Color.TRANSPARENT, FigureHair.DEFAULT_HAIR_COLOR, FigureHair.STYLE_BUZZCUT, 0.0, Color(0.18, 0.13, 0.10), false, true, 1.0, true, Color.TRANSPARENT, female, child)

# Measure committed vertices in a common frame, including each part's
# asymmetric front/back offset and the torso pivot hierarchy.
func bounds_in_rig(part: MeshInstance3D, rig: Node3D) -> AABB:
	var vertices: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bounds := AABB(rig.to_local(part.to_global(vertices[0])), Vector3.ZERO)
	for vertex in vertices:
		bounds = bounds.expand(rig.to_local(part.to_global(vertex)))
	return bounds

func examine(size: float, child: bool, chest: float, hip: float, waist: float, female: bool) -> void:
	var host := Node3D.new()
	add_child(host)
	var p := make_figure(host, size, chest, hip, waist, child, female)
	var head: Node3D = p["head"]
	var upper: MeshInstance3D = p["chest"]
	var middle: MeshInstance3D = p["abdomen"]
	var label := "child=%s scale=%.2f female=%s" % [child, size, female]
	var hips: MeshInstance3D = p["hips"]
	var torso_root: Node3D = hips.get_parent()
	var chest_bounds := bounds_in_rig(upper, torso_root)
	var abdomen_bounds := bounds_in_rig(middle, torso_root)
	var hip_bounds := bounds_in_rig(hips, torso_root)
	check(hip_bounds.size.x + 0.00001 >= abdomen_bounds.size.x, label + ": hips support full abdomen width")
	check(abdomen_bounds.end.z <= chest_bounds.end.z + 0.00001, label + ": belly never passes chest front")
	check(abdomen_bounds.position.z >= chest_bounds.position.z - 0.00001, label + ": abdomen stays inside chest back")

	if child:
		check(head.scale.x > 1.0, label + ": head grows relative to body")
		check(size * head.scale.x < 1.0, label + ": absolute head remains smaller than adult")
		check(middle.mesh.get_aabb().size.x / upper.mesh.get_aabb().size.x >= 0.959, label + ": no muscular narrow waist")
		check(upper.mesh.get_aabb().size.x <= ProceduralFigure.CHEST_SIZE.x * 2.0 * 1.081, label + ": adult chest rolls softened")
	else:
		check(head.scale.is_equal_approx(Vector3.ONE), label + ": short adults keep adult head ratio")
		check(absf(upper.mesh.get_aabb().size.x - ProceduralFigure.CHEST_SIZE.x * 2.0 * chest) < 0.0001, label + ": adult build unchanged")
	# Face, ears, hair and spectacles are descendants of the same scaled
	# head. The logical skull base remains on its original neck attachment.
	check(head.position.is_equal_approx(Vector3(0, ProceduralFigure.HEAD_RAISE, 0)), label + ": head remains attached to neck")
	for eye: Node3D in p["eyes"]:
		check((eye.global_basis.x.length() / (size * head.scale.x)) > 0.1, label + ": eye inherits head scale")
	check(float(p["standing_height"]) > 0.0, label + ": resolved height available to collider")
	host.free()

func population_checks() -> void:
	var town_script = load("res://scripts/town_generator.gd")
	var children := 0
	for identity: Dictionary in town_script.VILLAGER_IDENTITIES:
		if identity.get("child", false):
			children += 1
			check(identity["name"] in ["Pip", "Tess", "Wick"], "Ohio child identity remains explicit")
	check(children == 3, "All three Ohio children receive child proportions")
	var chinese = load("res://scripts/chinese_appearance.gd")
	var npc_script = load("res://scripts/npc.gd")
	var count := 0
	for identity: String in chinese.LOOKS:
		var npc: Node = npc_script.new()
		chinese.apply(npc, identity)
		check(npc.is_child == bool(chinese.LOOKS[identity].get("child", false)), identity + ": appearance passes explicit age category")
		if npc.is_child:
			count += 1
		npc.free()
	check(count == 5, "All five authored Chinese children receive child proportions")
	# Exercise the real NPC wrapper and a wardrobe refresh, not just the builder.
	var npc: Node3D = load("res://scenes/npc.tscn").instantiate()
	npc.is_child = true
	npc.body_scale = 0.70
	npc.is_female = true
	npc.wears_dress = true
	npc.hip_build_scale = 1.6
	npc.chest_build_scale = 1.5
	npc.abdomen_width_scale = 1.0
	npc.terrain_ref = self
	npc.stationary = true
	add_child(npc)
	npc.set_physics_process(false)
	var collider := npc.get_node("CollisionShape3D") as CollisionShape3D
	var head: Node3D = npc.get("_head")
	check(head.scale.x > 1.2, "NPC wrapper uses child head proportions")
	var skirt: MeshInstance3D = npc.get("_skirt")
	var hips: MeshInstance3D = npc.get("_hips")
	var resolved_hip_scale := hips.mesh.get_aabb().size.x / (ProceduralFigure.HIP_SIZE.x * 2.0)
	check(is_equal_approx(skirt.mesh.get_aabb().size.x * 0.5, FigureDress.SKIRT_HALF_WIDTH * resolved_hip_scale), "Child dress follows widened supporting hips")
	check((collider.shape as CapsuleShape3D).height < 1.5, "Child collider no longer uses adult height")
	check(absf(collider.position.y * 2.0 - (collider.shape as CapsuleShape3D).height) < 0.00001, "Collider remains based at the feet")
	var height: float = npc.head_bounce_surface_height_at(npc.global_position.x, npc.global_position.z)
	check(absf(height - (collider.shape as CapsuleShape3D).height) < 0.00001, "Bounce surface uses resolved child height")
	var head_scale := head.scale.x
	npc.refresh_wardrobe()
	check(is_equal_approx((npc.get("_head") as Node3D).scale.x, head_scale), "Wardrobe refresh preserves child proportions")
	npc.free()

func get_mesh_height(_x: float, _z: float) -> float:
	return 0.0

func run() -> void:
	for size in [0.70, 0.76, 0.82]:
		for female in [false, true]:
			examine(size, true, 1.5, 1.4, 1.0, female)
			examine(size, true, 0.9, 0.95, 2.3, female)
	# Wide waists and asymmetric chest fronts must obey the same envelope
	# on adult bodies too; narrow adult waists retain their existing shape.
	for female in [false, true]:
		for chest in [0.8, 1.0, 1.5]:
			examine(1.0, false, chest, 0.9, 2.3, female)
	examine(1.0, false, 1.4, 1.0, 1.0, false)
	examine(0.76, false, 1.0, 1.0, 1.0, false)
	population_checks()
	print("Child rig: ", checks, " checks; ", failures, " failures")
	if "--render" in OS.get_cmdline_user_args():
		await gallery()
	get_tree().quit(1 if failures else 0)

func gallery() -> void:
	get_window().size = Vector2i(1500, 1050)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.12, 0.15, 0.18)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -25, 0)
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.0
	camera.position = Vector3(0, 2.0, 6)
	add_child(camera)
	var examples := [[1.0, 1.5, 1.0, 1.0, false, false, "Adult / muscular"], [0.70, 1.5, 1.0, 1.0, false, false, "Previous / scaled adult"], [0.70, 1.5, 1.0, 1.0, true, false, "Child / smaller boy"], [0.82, 1.5, 1.4, 1.0, true, true, "Child / taller girl"]]
	for column in examples.size():
		var e: Array = examples[column]
		for row in 2:
			var host := Node3D.new()
			add_child(host)
			host.position = Vector3((column - 1.5) * 1.35, (1 - row) * 2.2, 0)
			var p := make_figure(host, e[0], e[1], e[2], e[3], e[4], e[5])
			if row == 1:
				host.rotation.y = PI * 0.5
				(p["arm_left"] as Node3D).rotation.x = -0.4
				(p["elbow_left"] as Node3D).rotation.x = -0.5
			var label := Label3D.new()
			label.text = e[6]
			label.font_size = 32
			label.pixel_size = 0.0015
			label.position = host.position + Vector3(0, -0.13, 0.2)
			add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/child_rig_review.png")
	print("Gallery: /tmp/child_rig_review.png")
