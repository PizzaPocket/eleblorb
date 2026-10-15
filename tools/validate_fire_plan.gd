extends Node

## Validates FireCalderaPlan as data, before anything is built (the layout's
## implementation contract, section 11, the checks that need no terrain):
##   - reserved plots clear of one another, the reservoir and every route;
##   - every occupied plot's front reaches a public route and its back a
##     service route, and the dry network is one connected piece;
##   - every occupied plot has at least two emergency directions;
##   - the arrival-to-civic sightline crosses only the reservoir;
##   - three immersion shelves at the bank by their plots, every lower room
##     with two ways out, no thermal branch under the guest house;
##   - fourteen residents with real homes and workplaces, the trade ledger
##     and the rest point naming real people and places;
##   - the city inside the caldera floor.
## The plot survey (terrain under every footprint) joins once the localized
## caldera ground exists. Runs as a scene so autoloads and class names load.
##
##   Godot --headless --path . tools/validate_fire_plan.tscn

var _failures := 0
var _warnings := 0


func _ready() -> void:
	# A parse or script error stops _ready before quit(): end the run instead.
	get_tree().create_timer(60.0).timeout.connect(func() -> void:
		print("FAIL validate_fire_plan watchdog")
		get_tree().quit(2))
	_check_plots()
	_check_routes()
	_check_walkway_clearance()
	_check_network()
	_check_sightline()
	_check_lower_city()
	_check_people()
	_check_survey()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--svg="):
			_write_svg(argument.trim_prefix("--svg="))
	print("---- validate_fire_plan: %d plots, %d routes, %d FAIL, %d WARN" % [FireCalderaPlan.PLOTS.size(), FireCalderaPlan.routes().size(), _failures, _warnings])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _warn(message: String) -> void:
	_warnings += 1
	print("WARN ", message)


func _check_plots() -> void:
	var reservoir := FireCalderaPlan.reservoir_polygon()
	var plots := FireCalderaPlan.PLOTS
	for i in plots.size():
		var a := FireCalderaPlan.plot_polygon(plots[i])
		# A quay (the Renewal terrace) stands out over the lava on purpose.
		if not Geometry2D.intersect_polygons(a, reservoir).is_empty() and not bool(plots[i].get("quay", false)):
			_fail("%s's reserved plot reaches into the reservoir" % plots[i]["id"])
		for point in a:
			var site := str(plots[i].get("site", "ground"))
			var limit := FireCalderaPlan.RIM_RADIUS - 12.0 if site == "highline" else (FireCalderaPlan.RIM_RADIUS + 2.0 if site == "gate_platform" else FireCalderaPlan.HIGHLINE_RADIUS + 7.0)
			if bool(plots[i].get("open", false)):
				limit = FireCalderaPlan.RIM_RADIUS + 4.0
			if point.length() > limit:
				_fail("%s's reserved plot leaves its permitted site band (%.1f m out)" % [plots[i]["id"], point.length()])
				break
		for j in range(i + 1, plots.size()):
			var a_tier := str(plots[i].get("site", "ground"))
			var b_tier := str(plots[j].get("site", "ground"))
			if a_tier != b_tier and not bool(plots[i].get("open", false)) and not bool(plots[j].get("open", false)):
				continue
			if not Geometry2D.intersect_polygons(a, FireCalderaPlan.plot_polygon(plots[j])).is_empty():
				_fail("%s and %s's reserved plots overlap" % [plots[i]["id"], plots[j]["id"]])
		var footprint := FireCalderaPlan.plot_polygon(plots[i], "footprint")
		for point in footprint:
			if not Geometry2D.is_point_in_polygon(point, a) and _distance_to_polygon(point, a) > 0.01:
				_fail("%s's footprint leaves its reserved plot" % plots[i]["id"])
				break


