class_name OhioInteriors
extends RefCounted

## Furnishes each Ohio house, workshop and mill from its people and its trade
## (see the interior-design skill and the persona sheets in it), through a
## RoomLayout so that no piece can stand in a doorway, on a ramp, in front of a
## fire or inside a wall. The inn and the meeting house have their own plans.
##
## Frame: the building's own (front wall at z = -half depth, outward -Z; the
## west gable carries the ramp on a two-storey house; the hearth stands on an
## east gable unless the spec says otherwise). Pieces keep their backs to a
## wall (local +Z) and face the room (local -Z).

const FACE := TownProps.WALL_THICKNESS * 0.5 + 0.06
const UPPER_Y := TownProps.FLOOR_HEIGHT + 0.04

const BLANKETS: Array[Color] = [
	Color(0.32, 0.46, 0.66), Color(0.62, 0.34, 0.30), Color(0.34, 0.5, 0.36), Color(0.56, 0.44, 0.26),
]


## The fire openings of a building: the ones its plan names, or by default a
## hearth on the ground floor and, in a two-storey house, a second hearth on the
## same stack for the upper floor (so the chimney is a working fireplace on both
## floors, not a bare column through the sleeping room). Shared with
## TownGenerator so the stack and the furniture agree.
static func openings_for(spec: Dictionary, floors: int) -> Array:
	var fire: Dictionary = spec.get("fire", {})
	if fire.has("openings"):
		return fire["openings"]
	var stack_z := float(spec.get("chimney_z", 0.0))
	var openings: Array = [{"z": stack_z, "width": 1.7, "height": 1.4}]
	if floors > 1 and bool(spec.get("residential", false)) and bool(spec.get("upper_fire", true)):
		openings.append({"z": stack_z, "width": 1.2, "height": 1.05, "floor": 1})
	return openings


static func furnish(building: StaticBody3D, spec: Dictionary, w: int, d: int, floors: int) -> void:
	var half_w := float(w) * TownProps.CELL_SIZE * 0.5
	var half_d := float(d) * TownProps.CELL_SIZE * 0.5
	var inner := Vector2(half_w - FACE, half_d - FACE)
	var ground := RoomLayout.new(building, inner, 0)
	var upper: RoomLayout = null
	if floors > 1:
		upper = RoomLayout.new(building, inner, 1)
	var side := float(spec.get("chimney_side", 1.0))
	var openings: Array = openings_for(spec, floors)
	var context := {
		"b": building, "g": ground, "u": upper, "inner": inner, "half_w": half_w, "half_d": half_d,
		"side": side, "openings": openings, "has_fire": bool(spec.get("chimney", false)),
		"spec": spec, "w": w, "d": d, "floors": floors,
	}
	_reserve_structure(context)
	match str(spec.get("work", "")):
		"smithy":
			_smithy(context)
		"bakery":
			_bakehouse(context)
		"grain":
			_millhouse(context)
		"home_joinery":
			_joiner_home(context)
		"joinery":
			_sawmill(context)
		"mason":
			_mason(context)
		"naturalist":
			_naturalist(context)
		"dealer":
			_dealer(context)
		"herbal":
			_herbalist(context)
	var failures: Array[String] = []
	failures.append_array(ground.failures)
	if upper != null:
		failures.append_array(upper.failures)
	building.set_meta("layout_failures", failures)


# ---------------------------------------------------------------------------
# Structure the furniture must respect
# ---------------------------------------------------------------------------

