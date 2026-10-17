class_name FireCalderaAro
extends RefCounted

## Tovan, Miru and Kes's thermal works and home.  The 17 x 13 m plan is two
## exact bands: nine metres of public control/work rooms at the west and eight
## metres of private home at the east.  The service descent is a real cut in
## the surveyed podium and the thermal distribution workshop.

const WORK_CENTRE := Vector2(-4.0, 0.0)
const HOME_CENTRE := Vector2(4.5, 0.0)
const COBALT := Color(0.12, 0.30, 0.76, 0.68)
const TEAL := Color(0.08, 0.56, 0.54, 0.68)
const STAINED: Array[Color] = [COBALT, TEAL]
const FLOOR := Color(0.30, 0.28, 0.27)
const PARTITION := FireCalderaBuildings.BASALT_PARTITION
const BED_CENTRES: Array[Vector2] = [Vector2(2.0, -4.8), Vector2(4.5, -4.8), Vector2(7.0, -4.8)]
const BED_LAVA_Y := 0.55


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.make_body(parent, entry, float(line["datum"]))
	body.name = "AROShell"
	CalderaShell.add_volume(body, _works_spec())
	CalderaShell.add_volume(body, _home_spec())
	_partitions(body)
	_control_gallery(body)
	_valve_workshop(body)
	_home(body)
	_inspection_hatches(body)
	_lights(body)
	return body


