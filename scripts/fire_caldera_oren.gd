class_name FireCalderaOren
extends RefCounted

## The Oren mineral house (fire_caldera_buildings.md, section 4): Pela's gem
## counter and assay and Savi's preparation studio below, the siblings' home
## above. A commercial building, so the glass-pavilion family's frame and
## plinth, but its own glass (the stained band and forked posts are the guest
## house's alone). A gem dealer's front, made the city's way, by pouring:
##   - the shop's front is a wall of hand-cast solid glass bricks, each one a
##     little different, clear at eye level and deepening toward amethyst at
##     the top like the colour zoning of a geode (teal over the assay room); a
##     few larger cast blocks set into it are the display cells, each holding
##     one lit stone;
##   - the home above looks out through clear glass behind a screen of
##     vertical dichroic fins, whose colour turns teal, violet and gold with
##     the angle, the play of colour in labradorite or opal.
##
## Split level (approved 2026-10-07). The plot rises 1.35 m from the counter
## front to the service loop behind, so the shop stands at the promenade's
## level and the workshop half 1.35 m higher, flush with the service loop:
##   - front band (z 1..6), at the datum: the counter (west), the gem store
##     between a small lobby and the front wall, the assay room (east);
##   - the staff corridor (z -0.4..1): level with the workshop for most of its
##     length, then a ramp down to a landing at the assay room's door;
##   - back band (z -6..-0.4), at +1.35: receiving (west, Pela's door from the
##     service loop), the tested-stock store, Savi's studio (east).
## The home above (+4.0) is reached by an open-air ramp in the 2 m east bay,
## from a landing at the service loop's level, never through the shop. Its
## roof is flat. Local +Z faces the promenade; +X faces the east bay.

const SHELL_SIZE := Vector2(15.0, 12.0)
const SHELL_CENTRE := Vector2(-1.0, 0.0)
const TEAL := Color(0.10, 0.55, 0.55)
const VIOLET := Color(0.45, 0.25, 0.62)
const T := 0
const V := 1
const STAINED: Array[Color] = [TEAL, VIOLET]
const RAISE := 1.35
const UPPER := 4.0
const SLAB := 0.2
const FLOOR := Color(0.30, 0.28, 0.27)
const PARTITION := FireCalderaBuildings.BASALT_PARTITION
const INNER_DOOR_WIDTH := FireCalderaBuildings.INNER_DOOR_WIDTH
const INNER_DOOR_HEIGHT := FireCalderaBuildings.INNER_DOOR_HEIGHT
const WALL_Z_FRONT := 1.0
const WALL_Z_BACK := -0.4
const RAMP_TOP_X := 1.2
const RAMP_FOOT_X := 5.2
const ASSAY_DOOR_X := 5.85
const STORE_DOOR_X := -2.0
const STUDIO_DOOR_X := 0.4
const RECEIVING_INNER_DOOR_X := -6.0
const RECEIVING_DOOR_X := -6.0
const GEM_DOOR_X := 0.0
const HOME_DOOR_Z := 1.2


static func spec_ground() -> Dictionary:
	var smoky := CalderaShell.SMOKY_GLASS
	var clear := CalderaShell.CLEAR_GLASS
	return {
		"size": SHELL_SIZE, "offset": SHELL_CENTRE, "stained": STAINED, "roof": false, "transom": false,
		"walls": {
			# The counter's cast-brick front, its door, the gem store's stone,
			# the assay room's bricks (built by _brick_fronts in the open bays).
			"front": [
				{"to": 2.2, "kind": "open"}, {"to": 4.8, "kind": "door", "label": "shop door"},
				{"to": 7.0, "kind": "open"}, {"to": 10.0, "kind": "stone"},
				{"to": 15.0, "kind": "open"},
			],
			# Against the retained slope: full-height stone, Pela's receiving
			# door on the workshop's raised floor.
			"back": [
				{"to": 1.2, "kind": "stone", "band": -1},
				{"to": 3.8, "kind": "door", "band": -1, "sill": RAISE, "clear": 2.0, "height": 2.3, "label": "receiving door"},
				{"to": 8.5, "kind": "stone", "band": -1}, {"to": 15.0, "kind": "stone", "band": -1},
			],
			"west": [
				{"to": 5.6, "kind": "stone", "band": -1}, {"to": 7.0, "kind": "stone", "band": V}, {"to": 12.0, "kind": "stone", "band": V},
			],
			"east": [
				{"to": 5.6, "kind": "stone", "band": -1}, {"to": 7.0, "kind": "stone", "band": T}, {"to": 12.0, "kind": "stone", "band": T},
			],
		},
	}


static func spec_upper() -> Dictionary:
	var clear := CalderaShell.CLEAR_GLASS
	var smoky := CalderaShell.SMOKY_GLASS
	return {
		"size": SHELL_SIZE, "offset": SHELL_CENTRE, "stained": STAINED, "pitch": 0.0, "transom": false,
		# The lift rises past the east wall: no overhang there.
		"overhang": {"east": 0.0},
		"walls": {
			# The home's outlook over the reservoir.
			"front": [
				{"to": 2.5, "kind": "glass", "tint": clear, "band": V}, {"to": 5.0, "kind": "glass", "tint": clear, "band": T},
				{"to": 7.5, "kind": "glass", "tint": clear, "band": V}, {"to": 10.0, "kind": "glass", "tint": clear, "band": T},
				{"to": 12.5, "kind": "glass", "tint": clear, "band": V}, {"to": 15.0, "kind": "glass", "tint": clear, "band": T},
			],
			"back": [
				{"to": 5.0, "kind": "stone", "band": V}, {"to": 7.5, "kind": "glass", "tint": smoky, "band": T},
				{"to": 10.0, "kind": "glass", "tint": smoky, "band": T}, {"to": 15.0, "kind": "stone", "band": V},
			],
			"west": [
				{"to": 6.0, "kind": "stone", "band": V}, {"to": 9.0, "kind": "glass", "tint": smoky, "band": V}, {"to": 12.0, "kind": "stone", "band": V},
			],
			"east": [
				{"to": 5.9, "kind": "stone", "band": T}, {"to": 8.5, "kind": "door", "band": T, "label": "home door"},
				{"to": 12.0, "kind": "stone", "band": T},
			],
		},
	}


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), spec_ground())
	_brick_fronts(body)
	_floors(body)
	_ground_partitions(body)
	var upper := StaticBody3D.new()
	upper.name = "OrenHome"
	upper.collision_layer = 1
	upper.collision_mask = 0
	upper.position = Vector3(0, UPPER, 0)
	body.add_child(upper)
	CalderaShell.add_volume(upper, spec_upper())
	_dichroic_fins(upper)
	_parapet(upper)
	_upper_partitions(upper)
	_east_bay(body)
	_lift(body)
	_receiving_bridge(body)
	_lights(body, upper)
	_furnish(body, upper)
	return body


