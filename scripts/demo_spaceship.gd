class_name DemoSpaceship
extends Node3D

signal cabin_entered

## The ASAN launch vehicle, hanging in space above the volcano (see
## demo_world.gd). Built the way everything in this project is built, out of
## SuperEggs: the main hull is one long hollow superegg shell with real wall
## thickness and a superellipse aperture punched through its flank
## (SuperEgg.build_hollow_shell_mesh()), not a skin of linked segments. A
## solid flat deck runs the length of the cabin inside it, and that deck, not
## the curved hull, is what anyone walks and platforms on.
##
## Proportions follow a heavy-lift rocket: a long core stage, a tapering nose
## stack, two strap-on boosters down the far flank, and a clustered engine
## bell at the aft. The hull lies along local Z, nose forward (+Z), with the
## doorway facing +X so it can be flown straight into from the ascent portal.

## The core stage: radius, half-length, and how thick its wall reads.
const HULL_RADIUS := 11.0
const HULL_HALF_LENGTH := 35.0
const HULL_WALL := 0.9
## The doorway, as a superellipse punched through the +X flank: its centre
## along the hull and up the flank, and its half-extents the same way.
const DOOR_CENTER := Vector2(-6.0, -1.0)
const DOOR_HALF := Vector2(6.5, 5.0)
const DOOR_EXPONENT := 2.8
## A second, much smaller opening at the aft end of the same flank: a circle
## (a superellipse of exponent 2 with equal halves), sized so only a blorb
## fits through it, and matched by the escape pod's own circular opening.
const HATCH_CENTER := Vector2(-26.0, -3.6)
const HATCH_RADIUS := EscapePod.POD_DOOR_RADIUS
## How far the pod's shell is pushed into the hull's. The two overlap by this
## much, which is what closes the seam between them.
const POD_SEAL_INSET := 0.9
## Windows down both flanks, at eye height above the deck: each is cut out of
## the hull and then filled by the very piece the cut removed, rebuilt in
## glass (SuperEgg.build_shell_patch_mesh()), so every pane sits flush in its
## own opening by construction.
## One long port a side rather than three small ones, per direct instruction.
## It sits above the consoles, which stand under it.
const WINDOW_STATIONS := [17.0]
const WINDOW_Y := 1.5
const WINDOW_HALF := Vector2(13.0, 4.2)
const WINDOW_EXPONENT := 2.6
## Hull left standing between a window and any doorway or hatch, so every
## opening keeps a frame of its own.
const WINDOW_KEEP_CLEAR := 2.5
## How far a window may be slid along the flank, and in what increments, to
## find room beside an opening it would otherwise have met.
const WINDOW_SLIDE := 1.5
const WINDOW_SLIDE_STEPS := 14
const GLASS := Color(0.44, 0.68, 0.86, 0.34)
## The hull is built on a finer grid than the default. Openings are cut cell
## by cell, so the grid's own spacing is the resolution of every outline: at
## the default the windows came out as chunky staircases. Panes are the exact
## complement of the cut, so nothing can gap either way.
## Fine enough that an opening's clipped edge reads as a curve rather than as
## the grid beneath it. The clip puts vertices exactly on the boundary either
## way, but how closely the polyline between them follows the curve is still a
## question of how big a cell is.
## The shell's own grid, deliberately moderate. An opening's outline no longer
## depends on it: the cells its edge runs through are subdivided and clipped
## (see SuperEgg.EDGE_SUBDIVISION), so a hole is sampled finely while the rest
## of the hull stays cheap.
const HULL_RINGS := 56
const HULL_SEGMENTS := 76
## The deck: its height below the hull's axis, how far it reaches either side
## of the centreline, and its thickness.
const DECK_Y := -5.0
const DECK_HALF_WIDTH := 8.5
const DECK_THICKNESS := 0.5
## Head height inside: the cabin's collision ceiling.
const CABIN_CEILING_Y := 7.0
## Breathable volume, inset from the hull so the seal never reads as extending
## through the wall.
const CABIN_AIR_RADIUS := 9.6
## How far the air reaches past the cabin's own inner surface, so a body
## pressed against the wall is still breathing. Comfortably less than the
## wall's thickness, so the air never reaches outside the hull.
const AIR_WALL_GRIP := 0.35
## How long a console bank runs along the flank, which is also the clearance
## it keeps from a window so it never stands in front of the glass.
const CONSOLE_HALF_LENGTH := 2.4
## Where the consoles stand along each flank. Two spread down the near side
## and one on the far side, all of them under the long window above.
## How many steps the floor's own outline is swept in. Its width follows the
## hull at every one, so this is how finely that curve is drawn rather than how
## many pieces the floor is made of: it is one mesh.
const DECK_STATIONS := 96
## How far a console stands clear of the wall behind it.
const CONSOLE_WALL_GAP := 1.6
const CONSOLE_STATIONS_NEAR := [9.0, 26.0]
const CONSOLE_STATIONS_FAR := [17.0]

