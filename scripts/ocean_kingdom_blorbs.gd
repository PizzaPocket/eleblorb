extends Node3D

## Wild blorbs in the ocean kingdom -- "only water and air to start" per
## direct instruction (see docs/world_bible.md's own Kingdoms entry). Same
## sibling-parenting pattern as jungle_kingdom_blorbs.gd/wilderness_scatter.
## gd's own _spawn_lake_water_blorbs() -- blorb.gd's own _ready() needs its
## spawned instance to be a sibling of Terrain/Player, not a child of this
## node, to resolve its fixed get_node("../Terrain")/("../Player") lookups.

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const RADIUS := 380.0
## Keeps clear of OceanKingdomDock's own footprint (DECK_SIZE 14x16, stilts
## out to +/-7) so nothing spawns underneath the arrival dock.
const CLEAR_RADIUS := 20.0

const WATER_COUNT := 8
const AIR_COUNT := 4

var _rng := RandomNumberGenerator.new()
var _terrain: Node


func _ready() -> void:
	_rng.seed = 20260826
	_terrain = get_node_or_null("../Terrain")
	if _terrain == null or not _terrain.has_method("get_lake_water_level"):
		return
	# Deferred -- this _ready() can run while the kingdom scene root is still
	# synchronously working through its own children's _ready() calls, and
	# _place()'s own get_parent().add_child() fails outright while the parent
	# is in that state (confirmed by direct report: "Parent node is busy
	# setting up children"). Matches wilderness_scatter.gd's own identical
	# _finish_dynamic_initialization.call_deferred() fix for the same class
	# of issue.
	_spawn_wild_blorbs.call_deferred()


func _spawn_wild_blorbs() -> void:
	for i in WATER_COUNT:
		_place("water")
	for i in AIR_COUNT:
		_place("air")


func _place(element: String) -> void:
	var pos := _pick_position()
	var inst = BLORB_SCENE.instantiate()
	inst.in_party = false
	inst.initial_element = element
	inst.is_shiny = false
	# Start at the shared waterline -- blorb.gd's own buoyancy (water) or
	# hover (air) settles it from there on the next frame, same as
	# wilderness_scatter.gd's own _spawn_lake_water_blorbs().
	inst.position = Vector3(pos.x, _terrain.get_lake_water_level(), pos.y)
	get_parent().add_child(inst)


func _pick_position() -> Vector2:
	for attempt in 5:
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * RADIUS
		var a := _rng.randf_range(0.0, TAU)
		var pos := Vector2(cos(a) * r, sin(a) * r)
		if pos.length() >= CLEAR_RADIUS:
			return pos
	return Vector2(RADIUS * 0.5, 0.0)
