class_name FireCalderaCivic
extends RefCounted

## The caldera's open civic living room. A monumental central portal frames a
## building-scale living terrarium; council, school, archive and observation
## uses occupy the clear perimeter beneath one luminous butterfly gridshell.
## Austin Central Library supplies the social-atrium/reading-porch lesson,
## Calgary Central Library the civic portal and sky-facing heart, and the
## British Museum Great Court the idea of a light glazed roof over a public
## court. The forms themselves remain Fire volcanic modernism.

const SIZE := Vector2(24.0, 15.0)
const STOREY := 4.0
const UPPER := 4.0
const HALL := 8.6
const PORTAL_CLEAR := 5.2
const TERRARIUM_HALF := Vector2(4.4, 3.5)
const TERRARIUM_RISE := 8.15
const FLOOR := Color(0.30, 0.28, 0.27)
const PARTITION := FireCalderaBuildings.BASALT_PARTITION
const COBALT := Color(0.12, 0.30, 0.76, 0.72)
const AMBER := Color(0.96, 0.56, 0.12, 0.72)
const TEAL := Color(0.08, 0.56, 0.54, 0.72)
const STAINED: Array[Color] = [COBALT, AMBER, TEAL]


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.make_body(parent, entry, float(line["datum"]))
	body.name = "CIVICShell"
	_court_enclosure(body)
	_upper_floor(body)
	_switchback_ramp(body)
	_upper_shell(body)
	_council(body)
	_school_and_archive(body)
	_terrarium(body)
	_daylight_canopy(body)
	_observation_landing(body)
	_lights(body)
	_register_public_routes(body)
	return body


## A symmetrical, mostly glazed facade around a leafless civic portal. The
## matching rear opening makes the terrarium a waypoint between Highline and
## reservoir outlook rather than an object at the end of a room.
static func _court_enclosure(body: StaticBody3D) -> void:
	var glass_top := HALL - 0.25
	for z: float in [-7.5, 7.5]:
		var front := z > 0.0
		var portal_height := 6.7 if front else 5.2
		_portal_frame(body, Vector3(0.0, 0.0, z), portal_height, "CivicEntryPortal" if front else "CivicOutlookPortal")
		for side: float in [-1.0, 1.0]:
			var x := side * 7.65
			CalderaShell._pane(body, "CivicFacadeGlass", Vector3(x, glass_top * 0.5, z), Vector2(4.25, glass_top * 0.5 - 0.08), 0.0, Color(CalderaShell.CLEAR_GLASS, 0.23))
			CalderaShell._metal(body, Vector3(side * 3.35, glass_top * 0.5, z), Vector3(0.28, glass_top, 0.28), CalderaShell.STEEL_BLUED, true)
	for x: float in [-12.0, 12.0]:
		CalderaShell._pane(body, "CivicSideGlass", Vector3(x, glass_top * 0.5, 0.0), Vector2(7.25, glass_top * 0.5 - 0.08), PI * 0.5, Color(CalderaShell.SMOKY_GLASS, 0.22))
	# Four branching piers carry the canopy and make the entrance shoulders
	# visible without turning the open portal into a conventional portico.
	for at: Vector3 in [Vector3(-3.35, 0, 7.5), Vector3(3.35, 0, 7.5), Vector3(-11.65, 0, -7.2), Vector3(11.65, 0, -7.2)]:
		_branching_pier(body, at)
	# Thin colored glass veils hang inside the clear facade. They are the civic
	# art layer, not the building's wall system.
	var veil_colours := [Color(0.94, 0.35, 0.13, 0.58), Color(0.64, 0.12, 0.72, 0.58), Color(0.08, 0.62, 0.52, 0.58), Color(0.13, 0.34, 0.90, 0.58)]
	for i in 4:
		var side := -1.0 if i < 2 else 1.0
		var rank := i % 2
		var pane := SuperEgg.build_part(Vector3(0.055, 1.55 + 0.35 * rank, 0.72), veil_colours[i], 6.0, 6.0)
		pane.name = "SuspendedCivicGlass"
		pane.position = Vector3(side * (5.0 + 1.65 * rank), 5.65 - 0.25 * rank, 7.15)
		pane.material_override = SolidModel.material(veil_colours[i], 0.04, 0.06)
		body.add_child(pane)
		CollisionPolicy.mark_decorative(pane)