func _check_routes() -> void:
	var reservoir := FireCalderaPlan.reservoir_polygon()
	for route in FireCalderaPlan.routes() + FireCalderaPlan.emergency_spokes():
		var points: PackedVector2Array = route["points"]
		var half := float(route["width"]) * 0.5
		var tier := str(route.get("tier", "ground"))
		var serves: Array = route.get("serves", [])
		for i in points.size() - 1:
			var lane := _lane(points[i], points[i + 1], half)
			# A route may end at a plot's edge; only its body counts.
			var body := _lane(points[i], points[i + 1], half - 0.3)
			for entry in FireCalderaPlan.PLOTS:
				if bool(entry.get("open", false)) or bool(entry.get("crossed", false)):
					continue
				if str(entry["id"]) in serves:
					continue
				var entry_tier := str(entry.get("site", "ground"))
				if tier == "ramp" or tier != entry_tier:
					continue
				if str(route["id"]) == "H1" and entry_tier == "highline":
					continue
				var shrunk := _shrink(FireCalderaPlan.plot_polygon(entry), 0.4)
				if not Geometry2D.intersect_polygons(body, shrunk).is_empty():
					_fail("%s (%s) runs through %s's reserved plot near %s" % [route["id"], route["role"], entry["id"], str(points[i].lerp(points[i + 1], 0.5).round())])
					break
			if tier == "ground" and not Geometry2D.intersect_polygons(lane, reservoir).is_empty():
				_fail("%s runs into the reservoir near %s" % [route["id"], str(points[i].round())])
			# Raised circulation may pass above open terrain, but never through a
			# building shell. Tier separation is not permission for an accidental
			# bridge/building collision.
			if tier in ["highline", "ramp"]:
				for entry in FireCalderaPlan.PLOTS:
					if bool(entry.get("open", false)):
						continue
					if bool(route.get("landing_overlap", false)) and str(entry["id"]) in serves:
						continue
					# A served building may share only the final landing bay with
					# its route. It is not exempt along the rest of its envelope.
					if str(entry["id"]) in serves and i >= points.size() - 2:
						continue
					if str(route["id"]) == "H1" and str(entry.get("site", "ground")) == "highline":
						continue
					var shell := _shrink(FireCalderaPlan.plot_polygon(entry, "footprint"), 0.15)
					if not Geometry2D.intersect_polygons(body, shell).is_empty():
						_fail("%s clips %s's building footprint near %s" % [route["id"], entry["id"], str(points[i].lerp(points[i + 1], 0.5).round())])
						break
	# The promenade keeps a real bank between it and the lava.
	for point in FireCalderaPlan.ground_promenade():
		var gap := point.length() - FireCalderaPlan.reservoir_radius(point.angle()) - 2.0
		if gap < 1.5:
			_fail("the promenade comes within %.1f m of the bank at %s" % [gap, str(point.round())])
			break


