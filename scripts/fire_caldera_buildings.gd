class_name FireCalderaBuildings
extends RefCounted

## The Fire caldera's buildings from their approved briefs
## (fire_caldera_buildings.md), each a CalderaShell on its SocketPlinth with
## its rooms inside. Shell frame: local +Z toward the plot's front (the
## reservoir), +X across; the floor at y 0 (the plinth's datum).

const BASALT_PARTITION := Color(0.24, 0.22, 0.21)
const COOL_STONE := Color(0.46, 0.46, 0.48)


# ---------------------------------------------------------------------------
# Guest house (brief section 3): 13 x 10 m. A generous receiving lounge fills
# the front 5.5 m. Four small rooms share a cool, flat-ceilinged rear band:
# provisions, washroom and two private guest rooms. This is intentionally a
# two-visitor house for a place that rarely receives cooler-bodied outsiders.
# ---------------------------------------------------------------------------

const GUEST_SIZE := Vector2(13.0, 10.0)
const GUEST_FRONT_DOOR := -4.0
const GUEST_STAINED: Array[Color] = [Color(0.16, 0.30, 0.72), Color(0.92, 0.60, 0.16)]


static func guest_house(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), GUEST_SIZE, GUEST_FRONT_DOOR, GUEST_STAINED)
	_guest_terrace(body)
	_guest_entry_fin(body)
	_guest_rear_rooms(body)
	_guest_rear_ceiling(body)

	# Eris receives visitors across a compact desk, facing the entrance. The
	# rest of the glazed lounge is deliberately open rather than dormitory-like.
	Furnishings.counter(body, Vector3(-4.65, 0.0, 1.10), PI, 1.55, false)
	_piece(body, Vector3(0.32, 0.22, 0.95), COOL_STONE, Vector3(-6.0, 0.22, 3.05), true)
	Furnishings.table(body, Vector3(2.25, 0.0, 2.70), 0.0, 2.6, 0.9, "chairs")
	_marker(body, "StandMarker", Vector3(-4.65, 0.0, 2.05), 0.0)
	_marker(body, "KeeperStand", Vector3(-4.65, 0.0, 0.25), 0.0)
	_marker(body, "GatherMarker", Vector3(1.9, 0.0, 1.45), 0.0)

	# Provisions room: insulated supplies for the rare cooler-bodied visitor.
	Furnishings.shelf(body, Vector3(-5.15, 0.0, -4.55), 0.0, 2.1, 4, "crocks")
	Furnishings.chest(body, Vector3(-6.0, 0.0, -2.15), PI * 0.5, Furnishings.OAK_DARK, 0.8)

	# Washroom: toilet, cool-water basin and a glass shower screen.
	var toilet := ToiletFixtures.build("incinerating")
	toilet.name = "IncineratingToilet"
	toilet.position = Vector3(-1.75, 0.0, -4.35)
	body.add_child(toilet)
	Furnishings.washstand(body, Vector3(-2.85, 0.0, -3.55), PI * 0.5)
	_piece(body, Vector3(0.52, 0.03, 0.52), COOL_STONE, Vector3(-0.55, 0.03, -4.25), false)
	var screen := SuperEgg.build_part(Vector3(0.52, 1.0, 0.035), Color(0.62, 0.72, 0.80, 0.35), 3.2, 3.2)
	screen.name = "ShowerScreen"
	screen.position = Vector3(-0.55, 1.02, -3.66)
	var glass := SolidModel.material(Color(0.62, 0.72, 0.80, 0.35), 0.10, 0.05)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	screen.material_override = glass
	body.add_child(screen)
	CollisionPolicy.mark_decorative(screen)

	# Two genuinely private rooms, each with one bed and one small chest.
	for i in 2:
		var x := 1.625 + float(i) * 3.25
		var bed := TownProps.build_bed(_blanket(i))
		bed.position = Vector3(x, 0.0, -3.62)
		body.add_child(bed)
		Furnishings.chest(body, Vector3(x + 0.92, 0.0, -1.35), 0.0, Furnishings.OAK_DARK, 0.55)
	_marker(body, "WakeMarker", Vector3(1.625, 0.60, -3.62), PI)
	return body


