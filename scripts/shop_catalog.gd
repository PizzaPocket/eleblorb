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
const CITY_COLOR := Color(0.2, 0.65, 0.95)
const ICE_COLOR := Color(0.78, 0.92, 0.98)
const SNOW_COLOR := ElementPalette.SNOW_BODY
const WOOD_COLOR := Color(0.42, 0.26, 0.15)
const BEAN_OF_LIFE_COLOR := Color(0.36, 0.6, 0.22)
const BLORB_SLIME_COLOR := Color(0.42, 0.92, 0.68)
const JINGU_BANG_RED := Color(0.75, 0.08, 0.06)
const JINGU_BANG_GOLD := Color(0.85, 0.66, 0.18)

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


static func edible_healing(item_name: String) -> float:
	var entry := find(item_name)
	if not bool(entry.get("edible", false)):
		return 0.0
	if entry.has("healing_amount"):
		return float(entry["healing_amount"])
	match String(entry.get("rarity", "common")):
		"uncommon": return 20.0
		"rare": return 35.0
		"exceptional": return 60.0
		_: return 10.0


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
			"name": "City Gem", "color": CITY_COLOR, "price": 0, "sell_price": 7,
			"purchasable": false, "element": "city", "description": "Found somewhere in the city streets, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(CITY_COLOR),
		},
		{
			"name": "Ice Gem", "color": ICE_COLOR, "price": 0, "sell_price": 8,
			"purchasable": false, "element": "ice", "description": "Cold enough to frost over in your hand, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(ICE_COLOR),
		},
		{
			"name": "Snow Gem", "color": SNOW_COLOR, "price": 0, "sell_price": 8,
			"purchasable": false, "element": "snow", "description": "Packed soft and cold, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(SNOW_COLOR),
		},
		{
			"name": "Wood Gem", "color": WOOD_COLOR, "price": 0, "sell_price": 8,
			"purchasable": false, "element": "wood", "description": "Smells faintly of an old forest, not sold here.",
			"build_visual": Callable(ShopCatalog, "_build_gem_visual").bind(WOOD_COLOR),
		},
		{
			"name": "Diving Helmet", "color": Color(0.18, 0.58, 0.82), "price": 25, "sell_price": 12,
			"purchasable": true, "element": "", "core_item": "Diving Helmet", "core_slot": "head", "armor_defense": 2, "shop": "lake",
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
			"name": "Nautilus Shell", "color": Color(0.42, 0.9, 0.78), "price": 12, "sell_price": 5,
			"purchasable": true, "element": "", "shop": "ocean_merfolk",
			"description": "A luminous spiral shell carried up from the deep city.",
			"build_visual": Callable(ShopCatalog, "_build_nautilus_shell_visual"),
		},
		{
			"name": "Watering Can", "color": Color(0.34, 0.68, 0.72), "price": 18, "sell_price": 8,
			"purchasable": true, "element": "", "shop": "ocean_merfolk",
			"description": "A small sea-metal vessel made for carrying living water.",
			"build_visual": Callable(ShopCatalog, "_build_watering_can_visual"),
		},
		{
			"name": "Nautilus Crown", "color": Color(0.36, 0.88, 0.74), "price": 0, "sell_price": 0,
			"purchasable": false, "element": "", "core_item": "Nautilus Crown", "core_slot": "head", "armor_defense": 7,
			"description": "The Tidekeeper's spiral crown.",
			"build_visual": Callable(ShopCatalog, "_build_nautilus_shell_visual"),
		},
		{
			"name": "Knight's Helm", "color": Color(0.34, 0.36, 0.39), "price": 28, "sell_price": 14,
			"purchasable": true, "element": "", "core_item": "Knight's Helm", "core_slot": "head", "armor_defense": 6, "shop": "city",
			"description": "A sealed steel helm. A blorb can bind one head modification at a time.",
			"build_visual": Callable(ShopCatalog, "_build_knights_helm_visual"),
		},
		{
			"name": "Toboggan", "color": TobogganHelm.KNIT_COLOR, "price": 18, "sell_price": 8,
			"purchasable": true, "element": "", "core_item": "Toboggan", "core_slot": "head", "armor_defense": 3, "shop": "snow",
			"description": "A thick winter knit with a folded band and soft pom-pom.",
			"build_visual": Callable(TobogganHelm, "build_visual"),
		},
		{
			"name": "Lava Helm", "color": Color(0.035, 0.03, 0.028), "price": 0, "sell_price": 0,
			"purchasable": false, "element": "", "core_item": "Lava Helm", "core_slot": "head", "armor_defense": 10,
			"required_element": "fire",
			"description": "A glassy volcanic helm whose swept crown is warm to the touch.",
			"build_visual": Callable(ShopCatalog, "_build_lava_helm_visual"),
		},
		{
			"name": "Penguin Helm", "color": PenguinHelm.HOOD_COLOR, "price": 0, "sell_price": 0,
			"purchasable": false, "element": "", "core_item": "Penguin Helm", "core_slot": "head", "armor_defense": 6,
			"required_element": "ice",
			"description": "A sleek dark hood with a slender beak, cold and smooth as sea ice.",
			"build_visual": Callable(PenguinHelm, "build_visual"),
		},
		{
			"name": "Bird Helm", "color": Color(0.62, 0.58, 0.42), "price": 0, "sell_price": 0,
			"purchasable": false, "element": "", "core_item": "Bird Helm", "core_slot": "head", "armor_defense": 4,
			"description": "Blorbaka's own crest -- said to lend a wearer sight of the Sky Kingdom.",
			"build_visual": Callable(ShopCatalog, "_build_bird_helm_visual"),
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
			"purchasable": true, "element": "", "shop": "red", "shops": ["city"], "weapon": true,
			"weapon_damage": 15.0, "weapon_reach": 1.65, "held_scale": 1.0,
			"description": "Seen some use. Still holds an edge.",
			"build_visual": Callable(RedShopProps, "build_sword"),
		},
		{
			"name": "Dented Breastplate", "color": Color(0.5, 0.52, 0.56), "price": 22, "sell_price": 9,
			"purchasable": true, "element": "", "core_item": "Dented Breastplate", "core_slot": "armor", "armor_defense": 5, "shop": "red", "shops": ["city"],
			"description": "Whoever wore it last, it stopped whatever hit it. A blorb can bind it as body armor.",
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
			"edible": true, "rarity": "uncommon",
			"purchasable": true, "element": "", "shop": "green", "shops": ["lake", "snow"],
			"description": "Dense enough to survive the bottom of a pack.",
			"build_visual": Callable(GreenShopProps, "build_bread"),
		},
		{
			"name": "Wedge of Cheese", "color": Color(0.92, 0.78, 0.25), "price": 4, "sell_price": 2,
			"edible": true, "rarity": "uncommon",
			"purchasable": true, "element": "", "shop": "green",
			"description": "Waxed rind, sharp inside.",
			"build_visual": Callable(GreenShopProps, "build_cheese"),
		},
		{
			"name": "Dried Berries", "color": Color(0.55, 0.12, 0.22), "price": 3, "sell_price": 1,
			"edible": true, "rarity": "common",
			"purchasable": true, "element": "", "shop": "green", "shops": ["lake", "snow"],
			"description": "Shriveled, but they'll keep for months.",
			"build_visual": Callable(GreenShopProps, "build_berries"),
		},
		{
			"name": "Apple", "color": NatureProps.FRUIT_COLORS["Apple"], "price": 0, "sell_price": 2,
			"edible": true, "rarity": "common",
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Apple"]),
		},
		{
			"name": "Orange", "color": NatureProps.FRUIT_COLORS["Orange"], "price": 0, "sell_price": 2,
			"edible": true, "rarity": "common",
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Orange"]),
		},
		{
			"name": "Lemon", "color": NatureProps.FRUIT_COLORS["Lemon"], "price": 0, "sell_price": 1,
			"edible": true, "rarity": "common",
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Lemon"]),
		},
		{
			"name": "Plum", "color": NatureProps.FRUIT_COLORS["Plum"], "price": 0, "sell_price": 2,
			"edible": true, "rarity": "common",
			"purchasable": false, "element": "", "description": "Fallen from a fruit tree out in the wilds.",
			"build_visual": Callable(ShopCatalog, "_build_fruit_visual").bind(NatureProps.FRUIT_COLORS["Plum"]),
		},
		{
			"name": "Banana", "color": NatureProps.FRUIT_COLORS["Banana"], "price": 0, "sell_price": 2,
			"edible": true, "rarity": "common",
			"purchasable": false, "element": "", "description": "Fallen from a banana tree in the jungle.",
			"build_visual": Callable(ShopCatalog, "_build_banana_visual").bind(NatureProps.FRUIT_COLORS["Banana"]),
		},
		{
			"name": "Durian", "color": NatureProps.FRUIT_COLORS["Durian"], "price": 0, "sell_price": 3,
			"edible": true, "rarity": "rare",
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
		{
			"name": "Seed of Life", "color": BEAN_OF_LIFE_COLOR, "price": 30, "sell_price": 14,
			"purchasable": true, "element": "", "shop": "chinese_village",
			"description": "A rare living seed. Plant it in the magical clearing to grow the Tree of Life.",
			"build_visual": Callable(ShopCatalog, "_build_bean_of_life_visual"),
		},
		{
			"name": "Blorb Slime", "color": BLORB_SLIME_COLOR, "price": 48, "sell_price": 22,
			"purchasable": true, "element": "", "shop": "green", "shops": ["lake", "ocean_merfolk"],
			"description": "Rare living slime that restores a blorb's body.",
			"build_visual": Callable(ShopCatalog, "_build_blorb_slime_visual"),
		},
		{
			"name": "Paper Lantern", "color": Color(0.95, 0.72, 0.32), "price": 9, "sell_price": 4,
			"purchasable": true, "element": "", "shop": "chinese_village",
			"description": "Lit from within. Warm to carry on a cold walk.",
			"build_visual": Callable(ShopCatalog, "_build_paper_lantern_visual"),
		},
		{
			"name": "Steamed Bun", "color": Color(0.94, 0.9, 0.82), "price": 4, "sell_price": 2,
			"edible": true, "rarity": "uncommon",
			"purchasable": true, "element": "", "shop": "chinese_village",
			"description": "Still warm from the basket.",
			"build_visual": Callable(ShopCatalog, "_build_steamed_bun_visual"),
		},
		{
			"name": "Jingu Bang", "color": JINGU_BANG_RED, "price": 0, "sell_price": 0,
			"purchasable": false, "element": "", "weapon": true,
			"weapon_damage": 24.0, "weapon_reach": 2.45,
			"description": "Sun Wu Kong's own legendary staff. Found, not sold.",
			"build_visual": Callable(ShopCatalog, "build_jingu_bang_visual"),
		},
		{
			"name": "Royal Meat Cleaver", "color": Color(0.68, 0.7, 0.72),
			"price": 0, "sell_price": 10, "purchasable": false, "element": "",
			"weapon": true, "weapon_damage": 19.0, "weapon_reach": 1.45,
			"held_scale": 1.0,
			"description": "The Royal Chef's weighty chopping cleaver.",
			"build_visual": Callable(ShopCatalog, "build_meat_cleaver_visual"),
		},
	]


