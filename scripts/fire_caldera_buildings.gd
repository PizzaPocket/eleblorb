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
# lounge fills the front (z 0.25..6). Behind it four rooms, each fitted to its
# use, across 3 + 5 + 3.5 + 4 = 15.5 m:
#   keeper's room x -7.75..-4.75: Eris's provisions and ledger; stone, one
#     tall glass slot, no skylight; a working room, not a guest room.
#   rim room      x -4.75..0.25: two beds for the party, full rear glass up to
#     the crater rim, amber band and an amber-tinted dome (warm light).
#   washroom      x 0.25..3.75: the lava people's way with water and heat
#     (see _guest_washroom).
#   lake room     x 3.75..7.75: one bed under east glass toward the
#     reservoir's glow, cobalt band and a cobalt-tinted dome (cool light).
# Partitions are stone to 3.0 m, so every door has a 0.6 m stone lintel, then
# stained glass to the roof.
# ---------------------------------------------------------------------------

const GUEST_SIZE := Vector2(15.5, 12.0)
const GUEST_FRONT_DOOR := -5.75
const COBALT := Color(0.16, 0.30, 0.72)
const AMBER := Color(0.92, 0.60, 0.16)
const GUEST_STAINED: Array[Color] = [COBALT, AMBER]
const REAR_Z := 0.25
const PARTITION_SOLID := 3.0
const INNER_DOOR_WIDTH := 1.2
const INNER_DOOR_HEIGHT := 2.4
const WARM_GLASS := Color(0.62, 0.52, 0.40, 0.30)
const COOL_GLASS := Color(0.30, 0.42, 0.66, 0.32)


static func guest_spec() -> Dictionary:
	var clear := CalderaShell.CLEAR_GLASS
	var smoky := CalderaShell.SMOKY_GLASS
	return {
		"size": GUEST_SIZE,
		"door_at": GUEST_FRONT_DOOR,
		"stained": GUEST_STAINED,
		"walls": {
			# West to east along the front: a stone pier, the door, then six
			# full glass panels onto the forecourt.
			"front": [
				{"to": 0.70, "kind": "stone", "band": 1}, {"to": 3.30, "kind": "door", "band": 0},
				{"to": 5.33, "kind": "glass", "tint": clear, "band": 1}, {"to": 7.37, "kind": "glass", "tint": clear, "band": 0},
				{"to": 9.40, "kind": "glass", "tint": clear, "band": 1}, {"to": 11.43, "kind": "glass", "tint": clear, "band": 0},
				{"to": 13.47, "kind": "glass", "tint": clear, "band": 1}, {"to": 15.50, "kind": "glass", "tint": clear, "band": 0},
			],
			# West to east along the back: keeper's stone, the rim room's glass,
			# the washroom's stone, the lake room's glass.
			"back": [
				{"to": 3.0, "kind": "stone", "band": 0},
				{"to": 5.5, "kind": "glass", "tint": WARM_GLASS, "band": 1}, {"to": 8.0, "kind": "glass", "tint": WARM_GLASS, "band": 1},
				{"to": 11.5, "kind": "stone", "band": 0},
				{"to": 13.5, "kind": "glass", "tint": COOL_GLASS, "band": 0}, {"to": 15.5, "kind": "glass", "tint": COOL_GLASS, "band": 0},
			],
			# Back to front along the west: the keeper's room with one tall glass
			# slot at the desk, then the lounge.
			"west": [
				{"to": 2.6, "kind": "stone", "band": 0}, {"to": 3.5, "kind": "glass", "tint": smoky, "band": 1},
				{"to": 6.25, "kind": "stone", "band": 0},
				{"to": 9.125, "kind": "glass", "tint": clear, "band": 1}, {"to": 12.0, "kind": "glass", "tint": clear, "band": 0},
			],
			# Back to front along the east: the lake room's glass toward the
			# reservoir, then the lounge.
			"east": [
				{"to": 3.125, "kind": "glass", "tint": COOL_GLASS, "band": 0}, {"to": 6.25, "kind": "glass", "tint": COOL_GLASS, "band": 0},
				{"to": 9.125, "kind": "glass", "tint": clear, "band": 1}, {"to": 12.0, "kind": "glass", "tint": clear, "band": 0},
			],
		},
		"skylights": [
			{"name": "Lounge", "at": Vector2(0.7, 2.75), "half": Vector2(2.75, 1.85), "rise": 1.05, "tint": clear},
			{"name": "RimRoom", "at": Vector2(-2.25, -3.0), "half": Vector2(1.75, 1.6), "rise": 0.82, "tint": Color(0.95, 0.66, 0.30, 0.34)},
			{"name": "Washroom", "at": Vector2(2.0, -3.0), "half": Vector2(1.0, 0.95), "rise": 0.55, "tint": Color(0.86, 0.88, 0.90, 0.6)},
			{"name": "LakeRoom", "at": Vector2(5.75, -3.0), "half": Vector2(1.4, 1.6), "rise": 0.75, "tint": Color(0.30, 0.45, 0.88, 0.36)},
		],
	}