static func _reserve_structure(c: Dictionary) -> void:
	var half_w: float = c["half_w"]
	var side: float = c["side"]
	var ground: RoomLayout = c["g"]
	var upper: RoomLayout = c["u"]
	if bool(c["has_fire"]):
		var z_lo := INF
		var z_hi := -INF
		var forge_lo := INF
		var forge_hi := -INF
		for opening: Dictionary in c["openings"]:
			var reach := float(opening["width"]) * 0.5 + 0.5
			z_lo = minf(z_lo, float(opening["z"]) - reach)
			z_hi = maxf(z_hi, float(opening["z"]) + reach)
			if str(opening.get("kind", "hearth")) == "forge":
				forge_lo = minf(forge_lo, float(opening["z"]) - reach)
				forge_hi = maxf(forge_hi, float(opening["z"]) + reach)
		var depth := 0.93
		var centre := Vector2(side * (half_w - depth * 0.5 + 0.06), (z_lo + z_hi) * 0.5)
		var half := Vector2(depth * 0.5 + 0.06, (z_hi - z_lo) * 0.5 + 0.05)
		ground.reserve(centre, half)
		if upper != null:
			upper.reserve(centre, half)
		if forge_lo < INF:
			# The forge's hearth table stands out in front of the breast.
			var table_depth := Hearth.FORGE_TABLE_DEPTH
			var table_centre := Vector2(side * (half_w - depth - table_depth * 0.5 + 0.06), (forge_lo + forge_hi) * 0.5)
			ground.reserve(table_centre, Vector2(table_depth * 0.5 + 0.02, (forge_hi - forge_lo) * 0.5 + 0.05))
	if int(c["floors"]) > 1:
		var ramp := TownProps.ramp_geometry(int(c["w"]), int(c["d"]))
		var ramp_x := float(ramp["x"])
		var low := float(ramp["z_low"])
		var high := float(ramp["z_high"])
		ground.reserve(Vector2(ramp_x, (low + high) * 0.5), Vector2(TownProps.RAMP_WIDTH * 0.5 + 0.2, (high - low) * 0.5 + 0.05))
		var open_low := float(ramp["opening_start"]) - 0.3
		upper.reserve(Vector2(ramp_x + 0.05, (open_low + high) * 0.5), Vector2(TownProps.STAIR_HOLE_HALF_WIDTH + 0.35, (high - open_low) * 0.5 + 0.35))


# ---------------------------------------------------------------------------
# Placement helpers
# ---------------------------------------------------------------------------

## Candidate positions along a wall, ordered from the "low" end, the "high" end
## or the "center" outward.
static func _along(c: Dictionary, wall: String, margin: float, mode: String = "low") -> Array[float]:
	var inner: Vector2 = c["inner"]
	var limit := (inner.x if wall in ["north", "south"] else inner.y) - margin
	var values := RoomLayout.span(-limit, limit, 0.25)
	if mode == "high":
		values.reverse()
	elif mode == "center":
		values.sort_custom(func(a: float, b: float) -> bool: return absf(a) < absf(b))
	return values


static func _wall(
	c: Dictionary, floor_key: String, walls: Array[String], hx: float, hz: float, front: float,
	label: String, mode: String = "low", height: float = 0.9
) -> Dictionary:
	var layout: RoomLayout = c[floor_key]
	var wall_list: Array[String] = walls
	for wall in wall_list:
		var pose := layout.on_walls([wall], hx, hz, front, _along(c, wall, hx, mode), label, height)
		if not pose.is_empty():
			pose["wall"] = wall
			return pose
	return {}


static func _at3(c: Dictionary, floor_key: String, pose: Dictionary, lift: float = 0.0) -> Vector3:
	var y := 0.0 if floor_key == "g" else UPPER_Y
	var pos: Vector2 = pose["pos"]
	return Vector3(pos.x, y + lift, pos.y)


static func _light(building: StaticBody3D, at: Vector3, energy: float = 0.55, reach: float = 6.0) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(1.0, 0.72, 0.4)
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	building.add_child(light)


## The fire's end of the room: a rug under the clear zone's edge, a pair of
## armchairs facing the fire, tools and logs beside the breast. `armchairs`
## and `chair_colors` let a household tailor it (one worn chair, or two).
static func _fireside(
	c: Dictionary, armchairs: int = 2, rug_color: Color = Furnishings.CLOTH_RED.darkened(0.2), floor_key: String = "g"
) -> void:
	if not bool(c["has_fire"]):
		return
	var opening := _opening_on(c, 1 if floor_key == "u" else 0)
	if opening.is_empty():
		return
	var y := 0.0 if floor_key == "g" else UPPER_Y
	var body: StaticBody3D = c["b"]
	var layout: RoomLayout = c[floor_key]
	var side: float = c["side"]
	var half_w: float = c["half_w"]
	var hearth_z := float(opening["z"])
	var width := float(opening["width"])
	var face_abs := half_w - 0.88
	var seat_x := side * (face_abs - 1.35 - 0.5)
	var facing := -PI * 0.5 if side > 0.0 else PI * 0.5
	Furnishings.rug(body, Vector3(side * (face_abs - 1.35 - 0.55), y, hearth_z), 0.0, Vector2(2.1, 2.0), rug_color)
	var offsets: Array[float] = [-0.75, 0.75]
	for i in mini(armchairs, 2):
		var pose := {"pos": Vector2(seat_x, hearth_z + offsets[i]), "yaw": facing}
		if layout.at_any([pose], 0.34, 0.3, 0.3, "fireside armchair", 0.9).is_empty():
			continue
		Furnishings.armchair(body, Vector3(seat_x, y, hearth_z + offsets[i]), facing, [Furnishings.CLOTH_BLUE, Furnishings.CLOTH_GREEN][i % 2])
	var reach := width * 0.5 + 0.5
	var tool_x := side * (half_w - 0.5)
	# Tools go either side of the breast, whichever has room.
	var basket := _first_fit(layout, [
		{"pos": Vector2(tool_x, hearth_z + reach + 0.5), "yaw": 0.0}, {"pos": Vector2(tool_x, hearth_z - reach - 0.5), "yaw": 0.0},
	] as Array[Dictionary], 0.32, 0.32, 0.9)
	if not basket.is_empty():
		layout.at_any([basket], 0.32, 0.32, 0.0, "log basket", 0.9)
		Furnishings.log_basket(body, Vector3(basket["pos"].x, y, basket["pos"].y))
	var irons := _first_fit(layout, [
		{"pos": Vector2(tool_x, hearth_z - reach - 0.5), "yaw": 0.0}, {"pos": Vector2(tool_x, hearth_z + reach + 0.5), "yaw": 0.0},
	] as Array[Dictionary], 0.15, 0.15, 0.9)
	if not irons.is_empty():
		layout.at_any([irons], 0.15, 0.15, 0.0, "fire irons", 0.9)
		Furnishings.fire_irons(body, Vector3(irons["pos"].x, y, irons["pos"].y))
	_light(body, Vector3(seat_x, y + 2.3, hearth_z), 0.5, 6.0)


