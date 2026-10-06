class_name DemoSpaceship
extends Node3D

signal cabin_entered

## The ASAN launch vehicle, hanging in space above the volcano (see
## demo_world.gd). Built the way everything in this project is built, out of
## SuperEggs: the main hull is one long hollow superegg shell with real wall
## thickness built as outer solid minus inner solid through SolidModel. Doors,
## windows and the pod hatch are closed negative volumes subtracted from that
## hull; there is no surface-grid stitching. A solid flat deck runs the length
## of the cabin inside it, and that deck, not the curved hull, is what anyone
## walks and platforms on.
##
## Proportions follow a heavy-lift rocket: a long core stage, a hollow forward
## cockpit, two strap-on boosters down the far flank, and a clustered engine
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
const HATCH_CENTER := Vector2(-18.0, DECK_Y + HATCH_RADIUS)
const HATCH_RADIUS := EscapePod.POD_DOOR_RADIUS
## How far the pod's shell is pushed into the hull's. The two overlap by this
## much, which is what closes the seam between them.
const POD_SEAL_INSET := EscapePod.HULL_SEAL_INSET
## Windows down both flanks, at eye height above the deck: each is cut out of
## the hull and then filled by the same cutter intersected with the outer hull
## and stripped of the inner cabin, so every pane is exactly the removed wall
## volume rebuilt in glass.
## One long port a side rather than three small ones, per direct instruction.
## It sits above the consoles, which stand under it.
const WINDOW_STATIONS_ENTRANCE := [13.0]
const WINDOW_STATIONS_OPPOSITE := [-13.0, 13.0]
const WINDOW_Y := 1.5
const WINDOW_HALF := Vector2(7.0, 4.2)
const WINDOW_EXPONENT := 2.6
## Hull left standing between a window and any doorway or hatch, so every
## opening keeps a frame of its own.
const WINDOW_KEEP_CLEAR := 2.5
## How far a window may be slid along the flank, and in what increments, to
## find room beside an opening it would otherwise have met.
const WINDOW_SLIDE := 1.5
const WINDOW_SLIDE_STEPS := 14
const GLASS := Color(0.44, 0.68, 0.86, 0.34)
## Architectural source resolution. Boolean cutters are independent closed
## volumes, so their outlines no longer depend on this grid; these samples
## only control the smoothness of the hull itself.
const HULL_RINGS := 56
const HULL_SEGMENTS := 76
## A hollow forward cockpit overlaps the main hull, with a matched passage
## through both bulkheads and a glazed windshield in its upper nose.
const COCKPIT_CENTER_Z := 43.0
# Bottom-anchored vertical expansion: the original shell ran from -6.1 to
# +1.1. Increasing half-height by 1.2 while raising its centre by the same
# amount preserves that exact -6.1 underside (and therefore the established
# deck, door and console relationships) while lifting only the roof to +3.5.
const COCKPIT_CENTER_Y := -1.3
const COCKPIT_HALF := Vector3(11.0, 4.8, 7.5)
const COCKPIT_WALL := 0.7
const COCKPIT_DOOR_HALF := Vector2(3.0, 2.3)
const COCKPIT_DOOR_EXPONENT := 3.0
## Boolean collision carries a small contact margin. Cutting every layer of
## the passage this far below the deck keeps that margin from becoming a lip
## even though the visible floor and doorway nominally meet at DECK_Y.
const PASSAGE_FLOOR_CLEARANCE := 0.18
# Same bottom-anchored treatment as the cockpit: the sill stays at -3.55,
# while the pane grows upward with the newly taller room. Vector2.x is the
# profile's vertical half-extent here; .y is its horizontal width.
const COCKPIT_WINDSHIELD_CENTER_Y := -1.0
const COCKPIT_WINDSHIELD_HALF := Vector2(2.55, 4.6)
const COCKPIT_WINDSHIELD_EXPONENT := 3.0
## The deck: its height below the hull's axis, how far it reaches either side
## of the centreline, and its thickness.
const DECK_Y := -5.0
const DECK_HALF_WIDTH := 8.5
const DECK_THICKNESS := 0.5
## The door bottom is exactly the common walkable deck plane.
const COCKPIT_DOOR_CENTER_Y := DECK_Y + COCKPIT_DOOR_HALF.y
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
const CABIN_FLOOR := Color(0.86, 0.89, 0.93)
const CABIN_PANEL := Color(0.91, 0.93, 0.96)
const CABIN_CONTROL := Color(0.68, 0.73, 0.81)
const SCREEN := Color(0.52, 0.86, 1.0)
const STRIP_LIGHT := Color(0.66, 0.92, 1.0)

## The escape pod, mounted outside the blorb hatch (see escape_pod.gd).
var escape_pod: EscapePod

var _was_inside := false
var _pilot: Node3D
var _flight_velocity := Vector3.ZERO
var _pilot_anchor: Marker3D
var _main_engine_flames: Array[GPUParticles3D] = []
var _reaction_thrusters: Dictionary = {}
var _thruster_sound_cooldown := 0.0
var _suspended_collision_objects: Array[Dictionary] = []
var _suspended_csg_collisions: Array[CSGShape3D] = []
var _flight_passengers: Array[Node3D] = []
var _cached_pod_surface_x := NAN

