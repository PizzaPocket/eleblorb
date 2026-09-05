extends Node3D
class_name CloudScatter

## Scatters simple low-poly cloud puffs (clusters of overlapping SuperEggs,
## unshaded so lighting doesn't darken them) high above the field. No cloud
## assets exist in either Kenney kit, so these are built procedurally.
## Puffs use the same SuperEgg primitive the character rig is built from
## (per direct instruction), squashed wider than they are tall (PUFF_
## HEIGHT_FACTOR) rather than the plain spheres used before -- a real
## cumulus puff reads as a flattened, horizontally-spread blob, not a ball.
##
## Puffs are unshaded, so day_night_cycle.gd's sun/sky changes never touch
## them on their own -- they'd stay pure white at midnight otherwise.
## set_night_factor() below is how day_night_cycle.gd tints the single
## shared puff material toward a dim moonlit grey-blue instead.

## Dense enough to form a real aerial platforming field rather than a few
## distant sky decorations; seeded generation keeps the route repeatable.
@export var cloud_count: int = 52
@export var altitude_min: float = 70.0
@export var altitude_max: float = 110.0
@export var spread: float = 260.0
@export var rng_seed: int = 77

## How tall a puff is relative to its own horizontal radius -- below 1.0,
## since puffs should read as wider than they are tall.
const PUFF_HEIGHT_FACTOR := 0.6

const DAY_COLOR := Color(1, 1, 1)
const NIGHT_COLOR := Color(0.22, 0.25, 0.38)

var _rng := RandomNumberGenerator.new()
var _material: StandardMaterial3D


func _ready() -> void:
	_rng.seed = rng_seed
	_ensure_material()

	for i in cloud_count:
		_place_cloud()


func _ensure_material() -> void:
	if _material != null:
		return
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(1, 1, 1)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED


