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

var motion := 0.0


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
