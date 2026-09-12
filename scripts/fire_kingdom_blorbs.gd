extends Node3D

## Wild fire blorbs scattered through the Fire Kingdom -- mirrors
## jungle_kingdom_blorbs.gd's own pattern exactly (each spawned blorb is
## parented to the kingdom root, a sibling of Terrain/Player, since blorb.gd's
## own _ready() resolves those via a fixed get_node("../Terrain")/("../Player")
## sibling lookup; the whole spawn is deferred since that add_child() would
## otherwise crash "Parent node is busy setting up children" if called
## straight from _ready(), while the kingdom root is still mid-setup adding
## its own children -- see jungle_kingdom_village.gd's own _ready() comment
## for the full reasoning).

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const FIRE_COUNT := 8
const SPAWN_RADIUS := 220.0

var _rng := RandomNumberGenerator.new()
var _terrain: Node


func _ready() -> void:
	_rng.seed = 20260905
	_terrain = get_node_or_null("../Terrain")
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	_spawn_all.call_deferred()


func _spawn_all() -> void:
	for i in FIRE_COUNT:
		_place()


func _place() -> void:
	var pos: Variant = _pick_position()
	if pos == null:
		return
	var picked: Vector2 = pos
	var inst = BLORB_SCENE.instantiate()
	inst.in_party = false
	inst.initial_element = "fire"
	inst.position = Vector3(picked.x, _terrain.get_mesh_height(picked.x, picked.y), picked.y)
	get_parent().add_child(inst)


func _pick_position() -> Variant:
	for attempt in 8:
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * SPAWN_RADIUS
		var a := _rng.randf_range(0.0, TAU)
		var pos := Vector2(cos(a) * r, sin(a) * r)
		if pos.length() < 10.0 or _terrain.is_lava_area(pos) or _terrain.is_safe_zone(pos):
			continue
		return pos
	return null
