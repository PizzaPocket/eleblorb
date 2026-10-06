class_name ClearZones
extends RefCounted

## The standing rule behind "nothing blocks a doorway": every opening, ramp and
## fire registers the floor area people need around it, and the village
## validator fails any furniture that stands inside one. Added after the
## 2026-10-04 Ohio walkthrough found barrels in front of the larder door,
## stools in front of a bedroom door and sacks on the mill ramp, each placed by
## hand with nothing to say it was wrong.
##
## Three registrations, all stored as metadata on the body that owns them so the
## check needs no extra bookkeeping:
##   add()       an oriented floor rectangle that furniture must leave clear.
##   add_lane()  a walking line (a ramp) that must stay open to a person's full
##               height, checked with the physics engine.
##   mark_furniture() tags a collision shape as furniture (Furnishings.piece
##               does this for every solid piece).
##
## Kinds: "door" (a doorway and its approach), "ramp" (a ramp's sides and
## landings), "fire" (the space in front of a hearth; seating stays back).

const ZONES_META := "clear_zones"
const LANES_META := "walk_lanes"
const FURNITURE_META := "furniture"
const FIRE_OK_META := "fire_ok"
const WALLS_META := "struct_walls"
const VOIDS_META := "struct_voids"
const SUPPORTS_META := "struct_supports"

const PERSON_RADIUS := 0.28
const PERSON_HEIGHT := 1.65
## A person's feet may clear a kerb or a stair edge this high.
const STEP_ALLOWANCE := 0.35
const LANE_SAMPLE := 0.3
## Minimum overlap area (m^2) that counts, so edges that merely touch pass.
const MIN_OVERLAP := 0.015


## Registers a rectangle in `body`'s local frame. `dir` is the unit direction
## of travel through it (out of a door, up a ramp, away from a fire); the
## rectangle extends `behind` back from `center` and `ahead` forward along it,
## `half_across` to each side, from `y0` to `y1` above the body's origin.
static func add(
	body: Node3D, label: String, kind: String, center: Vector2, dir: Vector2,
	behind: float, ahead: float, half_across: float, y0: float, y1: float
) -> void:
	var zones: Array = body.get_meta(ZONES_META, [])
	zones.append({
		"label": label, "kind": kind, "center": center, "dir": dir.normalized(),
		"behind": behind, "ahead": ahead, "across": half_across, "y0": y0, "y1": y1,
	})
	body.set_meta(ZONES_META, zones)


## Registers a walking line in `body`'s local frame: points are (x, floor y, z).
## `radius` is half the width a person needs: 0.28 through a doorway, 0.55 along
## a corridor or gallery that must pass two people comfortably (1.1 m).
static func add_lane(body: Node3D, label: String, points: Array[Vector3], radius: float = PERSON_RADIUS) -> void:
	var lanes: Array = body.get_meta(LANES_META, [])
	lanes.append({"label": label, "points": points, "radius": radius})
	body.set_meta(LANES_META, lanes)


## The structural record the stacking audit reads (see audit_stacking). All are
## in the body's local plan frame (x, z) with heights above the body origin.
##   add_wall    a wall run: full height from `base_y`, thickness in metres.
##   add_void    a hole through the deck at `deck_y` (a stairwell, a double-height
##               hall): a polygon in plan.
##   add_support a beam or a post carrying the deck at `deck_y`.
static func add_wall(body: Node3D, label: String, from: Vector2, to: Vector2, base_y: float, height: float, thickness: float = 0.16, exterior: bool = false) -> void:
	var walls: Array = body.get_meta(WALLS_META, [])
	walls.append({"label": label, "from": from, "to": to, "base_y": base_y, "height": height, "thickness": thickness, "exterior": exterior})
	body.set_meta(WALLS_META, walls)


static func add_void(body: Node3D, label: String, deck_y: float, polygon: PackedVector2Array) -> void:
	var voids: Array = body.get_meta(VOIDS_META, [])
	voids.append({"label": label, "deck_y": deck_y, "polygon": polygon})
	body.set_meta(VOIDS_META, voids)


static func add_support(body: Node3D, label: String, kind: String, from: Vector2, to: Vector2, deck_y: float) -> void:
	var supports: Array = body.get_meta(SUPPORTS_META, [])
	supports.append({"label": label, "kind": kind, "from": from, "to": to, "deck_y": deck_y})
	body.set_meta(SUPPORTS_META, supports)


