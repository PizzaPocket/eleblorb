extends Node

## Plan validator for Kai Mālie. It reads only KaiMaliePlan, so it runs before
## any part of the village is built:
##
##   Godot --headless --path . tools/validate_kai_malie_plan.tscn
##
## Exit code 1 if anything FAILs. The rules are
## docs/architecture/ocean_island_village_layout.md and _buildings.md. The shore
## and zones are curved polygons and the houses are turned, so every test is
## made on the true shapes:
##   - every building's rooms add up to its walls, floor by floor, and every
##     room meets the world-scale minimum for its kind;
##   - buildings stand on the coastal plain (the canoe house down the beach),
##     clear of the taro terraces, the green and the pier head, 3 m from the
##     stream, turned no more than 12 degrees;
##   - neighbours stand at least 3 m apart at the eaves;
##   - no path runs through a wall or a lānai, and every front faces a path or
##     the green;
##   - every resident has a building, and the rest point has a toilet.

const EPS := 0.05
const MIN_GAP := 2.99
const FRONT_REACH := 8.0
const MAX_TURN := 12.0
## Room minimums at world scale: kind -> (short side, long side).
const MIN_ROOM := {
	"bed2": Vector2(3.2, 3.4), "bed1": Vector2(3.0, 3.2), "living": Vector2(3.2, 3.6),
	"kitchen": Vector2(2.8, 3.0), "bath": Vector2(1.4, 1.8), "store": Vector2(1.6, 1.6),
	"work": Vector2(3.0, 3.0), "hall": Vector2(1.4, 1.4),
}

var _failures := 0


