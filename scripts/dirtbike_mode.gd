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

## How far ahead of the wheels the grade is read. A property of the ground
## rather than of the rider, so it does not scale with the rig: sampled over a
## shorter baseline, ordinary terrain noise reads as a steep climb, and the
## crest latch then throws the bike off every ripple. A quarter-size rider
## measuring over 0.2 m rode the dirt course at 100 m/s for exactly that
## reason, against the human's 13.
const SLOPE_SAMPLE_DISTANCE := 0.6

## A tracked climb hands its own measured motion over as a launch when the
## support falls away; below this grade the wheels are not climbing anything.
const ASCEND_TRACK_THRESHOLD := 0.02
## About 12% more vertical takeoff speed (sqrt(1.25)) off a crest, without
## altering the horizontal component or the terrain-derived direction.
const JUMP_HEIGHT_MULTIPLIER := 1.25

var smoothed_grade := 0.0
## The crest latch and the air it produces: whether the wheels were climbing
## last frame, and whether they are off the ground now.
var was_climbing := false
var airborne := false
var surface_velocity := Vector3.ZERO


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


## The grade along `direction` at the body's feet.
static func slope_along(terrain: Node, at: Vector3, direction: Vector2) -> float:
	if terrain == null or direction.length_squared() < 0.0001:
		return 0.0
	var aim := direction.normalized()
	var here: float = terrain.get_mesh_height(at.x, at.z)
	var ahead: float = terrain.get_mesh_height(
		at.x + aim.x * SLOPE_SAMPLE_DISTANCE, at.z + aim.y * SLOPE_SAMPLE_DISTANCE
	)
	return (ahead - here) / SLOPE_SAMPLE_DISTANCE


## One frame of ground contact under the wheels. `target_h` is the terrain
## beneath them, `foot_offset` how far the body's origin rides above its
## feet, and `travel_slope` the grade along the direction of travel, which
## each rig measures its own way.
##
## Climbing is tracked rather than followed: the motion that actually
## occurred is measured while the wheels climb, and handed over whole as a
## real arc the moment the support falls away. That is what makes a crest
## throw the bike rather than glue it to the far side.
##
## Returns true if the bike left the ground this frame, so the caller can
## mark its own jump state.
func follow_terrain(
	ctx: TraversalContext, target_h: float, foot_offset: float,
	travel_slope: float, pre_move_position: Vector3
) -> bool:
	var body := ctx.body
	var feet_y: float = body.global_position.y - foot_offset
	if airborne:
		# Already flying. An arc in progress is nobody else's to rewrite:
		# measuring the ground again mid-flight is what used to feed a launch
		# back into itself, each pass reading the last one's motion as more
		# climb and throwing the bike harder than the one before.
		if feet_y <= target_h:
			body.global_position.y = target_h + foot_offset
			body.velocity.y = 0.0
			airborne = false
		elif body.is_on_floor() and body.velocity.y <= 0.0:
			airborne = false
		return false
	if travel_slope > ASCEND_TRACK_THRESHOLD:
		# Resolve onto the support, then measure the whole motion that
		# actually occurred this frame. Y in particular is a real change in
		# position over time, not a value anyone chose.
		was_climbing = true
		airborne = false
		body.global_position.y = target_h + foot_offset
		surface_velocity = HumanoidLocomotion.resolved_velocity(
			pre_move_position, body.global_position, ctx.delta
		)
		body.velocity.y = surface_velocity.y
		return false
	if was_climbing:
		# The support has fallen away from under a climb: keep both the
		# horizontal velocity and the full vertical tangent.
		was_climbing = false
		airborne = true
		body.velocity = surface_velocity
		body.velocity.y *= sqrt(JUMP_HEIGHT_MULTIPLIER)
		return true
	was_climbing = false
	if target_h - feet_y >= 0.0:
		# Level or rising ground that is not a tracked climb stays attached.
		body.global_position.y = target_h + foot_offset
		body.velocity.y = 0.0
		airborne = false
		return false
	# Per direct correction ("even when cresting smaller hills at speed he
	# should still get airtime according to the laws of physics -- his
	# downward translation should never exceed the speed his body would be
	# falling from gravity") -- every frame from here is a real
	# gravity-integrated fall compared against the actual terrain height,
	# rather than a slope-ratio threshold or a hang-time timer, both of which
	# were tried and replaced. A slope gentle enough for gravity to keep pace
	# with reads as hugging the downhill, because the predicted fall lands at
	# or past the terrain almost every frame; a drop steeper than gravity can
	# match falls behind it, producing real air that scales with exactly how
	# far the terrain outpaces gravity. That scales to any hill, with no
	# separate constant for small ones and large ones.
	body.velocity.y = HumanoidLocomotion.apply_gravity(
		body.velocity.y, ctx.delta, ctx.profile, Player.TERMINAL_FALL_SPEED
	)
	var predicted := feet_y + body.velocity.y * ctx.delta
	if predicted > target_h:
		body.global_position.y = predicted + foot_offset
		airborne = true
		return false
	body.global_position.y = target_h + foot_offset
	body.velocity.y = 0.0
	airborne = false
	return false


func reset() -> void:
	smoothed_grade = 0.0
	was_climbing = false
	airborne = false
	surface_velocity = Vector3.ZERO
