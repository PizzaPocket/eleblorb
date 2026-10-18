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

static var _cloud_layers_cache: Array[Node] = []
static var _cloud_layers_frame := -1


## A swimmer may already overlap a shallow floor at the feet. Allow recovery
## away from that floor, while checking every contact for a wall or ceiling.
static func can_lift(body: CharacterBody3D, lift: float) -> bool:
	var collision := KinematicCollision3D.new()
	var poses := [body.global_transform, body.global_transform.translated(Vector3.UP * lift)]
	for i in poses.size():
		var motion := Vector3.UP * lift if i == 0 else Vector3.ZERO
		if body.test_move(poses[i], motion, collision, body.safe_margin, true, 8):
			for contact in collision.get_collision_count():
				if collision.get_normal(contact).dot(body.up_direction) < cos(body.floor_max_angle):
					return false
	return true


## Discrete walking steps use the body's whole collision shape, never an
## analytic terrain snap. Slopes remain move_and_slide's responsibility.
static func try_step_up(ctx: TraversalContext) -> bool:
	var body := ctx.body
	var planar := Vector3(body.velocity.x, 0.0, body.velocity.z)
	if not ctx.grounded or planar.length() < ctx.scaled(0.1):
		return false
	var travel := planar * ctx.delta
	var obstacle := KinematicCollision3D.new()
	if not body.test_move(body.global_transform, travel, obstacle, body.safe_margin, false, 8):
		return false
	var minimum_up := cos(body.floor_max_angle)
	var blocked := false
	for i in obstacle.get_collision_count():
		if obstacle.get_normal(i).dot(body.up_direction) < minimum_up:
			blocked = true
	if not blocked:
		return false
	var maximum := ctx.scaled(0.35)
	var raised := body.global_transform
	if not can_lift(body, maximum):
		return false
	raised.origin.y += maximum
	# Look past the capsule's leading edge, but only lift once actual travel
	# encounters a wall. This cannot pull a falling body onto a distant roof.
	var forward := planar.normalized() * maxf(travel.length(), ctx.scaled(0.4))
	if body.test_move(raised, forward):
		return false
	raised.origin += forward
	var landing := KinematicCollision3D.new()
	if not body.test_move(raised, Vector3.DOWN * (maximum + ctx.scaled(0.03)), landing):
		return false
	for i in landing.get_collision_count():
		var collider := landing.get_collider(i) as Node
		if collider is CharacterBody3D or (collider != null and collider.is_in_group("blorbs")):
			return false
		if landing.get_normal(i).dot(body.up_direction) < minimum_up:
			return false
	var rise := maximum + landing.get_travel().y
	if rise <= ctx.scaled(0.01) or rise > maximum:
		return false
	# XZ is still advanced exactly once, by the driver's move_and_slide.
	body.global_position.y += rise + body.safe_margin
	body.velocity.y = 0.0
	return true


## The height to stand at on a cloud above `world`, or null where there is
## none. Any character can ask; only the one-way surface decides.
##
## Every cloud layer in the world is asked, not one named sibling. The demo
## world has two, and for a long time only the Air Kingdom's was ever
## queried: the 180 clouds strung down the valley were scenery you fell
## through, for no reason anybody chose. A cloud is a cloud.
static func cloud_stand_height(body: Node3D, foot_offset: float, ceiling: float) -> Variant:
	var best: Variant = null
	for layer in _cloud_layers(body):
		var top: Variant = layer.get_support_height_at(
			body.global_position.x, body.global_position.z, ceiling
		)
		if top != null and (best == null or (top as float) > (best as float)):
			best = top
	if best == null:
		return null
	return (best as float) + foot_offset - CLOUD_SINK_DEPTH


## The world's cloud layers, looked up once a frame rather than once a query.
## Every body and every free blorb asks for cloud support every frame, and the
## group lookup allocates a fresh array each time it is made.
static func _cloud_layers(body: Node3D) -> Array[Node]:
	var tree := body.get_tree()
	if tree == null:
		return []
	var frame := Engine.get_process_frames()
	if frame != _cloud_layers_frame:
		_cloud_layers_frame = frame
		_cloud_layers_cache.clear()
		for layer in tree.get_nodes_in_group("cloud_scatters"):
			if layer.has_method("get_support_height_at"):
				_cloud_layers_cache.append(layer)
	return _cloud_layers_cache


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


## The same support contract at a proposed foot position. Driven mounts use
## the normal to sweep along a built ramp instead of treating it as a wall.
static func sample_ground(body: Node3D, terrain: Node, at: Vector3, exclude: Array[RID], reach: float = REACH) -> Dictionary:
	var fallback := at.y
	if terrain!=null and terrain.has_method("get_mesh_height"):
		fallback=terrain.get_mesh_height(at.x,at.z)
	var result := {"height":fallback,"normal":Vector3.UP}
	var world := body.get_world_3d()
	if world==null: return result
	var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*RISE,at-Vector3.UP*reach,1)
	query.exclude=exclude
	var hit := world.direct_space_state.intersect_ray(query)
	if not hit.is_empty() and float(hit.position.y)>=fallback-0.001:
		result.height=float(hit.position.y)
		result.normal=hit.normal
	return result
