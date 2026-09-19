class_name CrystalTrack
extends Node3D

## The magic ice track Crystal Skates lay ahead of their wearer (see
## Player's crystal riding): a ribbon of short, solid ice planks laid along a
## path that the skater steers in three dimensions, riding along it like a
## rail. The skater's own position lives here as a distance along the path.
##
## Planks are laid PLANK_LENGTH apart and kept LEAD metres ahead of the
## skater. Each melts LIFETIME seconds after it was laid, shrinking away over
## MELT_TIME, from the back of the track forward, but never the planks within
## KEEP_BEHIND of the skater or anywhere ahead, so a skater who stops stays
## standing on the ice. Planks are pooled and reused, never more than
## MAX_PLANKS at once, so a long ride costs no more than a short one.
##
## The path point is the top of the ice, where the skater's feet go. Planks
## are solid to everyone (layer 1), so others can stand on them too, and they
## are skateable ice (group "power_platforms", like IceCrag).

const PLANK_LENGTH := 0.8
const PLANK_HALF_WIDTH := 0.75
const PLANK_HALF_THICKNESS := 0.1
const LEAD := 5.5
const LIFETIME := 3.0
const MELT_TIME := 0.5
const KEEP_BEHIND := 2.0
const MAX_PLANKS := 90
## Never lay ice below the ground: a plank that would sink rides up onto it.
const GROUND_CLEARANCE := 0.05
const CRYSTAL_TINT := Color(0.8, 0.95, 1.0)

## Path points (top of the ice) and the time each was laid. Plank i spans
## points[i] to points[i + 1].
var _points: Array[Vector3] = []
var _laid_at: Array[float] = []
var _planks: Array[StaticBody3D] = []
var _pool: Array[StaticBody3D] = []
## The skater: on plank _rider_index, _rider_t of the way along it.
var _rider_index := 0
var _rider_t := 0.0
var _clock := 0.0
var _material: StandardMaterial3D
var _blocked := false
## While a skater rides this track its footing is spared from melting. Once
## they leave it, it melts away entirely and frees itself.
var riding := false


func _init() -> void:
	name = "CrystalTrack"
	top_level = true


## Starts a fresh track under the skater's feet at `feet`.
func begin(feet: Vector3) -> void:
	for plank in _planks:
		_release(plank)
	_planks.clear()
	_points = [feet]
	_laid_at = [_clock]
	_rider_index = 0
	_rider_t = 0.0
	_blocked = false


func _physics_process(delta: float) -> void:
	melt(delta, riding)


func is_empty() -> bool:
	return _planks.is_empty()


## Where the skater's feet are on the ice, and the track's direction there.
func rider_point() -> Vector3:
	if _planks.is_empty():
		return _points[0]
	return _points[_rider_index].lerp(_points[_rider_index + 1], _rider_t)


func rider_tangent() -> Vector3:
	if _planks.is_empty():
		return Vector3.ZERO
	return (_points[_rider_index + 1] - _points[_rider_index]).normalized()


## The laid track's leading end, and how far ahead of the skater it reaches.
func lead_point() -> Vector3:
	return _points[_points.size() - 1]


func lead_direction() -> Vector3:
	if _points.size() < 2:
		return Vector3.ZERO
	return (_points[_points.size() - 1] - _points[_points.size() - 2]).normalized()


func distance_ahead() -> float:
	if _planks.is_empty():
		return 0.0
	var ahead := (1.0 - _rider_t) * _points[_rider_index].distance_to(_points[_rider_index + 1])
	for index in range(_rider_index + 1, _planks.size()):
		ahead += _points[index].distance_to(_points[index + 1])
	return ahead


## True once the track met an obstacle it could not be laid through: it ends
## there until the skater turns away (clear_block()).
func is_blocked() -> bool:
	return _blocked


func clear_block() -> void:
	_blocked = false


## Lays planks from the leading end along `heading` until the track reaches
## LEAD ahead of the skater, riding up over the ground and stopping at any
## solid obstacle (`space` ray, ignoring `exclude`).
func extend(heading: Vector3, terrain: Node, space: PhysicsDirectSpaceState3D, exclude: Array[RID]) -> void:
	var guard := 0
	while not _blocked and distance_ahead() < LEAD and guard < 16:
		guard += 1
		var from := lead_point()
		var to := from + heading * PLANK_LENGTH
		if terrain != null and terrain.has_method("get_mesh_height"):
			var ground: float = terrain.get_mesh_height(to.x, to.z)
			to.y = maxf(to.y, ground + GROUND_CLEARANCE)
		# Clearance for a standing body, not just the thin plank.
		var probe := PhysicsRayQueryParameters3D.create(from + Vector3.UP * 0.9, to + Vector3.UP * 0.9, 1)
		probe.exclude = exclude + _plank_rids()
		if not space.intersect_ray(probe).is_empty():
			_blocked = true
			return
		_lay(from, to)


## Moves the skater `distance` along the track. Returns the distance it could
## not travel because the track ran out.
func advance(distance: float) -> float:
	var remaining := distance
	while remaining > 0.0 and not _planks.is_empty():
		var length := _points[_rider_index].distance_to(_points[_rider_index + 1])
		var left_on_plank := (1.0 - _rider_t) * length
		if remaining < left_on_plank:
			_rider_t += remaining / maxf(length, 0.0001)
			return 0.0
		remaining -= left_on_plank
		if _rider_index + 1 >= _planks.size():
			_rider_t = 1.0
			return remaining
		_rider_index += 1
		_rider_t = 0.0
	return remaining


