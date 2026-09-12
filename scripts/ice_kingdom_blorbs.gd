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
const SPAWN_RADIUS := 230.0

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
		_place("ice", true)
	for i in SNOW_COUNT:
		_place("snow", false)


## `favor_snow_zone` restricts the pick to the terrain's own snowy-forest
## radius (see ice_kingdom_terrain.gd's is_snow_zone()) -- Ice blorbs stay
## close to the arrival clearing, Snow blorbs range anywhere.
func _place(element: String, favor_snow_zone: bool) -> void:
	var pos := _pick_position(favor_snow_zone)
	var inst = BLORB_SCENE.instantiate()
	inst.in_party = false
	inst.initial_element = element
	inst.position = Vector3(pos.x, _terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(inst)


func _pick_position(favor_snow_zone: bool) -> Vector2:
	var radius: float = float(_terrain.get_snow_radius()) if favor_snow_zone else SPAWN_RADIUS
	for attempt in 8:
		var r: float = sqrt(_rng.randf_range(0.0, 1.0)) * radius
		var a := _rng.randf_range(0.0, TAU)
		var pos := Vector2(cos(a) * r, sin(a) * r)
		if pos.length() < 10.0 or _terrain.is_lake_area(pos) or _terrain.is_safe_zone(pos):
			continue
		return pos
	return Vector2(radius, 0.0)
