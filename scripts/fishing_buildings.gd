class_name FishingBuildings
extends RefCounted

## The fishing village's buildings, each built from its approved design brief
## (docs/architecture/fishing_village_building_designs.md) and interior brief
## (fishing_village_interiors.md) out of the shared StiltKit and StiltRoofs.
## A builder returns one StaticBody3D whose origin is the building's plan
## anchor at the lake surface W; FloatingVillage places it with `anchor()`.
## The drawings (plan, section, roof) for each are in the design brief.

## Buildings that have left the placeholder stage. FloatingVillage builds these
## instead of its owned placeholder boxes.
const BUILT := ["VennHouse", "SenHouse", "CisternHouse", "NetShed", "Pavilion", "AranHouse"]

const SHELF_Y := -3.2 - 0.4
const HOUSE_FLOOR := FishingVillagePlan.HOUSE_FLOOR
const DECK_TOP := FishingVillagePlan.DECK_TOP


static func build(name_text: String) -> StaticBody3D:
	match name_text:
		"VennHouse":
			return venn_house()
		"SenHouse":
			return sen_house()
		"CisternHouse":
			return cistern_house()
		"NetShed":
			return net_shed()
		"Pavilion":
			return pavilion()
		"AranHouse":
			return aran_house()
	return null


## Plan point the builder's origin stands on.
static func anchor(name_text: String) -> Vector2:
	match name_text:
		"VennHouse":
			return VENN_ORIGIN
		"SenHouse":
			return SEN_ORIGIN
		"CisternHouse":
			return CISTERN_ORIGIN
		"NetShed":
			return NET_SHED_ORIGIN
		"Pavilion":
			return PAVILION_ORIGIN
		"AranHouse":
			return ARAN_ORIGIN
	return Vector2.ZERO


static func _household(owner: String) -> Color:
	return FishingVillagePlan.HOUSEHOLD_COLORS[FishingVillagePlan.household_of(owner)]


# ---------------------------------------------------------------------------
# 4.2 Venn house and lake shop (Nara, Mateo, Lio)
# ---------------------------------------------------------------------------
# Body frame: origin at the main house's centre, plan (-29.5, -17.75), at W.
# Main house x -4.5..4.5, z -2.25..2.25: three 3 m bays (Lio's room, the living
# room and kitchen, Nara and Mateo's room). Shop veranda z 2.25..4.75 under a
# pent; its east bay is the enclosed dive-gear store. Threshold ramp z 4.75..5.75
# down to the arrival landing's deck. See the design brief, section 4.2.

const VENN_ORIGIN := Vector2(-29.5, -17.75)
const VENN_HALF := Vector2(4.5, 2.25)
const VENN_VERANDA_Z := 4.75
const VENN_RAMP_Z := 5.75
const VENN_SHUTTER := Color(0.82, 0.58, 0.22)
## The pent's underside where it meets the house wall, above the floor.
const VENN_PENT_AT_WALL := 2.75