## A superellipse hole centred on `center` with half sizes `half` and exponent
## `n`, as a plan polygon, for add_void().
static func superellipse_polygon(center: Vector2, half: Vector2, n: float = 4.0, steps: int = 48) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps:
		var angle := TAU * float(i) / float(steps)
		var c := cos(angle)
		var s := sin(angle)
		points.append(center + Vector2(
			half.x * signf(c) * pow(absf(c), 2.0 / n), half.y * signf(s) * pow(absf(s), 2.0 / n)
		))
	return points


## Tags a collision shape as furniture. `fire_ok` exempts small hearth tools
## (a log basket, fire irons) from the fire zone.
static func mark_furniture(shape: CollisionShape3D, fire_ok: bool = false) -> void:
	shape.set_meta(FURNITURE_META, true)
	if fire_ok:
		shape.set_meta(FIRE_OK_META, true)


# ---------------------------------------------------------------------------
# Audit
# ---------------------------------------------------------------------------

## Returns one message per violation under `root`.
static func audit(root: Node3D) -> Array[String]:
	var zones: Array[Dictionary] = []
	var lanes: Array[Dictionary] = []
	var shapes: Array[Dictionary] = []
	_collect(root, zones, lanes, shapes)
	var problems: Array[String] = []
	for zone in zones:
		for shape in shapes:
			if str(zone["kind"]) == "fire" and bool(shape["fire_ok"]):
				continue
			if _overlaps(zone, shape):
				problems.append("%s blocks the %s clear zone '%s' at (%.1f, %.1f)" % [
					shape["name"], zone["kind"], zone["label"], (zone["polygon"] as PackedVector2Array)[0].x,
					(zone["polygon"] as PackedVector2Array)[0].y,
				])
	problems.append_array(_audit_lanes(root, lanes))
	problems.append_array(audit_stacking(root))
	problems.append_array(_audit_furniture_in_walls(root, shapes))
	_collect_layout_failures(root, problems)
	return problems


## Pieces a RoomLayout could not place (no room anywhere that respects the
## doors, ramp and fire) are recorded on the building; they are findings too.
static func _collect_layout_failures(node: Node, problems: Array[String]) -> void:
	if node.has_meta("layout_failures"):
		for failure: String in node.get_meta("layout_failures"):
			problems.append("%s: %s" % [node.name, failure])
	for child in node.get_children():
		_collect_layout_failures(child, problems)


static func _collect(node: Node, zones: Array[Dictionary], lanes: Array[Dictionary], shapes: Array[Dictionary]) -> void:
	if node is Node3D:
		var body := node as Node3D
		if body.has_meta(ZONES_META) and body.is_inside_tree():
			for zone: Dictionary in body.get_meta(ZONES_META):
				zones.append(_world_zone(body, zone))
		if body.has_meta(LANES_META) and body.is_inside_tree():
			for lane: Dictionary in body.get_meta(LANES_META):
				var points: Array[Vector3] = []
				for point: Vector3 in lane["points"]:
					points.append(body.global_transform * point)
				lanes.append({"label": lane["label"], "points": points, "radius": lane.get("radius", PERSON_RADIUS)})
	if node is CollisionShape3D:
		var shape_node := node as CollisionShape3D
		var parent := shape_node.get_parent()
		var tagged := shape_node.has_meta(FURNITURE_META) or (parent != null and parent.has_meta(FURNITURE_META))
		if tagged and shape_node.shape is BoxShape3D and shape_node.is_inside_tree() and not shape_node.disabled:
			shapes.append(_world_box(shape_node))
	for child in node.get_children():
		_collect(child, zones, lanes, shapes)


## A zone's rectangle in the owning body's own plane (x, z).
static func local_polygon(zone: Dictionary) -> PackedVector2Array:
	var center: Vector2 = zone["center"]
	var dir: Vector2 = zone["dir"]
	var across_dir := Vector2(-dir.y, dir.x)
	var behind: float = zone["behind"]
	var ahead: float = zone["ahead"]
	var across: float = zone["across"]
	return PackedVector2Array([
		center - dir * behind - across_dir * across, center + dir * ahead - across_dir * across,
		center + dir * ahead + across_dir * across, center - dir * behind + across_dir * across,
	])


