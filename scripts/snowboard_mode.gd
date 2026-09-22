class_name SnowboardMode
extends TraversalMode

## Riding a snowboard on Snow legs, shared by every character (see
## docs/traversal_powers_architecture.md).
##
## Owns the board's contact model and its glide. Both are LAYERS inside
## ordinary grounded movement rather than a power that takes the whole frame:
## the glide replaces the horizontal velocity, and follow_terrain() decides
## the board's height and whether it is flying, while the surrounding frame
## keeps the steering, the collision move and the rest.
##
## Two rules, and no speed-dependent thresholds:
##
## - Rising or level snow is simply followed, and a planted board carries the
##   grade's OWN vertical speed rather than zero. That is what makes a steady
##   slope stable at any speed: the board already descends at the rate the
##   snow falls away, so the next frame finds it on the surface. Zeroing it
##   instead meant that at 38 m/s the ground dropped 0.29 m in a frame while
##   gravity from rest covered 0.006 m, and the board "outran" the snow and
##   flew on every slope.
## - Real flight begins only where the snow falls away faster than gravity
##   can pull the board down from the speed it already has: a cornice, a ramp
##   lip, a cliff. Air scales with the drop, with nothing to tune.
##
## Landing keeps the downhill momentum, drops the impact velocity, and
## latches the board down briefly so a touchdown cannot bounce straight back
## into the air. An explicit jump is unaffected: it runs earlier in the frame.

const LANDING_LATCH := 0.12
const LATCH_DROP_MARGIN := 0.25
## Glide tuning. This class is the owner; player.gd forwards these for the
## callers that have not migrated yet.
const ROLLING_RESISTANCE := 0.04
const ICE_RESISTANCE := 0.032
const OFF_SNOW_BRAKING := 40.0
const AIR_DRAG := 0.00032
const TUCK_DRAG_MULTIPLIER := 0.42
const TUCK_TERMINAL_MULTIPLIER := 1.22
const TURN_RATE := deg_to_rad(105.0)
const CARVE_GRIP := 2.4
const STOP_SPEED := 0.12
const TERMINAL_SPEED := 150.0
const GRAVITY_SCALE := 2.15
## The rider stands on the deck, so the deck's underside rests on the snow,
## not the bare sole. Authored against the human figure and scaled per body.
const DECK_LIFT := 0.13

var airborne := false
var ground_latch := 0.0


func id() -> StringName:
	return &"snowboard"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null and ctx.suit.has_snowboard_legs()


## The board's own velocity across the snow, carving toward the steering and
## accelerating down the fall line. Ice is slicker than snow.
func glide(ctx: TraversalContext, surface_normal: Vector3, on_ice: bool) -> Vector2:
	var tuck := ctx.sprinting
	var steering := Vector2(ctx.direction.x, ctx.direction.z)
	return HumanoidLocomotion.gravity_surface_glide(
		Vector2(ctx.body.velocity.x, ctx.body.velocity.z), surface_normal, steering, ctx.delta,
		ICE_RESISTANCE if on_ice else ROLLING_RESISTANCE,
		AIR_DRAG * (TUCK_DRAG_MULTIPLIER if tuck else 1.0),
		TURN_RATE, CARVE_GRIP, STOP_SPEED,
		TERMINAL_SPEED * (TUCK_TERMINAL_MULTIPLIER if tuck else 1.0),
		GRAVITY_SCALE
	)


## Off the snow the board does not slide at all: it grinds to a halt, and
## neither slope nor steering can push it.
func brake_off_snow(ctx: TraversalContext) -> Vector2:
	return Vector2(ctx.body.velocity.x, ctx.body.velocity.z).move_toward(
		Vector2.ZERO, OFF_SNOW_BRAKING * ctx.delta
	)


