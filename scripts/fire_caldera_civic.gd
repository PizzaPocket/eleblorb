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
	_glazed_eaves_and_portals(body)
	_switchback_ramp(body)
	_upper_shell(body)
	_council(body)
	_school_and_archive(body)
	_terrarium(body)
	_daylight_canopy(body)
	_stained_glass_baffles(body)
	_observation_landing(body)
	_lights(body)
	_register_public_routes(body)
	return body


## A symmetrical, mostly glazed facade around the civic portal. The matching
## rear opening keeps the terrarium on the public axis between Highline and
## reservoir outlook.
static func _court_enclosure(body: StaticBody3D) -> void:
	# Curtain walls rise to the steel eaves ring. The old 25 cm reveal read as
	# an accidental open slot under the canopy from inside the hall.
	var glass_top := HALL + 0.18
	for z: float in [-7.5, 7.5]:
		var front := z > 0.0
		var portal_height := 6.7 if front else 5.2
		_portal_frame(body, Vector3(0.0, 0.0, z), portal_height, "CivicEntryPortal" if front else "CivicOutlookPortal")
		for side: float in [-1.0, 1.0]:
			var x := side * 7.30
			# Side lights begin at the portal jamb and continue to the corner pier,
			# so the entry arch and curtain wall meet on one clean line.
			CalderaShell._pane(body, "CivicFacadeGlass", Vector3(x, glass_top * 0.5, z), Vector2(4.65, glass_top * 0.5 - 0.08), 0.0, Color(CalderaShell.CLEAR_GLASS, 0.23))
			# One fine mullion divides each broad glass bay at its midpoint.
			CalderaShell._metal(body, Vector3(side * 7.30, glass_top * 0.5, z), Vector3(0.10, glass_top, 0.10), CalderaShell.STEEL_BLUED, true)
	for x: float in [-12.0, 12.0]:
		CalderaShell._pane(body, "CivicSideGlass", Vector3(x, glass_top * 0.5, 0.0), Vector2(7.25, glass_top * 0.5 - 0.08), PI * 0.5, Color(CalderaShell.SMOKY_GLASS, 0.22))
	# The monumental portals remain open arches. Surface-mounted sliders belong
	# to the smaller gallery partitions, where their leaves fit the openings.
	for direction: Vector2 in [Vector2(0, 1), Vector2(0, -1)]:
		ClearZones.add(body, "civic outlook portal", "door", Vector2(0.0, -7.5), direction, 1.0, 1.0, PORTAL_CLEAR * 0.5, 0.05, 2.1)
	# Four corner Y-piers align with the curtain-wall corners; the portal remains
	# visually quiet and its arch is the only frame around the public entry.
	for at: Vector3 in [Vector3(-11.82, 0, 7.32), Vector3(11.82, 0, 7.32), Vector3(-11.82, 0, -7.32), Vector3(11.82, 0, -7.32)]:
		_branching_pier(body, at)


static func _portal_frame(body: StaticBody3D, at: Vector3, height: float, label: String) -> void:
	# Sink the pipe ends below the walking plane. The broad radius belongs to
	# the portal itself; a second ring only thickened and cluttered its silhouette.
	var outline := OpeningTrim.door_arch(PORTAL_CLEAR * 0.5, height, TownProps.OPENING_EXPONENT, 0.9, 0.28)
	var outer := OpeningTrim.piped_frame(outline, 0.11, CalderaShell.STEEL_BLUED, false, Vector2(0.0, height * 0.45))
	outer.name = label
	outer.position = at
	body.add_child(outer)


