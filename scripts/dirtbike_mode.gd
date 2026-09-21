class_name DirtbikeMode
extends TraversalMode

## The dirt bike, shared by every character
## (docs/traversal_powers_architecture.md).
##
## Two wheels and a throttle behave the same under anybody. What differs per
## character is the pose on the bike and how each rig finds the grade beneath
## it, so those stay with the rider; the wheel dynamics live here.
##
## Powered travel accelerates toward its target rather than reaching full
## speed on the first input frame. With the drive released, gravity along the
## slope, rolling resistance and quadratic air drag are integrated
## continuously, so a bike coasts down a hill and dies out on the flat.

const DRIVE_ACCELERATION := 22.0
## Tire traction is deliberately balanced: ordinary steering carries speed,
## while a perpendicular carve scrubs and a full reversal brakes decisively.
const LATERAL_GRIP := 36.0
const REVERSE_BRAKING := 30.0
const ROLLING_RESISTANCE := 0.16
const AIR_DRAG := 0.011
const ROLL_STOP_SPEED := 0.12
const TERMINAL_ROLL_SPEED := 34.0
## How quickly the grade under the wheels is believed, so a single rough
## triangle does not read as a hill.
const GRADE_RESPONSE := 7.0

var smoothed_grade := 0.0


func id() -> StringName:
	return &"dirtbike"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null and ctx.suit.has_dirtbike_legs()


## Under throttle: steer and accelerate the wheels toward what the rider asks
## for, losing speed to a carve or a reversal rather than to a clamp.
func drive(rolling: Vector2, wanted: Vector2, speed: float, delta: float) -> Vector2:
	return HumanoidLocomotion.drive_wheel_velocity(
		rolling, wanted, speed, delta,
		DRIVE_ACCELERATION, LATERAL_GRIP, REVERSE_BRAKING, ROLL_STOP_SPEED
	)


## Off the throttle: the slope, the tires and the air decide. `sampled_grade`
## is this frame's raw grade along travel, which each rig measures its own
## way; the smoothing belongs to the bike and lives here.
func coast(rolling: Vector2, sampled_grade: float, delta: float, grounded: bool) -> Vector2:
	smoothed_grade = lerpf(
		smoothed_grade, sampled_grade if grounded else 0.0,
		minf(GRADE_RESPONSE * delta, 1.0)
	)
	return HumanoidLocomotion.coast_wheel_velocity(
		rolling, smoothed_grade if grounded else 0.0, delta,
		ROLLING_RESISTANCE if grounded else 0.0, AIR_DRAG,
		ROLL_STOP_SPEED, TERMINAL_ROLL_SPEED
	)


func reset() -> void:
	smoothed_grade = 0.0
