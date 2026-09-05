class_name ShopCatalog
extends RefCounted

## Single source of truth for every item that can be bought, sold, held, or
## thrown -- replaces what used to be a duplicated SHOP_ITEMS const in
## town_generator.gd. Read by ShopUI (buy/sell lists), town_generator.gd
## (shop-counter scenery), player.gd (held-item visual), and thrown_item.gd
## (element lookup on a blorb hit).
##
## Built lazily via _ensure_items() rather than a plain `const` array --
## GDScript consts must be compile-time constants, and build_visual entries
## need Callable.bind(), which is a runtime call.

const FIRE_COLOR := Color(1.0, 0.4, 0.1)
const WATER_COLOR := Color(0.2, 0.55, 1.0)
const ELECTRIC_COLOR := Color(0.95, 0.85, 0.2)
const AIR_COLOR := Color(0.55, 0.9, 1.0)
const ROCK_COLOR := Color(0.55, 0.4, 0.24)
const GROUND_COLOR := Color(0.35, 0.24, 0.1)
const PLANT_COLOR := Color(0.35, 0.8, 0.3)

static var _items: Array[Dictionary] = []


static func get_items() -> Array[Dictionary]:
	_ensure_items()
	return _items


## Every entry carries a "shop" key (antique/red/green) naming which
## vendor stall sells it -- used to filter ShopUI.open() per-vendor so the
## armorer's stall doesn't also offer curios, etc. See npc.gd's
## shop_category.
static func get_items_for_shop(shop: String) -> Array[Dictionary]:
	_ensure_items()
	var result: Array[Dictionary] = []
	for item in _items:
		var additional_shops: Array = item.get("shops", [])
		if item.get("shop", "antique") == shop or additional_shops.has(shop):
			result.append(item)
	return result


static func find(item_name: String) -> Dictionary:
	_ensure_items()
	for item in _items:
		if item["name"] == item_name:
			return item
	return {}


