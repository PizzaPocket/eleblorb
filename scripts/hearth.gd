class_name Hearth
extends RefCounted

## A masonry hearth set against the centre of a GABLE-END wall (the +X or -X
## wall of a TownProps building, where the roof rises to the ridge). Domestic
## fireplaces never sit mid-way along a long eave wall: the breast and flue
## here rise as one mass against the end wall, through the gable, and clear the
## ridge. The firebox is a real recess (back, two cheeks and a hearth floor)
## with the flame inside it, topped by a mantel and a chimney breast.
##
## Everything is authored in a hearth-local frame (open side toward -Z, back
## wall toward +Z) and placed through one transform, so collision boxes and
## visuals are written together in the building's own space.

## Warm local masonry related to Ohio's wall stone, not the former charcoal
## shaft that read as an unrelated narrow object pasted onto the building.
const STONE := Color(0.68,0.66,0.62)
const OPENING_WIDTH := 1.05
const OPENING_HEIGHT := 1.0
const DEPTH := 0.62
const WALL := 0.14
const BREAST_HEIGHT := 1.9
const FLUE_RADIUS := 0.34
## How far the flue's cap stands clear of the ridge.
const RIDGE_CLEARANCE := 0.8
## Inner face of a log wall plus a hand's breadth of clearance.
const WALL_INSET := 0.46

## Height of the hearthstone: the firebox floor, and the flush apron before it.
const FIRE_FLOOR := 0.14
const APRON_HEIGHT := 0.09
const APRON_DEPTH := 0.95
## How far the stack stands out from the outside of the wall, and how far the
## flue shaft stands out from it, inside and out.
const OUTSIDE_PROJECTION := 0.55
const INTERIOR_FLUE_PROJECTION := 0.5
const EXTERIOR_FLUE_PROJECTION := 0.4
const MORTAR_ROW := 0.21
const IRON := Color(0.17,0.17,0.19)
const LOG_COLOR := Color(0.30,0.19,0.10)
const MANTEL_WOOD := Color(0.30,0.19,0.11)
## A smith's forge burns on a raised hearth table, at working height.
const FORGE_SILL := 0.85
const FORGE_TABLE_DEPTH := 0.95
const COAL := Color(0.07,0.07,0.08)


