extends Node3D

## The Fire caldera's isolated prototype (handoff: "prototype the localized
## caldera bank, one sloped-ground socket foundation and one lava interface
## in isolation before constructing the city"). Builds FireCalderaGround, the
## reservoir's lava and a socketed plinth on every building plot, then checks
## each socket with physics:
##   - no ground collision inside the socket (the plinth is the only floor);
##   - the floor is the plinth, at its datum;
##   - the uphill reveal is clear and walled, the downhill face reaches below
##     the ground (no daylight under the base);
##   - the front landing meets the floor flush.
## Headless it checks and quits; with a window it also saves renders.
##
##   Godot --headless --path . tools/fire_caldera_proof.tscn
##   Godot --path . tools/fire_caldera_proof.tscn -- --shots=/abs/dir

var _failures := 0
var _shots := ""
var _ground: StaticBody3D
var _plinths := {}
var _lines := {}
var _shell: StaticBody3D


func _ready() -> void:
	get_tree().create_timer(180.0).timeout.connect(func() -> void:
		print("FAIL fire_caldera_proof watchdog")
		get_tree().quit(2))
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--shots="):
			_shots = argument.trim_prefix("--shots=")
	_run.call_deferred()


func _run() -> void:
	var sockets := []
	for entry in FireCalderaPlan.PLOTS:
		if bool(entry.get("open", false)):
			continue
		var line := FireCalderaGround.survey(entry)
		_lines[entry["id"]] = line
		var key := SocketPlinth.size_key(entry)
		sockets.append({"outline": SocketPlinth.exclusion(entry, line, key), "band": SocketPlinth.band(entry, key), "datum": float(line["datum"])})
	_ground = FireCalderaGround.build(self, sockets)
	FireCalderaGround.build_lava(self)
	for entry in FireCalderaPlan.PLOTS:
		if _lines.has(entry["id"]):
			_plinths[entry["id"]] = SocketPlinth.build(self, entry, _lines[entry["id"]], SocketPlinth.size_key(entry))
	# The kit's first shell: the guest house (brief section 3), cobalt and amber.
	var guest := FireCalderaPlan.plot("GUEST")
	_shell = FireCalderaBuildings.guest_house(self, guest, _lines["GUEST"])
	_stage()
	for _i in 6:
		await get_tree().physics_frame
	_check()
	if not _shots.is_empty():
		await _render()
	print("---- fire_caldera_proof: %d plinths, %d FAIL" % [_plinths.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _check() -> void:
	var space := get_world_3d().direct_space_state
	for id: String in _plinths:
		var entry := FireCalderaPlan.plot(id)
		var line: Dictionary = _lines[id]
		var datum := float(line["datum"])
		var plinth: StaticBody3D = _plinths[id]
		var polygon := FireCalderaPlan.plot_polygon(entry, "footprint")
		var centre: Vector2 = entry["centre"]
		# Inside the socket: the plinth first, and no ground under it.
		for i in 9:
			var p := centre.lerp(polygon[i % 4], 0.2 + 0.1 * float(i % 5))
			# Past the building and its furniture: the check is of the floor.
			var hit := _ray(space, Vector3(p.x, datum + 3.0, p.y), Vector3(p.x, float(line["bottom"]) - 2.0, p.y), _building_rids())
			if hit.is_empty() or hit["collider"] != plinth:
				_fail("%s: the floor at %s is not the plinth" % [id, str(p.round())])
				continue
			if absf(float(hit["position"].y) - datum) > 0.05:
				_fail("%s: the plinth's top at %s is %.2f, not its datum %.2f" % [id, str(p.round()), hit["position"].y, datum])
			var under := _ray(space, Vector3(p.x, datum + 3.0, p.y), Vector3(p.x, float(line["bottom"]) - 2.0, p.y), [plinth.get_rid()])
			if not under.is_empty() and under["collider"] == _ground:
				_fail("%s: ground collision inside the socket at %s (y %.2f)" % [id, str(p.round()), under["position"].y])
		# Round the edge: uphill, a clear reveal at the datum; downhill, the
		# base reaches below the ground.
		var outline := SocketPlinth.exclusion(entry, line)
		var walled := 0
		for i in range(0, outline.size(), 6):
			var edge := outline[i]
			var outward := (edge - centre).normalized()
			var ground := FireCalderaGround.height(edge + outward * 1.0)
			if ground > datum + 0.3:
				walled += 1
				var reveal := edge - outward * 0.6
				# Past any roof overhanging the reveal: the check is of its floor.
				var hit := _ray(space, Vector3(reveal.x, ground + 2.0, reveal.y), Vector3(reveal.x, datum - 1.0, reveal.y), _building_rids())
				if hit.is_empty() or hit["collider"] != plinth or absf(float(hit["position"].y) - datum) > 0.06:
					var detail := "no floor" if hit.is_empty() else "%s at %.2f" % [(hit["collider"] as Node).name, float(hit["position"].y)]
					_fail("%s: the uphill reveal at %s is not clear at the datum (%s)" % [id, str(reveal.round()), detail])
			elif ground < datum - 0.05 and float(line["bottom"]) > ground - 1.0:
				_fail("%s: daylight under the base at %s" % [id, str(edge.round())])
		# The front landing meets the floor.
		var landing := FireCalderaPlan.front_point(entry) + FireCalderaPlan.facing(entry) * 2.0
		var at_landing := FireCalderaGround.height(landing)
		if absf(at_landing - datum) > 0.15:
			_fail("%s: the front landing is %.2f m off the floor" % [id, at_landing - datum])
		print("ok   %s: %s, datum %.2f, %d uphill wall pieces" % [id, line["foundation"], datum, walled])
	_check_shell(space)
	# The lava's edge runs under the bank: ground below the lava just inside.
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var p := Vector2(cos(angle), sin(angle)) * (FireCalderaPlan.reservoir_radius(angle) - 0.5)
		if FireCalderaGround.height(p) > FireCalderaGround.LAVA_Y - 0.1 and FireCalderaGround.height(p) < FireCalderaGround.LIP_Y - 0.5:
			pass
		var outside := Vector2(cos(angle), sin(angle)) * (FireCalderaPlan.reservoir_radius(angle) + 1.6)
		if FireCalderaGround.height(outside) < FireCalderaGround.LAVA_Y:
			_fail("the bank at %s dips below the lava beyond the lava's edge" % str(outside.round()))


## The guest house's shell: inside its plinth, its door open clear through,
## 2.4 m or more of headroom under the roof.
func _check_shell(space: PhysicsDirectSpaceState3D) -> void:
	var entry := FireCalderaPlan.plot("GUEST")
	var datum := float(_lines["GUEST"]["datum"])
	var to_world := _shell.global_transform
	var hz := (entry["footprint"] as Vector2).y * 0.5
	var through := _ray(space, to_world * Vector3(-4.0, 1.2, hz + 2.0), to_world * Vector3(-4.0, 1.2, hz - 2.0), [])
	if not through.is_empty():
		_fail("GUEST: the door bay is blocked by %s" % (through["collider"] as Node).name)
	for x: float in [-4.0, 0.0, 4.0]:
		var up := _ray(space, to_world * Vector3(x, 0.1, 0.0), to_world * Vector3(x, 6.0, 0.0), [])
		if up.is_empty():
			_fail("GUEST: no roof over (%.0f, 0)" % x)
		elif float(up["position"].y) - datum < 2.4:
			_fail("GUEST: %.2f m of headroom at (%.0f, 0)" % [float(up["position"].y) - datum, x])
	var below := _ray(space, to_world * Vector3(0.0, 0.5, 0.0), to_world * Vector3(0.0, -1.0, 0.0), [])
	if below.is_empty() or below["collider"] != _plinths["GUEST"]:
		_fail("GUEST: the shell does not stand on its plinth")
	# Each inner doorway clear at chest height: party room, washroom, cabinet.
	for door: Array in [["party room", Vector3(-2.2, 1.2, 2.5), Vector3(-0.8, 1.2, 2.5)], ["washroom", Vector3(-0.8, 1.2, -1.7), Vector3(-2.2, 1.2, -1.7)],
			["provisions cabinet", Vector3(-5.25, 1.2, -0.3), Vector3(-5.25, 1.2, -1.7)]]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("GUEST: the %s doorway is blocked by %s" % [door[0], (hit["collider"] as Node).name])
	for marker in ["WakeMarker", "StandMarker", "GatherMarker", "KeeperStand", "DryPartyTerrace", "EntryFin"]:
		if _shell.get_node_or_null(marker) == null:
			_fail("GUEST: no %s" % marker)
	print("ok   GUEST: door bay and inner doorways clear, roof, plinth and rest markers in place")


func _building_rids() -> Array:
	var rids := []
	if _shell != null:
		rids.append(_shell.get_rid())
		for node in _shell.find_children("*", "CollisionObject3D", true, false):
			rids.append((node as CollisionObject3D).get_rid())
	return rids


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = exclude
	return space.intersect_ray(query)


func _stage() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.36, 0.30, 0.30)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.48, 0.46)
	env.ambient_light_energy = 0.6
	environment.environment = env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 30.0, 0.0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)


