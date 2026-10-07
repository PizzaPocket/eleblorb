class_name TownProps
extends RefCounted

const WORLD_DOOR_SCRIPT := preload("res://scripts/world_door.gd")

## Procedural building-block library for the town -- built entirely from
## SuperEgg primitives (the same primitive the character rig and the
## clouds use), replacing every borrowed Kenney Fantasy Town Kit GLB asset
## the town used as a prototype, per direct instruction. True round shapes
## (the fountain, mill wheels) use SuperEgg with epsilon=2.0 -- the plain-
## ellipse case (see superegg.gd's own epsilon-direction note: epsilon=2
## is the one exact, genuinely round value, not just "less boxy") -- rather
## than a dedicated lathe, so even the round pieces stay on this project's
## one shared primitive.
##
## Every dimension here is real-world meters, measured directly against
## the player's own ~1.8m scale -- there's no borrowed asset's native
## grid-unit scale to compensate for the way BUILDING_SCALE/LAYOUT_SCALE
## used to in town_generator.gd (both retired along with the GLBs).
##
## Buildings/fountain/stalls/fences/mills all return a StaticBody3D (or a
## Dictionary wrapping one) with every collision shape already baked in as
## a direct child -- town_generator.gd just positions/rotates the whole
## returned root and adds it to the scene, no separate AABB-measuring pass
## needed the way the old GLB-loading code required.

# ---- Palette -----------------------------------------------------------
const WALL_STONE := Color(0.76, 0.74, 0.7)
const WALL_WOOD := Color(0.58, 0.4, 0.24)
const TRIM_WOOD := Color(0.35, 0.22, 0.13)
const OHIO_BRICK := Color(0.52,0.30,0.23)
const FLOOR_COLOR := Color(0.65, 0.5, 0.33)
const ROAD_COLOR := Color(0.62, 0.58, 0.52)
## A vibrant roof per building (cycled by building index -- see
## town_generator.gd's own call site), matching the same "colorful
## palette" the villagers' clothes use, per direct instruction.
const ROOF_COLORS := [
	Color(0.8, 0.22, 0.2),
	Color(0.2, 0.55, 0.34),
	Color(0.22, 0.42, 0.78),
	Color(0.82, 0.58, 0.14),
	Color(0.56, 0.28, 0.62),
	Color(0.16, 0.62, 0.62),
]
const FOUNTAIN_STONE := Color(0.7, 0.68, 0.65)
# Matches a standard water blorb's body: a rich, saturated blue rather than
# a pale transparent overlay that simply inherits the color beneath it.
const WATER_COLOR := Color(0.08, 0.28, 0.55, 0.9)
const LANTERN_GLOW := Color(1.0, 0.8, 0.4)

# ---- Building grid -------------------------------------------------------
const CELL_SIZE := 3.2
const WALL_THICKNESS := 0.16
const FLOOR_HEIGHT := 3.25
const DOOR_WIDTH := 1.2
const DOOR_HEIGHT := 2.4
const INN_DOOR_WIDTH := 2.7
const WINDOW_SIZE := Vector2(0.82, 0.86)
const ROOF_PITCH := deg_to_rad(30.0)
## A roof does not project equally in every direction. The eaves need enough
## throw to shed water clear of the wall; the gable rake only needs to protect
## the end wall and visually finish the verge. ROOF_OVERHANG remains as the
## eave-compatible public alias for older placement helpers.
const ROOF_EAVE_OVERHANG := 0.46
const ROOF_GABLE_OVERHANG := 0.30
const ROOF_OVERHANG := ROOF_EAVE_OVERHANG
## Roof slabs are real thickness (double the first pass), and squarish on their
## free edges so the eave covers the corners of the walls it shelters.
const ROOF_THICKNESS := 0.24
const ROOF_EDGE_EPSILON := 40.0
## Posts are small, so a lower exponent already reads square at the default sampling.
const POST_EPSILON := 12.0
## Sampling for roof slabs, finer than the figure rig's: see SuperEgg.build_clipped_mesh.
const ROOF_SEGMENTS := 72
const ROOF_RINGS := 28
## Collision-only padding on top of ROOF_THICKNESS's own visual thinness --
## per direct instruction, roofs need to be a real landable platform (the
## player can now jump/blorb-bounce high enough to reach one), and a
## paper-thin 0.1m collision plane is a worse target to land on reliably
## than a slightly thicker one. Purely a collision-shape padding; the
## visual panel mesh is untouched.
const ROOF_COLLISION_THICKNESS := 0.3
## Where the roof sits. The roof slab rests exactly on the top of the walls it
## covers: its UNDERSIDE passes through the wall top (y = floor_top) at the wall
## plane and climbs at ROOF_PITCH toward the ridge, so no gap shows under the eave
## and nothing in the wall reaches into the slab. Every piece that meets the roof
## (gable infill, chimneys, posts, hoists, belfries) asks these three functions
## for the surface it meets, never recomputing the slope.
static func roof_vertical_half() -> float:
	return ROOF_THICKNESS * 0.5 / cos(ROOF_PITCH)


## Height of the roof's underside at |z| from the ridge, for a building whose wall
## top is `floor_top_y` and whose walls stand `half_wall_depth` from the ridge line.
static func roof_underside_y(floor_top_y: float, half_wall_depth: float, z_abs: float) -> float:
	return floor_top_y + (half_wall_depth - z_abs) * tan(ROOF_PITCH)


static func roof_center_y(floor_top_y: float, half_wall_depth: float, z_abs: float) -> float:
	return roof_underside_y(floor_top_y, half_wall_depth, z_abs) + roof_vertical_half()


static func roof_top_y(floor_top_y: float, half_wall_depth: float, z_abs: float) -> float:
	return roof_underside_y(floor_top_y, half_wall_depth, z_abs) + 2.0 * roof_vertical_half()


## Same idea as ROOF_COLLISION_THICKNESS -- floor tiles are visually a thin
## 0.08m slab, padded here for a more forgiving landing collider.
const FLOOR_COLLISION_THICKNESS := 0.2


## Builds one whole building (walls, corner posts, floors, gable roof) as a
## single StaticBody3D -- w/d in cells (d is always 2, matching the roof's
## single-ridge gable design), floors >= 1. roof_color lets the caller vary
## it per building for visual variety. Ground floor reads stone, any floor
## above reads wood, matching the kit-era building's two-tone convention.
## The door is always centered on the south wall's ground floor, as an
## actually-open gap (only its jambs/lintel collide, the opening itself
## doesn't) so the player can still walk in.
## wall_style: "panel" (default, a flat painted wall) or "log" (a log-cabin
## stack of horizontal rounded logs occupying the exact same footprint --
## see _build_log_wall_panel()). add_bed places one TownProps bed inside,
## in the back corner farthest from the door, per direct instruction ("since
## we now have the bed object... you can go ahead and put a bed in pretty
## much everyone's home").
static func build_building(
	w: int, d: int, floors: int, roof_color: Color,
	ground_wall_color: Color = WALL_STONE,
	upper_wall_color: Color = WALL_WOOD,
	floor_color: Color = FLOOR_COLOR,
	shutter_color: Color = Color(-1.0, -1.0, -1.0),
	wall_style: String = "panel",
	add_bed: bool = false,
	entry_style: String = "door",
	back_door_x: float = NO_BACK_DOOR,
	shutter_style: String = "all",
	roof_form: Dictionary = {},
	floor_voids: Array = [],
	opening_notes: Array = []
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var door_ix := int(w / 2.0)
	var resolved_shutter_color := shutter_color if shutter_color.r >= 0.0 else roof_color.darkened(0.12)

	for floor_index in floors:
		if floor_index > 0:
			_build_floor_with_ramp_opening(body, w, d, float(floor_index) * FLOOR_HEIGHT, floor_color, floor_voids)
		else:
			_build_floor(body, w, d, 0.0, floor_color)
	if floors > 1:
		_build_interior_ramps(body, w, d, floors)
	if wall_style == "log":
		_build_continuous_log_shell(
			body, w, d, floors, ground_wall_color, upper_wall_color,
			resolved_shutter_color
		)
		_build_roof(body, w, d, float(floors) * FLOOR_HEIGHT, roof_color)
		if add_bed:
			_build_house_bed(body, w, d)
		return body
	if wall_style == "continuous_panel":
		var structural_color:=ground_wall_color if ground_wall_color.get_luminance()<upper_wall_color.get_luminance() else upper_wall_color
		_build_continuous_panel_shell(
			body, w, d, floors, ground_wall_color, upper_wall_color,
			resolved_shutter_color, structural_color, entry_style, back_door_x, shutter_style, opening_notes
		)
		_build_roof(body, w, d, float(floors) * FLOOR_HEIGHT, roof_color, roof_form)
		_build_continuous_gable_infill(
			body,w,d,float(floors)*FLOOR_HEIGHT,upper_wall_color if floors>1 else ground_wall_color,
			float(roof_form.get("half_hip",0.0))
		)
		if add_bed:
			_build_house_bed(body, w, d)
		return body

	var top_wall_color := ground_wall_color if floors <= 1 else upper_wall_color
	for floor_index in floors:
		var y := float(floor_index) * FLOOR_HEIGHT
		var is_ground := floor_index == 0
		var wall_color := ground_wall_color if is_ground else upper_wall_color
		for ix in w:
			for iz in d:
				var on_west := ix == 0
				var on_east := ix == w - 1
				var on_south := iz == 0
				var on_north := iz == d - 1
				if not (on_west or on_east or on_south or on_north):
					continue  # interior cell, no wall
				var is_corner := (on_west or on_east) and (on_south or on_north)
				var cx := (ix - (w - 1) / 2.0) * CELL_SIZE
				var cz := (iz - (d - 1) / 2.0) * CELL_SIZE

				if is_corner:
					var corner_x := -w * CELL_SIZE * 0.5 if on_west else w * CELL_SIZE * 0.5
					var corner_z := -d * CELL_SIZE * 0.5 if on_south else d * CELL_SIZE * 0.5
					_build_corner_post(body, Vector3(corner_x, y, corner_z), wall_color)

				# A corner belongs to two walls. The old early `continue` above
				# skipped both, leaving every 1x1 house entirely open and cutting
				# large holes out of larger houses. Build each boundary face
				# independently; their small overlap hides behind the corner post.
				# yaw is chosen so the wall's own local -Z (where the
				# window inset/door face outward) ends up pointing away
				# from the building's interior for every one of the 4
				# possible walls -- worked out from Godot's actual
				# Y-rotation matrix (x' = cos*x + sin*z, z' = -sin*x +
				# cos*z), not guessed: south (yaw 0) needs no rotation
				# since local -Z is already world -Z (outward on the
				# south/negative-Z edge); north (yaw 180) flips local -Z to
				# world +Z (outward there); west (yaw 90) turns local -Z to
				# world -X (outward on the west/negative-X edge); east
				# (yaw -90) turns it to world +X. Not visually re-verified
				# in-engine.
				if on_west:
					_build_wall_cell(body, Vector3(-w * CELL_SIZE * 0.5, y, cz), deg_to_rad(90.0), wall_color, "window", resolved_shutter_color, wall_style)
				if on_east:
					_build_wall_cell(body, Vector3(w * CELL_SIZE * 0.5, y, cz), deg_to_rad(-90.0), wall_color, "window", resolved_shutter_color, wall_style)
				if on_south:
					var south_opening := "door" if is_ground and ix == door_ix else "window"
					_build_wall_cell(body, Vector3(cx, y, -d * CELL_SIZE * 0.5), 0.0, wall_color, south_opening, resolved_shutter_color, wall_style)
				if on_north:
					_build_wall_cell(body, Vector3(cx, y, d * CELL_SIZE * 0.5), deg_to_rad(180.0), wall_color, "window", resolved_shutter_color, wall_style)

	_build_roof(body, w, d, float(floors) * FLOOR_HEIGHT, roof_color)
	# Per direct correction ("the triangle area above the walls where the
	# triangle roofs come together... there's just no triangle shape to fill
	# it in") -- the gable roof's ridge rises above the flat top of the
	# west/east end walls; this fills that gap.
	_build_gable_infill(body, w, d, float(floors) * FLOOR_HEIGHT, top_wall_color)
	if add_bed:
		_build_house_bed(body, w, d)
	return body


## One triangular wall prism at each gable end. The generic legacy infill is
## intentionally made from stacked rounded bands and therefore reads like
## logs; Ohio's plaster/timber buildings need a single uninterrupted plane.
static func _build_continuous_gable_infill(
	body: StaticBody3D,w: int,d: int,floor_top_y: float,color: Color,hip_side: float = 0.0
) -> void:
	var half_depth:=float(d)*CELL_SIZE*0.5
	# The triangle fills exactly to the underside of the roof (it rests flush on it).
	var peak_y:=roof_underside_y(floor_top_y,half_depth,0.0)
	var material:=StandardMaterial3D.new()
	material.albedo_color=color
	material.roughness=0.86
	for side: float in [-1.0,1.0]:
		var wall_x:float=side*float(w)*CELL_SIZE*0.5
		if hip_side == side:
			# A half-hip end: the gable wall stops at the underside of the hip facet,
			# which at the wall plane is lower than the main ridge (see _build_hipped_roof).
			var hip_pitch:=atan(HIP_HEIGHT/HIP_INSET)
			var hip_x_at_wall:=float(w)*CELL_SIZE*0.5-(float(w)*CELL_SIZE*0.5+ROOF_GABLE_OVERHANG-HIP_INSET)
			var facet_center_y:=roof_center_y(floor_top_y,half_depth,0.0)-hip_x_at_wall*HIP_HEIGHT/HIP_INSET
			var top:=facet_center_y-ROOF_THICKNESS*0.5/cos(hip_pitch)-floor_top_y
			var half_top:=half_depth*(1.0-top/(peak_y-floor_top_y))
			var polygon:Array[Vector2]=[
				Vector2(-half_depth,0.0),Vector2(half_depth,0.0),Vector2(half_top,top),Vector2(-half_top,top)
			]
			RoofForms.prism(
				body,polygon,Vector3(wall_x,floor_top_y,0.0),
				Basis(Vector3(0,0,1),Vector3(0,1,0),Vector3(1,0,0)),WALL_THICKNESS,color,true
			)
			continue
		var x0:float=wall_x-WALL_THICKNESS*0.5
		var x1:float=wall_x+WALL_THICKNESS*0.5
		var points:=PackedVector3Array([
			Vector3(x0,floor_top_y,-half_depth),Vector3(x0,floor_top_y,half_depth),Vector3(x0,peak_y,0),
			Vector3(x1,floor_top_y,-half_depth),Vector3(x1,floor_top_y,half_depth),Vector3(x1,peak_y,0),
		])
		var indices:=PackedInt32Array([
			0,2,1,3,4,5,
			0,3,5,0,5,2,
			1,2,5,1,5,4,
			0,1,4,0,4,3,
		])
		var arrays:=[]
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX]=points
		arrays[Mesh.ARRAY_INDEX]=indices
		var raw:=ArrayMesh.new()
		raw.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		var surface:=SurfaceTool.new()
		surface.create_from(raw,0)
		surface.generate_normals()
		var mesh:=surface.commit()
		mesh.surface_set_material(0,material)
		var visual:=MeshInstance3D.new()
		visual.mesh=mesh
		visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.SOLID)
		body.add_child(visual)
		var shape:=ConvexPolygonShape3D.new()
		shape.points=points
		var collision:=CollisionShape3D.new()
		collision.shape=shape
		collision.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.SOLID)
		body.add_child(collision)


## Broad, continuous wall planes with a deliberately authored opening count.
## This is the ordinary plaster/timber counterpart to the continuous log
## shell: it avoids the old visible grid of capped square wall tiles and the
## implausible one-window-per-cell rhythm.
const NO_BACK_DOOR := -999.0


static func _build_continuous_panel_shell(
	body: StaticBody3D, w: int, d: int, floors: int,
	ground_color: Color, upper_color: Color, trim_color: Color, structural_color: Color,
	entry_style: String = "door",
	back_door_x: float = NO_BACK_DOOR,
	shutter_style: String = "all",
	opening_notes: Array = []
) -> void:
	# Frames, rails and sills are the house's own timber, a shade darker than its
	# wall material, so they read as part of the wall; `trim_color` (the accent)
	# is reserved for the shutters and door leaf.
	var frame_color := structural_color.darkened(0.3)
	var width := float(w) * CELL_SIZE
	var depth := float(d) * CELL_SIZE
	for floor_index in floors:
		var floor_base := float(floor_index) * FLOOR_HEIGHT
		var color := ground_color if floor_index == 0 else upper_color
		var walls := [
			{"wall": "south", "length": width, "origin": Vector3(0, floor_base, -depth * 0.5), "yaw": 0.0},
			{"wall": "north", "length": width, "origin": Vector3(0, floor_base, depth * 0.5), "yaw": PI},
			{"wall": "west", "length": depth, "origin": Vector3(-width * 0.5, floor_base, 0), "yaw": PI * 0.5},
			{"wall": "east", "length": depth, "origin": Vector3(width * 0.5, floor_base, 0), "yaw": -PI * 0.5},
		]
		var corners: Array[Vector2] = [
			Vector2(-width * 0.5, -depth * 0.5), Vector2(width * 0.5, -depth * 0.5),
			Vector2(width * 0.5, depth * 0.5), Vector2(-width * 0.5, depth * 0.5),
		]
		for corner_index in 4:
			ClearZones.add_wall(body, "outside wall", corners[corner_index], corners[(corner_index + 1) % 4], floor_base, FLOOR_HEIGHT, WALL_THICKNESS, true)
		for wall: Dictionary in walls:
			var openings := panel_wall_openings(
				str(wall["wall"]), float(wall["length"]), floor_index, floors, entry_style, back_door_x, shutter_style
			)
			_apply_opening_notes(openings, str(wall["wall"]), floor_index, opening_notes)
			_build_panel_facade(body, float(wall["length"]), wall["origin"], float(wall["yaw"]), color, openings, floor_base)
			for opening in openings:
				_build_panel_opening_trim(body, wall["origin"], float(wall["yaw"]), opening, floor_base, frame_color, WALL_THICKNESS, trim_color)
				_register_exterior_door_zone(body, str(wall["wall"]), opening, width, depth, floor_base)
	# Corner pilasters belong to the wall construction, not the bright accent
	# palette. On a two-tone house the darker wall material quietly ties both
	# storeys together without adding a fourth competing facade color.
	_build_panel_corner_posts(body, w, d, float(floors) * FLOOR_HEIGHT, structural_color)


## A window that a projecting oriel or bay stands in front of keeps no shutters on
## the wall behind it: the shutters belong to the oriel's own front (see
## FacadeFeatures.oriel), where they can fold back against its sides. `notes` are
## {"floor", "x"} for each oriel or bay on the front (south) wall.
static func _apply_opening_notes(openings: Array[Dictionary], wall: String, floor_index: int, notes: Array) -> void:
	if wall != "south":
		return
	for note: Dictionary in notes:
		if int(note["floor"]) != floor_index:
			continue
		for opening in openings:
			if absf(float(opening["center"]) - float(note["x"])) < 0.8 and str(opening["kind"]) in ["window", "wide"]:
				opening["shutters"] = false


## Furniture must leave the floor just inside every outside door and cart bay
## clear. South wall frame x maps straight to the building's x; the north wall
## is turned half way round, so its x is mirrored.
static func _register_exterior_door_zone(
	body: StaticBody3D, wall: String, opening: Dictionary, width: float, depth: float, floor_base: float
) -> void:
	var kind := str(opening["kind"])
	var centre := float(opening["center"])
	var half := float(opening["width"]) * 0.5
	if kind in ["window", "wide"]:
		# A window keeps tall furniture off the wall in front of it, to the
		# width of its shutters. A bed or chest may stand beneath the sill.
		var sill := float(opening["bottom"])
		var window_half := half + 0.25
		match wall:
			"south":
				ClearZones.add(body, "window", "window", Vector2(centre, -depth * 0.5), Vector2(0, 1), 0.05, 0.55, window_half, sill, sill + 1.4)
			"north":
				ClearZones.add(body, "window", "window", Vector2(-centre, depth * 0.5), Vector2(0, -1), 0.05, 0.55, window_half, sill, sill + 1.4)
			"west":
				ClearZones.add(body, "window", "window", Vector2(-width * 0.5, -centre), Vector2(1, 0), 0.05, 0.55, window_half, sill, sill + 1.4)
			"east":
				ClearZones.add(body, "window", "window", Vector2(width * 0.5, centre), Vector2(-1, 0), 0.05, 0.55, window_half, sill, sill + 1.4)
		return
	if kind not in ["door", "bay"] or wall not in ["south", "north"]:
		return
	var wide := half + 0.2
	if wall == "south":
		ClearZones.add(body, "front door", "door", Vector2(centre, -depth * 0.5), Vector2(0, 1), 0.3, 1.3, wide, floor_base + 0.05, floor_base + 1.9)
	else:
		ClearZones.add(body, "back door", "door", Vector2(-centre, depth * 0.5), Vector2(0, -1), 0.3, 1.3, wide, floor_base + 0.05, floor_base + 1.9)