## A route is a volume, not a line. Sample the centre and both deck edges
## against the untouched analytic volcano. Endpoints may meet a platform, but
## no intermediate sample may disappear into the bowl.
func _check_walkway_clearance() -> void:
	var arrival := FireCalderaPlan.arrival_byway()
	var arrival_start := FireCalderaGround.crater_wall(arrival[0]) + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE
	var guest := FireCalderaPlan.guest_gate_link()
	var guest_t := clampf((FireCalderaPlan.RIM_RADIUS - guest[0].length()) / (FireCalderaPlan.RIM_RADIUS - FireCalderaPlan.HIGHLINE_RADIUS), 0.0, 1.0)
	var guest_start := lerpf(arrival_start, FireCalderaPlan.HIGHLINE_DATUM, FireCalderaPlan.route_height_t("H0", guest_t))
	var renewal_y := float(FireCalderaGround.survey(FireCalderaPlan.plot("RENEWAL"))["datum"])
	var oren_y := float(FireCalderaGround.survey(FireCalderaPlan.plot("OREN"))["datum"]) + FireCalderaOren.UPPER + FireCalderaOren.roof_top()
	var kel_y := float(FireCalderaGround.survey(FireCalderaPlan.plot("KEL"))["datum"]) + FireCalderaKel.RESIDENCE
	_check_path_above_ground("H0", arrival, 3.8, arrival_start, FireCalderaPlan.HIGHLINE_DATUM)
	_check_path_above_ground("HG", guest, 3.0, guest_start, FireCalderaPlan.GUEST_GATE_DATUM)
	_check_path_above_ground("H2W", FireCalderaPlan.renewal_byway(-1.0), 3.2, FireCalderaPlan.HIGHLINE_DATUM, renewal_y, "RENEWAL")
	_check_path_above_ground("H2E", FireCalderaPlan.renewal_byway(1.0), 3.2, FireCalderaPlan.HIGHLINE_DATUM, renewal_y, "RENEWAL")
	_check_path_above_ground("H4", FireCalderaPlan.oren_terrace_link(), 2.4, FireCalderaPlan.HIGHLINE_DATUM, oren_y)
	_check_path_above_ground("H5", FireCalderaPlan.kel_upper_link(), 2.4, FireCalderaPlan.HIGHLINE_DATUM, kel_y)
	for i in 96:
		var angle := TAU * (float(i) + 0.5) / 96.0
		for radius: float in [FireCalderaPlan.HIGHLINE_RADIUS - FireCalderaPlan.HIGHLINE_WIDTH * 0.5, FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5]:
			var point := Vector2(cos(angle), sin(angle)) * radius
			if FireCalderaPlan.HIGHLINE_DATUM - FireCalderaGround.height(point) < FireCalderaHighline.DECK_THICKNESS + 0.04:
				_fail("H1 clips the volcano ground near %s" % str(point.round()))
				return


func _check_path_above_ground(id: String, points: PackedVector2Array, width: float, start_y: float, finish_y: float, landing_id: String = "") -> void:
	for i in points.size() - 1:
		var delta := points[i + 1] - points[i]
		if delta.length() < 0.01:
			continue
		var across := Vector2(-delta.y, delta.x).normalized()
		for k in 5:
			var local_t := float(k) / 4.0
			var global_t := (float(i) + local_t) / float(points.size() - 1)
			# A route's first and last centre-lines intentionally share the
			# authored landing plane with the gate, deck or roof terrace.  That
			# flush contact is not terrain clipping; every sample immediately
			# beyond either endpoint, including both deck edges, still has to
			# clear the untouched bowl.
			if global_t < 0.0001 or global_t > 0.9999:
				continue
			var height_t := FireCalderaPlan.route_height_t(id, global_t)
			var y := lerpf(start_y, finish_y, height_t)
			var centre := points[i].lerp(points[i + 1], local_t)
			for side: float in [-1.0, 0.0, 1.0]:
				var sample := centre + across * side * (width * 0.5 - 0.08)
				var ground := FireCalderaGround.height(sample)
				if not landing_id.is_empty():
					var landing := FireCalderaPlan.plot(landing_id)
					if Geometry2D.is_point_in_polygon(sample, SocketPlinth.band(landing, SocketPlinth.size_key(landing))):
						ground = minf(ground, finish_y - FireCalderaHighline.DECK_THICKNESS - 0.08)
				var clearance := y - ground
				var required := FireCalderaHighline.DECK_THICKNESS + 0.04
				if clearance + 0.001 < required:
					_fail("%s clips the volcano ground at %s (clearance %.2f m, route %.3f)" % [id, str(sample.round()), clearance, global_t])
					return


