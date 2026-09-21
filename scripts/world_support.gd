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
## The one-way surfaces: clouds and tree canopies hold a body up from above
## but are entered freely from below, so each is queried with a ceiling and
## a body sinks slightly into it rather than perching on top. A canopy is a
## thin leaf mass, so it takes less than a cloud.
const CLOUD_SINK_DEPTH := 0.10
const CANOPY_SINK_DEPTH := 0.04


## The height to stand at on a cloud above `world`, or null where there is
## none. Any character can ask; only the one-way surface decides.
static func cloud_stand_height(body: Node3D, foot_offset: float, ceiling: float) -> Variant:
	return _one_way_stand_height(body, "Clouds", foot_offset, ceiling, CLOUD_SINK_DEPTH)


## The same for a walkable tree canopy.
static func canopy_stand_height(body: Node3D, foot_offset: float, ceiling: float) -> Variant:
	return _one_way_stand_height(body, "Scatter", foot_offset, ceiling, CANOPY_SINK_DEPTH)


## Duck-typed on the sibling's name and its get_support_height_at() contract,
## which both the Crossroads scatter and a kingdom's own foliage implement
## without sharing a class.
static func _one_way_stand_height(
	body: Node3D, sibling: String, foot_offset: float, ceiling: float, sink: float
) -> Variant:
	var source := body.get_node_or_null("../%s" % sibling)
	if source == null or not source.has_method("get_support_height_at"):
		return null
	var top: Variant = source.get_support_height_at(body.global_position.x, body.global_position.z, ceiling)
	if top == null:
		return null
	return (top as float) + foot_offset - sink


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
