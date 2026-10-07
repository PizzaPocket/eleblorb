class_name SlopeFoundation
extends RefCounted

## Building on sloping ground (the architecture skill's "Foundations on sloping
## ground"): a level deck set just above the highest ground anywhere under its
## footprint, carried by coursed stone that runs from the deck's edge down into
## the ground at every point of its perimeter, embedded past the ground there.
## Where the ground is nearly level the foundation is a single low course;
## where it falls away it becomes a stepped, battered retaining wall. Nothing
## is pushed down to "approximately grounded": the deck takes the high point
## and the masonry reaches the low ones.
##
## First used for Ohio's overlook at the cliff edge; built for any deck or
## building pad on a slope (the fire caldera's terraces next).

const COURSE := 0.48
const EMBED := 0.45
const DEPTH := 0.5
## Each course below the top steps out this far (a battered wall).
const BATTER := 0.05


## A round pad of radius `radius` at plan point `centre` (in `ground`'s frame).
## Returns {"body": StaticBody3D, "surface_y": float}: the walking deck is the
## caller's to finish (pavers, planks); this provides its level, its collider
## and the stone that carries it.
static func build_round(
	parent: Node3D, centre: Vector2, radius: float, ground: Callable, stone: Color,
	node_name: String = "SlopeFoundation", clearance: float = 0.12, segments: int = 30
) -> Dictionary:
	var high := -INF
	for ring: float in [0.0, 0.35, 0.7, 1.0]:
		var count := 1 if ring == 0.0 else int(10.0 * ring) + 6
		for i in count:
			var angle := TAU * float(i) / float(count)
			high = maxf(high, float(ground.call(centre + Vector2(cos(angle), sin(angle)) * radius * ring)))
	var surface_y := high + clearance
	var body := StaticBody3D.new()
	body.name = node_name
	body.collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
	body.collision_mask = 0
	parent.add_child(body)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(centre.x * 131.0 + centre.y * 17.0)
	var chord := TAU * radius / float(segments)
	for i in segments:
		var angle := TAU * (float(i) + 0.5) / float(segments)
		var out := Vector2(cos(angle), sin(angle))
		var at := centre + out * (radius - DEPTH * 0.5)
		# The low point this column must reach: the ground at its face and a
		# little beyond it, so the foot is buried even on the steepest side.
		var low := minf(float(ground.call(centre + out * radius)), float(ground.call(centre + out * (radius + 0.8))))
		var foot := low - EMBED
		var height := surface_y - foot
		var yaw := atan2(out.x, out.y)
		var courses := maxi(int(ceil(height / COURSE)), 1)
		for course in courses:
			var top := surface_y - float(course) * COURSE
			var course_height := minf(COURSE, top - foot)
			if course_height < 0.05:
				break
			var step_out := BATTER * float(course)
			# Two stones per segment, their joints shifted a quarter stone on
			# alternate courses so no joint runs straight up the wall.
			var stagger := 0.12 if course % 2 == 1 else -0.12
			for half: float in [-0.25, 0.25]:
				var along := (half + stagger) * chord
				var tangent := Vector2(-out.y, out.x)
				var stone_at := at + out * step_out + tangent * along
				var semi := Vector3(chord * 0.27 + rng.randf_range(-0.03, 0.05), course_height * 0.5 - 0.01, DEPTH * 0.5 + rng.randf_range(0.0, 0.06))
				var block := SuperEgg.build_part(semi, stone.darkened(rng.randf_range(0.0, 0.14)).lerp(stone.lightened(0.1), rng.randf_range(0.0, 0.3)), 4.2, 4.2)
				block.transform = Transform3D(Basis(Vector3.UP, yaw + rng.randf_range(-0.04, 0.04)), Vector3(stone_at.x, top - course_height * 0.5, stone_at.y))
				body.add_child(block)
				CollisionPolicy.mark_decorative(block)
		# One collider per column: the wall a player meets or climbs.
		var holder := MeshInstance3D.new()
		holder.name = "FoundationColumn%d" % i
		body.add_child(holder)
		var collider := CollisionPolicy.add_box(
			body, holder, Vector3(chord + 0.1, height, DEPTH + BATTER * float(courses)),
			Vector3(at.x + out.x * BATTER * float(courses) * 0.5, foot + height * 0.5, at.y + out.y * BATTER * float(courses) * 0.5),
			Basis(Vector3.UP, yaw), false
		)
		collider.name = "FoundationColumnShape%d" % i
	# The deck's own collider: one level disc, so nothing snags.
	var holder := MeshInstance3D.new()
	holder.name = "DeckSurface"
	body.add_child(holder)
	var deck := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.3
	deck.shape = shape
	deck.position = Vector3(centre.x, surface_y - 0.15, centre.y)
	deck.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	holder.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(deck)
	return {"body": body, "surface_y": surface_y}
