extends Node

## Plan validator for the Crossroads Fishing Village. It reads only
## FishingVillagePlan, so it runs before any structure is built:
##
##   Godot --headless --path . tools/validate_fishing_plan.tscn
##
## It runs as a scene, not with --script, so the autoloads the plan depends on
## (through LiquidEnvironment) compile; under --script it failed to compile and
## still exited 0.
##
## Exit code 1 if anything FAILs. The rules are layout section 10, item 3.

const REFERENCE_HEAD_BASE := 1.596
const GRID := 1.0

var _failures := 0
var _structures := {}


func _ready() -> void:
	for s in FishingVillagePlan.STRUCTURES:
		_structures[str(s["name"])] = s
	_check_census()
	_check_structures()
	_check_routes()
	_check_lanes_and_boats()
	_check_swim_exits()
	_check_separation()
	_check_portal()
	_check_trade()
	print("---- validate_fishing_plan: %d structures, %d routes, %d FAIL" % [_structures.size(), FishingVillagePlan.ROUTES.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _rect_of(name: String) -> Rect2:
	return _structures[name]["rect"]


## A route or lane as the rectangle-by-rectangle strip it sweeps.
func _strip_polygons(points: Array, width: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var along := (b - a).normalized()
		var side := Vector2(-along.y, along.x) * width * 0.5
		out.append(PackedVector2Array([a + side, b + side, b - side, a - side]))
	return out


func _rect_polygon(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


func _overlap_area(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var total := 0.0
	for piece in Geometry2D.intersect_polygons(a, b):
		var area := 0.0
		for i in piece.size():
			var p: Vector2 = piece[i]
			var q: Vector2 = piece[(i + 1) % piece.size()]
			area += p.x * q.y - q.x * p.y
		total += absf(area) * 0.5
	return total


func _attached(a: String, b: String) -> bool:
	for pair in FishingVillagePlan.ATTACHED:
		if (pair[0] == a and pair[1] == b) or (pair[0] == b and pair[1] == a):
			return true
	return false


func _check_census() -> void:
	if FishingVillagePlan.RESIDENTS.size() != 15:
		_fail("The census has %d residents, not fifteen" % FishingVillagePlan.RESIDENTS.size())
	var households := {}
	for name: String in FishingVillagePlan.RESIDENTS:
		households[FishingVillagePlan.RESIDENTS[name]] = true
	if households.size() != 5:
		_fail("The census has %d households, not five" % households.size())


func _check_structures() -> void:
	var names := _structures.keys()
	for name: String in names:
		var s: Dictionary = _structures[name]
		var owner := str(s["owner"])
		if owner != "village" and not FishingVillagePlan.RESIDENTS.has(owner):
			_fail("%s has owner %s, who is not a resident" % [name, owner])
		if str(s["program"]) == "":
			_fail("%s has no program" % name)
		if s["support"] == "piles":
			var r: Rect2 = s["rect"]
			var x := r.position.x
			while x <= r.end.x + 0.001:
				var z := r.position.y
				while z <= r.end.y + 0.001:
					if FishingVillagePlan.shelf_distance(Vector2(x, z)) > 0.01:
						_fail("%s stands on piles at (%.1f, %.1f), off every shelf" % [name, x, z])
						x = INF
						break
					z += GRID
				if x == INF:
					break
				x += GRID
	for i in names.size():
		for j in range(i + 1, names.size()):
			var a: String = names[i]
			var b: String = names[j]
			if _attached(a, b):
				continue
			var area := _overlap_area(_rect_polygon(_rect_of(a)), _rect_polygon(_rect_of(b)))
			if area > 0.05:
				_fail("%s and %s overlap by %.1f m²" % [a, b, area])


func _check_routes() -> void:
	for route in FishingVillagePlan.ROUTES:
		var name := str(route["name"])
		var min_width: float = FishingVillagePlan.CLASS_MIN_WIDTH[route["class"]]
		if float(route["width"]) < min_width - 0.001:
			_fail("%s is %.1f m wide, under its %s class minimum %.1f" % [name, route["width"], route["class"], min_width])
		if route["class"] == "gangway":
			var run := 0.0
			var points: Array = route["points"]
			for i in points.size() - 1:
				run += (points[i] as Vector2).distance_to(points[i + 1])
			var grade := rad_to_deg(atan2(float(route["rise"]), run))
			if grade > FishingVillagePlan.MAX_GANGWAY_DEGREES:
				_fail("%s is %.1f° (limit %.0f°)" % [name, grade, FishingVillagePlan.MAX_GANGWAY_DEGREES])
		if route["class"] != "gangway":
			var pts: Array = route["points"]
			for i in pts.size() - 1:
				var length: float = (pts[i] as Vector2).distance_to(pts[i + 1])
				var t := 0.0
				while t <= length + 0.001:
					var at: Vector2 = (pts[i] as Vector2).lerp(pts[i + 1], t / length)
					if FishingVillagePlan.shelf_distance(at) > 0.01:
						_fail("%s stands on piles at (%.1f, %.1f), off every shelf" % [name, at.x, at.y])
						t = INF
					else:
						t += 2.0
		var ends: Array = route["ends"]
		var strips := _strip_polygons(route["points"], float(route["width"]))
		for sname: String in _structures:
			if sname in ends:
				continue
			for strip in strips:
				if _overlap_area(strip, _rect_polygon(_rect_of(sname))) > 0.05:
					_fail("%s runs through %s" % [name, sname])
					break
		for end: String in ends:
			if not _structures.has(end) and not _route_named(end):
				_fail("%s ends at %s, which is not in the plan" % [name, end])
		# Every route must actually reach a destination.
		var reached := false
		var last: Vector2 = (route["points"] as Array)[-1]
		var first: Vector2 = (route["points"] as Array)[0]
		for end: String in ends:
			if _structures.has(end):
				var grown := _rect_of(end).grow(0.6)
				if grown.has_point(last) or grown.has_point(first):
					reached = true
			elif _route_named(end):
				reached = true
		if not reached:
			_fail("%s ends in open water, short of %s" % [name, ", ".join(PackedStringArray(ends))])


func _route_named(name: String) -> bool:
	for route in FishingVillagePlan.ROUTES:
		if route["name"] == name:
			return true
	return false


func _lane(name: String) -> Dictionary:
	for lane in FishingVillagePlan.LANES:
		if lane["name"] == name:
			return lane
	return {}


func _check_lanes_and_boats() -> void:
	for lane in FishingVillagePlan.LANES:
		var strips := _strip_polygons(lane["points"], float(lane["width"]))
		for sname: String in _structures:
			for strip in strips:
				if _overlap_area(strip, _rect_polygon(_rect_of(sname))) > 0.05:
					_fail("Structure %s stands in the %s lane" % [sname, lane["name"]])
					break
		for route in FishingVillagePlan.ROUTES:
			if route["class"] == "gangway":
				continue
			for rs in _strip_polygons(route["points"], float(route["width"])):
				for strip in strips:
					if _overlap_area(strip, rs) > 0.05:
						_fail("Route %s crosses the %s lane" % [route["name"], lane["name"]])
	for boat in FishingVillagePlan.BOATS:
		var name := str(boat["name"])
		if not FishingVillagePlan.RESIDENTS.has(str(boat["owner"])):
			_fail("%s has no resident owner" % name)
		if _lane(str(boat["lane"])).is_empty():
			_fail("%s has no lane" % name)
			continue
		var hull := _rect_polygon(boat["berth"])
		for sname: String in _structures:
			var s: Dictionary = _structures[sname]
			if s["support"] == "slip" and sname == "BoatwrightSlip" and name == "RepairBoat":
				continue
			if _overlap_area(hull, _rect_polygon(_rect_of(sname))) > 0.05:
				_fail("%s's berth overlaps %s" % [name, sname])
		for lane in FishingVillagePlan.LANES:
			if lane["name"] == boat["lane"]:
				continue
			for strip in _strip_polygons(lane["points"], float(lane["width"])):
				if _overlap_area(hull, strip) > 0.05:
					_fail("%s's berth lies in the %s lane, not its own" % [name, lane["name"]])
		for other in FishingVillagePlan.BOATS:
			if other["name"] != name and _overlap_area(hull, _rect_polygon(other["berth"])) > 0.05:
				_fail("%s's berth overlaps %s's" % [name, other["name"]])
		# The berth must open onto its own lane.
		var near := false
		for strip in _strip_polygons(_lane(str(boat["lane"]))["points"], float(_lane(str(boat["lane"]))["width"])):
			if Geometry2D.intersect_polygons(hull, strip).size() > 0 or _polygon_gap(hull, strip) < 2.0:
				near = true
		if not near:
			_fail("%s's berth is not within 2 m of its %s lane" % [name, boat["lane"]])


func _polygon_gap(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var best := INF
	for pair in [[a, b], [b, a]]:
		for p: Vector2 in pair[0]:
			for i in (pair[1] as PackedVector2Array).size():
				var seg: PackedVector2Array = pair[1]
				best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, seg[i], seg[(i + 1) % seg.size()])))
	return best


func _check_swim_exits() -> void:
	if FishingVillagePlan.SWIM_EXITS.size() < 3:
		_fail("Only %d swim exits; at least three are required" % FishingVillagePlan.SWIM_EXITS.size())
	var run := FishingVillagePlan.exit_run(REFERENCE_HEAD_BASE)
	var drop := FishingVillagePlan.DECK_TOP - FishingVillagePlan.exit_lower_end(REFERENCE_HEAD_BASE)
	if drop / run > FishingVillagePlan.MAX_RAMP_GRADE + 0.0001:
		_fail("Derived exit grade %.3f exceeds the ramp limit" % (drop / run))
	for e in FishingVillagePlan.SWIM_EXITS:
		var name := str(e["name"])
		if not _structures.has(str(e["deck"])):
			_fail("%s names deck %s, which is not in the plan" % [name, e["deck"]])
			continue
		var deck := _rect_of(str(e["deck"]))
		if absf(float(e["edge_z"]) - deck.end.y) > 0.01:
			_fail("%s is at z %.1f but %s's south edge is z %.1f" % [name, e["edge_z"], e["deck"], deck.end.y])
		if float(e["x0"]) < deck.position.x or float(e["x1"]) > deck.end.x:
			_fail("%s is not within %s's width" % [name, e["deck"]])
		if float(e["x1"]) - float(e["x0"]) < FishingVillagePlan.EXIT_WIDTH - 0.01:
			_fail("%s is narrower than %.1f m" % [name, FishingVillagePlan.EXIT_WIDTH])
		# Ramp plus eight clear metres beyond its foot.
		var zone := Rect2(float(e["x0"]), float(e["edge_z"]), float(e["x1"]) - float(e["x0"]), run + FishingVillagePlan.EXIT_CLEAR_WATER)
		var poly := _rect_polygon(zone)
		for sname: String in _structures:
			if sname == e["deck"] or sname == "MorHouseboat" and false:
				continue
			if _overlap_area(poly, _rect_polygon(_rect_of(sname))) > 0.05:
				_fail("%s's ramp and clear water run into %s" % [name, sname])
		for boat in FishingVillagePlan.BOATS:
			if _overlap_area(poly, _rect_polygon(boat["berth"])) > 0.05:
				_fail("%s's ramp and clear water run into %s's berth" % [name, boat["name"]])
		for route in FishingVillagePlan.ROUTES:
			if route["class"] == "gangway":
				continue
			for rs in _strip_polygons(route["points"], float(route["width"])):
				if _overlap_area(poly, rs) > 0.05 and not _route_on_deck(route, str(e["deck"])):
					_fail("%s's clear water is crossed by %s" % [name, route["name"]])


func _route_on_deck(route: Dictionary, deck: String) -> bool:
	return deck in route["ends"]


func _check_separation() -> void:
	for pair in FishingVillagePlan.SEPARATED:
		var gap := _polygon_gap(_rect_polygon(_rect_of(pair[0])), _rect_polygon(_rect_of(pair[1])))
		if gap < FishingVillagePlan.SEPARATION_GAP:
			_fail("%s and %s are only %.1f m apart; they must stay separated" % [pair[0], pair[1], gap])


func _check_portal() -> void:
	var gate: Dictionary = FishingVillagePlan.PORTAL_GATE
	var at: Vector2 = gate["at"]
	var landing := _rect_of("PortalLanding")
	if not landing.has_point(at):
		_fail("The portal gate is not on the portal landing")
	var behind := at - (gate["facing"] as Vector2).normalized() * FishingVillagePlan.PORTAL_CLEAR_BEHIND
	if not landing.grow(-0.4).has_point(behind):
		_fail("The portal gate has less than %.0f m of clear deck behind it" % FishingVillagePlan.PORTAL_CLEAR_BEHIND)
	for boat in FishingVillagePlan.BOATS:
		if (boat["berth"] as Rect2).grow(1.0).has_point(behind):
			_fail("%s's berth is behind the portal gate" % boat["name"])
	if at.length() > FishingVillagePlan.PROTECTED_RADIUS:
		_fail("The portal lies outside the protected bounds")


func _check_trade() -> void:
	for vendor: String in FishingVillagePlan.TRADE:
		var goods: Dictionary = FishingVillagePlan.TRADE[vendor]["goods"]
		var stocked := {}
		for item in ShopCatalog.get_items_for_shop(str(FishingVillagePlan.TRADE[vendor]["category"])):
			if item.get("purchasable", false):
				stocked[str(item["name"])] = true
		for item_name: String in stocked:
			if not goods.has(item_name):
				_fail("%s sells %s but the ledger gives it no source" % [vendor, item_name])
		for item_name: String in goods:
			var good: Dictionary = goods[item_name]
			if not stocked.has(item_name):
				_fail("The ledger says %s sells %s, but the shop does not stock it" % [vendor, item_name])
			var origin := str(good["at"])
			if origin != "" and not _structures.has(origin):
				_fail("%s's %s is made at %s, which is not in the plan" % [vendor, item_name, origin])
			if origin == "" and str(good["carried_by"]) == "":
				_fail("%s's %s comes from outside and nobody carries it in" % [vendor, item_name])
