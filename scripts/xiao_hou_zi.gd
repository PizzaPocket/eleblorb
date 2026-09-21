class_name XiaoHouZi
extends CharacterBody3D

## Xiao Hou Zi, the jungle biome's resident monkey (see docs/world_bible.md).
## Roams the jungle plateau as ambient wildlife until the player wanders
## close enough to be noticed, then leaves his own wandering behind to come
## find the PLAYER specifically -- never "the blorbs." That's the one
## deliberate divergence from blorb.gd's otherwise near-identical discover/
## bond/join/follow state machine (see blorb.gd's own _follow_target(),
## which sends a discovered-but-unpartied wild blorb toward the nearest
## PARTY blorb instead of the player). After the player's spent
## JOIN_BOND_DURATION seconds actually near him (not necessarily
## continuously -- see blorb.gd's identical-in-spirit comment on its own
## JOIN_BOND_DURATION), he joins the party for good and keeps following
## like an ordinary blorb from then on -- but is never added to the
## "blorbs" group (see _ready()), so none of the blorb-only systems (the
## blorb suit, the Blorbs tab, inter-blorb separation) ever pick him up.
##
## Built as a standalone StaticBody3D mirroring blorb.gd's own architecture
## (manual XZ position updates every frame, no CharacterBody3D/
## move_and_slide -- StaticBody3D has no physics stepping of its own to
## drive) for his own independent roam/follow AI, which keeps running every
## single frame (see _process()) regardless of possession state -- direct
## piloting never pauses it.
##
## Once the player possesses him (see player.gd's own
## _try_start_xiao_hou_zi_control()), the HUMAN CharacterBody reskins
## itself as MonkeyFigure right where it's already standing and takes
## direct control, reusing player.gd's entire movement stack -- walk/run/
## jump feel, swimming, flight, the blorb suit -- unmodified. THIS body
## does NOT hide for that (an earlier version of this mechanism did, but
## per direct correction -- "the player character disappears, but that
## shouldn't happen. He should stay in his position, and switch to
## following you in the same way he does when you're playing as Blorbus" --
## the human must stay visible). Instead, begin_possession() below reskins
## THIS body as that human (via player.gd's own static
## build_portrait_body()) right where it already is standing -- no
## position/rotation snap of either body, ever, matching Blorbus possession's
## own zero-teleport behavior exactly (per further direct correction: "both
## the player character and Xiao Hou Zi should keep their existing position
## throughout any switches, just as blorbus and the player do") -- then just
## keeps running its ordinary _update_ai(): since he's already in_party by
## the time he's possessable,
## that state machine already makes an idle party member stand still until
## the player wanders off, then trail after them at the same loose follow/
## rest cadence covered above -- exactly the behavior needed to stand in for
## the human convincingly, with zero extra follow logic required. This
## mirrors what player.gd's own CharacterBody already does while the player
## is off piloting Blorbus (see that file's _update_blorbus_control()).
## end_possession() below swaps him back to MonkeyFigure in place, right
## where his own follow AI has walked him to, and he resumes being himself.

## Shown as the speaker name in DialogUI, same convention as npc.gd's own
## display_name.
@export var display_name: String = "Xiao Hou Zi"
## First-pass personality lines -- per direct instruction his personality
## is still being worked out (see docs/world_bible.md's own open thread),
## so these read as a curious, cheeky jungle local without committing to a
## deeper backstory yet.
@export var talk_lines: Array[String] = [
	"Ooh, a visitor! Nobody this far up the jungle usually smells like blorb goo.",
	"I've lived on this plateau longer than I can count. Longer than the vines, probably.",
	"You keep looking at me like you want me to follow you somewhere. I might, if you stick around.",
	"The durians up here are the best in the whole jungle. Don't tell the birds I said that.",
	"I talk to plenty of things that don't talk back. It's nice when one finally does.",
	"Careful on the mossy shelves -- I've seen a few too many travelers slide right off those.",
	"Something's coming for this world, or so the older vines whisper. I'd rather just eat fruit and swing around, myself.",
]

## Party-membership flag -- mirrors blorb.gd's own in_party (see that
## file's doc comment for the full reasoning), just for one specific named
## creature rather than an interchangeable wild blorb. Deliberately never
## touches the "blorbs" group (see _ready()) so every blorb-only system
## stays blind to him.
var in_party: bool = false
## Ordinary world encounters use the proximity/bond recruitment below. Demo
## courses can disable that path and award him from a deliberate portal beat.
@export var auto_join_enabled: bool = true

const INTERACT_RADIUS := 2.0
# Same axial look-turn range npc.gd's own head tracking uses -- see that
# file's HEAD_YAW_LIMIT for the full reasoning (no pitch limit needed,
# since he only turns to look, never tilts).
const HEAD_YAW_LIMIT := deg_to_rad(80.0)
const HEAD_TURN_SPEED := 10.0

## How close the player has to wander before roaming, undiscovered Xiao
## Hou Zi notices them and starts approaching -- same idea as blorb.gd's
## own DISCOVERY_RADIUS.
const DISCOVERY_RADIUS := 9.0
## Total time the player has to actually spend within FOLLOW_DISTANCE of
## him (doesn't have to be continuous -- falling behind and catching back
## up just pauses this rather than resetting it, same reasoning as
## blorb.gd's identical JOIN_BOND_DURATION) before he joins outright.
## Shorter than blorb.gd's own 25s -- a named, one-off companion reads as
## a shorter, more personal encounter than a random wild blorb.
const JOIN_BOND_DURATION := 18.0
const FOLLOW_DISTANCE := 7.0
const ARRIVE_DISTANCE := 3.0

## Lets him stand still and take breaks while catching up to the player,
## instead of beelining toward them nonstop the whole time he's in
## State.FOLLOWING -- mirrors the rest cadence State.ROAM already has via
## _pause_timer/ROAM_PAUSE_MIN/MAX below. Only kicks in once he's within
## FOLLOW_REST_DISTANCE of the player (a good bit closer than
## FOLLOW_DISTANCE itself) so he never dawdles while genuinely lagging
## behind -- he only rests once he's basically caught up and just keeping
## pace.
const FOLLOW_REST_DISTANCE := 4.5
const FOLLOW_MOVE_MIN := 1.5
const FOLLOW_MOVE_MAX := 3.5
const FOLLOW_PAUSE_MIN := 1.0
const FOLLOW_PAUSE_MAX := 2.5

const ROAM_PAUSE_MIN := 1.5
const ROAM_PAUSE_MAX := 4.5
## Roams the jungle plateau's own footprint (anchored on the biome's
## center, not his spawn point, so he actually covers the whole jungle
## rather than idling near wherever he happened to spawn) -- 80% of the
## plateau's own radius keeps him shy of its noise-wobbled edge.
const ROAM_RADIUS_FRACTION := 0.8
const ROAM_ARRIVE_DISTANCE := 0.3
const ROAM_MOVE_SPEED := 1.6

const ROTATION_SPEED := 6.0
const GROUND_SETTLE_SPEED := 8.0

## Same presentation scale player.gd's own (now-disabled) TEMP_MONKEY_SCALE
## used for this exact rig -- confirmed the right size by direct
## instruction ("scaled back up to the size we were testing at"). Applied to
## MonkeyFigure.build() below and to every world-space measurement derived
## from his unscaled rig dimensions.
const DISPLAY_SCALE := 2.3585

## Rough feet-to-head-top height at scale 1.0 -- the rig's own root sits at
## foot level (see monkey_figure.gd's ankle_y/knee_y/hip_y stack: hips at
## 0.05, torso rising another BODY_HEIGHT=0.09 to ~0.14, head crown a
## little above that). Used the same way blorb.gd's BODY_HEIGHT is: only a
## fraction of this actually goes under the water line when floating.
const STANDING_HEIGHT := 0.16 * DISPLAY_SCALE

## Same buoyancy blorb.gd's own free (non-giant) blorbs use (see that
## file's identically-named constants), but LAKE_FLOAT_MIN_DEPTH is scaled
## down to his own stature rather than reused verbatim -- blorb.gd's
## 0.4 depth threshold is tuned for its own ~1.15m-tall body, which at Xiao
## Hou Zi's own display height meant almost no lake water ever counted as
## "deep enough," so he just sat on the real lake floor fully submerged
## (per direct correction: "his head [should be] above the surface," not
## down where the player's feet would be) instead of floating.
const LAKE_FLOAT_MIN_DEPTH := STANDING_HEIGHT * 0.3
const LAKE_FLOAT_SUBMERGENCE_FRACTION := 0.35
const LAKE_FLOAT_SETTLE_SPEED := 3.5

# Roughly the player's own collision capsule radius (0.4, see blorb.gd's
# identical PLAYER_PUSH_RADIUS comment) plus a small margin -- keeps the
# player from getting physically stuck against his tiny static collider
# while walking through his roaming path, same reasoning blorb.gd's own
# _apply_player_push exists for.
const PLAYER_PUSH_RADIUS := 0.5
const PLAYER_PUSH_SPEED := 4.0

const WALK_SWING_SPEED := 8.0
const WALK_SWING_AMOUNT := 0.55
const POSE_SETTLE_SPEED := 8.0

enum State { ROAM, FOLLOWING }

@onready var terrain: Node = get_node("../Terrain")

var _player: Node3D
var _pivots: Dictionary
var _blorb_suit := BlorbSuitController.new()
## His joints by rig-neutral name, and the powers he shares with every other
## character (docs/traversal_powers_architecture.md).
var _rig: RigAdapter = null
var _ice_skates := IceSkateMode.new()
var _snowboard_mode := SnowboardMode.new()
var _crystal := CrystalSkateMode.new()
var _swim := SwimMode.new()
var _penguin := PenguinMode.new()
var _flight := FlightMode.new()
var _powers := SuitPowers.new()
## The liquid under him, read fresh each frame.
var _liquid := LiquidEnvironment.new()
var _snowboard_chord := PowerChord.new()
var _wheelie_chord := PowerChord.new()
var _lava := LavaMode.new()
var _dirtbike := DirtbikeMode.new()
## His snowboard: the same power the player rides, on his own rig and at his
## own scale. Toggled by the leg-power chord, as the player's is.
var _direct_snowboard_active: bool = false
var _direct_snowboard: Node3D = null
var _direct_snowboard_up: Vector3 = Vector3.UP
var _direct_snowboard_heading: Vector3 = Vector3.FORWARD
var _portrait := PlayerPortrait.new()
var _playable_profile := PlayableCharacterProfile.xiao_hou_zi()
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()
var _look_target: Node3D = null

var _state: State = State.ROAM
var _rng := RandomNumberGenerator.new()

var _discovered: bool = false
var _bond_time: float = 0.0

var _wander_center: Vector2
var _roam_radius: float = 20.0
var _wander_target: Vector2
var _has_wander_target: bool = false
var _pause_timer: float = 0.0

## Rest-break state for State.FOLLOWING -- see FOLLOW_REST_DISTANCE above.
var _follow_resting: bool = false
var _follow_pause_timer: float = 0.0

var _walk_phase: float = 0.0

