extends Node

const CityPlan := preload("res://scripts/city_plan.gd")

## Plan validator for Moy. It reads only CityPlan, so it runs before any part
## of the city is built:
##
##   Godot --headless --path . tools/validate_city_plan.tscn
##
## It runs as a scene, like the other plan validators, so autoloads compile.
## Exit code 1 if anything FAILs. The rules are docs/architecture/city.md,
## section 7 and the building schedule:
##   - everything built stands inside the Rim Walk; the works stand outside it;
##   - no two footprints overlap, and nothing is built on a street or square
##     (turned estate blocks are tested by their true outline, corners());
##   - every building in a street block has a face on a street, square, the
##     park or the Rim Walk; estate blocks stand in a precinct instead;
##   - every street meets another street, a square or the Rim Walk at both
##     ends (no dead ends);
##   - building numbers are unique, every resident's home exists;
##   - the turbines keep clear of the Jungle and Ice plateaus;
##   - Old Moy's tower houses stand on lots wide enough for their ramp core,
##     on a stone base of 1 to 3 storeys or an earth base of 2 storeys up to
##     two-thirds of the height
##     (docs/architecture/moy_tower_house.md).

const TerrainGen := preload("res://scripts/terrain_generator.gd")

## Turbines stand at least this far from a plateau's centre (city.md, the
## wind farm): 140 m beyond the foot of its slope.
const TURBINE_PLATEAU_CLEARANCE := 280.0
## Numbers of the works outside the Rim Walk.
const OUTSIDE := [40, 41, 42, 43, 44]
const STEP := 1.0
const EPS := 0.01

var _failures := 0
var _numbers := {}


