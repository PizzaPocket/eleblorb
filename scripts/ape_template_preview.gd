class_name ApeTemplatePreview
extends StaticBody3D

## Minimal standalone instance of ApeTemplate for visual review -- per
## direct instruction ("we'll use it to build out some ape species after we
## get it right"), this is a first-pass pose/proportion check, not a
## finished creature. Wanders a small radius around its own spawn point so
## the walk cycle can actually be examined (per direct instruction), plus
## idle blink and (when has_tail is true) the tail's own idle sway. No
## talk prompt, no real AI. Once the proportions/pose read right, a real
## species script replaces this the same way jungle_villager.gd replaced
## an early monkey pass.

@export var fur_color: Color = MonkeyFigure.MONKEY_FUR_COLOR
@export var marking_color: Color = MonkeyFigure.MARKING_COLOR
@export var display_scale: float = 1.0
## false = ape, true = ApeTemplate's own "primate template" monkey variant
## (has a tail -- see that file's own class doc comment on the monkey/ape
## class split).
@export var has_tail: bool = false
## 0.0 (ectomorph) - 1.0 (extreme mesomorph), 0.5 is ApeTemplate's own
## established default build -- see that file's own CHEST_BUILD_SCALE_*
## doc comment.
@export var body_type: float = 0.5
## Multiplies ApeTemplate's own MONKEY_HEAD_SIZE_SCALE.y -- 1.0 is that
## file's own established default head proportions, higher grows a taller
## head within a range, per direct instruction.
@export var head_height_scale: float = 1.0
## Defaults per direct instruction ("leaning quite a bit forward at the
## hips... significantly bent [leg joints]... head tilted upward"). Per a
## later correction, the upward tilt should land exactly level with the
## horizon (simple cancellation of the spine lean), not past level -- see
## ApeTemplate's own SPINE_TILT_SHARES/total_tilt comment for how this
## factor is used (0.0 = cancel the lean exactly; >0.0 would tilt past
## level).
@export var spine_forward_bend: float = deg_to_rad(45.0)
## 0.0 here would hang the arm exactly straight down (fully canceling the
## spine lean, see ApeTemplate.build()'s own arm_rest_x formula); this
## tips it further forward past straight-down by this fraction of the
## lean angle. Brought down from an initial 0.35 per direct feedback that
## the arms hung too far forward for a natural resting pose.
@export var arm_forward_relax_factor: float = 0.15
@export var head_tilt_factor: float = 0.0

const ROAM_RADIUS := 10.0
const ROAM_PAUSE_MIN := 2.0
const ROAM_PAUSE_MAX := 5.0
const ROAM_ARRIVE_DISTANCE := 0.3
const ROAM_MOVE_SPEED := 1.3
const ROTATION_SPEED := 5.0
const GROUND_SETTLE_SPEED := 8.0

const WALK_SWING_SPEED := 6.0
const WALK_SWING_AMOUNT := 0.4
const POSE_SETTLE_SPEED := 8.0
## Knee/elbow bend curves below are ported straight from player.gd's own
## walk cycle (_animate_walk() there) rather than reinvented -- per direct
## instruction this rig's own cycle read as "very very simplified" next to
## the human figures'. Reused as relative offsets on top of THIS rig's own
## rest angles (permanent crouch/lean, captured below) instead of toward
## zero, and with the sprint-only pieces (stride easing, stance-phase knee
## bump, dorsiflex/plantarflex ankles, run body-bob) left out entirely --
## this rig has no sprint state to drive them. Swing/arm-swing were already
## a direct port (same sign convention, confirmed by player.gd's own
## already-verified comments); knee bend and elbow bend below are the new
## ports.

var _pivots: Dictionary
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()

var _terrain: Node
var _roam_center: Vector2
var _wander_target: Vector2
var _has_wander_target := false
var _pause_timer := 0.0
var _walk_phase := 0.0
var _rng := RandomNumberGenerator.new()

