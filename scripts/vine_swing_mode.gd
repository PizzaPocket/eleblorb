class_name VineSwingMode
extends TraversalMode

## Vine swinging, shared by every character (see
## docs/traversal_powers_architecture.md). A complete Plant suit commanded by
## the Leaf Hat throws a living vine at anything tall enough overhead and
## swings from it, hand over hand, without touching the ground.
##
## Jump is the whole control. Press it with the hat on and a support in reach
## and the vine takes hold; press it again and the hand opens, keeping every
## bit of the speed the arc had gathered. There is no separate toggle: a
## traversal the player enters by jumping at a tree needs no mode switch, and
## the failed throw is its own report (no vine appears).
##
## The lengths here are deliberately NOT scaled to the body. Every other power
## in this project scales, because it acts on the character's own limbs. This
## one acts on the world's trees: the same forty-metre emergent canopy has to
## be reachable by the human and by a monkey a quarter his height, so the
## reach, the rope and the cast impulse stay in world units and only the
## throwing hand's own height above the feet follows the rig.

## How far a throw carries, and how high above the thrower a support must
## stand before it counts as overhead at all.
const ANCHOR_RANGE := 62.0
const MIN_ANCHOR_RISE := 5.0
## The rope's working length. An anchor further away than MAX_ROPE is refused
## rather than clamped: clamping one would snap the body the difference in a
## single frame, which reads as a teleport into the tree.
const MIN_ROPE := 7.0
const MAX_ROPE := 40.0
## Steering authority while hanging, then the pickup a first throw grants so
## the swing visibly lifts into its first descending arc.
const STEER_ACCELERATION := 5.5
const CAST_LIFT := 7.0
const CAST_FORWARD := 8.5
## How long a fresh grip holds before the free hand may throw for the next
## support, and how long an opened hand stays open before it can catch again.
const HANDOFF_DELAY := 0.62
const RELATCH_DELAY := 0.28
## Above this rising speed the arc is still climbing, so the free hand waits.
const HANDOFF_RISE_LIMIT := 1.25
## How fast a thrown vine reaches its anchor, and a spent one returns.
const CAST_SPEED := 46.0
const RETRACT_SPEED := 58.0
const TERMINAL_FALL := 60.0
## The throwing hand's own height above the feet, on the human. This one
## length is the body's, so it follows the rig.
const REFERENCE_HAND_HEIGHT := 1.6
const VINE_TOP_RADIUS := 0.016
const VINE_BOTTOM_RADIUS := 0.022

var swinging := false
var anchor := Vector3.ZERO
var rope_length := 0.0
## Which hand carries the load. The other one is the one that throws next.
var left_hand := true
var handoff_timer := 0.0
var relatch_timer := 0.0
var _vine: MeshInstance3D
var _cast_fraction := 0.0
var _retiring: Array[Dictionary] = []


func id() -> StringName:
	return &"vine_swing"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null and ctx.suit.has_vine_swing_suit()


## The whole power for one frame. `aim` is the world direction the thrower is
## looking or travelling, horizontal. Returns true when the swing owned the
## frame, in which case the caller has already been moved and must not run its
## own locomotion.
func swing(ctx: TraversalContext, aim: Vector3, jump_pressed: bool) -> bool:
	_advance_retiring(ctx)
	if not is_available(ctx):
		if swinging:
			_open_hand()
		relatch_timer = 0.0
		return false
	relatch_timer = maxf(relatch_timer - ctx.delta, 0.0)
	if swinging:
		if jump_pressed:
			_open_hand()
			relatch_timer = RELATCH_DELAY
			return false
		_hang(ctx, aim)
		return true
	if jump_pressed and relatch_timer <= 0.0 and _throw(ctx, aim, true):
		_hang(ctx, aim)
		return true
	return false


## Lets go without ending the power: the next jump throws again.
func _open_hand() -> void:
	swinging = false
	_retire_vine()


func reset() -> void:
	swinging = false
	relatch_timer = 0.0
	handoff_timer = 0.0
	_retire_vine()


## Throws for a support. `with_pickup` marks a standing start, which gets the
## one modest impulse; a mid-arc hand-off keeps the trajectory it already has.
func _throw(ctx: TraversalContext, aim: Vector3, with_pickup: bool) -> bool:
	var found: Variant = find_anchor(ctx, aim)
	if found == null:
		# Nothing overhead took the throw. The vine simply does not appear,
		# which is the whole report: naming what it wanted would be telling
		# the player where to stand.
		return false
	anchor = found as Vector3
	rope_length = clampf(
		ctx.body.global_position.distance_to(anchor), MIN_ROPE, MAX_ROPE
	)
	handoff_timer = HANDOFF_DELAY
	if with_pickup:
		left_hand = true
		var forward := _horizontal(aim, ctx)
		ctx.body.velocity += forward * CAST_FORWARD
		ctx.body.velocity.y = maxf(ctx.body.velocity.y, CAST_LIFT)
	swinging = true
	_cast_fraction = 0.0
	return true


