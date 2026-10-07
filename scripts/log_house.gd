class_name LogHouse
extends RefCounted

## Laft log houses for the Snow Village: whole courses of squarish logs that run
## corner to corner with projecting notched ends, a stone plinth, a steep
## snow-bearing roof (optionally bellcast) with carved bargeboards and crossed
## horse-head finials, and true gaps in the courses at every door and window.
##
## Building frame (same as TownProps): front wall (door) at local -Z, gable ends
## at +/-X, the ridge runs along X. `cells` is (ridge length, depth) in 3.2 m
## cells. A spec Dictionary describes one mass; the generator then adds hearths,
## partitions, lean-tos, galleries and furniture around the returned body.
##
## Spec keys: cells (Vector2), floors (int), pitch_deg (float, default 46),
## bellcast (bool), log_color, roof_color, openings (Array of {wall: front|back|
## west|east, x (metres along the wall; world X on front/back, world Z on the
## ends), width, bottom, top, kind: door|window|wide, leaves, shutters}).

const CELL := 3.2
const STOREY := 3.25
const COURSE := 0.325
const R := 0.17
# Alternating courses still interlock, but the long course stops flush with the
# outer face of the crossing log. The former 30 cm projection read as a row of
# fingers rather than a fitted laft joint.
const NOTCH := 0.0
const LOG_EPS := 6.0
const WALL_T := 0.30
const PLINTH_H := 0.42
const EAVE := 0.8
const GABLE_OH := 0.6
const ROOF_T := 0.14
const SNOW_T := 0.17
const ROOF_COLOR := Color(0.25, 0.19, 0.16)
const SNOW := Color(0.95, 0.97, 1.0)
const CASING := Color(0.93, 0.92, 0.87)
const STONE := Color(0.50, 0.50, 0.52)
const LOG_COLORS: Array[Color] = [
	Color(0.38, 0.25, 0.15), Color(0.44, 0.29, 0.17), Color(0.33, 0.22, 0.14),
	Color(0.46, 0.32, 0.20), Color(0.30, 0.22, 0.17),
]
const DOOR_W := 1.2
const DOOR_TOP := 2.46
const WINDOW_W := 0.9
const WINDOW_H := 1.1
const WINDOW_SILL := 1.0


## Returns the shell body. `spec` is updated in place with the resolved
## openings (gap bounds included) under "resolved_openings".
static func build(spec: Dictionary) -> StaticBody3D:
	var cells: Vector2 = spec["cells"]
	var floors := int(spec.get("floors", 1))
	var w := int(cells.x)
	var d := int(cells.y)
	var width := float(w) * CELL
	var depth := float(d) * CELL
	var pitch := deg_to_rad(float(spec.get("pitch_deg", 46.0)))
	var log_color: Color = spec.get("log_color", LOG_COLORS[0])
	var body := StaticBody3D.new()
	body.name = str(spec.get("name", "LogHouse"))
	body.collision_layer = 1
	body.collision_mask = 0

	TownProps._build_floor(body, w, d, 0.0, spec.get("floor_color", TownProps.FLOOR_COLOR))
	for level in range(1, floors):
		TownProps._build_floor_with_ramp_opening(
			body, w, d, float(level) * STOREY, spec.get("floor_color", TownProps.FLOOR_COLOR), spec.get("floor_voids", [])
		)
	if floors > 1:
		TownProps._build_interior_ramps(body, w, d, floors)

	var openings := _resolve_openings(spec, width, depth, floors)
	spec["resolved_openings"] = openings
	var skip: Array = spec.get("skip_walls", [])
	_build_walls(body, width, depth, floors, openings, log_color, pitch, skip)
	_build_plinth(body, width, depth, openings, skip)
	for opening: Dictionary in openings:
		_build_opening(body, opening, width, depth)
	_build_roof(
		body, width, depth, floors, pitch, bool(spec.get("bellcast", false)), spec.get("roof_color", ROOF_COLOR),
		float(spec.get("gallery", 0.0))
	)
	return body


# ---------------------------------------------------------------------------
# Openings
# ---------------------------------------------------------------------------