## The rooms, kept spare: Pela's counter facing the door with stones on the
## shelves behind; the vault's shelves; the assay bench with lenses; crates in
## receiving; the tested stock; Savi's bench and heat cell; above, seats round
## a low table, a lava bed each for Pela and Savi, the pantry's shelves of
## mineral delicacies.
static func _furnish(body: StaticBody3D, upper: StaticBody3D) -> void:
	var stones := func(b: StaticBody3D, p: Vector3, i: int) -> void:
		var tones: Array[Color] = [Color(0.55, 0.30, 0.68), Color(0.25, 0.62, 0.60), Color(0.85, 0.55, 0.20), Color(0.70, 0.20, 0.28), Color(0.85, 0.85, 0.80)]
		CalderaFurniture.piece(b, Vector3(0.05, 0.05, 0.05), tones[(i * 3) % tones.size()], p + Vector3(0, 0.05, 0), float(i), false, 2.4)
	var r := RAISE
	# Counter room.
	CalderaFurniture.counter(body, Vector3(-5.0, 0.0, 2.6), PI, 2.4)
	CalderaFurniture.shelves(body, Vector3(-8.1, 0.0, 3.8), -PI * 0.5, 2.0, 3, stones)
	FireCalderaBuildings._marker(body, "PelaStand", Vector3(-5.0, 0.0, 1.7), 0.0)
	# Gem store.
	CalderaFurniture.shelves(body, Vector3(0.0, 0.0, 5.6), 0.0, 2.2, 4, stones)
	# Assay room.
	CalderaFurniture.table(body, Vector3(4.0, 0.0, 4.4), 0.0, 2.0, 0.7)
	CalderaFurniture.chair(body, Vector3(4.0, 0.0, 3.5), PI, CalderaFurniture.FIBRE_GREY)
	for i in 3:
		CalderaFurniture.jar(body, Vector3(3.4 + 0.5 * float(i), 0.8, 4.5), [Color(0.55, 0.30, 0.68), Color(0.25, 0.62, 0.60), Color(0.85, 0.55, 0.20)][i], 0.05)
	# Receiving: crates of raw ore.
	for at: Vector3 in [Vector3(-7.9, r, -2.4), Vector3(-7.9, r, -3.4), Vector3(-4.1, r, -2.6)]:
		CalderaFurniture.chest(body, at, PI * 0.5 if at.x < -6.0 else -PI * 0.5, 0.8)
	# Tested stock.
	CalderaFurniture.shelves(body, Vector3(-2.0, r, -5.6), PI, 2.2, 3, stones)
	# Savi's studio: the bench and a heat cell.
	CalderaFurniture.table(body, Vector3(3.0, r, -3.4), 0.0, 2.6, 0.8)
	CalderaFurniture.piece(body, Vector3(0.45, 0.6, 0.4), CalderaShell.BASALT, Vector3(5.7, r + 0.6, -5.2), 0.0, true)
	FireCalderaBuildings._glow(body, "HeatCellPort", Vector3(0.2, 0.12, 0.01), Vector3(5.7, r + 0.75, -4.79), Color(1.0, 0.5, 0.12))
	# Above: the front room's seats round a low table.
	CalderaFurniture.low_table(upper, Vector3(-3.0, 0.0, 3.4), 0.0)
	for side: float in [-1.0, 1.0]:
		CalderaFurniture.piece(upper, Vector3(0.36, 0.22, 0.3), CalderaShell.BASALT.lightened(0.08), Vector3(-3.0 + side * 1.0, 0.22, 3.4), 0.0, true, SuperEgg.EPSILON_SOFT)
	# A lava bed each: a cast basalt basin the lava fills from beneath.
	for x: float in BED_XS:
		CalderaFurniture.piece(upper, Vector3(1.1, 0.28, 0.55), CalderaShell.BASALT, Vector3(x, 0.28, BED_Z), 0.0, true, 4.0)
		FireCalderaBuildings._glow(upper, "BedLava", Vector3(0.95, 0.02, 0.42), Vector3(x, BED_LAVA, BED_Z), Color(1.0, 0.42, 0.08))
		CalderaFurniture.concealed_light(upper, Vector3(x, 1.0, BED_Z), Color(1.0, 0.55, 0.22), 0.8, 4.0)
	# The pantry: shelves of Savi's mineral delicacies.
	CalderaFurniture.shelves(upper, Vector3(4.0, 0.0, -5.6), PI, 2.4, 3, stones)
	_furnish_more(body, upper)