## Drops every plank ahead of the skater, so a stopped skater can set off in
## a new direction from where they stand.
func truncate_ahead() -> void:
	var here := rider_point()
	while _planks.size() > _rider_index + 1:
		_release(_planks.pop_back())
		_points.pop_back()
		_laid_at.pop_back()
	# The skater's own plank now ends where they stand.
	if not _planks.is_empty():
		_points[_points.size() - 1] = here
		_rider_t = 1.0
		_restretch(_planks.size() - 1)
	_blocked = false


## Melts the track: planks past LIFETIME shrink away over MELT_TIME from the
## back forward, sparing the skater's footing (when `riding`).
func melt(delta: float, riding: bool) -> void:
	_clock += delta
	# Oldest first, and never more than MAX_PLANKS.
	while _planks.size() > MAX_PLANKS and (not riding or _rider_index > 0):
		_drop_back()
	var index := 0
	while index < _planks.size():
		var age := _clock - _laid_at[index + 1]
		var protected := riding and (index >= _rider_index or _distance_behind(index) < KEEP_BEHIND)
		var plank := _planks[index]
		if protected or age < LIFETIME:
			plank.scale = Vector3.ONE
			index += 1
			continue
		var shrink := 1.0 - clampf((age - LIFETIME) / MELT_TIME, 0.0, 1.0)
		if shrink <= 0.0 and index == 0:
			_drop_back()
			continue
		plank.scale = Vector3(maxf(shrink, 0.01), maxf(shrink, 0.01), 1.0)
		index += 1
	if not riding and _planks.is_empty():
		queue_free()


func _distance_behind(index: int) -> float:
	if _planks.is_empty():
		return 0.0
	var behind := _rider_t * _points[_rider_index].distance_to(_points[_rider_index + 1])
	for plank_index in range(index + 1, _rider_index):
		behind += _points[plank_index].distance_to(_points[plank_index + 1])
	return behind if index < _rider_index else 0.0


func _drop_back() -> void:
	_release(_planks.pop_front())
	_points.pop_front()
	_laid_at.pop_front()
	_rider_index = maxi(_rider_index - 1, 0)


func _lay(from: Vector3, to: Vector3) -> void:
	_points.append(to)
	_laid_at.append(_clock)
	var plank := _take()
	_planks.append(plank)
	_restretch(_planks.size() - 1)


## Fits plank `index` between its two path points: its top face on the path,
## its length along it, its width level across it.
func _restretch(index: int) -> void:
	var plank := _planks[index]
	var from := _points[index]
	var to := _points[index + 1]
	var along := to - from
	var length := along.length()
	if length < 0.001:
		along = Vector3.FORWARD
		length = 0.001
	var forward := along / length
	var across := forward.cross(Vector3.UP)
	across = across.normalized() if across.length_squared() > 0.001 else Vector3.RIGHT
	var up := across.cross(forward).normalized()
	plank.global_transform = Transform3D(Basis(across, up, forward), (from + to) * 0.5 - up * PLANK_HALF_THICKNESS)
	var half_length := length * 0.5 + 0.06
	var visual := plank.get_child(0) as MeshInstance3D
	visual.mesh = SuperEgg.build_mesh(Vector3(PLANK_HALF_WIDTH, PLANK_HALF_THICKNESS, half_length), 3.4, 3.4)
	var box := (plank.get_child(1) as CollisionShape3D).shape as BoxShape3D
	box.size = Vector3(PLANK_HALF_WIDTH, PLANK_HALF_THICKNESS, half_length) * 2.0


func _plank_rids() -> Array[RID]:
	var rids: Array[RID] = []
	for plank in _planks:
		rids.append(plank.get_rid())
	return rids


func _take() -> StaticBody3D:
	var plank: StaticBody3D
	if not _pool.is_empty():
		plank = _pool.pop_back()
		plank.visible = true
		(plank.get_child(1) as CollisionShape3D).disabled = false
		plank.scale = Vector3.ONE
		return plank
	plank = StaticBody3D.new()
	plank.collision_layer = 1
	plank.collision_mask = 0
	plank.add_to_group("power_platforms")
	plank.add_to_group("crystal_track")
	var visual := MeshInstance3D.new()
	visual.name = "Ice"
	if _material == null:
		_material = crystal_material()
	visual.material_override = _material
	plank.add_child(visual)
	var collider := CollisionShape3D.new()
	collider.shape = BoxShape3D.new()
	plank.add_child(collider)
	# Solid ice meant to be stood on: the visual and its box are paired.
	visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	add_child(plank)
	return plank


func _release(plank: StaticBody3D) -> void:
	plank.visible = false
	(plank.get_child(1) as CollisionShape3D).disabled = true
	_pool.append(plank)


## Crystal ice: the Ice blorbs' raised ice (IceCrag), clearer and faintly
## glowing, the look of the skates and everything they lay.
static func crystal_material() -> StandardMaterial3D:
	var material := IceCrag.build_ice_material()
	material.albedo_color = Color(CRYSTAL_TINT, 0.78)
	material.roughness = 0.04
	material.emission_enabled = true
	material.emission = CRYSTAL_TINT
	material.emission_energy_multiplier = 0.25
	return material


## A loose pair of Crystal Skates for the shop/inventory: two slim crystal
## runners.
static func build_skate_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "CrystalSkates"
	var material := crystal_material()
	for side in [-1.0, 1.0]:
		var runner := MeshInstance3D.new()
		runner.mesh = SuperEgg.build_mesh(Vector3(0.025, 0.05, 0.2) * item_scale, 4.8, 4.8)
		runner.material_override = material
		runner.position = Vector3(side * 0.08 * item_scale, 0.05 * item_scale, 0.0)
		root.add_child(runner)
	return root
