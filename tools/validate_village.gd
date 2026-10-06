extends Node

## Layout validator: loads a world, lets it finish building, asks its Town for
## the layout it actually built (TownGenerator.layout_report) and checks it
## against the architecture skill's rules: overlapping or too-close buildings,
## doors that are blocked or unreachable, enclosures without a lined-up gate,
## things that face a wall, and worn paths that stop in grass.
##
##   Godot --path . tools/validate_village.tscn -- --village=ohio
##
## Exit code 1 if anything FAILs. WARN lines are advisory.

const TARGETS := {"ohio": "res://scenes/main.tscn", "snow": "res://scenes/ice_kingdom.tscn"}
const TOWN_NODES := {"ohio": "Town", "snow": "SnowVillage"}
const MIN_GAP_FAIL := 1.5
const MIN_GAP_WARN := 3.0
const EAVE := 0.3
const DOOR_DEPTH := 2.0
const BODY_RADIUS := 0.35
const GRID := 0.5
## The walkable plan runs from the village out over the hills to the mill.
var GRID_MIN := Vector2(-80.0, -170.0)
var GRID_SIZE := Vector2(180.0, 235.0)
const PATH_JOIN := 2.2

var _failures := 0
var _warnings := 0


func _ready() -> void:
	var name := "ohio"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--village="):
			name = arg.trim_prefix("--village=")
	if not TARGETS.has(name):
		push_error("Unknown village %s" % name)
		get_tree().quit(2)
		return
	_run.call_deferred(name)


func _run(name: String) -> void:
	var world := (load(TARGETS[name]) as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 10:
		await get_tree().process_frame
	var town := world.get_node(str(TOWN_NODES[name]))
	var report: Dictionary = town.layout_report()
	GRID_MIN = report.get("grid_min", GRID_MIN)
	GRID_SIZE = report.get("grid_size", GRID_SIZE)
	if name == "snow":
		_check_snow_plan(report)
		_check_trade(SnowPlan.TRADE, report)
		_check_ski_lift(world)
	else:
		_check_plan(report)
		_check_trade(OhioPlan.TRADE, report)
	_check_overlaps(report)
	_check_doors(report)
	_check_facing(report)
	_check_lanterns(report)
	await _check_clear_zones(town)
	_check_door_frames(town)
	_check_chest_orientation(town)
	_check_gates(report)
	_check_paths(report)
	if name == "ohio":
		_check_daily_schedules(report, OhioPlan.HOMES, OhioPlan.DAILY_SCHEDULES)
	else:
		_check_daily_schedules(report, SnowPlan.HOMES, SnowPlan.DAILY_SCHEDULES)
	_check_stop_overlaps(OhioPlan.DAILY_SCHEDULES if name == "ohio" else SnowPlan.DAILY_SCHEDULES)
	print("---- validate_village (%s): %d FAIL, %d WARN" % [name, _failures, _warnings])
	get_tree().quit(1 if _failures > 0 else 0)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)


func _warn(message: String) -> void:
	_warnings += 1
	print("WARN ", message)


# ---------------------------------------------------------------------------
# Geometry
# ---------------------------------------------------------------------------

func _corners(solid: Dictionary, grow: float = 0.0) -> PackedVector2Array:
	var center: Vector2 = solid["center"]
	var half: Vector2 = (solid["half"] as Vector2) + Vector2(grow, grow)
	var yaw: float = solid["yaw"]
	var ax := Vector2(cos(yaw), -sin(yaw))
	var az := Vector2(sin(yaw), cos(yaw))
	return PackedVector2Array([
		center + ax * half.x + az * half.y, center - ax * half.x + az * half.y,
		center - ax * half.x - az * half.y, center + ax * half.x - az * half.y,
	])


