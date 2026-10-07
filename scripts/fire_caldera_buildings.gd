class_name FireCalderaBuildings
extends RefCounted

## The Fire caldera's buildings from their approved briefs
## (fire_caldera_buildings.md), each a CalderaShell on its SocketPlinth with
## its rooms inside. Shell frame: local +Z toward the plot's front (the
## reservoir), +X across; the floor at y 0 (the plinth's datum).

const BASALT_PARTITION := Color(0.24, 0.22, 0.21)
const COOL_STONE := Color(0.46, 0.46, 0.48)


# ---------------------------------------------------------------------------
# Guest house (brief section 3): a 15.5 x 12 m glass pavilion. The receiving
# hall fills the front (z 0.25..6). Behind it four rooms fitted to their use,
# across 3 + 5 + 3.5 + 4 = 15.5 m: the keeper's room, the rim room, the
# washroom, the lake room. See the brief for the occupant, the program and
# the colour rule: amber is welcome and warmth, cobalt is cooling and water;
# every band takes the colour of the room behind it, so the west half reads
# warm and the east half cool, and the hall, which faces both, carries amber
# from its door and cobalt toward the lake end, interleaved in its middle.
# Nothing is wood or ordinary cloth (CalderaFurniture).
# ---------------------------------------------------------------------------

const GUEST_SIZE := Vector2(15.5, 12.0)
const GUEST_FRONT_DOOR := -5.75
const COBALT := Color(0.16, 0.30, 0.72)
const AMBER := Color(0.92, 0.60, 0.16)
const GUEST_STAINED: Array[Color] = [COBALT, AMBER]
const C := 0
const A := 1
const REAR_Z := 0.25
const PARTITION_SOLID := 3.0
const INNER_DOOR_WIDTH := 1.2
const INNER_DOOR_HEIGHT := 2.4
const WARM_GLASS := Color(0.62, 0.52, 0.40, 0.30)
const COOL_GLASS := Color(0.30, 0.42, 0.66, 0.32)
const AMBER_CLOTH := Color(0.74, 0.48, 0.18)
const COBALT_CLOTH := Color(0.20, 0.30, 0.58)
## The rooms behind the hall: [x from, x to, door x, band colour].
const ROOMS := {
	"keeper": [-7.75, -4.75, -6.25, A],
	"rim": [-4.75, 0.25, -3.4, A],
	"washroom": [0.25, 3.75, 2.0, C],
	"lake": [3.75, 7.75, 5.0, C],
}


static func guest_spec() -> Dictionary:
	var clear := CalderaShell.CLEAR_GLASS
	var smoky := CalderaShell.SMOKY_GLASS
	return {
		"size": GUEST_SIZE,
		"door_at": GUEST_FRONT_DOOR,
		"stained": GUEST_STAINED,
		"walls": {
			# West to east: amber from the stone pier and the door, interleaved
			# over the dining table, cobalt toward the lake end.
			"front": [
				{"to": 0.70, "kind": "stone", "band": A}, {"to": 3.30, "kind": "door", "band": A},
				{"to": 5.33, "kind": "glass", "tint": clear, "band": A}, {"to": 7.37, "kind": "glass", "tint": clear, "band": C},
				{"to": 9.40, "kind": "glass", "tint": clear, "band": A}, {"to": 11.43, "kind": "glass", "tint": clear, "band": C},
				{"to": 13.47, "kind": "glass", "tint": clear, "band": C}, {"to": 15.50, "kind": "glass", "tint": clear, "band": C},
			],
			"back": [
				{"to": 3.0, "kind": "stone", "band": A},
				{"to": 5.5, "kind": "glass", "tint": WARM_GLASS, "band": A}, {"to": 8.0, "kind": "glass", "tint": WARM_GLASS, "band": A},
				{"to": 11.5, "kind": "stone", "band": C},
				{"to": 13.5, "kind": "glass", "tint": COOL_GLASS, "band": C}, {"to": 15.5, "kind": "glass", "tint": COOL_GLASS, "band": C},
			],
			"west": [
				{"to": 2.6, "kind": "stone", "band": A}, {"to": 3.5, "kind": "glass", "tint": smoky, "band": A},
				{"to": 6.25, "kind": "stone", "band": A},
				{"to": 9.125, "kind": "glass", "tint": clear, "band": A}, {"to": 12.0, "kind": "glass", "tint": clear, "band": A},
			],
			"east": [
				{"to": 3.125, "kind": "glass", "tint": COOL_GLASS, "band": C}, {"to": 6.25, "kind": "glass", "tint": COOL_GLASS, "band": C},
				{"to": 9.125, "kind": "glass", "tint": clear, "band": C}, {"to": 12.0, "kind": "glass", "tint": clear, "band": C},
			],
		},
		# Each dome takes the full reach of its room's roof, less a margin.
		"skylights": [
			{"name": "Hall", "at": Vector2(0.0, 3.125), "half": Vector2(7.0, 2.4), "rise": 1.25, "tint": clear},
			{"name": "KeeperRoom", "at": Vector2(-6.25, -2.875), "half": Vector2(1.05, 2.6), "rise": 0.6, "tint": Color(0.95, 0.70, 0.36, 0.36)},
			{"name": "RimRoom", "at": Vector2(-2.25, -2.875), "half": Vector2(2.05, 2.7), "rise": 0.95, "tint": Color(0.95, 0.66, 0.30, 0.34)},
			{"name": "Washroom", "at": Vector2(2.0, -2.875), "half": Vector2(1.3, 2.6), "rise": 0.65, "tint": Color(0.78, 0.84, 0.94, 0.55)},
			{"name": "LakeRoom", "at": Vector2(5.75, -2.875), "half": Vector2(1.55, 2.7), "rise": 0.85, "tint": Color(0.30, 0.45, 0.88, 0.36)},
		],
	}


