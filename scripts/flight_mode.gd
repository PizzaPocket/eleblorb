class_name FlightMode
extends TraversalMode

## Suit flight, shared by every character
## (docs/traversal_powers_architecture.md).
##
## Flying has the same two behaviours swimming does, and for the same reason:
## a flier holding station hangs upright, while one under way lies along its
## travel and trails. Xiao Hou Zi flew bolt upright wherever he went, because
## his flight only bent his spine by the stick's vertical component and never
## turned his body at all.
##
## As elsewhere, the mode reports the attitude and each character applies it
## its own way: the human pivots about the skull so the camera keeps its
## distance from the head, while a smaller rig simply turns.

const MOVING_SPEED := 0.6
const MOTION_BLEND_RATE := 2.2
## How far over a flier lies at full cruise, and how sharply it may point up
## or down when climbing or diving.
const CRUISE_LEAN := deg_to_rad(78.0)
const PITCH_LIMIT := deg_to_rad(80.0)

## Deliberate jump toggle; wearing the chest alone leaves ordinary locomotion.
var enabled := false
var toggle_consumed := false


func toggle(ctx: TraversalContext, pressed: bool, allowed: bool = true) -> bool:
	toggle_consumed = false
	if ctx.suit == null or not ctx.suit.has_chest_air_blorb():
		enabled = false
	elif pressed and allowed:
		enabled = not enabled
		toggle_consumed = true
	return enabled and allowed


var motion := 0.0
var liquid_exit_active := false


## A surface breach, not underwater flight. Keep it latched through the
## body's passage across the plane, so the swim clamp cannot recapture it.
func update_liquid_exit(ctx: TraversalContext, liquid: LiquidEnvironment, head_base: float, foot_offset: float) -> bool:
	var feet_y := ctx.body.global_position.y - foot_offset
	if liquid.liquid == LiquidEnvironment.Liquid.NONE or feet_y > liquid.surface_height + ctx.scaled(0.08):
		liquid_exit_active = false
		return false
	var upward := ctx.direction.y > 0.05 or ctx.jump_pressed
	var lift := ctx.suit != null and (ctx.suit.has_chest_air_blorb() or ctx.suit.has_air_hover_legs() or _fire_lift_requested(ctx))
	if not upward or not lift:
		liquid_exit_active = false
		return false
	var surface_band := liquid.surface_height - LiquidEnvironment.float_depth(head_base) - ctx.scaled(0.1)
	liquid_exit_active = liquid_exit_active or feet_y >= surface_band
	return liquid_exit_active


func apply_liquid_exit(ctx: TraversalContext) -> void:
	if liquid_exit_active:
		ctx.body.velocity.y = maxf(ctx.body.velocity.y, ctx.scaled(3.5))


## Fire remains usable while wading with the body above water, and in lava.
## Immersed water disables it except during the bounded surface breach.
func suppress_fire(liquid: LiquidEnvironment, immersed: bool) -> bool:
	return liquid.in_water() and immersed and not liquid_exit_active


static func _fire_lift_requested(ctx: TraversalContext) -> bool:
	if UIState.modal_open:
		return false
	var suit := ctx.suit
	for pair in [["arm_left", "arm_right", "left_arm_power", "right_arm_power"],
		["leg_left", "leg_right", "left_leg_power", "right_leg_power"]]:
		if pair[0] == "arm_left" and (ctx.left_arm_busy or ctx.right_arm_busy):
			continue
		var left := suit.worn_blorb_in_slot(pair[0])
		var right := suit.worn_blorb_in_slot(pair[1])
		if left != null and right != null and left.element_state == "fire" and right.element_state == "fire" and left.current_mp > 0.0 and right.current_mp > 0.0 and Input.is_action_pressed(pair[2]) and Input.is_action_pressed(pair[3]):
			return true
	return false


func id() -> StringName:
	return &"flight"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null


## Eases between holding station and cruising, on how fast the body is
## actually travelling rather than on what is being asked of it.
func update_motion(ctx: TraversalContext) -> void:
	var wants := 1.0 if ctx.body.velocity.length() > MOVING_SPEED else 0.0
	motion = move_toward(motion, wants, MOTION_BLEND_RATE * ctx.delta)


## How far over the body lies right now. Nothing while holding station, the
## full cruise lean under way, tilted by how steeply the travel climbs or
## dives.
func attitude_pitch(travel: Vector3) -> float:
	if motion <= 0.001:
		return 0.0
	var flat := Vector2(travel.x, travel.z).length()
	var climb := 0.0
	if flat > 0.0001 or absf(travel.y) > 0.0001:
		climb = atan2(travel.y, flat)
	return clampf(CRUISE_LEAN * motion - climb, -PITCH_LIMIT, PITCH_LIMIT)


func reset() -> void:
	motion = 0.0
	liquid_exit_active = false
