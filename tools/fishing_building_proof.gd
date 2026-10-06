extends Node3D

## Isolated proof for one fishing-village building (the architecture skill's
## step 5: review a subsystem without staging the whole world). Builds the
## structure from FishingBuildings over a flat stand-in lake with the arrival
## landing's deck for scale, then audits it:
##   - every solid visual has its collider (CollisionPolicy.validate_body);
##   - furniture clear of doors, windows and fires, routes walkable
##     (ClearZones.audit) and no wall standing in a void (audit_stacking);
##   - every pile stands on a shelf (FishingVillagePlan.shelf_distance).
## Headless, it audits and quits. With a window it also saves renders: aerial,
## approach, eye level at the counter, the front, the north side and a roofless
## cutaway of the rooms.
##
##   Godot --headless --path . tools/fishing_building_proof.tscn -- --building=VennHouse
##   Godot --path . tools/fishing_building_proof.tscn -- --building=VennHouse --shots=/abs/dir

var _failures := 0
var _building := "VennHouse"
var _shots := ""


func _ready() -> void:
	get_tree().create_timer(120.0).timeout.connect(func() -> void:
		print("FAIL proof watchdog: did not finish in 120 s")
		get_tree().quit(2))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--building="):
			_building = argument.get_slice("=", 1)
		elif argument.begins_with("--shots="):
			_shots = argument.get_slice("=", 1)
	_stage()
	var body := FishingBuildings.build(_building)
	if body == null:
		print("FAIL no builder for %s" % _building)
		get_tree().quit(1)
		return
	add_child(body)
	var anchor := FishingBuildings.anchor(_building)
	body.position = Vector3(anchor.x, 0.0, anchor.y)
	if _building == "VennHouse":
		FishingBuildings.lay_out_wares(body, (body.get_node("WaresCounter") as Node3D).position, 2.6)
	for _i in 6:
		await get_tree().physics_frame
	_audit(body, anchor)
	if _shots != "" and DisplayServer.get_name() != "headless":
		await _render(body, anchor)
	print("---- fishing_building_proof %s: %d FAIL" % [_building, _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _audit(body: StaticBody3D, anchor: Vector2) -> void:
	for node in [body] + body.find_children("*", "StaticBody3D", true, false):
		if not CollisionPolicy.validate_body(node as StaticBody3D):
			_fail("%s: visuals and colliders do not pair" % node.name)
	for problem in ClearZones.audit(self):
		_fail(problem)
	for problem in ClearZones.audit_stacking(self):
		_fail(problem)
	var piles := 0
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		# Piles are the only parts reaching below the shelf top.
		if mesh.position.y < -1.0 and mesh.get_parent() == body:
			piles += 1
			var plan := anchor + Vector2(mesh.position.x, mesh.position.z)
			if FishingVillagePlan.shelf_distance(plan) > -0.2:
				_fail("pile at plan (%.1f, %.1f) is not on a shelf" % [plan.x, plan.y])
	print("ok   %s: %d piles, %d colliders" % [_building, piles, body.find_children("*", "CollisionShape3D", true, false).size()])


## The stand-in lake, light and sky, and the arrival landing for scale.
func _stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.62, 0.78, 0.90)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.78, 0.82)
	environment.ambient_light_energy = 0.55
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -35.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200.0, 200.0)
	water.mesh = plane
	water.material_override = SolidModel.material(Color(0.16, 0.38, 0.46), 0.2, 0.0)
	water.position = Vector3(0.0, -0.02, 0.0)
	add_child(water)
	for structure in FishingVillagePlan.STRUCTURES:
		if structure["name"] == "ArrivalLanding":
			var rect: Rect2 = structure["rect"]
			var deck := StaticBody3D.new()
			deck.name = "ArrivalLandingStandIn"
			add_child(deck)
			StiltKit.floor_slab(deck, rect, FishingVillagePlan.DECK_TOP)


func _render(body: StaticBody3D, anchor: Vector2) -> void:
	DirAccess.make_dir_recursive_absolute(_shots)
	var camera := Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 60.0
	var c := Vector3(anchor.x, 1.5, anchor.y)
	var views := {
		"aerial": [c + Vector3(-14, 16, 18), c],
		"approach": [c + Vector3(-9, 2.2, 13), c + Vector3(0, 1.8, 0)],
		"counter_eye": [c + Vector3(-2.0, 2.1, 9.5), c + Vector3(-3.0, 1.5, 3.0)],
		"front": [c + Vector3(2, 2.0, 14), c + Vector3(0, 1.8, 0)],
		"north_side": [c + Vector3(10, 5, -12), c],
		"east_side": [c + Vector3(14, 3, 3), c],
	}
	for view: String in views:
		var pair: Array = views[view]
		camera.global_position = pair[0]
		camera.look_at(pair[1], Vector3.UP)
		await _capture("%s/%s_%s.png" % [_shots, _building, view])
	# Cutaway: hide everything above the ring beam to read the rooms as a plan.
	var cut_y := FishingBuildings.HOUSE_FLOOR + 2.9
	var hidden: Array[Node3D] = []
	for node in body.find_children("*", "Node3D", true, false):
		var spatial := node as Node3D
		if (spatial is GeometryInstance3D) and spatial.global_position.y > cut_y:
			spatial.visible = false
			hidden.append(spatial)
	camera.global_position = c + Vector3(0.5, 15, 7)
	camera.look_at(c + Vector3(0, 0, 0.8), Vector3.UP)
	await _capture("%s/%s_cutaway.png" % [_shots, _building])
	camera.global_position = c + Vector3(-6, 6.5, 9)
	camera.look_at(c + Vector3(0, 0.2, 0.5), Vector3.UP)
	await _capture("%s/%s_cutaway_oblique.png" % [_shots, _building])
	for node in hidden:
		node.visible = true


func _capture(path: String) -> void:
	for _i in 8:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)
	print("Saved ", path)
