extends Node3D

## Regression scene plus optional visual gallery:
## Godot --headless --path . tools/monkey_rig_probe.tscn
## Godot --path . tools/monkey_rig_probe.tscn -- --render
## Optional --baseline=/absolute/path/to/renamed_original_monkey_script.gd
class SuitSample extends Blorb:
	func body_visual_snapshot() -> Dictionary:
		return {"albedo": Color(0.35, 0.7, 0.9), "roughness": 0.7, "metallic": 0.0,
			"emission_enabled": false, "emission": Color.BLACK, "emission_energy": 0.0,
			"core_color": Color(0.2, 0.8, 0.6), "core_emissive": false,
			"core_emission": Color.BLACK, "core_emission_energy": 0.0,
			"has_light": false, "light_color": Color.WHITE}

var failures := 0
var checks := 0
var sample := SuitSample.new()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		if failures <= 8:
			push_error(message)

func _ready() -> void:
	call_deferred("run")

func mesh_vertices(mesh: MeshInstance3D) -> PackedVector3Array:
	return mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

# At rest the rear surface must keep facing backward as it rounds into
# the sole. A forward-facing patch here is the heel folding over itself.
func unfolded_heel(mesh: MeshInstance3D, knee: Vector3, ankle: Vector3) -> bool:
	var arrays := mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for triangle in range(0, vertices.size(), 3):
		var a := vertices[triangle]
		var b := vertices[triangle + 1]
		var c := vertices[triangle + 2]
		var center := (a + b + c) / 3.0
		if center.y >= knee.y or center.z >= ankle.z - 0.004:
			continue
		var outward := (c - a).cross(b - a)
		if outward.length_squared() > 1e-18 and outward.normalized().z > 0.001:
			return false
	return true

func nearest(mesh: MeshInstance3D, point: Vector3) -> float:
	var distance := INF
	for vertex in mesh_vertices(mesh):
		distance = minf(distance, vertex.distance_to(point))
	return distance

func nearest_edge(mesh: MeshInstance3D, point: Vector3) -> float:
	var distance := INF
	var vertices := mesh_vertices(mesh)
	for triangle in range(0, vertices.size(), 3):
		for edge in 3:
			var closest := Geometry3D.get_closest_point_to_segment(point, vertices[triangle + edge], vertices[triangle + (edge + 1) % 3])
			distance = minf(distance, point.distance_to(closest))
	return distance

func valid_mesh(mesh: MeshInstance3D) -> bool:
	for vertex in mesh_vertices(mesh):
		if not vertex.is_finite():
			return false
	return true

