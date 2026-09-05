class_name Manchego
extends StaticBody3D

## Manchego, the Primate Kingdom's horse mount (see docs/world_bible.md's
## own Mounts section) -- spawned in the Primate Kingdom's own village (see
## jungle_kingdom_village.gd's own _build_manchego_and_quest_ape()), idling
## in place (follows_player starts false) and ridden by a quest-giving ape
## until the placeholder "special banana" quest hands him over to the player
## (follows_player/available_to_player both flip true; see those vars' own
## doc comments).
##
## Built as a standalone StaticBody3D mirroring blorb.gd's/xiao_hou_zi.gd's
## own architecture (manual XZ position updates every frame, no
## CharacterBody3D/move_and_slide) -- see this project's own memory notes on
## why AnimatableBody3D/CharacterBody3D-driven NPCs are the wrong tool here.
##
## Possession mirrors Blorbus, NOT Xiao Hou Zi's reskin-in-place trick --
## per direct design note in the world bible ("similar in spirit"), but
## Manchego's rig is a genuine quadruped with no biped arm_left/arm_right-
## style pivot contract for player.gd's existing walk-cycle code to drive,
## so reskinning the human CharacterBody as him isn't viable the way it is
## for Xiao Hou Zi (see player.gd's own _try_start_xiao_hou_zi_control() doc
## comment for why THAT one gets swimming/flight/blorb-suit compatibility
## "for free" -- none of that matters yet for a ground-only horse). Instead,
## player.gd drives this body directly via drive_from_player() every physics
## frame while the human CharacterBody follows at a loose distance, exactly
## like _update_blorbus_control() already does for Blorbus/the giant.
## Mounting happens via a "Ride Manchego" Interactable prompt (per direct
## instruction) rather than the B-key cycle Blorbus/Xiao Hou Zi share;
## pressing that same contextual Interact control again dismounts; the
## separate Blorbus-switch control remains dedicated to psychic possession.

const INTERACT_RADIUS := 2.5
const HEAD_YAW_LIMIT := deg_to_rad(50.0)
const HEAD_TURN_SPEED := 8.0

## Loyal-companion follow, not a discover/bond/roam state machine like
## blorb.gd's/xiao_hou_zi.gd's own wild-creature AI -- Manchego is already
## "with" the player from the moment he exists, so there's no undiscovered
## state to model, just "walk to keep up, stop once close."
const FOLLOW_DISTANCE := 6.0
const ARRIVE_DISTANCE := 3.0
const FOLLOW_MOVE_SPEED := 2.6
const ROTATION_SPEED := 5.0
const GROUND_SETTLE_SPEED := 8.0

## Ambient "grazing" wander for follows_player == false -- see that var's own
## doc comment. A slower amble around a fixed anchor point, not the loyal-
## companion follow above; deliberately gentle/first-draft, adjustable on
## report like every other unspecified magnitude in this rig.
const IDLE_WANDER_RADIUS := 4.0
const IDLE_WANDER_MOVE_SPEED := 0.9
const IDLE_PAUSE_MIN := 3.0
const IDLE_PAUSE_MAX := 7.0
const IDLE_ARRIVE_DISTANCE := 0.3

## "Faster ground movement," per docs/world_bible.md's own Mounts entry --
## multiplies the human player's own move_speed while ridden, the same
## movement_speed_multiplier idiom blorb.gd's drive_from_player() uses.
const RIDE_SPEED_MULTIPLIER := 1.7

const GAIT_CYCLE_SPEED := 7.0
## Below this planar speed the gait is treated as "not moving" and eases
## back to a standing rest pose instead of visibly trotting in place.
const GAIT_MOVING_THRESHOLD := 0.05
## Per direct correction ("give him a running gait too, which should not
## only be increased limb speed but also amplify in the bend degree of all
## his limbs in the strides") -- this covers the "increased limb speed"
## half (see _animate_gait()'s own use of this against GAIT_CYCLE_SPEED);
## the "amplify the bend" half lives in HorseFigure.RUN_BEND_MULTIPLIER
## instead, since only that file's own animate_gait() touches individual
## joint rotations. Driven by the SAME `sprinting` flag drive_from_player()
## already receives from player.gd (see that function's own use below) --
## there's no separate run/walk state to invent, sprinting while ridden IS
## the run trigger. First-draft magnitude, adjustable on report.
const RUN_CYCLE_SPEED_MULTIPLIER := 1.8