static func _build_blorb_slime_visual(item_scale: float) -> Node3D:
	var root := Node3D.new()
	var drop := SuperEgg.build_part(Vector3(0.11,0.085,0.11)*item_scale,BLORB_SLIME_COLOR,2.4,2.8)
	drop.position.y = 0.085*item_scale
	root.add_child(drop)
	return root


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


static func _build_nautilus_shell_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var color := Color(0.42, 0.9, 0.78)
	for index in 11:
		var t := float(index) / 10.0
		var angle := t * TAU * 1.65
		var radius := lerpf(0.025, 0.19, t)
		var chamber := SuperEgg.build_part(Vector3(0.038 + t * 0.018, 0.03 + t * 0.012, 0.025), color.lightened(t * 0.12), 2.3, 2.3)
		chamber.position = Vector3(cos(angle) * radius, sin(angle) * radius + 0.16, 0.0)
		root.add_child(chamber)
	_add_catalog_grip(root)
	return root


static func _build_watering_can_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var metal := Color(0.34, 0.68, 0.72)
	var body := SuperEgg.build_part(Vector3(0.16, 0.13, 0.12), metal, 2.8, SuperEgg.EPSILON_FLAT)
	body.position.y = 0.13
	root.add_child(body)
	var spout := SuperEgg.build_part(Vector3(0.045, 0.19, 0.045), metal.lightened(0.08), 2.2, 2.2)
	spout.position = Vector3(0.23, 0.18, 0.0)
	spout.rotation.z = deg_to_rad(-62.0)
	root.add_child(spout)
	for side: float in [-1.0, 1.0]:
		var handle := SuperEgg.build_part(Vector3(0.025, 0.13, 0.025), metal.darkened(0.12), 2.0, 2.0)
		handle.position = Vector3(side * 0.12, 0.29, 0.0)
		handle.rotation.z = side * deg_to_rad(35.0)
		root.add_child(handle)
	_add_catalog_grip(root)
	return root


