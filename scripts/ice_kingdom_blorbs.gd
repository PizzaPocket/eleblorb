extends Node3D

## Wild Ice and Snow blorbs scattered through the Ice Kingdom -- mirrors
## fire_kingdom_blorbs.gd's own pattern exactly (each spawned blorb is
## parented to the kingdom root, a sibling of Terrain/Player, since blorb.gd's
## own _ready() resolves those via a fixed get_node("../Terrain")/("../Player")
## sibling lookup; the whole spawn is deferred since that add_child() would
## otherwise crash "Parent node is busy setting up children" if called
## straight from _ready()). Ice blorbs favor the snowy-forest zone near the
## arrival point; Snow blorbs range across both zones -- see
## ice_kingdom_terrain.gd's own is_snow_zone().

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const ICE_COUNT := 6
const SNOW_COUNT := 8
const SPAWN_RADIUS := 520.0

var _rng := RandomNumberGenerator.new()
var _terrain: Node


func _ready() -> void:
	_rng.seed = 20260908
	_terrain = get_node_or_null("../Terrain")
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	_spawn_all.call_deferred()


func _spawn_all() -> void:
	for i in ICE_COUNT:
		_place("ice" if i % 2 == 0 else "", true)
	for i in SNOW_COUNT:
		_place("snow" if i % 2 == 0 else "", false)


## Ice blorbs inhabit the lake/glacier half (positive X); Snow blorbs inhabit
## the village/mountain half (negative X). Normal blorbs remain interspersed
## through both populations by the caller's alternating element string.
func _place(element: String, ice_side: bool) -> void:
	var pos := _pick_position(ice_side)
	var inst = BLORB_SCENE.instantiate()
	inst.in_party = false
	inst.initial_element = element
	inst.position = Vector3(pos.x, _terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(inst)


func _pick_position(ice_side: bool) -> Vector2:
	for attempt in 30:
		var pos := Vector2(
			_rng.randf_range(35.0,520.0) if ice_side else _rng.randf_range(-730.0,-35.0),
			_rng.randf_range(-420.0,420.0)
		)
		if pos.length() < 10.0 or _terrain.is_lake_area(pos) or _terrain.is_safe_zone(pos):
			continue
		return pos
	return Vector2(420.0,0.0) if ice_side else Vector2(-420.0,0.0)
