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
var _nahl: StaticBody3D
var _oren: StaticBody3D
var _renewal: StaticBody3D


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
		sockets.append({"outline": SocketPlinth.exclusion(entry, line, key), "band": SocketPlinth.band(entry, key), "datum": float(line["datum"]), "sink": SocketPlinth.sink(entry)})
	_ground = FireCalderaGround.build(self, sockets)
	FireCalderaGround.build_lava(self)
	for entry in FireCalderaPlan.PLOTS:
		if _lines.has(entry["id"]):
			_plinths[entry["id"]] = SocketPlinth.build(self, entry, _lines[entry["id"]], SocketPlinth.size_key(entry))
	# The kit's first shell: the guest house (brief section 3), cobalt and amber.
	var guest := FireCalderaPlan.plot("GUEST")
	_shell = FireCalderaBuildings.guest_house(self, guest, _lines["GUEST"])
	# The second: the Nahl tempering hall and Eris's suite.
	_nahl = FireCalderaNahl.build(self, FireCalderaPlan.plot("NAHL"), _lines["NAHL"])
	# The third: the Oren mineral house, split level.
	_oren = FireCalderaOren.build(self, FireCalderaPlan.plot("OREN"), _lines["OREN"])
	_renewal = FireCalderaRenewal.build(self, FireCalderaPlan.plot("RENEWAL"), _lines["RENEWAL"])
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
		var pits := FireCalderaPlan.pit_outlines(entry)
		for i in 9:
			var p := centre.lerp(polygon[i % 4], 0.2 + 0.1 * float(i % 5))
			var pitted := false
			for pit in pits:
				pitted = pitted or Geometry2D.is_point_in_polygon(p, pit["outline"])
			if pitted:
				continue
			# Past the building and its furniture: the check is of the floor.
			var hit := _floor_ray_past_shell(space, Vector3(p.x, datum + 3.0, p.y), Vector3(p.x, float(line["bottom"]) - 2.0, p.y)) if id == "GUEST" else _ray(space, Vector3(p.x, datum + 3.0, p.y), Vector3(p.x, float(line["bottom"]) - 2.0, p.y), _building_rids())
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
				var hit := _floor_ray_past_shell(space, Vector3(reveal.x, ground + 2.0, reveal.y), Vector3(reveal.x, datum - 1.0, reveal.y))
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
	_check_nahl(space)
	_check_oren(space)
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
	var through := _ray(space, to_world * Vector3(-5.75, 1.2, hz + 2.0), to_world * Vector3(-5.75, 1.2, hz - 2.0), [])
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
	# Each rear room has a punched, fitted doorway directly off the lounge.
	for door: Array in [
		["keeper's room", Vector3(-6.25, 1.2, 0.9), Vector3(-6.25, 1.2, -0.6)],
		["rim room", Vector3(-3.4, 1.2, 0.9), Vector3(-3.4, 1.2, -0.6)],
		["washroom", Vector3(2.0, 1.2, 0.9), Vector3(2.0, 1.2, -0.6)],
		["lake room", Vector3(5.0, 1.2, 0.9), Vector3(5.0, 1.2, -0.6)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("GUEST: the %s doorway is blocked by %s" % [door[0], (hit["collider"] as Node).name])
	for marker in ["WakeMarker", "StandMarker", "GatherMarker", "KeeperStand", "DryGuestTerrace", "EntryFin", "LowPitchSkylightRoof"]:
		if _shell.get_node_or_null(marker) == null:
			_fail("GUEST: no %s" % marker)
	for problem in ClearZones.audit(_shell):
		_fail("GUEST layout: %s" % problem)
	# At every clear approach and interior lane, the first surface below ankle
	# height must be the plinth itself. This catches any invisible retained ground
	# that would make the player hover above the authored foundation.
	for local: Vector3 in [
		Vector3(-7.0, 0.35, 7.1), Vector3(-5.75, 0.35, 7.1), Vector3(0.0, 0.35, 7.1), Vector3(7.0, 0.35, 7.1),
		Vector3(-5.75, 0.35, 5.5), Vector3(0.0, 0.35, 5.5),
		Vector3(-5.0, 0.35, 1.0), Vector3(0.0, 0.35, 1.0), Vector3(5.0, 0.35, 1.0),
		Vector3(-6.25, 0.35, -0.8), Vector3(-3.4, 0.35, -0.6), Vector3(2.0, 0.35, -1.6), Vector3(5.0, 0.35, -1.0),
	]:
		var floor_hit := _ray(space, to_world * local, to_world * Vector3(local.x, -0.8, local.z), _building_rids())
		if floor_hit.is_empty() or floor_hit["collider"] != _plinths["GUEST"]:
			var detail: String = "nothing" if floor_hit.is_empty() else str((floor_hit["collider"] as Node).name)
			_fail("GUEST: invisible floor at local (%.1f, %.1f) is %s, not the plinth" % [local.x, local.z, detail])
	print("ok   GUEST: fitted doorways clear; spacious plan, skylight roof, plinth and rest markers in place")


func _building_rids() -> Array:
	var rids := []
	for building: StaticBody3D in [_shell, _nahl, _oren, _renewal]:
		if building == null:
			continue
		rids.append(building.get_rid())
		for node in building.find_children("*", "CollisionObject3D", true, false):
			rids.append((node as CollisionObject3D).get_rid())
	return rids


## The Oren house: each door open through at its own floor, every floor the
## building's (raised, ramped, upper) meeting the height query, the clear
## zones of both storeys.
func _check_oren(space: PhysicsDirectSpaceState3D) -> void:
	var to_world := _oren.global_transform
	var datum := float(_lines["OREN"]["datum"])
	var entry := FireCalderaPlan.plot("OREN")
	var up := FireCalderaOren.UPPER
	var raise := FireCalderaOren.RAISE
	for door: Array in [
		["shop door", Vector3(-5.0, 1.2, 8.0), Vector3(-5.0, 1.2, 4.0)],
		["assay door", Vector3(FireCalderaOren.ASSAY_DOOR_X, 1.2, 0.3), Vector3(FireCalderaOren.ASSAY_DOOR_X, 1.2, 1.8)],
		["receiving door", Vector3(-6.0, raise + 1.2, -7.5), Vector3(-6.0, raise + 1.2, -4.5)],
		["receiving inner door", Vector3(-6.0, raise + 1.2, -1.2), Vector3(-6.0, raise + 1.2, 0.4)],
		["stock store door", Vector3(FireCalderaOren.STORE_DOOR_X, raise + 1.2, -1.2), Vector3(FireCalderaOren.STORE_DOOR_X, raise + 1.2, 0.4)],
		["studio door", Vector3(FireCalderaOren.STUDIO_DOOR_X, raise + 1.2, -1.2), Vector3(FireCalderaOren.STUDIO_DOOR_X, raise + 1.2, 0.4)],
		["gem store door", Vector3(0.0, 1.2, 1.4), Vector3(0.0, 1.2, 3.0)],
		["home door", Vector3(7.5, up + 1.2, FireCalderaOren.HOME_DOOR_Z), Vector3(4.5, up + 1.2, FireCalderaOren.HOME_DOOR_Z)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("OREN: the %s is blocked by %s" % [door[0], (hit["collider"] as Node).name])
	# Each floor is where the height query says it is.
	for local: Vector2 in [Vector2(-5.0, 3.5), Vector2(4.0, 3.5), Vector2(-5.0, -3.0), Vector2(3.0, -3.0), Vector2(-4.0, 0.3), Vector2(3.2, 0.3), Vector2(7.5, -5.5), Vector2(7.5, -2.5), Vector2(7.5, 1.2), Vector2(-6.0, -6.5)]:
		var world := to_world * Vector3(local.x, 6.0 if local.x < 6.5 or local.y < -4.6 else 9.0, local.y)
		var plan := Vector2(world.x, world.z)
		var hit := _ray(space, world, Vector3(world.x, datum - 1.0, world.z), [])
		var expected := FireCalderaPlan.level_height(entry, plan)
		if is_nan(expected):
			expected = 0.0
		if hit.is_empty():
			_fail("OREN: no floor at %s" % str(local))
		elif absf(float(hit["position"].y) - datum - expected) > 0.05 and not (local.x < 6.5 and float(hit["position"].y) - datum > 3.0):
			_fail("OREN: the floor at %s is %.2f, the height query %.2f" % [str(local), float(hit["position"].y) - datum, expected])
	for problem in ClearZones.audit(_oren):
		_fail("OREN layout: %s" % problem)
	var home := _oren.get_node_or_null("OrenHome") as StaticBody3D
	if home == null:
		_fail("OREN: no home above")
	else:
		for problem in ClearZones.audit(home):
			_fail("OREN home layout: %s" % problem)
	# The roof terrace stands at its roof's top, and the lift serves it.
	var roof_hit := _ray(space, to_world * Vector3(-3.0, 12.0, 0.0), to_world * Vector3(-3.0, 6.0, 0.0), [])
	if roof_hit.is_empty() or absf(float(roof_hit["position"].y) - datum - up - FireCalderaOren.roof_top()) > 0.06:
		_fail("OREN: the roof terrace is not a floor at its roof's top")
	if _oren.get_node_or_null("Lift") == null:
		_fail("OREN: no lift to the terrace")
	print("ok   OREN: doors clear at their floors, split levels and ramps meet the height query")


## The Nahl hall: its four doors open clear through, the hall's full height,
## its clear zones, its markers and its molten surfaces.
func _check_nahl(space: PhysicsDirectSpaceState3D) -> void:
	var to_world := _nahl.global_transform
	var datum := float(_lines["NAHL"]["datum"])
	for door: Array in [
		["hall door", Vector3(-3.0, 1.2, 8.0), Vector3(-3.0, 1.2, 4.5)],
		["suite door", Vector3(FireCalderaNahl.SUITE_DOOR_X, 1.2, 8.0), Vector3(FireCalderaNahl.SUITE_DOOR_X, 1.2, 4.6)],
		["staff door", Vector3(1.2, 1.2, FireCalderaNahl.STAFF_DOOR_Z), Vector3(2.8, 1.2, FireCalderaNahl.STAFF_DOOR_Z)],
		["mediation door", Vector3(1.2, 1.2, FireCalderaNahl.MEDIATION_DOOR_Z), Vector3(2.8, 1.2, FireCalderaNahl.MEDIATION_DOOR_Z)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("NAHL: the %s is blocked by %s" % [door[0], (hit["collider"] as Node).name])
	var up := _ray(space, to_world * Vector3(-3.0, 0.6, 5.0), to_world * Vector3(-3.0, 9.0, 5.0), [])
	if up.is_empty():
		_fail("NAHL: no roof over the hall")
	elif float(up["position"].y) - datum < 5.8:
		_fail("NAHL: the hall is only %.2f m high" % (float(up["position"].y) - datum))
	var wing := _ray(space, to_world * Vector3(5.0, 0.6, -2.0), to_world * Vector3(5.0, 9.0, -2.0), [])
	if wing.is_empty() or float(wing["position"].y) - datum < 3.6:
		_fail("NAHL: the wing's roof is missing or low")
	for marker in ["ErisWorkMarker", "ErisRestMarker", "MoltenFloor"]:
		if _nahl.get_node_or_null(marker) == null:
			_fail("NAHL: no %s" % marker)
	for problem in ClearZones.audit(_nahl):
		_fail("NAHL layout: %s" % problem)
	# The conversation pit: its floor half a metre down in the plinth, and the
	# floor beside it still the datum.
	var pit: Dictionary = (FireCalderaPlan.plot("NAHL")["pits"] as Array)[0]
	var pit_at: Vector2 = pit["at"]
	var in_pit := _ray(space, to_world * Vector3(pit_at.x, 1.0, pit_at.y), to_world * Vector3(pit_at.x, -2.0, pit_at.y), _building_rids())
	if in_pit.is_empty() or in_pit["collider"] != _plinths["NAHL"] or absf(float(in_pit["position"].y) - (datum - float(pit["depth"]))) > 0.03:
		_fail("NAHL: the pit's floor is not the plinth %.2f m down" % float(pit["depth"]))
	var beside := _ray(space, to_world * Vector3(pit_at.x, 1.0, pit_at.y + 2.1), to_world * Vector3(pit_at.x, -2.0, pit_at.y + 2.1), _building_rids())
	if beside.is_empty() or absf(float(beside["position"].y) - datum) > 0.03:
		_fail("NAHL: the floor beside the pit is not the datum")
	var plinth_mesh := _plinths["NAHL"].get_node("PlinthMesh") as MeshInstance3D
	var low := 0
	var tops := 0
	var arrays := plinth_mesh.mesh.surface_get_arrays(0)
	for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		if absf(v.y - (datum - 0.5)) < 0.01: low += 1
		if absf(v.y - datum) < 0.001: tops += 1
	if FireCalderaNahl.lava_surfaces().size() != 2:
		_fail("NAHL: the molten floor and the well are not both registered")
	print("ok   NAHL: four doors clear, 6 m clerestory front, wing, pit, molten surfaces")


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = exclude
	return space.intersect_ray(query)


## CSG walls own physics RIDs that are not the shell body's RID. Skip any such
## envelope hit when a proof ray is specifically checking the plinth below it.
func _floor_ray_past_shell(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var excluded := _building_rids()
	for _i in 16:
		var hit := _ray(space, from, to, excluded)
		if hit.is_empty():
			return hit
		var collider := hit["collider"] as Node
		var ours := false
		for building: StaticBody3D in [_shell, _nahl, _oren, _renewal]:
			if building != null and (collider == building or building.is_ancestor_of(collider)):
				ours = true
		if ours:
			excluded.append(hit["rid"])
			continue
		return hit
	return {}


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
		var roof := _shell.get_node_or_null("LowPitchSkylightRoof") as Node3D if _shell != null else null
		if roof != null:
			roof.visible = name != "guest_cutaway"
		if name == "guest_cutaway":
			for _i in 3:
				await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	# Inside the guest house, poses in its own frame: (eye, target).
	var rooms := {
		"guest_lounge_doors": [Vector3(4.5, 1.65, 5.2), Vector3(-2.5, 2.0, 0.25)],
		"guest_rim_room": [Vector3(-0.6, 1.6, -0.4), Vector3(-3.0, 1.2, -5.8)],
		"guest_washroom": [Vector3(1.3, 1.6, -1.2), Vector3(3.1, 0.9, -5.4)],
		"guest_hall": [Vector3(-7.3, 1.7, 0.9), Vector3(6.0, 1.1, 4.2)],
		"guest_hall_relief": [Vector3(0.5, 1.6, 4.6), Vector3(-0.7, 1.4, 0.25)],
		"guest_hall_studies": [Vector3(4.6, 1.6, 3.8), Vector3(3.5, 1.5, 0.25)],
		"guest_rim_wash_glass": [Vector3(-1.6, 1.7, -1.2), Vector3(0.25, 3.3, -3.5)],
		"guest_lake_room": [Vector3(7.3, 1.6, -0.7), Vector3(4.2, 1.1, -4.6)],
		"guest_keeper_room": [Vector3(-5.2, 1.6, -0.3), Vector3(-6.8, 1.0, -5.0)],
		# Wall heads against the roof's pitch: the east side at eye level with
		# the ring beam.
		"guest_wallhead_east": [Vector3(13.0, 4.2, 0.5), Vector3(7.75, 3.85, 0.0)],
		"guest_wallhead_back": [Vector3(4.0, 4.2, -10.0), Vector3(0.0, 3.8, -6.0)],
	}
	var oren := {
		"oren_front": [Vector3(-1.0, 1.7, 17.0), Vector3(-1.0, 3.5, 0.0)],
		"oren_back": [Vector3(4.0, 3.2, -16.0), Vector3(0.0, 2.5, -6.0)],
		"oren_east_ramp": [Vector3(15.0, 4.0, -8.0), Vector3(7.5, 2.5, -2.0)],
		"oren_counter": [Vector3(-7.6, 1.7, 5.4), Vector3(0.5, 1.0, 1.4)],
		"oren_corridor": [Vector3(-7.6, 1.35 + 1.6, 0.3), Vector3(6.4, 0.8, 0.3)],
		"oren_studio": [Vector3(0.6, 1.35 + 1.6, -0.9), Vector3(5.5, 1.6, -5.4)],
		"oren_terrace": [Vector3(6.4, 4.0 + 3.99 + 1.7, -4.5), Vector3(-3.0, 4.0 + 3.99, 4.0)],
		"oren_lift": [Vector3(13.0, 6.5, 8.0), Vector3(7.6, 5.5, 3.0)],
		"oren_home": [Vector3(5.8, 4.0 + 1.6, 1.4), Vector3(-7.0, 4.0 + 1.0, 4.0)],
	}
	for name: String in oren:
		var pose: Array = oren[name]
		camera.global_position = _oren.global_transform * (pose[0] as Vector3)
		camera.look_at(_oren.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	var renewal := {
		"renewal_front": [Vector3(0.0, 1.7, 14.0), Vector3(0.0, 3.0, -2.0)],
		"renewal_under": [Vector3(-5.0, 1.35 + 1.6, -4.4), Vector3(4.0, 2.5, 3.0)],
		"renewal_aerial": [Vector3(14.0, 14.0, 16.0), Vector3(0.0, 2.0, -1.0)],
		"renewal_stones": [Vector3(-1.0, 1.6, 7.5), Vector3(-5.0, 1.0, 4.0)],
	}
	for name: String in renewal:
		var pose: Array = renewal[name]
		camera.global_position = _renewal.global_transform * (pose[0] as Vector3)
		camera.look_at(_renewal.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	# The Nahl hall, poses in its own frame.
	var nahl := {
		"nahl_front": [Vector3(-1.0, 1.7, 17.0), Vector3(0.0, 3.0, 0.0)],
		"nahl_suite_side": [Vector3(17.0, 1.7, -6.0), Vector3(7.0, 2.0, -1.0)],
		"nahl_cutaway": [Vector3(13.0, 17.0, 15.0), Vector3(0.0, 0.0, 0.0)],
		"nahl_hall": [Vector3(1.0, 1.7, 1.6), Vector3(-6.0, 1.0, -3.5)],
		"nahl_molten_bay": [Vector3(-3.6, 1.7, 1.2), Vector3(-6.4, 0.4, -3.2)],
		"nahl_clerestory": [Vector3(-4.0, 1.6, -4.0), Vector3(-2.0, 5.0, 6.0)],
		"nahl_pit_top": [Vector3(5.1, 7.0, -2.5), Vector3(5.1, -0.5, -3.5)],
		"nahl_mediation": [Vector3(2.5, 1.6, -1.6), Vector3(6.2, -0.4, -4.2)],
		"nahl_suite": [Vector3(7.2, 1.7, 5.2), Vector3(3.0, 0.4, 0.6)],
		"nahl_wallhead_east": [Vector3(13.0, 4.4, 0.0), Vector3(8.0, 3.9, 0.0)],
		"nahl_wallhead_west": [Vector3(-14.0, 4.6, 1.0), Vector3(-8.0, 4.8, 0.0)],
				"nahl_keepsakes": [Vector3(4.6, 1.6, 2.6), Vector3(7.6, 1.0, 1.8)],
	}
	var roof_node := _shell.get_node_or_null("LowPitchSkylightRoof") as Node3D if _shell != null else null
	if roof_node != null:
		roof_node.visible = true
	for name: String in rooms:
		var pose: Array = rooms[name]
		camera.global_position = _shell.global_transform * (pose[0] as Vector3)
		camera.look_at(_shell.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	for name: String in nahl:
		var pose: Array = nahl[name]
		for roof in _nahl.find_children("*", "CSGCombiner3D", false, false):
			(roof as Node3D).visible = name != "nahl_cutaway" and name != "nahl_pit_top"
		camera.global_position = _nahl.global_transform * (pose[0] as Vector3)
		camera.look_at(_nahl.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