## Applies the course grid to each requested opening: a course is removed when
## its centre lies inside the requested band, so the gap is a whole number of
## courses (`gap_bottom`, `gap_top`).
static func _resolve_openings(spec: Dictionary, width: float, depth: float, floors: int) -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	var requested: Array = spec.get("openings", [])
	for source: Dictionary in requested:
		var opening := source.duplicate()
		var bottom := float(opening["bottom"])
		var top := float(opening["top"])
		var first := -1
		var last := -1
		var course_count := floors * 10 + 40
		for c in course_count:
			var y := (float(c) + 0.5) * COURSE
			if y > bottom and y < top:
				if first < 0:
					first = c
				last = c
		if first < 0:
			continue
		opening["first_course"] = first
		opening["last_course"] = last
		opening["gap_bottom"] = 0.0 if first == 0 else float(first) * COURSE
		opening["gap_top"] = float(last + 1) * COURSE
		resolved.append(opening)
	return resolved


## Wall frame for an opening: pivot origin, yaw (outward is the pivot's -Z), and
## the sign mapping the opening's `x` to the pivot's local X.
static func _wall_frame(wall: String, width: float, depth: float) -> Dictionary:
	match wall:
		"front":
			return {"origin": Vector3(0, 0, -(depth * 0.5 - R)), "yaw": 0.0, "sign": 1.0}
		"back":
			return {"origin": Vector3(0, 0, depth * 0.5 - R), "yaw": PI, "sign": -1.0}
		"west":
			return {"origin": Vector3(-(width * 0.5 - R), 0, 0), "yaw": PI * 0.5, "sign": -1.0}
	return {"origin": Vector3(width * 0.5 - R, 0, 0), "yaw": -PI * 0.5, "sign": 1.0}


static func _build_opening(body: StaticBody3D, opening: Dictionary, width: float, depth: float) -> void:
	var frame := _wall_frame(str(opening["wall"]), width, depth)
	var origin: Vector3 = frame["origin"]
	var yaw: float = frame["yaw"]
	var centre := float(opening["x"]) * float(frame["sign"])
	var kind := str(opening.get("kind", "window"))
	var gap_bottom := float(opening["gap_bottom"])
	var gap_top := float(opening["gap_top"])
	var span := float(opening["width"])
	var pivot := Node3D.new()
	pivot.position = origin
	pivot.rotation.y = yaw
	body.add_child(pivot)
	var trim := {
		"kind": kind, "center": centre, "width": span - 0.06, "bottom": gap_bottom + (0.0 if gap_bottom <= 0.0 else 0.04),
		"top": gap_top - 0.06, "leaves": int(opening.get("leaves", 1)), "shutters": bool(opening.get("shutters", false)),
		"exponent": SuperEgg.EPSILON_FLAT,
	}
	TownProps._build_panel_opening_trim(
		body, origin, yaw, trim, 0.0, TownProps.TRIM_WOOD, WALL_T,
		opening.get("accent", Color(0.52, 0.18, 0.14))
	)
	if kind != "door":
		# The window gap would otherwise be a hole a body could pass through.
		var local := Vector3(centre, (gap_bottom + gap_top) * 0.5, 0.0)
		var box := Basis(Vector3.UP, yaw)
		TownProps._add_box_collision(
			body, origin + box * local, Vector3(span, gap_top - gap_bottom, WALL_T), box
		)


