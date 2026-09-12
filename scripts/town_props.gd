class_name TownProps
extends RefCounted

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
const WINDOW_COLOR := Color(0.55, 0.78, 0.85)
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
const CELL_SIZE := 2.8
const WALL_THICKNESS := 0.16
const FLOOR_HEIGHT := 2.6
const DOOR_WIDTH := 1.0
const DOOR_HEIGHT := 2.05
const WINDOW_SIZE := Vector2(0.6, 0.7)
const ROOF_PITCH := deg_to_rad(30.0)
const ROOF_OVERHANG := 0.3
const ROOF_THICKNESS := 0.1
## Collision-only padding on top of ROOF_THICKNESS's own visual thinness --
## per direct instruction, roofs need to be a real landable platform (the
## player can now jump/blorb-bounce high enough to reach one), and a
## paper-thin 0.1m collision plane is a worse target to land on reliably
## than a slightly thicker one. Purely a collision-shape padding; the
## visual panel mesh is untouched.
const ROOF_COLLISION_THICKNESS := 0.3
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
static func build_building(
	w: int, d: int, floors: int, roof_color: Color,
	ground_wall_color: Color = WALL_STONE,
	upper_wall_color: Color = WALL_WOOD,
	floor_color: Color = FLOOR_COLOR
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var door_ix := int(w / 2.0)

	for floor_index in floors:
		_build_floor(body, w, d, float(floor_index) * FLOOR_HEIGHT, floor_color)

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
					_build_wall_cell(body, Vector3(-w * CELL_SIZE * 0.5, y, cz), deg_to_rad(90.0), wall_color, "window")
				if on_east:
					_build_wall_cell(body, Vector3(w * CELL_SIZE * 0.5, y, cz), deg_to_rad(-90.0), wall_color, "window")
				if on_south:
					var south_opening := "door" if is_ground and ix == door_ix else "window"
					_build_wall_cell(body, Vector3(cx, y, -d * CELL_SIZE * 0.5), 0.0, wall_color, south_opening)
				if on_north:
					_build_wall_cell(body, Vector3(cx, y, d * CELL_SIZE * 0.5), deg_to_rad(180.0), wall_color, "window")

	_build_roof(body, w, d, float(floors) * FLOOR_HEIGHT, roof_color)
	return body


static func _build_floor(body: StaticBody3D, w: int, d: int, y: float, floor_color: Color = FLOOR_COLOR) -> void:
	for ix in w:
		for iz in d:
			var cx := (ix - (w - 1) / 2.0) * CELL_SIZE
			var cz := (iz - (d - 1) / 2.0) * CELL_SIZE
			var tile_pos := Vector3(cx, y, cz)
			var tile := SuperEgg.build_part(
				Vector3(CELL_SIZE * 0.5, 0.04, CELL_SIZE * 0.5), floor_color,
				SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			tile.position = tile_pos
			body.add_child(tile)
			# Landable per direct instruction -- upper-story floors previously
			# had no collision at all (see the ground floor's own real
			# terrain collision, which this is redundant with and harmless
			# alongside).
			_add_box_collision(
				body, tile_pos, Vector3(CELL_SIZE, FLOOR_COLLISION_THICKNESS, CELL_SIZE)
			)


static func _build_corner_post(body: StaticBody3D, pos: Vector3, color: Color) -> void:
	var post := SuperEgg.build_part(
		Vector3(0.14, FLOOR_HEIGHT * 0.5, 0.14), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	var post_pos := pos + Vector3(0, FLOOR_HEIGHT * 0.5, 0)
	post.position = post_pos
	body.add_child(post)
	_add_box_collision(body, post_pos, Vector3(0.28, FLOOR_HEIGHT, 0.28))


static func _build_wall_cell(
	body: StaticBody3D, pos: Vector3, yaw: float, color: Color, opening: String
) -> void:
	var basis := Basis(Vector3.UP, yaw)

	if opening == "door":
		_build_door_cell(body, pos, basis, color)
		return

	var wall := SuperEgg.build_part(
		Vector3(CELL_SIZE * 0.5, FLOOR_HEIGHT * 0.5, WALL_THICKNESS * 0.5), color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	wall.basis = basis
	var wall_pos := pos + Vector3(0, FLOOR_HEIGHT * 0.5, 0)
	wall.position = wall_pos
	body.add_child(wall)
	_add_box_collision(body, wall_pos, Vector3(CELL_SIZE, FLOOR_HEIGHT, WALL_THICKNESS), basis)

	if opening == "window":
		var window := SuperEgg.build_part(
			Vector3(WINDOW_SIZE.x * 0.5, WINDOW_SIZE.y * 0.5, 0.02), WINDOW_COLOR,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		window.basis = basis
		var outward := basis * Vector3(0, 0, -1)
		window.position = (
			pos + Vector3(0, FLOOR_HEIGHT * 0.55, 0) + outward * (WALL_THICKNESS * 0.5 + 0.015)
		)
		body.add_child(window)


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

	# No door panel -- per direct instruction, the opening stays a real
	# open doorway (no door mesh to visually imply something the player
	# was just walking straight through anyway). Just the jambs/lintel
	# above, framing an actually-empty gap.


## A gable roof: two flat panels sloping down from a central ridge toward
## the north/south eaves. Built via an explicit outward-normal Basis (the
## same decal-alignment technique figure_eyes.gd/figure_emblem.gd use for
## a curved surface) rather than a raw Euler rotation -- far more robust
## than hand-deriving the right sign for a slanted panel, since the north
## and south panels are mirror images of each other and would otherwise
## need opposite rotation signs worked out separately. normal is forced to
## point up (normal.y >= 0) regardless of which cross-product order
## happens to give that.
static func _build_roof(body: StaticBody3D, w: int, d: int, floor_top_y: float, color: Color) -> void:
	var width := w * CELL_SIZE + ROOF_OVERHANG * 2.0
	var half_depth := d * CELL_SIZE * 0.5 + ROOF_OVERHANG
	var slope_len := half_depth / cos(ROOF_PITCH)
	var peak_y := floor_top_y + slope_len * sin(ROOF_PITCH)
	var ridge_pos := Vector3(0, peak_y, 0)
	_build_roof_panel(body, ridge_pos, width, slope_len, true, color)
	_build_roof_panel(body, ridge_pos, width, slope_len, false, color)


static func _build_roof_panel(
	body: StaticBody3D, ridge_pos: Vector3, width: float, slope_len: float, north: bool, color: Color
) -> void:
	var z_sign := 1.0 if north else -1.0
	var length_dir := Vector3(0, -sin(ROOF_PITCH), z_sign * cos(ROOF_PITCH)).normalized()
	var width_dir := Vector3(1, 0, 0)
	var normal := width_dir.cross(length_dir)
	if normal.y < 0.0:
		normal = -normal
	var panel := SuperEgg.build_part(
		Vector3(width * 0.5, ROOF_THICKNESS * 0.5, slope_len * 0.5), color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	var panel_basis := Basis(width_dir, normal, length_dir)
	panel.basis = panel_basis
	var panel_pos := ridge_pos + length_dir * (slope_len * 0.5)
	panel.position = panel_pos
	body.add_child(panel)
	# Landable per direct instruction -- the player can now jump/blorb-bounce
	# high enough to reach a roof, so it needs to actually hold them. The
	# panel's own 30-degree pitch (ROOF_PITCH) is well inside
	# CharacterBody3D's default floor_max_angle (45 degrees), so it reads as
	# ordinary (if slanted) ground once collidable, not a slide-off surface.
	_add_box_collision(
		body, panel_pos, Vector3(width, ROOF_COLLISION_THICKNESS, slope_len), panel_basis
	)


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
			Vector3(0.03, 0.78, 0.03), TRIM_WOOD, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
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
			Vector3(0.055, 1.38, 0.055), TRIM_WOOD,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
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


## Simplified custom landmark -- a stone tower, a colored cap, and a
## 4-blade rotor (static, not animated). Not a recreation of the Kenney
## windmill's own geometry, just a stand-in built from this file's own
## primitives, per direct instruction to phase out every borrowed asset.
static func build_windmill() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var tower := SuperEgg.build_part(
		Vector3(0.9, 3.0, 0.9), WALL_STONE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT
	)
	tower.position = Vector3(0, 3.0, 0)
	body.add_child(tower)

	var cap := SuperEgg.build_part(
		Vector3(1.0, 0.45, 1.0), ROOF_COLORS[0], SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	cap.position = Vector3(0, 6.25, 0)
	body.add_child(cap)

	# Bigger blades (was 0.13x1.3 half-extents), and rotated to an X
	# configuration (45 degrees off the plus-sign the plain 90-degree
	# spacing gave) -- both per direct correction, the X reads as more
	# natural for a windmill rotor. Scaled 3x again (width/length/thickness
	# all together, not just length) per a later direct instruction.
	var hub := Node3D.new()
	hub.position = Vector3(0, 5.4, 1.0)
	body.add_child(hub)
	const BLADE_LENGTH := 1.9 * 3.0
	const BLADE_WIDTH := 0.18 * 3.0
	const BLADE_THICKNESS := 0.05 * 3.0
	for i in 4:
		var blade := SuperEgg.build_part(
			Vector3(BLADE_WIDTH, BLADE_LENGTH * 0.5, BLADE_THICKNESS), TRIM_WOOD,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		# No position offset -- build_part's mesh is already centered on its
		# own local origin, so leaving position at its Node3D default (zero)
		# centers each blade exactly on the hub once rotated. An earlier
		# version offset this by (0, BLADE_LENGTH * 0.5, 0), which reads as
		# "shift the blade up so its inner end touches the hub" but Node3D
		# applies rotation to the mesh first and position second in the
		# parent's frame -- so what it actually did was drag the whole
		# blade's center (not just its inner end) that far above the hub,
		# regardless of rotation.z. Barely visible at the old blade length
		# (0.95m), but scaled 3x right along with BLADE_LENGTH (to 2.85m) --
		# that's what was floating the rotor visibly above the tower.
		blade.rotation.z = deg_to_rad(90.0 * i + 45.0)
		hub.add_child(blade)

	_add_box_collision(body, Vector3(0, 3.0, 0), Vector3(1.8, 6.0, 1.8))
	# The cap is landable too, per direct instruction -- a separate box
	# rather than just extending the tower's, since the cap flares out wider
	# than the tower shaft below it.
	_add_box_collision(body, Vector3(0, 6.25, 0), Vector3(2.0, 0.9, 2.0))
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
	var wheel := Node3D.new()
	wheel.position = Vector3(1.4, 1.1, 0)
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