func _polygons_overlap(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	return Geometry2D.intersect_polygons(a, b).size() > 0


func _polygon_distance(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var best := INF
	for polygon in [[a, b], [b, a]]:
		var from: PackedVector2Array = polygon[0]
		var to: PackedVector2Array = polygon[1]
		for point in from:
			for i in to.size():
				var closest := Geometry2D.get_closest_point_to_segment(point, to[i], to[(i + 1) % to.size()])
				best = minf(best, point.distance_to(closest))
	return best


func _point_in_solid(point: Vector2, solid: Dictionary, grow: float = 0.0) -> bool:
	var center: Vector2 = solid["center"]
	var half: Vector2 = (solid["half"] as Vector2) + Vector2(grow, grow)
	var yaw: float = solid["yaw"]
	var offset := point - center
	var local := Vector2(offset.x * cos(yaw) - offset.y * sin(yaw), offset.x * sin(yaw) + offset.y * cos(yaw))
	return absf(local.x) <= half.x and absf(local.y) <= half.y


func _is_building(solid: Dictionary) -> bool:
	return str(solid["kind"]) == "building"


# ---------------------------------------------------------------------------
# Checks
# ---------------------------------------------------------------------------


## Every purchasable item on a stall must be explained: someone makes or gathers
## it, in a building that exists, and someone carries it to the stall when it
## is not made where it is sold. The inventory tells a story, so the story must
## be in the data.
func _check_trade(ledger: Dictionary, report: Dictionary) -> void:
	var building_names := {}
	for solid in report["solids"]:
		building_names[str(solid["name"])] = true
	for vendor: String in ledger.keys():
		var entry: Dictionary = ledger[vendor]
		var goods: Dictionary = entry["goods"]
		var stocked := {}
		for item in ShopCatalog.get_items_for_shop(str(entry["category"])):
			if item.get("purchasable", false):
				stocked[str(item["name"])] = true
		for item_name: String in stocked.keys():
			if not goods.has(item_name):
				_fail("%s sells %s but the trade ledger gives it no source" % [vendor, item_name])
		for item_name: String in goods.keys():
			var good: Dictionary = goods[item_name]
			if not stocked.has(item_name):
				_fail("The ledger says %s sells %s, but the shop does not stock it" % [vendor, item_name])
			var origin := str(good["at"])
			if origin != "" and not building_names.has(origin):
				_fail("%s's %s is made at %s, which is not in the plan" % [vendor, item_name, origin])
			if origin == "" and str(good["carried_by"]) == "":
				_fail("%s's %s comes from outside the village and nobody carries it in" % [vendor, item_name])


## The Snow Village plan (SnowPlan) is the authority: every building and yard
## feature it names must exist, the yard must stay open from the lake road, and
## the lift lane must join the plaza to the yard.
func _check_snow_plan(report: Dictionary) -> void:
	var built := {}
	for solid in report["solids"]:
		built[str(solid["name"])] = true
	for building in SnowPlan.BUILDINGS:
		if not built.has(str(building["name"])):
			_fail("Plan building %s was not built" % building["name"])
	for feature in SnowPlan.YARD_FEATURES:
		if not built.has(str(feature["name"])):
			_fail("Plan yard feature %s was not built" % feature["name"])
	# The lake road mouth must see into the yard along a 4 m corridor.
	var from := Vector2(26.0, 14.0)
	var to: Vector2 = SnowPlan.YARD_CENTER
	var along := (to - from).normalized()
	var across := Vector2(-along.y, along.x)
	var corridor := PackedVector2Array([from + across * 2.0, from - across * 2.0, to - across * 2.0, to + across * 2.0])
	for solid in report["solids"]:
		var kind := str(solid["kind"])
		if kind in ["tree", "water"] or str(solid["name"]) in ["CommunalHearth", "YardCistern"]:
			continue
		if _polygons_overlap(corridor, _corners(solid)):
			_fail("The view from the lake road into the yard is blocked by %s (%s)" % [solid["name"], kind])


func _check_ski_lift(world: Node) -> void:
	var lift := world.get_node_or_null("SkiLift")
	if lift == null or not lift.has_method("terrain_clearance_report"):
		_fail("Snow world has no testable SkiLift terrain-clearance interface")
		return
	var findings: Array = lift.call("terrain_clearance_report")
	if findings.is_empty():
		return
	var worst: Dictionary = findings[0]
	for finding: Dictionary in findings:
		if float(finding["clearance"]) < float(worst["clearance"]):
			worst = finding
	var point: Vector3 = worst["point"]
	_fail("chairlift clips or nearly clips terrain on span %d at (%.1f, %.1f): %.2f m clearance" % [
		int(worst["segment"]), point.x, point.z, float(worst["clearance"]),
	])

## The plan (OhioPlan) is the authority: everything it names must have been
## built, and the arrival must show the village. A traveller standing between
## the gateway piers has to see the fountain along a corridor 5.6 m wide, with no
## building, yard prop or stall across it.
func _check_plan(report: Dictionary) -> void:
	var built := {}
	for solid in report["solids"]:
		built[str(solid["name"])] = true
	for building in OhioPlan.BUILDINGS:
		if not built.has(str(building["name"])):
			_fail("Plan building %s was not built" % building["name"])
	for needed in ["Windmill", "Fountain", "HoltInn", "GatePier", "OverlookTerrace"]:
		if not built.has(needed):
			_fail("Plan element %s was not built" % needed)
	var from: Vector2 = OhioPlan.ENTRANCE["center"]
	var to := Vector2.ZERO
	var along := (to - from).normalized()
	var across := Vector2(-along.y, along.x)
	var corridor := PackedVector2Array([
		from + across * 2.8, from - across * 2.8, to - across * 2.8, to + across * 2.8,
	])
	for solid in report["solids"]:
		var kind := str(solid["kind"])
		if kind in ["water", "fountain"]:
			continue
		if _polygons_overlap(corridor, _corners(solid)):
			_fail("The view from the entrance to the fountain is blocked by %s (%s)" % [solid["name"], kind])


func _check_overlaps(report: Dictionary) -> void:
	var solids: Array = report["solids"]
	var buildings: Array[Dictionary] = []
	for solid in solids:
		if _is_building(solid):
			buildings.append(solid)
	for i in buildings.size():
		for j in range(i + 1, buildings.size()):
			var a: Dictionary = buildings[i]
			var b: Dictionary = buildings[j]
			# A building built against another (an ice house beside a house, a
			# wing against a hall) is attached by design.
			if str(a.get("attached", "")) == str(b["name"]) or str(b.get("attached", "")) == str(a["name"]):
				continue
			var pa := _corners(a, EAVE)
			var pb := _corners(b, EAVE)
			if _polygons_overlap(pa, pb):
				_fail("%s overlaps %s (footprints incl. eaves)" % [a["name"], b["name"]])
				continue
			var gap := _polygon_distance(pa, pb)
			if gap < MIN_GAP_FAIL:
				_fail("%s and %s are only %.1f m apart (needs %.1f m to walk between)" % [a["name"], b["name"], gap, MIN_GAP_FAIL])
			elif gap < MIN_GAP_WARN:
				_warn("%s and %s are %.1f m apart (prefer %.1f m)" % [a["name"], b["name"], gap, MIN_GAP_WARN])
	# Props must not sit inside buildings or each other's no-go space.
	for solid in solids:
		if _is_building(solid):
			continue
		var kind := str(solid["kind"])
		if kind in ["fence", "hedge", "water"]:
			continue
		for building in buildings:
			if str(solid.get("attached", "")) == str(building["name"]):
				continue
			if _polygons_overlap(_corners(solid), _corners(building, EAVE)):
				_fail("%s (%s) intrudes into %s" % [solid["name"], kind, building["name"]])


func _blocking_solids(report: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for solid in report["solids"]:
		result.append(solid)
	return result


func _check_doors(report: Dictionary) -> void:
	var solids := _blocking_solids(report)
	var doors: Array = report["doors"]
	var grid := _build_walk_grid(report)
	var start: Vector2 = report.get("start", Vector2(0.0, 8.0))
	var reachable := _flood(grid, start)
	for door in doors:
		var pos: Vector2 = door["pos"]
		var dir: Vector2 = door["dir"]
		var width: float = door["width"]
		var label := "%s door at (%.1f, %.1f)" % [door["name"], pos.x, pos.y]
		# Clear rectangle in front of the door.
		var side := Vector2(-dir.y, dir.x)
		var box := PackedVector2Array([
			pos + side * (width * 0.5 + 0.3), pos - side * (width * 0.5 + 0.3),
			pos - side * (width * 0.5 + 0.3) + dir * DOOR_DEPTH, pos + side * (width * 0.5 + 0.3) + dir * DOOR_DEPTH,
		])
		var shifted := box.duplicate()
		for i in shifted.size():
			shifted[i] = shifted[i] + dir * 0.15
		for solid in solids:
			var own := str(solid["name"]).begins_with(str(door["name"]).replace(" (back)", ""))
			if own and _is_building(solid):
				continue
			var kind := str(solid["kind"])
			if kind == "water" and _near_bridge(report, pos):
				continue
			if _polygons_overlap(shifted, _corners(solid)):
				_fail("%s is blocked in front by %s (%s)" % [label, solid["name"], kind])
		var front := pos + dir * 1.2
		if not _is_reachable(grid, reachable, front):
			_fail("%s cannot be reached on foot from the green" % label)


func _near_bridge(report: Dictionary, at: Vector2) -> bool:
	return at.distance_to(report["bridge"]) < 5.0


func _build_walk_grid(report: Dictionary) -> Dictionary:
	var cells := Vector2i(int(GRID_SIZE.x / GRID), int(GRID_SIZE.y / GRID))
	var blocked := PackedByteArray()
	blocked.resize(cells.x * cells.y)
	var bridge: Vector2 = report["bridge"]
	for solid in report["solids"]:
		var grow := BODY_RADIUS
		var kind := str(solid["kind"])
		var corners := _corners(solid, grow)
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for corner in corners:
			lo = lo.min(corner)
			hi = hi.max(corner)
		var first := _cell(lo) - Vector2i(1, 1)
		var last := _cell(hi) + Vector2i(2, 2)
		for ix in range(maxi(first.x, 0), mini(last.x, cells.x)):
			for iz in range(maxi(first.y, 0), mini(last.y, cells.y)):
				var point := GRID_MIN + Vector2(float(ix) + 0.5, float(iz) + 0.5) * GRID
				if kind == "water" and point.distance_to(bridge) < 2.4:
					continue
				if _point_in_solid(point, solid, grow):
					blocked[iz * cells.x + ix] = 1
	return {"cells": cells, "blocked": blocked}


func _cell(point: Vector2) -> Vector2i:
	return Vector2i(int((point.x - GRID_MIN.x) / GRID), int((point.y - GRID_MIN.y) / GRID))


func _flood(grid: Dictionary, start: Vector2) -> PackedByteArray:
	var cells: Vector2i = grid["cells"]
	var blocked: PackedByteArray = grid["blocked"]
	var seen := PackedByteArray()
	seen.resize(cells.x * cells.y)
	var begin := _cell(start)
	var queue: Array[Vector2i] = [begin]
	seen[begin.y * cells.x + begin.x] = 1
	while not queue.is_empty():
		var current: Vector2i = queue.pop_back()
		for step in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var next: Vector2i = current + step
			if next.x < 0 or next.y < 0 or next.x >= cells.x or next.y >= cells.y:
				continue
			var index := next.y * cells.x + next.x
			if seen[index] == 1 or blocked[index] == 1:
				continue
			seen[index] = 1
			queue.append(next)
	return seen


func _is_reachable(grid: Dictionary, seen: PackedByteArray, point: Vector2) -> bool:
	var cells: Vector2i = grid["cells"]
	var cell := _cell(point)
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var x := cell.x + dx
			var z := cell.y + dz
			if x >= 0 and z >= 0 and x < cells.x and z < cells.y and seen[z * cells.x + x] == 1:
				return true
	return false


func _check_facing(report: Dictionary) -> void:
	for item in report["facing"]:
		var pos: Vector2 = item["pos"]
		var dir: Vector2 = item["dir"]
		var label := "%s at (%.1f, %.1f)" % [item["name"], pos.x, pos.y]
		for solid in report["solids"]:
			if not _is_building(solid):
				continue
			for distance in [1.0, 2.0, 3.0]:
				if _point_in_solid(pos + dir * distance, solid, EAVE):
					_fail("%s faces %s only %.0f m away" % [label, solid["name"], distance])
					break
		if str(item["kind"]) == "notice":
			var toward_square := (-pos).normalized()
			if dir.dot(toward_square) < 0.3:
				_fail("%s does not face the square" % label)


## A lantern's lit bracket is local -Z. It must reach toward the road, green or
## terrace it serves, not away from it, and its head must not hang inside a
## building. The 2026-10-04 walkthrough found every roadside standard facing
## away because yaws were typed in by hand.
func _check_lanterns(report: Dictionary) -> void:
	for lantern in report.get("lanterns", []):
		var pos: Vector2 = lantern["pos"]
		var yaw: float = lantern["yaw"]
		var serves: Vector2 = lantern["serves"]
		var arm := Vector2(-sin(yaw), -cos(yaw))
		var label := "%s at (%.1f, %.1f)" % [lantern["name"], pos.x, pos.y]
		var wanted := (serves - pos).normalized()
		if arm.dot(wanted) < 0.7:
			_fail("%s: bracket points away from what it serves (%.2f alignment)" % [label, arm.dot(wanted)])
		var head := pos + arm * 0.9
		for solid in report["solids"]:
			if _is_building(solid) and _point_in_solid(head, solid, 0.0):
				_fail("%s: lantern head hangs inside %s" % [label, solid["name"]])


## Furniture must leave doors, ramp approaches and the space in front of a fire
## clear, and every ramp must stay open to a person's full height (ClearZones).
## The check is physical, so it waits for the world's physics to settle first.
func _check_clear_zones(town: Node) -> void:
	for _i in 4:
		await get_tree().physics_frame
	if town is Node3D:
		for problem in ClearZones.audit(town as Node3D):
			_fail(problem)


## Two residents must not be asked to stand in the same place at the same hour.
## The walkthrough found Tess's stop on top of Petra's post. Every half hour, the
## active stop of each resident is compared with every other's; stops whose
## wander circles overlap by more than half are a failure.
func _check_stop_overlaps(schedules: Dictionary) -> void:
	var names: Array = schedules.keys()
	var hour := 0.0
	var reported := {}
	while hour < 24.0:
		var stops := {}
		for resident: String in names:
			var entries: Array = schedules[resident]
			var active: Dictionary = entries[entries.size() - 1]
			for entry: Dictionary in entries:
				if hour >= float(entry["hour"]):
					active = entry
			stops[resident] = active
		for i in names.size():
			for j in range(i + 1, names.size()):
				var a: Dictionary = stops[names[i]]
				var b: Dictionary = stops[names[j]]
				var reach := (float(a.get("range", 2.5)) + float(b.get("range", 2.5))) * 0.5
				var distance := (a["at"] as Vector2).distance_to(b["at"] as Vector2)
				if distance < reach:
					var key := "%s|%s" % [names[i], names[j]]
					if not reported.has(key):
						reported[key] = true
						_warn("%s and %s are both stationed near (%.1f, %.1f) at %.1f h" % [names[i], names[j], a["at"].x, a["at"].y, hour])
		hour += 0.5


## A door frame's jamb ends must stay inside the floor slab they stand on. Upper
## floors are only 0.12 m thick below the floor line, so a frame that sinks further
## shows below the ceiling of the room underneath.
func _check_door_frames(town: Node) -> void:
	var count := 0
	for node in town.find_children("DoorFrame", "MeshInstance3D", true, false):
		var frame := node as MeshInstance3D
		var pivot := frame.get_parent() as Node3D
		if pivot == null or pivot.position.y < 0.5:
			continue
		count += 1
		var lowest := frame.position.y + frame.mesh.get_aabb().position.y
		if lowest < -0.115:
			_fail("a door frame on an upper floor reaches %.2f m below its floor (the slab is 0.12 m thick) at (%.1f, %.1f)" % [-lowest, pivot.global_position.x, pivot.global_position.z])
	print("checked %d upper-floor door frames" % count)


## A chest's hinge is on its back (local +Z). A chest at the foot of a bed has its
## hinge toward the bed, so the lid lifts away from the person standing at the foot,
## not toward them. Beds are modelled head toward -Z, so the foot is local +Z.
func _check_chest_orientation(town: Node) -> void:
	var beds: Array[Node3D] = []
	var chests: Array[Node3D] = []
	for node in town.find_children("*", "StaticBody3D", true, false):
		var body := node as Node3D
		if body.has_meta(ClearZones.FURNITURE_META) and body.get_script() == null and "Bed" in str(body.name):
			beds.append(body)
		elif str(body.name).begins_with("LootChest"):
			chests.append(body)
	for chest in chests:
		for bed in beds:
			if absf(chest.global_position.y - bed.global_position.y) > 0.3:
				continue
			var offset := Vector2(chest.global_position.x - bed.global_position.x, chest.global_position.z - bed.global_position.z)
			var foot := Vector2((bed.global_transform.basis * Vector3(0, 0, 1)).x, (bed.global_transform.basis * Vector3(0, 0, 1)).z).normalized()
			var along := offset.dot(foot)
			var across := absf(offset.dot(Vector2(-foot.y, foot.x)))
			if along < 1.2 or along > 2.4 or across > 0.9:
				continue
			var back := Vector2((chest.global_transform.basis * Vector3(0, 0, 1)).x, (chest.global_transform.basis * Vector3(0, 0, 1)).z).normalized()
			if back.dot(-foot) < 0.7:
				_fail("chest at the foot of %s at (%.1f, %.1f) has its hinge turned away from the bed" % [bed.name, chest.global_position.x, chest.global_position.z])


func _check_gates(report: Dictionary) -> void:
	# Every gate should have a path or a door within reach on its approach side.
	for gate in report["gates"]:
		var pos: Vector2 = gate["pos"]
		var dir: Vector2 = gate["dir"]
		var approach: Vector2 = pos - dir * 2.5
		var served := false
		for door in report["doors"]:
			if (door["pos"] as Vector2).distance_to(pos) < 14.0:
				served = true
		for stroke in report["strokes"]:
			if _distance_to_polyline(approach, stroke["points"]) < 2.5:
				served = true
		if not served:
			_warn("gate at (%.1f, %.1f) has no door or path serving it" % [pos.x, pos.y])


func _distance_to_polyline(point: Vector2, points: Array) -> float:
	var best := INF
	for i in points.size() - 1:
		var closest := Geometry2D.get_closest_point_to_segment(point, points[i], points[i + 1])
		best = minf(best, point.distance_to(closest))
	return best


func _check_paths(report: Dictionary) -> void:
	# A path may end at a destination. What must never happen is a strip of
	# unworn grass left between a worn area and another worn area, doorstep or
	# gate that traffic plainly crosses: so an end that touches nothing but lies
	# near something is a gap to close.
	var strokes: Array = report["strokes"]
	for index in strokes.size():
		var points: Array = strokes[index]["points"]
		if points.size() < 2:
			continue
		for end_index in [0, points.size() - 1]:
			var end: Vector2 = points[end_index]
			if end.length() > 55.0:
				continue
			var nearest := _distance_to_worn(report, end, index)
			if nearest <= 0.5:
				continue
			var destination := _near_destination(report, end)
			if destination:
				continue
			if nearest < 9.0:
				_fail("path %d ends at (%.1f, %.1f), %.1f m short of other worn ground (a gap of unworn grass in the line of traffic)" % [index, end.x, end.y, nearest])
			else:
				_warn("path %d ends at (%.1f, %.1f) with no destination near" % [index, end.x, end.y])
	# Doors and gates must stand on worn ground.
	for door in report["doors"]:
		var front: Vector2 = (door["pos"] as Vector2) + (door["dir"] as Vector2) * 0.9
		if _distance_to_worn(report, front, -1) > 0.5:
			_fail("%s door at (%.1f, %.1f) opens onto unworn ground" % [door["name"], front.x, front.y])
	for gate in report["gates"]:
		var outside: Vector2 = (gate["pos"] as Vector2) - (gate["dir"] as Vector2) * 1.5
		if _distance_to_worn(report, outside, -1) > 0.5:
			_warn("gate at (%.1f, %.1f) opens onto unworn ground" % [outside.x, outside.y])


## Schedule routes are authored circulation, just like lanes. Catch the two
## failures that motivated the schedule layer: a named resident with no day,
## and a route segment that cuts through a building footprint.
func _check_daily_schedules(report: Dictionary, homes: Dictionary, schedules: Dictionary) -> void:
	var buildings: Array[Dictionary] = []
	for solid in report["solids"]:
		if _is_building(solid):
			buildings.append(solid)
	for resident_name in homes.keys():
		if not schedules.has(resident_name):
			_fail("%s has a home/work anchor but no daily schedule" % resident_name)
	for resident_name in schedules.keys():
		var entries: Array = schedules[resident_name]
		if entries.size() < 2:
			_fail("%s's daily schedule never goes anywhere" % resident_name)
			continue
		var previous: Vector2 = entries.back()["at"]
		for entry: Dictionary in entries:
			var route: Array = entry.get("route", [])
			var segment_from := previous
			for raw_point in route:
				var segment_to: Vector2 = raw_point
				_check_schedule_segment(str(resident_name), segment_from, segment_to, buildings)
				segment_from = segment_to
			var destination: Vector2 = entry["at"]
			if segment_from.distance_to(destination) > 0.05:
				_check_schedule_segment(str(resident_name), segment_from, destination, buildings)
			previous = destination


func _check_schedule_segment(
	resident_name: String, from: Vector2, to: Vector2, buildings: Array[Dictionary]
) -> void:
	var distance := from.distance_to(to)
	var steps := maxi(2, int(ceil(distance / 0.45)))
	# Leave the first and final body radius alone: an authored stop may sit at a
	# threshold, but the travelled middle of a segment may never cross a wall.
	for index in range(1, steps):
		var point := from.lerp(to, float(index) / float(steps))
		for building in buildings:
			if _point_in_solid(point, building, BODY_RADIUS):
				_fail("%s's schedule route crosses %s near (%.1f, %.1f)" % [resident_name, building["name"], point.x, point.y])
				return


## Distance from a point to the nearest worn ground (any stroke except `skip`,
## or any blob); 0 when it stands on worn ground.
func _distance_to_worn(report: Dictionary, point: Vector2, skip: int) -> float:
	var best := INF
	var strokes: Array = report["strokes"]
	for other in strokes.size():
		if other == skip:
			continue
		var distance := _distance_to_polyline(point, strokes[other]["points"]) - float(strokes[other]["width"]) * 0.5
		best = minf(best, maxf(distance, 0.0))
	for blob in report["blobs"]:
		var radii: Vector2 = blob["radii"]
		var offset: Vector2 = point - (blob["center"] as Vector2)
		var normalised := Vector2(offset.x / radii.x, offset.y / radii.y).length()
		if normalised <= 1.0:
			best = 0.0
		else:
			best = minf(best, (normalised - 1.0) * minf(radii.x, radii.y))
	return best


func _near_destination(report: Dictionary, point: Vector2) -> bool:
	for door in report["doors"]:
		if ((door["pos"] as Vector2) + (door["dir"] as Vector2) * 0.9).distance_to(point) < 2.5:
			return true
	for gate in report["gates"]:
		if (gate["pos"] as Vector2).distance_to(point) < 3.5:
			return true
	for item in report["facing"]:
		if (item["pos"] as Vector2).distance_to(point) < 3.5:
			return true
	return false