## Unlike blorb.gd's identically-named flag, this does NOT pause
## _update_ai() -- see this file's own class doc comment for why. He's
## always already in_party by the time this can go true, so that same
## state machine already produces exactly the right "stand still, then
## trail after them" behavior needed to stand in for the human while this
## is true. It only gates which rig _process() rebuilds/relofts (see
## _rebuild_rig() below) and skips the auto-look logic in
## _update_head_look() -- true here means "reskinned as the human,
## standing in for him while he directly pilots this body's own former
## self," set by begin_possession()/end_possession() below.
var is_player_controlled: bool = false
## These are the exact established Xiao modifiers formerly applied inside
## Player's shared movement stack. Keep them explicit during extraction so
## changing control ownership cannot silently retune the character.
var _direct_vertical_velocity: float = 0.0
var _mounted: bool = false
var max_hp: float = 100.0
var current_hp: float = 100.0
var _direct_diving: bool = false
var _direct_flying: bool = false
var _direct_air_feet: bool = false
var _direct_lava_surface: bool = false
var _direct_hover_height: float = 0.0
var _direct_left_arm_plant_cooldown: float = 0.0
var _direct_right_arm_plant_cooldown: float = 0.0
var _direct_water_arm_fx: Array[GPUParticles3D] = []
var _direct_fire_arm_fx: Array[GPUParticles3D] = []
var _direct_water_leg_fx: Array[GPUParticles3D] = []
var _direct_fire_leg_fx: Array[GPUParticles3D] = []
var _direct_electric_arm_fx: Array[LightningBolt] = []
var _direct_city_arm_fx: Array[LightningBolt] = []
var _direct_liquid_level: float = -INF
var _direct_floor_height: float = 0.0
var _direct_last_bounced_blorb: Blorb = null
var _direct_dirtbike_active: bool = false
var _direct_dirtbike_front_active: bool = false
var _direct_dirtbike_was_climbing: bool = false
var _direct_dirtbike_airborne: bool = false
var _direct_dirtbike_surface_velocity := Vector3.ZERO
var _direct_dirtbike_supported_pitch := 0.0
var _direct_dirtbike_airborne_pitch := 0.0
var _direct_dirtbike_pitch_was_grounded := false
var _direct_dirtbike_rear_wheel: MeshInstance3D = null
var _direct_dirtbike_front_wheel: MeshInstance3D = null
var _direct_ice_skates_active: bool = false
var _direct_ice_skating_active: bool = false
var _direct_ice_skate_left: Node3D = null
var _direct_ice_skate_right: Node3D = null
var _direct_ice_skate_lift_y: float = 0.0
var _direct_ice_skate_was_supported: bool = false
var _direct_ice_skate_airborne: bool = false
var _direct_ice_skate_surface_velocity := Vector3.ZERO
## Base glide speed while in the FOLLOWING AI state, catching back up to the
## player -- reads the player's own move_speed once at _ready() same as
## blorb.gd's _follow_glide_speed, so it stays correct if move_speed is ever
## retuned.
var _follow_speed: float = 6.0

## The proximity Area3D Interactable.attach() built for his "Talk" prompt --
## kept so begin_possession()/end_possession() can stop/resume monitoring;
## he stays visible and physically present the whole time now (see this
## file's own class doc comment), but a "Talk" prompt while he's standing
## in for the human himself wouldn't make sense, so this alone gets
## disabled for the duration.
var _interact_area: Area3D


func _ready() -> void:
	_rng.randomize()
	up_direction = Vector3.UP
	floor_snap_length = 0.12
	floor_max_angle = deg_to_rad(50.0)
	_pivots = MonkeyFigure.build(self, MonkeyFigure.MONKEY_FUR_COLOR, DISPLAY_SCALE)
	_rig = RigAdapter.new(_rig_joint_map())
	_eyes = _pivots["eyes"]
	_blorb_suit.setup(
		self, self, _blorb_suit_pivot_map(), _playable_profile.suit_rig_scale,
		_playable_profile.suit_limb_fit
	)
	_portrait.setup(self, self, "xiao_hou_zi")

	# Own dedicated group -- lets player.gd's switch_blorbus cycling find him
	# once recruited without ever touching the "blorbs" group. Never
	# add_to_group("blorbs") itself -- see this file's own class doc comment
	# for why staying outside that group is the whole mechanism keeping him
	# clear of every blorb-only system.
	add_to_group("xiao_hou_zi")
	add_to_group("party_playable_candidates")
	PartyControl.register_member(self)
	_player = get_node("../Player")
	_follow_speed = (_player as Player).move_speed

	# Only the outskirts' own TerrainGenerator exposes the jungle plateau's
	# shape -- a kingdom's Terrain (see kingdom_bootstrap.gd) has no such
	# landform, so when he's recruited into the party and follows the player
	# through a portal, he wanders around wherever he was spawned instead.
	if terrain.has_method("get_jungle_plateau_center"):
		_wander_center = terrain.get_jungle_plateau_center()
		_roam_radius = terrain.get_jungle_plateau_radius() * ROAM_RADIUS_FRACTION
	else:
		_wander_center = Vector2(global_position.x, global_position.z)
	global_position.y = terrain.get_mesh_height(global_position.x, global_position.z)
	_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)

	# A small solid collider so the player physically registers his
	# presence (and so Interactable's own Area3D below has a real body to
	# key its prompt off), sized to his own tiny frame rather than blorb.gd's
	# much larger sphere.
	# MonkeyFigure.build() applies DISPLAY_SCALE to its own inner rig child,
	# not to self -- this collider is a direct child of self, so it needs the
	# same scale applied by hand to stay sized to the visible rig.
	var collision_shape := CollisionShape3D.new()
	var collider := SphereShape3D.new()
	collider.radius = 0.08 * DISPLAY_SCALE
	collision_shape.shape = collider
	collision_shape.position = Vector3(0, 0.09 * DISPLAY_SCALE, 0)
	add_child(collision_shape)
	collision_layer = 1
	collision_mask = 1

	_interact_area = Interactable.attach(
		self, "Talk", INTERACT_RADIUS, _on_talk,
		func(body: Node3D) -> void: _look_target = body,
		func(body: Node3D) -> void:
			if _look_target == body:
				_look_target = null
	)


func _on_talk() -> void:
	var line: String = talk_lines[_rng.randi_range(0, talk_lines.size() - 1)]
	DialogUI.show_line(display_name, line)


func _process(delta: float) -> void:
	EyeBlink.apply(_eye_blink, delta, _eyes)
	_update_head_look(delta)
	# Keeps running in both rigs -- see this file's own class doc comment and
	# is_player_controlled's for why the same state machine already produces
	# the right behavior whether he's independently himself or standing in
	# for the human.
	if not is_player_controlled:
		_update_ai(delta)
	# This body always remains Xiao Hou Zi's real MonkeyFigure now. Its tubes
	# must follow the animated pivots during direct control as well as AI.
	MonkeyFigure.rebuild_limbs(_pivots, self, delta)
	_blorb_suit.update(delta)
	_update_direct_ice_skate_state()
	if is_player_controlled and Input.is_action_just_pressed("transform") and not UIState.modal_open:
		_blorb_suit.toggle()


## Every joint a shared power may need: the suit's own map plus the torso
## joints the suit never dresses but poses do use. Kept separate from
## _blorb_suit_pivot_map() so the suit is handed exactly what it expects.
func _rig_joint_map() -> Dictionary:
	var map := _blorb_suit_pivot_map()
	for name in ["thorax", "neck", "hips"]:
		var node: Node3D = _pivots.get(name) as Node3D
		if node != null:
			map[name] = node
	return map


## This frame, described for a shared power. Same shape the player builds
## (Player._traversal_context()), so a power cannot tell the two apart.
func _traversal_context(delta: float) -> TraversalContext:
	var ctx := TraversalContext.new(self, _playable_profile, _rig, _blorb_suit, _terrain())
	ctx.delta = delta
	ctx.sprinting = Input.is_action_pressed("run")
	ctx.grounded = is_on_floor()
	ctx.visuals = _pivots.get("_rig") as Node3D
	ctx.leg_speed_multiplier = _special_speed_multiplier(["leg_left", "leg_right"])
	return ctx


func _terrain() -> Node:
	return get_node_or_null("../Terrain")


func _blorb_suit_pivot_map() -> Dictionary:
	return {
		"arm_left_shoulder": _pivots["arm_left"], "arm_left_elbow": _pivots["elbow_left"],
		"arm_right_shoulder": _pivots["arm_right"], "arm_right_elbow": _pivots["elbow_right"],
		"leg_left_hip": _pivots["leg_left"], "leg_left_knee": _pivots["knee_left"], "leg_left_ankle": _pivots["ankle_left"],
		"leg_right_hip": _pivots["leg_right"], "leg_right_knee": _pivots["knee_right"], "leg_right_ankle": _pivots["ankle_right"],
		"spine": _pivots["spine"], "head": _pivots["head"],
		"back_left": _pivots["back_left"], "back_right": _pivots["back_right"],
		"wrist_left": _pivots["wrist_left"], "wrist_right": _pivots["wrist_right"],
		"fingertip_left": _pivots["fingertip_left"], "fingertip_right": _pivots["fingertip_right"],
		"toe_left": _pivots["toe_left"], "toe_right": _pivots["toe_right"],
	}


func get_blorb_suit() -> BlorbSuitController:
	return _blorb_suit


func get_own_blorb_suit() -> BlorbSuitController:
	return _blorb_suit


func get_portrait() -> PlayerPortrait:
	return _portrait


func _update_head_look(delta: float) -> void:
	var head: Node3D = _pivots["head"]
	var target_yaw := 0.0
	# Skip the auto-look entirely while the player is directly piloting him --
	# _look_target is usually the player's own body, so left alone this would
	# keep snapping his head to face the very camera controlling him.
	if not is_player_controlled and _look_target != null:
		var head_parent := head.get_parent()
		var local_target: Vector3 = head_parent.global_transform.affine_inverse() * _look_target.global_position
		var dir := local_target - head.position
		# Same atan2(x, z) convention npc.gd's own _update_head_look uses --
		# MonkeyFigure.build()'s rig deliberately mirrors procedural_figure.
		# gd's own contract (see that file's class doc), including local +Z
		# as the rig's true front.
		target_yaw = clampf(atan2(dir.x, dir.z), -HEAD_YAW_LIMIT, HEAD_YAW_LIMIT)
	head.rotation.y = lerp_angle(head.rotation.y, target_yaw, HEAD_TURN_SPEED * delta)


