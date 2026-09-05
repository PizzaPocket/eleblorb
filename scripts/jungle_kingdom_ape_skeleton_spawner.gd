extends Node3D
class_name JungleKingdomApeSkeletonSpawner

## Proximity-triggered ape-skeleton encounters for the Primate Kingdom --
## the exact same real-time cooldown/chance/exclusion pattern skeleton_
## spawner.gd already uses for the outskirts' human skeletons (see that
## file's own class doc comment), just pointed at skeleton_ape_nme.gd and
## excluding the village instead of the town/city.
##
## Per direct instruction, ape-skeletons "cannot appear in and near the
## primate village": VILLAGE_EXCLUSION_RADIUS (55.0) comfortably clears
## jungle_kingdom_village.gd's own GROUND_ROAM_RADIUS (32.0, the village's
## own roaming primates' own footprint around the village's world-origin
## center -- see that file's own const), so an encounter can't rise right at
## the edge of where a villager might be standing.
##
## A separate "ape_skeletons" group (see skeleton_ape_nme.gd's own _ready())
## backs this spawner's own population cap, rather than the shared
## "skeletons" group skeleton_spawner.gd counts -- the two scenes are never
## loaded simultaneously anyway (portal travel frees the whole previous
## scene), but counting only this scene's own spawns keeps the cap correct
## in principle, not just in practice.

const SKELETON_APE_SCENE := "res://scenes/skeleton_ape_nme.tscn"

const CHECK_INTERVAL_MS := 4000
const SPAWN_CHANCE := 0.3
const MAX_CONCURRENT_APE_SKELETONS := 3
const SPAWN_DISTANCE_MIN := 14.0
const SPAWN_DISTANCE_MAX := 24.0
## World-origin-centered, matching jungle_kingdom_village.gd's own untransformed
## placement (see that file's own class doc comment -- JungleVillage carries
## no position offset of its own, so its coordinates are already world-space).
const VILLAGE_CENTER := Vector2.ZERO
const VILLAGE_EXCLUSION_RADIUS := 55.0

@onready var terrain: Node = get_node("../Terrain")

var _rng := RandomNumberGenerator.new()
var _next_check_ms: int = 0


func _ready() -> void:
	_rng.randomize()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec()
	if now < _next_check_ms:
		return
	_next_check_ms = now + CHECK_INTERVAL_MS

	if get_tree().get_nodes_in_group("ape_skeletons").size() >= MAX_CONCURRENT_APE_SKELETONS:
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
	_spawn_ape_skeleton(spawn_pos)


## True inside/near the village -- everywhere an ape-skeleton should never
## rise, per direct instruction. Only the player's own position is checked
## (not the candidate spawn point too), same reasoning skeleton_spawner.gd's
## own _is_excluded() gives: SPAWN_DISTANCE_MAX is short enough that "the
## player is clear of the village" already implies the ring around them is
## too.
func _is_excluded(pos: Vector2) -> bool:
	return pos.distance_to(VILLAGE_CENTER) < VILLAGE_EXCLUSION_RADIUS


func _random_pos_around(center: Vector2) -> Vector2:
	for _attempt in 8:
		var angle := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
		var pos := center + Vector2(cos(angle), sin(angle)) * dist
		if not _is_excluded(pos):
			return pos
	return Vector2.INF


func _spawn_ape_skeleton(pos: Vector2) -> void:
	var packed: PackedScene = load(SKELETON_APE_SCENE)
	if packed == null:
		push_warning("Missing skeleton ape scene: " + SKELETON_APE_SCENE)
		return
	var inst: StaticBody3D = packed.instantiate()
	inst.set_terrain_reference(terrain)
	inst.position = Vector3(pos.x, terrain.get_mesh_height(pos.x, pos.y), pos.y)
	add_child(inst)