const HULL := Color(0.88, 0.90, 0.94)
const HULL_SHADOW := Color(0.62, 0.66, 0.74)
const TRIM := Color(0.15, 0.16, 0.20)
const PANEL := Color(0.74, 0.78, 0.85)
const SCREEN := Color(0.52, 0.86, 1.0)
const STRIP_LIGHT := Color(0.66, 0.92, 1.0)

## The escape pod, mounted outside the blorb hatch (see escape_pod.gd).
var escape_pod: EscapePod

var _was_inside := false


func _ready() -> void:
	add_to_group("pressurized_volumes")
	_build_ship()


## Inside the pressure hull: within the cabin's own radius of the hull axis,
## clear of both end walls, and above the deck.
## The air fills the cabin: the hull's INNER volume, not its outer skin.
##
## The boundary sits a little proud of the inner surface but still well inside
## the wall, which is what makes both halves of this true at once. Testing the
## inner surface exactly put a body standing against the wall outside its own
## ship's air, and dropped it into zero gravity; testing the outer surface
## instead reached out past the hull, so gravity came on while a body was still
## in the doorway rather than through it. The wall itself is the margin.
func contains_breathable_point(point: Vector3) -> bool:
	var local := to_local(point)
	# The hull is drawn with its long axis on Y and turned to lie along Z, so
	# the test is written in that same frame.
	var cabin := _hull_axes() - Vector3.ONE * (HULL_WALL - AIR_WALL_GRIP)
	return SuperEgg.contains_point(
		cabin, Vector3(local.x, local.z, -local.y),
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)


func _process(_delta: float) -> void:
	var body := PartyControl.active_control_body()
	var inside := is_instance_valid(body) and contains_breathable_point(body.global_position)
	if inside and not _was_inside:
		cabin_entered.emit()
	_was_inside = inside


func _build_ship() -> void:
	_build_hull()
	_build_deck()
	_build_interior_fittings()
	_build_stack()
	_build_escape_pod()


## The core stage itself: one hollow shell, its doorway cut straight through.
## The shell is authored in the superegg's own frame, whose long axis is Y,
## then turned a quarter turn so the hull lies along Z; the aperture stays on
## +X through that turn (it is the axis the turn is about).
func _build_hull() -> void:
	var shell := MeshInstance3D.new()
	shell.name = "Hull"
	var apertures := _hull_apertures()
	shell.mesh = SuperEgg.build_hollow_shell_mesh(
		_hull_axes(), HULL_WALL, apertures, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT,
		HULL_RINGS, HULL_SEGMENTS
	)
	shell.rotation.x = PI * 0.5
	var material := _hull_material(HULL)
	# Both faces of the shell are seen: the outside from space, the inside
	# from the cabin.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = material
	# The hull is what you actually stand inside, so it collides as the shape
	# it is drawn as, holes and all. A box of flat panels used to be built
	# inside it to do this job, which is what made the shell's own thickness
	# decorative and cost the cabin most of its width.
	var body := StaticBody3D.new()
	body.name = "HullBody"
	body.collision_layer = 1
	body.rotation.x = PI * 0.5
	add_child(body)
	shell.rotation.x = 0.0
	body.add_child(shell)
	# The collider is built from the same shell at a coarse edge: a body
	# leaning on the wall cannot feel how finely the window's outline is
	# sampled, and paying for that in physics as well as in pixels is waste.
	var collision_shell := SuperEgg.build_hollow_shell_mesh(
		_hull_axes(), HULL_WALL, apertures, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT,
		HULL_RINGS, HULL_SEGMENTS, false, 1
	)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(_mesh_faces(collision_shell))
	# Both faces of the shell are stood against: the inside from the cabin,
	# the outside when climbing on it.
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.name = "HullCollider"
	collider.shape = shape
	body.add_child(collider)
	_glaze_windows(apertures)


## Every triangle of `mesh`, for a collider that matches the drawn surface.
func _mesh_faces(mesh: Mesh) -> PackedVector3Array:
	var faces := PackedVector3Array()
	if mesh == null:
		return faces
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
		if raw_indices == null:
			faces.append_array(vertices)
			continue
		var indices: PackedInt32Array = raw_indices
		for index in indices:
			faces.append(vertices[index])
	return faces