func _update_ai(delta: float) -> void:
	var here := Vector2(global_position.x, global_position.z)

	if auto_join_enabled and not in_party and not _discovered:
		var dist_to_player := here.distance_to(Vector2(_player.global_position.x, _player.global_position.z))
		if dist_to_player < DISCOVERY_RADIUS:
			_discovered = true

	# Always the player specifically, never "the nearest blorb" -- see this
	# file's own class doc comment for why that's a deliberate divergence
	# from blorb.gd's identical-looking _follow_target().
	var follow_pt := Vector2(_player.global_position.x, _player.global_position.z)
	var dist_follow := here.distance_to(follow_pt)

	var was_following := _state == State.FOLLOWING
	if (in_party or _discovered) and dist_follow > FOLLOW_DISTANCE:
		_state = State.FOLLOWING
		if not was_following:
			# Freshly entered FOLLOWING (rather than continuing an existing
			# chase) -- start on a moving beat, not a resting one, since he's
			# by definition currently further than FOLLOW_DISTANCE away.
			_follow_resting = false
			_follow_pause_timer = _rng.randf_range(FOLLOW_MOVE_MIN, FOLLOW_MOVE_MAX)
	elif _state == State.FOLLOWING and dist_follow < ARRIVE_DISTANCE:
		_state = State.ROAM
		_has_wander_target = false
		_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)

	if auto_join_enabled and not in_party and _discovered and dist_follow < FOLLOW_DISTANCE:
		_bond_time += delta
		if _bond_time >= JOIN_BOND_DURATION:
			in_party = true
			Hud.show_message("Xiao Hou Zi joined your party!")

	var moving := false
	var target := here
	var speed := ROAM_MOVE_SPEED

	if _state == State.FOLLOWING:
		target = follow_pt
		speed = _follow_speed
		if dist_follow <= FOLLOW_REST_DISTANCE:
			# Close enough to just be keeping pace rather than genuinely
			# catching up -- alternate moving/resting beats instead of
			# beelining nonstop, same rest cadence idea as State.ROAM's own
			# _pause_timer above.
			_follow_pause_timer -= delta
			if _follow_pause_timer <= 0.0:
				_follow_resting = not _follow_resting
				_follow_pause_timer = (
					_rng.randf_range(FOLLOW_PAUSE_MIN, FOLLOW_PAUSE_MAX) if _follow_resting
					else _rng.randf_range(FOLLOW_MOVE_MIN, FOLLOW_MOVE_MAX)
				)
			moving = not _follow_resting
		else:
			# Genuinely lagging behind -- always close the gap, no rest
			# breaks, so he never dawdles his way into falling further back.
			_follow_resting = false
			moving = true
	elif in_party:
		# Once he's joined the party he stops ambient wandering entirely and
		# just stands still until FOLLOWING kicks back in above -- follows
		# along like an ordinary blorb rather than continuing to roam off on
		# his own between arrivals.
		_has_wander_target = false
	elif _has_wander_target and here.distance_to(_wander_target) > ROAM_ARRIVE_DISTANCE:
		target = _wander_target
		moving = true
	elif _has_wander_target:
		_has_wander_target = false
		_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)
	else:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_pick_new_wander_target()

	var new_pos := here
	if moving:
		var to_target := target - here
		var step := to_target.limit_length(speed * delta)
		new_pos = here + step
		if to_target.length() > 0.01:
			var target_angle := atan2(to_target.x, to_target.y)
			rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)

	new_pos = _apply_player_push(new_pos, delta)
	global_position.x = new_pos.x
	global_position.z = new_pos.y
	var ground_h := _ground_height_at(global_position.x, global_position.z)
	var lake_y: Variant = _lake_float_y(ground_h)
	if lake_y != null:
		global_position.y = move_toward(global_position.y, lake_y as float, LAKE_FLOAT_SETTLE_SPEED * delta)
	else:
		global_position.y = move_toward(global_position.y, ground_h, GROUND_SETTLE_SPEED * delta)

	_animate_walk(delta, moving)


## Terrain height, except a giant blorb's own analytic goo surface counts
## as standable ground too when it's the higher of the two -- same idea as
## blorb.gd's identically-named helper (its own free blorbs need to stand
## on top of the giant rather than sink through to the terrain beneath it).
## Cloud/canopy support is deliberately left out -- his roam/follow range
## never leaves ground level the way a flying blorb or a climbing player
## can.
func _ground_height_at(x: float, z: float) -> float:
	var terrain_h: float = terrain.get_mesh_height(x, z)
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not candidate is Blorb:
			continue
		var giant := candidate as Blorb
		if giant.blorb_type != "size":
			continue
		var giant_top: Variant = giant.giant_surface_height_at(x, z)
		if giant_top != null:
			return maxf(terrain_h, giant_top as float)
	return terrain_h


## Returns the float-line y coordinate if he's currently over deep enough
## lake water, or null if he should just rest on ground_h as normal --
## mirrors blorb.gd's own inline lake-float check in _process().
func _lake_float_y(ground_h: float) -> Variant:
	if not terrain.is_lake_area(Vector2(global_position.x, global_position.z)):
		return null
	var water_level: float = terrain.get_lake_water_level()
	if water_level - ground_h < LAKE_FLOAT_MIN_DEPTH:
		return null
	return water_level - STANDING_HEIGHT * LAKE_FLOAT_SUBMERGENCE_FRACTION


## Picks a fresh wander point anywhere inside his jungle roam disk --
## sqrt(randf()) keeps the distribution uniform across the disk's area
## rather than clustering samples near its own center.
func _pick_new_wander_target() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var r := _roam_radius * sqrt(_rng.randf())
	_wander_target = _wander_center + Vector2(cos(angle), sin(angle)) * r
	_has_wander_target = true


func _apply_player_push(pos: Vector2, delta: float) -> Vector2:
	var player_pos := Vector2(_player.global_position.x, _player.global_position.z)
	var offset := pos - player_pos
	var dist := offset.length()
	if dist < PLAYER_PUSH_RADIUS and dist > 0.001:
		var needed := offset.normalized() * (PLAYER_PUSH_RADIUS - dist)
		return pos + needed.limit_length(PLAYER_PUSH_SPEED * delta)
	return pos