## The fire opening on a floor (0 or 1), or empty if that floor has none.
static func _opening_on(c: Dictionary, floor_number: int) -> Dictionary:
	for opening: Dictionary in c["openings"]:
		if int(opening.get("floor", 0)) == floor_number:
			return opening
	return {}


## The first pose that would fit, without recording anything or logging a
## failure: for dressing that is welcome but not required.
static func _first_fit(layout: RoomLayout, poses: Array[Dictionary], hx: float, hz: float, height: float) -> Dictionary:
	for pose in poses:
		if layout.would_fit(pose["pos"], pose["yaw"], hx, hz, height):
			return pose
	return {}


## A table with seats, trying each candidate centre in turn.
static func _table(
	c: Dictionary, centres: Array[Vector2], length: float, depth: float, seats: String, label: String = "table",
	floor_key: String = "g"
) -> bool:
	var body: StaticBody3D = c["b"]
	var layout: RoomLayout = c[floor_key]
	var table_y := 0.0 if floor_key == "g" else UPPER_Y
	var inner: Vector2 = c["inner"]
	var candidates: Array[Vector2] = centres.duplicate()
	# If none of the preferred spots fits, scan the room for the nearest that does.
	var anchor: Vector2 = centres[0] if not centres.is_empty() else Vector2.ZERO
	var grid: Array[Vector2] = []
	var gx := -inner.x + 1.0
	while gx <= inner.x - 1.0:
		var gz := -inner.y + 1.0
		while gz <= inner.y - 1.0:
			grid.append(Vector2(gx, gz))
			gz += 0.5
		gx += 0.5
	grid.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_to(anchor) < b.distance_to(anchor))
	candidates.append_array(grid)
	for centre in candidates:
		for yaw: float in [0.0, PI * 0.5]:
			var hx := length * 0.5 + (0.8 if seats == "stools" else 0.12)
			var hz := depth * 0.5 + (0.12 if seats == "stools" else 0.62)
			var pose := {"pos": centre, "yaw": yaw}
			if not layout.would_fit(centre, yaw, hx, hz, 0.9):
				continue
			layout.at_any([pose], hx, hz, 0.0, label, 0.9)
			Furnishings.table(body, Vector3(centre.x, table_y, centre.y), yaw, length, depth, seats)
			return true
	layout.failures.append("%s found no room" % label)
	return false


static func _shelf(
	c: Dictionary, floor_key: String, walls: Array[String], length: float, tiers: int, stock: String, label: String = "shelf"
) -> void:
	var pose := _wall(c, floor_key, walls, length * 0.5, 0.2, 0.7, label, "low", 2.0)
	if not pose.is_empty():
		Furnishings.shelf(c["b"], _at3(c, floor_key, pose), float(pose["yaw"]), length, tiers, stock)


## A peg rail on the first wall with room for it clear of windows and doors.
## Its coats hang from rail height to about a metre off the floor.
static func _pegs(c: Dictionary, walls: Array[String], length: float, rail_y: float) -> void:
	var pose := _wall(c, "g", walls, length * 0.5, 0.06, 0.3, "peg rail", "center", rail_y + 0.1)
	if not pose.is_empty():
		Furnishings.peg_rail(c["b"], _at3(c, "g", pose), float(pose["yaw"]), length, rail_y)


