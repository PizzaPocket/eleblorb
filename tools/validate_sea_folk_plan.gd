extends Node

## Plan validator for the sea folk city. It reads only SeaFolkPlan, so it runs
## before any part of the city is rebuilt:
##
##   Godot --headless --path . tools/validate_sea_folk_plan.tscn
##
## Exit code 1 if anything FAILs. The rules are
## docs/architecture/ocean_sea_folk_city_layout.md and _buildings.md:
##   - every structure stands in its ring, and nothing but a glass tunnel
##     crosses the Ring Current;
##   - the eight avenues stay clear, and the castle's door faces the main one;
##   - structures stand at least CLEAR apart for swimmers;
##   - each glass tunnel joins two air halls and runs clear of everything else;
##   - the guest hall's rooms fit under its dome at world scale, with room for
##     the ramp out of the moon pool;
##   - every resident has a building, and there are sixteen homes.

const EPS := 0.01
const AVENUE_MARGIN := 1.0
const TUNNEL_MARGIN := 1.0
const MIN_ROOM := {"bed2": Vector2(3.2, 3.4), "bed1": Vector2(3.0, 3.2), "bath": Vector2(1.4, 1.8)}

var _failures := 0


func _ready() -> void:
	_check_rings()
	_check_avenues()
	_check_spacing()
	_check_tunnels()
	_check_guest_hall()
	_check_people()
	print("---- validate_sea_folk_plan: %d structures, %d tunnels, %d FAIL" % [SeaFolkPlan.STRUCTURES.size(), SeaFolkPlan.TUNNELS.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


## Least distance from a polygon to a polyline or polygon (0 where they meet).
func _distance(poly: PackedVector2Array, other: PackedVector2Array, closed: bool) -> float:
	var line := other.duplicate()
	if closed:
		line.append(other[0])
		for p in poly:
			if Geometry2D.is_point_in_polygon(p, other):
				return 0.0
	for p in other:
		if Geometry2D.is_point_in_polygon(p, poly):
			return 0.0
	var best := INF
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		for k in range(line.size() - 1):
			if Geometry2D.segment_intersects_segment(a, b, line[k], line[k + 1]) != null:
				return 0.0
			best = minf(best, a.distance_to(Geometry2D.get_closest_point_to_segment(a, line[k], line[k + 1])))
			best = minf(best, line[k].distance_to(Geometry2D.get_closest_point_to_segment(line[k], a, b)))
	return best


func _radii(poly: PackedVector2Array) -> Vector2:
	var lo := INF
	var hi := 0.0
	for p in poly:
		lo = minf(lo, p.length())
		hi = maxf(hi, p.length())
	return Vector2(lo, hi)


func _avenue(bearing: float) -> PackedVector2Array:
	var dir := Vector2.from_angle(deg_to_rad(bearing))
	var mound: Vector2 = SeaFolkPlan.RINGS["mound"]
	return PackedVector2Array([dir * mound.y, dir * SeaFolkPlan.FLAT_RADIUS])


func _check_rings() -> void:
	var current: Vector2 = SeaFolkPlan.RINGS["current"]
	for s in SeaFolkPlan.STRUCTURES:
		var r := _radii(s["footprint"])
		var ring: String = s["ring"]
		if ring == "edge":
			if r.y > SeaFolkPlan.FLAT_RADIUS + 25.0:
				_fail("%s stands too far beyond the city" % s["name"])
		elif ring != "mound":
			var band: Vector2 = SeaFolkPlan.RINGS[ring]
			if r.x < band.x - EPS or r.y > band.y + EPS:
				_fail("%s reaches out of the %s ring" % [s["name"], ring])
		if ring != "mound" and r.x < current.y and r.y > current.x:
			_fail("%s stands in the Ring Current" % s["name"])


func _check_avenues() -> void:
	for s in SeaFolkPlan.STRUCTURES:
		if s["ring"] == "mound":
			continue
		for b in SeaFolkPlan.AVENUES:
			if _distance(s["footprint"], _avenue(b), false) < SeaFolkPlan.AVENUE_WIDTH * 0.5 + AVENUE_MARGIN:
				_fail("%s stands in the avenue at %.0f degrees" % [s["name"], b])
	for s in SeaFolkPlan.STRUCTURES:
		if s["key"] == "tidehall" and absf(float(s["extra"]["facing"]) - SeaFolkPlan.MAIN_AVENUE) > EPS:
			_fail("Tidehall's door does not face the main avenue")


func _check_spacing() -> void:
	var list := SeaFolkPlan.STRUCTURES
	for i in list.size():
		for j in range(i + 1, list.size()):
			var g := _distance(list[i]["footprint"], list[j]["footprint"], true)
			if g < SeaFolkPlan.CLEAR - EPS:
				_fail("%s and %s are only %.1f m apart" % [list[i]["name"], list[j]["name"], g])


func _check_tunnels() -> void:
	for t in SeaFolkPlan.TUNNELS:
		var line: PackedVector2Array = t[1]
		var ends := 0
		for s in SeaFolkPlan.STRUCTURES:
			if s["kind"] == "air hall":
				if _distance(s["footprint"], PackedVector2Array([line[0], line[line.size() - 1]]), false) < 1.5:
					ends += 1
				continue
			if _distance(s["footprint"], line, false) < SeaFolkPlan.TUNNEL_WIDTH * 0.5 + TUNNEL_MARGIN:
				_fail("%s runs into %s" % [t[0], s["name"]])
		if ends < 2:
			_fail("%s does not join two air halls" % t[0])


func _check_guest_hall() -> void:
	for s in SeaFolkPlan.STRUCTURES:
		if s["key"] != "guest_hall":
			continue
		var radius := float(s["extra"]["diameter"]) * 0.5
		var height := float(s["extra"]["height"])
		var outer := radius - 0.3
		var depth := float(SeaFolkPlan.GUEST_ROOMS[0][2])
		var inner := outer - depth
		var n := SeaFolkPlan.DOME_EXPONENT
		var clear := height * pow(maxf(0.0, 1.0 - pow(outer / radius, n)), 1.0 / n)
		if clear < SeaFolkPlan.HEADROOM:
			_fail("the guest hall's rooms have %.1f m headroom at the wall" % clear)
		var arc := 0.0
		for room in SeaFolkPlan.GUEST_ROOMS:
			arc += float(room[3]) + 0.2
			var need: Vector2 = MIN_ROOM[room[1]]
			var a := float(room[2])
			var b := float(room[3])
			if minf(a, b) < need.x or maxf(a, b) < need.y:
				_fail("the guest hall's %s is too small" % room[0])
		if arc > TAU * inner - 4.0:
			_fail("the guest hall's rooms do not fit round the dome")
		if inner - 0.2 - SeaFolkPlan.MOON_POOL * 0.5 < SeaFolkPlan.RAMP_RUN + 1.4:
			_fail("the guest hall has no room for the ramp out of the moon pool")


func _check_people() -> void:
	for who in SeaFolkPlan.RESIDENTS:
		var housed := false
		for s in SeaFolkPlan.STRUCTURES:
			for w in s["who"]:
				if String(w).begins_with(who):
					housed = true
		if not housed:
			_fail("%s has no building" % who)
	var homes := 0
	for s in SeaFolkPlan.STRUCTURES:
		if s["kind"] == "home":
			homes += 1
	if homes != 16:
		_fail("there are %d homes, not sixteen" % homes)
