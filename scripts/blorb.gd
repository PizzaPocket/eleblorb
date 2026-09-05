class_name Blorb
extends StaticBody3D

signal progression_changed

## Size blorbs stay non-solid to the player but remain detectable by thrown
## items. Layer 9 is dedicated to that distinction; ordinary blorbs remain
## on world layer 1 as before.
const GIANT_THROWABLE_LAYER := 1 << 8

## A gooey little companion blorb, classic-JRPG-slime silhouette: a squashed
## sphere body, built procedurally (no asset for this exists yet). Mostly
## glides/slides smoothly along the ground -- toward a random nearby point
## while idling, or continuously toward the player once it wanders too far
## -- with only occasional sporadic hops mixed into that glide for
## character, not constant hopping.

@export var body_color: Color = Color(0.94, 0.96, 0.93, 0.85)
const BLORBUS_BODY_COLOR := Color(0.82, 0.60, 0.62, 0.85)
## A blorb's inherent type, distinct from its optional elemental merge.
## "size" identifies the single colossal wasteland blorb; it remains a
## creature of that type even though it has no elemental gem in its core.
@export_enum("normal", "size") var blorb_type: String = "normal"
## Uniform size relative to an ordinary blorb. Applied to the root, so the
## body, eyes, core, and collider all stay in proportion.
@export var size_multiplier: float = 1.0
## Lets a Size blorb spread wider and lower without changing its horizontal
## footprint. The wasteland giant uses this to read as a massive gliding
## puddle rather than a tall sphere.
@export var vertical_scale: float = 1.0
## Scales every self-directed motion: idle and follow gliding, turning, and
## any response to the player's shove. The wasteland giant uses 0.1.
@export var movement_speed_multiplier: float = 1.0
## False for creatures whose movement is a slow glide rather than the
## ordinary blorb's occasional hop. This also prevents climb hops.
@export var allow_movement_hops: bool = true
## A resident creature may be encountered without joining the player's party.
## The wasteland giant uses this so it remains a landmark in the north.
@export var can_join_party: bool = true
## Party-membership flag: only blorbs with this set true chase after the
## player once they wander too far (see _process's FOLLOW_DISTANCE check).
## Wild blorbs found out in the world (see wilderness_scatter.gd's
## _spawn_wild_blorbs()) leave this false at spawn -- but unlike an NPC, a
## wild blorb doesn't stay put
## forever once found: see _discovered/_bond_time below, which flips this
## to true on its own after the player's spent enough time with it. Default
## true so the original starter trio (Blorb1-3) keep their existing party
## behavior without needing every scene edited.
@export var in_party: bool = true
## Some wild blorbs are found already naturally elemental -- encountered
## out in the world already merged, rather than merged by hand with a
## thrown gem (see can_merge()'s own doc comment for that separate route).
## "" leaves it as a plain normal blorb, same as the default merge state.
@export var initial_element: String = ""
## True only for a throwaway instance blorb_portrait.gd spins up purely to
## be photographed for InventoryUI's Blorbs tab -- skips every gameplay
## hookup in _ready() (player lookup, party/collision setup, home position)
## that would error or make no sense with no real Player sibling in the
## capture rig, while still building the exact same visual body a real
## gameplay blorb uses.
@export var portrait_mode: bool = false
## True for a rare wild "shiny blorb" variant -- see _build_visuals()'s
## shiny-color override. Not an element: a shiny blorb has no gem merged
## into it and can never accept one (see can_merge()), and carries no
## elemental power. Purely a cosmetic rarity, distinguished from an
## ordinary ungemmed wild blorb by a distinctly bright, glossy pearlescent
## finish rather than the plain off-white body_color default.
@export var is_shiny: bool = false
## True only for the original starter trio (main.tscn's Blorb1-3) -- scopes
## the "third blorb becomes Blorbus" awakening (see
## _check_blorbus_awakening()) to just those three, not any wild blorb that
## later joins the party.
@export var is_starter_trio: bool = false
## Permanent non-elemental items absorbed into this blorb's core by a
## successful thrown-item hit (for example, the Diving Helmet).
@export var core_items: Array[String] = []

# Scaled down 15% from the original 1.0/1.5/0.25, per direct instruction.
# BODY_HEIGHT further flattened (RADIUS widened slightly alongside it, so
# the squash reads as spreading outward rather than just shrinking overall)
# per a later direct instruction asking for a shorter, more squashed-down
# default silhouette -- also drops the collision sphere's top height (see
# _build_visuals()'s collision_shape below), so an ordinary jump can
# actually clear it (see player.gd's jump_velocity, raised alongside this
# for the same reason). Eased back part of the way per a follow-up direct
# correction -- that pass read as squashed too far; these split the
# difference between the original 1.275/0.85 and the first (too-flat)
# 1.05/0.92 squash.
const RADIUS := 0.89
const BODY_HEIGHT := 1.15
# A full (non-hemisphere) squashed sphere, not a dome with a flat cut cap --
# continuous curvature all the way around. Sinking part of it below y=0
# gives a grounded, "resting in the grass" look without a hard flat bottom.
const EMBED_DEPTH := 0.2125
const COLLIDER_RADIUS := RADIUS * 0.9
## Root-to-crown height shared by the visible body and its collision sphere.
## Keeping these identical lets feet visibly meet the goo before a bounce.
const BOUNCE_CROWN_HEIGHT := BODY_HEIGHT - EMBED_DEPTH

# Radius-vs-height profile for the body's lathe (surface of revolution) --
# t=0 is the bottom pole, t=1 the top pole, widest ring at BULGE_T (0.30,
# not the geometric mid-height) for a "water balloon sagging under its own
# weight" silhouette. See BlorbBodyShape.profile_radius() for the actual
# curve (a smooth elliptical underside and subtly rounded version of the
# original narrow upper taper, factored out there so blorb_suit.gd's hat can
# reuse the same silhouette) -- BULGE_T is kept here too since _build_visuals()
# below still needs it directly for the core's own bulge-height placement.
const BULGE_T := 0.30

const CORE_RADIUS := 0.07  # apple-sized, matches gem.gd's own default scale
const HEAD_MOD_ITEMS := ["Diving Helmet", "Knight's Helm"]
## The "shiny blorb" cosmetic override applied in _build_visuals() -- a
## bright pearlescent cream, distinctly shinier than the plain off-white
## body_color default, but deliberately not tinted toward any element's own
## color (see is_shiny's doc comment: shiny is a rarity, not a type).
const SHINY_BODY_COLOR := Color(1.0, 0.97, 0.88, 0.88)


func has_core_item(item_name: String) -> bool:
	return core_items.has(item_name)


func add_core_item(item_name: String) -> bool:
	if item_name == "" or core_items.has(item_name):
		return false
	if item_name in HEAD_MOD_ITEMS:
		for existing in core_items:
			if existing in HEAD_MOD_ITEMS:
				return false
	core_items.append(item_name)
	return true

const IDLE_GLIDE_SPEED := 1.4
const ARRIVE_EPS := 0.05
const ROTATION_SPEED := 6.0

# How far the player has to walk from a blorb's resting spot before it
# bothers catching up -- "a number of meters," not the instant you move.
# ARRIVE_DISTANCE is just "close enough," not a docking point to stand on
# exactly -- there's no fixed offset to reach, so nothing keeps recirculating
# to a specific spot around the player once it's within range.
const FOLLOW_DISTANCE := 7.0
const ARRIVE_DISTANCE := 3.0
const IDLE_WANDER_RADIUS := 1.2

## How far a not-yet-joined wild blorb (whether currently FOLLOWING,
## declined moments ago, or just discovered) will chase before giving up
## and returning to ordinary local wandering, per direct instruction --
## well beyond FOLLOW_DISTANCE/DISCOVERY_RADIUS so a brief obstruction or
## slow catch-up isn't punished, but not infinite. Doesn't apply once
## in_party -- a real party member has no leash.
const DROP_OFF_DISTANCE := 35.0

## How close the player has to get to a not-yet-discovered wild blorb
## (in_party == false, _discovered == false) before it notices them and
## starts tagging along -- the Hud's own compass hint (see hud.gd) is what's
## meant to guide the player into this range, not a visual cue on the blorb
## itself.
const DISCOVERY_RADIUS := 9.0
## Total time a discovered wild blorb has to spend actually within
## FOLLOW_DISTANCE of the party (see _process's bond-timer block) before it
## joins outright. Doesn't have to be continuous -- falling behind and
## catching back up just pauses the accrual rather than resetting it, so an
## awkward bit of terrain doesn't undo real progress.
const JOIN_BOND_DURATION := 25.0
## How long a declined (or just-released) wild blorb ignores the player's
## proximity before DISCOVERY_RADIUS can notice it again -- see
## _decline_join_request()/release_to_wild(). Without this, a blorb that's
## just been told "no thanks" (or just kicked out of the party) is still
## standing right next to the party and would immediately re-discover them
## and re-accrue toward the exact same prompt, reading as a broken loop.
const JOIN_DECLINE_COOLDOWN := 20.0
const IDLE_PAUSE_MIN := 0.8
const IDLE_PAUSE_MAX := 2.2
# Slightly more than 2x the collision sphere radius (RADIUS * 0.9) so two
# blorbs' visible bodies don't overlap even when both are pushing toward it.
const MIN_SEPARATION := 2.0

# Roughly the player's own collision capsule radius (0.4, see player.tscn)
# plus this collision sphere's radius (RADIUS * 0.9), with a little margin
# so the push starts just before actual contact rather than right at it.
# Speed-limited (unlike _apply_separation's instant snap) so walking fast
# into one gives it a moment of give before it scoots aside, rather than
# an instant teleport away -- reads more like shoving something squishy.
const PLAYER_PUSH_RADIUS := 1.5
const PLAYER_PUSH_SPEED := 4.0
# The push is deliberately much weaker while the player's airborne than while
# grounded, per direct instruction -- a jump aimed at landing on top of a
# blorb (for the trampoline bounce, see trigger_bounce_squash()) shouldn't
# scoot the blorb out from under the player before they land. Not zero: a
# faint residual push still keeps a jump that clips the blorb's side from
# reading as passing clean through it.
const AIRBORNE_PLAYER_PUSH_SCALE := 0.15

# Sporadic hops: a small per-frame chance while gliding, not a constant gait.
const HOP_CHANCE_PER_SEC := 0.35
const HOP_HEIGHT := 0.16
const HOP_DURATION := 0.35
const WOBBLE_AMOUNT := 0.3
## Direct-control jump at ordinary scale. Size variants multiply the height
## by their body scale and divide the playback rate by their movement-speed
## multiplier, preserving distance proportions while moving more slowly.
const CONTROL_JUMP_HEIGHT := 3.3
## A deliberately game-heavy arc: from the 3.3m apex, the descent lasts
## about 0.42 seconds (roughly 37m/s² effective gravity), close to Player's
## own fast jump gravity rather than real-world gravity's floatier fall.
const CONTROL_JUMP_DURATION := 0.65
## Reach the apex early: a cubic ease-out gives takeoff a strong initial
## impulse whose upward velocity rapidly decays, leaving the longer second
## phase for an accelerating fall instead of a floaty symmetric arc.
const CONTROL_JUMP_APEX_FRACTION := 0.35
const SETTLE_SPEED := 8.0
## Visual-only slope alignment. The collider stays upright and stable while
## the goo body eases onto the plane it is visibly sliding across.
const SURFACE_TILT_SPEED := 6.0
## Maximum new ledge height a grounded blorb can acquire in one glide. This
## matches the player's approximate ordinary jump reach and, crucially,
## keeps the support ray local instead of selecting arbitrary roofs above.
const SUPPORT_ACQUIRE_HEIGHT := 1.5
# Free companions float partially immersed instead of obeying the terrain
# snap below a deep lake. This is deliberately separate from the giant,
# whose special goo traversal is handled by Player.
const LAKE_FLOAT_MIN_DEPTH := 0.4
const LAKE_FLOAT_SUBMERGENCE_FRACTION := 0.35
const LAKE_FLOAT_SETTLE_SPEED := 3.5
const AIR_HOVER_HEIGHT := 0.85
const AIR_HOVER_SETTLE_SPEED := 4.0
const FALL_GRAVITY := 28.0
const TERMINAL_FALL_SPEED := 24.0

