class_name FireCalderaNahl
extends RefCounted

## The Nahl tempering hall and Eris's suite (fire_caldera_buildings.md,
## section 3), the second building of the caldera kit and the first for lava
## bodies. Two volumes in one body, on its socket plinth:
##   - the tempering hall, 10 x 12 m, the kit's full glass bays and stained
##     band, under a roof raked from the back wall up toward the promenade, the
##     wedge between the level band and the roof filled with clear glass, so
##     the hall opens into a tall clerestory over the reservoir;
##   - a 6 m wing at the ring beam's height (3.8 m) on its +X side: Eris's
##     suite at the front, with its own door at the east end where R3 meets
##     the promenade, and the mediation room behind it, its conversation pit
##     dug into the plinth on the uphill side and lit by one cobalt dome.
## Local +Z faces the promenade (the reservoir); the plot rises toward -Z.
## A visitor never passes the treatment rooms to reach Eris.
##
## The colour rule is the guest house's: amber is warmth, cobalt is cooling.
## The hall, where cooled and cracked residents are warmed, is amber; the
## mediation room, where tempers cool, is cobalt; Eris's own rooms are amber.
## Light here is heat first: the molten floor, the radiant platforms' seams and
## two glass-enclosed flames, over the kit's concealed cove lines.

const HALL_SIZE := Vector2(10.0, 12.0)
const HALL_CENTRE := Vector2(-3.0, 0.0)
const WING_SIZE := Vector2(6.0, 12.0)
const WING_CENTRE := Vector2(5.0, 0.0)
## The hall roof's rise from its back wall head to its front.
const HALL_RAKE := 2.4
const COBALT := FireCalderaBuildings.COBALT
const AMBER := FireCalderaBuildings.AMBER
const C := 0
const A := 1
const STAINED: Array[Color] = [COBALT, AMBER]
## The party wall between hall and wing.
const PARTY_X := 2.0
## The wall between the suite (in front) and the mediation room (behind).
const SUITE_BACK_Z := -1.0
const STAFF_DOOR_Z := 4.6
const MEDIATION_DOOR_Z := -3.5
const SUITE_DOOR_X := 6.7
const INNER_DOOR_WIDTH := FireCalderaBuildings.INNER_DOOR_WIDTH
const INNER_DOOR_HEIGHT := FireCalderaBuildings.INNER_DOOR_HEIGHT
const PARTITION_SOLID := FireCalderaBuildings.PARTITION_SOLID
## The molten-floor bay in the hall's west back corner.
const MOLTEN_BAY := Rect2(Vector2(-7.75, -5.75), Vector2(3.15, 5.25))
const MOLTEN_Y := 0.03
const MOLTEN := Color(1.0, 0.42, 0.08)
## Eris's immersion well, in the suite's west half.
const WELL_CENTRE := Vector2(3.6, 1.2)
const WELL_HALF := Vector2(1.15, 0.95)
const COOL_LEDGE := Color(0.40, 0.38, 0.37)


static func spec_hall() -> Dictionary:
	var smoky := CalderaShell.SMOKY_GLASS
	return {
		"size": HALL_SIZE, "offset": HALL_CENTRE, "stained": STAINED,
		"rake": HALL_RAKE,
		"walls": {
			"front": [
				{"to": 1.85, "kind": "glass", "tint": smoky, "band": A}, {"to": 3.7, "kind": "glass", "tint": smoky, "band": A},
				{"to": 6.3, "kind": "door", "band": A, "label": "hall door"},
				{"to": 8.15, "kind": "glass", "tint": smoky, "band": A}, {"to": 10.0, "kind": "glass", "tint": smoky, "band": A},
			],
			# Heat walls behind the molten bay and the platforms, one long pane
			# between them onto the slope.
			"back": [
				{"to": 3.5, "kind": "stone", "band": A}, {"to": 6.5, "kind": "glass", "tint": smoky, "band": A},
				{"to": 10.0, "kind": "stone", "band": A},
			],
			"west": [
				{"to": 6.0, "kind": "stone", "band": A}, {"to": 9.0, "kind": "glass", "tint": smoky, "band": A},
				{"to": 12.0, "kind": "stone", "band": A},
			],
			# The party wall is the wing's; above the wing's roof the hall's
			# clerestory wedge runs on.
			"east": [
				{"to": 3.0, "kind": "open"}, {"to": 6.0, "kind": "open"}, {"to": 9.0, "kind": "open"}, {"to": 12.0, "kind": "open"},
			],
		},
	}


