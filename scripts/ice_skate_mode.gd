class_name IceSkateMode
extends TraversalMode

## Skating on Ice legs, as a shared traversal power: the first power moved
## onto the system described in docs/traversal_powers_architecture.md.
##
## This currently owns the POSE only. The movement half still lives in
## player.gd's own branch and calls in here, so that the migration lands in
## reviewable pieces rather than one sweep. Xiao Hou Zi keeps his own copy of
## this pose until his rig gains the ankle joint it needs (see the comment
## above MonkeyFigure.build(): his ankle marker moves nothing at all), at
## which point his duplicate goes away and both characters skate through this.
##
## Every joint is addressed by rig-neutral name and every write is checked, so
## a rig that lacks a joint reads as a fact rather than as a pose that quietly
## does nothing.

const POSE_SETTLE_SPEED := 9.0
const PUSH_HIP_BACK := deg_to_rad(25.0)
const GLIDE_HIP_FORWARD := deg_to_rad(13.0)
const RECOVERY_HIP_FORWARD := deg_to_rad(11.0)
const PUSH_OUTWARD := deg_to_rad(18.0)
const SPRINT_PUSH_OUTWARD := deg_to_rad(48.0)
const TOE_OUT := deg_to_rad(24.0)
const PUSH_KNEE := deg_to_rad(13.0)
const GLIDE_KNEE := deg_to_rad(27.0)
const RECOVERY_KNEE := deg_to_rad(20.0)
const ARM_SWING := deg_to_rad(18.0)
const SPRINT_POSE_MULTIPLIER := 2.0
const SPRINT_ARM_LIFT := deg_to_rad(16.0)
const CADENCE_GLIDE := 1.65
const CADENCE_THRUST := 4.35
const FULL_THRUST_ACCELERATION := 7.5
const MOVING_SPEED := 0.12

## Set by whoever owns the movement half while that is still outside this
## class. Once the movement moves in, this becomes the mode's own state.
var engaged := false

var _blend := 0.0
var _previous_speed := 0.0
var _smoothed_acceleration := 0.0
var _stride_phase := 0.0


func id() -> StringName:
	return &"ice_skates"


## Matched Ice legs, and not while the Penguin Suit is formed: the runners
## withdraw and the penguin glides in their place.
func is_available(ctx: TraversalContext) -> bool:
	if ctx.suit == null:
		return false
	return ctx.suit.has_ice_skate_legs() and not ctx.suit.penguin_form_active()


## Where the stride currently is, for whoever is pacing the skating audio.
func stride_phase() -> float:
	return _stride_phase


## The runners withdrew: this ride is over and none of its stride survives
## into the next one.
func reset() -> void:
	_blend = 0.0
	_stride_phase = 0.0
	_previous_speed = 0.0
	_smoothed_acceleration = 0.0


## One skate's support -> push -> forward recovery cycle. The other leg uses
## the same curve half a cycle later. Components are (push, recovery, support)
## and always sum to one, which is what prevents a side-to-side pendulum.
static func stroke(cycle: float) -> Vector3:
	var p := fposmod(cycle, 1.0)
	# Most of the first half is planted in the glide. Weight transfers quickly
	# into a rearward thrust, the extension hangs briefly, then that leg
	# recovers forward slowly in preparation for its next planted phase.
	var support := 1.0 - smoothstep(0.38, 0.50, p) + smoothstep(0.88, 1.0, p)
	var push := smoothstep(0.42, 0.52, p) * (1.0 - smoothstep(0.70, 0.88, p))
	var recovery := smoothstep(0.68, 0.80, p) * (1.0 - smoothstep(0.90, 1.0, p))
	var total := maxf(push + recovery + support, 0.001)
	return Vector3(push, recovery, support) / total


