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
## ahead of the tree already held. `skip` is a body the rays ignore.
static func best(
	ctx: TraversalContext, origin: Vector3, forward: Vector3, span: Vector2,
	reach_out: bool = false, skip: RID = RID()
) -> Found:
	var space := ctx.body.get_world_3d().direct_space_state
	if space == null:
		return null
	var from := ctx.body.global_position
	var found: Found = null
	var best_score := -INF
	var excluded: Array[RID] = [ctx.body.get_rid()]
	if skip.is_valid():
		excluded.append(skip)
	for bearing: float in BEARINGS:
		var horizontal := forward.rotated(Vector3.UP, deg_to_rad(bearing))
		for rise: float in ELEVATIONS:
			var direction := (
				horizontal * sqrt(maxf(0.0, 1.0 - rise * rise)) + Vector3.UP * rise
			).normalized()
			var query := PhysicsRayQueryParameters3D.create(
				origin, origin + direction * RANGE, 1
			)
			query.exclude = excluded
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				continue
			var point: Vector3 = hit["position"]
			var climb := point.y - from.y
			if climb < MIN_RISE:
				continue
			var reach := from.distance_to(point)
			if reach > span.y or reach < span.x:
				continue
			var score := (
				climb
				+ horizontal.dot(forward) * ALIGNMENT_WEIGHT
				+ (reach * FAR_WEIGHT if reach_out else -reach * NEAR_WEIGHT)
			)
			if score > best_score:
				best_score = score
				found = Found.new(point, hit["rid"])
	return found
