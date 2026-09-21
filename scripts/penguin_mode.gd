class_name PenguinMode
extends TraversalMode

## The Penguin Suit, shared by every character
## (docs/traversal_powers_architecture.md).
##
## Three states, and the whole feel is in how a body moves between them: a
## penguin WADDLES upright, DIVES forward off a jump, and then BELLY SLIDES
## where it lands on ice, tipping flat as it goes and rising again when it
## stops. One eased `prone` blend carries the body between upright and flat,
## so nothing snaps.
##
## As with swimming, the mode reports the body attitude rather than applying
## it: it hands back the tip and the height to pivot about, and each
## character turns its own body. Its collision capsule stays upright either
## way, which is what lets a penguin slide under things without the physics
## body catching.

## Diving: how fast it launches forward and how high it hops doing it.
const DIVE_FORWARD_SPEED := 15.0
const DIVE_HEIGHT := 0.45
## Landing on ice keeps most of the dive's speed, and a slide scrubs off
## this much per second on ice and far more off it.
const SLIDE_LANDING_BOOST := 1.2
const SLIDE_FRICTION := 1.1
const SLIDE_OFF_ICE_FRICTION := 12.0
const SLIDE_TURN_RATE := 1.3
const SLIDE_STOP_SPEED := 0.9
## Tipping between upright and flat, and where the body pivots in each.
const PRONE_RATE := 5.5
const BODY_PIVOT_HEIGHT := 0.75
const BELLY_REST_HEIGHT := 0.34
## Waddling: short steps, a small thigh lift, and a roll from side to side.
const WADDLE_SPEED_MULTIPLIER := 0.32
const WADDLE_CADENCE := 2.1
const WADDLE_STEP := deg_to_rad(7.0)
const WADDLE_THIGH_LIFT := deg_to_rad(6.0)
const WADDLE_KNEE := deg_to_rad(16.0)
const WADDLE_ROLL := deg_to_rad(7.0)

## The Penguin Suit is formed or unformed by pressing all four limb buttons
## together, within this many seconds of the first. Limb powers wait out the
## window, so a chord never also fires them.
const CHORD_WINDOW := 0.2
const CHORD_ACTIONS: Array[String] = [
	"left_arm_power", "right_arm_power", "left_leg_power", "right_leg_power",
]

var diving := false
var sliding := false
var prone := 0.0
var waddle_roll := 0.0
var waddle_phase := 0.0
var _waddle_posed := false
var _chord_timer := 0.0
var _chord_consumed := false
var _chord_pending_legs: Array[bool] = [false, false]


func id() -> StringName:
	return &"penguin"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null and ctx.suit.penguin_form_active()


## Watches for the four-button chord that forms or unforms the suit, which
## only the human's own file used to do, so nobody else could ever become a
## penguin at all.
##
## Returns whether limb powers must hold back this frame -- during the window,
## and until a completed chord's buttons are all released -- and which leg
## presses were held through a window that lapsed without a chord. A caller
## with its own use for those presses fires them; one without ignores them.
func update_form_chord(suit: BlorbSuitController, delta: float, sound_key: int = 0) -> Dictionary:
	var lapsed: Array[bool] = [false, false]
	if suit == null or UIState.modal_open or not suit.has_full_penguin_suit():
		_chord_timer = 0.0
		_chord_consumed = false
		_chord_pending_legs = [false, false]
		return {"holding": false, "lapsed_legs": lapsed}
	if _chord_consumed:
		_chord_consumed = CHORD_ACTIONS.any(
			func(action: String) -> bool: return Input.is_action_pressed(action)
		)
		return {"holding": true, "lapsed_legs": lapsed}
	var pressed_now := CHORD_ACTIONS.any(
		func(action: String) -> bool: return Input.is_action_just_pressed(action)
	)
	if pressed_now and _chord_timer <= 0.0:
		_chord_timer = CHORD_WINDOW
	if _chord_timer <= 0.0:
		return {"holding": false, "lapsed_legs": lapsed}
	if Input.is_action_just_pressed("left_leg_power"):
		_chord_pending_legs[0] = true
	if Input.is_action_just_pressed("right_leg_power"):
		_chord_pending_legs[1] = true
	if CHORD_ACTIONS.all(func(action: String) -> bool: return Input.is_action_pressed(action)):
		_chord_timer = 0.0
		_chord_consumed = true
		_chord_pending_legs = [false, false]
		if suit.toggle_penguin_form():
			UISounds.play_foley(&"transform_reveal", 0.6, sound_key)
		return {"holding": true, "lapsed_legs": lapsed}
	_chord_timer -= delta
	if _chord_timer > 0.0:
		return {"holding": true, "lapsed_legs": lapsed}
	# No chord formed: the leg presses held through the window were ordinary
	# presses after all.
	lapsed = _chord_pending_legs.duplicate()
	_chord_pending_legs = [false, false]
	return {"holding": false, "lapsed_legs": lapsed}


