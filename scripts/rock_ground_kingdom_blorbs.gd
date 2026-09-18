extends Node3D

## Wild Rock and Ground blorbs scattered through the Rock and Ground
## Kingdom -- mirrors fire_kingdom_blorbs.gd's own pattern exactly (each
## spawned blorb is parented to the kingdom root, a sibling of Terrain/
## Player, since blorb.gd's own _ready() resolves those via a fixed
## get_node("../Terrain")/("../Player") sibling lookup; the whole spawn is
## deferred since that add_child() would otherwise crash "Parent node is
## busy setting up children" if called straight from _ready()). Per direct
## instruction: "lots of naturally spawning rock blorbs and ground blorbs."

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const ROCK_COUNT := 10
const GROUND_COUNT := 10
const SPAWN_RADIUS := 500.0

var _rng := RandomNumberGenerator.new()
var _terrain: Node


func _ready() -> void:
	_rng.seed = 20260907
	_terrain = get_node_or_null("../Terrain")
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	_spawn_all.call_deferred()


func _spawn_all() -> void:
	for i in ROCK_COUNT:
		_place("rock" if i % 2 == 0 else "", true)
	for i in GROUND_COUNT:
		_place("ground" if i % 2 == 0 else "", false)


func _place(element: String, rock_side: bool) -> void:
	var pos := _pick_position(rock_side)
	var inst = BLORB_SCENE.instantiate()
	inst.in_party = false
	inst.initial_element = element
	inst.position = Vector3(pos.x, _terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(inst)


func _pick_position(rock_side: bool) -> Vector2:
	for attempt in 30:
		var point := Vector2(
			_rng.randf_range(-SPAWN_RADIUS,-35.0) if rock_side else _rng.randf_range(35.0,SPAWN_RADIUS),
			_rng.randf_range(-SPAWN_RADIUS,SPAWN_RADIUS)
		)
		if _terrain.has_method("is_safe_zone") and _terrain.is_safe_zone(point): continue
		return point
	return Vector2(-90.0,90.0) if rock_side else Vector2(90.0,90.0)
