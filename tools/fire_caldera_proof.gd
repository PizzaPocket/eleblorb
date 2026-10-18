extends Node3D

const FireCalderaHighline := preload("res://scripts/fire_caldera_highline.gd")

const FireCalderaVara := preload("res://scripts/fire_caldera_vara.gd")
const FireCalderaCivic := preload("res://scripts/fire_caldera_civic.gd")
const FireCalderaIren := preload("res://scripts/fire_caldera_iren.gd")
const FireCalderaAro := preload("res://scripts/fire_caldera_aro.gd")

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
var _kel: StaticBody3D
var _vara: StaticBody3D
var _civic: StaticBody3D
var _iren: StaticBody3D
var _aro: StaticBody3D
var _highline: StaticBody3D


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
		var elevated := FireCalderaPlan.is_elevated(entry)
		if not elevated:
			sockets.append({"outline": SocketPlinth.exclusion(entry, line, key), "band": SocketPlinth.band(entry, key), "datum": float(line["datum"]), "sink": SocketPlinth.sink(entry), "elevated": false})
	_ground = await FireCalderaGround.build(self, sockets)
	FireCalderaGround.build_lava(self)
	_highline = FireCalderaHighline.build(self)
	for entry in FireCalderaPlan.PLOTS:
		if _lines.has(entry["id"]):
			if FireCalderaPlan.is_elevated(entry):
				_plinths[entry["id"]] = FireCalderaHighline.build_platform(self, entry, _lines[entry["id"]])
			elif str(entry.get("foundation_kind", "")) == "renewal_glass":
				_plinths[entry["id"]] = FireCalderaRenewal.build_foundation(self, entry, _lines[entry["id"]])
			else:
				_plinths[entry["id"]] = SocketPlinth.build(self, entry, _lines[entry["id"]], SocketPlinth.size_key(entry))
	# The kit's first shell: the guest house (brief section 3), cobalt and amber.
	var guest := FireCalderaPlan.plot("GUEST")
	_shell = FireCalderaBuildings.guest_house(self, guest, _lines["GUEST"])
	# The second: the Nahl tempering hall and Eris's suite.
	_nahl = FireCalderaNahl.build(self, FireCalderaPlan.plot("NAHL"), _lines["NAHL"])
	# The third: the Oren mineral house, split level.
	_oren = FireCalderaOren.build(self, FireCalderaPlan.plot("OREN"), _lines["OREN"])
	_renewal = FireCalderaRenewal.build(self, FireCalderaPlan.plot("RENEWAL"), _lines["RENEWAL"])
	_kel = FireCalderaKel.build(self, FireCalderaPlan.plot("KEL"), _lines["KEL"])
	_vara = FireCalderaVara.build(self, FireCalderaPlan.plot("VARA"), _lines["VARA"])
	_civic = FireCalderaCivic.build(self, FireCalderaPlan.plot("CIVIC"), _lines["CIVIC"])
	_iren = FireCalderaIren.build(self, FireCalderaPlan.plot("IREN"), _lines["IREN"], _lines["CIVIC"])
	_aro = FireCalderaAro.build(self, FireCalderaPlan.plot("ARO"), _lines["ARO"])
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
		if str(entry.get("foundation_kind", "")) == "ghat":
			continue
		if FireCalderaPlan.is_elevated(entry):
			var centre: Vector2 = entry["centre"]
			var elevated_hit := _floor_ray_past_shell(space, Vector3(centre.x, datum + 3.0, centre.y), Vector3(centre.x, FireCalderaGround.height(centre) - 1.0, centre.y)) if id == "GUEST" else _ray(space, Vector3(centre.x, datum + 3.0, centre.y), Vector3(centre.x, FireCalderaGround.height(centre) - 1.0, centre.y), _building_rids())
			if elevated_hit.is_empty() or elevated_hit["collider"] != plinth or absf(float(elevated_hit["position"].y) - datum) > 0.06:
				_fail("%s: the Highline platform is not the first floor at datum %.2f" % [id, datum])
			print("ok   %s: Highline platform at %.2f over natural ground %.2f" % [id, datum, FireCalderaGround.height(centre)])
			continue
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
			var hit := _floor_ray_past_shell(space, Vector3(p.x, datum + 3.0, p.y), Vector3(p.x, float(line["bottom"]) - 2.0, p.y))
			if hit.is_empty() or hit["collider"] != plinth:
				var floor_detail := "nothing" if hit.is_empty() else "%s at %.2f" % [(hit["collider"] as Node).name, float(hit["position"].y)]
				_fail("%s: the floor at %s is not the plinth (%s)" % [id, str(p.round()), floor_detail])
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
		if absf(at_landing - datum) > 0.15 and not bool(entry.get("quay", false)):
			_fail("%s: the front landing is %.2f m off the floor" % [id, at_landing - datum])
		print("ok   %s: %s, datum %.2f, %d uphill cut samples" % [id, line["foundation"], datum, walled])
	_check_highline(space)
	_check_shell(space)
	_check_nahl(space)
	_check_oren(space)
	_check_vara(space)
	_check_civic(space)
	_check_iren(space)
	_check_aro(space)
	# The lava's edge runs under the bank: ground below the lava just inside.
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var p := Vector2(cos(angle), sin(angle)) * (FireCalderaPlan.reservoir_radius(angle) - 0.5)
		if FireCalderaGround.height(p) > FireCalderaGround.LAVA_Y - 0.1 and FireCalderaGround.height(p) < FireCalderaGround.LIP_Y - 0.5:
			pass
		var outside := Vector2(cos(angle), sin(angle)) * (FireCalderaPlan.reservoir_radius(angle) + 1.6)
		if FireCalderaGround.height(outside) < FireCalderaGround.LAVA_Y:
			_fail("the bank at %s dips below the lava beyond the lava's edge" % str(outside.round()))


