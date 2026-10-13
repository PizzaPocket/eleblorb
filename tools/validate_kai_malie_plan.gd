extends Node

## Plan validator for Kai Mālie. It reads only KaiMaliePlan, so it runs before
## any part of the village is built:
##
##   Godot --headless --path . tools/validate_kai_malie_plan.tscn
##
## Exit code 1 if anything FAILs. The rules are
## docs/architecture/ocean_island_village_layout.md and _buildings.md:
##   - every building's rooms add up to its walls, floor by floor, and every
##     room meets the world-scale minimum for its kind;
##   - buildings stand on the coastal plain (the canoe house on the beach), off
##     the taro terraces, the stream, the green and the pier head;
##   - neighbours stand at least 3 m apart at the eaves;
##   - no path runs through a wall or a lānai, and every front faces a path or
##     the green;
##   - every resident has a building, and the rest point has a toilet.

const EPS := 0.05
const MIN_GAP := 2.99
const FRONT_REACH := 8.0
const STREAM_BAND := 3.0
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


## Walls plus lānai: the solid body a path may not cross.
func _body(b: Dictionary) -> Rect2:
	var r: Rect2 = b["walls"]
	var lanai: Dictionary = b["lanai"]
	for side in lanai:
		var d := float(lanai[side])
		match side:
			"u+": r.size.x += d
			"u-": r.position.x -= d; r.size.x += d
			"v+": r.size.y += d
			"v-": r.position.y -= d; r.size.y += d
	return r


func _gap(a: Rect2, b: Rect2) -> float:
	var du := maxf(maxf(b.position.x - a.end.x, a.position.x - b.end.x), 0.0)
	var dv := maxf(maxf(b.position.y - a.end.y, a.position.y - b.end.y), 0.0)
	return Vector2(du, dv).length()


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
	var plain: Rect2 = KaiMaliePlan.PLAIN
	for b in KaiMaliePlan.BUILDINGS:
		var fp: Rect2 = b["footprint"]
		var reach_u := plain.end.x + 0.8
		if b["key"] == "canoe_house":
			reach_u = KaiMaliePlan.BEACH.end.x + 0.8
		if fp.position.x < plain.position.x - 1.4 or fp.end.x > reach_u or fp.position.y < plain.position.y or fp.end.y > plain.end.y:
			_fail("%s stands outside the coastal plain" % b["name"])
		if fp.intersects(KaiMaliePlan.TERRACES):
			_fail("%s stands on the taro terraces" % b["name"])
		if fp.position.y < KaiMaliePlan.STREAM_V + STREAM_BAND and fp.end.y > KaiMaliePlan.STREAM_V - STREAM_BAND:
			_fail("%s stands in the stream" % b["name"])
		if fp.intersects(KaiMaliePlan.GREEN):
			_fail("%s stands on the green" % b["name"])
		if fp.intersects(KaiMaliePlan.PIER_HEAD):
			_fail("%s stands on the pier head" % b["name"])


func _check_spacing() -> void:
	var list := KaiMaliePlan.BUILDINGS
	for i in list.size():
		for j in range(i + 1, list.size()):
			var g := _gap(list[i]["footprint"], list[j]["footprint"])
			if g < MIN_GAP:
				_fail("%s and %s are only %.1f m apart at the eaves" % [list[i]["name"], list[j]["name"], g])


func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b))


func _check_paths() -> void:
	for path in KaiMaliePlan.PATHS:
		var half := float(path[1]) * 0.5
		var pts: Array = path[2]
		for k in range(pts.size() - 1):
			var a: Vector2 = pts[k]
			var c: Vector2 = pts[k + 1]
			var seg := Rect2(a, Vector2.ZERO).expand(c).grow(half)
			for b in KaiMaliePlan.BUILDINGS:
				if seg.intersects(_body(b)):
					_fail("%s runs through %s" % [path[0], b["name"]])
	for b in KaiMaliePlan.BUILDINGS:
		var body := _body(b)
		var front := body.get_center()
		match b["front"]:
			"u+": front.x = body.end.x
			"u-": front.x = body.position.x
			"v+": front.y = body.end.y
			"v-": front.y = body.position.y
		var served := Rect2(front - Vector2(3, 3), Vector2(6, 6)).intersects(KaiMaliePlan.GREEN)
		for path in KaiMaliePlan.PATHS:
			var pts: Array = path[2]
			for k in range(pts.size() - 1):
				if _segment_distance(front, pts[k], pts[k + 1]) <= FRONT_REACH + float(path[1]) * 0.5:
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