func suit_arm(p: Dictionary, root: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	root.add_child(mesh)
	BlorbSuit.rebuild_arm(mesh, root, p["arm_left"], p["elbow_left"], p["wrist_left"], p["fingertip_left"], p["back_left"], sample, 0.245, false, PlayableCharacterProfile.xiao_hou_zi().suit_limb_fit)
	return mesh

func suit_leg(p: Dictionary, root: Node3D) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	root.add_child(mesh)
	BlorbSuit.rebuild_leg(mesh, root, p["leg_left"], p["knee_left"], p["ankle_left"], p["toe_left"], sample, 0.245, false, false, PlayableCharacterProfile.xiao_hou_zi().suit_limb_fit)
	return mesh

func inside_torso(p: Dictionary, root_point: Vector3, variant: Dictionary) -> bool:
	var rig: Node3D = p["_rig"]
	var spine: Node3D = p["spine"]
	var local := spine.to_local(rig.to_global(root_point))
	var height := MonkeyFigure.BODY_HEIGHT * float(variant.get("body_height_scale", 1.0))
	var radius := MonkeyFigure.BODY_RADIUS * float(variant.get("body_radius_scale", 1.0)) * BlorbBodyShape.profile_radius(local.y / height, float(variant.get("body_taper_blend", 1.0)))
	return local.y >= 0.0 and local.y <= height and Vector2(local.x, local.z).length() < radius + 0.0001

func socket_covered(p: Dictionary, centre: Vector3, tangent: Vector3, radius: float, variant: Dictionary) -> bool:
	var basis := BlorbSuit._ring_basis(tangent)
	for vertex in BlorbSuit._build_ring(centre, basis.x, basis.y, radius, 32):
		if not inside_torso(p, vertex, variant):
			return false
	return true

func examine(variant: Dictionary, scale_factor: float, label: String) -> void:
	var host := Node3D.new()
	add_child(host)
	var p := MonkeyFigure.build(host, MonkeyFigure.MONKEY_FUR_COLOR, scale_factor, variant)
	var root: Node3D = p["_rig"]
	var arm: MeshInstance3D = p["_limb_mesh_arm_left"]
	var leg: MeshInstance3D = p["_limb_mesh_leg_left"]
	var hip: Node3D = p["leg_left"]
	var knee: Node3D = p["knee_left"]
	var ankle: Node3D = p["ankle_left"]
	check(unfolded_heel(leg, root.to_local(knee.global_position), root.to_local(ankle.global_position)), label + ": resting heel has no folded surface")
	check(absf(hip.global_position.distance_to(knee.global_position) - knee.global_position.distance_to(ankle.global_position)) < 0.00001, label + ": balanced hidden knee")
	var shoulder_profile := MonkeyFigure.suit_arm_profile(root, p["arm_left"], p["elbow_left"], p["wrist_left"], p["fingertip_left"])
	var shoulder_points: Array = shoulder_profile["points"]
	check(socket_covered(p, shoulder_points[1], (shoulder_points[2] as Vector3) - (shoulder_points[0] as Vector3), (shoulder_profile["radii"] as Array)[1], variant), label + ": shoulder root fully buried in actual torso")
	check(socket_covered(p, root.to_local(hip.global_position), knee.position, MonkeyFigure.LEG_RADIUS_HIP * float(variant.get("leg_radius_scale", 1.0)), variant), label + ": hip root fully buried in actual torso")
	var bone_length := 0.0
	for pair in [["arm_left", "elbow_left"], ["elbow_left", "wrist_left"], ["wrist_left", "fingertip_left"]]:
		bone_length += (p[pair[0]] as Node3D).global_position.distance_to((p[pair[1]] as Node3D).global_position)
	check(absf(bone_length - 0.07 * scale_factor * float(variant.get("limb_length_scale", 1.0))) < 0.00001, label + ": wrist preserves authored arm length")
	# The visible foot must reach its toe and sole, with no extra toe below
	# that sole. Check actual vertices, rather than only repeating formulas.
	var minimum_y := INF
	for vertex in mesh_vertices(leg):
		minimum_y = minf(minimum_y, vertex.y)
	print(label, " foot minimum=", minimum_y)
	check(minimum_y >= -0.001, label + ": no geometry bulb below sole")
	check(nearest_edge(leg, root.to_local((p["sole_left"] as Node3D).global_position)) < 0.001, label + ": sole describes actual surface")
	for phase in [0.0, PI * 0.5, PI, PI * 1.5]:
		MonkeyGait.pose(p, phase, true, 1.0, 0.55, 8.0)
		MonkeyFigure.rebuild_limbs(p, host)
		check(valid_mesh(arm) and valid_mesh(leg), label + ": valid bent meshes")
		check(nearest(arm, root.to_local((p["fingertip_left"] as Node3D).global_position)) < 0.00001, label + ": arm stops at fingertip")
		check(nearest_edge(leg, root.to_local((p["toe_left"] as Node3D).global_position)) < 0.001, label + ": foot stops at toe")
		var arm_shell := suit_arm(p, host)
		var leg_shell := suit_leg(p, host)
		check(valid_mesh(arm_shell) and valid_mesh(leg_shell), label + ": valid outer shells in world units")
		face_fits(arm_shell, label + " arm")
		face_fits(leg_shell, label + " foot")
		var core := leg_shell.get_node("Core") as Node3D
		var foot_up := (host.global_basis.inverse() * ankle.global_basis).y.normalized()
		check((core.position - host.to_local(ankle.global_position)).dot(foot_up) > 0.0, label + ": core above foot, not below sole")
		var ap := MonkeyFigure.suit_arm_profile(host, p["arm_left"], p["elbow_left"], p["wrist_left"], p["fingertip_left"])
		var lp := MonkeyFigure.suit_leg_profile(host, knee, ankle)
		var arm_end: Vector3 = (ap["points"] as Array).back() + (ap["tip_direction"] as Vector3) * float((ap["radii"] as Array).back()) * 1.14
		var leg_end: Vector3 = (lp["stations"] as Array).back() + (lp["tip_direction"] as Vector3) * float((lp["radii"] as Array).back()) * 1.14
		check(nearest(arm_shell, arm_end) < 0.00001, label + ": suit follows live arm dimensions")
		check(nearest(leg_shell, leg_end) < 0.00001, label + ": suit follows live foot dimensions")
		arm_shell.free()
		leg_shell.free()
	# Coordinated gait bends the leading elbow more, and the recovering knee.
	MonkeyGait.pose(p, PI * 0.5, true, 1.0, 0.55, 8.0)
	check((p["elbow_left"] as Node3D).rotation.x < (p["elbow_right"] as Node3D).rotation.x - 0.5, label + ": forward arm flexes")
	MonkeyGait.pose(p, 0.0, true, 1.0, 0.55, 8.0)
	check((p["knee_right"] as Node3D).rotation.x > 0.5, label + ": recovery knee flexes")
	(p["head"] as Node3D).rotation.y = 0.3
	MonkeyGait.pose(p, 0.0, false, 1.0, 0.55, 8.0)
	check(absf((p["arm_left"] as Node3D).rotation.x - float(-variant.get("spine_forward_bend", 0.0)) * (1.0 + float(variant.get("arm_forward_relax_factor", 0.0)))) < 0.00001, label + ": rest shoulder preserves posture")
	check(is_equal_approx((p["head"] as Node3D).rotation.y, 0.3), label + ": gaze retains yaw")
	host.free()

func inside_mesh(mesh: MeshInstance3D, point: Vector3) -> bool:
	var faces := mesh.mesh.get_faces()
	var direction := Vector3(0.217, 0.413, 0.884).normalized()
	var distances: Array[float] = []
	for triangle in range(0, faces.size(), 3):
		var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3.ZERO, direction, (faces[triangle] - point) * 1000.0, (faces[triangle + 1] - point) * 1000.0, (faces[triangle + 2] - point) * 1000.0)
		if hit != null:
			distances.append((hit as Vector3).length() / 1000.0)
	distances.sort()
	var count := 0
	var previous := -1.0
	for distance in distances:
		if absf(distance - previous) > 0.000001:
			count += 1
			previous = distance
	return count % 2 == 1