static func _works_spec() -> Dictionary:
	return {
		"size": Vector2(9.0, 13.0), "offset": WORK_CENTRE,
		"stained": STAINED, "transom": false, "pitch": 0.0,
		"overhang": {"east": 0.0},
		"walls": {
			"front": [
				{"to": 2.2, "kind": "glass", "tint": Color(COBALT, 0.28)},
				{"to": 5.0, "kind": "door", "clear": 2.2, "door_type": "sliding", "label": "thermal works entrance"},
				{"to": 9.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
			"back": [{"to": 9.0, "kind": "stone", "band": -1}],
			"west": [
				{"to": 4.5, "kind": "stone", "band": -1},
				{"to": 8.5, "kind": "glass", "tint": CalderaShell.SMOKY_GLASS},
				{"to": 13.0, "kind": "glass", "tint": Color(TEAL, 0.25)},
			],
			"east": [{"to": 13.0, "kind": "open"}],
		},
	}


static func _home_spec() -> Dictionary:
	return {
		"size": Vector2(8.0, 13.0), "offset": HOME_CENTRE,
		"stained": STAINED, "transom": false, "pitch": 0.0,
		"overhang": {"west": 0.0},
		"walls": {
			"front": [
				{"to": 4.0, "kind": "glass", "tint": Color(COBALT, 0.26)},
				{"to": 8.0, "kind": "glass", "tint": Color(TEAL, 0.26)},
			],
			"back": [{"to": 8.0, "kind": "stone", "band": -1}],
			"west": [{"to": 13.0, "kind": "open"}],
			"east": [
				{"to": 7.2, "kind": "stone", "band": -1},
				{"to": 10.2, "kind": "door", "clear": 2.2, "door_type": "sliding", "label": "Aro home entrance"},
				{"to": 13.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
		},
	}


static func _partitions(body: StaticBody3D) -> void:
	# The public control gallery is the front 7 m of the works; the noisy valve
	# shop is the rear 6 m and closes with a surface slider.
	_wall_with_opening(body, -8.5, 0.5, -0.5, true, -4.0, 2.4, "valve workshop", true)
	# One private service passage joins work and home.  It is not on the public
	# axis and closes acoustically into the family's receiving room.
	_wall_with_opening(body, -6.5, 6.5, 0.5, false, -3.0, 1.8, "family service passage", true)
	# The home's rear molten room closes from the receiving/shaping room.
	_wall_with_opening(body, 0.5, 8.5, -0.5, true, 4.5, 2.0, "home molten room", true)


static func _wall_with_opening(body: StaticBody3D, lo: float, hi: float, fixed: float, along_x: bool, at: float, clear: float, label: String, slider: bool) -> void:
	var a := at - clear * 0.5 - 0.28
	var b := at + clear * 0.5 + 0.28
	_partition(body, lo, a, fixed, along_x)
	var origin := Vector3((a + b) * 0.5, 0.0, fixed) if along_x else Vector3(fixed, 0.0, (a + b) * 0.5)
	var yaw := 0.0 if along_x else PI * 0.5
	CalderaShell.door_opening(body, origin, yaw, b - a, CalderaShell.STOREY, 0.18, clear, 2.6, 0, PARTITION)
	if slider:
		CalderaShell.open_sliding_door(body, origin, yaw, clear, 2.6, true)
	var point := Vector2(at, fixed) if along_x else Vector2(fixed, at)
	var normal := Vector2(0, 1) if along_x else Vector2(1, 0)
	for direction: Vector2 in [normal, -normal]:
		ClearZones.add(body, label, "door", point, direction, 0.0, 1.0, clear * 0.5, 0.05, 1.95)
	_partition(body, b, hi, fixed, along_x)


static func _partition(body: StaticBody3D, lo: float, hi: float, fixed: float, along_x: bool) -> void:
	if hi - lo < 0.05:
		return
	var size := Vector3(hi - lo, CalderaShell.STOREY, 0.18) if along_x else Vector3(0.18, CalderaShell.STOREY, hi - lo)
	var at := Vector3((lo + hi) * 0.5, CalderaShell.STOREY * 0.5, fixed) if along_x else Vector3(fixed, CalderaShell.STOREY * 0.5, (lo + hi) * 0.5)
	FireCalderaOren._block(body, "AroPartition", at, size, PARTITION)


static func _control_gallery(body: StaticBody3D) -> void:
	# The valve wall is the room's anchor: supply, return, bypass, relief and
	# reservoir isolation, each with a bright stem and a readable gauge above.
	for i in 5:
		var x := -7.4 + 1.55 * float(i)
		_valve_station(body, Vector3(x, 0.0, 1.25), i)
	CalderaFurniture.counter(body, Vector3(-5.6, 0.0, 3.8), PI, 2.8)
	CalderaFurniture.table(body, Vector3(-1.7, 0.0, 3.8), 0.0, 2.2, 0.8)
	# Council emergency bell: one civic signal, reachable from the operator's
	# route but clear of the entrance and controls.
	var bell := SuperEgg.build_part(Vector3(0.32, 0.42, 0.32), Color(0.82, 0.48, 0.16), 2.2, 3.0)
	bell.name = "EmergencyBell"
	bell.position = Vector3(-8.0, 2.25, 5.5)
	body.add_child(bell)
	CollisionPolicy.mark_decorative(bell)
	CalderaShell._metal(body, Vector3(-8.0, 2.9, 5.5), Vector3(0.04, 0.7, 0.04), CalderaShell.STAINLESS, false)
	FireCalderaBuildings._marker(body, "TovanControlMarker", Vector3(-5.0, 0.0, 2.4), PI)


static func _valve_station(body: StaticBody3D, at: Vector3, index: int) -> void:
	CalderaShell._metal(body, at + Vector3(0, 1.0, 0), Vector3(0.24, 2.0, 0.24), CalderaShell.STAINLESS_SHADOW, true)
	var valve := SuperEgg.build_part(Vector3(0.32, 0.32, 0.09), [COBALT, TEAL][index % 2], 3.0, 3.0)
	valve.position = at + Vector3(0, 1.15, 0.18)
	body.add_child(valve)
	CollisionPolicy.mark_decorative(valve)
	for spoke in 4:
		var angle := TAU * float(spoke) / 4.0
		CalderaShell._beam(body, valve.position, valve.position + Vector3(cos(angle) * 0.42, sin(angle) * 0.42, 0), Vector2(0.025, 0.025), CalderaShell.STAINLESS)
	var gauge := SuperEgg.build_part(Vector3(0.26, 0.26, 0.05), Color(0.82, 0.86, 0.86), 2.2, 2.2)
	gauge.position = at + Vector3(0, 2.45, 0.16)
	body.add_child(gauge)
	CollisionPolicy.mark_decorative(gauge)


static func _valve_workshop(body: StaticBody3D) -> void:
	# Miru's bending and welding line stays on the east half so the descent has
	# a clear two-metre approach on the west.
	CalderaFurniture.table(body, Vector3(-2.2, 0.0, -2.4), 0.0, 2.4, 0.8)
	CalderaFurniture.table(body, Vector3(-2.0, 0.0, -5.0), 0.0, 2.2, 0.8)
	# Pipe bender: three rollers over a heavy bench.
	for x: float in [-2.65, -2.0, -1.35]:
		var roller := SuperEgg.build_part(Vector3(0.22, 0.22, 0.12), CalderaShell.STAINLESS, 2.2, 2.2)
		roller.position = Vector3(x, 1.05, -2.4)
		body.add_child(roller)
		CollisionPolicy.mark_decorative(roller)
	# Pressure-test rig and spare valve bodies.
	for x: float in [-3.0, -2.0, -1.0]:
		CalderaShell._metal(body, Vector3(x, 1.25, -5.0), Vector3(0.04, 0.8, 0.04), CalderaShell.STEEL_BLUED, false)
	for at: Vector3 in [Vector3(-3.8, 0.35, -2.0), Vector3(-3.8, 0.35, -3.0), Vector3(-3.8, 0.35, -4.0)]:
		CalderaFurniture.piece(body, Vector3(0.30, 0.30, 0.30), CalderaShell.STAINLESS_SHADOW, at, 0.0, true, 3.0)
	FireCalderaBuildings._marker(body, "MiruWorkMarker", Vector3(-2.2, 0.0, -3.3), 0.0)
	FireCalderaBuildings._marker(body, "KesWorkMarker", Vector3(-1.0, 0.0, -4.4), 0.0)


static func _home(body: StaticBody3D) -> void:
	CalderaFurniture.low_table(body, Vector3(4.5, 0.0, 3.7), 0.0)
	for x: float in [3.2, 5.8]:
		CalderaFurniture.chair(body, Vector3(x, 0.0, 3.7), PI * (0.5 if x < 4.5 else -0.5), CalderaFurniture.FIBRE_GREY)
	# Tovan's labelled-by-shape samples: vent rock, pipe scale and three alloy
	# coupons, arranged on the solid east wall.
	CalderaFurniture.sideboard(body, Vector3(8.05, 0.0, 4.65), -PI * 0.5, 2.2)
	for i in 5:
		CalderaFurniture.piece(body, Vector3(0.12, 0.10, 0.08), [Color(0.30, 0.25, 0.22), COBALT, TEAL][i % 3], Vector3(7.75, 0.88, 3.9 + 0.38 * float(i)), 0.2 * float(i), false, 3.0)
	for centre: Vector2 in BED_CENTRES:
		CalderaLavaFixture.add_bed(body, "LavaBed", centre, Vector2(0.90, 0.46), 0.56, 0.13, BED_LAVA_Y, CalderaShell.BASALT, 41000 + int(centre.x * 10.0))
	# Keep the well clear of the full player capsule sweeping through the room
	# threshold; it is a destination beside the circulation line, not a curb
	# placed in the doorway.
	CalderaLavaFixture.add_bed(body, "SharedImmersionWell", Vector2(4.5, -3.1), Vector2(0.78, 0.62), 0.72, 0.16, 0.60, CalderaShell.BASALT, 41100)
	for data: Array in [["TovanRestMarker", BED_CENTRES[0]], ["MiruRestMarker", BED_CENTRES[1]], ["KesRestMarker", BED_CENTRES[2]]]:
		var centre: Vector2 = data[1]
		FireCalderaBuildings._marker(body, data[0], Vector3(centre.x, BED_LAVA_Y, centre.y), 0.0)


static func _inspection_hatches(body: StaticBody3D) -> void:
	for x: float in [-3.2, -1.4]:
		var hatch := SuperEgg.build_part(Vector3(0.62, 0.08, 0.48), CalderaShell.STEEL_BLUED, 5.5, 5.5)
		hatch.name = "ServiceInspectionHatch"
		hatch.position = Vector3(x, 0.08, -7.05)
		body.add_child(hatch)
		CollisionPolicy.mark_decorative(hatch)


static func _lights(body: StaticBody3D) -> void:
	for at: Vector3 in [Vector3(-4.0, 3.0, 3.0), Vector3(-2.2, 3.0, -3.7), Vector3(4.5, 3.0, 3.2)]:
		CalderaFurniture.concealed_light(body, at, CalderaFurniture.LED_WARM, 0.78, 5.5)
	CalderaFurniture.concealed_light(body, Vector3(4.5, 2.8, -3.5), Color(1.0, 0.48, 0.18), 0.8, 5.0)


static func register_lava(body: Node3D, terrain: Node) -> void:
	var surfaces: Array[Dictionary] = []
	for centre: Vector2 in BED_CENTRES:
		surfaces.append({"centre": centre, "half": Vector2(0.76, 0.32), "y": BED_LAVA_Y})
	surfaces.append({"centre": Vector2(4.5, -3.1), "half": Vector2(0.62, 0.46), "y": 0.60})
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
