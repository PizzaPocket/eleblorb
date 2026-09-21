class_name SwimMode
extends TraversalMode

## Swimming, shared by every character (docs/traversal_powers_architecture.md).
##
## Swimming is not one behaviour but a pair, and getting that pair wrong is
## what made Xiao Hou Zi read so unlike the human in water: he lay flat and
## kicked without pause, wherever he was and whether or not he was going
## anywhere. A swimmer at rest hangs upright and still, legs trailing down; a
## swimmer under way lies along their travel and kicks. Everything here is
## driven by one eased `motion` blend between those two, so a body arrives at
## and leaves each of them smoothly instead of snapping.
##
## The mode owns the kick, the limbs and the head. It does NOT apply the body
## attitude itself: it reports the pitch through `attitude_pitch()`, because
## each character turns its own body differently (the human pivots about the
## skull so the camera keeps its distance, while Xiao Hou Zi turns his rig
## about the spine). The number they use is the same.

## Below this speed a swimmer counts as resting, and the blend eases back.
const MOVING_SPEED := 0.35
const MOTION_BLEND_RATE := 2.4
const POSE_SETTLE_SPEED := 9.0
## The relaxed float: how the legs hang when nobody is swimming anywhere.
const REST_HIP_BEND := deg_to_rad(18.0)
const REST_KNEE_BEND := deg_to_rad(46.0)
const FLOAT_ANKLE_EXTEND := deg_to_rad(38.0)
## The kick, added only while under way.
const KICK_SPEED := 8.0
const KICK_HIP_AMOUNT := deg_to_rad(19.0)
const KICK_KNEE_AMOUNT := deg_to_rad(17.0)
const KICK_ANKLE_AMOUNT := deg_to_rad(10.0)
## Streamlining: the arms sweep back as the swimmer picks up speed.
const FAST_ARM_BACK_SWING := deg_to_rad(22.0)
const FAST_ELBOW_BEND := deg_to_rad(3.0)
## How far the body lies over when fully under way, diving or at the surface,
## and how far the head turns to lead.
const DIVE_PITCH := deg_to_rad(76.0)
const SURFACE_PITCH := deg_to_rad(52.0)
const HEAD_LEAD := deg_to_rad(26.0)

## 0 resting, 1 under way. Everything else follows it.
var motion := 0.0
var kick_phase := 0.0


func id() -> StringName:
	return &"swim"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null


## Advances the rest/motion blend for this frame. `reference_speed` is what
## counts as full speed for this body, so a small character reaches a full
## kick at its own pace rather than the human's.
func update_motion(ctx: TraversalContext, reference_speed: float) -> void:
	var speed := ctx.body.velocity.length()
	var wants := 1.0 if speed > MOVING_SPEED else 0.0
	motion = move_toward(motion, wants, MOTION_BLEND_RATE * ctx.delta)
	if motion <= 0.001:
		kick_phase = 0.0
		return
	var fraction := clampf(speed / maxf(reference_speed, 0.001), 0.0, 1.0)
	# Fast swimming quickens the kick rather than merely widening it.
	kick_phase += ctx.delta * KICK_SPEED * lerpf(0.6, 1.8, fraction) * motion


## How far over the body should lie right now: nothing at rest, and the full
## angle under way. The caller turns its own body by this.
func attitude_pitch(diving: bool) -> float:
	return (DIVE_PITCH if diving else SURFACE_PITCH) * motion