static func guest_house(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), guest_spec())
	_guest_terrace(body)
	_guest_entry_fin(body)
	_guest_partitions(body)
	_guest_hall(body)
	_guest_keeper_room(body)
	_guest_rim_room(body)
	_guest_washroom(body)
	_guest_lake_room(body)
	return body


## Stone partitions to 3.0 m, each doorway a punched superellipse with its
## frame and leaf, a stained band to the roof in each room's colour.
static func _guest_partitions(body: StaticBody3D) -> void:
	# Along the hall: one door into each room.
	for key: String in ROOMS:
		var room: Array = ROOMS[key]
		var x0: float = room[0]
		var x1: float = room[1]
		var door: float = room[2]
		var west := door - INNER_DOOR_WIDTH * 0.5 - 0.35
		var east := door + INNER_DOOR_WIDTH * 0.5 + 0.35
		CalderaShell.door_opening(body, Vector3((west + east) * 0.5, 0.0, REAR_Z), 0.0, east - west, PARTITION_SOLID, 0.18, INNER_DOOR_WIDTH, INNER_DOOR_HEIGHT, 1, BASALT_PARTITION)
		for span: Vector2 in [Vector2(x0, west), Vector2(east, x1)]:
			if span.y - span.x > 0.05:
				_slab(body, (span.x + span.y) * 0.5, span.y - span.x, REAR_Z, true, 0.0, PARTITION_SOLID, BASALT_PARTITION)
		_band(body, x0, x1, REAR_Z, true, GUEST_STAINED[int(room[3])])
		for direction: Vector2 in [Vector2(0, 1), Vector2(0, -1)]:
			ClearZones.add(body, "%s door" % key, "door", Vector2(door, REAR_Z), direction, 0.0, 1.0, INNER_DOOR_WIDTH * 0.5, 0.05, 1.9)
	# Between the rooms: a divider takes its warm side's colour, so the rim
	# room is amber on every side; only the wall between the two cool rooms is
	# cobalt.
	for wall: Array in [[-4.75, A], [0.25, A], [3.75, C]]:
		var x: float = wall[0]
		_slab(body, -2.875, 6.25, x, false, 0.0, PARTITION_SOLID, BASALT_PARTITION)
		_band(body, -6.0, REAR_Z, x, false, GUEST_STAINED[int(wall[1])])


static func _band(body: StaticBody3D, s0: float, s1: float, fixed: float, along_x: bool, colour: Color) -> void:
	var height := CalderaShell.STOREY - PARTITION_SOLID
	var size := Vector3(s1 - s0 - 0.06, height - 0.06, 0.05) if along_x else Vector3(0.05, height - 0.06, s1 - s0 - 0.06)
	var at := Vector3((s0 + s1) * 0.5, PARTITION_SOLID + height * 0.5, fixed) if along_x else Vector3(fixed, PARTITION_SOLID + height * 0.5, (s0 + s1) * 0.5)
	var pane := MeshInstance3D.new()
	pane.name = "PartitionBand"
	var box := BoxMesh.new()
	box.size = size
	pane.mesh = box
	var material := SolidModel.material(Color(colour, 0.6), 0.06, 0.05)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.material_override = material
	pane.position = at
	body.add_child(pane)
	CollisionPolicy.add_box(body, pane, size, at, Basis(), false)
	var bar_size := Vector3(s1 - s0, 0.08, 0.2) if along_x else Vector3(0.2, 0.08, s1 - s0)
	CalderaShell._metal(body, Vector3(at.x, PARTITION_SOLID, at.z), bar_size, CalderaShell.STEEL_BLUED, false)