func _check_highline(space: PhysicsDirectSpaceState3D) -> void:
	var raised_ids: Array[String] = ["GUEST", "NAHL", "VARA", "CIVIC", "IREN"]
	for id: String in raised_ids:
		var pier_name := "%sSupertoroidalServicePier" % id
		if (_plinths[id] as Node).get_node_or_null(pier_name) == null:
			_fail("%s: no foundation-flush supertoroidal service pier" % id)
	for entry in FireCalderaPlan.PLOTS:
		var id := str(entry["id"])
		if FireCalderaPlan.is_elevated(entry) != (id in raised_ids):
			_fail("%s: raised-building classification drifted from the five supported properties" % id)
	var guest := FireCalderaPlan.plot("GUEST")
	if (guest["centre"] as Vector2).distance_to(FireCalderaPlan.ARRIVAL_THRESHOLD) > 30.0:
		_fail("GUEST: the inn is no longer beside the true gate")
	if _highline.find_children("GuestGateLinkGlass*", "MeshInstance3D", true, false).is_empty():
		_fail("GUEST: no short gate-forecourt link reaches the inn")
	if _highline.find_children("OrenTerraceLinkGlass*", "MeshInstance3D", true, false).is_empty():
		_fail("OREN: no deliberate Highline access reaches the roof terrace")
	if not _highline.find_children("CraftDescent*", "*", true, false).is_empty():
		_fail("KEL: the obsolete sweeping craft descent remains")
	var angle := deg_to_rad(30.0)
	var from := Vector3(cos(angle) * 68.0, FireCalderaPlan.HIGHLINE_DATUM + 0.8, sin(angle) * 68.0)
	var to := Vector3(cos(angle) * 76.0, FireCalderaPlan.HIGHLINE_DATUM + 0.8, sin(angle) * 76.0)
	var rail_hit := _ray(space, from, to, [])
	if rail_hit.is_empty() or rail_hit["collider"] != _highline:
		_fail("Highline: the glass edge railing has no collision")
	for rail_name: String in ["InnerTopRailRun", "OuterTopRailRun", "ArrivalBywayLeftTopRail", "ArrivalBywayRightTopRail"]:
		if _highline.find_child(rail_name, true, false) == null:
			_fail("Highline: no continuous pipe run named %s" % rail_name)
	for label: String in ["ArrivalByway", "GuestGateLink", "RenewalWest", "RenewalEast", "OrenTerraceLink"]:
		if _highline.find_child("%sGlassRibbon" % label, true, false) == null:
			_fail("Highline: %s is not one continuous visual ribbon" % label)
		if _highline.find_child("%sRibbonCollision" % label, true, false) == null:
			_fail("Highline: %s is not one continuous collision ribbon" % label)
		if _highline.find_child("%sGlass00" % label, true, false) != null:
			_fail("Highline: %s still uses segmented box slabs" % label)
	var arrival := FireCalderaPlan.arrival_byway()
	var arrival_start := FireCalderaGround.crater_wall(arrival[0]) + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE
	_check_ribbon_floor(space, "H0", arrival, FireCalderaGround.height(arrival[0]), FireCalderaPlan.HIGHLINE_DATUM)
	var guest_path := FireCalderaPlan.guest_gate_link()
	var guest_station := 0
	var guest_station_distance := INF
	for i in arrival.size():
		var distance := arrival[i].distance_to(guest_path[0])
		if distance < guest_station_distance:
			guest_station_distance = distance
			guest_station = i
	var guest_join_start := maxi(0, guest_station - 1)
	var guest_join_end := mini(arrival.size() - 1, guest_station + 1)
	var guest_start_y := 0.0
	for i in [guest_join_start, guest_join_end]:
		var t := float(i) / float(arrival.size() - 1)
		var y := FireCalderaGround.height(arrival[0]) if i == 0 else lerpf(arrival_start, FireCalderaPlan.HIGHLINE_DATUM, FireCalderaPlan.route_height_t("H0", t))
		if t < 0.08 and i > 0:
			y = lerpf(FireCalderaGround.height(arrival[0]), arrival_start, smoothstep(0.0, 0.08, t))
		guest_start_y += y * 0.5
	_check_ribbon_floor(space, "HG", guest_path, guest_start_y, FireCalderaPlan.GUEST_GATE_DATUM)
	_check_ribbon_floor(space, "H2W", FireCalderaPlan.renewal_byway(-1.0), FireCalderaPlan.HIGHLINE_DATUM, float(_lines["RENEWAL"]["datum"]))
	_check_ribbon_floor(space, "H2E", FireCalderaPlan.renewal_byway(1.0), FireCalderaPlan.HIGHLINE_DATUM, float(_lines["RENEWAL"]["datum"]))
	_check_ribbon_floor(space, "H4", FireCalderaPlan.oren_terrace_link(), FireCalderaPlan.HIGHLINE_DATUM, float(_lines["OREN"]["datum"]) + FireCalderaOren.UPPER + FireCalderaOren.roof_top())
	var renewal_plinth := _plinths["RENEWAL"] as Node
	for feature: String in ["RenewalGlassDeck", "RenewalSupertoroidalServicePier"]:
		if renewal_plinth.find_child(feature, true, false) == null:
			_fail("RENEWAL: no %s" % feature)
	if renewal_plinth.find_child("ImmersionTongueGlassRibbon", true, false) == null:
		_fail("RENEWAL: the immersion tongue is missing from its civic platform")
	if not renewal_plinth.find_children("GhatStep", "*", true, false).is_empty():
		_fail("RENEWAL: the obsolete bulky ghat steps remain")
	for prefix: String in ["RenewalWestGlass", "RenewalEastGlass"]:
		if _highline.find_children("%s*" % prefix, "MeshInstance3D", true, false).is_empty():
			_fail("RENEWAL: no %s access" % prefix)
	if _iren.find_child("IrenCivicBridgeFloor", true, false) != null:
		_fail("IREN: the obsolete cross-village Civic bridge remains")