## ---- Jump ---- Per direct correction ("we'll want to add a jump ability...
## think how the player jumps"), only while actively ridden -- see
## drive_from_player()'s own use of these. Manchego has no CharacterBody3D/
## real physics gravity (see this file's own class doc for why -- manual
## position updates every frame, same as blorb.gd/xiao_hou_zi.gd), so this
## is a self-contained vertical arc tracked in _vertical_velocity, not
## anything player.gd's own gravity/jump_velocity feeds into. First-draft
## magnitudes, unverified in-engine -- adjustable on report, same as every
## other unspecified number in HorseFigure.
const JUMP_VELOCITY := 8.5
const JUMP_GRAVITY := 24.0
## How long the landing-impact pose (HorseFigure.animate_landing()) holds
## before _animate_gait() resumes ordinary animate_gait()/rest -- same idiom
## as player.gd's own LANDING_DURATION.
const LANDING_DURATION := 0.18

var is_player_controlled: bool = false
## True (the original/default behavior) once he's a party mount: walks to
## keep up with the player, per this file's own class doc comment. False for
## an instance planted somewhere as a scene fixture rather than a companion
## -- see jungle_kingdom_village.gd's own quest-ape spawn, where Manchego
## starts out idling in place in the village (per direct instruction, "we
## will see Manchego there idling around, not following the player") rather
## than immediately chasing after them the way a bonded mount would. Flipped
## to true once the "special banana" quest hands him over.
var follows_player: bool = true
## Gates the "Ride Manchego" Interactable prompt itself, independent of
## is_player_controlled -- per direct instruction, before the quest above
## resolves he's already "occupied" (ridden by the quest-giving ape) and
## should not be rideable by the player yet. See set_available_to_player().
var available_to_player: bool = true
## Small ambient wander anchor for the not-following-yet state above -- see
## _update_idle()'s own doc comment. Captured once in _ready() rather than
## always "wherever he currently is," so a slow drift over many idle cycles
## can't walk him away from his intended spot.
var _idle_anchor: Vector2 = Vector2.ZERO
var _idle_wander_target: Vector2 = Vector2.ZERO
var _idle_has_target: bool = false
var _idle_pause_timer: float = 0.0

var _player: Node3D
var terrain: Node

var _pivots: Dictionary
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()

## Jump state -- see JUMP_VELOCITY's own comment. _jump_takeoff_speed is
## captured at the moment of takeoff (rather than always reading
## JUMP_VELOCITY directly) purely to mirror player.gd's own
## _jump_takeoff_speed/apex_fraction shape exactly, in case a future variable
## launch speed (a super-jump equivalent) is ever added on top of this.
var _vertical_velocity: float = 0.0
var _is_airborne: bool = false
var _jump_takeoff_speed: float = JUMP_VELOCITY
var _landing_timer: float = 0.0
var _look_target: Node3D = null

var _rng := RandomNumberGenerator.new()
var _stride_phase: float = 0.0
## Eased look-yaw, radians relative to the body's own forward facing (self.
## rotation.y) -- see _update_head_look()'s own doc comment for why this is
## tracked separately rather than read back from head.rotation.y each frame
## (that node's rotation.y is no longer meaningful on its own once look-yaw
## is applied via a direct global_transform.basis composition instead).
var _current_head_yaw: float = 0.0

## The proximity Area3D Interactable.attach() built for the "Ride Manchego"
## prompt -- kept so begin_ride()/end_ride() can stop/resume monitoring
## while he's actively being ridden, same reasoning xiao_hou_zi.gd's own
## identically-named field documents for its "Talk" prompt.
var _interact_area: Area3D


func _ready() -> void:
	_rng.randomize()
	_pivots = HorseFigure.build(self)
	_eyes = _pivots["eyes"]

	add_to_group("manchego")
	_player = get_node("../Player")
	terrain = get_node("../Terrain")
	global_position.y = terrain.get_mesh_height(global_position.x, global_position.z)
	_idle_anchor = Vector2(global_position.x, global_position.z)

	var collision_shape := CollisionShape3D.new()
	var collider := BoxShape3D.new()
	collider.size = Vector3(0.7, 1.5, 1.7)
	collision_shape.shape = collider
	collision_shape.position = Vector3(0, 0.9, 0)
	add_child(collision_shape)
	collision_layer = 1
	collision_mask = 0

	_interact_area = Interactable.attach(
		self, "Ride Manchego", INTERACT_RADIUS, _on_ride,
		func(body: Node3D) -> void: _look_target = body,
		func(body: Node3D) -> void:
			if _look_target == body:
				_look_target = null
	)
	_interact_area.monitoring = available_to_player