func face_fits(mesh: MeshInstance3D, label: String) -> void:
	var core := mesh.get_node("Core") as MeshInstance3D
	check(core.visible and inside_mesh(mesh, core.position), label + ": core centre inside suit")
	var all_inside := true
	var vertices: PackedVector3Array = core.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	for index in range(0, vertices.size(), 18):
		if not inside_mesh(mesh, core.transform * vertices[index]):
			all_inside = false
	check(all_inside, label + ": entire core remains inside bent skin")
	for name in ["EyeL", "EyeR"]:
		var eye := mesh.get_node(name) as MeshInstance3D
		check(eye.visible and eye.has_meta("skin_point"), label + ": " + name + " finds actual skin")
		if not eye.visible or not eye.has_meta("skin_point"):
			continue
		var normal: Vector3 = eye.get_meta("skin_normal")
		var surface: Vector3 = eye.position + normal * float(eye.get_meta("skin_embed"))
		# Independently intersect the committed mesh triangles, not the ring
		# query cache used to attach the eyes in production.
		var hit_distance := INF
		var reach := eye.mesh.get_aabb().size.x * 2.0
		var origin := surface + normal * reach
		var faces := mesh.mesh.get_faces()
		for triangle in range(0, faces.size(), 3):
			var hit: Variant = Geometry3D.ray_intersects_triangle(Vector3.ZERO, -normal, (faces[triangle] - origin) * 1000.0, (faces[triangle + 1] - origin) * 1000.0, (faces[triangle + 2] - origin) * 1000.0)
			if hit != null:
				hit_distance = minf(hit_distance, (hit as Vector3).length() / 1000.0)
		check(absf(hit_distance - reach) < 0.00001, label + ": " + name + " anchored on rendered triangle")

