class_name FireCalderaBuildings
extends RefCounted

## The Fire caldera's buildings from their approved briefs
## (fire_caldera_buildings.md), each a CalderaShell on its SocketPlinth with
## its rooms inside. Shell frame: local +Z toward the plot's front (the
## reservoir), +X across; the floor at y 0 (the plinth's datum).

const BASALT_PARTITION := Color(0.24, 0.22, 0.21)
const COOL_STONE := Color(0.46, 0.46, 0.48)
const PARTITION := 0.16
const INNER_DOOR := 1.0
const PARTY_DOOR := 1.2


# ---------------------------------------------------------------------------
# Guest house (brief section 3): 13 x 10 m. West column x -6.5..-1.5: the
# receiving room at the front (z -1..5), the provisions cabinet (x -6.5..-4)
# and the washroom (x -4..-1.5) behind it (z -5..-1). The party room fills x
# -1.5..6.5. The front door opens into the receiving room from the forecourt;
# the party room's door is in the shared wall; the washroom opens off the
# party room, in the aisle between its two rows of beds, so guests never
# cross the receiving room; the cabinet opens behind Eris's counter.
# ---------------------------------------------------------------------------

const GUEST_SIZE := Vector2(13.0, 10.0)
const GUEST_FRONT_DOOR := -4.0
const GUEST_STAINED: Array[Color] = [Color(0.16, 0.30, 0.72), Color(0.92, 0.60, 0.16)]


static func guest_house(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), GUEST_SIZE, GUEST_FRONT_DOOR, GUEST_STAINED)
	_guest_terrace(body)
	_guest_entry_fin(body)
	var top := CalderaShell.STOREY
	# Partitions, with their doorways.
	_partition(body, Vector2(-1.5, -5.0), Vector2(-1.5, 5.0), top, [[2.5, PARTY_DOOR], [-1.7, INNER_DOOR]])
	_partition(body, Vector2(-6.5, -1.0), Vector2(-1.5, -1.0), top, [[-5.25, INNER_DOOR]])
	_partition(body, Vector2(-4.0, -5.0), Vector2(-4.0, -1.0), top, [])
	# Receiving room: Eris's counter facing the door, a cool stone bench on
	# the west wall, the window onto the reservoir behind the glazed front.
	Furnishings.counter(body, Vector3(-4.6, 0.0, 1.0), PI, 1.6, false)
	_piece(body, Vector3(0.3, 0.22, 0.9), COOL_STONE, Vector3(-6.0, 0.22, 3.2), true)
	_marker(body, "StandMarker", Vector3(-4.6, 0.0, 0.1), 0.0)
	_marker(body, "KeeperStand", Vector3(-4.6, 0.0, 1.85), PI)
	# Provisions cabinet: insulated shelves of imported food and water.
	Furnishings.shelf(body, Vector3(-5.25, 0.0, -4.6), 0.0, 2.0, 4, "crocks")
	Furnishings.chest(body, Vector3(-6.0, 0.0, -2.2), PI * 0.5, Furnishings.OAK_DARK, 0.8)
	# Washroom: the incinerating toilet against the back wall, a cool-water
	# basin by the door, a shower in the west corner behind a glass screen.
	var toilet := ToiletFixtures.build("incinerating")
	toilet.name = "IncineratingToilet"
	toilet.position = Vector3(-2.2, 0.0, -4.4)
	body.add_child(toilet)
	Furnishings.washstand(body, Vector3(-2.8, 0.0, -1.35), StiltKit.yaw_back_to(Vector2(0, 1)))
	_piece(body, Vector3(0.55, 0.03, 0.55), COOL_STONE, Vector3(-3.35, 0.03, -4.35), false)
	var screen := CalderaShell._pane(body, Vector3(-3.35, 1.05, -3.75), Vector2(0.55, 1.0), Color(0.62, 0.72, 0.80, 0.35))
	screen.name = "ShowerScreen"
	# Party room: eight beds in two rows of four, heads to the back wall and to
	# the aisle; a long table with benches at the reservoir window.
	for row in 2:
		var z := -3.47 if row == 0 else 0.09
		for i in 4:
			var bed := TownProps.build_bed(_blanket(row * 4 + i))
			bed.position = Vector3(-0.41 + 1.94 * float(i), 0.0, z)
			body.add_child(bed)
	Furnishings.table(body, Vector3(2.5, 0.0, 3.2), 0.0, 3.2, 1.0, "benches")
	_marker(body, "WakeMarker", Vector3(-0.41, 0.6, -3.47), PI)
	_marker(body, "GatherMarker", Vector3(2.5, 0.0, 1.9), 0.0)
	return body


## The shell was shifted two metres toward the service edge in the plan, so
## this full 13 x 4 m terrace occupies the public half of the reserved plot.
## Its finish is visual cladding flush with the socket plinth: the plinth is
## deliberately the one and only floor collider.
static func _guest_terrace(body: StaticBody3D) -> void:
	var terrace := MeshInstance3D.new()
	terrace.name = "DryPartyTerrace"
	var slab := BoxMesh.new()
	slab.size = Vector3(13.0, 0.08, 4.0)
	terrace.mesh = slab
	var material := StandardMaterial3D.new()
	material.albedo_color = COOL_STONE.darkened(0.12)
	material.roughness = 0.82
	terrace.material_override = material
	terrace.position = Vector3(0.0, -0.04, 7.0)
	body.add_child(terrace)
	CollisionPolicy.mark_decorative(terrace)