func _ready() -> void:
	_check_rooms()
	_check_sites()
	_check_spacing()
	_check_paths()
	_check_people()
	print("---- validate_kai_malie_plan: %d buildings, %d paths, %d FAIL" % [KaiMaliePlan.BUILDINGS.size(), KaiMaliePlan.PATHS.size(), _failures])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _meet(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	return not Geometry2D.intersect_polygons(a, b).is_empty()


## Least distance from a polygon to a polyline (0 where they cross).
func _distance_to_line(poly: PackedVector2Array, line: PackedVector2Array) -> float:
	var best := INF
	for p in line:
		if Geometry2D.is_point_in_polygon(p, poly):
			return 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		for k in range(line.size() - 1):
			if Geometry2D.segment_intersects_segment(a, b, line[k], line[k + 1]) != null:
				return 0.0
			best = minf(best, a.distance_to(Geometry2D.get_closest_point_to_segment(a, line[k], line[k + 1])))
			best = minf(best, line[k].distance_to(Geometry2D.get_closest_point_to_segment(line[k], a, b)))
	return best


func _closed(poly: PackedVector2Array) -> PackedVector2Array:
	var out := poly.duplicate()
	out.append(poly[0])
	return out


func _check_rooms() -> void:
	for b in KaiMaliePlan.BUILDINGS:
		var walls: Rect2 = b["walls"]
		for fi in b["floors"].size():
			var rows: Array = b["floors"][fi]
			var depth := 0.0
			for row in rows:
				var d := float(row[0])
				depth += d
				var width := 0.0
				for room in row[1]:
					width += float(room[2])
					if MIN_ROOM.has(room[1]):
						var need: Vector2 = MIN_ROOM[room[1]]
						var w := float(room[2])
						if minf(w, d) < need.x - 0.01 or maxf(w, d) < need.y - 0.01:
							_fail("%s, floor %d: %s is %.1f x %.1f, under %.1f x %.1f" % [b["name"], fi, room[0], w, d, need.x, need.y])
				if absf(width - walls.size.y) > EPS:
					_fail("%s, floor %d: a row of rooms adds to %.2f m, not the %.2f m width" % [b["name"], fi, width, walls.size.y])
			if absf(depth - walls.size.x) > EPS:
				_fail("%s, floor %d: the rows add to %.2f m, not the %.2f m depth" % [b["name"], fi, depth, walls.size.x])


func _check_sites() -> void:
	for b in KaiMaliePlan.BUILDINGS:
		var body: PackedVector2Array = b["body"]
		var fp: PackedVector2Array = b["footprint"]
		if b["key"] == "canoe_house":
			for p in body:
				if not Geometry2D.is_point_in_polygon(p, KaiMaliePlan.PLAIN) and not Geometry2D.is_point_in_polygon(p, KaiMaliePlan.BEACH):
					_fail("%s stands off the plain and the beach" % b["name"])
					break
		else:
			for p in body:
				if not Geometry2D.is_point_in_polygon(p, KaiMaliePlan.PLAIN):
					_fail("%s stands outside the coastal plain" % b["name"])
					break
		if _meet(fp, KaiMaliePlan.TERRACES):
			_fail("%s stands on the taro terraces" % b["name"])
		if _meet(fp, KaiMaliePlan.GREEN):
			_fail("%s stands on the green" % b["name"])
		if _meet(fp, KaiMaliePlan.PIER_HEAD):
			_fail("%s stands on the pier head" % b["name"])
		if _distance_to_line(fp, KaiMaliePlan.STREAM) < KaiMaliePlan.STREAM_CLEAR:
			_fail("%s stands within %.0f m of the stream" % [b["name"], KaiMaliePlan.STREAM_CLEAR])
		if absf(float(b["turn"])) > MAX_TURN:
			_fail("%s turns %.0f degrees off the island's frame" % [b["name"], b["turn"]])


func _check_spacing() -> void:
	var list := KaiMaliePlan.BUILDINGS
	for i in list.size():
		for j in range(i + 1, list.size()):
			var g := _distance_to_line(list[i]["footprint"], _closed(list[j]["footprint"]))
			if g < MIN_GAP:
				_fail("%s and %s are only %.1f m apart at the eaves" % [list[i]["name"], list[j]["name"], g])


## The middle of a building's front edge, turned with the building.
func _front(b: Dictionary) -> Vector2:
	var walls: Rect2 = b["walls"]
	var r := walls
	var lanai: Dictionary = b["lanai"]
	for side in lanai:
		var d := float(lanai[side])
		match side:
			"u+": r.size.x += d
			"u-": r.position.x -= d; r.size.x += d
			"v+": r.size.y += d
			"v-": r.position.y -= d; r.size.y += d
	var mid := r.get_center()
	match b["front"]:
		"u+": mid.x = r.end.x
		"u-": mid.x = r.position.x
		"v+": mid.y = r.end.y
		"v-": mid.y = r.position.y
	var c := walls.get_center()
	return c + (mid - c).rotated(deg_to_rad(float(b["turn"])))


func _check_paths() -> void:
	for path in KaiMaliePlan.PATHS:
		var half := float(path[1]) * 0.5
		for b in KaiMaliePlan.BUILDINGS:
			if _distance_to_line(b["body"], path[2]) < half:
				_fail("%s runs through %s" % [path[0], b["name"]])
	for b in KaiMaliePlan.BUILDINGS:
		var front := _front(b)
		var served := _distance_to_line(PackedVector2Array([front - Vector2(0.01, 0), front + Vector2(0.01, 0), front + Vector2(0, 0.01)]), _closed(KaiMaliePlan.GREEN)) <= FRONT_REACH
		for path in KaiMaliePlan.PATHS:
			var line: PackedVector2Array = path[2]
			for k in range(line.size() - 1):
				if front.distance_to(Geometry2D.get_closest_point_to_segment(front, line[k], line[k + 1])) <= FRONT_REACH + float(path[1]) * 0.5:
					served = true
		if not served:
			_fail("%s faces no path or the green" % b["name"])


func _check_people() -> void:
	for who in KaiMaliePlan.RESIDENTS:
		var housed := false
		for b in KaiMaliePlan.BUILDINGS:
			for w in b["who"]:
				if String(w).begins_with(who):
					housed = true
		if not housed:
			_fail("%s has no building" % who)
	for b in KaiMaliePlan.BUILDINGS:
		var extra: Dictionary = b["extra"]
		if extra.get("rest_point", false) and String(extra.get("toilet", "")) == "":
			_fail("%s is a rest point without a toilet" % b["name"])
