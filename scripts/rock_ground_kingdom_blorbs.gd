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
const SPAWN_RADIUS := 190.0

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
		_place("rock")
	for i in GROUND_COUNT:
		_place("ground")


func _place(element: String) -> void:
	var pos := _pick_position()
	var inst = BLORB_SCENE.instantiate()
	inst.in_party = false
	inst.initial_element = element
	inst.position = Vector3(pos.x, _terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(inst)


func _pick_position() -> Vector2:
	var r := sqrt(_rng.randf_range(0.0, 1.0)) * SPAWN_RADIUS
	var a := _rng.randf_range(0.0, TAU)
	return Vector2(cos(a) * r, sin(a) * r)