func _check_ribbon_floor(space: PhysicsDirectSpaceState3D, id: String, points: PackedVector2Array, start_y: float, finish_y: float) -> void:
	var cumulative := PackedFloat32Array()
	if id == "H2W" or id == "H2E":
		cumulative.resize(points.size())
		for i in range(1, points.size()):
			cumulative[i] = cumulative[i - 1] + points[i - 1].distance_to(points[i])
	for i in range(1, points.size() - 1, 2):
		var t := float(i) / float(points.size() - 1)
		var height_t := cumulative[i] / maxf(cumulative[-1], 0.001) if not cumulative.is_empty() else FireCalderaPlan.route_height_t(id, t)
		var y := lerpf(start_y, finish_y, height_t)
		if id == "H0":
			var ramp_start := FireCalderaGround.crater_wall(points[0]) + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE
			if t < 0.08:
				y = lerpf(start_y, ramp_start, smoothstep(0.0, 0.08, t))
			else:
				y = lerpf(ramp_start, finish_y, height_t)
		var p := points[i]
		var hit := _ray(space, Vector3(p.x, y + 0.35, p.y), Vector3(p.x, y - 0.45, p.y), [_ground.get_rid()])
		if hit.is_empty() or hit["collider"] != _highline or absf(float(hit["position"].y) - y) > 0.06:
			var found := "no hit" if hit.is_empty() else "%s at %.3f (expected %.3f)" % [(hit["collider"] as Node).name, float(hit["position"].y), y]
			_fail("%s has no continuous walkable ribbon at %.0f%% near %s: %s" % [id, t * 100.0, str(p.round()), found])
			return


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
	_check_capsule_passage(space, "GUEST: entrance", to_world * Vector3(-5.75, 1.2, hz + 2.0), to_world * Vector3(-5.75, 1.2, hz - 2.0))
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
		_check_capsule_passage(space, "GUEST: %s doorway" % door[0], to_world * (door[1] as Vector3), to_world * (door[2] as Vector3))
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
		var excluded := _building_rids()
		excluded.append(_highline.get_rid())
		var floor_hit := _ray(space, to_world * local, to_world * Vector3(local.x, -0.8, local.z), excluded)
		if floor_hit.is_empty() or floor_hit["collider"] != _plinths["GUEST"]:
			var detail: String = "nothing" if floor_hit.is_empty() else str((floor_hit["collider"] as Node).name)
			_fail("GUEST: invisible floor at local (%.1f, %.1f) is %s, not the plinth" % [local.x, local.z, detail])
	print("ok   GUEST: fitted doorways clear; spacious plan, skylight roof, plinth and rest markers in place")


func _building_rids() -> Array:
	var rids := []
	for building: StaticBody3D in [_shell, _nahl, _oren, _renewal, _kel, _vara, _civic, _iren, _aro]:
		if building == null:
			continue
		rids.append(building.get_rid())
		for node in building.find_children("*", "CollisionObject3D", true, false):
			rids.append((node as CollisionObject3D).get_rid())
	return rids