## The second layer: what tells the rooms apart. A glass case of finished
## stones in the counter room; the vault's strongbox; the assay room's lens on
## its stand, balance and small heat cell; Savi's stations along the studio's
## back wall in working order (crushing, grading, alloying, the heat cell,
## then the cooling rack and presentation trays on the bench); in the home, a
## split geode on a plinth, the one stone they kept.
static func _furnish_more(body: StaticBody3D, upper: StaticBody3D) -> void:
	var r := RAISE
	var steel := CalderaShell.STEEL_BLUED
	var glass := Color(0.86, 0.92, 0.95, 0.22)
	var gems: Array[Color] = [Color(0.55, 0.30, 0.68), Color(0.25, 0.62, 0.60), Color(0.85, 0.55, 0.20), Color(0.70, 0.20, 0.28)]
	# Counter room: a glass case of finished stones.
	CalderaFurniture.piece(body, Vector3(0.7, 0.42, 0.3), CalderaShell.BASALT, Vector3(-2.6, 0.42, 3.9), PI * 0.5, true)
	var case := CalderaFurniture.piece(body, Vector3(0.68, 0.14, 0.28), glass, Vector3(-2.6, 0.98, 3.9), PI * 0.5, false, 6.0)
	var case_glass := SolidModel.material(glass, 0.04, 0.05)
	case_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	case.material_override = case_glass
	for i in 4:
		CalderaFurniture.piece(body, Vector3(0.04, 0.04, 0.04), gems[i], Vector3(-2.6, 0.9, 3.4 + 0.33 * float(i)), float(i), false, 2.4)
	CalderaFurniture.led_line(body, Vector3(-2.6, 0.86, 3.9), PI * 0.5, 1.2, CalderaFurniture.LED_WARM)
	# The vault's strongbox, against its west wall.
	CalderaFurniture.chest(body, Vector3(-1.05, 0.0, 4.2), PI * 0.5, 0.9)
	CalderaFurniture.piece(body, Vector3(0.06, 0.08, 0.03), CalderaShell.STAINLESS, Vector3(-0.78, 0.32, 4.2), PI * 0.5, false, 2.0)
	# Assay: a lens on a steel stand, a balance, a small heat cell.
	CalderaShell._metal(body, Vector3(3.5, 0.98, 4.5), Vector3(0.025, 0.36, 0.025), steel, false)
	var lens := CalderaFurniture.piece(body, Vector3(0.09, 0.09, 0.012), glass, Vector3(3.5, 1.18, 4.42), 0.0, false, 2.0)
	lens.material_override = case_glass
	CalderaShell._metal(body, Vector3(4.6, 0.95, 4.5), Vector3(0.4, 0.02, 0.02), CalderaShell.STAINLESS, false)
	for side: float in [-1.0, 1.0]:
		CalderaFurniture.piece(body, Vector3(0.08, 0.012, 0.08), CalderaShell.STAINLESS, Vector3(4.6 + side * 0.2, 0.88, 4.5), 0.0, false, 2.0)
	CalderaShell._metal(body, Vector3(4.6, 0.85, 4.5), Vector3(0.025, 0.12, 0.025), steel, false)
	CalderaFurniture.piece(body, Vector3(0.3, 0.35, 0.3), CalderaShell.BASALT, Vector3(6.1, 0.35, 4.9), 0.0, true)
	FireCalderaBuildings._glow(body, "AssayCellPort", Vector3(0.1, 0.07, 0.01), Vector3(6.1, 0.45, 4.59), Color(1.0, 0.5, 0.12))
	# Savi's stations along the studio's back wall, in working order.
	# Crushing: a heavy basalt mortar and its pestle.
	CalderaFurniture.piece(body, Vector3(0.3, 0.25, 0.3), CalderaShell.BASALT, Vector3(0.4, r + 0.25, -5.3), 0.0, true, 2.6)
	CalderaFurniture.piece(body, Vector3(0.05, 0.22, 0.05), CalderaShell.BASALT.lightened(0.1), Vector3(0.45, r + 0.62, -5.3), 0.3, false, 2.2)
	# Grading: three stacked steel sieves on a stand.
	CalderaFurniture.piece(body, Vector3(0.3, 0.38, 0.25), CalderaShell.VOLCANIC_STONE, Vector3(1.4, r + 0.38, -5.4), 0.0, true)
	for i in 3:
		CalderaFurniture.piece(body, Vector3(0.22, 0.04, 0.22), CalderaShell.STAINLESS, Vector3(1.4, r + 0.82 + 0.09 * float(i), -5.4), 0.0, false, 2.0)
	# Alloying: a crucible glowing on its steel ring.
	CalderaShell._metal(body, Vector3(3.6, r + 0.4, -5.3), Vector3(0.5, 0.8, 0.5), steel, true)
	var crucible := SuperEgg.build_part(Vector3(0.16, 0.14, 0.16), Color(1.0, 0.45, 0.1), 2.4, 2.4)
	var molten := StandardMaterial3D.new()
	molten.albedo_color = Color(1.0, 0.45, 0.1)
	molten.emission_enabled = true
	molten.emission = Color(1.0, 0.45, 0.1)
	molten.emission_energy_multiplier = 2.0
	crucible.material_override = molten
	crucible.position = Vector3(3.6, r + 0.95, -5.3)
	body.add_child(crucible)
	CollisionPolicy.mark_decorative(crucible)
	CalderaFurniture.concealed_light(body, Vector3(3.6, r + 1.4, -5.0), Color(1.0, 0.55, 0.25), 0.7, 3.5)
	# Cooling: a steel rack on the east wall; presentation trays on the bench.
	CalderaFurniture.shelves(body, Vector3(6.15, r, -2.4), -PI * 0.5, 1.6, 2, func(b: StaticBody3D, p: Vector3, i: int) -> void:
		CalderaFurniture.piece(b, Vector3(0.1, 0.02, 0.1), Color(0.70, 0.62, 0.55), p + Vector3(0, 0.02, 0), 0.0, false, 4.0), CalderaShell.STAINLESS)
	for i in 3:
		var tray := Vector3(2.2 + 0.8 * float(i), r + 0.81, -3.4)
		CalderaFurniture.piece(body, Vector3(0.25, 0.015, 0.18), CalderaShell.BASALT.lightened(0.2), tray, 0.0, false, 5.0)
		for j in 3:
			CalderaFurniture.piece(body, Vector3(0.03, 0.025, 0.03), [Color(0.55, 0.62, 0.40), Color(0.80, 0.70, 0.45), Color(0.62, 0.40, 0.36)][(i + j) % 3], tray + Vector3(-0.12 + 0.12 * float(j), 0.035, 0.0), 0.0, false, 2.4)
	FireCalderaBuildings._marker(body, "SaviStand", Vector3(3.0, r, -2.6), PI)
	# The home: a split geode on a basalt plinth, amethyst inside.
	CalderaFurniture.piece(upper, Vector3(0.3, 0.45, 0.3), CalderaShell.BASALT, Vector3(4.6, 0.45, 4.6), 0.0, true)
	CalderaFurniture.piece(upper, Vector3(0.28, 0.3, 0.1), Color(0.35, 0.32, 0.30), Vector3(4.6, 1.2, 4.62), 0.0, false, 2.2)
	var crystal := CalderaFurniture.piece(upper, Vector3(0.21, 0.23, 0.02), Color(0.55, 0.32, 0.72), Vector3(4.6, 1.2, 4.52), 0.0, false, 2.2)
	var amethyst := StandardMaterial3D.new()
	amethyst.albedo_color = Color(0.55, 0.32, 0.72)
	amethyst.emission_enabled = true
	amethyst.emission = Color(0.45, 0.25, 0.62)
	amethyst.emission_energy_multiplier = 0.5
	amethyst.roughness = 0.1
	crystal.material_override = amethyst