## Fills the rectangular gap the courses leave with a flat white casing that has
## a superellipse hole (square foot and rounded head for a door), so the
## opening a person sees is a superellipse framed in white board.
static func _casing(kind: String, centre: float, gap_bottom: float, gap_top: float, span: float) -> CSGCombiner3D:
	var height := gap_top - gap_bottom
	var material := SolidModel.material(CASING, 0.85, 0.0)
	var combiner := CSGCombiner3D.new()
	combiner.name = "Casing"
	combiner.use_collision = false
	SolidModel.add_box(
		combiner, "Plate", Vector3(span, height, WALL_T * 0.9), CSGShape3D.OPERATION_UNION, material,
		Vector3(centre, gap_bottom + height * 0.5, 0.0)
	)
	if kind == "door":
		SolidModel.add_box(
			combiner, "DoorFoot", Vector3(span - 0.16, height * 0.5, WALL_T * 2.0), CSGShape3D.OPERATION_SUBTRACTION,
			material, Vector3(centre, gap_bottom + height * 0.25, 0.0)
		)
		var head := SolidModel.add_profile(
			combiner, "DoorHead", WALL_T * 2.0, Vector2(height * 0.5 - 0.06, (span - 0.16) * 0.5), 4.0,
			CSGShape3D.OPERATION_SUBTRACTION, material, Vector3(centre, gap_bottom + height * 0.5 - 0.0, 0.0), 64
		)
		head.rotation.y = PI * 0.5
	else:
		var hole := SolidModel.add_profile(
			combiner, "Aperture", WALL_T * 2.0, Vector2(height * 0.5 - 0.08, span * 0.5 - 0.08), 4.0,
			CSGShape3D.OPERATION_SUBTRACTION, material, Vector3(centre, gap_bottom + height * 0.5, 0.0), 64
		)
		hole.rotation.y = PI * 0.5
	return combiner


# ---------------------------------------------------------------------------
# Walls
# ---------------------------------------------------------------------------

static func _build_walls(
	body: StaticBody3D, width: float, depth: float, floors: int, openings: Array[Dictionary],
	log_color: Color, pitch: float, skip: Array = []
) -> void:
	var wall_courses := floors * 10
	var wall_height := float(floors) * STOREY
	var tan_pitch := tan(pitch)
	var walls := ["front", "back", "west", "east"]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(width * 100.0 + depth * 7.0)
	for c in wall_courses:
		var y := (float(c) + 0.5) * COURSE
		var tone := log_color.darkened(0.035 * float(c % 3)).lightened(0.02 * float(rng.randi() % 3))
		var even := c % 2 == 0
		for wall: String in walls:
			if skip.has(wall):
				continue
			var along_x := wall == "front" or wall == "back"
			var long_wall := even if along_x else not even
			var half_run: float
			if along_x:
				half_run = (width * 0.5 + NOTCH) if long_wall else (width * 0.5 - 2.0 * R)
			else:
				half_run = (depth * 0.5 + NOTCH) if long_wall else (depth * 0.5 - 2.0 * R)
			var intervals: Array[Vector2] = [Vector2(-half_run, half_run)]
			for opening: Dictionary in openings:
				if str(opening["wall"]) != wall:
					continue
				if c < int(opening["first_course"]) or c > int(opening["last_course"]):
					continue
				var half_span := float(opening["width"]) * 0.5
				intervals = TownProps._subtract_interval(
					intervals, Vector2(float(opening["x"]) - half_span, float(opening["x"]) + half_span)
				)
			for interval in intervals:
				var length := interval.y - interval.x
				if length < 0.05:
					continue
				var mid := (interval.x + interval.y) * 0.5
				_log(body, length, _wall_point(wall, width, depth, mid, y), 0.0 if along_x else PI * 0.5, tone)
	_wall_collision(body, width, depth, wall_height, openings, skip)
	_build_gables(body, width, depth, wall_courses, wall_height, tan_pitch, openings, log_color)


static func _wall_point(wall: String, width: float, depth: float, along: float, y: float) -> Vector3:
	match wall:
		"front":
			return Vector3(along, y, -(depth * 0.5 - R))
		"back":
			return Vector3(along, y, depth * 0.5 - R)
		"west":
			return Vector3(-(width * 0.5 - R), y, along)
	return Vector3(width * 0.5 - R, y, along)


static func _log(body: StaticBody3D, length: float, at: Vector3, yaw: float, color: Color) -> void:
	var log := SuperEgg.build_part(Vector3(length * 0.5, R, R), color, LOG_EPS, LOG_EPS)
	log.position = at
	log.rotation.y = yaw
	body.add_child(log)
	CollisionPolicy.mark_decorative(log)