static func _world_zone(body: Node3D, zone: Dictionary) -> Dictionary:
	var transform := body.global_transform
	var center: Vector2 = zone["center"]
	var dir: Vector2 = zone["dir"]
	var across_dir := Vector2(-dir.y, dir.x)
	var behind: float = zone["behind"]
	var ahead: float = zone["ahead"]
	var across: float = zone["across"]
	var corners_local: Array[Vector2] = [
		center - dir * behind - across_dir * across, center + dir * ahead - across_dir * across,
		center + dir * ahead + across_dir * across, center - dir * behind + across_dir * across,
	]
	var polygon := PackedVector2Array()
	for corner in corners_local:
		var world := transform * Vector3(corner.x, 0.0, corner.y)
		polygon.append(Vector2(world.x, world.z))
	var origin_y := transform.origin.y
	return {
		"label": zone["label"], "kind": zone["kind"], "polygon": polygon,
		"y0": origin_y + float(zone["y0"]), "y1": origin_y + float(zone["y1"]),
	}


static func _world_box(shape_node: CollisionShape3D) -> Dictionary:
	var size: Vector3 = (shape_node.shape as BoxShape3D).size
	var transform := shape_node.global_transform
	var points := PackedVector2Array()
	var y_min := INF
	var y_max := -INF
	for sx in [-0.5, 0.5]:
		for sy in [-0.5, 0.5]:
			for sz in [-0.5, 0.5]:
				var world := transform * Vector3(size.x * sx, size.y * sy, size.z * sz)
				points.append(Vector2(world.x, world.z))
				y_min = minf(y_min, world.y)
				y_max = maxf(y_max, world.y)
	var parent := shape_node.get_parent()
	var label := str(parent.name) if parent != null else str(shape_node.name)
	if parent != null and parent.get_parent() != null and label.begins_with("@"):
		label = str(parent.get_parent().name)
	return {
		"ground": _storey_ground(shape_node),
		"name": "%s piece %s (%.2f x %.2f x %.2f) at (%.1f, %.1f)" % [
			label, _piece_name(shape_node), size.x, size.y, size.z, transform.origin.x, transform.origin.z,
		],
		"polygon": Geometry2D.convex_hull(points), "y0": y_min, "y1": y_max,
		"fire_ok": shape_node.has_meta(FIRE_OK_META),
	}


## The piece a collision box belongs to: its sibling mesh at the same place, so a
## report can say "table top" or "bed" rather than only "box".
static func _piece_name(shape_node: CollisionShape3D) -> String:
	var parent := shape_node.get_parent()
	if parent == null:
		return "?"
	var best := ""
	var best_distance := 0.2
	for sibling in parent.get_children():
		if sibling is MeshInstance3D and (sibling as MeshInstance3D).mesh != null:
			var distance := (sibling as Node3D).position.distance_to(shape_node.position)
			if distance < best_distance:
				best_distance = distance
				var mesh_resource := (sibling as MeshInstance3D).mesh
				best = str(mesh_resource.resource_name) if mesh_resource.resource_name != "" else str(sibling.name)
	return best if best != "" else str(shape_node.name)


static func _overlaps(zone: Dictionary, shape: Dictionary) -> bool:
	if float(shape["y1"]) <= float(zone["y0"]) + 0.02 or float(shape["y0"]) >= float(zone["y1"]):
		return false
	var pieces := Geometry2D.intersect_polygons(zone["polygon"] as PackedVector2Array, shape["polygon"] as PackedVector2Array)
	for piece in pieces:
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