# A one-shot squash for when the player lands on top (see
# trigger_bounce_squash()) -- trampoline-style compression, distinct from
# the idle hop's stretch (this flattens instead of stretching, and has no
# vertical hop offset of its own since the blorb itself doesn't move).
const BOUNCE_SQUASH_AMOUNT := 0.4

enum State { IDLE, FOLLOWING, COMBAT }

## How far a free-roaming party blorb will notice a skeleton NME and break
## off from following/wandering to fight it (see skeleton_nme.gd's
## "skeletons" group). Re-scanned every frame rather than cached -- matches
## this file's existing convention of proximity checks over event callbacks.
const AGGRO_RADIUS := 12.0
## Approach distance for a jump-attacking (non-elemental) blorb -- close
## enough to read as a bounce-off-the-target hit.
const MELEE_RANGE := 1.3
## Approach distance for a water/fire blorb's stream attack -- kept further
## back than melee range since the stream itself covers the gap.
const STREAM_RANGE := 5.0
## Base damage before combat_math.gd's own Strength scaling/variance/crit
## roll -- see _try_jump_attack(). Renamed from JUMP_ATTACK_DAMAGE now that
## it's a base rather than the literal dealt amount.
const JUMP_ATTACK_BASE_DAMAGE := 8.0
const JUMP_ATTACK_COOLDOWN := 1.2
## Matches player.gd's own WATER_POWER_MP_PER_SECOND/FIRE_POWER_MP_PER_SECOND
## exactly, so a blorb's arm-power drain rate and its combat-stream drain
## rate feel the same regardless of which context it's using the power in.
const WATER_STREAM_MP_PER_SECOND := 3.0
const FIRE_STREAM_MP_PER_SECOND := 4.5
## Base rate before combat_math.gd's own Strength scaling -- see
## _update_elemental_stream(). Renamed from STREAM_DAMAGE_PER_SECOND now
## that it's a base rather than the literal per-second rate.
const STREAM_BASE_DAMAGE_PER_SECOND := 6.0

@onready var terrain: Node = get_node("../Terrain")
@onready var body: Node3D = $Body

var _player: Node3D
var _follow_glide_speed: float = 6.0
var _home: Vector2
var _state: State = State.IDLE
var _rng := RandomNumberGenerator.new()

var _wander_target: Vector2
var _has_wander_target: bool = false
var _idle_pause_timer: float = 0.0

var _hop_active: bool = false
var _hop_elapsed: float = 0.0
var _control_jump_elapsed := 0.0
var _control_jump_active := false
var _control_jump_base_offset := 0.0

## True while a hop is specifically climbing a step up onto a higher
## surface (a slab edge, a ramp's own base) rather than just the ambient
## cosmetic hop -- see _process()'s own CLIMB_HOP_THRESHOLD check. Distinct
## from _hop_active: an ambient hop never needs _climb_start_y since the
## ground height barely changes across it, but a climb does.
var _climbing: bool = false
var _climb_start_y: float = 0.0

## Set when a suit dismount lands on a raised ordinary collider. While that
## support remains directly underneath the blorb, keep following it rather
## than immediately reverting to terrain-only movement on the next frame.
## This is deliberately scoped to a confirmed landing: see
## _ground_height_at() for why ordinary followers still do not search for
## arbitrary platforms above their heads.
var _dismount_support_active: bool = false
## Root-space falling is separate from the small cosmetic body hop. Free
## blorbs use this whenever their support is below them instead of snapping
## vertically to it (most visibly after removing a suit while flying).
var _fall_velocity: float = 0.0
var _falling_after_dismount: bool = false

## Whether a not-yet-partied wild blorb has noticed the player (see
## DISCOVERY_RADIUS) and started tagging along after the party. Meaningless
## once in_party is true.
var _discovered: bool = false
var _bond_time: float = 0.0
## True while the "wants to join your party" dialog is up for this blorb --
## guards _process's bond-timer block so it isn't re-triggered every single
## frame the dialog stays open (see _prompt_join_request()).
var _join_prompt_open: bool = false
## Counts down after a decline/release before DISCOVERY_RADIUS can notice
## this blorb again -- see JOIN_DECLINE_COOLDOWN's own doc comment.
var _join_decline_cooldown: float = 0.0

## "" (normal) / "water" / "fire" -- current merge state. "" means this
## blorb hasn't been given a gem yet and can still accept any element (see
## can_merge()); once set, it's locked in (merging again is a no-op).
var element_state: String = ""
var _body_material: StandardMaterial3D
var _core_mesh_instance: MeshInstance3D
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()
## Independent from eye blinking: each free air blorb has its own gentle,
## randomized wing-beat timing.
var _air_wing_flap_phase := 0.0
var _air_wing_flap_speed := 1.0

## Optional player-given name. A blank value is displayed as the Blorb's
## elemental identity ("water blorb", "normal blorb", etc.); Blorbus's true
## name is immutable and takes precedence over this field.
@export var blorb_name: String = ""

## Level-one stats are rolled once per instance so different blorbs begin as
## individuals rather than clones. Progression then grows those same stats
## deterministically (see _level_up()) instead of rerolling them, preserving
## each blorb's original strengths across the campaign.
const STAT_MIN := 5
const STAT_MAX := 15
const MAX_LEVEL := 99
const XP_THRESHOLD_BASE := 20.0
const XP_THRESHOLD_EXPONENT := 1.35
var strength: int = 0
var defense: int = 0
var max_hp: int = 0
var max_mp: int = 0
var current_hp: float = 0.0
var current_mp: float = 0.0
var level: int = 1
## XP earned inside the current level, not lifetime cumulative XP. Keeping
## this local to the current threshold makes the menu's filled-until-next-
## level bar direct and avoids precision loss at high cumulative totals.
var experience: int = 0
var _hp_regen_delay: float = 0.0
var _mp_regen_delay: float = 0.0

const HP_REGEN_PER_SECOND := 0.5
const HP_REGEN_DELAY := 4.0
const MP_REGEN_PER_SECOND := 2.25
const MP_REGEN_DELAY := 0.8

## True from the moment this blorb starts hopping toward the player's body
## through to when it hops back off again (see blorb_suit_controller.gd) --
## freezes its independent glide/idle AI and collision for the whole
## span (see _process's guard below), even during the brief flight where
## its round body is still visible and hasn't been swapped for the flat
## suit-piece geometry yet. Never set true/false from within this file --
## only blorb_suit_controller.gd's begin_worn()/finish_unworn() calls
## decide when a party blorb is called into the suit or released from it.
var is_worn: bool = false

## True once current_hp has been fully depleted by combat -- the blorb has
## "lost its mass" and disappears from the world entirely (conceptually
## returned to the player's blorb inventory) until HP regenerates back to
## max (see take_damage()/_update_resources()/melt()/_reform()). Frozen in
## place the same way is_worn freezes a suit-worn blorb (see _process's
## early-return below), and excluded from blorb suit eligibility by
## blorb_suit_controller.gd. Also settable before _ready() by
## blorb_portrait.gd for a core-only portrait capture -- see _build_visuals().
var is_melted: bool = false
var _collision_shape: CollisionShape3D

## Nearest skeleton NME currently being engaged in State.COMBAT -- see
## _process()'s combat scan. Null whenever not in combat.
var _combat_target: Node3D = null
var _attack_cooldown: float = 0.0
## Lazily built the first time a water/fire blorb streams at a skeleton --
## see _update_elemental_stream()/_make_combat_stream().
var _stream_particles: GPUParticles3D = null

## True once this blorb has awoken as Blorbus -- see become_blorbus().
## Permanently locks out can_merge() and adds a talk prompt. Never set
## directly; only _check_blorbus_awakening() flips it, and only once.
var is_blorbus: bool = false
## Player owns movement while psychically inhabiting this body. This keeps
## the ordinary idle/follow loop from fighting direct input.
var is_player_controlled: bool = false


func _ready() -> void:
	_rng.randomize()
	_air_wing_flap_speed = _rng.randf_range(1.2, 2.0)
	# Do this before the procedural children are built: their mesh and
	# collision dimensions inherit this root scale together.
	scale = Vector3(size_multiplier, size_multiplier * vertical_scale, size_multiplier)
	strength = _rng.randi_range(STAT_MIN, STAT_MAX)
	defense = _rng.randi_range(STAT_MIN, STAT_MAX)
	max_hp = _rng.randi_range(STAT_MIN, STAT_MAX) * 4
	max_mp = _rng.randi_range(STAT_MIN, STAT_MAX) * 2
	current_hp = max_hp
	current_mp = max_mp
	_build_visuals()
	if initial_element != "":
		merge_element(initial_element)
	if portrait_mode:
		return

	collision_layer = 1
	collision_mask = 0
	# The giant is traversed through its goo rather than treated as the
	# ordinary blorb's solid trampoline collider. Player owns its precise
	# mesh-profile lift and surface-walking behavior (see player.gd).
	if blorb_type == "size":
		collision_layer = GIANT_THROWABLE_LAYER
	add_to_group("blorbs")
	_player = get_node("../Player")
	# Reads the player's own walk speed directly rather than duplicating the
	# number, so it stays correct if move_speed is ever retuned. Sprinting
	# (sprint_multiplier on top of that) is intentionally faster than this,
	# so a blorb falls behind while you sprint and closes the gap once you
	# slow back down.
	_follow_glide_speed = _player.move_speed * movement_speed_multiplier
	_home = Vector2(global_position.x, global_position.z)
	# _ground_height_at(), not terrain.get_mesh_height() directly -- see
	# that function's own doc comment.
	global_position.y = _ground_height_at(global_position.x, global_position.z) + _ground_embed_offset()
	_idle_pause_timer = _rng.randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)