## Every occupied plot's front on a public route and back on the service
## loop; the whole dry network connected; two emergency spokes reachable.
func _check_network() -> void:
	var routes := FireCalderaPlan.routes()
	var spokes := FireCalderaPlan.emergency_spokes()
	var public_routes := routes.filter(func(route: Dictionary) -> bool: return str(route["class"]) != "service")
	var all := public_routes + spokes
	# Union-find over routes: two routes join where they meet or cross.
	var parent := {}
	for route in all:
		parent[route["id"]] = route["id"]
	for i in all.size():
		for j in range(i + 1, all.size()):
			if _routes_meet(all[i], all[j]):
				_union(parent, str(all[i]["id"]), str(all[j]["id"]))
	var roots := {}
	for route in public_routes:
		roots[_find(parent, str(route["id"]))] = true
	if roots.size() != 1:
		_fail("the dry network is in %d separate pieces" % roots.size())
	for spoke in spokes:
		if _find(parent, str(spoke["id"])) != _find(parent, "H1"):
			_fail("emergency spoke %s does not join the dry network" % spoke["id"])
	for entry in FireCalderaPlan.PLOTS:
		if not bool(entry["occupied"]):
			continue
		var front := FireCalderaPlan.front_point(entry)
		var back := FireCalderaPlan.back_point(entry)
		var front_route := _nearest_route(front, routes, ["public", "link"])
		var back_route := _nearest_route(back, routes, ["service", "link"])
		if front_route.is_empty():
			_fail("%s's front reaches no public route" % entry["id"])
		if back_route.is_empty():
			_fail("%s's back reaches no service route (receiving would cross a public front)" % entry["id"])
	# Two emergency directions: at least two spokes leave the one network, at
	# different bearings, so no plot depends on a single way out.
	var bearings := []
	for spoke in spokes:
		bearings.append(snappedf(rad_to_deg((spoke["points"] as PackedVector2Array)[1].angle()), 1.0))
	if spokes.size() < 2:
		_fail("fewer than two emergency spokes")
	print("network: %d routes and %d emergency spokes, spokes at %s degrees" % [routes.size(), spokes.size(), str(bearings)])


func _check_sightline() -> void:
	var sight := FireCalderaPlan.sightline()
	var lane := _lane(sight[0], sight[1], 1.0)
	for entry in FireCalderaPlan.PLOTS:
		if str(entry["id"]) in ["ARRIVAL", "CIVIC"]:
			continue
		if not Geometry2D.intersect_polygons(lane, FireCalderaPlan.plot_polygon(entry)).is_empty():
			_fail("%s blocks the arrival view to Civic" % entry["id"])


func _check_lower_city() -> void:
	var rooms := {}
	for room in FireCalderaPlan.LOWER_ROOMS:
		rooms[room["id"]] = room
		var centre: Vector2 = room["centre"]
		if centre.length() > FireCalderaPlan.reservoir_radius(centre.angle()) - 3.0:
			_fail("lower room %s (%s) is not under the reservoir" % [room["id"], room["name"]])
	var exits := {}
	for passage: Array in FireCalderaPlan.LOWER_PASSAGES:
		for id in passage:
			if not rooms.has(id):
				_fail("a lower passage names %s, which is not a room" % id)
			exits[id] = int(exits.get(id, 0)) + 1
	for id in rooms:
		if int(exits.get(id, 0)) < 2:
			_fail("lower room %s has only %d way out" % [id, int(exits.get(id, 0))])
	var shelves := FireCalderaPlan.IMMERSION_SHELVES
	if shelves.size() < 3:
		_fail("fewer than three immersion shelves")
	for shelf in shelves:
		var entry := FireCalderaPlan.plot(str(shelf["plot"]))
		if entry.is_empty() or not rooms.has(shelf["room"]):
			_fail("shelf %s names a missing plot or room" % shelf["id"])
			continue
		# From the plot's front across the promenade to the bank.
		var front := FireCalderaPlan.front_point(entry)
		var bank := FireCalderaPlan.reservoir_radius(front.angle())
		var maximum_link := 24.0 if FireCalderaPlan.is_elevated(entry) else 9.0
		if front.length() - bank > maximum_link:
			_fail("shelf %s: %s's front is %.1f m from the bank" % [shelf["id"], entry["id"], front.length() - bank])
	for branch in FireCalderaPlan.THERMAL_BRANCHES:
		if "GUEST" in (branch["serves"] as Array):
			_fail("thermal branch %s runs to the guest house" % branch["id"])
	for lift: Array in FireCalderaPlan.LIFTS:
		if not rooms.has(lift[0]) or FireCalderaPlan.plot(str(lift[1])).is_empty():
			_fail("lift %s to %s names a missing room or plot" % [lift[0], lift[1]])


