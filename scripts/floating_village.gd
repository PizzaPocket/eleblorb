class_name FloatingVillage
extends Node3D

## The Crossroads Fishing Village, built from FishingVillagePlan: every deck,
## pile, jetty, gangway, swim exit and berth is placed from that one data file
## (docs/architecture/fishing_village_layout.md). It stands against Anvil Rock
## and Heron Rock (FishingIslets) and is reached by swimming to one of three
## ramps. Houses are owned, programmed placeholders until the architecture kit
## proofs replace them; nothing here is anonymous.

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
const HOUSE_HEIGHT := 3.0
const ROOF_PITCH := deg_to_rad(22.0)
## The Mor houseboat's rest point: 10 Tokoins, the village's inn rate.
const REST_FEE := 10
const REST_WORLD := "outskirts"
const REST_POINT := "fishing_village_houseboat"

var _terrain: Node
var _water := 0.0
var _pile_positions: Array[Vector2] = []
var _roof_index := 0
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


# ---------------------------------------------------------------------------
# Structures
# ---------------------------------------------------------------------------

func _household_color(owner: String) -> Color:
	return FishingVillagePlan.HOUSEHOLD_COLORS[FishingVillagePlan.household_of(owner)]


func _build_structure(structure: Dictionary) -> void:
	var rect: Rect2 = structure["rect"]
	var owner := str(structure["owner"])
	var wall := _household_color(owner)
	var structure_name := str(structure["name"])
	if structure_name in FishingBuildings.BUILT:
		# Built from its design brief, on its own piles (FishingBuildings).
		var built := FishingBuildings.build(structure_name)
		add_child(built)
		built.global_position = _at(FishingBuildings.anchor(structure_name), 0.0)
		_built[structure_name] = built
		return
	match str(structure["kind"]):
		"deck":
			_deck(str(structure["name"]), rect, FishingVillagePlan.DECK_TOP, DECK_COLOR)
			_queue_piles(rect)
			if structure_name in FishingBuildings.DRESSED:
				var dressing := FishingBuildings.dress(structure_name)
				add_child(dressing)
				dressing.global_position = _at(Vector2.ZERO, 0.0)
		"house":
			_deck(str(structure["name"]), rect, FishingVillagePlan.DECK_TOP, DECK_COLOR)
			_house(str(structure["name"]), rect, FishingVillagePlan.DECK_TOP, wall)
			_queue_piles(rect)
		"pavilion":
			_deck(str(structure["name"]), rect, FishingVillagePlan.DECK_TOP, DECK_COLOR)
			_open_roof(str(structure["name"]), rect, FishingVillagePlan.DECK_TOP, wall)
			_queue_piles(rect)
		"deck_shelter":
			_deck(str(structure["name"]), rect, FishingVillagePlan.DECK_TOP, DECK_COLOR)
			var shelter := Rect2(rect.position + Vector2(0.0, 0.0), Vector2(rect.size.x, rect.size.y * 0.5))
			_open_roof(str(structure["name"]) + "Shelter", shelter, FishingVillagePlan.DECK_TOP, wall)
			_queue_piles(rect)
		"pontoon":
			_deck(str(structure["name"]), rect, FishingVillagePlan.FLOAT_DECK, DECK_COLOR.lightened(0.06))
		"houseboat":
			_houseboat(str(structure["name"]), rect, wall)
		"lines":
			_mussel_lines(rect)