## Concealed light, one per room or run, until the rooms are furnished.
static func _lights(body: StaticBody3D, upper: StaticBody3D) -> void:
	var warm := CalderaFurniture.LED_WARM
	for at: Vector3 in [Vector3(-5.0, 3.0, 3.5), Vector3(4.0, 3.0, 3.5), Vector3(0.0, 3.0, 4.0),
			Vector3(-6.0, 3.3, -3.2), Vector3(-2.0, 3.3, -3.2), Vector3(3.0, 3.3, -3.2),
			Vector3(-4.0, 3.2, 0.3), Vector3(3.5, 3.0, 0.3)]:
		CalderaFurniture.concealed_light(body, at, warm, 0.8, 5.5)
	for at: Vector3 in [Vector3(-5.0, 3.0, 3.0), Vector3(3.0, 3.0, 3.0), Vector3(-6.0, 3.0, -3.0), Vector3(-1.0, 3.0, -3.0), Vector3(4.0, 3.0, -3.0)]:
		CalderaFurniture.concealed_light(upper, at, warm, 0.8, 5.5)


## The home's two lava beds, in the body's plan at the upper floor: for the
## terrain's lava queries, as Nahl registers its own.
const BED_XS: Array[float] = [-6.0, -1.0]
const BED_Z := -3.6
const BED_LAVA := 0.55


static func register_lava(body: Node3D, terrain: Node) -> void:
	for x: float in BED_XS:
		var world := PackedVector2Array()
		var height := 0.0
		for corner: Vector2 in [Vector2(-0.9, -0.38), Vector2(0.9, -0.38), Vector2(0.9, 0.38), Vector2(-0.9, 0.38)]:
			var at := body.global_transform * Vector3(x + corner.x, UPPER + BED_LAVA, BED_Z + corner.y)
			world.append(Vector2(at.x, at.z))
			height = at.y
		terrain.register_lava_polygon(world, height)


# ---------------------------------------------------------------------------
# The glass.
# ---------------------------------------------------------------------------

const BRICK := Vector3(0.30, 0.15, 0.22)
const BRICK_JOINT := 0.006
const CLEAR_CAST := Color(0.52, 0.62, 0.66, 0.14)
const AMETHYST := Color(0.46, 0.24, 0.66, 0.66)
const TEAL_CAST := Color(0.18, 0.58, 0.58, 0.62)


## The cast-brick fronts in the ground storey's open bays: the counter's two
## runs either side of the door, deepening to amethyst, three display cells in
## each at eye height; the assay room's run, deepening to teal, no cells.
static func _brick_fronts(body: StaticBody3D) -> void:
	var z := SHELL_SIZE.y * 0.5
	var x0 := SHELL_CENTRE.x - SHELL_SIZE.x * 0.5
	var post := CalderaShell.POST * 0.5
	var corner := CalderaShell.POST
	_brick_wall(body, Vector2(x0 + corner, z), Vector2(x0 + 2.2 - post, z), AMETHYST, [0.55, 1.35])
	_brick_wall(body, Vector2(x0 + 4.8 + post, z), Vector2(x0 + 7.0 - post, z), AMETHYST, [0.6, 1.5])
	_brick_wall(body, Vector2(x0 + 10.0 + post, z), Vector2(x0 + 15.0 - corner, z), TEAL_CAST, [])