## A person-sized cylinder is swept along every lane, lifted over the surface it
## walks on by a step height. Anything it touches (a sack, a floor slab, a
## beam) is something a person would hit, so headroom and blockers are one test.
static func _audit_lanes(root: Node3D, lanes: Array[Dictionary]) -> Array[String]:
	var problems: Array[String] = []
	if lanes.is_empty() or not root.is_inside_tree():
		return problems
	var space := root.get_world_3d().direct_space_state
	for lane in lanes:
		var cylinder := CylinderShape3D.new()
		cylinder.radius = float(lane.get("radius", PERSON_RADIUS))
		cylinder.height = PERSON_HEIGHT
		var points: Array[Vector3] = lane["points"]
		var reported := false
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var steps := maxi(int(a.distance_to(b) / LANE_SAMPLE), 1)
			for s in steps + 1:
				var at := a.lerp(b, float(s) / float(steps))
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape = cylinder
				query.transform = Transform3D(Basis(), at + Vector3(0.0, STEP_ALLOWANCE + PERSON_HEIGHT * 0.5, 0.0))
				query.collision_mask = 1
				var hits := space.intersect_shape(query, 4)
				if not hits.is_empty() and not reported:
					var collider := hits[0]["collider"] as Node
					var obstruction: String = str(collider.name) if collider != null else "?"
					if collider is CollisionObject3D and hits[0].has("shape"):
						var shape_index := int(hits[0]["shape"])
						var owner_id := (collider as CollisionObject3D).shape_find_owner(shape_index)
						var owner: Object = (collider as CollisionObject3D).shape_owner_get_owner(owner_id)
						if owner is Node:
							obstruction += "/" + str((owner as Node).name)
						if owner is CollisionShape3D:
							var obstruction_shape := owner as CollisionShape3D
							obstruction += " at %s" % str(obstruction_shape.global_position)
							if obstruction_shape.shape is BoxShape3D:
								obstruction += " size %s" % str((obstruction_shape.shape as BoxShape3D).size)
					problems.append("walking lane '%s' is blocked or too low at (%.2f, %.2f, %.2f) by %s" % [
						lane["label"], at.x, at.y, at.z, obstruction,
					])
					reported = true
	return problems


# ---------------------------------------------------------------------------
# Stacking: floor plans must agree with the storeys above and below
# ---------------------------------------------------------------------------

const SAMPLE := 0.35


## A building's storeys are drawn against one another. Two failures this audit
## catches (both found in the Holt Inn on 2026-10-04):
##   1. A wall on one floor runs into the opening cut through the floor above
##      it (a hearth hall, a stairwell): its top stands free in the void.
##   2. A wall on an upper floor stands on a void in its own deck.
## An upper wall with no wall or beam directly below it is not a failure: most
## upper walls are light partitions that sit on the floor joists. Supports are
## still recorded for whatever builds beams or posts, but are not audited.
## Registered by TownProps (walls, voids) and by whatever builds beams or posts.
static func audit_stacking(root: Node3D) -> Array[String]:
	var groups := {}
	_collect_structure(root, groups)
	var problems: Array[String] = []
	for key in groups:
		var group: Dictionary = groups[key]
		var walls: Array = group["walls"]
		var voids: Array = group["voids"]
		for wall: Dictionary in walls:
			var floor_index := int(roundf(float(wall["base_y"]) / TownProps.FLOOR_HEIGHT))
			var length := (wall["to"] as Vector2).distance_to(wall["from"] as Vector2)
			var steps := maxi(int(length / SAMPLE), 1)
			var inside_above := 0.0
			var inside_own := 0.0
			for i in steps + 1:
				var point := (wall["from"] as Vector2).lerp(wall["to"] as Vector2, float(i) / float(steps))
				for void_item: Dictionary in voids:
					var deck_floor := int(roundf(float(void_item["deck_y"]) / TownProps.FLOOR_HEIGHT))
					var inside := Geometry2D.is_point_in_polygon(point, void_item["polygon"] as PackedVector2Array)
					if inside and deck_floor == floor_index + 1:
						inside_above += length / float(steps)
					if inside and deck_floor == floor_index and floor_index >= 1:
						inside_own += length / float(steps)
			if inside_above > 0.15:
				problems.append("%s: wall '%s' rises into the opening above it for %.1f m (a wall may not run under a void in the next floor)" % [key, wall["label"], inside_above])
			if inside_own > 0.15:
				problems.append("%s: wall '%s' stands over a hole in its own floor for %.1f m" % [key, wall["label"], inside_own])
	return problems


