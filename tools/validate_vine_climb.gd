extends Node3D

## Small real-physics regression, independent of settlement construction.
var failures: Array[String] = []


func _ready() -> void:
	await get_tree().physics_frame
	for profile in [PlayableCharacterProfile.human(), PlayableCharacterProfile.xiao_hou_zi()]:
		await _check_climb(profile)
	await _check_targeting()
	for failure in failures: push_error(failure)
	print("Vine camera climb: %d failures" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)


func _check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)


func _body(at: Vector3, height: float = 1.8) -> CharacterBody3D:
	var body := CharacterBody3D.new()
	body.collision_layer = 2
	body.collision_mask = 1
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = minf(0.4, height * 0.22)
	shape.height = height
	collider.shape = shape
	collider.position.y = height * 0.5
	body.add_child(collider)
	add_child(body)
	body.position = at
	return body


func _context(body: CharacterBody3D, profile: PlayableCharacterProfile) -> TraversalContext:
	var ctx := TraversalContext.new(body, profile, null, null, self)
	ctx.delta = 1.0 / 60.0
	return ctx


func get_mesh_height(_x: float, _z: float) -> float:
	return 0.0


func _check_climb(profile: PlayableCharacterProfile) -> void:
	var body := _body(Vector3(0, 35, 0), profile.standing_height)
	var ctx := _context(body, profile)
	var mode := VineSwingMode.new()
	mode.anchor = Vector3(0, 65, 0)
	mode.rope_length = 30.0
	mode.swinging = true
	_check(is_zero_approx(VineAnchorSearch.climb_intent(ctx)), "level aim requests climb")
	ctx.aim_basis = Basis(Vector3.RIGHT, deg_to_rad(10.0))
	_check(is_zero_approx(VineAnchorSearch.climb_intent(ctx)), "small look exceeds dead zone")
	ctx.aim_basis = Basis.IDENTITY
	for frame in 60:
		await get_tree().physics_frame
		mode._hang(ctx, Vector3.FORWARD)
	_check(absf(body.position.y - 35.0) < 0.05 and is_equal_approx(mode.rope_length, 30.0), profile.id + ": level swing changed")
	ctx.aim_basis = Basis(Vector3.RIGHT, deg_to_rad(65.0))
	for frame in 120:
		await get_tree().physics_frame
		mode._hang(ctx, Vector3.FORWARD)
	var climbed := body.position.y
	_check(climbed > 40.5 and climbed < 41.5, profile.id + ": failed to climb beyond baseline: " + str(climbed))
	ctx.aim_basis = Basis.IDENTITY
	for frame in 60:
		await get_tree().physics_frame
		mode._hang(ctx, Vector3.FORWARD)
	_check(body.position.y < climbed + 0.2, profile.id + ": kept reeling at level aim")
	# A ceiling must block ascent without tightening the rope through it.
	var ceiling := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(6, 0.4, 6)
	collider.shape = box; ceiling.add_child(collider); add_child(ceiling)
	ceiling.position = Vector3(0, body.position.y + profile.standing_height + 0.4, 0)
	var ceiling_bottom := ceiling.position.y - 0.2
	ctx.aim_basis = Basis(Vector3.RIGHT, deg_to_rad(65.0))
	for frame in 120:
		await get_tree().physics_frame
		mode._hang(ctx, Vector3.FORWARD)
	_check(body.position.y + profile.standing_height <= ceiling_bottom + 0.01, profile.id + ": pulled through ceiling")
	_check(mode.rope_length >= mode.anchor.distance_to(body.position) - 0.01, profile.id + ": rope tightened past blocked body")
	# The 12 m working minimum stays in place.
	ceiling.free()
	body.position = Vector3(0, 53, 0); body.velocity = Vector3.ZERO
	mode.rope_length = VineSwingMode.MIN_ROPE
	_check(not mode._pull_for_climb(ctx, body.position - mode.anchor), profile.id + ": reeled inside minimum")
	print(profile.id, " climbed ", climbed - 35.0, " m above startup baseline; ceiling/minimum checks complete")
	mode.reset(); body.queue_free()
	await get_tree().physics_frame


func _check_targeting() -> void:
	var body := _body(Vector3(100, 35, 0))
	var ctx := _context(body, PlayableCharacterProfile.human())
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(40, 80, 0.2)
	collider.shape = box; wall.add_child(collider); add_child(wall)
	wall.position = Vector3(100, 65, -8)
	await get_tree().physics_frame
	var mode := VineSwingMode.new()
	var level := mode.find_anchor(ctx, Vector3.FORWARD)
	ctx.aim_basis = Basis(Vector3.RIGHT, deg_to_rad(65.0))
	var up := mode.find_anchor(ctx, Vector3.FORWARD)
	_check(level != null and up != null, "targeting lost available wall")
	if level != null and up != null:
		_check(up.point.y > level.point.y + 10.0, "upward camera did not find a higher support")
		_check(up.point.distance_to(body.position) <= VineSwingMode.MAX_ROPE, "target exceeds rope range")
	# A failed handover keeps the original grip; no free-air climb target.
	mode.anchor = Vector3(100, 65, 0); mode.rope_length = 30.0; mode.swinging = true
	mode.anchor_rid = wall.get_rid()
	_check(not mode._catch_next(ctx, Vector3.FORWARD) and mode.anchor == Vector3(100, 65, 0) and mode.swinging, "failed handover dropped current grip")
	wall.free(); body.queue_free(); mode.reset()