## One solid box per wall piece (left of, right of, above and below each gap)
## rather than one per log; the logs themselves are visual.
static func _wall_collision(
	body: StaticBody3D, width: float, depth: float, wall_height: float, openings: Array[Dictionary],
	skip: Array = []
) -> void:
	for wall: String in ["front", "back", "west", "east"]:
		if skip.has(wall):
			continue
		var along_x := wall == "front" or wall == "back"
		var half := (width if along_x else depth) * 0.5
		var cuts: Array[Dictionary] = []
		for opening: Dictionary in openings:
			if str(opening["wall"]) == wall:
				cuts.append(opening)
		cuts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["x"]) < float(b["x"]))
		var cursor := -half
		for cut: Dictionary in cuts:
			var lo := float(cut["x"]) - float(cut["width"]) * 0.5
			var hi := float(cut["x"]) + float(cut["width"]) * 0.5
			_wall_box(body, wall, width, depth, cursor, lo, 0.0, wall_height)
			var gap_top := float(cut["gap_top"])
			_wall_box(body, wall, width, depth, lo, hi, gap_top, wall_height)
			if float(cut["gap_bottom"]) > 0.0:
				_wall_box(body, wall, width, depth, lo, hi, 0.0, float(cut["gap_bottom"]))
			cursor = hi
		_wall_box(body, wall, width, depth, cursor, half, 0.0, wall_height)


static func _wall_box(
	body: StaticBody3D, wall: String, width: float, depth: float, from: float, to: float, y0: float, y1: float
) -> void:
	if to - from < 0.03 or y1 - y0 < 0.03:
		return
	var along_x := wall == "front" or wall == "back"
	var centre := _wall_point(wall, width, depth, (from + to) * 0.5, (y0 + y1) * 0.5)
	var size := Vector3(to - from, y1 - y0, 2.0 * R) if along_x else Vector3(2.0 * R, y1 - y0, to - from)
	TownProps._add_box_collision(body, centre, size)


## Gable ends keep laying shortening courses of the same logs until the roof
## closes them.
static func _build_gables(
	body: StaticBody3D, width: float, depth: float, first_course: int, wall_height: float, tan_pitch: float,
	openings: Array[Dictionary], log_color: Color
) -> void:
	var c := first_course
	while true:
		var y := (float(c) + 0.5) * COURSE
		var half_len := depth * 0.5 - (y - wall_height - 0.12 + ROOF_T) / tan_pitch
		if half_len < 0.2:
			break
		var tone := log_color.darkened(0.035 * float(c % 3))
		for side: float in [-1.0, 1.0]:
			var wall := "west" if side < 0.0 else "east"
			var intervals: Array[Vector2] = [Vector2(-half_len, half_len)]
			for opening: Dictionary in openings:
				if str(opening["wall"]) != wall:
					continue
				if c < int(opening["first_course"]) or c > int(opening["last_course"]):
					continue
				var half_span := float(opening["width"]) * 0.5
				intervals = TownProps._subtract_interval(
					intervals, Vector2(float(opening["x"]) - half_span, float(opening["x"]) + half_span)
				)
			for interval in intervals:
				if interval.y - interval.x < 0.05:
					continue
				var mid := (interval.x + interval.y) * 0.5
				_log(body, interval.y - interval.x, Vector3(side * (width * 0.5 - R), y, mid), PI * 0.5, tone)
		c += 1


static func _build_plinth(
	body: StaticBody3D, width: float, depth: float, openings: Array[Dictionary], skip: Array = []
) -> void:
	for wall: String in ["front", "back", "west", "east"]:
		if skip.has(wall):
			continue
		var along_x := wall == "front" or wall == "back"
		var half := (width if along_x else depth) * 0.5 + 0.05
		var intervals: Array[Vector2] = [Vector2(-half, half)]
		for opening: Dictionary in openings:
			if str(opening["wall"]) != wall or float(opening["gap_bottom"]) > 0.0:
				continue
			var half_span := float(opening["width"]) * 0.5 + 0.02
			intervals = TownProps._subtract_interval(
				intervals, Vector2(float(opening["x"]) - half_span, float(opening["x"]) + half_span)
			)
		for interval in intervals:
			if interval.y - interval.x < 0.1:
				continue
			var mid := (interval.x + interval.y) * 0.5
			var at := _wall_point(wall, width, depth, mid, PLINTH_H * 0.5 - 0.02)
			var outward := Vector3.ZERO
			match wall:
				"front":
					outward = Vector3(0, 0, -0.06)
				"back":
					outward = Vector3(0, 0, 0.06)
				"west":
					outward = Vector3(-0.06, 0, 0)
				_:
					outward = Vector3(0.06, 0, 0)
			var half_size := Vector3((interval.y - interval.x) * 0.5, PLINTH_H * 0.5, R + 0.08) if along_x \
				else Vector3(R + 0.08, PLINTH_H * 0.5, (interval.y - interval.x) * 0.5)
			var stone := SuperEgg.build_part(half_size, STONE.darkened(0.06 * float(int(mid) % 3)), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT)
			stone.position = at + outward
			body.add_child(stone)
			CollisionPolicy.mark_decorative(stone)


