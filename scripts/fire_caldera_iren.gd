class_name FireCalderaIren
extends RefCounted

## Selka, Aru and Mena's compact home.  It is acoustically separate from the
## civic complex but joined to it through the shared Highline.  The earlier
## private diagonal bridge became redundant once both front doors docked to
## the same civic circulation and is deliberately retired.

const SIZE := Vector2(12.0, 9.0)
const COBALT := Color(0.12, 0.30, 0.76, 0.66)
const AMBER := Color(0.96, 0.56, 0.12, 0.66)
const STAINED: Array[Color] = [COBALT, AMBER]
const FLOOR := Color(0.30, 0.28, 0.27)
const BED_CENTRES: Array[Vector2] = [Vector2(-3.8, -3.65), Vector2(0.0, -3.65), Vector2(3.8, -3.65)]
const BED_LAVA_Y := 0.55


static func build(parent: Node3D, entry: Dictionary, line: Dictionary, civic_line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), _spec())
	body.name = "IRENShell"
	_partition(body)
	_furnish(body)
	_lights(body)
	return body


static func _spec() -> Dictionary:
	return {
		"size": SIZE, "stained": STAINED, "transom": false, "pitch": 0.0,
		"walls": {
			"front": [
				{"to": 2.8, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
				{"to": 6.0, "kind": "door", "clear": 2.2, "door_type": "sliding", "label": "Iren home entrance"},
				{"to": 9.0, "kind": "glass", "tint": Color(COBALT, 0.28)},
				{"to": 12.0, "kind": "glass", "tint": Color(AMBER, 0.28)},
			],
			"back": [{"to": 12.0, "kind": "stone", "band": -1}],
			"west": [
				{"to": 6.3, "kind": "stone", "band": -1},
				{"to": 9.0, "kind": "glass", "tint": CalderaShell.SMOKY_GLASS},
			],
			"east": [
				{"to": 4.5, "kind": "stone", "band": -1},
				{"to": 9.0, "kind": "glass", "tint": CalderaShell.CLEAR_GLASS},
			],
		},
	}


static func _partition(body: StaticBody3D) -> void:
	# The receiving room stays public-facing.  One broad slider closes the
	# family's molten resting room without spending its circulation on a swing.
	FireCalderaOren._block(body, "RestPartitionWest", Vector3(-4.6, 1.9, -0.6), Vector3(2.8, 3.8, 0.18), FireCalderaBuildings.BASALT_PARTITION)
	CalderaShell.door_opening(body, Vector3(-1.5, 0.0, -0.6), 0.0, 3.4, 3.8, 0.18, 2.2, 2.6, 0, FireCalderaBuildings.BASALT_PARTITION)
	CalderaShell.open_sliding_door(body, Vector3(-1.5, 0.0, -0.6), 0.0, 2.2, 2.6, true)
	FireCalderaOren._block(body, "RestPartitionEast", Vector3(3.1, 1.9, -0.6), Vector3(5.8, 3.8, 0.18), FireCalderaBuildings.BASALT_PARTITION)
	for direction: Vector2 in [Vector2(0, 1), Vector2(0, -1)]:
		ClearZones.add(body, "family resting room", "door", Vector2(-1.5, -0.6), direction, 0.0, 1.0, 1.1, 0.05, 1.95)


static func _furnish(body: StaticBody3D) -> void:
	CalderaFurniture.low_table(body, Vector3(0.8, 0.0, 2.4), 0.0)
	for x: float in [-0.5, 2.1]:
		CalderaFurniture.chair(body, Vector3(x, 0.0, 2.4), PI * (0.5 if x < 0.8 else -0.5), CalderaFurniture.FIBRE_GREY)
	CalderaFurniture.sideboard(body, Vector3(5.55, 0.0, 1.2), -PI * 0.5, 1.8)
	for centre: Vector2 in BED_CENTRES:
		CalderaLavaFixture.add_bed(body, "LavaBed", centre, Vector2(0.92, 0.46), 0.56, 0.13, BED_LAVA_Y, CalderaShell.BASALT, 39000 + int(centre.x * 10.0))
	# The family well occupies the centre of the private room without blocking
	# the 1.4 m route along its front edge.
	CalderaLavaFixture.add_bed(body, "FamilyImmersionWell", Vector2(0.0, -1.55), Vector2(0.72, 0.58), 0.70, 0.15, 0.60, CalderaShell.BASALT, 39100)
	# Mena keeps colour fragments in a low backlit case beside the receiving
	# room, visible from the family passage but outside its clear zone.
	CalderaFurniture.piece(body, Vector3(1.15, 0.48, 0.28), CalderaShell.BASALT, Vector3(-4.25, 0.48, 2.8), 0.0, true, 6.0)
	for i in 8:
		var colour := COBALT.lerp(AMBER, float(i) / 7.0)
		var fragment := SuperEgg.build_part(Vector3(0.10, 0.12, 0.025), colour, 2.6, 2.6)
		fragment.position = Vector3(-5.05 + 0.23 * float(i), 1.05 + 0.12 * float(i % 2), 2.55)
		body.add_child(fragment)
		CollisionPolicy.mark_decorative(fragment)
	FireCalderaBuildings._marker(body, "SelkaRestMarker", Vector3(BED_CENTRES[0].x, BED_LAVA_Y, BED_CENTRES[0].y), 0.0)
	FireCalderaBuildings._marker(body, "AruRestMarker", Vector3(BED_CENTRES[1].x, BED_LAVA_Y, BED_CENTRES[1].y), 0.0)
	FireCalderaBuildings._marker(body, "MenaRestMarker", Vector3(BED_CENTRES[2].x, BED_LAVA_Y, BED_CENTRES[2].y), 0.0)
	FireCalderaBuildings._marker(body, "MenaGlassMarker", Vector3(-4.2, 0.0, 2.0), PI)


static func _glazed_bridge(body: StaticBody3D, iren_datum: float, civic_datum: float) -> void:
	# The bridge endpoint comes from Civic's authored east-hall wall in the
	# shared plan frame. Never retain an old world coordinate when settlement
	# planning moves either building.
	var civic_door_plan := FireCalderaPlan.shell_to_plan(FireCalderaPlan.plot("CIVIC"), Vector2(12.0, 0.0))
	var finish := body.to_local(Vector3(civic_door_plan.x, civic_datum, civic_door_plan.y))
	var start := Vector3(-6.0, 0.0, 0.0)
	var delta := Vector2(finish.x - start.x, finish.z - start.z)
	var length := delta.length()
	var yaw := atan2(delta.x, delta.y)
	var rise := finish.y - start.y
	var pitch := -atan2(rise, length)
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var middle := start.lerp(finish, 0.5)
	CalderaShell.soft_slab(body, "IrenCivicBridgeFloor", middle + Vector3(0, -0.09, 0), Vector3(1.15, 0.09, length * 0.5), Vector2(1.15, length * 0.5), FLOOR, basis)
	CalderaShell.soft_slab(body, "IrenCivicBridgeRoof", middle + Vector3(0, 2.85, 0), Vector3(1.20, 0.09, length * 0.5), Vector2(1.20, length * 0.5), CalderaShell.STAINLESS_SHADOW.darkened(0.16), basis)
	var forward := Vector3(delta.x / length, 0.0, delta.y / length)
	var right := Vector3(forward.z, 0.0, -forward.x)
	for side: float in [-1.0, 1.0]:
		var edge := middle + right * 1.12 + Vector3(0, 1.38, 0)
		CalderaShell._pane(body, "BridgeGlass", edge, Vector2(length * 0.5 - 0.08, 1.32), yaw + PI * 0.5, Color(CalderaShell.CLEAR_GLASS, 0.22))
	ClearZones.add(body, "Iren civic bridge", "lane", Vector2((start.x + finish.x) * 0.5, (start.z + finish.z) * 0.5), Vector2(delta.x, delta.y).normalized(), length * 0.45, length * 0.45, 0.72, minf(0.05, rise + 0.05), maxf(1.95, rise + 1.95))


static func _lights(body: StaticBody3D) -> void:
	CalderaFurniture.concealed_light(body, Vector3(0.0, 3.0, 2.2), CalderaFurniture.LED_WARM, 0.75, 5.0)
	CalderaFurniture.concealed_light(body, Vector3(0.0, 2.8, -2.8), Color(1.0, 0.48, 0.18), 0.8, 5.0)


static func register_lava(body: Node3D, terrain: Node) -> void:
	var surfaces: Array[Dictionary] = []
	for centre: Vector2 in BED_CENTRES:
		surfaces.append({"centre": centre, "half": Vector2(0.78, 0.32), "y": BED_LAVA_Y})
	surfaces.append({"centre": Vector2(0.0, -1.55), "half": Vector2(0.56, 0.42), "y": 0.60})
	for surface: Dictionary in surfaces:
		var world := PackedVector2Array()
		var height := 0.0
		for corner: Vector2 in [Vector2(-surface.half.x, -surface.half.y), Vector2(surface.half.x, -surface.half.y), Vector2(surface.half.x, surface.half.y), Vector2(-surface.half.x, surface.half.y)]:
			var point := body.global_transform * Vector3(surface.centre.x + corner.x, float(surface.y), surface.centre.y + corner.y)
			world.append(Vector2(point.x, point.z))
			height = point.y
		terrain.register_lava_polygon(world, height)
