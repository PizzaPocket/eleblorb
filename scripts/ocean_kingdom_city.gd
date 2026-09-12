extends Node3D

## The actual submerged Ocean Kingdom: a luminous teal/prism-green castle
## on the deep seabed, populated by peaceful merfolk.

const MERFOLK_SCENE: PackedScene = preload("res://scenes/merfolk.tscn")
const CITY_CENTER := Vector2(0.0, -540.0)
const TEAL := Color(0.04, 0.58, 0.54)
const PRISM_GREEN := Color(0.22, 0.88, 0.58)
const DARK_TEAL := Color(0.025, 0.26, 0.31)
const MERFOLK_TAIL_COLORS: Array[Color] = [
	Color(0.06, 0.46, 0.56), Color(0.08, 0.31, 0.68),
	Color(0.12, 0.58, 0.48), Color(0.68, 0.19, 0.25),
	Color(0.18, 0.42, 0.62), Color(0.55, 0.24, 0.38),
]
const MERFOLK_HAIR_COLORS: Array[Color] = [
	Color(0.035, 0.34, 0.38), Color(0.06, 0.48, 0.52),
	Color(0.055, 0.24, 0.52), Color(0.12, 0.38, 0.68),
	Color(0.62, 0.12, 0.14), Color(0.82, 0.24, 0.18),
	Color(0.46, 0.08, 0.20),
]
const FEMALE_HAIR_STYLES: Array[String] = [
	FigureHair.STYLE_LONG, FigureHair.STYLE_BUN,
	FigureHair.STYLE_PIGTAILS, FigureHair.STYLE_PONYTAIL,
]
const MALE_HAIR_STYLES: Array[String] = [
	FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_AFRO, FigureHair.STYLE_BUZZCUT,
]
const PEARL_LIGHT_COLORS: Array[Color] = [
	Color(0.24, 0.96, 0.82), Color(0.30, 0.76, 1.0), Color(0.66, 0.48, 1.0),
]
const RESIDENT_IDENTITIES: Array[Dictionary] = [
	{"name": "Tidekeeper Nerion", "line": "Every current reaches this hall eventually. I listen before I judge what it carries."},
	{"name": "Marella Shellwise", "line": "I trade in things the sea has finished with, never what it still needs."},
	{"name": "Corren Bluewake", "line": "The lantern pearls brighten when a storm is gathering far above us."},
	{"name": "Nerissa Bloomfin", "line": "My sea flowers only open when the warm current curls around the eastern reef."},
	{"name": "Tavio Reedtail", "line": "Fish Goblins leave crooked trails in the sand. Peaceful swimmers leave almost none."},
	{"name": "Luma Pearlsong", "line": "The village lights are living pearls. Hum softly and sometimes they answer."},
	{"name": "Orin Redfin", "line": "I raced the copper current once. It won, but only by the length of my tail."},
	{"name": "Selkie Seabloom", "line": "A shell worn in the hair remembers both the shore and the deep."},
	{"name": "Pelagos Drift", "line": "The ships overhead sound like distant wooden thunder from down here."},
	{"name": "Thalina Foamcrest", "line": "Do not mistake quiet water for empty water. The smallest lives are listening."},
	{"name": "Caspian Kelpweaver", "line": "I braid young kelp around the homes so the walls sway with the village."},
	{"name": "Maris Coralglow", "line": "At night the reef keeps its own constellations, all pink and green and gold."},
	{"name": "Delmar Deepcurrent", "line": "Beyond the last lamp the floor falls away faster than a frightened stone."},
	{"name": "Ondine Silvergill", "line": "Silver scales are formal here. Brown scales are better for garden work."},
	{"name": "Nilo Tideglass", "line": "Clear water can still bend what you see. Trust the current against your skin."},
	{"name": "Azura Ripplefin", "line": "I saw the Kraken turn in its sleep. The whole reef leaned away."},
	{"name": "Brin Nautilus", "line": "A nautilus builds its home one chamber at a time. A kingdom is much the same."},
	{"name": "Calypso Sunkenstar", "line": "Sunlight reaches us in ribbons. I collect the brightest places to rest."},
	{"name": "Muirin Softcurrent", "line": "Young tails learn balance in the village lanes before trying the open sea."},
	{"name": "Ronan Amberkelp", "line": "If you carry a watering can inland, remember: it is meant for the Seed of Life."},
]

