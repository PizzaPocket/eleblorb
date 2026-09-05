extends Node3D

## Wild blorbs scattered through the primate kingdom -- "various types...
## including plant type" per direct instruction. Mirrors wilderness_scatter.
## gd's own _place_wild_blorb()/_spawn_jungle_plant_blorbs() pattern: each
## spawned blorb is parented to the kingdom root (a sibling of Terrain/
## Player, not a child of this node), because blorb.gd's own _ready()
## resolves those via a fixed get_node("../Terrain")/("../Player") sibling
## lookup -- see that file's own comment on _place_wild_blorb() for why.

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const RADIUS := 380.0
## Matches jungle_kingdom_foliage.gd's own CLEAR_RADIUS -- stays out of
## JungleVillage's footprint the same way that scatter does.
const CLEAR_RADIUS := 24.0

const NORMAL_COUNT := 6
const OTHER_ELEMENTS := ["electric", "rock", "fire", "ground"]
const PLANT_COUNT := 5
const AIR_COUNT := 2

var _rng := RandomNumberGenerator.new()
var _terrain: Node


func _ready() -> void:
	_rng.seed = 20260825
	_terrain = get_node_or_null("../Terrain")
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	# Deferred -- see jungle_kingdom_village.gd's own _ready() comment for the
	# full reasoning: _place() below reaches up to get_parent().add_child(),
	# which crashes ("Parent node is busy setting up children") if called
	# straight from _ready(), since the kingdom root is still mid-setup,
	# iterating its own children's _ready() calls (this node included) at
	# that exact moment.
	_spawn_all.call_deferred()


func _spawn_all() -> void:
	for i in NORMAL_COUNT:
		_place("", false)
	for element in OTHER_ELEMENTS:
		_place(element, false)
	for i in PLANT_COUNT:
		_place("plant", false)
	for i in AIR_COUNT:
		_place("air", false)


func _place(element: String, shiny: bool) -> void:
	var picked: Variant = _pick_position()
	if picked == null:
		return
	var pos: Vector2 = picked
	var inst = BLORB_SCENE.instantiate()
	inst.in_party = false
	inst.initial_element = element
	inst.is_shiny = shiny
	inst.position = Vector3(pos.x, _terrain.get_mesh_height(pos.x, pos.y), pos.y)
	get_parent().add_child(inst)


## Stays out of the village clearing and the river -- everything here is a
## grounded/ordinary element, none of them the water type that would
## actually want the riverbed.
func _pick_position() -> Variant:
	for attempt in 8:
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * RADIUS
		var a := _rng.randf_range(0.0, TAU)
		var pos := Vector2(cos(a) * r, sin(a) * r)
		if pos.length() < CLEAR_RADIUS:
			continue
		if _terrain.has_method("river_coverage") and _terrain.river_coverage(pos.x, pos.y) > 0.05:
			continue
		return pos
	return null