static func _slab(body: StaticBody3D, along: float, length: float, fixed: float, along_x: bool, y0: float, y1: float, colour: Color) -> void:
	var size := Vector3(length, y1 - y0, 0.18) if along_x else Vector3(0.18, y1 - y0, length)
	var at := Vector3(along, (y0 + y1) * 0.5, fixed) if along_x else Vector3(fixed, (y0 + y1) * 0.5, along)
	var mesh := MeshInstance3D.new()
	mesh.name = "PartitionStone"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = SolidModel.material(colour, 0.9, 0.0)
	mesh.position = at
	body.add_child(mesh)
	CollisionPolicy.add_box(body, mesh, size, at, Basis(), false)


## The receiving hall, laid out for hospitality from the door inward:
##   arrival: a stone bench and a pack rack by the door to set down loads;
##   welcome: Eris's counter facing the door, a glass carafe of the guests'
##     imported water and two cups on it (the most precious thing she can
##     offer a cool body), her ledger plates at her side;
##   provision: a long stone sideboard of imported food, under the hall's
##     great work: a backlit fused-glass panel from the Vara studio, the
##     caldera's strata in section with the reservoir as a cobalt inlay;
##   studies: three small panels by the same hands on the free wall lengths,
##     warm by the door, mixed by the table, cool by the rest corner;
##   table: a stone table and six chairs at the reservoir glass;
##   rest: two armchairs and a low table on a basalt-fibre mat at the cool end;
##   light: the shell's cove lines, lines under the counter and sideboard,
##     and three concealed lights, one per group; no visible fittings.
static func _guest_hall(body: StaticBody3D) -> void:
	# Arrival.
	CalderaFurniture.bench(body, Vector3(-7.25, 0.0, 2.45), -PI * 0.5, 1.9)
	CalderaFurniture.piece(body, Vector3(0.3, 0.35, 0.45), CalderaShell.STEEL_BLUED, Vector3(-7.3, 0.35, 4.25), 0.0, true)
	CalderaFurniture.piece(body, Vector3(0.22, 0.18, 0.3), CalderaFurniture.FIBRE, Vector3(-7.3, 0.88, 4.15), 0.2, false, SuperEgg.EPSILON_SOFT)
	# Welcome.
	CalderaFurniture.counter(body, Vector3(-5.65, 0.0, 2.35), PI, 1.8)
	CalderaFurniture.jar(body, Vector3(-5.2, 1.03, 2.35), Color(0.30, 0.58, 0.88, 0.6), 0.08)
	for i in 2:
		CalderaFurniture.jar(body, Vector3(-4.95 + 0.14 * float(i), 1.03, 2.45), Color(0.80, 0.90, 0.95, 0.2), 0.04)
	for i in 3:
		CalderaFurniture.piece(body, Vector3(0.12, 0.006, 0.16), CalderaShell.STAINLESS.darkened(0.08 * float(i)), Vector3(-6.2, 1.04 + 0.012 * float(i), 2.3 + 0.04 * float(i)))
	_marker(body, "StandMarker", Vector3(-5.65, 0.0, 3.45), 0.0)
	_marker(body, "KeeperStand", Vector3(-5.65, 0.0, 1.35), 0.0)
	CalderaFurniture.concealed_light(body, Vector3(-5.2, 2.9, 2.6), CalderaFurniture.LED_WARM, 0.8, 6.0)
	# Provision, under the caldera relief.
	CalderaFurniture.sideboard(body, Vector3(-0.7, 0.0, REAR_Z + 0.36), PI, 3.6)
	for i in 5:
		var tones: Array[Color] = [Color(0.72, 0.55, 0.30), Color(0.62, 0.32, 0.30), Color(0.80, 0.70, 0.42)]
		CalderaFurniture.piece(body, Vector3(0.16, 0.05, 0.16), CalderaFurniture.BASALT.lightened(0.15), Vector3(-2.1 + 0.68 * float(i), 0.95, REAR_Z + 0.36), 0.0, false, 2.4)
		CalderaFurniture.piece(body, Vector3(0.1, 0.06, 0.1), tones[i % 3], Vector3(-2.1 + 0.68 * float(i), 1.03, REAR_Z + 0.36), 0.0, false, 2.0)
	_hall_glass_panel(body, Vector3(-0.7, 1.95, REAR_Z + 0.12))
	_hall_studies(body)
	# Table at the glass.
	CalderaFurniture.table(body, Vector3(2.0, 0.0, 3.6), 0.0, 3.0, 1.0)
	for i in 3:
		var x := 1.0 + float(i)
		CalderaFurniture.chair(body, Vector3(x, 0.0, 2.65), PI, AMBER_CLOTH)
		CalderaFurniture.chair(body, Vector3(x, 0.0, 4.55), 0.0, COBALT_CLOTH)
	CalderaFurniture.concealed_light(body, Vector3(1.0, 2.9, 2.4), CalderaFurniture.LED_WARM, 0.7, 6.0)
	_marker(body, "GatherMarker", Vector3(2.0, 0.0, 1.55), 0.0)
	# Rest at the cool end.
	CalderaFurniture.mat(body, Vector3(6.1, 0.0, 3.3), 0.0, Vector2(2.6, 2.2), CalderaFurniture.FIBRE_GREY)
	CalderaFurniture.chair(body, Vector3(5.1, 0.0, 3.3), -PI * 0.5, COBALT_CLOTH, true)
	CalderaFurniture.chair(body, Vector3(7.1, 0.0, 3.3), PI * 0.5, COBALT_CLOTH, true)
	CalderaFurniture.low_table(body, Vector3(6.1, 0.0, 3.3), 0.0)
	CalderaFurniture.concealed_light(body, Vector3(6.1, 2.9, 2.8), CalderaFurniture.LED_WARM.lerp(CalderaFurniture.LED_COOL, 0.5), 0.6, 5.0)


