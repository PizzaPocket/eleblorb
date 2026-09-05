extends Node3D

## Content for the city kingdom (see kingdom_bootstrap.gd): a repeating
## avenue/cross-street grid spanning out to the mountain ring, replacing the
## original small hand-authored 112x112 downtown block -- per direct
## instruction that kingdoms should read as "spanning out to the mountains
## ringing it" rather than a small pocket. Each interior block gets one
## TownProps.build_building() house (the same simple builder
## jungle_kingdom_village.gd uses for its treehouses), not city_generator.gd's
## paired-skyscraper system, since that system is purpose-built around its
## own fixed 4x3 BLOCK_X/BLOCK_Z grid and skybridge wiring rather than a
## general repeating grid.
## Terrain here is flat_ground.gd (no undulation), so every slab sits at a
## fixed ground_y rather than querying per-point height.

const CENTER := Vector2.ZERO
const GROUND_Y := 0.0

const BLOCK_SPACING := 80.0
const RADIUS := 800.0
const LINE_COUNT := 10  # avenues/cross-streets run at multiples of BLOCK_SPACING from -LINE_COUNT to LINE_COUNT

const ROAD_WIDTH := 8.0
const SIDEWALK_WIDTH := 2.6
const SIDEWALK_OFFSET := 5.4
const ROAD_LENGTH := RADIUS * 2.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20260823
	_build_roads()
	_build_blocks()
	_build_streetlights()


func _build_roads() -> void:
	for i in range(-LINE_COUNT, LINE_COUNT + 1):
		var pos := float(i) * BLOCK_SPACING
		_add_road(Vector2(pos, 0), Vector2(ROAD_WIDTH, ROAD_LENGTH))
		_add_road(Vector2(0, pos), Vector2(ROAD_LENGTH, ROAD_WIDTH))
		for side in [-1.0, 1.0]:
			_add_sidewalk(Vector2(pos + side * SIDEWALK_OFFSET, 0), Vector2(SIDEWALK_WIDTH, ROAD_LENGTH))
			_add_sidewalk(Vector2(0, pos + side * SIDEWALK_OFFSET), Vector2(ROAD_LENGTH, SIDEWALK_WIDTH))


func _build_blocks() -> void:
	var building_index := 0
	for ix in range(-LINE_COUNT, LINE_COUNT):
		for iz in range(-LINE_COUNT, LINE_COUNT):
			var center := Vector2((float(ix) + 0.5) * BLOCK_SPACING, (float(iz) + 0.5) * BLOCK_SPACING)
			_add_building(center, building_index)
			building_index += 1


func _add_building(local_pos: Vector2, building_index: int) -> void:
	var world := CENTER + local_pos
	var w := _rng.randi_range(3, 7)
	var d := _rng.randi_range(3, 6)
	var floors := _rng.randi_range(1, 4)
	var roof_color: Color = TownProps.ROOF_COLORS[building_index % TownProps.ROOF_COLORS.size()]
	var building := TownProps.build_building(w, d, floors, roof_color)
	building.position = Vector3(world.x, GROUND_Y, world.y)
	building.rotation.y = _rng.randi_range(0, 3) * PI * 0.5
	add_child(building)


func _build_streetlights() -> void:
	for i in range(-LINE_COUNT, LINE_COUNT + 1):
		for j in range(-LINE_COUNT, LINE_COUNT + 1):
			_add_streetlight(Vector2(float(i) * BLOCK_SPACING - SIDEWALK_OFFSET, float(j) * BLOCK_SPACING - SIDEWALK_OFFSET), Vector2(1, 1))


func _add_road(local_pos: Vector2, size: Vector2) -> void:
	var world := CENTER + local_pos
	var slab := TownProps.build_city_pavement(size, Color(0.16, 0.18, 0.2), 0.08)
	slab.position = Vector3(world.x, GROUND_Y + 0.12, world.y)
	add_child(slab)


func _add_sidewalk(local_pos: Vector2, size: Vector2) -> void:
	var world := CENTER + local_pos
	var slab := TownProps.build_city_pavement(size, Color(0.44, 0.42, 0.38), 0.14)
	slab.position = Vector3(world.x, GROUND_Y + 0.08, world.y)
	add_child(slab)


func _add_streetlight(local_pos: Vector2, overhang_direction: Vector2) -> void:
	var world := CENTER + local_pos
	var lamp := TownProps.build_city_streetlight()
	lamp.position = Vector3(world.x, GROUND_Y, world.y)
	lamp.rotation.y = atan2(-overhang_direction.x, -overhang_direction.y)
	add_child(lamp)
