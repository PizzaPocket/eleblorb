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
const ANCHOR_RANGE := 78.0
const MIN_ANCHOR_RISE := 5.0
## The rope's working length. An anchor further away than MAX_ROPE is refused
## rather than clamped: clamping one would snap the body the difference in a
## single frame, which reads as a teleport into the tree.
const MIN_ROPE := 7.0
const MAX_ROPE := 52.0
## Steering authority while hanging, then the pickup a first throw grants so
## the swing visibly lifts into its first descending arc.
const STEER_ACCELERATION := 5.5
const CAST_LIFT := 7.0
const CAST_FORWARD := 8.5
## The shortest a grip can last, so one apex cannot fire two throws, and how
## long an opened hand stays open before it can catch again.
const MIN_GRIP := 0.25
const RELATCH_DELAY := 0.28
## The free hand throws at the apex of an arc and nowhere else. The apex is an
## event, not a threshold: the body has to have been climbing and then stop
## climbing. Testing "vertical speed below a small number" instead, as this did
## at first, is true through the whole descending half of every arc, so the
## hands alternated on the grip timer and read as a metronome.
const APEX_RISE_MIN := 0.6
## How fast a thrown vine reaches its anchor, and a spent one returns.
const CAST_SPEED := 46.0
const RETRACT_SPEED := 58.0
const TERMINAL_FALL := 60.0
## The throwing hand's own height above the feet, on the human. This one
## length is the body's, so it follows the rig.
const REFERENCE_HAND_HEIGHT := 1.6
const VINE_TOP_RADIUS := 0.016
const VINE_BOTTOM_RADIUS := 0.022

## The holding arm follows the rope instead of holding one fixed angle, and it
## is aimed by building the shoulder's own basis rather than by commanding an
## Euler angle. That is deliberate: this rig's shoulder pivot does not turn by
## the angle it is given (ARM_POWER_POSE_ANGLE in player.gd records 150 degrees
## commanded reading as a true 90, measured twice, with no root cause found),
## so any angle computed here would inherit that unexplained scale. Aiming the
## segment's own axis at the anchor is exact whatever the pivot does with it.
##
## The arm extends along its own local -Y, the convention every segment in this
## rig uses (see procedural_figure.gd's own joint offsets, all negative down
## the chain).
##
## A shoulder cannot carry the arm past straight up, so the aim is clamped
## there: the rope direction is pushed out of the rear half-space rather than
## allowed to fold the joint backwards.
const SHOULDER_BLEND := 14.0
## How far the wrist may turn the fingers away from the forearm's own line. A
## real wrist manages something close to this before the forearm has to roll.
const WRIST_LIMIT := deg_to_rad(78.0)
## The opposite leg to the holding hand leads the swing, the same leg the arm
## would answer in a stride. Hip FORWARD is negative rotation.x and the knee's
## own bend is POSITIVE: both taken from _apply_airborne_pose() in player.gd,
## which applies -(hip_bend) and +knee_bend after that shoulder/hip sign was
## found backwards once by direct observation. Reused, not re-derived.
const SWING_HIP_LEAD := deg_to_rad(52.0)
const SWING_HIP_TRAIL := deg_to_rad(16.0)
## The knees keep the airborne pose's own fold (JUMP_KNEE_BEND is 130 degrees);
## only the hips are the swing's own.
const SWING_KNEE_BEND := deg_to_rad(130.0)
const LEG_BLEND := 9.0
## How quickly the joints this mode wrote hand themselves back afterwards.
const RELEASE_BLEND := 11.0

var swinging := false
var anchor := Vector3.ZERO
var rope_length := 0.0
## Which hand carries the load. The other one is the one that throws next.
var left_hand := true
var grip_timer := 0.0
var relatch_timer := 0.0
## Whether this grip has climbed yet, which is what makes the next stop
## climbing an apex rather than just a slow moment.
var _climbed := false
## Every joint this mode wrote, with the rotation it found there, so leaving the
## swing puts back what the ordinary animation does not itself rewrite (it
## drives rotation.x each frame and leaves y and z alone, which is exactly
## where an aimed basis leaves its residue).
var _borrowed: Dictionary = {}
var _releasing := false
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
		_hand_back(ctx)
		return false
	relatch_timer = maxf(relatch_timer - ctx.delta, 0.0)
	if swinging:
		if jump_pressed:
			_open_hand()
			relatch_timer = RELATCH_DELAY
			return false
		_hang(ctx, aim)
		return true
	_hand_back(ctx)
	if jump_pressed and relatch_timer <= 0.0 and _throw(ctx, aim, true):
		_hang(ctx, aim)
		return true
	return false