## Every opening cut through the hull. The superegg's own Y is the hull's Z
## and its Z is the hull's -Y, so each centre is written in that frame.
func _hull_apertures() -> Array[Dictionary]:
	var apertures: Array[Dictionary] = [
		{
			"center": Vector2(DOOR_CENTER.x, -DOOR_CENTER.y),
			"half": DOOR_HALF, "exponent": DOOR_EXPONENT,
		},
		_pod_hatch_aperture(),
	]
	# A window is never cut where a way in or out already is. The openings
	# share one surface, and two that meet make a single ragged hole with no
	# frame between them, which is what the windows did to the doorway.
	# Only the ways in and out are protected. The windows' own spacing is
	# authored, and policing them against each other as well was quietly
	# costing the flank two of its three panes.
	var ways := apertures.duplicate()
	for side: float in [-1.0, 1.0]:
		for station: float in WINDOW_STATIONS:
			var placed := _place_window(station, side, ways)
			if not placed.is_empty():
				apertures.append(placed)
	return apertures


## A window at `station`, slid along the flank until it clears every opening
## already cut. Sliding rather than dropping it: the flank is meant to carry
## three windows a side, and one that would have met the doorway belongs a
## little further along, not nowhere.
func _place_window(station: float, side: float, existing: Array[Dictionary]) -> Dictionary:
	for step in WINDOW_SLIDE_STEPS + 1:
		for direction: float in [1.0, -1.0]:
			var moved := station + direction * float(step) * WINDOW_SLIDE
			if absf(moved) > HULL_HALF_LENGTH - WINDOW_HALF.x - 4.0:
				continue
			var window := {
				"center": Vector2(moved, -WINDOW_Y),
				"half": WINDOW_HALF, "exponent": WINDOW_EXPONENT, "side": side,
			}
			if _aperture_clear_of_ways(window, existing):
				return window
			if step == 0:
				break
	return {}


## The hatch, cut by the escape pod's own shell rather than by a circle drawn
## on the hull. The superegg is authored with its long axis on Y and turned a
## quarter turn to lie along Z, so the pod's position is written in that frame:
## the hull's Z is the superegg's Y, and the hull's Y its -Z.
func _pod_hatch_aperture() -> Dictionary:
	var mount := _pod_mount()
	return {
		"sphere_center": Vector3(mount.x, mount.z, -mount.y),
		"sphere_radius": EscapePod.POD_RADIUS,
		"half": Vector2(HATCH_RADIUS, HATCH_RADIUS),
		"center": Vector2(HATCH_CENTER.x, -HATCH_CENTER.y),
		"exponent": 2.0,
	}


## Whether `candidate` keeps its distance from every opening already cut.
## Both footprints are grown by WINDOW_KEEP_CLEAR first, so they are not
## merely disjoint but leave hull between them to hold a frame.
static func _aperture_clear_of_ways(candidate: Dictionary, existing: Array[Dictionary]) -> bool:
	var centre: Vector2 = candidate["center"]
	var half: Vector2 = candidate["half"]
	var side: float = float(candidate.get("side", 0.0))
	for opening in existing:
		# Two openings on opposite flanks cannot meet. An opening with no side
		# of its own is cut straight through, so it is on both.
		var other_side: float = float(opening.get("side", 0.0))
		if side != 0.0 and other_side != 0.0 and side != other_side:
			continue
		var other_centre: Vector2 = opening["center"]
		var other_half: Vector2 = opening["half"]
		var gap := (centre - other_centre).abs()
		var reach := half + other_half + Vector2.ONE * WINDOW_KEEP_CLEAR
		if gap.x < reach.x and gap.y < reach.y:
			return false
	return true


## Fills each window opening with the piece its own cut removed, rebuilt in
## glass. Same axes, same wall, same aperture: the pane cannot drift out of
## its hole because it is the hole.
func _glaze_windows(apertures: Array[Dictionary]) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = GLASS
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.2
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var index := 0
	for aperture in apertures:
		if float(aperture.get("exponent", 0.0)) != WINDOW_EXPONENT:
			continue
		var pane := MeshInstance3D.new()
		pane.name = "Window%d" % index
		index += 1
		pane.mesh = SuperEgg.build_shell_patch_mesh(
			_hull_axes(), HULL_WALL, aperture, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT,
			HULL_RINGS, HULL_SEGMENTS
		)
		pane.material_override = glass
		pane.rotation.x = PI * 0.5
		add_child(pane)
		CollisionPolicy.mark_decorative(pane)