static func _chest(
	c: Dictionary, floor_key: String, walls: Array[String], length: float = 0.9, label: String = "chest"
) -> void:
	var pose := _wall(c, floor_key, walls, length * 0.5, 0.3, 0.8, label, "high", 0.5)
	if not pose.is_empty():
		Furnishings.chest(c["b"], _at3(c, floor_key, pose), float(pose["yaw"]), Furnishings.OAK_DARK, length)


## A bed head to the wall with a chest at its foot where it fits. Returns the
## pose chosen so a caller can dress around it.
static func _bed(c: Dictionary, floor_key: String, walls: Array[String], blanket: Color, with_chest: bool = true) -> Dictionary:
	# The bed reserves no foot space of its own; its chest reserves the space
	# in front of both, so the pair is one unit with one clear approach.
	var pose := _wall(c, floor_key, walls, 0.78, 1.23, 0.0, "bed", "low", 0.9)
	if pose.is_empty():
		return pose
	var bed := TownProps.build_bed(blanket)
	bed.position = _at3(c, floor_key, pose)
	bed.rotation.y = float(pose["yaw"]) + PI
	(c["b"] as StaticBody3D).add_child(bed)
	if with_chest:
		var layout: RoomLayout = c[floor_key]
		# The bed is built at yaw + PI (head to the wall), so its foot is the
		# way local +Z points after that turn: toward the room.
		var bed_yaw := float(pose["yaw"]) + PI
		var foot: Vector2 = (pose["pos"] as Vector2) + Vector2(sin(bed_yaw), cos(bed_yaw)) * 1.62
		var chest_pose := {"pos": foot, "yaw": float(pose["yaw"])}
		var placed := {}
		if layout.would_fit(foot, float(pose["yaw"]), 0.45, 0.28, 0.5):
			placed = layout.try_quietly(chest_pose, 0.45, 0.28, 0.7, 0.5)
		if not placed.is_empty():
			Furnishings.chest(c["b"], Vector3(foot.x, 0.0 if floor_key == "g" else UPPER_Y, foot.y), float(pose["yaw"]), Furnishings.OAK_DARK, 0.9)
		else:
			# No room at the foot of the bed: the chest goes on any free wall.
			_chest(c, floor_key, ["east", "south", "north", "west"] as Array[String])
	return pose


## The sleeping floor of a two-storey house: beds head to the long wall, a
## washstand, pegs, a rug and a light, around the stair hole.
static func _sleeping_floor(c: Dictionary, beds: int, extra_walls: Array[String] = []) -> void:
	if c["u"] == null:
		return
	var walls: Array[String] = ["north", "south", "east"]
	walls.append_array(extra_walls)
	for i in beds:
		_bed(c, "u", walls, BLANKETS[i % BLANKETS.size()])
	var pose := _wall(c, "u", ["south", "north", "east"] as Array[String], 0.4, 0.28, 0.6, "washstand", "center", 0.9)
	if not pose.is_empty():
		Furnishings.washstand(c["b"], _at3(c, "u", pose), float(pose["yaw"]))
	# The upper hearth gets its own fireside; the bedroom rug moves off it.
	var rug_x := 1.0
	if not _opening_on(c, 1).is_empty():
		_fireside(c, 1, Furnishings.CLOTH_RED.darkened(0.3), "u")
		rug_x = -1.0
	Furnishings.rug(c["b"], Vector3(rug_x, UPPER_Y, 0.0), 0.0, Vector2(2.4, 1.6), Color(0.52, 0.3, 0.24))
	_light(c["b"], Vector3(0.5, UPPER_Y + 2.1, 0.0), 0.5, 5.5)


# ---------------------------------------------------------------------------
# The households and trades
# ---------------------------------------------------------------------------

