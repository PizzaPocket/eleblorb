class_name CrouchMode
extends TraversalMode

## Ordinary locomotion layer shared by every controllable rig. Feet remain
## planted by solving each bent leg back to its original ankle position.
const SPEED_FACTOR := 0.4
const HEIGHT_FACTOR := 0.82
var active := false
var amount := 0.0
var phase := 0.0
var _collision: CollisionShape3D
var _standing_shape: Shape3D
var _crouch_shape: Shape3D
var _standing_transform := Transform3D.IDENTITY
var _translations: Dictionary = {}


func id() -> StringName:
	return &"crouch"


## Remove last frame's positional layer before the driver's ordinary poses.
func prepare(ctx: TraversalContext) -> void:
	for name: String in _translations:
		var joint := ctx.rig.joint(name)
		if joint != null:
			joint.position -= _translations[name] as Vector3
	_translations.clear()
	if _collision == null and ctx.standing_collision != null:
		_collision = ctx.standing_collision
		_standing_shape = _collision.shape.duplicate()
		_standing_transform = ctx.standing_collision_transform
		_crouch_shape = _standing_shape.duplicate()
		if _standing_shape is SphereShape3D:
			# A sphere cannot lose height while retaining its width. A short
			# cylinder preserves a round rig's footprint only while crouched.
			var cylinder := CylinderShape3D.new()
			cylinder.radius = (_standing_shape as SphereShape3D).radius
			_crouch_shape = cylinder


func can_stand(ctx: TraversalContext) -> bool:
	if _collision == null:
		return true
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _standing_shape
	query.transform = ctx.body.global_transform * _standing_transform
	# A small inset excludes resting floor contact without ignoring ceilings.
	query.margin = 0.001
	query.transform.origin += Vector3.UP * ctx.scaled(0.015)
	query.collision_mask = ctx.body.collision_mask
	query.exclude = [ctx.body.get_rid()]
	return ctx.body.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func step(ctx: TraversalContext, pressed: bool, allowed: bool) -> void:
	if pressed and allowed:
		active = not active
	if not allowed and leave(ctx):
		return
	# An attempted stand is postponed until there is room, including jumping.
	if not active and amount > 0.0 and not can_stand(ctx):
		active = true
	amount = move_toward(amount, 1.0 if active else 0.0, ctx.delta * 7.0)
	if _collision != null:
		_collision.shape = _crouch_shape if amount > 0.0 else _standing_shape
		var standing_height := 0.0
		var height := 0.0
		if _standing_shape is CapsuleShape3D:
			var standing := _standing_shape as CapsuleShape3D
			standing_height = standing.height
			height = lerpf(standing_height, maxf(standing.radius * 2.0, standing_height * HEIGHT_FACTOR), amount)
			(_crouch_shape as CapsuleShape3D).height = height
		elif _standing_shape is SphereShape3D:
			standing_height = (_standing_shape as SphereShape3D).radius * 2.0
			height = lerpf(standing_height, standing_height * HEIGHT_FACTOR, amount)
			(_crouch_shape as CylinderShape3D).height = height
		_collision.transform = _standing_transform
		_collision.position.y -= (standing_height - height) * 0.5


## A full-body traversal can unfold only where the standing shape fits.
func leave(ctx: TraversalContext) -> bool:
	if amount > 0.0 and not can_stand(ctx):
		return false
	active = false
	amount = 0.0
	if _collision != null:
		_collision.shape = _standing_shape
		_collision.transform = _standing_transform
	return true


func speed_factor() -> float:
	return lerpf(1.0, SPEED_FACTOR, amount)


func _translate(ctx: TraversalContext, name: String, offset: Vector3) -> void:
	var joint := ctx.rig.joint(name)
	if joint == null:
		return
	joint.position += offset
	_translations[name] = offset


func _rotate(ctx: TraversalContext, name: String, target: Vector3) -> void:
	if ctx.rig.articulates(name):
		var joint := ctx.rig.joint(name)
		joint.rotation = joint.rotation.lerp(target, amount)


func pose(ctx: TraversalContext) -> void:
	if amount <= 0.0:
		return
	phase += ctx.delta * Vector2(ctx.body.velocity.x, ctx.body.velocity.z).length() / maxf(ctx.scaled(0.28), 0.001)
	var stride := sin(phase) * 0.12
	var pelvis_shift := Vector3.ZERO
	var legs := 0
	for side in ["left", "right"]:
		var hip_name: String = "leg_" + side + "_hip"
		var knee_name: String = "leg_" + side + "_knee"
		var ankle_name: String = "leg_" + side + "_ankle"
		var hip := ctx.rig.joint(hip_name)
		var ankle := ctx.rig.joint(ankle_name)
		if hip == null or ankle == null:
			continue
		# Solve from the neutral leg every frame, rather than reusing last
		# frame's bent ankle (which would erase the pelvis drop on frame two).
		for name in [hip_name, knee_name, ankle_name]:
			if ctx.rig.articulates(name):
				ctx.rig.joint(name).rotation = ctx.rig.rest_rotation(name)
		var anchor := ankle.global_position
		var step := stride if side == "left" else -stride
		# Reuse the confirmed landing signs: hip negative, knee positive,
		# ankle negative. Their sum keeps the feet level in a deep squat.
		_rotate(ctx, hip_name, Vector3(-1.1 + step, 0.0, 0.0))
		_rotate(ctx, knee_name, Vector3(2.2 - step * 0.5, 0.0, 0.0))
		_rotate(ctx, ankle_name, Vector3(-1.1 - step * 0.5, 0.0, 0.0))
		var shift := hip.get_parent_node_3d().global_basis.inverse() * (anchor - ankle.global_position)
		_translate(ctx, hip_name, shift)
		pelvis_shift += shift
		legs += 1
	if legs > 0:
		pelvis_shift /= float(legs)
		_translate(ctx, "spine", pelvis_shift)
		# On rigs whose hips mesh belongs to the spine this would double dip.
		var hips := ctx.rig.joint("hips")
		var spine := ctx.rig.joint("spine")
		if hips != null and spine != null and not spine.is_ancestor_of(hips):
			_translate(ctx, "hips", pelvis_shift)
	_rotate(ctx, "spine", Vector3(0.35, 0.0, 0.0))
	_rotate(ctx, "head", Vector3(-0.35, 0.0, 0.0))
	for side in ["left", "right"]:
		if (side == "left" and ctx.left_arm_busy) or (side == "right" and ctx.right_arm_busy):
			continue
		# Confirmed airborne elbow/shoulder signs draw the hands forward;
		# zero shoulder spread brings the elbows close to the ribs.
		_rotate(ctx, "arm_" + side + "_shoulder", Vector3(-0.3, 0.0, 0.0))
		_rotate(ctx, "arm_" + side + "_elbow", Vector3(-1.15, 0.0, 0.0))