## Vara: all four outside approaches and the two court connections take the
## real player capsule, the daylight court stays open to the sky, and the
## studio/home markers and molten fixtures exist.
func _check_vara(space: PhysicsDirectSpaceState3D) -> void:
	var to_world := _vara.global_transform
	for door: Array in [
		["studio entrance", Vector3(-6.3, 1.2, 9.0), Vector3(-6.3, 1.2, 5.2)],
		["hot-shop service door", Vector3(-11.0, 1.2, -4.5), Vector3(-7.2, 1.2, -4.5)],
		["home entrance", Vector3(11.0, 1.2, 2.0), Vector3(7.2, 1.2, 2.0)],
		["studio court door", Vector3(-2.3, 1.2, 1.5), Vector3(0.4, 1.2, 1.5)],
		["home court door", Vector3(2.7, 1.2, 2.5), Vector3(5.3, 1.2, 2.5)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("VARA: the %s is blocked by %s" % [door[0], (hit["collider"] as Node).name])
		_check_capsule_passage(space, "VARA: %s" % door[0], to_world * (door[1] as Vector3), to_world * (door[2] as Vector3))
	# The 5 x 8 m court has no roof, while all three occupied masses do.
	var court_up := _ray(space, to_world * Vector3(1.6, 0.4, 3.0), to_world * Vector3(1.6, 8.0, 3.0), [])
	if not court_up.is_empty():
		_fail("VARA: the daylight court is roofed over")
	for local: Vector3 in [Vector3(-6.0, 0.4, 3.0), Vector3(-6.0, 0.4, -4.0), Vector3(1.5, 0.4, -4.5), Vector3(6.5, 0.4, 3.0)]:
		var roof := _ray(space, to_world * local, to_world * Vector3(local.x, 8.0, local.z), [])
		if roof.is_empty():
			_fail("VARA: no roof over local %s" % str(Vector2(local.x, local.z)))
	for marker: String in ["OmiWorkMarker", "TalenWorkMarker", "CourtInspectionMarker", "OmiRestMarker", "TalenRestMarker"]:
		if _vara.get_node_or_null(marker) == null:
			_fail("VARA: no %s" % marker)
	var lava_meshes := _vara.find_children("*", "MeshInstance3D", true, false).filter(func(node: Node) -> bool: return node.has_meta("caldera_lava_surface"))
	if lava_meshes.size() != 3:
		_fail("VARA: household lava beds or immersion well are missing")
	for problem in ClearZones.audit(_vara):
		_fail("VARA layout: %s" % problem)
	print("ok   VARA: separate studio/home entries, open daylight court and hot-work service route")


## Civic: the central portal, both terrarium walks, archive slider and ramp
## flights take the real player capsule; the court remains double height; the
## building-scale terrarium and glazed saddle canopy are present.
func _check_civic(space: PhysicsDirectSpaceState3D) -> void:
	var to_world := _civic.global_transform
	for door: Array in [
		["central public portal", Vector3(0.0, 1.2, 9.2), Vector3(0.0, 1.2, 5.0)],
		["west terrarium walk", Vector3(-5.55, 1.2, 5.4), Vector3(-5.55, 1.2, -5.2)],
		["east terrarium walk", Vector3(5.55, 1.2, 5.4), Vector3(5.55, 1.2, -5.2)],
		["archive slider", Vector3(8.75, 1.2, 0.2), Vector3(8.75, 1.2, -2.4)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("CIVIC: the %s is blocked by %s" % [door[0], (hit["collider"] as Node).name])
		_check_capsule_passage(space, "CIVIC: %s" % door[0], to_world * (door[1] as Vector3), to_world * (door[2] as Vector3))
	# No floor may cap the double-height council at the upper-storey datum.
	var council_up := _ray(space, to_world * Vector3(0.0, 3.55, 4.6), to_world * Vector3(0.0, 8.55, 4.6), [])
	if not council_up.is_empty():
		_fail("CIVIC: the double-height council is capped below its roof")
	# Both ramp centre lines must have continuous walkable collision.
	for sample: Array in [
		["lower", Vector3(-10.0, 1.55, 5.5), Vector3(-10.0, 2.95, 2.0)],
		["upper", Vector3(-8.0, 3.35, 1.2), Vector3(-8.0, 4.95, -4.05)],
	]:
		_check_capsule_passage(space, "CIVIC: %s ramp flight" % sample[0], to_world * (sample[1] as Vector3), to_world * (sample[2] as Vector3))
	for marker: String in ["CouncilSpeakerMarker", "CouncilStandingMarker", "SchoolMarker", "ArchiveMarker", "LowerObservationMarker"]:
		if _civic.get_node_or_null(marker) == null:
			_fail("CIVIC: no %s" % marker)
	for marker: String in ["SelkaInstrumentMarker", "CivicSaddleCanopy", "CivicTerrariumShell", "TerrariumLivingTree"]:
		if _civic.find_child(marker, true, false) == null:
			_fail("CIVIC: no %s" % marker)
	for problem in ClearZones.audit(_civic):
		_fail("CIVIC layout: %s" % problem)
	print("ok   CIVIC: open Terrarium Court, central portal, public ramp, school/archive and glazed saddle canopy")


func _check_iren(space: PhysicsDirectSpaceState3D) -> void:
	var to_world := _iren.global_transform
	for door: Array in [
		["home entrance", Vector3(-1.6, 1.2, 6.2), Vector3(-1.6, 1.2, 3.4)],
		["resting room", Vector3(-1.5, 1.2, 0.7), Vector3(-1.5, 1.2, -1.4)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("IREN: the %s is blocked by %s" % [door[0], (hit["collider"] as Node).name])
		_check_capsule_passage(space, "IREN: %s" % door[0], to_world * (door[1] as Vector3), to_world * (door[2] as Vector3))
	for marker: String in ["SelkaRestMarker", "AruRestMarker", "MenaRestMarker", "MenaGlassMarker"]:
		if _iren.get_node_or_null(marker) == null:
			_fail("IREN: no %s" % marker)
	var lava_meshes := _iren.find_children("*", "MeshInstance3D", true, false).filter(func(node: Node) -> bool: return node.has_meta("caldera_lava_surface"))
	if lava_meshes.size() != 4:
		_fail("IREN: three lava beds and the family immersion well are not all present")
	for problem in ClearZones.audit(_iren):
		_fail("IREN layout: %s" % problem)
	print("ok   IREN: household rooms, molten resting fixtures and a front door on the shared Highline")


## Aro: both public/private outside doors and all three internal passages take
## the real player capsule.  The service descent has a continuous sloping
## floor, its lower end is sealed, and every operator/home fixture is present.
func _check_aro(space: PhysicsDirectSpaceState3D) -> void:
	var to_world := _aro.global_transform
	for door: Array in [
		["thermal works entrance", Vector3(-4.9, 1.2, 8.3), Vector3(-4.9, 1.2, 5.0)],
		["home entrance", Vector3(10.3, 1.2, 2.2), Vector3(7.0, 1.2, 2.2)],
		["valve workshop", Vector3(-4.0, 1.2, 0.8), Vector3(-4.0, 1.2, -1.8)],
		["family service passage", Vector3(-0.8, 1.2, -3.0), Vector3(1.8, 1.2, -3.0)],
		["home molten room", Vector3(4.5, 1.2, 0.8), Vector3(4.5, 1.2, -1.8)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("ARO: the %s is blocked by %s" % [door[0], (hit["collider"] as Node).name])
		_check_capsule_passage(space, "ARO: %s" % door[0], to_world * (door[1] as Vector3), to_world * (door[2] as Vector3))
	# The ramp drops 2.4 m over four metres.  Sample its centreline vertically;
	# every point must find the same authored shell and match the designed grade.
	for i in 9:
		# Stay just inside the rounded SuperEgg ends.  Those curved noses are
		# visual edge softening, not part of the ramp's standing route.
		var fraction := lerpf(0.04, 0.96, float(i) / 8.0)
		var local_z := lerpf(-1.6, -5.6, fraction)
		var expected_y := lerpf(0.0, -2.4, fraction)
		var ray_from := to_world * Vector3(-6.1, expected_y + 0.8, local_z)
		var ray_to := to_world * Vector3(-6.1, expected_y - 0.5, local_z)
		var ramp_hit := _ray(space, ray_from, ray_to, [_ground.get_rid(), (_plinths["ARO"] as CollisionObject3D).get_rid()])
		if ramp_hit.is_empty() or ramp_hit["collider"] != _aro:
			_fail("ARO: service descent has no authored floor at %.0f%%" % (fraction * 100.0))
		elif absf(float((to_world.affine_inverse() * (ramp_hit["position"] as Vector3)).y) - expected_y) > 0.13:
			_fail("ARO: service descent is off grade at %.0f%%" % (fraction * 100.0))
	for marker: String in ["L1DescentMarker", "TovanControlMarker", "MiruWorkMarker", "KesWorkMarker", "TovanRestMarker", "MiruRestMarker", "KesRestMarker"]:
		if _aro.get_node_or_null(marker) == null:
			_fail("ARO: no %s" % marker)
	for fixture: String in ["L1Bulkhead", "EmergencyBell"]:
		if _aro.find_child(fixture, true, false) == null:
			_fail("ARO: no %s" % fixture)
	var lava_meshes := _aro.find_children("*", "MeshInstance3D", true, false).filter(func(node: Node) -> bool: return node.has_meta("caldera_lava_surface"))
	if lava_meshes.size() != 4:
		_fail("ARO: three lava beds and the shared immersion well are not all present")
	for problem in ClearZones.audit(_aro):
		_fail("ARO layout: %s" % problem)
	print("ok   ARO: separate works/home entries, valve rooms, household fixtures and protected L1 descent")


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
		# The lobby is bounded by another partition at z=1.3, so keep this
		# capsule sweep local to the gem-store threshold rather than sampling
		# that separate wall as part of the doorway.
		["gem store door", Vector3(0.0, 1.2, 1.8), Vector3(0.0, 1.2, 2.8)],
		["home door", Vector3(7.5, up + 1.2, FireCalderaOren.HOME_DOOR_Z), Vector3(4.5, up + 1.2, FireCalderaOren.HOME_DOOR_Z)],
	]:
		var hit := _ray(space, to_world * (door[1] as Vector3), to_world * (door[2] as Vector3), [])
		if not hit.is_empty():
			_fail("OREN: the %s is blocked by %s" % [door[0], (hit["collider"] as Node).name])
		_check_capsule_passage(space, "OREN: %s" % door[0], to_world * (door[1] as Vector3), to_world * (door[2] as Vector3))
	# Each floor is where the height query says it is.
	for local: Vector2 in [Vector2(-5.0, 3.5), Vector2(4.0, 3.5), Vector2(-5.0, -3.0), Vector2(3.0, -3.0), Vector2(-4.0, 0.3), Vector2(3.2, 0.3), Vector2(7.5, -5.5), Vector2(7.5, -2.5), Vector2(7.5, 1.2), Vector2(-6.0, -6.5)]:
		var world := to_world * Vector3(local.x, 6.0 if local.x < 6.5 or local.y < -4.6 else 9.0, local.y)
		var plan := Vector2(world.x, world.z)
		var hit := _ray(space, world, Vector3(world.x, datum - 1.0, world.z), [])
		# Oren is a lower-bowl building and the shared Highline may cross above
		# its exterior home ramp. Look through that upper civic floor when
		# proving Oren's own authored walking surface.
		if not hit.is_empty() and (hit["collider"] as Node).name == "CalderaHighline":
			hit = _ray(space, world, Vector3(world.x, datum - 1.0, world.z), [hit["rid"]])
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
		var fins := home.find_children("*", "MeshInstance3D", true, false).filter(func(node: Node) -> bool: return node.has_meta("dichroic_fin"))
		if fins.size() < 18:
			_fail("OREN: the close-spaced dichroic fin screen is missing")
		elif (fins[0] as MeshInstance3D).mesh.get_aabb().size.x > 0.05:
			_fail("OREN: dichroic fins became broad blocks instead of thin SuperEgg slabs")
	# The roof terrace stands at its roof's top, and the lift serves it.
	var roof_hit := _ray(space, to_world * Vector3(-3.0, 12.0, 0.0), to_world * Vector3(-3.0, 6.0, 0.0), [])
	if roof_hit.is_empty() or absf(float(roof_hit["position"].y) - datum - up - FireCalderaOren.roof_top()) > 0.06:
		_fail("OREN: the roof terrace is not a floor at its roof's top")
	# Renewal: every canopy support stands on the quay's deck, not over lava.
	if _renewal != null:
		if _renewal.get_node_or_null("../RENEWALRetaining") != null or not _renewal.find_children("*", "MeshInstance3D", true, false).filter(func(node: Node) -> bool: return node.name == "Windbreak").is_empty():
			_fail("RENEWAL: the landward entry is still obstructed by retaining or glass panels")
		var deck: StaticBody3D = _plinths["RENEWAL"]
		for side: float in [-1.0, 1.0]:
			for i in FireCalderaRenewal.RIBS:
				var z := lerpf(FireCalderaRenewal.BACK_Z, FireCalderaRenewal.FRONT_Z, float(i) / float(FireCalderaRenewal.RIBS - 1))
				var foot := _renewal.global_transform * Vector3(side * (FireCalderaRenewal.SPAN * 0.5 + 0.4), 0.0, z)
				var below := _ray(space, foot + Vector3(0, 0.1, 0), foot - Vector3(0, 0.5, 0), _building_rids())
				if below.is_empty() or below["collider"] != deck:
					_fail("RENEWAL: a canopy support at z %.1f has no deck under its foot" % z)
	# Kel: its doors open at their floors; the dock, ramps and landing meet
	# the height query; the layout audit of both bodies.
	if _kel != null:
		var kel_world := _kel.global_transform
		var kel_datum := float(_lines["KEL"]["datum"])
		for door: Array in [
			["gallery door", Vector3(-3.2, 1.2, 9.0), Vector3(-3.2, 1.2, 5.5)],
			["dock door", Vector3(FireCalderaKel.DOCK_DOOR_X, FireCalderaKel.DOCK + 1.2, -9.0), Vector3(FireCalderaKel.DOCK_DOOR_X, FireCalderaKel.DOCK + 1.2, -5.0)],
			["descent door", Vector3(FireCalderaKel.DESCENT_DOOR_X, 1.2, -1.4), Vector3(FireCalderaKel.DESCENT_DOOR_X, 1.2, 0.4)],
			["staff door", Vector3(FireCalderaKel.STAFF_DOOR_X, 1.2, 0.4), Vector3(FireCalderaKel.STAFF_DOOR_X, 1.2, -1.4)],
			["home door", Vector3(11.0, FireCalderaKel.RESIDENCE + 1.2, FireCalderaKel.HOME_DOOR_Z), Vector3(8.0, FireCalderaKel.RESIDENCE + 1.2, FireCalderaKel.HOME_DOOR_Z)],
		]:
			var through := _ray(space, kel_world * (door[1] as Vector3), kel_world * (door[2] as Vector3), [])
			if not through.is_empty():
				_fail("KEL: the %s is blocked by %s" % [door[0], (through["collider"] as Node).name])
			_check_capsule_passage(space, "KEL: %s" % door[0], kel_world * (door[1] as Vector3), kel_world * (door[2] as Vector3))
		for local: Vector2 in [Vector2(1.0, -5.0), Vector2(7.5, -4.0), Vector2(2.7, -1.7), Vector2(10.8, -8.0), Vector2(10.5, -4.0), Vector2(-5.0, 3.0)]:
			var top := kel_world * Vector3(local.x, 12.0 if local.x > 9.5 else 4.6, local.y)
			var hit := _ray(space, top, Vector3(top.x, kel_datum - 1.0, top.z), [])
			# Kel deliberately occupies the lower bowl beneath the Highline.  Its
			# floor proof must look past that overhead civic deck, just as it looks
			# past a roof when checking a room below.
			if not hit.is_empty() and (hit["collider"] as Node).name == "CalderaHighline":
				hit = _ray(space, top, Vector3(top.x, kel_datum - 1.0, top.z), [hit["rid"]])
			var expected := FireCalderaPlan.level_height(FireCalderaPlan.plot("KEL"), Vector2(top.x, top.z))
			if is_nan(expected):
				expected = 0.0
			if hit.is_empty() or absf(float(hit["position"].y) - kel_datum - expected) > 0.06:
				_fail("KEL: the floor at %s is %s, the height query %.2f" % [str(local), "none" if hit.is_empty() else "%.2f" % (float(hit["position"].y) - kel_datum), expected])
		for problem in ClearZones.audit(_kel):
			_fail("KEL layout: %s" % problem)
		var kel_home := _kel.get_node_or_null("KelHome") as StaticBody3D
		if kel_home != null:
			for problem in ClearZones.audit(kel_home):
				_fail("KEL home layout: %s" % problem)
		# The ramp and landing covers are extended SuperEgg slabs clipped on
		# one vertical junction plane. Their centre surfaces and their visible
		# side edges must meet exactly; matching height alone can still leave the
		# level slab visibly wider because each rounded solid narrows near its end.
		var ramp_cover := _kel.get_node_or_null("BridgeCover/Slope/RampCoverSlab") as CSGMesh3D
		var landing_cover := _kel.get_node_or_null("BridgeCover/Level/LandingCoverSlab") as CSGMesh3D
		if ramp_cover == null or landing_cover == null:
			_fail("KEL: the two clipped bridge-cover slabs are missing")
		else:
			var bridge_ramp: Rect2 = (FireCalderaPlan.plot("KEL")["levels"] as Array)[3]["rect"]
			# The slab's local Z is longer than its horizontal plan run after
			# rotation; solve the local coordinate whose transformed Z is exactly
			# the shared vertical cut plane.
			var local_join_z := (bridge_ramp.end.y - ramp_cover.position.z) / ramp_cover.basis.z.z
			var at_join := ramp_cover.transform * Vector3(0.0, 0.0, local_join_z)
			if absf(at_join.y - landing_cover.position.y) > 0.001:
				_fail("KEL: bridge-cover cut edges differ in height by %.3f m" % absf(at_join.y - landing_cover.position.y))
			var ramp_half := ramp_cover.mesh.get_aabb().size * 0.5
			var level_half := landing_cover.mesh.get_aabb().size * 0.5
			var level_join_z := bridge_ramp.end.y - landing_cover.position.z
			# Both slabs deliberately share the ramp slab's authored exponent.
			var epsilon := CalderaShell.soft_epsilon(Vector2(bridge_ramp.size.x * 0.5 + 0.1, ramp_half.z - 0.4), Vector2(ramp_half.x, ramp_half.z))
			var ramp_join_width := ramp_half.x * FireCalderaKel._superellipse_section_factor(local_join_z / ramp_half.z, epsilon)
			var level_join_width := level_half.x * FireCalderaKel._superellipse_section_factor(level_join_z / level_half.z, epsilon)
			if absf(ramp_join_width - level_join_width) > 0.001:
				_fail("KEL: bridge-cover cut edges differ in half-width by %.3f m" % absf(ramp_join_width - level_join_width))
		print("ok   KEL: doors clear at their floors, dock and bridge meet the height query")
	var oren_lift := _oren.get_node_or_null("Lift") as CalderaLift
	if oren_lift == null:
		_fail("OREN: no lift to the terrace")
	else:
		if oren_lift.destination_labels() != ["Roof", "Home", "Ground"]:
			_fail("OREN: lift destinations are not the stable Roof, Home, Ground order")
		var canopy := _oren.get_node_or_null("LiftCanopy") as MeshInstance3D
		var roof_stop := FireCalderaOren.UPPER + FireCalderaOren.roof_top()
		if canopy == null or canopy.position.y - 0.05 - roof_stop < 2.4:
			_fail("OREN: lift canopy does not clear the roof stop by 2.4 m")
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
		_check_capsule_passage(space, "NAHL: %s" % door[0], to_world * (door[1] as Vector3), to_world * (door[2] as Vector3))
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


## A ray through the centre can miss an open door leaf that occupies the side
## of the aperture but still catches the player's 0.4 m-radius body. Sample the
## middle 60% of the approach with the actual standing capsule; endpoints are
## omitted because these proof routes intentionally extend into furnished rooms.
func _check_capsule_passage(space: PhysicsDirectSpaceState3D, label: String, from: Vector3, to: Vector3) -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	for fraction: float in [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]:
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis(), from.lerp(to, fraction))
		query.collision_mask = 1
		query.exclude = [_ground.get_rid()]
		for plinth in _plinths.values():
			query.exclude.append((plinth as CollisionObject3D).get_rid())
		var hits := space.intersect_shape(query, 4)
		if hits.is_empty():
			continue
		var collider := hits[0]["collider"] as Node
		_fail("%s catches the player capsule at %.0f%% on %s (shape %s)" % [label, fraction * 100.0, collider.name if collider != null else "unknown collision", str(hits[0].get("collider_shape", "?"))])
		return


## CSG walls own physics RIDs that are not the shell body's RID. Skip any such
## envelope hit when a proof ray is specifically checking the plinth below it.
func _floor_ray_past_shell(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var excluded := _building_rids()
	if _highline != null:
		excluded.append(_highline.get_rid())
	for _i in 16:
		var hit := _ray(space, from, to, excluded)
		if hit.is_empty():
			return hit
		var collider := hit["collider"] as Node
		var ours := false
		for building: StaticBody3D in [_shell, _nahl, _oren, _renewal, _kel, _vara, _civic, _iren, _aro, _highline]:
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
		"aerial": [Vector2(0.0, -138.0), 108.0, Vector2(0.0, 0.0), 3.0],
		"lip_gate": [Vector2(0.0, -120.0), 7.0, Vector2(22.0, -96.0), 4.0],
		"arrival_gallery": [Vector2(34.0, -116.0), 12.0, Vector2(0.0, -86.0), 7.0],
		"inn_at_arrival": [Vector2(46.0, -118.0), 12.0, Vector2(22.0, -98.5), 5.0],
		"guest_service_pier": [Vector2(39.0, -111.0), 5.0, Vector2(22.0, -98.5), 1.0],
		"renewal_public": [Vector2(-91.0, -24.0), 12.0, Vector2(-58.7, -5.5), 2.0],
		"renewal_aerial": [Vector2(-94.0, 20.0), 30.0, Vector2(-58.7, -5.5), 4.0],
		"renewal_immersion": [Vector2(-39.0, -4.0), 6.0, Vector2(-58.7, -5.5), 1.0],
		"highline_oblique": [Vector2(-88.0, -68.0), 28.0, Vector2(-5.0, 5.0), 5.0],
		"civic_bowl": [Vector2(28.0, 104.0), 18.0, Vector2(0.0, 72.0), 5.0],
		"kel_under_highline": [Vector2(40.0, -40.0), 9.0, Vector2(57.6, -21.0), 3.0],
		"kel_upper_frontage": [Vector2(82.0, -43.0), 16.0, Vector2(64.0, -19.0), 10.0],
		"oren_terrace": [Vector2(57.0, -62.0), 10.0, Vector2(41.8, -47.4), 7.0],
		"guest_cutaway": [Vector2(46.0, -116.0), 15.0, Vector2(22.0, -98.5), 1.0],
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
		"oren_lift_top": [Vector3(11.5, 9.2, 8.0), Vector3(7.62, 9.2, 3.7)],
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
		"renewal_promenade": [Vector3(-9.0, 1.7, -2.8), Vector3(0.0, -0.5, -2.8)],
		"renewal_steps": [Vector3(-6.0, 1.7, -0.5), Vector3(1.0, -1.8, 5.0)],
		"renewal_landing": [Vector3(6.0, 1.7, 5.5), Vector3(-3.0, 0.5, -5.5)],
		"renewal_aerial": [Vector3(16.0, 15.0, -14.0), Vector3(0.0, 0.0, 3.0)],
		"renewal_from_lava": [Vector3(0.0, 1.0, 22.0), Vector3(0.0, 1.0, 0.0)],
	}
	for name: String in renewal:
		var pose: Array = renewal[name]
		camera.global_position = _renewal.global_transform * (pose[0] as Vector3)
		camera.look_at(_renewal.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	var kel := {
		"kel_front": [Vector3(-2.0, 1.7, 18.0), Vector3(0.0, 3.5, 0.0)],
		"kel_back": [Vector3(4.0, 3.5, -18.0), Vector3(2.0, 3.5, -6.0)],
		"kel_aerial": [Vector3(18.0, 16.0, 14.0), Vector3(0.0, 3.0, -1.0)],
		"kel_gallery": [Vector3(-0.2, 1.7, 6.5), Vector3(-7.0, 1.4, 2.5)],
		"kel_workshop": [Vector3(-1.5, 2.0, -1.3), Vector3(-7.5, 1.0, -6.5)],
		"kel_dock": [Vector3(4.8, 1.25 + 1.7, -1.6), Vector3(1.5, 1.3, -7.0)],
		"kel_home": [Vector3(8.6, 5.2 + 1.6, -1.6), Vector3(2.5, 5.2 + 0.4, -6.5)],
		"kel_bridge_join": [Vector3(15.0, 7.6, -1.8), Vector3(10.8, 7.8, -4.9)],
	}
	for name: String in kel:
		var pose: Array = kel[name]
		camera.global_position = _kel.global_transform * (pose[0] as Vector3)
		camera.look_at(_kel.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	var vara := {
		"vara_front": [Vector3(-1.0, 1.7, 19.0), Vector3(0.0, 2.2, 0.0)],
		"vara_court": [Vector3(1.5, 1.7, 6.5), Vector3(1.0, 1.2, -1.0)],
		"vara_studio": [Vector3(-2.0, 1.65, 5.4), Vector3(-7.0, 1.1, -3.8)],
		"vara_hot_shop": [Vector3(-5.0, 1.7, -0.8), Vector3(-6.5, 1.0, -5.4)],
		"vara_home": [Vector3(5.0, 1.65, 5.6), Vector3(6.5, 0.8, -3.6)],
		"vara_aerial": [Vector3(17.0, 15.0, 16.0), Vector3(0.0, 0.8, 0.0)],
	}
	for name: String in vara:
		var pose: Array = vara[name]
		camera.global_position = _vara.global_transform * (pose[0] as Vector3)
		camera.look_at(_vara.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	var civic := {
		"civic_front": [Vector3(0.0, 3.6, 23.0), Vector3(0.0, 4.0, 0.0)],
		"civic_portal": [Vector3(0.0, 1.7, 10.8), Vector3(0.0, 3.5, 0.0)],
		"civic_terrarium": [Vector3(-5.5, 2.0, 5.6), Vector3(0.0, 3.4, 0.0)],
		"civic_council": [Vector3(-4.9, 1.7, 5.5), Vector3(-8.0, 1.3, 0.0)],
		"civic_school": [Vector3(5.3, 1.7, 6.1), Vector3(8.2, 1.2, 3.8)],
		"civic_ramp": [Vector3(-6.2, 2.0, 5.8), Vector3(-9.0, 2.5, -1.0)],
		"civic_upper": [Vector3(7.5, 5.5, -3.2), Vector3(0.0, 5.2, -1.0)],
		"civic_aerial": [Vector3(22.0, 18.0, 19.0), Vector3(0.0, 3.8, 0.0)],
	}
	for name: String in civic:
		var pose: Array = civic[name]
		camera.global_position = _civic.global_transform * (pose[0] as Vector3)
		camera.look_at(_civic.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	var iren := {
		"iren_front": [Vector3(0.0, 1.8, 14.0), Vector3(0.0, 1.7, 0.0)],
		"iren_receiving": [Vector3(-1.2, 1.65, 3.7), Vector3(0.0, 1.0, 0.8)],
		"iren_resting": [Vector3(-1.5, 1.65, -0.9), Vector3(0.0, 0.7, -3.5)],
		"iren_bridge": [Vector3(-2.5, 2.4, 6.0), Vector3(-8.5, 1.0, 3.3)],
		"iren_aerial": [Vector3(12.0, 12.0, 12.0), Vector3(-2.0, 0.8, 1.0)],
	}
	for name: String in iren:
		var pose: Array = iren[name]
		camera.global_position = _iren.global_transform * (pose[0] as Vector3)
		camera.look_at(_iren.global_transform * (pose[1] as Vector3), Vector3.UP)
		for _i in 4:
			await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_shots, name])
		print("saved %s/%s.png" % [_shots, name])
	var aro := {
		"aro_front": [Vector3(0.0, 2.0, 18.0), Vector3(0.0, 1.8, 0.0)],
		"aro_control": [Vector3(-4.0, 1.7, 5.4), Vector3(-4.0, 1.2, 0.0)],
		"aro_valve_wall": [Vector3(-4.0, 1.7, 4.0), Vector3(-4.0, 1.4, -0.1)],
		"aro_workshop": [Vector3(-2.0, 1.7, -1.0), Vector3(-3.0, 1.0, -4.5)],
		"aro_descent": [Vector3(-4.6, 1.8, -1.0), Vector3(-6.1, -1.0, -4.5)],
		"aro_home": [Vector3(4.5, 1.7, 5.3), Vector3(4.5, 0.8, -3.5)],
		"aro_aerial": [Vector3(16.0, 14.0, 16.0), Vector3(0.0, 0.0, 0.0)],
	}
	for name: String in aro:
		var pose: Array = aro[name]
		camera.global_position = _aro.global_transform * (pose[0] as Vector3)
		camera.look_at(_aro.global_transform * (pose[1] as Vector3), Vector3.UP)
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