static func _ensure_items() -> void:
	if not _items.is_empty():
		return
	_items = [
		{
			"name": "Fire Gem", "color": FIRE_COLOR, "price": 26, "sell_price": 12,
			"purchasable": true, "element": "fire", "description": "Warm to the touch even in shade.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(FIRE_COLOR),
		},
		{
			"name": "Water Gem", "color": WATER_COLOR, "price": 0, "sell_price": 5,
			"purchasable": false, "element": "water", "description": "Found in the fountain, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(WATER_COLOR),
		},
		{
			"name": "Electric Gem", "color": ELECTRIC_COLOR, "price": 32, "sell_price": 13,
			"purchasable": true, "element": "electric", "description": "Faint static crackles across its facets.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(ELECTRIC_COLOR),
		},
		{
			"name": "Air Gem", "color": AIR_COLOR, "price": 0, "sell_price": 7,
			"purchasable": false, "element": "air", "description": "Found on a hill overlooking town, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(AIR_COLOR),
		},
		{
			"name": "Rock Gem", "color": ROCK_COLOR, "price": 0, "sell_price": 6,
			"purchasable": false, "element": "rock", "description": "Found out in the canyon, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(ROCK_COLOR),
		},
		{
			"name": "Ground Gem", "color": GROUND_COLOR, "price": 0, "sell_price": 6,
			"purchasable": false, "element": "ground", "description": "Found atop the canyon's tallest hoodoo, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(GROUND_COLOR),
		},
		{
			"name": "Plant Gem", "color": PLANT_COLOR, "price": 0, "sell_price": 6,
			"purchasable": false, "element": "plant", "description": "Found atop a jungle tree, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(PLANT_COLOR),
		},
		{
			"name": "Diving Helmet", "color": Color(0.18, 0.58, 0.82), "price": 25, "sell_price": 12,
			"purchasable": true, "element": "", "core_item": "Diving Helmet", "shop": "lake",
			"description": "Throw it into a blorb to bind a sealed diving helmet to its core.",
			"build_visual": Callable(ShopCatalog, "_build_diving_helmet_visual"),
		},
		{
			"name": "Lake Shell", "color": Color(0.92, 0.72, 0.54), "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "shop": "lake",
			"description": "A warm-striped shell gathered from the newly exposed shore.",
			"build_visual": Callable(ShopCatalog, "_build_shell_visual"),
		},
		{
			"name": "Freshwater Clam", "color": Color(0.48, 0.34, 0.28), "price": 0, "sell_price": 3,
			"purchasable": false, "element": "", "shop": "lake",
			"description": "A heavy ridged clam found where the shallows meet the basin.",
			"build_visual": Callable(ShopCatalog, "_build_clam_visual"),
		},
		{
			"name": "Lakeweed", "color": Color(0.12, 0.42, 0.25), "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "shop": "lake",
			"description": "A supple strand of vegetation harvested from the lake floor.",
			"build_visual": Callable(ShopCatalog, "_build_lakeweed_visual"),
		},
		{
			"name": "Knight's Helm", "color": Color(0.34, 0.36, 0.39), "price": 28, "sell_price": 14,
			"purchasable": true, "element": "", "core_item": "Knight's Helm", "shop": "city",
			"description": "A sealed steel helm. A blorb can bind one head modification at a time.",
			"build_visual": Callable(ShopCatalog, "_build_knights_helm_visual"),
		},
		{
			"name": "Corroded Pocket Compass", "color": Color(0.55, 0.42, 0.18), "price": 4, "sell_price": 4,
			"purchasable": true, "element": "", "shops": ["lake", "antique"],
			"description": "Its needle never settles.",
			"build_visual": Callable(AntiqueProps, "build_compass"),
		},
		{
			"name": "Sealed Reliquary Locket", "color": Color(0.62, 0.5, 0.28), "price": 8, "sell_price": 4,
			"purchasable": true, "element": "", "description": "Won't open, however hard you try.",
			"build_visual": Callable(AntiqueProps, "build_locket"),
		},
		{
			"name": "Cracked Hourglass", "color": Color(0.78, 0.65, 0.4), "price": 6, "sell_price": 3,
			"purchasable": true, "element": "", "description": "The sand stopped falling long ago.",
			"build_visual": Callable(AntiqueProps, "build_hourglass"),
		},
		{
			"name": "Notched Shortsword", "color": Color(0.75, 0.77, 0.8), "price": 18, "sell_price": 7,
			"purchasable": true, "element": "", "shop": "red", "shops": ["city"],
			"description": "Seen some use. Still holds an edge.",
			"build_visual": Callable(RedShopProps, "build_sword"),
		},
		{
			"name": "Dented Breastplate", "color": Color(0.5, 0.52, 0.56), "price": 22, "sell_price": 9,
			"purchasable": true, "element": "", "shop": "red", "shops": ["city"],
			"description": "Whoever wore it last, it stopped whatever hit it.",
			"build_visual": Callable(RedShopProps, "build_armor"),
		},
		{
			"name": "Pitch Torch", "color": Color(0.95, 0.55, 0.15), "price": 10, "sell_price": 4,
			"purchasable": true, "element": "", "shop": "red", "shops": ["city", "lake"],
			"description": "Burns steady without ever needing relighting.",
			"build_visual": Callable(RedShopProps, "build_torch"),
		},
		{
			"name": "Rye Loaf", "color": Color(0.66, 0.46, 0.24), "price": 5, "sell_price": 2,
			"purchasable": true, "element": "", "shop": "green", "shops": ["lake"],
			"description": "Dense enough to survive the bottom of a pack.",
			"build_visual": Callable(GreenShopProps, "build_bread"),
		},
		{
			"name": "Wedge of Cheese", "color": Color(0.92, 0.78, 0.25), "price": 4, "sell_price": 2,
			"purchasable": true, "element": "", "shop": "green",
			"description": "Waxed rind, sharp inside.",
			"build_visual": Callable(GreenShopProps, "build_cheese"),
		},
		{
			"name": "Dried Berries", "color": Color(0.55, 0.12, 0.22), "price": 3, "sell_price": 1,
			"purchasable": true, "element": "", "shop": "green", "shops": ["lake"],
			"description": "Shriveled, but they'll keep for months.",
			"build_visual": Callable(GreenShopProps, "build_berries"),
		},
		{
			"name": "Apple", "color": NatureProps.FRUIT_COLORS["Apple"], "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Apple"]),
		},
		{
			"name": "Orange", "color": NatureProps.FRUIT_COLORS["Orange"], "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Orange"]),
		},
		{
			"name": "Lemon", "color": NatureProps.FRUIT_COLORS["Lemon"], "price": 0, "sell_price": 1,
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Lemon"]),
		},
		{
			"name": "Plum", "color": NatureProps.FRUIT_COLORS["Plum"], "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Plum"]),
		},
		{
			"name": "Banana", "color": NatureProps.FRUIT_COLORS["Banana"], "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "description": "Fallen from a banana tree in the jungle.",
			"build_visual": Callable(ShopCatalog, "_build_banana_visual").bind(NatureProps.FRUIT_COLORS["Banana"]),
		},
		{
			"name": "Durian", "color": NatureProps.FRUIT_COLORS["Durian"], "price": 0, "sell_price": 3,
			"purchasable": false, "element": "", "description": "Fallen from a durian tree in the jungle. Smells worse than it looks.",
			"build_visual": Callable(ShopCatalog, "_build_durian_visual"),
		},
		{
			"name": "Red Flower", "color": NatureProps.FLOWER_COLORS["Red Flower"], "price": 0, "sell_price": 1,
			"purchasable": false, "element": "", "description": "Picked from the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_flower_visual").bind(NatureProps.FLOWER_COLORS["Red Flower"]),
		},
		{
			"name": "Yellow Flower", "color": NatureProps.FLOWER_COLORS["Yellow Flower"], "price": 0, "sell_price": 1,
			"purchasable": false, "element": "", "description": "Picked from the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_flower_visual").bind(NatureProps.FLOWER_COLORS["Yellow Flower"]),
		},
		{
			"name": "Purple Flower", "color": NatureProps.FLOWER_COLORS["Purple Flower"], "price": 0, "sell_price": 1,
			"purchasable": false, "element": "", "description": "Picked from the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_flower_visual").bind(NatureProps.FLOWER_COLORS["Purple Flower"]),
		},
		{
			"name": "Orchid", "color": NatureProps.FLOWER_COLORS["Orchid"], "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "description": "Picked from the jungle, more delicate than the flowers found elsewhere.",
			"build_visual": Callable(ShopCatalog, "_build_flower_visual").bind(NatureProps.FLOWER_COLORS["Orchid"]),
		},
		{
			"name": "Red Mushroom", "color": NatureProps.MUSHROOM_COLORS["Red Mushroom"], "price": 0, "sell_price": 1,
			"purchasable": false, "element": "", "description": "Picked from the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_mushroom_visual").bind(NatureProps.MUSHROOM_COLORS["Red Mushroom"]),
		},
		{
			"name": "Tan Mushroom", "color": NatureProps.MUSHROOM_COLORS["Tan Mushroom"], "price": 0, "sell_price": 1,
			"purchasable": false, "element": "", "description": "Picked from the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_mushroom_visual").bind(NatureProps.MUSHROOM_COLORS["Tan Mushroom"]),
		},
		{
			"name": "Jungle Mushroom", "color": NatureProps.MUSHROOM_COLORS["Jungle Mushroom"], "price": 0, "sell_price": 2,
			"purchasable": false, "element": "", "description": "Picked from the jungle, colored like nothing found elsewhere.",
			"build_visual": Callable(ShopCatalog, "_build_mushroom_visual").bind(NatureProps.MUSHROOM_COLORS["Jungle Mushroom"]),
		},
	]