## See available_to_player's own doc comment -- toggles both the flag _on_ride()
## checks and the Interactable prompt's own monitoring, so an unavailable
## Manchego shows no "Ride Manchego" prompt at all rather than showing one
## that then silently does nothing on activate.
func set_available_to_player(value: bool) -> void:
	available_to_player = value
	_interact_area.monitoring = value


func _on_ride() -> void:
	if is_player_controlled or not available_to_player:
		return
	(_player as Player).start_riding_manchego(self)


func begin_ride() -> void:
	is_player_controlled = true
	_interact_area.monitoring = false
	InteractionManager.exit(_interact_area)
	_look_target = null
	# _update_head_look() stops being called entirely once is_player_controlled
	# is true, so without this the head/neck just freeze wherever they last
	# pointed (whoever was approaching to mount) instead of resetting --
	# confirmed by direct report ("his head is actually freezing where it was
	# looking at the player instead of resetting when starting to ride").
	# Snap both back to their rest pose (zero look-yaw) right here instead --
	# the neck needs this too now that it shares in the look-yaw (see
	# _update_head_look()'s own doc comment).
	_current_head_yaw = 0.0
	var head: Node3D = _pivots["head"]
	var neck: Node3D = _pivots["neck"]
	var spine: Node3D = _pivots["spine"]
	neck.global_transform.basis = spine.global_transform.basis * Basis(Vector3.RIGHT, HorseFigure.NECK_TILT_ANGLE)
	head.global_transform.basis = neck.global_transform.basis * Basis(Vector3.RIGHT, HorseFigure.HEAD_REST_PITCH)


func end_ride() -> void:
	is_player_controlled = false
	_interact_area.monitoring = available_to_player


## Live world transform of HorseFigure.SEAT_Y/SEAT_Z's own marker node --
## see that const's own comment. A generic accessor, not player-specific,
## per direct instruction to keep this reusable for future riders (Xiao Hou
## Zi, Blorbus) rather than something the human alone reaches into _pivots
## for.
func get_seat_transform() -> Transform3D:
	return (_pivots["seat"] as Node3D).global_transform


func _process(delta: float) -> void:
	EyeBlink.apply(_eye_blink, delta, _eyes)
	_update_head_look(delta)
	if is_player_controlled:
		return
	if follows_player:
		_update_follow(delta)
	else:
		_update_idle(delta)


## How much of the total look-yaw the NECK takes, pivoting from its own
## base (neck_pivot's own origin, which already sits exactly at the neck's
## attachment point on the torso -- rotating any node inherently pivots
## around its own origin, so no extra work is needed to make the neck pivot
## "from its bottom base" specifically). The remainder goes to the head. Per
## direct correction ("distribute that angle of twist between the head
## segment as well as the neck segment... using the same concept of
## swivelling on an axis perpendicular to the horizon") -- an even split is
## a first-draft choice, not a specified ratio; adjustable on report.
const NECK_LOOK_SHARE := 0.5