## Captured from the freshly-built rig, not hardcoded to 0.0 -- ApeTemplate.
## build() gives every one of these its own rest rotation.x for the crouch/
## lean pose (see that file's own doc comment); the walk cycle below must
## swing/settle around THESE values, not zero, or an idle lerp toward a
## hardcoded 0.0 would slowly undo the rest pose every time the ape stops
## moving (exactly the bug jungle_villager.gd's own _arm_rest_x fixes for
## the monkey NPCs).
var _leg_rest_x := 0.0
var _knee_rest_x := 0.0
var _ankle_rest_x := 0.0
var _arm_rest_x := 0.0
## Per direct instruction: the gait should be proportional to the
## instance's own relative size, not the same fixed ROAM_MOVE_SPEED/
## WALK_SWING_SPEED for every ape AND monkey regardless of how small the
## "primate template" monkey variant (has_tail=true) can get. Move speed
## scales DOWN with display_scale (a smaller body has shorter legs, so
## covers less ground per stride at the same cadence -- moving at the
## same fixed absolute speed as a much taller ape would either slide the
## feet or read as gliding); swing speed (cadence) scales UP inversely --
## real small animals take quicker, choppier steps, not slower ones.
## Computed once in _ready() from this instance's own display_scale, with
## 1.0 (roughly the ape range's own center) as the reference where both
## reduce to the original fixed constants unchanged.
var _move_speed := ROAM_MOVE_SPEED
var _swing_speed := WALK_SWING_SPEED
## No permanent elbow bend on this rig (unlike hip/knee/ankle) -- 0.0
## matches ProceduralFigure's own human elbow rest.
var _elbow_rest_x := 0.0
## Unlike _elbow_rest_x, THIS one isn't 0 -- ApeTemplate.build() gives the
## elbow its own permanent inward rest angle (ELBOW_INWARD_ANGLE, opposite-
## signed per side), so this has to be captured per side, same reasoning
## as every other _*_rest_* var above.
var _elbow_rest_z_left := 0.0
var _elbow_rest_z_right := 0.0


func _ready() -> void:
	_rng.randomize()
	_move_speed = ROAM_MOVE_SPEED * display_scale
	_swing_speed = WALK_SWING_SPEED / display_scale
	var variant := {
		"marking_color": marking_color,
		"spine_forward_bend": spine_forward_bend,
		"arm_forward_relax_factor": arm_forward_relax_factor,
		"head_tilt_factor": head_tilt_factor,
		"body_type": body_type,
		"head_height_scale": head_height_scale,
		"has_tail": has_tail,
	}
	_pivots = ApeTemplate.build(self, fur_color, display_scale, variant)
	_eyes = _pivots["eyes"]
	_leg_rest_x = (_pivots["leg_left"] as Node3D).rotation.x
	_knee_rest_x = (_pivots["knee_left"] as Node3D).rotation.x
	_ankle_rest_x = (_pivots["ankle_left"] as Node3D).rotation.x
	_arm_rest_x = (_pivots["arm_left"] as Node3D).rotation.x
	_elbow_rest_z_left = (_pivots["elbow_left"] as Node3D).rotation.z
	_elbow_rest_z_right = (_pivots["elbow_right"] as Node3D).rotation.z

	_terrain = get_node_or_null("../Terrain")
	if _terrain != null and _terrain.has_method("get_mesh_height"):
		global_position.y = _terrain.get_mesh_height(global_position.x, global_position.z)
	_roam_center = Vector2(global_position.x, global_position.z)
	_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)

	var collision_shape := CollisionShape3D.new()
	var collider := CapsuleShape3D.new()
	collider.radius = 0.35 * display_scale
	collider.height = 1.5 * display_scale
	collision_shape.shape = collider
	collision_shape.position = Vector3(0, 0.9 * display_scale, 0)
	add_child(collision_shape)
	collision_layer = 1
	collision_mask = 0


func _process(delta: float) -> void:
	EyeBlink.apply(_eye_blink, delta, _eyes)
	var moving := _update_roam(delta)
	_animate_walk(delta, moving)
	if has_tail:
		MonkeyFigure._rebuild_tail(_pivots["_tail"] as Dictionary, delta)


func _update_roam(delta: float) -> bool:
	var here := Vector2(global_position.x, global_position.z)
	var moving := false
	if _has_wander_target and here.distance_to(_wander_target) > ROAM_ARRIVE_DISTANCE:
		moving = true
	elif _has_wander_target:
		_has_wander_target = false
		_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)
	else:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_pick_new_wander_target()

	if moving:
		var to_target := _wander_target - here
		var step := to_target.limit_length(_move_speed * delta)
		var new_pos := here + step
		if to_target.length() > 0.01:
			var target_angle := atan2(to_target.x, to_target.y)
			rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)
		global_position.x = new_pos.x
		global_position.z = new_pos.y

	if _terrain != null and _terrain.has_method("get_mesh_height"):
		var ground_h: float = _terrain.get_mesh_height(global_position.x, global_position.z)
		global_position.y = move_toward(global_position.y, ground_h, GROUND_SETTLE_SPEED * delta)
	return moving


func _pick_new_wander_target() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var r := ROAM_RADIUS * sqrt(_rng.randf())
	_wander_target = _roam_center + Vector2(cos(angle), sin(angle)) * r
	_has_wander_target = true