func human_surface_checks() -> void:
	var host := Node3D.new()
	add_child(host)
	var p := ProceduralFigure.build(host)
	var arm := MeshInstance3D.new()
	var leg := MeshInstance3D.new()
	host.add_child(arm)
	host.add_child(leg)
	var poses := [Vector3(0, -0.2, 0), Vector3(-PI * 0.5, -0.7, 0.4), Vector3(-2.5, -1.6, -0.8), Vector3(0, -2.3, 0.7), Vector3(0.8, -0.7, -0.5), Vector3(0, -0.2, 0)]
	var first_eye := Vector3.ZERO
	for index in poses.size():
		var pose: Vector3 = poses[index]
		(p["arm_left"] as Node3D).rotation.x = pose.x
		(p["elbow_left"] as Node3D).rotation.x = pose.y
		(p["hand_left"] as Node3D).rotation.y = pose.z
		(p["ankle_left"] as Node3D).rotation.x = pose.z * 0.5
		BlorbSuit.rebuild_arm(arm, host, p["arm_left"], p["elbow_left"], p["wrist_left"], p["fingertip_left"], p["back_left"], sample)
		BlorbSuit.rebuild_leg(leg, host, p["leg_left"], p["knee_left"], p["ankle_left"], p["toe_left"], sample)
		face_fits(arm, "Human arm pose " + str(index))
		face_fits(leg, "Human foot pose " + str(index))
		var foot_up := (p["ankle_left"] as Node3D).global_basis.y.normalized()
		check(((leg.get_node("Core") as Node3D).position - host.to_local((p["ankle_left"] as Node3D).global_position)).dot(foot_up) > 0.0, "Human core above foot in pose " + str(index))
		if index == 0:
			first_eye = (arm.get_node("EyeL") as Node3D).position
		elif index == poses.size() - 1:
			check((arm.get_node("EyeL") as Node3D).position.is_equal_approx(first_eye), "Repeated arm motion has no eye drift")
	host.free()

func run() -> void:
	check(load("res://scripts/player.gd").can_instantiate(), "Human controller compiles")
	check(load("res://scripts/xiao_hou_zi.gd").can_instantiate(), "Monkey controller compiles")
	examine({}, MonkeyFigure.REFERENCE_BUILD_SCALE, "Xiao Hou Zi")
	for limb in [JungleVillager.LIMB_LENGTH_SCALE_MIN, JungleVillager.LIMB_LENGTH_SCALE_MAX]:
		for scale_factor in [JungleVillager.DISPLAY_SCALE_MIN, JungleVillager.DISPLAY_SCALE_MAX]:
			for tail in [JungleVillager.TAIL_LENGTH_SCALE_MIN, JungleVillager.TAIL_LENGTH_SCALE_MAX]:
				examine(JungleVillager.body_variant(limb, tail), scale_factor, "Villager %.2f/%.2f/%.2f" % [limb, scale_factor, tail])
	human_surface_checks()
	print("Monkey rig: ", checks, " checks; ", failures, " failures")
	if "--benchmark" in OS.get_cmdline_user_args():
		benchmark()
	if "--detail" in OS.get_cmdline_user_args():
		await attachment_gallery()
	elif "--render" in OS.get_cmdline_user_args():
		await gallery()
	sample.free()
	get_tree().quit(1 if failures else 0)

func benchmark() -> void:
	var host := Node3D.new()
	add_child(host)
	var p := ProceduralFigure.build(host)
	var arm := MeshInstance3D.new()
	var leg := MeshInstance3D.new()
	host.add_child(arm)
	host.add_child(leg)
	var started := Time.get_ticks_usec()
	for frame in 60:
		(p["elbow_left"] as Node3D).rotation.x = -1.0 - sin(frame * 0.1)
		BlorbSuit.rebuild_arm(arm, host, p["arm_left"], p["elbow_left"], p["wrist_left"], p["fingertip_left"], p["back_left"], sample)
		BlorbSuit.rebuild_leg(leg, host, p["leg_left"], p["knee_left"], p["ankle_left"], p["toe_left"], sample)
	print("Human arm + foot rebuild incl. surface fitting: ", (Time.get_ticks_usec() - started) / 60000.0, " ms/pair")
	host.free()