## Complete each curtain-wall bay up to the sloped canopy and glaze the
## superellipse-shaped fanlight above both open portals. The door apertures
## remain true voids; no rectangular pane crosses their curved heads.
static func _glazed_eaves_and_portals(body: StaticBody3D) -> void:
	var glass_bottom := HALL + 0.10
	for z: float in [-7.5, 7.5]:
		for span: Vector2 in [Vector2(-11.95, -PORTAL_CLEAR * 0.5), Vector2(PORTAL_CLEAR * 0.5, 11.95)]:
			_glass_eave_strip(body, "CivicFacadeEave", span.x, span.y, z, true,
				func(_value: float) -> float: return glass_bottom,
				func(value: float) -> float: return _canopy_height(value, z))
		var portal_height := 6.7 if z > 0.0 else 5.2
		var arch_half := (portal_height + 0.9) * 0.5
		var arch_centre := portal_height - arch_half
		_glass_eave_strip(body, "CivicPortalFanlight", -PORTAL_CLEAR * 0.5, PORTAL_CLEAR * 0.5, z, true,
			func(value: float) -> float:
				var ratio := clampf(absf(value) / (PORTAL_CLEAR * 0.5), 0.0, 1.0)
				return arch_centre + arch_half * pow(maxf(0.0, 1.0 - pow(ratio, TownProps.OPENING_EXPONENT)), 1.0 / TownProps.OPENING_EXPONENT),
			func(value: float) -> float: return _canopy_height(value, z))
	for x: float in [-12.0, 12.0]:
		_glass_eave_strip(body, "CivicSideEave", -7.25, 7.25, x, false,
			func(_value: float) -> float: return glass_bottom,
			func(value: float) -> float: return _canopy_height(x, value))


static func _glass_eave_strip(body: StaticBody3D, label: String, start: float, finish: float, fixed: float, along_x: bool, lower: Callable, upper: Callable) -> void:
	const SEGMENTS := 32
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in SEGMENTS:
		var a := lerpf(start, finish, float(i) / float(SEGMENTS))
		var b := lerpf(start, finish, float(i + 1) / float(SEGMENTS))
		var pa := Vector3(a, lower.call(a), fixed) if along_x else Vector3(fixed, lower.call(a), a)
		var pb := Vector3(b, lower.call(b), fixed) if along_x else Vector3(fixed, lower.call(b), b)
		var qa := Vector3(a, upper.call(a), fixed) if along_x else Vector3(fixed, upper.call(a), a)
		var qb := Vector3(b, upper.call(b), fixed) if along_x else Vector3(fixed, upper.call(b), b)
		var normal := Vector3.FORWARD if along_x else Vector3.RIGHT
		_civic_quad(st, faces, pa, pb, qb, qa, normal)
	var pane := MeshInstance3D.new()
	pane.name = label
	pane.mesh = st.commit()
	pane.material_override = SolidModel.material(Color(CalderaShell.CLEAR_GLASS, 0.23), 0.12, 0.02)
	body.add_child(pane)
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	body.add_child(collision)


