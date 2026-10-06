class_name RoomLayout
extends RefCounted

## Places furniture in one storey of a building so that it cannot block a door,
## a ramp or a fire, cannot stand inside a wall, and cannot sit on top of
## another piece. A piece is offered a list of candidate poses and takes the
## first that fits; if none does, the failure is recorded and the caller can
## shrink, move or drop it. The ClearZones audit stays as the independent check
## that this did its job.
##
## Frame: the building's own plane (x, z). Every piece has its BACK toward local
## +Z and its FRONT toward local -Z, the convention Furnishings uses for
## settles, shelves, chests, desks and peg rails. A bed is modelled with its
## head toward -Z, so a bed placed head-to-wall is built with yaw + PI.

const GAP := 0.03
const MIN_OVERLAP := 0.01

var half: Vector2
var floor_index := 0
var base_y := 0.0
var failures: Array[String] = []

var _hard: Array[PackedVector2Array] = []
var _zones: Array[PackedVector2Array] = []
var _zone_kinds: Array[String] = []
var _fronts: Array[PackedVector2Array] = []


## `half_extents` is the usable interior (inside the wall faces). Zones that
## belong to this storey (registered on `building` by ClearZones.add) are read
## straight away, so build doors, ramps and hearths before furnishing.
func _init(building: Node3D, half_extents: Vector2, floor_number: int = 0) -> void:
	half = half_extents
	floor_index = floor_number
	base_y = float(floor_number) * TownProps.FLOOR_HEIGHT
	for zone: Dictionary in building.get_meta(ClearZones.ZONES_META, []):
		var y0 := float(zone["y0"])
		if y0 >= base_y - 0.01 and y0 < base_y + TownProps.FLOOR_HEIGHT - 0.01:
			_zones.append(ClearZones.local_polygon(zone))
			_zone_kinds.append(str(zone["kind"]))


## Marks an axis-aligned plan rectangle (a chimney breast, a stair hole) as
## solid ground nothing may stand on.
func reserve(center: Vector2, half_size: Vector2) -> void:
	_hard.append(PackedVector2Array([
		center + Vector2(-half_size.x, -half_size.y), center + Vector2(half_size.x, -half_size.y),
		center + Vector2(half_size.x, half_size.y), center + Vector2(-half_size.x, half_size.y),
	]))


## Poses along a wall for a piece with half extents (hx, hz): `along` are the
## positions along the wall (x for the north and south walls, z for east and
## west). Returns {"pos": Vector2, "yaw": float} for the first that fits and
## records it, or an empty dictionary.
func on_wall(wall: String, hx: float, hz: float, front: float, along: Array[float], label: String = "", height: float = 2.0) -> Dictionary:
	for position_along in along:
		var pose := _wall_pose(wall, hz, position_along)
		if _try(pose["pos"], pose["yaw"], hx, hz, front, height):
			return pose
	failures.append("%s found no room on the %s wall" % [label if label != "" else "piece", wall])
	return {}


## Records the pose if it fits, with no failure logged when it does not.
func try_quietly(pose: Dictionary, hx: float, hz: float, front: float, height: float = 2.0) -> Dictionary:
	if _try(pose["pos"], pose["yaw"], hx, hz, front, height):
		return pose
	return {}


## A piece anywhere on a list of candidate (position, yaw) pairs.
func at_any(candidates: Array[Dictionary], hx: float, hz: float, front: float, label: String = "", height: float = 2.0) -> Dictionary:
	for pose in candidates:
		if _try(pose["pos"], pose["yaw"], hx, hz, front, height):
			return pose
	failures.append("%s found no room" % (label if label != "" else "piece"))
	return {}


## Tries the first of several walls in order, each at several positions.
func on_walls(walls: Array[String], hx: float, hz: float, front: float, along: Array[float], label: String = "", height: float = 2.0) -> Dictionary:
	for wall in walls:
		for position_along in along:
			var pose := _wall_pose(wall, hz, position_along)
			if _try(pose["pos"], pose["yaw"], hx, hz, front, height):
				return pose
	failures.append("%s found no room on any of %s" % [label if label != "" else "piece", walls])
	return {}