## A fan of rays looks for real collision high above the thrower. The rays
## along `aim` score first, so a throw goes where the swing is already going,
## while the side and rear rays let a grove or a lined street carry the
## traversal without demanding precise aim at every hand-off.
func find_anchor(ctx: TraversalContext, aim: Vector3) -> Variant:
	var space := ctx.body.get_world_3d().direct_space_state
	var origin: Vector3 = ctx.body.global_position + Vector3.UP * ctx.scaled(REFERENCE_HAND_HEIGHT)
	var forward := _horizontal(aim, ctx)
	var best: Variant = null
	var best_score := -INF
	for yaw_degrees: float in [0.0, -24.0, 24.0, -48.0, 48.0, -78.0, 78.0, 180.0]:
		var horizontal := forward.rotated(Vector3.UP, deg_to_rad(yaw_degrees))
		for rise: float in [0.92, 0.72, 0.55, 0.40]:
			var direction := (
				horizontal * sqrt(maxf(0.0, 1.0 - rise * rise)) + Vector3.UP * rise
			).normalized()
			var query := PhysicsRayQueryParameters3D.create(
				origin, origin + direction * ANCHOR_RANGE, 1
			)
			query.exclude = [ctx.body.get_rid()]
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				continue
			var point: Vector3 = hit["position"]
			if point.y - ctx.body.global_position.y < MIN_ANCHOR_RISE:
				continue
			var span := ctx.body.global_position.distance_to(point)
			if span > MAX_ROPE:
				continue
			var score := (point.y - ctx.body.global_position.y) + horizontal.dot(forward) * 9.0 - span * 0.08
			if score > best_score:
				best_score = score
				best = point
	return best


## One frame on the rope: gravity and steering, then the rope's own
## constraint. The rope cannot stretch, so the component of velocity trying to
## lengthen it is removed while inward velocity is kept, which is what lets a
## fresh throw climb before it falls. Near the top of an arc the free hand
## throws for the next support; failing costs nothing, since the vine already
## held is still load-bearing.
func _hang(ctx: TraversalContext, aim: Vector3) -> void:
	var body := ctx.body
	handoff_timer = maxf(handoff_timer - ctx.delta, 0.0)
	body.velocity += ctx.direction * STEER_ACCELERATION * ctx.delta
	body.velocity.y = HumanoidLocomotion.apply_gravity(
		body.velocity.y, ctx.delta, ctx.profile, TERMINAL_FALL
	)
	var radial := body.global_position - anchor
	if radial.length_squared() > 0.001:
		var outward := radial.normalized()
		var stretching := body.velocity.dot(outward)
		if stretching > 0.0:
			body.velocity -= outward * stretching
	body.move_and_slide()
	radial = body.global_position - anchor
	if radial.length() > rope_length:
		body.global_position = anchor + radial.normalized() * rope_length
	if handoff_timer <= 0.0 and body.velocity.y <= HANDOFF_RISE_LIMIT:
		var held := anchor
		var hand_was := left_hand
		if _throw(ctx, _swing_aim(ctx, aim), false) and anchor.distance_to(held) > 2.0:
			_retire_vine_from(held, hand_was)
			left_hand = not left_hand
		else:
			anchor = held
	_draw_vine(ctx)


## Where the next throw looks: along the travel, which during a swing is the
## direction the arc is actually carrying the body, falling back to the
## thrower's own aim when barely moving.
func _swing_aim(ctx: TraversalContext, aim: Vector3) -> Vector3:
	var travel := ctx.body.velocity
	travel.y = 0.0
	if travel.length_squared() > 1.0:
		return travel.normalized()
	return _horizontal(aim, ctx)


func _horizontal(aim: Vector3, ctx: TraversalContext) -> Vector3:
	var flat := aim
	flat.y = 0.0
	if flat.length_squared() > 0.0001:
		return flat.normalized()
	if ctx.visuals != null:
		flat = -ctx.visuals.global_transform.basis.z
		flat.y = 0.0
		if flat.length_squared() > 0.0001:
			return flat.normalized()
	return Vector3.FORWARD


