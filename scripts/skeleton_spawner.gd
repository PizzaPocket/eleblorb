extends Node3D
class_name SkeletonSpawner

## Proximity-triggered skeleton encounters (see skeleton_nme.gd, docs/
## world_bible.md's Aggros section) -- a real-time cooldown checks the
## player's current position and, if it's valid open wasteland, rolls a
## chance to rise a new skeleton nearby. Not an ambient population like
## WildernessScatter's one-shot field of props/NPCs/wild blorbs (this file
## keeps checking for the life of the run) and not night-only -- per the
## scoping decision, skeletons are just "proximity-triggered," full stop.
##
## Sibling of WildernessScatter under Main (see scenes/main.tscn) and
## structured the same way: @onready terrain/town_center off the shared
## Terrain node, an _is_excluded()-style guard reusing the same town-
## exclusion-radius idea plus a city-center exclusion and terrain.
## is_lake_area() so skeletons never rise in town, the city, the starting
## clearing, or the lake.
## Spawned instances are parented to self (not get_parent()/Main) and given
## their Terrain reference via set_terrain_reference(), the same injected-
## setter pattern WildernessScatter uses for NPCs -- skeleton_nme.gd's own
## _ready() fallback (get_node("../../Terrain")) matches that one-level-
## deeper parenting.

const SKELETON_SCENE := "res://scenes/skeleton.tscn"

## How often (real seconds, not per-frame) a spawn roll is attempted --
## Time.get_ticks_msec()-based like hud.gd's own REPLENISH_COOLDOWN_MS, not
## a per-frame check, so this can't roll 60 times a second while the player
## stands still in valid territory.
const CHECK_INTERVAL_MS := 4000
## Chance a valid check actually spawns a skeleton -- kept well under 1.0 so
## encounters feel occasional rather than a skeleton appearing on every tick
## the player happens to be out in the open.
const SPAWN_CHANCE := 0.3
const MAX_CONCURRENT_SKELETONS := 3
## Where around the player a newly-risen skeleton appears -- far enough to
## rise unnoticed rather than popping up underfoot, close enough to still
## read as reacting to the player's presence rather than a random distant
## spawn.
const SPAWN_DISTANCE_MIN := 14.0
const SPAWN_DISTANCE_MAX := 24.0
## Mirrors WildernessScatter's own town_exclusion_radius default.
const TOWN_EXCLUSION_RADIUS := 85.0
## Duplicated from terrain_generator.gd's own CITY_CENTER/CITY_FLAT_RADIUS
## (neither TerrainGenerator nor CityGenerator declares a class_name, so
## there's no static way to reference them from here) -- city_generator.gd
## already duplicates CITY_CENTER the same way rather than reaching across
## files for it, so this matches existing precedent instead of inventing a
## new cross-referencing pattern. CITY_EXCLUSION_RADIUS itself is
## CITY_FLAT_RADIUS (78.0) plus margin so skeletons don't rise just outside
## the city's own flattened foundation edge.
const CITY_CENTER := Vector2(-540, 0)
const CITY_EXCLUSION_RADIUS := 110.0
## The player's arrival clearing is a settlement-like safe space even though
## it has no buildings. Check both the player and candidate positions so an
## encounter cannot rise just inside the boundary while the player stands
## immediately outside it.
const START_CENTER := Vector2.ZERO
const START_EXCLUSION_RADIUS := 55.0

@onready var terrain: Node = get_node("../Terrain")
@onready var town_center: Vector2 = terrain.town_center

var _rng := RandomNumberGenerator.new()
var _next_check_ms: int = 0


func _ready() -> void:
	_rng.randomize()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now < _next_check_ms:
		return
	_next_check_ms = now + CHECK_INTERVAL_MS

	if get_tree().get_nodes_in_group("skeletons").size() >= MAX_CONCURRENT_SKELETONS:
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var player_here := Vector2(player.global_position.x, player.global_position.z)
	if _is_excluded(player_here):
		return
	if _rng.randf() > SPAWN_CHANCE:
		return

	var spawn_pos := _random_pos_around(player_here)
	if spawn_pos == Vector2.INF:
		return
	_spawn_skeleton(spawn_pos)


## True for the starting clearing, town, city, or lake -- everywhere a
## skeleton should never rise, per docs/world_bible.md's Aggros section.
## Both the player's position and candidate position pass through this same
## function, so encounters cannot straddle a protected boundary.
func _is_excluded(pos: Vector2) -> bool:
	if terrain.is_lake_area(pos):
		return true
	if pos.distance_to(town_center) < TOWN_EXCLUSION_RADIUS:
		return true
	if pos.distance_to(CITY_CENTER) < CITY_EXCLUSION_RADIUS:
		return true
	if pos.distance_to(START_CENTER) < START_EXCLUSION_RADIUS:
		return true
	return false


func _random_pos_around(center: Vector2) -> Vector2:
	for _attempt in 8:
		var angle := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
		var pos := center + Vector2(cos(angle), sin(angle)) * dist
		if not _is_excluded(pos):
			return pos
	return Vector2.INF


func _spawn_skeleton(pos: Vector2) -> void:
	var packed: PackedScene = load(SKELETON_SCENE)
	if packed == null:
		push_warning("Missing skeleton scene: " + SKELETON_SCENE)
		return
	var inst: StaticBody3D = packed.instantiate()
	inst.set_terrain_reference(terrain)
	inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	add_child(inst)