func _build_visuals() -> void:
	# A melted instance keeps only its core -- see is_melted's own doc
	# comment. blorb_portrait.gd sets is_melted = true before add_child()
	# specifically so a throwaway portrait-capture instance never builds
	# these meshes at all (not just hides them), since _world_aabb() there
	# measures every MeshInstance3D descendant regardless of .visible.
	if is_shiny:
		body_color = SHINY_BODY_COLOR
	if not is_melted:
		var body_mesh := MeshInstance3D.new()
		# Built through the same shared function blorb_suit.gd's worn pieces
		# use (see BlorbBodyShape.build_body_material()'s own doc comment) --
		# guarantees the two stay identically lit/reactive rather than risking
		# drift between two hand-kept-in-sync copies. ALPHA_DEPTH_PRE_PASS
		# (not plain ALPHA) matters specifically because a plain alpha-blend
		# material doesn't write depth, and Godot's shadow pass is depth-based
		# -- the body would render with no shadow at all while the (opaque)
		# eyes cast normal ones, reading as two floating shadow dots with
		# nothing connecting them. Winding for the lathe below was hand-
		# derived (checked that the cross product at a sample point on the +X
		# side comes out pointing +X, i.e. outward) rather than empirically
		# verified in-render -- cull disabled (part of the shared material) as
		# the same safety net gem.gd/terrain_generator.gd already lean on for
		# this exact class of uncertainty, guaranteeing visibility even if the
		# derivation is wrong; only shading would be affected.
		# Shiny gets a noticeably glossier finish (lower roughness, higher
		# metallic) plus a faint warm glow on top of its brighter body_color,
		# so the rarity reads even at a glance and not just up close.
		if is_shiny:
			_body_material = BlorbBodyShape.build_body_material(
				body_color, 0.03, 0.3, true, Color(1.0, 0.95, 0.8), 0.3
			)
		else:
			_body_material = BlorbBodyShape.build_body_material(body_color, 0.15, 0.05, false, Color.BLACK, 0.0)
		body_mesh.mesh = _build_body_mesh()
		body_mesh.set_surface_override_material(0, _body_material)
		body_mesh.position.y = -EMBED_DEPTH
		body.add_child(body_mesh)

		# Eyes are parented to body_mesh itself, whose own position already
		# carries the -EMBED_DEPTH offset -- so they use the raw, un-adjusted
		# bulge height in body_mesh's own vertex space (0..BODY_HEIGHT). The
		# core is parented to body directly instead, one level up, so it needs
		# that same offset applied explicitly.
		# A bit above the widest ring, not right on the equator -- reads more
		# like a face sitting on the upper body than eyes wrapped around the
		# middle. See BlorbBodyShape.eye_surface()'s own doc comment for the
		# dr_dy derivation (why the true surface normal isn't purely
		# horizontal here) -- shared with blorb_suit.gd's differently-scaled
		# hat covering rather than kept as a private copy.
		const EYE_T := 0.42
		var eye_data := BlorbBodyShape.eye_surface(EYE_T, RADIUS, BODY_HEIGHT)
		_eyes = BlorbFace.add_eyes(
			body_mesh, eye_data["radius"] as float, eye_data["y"] as float, eye_data["dr_dy"] as float, body_color
		)

	var bulge_y_local := BULGE_T * BODY_HEIGHT
	_core_mesh_instance = BlorbCore.build(CORE_RADIUS, Color(0.85, 0.9, 0.95), false)
	_core_mesh_instance.position.y = bulge_y_local - EMBED_DEPTH
	body.add_child(_core_mesh_instance)

	# Collision lives on the root (not on Body), so it doesn't get distorted
	# by the hop squash/stretch animation applied to Body's scale. Kept as
	# an approximating sphere rather than matching the new silhouette
	# exactly -- consistent with this file's existing precedent that
	# collision doesn't need to hug the visual mesh precisely.
	var collision_shape := CollisionShape3D.new()
	var collider := SphereShape3D.new()
	collider.radius = COLLIDER_RADIUS
	collision_shape.shape = collider
	# Preserve the broad horizontal collision radius, but lower its centre so
	# its upper pole meets the visible crown instead of floating above it.
	collision_shape.position = Vector3(0, BOUNCE_CROWN_HEIGHT - COLLIDER_RADIUS, 0)
	add_child(collision_shape)
	_collision_shape = collision_shape
	if is_melted:
		collision_shape.disabled = true


## Now a thin wrapper over BlorbBodyShape (see that file's own docstring) --
## kept as a private method here rather than inlining BlorbBodyShape.
## build_mesh(RADIUS, BODY_HEIGHT) at the one call site, so _build_visuals()
## above reads the same as it always did.
func _build_body_mesh() -> ArrayMesh:
	return BlorbBodyShape.build_mesh(RADIUS, BODY_HEIGHT)


## Per the world bible: "giving a blorb an elemental gem transforms it into
## an elemental blorb of that type" -- any normal (not yet merged) blorb
## accepts any elemental gem, no per-blorb restriction. An earlier version
## of this file locked each blorb to one pre-assigned element instead,
## which doesn't match that lore and made most gem/blorb pairings silently
## "not react" for no reason a player could discover.
func can_merge(element: String) -> bool:
	return element_state == "" and element != "" and not is_blorbus and not is_shiny


## "Normal", "Shiny" (the rare cosmetic wild variant, see is_shiny -- never
## elemental, so this takes priority over the element check below even
## though a shiny blorb's element_state is always "" in practice), or the
## capitalized element name -- InventoryUI's Blorbs tab row label.
func display_type() -> String:
	if blorb_type == "size":
		return "Size"
	if is_blorbus:
		return "Psychic"
	if is_shiny:
		return "Shiny"
	if element_state == "":
		return "Normal"
	return element_state.capitalize()


func display_name() -> String:
	if is_blorbus:
		return "Blorbus"
	var custom_name := blorb_name.strip_edges()
	if custom_name != "":
		return custom_name
	var element_name := element_state if element_state != "" else "normal"
	return "%s blorb" % element_name.to_lower()


## Surfaces the Accept/decline choice once a discovered wild blorb has bonded
## with the party long enough (see _process's JOIN_BOND_DURATION check) --
## replaces the old auto-join, per direct instruction.
func _prompt_join_request() -> void:
	_join_prompt_open = true
	var type_desc := display_type()
	var line := "A wild blorb wants to join your party."
	if type_desc != "Normal":
		line = "A wild %s blorb wants to join your party." % type_desc
	var actions: Array[Dictionary] = [{
		"label": "Accept.",
		"callback": func():
			DialogUI.hide_dialog()
			_accept_join_request(),
	}]
	DialogUI.show_line("Wild Blorb", line, actions, "No thanks.", _decline_join_request)


func _accept_join_request() -> void:
	_join_prompt_open = false
	in_party = true
	Hud.show_message("A wild blorb joined your party!")
	# Seeds a default slot assignment immediately (see BlorbSuitController's
	# own comment) -- per direct instruction, a blorb should already be
	# assigned to a body part from the moment it joins, not just once the
	# player has opened the paper-doll UI. _player is safe to use directly
	# here (unlike player.gd's own call-site, which has to defer) since this
	# runs well after every node's _ready() has already finished, mid-game.
	(_player as Player).get_blorb_suit().auto_assign_new_members()


## Declining doesn't just leave _discovered/in_party as they were -- with
## the party usually still standing right there, that would re-discover and
## re-accrue toward the exact same prompt within moments. Resetting both and
## sitting out DISCOVERY_RADIUS for JOIN_DECLINE_COOLDOWN instead lets the
## blorb actually wander off before it can be noticed again.
func _decline_join_request() -> void:
	_join_prompt_open = false
	_discovered = false
	_bond_time = 0.0
	_join_decline_cooldown = JOIN_DECLINE_COOLDOWN
	# Per direct instruction: a declined blorb shouldn't keep tagging along.
	# Clearing _discovered alone isn't enough on its own -- if _state was
	# already FOLLOWING (reaching the prompt at all requires having been
	# within FOLLOW_DISTANCE, so this is a real, not just theoretical, case),
	# nothing else would otherwise break it out of that state; the
	# movement code further down in _process() acts on _state directly, not
	# on _discovered.
	if _state == State.FOLLOWING:
		_state = State.IDLE
		_home = Vector2(global_position.x, global_position.z)
		_has_wander_target = false


## Counterpart to _accept_join_request() -- restores a party member to
## ordinary wild wandering. Blorbus is permanent and never eligible; callers
## (InventoryUI's release button) are expected to check is_blorbus themselves
## before offering this, but it's guarded here too since silently doing
## nothing is safer than an accidental permanent Blorbus release.
func release_to_wild() -> void:
	if is_blorbus or not in_party:
		return
	in_party = false
	_discovered = false
	_bond_time = 0.0
	_join_decline_cooldown = JOIN_DECLINE_COOLDOWN
	# Same reasoning as _decline_join_request()'s own identical reset -- a
	# released blorb mid-FOLLOWING would otherwise keep closing on the party
	# forever, since the movement code acts on _state directly, not in_party
	# or _discovered.
	if _state == State.FOLLOWING:
		_state = State.IDLE
		_home = Vector2(global_position.x, global_position.z)
		_has_wander_target = false


## Continuous elemental powers consume MP. Attempting to use an empty pool
## still refreshes the delay, preventing a held input from flickering the
## effect on for one frame every time a tiny amount regenerates.
func consume_mp(amount: float) -> bool:
	_mp_regen_delay = MP_REGEN_DELAY
	if current_mp <= 0.0 or amount <= 0.0:
		return false
	current_mp = maxf(current_mp - amount, 0.0)
	return true


## A familiar rising RPG curve: early levels arrive quickly enough to teach
## the system, while each successive level asks for meaningfully more XP.
func xp_to_next_level() -> int:
	if level >= MAX_LEVEL:
		return 0
	return maxi(1, roundi(XP_THRESHOLD_BASE * pow(float(level), XP_THRESHOLD_EXPONENT)))


func gain_experience(amount: int) -> void:
	if amount <= 0 or level >= MAX_LEVEL:
		return
	experience += amount
	while level < MAX_LEVEL:
		var threshold := xp_to_next_level()
		if experience < threshold:
			break
		experience -= threshold
		_level_up()
	if level >= MAX_LEVEL:
		experience = 0
	progression_changed.emit()


func _level_up() -> void:
	level += 1
	# Every level advances both core combat stats. Periodic extra points keep
	# milestones noticeable without random level-up rolls obscuring a blorb's
	# established identity. Strength and Defense now drive combat directly
	# (see combat_math.gd -- Strength scales an attack's own damage, Defense
	# mitigates incoming damage) rather than HP/MP growth, per direct
	# correction; HP and MP instead grow with level itself below.
	strength += 1 + (1 if level % 4 == 0 else 0)
	defense += 1 + (1 if level % 5 == 0 else 0)
	var hp_growth := 4 + ceili(float(level) / 5.0)
	var mp_growth := 2 + ceili(float(level) / 8.0)
	max_hp += hp_growth
	max_mp += mp_growth
	if not is_melted:
		current_hp = minf(current_hp + hp_growth, float(max_hp))
	current_mp = minf(current_mp + mp_growth, float(max_mp))
	Hud.show_passive_message("%s reached Level %d!" % [display_name(), level], 3.0)


func progression_snapshot() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"strength": strength,
		"defense": defense,
		"max_hp": max_hp,
		"max_mp": max_mp,
	}