## A wall of solid cast-glass bricks along Z = from.y (front wall), stretcher
## bond with hairline joints, one MultiMesh: each brick's tint drifts a little
## (no two pours are the same) and deepens from clear below toward `deep` at
## the top. `cells` are positions along the run (from its start) of display
## cells: a larger cast block at eye height holding one lit stone.
static func _brick_wall(body: StaticBody3D, from: Vector2, to: Vector2, deep: Color, cells: Array) -> void:
	var length := to.x - from.x
	var height := CalderaShell.STOREY - 0.12
	var rows := int(height / (BRICK.y + BRICK_JOINT))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(absf(from.x) * 1000.0) + 7
	var cell_half := Vector2(0.33, 0.24)
	var cell_y := 1.45
	var transforms: Array[Transform3D] = []
	var colours: Array[Color] = []
	for row in rows:
		var y := 0.06 + (BRICK.y + BRICK_JOINT) * (float(row) + 0.5)
		var shift := (BRICK.x + BRICK_JOINT) * 0.5 if row % 2 == 1 else 0.0
		var x := -shift
		while x < length:
			var a := maxf(x, 0.0)
			var b := minf(x + BRICK.x, length)
			x += BRICK.x + BRICK_JOINT
			if b - a < 0.06:
				continue
			var centre := (a + b) * 0.5
			var in_cell := false
			for cell: float in cells:
				if absf(centre - cell) < cell_half.x + (b - a) * 0.5 and absf(y - cell_y) < cell_half.y + BRICK.y * 0.5:
					in_cell = true
			if in_cell:
				continue
			var t := clampf((y - 1.2) / (height - 1.2), 0.0, 1.0)
			var tint := CLEAR_CAST.lerp(deep, pow(t, 1.4))
			tint = tint.lightened(rng.randf_range(-0.05, 0.05))
			tint.a = clampf(tint.a + rng.randf_range(-0.04, 0.04), 0.1, 0.8)
			colours.append(tint)
			transforms.append(Transform3D(Basis().scaled(Vector3((b - a) / BRICK.x, 1.0, 1.0)), Vector3(from.x + centre, y, from.y)))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = SuperEgg.build_mesh(BRICK * 0.5, 10.0, 10.0)
	multimesh.instance_count = transforms.size()
	for i in transforms.size():
		multimesh.set_instance_transform(i, transforms[i])
		multimesh.set_instance_color(i, colours[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = "CastGlassBricks"
	instance.multimesh = multimesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.12
	material.metallic_specular = 0.35
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	body.add_child(instance)
	CollisionPolicy.mark_decorative(instance)
	var holder := MeshInstance3D.new()
	body.add_child(holder)
	CollisionPolicy.add_box(body, holder, Vector3(length, height, BRICK.z), Vector3((from.x + to.x) * 0.5, 0.06 + height * 0.5, from.y), Basis(), false)
	# The display cells: a cast block, deeper than the bricks, with one stone
	# lit inside it.
	var stones: Array[Color] = [Color(0.55, 0.30, 0.68), Color(0.25, 0.62, 0.60), Color(0.85, 0.55, 0.20), Color(0.70, 0.20, 0.28)]
	for i in cells.size():
		var at := Vector3(from.x + float(cells[i]), cell_y, from.y)
		var block := SuperEgg.build_part(Vector3(cell_half.x - 0.01, cell_half.y - 0.01, 0.2), CLEAR_CAST, 6.0, 6.0)
		var glass := SolidModel.material(Color(0.90, 0.93, 0.95, 0.22), 0.04, 0.1)
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		block.material_override = glass
		block.position = at
		body.add_child(block)
		CollisionPolicy.mark_decorative(block)
		var stone := SuperEgg.build_part(Vector3(0.06, 0.07, 0.05), stones[(i + int(absf(from.x))) % stones.size()], 3.0, 2.2)
		var lit := StandardMaterial3D.new()
		lit.albedo_color = stones[(i + int(absf(from.x))) % stones.size()]
		lit.emission_enabled = true
		lit.emission = lit.albedo_color
		lit.emission_energy_multiplier = 1.4
		lit.roughness = 0.05
		stone.material_override = lit
		stone.position = at
		body.add_child(stone)
		CollisionPolicy.mark_decorative(stone)


## The home's screen: vertical dichroic glass fins standing off the front
## glass, turned a little toward the reservoir, their colour shifting with the
## angle of view.
static func _dichroic_fins(upper: StaticBody3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = _dichroic_shader()
	var x0 := SHELL_CENTRE.x - SHELL_SIZE.x * 0.5 + 0.3
	var x1 := SHELL_CENTRE.x + SHELL_SIZE.x * 0.5 - 0.3
	var count := int((x1 - x0) / 0.7) + 1
	for i in count:
		var x := lerpf(x0, x1, float(i) / float(count - 1))
		var fin := MeshInstance3D.new()
		fin.name = "DichroicFin"
		var box := BoxMesh.new()
		box.size = Vector3(0.03, CalderaShell.STOREY - 0.3, 0.5)
		fin.mesh = box
		fin.material_override = material
		fin.position = Vector3(x, (CalderaShell.STOREY - 0.3) * 0.5 + 0.1, SHELL_SIZE.y * 0.5 + 0.4)
		fin.rotation.y = deg_to_rad(28.0)
		upper.add_child(fin)
		CollisionPolicy.mark_decorative(fin)
	# The fins' heads and feet: two slim blued-steel rails.
	for y: float in [0.1, CalderaShell.STOREY - 0.2]:
		CalderaShell._metal(upper, Vector3((x0 + x1) * 0.5, y, SHELL_SIZE.y * 0.5 + 0.4), Vector3(x1 - x0 + 0.3, 0.05, 0.08), CalderaShell.STEEL_BLUED, false)


## The roof terrace: a cast upstand round the roof's edge with a balustrade
## of dichroic glass on it (the fins' glass), open on the east side where the
## lift arrives; two seats and a low table looking over the reservoir.
const LIFT_AT := Vector2(7.62, 3.7)
const LIFT_SIZE := Vector2(1.66, 1.6)


static func roof_top() -> float:
	return CalderaShell.STOREY + 0.10 + CalderaShell.ROOF_DEPTH * 0.5


static func _parapet(upper: StaticBody3D) -> void:
	var top := roof_top()
	var half := SHELL_SIZE * 0.5 + Vector2.ONE * 0.35
	var x0 := SHELL_CENTRE.x - half.x
	var x1 := SHELL_CENTRE.x + SHELL_SIZE.x * 0.5 - 0.08
	var glass := ShaderMaterial.new()
	glass.shader = _dichroic_shader()
	# [from, to] runs of upstand; the east side breaks for the lift's landing.
	var gap0 := LIFT_AT.y - LIFT_SIZE.y * 0.5 - 0.05
	var gap1 := LIFT_AT.y + LIFT_SIZE.y * 0.5 + 0.05
	var runs := [
		[Vector2(x0, -half.y), Vector2(x1, -half.y)], [Vector2(x0, half.y), Vector2(x1, half.y)],
		[Vector2(x0, -half.y), Vector2(x0, half.y)],
		[Vector2(x1, -half.y), Vector2(x1, gap0)], [Vector2(x1, gap1), Vector2(x1, half.y)],
	]
	for run: Array in runs:
		var a: Vector2 = run[0]
		var b: Vector2 = run[1]
		var mid := (a + b) * 0.5
		var along_x := absf(b.x - a.x) > absf(b.y - a.y)
		var length := a.distance_to(b)
		var size := Vector3(length, 0.3, 0.16) if along_x else Vector3(0.16, 0.3, length)
		CalderaShell._metal(upper, Vector3(mid.x, top + 0.15, mid.y), size, CalderaShell.BASALT, true)
		var pane := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(length, 0.75, 0.03) if along_x else Vector3(0.03, 0.75, length)
		pane.mesh = box
		pane.material_override = glass
		pane.position = Vector3(mid.x, top + 0.3 + 0.375, mid.y)
		upper.add_child(pane)
		CollisionPolicy.add_box(upper, pane, box.size, pane.position, Basis(), false)
		CalderaShell._metal(upper, Vector3(mid.x, top + 1.07, mid.y), size * Vector3(1, 0, 1) + Vector3(0.0, 0.04, 0.0), CalderaShell.STEEL_BLUED, false)
	# Pale cast pavers over the roof: the terrace's floor.
	var paving := MeshInstance3D.new()
	paving.name = "TerracePaving"
	var slab := BoxMesh.new()
	slab.size = Vector3(SHELL_SIZE.x - 0.3, 0.02, SHELL_SIZE.y + 0.4)
	paving.mesh = slab
	paving.material_override = SolidModel.material(Color(0.58, 0.55, 0.52), 0.85, 0.0)
	paving.position = Vector3(SHELL_CENTRE.x, top + 0.01, 0.0)
	upper.add_child(paving)
	CollisionPolicy.mark_decorative(paving)
	# Seats round two low tables toward the reservoir, a flame in glass at
	# each end of the group for the evenings.
	for x: float in [-4.0, 0.5]:
		CalderaFurniture.low_table(upper, Vector3(x, top, 4.3), 0.0)
		for offset: Vector2 in [Vector2(-1.1, 0.0), Vector2(1.1, 0.0), Vector2(0.0, -1.0)]:
			CalderaFurniture.piece(upper, Vector3(0.4, 0.22, 0.32), CalderaShell.BASALT.lightened(0.1), Vector3(x + offset.x, top + 0.22, 4.3 + offset.y), 0.0 if offset.y == 0.0 else PI * 0.5, true, SuperEgg.EPSILON_SOFT)
	for x: float in [-6.4, 2.9]:
		CalderaFurniture.flame_capsule(upper, Vector3(x, top, 5.3))


## The lift: three stations, the east bay's floor (the ground), the home's
## door landing and the roof terrace, on four steel masts at the bay's north
## end, the platform with dichroic cheeks on its open sides; a call post at
## each station.
static func _lift(body: StaticBody3D) -> void:
	var top := UPPER + roof_top()
	var glass := ShaderMaterial.new()
	glass.shader = _dichroic_shader()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var p := LIFT_AT + Vector2(corner.x * (LIFT_SIZE.x * 0.5 + 0.06), corner.y * (LIFT_SIZE.y * 0.5 + 0.06))
		CalderaShell._metal(body, Vector3(p.x, (top + 1.2) * 0.5, p.y), Vector3(0.1, top + 1.2, 0.1), CalderaShell.STEEL_BLUED, true)
	CalderaShell._metal(body, Vector3(LIFT_AT.x, top + 1.2, LIFT_AT.y), Vector3(LIFT_SIZE.x + 0.3, 0.1, LIFT_SIZE.y + 0.3), CalderaShell.STEEL_BLUED, false)
	var heights: Array[float] = [0.0, UPPER, top]
	var names: Array[String] = ["Ground", "Home", "Roof terrace"]
	var lift := CalderaLift.build(body, LIFT_AT, LIFT_SIZE, heights, names, 1, ["east", "north"], glass)
	# A fixed plate bridging from the roof's edge to the lift at the top stop.
	var edge := SHELL_CENTRE.x + SHELL_SIZE.x * 0.5
	var lift_west := LIFT_AT.x - LIFT_SIZE.x * 0.5
	var plate := CalderaShell._metal(body, Vector3((edge - 0.1 + lift_west - 0.02) * 0.5, top - 0.04, LIFT_AT.y), Vector3(lift_west - 0.02 - edge + 0.1, 0.08, LIFT_SIZE.y), CalderaShell.STEEL_BLUED, false)
	var holder := MeshInstance3D.new()
	body.add_child(holder)
	CollisionPolicy.add_box(body, holder, Vector3(lift_west - 0.02 - edge + 0.1, 0.08, LIFT_SIZE.y), plate.position, Basis(), true)
	# Call posts: at the ground beside the well, on the home's landing, on
	# the terrace by the plate.
	var south := LIFT_AT.y - LIFT_SIZE.y * 0.5 - 0.25
	CalderaLift.add_call(body, lift, 0, Vector3(LIFT_AT.x + 0.5, 0.0, south))
	CalderaLift.add_call(body, lift, 1, Vector3(LIFT_AT.x + 0.5, UPPER, south))
	CalderaLift.add_call(body, lift, 2, Vector3(edge - 0.45, top, south + 0.05))
	for station: float in heights:
		ClearZones.add(body, "lift landing", "door", Vector2(LIFT_AT.x, LIFT_AT.y - LIFT_SIZE.y * 0.5), Vector2(0, -1), 0.0, 1.0, LIFT_SIZE.x * 0.5 - 0.3, station + 0.05, station + 1.9)


static func _dichroic_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

uniform vec3 face_on : source_color = vec3(0.20, 0.66, 0.66);
uniform vec3 oblique : source_color = vec3(0.52, 0.30, 0.74);
uniform vec3 grazing : source_color = vec3(0.92, 0.70, 0.30);

void fragment() {
	// Dichroic glass: its colour turns with the angle between the view and the
	// pane, teal face on, violet oblique, gold at a grazing angle.
	float facing = abs(dot(NORMAL, VIEW));
	float turn = 1.0 - facing;
	vec3 colour = mix(face_on, oblique, smoothstep(0.15, 0.6, turn));
	colour = mix(colour, grazing, smoothstep(0.7, 0.95, turn));
	ALBEDO = colour;
	ALPHA = 0.45 + 0.35 * turn;
	ROUGHNESS = 0.05;
	METALLIC = 0.4;
	EMISSION = colour * 0.12;
}
"""
	return shader


# ---------------------------------------------------------------------------
# Floors: the workshop's raised floor, the corridor and its ramp, the floor
# between the storeys.
# ---------------------------------------------------------------------------

static func _floors(body: StaticBody3D) -> void:
	var x0 := SHELL_CENTRE.x - SHELL_SIZE.x * 0.5 + CalderaShell.WALL * 0.5
	var x1 := SHELL_CENTRE.x + SHELL_SIZE.x * 0.5 - CalderaShell.WALL * 0.5
	var z0 := -SHELL_SIZE.y * 0.5 + CalderaShell.WALL * 0.5
	# The workshop's raised floor, a cast block on the plinth.
	_block(body, "WorkshopFloor", Vector3((x0 + x1) * 0.5, RAISE * 0.5, (z0 + WALL_Z_BACK) * 0.5), Vector3(x1 - x0, RAISE, WALL_Z_BACK - z0), FLOOR)
	# The corridor: level with the workshop, then the ramp to the assay landing.
	_block(body, "CorridorFloor", Vector3((x0 + RAMP_TOP_X) * 0.5, RAISE * 0.5, (WALL_Z_BACK + WALL_Z_FRONT) * 0.5), Vector3(RAMP_TOP_X - x0, RAISE, WALL_Z_FRONT - WALL_Z_BACK), FLOOR)
	_wedge(body, "CorridorRamp", Vector2(RAMP_TOP_X, WALL_Z_BACK), Vector2(RAMP_FOOT_X, WALL_Z_FRONT), RAISE, 0.0, true, FLOOR)
	# The floor between the storeys.
	_block(body, "UpperSlab", Vector3((x0 + x1) * 0.5, CalderaShell.STOREY + SLAB * 0.5, 0.0), Vector3(x1 - x0 + CalderaShell.WALL, SLAB, SHELL_SIZE.y + CalderaShell.WALL), FLOOR.lightened(0.05))


## Partitions below: the corridor's two walls with their doors at the floor
## each side meets, the gem store between the counter and the assay room with
## its lobby, and the workshop's three rooms.
static func _ground_partitions(body: StaticBody3D) -> void:
	var x0 := SHELL_CENTRE.x - SHELL_SIZE.x * 0.5
	var x1 := SHELL_CENTRE.x + SHELL_SIZE.x * 0.5
	# The corridor's front wall, from the shop's floor: one door, at the
	# assay room, where the ramp has come down.
	_wall_with_doors(body, Vector2(x0, WALL_Z_FRONT), Vector2(x1, WALL_Z_FRONT), 0.0, [[ASSAY_DOOR_X, "assay door"]])
	# The corridor's back wall, from the workshop's raised floor: receiving,
	# the stock store, the studio.
	_wall_with_doors(body, Vector2(x0, WALL_Z_BACK), Vector2(x1, WALL_Z_BACK), RAISE, [[RECEIVING_INNER_DOOR_X, "receiving inner door"], [STORE_DOOR_X, "stock store door"], [STUDIO_DOOR_X, "studio door"]])
	# Between the workshop's rooms.
	for x: float in [-3.5, -0.5]:
		_wall_with_doors(body, Vector2(x, -SHELL_SIZE.y * 0.5), Vector2(x, WALL_Z_BACK), RAISE, [])
	# The gem store: walls on three sides, its forged door onto the lobby
	# (z 1..2) that joins the counter and the assay room.
	for x: float in [-1.5, 1.5]:
		_wall_with_doors(body, Vector2(x, 2.0), Vector2(x, SHELL_SIZE.y * 0.5), 0.0, [])
	_wall_with_doors(body, Vector2(-1.5, 2.0), Vector2(1.5, 2.0), 0.0, [[GEM_DOOR_X, "gem store door"]])


## Partitions above: the shared front room (receiving and shaping, its glass
## to the reservoir), and behind it Pela's room, Savi's room and the pantry.
static func _upper_partitions(upper: StaticBody3D) -> void:
	var x0 := SHELL_CENTRE.x - SHELL_SIZE.x * 0.5
	var x1 := SHELL_CENTRE.x + SHELL_SIZE.x * 0.5
	_wall_with_doors(upper, Vector2(x0, 0.0), Vector2(x1, 0.0), 0.0, [[-6.0, "Pela's door"], [-1.0, "Savi's door"], [4.0, "pantry door"]])
	for x: float in [-3.5, 1.5]:
		_wall_with_doors(upper, Vector2(x, -SHELL_SIZE.y * 0.5), Vector2(x, 0.0), 0.0, [])


## A stone partition from `from` to `to` on a floor at `base`, to the ring
## beam, with superellipse doors at the given positions along it ([x or z,
## label]); a door's clear zones on both sides.
static func _wall_with_doors(body: StaticBody3D, from: Vector2, to: Vector2, base: float, doors: Array) -> void:
	var along_x := absf(to.x - from.x) > absf(to.y - from.y)
	var start := from.x if along_x else from.y
	var finish := to.x if along_x else to.y
	var fixed := from.y if along_x else from.x
	var height := CalderaShell.STOREY - base
	var cursor := start
	for door: Array in doors:
		var at: float = door[0]
		var low := at - INNER_DOOR_WIDTH * 0.5 - 0.3
		var high := at + INNER_DOOR_WIDTH * 0.5 + 0.3
		if low - cursor > 0.05:
			_partition(body, cursor, low, fixed, along_x, base, height)
		var mid := (low + high) * 0.5
		var origin := Vector3(mid, base, fixed) if along_x else Vector3(fixed, base, mid)
		CalderaShell.door_opening(body, origin, 0.0 if along_x else PI * 0.5, high - low, height, 0.18, INNER_DOOR_WIDTH, INNER_DOOR_HEIGHT, 1, PARTITION)
		var point := Vector2(at, fixed) if along_x else Vector2(fixed, at)
		var normal := Vector2(0, 1) if along_x else Vector2(1, 0)
		for direction: Vector2 in [normal, -normal]:
			ClearZones.add(body, str(door[1]), "door", point, direction, 0.0, 1.0, INNER_DOOR_WIDTH * 0.5, base + 0.05, base + 1.9)
		cursor = high
	if finish - cursor > 0.05:
		_partition(body, cursor, finish, fixed, along_x, base, height)


static func _partition(body: StaticBody3D, s0: float, s1: float, fixed: float, along_x: bool, base: float, height: float) -> void:
	var size := Vector3(s1 - s0, height, 0.18) if along_x else Vector3(0.18, height, s1 - s0)
	var at := Vector3((s0 + s1) * 0.5, base + height * 0.5, fixed) if along_x else Vector3(fixed, base + height * 0.5, (s0 + s1) * 0.5)
	_block(body, "Partition", at, size, PARTITION)


# ---------------------------------------------------------------------------
# The east bay: the home's open-air ramp, and the receiving door's bridge.
# ---------------------------------------------------------------------------

## From a landing at the service loop's level at the back of the bay, a cast
## ramp climbs north to a landing on blued-steel posts at the home's door,
## with a steel rail on its open side.
static func _east_bay(body: StaticBody3D) -> void:
	var entry := FireCalderaPlan.plot("OREN")
	var levels: Array = entry["levels"]
	var landing: Rect2 = levels[4]["rect"]
	var ramp: Rect2 = levels[5]["rect"]
	var head: Rect2 = levels[6]["rect"]
	_block(body, "RampFootLanding", Vector3(landing.get_center().x, RAISE * 0.5, landing.get_center().y), Vector3(landing.size.x, RAISE, landing.size.y), FLOOR)
	_wedge(body, "HomeRamp", ramp.position, ramp.end, RAISE, UPPER, false, FLOOR)
	_block(body, "RampHeadLanding", Vector3(head.get_center().x, UPPER - SLAB * 0.5, head.get_center().y), Vector3(head.size.x, SLAB, head.size.y), FLOOR)
	for z: float in [head.position.y + 0.2, head.end.y - 0.2]:
		CalderaShell._metal(body, Vector3(head.end.x - 0.15, (UPPER - SLAB) * 0.5, z), Vector3(0.14, UPPER - SLAB, 0.14), CalderaShell.STEEL_BLUED, true)
	# The rail along the open side, following the ramp and the landing.
	var rail_x := ramp.end.x - 0.06
	CalderaShell._beam(body, Vector3(rail_x, RAISE + 1.0, ramp.position.y), Vector3(rail_x, UPPER + 1.0, ramp.end.y), Vector2(0.05, 0.05), CalderaShell.STAINLESS)
	CalderaShell._beam(body, Vector3(rail_x, UPPER + 1.0, head.position.y), Vector3(rail_x, UPPER + 1.0, head.end.y), Vector2(0.05, 0.05), CalderaShell.STAINLESS)
	for i in 5:
		var z := lerpf(ramp.position.y, ramp.end.y, float(i) / 4.0)
		var y := lerpf(RAISE, UPPER, float(i) / 4.0)
		CalderaShell._metal(body, Vector3(rail_x, y + 0.5, z), Vector3(0.04, 1.0, 0.04), CalderaShell.STEEL_BLUED, false)
	CalderaShell._metal(body, Vector3(rail_x, UPPER + 0.5, head.end.y - 0.1), Vector3(0.04, 1.0, 0.04), CalderaShell.STEEL_BLUED, false)
	var holder := MeshInstance3D.new()
	body.add_child(holder)
	CollisionPolicy.add_box(body, holder, Vector3(0.08, 1.1, ramp.size.y + head.size.y), Vector3(rail_x, (RAISE + UPPER) * 0.5 + 0.55, (ramp.position.y + head.end.y) * 0.5), Basis(), false)


## The receiving door's threshold: a cast landing at the service loop's level
## across the plinth's reveal to the retaining wall's head.
static func _receiving_bridge(body: StaticBody3D) -> void:
	var levels: Array = FireCalderaPlan.plot("OREN")["levels"]
	var bridge: Rect2 = levels[3]["rect"]
	_block(body, "ReceivingThreshold", Vector3(bridge.get_center().x, RAISE * 0.5, bridge.get_center().y), Vector3(bridge.size.x, RAISE, bridge.size.y), FLOOR)


# ---------------------------------------------------------------------------
# Solids.
# ---------------------------------------------------------------------------

static func _block(body: StaticBody3D, name_text: String, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = name_text
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = SolidModel.material(colour, 0.85, 0.0)
	mesh.position = at
	body.add_child(mesh)
	CollisionPolicy.add_box(body, mesh, size, at, Basis(), true)
	return mesh


## A cast ramp over the plan rectangle `a`..`b`, its top rising from `low_y`
## at the start of its axis to `high_y` at the end (axis x when `along_x`),
## solid to the floor beneath, one convex collider.
static func _wedge(body: StaticBody3D, name_text: String, a: Vector2, b: Vector2, start_y: float, end_y: float, along_x: bool, colour: Color) -> void:
	var top := func(p: Vector2) -> float:
		var t := (p.x - a.x) / (b.x - a.x) if along_x else (p.y - a.y) / (b.y - a.y)
		return lerpf(start_y, end_y, t)
	var corners := [Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(b.x, b.y), Vector2(a.x, b.y)]
	var points := PackedVector3Array()
	for c: Vector2 in corners:
		points.append(Vector3(c.x, 0.0, c.y))
		points.append(Vector3(c.x, float(top.call(c)), c.y))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [[1, 3, 5, 7], [0, 2, 4, 6], [0, 2, 3, 1], [2, 4, 5, 3], [4, 6, 7, 5], [6, 0, 1, 7]]
	var centre := Vector3((a.x + b.x) * 0.5, maxf(start_y, end_y) * 0.4, (a.y + b.y) * 0.5)
	for f: Array in faces:
		var q := [points[f[0]], points[f[1]], points[f[2]], points[f[3]]]
		var n: Vector3 = (q[1] - q[0]).cross(q[3] - q[0]).normalized()
		if n.dot((q[0] + q[2]) * 0.5 - centre) < 0.0:
			n = -n
		for tri: Array in [[0, 1, 2], [0, 2, 3]]:
			var v0: Vector3 = q[tri[0]]
			var v1: Vector3 = q[tri[1]]
			var v2: Vector3 = q[tri[2]]
			if (v1 - v0).cross(v2 - v0).dot(n) > 0.0:
				var swap := v1
				v1 = v2
				v2 = swap
			for v in [v0, v1, v2]:
				st.set_normal(n)
				st.add_vertex(v)
	var mesh := MeshInstance3D.new()
	mesh.name = name_text
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(colour, 0.85, 0.0)
	body.add_child(mesh)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collider)