## A deck of planks over joists, with one box collider through the shared
## collision policy. `top` is relative to the lake surface.
func _deck(name_text: String, rect: Rect2, top: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = name_text
	add_child(body)
	body.global_position = _at(rect.get_center(), 0.0)
	StiltKit.floor_slab(body, Rect2(-rect.size * 0.5, rect.size), top, color)
	return body


## A placeholder house: walls, a gabled roof along the long axis and a dark
## door panel on the south wall, in the household's colour. The architecture
## kit proofs replace it; its footprint and owner are the plan's.
func _house(name_text: String, rect: Rect2, floor_top: float, wall_color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = name_text + "Walls"
	add_child(body)
	body.global_position = _at(rect.get_center(), floor_top)
	var inner := rect.size - Vector2(1.2, 1.2)
	var wall_size := Vector3(inner.x, HOUSE_HEIGHT, inner.y)
	var walls := SuperEgg.build_part(wall_size * 0.5, wall_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	walls.position.y = HOUSE_HEIGHT * 0.5
	body.add_child(walls)
	CollisionPolicy.add_box(body, walls, wall_size, walls.position, Basis(), false)
	var door := SuperEgg.build_part(Vector3(0.55, 1.05, 0.06), Color(0.16, 0.09, 0.05), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	door.position = Vector3(0.0, 1.05, inner.y * 0.5 + 0.02)
	body.add_child(door)
	CollisionPolicy.mark_decorative(door)
	_gable_roof(body, inner + Vector2(0.9, 0.9), HOUSE_HEIGHT)


func _gable_roof(body: StaticBody3D, footprint: Vector2, base_y: float) -> void:
	var color: Color = TownProps.ROOF_COLORS[_roof_index % TownProps.ROOF_COLORS.size()]
	_roof_index += 1
	var along_x := footprint.x >= footprint.y
	var span := minf(footprint.x, footprint.y)
	var length := maxf(footprint.x, footprint.y)
	var half_width := span * 0.25 / cos(ROOF_PITCH) + 0.25
	for side: float in [-1.0, 1.0]:
		var slab := SuperEgg.build_part(Vector3(half_width, 0.14, length * 0.5), color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		var offset := side * span * 0.25
		var basis := Basis(Vector3(0, 0, 1), -side * ROOF_PITCH)
		var at := Vector3(offset, base_y + 0.55 + (span * 0.25) * tan(ROOF_PITCH) * 0.5, 0.0)
		var full := Basis(Vector3.UP, 0.0 if not along_x else PI * 0.5)
		slab.transform = Transform3D(full * basis, full * at)
		body.add_child(slab)
		CollisionPolicy.add_box(body, slab, Vector3(half_width * 2.0, 0.28, length), slab.position, full * basis, true)


## An open-sided roof on four posts: the pavilion and the catch deck's shelter.
func _open_roof(name_text: String, rect: Rect2, floor_top: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.name = name_text + "Roof"
	add_child(body)
	body.global_position = _at(rect.get_center(), floor_top)
	var post_height := 3.8
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var offset := Vector2(corner.x * (rect.size.x * 0.5 - 0.5), corner.y * (rect.size.y * 0.5 - 0.5))
		var post := SuperEgg.build_part(Vector3(0.18, post_height * 0.5, 0.18), PILE_COLOR.lightened(0.15), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		post.position = Vector3(offset.x, post_height * 0.5, offset.y)
		body.add_child(post)
		CollisionPolicy.add_cylinder(body, post, 0.18, post_height, post.position, false)
	var roof_size := Vector3(rect.size.x + 1.2, 0.5, rect.size.y + 1.2)
	var roof := SuperEgg.build_part(roof_size * 0.5, color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	roof.position.y = post_height + 0.1
	body.add_child(roof)
	CollisionPolicy.add_box(body, roof, roof_size, roof.position, Basis(), true)


func _houseboat(name_text: String, rect: Rect2, wall_color: Color) -> void:
	var float_top := FishingVillagePlan.FLOAT_DECK
	var deck := _deck(name_text, rect, float_top, DECK_COLOR.lightened(0.04))
	var hull_size := Vector3(rect.size.x + 0.6, 1.3, rect.size.y + 0.4)
	var hull := SuperEgg.build_part(hull_size * 0.5, wall_color.darkened(0.35), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	# The deck body stands at the lake surface; the hull's centre sits 0.4 m
	# below it, its top just under the planks.
	hull.position.y = -DECK_THICKNESS - 0.1
	deck.add_child(hull)
	CollisionPolicy.add_box(deck, hull, hull_size, hull.position, Basis(), false)
	# Cabin between the arrival deck at the west end and the cargo deck at the east.
	var cabin := Rect2(rect.position + Vector2(4.0, 0.6), rect.size - Vector2(8.0, 1.2))
	_houseboat_cabin(name_text, cabin, float_top, wall_color)


## The Mor guest houseboat's cabin: the settlement's rest point. A walled room
## with a doorway on the south wall, three berths along the north wall, the
## marine toilet at the south-east corner and Leena by the door. Its wake and
## stand markers are aboard, so resting never leaves the collidable boat.
func _houseboat_cabin(name_text: String, rect: Rect2, floor_top: float, wall_color: Color) -> void:
	const WALL := 0.18
	const DOOR_WIDTH := 1.6
	var body := StaticBody3D.new()
	body.name = name_text + "Cabin"
	add_child(body)
	body.global_position = _at(rect.get_center(), floor_top)
	var half := rect.size * 0.5
	var door_x := -0.5
	var panels: Array[Dictionary] = [
		{"at":Vector3(0.0, HOUSE_HEIGHT * 0.5, -half.y), "size":Vector3(rect.size.x, HOUSE_HEIGHT, WALL)},
		{"at":Vector3(-half.x, HOUSE_HEIGHT * 0.5, 0.0), "size":Vector3(WALL, HOUSE_HEIGHT, rect.size.y)},
		{"at":Vector3(half.x, HOUSE_HEIGHT * 0.5, 0.0), "size":Vector3(WALL, HOUSE_HEIGHT, rect.size.y)},
	]
	var left_len := (door_x - DOOR_WIDTH * 0.5) + half.x
	var right_len := half.x - (door_x + DOOR_WIDTH * 0.5)
	panels.append({"at":Vector3(-half.x + left_len * 0.5, HOUSE_HEIGHT * 0.5, half.y), "size":Vector3(left_len, HOUSE_HEIGHT, WALL)})
	panels.append({"at":Vector3(half.x - right_len * 0.5, HOUSE_HEIGHT * 0.5, half.y), "size":Vector3(right_len, HOUSE_HEIGHT, WALL)})
	for panel in panels:
		var size: Vector3 = panel["size"]
		var mesh := SuperEgg.build_part(size * 0.5, wall_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		mesh.position = panel["at"]
		body.add_child(mesh)
		CollisionPolicy.add_box(body, mesh, size, mesh.position, Basis(), false)
	# Lintel over the doorway so the south wall reads as one wall.
	var lintel_size := Vector3(DOOR_WIDTH, HOUSE_HEIGHT - 2.3, WALL)
	var lintel := SuperEgg.build_part(lintel_size * 0.5, wall_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	lintel.position = Vector3(door_x, 2.3 + lintel_size.y * 0.5, half.y)
	body.add_child(lintel)
	CollisionPolicy.add_box(body, lintel, lintel_size, lintel.position, Basis(), false)
	_gable_roof(body, rect.size + Vector2(0.9, 0.9), HOUSE_HEIGHT)

	# Three berths along the north wall, heads to the wall.
	var berth_colors: Array[Color] = [Color(0.42, 0.35, 0.68), Color(0.32, 0.46, 0.66), Color(0.62, 0.34, 0.30)]
	var first_bed := Vector3.ZERO
	for i in 3:
		var bed := TownProps.build_bed(berth_colors[i])
		bed.name = "PartyBed%d" % (i + 1)
		bed.position = Vector3(-half.x + 1.2 + float(i) * 1.6, 0.0, -half.y + 1.28)
		body.add_child(bed)
		if i == 0:
			first_bed = bed.position
	# The contained marine toilet in the south-east corner, back to the wall.
	var toilet := ToiletFixtures.build("marine")
	toilet.name = "MarineToilet"
	toilet.position = Vector3(half.x - 0.8, 0.0, half.y - 0.55)
	body.add_child(toilet)

	var wake := Marker3D.new()
	wake.name = "WakeMarker"
	wake.position = first_bed + Vector3(0.0, 0.88, 0.0)
	body.add_child(wake)
	var stand := Marker3D.new()
	stand.name = "StandMarker"
	stand.position = Vector3(door_x, 0.1, half.y - 1.6)
	body.add_child(stand)
	_build_keeper(body, wake, stand, Vector3(half.x - 2.4, 0.0, 0.5))


## Leena keeps the stores and the rest point (10 Tokoins, through the shared
## transaction UI, as in every inn).
func _build_keeper(body: StaticBody3D, wake: Marker3D, stand: Marker3D, local_position: Vector3) -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		return
	var keeper = packed.instantiate()
	keeper.display_name = "Leena Mor"
	keeper.stationary = true
	keeper.is_female = true
	keeper.facing_degrees = 180.0
	keeper.fixed_ground_y = body.global_position.y
	keeper.skin_color = Color(0.58, 0.40, 0.28)
	keeper.shirt_color = FishingVillagePlan.HOUSEHOLD_COLORS["Mor"]
	keeper.hair_color = Color(0.12, 0.09, 0.07)
	keeper.hair_style = FigureHair.STYLE_BUN
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
		stand.global_position + Vector3(0, 0, 2.5)
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
	var counter_at := Vector2(-31.0, -9.6)
	_build_lake_shop_display(_at(counter_at, FishingVillagePlan.DECK_TOP + 0.02))
	_build_vendor(_at(counter_at + Vector2(0.0, -1.6), FishingVillagePlan.DECK_TOP + 0.2))


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


## Every item sold by the lake vendor is represented on a low dock counter,
## making the shop legible before its dialogue is opened.
func _build_lake_shop_display(pos: Vector3) -> void:
	var display := StaticBody3D.new()
	display.name = "LakeVendorWares"
	display.position = pos
	add_child(display)
	# A two-row display keeps the full lake assortment on the tabletop even
	# as the catalog grows; the former single row overflowed after four items.
	const COLUMNS := 3
	const ITEM_SPACING := 0.82
	var purchasable_items: Array[Dictionary] = []
	for raw_item in ShopCatalog.get_items_for_shop("lake"):
		var item: Dictionary = raw_item
		if item.get("purchasable", false):
			purchasable_items.append(item)
	var rows := maxi(1, int(ceil(float(purchasable_items.size()) / COLUMNS)))
	var counter_half_width := 1.55
	var counter_half_depth := maxf(0.68, 0.48 + float(rows - 1) * ITEM_SPACING * 0.5)
	var counter := SuperEgg.build_part(Vector3(counter_half_width, 0.34, counter_half_depth), Color(0.38, 0.22, 0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	counter.position.y = 0.34
	display.add_child(counter)
	var counter_collision := CollisionShape3D.new()
	var counter_shape := BoxShape3D.new()
	counter_shape.size = Vector3(counter_half_width * 2.0, 0.68, counter_half_depth * 2.0)
	counter_collision.shape = counter_shape
	counter_collision.position.y = 0.34
	display.add_child(counter_collision)
	for item_index in purchasable_items.size():
		var item: Dictionary = purchasable_items[item_index]
		var visual: Node3D = (item["build_visual"] as Callable).call(1.0) as Node3D
		var column := item_index % COLUMNS
		var row := item_index / COLUMNS
		visual.position = Vector3((float(column) - 1.0) * ITEM_SPACING, 0.9, (float(row) - float(rows - 1) * 0.5) * ITEM_SPACING)
		display.add_child(visual)


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
	vendor.skin_color = Color(0.48, 0.31, 0.2)
	vendor.shirt_color = Color(0.12, 0.35, 0.43)
	vendor.hair_color = Color(0.08, 0.06, 0.04)
	vendor.fixed_ground_y = pos.y
	vendor.position = pos
	add_child(vendor)
