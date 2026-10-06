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
@export var cloud_count: int = 72
# +25% over the original 70.0/110.0, per direct correction ("raise up the
# level of the normal clouds as well as the Sky Kingdom because right now
# it just kind of feels a bit too low to the ground").
@export var altitude_min: float = 87.5
@export var altitude_max: float = 137.5
## Ambient weather belongs to the whole kingdom, not merely the neighbourhood
## around its origin. The ordinary kingdom terrain fields extend roughly
## 620-900 m from centre, so this reaches their outskirts while still leaving
## genuinely clear sectors between the clustered banks. Purpose-built fields
## (the demo's valley layer and authored Sky Kingdom course) override this.
@export var spread: float = 820.0
@export var rng_seed: int = 77
## Ambient clouds are organised into coherent weather banks rather than
## sampled independently across a square. Zero derives a sensible count.
@export_range(0, 12, 1) var weather_bank_count: int = 0
@export_range(0.0, 80.0, 1.0) var ambient_cluster_spacing: float = 18.0

## How tall a puff is relative to its own horizontal radius -- below 1.0,
## since puffs should read as wider than they are tall.
const PUFF_HEIGHT_FACTOR := 0.6

const DAY_COLOR := Color(1, 1, 1)
const NIGHT_COLOR := Color(0.22, 0.25, 0.38)

var _rng := RandomNumberGenerator.new()
var _material: StandardMaterial3D
var _ambient_exclusions: Array[Dictionary] = []
var _ambient_roots: Array[Node3D] = []
## Set by build_sky_course() once it actually runs -- see that function's
## own comment on _place_air_gem() for why this is the practical way to
## find "where the Air Gem cloud actually ended up" from another script.
var last_sky_course_landing: Vector3 = Vector3.ZERO
## Lazily created by build_stair_step() -- one shared BirdHelmGate holding
## every step of town_generator.gd's own hand-authored spiral climb, so
## get_support_height_at() (see its own comment on why it now recurses)
## finds them the exact same way it finds build_sky_course()'s own
## SkyParkourCourse puffs.
var _stairs_gate: BirdHelmGate


func _ready() -> void:
	add_to_group("cloud_scatters")
	_rng.seed = rng_seed
	_ensure_material()
	# Build now so later-authored cloud routes can clear their exact footprint.
	# Exclusions registered after this remain safe: they cull ambient roots only.
	_build_ambient_weather()


## Lets another script (town_generator.gd's own converted sky-stairs steps)
## use the exact same shared cloud material -- including day/night tinting
## staying in sync -- instead of a separately-built lookalike.
func get_material() -> StandardMaterial3D:
	_ensure_material()
	return _material


func _ensure_material() -> void:
	if _material != null:
		return
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(1, 1, 1)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED


## Reserve cylindrical world-space airspace for authored aerial content.
## Only ambient roots are removed; cloud stairs and platforms are untouched.
func add_ambient_exclusion(
	world_center: Vector3, horizontal_radius: float,
	min_world_y: float = -INF, max_world_y: float = INF
) -> void:
	_ambient_exclusions.append({
		"center": Vector2(world_center.x, world_center.z),
		"radius": maxf(horizontal_radius, 0.0),
		"min_y": min_world_y,
		"max_y": max_world_y,
	})
	_cull_ambient_in_exclusions()


