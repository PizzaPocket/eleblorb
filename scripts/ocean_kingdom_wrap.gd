extends Node3D

## Makes the ocean kingdom read as an endless sea, per direct instruction --
## crossing the map's edge teleports the player straight through to the
## exact opposite edge (leaving north re-enters south, leaving east
## re-enters west), so sailing in one direction loops forever instead of
## hitting a wall. The classic wraparound-world trick: shift by the full
## span (not mirror/negate the coordinate), so travel continues in the same
## direction and at the same offset past the boundary, reading as passing
## straight through rather than bouncing or flipping.
##
## True seamless "look toward the edge and see the opposite side stitched
## in" rendering (portal cameras) was considered and explicitly ruled out
## as too heavy an engineering lift for a featureless open-ocean kingdom --
## instead this pairs with a much denser fog on this kingdom's own
## WorldEnvironment (see ocean_kingdom.tscn) that fades the water into an
## indistinct horizon well before WRAP_HALF_SIZE, so the actual edge is
## never visually legible and the teleport itself is never seen happening.

## Matches ocean_kingdom_terrain.gd's own HALF_SIZE -- the collision
## floor's/water surface's own extent, so wrapping happens exactly at the
## edge of the actual playable water rather than an arbitrary inset.
const WRAP_HALF_SIZE := 900.0

@onready var _player: Node3D = $"../Player"


func _physics_process(_delta: float) -> void:
	var span := WRAP_HALF_SIZE * 2.0
	var pos := _player.global_position
	var wrapped := false
	if pos.x > WRAP_HALF_SIZE:
		pos.x -= span
		wrapped = true
	elif pos.x < -WRAP_HALF_SIZE:
		pos.x += span
		wrapped = true
	if pos.z > WRAP_HALF_SIZE:
		pos.z -= span
		wrapped = true
	elif pos.z < -WRAP_HALF_SIZE:
		pos.z += span
		wrapped = true
	if wrapped:
		_player.global_position = pos