## True while upright on its feet: not in the air off a dive, not sliding.
func waddling() -> bool:
	return not diving and not sliding


## The dive's launch velocity, given where the body is pointing and what the
## stick asks for. Never slower than the dive's own forward speed.
static func dive_velocity(heading: Vector3, jump_speed: float) -> Vector3:
	var flat := Vector3(heading.x, 0.0, heading.z)
	if flat.length_squared() < 0.0001:
		flat = Vector3.FORWARD
	flat = flat.normalized() * DIVE_FORWARD_SPEED
	return Vector3(flat.x, jump_speed * DIVE_HEIGHT, flat.z)


## Watches for the dive landing and for a slide running out of ice. `grounded`
## and `on_ice` are the body's own answers, since each rig tests them its own
## way.
func update_state(ctx: TraversalContext, grounded: bool, on_ice: bool, jumping: bool) -> void:
	if not is_available(ctx):
		diving = false
		sliding = false
		return
	if diving and not jumping and ctx.body.velocity.y <= 0.0 and grounded:
		diving = false
		sliding = on_ice
		if on_ice:
			# Landing on the belly keeps most of the dive's speed.
			ctx.body.velocity.x *= SLIDE_LANDING_BOOST
			ctx.body.velocity.z *= SLIDE_LANDING_BOOST
	elif sliding and not on_ice and not grounded:
		sliding = false


## One frame of a belly slide: it scrubs speed, steers slowly toward the
## stick, and stands up when it runs out. Returns the heading it now travels,
## or zero once it has stopped.
func slide_step(ctx: TraversalContext, on_ice: bool) -> Vector2:
	var planar := Vector2(ctx.body.velocity.x, ctx.body.velocity.z)
	var friction := SLIDE_FRICTION if on_ice else SLIDE_OFF_ICE_FRICTION
	var speed := maxf(planar.length() - friction * ctx.delta, 0.0)
	if speed < SLIDE_STOP_SPEED:
		sliding = false
		ctx.body.velocity.x = 0.0
		ctx.body.velocity.z = 0.0
		return Vector2.ZERO
	var heading := planar.normalized()
	var wanted := Vector2(ctx.direction.x, ctx.direction.z)
	if wanted.length_squared() > 0.0001:
		var turn := clampf(
			heading.angle_to(wanted.normalized()),
			-SLIDE_TURN_RATE * ctx.delta, SLIDE_TURN_RATE * ctx.delta
		)
		heading = heading.rotated(turn)
	ctx.body.velocity.x = heading.x * speed
	ctx.body.velocity.z = heading.y * speed
	return heading


## Eases the body between upright and flat, and settles a waddle lean that
## this frame's gait did not refresh. Returns the blend.
func update_prone(ctx: TraversalContext) -> float:
	var target := 1.0 if (diving or sliding) else 0.0
	prone = move_toward(prone, target, PRONE_RATE * ctx.delta)
	if not _waddle_posed:
		waddle_roll = move_toward(waddle_roll, 0.0, WADDLE_ROLL * 4.0 * ctx.delta)
	_waddle_posed = false
	return prone


## The body's attitude this frame: how far it has tipped forward (0 upright,
## 1 flat on the belly) and the height it pivots about. The caller builds its
## own basis from these, because a penguin tips about its belly while its
## collision capsule stays upright.
func attitude() -> Dictionary:
	var tip := smoothstep(0.0, 1.0, prone)
	return {
		"tip": tip * PI * 0.5,
		"pivot_height": lerpf(BODY_PIVOT_HEIGHT, BELLY_REST_HEIGHT, tip),
		"roll": waddle_roll,
	}


## The waddle: short alternating steps with a small thigh lift, rolling the
## body from side to side. Only while upright on the feet.
func pose_waddle(ctx: TraversalContext, moving: bool) -> void:
	var rig := ctx.rig
	if rig == null or not waddling():
		return
	if moving:
		waddle_phase += ctx.delta * WADDLE_CADENCE * TAU
	var swing := sin(waddle_phase)
	waddle_roll = swing * WADDLE_ROLL
	_waddle_posed = true
	var t := minf(8.0 * ctx.delta, 1.0)
	for side in 2:
		var prefix := "leg_left" if side == 0 else "leg_right"
		var phase := swing if side == 0 else -swing
		var hip := rig.joint("%s_hip" % prefix)
		if hip != null:
			hip.rotation.x = lerp_angle(
				hip.rotation.x, -WADDLE_STEP * phase - WADDLE_THIGH_LIFT * maxf(phase, 0.0), t
			)
		var knee := rig.joint("%s_knee" % prefix)
		if knee != null:
			knee.rotation.x = lerp_angle(knee.rotation.x, WADDLE_KNEE * maxf(phase, 0.0), t)


func reset() -> void:
	diving = false
	sliding = false
	prone = 0.0
	waddle_roll = 0.0
	waddle_phase = 0.0