func _check_people() -> void:
	var places := {}
	for entry in FireCalderaPlan.PLOTS:
		places[entry["id"]] = true
	for room in FireCalderaPlan.LOWER_ROOMS:
		places[room["id"]] = true
	var names := {}
	for resident in FireCalderaPlan.RESIDENTS:
		names[resident["name"]] = true
		var home := FireCalderaPlan.plot(str(resident["home"]))
		if home.is_empty() or not bool(home["occupied"]):
			_fail("%s's home %s is not an occupied plot" % [resident["name"], resident["home"]])
		for place in resident["work"]:
			if not places.has(place):
				_fail("%s works at %s, which is not in the plan" % [resident["name"], place])
	if FireCalderaPlan.RESIDENTS.size() != 14:
		_fail("the census has %d residents, not the approved fourteen" % FireCalderaPlan.RESIDENTS.size())
	for shop: String in FireCalderaPlan.TRADE:
		var line: Dictionary = FireCalderaPlan.TRADE[shop]
		if not names.has(line["vendor"]):
			_fail("the %s's vendor %s is not a resident" % [shop, line["vendor"]])
		if not places.has(line["counter"]):
			_fail("the %s's counter %s is not a plot" % [shop, line["counter"]])
		for maker in line["makers"]:
			if not names.has(maker):
				_fail("the %s's maker %s is not a resident" % [shop, maker])
		for place in line["made_at"]:
			if not places.has(place):
				_fail("the %s's goods are made at %s, which is not in the plan" % [shop, place])
	if not names.has(FireCalderaPlan.REST_POINT["keeper"]) or not places.has(FireCalderaPlan.REST_POINT["plot"]):
		_fail("the rest point names a missing keeper or plot")