## Applied after a portal-created Blorb has run _ready() and generated its
## throwaway level-one roll. Older snapshots without progression data simply
## keep that fresh roll, preserving compatibility with an in-progress game.
func restore_progression(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	level = clampi(int(snapshot.get("level", 1)), 1, MAX_LEVEL)
	experience = maxi(0, int(snapshot.get("experience", 0)))
	strength = maxi(1, int(snapshot.get("strength", strength)))
	defense = maxi(1, int(snapshot.get("defense", defense)))
	max_hp = maxi(1, int(snapshot.get("max_hp", max_hp)))
	max_mp = maxi(1, int(snapshot.get("max_mp", max_mp)))
	# World travel has always reformed carried blorbs at full resources. Keep
	# that established transition behavior while retaining their progression.
	current_hp = max_hp
	current_mp = max_mp
	is_melted = false
	if level >= MAX_LEVEL:
		experience = 0
	else:
		experience = mini(experience, xp_to_next_level() - 1)
	progression_changed.emit()


## Used by skeleton NMEs' punches (this blorb's own Defense mitigates the
## raw incoming amount -- see combat_math.gd's mitigated_damage()).
## Depleting current_hp fully melts the blorb -- see melt().
func take_damage(amount: float) -> void:
	if amount <= 0.0 or is_melted:
		return
	current_hp = maxf(current_hp - CombatMath.mitigated_damage(amount, defense), 0.0)
	_hp_regen_delay = HP_REGEN_DELAY
	if current_hp <= 0.0:
		melt()


func heal(amount: float) -> void:
	if amount > 0.0:
		current_hp = minf(current_hp + amount, float(max_hp))


func _update_resources(delta: float) -> void:
	_mp_regen_delay = maxf(_mp_regen_delay - delta, 0.0)
	_hp_regen_delay = maxf(_hp_regen_delay - delta, 0.0)
	if _mp_regen_delay <= 0.0:
		current_mp = minf(current_mp + MP_REGEN_PER_SECOND * delta, float(max_mp))
	if _hp_regen_delay <= 0.0:
		current_hp = minf(current_hp + HP_REGEN_PER_SECOND * delta, float(max_hp))
	if is_melted and current_hp >= float(max_hp):
		_reform()


## Depleting HP to 0 in combat "loses its mass" -- per direct instruction,
## the whole blorb disappears (not just the body/eyes, leaving a frozen core
## standing around in the world) and its collider is disabled, freezing
## independent AI/movement (see _process's is_melted early-return, the same
## shape as the existing is_worn one). It reads as conceptually returned to
## the player's blorb inventory until it regenerates back to a full, visible
## blorb once current_hp refills (_reform()). in_party is untouched -- it's
## still a party member the whole time, just not physically present.
##
## Hides `body` (which parents the body mesh, eyes, AND core -- see
## _build_visuals()), not the Blorb root itself -- the root's own `visible`
## is separately driven by player.gd while Blorbus is possessed and merged
## into the giant, and stomping that here would pop him back into view
## mid-merge if he ever melted in that state.
func melt() -> void:
	if is_melted:
		return
	is_melted = true
	# Melting is a combat reset, not merely a temporary visual state. Remove
	# every hit this Blorb registered against every live NME so reforming
	# before one of those enemies dies cannot restore stale XP eligibility.
	for nme in get_tree().get_nodes_in_group("skeletons"):
		if nme.has_method("unregister_xp_participant"):
			nme.unregister_xp_participant(self)
	body.visible = false
	if _collision_shape != null:
		_collision_shape.disabled = true
	_combat_target = null
	_state = State.IDLE
	_set_combat_stream_active(false)


func _reform() -> void:
	if not is_melted:
		return
	is_melted = false
	body.visible = true
	if _collision_shape != null:
		_collision_shape.disabled = false
	_home = Vector2(global_position.x, global_position.z)
	_state = State.IDLE
	_has_wander_target = false


## Current rendered body color, also used when keying the real 3D portrait
## for an unmerged Blorb.
func icon_color() -> Color:
	return _element_glow_color() if element_state != "" else body_color


func _element_glow_color() -> Color:
	match element_state:
		"water":
			return Color(0.3, 0.55, 0.95)
		"fire":
			return Color(1.0, 0.5, 0.15)
		"electric":
			return Color(0.95, 0.85, 0.2)
		"rock":
			return Color(0.7, 0.5, 0.3)
		"ground":
			return Color(0.55, 0.4, 0.15)
		"air":
			return Color(0.72, 0.9, 1.0)
		"plant":
			return Color(0.4, 0.85, 0.35)
		_:
			return Color(1.0, 0.88, 0.55)


func merge_element(element: String) -> void:
	if not can_merge(element):
		return
	element_state = element
	_apply_element_visuals()
	if is_starter_trio:
		_check_blorbus_awakening()


func _apply_element_visuals() -> void:
	var core_material: StandardMaterial3D = _core_mesh_instance.get_meta("material")
	match element_state:
		"water":
			# Medium-dark blue, deliberately between a pale sky blue and
			# a near-navy -- "dark viscous water," per direct
			# instruction, not bright/cartoonish.
			_body_material.albedo_color = Color(0.08, 0.28, 0.55, 0.9)
			_body_material.roughness = 0.05
			_body_material.metallic = 0.1
			core_material.albedo_color = Color(0.2, 0.45, 0.8)
			core_material.emission_enabled = true
			core_material.emission = Color(0.2, 0.45, 0.8)
			core_material.emission_energy_multiplier = 1.0
		"fire":
			_body_material.albedo_color = Color(0.85, 0.25, 0.05, 0.95)
			_body_material.roughness = 0.35
			_body_material.metallic = 0.0
			_body_material.emission_enabled = true
			_body_material.emission = Color(0.9, 0.35, 0.05)
			_body_material.emission_energy_multiplier = 1.4
			core_material.albedo_color = Color(1.0, 0.5, 0.1)
			core_material.emission_enabled = true
			core_material.emission = Color(1.0, 0.45, 0.05)
			core_material.emission_energy_multiplier = 1.6
			_add_core_light(Color(1.0, 0.45, 0.05))
		"electric":
			_body_material.albedo_color = Color(0.92, 0.82, 0.15, 0.9)
			_body_material.roughness = 0.1
			_body_material.metallic = 0.05
			_body_material.emission_enabled = true
			_body_material.emission = Color(0.95, 0.85, 0.2)
			_body_material.emission_energy_multiplier = 1.1
			core_material.albedo_color = Color(1.0, 0.92, 0.3)
			core_material.emission_enabled = true
			core_material.emission = Color(1.0, 0.9, 0.25)
			core_material.emission_energy_multiplier = 1.8
			_add_core_light(Color(1.0, 0.9, 0.25))
		"rock":
			# Warm banded-sandstone brown (matches the canyon biome's own
			# CANYON_BAND_COLORS palette, see nature_props.gd) rather than
			# flat grey stone -- this project's rock formations already
			# lean earthy/orange, not grey.
			_body_material.albedo_color = Color(0.5, 0.36, 0.22, 0.92)
			_body_material.roughness = 0.7
			_body_material.metallic = 0.0
			core_material.albedo_color = Color(0.65, 0.48, 0.28)
			core_material.emission_enabled = true
			core_material.emission = Color(0.55, 0.4, 0.2)
			core_material.emission_energy_multiplier = 0.7
		"ground":
			# Deliberately darker/richer than "rock" above -- loamy soil,
			# not sandstone -- so the two read as distinct elements despite
			# both being earth-toned. Per direct instruction, ground is its
			# own element, not just a synonym for rock.
			_body_material.albedo_color = Color(0.3, 0.2, 0.1, 0.93)
			_body_material.roughness = 0.55
			_body_material.metallic = 0.0
			core_material.albedo_color = Color(0.5, 0.38, 0.15)
			core_material.emission_enabled = true
			core_material.emission = Color(0.45, 0.35, 0.12)
			core_material.emission_energy_multiplier = 0.8
		"air":
			# Pale, luminous sky-blue: distinct from the darker water blorb.
			_body_material.albedo_color = Color(0.62, 0.84, 1.0, 0.72)
			_body_material.roughness = 0.02
			_body_material.metallic = 0.08
			_body_material.emission_enabled = true
			_body_material.emission = Color(0.4, 0.7, 1.0)
			_body_material.emission_energy_multiplier = 0.45
			core_material.albedo_color = Color(0.8, 0.95, 1.0)
			core_material.emission_enabled = true
			core_material.emission = Color(0.55, 0.82, 1.0)
			core_material.emission_energy_multiplier = 1.25
			# The free creature has its own small back wings as a readable
			# prototype before those same wings become suit attachments.
			if body.get_node_or_null("AirBlorbWings") == null:
				# The Blorb body mesh is offset down by EMBED_DEPTH. Put the wing
				# root directly on its back surface at mid-height, so the slabs'
				# inner corners visibly grow from the goo instead of floating behind.
				BlorbSuit.build_air_wings(
					body, 0.58, Vector3(0.0, BODY_HEIGHT * 0.52 - EMBED_DEPTH, -RADIUS)
				)
		"plant":
			# Leafy, saturated green -- distinct from ground/rock's earth
			# tones and matched to the jungle biome's own foliage palette.
			_body_material.albedo_color = Color(0.22, 0.6, 0.2, 0.9)
			_body_material.roughness = 0.3
			_body_material.metallic = 0.0
			core_material.albedo_color = Color(0.4, 0.85, 0.35)
			core_material.emission_enabled = true
			core_material.emission = Color(0.35, 0.8, 0.3)
			core_material.emission_energy_multiplier = 0.8


## Checked after every successful gem merge on a starter-trio member (see
## merge_element()) -- per direct instruction, once exactly one of the
## original trio (main.tscn's Blorb1-3, see is_starter_trio) is still
## ungemmed while the other two have taken a gem, that one becomes Blorbus.
## Scans the whole "blorbs" group rather than a dedicated trio list, since
## there isn't one -- is_starter_trio filters it down by hand instead.
func _check_blorbus_awakening() -> void:
	if portrait_mode:
		return
	var ungemmed: Array = []
	var gemmed_count := 0
	for other in get_tree().get_nodes_in_group("blorbs"):
		if not other.is_starter_trio:
			continue
		if other.element_state == "":
			ungemmed.append(other)
		else:
			gemmed_count += 1
	if gemmed_count == 2 and ungemmed.size() == 1:
		ungemmed[0].become_blorbus()


## The third starter blorb -- whichever of the trio is still ungemmed once
## you've thrown gems into the other two -- turns pink and wakes up
## talking. Per direct instruction: "the third regular blorb that you don't
## put a gem into" becomes Blorbus, the sentient companion docs/
## world_bible.md already names but never explains. Permanent and one-way:
## is_blorbus locks out can_merge() for good (see that function), so a
## later gem throw just bounces off with the ordinary "doesn't react"
## message (see thrown_item.gd's _resolve_hit()) rather than un-awakening
## it.
func become_blorbus() -> void:
	if is_blorbus:
		return
	is_blorbus = true
	blorb_name = "Blorbus"
	# A duller, greyish "brain pink" per direct instruction -- not a bright
	# bubblegum pink, closer to the muted pinkish-grey of an actual brain.
	body_color = BLORBUS_BODY_COLOR
	_body_material.albedo_color = body_color
	_body_material.roughness = 0.25
	_body_material.metallic = 0.0
	var core_material: StandardMaterial3D = _core_mesh_instance.get_meta("material")
	core_material.albedo_color = Color(0.88, 0.68, 0.7)
	core_material.emission_enabled = true
	core_material.emission = Color(0.85, 0.62, 0.65)
	core_material.emission_energy_multiplier = 0.7
	Hud.show_message("One of your blorbs turns pink... and starts talking?")
	Interactable.attach(self, "Talk", TALK_RADIUS, _on_talk)


const TALK_RADIUS := 2.5
## First-pass placeholder lines -- see become_blorbus()'s own doc comment;
## resolves docs/world_bible.md's long-open "Blorbus's backstory/role"
## thread just enough to give him a voice, not a full backstory yet.
const BLORBUS_LINES := [
	"Oh -- hello. I don't quite know why I can talk and the others can't. I didn't ask to be the strange one.",
	"I noticed I never went pink until you'd already gemmed the other two. Funny how that works.",
	"Don't bother trying to give me a gem. I tried holding one once. It just... rolled right off.",
	"I'm Blorbus, by the way. I don't remember deciding that. It just felt true the moment I said it.",
]


func _on_talk() -> void:
	var line: String = BLORBUS_LINES[_rng.randi_range(0, BLORBUS_LINES.size() - 1)]
	DialogUI.show_line("Blorbus", line)


## A real point light, not just an emissive core material -- per direct
## instruction that fire (and electric) blorbs should actually give off
## light. A permanent trait of the element itself, so it's never removed
## once added, party member or not. Parented to the core mesh (not body) so
## it moves with the body's hop/squash animation for free without getting
## stretched by it. Same shadow/range convention as town_props.gd's
## build_lantern().
func _add_core_light(color: Color) -> void:
	if _core_mesh_instance.has_node("Light"):
		return
	var light := OmniLight3D.new()
	light.name = "Light"
	light.light_color = color
	light.omni_range = 2.2
	light.shadow_enabled = false
	_core_mesh_instance.add_child(light)


## Called by player.gd (_bounce_off_blorb()) the instant a jump/fall lands
## on top of this blorb. Sets the squash directly rather than easing into
## it -- an impact should read as instant -- and leaves springing back out
## to _process()'s existing "else" branch below, which already lerps
## body.scale back to Vector3.ONE whenever a hop isn't in progress.
func trigger_bounce_squash() -> void:
	if not _hop_active:
		body.scale = Vector3(1.0 + BOUNCE_SQUASH_AMOUNT, 1.0 - BOUNCE_SQUASH_AMOUNT, 1.0 + BOUNCE_SQUASH_AMOUNT)


## Purely cosmetic uniform scale override for the blorb suit's own hop
## animation (see blorb_suit_controller.gd) -- shrinks the round body down
## to roughly match the mass of the body part it's about to become while
## flying onto the player, and grows it back while flying off, per direct
## instruction. Safe to drive directly like this only because _process's
## own hop-squash/settle handling is frozen the whole time (is_worn is
## already true for the entire flight -- see begin_worn()) rather than
## fighting it every frame.
func set_visual_scale(scale_factor: float) -> void:
	body.scale = Vector3.ONE * scale_factor


## Called by blorb_suit_controller.gd the instant a blorb starts hopping
## toward its slot on the player's body -- per direct instruction the suit
## is no longer instantaneous, so this only freezes the blorb's own
## independent glide/idle AI and collision (the controller is about to
## drive global_position through a hop arc by hand); the round body/eyes
## stay VISIBLE and keep animating (see blorb.gd's own _process guard
## below) all the way through the flight, only swapping for the flat suit
## piece once it actually lands -- see finish_worn().
func begin_worn() -> void:
	is_worn = true
	collision_layer = 0
	# A blorb hopping onto the suit mid-attack shouldn't keep visibly
	# streaming at whatever it was targeting -- it's about to become a
	# stationary suit piece, not an independent combatant any more. Per
	# direct report: this used to keep emitting on its own indefinitely,
	# since _process()'s own "if is_worn: return" guard right below skips
	# the ordinary combat-state code that would otherwise have stopped it,
	# and nothing else ever freed the particle node itself.
	if _stream_particles != null:
		_stream_particles.queue_free()
		_stream_particles = null


## Called once an equip hop's landing animation completes -- hides the
## round body (the suit piece geometry takes over from here) without
## touching is_worn/collision, which begin_worn() above already set for
## the whole flight.
func finish_worn() -> void:
	body.visible = false


## The reverse of finish_worn() -- called the instant an unequip hop
## STARTS, so the round body reappears and starts hopping away right as
## the flat suit piece disappears, rather than the two ever being visible
## at once. is_worn stays true (AI/collision stay frozen) until the hop
## actually lands -- see finish_unworn().
func begin_unworn() -> void:
	body.visible = true


## Returns the first solid world surface directly below a requested suit
## dismount point. This intentionally differs from _ground_height_at():
## that helper only considers terrain and explicitly climbable ramps, so
## ordinary raised platforms do not make wandering blorbs teleport upward.
## A blorb leaving the suit is already falling, though, so its landing must
## instead stop at the first surface in that fall path.
func resolve_dismount_landing_position(drop_position: Vector3) -> Vector3:
	var landing := drop_position
	var terrain_h: float = terrain.get_mesh_height(landing.x, landing.z)
	var space_state := get_world_3d().direct_space_state
	# The scatter point is at the player's feet. Start only just above it,
	# never at the higher head/torso slot that the blorb hops from: a player
	# standing below an overhead platform must not have their blorbs pulled
	# upward onto that platform.
	var from := Vector3(landing.x, landing.y + 0.1, landing.z)
	var to := Vector3(landing.x, terrain_h - 5.0, landing.z)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [get_rid()]
	var result := space_state.intersect_ray(query)
	landing.y = result.position.y if result else terrain_h
	return landing


## Called once an unequip hop's landing animation completes. Lands at
## drop_position (picked by the controller to scatter around the player,
## per direct instruction blorbs should "land around you" rather than all
## on the same spot) rather than wherever it happened to be standing
## before it was worn.
func finish_unworn(drop_position: Vector3) -> void:
	is_worn = false
	collision_layer = 1
	global_position = drop_position
	_dismount_support_active = false
	_fall_velocity = minf((_player as Player).velocity.y if _player is Player else 0.0, 0.0)
	_falling_after_dismount = true
	_home = Vector2(global_position.x, global_position.z)
	_state = State.IDLE
	_has_wander_target = false


## Read-only snapshot of this blorb's own already-computed body/core
## material look (color, gloss, emission, whether its element gives off
## real light) -- lets blorb_suit.gd's jelly-covering pieces match this
## blorb's exact current appearance per element without re-deriving the
## same per-element match statement a second time in a different file (see
## _apply_element_visuals above, the actual source of truth this just reads
## back from).
func body_visual_snapshot() -> Dictionary:
	var core_material: StandardMaterial3D = _core_mesh_instance.get_meta("material")
	var has_light := _core_mesh_instance.has_node("Light")
	var light_color := Color.WHITE
	if has_light:
		light_color = (_core_mesh_instance.get_node("Light") as OmniLight3D).light_color
	return {
		"albedo": _body_material.albedo_color,
		"roughness": _body_material.roughness,
		"metallic": _body_material.metallic,
		"emission_enabled": _body_material.emission_enabled,
		"emission": _body_material.emission,
		"emission_energy": _body_material.emission_energy_multiplier,
		"core_color": core_material.albedo_color,
		"core_emissive": core_material.emission_enabled,
		"core_emission": core_material.emission,
		"core_emission_energy": core_material.emission_energy_multiplier,
		"has_light": has_light,
		"light_color": light_color,
	}


func _process(delta: float) -> void:
	# A portrait_mode instance (see blorb_portrait.gd) has no Player sibling
	# to reference -- _player is left null since _ready() returns before
	# assigning it -- and needs no gameplay simulation at all besides
	# holding still and looking correct for its own photoshoot.
	if portrait_mode:
		return
	_update_resources(delta)
	if is_worn:
		return
	if is_melted:
		return
	EyeBlink.apply(_eye_blink, delta, _eyes)
	_update_air_wing_flap(delta)
	if is_player_controlled:
		return
	var here := Vector2(global_position.x, global_position.z)

	# Free-roaming party blorbs (not the giant, and not suit-worn/melted --
	# already excluded above) break off to engage the nearest skeleton NME
	# within range instead of their usual follow/wander behavior. See
	# skeleton_nme.gd's "skeletons" group.
	if in_party and blorb_type != "size":
		var nearest_skeleton := _find_nearest_skeleton(here)
		if nearest_skeleton != null:
			_combat_target = nearest_skeleton
			_state = State.COMBAT
		elif _state == State.COMBAT:
			_exit_combat(here)
	elif _state == State.COMBAT:
		_exit_combat(here)
	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	if _join_decline_cooldown > 0.0:
		_join_decline_cooldown = maxf(_join_decline_cooldown - delta, 0.0)

	if can_join_party and not in_party and not _discovered and _join_decline_cooldown <= 0.0:
		var dist_to_player := here.distance_to(Vector2(_player.global_position.x, _player.global_position.z))
		if dist_to_player < DISCOVERY_RADIUS:
			_discovered = true

	var follow_pt := _follow_target()
	var dist_follow := here.distance_to(follow_pt)

	# A not-yet-joined wild blorb gives up tagging along entirely once it's
	# fallen this far behind -- whether it was actively FOLLOWING, had just
	# been _discovered, or (per direct instruction) had just declined the
	# join prompt moments ago, none of those should chase indefinitely if
	# the party keeps moving away or it gets stuck behind terrain. Checked
	# before the FOLLOWING transition right below so a drop-off this frame
	# can't immediately re-enter it in the same tick. A joined party member
	# (in_party) has no such ceiling -- this only bounds the pre-join
	# tag-along.
	if not in_party and _discovered and dist_follow > DROP_OFF_DISTANCE:
		_discovered = false
		_state = State.IDLE
		_home = here
		_has_wander_target = false
		_bond_time = 0.0

	if _state != State.COMBAT:
		if (in_party or _discovered) and dist_follow > FOLLOW_DISTANCE:
			_state = State.FOLLOWING
		elif _state == State.FOLLOWING and dist_follow < ARRIVE_DISTANCE:
			_state = State.IDLE
			_home = here
			_has_wander_target = false
			_idle_pause_timer = _rng.randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)

	# A discovered wild blorb accrues toward joining the party for real
	# whenever it's actually close to the party (not just "has noticed
	# them and is en route") -- see JOIN_BOND_DURATION's own doc comment
	# for why this pauses rather than resets while it's lagging behind.
	# Reaching the threshold surfaces the join prompt (_prompt_join_request())
	# rather than joining outright -- guarded by _join_prompt_open so the
	# still-true bond_time >= JOIN_BOND_DURATION condition doesn't re-open it
	# every subsequent frame while the player is deciding.
	if can_join_party and _discovered and not in_party and not _join_prompt_open:
		if dist_follow < FOLLOW_DISTANCE:
			_bond_time += delta
			if _bond_time >= JOIN_BOND_DURATION:
				_prompt_join_request()

	var moving := false
	var target := here
	var glide_speed := IDLE_GLIDE_SPEED * movement_speed_multiplier

	if _state == State.COMBAT and _combat_target != null and is_instance_valid(_combat_target):
		var skeleton_here := Vector2(_combat_target.global_position.x, _combat_target.global_position.z)
		var to_skeleton := skeleton_here - here
		var is_elemental := element_state == "water" or element_state == "fire"
		var engage_range := STREAM_RANGE if is_elemental else MELEE_RANGE
		# True 3D distance decides whether an attack can actually land -- a
		# blorb standing at the base of a cliff/tower shouldn't be able to
		# hit a skeleton floating far above or below it just because their
		# ground (XZ) positions happen to line up. Per direct correction.
		# The approach-target math right below still uses the horizontal-
		# only `to_skeleton` -- this blorb steers across the ground plane
		# regardless, only the attack gate needs the real 3D check.
		if global_position.distance_to(_combat_target.global_position) > engage_range:
			target = skeleton_here - to_skeleton.normalized() * engage_range
			glide_speed = _follow_glide_speed
			moving = true
			_set_combat_stream_active(false)
		else:
			# Already in range -- hold position and attack instead of
			# continuing to close the last bit of distance, which would
			# otherwise walk a jump-attacker straight into the skeleton.
			if to_skeleton.length() > 0.01:
				var face_angle := atan2(to_skeleton.x, to_skeleton.y) + PI
				rotation.y = lerp_angle(rotation.y, face_angle, ROTATION_SPEED * movement_speed_multiplier * delta)
			if is_elemental:
				_update_elemental_stream(delta)
			else:
				_try_jump_attack()
	elif _state == State.FOLLOWING:
		target = follow_pt
		glide_speed = _follow_glide_speed
		moving = true
	elif _has_wander_target and here.distance_to(_wander_target) > ARRIVE_EPS:
		target = _wander_target
		moving = true
	elif _has_wander_target:
		_has_wander_target = false
		_idle_pause_timer = _rng.randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)
	else:
		_idle_pause_timer -= delta * movement_speed_multiplier
		if _idle_pause_timer <= 0.0:
			var angle := _rng.randf_range(0.0, TAU)
			var r := _rng.randf_range(0.3, IDLE_WANDER_RADIUS)
			_wander_target = _home + Vector2(cos(angle), sin(angle)) * r
			_has_wander_target = true

	var new_pos := here
	if moving:
		var to_target := target - here
		var step := to_target.limit_length(glide_speed * delta)
		new_pos = here + step

		if to_target.length() > 0.01:
			# Blorb faces are authored toward local -Z, so add the same half-turn
			# used by direct Blorbus control. Without it, ordinary followers and
			# wanderers visually glide backward toward their targets.
			var target_angle := atan2(to_target.x, to_target.y) + PI
			rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * movement_speed_multiplier * delta)

		if allow_movement_hops and not _hop_active and _rng.randf() < HOP_CHANCE_PER_SEC * delta:
			_hop_active = true
			_hop_elapsed = 0.0

	# StaticBody3D collision is only ever checked against by something else
	# doing collision-aware movement (like the player's move_and_slide) --
	# it never resolves on its own, and two StaticBody3Ds never push each
	# other regardless of layers/masks. Since blorbs just set their own
	# position directly rather than moving through the physics engine,
	# mutual separation (and getting shoved by the player) both have to be
	# done by hand here.
	new_pos = _apply_separation(new_pos)
	new_pos = _apply_player_push(new_pos, delta)
	global_position.x = new_pos.x
	global_position.z = new_pos.y

	# Checked before this frame's own hop/settle handling below, since
	# starting a climb needs to happen in the same frame a big enough rise
	# is first seen -- ground_h itself gets used again at the very bottom
	# regardless of whether a climb started here.
	var ground_h := _ground_height_at(global_position.x, global_position.z)
	if _falling_after_dismount:
		# A released blorb lands on the first real surface below it, including
		# raised props/platforms that ordinary terrain-following ignores.
		ground_h = resolve_dismount_landing_position(global_position).y
	# Air blorbs never settle to a ground/cloud surface. They retain a soft
	# hover even while idle, and a party member lifts toward its airborne
	# player so it remains an actual aerial companion rather than trailing
	# far below during flight.
	if element_state == "air" and not _falling_after_dismount:
		_hop_active = false
		_climbing = false
		body.scale = body.scale.lerp(Vector3.ONE, SETTLE_SPEED * movement_speed_multiplier * delta)
		var hover_y := ground_h + _ground_embed_offset() + AIR_HOVER_HEIGHT
		if in_party or _discovered:
			# Chase until the visible crown reaches the player's feet, never by
			# driving the collider deep through them. Player then owns the bounce.
			hover_y = maxf(hover_y, _player.global_position.y - BOUNCE_CROWN_HEIGHT)
		global_position.y = move_toward(global_position.y, hover_y, AIR_HOVER_SETTLE_SPEED * delta)
		_update_surface_tilt(delta, Vector3.UP)
		return
	# A normal free blorb is buoyant: once the basin is genuinely deep it
	# follows the lake surface, remaining partially immersed, rather than
	# snapping all the way down to terrain thousands of centimetres below.
	# Its ordinary XZ following/wandering above remains unchanged, so party
	# members naturally gather and drift around a swimming player.
	var lake_float := false
	if blorb_type != "size" and terrain.is_lake_area(Vector2(global_position.x, global_position.z)):
		var water_level: float = terrain.get_lake_water_level()
		lake_float = water_level - ground_h >= LAKE_FLOAT_MIN_DEPTH
		if lake_float:
			_hop_active = false
			_climbing = false
			body.scale = body.scale.lerp(Vector3.ONE, SETTLE_SPEED * movement_speed_multiplier * delta)
			var visible_height := BODY_HEIGHT * size_multiplier * vertical_scale
			var float_y := water_level - visible_height * LAKE_FLOAT_SUBMERGENCE_FRACTION
			global_position.y = move_toward(global_position.y, float_y, LAKE_FLOAT_SETTLE_SPEED * delta)
			_falling_after_dismount = false
			_fall_velocity = 0.0
			_update_surface_tilt(delta, Vector3.UP)
			return
	var rise := ground_h - global_position.y
	# Big enough that snapping straight to it would read as clipping/
	# teleporting (a slab's edge, a ramp's own base) triggers a hop up onto
	# it instead of an instant snap -- ordinary ground-height change
	# (walking down a gentle slope, the smooth rise partway up a ramp) stays
	# well under this and is still applied instantly, same as before.
	# Per direct instruction: blorbs were clipping up through the canyon
	# biome's slab floor and correcting with a jarring pop instead of
	# visibly climbing onto it.
	const CLIMB_HOP_THRESHOLD := 0.15
	if allow_movement_hops and rise > CLIMB_HOP_THRESHOLD and not _climbing:
		_climbing = true
		_climb_start_y = global_position.y
		if not _hop_active:
			_hop_active = true
			_hop_elapsed = 0.0

	var hop_offset := 0.0
	if _hop_active:
		_hop_elapsed += delta
		var t: float = clampf(_hop_elapsed / HOP_DURATION, 0.0, 1.0)
		hop_offset = sin(t * PI) * HOP_HEIGHT
		var stretch := sin(t * PI) * WOBBLE_AMOUNT
		body.scale = Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
		if t >= 1.0:
			_hop_active = false
			_climbing = false
	else:
		body.scale = body.scale.lerp(Vector3.ONE, SETTLE_SPEED * movement_speed_multiplier * delta)

	if _climbing:
		# Re-reads ground_h (queried fresh at the top of this frame) as the
		# lerp's own target every frame rather than freezing it at the
		# climb's start -- the blorb is still moving in XZ across the hop's
		# short duration, so the true target height can drift slightly as
		# it goes; this keeps chasing wherever it actually ends up instead
		# of a target frozen the instant the climb began.
		var climb_t: float = clampf(_hop_elapsed / HOP_DURATION, 0.0, 1.0)
		global_position.y = lerp(_climb_start_y, ground_h + _ground_embed_offset(), climb_t) + hop_offset
	else:
		var rest_y := ground_h + _ground_embed_offset()
		if _hop_active:
			global_position.y = rest_y + hop_offset
			_fall_velocity = 0.0
		elif global_position.y > rest_y + 0.01:
			_fall_velocity = maxf(_fall_velocity - FALL_GRAVITY * delta, -TERMINAL_FALL_SPEED)
			global_position.y = maxf(rest_y, global_position.y + _fall_velocity * delta)
			if global_position.y <= rest_y + 0.001:
				_fall_velocity = 0.0
				_falling_after_dismount = false
		else:
			global_position.y = rest_y + hop_offset
			_fall_velocity = 0.0
			_falling_after_dismount = false
	_update_surface_tilt(delta, _surface_normal_at(global_position.x, global_position.z, ground_h))