static func spec_wing() -> Dictionary:
	var smoky := CalderaShell.SMOKY_GLASS
	return {
		"size": WING_SIZE, "offset": WING_CENTRE, "stained": STAINED,
		"overhang": {"west": 0.0},
		# One cobalt dome over the conversation pit (wing-local).
		"skylights": [{"name": "Mediation", "at": Vector2(0.1, -3.5), "half": Vector2(2.2, 1.9), "rise": 0.8, "tint": Color(0.30, 0.45, 0.88, 0.40)}],
		"walls": {
			# The suite's window onto the reservoir, then its own door at the
			# east end, nearest R3.
			"front": [
				{"to": 1.7, "kind": "glass", "band": A}, {"to": 3.4, "kind": "stone", "band": A},
				{"to": 6.0, "kind": "door", "band": A, "label": "suite door"},
			],
			# Uphill: the mediation room is closed to the slope.
			"back": [
				{"to": 3.0, "kind": "stone", "band": C}, {"to": 6.0, "kind": "stone", "band": C},
			],
			# Back to front: the mediation room, then the suite, glazed by its
			# door.
			"east": [
				{"to": 2.5, "kind": "stone", "band": C}, {"to": 5.0, "kind": "stone", "band": C},
				{"to": 9.4, "kind": "stone", "band": A}, {"to": 12.0, "kind": "glass", "tint": smoky, "band": A},
			],
		},
	}


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), spec_hall())
	CalderaShell.add_volume(body, spec_wing())
	_partitions(body)
	_molten_bay(body)
	_platforms(body)
	_hall_fittings(body)
	_mediation_room(body)
	_suite(body)
	return body


## The molten surfaces in the body's plan, for the terrain's lava queries:
## [{"polygon": PackedVector2Array, "y": float}], local.
static func lava_surfaces() -> Array[Dictionary]:
	var bay := PackedVector2Array([MOLTEN_BAY.position, Vector2(MOLTEN_BAY.end.x, MOLTEN_BAY.position.y), MOLTEN_BAY.end, Vector2(MOLTEN_BAY.position.x, MOLTEN_BAY.end.y)])
	var well := PackedVector2Array()
	for i in 24:
		var angle := TAU * float(i) / 24.0
		well.append(WELL_CENTRE + Vector2(cos(angle) * WELL_HALF.x * 0.9, sin(angle) * WELL_HALF.y * 0.9))
	return [{"polygon": bay, "y": MOLTEN_Y}, {"polygon": well, "y": 0.04}]


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


## The party wall: stone to 3.0 m with the staff door into the suite and the
## mediation door, a band in each side's colour to the wing's roof; the wall
## between the suite and the mediation room, stone with no door.
static func _partitions(body: StaticBody3D) -> void:
	var front := WING_SIZE.y * 0.5
	var back := -front
	var doors := [[MEDIATION_DOOR_Z, "mediation door"], [STAFF_DOOR_Z, "staff door"]]
	var cursor := back
	for door: Array in doors:
		var z: float = door[0]
		var south := z - INNER_DOOR_WIDTH * 0.5 - 0.35
		var north := minf(z + INNER_DOOR_WIDTH * 0.5 + 0.35, front)
		FireCalderaBuildings._slab(body, (cursor + south) * 0.5, south - cursor, PARTY_X, false, 0.0, PARTITION_SOLID, FireCalderaBuildings.BASALT_PARTITION)
		CalderaShell.door_opening(body, Vector3(PARTY_X, 0.0, (south + north) * 0.5), PI * 0.5, north - south, PARTITION_SOLID, 0.18, INNER_DOOR_WIDTH, INNER_DOOR_HEIGHT, 1, FireCalderaBuildings.BASALT_PARTITION)
		for direction: Vector2 in [Vector2(1, 0), Vector2(-1, 0)]:
			ClearZones.add(body, str(door[1]), "door", Vector2(PARTY_X, z), direction, 0.0, 1.0, INNER_DOOR_WIDTH * 0.5, 0.05, 1.9)
		cursor = north
	if front - cursor > 0.05:
		FireCalderaBuildings._slab(body, (cursor + front) * 0.5, front - cursor, PARTY_X, false, 0.0, PARTITION_SOLID, FireCalderaBuildings.BASALT_PARTITION)
	FireCalderaBuildings._band(body, back, SUITE_BACK_Z, PARTY_X, false, COBALT)
	FireCalderaBuildings._band(body, SUITE_BACK_Z, front, PARTY_X, false, AMBER)
	FireCalderaBuildings._slab(body, WING_CENTRE.x, WING_SIZE.x, SUITE_BACK_Z, true, 0.0, PARTITION_SOLID, FireCalderaBuildings.BASALT_PARTITION)
	FireCalderaBuildings._band(body, PARTY_X, PARTY_X + WING_SIZE.x, SUITE_BACK_Z, true, AMBER)


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


