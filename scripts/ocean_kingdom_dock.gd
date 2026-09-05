extends Node3D

## A small standalone arrival dock for the ocean kingdom -- built the same way
## floating_village.gd's own _build_portal_dock()/_build_stilt() build the
## fishing village's portal deck, reused here directly since "the portal
## should sit on a floating dock platform exactly like it is in the fishing
## village" per direct instruction. Unlike that village, this kingdom is nothing
## but water (see ocean_kingdom_terrain.gd), so this single deck is the
## kingdom's entire "solid ground": both the ReturnPortal and the arriving
## Player stand on it (their exact Y is baked into ocean_kingdom.tscn to match
## DECK_Y here, since kingdom_bootstrap.gd's _snap_portal_to_ground() skips
## adjusting height wherever is_lake_area() is true).

const DECK_Y := 0.34
const DECK_SIZE := Vector3(14.0, 0.32, 16.0)
const DECK_COLOR := Color(0.26, 0.16, 0.09)

var _terrain: Node


func _ready() -> void:
	_terrain = get_node_or_null("../Terrain")
	call_deferred("_build")


func _build() -> void:
	if _terrain == null or not _terrain.has_method("get_lake_water_level"):
		return
	var center := Vector3(0.0, _terrain.get_lake_water_level(), 0.0)
	_build_box("ArrivalDock", center + Vector3(0, DECK_Y, 0), DECK_SIZE, DECK_COLOR, true)
	for corner in [Vector3(-6.0, 0, -7.0), Vector3(6.0, 0, -7.0), Vector3(-6.0, 0, 7.0), Vector3(6.0, 0, 7.0)]:
		_build_stilt(center + corner)
	for offset in [Vector3(-5.5, DECK_Y + 0.16, -1.5), Vector3(5.5, DECK_Y + 0.16, 1.5)]:
		var lantern := TownProps.build_lantern()
		lantern.name = "OceanDockLantern"
		lantern.position = center + offset
		add_child(lantern)
	_build_docking_ramps(center)


## Two climbable ramps let a swimming player or trailing blorb climb back
## onto the deck from the water -- there's no shoreline anywhere in this
## kingdom (see ocean_kingdom_terrain.gd's is_lake_area(), true everywhere),
## so without these the arrival dock would be unreachable once you left it.
## Reuses floating_village.gd's own _build_docking_ramps() technique
## (WIDTH/RUN/RISE/SUBMERGED_BASE values and TownProps.build_ramp() call)
## verbatim, positioned flush with this dock's own DECK_SIZE (half-depth 8.0)
## rather than that village's boardwalk offsets.
func _build_docking_ramps(center: Vector3) -> void:
	const WIDTH := 3.4
	const RUN := 8.0
	const RISE := 1.95
	const SUBMERGED_BASE := 1.45
	var south_ramp := TownProps.build_ramp(WIDTH, RUN, RISE, DECK_COLOR)
	south_ramp.name = "SouthDockRamp"
	south_ramp.position = center + Vector3(0, -SUBMERGED_BASE, -8.0 - RUN)
	add_child(south_ramp)
	var north_ramp := TownProps.build_ramp(WIDTH, RUN, RISE, DECK_COLOR)
	north_ramp.name = "NorthDockRamp"
	north_ramp.position = center + Vector3(0, -SUBMERGED_BASE, 8.0 + RUN)
	north_ramp.rotation.y = PI
	add_child(north_ramp)


func _build_stilt(pos: Vector3) -> void:
	_build_box("Stilt", pos + Vector3(0, -3.0, 0), Vector3(0.34, 6.0, 0.34), Color(0.2, 0.12, 0.07), false)


func _build_box(name_text: String, pos: Vector3, size: Vector3, color: Color, collision: bool) -> void:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = name_text
	root.position = pos
	add_child(root)
	var mesh := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	root.add_child(mesh)
	if collision:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		root.add_child(shape)
