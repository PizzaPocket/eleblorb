extends Node

## Validates the live Fire Caldera build against both generated walkway plans.
## The geometry source of truth is the plan data, including polygon holes,
## level guard lines, sampled flight profiles, SITE and SECTION.

var _failures := 0


func _ready() -> void:
	_check_walkway_levels(FireCalderaWalkwaysPlan.LEVELS)
	_check_flights(FireCalderaWalkwaysPlan.LEVELS, FireCalderaWalkwaysPlan.FLIGHTS, "surface")
	_check_level_overlaps(FireCalderaWalkwaysPlan.LEVELS, "surface")
	_check_walkway_site(FireCalderaWalkwaysPlan.SITE)
	_check_heartworks()
	_check_level_overlaps(FireCalderaHeartworksPlan.LEVELS, "Heartworks")
	_check_census()
	_check_surveys()
	print("---- validate_fire_plan: %d surface levels, %d surface flights, %d chamber levels, %d chamber flights, %d FAIL" % [
		FireCalderaWalkwaysPlan.LEVELS.size(), FireCalderaWalkwaysPlan.FLIGHTS.size(),
		FireCalderaHeartworksPlan.LEVELS.size(), FireCalderaHeartworksPlan.FLIGHTS.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	push_error(message)
	print("FAIL ", message)


func _check_walkway_levels(levels: Array) -> void:
	for level: Dictionary in levels:
		var level_id := str(level["id"])
		var datum := float(level["datum"])
		if not bool(level.get("build", true)) and str(level.get("owner", "")).is_empty():
			_fail("%s is excluded from shared construction but has no owner" % level_id)
		if level["surface"].is_empty():
			_fail("%s has no authored floor surfaces" % level_id)
		for region: Dictionary in level["surface"]:
			var polygon := FireCalderaPlanWalks._polygon_with_holes(region)
			var indices := Geometry2D.triangulate_polygon(polygon)
			if indices.is_empty():
				_fail("%s outline and holes did not triangulate" % level_id)
				continue
			var expected := absf(_area(_points(region["outer"])))
			for hole: Array in region.get("holes", []):
				expected -= absf(_area(_points(hole)))
			var actual := 0.0
			for i in range(0, indices.size(), 3):
				actual += absf((_cross(polygon[indices[i]], polygon[indices[i + 1]], polygon[indices[i + 2]])) * 0.5)
			if absf(expected - actual) > maxf(0.2, expected * 0.0001):
				_fail("%s triangulation area %.2f does not preserve outer minus holes %.2f" % [level_id, actual, expected])
		for line: Array in level.get("guards", []):
			if line.size() < 2:
				_fail("%s has a short guard line" % level_id)
			continue
			for point: Array in line:
				if not is_finite(float(point[0])) or not is_finite(float(point[1])):
					_fail("%s has a non-finite level guard point" % level_id)
					break
		print("ok   %s level: datum %.2f, %d surfaces, %d plan guard lines" % [level_id, datum, level["surface"].size(), level.get("guards", []).size()])


func _check_flights(levels: Array, flights: Array, label: String) -> void:
	var levels_by_id := {}
	for level: Dictionary in levels:
		levels_by_id[str(level["id"])] = level
	for flight: Dictionary in flights:
		var id := str(flight["id"])
		var profile: Array = flight["profile"]
		var deck: Array = flight.get("deck", profile)
		if profile.size() < 2:
			_fail("%s flight %s has no sampled profile" % [label, id])
			continue
		if deck.size() < 2 or deck.size() > profile.size():
			_fail("%s flight %s has malformed slope-only deck samples" % [label, id])
		if not levels_by_id.has(str(flight["upper"])) or not levels_by_id.has(str(flight["lower"])):
			_fail("%s flight %s names an absent level" % [label, id])
		var calculated_length := 0.0
		for i in profile.size() - 1:
			var a: Array = profile[i]
			var b: Array = profile[i + 1]
			var dx := float(b[0]) - float(a[0])
			var dy := float(b[1]) - float(a[1])
			var dz := float(b[2]) - float(a[2])
			var horizontal := Vector2(dx, dz).length()
			calculated_length += Vector3(dx, dy, dz).length()
			if horizontal > 0.001 and absf(dy) / horizontal > 1.0:
				_fail("%s flight %s has an unwalkable sampled segment" % [label, id])
		# The plan summary length can omit its level approaches. Sampled profile
		# positions are the construction truth; never redistribute their drop.
		for rail: Array in flight.get("guards", []):
			if rail.size() < 2:
				_fail("%s flight %s contains a short handrail" % [label, id])
				continue
			for point: Array in rail:
				if point.size() != 3 or not is_finite(float(point[1])):
					_fail("%s flight %s has malformed 3D guard coordinates" % [label, id])
					break
		print("ok   %s flight %s: %d profile samples, %.1f m" % [label, id, profile.size(), calculated_length])


func _check_walkway_site(site: Dictionary) -> void:
	var terrace: Dictionary = site["gate_terrace"]
	var foundation: Dictionary = site["gate_plinth"]
	if float(foundation["top"]) != float(FireCalderaPlan.GUEST_GATE_DATUM):
		_fail("Gate Terrace plinth top and guest arrival datum disagree")
	if not is_equal_approx(FireCalderaPlan.GROUND_PROMENADE_DATUM, FireCalderaPlan.FLOOR_Y):
		_fail("Promenade datum does not meet the surveyed ground shoulder")
	if site["frames"].size() != 12:
		_fail("Highline plan has %d paired-fork frame bearings, expected 12" % site["frames"].size())
	var funicular: Dictionary = site["funicular"]
	var profile: Array = funicular["profile"]
	if profile.size() < 2 or Vector2(float(profile[0][0]), float(profile[0][2])).distance_to(Vector2(float(profile[-1][0]), float(profile[-1][2]))) < 100.0:
		_fail("funicular section does not reach between stations")
	if terrace["half"].size() != 2:
		_fail("Gate Terrace has malformed authored half extents")
	var beds: Dictionary = site["beds"]
	for level: Dictionary in FireCalderaWalkwaysPlan.LEVELS:
		var bed: Dictionary = beds.get(str(level["id"]), {})
		if str(bed.get("kind", "")) == "ground":
			if not bed.has("cut_to"):
				_fail("ground bed %s lacks its generated cut datum" % level["id"])
	var cuts: Dictionary = site["flight_cuts"]
	for id: String in cuts:
		var found_flight := false
		for flight: Dictionary in FireCalderaWalkwaysPlan.FLIGHTS:
			found_flight = found_flight or str(flight["id"]) == id
		if not found_flight:
			_fail("ground cut references an unknown flight %s" % id)
	var materials: Dictionary = site["materials"]
	if materials["deck_glass"]["colour"] != [0.62, 0.82, 0.88] or float(materials["deck_glass"]["alpha"]) != 0.2:
		_fail("generated glass deck material changed from the Fire palette")
	if profile.size() < 2 or funicular["piers"].size() != 12 or funicular["stair"]["profile"].size() < 2:
		_fail("funicular profile, pier or stair data is incomplete")
	print("ok   site: Gate Terrace/plinth, 12 frames, %d sampled funicular stations" % profile.size())


func _check_heartworks() -> void:
	var section: Dictionary = FireCalderaHeartworksPlan.SECTION
	var chamber: Dictionary = section["chamber"]
	var cascade: Dictionary = section["cascade"]
	var volumes: Array = section["lava_volumes"]
	if volumes.size() != 3 or str(volumes[0]["kind"]) != "layer" or str(volumes[1]["kind"]) != "frustum" or str(volumes[2]["kind"]) != "cylinder":
		_fail("Heartworks plan does not define the reservoir, cascade and pool volumes")
	if volumes[0]["outline"].size() < 3 or not volumes[0]["floor"].has("dome"):
		_fail("Heartworks reservoir outline or dome floor is missing")
	if float(volumes[0]["top"]) != 29.2 or float(volumes[1]["top_radius"]) != 6.0 or float(volumes[1]["bottom_radius"]) != 4.2 or float(volumes[2]["radius"]) != 10.5:
		_fail("Heartworks lava volumes disagree with the generated section")
	if float(cascade["top_radius"]) * 2.0 != 12.0 or float(cascade["bottom_radius"]) * 2.0 != 8.4:
		_fail("Heartworks cascade radii disagree with the generated section")
	if absf(float(cascade["bottom_depth"]) - float(chamber["pool_surface"])) > 0.001:
		_fail("Heartworks cascade does not terminate at the collection pool")
	if float(chamber["opening"]) < float(cascade["top_radius"]) * 2.0:
		_fail("Floor opening is narrower than the cascade")
	_check_walkway_levels(FireCalderaHeartworksPlan.LEVELS)
	_check_flights(FireCalderaHeartworksPlan.LEVELS, FireCalderaHeartworksPlan.FLIGHTS, "Heartworks")
	print("ok   Heartworks section: single cascade, oculus, collection pool, %d crossings" % FireCalderaHeartworksPlan.SECTION["crossings"].size())


func _check_level_overlaps(levels: Array, label: String) -> void:
	for i in levels.size():
		var first: Dictionary = levels[i]
		if not bool(first.get("build", true)):
			continue
		for j in range(i + 1, levels.size()):
			var second: Dictionary = levels[j]
			if not bool(second.get("build", true)) or absf(float(first["datum"]) - float(second["datum"])) >= 0.02:
				continue
			for a: Dictionary in first["surface"]:
				for b: Dictionary in second["surface"]:
					for overlap: PackedVector2Array in Geometry2D.intersect_polygons(_points(a["outer"]), _points(b["outer"])):
						if absf(_area(overlap)) > 0.02 and _overlap_has_walkable_point(overlap, a, b):
							_fail("%s walkable surfaces %s and %s overlap at equal height" % [label, first["id"], second["id"]])


func _overlap_has_walkable_point(overlap: PackedVector2Array, first: Dictionary, second: Dictionary) -> bool:
	var indices := Geometry2D.triangulate_polygon(overlap)
	for i in range(0, indices.size(), 3):
		var p := (overlap[indices[i]] + overlap[indices[i + 1]] + overlap[indices[i + 2]]) / 3.0
		if _region_contains(first, p) and _region_contains(second, p):
			return true
	return false


func _region_contains(region: Dictionary, point: Vector2) -> bool:
	if not Geometry2D.is_point_in_polygon(point, _points(region["outer"])):
		return false
	for hole: Array in region.get("holes", []):
		if Geometry2D.is_point_in_polygon(point, _points(hole)):
			return false
	return true


func _check_census() -> void:
	var places := {"HEARTWORKS": true}
	for entry: Dictionary in FireCalderaPlan.PLOTS:
		places[str(entry["id"])] = true
	var names := {}
	for resident: Dictionary in FireCalderaPlan.RESIDENTS:
		names[str(resident["name"])] = true
		var home := FireCalderaPlan.plot(str(resident["home"]))
		if home.is_empty() or not bool(home["occupied"]):
			_fail("%s has no occupied home" % resident["name"])
		for place: String in resident["work"]:
			if not places.has(place):
				_fail("%s references obsolete or missing workplace %s" % [resident["name"], place])
	if FireCalderaPlan.RESIDENTS.size() != 14:
		_fail("resident census changed from fourteen")
	for shop: String in FireCalderaPlan.TRADE:
		var trade: Dictionary = FireCalderaPlan.TRADE[shop]
		if not names.has(str(trade["vendor"])):
			_fail("%s trade counter has an unknown vendor" % shop)
		for place: String in trade["made_at"]:
			if not places.has(place):
				_fail("%s trade ledger references obsolete workplace %s" % [shop, place])
	print("ok   census: 14 residents, existing plots and the single Heartworks public workplace")


func _check_surveys() -> void:
	for entry: Dictionary in FireCalderaPlan.PLOTS:
		if bool(entry.get("open", false)):
			continue
		var line := FireCalderaGround.survey(entry)
		if not line.has("datum") or not is_finite(float(line["datum"])):
			_fail("%s has no finite floor datum" % entry["id"])
		if str(entry["id"]) in ["OREN", "KEL", "ARO"] and not is_equal_approx(float(line["datum"]), FireCalderaPlan.GROUND_PROMENADE_DATUM):
			_fail("%s threshold is not flush with the promenade datum" % entry["id"])
	print("ok   surveys: %d occupied foundations and thresholds" % (FireCalderaPlan.PLOTS.size() - 1))


func _points(raw: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Array in raw:
		result.append(Vector2(float(point[0]), float(point[1])))
	return result


func _area(points: PackedVector2Array) -> float:
	var area := 0.0
	for i in points.size():
		var a := points[i]
		var b := points[(i + 1) % points.size()]
		area += a.x * b.y - b.x * a.y
	return area * 0.5


func _cross(a: Vector2, b: Vector2, c: Vector2) -> float:
	return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