var _terrain: Node


func _ready() -> void:
	_terrain = get_node("../Terrain")
	_build_castle()
	_build_village()
	_spawn_merfolk.call_deferred()


func _build_castle() -> void:
	var floor_y: float = _terrain.get_mesh_height(CITY_CENTER.x, CITY_CENTER.y)
	var castle := StaticBody3D.new()
	castle.name = "SubmergedOceanCastle"
	castle.position = Vector3(CITY_CENTER.x, floor_y, CITY_CENTER.y)
	castle.collision_layer = 1
	castle.collision_mask = 0
	add_child(castle)
	# Walkable foundation and an actual hollow audience hall. The old palace
	# was a stack of solid boxes, so its apparent doorway could never lead
	# anywhere.
	_add_block(castle, Vector3(0, 1.0, 0), Vector3(34, 2, 30), DARK_TEAL)
	_add_block(castle, Vector3(-9.2, 6.0, 4.0), Vector3(1.4, 8, 17), TEAL)
	_add_block(castle, Vector3(9.2, 6.0, 4.0), Vector3(1.4, 8, 17), TEAL)
	_add_block(castle, Vector3(0.0, 6.0, 12.0), Vector3(19.8, 8, 1.4), TEAL)
	_add_block(castle, Vector3(-6.2, 6.0, -4.0), Vector3(6.0, 8, 1.4), TEAL)
	_add_block(castle, Vector3(6.2, 6.0, -4.0), Vector3(6.0, 8, 1.4), TEAL)
	_add_block(castle, Vector3(0, 10.3, 4), Vector3(19.8, 1.2, 17), PRISM_GREEN)
	_add_block(castle, Vector3(0, 12.2, 5), Vector3(13, 2.6, 12), PRISM_GREEN)
	for corner in [Vector3(-13, 7, -9), Vector3(13, 7, -9), Vector3(-13, 7, 13), Vector3(13, 7, 13)]:
		_add_block(castle, corner, Vector3(6, 12, 6), TEAL.lightened(0.08))
		var crown := SuperEgg.build_part(Vector3(4.2, 3.8, 4.2), PRISM_GREEN, 1.3, SuperEgg.EPSILON_FLAT)
		crown.position = corner + Vector3.UP * 8.7
		castle.add_child(crown)
	# A wide open approach reads as the palace entrance rather than a sealed
	# monolith, with luminous shell-like columns marking the threshold.
	for side: float in [-1.0, 1.0]:
		var column := SuperEgg.build_part(Vector3(1.1, 5.5, 1.1), PRISM_GREEN, 2.2, 2.2)
		column.position = Vector3(side * 6.0, 6.5, -12.8)
		castle.add_child(column)
	# Interior throne and aisle make crossing the doorway visibly worthwhile.
	_add_block(castle, Vector3(0.0, 2.65, 9.0), Vector3(4.5, 1.3, 3.0), PRISM_GREEN.darkened(0.16))
	_add_block(castle, Vector3(0.0, 4.35, 10.0), Vector3(3.2, 2.2, 1.0), PRISM_GREEN)
	for aisle_index in 7:
		var aisle := SuperEgg.build_part(Vector3(1.15, 0.055, 0.72), Color(0.26, 0.86, 0.72), 2.2, 2.2)
		aisle.position = Vector3(0.0, 2.08, -1.7 + float(aisle_index) * 1.55)
		castle.add_child(aisle)
	var light := OmniLight3D.new()
	light.light_color = Color(0.22, 0.94, 0.76)
	light.light_energy = 3.0
	light.omni_range = 58.0
	light.position = Vector3(0.0, 10.0, 2.0)
	castle.add_child(light)
	var palace_lamps: Array[Dictionary] = [
		{"position": Vector3(-6.0, 3.0, -12.9), "color": 0},
		{"position": Vector3(6.0, 3.0, -12.9), "color": 0},
		{"position": Vector3(-13.0, 8.0, 13.0), "color": 1},
		{"position": Vector3(13.0, 8.0, 13.0), "color": 2},
	]
	for lamp_data: Dictionary in palace_lamps:
		var lamp_position: Vector3 = lamp_data["position"]
		var color_index: int = lamp_data["color"]
		_add_pearl_lamp(castle, lamp_position, PEARL_LIGHT_COLORS[color_index], 2.2, 20.0, 0.34)