## The relaxed float, with the kick laid over it in proportion to how much
## the swimmer is actually going somewhere. A rig missing a joint skips that
## part rather than writing somewhere nothing moves.
## `lead_head` is false for a body whose head-look is owned elsewhere, so
## this never fights it for the same joint.
func pose_swim(ctx: TraversalContext, reference_speed: float, lead_head: bool = true) -> void:
	var rig := ctx.rig
	if rig == null:
		return
	var t := minf(POSE_SETTLE_SPEED * ctx.delta, 1.0)
	var speed := ctx.body.velocity.length()
	var fraction := clampf(speed / maxf(reference_speed, 0.001), 0.0, 1.0)
	var wave := sin(kick_phase) * motion
	for side in 2:
		var prefix := "leg_left" if side == 0 else "leg_right"
		var swing := wave if side == 0 else -wave
		var hip := rig.joint("%s_hip" % prefix)
		if hip != null:
			hip.rotation.x = lerp_angle(hip.rotation.x, -REST_HIP_BEND + swing * KICK_HIP_AMOUNT, t)
		var knee := rig.joint("%s_knee" % prefix)
		if knee != null:
			knee.rotation.x = lerp_angle(
				knee.rotation.x, REST_KNEE_BEND + maxf(0.0, -swing) * KICK_KNEE_AMOUNT, t
			)
		if rig.articulates("%s_ankle" % prefix):
			var ankle := rig.joint("%s_ankle" % prefix)
			ankle.rotation.x = lerp_angle(
				ankle.rotation.x, FLOAT_ANKLE_EXTEND + maxf(0.0, swing) * KICK_ANKLE_AMOUNT, t
			)
	# Streamlined arms, scaled by speed so a slow float stays relaxed.
	var arm_back := FAST_ARM_BACK_SWING * fraction * motion
	var elbow_bend := FAST_ELBOW_BEND * fraction * motion
	for side in 2:
		if (ctx.left_arm_busy if side == 0 else ctx.right_arm_busy):
			continue
		var shoulder := rig.joint("arm_left_shoulder" if side == 0 else "arm_right_shoulder")
		if shoulder != null:
			shoulder.rotation.x = lerp_angle(shoulder.rotation.x, arm_back, t)
		var elbow := rig.joint("arm_left_elbow" if side == 0 else "arm_right_elbow")
		if elbow != null:
			elbow.rotation.x = lerp_angle(elbow.rotation.x, -elbow_bend, t)
	if lead_head:
		_lead_with_the_head(rig, t)


## The mermaid tail: a VARIANT of swimming rather than a separate power, the
## legs held together inside the tail and kicking as one like a dolphin. The
## hips drive, the knees fold on the upbeat, and the fluke whips a quarter
## beat behind them. The kick quickens with speed, and the arms stay
## streamlined but sweep less than a free swimmer's.
##
## Like the ordinary swim, it only kicks once actually under way: a tail at
## rest hangs still.
const MERMAID_SPEED_MULTIPLIER := 3.0
const MERMAID_LEG_ADDUCT := deg_to_rad(7.5)
const MERMAID_ANKLE_POINT := deg_to_rad(86.0)
const MERMAID_KICK_SPEED := 10.0
const MERMAID_KICK_HIP_AMOUNT := deg_to_rad(15.0)
const MERMAID_KICK_KNEE_AMOUNT := deg_to_rad(28.0)
const MERMAID_KICK_ANKLE_AMOUNT := deg_to_rad(16.0)
const MERMAID_ARM_BACK_FRACTION := 0.4


func update_mermaid_motion(ctx: TraversalContext, reference_speed: float) -> void:
	var speed := ctx.body.velocity.length()
	var wants := 1.0 if speed > MOVING_SPEED else 0.0
	motion = move_toward(motion, wants, MOTION_BLEND_RATE * ctx.delta)
	if motion <= 0.001:
		kick_phase = 0.0
		return
	var fraction := clampf(speed / maxf(reference_speed, 0.001), 0.0, 1.0)
	kick_phase += ctx.delta * MERMAID_KICK_SPEED * lerpf(0.5, 1.6, fraction) * motion


func pose_mermaid(ctx: TraversalContext, reference_speed: float, lead_head: bool = true) -> void:
	var rig := ctx.rig
	if rig == null:
		return
	var t := minf(POSE_SETTLE_SPEED * ctx.delta, 1.0)
	var speed := ctx.body.velocity.length()
	var fraction := clampf(speed / maxf(reference_speed, 0.001), 0.0, 1.0)
	var wave := sin(kick_phase) * motion
	var hip := -REST_HIP_BEND * 0.4 + wave * MERMAID_KICK_HIP_AMOUNT
	var knee := maxf(0.0, -wave) * MERMAID_KICK_KNEE_AMOUNT
	# The fluke lags the hips by a quarter beat.
	var ankle := MERMAID_ANKLE_POINT - cos(kick_phase) * MERMAID_KICK_ANKLE_AMOUNT * motion
	for side in 2:
		var prefix := "leg_left" if side == 0 else "leg_right"
		var hip_joint := rig.joint("%s_hip" % prefix)
		if hip_joint != null:
			hip_joint.rotation.x = lerp_angle(hip_joint.rotation.x, hip, t)
			# Drawn together inside the one tail.
			hip_joint.rotation.z = lerp_angle(
				hip_joint.rotation.z, -signf(hip_joint.position.x) * MERMAID_LEG_ADDUCT, t
			)
		var knee_joint := rig.joint("%s_knee" % prefix)
		if knee_joint != null:
			knee_joint.rotation.x = lerp_angle(knee_joint.rotation.x, knee, t)
		if rig.articulates("%s_ankle" % prefix):
			var ankle_joint := rig.joint("%s_ankle" % prefix)
			ankle_joint.rotation.x = lerp_angle(ankle_joint.rotation.x, ankle, t)
	var arm_back := FAST_ARM_BACK_SWING * fraction * MERMAID_ARM_BACK_FRACTION * motion
	var elbow_bend := FAST_ELBOW_BEND * fraction * MERMAID_ARM_BACK_FRACTION * motion
	for side in 2:
		if (ctx.left_arm_busy if side == 0 else ctx.right_arm_busy):
			continue
		var shoulder := rig.joint("arm_left_shoulder" if side == 0 else "arm_right_shoulder")
		if shoulder != null:
			shoulder.rotation.x = lerp_angle(shoulder.rotation.x, arm_back, t)
		var elbow := rig.joint("arm_left_elbow" if side == 0 else "arm_right_elbow")
		if elbow != null:
			elbow.rotation.x = lerp_angle(elbow.rotation.x, -elbow_bend, t)
	var spine := rig.joint("spine")
	if spine != null:
		spine.rotation.x = lerp_angle(spine.rotation.x, 0.0, t)
		spine.position.y = lerpf(spine.position.y, rig.rest_position("spine").y, t)
	if lead_head:
		_lead_with_the_head(rig, t)