func _build_ambient_weather() -> void:
	if cloud_count <= 0:
		return
	_rng.seed = rng_seed
	var bank_count := weather_bank_count
	if bank_count <= 0:
		bank_count = clampi(int(round(sqrt(float(cloud_count)) * 0.48)), 2, 8)
	var banks: Array[Dictionary] = []
	var total_weight := 0.0
	for i in range(bank_count):
		var angle := TAU * (float(i) / float(bank_count)) + _rng.randf_range(-0.65, 0.65)
		var distance := spread * _rng.randf_range(0.08, 0.68)
		var wind_angle := _rng.randf_range(0.0, TAU)
		var long_axis := spread * _rng.randf_range(0.22, 0.42)
		var short_axis := long_axis * _rng.randf_range(0.32, 0.68)
		var weight := long_axis * short_axis * _rng.randf_range(0.7, 1.35)
		banks.append({
			"center": Vector2(cos(angle), sin(angle)) * distance,
			"long_axis": long_axis,
			"short_axis": short_axis,
			"wind": Vector2(cos(wind_angle), sin(wind_angle)),
			"base_y": _rng.randf_range(altitude_min, altitude_max),
			"weight": weight,
		})
		total_weight += weight

	var accepted: Array[Vector2] = []
	var attempts := 0
	var max_attempts := maxi(cloud_count * 35, 200)
	while accepted.size() < cloud_count and attempts < max_attempts:
		attempts += 1
		var pick := _rng.randf() * total_weight
		var bank: Dictionary = banks.back()
		for candidate in banks:
			pick -= candidate["weight"] as float
			if pick <= 0.0:
				bank = candidate
				break
		var wind: Vector2 = bank["wind"]
		var across := Vector2(-wind.y, wind.x)
		# Summed-uniform samples approximate a normal distribution: a dense
		# core that naturally dissipates into wisps, without a hard ellipse edge.
		var along_n := _normal_sample()
		var across_n := _normal_sample()
		var local := wind * along_n * (bank["long_axis"] as float)
		local += across * across_n * (bank["short_axis"] as float)
		var flat: Vector2 = (bank["center"] as Vector2) + local
		if absf(flat.x) > spread or absf(flat.y) > spread:
			continue
		var normalized_radius := sqrt(pow(along_n, 2.0) + pow(across_n, 2.0))
		var edge_factor := clampf(1.0 - normalized_radius / 2.4, 0.18, 1.0)
		var y := clampf(
			(bank["base_y"] as float)
			+ along_n * (altitude_max - altitude_min) * 0.055
			+ _rng.randf_range(-2.0, 2.0),
			altitude_min, altitude_max
		)
		var local_pos := Vector3(flat.x, y, flat.y)
		if _is_ambient_excluded(to_global(local_pos)):
			continue
		var spacing := ambient_cluster_spacing * lerpf(0.72, 1.2, edge_factor)
		var too_close := false
		for prior in accepted:
			if prior.distance_squared_to(flat) < spacing * spacing:
				too_close = true
				break
		if too_close:
			continue
		accepted.append(flat)
		_place_cloud(local_pos, edge_factor, wind)
	_puffs_dirty = true


func _normal_sample() -> float:
	var value := 0.0
	for i in range(6):
		value += _rng.randf()
	return (value - 3.0) / 1.2


