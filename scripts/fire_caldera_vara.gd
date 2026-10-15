class_name FireCalderaVara
extends RefCounted

## The Vara glass-and-metal studio and home (fire_caldera_buildings.md,
## section 4; Omi and Talen).  Its plan is the brief made literal: an 8 m
## studio wing and a 5 m home wing flank a 5 x 8 m open daylight court.  The
## court is not leftover space.  It is the building's full-scale inspection
## room: finished structural panes stand on an A-frame rack where sun and the
## reservoir's glow reveal strain, colour and distortion before installation.
## A 5 x 5 m metal shop closes the court's back while leaving its front open.
##
## Local +Z faces the promenade.  Customers enter the clean assembly room at
## the west front; the household enters from the east path.  The hot shop and
## metal shop have their own service doors at the back.  The court is reached
## from the clean room and the home, never used as a public shortcut.

const SIZE := Vector2(18.0, 14.0)
const WEST_CENTRE := Vector2(-5.0, 0.0)
const HOME_CENTRE := Vector2(6.5, 0.0)
const METAL_CENTRE := Vector2(1.5, -4.5)
const STOREY := CalderaShell.STOREY
const WALL := 0.20
const PARTITION := FireCalderaBuildings.BASALT_PARTITION
const TEAL := Color(0.10, 0.58, 0.55, 0.68)
const AMBER := Color(0.96, 0.57, 0.14, 0.68)
const STAINED: Array[Color] = [TEAL, AMBER]
const FLOOR := Color(0.31, 0.29, 0.28)
const BED_LAVA_Y := 0.55
const BED_CENTRES: Array[Vector2] = [Vector2(5.25, -4.8), Vector2(7.75, -4.8)]


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.make_body(parent, entry, float(line["datum"]))
	body.name = "VARAShell"
	CalderaShell.add_volume(body, _studio_spec())
	CalderaShell.add_volume(body, _home_spec())
	CalderaShell.add_volume(body, _metal_spec())
	_partitions(body)
	_daylight_court(body)
	_furnish_studio(body)
	_furnish_home(body)
	_lights(body)
	return body


