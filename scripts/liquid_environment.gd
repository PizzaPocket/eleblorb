class_name LiquidEnvironment
extends RefCounted

## What liquid a body is standing in, for any character
## (docs/traversal_powers_architecture.md).
##
## Every character has to ask the same questions before it can move: is there
## lava here, is there water, where is its surface, where is the ground under
## it, and what does this suit make of that. Both characters asked the terrain
## themselves and, asking slightly differently, came to different answers
## about the same pond.
##
## This reports the facts only. What a body does about them stays its own: a
## swimmer clamps itself between the surface and the bed, a lava walker pins
## itself to the molten plane, and each does it at its own scale.

## How deep a swimmer floats, and how much water a basin needs before it can
## be swum at all rather than waded through.
const SWIM_FOOT_DEPTH := 1.4
const MIN_SWIMMABLE_DEPTH := SWIM_FOOT_DEPTH + 0.35

enum Liquid { NONE, WATER, LAVA }

var liquid := Liquid.NONE
## The liquid's own surface, and the solid ground beneath it.
var surface_height := -INF
var floor_height := 0.0
## What the suit makes of lava here, which is only meaningful in it.
var lava_contact := LavaMode.Contact.BARRED


## Reads the world at `at`. Lava wins where the two ever overlap: it is the
## hazard, and being in it decides everything else.
func read(terrain: Node, suit: BlorbSuitController, at: Vector3) -> void:
	liquid = Liquid.NONE
	surface_height = -INF
	lava_contact = LavaMode.Contact.BARRED
	if terrain == null:
		floor_height = at.y
		return
	var xz := Vector2(at.x, at.z)
	floor_height = terrain.get_mesh_height(xz.x, xz.y)
	if LavaMode.terrain_has_lava(terrain) and bool(terrain.is_lava_area(xz)):
		liquid = Liquid.LAVA
		surface_height = terrain.get_lava_surface_height(xz)
		lava_contact = LavaMode.contact(suit)
		return
	if terrain.has_method("is_lake_area") and bool(terrain.is_lake_area(xz)):
		liquid = Liquid.WATER
		surface_height = terrain.get_lake_water_level()


func in_lava() -> bool:
	return liquid == Liquid.LAVA


func in_water() -> bool:
	return liquid == Liquid.WATER


## Whether the basin here holds enough water to swim in. A feathered
## shoreline stays something to walk through.
func deep_enough_to_swim() -> bool:
	return liquid != Liquid.NONE and surface_height - floor_height >= MIN_SWIMMABLE_DEPTH


## Whether a body at `feet_y` is under the liquid's surface.
func submerged(feet_y: float) -> bool:
	return liquid != Liquid.NONE and feet_y <= surface_height