## Keeps local +Z pointed as close as possible to the blorb's existing
## travel-facing direction while local +Y follows the support normal. Work
## in the yawed root's local frame so slope tilt never steals heading.
func _update_surface_tilt(delta: float, world_normal: Vector3) -> void:
	# Giant traversal samples an untilted analytic mesh profile, so keep that
	# landmark upright to preserve exact visible/gameplay surface agreement.
	if blorb_type == "size":
		world_normal = Vector3.UP
	var root_rotation := global_transform.basis.orthonormalized()
	var local_up := (root_rotation.inverse() * world_normal).normalized()
	var local_forward := Vector3.FORWARD - local_up * Vector3.FORWARD.dot(local_up)
	if local_forward.length_squared() < 0.0001:
		local_forward = Vector3.RIGHT - local_up * Vector3.RIGHT.dot(local_up)
	local_forward = local_forward.normalized()
	var local_right := local_up.cross(local_forward).normalized()
	var target := Basis(local_right, local_up, local_forward).orthonormalized().get_rotation_quaternion()
	var weight := 1.0 - exp(-SURFACE_TILT_SPEED * maxf(movement_speed_multiplier, 0.25) * delta)
	body.quaternion = body.quaternion.slerp(target, weight)


## Prefer the real collision normal of whatever solid surface supports the
## blorb; otherwise use the exact terrain triangle normal matching ground_h.
func _surface_normal_at(x: float, z: float, ground_h: float) -> Vector3:
	var from := Vector3(x, ground_h + 1.0, z)
	var to := Vector3(x, ground_h - 0.5, z)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | TownProps.BLORB_CLIMBABLE_LAYER)
	query.exclude = _blorb_support_exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var normal := hit.normal as Vector3
		return normal if normal.y >= 0.0 else -normal
	return terrain.get_mesh_normal(x, z)