## Brinna Kest's forge and the room over it. The ground floor is the working
## level: a raised brick forge with a hood in the gable wall (see Hearth), the
## anvil a pace from its edge, the quench trough and coal bin within reach, the
## bench, grindstone and her stock on the far walls. She lives upstairs: bed,
## table, shelf and a small hearth on the same stack.
static func _smithy(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var layout: RoomLayout = c["g"]
	var side: float = c["side"]
	var half_w: float = c["half_w"]
	var face_abs := half_w - 0.88
	var forge := _opening_on(c, 0)
	var forge_z := float(forge.get("z", 0.0))
	# The forge triangle: the anvil stands a pace from the edge of the hearth
	# table, on the line out from the fire, with the trough and coal to either hand.
	var anvil_at := Vector2(side * (face_abs - Hearth.FORGE_TABLE_DEPTH - 1.05), forge_z)
	if not layout.at_any([{"pos": anvil_at, "yaw": 0.0}], 0.32, 0.32, 0.0, "anvil", 0.9).is_empty():
		TradeFurnishings.anvil(body, Vector3(anvil_at.x, 0.0, anvil_at.y), 0.0)
	# Scorched flagstones under the whole working floor of the forge.
	Furnishings.piece(
		body, Vector3(1.5, 0.006, 1.55), Color(0.2, 0.19, 0.18),
		Vector3(side * (face_abs - 1.4), 0.008, forge_z), 0.0, false, SuperEgg.EPSILON_SOFT
	)
	var trough := _wall(c, "g", ["east"] as Array[String], 0.55, 0.26, 0.4, "quench trough", "high", 0.6)
	if not trough.is_empty():
		TradeFurnishings.quench_trough(body, _at3(c, "g", trough), float(trough["yaw"]), 1.1)
	var coal := _wall(c, "g", ["east"] as Array[String], 0.5, 0.36, 0.4, "coal bin", "low", 0.6)
	if not coal.is_empty():
		TradeFurnishings.coal_bin(body, _at3(c, "g", coal), float(coal["yaw"]))
	var bench := _wall(c, "g", ["north"] as Array[String], 0.95, 0.34, 0.8, "workbench", "high", 0.95)
	if not bench.is_empty():
		TradeFurnishings.workbench(body, _at3(c, "g", bench), float(bench["yaw"]), 1.9)
		TradeFurnishings.tool_rack(body, _at3(c, "g", bench, 0.0), float(bench["yaw"]), 1.5)
	var grind := _wall(c, "g", ["north"] as Array[String], 0.3, 0.26, 0.7, "grindstone", "center", 0.9)
	if not grind.is_empty():
		TradeFurnishings.grindstone(body, _at3(c, "g", grind), float(grind["yaw"]))
	var rack := _wall(c, "g", ["north", "west"] as Array[String], 0.78, 0.14, 0.8, "weapon rack", "low", 2.0)
	if not rack.is_empty():
		TradeFurnishings.weapon_rack(body, _at3(c, "g", rack), float(rack["yaw"]), 1.5)
	var stand := _wall(c, "g", ["north", "west"] as Array[String], 0.24, 0.24, 0.5, "armor stand", "low", 1.6)
	if not stand.is_empty():
		TradeFurnishings.armor_stand(body, _at3(c, "g", stand), float(stand["yaw"]))
	_shelf(c, "g", ["west", "north"] as Array[String], 1.6, 3, "boxes", "rivets and pitch cans")
	_light(body, Vector3(side * (face_abs - 1.8), 2.6, forge_z), 0.7, 7.0)
	_light(body, Vector3(-1.0, 2.6, 1.0), 0.45, 6.0)
	# The residence: bed and chest, the kitchen table, a shelf, her old cloak on
	# a peg rail, and the fire on the same stack as the forge below.
	_sleeping_floor(c, 1)
	_table(c, [Vector2(-1.2, 1.8), Vector2(-1.2, -1.8)] as Array[Vector2], 1.2, 0.8, "stools", "Brinna's table", "u")
	_shelf(c, "u", ["west", "north"] as Array[String], 1.6, 3, "crocks", "kitchen shelf")
	var pegs := _wall(c, "u", ["south", "north"] as Array[String], 0.7, 0.1, 0.6, "peg rail", "high", 1.8)
	if not pegs.is_empty():
		Furnishings.peg_rail(body, _at3(c, "u", pegs), float(pegs["yaw"]), 1.4, 1.7)


## Nell Barrow's bakehouse: the oven is the hearth, the table is floured, loaves
## cool on racks and flour waits in bins and sacks.
static func _bakehouse(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var layout: RoomLayout = c["g"]
	var side: float = c["side"]
	var half_w: float = c["half_w"]
	var face_abs := half_w - 0.88
	var opening: Dictionary = (c["openings"] as Array)[0]
	var peel := {"pos": Vector2(side * (half_w - 0.4), float(opening["z"]) - float(opening["width"]) * 0.5 - 0.75), "yaw": 0.0}
	if not layout.at_any([peel], 0.15, 0.15, 0.0, "peel", 0.9).is_empty():
		TradeFurnishings.peel_and_rake(body, Vector3(peel["pos"].x, 0.0, peel["pos"].y), 0.0)
	var kneading := Vector2(side * (face_abs - 1.35 - 1.2), 0.0)
	var table_pose := {"pos": kneading, "yaw": PI * 0.5}
	if not layout.at_any([table_pose], 1.2, 0.7, 0.0, "kneading table", 0.9).is_empty():
		TradeFurnishings.kneading_table(body, Vector3(kneading.x, 0.0, kneading.y), PI * 0.5, 2.2)
		TradeFurnishings.scale(body, Vector3(kneading.x, 0.0, kneading.y + 0.7), 0.0, 0.89)
	for i in 2:
		var bin := _wall(c, "g", ["north"] as Array[String], 0.55, 0.42, 0.7, "flour bin", "high", 0.9)
		if not bin.is_empty():
			TradeFurnishings.grain_bin(body, _at3(c, "g", bin), float(bin["yaw"]))
	var racks := _wall(c, "g", ["west", "north"] as Array[String], 0.65, 0.24, 0.8, "loaf rack", "low", 2.0)
	if not racks.is_empty():
		TradeFurnishings.loaf_rack(body, _at3(c, "g", racks), float(racks["yaw"]), 1.2)
	_shelf(c, "g", ["north", "west"] as Array[String], 1.8, 3, "crocks", "bakery shelf")
	var sack_pose := _wall(c, "g", ["west", "north", "south"] as Array[String], 0.6, 0.3, 0.3, "flour sacks", "high", 0.5)
	if not sack_pose.is_empty():
		Furnishings.sacks_along(body, _at3(c, "g", sack_pose), float(sack_pose["yaw"]), 5)
	_bed(c, "g", ["south", "west"] as Array[String], BLANKETS[2])
	_light(body, Vector3(kneading.x, 2.4, 0.0), 0.7, 6.5)


## Cob Ferris's millhouse: sacks and bins, the scale, a long family table, and
## his grandmother's chair worn to the shape of her by the fire.
static func _millhouse(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var layout: RoomLayout = c["g"]
	var half_w: float = c["half_w"]
	_fireside(c, 1, Furnishings.CLOTH_BLUE.darkened(0.3))
	_table(c, [Vector2(half_w - 5.5, 1.2), Vector2(half_w - 5.5, -1.0), Vector2(half_w - 6.5, 1.0)] as Array[Vector2], 1.9, 0.9, "benches", "family table")
	for i in 3:
		var bin := _wall(c, "g", ["north"] as Array[String], 0.55, 0.42, 0.7, "grain bin", "low", 0.9)
		if not bin.is_empty():
			TradeFurnishings.grain_bin(body, _at3(c, "g", bin), float(bin["yaw"]), Color(0.84, 0.74, 0.5))
	var pile := _wall(c, "g", ["west"] as Array[String], 0.65, 0.3, 0.3, "stacked sacks", "center", 0.9)
	if not pile.is_empty():
		Furnishings.sacks_along(body, _at3(c, "g", pile), float(pile["yaw"]), 7)
	var weigh := _wall(c, "g", ["south"] as Array[String], 0.4, 0.3, 0.3, "scale table", "low", 0.9)
	if not weigh.is_empty():
		Furnishings.table(body, _at3(c, "g", weigh), float(weigh["yaw"]) + PI, 0.8, 0.5, "none")
		TradeFurnishings.scale(body, _at3(c, "g", weigh), 0.0, 0.8)
	_shelf(c, "g", ["south", "north"] as Array[String], 1.6, 3, "boxes", "ledger shelf")
	_bed(c, "g", ["north", "south"] as Array[String], BLANKETS[3])
	_light(body, Vector3(-3.0, 2.5, 0.0), 0.6, 7.0)


## Dorran Fask and Halda Prewitt's house: his joinery bench and drawings, her
## ledgers and seals, one crooked beam they do not discuss.
static func _joiner_home(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var half_w: float = c["half_w"]
	_fireside(c, 2)
	_table(c, [Vector2(half_w - 5.2, 1.4), Vector2(half_w - 5.2, -1.4), Vector2(half_w - 6.2, 0.0)] as Array[Vector2], 1.7, 0.9, "benches", "kitchen table")
	var bench := _wall(c, "g", ["north"] as Array[String], 1.0, 0.34, 0.8, "joinery bench", "low", 0.95)
	if not bench.is_empty():
		TradeFurnishings.workbench(body, _at3(c, "g", bench), float(bench["yaw"]), 2.0)
		TradeFurnishings.tool_rack(body, _at3(c, "g", bench), float(bench["yaw"]), 1.6)
		Furnishings.piece(body, Vector3(0.22, 0.12, 0.17), Furnishings.OAK_LIGHT, _at3(c, "g", bench, 1.02) + Vector3(0.5, 0.0, 0.0), 0.3, false)
	var offcuts := _wall(c, "g", ["north", "south"] as Array[String], 0.6, 0.3, 0.3, "timber offcuts", "high", 0.9)
	if not offcuts.is_empty():
		TradeFurnishings.timber_rack(body, _at3(c, "g", offcuts), float(offcuts["yaw"]), 1.1)
	_shelf(c, "g", ["south", "north"] as Array[String], 1.5, 3, "boxes", "Halda's ledgers")
	var box := _wall(c, "g", ["south", "north"] as Array[String], 0.3, 0.22, 0.4, "seal box", "center", 0.5)
	if not box.is_empty():
		Furnishings.strongbox(body, _at3(c, "g", box), float(box["yaw"]))
	Furnishings.peg_rail(body, Vector3(-0.8, 0.0, -c["inner"].y + 0.05), PI, 1.4, 1.7)
	_sleeping_floor(c, 2)


## The mill's saw floor: boards on racks, benches with vises, a grindstone.
static func _sawmill(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var racks := 0
	for i in 2:
		var rack := _wall(c, "g", ["north"] as Array[String], 1.5, 0.3, 0.6, "timber rack", "low", 1.0)
		if not rack.is_empty():
			TradeFurnishings.timber_rack(body, _at3(c, "g", rack), float(rack["yaw"]), 3.0)
			racks += 1
	for i in 2:
		var bench := _wall(c, "g", ["south", "east"] as Array[String], 1.0, 0.34, 0.8, "saw bench", "high", 0.95)
		if not bench.is_empty():
			TradeFurnishings.workbench(body, _at3(c, "g", bench), float(bench["yaw"]), 2.0)
			TradeFurnishings.tool_rack(body, _at3(c, "g", bench), float(bench["yaw"]), 1.6)
	_fireside(c, 1, Furnishings.CLOTH_RED.darkened(0.35))
	_shelf(c, "g", ["east", "north"] as Array[String], 1.8, 3, "boxes", "pitch and nails")
	_light(body, Vector3(0.0, 2.8, 0.0), 0.8, 9.0)
	_sleeping_floor(c, 1)


## Tam Ruskin's house: stone samples, drawings of the fountain carvings, an
## hourglass that no longer runs, a bed in the rear corner.
static func _mason(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var half_w: float = c["half_w"]
	_fireside(c, 1, Furnishings.CLOTH_GREEN.darkened(0.3))
	var drawing := _wall(c, "g", ["north"] as Array[String], 0.75, 0.42, 0.9, "drawing table", "low", 1.2)
	if not drawing.is_empty():
		TradeFurnishings.drawing_table(body, _at3(c, "g", drawing), float(drawing["yaw"]))
	var stone := _wall(c, "g", ["south", "west"] as Array[String], 0.7, 0.26, 0.4, "stone samples", "center", 0.5)
	if not stone.is_empty():
		TradeFurnishings.stone_samples(body, _at3(c, "g", stone), float(stone["yaw"]))
	_table(c, [Vector2(half_w - 5.0, -1.2), Vector2(half_w - 5.0, 1.2)] as Array[Vector2], 1.3, 0.8, "stools", "Tam's table")
	_shelf(c, "g", ["west", "south"] as Array[String], 1.5, 3, "boxes", "carving studies")
	_bed(c, "g", ["north", "west", "south"] as Array[String], BLANKETS[1])
	var hourglass := Vector3(c["inner"].x * 0.4, 0.0, 0.0)
	_light(body, Vector3(hourglass.x - 2.0, 2.3, 0.0), 0.55, 6.0)


## Oswin Cray's worn chair and tools downstairs; Ivy Thorne's study and her
## jars upstairs, and a cushion where a wild blorb sometimes sleeps.
static func _naturalist(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var half_w: float = c["half_w"]
	_fireside(c, 2, Furnishings.CLOTH_BLUE.darkened(0.25))
	_table(c, [Vector2(half_w - 5.0, 1.0), Vector2(half_w - 5.0, -1.0)] as Array[Vector2], 1.4, 0.9, "stools", "kitchen table")
	var rack := _wall(c, "g", ["west", "south"] as Array[String], 0.7, 0.04, 0.4, "tool rack", "low", 1.7)
	if not rack.is_empty():
		TradeFurnishings.tool_rack(body, _at3(c, "g", rack), float(rack["yaw"]), 1.4)
	_shelf(c, "g", ["south", "north"] as Array[String], 1.6, 3, "crocks", "jar shelf")
	_pegs(c, ["south", "west", "north"] as Array[String], 1.2, 1.7)
	# Upstairs: Ivy's desk by a window, specimen shelf, two beds, the cushion.
	var desk := _wall(c, "u", ["north"] as Array[String], 0.9, 0.5, 1.1, "Ivy's desk", "center", 0.9)
	if not desk.is_empty():
		Furnishings.desk(body, _at3(c, "u", desk), float(desk["yaw"]))
	var specimens := _wall(c, "u", ["east", "south"] as Array[String], 0.8, 0.2, 0.7, "specimen shelf", "low", 2.0)
	if not specimens.is_empty():
		TradeFurnishings.specimen_shelf(body, _at3(c, "u", specimens), float(specimens["yaw"]), 1.6)
	_sleeping_floor(c, 2, ["west"] as Array[String])
	var cushion := Vector2(c["inner"].x * 0.3, c["inner"].y * 0.2)
	if (c["u"] as RoomLayout).would_fit(cushion, 0.0, 0.3, 0.3):
		Furnishings.piece(body, Vector3(0.3, 0.07, 0.3), Furnishings.CLOTH_GREEN.lightened(0.1), Vector3(cushion.x, UPPER_Y + 0.08, cushion.y), 0.0, false, SuperEgg.EPSILON_SOFT)


## Aldren Vey's house, a little too tidy: glazed cabinets of curios, a good chair,
## a locked strongbox, labelled boxes.
static func _dealer(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var half_w: float = c["half_w"]
	_fireside(c, 1, Furnishings.CLOTH_RED.darkened(0.4))
	for i in 2:
		var cabinet := _wall(c, "g", ["north", "west", "south"] as Array[String], 0.6, 0.26, 0.8, "curio cabinet", "low", 2.0)
		if not cabinet.is_empty():
			TradeFurnishings.cabinet(body, _at3(c, "g", cabinet), float(cabinet["yaw"]), 1.2)
	var desk := _wall(c, "g", ["south", "north"] as Array[String], 0.9, 0.5, 1.1, "ledger desk", "high", 0.9)
	if not desk.is_empty():
		Furnishings.desk(body, _at3(c, "g", desk), float(desk["yaw"]))
	var box := _wall(c, "g", ["south", "north", "west"] as Array[String], 0.3, 0.22, 0.4, "strongbox", "center", 0.5)
	if not box.is_empty():
		Furnishings.strongbox(body, _at3(c, "g", box), float(box["yaw"]))
	_shelf(c, "g", ["west", "south"] as Array[String], 1.4, 4, "boxes", "labelled boxes")
	_table(c, [Vector2(half_w - 5.0, 0.0)] as Array[Vector2], 1.1, 0.8, "stools", "tea table")
	_sleeping_floor(c, 1)


## Wren Sallow's cottage: herbs drying overhead, boots by the door, a gathering
## basket, a map of the hedge line, one low lamp.
static func _herbalist(c: Dictionary) -> void:
	var body: StaticBody3D = c["b"]
	var half_w: float = c["half_w"]
	_fireside(c, 1, Furnishings.CLOTH_GREEN.darkened(0.3))
	TradeFurnishings.herb_rail(body, Vector3(-1.5, 0.0, 0.8), 0.0, 2.0)
	TradeFurnishings.herb_rail(body, Vector3(0.8, 0.0, -0.8), 0.0, 1.8)
	_table(c, [Vector2(half_w - 5.0, 1.2), Vector2(half_w - 5.0, -1.2)] as Array[Vector2], 1.5, 0.8, "stools", "herb table")
	_shelf(c, "g", ["west", "south", "north"] as Array[String], 2.0, 4, "crocks", "herb shelf")
	_pegs(c, ["south", "west", "north"] as Array[String], 1.6, 1.8)
	var basket := _wall(c, "g", ["south", "north"] as Array[String], 0.25, 0.25, 0.3, "gathering basket", "center", 0.5)
	if not basket.is_empty():
		Furnishings.piece(body, Vector3(0.25, 0.16, 0.25), Color(0.62, 0.46, 0.24), _at3(c, "g", basket, 0.16), 0.0, true, 2.4)
	_bed(c, "g", ["north", "west"] as Array[String], BLANKETS[2])
	_light(body, Vector3(1.0, 1.9, 0.0), 0.35, 4.5)