## The holding arm reaches overhead along the rope. A pendulum always hangs
## below its anchor, so straight up is where the rope is, on any rig.
func pose(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	if rig == null or not swinging:
		return
	var prefix := "arm_left" if left_hand else "arm_right"
	if left_hand and ctx.left_arm_busy:
		return
	if not left_hand and ctx.right_arm_busy:
		return
	var t := minf(12.0 * ctx.delta, 1.0)
	var shoulder := rig.joint("%s_shoulder" % prefix)
	if shoulder != null:
		shoulder.rotation.x = lerp_angle(shoulder.rotation.x, -PI * 0.52, t)
		shoulder.rotation.z = lerp_angle(shoulder.rotation.z, 0.0, t)
	var elbow := rig.joint("%s_elbow" % prefix)
	if elbow != null:
		elbow.rotation.x = lerp_angle(elbow.rotation.x, 0.0, t)


## The vine itself, growing from the carrying hand to its anchor as it is
## thrown. Parented to the scene rather than the body, because it connects two
## points in the world and must not inherit the swinging body's own motion.
func _draw_vine(ctx: TraversalContext) -> void:
	var scene := ctx.body.get_tree().current_scene
	if scene == null:
		return
	if not is_instance_valid(_vine):
		_vine = MeshInstance3D.new()
		_vine.name = "SwingVine"
		var material := StandardMaterial3D.new()
		material.albedo_color = LeafHat.VINE_COLOR
		material.roughness = 0.9
		_vine.material_override = material
		scene.add_child(_vine)
	var start := _hand_point(ctx, left_hand)
	var full := start.distance_to(anchor)
	_cast_fraction = move_toward(
		_cast_fraction, 1.0, CAST_SPEED * ctx.delta / maxf(full, 0.001)
	)
	_segment(_vine, start, start.lerp(anchor, _cast_fraction))


## Where a vine meets its hand. Xiao Hou Zi has no separate fingertip, so the
## wrist is asked next and the body itself last, rather than assuming a joint
## every rig happens not to have.
func _hand_point(ctx: TraversalContext, use_left: bool) -> Vector3:
	var rig := ctx.rig
	if rig != null:
		var names := (
			["fingertip_left", "wrist_left"] if use_left
			else ["fingertip_right", "wrist_right"]
		)
		for joint_name: String in names:
			var hand := rig.joint(joint_name)
			if hand != null:
				return hand.global_position
	return ctx.body.global_position + Vector3.UP * ctx.scaled(REFERENCE_HAND_HEIGHT)


func _segment(mesh_instance: MeshInstance3D, start: Vector3, finish: Vector3) -> void:
	var length := start.distance_to(finish)
	mesh_instance.visible = length > 0.002
	if not mesh_instance.visible:
		return
	var cylinder := mesh_instance.mesh as CylinderMesh
	if cylinder == null:
		cylinder = CylinderMesh.new()
		cylinder.top_radius = VINE_TOP_RADIUS
		cylinder.bottom_radius = VINE_BOTTOM_RADIUS
		cylinder.radial_segments = 7
		mesh_instance.mesh = cylinder
	cylinder.height = length
	mesh_instance.global_position = (start + finish) * 0.5
	mesh_instance.global_basis = Basis(Quaternion(Vector3.UP, (finish - start).normalized()))


## Hands the current vine to the retracting set, whose tip travels back to the
## hand that threw it while the other hand's throw is already under way.
func _retire_vine() -> void:
	_retire_vine_from(anchor, left_hand)


func _retire_vine_from(from_anchor: Vector3, from_left_hand: bool) -> void:
	if not is_instance_valid(_vine):
		return
	_retiring.append({
		"mesh": _vine,
		"anchor": from_anchor,
		"left_hand": from_left_hand,
		"fraction": _cast_fraction,
	})
	_vine = null
	_cast_fraction = 0.0


func _advance_retiring(ctx: TraversalContext) -> void:
	for index in range(_retiring.size() - 1, -1, -1):
		var entry: Dictionary = _retiring[index]
		var mesh := entry["mesh"] as MeshInstance3D
		if not is_instance_valid(mesh):
			_retiring.remove_at(index)
			continue
		var hand := _hand_point(ctx, bool(entry["left_hand"]))
		var from_anchor: Vector3 = entry["anchor"]
		var full := hand.distance_to(from_anchor)
		var fraction := float(entry["fraction"]) - RETRACT_SPEED * ctx.delta / maxf(full, 0.001)
		if fraction <= 0.0:
			mesh.queue_free()
			_retiring.remove_at(index)
			continue
		entry["fraction"] = fraction
		_retiring[index] = entry
		_segment(mesh, hand, hand.lerp(from_anchor, fraction))