## CONFIRMED BROKEN by direct report ("simply tilting his head side to
## side... the head swivels on an axis perpendicular to the horizon
## wouldn't it"). The original code set head.rotation.y directly on
## HorseFigure's own head_pivot -- but that same node already carries a
## large static rotation.x (HorseFigure.HEAD_REST_PITCH, the poll bend).
## Godot's Node3D.rotation Vector3 composes as Ry*Rx*Rz, so adding a
## rotation.y on a node that ALSO has a big rotation.x does NOT rotate
## around that node's own (mostly-vertical) world up axis -- it rotates
## around whatever Y axis existed going INTO that node, i.e. its PARENT's
## local Y. Fixed by composing the rotation directly as Bases in WORLD space
## instead of mutating local Euler angles, guaranteeing the look-turn always
## swivels around a real vertical axis regardless of how a pitched parent is
## tilted.
##
## Per direct correction, the NECK now shares in this same swivel instead of
## staying static -- the total look-yaw splits into a neck share and a head
## share (NECK_LOOK_SHARE above). The neck's own desired world orientation
## is "spine_pivot's current world orientation, tilted by the neck's own
## fixed rest angle, then yawed by its own share around TRUE WORLD UP" --
## exactly the same technique the head already used, just rooted one level
## higher in the chain (off spine_pivot instead of off neck_pivot). The
## head's own rotation then composes on top of the NECK's newly-updated
## basis, same as before, so it inherits the neck's own share automatically
## and only needs to add its own remaining share on top.
func _update_head_look(delta: float) -> void:
	if is_player_controlled:
		return
	var head: Node3D = _pivots["head"]
	var neck: Node3D = _pivots["neck"]
	var spine: Node3D = _pivots["spine"]
	var target_yaw := 0.0
	if _look_target != null:
		# Bearing to the target and the body's own facing, both computed in
		# world-horizontal terms (not relative to the neck's tilted local
		# frame), so target_yaw cleanly means "how far to turn from straight-
		# ahead," independent of the neck's own pitch.
		var to_target := _look_target.global_position - global_position
		to_target.y = 0.0
		var world_bearing := atan2(to_target.x, to_target.z)
		target_yaw = clampf(angle_difference(rotation.y, world_bearing), -HEAD_YAW_LIMIT, HEAD_YAW_LIMIT)
	_current_head_yaw = lerp_angle(_current_head_yaw, target_yaw, HEAD_TURN_SPEED * delta)
	var neck_share := _current_head_yaw * NECK_LOOK_SHARE
	var head_share := _current_head_yaw - neck_share
	var neck_rest := Basis(Vector3.RIGHT, HorseFigure.NECK_TILT_ANGLE)
	neck.global_transform.basis = Basis(Vector3.UP, neck_share) * spine.global_transform.basis * neck_rest
	var head_rest := Basis(Vector3.RIGHT, HorseFigure.HEAD_REST_PITCH)
	head.global_transform.basis = Basis(Vector3.UP, head_share) * neck.global_transform.basis * head_rest


func _update_follow(delta: float) -> void:
	var offset := _player.global_position - global_position
	offset.y = 0.0
	var distance := offset.length()
	var moving := false
	if distance > FOLLOW_DISTANCE:
		moving = true
		var dir := offset.normalized()
		var next := Vector2(global_position.x, global_position.z) + Vector2(dir.x, dir.z) * FOLLOW_MOVE_SPEED * delta
		global_position.x = next.x
		global_position.z = next.y
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), ROTATION_SPEED * delta)
	elif distance < ARRIVE_DISTANCE:
		moving = false
	# Explicit : float, not := -- terrain is plain Node-typed (see this
	# file's own @onready-equivalent assignment in _ready()), so GDScript
	# can't infer get_mesh_height()'s return type through := alone (same
	# pitfall blorb.gd's own _ground_height_at() flags).
	var ground_h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	global_position.y = move_toward(global_position.y, ground_h, GROUND_SETTLE_SPEED * delta)
	_animate_gait(delta, moving)


## See follows_player's own doc comment -- a gentle amble around _idle_anchor
## instead of chasing the player, same pick-a-nearby-point-and-pause shape as
## jungle_villager.gd's/xiao_hou_zi.gd's own wander AI, just built directly
## here rather than shared, since Manchego's gait dispatch (_animate_gait())
## is specific to this file's own HorseFigure pivots.
func _update_idle(delta: float) -> void:
	var here := Vector2(global_position.x, global_position.z)
	var moving := false
	if _idle_has_target and here.distance_to(_idle_wander_target) > IDLE_ARRIVE_DISTANCE:
		moving = true
	elif _idle_has_target:
		_idle_has_target = false
		_idle_pause_timer = _rng.randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)
	else:
		_idle_pause_timer -= delta
		if _idle_pause_timer <= 0.0:
			var angle := _rng.randf_range(0.0, TAU)
			var r := IDLE_WANDER_RADIUS * sqrt(_rng.randf())
			_idle_wander_target = _idle_anchor + Vector2(cos(angle), sin(angle)) * r
			_idle_has_target = true

	if moving:
		var to_target := _idle_wander_target - here
		var step := to_target.limit_length(IDLE_WANDER_MOVE_SPEED * delta)
		var next := here + step
		global_position.x = next.x
		global_position.z = next.y
		if to_target.length() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(to_target.x, to_target.y), ROTATION_SPEED * delta)
	var idle_ground_h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	global_position.y = move_toward(global_position.y, idle_ground_h, GROUND_SETTLE_SPEED * delta)
	_animate_gait(delta, moving)