## Positions every `step` metres from `from_value` to `to_value` inclusive.
static func span(from_value: float, to_value: float, step: float = 0.25) -> Array[float]:
	var values: Array[float] = []
	var steps := maxi(int(absf(to_value - from_value) / step), 1)
	for i in steps + 1:
		values.append(lerpf(from_value, to_value, float(i) / float(steps)))
	return values


func _wall_pose(wall: String, hz: float, position_along: float) -> Dictionary:
	match wall:
		"north":
			return {"pos": Vector2(position_along, half.y - hz - GAP), "yaw": 0.0}
		"south":
			return {"pos": Vector2(position_along, -half.y + hz + GAP), "yaw": PI}
		"east":
			return {"pos": Vector2(half.x - hz - GAP, position_along), "yaw": PI * 0.5}
		_:
			return {"pos": Vector2(-half.x + hz + GAP, position_along), "yaw": -PI * 0.5}


func _try(pos: Vector2, yaw: float, hx: float, hz: float, front: float, height: float = 2.0) -> bool:
	var body_poly := _rect(pos, yaw, hx, -hz, hz)
	for corner in body_poly:
		if absf(corner.x) > half.x + 0.001 or absf(corner.y) > half.y + 0.001:
			return false
	if _hits(body_poly, _hard) or _hits_zones(body_poly, height) or _hits(body_poly, _fronts):
		return false
	var front_poly := PackedVector2Array()
	if front > 0.0:
		front_poly = _rect(pos, yaw, hx, -hz - front, -hz)
		if _hits(front_poly, _hard):
			return false
		for corner in front_poly:
			if absf(corner.x) > half.x + 0.3 or absf(corner.y) > half.y + 0.3:
				return false
	_hard.append(body_poly)
	if front > 0.0:
		_fronts.append(front_poly)
	return true


## Whether a footprint at this pose would be accepted, without recording it.
func would_fit(pos: Vector2, yaw: float, hx: float, hz: float, height: float = 0.5) -> bool:
	var body_poly := _rect(pos, yaw, hx, -hz, hz)
	for corner in body_poly:
		if absf(corner.x) > half.x + 0.001 or absf(corner.y) > half.y + 0.001:
			return false
	return not (_hits(body_poly, _hard) or _hits_zones(body_poly, height) or _hits(body_poly, _fronts))


## Zones apply to a piece unless it is the wrong height to matter: a window zone
## only concerns pieces that reach the sill, so a bed or chest may stand under a
## window but a shelf or cabinet may not stand in front of one.
func _hits_zones(poly: PackedVector2Array, height: float) -> bool:
	for i in _zones.size():
		if _zone_kinds[i] == "window" and height < 0.95:
			continue
		for piece in Geometry2D.intersect_polygons(poly, _zones[i]):
			if _area(piece) > MIN_OVERLAP:
				return true
	return false


## A rectangle of local x in [-hx, hx] and local z in [z0, z1], posed at `pos`
## with `yaw` (Godot's Y rotation: local (x, z) -> (x cos + z sin, -x sin + z cos)).
static func _rect(pos: Vector2, yaw: float, hx: float, z0: float, z1: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for corner: Vector2 in [Vector2(-hx, z0), Vector2(hx, z0), Vector2(hx, z1), Vector2(-hx, z1)]:
		points.append(pos + Vector2(
			corner.x * cos(yaw) + corner.y * sin(yaw), -corner.x * sin(yaw) + corner.y * cos(yaw)
		))
	return points


static func _hits(poly: PackedVector2Array, others: Array[PackedVector2Array]) -> bool:
	for other in others:
		for piece in Geometry2D.intersect_polygons(poly, other):
			if _area(piece) > MIN_OVERLAP:
				return true
	return false


static func _area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return absf(total) * 0.5