static func venn_house() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "VennHouse"
	var f := HOUSE_FLOOR
	var teal := _household("Nara")
	var hx := VENN_HALF.x
	var hz := VENN_HALF.y
	var vz := VENN_VERANDA_Z
	var plate := f + StiltKit.RING_BEAM
	var pent_wall := f + VENN_PENT_AT_WALL
	var pent_grad := Vector2(0.0, -tan(StiltRoofs.PENT_PITCH))
	var pent_plane := {"at": Vector2(0.0, hz), "y": pent_wall, "grad": pent_grad}

	# Substructure: piles on the 3 m grid under every bay line, floor beams
	# across each row, one plank floor for the house, veranda and store.
	var xs: Array[float] = [-hx, -1.5, 1.5, hx]
	var rows: Array = []
	for z: float in [-hz, 0.0, hz, vz]:
		var row: Array[Vector2] = []
		for x in xs:
			row.append(Vector2(x, z))
		rows.append(row)
		StiltKit.beam(body, Vector2(-hx - 0.1, z), Vector2(hx + 0.1, z), f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH * 0.5, Vector2(0.11, StiltKit.BEAM_DEPTH * 0.5))
	StiltKit.piles(body, rows, f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH, SHELF_Y)
	StiltKit.floor_slab(body, Rect2(-hx, -hz, hx * 2.0, vz + hz), f)

	# Main house walls. The front door is centred on the south wall, in the
	# living room; every room has a window; the north wall faces the rock.
	var no_openings: Array[Dictionary] = []
	StiltKit.wall(body, Vector2(-hx, hz), Vector2(hx, hz), Vector2(0, 1), f, StiltKit.RING_BEAM,
		# A pair of narrow leaves: one 1.2 m leaf swinging in would cross the way to
		# one of the two side doors in a 3 m living room.
		[StiltKit.door(Vector2(0.0, hz), StiltKit.DOOR_TOP, 2), StiltKit.window(Vector2(-3.0, hz))], teal, VENN_SHUTTER)
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(0, -1), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-3.0, -hz)), StiltKit.window(Vector2(-0.75, -hz)), StiltKit.window(Vector2(3.25, -hz))], teal, VENN_SHUTTER)
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(-hx, hz), Vector2(-1, 0), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-hx, 0.0))], teal, VENN_SHUTTER)
	StiltKit.wall(body, Vector2(hx, -hz), Vector2(hx, hz), Vector2(1, 0), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(hx, 0.6))], teal, VENN_SHUTTER)
	# Partitions on the bay lines, doors near the front so the living room's
	# back wall stays free for the brazier and table. Lio's room lies west of
	# x -1.5 (drawn south to north, so its door swings west into it); Nara and
	# Mateo's lies east of x 1.5 (drawn north to south).
	StiltKit.partition(body, Vector2(-1.5, hz), Vector2(-1.5, -hz), f, StiltKit.RING_BEAM, [1.25])
	StiltKit.partition(body, Vector2(1.5, -hz), Vector2(1.5, hz), f, StiltKit.RING_BEAM, [3.25])
	StiltKit.ceiling(body, Rect2(-hx, -hz, hx * 2.0, hz * 2.0), plate)

	# Frame: posts on every bay line and mid-end, ring beam at the plate.
	for x in xs:
		for z: float in [-hz, hz]:
			StiltKit.post(body, Vector2(x, z), f - StiltKit.FLOOR_THICKNESS, plate)
	for x: float in [-hx, hx]:
		StiltKit.post(body, Vector2(x, 0.0), f - StiltKit.FLOOR_THICKNESS, plate)
	var corners: Array[Vector2] = [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	for i in 4:
		StiltKit.beam(body, corners[i], corners[(i + 1) % 4], plate - 0.1, Vector2(0.12, 0.1))

	# The dive-gear store: the veranda's east bay, enclosed, door onto the
	# veranda. Its walls rise to the pent's underside.
	var store := Rect2(1.5, hz, 3.0, vz - hz)
	StiltKit.wall(body, Vector2(1.5, hz), Vector2(1.5, vz), Vector2(-1, 0), f, VENN_PENT_AT_WALL,
		[StiltKit.door(Vector2(1.5, (hz + vz) * 0.5), 2.25)], teal, VENN_SHUTTER, pent_plane)
	StiltKit.wall(body, Vector2(1.5, vz), Vector2(hx, vz), Vector2(0, 1), f, VENN_PENT_AT_WALL,
		no_openings, teal, VENN_SHUTTER, pent_plane)
	StiltKit.wall(body, Vector2(hx, hz), Vector2(hx, vz), Vector2(1, 0), f, VENN_PENT_AT_WALL,
		no_openings, teal, VENN_SHUTTER, pent_plane)

	# Veranda: added when Nara took over the trade, so its posts are paler
	# timber in her household's ochre. The two posts either side of the way up
	# from the landing are rope-bound.
	var pent_at_edge := pent_wall + pent_grad.y * (vz - hz)
	for x in xs:
		StiltKit.post(body, Vector2(x, vz), f - StiltKit.FLOOR_THICKNESS, pent_at_edge, VENN_SHUTTER.lerp(StiltKit.TIMBER_PALE, 0.4), absf(x) < 2.0)
	StiltKit.beam(body, Vector2(-hx, vz), Vector2(hx, vz), pent_at_edge - 0.1, Vector2(0.1, 0.1))
	StiltKit.rail(body, Vector2(-hx, hz + 0.2), Vector2(-hx, vz - 0.2), f)

	# Roofs: a hip over the main house (ridge east to west, teal ridge cap), a
	# pent over the veranda tucked under its south eave, falling south.
	StiltRoofs.hip(body, VENN_HALF, plate, StiltKit.SHINGLE, teal)
	StiltRoofs.pent(body, Rect2(-hx - 0.3, hz, hx * 2.0 + 0.6, vz - hz + 0.25), pent_wall + StiltRoofs.THICKNESS / cos(StiltRoofs.PENT_PITCH), Vector3(0, 0, 1), StiltKit.SHINGLE.lightened(0.05))
	var gutter_y := pent_wall + pent_grad.y * (vz + 0.25 - hz) - 0.08
	# The pent drains west to a downpipe beyond the ramp's edge and a jar on the
	# landing beside the counter's end.
	var jar_at := Vector2(-hx + 0.2, VENN_RAMP_Z + 0.5)
	StiltKit.gutter(body, Vector2(-hx - 0.3, vz + 0.27), Vector2(hx + 0.3, vz + 0.27), gutter_y, Vector2(-hx - 0.2, vz + 0.27), jar_at, DECK_TOP + 0.8)
	StiltKit.rain_jar(body, jar_at, DECK_TOP, Color(0.24, 0.42, 0.40))

	# The threshold: a broad ramp from the landing's deck up 0.25 m to the
	# veranda floor, across the landing's width of the frontage.
	StiltKit.ramp(body, Vector2(-1.5, VENN_RAMP_Z), Vector2(-1.5, vz), DECK_TOP, f, 6.0)

	# Circulation the clearance audit walks: up from the landing, through the
	# front door, into each room and the store.
	ClearZones.add_lane(body, "landing to front door", [Vector3(0.0, f, vz - 0.6), Vector3(0.0, f, hz + 0.6)], 0.55)
	ClearZones.add_lane(body, "through the front door", [Vector3(0.0, f, hz + 0.6), Vector3(0.0, f, 1.2)])
	ClearZones.add_lane(body, "front door to Lio's door", [Vector3(0.0, f, 1.2), Vector3(-0.9, f, 1.05), Vector3(-2.2, f, 1.0)])
	ClearZones.add_lane(body, "front door to the bedroom door", [Vector3(0.0, f, 1.2), Vector3(0.9, f, 1.05), Vector3(2.2, f, 1.0)])
	ClearZones.add_lane(body, "veranda to the store", [Vector3(-0.6, f, 4.1), Vector3(0.9, f, 3.5), Vector3(2.3, f, 3.5)])

	_venn_interior(body, f, teal)
	_venn_shop(body, f)
	return body


static func _venn_interior(body: StaticBody3D, f: float, teal: Color) -> void:
	var layout := RoomLayout.new(body, VENN_HALF - Vector2(0.08, 0.08))
	layout.base_y = f
	var inner_z := VENN_HALF.y - 0.08

	# Living room and kitchen (x -1.5..1.5): the clay brazier and its hood in
	# the north-east corner, venting to the ridge; a low table with floor
	# cushions; crockery shelves; the rope chest.
	var brazier_at := Vector2(0.8, -inner_z + 0.4)
	ClearZones.add(body, "brazier", "fire", brazier_at, Vector2(0, 1), 0.4, 0.75, 0.45, f, f + 1.6)
	layout.reserve(brazier_at, Vector2(0.4, 0.4))
	_brazier(body, Vector3(brazier_at.x, f, brazier_at.y), f + StiltKit.RING_BEAM)
	if not layout.at_any([{"pos": Vector2(0.0, -0.45), "yaw": 0.0}], 0.45, 0.3, 0.0, "low table", 0.5).is_empty():
		_low_table(body, Vector3(0.0, f, -0.45), teal)
	var shelf := layout.at_any([{"pos": Vector2(-1.25, -0.85), "yaw": StiltKit.yaw_back_to(Vector2(-1, 0))}], 0.55, 0.17, 0.5, "crockery shelf")
	if not shelf.is_empty():
		Furnishings.shelf(body, Vector3(-1.25, f, -0.85), shelf["yaw"], 1.1, 3, "crocks")
	var chest := layout.at_any([{"pos": Vector2(1.1, -0.45), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.45, 0.28, 0.35, "rope chest", 0.6)
	if not chest.is_empty():
		Furnishings.chest(body, Vector3(1.1, f, -0.45), chest["yaw"], Furnishings.OAK_DARK, 0.9)
		# Mateo's chisels in a wrapped roll, on the chest.
		Furnishings.piece(body, Vector3(0.22, 0.05, 0.06), Color(0.42, 0.30, 0.22), Vector3(1.1, f + 0.62, -0.45), PI * 0.5, false, SuperEgg.EPSILON_SOFT)
	Furnishings.rug(body, Vector3(0.0, f, -0.5), 0.0, Vector2(1.9, 1.5), teal.darkened(0.1))
	# A child's drawing of a ferry pinned above the brazier, and pegs by the door.
	Furnishings.piece(body, Vector3(0.22, 0.16, 0.01), Color(0.92, 0.88, 0.76), Vector3(0.2, f + 1.75, -inner_z + 0.02))
	Furnishings.piece(body, Vector3(0.12, 0.05, 0.012), Color(0.72, 0.42, 0.22), Vector3(0.2, f + 1.72, -inner_z + 0.035))
	Furnishings.peg_rail(body, Vector3(-0.95, f, inner_z - 0.03), PI, 0.7)
	Furnishings.hanging_lamp(body, Vector3(0.0, f + 2.55, -0.4), 0.7, 5.0)

	# Nara and Mateo's room (x 1.5..4.5): the bed head to the north wall under
	# its window, the sea chest at the foot with its hinge to the bed, oilskins
	# on pegs, the hot-night hammock folded over a rail.
	if not layout.at_any([{"pos": Vector2(3.3, -inner_z + 1.3), "yaw": 0.0}], 0.8, 1.2, 0.0, "Nara and Mateo's bed", 0.6).is_empty():
		var bed := TownProps.build_bed(Color(0.62, 0.34, 0.30))
		bed.position = Vector3(3.3, f, -inner_z + 1.3)
		body.add_child(bed)
	if not layout.at_any([{"pos": Vector2(3.3, 0.68), "yaw": PI}], 0.45, 0.25, 0.0, "sea chest", 0.6).is_empty():
		Furnishings.chest(body, Vector3(3.3, f, 0.68), PI, Furnishings.OAK, 0.9)
	Furnishings.peg_rail(body, Vector3(4.39, f, -1.5), StiltKit.yaw_back_to(Vector2(1, 0)), 0.9)
	Furnishings.piece(body, Vector3(0.6, 0.02, 0.02), Furnishings.OAK_DARK, Vector3(3.3, f + 1.55, inner_z - 0.06))
	Furnishings.piece(body, Vector3(0.55, 0.2, 0.025), Color(0.82, 0.74, 0.56), Vector3(3.3, f + 1.36, inner_z - 0.08), 0.0, false, SuperEgg.EPSILON_SOFT)
	Furnishings.hanging_lamp(body, Vector3(3.0, f + 2.55, 0.2), 0.5, 4.0)

	# Lio's room (x -4.5..-1.5): his bed head to the north wall, his lamp hung in
	# the west window where the slip yard can see it, a rack of practice knots,
	# his shells graded by size.
	if not layout.at_any([{"pos": Vector2(-3.25, -inner_z + 1.3), "yaw": 0.0}], 0.8, 1.2, 0.0, "Lio's bed", 0.6).is_empty():
		var lio_bed := TownProps.build_bed(Color(0.30, 0.50, 0.62))
		lio_bed.position = Vector3(-3.25, f, -inner_z + 1.3)
		body.add_child(lio_bed)
	Furnishings.hanging_lamp(body, Vector3(-4.05, f + 2.15, 0.0), 0.6, 4.5)
	var shell_shelf := layout.at_any([{"pos": Vector2(-4.25, 1.45), "yaw": StiltKit.yaw_back_to(Vector2(-1, 0))}], 0.5, 0.15, 0.5, "shell shelf", 1.2)
	if not shell_shelf.is_empty():
		_shell_shelf(body, Vector3(-4.27, f, 1.45))
	_knot_rack(body, Vector3(-3.0, f, inner_z - 0.03))
	if not layout.at_any([{"pos": Vector2(-2.2, -0.4), "yaw": 0.0}], 0.25, 0.25, 0.0, "Lio's stool", 0.5).is_empty():
		Furnishings.stool(body, Vector3(-2.2, f, -0.4))

	for failure in layout.failures:
		push_warning("VennHouse interior: " + failure)

	# The dive-gear store (veranda east bay x 1.5..4.5, z 2.25..4.75): a drying
	# rack of suits, three helmets on a shelf, the bench with a helmet housing in
	# pieces (Mateo builds it, Rian seals it).
	var sz := VENN_HALF.y
	Furnishings.piece(body, Vector3(0.3, 0.42, 0.75), Furnishings.OAK, Vector3(4.12, f + 0.42, sz + 1.25), 0.0, true)
	for i in 3:
		Furnishings.piece(body, Vector3(0.11, 0.1, 0.11), Color(0.62, 0.52, 0.30).darkened(0.08 * float(i)), Vector3(4.05, f + 0.94, sz + 0.75 + 0.45 * float(i)), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.75, 0.025, 0.14), Furnishings.OAK_DARK, Vector3(3.3, f + 1.55, sz + 0.2))
	for i in 3:
		Furnishings.piece(body, Vector3(0.17, 0.17, 0.17), Color(0.70, 0.56, 0.30).lightened(0.05 * float(i)), Vector3(2.75 + 0.55 * float(i), f + 1.75, sz + 0.2), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.7, 0.02, 0.02), Furnishings.OAK_DARK, Vector3(3.3, f + 1.9, VENN_VERANDA_Z - 0.25))
	for i in 3:
		Furnishings.piece(body, Vector3(0.18, 0.55, 0.03), Color(0.24, 0.30, 0.32).lightened(0.06 * float(i)), Vector3(2.85 + 0.45 * float(i), f + 1.32, VENN_VERANDA_Z - 0.26), 0.0, false, SuperEgg.EPSILON_SOFT)
	Furnishings.hanging_lamp(body, Vector3(3.0, f + 2.05, sz + 1.25), 0.4, 3.5)


## The shop counter along the veranda's south edge between the west posts,
## facing the landing, and Nara's things behind it.
static func _venn_shop(body: StaticBody3D, f: float) -> void:
	var counter_at := Vector3(-3.0, f, VENN_VERANDA_Z - 0.55)
	# Furnishings' counter turns its customer face to local -Z, its back to +Z;
	# the customers stand on the landing to the south.
	Furnishings.counter(body, counter_at, PI, 2.6, false)
	var wares := Marker3D.new()
	wares.name = "WaresCounter"
	wares.position = counter_at + Vector3(0.0, 1.08, 0.0)
	body.add_child(wares)
	var stand := Marker3D.new()
	stand.name = "VendorStand"
	stand.position = Vector3(-3.0, f, VENN_HALF.y + 0.75)
	body.add_child(stand)
	# Her stool for slow hours, a helmet on a peg behind her, a row of knotted
	# cords (one for each dive that went wrong) on the post, the call bell.
	Furnishings.stool(body, Vector3(-4.1, f, VENN_HALF.y + 0.55))
	Furnishings.piece(body, Vector3(0.18, 0.18, 0.18), Color(0.70, 0.56, 0.30), Vector3(-2.2, f + 1.85, VENN_HALF.y + 0.18), 0.0, false, 2.2)
	for i in 5:
		# Hung from the post's inner face, below the pent (2.0 m clear here).
		Furnishings.piece(body, Vector3(0.012, 0.25, 0.012), StiltKit.ROPE.darkened(0.1), Vector3(-1.5 + 0.03 * float(i - 2), f + 1.55, VENN_VERANDA_Z - 0.16), 0.0, false)
		Furnishings.piece(body, Vector3(0.03, 0.03, 0.03), StiltKit.ROPE.darkened(0.25), Vector3(-1.5 + 0.03 * float(i - 2), f + 1.38 + 0.06 * float(i % 3), VENN_VERANDA_Z - 0.16), 0.0, false, 2.0)
	Furnishings.piece(body, Vector3(0.08, 0.09, 0.08), Color(0.78, 0.62, 0.26), Vector3(-1.72, f + 1.75, VENN_VERANDA_Z - 0.3), 0.0, false, 2.0)
	# Lamps hang from the pent's rafters near the wall, where it is highest.
	Furnishings.hanging_lamp(body, Vector3(-3.0, f + 1.9, VENN_HALF.y + 0.9), 0.6, 5.0)
	Furnishings.hanging_lamp(body, Vector3(0.0, f + 1.95, VENN_HALF.y + 0.7), 0.5, 4.5)


## The lake wares laid out on the counter: two rows of three, in catalogue
## order, so the shop reads before its dialogue opens.
static func lay_out_wares(body: Node3D, at: Vector3, length: float) -> void:
	var items: Array[Dictionary] = []
	for raw_item in ShopCatalog.get_items_for_shop("lake"):
		var item: Dictionary = raw_item
		if item.get("purchasable", false):
			items.append(item)
	var columns := maxi(int(ceil(float(items.size()) / 2.0)), 1)
	var spacing := minf(0.82, (length - 0.3) / float(columns))
	for i in items.size():
		var visual: Node3D = (items[i]["build_visual"] as Callable).call(1.0) as Node3D
		var column := i % columns
		var row := i / columns
		visual.position = at + Vector3((float(column) - float(columns - 1) * 0.5) * spacing, 0.0, (float(row) - 0.5) * 0.3)
		body.add_child(visual)


# ---------------------------------------------------------------------------
# 4.4 Sen house, clinic and school room (Asha, Rian)
# ---------------------------------------------------------------------------
# Body frame: origin at the range's centre, plan (-15.5, -16), at W. Range
# x -4.5..4.5, z -4..4 under one hip: public front row z 0.4..4 (records,
# clinic, school room), private corridor z -1.0..0.4, private back row z -4..-1
# (Asha, Rian, kitchen and wash). Porch z 4..6 under a pent; threshold ramp
# z 6..7 onto the Sen spur. See the design brief, section 4.4.

const SEN_ORIGIN := Vector2(-15.5, -16.0)
const SEN_HALF := Vector2(4.5, 4.0)
const SEN_CORRIDOR := Vector2(-1.0, 0.4)
const SEN_PORCH_Z := 6.0
const SEN_SHUTTER := Color(0.90, 0.86, 0.74)
const SEN_PENT_AT_WALL := 2.75
## Door and window positions along the front, chosen so every frame clears its
## neighbour and the bay partitions (the brief's numbers did not; see 4.4).
const SEN_FAMILY_DOOR := -3.0
const SEN_CLINIC_DOOR := -0.45
const SEN_CLINIC_WINDOW := 0.8
const SEN_SCHOOL_WINDOW := 2.15
const SEN_SCHOOL_DOOR := 3.5


static func sen_house() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "SenHouse"
	var f := HOUSE_FLOOR
	var violet := _household("Asha")
	var hx := SEN_HALF.x
	var hz := SEN_HALF.y
	var pz := SEN_PORCH_Z
	var plate := f + StiltKit.RING_BEAM
	var pent_wall := f + SEN_PENT_AT_WALL
	var pent_grad := Vector2(0.0, -tan(StiltRoofs.PENT_PITCH))
	var xs: Array[float] = [-hx, -1.5, 1.5, hx]

	# Substructure: piles at the bay lines on every row the brief gives.
	var rows: Array = []
	for z: float in [-hz, SEN_CORRIDOR.x, SEN_CORRIDOR.y, hz, pz]:
		var row: Array[Vector2] = []
		for x in xs:
			row.append(Vector2(x, z))
		rows.append(row)
		StiltKit.beam(body, Vector2(-hx - 0.1, z), Vector2(hx + 0.1, z), f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH * 0.5, Vector2(0.11, StiltKit.BEAM_DEPTH * 0.5))
	StiltKit.piles(body, rows, f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH, SHELF_Y)
	StiltKit.floor_slab(body, Rect2(-hx, -hz, hx * 2.0, pz + hz), f)

	# Outside walls. Three doors off the porch: the family's, the clinic's
	# (knot-carved) and the school room's. Back rooms light from the north.
	var front: Array[Dictionary] = [
		StiltKit.door(Vector2(SEN_FAMILY_DOOR, hz)), StiltKit.door(Vector2(SEN_CLINIC_DOOR, hz)),
		StiltKit.window(Vector2(SEN_CLINIC_WINDOW, hz)), StiltKit.window(Vector2(SEN_SCHOOL_WINDOW, hz)),
		StiltKit.door(Vector2(SEN_SCHOOL_DOOR, hz)),
	]
	StiltKit.wall(body, Vector2(-hx, hz), Vector2(hx, hz), Vector2(0, 1), f, StiltKit.RING_BEAM, front, violet, SEN_SHUTTER)
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(0, -1), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-2.3, -hz)), StiltKit.window(Vector2(0.0, -hz)), StiltKit.window(Vector2(3.0, -hz))], violet, SEN_SHUTTER)
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(-hx, hz), Vector2(-1, 0), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-hx, 2.4))], violet, SEN_SHUTTER)
	StiltKit.wall(body, Vector2(hx, -hz), Vector2(hx, hz), Vector2(1, 0), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(hx, -2.5))], violet, SEN_SHUTTER)

	# Partitions. The corridor's south wall has only the family archway; its
	# north wall has a door into each back room (drawn west to east, so each
	# leaf swings north into its room). The two front partitions are drawn
	# north to south so their doors swing east: records into the clinic, the
	# clinic into the school room.
	var cs := SEN_CORRIDOR.y
	var cn := SEN_CORRIDOR.x
	var no_doors: Array[float] = []
	TownProps.build_interior_wall(body, Vector2(-hx, cs), Vector2(hx, cs), f, no_doors, StiltKit.TIMBER_PALE, StiltKit.TIMBER_DARK, StiltKit.RING_BEAM, true, [SEN_FAMILY_DOOR + hx])
	StiltKit.partition(body, Vector2(-hx, cn), Vector2(hx, cn), f, StiltKit.RING_BEAM, [1.5, 4.5, 7.5])
	StiltKit.partition(body, Vector2(-1.5, cs), Vector2(-1.5, hz), f, StiltKit.RING_BEAM, [1.8])
	StiltKit.partition(body, Vector2(1.5, cs), Vector2(1.5, hz), f, StiltKit.RING_BEAM, [1.8])
	StiltKit.partition(body, Vector2(-1.5, -hz), Vector2(-1.5, cn), f, StiltKit.RING_BEAM, no_doors)
	StiltKit.partition(body, Vector2(1.5, -hz), Vector2(1.5, cn), f, StiltKit.RING_BEAM, no_doors)
	StiltKit.ceiling(body, Rect2(-hx, -hz, hx * 2.0, hz * 2.0), plate)

	# Frame: posts on the bay lines front and back and two on each end wall.
	for x in xs:
		for z: float in [-hz, hz]:
			StiltKit.post(body, Vector2(x, z), f - StiltKit.FLOOR_THICKNESS, plate)
	for x: float in [-hx, hx]:
		for z: float in [-1.0, 1.4]:
			StiltKit.post(body, Vector2(x, z), f - StiltKit.FLOOR_THICKNESS, plate)
	var corners: Array[Vector2] = [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	for i in 4:
		StiltKit.beam(body, corners[i], corners[(i + 1) % 4], plate - 0.1, Vector2(0.12, 0.1))

	# Porch: added later for the clinic queue, its posts paler. The two either
	# side of the way up from the spur are rope-bound; rails close the open
	# edges except the ramp's opening.
	var pent_at_edge := pent_wall + pent_grad.y * (pz - hz)
	for x in xs:
		StiltKit.post(body, Vector2(x, pz), f - StiltKit.FLOOR_THICKNESS, pent_at_edge, StiltKit.TIMBER_PALE, absf(x) < 2.0)
	StiltKit.beam(body, Vector2(-hx, pz), Vector2(hx, pz), pent_at_edge - 0.1, Vector2(0.1, 0.1))
	StiltKit.rail(body, Vector2(-hx + 0.15, pz), Vector2(-1.65, pz), f)
	StiltKit.rail(body, Vector2(1.65, pz), Vector2(hx - 0.15, pz), f)
	StiltKit.rail(body, Vector2(-hx, hz + 0.2), Vector2(-hx, pz - 0.15), f)
	StiltKit.rail(body, Vector2(hx, hz + 0.2), Vector2(hx, pz - 0.15), f)
	StiltKit.ramp(body, Vector2(SEN_CLINIC_DOOR + 0.45, pz + 1.0), Vector2(SEN_CLINIC_DOOR + 0.45, pz), DECK_TOP, f, 2.6)

	# Roofs: a hip over the 9 x 8 range (a short ridge, violet cap), the pent
	# over the porch under its south eave. The kitchen flue leaves by the hip's
	# east slope.
	StiltRoofs.hip(body, SEN_HALF, plate, StiltKit.SHINGLE, violet)
	StiltRoofs.pent(body, Rect2(-hx - 0.3, hz, hx * 2.0 + 0.6, pz - hz + 0.25), pent_wall + StiltRoofs.THICKNESS / cos(StiltRoofs.PENT_PITCH), Vector3(0, 0, 1), StiltKit.SHINGLE.lightened(0.05))
	var gutter_y := pent_wall + pent_grad.y * (pz + 0.25 - hz) - 0.08
	var jar_at := Vector2(hx - 0.45, pz - 0.5)
	StiltKit.gutter(body, Vector2(-hx - 0.3, pz + 0.27), Vector2(hx + 0.3, pz + 0.27), gutter_y, Vector2(hx + 0.2, pz + 0.27), jar_at, f + 0.8)
	StiltKit.rain_jar(body, jar_at, f, Color(0.42, 0.36, 0.56))

	# The knot mark carved beside the clinic door.
	var knot := SuperEgg.build_part(Vector3(0.14, 0.14, 0.03), StiltKit.TIMBER_DARK, 2.0, 2.0)
	knot.position = Vector3(SEN_CLINIC_DOOR - 0.9, f + 1.9, hz + 0.1)
	body.add_child(knot)
	CollisionPolicy.mark_decorative(knot)
	StiltKit.rope_binding(body, Vector2(SEN_CLINIC_DOOR - 0.9, hz + 0.1), f + 1.82, f + 1.98, 0.08)

	# Routes the audit walks: the patient, the pupil and the family's own way.
	ClearZones.add_lane(body, "spur to the clinic door", [Vector3(0.0, f, pz - 0.6), Vector3(SEN_CLINIC_DOOR, f, hz + 0.8)], 0.55)
	ClearZones.add_lane(body, "porch to the school door", [Vector3(0.0, f, pz - 0.6), Vector3(2.4, f, pz - 1.0), Vector3(SEN_SCHOOL_DOOR, f, hz + 0.7)])
	ClearZones.add_lane(body, "porch to the family door", [Vector3(0.0, f, pz - 0.6), Vector3(-2.0, f, pz - 1.0), Vector3(SEN_FAMILY_DOOR, f, hz + 0.7)])
	ClearZones.add_lane(body, "family door to the corridor", [Vector3(SEN_FAMILY_DOOR, f, hz - 1.4), Vector3(SEN_FAMILY_DOOR, f, (cs + cn) * 0.5)])
	ClearZones.add_lane(body, "the corridor", [Vector3(-hx + 0.6, f, (cs + cn) * 0.5), Vector3(hx - 0.6, f, (cs + cn) * 0.5)])

	_sen_interior(body, f, violet)
	return body


static func _sen_interior(body: StaticBody3D, f: float, violet: Color) -> void:
	var layout := RoomLayout.new(body, SEN_HALF - Vector2(0.08, 0.08))
	var w := SEN_HALF.x - 0.08
	var n := SEN_HALF.y - 0.08
	var cs := SEN_CORRIDOR.y + 0.08
	var cn := SEN_CORRIDOR.x - 0.08

	# Family entry and records room: record shelves of tied bundles, the cord
	# board of the village's decisions in pictured knots, a low bench, pegs.
	if not layout.at_any([{"pos": Vector2(-w + 0.17, cs + 0.55), "yaw": StiltKit.yaw_back_to(Vector2(-1, 0))}], 0.45, 0.17, 0.5, "record shelves").is_empty():
		Furnishings.shelf(body, Vector3(-w + 0.17, f, cs + 0.55), StiltKit.yaw_back_to(Vector2(-1, 0)), 0.9, 3, "boxes")
	if not layout.at_any([{"pos": Vector2(-1.77, 3.4), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.5, 0.19, 0.0, "family bench", 0.5).is_empty():
		Furnishings.bench(body, Vector3(-1.77, f, 3.4), StiltKit.yaw_back_to(Vector2(1, 0)), 1.0)
	_cord_board(body, Vector3(-2.2, f, n - 0.02), PI)
	Furnishings.peg_rail(body, Vector3(-4.0, f, n - 0.03), PI, 0.6)
	Furnishings.hanging_lamp(body, Vector3(-3.0, f + 2.6, 2.0), 0.6, 4.5)

	# Clinic: the raised cot against the corridor wall with the lamp over it,
	# corked jars sorted by colour, the washing table, the stool worn smooth.
	if not layout.at_any([{"pos": Vector2(0.27, cs + 0.42), "yaw": 0.0}], 0.92, 0.4, 0.0, "clinic cot", 0.7).is_empty():
		_cot(body, Vector3(0.27, f, cs + 0.42))
	if not layout.at_any([{"pos": Vector2(-1.25, cs + 0.55), "yaw": StiltKit.yaw_back_to(Vector2(-1, 0))}], 0.45, 0.17, 0.4, "jar shelves").is_empty():
		_jar_shelf(body, Vector3(-1.25, f, cs + 0.55), StiltKit.yaw_back_to(Vector2(-1, 0)))
	if not layout.at_any([{"pos": Vector2(1.14, 3.4), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.4, 0.28, 0.4, "washing table", 0.9).is_empty():
		Furnishings.washstand(body, Vector3(1.14, f, 3.4), StiltKit.yaw_back_to(Vector2(1, 0)))
	if not layout.at_any([{"pos": Vector2(0.0, cs + 1.2), "yaw": 0.0}], 0.23, 0.23, 0.0, "Asha's stool", 0.5).is_empty():
		Furnishings.stool(body, Vector3(0.0, f, cs + 1.2))
	Furnishings.hanging_lamp(body, Vector3(0.27, f + 2.4, cs + 0.5), 0.7, 4.5)
	# Cuttings drying from the rafters.
	for i in 3:
		Furnishings.piece(body, Vector3(0.05, 0.16, 0.05), Color(0.44, 0.52, 0.30).darkened(0.08 * float(i)), Vector3(-0.8 + 0.3 * float(i), f + 2.95, 2.6), 0.0, false, SuperEgg.EPSILON_SOFT)

	# School room: a low table with three stools (Tavi's floats under his), the
	# slate wall of chalk marks, shells for counting, the children's boats.
	if not layout.at_any([{"pos": Vector2(3.35, 1.45), "yaw": 0.0}], 0.6, 0.35, 0.0, "school table", 0.8).is_empty():
		Furnishings.piece(body, Vector3(0.6, 0.035, 0.35), Furnishings.OAK_LIGHT, Vector3(3.35, f + 0.62, 1.45), 0.0, true)
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				Furnishings.piece(body, Vector3(0.04, 0.3, 0.04), Furnishings.OAK_DARK, Vector3(3.35 + sx * 0.5, f + 0.3, 1.45 + sz * 0.27))
	for stool: Vector2 in [Vector2(3.0, cs + 0.3), Vector2(3.7, cs + 0.3), Vector2(3.35, 2.15)]:
		if not layout.at_any([{"pos": stool, "yaw": 0.0}], 0.23, 0.23, 0.0, "school stool", 0.5).is_empty():
			Furnishings.stool(body, Vector3(stool.x, f, stool.y))
	Furnishings.piece(body, Vector3(0.1, 0.1, 0.1), Color(0.86, 0.66, 0.30), Vector3(3.35, f + 0.1, 2.15), 0.0, false, 2.0)
	Furnishings.piece(body, Vector3(0.9, 0.55, 0.012), Color(0.20, 0.22, 0.22), Vector3(3.0, f + 1.55, cs + 0.005))
	for i in 7:
		Furnishings.piece(body, Vector3(0.01, 0.07, 0.004), Color(0.92, 0.92, 0.88), Vector3(2.4 + 0.12 * float(i), f + 1.62, cs + 0.02))
	if not layout.at_any([{"pos": Vector2(w - 0.17, cs + 0.6), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.45, 0.17, 0.0, "counting shelf").is_empty():
		_boat_shelf(body, Vector3(w - 0.17, f, cs + 0.6))
	Furnishings.rug(body, Vector3(3.35, f, 1.45), 0.0, Vector2(1.9, 1.2), violet.lightened(0.2))
	Furnishings.hanging_lamp(body, Vector3(3.0, f + 2.6, 1.6), 0.6, 4.5)

	# Asha's room: bed head to the west wall, the writing desk by the window on
	# the partition, her chest.
	if not layout.at_any([{"pos": Vector2(-w + 1.27, -n + 0.84), "yaw": 0.0}], 1.23, 0.8, 0.0, "Asha's bed", 0.6).is_empty():
		var bed := TownProps.build_bed(violet.lightened(0.1))
		bed.position = Vector3(-w + 1.27, f, -n + 0.84)
		bed.rotation.y = PI * 0.5
		body.add_child(bed)
	# A small writing table on the partition beside the window (a full desk and
	# chair would not fit beside the bed in a 3 x 3 room).
	if not layout.at_any([{"pos": Vector2(-1.83, -1.7), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.45, 0.25, 0.0, "Asha's writing table", 0.8).is_empty():
		Furnishings.piece(body, Vector3(0.25, 0.03, 0.45), Furnishings.OAK_LIGHT, Vector3(-1.83, f + 0.76, -1.7), 0.0, true)
		for sz: float in [-1.0, 1.0]:
			Furnishings.piece(body, Vector3(0.03, 0.37, 0.03), Furnishings.OAK_DARK, Vector3(-1.95, f + 0.37, -1.7 + sz * 0.38))
		Furnishings.piece(body, Vector3(0.16, 0.015, 0.2), Color(0.86, 0.80, 0.66), Vector3(-1.85, f + 0.8, -1.8))
		Furnishings.piece(body, Vector3(0.05, 0.07, 0.05), Color(1.0, 0.82, 0.45), Vector3(-1.8, f + 0.86, -1.4), 0.0, false, 2.2)
	if not layout.at_any([{"pos": Vector2(-4.0, cn - 0.28), "yaw": StiltKit.yaw_back_to(Vector2(0, 1))}], 0.35, 0.28, 0.0, "Asha's chest", 0.6).is_empty():
		Furnishings.chest(body, Vector3(-4.0, f, cn - 0.28), StiltKit.yaw_back_to(Vector2(0, 1)), Furnishings.OAK, 0.7)
	Furnishings.hanging_lamp(body, Vector3(-3.0, f + 2.5, -2.4), 0.5, 4.0)

	# Rian's room: bed head to the west partition, spools and needles on a shelf,
	# the mother-of-pearl button on its nail by the door.
	if not layout.at_any([{"pos": Vector2(-0.15, -n + 0.84), "yaw": 0.0}], 1.23, 0.8, 0.0, "Rian's bed", 0.6).is_empty():
		var rian_bed := TownProps.build_bed(Color(0.30, 0.46, 0.44))
		rian_bed.position = Vector3(-0.15, f, -n + 0.84)
		rian_bed.rotation.y = PI * 0.5
		body.add_child(rian_bed)
	if not layout.at_any([{"pos": Vector2(1.25, -1.7), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.4, 0.17, 0.4, "Rian's shelf").is_empty():
		Furnishings.shelf(body, Vector3(1.25, f, -1.7), StiltKit.yaw_back_to(Vector2(1, 0)), 0.8, 2, "crocks")
	Furnishings.piece(body, Vector3(0.04, 0.04, 0.01), Color(0.92, 0.90, 0.86), Vector3(0.75, f + 1.6, cn - 0.02), 0.0, false, 2.0)
	# His spare coils of rope at the corridor's east end.
	for i in 2:
		Furnishings.piece(body, Vector3(0.3, 0.08, 0.3), StiltKit.ROPE.darkened(0.05 * float(i)), Vector3(4.0, f + 0.08 + 0.16 * float(i), (cs + cn) * 0.5), 0.0, false, 2.0)
	Furnishings.hanging_lamp(body, Vector3(0.0, f + 2.5, -2.4), 0.5, 4.0)

	# Kitchen and wash: the brazier under its hood in the north-east corner, its
	# flue through the hip; the water jar, the wash basin, the woodbox.
	var brazier_at := Vector2(w - 0.45, -n + 0.45)
	ClearZones.add(body, "kitchen brazier", "fire", brazier_at, Vector2(-0.7, 0.7), 0.4, 0.7, 0.45, f, f + 1.6)
	layout.reserve(brazier_at, Vector2(0.4, 0.4))
	_brazier(body, Vector3(brazier_at.x, f, brazier_at.y), f + StiltKit.RING_BEAM)
	_roof_flue(body, brazier_at, f + StiltKit.RING_BEAM, f + StiltKit.RING_BEAM + StiltRoofs.PLATE + 0.45 * tan(StiltRoofs.PITCH) + 0.7)
	StiltKit.rain_jar(body, Vector2(2.0, -n + 0.35), f, Color(0.30, 0.42, 0.48))
	if not layout.at_any([{"pos": Vector2(1.86, -1.75), "yaw": StiltKit.yaw_back_to(Vector2(-1, 0))}], 0.4, 0.28, 0.4, "wash basin", 0.9).is_empty():
		Furnishings.washstand(body, Vector3(1.86, f, -1.75), StiltKit.yaw_back_to(Vector2(-1, 0)))
		for i in 2:
			Furnishings.piece(body, Vector3(0.09, 0.03, 0.09), Furnishings.CLAY.lightened(0.1), Vector3(1.86, f + 0.9 + 0.06 * float(i), -1.45), 0.0, false, 2.2)
	if not layout.at_any([{"pos": Vector2(w - 0.25, -1.75), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.35, 0.22, 0.3, "woodbox", 0.5).is_empty():
		Furnishings.piece(body, Vector3(0.22, 0.22, 0.35), Furnishings.OAK_DARK, Vector3(w - 0.25, f + 0.22, -1.75), 0.0, true)
		for i in 3:
			Furnishings.piece(body, Vector3(0.05, 0.05, 0.3), Furnishings.OAK, Vector3(w - 0.33 + 0.08 * float(i), f + 0.46, -1.75), 0.0, false, SuperEgg.EPSILON_SOFT)
	Furnishings.hanging_lamp(body, Vector3(3.0, f + 2.5, -2.4), 0.5, 4.0)

	for failure in layout.failures:
		push_warning("SenHouse interior: " + failure)

	# On the porch: the bench for the clinic's queue at the east end, facing the
	# house, and pegs for hats by the school door.
	Furnishings.bench(body, Vector3(3.15, f, SEN_PORCH_Z - 0.3), 0.0, 2.0)


static func _cot(body: StaticBody3D, at: Vector3) -> void:
	Furnishings.piece(body, Vector3(0.92, 0.06, 0.4), Furnishings.OAK, at + Vector3(0, 0.62, 0), 0.0, true)
	Furnishings.piece(body, Vector3(0.88, 0.05, 0.36), Color(0.80, 0.74, 0.58), at + Vector3(0, 0.72, 0), 0.0, false, SuperEgg.EPSILON_SOFT)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			Furnishings.piece(body, Vector3(0.04, 0.29, 0.04), Furnishings.OAK_DARK, at + Vector3(sx * 0.82, 0.29, sz * 0.32))


## Shelves of corked jars sorted by colour.
static func _jar_shelf(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	Furnishings.shelf(body, at, yaw, 0.9, 3, "none")
	var tones: Array[Color] = [Color(0.36, 0.52, 0.30), Color(0.62, 0.32, 0.26), Color(0.30, 0.40, 0.58), Color(0.78, 0.66, 0.34)]
	for level in 3:
		for i in 4:
			var local := Vector3(-0.32 + 0.21 * float(i), 0.55 + 0.5 * float(level) + 0.1, 0.0)
			Furnishings.piece(body, Vector3(0.06, 0.1, 0.06), tones[(i + level) % 4], Furnishings._at(at, yaw, local), 0.0, false, 2.2)


## Counting shells and the row of carved sailing boats on a low shelf.
static func _boat_shelf(body: StaticBody3D, at: Vector3) -> void:
	for level: float in [0.7, 1.15]:
		Furnishings.piece(body, Vector3(0.14, 0.02, 0.45), Furnishings.OAK, at + Vector3(0, level, 0))
	for i in 4:
		Furnishings.piece(body, Vector3(0.05, 0.03, 0.1), Color(0.70, 0.52, 0.32).darkened(0.06 * float(i)), at + Vector3(0, 1.2, -0.3 + 0.2 * float(i)), 0.0, false, SuperEgg.EPSILON_SOFT)
		Furnishings.piece(body, Vector3(0.008, 0.08, 0.008), Furnishings.OAK_DARK, at + Vector3(0, 1.3, -0.3 + 0.2 * float(i)))
	for i in 8:
		Furnishings.piece(body, Vector3(0.035, 0.02, 0.035), Color(0.92, 0.86, 0.76), at + Vector3(0, 0.74, -0.35 + 0.1 * float(i)), 0.0, false, 2.2)


## The village's decisions, kept as pictured knots on a board of cords.
static func _cord_board(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	Furnishings.piece(body, Vector3(0.45, 0.04, 0.02), Furnishings.OAK, Furnishings._at(at, yaw, Vector3(0, 2.05, 0)), yaw)
	for i in 6:
		var x := -0.38 + 0.15 * float(i)
		Furnishings.piece(body, Vector3(0.008, 0.3, 0.008), StiltKit.ROPE, Furnishings._at(at, yaw, Vector3(x, 1.75, -0.02)), yaw)
		for k in 1 + i % 3:
			Furnishings.piece(body, Vector3(0.025, 0.025, 0.025), StiltKit.ROPE.darkened(0.2), Furnishings._at(at, yaw, Vector3(x, 1.9 - 0.15 * float(k), -0.02)), yaw, false, 2.0)


## A clay flue from the ceiling up through the roof, capped above the slope.
static func _roof_flue(body: StaticBody3D, at: Vector2, from_y: float, to_y: float) -> void:
	var pipe := SuperEgg.build_part(Vector3(0.11, (to_y - from_y) * 0.5, 0.11), Furnishings.CLAY.darkened(0.3), 2.4, SuperEgg.EPSILON_FLAT)
	pipe.position = Vector3(at.x, (from_y + to_y) * 0.5, at.y)
	body.add_child(pipe)
	CollisionPolicy.mark_decorative(pipe)
	var cap := SuperEgg.build_part(Vector3(0.2, 0.05, 0.2), Furnishings.CLAY.darkened(0.4), 2.4, SuperEgg.EPSILON_FLAT)
	cap.position = Vector3(at.x, to_y + 0.1, at.y)
	body.add_child(cap)
	CollisionPolicy.mark_decorative(cap)


# ---------------------------------------------------------------------------
# 4.6 Cistern house and shared stores (village; Leena keeps the stores)
# ---------------------------------------------------------------------------
# Body frame: origin at the stores house's centre, plan (-2, -15.9), at W.
# House x -3..3, z -2.5..2.5 (6 x 5), one room. The covered cistern, a stone
# tank, stands behind it at z -4.1..-2.6 against Anvil Rock's foot, where the
# seep leaves the face (the face is sheer at plan z -20.5; the shelf runs to -20).
# The front threshold ramp z 2.5..3.9 meets the Cistern spur. Section in the
# design brief, 4.6.

const CISTERN_ORIGIN := Vector2(-2.0, -15.9)
const CISTERN_HALF := Vector2(3.0, 2.5)
const CISTERN_TANK := Rect2(-3.0, -4.1, 6.0, 1.5)
const CISTERN_TANK_TOP := 1.45
const STONE := Color(0.62, 0.60, 0.55)
const MOSS := Color(0.32, 0.44, 0.24)


static func cistern_house() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CisternHouse"
	var f := HOUSE_FLOOR
	var green := _household("village")
	var hx := CISTERN_HALF.x
	var hz := CISTERN_HALF.y
	var plate := f + StiltKit.RING_BEAM
	var xs: Array[float] = [-hx, 0.0, hx]
	var rows: Array = []
	for z: float in [-hz, 0.0, hz]:
		var row: Array[Vector2] = []
		for x in xs:
			row.append(Vector2(x, z))
		rows.append(row)
		StiltKit.beam(body, Vector2(-hx - 0.1, z), Vector2(hx + 0.1, z), f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH * 0.5, Vector2(0.11, StiltKit.BEAM_DEPTH * 0.5))
	StiltKit.piles(body, rows, f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH, SHELF_Y)
	StiltKit.floor_slab(body, Rect2(-hx, -hz, hx * 2.0, hz * 2.0), f)

	# A store: one public door, no glazing to the front; a small north hatch
	# over the tank for cleaning it, which also lights the shelves.
	var no_openings: Array[Dictionary] = []
	StiltKit.wall(body, Vector2(-hx, hz), Vector2(hx, hz), Vector2(0, 1), f, StiltKit.RING_BEAM,
		[StiltKit.door(Vector2(0.0, hz))], StiltKit.TIMBER_PALE, green)
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(0, -1), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-1.2, -hz), false)], StiltKit.TIMBER_PALE, green)
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(-hx, hz), Vector2(-1, 0), f, StiltKit.RING_BEAM, no_openings, StiltKit.TIMBER_PALE, green)
	StiltKit.wall(body, Vector2(hx, -hz), Vector2(hx, hz), Vector2(1, 0), f, StiltKit.RING_BEAM, no_openings, StiltKit.TIMBER_PALE, green)
	StiltKit.ceiling(body, Rect2(-hx, -hz, hx * 2.0, hz * 2.0), plate)
	# Posts on the bay lines, except that the front's middle line is the
	# doorway: two rope-bound posts flank it instead.
	for x in xs:
		StiltKit.post(body, Vector2(x, -hz), f - StiltKit.FLOOR_THICKNESS, plate)
	for x: float in [-hx, -0.85, 0.85, hx]:
		StiltKit.post(body, Vector2(x, hz), f - StiltKit.FLOOR_THICKNESS, plate, StiltKit.TIMBER, absf(x) < 1.0)
	var corners: Array[Vector2] = [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	for i in 4:
		StiltKit.beam(body, corners[i], corners[(i + 1) % 4], plate - 0.1, Vector2(0.12, 0.1))
	StiltRoofs.hip(body, CISTERN_HALF, plate, StiltKit.SHINGLE, green)

	# The cistern: a stone tank from the shelf, damp and mossed at the foot,
	# under a plank lid; the seep's stone channel from the rock face; the north
	# gutter's downpipe into it.
	var tank := CISTERN_TANK
	var tank_centre := tank.get_center()
	var tank_height := CISTERN_TANK_TOP - SHELF_Y
	var stone := SuperEgg.build_part(Vector3(tank.size.x * 0.5, tank_height * 0.5, tank.size.y * 0.5), STONE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	stone.position = Vector3(tank_centre.x, (CISTERN_TANK_TOP + SHELF_Y) * 0.5, tank_centre.y)
	body.add_child(stone)
	CollisionPolicy.add_box(body, stone, Vector3(tank.size.x, tank_height, tank.size.y), stone.position, Basis(), true)
	var moss := SuperEgg.build_part(Vector3(tank.size.x * 0.5 + 0.03, 0.35, tank.size.y * 0.5 + 0.03), MOSS, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT)
	moss.position = Vector3(tank_centre.x, 0.2, tank_centre.y)
	body.add_child(moss)
	CollisionPolicy.mark_decorative(moss)
	for i in 5:
		var plank := SuperEgg.build_part(Vector3(0.58, 0.04, tank.size.y * 0.5 + 0.06), StiltKit.TIMBER.darkened(0.05 * float(i % 2)), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		plank.position = Vector3(tank.position.x + 0.6 + 1.2 * float(i), CISTERN_TANK_TOP + 0.04, tank_centre.y)
		body.add_child(plank)
		CollisionPolicy.mark_decorative(plank)
	var channel_from := Vector3(-0.6, 2.1, -4.7)
	var channel_to := Vector3(-0.6, CISTERN_TANK_TOP + 0.12, tank_centre.y)
	var along := (channel_to - channel_from).normalized()
	var channel := SuperEgg.build_part(Vector3(0.16, 0.08, channel_from.distance_to(channel_to) * 0.5), STONE.darkened(0.1), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT)
	channel.transform = Transform3D(Basis.looking_at(-along, Vector3.UP), (channel_from + channel_to) * 0.5)
	body.add_child(channel)
	CollisionPolicy.mark_decorative(channel)
	var trickle := SuperEgg.build_part(Vector3(0.08, 0.02, channel_from.distance_to(channel_to) * 0.5), Color(0.55, 0.75, 0.85, 0.8), 2.0, 2.0)
	trickle.transform = Transform3D(Basis.looking_at(-along, Vector3.UP), (channel_from + channel_to) * 0.5 + Vector3(0, 0.07, 0))
	body.add_child(trickle)
	CollisionPolicy.mark_decorative(trickle)
	var north_gutter_y := plate + StiltRoofs.PLATE - StiltRoofs.EAVE * tan(StiltRoofs.PITCH) - 0.1
	StiltKit.beam(body, Vector2(-hx - 0.9, -hz - 0.92), Vector2(hx + 0.9, -hz - 0.92), north_gutter_y, Vector2(0.06, 0.05))
	var downpipe := SuperEgg.build_part(Vector3(0.045, (north_gutter_y - CISTERN_TANK_TOP) * 0.5, 0.045), StiltKit.TIMBER_DARK, 2.2, SuperEgg.EPSILON_FLAT)
	downpipe.position = Vector3(1.6, (north_gutter_y + CISTERN_TANK_TOP) * 0.5, -hz - 0.92)
	body.add_child(downpipe)
	CollisionPolicy.mark_decorative(downpipe)

	# The tap: a pipe from the tank along the east wall to a spout on the front,
	# with the bucket ledge beneath it, over the east part of the apron.
	var pipe_y := f + 1.25
	StiltKit.beam(body, Vector2(hx + 0.1, tank.end.y - 0.1), Vector2(hx + 0.1, hz + 0.1), pipe_y, Vector2(0.04, 0.04), Furnishings.CLAY.darkened(0.2))
	StiltKit.beam(body, Vector2(hx + 0.1, hz + 0.1), Vector2(1.7, hz + 0.1), pipe_y, Vector2(0.04, 0.04), Furnishings.CLAY.darkened(0.2))
	Furnishings.piece(body, Vector3(0.05, 0.12, 0.05), Color(0.62, 0.50, 0.28), Vector3(1.7, pipe_y - 0.1, hz + 0.16), 0.0, false, 2.2)
	var ledge := SuperEgg.build_part(Vector3(0.45, 0.04, 0.2), StiltKit.TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	ledge.position = Vector3(1.7, f + 0.45, hz + 0.28)
	body.add_child(ledge)
	CollisionPolicy.add_box(body, ledge, Vector3(0.9, 0.08, 0.4), ledge.position, Basis(), true)
	Furnishings.piece(body, Vector3(0.16, 0.14, 0.16), Color(0.50, 0.42, 0.30), Vector3(1.85, f + 0.63, hz + 0.28), 0.0, false, 2.2)

	# The threshold: a broad ramp from the spur up to the door, wide enough for
	# the tap's queue beside the doorway.
	StiltKit.ramp(body, Vector2(0.6, hz + 1.4), Vector2(0.6, hz), DECK_TOP, f, 3.6)
	ClearZones.add_lane(body, "spur to the stores door", [Vector3(0.0, f, hz + 1.2), Vector3(0.0, f, hz + 0.6)], 0.55)
	ClearZones.add_lane(body, "into the stores", [Vector3(0.0, f, hz + 0.6), Vector3(0.0, f, hz - 1.3)])

	_cistern_interior(body, f)
	return body


static func _cistern_interior(body: StaticBody3D, f: float) -> void:
	var layout := RoomLayout.new(body, CISTERN_HALF - Vector2(0.08, 0.08))
	var w := CISTERN_HALF.x - 0.08
	var n := CISTERN_HALF.y - 0.08
	# Shelves along three walls: rope and pitch to the north, lamp oil in jars to
	# the west, dried food in lidded baskets to the east.
	if not layout.at_any([{"pos": Vector2(1.3, -n + 0.17), "yaw": StiltKit.yaw_back_to(Vector2(0, -1))}], 1.2, 0.17, 0.5, "rope and pitch shelf").is_empty():
		Furnishings.shelf(body, Vector3(1.3, f, -n + 0.17), StiltKit.yaw_back_to(Vector2(0, -1)), 2.4, 3, "boxes")
	if not layout.at_any([{"pos": Vector2(-w + 0.17, -0.5), "yaw": StiltKit.yaw_back_to(Vector2(-1, 0))}], 1.2, 0.17, 0.5, "oil jar shelf").is_empty():
		Furnishings.shelf(body, Vector3(-w + 0.17, f, -0.5), StiltKit.yaw_back_to(Vector2(-1, 0)), 2.4, 3, "crocks")
	if not layout.at_any([{"pos": Vector2(w - 0.17, -0.5), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 1.2, 0.17, 0.5, "basket shelf").is_empty():
		Furnishings.shelf(body, Vector3(w - 0.17, f, -0.5), StiltKit.yaw_back_to(Vector2(1, 0)), 2.4, 3, "boxes")
	# A stack of spare lamps, and Leena's stool by the door where she checks the
	# jars in the evening, under the ledger of beads on wires, one per household.
	if not layout.at_any([{"pos": Vector2(-1.4, n - 0.5), "yaw": 0.0}], 0.23, 0.23, 0.0, "Leena's stool", 0.5).is_empty():
		Furnishings.stool(body, Vector3(-1.4, f, n - 0.5))
	_bead_ledger(body, Vector3(-1.6, f, n - 0.02))
	if not layout.at_any([{"pos": Vector2(1.9, n - 0.4), "yaw": 0.0}], 0.35, 0.3, 0.0, "spare lamps", 0.5).is_empty():
		Furnishings.piece(body, Vector3(0.35, 0.18, 0.3), Furnishings.OAK_DARK, Vector3(1.9, f + 0.18, n - 0.4), 0.0, true)
		for i in 4:
			Furnishings.piece(body, Vector3(0.1, 0.09, 0.1), Color(0.9, 0.66, 0.28), Vector3(1.7 + 0.14 * float(i), f + 0.45, n - 0.4 + 0.08 * float(i % 2)), 0.0, false, 2.2)
	for failure in layout.failures:
		push_warning("CisternHouse interior: " + failure)
	Furnishings.hanging_lamp(body, Vector3(0.0, f + 2.6, -0.3), 0.6, 5.0)


## Leena's ledger: a board of wires, one per household, with beads for each
## share drawn from the stores, each household in its own colour.
static func _bead_ledger(body: StaticBody3D, at: Vector3) -> void:
	Furnishings.piece(body, Vector3(0.45, 0.32, 0.015), Furnishings.OAK, at + Vector3(0, 1.6, 0))
	var households := ["Venn", "Aran", "Vale", "Mor", "Sen"]
	for i in households.size():
		var y := 1.85 - 0.12 * float(i)
		Furnishings.piece(body, Vector3(0.4, 0.006, 0.006), Furnishings.IRON, at + Vector3(0, y, -0.03))
		for b in 2 + i % 3:
			Furnishings.piece(body, Vector3(0.025, 0.025, 0.025), FishingVillagePlan.HOUSEHOLD_COLORS[households[i]], at + Vector3(-0.32 + 0.06 * float(b), y, -0.035), 0.0, false, 2.0)


# ---------------------------------------------------------------------------
# 4.7 Net shed and gear loft (Salim, shared with Jori)
# ---------------------------------------------------------------------------
# Body frame: origin at the shed's centre, plan (8, -16.5), at W. A deck fills
# the footprint (x -4..4, z -3.5..4.5) at the public deck height, flush with
# the spur. The shed, x -3..3, z -3..3, is open south, east and west under a
# high gable; boarded on the north. A loft 2 m deep along the north at 2.6 m,
# reached by a 32 degree ramp up the west side. See the design brief, 4.7.

const NET_SHED_ORIGIN := Vector2(8.0, -16.5)
const NET_SHED_HALF := Vector2(3.0, 3.0)
const NET_SHED_POSTS := 4.8
const NET_LOFT_RISE := 2.6
const NET_LOFT_EDGE := -1.0
const NET_COLOR := Color(0.30, 0.34, 0.28)


static func net_shed() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "NetShed"
	var f := DECK_TOP
	var hx := NET_SHED_HALF.x
	var hz := NET_SHED_HALF.y
	var plate := f + NET_SHED_POSTS
	var loft_y := f + NET_LOFT_RISE

	# The deck and its piles.
	var rows: Array = []
	for z: float in [-3.5, -0.5, 2.5, 4.5]:
		var row: Array[Vector2] = []
		for x: float in [-4.0, -1.35, 1.35, 4.0]:
			row.append(Vector2(x, z))
		rows.append(row)
		StiltKit.beam(body, Vector2(-4.1, z), Vector2(4.1, z), f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH * 0.5, Vector2(0.11, StiltKit.BEAM_DEPTH * 0.5))
	StiltKit.piles(body, rows, f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH, SHELF_Y)
	StiltKit.floor_slab(body, Rect2(-4.0, -3.5, 8.0, 8.0), f)

	# Frame. No post stands in the 6 m front opening where the spur arrives: a
	# deeper front beam spans it. Tie beams on the bay lines carry the nets.
	for x: float in [-hx, 0.0, hx]:
		StiltKit.post(body, Vector2(x, -hz), f - StiltKit.FLOOR_THICKNESS, plate)
	for x: float in [-hx, hx]:
		StiltKit.post(body, Vector2(x, 0.0), f - StiltKit.FLOOR_THICKNESS, plate)
		StiltKit.post(body, Vector2(x, hz), f - StiltKit.FLOOR_THICKNESS, plate, StiltKit.TIMBER, true)
	StiltKit.beam(body, Vector2(-hx, hz), Vector2(hx, hz), plate - 0.2, Vector2(0.13, 0.2))
	StiltKit.beam(body, Vector2(-hx, -hz), Vector2(hx, -hz), plate - 0.1, Vector2(0.12, 0.1))
	for x: float in [-hx, 0.0, hx]:
		StiltKit.beam(body, Vector2(x, -hz), Vector2(x, hz), plate - 0.1, Vector2(0.1, 0.1))

	# The north wall, boards full height, and the gable ends boarded above the
	# plate up to the rafters.
	var no_openings: Array[Dictionary] = []
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(0, -1), f, NET_SHED_POSTS, no_openings, StiltKit.TIMBER_PALE, StiltKit.TIMBER_DARK)
	var rise := tan(StiltRoofs.PITCH)
	var peak := hz * rise + StiltRoofs.PLATE - StiltRoofs.THICKNESS - 0.02
	for x: float in [-hx, hx]:
		var cuts := [{"a": peak, "b": rise}, {"a": peak, "b": -rise}]
		TownProps._build_panel_facade(body, hz * 2.0, Vector3(x, plate, 0.0), -PI * 0.5, StiltKit.TIMBER_PALE, [], plate, peak + 0.1, TownProps.WALL_THICKNESS, cuts)
	StiltRoofs.gable(body, NET_SHED_HALF, plate, StiltKit.SHINGLE, _household("village"))

	# The gear loft along the north wall, its edge beam on two posts, a rail
	# along its open edge except at the ramp's head.
	StiltKit.slab(body, Rect2(-hx, -hz, hx * 2.0, NET_LOFT_EDGE + hz), loft_y - 0.08, 0.16, StiltKit.PLANK, true)
	StiltKit.beam(body, Vector2(-hx, NET_LOFT_EDGE), Vector2(hx, NET_LOFT_EDGE), loft_y - 0.26, Vector2(0.1, 0.1))
	for x: float in [-1.2, 1.5]:
		StiltKit.post(body, Vector2(x, NET_LOFT_EDGE), f, loft_y - 0.16)
	StiltKit.rail(body, Vector2(-1.35, NET_LOFT_EDGE), Vector2(hx - 0.15, NET_LOFT_EDGE), loft_y)
	var ramp_x := -hx + 0.85
	var ramp_run := NET_LOFT_RISE / tan(TownProps.RAMP_PITCH)
	StiltKit.ramp(body, Vector2(ramp_x, NET_LOFT_EDGE + ramp_run), Vector2(ramp_x, NET_LOFT_EDGE), f, loft_y, TownProps.RAMP_WIDTH)
	StiltKit.rail(body, Vector2(ramp_x + 0.75, NET_LOFT_EDGE + ramp_run - 0.4), Vector2(ramp_x + 0.75, NET_LOFT_EDGE + 0.1), f + NET_LOFT_RISE * 0.5)
	ClearZones.add(body, "loft ramp foot", "door", Vector2(ramp_x, NET_LOFT_EDGE + ramp_run), Vector2(0, -1), 1.2, 0.0, 0.7, f, f + 1.9)

	# Nets hang from the rafters like curtains, down to 2.2 m above the floor.
	for net: Vector3 in [Vector3(-0.2, 0.0, 1.5), Vector3(1.1, 0.8, 1.2), Vector3(0.4, 1.9, 1.7), Vector3(2.2, -0.2, 1.0)]:
		var top := plate + 0.2
		var bottom := f + 2.2
		var sheet := SuperEgg.build_part(Vector3(net.z * 0.5, (top - bottom) * 0.5, 0.02), NET_COLOR.lightened(0.05 * net.x), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
		sheet.position = Vector3(net.x, (top + bottom) * 0.5, net.y)
		body.add_child(sheet)
		CollisionPolicy.mark_decorative(sheet)
		for k in 4:
			var float_ball := SuperEgg.build_part(Vector3(0.06, 0.06, 0.06), Color(0.86, 0.62, 0.24), 2.0, 2.0)
			float_ball.position = Vector3(net.x - net.z * 0.4 + net.z * 0.27 * float(k), bottom + 0.05, net.y)
			body.add_child(float_ball)
			CollisionPolicy.mark_decorative(float_ball)

	# Under the loft: the mending bench with a half-tied mesh and the netting
	# needle, the tar barrel, the cat asleep in its basket. Floats in baskets on
	# the east side, traps and floats stacked in the loft.
	Furnishings.bench(body, Vector3(0.6, f, -hz + 0.35), 0.0, 1.8)
	Furnishings.piece(body, Vector3(0.5, 0.01, 0.25), NET_COLOR, Vector3(0.4, f + 0.5, -hz + 0.35), 0.0, false, SuperEgg.EPSILON_SOFT)
	Furnishings.piece(body, Vector3(0.12, 0.012, 0.02), Furnishings.OAK_LIGHT, Vector3(1.0, f + 0.52, -hz + 0.35), 0.4)
	Furnishings.barrel(body, Vector3(2.4, f, -hz + 0.5), 0.45)
	Furnishings.piece(body, Vector3(0.28, 0.1, 0.22), Color(0.62, 0.50, 0.32), Vector3(-0.6, f + 0.1, -hz + 0.4), 0.0, false, SuperEgg.EPSILON_SOFT)
	Furnishings.piece(body, Vector3(0.17, 0.09, 0.12), Color(0.28, 0.24, 0.22), Vector3(-0.6, f + 0.2, -hz + 0.4), 0.2, false, 2.2)
	Furnishings.piece(body, Vector3(0.06, 0.05, 0.06), Color(0.28, 0.24, 0.22), Vector3(-0.42, f + 0.24, -hz + 0.42), 0.0, false, 2.2)
	for i in 3:
		var basket := Vector3(hx - 0.45, f, 0.4 + 0.75 * float(i))
		Furnishings.piece(body, Vector3(0.3, 0.22, 0.3), Color(0.66, 0.52, 0.32), basket + Vector3(0, 0.22, 0), 0.0, true, SuperEgg.EPSILON_SOFT)
		for k in 3:
			Furnishings.piece(body, Vector3(0.09, 0.09, 0.09), Color(0.86, 0.62, 0.24).darkened(0.1 * float(k)), basket + Vector3(-0.1 + 0.1 * float(k), 0.48, 0.05 * float(k - 1)), 0.0, false, 2.0)
	for i in 4:
		Furnishings.piece(body, Vector3(0.35, 0.22, 0.28), Furnishings.OAK.darkened(0.08 * float(i % 2)), Vector3(-0.2 + 0.8 * float(i), loft_y + 0.22, -hz + 0.5), 0.1 * float(i), true)
	# Salim's lucky knot, tied off over the opening.
	StiltKit.rope_binding(body, Vector2(0.0, hz), plate - 0.75, plate - 0.55, 0.06)
	Furnishings.piece(body, Vector3(0.01, 0.25, 0.01), StiltKit.ROPE, Vector3(0.0, plate - 0.95, hz), 0.0, false)
	Furnishings.hanging_lamp(body, Vector3(0.0, plate - 1.1, 0.4), 0.7, 6.0)

	ClearZones.add_lane(body, "spur into the shed", [Vector3(0.0, f, 4.2), Vector3(0.0, f, 0.0)], 0.55)
	ClearZones.add_lane(body, "to the loft ramp", [Vector3(0.0, f, 3.4), Vector3(ramp_x, f, NET_LOFT_EDGE + ramp_run + 0.6)])
	ClearZones.add_lane(body, "the loft", [Vector3(ramp_x, loft_y, -1.6), Vector3(hx - 0.6, loft_y, -1.4)])
	return body


# ---------------------------------------------------------------------------
# 4.8 Communal pavilion (Leena keeps it)
# ---------------------------------------------------------------------------
# Body frame: origin at the pavilion's centre, plan (-2, 0), at W. Deck
# x -6..6, z -4..4 at the public deck height. The hall, 12 x 6 m (z -3..3),
# open on every side, four bays by two, under the village's largest hip with a
# raised ridge vent and carved ridge ends. The pavilion spur arrives on the
# north at x 0; swim exit 2 leaves the south edge at x -1.7..1.7; the return
# route leaves the west end at z 2. See the design brief, 4.8.

const PAVILION_ORIGIN := Vector2(-2.0, 0.0)
const PAVILION_HALF := Vector2(6.0, 3.0)
const PAVILION_POSTS := 3.6


static func pavilion() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Pavilion"
	var f := DECK_TOP
	var green := _household("village")
	var hx := PAVILION_HALF.x
	var hz := PAVILION_HALF.y
	var plate := f + PAVILION_POSTS
	var xs: Array[float] = [-6.0, -3.0, 0.0, 3.0, 6.0]

	var rows: Array = []
	for z: float in [-4.0, -1.3, 1.3, 4.0]:
		var row: Array[Vector2] = []
		for x in xs:
			row.append(Vector2(x, z))
		rows.append(row)
		StiltKit.beam(body, Vector2(-6.1, z), Vector2(6.1, z), f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH * 0.5, Vector2(0.11, StiltKit.BEAM_DEPTH * 0.5))
	StiltKit.piles(body, rows, f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH, SHELF_Y)
	StiltKit.floor_slab(body, Rect2(-6.0, -4.0, 12.0, 8.0), f)

	# Posts four bays by two; the centre row carries the ridge. The posts either
	# side of the north and south ways are rope-bound.
	for x in xs:
		for z: float in [-hz, 0.0, hz]:
			if z == 0.0 and absf(x) > 5.0:
				continue
			# The way from the spur to the swim exit runs straight through at
			# x 0 between the rope-bound posts at x -3 and 3; the edge beams and
			# the ridge's centre beam span the 6 m over it.
			if absf(x) < 0.1:
				continue
			StiltKit.post(body, Vector2(x, z), f - StiltKit.FLOOR_THICKNESS, plate, StiltKit.TIMBER, absf(z) > 1.0 and absf(x) < 4.0 and absf(x) > 2.0)
	var corners: Array[Vector2] = [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	for i in 4:
		StiltKit.beam(body, corners[i], corners[(i + 1) % 4], plate - 0.12, Vector2(0.13, 0.12))
	for x in xs:
		StiltKit.beam(body, Vector2(x, -hz), Vector2(x, hz), plate - 0.1, Vector2(0.1, 0.1))
	StiltKit.beam(body, Vector2(-hx, 0.0), Vector2(hx, 0.0), plate - 0.12, Vector2(0.13, 0.12))
	StiltRoofs.hip(body, PAVILION_HALF, plate, StiltKit.SHINGLE, green)

	# The ridge vent: a small raised gable riding the ridge on short posts, so
	# the stove's smoke and the day's heat leave; carved curls at the ridge ends.
	var ridge_y := plate + StiltRoofs.PLATE + hz * tan(StiltRoofs.PITCH)
	var vent_half := Vector2(2.2, 0.55)
	var vent := StaticBody3D.new()
	vent.name = "RidgeVent"
	vent.position = Vector3(0.0, ridge_y + 0.35, 0.0)
	body.add_child(vent)
	StiltRoofs.gable(vent, vent_half, 0.0, StiltKit.SHINGLE.darkened(0.05), green)
	for x: float in [-vent_half.x, 0.0, vent_half.x]:
		for z: float in [-vent_half.y, vent_half.y]:
			var stub := SuperEgg.build_part(Vector3(0.06, 0.25, 0.06), StiltKit.TIMBER_DARK, TownProps.POST_EPSILON, TownProps.POST_EPSILON)
			stub.position = Vector3(x, ridge_y + 0.1, z)
			body.add_child(stub)
			CollisionPolicy.mark_decorative(stub)
	var ridge_half := hx - hz
	for side: float in [-1.0, 1.0]:
		var curl := SuperEgg.build_part(Vector3(0.12, 0.32, 0.08), green.darkened(0.15), 2.4, 2.4)
		curl.transform = Transform3D(Basis(Vector3(0, 0, 1), side * 0.6), Vector3(side * (ridge_half + 0.2), ridge_y + 0.32, 0.0))
		body.add_child(curl)
		CollisionPolicy.mark_decorative(curl)

	_pavilion_furnishings(body, f, plate, green)

	ClearZones.add_lane(body, "spur to the swim exit", [Vector3(0.0, f, -3.9), Vector3(0.0, f, 3.9)], 0.55)
	ClearZones.add_lane(body, "return route into the hall", [Vector3(-5.9, f, 2.0), Vector3(0.0, f, 2.0)], 0.55)
	return body


static func _pavilion_furnishings(body: StaticBody3D, f: float, plate: float, green: Color) -> void:
	# Two long tables with benches on the north half, either side of the way
	# through; the clay stove with its hood in the north-west corner.
	Furnishings.table(body, Vector3(-2.9, f, -1.55), 0.0, 3.6, 0.9, "benches")
	Furnishings.table(body, Vector3(2.4, f, -1.55), 0.0, 2.6, 0.9, "benches")
	var stove_at := Vector2(-5.35, -2.45)
	ClearZones.add(body, "pavilion stove", "fire", stove_at, Vector2(0, 1), 0.4, 0.7, 0.45, f, f + 1.6)
	# In the open hall the flue runs up through the hip and is capped above it.
	_brazier(body, Vector3(stove_at.x, f, stove_at.y), plate)
	_roof_flue(body, stove_at, plate - 0.05, plate + 1.0)
	# The repair bench with its vice at the east end.
	Furnishings.piece(body, Vector3(0.4, 0.05, 1.1), Furnishings.OAK, Vector3(5.35, f + 0.85, 0.9), 0.0, true)
	for z: float in [0.0, 1.8]:
		Furnishings.piece(body, Vector3(0.35, 0.4, 0.05), Furnishings.OAK_DARK, Vector3(5.35, f + 0.4, z))
	Furnishings.piece(body, Vector3(0.08, 0.1, 0.14), Furnishings.IRON, Vector3(5.1, f + 0.98, 0.4), 0.0, false)
	# The bell on the south-east post, its pull rope hanging.
	var bell_at := Vector3(hx_bell(), f + 2.55, 2.75)
	Furnishings.piece(body, Vector3(0.3, 0.04, 0.04), StiltKit.TIMBER_DARK, bell_at + Vector3(-0.2, 0.42, 0.0))
	Furnishings.piece(body, Vector3(0.2, 0.24, 0.2), Color(0.70, 0.56, 0.26), bell_at + Vector3(-0.32, 0.12, 0.0), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.012, 0.6, 0.012), StiltKit.ROPE, bell_at + Vector3(-0.32, -0.6, 0.0))
	# Rain jars in the corners.
	for corner: Vector2 in [Vector2(-5.55, 3.55), Vector2(5.55, -3.55), Vector2(-5.55, -3.55)]:
		StiltKit.rain_jar(body, corner, f, Color(0.28, 0.44, 0.34))
	# Lamps in a row under the ridge.
	for x: float in [-4.5, -1.5, 1.5, 4.5]:
		Furnishings.hanging_lamp(body, Vector3(x, plate - 0.5, 0.0), 0.7, 6.0)
	# Every household's mug on its own peg, in its own colour, on the post at
	# (-3, 0); a child's height marks cut into the post at (3, 0).
	Furnishings.piece(body, Vector3(0.02, 0.06, 0.32), Furnishings.OAK, Vector3(-3.15, f + 1.6, 0.0))
	var households := ["Venn", "Aran", "Vale", "Mor", "Sen"]
	for i in households.size():
		Furnishings.piece(body, Vector3(0.05, 0.06, 0.05), FishingVillagePlan.HOUSEHOLD_COLORS[households[i]], Vector3(-3.22, f + 1.5, -0.24 + 0.12 * float(i)), 0.0, false, 2.2)
	for i in 5:
		Furnishings.piece(body, Vector3(0.006, 0.008, 0.08), StiltKit.TIMBER_DARK, Vector3(3.14, f + 0.8 + 0.12 * float(i), 0.0))


## The bell hangs on a bracket from the south-east post, just inside it.
static func hx_bell() -> float:
	return PAVILION_HALF.x - 0.05


# ---------------------------------------------------------------------------
# 4.9 Aran house and pearl yard (Mai, Salim, Dala, Pree)
# ---------------------------------------------------------------------------
# Body frame: origin at the house's centre, plan (11, 1), at W. House x -3..3,
# z -4..4 (6 x 8), ridge north to south, in three rows: north z -4..-1.1 (Mai
# and Salim west, Pree east), the living room across the middle z -1.1..1.4,
# south z 1.4..4 (Dala west, the kitchen east). The veranda, 2 m deep, runs the
# west side (x -5..-3) facing the water court; a threshold ramp at its north
# end meets the Aran spur; the kitchen's wet door leads down a ramp to the pearl
# yard pontoon. See the design brief, 4.9.

const ARAN_ORIGIN := Vector2(11.0, 1.0)
const ARAN_HALF := Vector2(3.0, 4.0)
const ARAN_NORTH_ROW := -1.05
const ARAN_SOUTH_ROW := 1.4
const ARAN_VERANDA_X := -5.0
const ARAN_SHUTTER := Color(0.30, 0.50, 0.32)
const ARAN_PENT_AT_WALL := 2.75
## The kitchen's wet door stands west of the living-room door's line, so the
## two leaves (each open 78 degrees, into the kitchen) leave a way between them.
const ARAN_WET_DOOR := 1.0


static func aran_house() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "AranHouse"
	var f := HOUSE_FLOOR
	var ochre := _household("Dala")
	var hx := ARAN_HALF.x
	var hz := ARAN_HALF.y
	var vx := ARAN_VERANDA_X
	var nr := ARAN_NORTH_ROW
	var sr := ARAN_SOUTH_ROW
	var plate := f + StiltKit.RING_BEAM
	var living_z := (nr + sr) * 0.5

	# Dala's generation's first piles: the same grid, the oldest timbers.
	var zs: Array[float] = [-hz, nr, sr, hz]
	var rows: Array = []
	for z in zs:
		var row: Array[Vector2] = []
		for x: float in [vx, -hx, 0.0, hx]:
			row.append(Vector2(x, z))
		rows.append(row)
		StiltKit.beam(body, Vector2(vx - 0.1, z), Vector2(hx + 0.1, z), f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH * 0.5, Vector2(0.11, StiltKit.BEAM_DEPTH * 0.5), StiltKit.TIMBER_DARK.darkened(0.15))
	StiltKit.piles(body, rows, f - StiltKit.FLOOR_THICKNESS - StiltKit.BEAM_DEPTH, SHELF_Y)
	StiltKit.floor_slab(body, Rect2(vx, -hz, hx - vx, hz * 2.0), f, StiltKit.PLANK.darkened(0.05))

	# Outside walls. The front door opens from the veranda into the living room,
	# between the two rope-bound posts; every room has its window.
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(-hx, hz), Vector2(-1, 0), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-hx, -2.55)), StiltKit.door(Vector2(-hx, living_z)), StiltKit.window(Vector2(-hx, 2.65))], ochre, ARAN_SHUTTER)
	StiltKit.wall(body, Vector2(hx, -hz), Vector2(hx, hz), Vector2(1, 0), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(hx, living_z)), StiltKit.window(Vector2(hx, 3.0))], ochre, ARAN_SHUTTER)
	StiltKit.wall(body, Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(0, -1), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-1.5, -hz)), StiltKit.window(Vector2(1.5, -hz))], ochre, ARAN_SHUTTER)
	StiltKit.wall(body, Vector2(-hx, hz), Vector2(hx, hz), Vector2(0, 1), f, StiltKit.RING_BEAM,
		[StiltKit.window(Vector2(-1.5, hz)), StiltKit.door(Vector2(ARAN_WET_DOOR, hz))], ochre, ARAN_SHUTTER)

	# Partitions. The living room's north wall has a door into each north room
	# (drawn west to east, leaves swing north); its south wall a door into
	# Dala's room and the kitchen (drawn east to west, leaves swing south).
	var no_doors: Array[float] = []
	StiltKit.partition(body, Vector2(-hx, nr), Vector2(hx, nr), f, StiltKit.RING_BEAM, [1.5, 4.5])
	StiltKit.partition(body, Vector2(hx, sr), Vector2(-hx, sr), f, StiltKit.RING_BEAM, [1.5, 4.5])
	StiltKit.partition(body, Vector2(0.0, -hz), Vector2(0.0, nr), f, StiltKit.RING_BEAM, no_doors)
	StiltKit.partition(body, Vector2(0.0, sr), Vector2(0.0, hz), f, StiltKit.RING_BEAM, no_doors)
	StiltKit.ceiling(body, Rect2(-hx, -hz, hx * 2.0, hz * 2.0), plate)

	for z in zs:
		for x: float in [-hx, hx]:
			StiltKit.post(body, Vector2(x, z), f - StiltKit.FLOOR_THICKNESS, plate)
	for z: float in [-hz, hz]:
		StiltKit.post(body, Vector2(0.0, z), f - StiltKit.FLOOR_THICKNESS, plate)
	var corners: Array[Vector2] = [Vector2(-hx, -hz), Vector2(hx, -hz), Vector2(hx, hz), Vector2(-hx, hz)]
	for i in 4:
		StiltKit.beam(body, corners[i], corners[(i + 1) % 4], plate - 0.1, Vector2(0.12, 0.1))

	# Roof: the hip runs north to south over the long plan (its own body, turned
	# a quarter); a pent over the veranda falls west, tucked under its eave.
	var roof := StaticBody3D.new()
	roof.name = "AranRoof"
	roof.rotation.y = PI * 0.5
	body.add_child(roof)
	StiltRoofs.hip(roof, Vector2(hz, hx), plate, StiltKit.SHINGLE.darkened(0.04), ochre.darkened(0.1))
	var pent_wall := f + ARAN_PENT_AT_WALL
	var pent_rise := tan(StiltRoofs.PENT_PITCH)
	StiltRoofs.pent(body, Rect2(vx - 0.25, -hz - 0.3, -hx - vx + 0.25, hz * 2.0 + 0.6), pent_wall + StiltRoofs.THICKNESS / cos(StiltRoofs.PENT_PITCH), Vector3(-1, 0, 0), StiltKit.SHINGLE.lightened(0.05))
	var pent_at_edge := pent_wall - pent_rise * (-hx - vx)
	for z in zs:
		StiltKit.post(body, Vector2(vx, z), f - StiltKit.FLOOR_THICKNESS, pent_at_edge, StiltKit.TIMBER, z == nr or z == sr)
	StiltKit.beam(body, Vector2(vx, -hz), Vector2(vx, hz), pent_at_edge - 0.1, Vector2(0.1, 0.1))
	for i in zs.size() - 1:
		StiltKit.rail(body, Vector2(vx, zs[i] + 0.15), Vector2(vx, zs[i + 1] - 0.15), f)
	StiltKit.rail(body, Vector2(vx + 0.15, hz), Vector2(-hx - 0.15, hz), f)

	# Thresholds: from the spur up to the veranda's north end; from the
	# kitchen's wet door down to the pearl yard pontoon.
	StiltKit.ramp(body, Vector2((vx - hx) * 0.5, -hz - 1.0), Vector2((vx - hx) * 0.5, -hz), DECK_TOP, f, -hx - vx)
	StiltKit.ramp(body, Vector2(ARAN_WET_DOOR, hz + 1.5), Vector2(ARAN_WET_DOOR, hz), FishingVillagePlan.FLOAT_DECK, f, 2.0)
	_roof_flue(body, Vector2(2.45, 2.0), plate - 0.05, plate + StiltRoofs.PLATE + 0.55 * tan(StiltRoofs.PITCH) + 0.7)

	# Along the veranda on its house side (Dala's chair stands at the rail),
	# in at the front door, and across the living room north of the low table
	# to the four room doors; out of the kitchen by the wet door.
	ClearZones.add_lane(body, "spur along the veranda", [Vector3(-hx - 0.7, f, -hz + 0.2), Vector3(-hx - 0.7, f, hz - 0.7)], 0.55)
	ClearZones.add_lane(body, "in at the front door", [Vector3(-hx - 0.7, f, living_z), Vector3(-hx + 0.6, f, living_z)])
	ClearZones.add_lane(body, "across the living room", [Vector3(-hx + 0.6, f, living_z), Vector3(-1.1, f, living_z), Vector3(-1.1, f, nr + 0.5), Vector3(1.5, f, nr + 0.5)])
	ClearZones.add_lane(body, "kitchen to the wet door", [Vector3(1.4, f, sr + 0.6), Vector3(ARAN_WET_DOOR, f, hz + 0.7)])

	_aran_interior(body, f, ochre)
	return body


static func _aran_interior(body: StaticBody3D, f: float, ochre: Color) -> void:
	var layout := RoomLayout.new(body, ARAN_HALF - Vector2(0.08, 0.08))
	var w := ARAN_HALF.x - 0.08
	var n := ARAN_HALF.y - 0.08
	var nr := ARAN_NORTH_ROW
	var sr := ARAN_SOUTH_ROW
	var living_z := (nr + sr) * 0.5

	# Living room: a low table and cushions, Dala's wooden charms on a board, a
	# bamboo flute on a nail, floor boards of different ages.
	if not layout.at_any([{"pos": Vector2(0.0, living_z), "yaw": 0.0}], 0.45, 0.3, 0.0, "low table", 0.5).is_empty():
		_low_table(body, Vector3(0.0, f, living_z), ochre)
	for i in 3:
		Furnishings.piece(body, Vector3(0.5, 0.008, 0.12), StiltKit.PLANK.lightened(0.08 * float(i % 2)), Vector3(-1.4 + 1.3 * float(i), f + 0.002, living_z + 0.6 - 0.5 * float(i)), 0.0, false)
	Furnishings.piece(body, Vector3(0.015, 0.25, 0.4), Furnishings.OAK, Vector3(w - 0.02, f + 1.7, living_z))
	for i in 5:
		Furnishings.piece(body, Vector3(0.02, 0.05, 0.03), Color(0.62, 0.44, 0.26).darkened(0.08 * float(i % 3)), Vector3(w - 0.05, f + 1.6 + 0.08 * float(i % 2), living_z - 0.3 + 0.15 * float(i)), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.02, 0.02, 0.32), Color(0.70, 0.62, 0.36), Vector3(-0.2, f + 2.0, nr + 0.12), PI * 0.5)
	Furnishings.hanging_lamp(body, Vector3(0.0, f + 2.6, living_z), 0.7, 5.0)

	# Mai and Salim's room (north-west): the broad bed head to the west wall,
	# the chest with Mai's grading tools, nets folded on a bench.
	if not layout.at_any([{"pos": Vector2(-w + 1.25, -n + 0.82), "yaw": 0.0}], 1.23, 0.8, 0.0, "Mai and Salim's bed", 0.6).is_empty():
		var bed := TownProps.build_bed(ochre.lightened(0.15))
		bed.position = Vector3(-w + 1.25, f, -n + 0.82)
		bed.rotation.y = PI * 0.5
		body.add_child(bed)
	if not layout.at_any([{"pos": Vector2(-0.36, -1.75), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.4, 0.28, 0.0, "Mai's chest", 0.6).is_empty():
		Furnishings.chest(body, Vector3(-0.36, f, -1.75), StiltKit.yaw_back_to(Vector2(1, 0)), Furnishings.OAK, 0.8)
	Furnishings.hanging_lamp(body, Vector3(-1.5, f + 2.5, -2.6), 0.5, 4.0)

	# Pree's room (north-east): a narrow bed head to the east wall, her jars of
	# living things on a low table, her drawings, the pearl-blank lens.
	if not layout.at_any([{"pos": Vector2(w - 1.05, -n + 0.5), "yaw": 0.0}], 1.05, 0.5, 0.0, "Pree's bed", 0.6).is_empty():
		_narrow_bed(body, Vector3(w - 1.05, f, -n + 0.5), Color(0.42, 0.62, 0.66))
	if not layout.at_any([{"pos": Vector2(0.35, -2.2), "yaw": StiltKit.yaw_back_to(Vector2(-1, 0))}], 0.4, 0.25, 0.0, "Pree's jar table", 0.7).is_empty():
		Furnishings.piece(body, Vector3(0.25, 0.03, 0.4), Furnishings.OAK_LIGHT, Vector3(0.35, f + 0.62, -2.2), 0.0, true)
		for sz: float in [-1.0, 1.0]:
			Furnishings.piece(body, Vector3(0.03, 0.3, 0.03), Furnishings.OAK_DARK, Vector3(0.35, f + 0.3, -2.2 + sz * 0.33))
		for i in 3:
			Furnishings.piece(body, Vector3(0.07, 0.1, 0.07), Color(0.70, 0.86, 0.88, 0.7), Vector3(0.35, f + 0.75, -2.45 + 0.22 * float(i)), 0.0, false, 2.2)
	for i in 3:
		Furnishings.piece(body, Vector3(0.14, 0.11, 0.008), Color(0.95, 0.92, 0.82), Vector3(1.0 + 0.36 * float(i), f + 1.5 + 0.1 * float(i % 2), nr - 0.09), 0.0, false)
	Furnishings.hanging_lamp(body, Vector3(1.5, f + 2.5, -2.6), 0.5, 4.0)

	# Dala's room (south-west): her narrow bed by the window onto the water, the
	# chair she watches the lake from at night, a wall of charms, the rain jar.
	if not layout.at_any([{"pos": Vector2(-w + 1.05, n - 0.5), "yaw": 0.0}], 1.05, 0.5, 0.0, "Dala's bed", 0.6).is_empty():
		_narrow_bed(body, Vector3(-w + 1.05, f, n - 0.5), Color(0.56, 0.36, 0.30))
	if not layout.at_any([{"pos": Vector2(-w + 0.4, sr + 0.55), "yaw": 0.0}], 0.3, 0.3, 0.0, "Dala's chair", 0.9).is_empty():
		Furnishings.armchair(body, Vector3(-w + 0.4, f, sr + 0.55), StiltKit.yaw_back_to(Vector2(1, 0)), ochre.darkened(0.2))
	for i in 6:
		Furnishings.piece(body, Vector3(0.03, 0.06, 0.012), Color(0.62, 0.44, 0.26).darkened(0.07 * float(i % 3)), Vector3(-0.09, f + 1.5 + 0.18 * float(i / 3), sr + 0.6 + 0.3 * float(i % 3)), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.08, 0.14, 0.08), Color(0.62, 0.78, 0.84, 0.6), Vector3(-0.5, f + 0.14, n - 1.25), 0.0, false, 2.2)
	Furnishings.hanging_lamp(body, Vector3(-1.5, f + 2.5, 2.6), 0.5, 4.0)

	# Kitchen (south-east): the brazier and hood on the east wall, dried fish on
	# a rack, jars of pickled weed, a stone mortar by the wet door.
	var brazier_at := Vector2(w - 0.4, sr + 0.6)
	ClearZones.add(body, "Aran brazier", "fire", brazier_at, Vector2(-1, 0), 0.4, 0.7, 0.45, f, f + 1.6)
	layout.reserve(brazier_at, Vector2(0.35, 0.35))
	_brazier(body, Vector3(brazier_at.x, f, brazier_at.y), f + StiltKit.RING_BEAM)
	# Jars of pickled weed on a low bench under the east window.
	if not layout.at_any([{"pos": Vector2(w - 0.22, 3.1), "yaw": StiltKit.yaw_back_to(Vector2(1, 0))}], 0.45, 0.2, 0.0, "pickled weed bench", 0.6).is_empty():
		Furnishings.piece(body, Vector3(0.2, 0.25, 0.45), Furnishings.OAK, Vector3(w - 0.22, f + 0.25, 3.1), 0.0, true)
		for i in 3:
			Furnishings.piece(body, Vector3(0.08, 0.11, 0.08), Color(0.48, 0.58, 0.34).darkened(0.08 * float(i)), Vector3(w - 0.22, f + 0.61, 2.8 + 0.3 * float(i)), 0.0, false, 2.2)
	Furnishings.pot_rack(body, Vector3(1.5, f, sr + 0.15), 0.0, 1.4, 2.3)
	for i in 4:
		Furnishings.piece(body, Vector3(0.04, 0.16, 0.08), Color(0.64, 0.54, 0.40), Vector3(1.0 + 0.32 * float(i), f + 2.0, sr + 0.15), 0.0, false, SuperEgg.EPSILON_SOFT)
	if not layout.at_any([{"pos": Vector2(0.38, sr + 0.6), "yaw": 0.0}], 0.25, 0.25, 0.0, "stone mortar", 0.5).is_empty():
		Furnishings.piece(body, Vector3(0.22, 0.22, 0.22), Color(0.56, 0.54, 0.50), Vector3(0.38, f + 0.22, sr + 0.6), 0.0, true, 2.4)
	Furnishings.hanging_lamp(body, Vector3(1.5, f + 2.5, 2.7), 0.5, 4.0)

	for failure in layout.failures:
		push_warning("AranHouse interior: " + failure)

	# The veranda, where Dala reads the weather: her worn chair facing the court,
	# the shell barometer on a string, the bell to call the weather, a blanket on
	# the rail, Pree's herb floats tied by short lines below it.
	var vx := ARAN_VERANDA_X
	Furnishings.armchair(body, Vector3(vx + 0.38, f, -2.4), StiltKit.yaw_back_to(Vector2(1, 0)), ochre.darkened(0.25))
	for i in 7:
		Furnishings.piece(body, Vector3(0.035, 0.025, 0.035), Color(0.92, 0.86, 0.76), Vector3(vx + 0.25, f + 2.0 - 0.1 * float(i), -1.6), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.008, 0.38, 0.008), StiltKit.ROPE, Vector3(vx + 0.25, f + 1.75, -1.6))
	Furnishings.piece(body, Vector3(0.14, 0.16, 0.14), Color(0.70, 0.56, 0.26), Vector3(vx + 0.2, f + 1.85, 2.9), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.04, 0.3, 0.55), Color(0.62, 0.32, 0.26), Vector3(vx - 0.02, f + 0.78, 0.6), 0.0, false, SuperEgg.EPSILON_SOFT)
	for i in 3:
		var raft := Vector3(vx - 0.9 - 0.25 * float(i % 2), 0.05, -1.0 + 1.3 * float(i))
		Furnishings.piece(body, Vector3(0.4, 0.05, 0.3), StiltKit.TIMBER_PALE, raft, 0.2 * float(i), false)
		for k in 3:
			Furnishings.piece(body, Vector3(0.09, 0.12, 0.09), Color(0.36, 0.56, 0.28).lightened(0.06 * float(k)), raft + Vector3(-0.22 + 0.22 * float(k), 0.15, 0.0), 0.0, false, SuperEgg.EPSILON_SOFT)
		Furnishings.piece(body, Vector3(0.006, 0.006, 0.45), StiltKit.ROPE, raft + Vector3(0.6, 0.35, 0.0), 0.0, false)


## A narrow bed for one, 2.1 x 1.0, lying along x with its pillow at +x.
static func _narrow_bed(body: StaticBody3D, at: Vector3, blanket: Color) -> void:
	Furnishings.piece(body, Vector3(1.05, 0.2, 0.5), TownProps.BED_FRAME_COLOR, at + Vector3(0, 0.2, 0), 0.0, true)
	Furnishings.piece(body, Vector3(0.98, 0.08, 0.44), TownProps.BED_MATTRESS_COLOR, at + Vector3(0, 0.46, 0), 0.0, false, SuperEgg.EPSILON_SOFT)
	Furnishings.piece(body, Vector3(0.7, 0.05, 0.46), blanket, at + Vector3(-0.25, 0.53, 0), 0.0, false, SuperEgg.EPSILON_SOFT)
	Furnishings.piece(body, Vector3(0.2, 0.07, 0.3), Color(0.92, 0.90, 0.84), at + Vector3(0.78, 0.56, 0), 0.0, false, SuperEgg.EPSILON_SOFT)


# ---------------------------------------------------------------------------
# Shared furnishings particular to this village
# ---------------------------------------------------------------------------

## A clay brazier on a stand with a smoke hood above it and a flue to the roof.
static func _brazier(body: StaticBody3D, at: Vector3, ceiling_y: float) -> void:
	# The brazier is the fire itself, so its own body may stand in its fire zone.
	var stand := Furnishings.piece(body, Vector3(0.3, 0.2, 0.3), Furnishings.CLAY.darkened(0.15), at + Vector3(0, 0.2, 0), 0.0, false, 2.4)
	ClearZones.mark_furniture(CollisionPolicy.add_box(body, stand, Vector3(0.6, 0.4, 0.6), stand.position, Basis(), false), true)
	Furnishings.piece(body, Vector3(0.32, 0.12, 0.32), Furnishings.CLAY, at + Vector3(0, 0.52, 0), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.2, 0.03, 0.2), Color(0.95, 0.45, 0.15), at + Vector3(0, 0.63, 0), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.12, 0.1, 0.12), Color(0.25, 0.25, 0.27), at + Vector3(0.05, 0.72, 0), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.42, 0.14, 0.42), Furnishings.CLAY.darkened(0.3), at + Vector3(0, 1.9, 0), 0.0, false, 3.0)
	var flue_bottom := at.y + 2.0
	Furnishings.piece(body, Vector3(0.09, (ceiling_y - flue_bottom) * 0.5 + 0.05, 0.09), Furnishings.CLAY.darkened(0.35), Vector3(at.x, (ceiling_y + flue_bottom) * 0.5, at.z), 0.0, false, 2.4)


## A low table for floor sitting, with cushions in the household colour.
static func _low_table(body: StaticBody3D, at: Vector3, cloth: Color) -> void:
	Furnishings.piece(body, Vector3(0.45, 0.035, 0.3), Furnishings.OAK_LIGHT, at + Vector3(0, 0.4, 0), 0.0, true)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			Furnishings.piece(body, Vector3(0.04, 0.18, 0.04), Furnishings.OAK_DARK, at + Vector3(sx * 0.37, 0.18, sz * 0.22))
	for offset: Vector3 in [Vector3(-0.32, 0, -0.55), Vector3(0.32, 0, -0.55), Vector3(-0.32, 0, 0.55), Vector3(0.32, 0, 0.55)]:
		Furnishings.piece(body, Vector3(0.24, 0.07, 0.24), cloth.lightened(0.15), at + offset + Vector3(0, 0.07, 0), 0.0, false, SuperEgg.EPSILON_SOFT)
	# A broken compass in a bowl.
	Furnishings.piece(body, Vector3(0.12, 0.04, 0.12), Furnishings.CLAY, at + Vector3(0.2, 0.47, 0.05), 0.0, false, 2.2)
	Furnishings.piece(body, Vector3(0.05, 0.015, 0.05), Color(0.72, 0.60, 0.30), at + Vector3(0.2, 0.51, 0.05), 0.0, false, 2.0)


## Lio's shells on a plank shelf, graded smallest to largest.
static func _shell_shelf(body: StaticBody3D, at: Vector3) -> void:
	for level: float in [0.9, 1.3]:
		Furnishings.piece(body, Vector3(0.12, 0.02, 0.5), Furnishings.OAK, at + Vector3(0, level, 0))
		for i in 6:
			var size := 0.03 + 0.012 * float(i)
			Furnishings.piece(body, Vector3(size, size * 0.6, size), Color(0.90, 0.84, 0.74).darkened(0.04 * float(i % 3)), at + Vector3(0, level + 0.02 + size * 0.6, -0.4 + 0.16 * float(i)), 0.0, false, 2.2)


## A board of practice knots on pegs.
static func _knot_rack(body: StaticBody3D, at: Vector3) -> void:
	Furnishings.piece(body, Vector3(0.55, 0.15, 0.015), Furnishings.OAK, at + Vector3(0, 1.6, 0))
	for i in 5:
		Furnishings.piece(body, Vector3(0.012, 0.16, 0.012), StiltKit.ROPE, at + Vector3(-0.4 + 0.2 * float(i), 1.42, -0.03))
		Furnishings.piece(body, Vector3(0.04, 0.035, 0.035), StiltKit.ROPE.darkened(0.15), at + Vector3(-0.4 + 0.2 * float(i), 1.3 + 0.03 * float(i % 2), -0.03), 0.0, false, 2.0)