static func _portal_frame(body: StaticBody3D, at: Vector3, height: float, label: String) -> void:
	var outline := OpeningTrim.door_arch(PORTAL_CLEAR * 0.5, height, TownProps.OPENING_EXPONENT, 0.9, 0.06)
	var outer := OpeningTrim.piped_frame(outline, 0.18, CalderaShell.STEEL_BLUED, false, Vector2(0.0, height * 0.45))
	outer.name = label
	outer.position = at
	body.add_child(outer)
	# A second fine stainless line makes the frame luminous from both approach
	# directions without inserting an opaque wall around the opening.
	var inner_outline: Array[Vector2] = []
	for point: Vector2 in outline:
		inner_outline.append(Vector2(point.x * 0.94, point.y * 0.96 + 0.05))
	var inner := OpeningTrim.piped_frame(inner_outline, 0.055, CalderaShell.STAINLESS, false, Vector2(0.0, height * 0.45))
	inner.name = "%sInner" % label
	inner.position = at + Vector3(0.0, 0.0, -0.025)
	body.add_child(inner)


static func _branching_pier(body: StaticBody3D, at: Vector3) -> void:
	CalderaShell._metal(body, at + Vector3.UP * 3.85, Vector3(0.38, 7.7, 0.38), CalderaShell.STEEL_BLUED, true)
	for dx: float in [-1.0, 1.0]:
		CalderaShell._beam(body, at + Vector3(0.0, 6.8, 0.0), at + Vector3(dx * 1.25, 8.85, -0.35), Vector2(0.20, 0.18), CalderaShell.STEEL_BLUED)


static func _council_spec() -> Dictionary:
	return {
		"size": Vector2(10.0, 15.0), "offset": Vector2(-7.0, 0.0),
		"storey": HALL, "stained": STAINED, "transom": false, "pitch": 0.0,
		"overhang": {"east": 0.0},
		"walls": {
			"front": [
				{"to": 3.3, "kind": "glass", "tint": Color(COBALT, 0.34)},
				{"to": 6.6, "kind": "glass", "tint": Color(AMBER, 0.34)},
				{"to": 10.0, "kind": "glass", "tint": Color(TEAL, 0.34)},
			],
			"back": [{"to": 10.0, "kind": "stone", "band": -1}],
			"west": [
				{"to": 5.0, "kind": "stone", "band": -1},
				{"to": 10.0, "kind": "glass", "tint": CalderaShell.SMOKY_GLASS, "band": -1},
				{"to": 15.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS, "band": -1},
			],
			"east": [{"to": 15.0, "kind": "open"}],
		},
	}


static func _middle_spec() -> Dictionary:
	return {
		"size": Vector2(7.0, 15.0), "offset": Vector2(1.5, 0.0),
		"stained": STAINED, "transom": false, "roof": false,
		"overhang": {"west": 0.0, "east": 0.0},
		"walls": {
			"front": [
				{"to": 3.5, "kind": "glass", "tint": Color(TEAL, 0.28)},
				{"to": 7.0, "kind": "glass", "tint": Color(AMBER, 0.28)},
			],
			"back": [{"to": 7.0, "kind": "stone", "band": -1}],
			"west": [{"to": 15.0, "kind": "open"}],
			"east": [{"to": 15.0, "kind": "open"}],
		},
	}