## Lets go without ending the power: the next jump throws again. A vine let go
## of on purpose is gone at once rather than retracting on its own time, which
## left a line trailing back to a tree the swinger had already left.
func _open_hand() -> void:
	swinging = false
	if is_instance_valid(_vine):
		_vine.queue_free()
	_vine = null
	_cast_fraction = 0.0
	_releasing = true


func reset() -> void:
	swinging = false
	relatch_timer = 0.0
	grip_timer = 0.0
	_open_hand()


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
	grip_timer = MIN_GRIP
	_climbed = false
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
	grip_timer = maxf(grip_timer - ctx.delta, 0.0)
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
	if body.velocity.y > APEX_RISE_MIN:
		_climbed = true
	var at_apex := _climbed and body.velocity.y <= 0.0
	if at_apex and grip_timer <= 0.0:
		var held := anchor
		var hand_was := left_hand
		if _throw(ctx, _swing_aim(ctx, aim), false) and anchor.distance_to(held) > 2.0:
			_retire_vine_from(held, hand_was)
			left_hand = not left_hand
		else:
			anchor = held
			_climbed = false
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
		# The rendered body faces its own +Z in this project, not -Z as a
		# Camera3D does (see the 180 degree turn player.gd applies for exactly
		# this reason). Taking -Z here aimed every fallback throw backwards.
		flat = ctx.visuals.global_transform.basis.z
		flat.y = 0.0
		if flat.length_squared() > 0.0001:
			return flat.normalized()
	return Vector3.FORWARD