## The hall's art, commissioned from the Vara studio: Omi's kiln-formed glass,
## hung on Talen's concealed steel pins. A glass craftsman would not draw a map; she would
## let the material show its own making. The panel is the caldera in section:
## fused strata from basalt black through cooling reds to amber and smoke,
## their boundaries flowing the way a slumped sheet does, and set into the
## amber the reservoir as one polished cobalt inlay ringed in stainless. It
## hangs frameless on the stone.
static func _hall_glass_panel(body: StaticBody3D, at: Vector3) -> void:
	_fused_glass(body, at, Vector2(1.2, 0.62), [
		Color(0.10, 0.09, 0.09), Color(0.42, 0.10, 0.06), Color(0.86, 0.32, 0.08),
		Color(0.98, 0.62, 0.20), Color(0.74, 0.66, 0.56),
	], 0.0, Vector3(0.35, 0.24, 0.1))


## Three studies for the great panel, the kind a glass studio makes first and
## a host hangs near the work: the same strata cut small, in the hall's colour
## rule (amber by the door, mixed by the table, cobalt at the cool end).
static func _hall_studies(body: StaticBody3D) -> void:
	var face := REAR_Z + 0.11
	_fused_glass(body, Vector3(-4.85, 1.75, face), Vector2(0.24, 0.36), [
		Color(0.42, 0.10, 0.06), Color(0.86, 0.32, 0.08), Color(0.98, 0.62, 0.20),
	], 1.3, Vector3.ZERO)
	_fused_glass(body, Vector3(3.5, 1.75, face), Vector2(0.3, 0.3), [
		Color(0.10, 0.09, 0.09), Color(0.98, 0.62, 0.20), Color(0.74, 0.66, 0.56),
	], 2.6, Vector3(0.0, 0.0, 0.05))
	_fused_glass(body, Vector3(6.7, 1.75, face), Vector2(0.24, 0.36), [
		Color(0.10, 0.12, 0.20), Color(0.16, 0.30, 0.72), Color(0.55, 0.72, 0.90),
	], 4.1, Vector3.ZERO)