func _render() -> void:
	DisplayServer.window_set_size(Vector2i(1600, 1000))
	var camera := Camera3D.new()
	camera.far = 600.0
	add_child(camera)
	camera.current = true
	# Poses as (plan point, height above its ground) -> (plan point, height).
	var shots := {
		"aerial": [Vector2(0.0, -95.0), 90.0, Vector2(0.0, 4.0), 0.0],
		"arrival_eye": [Vector2(0.0, -52.0), 1.7, Vector2(0.0, 40.0), 1.0],
		"promenade_west": [Vector2(-31.0, -14.0), 1.7, Vector2(-28.0, 30.0), 1.0],
		"aro_plinth": [Vector2(-24.0, 36.0), 3.0, Vector2(-39.4, 27.0), 0.0],
		"civic_back": [Vector2(0.0, 66.0), 4.0, Vector2(0.0, 49.0), 0.0],
		"kel_bank": [Vector2(26.0, -14.0), 1.7, Vector2(48.0, -4.0), 0.5],
		"guest_front": [Vector2(-18.0, -36.0), 1.7, Vector2(-27.0, -51.0), 1.8],
		"guest_door": [Vector2(-22.5, -41.0), 1.6, Vector2(-26.5, -48.0), 1.4],
		"guest_cutaway": [Vector2(-21.0, -40.0), 14.0, Vector2(-27.0, -51.0), 0.0],
	}
	DirAccess.make_dir_recursive_absolute(_shots)
	for name: String in shots:
		var pose: Array = shots[name]
		var from: Vector2 = pose[0]
		var to: Vector2 = pose[2]
		camera.global_position = Vector3(from.x, FireCalderaGround.blended_height(from, Callable(FireCalderaGround, "crater_wall")) + float(pose[1]), from.y)
		camera.look_at(Vector3(to.x, FireCalderaGround.blended_height(to, Callable(FireCalderaGround, "crater_wall")) + float(pose[3]), to.y), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		var roof := _shell.get_node_or_null("Roof") as Node3D if _shell != null else null
		if roof != null:
			roof.visible = name != "guest_cutaway"
		if name == "guest_cutaway":
			for _i in 3:
				await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