static func guest_house(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), guest_spec())
	_guest_terrace(body)
	_guest_entry_fin(body)
	_guest_partitions(body)
	# The lounge: Eris's counter facing the door, a cool stone bench, a table.
	Furnishings.counter(body, Vector3(-5.65, 0.0, 2.35), PI, 1.70, false)
	_piece(body, Vector3(0.34, 0.22, 1.05), COOL_STONE, Vector3(-7.15, 0.22, 2.55), true)
	Furnishings.table(body, Vector3(2.35, 0.0, 3.20), 0.0, 3.0, 1.0, "chairs")
	_marker(body, "StandMarker", Vector3(-5.65, 0.0, 3.45), 0.0)
	_marker(body, "KeeperStand", Vector3(-5.65, 0.0, 1.35), 0.0)
	_marker(body, "GatherMarker", Vector3(2.10, 0.0, 1.65), 0.0)
	_guest_keeper_room(body)
	_guest_rim_room(body)
	_guest_washroom(body)
	_guest_lake_room(body)
	return body


## Stone partitions to 3.0 m with a stained band to the roof: the rear wall
## along the lounge with a door into each room, and the three walls between
## the rooms.
static func _guest_partitions(body: StaticBody3D) -> void:
	_partition(body, Vector2(-7.75, REAR_Z), Vector2(7.75, REAR_Z), [-6.25, -3.4, 2.0, 5.0], [AMBER, COBALT, AMBER, COBALT])
	_partition(body, Vector2(-4.75, -6.0), Vector2(-4.75, REAR_Z), [], [COBALT])
	_partition(body, Vector2(0.25, -6.0), Vector2(0.25, REAR_Z), [], [AMBER])
	_partition(body, Vector2(3.75, -6.0), Vector2(3.75, REAR_Z), [], [COBALT])


static func _partition(body: StaticBody3D, a: Vector2, b: Vector2, doors: Array, bands: Array) -> void:
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	var start := minf(a.x, b.x) if along_x else minf(a.y, b.y)
	var finish := maxf(a.x, b.x) if along_x else maxf(a.y, b.y)
	var fixed := a.y if along_x else a.x
	var pieces: Array[Vector2] = []
	var cursor := start
	for centre: float in doors:
		pieces.append(Vector2(cursor, centre - INNER_DOOR_WIDTH * 0.5))
		cursor = centre + INNER_DOOR_WIDTH * 0.5
	pieces.append(Vector2(cursor, finish))
	for piece: Vector2 in pieces:
		if piece.y - piece.x > 0.05:
			_slab(body, (piece.x + piece.y) * 0.5, piece.y - piece.x, fixed, along_x, 0.0, PARTITION_SOLID, BASALT_PARTITION)
	for i in doors.size():
		var centre: float = doors[i]
		# A 0.6 m stone lintel over every door: the stained glass starts well
		# clear of the frame.
		_slab(body, centre, INNER_DOOR_WIDTH, fixed, along_x, INNER_DOOR_HEIGHT, PARTITION_SOLID, BASALT_PARTITION.darkened(0.08))
		var door: Node3D = load("res://scripts/world_door.gd").new()
		door.position = Vector3(centre, 0.0, fixed) if along_x else Vector3(fixed, 0.0, centre)
		door.rotation.y = 0.0 if along_x else PI * 0.5
		body.add_child(door)
		door.configure(INNER_DOOR_WIDTH * 0.5 - 0.04, INNER_DOOR_HEIGHT, 1, CalderaShell.STEEL_BLUED.lightened(0.2))
		var at2 := Vector2(centre, fixed) if along_x else Vector2(fixed, centre)
		for direction: Vector2 in ([Vector2(0, 1), Vector2(0, -1)] if along_x else [Vector2(1, 0), Vector2(-1, 0)]):
			ClearZones.add(body, "inner door", "door", at2, direction, 0.0, 1.0, INNER_DOOR_WIDTH * 0.5, 0.05, 1.9)
	# The stained band above, one colour per segment between the room walls.
	var band_height := CalderaShell.STOREY - PARTITION_SOLID
	var count := bands.size()
	for i in count:
		var s0 := lerpf(start, finish, float(i) / float(count))
		var s1 := lerpf(start, finish, float(i + 1) / float(count))
		var colour: Color = bands[i]
		var size := Vector3(s1 - s0 - 0.06, band_height - 0.06, 0.05) if along_x else Vector3(0.05, band_height - 0.06, s1 - s0 - 0.06)
		var at := Vector3((s0 + s1) * 0.5, PARTITION_SOLID + band_height * 0.5, fixed) if along_x else Vector3(fixed, PARTITION_SOLID + band_height * 0.5, (s0 + s1) * 0.5)
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
	# A blued-steel bar where stone meets glass, the same seam as the outside.
	var run := finish - start
	var bar_size := Vector3(run, 0.08, 0.2) if along_x else Vector3(0.2, 0.08, run)
	var bar_at := Vector3((start + finish) * 0.5, PARTITION_SOLID, fixed) if along_x else Vector3(fixed, PARTITION_SOLID, (start + finish) * 0.5)
	CalderaShell._metal(body, bar_at, bar_size, CalderaShell.STEEL_BLUED, false)


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