## Free air blorbs flap gently at rest. This timer deliberately has no
## relationship to EyeBlink's randomized timing, so a wingbeat never reads
## as a visual tick synchronized with the face.
func _update_air_wing_flap(delta: float) -> void:
	if element_state != "air":
		return
	var wings := body.get_node_or_null("AirBlorbWings") as Node3D
	if wings == null:
		return
	_air_wing_flap_phase += delta * _air_wing_flap_speed
	BlorbSuit.animate_air_wings(wings, sin(_air_wing_flap_phase) * deg_to_rad(5.0))


## get_mesh_height(), not get_height() -- matches the exact rendered/
## collision surface (see terrain_generator.gd's get_mesh_height() doc
## comment). The two can visibly disagree between grid vertices;
## EMBED_DEPTH happened to mask that gap for blorbs specifically, but the
## underlying mismatch was real and was worth fixing at the source rather
## than relying on the embed to keep covering for it.
##
## A local downward probe includes world layer 1, the same solid geometry
## the Player's CharacterBody can stand on, plus the dedicated ramp layer.
## Its origin is only SUPPORT_ACQUIRE_HEIGHT above the blorb's current feet:
## this admits reachable ledges without reviving the old world-spanning-ray
## bug that teleported blorbs from beneath buildings onto their roofs.
func _ground_height_at(x: float, z: float) -> float:
	# Explicit : float, not := -- terrain is typed as plain Node (see this
	# file's @onready var), so GDScript can't infer get_mesh_height()'s
	# return type through type inference alone.
	var terrain_h: float = terrain.get_mesh_height(x, z)
	# Free blorbs use the same one-way cloud tops as Player. Their ordinary
	# direct Y-following means they can only acquire a cloud when already at
	# or above it (for example after being released in the air), never snap
	# upward from the ground through a cloud's underside.
	var clouds := get_node_or_null("../Clouds") as CloudScatter
	if clouds != null:
		var cloud_top: Variant = clouds.get_support_height_at(x, z, global_position.y + 0.2)
		if cloud_top != null:
			return maxf(terrain_h, (cloud_top as float) - 0.10)
	# Tree canopies are the same kind of one-way support as clouds above --
	# see NatureProps._add_canopy_blob() and
	# WildernessScatter.get_support_height_at(). Shallower sink than the
	# cloud's own 0.10 (see player.gd's TREE_CANOPY_SINK_DEPTH for why).
	# Duck-typed rather than `as WildernessScatter` -- see player.gd's
	# identical _tree_canopy_stand_height_at() comment for why.
	var scatter := get_node_or_null("../Scatter")
	if scatter != null and scatter.has_method("get_support_height_at"):
		var canopy_top: Variant = scatter.get_support_height_at(x, z, global_position.y + 0.2)
		if canopy_top != null:
			return maxf(terrain_h, (canopy_top as float) - 0.04)
	var space_state := get_world_3d().direct_space_state
	if _dismount_support_active:
		# Once released onto a platform, only test from just above the
		# blorb's current feet downward. That keeps the platform as support
		# while it walks on it, but cannot pull a blorb up to an overhead
		# roof/platform the way a tall world-spanning ray would.
		var support_from := Vector3(x, global_position.y + 0.1, z)
		var support_to := Vector3(x, terrain_h - 5.0, z)
		var support_query := PhysicsRayQueryParameters3D.create(support_from, support_to, 1)
		support_query.exclude = [get_rid()]
		var support := space_state.intersect_ray(support_query)
		if support and support.position.y > terrain_h + 0.01:
			return support.position.y
		# The blorb has stepped off its raised landing surface (or landed on
		# terrain), so restore its ordinary terrain/ramp-following behavior.
		_dismount_support_active = false
	# The giant is intentionally outside the player's ordinary collision
	# mask, but its analytic goo surface is standable too. Treat entering its
	# footprint like the player's viscous lift onto that surface.
	if blorb_type != "size":
		for candidate in get_tree().get_nodes_in_group("blorbs"):
			if not candidate is Blorb or candidate == self:
				continue
			var giant := candidate as Blorb
			if giant.blorb_type != "size":
				continue
			var giant_top: Variant = giant.giant_surface_height_at(x, z)
			if giant_top != null:
				return maxf(terrain_h, giant_top as float)
	var from := Vector3(x, global_position.y + SUPPORT_ACQUIRE_HEIGHT, z)
	var to := Vector3(x, terrain_h - 5.0, z)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | TownProps.BLORB_CLIMBABLE_LAYER)
	query.exclude = _blorb_support_exclusions()
	var result := space_state.intersect_ray(query)
	if result:
		return maxf(terrain_h, result.position.y)
	return terrain_h