## Where light and entry go, wall by wall. Windows serve rooms rather than
## fill facades: the front gets the entry plus a large window onto the main
## room, the rear a small window or two for the kitchen and stores, the west
## gable (where there is no ramp) and upper floors single small lights, and the
## east gable none except an inn's, which flanks its hearth stack with windows.
static func panel_wall_openings(
	wall: String, length: float, floor_index: int, floors: int,
	entry_style: String, back_door_x: float = NO_BACK_DOOR, shutter_style: String = "all"
) -> Array[Dictionary]:
	var base := float(floor_index) * FLOOR_HEIGHT
	var ground := floor_index == 0
	var openings: Array[Dictionary] = []
	if entry_style == "shed":
		# A store, shed or granary has a door and nothing else: no glazed windows
		# for a thief or the weather, ventilation is in the boards.
		if wall == "south" and ground:
			openings.append_array(_entry_openings(length, base, "door"))
		return openings
	match wall:
		"south":
			if ground:
				openings.append_array(_entry_openings(length, base, entry_style))
				match entry_style:
					"door":
						if length >= 9.0:
							_add_window_if_fits(openings, base, -length * 0.3, "wide")
					"civic":
						_add_window_if_fits(openings, base, -length * 0.28, "wide")
						_add_window_if_fits(openings, base, length * 0.28, "wide")
					"inn":
						# One generous public-room window to either side of the broad
						# entrance.  The former pair of windows on each side put their
						# shutters into one another and bore no relation to the rooms.
						for center in [-5.4, 5.4]:
							openings.append({
								"kind":"wide", "center":center, "width":3.0,
								"bottom":base+0.92, "top":base+2.55, "leaves":0,
							})
			else:
				_add_even_windows(openings, base, length, maxi(1, roundi(length / 4.8)))
		"north":
			if ground and back_door_x != NO_BACK_DOOR:
				# The north wall runs the other way round (yaw PI), so the door's
				# building-frame x becomes -x in the wall's own frame.
				openings.append({
					"kind": "door", "center": -back_door_x, "width": DOOR_WIDTH,
					"bottom": base, "top": base + DOOR_HEIGHT, "leaves": 1,
				})
			_add_even_windows(openings, base, length, maxi(1, roundi(length / 6.5)))
		"west":
			if floor_index > 0 or floors == 1:
				_add_window_if_fits(openings, base, 0.0, "window")
		"east":
			# The inn's hearth wall is the village's face to the road: a window
			# either side of the stack on each floor, in the rooms behind them.
			if entry_style == "inn":
				# The chimney stands on the wall's centre line, so a window on
				# each side of it, equally far out and each inside its own room.
				_add_window_if_fits(openings, base, -length * 0.36, "window")
				_add_window_if_fits(openings, base, length * 0.36, "window")
		_:
			pass
	_apply_shutter_policy(openings, floor_index, shutter_style)
	return openings


## Shutters belong to dwellings: privacy, weather and security for rooms people
## sleep and sit in. "all": every window; "upper": only the storeys above the
## ground floor (a workshop below, a home above); "none": halls, workshops,
## mills and outbuildings, whose windows work and are never closed up.
static func _apply_shutter_policy(openings: Array[Dictionary], floor_index: int, shutter_style: String) -> void:
	for opening in openings:
		var kind := str(opening["kind"])
		# Shutters belong on narrow casements only. A wide window has mullions, a
		# hood mould and a window box instead; giant shutters read as absurd.
		if kind != "window":
			continue
		match shutter_style:
			"all":
				opening["shutters"] = true
			"upper":
				opening["shutters"] = floor_index > 0
			_:
				opening["shutters"] = false


## Kept for callers that only want the front.
static func panel_south_openings(width: float, floor_index: int, entry_style: String) -> Array[Dictionary]:
	return panel_wall_openings("south", width, floor_index, 1, entry_style)


static func _entry_openings(width: float, base: float, entry_style: String) -> Array[Dictionary]:
	var openings: Array[Dictionary] = []
	match entry_style:
		"inn":
			# A public inn needs a true arrival opening, wide enough for travellers,
			# mounts and luggage to pass beneath the porch without a bottleneck.
			openings.append({"kind":"door","center":0.0,"width":INN_DOOR_WIDTH,"bottom":base,"top":base+2.85,"leaves":2})
		"civic":
			openings.append({"kind": "door", "center": 0.0, "width": 2.0, "bottom": base, "top": base + 2.7, "leaves": 2})
		"forge":
			openings.append({"kind": "door", "center": -width * 0.22, "width": DOOR_WIDTH, "bottom": base, "top": base + DOOR_HEIGHT, "leaves": 1})
			openings.append({"kind": "bay", "center": width * 0.22, "width": 2.6, "bottom": base, "top": base + 2.6, "leaves": 0})
		"cart":
			# The work-yard facade has one unmistakable cart bay. The ordinary
			# personnel door belongs on the opposite, lane-facing wall.
			openings.append({"kind":"bay","center":0.0,"width":3.2,"bottom":base,"top":base+3.0,"leaves":2})
		"bakery":
			openings.append({"kind": "door", "center": -width * 0.2, "width": DOOR_WIDTH, "bottom": base, "top": base + DOOR_HEIGHT, "leaves": 1})
			openings.append({"kind": "hatch", "center": width * 0.2, "width": 1.5, "bottom": base + 0.95, "top": base + 2.15, "leaves": 0})
		_:
			openings.append({"kind": "door", "center": 0.0, "width": DOOR_WIDTH, "bottom": base, "top": base + DOOR_HEIGHT, "leaves": 1})
	return openings


static func _window_opening(base: float, center: float, kind: String) -> Dictionary:
	if kind == "wide":
		return {"kind": "wide", "center": center, "width": 1.7, "bottom": base + 1.08, "top": base + 2.38, "leaves": 0}
	return {"kind": "window", "center": center, "width": 0.94, "bottom": base + 1.02, "top": base + 2.42, "leaves": 0}


static func _add_window_if_fits(openings: Array[Dictionary], base: float, center: float, kind: String) -> void:
	var candidate := _window_opening(base, center, kind)
	var half := float(candidate["width"]) * 0.5
	for opening in openings:
		if absf(center - float(opening["center"])) < float(opening["width"]) * 0.5 + half + 0.6:
			return
	openings.append(candidate)


static func _add_even_windows(openings: Array[Dictionary], base: float, length: float, count: int) -> void:
	for index in count:
		var center := -length * 0.5 + (float(index) + 0.5) * length / float(count)
		_add_window_if_fits(openings, base, center, "window")


static func _build_panel_facade(
	body: StaticBody3D,length: float,origin: Vector3,yaw: float,color: Color,
	openings: Array[Dictionary],floor_base: float,
	height: float = FLOOR_HEIGHT,thickness: float = WALL_THICKNESS,
	slope_cuts: Array = []
) -> void:
	# This is deliberately the proven spaceship construction: one closed
	# positive solid and closed, extruded superellipse negatives.  It yields a
	# true cut rim without deforming or assembling strips around the opening.
	var facade := CSGCombiner3D.new()
	facade.name = "PunchedFacade"
	facade.position = origin
	facade.rotation.y = yaw
	facade.use_collision = true
	facade.collision_layer = 1
	facade.collision_mask = 0
	var wall_material := SolidModel.material(color,0.86,0.0)
	var cut_material := SolidModel.material(color.darkened(0.055),0.86,0.0)
	SolidModel.add_box(
		facade,"Wall",Vector3(length,height,thickness),
		CSGShape3D.OPERATION_UNION,wall_material,
		Vector3(0,height*0.5,0)
	)
	for index in openings.size():
		var opening: Dictionary = openings[index]
		var kind := str(opening["kind"])
		var opening_half_width := float(opening["width"]) * 0.5
		var top := float(opening["top"]) - floor_base
		var bottom := float(opening["bottom"]) - floor_base
		var half_height := (top - bottom) * 0.5
		var center_y := (top + bottom) * 0.5
		if kind == "door" or kind == "bay":
			# Superellipse head, square foot: the cutter is the full ellipse
			# with its lower half carried below the wall base.
			half_height = (top - bottom + DOOR_CUT_EXTENSION) * 0.5
			center_y = top - half_height
		var cutter := SolidModel.add_profile(
			facade,"OpeningNegative%d"%index,thickness*4.0,
			Vector2(half_height,opening_half_width),OPENING_EXPONENT,
			CSGShape3D.OPERATION_SUBTRACTION,cut_material,
			Vector3(float(opening["center"]),center_y,0),96
		)
		# SolidModel profiles extrude on X; the facade depth is local Z.
		cutter.rotation.y = PI*0.5
	# A partition under a pitched roof follows the rafters: each cut removes the
	# wall above a roof plane, given in wall-local x/y as y = a + b * x.
	for cut_index in slope_cuts.size():
		var cut: Dictionary = slope_cuts[cut_index]
		var angle := atan(float(cut["b"]))
		var cutter_box := SolidModel.add_box(
			facade,"RoofCut%d"%cut_index,Vector3(length*2.0+6.0,6.0,thickness*4.0),
			CSGShape3D.OPERATION_SUBTRACTION,wall_material,
			Vector3(0.0,float(cut["a"]),0.0)+Vector3(-sin(angle),cos(angle),0.0)*3.0
		)
		cutter_box.rotation.z = angle
	body.add_child(facade)


## The flat slabs meet in hard butt joints. A square-edged post at each
## corner hides the seam: it sinks into the ground and runs up until it meets
## the roof slab.
static func _build_panel_corner_posts(
	body: StaticBody3D, w: int, d: int, floor_top_y: float, color: Color
) -> void:
	# SuperEgg posts on the squarish end of the range. A post's top is level, so it
	# stops at the LOWEST point where it meets the roof: the roof's underside over
	# the post's outer edge, which falls away from the ridge. The highest point of
	# the post therefore never exceeds the lowest point of the roof above it.
	const HALF := 0.18
	const SINK := 0.35
	var half_wall_d := float(d) * CELL_SIZE * 0.5
	var top_y := roof_underside_y(floor_top_y, half_wall_d, half_wall_d + HALF)
	var half_size := Vector3(HALF, (top_y + SINK) * 0.5, HALF)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var pos := Vector3(
				sx * (float(w) * CELL_SIZE * 0.5), (top_y - SINK) * 0.5, sz * half_wall_d
			)
			var post := SuperEgg.build_part(half_size, color, POST_EPSILON, POST_EPSILON)
			post.position = pos
			body.add_child(post)
			CollisionPolicy.add_box(body, post, half_size * 2.0, pos, Basis(), true)