# ---------------------------------------------------------------------------
# Roof
# ---------------------------------------------------------------------------

## Roof surface as (|z|, y) points from the ridge outward. A gallery makes the
## bellcast flare long and shallow so it covers a walkway on posts.
static func roof_profile(
	width: float, depth: float, floors: int, pitch: float, bellcast: bool, gallery: float = 0.0
) -> Array[Vector2]:
	var wall_height := float(floors) * STOREY
	var tan_pitch := tan(pitch)
	var ridge_y := wall_height + 0.12 + depth * 0.5 * tan_pitch
	var points: Array[Vector2] = [Vector2(0.0, ridge_y)]
	if bellcast or gallery > 0.0:
		var break_z := depth * 0.5 - 0.35
		var break_y := wall_height + 0.12 + 0.35 * tan_pitch
		var tip_z := depth * 0.5 + (gallery + 0.3 if gallery > 0.0 else EAVE + 0.5)
		var flare_angle := deg_to_rad(15.0) if gallery > 0.0 else maxf(pitch - deg_to_rad(22.0), deg_to_rad(12.0))
		points.append(Vector2(break_z, break_y))
		points.append(Vector2(tip_z, break_y - (tip_z - break_z) * tan(flare_angle)))
	else:
		var tip_z := depth * 0.5 + EAVE
		points.append(Vector2(tip_z, ridge_y - tip_z * tan_pitch))
	return points


static func _slab_basis(front: bool, run: float, rise: float) -> Basis:
	# `run` is |z| travelled away from the ridge and `rise` the (negative) height change.
	var angle := atan2(-rise, run)
	var normal := Vector3(0.0, cos(angle), -sin(angle) if front else sin(angle))
	var along := Vector3(0.0, -normal.z, normal.y)
	return Basis(Vector3.RIGHT, normal, along)