## Follows the snow for this frame. `target_h` is the surface height under
## the board and `rise` how far that is above its feet; `surface_fall` is the
## vertical speed of travelling along the current grade. `foot_offset` is the
## body's own feet-to-origin distance.
func follow_terrain(
	ctx: TraversalContext, target_h: float, rise: float, surface_fall: float, foot_offset: float
) -> void:
	ground_latch = maxf(ground_latch - ctx.delta, 0.0)
	if rise >= 0.0:
		_land(ctx, target_h, surface_fall, foot_offset)
		return
	# A fresh landing needs the ground to fall further away than an ordinary
	# frame would, so the touchdown itself cannot relaunch the board.
	var drop_margin := LATCH_DROP_MARGIN if ground_latch > 0.0 else 0.0
	if -rise <= drop_margin:
		_land(ctx, target_h, surface_fall, foot_offset)
		return
	var body := ctx.body
	body.velocity.y = HumanoidLocomotion.apply_gravity(
		body.velocity.y, ctx.delta, ctx.profile, Player.TERMINAL_FALL_SPEED
	)
	var predicted_h := (body.global_position.y - foot_offset) + body.velocity.y * ctx.delta
	if predicted_h > target_h:
		body.global_position.y = predicted_h + foot_offset
		airborne = true
		return
	_land(ctx, target_h, surface_fall, foot_offset)


## Plants the board, riding the surface at the grade's own vertical speed and
## keeping its horizontal momentum. A landing out of real flight latches.
func _land(ctx: TraversalContext, target_h: float, surface_fall: float, foot_offset: float) -> void:
	ctx.body.global_position.y = target_h + foot_offset
	ctx.body.velocity.y = minf(surface_fall, 0.0)
	if airborne:
		airborne = false
		ground_latch = LANDING_LATCH


## Riding stance: knees and hips flexed, feet splayed across the deck, the
## torso twisted to face down the fall line and leaning into the speed, with
## the arms out for balance. Grade flex opens one knee and closes the other
## so the board stays along the slope under it.
const POSE_SETTLE_SPEED := 7.0
const STANCE_SPLAY := deg_to_rad(15.0)
const HIP_BEND := deg_to_rad(10.0)
const TUCK_HIP_BEND := deg_to_rad(16.0)
const KNEE_BEND := deg_to_rad(25.0)
const TUCK_KNEE_BEND := deg_to_rad(27.0)
const ARM_SPREAD := deg_to_rad(20.0)
const TUCK_ARM_SPREAD := deg_to_rad(12.0)
const ELBOW_BEND := deg_to_rad(10.0)
const TUCK_ELBOW_BEND := deg_to_rad(10.0)
const ABDOMEN_TWIST := deg_to_rad(16.0)
const THORAX_TWIST := deg_to_rad(18.0)
const SPEED_LEAN_MAX := deg_to_rad(-17.0)
const TUCK_LEAN := deg_to_rad(-6.0)
const FULL_LEAN_SPEED := 25.0
const GRADE_FLEX_LIMIT := deg_to_rad(16.0)

var pose_blend := 0.0


