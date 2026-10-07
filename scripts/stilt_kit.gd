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
## House floors: indoor boards, out of the sun, a warm mid brown.
const PLANK := Color(0.58, 0.43, 0.29)
## Open decks: tropical hardwood (chengal, belian) bleached by sun and water to
## a silvery grey-brown on top. Only wet timber (piles, beam undersides) stays
## dark. Each plank varies a little toward silver or warmer brown.
const DECK := Color(0.60, 0.53, 0.43)
const DECK_SILVER := Color(0.66, 0.65, 0.60)
const DECK_WARM := Color(0.55, 0.42, 0.30)
const PLANK_WIDTH := 0.2
const PLANK_GAP := 0.015
const PLANK_THICKNESS := 0.05
## Longest plank; wider decks are planked in staggered lengths over joists.
const PLANK_MAX := 3.2
const SHINGLE := Color(0.47, 0.39, 0.31)
const ROPE := Color(0.72, 0.62, 0.42)

## Charter module, revised (2026-10-07, after the walkthrough found eaves
## "barely above the player's head"): the ring beam stands 4.0 m above the
## floor, so a veranda pent of Ohio-thick slabs tucks under the main eave and
## still clears 2.4 m at its outer edge. Every eave a person walks under
## clears MIN_HEADROOM (the proof scene checks it along every route).
const RING_BEAM := 4.0
## Where a veranda or porch pent meets its house wall, above the floor.
const PENT_AT_WALL := 3.15
const MIN_HEADROOM := 2.35
const BAND := 1.0
const POST_HALF := 0.13
const PILE_HALF := 0.15
const FLOOR_THICKNESS := 0.16
const BEAM_DEPTH := 0.24
const RAIL_HEIGHT := 0.95
const DOOR_TOP := 2.4
const INTERIOR_DOOR_TOP := 2.45
const WINDOW_SILL := 1.02
const WINDOW_TOP := 2.42
const WINDOW_WIDTH := 0.94


# ---------------------------------------------------------------------------
# Walls
# ---------------------------------------------------------------------------

## A door opening at a plan point on a wall. `top` is above the wall's base.
## Its leaf swings inward, into the room it serves, never across a porch or
## veranda (TownProps' outside doors swing out; this village's do not).
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
			# TownProps' side-hung pairs are not this village's joinery; the
			# top-hung awning shutter is built below instead.
			entry["shutters"] = false
			entry["awning"] = bool(opening.get("shutters", false))
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
		if opening["kind"] == "door":
			# Built from the inner face (the wall turned half round, so the
			# opening's position along it mirrors): frames are the same on both
			# faces, and the leaf now hangs on the inside.
			var inward := opening.duplicate()
			inward["center"] = -float(opening["center"])
			TownProps._build_panel_opening_trim(body, Vector3(mid.x, base_y, mid.y), yaw + PI, inward, base_y, TIMBER_DARK, TownProps.WALL_THICKNESS, accent)
		else:
			TownProps._build_panel_opening_trim(body, Vector3(mid.x, base_y, mid.y), yaw, opening, base_y, TIMBER_DARK, TownProps.WALL_THICKNESS, accent)
	for opening in resolved:
		if bool(opening.get("awning", false)):
			_awning_shutter(body, mid + dir * float(opening["center"]), dir, Vector2(dir.y, -dir.x), float(opening["width"]), float(opening["top"]), accent)
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


## The top-hung shutter of the charter's Thai and Malay joinery: one panel
## hinged at the window head, propped out by a stick as a sunshade. It never
## reaches sideways, so neighbouring windows, doors and posts keep clear, and
## its low edge stays above head height.
const AWNING_DROP := 0.78
const AWNING_ANGLE := deg_to_rad(64.0)