static func _studio_spec() -> Dictionary:
	return {
		"size": Vector2(8.0, 14.0), "offset": WEST_CENTRE, "stained": STAINED,
		"transom": false, "pitch": 2.0,
		"overhang": {"east": 0.0},
		"walls": {
			"front": [
				{"to": 1.2, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
				{"to": 4.2, "kind": "door", "label": "studio entrance", "clear": 2.2},
				{"to": 8.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
			"back": [{"to": 8.0, "kind": "stone", "band": -1}],
			"west": [
				{"to": 1.0, "kind": "stone", "band": -1},
				{"to": 4.0, "kind": "door", "band": -1, "clear": 2.2, "height": 2.7, "door_type": "overhead", "label": "hot-shop service door"},
				{"to": 10.0, "kind": "glass", "tint": CalderaShell.SMOKY_GLASS},
				{"to": 14.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
			"east": [
				{"to": 5.0, "kind": "open"},
				{"to": 7.0, "kind": "stone", "band": -1},
				{"to": 10.0, "kind": "door", "clear": 1.7, "door_type": "sliding", "label": "studio court door"},
				{"to": 14.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
		},
	}


static func _home_spec() -> Dictionary:
	return {
		"size": Vector2(5.0, 14.0), "offset": HOME_CENTRE, "stained": STAINED,
		"transom": false, "pitch": 2.0,
		"overhang": {"west": 0.0},
		"walls": {
			"front": [
				{"to": 2.5, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
				{"to": 5.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
			"back": [{"to": 5.0, "kind": "stone", "band": -1}],
			"west": [
				{"to": 5.0, "kind": "stone", "band": -1},
				{"to": 8.0, "kind": "glass", "tint": CalderaShell.SMOKY_GLASS},
				{"to": 11.0, "kind": "door", "clear": 1.6, "door_type": "sliding", "label": "home court door"},
				{"to": 14.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
			"east": [
				{"to": 7.5, "kind": "stone", "band": -1},
				{"to": 10.5, "kind": "door", "clear": 2.2, "door_type": "sliding", "label": "home entrance"},
				{"to": 14.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
		},
	}


static func _metal_spec() -> Dictionary:
	return {
		"size": Vector2(5.0, 5.0), "offset": METAL_CENTRE, "stained": STAINED,
		"transom": false, "pitch": 2.0,
		"overhang": {"west": 0.0, "east": 0.0},
		"walls": {
			"front": [{"to": 5.0, "kind": "glass", "tint": Color(TEAL, 0.24)}],
			"back": [{"to": 5.0, "kind": "stone", "band": -1}],
			"west": [{"to": 5.0, "kind": "open"}],
			"east": [{"to": 5.0, "kind": "stone", "band": -1}],
		},
	}


static func _partitions(body: StaticBody3D) -> void:
	# Studio: clean assembly in front, hot work and annealing behind.  The wide
	# opening is leafless because material moves through it all day.
	_wall_with_opening(body, Vector2(-9.0, -1.0), Vector2(-1.0, -1.0), -5.7, 2.0, "assembly to hot shop")
	# The back row divides the 5 m hot shop from the 3 m annealing chamber.
	_wall_with_opening(body, Vector2(-4.0, -7.0), Vector2(-4.0, -1.0), -4.0, 1.4, "annealing slider", true)
	# Home: the rear molten resting room is private, but its slider parks inside
	# the room and leaves the receiving route at full width.
	_wall_with_opening(body, Vector2(4.0, -1.5), Vector2(9.0, -1.5), 6.5, 1.5, "resting-room slider", true)


static func _wall_with_opening(body: StaticBody3D, start: Vector2, finish: Vector2, at: float, clear: float, label: String, slider: bool = false) -> void:
	var along_x := absf(finish.x - start.x) > absf(finish.y - start.y)
	var lo := start.x if along_x else start.y
	var hi := finish.x if along_x else finish.y
	var fixed := start.y if along_x else start.x
	var a := at - clear * 0.5 - 0.28
	var b := at + clear * 0.5 + 0.28
	_partition(body, lo, a, fixed, along_x)
	var origin := Vector3((a + b) * 0.5, 0.0, fixed) if along_x else Vector3(fixed, 0.0, (a + b) * 0.5)
	var yaw := 0.0 if along_x else PI * 0.5
	CalderaShell.door_opening(body, origin, yaw, b - a, STOREY, WALL, clear, 2.45, 0, PARTITION)
	if slider:
		CalderaShell.open_sliding_door(body, origin, yaw, clear, 2.45, true)
	var point := Vector2(at, fixed) if along_x else Vector2(fixed, at)
	var normal := Vector2(0, 1) if along_x else Vector2(1, 0)
	for direction: Vector2 in [normal, -normal]:
		ClearZones.add(body, label, "door", point, direction, 0.0, 1.0, clear * 0.5, 0.05, 1.95)
	_partition(body, b, hi, fixed, along_x)


static func _partition(body: StaticBody3D, lo: float, hi: float, fixed: float, along_x: bool) -> void:
	if hi - lo <= 0.04:
		return
	var size := Vector3(hi - lo, STOREY, WALL) if along_x else Vector3(WALL, STOREY, hi - lo)
	var at := Vector3((lo + hi) * 0.5, STOREY * 0.5, fixed) if along_x else Vector3(fixed, STOREY * 0.5, (lo + hi) * 0.5)
	FireCalderaOren._block(body, "Partition", at, size, PARTITION)


static func _daylight_court(body: StaticBody3D) -> void:
	# The court's west-side A-frame holds finished panes on edge.  It is a
	# working inspection rack, not an unexplained decorative glass screen.
	for z: float in [-0.2, 1.8, 3.8, 5.8]:
		for side: float in [-1.0, 1.0]:
			CalderaShell._beam(body, Vector3(-0.55, 0.08, z), Vector3(-0.15 + side * 0.24, 2.2, z), Vector2(0.045, 0.045), CalderaShell.STEEL_BLUED)
	var pane_colours: Array[Color] = [Color(TEAL, 0.22), Color(AMBER, 0.22), Color(CalderaShell.CLEAR_GLASS, 0.20)]
	for i in 6:
		var pane := SuperEgg.build_part(Vector3(0.035, 1.05, 0.62), pane_colours[i % pane_colours.size()], 8.0, 8.0)
		var glass := SolidModel.material(pane_colours[i % pane_colours.size()], 0.04, 0.04)
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		pane.material_override = glass
		pane.position = Vector3(-0.24 + 0.09 * float(i), 1.08, 0.1 + 0.85 * float(i))
		pane.rotation.y = -0.10 + 0.04 * float(i)
		body.add_child(pane)
		CollisionPolicy.mark_decorative(pane)
	# A low sample table leaves a 2 m route through the court.
	CalderaFurniture.table(body, Vector3(2.0, 0.0, 4.9), 0.0, 2.0, 0.72)
	for i in 5:
		CalderaFurniture.jar(body, Vector3(1.3 + 0.34 * float(i), 0.82, 4.9), [TEAL, AMBER][i % 2], 0.055)
	CalderaFurniture.flame_capsule(body, Vector3(3.25, 0.0, 6.2), 0.9)
	FireCalderaBuildings._marker(body, "CourtInspectionMarker", Vector3(1.8, 0.0, 3.4), PI)


static func _furnish_studio(body: StaticBody3D) -> void:
	# Clean assembly: cutting/light table, full-size design wall and finished
	# pane rack.  The centreline from the public door to the court stays clear.
	CalderaFurniture.table(body, Vector3(-6.7, 0.0, 3.4), 0.0, 2.6, 1.0)
	CalderaFurniture.table(body, Vector3(-3.0, 0.0, 4.8), PI * 0.5, 2.0, 0.8)
	_colour_samples(body, Vector3(-8.65, 1.6, 2.6))
	# Hot forming: furnace, glory hole, marver and Omi's blowing bench.
	_furnace(body, Vector3(-7.8, 0.0, -2.2), "GlassFurnace")
	_furnace(body, Vector3(-4.8, 0.0, -5.6), "GloryHole")
	CalderaFurniture.table(body, Vector3(-6.6, 0.0, -2.8), 0.0, 2.2, 0.7)
	CalderaFurniture.bench(body, Vector3(-6.3, 0.0, -5.8), 0.0, 1.8)
	# Annealing chamber: one long lehr and two small annealers.
	CalderaFurniture.piece(body, Vector3(0.82, 0.65, 0.62), CalderaShell.VOLCANIC_STONE, Vector3(-2.25, 0.65, -5.75), PI * 0.5, true, 7.0)
	FireCalderaBuildings._glow(body, "LehrPort", Vector3(0.40, 0.12, 0.01), Vector3(-2.25, 0.72, -5.12), Color(1.0, 0.36, 0.08))
	for z: float in [-2.5, -3.4]:
		_furnace(body, Vector3(-2.1, 0.0, z), "Annealer")
	# Metal shop: cold cutting, leading, soldering and the frame-bending bench.
	CalderaFurniture.table(body, Vector3(1.5, 0.0, -3.1), 0.0, 2.8, 0.8)
	CalderaFurniture.table(body, Vector3(1.5, 0.0, -5.7), 0.0, 2.4, 0.7)
	for x: float in [0.5, 1.5, 2.5]:
		CalderaShell._metal(body, Vector3(x, 1.65, -6.65), Vector3(0.35, 0.025, 0.04), CalderaShell.STEEL_BLUED, false)
	FireCalderaBuildings._marker(body, "OmiWorkMarker", Vector3(-6.6, 0.0, -2.0), PI)
	FireCalderaBuildings._marker(body, "TalenWorkMarker", Vector3(1.5, 0.0, -3.8), 0.0)


static func _furnish_home(body: StaticBody3D) -> void:
	CalderaFurniture.low_table(body, Vector3(6.5, 0.0, 5.0), 0.0)
	for x: float in [5.35, 7.65]:
		CalderaFurniture.chair(body, Vector3(x, 0.0, 5.0), PI * (0.5 if x < 6.5 else -0.5), CalderaFurniture.FIBRE_GREY)
	# The clear reservoir front is kept free; a shaping shelf occupies the solid
	# east wall beside the household entrance.
	CalderaFurniture.sideboard(body, Vector3(8.62, 0.0, 5.3), -PI * 0.5, 1.6)
	for centre: Vector2 in BED_CENTRES:
		CalderaLavaFixture.add_bed(body, "LavaBed", centre, Vector2(0.92, 0.46), 0.56, 0.13, BED_LAVA_Y, CalderaShell.BASALT, 37000 + int(centre.x * 10.0))
		CalderaFurniture.concealed_light(body, Vector3(centre.x, 0.9, centre.y), Color(1.0, 0.52, 0.2), 0.7, 3.8)
	# A compact private immersion well between the two resting niches.
	CalderaLavaFixture.add_bed(body, "ImmersionWell", Vector2(6.5, -2.7), Vector2(0.72, 0.72), 0.72, 0.16, 0.60, CalderaShell.BASALT, 37110)
	FireCalderaBuildings._marker(body, "OmiRestMarker", Vector3(BED_CENTRES[0].x, BED_LAVA_Y, BED_CENTRES[0].y), 0.0)
	FireCalderaBuildings._marker(body, "TalenRestMarker", Vector3(BED_CENTRES[1].x, BED_LAVA_Y, BED_CENTRES[1].y), 0.0)


static func _colour_samples(body: StaticBody3D, at: Vector3) -> void:
	for i in 8:
		var colour := TEAL.lerp(AMBER, float(i) / 7.0)
		var tile := SuperEgg.build_part(Vector3(0.18, 0.28, 0.025), colour, 7.0, 7.0)
		tile.position = at + Vector3(0.0, 0.42 * float(i % 4), -0.45 + 0.3 * float(i / 4))
		body.add_child(tile)
		CollisionPolicy.mark_decorative(tile)


static func _furnace(body: StaticBody3D, at: Vector3, name_text: String) -> void:
	var mass := CalderaFurniture.piece(body, Vector3(0.55, 0.62, 0.5), CalderaShell.BASALT, at + Vector3(0, 0.62, 0), 0.0, true, 6.0)
	mass.name = name_text
	FireCalderaBuildings._glow(body, "%sPort" % name_text, Vector3(0.25, 0.20, 0.01), at + Vector3(0, 0.68, 0.51), Color(1.0, 0.34, 0.07))


static func _lights(body: StaticBody3D) -> void:
	CalderaFurniture.concealed_light(body, Vector3(-5.0, 3.0, 3.0), Color(0.72, 0.88, 0.9), 0.75, 6.0)
	CalderaFurniture.concealed_light(body, Vector3(-5.8, 2.8, -4.0), Color(1.0, 0.48, 0.18), 0.8, 5.0)
	CalderaFurniture.concealed_light(body, Vector3(1.5, 2.8, -4.5), CalderaFurniture.LED_WARM, 0.7, 5.0)
	CalderaFurniture.concealed_light(body, Vector3(6.5, 2.8, 2.8), CalderaFurniture.LED_WARM, 0.7, 5.0)


static func register_lava(body: Node3D, terrain: Node) -> void:
	var surfaces: Array[Dictionary] = []
	for centre: Vector2 in BED_CENTRES:
		surfaces.append({"centre": centre, "half": Vector2(0.78, 0.32), "y": BED_LAVA_Y})
	surfaces.append({"centre": Vector2(6.5, -2.7), "half": Vector2(0.56, 0.56), "y": 0.60})
	for surface: Dictionary in surfaces:
		var world := PackedVector2Array()
		var height := 0.0
		var centre: Vector2 = surface["centre"]
		var half: Vector2 = surface["half"]
		for corner: Vector2 in [Vector2(-half.x, -half.y), Vector2(half.x, -half.y), Vector2(half.x, half.y), Vector2(-half.x, half.y)]:
			var point := body.global_transform * Vector3(centre.x + corner.x, float(surface["y"]), centre.y + corner.y)
			world.append(Vector2(point.x, point.z))
			height = point.y
		terrain.register_lava_polygon(world, height)