## Dispatches to whichever leg animation applies this frame -- ordinary gait,
## the airborne jump tuck, or the brief post-landing impact pose -- then
## always re-lofts the tubes/tail regardless of which one ran. _is_airborne/
## _landing_timer are only ever set from drive_from_player() (see its own
## comment), so _update_follow()'s calls into this always fall through to
## the plain gait branch, unchanged from before the jump ability existed.
func _animate_gait(delta: float, moving: bool, running: bool = false) -> void:
	if _is_airborne:
		# Same apex_fraction shape as player.gd's own _animate_airborne():
		# 0 at takeoff, 1 at the apex (vertical_velocity == 0), easing back
		# toward 0 again on the way down (using a gentler reference speed on
		# the descent side, same reasoning player.gd's own comment gives --
		# the full tuck should release before touchdown, not hold all the
		# way to the ground). `rising` is also passed through on its own --
		# see HorseFigure.animate_airborne()'s own comment for why the body
		# pitch needs it (nose-up on the way up, nose-down on the way down),
		# something apex_fraction alone can't distinguish since it's the same
		# shape on both halves of the arc.
		var rising := _vertical_velocity >= 0.0
		var apex_fraction: float
		if rising:
			apex_fraction = 1.0 - smoothstep(0.0, _jump_takeoff_speed, _vertical_velocity)
		else:
			apex_fraction = 1.0 - smoothstep(0.0, _jump_takeoff_speed * 0.75, -_vertical_velocity)
		HorseFigure.animate_airborne(_pivots, delta, apex_fraction, rising)
	elif _landing_timer > 0.0:
		_landing_timer -= delta
		HorseFigure.animate_landing(_pivots, delta)
	else:
		if moving:
			_stride_phase += delta * GAIT_CYCLE_SPEED * (RUN_CYCLE_SPEED_MULTIPLIER if running else 1.0)
		HorseFigure.animate_gait(_pivots, delta, moving, _stride_phase, running)
	# Re-loft the four leg noodle tubes from the pivots' just-updated global
	# positions -- must run AFTER whichever branch above just ran, same
	# per-frame ordering player.gd uses for MonkeyFigure.rebuild_limbs(). See
	# HorseFigure.rebuild_limbs()'s own doc comment.
	HorseFigure.rebuild_limbs(_pivots)
	# Tail sway/flit runs continuously regardless of moving/ridden/airborne
	# state -- see HorseFigure.animate_tail()'s own doc comment.
	HorseFigure.animate_tail(_pivots["_tail"], delta)


## Driven every physics frame by player.gd's _update_manchego_control() while
## is_player_controlled is true -- mirrors blorb.gd's own drive_from_player()
## almost exactly (planar XZ integrated straight into global_position,
## ground height re-derived at the new XZ, rotation.y eased toward the
## direction of travel), just without that method's lake/cloud/canopy
## handling -- Manchego is ground-only, per docs/world_bible.md's own Mounts
## entry ("no other gameplay effect yet"). jump_pressed is new (see
## JUMP_VELOCITY's own comment) -- the one exception to "ground-only," a
## simple self-contained vertical hop, not real 3D physics.
func drive_from_player(direction: Vector3, delta: float, sprinting: bool, jump_pressed: bool = false) -> void:
	var planar := Vector2(direction.x, direction.z)
	if planar.length() > 1.0:
		planar = planar.normalized()
	var speed := (_player as Player).move_speed * RIDE_SPEED_MULTIPLIER
	if sprinting:
		speed *= (_player as Player).sprint_multiplier
	var next := Vector2(global_position.x, global_position.z) + planar * speed * delta
	global_position.x = next.x
	global_position.z = next.y
	# Explicit : float, not := -- see _update_follow()'s own identical
	# comment on the same get_mesh_height() return-type pitfall.
	var ground_h: float = terrain.get_mesh_height(next.x, next.y)
	# _landing_timer > 0.0 guards against an immediate re-jump the instant
	# the impact pose starts -- has to actually finish reading as a landing
	# first, not just touch the ground for one frame.
	if jump_pressed and not _is_airborne and _landing_timer <= 0.0:
		_is_airborne = true
		_vertical_velocity = JUMP_VELOCITY
		_jump_takeoff_speed = JUMP_VELOCITY
	if _is_airborne:
		_vertical_velocity -= JUMP_GRAVITY * delta
		global_position.y += _vertical_velocity * delta
		if global_position.y <= ground_h:
			global_position.y = ground_h
			_is_airborne = false
			_landing_timer = LANDING_DURATION
	else:
		global_position.y = ground_h
	if planar.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(planar.x, planar.y), ROTATION_SPEED * delta)
	var moving := planar.length() * speed > GAIT_MOVING_THRESHOLD
	_animate_gait(delta, moving, sprinting and moving)
