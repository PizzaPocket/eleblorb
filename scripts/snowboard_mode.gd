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


func reset() -> void:
	airborne = false
	ground_latch = 0.0