## The holding arm follows the rope, the wrist turns the fingers back down over
## it, and the opposite leg leads the swing.
func pose(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	if rig == null or not swinging or ctx.visuals == null:
		return
	var busy := ctx.left_arm_busy if left_hand else ctx.right_arm_busy
	if not busy:
		_pose_arm(ctx)
	_pose_legs(ctx)


## Aims the shoulder so the arm lies along the rope, then the wrist so the
## fingers point back down toward the toes with the palm turned onto the vine.
func _pose_arm(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	var prefix := "arm_left" if left_hand else "arm_right"
	var shoulder := rig.joint("%s_shoulder" % prefix)
	if shoulder == null:
		return
	var t := minf(SHOULDER_BLEND * ctx.delta, 1.0)
	var up_the_rope := anchor - shoulder.global_position
	if up_the_rope.length_squared() < 0.0001:
		return
	up_the_rope = _within_shoulder_reach(ctx, up_the_rope.normalized())
	# The arm runs along its own local -Y, so -Y has to end up along the rope.
	_borrow(shoulder)
	_aim_segment(shoulder, up_the_rope, ctx.visuals.global_transform.basis.x, t)
	var elbow := rig.joint("%s_elbow" % prefix)
	if elbow != null:
		# Straight: the arm is hanging from the vine, not pulling on it.
		_borrow(elbow)
		elbow.rotation.x = lerp_angle(elbow.rotation.x, 0.0, t)
		elbow.rotation.y = lerp_angle(elbow.rotation.y, 0.0, t)
		elbow.rotation.z = lerp_angle(elbow.rotation.z, 0.0, t)
	var hand := rig.joint("hand_left" if left_hand else "hand_right")
	if hand == null:
		hand = rig.joint("wrist_left" if left_hand else "wrist_right")
	if hand == null or not rig.has_real("hand_left" if left_hand else "hand_right"):
		return
	# Fingers point at the toes, not up at the sky: a hand hanging from a vine
	# curls back down over it. The wrist can only turn so far off the forearm's
	# own line, so the reachable direction closest to straight down is used, and
	# the rest of the turn is what reads as the forearm rolling outward.
	var down: Vector3 = -ctx.visuals.global_transform.basis.y
	var fingers := _within_wrist_reach(down, -up_the_rope)
	# Palm onto the vine: with the fingers curled down, the palm faces back up
	# the rope. Palm is the hand's own local +Z (confirmed; see the PalmAttach
	# comment in procedural_figure.gd).
	var palm := up_the_rope - fingers * up_the_rope.dot(fingers)
	if palm.length_squared() < 0.0001:
		palm = ctx.visuals.global_transform.basis.z
	_borrow(hand)
	_aim_hand(hand, fingers, palm.normalized(), t)


## The rope direction, kept out of the half-space behind the body so the
## shoulder is never asked to carry the arm past straight up.
func _within_shoulder_reach(ctx: TraversalContext, direction: Vector3) -> Vector3:
	var forward: Vector3 = ctx.visuals.global_transform.basis.z
	var behind := direction.dot(forward)
	if behind >= 0.0:
		return direction
	var flattened := direction - forward * behind
	if flattened.length_squared() < 0.0001:
		return Vector3.UP
	return flattened.normalized()


## `wanted` if the wrist can turn that far off `along`, otherwise as far toward
## it as WRIST_LIMIT allows.
func _within_wrist_reach(wanted: Vector3, along: Vector3) -> Vector3:
	var apart := along.angle_to(wanted)
	if apart <= WRIST_LIMIT:
		return wanted
	var axis := along.cross(wanted)
	if axis.length_squared() < 0.000001:
		return along
	return along.rotated(axis.normalized(), WRIST_LIMIT)


## Turns a segment so its own local -Y lies along `direction`, given a hint for
## which way is sideways. Exact whatever the pivot does with an Euler angle.
func _aim_segment(segment: Node3D, direction: Vector3, side_hint: Vector3, t: float) -> void:
	var down_the_limb := -direction
	var side := side_hint - down_the_limb * side_hint.dot(down_the_limb)
	if side.length_squared() < 0.0001:
		side = Vector3.FORWARD - down_the_limb * Vector3.FORWARD.dot(down_the_limb)
	if side.length_squared() < 0.0001:
		return
	side = side.normalized()
	var wanted := Basis(side, down_the_limb, side.cross(down_the_limb).normalized())
	_slerp_into_parent(segment, wanted, t)


## The hand, whose own -Y is the fingertips and whose +Z is the palm.
func _aim_hand(hand: Node3D, fingers: Vector3, palm: Vector3, t: float) -> void:
	var y := -fingers
	var z := palm - y * palm.dot(y)
	if z.length_squared() < 0.0001:
		return
	z = z.normalized()
	_slerp_into_parent(hand, Basis(y.cross(z).normalized(), y, z), t)


## Eases a joint toward a world-space orientation, expressed in its parent's
## frame so the joint's own local rotation is what actually changes.
func _slerp_into_parent(joint: Node3D, wanted_world: Basis, t: float) -> void:
	var parent := joint.get_parent() as Node3D
	if parent == null:
		return
	var wanted_local := (
		parent.global_transform.basis.orthonormalized().inverse()
		* wanted_world.orthonormalized()
	).orthonormalized()
	joint.quaternion = joint.quaternion.slerp(wanted_local.get_rotation_quaternion(), t)


## The leg opposite the holding hand leads, the other trails, and the knees keep
## the airborne pose's own fold. Hip forward is negative rotation.x, the knee's
## bend positive: see SWING_HIP_LEAD.
func _pose_legs(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	var t := minf(LEG_BLEND * ctx.delta, 1.0)
	var lead_is_left := not left_hand
	for side in 2:
		var prefix := "leg_left" if side == 0 else "leg_right"
		var leads := (side == 0) == lead_is_left
		var hip := rig.joint("%s_hip" % prefix)
		if hip != null:
			_borrow(hip)
			hip.rotation.x = lerp_angle(
				hip.rotation.x, -SWING_HIP_LEAD if leads else SWING_HIP_TRAIL, t
			)
		var knee := rig.joint("%s_knee" % prefix)
		if knee != null:
			_borrow(knee)
			knee.rotation.x = lerp_angle(knee.rotation.x, SWING_KNEE_BEND, t)


## Records a joint's rotation the first time this mode touches it.
func _borrow(joint: Node3D) -> void:
	var id := joint.get_instance_id()
	if not _borrowed.has(id):
		_borrowed[id] = joint.rotation


## Gives back what the ordinary animation will not rewrite itself. It drives
## rotation.x on these joints every frame and leaves y and z alone, and an aimed
## basis leaves its residue in exactly those two, so those are what this puts
## back. Leaving x to the ordinary pose avoids fighting it for one frame.
func _hand_back(ctx: TraversalContext) -> void:
	if not _releasing:
		return
	var t := minf(RELEASE_BLEND * ctx.delta, 1.0)
	var settled := true
	for id: int in _borrowed.keys():
		var joint := instance_from_id(id) as Node3D
		if joint == null or not is_instance_valid(joint):
			continue
		var rest: Vector3 = _borrowed[id]
		joint.rotation.y = lerp_angle(joint.rotation.y, rest.y, t)
		joint.rotation.z = lerp_angle(joint.rotation.z, rest.z, t)
		if absf(angle_difference(joint.rotation.y, rest.y)) > 0.01:
			settled = false
		if absf(angle_difference(joint.rotation.z, rest.z)) > 0.01:
			settled = false
	if settled:
		_borrowed.clear()
		_releasing = false


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
