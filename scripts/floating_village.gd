class_name FloatingVillage
extends Node3D

## The Crossroads Fishing Village, built from FishingVillagePlan: every deck,
## pile, jetty, gangway, swim exit and berth is placed from that one data file
## (docs/architecture/fishing_village_layout.md). It stands against Anvil Rock
## and Heron Rock (FishingIslets) and is reached by swimming to one of three
## ramps. Every building is built from its design brief by FishingBuildings;
## this script lays the plan's decks, routes, piles, exits, boats and lines and
## wires the shop and the rest point.

const CENTER := Vector3(440.0, 0.0, 0.0)
const NPC_SCENE := "res://scenes/npc.tscn"
## Where the Ocean portal stands: the plan's gate on the portal landing.
const PORTAL_OFFSET := Vector3(30.0, 0.0, 20.0)
const DECK_THICKNESS := 0.3
const PILE_SPACING := 4.0
const PILE_RADIUS := 0.17
## A pile's foot is driven this far into the shelf.
const PILE_EMBED := 0.4
## Sun-bleached hardwood on top; only the wet piles stay dark (StiltKit.DECK).
const DECK_COLOR := StiltKit.DECK
const PILE_COLOR := Color(0.2, 0.12, 0.07)
## The Mor houseboat's rest point: 10 Tokoins, the village's inn rate.
const REST_FEE := 10
const REST_WORLD := "outskirts"
const REST_POINT := "fishing_village_houseboat"

var _terrain: Node
var _water := 0.0
var _pile_positions: Array[Vector2] = []
## Structures built from their design briefs, by plan name.
var _built := {}


func _ready() -> void:
	_terrain = get_node_or_null("../Terrain")
	LoadingScreen.enqueue_build_stage("Configuring world systems…",0.88,_build)


## World position of a plan point at a height above the lake surface.
func _at(local: Vector2, height: float) -> Vector3:
	return Vector3(CENTER.x + local.x, _water + height, CENTER.z + local.y)


func _build() -> void:
	if _terrain == null:
		return
	_water = _terrain.get_lake_water_level()
	FishingIslets.build(self, _terrain)
	for structure in FishingVillagePlan.STRUCTURES:
		_build_structure(structure)
	for route in FishingVillagePlan.ROUTES:
		_build_route(route)
	_build_swim_exits()
	_build_piles()
	_build_streetlights()
	_build_boats()
	_build_shop()
	_build_residents()
	_merge_static()


# ---------------------------------------------------------------------------
# Structures
# ---------------------------------------------------------------------------

func _household_color(owner: String) -> Color:
	return FishingVillagePlan.HOUSEHOLD_COLORS[FishingVillagePlan.household_of(owner)]


func _build_structure(structure: Dictionary) -> void:
	var rect: Rect2 = structure["rect"]
	var structure_name := str(structure["name"])
	if structure_name in FishingBuildings.BUILT:
		# Built from its design brief, on its own piles (FishingBuildings).
		var built := FishingBuildings.build(structure_name)
		add_child(built)
		built.global_position = _at(FishingBuildings.anchor(structure_name), 0.0)
		_built[structure_name] = built
		if structure_name == "MorHouseboat":
			_wire_rest_point(built)
		return
	match str(structure["kind"]):
		"deck":
			_deck(str(structure["name"]), rect, FishingVillagePlan.DECK_TOP, DECK_COLOR)
			_queue_piles(rect)
			if structure_name in FishingBuildings.DRESSED:
				var dressing := FishingBuildings.dress(structure_name)
				add_child(dressing)
				dressing.global_position = _at(Vector2.ZERO, 0.0)
		"pontoon":
			_deck(str(structure["name"]), rect, FishingVillagePlan.FLOAT_DECK, DECK_COLOR.lightened(0.06))
			if structure_name in FishingBuildings.DRESSED:
				var yard := FishingBuildings.dress(structure_name)
				add_child(yard)
				yard.global_position = _at(Vector2.ZERO, 0.0)
		"lines":
			_mussel_lines(rect)
		_:
			push_error("FloatingVillage: %s has no builder; add it to FishingBuildings.BUILT" % structure_name)


