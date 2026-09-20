class_name WorldSupport
extends RefCounted

## What a character is actually standing on, rather than what the terrain
## function says is underneath them.
##
## Several characters set their height straight from terrain.get_mesh_height()
## every frame. That is correct out in the world and wrong everywhere else:
## on a spaceship deck, a raised platform or anything else built rather than
## generated, it drags them back down to the ground, which is exactly what
## "the characters snap back to ground level when leaving the spaceship"
## turned out to be.
##
## So: look for something solid just beneath the feet first, and fall back to
## the terrain when nothing is there. Deliberately short-reaching, so it finds
## the floor a body is standing on without reaching for a roof far below.

const REACH := 3.0
const RISE := 1.0


## The height to stand at, at the body's own XZ. `terrain` may be null.
static func ground_height(body: Node3D, terrain: Node, reach: float = REACH) -> float:
	var terrain_height := body.global_position.y
	if terrain != null and terrain.has_method("get_mesh_height"):
		terrain_height = terrain.get_mesh_height(body.global_position.x, body.global_position.z)
	var world := body.get_world_3d()
	if world == null:
		return terrain_height
	var from := body.global_position + Vector3.UP * RISE
	var to := body.global_position - Vector3.UP * reach
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	if body is CollisionObject3D:
		query.exclude = [(body as CollisionObject3D).get_rid()]
	var hit := world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return terrain_height
	var surface: float = (hit["position"] as Vector3).y
	# Only ever prefer a surface that stands above the terrain here: below it
	# is something buried, which nobody is standing on.
	return maxf(surface, terrain_height)