func _build_village() -> void:
	# Two loose rings of small, enterable dwellings surround the palace,
	# leaving broad swimming lanes between them and the royal approach.
	for index in 16:
		var ring := 0 if index < 8 else 1
		var ring_index := index if ring == 0 else index - 8
		var angle := TAU * float(ring_index) / 8.0 + (0.22 if ring == 1 else 0.0)
		var distance := 49.0 if ring == 0 else 82.0
		var x := CITY_CENTER.x + cos(angle) * distance
		var z := CITY_CENTER.y + sin(angle) * distance
		_build_village_home(index, Vector2(x, z), PI * 0.5 - angle)
	# Luminous stepping-stone paths and kelp gardens tie the rings together.
	for spoke in 8:
		var angle := TAU * float(spoke) / 8.0
		for step in 5:
			var distance := 25.0 + float(step) * 12.0
			var point := CITY_CENTER + Vector2(cos(angle), sin(angle)) * distance
			var path := SuperEgg.build_part(Vector3(1.5, 0.08, 1.0), Color(0.12, 0.62, 0.56), 2.4, 2.4)
			var path_material := path.get_surface_override_material(0) as StandardMaterial3D
			path_material.emission_enabled = true
			path_material.emission = Color(0.08, 0.50, 0.46)
			path_material.emission_energy_multiplier = 0.48
			path.position = Vector3(point.x, _terrain.get_mesh_height(point.x, point.y) + 0.10, point.y)
			path.rotation.y = -angle
			add_child(path)
	for garden_index in 24:
		var angle := TAU * float(garden_index) / 24.0 + sin(float(garden_index) * 1.7) * 0.12
		var distance := 35.0 + float(garden_index % 4) * 16.0
		var point := CITY_CENTER + Vector2(cos(angle), sin(angle)) * distance
		var kelp := SuperEgg.build_part(Vector3(0.18, 0.9 + float(garden_index % 3) * 0.25, 0.18), Color(0.08, 0.55, 0.35), 2.8, 2.8)
		kelp.position = Vector3(point.x, _terrain.get_mesh_height(point.x, point.y) + 0.9, point.y)
		kelp.rotation.z = sin(float(garden_index) * 2.1) * 0.18
		add_child(kelp)


func _build_village_home(index: int, point: Vector2, facing: float) -> void:
	var floor_y: float = _terrain.get_mesh_height(point.x, point.y)
	var home := StaticBody3D.new()
	home.name = "MerfolkHome%02d" % (index + 1)
	home.position = Vector3(point.x, floor_y, point.y)
	home.rotation.y = facing
	home.collision_layer = 1
	home.collision_mask = 0
	add_child(home)
	var wall_color := TEAL.lightened(0.03 + float(index % 3) * 0.035)
	_add_block(home, Vector3(0, 0.35, 0), Vector3(8.0, 0.7, 7.0), DARK_TEAL)
	_add_block(home, Vector3(-3.55, 3.0, 0), Vector3(0.9, 5.3, 7.0), wall_color)
	_add_block(home, Vector3(3.55, 3.0, 0), Vector3(0.9, 5.3, 7.0), wall_color)
	_add_block(home, Vector3(0, 3.0, 3.05), Vector3(8.0, 5.3, 0.9), wall_color)
	# Split front wall leaves a human-scale doorway into the furnished shell.
	_add_block(home, Vector3(-2.55, 3.0, -3.05), Vector3(2.9, 5.3, 0.9), wall_color)
	_add_block(home, Vector3(2.55, 3.0, -3.05), Vector3(2.9, 5.3, 0.9), wall_color)
	var roof := SuperEgg.build_part(Vector3(4.5, 1.1, 4.0), PRISM_GREEN.darkened(0.08), 1.25, SuperEgg.EPSILON_FLAT)
	roof.position = Vector3(0, 6.25, 0)
	home.add_child(roof)
	_add_pearl_lamp(home, Vector3(0, 3.35, -3.65), PEARL_LIGHT_COLORS[index % PEARL_LIGHT_COLORS.size()], 1.55, 15.0, 0.24)