func pose(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	if rig == null:
		return
	var delta := ctx.delta
	var planar_speed := Vector2(ctx.body.velocity.x, ctx.body.velocity.z).length()
	var moving := engaged and planar_speed > MOVING_SPEED
	_blend = move_toward(_blend, 1.0 if moving else 0.0, POSE_SETTLE_SPEED * delta)
	if not moving:
		_settle(ctx, delta)
		return
	var w := _blend
	# Pose strength and temporal interpolation are distinct. Using w itself as
	# the lerp weight became a literal one-frame snap once the blend hit 1.0.
	var pose_t := minf(POSE_SETTLE_SPEED * delta, 1.0) * w
	var effort := SPRINT_POSE_MULTIPLIER if ctx.sprinting else 1.0
	var raw_acceleration := maxf((planar_speed - _previous_speed) / maxf(delta, 0.0001), 0.0)
	_previous_speed = planar_speed
	_smoothed_acceleration = lerpf(_smoothed_acceleration, raw_acceleration, 1.0 - exp(-5.0 * delta))
	var thrust_mix := clampf(_smoothed_acceleration / FULL_THRUST_ACCELERATION, 0.0, 1.0)
	_stride_phase += delta * lerpf(CADENCE_GLIDE, CADENCE_THRUST, smoothstep(0.0, 1.0, thrust_mix))
	var cycle := fposmod(_stride_phase / TAU, 1.0)
	var left := stroke(cycle)
	var right := stroke(fposmod(cycle + 0.5, 1.0))
	for side in 2:
		var s: Vector3 = left if side == 0 else right
		var other: Vector3 = right if side == 0 else left
		var prefix := "leg_left" if side == 0 else "leg_right"
		var arm := "arm_left_shoulder" if side == 0 else "arm_right_shoulder"
		var toe_sign := 1.0 if side == 0 else -1.0
		var knee := (GLIDE_KNEE * s.z + PUSH_KNEE * s.x + RECOVERY_KNEE * s.y) * effort
		# Positive X is backward on this rig, for both characters -- measured,
		# see the comment above MonkeyFigure.build(). A negative push kicks
		# forward, which is what an early version of this pose did.
		var hip_x := (
			PUSH_HIP_BACK * s.x * effort
			- RECOVERY_HIP_FORWARD * s.y
			- GLIDE_HIP_FORWARD * s.z * effort
		)
		var hip := rig.joint("%s_hip" % prefix)
		var knee_joint := rig.joint("%s_knee" % prefix)
		var ankle := rig.joint("%s_ankle" % prefix)
		if hip != null:
			hip.rotation.x = lerp_angle(hip.rotation.x, hip_x, pose_t)
			# Positive yaw on the left and negative on the right open the
			# toes, not the heels.
			hip.rotation.y = lerp_angle(hip.rotation.y, toe_sign * TOE_OUT * s.x * effort, pose_t)
		if knee_joint != null:
			knee_joint.rotation.x = lerp_angle(knee_joint.rotation.x, knee, pose_t)
		# Lateral extension is resolved after the hip, toe and knee pose is
		# present: deep flex changes the combined Euler result substantially.
		if hip != null and ankle != null and ctx.visuals != null:
			var outward := SPRINT_PUSH_OUTWARD if ctx.sprinting else PUSH_OUTWARD
			var roll := outward_roll(hip, ankle, rig.joint("spine"), ctx.visuals, outward)
			hip.rotation.z = lerp_angle(hip.rotation.z, roll * s.x, pose_t)
		# Counter the whole support-leg chain at the ankle, keeping the
		# weighted runner parallel to the ice rather than pitching with the
		# bent knee. A rig whose ankle drives nothing simply does not get this.
		if ankle != null and rig.articulates("%s_ankle" % prefix):
			ankle.rotation.x = lerp_angle(ankle.rotation.x, -(hip_x + knee) * s.z, pose_t)
		# Run-like opposition on the same support weights as the legs.
		var shoulder := rig.joint(arm)
		if shoulder != null:
			var lift := SPRINT_ARM_LIFT if ctx.sprinting else 0.0
			var swing := (-ARM_SWING * other.z + ARM_SWING * 0.55 * s.z) * effort - lift
			shoulder.rotation.x = lerp_angle(shoulder.rotation.x, swing, pose_t)


## Leaving the stride: the ordinary gait already owns the limbs by now, so
## only the torso lean this layer applied is straightened, and only where
## this layer is the one that applied it.
func _settle(ctx: TraversalContext, delta: float) -> void:
	_previous_speed = Vector2(ctx.body.velocity.x, ctx.body.velocity.z).length()
	_smoothed_acceleration = 0.0
	var rest_t := minf(POSE_SETTLE_SPEED * delta, 1.0)
	var spine := ctx.rig.joint("spine")
	if engaged and spine != null:
		# Stopped but still on the ice: ordinary gait is suppressed there, so
		# this layer settles the torso itself.
		spine.rotation.x = lerp_angle(spine.rotation.x, 0.0, rest_t)
	# Only this layer ever leans the thorax, so it straightens it on every way
	# out of skating, not only a stop on ice.
	var thorax := ctx.rig.joint("thorax")
	if thorax != null:
		thorax.rotation.x = lerp_angle(thorax.rotation.x, 0.0, rest_t)


## The leg roll that carries the ankle furthest outward, searched rather than
## assumed: comparing only the two extremes picks the less-inward endpoint
## when deep sprint flex folds both toward the centre.
static func outward_roll(
	leg: Node3D, ankle: Node3D, spine: Node3D, visuals: Node3D, amount: float
) -> float:
	var original := leg.rotation.z
	var right := visuals.global_transform.basis.x.normalized()
	var reference: Vector3 = spine.global_position if spine != null else visuals.global_position
	var side := signf((leg.global_position - reference).dot(right))
	if is_zero_approx(side):
		side = signf(leg.position.x)
	var best_angle := 0.0
	var best_score := -INF
	for sample in 17:
		var candidate := lerpf(-amount, amount, float(sample) / 16.0)
		leg.rotation.z = candidate
		leg.force_update_transform()
		ankle.force_update_transform()
		var score := side * (ankle.global_position - leg.global_position).dot(right)
		if score > best_score:
			best_score = score
			best_angle = candidate
	leg.rotation.z = original
	return best_angle
