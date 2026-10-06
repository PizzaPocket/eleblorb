class_name StiltKit
extends RefCounted

## The fishing village's kit of parts (docs/style_charters.md, "Crossroads
## Fishing Village"; docs/architecture/fishing_village_building_designs.md,
## section 2): light post-and-beam frames on squarish piles, walls of timber
## boards to the waist with panels in the household colour above, superellipse
## openings with piped frames, rope-bound threshold posts, top rails at open
## deck edges. Every building in the village is assembled from these, so the
## same few parts recur and the village reads as one people's work.
##
## Frame: a building body's own plan (x east, z south, as in FishingVillagePlan)
## with y measured from the lake surface W, so the plan's heights (deck W + 0.50,
## house floor W + 0.75) are used as they are written.

## Natural timber is 60 percent of the palette; the household colour 30; the
## accent (shutters, door leaves, ridge caps) 10.
const TIMBER := Color(0.55, 0.40, 0.26)
const TIMBER_PALE := Color(0.66, 0.52, 0.36)
const TIMBER_DARK := Color(0.33, 0.22, 0.14)
const PLANK := Color(0.50, 0.36, 0.22)
const SHINGLE := Color(0.47, 0.39, 0.31)
const ROPE := Color(0.72, 0.62, 0.42)

## Charter module, revised (2026-10-06): the ring beam stands 3.3 m above the
## floor, so a veranda pent can tuck under the main eave and still leave 2.0 m
## of headroom at its outer edge.
const RING_BEAM := 3.3
const BAND := 1.0
const POST_HALF := 0.13
const PILE_HALF := 0.15
const FLOOR_THICKNESS := 0.16
const BEAM_DEPTH := 0.24
const RAIL_HEIGHT := 0.95
const DOOR_TOP := 2.4
const WINDOW_SILL := 1.02
const WINDOW_TOP := 2.42
const WINDOW_WIDTH := 0.94


# ---------------------------------------------------------------------------
# Walls
# ---------------------------------------------------------------------------

## A door opening at a plan point on a wall. `top` is above the wall's base.
static func door(at: Vector2, top: float = DOOR_TOP, leaves: int = 1, width: float = TownProps.DOOR_WIDTH) -> Dictionary:
	return {"kind": "door", "at": at, "width": width, "rise": top, "leaves": leaves}


## A window at a plan point on a wall: a narrow casement with top-hung-style
## shutters drawn open (dwellings only, per the charter).
static func window(at: Vector2, shutters: bool = true) -> Dictionary:
	return {"kind": "window", "at": at, "width": WINDOW_WIDTH, "shutters": shutters}


## An outside wall from `a` to `b` whose outer face looks toward `outward`.
## Boards to the waist in natural timber, panels in `panel_color` above, a dado
## rail where they meet, and every opening punched once through both bands and
## framed on both faces. `roof_plane` (optional) cuts the wall to a roof's
## underside: {"at": Vector2, "y": float, "grad": Vector2} is the height of the
## plane at a plan point and its rise per metre in plan.
static func wall(
	body: StaticBody3D, a: Vector2, b: Vector2, outward: Vector2, base_y: float, height: float,
	openings: Array[Dictionary], panel_color: Color, accent: Color, roof_plane: Dictionary = {}
) -> void:
	var dir := (b - a).normalized()
	# TownProps walls face their outer side along local -Z, which lies at
	# (dir.y, -dir.x) in plan; draw the wall the way round that makes it so.
	if Vector2(dir.y, -dir.x).dot(outward) < 0.0:
		var swap := a
		a = b
		b = swap
		dir = -dir
	var length := a.distance_to(b)
	var mid := (a + b) * 0.5
	var yaw := atan2(-dir.y, dir.x)
	var resolved: Array[Dictionary] = []
	for opening in openings:
		var centre := (Vector2(opening["at"]) - mid).dot(dir)
		var entry := {"kind": opening["kind"], "center": centre, "width": opening["width"], "interior": true}
		if opening["kind"] == "door":
			entry["bottom"] = base_y
			entry["top"] = base_y + float(opening["rise"])
			entry["leaves"] = int(opening["leaves"])
		else:
			entry["bottom"] = base_y + WINDOW_SILL
			entry["top"] = base_y + WINDOW_TOP
			entry["leaves"] = 0
			entry["shutters"] = bool(opening.get("shutters", false))
		resolved.append(entry)
	var top_at := func(p: Vector2) -> float:
		if roof_plane.is_empty():
			return base_y + height
		return float(roof_plane["y"]) + Vector2(roof_plane["grad"]).dot(p - Vector2(roof_plane["at"]))
	var cut_a: float = top_at.call(mid)
	var cut_b := 0.0 if roof_plane.is_empty() else Vector2(roof_plane["grad"]).dot(dir)
	var full := maxf(float(top_at.call(a)), float(top_at.call(b))) - base_y if not roof_plane.is_empty() else height
	# Lower band: boards to the waist.
	var lower_cuts: Array = []
	TownProps._build_panel_facade(body, length, Vector3(mid.x, base_y, mid.y), yaw, TIMBER, resolved, base_y, BAND, TownProps.WALL_THICKNESS, lower_cuts)
	# Upper band: the household's panels, cut to the roof where one bears on it.
	var upper_cuts: Array = []
	if not roof_plane.is_empty():
		upper_cuts.append({"a": cut_a - (base_y + BAND), "b": cut_b})
	TownProps._build_panel_facade(body, length, Vector3(mid.x, base_y + BAND, mid.y), yaw, panel_color, resolved, base_y + BAND, full - BAND, TownProps.WALL_THICKNESS, upper_cuts)
	for opening in resolved:
		TownProps._build_panel_opening_trim(body, Vector3(mid.x, base_y, mid.y), yaw, opening, base_y, TIMBER_DARK, TownProps.WALL_THICKNESS, accent)
	_dado_rail(body, a, dir, length, base_y + BAND, resolved)
	ClearZones.add_wall(body, "outside wall (%.1f, %.1f) to (%.1f, %.1f)" % [a.x, a.y, b.x, b.y], a, b, base_y, full, TownProps.WALL_THICKNESS, true)
	var inward := -outward.normalized()
	for opening in resolved:
		var at := mid + dir * float(opening["center"])
		var half := float(opening["width"]) * 0.5
		if opening["kind"] == "door":
			ClearZones.add(body, "door at (%.1f, %.1f)" % [at.x, at.y], "door", at, inward, 1.3, 1.3, half + 0.2, base_y + 0.05, base_y + 1.9)
		else:
			ClearZones.add(body, "window at (%.1f, %.1f)" % [at.x, at.y], "window", at, inward, 0.05, 0.55, half + 0.25, float(opening["bottom"]), float(opening["bottom"]) + 1.4)


