class_name FireCalderaNahl
extends RefCounted

## The Nahl tempering hall and Eris's house (fire_caldera_buildings.md,
## section 3): where cooled and cracked lava bodies are warmed back to health,
## disputes are talked through, and Eris lives. A house of care, so it does not
## share the guest house's sleek, glassy, commercial face: thick walls of pale
## cream tuff with a few deep superellipse openings, a floor of white
## hot-spring sinter, no stained band, and the character carried by
## hand-forged ironwork (window grilles, the clerestory's tracery, the screens
## round the molten floor, two branching columns carrying the roof). The one
## strong colour is the lava itself. Two volumes in one body:
##   - the tempering hall, 10 x 12 m, its roof raked from the back wall up
##     toward the promenade, the wedge between the level wall head and the roof
##     glazed behind iron tracery, so the room opens into a tall clerestory;
##   - a 6 m wing at 3.8 m on its +X side: Eris's suite at the front with its
##     own door at the east end, where R3 meets the promenade, and the
##     mediation room behind it, its conversation pit dug into the plinth on
##     the uphill side and lit by one pale dome.
## Local +Z faces the promenade (the reservoir); the plot rises toward -Z. A
## visitor never passes the treatment rooms to reach Eris.

const HALL_SIZE := Vector2(10.0, 12.0)
const HALL_CENTRE := Vector2(-3.0, 0.0)
const WING_SIZE := Vector2(6.0, 12.0)
const WING_CENTRE := Vector2(5.0, 0.0)
const STOREY := CalderaShell.STOREY
## The hall roof's rise from its back wall head to its front.
const HALL_RAKE := 2.4
const HALF_X := 8.0
const HALF_Z := 6.0
const WALL := CalderaShell.WALL
## The palette of a house of care, from the caldera's own pale rocks.
const TUFF := Color(0.84, 0.79, 0.70)
const PUMICE := Color(0.90, 0.88, 0.83)
const SINTER := Color(0.93, 0.92, 0.88)
const OLIVINE := Color(0.64, 0.72, 0.50)
const SULPHUR := Color(0.92, 0.86, 0.62)
const RHYOLITE := Color(0.80, 0.70, 0.66)
const IRON := CalderaShell.STEEL_BLUED
const ROOF := Color(0.82, 0.80, 0.75)
## Shards for the trencadis: broken pale mineral tile.
const MOSAIC: Array[Color] = [SINTER, SULPHUR, Color(0.76, 0.82, 0.66), RHYOLITE, Color(0.84, 0.82, 0.78)]
## The party wall between hall and wing.
const PARTY_X := 2.0
## The wall between the suite (in front) and the mediation room (behind).
const SUITE_BACK_Z := -1.0
const STAFF_DOOR_Z := 4.6
const MEDIATION_DOOR_Z := -3.5
const HALL_DOOR_X := -3.0
const SUITE_DOOR_X := 6.4
const DOOR_CLEAR := 2.3
const DOOR_HEIGHT := 2.75
const INNER_DOOR_WIDTH := FireCalderaBuildings.INNER_DOOR_WIDTH
const INNER_DOOR_HEIGHT := FireCalderaBuildings.INNER_DOOR_HEIGHT
## The molten-floor bay in the hall's west back corner.
const MOLTEN_BAY := Rect2(Vector2(-7.7, -5.7), Vector2(3.1, 5.2))
const MOLTEN_Y := 0.03
const MOLTEN := Color(1.0, 0.42, 0.08)
## Eris's lava bed: a raised bath she rests in, its head to the party wall.
const BED_CENTRE := Vector2(3.35, 1.0)
const BED_HALF := Vector2(1.15, 0.6)
const BED_HEIGHT := 0.55
const BED_WALL := 0.13
const BED_LAVA_Y := 0.47
## Cast forsterite: the refractory made from the caldera's own olivine.
const FORSTERITE := Color(0.82, 0.83, 0.74)
## The heat-proof cloths, pale and undyed: silica cloth, ceramic fibre and
## basalt fibre lightened by weathering. No stainless steel in this house: its
## metal is wrought iron (stainless belongs to the guest house).
const SILICA := Color(0.90, 0.87, 0.80)
const CERAMIC := Color(0.94, 0.93, 0.89)
const BASALT_FIBRE := Color(0.76, 0.68, 0.55)
const COOL_LEDGE := Color(0.62, 0.60, 0.57)


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.make_body(parent, entry, float(line["datum"]))
	_walls(body)
	_clerestory(body)
	_roofs(body)
	_tree_columns(body)
	_partitions(body)
	_molten_bay(body)
	_platforms(body)
	_hall_fittings(body)
	_mediation_room(body)
	_suite(body)
	return body


## The hall roof's underside height at a plan depth z.
static func head(z: float) -> float:
	return STOREY + HALL_RAKE * clampf((z + HALF_Z) / (2.0 * HALF_Z), 0.0, 1.0)


# ---------------------------------------------------------------------------
# The envelope.
# ---------------------------------------------------------------------------

