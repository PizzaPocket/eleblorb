class_name ObstacleSweep
extends RefCounted

## Collision-aware planar motion for bodies moved by assigning their position
## directly (StaticBody3D companions and mounts) rather than by move_and_slide().
## Sweeps the body's own shape through the proposed motion, stops at the first
## solid it meets, and slides the remainder along that surface, so a driven
## body meets the same rocks, walls and props the player's CharacterBody does.
##
## The swept shape should start above the body's step height, and callers
## exclude the terrain: ground height is followed separately by each body's
## own ground snapping, so the sweep only has to answer "is something solid in
## the way", never "is the ground rising".

const MAX_SLIDES := 3


## Returns the portion of `motion` the shape can travel from `from` without
## entering anything on `mask`. Vertical motion is passed through untouched by
## the slide response (surface normals are flattened), so callers pass planar
## motion only.
static func slide(
	space: PhysicsDirectSpaceState3D, shape: Shape3D, from: Transform3D,
	motion: Vector3, exclude: Array[RID], mask: int = 1
) -> Vector3:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = mask
	query.exclude = exclude
	var moved := Vector3.ZERO
	var remaining := motion
	for _slide in MAX_SLIDES:
		if remaining.length_squared() < 0.000001:
			break
		query.transform = Transform3D(from.basis, from.origin + moved)
		query.motion = remaining
		var fractions := space.cast_motion(query)
		var safe: float = fractions[0]
		var unsafe: float = fractions[1]
		if safe >= 1.0:
			return moved + remaining
		if unsafe <= 0.0:
			# Already overlapping where it starts (spawned or shoved into a
			# prop). Refusing every move would trap the body, so let it leave.
			return moved + remaining
		moved += remaining * safe
		# Read the surface normal just inside the contact, then flatten it:
		# a driven body slides along walls, never up or down them.
		query.transform = Transform3D(from.basis, from.origin + moved + remaining * (unsafe - safe))
		query.motion = Vector3.ZERO
		var rest := space.get_rest_info(query)
		if rest.is_empty():
			break
		var normal: Vector3 = rest["normal"]
		normal.y = 0.0
		if normal.length_squared() < 0.0001:
			break
		normal = normal.normalized()
		var leftover := remaining * (1.0 - safe)
		remaining = leftover - normal * minf(leftover.dot(normal), 0.0)
	return moved