## The rail capping the board band, broken at every door.
static func _dado_rail(body: StaticBody3D, a: Vector2, dir: Vector2, length: float, y: float, openings: Array[Dictionary]) -> void:
	var runs: Array[Vector2] = [Vector2(0.0, length)]
	for opening in openings:
		if opening["kind"] != "door":
			continue
		var centre := float(opening["center"]) + length * 0.5
		var half := float(opening["width"]) * 0.5 + 0.08
		runs = TownProps._subtract_interval(runs, Vector2(centre - half, centre + half))
	for run in runs:
		if run.y - run.x < 0.2:
			continue
		var centre := a + dir * ((run.x + run.y) * 0.5)
		var rail := SuperEgg.build_part(Vector3((run.y - run.x) * 0.5, 0.03, TownProps.WALL_THICKNESS * 0.5 + 0.025), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		rail.transform = Transform3D(Basis(Vector3.UP, atan2(-dir.y, dir.x)), Vector3(centre.x, y, centre.y))
		body.add_child(rail)
		CollisionPolicy.mark_decorative(rail)


## A full-height interior partition of boards, with framed doorways. Draw it so
## the room its doors open into lies to the left of `from` -> `to` (TownProps'
## rule: a door swings toward the wall's local -Z).
static func partition(body: StaticBody3D, from: Vector2, to: Vector2, base_y: float, height: float, door_distances: Array[float]) -> void:
	TownProps.build_interior_wall(body, from, to, base_y, door_distances, TIMBER_PALE, TIMBER_DARK, height)


# ---------------------------------------------------------------------------
# Frame: posts, beams, floors, ceilings, piles, rails
# ---------------------------------------------------------------------------

## A squarish post from `y0` to `y1`. A rope-bound post (the village's signature
## motif, at every threshold and mooring) carries a close spiral of rope.
static func post(body: StaticBody3D, at: Vector2, y0: float, y1: float, color: Color = TIMBER, roped: bool = false) -> void:
	var half := Vector3(POST_HALF, (y1 - y0) * 0.5, POST_HALF)
	var mesh := SuperEgg.build_part(half, color, TownProps.POST_EPSILON, TownProps.POST_EPSILON)
	mesh.position = Vector3(at.x, (y0 + y1) * 0.5, at.y)
	body.add_child(mesh)
	CollisionPolicy.add_box(body, mesh, half * 2.0, mesh.position, Basis(), false)
	if roped:
		rope_binding(body, at, y0 + 0.55, y0 + 1.55)


## A close spiral of rope round a post between two heights: a stack of soft
## rings, each a little turned, so it reads as wrapped rather than banded.
static func rope_binding(body: StaticBody3D, at: Vector2, y0: float, y1: float, post_half: float = POST_HALF) -> void:
	var y := y0
	var turn := 0
	while y <= y1:
		var ring := SuperEgg.build_part(Vector3(post_half + 0.035, 0.03, post_half + 0.035), ROPE.darkened(0.06 * float(turn % 2)), SuperEgg.EPSILON_SOFT, 2.0)
		ring.transform = Transform3D(Basis(Vector3.UP, 0.2 * float(turn)) * Basis(Vector3.RIGHT, 0.06), Vector3(at.x, y, at.y))
		body.add_child(ring)
		CollisionPolicy.mark_decorative(ring)
		y += 0.058
		turn += 1


## A horizontal timber between two plan points at height `y` (its centre).
static func beam(body: StaticBody3D, a: Vector2, b: Vector2, y: float, half_section: Vector2 = Vector2(0.1, 0.12), color: Color = TIMBER_DARK) -> void:
	var dir := (b - a)
	var length := dir.length()
	if length < 0.05:
		return
	var mesh := SuperEgg.build_part(Vector3(length * 0.5, half_section.y, half_section.x), color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	var mid := (a + b) * 0.5
	mesh.transform = Transform3D(Basis(Vector3.UP, atan2(-dir.y, dir.x)), Vector3(mid.x, y, mid.y))
	body.add_child(mesh)
	CollisionPolicy.mark_decorative(mesh)


## A plank floor: a plain slab filling to the walls (a rounded slab would leave
## open corners), top at `top_y`.
static func floor_slab(body: StaticBody3D, rect: Rect2, top_y: float, color: Color = PLANK) -> void:
	slab(body, rect, top_y - FLOOR_THICKNESS * 0.5, FLOOR_THICKNESS, color, true)


## A flat plank ceiling at the ring beam: the roof space above is vented at the
## ridge, the rooms below are closed.
static func ceiling(body: StaticBody3D, rect: Rect2, underside_y: float) -> void:
	slab(body, rect, underside_y + 0.05, 0.1, TIMBER_DARK.lightened(0.08), true)


static func slab(body: StaticBody3D, rect: Rect2, centre_y: float, thickness: float, color: Color, solid: bool) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rect.size.x, thickness, rect.size.y)
	mesh.mesh = box
	mesh.material_override = SolidModel.material(color, 0.86, 0.0)
	var centre := rect.get_center()
	mesh.position = Vector3(centre.x, centre_y, centre.y)
	body.add_child(mesh)
	if solid:
		CollisionPolicy.add_box(body, mesh, box.size, mesh.position, Basis(), true)
	else:
		CollisionPolicy.mark_decorative(mesh)


## Squarish piles from the shelf to the underside of the floor beams, each with
## a cap, braced in pairs along each row. `rows` are lists of plan points; every
## point must lie on a shelf (FishingVillagePlan.shelf_distance), which the
## caller checks in world plan coordinates.
static func piles(body: StaticBody3D, rows: Array, top_y: float, shelf_y: float) -> void:
	for row: Array in rows:
		for p: Vector2 in row:
			var half := Vector3(PILE_HALF, (top_y - shelf_y) * 0.5, PILE_HALF)
			var mesh := SuperEgg.build_part(half, TIMBER_DARK.darkened(0.15), TownProps.POST_EPSILON, TownProps.POST_EPSILON)
			mesh.position = Vector3(p.x, (top_y + shelf_y) * 0.5, p.y)
			body.add_child(mesh)
			CollisionPolicy.add_box(body, mesh, half * 2.0, mesh.position, Basis(), false)
			var cap := SuperEgg.build_part(Vector3(PILE_HALF + 0.04, 0.05, PILE_HALF + 0.04), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			cap.position = Vector3(p.x, top_y - 0.04, p.y)
			body.add_child(cap)
			CollisionPolicy.mark_decorative(cap)
		# Braced in pairs: one diagonal between each neighbouring pair, below the
		# beams and above the water, so the bracing reads at the deck edge.
		for i in row.size() - 1:
			var p0: Vector2 = row[i]
			var p1: Vector2 = row[i + 1]
			var from := Vector3(p0.x, top_y - 0.15, p0.y)
			var to := Vector3(p1.x, maxf(shelf_y, -0.9), p1.y)
			var length := from.distance_to(to)
			var brace := SuperEgg.build_part(Vector3(0.06, length * 0.5, 0.06), TIMBER_DARK.darkened(0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			var up := (to - from).normalized()
			var side := up.cross(Vector3.FORWARD if absf(up.z) < 0.9 else Vector3.RIGHT).normalized()
			brace.transform = Transform3D(Basis(side, up, side.cross(up)), (from + to) * 0.5)
			body.add_child(brace)
			CollisionPolicy.mark_decorative(brace)


## A top rail on slender posts along an open deck edge more than 0.6 m above
## the water. The collider is one thin solid fence, so nothing falls through
## between the posts.
static func rail(body: StaticBody3D, a: Vector2, b: Vector2, floor_y: float) -> void:
	var dir := b - a
	var length := dir.length()
	var yaw := atan2(-dir.y, dir.x)
	var mid := (a + b) * 0.5
	var top := SuperEgg.build_part(Vector3(length * 0.5, 0.04, 0.05), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	top.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(mid.x, floor_y + RAIL_HEIGHT, mid.y))
	body.add_child(top)
	CollisionPolicy.add_box(body, top, Vector3(length, RAIL_HEIGHT + 0.08, 0.1), Vector3(mid.x, floor_y + (RAIL_HEIGHT + 0.08) * 0.5, mid.y), Basis(Vector3.UP, yaw), false)
	var count := maxi(int(ceil(length / 1.2)), 1)
	for i in count + 1:
		var p := a + dir * (float(i) / float(count))
		var baluster := SuperEgg.build_part(Vector3(0.035, RAIL_HEIGHT * 0.5, 0.035), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		baluster.position = Vector3(p.x, floor_y + RAIL_HEIGHT * 0.5, p.y)
		body.add_child(baluster)
		CollisionPolicy.mark_decorative(baluster)
	var mid_rail := SuperEgg.build_part(Vector3(length * 0.5, 0.025, 0.03), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	mid_rail.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(mid.x, floor_y + RAIL_HEIGHT * 0.5, mid.y))
	body.add_child(mid_rail)
	CollisionPolicy.mark_decorative(mid_rail)


## A broad timber ramp from `low` (at `low_y`) up to `high` (at `high_y`),
## `width` across: the threshold from a deck up to a house floor. Its own body,
## built with the shared ramp so the top face is flush at both ends.
static func ramp(body: StaticBody3D, low: Vector2, high: Vector2, low_y: float, high_y: float, width: float) -> void:
	var run := low.distance_to(high)
	var ramp_body := TownProps.build_ramp(width, run, high_y - low_y, PLANK.lightened(0.05))
	ramp_body.name = "ThresholdRamp"
	var dir := (high - low) / run
	ramp_body.position = Vector3(low.x, low_y, low.y)
	ramp_body.rotation.y = atan2(dir.x, dir.y)
	body.add_child(ramp_body)


## A glazed rain jar under a downpipe: every roof drains somewhere.
static func rain_jar(body: StaticBody3D, at: Vector2, floor_y: float, glaze: Color) -> void:
	var jar := SuperEgg.build_part(Vector3(0.3, 0.38, 0.3), glaze, 2.2, 2.2)
	jar.position = Vector3(at.x, floor_y + 0.38, at.y)
	body.add_child(jar)
	CollisionPolicy.add_box(body, jar, Vector3(0.6, 0.76, 0.6), jar.position, Basis(), true)
	var lip := SuperEgg.build_part(Vector3(0.2, 0.04, 0.2), glaze.darkened(0.2), 2.2, 2.2)
	lip.position = Vector3(at.x, floor_y + 0.78, at.y)
	body.add_child(lip)
	CollisionPolicy.mark_decorative(lip)


## A gutter along an eave line, a downpipe falling at `pipe_at`, and a short
## spout from the pipe's foot to the glazed jar at `jar_at` that catches it.
static func gutter(body: StaticBody3D, a: Vector2, b: Vector2, y: float, pipe_at: Vector2, jar_at: Vector2, jar_top_y: float) -> void:
	beam(body, a, b, y, Vector2(0.06, 0.05), TIMBER_DARK)
	var foot_y := jar_top_y + 0.35
	var pipe := SuperEgg.build_part(Vector3(0.045, (y - foot_y) * 0.5, 0.045), TIMBER_DARK, 2.2, SuperEgg.EPSILON_FLAT)
	pipe.position = Vector3(pipe_at.x, (y + foot_y) * 0.5, pipe_at.y)
	body.add_child(pipe)
	CollisionPolicy.mark_decorative(pipe)
	var from := Vector3(pipe_at.x, foot_y, pipe_at.y)
	var to := Vector3(jar_at.x, jar_top_y + 0.05, jar_at.y)
	var up := (from - to).normalized()
	var side := up.cross(Vector3.UP if absf(up.y) < 0.95 else Vector3.RIGHT).normalized()
	var spout := SuperEgg.build_part(Vector3(0.04, from.distance_to(to) * 0.5, 0.04), TIMBER_DARK, 2.2, SuperEgg.EPSILON_FLAT)
	spout.transform = Transform3D(Basis(side, up, side.cross(up)), (from + to) * 0.5)
	body.add_child(spout)
	CollisionPolicy.mark_decorative(spout)


## A body-relative direction's yaw for a piece whose back (local +Z) must face
## `back_toward` in plan (Furnishings' convention: back +Z, front -Z).
static func yaw_back_to(back_toward: Vector2) -> float:
	return atan2(back_toward.x, back_toward.y)