static func _branch(body: StaticBody3D, root: Vector3, tip: Vector3) -> void:
	var delta := tip - root
	var part := SuperEgg.build_part(Vector3(0.022, delta.length() * 0.5 + 0.02, 0.022), CalderaShell.STEEL_BLUED, 6.0, 6.0)
	part.material_override = SolidModel.material(CalderaShell.STEEL_BLUED, 0.3, 0.85)
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
		# The control: a stainless dial on a short post at the head.
		CalderaShell._metal(body, Vector3(x + 0.4, 0.45, -5.75), Vector3(0.06, 0.9, 0.06), CalderaShell.STAINLESS_SHADOW, false)
		var dial := CalderaFurniture.piece(body, Vector3(0.07, 0.07, 0.02), CalderaShell.STAINLESS, Vector3(x + 0.4, 0.92, -5.72), 0.0, false, 2.0)
		dial.material_override = SolidModel.material(CalderaShell.STAINLESS, 0.15, 0.95)
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
		CalderaFurniture.piece(b, Vector3(0.06, 0.05, 0.06), minerals[(i * 3) % minerals.size()], p + Vector3(0, 0.05, 0), float(i) * 0.7, false, 2.6))
	CalderaFurniture.bench(body, Vector3(-0.2, 0.0, 3.2), 0.0, 2.2)
	for x: float in [-4.6, -1.4]:
		CalderaFurniture.flame_capsule(body, Vector3(x, 0.0, 5.55))


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
		var seat := CalderaFurniture.piece(body, Vector3(0.3, (seat_top - 0.06 + depth) * 0.5, 0.24), CalderaShell.BASALT.lightened(0.06), Vector3(p.x, -depth + (seat_top - 0.06 + depth) * 0.5, p.y), yaw, true, 5.0)
		seat.name = "PitBench"
		# A silica-cloth cushion, the one textile a lava body can sit on.
		CalderaFurniture.piece(body, Vector3(0.28, 0.04, 0.22), CalderaFurniture.SILICA, Vector3(p.x, seat_top - 0.04, p.y), yaw, false, SuperEgg.EPSILON_SOFT)
	# The step down, at the door end.
	var step := at + Vector2(-half.x + 0.3, 0.0)
	CalderaFurniture.piece(body, Vector3(0.28, (depth * 0.5) * 0.5, 0.45), CalderaShell.BASALT.lightened(0.06), Vector3(step.x, -depth + depth * 0.25, step.y), 0.0, true, 5.0)
	FireCalderaBuildings._glow(body, "PitSeam", Vector3(0.9, 0.01, 0.5), Vector3(at.x, -depth + 0.012, at.y), Color(1.0, 0.45, 0.10))
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
	CalderaFurniture.concealed_light(body, Vector3(at.x, 2.9, at.y), CalderaFurniture.LED_WARM.lerp(CalderaFurniture.LED_COOL, 0.5), 0.6, 5.0)


