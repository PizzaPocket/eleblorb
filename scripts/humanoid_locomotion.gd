class_name HumanoidLocomotion
extends RefCounted

## Pure tuning/formula layer shared by every humanoid pawn. It intentionally
## owns no nodes or state: each real body keeps its own velocity, contacts,
## environment state, and animation pivots.


static func ground_speed(profile: PlayableCharacterProfile, sprinting: bool) -> float:
	return profile.move_speed * (profile.sprint_multiplier if sprinting else 1.0)


static func jump_speed(profile: PlayableCharacterProfile, height_multiplier: float = 1.0) -> float:
	return profile.jump_speed * sqrt(height_multiplier)


static func apply_gravity(
	vertical_velocity: float,
	delta: float,
	profile: PlayableCharacterProfile,
	terminal_speed: float
) -> float:
	var gravity := float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	return maxf(vertical_velocity - gravity * profile.gravity_scale * delta, -terminal_speed)


## Derives the complete world-space velocity from motion that was actually
## resolved. This stays useful across height fields, collision meshes, moving
## platforms, vehicles, and future nonstandard gravity: callers preserve the
## vector rather than reconstructing one axis from a terrain sample.
static func resolved_velocity(previous_position: Vector3,current_position: Vector3,delta: float) -> Vector3:
	if delta <= 0.000001:
		return Vector3.ZERO
	return (current_position-previous_position)/delta


## Free-rolling motion along the current ground tangent. `grade` is rise/run
## measured in the direction of travel: gravity accelerates downhill and
## retards uphill, rolling resistance scales with the surface-normal force,
## and quadratic drag grows naturally at high speed. There is no authored
## stop distance or input-duration switch in this model.
static func coast_wheel_velocity(
	planar_velocity: Vector2,grade: float,delta: float,
	rolling_resistance: float,drag_coefficient: float,stop_speed: float,
	terminal_speed: float
) -> Vector2:
	var speed:=planar_velocity.length()
	if speed<=stop_speed:
		return Vector2.ZERO
	var gravity:=float(ProjectSettings.get_setting("physics/3d/default_gravity",9.8))
	var normalizer:=sqrt(1.0+grade*grade)
	var sin_angle:=grade/normalizer
	var cos_angle:=1.0/normalizer
	var acceleration_along: float=(
		-gravity*sin_angle
		-rolling_resistance*gravity*cos_angle
		-drag_coefficient*speed*speed
	)
	var next_speed:=clampf(speed+acceleration_along*delta,0.0,terminal_speed)
	return planar_velocity.normalized()*next_speed if next_speed>stop_speed else Vector2.ZERO


## Powered rolling with directional tire traction. Momentum is decomposed
## relative to the requested steering direction: sideways velocity is scrubbed
## by tire friction, while velocity pointing opposite the wheels must brake to
## zero before drive can accelerate in the new direction. A shallow steering
## change therefore preserves most speed; a hard turn or reversal sheds much
## more energy without ever snapping the velocity vector.
static func drive_wheel_velocity(
	planar_velocity: Vector2,steering_direction: Vector2,target_speed: float,
	delta: float,drive_acceleration: float,lateral_grip: float,
	reverse_braking: float,stop_speed: float
) -> Vector2:
	if steering_direction.length_squared()<=0.000001:
		return planar_velocity
	var forward:=steering_direction.normalized()
	var original_speed:=planar_velocity.length()
	var forward_speed:=planar_velocity.dot(forward)
	var lateral_velocity:=planar_velocity-forward*forward_speed
	var lateral_speed:=lateral_velocity.length()
	if lateral_speed>0.0:
		# Slip ratio follows |sin(turn angle)|: zero for aligned or exactly
		# reversed wheels, strongest at a perpendicular carve. High slip loads
		# the tire more heavily than a shallow correction.
		var slip_ratio:=lateral_speed/maxf(original_speed,0.001)
		var scrub_acceleration:=lateral_grip*lerpf(0.35,1.0,slip_ratio)
		var scrubbed_speed:=move_toward(lateral_speed,0.0,scrub_acceleration*delta)
		lateral_velocity*=scrubbed_speed/lateral_speed
	if forward_speed < -stop_speed:
		# Reversing the controls while still travelling forward is braking,
		# not instantaneous reverse thrust.
		forward_speed=move_toward(forward_speed,0.0,reverse_braking*delta)
	elif original_speed<=stop_speed or lateral_speed/original_speed<0.45:
		# Do not add fresh perpendicular thrust during a severe skid. The old
		# kinetic energy must be absorbed first; gentle steering retains drive.
		forward_speed=move_toward(maxf(forward_speed,0.0),target_speed,drive_acceleration*delta)
	return forward*forward_speed+lateral_velocity