static func _hall_spec() -> Dictionary:
	return {
		"size": Vector2(7.0, 15.0), "offset": Vector2(8.5, 0.0),
		"stained": STAINED, "transom": false, "roof": false,
		"overhang": {"west": 0.0},
		"walls": {
			"front": [
				{"to": 1.8, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
				{"to": 5.2, "kind": "door", "clear": 2.6, "door_type": "sliding", "label": "civic entrance"},
				{"to": 7.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
			"back": [{"to": 7.0, "kind": "stone", "band": -1}],
			"west": [{"to": 15.0, "kind": "open"}],
			"east": [
				{"to": 10.3, "kind": "stone", "band": -1},
				{"to": 15.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
		},
	}


static func _ground_partitions(body: StaticBody3D) -> void:
	# The east wall of the council has one broad, leafless public passage from
	# the central lobby.  Nothing swings into the standing room.
	_wall_with_openings(body, -7.5, 7.5, -2.0, false, [
		{"at": 0.0, "width": 2.6, "label": "council passage", "type": "arch"},
	], 0.0, HALL)
	# The middle bay is exactly school (front 6), lobby (3), archive (rear 6).
	_wall_with_openings(body, -2.0, 5.0, 1.5, true, [
		{"at": 1.5, "width": 2.0, "label": "school passage", "type": "sliding"},
	], 0.0, STOREY)
	_wall_with_openings(body, -2.0, 5.0, -1.5, true, [
		{"at": 1.5, "width": 2.0, "label": "archive passage", "type": "sliding"},
	], 0.0, STOREY)
	# A wide opening between the entrance hall and the central lobby.
	_wall_with_openings(body, -7.5, 7.5, 5.0, false, [
		{"at": 0.0, "width": 2.8, "label": "lobby passage", "type": "arch"},
		{"at": 4.5, "width": 2.2, "label": "school hall passage", "type": "arch"},
		{"at": -4.5, "width": 2.2, "label": "archive hall passage", "type": "arch"},
	], 0.0, STOREY)


static func _wall_with_openings(body: StaticBody3D, lo: float, hi: float, fixed: float, along_x: bool, doors: Array, base: float, height: float) -> void:
	var ordered := doors.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["at"]) < float(b["at"]))
	var cursor := lo
	for door: Dictionary in ordered:
		var half := float(door["width"]) * 0.5 + 0.28
		var a := float(door["at"]) - half
		var b := float(door["at"]) + half
		_partition(body, cursor, a, fixed, along_x, base, height)
		var origin := Vector3((a + b) * 0.5, base, fixed) if along_x else Vector3(fixed, base, (a + b) * 0.5)
		var yaw := 0.0 if along_x else PI * 0.5
		CalderaShell.door_opening(body, origin, yaw, b - a, height, 0.18, float(door["width"]), 2.75, 0, PARTITION)
		if str(door["type"]) == "sliding":
			CalderaShell.open_sliding_door(body, origin, yaw, float(door["width"]), 2.75, true)
		var point := Vector2(float(door["at"]), fixed) if along_x else Vector2(fixed, float(door["at"]))
		var normal := Vector2(0, 1) if along_x else Vector2(1, 0)
		for direction: Vector2 in [normal, -normal]:
			ClearZones.add(body, str(door["label"]), "door", point, direction, 0.0, 1.0, float(door["width"]) * 0.5, base + 0.05, base + 1.95)
		cursor = b
	_partition(body, cursor, hi, fixed, along_x, base, height)


static func _partition(body: StaticBody3D, lo: float, hi: float, fixed: float, along_x: bool, base: float, height: float) -> void:
	if hi - lo < 0.05:
		return
	var size := Vector3(hi - lo, height, 0.18) if along_x else Vector3(0.18, height, hi - lo)
	var at := Vector3((lo + hi) * 0.5, base + height * 0.5, fixed) if along_x else Vector3(fixed, base + height * 0.5, (lo + hi) * 0.5)
	FireCalderaOren._block(body, "CivicPartition", at, size, PARTITION)


static func _upper_floor(body: StaticBody3D) -> void:
	# One rear observation porch: the centre stays double height and the glass
	# crown of the terrarium remains visible from entrance to roof.
	CalderaShell.soft_slab(body, "CivicObservationGallery", Vector3(0.8, UPPER - 0.10, -5.85), Vector3(10.8, 0.10, 1.45), Vector2(10.8, 1.45), FLOOR)
	# The gallery guard stops at the ramp throat.
	_guard(body, Vector3(-11.2, UPPER + 1.05, -4.35), Vector3(-9.15, UPPER + 1.05, -4.35))
	_guard(body, Vector3(-6.75, UPPER + 1.05, -4.35), Vector3(11.6, UPPER + 1.05, -4.35))


static func _switchback_ramp(body: StaticBody3D) -> void:
	# Two six-metre flights sit against the west edge, leaving the public axis
	# and all four sides of the terrarium unobstructed. At 2 m rise per flight
	# the grade is 18.4 percent. Both landing interfaces share exact datums.
	FireCalderaOren._wedge(body, "CivicRampLower", Vector2(-11.0, 1.6), Vector2(-9.0, 6.4), 2.0, 0.0, false, FLOOR)
	FireCalderaOren._block(body, "CivicRampLanding", Vector3(-9.4, 1.0, 1.1), Vector3(3.2, 2.0, 1.0), FLOOR)
	FireCalderaOren._wedge(body, "CivicRampUpper", Vector2(-9.0, -4.4), Vector2(-7.0, 1.6), UPPER, 2.0, false, FLOOR)
	CalderaShell.soft_slab(body, "CivicRampHead", Vector3(-8.0, UPPER - 0.10, -4.75), Vector3(1.15, 0.10, 0.35), Vector2(1.15, 0.35), FLOOR)
	_guard(body, Vector3(-11.0, 1.05, 6.4), Vector3(-11.0, 3.05, 1.6))
	_guard(body, Vector3(-7.0, 3.05, 1.6), Vector3(-7.0, UPPER + 1.05, -4.4))
	ClearZones.add(body, "civic lower ramp", "ramp", Vector2(-10.0, 4.0), Vector2(0, -1), 2.4, 2.4, 0.75, 0.05, 2.0)
	ClearZones.add(body, "civic upper ramp", "ramp", Vector2(-8.0, -1.4), Vector2(0, -1), 3.0, 3.0, 0.75, 2.0, UPPER)


static func _guard(body: StaticBody3D, from: Vector3, to: Vector3) -> void:
	var member := CalderaShell._beam(body, from, to, Vector2(0.10, 0.10), CalderaShell.STAINLESS)
	var delta := to - from
	var basis := member.transform.basis.orthonormalized()
	CollisionPolicy.add_box(body, member, Vector3(delta.length(), 0.14, 0.14), (from + to) * 0.5, basis, false)


static func _upper_shell(body: StaticBody3D) -> void:
	# Instruments sit on an open rear mezzanine instead of beneath another
	# dome. The glass roof and terrarium remain the only dominant silhouettes.
	for i in 6:
		var x := -4.4 + 1.7 * float(i)
		CalderaFurniture.piece(body, Vector3(0.30, 0.65, 0.24), CalderaShell.VOLCANIC_STONE, Vector3(x, UPPER + 0.65, -6.0), 0.0, true, 6.0)
		CalderaShell._metal(body, Vector3(x, UPPER + 1.45, -6.0), Vector3(0.04, 0.35, 0.04), CalderaShell.STAINLESS, false)
	FireCalderaBuildings._marker(body, "SelkaInstrumentMarker", Vector3(0.0, UPPER, -5.6), 0.0)


static func _council(body: StaticBody3D) -> void:
	# Five warm basalt seats occupy the west porch and face the living archive.
	# They no longer turn the centerpiece into a display at the back of a room.
	for i in 5:
		var z := lerpf(2.25, 6.05, float(i) / 4.0)
		var x := -7.65 - 0.45 * cos(lerpf(-PI * 0.5, PI * 0.5, float(i) / 4.0))
		CalderaFurniture.chair(body, Vector3(x, 0.0, z), -PI * 0.5, Color(0.42, 0.25, 0.18))
	FireCalderaBuildings._marker(body, "CouncilSpeakerMarker", Vector3(-5.6, 0.0, 4.0), -PI * 0.5)
	FireCalderaBuildings._marker(body, "CouncilStandingMarker", Vector3(-8.4, 0.0, 4.0), PI * 0.5)


static func _school_and_archive(body: StaticBody3D) -> void:
	# The school is an open reading porch behind a transparent divider.
	_glass_divider(body, Vector2(6.5, 1.15), Vector2(6.5, 6.85), [])
	for z: float in [2.15, 4.25, 6.15]:
		CalderaFurniture.bench(body, Vector3(8.0, 0.0, z), PI * 0.5, 1.6)
	CalderaFurniture.table(body, Vector3(10.1, 0.0, 3.3), PI * 0.5, 1.7, 0.8)
	# The archive is the only secure ground room. Clear/smoky glass preserves
	# visual continuity while the centered surface slider protects the records.
	_glass_divider(body, Vector2(6.5, -1.15), Vector2(6.5, -6.85), [])
	_glass_divider(body, Vector2(6.5, -1.15), Vector2(11.65, -1.15), [{"at": 8.75, "width": 2.0}])
	CalderaFurniture.shelves(body, Vector3(8.55, 0.0, -6.85), PI, 4.8, 4, func(b: StaticBody3D, p: Vector3, i: int) -> void:
		CalderaFurniture.piece(b, Vector3(0.16, 0.025, 0.11), CalderaShell.VOLCANIC_STONE.lightened(0.12), p + Vector3(0, 0.03, 0), 0.0, false, 6.0))
	CalderaFurniture.table(body, Vector3(8.6, 0.0, -3.7), 0.0, 2.4, 0.8)
	FireCalderaBuildings._marker(body, "SchoolMarker", Vector3(8.0, 0.0, 4.5), PI)
	FireCalderaBuildings._marker(body, "ArchiveMarker", Vector3(8.5, 0.0, -4.3), 0.0)


## A full-height glass screen with optional open SuperEgg-framed sliders. It
## divides functions while preserving the court's one-room daylight character.
static func _glass_divider(body: StaticBody3D, a: Vector2, b: Vector2, openings: Array) -> void:
	var along := (b - a).normalized()
	var length := a.distance_to(b)
	var yaw := atan2(along.y, along.x)
	var ordered := openings.duplicate()
	ordered.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left["at"]) < float(right["at"]))
	var cursor := 0.0
	for opening: Dictionary in ordered:
		var centre_distance := float(opening["at"])
		# Absolute x coordinates are convenient for the east archive cross-screen.
		if absf(b.x - a.x) > absf(b.y - a.y):
			centre_distance = centre_distance - a.x
		var half := float(opening["width"]) * 0.5
		_add_glass_screen_run(body, a + along * cursor, a + along * maxf(cursor, centre_distance - half), yaw)
		var origin2 := a + along * centre_distance
		var origin := Vector3(origin2.x, 0.0, origin2.y)
		CalderaShell.door_opening(body, origin, yaw, float(opening["width"]) + 0.55, STOREY, 0.18, float(opening["width"]), 2.75, 0, PARTITION)
		CalderaShell.open_sliding_door(body, origin, yaw, float(opening["width"]), 2.75, true)
		ClearZones.add(body, "archive slider", "door", origin2, Vector2(-along.y, along.x), 1.25, 1.25, half + 0.15, 0.05, 1.95)
		cursor = centre_distance + half
	_add_glass_screen_run(body, a + along * cursor, b, yaw)


static func _add_glass_screen_run(body: StaticBody3D, a: Vector2, b: Vector2, yaw: float) -> void:
	var length := a.distance_to(b)
	if length < 0.08:
		return
	var middle := (a + b) * 0.5
	CalderaShell._pane(body, "CivicGlassDivider", Vector3(middle.x, STOREY * 0.5, middle.y), Vector2(length * 0.5, STOREY * 0.5 - 0.08), yaw, Color(CalderaShell.CLEAR_GLASS, 0.20))
	for point: Vector2 in [a, b]:
		CalderaShell._metal(body, Vector3(point.x, STOREY * 0.5, point.y), Vector3(0.14, STOREY, 0.14), CalderaShell.STEEL_BLUED, true)


static func _terrarium(body: StaticBody3D) -> void:
	# The shell owns the centre of the plan. Its crown rises more than three
	# metres above the tree, so foliage never appears to puncture the glass.
	var centre := Vector3.ZERO
	var base := SuperEgg.build_part(Vector3(TERRARIUM_HALF.x + 0.22, 0.34, TERRARIUM_HALF.y + 0.22), FLOOR, 5.5, 5.5)
	base.name = "TerrariumPlinth"
	base.position = centre + Vector3(0.0, 0.34, 0.0)
	body.add_child(base)
	CollisionPolicy.add_box(body, base, Vector3(TERRARIUM_HALF.x * 2.0 + 0.44, 0.68, TERRARIUM_HALF.y * 2.0 + 0.44), base.position, Basis(), false)
	var shell := _clipped_dome(Vector3(TERRARIUM_HALF.x, TERRARIUM_RISE, TERRARIUM_HALF.y), Color(0.25, 0.73, 0.70, 0.18), 4.6)
	shell.name = "CivicTerrariumShell"
	shell.position = centre + Vector3(0.0, 0.56, 0.0)
	var glass := SolidModel.material(Color(0.25, 0.73, 0.70, 0.18), 0.02, 0.02)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = glass
	body.add_child(shell)
	CollisionPolicy.mark_decorative(shell)
	var soil := SuperEgg.build_part(Vector3(TERRARIUM_HALF.x - 0.35, 0.26, TERRARIUM_HALF.y - 0.35), Color(0.18, 0.10, 0.055), 4.0, 4.0)
	soil.position = centre + Vector3(0.0, 0.58, 0.0)
	body.add_child(soil)
	CollisionPolicy.mark_decorative(soil)
	var tree := NatureProps.build_round_tree(5.1, Color(0.16, 0.48, 0.22))
	tree.name = "TerrariumLivingTree"
	tree.position = centre + Vector3(0.0, 0.72, 0.0)
	tree.scale = Vector3.ONE * 0.92
	body.add_child(tree)
	# Rock and low plant specimens turn the enclosure into a miniature living
	# landscape rather than one tree on an empty display disc.
	for specimen: Array in [
		[Vector3(-2.45, 0.0, 1.25), Vector3(0.60, 0.40, 0.52), Color(0.32, 0.29, 0.27)],
		[Vector3(2.35, 0.0, -1.25), Vector3(0.52, 0.34, 0.46), Color(0.38, 0.34, 0.30)],
		[Vector3(-2.20, 0.0, -1.55), Vector3(0.48, 0.28, 0.40), Color(0.23, 0.42, 0.18)],
		[Vector3(2.10, 0.0, 1.65), Vector3(0.54, 0.31, 0.44), Color(0.18, 0.48, 0.22)],
	]:
		var piece := SuperEgg.build_part(specimen[1], specimen[2], 3.0, 3.0)
		piece.position = centre + (specimen[0] as Vector3) + Vector3(0.0, 0.82, 0.0)
		body.add_child(piece)
		CollisionPolicy.mark_decorative(piece)
	_ellipse_ring(body, centre + Vector3(0.0, 0.57, 0.0), TERRARIUM_HALF + Vector2(0.06, 0.06))
	# Branching ribs and a suspended mineral-glass belt make the enclosure read
	# as fabricated civic infrastructure, not an enlarged inn skylight.
	var belt := [Color(0.93, 0.43, 0.10, 0.55), Color(0.72, 0.12, 0.56, 0.55), Color(0.10, 0.45, 0.88, 0.55), Color(0.10, 0.62, 0.42, 0.55)]
	for i in 12:
		var a := TAU * float(i) / 12.0
		var foot := centre + Vector3(cos(a) * TERRARIUM_HALF.x, 0.64, sin(a) * TERRARIUM_HALF.y)
		var shoulder := centre + Vector3(cos(a) * TERRARIUM_HALF.x * 0.55, 5.95, sin(a) * TERRARIUM_HALF.y * 0.55)
		CalderaShell._beam(body, foot, shoulder, Vector2(0.085, 0.085), CalderaShell.STEEL_BLUED)
		if i % 3 == 0:
			var pane := SuperEgg.build_part(Vector3(0.055, 0.68, 0.42), belt[i / 3], 6.0, 6.0)
			pane.name = "TerrariumMineralGlass"
			pane.position = lerp(foot, shoulder, 0.72)
			pane.rotation.y = -a
			pane.material_override = SolidModel.material(belt[i / 3], 0.04, 0.06)
			body.add_child(pane)
			CollisionPolicy.mark_decorative(pane)


## One continuous translucent butterfly surface. The long central valley falls
## toward the rear, so the roof never repeats the inn's dome and never ponds
## over the entrance. Broad clear panes are the field; restrained coloured
## glass remains a suspended accent below it.
static func _daylight_canopy(body: StaticBody3D) -> void:
	var hx := 12.65
	var hz := 8.15
	var x_steps := 24
	var z_steps := 16
	var roof_y := func(x: float, z: float) -> float:
		return 9.00 + 1.05 * pow(absf(x) / hx, 1.45) + 0.55 * (z / hz)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for zi in z_steps:
		var z0 := lerpf(-hz, hz, float(zi) / float(z_steps))
		var z1 := lerpf(-hz, hz, float(zi + 1) / float(z_steps))
		for xi in x_steps:
			var x0 := lerpf(-hx, hx, float(xi) / float(x_steps))
			var x1 := lerpf(-hx, hx, float(xi + 1) / float(x_steps))
			var a := Vector3(x0, roof_y.call(x0, z0), z0)
			var b := Vector3(x1, roof_y.call(x1, z0), z0)
			var c := Vector3(x1, roof_y.call(x1, z1), z1)
			var d := Vector3(x0, roof_y.call(x0, z1), z1)
			_canopy_quad(st, a, b, c, d)
	var canopy := MeshInstance3D.new()
	canopy.name = "CivicSaddleCanopy"
	canopy.mesh = st.commit()
	var roof_glass := SolidModel.material(Color(0.49, 0.76, 0.82, 0.24), 0.05, 0.04)
	roof_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	canopy.material_override = roof_glass
	body.add_child(canopy)
	var collision := CollisionShape3D.new()
	collision.name = "CivicSaddleCanopyCollision"
	collision.shape = canopy.mesh.create_trimesh_shape()
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)
	# Seven transverse V-ribs and five longitudinal fall ribs explain the span.
	for zi in 7:
		var z := lerpf(-hz, hz, float(zi) / 6.0)
		var left := Vector3(-hx, roof_y.call(-hx, z) - 0.04, z)
		var valley := Vector3(0.0, roof_y.call(0.0, z) - 0.04, z)
		var right := Vector3(hx, roof_y.call(hx, z) - 0.04, z)
		CalderaShell._beam(body, left, valley, Vector2(0.12, 0.13), CalderaShell.STEEL_BLUED)
		CalderaShell._beam(body, valley, right, Vector2(0.12, 0.13), CalderaShell.STEEL_BLUED)
	for xi in 5:
		var x := lerpf(-hx, hx, float(xi) / 4.0)
		CalderaShell._beam(body, Vector3(x, roof_y.call(x, -hz) - 0.05, -hz), Vector3(x, roof_y.call(x, hz) - 0.05, hz), Vector2(0.10, 0.12), CalderaShell.STAINLESS_SHADOW)