static func _awning_shutter(body: StaticBody3D, centre: Vector2, along: Vector2, outward: Vector2, width: float, top_y: float, accent: Color) -> void:
	var hinge := Vector3(centre.x, top_y + 0.06, centre.y) + Vector3(outward.x, 0.0, outward.y) * 0.1
	var out3 := Vector3(outward.x, 0.0, outward.y)
	# The panel's local y runs from the hinge down its face; turned out by the
	# prop angle about the wall's line.
	var down := (Vector3.DOWN * cos(AWNING_ANGLE) + out3 * sin(AWNING_ANGLE)).normalized()
	var across := Vector3(along.x, 0.0, along.y)
	var normal := across.cross(down).normalized()
	var basis := Basis(across, down, normal)
	var panel := egg(Vector3(width * 0.5 + 0.08, AWNING_DROP * 0.5, 0.025), accent, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	panel.transform = Transform3D(basis, hinge + down * (AWNING_DROP * 0.5))
	body.add_child(panel)
	CollisionPolicy.mark_decorative(panel)
	var batten := egg(Vector3(width * 0.5 + 0.02, 0.025, 0.02), accent.darkened(0.25), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	batten.transform = Transform3D(basis, hinge + down * (AWNING_DROP * 0.55) + normal * 0.03)
	body.add_child(batten)
	CollisionPolicy.mark_decorative(batten)
	# The prop stick from the sill to the panel's lower edge.
	var tip := hinge + down * AWNING_DROP
	var foot := Vector3(centre.x, top_y - 1.25, centre.y) + out3 * 0.08
	var stick := egg(Vector3(0.015, foot.distance_to(tip) * 0.5, 0.015), TIMBER_DARK, 2.0, 2.0)
	var up := (tip - foot).normalized()
	var side := up.cross(across).normalized()
	stick.transform = Transform3D(Basis(across, up, side).orthonormalized(), (foot + tip) * 0.5 + across * (width * 0.35))
	body.add_child(stick)
	CollisionPolicy.mark_decorative(stick)


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
		var rail := egg(Vector3((run.y - run.x) * 0.5, 0.03, TownProps.WALL_THICKNESS * 0.5 + 0.025), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		rail.transform = Transform3D(Basis(Vector3.UP, atan2(-dir.y, dir.x)), Vector3(centre.x, y, centre.y))
		body.add_child(rail)
		CollisionPolicy.mark_decorative(rail)


## A full-height interior partition of boards, with framed doorways. Draw it so
## the room its doors open into lies to the left of `from` -> `to` (TownProps'
## rule: a door swings toward the wall's local -Z).
## With a `curtain` colour (alpha above zero) its doorways carry no leaf but a
## cloth curtain (the langsir of Malay and Thai houses): framed openings that
## anyone walks straight through, the cloth gathered to one jamb. Hard doors
## stay where something must close: outside doors, toilets, stores.
static func partition(body: StaticBody3D, from: Vector2, to: Vector2, base_y: float, height: float, door_distances: Array[float], curtain: Color = Color(0, 0, 0, 0)) -> void:
	# Doorways are as tall as the outside doors (2.45 m), so a route through one
	# keeps MIN_HEADROOM; the engine's interior default is 2.3 m.
	var options: Array[Dictionary] = []
	for i in door_distances.size():
		var option := {"top": base_y + INTERIOR_DOOR_TOP}
		if curtain.a > 0.0:
			option["leaves"] = 0
		options.append(option)
	TownProps.build_interior_wall(body, from, to, base_y, door_distances, TIMBER_PALE, TIMBER_DARK, height, true, [], {}, options)
	if curtain.a <= 0.0:
		return
	var dir := (to - from).normalized()
	var yaw := atan2(-dir.y, dir.x)
	var half := TownProps.INTERIOR_DOOR_WIDTH * 0.5
	var top := base_y + INTERIOR_DOOR_TOP
	for i in door_distances.size():
		var centre := from + dir * door_distances[i]
		var basis := Basis(Vector3.UP, yaw)
		var at := Vector3(centre.x, 0.0, centre.y)
		# The rod and a short valance across the head, on the wall's face.
		var rod := egg(Vector3(half + 0.08, 0.02, 0.02), TIMBER_DARK, 2.0, 2.0)
		rod.transform = Transform3D(basis, at + Vector3(0.0, top - 0.08, 0.0))
		body.add_child(rod)
		CollisionPolicy.mark_decorative(rod)
		var valance := egg(Vector3(half + 0.04, 0.09, 0.025), curtain, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
		valance.transform = Transform3D(basis, at + Vector3(0.0, top - 0.17, 0.0))
		body.add_child(valance)
		CollisionPolicy.mark_decorative(valance)
		# The cloth drawn back to one jamb and tied, in soft folds.
		for fold in 3:
			var x := -half + 0.07 + 0.07 * float(fold)
			var cloth := egg(Vector3(0.05, (top - base_y - 0.3) * 0.5, 0.03), curtain.darkened(0.06 * float(fold % 2)), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
			cloth.transform = Transform3D(basis, at + basis * Vector3(x, 0.0, 0.0) + Vector3(0.0, base_y + 0.15 + (top - base_y - 0.3) * 0.5, 0.0))
			body.add_child(cloth)
			CollisionPolicy.mark_decorative(cloth)
		var tie := egg(Vector3(0.14, 0.03, 0.05), curtain.lightened(0.25), 2.0, 2.0)
		tie.transform = Transform3D(basis, at + basis * Vector3(-half + 0.14, 0.0, 0.0) + Vector3(0.0, base_y + 1.0, 0.0))
		body.add_child(tie)
		CollisionPolicy.mark_decorative(tie)


# ---------------------------------------------------------------------------
# Frame: posts, beams, floors, ceilings, piles, rails
# ---------------------------------------------------------------------------

## A squarish post from `y0` to `y1`. A rope-bound post (the village's signature
## motif, at every threshold and mooring) carries a close spiral of rope.
static func post(body: StaticBody3D, at: Vector2, y0: float, y1: float, color: Color = TIMBER, roped: bool = false) -> void:
	var half := Vector3(POST_HALF, (y1 - y0) * 0.5, POST_HALF)
	var mesh := egg(half, color, TownProps.POST_EPSILON, TownProps.POST_EPSILON)
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
		var ring := egg(Vector3(post_half + 0.035, 0.03, post_half + 0.035), ROPE.darkened(0.06 * float(turn % 2)), SuperEgg.EPSILON_SOFT, 2.0)
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
	var mesh := egg(Vector3(length * 0.5, half_section.y, half_section.x), color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	var mid := (a + b) * 0.5
	mesh.transform = Transform3D(Basis(Vector3.UP, atan2(-dir.y, dir.x)), Vector3(mid.x, y, mid.y))
	body.add_child(mesh)
	CollisionPolicy.mark_decorative(mesh)
	# Not solid, but a lamp or cord may hang from it (reach_hangers).
	mesh.set_meta("overhead", true)


## A plank floor, top at `top_y`: planks over joists, with one smooth collider
## for the whole floor so nothing snags on a plank edge. Planks run across the
## rect's longer side (laid across the way people walk along it).
static func floor_slab(body: StaticBody3D, rect: Rect2, top_y: float, color: Color = PLANK) -> void:
	var centre := rect.get_center()
	var along_x := rect.size.x >= rect.size.y
	var basis := Basis() if not along_x else Basis(Vector3.UP, PI * 0.5)
	var across := rect.size.y if along_x else rect.size.x
	var along := rect.size.x if along_x else rect.size.y
	var planks := plank_surface(body, Transform3D(basis, Vector3(centre.x, top_y, centre.y)), across, along, color)
	CollisionPolicy.add_box(body, planks, Vector3(rect.size.x, FLOOR_THICKNESS, rect.size.y), Vector3(centre.x, top_y - FLOOR_THICKNESS * 0.5, centre.y), Basis(), true)
	# The joists' dark line under the planks, seen through the gaps and at the
	# deck's edge.
	var under := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(rect.size.x - 0.04, FLOOR_THICKNESS - PLANK_THICKNESS, rect.size.y - 0.04)
	under.mesh = box
	under.material_override = SolidModel.material(TIMBER_DARK.darkened(0.3), 0.9, 0.0)
	under.position = Vector3(centre.x, top_y - PLANK_THICKNESS - box.size.y * 0.5 - 0.01, centre.y)
	body.add_child(under)
	CollisionPolicy.mark_decorative(under)


## Planks covering an `across` x `along` area in `parent`'s frame at `xform`
## (local x across the planks' length, local z along the run, the planks' top at
## local y 0). Squarish SuperEgg boards, gapped, in staggered lengths, each a
## little different in tone, drawn as one MultiMesh. Visual only: the caller
## pairs it with the collider (CollisionPolicy).
static func plank_surface(parent: Node3D, xform: Transform3D, across: float, along: float, color: Color = DECK) -> MultiMeshInstance3D:
	var pitch := PLANK_WIDTH + PLANK_GAP
	var rows := maxi(int(round(along / pitch)), 1)
	var row_pitch := along / float(rows)
	var transforms: Array[Transform3D] = []
	var tones: Array[Color] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector3(xform.origin.x, xform.origin.z, across * 31.0 + along))
	for row in rows:
		var z := -along * 0.5 + (float(row) + 0.5) * row_pitch
		# Joints fall on joist lines, staggered row to row.
		var cuts: Array[float] = [-across * 0.5]
		if across > PLANK_MAX:
			var x := -across * 0.5 + PLANK_MAX * (0.34 + 0.33 * float(row % 3))
			while x < across * 0.5 - 0.4:
				cuts.append(x)
				x += PLANK_MAX
		cuts.append(across * 0.5)
		for i in cuts.size() - 1:
			var length := cuts[i + 1] - cuts[i] - PLANK_GAP
			var centre := (cuts[i] + cuts[i + 1]) * 0.5
			var basis := Basis().scaled(Vector3(length, 1.0, 1.0))
			transforms.append(xform * Transform3D(basis, Vector3(centre, -PLANK_THICKNESS * 0.5, z)))
			var tone := color.lerp(DECK_SILVER if rng.randf() < 0.5 else DECK_WARM, rng.randf_range(0.0, 0.45))
			if rng.randf() < 0.04:
				tone = tone.lightened(0.18)
			tones.append(tone.darkened(rng.randf_range(0.0, 0.06)))
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = _plank_mesh()
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, tones[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = "Planks"
	instance.multimesh = multi
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	# Instance colours are authored in sRGB like every other colour here.
	material.vertex_color_is_srgb = true
	material.roughness = 0.88
	instance.material_override = material
	parent.add_child(instance)
	return instance


static var _plank_mesh_cache: Mesh


## One plank, a metre long (scaled to length), squarish SuperEgg. The plan
## outline shares the profile's exponent, and at EPSILON_FLAT a long thin plank
## tapers over its last 20 cm into a lozenge; at 14 the end rounds over a few
## centimetres, a board with softened edges.
const PLANK_EPSILON := 14.0


static func _plank_mesh() -> Mesh:
	if _plank_mesh_cache == null:
		# A plank is a box with softened arrises: 8 x 12 sampling keeps that at
		# a sixth of the triangles, and it is drawn thousands of times.
		_plank_mesh_cache = SuperEgg.build_mesh(Vector3(0.5, PLANK_THICKNESS * 0.5, PLANK_WIDTH * 0.5), PLANK_EPSILON, PLANK_EPSILON, 8, 12)
	return _plank_mesh_cache


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
			var mesh := egg(half, TIMBER_DARK.darkened(0.15), TownProps.POST_EPSILON, TownProps.POST_EPSILON)
			mesh.position = Vector3(p.x, (top_y + shelf_y) * 0.5, p.y)
			mesh.set_meta("pile", true)
			body.add_child(mesh)
			CollisionPolicy.add_box(body, mesh, half * 2.0, mesh.position, Basis(), false)
			var cap := egg(Vector3(PILE_HALF + 0.04, 0.05, PILE_HALF + 0.04), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
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
			var brace := egg(Vector3(0.06, length * 0.5, 0.06), TIMBER_DARK.darkened(0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
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
	var top := egg(Vector3(length * 0.5, 0.04, 0.05), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	top.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(mid.x, floor_y + RAIL_HEIGHT, mid.y))
	body.add_child(top)
	CollisionPolicy.add_box(body, top, Vector3(length, RAIL_HEIGHT + 0.08, 0.1), Vector3(mid.x, floor_y + (RAIL_HEIGHT + 0.08) * 0.5, mid.y), Basis(Vector3.UP, yaw), false)
	var count := maxi(int(ceil(length / 1.2)), 1)
	for i in count + 1:
		var p := a + dir * (float(i) / float(count))
		var baluster := egg(Vector3(0.035, RAIL_HEIGHT * 0.5, 0.035), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		baluster.position = Vector3(p.x, floor_y + RAIL_HEIGHT * 0.5, p.y)
		body.add_child(baluster)
		CollisionPolicy.mark_decorative(baluster)
	var mid_rail := egg(Vector3(length * 0.5, 0.025, 0.03), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	mid_rail.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(mid.x, floor_y + RAIL_HEIGHT * 0.5, mid.y))
	body.add_child(mid_rail)
	CollisionPolicy.mark_decorative(mid_rail)


## A broad planked ramp from `low` (at `low_y`) up to `high` (at `high_y`),
## `width` across: the threshold from a deck up to a house floor, a slipway, a
## swim exit. Planks laid across the slope on two stringers, with one sloped
## collider whose top face is flush with the planks at both ends. Its own body.
static func ramp(body: StaticBody3D, low: Vector2, high: Vector2, low_y: float, high_y: float, width: float, color: Color = DECK) -> StaticBody3D:
	var run := low.distance_to(high)
	var rise := high_y - low_y
	var slope := sqrt(run * run + rise * rise)
	var dir := (high - low) / run
	var basis := Basis(Vector3.UP, atan2(dir.x, dir.y)) * Basis(Vector3.RIGHT, -atan2(rise, run))
	var mid := Vector3((low.x + high.x) * 0.5, (low_y + high_y) * 0.5, (low.y + high.y) * 0.5)
	var ramp_body := StaticBody3D.new()
	ramp_body.name = "Ramp"
	ramp_body.collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
	ramp_body.collision_mask = 0
	body.add_child(ramp_body)
	var planks := plank_surface(ramp_body, Transform3D(basis, mid), width, slope, color)
	CollisionPolicy.add_box(ramp_body, planks, Vector3(width, 0.3, slope), mid - basis.y * 0.15, basis, true)
	for side: float in [-1.0, 1.0]:
		var stringer := egg(Vector3(0.07, 0.11, slope * 0.5), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		stringer.transform = Transform3D(basis, mid + basis * Vector3(side * (width * 0.5 - 0.25), -PLANK_THICKNESS - 0.11, 0.0))
		ramp_body.add_child(stringer)
		CollisionPolicy.mark_decorative(stringer)
	return ramp_body


## Handrails along both sides of a ramp's upper part, the part that stands
## above the water (swim exits keep their lower ends open for climbing out).
static func ramp_rails(body: StaticBody3D, low: Vector2, high: Vector2, low_y: float, high_y: float, width: float) -> void:
	var start := clampf(-low_y / maxf(high_y - low_y, 0.01), 0.0, 1.0)
	for side: float in [-1.0, 1.0]:
		var offset := Vector2(-(high - low).normalized().y, (high - low).normalized().x) * side * (width * 0.5 - 0.06)
		sloped_rail(body, low.lerp(high, start) + offset, high + offset, lerpf(low_y, high_y, start), high_y, false)


## A handrail that climbs with a ramp: from plan point `a` at walking level
## `ya` to `b` at `yb`, balusters standing on the slope, the rail parallel to
## it. With `solid`, a sloped collider keeps people off the open edge.
static func sloped_rail(body: StaticBody3D, a: Vector2, b: Vector2, ya: float, yb: float, solid: bool = true) -> void:
	var count := maxi(int(ceil(a.distance_to(b) / 1.2)), 1)
	for i in count + 1:
		var t := float(i) / float(count)
		var p := a.lerp(b, t)
		var y := lerpf(ya, yb, t)
		var baluster := egg(Vector3(0.035, RAIL_HEIGHT * 0.5, 0.035), TIMBER_DARK, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		baluster.position = Vector3(p.x, y + RAIL_HEIGHT * 0.5, p.y)
		body.add_child(baluster)
		CollisionPolicy.mark_decorative(baluster)
	var from := Vector3(a.x, ya + RAIL_HEIGHT, a.y)
	var to := Vector3(b.x, yb + RAIL_HEIGHT, b.y)
	var along := (to - from).normalized()
	var rail_mesh := egg(Vector3(0.04, 0.04, from.distance_to(to) * 0.5), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	# Its long axis (local z) along the rail.
	var basis := Basis.looking_at(-along, Vector3.UP)
	rail_mesh.transform = Transform3D(basis, (from + to) * 0.5)
	body.add_child(rail_mesh)
	if solid:
		# A slab from the ramp's surface up to the rail, tilted with it.
		var centre := (from + to) * 0.5 - basis.y * ((RAIL_HEIGHT + 0.08) * 0.5 - 0.04)
		CollisionPolicy.add_box(body, rail_mesh, Vector3(0.1, RAIL_HEIGHT + 0.08, from.distance_to(to)), centre, basis, false)
	else:
		CollisionPolicy.mark_decorative(rail_mesh)


## A junction lamp: a rope-bound post with a bracket arm toward `arm`, and an
## oil lamp hung from the arm (the charter's "lamps hang under eaves and from
## junction posts"; no lights on poles).
static func lamp_post(body: StaticBody3D, at: Vector2, floor_y: float, arm: Vector2) -> void:
	post(body, at, floor_y - FLOOR_THICKNESS, floor_y + 3.1, TIMBER, true)
	var tip := at + arm.normalized() * 0.65
	beam(body, at, tip, floor_y + 2.95, Vector2(0.05, 0.06), TIMBER_DARK)
	# The shade hangs well above head height over the way it lights.
	# Hung just inside the arm's rounded end, so the chain meets timber.
	var hook := at + arm.normalized() * 0.56
	Furnishings.hanging_lamp(body, Vector3(hook.x, floor_y + 2.45, hook.y), 0.9, 7.0)


## A glazed rain jar under a downpipe: every roof drains somewhere.
static func rain_jar(body: StaticBody3D, at: Vector2, floor_y: float, glaze: Color) -> void:
	var jar := egg(Vector3(0.3, 0.38, 0.3), glaze, 2.2, 2.2)
	jar.position = Vector3(at.x, floor_y + 0.38, at.y)
	body.add_child(jar)
	CollisionPolicy.add_box(body, jar, Vector3(0.6, 0.76, 0.6), jar.position, Basis(), true)
	var lip := egg(Vector3(0.2, 0.04, 0.2), glaze.darkened(0.2), 2.2, 2.2)
	lip.position = Vector3(at.x, floor_y + 0.78, at.y)
	body.add_child(lip)
	CollisionPolicy.mark_decorative(lip)


## A gutter along an eave line, a downpipe falling at `pipe_at`, and a short
## spout from the pipe's foot to the glazed jar at `jar_at` that catches it.
static func gutter(body: StaticBody3D, a: Vector2, b: Vector2, y: float, pipe_at: Vector2, jar_at: Vector2, jar_top_y: float) -> void:
	beam(body, a, b, y, Vector2(0.06, 0.05), TIMBER_DARK)
	var foot_y := jar_top_y + 0.35
	var pipe := egg(Vector3(0.045, (y - foot_y) * 0.5, 0.045), TIMBER_DARK, 2.2, SuperEgg.EPSILON_FLAT)
	pipe.position = Vector3(pipe_at.x, (y + foot_y) * 0.5, pipe_at.y)
	body.add_child(pipe)
	CollisionPolicy.mark_decorative(pipe)
	var from := Vector3(pipe_at.x, foot_y, pipe_at.y)
	var to := Vector3(jar_at.x, jar_top_y + 0.05, jar_at.y)
	var up := (from - to).normalized()
	var side := up.cross(Vector3.UP if absf(up.y) < 0.95 else Vector3.RIGHT).normalized()
	var spout := egg(Vector3(0.04, from.distance_to(to) * 0.5, 0.04), TIMBER_DARK, 2.2, SuperEgg.EPSILON_FLAT)
	spout.transform = Transform3D(Basis(side, up, side.cross(up)), (from + to) * 0.5)
	body.add_child(spout)
	CollisionPolicy.mark_decorative(spout)


## A body-relative direction's yaw for a piece whose back (local +Z) must face
## `back_toward` in plan (Furnishings' convention: back +Z, front -Z).
static func yaw_back_to(back_toward: Vector2) -> float:
	return atan2(back_toward.x, back_toward.y)


## Stretches every hanger in `body` (a node with meta "hanger": a lamp chain,
## a string, a cord; a thin piece standing on its centre) up to the first
## solid above it, so nothing hangs from thin air whatever the ceiling height.
## Measured against the body's own box colliders (ceilings, pents, roof slabs,
## beams), before the body enters the tree. A hanger with nothing within
## `reach` above it is left as built and reported.
static func reach_hangers(body: Node3D, reach: float = 3.5) -> void:
	var boxes: Array = []
	var triangles: Array[PackedVector3Array] = []
	for node in body.find_children("*", "CollisionShape3D", true, false):
		var shape_node := node as CollisionShape3D
		if shape_node.disabled or shape_node.shape == null:
			continue
		if shape_node.shape is BoxShape3D:
			boxes.append([_xform_in(body, shape_node), (shape_node.shape as BoxShape3D).size * 0.5])
		else:
			# Any other shape (a hip end's convex hull): its faces as triangles.
			var faces := shape_node.shape.get_debug_mesh().get_faces()
			var shape_xform := _xform_in(body, shape_node)
			var world_faces := PackedVector3Array()
			for point in faces:
				world_faces.append(shape_xform * point)
			triangles.append(world_faces)
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var member := node as MeshInstance3D
		if member.has_meta("overhead") and member.mesh != null:
			var bounds := member.mesh.get_aabb()
			boxes.append([_xform_in(body, member) * Transform3D(Basis(), bounds.get_center()), bounds.size * 0.5])
	for node in body.find_children("*", "MeshInstance3D", true, false):
		var hanger := node as MeshInstance3D
		if not hanger.has_meta("hanger") or hanger.mesh == null:
			continue
		var xform := _xform_in(body, hanger)
		var aabb := xform * hanger.mesh.get_aabb()
		var foot_y := aabb.position.y
		var top := Vector3(aabb.get_center().x, aabb.end.y, aabb.get_center().z)
		var hit := INF
		var origin := top - Vector3(0, 0.02, 0)
		for box: Array in boxes:
			hit = minf(hit, _ray_up_box(origin, box[0], box[1]))
		for faces in triangles:
			for i in range(0, faces.size() - 2, 3):
				var point: Variant = Geometry3D.ray_intersects_triangle(origin, Vector3.UP, faces[i], faces[i + 1], faces[i + 2])
				if point != null:
					hit = minf(hit, (point as Vector3).y - origin.y)
		if hit == INF or hit > reach:
			push_warning("%s: hanger %s has nothing above it within %.1f m" % [body.name, hanger.name, reach])
			continue
		var target_top := top.y - 0.02 + hit + 0.03
		var scale_y := (target_top - foot_y) / maxf(aabb.size.y, 0.001)
		hanger.scale.y *= scale_y
		var centre_y := (foot_y + target_top) * 0.5
		hanger.position.y += centre_y - aabb.get_center().y
		hanger.set_meta("hanger_top", target_top)


static func _xform_in(root: Node3D, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			xform = (current as Node3D).transform * xform
		current = current.get_parent()
	return xform


## Distance up from `origin` to the box (`xform`, half extents `half`), or INF.
static func _ray_up_box(origin: Vector3, xform: Transform3D, half: Vector3) -> float:
	var inv := xform.affine_inverse()
	var o := inv * origin
	var d := inv.basis * Vector3.UP
	var t_near := -INF
	var t_far := INF
	for axis in 3:
		if absf(d[axis]) < 1e-6:
			if o[axis] < -half[axis] or o[axis] > half[axis]:
				return INF
			continue
		var t1 := (-half[axis] - o[axis]) / d[axis]
		var t2 := (half[axis] - o[axis]) / d[axis]
		t_near = maxf(t_near, minf(t1, t2))
		t_far = minf(t_far, maxf(t1, t2))
	if t_near > t_far or t_far < 0.0:
		return INF
	return maxf(t_near, 0.0)


## A SuperEgg part sampled for its size (SuperEgg.prop_detail): the kit's
## posts, rails and balusters are drawn by the hundred in every village.
static func egg(semi_axes: Vector3, color: Color, epsilon_top: float = SuperEgg.EPSILON_SOFT, epsilon_bottom: float = SuperEgg.EPSILON_SOFT) -> MeshInstance3D:
	var detail := SuperEgg.prop_detail(semi_axes)
	return SuperEgg.build_part(semi_axes, color, epsilon_top, epsilon_bottom, detail.x, detail.y)