static func _build_gem_visual(item_scale: float, color: Color) -> Node3D:
	var packed: PackedScene = load("res://scenes/gem.tscn")
	var gem = packed.instantiate()
	gem.gem_color = color
	gem.scale = Vector3.ONE * item_scale
	# GripPoint: a gem is a bipyramid (see gem.gd's own _build_mesh, two
	# 6-sided pyramids joined base-to-base) with no flat face of its own --
	# the bottom point is the closest thing to a natural resting spot for
	# it to sit against the palm (see player.gd's own _on_held_item_changed
	# for how this gets used). First pass, not visually verified in-engine.
	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3(0, -gem.height * 0.5, 0)
	gem.add_child(grip)
	return gem


## Shares its geometry with fruit.gd's own ground pickup (see NatureProps.
## build_fruit_visual()'s own doc comment) -- a fruit reads the same whether
## it's sitting under a tree, held in the player's hand, or mid-throw.
static func _build_fruit_visual(item_scale: float, color: Color) -> Node3D:
	return NatureProps.build_fruit_visual(color, 0.09, item_scale)


## Shares its geometry with fruit.gd's own Banana ground pickup (see
## NatureProps.build_banana_fruit()) -- same reasoning as _build_fruit_visual
## above, just for the curved-segment shape instead of the plain sphere.
static func _build_banana_visual(item_scale: float, color: Color) -> Node3D:
	return NatureProps.build_banana_fruit(color, 0.09, item_scale)