static func _canopy_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	var normal := (b - a).cross(d - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	for point: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(normal)
		st.add_vertex(point)


static func _register_public_routes(body: StaticBody3D) -> void:
	ClearZones.add(body, "civic central portal", "door", Vector2(0.0, 7.5), Vector2(0, -1), 2.0, 3.0, PORTAL_CLEAR * 0.5, 0.05, 2.2)
	ClearZones.add_lane(body, "civic entry axis", [Vector3(0.0, 0.05, 9.0), Vector3(0.0, 0.05, 4.6)], 0.55)
	ClearZones.add_lane(body, "civic east terrarium walk", [Vector3(5.55, 0.05, 5.6), Vector3(5.55, 0.05, -5.4)], 0.55)
	ClearZones.add_lane(body, "civic west terrarium walk", [Vector3(-5.55, 0.05, 5.6), Vector3(-5.55, 0.05, -5.4)], 0.55)


## A real half-SuperEgg: the y=0 plane discards the lower hemisphere and the
## shared mesh builder closes that cut with a planar cap.  This avoids the
## visible hanging bowl produced by merely burying a complete SuperEgg in a
## roof or plinth.
static func _clipped_dome(semi_axes: Vector3, colour: Color, epsilon: float) -> MeshInstance3D:
	var dome := MeshInstance3D.new()
	dome.mesh = SuperEgg.build_clipped_mesh(semi_axes, [Plane(Vector3.DOWN, 0.0)], epsilon, epsilon, 36, 28)
	var material := SolidModel.material(colour, 0.03, 0.02)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	dome.material_override = material
	return dome


static func _ring(body: StaticBody3D, at: Vector3, radius: float) -> void:
	for i in 20:
		var a := TAU * float(i) / 20.0
		var b := TAU * float(i + 1) / 20.0
		CalderaShell._beam(body, at + Vector3(cos(a) * radius, 0, sin(a) * radius), at + Vector3(cos(b) * radius, 0, sin(b) * radius), Vector2(0.045, 0.045), CalderaShell.STEEL_BLUED)


static func _ellipse_ring(body: StaticBody3D, at: Vector3, radii: Vector2) -> void:
	for i in 28:
		var a := TAU * float(i) / 28.0
		var b := TAU * float(i + 1) / 28.0
		CalderaShell._beam(body, at + Vector3(cos(a) * radii.x, 0, sin(a) * radii.y), at + Vector3(cos(b) * radii.x, 0, sin(b) * radii.y), Vector2(0.055, 0.055), CalderaShell.STEEL_BLUED)


static func _instruments(upper: StaticBody3D) -> void:
	for i in 5:
		var x := -0.8 + 1.15 * float(i)
		CalderaFurniture.piece(upper, Vector3(0.30, 0.65, 0.24), CalderaShell.VOLCANIC_STONE, Vector3(x, 0.65, -4.7), 0.0, true, 6.0)
		CalderaShell._metal(upper, Vector3(x, 1.45, -4.7), Vector3(0.04, 0.35, 0.04), CalderaShell.STAINLESS, false)
	FireCalderaBuildings._marker(upper, "SelkaInstrumentMarker", Vector3(1.5, 0.0, -2.5), 0.0)


static func _observation_landing(body: StaticBody3D) -> void:
	# This is the dry surface threshold for the future lower-city descent.  It
	# projects from the reservoir facade and is already aligned to the council;
	# the submerged L2 continuation can attach without cutting through it.
	CalderaShell.soft_slab(body, "LowerObservationThreshold", Vector3(0.0, -0.10, -8.45), Vector3(3.2, 0.10, 0.95), Vector2(3.2, 0.95), FLOOR)
	FireCalderaBuildings._marker(body, "LowerObservationMarker", Vector3(0.0, 0.0, -8.5), 0.0)


static func _lights(body: StaticBody3D) -> void:
	for at: Vector3 in [Vector3(-8.0, 5.8, 3.6), Vector3(8.0, 5.8, 3.6), Vector3(-8.0, 5.8, -3.6), Vector3(8.0, 5.8, -3.6)]:
		CalderaFurniture.concealed_light(body, at, CalderaFurniture.LED_WARM, 0.8, 6.0)