func _add_pearl_lamp(
	parent: Node3D, position: Vector3, color: Color,
	energy: float, light_range: float, radius: float
) -> void:
	var fixture := Node3D.new()
	fixture.name = "LivingPearlLamp"
	fixture.position = position
	parent.add_child(fixture)
	var shell := SuperEgg.build_part(Vector3(radius * 1.35, radius * 0.36, radius), color.darkened(0.38), 2.5, SuperEgg.EPSILON_FLAT)
	shell.position.y = -radius * 0.28
	fixture.add_child(shell)
	var pearl := SuperEgg.build_part(Vector3.ONE * radius, color, 2.0, 2.0)
	pearl.name = "Pearl"
	var pearl_material := pearl.get_surface_override_material(0) as StandardMaterial3D
	pearl_material.emission_enabled = true
	pearl_material.emission = color
	pearl_material.emission_energy_multiplier = 1.65
	pearl_material.roughness = 0.24
	fixture.add_child(pearl)
	var glow := OmniLight3D.new()
	glow.name = "PearlLight"
	glow.light_color = color
	glow.light_energy = energy
	glow.omni_range = light_range
	glow.shadow_enabled = false
	fixture.add_child(glow)


func _add_block(parent: StaticBody3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var mesh := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	mesh.position = pos
	parent.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	parent.add_child(collision)


func _spawn_merfolk() -> void:
	for index in 20:
		var resident: Merfolk = MERFOLK_SCENE.instantiate()
		var identity: Dictionary = RESIDENT_IDENTITIES[index]
		resident.display_name = identity["name"] as String
		resident.dialogue_text = identity["line"] as String
		resident.is_king = index == 0
		resident.is_vendor = index == 1
		resident.is_female = index % 2 == 1
		resident.wander_radius = 4.5 if index < 2 else 9.0 + float(index % 3) * 2.0
		resident.scale_clothing_color = [Color(0.76, 0.81, 0.83), Color(0.08, 0.24, 0.46), Color(0.42, 0.29, 0.17)][index % 3]
		resident.tail_color = MERFOLK_TAIL_COLORS[index % MERFOLK_TAIL_COLORS.size()]
		resident.sleeve_style = ProceduralFigure.SLEEVE_STYLE_NONE if index % 3 == 0 else ProceduralFigure.SLEEVE_STYLE_SHORT
		resident.has_midriff = resident.is_female and index % 4 == 1
		var hairstyle_index := floori(float(index) / 2.0)
		resident.hair_style = FEMALE_HAIR_STYLES[hairstyle_index % FEMALE_HAIR_STYLES.size()] if resident.is_female else MALE_HAIR_STYLES[hairstyle_index % MALE_HAIR_STYLES.size()]
		if resident.is_female and hairstyle_index % 3 != 2:
			resident.hair_ornament = "shell" if hairstyle_index % 3 == 0 else "sea_flower"
			resident.hair_ornament_color = [Color(0.94, 0.72, 0.48), Color(0.95, 0.42, 0.52), Color(0.58, 0.90, 0.82)][hairstyle_index % 3]
		# Step through the palette at a different interval than tails/clothes,
		# preventing residents from becoming monochrome matching sets.
		resident.hair_color = MERFOLK_HAIR_COLORS[(index * 3 + 1) % MERFOLK_HAIR_COLORS.size()]
		resident.hair_length_variance = 0.04 + float(index % 4) * 0.025 if resident.hair_style == FigureHair.STYLE_LONG else 0.0
		var world_x: float
		var world_z: float
		if index == 0:
			# The Tidekeeper receives visitors in front of the palace rather
			# than spawning inside its solid central structure.
			world_x = CITY_CENTER.x
			world_z = CITY_CENTER.y - 21.0
		elif index == 1:
			world_x = CITY_CENTER.x - 11.0
			world_z = CITY_CENTER.y - 22.0
		else:
			var angle: float = TAU * float(index - 2) / 18.0
			var distance: float = 30.0 + float(index % 4) * 16.0
			world_x = CITY_CENTER.x + cos(angle) * distance
			world_z = CITY_CENTER.y + sin(angle) * distance
		var floor_y: float = _terrain.get_mesh_height(world_x, world_z)
		resident.position = Vector3(world_x, floor_y + 2.1, world_z)
		# Position before entering the tree so Merfolk._ready() captures the
		# authored spot as the center of this resident's personal route.
		add_child(resident)