## Eris's working room off her counter: the sealed provisions wall (imported
## food and water for the rare guest), her desk at the glass slot with the
## guest ledger cast in thin metal plates, hooks for travellers' gear.
static func _guest_keeper_room(body: StaticBody3D) -> void:
	Furnishings.shelf(body, Vector3(-6.25, 0.0, -5.6), 0.0, 2.4, 4, "crocks")
	Furnishings.chest(body, Vector3(-5.35, 0.0, -3.9), PI * 0.5, Furnishings.OAK_DARK, 0.8)
	Furnishings.desk(body, Vector3(-7.0, 0.0, -2.05), -PI * 0.5)
	for i in 3:
		_piece(body, Vector3(0.12, 0.006, 0.16), CalderaShell.STAINLESS.darkened(0.1 * float(i)), Vector3(-7.15, 0.83 + 0.012 * float(i), -2.2 + 0.05 * float(i)), false)
	Furnishings.peg_rail(body, Vector3(-4.87, 0.0, -1.6), -PI * 0.5, 1.2, 1.75)


## The rim room: two beds for the party, heads to the lounge wall, feet toward
## the full rear glass and the crater rim beyond; a cool stone ledge under the
## glass; amber light from its dome and band.
static func _guest_rim_room(body: StaticBody3D) -> void:
	for i in 2:
		var bed := TownProps.build_bed(_blanket(i))
		bed.position = Vector3(-3.55 + 2.3 * float(i), 0.0, -2.25)
		bed.rotation.y = PI
		body.add_child(bed)
	_marker(body, "WakeMarker", Vector3(-3.55, 0.60, -2.25), 0.0)
	_piece(body, Vector3(2.0, 0.2, 0.28), COOL_STONE, Vector3(-2.25, 0.2, -5.55), true)
	Furnishings.chest(body, Vector3(-0.35, 0.0, -0.45), 0.0, Furnishings.OAK_DARK, 0.62)


## The lake room: one bed along the east glass toward the reservoir's glow, a
## reading chair, cobalt light from its dome and band.
static func _guest_lake_room(body: StaticBody3D) -> void:
	var bed := TownProps.build_bed(_blanket(2))
	bed.position = Vector3(6.6, 0.0, -3.4)
	bed.rotation.y = PI * 0.5
	body.add_child(bed)
	Furnishings.armchair(body, Vector3(4.6, 0.0, -4.9), StiltKit.yaw_back_to(Vector2(-1, -1).normalized()))
	Furnishings.chest(body, Vector3(7.1, 0.0, -1.0), -PI * 0.5, Furnishings.OAK_DARK, 0.62)


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
	# The radiant drying bench, its heat seam along the front.
	_piece(body, Vector3(0.26, 0.22, 0.7), CalderaShell.BASALT, Vector3(0.6, 0.22, -1.4), true)
	_glow(body, "RadiantSeam", Vector3(0.01, 0.015, 0.62), Vector3(0.87, 0.3, -1.4), Color(1.0, 0.45, 0.12))


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