func gallery() -> void:
	get_window().size = Vector2i(1536, 2048)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.12, 0.15, 0.18)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35, -25, 0)
	light.light_energy = 1.3
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.7
	camera.position = Vector3(0, 2.65, 5)
	add_child(camera)
	camera.look_at(Vector3(0, 2.65, 0))
	var baseline: Script
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--baseline="):
			baseline = load(arg.trim_prefix("--baseline="))
	for column in 4:
		var variant := {} if column == 0 else JungleVillager.body_variant(lerpf(1.6, 1.9, (column - 1) / 2.0), 1.0)
		var size := MonkeyFigure.REFERENCE_BUILD_SCALE if column == 0 else lerpf(2.55, 3.15, (column - 1) / 2.0)
		for row in 5:
			var host := Node3D.new()
			add_child(host)
			host.position = Vector3((column - 1.5) * 0.8, (4 - row) * 1.1, 0)
			var p: Dictionary = baseline.build(host, MonkeyFigure.MONKEY_FUR_COLOR, size, variant) if baseline != null else MonkeyFigure.build(host, MonkeyFigure.MONKEY_FUR_COLOR, size, variant)
			if row == 1:
				host.rotation.y = PI * 0.5
			elif row == 2 or row == 3:
				if baseline == null:
					MonkeyGait.pose(p, PI * 0.5 if row == 2 else 0.0, true, 1.0, 0.55, 8.0)
					MonkeyFigure.rebuild_limbs(p, host)
				else:
					(p["leg_left"] as Node3D).rotation.x = 0.55
					(p["leg_right"] as Node3D).rotation.x = -0.55
					(p["arm_left"] as Node3D).rotation.x = -0.55
					(p["arm_right"] as Node3D).rotation.x = 0.55
					baseline.rebuild_limbs(p, host)
				host.rotation.y = PI * 0.33
			if row == 4 and baseline == null:
				suit_arm(p, host)
				suit_leg(p, host)
			var label := Label3D.new()
			label.text = ("Xiao Hou Zi" if column == 0 else ["Villager: small", "Villager: middle", "Villager: tall"][column - 1]) + [" / front", " / side", " / stride", " / recovery", " / left suit limbs"][row]
			label.font_size = 32
			label.pixel_size = 0.0012
			label.position = host.position + Vector3(0, -0.07, 0.2)
			add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var path := "/tmp/monkey_before.png" if baseline != null else "/tmp/monkey_after.png"
	get_viewport().get_texture().get_image().save_png(path)
	print("Gallery: ", path)


func attachment_gallery() -> void:
	get_window().size = Vector2i(1400, 1000)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.12, 0.15, 0.18)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.8
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-30, -20, 0)
	add_child(light)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.2
	camera.position = Vector3(0, 0.55, 4)
	add_child(camera)
	for column in 4:
		for row in 2:
			var host := Node3D.new()
			add_child(host)
			var human := column < 2
			var bent := column % 2 == 1
			var p := ProceduralFigure.build(host) if human else MonkeyFigure.build(host, MonkeyFigure.MONKEY_FUR_COLOR, 2.3585)
			if bent:
				(p["elbow_left"] as Node3D).rotation.x = -2.0
				(p["hand_left"] as Node3D).rotation.y = -0.6
				(p["ankle_left"] as Node3D).rotation.x = 0.5
			for mesh: MeshInstance3D in host.find_children("*", "MeshInstance3D", true, false):
				mesh.visible = false
			var shell := MeshInstance3D.new()
			host.add_child(shell)
			var fit := {} if human else PlayableCharacterProfile.xiao_hou_zi().suit_limb_fit
			var size := 1.0 if human else 0.245
			if row == 0:
				BlorbSuit.rebuild_arm(shell, host, p["arm_left"], p["elbow_left"], p["wrist_left"], p["fingertip_left"], p["back_left"], sample, size, false, fit)
			else:
				BlorbSuit.rebuild_leg(shell, host, p["leg_left"], p["knee_left"], p["ankle_left"], p["toe_left"], sample, size, false, false, fit)
			# Inspection-only transparency exposes the fitted core; production
			# keeps the wearer's own blorb material and opacity unchanged.
			var material := shell.get_surface_override_material(0) as StandardMaterial3D
			material.albedo_color.a = 0.35
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var centre := shell.mesh.get_aabb().get_center()
			var factor := 0.75 if human else 2.8
			shell.scale = Vector3.ONE * factor
			shell.position = -centre * factor
			host.position = Vector3((column - 1.5) * 0.65, (1 - row) * 0.85, 0)
			if row == 0:
				host.rotation.y = -PI * 0.5
			else:
				host.rotation.x = 0.15
			var label := Label3D.new()
			label.text = ("Human" if human else "Monkey") + (" / bent" if bent else " / rest") + (" arm" if row == 0 else " foot")
			label.pixel_size = 0.0012
			label.font_size = 28
			label.position = host.position + Vector3(0, -0.36, 0.1)
			add_child(label)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("/tmp/suit_attachments.png")
	print("Attachment gallery: /tmp/suit_attachments.png (inspection transparency)")