## Blorbs are trampoline creatures, not stackable terrain. Excluding every
## blorb RID keeps the generalized world-solid probe from treating another
## companion's collision sphere as a platform.
func _blorb_support_exclusions() -> Array[RID]:
	var exclusions: Array[RID] = []
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if candidate is CollisionObject3D:
			exclusions.append((candidate as CollisionObject3D).get_rid())
	# NPC heads are trampoline contacts too, never passive platforms.
	for candidate in get_tree().get_nodes_in_group("npcs"):
		if candidate is CollisionObject3D:
			exclusions.append((candidate as CollisionObject3D).get_rid())
	return exclusions


## BODY's mesh is embedded slightly into the ground at ordinary scale. When
## the entire blorb is enlarged, lift its root by the extra scaled embed
## depth so its huge lower curve still meets the ground rather than sinking
## tens of metres into it.
func _ground_embed_offset() -> float:
	if blorb_type == "size":
		# The giant's newer, flatter underside needs only a shallow 10% sink;
		# the previous 18% buried too much of its visible mass underground.
		return EMBED_DEPTH * size_multiplier * vertical_scale - BODY_HEIGHT * size_multiplier * vertical_scale * 0.10
	# Lift an ordinary blorb by half its authored embed depth. It still meets
	# the grass softly, but no longer loses so much of its lower silhouette.
	return EMBED_DEPTH * (size_multiplier - 0.5)


## Height of this Size blorb's upper visible body mesh at an XZ world point.
## This uses the exact shared profile that generated the mesh (not the old
## sphere collider), so the player can stand on the goo's real silhouette.
func giant_surface_height_at(world_x: float, world_z: float) -> Variant:
	if blorb_type != "size":
		return null
	var radial_distance := Vector2(world_x - global_position.x, world_z - global_position.z).length()
	var normalized_radius := radial_distance / (RADIUS * size_multiplier)
	if normalized_radius > 1.0:
		return null
	var angle := PI - asin(clampf(normalized_radius, 0.0, 1.0))
	var t := BULGE_T + ((angle / PI) - 0.5) * 2.0 * (1.0 - BULGE_T)
	return global_position.y + (t * BODY_HEIGHT - EMBED_DEPTH) * size_multiplier * vertical_scale


## Upper collision-sphere surface at an XZ point, used when a moving air
## blorb rises into a player. Static-body overlap recovery does not always
## appear in CharacterBody3D's slide-collision list, so the player needs the
## same geometric surface to turn that contact into a proper bounce.
func bounce_surface_height_at(world_x: float, world_z: float) -> Variant:
	if blorb_type == "size" or is_worn or is_melted:
		return null
	# Use the rendered lathe profile, not the broad spherical collider. The
	# latter sits substantially above the goo away from its crown and was the
	# reason air-blorb bounces visibly launched from empty space.
	var scaled_radius := RADIUS * size_multiplier
	var radial_distance := Vector2(world_x - global_position.x, world_z - global_position.z).length()
	if radial_distance > scaled_radius:
		return null
	var normalized_radius := radial_distance / scaled_radius
	var angle := PI - asin(clampf(normalized_radius, 0.0, 1.0))
	var t := BULGE_T + ((angle / PI) - 0.5) * 2.0 * (1.0 - BULGE_T)
	return global_position.y + (t * BODY_HEIGHT - EMBED_DEPTH) * size_multiplier * vertical_scale


## True once the midpoint of the player's capsule has crossed the actual
## goo volume. The player then rises slowly through the viscous body rather
## than colliding with an approximate sphere at its outside edge.
func contains_player_majority(feet_position: Vector3, player_height: float) -> bool:
	if blorb_type != "size":
		return false
	var radial_distance := Vector2(feet_position.x - global_position.x, feet_position.z - global_position.z).length()
	var normalized_radius := radial_distance / (RADIUS * size_multiplier)
	if normalized_radius > 1.0:
		return false
	var upper := giant_surface_height_at(feet_position.x, feet_position.z) as float
	var lower_angle := asin(clampf(normalized_radius, 0.0, 1.0))
	var lower_t := (lower_angle / PI) * 2.0 * BULGE_T
	var lower := global_position.y + (lower_t * BODY_HEIGHT - EMBED_DEPTH) * size_multiplier * vertical_scale
	# True majority-volume check: at least half of the player's collision
	# capsule height must overlap the goo between its lower and upper mesh
	# surfaces. A midpoint-only test missed this at the giant's low edge.
	var player_top := feet_position.y + player_height
	var overlap := maxf(0.0, minf(player_top, upper) - maxf(feet_position.y, lower))
	return overlap >= player_height * 0.5


## Direct psychic movement used for Blorbus and, after merging, the Size
## blorb. It deliberately retains each body's normal movement multiplier.
func drive_from_player(direction: Vector3, delta: float, sprinting: bool, jump_pressed: bool) -> void:
	var planar := Vector2(direction.x, direction.z)
	if planar.length() > 1.0:
		planar = planar.normalized()
	var speed := _follow_glide_speed
	if sprinting:
		speed *= (_player as Player).sprint_multiplier
	if blorb_type == "size":
		# World-space speed must grow with the body. Applying only the giant's
		# 0.1 movement multiplier made a fifty-times-wider creature advance in
		# tiny ordinary-blorb increments, which read as barely moving at all.
		# It remains slow in body-lengths per second, but now crosses enough
		# ground for direct control to feel responsive at its actual scale.
		speed = (_player as Player).move_speed * movement_speed_multiplier * size_multiplier
		if sprinting:
			speed *= (_player as Player).sprint_multiplier
	var next := Vector2(global_position.x, global_position.z) + planar * speed * delta
	global_position.x = next.x
	global_position.z = next.y
	var ground_h := _ground_height_at(next.x, next.y)
	var rest_y := ground_h + _ground_embed_offset()
	# Directly-controlled Blorbus is still just a blorb body in the water --
	# per direct correction, he should float/swim across deep lake water
	# instead of snapping down to the real lake floor the way ordinary ground
	# height would otherwise place him. Mirrors the free-roaming follower's
	# own lake_float check above, just evaluated here instead since a
	# player-controlled body skips the rest of _process() entirely.
	if blorb_type != "size" and terrain.is_lake_area(next):
		var water_level: float = terrain.get_lake_water_level()
		if water_level - ground_h >= LAKE_FLOAT_MIN_DEPTH:
			var visible_height := BODY_HEIGHT * size_multiplier * vertical_scale
			rest_y = water_level - visible_height * LAKE_FLOAT_SUBMERGENCE_FRACTION
	# Psychic control grants the same deliberate high jump to Blorbus's own
	# body and to the giant body he has merged into. The giant still never
	# performs its ordinary AI's random ambient hops.
	if jump_pressed and not _control_jump_active:
		_control_jump_active = true
		_control_jump_elapsed = 0.0
		_control_jump_base_offset = 0.0
	if _control_jump_active:
		var previous_y := global_position.y
		# Advancing scaled time instead of scaling only velocity ensures every
		# part of a giant jump—takeoff, apex, and landing—is slowed uniformly.
		_control_jump_elapsed += delta * movement_speed_multiplier
		var jump_t := clampf(_control_jump_elapsed / CONTROL_JUMP_DURATION, 0.0, 1.0)
		# The giant is intentionally vertically flattened. Include that scale
		# so its jump remains the same number of body-heights as Blorbus's,
		# rather than using its much wider horizontal diameter as the yardstick.
		var jump_height := CONTROL_JUMP_HEIGHT * size_multiplier * vertical_scale
		var height_fraction: float
		if jump_t < CONTROL_JUMP_APEX_FRACTION:
			var ascent_t := jump_t / CONTROL_JUMP_APEX_FRACTION
			height_fraction = 1.0 - pow(1.0 - ascent_t, 3.0)
		else:
			var fall_t := (jump_t - CONTROL_JUMP_APEX_FRACTION) / (1.0 - CONTROL_JUMP_APEX_FRACTION)
			height_fraction = 1.0 - fall_t * fall_t
		global_position.y = rest_y + _control_jump_base_offset + height_fraction * jump_height
		var stretch := height_fraction * WOBBLE_AMOUNT
		body.scale = Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
		if jump_t > CONTROL_JUMP_APEX_FRACTION and _try_controlled_creature_bounce(previous_y):
			return
		if jump_t >= 1.0:
			global_position.y = rest_y
			_control_jump_active = false
			_control_jump_base_offset = 0.0
			trigger_bounce_squash()
	else:
		global_position.y = rest_y
		body.scale = body.scale.lerp(Vector3.ONE, SETTLE_SPEED * delta)
	if planar.length() > 0.01:
		rotation.y = lerp_angle(rotation.y, atan2(planar.x, planar.y) + PI, ROTATION_SPEED * movement_speed_multiplier * delta)


