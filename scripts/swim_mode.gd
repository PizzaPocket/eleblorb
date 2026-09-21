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