## A fused-glass panel facing +Z: `strata` bottom to top, each a run of
## overlapping slumped lozenges whose edges follow a slow wave, so the layers
## flow into one another; an optional reservoir lens `inlay` (x, y, size).
## Hung frameless, straight on the stone: the glass carries its own glow.
static func _fused_glass(body: StaticBody3D, at: Vector3, half: Vector2, strata: Array, phase: float, inlay: Vector3) -> void:
	# The strata.
	var count := strata.size()
	var segments := maxi(int(half.x / 0.12), 3)
	var span := half.x * 2.0 / float(segments)
	var boundary := func(k: int, x: float) -> float:
		if k <= 0:
			return -half.y
		if k >= count:
			return half.y
		var base := -half.y + 2.0 * half.y * float(k) / float(count)
		return base + half.y * 0.09 * sin(x / half.x * 2.4 + phase + float(k) * 1.9)
	for k in count:
		for j in segments:
			var x := -half.x + span * (float(j) + 0.5)
			var lo: float = boundary.call(k, x)
			var hi: float = boundary.call(k + 1, x)
			var lozenge := Vector3(span * 0.75, (hi - lo) * 0.5 + 0.015, 0.012)
			_art_glass(body, lozenge, strata[k], at + Vector3(x, (lo + hi) * 0.5, 0.004 * float(k)), 5.5)
	if inlay.z > 0.0:
		# The reservoir: a flat cobalt lens pressed into the top of the strata,
		# edged with a thin stainless line, as water lies in the caldera floor.
		var ring := CalderaFurniture.piece(body, Vector3(inlay.z * 2.4 + 0.015, inlay.z * 0.5 + 0.015, 0.012), CalderaShell.STAINLESS, at + Vector3(inlay.x, inlay.y, 0.03), 0.0, false, 2.4)
		ring.material_override = SolidModel.material(CalderaShell.STAINLESS, 0.2, 0.9)
		_art_glass(body, Vector3(inlay.z * 2.4, inlay.z * 0.5, 0.016), Color(0.16, 0.32, 0.80), at + Vector3(inlay.x, inlay.y, 0.04), 2.4)


static func _art_glass(body: StaticBody3D, half: Vector3, colour: Color, at: Vector3, epsilon: float) -> void:
	var part := SuperEgg.build_part(half, colour, epsilon, epsilon)
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.12
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 0.7
	part.material_override = material
	part.position = at
	body.add_child(part)
	CollisionPolicy.mark_decorative(part)


## Eris's working room: the sealed provisions shelves along the back wall, her
## desk at the glass slot with the ledger plates, hooks for travellers' gear;
## her own art is a row of three mineral discs, gifts from the city.
static func _guest_keeper_room(body: StaticBody3D) -> void:
	CalderaFurniture.shelves(body, Vector3(-6.25, 0.0, -5.75), PI, 2.4, 4, func(b: StaticBody3D, p: Vector3, i: int) -> void:
		CalderaFurniture.jar(b, p, [Color(0.72, 0.55, 0.30), Color(0.30, 0.55, 0.85, 0.6), Color(0.62, 0.32, 0.30)][i % 3], 0.06))
	CalderaFurniture.chest(body, Vector3(-5.25, 0.0, -4.0), PI * 0.5)
	CalderaFurniture.table(body, Vector3(-7.25, 0.0, -2.9), PI * 0.5, 1.4, 0.7)
	for i in 3:
		CalderaFurniture.piece(body, Vector3(0.12, 0.006, 0.16), CalderaShell.STAINLESS.darkened(0.08 * float(i)), Vector3(-7.25, 0.8 + 0.012 * float(i), -3.1 + 0.05 * float(i)))
	CalderaFurniture.hooks(body, Vector3(-4.9, 0.0, -1.6), PI * 0.5, 1.2)
	for i in 3:
		var disc := CalderaFurniture.piece(body, Vector3(0.16, 0.16, 0.02), [Color(0.55, 0.30, 0.60), Color(0.30, 0.62, 0.55), Color(0.80, 0.55, 0.20)][i], Vector3(-7.55, 1.75, -5.2 + 0.45 * float(i)), PI * 0.5, false, 2.0)
		disc.material_override = SolidModel.material(disc.get_surface_override_material(0).albedo_color, 0.2, 0.3)
	CalderaFurniture.concealed_light(body, Vector3(-6.25, 2.9, -3.0), CalderaFurniture.LED_WARM, 0.5, 4.5)


## The rim room, for two of the party: both beds head to the west wall side by
## side, feet toward the room's middle, the full rear glass and the crater rim
## to the side; a chest at each bed's foot, its back to the bed; an amber mat
## between; on the east wall, the room's art, a forged steel skyline of the
## rim set with amber glass; the bed heads washed by their own hidden lines.
static func _guest_rim_room(body: StaticBody3D) -> void:
	for i in 2:
		var z := -2.0 - 2.55 * float(i)
		CalderaFurniture.bed(body, Vector3(-3.5, 0.0, z), PI * 0.5, AMBER_CLOTH if i == 0 else CalderaFurniture.FIBRE)
		CalderaFurniture.chest(body, Vector3(-1.9, 0.0, z), -PI * 0.5, 0.7)
	_marker(body, "WakeMarker", Vector3(-3.5, 0.60, -2.0), 0.0)
	CalderaFurniture.mat(body, Vector3(-3.1, 0.0, -3.28), PI * 0.5, Vector2(1.6, 2.4), AMBER_CLOTH.darkened(0.2))
	_rim_skyline(body, Vector3(0.14, 1.9, -3.2))
	CalderaFurniture.concealed_light(body, Vector3(-2.6, 2.9, -3.3), CalderaFurniture.LED_WARM, 0.55, 5.0)