## Where a console stands against the flank: inside the hull's own wall, far
## enough in that the curve above it clears a standing body.
func _console_flank_offset_at(hull_z: float) -> float:
	# The hull narrows toward both ends, so a fixed offset put a console
	# through the wall at some stations and out through an opening at others.
	return maxf(_deck_half_width_at(hull_z) - CONSOLE_WALL_GAP, 1.0)


func _hull_axes() -> Vector3:
	return Vector3(HULL_RADIUS, HULL_HALF_LENGTH, HULL_RADIUS)


## How far out the floor reaches at `hull_z`: to the hull's own inner surface
## at deck height, so the two meet with nothing between them.
## One quad of the floor, into both the drawn mesh and its collider.
func _deck_quad(
	tool: SurfaceTool, faces: PackedVector3Array,
	a0: Vector3, a1: Vector3, b0: Vector3, b1: Vector3
) -> void:
	for corner in [a0, b0, a1, a1, b0, b1]:
		tool.add_vertex(corner)
		faces.append(corner)


func _deck_half_width_at(hull_z: float) -> float:
	var axes := _hull_axes() - Vector3.ONE * HULL_WALL
	var rise: float = absf(DECK_Y) / maxf(axes.x, 0.0001)
	var along: float = absf(hull_z) / maxf(axes.y, 0.0001)
	# The shell's own profile: how much width is left at this station once the
	# length and the drop to the deck have been spent.
	var spent: float = pow(along, SuperEgg.EPSILON_SOFT) + pow(rise, SuperEgg.EPSILON_SOFT)
	if spent >= 1.0:
		return 0.0
	return axes.x * pow(1.0 - spent, 1.0 / SuperEgg.EPSILON_SOFT)


## The hull's own outer surface distance from its axis at `hull_z`, found by
## walking the superegg's profile rather than assuming a cylinder: the hull
## tapers toward both ends, so the pod has to sit against the real surface.
func _hull_surface_x(hull_z: float) -> float:
	var best := HULL_RADIUS
	var closest := INF
	for step in 361:
		var eta := -PI * 0.5 + PI * float(step) / 360.0
		var point := SuperEgg.surface_point(_hull_axes(), eta, PI * 0.5)
		var gap := absf(point.y - hull_z)
		if gap < closest:
			closest = gap
			best = point.x
	return best