## `riding` is whether the board is out; `deck_up` is the board's own smoothed
## up axis and `heading` the direction it points, both owned by whoever draws
## the deck.
func pose_stance(ctx: TraversalContext, riding: bool, deck_up: Vector3, heading: Vector3) -> void:
	var rig := ctx.rig
	if rig == null:
		return
	var settle := minf(POSE_SETTLE_SPEED * ctx.delta, 1.0)
	pose_blend = move_toward(pose_blend, 1.0 if riding else 0.0, POSE_SETTLE_SPEED * ctx.delta)
	if pose_blend <= 0.001:
		_relax(rig, "spine", settle)
		_relax(rig, "thorax", settle)
		return
	var w := pose_blend
	var tuck := 1.0 if ctx.sprinting and riding else 0.0
	var speed_ratio := clampf(
		Vector2(ctx.body.velocity.x, ctx.body.velocity.z).length() / FULL_LEAN_SPEED, 0.0, 1.0
	)
	var forward_lean := (SPEED_LEAN_MAX * speed_ratio + TUCK_LEAN * tuck) * w
	var grade_heading := Vector3(heading.x, 0.0, heading.z).normalized()
	var grade_forward := grade_heading - deck_up * grade_heading.dot(deck_up)
	var deck_grade := 0.0
	if grade_forward.length_squared() > 0.001:
		deck_grade = asin(clampf(grade_forward.normalized().y, -1.0, 1.0))
	var grade_flex := clampf(deck_grade * 0.55, -GRADE_FLEX_LIMIT, GRADE_FLEX_LIMIT)
	var hip_target := -(HIP_BEND + TUCK_HIP_BEND * tuck)
	var knee_target := KNEE_BEND + TUCK_KNEE_BEND * tuck
	for side in 2:
		var prefix := "leg_left" if side == 0 else "leg_right"
		var flex := grade_flex if side == 0 else -grade_flex
		var hip := rig.joint("%s_hip" % prefix)
		if hip != null:
			hip.rotation.x = lerp_angle(hip.rotation.x, hip_target + flex, w)
			hip.rotation.z = lerp_angle(hip.rotation.z, signf(hip.position.x) * STANCE_SPLAY, w)
		var knee := rig.joint("%s_knee" % prefix)
		if knee != null:
			knee.rotation.x = lerp_angle(knee.rotation.x, knee_target - flex, w)
		# Feet sit flat on the deck; a rig whose ankle drives nothing skips it.
		if rig.articulates("%s_ankle" % prefix):
			var ankle := rig.joint("%s_ankle" % prefix)
			ankle.rotation.x = lerp_angle(ankle.rotation.x, 0.0, w)
	var arm_spread := ARM_SPREAD + TUCK_ARM_SPREAD * tuck
	var elbow_bend := ELBOW_BEND + TUCK_ELBOW_BEND * tuck
	for side in 2:
		if (ctx.left_arm_busy if side == 0 else ctx.right_arm_busy):
			continue
		var shoulder := rig.joint("arm_left_shoulder" if side == 0 else "arm_right_shoulder")
		if shoulder != null:
			shoulder.rotation.x = lerp_angle(shoulder.rotation.x, 0.0, w)
			shoulder.rotation.z = lerp_angle(shoulder.rotation.z, signf(shoulder.position.x) * arm_spread, w)
		var elbow := rig.joint("arm_left_elbow" if side == 0 else "arm_right_elbow")
		if elbow != null:
			elbow.rotation.x = lerp_angle(elbow.rotation.x, -elbow_bend, w)
	var spine := rig.joint("spine")
	if spine != null:
		spine.rotation.y = lerp_angle(spine.rotation.y, ABDOMEN_TWIST, w)
		spine.rotation.z = lerp_angle(spine.rotation.z, forward_lean, settle)
		spine.position.y = lerpf(spine.position.y, rig.rest_position("spine").y, w)
	var thorax := rig.joint("thorax")
	if thorax != null:
		thorax.rotation.y = lerp_angle(thorax.rotation.y, THORAX_TWIST, w)
		thorax.rotation.z = lerp_angle(thorax.rotation.z, forward_lean * 0.35, settle)
	var hips := rig.joint("hips")
	if hips != null:
		hips.position.y = lerpf(hips.position.y, rig.rest_position("hips").y, w)


## Only this layer ever leans the torso sideways, so it straightens it on the
## way out of riding.
static func _relax(rig: RigAdapter, name: String, settle: float) -> void:
	var joint := rig.joint(name)
	if joint != null:
		joint.rotation.z = lerp_angle(joint.rotation.z, 0.0, settle)


## The board itself: one continuous manifold deck, rounded at nose and tail
## by the SuperEgg rather than seamed on. Built at the wearer's own scale, so
## a smaller rig gets a board that fits its feet rather than the human's.
const LENGTH := 2.45
const WIDTH := 0.32
const THICKNESS := 0.08
const DECK_COLOR := ElementPalette.SNOW_BODY


## `worn` is the snow blorb the board grows out of. The board is that blorb
## reshaped, so it takes the same translucent gel as the legs it is under
## rather than reading as an opaque plank in snow colour.
static func build_deck(parent: Node3D, rig_scale: float = 1.0, worn: Blorb = null) -> Node3D:
	var root := Node3D.new()
	root.name = "Snowboard"
	parent.add_child(root)
	var deck := SuperEgg.build_part(
		Vector3(LENGTH * 0.5, THICKNESS, WIDTH) * rig_scale, DECK_COLOR, 3.2, 3.2
	)
	deck.name = "ContinuousDeck"
	if worn != null:
		deck.set_surface_override_material(0, BlorbSuit.gel_material_for(worn))
	root.add_child(deck)
	CollisionPolicy.mark_decorative(deck)
	return root


func reset() -> void:
	airborne = false
	ground_latch = 0.0
