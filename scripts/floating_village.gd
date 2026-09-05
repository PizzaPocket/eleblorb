class_name FloatingVillage
extends Node3D

## A compact lake settlement inspired by the supplied stilt-village
## references: weathered timber decks, dense low gabled huts, narrow docks,
## and a few small boats. It is deliberately built at the lake waterline so
## its supports disappear into the deep basin rather than reading as a town
## dropped on dry terrain.

const CENTER := Vector3(440.0, 0.0, 0.0)
const DECK_Y := 0.34
const NPC_SCENE := "res://scenes/npc.tscn"
# Clear of every stilt/hut/boat/dock footprint listed in _build() below (the
# nearest, the (-17,-9) hut, sits ~2 units off this dock's edge) -- the
# ocean_kingdom portal (see main.gd) gets its own small deck here rather than
# sharing one of the existing structures.
const PORTAL_OFFSET := Vector3(-26.0, 0.0, 3.5)

var _terrain: Node


func _ready() -> void:
	_terrain = get_node_or_null("../Terrain")
	call_deferred("_build")


func _build() -> void:
	if _terrain == null:
		return
	var center := Vector3(CENTER.x, _terrain.get_lake_water_level(), CENTER.z)
	var deck_color := Color(0.26, 0.16, 0.09)
	# Share the first village's lively roof language so this reads as a real
	# inhabited sister settlement rather than a uniformly brown dock.colo
	var roof_colors: Array[Color] = []
	roof_colors.assign(TownProps.ROOF_COLORS)
	var wall_colors: Array[Color] = [
		Color(0.72, 0.42, 0.22), Color(0.24, 0.55, 0.52), Color(0.82, 0.58, 0.22),
		Color(0.42, 0.35, 0.68), Color(0.76, 0.3, 0.28), Color(0.32, 0.58, 0.31),
	]
	# Central boardwalk and cross-docks.
	_build_box("MainDock", center + Vector3(0, DECK_Y, 0), Vector3(46, 0.32, 4), deck_color, true)
	_build_box("CrossDock", center + Vector3(5, DECK_Y, 0), Vector3(4, 0.32, 34), deck_color, true)
	_build_docking_ramps(center, deck_color)
	_build_streetlights(center)
	for x in [-19.0, -8.0, 7.0, 19.0]:
		for z in [-8.0, 8.0]:
			_build_stilt(Vector3(center.x + x, center.y, center.z + z))
	var huts := [
		Vector3(-17, 0, -9), Vector3(-7, 0, -9), Vector3(6, 0, -9),
		Vector3(17, 0, -9), Vector3(-13, 0, 9), Vector3(0, 0, 9), Vector3(14, 0, 9),
	]
	for i in huts.size():
		var p: Vector3 = huts[i]
		_build_hut(center + p + Vector3(0, DECK_Y, 0), roof_colors[i % roof_colors.size()], wall_colors[i % wall_colors.size()])
	var boat_specs := [
		{"pos": Vector3(-28, 0.2, -8), "yaw": -0.18, "color": TownProps.ROOF_COLORS[0]},
		{"pos": Vector3(28, 0.2, 7), "yaw": 0.22, "color": TownProps.ROOF_COLORS[1]},
		{"pos": Vector3(-23, 0.18, 12), "yaw": 0.55, "color": TownProps.ROOF_COLORS[2]},
		{"pos": Vector3(22, 0.18, -12), "yaw": -0.48, "color": TownProps.ROOF_COLORS[3]},
		{"pos": Vector3(-4, 0.16, -19), "yaw": 0.05, "color": TownProps.ROOF_COLORS[4]},
		{"pos": Vector3(8, 0.16, 19), "yaw": PI - 0.12, "color": TownProps.ROOF_COLORS[5]},
	]
	for spec in boat_specs:
		_build_boat(center + spec["pos"], spec["yaw"], spec["color"])
	_build_lake_shop_display(center + Vector3(1.25, DECK_Y + 0.02, -1.2))
	_build_vendor(center + Vector3(4, DECK_Y + 0.2, 0))
	_build_portal_dock(center, deck_color)


func _build_hut(pos: Vector3, roof_color: Color, wall: Color) -> void:
	_build_box("HutFloor", pos + Vector3(0, 0.2, 0), Vector3(7.2, 0.28, 5.8), wall, true)
	_build_box("HutWalls", pos + Vector3(0, 2.0, 0), Vector3(6.7, 3.2, 5.2), wall, true)
	# Two shallow sloped roof halves approximate the reference huts' broad
	# thatch without relying on an imported asset.
	_build_box("RoofL", pos + Vector3(-1.6, 4.25, 0), Vector3(3.8, 0.34, 6.1), roof_color, false, deg_to_rad(22))
	_build_box("RoofR", pos + Vector3(1.6, 4.25, 0), Vector3(3.8, 0.34, 6.1), roof_color, false, deg_to_rad(-22))
	for corner in [Vector3(-2.8, 0, -2.1), Vector3(2.8, 0, -2.1), Vector3(-2.8, 0, 2.1), Vector3(2.8, 0, 2.1)]:
		_build_stilt(pos + corner - Vector3(0, DECK_Y, 0))