static func _build_roof(
	body: StaticBody3D, width: float, depth: float, floors: int, pitch: float, bellcast: bool, roof_color: Color,
	gallery: float = 0.0
) -> void:
	var front_profile := roof_profile(width, depth, floors, pitch, bellcast, gallery)
	var back_profile := roof_profile(width, depth, floors, pitch, bellcast)
	var profile := front_profile
	var half_length := width * 0.5 + GABLE_OH
	for front: bool in [true, false]:
		var sign_z := -1.0 if front else 1.0
		profile = front_profile if front else back_profile
		for i in profile.size() - 1:
			var a := profile[i]
			var b := profile[i + 1]
			var run := b.x - a.x
			var drop := a.y - b.y
			var length := Vector2(run, drop).length()
			var basis := _slab_basis(front, run, -drop)
			var mid := Vector3(0.0, (a.y + b.y) * 0.5, sign_z * (a.x + b.x) * 0.5)
			var overlap := 0.05 if i == 0 else 0.0
			var centre := mid - basis.y * ROOF_T * 0.5
			# The same roof construction as Ohio (TownProps.roof_slab): squarish
			# shoulders, and the slope meeting the ridge is cut in the vertical plane
			# through it so the two slopes join in one flat seam, with no overlap.
			var slab: MeshInstance3D
			if i == 0:
				slab = TownProps.build_ridge_slab(
					body, basis, centre, half_length, length, ROOF_T, roof_color,
					-sign_z, Plane(Vector3(0.0, 0.0, -sign_z), 0.0)
				)
			else:
				slab = TownProps.roof_slab(Vector3(half_length, ROOF_T * 0.5, length * 0.5), roof_color)
				slab.transform = Transform3D(basis, centre)
				body.add_child(slab)
			CollisionPolicy.add_box(body, slab, Vector3(half_length * 2.0, ROOF_T, length + overlap * 2.0), centre, basis, true)
			# Snow lies on the slab but stops short of the drip edge on the last run.
			var last_run := i == profile.size() - 2
			var snow_length := length - (0.28 if last_run else 0.0)
			var snow := SuperEgg.build_part(
				Vector3(half_length - 0.08, SNOW_T * 0.5, snow_length * 0.5 + overlap), SNOW, 4.2, 4.2
			)
			snow.set_meta(DesignAudit.ROOF_COVER_META, true)
			var shift := (0.14 if front else -0.14) if last_run else 0.0
			var snow_centre := mid + basis.y * (SNOW_T * 0.5 - 0.01) + basis.z * shift
			snow.transform = Transform3D(basis, snow_centre)
			body.add_child(snow)
			CollisionPolicy.mark_decorative(snow)
	var ridge := SuperEgg.build_part(Vector3(half_length + 0.05, 0.11, 0.13), TownProps.TRIM_WOOD.darkened(0.2), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	ridge.position = Vector3(0.0, front_profile[0].y + 0.06, 0.0)
	body.add_child(ridge)
	CollisionPolicy.mark_decorative(ridge)
	_build_rakes(body, width, front_profile, back_profile, pitch)


## Carved bargeboards along each gable rake, extended past the peak into crossed
## horse-head finials, the village's signature motif.
static func _build_rakes(
	body: StaticBody3D, width: float, front_profile: Array[Vector2], back_profile: Array[Vector2], pitch: float
) -> void:
	var x_edge := width * 0.5 + GABLE_OH
	var wood := TownProps.TRIM_WOOD.lightened(0.04)
	for side: float in [-1.0, 1.0]:
		for front: bool in [true, false]:
			var sign_z := -1.0 if front else 1.0
			var profile := front_profile if front else back_profile
			for i in profile.size() - 1:
				var a := profile[i]
				var b := profile[i + 1]
				var length := Vector2(b.x - a.x, a.y - b.y).length()
				var angle := atan2(a.y - b.y, b.x - a.x)
				var board := SuperEgg.build_part(Vector3(0.035, 0.12, length * 0.5 + 0.03), wood, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
				var mid := Vector3(side * x_edge, (a.y + b.y) * 0.5 - 0.08, sign_z * (a.x + b.x) * 0.5)
				var basis := _slab_basis(front, b.x - a.x, -(a.y - b.y))
				board.transform = Transform3D(basis, mid)
				board.scale = Vector3(1, 1, 1)
				body.add_child(board)
				CollisionPolicy.mark_decorative(board)
				if i == 0:
					# The board continues over the peak on the far slope: with the mirror
					# board it makes the crossed finial.
					var ext := 0.62
					var dir := Vector3(0.0, sin(angle), -sign_z * cos(angle))
					var centre := Vector3(side * x_edge, a.y - 0.02, 0.0) + dir * ext * 0.5
					var up := Vector3(0.0, cos(angle), sign_z * sin(angle)).normalized()
					var finial_basis := Basis(Vector3.RIGHT, up, Vector3(0.0, -up.z, up.y))
					var piece := SuperEgg.build_part(Vector3(0.035, 0.1, ext * 0.5), wood, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
					piece.transform = Transform3D(finial_basis, centre)
					body.add_child(piece)
					CollisionPolicy.mark_decorative(piece)
					var head := SuperEgg.build_part(Vector3(0.075, 0.1, 0.12), wood.darkened(0.1), 2.4, 2.4)
					head.transform = Transform3D(finial_basis, centre + dir * (ext * 0.5 + 0.05))
					body.add_child(head)
					CollisionPolicy.mark_decorative(head)