func _place_cloud(local_position: Vector3, edge_factor: float, wind: Vector2) -> void:
	var cloud := Node3D.new()
	cloud.name = "AmbientCloud"
	cloud.set_meta("ambient_cloud", true)
	cloud.position = local_position
	add_child(cloud)
	_ambient_roots.append(cloud)

	var puff_count := maxi(3, int(round(_rng.randf_range(4.0, 8.0) * lerpf(0.65, 1.0, edge_factor))))
	var across := Vector2(-wind.y, wind.x)
	for i in puff_count:
		var puff_radius := _rng.randf_range(3.0, 7.0) * lerpf(0.62, 1.0, edge_factor)
		var semi_axes := Vector3(puff_radius, puff_radius * PUFF_HEIGHT_FACTOR, puff_radius)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = SuperEgg.build_mesh(semi_axes, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		mesh_instance.material_override = _material
		mesh_instance.set_meta("cloud_semi_axes", semi_axes)
		_puffs_dirty = true
		var along_offset := _rng.randf_range(-9.5, 9.5)
		var across_offset := _rng.randf_range(-5.5, 5.5)
		var flat_offset := wind * along_offset + across * across_offset
		mesh_instance.position = Vector3(flat_offset.x, _rng.randf_range(-1.5, 1.5), flat_offset.y)
		cloud.add_child(mesh_instance)


func _is_ambient_excluded(world_position: Vector3) -> bool:
	for exclusion in _ambient_exclusions:
		if world_position.y < (exclusion["min_y"] as float) or world_position.y > (exclusion["max_y"] as float):
			continue
		var center: Vector2 = exclusion["center"]
		var flat := Vector2(world_position.x, world_position.z)
		if flat.distance_squared_to(center) <= pow(exclusion["radius"] as float, 2.0):
			return true
	return false


func _cull_ambient_in_exclusions() -> void:
	for cloud in _ambient_roots.duplicate():
		if not is_instance_valid(cloud):
			_ambient_roots.erase(cloud)
			continue
		if _is_ambient_excluded(cloud.global_position):
			_ambient_roots.erase(cloud)
			cloud.queue_free()
			_puffs_dirty = true


## Returns the highest visible puff top at this XZ position, provided that
## top is not above `max_surface_y`. Callers use that ceiling to make cloud
## support one-way: rising bodies pass through undersides, falling bodies
## approaching from above can settle on the top.
## Width of one bucket in the XZ index below. Comfortably wider than a single
## puff, so most puffs land in one or two cells.
const SUPPORT_CELL_SIZE := 40.0

## Puffs flattened out of the node tree, with the bounds enclosing them all:
## rebuilt whenever a puff is added, read on every support query.
var _puffs: Array[Dictionary] = []
var _puff_bounds := AABB()
var _puffs_dirty := true
## Puff indices bucketed by XZ cell, so a query inside the field looks at the
## handful of puffs overhead rather than every puff in the layer.
var _puff_cells: Dictionary = {}


## Marks the flattened puff list stale. Any code that adds a puff after this
## node is built (the sky course, the stair gates) calls it.
func invalidate_support_cache() -> void:
	_puffs_dirty = true


func _rebuild_support_cache() -> void:
	_puffs.clear()
	_puff_cells.clear()
	_collect_puffs(self)
	_puffs_dirty = false
	if _puffs.is_empty():
		_puff_bounds = AABB()
		return
	var first: Dictionary = _puffs[0]
	_puff_bounds = AABB((first["center"] as Vector3) - (first["axes"] as Vector3), (first["axes"] as Vector3) * 2.0)
	for index in _puffs.size():
		var puff: Dictionary = _puffs[index]
		var centre: Vector3 = puff["center"]
		var axes: Vector3 = puff["axes"]
		_puff_bounds = _puff_bounds.merge(AABB(centre - axes, axes * 2.0))
		# Every cell this puff reaches over, so a query reads one cell.
		var from := _cell_of(centre.x - axes.x, centre.z - axes.z)
		var to := _cell_of(centre.x + axes.x, centre.z + axes.z)
		for cell_x in range(from.x, to.x + 1):
			for cell_z in range(from.y, to.y + 1):
				var key := Vector2i(cell_x, cell_z)
				var bucket: PackedInt32Array = _puff_cells.get(key, PackedInt32Array())
				bucket.append(index)
				_puff_cells[key] = bucket


func _cell_of(world_x: float, world_z: float) -> Vector2i:
	return Vector2i(
		int(floor(world_x / SUPPORT_CELL_SIZE)), int(floor(world_z / SUPPORT_CELL_SIZE))
	)


func _collect_puffs(node: Node) -> void:
	for child in node.get_children():
		if child is MeshInstance3D and child.has_meta("cloud_semi_axes"):
			var puff := child as MeshInstance3D
			_puffs.append({
				"center": puff.global_position,
				"axes": puff.get_meta("cloud_semi_axes") as Vector3,
			})
		elif child.get_child_count() > 0:
			_collect_puffs(child)


## The standable cloud top at a point, or null.
##
## Every character and every free blorb asks this, every frame, and a cloud
## field sits at one place on a course kilometres long: the overwhelmingly
## common answer is "nowhere near". So the puffs are flattened once and
## enclosed in one box, and a query outside that box costs a single test
## instead of a walk of hundreds of nodes with two pow() calls apiece.
##
## Inside the box, the XZ index decides: a valley layer can be kilometres
## wide and a thousand puffs deep, and only the few directly overhead can
## possibly hold anybody up.
func get_support_height_at(world_x: float, world_z: float, max_surface_y: float = INF) -> Variant:
	if _puffs_dirty:
		_rebuild_support_cache()
	if _puffs.is_empty():
		return null
	if (
		world_x < _puff_bounds.position.x or world_x > _puff_bounds.end.x
		or world_z < _puff_bounds.position.z or world_z > _puff_bounds.end.z
		or max_surface_y < _puff_bounds.position.y
	):
		return null
	var bucket: PackedInt32Array = _puff_cells.get(_cell_of(world_x, world_z), PackedInt32Array())
	var best: Variant = null
	for index in bucket:
		var puff: Dictionary = _puffs[index]
		var center: Vector3 = puff["center"]
		var axes: Vector3 = puff["axes"]
		# Cheap rejections before the profile maths, which is the expensive
		# part: most puffs in range across one axis are out across another.
		if absf(world_x - center.x) > axes.x or absf(world_z - center.z) > axes.z:
			continue
		if center.y - axes.y > max_surface_y:
			continue
		var horizontal_profile := (
			pow(absf((world_x - center.x) / axes.x), SuperEgg.EPSILON_SOFT)
			+ pow(absf((world_z - center.z) / axes.z), SuperEgg.EPSILON_SOFT)
		)
		if horizontal_profile > 1.0:
			continue
		var top := center.y + axes.y * pow(1.0 - horizontal_profile, 1.0 / SuperEgg.EPSILON_SOFT)
		if top <= max_surface_y and (best == null or top > (best as float)):
			best = top
	return best


## Recurses through every descendant instead of assuming a fixed "cloud ->
## puff" nesting depth. Ambient puffs (_place_cloud()) really are only two
## levels down, but a gated climbing course -- build_sky_course()'s own
## SkyParkourCourse, and build_stair_step()'s own SkyStairsGate -- adds an
## extra BirdHelmGate wrapper level in between to hide/uncollide the whole
## course at once, which a fixed-depth walk would silently skip over
## entirely (found while chasing "the platform on the spiral staircase...
## doesn't seem to have the same physics as clouds").
func _support_height_in_children(node: Node, world_x: float, world_z: float, max_surface_y: float) -> Variant:
	var best: Variant = null
	for child in node.get_children():
		if child is MeshInstance3D and child.has_meta("cloud_semi_axes"):
			var puff := child as MeshInstance3D
			var axes := puff.get_meta("cloud_semi_axes") as Vector3
			var center := puff.global_position
			# Match SuperEgg.EPSILON_SOFT's rounded-square horizontal profile.
			# The old ellipse approximation excluded the puff's real side/corner
			# volume, which made a character fall through visibly rendered cloud.
			var horizontal_profile := pow(absf((world_x - center.x) / axes.x), SuperEgg.EPSILON_SOFT) + pow(absf((world_z - center.z) / axes.z), SuperEgg.EPSILON_SOFT)
			if horizontal_profile > 1.0:
				continue
			var top := center.y + axes.y * pow(1.0 - horizontal_profile, 1.0 / SuperEgg.EPSILON_SOFT)
			if top <= max_surface_y and (best == null or top > (best as float)):
				best = top
		elif child.get_child_count() > 0:
			var nested: Variant = _support_height_in_children(child, world_x, world_z, max_surface_y)
			if nested != null and (best == null or (nested as float) > (best as float)):
				best = nested
	return best


## Adds one gated "cloud step" cluster to town_generator.gd's own hand-
## authored spiral climb (see that file's own _build_sky_stairs()), using
## the exact same organic multi-puff technique as the ambient sky and the
## parkour course above it -- and, crucially, actually parented under this
## node (not the town's own scene root, where a separately-built StaticBody3D
## used to live) so get_support_height_at() finds it and gives it real
## one-way cloud physics instead of an ordinary solid box that blocks from
## every side. `world_pos` is where the step's own highest puff should land
## (see _build_course_cluster()'s own comment on solving for that after the
## fact), matching the per-step rise the caller's own spiral already walks.
## Frees any previously-built spiral steps first -- same reasoning as
## build_sky_course()'s own stale-"SkyParkourCourse" guard: town_generator.gd's
## own editor "rebuild_now" button re-runs _build_sky_stairs() without ever
## tearing this sibling CloudScatter node down first, so without this a
## repeat rebuild would leave every previous run's steps behind, doubled up.
func reset_stair_steps() -> void:
	if is_instance_valid(_stairs_gate):
		_stairs_gate.free()
	_stairs_gate = null


func build_stair_step(world_pos: Vector3, rng: RandomNumberGenerator) -> void:
	_ensure_material()
	if _stairs_gate == null or not is_instance_valid(_stairs_gate):
		_stairs_gate = BirdHelmGate.new()
		_stairs_gate.name = "SkyStairsGate"
		add_child(_stairs_gate)
	_build_course_cluster(_stairs_gate, world_pos.x, world_pos.z, world_pos.y, rng, 1.1, 1.6, 3, 5, 1.1)


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
	# Clear randomly generated puffs around the stair hand-off. They are
	# scenery elsewhere, but here a low cluster can physically cover the
	# authored route and make its first landing unreadable.
	for child in get_children():
		if child.name == "SkyParkourCourse" or not child is Node3D:
			continue
		if not child.has_meta("ambient_cloud"):
			continue
		var cloud := child as Node3D
		var horizontal := Vector2(cloud.global_position.x - start.x, cloud.global_position.z - start.z)
		# Ambient clusters can extend roughly 15m beyond their root once puff
		# radius and local jitter are combined. Clear by that real footprint,
		# not merely by the otherwise-invisible cluster origin.
		if horizontal.length() < 42.0 and cloud.global_position.y < start.y + 18.0:
			cloud.queue_free()
	# town_generator.gd's own "rebuild_now" editor button re-runs the whole
	# call chain that reaches here without this script's "Generated" subtree
	# equivalent to free the old one first -- without this, each in-editor
	# rebuild would leave a stale, still-standing (and still walkable) extra
	# course and gem behind rather than replacing them.
	var existing := get_node_or_null("SkyParkourCourse")
	if existing != null:
		existing.free()
	# A BirdHelmGate, not a plain Node3D -- per direct instruction, this
	# whole course (and the Air Gem on it) is now "the gateway to the Sky
	# Kingdom": invisible and untouchable until the player has the Bird
	# Helm equipped, the same "totally turned off" rule Sky Kingdom's own
	# islands use.
	var course := BirdHelmGate.new()
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
	# Recorded so other systems (sky_kingdom.gd) can position themselves
	# relative to the actual landing cloud instead of a hand-guessed
	# world-space constant -- this course's own final position depends on a
	# long chain of preceding RNG draws (building placement, etc.) that
	# isn't practical to reproduce by hand.
	last_sky_course_landing = Vector3(pos.x, top_y, pos.y)

	_build_safety_net(course, path_positions, start.y, rng)


## A few big catch clouds a bit below the whole climb, per direct
## instruction ("as a bit of a safety net if a player falls") -- generous
## radius and generous overlap with each other so a slip anywhere along the
## course's own horizontal path (see `path_positions`, every step center
## from the ground hand-off through the landing) still comes down onto one
## of them rather than dropping all the way back to the crate spiral or the
## ground below it.
func _build_safety_net(course: Node3D, path_positions: Array[Vector2], start_y: float, rng: RandomNumberGenerator) -> void:
	const NET_DROP := 18.0
	const NET_PUFF_MIN := 5.5
	const NET_PUFF_MAX := 7.0
	const NET_JITTER := 3.0
	var net_y := start_y - NET_DROP
	# Never put a catch cloud below the first point: that is exactly where the
	# crate staircase arrives, and its large puffs were visibly swallowing the
	# top of the stairs. Catch clouds begin under the aerial half of the route.
	var sample_indices: Array[int] = [path_positions.size() / 2, path_positions.size() - 1]
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
		_puffs_dirty = true
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