## Walls, voids and supports from every registering body, in world plan
## coordinates, grouped by the building they belong to (bodies of one building
## share an origin).
static func _collect_structure(node: Node, groups: Dictionary) -> void:
	if node is Node3D and (node.has_meta(WALLS_META) or node.has_meta(VOIDS_META) or node.has_meta(SUPPORTS_META)) and node.is_inside_tree():
		var body := node as Node3D
		var key := "%s@(%.1f, %.1f)" % [str(body.get_parent().name) if body.get_parent() != null else "?", body.global_position.x, body.global_position.z]
		# Bodies of one building share the building's origin; the inn's wall bodies
		# are children of the inn node, so key by position only.
		key = "building at (%.1f, %.1f)" % [snappedf(body.global_position.x, 0.1), snappedf(body.global_position.z, 0.1)]
		if not groups.has(key):
			groups[key] = {"walls": [], "voids": [], "supports": []}
		var group: Dictionary = groups[key]
		var transform := body.global_transform
		for wall: Dictionary in body.get_meta(WALLS_META, []):
			var from_world := transform * Vector3((wall["from"] as Vector2).x, 0.0, (wall["from"] as Vector2).y)
			var to_world := transform * Vector3((wall["to"] as Vector2).x, 0.0, (wall["to"] as Vector2).y)
			(group["walls"] as Array).append({
				"label": wall["label"], "from": Vector2(from_world.x, from_world.z), "to": Vector2(to_world.x, to_world.z),
				"base_y": wall["base_y"], "height": wall["height"], "thickness": wall["thickness"], "exterior": wall["exterior"],
			})
		for void_item: Dictionary in body.get_meta(VOIDS_META, []):
			var polygon := PackedVector2Array()
			for point in void_item["polygon"] as PackedVector2Array:
				var world := transform * Vector3(point.x, 0.0, point.y)
				polygon.append(Vector2(world.x, world.z))
			(group["voids"] as Array).append({"label": void_item["label"], "deck_y": void_item["deck_y"], "polygon": polygon})
		for support: Dictionary in body.get_meta(SUPPORTS_META, []):
			var from_world := transform * Vector3((support["from"] as Vector2).x, 0.0, (support["from"] as Vector2).y)
			var to_world := transform * Vector3((support["to"] as Vector2).x, 0.0, (support["to"] as Vector2).y)
			(group["supports"] as Array).append({
				"label": support["label"], "kind": support["kind"], "from": Vector2(from_world.x, from_world.z),
				"to": Vector2(to_world.x, to_world.z), "deck_y": support["deck_y"],
			})
	for child in node.get_children():
		_collect_structure(child, groups)


## Furniture must not stand inside a wall: any tagged furniture box that overlaps
## a registered wall run at its height. (Snow report S1: pieces clipping through
## walls everywhere.)
static func _audit_furniture_in_walls(root: Node3D, shapes: Array[Dictionary]) -> Array[String]:
	var groups := {}
	_collect_structure(root, groups)
	var wall_polygons: Array[Dictionary] = []
	for key in groups:
		for wall: Dictionary in (groups[key] as Dictionary)["walls"]:
			var from: Vector2 = wall["from"]
			var to: Vector2 = wall["to"]
			var direction := (to - from)
			if direction.length() < 0.05:
				continue
			direction = direction.normalized()
			var across := Vector2(-direction.y, direction.x) * float(wall["thickness"]) * 0.5
			var body_y := _ground_of(root, from)
			wall_polygons.append({
				"label": wall["label"], "key": key,
				"polygon": PackedVector2Array([from - across, to - across, to + across, from + across]),
				"y0": float(wall["base_y"]), "y1": float(wall["base_y"]) + float(wall["height"]),
			})
	var problems: Array[String] = []
	for shape in shapes:
		for wall in wall_polygons:
			var pieces := Geometry2D.intersect_polygons(wall["polygon"] as PackedVector2Array, shape["polygon"] as PackedVector2Array)
			var overlap := 0.0
			for piece in pieces:
				overlap += _area(piece)
			if overlap > 0.02 and _heights_overlap(shape, wall):
				problems.append("%s stands inside wall '%s' (%s)" % [shape["name"], wall["label"], wall["key"]])
	return problems


static func _ground_of(_root: Node3D, _at: Vector2) -> float:
	return 0.0


## Heights are compared relative to each shape's own storey, so the test uses the
## shape's height above the lowest wall base of its building: here, the wall's
## own base against the shape's height above ground, both measured from the
## body that owns them.
static func _heights_overlap(shape: Dictionary, wall: Dictionary) -> bool:
	var base := float(shape.get("ground", 0.0))
	return float(shape["y1"]) - base > float(wall["y0"]) + 0.05 and float(shape["y0"]) - base < float(wall["y1"]) - 0.05


## The world height of the ground the piece's building stands on: the origin
## height of the nearest ancestor body that owns structural records.
static func _storey_ground(shape_node: Node) -> float:
	var node := shape_node.get_parent()
	while node != null:
		if node is Node3D and (node.has_meta(WALLS_META) or node.has_meta(ZONES_META) or node.has_meta(VOIDS_META)):
			return (node as Node3D).global_position.y
		node = node.get_parent()
	return 0.0