func _animate_walk(delta: float, moving: bool) -> void:
	var leg_left := _pivots["leg_left"] as Node3D
	var leg_right := _pivots["leg_right"] as Node3D
	var knee_left := _pivots["knee_left"] as Node3D
	var knee_right := _pivots["knee_right"] as Node3D
	var ankle_left := _pivots["ankle_left"] as Node3D
	var ankle_right := _pivots["ankle_right"] as Node3D
	var arm_left := _pivots["arm_left"] as Node3D
	var arm_right := _pivots["arm_right"] as Node3D
	var elbow_left := _pivots["elbow_left"] as Node3D
	var elbow_right := _pivots["elbow_right"] as Node3D
	if moving:
		_walk_phase += delta * _swing_speed
		var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
		leg_left.rotation.x = _leg_rest_x + swing
		leg_right.rotation.x = _leg_rest_x - swing
		arm_left.rotation.x = _arm_rest_x - swing
		arm_right.rotation.x = _arm_rest_x + swing
		# Knee flex tied to each leg's own swing VELOCITY (cos of phase),
		# not position -- ported from player.gd's own walk cycle (see that
		# file's own comment: bending in step with position alone barely
		# reads as distinct from the swing itself). Same phase convention
		# as player.gd's already-confirmed left/right pairing (this rig's
		# leg_left uses +swing, matching player.gd's _leg_left, so the
		# same cos(phase+PI)/cos(phase) split applies unchanged) -- added
		# on top of this rig's own permanent crouch rest instead of
		# player.gd's near-straight rest.
		var left_knee_bump := maxf(0.0, cos(_walk_phase + PI)) * ProceduralFigure.KNEE_BEND_AMOUNT
		var right_knee_bump := maxf(0.0, cos(_walk_phase)) * ProceduralFigure.KNEE_BEND_AMOUNT
		knee_left.rotation.x = _knee_rest_x + left_knee_bump
		knee_right.rotation.x = _knee_rest_x + right_knee_bump
		ankle_left.rotation.x = _ankle_rest_x - swing * 0.3
		ankle_right.rotation.x = _ankle_rest_x + swing * 0.3
		# Elbow's own contribution to the stride, per direct correction: NOT
		# a forward/back bend (rotation.x, the original ported-from-player.
		# gd curve) any more -- the forearm now swings further INWARD
		# (toward the body) and back to resting instead, on rotation.z, the
		# same axis ELBOW_INWARD_ANGLE's own permanent rest pose already
		# uses (ape_template.gd's build()). "Further inward" = more of
		# whatever sign that rest pose already is, so multiplying by
		# signf(_elbow_rest_z_*) keeps this correct on both sides without
		# hardcoding which side is positive. rotation.x itself just stays
		# at rest the whole time now (also true in the idle branch below),
		# no longer animated during the stride at all. Reuses the same
		# forward_fraction shape (least at each arm's own backmost swing
		# point, most at its own forwardmost) and the same ELBOW_BEND_
		# AMOUNT magnitude the old curve used, just applied to a different
		# axis -- not visually confirmed.
		var right_forward_fraction := (1.0 - sin(_walk_phase)) * 0.5
		var left_forward_fraction := 1.0 - right_forward_fraction
		elbow_right.rotation.x = _elbow_rest_x
		elbow_left.rotation.x = _elbow_rest_x
		elbow_right.rotation.z = (
			_elbow_rest_z_right
			+ right_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT * signf(_elbow_rest_z_right)
		)
		elbow_left.rotation.z = (
			_elbow_rest_z_left
			+ left_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT * signf(_elbow_rest_z_left)
		)
	else:
		leg_left.rotation.x = lerp_angle(leg_left.rotation.x, _leg_rest_x, POSE_SETTLE_SPEED * delta)
		leg_right.rotation.x = lerp_angle(leg_right.rotation.x, _leg_rest_x, POSE_SETTLE_SPEED * delta)
		knee_left.rotation.x = lerp_angle(knee_left.rotation.x, _knee_rest_x, POSE_SETTLE_SPEED * delta)
		knee_right.rotation.x = lerp_angle(knee_right.rotation.x, _knee_rest_x, POSE_SETTLE_SPEED * delta)
		ankle_left.rotation.x = lerp_angle(ankle_left.rotation.x, _ankle_rest_x, POSE_SETTLE_SPEED * delta)
		ankle_right.rotation.x = lerp_angle(ankle_right.rotation.x, _ankle_rest_x, POSE_SETTLE_SPEED * delta)
		arm_left.rotation.x = lerp_angle(arm_left.rotation.x, _arm_rest_x, POSE_SETTLE_SPEED * delta)
		arm_right.rotation.x = lerp_angle(arm_right.rotation.x, _arm_rest_x, POSE_SETTLE_SPEED * delta)
		elbow_left.rotation.x = lerp_angle(elbow_left.rotation.x, _elbow_rest_x, POSE_SETTLE_SPEED * delta)
		elbow_right.rotation.x = lerp_angle(elbow_right.rotation.x, _elbow_rest_x, POSE_SETTLE_SPEED * delta)
		elbow_left.rotation.z = lerp_angle(elbow_left.rotation.z, _elbow_rest_z_left, POSE_SETTLE_SPEED * delta)
		elbow_right.rotation.z = lerp_angle(elbow_right.rotation.z, _elbow_rest_z_right, POSE_SETTLE_SPEED * delta)
