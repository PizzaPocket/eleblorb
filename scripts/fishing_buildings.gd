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
const BUILT := ["VennHouse"]

const SHELF_Y := -3.2 - 0.4
const HOUSE_FLOOR := FishingVillagePlan.HOUSE_FLOOR
const DECK_TOP := FishingVillagePlan.DECK_TOP


static func build(name_text: String) -> StaticBody3D:
	match name_text:
		"VennHouse":
			return venn_house()
	return null


## Plan point the builder's origin stands on.
static func anchor(name_text: String) -> Vector2:
	match name_text:
		"VennHouse":
			return VENN_ORIGIN
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
		[StiltKit.door(Vector2(0.0, hz)), StiltKit.window(Vector2(-3.0, hz))], teal, VENN_SHUTTER)
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
	# Drawn facing into the store so its leaf swings into the room it serves,
	# not across the veranda.
	StiltKit.wall(body, Vector2(1.5, hz), Vector2(1.5, vz), Vector2(1, 0), f, VENN_PENT_AT_WALL,
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
	ClearZones.add_lane(body, "landing to front door", [Vector3(0.0, f, vz - 0.6), Vector3(0.0, f, 4.15)], 0.55)
	ClearZones.add_lane(body, "through the front door", [Vector3(0.0, f, 4.15), Vector3(0.0, f, hz - 0.5)])
	ClearZones.add_lane(body, "front door to Lio's door", [Vector3(0.0, f, hz - 0.4), Vector3(-0.9, f, 1.0), Vector3(-2.2, f, 1.0)])
	ClearZones.add_lane(body, "front door to the bedroom door", [Vector3(0.0, f, hz - 0.4), Vector3(0.9, f, 1.0), Vector3(2.2, f, 1.0)])
	# The front door's leaf stands open on the veranda (exterior doors open
	# outward throughout the world), so the way to the store passes south of it.
	ClearZones.add_lane(body, "veranda to the store", [Vector3(-0.6, f, 4.1), Vector3(0.9, f, 4.0), Vector3(1.0, f, 3.5), Vector3(2.3, f, 3.5)])

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