func _ready() -> void:
	_check_numbers_and_homes()
	_check_inside_rim()
	_check_overlaps()
	_check_frontage()
	_check_streets()
	_check_turbines()
	_check_tower_kits()
	print("---- validate_city_plan: %d streets, %d buildings, %d lots, %d FAIL" % [CityPlan.STREETS.size(), CityPlan.BUILDINGS.size(), CityPlan.LOTS.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _inside_built(p: Vector2) -> bool:
	return p.distance_to(CityPlan.CENTER) <= CityPlan.BUILT_RADIUS


func _corners(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## True when two convex outlines share area (touching edges do not count):
## no edge normal of either separates them.
func _polys_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	for poly in [a, b]:
		for i in poly.size():
			var e: Vector2 = poly[(i + 1) % poly.size()] - poly[i]
			var axis := Vector2(-e.y, e.x).normalized()
			var amin := INF
			var amax := -INF
			var bmin := INF
			var bmax := -INF
			for p in a:
				amin = minf(amin, p.dot(axis))
				amax = maxf(amax, p.dot(axis))
			for p in b:
				bmin = minf(bmin, p.dot(axis))
				bmax = maxf(bmax, p.dot(axis))
			if amax <= bmin + EPS or bmax <= amin + EPS:
				return false
	return true


func _in_street_or_open(p: Vector2) -> bool:
	for s in CityPlan.STREETS:
		if (s["rect"] as Rect2).has_point(p):
			return true
	for o in CityPlan.OPENS:
		if (o["rect"] as Rect2).has_point(p):
			return true
	return false


func _in_precinct(p: Vector2) -> bool:
	for pr in CityPlan.PRECINCTS:
		for r in pr:
			if (r as Rect2).has_point(p):
				return true
	return false


func _footprints() -> Array:
	var out := []
	for b in CityPlan.BUILDINGS:
		if b["rect"] != null and not OUTSIDE.has(int(b["n"])):
			out.append({"label": "building %d %s" % [b["n"], b["name"]], "rect": b["rect"], "outline": CityPlan.corners(b), "kind": b["kind"]})
	for i in CityPlan.LOTS.size():
		out.append({"label": "lot %d" % i, "rect": CityPlan.LOTS[i][0], "outline": _corners(CityPlan.LOTS[i][0]), "kind": "lot"})
	return out


func _check_numbers_and_homes() -> void:
	for b in CityPlan.BUILDINGS:
		var n := int(b["n"])
		if _numbers.has(n):
			_fail("building number %d is used twice" % n)
		_numbers[n] = b
	for who in CityPlan.RESIDENT_HOMES:
		if not _numbers.has(int(CityPlan.RESIDENT_HOMES[who])):
			_fail("%s's home, building %d, does not exist" % [who, CityPlan.RESIDENT_HOMES[who]])


func _check_inside_rim() -> void:
	for f in _footprints():
		for c in f["outline"]:
			if not _inside_built(c):
				_fail("%s reaches beyond the Rim Walk" % f["label"])
				break
	for n in OUTSIDE:
		var r: Rect2 = _numbers[n]["rect"]
		if r.get_center().distance_to(CityPlan.CENTER) <= CityPlan.RIM_RADIUS:
			_fail("building %d should stand outside the Rim Walk" % n)


func _check_overlaps() -> void:
	var fps := _footprints()
	for i in fps.size():
		var a: PackedVector2Array = fps[i]["outline"]
		for j in range(i + 1, fps.size()):
			if _polys_overlap(a, fps[j]["outline"]):
				_fail("%s overlaps %s" % [fps[i]["label"], fps[j]["label"]])
		for s in CityPlan.STREETS:
			if _polys_overlap(a, _corners(s["rect"])):
				_fail("%s is built on %s" % [fps[i]["label"], s["name"]])
		for o in CityPlan.OPENS:
			# The park's tea house and lodge stand in the park by design.
			if o["name"] == "park" and fps[i]["kind"] == "civic":
				continue
			if _polys_overlap(a, _corners(o["rect"])):
				_fail("%s is built on %s" % [fps[i]["label"], o["name"]])


## A face is open when, walking straight out from it across open ground (a
## front garden or yard) for up to FRONT_REACH, you reach a street, a square,
## the park, or the Rim Walk's garden edge beyond the built radius.
const FRONT_REACH := 6

var _all_footprints: Array[PackedVector2Array] = []


func _occupied(p: Vector2) -> bool:
	for outline in _all_footprints:
		if Geometry2D.is_point_in_polygon(p, outline):
			return true
	return false


func _has_frontage(r: Rect2) -> bool:
	var sides := [
		[r.position, Vector2(r.end.x, r.position.y), Vector2(0, -0.5)],
		[Vector2(r.position.x, r.end.y), r.end, Vector2(0, 0.5)],
		[r.position, Vector2(r.position.x, r.end.y), Vector2(-0.5, 0)],
		[Vector2(r.end.x, r.position.y), r.end, Vector2(0.5, 0)],
	]
	for side in sides:
		var a: Vector2 = side[0]
		var b: Vector2 = side[1]
		var off: Vector2 = side[2]
		var n := maxi(int(a.distance_to(b) / STEP), 1)
		var dir := off.normalized()
		for k in n:
			var p := a.lerp(b, (k + 0.5) / n) + off
			for d in FRONT_REACH:
				if _in_street_or_open(p) or not _inside_built(p):
					return true
				if _occupied(p):
					break
				p += dir
	return false


func _check_frontage() -> void:
	_all_footprints.clear()
	for f in _footprints():
		_all_footprints.append(f["outline"])
	for f in _footprints():
		var r: Rect2 = f["rect"]
		if f["kind"] == "estate" or (f["kind"] == "civic" and _in_precinct(r.get_center())):
			if not _in_precinct(r.get_center()):
				_fail("%s should stand in a precinct garden" % f["label"])
			continue
		if not _has_frontage(r):
			_fail("%s has no face on a street, square or the Rim Walk" % f["label"])


## Each street's two ends, clipped to the Rim Walk, must meet another street,
## a square or the Rim Walk itself.
func _check_streets() -> void:
	for i in CityPlan.STREETS.size():
		var s: Dictionary = CityPlan.STREETS[i]
		if s["name"] == "Park Ring":
			continue
		var r: Rect2 = s["rect"]
		var horizontal := r.size.x >= r.size.y
		var length := r.size.x if horizontal else r.size.y
		var mid := r.get_center()
		var inside: Array[float] = []
		var t := 0.5
		while t < length:
			var p := Vector2(r.position.x + t, mid.y) if horizontal else Vector2(mid.x, r.position.y + t)
			if _inside_built(p):
				inside.append(t)
			t += STEP
		if inside.is_empty():
			_fail("%s lies wholly outside the Rim Walk" % s["name"])
			continue
		for end_t in [inside[0] - STEP, inside[inside.size() - 1] + STEP]:
			var width := r.size.y if horizontal else r.size.x
			var met := false
			var k := 0.5
			while k < width:
				var p := Vector2(r.position.x + end_t, r.position.y + k) if horizontal else Vector2(r.position.x + k, r.position.y + end_t)
				if not _inside_built(p) or _in_other_street_or_open(p, i):
					met = true
					break
				k += STEP
			if not met:
				_fail("%s dead-ends at %s" % [s["name"], str(end_t)])


func _in_other_street_or_open(p: Vector2, me: int) -> bool:
	for j in CityPlan.STREETS.size():
		if j != me and (CityPlan.STREETS[j]["rect"] as Rect2).has_point(p):
			return true
	for o in CityPlan.OPENS:
		if (o["rect"] as Rect2).has_point(p):
			return true
	return false


func _check_turbines() -> void:
	for t in CityPlan.TURBINES:
		if t.distance_to(TerrainGen.JUNGLE_PLATEAU_CENTER) < TURBINE_PLATEAU_CLEARANCE:
			_fail("turbine at %s is too close to the Jungle plateau" % str(t))
		if t.distance_to(TerrainGen.ICE_PLATEAU_CENTER) < TURBINE_PLATEAU_CLEARANCE:
			_fail("turbine at %s is too close to the Ice plateau" % str(t))
		if t.distance_to(CityPlan.CENTER) < CityPlan.RIM_RADIUS + CityPlan.TURBINE_ROTOR_RADIUS:
			_fail("turbine at %s sweeps over the Rim Walk" % str(t))


## Tower houses need 6 m across for the 3.4 m ramp core inside their walls.
const TOWER_MIN_WIDTH := 6.0


func _check_tower_kit(label: String, kit: Dictionary, r: Rect2) -> void:
	if kit["kit"] == "tong_lau":
		_check_tong_lau(label, kit, r)
		return
	if kit["kit"] == "lockup" and int(kit["storeys"]) != 2:
		_fail("%s is a lock-up shop of %d storeys" % [label, kit["storeys"]])
	if kit["kit"] != "tower":
		return
	if minf(r.size.x, r.size.y) < TOWER_MIN_WIDTH and not label.begins_with("building"):
		_fail("%s is a tower house on a lot narrower than %.0f m" % [label, TOWER_MIN_WIDTH])
	var storeys := int(kit["storeys"])
	var base := int(kit["base"])
	match kit["base_kind"]:
		"earth":
			if base < 2 or base > maxi(2, (2 * storeys) / 3):
				_fail("%s has an earth base of %d storeys in %d" % [label, base, storeys])
		"stone":
			if base < 1 or base > 3:
				_fail("%s has a stone base of %d storeys" % [label, base])
		_:
			_fail("%s has an unknown base %s" % [label, kit["base_kind"]])


func _check_tower_kits() -> void:
	if CityPlan.LOT_KITS.size() != CityPlan.LOTS.size():
		_fail("LOT_KITS has %d entries for %d lots" % [CityPlan.LOT_KITS.size(), CityPlan.LOTS.size()])
		return
	for i in CityPlan.LOTS.size():
		if CityPlan.LOT_KITS[i] != null:
			_check_tower_kit("lot %d" % i, CityPlan.LOT_KITS[i], CityPlan.LOTS[i][0])
	for n in CityPlan.BUILDING_KITS:
		_check_tower_kit("building %d" % n, CityPlan.BUILDING_KITS[n], _numbers[n]["rect"])


## Market lanes (docs/architecture/moy_market_lanes.md): boom houses are 4 or
## 5 storeys and only they have verandas; tile houses are 6 to 9; a house
## under 6 m across shares its ramp core, and core pairs are mutual.
func _check_tong_lau(label: String, kit: Dictionary, r: Rect2) -> void:
	var storeys := int(kit["storeys"])
	if (kit["gen"] == "boom") != (storeys <= 5):
		_fail("%s is a %s house of %d storeys" % [label, kit["gen"], storeys])
	if kit["veranda"] and kit["gen"] != "boom":
		_fail("%s has a veranda on a tile house" % label)
	if minf(r.size.x, r.size.y) < 6.0 and kit["core"] != "shared" and not kit.has("units"):
		_fail("%s is under 6 m across without a shared ramp core" % label)
	var pair := int(kit["pair"])
	if pair >= 0:
		var other = CityPlan.LOT_KITS[pair]
		if other == null or int(other["pair"]) != int(label.get_slice(" ", 1)):
			_fail("%s shares a ramp core with lot %d, which does not share back" % [label, pair])