## A cobalt-and-amber threshold fin beside, never in front of, the two-metre
## door. The forged stem forks like the shell mullions and holds two mineral
## glass leaves, making the entrance legible from the forecourt.
static func _guest_entry_fin(body: StaticBody3D) -> void:
	var fin := Node3D.new()
	fin.name = "EntryFin"
	fin.position = Vector3(-6.0, 0.0, 6.2)
	body.add_child(fin)
	var stem := SuperEgg.build_part(Vector3(0.11, 1.8, 0.11), CalderaShell.STEEL_BLUED, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	stem.position.y = 1.8
	fin.add_child(stem)
	CollisionPolicy.add_box(body, stem, Vector3(0.22, 3.6, 0.22), fin.position + stem.position, Basis(), false)
	for side: float in [-1.0, 1.0]:
		var branch := SuperEgg.build_part(Vector3(0.055, 0.72, 0.07), CalderaShell.STEEL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		branch.position = Vector3(side * 0.22, 2.85, 0.0)
		branch.rotation.z = side * -0.34
		fin.add_child(branch)
		CollisionPolicy.mark_decorative(branch)
	var cobalt := CalderaShell._pane(body, fin.position + Vector3(-0.43, 1.72, 0.0), Vector2(0.34, 1.45), Color(GUEST_STAINED[0], 0.72))
	cobalt.name = "CobaltFinGlass"
	var amber := CalderaShell._pane(body, fin.position + Vector3(0.36, 1.35, 0.0), Vector2(0.27, 1.08), Color(GUEST_STAINED[1], 0.72))
	amber.name = "AmberFinGlass"


static func _blanket(i: int) -> Color:
	var tones: Array[Color] = [Color(0.16, 0.30, 0.72), Color(0.92, 0.60, 0.16), Color(0.30, 0.34, 0.40), Color(0.62, 0.30, 0.20)]
	return tones[i % tones.size()]


## A straight basalt partition from `a` to `b` (shell plan, along x or z),
## floor to `top`, with doorways given as [centre on the wall's run, width],
## each with a lintel above.
static func _partition(body: StaticBody3D, a: Vector2, b: Vector2, top: float, doors: Array) -> void:
	var along_x := absf(b.x - a.x) > absf(b.y - a.y)
	var start := a.x if along_x else a.y
	var finish := b.x if along_x else b.y
	if start > finish:
		var swap := start
		start = finish
		finish = swap
	var cuts: Array = []
	for door: Array in doors:
		cuts.append(Vector2(float(door[0]) - float(door[1]) * 0.5, float(door[0]) + float(door[1]) * 0.5))
	cuts.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
	var pieces: Array[Vector2] = []
	var cursor := start
	for cut: Vector2 in cuts:
		pieces.append(Vector2(cursor, cut.x))
		cursor = cut.y
	pieces.append(Vector2(cursor, finish))
	for piece: Vector2 in pieces:
		if piece.y - piece.x < 0.05:
			continue
		var mid := (piece.x + piece.y) * 0.5
		var length := piece.y - piece.x
		var size := Vector3(length, top, PARTITION) if along_x else Vector3(PARTITION, top, length)
		var at := Vector3(mid, top * 0.5, a.y) if along_x else Vector3(a.x, top * 0.5, mid)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = BASALT_PARTITION
		material.roughness = 0.9
		mesh.material_override = material
		mesh.position = at
		body.add_child(mesh)
		CollisionPolicy.add_box(body, mesh, size, at, Basis(), false)
	# A lintel over each doorway, so the wall reads as one.
	for cut: Vector2 in cuts:
		var mid := (cut.x + cut.y) * 0.5
		var length := cut.y - cut.x
		var lintel_h := top - CalderaShell.DOOR_HEIGHT
		var size := Vector3(length, lintel_h, PARTITION) if along_x else Vector3(PARTITION, lintel_h, length)
		var at := Vector3(mid, CalderaShell.DOOR_HEIGHT + lintel_h * 0.5, a.y) if along_x else Vector3(a.x, CalderaShell.DOOR_HEIGHT + lintel_h * 0.5, mid)
		var mesh := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = size
		mesh.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = BASALT_PARTITION.darkened(0.1)
		mesh.material_override = material
		mesh.position = at
		body.add_child(mesh)
		CollisionPolicy.add_box(body, mesh, size, at, Basis(), false)


static func _piece(body: StaticBody3D, half: Vector3, colour: Color, at: Vector3, solid: bool) -> void:
	Furnishings.piece(body, half, colour, at, 0.0, solid)


static func _marker(body: StaticBody3D, name_text: String, at: Vector3, yaw: float) -> void:
	var marker := Marker3D.new()
	marker.name = name_text
	marker.position = at
	marker.rotation.y = yaw
	body.add_child(marker)