## A full-height interior wall between two plan points (building-local XZ),
## punched with real doorways: superellipse-headed openings with piped frames on
## both faces and a hung leaf, exactly like exterior doors. `door_distances` are
## metres along the wall from `from`. Interior walls never stop short of the
## ceiling and never have a bare gap standing in for a door.
static func build_interior_wall(
	body: StaticBody3D, from: Vector2, to: Vector2, base_y: float, door_distances: Array[float],
	color: Color, trim_color: Color = TRIM_WOOD, height: float = FLOOR_HEIGHT, cap_ends: bool = true,
	archways: Array[float] = [], roof: Dictionary = {}, door_options: Array[Dictionary] = []
) -> void:
	var delta := to - from
	var length := delta.length()
	if length < 0.3:
		return
	var middle := (from + to) * 0.5
	# Local +X along the wall; Godot's Y rotation maps +X to (cos, 0, -sin).
	var yaw := atan2(-delta.y, delta.x)
	var origin := Vector3(middle.x, base_y, middle.y)
	var openings: Array[Dictionary] = []
	for door_index in door_distances.size():
		var distance: float = door_distances[door_index]
		var opening := {
			"kind": "door", "center": distance - length * 0.5, "width": INTERIOR_DOOR_WIDTH,
			"bottom": base_y, "top": base_y + INTERIOR_DOOR_HEIGHT, "leaves": 1, "interior": true,
		}
		if door_index < door_options.size():
			opening.merge(door_options[door_index], true)
		openings.append(opening)
	# Open archways: a framed superellipse opening with no leaf, for a passage
	# between spaces that share a use (a vestibule and the room it serves).
	for distance in archways:
		openings.append({
			"kind": "door", "center": distance - length * 0.5, "width": ARCHWAY_WIDTH,
			"bottom": base_y, "top": base_y + ARCHWAY_HEIGHT, "leaves": 0, "interior": true,
		})
	ClearZones.add_wall(body, "interior wall (%.1f, %.1f) to (%.1f, %.1f)" % [from.x, from.y, to.x, to.y], from, to, base_y, height, WALL_THICKNESS)
	var wall_direction := delta / length
	var wall_normal := Vector2(-wall_direction.y, wall_direction.x)
	for opening in openings:
		var door_centre := from + wall_direction * (float(opening["center"]) + length * 0.5)
		ClearZones.add(
			body, "interior door at (%.1f, %.1f)" % [door_centre.x, door_centre.y], "door", door_centre, wall_normal,
			1.25, 1.25, float(opening["width"]) * 0.5 + 0.15, base_y + 0.05, base_y + 1.9
		)
	var slope_cuts: Array = []
	if not roof.is_empty():
		# Under a pitched roof a partition runs up to the rafters: a wall along the
		# ridge rises to the roof's underside at its own distance from the ridge; a
		# cross wall is gable-shaped, following both slopes.
		var rise := tan(ROOF_PITCH)
		var floor_top: float = roof["floor_top"]
		# `run` is the half depth to the eave end (wall plus overhang); the roof's
		# underside is flush with the wall top at the wall plane, so measure from there.
		var run: float = float(roof["run"]) - ROOF_EAVE_OVERHANG
		var peak := floor_top + run * rise - 0.04
		if absf(delta.y) < 0.01:
			height = floor_top + (run - absf(from.y)) * rise - 0.04 - base_y
		else:
			var along := signf(delta.y)
			height = peak - base_y
			slope_cuts = [
				{"a": peak + middle.y * rise - base_y, "b": along * rise},
				{"a": peak - middle.y * rise - base_y, "b": -along * rise},
			]
	_build_panel_facade(body, length, origin, yaw, color, openings, base_y, height, WALL_THICKNESS, slope_cuts)
	for opening in openings:
		_build_panel_opening_trim(body, origin, yaw, opening, base_y, trim_color, WALL_THICKNESS)
	if cap_ends:
		# A slab wall that simply stops, or meets another at a T, shows a bare cut
		# edge. A small square-edged post at each end hides it, as the corner posts
		# do on the outside; where the end meets a wall it reads as a pilaster.
		for end in [from, to]:
			# Under a pitched roof the post stops at the rafters at its own z.
			var post_height := height
			if not roof.is_empty():
				var rafter_y: float = float(roof["floor_top"]) + (float(roof["run"]) - ROOF_EAVE_OVERHANG - absf(end.y)) * tan(ROOF_PITCH) - 0.04
				post_height = minf(height, rafter_y - base_y)
			var post := SuperEgg.build_part(
				Vector3(WALL_END_POST_HALF, post_height * 0.5, WALL_END_POST_HALF), trim_color,
				SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			post.position = Vector3(end.x, base_y + post_height * 0.5, end.y)
			body.add_child(post)
			_add_box_collision(body, post.position, Vector3(WALL_END_POST_HALF * 2.0, post_height, WALL_END_POST_HALF * 2.0))


const WALL_END_POST_HALF := 0.1
const ARCHWAY_WIDTH := 1.7
const ARCHWAY_HEIGHT := 2.6
const INTERIOR_DOOR_WIDTH := 1.0
const INTERIOR_DOOR_HEIGHT := 2.3


const OPENING_EXPONENT := 4.0
const DOOR_CUT_EXTENSION := 0.7
const FRAME_PIPE := 0.045
## Frame pipes, doors and windows alike, are a little slimmer than before
## (doors were 1.2 x FRAME_PIPE, windows 1.0 x), so they read as a subtle edge.
const PIPE_SCALE := 0.9
const SHUTTER_DEPTH := 0.035


## Trim for one punched opening, built into the wall's own thickness so it
## reads from both sides: a piped superellipse frame on each face, rails
## embedded across the glass, and, outside, a sill and shutters (windows) or a
## swung leaf and threshold (doors).
static func _build_panel_opening_trim(
	body: StaticBody3D, origin: Vector3, yaw: float, opening: Dictionary,
	floor_base: float, trim_color: Color, thickness: float = WALL_THICKNESS,
	accent_color: Color = Color(-1.0, -1.0, -1.0)
) -> void:
	# `trim_color` is the local timber the frames, rails and sills are made of, so
	# they melt into the house; `accent_color` (default the same) is the one
	# painted element of the opening, the door leaf and the shutters.
	var accent := accent_color if accent_color.r >= 0.0 else trim_color
	var pivot := Node3D.new()
	pivot.position = origin
	pivot.rotation.y = yaw
	body.add_child(pivot)
	var kind := str(opening["kind"])
	var cx := float(opening["center"])
	var half_w := float(opening["width"]) * 0.5
	var top := float(opening["top"]) - floor_base
	var bottom := float(opening["bottom"]) - floor_base
	var height := top - bottom
	var mid := (top + bottom) * 0.5
	var half_t := thickness * 0.5
	var opening_exponent := float(opening.get("exponent", OPENING_EXPONENT))
	# Outward (-Z) face looks along the pivot's -Z, so its mesh turns by PI.
	var outer_z := -half_t
	var inner_z := half_t

	if kind == "door" or kind == "bay":
		# The frame's jamb ends sink below the sill so they bury. An interior doorway
		# always stands on a slab (0.12 m thick below the floor line on an upper
		# floor), so its frame sinks only 0.04 m; a 0.2 m sink plus the pipe's own
		# radius came out through the ceiling of the room below (the "pipes poking
		# down" the user found in the Holt Inn). An exterior doorway stands on
		# terrain that can fall away from the sill, so it keeps the longer sink.
		var frame_sink := 0.04 if bool(opening.get("interior", false)) else 0.2
		var arch := OpeningTrim.door_arch(half_w, height, opening_exponent, DOOR_CUT_EXTENSION, frame_sink)
		var inside := Vector2(0.0, height * 0.5)
		# The reveal between the two frames takes the frame's colour, and the pipes
		# are slim, so the trim reads as one quiet edge rather than two bright
		# pipes either side of a differently coloured wall.
		var liner := OpeningTrim.reveal_liner(arch, half_t, trim_color, inside)
		liner.name = "DoorReveal"
		liner.position = Vector3(cx, bottom, 0.0)
		pivot.add_child(liner)
		for face in 2:
			var frame := OpeningTrim.piped_frame(arch, FRAME_PIPE * PIPE_SCALE, trim_color, false, inside)
			frame.name = "DoorFrame"
			frame.position = Vector3(cx, bottom, outer_z if face == 0 else inner_z)
			frame.rotation.y = PI if face == 0 else 0.0
			pivot.add_child(frame)
		_build_door_leaves(pivot, cx, bottom, half_w, height, int(opening["leaves"]), accent, opening)
		# A single stone threshold step outside (exterior doors only).
		if bool(opening.get("interior", false)):
			return
		var step := SuperEgg.build_part(Vector3(half_w + 0.12, 0.04, 0.2), WALL_STONE.darkened(0.12), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		step.position = Vector3(cx, bottom + 0.04, outer_z - 0.2)
		pivot.add_child(step)
		CollisionPolicy.mark_decorative(step)
		return

	# Window or service hatch: glazing exactly fills the cut.
	var half_h := height * 0.5
	var loop := OpeningTrim.window_loop(half_w, half_h, opening_exponent)
	if kind == "window" or kind == "wide":
		var pane := MeshInstance3D.new()
		pane.mesh = SolidModel.extruded_profile_mesh(0.03, Vector2(half_h - 0.004, half_w - 0.004), opening_exponent, 96)
		pane.material_override = SolidModel.material(Color(0.38, 0.63, 0.75, 0.42), 0.12, 0.0)
		pane.position = Vector3(cx, mid, 0.0)
		pane.rotation.y = PI * 0.5
		pivot.add_child(pane)
		CollisionPolicy.mark_decorative(pane)
		# Rails run past the glass and bury their ends in the wall.
		var rail_color := trim_color
		var upright_xs: Array[float] = []
		if kind == "window":
			upright_xs.append(0.0)
		else:
			upright_xs.append(-half_w / 3.0)
			upright_xs.append(half_w / 3.0)
		for upright_x in upright_xs:
			var upright := SuperEgg.build_part(Vector3(0.016, half_h + 0.05, 0.022), rail_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			upright.position = Vector3(cx + upright_x, mid, 0.0)
			pivot.add_child(upright)
			CollisionPolicy.mark_decorative(upright)
		var crossbar := SuperEgg.build_part(Vector3(half_w + 0.05, 0.016, 0.022), rail_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		crossbar.position = Vector3(cx, mid + 0.1, 0.0)
		pivot.add_child(crossbar)
		CollisionPolicy.mark_decorative(crossbar)
	# As with doorways, the reveal between the two frames takes the frame colour.
	var liner := OpeningTrim.reveal_liner(loop, half_t, trim_color, Vector2.ZERO, 0.995, true)
	liner.name = "WindowReveal"
	liner.position = Vector3(cx, mid, 0.0)
	pivot.add_child(liner)
	for face in 2:
		var frame := OpeningTrim.piped_frame(loop, FRAME_PIPE * PIPE_SCALE, trim_color, true)
		frame.position = Vector3(cx, mid, outer_z if face == 0 else inner_z)
		frame.rotation.y = PI if face == 0 else 0.0
		pivot.add_child(frame)
	# Sill: a projecting board with a drip edge below the opening.
	# Ground-storey sills are stone, upper ones the oak of the frame.
	var sill_color := WALL_STONE.darkened(0.16) if floor_base < 0.5 else trim_color
	var sill := SuperEgg.build_part(Vector3(half_w + 0.14, 0.035, 0.12), sill_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	sill.position = Vector3(cx, bottom - FRAME_PIPE - 0.02, outer_z - 0.08)
	pivot.add_child(sill)
	CollisionPolicy.mark_decorative(sill)
	var inner_sill := SuperEgg.build_part(Vector3(half_w + 0.08, 0.025, 0.07), sill_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	inner_sill.position = Vector3(cx, bottom - FRAME_PIPE - 0.01, inner_z + 0.05)
	pivot.add_child(inner_sill)
	CollisionPolicy.mark_decorative(inner_sill)
	if kind == "window" or kind == "wide":
		# Shutters only where the building's purpose calls for them (dwellings and
		# inns' narrow casements; never workshops, halls, sheds or wide windows).
		# They are drawn open, lying flat against the wall either side of the
		# window like the covers of an open book, curved edge to the frame and
		# straight edge out, each with a raised panel and a cut diamond.
		if bool(opening.get("shutters", false)):
			var material := StandardMaterial3D.new()
			material.albedo_color = accent
			material.roughness = 0.85
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			var panel_material := StandardMaterial3D.new()
			panel_material.albedo_color = accent.lightened(0.16)
			panel_material.roughness = 0.8
			panel_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			var diamond_material := StandardMaterial3D.new()
			diamond_material.albedo_color = accent.darkened(0.45)
			diamond_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			var leaf_mesh := OpeningTrim.half_slab(half_w, half_h, opening_exponent, SHUTTER_DEPTH * 1.2)
			var panel_mesh := OpeningTrim.half_slab(half_w, half_h, opening_exponent, SHUTTER_DEPTH * 0.7)
			var hinge_x := half_w + FRAME_PIPE * 1.3
			for side: float in [-1.0, 1.0]:
				var leaf := MeshInstance3D.new()
				leaf.mesh = leaf_mesh
				leaf.material_override = material
				# Mirrored so the curved edge meets the frame and the straight
				# edge lies outward; flat on the wall face.
				leaf.position = Vector3(cx + side * (hinge_x + half_w), mid, outer_z - 0.04)
				leaf.scale = Vector3(-side, 1.0, 1.0)
				pivot.add_child(leaf)
				CollisionPolicy.mark_decorative(leaf)
				var inset := MeshInstance3D.new()
				inset.mesh = panel_mesh
				inset.material_override = panel_material
				inset.position = Vector3(half_w * 0.1, 0.0, -0.016)
				inset.scale = Vector3(0.76, 0.8, 1.0)
				leaf.add_child(inset)
				CollisionPolicy.mark_decorative(inset)
				var diamond := SuperEgg.build_part(Vector3(0.05, 0.085, 0.01), accent.darkened(0.45), 2.4, 2.4)
				diamond.position = Vector3(half_w * 0.52, half_h * 0.28, -0.028)
				diamond.rotation.z = PI * 0.25
				diamond.scale = Vector3(1.0, 0.7, 1.0)
				leaf.add_child(diamond)
				CollisionPolicy.mark_decorative(diamond)
	else:
		# Counter shelf and a propped awning flap for a service hatch.
		var shelf := SuperEgg.build_part(Vector3(half_w + 0.1, 0.04, 0.3), trim_color.lightened(0.08), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		shelf.position = Vector3(cx, bottom - 0.02, outer_z - 0.3)
		pivot.add_child(shelf)
		CollisionPolicy.add_box(body, shelf, Vector3((half_w + 0.1) * 2.0, 0.08, 0.6), origin + Basis(Vector3.UP, yaw) * shelf.position, Basis(Vector3.UP, yaw), true)
		var flap := SuperEgg.build_part(Vector3(half_w + 0.2, 0.025, 0.4), trim_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		flap.position = Vector3(cx, top + 0.3, outer_z - 0.36)
		flap.rotation.x = deg_to_rad(-18.0)
		pivot.add_child(flap)
		CollisionPolicy.mark_decorative(flap)


## Door leaves hinged at the jambs and swung open outward. `leaves` is 0 for an
## open bay, 1 for a single door, 2 for a pair.
static func _build_door_leaves(
	pivot: Node3D, cx: float, bottom: float, half_w: float, height: float, leaves: int, color: Color,
	options: Dictionary = {}
) -> void:
	if leaves <= 0:
		return
	var door := WORLD_DOOR_SCRIPT.new()
	door.position = Vector3(cx, bottom, -WALL_THICKNESS * 0.5 - 0.04)
	pivot.add_child(door)
	door.configure(
		half_w, height, leaves, color,
		bool(options.get("initially_open", true)), bool(options.get("locked", false)),
		str(options.get("required_key", "")), str(options.get("lock_id", "")),
		bool(options.get("hinge_right", false))
	)


## Whole log courses, not one capped log stack per grid cell. Openings are
## removed from each affected course, so timber runs corner-to-window,
## resumes on the far side, and stays continuous above each lintel. The
## west/east gables continue in the same material and course spacing.
static func _build_continuous_log_shell(
	body: StaticBody3D, w: int, d: int, floors: int,
	ground_color: Color, upper_color: Color, trim_color: Color
) -> void:
	var width := float(w) * CELL_SIZE
	var depth := float(d) * CELL_SIZE
	for floor_index in floors:
		var floor_base := float(floor_index) * FLOOR_HEIGHT
		var color := ground_color if floor_index == 0 else upper_color
		var window_y := floor_base + 1.72
		var window_open := {
			"center": 0.0, "width": 0.98,
			"bottom": window_y - 0.72, "top": window_y + 0.72,
		}
		var south_openings: Array[Dictionary] = [window_open]
		if floor_index == 0:
			south_openings = [{
				"center": 0.0, "width": DOOR_WIDTH,
				"bottom": floor_base, "top": floor_base + DOOR_HEIGHT,
			}]
		_build_log_facade(body, width, Vector3(0, floor_base, -depth * 0.5), 0.0, color, south_openings, floor_base)
		_build_log_facade(body, width, Vector3(0, floor_base, depth * 0.5), PI, color, [window_open], floor_base)
		_build_log_facade(body, depth, Vector3(-width * 0.5, floor_base, 0), PI * 0.5, color, [window_open], floor_base)
		_build_log_facade(body, depth, Vector3(width * 0.5, floor_base, 0), -PI * 0.5, color, [window_open], floor_base)
		if floor_index == 0:
			_build_log_door_frame(body, Vector3(0, floor_base, -depth * 0.5), 0.0, trim_color)
		else:
			_build_open_log_window(body, Vector3(0, window_y, -depth * 0.5), 0.0, trim_color)
		_build_open_log_window(body, Vector3(0, window_y, depth * 0.5), PI, trim_color)
		_build_open_log_window(body, Vector3(-width * 0.5, window_y, 0), PI * 0.5, trim_color)
		_build_open_log_window(body, Vector3(width * 0.5, window_y, 0), -PI * 0.5, trim_color)

	var half_depth := depth * 0.5
	var slope_len := (half_depth + ROOF_OVERHANG) / cos(ROOF_PITCH)
	var gable_height := slope_len * sin(ROOF_PITCH)
	var gable_base := float(floors) * FLOOR_HEIGHT
	var slot_height := FLOOR_HEIGHT / float(LOG_COUNT)
	var course_count := ceili(gable_height / slot_height)
	var gable_color := ground_color if floors <= 1 else upper_color
	for side in [-1.0, 1.0]:
		var yaw := PI * 0.5 if side < 0.0 else -PI * 0.5
		for course in course_count:
			var center_y := gable_base + (float(course) + 0.5) * slot_height
			var ratio := clampf((center_y - gable_base) / gable_height, 0.0, 1.0)
			var course_length := depth * (1.0 - ratio)
			if course_length > 0.08:
				_add_log_segment(body, course_length, Vector3(side * width * 0.5, center_y, 0), yaw, gable_color)


static func _build_log_facade(
	body: StaticBody3D, length: float, origin: Vector3, yaw: float, color: Color,
	openings: Array[Dictionary], floor_base: float
) -> void:
	var slot_height := FLOOR_HEIGHT / float(LOG_COUNT)
	var basis := Basis(Vector3.UP, yaw)
	for course in LOG_COUNT:
		var center_y := floor_base + slot_height * (float(course) + 0.5)
		var intervals: Array[Vector2] = [Vector2(-length * 0.5, length * 0.5)]
		for opening in openings:
			if center_y <= float(opening["bottom"]) or center_y >= float(opening["top"]):
				continue
			var half_width := float(opening["width"]) * 0.5
			intervals = _subtract_interval(
				intervals,
				Vector2(float(opening["center"]) - half_width, float(opening["center"]) + half_width)
			)
		for interval in intervals:
			var segment_length := interval.y - interval.x
			if segment_length <= 0.04:
				continue
			var local_center := (interval.x + interval.y) * 0.5
			_add_log_segment(
				body, segment_length,
				origin + basis * Vector3(local_center, center_y - floor_base, 0),
				yaw, color
			)


static func _subtract_interval(source: Array[Vector2], cut: Vector2) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for span in source:
		if cut.y <= span.x or cut.x >= span.y:
			result.append(span)
			continue
		if cut.x > span.x:
			result.append(Vector2(span.x, minf(cut.x, span.y)))
		if cut.y < span.y:
			result.append(Vector2(maxf(cut.y, span.x), span.y))
	return result


static func _add_log_segment(
	body: StaticBody3D, length: float, center: Vector3, yaw: float, color: Color
) -> void:
	var radius := _log_radius()
	var log := SuperEgg.build_part(
		Vector3(length * 0.5, radius, radius), color,
		LOG_EPSILON, LOG_EPSILON
	)
	log.position = center
	log.rotation.y = yaw
	body.add_child(log)
	_add_box_collision(
		body, center, Vector3(length, radius * 2.0, radius * 2.0),
		Basis(Vector3.UP, yaw)
	)


## Snow cabins are assembled timber, so this is a genuinely empty gap between
## stopped log courses.  There is intentionally no opaque 'window' slab.
static func _build_open_log_window(
	body: StaticBody3D, center: Vector3, yaw: float, trim_color: Color
) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var outward := basis * Vector3(0, 0, -1)
	var wall_plane := outward*_log_radius()
	for x in [-0.56,0.56]:
		_add_log_trim(body,center+basis*Vector3(x,0,0)+wall_plane,Vector3(0.055,0.78,0.04),yaw,trim_color)
	for y in [-0.78,0.78]:
		_add_log_trim(body,center+basis*Vector3(0,y,0)+wall_plane,Vector3(0.61,0.055,0.04),yaw,trim_color)
	# Open shutters sit outside the wall plane and fold away from the opening.
	for side in [-1.0,1.0]:
		var shutter := SuperEgg.build_part(
			Vector3(0.23,0.69,0.035),trim_color,
			SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT
		)
		shutter.position=center+basis*Vector3(side*0.79,0,-_log_radius()-0.055)
		shutter.rotation.y=yaw+side*deg_to_rad(18.0)
		body.add_child(shutter)


static func _build_log_door_frame(
	body: StaticBody3D, base_center: Vector3, yaw: float, trim_color: Color
) -> void:
	var basis := Basis(Vector3.UP, yaw)
	for x in [-DOOR_WIDTH * 0.5 - 0.08, DOOR_WIDTH * 0.5 + 0.08]:
		_add_log_trim(body, base_center + basis * Vector3(x, DOOR_HEIGHT * 0.5, -_log_radius() - 0.02), Vector3(0.07, DOOR_HEIGHT * 0.5, 0.05), yaw, trim_color)
	_add_log_trim(body, base_center + basis * Vector3(0, DOOR_HEIGHT + 0.08, -_log_radius() - 0.02), Vector3(DOOR_WIDTH * 0.5 + 0.15, 0.08, 0.05), yaw, trim_color)
	var door := WORLD_DOOR_SCRIPT.new()
	door.transform = Transform3D(basis, base_center + basis * Vector3(0.0, 0.0, -_log_radius() - 0.04))
	body.add_child(door)
	door.configure(DOOR_WIDTH * 0.5, DOOR_HEIGHT, 1, trim_color, true)


static func _add_log_trim(
	body: StaticBody3D, center: Vector3, half_size: Vector3,
	yaw: float, color: Color
) -> void:
	var trim := SuperEgg.build_part(
		half_size, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	trim.position = center
	trim.rotation.y = yaw
	body.add_child(trim)


## One single slab spanning the whole floor's footprint, not a per-cell
## grid -- per direct correction ("the procedural floors... seem to be
## using these modular tiled systems, which leaves a lot of gap in
## between the tiles... have a final pass... merge that into a single
## larger floor"). Even at EPSILON_FLAT, a superellipsoid's corners/edges
## still round off slightly short of the nominal box, which is exactly what
## showed as a seam wherever two tiles met -- one slab has no interior
## seams left to show at all.
static func _build_floor(body: StaticBody3D, w: int, d: int, y: float, floor_color: Color = FLOOR_COLOR) -> void:
	var half_size := Vector3(float(w) * CELL_SIZE * 0.5, 0.04, float(d) * CELL_SIZE * 0.5)
	var tile_pos := Vector3(0.0, y, 0.0)
	_add_flat_floor_visual(body,half_size,tile_pos,floor_color)
	# Landable per direct instruction -- upper-story floors previously had no
	# collision at all (see the ground floor's own real terrain collision,
	# which this is redundant with and harmless alongside).
	_add_box_collision(
		body, tile_pos, Vector3(float(w) * CELL_SIZE, FLOOR_COLLISION_THICKNESS, float(d) * CELL_SIZE)
	)


## An upper floor assembled around a genuine stairwell opening. Four broad
## plates retain a seamless room while leaving a rectangular void where the
## ramp arrives; unlike the former full slab, nothing invisible blocks the
## character's head or forces them through the floor.
## Interior ramps rise along the WEST gable wall, climbing toward the rear, at
## a plain 32 degrees: steep enough that a storey costs about five metres of
## run rather than a whole building's length, shallow enough to walk up. The
## ramp stays clear of the front door (centre of the south wall), of the hearth
## (east gable) and of the rear wall furniture.
const RAMP_PITCH := deg_to_rad(32.0)
const RAMP_WIDTH := 1.4


static func ramp_geometry(w: int, d: int) -> Dictionary:
	var width := float(w) * CELL_SIZE
	var depth := float(d) * CELL_SIZE
	var run := FLOOR_HEIGHT / tan(RAMP_PITCH)
	var z_low := -depth * 0.5 + 0.9
	return {
		"x": -width * 0.5 + 0.2 + RAMP_WIDTH * 0.5 + 0.05,
		"z_low": z_low, "z_high": z_low + run, "run": run,
		# The slab only reaches 2 m headroom this far along, so the floor above
		# stays solid until then and is open from here to the ramp's head.
		# Open the floor once the underside would come within 2.2 m of the
		# ramp surface. This leaves deliberate but close clearance above the
		# human rig and its hair instead of relying on a near-miss.
		"opening_start": z_low + 1.65,
	}


## The hole in an upper floor that the ramp climbs through: a superellipse
## (squarish, rounded corners), punched through a floor slab with the same
## constructive solid the walls use, framed by a piped timber rim, with guard
## rails on the open sides. The slab keeps the thickness and top height of the
## flat plates it replaces, and a plain box fills it to the walls.
const STAIR_HOLE_HALF_WIDTH := 0.9
const STAIR_HOLE_EXPONENT := 4.0


static func _build_floor_with_ramp_opening(
	body: StaticBody3D,w: int,d: int,y: float,floor_color: Color,voids: Array = []
) -> void:
	var width:=float(w)*CELL_SIZE
	var depth:=float(d)*CELL_SIZE
	var ramp := ramp_geometry(w, d)
	var open_z_low: float = ramp["opening_start"]
	var open_z_high: float = ramp["z_high"]
	# Wide and long enough that the ramp passes the narrowing ends of the curve.
	var half_a := STAIR_HOLE_HALF_WIDTH
	var half_b := (open_z_high - open_z_low) * 0.5 / 0.9 + 0.05
	var hole_x: float = float(ramp["x"]) + 0.05
	var hole_z := (open_z_low + open_z_high) * 0.5
	var deck := CSGCombiner3D.new()
	deck.name = "FloorWithStairHole"
	deck.position = Vector3(0.0, y, 0.0)
	deck.use_collision = true
	deck.collision_layer = 1
	deck.collision_mask = 0
	var material := SolidModel.material(floor_color, 0.82, 0.0)
	SolidModel.add_box(deck, "Deck", Vector3(width, 0.16, depth), CSGShape3D.OPERATION_UNION, material, Vector3(0.0, -0.04, 0.0))
	# The cutter extrudes along X; turned on its side it punches vertically.
	var cutter := SolidModel.add_profile(
		deck, "StairHole", 1.0, Vector2(half_a, half_b), STAIR_HOLE_EXPONENT,
		CSGShape3D.OPERATION_SUBTRACTION, material, Vector3(hole_x, 0.0, hole_z), 96
	)
	cutter.rotation.z = PI * 0.5
	# Further openings in the deck. Ordinary voids remain rectangles, while a
	# wall_superellipse is centred on an outside wall: only its interior half
	# intersects the floor, producing a broad, rounded gallery edge with a clean
	# straight clip at the wall. This is the right construction for a double-
	# height hearth hall, rather than a hard-cornered box cut beside a chimney.
	for void_index in voids.size():
		var void_spec: Variant = voids[void_index]
		if void_spec is Dictionary and str(void_spec.get("shape", "rect")) == "wall_superellipse":
			var center: Vector2 = void_spec["center"]
			var half_size: Vector2 = void_spec["half_size"]
			var exponent := float(void_spec.get("exponent", OPENING_EXPONENT))
			var void_cutter := SolidModel.add_profile(
				deck, "FloorVoid%d" % void_index, 1.0, half_size, exponent,
				CSGShape3D.OPERATION_SUBTRACTION, material,
				Vector3(center.x, 0.0, center.y), 128
			)
			void_cutter.rotation.z = PI * 0.5
		else:
			var rect: Rect2 = void_spec["rect"] if void_spec is Dictionary else void_spec
			var rect_center := rect.position + rect.size * 0.5
			SolidModel.add_box(
				deck, "FloorVoid%d" % void_index, Vector3(rect.size.x, 1.0, rect.size.y),
				CSGShape3D.OPERATION_SUBTRACTION, material, Vector3(rect_center.x, 0.0, rect_center.y)
			)
	body.add_child(deck)
	# Record every hole in this deck for the stacking audit (ClearZones).
	ClearZones.add_void(body, "stairwell", y, ClearZones.superellipse_polygon(Vector2(hole_x, hole_z), Vector2(half_a, half_b), STAIR_HOLE_EXPONENT))
	# A hall void is centred on a wall; only its inside half is a hole in this
	# floor, so clip the recorded polygon to the building's footprint.
	var footprint := PackedVector2Array([
		Vector2(-width * 0.5 + 0.1, -depth * 0.5 + 0.1), Vector2(width * 0.5 - 0.1, -depth * 0.5 + 0.1),
		Vector2(width * 0.5 - 0.1, depth * 0.5 - 0.1), Vector2(-width * 0.5 + 0.1, depth * 0.5 - 0.1),
	])
	for void_index in voids.size():
		var recorded: Variant = voids[void_index]
		if recorded is Dictionary and str(recorded.get("shape", "rect")) == "wall_superellipse":
			var full := ClearZones.superellipse_polygon(recorded["center"] as Vector2, recorded["half_size"] as Vector2, float(recorded.get("exponent", OPENING_EXPONENT)))
			for inside in Geometry2D.intersect_polygons(full, footprint):
				ClearZones.add_void(body, "double-height hall", y, inside)
		else:
			var recorded_rect: Rect2 = recorded["rect"] if recorded is Dictionary else recorded
			ClearZones.add_void(body, "floor opening", y, PackedVector2Array([
				recorded_rect.position, recorded_rect.position + Vector2(recorded_rect.size.x, 0.0),
				recorded_rect.position + recorded_rect.size, recorded_rect.position + Vector2(0.0, recorded_rect.size.y),
			]))
	for void_spec in voids:
		if void_spec is Dictionary and str(void_spec.get("shape", "rect")) == "wall_superellipse":
			_build_wall_superellipse_void_rail(body, void_spec, y)
		elif void_spec is Dictionary:
			_build_void_rails(body, void_spec["rect"], y, width * 0.5, depth * 0.5, void_spec.get("rails", []))
		else:
			_build_void_rails(body, void_spec, y, width * 0.5, depth * 0.5, [])
	# A rim of timber round the hole, lying flat on the deck.
	var loop := OpeningTrim.window_loop(half_a, half_b, STAIR_HOLE_EXPONENT)
	var rim := MeshInstance3D.new()
	rim.name = "StairHoleRim"
	rim.mesh = OpeningTrim.piped_mesh(loop, 0.035, true, Vector2.ZERO)
	var rim_material := StandardMaterial3D.new()
	rim_material.albedo_color = TRIM_WOOD
	rim_material.roughness = 0.7
	rim_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	rim.material_override = rim_material
	rim.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(hole_x, y + 0.045, hole_z))
	body.add_child(rim)
	CollisionPolicy.mark_decorative(rim)
	# Guard rails: along the straight east side of the hole from the foot to a
	# clear landing at the head, and across its open south end. The head itself,
	# where the ramp arrives, is left open to step off.
	var landing := 1.4
	var rail_from := hole_z - half_b + 0.5
	var rail_to := open_z_high - landing
	if rail_to > rail_from:
		_balustrade(body, Vector2(hole_x + half_a - 0.02, rail_from), Vector2(hole_x + half_a - 0.02, rail_to), y)
	var south_z := hole_z - half_b + 0.07
	_balustrade(body, Vector2(hole_x - half_a * 0.55, south_z), Vector2(hole_x + half_a * 0.55, south_z), y)


## A balustrade between two plan points: a top rail on slender posts, with
## collision along the rail. Used for floor holes and voids.
static func _balustrade(body: StaticBody3D, a: Vector2, b: Vector2, y: float) -> void:
	var rail := TRIM_WOOD
	var length := a.distance_to(b)
	if length < 0.2:
		return
	var middle := (a + b) * 0.5
	var along := (b - a) / length
	var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
	var top := SuperEgg.build_part(Vector3(length * 0.5 + 0.04, 0.04, 0.04), rail, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	top.transform = Transform3D(basis, Vector3(middle.x, y + 1.0, middle.y))
	body.add_child(top)
	# Collision matches the timber itself. The former metre-tall invisible box
	# made a rail impossible to balance on and placed its apparent top half a
	# metre above the visible wood.
	_add_box_collision(body, top.position, Vector3(length, 0.10, 0.10), basis)
	var count := maxi(int(length / 0.35), 2)
	for i in count + 1:
		var point := a.lerp(b, float(i) / float(count))
		var post_height := 0.5 if i % 2 == 0 else 0.46
		var post := SuperEgg.build_part(Vector3(0.035, post_height, 0.035), rail.lightened(0.06), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		post.position = Vector3(point.x, y + post_height + 0.04, point.y)
		body.add_child(post)
		_add_box_collision(body, post.position, Vector3(0.07, post_height * 2.0, 0.07))


## A continuous guard following the interior half of a wall-centred
## superellipse. The outer half lies beyond the building and is deliberately
## unrailed, so the opening meets the chimney wall as one double-height room.
static func _build_wall_superellipse_void_rail(body: StaticBody3D, spec: Dictionary, y: float) -> void:
	var center: Vector2 = spec["center"]
	var half_size: Vector2 = spec["half_size"]
	var exponent := float(spec.get("exponent", OPENING_EXPONENT))
	var wall := str(spec.get("wall", "east"))
	var steps := maxi(int(spec.get("rail_segments", 18)), 8)
	var points: Array[Vector2] = []
	for index in steps + 1:
		var t := float(index) / float(steps)
		var angle: float
		match wall:
			"west":
				angle = -PI * 0.5 + PI * t
			"north":
				angle = PI * t
			"south":
				angle = PI + PI * t
			_:
				angle = PI * 0.5 + PI * t
		var cosine := cos(angle)
		var sine := sin(angle)
		points.append(center + Vector2(
			half_size.x * signf(cosine) * pow(absf(cosine), 2.0 / exponent),
			half_size.y * signf(sine) * pow(absf(sine), 2.0 / exponent)
		))
	var rail_color := TRIM_WOOD
	for index in points.size() - 1:
		var a := points[index]
		var b := points[index + 1]
		var length := a.distance_to(b)
		if length < 0.02:
			continue
		var middle := (a + b) * 0.5
		var along := (b - a) / length
		var basis := Basis(Vector3.UP, atan2(-along.y, along.x))
		var top := SuperEgg.build_part(Vector3(length * 0.5 + 0.035, 0.04, 0.04), rail_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		top.transform = Transform3D(basis, Vector3(middle.x, y + 1.0, middle.y))
		body.add_child(top)
		_add_box_collision(body, top.position, Vector3(length + 0.05, 0.10, 0.10), basis)
	# Posts follow the curve at a calm architectural rhythm. Building a complete
	# mini-balustrade for every curve segment produced a thicket of duplicates.
	for index in points.size():
		if index % 2 != 0 and index != points.size() - 1:
			continue
		var point := points[index]
		var post := SuperEgg.build_part(Vector3(0.04, 0.5, 0.04), rail_color.lightened(0.06), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		post.position = Vector3(point.x, y + 0.54, point.y)
		body.add_child(post)
		_add_box_collision(body, post.position, Vector3(0.08, 1.0, 0.08))


## Guard rails along the edges of a floor void: the named sides ("west",
## "east", "north", "south"; north is -Z) or, if none are named, every edge that
## is not against an outer wall.
static func _build_void_rails(body: StaticBody3D, rect: Rect2, y: float, half_w: float, half_d: float, sides: Array) -> void:
	var edges := {
		"west": [Vector2(rect.position.x, rect.position.y), Vector2(rect.position.x, rect.end.y)],
		"north": [Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y)],
		"south": [Vector2(rect.position.x, rect.end.y), Vector2(rect.end.x, rect.end.y)],
		"east": [Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.end.y)],
	}
	for side_name: String in edges:
		var edge: Array = edges[side_name]
		var a: Vector2 = edge[0]
		var b: Vector2 = edge[1]
		if sides.is_empty():
			var on_wall := (absf(a.x - half_w) < 0.2 and absf(b.x - half_w) < 0.2) or (absf(a.x + half_w) < 0.2 and absf(b.x + half_w) < 0.2) or (absf(a.y - half_d) < 0.2 and absf(b.y - half_d) < 0.2) or (absf(a.y + half_d) < 0.2 and absf(b.y + half_d) < 0.2)
			if on_wall:
				continue
		elif not (side_name in sides):
			continue
		_balustrade(body, a, b, y)


static func _add_floor_plate(body: StaticBody3D,half_size: Vector3,position: Vector3,color: Color) -> void:
	if half_size.x<=0.01 or half_size.z<=0.01:
		return
	_add_flat_floor_visual(body,half_size,position,color)
	_add_box_collision(body,position,Vector3(half_size.x*2.0,FLOOR_COLLISION_THICKNESS,half_size.z*2.0))


## Floors are architectural planes, not organic masses. A BoxMesh reaches its
## authored corners exactly, so the visible deck and square collision agree at
## every edge rather than exposing crescent gaps left by a flattened superegg.
static func _add_flat_floor_visual(
	body: StaticBody3D,half_size: Vector3,position: Vector3,color: Color
) -> void:
	var mesh:=BoxMesh.new()
	mesh.size=half_size*2.0
	mesh.material=SolidModel.material(color,0.82,0.0)
	var plate:=MeshInstance3D.new()
	plate.mesh=mesh
	plate.position=position
	body.add_child(plate)


## Switchback-ready interior circulation shared by every ordinary multi-storey
## village building. Each flight terminates through the opening in the floor
## above, with a real landing guard rather than intersecting a ceiling plate.
static func _build_interior_ramps(body: StaticBody3D,w: int,d: int,floors: int) -> void:
	var ramp := ramp_geometry(w, d)
	var run: float = ramp["run"]
	var z_low: float = ramp["z_low"]
	var length := Vector2(run, FLOOR_HEIGHT).length()
	for level in floors-1:
		var base_y:=float(level)*FLOOR_HEIGHT
		# Rotating about X by -pitch lifts the +Z end: the ramp climbs toward the rear.
		var basis := Basis(Vector3.RIGHT, -RAMP_PITCH)
		var ramp_slab:=SuperEgg.build_part(Vector3(RAMP_WIDTH * 0.5, 0.075, length * 0.5),TRIM_WOOD,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		var centre := Vector3(float(ramp["x"]), base_y + FLOOR_HEIGHT * 0.5 - 0.075, z_low + run * 0.5)
		var lane_x := float(ramp["x"])
		# The foot of the ramp is only 0.9 m inside the front wall, so the lane
		# starts just inside it and ends at most 1 m past the head.
		var half_room := float(d) * CELL_SIZE * 0.5
		# Start the clearance sweep beyond the inside face of the log wall. A
		# person approaching through the door is still checked by the door zone;
		# including the wall itself in the ramp sweep only reports the jamb as an
		# obstruction before the ramp has begun.
		var lane_start := maxf(z_low - 0.3, -half_room + 0.7)
		var lane_end := minf(z_low + run + 0.7, half_room - 0.4)
		var lane_points: Array[Vector3] = [
			Vector3(lane_x, base_y, lane_start), Vector3(lane_x, base_y, z_low),
			Vector3(lane_x, base_y + FLOOR_HEIGHT, z_low + run), Vector3(lane_x, base_y + FLOOR_HEIGHT, lane_end),
		]
		ClearZones.add_lane(body, "ramp level %d" % level, lane_points)
		ClearZones.add(body, "ramp foot", "ramp", Vector2(lane_x, z_low), Vector2(0, 1), 0.8, 0.0, RAMP_WIDTH * 0.5 + 0.25, base_y + 0.05, base_y + 1.9)
		ClearZones.add(body, "ramp head", "ramp", Vector2(lane_x, z_low + run), Vector2(0, 1), 0.0, 1.3, RAMP_WIDTH * 0.5 + 0.25, base_y + FLOOR_HEIGHT + 0.05, base_y + FLOOR_HEIGHT + 1.9)
		ramp_slab.transform=Transform3D(basis, centre)
		body.add_child(ramp_slab)
		_add_box_collision(body, centre, Vector3(RAMP_WIDTH, 0.15, length), basis)
		# Grip battens across the slab, so boots and blorbs stay controllable.
		var battens := int(length / 0.55)
		for i in battens:
			var t := (float(i) + 0.5) / float(battens)
			var along := (t - 0.5) * length
			var batten := SuperEgg.build_part(Vector3(RAMP_WIDTH * 0.5 - 0.05, 0.02, 0.025), TRIM_WOOD.lightened(0.12), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			batten.transform = Transform3D(basis, centre + basis * Vector3(0.0, 0.09, along))
			body.add_child(batten)
			CollisionPolicy.mark_decorative(batten)


static func _build_corner_post(body: StaticBody3D, pos: Vector3, color: Color) -> void:
	var post := SuperEgg.build_part(
		Vector3(0.14, FLOOR_HEIGHT * 0.5, 0.14), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	var post_pos := pos + Vector3(0, FLOOR_HEIGHT * 0.5, 0)
	post.position = post_pos
	body.add_child(post)
	_add_box_collision(body, post_pos, Vector3(0.28, FLOOR_HEIGHT, 0.28))


## The real outward half-thickness of a wall of this style -- a log wall's
## logs bulge out well past WALL_THICKNESS*0.5 (they need real radius to
## read as logs at all), so anything measuring where the wall's own outside
## FACE actually is (a window's own shutters, the wall's shared collision
## box) needs this instead of assuming the thin flat-panel thickness. Per
## direct correction ("window shutters are now clipping into those walls").
static func _wall_face_offset(wall_style: String) -> float:
	return _log_radius() if wall_style == "log" else WALL_THICKNESS * 0.5


static func _build_wall_cell(
	body: StaticBody3D, pos: Vector3, yaw: float, color: Color, opening: String,
	shutter_color: Color, wall_style: String = "panel"
) -> void:
	var basis := Basis(Vector3.UP, yaw)

	if opening == "door":
		_build_door_cell(body, pos, basis, color)
		return

	var wall_pos := pos + Vector3(0, FLOOR_HEIGHT * 0.5, 0)
	var face_offset := _wall_face_offset(wall_style)
	if wall_style == "log":
		_build_log_wall_panel(body, wall_pos, basis, color)
	else:
		var wall := SuperEgg.build_part(
			Vector3(CELL_SIZE * 0.5, FLOOR_HEIGHT * 0.5, WALL_THICKNESS * 0.5), color,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		wall.basis = basis
		wall.position = wall_pos
		body.add_child(wall)
	_add_box_collision(body, wall_pos, Vector3(CELL_SIZE, FLOOR_HEIGHT, face_offset * 2.0), basis)

	if opening == "window":
		var outward := basis * Vector3(0, 0, -1)
		var shutter_center := (
			pos + Vector3(0, FLOOR_HEIGHT * 0.55, 0) + outward * (face_offset + 0.015)
		)
		# Two closed leaves ARE the window treatment; there is no unrelated grey
		# glass slab behind them and no decorative leaves parked off to the side.
		for side in [-1.0, 1.0]:
			var shutter := SuperEgg.build_part(
				Vector3(WINDOW_SIZE.x * 0.245, WINDOW_SIZE.y * 0.5, 0.035),
				shutter_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			shutter.basis = basis
			shutter.position = shutter_center + basis * Vector3(side * WINDOW_SIZE.x * 0.25, 0.0, -0.025)
			body.add_child(shutter)
			for batten_y in [-0.27, 0.27]:
				var batten := SuperEgg.build_part(
					Vector3(WINDOW_SIZE.x * 0.21, 0.025, 0.018),
					shutter_color.darkened(0.22), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
				)
				batten.basis = basis
				batten.position = shutter.position + basis * Vector3(0.0, batten_y, -0.045)
				body.add_child(batten)


## Leaves the actual doorway open -- only the two jambs and the lintel
## above collide, matching the exact same "measured opening, forgiving
## collision" approach town_generator.gd used against the old Kenney door
## module, just built directly against dimensions this file already owns
## instead of having to parse them out of a loaded GLB.
static func _build_door_cell(body: StaticBody3D, pos: Vector3, basis: Basis, wall_color: Color) -> void:
	var jamb_width := (CELL_SIZE - DOOR_WIDTH) * 0.5
	if jamb_width > 0.02:
		for side: float in [-1.0, 1.0]:
			var jamb_local_x: float = side * (CELL_SIZE * 0.5 - jamb_width * 0.5)
			var jamb := SuperEgg.build_part(
				Vector3(jamb_width * 0.5, FLOOR_HEIGHT * 0.5, WALL_THICKNESS * 0.5), wall_color,
				SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			jamb.basis = basis
			var jamb_pos := pos + basis * Vector3(jamb_local_x, FLOOR_HEIGHT * 0.5, 0)
			jamb.position = jamb_pos
			body.add_child(jamb)
			_add_box_collision(body, jamb_pos, Vector3(jamb_width, FLOOR_HEIGHT, WALL_THICKNESS), basis)

	var lintel_height := FLOOR_HEIGHT - DOOR_HEIGHT
	if lintel_height > 0.05:
		var lintel := SuperEgg.build_part(
			Vector3(CELL_SIZE * 0.5, lintel_height * 0.5, WALL_THICKNESS * 0.5), wall_color,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		lintel.basis = basis
		var lintel_pos := pos + basis * Vector3(0, DOOR_HEIGHT + lintel_height * 0.5, 0)
		lintel.position = lintel_pos
		body.add_child(lintel)
		_add_box_collision(body, lintel_pos, Vector3(CELL_SIZE, lintel_height, WALL_THICKNESS), basis)

	var door := WORLD_DOOR_SCRIPT.new()
	door.transform = Transform3D(basis, pos + basis * Vector3(0.0, 0.0, -WALL_THICKNESS * 0.5 - 0.04))
	body.add_child(door)
	door.configure(DOOR_WIDTH * 0.5, DOOR_HEIGHT, 1, wall_color.darkened(0.12), true)


## Stacks several horizontal round SuperEgg "logs" across the exact same
## CELL_SIZE x FLOOR_HEIGHT footprint a flat panel would occupy, spanning
## LOG_OUTWARD_OFFSET*2 in actual thickness instead of WALL_THICKNESS (see
## that constant and _wall_face_offset() -- both callers of a log wall, the
## window shutters and the shared collision box, size against it instead of
## the thin flat-panel thickness, or shutters end up buried in the thicker
## logs and the collision stays thinner than what's actually rendered).
## Per direct correction ("[the logs] allowing a huge amount of gap between
## them... [the gable bands] fit together more cleanly with less gap... use
## that very similar geometry to the regular walls too") -- LOG_OVERLAP
## spaces log centers closer together than 2*radius (true circles merely
## touching at one point, the old spacing, leave a big visible lens-shaped
## gap between courses), and a moderately flatter epsilon (2.6, short of
## the gable band's fully flat 5.5 -- that would lose the round "log" read
## entirely) flattens each log's own top/bottom a bit further, closing the
## gap further still while it's still clearly a rounded log, not a board.
const LOG_COUNT := 9
const LOG_OVERLAP := 0.7
## Close to the exact circular case (2.0): clearly round timber rather than
## the flattened-plank silhouette produced by the former 2.6 value.
const LOG_EPSILON := 2.15
## Shared by _build_log_wall_panel() and _wall_face_offset() below, so a log
## wall's real outward thickness (used for window-shutter placement and the
## wall's own collision box) always matches what's actually rendered.
static func _log_radius() -> float:
	return (FLOOR_HEIGHT / float(LOG_COUNT) * 0.5) / LOG_OVERLAP
static func _build_log_wall_panel(body: StaticBody3D, center: Vector3, basis: Basis, color: Color) -> void:
	var slot_height := FLOOR_HEIGHT / float(LOG_COUNT)
	var log_radius := _log_radius()
	var base_y := center.y - FLOOR_HEIGHT * 0.5
	for i in LOG_COUNT:
		var log_y := base_y + slot_height * (float(i) + 0.5)
		var tint := color.lightened(0.06) if i % 2 == 0 else color.darkened(0.06)
		var log := SuperEgg.build_part(
			Vector3(CELL_SIZE * 0.5, log_radius, log_radius), tint, LOG_EPSILON, LOG_EPSILON
		)
		log.basis = basis
		log.position = Vector3(center.x, log_y, center.z)
		body.add_child(log)


## Fills the triangular gap a gable roof otherwise leaves above a building's
## short (west/east) end walls -- those only rise to the flat top of the top
## floor, while the roof's own ridge keeps rising above that. Per direct
## instruction: "the triangle area above the walls where the triangle roofs
## come together... there's just no triangle shape to fill it in."
## Approximated as several stacked, progressively narrower horizontal bands
## (this project's SuperEgg-only convention -- no hand-rolled wedge mesh)
## rather than one continuous triangle; close enough at this scale to read
## as solid infill rather than a visibly stepped edge.
const GABLE_INFILL_BANDS := 7
static func _build_gable_infill(body: StaticBody3D, w: int, d: int, floor_top_y: float, color: Color) -> void:
	var peak_y := roof_underside_y(floor_top_y, d * CELL_SIZE * 0.5, 0.0)
	var triangle_height := peak_y - floor_top_y
	var half_base := d * CELL_SIZE * 0.5
	var band_height := triangle_height / float(GABLE_INFILL_BANDS)
	var sides: Array[float] = [-1.0, 1.0]
	for side in sides:
		var wall_x := side * w * CELL_SIZE * 0.5
		var basis := Basis(Vector3.UP, deg_to_rad(90.0) if side < 0.0 else deg_to_rad(-90.0))
		for i in GABLE_INFILL_BANDS:
			var band_center_t := (float(i) + 0.5) / float(GABLE_INFILL_BANDS)
			var band_half_width := half_base * (1.0 - band_center_t)
			if band_half_width < 0.03:
				continue
			var band_y := floor_top_y + (float(i) + 0.5) * band_height
			var band := SuperEgg.build_part(
				Vector3(band_half_width, band_height * 0.5, WALL_THICKNESS * 0.5), color,
				SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			band.basis = basis
			band.position = Vector3(wall_x, band_y, 0.0)
			body.add_child(band)
			_add_box_collision(
				body, band.position, Vector3(band_half_width * 2.0, band_height, WALL_THICKNESS), basis
			)


## One simple frame+mattress bed (matching village_inn.gd's own guest beds)
## placed in the back corner farthest from the door -- door_ix/south wall
## match build_building()'s own convention, so "farthest corner" is always
## the north-west one regardless of building size.
const BED_FRAME_COLOR := Color(0.33, 0.18, 0.09)
const BED_MATTRESS_COLOR := Color(0.88, 0.82, 0.68)
static func _build_house_bed(body: StaticBody3D, w: int, d: int) -> void:
	# Head against the rear wall, east of the ramp that climbs the west gable
	# and clear of the hearth (east gable) and the rear-east work table.
	var bed_x := -(float(w) * CELL_SIZE * 0.5) + 3.3
	var bed_z := float(d) * CELL_SIZE * 0.5 - 0.12 - 1.2
	var bed := build_bed(Color(0.32, 0.46, 0.66))
	bed.position = Vector3(bed_x, 0.0, bed_z)
	# The bed is modelled head toward -Z; turn it so the head meets the rear wall.
	bed.rotation.y = PI
	body.add_child(bed)


## A legged timber bed with visible rails, recessed mattress, blanket,
## pillow, headboard and footboard. The former two stacked rounded slabs
## read as food rather than furniture and had no structural silhouette.
static func build_bed(blanket_color: Color = Color(0.32, 0.46, 0.66)) -> StaticBody3D:
	var bed := StaticBody3D.new()
	bed.collision_layer = 1
	bed.collision_mask = 0
	var half_w := 0.72
	var half_l := 1.18
	var rail_y := 0.34
	for x in [-half_w, half_w]:
		var rail := SuperEgg.build_part(Vector3(0.055, 0.10, half_l), BED_FRAME_COLOR, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		rail.position = Vector3(x, rail_y, 0)
		bed.add_child(rail)
	for z in [-half_l, half_l]:
		var rail := SuperEgg.build_part(Vector3(half_w, 0.10, 0.055), BED_FRAME_COLOR, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		rail.position = Vector3(0, rail_y, z)
		bed.add_child(rail)
	for x in [-half_w, half_w]:
		for z in [-half_l, half_l]:
			var leg := SuperEgg.build_part(Vector3(0.065, 0.24, 0.065), BED_FRAME_COLOR.darkened(0.08), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
			leg.position = Vector3(x, 0.24, z)
			bed.add_child(leg)
	var mattress := SuperEgg.build_part(Vector3(0.66, 0.13, 1.08), BED_MATTRESS_COLOR, 3.4, SuperEgg.EPSILON_FLAT)
	mattress.position = Vector3(0, 0.48, 0)
	bed.add_child(mattress)
	var blanket := SuperEgg.build_part(Vector3(0.67, 0.055, 0.69), blanket_color, 3.8, SuperEgg.EPSILON_FLAT)
	blanket.position = Vector3(0, 0.63, 0.34)
	bed.add_child(blanket)
	var pillow := SuperEgg.build_part(Vector3(0.48, 0.10, 0.25), Color(0.94, 0.91, 0.82), 2.8, 2.8)
	pillow.position = Vector3(0, 0.66, -0.76)
	bed.add_child(pillow)
	var headboard := SuperEgg.build_part(Vector3(0.78, 0.52, 0.065), BED_FRAME_COLOR, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	headboard.position = Vector3(0, 0.64, -half_l)
	bed.add_child(headboard)
	var footboard := SuperEgg.build_part(Vector3(0.78, 0.28, 0.055), BED_FRAME_COLOR, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	footboard.position = Vector3(0, 0.40, half_l)
	bed.add_child(footboard)
	_add_box_collision(bed, Vector3(0, 0.42, 0), Vector3(1.56, 0.70, 2.46))
	bed.set_meta(ClearZones.FURNITURE_META, true)
	return bed


## Insulated dry toilet used by cold-climate inns and enclosed service
## lean-tos. The seat and lid are recognizable furniture; its below-floor
## compost vault is represented by the room architecture, not an exposed
## decorative pipe that would freeze like water plumbing.
static func build_dry_toilet() -> StaticBody3D:
	var toilet := StaticBody3D.new()
	toilet.collision_layer = 1
	var ceramic:=Color(0.91,0.89,0.83)
	# Local +Z is the back placed against the wall; local -Z is the approach.
	var pedestal:=SuperEgg.build_part(Vector3(0.26,0.34,0.29),ceramic.darkened(0.04),3.2,3.2)
	pedestal.position=Vector3(0,0.34,0.02)
	toilet.add_child(pedestal)
	var bowl:=SuperEgg.build_part(Vector3(0.42,0.22,0.53),ceramic,2.5,2.7)
	bowl.position=Vector3(0,0.64,-0.06)
	toilet.add_child(bowl)
	var opening:=CylinderMesh.new()
	opening.top_radius=0.22
	opening.bottom_radius=0.22
	opening.height=0.018
	opening.radial_segments=48
	opening.material=SolidModel.material(Color(0.10,0.09,0.075),0.55,0.0)
	var hole:=MeshInstance3D.new()
	hole.mesh=opening
	hole.scale=Vector3(1.0,1.0,1.45)
	hole.position=Vector3(0,0.85,-0.10)
	toilet.add_child(hole)
	# One continuous oval seat replaces the four disconnected rods.
	var seat_mesh:=TorusMesh.new()
	seat_mesh.inner_radius=0.22
	seat_mesh.outer_radius=0.32
	seat_mesh.rings=48
	seat_mesh.ring_segments=10
	seat_mesh.material=SolidModel.material(ceramic.lightened(0.035),0.38,0.0)
	var seat:=MeshInstance3D.new()
	seat.mesh=seat_mesh
	seat.scale=Vector3(1.0,0.36,1.42)
	seat.position=Vector3(0,0.88,-0.10)
	toilet.add_child(seat)
	var tank:=SuperEgg.build_part(Vector3(0.40,0.43,0.16),ceramic,3.8,3.8)
	tank.position=Vector3(0,0.83,0.43)
	toilet.add_child(tank)
	var lid:=SuperEgg.build_part(Vector3(0.43,0.035,0.19),ceramic.lightened(0.025),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	lid.position=Vector3(0,1.28,0.43)
	toilet.add_child(lid)
	_add_box_collision(toilet,Vector3(0,0.48,0),Vector3(0.86,0.96,1.12))
	return toilet


## A gable roof: two flat panels sloping down from a central ridge toward
## the north/south eaves. Built via an explicit outward-normal Basis (the
## same decal-alignment technique figure_eyes.gd/figure_emblem.gd use for
## a curved surface) rather than a raw Euler rotation -- far more robust
## than hand-deriving the right sign for a slanted panel, since the north
## and south panels are mirror images of each other and would otherwise
## need opposite rotation signs worked out separately. normal is forced to
## point up (normal.y >= 0) regardless of which cross-product order
## happens to give that.
## Roof forms: "half_hip" (+1 or -1: that gable end is clipped by a small hip)
## and "catslide" (metres: the rear slope runs on, unbroken, down over an
## outshut that deep). Both keep the one pitch.
const HIP_INSET := 1.3
const HIP_HEIGHT := 0.9


static func _build_roof(body: StaticBody3D, w: int, d: int, floor_top_y: float, color: Color, form: Dictionary = {}) -> void:
	var width := w * CELL_SIZE + ROOF_GABLE_OVERHANG * 2.0
	var half_wall := d * CELL_SIZE * 0.5
	var half_depth := half_wall + ROOF_EAVE_OVERHANG
	var slope_len := half_depth / cos(ROOF_PITCH)
	var ridge_pos := Vector3(0, roof_center_y(floor_top_y, half_wall, 0.0), 0)
	var rear_len := slope_len + float(form.get("catslide", 0.0)) / cos(ROOF_PITCH)
	var hip_side := float(form.get("half_hip", 0.0))
	if form.has("belfry_gap") and hip_side == 0.0:
		_build_gapped_roof(body, ridge_pos, width, rear_len, slope_len, color, form["belfry_gap"] as Dictionary, half_wall, form.get("cross_gables", []))
	elif hip_side != 0.0:
		_build_hipped_roof(body, ridge_pos, width, rear_len, slope_len, color, hip_side)
		_build_ridge_beam(body, ridge_pos, width, color, hip_side)
	else:
		_build_roof_panel(body, ridge_pos, width, rear_len, true, color)
		_build_front_slope(body, ridge_pos, width, slope_len, color, half_wall, form.get("cross_gables", []))
		_build_ridge_beam(body, ridge_pos, width, color)


## The front (south) slope. Where a cross gable stands on it, the slope is cut away
## under the gable's own roof along the two valleys (each cut a mitre shared with
## the gable's slab), so the gable's roof is the roof there and nothing of the main
## slope shows through it. The slope is built as two pieces, one kept on each side
## of the gable's wedge; behind the gable's apex they overlap in the same plane.
static func _build_front_slope(
	body: StaticBody3D, ridge_pos: Vector3, width: float, slope_len: float, color: Color,
	half_wall: float, gables: Array, x_center: float = 0.0, round_left: bool = true, round_right: bool = true,
	s_start: float = 0.0, vertical_ridge: bool = true
) -> void:
	if gables.is_empty():
		_build_roof_panel(body, ridge_pos, width, slope_len, false, color, x_center, s_start, round_left, round_right, [], vertical_ridge)
		return
	var gable: Dictionary = gables[0]
	var gable_x := float(gable["x"])
	var gable_half := float(gable["width"]) * 0.5
	# A piece that does not reach the gable's footprint needs no cut.
	if gable_x + gable_half < x_center - width * 0.5 or gable_x - gable_half > x_center + width * 0.5:
		_build_roof_panel(body, ridge_pos, width, slope_len, false, color, x_center, s_start, round_left, round_right, [], vertical_ridge)
		return
	var planes := cross_gable_planes(ridge_pos.y, gable_x, gable_half, half_wall)
	# Three pieces that do not overlap: left and right of the gable's wedge in front of
	# its apex, and the whole width behind the apex.
	var apex_z := -(half_wall + ROOF_EAVE_OVERHANG) + gable_half
	var before_apex := Plane(Vector3(0.0, 0.0, 1.0), apex_z)
	var behind_apex := Plane(Vector3(0.0, 0.0, -1.0), -apex_z)
	for key in ["main_left", "main_right"]:
		_build_roof_panel(body, ridge_pos, width, slope_len, false, color, x_center, s_start, round_left, round_right, [planes[key] as Plane, before_apex], vertical_ridge)
	_build_roof_panel(body, ridge_pos, width, slope_len, false, color, x_center, s_start, round_left, round_right, [behind_apex], vertical_ridge)


## The four mitre planes at a cross gable's valleys, in the building frame: for each
## side, the plane that keeps the gable's slab ("cross_left", "cross_right") and the
## plane that keeps the main slope ("main_left", "main_right"). The gable has the
## main roof's pitch, its eave at the main roof's front eave height, and its ridge
## meets the main slope along two 45 degree valleys.
static func cross_gable_planes(main_ridge_y: float, gable_x: float, gable_half: float, half_wall: float) -> Dictionary:
	var front_run := half_wall + ROOF_EAVE_OVERHANG
	var front_z := -front_run
	var eave_y := main_ridge_y - front_run * tan(ROOF_PITCH)
	var ridge_y := eave_y + gable_half * tan(ROOF_PITCH)
	var main_normal := Vector3(0.0, cos(ROOF_PITCH), -sin(ROOF_PITCH))
	var result := {}
	for side: float in [-1.0, 1.0]:
		var cross_normal := Vector3(side * sin(ROOF_PITCH), cos(ROOF_PITCH), 0.0)
		var valley_start := Vector3(gable_x + side * gable_half, eave_y, front_z)
		var valley_end := Vector3(gable_x, ridge_y, front_z + gable_half)
		var keep := Vector3(gable_x + side * gable_half * 0.5, eave_y + gable_half * 0.5 * tan(ROOF_PITCH), front_z + gable_half * 0.35)
		var cross_plane := _mitre_plane(valley_start, valley_end - valley_start, cross_normal, main_normal, keep)
		var suffix := "left" if side < 0.0 else "right"
		result["cross_" + suffix] = cross_plane
		result["main_" + suffix] = Plane(-cross_plane.normal, -cross_plane.d)
	return result


## A half-hip: the roof ends in a small hip facet instead of a full gable. The
## facet is a SuperEgg slab like every other roof slope, clipped where it meets
## each main slope by a MITRE plane (the plane through their shared edge that
## bisects the angle between the two slabs). Each main slope is clipped by the
## same plane, so the joint is a hard flat edge that fits exactly, the same cut as
## a window shutter or a double door.
static func _build_hipped_roof(
	body: StaticBody3D, ridge_pos: Vector3, width: float, rear_len: float, slope_len: float,
	color: Color, hip_side: float
) -> void:
	var half_width := width * 0.5
	var drop := HIP_HEIGHT
	var base_z := drop / tan(ROOF_PITCH)
	var apex := ridge_pos + Vector3(hip_side * (half_width - HIP_INSET), 0.0, 0.0)
	var corner_south := Vector3(hip_side * half_width, ridge_pos.y - drop, -base_z)
	var corner_north := Vector3(hip_side * half_width, ridge_pos.y - drop, base_z)
	var hip_normal := (corner_south - apex).cross(corner_north - apex).normalized()
	if hip_normal.y < 0.0:
		hip_normal = -hip_normal
	var north_normal := Vector3(0.0, cos(ROOF_PITCH), sin(ROOF_PITCH))
	var south_normal := Vector3(0.0, cos(ROOF_PITCH), -sin(ROOF_PITCH))
	# North mitre: the edge apex-to-north-corner, bisecting the north slope and the facet.
	var north_edge := corner_north - apex
	var north_mitre := _mitre_plane(apex, north_edge, north_normal, hip_normal, Vector3(0.0, ridge_pos.y - 2.0 * tan(ROOF_PITCH), 2.0))
	var south_edge := corner_south - apex
	var south_mitre := _mitre_plane(apex, south_edge, south_normal, hip_normal, Vector3(0.0, ridge_pos.y - 2.0 * tan(ROOF_PITCH), -2.0))
	_build_roof_panel(body, ridge_pos, width, rear_len, true, color, 0.0, 0.0, true, true, [north_mitre])
	_build_roof_panel(body, ridge_pos, width, slope_len, false, color, 0.0, 0.0, true, true, [south_mitre])
	# The facet: its eave end at the line between the two corners, clipped on both sides
	# by the opposite halves of the mitre planes, and by the same planes it meets above.
	var eave_mid := (corner_north + corner_south) * 0.5
	var up_slope := (apex - eave_mid).normalized()
	var length := (apex - eave_mid).length() + 0.5
	var y_axis := hip_normal
	var z_axis := up_slope
	var x_axis := y_axis.cross(z_axis).normalized()
	var facet_basis := Basis(x_axis, y_axis, z_axis)
	var centre := eave_mid + up_slope * (length * 0.5)
	var to_local := Transform3D(facet_basis, centre).affine_inverse()
	var planes: Array[Plane] = [
		to_local * Plane(-north_mitre.normal, -north_mitre.d),
		to_local * Plane(-south_mitre.normal, -south_mitre.d),
	]
	var facet := MeshInstance3D.new()
	facet.mesh = SuperEgg.build_clipped_mesh(
		Vector3(base_z + 0.8, ROOF_THICKNESS * 0.5, length * 0.5), planes, ROOF_EDGE_EPSILON, ROOF_EDGE_EPSILON,
		ROOF_SEGMENTS, ROOF_RINGS
	)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	facet.material_override = material
	facet.transform = Transform3D(facet_basis, centre)
	body.add_child(facet)
	var up := hip_normal * ROOF_THICKNESS * 0.5
	var points := PackedVector3Array()
	for corner in [apex, corner_south, corner_north]:
		points.append(corner + up)
		points.append(corner - up)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)


## The mitre plane between two slabs that meet along `edge` (a direction through
## `origin`), whose upward surface normals are `normal_a` and `normal_b`: it
## contains the edge and the sum of the two normals. The returned plane retains
## the side holding `keep_point` (a point of slab A's interior).
static func _mitre_plane(origin: Vector3, edge: Vector3, normal_a: Vector3, normal_b: Vector3, keep_point: Vector3) -> Plane:
	var mitre_normal := edge.cross(normal_a + normal_b).normalized()
	var plane := Plane(mitre_normal, mitre_normal.dot(origin))
	if plane.distance_to(keep_point) > 0.0:
		plane = Plane(-mitre_normal, -mitre_normal.dot(origin))
	return plane


## A roof with a square opening at the ridge, for a bell rope to pass through.
## Each slope is three convex pieces (left of the opening, right of it, and the
## part below it) so the opening is a true hole in the roof surface and in its
## collision, with a timber collar framing it. `gap` is {"x": centre along the
## ridge, "half": half the opening's side in plan}. The ridge beam is split too.
static func _build_gapped_roof(
	body: StaticBody3D, ridge_pos: Vector3, width: float, rear_len: float, slope_len: float,
	color: Color, gap: Dictionary, half_wall: float = 0.0, gables: Array = []
) -> void:
	var gap_x := float(gap["x"])
	var half := float(gap["half"])
	var half_total := width * 0.5
	var s_hole := half / cos(ROOF_PITCH)
	var left_width := (gap_x - half) + half_total
	var right_width := half_total - (gap_x + half)
	for north: bool in [true, false]:
		var length := rear_len if north else slope_len
		var left_x := -half_total + left_width * 0.5
		var right_x := half_total - right_width * 0.5
		if north:
			_build_roof_panel(body, ridge_pos, left_width, length, true, color, left_x, 0.0, true, false)
			_build_roof_panel(body, ridge_pos, right_width, length, true, color, right_x, 0.0, false, true)
			_build_roof_panel(body, ridge_pos, half * 2.0, length - s_hole, true, color, gap_x, s_hole, false, false, [], false)
		else:
			_build_front_slope(body, ridge_pos, left_width, length, color, half_wall, gables, left_x, true, false)
			_build_front_slope(body, ridge_pos, right_width, length, color, half_wall, gables, right_x, false, true)
			_build_front_slope(body, ridge_pos, half * 2.0, length - s_hole, color, half_wall, gables, gap_x, false, false, s_hole, false)
	for segment: Vector2 in [Vector2(-half_total, gap_x - half), Vector2(gap_x + half, half_total)]:
		var segment_length := segment.y - segment.x
		var beam := SuperEgg.build_part(
			Vector3(segment_length * 0.5 + 0.03, 0.06, 0.13), color.darkened(0.06), ROOF_EDGE_EPSILON, ROOF_EDGE_EPSILON
		)
		beam.position = ridge_pos + Vector3((segment.x + segment.y) * 0.5, roof_vertical_half() - 0.01, 0.0)
		body.add_child(beam)
		CollisionPolicy.mark_decorative(beam)
	# The collar: four boards standing on edge round the opening, from below the
	# roof slab to a hand above it.
	var collar_bottom := ridge_pos.y - 0.6
	var collar_height := 0.95
	for side: float in [-1.0, 1.0]:
		var along_x := SuperEgg.build_part(Vector3(half + 0.03, collar_height * 0.5, 0.025), color.darkened(0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		along_x.position = Vector3(gap_x, collar_bottom + collar_height * 0.5, side * half)
		body.add_child(along_x)
		CollisionPolicy.mark_decorative(along_x)
		var along_z := SuperEgg.build_part(Vector3(0.025, collar_height * 0.5, half + 0.03), color.darkened(0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		along_z.position = Vector3(gap_x + side * half, collar_bottom + collar_height * 0.5, 0.0)
		body.add_child(along_z)
		CollisionPolicy.mark_decorative(along_z)


## A thick cross beam seaming the two roof panels along the ridge, in the
## roof's own colour. Every gable-roofed building gets one.
const RIDGE_BEAM_HALF := 0.27


static func _build_ridge_beam(body: StaticBody3D, ridge_pos: Vector3, width: float, color: Color, hip_side: float = 0.0) -> void:
	# The slopes meet in a clean mitre, so the cap is only a slim ridge board laid
	# on the seam, not a beam covering a gap.
	var length := width - (HIP_INSET if hip_side != 0.0 else 0.0)
	var beam := SuperEgg.build_part(
		Vector3(length * 0.5 + 0.04, 0.06, 0.13), color.darkened(0.06),
		ROOF_EDGE_EPSILON, ROOF_EDGE_EPSILON
	)
	beam.position = ridge_pos + Vector3(-hip_side * HIP_INSET * 0.5, roof_vertical_half() - 0.01, 0.0)
	body.add_child(beam)
	CollisionPolicy.mark_decorative(beam)


static func _build_roof_panel(
	body: StaticBody3D, ridge_pos: Vector3, width: float, slope_len: float, north: bool, color: Color,
	x_center: float = 0.0, s_start: float = 0.0, round_left: bool = true, round_right: bool = true,
	world_planes: Array[Plane] = [], vertical_ridge: bool = true
) -> void:
	var z_sign := 1.0 if north else -1.0
	var length_dir := Vector3(0, -sin(ROOF_PITCH), z_sign * cos(ROOF_PITCH)).normalized()
	var width_dir := Vector3(1, 0, 0)
	var normal := width_dir.cross(length_dir)
	if normal.y < 0.0:
		normal = -normal
	var panel_basis := Basis(width_dir, normal, length_dir)
	# One SuperEgg slab per slope, longer than the roof where a cut is to be made so
	# the cut (a plane through the solid) leaves a hard planar cap while every free
	# edge keeps the SuperEgg's own squarish shoulder.
	const CUT_EXTENSION := 0.34
	var left_extension := 0.0 if round_left else CUT_EXTENSION
	var right_extension := 0.0 if round_right else CUT_EXTENSION
	var ridge_extension := CUT_EXTENSION
	var offset := Vector3((right_extension - left_extension) * 0.5, 0.0, -ridge_extension * 0.5)
	var panel_pos := ridge_pos + length_dir * (s_start + slope_len * 0.5) + Vector3(x_center, 0.0, 0.0)
	var node_origin := panel_pos + panel_basis * offset
	var to_local := Transform3D(panel_basis, node_origin).affine_inverse()
	var semi_axes := Vector3(
		width * 0.5 + (left_extension + right_extension) * 0.5, ROOF_THICKNESS * 0.5,
		(slope_len + ridge_extension) * 0.5
	)
	var planes: Array[Plane] = []
	if vertical_ridge and s_start == 0.0:
		# The two slopes meet in the vertical plane through the ridge line, so the
		# cut faces coincide exactly: a hard flat edge and a perfect seam.
		planes.append(to_local * Plane(Vector3(0.0, 0.0, -z_sign), -z_sign * ridge_pos.z))
	else:
		var ridge_source_z := -slope_len * 0.5 - offset.z
		planes.append(Plane(Vector3.FORWARD, -ridge_source_z))
	if not round_left:
		planes.append(Plane(Vector3.LEFT, -(-width * 0.5 - offset.x)))
	if not round_right:
		planes.append(Plane(Vector3.RIGHT, width * 0.5 - offset.x))
	for world_plane in world_planes:
		planes.append(to_local * world_plane)
	var panel := MeshInstance3D.new()
	panel.mesh = SuperEgg.build_clipped_mesh(semi_axes, planes, ROOF_EDGE_EPSILON, ROOF_EDGE_EPSILON, ROOF_SEGMENTS, ROOF_RINGS)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel.material_override = material
	panel.transform = Transform3D(panel_basis, node_origin)
	body.add_child(panel)
	# Landable: the player can reach a roof, so it holds them (the slope is well
	# inside CharacterBody3D's floor angle).
	_add_box_collision(body, panel_pos, Vector3(width, ROOF_COLLISION_THICKNESS, slope_len), panel_basis)


## How far a slope slab runs past its ridge before the ridge cut trims it back.
const ROOF_CUT_EXTENSION := 0.34


## One roof slope as a clipped SuperEgg slab: Ohio's refined roof construction,
## shared so every settlement's roofs are built the same way. The shoulders are
## very squarish (ROOF_EDGE_EPSILON) and the mesh is sampled densely enough for
## that corner to be square. `planes` clip it (retained side is distance <= 0,
## in the slab's own frame).
static func roof_slab(semi_axes: Vector3, color: Color, planes: Array[Plane] = []) -> MeshInstance3D:
	var slab := MeshInstance3D.new()
	slab.mesh = SuperEgg.build_clipped_mesh(semi_axes, planes, ROOF_EDGE_EPSILON, ROOF_EDGE_EPSILON, ROOF_SEGMENTS, ROOF_RINGS)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	slab.material_override = material
	return slab


## A slope slab that meets a ridge. It runs past the ridge by ROOF_CUT_EXTENSION
## and is cut along `ridge_plane` (body frame; the retained side is distance <= 0),
## so the two slopes of a gable meet in one hard flat seam and every free edge
## keeps the squarish shoulder. `basis` has x across the slope, y its normal and
## z down or up it; `toward_ridge` is +1 if the ridge lies along +z of the
## basis and -1 if along -z. `centre` is the middle of the visible slab.
static func build_ridge_slab(
	body: Node3D, basis: Basis, centre: Vector3, half_width: float, length: float,
	thickness: float, color: Color, toward_ridge: float, ridge_plane: Plane
) -> MeshInstance3D:
	var origin := centre + basis.z * (toward_ridge * ROOF_CUT_EXTENSION * 0.5)
	var semi := Vector3(half_width, thickness * 0.5, length * 0.5 + ROOF_CUT_EXTENSION * 0.5)
	var to_local := Transform3D(basis, origin).affine_inverse()
	var planes: Array[Plane] = [to_local * ridge_plane]
	var slab := roof_slab(semi, color, planes)
	slab.transform = Transform3D(basis, origin)
	body.add_child(slab)
	return slab


# ---------------------------------------------------------------------------
# Fountain
# ---------------------------------------------------------------------------

const FOUNTAIN_RADIUS := 2.0
const FOUNTAIN_RIM_HEIGHT := 0.55
const FOUNTAIN_RIM_THICKNESS := 0.22
## A small embed into the ground so the rim's own bottom edge never shows
## a gap against the terrain -- NOT how tall the basin is (see the previous
## FOUNTAIN_BASIN_DEPTH, retired): per direct correction, the whole rim
## needs to rise up out of the ground as a real raised wall, not sit mostly
## buried with only a sliver poking up above ground level the way a
## symmetric center-on-ground-level placement did.
const FOUNTAIN_GROUND_EMBED := 0.05
const FOUNTAIN_RIM_SEGMENTS := 16
## How far up the rim's own height (measured from the floor) the water
## surface sits -- comfortably below the rim's top edge so it doesn't read
## as overflowing.
const FOUNTAIN_WATER_HEIGHT_FRACTION := 0.68


## Returns {"root": StaticBody3D, "water_y": float, "gem_y": float} --
## water_y is the water surface's own local Y; gem_y sits a little below
## that (visible through the translucent water rather than floating above
## it) for a floating collectible.
static func build_fountain() -> Dictionary:
	var fountain := StaticBody3D.new()
	fountain.collision_layer = 1
	fountain.collision_mask = 0

	var floor_y := -FOUNTAIN_GROUND_EMBED
	var rim_center_y := FOUNTAIN_RIM_HEIGHT * 0.5 - FOUNTAIN_GROUND_EMBED

	# Basin floor -- a true round (epsilon=2.0, the plain-ellipse case),
	# flattened SuperEgg, inset slightly from the rim's own outer radius so
	# it doesn't poke out past the rim wall.
	var basin := SuperEgg.build_part(
		Vector3(
			FOUNTAIN_RADIUS - FOUNTAIN_RIM_THICKNESS * 0.5, 0.04,
			FOUNTAIN_RADIUS - FOUNTAIN_RIM_THICKNESS * 0.5
		),
		FOUNTAIN_STONE, 2.0, 2.0
	)
	basin.position = Vector3(0, floor_y, 0)
	fountain.add_child(basin)

	# Rim -- a continuous ring of tangent-aligned, chord-width segments (the
	# same technique the old fountain's own invisible collision ring
	# already used -- see the Basis(tangent, UP, radial) construction --
	# just built as real visible geometry too now, and widened slightly
	# past the exact chord so neighboring segments overlap a little instead
	# of leaving a hairline gap at the joints, which is what let water
	# escape ("the sides need to be touching each other to hold water").
	for i in FOUNTAIN_RIM_SEGMENTS:
		var angle := (float(i) / FOUNTAIN_RIM_SEGMENTS) * TAU
		var next_angle := (float(i + 1) / FOUNTAIN_RIM_SEGMENTS) * TAU
		var mid_angle := (angle + next_angle) * 0.5
		var chord := 2.0 * FOUNTAIN_RADIUS * sin((next_angle - angle) * 0.5)
		var tangent := Vector3(-sin(mid_angle), 0.0, cos(mid_angle))
		var radial := Vector3(cos(mid_angle), 0.0, sin(mid_angle))
		var seg_pos := Vector3(radial.x * FOUNTAIN_RADIUS, rim_center_y, radial.z * FOUNTAIN_RADIUS)
		var seg_basis := Basis(tangent, Vector3.UP, radial)
		var seg := SuperEgg.build_part(
			Vector3(chord * 0.56, FOUNTAIN_RIM_HEIGHT * 0.5, FOUNTAIN_RIM_THICKNESS * 0.5), FOUNTAIN_STONE,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		seg.basis = seg_basis
		seg.position = seg_pos
		fountain.add_child(seg)
		_add_box_collision(
			fountain, seg_pos, Vector3(chord * 1.1, FOUNTAIN_RIM_HEIGHT, FOUNTAIN_RIM_THICKNESS * 2.2), seg_basis
		)

	# Water -- doesn't need to be a SuperEgg (per direct instruction), just
	# a real translucent blue material on a plain round mesh, sitting well
	# inside the rim so it's clearly held rather than floating loose over
	# the top.
	var water_y := floor_y + FOUNTAIN_RIM_HEIGHT * FOUNTAIN_WATER_HEIGHT_FRACTION
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = FOUNTAIN_RADIUS - FOUNTAIN_RIM_THICKNESS * 0.7
	water_mesh.bottom_radius = water_mesh.top_radius
	water_mesh.height = 0.04
	water_mesh.radial_segments = 28
	var water := MeshInstance3D.new()
	water.mesh = water_mesh
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = WATER_COLOR
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness = 0.05
	water_material.metallic = 0.15
	water.material_override = water_material
	water.position = Vector3(0, water_y, 0)
	fountain.add_child(water)

	return {"root": fountain, "water_y": water_y, "gem_y": water_y - 0.08}


# ---------------------------------------------------------------------------
# Decorations
# ---------------------------------------------------------------------------

const LANTERN_POST_HEIGHT := 0.55
const LANTERN_HEAD_SIZE := 0.13
const LANTERN_LIGHT_RANGE := 4.5
const OHIO_LANTERN_IRON := Color(0.20, 0.16, 0.12)
const OHIO_LANTERN_STONE := Color(0.58, 0.55, 0.50)

# Dense western-city materials: weathered concrete, oxidized utility steel,
# and a small set of apartment accent colors inspired by stacked, lived-in
# high-rises rather than the village's pitched-roof language.
const CITY_CONCRETE := Color(0.34, 0.36, 0.38)
const CITY_DARK_CONCRETE := Color(0.19, 0.22, 0.25)
const CITY_LIGHT := Color(1.0, 0.67, 0.3)
const CITY_ACCENTS := [
	Color(0.82, 0.16, 0.13), Color(0.1, 0.58, 0.68), Color(0.96, 0.62, 0.12),
	Color(0.8, 0.28, 0.48), Color(0.34, 0.72, 0.32), Color(0.54, 0.3, 0.78),
]


## Named "lanterns" so day_night_cycle.gd can find every instance via
## get_tree().get_nodes_in_group() and drive both the OmniLight3D's energy
## and the head's emission strength from the game clock -- neither is lit
## by anything else, so without that call they'd stay permanently dark
## (the light) or permanently at one fixed brightness (the emission).
static func build_lantern() -> Node3D:
	var lantern := Node3D.new()
	lantern.add_to_group("lanterns")
	var post := SuperEgg.build_part(
		Vector3(0.04, LANTERN_POST_HEIGHT, 0.04), TRIM_WOOD, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	post.position = Vector3(0, LANTERN_POST_HEIGHT, 0)
	lantern.add_child(post)

	var head_position := Vector3(0, LANTERN_POST_HEIGHT * 2.0 + LANTERN_HEAD_SIZE * 0.5, 0)

	var head := SuperEgg.build_part(
		Vector3(LANTERN_HEAD_SIZE, LANTERN_HEAD_SIZE, LANTERN_HEAD_SIZE), LANTERN_GLOW,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	head.name = "Head"
	head.position = head_position
	var head_material := head.get_surface_override_material(0) as StandardMaterial3D
	head_material.emission_enabled = true
	head_material.emission = LANTERN_GLOW
	head_material.emission_energy_multiplier = 1.4
	lantern.add_child(head)

	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = head_position
	light.light_color = LANTERN_GLOW
	light.omni_range = LANTERN_LIGHT_RANGE
	light.shadow_enabled = false
	lantern.add_child(light)

	return lantern


## Ohio's outdoor lights are pieces of civic joinery, not the generic glowing
## bead on a stick above.  A square oak standard rises from a stone foot, a
## bracket projects the light over the path, and a little cap keeps weather off
## the glazed lantern.  The local -Z side is the lit side, so callers can yaw a
## standard toward the street it serves.
static func build_ohio_street_lantern() -> StaticBody3D:
	var lantern := StaticBody3D.new()
	lantern.name = "OhioStreetLantern"
	lantern.collision_layer = 1
	lantern.collision_mask = 0
	lantern.add_to_group("lanterns")

	var plinth := SuperEgg.build_part(
		Vector3(0.31, 0.16, 0.31), OHIO_LANTERN_STONE,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	plinth.position = Vector3(0.0, 0.16, 0.0)
	lantern.add_child(plinth)
	CollisionPolicy.add_box(lantern, plinth, Vector3(0.62, 0.32, 0.62), plinth.position, Basis(), true)

	var post := SuperEgg.build_part(
		Vector3(0.12, 1.22, 0.12), TRIM_WOOD,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	post.position = Vector3(0.0, 1.48, 0.0)
	lantern.add_child(post)
	CollisionPolicy.add_box(lantern, post, Vector3(0.24, 2.44, 0.24), post.position, Basis(), false)

	# A short knee brace makes the projection read as carpentry instead of a
	# floating light.  These small upper members are decorative, while the post
	# itself remains the simple blocking collider.
	var arm := SuperEgg.build_part(
		Vector3(0.09, 0.09, 0.54), TRIM_WOOD.lightened(0.04),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	arm.position = Vector3(0.0, 2.58, -0.46)
	lantern.add_child(arm)
	CollisionPolicy.mark_decorative(arm)
	var brace := SuperEgg.build_part(
		Vector3(0.065, 0.43, 0.065), TRIM_WOOD.darkened(0.04),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	brace.position = Vector3(0.0, 2.27, -0.35)
	brace.rotation.x = deg_to_rad(-43.0)
	lantern.add_child(brace)
	CollisionPolicy.mark_decorative(brace)

	_add_ohio_lantern_head(lantern, Vector3(0.0, 2.30, -0.90), 0.23, 6.2)
	return lantern


## Compact crown used on an already substantial masonry gateway pier.  It has
## no second post, so the entrance reads as a pair of lit stone gate markers
## rather than two lamps balanced on two unrelated sticks.
static func build_ohio_pier_lantern() -> Node3D:
	var lantern := Node3D.new()
	lantern.name = "OhioPierLantern"
	lantern.add_to_group("lanterns")
	var foot := SuperEgg.build_part(
		Vector3(0.30, 0.07, 0.30), OHIO_LANTERN_IRON,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	foot.position = Vector3(0.0, 0.07, 0.0)
	lantern.add_child(foot)
	CollisionPolicy.mark_decorative(foot)
	_add_ohio_lantern_head(lantern, Vector3(0.0, 0.37, 0.0), 0.25, 6.0)
	return lantern


## A modest wall bracket for public thresholds.  The root sits on a facade and
## local -Z points out from it.  It shares the same cap, cage and warm glazing
## as the freestanding standards, so the town has one fixture family.
static func build_ohio_wall_lantern() -> Node3D:
	var lantern := Node3D.new()
	lantern.name = "OhioWallLantern"
	lantern.add_to_group("lanterns")
	var backplate := SuperEgg.build_part(
		Vector3(0.19, 0.29, 0.055), OHIO_LANTERN_IRON,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	backplate.position = Vector3(0.0, 0.0, 0.0)
	lantern.add_child(backplate)
	CollisionPolicy.mark_decorative(backplate)
	var bracket := SuperEgg.build_part(
		Vector3(0.055, 0.055, 0.26), TRIM_WOOD,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	bracket.position = Vector3(0.0, 0.12, -0.25)
	lantern.add_child(bracket)
	CollisionPolicy.mark_decorative(bracket)
	_add_ohio_lantern_head(lantern, Vector3(0.0, -0.11, -0.49), 0.18, 4.8)
	return lantern


static func _add_ohio_lantern_head(parent: Node3D, at: Vector3, half_size: float, light_range: float) -> void:
	var head := SuperEgg.build_part(
		Vector3(half_size, half_size * 1.12, half_size), LANTERN_GLOW,
		3.2, SuperEgg.EPSILON_SOFT
	)
	head.name = "Head"
	head.position = at
	var head_material := head.get_surface_override_material(0) as StandardMaterial3D
	head_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	head_material.albedo_color = Color(LANTERN_GLOW.r, LANTERN_GLOW.g, LANTERN_GLOW.b, 0.72)
	head_material.emission_enabled = true
	head_material.emission = LANTERN_GLOW
	head_material.emission_energy_multiplier = 1.4
	parent.add_child(head)
	CollisionPolicy.mark_decorative(head)

	# Four dark cage uprights and a shallow weather cap give the glow a visible
	# scale and silhouette by day.  They remain decorative because the whole
	# fixture is far smaller than a character.
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			var rail := SuperEgg.build_part(
				Vector3(0.025, half_size * 1.18, 0.025), OHIO_LANTERN_IRON,
				SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			rail.position = at + Vector3(x * half_size * 0.86, 0.0, z * half_size * 0.86)
			parent.add_child(rail)
			CollisionPolicy.mark_decorative(rail)
	var cap := SuperEgg.build_part(
		Vector3(half_size * 1.28, 0.065, half_size * 1.28), OHIO_LANTERN_IRON,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	cap.position = at + Vector3(0.0, half_size * 1.27, 0.0)
	parent.add_child(cap)
	CollisionPolicy.mark_decorative(cap)
	var finial := SuperEgg.build_part(
		Vector3(0.065, 0.10, 0.065), OHIO_LANTERN_IRON,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	finial.position = cap.position + Vector3(0.0, 0.15, 0.0)
	parent.add_child(finial)
	CollisionPolicy.mark_decorative(finial)

	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = at
	light.light_color = LANTERN_GLOW
	light.omni_range = light_range
	light.shadow_enabled = false
	parent.add_child(light)


## Dedicated high-mast city streetlight: a tall steel pole, an angled arm
## projecting over the roadway, and a warm head at the arm's end. It keeps
## the village lantern group's exact node contract so day/night lighting
## continues to drive it without a second system.
static func build_city_streetlight() -> Node3D:
	const POLE_HEIGHT := 5.2
	const ARM_LENGTH := 1.8
	var lightpost := Node3D.new()
	lightpost.add_to_group("lanterns")
	lightpost.add_to_group("city_streetlights")
	var base := SuperEgg.build_part(Vector3(0.22, 0.12, 0.22), CITY_DARK_CONCRETE, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	base.position = Vector3(0, 0.12, 0)
	lightpost.add_child(base)
	var pole := SuperEgg.build_part(Vector3(0.075, POLE_HEIGHT * 0.5, 0.075), CITY_DARK_CONCRETE, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	pole.position = Vector3(0, POLE_HEIGHT * 0.5, 0)
	lightpost.add_child(pole)
	var arm := SuperEgg.build_part(Vector3(0.07, 0.07, ARM_LENGTH * 0.5), CITY_DARK_CONCRETE, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	arm.position = Vector3(0, POLE_HEIGHT - 0.18, -ARM_LENGTH * 0.5)
	arm.rotation.x = deg_to_rad(-8.0)
	lightpost.add_child(arm)
	var head := SuperEgg.build_part(Vector3(0.18, 0.09, 0.24), LANTERN_GLOW, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	head.name = "Head"
	head.position = Vector3(0, POLE_HEIGHT - 0.42, -ARM_LENGTH)
	var head_material := head.get_surface_override_material(0) as StandardMaterial3D
	head_material.emission_enabled = true
	head_material.emission = LANTERN_GLOW
	head_material.emission_energy_multiplier = 1.4
	lightpost.add_child(head)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = head.position
	light.light_color = LANTERN_GLOW
	light.omni_range = 8.5
	light.shadow_enabled = false
	lightpost.add_child(light)
	return lightpost


## A compact high-rise with a real collision floor on every storey, one varied
## apartment fixture per storey, and a switchback fire escape. The exterior
## access route turns the whole facade into playable vertical level geometry:
## each ramp rises only one storey and terminates on a landable balcony.
static func build_city_building(w: int, d: int, floors: int, accent: Color, light_seed: int = 0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var width := float(w) * CELL_SIZE
	var depth := float(d) * CELL_SIZE
	var half_w := width * 0.5
	var half_d := depth * 0.5
	# A fixed per-building seed creates a varied lived-in pattern that stays
	# stable through rebuilds instead of windows flickering randomly on load.
	var room_rng := RandomNumberGenerator.new()
	room_rng.seed = light_seed * 7919 + w * 101 + d * 17

	for floor_index in floors:
		var y := float(floor_index) * FLOOR_HEIGHT
		# Floors remain individually solid, but their repeated visuals are drawn
		# as one MultiMesh per tower rather than one draw call per storey.
		_queue_city_floor(body, Vector3(0, y, 0), Vector3(width, 0.14, depth))
		_add_box_collision(body, Vector3(0, y, 0), Vector3(width, FLOOR_COLLISION_THICKNESS, depth))

		var facade_color := CITY_CONCRETE if floor_index % 3 != 2 else CITY_DARK_CONCRETE
		# Side and rear facades are solid; the front is divided around an open
		# central doorway that meets the fire-escape balcony each storey.
		_city_side_facade(body, -half_w, y, depth, facade_color, accent)
		_city_side_facade(body, half_w, y, depth, facade_color, accent)
		_city_back_facade(body, y, width, half_d, facade_color, accent)
		var opening_width := 1.55
		var side_width := (width - opening_width) * 0.5
		_city_panel(body, Vector3(-(opening_width + side_width) * 0.5, y + FLOOR_HEIGHT * 0.5, -half_d), Vector3(side_width, FLOOR_HEIGHT, WALL_THICKNESS), facade_color)
		_city_panel(body, Vector3((opening_width + side_width) * 0.5, y + FLOOR_HEIGHT * 0.5, -half_d), Vector3(side_width, FLOOR_HEIGHT, WALL_THICKNESS), facade_color)
		if floor_index % 4 == 1:
			var stripe := SuperEgg.build_part(Vector3(width * 0.5 + 0.04, 0.08, 0.06), accent, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			stripe.position = Vector3(0, y + 0.18, -half_d - 0.04)
			body.add_child(stripe)
		# One randomly positioned fixture per floor keeps the inhabited, varied
		# look while removing two-thirds of the city room nodes and fixtures.
		var lit_room_index := room_rng.randi_range(0, w - 1)
		var fixture_room_x := (float(lit_room_index) - float(w - 1) * 0.5) * CELL_SIZE
		# The fixture's 12 cm body meets the underside of the next floor plate,
		# so it reads as ceiling-mounted instead of floating in the room.
		_city_room_light(body, Vector3(fixture_room_x, y + FLOOR_HEIGHT - 0.13, 0), room_rng.randf() < 0.62)
		_city_fire_escape(body, floor_index, width, half_d, y)
		_city_balcony_and_ac(body, floor_index, half_w, y, accent)

	# Flat rooftop is a final platform and landing from the last fire-escape.
	var roof := SuperEgg.build_part(Vector3(half_w + 0.18, 0.12, half_d + 0.18), CITY_DARK_CONCRETE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	roof.position = Vector3(0, float(floors) * FLOOR_HEIGHT, 0)
	body.add_child(roof)
	_add_box_collision(body, roof.position, Vector3(width + 0.36, 0.3, depth + 0.36))
	_build_city_roof_ramp(body, half_d, floors)
	_build_city_floor_batch(body)
	_build_city_panel_batches(body)
	_build_city_wall_collision(body)
	return body


static func _city_panel(body: StaticBody3D, pos: Vector3, size: Vector3, color: Color) -> void:
	# The facade is still divided around every playable opening. Instead of
	# creating a MeshInstance and CollisionShape for every tiny wall segment,
	# queue it for a two-material MultiMesh and one combined static collider.
	var panel_key := "city_panels_dark" if color == CITY_DARK_CONCRETE else "city_panels_light"
	var panels: Array = body.get_meta(panel_key, [])
	panels.append({"position": pos, "size": size})
	body.set_meta(panel_key, panels)
	var wall_boxes: Array = body.get_meta("city_wall_boxes", [])
	wall_boxes.append({"position": pos, "size": size})
	body.set_meta("city_wall_boxes", wall_boxes)


static func _queue_city_floor(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var floors: Array = body.get_meta("city_floor_plates", [])
	floors.append({"position": pos, "size": size})
	body.set_meta("city_floor_plates", floors)


static func _build_city_floor_batch(body: StaticBody3D) -> void:
	_build_city_box_batch(body, "city_floor_plates", FLOOR_COLOR, "FloorPlates")


static func _build_city_panel_batches(body: StaticBody3D) -> void:
	_build_city_box_batch(body, "city_panels_light", CITY_CONCRETE, "LightFacade")
	_build_city_box_batch(body, "city_panels_dark", CITY_DARK_CONCRETE, "DarkFacade")


## All queued panels with a shared color use a single instanced mesh. The
## source mesh is a unit-size flat superegg so the transform supplies each
## panel's original dimensions exactly.
static func _build_city_box_batch(body: StaticBody3D, meta_key: String, color: Color, node_name: String) -> void:
	var boxes: Array = body.get_meta(meta_key, [])
	if boxes.is_empty():
		return
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = boxes.size()
	multimesh.mesh = SuperEgg.build_mesh(Vector3(0.5, 0.5, 0.5), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	for index in boxes.size():
		var box: Dictionary = boxes[index]
		var box_pos: Vector3 = box["position"]
		var box_size: Vector3 = box["size"]
		multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY.scaled(box_size), box_pos))
	var batch := MultiMeshInstance3D.new()
	batch.name = node_name
	batch.multimesh = multimesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	batch.material_override = material
	body.add_child(batch)
	body.remove_meta(meta_key)


## Preserve every wall and every opening while reducing the city facade from
## thousands of broadphase objects to one static concave shape per building.
## Concave collision is safe here because these walls never move; it also
## matches the terrain's proven collision strategy.
static func _build_city_wall_collision(body: StaticBody3D) -> void:
	var wall_boxes: Array = body.get_meta("city_wall_boxes", [])
	if wall_boxes.is_empty():
		return
	var faces := PackedVector3Array()
	for entry in wall_boxes:
		var box: Dictionary = entry
		var box_pos: Vector3 = box["position"]
		var box_size: Vector3 = box["size"]
		_append_city_box_faces(faces, box_pos, box_size)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collision := CollisionShape3D.new()
	collision.name = "FacadeCollision"
	collision.shape = shape
	body.add_child(collision)
	body.remove_meta("city_wall_boxes")


static func _append_city_box_faces(faces: PackedVector3Array, center: Vector3, size: Vector3) -> void:
	var half := size * 0.5
	var nnn := center + Vector3(-half.x, -half.y, -half.z)
	var nnp := center + Vector3(-half.x, -half.y, half.z)
	var npn := center + Vector3(-half.x, half.y, -half.z)
	var npp := center + Vector3(-half.x, half.y, half.z)
	var pnn := center + Vector3(half.x, -half.y, -half.z)
	var pnp := center + Vector3(half.x, -half.y, half.z)
	var ppn := center + Vector3(half.x, half.y, -half.z)
	var ppp := center + Vector3(half.x, half.y, half.z)
	_append_city_quad(faces, nnn, pnn, ppn, npn) # -Z
	_append_city_quad(faces, pnp, nnp, npp, ppp) # +Z
	_append_city_quad(faces, nnp, nnn, npn, npp) # -X
	_append_city_quad(faces, pnn, pnp, ppp, ppn) # +X
	_append_city_quad(faces, nnn, nnp, pnp, pnn) # -Y
	_append_city_quad(faces, npn, ppn, ppp, npp) # +Y


static func _append_city_quad(faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	faces.append(a)
	faces.append(b)
	faces.append(c)
	faces.append(a)
	faces.append(c)
	faces.append(d)


## A compact enclosed connector for city towers. It is deliberately a real
## platform route: floor, ceiling, and side walls all have collision, while
## the open ends meet the existing person-sized side openings of the towers.
static func build_city_skybridge(length: float, width: float, accent: Color) -> StaticBody3D:
	const CLEAR_HEIGHT := 2.25
	const WALL_DEPTH := 0.12
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var floor := SuperEgg.build_part(Vector3(length * 0.5, 0.1, width * 0.5), CITY_DARK_CONCRETE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	floor.position = Vector3(0, 0, 0)
	body.add_child(floor)
	_add_box_collision(body, floor.position, Vector3(length, FLOOR_COLLISION_THICKNESS, width))
	var roof := SuperEgg.build_part(Vector3(length * 0.5, 0.08, width * 0.5), CITY_CONCRETE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	roof.position = Vector3(0, CLEAR_HEIGHT, 0)
	body.add_child(roof)
	_add_box_collision(body, roof.position, Vector3(length, 0.16, width))
	for side in [-1.0, 1.0]:
		var wall := SuperEgg.build_part(Vector3(length * 0.5, CLEAR_HEIGHT * 0.5, WALL_DEPTH * 0.5), CITY_CONCRETE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		wall.position = Vector3(0, CLEAR_HEIGHT * 0.5, side * (width * 0.5 - WALL_DEPTH * 0.5))
		body.add_child(wall)
		_add_box_collision(body, wall.position, Vector3(length, CLEAR_HEIGHT, WALL_DEPTH))
	# Two narrow colored bands make the enclosed route legible from the street
	# without restoring the removed blue-glass window treatment.
	for side in [-1.0, 1.0]:
		var stripe := SuperEgg.build_part(Vector3(length * 0.5, 0.06, 0.035), accent, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		stripe.position = Vector3(0, CLEAR_HEIGHT * 0.68, side * (width * 0.5 + 0.01))
		body.add_child(stripe)
	return body


## Side and rear windows are actual person-sized openings: the facade is
## built around them rather than putting a decorative pane on a solid wall.
## The bright trim makes them legible from across the tight city streets.
static func _city_side_facade(body: StaticBody3D, x: float, y: float, depth: float, color: Color, accent: Color) -> void:
	const OPENING_WIDTH := 1.7
	const OPENING_HEIGHT := 1.9
	var side_span := (depth - OPENING_WIDTH) * 0.5
	_city_panel(body, Vector3(x, y + 0.18, 0), Vector3(WALL_THICKNESS, 0.36, depth), color)
	_city_panel(body, Vector3(x, y + FLOOR_HEIGHT - 0.17, 0), Vector3(WALL_THICKNESS, 0.34, depth), color)
	for side in [-1.0, 1.0]:
		_city_panel(body, Vector3(x, y + FLOOR_HEIGHT * 0.5, side * (OPENING_WIDTH + side_span) * 0.5), Vector3(WALL_THICKNESS, FLOOR_HEIGHT, side_span), color)
		var trim := SuperEgg.build_part(Vector3(0.05, OPENING_HEIGHT * 0.5, 0.05), accent, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		trim.position = Vector3(x + signf(x) * 0.04, y + 0.36 + OPENING_HEIGHT * 0.5, side * OPENING_WIDTH * 0.5)
		body.add_child(trim)


static func _city_back_facade(body: StaticBody3D, y: float, width: float, half_d: float, color: Color, accent: Color) -> void:
	const OPENING_WIDTH := 1.7
	var side_width := (width - OPENING_WIDTH) * 0.5
	_city_panel(body, Vector3(0, y + 0.18, half_d), Vector3(width, 0.36, WALL_THICKNESS), color)
	_city_panel(body, Vector3(0, y + FLOOR_HEIGHT - 0.17, half_d), Vector3(width, 0.34, WALL_THICKNESS), color)
	for side in [-1.0, 1.0]:
		_city_panel(body, Vector3(side * (OPENING_WIDTH + side_width) * 0.5, y + FLOOR_HEIGHT * 0.5, half_d), Vector3(side_width, FLOOR_HEIGHT, WALL_THICKNESS), color)
	var lintel := SuperEgg.build_part(Vector3(OPENING_WIDTH * 0.5, 0.05, 0.05), accent, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	lintel.position = Vector3(0, y + FLOOR_HEIGHT - 0.34, half_d + 0.04)
	body.add_child(lintel)


static func _city_room_light(body: StaticBody3D, pos: Vector3, lit: bool) -> void:
	# An off room has neither a visible fixture nor a light to update. Skipping
	# the node outright makes the randomized dark floors genuinely free.
	if not lit:
		return
	# Each surviving fixture is its own grouped node, exactly like a village
	# lantern. This lets day_night_cycle.gd fade active interior lighting.
	var lamp := Node3D.new()
	lamp.add_to_group("lanterns")
	lamp.add_to_group("city_room_lights")
	lamp.set_meta("room_lit", true)
	lamp.position = pos
	body.add_child(lamp)
	var fixture := SuperEgg.build_part(Vector3(0.13, 0.06, 0.13), CITY_LIGHT, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	fixture.name = "Head"
	var material := fixture.get_surface_override_material(0) as StandardMaterial3D
	material.emission_enabled = true
	material.emission = CITY_LIGHT
	material.emission_energy_multiplier = 1.1
	lamp.add_child(fixture)


## Physical apartment lights are created on demand by city_generator.gd's
## proximity LOD. The emissive fixture remains cheap visual proof of a lit
## room while distant towers avoid constructing hundreds of OmniLight3Ds.
static func ensure_city_room_light(lamp: Node3D) -> void:
	if lamp.has_node("Light"):
		return
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = CITY_LIGHT
	light.omni_range = 4.2
	light.light_energy = 0.8
	light.shadow_enabled = false
	lamp.add_child(light)


static func _city_fire_escape(body: StaticBody3D, floor_index: int, width: float, half_d: float, y: float) -> void:
	# Midpoint between the original compact landing and the wider first fix:
	# enough to catch the ramp, without turning each floor into a broad deck.
	var balcony := SuperEgg.build_part(Vector3(width * 0.29, 0.1, 0.65), CITY_DARK_CONCRETE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	balcony.position = Vector3(0, y + 0.03, -half_d - 0.62)
	body.add_child(balcony)
	_add_box_collision(body, balcony.position, Vector3(width * 0.58, 0.22, 1.3))
	# Alternate the escape's depth on every storey. Both lanes sit clear of
	# the balcony plane, leaving headroom under every horizontal landing.
	# The balcony remains tight to the building; do not extend a catwalk over
	# the ramp, which would recreate the head-bumping obstruction.
	var ramp_z := -half_d - (2.85 if floor_index % 2 == 0 else 1.85)
	if floor_index == 0:
		return
	# Keep both ramp ends above the balcony's landing footprint. This makes
	# every storey a continuous reachable route instead of a visual escape
	# stair whose endpoints would overshoot the platform.
	# Midpoint run keeps the compact fire-escape profile while holding a
	# narrow-tower slope near 41 degrees rather than the old unwalkable 48.
	var run := maxf(width * 0.42, 3.0)
	var goes_right := floor_index % 2 == 1
	var ramp := build_ramp(1.25, run, FLOOR_HEIGHT, CITY_DARK_CONCRETE)
	ramp.position = Vector3(-run * 0.5 if goes_right else run * 0.5, y - FLOOR_HEIGHT, ramp_z)
	ramp.rotation.y = PI * 0.5 if goes_right else -PI * 0.5
	body.add_child(ramp)


## Final vertical link: rises from the top fire-escape landing, through the
## already-open central facade, and finishes directly on the flat roof. This
## prevents the highest balcony becoming a dead end in the platform route.
static func _build_city_roof_ramp(body: StaticBody3D, half_d: float, floors: int) -> void:
	var ramp := build_ramp(1.25, 3.5, FLOOR_HEIGHT, CITY_DARK_CONCRETE)
	ramp.position = Vector3(0, float(floors - 1) * FLOOR_HEIGHT, -half_d - 0.62)
	body.add_child(ramp)


## Alternating balconies and air-conditioning units extend the vertical route
## onto all facades. AC housings have real collision, so they are compact
## jump platforms rather than scenery painted onto the wall.
static func _city_balcony_and_ac(body: StaticBody3D, floor_index: int, half_w: float, y: float, accent: Color) -> void:
	var side := -1.0 if floor_index % 2 == 0 else 1.0
	if floor_index % 3 == 0:
		var balcony := SuperEgg.build_part(Vector3(0.72, 0.1, 1.05), accent.darkened(0.35), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		balcony.position = Vector3(side * (half_w + 0.65), y + 0.06, 0)
		body.add_child(balcony)
		_add_box_collision(body, balcony.position, Vector3(1.44, 0.22, 2.1))
	if floor_index % 2 == 1:
		var ac := SuperEgg.build_part(Vector3(0.48, 0.28, 0.3), CITY_DARK_CONCRETE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		ac.position = Vector3(side * (half_w + 0.3), y + 0.58, 0.0)
		body.add_child(ac)
		_add_box_collision(body, ac.position, Vector3(0.96, 0.56, 0.6))


static func build_fence_segment(color: Color = TRIM_WOOD) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	for x in [-0.45, 0.45]:
		var post := SuperEgg.build_part(
			Vector3(0.04, 0.35, 0.04), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		post.position = Vector3(x, 0.35, 0)
		body.add_child(post)
	for y in [0.25, 0.5]:
		var rail := SuperEgg.build_part(
			Vector3(0.5, 0.03, 0.03), color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		rail.position = Vector3(0, y, 0)
		body.add_child(rail)
	_add_box_collision(body, Vector3(0, 0.25, 0), Vector3(1.0, 0.5, 0.12))
	return body


const STALL_COUNTER_Y := 0.75


## Returns {"body": StaticBody3D, "counter_y": float}.
static func build_stall(canopy_color: Color) -> Dictionary:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var counter := SuperEgg.build_part(
		Vector3(0.6, 0.04, 0.4), TRIM_WOOD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	counter.position = Vector3(0, STALL_COUNTER_Y, 0)
	body.add_child(counter)

	for x in [-0.5, 0.5]:
		for z in [-0.32, 0.32]:
			var leg := SuperEgg.build_part(
				Vector3(0.03, STALL_COUNTER_Y * 0.5, 0.03), TRIM_WOOD,
				SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
			)
			leg.position = Vector3(x, STALL_COUNTER_Y * 0.5, z)
			body.add_child(leg)

	for x in [-0.55, 0.55]:
		var canopy_post := SuperEgg.build_part(
			Vector3(0.04, 0.78, 0.04), TRIM_WOOD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		canopy_post.position = Vector3(x, 0.78, -0.35)
		body.add_child(canopy_post)

	var canopy := SuperEgg.build_part(
		Vector3(0.7, 0.05, 0.5), canopy_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	var canopy_pos := Vector3(0, 1.58, -0.35)
	canopy.position = canopy_pos
	body.add_child(canopy)

	_add_box_collision(body, Vector3(0, 0.45, 0), Vector3(1.25, 0.9, 0.85))
	# The canopy roof is landable too, per direct instruction -- padded a bit
	# thicker than its own thin visual slab for a more forgiving landing
	# collider, same reasoning as TownProps' building roofs.
	_add_box_collision(body, canopy_pos, Vector3(1.5, 0.3, 1.1))
	return {"body": body, "counter_y": STALL_COUNTER_Y}


## Shared market-stall blocking. Local -Z is the post/canopy-back side and
## local +Z is the customer approach, so a vendor belongs just beyond one
## counter end and slightly forward—not behind the displayed wares. The
## returned facing points diagonally into the approach lane, keeping both
## seller and merchandise readable while guaranteeing body clearance from
## the counter footprint. Wider equipment pavilions only need supply their
## own half-width; the placement rule remains identical.
static func vendor_layout(
	stall_position: Vector2,stall_yaw: float,counter_half_width: float=0.6
) -> Dictionary:
	const BODY_CLEARANCE := 0.48
	const FORWARD_OFFSET := 0.52
	const CUSTOMER_DEPTH := 1.25
	var local_vendor:=Vector2(counter_half_width+BODY_CLEARANCE,FORWARD_OFFSET)
	var local_customer:=Vector2(0.0,CUSTOMER_DEPTH)
	# Vector2.rotated() is counter-clockwise in X/Y, while Godot's 3D yaw
	# maps local X/Z with the opposite sign. Using +yaw mirrored every vendor
	# across the stall and is why some sellers faced or stood behind the wares.
	var vendor_position:=stall_position+local_vendor.rotated(-stall_yaw)
	var customer_position:=stall_position+local_customer.rotated(-stall_yaw)
	var facing:=customer_position-vendor_position
	return {
		"position": vendor_position,
		"facing_degrees": rad_to_deg(atan2(facing.x,facing.y)),
	}


## Full-size equipment cannot plausibly share the low, narrow produce-stall
## silhouette above. The armorer gets a broad pavilion with a raised canopy,
## an extra-deep counter, and a rear display rail: enough clear volume for a
## real torso-sized breastplate and an upright sword without either piercing
## the roof.
static func build_armorer_stall(canopy_color: Color) -> Dictionary:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	const COUNTER_Y := 0.88
	const HALF_WIDTH := 1.45
	const HALF_DEPTH := 0.52

	var counter := SuperEgg.build_part(
		Vector3(HALF_WIDTH, 0.065, HALF_DEPTH), TRIM_WOOD,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	counter.position.y = COUNTER_Y
	body.add_child(counter)

	for x in [-1.28, 1.28]:
		for z in [-0.42, 0.42]:
			var leg := SuperEgg.build_part(
				Vector3(0.055, COUNTER_Y * 0.5, 0.055), TRIM_WOOD,
				SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
			)
			leg.position = Vector3(x, COUNTER_Y * 0.5, z)
			body.add_child(leg)

	for x in [-1.38, 1.38]:
		var post := SuperEgg.build_part(
			Vector3(0.065, 1.38, 0.065), TRIM_WOOD,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		post.position = Vector3(x, 1.38, -0.46)
		body.add_child(post)

	# Rear rails visually organize the large wares without enclosing the stall
	# or obscuring the armorer behind a solid wall.
	for rail_y in [1.18, 1.82]:
		var rail := SuperEgg.build_part(
			Vector3(1.34, 0.035, 0.04), TRIM_WOOD,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		rail.position = Vector3(0.0, rail_y, -0.46)
		body.add_child(rail)

	var canopy_position := Vector3(0.0, 2.78, -0.24)
	var canopy := SuperEgg.build_part(
		Vector3(1.62, 0.07, 0.72), canopy_color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	canopy.position = canopy_position
	body.add_child(canopy)

	_add_box_collision(body, Vector3(0.0, 0.48, 0.0), Vector3(2.95, 0.96, 1.12))
	_add_box_collision(body, canopy_position, Vector3(3.35, 0.28, 1.58))
	return {"body": body, "counter_y": COUNTER_Y}


## A working grain mill: broad masonry millhouse, timber upper machinery
## storey and a continuously turning four-sail rotor. The former narrow tower
## had neither working floor area nor any plausible place for grain or stones.
static func build_windmill() -> StaticBody3D:
	# A compact two-stage smock mill you can walk into. The masonry ground stage
	# carries the stones; the lighter timber-smock stage carries the gearing and
	# hoist. Its octagonal construction is structural rather than merely a
	# faceted decoration: rounded corner posts bind the panels and a single soft
	# cap is centred on precisely the same axis.
	const APOTHEM := 2.9
	const STONE_HEIGHT := 3.25
	const HEIGHT := 8.1
	const WALL := 0.45
	var roof := ROOF_COLORS[0]
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var side := 2.0 * APOTHEM * tan(PI / 8.0)
	# Mitred so adjacent thick panels meet on the outer corner without nubs.
	var panel_length := side + WALL * tan(PI / 8.0) + 0.02
	for i in 8:
		var yaw := PI / 4.0 * float(i)
		var outward := Vector3(-sin(yaw), 0.0, -cos(yaw))
		var origin := outward * APOTHEM
		var lower_openings: Array[Dictionary] = []
		var upper_openings: Array[Dictionary] = []
		match i:
			0:
				lower_openings.append({"kind": "door", "center": 0.0, "width": DOOR_WIDTH, "bottom": 0.0, "top": DOOR_HEIGHT, "leaves": 1})
			2, 6:
				lower_openings.append(_window_opening(0.0, 0.0, "window"))
				upper_openings.append(_window_opening(STONE_HEIGHT, 0.0, "window"))
			1, 3, 5, 7:
				upper_openings.append(_window_opening(STONE_HEIGHT, 0.0, "window"))
		_build_panel_facade(body, panel_length, origin, yaw, WALL_STONE, lower_openings, 0.0, STONE_HEIGHT, WALL)
		var upper_origin := origin + Vector3.UP * STONE_HEIGHT
		_build_panel_facade(body, panel_length, upper_origin, yaw, WALL_WOOD.lightened(0.08), upper_openings, STONE_HEIGHT, HEIGHT - STONE_HEIGHT, WALL)
		for opening in lower_openings:
			_build_panel_opening_trim(body, origin, yaw, opening, 0.0, TRIM_WOOD, WALL)
		for opening in upper_openings:
			_build_panel_opening_trim(body, upper_origin, yaw, opening, STONE_HEIGHT, TRIM_WOOD, WALL)
	_octagon_prism(body, APOTHEM - WALL * 0.5, 0.0, 0.2, FLOOR_COLOR)
	# Rounded oak posts soften and truthfully cover every panel joint. A broad
	# belt at the stage change makes the stone base and timber smock read as one
	# inherited building rather than stacked unrelated shapes.
	var corner_radius := APOTHEM / cos(PI / 8.0)
	for i in 8:
		var angle := -PI * 0.5 + PI / 8.0 + TAU * float(i) / 8.0
		var post := SuperEgg.build_part(Vector3(0.18, HEIGHT * 0.5, 0.18), TRIM_WOOD, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		post.position = Vector3(cos(angle) * corner_radius, HEIGHT * 0.5, sin(angle) * corner_radius)
		body.add_child(post)
		_add_box_collision(body, post.position, Vector3(0.36, HEIGHT, 0.36))
	for i in 8:
		var yaw := PI / 4.0 * float(i)
		var outward := Vector3(-sin(yaw), 0.0, -cos(yaw))
		var belt := SuperEgg.build_part(Vector3(panel_length * 0.5 + 0.05, 0.12, 0.12), TRIM_WOOD, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		belt.position = outward * (APOTHEM + WALL * 0.5) + Vector3.UP * STONE_HEIGHT
		belt.rotation.y = yaw
		body.add_child(belt)
		CollisionPolicy.mark_decorative(belt)
	# A soft boat-cap replaces the misaligned faceted cone. It overlaps the
	# wall heads deliberately, so no daylight seam can appear around the eaves.
	var cap := SuperEgg.build_part(Vector3(APOTHEM + 0.5, 0.82, APOTHEM + 0.5), roof, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	cap.position=Vector3(0,HEIGHT+0.46,0)
	body.add_child(cap)
	_add_box_collision(body,Vector3(0,HEIGHT+0.12,0),Vector3((APOTHEM+0.5)*1.72,0.28,(APOTHEM+0.5)*1.72))
	var finial := SuperEgg.build_part(Vector3(0.1, 0.35, 0.1), TRIM_WOOD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	finial.position = Vector3(0,HEIGHT+1.42,0)
	body.add_child(finial)
	CollisionPolicy.mark_decorative(finial)
	EntryDressing.lean_to(body, 0.0, 2.8, 1.2, -(APOTHEM + WALL * 0.5), 2.95, 14.0, roof, TRIM_WOOD, WALL_STONE, 2)

	# The windshaft, brake wheel and sails are one rotating assembly. The shaft
	# visibly penetrates the cap and terminates at the gear stage instead of
	# ending as an unrelated exterior decoration.
	const HUB_Y := 7.25
	var hub := WindmillRotor.new()
	hub.position = Vector3(0, HUB_Y, APOTHEM + WALL * 0.5 + 0.6)
	body.add_child(hub)
	var hub_block := SuperEgg.build_part(Vector3(0.42, 0.42, 0.4), TRIM_WOOD.darkened(0.1), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	hub.add_child(hub_block)
	CollisionPolicy.mark_decorative(hub_block)
	for i in 4:
		var arm := Node3D.new()
		arm.rotation.z = deg_to_rad(90.0 * i + 45.0)
		hub.add_child(arm)
		_build_mill_sail(arm)
	var shaft_length := APOTHEM + WALL * 0.5 + 2.9
	var shaft := SuperEgg.build_part(Vector3(0.16, 0.16, shaft_length * 0.5), TRIM_WOOD.darkened(0.2), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	shaft.position = Vector3(0, 0, -shaft_length * 0.5 + 0.25)
	hub.add_child(shaft)
	CollisionPolicy.mark_decorative(shaft)
	_add_mill_wheel(hub, Vector3(0, 0, -shaft_length + 1.55), 1.12, 0.11, TRIM_WOOD)
	var drive := _build_mill_works(body)
	hub.add_driven_part(drive["upright"] as Node3D, Vector3.UP, -2.1)
	hub.add_driven_part(drive["great_spur"] as Node3D, Vector3.UP, -2.1)
	hub.add_driven_part(drive["stone_nut"] as Node3D, Vector3.UP, 4.2)
	hub.add_driven_part(drive["runner"] as Node3D, Vector3.UP, 4.2)
	return body


## A flat regular octagon (inscribed apothem `apothem`) slab with a convex
## collider, its top face at y_bottom + thickness.
static func _octagon_prism(
	body: StaticBody3D, apothem: float, y_bottom: float, thickness: float, color: Color
) -> void:
	var circumradius := apothem / cos(PI / 8.0)
	var ring: Array[Vector2] = []
	for i in 8:
		var angle := PI / 8.0 + TAU * float(i) / 8.0
		ring.append(Vector2(cos(angle), sin(angle)) * circumradius)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := y_bottom + thickness
	for i in 8:
		var a := ring[i]
		var b := ring[(i + 1) % 8]
		for point: Vector2 in [Vector2.ZERO, b, a]:
			tool.set_normal(Vector3.UP)
			tool.add_vertex(Vector3(point.x, top, point.y))
		for point: Vector2 in [Vector2.ZERO, a, b]:
			tool.set_normal(Vector3.DOWN)
			tool.add_vertex(Vector3(point.x, y_bottom, point.y))
		var edge := (b - a).normalized()
		var normal := Vector3(edge.y, 0.0, -edge.x)
		for pair: Array in [[a, top], [a, y_bottom], [b, top], [b, top], [a, y_bottom], [b, y_bottom]]:
			var p: Vector2 = pair[0]
			tool.set_normal(normal)
			tool.add_vertex(Vector3(p.x, pair[1], p.y))
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = material
	body.add_child(mesh)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	var points := PackedVector3Array()
	for point in ring:
		points.append(Vector3(point.x, top, point.y))
		points.append(Vector3(point.x, y_bottom, point.y))
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collider)


## One sail: a stock running out from the hub, and a lattice frame of two long
## rails and cross-bars hung on its leading side, with canvas stretched across
## alternate bays. The frame is pitched (twisted about the stock) so the sail
## bites the wind.
static func _build_mill_sail(arm: Node3D) -> void:
	const LENGTH := 5.35
	const START := 0.9
	const WIDTH := 1.3
	var stock := SuperEgg.build_part(Vector3(0.07, LENGTH * 0.5, 0.07), TRIM_WOOD.darkened(0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	stock.position = Vector3(0, LENGTH * 0.5, 0)
	arm.add_child(stock)
	CollisionPolicy.mark_decorative(stock)
	var sail := Node3D.new()
	sail.rotation.y = deg_to_rad(17.0)
	arm.add_child(sail)
	var canvas := Color(0.93, 0.89, 0.78)
	var frame_length := LENGTH - START
	for x: float in [0.12, WIDTH]:
		var rail := SuperEgg.build_part(Vector3(0.035, frame_length * 0.5, 0.035), TRIM_WOOD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		rail.position = Vector3(x, START + frame_length * 0.5, 0)
		sail.add_child(rail)
		CollisionPolicy.mark_decorative(rail)
	var bars := 9
	for i in bars + 1:
		var y := START + frame_length * float(i) / float(bars)
		var bar := SuperEgg.build_part(Vector3((WIDTH - 0.12) * 0.5 + 0.03, 0.03, 0.03), TRIM_WOOD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		bar.position = Vector3((WIDTH + 0.12) * 0.5, y, 0)
		sail.add_child(bar)
		CollisionPolicy.mark_decorative(bar)
		if i < bars and i % 2 == 0:
			var cloth := SuperEgg.build_part(Vector3((WIDTH - 0.12) * 0.5 - 0.02, frame_length / float(bars) * 0.5 - 0.02, 0.012), canvas, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			cloth.position = Vector3((WIDTH + 0.12) * 0.5, y + frame_length / float(bars) * 0.5, 0)
			sail.add_child(cloth)
			CollisionPolicy.mark_decorative(cloth)


## Milling gear on the ground floor: a stone-bedded runner stone under a hopper
## on the east side, grain sacks stacked against the west wall. The doorway
## zone (centre of the -Z side) and the middle of the room stay clear.
static func _build_mill_works(body: StaticBody3D) -> Dictionary:
	var stone := WALL_STONE.darkened(0.15)
	var stone_at := Vector3(1.28, 0.0, 0.38)
	var bed := SuperEgg.build_part(Vector3(0.92, 0.35, 0.92), stone, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	bed.position = stone_at + Vector3.UP * 0.35
	body.add_child(bed)
	_add_box_collision(body, bed.position, Vector3(1.84, 0.7, 1.84))
	var runner_pivot := Node3D.new()
	runner_pivot.name = "RunnerStoneDrive"
	runner_pivot.position = stone_at + Vector3.UP * 0.82
	body.add_child(runner_pivot)
	var runner := SuperEgg.build_part(Vector3(0.78, 0.12, 0.78), WALL_STONE, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	runner_pivot.add_child(runner)
	CollisionPolicy.mark_decorative(runner)
	# Enclosing timber tun makes the stones safe and gives the meal a real
	# collection chamber. The runner remains visible above its low rim.
	for i in 12:
		var angle := TAU * float(i) / 12.0
		var stave := SuperEgg.build_part(Vector3(0.21, 0.3, 0.06), TRIM_WOOD.lightened(0.12), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		stave.position = stone_at + Vector3(cos(angle) * 0.92, 0.92, sin(angle) * 0.92)
		stave.rotation.y = -angle
		body.add_child(stave)
		CollisionPolicy.mark_decorative(stave)
	var hopper := SuperEgg.build_part(Vector3(0.48, 0.42, 0.48), TRIM_WOOD, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	hopper.position = stone_at + Vector3.UP * 1.76
	body.add_child(hopper)
	_add_box_collision(body, hopper.position, Vector3(0.9, 0.8, 0.9))
	var shoe := SuperEgg.build_part(Vector3(0.12, 0.08, 0.46), TRIM_WOOD.lightened(0.12), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	shoe.position = stone_at + Vector3(0, 1.28, -0.34)
	shoe.rotation.x = deg_to_rad(-18.0)
	body.add_child(shoe)
	CollisionPolicy.mark_decorative(shoe)
	var meal_chute := SuperEgg.build_part(Vector3(0.16, 0.12, 0.62), TRIM_WOOD.lightened(0.1), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	meal_chute.position = stone_at + Vector3(0.62, 0.56, -0.72)
	meal_chute.rotation.x = deg_to_rad(-24.0)
	body.add_child(meal_chute)
	CollisionPolicy.mark_decorative(meal_chute)
	# The upright shaft receives power from the brake wheel's wallower above;
	# its great spur wheel drives the smaller stone nut beside it.
	var upright := Node3D.new()
	upright.name = "UprightShaftDrive"
	upright.position = Vector3(0, 4.45, 0)
	body.add_child(upright)
	var upright_post := SuperEgg.build_part(Vector3(0.13, 2.65, 0.13), TRIM_WOOD.darkened(0.18), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	upright.add_child(upright_post)
	CollisionPolicy.mark_decorative(upright_post)
	_add_mill_wheel(upright, Vector3(0, 2.2, 0), 0.58, 0.13, TRIM_WOOD.lightened(0.05), true)
	var great_spur := Node3D.new()
	great_spur.name = "GreatSpurWheel"
	great_spur.position = Vector3(0, 4.15, 0)
	body.add_child(great_spur)
	_add_mill_wheel(great_spur, Vector3.ZERO, 1.35, 0.12, TRIM_WOOD, true)
	var stone_nut := Node3D.new()
	stone_nut.name = "StoneNut"
	stone_nut.position = Vector3(stone_at.x, 4.15, stone_at.z)
	body.add_child(stone_nut)
	_add_mill_wheel(stone_nut, Vector3.ZERO, 0.48, 0.11, TRIM_WOOD.lightened(0.08), true)
	var spindle := SuperEgg.build_part(Vector3(0.09, 1.62, 0.09), TRIM_WOOD.darkened(0.2), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	spindle.position = Vector3(0, -1.62, 0)
	stone_nut.add_child(spindle)
	CollisionPolicy.mark_decorative(spindle)
	# A timber service deck under the gearing makes the upper stage legible. It
	# is open around the shafts and supported by beams, rather than pretending a
	# solid ceiling can intersect the machinery.
	# The service deck is a C around the upright shaft, open over the ramps. A
	# deck across the west side would sit 1.4 m above the head of the ramp it
	# is climbed by (the walkthrough found a person could barely stand), so the
	# west deck stops where the ramp is still low and the south deck stands
	# clear of the turn landing and the second flight.
	var west_deck := SuperEgg.build_part(Vector3(0.62, 0.1, 1.125), FLOOR_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	west_deck.position = Vector3(-1.95, 3.32, -1.125)
	body.add_child(west_deck)
	_add_box_collision(body, west_deck.position, Vector3(1.24, 0.2, 2.25))
	var east_deck := SuperEgg.build_part(Vector3(0.72, 0.1, 2.25), FLOOR_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	east_deck.position = Vector3(1.85, 3.32, 0)
	body.add_child(east_deck)
	_add_box_collision(body, east_deck.position, Vector3(1.44, 0.2, 4.5))
	var north_deck := SuperEgg.build_part(Vector3(1.15, 0.1, 0.42), FLOOR_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	north_deck.position = Vector3(0, 3.32, -1.82)
	body.add_child(north_deck)
	_add_box_collision(body, north_deck.position, Vector3(2.3, 0.2, 0.84))
	var south_deck := SuperEgg.build_part(Vector3(0.6, 0.1, 0.42), FLOOR_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	south_deck.position = Vector3(0.55, 3.32, 1.82)
	body.add_child(south_deck)
	_add_box_collision(body, south_deck.position, Vector3(1.2, 0.2, 0.84))
	# Two broad switchback ramps (a metre wide, so a person and a blorb pass
	# without brushing the wall) hug the west wall and keep the mill's
	# railing-free ramp convention.
	_add_mill_ramp(body, -1.8, -1.62, 1.0, 0.2, 1.61, 3.12)
	var turn_landing := SuperEgg.build_part(Vector3(1.0, 0.1, 0.45), FLOOR_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	turn_landing.position = Vector3(-1.3, 1.71, 1.72)
	body.add_child(turn_landing)
	_add_box_collision(body, turn_landing.position, Vector3(2.0, 0.2, 0.9))
	_add_mill_ramp(body, -0.8, 1.5, -1.0, 1.81, 1.61, 3.12)
	var top_landing := SuperEgg.build_part(Vector3(1.0, 0.1, 0.48), FLOOR_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	top_landing.position = Vector3(-1.3, 3.32, -1.72)
	body.add_child(top_landing)
	_add_box_collision(body, top_landing.position, Vector3(2.0, 0.2, 0.96))
	# Walking lanes for the clear-zone audit: a person's full height must clear
	# the whole climb, and nothing may stand on it.
	var first_flight: Array[Vector3] = [Vector3(-1.8, 0.29, -1.45), Vector3(-1.8, 1.81, 1.5), Vector3(-1.55, 1.81, 1.72)]
	ClearZones.add_lane(body, "mill ramp, first flight", first_flight)
	var second_flight: Array[Vector3] = [Vector3(-1.05, 1.81, 1.5), Vector3(-0.8, 1.81, 1.5), Vector3(-0.8, 3.42, -1.62), Vector3(-1.3, 3.42, -1.72)]
	ClearZones.add_lane(body, "mill ramp, second flight", second_flight)
	ClearZones.add(body, "mill door", "door", Vector2(0.0, -2.45), Vector2(0, 1), 0.4, 1.4, 0.85, 0.05, 1.9)
	ClearZones.add(body, "mill ramp foot", "ramp", Vector2(-1.8, -1.62), Vector2(0, 1), 0.7, 0.0, 0.75, 0.05, 1.9)
	# Stock stands against the south wall, clear of both flights.
	var sack_color := Color(0.78, 0.68, 0.46)
	for x in [0.3, 0.76]:
		Furnishings.piece(body, Vector3(0.22, 0.4, 0.32), sack_color, Vector3(x, 0.4, 2.05), 0.0, true, SuperEgg.EPSILON_SOFT)
	Furnishings.piece(body, Vector3(0.22, 0.4, 0.32), sack_color.darkened(0.04), Vector3(0.53, 1.2, 2.05), 0.1, true, SuperEgg.EPSILON_SOFT)
	var flour_bin := SuperEgg.build_part(Vector3(0.48, 0.42, 0.48), sack_color.lightened(0.06), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	flour_bin.position = stone_at + Vector3(0.88, 0.42, -1.25)
	body.add_child(flour_bin)
	_add_box_collision(body, flour_bin.position, Vector3(0.96, 0.84, 0.96))
	return {"upright": upright, "great_spur": great_spur, "stone_nut": stone_nut, "runner": runner_pivot}


static func _add_mill_ramp(
	body: StaticBody3D, x: float, start_z: float, direction: float,
	base_y: float, rise: float, run: float
) -> void:
	const WIDTH := 1.0
	const THICKNESS := 0.18
	var angle := atan2(rise, run)
	var slope_length := Vector2(run, rise).length()
	var pitch := Basis(Vector3.RIGHT, -angle)
	var basis := pitch if direction > 0.0 else Basis(Vector3.UP, PI) * pitch
	var center := Vector3(
		x,
		base_y + rise * 0.5 - THICKNESS * 0.5 * cos(angle),
		start_z + direction * (run * 0.5 + THICKNESS * 0.5 * sin(angle))
	)
	var ramp := SuperEgg.build_part(
		Vector3(WIDTH * 0.5, THICKNESS * 0.5, slope_length * 0.5), FLOOR_COLOR,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	ramp.transform = Transform3D(basis, center)
	body.add_child(ramp)
	_add_box_collision(body, center, Vector3(WIDTH, THICKNESS, slope_length), basis)


## Open timber wheel assembled from soft SuperEgg rails. `horizontal` means
## the wheel lies in XZ and turns about Y; otherwise it lies in XY and turns
## about Z. Unlike a solid disc, the spokes and rim make the gearing readable.
static func _add_mill_wheel(parent: Node3D, center: Vector3, radius: float, depth: float, color: Color, horizontal: bool = false) -> void:
	var wheel := Node3D.new()
	wheel.position = center
	parent.add_child(wheel)
	const SEGMENTS := 12
	for i in SEGMENTS:
		var angle := TAU * (float(i) + 0.5) / float(SEGMENTS)
		var chord := 2.0 * radius * sin(PI / float(SEGMENTS))
		var rim := SuperEgg.build_part(Vector3(chord * 0.54, depth, depth), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		if horizontal:
			rim.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
			rim.rotation.y = -angle
		else:
			rim.position = Vector3(cos(angle) * radius, sin(angle) * radius, 0)
			rim.rotation.z = angle
		wheel.add_child(rim)
		CollisionPolicy.mark_decorative(rim)
	for i in 6:
		var angle := TAU * float(i) / 6.0
		var spoke := SuperEgg.build_part(Vector3(radius * 0.5, depth * 0.65, depth * 0.65), color.darkened(0.08), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		if horizontal:
			spoke.position = Vector3(cos(angle) * radius * 0.5, 0, sin(angle) * radius * 0.5)
			spoke.rotation.y = -angle
		else:
			spoke.position = Vector3(cos(angle) * radius * 0.5, sin(angle) * radius * 0.5, 0)
			spoke.rotation.z = angle
		wheel.add_child(spoke)
		CollisionPolicy.mark_decorative(spoke)


## The paddle wheel alone (axle along X, wheel plane YZ), so a mill building
## can carry it on its own wall. Outer radius is WATER_WHEEL_OUTER_RADIUS.
const WATER_WHEEL_OUTER_RADIUS := 2.5


static func _add_water_wheel(body: StaticBody3D, center: Vector3) -> void:
	var wheel := Node3D.new()
	wheel.position = center
	body.add_child(wheel)
	const WHEEL_RADIUS := 1.3
	const WHEEL_SPOKES := 12
	const PADDLE_LENGTH := 1.2
	const PADDLE_THICKNESS := 0.7
	var paddle_radius := WHEEL_RADIUS + PADDLE_LENGTH * 0.5
	for i in WHEEL_SPOKES:
		var angle := (float(i) / WHEEL_SPOKES) * TAU
		var next_angle := (float(i + 1) / WHEEL_SPOKES) * TAU
		var mid_angle := (angle + next_angle) * 0.5
		var chord := 2.0 * WHEEL_RADIUS * sin((next_angle - angle) * 0.5)
		var seg := SuperEgg.build_part(
			Vector3(PADDLE_THICKNESS * 0.5, PADDLE_LENGTH * 0.5, chord * 0.56), TRIM_WOOD,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		seg.position = Vector3(0, cos(mid_angle) * paddle_radius, sin(mid_angle) * paddle_radius)
		seg.rotation.x = mid_angle
		wheel.add_child(seg)

		_add_box_collision(
			body, wheel.position + seg.position,
			Vector3(PADDLE_THICKNESS, PADDLE_LENGTH, chord * 1.12), Basis(Vector3.RIGHT, mid_angle)
		)


static func build_water_wheel() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	_add_water_wheel(body, Vector3.ZERO)
	return body


## Same idea as build_windmill() -- a simplified custom stand-in, not a
## recreation of the Kenney watermill.
static func build_watermill() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var tower := SuperEgg.build_part(
		Vector3(1.1, 2.1, 1.1), WALL_WOOD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT
	)
	tower.position = Vector3(0, 2.1, 0)
	body.add_child(tower)

	var roof := SuperEgg.build_part(
		Vector3(1.25, 0.4, 1.25), ROOF_COLORS[2], SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	roof.position = Vector3(0, 4.4, 0)
	body.add_child(roof)

	# Paddle segments sized to their own chord width (the same tangent-
	# matching technique the fountain's rim uses), not a small fixed size
	# guessed independently of the ring's actual circumference -- per
	# direct correction, the old fixed 0.07x0.22x0.14 half-extents left
	# gaps between segments far bigger than the segments themselves,
	# reading as floating debris around the wheel rather than a solid
	# paddle wheel. Local Z (tangential, after the rotation.x below) is
	# what needs to span the chord; local Y (radial) and X (axial
	# thickness) are just sized generously for a chunkier paddle look.
	#
	# PADDLE_LENGTH/PADDLE_THICKNESS pushed well past the original 0.8m
	# radial / 0.24m axial per a later direct instruction -- the old
	# proportions read as "practically a flat circle" rather than
	# individual blades, and (the actual point of the change) were never
	# landable at all: this loop now bakes a real rotated box collider
	# onto each paddle (there was none before), each attached to the rim
	# at PADDLE_LENGTH beyond WHEEL_RADIUS rather than centered on it, so
	# the wheel reads as a ring of jumpable ledges around a solid hub
	# instead of a thin disc.
	_add_water_wheel(body, Vector3(1.4, 1.1, 0))

	_add_box_collision(body, Vector3(0, 2.1, 0), Vector3(2.2, 4.2, 2.2))
	# The roof is landable too, per direct instruction -- a separate box
	# rather than extending the tower's, since the roof flares out wider
	# than the tower shaft below it.
	_add_box_collision(body, Vector3(0, 4.4, 0), Vector3(2.5, 0.8, 2.5))
	return body


## Flat ground paving (plaza/paths) -- replaces the old stretched "road"
## GLB slabs.
static func build_flat_slab(size: Vector2, color: Color = ROAD_COLOR, thickness: float = 0.05) -> MeshInstance3D:
	return SuperEgg.build_part(
		Vector3(size.x * 0.5, thickness * 0.5, size.y * 0.5), color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)


## Plain rectangular paving slab (BoxMesh, not SuperEgg) -- city streets and
## sidewalks tile edge-to-edge into a grid, and SuperEgg's rounded/beveled
## sides (the project's default primitive everywhere else) left a visible
## seam gap at every strip boundary. Kept separate from build_flat_slab(),
## which the village plaza/paths still use as-is.
static func build_rect_slab(size: Vector2, color: Color = ROAD_COLOR, thickness: float = 0.05) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, thickness, size.y)
	mesh_instance.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	mesh_instance.set_surface_override_material(0, material)
	return mesh_instance


## City roads and sidewalks need collision at their rendered height. Without
## it a character keeps standing on the terrain underneath and appears to
## sink into the raised pavement mesh.
static func build_city_pavement(size: Vector2, color: Color, thickness: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var slab := build_rect_slab(size, color, thickness)
	body.add_child(slab)
	_add_box_collision(body, Vector3.ZERO, Vector3(size.x, thickness, size.y))
	return body


# ---------------------------------------------------------------------------
# Platforming (town_generator.gd's _scatter_platforming())
# ---------------------------------------------------------------------------

## Extra collision layer bit (on top of the normal layer 1 every solid prop
## uses) marking a surface as one blorb.gd's followers can actually climb
## -- see blorb.gd's _ground_height_at(), which raycasts against this
## layer specifically rather than layer 1 in general. Only build_ramp()'s
## own slope and a ramp's own landing (build_crate(..., blorb_climbable =
## true)) carry it. Everything else solid -- building roofs, the windmill
## cap, ordinary crate-stack clusters, fences, rock spires -- stays off
## this layer on purpose: an earlier version had blorbs raycast against
## layer 1 in general, which meant a blorb wandering under ANY elevated
## surface (not just one it had actually climbed) would instantly snap up
## onto it -- reported as blorbs "teleporting between terrain levels."
## Restricting the raycast to this dedicated layer means only a genuine,
## continuous ramp (the one thing blorbs can actually climb smoothly, see
## build_ramp()'s own doc comment) can move them.
##
## 4, not 2 -- a first version used layer 2, not checking that player.tscn
## already claims collision_layer = 2 for the player's own CharacterBody3D.
## Since blorb.gd's raycast masks on this layer, that meant it would also
## hit the player directly, any time the player's own collision capsule
## happened to be above a blorb's XZ position -- exactly what landing a
## jump on a blorb does (see blorb.gd's trigger_bounce_squash()) -- and
## the blorb would snap up onto the player's own collider for a frame.
## Reported as blorbs "glitchily shifting up" specifically when jumped on.
## 4 is the first layer nothing else uses.
const BLORB_CLIMBABLE_LAYER := 4


## A simple landable box -- the jump-to-jump building block for crate-stack
## platforming clusters, and (with blorb_climbable = true) the flat landing
## at the top of a build_ramp().
static func build_crate(size: Vector3, color: Color = TRIM_WOOD, blorb_climbable: bool = false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	if blorb_climbable:
		body.collision_layer |= BLORB_CLIMBABLE_LAYER
	body.collision_mask = 0

	var box := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	box.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(box)

	_add_box_collision(body, Vector3(0, size.y * 0.5, 0), size)
	return body


## A flat slab tilted up to the slope's own angle, from local (0,0,0)
## toward local (0, rise, run), width centered on local X -- one
## SuperEgg.build_part(), the same shared primitive every other prop in
## this project builds from, rather than a one-off hand-rolled wedge mesh
## (an earlier version of this function built its own SurfaceTool
## geometry directly, per direct correction that it should be a SuperEgg
## part like everything else here). Collision is a single box rotated to
## match, so it's a genuinely continuous surface: the player's
## move_and_slide() climbs it like any other floor within its slope limit,
## and (the actual point of it) blorb.gd's ground-height raycast reads a
## smooth rising height as a blorb crosses it in XZ, rather than the
## instant per-step jumps a real staircase would produce -- blorbs have no
## jump of their own (see blorb.gd's docstring), so a stepped rise would
## read as them teleporting up each stair instead of climbing it.
static func build_ramp(width: float, run: float, rise: float, color: Color = ROAD_COLOR) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1 | BLORB_CLIMBABLE_LAYER
	body.collision_mask = 0

	var angle := atan2(rise, run)
	var slope_length := Vector2(run, rise).length()
	# Offset from the slope's exact centerline along its own true normal
	# direction (cos(angle), -sin(angle) in (Y, Z)) by half the slab's
	# thickness, not just straight down by THICKNESS * 0.5 -- a first
	# version did the latter, which only lands the top face flush with the
	# slope at its midpoint; everywhere else (worst right at the bottom,
	# where a player first steps on) the top face sagged up to a few cm
	# below the true ground line, reported as trouble smoothly stepping
	# onto the ramp. This version's exact for any angle: at local z=0 it
	# lands the top face precisely at (y=0, z=0) -- flush with the ground
	# it's approached from -- and at z=run precisely at (y=rise, z=run),
	# not just approximately close at both ends.
	const THICKNESS := 0.4
	var center := Vector3(
		0, rise * 0.5 - THICKNESS * 0.5 * cos(angle), run * 0.5 + THICKNESS * 0.5 * sin(angle)
	)
	var basis := Basis(Vector3.RIGHT, -angle)

	var slab := SuperEgg.build_part(
		Vector3(width * 0.5, THICKNESS * 0.5, slope_length * 0.5), color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	slab.transform = Transform3D(basis, center)
	body.add_child(slab)

	_add_box_collision(body, center, Vector3(width, THICKNESS, slope_length), basis)
	return body


static func _add_box_collision(body: StaticBody3D, pos: Vector3, size: Vector3, basis: Basis = Basis()) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.transform = Transform3D(basis, pos)
	body.add_child(shape)