## A small standalone deck for the ocean_kingdom return portal, built the
## same way a hut's floor is (its own corner stilts), so the gate reads as
## part of the settlement rather than floating unsupported above the water.
func _build_portal_dock(center: Vector3, deck_color: Color) -> void:
	var pos := center + PORTAL_OFFSET
	# Sized generously (vs. a hut's 7.2x5.8 footprint) so the 3-unit
	# behind-the-gate spawn offset used both here and by kingdom_bootstrap.gd
	# (see _place_returning_player() in main.gd) lands the returning player
	# on solid deck rather than off the edge into the water.
	_build_box("PortalDock", pos + Vector3(0, DECK_Y, 0), Vector3(7.0, 0.28, 7.0), deck_color, true)
	for corner in [Vector3(-3.0, 0, -3.0), Vector3(3.0, 0, -3.0), Vector3(-3.0, 0, 3.0), Vector3(3.0, 0, 3.0)]:
		_build_stilt(pos + corner)


## World-space spot for the ocean_kingdom portal to stand on, atop the small
## deck _build_portal_dock() builds -- see main.gd's _add_portal.
func get_portal_anchor() -> Vector3:
	var terrain: Node = get_node_or_null("../Terrain")
	var water_y: float = terrain.get_lake_water_level() if terrain != null else 0.0
	return Vector3(CENTER.x, water_y, CENTER.z) + PORTAL_OFFSET + Vector3(0, DECK_Y, 0)


func _build_stilt(pos: Vector3) -> void:
	_build_box("Stilt", pos + Vector3(0, -3.0, 0), Vector3(0.34, 6.0, 0.34), Color(0.2, 0.12, 0.07), false)


## Two wide, climbable ramps begin beneath the swimmer's surface position
## and finish flush with the main dock. This provides a real continuous
## route out of the lake for both the player and following blorbs.
func _build_docking_ramps(center: Vector3, color: Color) -> void:
	const WIDTH := 3.4
	const RUN := 8.0
	const RISE := 1.95
	const SUBMERGED_BASE := 1.45
	# These lanes occupy the actual gaps between hut footprints. The former
	# symmetric +/-12 placement intersected the huts centered around both
	# ends of the boardwalk, making the ramps look open but physically blocked.
	for x in [0.0]:
		var south_ramp := TownProps.build_ramp(WIDTH, RUN, RISE, color)
		south_ramp.name = "SouthDockRamp"
		south_ramp.position = center + Vector3(x, -SUBMERGED_BASE, -10.0)
		add_child(south_ramp)
	for x in [-6.5, 7.0]:
		var north_ramp := TownProps.build_ramp(WIDTH, RUN, RISE, color)
		north_ramp.name = "NorthDockRamp"
		north_ramp.position = center + Vector3(x, -SUBMERGED_BASE, 10.0)
		north_ramp.rotation.y = PI
		add_child(north_ramp)


## A few low village lanterns provide nighttime wayfinding without giving
## the fishing settlement the dense, tall street furniture of the city.
func _build_streetlights(center: Vector3) -> void:
	var positions := [
		Vector3(-12.0, DECK_Y + 0.16, 1.55),
		Vector3(12.0, DECK_Y + 0.16, -1.55),
		Vector3(3.25, DECK_Y + 0.16, -7.0),
		Vector3(6.75, DECK_Y + 0.16, 7.0),
	]
	for offset in positions:
		var lantern := TownProps.build_lantern()
		lantern.name = "FishingVillageStreetlight"
		lantern.position = center + offset
		add_child(lantern)


func _build_boat(pos: Vector3, yaw: float, hull_color: Color) -> void:
	var boat := Node3D.new()
	boat.name = "FishingBoat"
	boat.position = pos
	boat.rotation.y = yaw
	add_child(boat)
	# Rounded superegg hull, raised colored gunwales, a bench, and a compact
	# mast make these unmistakably small working fishing boats from shore.
	_add_boat_part(boat, Vector3(3.8, 0.32, 0.95), Vector3(0, 0, 0), hull_color, SuperEgg.EPSILON_SOFT)
	_add_boat_part(boat, Vector3(3.25, 0.08, 1.02), Vector3(0, 0.36, 0), hull_color.lightened(0.14), SuperEgg.EPSILON_FLAT)
	_add_boat_part(boat, Vector3(0.75, 0.08, 1.12), Vector3(0, 0.48, 0), Color(0.42, 0.25, 0.12), SuperEgg.EPSILON_FLAT)
	_add_boat_part(boat, Vector3(0.09, 0.82, 0.09), Vector3(-0.75, 0.92, 0), Color(0.3, 0.18, 0.1), SuperEgg.EPSILON_SOFT)


func _add_boat_part(parent: Node3D, semi_axes: Vector3, local_pos: Vector3, color: Color, epsilon: float) -> void:
	var part := SuperEgg.build_part(semi_axes, color, epsilon, epsilon)
	part.position = local_pos
	parent.add_child(part)


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


func _build_box(name_text: String, pos: Vector3, size: Vector3, color: Color, collision: bool, pitch := 0.0) -> void:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = name_text
	root.position = pos
	root.rotation.x = pitch
	add_child(root)
	# Every visible architectural member uses the project's shared superegg
	# primitive. Collision remains a simple box so docks and walls stay
	# robust under character physics, while the silhouette gets the softer,
	# coherent supershape language used across the rest of the world.
	var mesh := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	root.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		root.add_child(shape)


func _build_vendor(pos: Vector3) -> void:
	var packed: PackedScene = load(NPC_SCENE)
	if packed == null:
		return
	var vendor = packed.instantiate()
	vendor.set_terrain_reference(_terrain)
	vendor.stationary = true
	vendor.is_vendor = true
	vendor.display_name = "Lake Diver"
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