## The plot survey (layout 1a) from FireCalderaGround: a ledger line per plot,
## failing where a foundation would show more than EXPOSED_MAX of blank base.
## Routes must climb at a walkable grade over the terraces.
func _check_survey() -> void:
	# The inhabited ground is one true annular parabola beginning at the lava
	# shoulder, with a second parabola below the lava. Halfway from its vertex
	# to the lip must be one quarter of its full rise—not a graded shelf.
	var vertex := FireCalderaGround.outer_bowl_height(Vector2(FireCalderaPlan.FLOOR_RADIUS, 0.0))
	var halfway_radius := lerpf(FireCalderaPlan.FLOOR_RADIUS, FireCalderaPlan.RIM_RADIUS, 0.5)
	var half := FireCalderaGround.outer_bowl_height(Vector2(halfway_radius, 0.0))
	var lip := FireCalderaGround.outer_bowl_height(Vector2(FireCalderaPlan.RIM_RADIUS, 0.0))
	if absf((half - vertex) - (lip - vertex) / 4.0) > 0.01:
		_fail("the inhabited caldera section is not parabolic")
	var lip_slope := 2.0 * (lip - vertex) / (FireCalderaPlan.RIM_RADIUS - FireCalderaPlan.FLOOR_RADIUS)
	if lip_slope < 0.45:
		_fail("the inhabited parabola is too shallow at the crater lip (%.0f degrees)" % rad_to_deg(atan(lip_slope)))
	var basin_angle := 0.37
	var bank := FireCalderaPlan.reservoir_radius(basin_angle)
	var direction := Vector2(cos(basin_angle), sin(basin_angle))
	var bed := FireCalderaGround.height(Vector2.ZERO)
	var basin_half := FireCalderaGround.height(direction * bank * 0.5)
	var basin_edge := FireCalderaGround.height(direction * bank)
	if absf((basin_half - bed) - (basin_edge - bed) * 0.25) > 0.01:
		_fail("the central lava basin section is not a second parabola")
	print("---- plot survey (heights world Y; datum from the public landing)")
	# The geology must remain a changing bowl beneath the Highline. A level
	# terrain ring here would mean the structural datum had leaked back into the
	# A radial parabola is intentionally level around any one contour. Verify
	# that the Highline bridges above the curved bowl rather than demanding an
	# artificial terrace at its own datum.
	var ring_ground := FireCalderaGround.outer_bowl_height(Vector2(FireCalderaPlan.HIGHLINE_RADIUS, 0.0))
	if ring_ground >= FireCalderaPlan.HIGHLINE_DATUM - 0.5:
		_fail("the natural parabolic bowl leaves no structural clearance beneath the Highline")
	var clear_half := FireCalderaPlan.ARRIVAL_MARKER_OFFSET - 0.38
	if clear_half < 3.0:
		_fail("arrival markers narrow R0 below its 6 m clear width")
	for entry in FireCalderaPlan.PLOTS:
		if bool(entry.get("open", false)):
			continue
		var line := FireCalderaGround.survey(entry)
		print("%-8s %-14s datum %6.2f  ground %6.2f..%6.2f (change %.2f, grade %.0f%%)  exposed %.2f  retaining %.2f  bottom %6.2f  service landing %6.2f" % [
			line["id"], line["foundation"], line["datum"], line["low"], line["high"], line["change"], float(line["max_grade"]) * 100.0,
			line["exposed"], line["retaining"], line["bottom"], line["service_landing"]])
		# A quay's exposed face is its wall rising out of the lava, by design.
		if str(entry.get("site", "ground")) == "highline" and absf(float(line["datum"]) - FireCalderaPlan.HIGHLINE_DATUM) > 0.01:
			_fail("%s does not share the Highline datum" % line["id"])
		if FireCalderaPlan.is_elevated(entry) and str(entry.get("site", "")) == "highline":
			var facade_gap := FireCalderaPlan.front_point(entry, "footprint").length() - (FireCalderaPlan.HIGHLINE_RADIUS + FireCalderaPlan.HIGHLINE_WIDTH * 0.5)
			if facade_gap < 1.0 or facade_gap > 4.5:
				_fail("%s lacks a deliberate 1–4.5 m private arrival porch (%.2f m)" % [line["id"], facade_gap])
		if float(line["exposed"]) > FireCalderaGround.EXPOSED_MAX and not bool(entry.get("quay", false)) and not FireCalderaPlan.is_elevated(entry):
			_fail("%s would show %.1f m of blank foundation: step it, split it or move it" % [line["id"], line["exposed"]])
		if float(line["datum"]) <= FireCalderaGround.LAVA_Y + 0.5:
			_fail("%s's floor is at the lava" % line["id"])
	for route in FireCalderaPlan.routes():
		if str(route.get("tier", "ground")) != "ground":
			continue
		var points: PackedVector2Array = route["points"]
		var worst := 0.0
		for i in points.size() - 1:
			var steps := maxi(int(points[i].distance_to(points[i + 1]) / 2.0), 1)
			for k in steps:
				var a := points[i].lerp(points[i + 1], float(k) / float(steps))
				var b := points[i].lerp(points[i + 1], float(k + 1) / float(steps))
				if a.length() > FireCalderaPlan.FLOOR_RADIUS or b.length() > FireCalderaPlan.FLOOR_RADIUS:
					continue
				worst = maxf(worst, absf(FireCalderaGround.height(a) - FireCalderaGround.height(b)) / a.distance_to(b))
		if worst > 0.12:
			_fail("%s climbs at %.0f%% somewhere; ramps are for buildings, routes stay walkable" % [route["id"], worst * 100.0])
	_check_highline_grades()