## Eris's suite: her own door from the promenade's east end into an entry, a
## receiving and shaping room with a tall obsidian glass to shape her
## silhouette by, a private immersion well, a cooler resting niche in the back
## corner, and along the east wall her shelf of objects from seventy years.
static func _suite(body: StaticBody3D) -> void:
	# Entry: a basalt ledge to set things on, by the door.
	CalderaFurniture.piece(body, Vector3(0.2, 0.45, 0.35), CalderaShell.BASALT, Vector3(7.6, 0.45, 4.0), 0.0, true)
	# Receiving: two warm seats side by side.
	for x: float in [5.0, 6.3]:
		CalderaFurniture.piece(body, Vector3(0.34, 0.22, 0.3), CalderaShell.BASALT.lightened(0.05), Vector3(x, 0.22, 3.4), 0.0, true, SuperEgg.EPSILON_SOFT)
	# Shaping: a tall obsidian glass on the party wall, a line behind its head.
	var mirror := CalderaFurniture.piece(body, Vector3(0.02, 1.0, 0.5), Color(0.05, 0.05, 0.06), Vector3(PARTY_X + 0.14, 1.25, 2.9), 0.0, false, 7.0)
	mirror.material_override = SolidModel.material(Color(0.05, 0.05, 0.06), 0.04, 0.5)
	CalderaFurniture.led_line(body, Vector3(PARTY_X + 0.115, 2.27, 2.9), PI * 0.5, 0.9, CalderaFurniture.LED_WARM)
	# The immersion well: a shallow lava pool within a cool basalt ledge for
	# her adornments.
	var lava := SuperEgg.build_part(Vector3(WELL_HALF.x, 0.02, WELL_HALF.y), MOLTEN, 2.6, 2.6)
	var material := StandardMaterial3D.new()
	material.albedo_color = MOLTEN
	material.emission_enabled = true
	material.emission = MOLTEN
	material.emission_energy_multiplier = 2.4
	lava.material_override = material
	lava.position = Vector3(WELL_CENTRE.x, 0.04, WELL_CENTRE.y)
	body.add_child(lava)
	CollisionPolicy.mark_decorative(lava)
	for i in 16:
		var angle := TAU * float(i) / 16.0
		var at := WELL_CENTRE + Vector2(cos(angle) * (WELL_HALF.x + 0.12), sin(angle) * (WELL_HALF.y + 0.12))
		CalderaFurniture.piece(body, Vector3(0.2, 0.08, 0.14), COOL_LEDGE, Vector3(at.x, 0.08, at.y), -angle + PI * 0.5, false, 4.0)
	CalderaFurniture.concealed_light(body, Vector3(WELL_CENTRE.x, 0.6, WELL_CENTRE.y), Color(1.0, 0.5, 0.18), 1.1, 4.5)
	# The resting niche: a cooler basalt slab in a stone alcove, back east.
	CalderaFurniture.piece(body, Vector3(0.9, 0.16, 0.5), COOL_LEDGE, Vector3(6.9, 0.16, -0.35), 0.0, true, SuperEgg.EPSILON_SOFT)
	CalderaFurniture.piece(body, Vector3(0.08, 1.1, 0.5), CalderaShell.VOLCANIC_STONE, Vector3(5.9, 1.1, -0.4), 0.0, true)
	FireCalderaBuildings._marker(body, "ErisRestMarker", Vector3(6.9, 0.32, -0.35), 0.0)
	# Seventy years of objects: glass and steel shelves on the east wall, each
	# piece different, gifts and keepsakes from every household.
	CalderaFurniture.shelves(body, Vector3(7.62, 0.0, 2.0), PI * 0.5, 2.4, 3, func(b: StaticBody3D, p: Vector3, i: int) -> void:
		var keepsakes: Array[Color] = [Color(0.55, 0.30, 0.60), Color(0.82, 0.62, 0.24), Color(0.30, 0.62, 0.55), Color(0.70, 0.73, 0.75), Color(0.62, 0.20, 0.18), Color(0.16, 0.30, 0.72)]
		var size := 0.04 + 0.03 * float((i * 7) % 3)
		CalderaFurniture.piece(b, Vector3(size, size * (1.0 + float(i % 2)), size), keepsakes[(i * 5) % keepsakes.size()], p + Vector3(0, size * (1.0 + float(i % 2)), 0), float(i), false, 2.0 + float(i % 4)))
	CalderaFurniture.concealed_light(body, Vector3(5.0, 2.9, 2.4), CalderaFurniture.LED_WARM, 0.5, 5.0)