## The deck: a solid floor plate running the cabin's length, and the surface
## everyone actually stands on. The hull around it is scenery; this is not.
## The floor spans the hull, so it IS the hull's own cross-section at deck
## height: one mesh whose edge is that curve, swept the cabin's length and
## closed at both ends.
##
## Two earlier attempts are recorded because each looked like the answer to
## the other. One fixed-width slab gapped down each side everywhere but
## amidships, since the shell tapers toward both ends. Two dozen slabs of
## stepped width replaced that gap with a staircase, which is the same fault
## at a smaller scale. A curve is not a series of boxes.
func _build_deck() -> void:
	var body := StaticBody3D.new()
	body.name = "Deck"
	body.collision_layer = 1
	body.position = Vector3(0.0, DECK_Y - DECK_THICKNESS, 0.0)
	add_child(body)
	var reach := HULL_HALF_LENGTH - 3.0
	var steps := DECK_STATIONS
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for index in steps:
		var from := -reach + 2.0 * reach * float(index) / float(steps)
		var to := -reach + 2.0 * reach * float(index + 1) / float(steps)
		var from_half := _deck_half_width_at(from)
		var to_half := _deck_half_width_at(to)
		var top := DECK_THICKNESS
		var under := -DECK_THICKNESS
		# The top surface, the underside, and the curved edge joining them.
		_deck_quad(tool, faces,
			Vector3(-from_half, top, from), Vector3(from_half, top, from),
			Vector3(-to_half, top, to), Vector3(to_half, top, to))
		_deck_quad(tool, faces,
			Vector3(from_half, under, from), Vector3(-from_half, under, from),
			Vector3(to_half, under, to), Vector3(-to_half, under, to))
		for side: float in [-1.0, 1.0]:
			_deck_quad(tool, faces,
				Vector3(side * from_half, under, from), Vector3(side * from_half, top, from),
				Vector3(side * to_half, under, to), Vector3(side * to_half, top, to))
	var plate := MeshInstance3D.new()
	plate.name = "DeckPlate"
	tool.generate_normals()
	plate.mesh = tool.commit()
	var panel := StandardMaterial3D.new()
	panel.albedo_color = PANEL
	panel.roughness = 0.6
	plate.material_override = panel
	body.add_child(plate)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.name = "DeckCollider"
	collider.shape = shape
	body.add_child(collider)
	# A brighter grating strip down the centreline, as in the reference cabin.
	var grating := SuperEgg.build_part(
		Vector3(2.6, 0.06, HULL_HALF_LENGTH - 5.0), HULL_SHADOW,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	grating.name = "DeckGrating"
	grating.position = Vector3(0.0, DECK_THICKNESS, 0.0)
	body.add_child(grating)
	CollisionPolicy.mark_decorative(grating)


## Walls a body can lean on, rather than leaving the curved shell uncollided:
## the two flanks, the ceiling and both end walls, with the doorway left open
## on +X. Boxes, per this project's collision policy.
## Consoles, screens and light strips down both flanks, in the reference
## cabin's arrangement: a continuous bank of instrument panels at working
## height with lit screens above them, under a run of ceiling strip light.
func _build_interior_fittings() -> void:
	# The consoles stand against the hull itself now that nothing is built
	# inside it, set in far enough that the flank curves away above them
	# rather than through them. They stand UNDER the long window rather than
	# beside it, per direct instruction: two spread down one flank and one on
	# the other, instead of three crowded in a row.
	for side: float in [-1.0, 1.0]:
		for station: float in (CONSOLE_STATIONS_NEAR if side > 0.0 else CONSOLE_STATIONS_FAR):
			# The doorway's own stretch of flank carries no console.
			if side > 0.0 and absf(station - DOOR_CENTER.x) < DOOR_HALF.x + CONSOLE_HALF_LENGTH:
				continue
			if absf(station - HATCH_CENTER.x) < HATCH_RADIUS + CONSOLE_HALF_LENGTH + 3.0:
				continue
			_console(
				Vector3(side * _console_flank_offset_at(station), DECK_Y + 1.1, station), side
			)
	var strip := SuperEgg.build_part(
		Vector3(0.5, 0.18, HULL_HALF_LENGTH - 6.0), STRIP_LIGHT,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	strip.name = "CeilingStrip"
	strip.position = Vector3(0.0, CABIN_CEILING_Y - 0.3, 0.0)
	var glow := strip.get_surface_override_material(0) as StandardMaterial3D
	if glow != null:
		glow.emission_enabled = true
		glow.emission = STRIP_LIGHT
		glow.emission_energy_multiplier = 1.6
	add_child(strip)
	CollisionPolicy.mark_decorative(strip)
	var light := OmniLight3D.new()
	light.name = "CabinLight"
	light.position = Vector3(0.0, CABIN_CEILING_Y - 1.5, 0.0)
	light.light_color = Color(0.78, 0.9, 1.0)
	light.light_energy = 2.4
	light.omni_range = 46.0
	light.shadow_enabled = false
	add_child(light)


## One instrument station: a slanted console block with a lit screen standing
## behind it, facing the centreline.
func _console(at: Vector3, side: float) -> void:
	var body := StaticBody3D.new()
	body.name = "Console"
	body.collision_layer = 1
	body.position = at
	# Facing inward, across the cabin: the panel and its screen turn toward
	# whoever is standing at it rather than toward the hull behind it.
	body.rotation.y = PI * 0.5 * side
	add_child(body)
	var desk := SuperEgg.build_part(Vector3(2.8, 1.1, 1.0), PANEL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	desk.name = "ConsoleDesk"
	body.add_child(desk)
	CollisionPolicy.add_box(body, desk, Vector3(2.8, 1.1, 1.0) * 2.0)
	var face := SuperEgg.build_part(Vector3(2.4, 0.7, 0.08), TRIM, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	face.name = "ConsoleFace"
	face.position = Vector3(0.0, 0.5, -1.0)
	face.rotation.x = deg_to_rad(28.0)
	body.add_child(face)
	CollisionPolicy.mark_decorative(face)
	var screen := SuperEgg.build_part(Vector3(1.6, 0.9, 0.06), SCREEN, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	screen.name = "ConsoleScreen"
	screen.position = Vector3(0.0, 2.1, -0.4)
	screen.rotation.x = deg_to_rad(12.0)
	var lit := screen.get_surface_override_material(0) as StandardMaterial3D
	if lit != null:
		lit.emission_enabled = true
		lit.emission = SCREEN
		lit.emission_energy_multiplier = 1.4
	body.add_child(screen)
	CollisionPolicy.mark_decorative(screen)


## The pod hangs on the flank directly outside the blorb hatch, turned so its
## own opening faces back through that hatch. Its shell is authored with the
## opening on +X, so a half turn about Y points it at the hull.
## Where the pod's own centre sits against the hull: standing off the real
## surface by enough that its opening's rim reaches the hull, less an inset so
## the two shells overlap. That overlap is what makes the seal seamless, and
## it is the same sphere that cuts the hull's hatch (see _hull_apertures()),
## so the hole is exactly where the pod meets the ship and nowhere else.
func _pod_mount() -> Vector3:
	var half_angle := asin(clampf(EscapePod.POD_DOOR_RADIUS / EscapePod.POD_RADIUS, 0.0, 1.0))
	var standoff := EscapePod.POD_RADIUS * cos(half_angle) - POD_SEAL_INSET
	return Vector3(
		_hull_surface_x(HATCH_CENTER.x) + standoff, HATCH_CENTER.y, HATCH_CENTER.x
	)


func _build_escape_pod() -> void:
	escape_pod = EscapePod.new()
	escape_pod.name = "EscapePod"
	escape_pod.position = _pod_mount()
	escape_pod.rotation.y = PI
	add_child(escape_pod)


## Everything outside the pressure hull: the nose stack, the two strap-on
## boosters down the far flank (clear of the doorway), the aft engine cluster
## and its fins. All solid, so any of it can be landed on from outside.
func _build_stack() -> void:
	_outer_part("NoseCone", Vector3(0.0, 0.0, HULL_HALF_LENGTH + 5.0), Vector3(7.6, 7.6, 9.0), HULL)
	_outer_part("NoseTip", Vector3(0.0, 0.0, HULL_HALF_LENGTH + 15.0), Vector3(2.0, 2.0, 7.0), HULL)
	_outer_part("Collar", Vector3(0.0, 0.0, HULL_HALF_LENGTH - 2.0), Vector3(11.4, 11.4, 2.2), TRIM)
	for side: float in [-1.0, 1.0]:
		var booster_x := -6.0
		var booster_y := side * 12.0
		_outer_part(
			"Booster", Vector3(booster_x, booster_y, -6.0), Vector3(4.6, 4.6, 24.0), HULL
		)
		_outer_part(
			"BoosterNose", Vector3(booster_x, booster_y, 20.0), Vector3(4.0, 4.0, 6.0), HULL
		)
		_outer_part(
			"BoosterBand", Vector3(booster_x, booster_y, 2.0), Vector3(4.8, 4.8, 1.2), TRIM
		)
		_outer_part(
			"BoosterBell", Vector3(booster_x, booster_y, -32.0), Vector3(3.6, 3.6, 3.4), TRIM
		)
	for offset in [Vector2(-4.2, -4.2), Vector2(4.2, -4.2), Vector2(-4.2, 4.2), Vector2(4.2, 4.2)]:
		_outer_part(
			"EngineBell", Vector3(offset.x, offset.y, -HULL_HALF_LENGTH - 3.0),
			Vector3(3.2, 3.2, 4.0), TRIM
		)
	_outer_part("AftSkirt", Vector3(0.0, 0.0, -HULL_HALF_LENGTH + 1.0), Vector3(11.3, 11.3, 3.0), TRIM)
	var brand := Label3D.new()
	brand.name = "Brand"
	brand.text = "ASAN"
	brand.font_size = 96
	brand.modulate = Color(0.24, 0.30, 0.52)
	brand.outline_size = 0
	brand.position = Vector3(-HULL_RADIUS - 0.2, 0.0, 12.0)
	brand.rotation = Vector3(0.0, -PI * 0.5, PI * 0.5)
	brand.pixel_size = 0.03
	add_child(brand)


## One solid piece of the stack: a SuperEgg with a matching box collider, so
## the whole vehicle can be climbed over from outside.
func _outer_part(label: String, at: Vector3, half: Vector3, color: Color) -> MeshInstance3D:
	var body := StaticBody3D.new()
	body.name = "%sBody" % label
	body.collision_layer = 1
	body.position = at
	add_child(body)
	var piece := SuperEgg.build_part(half, color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	piece.name = label
	piece.material_override = _hull_material(color)
	body.add_child(piece)
	CollisionPolicy.add_box(body, piece, half * 2.0)
	return piece


func _hull_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.34
	material.metallic = 0.12
	return material