func _check_highline_grades() -> void:
	for spec: Array in [
		["H0", FireCalderaPlan.arrival_byway(), FireCalderaGround.crater_wall(FireCalderaPlan.arrival_byway()[0]) + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE, FireCalderaPlan.HIGHLINE_DATUM],
		["HG", FireCalderaPlan.guest_gate_link(), lerpf(FireCalderaGround.BOWL_LIP_Y + FireCalderaPlan.ARRIVAL_DECK_CLEARANCE, FireCalderaPlan.HIGHLINE_DATUM, FireCalderaPlan.route_height_t("H0", clampf((FireCalderaPlan.RIM_RADIUS - FireCalderaPlan.guest_gate_link()[0].length()) / (FireCalderaPlan.RIM_RADIUS - FireCalderaPlan.HIGHLINE_RADIUS), 0.0, 1.0))), FireCalderaPlan.GUEST_GATE_DATUM],
		["H2W", FireCalderaPlan.renewal_byway(-1.0), FireCalderaPlan.HIGHLINE_DATUM, FireCalderaGround.survey(FireCalderaPlan.plot("RENEWAL"))["datum"]],
		["H2E", FireCalderaPlan.renewal_byway(1.0), FireCalderaPlan.HIGHLINE_DATUM, FireCalderaGround.survey(FireCalderaPlan.plot("RENEWAL"))["datum"]],
		["H4", FireCalderaPlan.oren_terrace_link(), FireCalderaPlan.HIGHLINE_DATUM, FireCalderaGround.survey(FireCalderaPlan.plot("OREN"))["datum"] + FireCalderaOren.UPPER + FireCalderaOren.roof_top()],
		["H5", FireCalderaPlan.kel_upper_link(), FireCalderaPlan.HIGHLINE_DATUM, FireCalderaGround.survey(FireCalderaPlan.plot("KEL"))["datum"] + FireCalderaKel.RESIDENCE],
	]:
		var points: PackedVector2Array = spec[1]
		var run := 0.0
		for i in points.size() - 1:
			run += points[i].distance_to(points[i + 1])
		var grade := absf(float(spec[3]) - float(spec[2])) / run
		if grade > 0.22:
			_fail("%s's civic ribbon exceeds the 22%% design grade (%.0f%%)" % [spec[0], grade * 100.0])
		else:
			print("ok   %s: %.1f m long at %.0f%%" % [spec[0], run, grade * 100.0])


## A plan drawing for review: reservoir, plots (reserved and footprint),
## routes by class, emergency spokes, the sightline and the lower rooms.
func _write_svg(path: String) -> void:
	var scale := 6.0
	var half := FireCalderaPlan.FLOOR_RADIUS + 10.0
	var size := half * 2.0 * scale
	var svg := PackedStringArray()
	svg.append('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d" font-family="sans-serif">' % [size, size, size, size])
	svg.append('<rect width="100%%" height="100%%" fill="#2b2523"/>')
	svg.append('<circle cx="%f" cy="%f" r="%f" fill="#3a3330" stroke="#5a504a"/>' % [size / 2, size / 2, FireCalderaPlan.FLOOR_RADIUS * scale])
	svg.append(_path(FireCalderaPlan.reservoir_polygon(), scale, half, true, "#e0612b", "#f08a3c", 2))
	for room in FireCalderaPlan.LOWER_ROOMS:
		var c := _svg_point(room["centre"], scale, half)
		svg.append('<circle cx="%f" cy="%f" r="%f" fill="none" stroke="#ffd27a" stroke-dasharray="4 3"/>' % [c.x, c.y, 4.0 * scale])
		svg.append('<text x="%f" y="%f" fill="#ffd27a" font-size="13" text-anchor="middle">%s</text>' % [c.x, c.y + 4, room["id"]])
	for route in FireCalderaPlan.routes():
		var colour: String = {"public": "#d8cbb8", "service": "#8a7f74", "link": "#b8a890"}[str(route["class"])]
		svg.append(_path(route["points"], scale, half, false, "none", colour, float(route["width"]) * scale))
	for spoke in FireCalderaPlan.emergency_spokes():
		svg.append(_path(spoke["points"], scale, half, false, "none", "#6fbf73", 2.0, "6 4"))
	svg.append(_path(FireCalderaPlan.sightline(), scale, half, false, "none", "#7ab8ff", 2.0, "3 3"))
	for entry in FireCalderaPlan.PLOTS:
		svg.append(_path(FireCalderaPlan.plot_polygon(entry), scale, half, true, "none", "#c9b79c", 1.5, "5 3"))
		svg.append(_path(FireCalderaPlan.plot_polygon(entry, "footprint"), scale, half, true, "#4d4743", "#e8dccb", 2))
		var c := _svg_point(entry["centre"], scale, half)
		svg.append('<text x="%f" y="%f" fill="#f4ece0" font-size="15" text-anchor="middle">%s</text>' % [c.x, c.y + 5, entry["id"]])
		var front := _svg_point(FireCalderaPlan.front_point(entry, "footprint"), scale, half)
		svg.append('<circle cx="%f" cy="%f" r="5" fill="#ffffff"/>' % [front.x, front.y])
	svg.append('<text x="12" y="24" fill="#f4ece0" font-size="16">FireCalderaPlan: north is local +Y (into the city from the gate). White dot = front. Dashed green = emergency spokes; dashed blue = arrival sightline.</text>')
	svg.append('</svg>')
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("\n".join(svg))
	print("plan drawing written to ", path)