## A forged steel silhouette of the crater rim, its peaks filled with amber
## glass.
static func _rim_skyline(body: StaticBody3D, at: Vector3) -> void:
	CalderaFurniture.piece(body, Vector3(0.015, 0.5, 1.5), CalderaFurniture.BASALT, at + Vector3(0.005, 0.05, 0))
	var heights := [0.25, 0.55, 0.35, 0.75, 0.45, 0.3, 0.6, 0.2]
	for i in heights.size():
		var z := at.z - 1.2 + 0.34 * float(i)
		var h: float = heights[i]
		var pane := CalderaFurniture.piece(body, Vector3(0.015, h * 0.5, 0.18), AMBER, at + Vector3(-0.02, h * 0.5 - 0.3, z - at.z), 0.0, false, 7.0)
		var glass := SolidModel.material(Color(AMBER, 0.75), 0.06, 0.05)
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		pane.material_override = glass
		CalderaFurniture.piece(body, Vector3(0.02, 0.02, 0.18), CalderaShell.STEEL_BLUED, at + Vector3(-0.02, h - 0.3, z - at.z))
	CalderaFurniture.piece(body, Vector3(0.025, 0.025, 1.4), CalderaShell.STEEL_BLUED, at + Vector3(-0.02, -0.3, 0))


## The lake room, for one: the bed's head on the west wall and its foot toward
## the east glass and the reservoir's glow; a chest at its foot; an armchair
## in the glass corner facing the water; the room's art, a
## cobalt glass ripple roundel, above the bed's head.
static func _guest_lake_room(body: StaticBody3D) -> void:
	CalderaFurniture.bed(body, Vector3(5.1, 0.0, -3.4), PI * 0.5, COBALT_CLOTH)
	CalderaFurniture.chest(body, Vector3(6.7, 0.0, -3.4), -PI * 0.5, 0.7)
	CalderaFurniture.chair(body, Vector3(7.0, 0.0, -1.4), -PI * 0.5, COBALT_CLOTH, true)
	CalderaFurniture.mat(body, Vector3(6.3, 0.0, -1.5), 0.0, Vector2(1.6, 1.2), COBALT_CLOTH.darkened(0.2))
	CalderaFurniture.concealed_light(body, Vector3(5.8, 2.9, -3.0), CalderaFurniture.LED_COOL, 0.5, 5.0)
	for ring in 3:
		var r := 0.42 - 0.12 * float(ring)
		var disc := CalderaFurniture.piece(body, Vector3(0.012 + 0.004 * float(ring), r, r), COBALT.lightened(0.15 * float(ring)), Vector3(3.86 + 0.01 * float(ring), 1.9, -3.4), 0.0, false, 2.0)
		var glass := SolidModel.material(Color(COBALT.lightened(0.15 * float(ring)), 0.7), 0.06, 0.05)
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		disc.material_override = glass
	CalderaFurniture.piece(body, Vector3(0.02, 0.46, 0.46), CalderaShell.STEEL_BLUED, Vector3(3.85, 1.9, -3.4), 0.0, false, 2.0)