## Shares its geometry with fruit.gd's own Durian ground pickup (see
## NatureProps.build_durian_fruit()).
static func _build_durian_visual(item_scale: float) -> Node3D:
	return NatureProps.build_durian_fruit(NatureProps.FRUIT_COLORS["Durian"], 0.16, item_scale)


## Shares its geometry with flower_pickup.gd's own ground pickup (see
## NatureProps.build_flower()). NatureProps.build_flower() itself has no
## item_scale of its own (it's only ever built at one fixed size out in the
## wilderness), so this wraps it in a scaled root the same way
## _build_fruit_visual's underlying NatureProps.build_fruit_visual() does.
static func _build_flower_visual(item_scale: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	root.add_child(NatureProps.build_flower(color))
	var grip := Node3D.new()
	grip.name = "GripPoint"
	root.add_child(grip)
	return root


## Shares its geometry with mushroom_pickup.gd's own ground pickup (see
## NatureProps.build_mushroom()), wrapped the same way _build_flower_visual
## wraps build_flower() above.
static func _build_mushroom_visual(item_scale: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	root.add_child(NatureProps.build_mushroom(color))
	var grip := Node3D.new()
	grip.name = "GripPoint"
	root.add_child(grip)
	return root


static func _build_shell_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var shell := SuperEgg.build_part(Vector3(0.24, 0.08, 0.2), Color(0.92, 0.72, 0.54), 2.4, 3.4)
	shell.position.y = 0.08
	root.add_child(shell)
	for i in 4:
		var ridge := SuperEgg.build_part(Vector3(0.025, 0.015, 0.16), Color(0.72, 0.43, 0.3), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		ridge.position = Vector3((float(i) - 1.5) * 0.07, 0.158, 0)
		root.add_child(ridge)
	_add_catalog_grip(root)
	return root


static func _build_clam_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	for z in [-0.045, 0.045]:
		var half := SuperEgg.build_part(Vector3(0.23, 0.08, 0.14), Color(0.48, 0.34, 0.28), 3.0, 3.8)
		half.position = Vector3(0, 0.08, z)
		root.add_child(half)
	_add_catalog_grip(root)
	return root


static func _build_lakeweed_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var colors := [Color(0.08, 0.34, 0.18), Color(0.12, 0.42, 0.25), Color(0.18, 0.5, 0.28)]
	for i in 3:
		var blade := SuperEgg.build_part(Vector3(0.045, 0.34 + i * 0.06, 0.025), colors[i], SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		blade.position = Vector3((float(i) - 1.0) * 0.08, 0.3 + i * 0.04, 0)
		blade.rotation.z = (float(i) - 1.0) * 0.2
		root.add_child(blade)
	_add_catalog_grip(root)
	return root


static func _add_catalog_grip(root: Node3D) -> void:
	var grip := Node3D.new()
	grip.name = "GripPoint"
	root.add_child(grip)


static func _build_diving_helmet_visual(item_scale: float = 1.0) -> Node3D:
	# A wearable diving shell must clear the whole head rather than reading
	# like a handheld toy. Size it from the actual player head proportions.
	var helmet_radius := maxf(ProceduralFigure.HEAD_SIZE.x, ProceduralFigure.HEAD_SIZE.z) * 1.45
	var helmet_height := maxf(helmet_radius * 2.0, ProceduralFigure.HEAD_SIZE.y * 2.0 * 1.25)
	return _build_open_helmet(
		item_scale, helmet_radius, helmet_height,
		Color(0.18, 0.58, 0.82, 0.9), 0.45, 0.22
	)


static func _build_knights_helm_visual(item_scale: float = 1.0) -> Node3D:
	# The physical item shares the exact same continuous helmet silhouette as
	# the perfected blorb form; only its steel finish and small crest dressing
	# differ while it is on a counter, in a hand, or being thrown.
	var root := Node3D.new()
	var radius := 0.12 * item_scale
	var shell := MeshInstance3D.new()
	shell.name = "KnightHelmBody"
	shell.mesh = BlorbBodyShape.build_mesh_from_rings(BlorbSuit._build_knight_helm_rings(radius))
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.34, 0.36, 0.39)
	material.metallic = 0.9
	material.roughness = 0.28
	shell.material_override = material
	root.add_child(shell)
	var crest_node := MeshInstance3D.new()
	crest_node.name = "CrestRidge"
	# Match the blorb helm's curved, rear-taller mohawk silhouette, but make
	# the item's dressing a distinct red lacquer over the metal shell.
	crest_node.mesh = BlorbSuit._build_knight_helm_crest_mesh(radius)
	var crest_material := StandardMaterial3D.new()
	crest_material.albedo_color = Color(0.68, 0.06, 0.045)
	crest_material.metallic = 0.25
	crest_material.roughness = 0.4
	crest_node.material_override = crest_material
	root.add_child(crest_node)
	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3(0.0, -radius * 1.38, 0.0)
	root.add_child(grip)
	return root


static func _add_helm_part(
	parent: Node3D, part_name: String, semi_axes: Vector3,
	position: Vector3, material: StandardMaterial3D
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = part_name
	part.mesh = SuperEgg.build_mesh(semi_axes, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	part.position = position
	part.material_override = material
	parent.add_child(part)
	return part


## Builds a real open-bottom helmet rather than a closed sphere disguised as
## one. The shell stops above its south pole; a torus collar gives the head
## opening a readable, reinforced rim from table, hand, and portrait angles.
static func _build_open_helmet(
	item_scale: float, radius: float, height: float,
	color: Color, metallic: float, roughness: float
) -> Node3D:
	const SEGMENTS := 24
	const RINGS := 10
	const OPEN_ANGLE := 2.05
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness

	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index in RINGS:
		var theta_0 := OPEN_ANGLE * float(ring_index) / float(RINGS)
		var theta_1 := OPEN_ANGLE * float(ring_index + 1) / float(RINGS)
		for segment_index in SEGMENTS:
			var phi_0 := TAU * float(segment_index) / float(SEGMENTS)
			var phi_1 := TAU * float(segment_index + 1) / float(SEGMENTS)
			var p00 := _helmet_point(radius, height, theta_0, phi_0)
			var p01 := _helmet_point(radius, height, theta_0, phi_1)
			var p10 := _helmet_point(radius, height, theta_1, phi_0)
			var p11 := _helmet_point(radius, height, theta_1, phi_1)
			_helmet_vertex(surface, p00, radius, height)
			_helmet_vertex(surface, p11, radius, height)
			_helmet_vertex(surface, p10, radius, height)
			_helmet_vertex(surface, p00, radius, height)
			_helmet_vertex(surface, p01, radius, height)
			_helmet_vertex(surface, p11, radius, height)
	var shell := MeshInstance3D.new()
	shell.name = "Shell"
	shell.mesh = surface.commit()
	shell.material_override = material

	var opening_radius := radius * sin(OPEN_ANGLE)
	var opening_y := height * 0.5 * cos(OPEN_ANGLE)
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = opening_radius * 0.90
	rim_mesh.outer_radius = opening_radius * 1.08
	rim_mesh.rings = 24
	rim_mesh.ring_segments = 8
	var rim := MeshInstance3D.new()
	rim.name = "OpeningRim"
	rim.mesh = rim_mesh
	rim.position.y = opening_y
	rim.material_override = material

	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	root.add_child(shell)
	root.add_child(rim)
	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3(0.0, opening_y, 0.0)
	root.add_child(grip)
	return root


static func _helmet_point(radius: float, height: float, theta: float, phi: float) -> Vector3:
	return Vector3(
		radius * sin(theta) * cos(phi),
		height * 0.5 * cos(theta),
		radius * sin(theta) * sin(phi)
	)


static func _helmet_vertex(surface: SurfaceTool, point: Vector3, radius: float, height: float) -> void:
	var normal := Vector3(point.x / radius, point.y / (height * 0.5), point.z / radius).normalized()
	surface.set_normal(normal)
	surface.add_vertex(point)