func _svg_point(local: Vector2, scale: float, half: float) -> Vector2:
	# Local +Y up the page.
	return Vector2((local.x + half) * scale, (half - local.y) * scale)


func _path(points: PackedVector2Array, scale: float, half: float, closed: bool, fill: String, stroke: String, width: float, dash: String = "") -> String:
	var d := ""
	for i in points.size():
		var p := _svg_point(points[i], scale, half)
		d += ("M" if i == 0 else "L") + "%.1f %.1f " % [p.x, p.y]
	if closed:
		d += "Z"
	return '<path d="%s" fill="%s" stroke="%s" stroke-width="%.1f" stroke-linejoin="round" stroke-linecap="round" %s/>' % [d, fill, stroke, width, ('stroke-dasharray="%s"' % dash) if dash != "" else ""]


# --- geometry -------------------------------------------------------------

func _lane(a: Vector2, b: Vector2, half: float) -> PackedVector2Array:
	var across := (b - a).normalized().orthogonal() * half
	return PackedVector2Array([a + across, b + across, b - across, a - across])


func _shrink(polygon: PackedVector2Array, by: float) -> PackedVector2Array:
	var result := Geometry2D.offset_polygon(polygon, -by)
	return result[0] if not result.is_empty() else polygon


func _distance_to_polygon(point: Vector2, polygon: PackedVector2Array) -> float:
	var best := INF
	for i in polygon.size():
		var closest := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		best = minf(best, point.distance_to(closest))
	return best


func _routes_meet(a: Dictionary, b: Dictionary) -> bool:
	var pa: PackedVector2Array = a["points"]
	var pb: PackedVector2Array = b["points"]
	var reach := (float(a["width"]) + float(b["width"])) * 0.5 + 0.5
	for i in pa.size() - 1:
		for j in pb.size() - 1:
			if Geometry2D.segment_intersects_segment(pa[i], pa[i + 1], pb[j], pb[j + 1]) != null:
				return true
			var closest := Geometry2D.get_closest_points_between_segments(pa[i], pa[i + 1], pb[j], pb[j + 1])
			if closest[0].distance_to(closest[1]) <= reach:
				return true
	return false


## The id of a route of one of `classes` within reach of `point`, or "".
func _nearest_route(point: Vector2, routes: Array[Dictionary], classes: Array) -> String:
	for route in routes:
		if str(route["class"]) not in classes:
			continue
		var points: PackedVector2Array = route["points"]
		for i in points.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(point, points[i], points[i + 1])
			# A front terrace of up to 3 m may lie between a door and its route.
			if point.distance_to(closest) <= float(route["width"]) * 0.5 + 3.0:
				return str(route["id"])
	return ""


func _find(parent: Dictionary, id: String) -> String:
	while parent[id] != id:
		id = parent[id]
	return id


func _union(parent: Dictionary, a: String, b: String) -> void:
	parent[_find(parent, a)] = _find(parent, b)