func _animate_walk(delta: float, moving: bool, cadence_scale: float = 1.0) -> void:
	var leg_left: Node3D = _pivots["leg_left"]
	var leg_right: Node3D = _pivots["leg_right"]
	var arm_left: Node3D = _pivots["arm_left"]
	var arm_right: Node3D = _pivots["arm_right"]
	if moving:
		_walk_phase += delta * WALK_SWING_SPEED * cadence_scale
		var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
		leg_left.rotation.x = swing
		leg_right.rotation.x = -swing
		arm_left.rotation.x = -swing
		arm_right.rotation.x = swing
	else:
		leg_left.rotation.x = lerp_angle(leg_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		leg_right.rotation.x = lerp_angle(leg_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		arm_left.rotation.x = lerp_angle(arm_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		arm_right.rotation.x = lerp_angle(arm_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
	# Direct skating additionally owns toe yaw, lateral hip roll, knees,
	# ankles, elbows, spine lean, and the compensating head pitch. Ordinary
	# Xiao locomotion must explicitly reclaim every one of those properties;
	# otherwise leaving ice preserves whichever stroke pose happened to be
	# active on the last supported frame.
	var settle:=minf(POSE_SETTLE_SPEED*delta,1.0)
	leg_left.rotation.y=lerp_angle(leg_left.rotation.y,0.0,settle)
	leg_right.rotation.y=lerp_angle(leg_right.rotation.y,0.0,settle)
	leg_left.rotation.z=lerp_angle(leg_left.rotation.z,0.0,settle)
	leg_right.rotation.z=lerp_angle(leg_right.rotation.z,0.0,settle)
	(_pivots["knee_left"] as Node3D).rotation.x=lerp_angle((_pivots["knee_left"] as Node3D).rotation.x,0.0,settle)
	(_pivots["knee_right"] as Node3D).rotation.x=lerp_angle((_pivots["knee_right"] as Node3D).rotation.x,0.0,settle)
	(_pivots["ankle_left"] as Node3D).rotation.x=lerp_angle((_pivots["ankle_left"] as Node3D).rotation.x,0.0,settle)
	(_pivots["ankle_right"] as Node3D).rotation.x=lerp_angle((_pivots["ankle_right"] as Node3D).rotation.x,0.0,settle)
	(_pivots["elbow_left"] as Node3D).rotation.x=lerp_angle((_pivots["elbow_left"] as Node3D).rotation.x,0.0,settle)
	(_pivots["elbow_right"] as Node3D).rotation.x=lerp_angle((_pivots["elbow_right"] as Node3D).rotation.x,0.0,settle)
	(_pivots["spine"] as Node3D).rotation.x=lerp_angle((_pivots["spine"] as Node3D).rotation.x,0.0,settle)
	(_pivots["head"] as Node3D).rotation.x=lerp_angle((_pivots["head"] as Node3D).rotation.x,0.0,settle)


## Called by player.gd's _try_start_xiao_hou_zi_control(). Reskins THIS body
## as the human right where it already is standing -- no position/rotation
## change at all, mirroring Blorbus possession's own zero-teleport behavior
## (see this file's own class doc comment) -- and disables the now-
## nonsensical "Talk" prompt. is_player_controlled flipping to true is all
## _update_ai() needs to start treating him like a party member who'll stand
## put until the player (now off piloting this body) wanders away, then
## trail after them.
func playable_id() -> String:
	return _playable_profile.id


func playable_profile() -> PlayableCharacterProfile:
	return _playable_profile


## Camera framing contract -- see Player.camera_focus_point().
func camera_focus_point() -> Vector3:
	return global_position + Vector3.UP * _playable_profile.camera_height


## World-trigger contract shared with Player. The centre is derived from this
## profile's actual standing height, not the human collision capsule.
func body_center() -> Vector3:
	return global_position + Vector3.UP * (_playable_profile.standing_height * 0.5)


func suit_wearer_center() -> Variant:
	return body_center() if PartyControl.active_control_body() == self else null


func camera_follow_distance() -> float:
	return _playable_profile.camera_distance


func is_playable_available() -> bool:
	return in_party


func has_playable_capability(capability: StringName) -> bool:
	return bool(_playable_profile.capabilities.get(String(capability), false))


func playable_switch_order() -> int:
	return _playable_profile.switch_order


func take_damage(amount: float) -> void:
	# Invincible by design: he is a beloved stuffed animal come to life (see
	# docs/world_bible.md). Kept as a compatibility target for combat callers
	# without creating a hidden HP/faint path.
	pass


func begin_direct_control() -> void:
	is_player_controlled = true
	collision_layer = 2
	_look_target = null
	if _interact_area != null:
		_interact_area.monitoring = false


## Called by player.gd's _end_xiao_hou_zi_control() -- reskins back to his
## own Monkey rig right where his own follow AI has already walked him to
## (no position snap needed; unlike the old hide-and-freeze version, this
## body's position has stayed continuously live and correct the whole time
## it stood in for the human), re-enables the "Talk" prompt, and resumes
## being himself.
func end_direct_control() -> void:
	if _interact_area != null:
		_interact_area.monitoring = true
	is_player_controlled = false
	collision_layer = 1
	_direct_vertical_velocity = 0.0
	_wheelie_chord.toggled = false
	_direct_dirtbike_front_active = false
	_direct_dirtbike_active = false
	_direct_dirtbike_airborne = false
	_set_direct_dirtbike_wheel_presence()
	_direct_ice_skating_active = false
	_clear_direct_environment()


func prepare_direct_control_environment(delta: float) -> void:
	_clear_direct_environment()
	_update_direct_dirtbike_state()
	_update_direct_snowboard_state()
	_update_direct_penguin_state()
	_update_direct_ice_skate_state()
	_update_direct_powered_movement(delta)
	# Turned back at the pool's edge by the same rule the player answers to.
	# His origin sits at his feet, so his underside is simply where he is.
	_lava.enforce_access(_traversal_context(delta), global_position.y, 0.0)
	_liquid.read(terrain, _blorb_suit, global_position)
	_direct_floor_height = _liquid.floor_height
	_direct_liquid_level = _liquid.surface_height
	if _liquid.in_lava():
		match _liquid.lava_contact:
			LavaMode.Contact.IMMERSED:
				if _liquid.submerged(global_position.y):
					_direct_diving = true
			LavaMode.Contact.SURFACE:
				# A real jump off the surface is preserved; the molten plane
				# catches him again on the way down, at the same band the
				# player is caught at.
				var rising: bool = velocity.y > 0.0 and global_position.y > _direct_liquid_level
				if not rising and global_position.y <= _direct_liquid_level + LavaMode.CONTACT_TOLERANCE:
					_direct_lava_surface = true
	elif _liquid.in_water() and _liquid.deep_enough_to_swim() and _liquid.submerged(global_position.y):
		# Anybody can go under, whatever they are wearing. Only breath
		# depends on the helmet, which he does not need at all.
		_direct_diving = true
	if not _direct_diving and not _direct_lava_surface:
		_direct_flying = _blorb_suit.has_chest_air_blorb()
		_direct_air_feet = _blorb_suit.has_air_hover_legs()


func uses_pitched_movement_input() -> bool:
	return _direct_diving or _direct_flying or _direct_air_feet or _powers.fire_limb_flight


func _clear_direct_environment() -> void:
	_direct_diving = false
	_direct_flying = false
	_direct_air_feet = false
	_direct_lava_surface = false
	_direct_liquid_level = -INF


func _update_direct_powered_movement(delta: float) -> void:
	var was_hovering: bool = _powers.powered_hover_active()
	_powers.update(
		_blorb_suit, delta, _direct_diving,
		false, false, get_instance_id()
	)
	_update_direct_plant_powers(delta)
	if _powers.powered_hover_active() and not was_hovering:
		_direct_hover_height = global_position.y


func _update_direct_plant_powers(delta: float) -> void:
	_direct_left_arm_plant_cooldown = maxf(_direct_left_arm_plant_cooldown - delta, 0.0)
	_direct_right_arm_plant_cooldown = maxf(_direct_right_arm_plant_cooldown - delta, 0.0)
	if UIState.modal_open:
		return
	for side in ["left", "right"]:
		var cooldown: float = _direct_left_arm_plant_cooldown if side == "left" else _direct_right_arm_plant_cooldown
		if cooldown > 0.0 or not Input.is_action_pressed("%s_arm_power" % side):
			continue
		var slot := "arm_%s" % side
		var blorb := _blorb_suit.worn_blorb_in_slot(slot)
		if blorb == null or blorb.element_state != "plant" or not blorb.consume_mp(Player.PLANT_POWER_MP_PER_SHOT):
			continue
		var pellet := SeedPellet.new()
		var forward := global_basis.z.normalized()
		pellet.velocity = forward * Player.PLANT_PELLET_SPEED + velocity
		pellet.damage = CombatMath.rolled_attack(Player.PLANT_PELLET_DAMAGE_BASE, blorb.strength, _rng)["amount"]
		pellet.attacker_element = "plant"
		pellet.credit_blorbs = [blorb]
		get_tree().current_scene.add_child(pellet)
		pellet.global_position = (_pivots["palm_%s" % side] as Node3D).global_position
		UISounds.play_seed_eject(get_instance_id())
		if side == "left":
			_direct_left_arm_plant_cooldown = Player.PLANT_PELLET_COOLDOWN
		else:
			_direct_right_arm_plant_cooldown = Player.PLANT_PELLET_COOLDOWN
func _special_speed_multiplier(slots: Array[String], averaged: bool = false) -> float:
	var contributors: Array[Blorb] = []
	for slot in slots:
		var blorb := _blorb_suit.worn_blorb_for_slot(slot)
		if blorb != null:
			contributors.append(blorb)
	return (
		HumanoidLocomotion.averaged_blorb_speed_multiplier(contributors, Player.SPECIAL_MOVEMENT_SPEED_PER_POINT)
		if averaged
		else HumanoidLocomotion.blorb_speed_multiplier(contributors, Player.SPECIAL_MOVEMENT_SPEED_PER_POINT)
	)


## How many water limbs are jetting while he swims, which is nothing at all
## when he is out of the water.
func _direct_swim_jets() -> int:
	if not (_direct_diving):
		return 0
	return _powers.swim_jet_count()


func drive_from_player(direction: Vector3, delta: float, sprinting: bool, jump_pressed: bool) -> void:
	if not is_player_controlled or _mounted:
		return
	if _update_direct_crystal_riding(direction, delta, sprinting, jump_pressed):
		return
	var planar := Vector2(direction.x, direction.z)
	if direction.length_squared() > 1.0:
		direction = direction.normalized()
	if planar.length_squared() > 1.0:
		planar = planar.normalized()
	var dirtbike_ballistic:=_direct_dirtbike_active and (
		_direct_dirtbike_airborne or (not is_on_floor()) or jump_pressed
	)
	var speed := HumanoidLocomotion.ground_speed(_playable_profile, sprinting)
	if _direct_dirtbike_active:
		speed *= Player.DIRTBIKE_SPEED_MULTIPLIER
		if _direct_dirtbike_front_active:
			speed *= Player.DIRTBIKE_WHEELIE_SPEED_MULTIPLIER
	if _blorb_suit.has_blorb_skates() and sprinting and not _direct_ice_skates_active:
		speed *= _special_speed_multiplier(["leg_left", "leg_right"])
	if _direct_diving:
		speed = Player.LAKE_DIVE_SPEED * _special_speed_multiplier(["head", "leg_left", "leg_right"], true)
		if sprinting:
			speed *= Player.AERIAL_FAST_SPEED_MULTIPLIER
	elif _direct_flying:
		speed = Player.AIR_FLIGHT_SPEED * _special_speed_multiplier(["torso"])
		# Fire feet are independent jet boosters during chest flight; each
		# contributing leg compounds exactly as it does for the human motor.
		var fire_boosters: Array[String] = []
		for slot in ["leg_left", "leg_right"]:
			var booster := _blorb_suit.worn_blorb_in_slot(slot)
			if booster != null and booster.element_state == "fire" and Input.is_action_pressed("left_leg_power" if slot == "leg_left" else "right_leg_power"):
				fire_boosters.append(slot)
		if not fire_boosters.is_empty():
			speed *= _special_speed_multiplier(fire_boosters)
		if sprinting:
			speed *= Player.FLIGHT_SPRINT_SPEED_MULTIPLIER
	elif _powers.fire_limb_flight:
		speed = Player.AIR_FLIGHT_SPEED * _special_speed_multiplier(["arm_left", "arm_right", "leg_left", "leg_right"], true)
		if sprinting:
			speed *= Player.FLIGHT_SPRINT_SPEED_MULTIPLIER
	# Water jets underwater propel the swimmer, each firing limb adding to
	# the blast. The shared power decides how much, so his jets match the
	# human's rather than doing nothing at all as they did.
	if _direct_diving:
		speed *= SwimMode.jet_speed_multiplier(_direct_swim_jets())
	if (
		_direct_ice_skating_active
		and not (_direct_diving or _direct_flying or _direct_air_feet or _powers.fire_limb_flight)
	):
		var skating_velocity:=Vector2(velocity.x,velocity.z)
		var skate_speed_before:=skating_velocity.length()
		if planar.length_squared()>0.0001:
			var skate_speed:=HumanoidLocomotion.ground_speed(
				_playable_profile,sprinting
			)*Player.ICE_SKATE_SPEED_MULTIPLIER*_special_speed_multiplier(["leg_left","leg_right"])
			skating_velocity=HumanoidLocomotion.drive_wheel_velocity(
				skating_velocity,planar,skate_speed,delta,
				Player.ICE_SKATE_DRIVE_ACCELERATION*(Player.ICE_SKATE_SPRINT_THRUST_MULTIPLIER if sprinting else 1.0),Player.ICE_SKATE_LATERAL_GRIP,
				Player.ICE_SKATE_REVERSE_BRAKING,Player.ICE_SKATE_STOP_SPEED
			)
		else:
			skating_velocity=HumanoidLocomotion.coast_wheel_velocity(
				skating_velocity,0.0,delta,Player.ICE_SKATE_ROLLING_RESISTANCE,
				Player.ICE_SKATE_AIR_DRAG,Player.ICE_SKATE_STOP_SPEED,
				Player.ICE_SKATE_TERMINAL_SPEED
			)
		if skating_velocity.length()>Player.ICE_SKATE_TERMINAL_SPEED:
			skating_velocity=skating_velocity.normalized()*Player.ICE_SKATE_TERMINAL_SPEED
		velocity.x=skating_velocity.x
		velocity.z=skating_velocity.y
		var skate_acceleration:=maxf((skating_velocity.length()-skate_speed_before)/maxf(delta,0.0001),0.0)
		var sound_cycle:=fposmod(_ice_skates.stride_phase()/TAU,1.0)
		var sound_left:=Player.ice_skate_stroke(sound_cycle)
		var sound_right:=Player.ice_skate_stroke(fposmod(sound_cycle+0.5,1.0))
		UISounds.pulse_ice_skates(
			get_instance_id(),skating_velocity.length(),skate_acceleration,
			1.0-sound_left.y,1.0-sound_right.y
		)
	elif _penguin.sliding:
		var slide_ctx := _traversal_context(delta)
		slide_ctx.direction = Vector3(planar.x, 0.0, planar.y)
		var slide_heading := _penguin.slide_step(slide_ctx, _direct_is_supported_by_ice())
		if slide_heading != Vector2.ZERO:
			rotation.y = lerp_angle(
				rotation.y, atan2(slide_heading.x, slide_heading.y), minf(ROTATION_SPEED * delta, 1.0)
			)
	elif _penguin.diving and (jump_pressed or not is_on_floor()):
		# A dive is ballistic: the launch carries, exactly as the skate and
		# board launches do. Ordinary walking used to overwrite it on the very
		# next frame, so a 15 m/s dive landed at his 2.5 m/s walking pace and
		# the belly slide had almost nothing left to scrub.
		pass
	elif (
		_direct_snowboard_active
		and is_on_floor()
		and not (_direct_diving or _direct_flying or _direct_air_feet or _powers.fire_limb_flight)
	):
		var board_ctx := _traversal_context(delta)
		board_ctx.direction = Vector3(planar.x, 0.0, planar.y)
		var board_velocity: Vector2
		if _direct_snowboard_surface():
			var support_normal: Vector3 = terrain.get_mesh_normal(global_position.x, global_position.z)
			board_velocity = _snowboard_mode.glide(
				board_ctx, support_normal, _direct_is_supported_by_ice()
			)
		else:
			board_velocity = _snowboard_mode.brake_off_snow(board_ctx)
		velocity.x = board_velocity.x
		velocity.z = board_velocity.y
		if board_velocity.length_squared() > 0.01:
			_direct_snowboard_heading = Vector3(board_velocity.x, 0.0, board_velocity.y).normalized()
	elif (
		_direct_dirtbike_active
		and not (_direct_diving or _direct_flying or _direct_air_feet or _powers.fire_limb_flight)
	):
		var rolling:=Vector2(velocity.x,velocity.z)
		if dirtbike_ballistic:
			pass
		elif planar.length_squared()>0.0001:
			rolling=_dirtbike.drive(rolling,planar,speed,delta)
		else:
			var wheels_down: bool = is_on_floor() and not _direct_dirtbike_airborne
			rolling=_dirtbike.coast(
				rolling,_direct_dirtbike_slope() if wheels_down else 0.0,delta,wheels_down
			)
		velocity.x=rolling.x
		velocity.z=rolling.y
	elif _direct_ice_skate_airborne:
		# Steering may rotate Xiao's pose below, but never rewrites the launch.
		pass
	else:
		velocity.x = planar.x * speed
		velocity.z = planar.y * speed
	if _direct_diving or _direct_flying or _direct_air_feet or _powers.fire_limb_flight:
		velocity = direction * speed
		_direct_vertical_velocity = velocity.y
	elif _powers.powered_hover_active():
		var height_error: float = _direct_hover_height - global_position.y
		_direct_vertical_velocity = clampf(
			height_error * Player.POWERED_HOVER_SETTLE_SPEED,
			-Player.POWERED_HOVER_LIFT_SPEED,
			Player.POWERED_HOVER_LIFT_SPEED
		)
		velocity.y = _direct_vertical_velocity
	elif _direct_lava_surface:
		global_position.y = _direct_liquid_level
		_direct_vertical_velocity = 0.0
		velocity.y = 0.0
	elif _direct_dirtbike_airborne:
		velocity=HumanoidLocomotion.ballistic_step(velocity,delta,_playable_profile,32.0)
		_direct_vertical_velocity=velocity.y
	elif _direct_ice_skate_airborne:
		velocity=HumanoidLocomotion.ballistic_step(velocity,delta,_playable_profile,32.0)
		_direct_vertical_velocity=velocity.y
	elif (is_on_floor() or _direct_is_supported_by_ice()) and jump_pressed and _penguin.is_available(_traversal_context(delta)):
		# In the suit a jump is a dive.
		_begin_direct_penguin_dive(Vector3(planar.x, 0.0, planar.y))
	elif _direct_one_way_support(delta):
		# Clouds and tree canopies hold him up exactly as they do the human;
		# he never asked them before, so both were thin air to him.
		pass
	elif is_on_floor() or _direct_is_supported_by_ice():
		if jump_pressed:
			_direct_vertical_velocity = HumanoidLocomotion.jump_speed(
				_playable_profile,
				Player.DIRTBIKE_JUMP_HEIGHT_MULTIPLIER if _direct_dirtbike_active else 1.0
			)
			if _direct_ice_skates_active:
				_direct_vertical_velocity=maxf(
					_direct_vertical_velocity,HumanoidLocomotion.jump_speed(_playable_profile)
				)
			_direct_dirtbike_airborne = _direct_dirtbike_active
			if _direct_ice_skates_active and _direct_ice_skate_was_supported:
				_direct_ice_skate_airborne=true
				_direct_ice_skating_active=false
		else:
			_direct_vertical_velocity = 0.0
	else:
		var gravity_velocity := HumanoidLocomotion.apply_gravity(
			_direct_vertical_velocity, delta, _playable_profile, 32.0
		)
		var gravity_factor := 1.0
		var atmosphere := AtmosphereLayer.active(get_tree())
		if atmosphere != null:
			gravity_factor = atmosphere.gravity_factor_at(global_position)
		_direct_vertical_velocity = lerpf(_direct_vertical_velocity, gravity_velocity, gravity_factor)
	velocity.y = _direct_vertical_velocity
	if _direct_diving:
		var dive_floor := _direct_floor_height + Player.LAKE_DIVE_FLOOR_CLEARANCE
		var dive_surface := _direct_liquid_level - Player.LAKE_SWIM_FOOT_DEPTH
		global_position.y = clampf(global_position.y, dive_floor, dive_surface)
	var pre_move_position := global_position
	var bounced_before_move: bool = _try_direct_blorb_bounce(delta)
	move_and_slide()
	_update_direct_ice_skate_airtime(delta,pre_move_position)
	_resolve_direct_dirtbike_motion(delta,pre_move_position)
	_resolve_direct_snowboard_motion(delta,pre_move_position)
	# CharacterBody movement can carry the body beyond a liquid boundary after
	# the pre-move clamp. Clamp the resolved position too, matching the human
	# swimmer's hard floor/surface guarantees.
	if _direct_diving:
		var resolved_dive_floor: float = _direct_floor_height + Player.LAKE_DIVE_FLOOR_CLEARANCE
		var resolved_dive_surface: float = _direct_liquid_level - Player.LAKE_SWIM_FOOT_DEPTH
		global_position.y = clampf(global_position.y, resolved_dive_floor, resolved_dive_surface)
	elif _direct_lava_surface:
		global_position.y = _direct_liquid_level
	if not bounced_before_move:
		_enforce_direct_blorb_bounce()
	if is_on_floor() and velocity.y <= 0.0 and not _direct_dirtbike_airborne:
		_direct_vertical_velocity = 0.0
	if planar.length_squared() > 0.0001:
		rotation.y = lerp_angle(rotation.y, atan2(planar.x, planar.y), ROTATION_SPEED * delta)
	_animate_direct_motion(delta, direction, speed)
	_apply_direct_power_pose(delta)
	_apply_direct_dirtbike_pose(delta)
	_apply_direct_swim_attitude(delta)
	_apply_direct_snowboard(delta)
	_update_direct_dirtbike_wheels(delta)
	_update_direct_power_fx()


func _ensure_direct_power_fx() -> void:
	if _direct_water_arm_fx.is_empty():
		_direct_water_arm_fx = [
			SuitPowerFX.make_water_stream(self, "LeftWaterHand"),
			SuitPowerFX.make_water_stream(self, "RightWaterHand"),
		]
		_direct_fire_arm_fx = [
			SuitPowerFX.make_fire_stream(self, "LeftFireHand"),
			SuitPowerFX.make_fire_stream(self, "RightFireHand"),
		]
		_direct_water_leg_fx = [
			SuitPowerFX.make_water_stream(self, "LeftWaterFoot"),
			SuitPowerFX.make_water_stream(self, "RightWaterFoot"),
		]
		_direct_fire_leg_fx = [
			SuitPowerFX.make_fire_stream(self, "LeftFireFoot"),
			SuitPowerFX.make_fire_stream(self, "RightFireFoot"),
		]
		_direct_electric_arm_fx = [
			LightningBolt.spawn(self, LightningBolt.ELECTRIC_LIGHTNING_COLOR),
			LightningBolt.spawn(self, LightningBolt.ELECTRIC_LIGHTNING_COLOR),
		]
		_direct_city_arm_fx = [
			LightningBolt.spawn(self, LightningBolt.CITY_LIGHTNING_COLOR),
			LightningBolt.spawn(self, LightningBolt.CITY_LIGHTNING_COLOR),
		]


func _update_direct_power_fx() -> void:
	_ensure_direct_power_fx()
	var forward: Vector3 = global_transform.basis.z.normalized()
	var hand_direction: Vector3 = Vector3.DOWN if _powers.fire_hand_hover else forward
	var roll_reference: Vector3 = forward
	SuitPowerFX.point_stream(_direct_water_arm_fx[0], _pivots["palm_left"], forward, _powers.left_arm_water, roll_reference)
	SuitPowerFX.point_stream(_direct_water_arm_fx[1], _pivots["palm_right"], forward, _powers.right_arm_water, roll_reference)
	SuitPowerFX.point_stream(_direct_fire_arm_fx[0], _pivots["palm_left"], hand_direction, _powers.left_arm_fire, roll_reference)
	SuitPowerFX.point_stream(_direct_fire_arm_fx[1], _pivots["palm_right"], hand_direction, _powers.right_arm_fire, roll_reference)
	SuitPowerFX.point_stream(_direct_water_leg_fx[0], _pivots["toe_left"], Vector3.DOWN, _powers.left_leg_water, roll_reference)
	SuitPowerFX.point_stream(_direct_water_leg_fx[1], _pivots["toe_right"], Vector3.DOWN, _powers.right_leg_water, roll_reference)
	SuitPowerFX.point_stream(_direct_fire_leg_fx[0], _pivots["toe_left"], Vector3.DOWN, _powers.left_leg_fire, roll_reference)
	SuitPowerFX.point_stream(_direct_fire_leg_fx[1], _pivots["toe_right"], Vector3.DOWN, _powers.right_leg_fire, roll_reference)
	SuitPowerFX.point_bolt(_direct_electric_arm_fx[0], _pivots["palm_left"], forward, _powers.left_arm_electric, roll_reference)
	SuitPowerFX.point_bolt(_direct_electric_arm_fx[1], _pivots["palm_right"], forward, _powers.right_arm_electric, roll_reference)
	SuitPowerFX.point_bolt(_direct_city_arm_fx[0], _pivots["palm_left"], forward, _powers.left_arm_city, roll_reference)
	SuitPowerFX.point_bolt(_direct_city_arm_fx[1], _pivots["palm_right"], forward, _powers.right_arm_city, roll_reference)


## Same trampoline invariant as the human motor: an ordinary Blorb can never
## become a stable floor. Resolve the descending crown crossing before physics
## can zero vertical velocity and strand both rigs in their squash/jump poses.
func _try_direct_blorb_bounce(delta: float) -> bool:
	if velocity.y > 0.1 or _direct_diving or _direct_flying or _direct_air_feet:
		return false
	# His origin sits at his feet, so his feet are simply where he is.
	var projected_xz := Vector2(
		global_position.x + velocity.x * delta, global_position.z + velocity.z * delta
	)
	var best := BlorbBounce.predicted(
		get_tree(), global_position.y, projected_xz, global_position.y + velocity.y * delta
	)
	if best == null:
		return false
	var surface: Variant = best.bounce_surface_height_at(projected_xz.x, projected_xz.y)
	if surface != null:
		global_position.y = BlorbBounce.release_height(surface as float)
	_launch_from_blorb(best)
	return true


## Collision-backed recovery closes the remaining edge case where a squashed
## or moving crown differs slightly from its analytic surface during a frame.
func _enforce_direct_blorb_bounce() -> bool:
	if velocity.y > 0.1 or _direct_diving or _direct_flying or _direct_air_feet:
		return false
	var candidate := BlorbBounce.in_contact(self)
	if candidate == null:
		return false
	var surface: Variant = candidate.bounce_surface_height_at(global_position.x, global_position.z)
	if surface != null:
		global_position.y = maxf(global_position.y, BlorbBounce.release_height(surface as float))
	_launch_from_blorb(candidate)
	return true


func _launch_from_blorb(blorb: Blorb) -> void:
	_direct_last_bounced_blorb = blorb
	_direct_vertical_velocity = HumanoidLocomotion.jump_speed(_playable_profile)
	velocity.y = _direct_vertical_velocity
	blorb.trigger_bounce_squash()
	blorb.finish_platform_aid()
	UISounds.play_blorb_bounce(false, get_instance_id())


func receive_platform_aid_bounce(platform: Blorb) -> void:
	if not is_player_controlled or platform == null:
		return
	var surface: Variant = platform.bounce_surface_height_at(global_position.x, global_position.z)
	if surface == null:
		return
	# Arrival is already constrained to the same physical support selected by
	# Player's downward probe. Put Xiao on the crown and launch immediately;
	# there is no intermediate planted frame that can shove or perma-squash.
	global_position.y = BlorbBounce.release_height(surface as float)
	_launch_from_blorb(platform)


func _animate_direct_motion(delta: float, direction: Vector3, speed: float) -> void:
	if _penguin.diving or _penguin.sliding:
		_animate_direct_penguin(delta)
		return
	if _direct_diving:
		_animate_direct_swim(delta, speed)
		return
	if _direct_flying:
		_animate_direct_flight(delta, direction)
		return
	if _direct_ice_skating_active:
		_animate_direct_ice_skating(delta)
		return
	if not is_on_floor() and not _direct_air_feet and not _direct_lava_surface:
		_animate_direct_airborne(delta)
		return
	var cadence := HumanoidLocomotion.walk_phase_step(
		1.0, Player.WALK_SWING_SPEED, speed, _playable_profile
	) / WALK_SWING_SPEED
	_animate_walk(delta, Vector2(velocity.x, velocity.z).length_squared() > 0.01, cadence)


## Skating's pose is IceSkateMode's, the same one the player uses: his own
## copy of it is gone. His rig can carry it now that his ankle articulates
## (see MonkeyFigure._rebuild_footed_leg()), and anything tuned on it from
## here lands for both of them.
func _animate_direct_ice_skating(delta: float) -> void:
	if Vector2(velocity.x, velocity.z).length() <= 0.12:
		_animate_walk(delta, false)
	_ice_skates.engaged = _direct_ice_skating_active
	_ice_skates.pose(_traversal_context(delta))


## Stands him on a cloud or in a tree canopy when one is under his feet and
## he is falling onto it. Returns true when one caught him.
func _direct_one_way_support(delta: float) -> bool:
	if _direct_vertical_velocity > 0.1 or _direct_diving or _direct_flying:
		return false
	var ceiling: float = global_position.y + 0.2
	var stand: Variant = WorldSupport.cloud_stand_height(self, 0.0, ceiling)
	if stand == null:
		stand = WorldSupport.canopy_stand_height(self, 0.0, ceiling)
	if stand == null:
		return false
	global_position.y = move_toward(global_position.y, float(stand), 8.0 * delta)
	_direct_vertical_velocity = 0.0
	velocity.y = 0.0
	return true


## Diving and sliding tip his body flat about its belly, the way the human's
## does, while his collision body stays upright.
func _animate_direct_penguin(delta: float) -> void:
	var ctx := _traversal_context(delta)
	_penguin.update_prone(ctx)
	var rig := _pivots.get("_rig") as Node3D
	if rig == null:
		return
	var attitude := _penguin.attitude()
	rig.rotation.z = lerp_angle(rig.rotation.z, float(attitude["roll"]), minf(8.0 * delta, 1.0))
	# The tip itself is applied by _apply_direct_swim_attitude(), which is now
	# the one place his body's pitch is written.


func _animate_direct_swim(delta: float, movement_speed: float) -> void:
	# The swim pose is SwimMode's, shared with the human. It carries the part
	# this body never had: a swimmer at rest hangs still with the legs
	# trailing, and only kicks once actually under way. This used to advance
	# the kick every frame regardless, which is why he paddled on the spot.
	var ctx := _traversal_context(delta)
	var reference: float = maxf(movement_speed, Player.LAKE_DIVE_SPEED)
	# The tail is a variant of the same power, so he gets one the moment his
	# suit qualifies rather than needing a second implementation.
	if _blorb_suit.mermaid_tail_active():
		_swim.update_mermaid_motion(ctx, reference * SwimMode.MERMAID_SPEED_MULTIPLIER)
		_swim.pose_mermaid(ctx, reference * SwimMode.MERMAID_SPEED_MULTIPLIER)
		if _direct_swim_jets() > 0:
			_swim.pose_jets(
				ctx, _powers.left_arm_water, _powers.right_arm_water,
				_powers.left_leg_water, _powers.right_leg_water, true
			)
		return
	_swim.update_motion(ctx, reference)
	_swim.pose_swim(ctx, reference)
	if _direct_swim_jets() > 0:
		_swim.pose_jets(
			ctx, _powers.left_arm_water, _powers.right_arm_water,
			_powers.left_leg_water, _powers.right_leg_water, false
		)


func _animate_direct_airborne(delta: float) -> void:
	var settle := Player.JUMP_POSE_SETTLE_SPEED * delta
	(_pivots["arm_left"] as Node3D).rotation.x = lerp_angle((_pivots["arm_left"] as Node3D).rotation.x, -(Player.JUMP_ARM_SWING - Player.JUMP_ARM_ASYMMETRY), settle)
	(_pivots["arm_right"] as Node3D).rotation.x = lerp_angle((_pivots["arm_right"] as Node3D).rotation.x, -(Player.JUMP_ARM_SWING + Player.JUMP_ARM_ASYMMETRY), settle)
	(_pivots["leg_left"] as Node3D).rotation.x = lerp_angle((_pivots["leg_left"] as Node3D).rotation.x, -Player.JUMP_HIP_BEND, settle)
	(_pivots["leg_right"] as Node3D).rotation.x = lerp_angle((_pivots["leg_right"] as Node3D).rotation.x, -Player.JUMP_HIP_BEND, settle)
	(_pivots["knee_left"] as Node3D).rotation.x = lerp_angle((_pivots["knee_left"] as Node3D).rotation.x, Player.JUMP_KNEE_BEND, settle)
	(_pivots["knee_right"] as Node3D).rotation.x = lerp_angle((_pivots["knee_right"] as Node3D).rotation.x, Player.JUMP_KNEE_BEND, settle)


func _animate_direct_flight(delta: float, direction: Vector3) -> void:
	var settle := Player.JUMP_POSE_SETTLE_SPEED * delta
	# His body lies along its travel through the shared attitude (see
	# _rig_pitch_target()); the spine keeps only a small extra bend so a climb
	# or dive still reads in the silhouette.
	var pitch := clampf(-direction.y, -0.8, 0.8) * 0.35
	(_pivots["spine"] as Node3D).rotation.x = lerp_angle((_pivots["spine"] as Node3D).rotation.x, pitch, settle)
	(_pivots["leg_left"] as Node3D).rotation.x = lerp_angle((_pivots["leg_left"] as Node3D).rotation.x, 0.0, settle)
	(_pivots["leg_right"] as Node3D).rotation.x = lerp_angle((_pivots["leg_right"] as Node3D).rotation.x, 0.0, settle)


func _apply_direct_power_pose(delta: float) -> void:
	if UIState.modal_open:
		return
	var settle: float = minf(Player.ARM_POWER_POSE_SETTLE_SPEED * delta, 1.0)
	var both_fire_hands: bool = _powers.fire_hand_hover
	for side in ["left", "right"]:
		var action: String = "%s_arm_power" % side
		if not Input.is_action_pressed(action):
			continue
		var arm := _pivots["arm_%s" % side] as Node3D
		var elbow := _pivots["elbow_%s" % side] as Node3D
		var wrist := _pivots["wrist_%s" % side] as Node3D
		if arm == null or elbow == null or wrist == null:
			continue
		if both_fire_hands:
			arm.rotation.x = lerp_angle(arm.rotation.x, Player.FIRE_JET_ARM_BACK_ANGLE, settle)
			arm.rotation.z = lerp_angle(
				arm.rotation.z,
				signf(arm.position.x) * Player.FIRE_JET_ARM_OUTWARD_ANGLE,
				settle
			)
			elbow.rotation.x = lerp_angle(elbow.rotation.x, Player.FIRE_JET_ELBOW_BEND, settle)
		else:
			arm.rotation.x = lerp_angle(arm.rotation.x, -Player.ARM_POWER_POSE_ANGLE, settle)
			# MonkeyFigure follows the same local-axis convention as the human:
			# this quarter turn presents the palm forward with fingertips vertical.
			wrist.rotation.z = lerp_angle(wrist.rotation.z, signf(arm.position.x) * PI * 0.5, settle)


## Skating a crystal track: the shared power, on his rig. It takes the whole
## frame when it engages, so his ordinary movement does not run at all while
## he rides. His origin sits on the ground, so his foot offset is zero.
func _update_direct_crystal_riding(
	direction: Vector3, delta: float, sprinting: bool, jump_pressed: bool
) -> bool:
	var ctx := _traversal_context(delta)
	ctx.sprinting = sprinting
	ctx.aim_basis = Basis(Vector3.UP, rotation.y)
	ctx.grounded = is_on_floor() and _direct_vertical_velocity <= 0.1
	var stick := Vector2(direction.x, direction.z)
	var blocked := (
		_direct_diving or _direct_flying or _direct_air_feet
		or _powers.fire_limb_flight or _direct_lava_surface or _direct_dirtbike_active
		or _direct_snowboard_active
	)
	var was_riding := _crystal.riding
	var owned := _crystal.ride(ctx, stick, jump_pressed and not UIState.modal_open, blocked, 0.0)
	if was_riding and not _crystal.riding:
		if _crystal.exit_velocity != Vector3.ZERO:
			velocity = _crystal.exit_velocity
		if jump_pressed and not UIState.modal_open:
			velocity.y = maxf(velocity.y, 0.0) + HumanoidLocomotion.jump_speed(_playable_profile)
		_direct_vertical_velocity = velocity.y
	if not owned:
		return false
	_direct_vertical_velocity = velocity.y
	var facing := _crystal.facing()
	if facing != Vector3.ZERO:
		rotation.y = lerp_angle(rotation.y, atan2(facing.x, facing.z), minf(ROTATION_SPEED * delta, 1.0))
	# A skating glide over his standing pose, then the shared skate stance.
	_animate_walk(delta, true)
	_ice_skates.engaged = _crystal.speed > 0.12
	_ice_skates.pose(ctx)
	UISounds.pulse_ice_skates(get_instance_id(), _crystal.speed, 0.0, 1.0, 1.0)
	return true


## The Penguin Suit, through the shared power: he had none at all. The dive
## and the belly slide are the same as the human's, on his own rig.
func _update_direct_penguin_state() -> void:
	var ctx := _traversal_context(0.016)
	var grounded := is_on_floor() or _direct_is_supported_by_ice()
	_penguin.update_state(ctx, grounded, _direct_is_supported_by_ice(), _direct_vertical_velocity > 0.0)


## Launches the dive: forward off a jump, toward the stick if it is held and
## otherwise the way he faces, at the shared power's own speed.
func _begin_direct_penguin_dive(direction: Vector3) -> void:
	var heading := direction
	if heading.length_squared() < 0.0001:
		heading = Vector3(sin(rotation.y), 0.0, cos(rotation.y))
	velocity = PenguinMode.dive_velocity(
		heading, HumanoidLocomotion.jump_speed(_playable_profile)
	)
	_direct_vertical_velocity = velocity.y
	_penguin.diving = true


## Snow legs, and the same left/right leg-power chord the player toggles a
## board with. The deck is built at his own rig scale, so it fits his feet.
func _update_direct_snowboard_state() -> void:
	var has_legs: bool = _blorb_suit.has_snowboard_legs()
	var was_active := _direct_snowboard_active
	_direct_snowboard_active = _snowboard_chord.update(has_legs)
	if _direct_snowboard_active:
		floor_max_angle = Player.DIRTBIKE_FLOOR_MAX_ANGLE
		if _direct_snowboard == null:
			var rig := _pivots.get("_rig") as Node3D
			if rig != null:
				_direct_snowboard = SnowboardMode.build_deck(rig, _playable_profile.suit_rig_scale)
	elif _direct_snowboard != null:
		_direct_snowboard.queue_free()
		_direct_snowboard = null
	if was_active and not _direct_snowboard_active:
		velocity.x = 0.0
		velocity.z = 0.0
		_snowboard_mode.reset()
		_direct_snowboard_up = Vector3.UP


## True where his board can actually slide: snow, or the frozen lake.
func _direct_snowboard_surface() -> bool:
	if terrain == null or not terrain.has_method("is_snow_footstep_surface"):
		return false
	var here := Vector2(global_position.x, global_position.z)
	if terrain.has_method("is_ice_surface") and terrain.is_ice_surface(here):
		return true
	return terrain.is_snow_footstep_surface(here)


## The board's own contact with the snow, after the move: the shared model,
## same as the player's. His origin sits on the ground, so his foot offset is
## zero.
func _resolve_direct_snowboard_motion(delta: float, _pre_move_position: Vector3) -> void:
	if not _direct_snowboard_active or terrain == null:
		return
	if _direct_diving or _direct_flying or _direct_lava_surface:
		return
	var target_h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	var rise: float = target_h - global_position.y
	var horizontal := Vector2(velocity.x, velocity.z)
	var surface_fall := horizontal.length() * _direct_dirtbike_slope()
	_snowboard_mode.follow_terrain(_traversal_context(delta), target_h, rise, surface_fall, 0.0)
	_direct_vertical_velocity = velocity.y


func _update_direct_dirtbike_state() -> void:
	_direct_dirtbike_active = _blorb_suit.has_dirtbike_legs()
	floor_max_angle = Player.DIRTBIKE_FLOOR_MAX_ANGLE if _direct_dirtbike_active else deg_to_rad(50.0)
	var can_wheelie: bool = _direct_dirtbike_active and _blorb_suit.has_dirtbike_arms()
	_direct_dirtbike_front_active = _wheelie_chord.update(can_wheelie, PowerChord.ARMS)
	if not _direct_dirtbike_front_active:
		_direct_dirtbike_supported_pitch = 0.0
		_direct_dirtbike_pitch_was_grounded = false
	_set_direct_dirtbike_wheel_presence()


## Same automatic paired-Ice-leg contract as Player. Geometry scales from
## the playable profile, while all momentum math uses the shared locomotion
## helpers and identical tuning constants.
func _update_direct_ice_skate_state() -> void:
	var has_legs: bool=_blorb_suit.has_ice_skate_legs() and not _blorb_suit.penguin_form_active()
	var was_active: bool=_direct_ice_skates_active
	_direct_ice_skates_active=has_legs
	var supported: bool=has_legs and is_player_controlled and _direct_is_supported_by_ice()
	if _direct_ice_skate_airborne and supported:
		_direct_ice_skate_airborne=false
	_direct_ice_skating_active=supported and not _direct_ice_skate_airborne
	if was_active and not has_legs:
		velocity.x=0.0
		velocity.z=0.0
		_ice_skates.reset()
		_direct_ice_skate_was_supported=false
		_direct_ice_skate_airborne=false
		_direct_ice_skate_surface_velocity=Vector3.ZERO
	_set_direct_ice_skate_visuals()


func _direct_is_supported_by_ice() -> bool:
	# His origin sits at his feet, and a climb is his equivalent of the
	# human's jump state.
	return IceSkateMode.supported_by_ice(
		_traversal_context(get_physics_process_delta_time()),
		global_position.y, velocity.y > 0.0
	)


func _update_direct_ice_skate_airtime(delta: float,pre_move_position: Vector3) -> void:
	_ice_skates.engaged = _direct_ice_skates_active and is_player_controlled
	var launch: Variant = _ice_skates.follow_ice(
		_traversal_context(delta), _direct_is_supported_by_ice(), pre_move_position,
		velocity.y > 0.0
	)
	_direct_ice_skate_was_supported = _ice_skates.was_supported
	_direct_ice_skate_airborne = _ice_skates.airborne
	_direct_ice_skate_surface_velocity = _ice_skates.surface_velocity
	if launch != null:
		velocity = launch as Vector3
		_direct_vertical_velocity = velocity.y


func _set_direct_ice_skate_visuals() -> void:
	var scale_factor: float=_playable_profile.suit_rig_scale
	if _direct_ice_skates_active:
		if not is_instance_valid(_direct_ice_skate_left):
			_direct_ice_skate_left=IceSkateMode.build_blade(
				_pivots["toe_left"] as Node3D,"LeftIceSkate",scale_factor
			)
		if not is_instance_valid(_direct_ice_skate_right):
			_direct_ice_skate_right=IceSkateMode.build_blade(
				_pivots["toe_right"] as Node3D,"RightIceSkate",scale_factor
			)
	else:
		if is_instance_valid(_direct_ice_skate_left):
			_direct_ice_skate_left.queue_free()
		if is_instance_valid(_direct_ice_skate_right):
			_direct_ice_skate_right.queue_free()
		_direct_ice_skate_left=null
		_direct_ice_skate_right=null
	var rig:=_pivots.get("_rig") as Node3D
	if rig!=null and not _mounted:
		var desired_lift: float=(
			IceSkateMode.visual_lift(scale_factor) if _direct_ice_skates_active else 0.0
		)
		rig.position.y+=desired_lift-_direct_ice_skate_lift_y
		_direct_ice_skate_lift_y=desired_lift


func _set_direct_dirtbike_wheel_presence() -> void:
	if _direct_dirtbike_active and _direct_dirtbike_rear_wheel == null:
		_direct_dirtbike_rear_wheel = _build_direct_dirtbike_wheel("RearDirtbikeWheel")
	elif not _direct_dirtbike_active and _direct_dirtbike_rear_wheel != null:
		_direct_dirtbike_rear_wheel.queue_free()
		_direct_dirtbike_rear_wheel = null
	if _direct_dirtbike_front_active and _direct_dirtbike_front_wheel == null:
		_direct_dirtbike_front_wheel = _build_direct_dirtbike_wheel("FrontDirtbikeWheel")
	elif not _direct_dirtbike_front_active and _direct_dirtbike_front_wheel != null:
		_direct_dirtbike_front_wheel.queue_free()
		_direct_dirtbike_front_wheel = null


func _build_direct_dirtbike_wheel(wheel_name: String) -> MeshInstance3D:
	var radius: float = Player.DIRTBIKE_WHEEL_RADIUS*_playable_profile.suit_rig_scale
	var thickness: float = Player.DIRTBIKE_WHEEL_THICKNESS*_playable_profile.suit_rig_scale
	var wheel: MeshInstance3D = SuperEgg.build_part(
		Vector3(radius,thickness*0.5,radius),Player.DIRTBIKE_WHEEL_COLOR,2.0,2.0
	)
	wheel.name = wheel_name
	add_child(wheel)
	return wheel


func _direct_dirtbike_slope() -> float:
	return DirtbikeMode.slope_along(terrain, global_position, Vector2(velocity.x, velocity.z))


func _resolve_direct_dirtbike_motion(delta: float,pre_move_position: Vector3) -> void:
	if not _direct_dirtbike_active or _direct_diving or _direct_lava_surface or _direct_flying:
		_dirtbike.was_climbing = false
		_direct_dirtbike_was_climbing = false
		_direct_dirtbike_airborne = false
		return
	# His origin sits at his feet, so he rides with no offset between them.
	var ground_height: float = terrain.get_mesh_height(global_position.x, global_position.z)
	_dirtbike.follow_terrain(
		_traversal_context(delta), ground_height, 0.0, _direct_dirtbike_slope(), pre_move_position
	)
	_direct_dirtbike_was_climbing = _dirtbike.was_climbing
	_direct_dirtbike_airborne = _dirtbike.airborne
	_direct_dirtbike_surface_velocity = _dirtbike.surface_velocity
	_direct_vertical_velocity = velocity.y


## The riding stance, and the deck under it. Both are the shared power's, so
## his board looks and behaves like the player's at his own size.
func _apply_direct_snowboard(delta: float) -> void:
	if terrain != null and _direct_snowboard_active and _direct_snowboard_surface():
		var normal: Vector3 = terrain.get_mesh_normal(global_position.x, global_position.z)
		_direct_snowboard_up = _direct_snowboard_up.slerp(normal, minf(6.0 * delta, 1.0)).normalized()
	_snowboard_mode.pose_stance(
		_traversal_context(delta), _direct_snowboard_active,
		_direct_snowboard_up, _direct_snowboard_heading
	)
	if _direct_snowboard == null:
		return
	var forward := _direct_snowboard_heading.normalized()
	var up := _direct_snowboard_up
	forward = (forward - up * forward.dot(up))
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var across := forward.cross(up).normalized()
	if across.length_squared() < 0.001:
		return
	up = across.cross(forward).normalized()
	_direct_snowboard.global_transform.basis = Basis(forward, up, across)
	var ankle_left := _pivots.get("ankle_left") as Node3D
	var ankle_right := _pivots.get("ankle_right") as Node3D
	if ankle_left != null and ankle_right != null:
		var mid := (ankle_left.global_position + ankle_right.global_position) * 0.5
		_direct_snowboard.global_position = mid - up * SnowboardMode.THICKNESS * _playable_profile.suit_rig_scale


## Swimming lies the body down along its travel instead of paddling along
## bolt upright, which is what he did until now: his limbs had a swim pose
## but nothing ever pitched his body, because the human's own pitched body
## (Player._pose_body_skull_anchored()) sits below the early return that
## hands his frame over.
##
## Same technique his wheelie already uses: turn the rig about a spine anchor
## and put the anchor back where it was, so he pivots around his own middle
## rather than swinging about his feet. Diving lies him flatter than swimming
## at the surface, where his head stays up.
const SWIM_BODY_PITCH := deg_to_rad(76.0)
const SURFACE_SWIM_BODY_PITCH := deg_to_rad(52.0)
const SWIM_BODY_PITCH_SPEED := 4.5


## Which power owns how far his body lies over this frame, and by how much.
##
## Several used to ease this same value toward different targets at once --
## the penguin tipping flat while the dirt bike straightened, the swim
## lying down while the dirt bike straightened -- and the result was a body
## stuck at whatever angle the tug of war settled on: 34 degrees instead of
## 90, 21 instead of 52. Resolving one owner per frame, in priority order,
## is the fix for the whole class rather than another guard per pair.
func _rig_pitch_target(delta: float) -> float:
	if _penguin.diving or _penguin.sliding:
		return float(_penguin.attitude()["tip"])
	if _direct_flying or _powers.fire_limb_flight:
		var flight_ctx := _traversal_context(delta)
		_flight.update_motion(flight_ctx)
		return _flight.attitude_pitch(velocity)
	if _direct_diving:
		return _swim.attitude_pitch(_direct_diving)
	if _direct_dirtbike_active:
		# The wheelie owns its own pitch entirely.
		return NAN
	return 0.0


func _apply_direct_swim_attitude(delta: float) -> void:
	var rig: Node3D = _pivots.get("_rig") as Node3D
	var spine: Node3D = _pivots.get("spine") as Node3D
	if rig == null or spine == null or _mounted:
		return
	var target := _rig_pitch_target(delta)
	if is_nan(target):
		# Something else owns the pitch outright this frame.
		return
	if target == 0.0 and not (_direct_diving):
		_swim.reset()
	if absf(rig.rotation.x - target) < 0.0005:
		return
	var anchor: Vector3 = spine.global_position
	rig.rotation.x = lerp_angle(rig.rotation.x, target, minf(SWIM_BODY_PITCH_SPEED * delta, 1.0))
	rig.global_position += anchor - spine.global_position


func _apply_direct_dirtbike_pose(delta: float) -> void:
	if not _direct_dirtbike_active or _direct_flying:
		# The rig's own pitch is not this function's to settle. It used to
		# straighten the body here whenever the bike was not in use, which
		# meant every other attitude -- the swimmer lying down, the flier
		# lying along its travel -- was fighting a second system easing the
		# same value, and the two met well short of the intended angle.
		# _apply_direct_swim_attitude() now resolves one owner per frame and
		# eases back upright itself when nothing owns it.
		return
	var rig: Node3D = _pivots.get("_rig") as Node3D
	var spine: Node3D = _pivots["spine"] as Node3D
	var settle: float = minf(Player.DIRTBIKE_POSE_SETTLE_SPEED*delta,1.0)
	for side in ["left","right"]:
		var leg: Node3D = _pivots["leg_%s" % side]
		var knee: Node3D = _pivots["knee_%s" % side]
		var ankle: Node3D = _pivots["ankle_%s" % side]
		leg.rotation.x = lerp_angle(leg.rotation.x,-Player.DIRTBIKE_HIP_BACK_ANGLE,settle)
		leg.rotation.z = lerp_angle(leg.rotation.z,signf(leg.position.x)*Player.DIRTBIKE_HIP_SPLAY,settle)
		knee.rotation.x = lerp_angle(knee.rotation.x,Player.DIRTBIKE_KNEE_BEND,settle)
		ankle.rotation.x = lerp_angle(ankle.rotation.x,Player.DIRTBIKE_ANKLE_BEND,settle)
	if not _direct_dirtbike_front_active:
		return
	if rig == null or spine == null:
		return
	for side in ["left","right"]:
		var arm: Node3D = _pivots["arm_%s" % side] as Node3D
		var elbow: Node3D = _pivots["elbow_%s" % side] as Node3D
		if arm != null:
			arm.rotation.x = lerp_angle(arm.rotation.x,-Player.ARM_POWER_POSE_ANGLE,settle)
		if elbow != null:
			elbow.rotation.x = lerp_angle(elbow.rotation.x,0.0,settle)
	var front: Vector3 = ((_pivots["wrist_left"] as Node3D).global_position+(_pivots["wrist_right"] as Node3D).global_position)*0.5
	var rear: Vector3 = ((_pivots["ankle_left"] as Node3D).global_position+(_pivots["ankle_right"] as Node3D).global_position)*0.5
	var local_front: Vector3 = rig.global_transform.affine_inverse()*front
	var local_rear: Vector3 = rig.global_transform.affine_inverse()*rear
	var relative: Vector3 = local_front-local_rear
	var target_pitch: float = atan2(relative.y,relative.z)
	var wheelbase: float = Vector2(front.x-rear.x,front.z-rear.z).length()
	if wheelbase > 0.05 and not _direct_dirtbike_airborne:
		var front_h: float = terrain.get_mesh_height(front.x,front.z)
		var rear_h: float = terrain.get_mesh_height(rear.x,rear.z)
		var contact_radius: float = Player.DIRTBIKE_WHEEL_RADIUS*_playable_profile.suit_rig_scale
		if front.y-contact_radius-front_h<=0.28*_playable_profile.suit_rig_scale:
			_direct_dirtbike_supported_pitch=-atan2(front_h-rear_h,wheelbase)
		target_pitch += _direct_dirtbike_supported_pitch
	if _direct_dirtbike_airborne:
		if _direct_dirtbike_pitch_was_grounded:
			_direct_dirtbike_airborne_pitch=rig.rotation.x
		target_pitch=_direct_dirtbike_airborne_pitch
	var rear_anchor: Vector3 = rear
	rig.rotation.x = lerp_angle(rig.rotation.x,target_pitch,minf(Player.DIRTBIKE_WHEELIE_SETTLE_SPEED*delta,1.0))
	var moved_rear: Vector3 = ((_pivots["ankle_left"] as Node3D).global_position+(_pivots["ankle_right"] as Node3D).global_position)*0.5
	rig.global_position += rear_anchor-moved_rear
	if not _direct_dirtbike_airborne:
		var settled_rear: Vector3 = ((_pivots["ankle_left"] as Node3D).global_position+(_pivots["ankle_right"] as Node3D).global_position)*0.5
		var radius: float = Player.DIRTBIKE_WHEEL_RADIUS*_playable_profile.suit_rig_scale
		var rear_error: float = terrain.get_mesh_height(settled_rear.x,settled_rear.z)+radius-settled_rear.y
		rig.global_position.y += rear_error
	_direct_dirtbike_pitch_was_grounded=not _direct_dirtbike_airborne


func _position_direct_dirtbike_wheel(wheel: MeshInstance3D,a: Node3D,b: Node3D,delta: float) -> void:
	if wheel == null or a == null or b == null:
		return
	var midpoint: Vector3 = (a.global_position+b.global_position)*0.5
	var axle: Vector3 = b.global_position-a.global_position
	axle = axle.normalized() if axle.length() > 0.001 else global_transform.basis.x
	var seed: Vector3 = Vector3.FORWARD if absf(axle.dot(Vector3.FORWARD)) < 0.9 else Vector3.UP
	var x_axis: Vector3 = seed.cross(axle).normalized()
	var z_axis: Vector3 = axle.cross(x_axis).normalized()
	wheel.global_transform = Transform3D(Basis(x_axis,axle,z_axis),midpoint)
	var radius: float = Player.DIRTBIKE_WHEEL_RADIUS*_playable_profile.suit_rig_scale
	wheel.rotate_object_local(Vector3.UP,Vector2(velocity.x,velocity.z).length()/maxf(radius,0.01)*delta)


func _update_direct_dirtbike_wheels(delta: float) -> void:
	if _direct_dirtbike_rear_wheel != null:
		_position_direct_dirtbike_wheel(_direct_dirtbike_rear_wheel,_pivots["ankle_left"],_pivots["ankle_right"],delta)
	if _direct_dirtbike_front_wheel != null:
		_position_direct_dirtbike_wheel(_direct_dirtbike_front_wheel,_pivots["wrist_left"],_pivots["wrist_right"],delta)


func begin_mounted(_mount: Node3D) -> void:
	_mounted = true
	collision_layer = 0
	var rig := _pivots.get("_rig") as Node3D
	if rig != null:
		rig.top_level = true


func update_mounted_pose(seat_transform: Transform3D, delta: float) -> void:
	var rig := _pivots.get("_rig") as Node3D
	if rig == null:
		return
	# Keep the real gameplay body travelling with its visual rider so
	# dismounting resumes at the horse rather than at the pre-mount location.
	global_position = seat_transform.origin
	_update_direct_powered_movement(delta)
	var hip_height := (_pivots["spine"] as Node3D).position.y * DISPLAY_SCALE
	var scaled_basis := seat_transform.basis.scaled(Vector3.ONE * DISPLAY_SCALE)
	rig.global_transform = Transform3D(
		scaled_basis,
		seat_transform.origin - seat_transform.basis.y * hip_height
	)
	var settle := minf(10.0 * delta, 1.0)
	(_pivots["spine"] as Node3D).rotation.x = lerp_angle((_pivots["spine"] as Node3D).rotation.x, deg_to_rad(-10.0), settle)
	(_pivots["arm_left"] as Node3D).rotation.x = lerp_angle((_pivots["arm_left"] as Node3D).rotation.x, deg_to_rad(-48.0), settle)
	(_pivots["arm_right"] as Node3D).rotation.x = lerp_angle((_pivots["arm_right"] as Node3D).rotation.x, deg_to_rad(-48.0), settle)
	(_pivots["elbow_left"] as Node3D).rotation.z = lerp_angle((_pivots["elbow_left"] as Node3D).rotation.z, deg_to_rad(-18.0), settle)
	(_pivots["elbow_right"] as Node3D).rotation.z = lerp_angle((_pivots["elbow_right"] as Node3D).rotation.z, deg_to_rad(18.0), settle)
	(_pivots["leg_left"] as Node3D).rotation.x = lerp_angle((_pivots["leg_left"] as Node3D).rotation.x, -1.15, settle)
	(_pivots["leg_right"] as Node3D).rotation.x = lerp_angle((_pivots["leg_right"] as Node3D).rotation.x, -1.15, settle)
	(_pivots["knee_left"] as Node3D).rotation.x = lerp_angle((_pivots["knee_left"] as Node3D).rotation.x, 1.3, settle)
	(_pivots["knee_right"] as Node3D).rotation.x = lerp_angle((_pivots["knee_right"] as Node3D).rotation.x, 1.3, settle)
	_apply_direct_power_pose(delta)
	_update_direct_power_fx()


func end_mounted() -> void:
	_mounted = false
	collision_layer = 2 if is_player_controlled else 1
	var rig := _pivots.get("_rig") as Node3D
	if rig != null:
		rig.top_level = false
		rig.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * DISPLAY_SCALE), Vector3.ZERO)


# Compatibility aliases for old saves/scripts while callers migrate.
func begin_possession() -> void:
	begin_direct_control()


func end_possession() -> void:
	end_direct_control()


func _exit_tree() -> void:
	PartyControl.unregister_member(self)