## `side` is +1.0 (east gable) or -1.0 (west gable). Returns the world-up
## position of the flue top in the building's local space, for chimney smoke.
static func build_on_gable(
	house: StaticBody3D, w: int, d: int, floors: int, side: float,
	z_offset: float, smoke_rng: RandomNumberGenerator, smoke_sink: Array,
	fire_light: bool = true,wall_inset: float = WALL_INSET,
	masonry_color: Color = STONE,external_stack: bool = false,
	fire_schedule: Dictionary = {"mode": "always"}
) -> Vector3:
	if external_stack:
		return build_chimney_wall(
			house, w, d, floors, side, [{"z": z_offset, "width": 1.7, "height": 1.4}], z_offset,
			smoke_rng, smoke_sink, fire_light, masonry_color, -1.0, fire_schedule
		)
	var half_w := float(w) * TownProps.CELL_SIZE * 0.5
	var origin := Vector3(side * (half_w - wall_inset - DEPTH * 0.5), 0.0, z_offset)
	# Hearth-local +Z (the back wall) must point outward at the gable.
	var yaw := PI * 0.5 * side
	var frame := Transform3D(Basis(Vector3.UP, yaw), origin)

	var half_width := OPENING_WIDTH * 0.5 + WALL
	var half_depth := DEPTH * 0.5
	var floor_top := 0.12
	_part(house,frame,Vector3(0.0,0.06,0.0),Vector3(half_width,0.06,half_depth),masonry_color)
	_part(
		house, frame,
		Vector3(0.0, floor_top + OPENING_HEIGHT * 0.5, half_depth - WALL * 0.5),
		Vector3(half_width,OPENING_HEIGHT*0.5,WALL*0.5),masonry_color
	)
	for cheek_side in [-1.0, 1.0]:
		_part(
			house, frame,
			Vector3(cheek_side * (OPENING_WIDTH * 0.5 + WALL * 0.5), floor_top + OPENING_HEIGHT * 0.5, 0.0),
			Vector3(WALL*0.5,OPENING_HEIGHT*0.5,half_depth),masonry_color
		)
	var mantel_thickness := 0.18
	var mantel_y := floor_top + OPENING_HEIGHT + mantel_thickness * 0.5
	_part(
		house, frame, Vector3(0.0, mantel_y, 0.0),
		Vector3(half_width + 0.07, mantel_thickness * 0.5, half_depth + 0.07),
		masonry_color.darkened(0.05),SuperEgg.EPSILON_SOFT
	)
	var breast_y := mantel_y + mantel_thickness * 0.5 + BREAST_HEIGHT * 0.5
	_part(
		house, frame, Vector3(0.0, breast_y, half_depth * 0.15),
		Vector3(half_width * 0.88, BREAST_HEIGHT * 0.5, half_depth * 0.85),
		masonry_color.darkened(0.05)
	)

	var ridge_y := TownProps.roof_top_y(float(floors) * TownProps.FLOOR_HEIGHT, float(d) * TownProps.CELL_SIZE * 0.5, 0.0)
	var shaft_base_y := breast_y + BREAST_HEIGHT * 0.5
	var shaft_top_y := ridge_y + RIDGE_CLEARANCE
	if external_stack:
		# Ohio exposes the OUTSIDE of the same masonry body: one broad, shallow
		# chimney breast bonded into the gable, narrowing only above mantel level.
		# It is deliberately wider than it is deep, like a real fireplace stack,
		# rather than decorative slabs tracing an imaginary flue on the wall.
		var wall_plane_z:=DEPTH*0.5+wall_inset
		# A stack steps in as it rises, with a sloped shoulder (set-off) at each
		# change of width, then finishes in a capped shaft: breast, eave stage,
		# shaft. A bare strip of one width reads as a pole pasted on the wall.
		var lower_top:=minf(2.65,shaft_top_y-0.5)
		var eave_y:=clampf(float(floors)*TownProps.FLOOR_HEIGHT+0.35,lower_top+0.6,shaft_top_y-0.6)
		var breast_half:=half_width+0.14
		_part(
			house,frame,Vector3(0,lower_top*0.5,wall_plane_z+0.22),
			Vector3(breast_half,lower_top*0.5,0.34),masonry_color
		)
		_part(
			house,frame,Vector3(0,lower_top+0.05,wall_plane_z+0.22),
			Vector3(breast_half+0.07,0.06,0.41),masonry_color.lightened(0.05),SuperEgg.EPSILON_SOFT
		)
		var stage_half:=breast_half-0.12
		_part(
			house,frame,Vector3(0,(lower_top+eave_y)*0.5+0.06,wall_plane_z+0.2),
			Vector3(stage_half,(eave_y-lower_top)*0.5,0.30),masonry_color.darkened(0.02)
		)
		_part(
			house,frame,Vector3(0,eave_y+0.04,wall_plane_z+0.2),
			Vector3(stage_half+0.06,0.06,0.36),masonry_color.lightened(0.05),SuperEgg.EPSILON_SOFT
		)
		var shaft_half:=stage_half-0.12
		var outside_upper_height:=maxf(shaft_top_y-eave_y-0.1,0.4)
		_part(
			house,frame,Vector3(0,eave_y+0.1+outside_upper_height*0.5,wall_plane_z+0.18),
			Vector3(shaft_half,outside_upper_height*0.5,0.27),masonry_color.darkened(0.04)
		)
		_part(
			house,frame,Vector3(0,shaft_top_y+0.08,wall_plane_z+0.18),
			Vector3(shaft_half+0.1,0.08,0.34),masonry_color.darkened(0.12),SuperEgg.EPSILON_SOFT
		)
	var shaft_height := maxf(shaft_top_y - shaft_base_y, 0.4)
	_part(
		house, frame, Vector3(0.0, shaft_base_y + shaft_height * 0.5, half_depth * 0.15),
		Vector3(FLUE_RADIUS,shaft_height*0.5,FLUE_RADIUS+0.05),masonry_color
	)
	var cap_y := shaft_base_y + shaft_height + 0.07
	var cap := SuperEgg.build_part(
		Vector3(FLUE_RADIUS*1.4,0.07,FLUE_RADIUS*1.5),masonry_color.darkened(0.1),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	cap.transform = Transform3D(frame.basis, frame * Vector3(0.0, cap_y, half_depth * 0.15))
	house.add_child(cap)
	CollisionPolicy.mark_decorative(cap)

	var fire := HearthFire.create(house, fire_schedule)
	var flame := ParticleFX.build_flame_particles(11, 0.6, 0.85, 1.8, 2.8, -0.6)
	flame.position = frame * Vector3(0.0, floor_top + 0.05, 0.0)
	fire.add_flame(flame)
	CollisionPolicy.mark_decorative(flame)
	if fire_light:
		var light := OmniLight3D.new()
		light.position = frame * Vector3(0.0, floor_top + 0.4, -0.15)
		light.light_color = Color(1.0, 0.42, 0.12)
		light.light_energy = 1.1
		light.omni_range = 8.0
		light.shadow_enabled = false
		fire.add_light(light)

	var smoke_position := frame * Vector3(0.0, cap_y + 0.12, half_depth * 0.15)
	if smoke_rng != null:
		var puffs := ChimneySmoke.spawn(house, smoke_position, smoke_rng, 4)
		smoke_sink.append_array(puffs)
		fire.smoke.append_array(puffs)
	fire.refresh()
	var mouth := frame * Vector3(0.0, 0.0, -half_depth)
	var outward := frame.basis * Vector3(0.0, 0.0, -1.0)
	ClearZones.add(
		house, "hearth", "fire", Vector2(mouth.x, mouth.z), Vector2(outward.x, outward.z),
		0.0, 1.2, OPENING_WIDTH * 0.5 + 0.6, 0.05, 1.6
	)
	return smoke_position


## One chimney built into a gable wall: a single masonry mass, not a hearth set
## in front of a separate stack. Inside, the breast projects from the wall, with
## a large superellipse opening (three sides, clipped by the floor) so the fire
## can use the height of the room; it rises and narrows like a funnel toward the
## stack, where it passes through the wall as the same masonry and continues
## outside as a stepped stack that clears the ridge. A small building gets one
## visible fire mouth and one flue. Larger programmes can still supply several
## openings, but they remain openings in one breast and never widen the shaft
## into something that reads as two chimneys joined together.
##
## `openings` entries: {"z", "width", "height"} in the building frame. The stack
## stands over `stack_z`. Returns the position of the flue top for smoke.
static func build_chimney_wall(
	house: StaticBody3D, w: int, d: int, floors: int, side: float, openings: Array, stack_z: float,
	smoke_rng: RandomNumberGenerator, smoke_sink: Array, fire_light: bool = true,
	masonry_color: Color = STONE, interior_height: float = -1.0, fire_schedule: Dictionary = {}
) -> Vector3:
	var half_w := float(w) * TownProps.CELL_SIZE * 0.5
	var frame := Transform3D(Basis(Vector3.UP, PI * 0.5 * side), Vector3(side * half_w, 0.0, 0.0))
	var wall_half := TownProps.WALL_THICKNESS * 0.5
	var depth := 0.8
	# Frame z runs out through the wall: -z is the room, +z is the open air.
	var face_z := -wall_half - depth
	var outer_z := wall_half + OUTSIDE_PROJECTION
	# Frame x runs along -side * z.
	var x_lo := INF
	var x_hi := -INF
	var tallest := 0.0
	var has_upper := false
	for opening: Dictionary in openings:
		var x_centre := -side * float(opening["z"])
		var reach := float(opening["width"]) * 0.5 + 0.5
		x_lo = minf(x_lo, x_centre - reach)
		x_hi = maxf(x_hi, x_centre + reach)
		tallest = maxf(tallest, _opening_base(opening) + _opening_sill(opening) + float(opening["height"]))
		has_upper = has_upper or int(opening.get("floor", 0)) > 0
	var x_stack := -side * stack_z
	# One compact flue however broad the breast below has to be.
	var stack_half := 0.62 if openings.size() <= 1 else 0.72
	var top := interior_height if interior_height > 0.0 else clampf(float(floors) * TownProps.FLOOR_HEIGHT - 0.35, 2.7, 5.0)
	if has_upper:
		# One stack carries a hearth on each floor: the breast stays full width
		# through both and only funnels in above the upper fire's lintel.
		top = float(floors) * TownProps.FLOOR_HEIGHT - 0.35
	var shoulder := minf(tallest + 0.5, top - 0.4)
	var roof_ridge := TownProps.roof_top_y(float(floors) * TownProps.FLOOR_HEIGHT, float(d) * TownProps.CELL_SIZE * 0.5, 0.0)
	var shaft_top := roof_ridge + RIDGE_CLEARANCE
	var material := SolidModel.material(masonry_color, 0.88, 0.0)
	# The whole chimney is ONE masonry body. The breast is a single extrusion
	# running from the room face right through the wall to the outside face, so
	# the outside shows exactly the silhouette the inside has (the wide breast,
	# its smooth shoulder, the flue). A shaft of the same width as the flue then
	# stands on it and runs up through the roof. Nothing outside is a separate
	# decoration standing in front of the wall: the stack is the fireplace.
	var mass := CSGCombiner3D.new()
	mass.name = "ChimneyBreast"
	mass.transform = frame
	mass.use_collision = true
	mass.collision_layer = 1
	mass.collision_mask = 0
	var outline := PackedVector2Array()
	var curve_start := shoulder * 0.78
	if has_upper:
		curve_start = minf(tallest + 0.3, top - 0.8)
	var curve_steps := 10
	outline.append(Vector2(x_lo, 0.0))
	outline.append(Vector2(x_lo, curve_start))
	for index in curve_steps + 1:
		var t := float(index) / float(curve_steps)
		var eased := t * t * (3.0 - 2.0 * t)
		outline.append(Vector2(lerpf(x_lo, x_stack - stack_half, eased), lerpf(curve_start, top, t)))
	for index in range(curve_steps, -1, -1):
		var t := float(index) / float(curve_steps)
		var eased := t * t * (3.0 - 2.0 * t)
		outline.append(Vector2(lerpf(x_hi, x_stack + stack_half, eased), lerpf(curve_start, top, t)))
	outline.append(Vector2(x_hi, 0.0))
	var breast := CSGPolygon3D.new()
	breast.name = "Breast"
	breast.polygon = outline
	breast.mode = CSGPolygon3D.MODE_DEPTH
	# Extrudes toward -z from its origin, so start at the outside face.
	breast.depth = outer_z - face_z
	breast.position = Vector3(0.0, 0.0, outer_z)
	breast.material = material
	mass.add_child(breast)
	var shaft_z_in := -wall_half - INTERIOR_FLUE_PROJECTION
	var shaft_z_out := wall_half + EXTERIOR_FLUE_PROJECTION
	var shaft_bottom := top - 0.3
	var shaft := CSGBox3D.new()
	shaft.name = "Flue"
	shaft.size = Vector3(stack_half * 2.0, shaft_top - shaft_bottom, shaft_z_out - shaft_z_in)
	shaft.position = Vector3(x_stack, (shaft_top + shaft_bottom) * 0.5, (shaft_z_in + shaft_z_out) * 0.5)
	shaft.material = material
	mass.add_child(shaft)
	var skip_ranges: Array[Vector4] = []
	for opening: Dictionary in openings:
		var open_height := float(opening["height"])
		var half_height := open_height * 0.62
		var recess_front := face_z - 0.1
		var recess_back := -wall_half - 0.14
		var x_open := -side * float(opening["z"])
		var sill := _opening_base(opening) + _opening_sill(opening)
		var cutter := SolidModel.add_profile(
			mass, "Opening", recess_back - recess_front, Vector2(half_height, float(opening["width"]) * 0.5),
			4.0, CSGShape3D.OPERATION_SUBTRACTION, SolidModel.material(masonry_color.darkened(0.45), 0.9, 0.0),
			Vector3(x_open, sill + open_height - half_height, (recess_front + recess_back) * 0.5), 96
		)
		cutter.rotation.y = PI * 0.5
		skip_ranges.append(Vector4(
			x_open - float(opening["width"]) * 0.5 - 0.36, x_open + float(opening["width"]) * 0.5 + 0.36,
			maxf(sill - 0.1, 0.0), sill + open_height + 0.5
		))
	# The firebox has a floor: hearthstone laid across the bottom of every
	# opening, after the cutters, so the fire sits on stone and not on the room.
	for opening: Dictionary in openings:
		var x_open := -side * float(opening["z"])
		var recess_back := -wall_half - 0.14
		var sill := _opening_base(opening) + _opening_sill(opening)
		# The cutter reaches below a raised sill, so the floor fills down to it.
		var drop := 0.0 if sill <= 0.0 else 0.3
		SolidModel.add_box(
			mass, "FireFloor", Vector3(float(opening["width"]) + 0.1, FIRE_FLOOR + drop, recess_back - face_z),
			CSGShape3D.OPERATION_UNION, SolidModel.material(masonry_color.lightened(0.06), 0.9, 0.0),
			Vector3(x_open, sill + (FIRE_FLOOR - drop) * 0.5, (recess_back + face_z) * 0.5)
		)
	house.add_child(mass)
	# Courses of brick or stone laid across both faces of the one breast.
	var mortar := masonry_color.darkened(0.2)
	_courses(house, frame, x_lo, x_hi, curve_start, face_z, -1.0, skip_ranges, mortar)
	var no_skips: Array[Vector4] = []
	_courses(house, frame, x_lo, x_hi, curve_start, outer_z, 1.0, no_skips, mortar)
	# Where the narrower flue steps in from the breast, a ledge on each face.
	var ledge_color := masonry_color.lightened(0.07)
	_part(
		house, frame, Vector3(x_stack, top + 0.05, (face_z + shaft_z_in) * 0.5),
		Vector3(stack_half + 0.07, 0.06, (shaft_z_in - face_z) * 0.5 + 0.06), ledge_color, SuperEgg.EPSILON_SOFT
	)
	_deco(
		house, frame, Vector3(x_stack, top + 0.05, (outer_z + shaft_z_out) * 0.5),
		Vector3(stack_half + 0.07, 0.06, (outer_z - shaft_z_out) * 0.5 + 0.06), ledge_color, SuperEgg.EPSILON_SOFT
	)
	var flue_mid_z := (shaft_z_in + shaft_z_out) * 0.5
	_deco(
		house, frame, Vector3(x_stack, shaft_top + 0.08, flue_mid_z),
		Vector3(stack_half + 0.1, 0.08, (shaft_z_out - shaft_z_in) * 0.5 + 0.08), masonry_color.darkened(0.10), 3.6
	)
	var smoke_position := frame * Vector3(x_stack, shaft_top + 0.3, flue_mid_z)
	var fires: Array[HearthFire] = []
	for opening: Dictionary in openings:
		var schedule: Dictionary = opening.get("fire", fire_schedule)
		var lifted := Transform3D(frame.basis, frame.origin + Vector3(0.0, _opening_base(opening), 0.0))
		if str(opening.get("kind", "hearth")) == "forge":
			fires.append(_dress_forge(house, lifted, side, opening, face_z, wall_half, masonry_color, fire_light, schedule))
		else:
			fires.append(_dress_firebox(house, lifted, side, opening, face_z, wall_half, masonry_color, fire_light, schedule))
	if smoke_rng != null and not fires.is_empty():
		var puffs := ChimneySmoke.spawn(house, smoke_position, smoke_rng, 4)
		smoke_sink.append_array(puffs)
		fires[0].smoke.append_array(puffs)
	for fire in fires:
		fire.refresh()
	return smoke_position


## Everything that makes the opening a fireplace and not a hole: the dressed
## stone surround, a lintel and keystone, an oak mantel on corbels, a hearthstone
## apron with a kerb and a fender, and in the firebox a pair of andirons carrying
## logs on a bed of embers, with a pot on a crane. The fire's lit state follows
## the clock (HearthFire).
static func _dress_firebox(
	house: StaticBody3D, frame: Transform3D, side: float, opening: Dictionary, face_z: float,
	wall_half: float, masonry: Color, fire_light: bool, schedule: Dictionary
) -> HearthFire:
	var width := float(opening["width"])
	var height := float(opening["height"])
	var x_open := -side * float(opening["z"])
	var fire := HearthFire.create(house, schedule)
	var dressed := masonry.lightened(0.14)
	# Hearthstone apron with a kerb along its front edge and slab joints.
	var apron_half := width * 0.5 + 0.45
	_part(
		house, frame, Vector3(x_open, APRON_HEIGHT * 0.5, face_z - APRON_DEPTH * 0.5),
		Vector3(apron_half, APRON_HEIGHT * 0.5, APRON_DEPTH * 0.5), masonry.lightened(0.1), SuperEgg.EPSILON_SOFT
	)
	_deco(
		house, frame, Vector3(x_open, APRON_HEIGHT + 0.012, face_z - APRON_DEPTH + 0.035),
		Vector3(apron_half, 0.014, 0.035), dressed.lightened(0.1), SuperEgg.EPSILON_SOFT
	)
	for slab in 3:
		var slab_x := x_open + (float(slab) - 1.0) * apron_half * 0.62
		_deco(
			house, frame, Vector3(slab_x, APRON_HEIGHT + 0.004, face_z - APRON_DEPTH * 0.5),
			Vector3(0.008, 0.004, APRON_DEPTH * 0.5), masonry.darkened(0.25)
		)
	# A low iron fender across the front of the apron.
	var fender_z := face_z - APRON_DEPTH + 0.12
	_deco(house, frame, Vector3(x_open, APRON_HEIGHT + 0.12, fender_z), Vector3(apron_half - 0.1, 0.012, 0.012), IRON, 2.2)
	for fender_side in [-1.0, 1.0]:
		_deco(house, frame, Vector3(x_open + fender_side * (apron_half - 0.1), APRON_HEIGHT + 0.07, fender_z), Vector3(0.014, 0.07, 0.014), IRON, 2.2)
	# Dressed jamb stones, long and short alternating, up either side.
	var rows := int((height + 0.1) / 0.34)
	for jamb_side in [-1.0, 1.0]:
		for row in rows:
			var long_stone := row % 2 == 0
			var half_x := 0.18 if long_stone else 0.12
			_deco(
				house, frame,
				Vector3(x_open + jamb_side * (width * 0.5 + half_x), FIRE_FLOOR + 0.17 + float(row) * 0.34, face_z - 0.012),
				Vector3(half_x, 0.155, 0.04), dressed if long_stone else dressed.darkened(0.05), SuperEgg.EPSILON_SOFT
			)
	# Lintel across the head of the opening with a keystone.
	_deco(house, frame, Vector3(x_open, height + 0.08, face_z - 0.012), Vector3(width * 0.5 + 0.34, 0.09, 0.04), dressed, SuperEgg.EPSILON_SOFT)
	_deco(house, frame, Vector3(x_open, height + 0.1, face_z - 0.03), Vector3(0.12, 0.13, 0.04), dressed.lightened(0.06), SuperEgg.EPSILON_SOFT)
	# Oak mantel on two stone corbels, with a pair of candlesticks and a jug.
	var mantel_y := height + 0.46
	_deco(house, frame, Vector3(x_open, mantel_y, face_z - 0.17), Vector3(width * 0.5 + 0.62, 0.075, 0.2), MANTEL_WOOD)
	for corbel_side in [-1.0, 1.0]:
		_deco(
			house, frame, Vector3(x_open + corbel_side * (width * 0.5 + 0.44), mantel_y - 0.16, face_z - 0.1),
			Vector3(0.1, 0.12, 0.1), dressed, SuperEgg.EPSILON_SOFT
		)
		_deco(
			house, frame, Vector3(x_open + corbel_side * (width * 0.5 + 0.2), mantel_y + 0.075 + 0.14, face_z - 0.17),
			Vector3(0.025, 0.14, 0.025), Furnishings.PEWTER, 2.2
		)
	_deco(house, frame, Vector3(x_open - 0.12, mantel_y + 0.075 + 0.09, face_z - 0.17), Vector3(0.06, 0.09, 0.06), Furnishings.CLAY, 2.2)
	# In the firebox: andirons, logs, embers, and a pot on a crane.
	var log_half := width * 0.5 * 0.62
	for iron_side in [-1.0, 1.0]:
		var ix: float = x_open + iron_side * width * 0.28
		_deco(house, frame, Vector3(ix, FIRE_FLOOR + 0.17, -0.74), Vector3(0.025, 0.17, 0.025), IRON, 2.2)
		_deco(house, frame, Vector3(ix, FIRE_FLOOR + 0.37, -0.74), Vector3(0.04, 0.04, 0.04), IRON, 2.0)
		_deco(house, frame, Vector3(ix, FIRE_FLOOR + 0.3, -0.53), Vector3(0.02, 0.02, 0.23), IRON)
		_deco(house, frame, Vector3(ix, FIRE_FLOOR + 0.12, -0.31), Vector3(0.02, 0.12, 0.02), IRON, 2.2)
	_deco(house, frame, Vector3(x_open, FIRE_FLOOR + 0.3 + 0.085, -0.62), Vector3(log_half, 0.085, 0.085), LOG_COLOR, 2.2)
	_deco(house, frame, Vector3(x_open, FIRE_FLOOR + 0.3 + 0.085, -0.44), Vector3(log_half * 0.95, 0.085, 0.085), LOG_COLOR.lightened(0.06), 2.2)
	_deco(house, frame, Vector3(x_open, FIRE_FLOOR + 0.3 + 0.255, -0.53), Vector3(log_half * 0.88, 0.08, 0.08), LOG_COLOR.darkened(0.12), 2.2)
	var ember_mesh := _deco(
		house, frame, Vector3(x_open, FIRE_FLOOR + 0.03, -0.5), Vector3(width * 0.34, 0.03, 0.22),
		Color(0.85, 0.3, 0.08), SuperEgg.EPSILON_SOFT
	)
	var ember_material := ember_mesh.get_surface_override_material(0) as StandardMaterial3D
	if ember_material != null:
		ember_material.emission_enabled = true
		ember_material.emission = Color(1.0, 0.34, 0.08)
		ember_material.emission_energy_multiplier = 1.6
		fire.add_ember(ember_material)
	if width >= 1.6 and height >= 1.4:
		var post_x := x_open + width * 0.5 - 0.14
		var arm_y := FIRE_FLOOR + height - 0.28
		_deco(house, frame, Vector3(post_x, FIRE_FLOOR + (height - 0.1) * 0.5, -0.3), Vector3(0.02, (height - 0.1) * 0.5, 0.02), IRON, 2.2)
		_deco(house, frame, Vector3(post_x - 0.4, arm_y, -0.3), Vector3(0.4, 0.015, 0.015), IRON)
		_deco(house, frame, Vector3(post_x - 0.78, arm_y - 0.2, -0.3), Vector3(0.008, 0.2, 0.008), IRON, 2.2)
		_deco(house, frame, Vector3(post_x - 0.78, arm_y - 0.46, -0.3), Vector3(0.17, 0.13, 0.17), IRON, 2.2)
	var flame := ParticleFX.build_flame_particles(11, 0.6, 0.85, 1.8, 2.8, -0.6)
	flame.position = frame * Vector3(x_open, FIRE_FLOOR + 0.5, -0.53)
	fire.add_flame(flame)
	CollisionPolicy.mark_decorative(flame)
	if fire_light:
		var light := OmniLight3D.new()
		light.position = frame * Vector3(x_open, 0.7, face_z - 0.25)
		light.light_color = Color(1.0, 0.42, 0.12)
		light.light_energy = 1.2
		light.omni_range = 9.0
		light.shadow_enabled = false
		fire.add_light(light)
	# Seating stays out of this zone (ClearZones audit): the heat and the sparks.
	var mouth := frame * Vector3(x_open, 0.0, face_z)
	var outward := frame.basis * Vector3(0.0, 0.0, -1.0)
	ClearZones.add(
		house, "hearth", "fire", Vector2(mouth.x, mouth.z), Vector2(outward.x, outward.z),
		0.0, 1.35, width * 0.5 + 0.55, frame.origin.y + 0.05, frame.origin.y + 1.6
	)
	return fire


## A smith's forge in place of a domestic fireplace: the same breast, but the
## fire burns on a raised brick hearth table at working height, in a broad open
## mouth under a hood-beam. A coal bed glows on the hearthstone with a tuyere
## entering at the back from a bellows hung beside the mouth; tongs hang on a
## rail, and a slack tub of water stands on the table. Nothing here is a
## domestic grate: no andirons, no logs, no crane, no mantel ornaments.
static func _dress_forge(
	house: StaticBody3D, frame: Transform3D, side: float, opening: Dictionary, face_z: float,
	wall_half: float, masonry: Color, fire_light: bool, schedule: Dictionary
) -> HearthFire:
	var width := float(opening["width"])
	var height := float(opening["height"])
	var sill := _opening_sill(opening)
	var x_open := -side * float(opening["z"])
	var fire := HearthFire.create(house, schedule)
	var dressed := masonry.lightened(0.1)
	var top := sill + FIRE_FLOOR
	# The hearth table: a solid block of brick, flush with the firebox floor.
	var half_x := width * 0.5 + 0.5
	_part(
		house, frame, Vector3(x_open, top * 0.5, face_z - FORGE_TABLE_DEPTH * 0.5),
		Vector3(half_x, top * 0.5, FORGE_TABLE_DEPTH * 0.5), masonry.darkened(0.04)
	)
	_deco(
		house, frame, Vector3(x_open, top - 0.025, face_z - FORGE_TABLE_DEPTH * 0.5),
		Vector3(half_x + 0.04, 0.03, FORGE_TABLE_DEPTH * 0.5 + 0.03), dressed.lightened(0.04), SuperEgg.EPSILON_SOFT
	)
	var mortar := masonry.darkened(0.22)
	var row := 0.2
	while row < top - 0.08:
		_deco(
			house, frame, Vector3(x_open, row, face_z - FORGE_TABLE_DEPTH - 0.004),
			Vector3(half_x - 0.2, 0.005, 0.006), mortar
		)
		for table_side in [-1.0, 1.0]:
			_deco(
				house, frame, Vector3(x_open + table_side * (half_x + 0.004), row, face_z - FORGE_TABLE_DEPTH * 0.5),
				Vector3(0.006, 0.005, FORGE_TABLE_DEPTH * 0.5 - 0.2), mortar
			)
		row += MORTAR_ROW
	# An iron kerb round the table's front edge.
	_deco(
		house, frame, Vector3(x_open, top + 0.012, face_z - FORGE_TABLE_DEPTH + 0.02),
		Vector3(half_x, 0.014, 0.018), IRON, 2.2
	)
	# The hood-beam over the mouth, and iron straps binding the breast above it.
	_deco(
		house, frame, Vector3(x_open, sill + height + 0.1, face_z - 0.08),
		Vector3(width * 0.5 + 0.36, 0.11, 0.14), MANTEL_WOOD
	)
	for strap_side in [-1.0, 1.0]:
		_deco(
			house, frame, Vector3(x_open + strap_side * (width * 0.5 + 0.18), sill + height + 0.1, face_z - 0.225),
			Vector3(0.025, 0.12, 0.012), IRON, 2.2
		)
	# Dressed jambs: tall courses either side of the mouth.
	var rows := int((height + 0.1) / 0.34)
	for jamb_side in [-1.0, 1.0]:
		for jamb_row in rows:
			var long_stone := jamb_row % 2 == 0
			var jamb_half := 0.18 if long_stone else 0.12
			_deco(
				house, frame,
				Vector3(x_open + jamb_side * (width * 0.5 + jamb_half), top + 0.17 + float(jamb_row) * 0.34, face_z - 0.012),
				Vector3(jamb_half, 0.155, 0.04), dressed if long_stone else dressed.darkened(0.05), SuperEgg.EPSILON_SOFT
			)
	# The coal bed: a dark mound with a glowing heart, and the tuyere pipe.
	_deco(
		house, frame, Vector3(x_open, top + 0.08, -0.55), Vector3(width * 0.34, 0.1, 0.27), COAL, SuperEgg.EPSILON_SOFT
	)
	var ember_mesh := _deco(
		house, frame, Vector3(x_open, top + 0.17, -0.55), Vector3(width * 0.2, 0.035, 0.15),
		Color(0.95, 0.4, 0.1), SuperEgg.EPSILON_SOFT
	)
	var ember_material := ember_mesh.get_surface_override_material(0) as StandardMaterial3D
	if ember_material != null:
		ember_material.emission_enabled = true
		ember_material.emission = Color(1.0, 0.42, 0.1)
		ember_material.emission_energy_multiplier = 2.4
		fire.add_ember(ember_material)
	var recess_back := -wall_half - 0.14
	_deco(house, frame, Vector3(x_open + width * 0.5 - 0.3, top + 0.2, (face_z + recess_back) * 0.5 + 0.1), Vector3(0.25, 0.018, 0.018), IRON, 2.2)
	_deco(house, frame, Vector3(x_open + width * 0.5 - 0.58, top + 0.2, (face_z + recess_back) * 0.5 + 0.1), Vector3(0.03, 0.03, 0.03), IRON, 2.0)
	# A bellows hung on the breast beside the mouth, nozzle toward the fire.
	var bellows_local := Vector3(x_open + width * 0.5 + 0.4, sill + 0.42, face_z - 0.2)
	var toward := frame.basis * Vector3(-1.0, 0.0, 0.0)
	TradeFurnishings.bellows(house, frame * bellows_local, atan2(-toward.x, -toward.z))
	_deco(house, frame, Vector3(x_open + width * 0.5 + 0.1, sill + 0.42, face_z - 0.2), Vector3(0.2, 0.014, 0.014), IRON, 2.2)
	# Tongs and a hammer on a rail on the other side of the mouth.
	var rail_x := x_open - width * 0.5 - 0.4
	_deco(house, frame, Vector3(rail_x, sill + 0.95, face_z - 0.05), Vector3(0.36, 0.012, 0.012), IRON, 2.2)
	for tong in 4:
		var tong_x := rail_x - 0.27 + float(tong) * 0.18
		var tong_half := 0.2 - 0.02 * float(tong % 2)
		_deco(house, frame, Vector3(tong_x, sill + 0.95 - tong_half, face_z - 0.06), Vector3(0.008, tong_half, 0.008), IRON, 2.2)
	# The slack tub: a half-barrel of water on the table, at the near corner.
	var tub_at := Vector3(x_open - width * 0.5 - 0.1, top + 0.11, face_z - 0.6)
	_deco(house, frame, tub_at, Vector3(0.19, 0.11, 0.19), Furnishings.OAK_DARK, 2.2)
	_deco(house, frame, tub_at + Vector3(0.0, 0.1, 0.0), Vector3(0.165, 0.008, 0.165), Color(0.2, 0.28, 0.34), 2.2)
	var flame := ParticleFX.build_flame_particles(11, 0.5, 0.75, 1.6, 2.4, -0.6)
	flame.position = frame * Vector3(x_open, top + 0.25, -0.55)
	fire.add_flame(flame)
	CollisionPolicy.mark_decorative(flame)
	if fire_light:
		var light := OmniLight3D.new()
		light.position = frame * Vector3(x_open, top + 0.5, face_z - 0.3)
		light.light_color = Color(1.0, 0.5, 0.16)
		light.light_energy = 1.8
		light.omni_range = 10.0
		light.shadow_enabled = false
		fire.add_light(light)
	var mouth := frame * Vector3(x_open, 0.0, face_z)
	var outward := frame.basis * Vector3(0.0, 0.0, -1.0)
	ClearZones.add(
		house, "forge", "fire", Vector2(mouth.x, mouth.z), Vector2(outward.x, outward.z),
		0.0, FORGE_TABLE_DEPTH + 0.4, width * 0.5 + 0.55, frame.origin.y + 0.05, frame.origin.y + sill + 1.6
	)
	return fire


## Mortar lines across a face of the breast, one row every MORTAR_ROW, skipping
## any x range given (the firebox and its surround). `face` is the frame z of
## the face and `outward` is -1.0 for the room face, +1.0 for the outside face.
static func _courses(
	house: StaticBody3D, frame: Transform3D, x_lo: float, x_hi: float, y_top: float, face: float,
	outward: float, skip_ranges: Array[Vector4], color: Color
) -> void:
	var y := 0.2
	while y < y_top - 0.05:
		var segments: Array[Vector2] = [Vector2(x_lo + 0.02, x_hi - 0.02)]
		for skip in skip_ranges:
			if y < skip.z or y > skip.w:
				continue
			var next: Array[Vector2] = []
			for segment in segments:
				if skip.y <= segment.x or skip.x >= segment.y:
					next.append(segment)
					continue
				if skip.x > segment.x:
					next.append(Vector2(segment.x, skip.x))
				if skip.y < segment.y:
					next.append(Vector2(skip.y, segment.y))
			segments = next
		for segment in segments:
			_deco(
				house, frame, Vector3((segment.x + segment.y) * 0.5, y, face + outward * 0.005),
				Vector3((segment.y - segment.x) * 0.5, 0.005, 0.008), color
			)
		y += MORTAR_ROW


## Height of the floor a hearth stands on, above the building's origin: 0 for
## the ground floor, the upper deck's surface for `"floor": 1`.
static func _opening_base(opening: Dictionary) -> float:
	return TownProps.FLOOR_HEIGHT + 0.04 if int(opening.get("floor", 0)) > 0 else 0.0


## How far a firebox floor stands above its own floor: a forge is waist high.
static func _opening_sill(opening: Dictionary) -> float:
	return float(opening.get("sill", FORGE_SILL if str(opening.get("kind", "hearth")) == "forge" else 0.0))


## A purely visual piece in the hearth frame (no collision).
static func _deco(
	house: StaticBody3D, frame: Transform3D, local_position: Vector3, half_size: Vector3,
	color: Color = STONE, epsilon: float = SuperEgg.EPSILON_FLAT
) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half_size, color, epsilon, SuperEgg.EPSILON_FLAT)
	mesh.transform = Transform3D(frame.basis, frame * local_position)
	house.add_child(mesh)
	CollisionPolicy.mark_decorative(mesh)
	return mesh


static func _part(
	house: StaticBody3D, frame: Transform3D, local_position: Vector3, half_size: Vector3,
	color: Color = STONE, epsilon: float = SuperEgg.EPSILON_FLAT
) -> void:
	var mesh := SuperEgg.build_part(half_size, color, epsilon, SuperEgg.EPSILON_FLAT)
	var position := frame * local_position
	mesh.transform = Transform3D(frame.basis, position)
	house.add_child(mesh)
	CollisionPolicy.add_box(house, mesh, half_size * 2.0, position, frame.basis, true)