## Passive board/sled motion on a supporting plane. Gravity is projected
## onto the plane so a stationary rider starts moving downhill naturally.
## Steering can rotate and scrub existing momentum, but never manufactures
## speed; releasing the stick therefore leaves a physically coasting body.
static func gravity_surface_glide(
	planar_velocity: Vector2,surface_normal: Vector3,steering_direction: Vector2,
	delta: float,rolling_resistance: float,drag_coefficient: float,
	turn_rate: float,carve_grip: float,stop_speed: float,terminal_speed: float,
	gravity_scale: float=1.0
) -> Vector2:
	var normal:=surface_normal.normalized()
	var gravity_strength:=float(ProjectSettings.get_setting("physics/3d/default_gravity",9.8))*gravity_scale
	var gravity_vector:=Vector3.DOWN*gravity_strength
	var tangent_gravity:=gravity_vector-normal*gravity_vector.dot(normal)
	var result:=planar_velocity+Vector2(tangent_gravity.x,tangent_gravity.z)*delta
	var speed:=result.length()
	if speed>stop_speed and steering_direction.length_squared()>0.000001:
		var current_angle:=result.angle()
		var desired_angle:=steering_direction.normalized().angle()
		var difference:=wrapf(desired_angle-current_angle,-PI,PI)
		var turn:=clampf(difference,-turn_rate*delta,turn_rate*delta)
		var scrub:=carve_grip*absf(sin(difference))*delta
		speed=maxf(speed-scrub,0.0)
		result=Vector2.from_angle(current_angle+turn)*speed
	if speed>0.0:
		var normal_force_ratio:=clampf(normal.dot(Vector3.UP),0.0,1.0)
		var deceleration:=(rolling_resistance*gravity_strength*normal_force_ratio+drag_coefficient*speed*speed)*delta
		var next_speed:=clampf(speed-deceleration,0.0,terminal_speed)
		result=result.normalized()*next_speed if next_speed>stop_speed else Vector2.ZERO
	return result


## Advances a true ballistic arc: the launch X/Z components are immutable;
## only gravity changes Y. Movement-mode owners can opt into this while still
## using live input independently for visual facing or other non-force intent.
static func ballistic_step(
	launch_velocity: Vector3,delta: float,profile: PlayableCharacterProfile,
	terminal_speed: float
) -> Vector3:
	var result:=launch_velocity
	result.y=apply_gravity(result.y,delta,profile,terminal_speed)
	return result


static func walk_phase_step(
	delta: float,
	base_swing_speed: float,
	horizontal_speed: float,
	profile: PlayableCharacterProfile,
	sprint_cadence_scale: float = 1.0
) -> float:
	return delta * base_swing_speed * horizontal_speed * profile.walk_cadence_scale * sprint_cadence_scale


static func blorb_speed_multiplier(blorbs: Array, per_point: float) -> float:
	if blorbs.is_empty():
		return 1.0
	var points := 0
	for blorb: Node in blorbs:
		if is_instance_valid(blorb):
			points += int(blorb.get("speed"))
	return 1.0 + float(points) * per_point


static func averaged_blorb_speed_multiplier(blorbs: Array, per_point: float) -> float:
	if blorbs.is_empty():
		return 1.0
	var points := 0
	var contributors := 0
	for blorb: Node in blorbs:
		if is_instance_valid(blorb):
			points += int(blorb.get("speed"))
			contributors += 1
	return 1.0 if contributors == 0 else 1.0 + (float(points) / float(contributors)) * per_point
