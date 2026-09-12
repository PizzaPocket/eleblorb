extends Node3D
class_name ElementalKingdomNMESpawner

## Shared proximity spawner for the Fire and Ice/Snow kingdoms. Encounters
## use the established Demon-Lord skeleton NME rather than introducing a new
## rig, but carry the local element in their color and combat affinity.

const SKELETON_SCENE := preload("res://scenes/skeleton.tscn")
const CHECK_INTERVAL_MS := 4000
const SPAWN_CHANCE := 0.34
const MAX_CONCURRENT := 4
const SPAWN_DISTANCE_MIN := 16.0
const SPAWN_DISTANCE_MAX := 27.0
const RETURN_GATE_SAFE_RADIUS := 34.0
const WORLD_EDGE_MARGIN := 70.0

@export_enum("fire", "ice") var nme_element: String = "ice"
@export var nme_color: Color = Color(0.66, 0.86, 1.0)

@onready var terrain: Node = get_node("../Terrain")
var _rng := RandomNumberGenerator.new()
var _next_check_ms: int = 0


func _ready() -> void:
	_rng.randomize()


func _process(_delta: float) -> void:
	var now: int = Time.get_ticks_msec()
	if now < _next_check_ms:
		return
	_next_check_ms = now + CHECK_INTERVAL_MS
	if get_tree().get_nodes_in_group("skeletons").size() >= MAX_CONCURRENT:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var player_pos := Vector2(player.global_position.x, player.global_position.z)
	if _is_excluded(player_pos) or _rng.randf() > SPAWN_CHANCE:
		return
	var spawn_pos := _random_position_around(player_pos)
	if spawn_pos != Vector2.INF:
		_spawn_nme(spawn_pos)


func _is_excluded(pos: Vector2) -> bool:
	if pos.length() < RETURN_GATE_SAFE_RADIUS:
		return true
	if terrain.has_method("is_safe_zone") and terrain.is_safe_zone(pos):
		return true
	if terrain.has_method("is_nme_hazard") and terrain.is_nme_hazard(pos):
		return true
	# Both elemental heightfields currently use a 900-unit half-size. Keep the
	# encounter ring comfortably away from its clamped outermost samples.
	if absf(pos.x) > 900.0 - WORLD_EDGE_MARGIN or absf(pos.y) > 900.0 - WORLD_EDGE_MARGIN:
		return true
	return false


func _random_position_around(center: Vector2) -> Vector2:
	for _attempt in 10:
		var angle: float = _rng.randf_range(0.0, TAU)
		var distance: float = _rng.randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
		var candidate := center + Vector2(cos(angle), sin(angle)) * distance
		if not _is_excluded(candidate):
			return candidate
	return Vector2.INF


func _spawn_nme(pos: Vector2) -> void:
	var nme := SKELETON_SCENE.instantiate() as StaticBody3D
	nme.set("bone_color", nme_color)
	nme.set("combat_element", nme_element)
	nme.set_terrain_reference(terrain)
	nme.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	add_child(nme)