func _place_cloud() -> void:
	var cloud := Node3D.new()
	cloud.position = Vector3(
		_rng.randf_range(-spread, spread),
		_rng.randf_range(altitude_min, altitude_max),
		_rng.randf_range(-spread, spread)
	)
	add_child(cloud)

	var puff_count := int(_rng.randf_range(4, 8))
	for i in puff_count:
		var puff_radius := _rng.randf_range(3.0, 7.0)
		var semi_axes := Vector3(puff_radius, puff_radius * PUFF_HEIGHT_FACTOR, puff_radius)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = SuperEgg.build_mesh(semi_axes, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		mesh_instance.material_override = _material
		mesh_instance.set_meta("cloud_semi_axes", semi_axes)
		mesh_instance.position = Vector3(
			_rng.randf_range(-8.0, 8.0),
			_rng.randf_range(-1.5, 1.5),
			_rng.randf_range(-8.0, 8.0)
		)
		cloud.add_child(mesh_instance)


## Returns the highest visible puff top at this XZ position, provided that
## top is not above `max_surface_y`. Callers use that ceiling to make cloud
## support one-way: rising bodies pass through undersides, falling bodies
## approaching from above can settle on the top.
func get_support_height_at(world_x: float, world_z: float, max_surface_y: float = INF) -> Variant:
	var best: Variant = null
	for cloud in get_children():
		for puff_node in cloud.get_children():
			if not puff_node is MeshInstance3D or not puff_node.has_meta("cloud_semi_axes"):
				continue
			var puff := puff_node as MeshInstance3D
			var axes := puff.get_meta("cloud_semi_axes") as Vector3
			var center := puff.global_position
			# Match SuperEgg.EPSILON_SOFT's rounded-square horizontal profile.
			# The old ellipse approximation excluded the puff's real side/corner
			# volume, which made a character fall through visibly rendered cloud.
			var horizontal_profile := pow(absf((world_x - center.x) / axes.x), SuperEgg.EPSILON_SOFT) + pow(absf((world_z - center.z) / axes.z), SuperEgg.EPSILON_SOFT)
			if horizontal_profile > 1.0:
				continue
			var top := center.y + axes.y * pow(1.0 - horizontal_profile, 1.0 / SuperEgg.EPSILON_SOFT)
			if top <= max_surface_y and (best == null or top > best):
				best = top
	return best


## t: 0 (full day, white) .. 1 (full night, dim moonlit grey-blue).
func set_night_factor(t: float) -> void:
	if _material:
		_material.albedo_color = DAY_COLOR.lerp(NIGHT_COLOR, t)


## The real ceiling on how much a single step can rise and still be
## reachable by an ordinary standing jump -- same derivation as
## town_generator.gd's own MAX_STEP_RISE (see that constant's own comment
## for the full v^2/(2*g*s) calculation); kept as its own copy here for the
## same reason every small helper shared between that script and this one
## already is (no common base class to hang it on).
const MAX_STEP_RISE := 1.2

## A hand-placed (not randomly scattered) chain of natural-looking cloud
## clusters continuing a ground-based climb up through this layer's ambient
## clouds -- see town_generator.gd's own _build_sky_stairs(), which climbs a
## crate spiral up to just below altitude_min and then hands off to this
## function at `start` (world position, matching this node's own untransformed
## origin -- see _place_cloud()'s identical assumption). Ends on one wide
## landing cluster carrying the Air Gem. Per direct instruction: "make [the
## floaty stairs around town] parkour all the way up to the clouds... and
## have an air gem be up there."
##
## Per direct correction: an earlier version built each step as one lone
## geometric puff, which "look[ed] kind of too much like a constructed
## route" next to every naturally-clustered cloud elsewhere in the sky.
## Steps are now the same multi-puff organic blob _place_cloud() itself
## builds for the ambient background (see _build_course_cluster()), just
## placed in a deliberate climbing sequence instead of scattered at random.
##
## Per direct correction, every step's rise is also capped at MAX_STEP_RISE.
## Nests puffs exactly as deep as get_support_height_at() expects (this
## node -> one cluster -> puffs) via _build_course_cluster(). Uses its own
## fixed-seed RandomNumberGenerator, not the shared _rng (already consumed
## by _ready()'s ambient placement).
func build_sky_course(start: Vector3) -> void:
	_ensure_material()
	# town_generator.gd's own "rebuild_now" editor button re-runs the whole
	# call chain that reaches here without this script's "Generated" subtree
	# equivalent to free the old one first -- without this, each in-editor
	# rebuild would leave a stale, still-standing (and still walkable) extra
	# course and gem behind rather than replacing them.
	var existing := get_node_or_null("SkyParkourCourse")
	if existing != null:
		existing.free()
	var course := Node3D.new()
	course.name = "SkyParkourCourse"
	add_child(course)

	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	var pos := Vector2(start.x, start.z)
	var top_y := start.y
	var heading := rng.randf_range(0.0, TAU)
	# The near edge of an organic cluster can sit anywhere from its jitter
	# pulling a puff away from the direction of travel down to (conservatively)
	# just its smallest puff's own radius -- using that smaller, conservative
	# figure (not an average or the jittered outer extent) for gap math means
	# the real edge-to-edge distance a jump has to cross never comes out
	# LARGER than intended, only ever the same or a bit shorter.
	const STEP_PUFF_MIN := 2.4
	const STEP_PUFF_MAX := 3.0
	const STEP_JITTER := 1.0
	const STEP_EFFECTIVE_RADIUS := STEP_PUFF_MIN
	const EDGE_GAP_MIN := 1.2
	const EDGE_GAP_MAX := 1.8
	const STEP_COUNT := 7
	var prev_effective_radius := 0.0
	var path_positions: Array[Vector2] = [Vector2(start.x, start.z)]
	for i in STEP_COUNT:
		var center_gap := prev_effective_radius + STEP_EFFECTIVE_RADIUS + rng.randf_range(EDGE_GAP_MIN, EDGE_GAP_MAX)
		heading += rng.randf_range(-0.45, 0.45)
		pos += Vector2(sin(heading), cos(heading)) * center_gap
		top_y += rng.randf_range(0.7, MAX_STEP_RISE)
		_build_course_cluster(course, pos.x, pos.y, top_y, rng, STEP_PUFF_MIN, STEP_PUFF_MAX, 4, 6, STEP_JITTER)
		prev_effective_radius = STEP_EFFECTIVE_RADIUS
		path_positions.append(pos)

	# One wide landing cluster at the top -- comfortably larger than the
	# climb's own steps, so the final jump and the reward sitting on it both
	# read as a clear destination rather than one more mid-climb step.
	const LANDING_PUFF_MIN := 4.0
	const LANDING_PUFF_MAX := 5.0
	const LANDING_JITTER := 1.6
	var landing_gap := prev_effective_radius + LANDING_PUFF_MIN + rng.randf_range(EDGE_GAP_MIN, EDGE_GAP_MAX)
	heading += rng.randf_range(-0.3, 0.3)
	pos += Vector2(sin(heading), cos(heading)) * landing_gap
	top_y += rng.randf_range(0.7, MAX_STEP_RISE)
	_build_course_cluster(course, pos.x, pos.y, top_y, rng, LANDING_PUFF_MIN, LANDING_PUFF_MAX, 5, 7, LANDING_JITTER)
	_place_air_gem(course, Vector3(pos.x, top_y + 0.5, pos.y))

	_build_safety_net(course, path_positions, start.y, rng)


## A few big catch clouds a bit below the whole climb, per direct
## instruction ("as a bit of a safety net if a player falls") -- generous
## radius and generous overlap with each other so a slip anywhere along the
## course's own horizontal path (see `path_positions`, every step center
## from the ground hand-off through the landing) still comes down onto one
## of them rather than dropping all the way back to the crate spiral or the
## ground below it.
func _build_safety_net(course: Node3D, path_positions: Array[Vector2], start_y: float, rng: RandomNumberGenerator) -> void:
	const NET_DROP := 11.0
	const NET_PUFF_MIN := 5.5
	const NET_PUFF_MAX := 7.0
	const NET_JITTER := 3.0
	var net_y := start_y - NET_DROP
	# One net cluster centered under a handful of points spread along the
	# path (first, middle, and last step) rather than just the start --
	# covers the whole course's own horizontal wander, not only its base.
	var sample_indices: Array[int] = [0, path_positions.size() / 2, path_positions.size() - 1]
	for index in sample_indices:
		var center := path_positions[index]
		_build_course_cluster(course, center.x, center.y, net_y, rng, NET_PUFF_MIN, NET_PUFF_MAX, 6, 9, NET_JITTER)


## One organic, multi-puff cloud cluster -- the same overlapping-SuperEgg
## technique _place_cloud() uses for the ambient background layer, kept as
## its own copy (not shared) so a future change to that background layer's
## density/shape can't silently reshape this deliberately-placed course.
##
## Generates its puffs' size/jitter first and only THEN solves for the
## cluster's own vertical position, rather than guessing a center height up
## front: a puff's own top depends on both its randomly-rolled radius and
## its jitter, neither known until it's actually built, so placing the
## cluster at `target_top_y - highest_local_top` (after the fact) is what
## lets build_sky_course() land each step's highest point -- what
## get_support_height_at() will actually pick as its standing height --
## exactly on the height its own MAX_STEP_RISE budget calls for, rather
## than only approximately.
func _build_course_cluster(
	parent: Node3D, target_x: float, target_z: float, target_top_y: float,
	rng: RandomNumberGenerator, puff_min: float, puff_max: float,
	puff_count_min: int, puff_count_max: int, jitter: float
) -> void:
	var puff_count := int(rng.randf_range(puff_count_min, puff_count_max))
	var puffs: Array[Dictionary] = []
	var highest_local_top := -INF
	for i in puff_count:
		var puff_radius := rng.randf_range(puff_min, puff_max)
		var semi_axes := Vector3(puff_radius, puff_radius * PUFF_HEIGHT_FACTOR, puff_radius)
		var local_offset := Vector3(
			rng.randf_range(-jitter, jitter),
			rng.randf_range(-jitter * 0.2, jitter * 0.2),
			rng.randf_range(-jitter, jitter)
		)
		puffs.append({"semi_axes": semi_axes, "offset": local_offset})
		highest_local_top = maxf(highest_local_top, local_offset.y + semi_axes.y)

	var cloud := Node3D.new()
	cloud.position = Vector3(target_x, target_top_y - highest_local_top, target_z)
	parent.add_child(cloud)
	for data in puffs:
		var semi_axes: Vector3 = data["semi_axes"]
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = SuperEgg.build_mesh(semi_axes, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		mesh_instance.material_override = _material
		mesh_instance.set_meta("cloud_semi_axes", semi_axes)
		mesh_instance.position = data["offset"]
		cloud.add_child(mesh_instance)


## Same _place_gem() pattern town_generator.gd/wilderness_scatter.gd each
## already keep their own copy of -- this script shares no base class with
## either to hang one on. Position set before add_child(), matching both of
## those: gem.gd's own _ready() (floats=true) captures _base_y from
## `position` immediately on entering the tree.
func _place_air_gem(course: Node3D, pos: Vector3) -> void:
	const GEM_SCENE := "res://scenes/gem.tscn"
	var packed: PackedScene = load(GEM_SCENE)
	if packed == null:
		push_warning("Missing gem scene: " + GEM_SCENE)
		return
	var gem = packed.instantiate()
	gem.gem_color = ShopCatalog.AIR_COLOR
	gem.display_name = "Air Gem"
	gem.collectible = true
	gem.floats = true
	gem.position = pos
	course.add_child(gem)