## Thick tuff walls, 3.8 m high all round, each punched for its few openings:
## the hall's door and two tall windows to the promenade, the suite's window
## and door at the east end, one high window onto the slope behind the
## platforms, one to the west, one by the suite's entry. Openings are deep
## superellipses (square foot for doors), framed in forged iron.
static func _walls(body: StaticBody3D) -> void:
	var long := HALF_X * 2.0 + WALL
	var short := HALF_Z * 2.0 - WALL
	# [name, origin, yaw, length, openings (centre along the wall's local X)]
	var windows := {
		"front": [Vector3(0, 0, HALF_Z), 0.0, long, [
			_window(-6.3, 1.3, 0.6, 2.9), _door(HALL_DOOR_X), _window(0.3, 1.3, 0.6, 2.9),
			_window(3.5, 1.2, 0.7, 2.8), _door(SUITE_DOOR_X),
		]],
		"back": [Vector3(0, 0, -HALF_Z), 0.0, long, [_window(-1.8, 2.6, 1.7, 3.1)]],
		# Walls along Z turn by PI/2: their local X runs toward -Z.
		"west": [Vector3(-HALF_X, 0, 0), PI * 0.5, short, [_window(-1.5, 1.3, 0.6, 2.9)]],
		"east": [Vector3(HALF_X, 0, 0), PI * 0.5, short, [_window(-4.6, 1.0, 0.8, 2.6)]],
	}
	for key: String in windows:
		var wall: Array = windows[key]
		var origin: Vector3 = wall[0]
		var yaw: float = wall[1]
		var openings: Array[Dictionary] = []
		openings.assign(wall[3])
		TownProps._build_panel_facade(body, float(wall[2]), origin, yaw, TUFF, openings, 0.0, STOREY, WALL)
		for opening in openings:
			if str(opening["kind"]) == "door":
				TownProps._build_panel_opening_trim(body, origin, yaw, opening, 0.0, IRON, WALL, IRON.lightened(0.08))
				var along := Vector2(cos(yaw), -sin(yaw))
				var at := Vector2(origin.x, origin.z) + along * float(opening["center"])
				var out := Vector2(origin.x, origin.z).normalized() if key != "front" else Vector2(0, 1)
				ClearZones.add(body, str(opening["label"]), "door", at, out, 1.25, 1.25, DOOR_CLEAR * 0.5 + 0.15, 0.05, 1.95)
			else:
				_grille(body, origin, yaw, opening)
		ClearZones.add_wall(body, key, Vector2(origin.x, origin.z) - Vector2(cos(yaw), -sin(yaw)) * float(wall[2]) * 0.5, Vector2(origin.x, origin.z) + Vector2(cos(yaw), -sin(yaw)) * float(wall[2]) * 0.5, 0.0, STOREY, WALL, true)
	# A cap of pumice along every wall head, under the roofs.
	for z: float in [-HALF_Z, HALF_Z]:
		CalderaShell._metal(body, Vector3(0, STOREY + 0.04, z), Vector3(long + 0.1, 0.08, WALL + 0.1), PUMICE, false).material_override = SolidModel.material(PUMICE, 0.85, 0.0)
	for x: float in [-HALF_X, HALF_X]:
		CalderaShell._metal(body, Vector3(x, STOREY + 0.04, 0), Vector3(WALL + 0.1, 0.08, short), PUMICE, false).material_override = SolidModel.material(PUMICE, 0.85, 0.0)


static func _door(x: float) -> Dictionary:
	return {"kind": "door", "center": x, "width": DOOR_CLEAR, "bottom": 0.0, "top": DOOR_HEIGHT, "leaves": 2,
		"exponent": TownProps.OPENING_EXPONENT, "label": "hall door" if x < PARTY_X else "suite door"}


static func _window(x: float, width: float, bottom: float, top: float) -> Dictionary:
	return {"kind": "window", "center": x, "width": width, "bottom": bottom, "top": top, "exponent": TownProps.OPENING_EXPONENT}