const FLIGHT_THRUST := 5.0
const FLIGHT_BOOST_THRUST := 9.0
const FLIGHT_BRAKE := 7.0
const FLIGHT_MAX_SPEED := 42.0
const COCKPIT_CONSOLE_FORWARD_SHIFT := 0.45


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
	var in_main := SuperEgg.contains_point(
		cabin, Vector3(local.x, local.z, -local.y),
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	var cockpit_point := Vector3(
		local.z - COCKPIT_CENTER_Z, local.y - COCKPIT_CENTER_Y, -local.x
	)
	var cockpit_cabin := COCKPIT_HALF - Vector3.ONE * (COCKPIT_WALL - AIR_WALL_GRIP)
	var in_cockpit := SuperEgg.contains_point(
		cockpit_cabin, cockpit_point, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	# The docking neck is a real part of the pressure vessel too. Without this
	# bridge, gravity briefly vanished between the hull and pod volumes while a
	# character was physically inside their shared passage.
	var pod_surface_x := _pod_surface_x()
	var pod_mount_x := _pod_mount().x
	var in_pod_throat := (
		local.x >= pod_surface_x - HULL_WALL
		and local.x <= pod_mount_x
		and Vector2(local.y - HATCH_CENTER.y, local.z - HATCH_CENTER.x).length()
			<= HATCH_RADIUS - 0.08
	)
	# One authoritative rectangular air bridge through the entire overlapped
	# main-hull/cockpit seam. Curved superellipse interiors taper independently;
	# their visual overlap does not mathematically guarantee that a capsule's
	# origin stays inside either volume for every centimetre of the crossing.
	# This throat matches the actual clear doorway and flush threshold deck.
	var passage_half := _cockpit_passage_half()
	var in_cockpit_throat := (
		local.z >= HULL_HALF_LENGTH - 4.5
		and local.z <= COCKPIT_CENTER_Z - COCKPIT_HALF.x + 6.5
		and absf(local.x) <= passage_half.x - 0.08
		and local.y >= DECK_Y - PASSAGE_FLOOR_CLEARANCE - 0.1
		and local.y <= COCKPIT_DOOR_CENTER_Y + passage_half.y - 0.08
	)
	return in_main or in_cockpit or in_pod_throat or in_cockpit_throat


func _process(_delta: float) -> void:
	_thruster_sound_cooldown = maxf(_thruster_sound_cooldown - _delta, 0.0)
	var body := PartyControl.active_control_body()
	var inside := is_instance_valid(body) and contains_breathable_point(body.global_position)
	if inside and not _was_inside:
		cabin_entered.emit()
	_was_inside = inside
	if is_instance_valid(_pilot) and is_instance_valid(_pilot_anchor):
		_pilot.global_transform = _pilot_anchor.global_transform


func _build_ship() -> void:
	_build_hull()
	_build_deck()
	_build_cockpit()
	_build_interior_fittings()
	_build_stack()
	_build_escape_pod()


## The core stage itself: one hollow shell, its doorway cut straight through.
## The shell is authored in the superegg's own frame, whose long axis is Y,
## then turned a quarter turn so the hull lies along Z; the aperture stays on
## +X through that turn (it is the axis the turn is about).
func _build_hull() -> void:
	var shell := CSGCombiner3D.new()
	shell.name = "Hull"
	var apertures := _hull_apertures()
	shell.use_collision = true
	shell.collision_layer = 1
	shell.collision_mask = 1
	shell.rotation.x = PI * 0.5
	var material := _hull_material(HULL)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Boolean cut faces are the cabin walls seen from inside, so keep them in
	# the same bright sterile family as the fittings rather than charcoal grey.
	var cut_material := _hull_material(CABIN_PANEL)
	SolidModel.add_super(
		shell, "OuterHull", _hull_axes(), CSGShape3D.OPERATION_UNION, material,
		Vector3.ZERO, SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
	)
	SolidModel.add_super(
		shell, "CabinNegative", _hull_axes() - Vector3.ONE * HULL_WALL,
		CSGShape3D.OPERATION_SUBTRACTION, cut_material, Vector3.ZERO,
		SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
	)
	# Each aperture is a closed negative volume through only its authored
	# flank. The surrounding hull has no awareness of the cutter's outline.
	for index in apertures.size():
		var aperture: Dictionary = apertures[index]
		var side := float(aperture.get("side", 1.0))
		var centre: Vector2 = aperture["center"]
		var half: Vector2 = aperture["half"]
		# The hull tapers toward both ends. Put the cutter on the actual flank at
		# this station rather than at the amidships radius; the latter only grazed
		# forward windows and entirely missed the pod hatch near the tail.
		var cutter_x := side * (_hull_surface_x(centre.x) - HULL_WALL * 0.45)
		SolidModel.add_profile(
			shell, "ApertureNegative%d" % index, HULL_WALL * 4.0, half,
			float(aperture.get("exponent", 2.0)), CSGShape3D.OPERATION_SUBTRACTION,
			cut_material, Vector3(cutter_x, centre.x, centre.y)
		)
	# Matching doorway through the main hull's forward bulkhead. The cutter's
	# native X extrusion is rotated onto the hull's long local-Y axis.
	var passage_half := _cockpit_passage_half()
	var cockpit_passage := SolidModel.add_profile(
		shell, "CockpitPassageNegative", HULL_WALL * 5.0,
		passage_half, COCKPIT_DOOR_EXPONENT, CSGShape3D.OPERATION_SUBTRACTION,
		cut_material,
		Vector3(0.0, HULL_HALF_LENGTH - HULL_WALL * 0.45, -COCKPIT_DOOR_CENTER_Y)
	)
	cockpit_passage.rotation.z = PI * 0.5
	add_child(shell)
	SolidModel.bake_when_ready(shell, self)
	_glaze_windows(apertures)

## Every opening cut through the hull. The superegg's own Y is the hull's Z
## and its Z is the hull's -Y, so each centre is written in that frame.
func _hull_apertures() -> Array[Dictionary]:
	var apertures: Array[Dictionary] = [
		{
			"center": Vector2(DOOR_CENTER.x, -DOOR_CENTER.y),
			"half": DOOR_HALF, "exponent": DOOR_EXPONENT, "side": 1.0,
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
		var stations := WINDOW_STATIONS_ENTRANCE if side > 0.0 else WINDOW_STATIONS_OPPOSITE
		for station: float in stations:
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
		"side": 1.0,
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
	var glass := SolidModel.material(GLASS, 0.05, 0.2)
	var index := 0
	for aperture in apertures:
		if float(aperture.get("exponent", 0.0)) != WINDOW_EXPONENT:
			continue
		var pane := CSGCombiner3D.new()
		pane.name = "Window%d" % index
		pane.rotation.x = PI * 0.5
		pane.use_collision = true
		pane.collision_layer = 1
		pane.collision_mask = 1
		index += 1
		var side := float(aperture.get("side", 1.0))
		var centre: Vector2 = aperture["center"]
		var cutter_x := side * (_hull_surface_x(centre.x) - HULL_WALL * 0.45)
		SolidModel.add_profile(
			pane, "GlassVolume", HULL_WALL * 4.0, aperture["half"] as Vector2,
			WINDOW_EXPONENT, CSGShape3D.OPERATION_UNION, glass,
			Vector3(cutter_x, centre.x, centre.y)
		)
		SolidModel.add_super(
			pane, "OuterBoundary", _hull_axes(), CSGShape3D.OPERATION_INTERSECTION,
			glass, Vector3.ZERO, SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
		)
		SolidModel.add_super(
			pane, "CabinNegative", _hull_axes() - Vector3.ONE * HULL_WALL,
			CSGShape3D.OPERATION_SUBTRACTION, glass, Vector3.ZERO,
			SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
		)
		add_child(pane)
		SolidModel.bake_when_ready(pane, self)


## Where a console stands against the flank: inside the hull's own wall, far
## enough in that the curve above it clears a standing body.
func _console_flank_offset_at(hull_z: float) -> float:
	# The hull narrows toward both ends, so a fixed offset put a console
	# through the wall at some stations and out through an opening at others.
	return maxf(_deck_half_width_at(hull_z) - CONSOLE_WALL_GAP, 1.0)


func _hull_axes() -> Vector3:
	return Vector3(HULL_RADIUS, HULL_HALF_LENGTH, HULL_RADIUS)


func _cockpit_passage_half() -> Vector2:
	return COCKPIT_DOOR_HALF + Vector2(0.0, PASSAGE_FLOOR_CLEARANCE)


## How far out the floor reaches at `hull_z`: to the hull's own inner surface
## at deck height, so the two meet with nothing between them.
## One quad of the floor, into both the drawn mesh and its collider.
func _deck_quad(
	tool: SurfaceTool,
	a0: Vector3, a1: Vector3, b0: Vector3, b1: Vector3
) -> void:
	for corner in [a0, b0, a1, a1, b0, b1]:
		tool.add_vertex(corner)


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
	var deck_root := Node3D.new()
	deck_root.name = "Deck"
	deck_root.position = Vector3(0.0, DECK_Y - DECK_THICKNESS, 0.0)
	add_child(deck_root)
	var reach := HULL_HALF_LENGTH - 3.0
	var steps := DECK_STATIONS
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in steps:
		var from := -reach + 2.0 * reach * float(index) / float(steps)
		var to := -reach + 2.0 * reach * float(index + 1) / float(steps)
		var from_half := _deck_half_width_at(from)
		var to_half := _deck_half_width_at(to)
		var top := DECK_THICKNESS
		var under := -DECK_THICKNESS
		# The top surface, the underside, and the curved edge joining them.
		_deck_quad(tool,
			Vector3(-from_half, top, from), Vector3(from_half, top, from),
			Vector3(-to_half, top, to), Vector3(to_half, top, to))
		_deck_quad(tool,
			Vector3(from_half, under, from), Vector3(-from_half, under, from),
			Vector3(to_half, under, to), Vector3(-to_half, under, to))
		for side: float in [-1.0, 1.0]:
			_deck_quad(tool,
				Vector3(side * from_half, under, from), Vector3(side * from_half, top, from),
				Vector3(side * to_half, under, to), Vector3(side * to_half, top, to))
	var plate := MeshInstance3D.new()
	plate.name = "DeckPlate"
	tool.generate_normals()
	plate.mesh = tool.commit()
	var panel := StandardMaterial3D.new()
	panel.albedo_color = CABIN_FLOOR
	panel.roughness = 0.6
	# The plate is a closed procedural volume. Godot's clockwise front-face
	# convention can cull the authored top triangles even though their generated
	# normals point upward, leaving only the underside visible one full deck
	# thickness below the collision plane. Both sides are architectural surfaces
	# here; drawing both guarantees the visible top is the walkable top.
	panel.cull_mode = BaseMaterial3D.CULL_DISABLED
	plate.material_override = panel
	deck_root.add_child(plate)
	# Generate physics from this exact rendered mesh. This deliberately avoids
	# maintaining a second face array whose transform or margin can diverge from
	# what the player sees.
	plate.create_trimesh_collision()
	var collision_body: StaticBody3D = null
	for child in plate.get_children():
		if child is StaticBody3D:
			collision_body = child as StaticBody3D
			break
	if collision_body != null:
		collision_body.name = "DeckBody"
		collision_body.collision_layer = 1
		collision_body.collision_mask = 1
		var collision := collision_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if collision != null and collision.shape != null:
			# A ConcavePolygonShape is one-sided by default. The deck's authored
			# upper triangles face opposite Godot Physics' accepted winding, so a
			# body entering from above used to pass through the visible top and
			# land on the underside a full metre lower, leaving the rendered floor
			# around its knees. Keep both faces physical: this is a closed slab
			# approached from inside and outside the spaceship.
			var concave := collision.shape as ConcavePolygonShape3D
			if concave != null:
				concave.backface_collision = true
			# The figure's rendered soles extend a couple of centimetres below its
			# capsule calibration. A small contact skin keeps those soles visually
			# on the deck instead of sunk into it, without moving either authored
			# surface or maintaining a second offset floor collider.
			collision.shape.margin = 0.025
			_assert_deck_surface_alignment(plate, collision)


## Guard the actual contract: the rendered top and generated physics top are
## the same local Y. This is deliberately checked from the resources Godot is
## using, not from duplicated constants in the builder.
func _assert_deck_surface_alignment(
	plate: MeshInstance3D, collision: CollisionShape3D
) -> void:
	if plate.mesh == null or collision.shape == null:
		return
	var visual_bounds := plate.mesh.get_aabb()
	var collision_bounds := collision.shape.get_debug_mesh().get_aabb()
	var visual_top := plate.position.y + visual_bounds.end.y
	var collision_top := collision.position.y + collision_bounds.end.y
	if not is_equal_approx(visual_top, collision_top):
		push_error(
			"Spaceship deck visual/collision mismatch: visible top %.4f, collision top %.4f"
			% [visual_top, collision_top]
		)


func _finish_exact_deck_collision(plate: MeshInstance3D, body_name: String) -> void:
	plate.create_trimesh_collision()
	var collision_body: StaticBody3D = null
	for child in plate.get_children():
		if child is StaticBody3D:
			collision_body = child as StaticBody3D
			break
	if collision_body == null:
		return
	collision_body.name = body_name
	collision_body.collision_layer = 1
	collision_body.collision_mask = 1
	var collision := collision_body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision == null or collision.shape == null:
		return
	var concave := collision.shape as ConcavePolygonShape3D
	if concave != null:
		concave.backface_collision = true
	collision.shape.margin = 0.025
	_assert_deck_surface_alignment(plate, collision)


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
				Vector3(side * _console_flank_offset_at(station), DECK_Y + 0.75, station), side
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
	var desk_half := Vector3(3.2, 0.75, 1.25)
	var desk := SuperEgg.build_part(desk_half, CABIN_PANEL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	desk.name = "ConsoleDesk"
	body.add_child(desk)
	CollisionPolicy.add_box(body, desk, desk_half * 2.0)
	var face := SuperEgg.build_part(Vector3(1.35, 0.07, 0.42), CABIN_CONTROL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	face.name = "ConsoleKeyboard"
	# The keyboard is a shallow panel seated INTO the desktop, directly below
	# and forward of the monitor. It is not a free-standing vertical object.
	face.position = Vector3(0.0, desk_half.y + 0.06, -0.42)
	body.add_child(face)
	CollisionPolicy.mark_decorative(face)
	var screen := SuperEgg.build_part(Vector3(0.85, 0.48, 0.05), SCREEN, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	screen.name = "ConsoleScreen"
	# The monitor grows directly out of the rear console top; it is not a
	# detached panel hovering behind the keyboard.
	screen.position = Vector3(0.0, desk_half.y + 0.52, 0.48)
	# Operator stands toward local -Z; lean the display's top toward them.
	screen.rotation.x = deg_to_rad(10.0)
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
		_pod_surface_x() + standoff, HATCH_CENTER.y, HATCH_CENTER.x
	)


func _build_escape_pod() -> void:
	_build_pod_docking_collar()
	escape_pod = EscapePod.new()
	escape_pod.name = "EscapePod"
	escape_pod.position = _pod_mount()
	escape_pod.rotation.y = PI
	add_child(escape_pod)


## A real hollow neck between the broad hull flank and the pod. Both openings
## share its inner radius, while the outer ring hides their overlapping seams
## and provides a continuous collidable rim rather than two shells merely
## intersecting at a difficult corner.
func _build_pod_docking_collar() -> void:
	var collar := CSGCombiner3D.new()
	collar.name = "PodDockingCollar"
	collar.use_collision = true
	collar.collision_layer = 1
	collar.collision_mask = 1
	var surface_x := _pod_surface_x()
	collar.position = Vector3(surface_x, HATCH_CENTER.y, HATCH_CENTER.x)
	var trim := _hull_material(TRIM)
	var hollow := _hull_material(HULL_SHADOW)
	SolidModel.add_profile(
		collar, "CollarOuter", HULL_WALL + POD_SEAL_INSET + 0.8,
		Vector2(HATCH_RADIUS + 0.38, HATCH_RADIUS + 0.38), 2.0,
		CSGShape3D.OPERATION_UNION, trim,
		Vector3((POD_SEAL_INSET - HULL_WALL) * 0.25, 0.0, 0.0)
	)
	SolidModel.add_profile(
		collar, "PassageNegative", HULL_WALL + POD_SEAL_INSET + 1.2,
		Vector2(HATCH_RADIUS, HATCH_RADIUS), 2.0,
		CSGShape3D.OPERATION_SUBTRACTION, hollow,
		Vector3((POD_SEAL_INSET - HULL_WALL) * 0.25, 0.0, 0.0)
	)
	add_child(collar)
	SolidModel.bake_when_ready(collar, self)


## A hollow forward flight deck, joined to the main cabin by matching Boolean
## openings. Local +X is rotated to ship-forward +Z, so the rear door and
## forward windshield are ordinary one-sided profile cuts on opposite ends.
func _build_cockpit() -> void:
	var shell := CSGCombiner3D.new()
	shell.name = "CockpitShell"
	shell.position = Vector3(0.0, COCKPIT_CENTER_Y, COCKPIT_CENTER_Z)
	shell.rotation.y = -PI * 0.5
	shell.use_collision = true
	shell.collision_layer = 1
	shell.collision_mask = 1
	var hull_material := _hull_material(HULL)
	hull_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var cut_material := _hull_material(CABIN_PANEL)
	SolidModel.add_super(
		shell, "CockpitOuter", COCKPIT_HALF, CSGShape3D.OPERATION_UNION,
		hull_material, Vector3.ZERO, SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
	)
	SolidModel.add_super(
		shell, "CockpitCabinNegative", COCKPIT_HALF - Vector3.ONE * COCKPIT_WALL,
		CSGShape3D.OPERATION_SUBTRACTION, cut_material, Vector3.ZERO,
		SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
	)
	var passage_half := _cockpit_passage_half()
	SolidModel.add_profile(
		shell, "RearDoorNegative", COCKPIT_WALL * 5.0,
		Vector2(passage_half.y, passage_half.x), COCKPIT_DOOR_EXPONENT,
		CSGShape3D.OPERATION_SUBTRACTION, cut_material,
		Vector3(
			-COCKPIT_HALF.x + COCKPIT_WALL * 0.45,
			COCKPIT_DOOR_CENTER_Y - COCKPIT_CENTER_Y, 0.0
		)
	)
	SolidModel.add_profile(
		shell, "WindshieldNegative", COCKPIT_WALL * 5.0,
		COCKPIT_WINDSHIELD_HALF, COCKPIT_WINDSHIELD_EXPONENT,
		CSGShape3D.OPERATION_SUBTRACTION, cut_material,
		Vector3(
			COCKPIT_HALF.x - COCKPIT_WALL * 0.45,
			COCKPIT_WINDSHIELD_CENTER_Y - COCKPIT_CENTER_Y, 0.0
		)
	)
	add_child(shell)
	SolidModel.bake_when_ready(shell, self)
	_build_cockpit_windshield()
	_build_cockpit_transition()
	_build_cockpit_deck()
	_build_cockpit_controls()
	_build_cockpit_lighting()


func _build_cockpit_windshield() -> void:
	var pane := CSGCombiner3D.new()
	pane.name = "CockpitWindshield"
	pane.position = Vector3(0.0, COCKPIT_CENTER_Y, COCKPIT_CENTER_Z)
	pane.rotation.y = -PI * 0.5
	pane.use_collision = true
	pane.collision_layer = 1
	pane.collision_mask = 1
	var glass := SolidModel.material(GLASS, 0.05, 0.2)
	var cutter_at := Vector3(
		COCKPIT_HALF.x - COCKPIT_WALL * 0.45,
		COCKPIT_WINDSHIELD_CENTER_Y - COCKPIT_CENTER_Y, 0.0
	)
	SolidModel.add_profile(
		pane, "WindshieldVolume", COCKPIT_WALL * 5.0,
		COCKPIT_WINDSHIELD_HALF, COCKPIT_WINDSHIELD_EXPONENT,
		CSGShape3D.OPERATION_UNION, glass, cutter_at
	)
	SolidModel.add_super(
		pane, "CockpitOuterBoundary", COCKPIT_HALF,
		CSGShape3D.OPERATION_INTERSECTION, glass, Vector3.ZERO,
		SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
	)
	SolidModel.add_super(
		pane, "CockpitCabinNegative", COCKPIT_HALF - Vector3.ONE * COCKPIT_WALL,
		CSGShape3D.OPERATION_SUBTRACTION, glass, Vector3.ZERO,
		SuperEgg.EPSILON_SOFT, HULL_RINGS, HULL_SEGMENTS
	)
	add_child(pane)
	SolidModel.bake_when_ready(pane, self)


func _build_cockpit_deck() -> void:
	# Same contract as the main deck: the visible closed mesh is the collision
	# source, and its side edge is solved from the INNER cockpit shell at floor
	# height. A rectangular insert cannot poke through the curved hull.
	var deck_root := Node3D.new()
	deck_root.name = "CockpitDeck"
	deck_root.position = Vector3(0.0, DECK_Y - DECK_THICKNESS, 0.0)
	add_child(deck_root)
	var rear_z := COCKPIT_CENTER_Z - 6.0
	var front_z := COCKPIT_CENTER_Z + 6.0
	var steps := 48
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in steps:
		var from := lerpf(rear_z, front_z, float(index) / float(steps))
		var to := lerpf(rear_z, front_z, float(index + 1) / float(steps))
		var from_half := _cockpit_deck_half_width_at(from)
		var to_half := _cockpit_deck_half_width_at(to)
		_deck_quad(tool,
			Vector3(-from_half, DECK_THICKNESS, from), Vector3(from_half, DECK_THICKNESS, from),
			Vector3(-to_half, DECK_THICKNESS, to), Vector3(to_half, DECK_THICKNESS, to))
		_deck_quad(tool,
			Vector3(from_half, -DECK_THICKNESS, from), Vector3(-from_half, -DECK_THICKNESS, from),
			Vector3(to_half, -DECK_THICKNESS, to), Vector3(-to_half, -DECK_THICKNESS, to))
		for side: float in [-1.0, 1.0]:
			_deck_quad(tool,
				Vector3(side * from_half, -DECK_THICKNESS, from), Vector3(side * from_half, DECK_THICKNESS, from),
				Vector3(side * to_half, -DECK_THICKNESS, to), Vector3(side * to_half, DECK_THICKNESS, to))
	var plate := MeshInstance3D.new()
	plate.name = "CockpitDeckPlate"
	tool.generate_normals()
	plate.mesh = tool.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = CABIN_FLOOR
	material.roughness = 0.6
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	plate.material_override = material
	deck_root.add_child(plate)
	_finish_exact_deck_collision(plate, "CockpitDeckBody")


func _cockpit_deck_half_width_at(world_z: float) -> float:
	var axes := COCKPIT_HALF - Vector3.ONE * COCKPIT_WALL
	var along := absf(world_z - COCKPIT_CENTER_Z) / maxf(axes.x, 0.0001)
	var rise := absf(DECK_Y - COCKPIT_CENTER_Y) / maxf(axes.y, 0.0001)
	var spent := pow(along, SuperEgg.EPSILON_SOFT) + pow(rise, SuperEgg.EPSILON_SOFT)
	if spent >= 1.0:
		return 0.0
	return maxf(
		axes.z * pow(1.0 - spent, 1.0 / SuperEgg.EPSILON_SOFT) - 0.03, 0.0
	)


func _build_cockpit_transition() -> void:
	# Both pressure shells overlap for strength. This short hollow collar hides
	# their two exposed cut rims and presents one continuous matched threshold.
	var collar := CSGCombiner3D.new()
	collar.name = "CockpitTransitionCollar"
	collar.position = Vector3(0.0, COCKPIT_DOOR_CENTER_Y, 34.0)
	collar.rotation.y = -PI * 0.5
	# The main and cockpit shells already own the two precisely matched cut
	# rims. A third concave CSG collider here created redundant coplanar edges
	# that caught the character capsule. The collar is seam-hiding trim only;
	# primitive architecture and the one deck below own passage collision.
	collar.use_collision = false
	var wall := SolidModel.material(CABIN_PANEL, 0.58, 0.0)
	var hollow := SolidModel.material(CABIN_CONTROL, 0.7, 0.0)
	var passage_half := _cockpit_passage_half()
	SolidModel.add_profile(
		collar, "TransitionOuter", 3.8,
		Vector2(passage_half.y + 0.22, passage_half.x + 0.22),
		COCKPIT_DOOR_EXPONENT, CSGShape3D.OPERATION_UNION, wall
	)
	SolidModel.add_profile(
		collar, "TransitionPassage", 4.2,
		Vector2(passage_half.y, passage_half.x),
		COCKPIT_DOOR_EXPONENT, CSGShape3D.OPERATION_SUBTRACTION, hollow
	)
	add_child(collar)
	SolidModel.bake_when_ready(collar, self)
	# The bridge shares the common deck top and spans the short curved-shell
	# interval before the cockpit's cross-section reaches doorway width.
	var bridge := StaticBody3D.new()
	bridge.name = "CockpitThresholdDeck"
	bridge.position = Vector3(0.0, DECK_Y - DECK_THICKNESS, 34.5)
	bridge.collision_layer = 1
	bridge.collision_mask = 1
	add_child(bridge)
	# Deliberately overlaps both exact decks while sharing their identical top
	# plane. There is no seam-sized gap and no raised lip to step over.
	var half := Vector3(COCKPIT_DOOR_HALF.x - 0.08, DECK_THICKNESS, 3.5)
	var mesh := MeshInstance3D.new()
	mesh.name = "CockpitThresholdPlate"
	var box := BoxMesh.new()
	box.size = half * 2.0
	box.material = SolidModel.material(CABIN_FLOOR, 0.6, 0.0)
	mesh.mesh = box
	bridge.add_child(mesh)
	CollisionPolicy.add_box(bridge, mesh, half * 2.0)


func _build_cockpit_controls() -> void:
	var body := StaticBody3D.new()
	body.name = "CockpitControlConsole"
	body.collision_layer = 1
	body.collision_mask = 1
	var console_z := COCKPIT_CENTER_Z + 4.0 + COCKPIT_CONSOLE_FORWARD_SHIFT
	body.position = Vector3(0.0, DECK_Y + 0.65, console_z)
	add_child(body)
	var desk_half := Vector3(
		maxf(_cockpit_deck_half_width_at(console_z) - 0.35, 2.2), 0.65, 1.1
	)
	var desk := SuperEgg.build_part(
		desk_half, CABIN_PANEL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	desk.name = "FlightConsole"
	body.add_child(desk)
	CollisionPolicy.add_box(body, desk, desk_half * 2.0)
	for side in [-1.0, 0.0, 1.0]:
		var display := SuperEgg.build_part(
			Vector3(1.15, 0.36, 0.07), SCREEN,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		display.name = "FlightDisplay"
		display.position = Vector3(side * (desk_half.x - 1.1), desk_half.y + 0.40, -0.18)
		# Pilot approaches from aft/local -Z, so the display leans aft.
		display.rotation.x = deg_to_rad(18.0)
		var lit := display.get_surface_override_material(0) as StandardMaterial3D
		if lit != null:
			lit.emission_enabled = true
			lit.emission = SCREEN
			lit.emission_energy_multiplier = 1.4
		body.add_child(display)
		CollisionPolicy.mark_decorative(display)
	_pilot_anchor = Marker3D.new()
	_pilot_anchor.name = "PilotAnchor"
	# Feet stay on the shared cockpit deck immediately aft of the console;
	# the console body origin itself is 0.65 m above that deck.
	_pilot_anchor.position = Vector3(0.0, -0.65, -2.1)
	body.add_child(_pilot_anchor)
	Interactable.attach(
		body, "Pilot spaceship", 4.2, _show_pilot_actions,
		Callable(), Callable(), true
	)


func _show_pilot_actions() -> void:
	if is_instance_valid(_pilot):
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var actions: Array[Dictionary] = [{
		"label": "Pilot spaceship",
		"callback": _start_pilot.bind(player),
	}]
	DialogUI.show_line(
		"Flight controls", "The ship waits in the silence beyond the glass.",
		actions, "Cancel", Callable(), true
	)


func _start_pilot(player: Player) -> void:
	DialogUI.hide_dialog()
	player.begin_controllable_host(self)


func begin_host_control(source: Node3D) -> bool:
	if is_instance_valid(_pilot):
		return false
	_pilot = source
	_flight_velocity = Vector3.ZERO
	_capture_flight_passengers()
	_suspend_architecture_collision()
	_set_all_thrusters_off()
	return true


func end_host_control(_source: Node3D) -> void:
	_flight_velocity = Vector3.ZERO
	_set_all_thrusters_off()
	_pilot = null
	_flight_passengers.clear()
	_restore_architecture_collision()


func host_exit_label() -> String:
	return "Leave the flight controls"


func uses_pitched_movement_input() -> bool:
	return true


func camera_focus_point() -> Vector3:
	return global_position + Vector3.UP * 4.0


func camera_follow_distance() -> float:
	return 58.0


## The ship root is not itself a CollisionObject3D; all of its hull, deck,
## cockpit and fitting collision lives on descendants. The shared camera must
## exclude the complete vehicle, otherwise its spring arm retracts against the
## hull and leaves the view inside the ship instead of behind it.
func camera_collision_exclusions() -> Array[RID]:
	var exclusions: Array[RID] = []
	_collect_camera_collision_rids(self, exclusions)
	return exclusions


func _collect_camera_collision_rids(node: Node, output: Array[RID]) -> void:
	for child in node.get_children():
		if child is CollisionObject3D:
			output.append((child as CollisionObject3D).get_rid())
		_collect_camera_collision_rids(child, output)


## Nobody can walk around the cabin while the whole vessel is the controlled
## body: the pilot is fixed at the console and every occupant is carried as a
## passenger. Suspending the hundreds of architectural collision faces during
## flight prevents Godot from rebuilding their broad-phase placement on every
## tiny ship translation. Visual geometry remains untouched and every layer is
## restored on leaving the controls.
func _suspend_architecture_collision() -> void:
	_suspended_collision_objects.clear()
	_suspended_csg_collisions.clear()
	_collect_and_suspend_collision(self)


func _collect_and_suspend_collision(node: Node) -> void:
	for child in node.get_children():
		if child is CSGShape3D:
			var csg := child as CSGShape3D
			if csg.use_collision:
				_suspended_csg_collisions.append(csg)
				csg.use_collision = false
		if child is CollisionObject3D:
			var object := child as CollisionObject3D
			_suspended_collision_objects.append({
				"object": object,
				"layer": object.collision_layer,
				"mask": object.collision_mask,
			})
			object.collision_layer = 0
			object.collision_mask = 0
		_collect_and_suspend_collision(child)


func _restore_architecture_collision() -> void:
	for state in _suspended_collision_objects:
		var object := state["object"] as CollisionObject3D
		if not is_instance_valid(object):
			continue
		object.collision_layer = int(state["layer"])
		object.collision_mask = int(state["mask"])
	for csg in _suspended_csg_collisions:
		if is_instance_valid(csg):
			csg.use_collision = true
	_suspended_collision_objects.clear()
	_suspended_csg_collisions.clear()


func drive_from_player(direction: Vector3, delta: float, sprinting: bool, _jump_pressed: bool) -> void:
	if not is_instance_valid(_pilot):
		return
	var braking := direction.length_squared() <= 0.0001 and sprinting
	if direction.length_squared() > 0.0001:
		var thrust := FLIGHT_BOOST_THRUST if sprinting else FLIGHT_THRUST
		_flight_velocity += direction.normalized() * thrust * delta
	elif braking:
		# The suit's run-with-neutral-input stabilization convention scales up
		# cleanly to the ship without stealing Back from the exit action.
		_flight_velocity = _flight_velocity.move_toward(Vector3.ZERO, FLIGHT_BRAKE * delta)
	_update_flight_thrusters(direction, braking, sprinting)
	_flight_velocity = _flight_velocity.limit_length(FLIGHT_MAX_SPEED)
	var motion := _flight_velocity * delta
	_carry_cabin_occupants(motion)
	global_position += motion


func _carry_cabin_occupants(motion: Vector3) -> void:
	if motion.length_squared() <= 0.0:
		return
	for body in _flight_passengers:
		if is_instance_valid(body) and body != self:
			body.global_position += motion


func _capture_flight_passengers() -> void:
	_flight_passengers.clear()
	var moved: Dictionary = {}
	for group_name in [&"player", &"party_playable_candidates", &"blorbs", &"party_companions"]:
		for candidate in get_tree().get_nodes_in_group(group_name):
			if not candidate is Node3D or candidate == self:
				continue
			var body := candidate as Node3D
			if moved.has(body.get_instance_id()) or not contains_breathable_point(body.global_position):
				continue
			moved[body.get_instance_id()] = true
			_flight_passengers.append(body)


func _pod_surface_x() -> float:
	if is_nan(_cached_pod_surface_x):
		_cached_pod_surface_x = _hull_surface_x(HATCH_CENTER.x)
	return _cached_pod_surface_x


func _build_cockpit_lighting() -> void:
	var ceiling_y := COCKPIT_CENTER_Y + COCKPIT_HALF.y - COCKPIT_WALL - 0.12
	var strip := SuperEgg.build_part(
		Vector3(2.8, 0.10, 0.34), STRIP_LIGHT,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	strip.name = "CockpitCeilingLight"
	strip.position = Vector3(0.0, ceiling_y, COCKPIT_CENTER_Z + 0.6)
	var material := strip.get_surface_override_material(0) as StandardMaterial3D
	if material != null:
		material.emission_enabled = true
		material.emission = STRIP_LIGHT
		material.emission_energy_multiplier = 2.0
	add_child(strip)
	CollisionPolicy.mark_decorative(strip)
	var light := OmniLight3D.new()
	light.name = "CockpitLight"
	light.position = Vector3(0.0, ceiling_y - 0.65, COCKPIT_CENTER_Z + 0.4)
	light.light_color = Color(0.76, 0.88, 1.0)
	light.light_energy = 3.0
	light.omni_range = 17.0
	light.shadow_enabled = false
	add_child(light)


## Everything outside the pressure hull: the two strap-on boosters down the
## far flank (clear of the doorway), the aft engine cluster and its fins. All
## solid, so any of it can be landed on from outside.
func _build_stack() -> void:
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
	_build_flight_thrusters()
	var brand := Label3D.new()
	brand.name = "Brand"
	brand.text = "ASAN"
	brand.font_size = 96
	brand.modulate = Color(0.24, 0.30, 0.52)
	brand.outline_size = 0
	# Opposite the entrance, centered on the uninterrupted hull panel between
	# the two windows rather than painted across either pane.
	brand.position = Vector3(-_hull_surface_x(0.0) - 0.2, WINDOW_Y, 0.0)
	brand.rotation = Vector3(0.0, -PI * 0.5, PI * 0.5)
	brand.pixel_size = 0.03
	add_child(brand)


## Main acceleration comes from the real aft bells already authored into the
## ship. Their exhaust is the same flame language as a Fire-suit
## flamethrower, enlarged to spacecraft scale. Fine translation is handled by
## cold-gas RCS puffs derived from the Space suit's own softly glowing jets.
func _build_flight_thrusters() -> void:
	var main_nozzles := [
		Vector3(-6.0, -12.0, -35.4), Vector3(-6.0, 12.0, -35.4),
		Vector3(-4.2, -4.2, -HULL_HALF_LENGTH - 7.0),
		Vector3(4.2, -4.2, -HULL_HALF_LENGTH - 7.0),
		Vector3(-4.2, 4.2, -HULL_HALF_LENGTH - 7.0),
		Vector3(4.2, 4.2, -HULL_HALF_LENGTH - 7.0),
	]
	for index in main_nozzles.size():
		var scale_factor := 4.8 if index < 2 else 3.4
		var flame := SuitPowerFX.make_fire_stream(self, "MainEngineFlame%d" % index, scale_factor)
		flame.top_level = false
		flame.position = main_nozzles[index]
		flame.amount = 120 if index < 2 else 84
		flame.lifetime = 0.48
		_main_engine_flames.append(flame)

	# Keys name the acceleration they create; the particle direction is the
	# opposite exhaust vector. Pairs keep the impulse visually balanced around
	# the ship's centre of mass.
	_add_reaction_pair("reverse", [
		Vector3(-5.0, 0.0, HULL_HALF_LENGTH + 6.0),
		Vector3(5.0, 0.0, HULL_HALF_LENGTH + 6.0),
	], Vector3.FORWARD)
	_add_reaction_pair("right", [
		Vector3(-HULL_RADIUS - 0.2, -4.0, 8.0),
		Vector3(-HULL_RADIUS - 0.2, 4.0, -8.0),
	], Vector3.LEFT)
	_add_reaction_pair("left", [
		Vector3(HULL_RADIUS + 0.2, -4.0, 8.0),
		Vector3(HULL_RADIUS + 0.2, 4.0, -8.0),
	], Vector3.RIGHT)
	_add_reaction_pair("up", [
		Vector3(-4.0, -HULL_RADIUS - 0.2, 7.0),
		Vector3(4.0, -HULL_RADIUS - 0.2, -7.0),
	], Vector3.DOWN)
	_add_reaction_pair("down", [
		Vector3(-4.0, HULL_RADIUS + 0.2, 7.0),
		Vector3(4.0, HULL_RADIUS + 0.2, -7.0),
	], Vector3.UP)


func _add_reaction_pair(key: String, positions: Array[Vector3], exhaust: Vector3) -> void:
	var streams: Array[GPUParticles3D] = []
	for index in positions.size():
		var stream := _make_ship_gas_thruster("RCS_%s_%d" % [key, index], exhaust)
		stream.position = positions[index]
		add_child(stream)
		streams.append(stream)
	_reaction_thrusters[key] = streams


func _make_ship_gas_thruster(stream_name: String, exhaust: Vector3) -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = stream_name
	stream.amount = 34
	stream.lifetime = 0.22
	stream.randomness = 0.52
	stream.local_coords = true
	stream.emitting = false
	stream.visibility_aabb = AABB(Vector3(-4, -4, -4), Vector3(8, 8, 8))
	var texture := ParticleFX.build_soft_gradient_texture(16, 2.4)
	var material := ParticleFX.build_billboard_material(texture, Color.WHITE, true, 0.0)
	material.vertex_color_use_as_albedo = true
	var puff := QuadMesh.new()
	puff.size = Vector2(0.34, 0.72)
	puff.material = material
	var process := ParticleProcessMaterial.new()
	process.direction = exhaust.normalized()
	process.spread = 10.0
	process.gravity = Vector3.ZERO
	process.initial_velocity_min = 5.5
	process.initial_velocity_max = 9.5
	process.scale_min = 0.45
	process.scale_max = 0.9
	process.particle_flag_align_y = true
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(0.96, 0.98, 1.0, 0.72)},
		{"offset": 0.42, "color": Color(0.62, 0.72, 1.0, 0.32)},
		{"offset": 1.0, "color": Color(0.35, 0.28, 0.62, 0.0)},
	])
	stream.process_material = process
	stream.draw_pass_1 = puff
	return stream


func _update_flight_thrusters(direction: Vector3, braking: bool, boosted: bool) -> void:
	var desired_acceleration := direction
	if braking and _flight_velocity.length_squared() > 0.0001:
		desired_acceleration = -_flight_velocity.normalized()
	var local_direction := global_transform.basis.inverse() * desired_acceleration
	var main_active := local_direction.z > 0.12
	for flame in _main_engine_flames:
		flame.emitting = main_active
		flame.amount_ratio = 0.46 if braking else (1.0 if boosted else 0.68)
	_set_reaction_active("reverse", local_direction.z < -0.12 or (braking and local_direction.z < -0.12), boosted)
	_set_reaction_active("right", local_direction.x > 0.12, boosted)
	_set_reaction_active("left", local_direction.x < -0.12, boosted)
	_set_reaction_active("up", local_direction.y > 0.12, boosted)
	_set_reaction_active("down", local_direction.y < -0.12, boosted)
	if (main_active or desired_acceleration.length_squared() > 0.0001) and _thruster_sound_cooldown <= 0.0:
		UISounds.play_foley(&"space_thruster", 0.34 if main_active else 0.18, get_instance_id())
		_thruster_sound_cooldown = 0.18 if main_active else 0.28


func _set_reaction_active(key: String, active: bool, boosted: bool) -> void:
	for stream in _reaction_thrusters.get(key, []) as Array:
		var particles := stream as GPUParticles3D
		particles.emitting = active
		particles.amount_ratio = 1.0 if boosted else 0.65


func _set_all_thrusters_off() -> void:
	for flame in _main_engine_flames:
		if is_instance_valid(flame):
			flame.emitting = false
	for streams in _reaction_thrusters.values():
		for stream in streams as Array:
			if is_instance_valid(stream):
				(stream as GPUParticles3D).emitting = false


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