## The Seed of Life retains the established long, tightly coiled organic
## silhouette. Built from a chain of small SuperEgg
## segments walking a shrinking helix (same "shrink each step" spirit as
## NatureProps.build_slab_tower()'s own tapering tiers), each one oriented
## along the helix's own tangent direction (derivative of the parametric
## curve) rather than left at a fixed rotation, so the segments read as one
## continuous curled pod instead of a stack of disconnected pills. Planting
## it. The magical clearing owns its planting and growth rules.
const BEAN_SEGMENT_COUNT := 18
const BEAN_SEGMENT_LENGTH := 0.032
const BEAN_SEGMENT_RADIUS := 0.016
const BEAN_CURL_TURNS := 2.4
const BEAN_CURL_RADIUS_START := 0.1
const BEAN_CURL_RADIUS_END := 0.035
const BEAN_CURL_RISE_TOTAL := 0.06


static func _build_bean_of_life_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var material := StandardMaterial3D.new()
	material.albedo_color = BEAN_OF_LIFE_COLOR
	material.roughness = 0.5
	for i in BEAN_SEGMENT_COUNT:
		var t := float(i) / float(BEAN_SEGMENT_COUNT - 1)
		var angle := t * TAU * BEAN_CURL_TURNS
		var radius := lerpf(BEAN_CURL_RADIUS_START, BEAN_CURL_RADIUS_END, t)
		var pos := Vector3(cos(angle) * radius, t * BEAN_CURL_RISE_TOTAL, sin(angle) * radius)
		var d_radius := BEAN_CURL_RADIUS_END - BEAN_CURL_RADIUS_START
		var d_angle := TAU * BEAN_CURL_TURNS
		var tangent := Vector3(
			d_radius * cos(angle) - radius * sin(angle) * d_angle,
			BEAN_CURL_RISE_TOTAL,
			d_radius * sin(angle) + radius * cos(angle) * d_angle
		).normalized()
		var x_axis := tangent.cross(Vector3.UP)
		if x_axis.length() < 0.001:
			x_axis = Vector3.RIGHT
		x_axis = x_axis.normalized()
		var z_axis := x_axis.cross(tangent).normalized()
		var segment := MeshInstance3D.new()
		segment.mesh = SuperEgg.build_mesh(
			Vector3(BEAN_SEGMENT_RADIUS, BEAN_SEGMENT_LENGTH * 0.5, BEAN_SEGMENT_RADIUS),
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		segment.set_surface_override_material(0, material)
		segment.basis = Basis(x_axis, tangent, z_axis)
		segment.position = pos
		root.add_child(segment)
	_add_catalog_grip(root)
	return root


static func _build_paper_lantern_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var glow_color := Color(0.95, 0.72, 0.32)
	var material := StandardMaterial3D.new()
	material.albedo_color = glow_color
	material.emission_enabled = true
	material.emission = glow_color
	material.emission_energy_multiplier = 1.2
	var body := SuperEgg.build_part(Vector3(0.08, 0.11, 0.08), glow_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	body.set_surface_override_material(0, material)
	body.position.y = 0.11
	root.add_child(body)
	var trim_color := Color(0.35, 0.22, 0.13)
	for y in [0.005, 0.215]:
		var cap := SuperEgg.build_part(Vector3(0.035, 0.02, 0.035), trim_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		cap.position = Vector3(0, y, 0)
		root.add_child(cap)
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = Vector3(0, 0.11, 0)
	light.light_color = glow_color
	light.omni_range = 3.5
	light.shadow_enabled = false
	root.add_child(light)
	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3(0, 0.24, 0)
	root.add_child(grip)
	return root


static func _build_steamed_bun_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var bun_color := Color(0.94, 0.9, 0.82)
	var bun := SuperEgg.build_part(Vector3(0.075, 0.05, 0.075), bun_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	bun.position.y = 0.05
	root.add_child(bun)
	var pleat_color := Color(0.8, 0.72, 0.58)
	var pleat := SuperEgg.build_part(Vector3(0.014, 0.014, 0.014), pleat_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	pleat.position.y = 0.1
	root.add_child(pleat)
	_add_catalog_grip(root)
	return root


static func build_meat_cleaver_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale
	var handle := SuperEgg.build_part(
		Vector3(0.035, 0.19, 0.04), Color(0.25, 0.105, 0.045),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT
	)
	handle.position.y = 0.18
	root.add_child(handle)
	var tang := SuperEgg.build_part(
		Vector3(0.055, 0.035, 0.022), Color(0.18, 0.15, 0.12),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	tang.position.y = 0.37
	root.add_child(tang)
	var blade_material := StandardMaterial3D.new()
	blade_material.albedo_color = Color(0.68, 0.7, 0.72)
	blade_material.metallic = 0.78
	blade_material.roughness = 0.28
	var blade := MeshInstance3D.new()
	blade.mesh = SuperEgg.build_mesh(
		Vector3(0.17, 0.22, 0.018), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	blade.position = Vector3(0.105, 0.54, 0.0)
	blade.rotation.z = deg_to_rad(-7.0)
	blade.set_surface_override_material(0, blade_material)
	root.add_child(blade)
	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3(0.0, 0.16, -0.04)
	root.add_child(grip)
	# Like the sword, the model's blade is authored along local +Y. The
	# procedural palm already supplies its inward yaw, so local Z is the pitch
	# axis that carries the blade forward rather than sideways through the arm.
	root.set_meta("held_rotation", Vector3(0.0, 0.0, PI * 0.5))
	return root


## One grip contract for every held weapon, regardless of whether the owner
## is the player or an NPC. Builders author a GripPoint on the physical hilt
## and optional held_rotation; this aligns that exact point to the hand after
## rotation and scale have been applied.
static func fit_visual_to_hand(visual: Node3D, local_offset: Vector3 = Vector3.ZERO) -> void:
	if visual == null:
		return
	if visual.has_meta("held_rotation"):
		visual.rotation = visual.get_meta("held_rotation") as Vector3
	var grip: Node3D = visual.get_node_or_null("GripPoint") as Node3D
	if grip == null:
		visual.position = local_offset
		return
	var scaled_grip: Vector3 = grip.position*visual.scale
	visual.position = -(visual.quaternion*scaled_grip)+local_offset


## Sun Wu Kong's legendary staff -- "a large staff, red in the middle with
## gold ends on either side," per direct instruction and reference image
## (a real Ruyi Jingu Bang replica: mostly red shaft, gold-banded grip
## sections at both tips). JINGU_BANG_LENGTH is dramatically larger than
## every other item in this catalog (all under half a meter) -- deliberate,
## per direct instruction that it read as a large staff rather than an
## ordinary handheld curio, even after player.gd's own HELD_ITEM_SCALE
## (0.6) shrinks it down for holding. Also used directly (not through
## get_items_for_shop()) by chinese_village.gd's own Fruit-based ground
## pickup, at item_scale 1.0 -- see that file's own _build_jingu_bang_
## pickup().
const JINGU_BANG_LENGTH := 2.2
const JINGU_BANG_RADIUS := 0.035
const JINGU_BANG_END_FRACTION := 0.16
const JINGU_BANG_BAND_COLOR := Color(0.45, 0.32, 0.08)


static func build_jingu_bang_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var length := JINGU_BANG_LENGTH * item_scale
	var radius := JINGU_BANG_RADIUS * item_scale
	var end_length := length * JINGU_BANG_END_FRACTION
	var mid_length := length - end_length * 2.0

	var red_material := StandardMaterial3D.new()
	red_material.albedo_color = JINGU_BANG_RED
	red_material.metallic = 0.1
	red_material.roughness = 0.5
	var mid := MeshInstance3D.new()
	mid.mesh = SuperEgg.build_mesh(Vector3(radius, mid_length * 0.5, radius), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	mid.set_surface_override_material(0, red_material)
	mid.rotation.z = deg_to_rad(90.0)
	root.add_child(mid)

	var gold_material := StandardMaterial3D.new()
	gold_material.albedo_color = JINGU_BANG_GOLD
	gold_material.metallic = 0.75
	gold_material.roughness = 0.3
	var end_radius := radius * 1.08
	for x in [-(mid_length * 0.5 + end_length * 0.5), mid_length * 0.5 + end_length * 0.5]:
		var cap := MeshInstance3D.new()
		cap.mesh = SuperEgg.build_mesh(Vector3(end_radius, end_length * 0.5, end_radius), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		cap.set_surface_override_material(0, gold_material)
		cap.rotation.z = deg_to_rad(90.0)
		cap.position = Vector3(x, 0, 0)
		root.add_child(cap)

	var band_material := StandardMaterial3D.new()
	band_material.albedo_color = JINGU_BANG_BAND_COLOR
	band_material.metallic = 0.6
	band_material.roughness = 0.35
	for x in [-mid_length * 0.5, mid_length * 0.5]:
		var band := MeshInstance3D.new()
		band.mesh = SuperEgg.build_mesh(
			Vector3(radius * 1.15, radius * 0.35, radius * 1.15), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		band.set_surface_override_material(0, band_material)
		band.rotation.z = deg_to_rad(90.0)
		band.position = Vector3(x, 0, 0)
		root.add_child(band)

	# Gripped at the exact center, like a real quarterstaff, rather than
	# GripPoint's usual "near one end" placement on smaller items.
	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3(0.0, 0.0, -radius)
	root.add_child(grip)
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


static func _build_lava_helm_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	# No real head to measure for a standalone shop/inventory icon -- the same
	# generic-head fallback blorb_suit.gd's own _measure_head_contents() uses
	# when it can't find real geometry either.
	var head_size := ProceduralFigure.HEAD_SIZE * item_scale
	var contents := AABB(Vector3(-head_size.x, 0.0, -head_size.z), head_size * 2.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.025, 0.022, 0.02)
	material.metallic = 0.72
	material.roughness = 0.16
	var shell := MeshInstance3D.new()
	shell.mesh = BlorbBodyShape.build_mesh_from_rings(BlorbSuit._build_lava_helm_rings(contents))
	shell.material_override = material
	root.add_child(shell)
	return root


## Never actually sold or dropped loose -- Blorbaka carries this item bound
## into her core from the moment she exists (see false_hero_nme.gd). This
## exists only so anything that enumerates ShopCatalog's own core-item
## entries (an inventory/portrait icon, an armor-bonus lookup) has a real
## visual and description rather than an empty catalog gap.
static func _build_bird_helm_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var epsilon := BirdHelm.DOME_EPSILON
	var semi_axes := ProceduralFigure.HEAD_SIZE * item_scale * 1.4
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.62, 0.58, 0.42)
	material.roughness = 0.62
	var shell := MeshInstance3D.new()
	shell.mesh = BlorbBodyShape.build_mesh_from_rings(BirdHelm.build_dome_rings(semi_axes, epsilon))
	shell.material_override = material
	root.add_child(shell)
	# No real head to measure for a standalone shop/inventory icon, so the
	# beak simply attaches partway down the front surface rather than at a
	# real-head-relative "nose height" the way the living helm computes it.
	var beak_surface: Dictionary = BirdHelm.front_surface(0.35 * PI * 0.5, semi_axes, epsilon)
	var beak_base := Vector3(0.0, beak_surface["y"] as float, beak_surface["radius"] as float)
	var beak := MeshInstance3D.new()
	beak.mesh = BlorbBodyShape.build_mesh_from_rings(BirdHelm.build_beak_rings(beak_base, semi_axes.z))
	beak.material_override = material
	shell.add_child(beak)
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