## Detects a descending direct-control body crossing a blorb surface or an
## NPC's head. Restarting the same high jump gives it the player's familiar
## trampoline response; the impacted blorb receives the same squash cue.
func _try_controlled_creature_bounce(previous_y: float) -> bool:
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not candidate is Blorb or candidate == self:
			continue
		var other := candidate as Blorb
		var blorb_surface: Variant = other.bounce_surface_height_at(global_position.x, global_position.z)
		if blorb_surface != null and previous_y >= (blorb_surface as float) and global_position.y <= (blorb_surface as float):
			global_position.y = blorb_surface as float
			_control_jump_elapsed = 0.0
			_control_jump_active = true
			_control_jump_base_offset = (blorb_surface as float) - _ground_height_at(global_position.x, global_position.z) - _ground_embed_offset()
			other.trigger_bounce_squash()
			return true
	for npc_candidate in get_tree().get_nodes_in_group("npcs"):
		if not npc_candidate.has_method("head_bounce_surface_height_at"):
			continue
		var npc_surface: Variant = npc_candidate.head_bounce_surface_height_at(global_position.x, global_position.z)
		if npc_surface != null and previous_y >= (npc_surface as float) and global_position.y <= (npc_surface as float):
			global_position.y = npc_surface as float
			_control_jump_elapsed = 0.0
			_control_jump_active = true
			_control_jump_base_offset = (npc_surface as float) - _ground_height_at(global_position.x, global_position.z) - _ground_embed_offset()
			return true
	return false


## Nearest live skeleton within AGGRO_RADIUS, or null if none are close
## enough. Re-scanned every frame from _process() rather than cached --
## matches this file's existing convention of proximity checks over event
## callbacks (see e.g. _nearest_party_blorb_position() below).
func _find_nearest_skeleton(here: Vector2) -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := AGGRO_RADIUS
	for node in get_tree().get_nodes_in_group("skeletons"):
		var skeleton := node as Node3D
		if skeleton == null:
			continue
		var dist := here.distance_to(Vector2(skeleton.global_position.x, skeleton.global_position.z))
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = skeleton
	return nearest


func _exit_combat(here: Vector2) -> void:
	_combat_target = null
	_set_combat_stream_active(false)
	_state = State.IDLE
	_home = here
	_has_wander_target = false
	_idle_pause_timer = _rng.randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)


## Non-elemental blorbs' combat response: a melee bounce dealing
## JUMP_ATTACK_BASE_DAMAGE (boosted by this blorb's own Strength, then
## randomized and occasionally critical -- see combat_math.gd), on a
## per-target cooldown so a single approach can't multi-hit. Reuses the same
## ambient hop animation (_hop_active/_hop_elapsed, see _process's hop-offset/
## squash handling below) rather than a separate attack animation.
func _try_jump_attack() -> void:
	if _attack_cooldown > 0.0 or _combat_target == null or not is_instance_valid(_combat_target):
		return
	if not _hop_active:
		_hop_active = true
		_hop_elapsed = 0.0
	if _combat_target.has_method("take_damage"):
		var roll := CombatMath.rolled_attack(JUMP_ATTACK_BASE_DAMAGE, strength, _rng)
		_combat_target.take_damage(roll["amount"], self)
	_attack_cooldown = JUMP_ATTACK_COOLDOWN


## Water/fire blorbs' combat response: streams their element from the core
## at the skeleton, draining MP at the same per-second rate player.gd uses
## for the equivalent arm power, and dealing damage (at a rate boosted by
## this blorb's own Strength -- see combat_math.gd's rolled_stream_rate())
## while actively streaming.
func _update_elemental_stream(delta: float) -> void:
	var rate := WATER_STREAM_MP_PER_SECOND if element_state == "water" else FIRE_STREAM_MP_PER_SECOND
	var draining := consume_mp(rate * delta)
	_set_combat_stream_active(draining)
	if draining and _combat_target != null and is_instance_valid(_combat_target) and _combat_target.has_method("take_damage"):
		var damage_rate := CombatMath.rolled_stream_rate(STREAM_BASE_DAMAGE_PER_SECOND, strength)
		_combat_target.take_damage(damage_rate * delta, self)


func _set_combat_stream_active(active: bool) -> void:
	if not active:
		if _stream_particles != null:
			_stream_particles.emitting = false
		return
	if _stream_particles == null:
		_stream_particles = _make_combat_stream()
	_stream_particles.emitting = true
	if _combat_target != null and is_instance_valid(_combat_target):
		var origin: Vector3 = _core_mesh_instance.global_position
		_stream_particles.global_position = origin
		var aim := _combat_target.global_position - origin
		if aim.length() > 0.01:
			# A small organic waver in the aim itself, matching player.gd's
			# own _update_water_stream()'s identical technique/comment --
			# a real stream of fire/water never points perfectly still.
			var phase := float(get_instance_id() % 1000) * 0.01
			var t := Time.get_ticks_msec() * 0.001 * 3.2 + phase
			var wobble := Basis(Vector3.UP, sin(t) * deg_to_rad(2.5)) * Basis(Vector3.RIGHT, cos(t * 1.3) * deg_to_rad(2.5))
			_stream_particles.look_at(origin + wobble * aim, Vector3.UP)


## Visually matches player.gd's own _make_water_stream()/_make_fire_stream()
## (same soft-billboard/color-ramp technique -- see particle_fx.gd's own
## class doc comment) but isn't shared code with that file -- the aiming
## here comes from the core's world position toward a live combat target
## rather than a hand's position along the character's facing, different
## enough that extracting a shared abstraction isn't worth touching that
## large, heavily-annotated file for.
func _make_combat_stream() -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = "CombatStream"
	var is_water := element_state == "water"
	stream.amount = 140 if is_water else 200
	stream.lifetime = 0.5 if is_water else 0.34
	stream.randomness = 0.12 if is_water else 0.35
	stream.visibility_aabb = AABB(Vector3(-1.5, -1.5, -6.0), Vector3(3.0, 3.0, 6.4))
	# fire's wobble is lower (0.2, not player.gd's own original 0.35) and
	# its quad is elongated, not square -- see _make_fire_stream()'s own
	# comment on particle_flag_align_y for why (a narrow angle_min/max
	# range replacing a full 0-360 spin, to keep each streak aligned with
	# its own velocity instead of pointing every which way).
	var texture := ParticleFX.build_soft_gradient_texture(24, 2.2 if is_water else 1.7, 0.0 if is_water else 0.2)
	var material := ParticleFX.build_billboard_material(texture, Color.WHITE, not is_water, 0.35 if is_water else 0.0)
	material.vertex_color_use_as_albedo = true
	var droplet := QuadMesh.new()
	droplet.size = Vector2(0.16, 0.16) if is_water else Vector2(0.22, 0.5)
	droplet.material = material
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 1.0 if is_water else 6.0
	process.gravity = Vector3(0.0, -1.2 if is_water else -1.4, 0.0)
	var speed := 8.0 if is_water else 11.0
	process.initial_velocity_min = speed * 0.9
	process.initial_velocity_max = speed * 1.15
	process.scale_min = 0.85 if is_water else 0.5
	process.scale_max = 1.3 if is_water else 1.05
	if is_water:
		process.color_ramp = ParticleFX.build_color_ramp([
			{"offset": 0.0, "color": Color(0.85, 0.95, 1.0, 0.95)},
			{"offset": 0.35, "color": TownProps.WATER_COLOR},
			{"offset": 1.0, "color": Color(TownProps.WATER_COLOR.r, TownProps.WATER_COLOR.g, TownProps.WATER_COLOR.b, 0.0)},
		])
	else:
		# See player.gd's own _make_fire_stream() for the full reasoning --
		# aligns each streak to its own velocity (paired with the elongated
		# quad above) so the stream reads as a directional jet rather than
		# a round puff, and keeps turbulence modest so it flickers without
		# visibly scattering the cone apart.
		process.particle_flag_align_y = true
		process.angle_min = -12.0
		process.angle_max = 12.0
		process.color_ramp = ParticleFX.build_color_ramp([
			{"offset": 0.0, "color": Color(1.0, 0.95, 0.75, 1.0)},
			{"offset": 0.25, "color": Color(1.0, 0.55, 0.1, 1.0)},
			{"offset": 0.6, "color": Color(0.85, 0.25, 0.05, 0.9)},
			{"offset": 1.0, "color": Color(0.35, 0.06, 0.02, 0.0)},
		])
		process.scale_curve = ParticleFX.build_scale_curve(0.6, 1.15, 0.3, 0.7)
		process.turbulence_enabled = true
		process.turbulence_noise_strength = 1.0
		process.turbulence_noise_scale = 2.0
		process.turbulence_influence_min = 0.04
		process.turbulence_influence_max = 0.15
	stream.process_material = process
	stream.draw_pass_1 = droplet
	stream.emitting = false
	add_child(stream)
	stream.top_level = true
	return stream


## Party blorbs beeline straight to the player, same as always. A discovered
## wild blorb instead heads for the nearest blorb that's already in the
## party -- per direct instruction, it should read as tagging along with
## the other blorbs, not beelining to the player itself -- falling back to
## the player only if the party's otherwise empty (shouldn't happen in
## practice, since the starter trio is always in_party from the start).
func _follow_target() -> Vector2:
	if not in_party:
		var nearest: Variant = _nearest_party_blorb_position()
		if nearest != null:
			return nearest
	return Vector2(_player.global_position.x, _player.global_position.z)


func _nearest_party_blorb_position() -> Variant:
	var here := Vector2(global_position.x, global_position.z)
	var best: Vector2
	var best_dist := INF
	var found := false
	for other in get_tree().get_nodes_in_group("blorbs"):
		if other == self or not other.in_party:
			continue
		var other_pos := Vector2(other.global_position.x, other.global_position.z)
		var d := here.distance_to(other_pos)
		if d < best_dist:
			best_dist = d
			best = other_pos
			found = true
	return best if found else null


func _apply_separation(pos: Vector2) -> Vector2:
	var result := pos
	for other in get_tree().get_nodes_in_group("blorbs"):
		if other == self:
			continue
		var other_pos := Vector2(other.global_position.x, other.global_position.z)
		var offset := result - other_pos
		var dist := offset.length()
		if dist < MIN_SEPARATION and dist > 0.001:
			result += offset.normalized() * (MIN_SEPARATION - dist)
	return result


func _apply_player_push(pos: Vector2, delta: float) -> Vector2:
	var player_pos := Vector2(_player.global_position.x, _player.global_position.z)
	var offset := pos - player_pos
	var dist := offset.length()
	if dist < PLAYER_PUSH_RADIUS and dist > 0.001:
		var push_scale := AIRBORNE_PLAYER_PUSH_SCALE if _player.is_airborne() else 1.0
		var needed := offset.normalized() * (PLAYER_PUSH_RADIUS - dist)
		return pos + needed.limit_length(PLAYER_PUSH_SPEED * movement_speed_multiplier * push_scale * delta)
	return pos
