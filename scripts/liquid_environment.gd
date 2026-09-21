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

## Both of these are about the head being out of the water, and both used to
## be absolute distances authored against the human figure. Floating a body's
## feet 1.4 m under the surface leaves a person's head and shoulders in the
## air and drowns a monkey a quarter that size outright.
##
## They are measured from where the body's own head begins -- the base of the
## skull, not its crown -- because that line is what "the head is above
## water" actually means. A rig with a large head for its size therefore
## floats higher, which is correct.

## Where the waterline sits relative to the base of the head while floating:
## just below it, so the whole head and a little shoulder stand clear. The
## human's authored 1.4 m against a head beginning 1.596 m up is where this
## comes from.
const FLOAT_DEPTH_FRACTION := 0.877
## How deep the water has to be before it must be swum, on the same measure:
## once standing on the bottom would put the base of the head under, there is
## nothing to do but swim. Below it a body wades or walks out up a bank or a
## ramp with its head in the air. The human's authored 1.75 m is where this
## comes from.
const SWIMMABLE_FRACTION := 1.097

## The human figure these were authored against, for a body that has not been
## measured yet.
const REFERENCE_HEAD_BASE := 1.596

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


## How far under the surface this body's feet hang while it floats, so that
## its head is out of the water whoever is swimming.
static func float_depth(head_base: float) -> float:
	return maxf(head_base, 0.01) * FLOAT_DEPTH_FRACTION


## The depth of water this body has to swim in rather than wade through: any
## less and its feet reach the bottom with its head still in the air.
static func swimmable_depth(head_base: float) -> float:
	return maxf(head_base, 0.01) * SWIMMABLE_FRACTION


## Where this body's head begins, above its own feet: the base of the skull,
## which is the line that decides whether the head is out of the water.
##
## Taken from the rendered head where there is one, so a rig of any shape or
## scale answers for itself rather than declaring a number anywhere. The head
## joint sits inside the skull on both existing rigs, so the underside of the
## rendered head is the honest answer; the joint and then the profile's
## standing height are the fallbacks for a body with less to measure.
static func head_height(head: Node3D, feet_y: float, profile: PlayableCharacterProfile) -> float:
	if head != null:
		var base := _rendered_base(head)
		if base != INF and base - feet_y > 0.01:
			return base - feet_y
		var joint := head.global_position.y - feet_y
		if joint > 0.01:
			return joint
	return profile.standing_height if profile != null else REFERENCE_HEAD_BASE


## The lowest rendered point of `node` and everything under it, in world
## space, or INF where it draws nothing.
static func _rendered_base(node: Node3D) -> float:
	var base := INF
	var mesh_node := node as MeshInstance3D
	if mesh_node != null and mesh_node.mesh != null:
		var box: AABB = mesh_node.global_transform * mesh_node.mesh.get_aabb()
		base = box.position.y
	for child in node.get_children():
		var child_node := child as Node3D
		if child_node != null:
			base = minf(base, _rendered_base(child_node))
	return base


func in_lava() -> bool:
	return liquid == Liquid.LAVA


func in_water() -> bool:
	return liquid == Liquid.WATER


## Whether the basin here is deeper than this body is tall enough to stand
## in. A feathered shoreline, a shelving bank and a dock ramp all stay
## something to walk out on, because the feet reach the bottom while the head
## is still in the air.
func deep_enough_to_swim(for_head_height: float = REFERENCE_HEAD_BASE) -> bool:
	if liquid == Liquid.NONE:
		return false
	return surface_height - floor_height >= swimmable_depth(for_head_height)


## Whether a body at `feet_y` is under the liquid's surface.
func submerged(feet_y: float) -> bool:
	return liquid != Liquid.NONE and feet_y <= surface_height