static func _civic_quad(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(normal)
		st.add_vertex(point)
		faces.append(point)


static func _branching_pier(body: StaticBody3D, at: Vector3) -> void:
	var roof_at := _canopy_height(at.x, at.z)
	# A broad SuperEgg shaft fills the true glass-wall corner. The small collar
	# capital receives the two saddle ribs without a floating Y fork or exposed
	# gap between the glazed elevations.
	var shaft := SuperEgg.build_part(Vector3(0.24, (roof_at - 0.34) * 0.5, 0.24), CalderaShell.STEEL_BLUED, 5.5, 5.5)
	shaft.position = Vector3(at.x, (roof_at - 0.34) * 0.5, at.z)
	body.add_child(shaft)
	CollisionPolicy.add_box(body, shaft, Vector3(0.42, roof_at - 0.34, 0.42), shaft.position, Basis(), false)
	var side := signf(at.x)
	var capital := SuperEgg.build_part(Vector3(0.38, 0.16, 0.38), CalderaShell.STEEL_BLUED, 5.5, 5.5)
	capital.position = Vector3(at.x, roof_at - 0.42, at.z)
	body.add_child(capital)
	CollisionPolicy.add_box(body, capital, Vector3(0.76, 0.32, 0.76), capital.position, Basis(), false)
	var bearing := Vector3(at.x, roof_at - 0.18, at.z)
	for direction: Vector3 in [Vector3(-side, 0.0, 0.0), Vector3(0.0, 0.0, signf(at.z))]:
		var end := at + direction * 0.82
		CalderaShell._beam(body, bearing, Vector3(end.x, _canopy_height(end.x, end.z) - 0.10, end.z), Vector2(0.16, 0.16), CalderaShell.STEEL_BLUED)


static func _canopy_height(x: float, z: float) -> float:
	return 9.00 + 1.05 * pow(absf(x) / 12.65, 1.45) + 0.55 * (z / 8.15)


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
			_sliding_door(body, origin, yaw, float(door["width"]), 2.75, true)
		var point := Vector2(float(door["at"]), fixed) if along_x else Vector2(fixed, float(door["at"]))
		var normal := Vector2(0, 1) if along_x else Vector2(1, 0)
		for direction: Vector2 in [normal, -normal]:
			ClearZones.add(body, str(door["label"]), "door", point, direction, 0.0, 1.0, float(door["width"]) * 0.5, base + 0.05, base + 1.95)
		cursor = b
	_partition(body, cursor, hi, fixed, along_x, base, height)


static func _sliding_door(body: StaticBody3D, origin: Vector3, yaw: float, clear: float, height: float, initially_open: bool) -> void:
	var slider := WorldSlidingDoor.new()
	slider.name = "CivicSlidingDoor"
	slider.position = origin
	body.add_child(slider)
	slider.configure(clear, height, yaw, initially_open, true)


static func _partition(body: StaticBody3D, lo: float, hi: float, fixed: float, along_x: bool, base: float, height: float) -> void:
	if hi - lo < 0.05:
		return
	var size := Vector3(hi - lo, height, 0.18) if along_x else Vector3(0.18, height, hi - lo)
	var at := Vector3((lo + hi) * 0.5, base + height * 0.5, fixed) if along_x else Vector3(fixed, base + height * 0.5, (lo + hi) * 0.5)
	FireCalderaOren._block(body, "CivicPartition", at, size, PARTITION)


static func _switchback_ramp(body: StaticBody3D) -> void:
	# Two even 2 m flights, joined by a broad half-turn. The terminal meets the
	# rear edge of a real west observation mezzanine; no exposed ramp ends in
	# front of the canopy or blocks the rear civic portal.
	var path := PackedVector3Array()
	const FLIGHT_X0 := -10.8
	const FLIGHT_X1 := -6.8
	const FLIGHT_Z0 := 5.8
	const FLIGHT_Z1 := -4.0
	const TURN_Z := -5.2
	const TURN_R := 2.0
	const LOW_Y := 0.05
	const MID_Y := 2.0
	const HIGH_Y := 4.0
	for i in 25:
		var t := float(i) / 24.0
		path.append(Vector3(FLIGHT_X0, lerpf(LOW_Y, MID_Y, t), lerpf(FLIGHT_Z0, FLIGHT_Z1, t)))
	for i in range(1, 5):
		path.append(Vector3(FLIGHT_X0, MID_Y, lerpf(FLIGHT_Z1, TURN_Z, float(i) / 4.0)))
	var turn_centre_x := (FLIGHT_X0 + FLIGHT_X1) * 0.5
	for i in range(1, 33):
		var angle := PI + PI * float(i) / 32.0
		path.append(Vector3(turn_centre_x + TURN_R * cos(angle), MID_Y, TURN_Z + TURN_R * sin(angle)))
	for i in range(1, 5):
		path.append(Vector3(FLIGHT_X1, MID_Y, lerpf(TURN_Z, FLIGHT_Z1, float(i) / 4.0)))
	for i in range(1, 25):
		var t := float(i) / 24.0
		path.append(Vector3(FLIGHT_X1, lerpf(MID_Y, HIGH_Y, t), lerpf(FLIGHT_Z1, 2.2, t)))
	FireCalderaHighline._build_glass_path(body, path, 2.4, "CivicAccessibleGallery", "glass")
	var lane: Array[Vector3] = []
	for point: Vector3 in path:
		lane.append(point)
	ClearZones.add_lane(body, "civic glass ramp", lane, 0.58)
	ClearZones.add_lane(body, "civic ramp forecourt", [Vector3(0.0, 0.05, 6.8), Vector3(-9.0, 0.05, 6.8), Vector3(FLIGHT_X0, LOW_Y, FLIGHT_Z0)], 0.58)


static func _guard(body: StaticBody3D, from: Vector3, to: Vector3) -> void:
	var member := CalderaShell._beam(body, from, to, Vector2(0.10, 0.10), CalderaShell.STAINLESS)
	var delta := to - from
	var basis := member.transform.basis.orthonormalized()
	CollisionPolicy.add_box(body, member, Vector3(delta.length(), 0.14, 0.14), (from + to) * 0.5, basis, false)


static func _upper_shell(body: StaticBody3D) -> void:
	# A full second-storey ring of public galleries surrounds the central
	# terrarium court. The four floor plates meet edge-to-edge; the open centre
	# keeps the dome visible from both levels. The north and south bridges stop
	# short of the monumental portals below.
	var floor_bays: Array[Dictionary] = [
		{"name": "CivicUpperWestGallery", "centre": Vector3(-8.7, UPPER - 0.11, 0.0), "size": Vector3(6.6, 0.22, 11.4)},
		{"name": "CivicUpperEastGallery", "centre": Vector3(8.7, UPPER - 0.11, 0.0), "size": Vector3(6.6, 0.22, 11.4)},
		{"name": "CivicUpperNorthGallery", "centre": Vector3(0.0, UPPER - 0.11, -4.7), "size": Vector3(10.8, 0.22, 2.0)},
		{"name": "CivicUpperSouthGallery", "centre": Vector3(0.0, UPPER - 0.11, 4.7), "size": Vector3(10.8, 0.22, 2.0)},
	]
	for bay: Dictionary in floor_bays:
		var slab := BoxMesh.new()
		slab.size = bay["size"]
		var gallery := MeshInstance3D.new()
		gallery.name = bay["name"]
		gallery.mesh = slab
		gallery.position = bay["centre"]
		gallery.material_override = SolidModel.material(FLOOR.lightened(0.05), 0.44, 0.08)
		body.add_child(gallery)
		CollisionPolicy.add_box(body, gallery, slab.size, gallery.position, Basis(), true)
	# Slender supports align with the facade piers and the four inner corners of
	# the gallery bridges, so the new floor reads as a carried structure.
	for at: Vector2 in [
		Vector2(-11.7, -5.3), Vector2(-11.7, 0.0), Vector2(-11.7, 5.3),
		Vector2(11.7, -5.3), Vector2(11.7, 0.0), Vector2(11.7, 5.3),
		Vector2(-5.25, -5.3), Vector2(5.25, -5.3),
		Vector2(-5.25, 5.3), Vector2(5.25, 5.3),
	]:
		var post := SuperEgg.build_part(Vector3(0.13, (UPPER - 0.22) * 0.5, 0.13), CalderaShell.STEEL_BLUED, 5.5, 5.5)
		post.position = Vector3(at.x, (UPPER - 0.22) * 0.5, at.y)
		body.add_child(post)
		CollisionPolicy.add_box(body, post, Vector3(0.28, UPPER - 0.22, 0.28), post.position, Basis(), false)
	# The atrium edge uses the same glass cassette and handrail as the Highline.
	# Its west-side opening is centred on the civic ramp's second-storey arrival.
	var inner_edges: Array[Array] = [
		[Vector3(-5.4, UPPER, -3.7), Vector3(-5.4, UPPER, 0.85)],
		[Vector3(-5.4, UPPER, 3.25), Vector3(-5.4, UPPER, 3.7)],
		[Vector3(5.4, UPPER, -3.7), Vector3(5.4, UPPER, 3.7)],
		[Vector3(-5.4, UPPER, -3.7), Vector3(5.4, UPPER, -3.7)],
		[Vector3(-5.4, UPPER, 3.7), Vector3(5.4, UPPER, 3.7)],
		[Vector3(-5.4, UPPER, -5.7), Vector3(5.4, UPPER, -5.7)],
		[Vector3(-5.4, UPPER, 5.7), Vector3(5.4, UPPER, 5.7)],
	]
	for edge: Array in inner_edges:
		var a: Vector3 = edge[0]
		var b: Vector3 = edge[1]
		FireCalderaHighline._path_guard(body, a, b, Vector3.UP)
		FireCalderaHighline._tube(body, PackedVector3Array([a + Vector3.UP * 1.09, b + Vector3.UP * 1.09]), 0.08, FireCalderaHighline.STEEL, "CivicUpperGalleryHandrail")
	FireCalderaBuildings._marker(body, "SelkaInstrumentMarker", Vector3(-8.25, UPPER, 4.4), 0.0)


static func _council(body: StaticBody3D) -> void:
	# Five mineral-teal chairs occupy the west council porch, facing the speaker
	# and leaving the forecourt route clear.
	for i in 5:
		var z := lerpf(1.65, 4.05, float(i) / 4.0)
		var x := -7.65 - 0.45 * cos(lerpf(-PI * 0.5, PI * 0.5, float(i) / 4.0))
		CalderaFurniture.chair(body, Vector3(x, 0.0, z), -PI * 0.5, Color(0.14, 0.36, 0.39))
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
		_sliding_door(body, origin, yaw, float(opening["width"]), 2.75, true)
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
	# The clamped, closed dome is also the terrarium's physical enclosure. Its
	# collision comes from this very mesh so the visible glass cannot be entered.
	var glass_body := StaticBody3D.new()
	glass_body.name = "CivicTerrariumGlassBarrier"
	glass_body.collision_layer = 1
	glass_body.collision_mask = 0
	glass_body.position = shell.position
	body.add_child(glass_body)
	var glass_collision := CollisionShape3D.new()
	glass_collision.name = "TerrariumDomeCollision"
	glass_collision.shape = shell.mesh.create_trimesh_shape()
	glass_collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	glass_body.add_child(glass_collision)
	CollisionPolicy.mark_decorative(shell)
	var soil := SuperEgg.build_part(Vector3(TERRARIUM_HALF.x - 0.35, 0.26, TERRARIUM_HALF.y - 0.35), Color(0.12, 0.34, 0.16), 4.0, 4.0)
	soil.name = "TerrariumGrassFloor"
	soil.position = centre + Vector3(0.0, 0.58, 0.0)
	body.add_child(soil)
	CollisionPolicy.mark_decorative(soil)
	var tree := NatureProps.build_round_tree(5.1, Color(0.05, 0.55, 0.16))
	tree.name = "TerrariumLivingTree"
	tree.position = centre + Vector3(0.0, 0.72, 0.0)
	tree.scale = Vector3.ONE * 0.92
	body.add_child(tree)
	# A sheltered microclimate holds a small, deliberately varied collection:
	# one canopy tree, two understory trees, flowering shrubs, and ground cover.
	var understory := NatureProps.build_pine_tree(2.8, Color(0.05, 0.55, 0.16))
	understory.name = "TerrariumPineUnderstory"
	understory.position = centre + Vector3(-2.45, 0.72, 1.25)
	understory.rotation.y = 0.62
	understory.scale = Vector3(0.84, 0.92, 0.72)
	body.add_child(understory)
	var rounded_tree := NatureProps.build_round_tree(2.4, Color(0.10, 0.62, 0.28))
	rounded_tree.name = "TerrariumBroadleafUnderstory"
	rounded_tree.position = centre + Vector3(2.35, 0.72, -1.25)
	rounded_tree.rotation.y = -0.9
	rounded_tree.scale = Vector3(0.72, 0.78, 0.94)
	body.add_child(rounded_tree)
	for i in 12:
		var angle := TAU * float(i) / 12.0
		var radius_x := 3.55 if i % 2 == 0 else 3.15
		var radius_z := 2.72 if i % 2 == 0 else 2.35
		var at := centre + Vector3(cos(angle) * radius_x, 0.86, sin(angle) * radius_z)
		var bush := NatureProps.build_bush([Color(0.04, 0.48, 0.24), Color(0.12, 0.66, 0.40), Color(0.16, 0.55, 0.58)][i % 3])
		bush.name = "TerrariumFloweringUnderstory"
		bush.position = at
		bush.scale = Vector3.ONE * (1.3 if i % 3 == 0 else 1.0)
		body.add_child(bush)
		if i % 2 == 0:
			var flower := NatureProps.build_flower([Color(0.95, 0.52, 0.16), Color(0.26, 0.58, 0.88), Color(0.90, 0.33, 0.54)][i % 3])
			flower.name = "TerrariumFlower"
			flower.position = at + Vector3(0.28, 0.04, -0.16)
			body.add_child(flower)
	for i in 20:
		var angle := TAU * float(i) / 20.0
		var grass := NatureProps.build_grass_tuft([Color(0.12, 0.63, 0.30), Color(0.24, 0.72, 0.38)][i % 2])
		grass.name = "TerrariumGroundcover"
		grass.position = centre + Vector3(cos(angle) * 3.7, 0.72, sin(angle) * 2.85)
		body.add_child(grass)
	# A single fine mineral sill seals the dome base; random braces and suspended
	# coloured shards are removed so the glass shell and plants read clearly.
	_ellipse_ring(body, centre + Vector3(0.0, 0.58, 0.0), TERRARIUM_HALF + Vector2(0.06, 0.06))
	# Two fine ring courses make the conservatory read as a deliberate lantern
	# with replaceable glazing bays, rather than a bare bubble in the hall.
	_ellipse_ring(body, centre + Vector3(0.0, 1.35, 0.0), TERRARIUM_HALF * 0.93)
	_ellipse_ring(body, centre + Vector3(0.0, 2.45, 0.0), TERRARIUM_HALF * 0.72)


## One continuous translucent butterfly surface. The long central valley falls
## toward the rear, so the roof never repeats the inn's dome and never ponds
## over the entrance. Clear panes keep the terrarium and civic hall legible.
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
	# A closed eaves ring follows the roof surface and meets the corner Y-piers.
	# Both transverse sides share the canopy's saddle profile.
	for z: float in [-7.5, 7.5]:
		for segment in 20:
			var x0 := lerpf(-12.0, 12.0, float(segment) / 20.0)
			var x1 := lerpf(-12.0, 12.0, float(segment + 1) / 20.0)
			CalderaShell._beam(body, Vector3(x0, roof_y.call(x0, z) - 0.12, z), Vector3(x1, roof_y.call(x1, z) - 0.12, z), Vector2(0.18, 0.18), CalderaShell.STEEL_BLUED)
	for side: float in [-1.0, 1.0]:
		for segment in 16:
			var z0 := lerpf(-7.5, 7.5, float(segment) / 16.0)
			var z1 := lerpf(-7.5, 7.5, float(segment + 1) / 16.0)
			CalderaShell._beam(body, Vector3(side * 12.0, roof_y.call(side * 12.0, z0) - 0.12, z0), Vector3(side * 12.0, roof_y.call(side * 12.0, z1) - 0.12, z1), Vector2(0.18, 0.18), CalderaShell.STEEL_BLUED)
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


## The Austin-library reference is translated into a restrained lantern of
## coloured glass below the canopy. Three framed panels hang behind the court,
## clear of both portals and the terrarium enclosure; they tint daylight
## without becoming loose shards or blocking the gallery.
static func _stained_glass_baffles(body: StaticBody3D) -> void:
	var panels := [
		{"x": -4.9, "z": -4.6, "w": 1.55, "h": 2.45, "c": Color(0.18, 0.43, 0.88, 0.62)},
		{"x": 0.0, "z": -4.6, "w": 1.85, "h": 2.9, "c": Color(0.96, 0.47, 0.16, 0.62)},
		{"x": 4.9, "z": -4.6, "w": 1.55, "h": 2.45, "c": Color(0.10, 0.66, 0.56, 0.62)},
	]
	for i in panels.size():
		var panel: Dictionary = panels[i]
		var width := float(panel["w"])
		var height := float(panel["h"])
		var colour: Color = panel["c"]
		var y := 8.2 - height * 0.5
		var pane := BoxMesh.new()
		pane.size = Vector3(width, height, 0.06)
		var glass := MeshInstance3D.new()
		glass.name = "CivicAustinGlassBaffle%d" % i
		glass.mesh = pane
		glass.position = Vector3(float(panel["x"]), y, float(panel["z"]))
		glass.material_override = SolidModel.material(colour, 0.08, 0.04)
		body.add_child(glass)
		CollisionPolicy.mark_decorative(glass)
		for side: float in [-1.0, 1.0]:
			CalderaShell._beam(body,
				Vector3(float(panel["x"]) + side * width * 0.5, y - height * 0.5, float(panel["z"])),
				Vector3(float(panel["x"]) + side * width * 0.5, y + height * 0.5, float(panel["z"])),
				Vector2(0.055, 0.055), CalderaShell.STEEL_BLUED)
		CalderaShell._beam(body,
			Vector3(float(panel["x"]) - width * 0.5, y, float(panel["z"])),
			Vector3(float(panel["x"]) + width * 0.5, y, float(panel["z"])),
			Vector2(0.045, 0.045), CalderaShell.STEEL_BLUED)


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