## The washroom, as the lava people would make one for cool bodies. Water is
## an imported curiosity to them and heat is how anything is disposed of:
##   - the sealed water supply is a clear glass cylinder on a steel cradle,
##     displayed like a specimen;
##   - the shower drains into an evaporation channel: a stainless grille over
##     a glowing heat seam where spent water flashes to steam;
##   - the incinerating toilet stands in a basalt plinth with a small amber
##     inspection port onto its heat, and a vent stack to the roof;
##   - a gently warmed radiant stone bench dries a bather instead of towels;
##   - the basin is a carved basalt bowl, the mirror polished obsidian.
static func _guest_washroom(body: StaticBody3D) -> void:
	_washroom_art(body)
	CalderaFurniture.concealed_light(body, Vector3(2.0, 2.9, -3.0), CalderaFurniture.LED_COOL, 0.45, 4.5)
	var toilet := ToiletFixtures.build("incinerating")
	toilet.name = "IncineratingToilet"
	toilet.position = Vector3(3.0, 0.0, -5.15)
	body.add_child(toilet)
	_glow(body, "IncineratorPort", Vector3(0.12, 0.07, 0.01), Vector3(3.0, 0.32, -4.72), Color(1.0, 0.55, 0.15))
	CalderaShell._metal(body, Vector3(3.45, 2.3, -5.8), Vector3(0.14, 3.0, 0.14), CalderaShell.STAINLESS, false)
	# The shower: stainless rose on its post, a glass screen, the channel.
	CalderaShell._metal(body, Vector3(0.55, 1.15, -5.75), Vector3(0.07, 2.3, 0.07), CalderaShell.STAINLESS, false)
	CalderaShell._metal(body, Vector3(0.85, 2.25, -5.6), Vector3(0.32, 0.04, 0.32), CalderaShell.STAINLESS, false)
	CalderaShell._pane(body, "ShowerScreen", Vector3(0.95, 1.05, -4.85), Vector2(0.65, 1.0), 0.0, Color(0.62, 0.72, 0.80, 0.30))
	_glow(body, "EvaporationSeam", Vector3(0.65, 0.008, 0.06), Vector3(0.95, 0.012, -5.55), Color(1.0, 0.42, 0.10))
	for i in 7:
		CalderaShell._metal(body, Vector3(0.4 + 0.18 * float(i), 0.03, -5.55), Vector3(0.03, 0.03, 0.2), CalderaShell.STAINLESS, false)
	# The sealed water vessel on its cradle.
	# A squared glass cylinder between two steel bands, so it reads as a made
	# vessel rather than a bubble.
	var vessel := SuperEgg.build_part(Vector3(0.26, 0.72, 0.26), Color(0.80, 0.90, 0.95, 0.25), 7.0, 7.0)
	vessel.position = Vector3(0.75, 1.05, -2.6)
	var glass := SolidModel.material(Color(0.80, 0.90, 0.95, 0.25), 0.05, 0.05)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	vessel.material_override = glass
	body.add_child(vessel)
	CollisionPolicy.mark_decorative(vessel)
	var water := SuperEgg.build_part(Vector3(0.23, 0.45, 0.23), Color(0.25, 0.55, 0.85, 0.55), 7.0, 7.0)
	water.position = Vector3(0.75, 0.82, -2.6)
	var water_material := SolidModel.material(Color(0.25, 0.55, 0.85, 0.55), 0.05, 0.0)
	water.material_override = water_material
	body.add_child(water)
	CollisionPolicy.mark_decorative(water)
	CalderaShell._metal(body, Vector3(0.75, 0.15, -2.6), Vector3(0.7, 0.3, 0.7), CalderaShell.STEEL_BLUED, true)
	CalderaShell._metal(body, Vector3(0.75, 1.80, -2.6), Vector3(0.6, 0.08, 0.6), CalderaShell.STAINLESS, false)
	CalderaShell._metal(body, Vector3(0.75, 0.36, -2.6), Vector3(0.6, 0.08, 0.6), CalderaShell.STAINLESS, false)
	# Basin: a carved basalt bowl on a stone ledge; an obsidian mirror above.
	_piece(body, Vector3(0.28, 0.42, 0.5), CalderaShell.BASALT, Vector3(3.45, 0.42, -2.3), true)
	var bowl := SuperEgg.build_part(Vector3(0.24, 0.09, 0.3), CalderaShell.BASALT.lightened(0.15), 2.4, 2.4)
	bowl.position = Vector3(3.4, 0.92, -2.3)
	body.add_child(bowl)
	CollisionPolicy.mark_decorative(bowl)
	var mirror := MeshInstance3D.new()
	mirror.name = "ObsidianMirror"
	var plate := BoxMesh.new()
	plate.size = Vector3(0.03, 0.8, 0.6)
	mirror.mesh = plate
	mirror.material_override = SolidModel.material(Color(0.05, 0.05, 0.06), 0.05, 0.4)
	mirror.position = Vector3(3.64, 1.65, -2.3)
	body.add_child(mirror)
	CollisionPolicy.mark_decorative(mirror)
	# Backlit: a line hidden behind the mirror's top edge haloes the wall.
	CalderaFurniture.led_line(body, Vector3(3.67, 2.06, -2.3), PI * 0.5, 0.56, CalderaFurniture.LED_COOL)
	# The radiant drying bench, its heat seam along the front.
	_piece(body, Vector3(0.26, 0.22, 0.7), CalderaShell.BASALT, Vector3(0.6, 0.22, -1.4), true)
	_glow(body, "RadiantSeam", Vector3(0.01, 0.015, 0.62), Vector3(0.87, 0.3, -1.4), Color(1.0, 0.45, 0.12))