## Water jets underwater are not the land jet: each active water limb drives
## the swimmer forward, and the limbs streamline rather than gesturing. The
## jetting hands sweep back beside the hips and the jetting legs straighten
## and stream behind, so the whole body reads as being propelled.
##
## A mermaid keeps her own kick and pointed toes: the jets fire from the
## fluke without straightening the legs inside the tail.
const JET_SPEED_MULTIPLIER := 1.35
const JET_POSE_SETTLE_SPEED := 9.0
const JET_ARM_BACK_ANGLE := deg_to_rad(8.0)
const JET_ARM_OUTWARD_ANGLE := deg_to_rad(16.0)
const JET_ELBOW_BEND := deg_to_rad(10.0)


## How much faster this swimmer travels with `jets` water limbs firing.
static func jet_speed_multiplier(jets: int) -> float:
	return pow(JET_SPEED_MULTIPLIER, maxf(jets, 0))


## Streamlines whichever limbs are jetting. `tail` keeps the legs inside a
## mermaid's fluke rather than straightening them.
func pose_jets(
	ctx: TraversalContext, left_arm: bool, right_arm: bool,
	left_leg: bool, right_leg: bool, tail: bool = false
) -> void:
	var rig := ctx.rig
	if rig == null:
		return
	var t := minf(JET_POSE_SETTLE_SPEED * ctx.delta, 1.0)
	for side in 2:
		if not (left_arm if side == 0 else right_arm):
			continue
		if (ctx.left_arm_busy if side == 0 else ctx.right_arm_busy):
			continue
		var outward := 1.0 if side == 0 else -1.0
		var shoulder := rig.joint("arm_left_shoulder" if side == 0 else "arm_right_shoulder")
		if shoulder != null:
			shoulder.rotation.x = lerp_angle(shoulder.rotation.x, JET_ARM_BACK_ANGLE, t)
			shoulder.rotation.y = lerp_angle(shoulder.rotation.y, 0.0, t)
			shoulder.rotation.z = lerp_angle(shoulder.rotation.z, outward * JET_ARM_OUTWARD_ANGLE, t)
		var elbow := rig.joint("arm_left_elbow" if side == 0 else "arm_right_elbow")
		if elbow != null:
			elbow.rotation = elbow.rotation.lerp(Vector3(-JET_ELBOW_BEND, 0.0, 0.0), t)
	if tail or not (left_leg or right_leg):
		return
	for side in 2:
		var prefix := "leg_left" if side == 0 else "leg_right"
		for name in ["%s_hip" % prefix, "%s_knee" % prefix, "%s_ankle" % prefix]:
			if not rig.articulates(name):
				continue
			var joint := rig.joint(name)
			joint.rotation = joint.rotation.lerp(Vector3.ZERO, t)


## Under way the head lifts to look along the travel, the way a swimmer
## looks where they are going rather than at the bottom. At rest it returns.
func _lead_with_the_head(rig: RigAdapter, t: float) -> void:
	var head := rig.joint("head")
	if head == null:
		return
	head.rotation.x = lerp_angle(head.rotation.x, -HEAD_LEAD * motion, t)


func reset() -> void:
	motion = 0.0
	kick_phase = 0.0
