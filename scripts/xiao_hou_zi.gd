class_name XiaoHouZi
extends StaticBody3D

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
	_pivots = MonkeyFigure.build(self, MonkeyFigure.MONKEY_FUR_COLOR, DISPLAY_SCALE)
	_eyes = _pivots["eyes"]

	# Own dedicated group -- lets player.gd's switch_blorbus cycling find him
	# once recruited without ever touching the "blorbs" group. Never
	# add_to_group("blorbs") itself -- see this file's own class doc comment
	# for why staying outside that group is the whole mechanism keeping him
	# clear of every blorb-only system.
	add_to_group("xiao_hou_zi")
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
	collision_mask = 0

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


## Swaps the visible rig live, mid-game -- Monkey normally, Human for the
## duration of a possession (see begin_possession()/end_possession() below).
## Frees whichever rig root is currently parented under self and builds the
## other one in its place, mirroring player.gd's own _rebuild_visuals_rig().
## Player.build_portrait_body() is a static helper (nothing about it is
## instance-specific -- see its own doc comment in player.gd), so it's safe
## to call here even though this isn't a Player node.
func _rebuild_rig(as_human: bool) -> void:
	var old_rig := get_node_or_null("MonkeyFigure")
	if old_rig == null:
		old_rig = get_node_or_null("ProceduralFigure")
	if old_rig != null:
		old_rig.free()
	if as_human:
		_pivots = Player.build_portrait_body(self)
	else:
		_pivots = MonkeyFigure.build(self, MonkeyFigure.MONKEY_FUR_COLOR, DISPLAY_SCALE)
	_eyes = _pivots["eyes"]


func _process(delta: float) -> void:
	EyeBlink.apply(_eye_blink, delta, _eyes)
	_update_head_look(delta)
	# Keeps running in both rigs -- see this file's own class doc comment and
	# is_player_controlled's for why the same state machine already produces
	# the right behavior whether he's independently himself or standing in
	# for the human.
	_update_ai(delta)
	if not is_player_controlled:
		# Re-lofts his limb tubes/tail from their live pivot positions every
		# frame -- see MonkeyFigure.rebuild_limbs's own doc comment for why
		# this can't just run once at build time. ProceduralFigure's rig has
		# no equivalent need (see player.gd's own identically-conditioned
		# _process(), which only ever calls this while piloting the monkey).
		MonkeyFigure.rebuild_limbs(_pivots, self, delta)


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

	if not in_party and not _discovered:
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

	if not in_party and _discovered and dist_follow < FOLLOW_DISTANCE:
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


## Called by player.gd's _try_start_xiao_hou_zi_control(). Reskins THIS body
## as the human right where it already is standing -- no position/rotation
## change at all, mirroring Blorbus possession's own zero-teleport behavior
## (see this file's own class doc comment) -- and disables the now-
## nonsensical "Talk" prompt. is_player_controlled flipping to true is all
## _update_ai() needs to start treating him like a party member who'll stand
## put until the player (now off piloting this body) wanders away, then
## trail after them.
func begin_possession() -> void:
	is_player_controlled = true
	_look_target = null
	if _interact_area != null:
		_interact_area.monitoring = false
	_rebuild_rig(true)


## Called by player.gd's _end_xiao_hou_zi_control() -- reskins back to his
## own Monkey rig right where his own follow AI has already walked him to
## (no position snap needed; unlike the old hide-and-freeze version, this
## body's position has stayed continuously live and correct the whole time
## it stood in for the human), re-enables the "Talk" prompt, and resumes
## being himself.
func end_possession() -> void:
	if _interact_area != null:
		_interact_area.monitoring = true
	is_player_controlled = false
	_rebuild_rig(false)