## The washroom's art: a panel of mineral crust, the pale banded deposit a
## vent leaves, set in a steel frame on the west wall.
static func _washroom_art(body: StaticBody3D) -> void:
	CalderaFurniture.piece(body, Vector3(0.02, 0.5, 0.35), CalderaShell.STEEL_BLUED, Vector3(0.36, 1.7, -4.2))
	for i in 5:
		CalderaFurniture.piece(body, Vector3(0.025, 0.08, 0.3), Color(0.82, 0.78, 0.66).darkened(0.07 * float(i % 3)), Vector3(0.38, 1.38 + 0.16 * float(i), -4.2), 0.0, false, 3.0)


static func _glow(body: StaticBody3D, name_text: String, half: Vector3, at: Vector3, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = name_text
	var box := BoxMesh.new()
	box.size = half * 2.0
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 2.2
	mesh.material_override = material
	mesh.position = at
	body.add_child(mesh)
	CollisionPolicy.mark_decorative(mesh)


## A shallow threshold terrace fits between the enlarged shell and the public
## edge. Its finish is visual cladding flush with the socket plinth: the plinth
## is deliberately the one and only floor collider.
static func _guest_terrace(body: StaticBody3D) -> void:
	var terrace := MeshInstance3D.new()
	terrace.name = "DryGuestTerrace"
	var slab := BoxMesh.new()
	slab.size = Vector3(15.5, 0.08, 1.8)
	terrace.mesh = slab
	var material := StandardMaterial3D.new()
	material.albedo_color = COOL_STONE.darkened(0.12)
	material.roughness = 0.82
	terrace.material_override = material
	terrace.position = Vector3(0.0, -0.028, 6.9)
	body.add_child(terrace)
	CollisionPolicy.mark_decorative(terrace)


## A cobalt-and-amber threshold fin beside, never in front of, the two-metre
## door. The forged stem forks like the shell mullions and holds two mineral
## glass leaves, making the entrance legible from the forecourt.
static func _guest_entry_fin(body: StaticBody3D) -> void:
	var fin := Node3D.new()
	fin.name = "EntryFin"
	fin.position = Vector3(-4.05, 0.0, 6.85)
	body.add_child(fin)
	var stem := SuperEgg.build_part(Vector3(0.10, 1.62, 0.10), CalderaShell.STEEL_BLUED, 6.5, 6.5)
	stem.position.y = 1.62
	fin.add_child(stem)
	CollisionPolicy.add_box(body, stem, Vector3(0.22, 3.24, 0.22), fin.position + stem.position, Basis(), false)
	_fin_glass(fin, "CobaltFinGlass", Vector3(-0.46, 2.56, 0.0), Vector3(0.39, 0.67, 0.045), Color(GUEST_STAINED[0], 0.72))
	_fin_glass(fin, "AmberFinGlass", Vector3(0.43, 2.13, 0.0), Vector3(0.34, 0.52, 0.045), Color(GUEST_STAINED[1], 0.72))
	_fin_beam(fin, Vector3(-0.04, 2.37, 0.0), Vector3(-0.46, 1.89, 0.0))
	_fin_beam(fin, Vector3(0.04, 2.20, 0.0), Vector3(0.43, 1.61, 0.0))


static func _fin_glass(fin: Node3D, name_text: String, at: Vector3, half: Vector3, colour: Color) -> void:
	var pane := SuperEgg.build_part(half, colour, 6.5, 6.5)
	pane.name = name_text
	pane.position = at
	var material := SolidModel.material(colour, 0.08, 0.08)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.material_override = material
	fin.add_child(pane)
	CollisionPolicy.mark_decorative(pane)


static func _fin_beam(fin: Node3D, start: Vector3, finish: Vector3) -> void:
	var delta := finish - start
	var beam := SuperEgg.build_part(Vector3(delta.length() * 0.5, 0.055, 0.065), CalderaShell.STAINLESS, 6.5, 6.5)
	beam.position = (start + finish) * 0.5
	beam.rotation.z = atan2(delta.y, delta.x)
	fin.add_child(beam)
	CollisionPolicy.mark_decorative(beam)


static func _blanket(i: int) -> Color:
	var tones: Array[Color] = [Color(0.16, 0.30, 0.72), Color(0.92, 0.60, 0.16), Color(0.30, 0.34, 0.40), Color(0.62, 0.30, 0.20)]
	return tones[i % tones.size()]


static func _piece(body: StaticBody3D, half: Vector3, colour: Color, at: Vector3, solid: bool) -> void:
	Furnishings.piece(body, half, colour, at, 0.0, solid)


static func _marker(body: StaticBody3D, name_text: String, at: Vector3, yaw: float) -> void:
	var marker := Marker3D.new()
	marker.name = name_text
	marker.position = at
	marker.rotation.y = yaw
	body.add_child(marker)
