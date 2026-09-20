class_name CrystalSkateMode
extends TraversalMode

## Riding the crystal track on Crystal Skates, shared by every character
## (docs/traversal_powers_architecture.md).
##
## Unlike skating or the snowboard, this one TAKES THE FRAME: while riding,
## the track is the ground, the rider's position is a distance along it, and
## ordinary movement does not run at all. So it is the shape the director was
## built for -- update() returns true when it owned the frame.
##
## It owns the track, the heading, the speed and the body pitch. Posing and
## audio stay with the caller, which knows its own rig and animation.

const SPEED_MULTIPLIER := 1.4
const SPRINT_MULTIPLIER := 1.5
const ACCELERATION := 26.0
const COAST_FRICTION := 18.0
const TURN_RATE := 2.6
const RESTART_ANGLE := deg_to_rad(55.0)
const MAX_PITCH := deg_to_rad(60.0)
## The body pitches with the track by this fraction of its climb or dive, and
## eases toward that at this rate.
const BODY_PITCH_FRACTION := 0.5
const BODY_PITCH_RATE := 4.0

var riding := false
var airborne := false
var speed := 0.0
var heading := Vector3.ZERO
var body_pitch := 0.0
var track: CrystalTrack = null


func id() -> StringName:
	return &"crystal_skates"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null and ctx.suit.has_crystal_skates()


## Where the rider is steering, in three dimensions: the aim direction,
## pitched no more steeply than the track can climb or dive.
func wanted_direction(ctx: TraversalContext, stick: Vector2) -> Vector3:
	if stick.length_squared() < 0.04 or ctx.aim_basis == Basis():
		return Vector3.ZERO
	var direction := ctx.aim_basis.x * stick.x + ctx.aim_basis.z * stick.y
	if direction.length_squared() < 0.0001:
		return Vector3.ZERO
	direction = direction.normalized()
	var pitch := clampf(asin(clampf(direction.y, -1.0, 1.0)), -MAX_PITCH, MAX_PITCH)
	var flat := Vector2(direction.x, direction.z)
	if flat.length_squared() < 0.0001:
		return Vector3.ZERO
	flat = flat.normalized() * cos(pitch)
	return Vector3(flat.x, sin(pitch), flat.y)


## Starts a fresh track under the rider's feet, setting off level in the
## wanted direction: the climb or dive then bends in smoothly.
func begin(ctx: TraversalContext, wanted: Vector3, foot_offset: float) -> void:
	var world := ctx.body.get_tree().current_scene
	if world == null:
		return
	if is_instance_valid(track):
		track.riding = false
	track = CrystalTrack.new()
	world.add_child(track)
	track.begin(ctx.body.global_position - Vector3.UP * foot_offset)
	track.riding = true
	riding = true
	speed = maxf(Vector2(ctx.body.velocity.x, ctx.body.velocity.z).length(), 0.0)
	heading = Vector3(wanted.x, 0.0, wanted.z).normalized()
	if heading.length_squared() < 0.0001:
		heading = Vector3.FORWARD


## The velocity the rider leaves the track with, recorded as the ride ends so
## the caller can hand it to the body along with any jump of its own.
var exit_velocity := Vector3.ZERO


func end(keep_momentum: bool) -> void:
	exit_velocity = Vector3.ZERO
	if is_instance_valid(track):
		track.riding = false
		exit_velocity = track.rider_tangent() * speed
	riding = false
	airborne = true
	if not keep_momentum:
		speed = 0.0
		exit_velocity = Vector3.ZERO


## One frame of the ride. Returns true when it owned the frame, in which case
## the caller poses and does nothing else. `blocked` is the caller saying
## something else already owns this body.
func ride(ctx: TraversalContext, stick: Vector2, jump_pressed: bool, blocked: bool, foot_offset: float) -> bool:
	var available := is_available(ctx) and not blocked
	if riding and not available:
		end(false)
	if not riding:
		body_pitch = move_toward(body_pitch, 0.0, BODY_PITCH_RATE * ctx.delta)
		var wanted_start := wanted_direction(ctx, stick)
		if not (available and ctx.grounded and wanted_start != Vector3.ZERO):
			return false
		begin(ctx, wanted_start, foot_offset)
	if jump_pressed:
		end(true)
		return false
	var wanted := wanted_direction(ctx, stick)
	if wanted != Vector3.ZERO:
		var turn := heading.angle_to(wanted)
		if speed < 1.0 and turn > RESTART_ANGLE:
			track.truncate_ahead()
			heading = wanted
		elif turn > 0.0001:
			heading = heading.slerp(wanted, minf(TURN_RATE * ctx.delta / turn, 1.0)).normalized()
		# The ordinary skates' own top speed, then the crystal boost, and the
		# sprint boost on top of that.
		var skate_speed := minf(
			HumanoidLocomotion.ground_speed(ctx.profile, false)
			* IceSkateMode.SPEED_MULTIPLIER * ctx.leg_speed_multiplier,
			IceSkateMode.TERMINAL_SPEED
		)
		var top_speed := skate_speed * SPEED_MULTIPLIER * (SPRINT_MULTIPLIER if ctx.sprinting else 1.0)
		speed = move_toward(speed, top_speed, ACCELERATION * ctx.delta)
	else:
		speed = move_toward(speed, 0.0, COAST_FRICTION * ctx.delta)
	if track.is_blocked() and heading.angle_to(track.lead_direction()) > 0.3:
		track.clear_block()
	var rids: Array[RID] = [ctx.body.get_rid()]
	track.extend(heading, ctx.terrain, ctx.body.get_world_3d().direct_space_state, rids)
	if track.advance(speed * ctx.delta) > 0.0:
		speed = 0.0
	ctx.body.global_position = track.rider_point() + Vector3.UP * foot_offset
	var tangent := track.rider_tangent()
	ctx.body.velocity = tangent * speed
	var climb := asin(clampf(tangent.y, -1.0, 1.0)) if tangent != Vector3.ZERO else 0.0
	body_pitch = move_toward(body_pitch, climb * BODY_PITCH_FRACTION, BODY_PITCH_RATE * ctx.delta)
	return true


## The heading to face while riding, or zero where the track has none yet.
func facing() -> Vector3:
	if not is_instance_valid(track):
		return Vector3.ZERO
	var tangent := track.rider_tangent()
	return tangent if Vector2(tangent.x, tangent.z).length_squared() > 0.01 else Vector3.ZERO