## A deck of planks over joists, with one box collider through the shared
## collision policy. `top` is relative to the lake surface.
func _deck(name_text: String, rect: Rect2, top: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name_text
	add_child(body)
	body.global_position = _at(rect.get_center(), 0.0)
	StiltKit.floor_slab(body, Rect2(-rect.size * 0.5, rect.size), top, color)
	return body


## The Mor houseboat's rest point: Leena at her stand in the common cabin, the
## wake marker by the first bunk, the party gathering on the arrival deck.
func _wire_rest_point(boat: StaticBody3D) -> void:
	var wake := boat.get_node("WakeMarker") as Marker3D
	var stand := boat.get_node("StandMarker") as Marker3D
	var gather := boat.get_node("GatherMarker") as Marker3D
	var keeper_at := (boat.get_node("KeeperStand") as Node3D).position
	_build_keeper(boat, wake, stand, keeper_at, gather.global_position)


## Leena keeps the stores and the rest point (10 Tokoins, through the shared
## transaction UI, as in every inn).
func _build_keeper(body: StaticBody3D, wake: Marker3D, stand: Marker3D, local_position: Vector3, gather_at: Vector3 = Vector3.INF) -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		return
	var keeper = packed.instantiate()
	keeper.display_name = "Leena Mor"
	keeper.stationary = true
	keeper.is_female = true
	keeper.facing_degrees = 180.0
	keeper.fixed_ground_y = body.global_position.y + local_position.y
	FishingVillagePeople.apply_look(keeper, "Leena Mor")
	var lines: Array[String] = [
		"The kettle never goes cold on this boat.",
		"Ivo says the ferry knows the weather before Dala does. Don't tell her.",
	]
	keeper.talk_lines = lines
	keeper.dialog_actions_provider = func() -> Array[Dictionary]:
		return [TransactionInteraction.paid_action(
			"Rest for the night", REST_FEE,
			func() -> void:
				if RecoveryManager.begin_paid_rest(REST_WORLD, REST_POINT):
					DialogUI.hide_dialog(),
			"Your purse feels too light.",
			func() -> bool: return RecoveryManager.can_rest()
		)]
	keeper.set_terrain_reference(_terrain)
	keeper.position = local_position
	body.add_child(keeper)
	RecoveryManager.register_rest_point.call_deferred(
		REST_WORLD, REST_POINT, wake.global_transform, stand.global_transform,
		gather_at if gather_at != Vector3.INF else stand.global_position + Vector3(0, 0, 2.5)
	)


func _mussel_lines(rect: Rect2) -> void:
	var holder := Node3D.new()
	holder.name = "MusselLines"
	add_child(holder)
	var z := rect.position.y + 2.0
	while z < rect.end.y:
		var rope := SuperEgg.build_part(Vector3(rect.size.x * 0.5, 0.03, 0.03), Color(0.35, 0.3, 0.2), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		rope.position = _at(Vector2(rect.get_center().x, z), 0.02)
		CollisionPolicy.mark_decorative(rope)
		holder.add_child(rope)
		var x := rect.position.x
		while x <= rect.end.x + 0.01:
			var buoy := SuperEgg.build_part(Vector3(0.22, 0.22, 0.22), Color(0.82, 0.74, 0.5), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
			buoy.position = _at(Vector2(x, z), 0.1)
			CollisionPolicy.mark_decorative(buoy)
			holder.add_child(buoy)
			x += 2.0
		z += 4.0


# ---------------------------------------------------------------------------
# Routes, gangways and swim exits
# ---------------------------------------------------------------------------

func _build_route(route: Dictionary) -> void:
	var points: Array = route["points"]
	var width: float = route["width"]
	var is_gangway: bool = route["class"] == "gangway"
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var length := a.distance_to(b)
		var along := (b - a) / length
		var body := StaticBody3D.new()
		body.name = "%s_%d" % [route["name"], i]
		add_child(body)
		var yaw := atan2(along.x, along.y)
		var top := FishingVillagePlan.DECK_TOP
		var pitch := 0.0
		if is_gangway:
			# Falls from the fixed deck to the floating one.
			var rise: float = route["rise"]
			pitch = atan2(rise, length)
			top = FishingVillagePlan.DECK_TOP - rise * 0.5
		body.global_position = _at(a.lerp(b, 0.5), top)
		# A little longer than the segment so joints in a bend leave no gap. Where
		# planks overlap (a bend, a spur meeting the spine, a route running onto
		# a landing) they sit a few millimetres apart so the overlap does not
		# flicker: landings on top, then the spine, then every other route, and
		# alternate segments of one route apart. Collision is not offset.
		var run := length + (0.0 if is_gangway else width * 0.5)
		var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
		var sink := (0.004 if route["class"] == "spine" else 0.009) + 0.002 * float(i % 2)
		var planks := StiltKit.plank_surface(body, Transform3D(basis, Vector3(0.0, -sink, 0.0)), width, run, DECK_COLOR)
		CollisionPolicy.add_box(body, planks, Vector3(width, DECK_THICKNESS, run), basis * Vector3(0.0, -DECK_THICKNESS * 0.5, 0.0), basis)
		if not is_gangway:
			_queue_route_piles(a, b, width)


func _build_swim_exits() -> void:
	var head := 1.596
	var lower := FishingVillagePlan.exit_lower_end(head)
	var run := FishingVillagePlan.exit_run(head)
	var body := StaticBody3D.new()
	body.name = "SwimExits"
	add_child(body)
	body.global_position = _at(Vector2.ZERO, 0.0)
	for e in FishingVillagePlan.SWIM_EXITS:
		var width: float = float(e["x1"]) - float(e["x0"])
		var x := (float(e["x0"]) + float(e["x1"])) * 0.5
		# Planked, flush with the deck at its edge, its foot at the derived
		# height a swimmer floats at, `run` out into the water.
		var low := Vector2(x, float(e["edge_z"]) + run)
		var high := Vector2(x, float(e["edge_z"]))
		var ramp := StiltKit.ramp(body, low, high, lower, FishingVillagePlan.DECK_TOP, width)
		ramp.name = str(e["name"])
		StiltKit.ramp_rails(body, low, high, lower, FishingVillagePlan.DECK_TOP, width)


# ---------------------------------------------------------------------------
# Piles: every deck stands on the shelves, never in open deep water
# ---------------------------------------------------------------------------

func _queue_piles(rect: Rect2) -> void:
	var x := rect.position.x + 0.5
	while x <= rect.end.x - 0.4:
		var z := rect.position.y + 0.5
		while z <= rect.end.y - 0.4:
			_pile_positions.append(Vector2(x, z))
			z += PILE_SPACING
		x += PILE_SPACING


func _queue_route_piles(a: Vector2, b: Vector2, width: float) -> void:
	var length := a.distance_to(b)
	var along := (b - a) / length
	var side := Vector2(-along.y, along.x) * (width * 0.5 - 0.3)
	var t := 0.0
	while t <= length:
		var centre := a + along * t
		_pile_positions.append(centre + side)
		_pile_positions.append(centre - side)
		t += PILE_SPACING


func _build_piles() -> void:
	var seen := {}
	var positions: Array[Vector2] = []
	for p in _pile_positions:
		if FishingVillagePlan.shelf_distance(p) > -0.2:
			continue
		var key := Vector2i(roundi(p.x * 2.0), roundi(p.y * 2.0))
		if seen.has(key):
			continue
		seen[key] = true
		positions.append(p)
	if positions.is_empty():
		return
	# From just under the deck down to the shelf top, plus the embed.
	var top := FishingVillagePlan.DECK_TOP - DECK_THICKNESS
	var bottom := -FishingIslets.SHELF_TOP_DEPTH - PILE_EMBED
	var length := top - bottom
	var mesh := SuperEgg.build_mesh(Vector3(PILE_RADIUS, length * 0.5, PILE_RADIUS), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	var material := StandardMaterial3D.new()
	material.albedo_color = PILE_COLOR
	material.roughness = 0.8
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.mesh = mesh
	multi.instance_count = positions.size()
	var body := StaticBody3D.new()
	body.name = "Piles"
	add_child(body)
	for i in positions.size():
		var at := _at(positions[i], (top + bottom) * 0.5)
		multi.set_instance_transform(i, Transform3D(Basis(), at))
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = PILE_RADIUS
		cylinder.height = length
		shape.shape = cylinder
		body.add_child(shape)
		shape.global_position = at
	var instance := MultiMeshInstance3D.new()
	instance.name = "PileMesh"
	instance.multimesh = multi
	instance.material_override = material
	CollisionPolicy.mark_decorative(instance)
	add_child(instance)


# ---------------------------------------------------------------------------
# Lights, boats and the shop
# ---------------------------------------------------------------------------

## Lamps for night wayfinding, hung from rope-bound junction posts where the
## spurs leave the spine (the charter allows no lights on poles).
func _build_streetlights() -> void:
	var body := StaticBody3D.new()
	body.name = "JunctionLamps"
	add_child(body)
	body.global_position = _at(Vector2.ZERO, 0.0)
	for lamp: Dictionary in FishingBuildings.JUNCTION_LAMPS:
		StiltKit.lamp_post(body, lamp["at"], FishingVillagePlan.DECK_TOP, lamp["arm"])


func _build_boats() -> void:
	for boat in FishingVillagePlan.BOATS:
		var berth: Rect2 = boat["berth"]
		var long_axis_x := berth.size.x >= berth.size.y
		var node := Node3D.new()
		node.name = str(boat["name"])
		add_child(node)
		node.global_position = _at(berth.get_center(), 0.16)
		node.rotation.y = 0.0 if long_axis_x else PI * 0.5
		var length := maxf(berth.size.x, berth.size.y)
		if boat.get("launch", false):
			# Ivo's roofed cargo launch, built at its own size (4.14).
			node.add_child(FishingBuildings.ferry_launch(length, minf(berth.size.x, berth.size.y)))
			continue
		node.scale = Vector3.ONE * (length / 7.6)
		var hull: Color = _household_color(str(boat["owner"]))
		_build_boat_parts(node, hull)


func _build_boat_parts(boat: Node3D, hull_color: Color) -> void:
	_add_boat_part(boat, Vector3(3.8, 0.32, 0.95), Vector3(0, 0, 0), hull_color, SuperEgg.EPSILON_SOFT)
	_add_boat_part(boat, Vector3(3.25, 0.08, 1.02), Vector3(0, 0.36, 0), hull_color.lightened(0.14), SuperEgg.EPSILON_FLAT)
	_add_boat_part(boat, Vector3(0.75, 0.08, 1.12), Vector3(0, 0.48, 0), Color(0.42, 0.25, 0.12), SuperEgg.EPSILON_FLAT)
	_add_boat_part(boat, Vector3(0.09, 0.82, 0.09), Vector3(-0.75, 0.92, 0), Color(0.3, 0.18, 0.1), SuperEgg.EPSILON_SOFT)


func _add_boat_part(parent: Node3D, semi_axes: Vector3, local_pos: Vector3, color: Color, epsilon: float) -> void:
	var part := SuperEgg.build_part(semi_axes, color, epsilon, epsilon)
	part.position = local_pos
	CollisionPolicy.mark_decorative(part)
	parent.add_child(part)


## Nara's counter on the Venn shop veranda, facing the landing. Her wares
## stand on it; the catalogue is unchanged.
func _build_shop() -> void:
	var venn: Node3D = _built.get("VennHouse")
	if venn != null:
		var wares := venn.get_node("WaresCounter") as Node3D
		FishingBuildings.lay_out_wares(venn, wares.position, 2.6)
		var stand := venn.get_node("VendorStand") as Node3D
		_build_vendor(stand.global_position)
		return
	push_error("FloatingVillage: the Venn house is missing, so Nara has no counter")


## World-space spot for the ocean_kingdom portal: the plan's gate on the portal
## landing, facing north-west with three metres of clear deck behind it.
func get_portal_anchor() -> Vector3:
	var terrain: Node = get_node_or_null("../Terrain")
	var water_y: float = terrain.get_lake_water_level() if terrain != null else 0.0
	return Vector3(CENTER.x, water_y, CENTER.z) + PORTAL_OFFSET + Vector3(0, FishingVillagePlan.DECK_TOP, 0)


## The yaw that turns the gate to face the plan's direction (+Z is forward).
func get_portal_yaw() -> float:
	var facing: Vector2 = FishingVillagePlan.PORTAL_GATE["facing"]
	return atan2(facing.x, facing.y)


## Bakes each finished structure's small static pieces into a few meshes
## (StaticMerge): the village was several thousand separate draw calls. Each
## structure merges on its own, so off-screen buildings are still culled.
## Residents, doors and anything scripted are left as they are.
func _merge_static() -> void:
	for child in get_children():
		if child is Node3D and child.get_script() == null and child.name != "FishingIslets":
			StaticMerge.merge(child as Node3D)


## The village's walking residents (FishingVillagePeople): each spawns where
## their day has them now and walks the decks between home and work. They find
## their footing by probing the decks below them, since the decks stand at
## several heights over water the terrain knows nothing about.
func _build_residents() -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		return
	var offset := Vector2(CENTER.x, CENTER.z)
	var hour := 9.0
	for name_text in FishingVillagePeople.walkers():
		var resident = packed.instantiate()
		resident.name = name_text.replace(" ", "")
		resident.display_name = name_text
		FishingVillagePeople.apply_look(resident, name_text)
		var lines: Array[String] = []
		for line: String in FishingVillagePeople.RESIDENTS[name_text]["lines"]:
			lines.append(line)
		resident.talk_lines = lines
		resident.ground_probe = true
		resident.ground_probe_seed_y = _water + 1.2 + FishingVillagePlan.HOUSE_FLOOR
		resident.set_terrain_reference(_terrain)
		resident.configure_daily_schedule(FishingVillagePeople.world_schedule(name_text, offset))
		var start := FishingVillagePeople.place_at(name_text, hour) + offset
		# Placed before entering the tree: its _ready probes the deck under it.
		resident.position = Vector3(start.x, resident.ground_probe_seed_y, start.y)
		add_child(resident)


func _build_vendor(pos: Vector3) -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		return
	var vendor = packed.instantiate()
	vendor.set_terrain_reference(_terrain)
	vendor.stationary = true
	vendor.is_vendor = true
	vendor.display_name = "Nara Venn"
	vendor.shop_category = "lake"
	var vendor_lines: Array[String] = [
		"The lake keeps what it takes. Best bring a sealed head if you mean to ask it questions.",
		"Throw the helmet into a blorb you trust. Wear that blorb on your head, and it will keep the water out.",
	]
	vendor.vendor_lines = vendor_lines
	FishingVillagePeople.apply_look(vendor, "Nara Venn")
	vendor.fixed_ground_y = pos.y
	vendor.position = pos
	add_child(vendor)