static func _guest_rear_rooms(body: StaticBody3D) -> void:
	var door_distances: Array[float] = [1.5, 4.75, 8.125, 11.375]
	TownProps.build_interior_wall(
		body, Vector2(-6.5, -0.5), Vector2(6.5, -0.5), 0.0, door_distances,
		BASALT_PARTITION, CalderaShell.STAINLESS_SHADOW, CalderaShell.STOREY
	)
	for x in [-3.5, 0.0, 3.25]:
		TownProps.build_interior_wall(
			body, Vector2(x, -5.0), Vector2(x, -0.5), 0.0, [],
			BASALT_PARTITION, CalderaShell.STAINLESS_SHADOW, CalderaShell.STOREY
		)


static func _guest_rear_ceiling(body: StaticBody3D) -> void:
	var ceiling := MeshInstance3D.new()
	ceiling.name = "CoolRearCeiling"
	var slab := BoxMesh.new()
	slab.size = Vector3(13.0, 0.12, 4.5)
	ceiling.mesh = slab
	ceiling.position = Vector3(0.0, CalderaShell.STOREY - 0.06, -2.75)
	ceiling.material_override = SolidModel.material(COOL_STONE.lightened(0.12), 0.84, 0.03)
	body.add_child(ceiling)
	CollisionPolicy.add_box(body, ceiling, slab.size, ceiling.position, Basis(), false)


## The shell was shifted two metres toward the service edge in the plan, so
## this full 13 x 4 m terrace occupies the public half of the reserved plot.
## Its finish is visual cladding flush with the socket plinth: the plinth is
## deliberately the one and only floor collider.
static func _guest_terrace(body: StaticBody3D) -> void:
	var terrace := MeshInstance3D.new()
	terrace.name = "DryGuestTerrace"
	var slab := BoxMesh.new()
	slab.size = Vector3(13.0, 0.08, 4.0)
	terrace.mesh = slab
	var material := StandardMaterial3D.new()
	material.albedo_color = COOL_STONE.darkened(0.12)
	material.roughness = 0.82
	terrace.material_override = material
	terrace.position = Vector3(0.0, -0.028, 7.0)
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
	var stem := SuperEgg.build_part(Vector3(0.11, 1.62, 0.11), CalderaShell.STEEL_BLUED, 3.2, 3.2)
	stem.position.y = 1.62
	fin.add_child(stem)
	CollisionPolicy.add_box(body, stem, Vector3(0.22, 3.24, 0.22), fin.position + stem.position, Basis(), false)
	_fin_glass(fin, "CobaltFinGlass", Vector3(-0.46, 2.56, 0.0), Vector3(0.39, 0.67, 0.045), Color(GUEST_STAINED[0], 0.72))
	_fin_glass(fin, "AmberFinGlass", Vector3(0.43, 2.13, 0.0), Vector3(0.34, 0.52, 0.045), Color(GUEST_STAINED[1], 0.72))
	_fin_beam(fin, Vector3(-0.04, 2.37, 0.0), Vector3(-0.46, 1.89, 0.0))
	_fin_beam(fin, Vector3(0.04, 2.20, 0.0), Vector3(0.43, 1.61, 0.0))


static func _fin_glass(fin: Node3D, name_text: String, at: Vector3, half: Vector3, colour: Color) -> void:
	var pane := SuperEgg.build_part(half, colour, 3.2, 3.2)
	pane.name = name_text
	pane.position = at
	var material := SolidModel.material(colour, 0.08, 0.08)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.material_override = material
	fin.add_child(pane)
	CollisionPolicy.mark_decorative(pane)


static func _fin_beam(fin: Node3D, start: Vector3, finish: Vector3) -> void:
	var delta := finish - start
	var beam := SuperEgg.build_part(Vector3(delta.length() * 0.5, 0.055, 0.065), CalderaShell.STAINLESS, 3.2, 3.2)
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