## A window's glass and its forged grille: a piped iron frame on the outer
## face, and inside the reveal three bars that rise and fork like a vein of
## cooled lava, the middle one twice.
static func _grille(body: StaticBody3D, origin: Vector3, yaw: float, opening: Dictionary) -> void:
	var pivot := Node3D.new()
	pivot.position = origin
	pivot.rotation.y = yaw
	body.add_child(pivot)
	var cx := float(opening["center"])
	var half_w := float(opening["width"]) * 0.5
	var bottom := float(opening["bottom"])
	var top := float(opening["top"])
	var half_h := (top - bottom) * 0.5
	var mid := (top + bottom) * 0.5
	var loop := OpeningTrim.window_loop(half_w, half_h, TownProps.OPENING_EXPONENT)
	var pane := MeshInstance3D.new()
	pane.mesh = SolidModel.extruded_profile_mesh(0.03, Vector2(half_h - 0.004, half_w - 0.004), TownProps.OPENING_EXPONENT, 96)
	pane.material_override = SolidModel.material(Color(0.80, 0.86, 0.84, 0.30), 0.08, 0.0)
	pane.position = Vector3(cx, mid, 0.0)
	pane.rotation.y = PI * 0.5
	pivot.add_child(pane)
	CollisionPolicy.mark_decorative(pane)
	var reveal := OpeningTrim.reveal_liner(loop, WALL * 0.5, PUMICE, Vector2.ZERO, 0.995, true)
	reveal.position = Vector3(cx, mid, 0.0)
	pivot.add_child(reveal)
	var frame := OpeningTrim.piped_frame(loop, 0.035, IRON, true)
	frame.position = Vector3(cx, mid, -WALL * 0.5)
	frame.rotation.y = PI
	pivot.add_child(frame)
	# The bars, just outside the glass.
	var z := -0.06
	for i in 3:
		var x := cx + (float(i) - 1.0) * half_w * 0.5
		var root := Vector3(x, bottom + 0.05, z)
		var fork := Vector3(x, mid + half_h * 0.25, z)
		_branch(pivot, root, fork)
		for side: float in [-1.0, 1.0]:
			var tip := Vector3(x + side * half_w * (0.22 if i == 1 else 0.14), top - half_h * (0.18 if i == 1 else 0.32), z)
			_branch(pivot, fork, tip)
			if i == 1:
				_branch(pivot, tip, Vector3(tip.x + side * 0.08, tip.y + half_h * 0.12, z))
	var sill := SuperEgg.build_part(Vector3(half_w + 0.1, 0.035, WALL * 0.5 + 0.06), SINTER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	sill.position = Vector3(cx, bottom - 0.02, 0.0)
	pivot.add_child(sill)
	CollisionPolicy.mark_decorative(sill)


## Above the hall's walls, the wedge of glass under the raked roof, behind a
## forged tracery: iron mullions every 2 m that fork as they meet the roof, on
## the front (full height) and the two sides (rising from back to front); the
## wing's roof covers the lower part on the party side.
static func _clerestory(body: StaticBody3D) -> void:
	var glass := Color(0.86, 0.90, 0.88, 0.22)
	var x0 := -HALF_X
	var x1 := PARTY_X
	# Front: a full rectangle.
	CalderaShell._wedge_pane(body, Vector2(x0, HALF_Z), Vector2(x1, HALF_Z), STOREY + 0.08, head(HALF_Z), head(HALF_Z), glass)
	var steps := 5
	for i in steps + 1:
		var x := lerpf(x0, x1, float(i) / float(steps))
		_tracery(body, Vector3(x, STOREY + 0.08, HALF_Z), head(HALF_Z), Vector3.RIGHT)
	# The sides: wedges.
	for x: float in [x0, x1]:
		CalderaShell._wedge_pane(body, Vector2(x, -HALF_Z), Vector2(x, HALF_Z), STOREY + 0.08, head(-HALF_Z), head(HALF_Z), glass)
		for i in 7:
			var z := lerpf(-HALF_Z, HALF_Z, float(i) / 6.0)
			if head(z) - STOREY > 0.5:
				_tracery(body, Vector3(x, STOREY + 0.08, z), head(z), Vector3.BACK)
		CalderaShell._beam(body, Vector3(x, head(-HALF_Z) - 0.05, -HALF_Z), Vector3(x, head(HALF_Z) - 0.05, HALF_Z), Vector2(0.1, 0.12), IRON)
	CalderaShell._beam(body, Vector3(x0, head(HALF_Z) - 0.05, HALF_Z), Vector3(x1, head(HALF_Z) - 0.05, HALF_Z), Vector2(0.1, 0.12), IRON)


## One clerestory mullion: a forged bar from the wall head up to the roof,
## forking into two branches at two thirds of its height; `along` is the
## wall's direction.
static func _tracery(body: Node3D, foot: Vector3, top: float, along: Vector3) -> void:
	var height := top - foot.y
	var fork := foot + Vector3.UP * height * 0.62
	_branch(body, foot, fork)
	for side: float in [-1.0, 1.0]:
		_branch(body, fork, Vector3(fork.x, top - 0.04, fork.z) + along * side * minf(height * 0.32, 0.55))


## The roofs: the hall's raked slab and the wing's, both pale, the wing's with
## one pale olivine dome over the conversation pit.
static func _roofs(body: StaticBody3D) -> void:
	CalderaShell._build_roof(body, HALL_CENTRE, HALL_SIZE, STOREY, HALL_RAKE, {"east": 0.0}, [], ROOF)
	CalderaShell._build_roof(body, WING_CENTRE, WING_SIZE, STOREY, 0.0, {"west": 0.0},
		[{"name": "Mediation", "at": Vector2(0.1, -3.5), "half": Vector2(2.2, 1.9), "rise": 0.8, "tint": Color(0.82, 0.90, 0.74, 0.38)}], ROOF)


## Two branching iron columns down the hall's middle carrying its raked roof,
## each a trunk that splits into four limbs, like a tree of cooled lava.
static func _tree_columns(body: StaticBody3D) -> void:
	for x: float in [-5.4, -0.6]:
		var foot := Vector3(x, 0.0, 1.2)
		var crown := Vector3(x, 3.0, 1.2)
		_branch(body, foot, crown, 0.09)
		CalderaFurniture.piece(body, Vector3(0.2, 0.06, 0.2), PUMICE, Vector3(x, 0.06, 1.2), 0.0, false, 4.0)
		var holder := MeshInstance3D.new()
		body.add_child(holder)
		CollisionPolicy.add_box(body, holder, Vector3(0.18, 3.0, 0.18), Vector3(x, 1.5, 1.2), Basis(), false)
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var reach := Vector3(x + corner.x * 1.0, 0.0, 1.2 + corner.y * 1.1)
			var elbow := crown + (reach - Vector3(x, 0.0, 1.2)) * 0.4 + Vector3.UP * 0.7
			_branch(body, crown, elbow, 0.06)
			var bearing := Vector3(reach.x, head(reach.z) + 0.06, reach.z)
			_branch(body, elbow, bearing, 0.045)
			# A forged plate where the limb takes the roof.
			var plate := SuperEgg.build_part(Vector3(0.22, 0.03, 0.22), IRON, 2.6, 6.0)
			plate.material_override = SolidModel.material(IRON, 0.3, 0.85)
			plate.position = Vector3(reach.x, head(reach.z) + 0.07, reach.z)
			plate.rotation.x = -atan2(HALL_RAKE, HALF_Z * 2.0)
			body.add_child(plate)
			CollisionPolicy.mark_decorative(plate)


## The molten surfaces in the body's plan, for the terrain's lava queries:
## [{"polygon": PackedVector2Array, "y": float}], local.
static func lava_surfaces() -> Array[Dictionary]:
	var bay := PackedVector2Array([MOLTEN_BAY.position, Vector2(MOLTEN_BAY.end.x, MOLTEN_BAY.position.y), MOLTEN_BAY.end, Vector2(MOLTEN_BAY.position.x, MOLTEN_BAY.end.y)])
	var bed := PackedVector2Array()
	for i in 32:
		var t := TAU * float(i) / 32.0
		var c := cos(t)
		var s := sin(t)
		bed.append(BED_CENTRE + Vector2(signf(c) * pow(absf(c), 0.5) * (BED_HALF.x - BED_WALL), signf(s) * pow(absf(s), 0.5) * (BED_HALF.y - BED_WALL)))
	return [{"polygon": bay, "y": MOLTEN_Y}, {"polygon": bed, "y": BED_LAVA_Y}]


## Registers this building's molten surfaces with the live terrain, in its
## world frame.
static func register_lava(body: Node3D, terrain: Node) -> void:
	for surface in lava_surfaces():
		var world := PackedVector2Array()
		var height := 0.0
		for point: Vector2 in surface["polygon"]:
			var at := body.global_transform * Vector3(point.x, float(surface["y"]), point.y)
			world.append(Vector2(at.x, at.z))
			height = at.y
		terrain.register_lava_polygon(world, height)


## The party wall, full height in tuff, with the staff door into the suite and
## the mediation door; the wall between the suite and the mediation room, with
## no door. Doors are superellipse openings with iron frames and leaves.
static func _partitions(body: StaticBody3D) -> void:
	var front := HALF_Z - WALL * 0.5
	var back := -front
	var doors := [[MEDIATION_DOOR_Z, "mediation door"], [STAFF_DOOR_Z, "staff door"]]
	var cursor := back
	for door: Array in doors:
		var z: float = door[0]
		var south := z - INNER_DOOR_WIDTH * 0.5 - 0.35
		var north := minf(z + INNER_DOOR_WIDTH * 0.5 + 0.35, front)
		_inner(body, Vector3(PARTY_X, STOREY * 0.5, (cursor + south) * 0.5), Vector3(0.22, STOREY, south - cursor))
		CalderaShell.door_opening(body, Vector3(PARTY_X, 0.0, (south + north) * 0.5), PI * 0.5, north - south, STOREY, 0.22, INNER_DOOR_WIDTH, INNER_DOOR_HEIGHT, 1, TUFF, IRON)
		for direction: Vector2 in [Vector2(1, 0), Vector2(-1, 0)]:
			ClearZones.add(body, str(door[1]), "door", Vector2(PARTY_X, z), direction, 0.0, 1.0, INNER_DOOR_WIDTH * 0.5, 0.05, 1.9)
		cursor = north
	if front - cursor > 0.05:
		_inner(body, Vector3(PARTY_X, STOREY * 0.5, (cursor + front) * 0.5), Vector3(0.22, STOREY, front - cursor))
	_inner(body, Vector3(WING_CENTRE.x + 0.11, STOREY * 0.5, SUITE_BACK_Z), Vector3(WING_SIZE.x - WALL * 0.5 - 0.11, STOREY, 0.22))


static func _inner(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "TuffPartition"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = SolidModel.material(TUFF, 0.88, 0.0)
	mesh.position = at
	body.add_child(mesh)
	CollisionPolicy.add_box(body, mesh, size, at, Basis(), false)


## The molten-floor room: the whole floor of the bay a thin molten layer for
## deep rejuvenation, screened from the hall by forged panels, entered by one
## gap the hall can see. Its own light is the molten floor.
static func _molten_bay(body: StaticBody3D) -> void:
	var size := MOLTEN_BAY.size
	var centre := MOLTEN_BAY.get_center()
	var floor := MeshInstance3D.new()
	floor.name = "MoltenFloor"
	floor.mesh = SuperEgg.build_part(Vector3(size.x * 0.5, 0.02, size.y * 0.5), MOLTEN, 7.0, 7.0).mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = MOLTEN
	material.emission_enabled = true
	material.emission = MOLTEN
	material.emission_energy_multiplier = 2.4
	floor.material_override = material
	floor.position = Vector3(centre.x, MOLTEN_Y - 0.01, centre.y)
	body.add_child(floor)
	CollisionPolicy.mark_decorative(floor)
	# A cast-basalt kerb round the molten floor, the step a body takes in.
	for side: float in [-1.0, 1.0]:
		CalderaShell._metal(body, Vector3(centre.x, 0.04, centre.y + side * (size.y * 0.5 + 0.06)), Vector3(size.x + 0.24, 0.08, 0.12), CalderaShell.BASALT, false)
		CalderaShell._metal(body, Vector3(centre.x + side * (size.x * 0.5 + 0.06), 0.04, centre.y), Vector3(0.12, 0.08, size.y), CalderaShell.BASALT, false)
	var glow := CalderaFurniture.concealed_light(body, Vector3(centre.x, 0.6, centre.y), Color(1.0, 0.5, 0.18), 1.6, 6.5)
	glow.name = "MoltenFloorLight"
	# Forged screens: along the front of the bay, and down its hall side with a
	# gap at the front for the way in.
	var east := MOLTEN_BAY.end.x + 0.15
	var north := MOLTEN_BAY.end.y + 0.15
	_forged_screen(body, Vector2(MOLTEN_BAY.position.x - 0.15, north), Vector2(east, north))
	_forged_screen(body, Vector2(east, MOLTEN_BAY.position.y - 0.15), Vector2(east, north - 1.6))
	ClearZones.add(body, "molten bay entrance", "door", Vector2(east, north - 0.8), Vector2(1, 0), 0.0, 1.0, 0.65, 0.05, 1.9)


## A forged screen panel 2.4 m tall between two plan points: blued-steel rails
## and posts, filled with branching bars like veins of cooled lava.
static func _forged_screen(body: StaticBody3D, from: Vector2, to: Vector2) -> void:
	var length := from.distance_to(to)
	var along := (to - from).normalized()
	var mid := (from + to) * 0.5
	var yaw := 0.0 if absf(along.x) > 0.5 else PI * 0.5
	for y: float in [0.12, 2.4]:
		CalderaShell._metal(body, Vector3(mid.x, y, mid.y), CalderaShell._oriented(Vector3(length, 0.07, 0.07), yaw), CalderaShell.STEEL_BLUED, false)
	var posts := maxi(int(length / 1.1), 1)
	var rail: MeshInstance3D = null
	for i in posts + 1:
		var p := from + along * length * float(i) / float(posts)
		rail = CalderaShell._metal(body, Vector3(p.x, 1.25, p.y), Vector3(0.08, 2.5, 0.08), CalderaShell.STEEL_BLUED, false)
		if i == posts:
			continue
		# In each panel a trunk rising and forking twice.
		var q := from + along * length * (float(i) + 0.5) / float(posts)
		var trunk := Vector3(q.x, 0.12, q.y)
		var dir := Vector3(along.x, 0.0, along.y)
		_branch(body, trunk, trunk + Vector3.UP * 1.0)
		for side: float in [-1.0, 1.0]:
			var fork := trunk + Vector3.UP * 1.0 + dir * side * 0.32 + Vector3.UP * 0.55
			_branch(body, trunk + Vector3.UP * 1.0, fork)
			_branch(body, fork, fork + dir * side * 0.18 + Vector3.UP * 0.72)
			_branch(body, fork, fork - dir * side * 0.16 + Vector3.UP * 0.72)
	CollisionPolicy.add_box(body, rail, CalderaShell._oriented(Vector3(length, 2.4, 0.1), yaw), Vector3(mid.x, 1.25, mid.y), Basis(), false)


static func _branch(body: Node3D, root: Vector3, tip: Vector3, radius: float = 0.022) -> void:
	var delta := tip - root
	var part := SuperEgg.build_part(Vector3(radius, delta.length() * 0.5 + radius, radius), IRON, 6.0, 6.0)
	part.material_override = SolidModel.material(IRON, 0.3, 0.85)
	var up := delta.normalized()
	var x_axis := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	part.transform = Transform3D(Basis(x_axis, up, x_axis.cross(up)), (root + tip) * 0.5)
	body.add_child(part)
	CollisionPolicy.mark_decorative(part)


## Three radiant platforms, heads to the back wall under its long pane: hot
## basalt slabs to lie on, each with a glowing seam where the duct runs under
## it and a temperature control at its head for Eris; her work stool beside the
## middle one.
static func _platforms(body: StaticBody3D) -> void:
	for x: float in [-3.6, -1.8, 0.0]:
		CalderaFurniture.piece(body, Vector3(0.55, 0.22, 1.15), CalderaShell.BASALT, Vector3(x, 0.22, -4.5), 0.0, true)
		CalderaFurniture.piece(body, Vector3(0.5, 0.03, 1.08), Color(0.22, 0.12, 0.10), Vector3(x, 0.46, -4.5), 0.0, false, SuperEgg.EPSILON_SOFT)
		for side: float in [-1.0, 1.0]:
			FireCalderaBuildings._glow(body, "RadiantSeam", Vector3(0.008, 0.012, 1.0), Vector3(x + side * 0.56, 0.18, -4.5), Color(1.0, 0.45, 0.12))
		# The control: a forged iron dial with a sinter face on a short post at
		# the head.
		CalderaShell._metal(body, Vector3(x + 0.4, 0.45, -5.75), Vector3(0.06, 0.9, 0.06), IRON, false)
		var dial := CalderaFurniture.piece(body, Vector3(0.07, 0.07, 0.02), IRON, Vector3(x + 0.4, 0.92, -5.72), 0.0, false, 2.0)
		dial.material_override = SolidModel.material(IRON, 0.3, 0.85)
		CalderaFurniture.piece(body, Vector3(0.05, 0.05, 0.01), SINTER, Vector3(x + 0.4, 0.92, -5.695), 0.0, false, 2.0)
	# A pale silica cloth folded at the foot of each platform, for the patient
	# to draw over as they cool back into themselves.
	for x: float in [-3.6, -1.8, 0.0]:
		CalderaFurniture.piece(body, Vector3(0.42, 0.035, 0.2), SILICA, Vector3(x, 0.5, -3.55), 0.0, false, SuperEgg.EPSILON_SOFT)
	# Eris's tray of corrective minerals by her stool.
	CalderaFurniture.piece(body, Vector3(0.24, 0.03, 0.16), PUMICE, Vector3(-2.7, 0.03, -2.35), 0.3, false, 4.0)
	for i in 3:
		CalderaFurniture.piece(body, Vector3(0.04, 0.03, 0.04), [OLIVINE, SULPHUR, RHYOLITE][i], Vector3(-2.82 + 0.1 * float(i), 0.08, -2.35 + 0.03 * float(i)), float(i), false, 2.4)
	CalderaFurniture.concealed_light(body, Vector3(-1.8, 1.2, -4.2), Color(1.0, 0.55, 0.22), 0.7, 5.0)
	# Eris's stool: a steel pedestal and a basalt seat.
	CalderaShell._metal(body, Vector3(-2.7, 0.3, -2.9), Vector3(0.08, 0.6, 0.08), CalderaShell.STEEL_BLUED, false)
	CalderaFurniture.piece(body, Vector3(0.2, 0.05, 0.2), CalderaShell.BASALT, Vector3(-2.7, 0.62, -2.9), 0.0, true, SuperEgg.EPSILON_SOFT)
	FireCalderaBuildings._marker(body, "ErisWorkMarker", Vector3(-2.7, 0.0, -2.4), PI)


## The rest of the hall: the mineral cabinet of corrective samples on the west
## wall, a waiting bench facing the platforms, two glass-enclosed flames
## flanking the door inside.
static func _hall_fittings(body: StaticBody3D) -> void:
	CalderaFurniture.shelves(body, Vector3(-7.62, 0.0, 4.4), -PI * 0.5, 2.4, 4, func(b: StaticBody3D, p: Vector3, i: int) -> void:
		var minerals: Array[Color] = [Color(0.55, 0.30, 0.60), Color(0.30, 0.62, 0.55), Color(0.80, 0.55, 0.20), Color(0.62, 0.20, 0.18), Color(0.85, 0.82, 0.72)]
		CalderaFurniture.piece(b, Vector3(0.06, 0.05, 0.06), minerals[(i * 3) % minerals.size()], p + Vector3(0, 0.05, 0), float(i) * 0.7, false, 2.6), IRON)
	CalderaFurniture.piece(body, Vector3(1.1, 0.22, 0.26), SINTER.darkened(0.06), Vector3(-0.2, 0.22, 3.2), 0.0, true)
	for x: float in [-4.6, -1.4]:
		CalderaFurniture.flame_capsule(body, Vector3(x, 0.0, 5.45))
	# A runner of weathered basalt fibre from the door to the platforms.
	CalderaFurniture.mat(body, Vector3(HALL_DOOR_X, 0.0, 0.9), 0.0, Vector2(1.3, 6.4), BASALT_FIBRE.lightened(0.12))
	for x: float in [-5.4, -0.6]:
		CalderaFurniture.concealed_light(body, Vector3(x, 3.4, 1.2), CalderaFurniture.LED_WARM, 0.9, 7.0)


## The mediation room: a conversation pit for disagreements that have become
## personal. Sunk half a metre into the plinth, its stone bench runs round the
## pit's wall so everyone sits level and faces in, with one step down at the
## end nearest the door; a warm seam glows in the pit's floor; the only window
## is the cobalt dome above.
static func _mediation_room(body: StaticBody3D) -> void:
	var pit: Dictionary = (FireCalderaPlan.plot("NAHL")["pits"] as Array)[0]
	var at: Vector2 = pit["at"]
	var half: Vector2 = pit["half"]
	var depth := float(pit["depth"])
	var exponent := float(pit["exponent"])
	var seat_top := -0.06
	var count := 22
	for i in count:
		var t := TAU * (float(i) + 0.5) / float(count)
		# Leave the west end, toward the door, for the step.
		if absf(wrapf(t - PI, -PI, PI)) < 0.32:
			continue
		var c := cos(t)
		var s := sin(t)
		var rim := Vector2(signf(c) * pow(absf(c), 2.0 / exponent) * half.x, signf(s) * pow(absf(s), 2.0 / exponent) * half.y)
		var inward := -rim.normalized()
		var p := at + rim + inward * 0.26
		var yaw := atan2(inward.x, inward.y)
		# The bench is clad in trencadis, each block a different broken mineral.
		var seat := CalderaFurniture.piece(body, Vector3(0.3, (seat_top - 0.06 + depth) * 0.5, 0.24), MOSAIC[(i * 3) % MOSAIC.size()], Vector3(p.x, -depth + (seat_top - 0.06 + depth) * 0.5, p.y), yaw, true, 5.0)
		seat.name = "PitBench"
		# A silica-cloth cushion, the one textile a lava body can sit on.
		CalderaFurniture.piece(body, Vector3(0.28, 0.04, 0.22), OLIVINE.lightened(0.2), Vector3(p.x, seat_top - 0.04, p.y), yaw, false, SuperEgg.EPSILON_SOFT)
	# The step down, at the door end.
	var step := at + Vector2(-half.x + 0.3, 0.0)
	CalderaFurniture.piece(body, Vector3(0.28, (depth * 0.5) * 0.5, 0.45), SINTER, Vector3(step.x, -depth + depth * 0.25, step.y), 0.0, true, 5.0)
	# Heated stone at the pit's heart: a low sinter slab, warm to sit beside;
	# its warmth shows only in the light the pit's own lamp gives it.
	CalderaFurniture.piece(body, Vector3(0.8, 0.05, 0.45), SINTER.darkened(0.04), Vector3(at.x, -depth + 0.05, at.y), 0.0, true, 6.0).name = "HeatedStone"
	# A concealed LED line under the pit's lip, lighting the cushions.
	var lip := PackedVector2Array()
	for i in 48:
		var t := TAU * float(i) / 48.0
		var c := cos(t)
		var s := sin(t)
		lip.append(at + Vector2(signf(c) * pow(absf(c), 2.0 / exponent) * (half.x - 0.03), signf(s) * pow(absf(s), 2.0 / exponent) * (half.y - 0.03)))
	for i in lip.size():
		var a := lip[i]
		var b := lip[(i + 1) % lip.size()]
		var mid := (a + b) * 0.5
		CalderaFurniture.led_line(body, Vector3(mid.x, -0.035, mid.y), atan2(-(b - a).y, (b - a).x), a.distance_to(b) + 0.01, CalderaFurniture.LED_WARM)
	CalderaFurniture.concealed_light(body, Vector3(at.x, -0.1, at.y), Color(1.0, 0.6, 0.3), 0.8, 3.5)
	FireCalderaBuildings._marker(body, "MediationMarker", Vector3(at.x, -depth, at.y), 0.0)
	CalderaFurniture.concealed_light(body, Vector3(at.x, 3.2, at.y), CalderaFurniture.LED_WARM, 0.9, 6.0)


## Eris's suite: her own door from the promenade's east end into an entry, a
## receiving and shaping room with a tall obsidian glass to shape her
## silhouette by, a private immersion well, a cooler resting niche in the back
## corner, and along the east wall her shelf of objects from seventy years.
static func _suite(body: StaticBody3D) -> void:
	# Entry: a sinter ledge to set things on, by the door.
	CalderaFurniture.piece(body, Vector3(0.18, 0.45, 0.3), SINTER.darkened(0.08), Vector3(7.55, 0.45, 3.55), 0.0, true)
	# Receiving: two warm seats side by side, a silica cloth over one.
	for x: float in [5.0, 6.3]:
		CalderaFurniture.piece(body, Vector3(0.34, 0.22, 0.3), RHYOLITE, Vector3(x, 0.22, 3.4), 0.0, true, SuperEgg.EPSILON_SOFT)
	CalderaFurniture.piece(body, Vector3(0.3, 0.02, 0.32), SILICA, Vector3(6.3, 0.45, 3.42), 0.15, false, SuperEgg.EPSILON_SOFT)
	# Shaping: a tall silvered glass on the party wall in a thin forged iron
	# frame, a line behind its head.
	var mirror := CalderaFurniture.piece(body, Vector3(0.02, 1.0, 0.5), Color(0.86, 0.87, 0.86), Vector3(PARTY_X + 0.14, 1.25, 2.9), 0.0, false, 7.0)
	mirror.name = "ShapingGlass"
	mirror.material_override = SolidModel.material(Color(0.86, 0.87, 0.86), 0.04, 0.8)
	var frame := SuperEgg.build_part(Vector3(0.015, 1.04, 0.54), IRON, 7.0, 7.0)
	frame.material_override = SolidModel.material(IRON, 0.3, 0.85)
	frame.position = Vector3(PARTY_X + 0.125, 1.25, 2.9)
	body.add_child(frame)
	CollisionPolicy.mark_decorative(frame)
	CalderaFurniture.led_line(body, Vector3(PARTY_X + 0.115, 2.27, 2.9), PI * 0.5, 0.9, CalderaFurniture.LED_WARM)
	_lava_bed(body)
	# Beside the bed, a mat of ceramic fibre to step out onto.
	CalderaFurniture.mat(body, Vector3(BED_CENTRE.x, 0.0, BED_CENTRE.y + BED_HALF.y + 0.5), 0.0, Vector2(1.6, 0.7), CERAMIC.darkened(0.05))
	# The day couch in the stone alcove, back east: a cool slab under a silica
	# cover, a basalt-fibre throw folded at one end.
	CalderaFurniture.piece(body, Vector3(0.9, 0.16, 0.5), COOL_LEDGE, Vector3(6.9, 0.16, -0.35), 0.0, true, SuperEgg.EPSILON_SOFT)
	CalderaFurniture.piece(body, Vector3(0.86, 0.035, 0.47), SILICA, Vector3(6.9, 0.34, -0.35), 0.0, false, SuperEgg.EPSILON_SOFT)
	CalderaFurniture.piece(body, Vector3(0.24, 0.05, 0.42), BASALT_FIBRE, Vector3(7.5, 0.41, -0.33), 0.05, false, SuperEgg.EPSILON_SOFT)
	CalderaFurniture.piece(body, Vector3(0.08, 1.1, 0.5), TUFF, Vector3(5.9, 1.1, -0.4), 0.0, true)
	# A curtain of silica cloth drawn half across the window onto the
	# promenade, on a thin iron rod.
	_curtain(body, Vector3(3.5, 0.0, HALF_Z - 0.3), 1.6, 3.0)
	# Seventy years of objects: glass and steel shelves on the east wall, each
	# piece different, gifts and keepsakes from every household.
	CalderaFurniture.shelves(body, Vector3(7.62, 0.0, 2.0), PI * 0.5, 2.4, 3, func(b: StaticBody3D, p: Vector3, i: int) -> void:
		var keepsakes: Array[Color] = [Color(0.80, 0.76, 0.70), Color(0.74, 0.78, 0.66), Color(0.82, 0.74, 0.62), Color(0.72, 0.74, 0.76), Color(0.78, 0.68, 0.64), Color(0.86, 0.84, 0.80)]
		var size := 0.04 + 0.03 * float((i * 7) % 3)
		CalderaFurniture.piece(b, Vector3(size, size * (1.0 + float(i % 2)), size), keepsakes[(i * 5) % keepsakes.size()], p + Vector3(0, size * (1.0 + float(i % 2)), 0), float(i), false, 2.0 + float(i % 4)), IRON)
	CalderaFurniture.concealed_light(body, Vector3(5.0, 3.2, 2.4), CalderaFurniture.LED_WARM, 0.9, 6.0)


## Eris's lava bed, between a bed and a bath: a raised superellipse of cast
## forsterite with a deep superellipse hollow punched into it, which the lava
## fills from a duct beneath. She rests in it. The duct shows only as an iron
## inspection plate in the floor at the bed's foot.
static func _lava_bed(body: StaticBody3D) -> void:
	var solid := CSGCombiner3D.new()
	solid.name = "LavaBed"
	solid.use_collision = true
	solid.collision_layer = 1
	solid.collision_mask = 0
	solid.position = Vector3(BED_CENTRE.x, 0.0, BED_CENTRE.y)
	body.add_child(solid)
	var stone := SolidModel.material(FORSTERITE, 0.7, 0.0)
	var shell := SolidModel.add_profile(solid, "Shell", BED_HEIGHT, Vector2(BED_HALF.x, BED_HALF.y), 4.0, CSGShape3D.OPERATION_UNION, stone, Vector3(0, BED_HEIGHT * 0.5, 0), 72)
	shell.rotation.z = PI * 0.5
	var hollow := SolidModel.add_profile(solid, "Hollow", BED_HEIGHT, Vector2(BED_HALF.x - BED_WALL, BED_HALF.y - BED_WALL), 4.0, CSGShape3D.OPERATION_SUBTRACTION, stone, Vector3(0, BED_HEIGHT * 0.5 + 0.18, 0), 72)
	hollow.rotation.z = PI * 0.5
	var lava := MeshInstance3D.new()
	lava.name = "BedLava"
	lava.mesh = SolidModel.extruded_profile_mesh(0.03, Vector2(BED_HALF.x - BED_WALL - 0.005, BED_HALF.y - BED_WALL - 0.005), 4.0, 72)
	var material := StandardMaterial3D.new()
	material.albedo_color = MOLTEN
	material.emission_enabled = true
	material.emission = MOLTEN
	material.emission_energy_multiplier = 2.2
	lava.material_override = material
	lava.position = Vector3(BED_CENTRE.x, BED_LAVA_Y, BED_CENTRE.y)
	lava.rotation.z = PI * 0.5
	body.add_child(lava)
	CollisionPolicy.mark_decorative(lava)
	# The duct's inspection plate in the floor at the bed's foot.
	var plate := SuperEgg.build_part(Vector3(0.16, 0.006, 0.16), PUMICE.darkened(0.12), 2.4, 6.0)
	plate.material_override = SolidModel.material(PUMICE.darkened(0.12), 0.8, 0.0)
	plate.position = Vector3(BED_CENTRE.x + BED_HALF.x + 0.3, 0.008, BED_CENTRE.y)
	body.add_child(plate)
	CollisionPolicy.mark_decorative(plate)
	CalderaFurniture.concealed_light(body, Vector3(BED_CENTRE.x, 0.9, BED_CENTRE.y), Color(1.0, 0.55, 0.22), 1.0, 4.5)
	FireCalderaBuildings._marker(body, "ErisRestMarker", Vector3(BED_CENTRE.x, BED_LAVA_Y, BED_CENTRE.y), 0.0)


## A soft curtain of silica cloth on a thin iron rod: a few hanging folds,
## faintly translucent, `width` wide, its rod at `height`.
static func _curtain(body: StaticBody3D, at: Vector3, width: float, height: float) -> void:
	_branch(body, at + Vector3(-width * 0.55, height, 0), at + Vector3(width * 0.55, height, 0), 0.012)
	var folds := 5
	for i in folds:
		var x := -width * 0.5 + width * (float(i) + 0.5) / float(folds) * 0.6
		var fold := SuperEgg.build_part(Vector3(width * 0.08, (height - 0.12) * 0.5, 0.025), SILICA, 3.0, 6.0)
		var cloth := SolidModel.material(Color(SILICA, 0.85), 0.9, 0.0)
		cloth.cull_mode = BaseMaterial3D.CULL_DISABLED
		fold.material_override = cloth
		fold.position = at + Vector3(x, (height - 0.12) * 0.5 + 0.06, 0.03 * float(i % 2))
		body.add_child(fold)
		CollisionPolicy.mark_decorative(fold)
