class_name VineAnchorSearch
extends RefCounted

## Looking for something to throw a vine at.
##
## Split out of VineSwingMode, which had grown to four jobs in one class. This is
## the world-querying one: it knows how to sweep for a support and how to judge
## one, and nothing about ropes or arcs. The rope's own limits are passed in,
## because the rope is the thing that decides what it can hold.
##
## A fan rather than a single ray, and scored rather than first-hit, so a grove or
## a lined street sustains the traversal without demanding precise aim at every
## hand-over.

## How far a throw carries.
const RANGE := 78.0
## How high above the thrower a support has to stand to be worth throwing at, so
## a low tree or a bank he is standing next to cannot start a swing with nowhere
## to go. The span limits passed to best() do most of that work; this stops the
## rest.
const MIN_RISE := 7.0
## The sweep itself: eight bearings either side of and behind the aim, each tried
## at four elevations. The rear bearing matters, since a swinger who has just
## turned is often facing away from the only thing in reach.
const BEARINGS: Array[float] = [0.0, -24.0, 24.0, -48.0, 48.0, -78.0, 78.0, 180.0]
const ELEVATIONS: Array[float] = [0.92, 0.72, 0.55, 0.40]
## What the score is made of: height above the thrower counts for itself, aim
## alignment counts this much, and distance counts either for or against (see
## best()'s own `reach_out`).
const ALIGNMENT_WEIGHT := 9.0
const NEAR_WEIGHT := 0.08
const FAR_WEIGHT := 0.45
## How many unusable hits a single bearing will step over before giving up on it,
## and how far past each one the ray resumes.
const PASS_THROUGH := 3
const PASS_THROUGH_STEP := 0.4

## A little camera movement is just looking around. Deliberately looking
## 15–65 degrees up progressively asks for climbing, on every playable rig.
static func climb_intent(ctx: TraversalContext) -> float:
	var look := -ctx.aim_basis.z.normalized()
	return smoothstep(sin(deg_to_rad(15.0)), sin(deg_to_rad(65.0)), look.y)


## One support worth throwing at. A class rather than a bare Vector3 because the
## body it belongs to matters too: the next search has to be able to look past
## the tree already held.
class Found extends RefCounted:
	var point := Vector3.ZERO
	var body := RID()

	func _init(at: Vector3, of: RID) -> void:
		point = at
		body = of


## The best support for a throw from `origin`, or null. `forward` is the
## horizontal direction being aimed, already normalised. `span` is the rope's own
## window, x the shortest it will hold and y the longest. `reach_out` scores
## distance as a reward instead of a cost, which is what a hand-over wants: a
## first throw wants the best support nearby, while a hand-over wants to GET
## somewhere, and scored the near way a hand-over kept choosing something barely
## ahead of the tree already held. `skip` is ignored entirely unless a finite
## `same_body_min_y` permits a genuinely higher grip on that same structure.
static func best(
	ctx: TraversalContext, origin: Vector3, forward: Vector3, span: Vector2,
	reach_out: bool = false, skip: RID = RID(), same_body_min_y: float = INF
) -> Found:
	var space := ctx.body.get_world_3d().direct_space_state
	if space == null:
		return null
	var from := ctx.body.global_position
	var found: Found = null
	var best_score := -INF
	var climb_bias := climb_intent(ctx)
	var elevations := ELEVATIONS.duplicate()
	if climb_bias > 0.0:
		# One extra steep ray per bearing; keep the old fan as a fallback so
		# looking up cannot miss a usable support just between new angles.
		elevations.push_front(lerpf(ELEVATIONS[0], 0.98, climb_bias))
	var excluded: Array[RID] = [ctx.body.get_rid()]
	if skip.is_valid() and is_inf(same_body_min_y):
		excluded.append(skip)
	for bearing: float in BEARINGS:
		var horizontal := forward.rotated(Vector3.UP, deg_to_rad(bearing))
		var directions: Array[Vector3] = []
		for rise: float in elevations:
			directions.append((
				horizontal * sqrt(maxf(0.0, 1.0 - rise * rise)) + Vector3.UP * rise
			).normalized())
		if climb_bias > 0.0:
			# Fixed ray elevations cannot reach high up a facade once the body
			# is pressed close to it. Measure its distance, then aim above the
			# real face; the subsequent ray must still hit physical geometry.
			var face_query := PhysicsRayQueryParameters3D.create(origin, origin + horizontal * span.y, 1)
			face_query.exclude = excluded
			var face := space.intersect_ray(face_query)
			if not face.is_empty():
				var face_distance := (face.position as Vector3).distance_to(origin)
				var reach := face_distance + maxf(face_distance * 0.005, 0.00005)
				var high := lerpf(span.x + MIN_RISE + 2.0, span.y * 0.8, climb_bias)
				var low := lerpf(span.x + MIN_RISE, span.y * 0.5, climb_bias)
				for height: float in [high, low]:
					directions.append((horizontal * reach + Vector3.UP * height).normalized())
		for direction in directions:
			# A sapling must not shadow the tree behind it. The first thing a ray
			# meets is often undergrowth, too low to swing from, and taking that
			# as the answer wasted the whole bearing: once the jungle filled in
			# properly the sweep stopped finding anything at all. So a rejected
			# hit is stepped over and the ray carries on from just past it.
			var start := origin
			var travelled := 0.0
			for attempt in PASS_THROUGH + 1:
				var left := RANGE - travelled
				if left <= 0.0:
					break
				var query := PhysicsRayQueryParameters3D.create(
					start, start + direction * left, 1
				)
				query.exclude = excluded
				var hit := space.intersect_ray(query)
				if hit.is_empty():
					break
				var point: Vector3 = hit["position"]
				if hit["rid"] == skip and point.y < same_body_min_y:
					# Do not shoot through this facade to look behind it.
					break
				var climb := point.y - from.y
				var reach := from.distance_to(point)
				if climb < MIN_RISE or reach > span.y or reach < span.x:
					# Step past this one and look again along the same bearing.
					travelled = start.distance_to(point) + PASS_THROUGH_STEP + travelled
					start = point + direction * PASS_THROUGH_STEP
					continue
				var score := (
					climb
					+ horizontal.dot(forward) * ALIGNMENT_WEIGHT
					+ (reach * FAR_WEIGHT if reach_out else -reach * NEAR_WEIGHT)
				)
				if score > best_score:
					best_score = score
					found = Found.new(point, hit["rid"])
				break
	return found
