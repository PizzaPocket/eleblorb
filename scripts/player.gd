class_name Player
extends CharacterBody3D

## Third-person controller. Movement is camera-relative; the visual mesh turns
## to face the direction of travel. Works with keyboard/mouse (WASD to move,
## mouse to look) and gamepad (left stick to move, right stick to look) via
## the project's own Input Map actions -- see input_map.gd for the full
## control scheme and how each action's keyboard/mouse and gamepad events
## are registered together.

## Fired whenever current_hp changes (damage, heal, or regen) so hud.gd can
## drive its HP readout without polling every frame.
signal hp_changed(current: float, max_value: float)

## Minimal HP pool -- didn't exist before skeleton NMEs (see skeleton_nme.gd)
## gave the player something to actually take damage from. Same regen-after-
## delay shape as blorb.gd's own HP (see its HP_REGEN_PER_SECOND/
## HP_REGEN_DELAY and _update_resources()); no death/respawn handling yet,
## current_hp just clamps at 0 (see docs/world_bible.md's open threads).
const MAX_HP := 100.0
const HP_REGEN_PER_SECOND := 2.0
const HP_REGEN_DELAY := 4.0

var current_hp: float = MAX_HP
var _hp_regen_delay: float = 0.0

@export var move_speed: float = 6.0
@export var sprint_multiplier: float = 1.6
## A matched pair of worn leg blorbs acts as skates while running. This is
## deliberately traversal-only: _animate_walk() compensates for it so the
## existing run pose and leg cadence remain exactly as they are without it.
const BLORB_SKATE_SPEED_MULTIPLIER := 3.0
## Raised from the original 6.8 per direct instruction, so an ordinary jump
## reliably clears a blorb's collision top (~1.14m -- see blorb.gd's
## RADIUS/BODY_HEIGHT) rather than falling short of it, not just for the
## trampoline bounce's own super-jump (which scales off this value too).
# Paired with JUMP_GRAVITY_SCALE below: this higher launch velocity gives
# the jump an immediate, decisive upward kick instead of a floaty rise.
# Both values were scaled together, so peak height remains approximately
# unchanged while the full arc completes substantially faster.
@export var jump_velocity: float = 11.3
@export var rotation_speed: float = 10.0
@export var mouse_sensitivity: float = 0.003
@export var joy_look_sensitivity: float = 3.0
@export var joy_deadzone: float = 0.2

const PITCH_MIN := deg_to_rad(-60.0)
const PITCH_MAX := deg_to_rad(70.0)
# A dive is a six-degree-of-freedom traversal state, unlike walking. Keep a
# tiny margin from ±90° to avoid the yaw singularity while still permitting
# an effectively straight vertical ascent or descent.
const AERIAL_CAMERA_PITCH_MIN := deg_to_rad(-88.0)
const AERIAL_CAMERA_PITCH_MAX := deg_to_rad(88.0)

# Terrain collision is real mesh (terrain_generator.gd's
# _build_terrain_collision(), a ConcavePolygonShape3D matching the rendered
# surface exactly). Walkable ground still snaps to the analytic height
# function rather than leaning on move_and_slide() for vertical position --
# not to work around approximate collision, but because a direct snap gives
# perfectly smooth vertical movement over the terrain's own noise-driven
# bumps, where physics-driven settling would read as slightly jittery. The
# real collision is still what's felt on slopes steeper than
# GROUND_SNAP_MAX_SLOPE, which is what keeps steep mountainsides unclimbable.
const GROUND_SNAP_MAX_SLOPE := 0.9  # rise/run, ~42 degrees
const FOOT_OFFSET := 0.05
const CLOUD_SINK_DEPTH := 0.10
## Shallower than CLOUD_SINK_DEPTH -- a tree canopy is a thin leaf mass, not
## a fluffy cloud bank, so standing on top should read as resting lightly on
## foliage rather than sinking noticeably in.
const TREE_CANOPY_SINK_DEPTH := 0.04

## Runtime possession flag: true whenever the player is directly piloting
## Xiao Hou Zi (see xiao_hou_zi.gd's begin_possession()/end_possession() and
## this file's own _try_start_xiao_hou_zi_control()/_end_xiao_hou_zi_
## control()). Started life as a permanently-false TEMP_PLAY_AS_XIAO_HOU_ZI
## debug const that reskinned this CharacterBody as the monkey rig for
## isolated review -- every site that const touched is still marked below
## with that old name, but now flips live at possession start/end instead
## of staying dead code.
## Reskinning THIS body (rather than driving a separate NPC one, the way
## Blorbus possession does) is deliberate: it's what lets swimming, flight,
## and the blorb suit -- none of which are aware of which rig is visible --
## keep working exactly as they do for the human, with zero duplicated logic.
var _piloting_xiao_hou_zi := false
# Temporary presentation scale for Xiao Hou Zi. Subsequent proportion work
# shortened the legs and lowered the body, so his current crown height is
# approximately 0.465m rather than forcing the rig back up to 0.50m.
const TEMP_MONKEY_SCALE := 2.3585
# Frame the half-metre monkey directly instead of retaining the human's
# 1.6m-high, 3.5m-distant camera composition.
const TEMP_MONKEY_CAMERA_HEIGHT := 0.75
const TEMP_MONKEY_CAMERA_DISTANCE := 2.0
# His short legs limit ground coverage, but they should still step briskly.
# Since phase advancement is multiplied by traversal speed below, 2.16x at
# 2.5m/s yields ~9.18rad/s: 10% below the human's 10.2rad/s full-walk cycle.
const TEMP_MONKEY_MOVE_SPEED := 2.5
const TEMP_MONKEY_WALK_CADENCE_SCALE := 2.16
# Per direct instruction: he's a monkey, so every jump -- baseline ground
# jump and blorb-bounce alike -- launches 80% faster than the human's. Both
# takeoff sites (the ground-jump branch and _apply_blorb_bounce_velocity)
# multiply jump_velocity by this before the sqrt(height_multiplier) scaling,
# so it stacks correctly with super/giant jump heights rather than
# replacing them.
const TEMP_MONKEY_JUMP_MULTIPLIER := 1.8
# Walk/run offsets are authored for ProceduralFigure's ~2m base rig. The
# monkey's unscaled rig is 0.20m, so one tenth preserves the same percentage
# of body height before each rig's separate display scale is applied.
const TEMP_MONKEY_BODY_MOTION_SCALE := 0.1
# Current displayed crown height (~0.465m) relative to the human player
# (~1.896m). World-space contact tolerances use this ratio, unlike local rig
# animation offsets above.
const TEMP_MONKEY_HEIGHT_RATIO := 0.245

# A small pre-emptive lift along the analytic terrain height before the real
# move, so move_and_slide() doesn't need to resolve the rise on its own this
# frame -- matters most right at small geometric seams (mesh triangle edges,
# prop bases) rather than the old coarse box-grid steps this originally
# guarded against. Only applies within the walkable slope range, so
# genuinely steep mountainsides are still a wall.
const STEP_LOOKAHEAD := 0.4

# Per direct instruction: leaving the ground and reaching the jump's apex
# should feel quick, not like real-world gravity -- steepens the whole
# airborne arc (both rising and falling use the same scaled gravity, since
# a fast rise needs upward velocity decaying faster too, not just a faster
# fall). jump_velocity above is bumped up alongside this so the peak height
# lands close to what the old jump_velocity=4.5/unscaled-gravity arc gave
# (~1m), rather than just making the jump shorter as well as faster.
const JUMP_GRAVITY_SCALE := 4.8
## A compact hop from ordinary chest-deep buoyancy, intended to clear a
## shoreline lip or low platform without making swimming launches as tall
## as the normal land jump.
const WATER_EXIT_JUMP_HEIGHT_MULTIPLIER := 0.7
## Caps every ordinary gravity-driven descent, including the instant flight
## ends because the air suit is removed. Upward jumps remain unchanged.
const TERMINAL_FALL_SPEED := 32.0

const WALK_SWING_SPEED := 1.7  # radians per (m/s of horizontal speed) per second
const WALK_SWING_AMOUNT := 0.5
# Running isn't just walking sped up -- per direct instruction, it should
# read as more dynamic movement, not just a faster cycle. SPRINT_SWING_SPEED_
# SCALE < 1.0 slows the cycle rate back down a bit relative to what linear
# scaling with speed would give (longer strides eating some of the speed
# increase instead of pure faster cadence), while SPRINT_SWING_AMOUNT/
# SPRINT_BEND_SCALE push the swing arc and knee/elbow bend further than
# walking ever reaches.
const SPRINT_SWING_SPEED_SCALE := 0.72
const SPRINT_SWING_AMOUNT := 0.8
const SPRINT_BEND_SCALE := 1.45
# The elbow's bend now ranges from a minimum at the back of the backswing
# up to a maximum at the forwardmost point (see _animate_walk's
# forward_fraction) -- while walking that minimum is 0 (arm fully
# straightens at the back), but per direct instruction running should keep
# more bend even at that low point, without losing "the back of the
# backswing is still the least-bent point of the cycle" -- a nonzero floor
# fraction rather than a different curve shape.
const SPRINT_ELBOW_MIN_FRACTION := 0.35
# Running-only second knee-bend peak for ground contact/loading, on top of
# the ordinary swing-phase bend -- see its own comment at the point of use
# in _animate_walk for the full derivation, including why this has to be a
# different amplitude than ProceduralFigure.KNEE_BEND_AMOUNT rather than
# reusing it. First-pass value, not derived/tested -- flagged as tunable.
const KNEE_STANCE_BEND_AMOUNT := deg_to_rad(38.0)
# Running-only ankle flex through ground contact -- foot toward the shin as
# the planted leg loads, foot toward the calf as it springs off. See the
# ankle block in _animate_walk for the sign convention (reused from the
# jump/landing poses, not re-guessed) and the phase derivation. First-pass
# values, not derived/tested -- flagged as tunable.
const ANKLE_DORSIFLEX_AMOUNT := deg_to_rad(18.0)
const ANKLE_PLANTARFLEX_AMOUNT := deg_to_rad(20.0)
# Per direct instruction: a natural running stride doesn't move at constant
# angular speed -- the limbs snap through fastest as they cross beneath the
# body (swing=0, legs closest together) and hang for a beat at the fully
# outstretched extremes (swing at its peak) before reversing. Plain sinusoidal
# timing (swing = sin(_walk_phase)*amount, phase advancing linearly in time)
# already has a mild version of this for free -- it's simple harmonic motion,
# so the position's rate of change is proportional to cos(phase), which is
# largest at swing=0 and zero at the swing peaks -- but per the correction
# that wasn't pronounced enough to read as this specific quality.
#
# SPRINT_STRIDE_EASE warps the phase fed into sin()/cos() rather than
# swapping the curve shape: stride_phase = _walk_phase + EASE*sin(2*
# _walk_phase). This is a standard phase-warp for biasing a periodic curve's
# speed while keeping its period and amplitude fixed. Worked out
# mathematically (no live preview available for this rig -- see figure-rig
# skill): d(stride_phase)/d(_walk_phase) = 1 + 2*EASE*cos(2*_walk_phase),
# which is >1 right around _walk_phase=0/PI (swing=0, the crossing point --
# limb races ahead of raw time, reads as faster) and <1 right around
# _walk_phase=PI/2/3PI/2 (swing at its peak, fully outstretched -- limb lags
# behind raw time, reads as a hang/pause before reversing). Keep EASE below
# 0.5 or that derivative goes negative (the phase would run backwards).
# _walk_phase itself must keep accumulating linearly, unwarped -- warping the
# accumulator instead of just its use would compound every frame.
#
# Applied to the run/sprint stride specifically (see stride_phase in
# _animate_walk), not the walk cycle -- per direct instruction this is about
# "the run cycle"/"the run stride"; NPCs never sprint at all (see npc.gd's
# own _animate_walk), so this constant and stride_phase only exist here.
const SPRINT_STRIDE_EASE := 0.35
# Per direct instruction, on top of SPRINT_BEND_SCALE (which also scales the
# knees) the sprinting arms should bend further still -- a separate knob so
# turning this up doesn't also over-bend the knees.
const SPRINT_ELBOW_EXTRA_BEND := 1.3
const POSE_SETTLE_SPEED := 8.0

# Human cervical range of motion: roughly 80 deg of axial rotation (turning
# to look over a shoulder) each way, ~50 deg of extension (looking up) and
# ~60 deg of flexion (looking down) -- looking straight back or folding the
# chin past the chest isn't something a neck does, so the head stops
# mirroring the camera past these and the body has to turn instead.
const HEAD_YAW_LIMIT := deg_to_rad(75.0)
const HEAD_PITCH_UP_LIMIT := deg_to_rad(50.0)
const HEAD_PITCH_DOWN_LIMIT := deg_to_rad(60.0)
const HEAD_TURN_SPEED := 10.0
## Flight/dive body lean can be extreme; keep the skull visually calm by
## using a restrained camera-facing neck adjustment in aerial states.
const AERIAL_HEAD_YAW_LIMIT := deg_to_rad(32.0)
## A horizontal flying body can be pitched nearly 80 degrees. Its neck must
## be able to counter-extend enough for the face to remain camera-led.
const AERIAL_HEAD_PITCH_LIMIT := deg_to_rad(85.0)
const AERIAL_HEAD_TURN_SPEED := 6.0

const CAMERA_GROUND_MARGIN := 0.4
const LAVA_CONTACT_TOLERANCE := 0.45
const LAVA_WARNING_COOLDOWN := 1.25
const WATER_STREAM_SPEED := 15.0
const WATER_STREAM_LIFETIME := 0.42

## CONVENTION, confirmed by direct correction -- do not rotate this
## CharacterBody's own top-level `rotation` to solve a spawn-framing
## problem (e.g. "the camera is blocked by something"). main.tscn's own
## spawn establishes that the player always starts facing the camera
## straight on (CameraRig hangs off this body with zero local rotation, so
## the camera's spawn position/facing is entirely inherited from THIS
## node's own rotation) -- kingdom_bootstrap.gd's arrival spawn must keep
## that same framing. A first attempt at fixing a kingdom-portal-blocks-
## camera bug rotated this body's own `rotation.y` instead, which desynced
## it from _animate_walk()'s/_update_ai()-style world-space facing math
## elsewhere (everything computed as atan2(motion.x, motion.z) and assigned
## directly to a LOCAL rotation implicitly assumes this body's own base
## rotation is 0) -- reported back as movement/animation reversed ("he
## moonwalks backwards"). The correct fix for a spawn-framing problem is to
## change where the blocking object (the portal) is placed relative to the
## fixed player-faces-camera arrangement, never to rotate this node.
@onready var camera_rig: Node3D = $CameraRig
@onready var camera_pivot: Node3D = $CameraRig/CameraPivot
@onready var camera_spring_arm: SpringArm3D = $CameraRig/CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraRig/CameraPivot/SpringArm3D/Camera3D
@onready var visuals: Node3D = $Visuals
@onready var terrain: Node = get_node("../Terrain")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var _leg_left: Node3D
var _leg_right: Node3D
var _arm_left: Node3D
var _arm_right: Node3D
var _knee_left: Node3D
var _knee_right: Node3D
var _elbow_left: Node3D
var _elbow_right: Node3D
var _ankle_left: Node3D
var _ankle_right: Node3D
var _spine: Node3D
# _piloting_xiao_hou_zi: holds the full pivots dict from MonkeyFigure.
# build() so _process() can re-loft its limb tubes every frame the same way
# BlorbSuitController re-lofts worn-blorb tubes -- see monkey_figure.gd's
# own rebuild_limbs(). Unused (stays empty) when the flag is off.
var _monkey_pivots: Dictionary = {}
## The pivots dict most recently handed to _blorb_suit.setup() (see
## _rebuild_visuals_rig()/_ready()), kept around purely so _apply_blorb_
## suit_rig_scale() can re-call setup() (e.g. when CheatCodes.enabled
## toggles) without needing to rebuild the whole visible rig from scratch.
var _visuals_pivots: Dictionary = {}
var _head: Node3D
var _head_look_yaw: float = 0.0
var _head_look_pitch: float = 0.0
## Only ProceduralFigure's own build() returns a "neck" pivot (see that
## file's own NeckPivot comment) -- MonkeyFigure's dict has no equivalent
## key, so this is null while piloting Xiao Hou Zi (see _apply_pivots()'s
## own .get() read). Currently only used by _apply_manchego_seated_pose(),
## which is unreachable while reskinned as Xiao Hou Zi anyway (mounting
## Manchego always releases that possession first -- see
## start_riding_manchego()), but kept nullable rather than assumed non-null
## since nothing else guarantees that ordering will always hold.
var _neck: Node3D
var _hips: Node3D
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()
var _walk_phase: float = 0.0
var _prev_grounded: bool = true
## How long the "was just genuinely touching ground" grace period lasts
## once is_on_floor() has actually fired, in seconds -- not indefinitely
## via _prev_grounded alone (see grounded's own comment in
## _physics_process for why that was a real bug: _prev_grounded never
## expires on its own, so once truly grounded, walking off a short
## platform's edge kept grounded true -- and gravity suppressed -- for as
## long as the player's height stayed within MAX_TERRAIN_FOLLOW_HEIGHT of
## the far-below analytic terrain function, which for an elevated platform
## could be a long, visibly-floating while. A handful of frames' worth is
## enough to smooth ordinary is_on_floor() flicker over terrain's own
## bumps -- the only thing this grace period was ever meant to cover).
const GROUNDED_GRACE_DURATION := 0.15
var _grounded_grace_timer: float = 0.0
var _landing_timer: float = 0.0
## Starts at zero after an impact, then fades the held landing limbs into
## the live walk/run cycle instead of letting phase-driven targets pop in.
var _walk_cycle_recovery: float = 1.0
## Prevents the walk cycle from replacing a released power-arm pose in one
## frame; the normal swing regains control through the same interpolation.
var _arm_power_recovery: float = 1.0
var _left_arm_power_blend := 0.0
var _right_arm_power_blend := 0.0
var _was_moving: bool = false
## Idle-pose variety, re-rolled each time movement stops (see
## _roll_idle_pose()) rather than fixed once at spawn -- a relaxed standing
## pose should read as freshly settled-into each time, not a single fixed
## quirk this character always has.
var _idle_elbow_left: float = 0.0
var _idle_elbow_right: float = 0.0
var _idle_leg_variant_active: bool = false
var _idle_bent_leg_side: float = 1.0
var _idle_knee_bend: float = 0.0
## _spine's own local Y at rest (cached once in _ready(), right after
## ProceduralFigure.build() sets it) -- the walk/run/landing body-dip
## effects offset _spine.position.y relative to this, rather than assuming
## 0.0, since spine_pivot's actual rest height is computed internally by
## procedural_figure.gd and isn't otherwise exposed.
var _spine_rest_y: float = 0.0
## Same idea as _spine_rest_y, for the hips mesh -- per direct instruction,
## the walk/run/landing vertical bob should move the hips together with
## the spine (the whole upper body above the legs, not just the spine
## alone), matching how a real gait's bob actually comes from leg
## articulation lifting/dropping the whole pelvis. Legs stay planted
## (leg_pivot isn't touched by this) since they're what's actually
## contacting the ground.
var _hips_rest_y: float = 0.0

const SHIRT_COLOR := Color(0.15, 0.35, 0.72)
const PANTS_COLOR := Color(0.1, 0.1, 0.13)
const SHOE_COLOR := Color(0.65, 0.14, 0.10)
# Per direct instruction: short sleeves (bare-skin arms with a shirt-
# colored cap over just the top of the upper arm -- see ProceduralFigure.
# SLEEVE_STYLE_SHORT), with a light blue triangle emblem on the chest --
# restoring a design element from before the rig went fully procedural.
const CHEST_EMBLEM_COLOR := Color(0.55, 0.78, 0.98)
# Per direct instruction: keeps the buzzcut (the hero's own established
# style, unlike the NPCs' mixed styles). A touch lighter than FigureHair's
# own DEFAULT_HAIR_COLOR (0.14, 0.1, 0.08) -- written as the literal
# result of DEFAULT_HAIR_COLOR.lightened(0.18) rather than calling
# .lightened() in this const initializer itself, since GDScript's const
# folding doesn't reliably evaluate method calls at parse time (the same
# class of issue documented in wilderness_scatter.gd's own TREE_BUILDERS
# fix, there for lambdas specifically).
const HAIR_COLOR := Color(0.2948, 0.262, 0.2456)
# Per direct instruction: a bit shorter overall (the only existing knob for
# height is ProceduralFigure.build()'s uniform `scale`, which also narrows
# him slightly along with it -- a normal tradeoff for "a bit shorter" on a
# human figure, not something that needed a dedicated height-only scale
# just for this). Abdomen width scale bumped up from the floor (1.0, the
# narrowest a build() caller can ask for), but per a direct correction not
# all the way to where build()'s own flush-cap logic kicks in (that
# happens at 1.2 on this build's chest proportions, which read as
# perfectly flush -- not what was wanted): 1.15 keeps the abdomen close to
# the chest's own width/front on both axes while leaving a real, if small,
# gap on each.
const HEIGHT_SCALE := 0.95
const ABDOMEN_WIDTH_SCALE := 1.15

# A real person's spine tilts forward a little while walking, not staying
# ramrod straight -- per direct instruction. Small and speed-proportional
# (full lean only once at full move_speed/sprint speed), not a fixed lean
# the instant movement starts. Running leans further than walking -- per a
# direct follow-up correction, the original single SPINE_LEAN_MAX (6 deg)
# read as too extreme for an ordinary walk; walking now leans half as far,
# with the original full amount kept for sprinting.
const SPINE_LEAN_MAX_WALK := deg_to_rad(3.0)
const SPINE_LEAN_MAX_RUN := deg_to_rad(6.0)

# Jump pose (airborne -- replaces what used to be a rigid neutral-pose
# hover, per direct instruction) and the brief landing-impact crouch that
# follows it.
#
# Signs: elbow keeps its own already-verified sign (negative = forward
# flex, never hyperextending) unchanged from the walk cycle. Ankle is a
# brand new joint (see procedural_figure.gd's AnklePivot) with no prior
# verified sign at all -- positive is chosen to match the same "+Z end
# tips down" pattern (toes point down = the foot's forward end tipping
# down) spine/head already use.
#
# Shoulder/hip were originally assumed to share that same "positive =
# forward" convention too, reasoned (not independently tested) off the
# walk cycle's reciprocal arm/leg negation -- confirmed backwards by direct
# observation (arms and legs were swinging into the jump pose backward,
# not forward). _animate_airborne negates JUMP_ARM_SWING/JUMP_HIP_BEND at
# the point of use below to correct for it, rather than flipping these
# consts' own sign, so their names still read as positive magnitudes.
# Halved per direct correction -- the shoulders were swinging the arms
# forward too far; the elbow bend itself was fine and stays as it was.
# Asymmetry scaled down to match (kept at roughly the same fraction of the
# smaller base angle, not left as a now-oversized wobble relative to it).
const JUMP_ARM_SWING := deg_to_rad(35.0)
const JUMP_ARM_ASYMMETRY := deg_to_rad(5.0)
const JUMP_ELBOW_BEND := deg_to_rad(55.0)
const JUMP_ELBOW_ASYMMETRY := deg_to_rad(12.0)
## Raised to 45 degrees per direct instruction (from an intermediate 30,
## itself raised from an original 14 -- "increase the hip angle to 45
## degrees").
## Stronger apex tuck brings the thighs much higher toward the torso while
## the separately tuned 130° knee fold remains unchanged.
const JUMP_HIP_BEND := deg_to_rad(82.0)
## Doubled from an original 5 degrees per direct instruction ("have one of
## the hips bend more by 10 degrees to give it variation") -- this is the
## SAME left/right variation mechanism the class doc already describes ("a
## small side-to-side asymmetry so it doesn't read as a perfectly mirrored,
## mechanical pose"), just amplified: each leg is offset this far from
## JUMP_HIP_BEND in opposite directions (see _animate_airborne's own ±
## below), so the two hips now differ from each other by 2x this value.
const JUMP_HIP_ASYMMETRY := deg_to_rad(10.0)
## 130 degrees -- was 3x JUMP_HIP_BEND (135), pulled back down 5 degrees per
## direct instruction ("reduce the knee bend by like 5 degrees"). Now a
## plain literal, not a multiple of JUMP_HIP_BEND, since it's being tuned
## independently of the hip bend at this point.
const JUMP_KNEE_BEND := deg_to_rad(130.0)
const JUMP_KNEE_ASYMMETRY := deg_to_rad(7.0)
const JUMP_ANKLE_EXTEND := deg_to_rad(22.0)
const JUMP_ANKLE_ASYMMETRY := deg_to_rad(6.0)
const JUMP_POSE_SETTLE_SPEED := 9.0
# After the apex the legs do not snap straight; they ease into this still
# clearly airborne, bent descent pose until the landing reaction takes over.
const DESCENT_HIP_BEND := deg_to_rad(18.0)
const DESCENT_KNEE_BEND := deg_to_rad(46.0)
const DESCENT_ANKLE_EXTEND := deg_to_rad(8.0)
const DESCENT_ASYMMETRY_FRACTION := 0.45

# Landing: a brief, fast-easing crouch -- hips/knees flex the same
# direction as the jump pose (just deeper, and symmetric -- landing on
# both feet evenly isn't a lopsided motion the way mid-air drift can read
# as), plus a forward spine lean reacting to the impact. Ankle flexes the
# OPPOSITE direction from the jump pose's toe-point (dorsiflexion
# absorbing the impact, not plantarflexion), matching how a real landing
# actually absorbs shock. Held for LANDING_DURATION, then _animate_walk's
# ordinary grounded branches take back over and ease it away -- no
# separate ease-out state needed since that lerp is already gentle.
const LANDING_SPINE_LEAN := deg_to_rad(12.0)
const LANDING_HIP_BEND := deg_to_rad(28.0)
const LANDING_KNEE_BEND := deg_to_rad(38.0)
const LANDING_ANKLE_BEND := deg_to_rad(16.0)
const LANDING_ARM_OUTWARD_ANGLE := deg_to_rad(27.0)
const LANDING_SETTLE_SPEED := 16.0
const LANDING_DURATION := 0.18
const LANDING_WALK_RECOVERY_SPEED := 7.0
# The upper body doesn't just react in rotation on impact -- per direct
# instruction, it should actually sink slightly below its resting height
# too, then ease back up. Applied as a temporary offset added on top of
# _spine_rest_y/_hips_rest_y (see _ready()), the same mechanism WALK_BODY_
# DIP_AMOUNT/RUN_BODY_BOB_AMOUNT use below, just driven by _landing_timer's
# own fast ease instead of walk phase. 0.05 originally, then a direct
# follow-up correction asking for a more noticeable impact; raised again by
# a further 0.10 (to 0.15) per direct instruction once JUMP_HIP_BEND/
# JUMP_KNEE_BEND grew much deeper -- the legs now fold noticeably more on
# the way up, so the impact needs to read as correspondingly harder on the
# way down too.
const LANDING_BODY_DIP_AMOUNT := 0.15

# Running's body-bob is a distinct shape from walking's, not just a bigger
# version of the same dip -- per direct instruction, a run has a real
# flight-phase feel: the body rises above baseline as the legs are in the
# process of spreading apart (the push-off/leap), then dips BELOW baseline
# right at the stride's apex (full leg spread), simulating the impact of
# landing back down, cycling continuously. cos(2*phase) matches this
# exactly: phase=0/PI (legs crossing beneath) is where it peaks (+1, the
# rise, right as the spreading is just beginning), falling through zero
# partway through the spread and reaching its minimum (-1, the dip) at
# phase=PI/2/3PI/2 (max spread, the stride's apex) -- see
# WALK_BODY_DIP_AMOUNT in procedural_figure.gd for the walk-only
# equivalent, which only ever dips (no rise) and bottoms out at the exact
# same max-spread point instead of just before it. 0.025, not the original
# 0.012, per a direct follow-up correction asking for a more noticeable bob.
const RUN_BODY_BOB_AMOUNT := 0.025

# Trampoline bounce off a blorb -- landing on top of one (see
# _check_blorb_bounce()) launches the player straight back into the jump arc
# instead of coming to rest, reusing jump_velocity/_jumping/_landing_timer
# rather than a separate mechanic, so it gets the ordinary landing-crouch and
# airborne poses for free. Height scales with velocity squared under
# constant gravity (h = v^2 / 2g), so hitting an exact height multiple needs
# a sqrt() on the velocity, not a direct multiply -- this const is
# deliberately named for the height it produces (8x, per direct
# instruction -- raised from an initial 3x), with sqrt() applied at the
# point of use in _bounce_off_blorb.
const SUPER_JUMP_HEIGHT_MULTIPLIER := 8.0
## The Size blorb is not a trampoline: standing on its mesh surface permits
## a deliberate jump three times as high as an ordinary blorb jump.
## Double the previous giant-surface superjump height: six times a normal
## blorb superjump's height (the ordinary blorb trampoline is 8x a normal
## jump), for a 48x normal-jump apex from the giant's elevated surface.
const GIANT_SUPER_JUMP_HEIGHT_MULTIPLIER := SUPER_JUMP_HEIGHT_MULTIPLIER * 6.0
const GIANT_GOO_LIFT_SPEED := 4.0
const GIANT_GOO_JUMP_LIFT_SPEED := 18.0
const GIANT_GOO_JUMP_LIFT_DURATION := 0.45
const GIANT_SURFACE_LANDING_SINK_DEPTH := 0.45  # one quarter of the 1.8m player capsule
const GIANT_SURFACE_RECOVERY_SPEED := 1.5
const PLAYER_CAPSULE_HEIGHT := 1.8
const GIANT_SURFACE_SNAP_TOLERANCE := 4.0
# Lake water uses the giant's slow, deliberate buoyancy rather than an
# invisible standable floor. With the player's feet 1.1m below the surface,
# their head and shoulders remain above water while the rest of the body is
# visibly submerged.
const LAKE_SWIM_FOOT_DEPTH := 1.4
const LAKE_BUOYANCY_LIFT_SPEED := 10.0
const LAKE_MIN_SWIMMABLE_DEPTH := LAKE_SWIM_FOOT_DEPTH + 0.35
const LAKE_DIVE_SPEED := 4.2
const LAKE_DIVE_FLOOR_CLEARANCE := 0.5
const AIR_FLIGHT_SPEED := 6.0
const AIR_FLIGHT_HOVER_HEIGHT := 0.5
const AIR_FLIGHT_EXIT_RECOVERY_DURATION := 0.45
const POWERED_HOVER_HEIGHT := 1.15
const POWERED_HOVER_LIFT_SPEED := 5.0
const POWERED_HOVER_SETTLE_SPEED := 9.0
## Each actively firing Fire foot compounds this multiplier while a chest
## Air blorb is already supplying flight: one leg = 1.35x, two = 1.8225x.
const FIRE_FOOT_FLIGHT_SPEED_MULTIPLIER := 1.35
const AERIAL_FAST_SPEED_MULTIPLIER := 1.8
## Flying sprint is intentionally twice its previous fast-flight rate;
## swimming retains AERIAL_FAST_SPEED_MULTIPLIER unchanged.
const FLIGHT_SPRINT_SPEED_MULTIPLIER := AERIAL_FAST_SPEED_MULTIPLIER * 2.0
# The underwater body turns around the base-of-skull anchor rather than its
# feet. Keeping these as aerial constants makes the same anchor-led movement
# usable by the forthcoming flying state without coupling it to lake logic.
const AERIAL_BODY_PITCH_MAX := deg_to_rad(88.0)
## Even level swimming carries a distinct forward, trailing-body angle;
## vertical camera movement adds to or subtracts from this cruise lean.
const AERIAL_BODY_CRUISE_LEAN := deg_to_rad(78.0)
const AERIAL_BODY_ROLL_MAX := deg_to_rad(16.0)
const AERIAL_BODY_LEAN_SPEED := 7.0
## Releasing input should feel buoyant and unhurried, not snap the body
## upright the instant a swim stroke stops.
const AERIAL_BODY_REST_SPEED := AERIAL_BODY_LEAN_SPEED * 0.1
## Alternating leg wave used for both chest-deep surface swimming and free
## diving. It layers over the relaxed descent/floating pose rather than
## replacing it with a rigid straight-legged crawl.
const SWIM_KICK_SPEED := 8.0
const SWIM_KICK_HIP_AMOUNT := deg_to_rad(19.0)
const SWIM_KICK_KNEE_AMOUNT := deg_to_rad(17.0)
## Fast strokes streamline the arms slightly behind the torso, with elbows
## almost straight rather than retaining the relaxed descent bend.
const SWIM_FAST_ARM_BACK_SWING := deg_to_rad(22.0)
const SWIM_FAST_ELBOW_BEND := deg_to_rad(3.0)
## Feet stay pointed back like relaxed flippers even while motionless; the
## kick is only a subtle extra extension, never a return toward standing.
const SWIM_FLOAT_ANKLE_EXTEND := deg_to_rad(38.0)
const SWIM_KICK_ANKLE_AMOUNT := deg_to_rad(10.0)
# How close to straight-up a slide collision's normal has to be to count as
# "landed on top of" the blorb rather than brushing its side while falling
# past -- roughly a 60-degree cone around straight up, deliberately looser
# than CharacterBody3D's own (~45-degree) floor_max_angle, so the bounce can
# trigger even where a genuine is_on_floor() landing wouldn't.
const BLORB_BOUNCE_NORMAL_MIN := 0.5
# A forgiveness window for "hit the jump button right as you bounce" --
# demanding a press on the exact physics frame contact resolves would be
# unreasonably precise. The "jump" action gets buffered for this long; if a blorb
# bounce happens while the buffer is still live, it counts as timed and
# upgrades to the super jump. Widened from an initial 0.15 per direct
# instruction asking for more forgiveness.
const BLORB_SUPER_JUMP_BUFFER := 0.25
# Covers the other direction -- pressing a beat AFTER the bounce, which is
# arguably the more natural way to "time" a reaction to something you only
# see/feel once it's already happened (the blorb's squash is itself a
# post-impact cue). A press landing within this window of an ordinary bounce
# retroactively upgrades it: velocity.y just gets overwritten to the super-
# jump launch value, same as a same-frame press would give, rather than
# something added on top -- not perfectly energy-consistent if the press
# lands right at the end of the window (a little height is "lost" versus a
# same-frame super jump), but the window's short enough that it isn't
# noticeable, and it reads as a satisfying last-instant save either way.
const BLORB_SUPER_JUMP_GRACE_WINDOW := 0.18

# Idle-pose variety, per direct instruction -- standing still shouldn't
# read as a perfectly symmetric, rigid mannequin. Elbows always get a very
# slight, independently-randomized (so naturally asymmetric) relaxed bend;
# legs OPTIONALLY (IDLE_LEG_VARIANT_CHANCE, not every idle moment) settle
# into a "weight on one leg" contrapposto variant on a randomly picked
# side -- see _roll_idle_pose() for how these get picked, and the idle
# branches below for how they're applied.
#
# Elbow sign matches the walk cycle's own already-verified convention
# (negative = forward flex). Leg abduction (IDLE_HIP_OUTWARD_ANGLE, on
# leg_pivot's Z), external rotation (IDLE_HIP_EXTERNAL_ROTATION, on
# leg_pivot's Y -- added per a direct follow-up correction: a true
# contrapposto needs the knee/toe themselves turned outward, not just the
# whole leg swung sideways, which abduction alone gives), and hip drop
# (IDLE_HIP_DROP_ANGLE, on the hips mesh's own Z) are all brand new,
# never-animated axes for this rig -- worked out from Godot's actual
# rotation matrices (Z: x' = cos*x - sin*y, y' = sin*x + cos*y; Y: x' =
# cos*x + sin*z, z' = -sin*x + cos*z) the same way the corner-piece/toe-out
# fixes were. The Z-axis ones (abduction, hip drop) are now confirmed
# correct by direct observation; external rotation is new this pass and
# not yet independently confirmed the same way -- if the knee/toe turn
# inward instead of outward, negate IDLE_HIP_EXTERNAL_ROTATION below. See
# _roll_idle_pose()'s own comment for the full sign derivation.
const IDLE_ELBOW_MIN := deg_to_rad(3.0)
const IDLE_ELBOW_MAX := deg_to_rad(9.0)
const IDLE_LEG_VARIANT_CHANCE := 0.5
const IDLE_KNEE_MIN := deg_to_rad(6.0)
const IDLE_KNEE_MAX := deg_to_rad(14.0)
const IDLE_HIP_OUTWARD_ANGLE := deg_to_rad(5.0)
const IDLE_HIP_EXTERNAL_ROTATION := deg_to_rad(12.0)
const IDLE_HIP_DROP_ANGLE := deg_to_rad(4.0)

var _skip_next_mouse_motion: bool = true
var _jumping: bool = false
## Captured at take-off so the airborne pose reaches its full tuck at the
## apex of normal, blorb, and giant jumps alike, regardless of jump height.
var _jump_takeoff_speed: float = 0.0
## See BLORB_SUPER_JUMP_BUFFER's own comment -- how long a recent "jump"
## press still counts as "timed for the bounce."
var _jump_buffer_timer: float = 0.0
var _giant_goo_active: bool = false
var _giant_surface_grounded: bool = false
var _lake_buoyancy_active: bool = false
var _lake_diving_active: bool = false
var _lake_water_walk_active: bool = false
var _air_flight_active: bool = false
var _was_air_flight_active: bool = false
var _was_suit_flight_active: bool = false
var _air_flight_exit_recovery := 0.0
## World-space heading captured on the exact frame chest-air flight ends.
## Flight can leave Visuals heavily pitched/rolled, where reading rotation.y
## back from Euler angles is ambiguous and can choose the opposite-facing
## solution. The recovery pass instead stands the body upright around this
## explicitly preserved heading.
var _air_flight_exit_yaw := 0.0
var _left_arm_water_active := false
var _right_arm_water_active := false
var _left_arm_fire_active := false
var _right_arm_fire_active := false
var _left_leg_water_active := false
var _right_leg_water_active := false
var _left_leg_fire_active := false
var _right_leg_fire_active := false
var _water_leg_hover_active := false
var _fire_hand_hover_active := false
var _fire_limb_flight_active := false
var _air_foot_hover_active := false
var _was_powered_hover_active := false
var _powered_hover_target_y := 0.0
## World-space swim heading, retained for the visual-only aerial anchor pass
## after move_and_slide() has placed the collision body this frame.
var _aerial_motion_direction := Vector3.ZERO
var _aerial_strafe_input := 0.0
var _aerial_target_yaw := 0.0
var _aerial_was_moving: bool = false
var _aerial_rest_yaw := 0.0
var _aerial_rest_heading_initialized: bool = false
var _swim_kick_phase := 0.0
## True only for a jump that began while standing on the giant's upper mesh.
## It is deliberately distinct from merely being inside the goo at ground
## level, which must never teleport a normal jump to the surface.
var _giant_surface_jump_in_progress: bool = false
var _giant_goo_jump_lift_timer: float = 0.0
var _giant_anchor: Blorb = null
var _giant_anchor_local_position := Vector3.ZERO
var _giant_anchor_yaw: float = 0.0
## See BLORB_SUPER_JUMP_GRACE_WINDOW's own comment -- counts down after an
## ordinary (non-super) blorb bounce; a jump press before it hits zero
## upgrades that bounce to a super jump after the fact.
var _blorb_super_jump_grace: float = 0.0
var _lava_warning_cooldown: float = 0.0

var _held_visual: Node3D = null
var _hand_right: Node3D
var _hand_left: Node3D
var _palm_right: Node3D
var _palm_left: Node3D
var _toe_right: Node3D
var _toe_left: Node3D
var _water_stream_left: GPUParticles3D
var _water_stream_right: GPUParticles3D
var _fire_stream_left: GPUParticles3D
var _fire_stream_right: GPUParticles3D
var _water_leg_stream_left: GPUParticles3D
var _water_leg_stream_right: GPUParticles3D
var _fire_leg_stream_left: GPUParticles3D
var _fire_leg_stream_right: GPUParticles3D
var _prev_throw_pressed: bool = false

## Blorb suit -- see blorb_suit_controller.gd's own module docstring for
## the full equip/unequip animation design, and blorb_suit.gd for the
## actual per-slot geometry it builds.
var _blorb_suit := BlorbSuitController.new()

## Psychic possession: Blorbus is directly driven (a separate body this
## CharacterBody then follows at a loose distance, like an ordinary party
## blorb) while this CharacterBody becomes that same follower. Entering a
## Size blorb transfers control to that body until switching back, at which
## point Blorbus emerges again. _player_following_blorbus is specifically
## the "a separate body is being driven and this one is following it" flag
## -- Xiao Hou Zi possession (see _piloting_xiao_hou_zi above) works
## differently, reskinning this CharacterBody as him directly rather than
## driving a second body, so it does NOT set this flag; see
## _try_start_xiao_hou_zi_control()'s own doc comment for why. Once Xiao Hou
## Zi has joined the party, the same switch_blorbus press still cycles a
## third state in: human -> Blorbus (if awakened) -> Xiao Hou Zi (if
## recruited) -> human (see _toggle_blorbus_control()).
var _controlled_blorbus: Blorb = null
var _controlled_giant: Blorb = null
## Which party member's own NPC body is currently reskinned as the human and
## AI-following this CharacterBody in his place -- see
## _try_start_xiao_hou_zi_control()/_end_xiao_hou_zi_control(). Distinct from
## _controlled_blorbus/_giant above: those are driven every frame via
## drive_from_player() on their own separate bodies while THIS CharacterBody
## follows them; here it's the reverse (this CharacterBody is what's driven,
## reskinned as Xiao Hou Zi -- see _piloting_xiao_hou_zi), so this var is
## just bookkeeping for which NPC to hand control back to.
var _controlled_xiao_hou_zi: XiaoHouZi = null
var _player_following_blorbus := false
const PLAYER_FOLLOW_DISTANCE := 7.0
const PLAYER_FOLLOW_ARRIVE_DISTANCE := 3.0

## Manchego possession -- a THIRD variant of the same "separate body is
## driven, this CharacterBody follows at a loose distance" shape
## _player_following_blorbus above already covers, reusing that exact
## pattern (see manchego.gd's own class doc for why he gets the
## Blorbus-style separate-body treatment rather than Xiao Hou Zi's
## reskin-in-place trick). Kept as its own flag/var pair rather than folded
## into the Blorbus ones since mounting is triggered by a "Ride Manchego"
## Interactable prompt, not the switch_blorbus cycle, and needs its own
## start entry point manchego.gd's Interactable callback can call directly
## (see start_riding_manchego() below).
var _controlled_manchego: Manchego = null
var _player_following_manchego := false
## Prevents the Interact press that mounted Manchego from immediately being
## read again as a dismount. Armed after the player releases the control.
var _manchego_dismount_armed := false

## ---- Manchego seated rider pose ---- Per direct correction ("add the
## player riding the horse... instead of leaving him where he is, he should
## actually mount on top of the horse and sit on him... the bottom of his
## hip segment [should] sit right on top of the horse's back, and bend his
## hips to maybe 75 degrees and angle them out wide from each other; while
## also rotating the lower legs down at the knee joints to aim toward the
## ground").
##
## Sign reuse, not new guesses (see the figure-rig skill's own "reuse a
## confirmed sign, don't re-derive it" rule): hip forward-bend reuses the
## SAME "negative leg_pivot.rotation.x = thigh forward/up" direction
## player.gd's own jump-tuck pose (JUMP_HIP_BEND, applied as
## `-(hip_bend...)`) and landing crouch (LANDING_HIP_BEND, applied as
## `-LANDING_HIP_BEND`) already confirmed; the outward splay reuses
## ProceduralFigure's own confirmed "rotation.z sign must match
## signf(leg_pivot.position.x) to read as outward" abduction fact (see
## procedural_figure.gd's own _build_leg() comment) directly off each leg
## pivot's own position, rather than hardcoding which named leg is which
## side (avoiding the exact "label vs. geometry" trap the figure-rig skill's
## own "Confirmed control-mapping facts" section documents having bitten
## arm_left/arm_right once already).
const RIDE_HIP_BEND := deg_to_rad(75.0)
## "Angle them out wide from each other" -- no exact degree given,
## first-draft guess, adjustable on report like every other unspecified
## magnitude in this rig. Brought in by a third (45 -> 30) per direct
## correction ("his legs are angled out way too much, bring them in about a
## third").
const RIDE_HIP_SPLAY := deg_to_rad(30.0)
## "Rotating the lower legs down at the knee joints to aim toward the
## ground" -- since knee_pivot is a CHILD of leg_pivot and both rotate about
## the same local X axis, their rotations compose by simple addition (see
## KneePivot's own construction in procedural_figure.gd's _build_leg()): a
## knee bend equal in magnitude to RIDE_HIP_BEND but of the SAME (positive)
## sign as this rig's own established knee-flexion direction very nearly
## cancels the hip's own -RIDE_HIP_BEND tilt (net ~= 0, straight down)
## rather than compounding it (which is what the jump-tuck pose's own much
## larger JUMP_KNEE_BEND deliberately does instead, folding the calf up and
## back under the body -- the opposite of what a straddling rider needs).
const RIDE_KNEE_BEND := RIDE_HIP_BEND
## Reuses the same POSE_SETTLE_SPEED every other pose transition in this
## file eases through, rather than inventing a new one.
const RIDE_POSE_SETTLE_SPEED := POSE_SETTLE_SPEED

## Per direct correction ("have the player in riding position lean his hips
## forward and bring his arms forward") -- "hips" here reads as the torso
## generally (the rider leaning forward over the horse's neck), not the
## already-bent leg/hip pivots (RIDE_HIP_BEND above already covers those),
## so this drives `_spine` instead. Reuses the SAME "positive _spine.
## rotation.x = forward lean" sign player.gd's own LANDING_SPINE_LEAN
## already established (see that const's own comment). First-draft
## magnitude, unverified in-engine.
const RIDE_SPINE_LEAN := deg_to_rad(20.0)
## Per direct correction ("since the player is leaning forward, it's
## affecting the forward tilt of the head that gets influenced by the
## camera pitch... adjust so his head defaults to upright at rest when on
## the horse, distributing the upward tilt between the point at the base of
## his skull and the point at the base of his neck"). _head is a child of
## _neck (procedural_figure.gd's own new NeckPivot), which is itself a
## child of _spine -- so RIDE_SPINE_LEAN's own forward tilt was compounding
## straight into _update_head_look()'s own camera-relative pitch target,
## since that target is computed relative to `visuals`' basis, not
## _spine's tilted one, with no awareness the parent chain now carries an
## extra +RIDE_SPINE_LEAN. Splitting a counter-rotation between _neck (see
## _apply_manchego_seated_pose()'s own use) and _head (see
## _update_head_look()'s own is_riding_manchego branch) cancels exactly
## that, the same "split a compensation between two joints" technique
## HorseFigure/manchego.gd's own NECK_LOOK_SHARE already uses for the
## horse's own look-yaw. A plain 50/50 split, not a specified ratio.
const MANCHEGO_HEAD_UPRIGHT_NECK_SHARE := 0.5
## Reuses the SAME "positive shoulder rotation.x = backward, negative =
## forward" sign already established for this rig (see _animate_swimming()'s
## own comment: "Positive shoulder X swings a hanging arm backward (-Z)").
## Raised from 30 to 60 degrees per a further direct correction ("raise his
## arms up a bit") -- since the arm hangs straight down at rotation.x=0 and
## this same forward sweep is what lifts it (0 = hanging, ~90 = horizontal
## reach), a bigger forward angle IS "raised up" in this rig's own
## vocabulary, not a separate axis. First-draft magnitude, unverified
## in-engine.
const RIDE_ARM_FORWARD := deg_to_rad(60.0)
## "Angle his forearms close together from the elbows -- gripping the mane."
## UNVERIFIED GUESS sign: reuses the SAME "rotation.z = side*angle is
## outward" convention already confirmed for the shoulder's own static
## ARM_OUTWARD_ANGLE tilt (see procedural_figure.gd's own comment), just
## negated and moved to the ELBOW pivot instead -- an inward roll there,
## rather than a repeat of the shoulder's outward one, is what should
## converge the two forearms toward each other in front of the chest. Not
## independently confirmed for this specific pivot; if the forearms splay
## apart instead of converging, negate this sign.
const RIDE_ELBOW_INWARD := deg_to_rad(35.0)

## Isolated paper-doll preview for InventoryUI's Blorbs tab.
var _portrait := PlayerPortrait.new()


## Read-only access to the suit controller. InventoryUI edits its persistent
## assignment map; PlayerPortrait renders that map on a separate figure.
func get_blorb_suit() -> BlorbSuitController:
	return _blorb_suit


## InventoryUI grabs this once (it's a live ViewportTexture, always
## current -- see player_portrait.gd) rather than requesting a fresh
## capture per refresh.
func get_portrait_texture() -> Texture2D:
	return _portrait.get_texture()


## InventoryUI calls this as its Blorbs tab opens/closes -- see
## PlayerPortrait.set_active()'s own comment for why the live camera
## shouldn't render every frame while nobody's actually looking at it.
func set_portrait_active(active: bool) -> void:
	_portrait.set_active(active)


func refresh_portrait_assignments() -> void:
	_portrait.refresh(_blorb_suit.assignment_snapshot())


func pick_portrait_slot(viewport_position: Vector2) -> String:
	return _portrait.pick_slot(viewport_position)


func set_portrait_highlighted_slot(slot: String) -> void:
	_portrait.set_highlighted_slot(slot)


func set_portrait_selected_blorb(blorb: Blorb) -> void:
	_portrait.set_selected_blorb(blorb)


func set_portrait_focused_blorb(blorb: Blorb) -> void:
	_portrait.set_focused_blorb(blorb)


func set_portrait_body_focus_active(active: bool) -> void:
	_portrait.set_body_focus_active(active)


## Factored out of _ready() below into its own static function purely so
## the color/proportion params (SHIRT_COLOR, HEIGHT_SCALE, etc.) live in
## exactly one place -- kept as `build_portrait_body`, its name from when
## player_portrait.gd's own now-retired capture rig also called this to
## build a second copy of the body; nothing else calls it today.
static func build_portrait_body(visuals: Node3D) -> Dictionary:
	return ProceduralFigure.build(
		visuals,
		ProceduralFigure.SKIN_COLOR,
		SHIRT_COLOR,
		PANTS_COLOR,
		ProceduralFigure.SLEEVE_STYLE_SHORT,
		HEIGHT_SCALE,
		1.0,  # chest_build_scale
		1.0,  # hip_build_scale
		ABDOMEN_WIDTH_SCALE,
		CHEST_EMBLEM_COLOR,
		HAIR_COLOR,
		FigureHair.STYLE_HERO,
		0.0,  # hair_length_variance
		SHOE_COLOR
	)


## Builds this frame's visible rig -- MonkeyFigure while piloting Xiao Hou
## Zi, ProceduralFigure otherwise -- as a fresh child of `visuals`. Callers
## own freeing whatever rig previously occupied `visuals` (see
## _rebuild_visuals_rig()); this only ever adds, never removes.
func _build_pivots(as_monkey: bool) -> Dictionary:
	if as_monkey:
		var pivots := MonkeyFigure.build(visuals, MonkeyFigure.MONKEY_FUR_COLOR, TEMP_MONKEY_SCALE)
		_monkey_pivots = pivots
		return pivots
	_monkey_pivots = {}
	return build_portrait_body(visuals)


## Points every one of this file's own tracked pivot vars (read every frame
## by _animate_walk() and friends) at the dictionary a fresh _build_pivots()
## call just returned. Split out from _ready() so _rebuild_visuals_rig() can
## re-point them mid-game when possession starts/ends, not just once at boot.
func _apply_pivots(pivots: Dictionary) -> void:
	_leg_left = pivots["leg_left"]
	_leg_right = pivots["leg_right"]
	_arm_left = pivots["arm_left"]
	_arm_right = pivots["arm_right"]
	_knee_left = pivots["knee_left"]
	_knee_right = pivots["knee_right"]
	_elbow_left = pivots["elbow_left"]
	_elbow_right = pivots["elbow_right"]
	_ankle_left = pivots["ankle_left"]
	_ankle_right = pivots["ankle_right"]
	_spine = pivots["spine"]
	_spine_rest_y = _spine.position.y
	# .get(), not ["neck"] -- see _neck's own comment: MonkeyFigure's dict
	# (used while piloting Xiao Hou Zi) has no "neck" key at all.
	_neck = pivots.get("neck")
	_head = pivots["head"]
	_head_look_yaw = 0.0
	_head_look_pitch = 0.0
	_eyes = pivots["eyes"]
	_hips = pivots["hips"]
	_hips_rest_y = _hips.position.y
	_hand_right = pivots["hand_right"]
	_hand_left = pivots["hand_left"]
	_palm_right = pivots["palm_right"]
	_palm_left = pivots["palm_left"]
	_toe_right = pivots["toe_right"]
	_toe_left = pivots["toe_left"]


## The pivot-name map BlorbSuitController.setup() expects, built from
## whichever rig's own pivots dict is currently live -- both ProceduralFigure
## and MonkeyFigure export the same key set (see each one's own build()), so
## this works unchanged for either rig.
func _blorb_suit_pivot_map(pivots: Dictionary) -> Dictionary:
	return {
		"arm_left_shoulder": pivots["arm_left"], "arm_left_elbow": pivots["elbow_left"],
		"arm_right_shoulder": pivots["arm_right"], "arm_right_elbow": pivots["elbow_right"],
		"leg_left_hip": pivots["leg_left"], "leg_left_knee": pivots["knee_left"], "leg_left_ankle": pivots["ankle_left"],
		"leg_right_hip": pivots["leg_right"], "leg_right_knee": pivots["knee_right"], "leg_right_ankle": pivots["ankle_right"],
		"spine": pivots["spine"], "head": pivots["head"],
		"back_left": pivots["back_left"], "back_right": pivots["back_right"],
		"wrist_left": pivots["wrist_left"], "wrist_right": pivots["wrist_right"],
		"fingertip_left": pivots["fingertip_left"], "fingertip_right": pivots["fingertip_right"],
		"toe_left": pivots["toe_left"], "toe_right": pivots["toe_right"],
	}


## Local camera_rig offset/spring length -- the monkey's much smaller scale
## needs its own much closer framing than the human's. Not routed through
## _update_possession_camera() (that one's reserved for Blorbus/the giant,
## which drive a separate body camera_rig has to chase in world space);
## piloting Xiao Hou Zi keeps camera_rig local to this CharacterBody like
## ordinary human control does, just with different numbers.
func _apply_camera_framing(as_monkey: bool) -> void:
	camera_rig.position.y = TEMP_MONKEY_CAMERA_HEIGHT if as_monkey else 1.6
	camera_spring_arm.spring_length = TEMP_MONKEY_CAMERA_DISTANCE if as_monkey else 3.5


## 1.0 (the human rig's own native scale, and what every ProceduralFigure-
## derived formula in blorb_suit.gd is natively written in terms of) unless
## actually piloting Xiao Hou Zi with CheatCodes.enabled off, in which case
## it's MonkeyFigure.BLORB_SUIT_RIG_SCALE -- the one value both
## _blorb_suit.setup() call sites below (and _apply_blorb_suit_rig_scale())
## feed through so the suit fits whichever rig is actually worn. See
## cheat_codes.gd's own class doc comment for the cheat itself: entering the
## Konami Code brings back the original comically-oversized-on-him look as
## an easter egg, on top of whatever else CheatCodes.enabled unlocks in the
## future.
func _current_blorb_suit_rig_scale() -> float:
	if _piloting_xiao_hou_zi and not CheatCodes.enabled:
		return MonkeyFigure.BLORB_SUIT_RIG_SCALE
	return 1.0


## Re-applies BlorbSuitController's own rig_scale without rebuilding the
## visible rig or touching which slots are worn -- called whenever
## CheatCodes.enabled toggles (see the _ready() connection to CheatCodes.
## toggled below), so a suit already worn on Xiao Hou Zi visibly resizes the
## instant the Konami Code lands instead of waiting for the next possession
## swap or a fresh equip.
func _apply_blorb_suit_rig_scale() -> void:
	_blorb_suit.setup(self, visuals, _blorb_suit_pivot_map(_visuals_pivots), _current_blorb_suit_rig_scale())


## Swaps the visible rig live, mid-game -- the core of possessing Xiao Hou
## Zi (see _try_start_xiao_hou_zi_control()/_end_xiao_hou_zi_control()).
## Frees whichever rig root _build_pivots() previously parented under
## `visuals`, builds the other one in its place, and re-points every pivot
## var (including BlorbSuitController's own copies via re-setup()) at the
## new rig -- worn blorb tubes and held items re-loft onto it automatically
## next frame, the same live-reloft pass they already run every frame.
func _rebuild_visuals_rig(as_monkey: bool) -> void:
	var old_rig := visuals.get_node_or_null("MonkeyFigure")
	if old_rig == null:
		old_rig = visuals.get_node_or_null("ProceduralFigure")
	if old_rig != null:
		old_rig.free()
	var pivots := _build_pivots(as_monkey)
	_apply_pivots(pivots)
	_visuals_pivots = pivots
	_blorb_suit.setup(self, visuals, _blorb_suit_pivot_map(pivots), _current_blorb_suit_rig_scale())
	_apply_camera_framing(as_monkey)


const HELD_ITEM_SCALE := 0.6
# Held items are parented to ProceduralFigure.build()'s palm_right -- a
# point sitting right on the hand's own palm surface (see that function's
# own PalmAttach comment), not the hand's center -- so a held item rests
# against the palm instead of sitting buried inside the hand volume.
#
# A build_visual() Node3D can additionally define its own child named
# "GripPoint" (see _on_held_item_changed()) marking roughly where on ITS
# OWN surface it should meet the palm -- ShopCatalog._build_gem_visual()
# and NatureProps.build_fruit_visual() both do this now. HELD_ITEM_
# LOCAL_OFFSET is the fallback for anything that doesn't (the antique/red/
# green shop props, still using this as a first pass -- not visually
# verified in-engine, see the figure-rig skill's guidance on flagging
# unverified placement) -- AND, always, an outward nudge added on top of
# GripPoint's own alignment: GripPoint only pins down whichever single
# axis its own offset actually varies (e.g. the gem's is Y-only, its
# bottom point), leaving the other two axes centered exactly ON the palm
# surface -- straddling it, half embedded, rather than resting on top of
# it. This pushes everything a bit further along the palm's own confirmed
# outward-facing axis (see PalmAttach's own comment in procedural_figure.
# gd for how +Z was confirmed, not guessed, as that direction).
const HELD_ITEM_LOCAL_OFFSET := Vector3(0, 0, 0.02)
const THROW_SPEED := 14.0
const THROW_LOFT := 2.0
const THROW_SPAWN_DISTANCE := 0.6


func _ready() -> void:
	# Hud (an autoload, not a scene sibling like blorb.gd's own "../Player")
	# has no relative path to reach this node -- the wild-blorb direction
	# hint looks it up by group instead (see hud.gd's _find_player()).
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# global_position.y is deliberately kept FOOT_OFFSET above the terrain
	# snap height (see that const's own comment -- needed so is_on_floor()
	# doesn't read as constantly falling), but Visuals has no offset of its
	# own to compensate, so the rendered rig's feet (built assuming local
	# y=0 IS ground level -- see procedural_figure.gd) floated at that same
	# small physics lift instead of sitting flush with the visible ground.
	# Shifting Visuals down by exactly FOOT_OFFSET cancels it back out for
	# rendering only; the collision capsule (a separate sibling node) keeps
	# its own real lift untouched.
	visuals.position.y = -FOOT_OFFSET

	# _piloting_xiao_hou_zi: camera reframed for the monkey's much
	# smaller scale (see TEMP_MONKEY_CAMERA_HEIGHT/DISTANCE's own comments).
	# The debug jungle-plateau spawn teleport used while iterating on the
	# rig has been removed -- the game now starts focused on the player at
	# the normal main.tscn placement, same as always. Always false at
	# startup in practice (possession only flips it later, at runtime), but
	# routed through the same _apply_camera_framing() helper possession
	# start/end use, so a future default-as-monkey debug session would still
	# frame correctly.
	_apply_camera_framing(_piloting_xiao_hou_zi)

	var pivots := _build_pivots(_piloting_xiao_hou_zi)
	_apply_pivots(pivots)
	_visuals_pivots = pivots
	_build_water_streams()
	_roll_idle_pose()
	HeldItem.changed.connect(_on_held_item_changed)
	# Reacts the instant the Konami Code lands (see cheat_codes.gd's own class
	# doc comment) rather than polling CheatCodes.enabled every frame -- a
	# suit already worn on Xiao Hou Zi visibly resizes right away instead of
	# waiting for the next possession swap or a fresh equip.
	CheatCodes.toggled.connect(_on_cheats_toggled)

	# `visuals` (not `rig`) is the blorb suit's stable reference frame for
	# its limb tubes -- see blorb_suit.gd's own rebuild_arm/rebuild_leg --
	# since it's only ever yawed to face travel direction, never itself
	# bent by any single joint the way spine/head/a limb pivot are. Always
	# 1.0 in practice here (_piloting_xiao_hou_zi is always false this early
	# at startup), but routed through _current_blorb_suit_rig_scale() anyway
	# for the same future-default-as-monkey reasoning _apply_camera_framing()
	# above already documents.
	_blorb_suit.setup(self, visuals, _blorb_suit_pivot_map(pivots), _current_blorb_suit_rig_scale())
	# Deferred, not called directly here -- sibling Blorb nodes' own _ready()
	# (which is what actually adds each one to the "blorbs" group
	# auto_assign_new_members() scans) isn't guaranteed to have already run
	# by the time THIS node's _ready() reaches this line, so calling it
	# directly here risks scanning an empty/incomplete group. Deferring
	# runs it after every node's _ready() for this frame has already
	# finished -- the standard fix for exactly this ordering hazard.
	_blorb_suit.auto_assign_new_members.call_deferred()

	# Safe to build directly here (unlike the old capture-rig approach this
	# replaced), not deferred or off-tree -- _ready() only ever runs once
	# this node is already live in the tree, so `visuals` and its meshes
	# (built by build_portrait_body() above) are already real and properly
	# positioned by this point.
	_portrait.setup(self, visuals)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# The OS warps the cursor to center on capture, which can report as one
		# large spurious motion event; skip it so the camera doesn't snap.
		if _skip_next_mouse_motion:
			_skip_next_mouse_motion = false
		else:
			_rotate_camera(
				-event.relative.x * mouse_sensitivity, -event.relative.y * mouse_sensitivity
			)
	# "pause" itself is no longer handled here -- pause_menu.gd owns opening/
	# closing on that action now, via the same UIState.push_modal()/
	# pop_modal() every other modal (Dialog/Shop/Inventory) already uses to
	# free/recapture the mouse, rather than this script toggling mouse_mode
	# directly.


func _physics_process(delta: float) -> void:
	_lava_warning_cooldown = maxf(_lava_warning_cooldown - delta, 0.0)
	_apply_gamepad_look(delta)
	if Input.is_action_just_pressed("switch_blorbus") and not UIState.modal_open and not _player_following_manchego:
		_toggle_blorbus_control()
	if _player_following_manchego:
		_update_manchego_control(delta)
		return
	if _player_following_blorbus:
		_update_blorbus_control(delta)
		return

	# Tracked every frame, not just while grounded (where the ordinary jump
	# input below is read) -- a press timed for a blorb bounce can happen
	# while still airborne, and would otherwise be silently dropped.
	# A modal owns the controller: movement/jump must not leak through while
	# the same stick and face buttons are navigating dialog responses.
	var jump_pressed := Input.is_action_just_pressed("jump") and not UIState.modal_open
	if jump_pressed:
		_jump_buffer_timer = BLORB_SUPER_JUMP_BUFFER
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	# The other half of the bounce's timing forgiveness -- see
	# BLORB_SUPER_JUMP_GRACE_WINDOW's own comment.
	if _blorb_super_jump_grace > 0.0:
		if jump_pressed:
			_apply_blorb_bounce_velocity(true)
			_blorb_super_jump_grace = 0.0
		else:
			_blorb_super_jump_grace = maxf(_blorb_super_jump_grace - delta, 0.0)

	_update_giant_goo_state(delta)
	_update_lake_buoyancy(delta)
	_update_air_flight()
	_update_limb_power_state(delta)
	_update_suit_flight_transition()
	var powered_hover := _is_powered_hover_active()
	var suit_flight := _is_suit_flight_active()
	var buoyant := _giant_goo_active or _lake_buoyancy_active or suit_flight or powered_hover
	var surface_walking := _lake_water_walk_active
	var giant_jump_ready := _giant_surface_grounded or _is_on_giant_mesh_surface()

	# FOOT_OFFSET keeps the character's collision volume a hair above the
	# analytic snap height, so it isn't always in continuous contact with the
	# real mesh collision below -- is_on_floor() alone would say "falling"
	# even while walking normally. _is_touching_terrain() covers that case
	# for gravity/jump too.
	#
	# _jumping has to persist for the whole arc, not just the input frame:
	# one frame after leaving the ground, the character is still within the
	# lenient "touching terrain" height threshold, so without this flag
	# _try_step_up()/_snap_to_terrain() would immediately zero velocity.y
	# again and cancel the jump almost before it starts.
	# _is_touching_terrain()'s loose 3m-of-analytic-ground proximity check
	# only stands in for real contact while GROUNDED_GRACE_DURATION-recently
	# touching real ground (_grounded_grace_timer) -- it's what lets
	# ordinary ground-following tolerate is_on_floor() flickering over
	# terrain's own bumps for a frame or two. During a genuine fall (walked
	# off a ledge, not just an active jump -- see _jumping's own narrower
	# scope) it must NOT fire on its own once that grace period runs out: an
	# elevated platform under 3m (a roof, an upper floor, a rock) sitting
	# between the player and true ground would otherwise get treated as
	# "close enough to snap to the ground," landing the player through it.
	# _is_near_ground()'s much tighter 0.3m band is still trusted
	# unconditionally, same as _jumping's own clear condition below --
	# nothing standable is that short.
	#
	# The grace timer itself (not a bare _prev_grounded bool, which never
	# expires on its own -- see its own doc comment for the bug that caused)
	# is refreshed from real contact, not from `grounded` itself, so it can't
	# perpetuate past however long is_on_floor() actually stays true plus
	# GROUNDED_GRACE_DURATION's own short tail.
	if is_on_floor():
		_grounded_grace_timer = GROUNDED_GRACE_DURATION
	else:
		_grounded_grace_timer = maxf(_grounded_grace_timer - delta, 0.0)

	# Ramps use TownProps' dedicated climbable layer. Treat a downward hit on
	# that layer as genuine ground, but never run the terrain/prop auto-step
	# helpers against it -- those helpers pre-lift and re-snap Y for discrete
	# ledges, which makes a continuous slope look like repeated tiny jumps.
	var on_climbable_ramp := _is_on_climbable_ramp()
	var cloud_stand_height: Variant = _cloud_stand_height_at(global_position.x, global_position.z, global_position.y - FOOT_OFFSET + 0.2)
	# 0.6, not the tighter 0.25 on_canopy uses right below -- a cloud top is
	# several overlapping puffs (see cloud_scatter.gd's own get_support_
	# height_at()), so its real walkable height can shift noticeably from
	# one step to the next near a puff's edge or where two puffs hand off to
	# each other, unlike a single solid canopy/terrain surface. Per direct
	# correction ("not really able to reliably stand on top of the
	# clouds... hopping onto the top surface often just makes you totally
	# fall through") -- see _snap_to_cloud() below for the other half of
	# this fix (actively re-anchoring to that shifting height every frame,
	# the same way _snap_to_terrain() already does for solid ground).
	var on_cloud := cloud_stand_height != null and absf(global_position.y - (cloud_stand_height as float)) < 0.6 and velocity.y <= 0.1
	# Same pattern as on_cloud immediately above, just against tree-canopy
	# support instead. Without this, standing on a canopy never counted as
	# grounded -- the one-way Y catch further down (see
	# _tree_canopy_stand_height_at()) still landed the player, but with
	# `grounded` staying false, movement kept using aerial/momentum-driven
	# horizontal control rather than switching to ordinary walk-speed input,
	# so any residual horizontal velocity carried the player straight across
	# and off a canopy's small, domed footprint within a frame or two --
	# reading as "lands for a moment, then keeps falling."
	var canopy_stand_height: Variant = _tree_canopy_stand_height_at(global_position.x, global_position.z, global_position.y - FOOT_OFFSET + 0.2)
	var on_canopy := canopy_stand_height != null and absf(global_position.y - (canopy_stand_height as float)) < 0.25 and velocity.y <= 0.1
	var grounded := (_giant_surface_grounded or surface_walking or on_climbable_ramp or (
		is_on_floor() or _is_near_ground() or (_is_touching_terrain() and _grounded_grace_timer > 0.0)
	) or on_cloud or on_canopy) and not _jumping
	if suit_flight or powered_hover:
		grounded = false
	# grounded is fixed at the top of the frame, before the jump decision
	# below -- so on the exact frame a jump starts, it's still stale-true
	# and would otherwise let the step-up/snap calls further down cancel
	# the jump velocity they just set. This one-frame guard covers that.
	var jumped_this_frame := false

	if not grounded and not buoyant:
		velocity.y = maxf(velocity.y - gravity * JUMP_GRAVITY_SCALE * delta, -TERMINAL_FALL_SPEED)
	elif jump_pressed and _giant_goo_active and not giant_jump_ready:
		# Goo is buoyant, not a fallable jump arc: pressing Jump while inside
		# it becomes a temporary fast upward swim toward the surface.
		_giant_goo_jump_lift_timer = GIANT_GOO_JUMP_LIFT_DURATION
		velocity.y = 0.0
		_jumping = false
	elif jump_pressed:
		var jump_height_multiplier := GIANT_SUPER_JUMP_HEIGHT_MULTIPLIER if giant_jump_ready else 1.0
		if _lake_buoyancy_active and not _lake_diving_active:
			jump_height_multiplier = WATER_EXIT_JUMP_HEIGHT_MULTIPLIER
		var jump_speed_scale := TEMP_MONKEY_JUMP_MULTIPLIER if _piloting_xiao_hou_zi else 1.0
		velocity.y = jump_velocity * jump_speed_scale * sqrt(jump_height_multiplier)
		_jump_takeoff_speed = absf(velocity.y)
		_giant_surface_jump_in_progress = giant_jump_ready
		_jumping = true
		jumped_this_frame = true

	var input_dir := _get_move_input()
	_aerial_motion_direction = Vector3.ZERO
	_aerial_strafe_input = 0.0
	# On land movement stays yaw-only. Inside a head-blorb dive, use the
	# pitched camera basis so looking up/down and swimming forward controls
	# ascent/descent naturally.
	var aerial_active := _lake_diving_active or suit_flight
	# Surface swimming keeps ordinary horizontal controls, but its body still
	# needs the same neck-led travel lean as diving.
	var neck_led_travel := _lake_buoyancy_active or suit_flight
	var cam_basis := camera.global_transform.basis if aerial_active else camera_rig.global_transform.basis
	var direction := cam_basis.x * input_dir.x + cam_basis.z * input_dir.y
	if not aerial_active:
		direction.y = 0.0

	var skating := _is_blorb_skating()
	var ground_move_speed := TEMP_MONKEY_MOVE_SPEED if _piloting_xiao_hou_zi else move_speed
	var current_speed := ground_move_speed * (sprint_multiplier if _is_sprinting() else 1.0)
	if _lake_diving_active:
		current_speed = LAKE_DIVE_SPEED
	elif _air_flight_active or _fire_limb_flight_active:
		current_speed = AIR_FLIGHT_SPEED
	# Air feet retain ordinary walk/run traversal speed and animation even
	# though their direction includes camera pitch (see _animate_walk()).
	if aerial_active and _is_sprinting():
		if _air_flight_active or _fire_limb_flight_active:
			current_speed *= FLIGHT_SPRINT_SPEED_MULTIPLIER
		elif _lake_diving_active:
			current_speed *= AERIAL_FAST_SPEED_MULTIPLIER
	if _air_flight_active:
		var active_fire_feet := int(_left_leg_fire_active) + int(_right_leg_fire_active)
		current_speed *= pow(FIRE_FOOT_FLIGHT_SPEED_MULTIPLIER, active_fire_feet)
	if skating and not aerial_active and not powered_hover:
		current_speed *= BLORB_SKATE_SPEED_MULTIPLIER

	if direction.length() > 0.001:
		direction = direction.normalized()
		if neck_led_travel:
			_aerial_motion_direction = direction
			_aerial_strafe_input = input_dir.x
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		if neck_led_travel:
			velocity.y = direction.y * current_speed
		var target_angle := atan2(direction.x, direction.z)
		if neck_led_travel:
			# All three visual axes must be applied inside the skull-anchored
			# pass below. Applying yaw here would still rotate around the feet.
			_aerial_target_yaw = target_angle
		else:
			visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		velocity.z = move_toward(velocity.z, 0.0, current_speed)
		if aerial_active:
			velocity.y = move_toward(velocity.y, 0.0, current_speed)

	# Water-leg and dual-hand Fire hover are level traversal modes: their
	# camera-relative direction has no Y component, so the jets own vertical
	# lift. Air feet and four-limb Fire flight instead use camera-pitched
	# direction above; with no input they hold the last elevation here.
	_apply_powered_hover_vertical(delta, direction.length() > 0.001 and aerial_active)

	_animate_walk(delta, grounded, BLORB_SKATE_SPEED_MULTIPLIER if skating and not powered_hover else 1.0)
	# Flight aiming is applied after the base pose but before the dedicated
	# shoulder-button power layer, so a held arm power still has precedence.
	_apply_flight_aim_pose(delta)
	# Called directly after _animate_walk (which also covers idle/airborne/
	# landing -- see that function's own branches), not from _process, per
	# direct instruction that the raised-arm pose must override the walk/
	# run/jump swing cycle unconditionally. Relying on _process running
	# after physics (as an earlier version did) is technically true, but
	# puts a whole callback boundary between "the swing cycle sets a
	# value" and "the pose overrides it" -- calling this right here instead
	# collapses that gap to zero, so there's no ordering assumption left to
	# get wrong.
	_apply_arm_power_poses(delta)
	_apply_fire_jet_pose(delta)
	_update_water_streams(delta)

	if grounded and not surface_walking and not on_climbable_ramp and not jumped_this_frame and not buoyant and not _giant_surface_grounded and _is_touching_terrain():
		_try_step_up()
	# Not gated behind _is_touching_terrain() the way _try_step_up() is --
	# that check is specifically "close to the analytic ground function,"
	# which a slab's own raised surface has nothing to do with; grounded
	# and not jumped_this_frame alone (the same "don't fight an active
	# jump" guard every other step/snap call here uses) is what actually
	# matters for this one.
	if grounded and not surface_walking and not on_climbable_ramp and not jumped_this_frame and not buoyant and not _giant_surface_grounded:
		_try_step_onto_prop()
	var pre_move_feet_y := global_position.y - FOOT_OFFSET
	move_and_slide()
	_enforce_lava_access()
	# Clouds are intentionally one-way: only a descending body that started
	# above a puff top is caught. Rising flight/jumps pass straight through
	# the underside, then a fall settles 10cm into the cloud.
	#
	# Deliberately NOT gated on the full `buoyant` flag -- that also covers
	# _air_flight_active, and air flight is the only realistic way to reach
	# tree-canopy height at all (an ordinary jump only clears about 1.3m,
	# nowhere near a 10m+ canopy) and has no manual toggle to drop out of
	# mid-air (see _update_air_flight()'s own doc comment: equipping the
	# chest air blorb is what turns flight on/off). Gating this on `buoyant`
	# meant a flying player descending onto a cloud or canopy could never be
	# caught by either, silently making both unreachable in practice. Goo/
	# lake buoyancy stay excluded below -- those are submersion states, not
	# a "falling" descent this one-way catch should react to.
	var descending_through_air := not (_giant_goo_active or _lake_buoyancy_active) and velocity.y <= 0.0
	if descending_through_air:
		var cloud_landing_height: Variant = _cloud_stand_height_at(global_position.x, global_position.z, pre_move_feet_y + 0.02)
		var cloud_feet_height := (cloud_landing_height as float) - FOOT_OFFSET if cloud_landing_height != null else 0.0
		if cloud_landing_height != null and pre_move_feet_y >= cloud_feet_height and global_position.y - FOOT_OFFSET <= cloud_feet_height:
			global_position.y = cloud_landing_height as float
			velocity.y = 0.0
		# Tree canopies (round/pine/palm/banana/banyan/baobab foliage) are
		# the same kind of one-way support as clouds above -- walkable
		# underneath and through the sides, landable only when already above
		# the leaf mass and descending onto it. See
		# NatureProps._add_canopy_blob() and
		# WildernessScatter.get_support_height_at().
		var canopy_landing_height: Variant = _tree_canopy_stand_height_at(global_position.x, global_position.z, pre_move_feet_y + 0.02)
		var canopy_feet_height := (canopy_landing_height as float) - FOOT_OFFSET if canopy_landing_height != null else 0.0
		if canopy_landing_height != null and pre_move_feet_y >= canopy_feet_height and global_position.y - FOOT_OFFSET <= canopy_feet_height:
			global_position.y = canopy_landing_height as float
			velocity.y = 0.0
	# Movement is resolved by the collision body, then the visual rig is
	# tilted around the head/neck junction. This order keeps the skull anchor
	# at the position that actually led this frame's swim rather than letting
	# a feet-pivoted mesh arc the head away from it.
	_update_aerial_body_anchor(delta)
	# Uses `grounded` as computed at the top of this frame (before this jump/
	# landing was resolved), same as the terrain step-up/snap calls around
	# it -- so this only ever fires while the frame started airborne, not on
	# every ground-level bump into a blorb's side.
	if not _check_rising_air_blorb_bounce(grounded):
		_check_creature_bounce(grounded, pre_move_feet_y)
	if grounded and not surface_walking and not on_climbable_ramp and not jumped_this_frame and not buoyant and not _giant_surface_grounded and _is_touching_terrain():
		_snap_to_terrain(delta)
	# Same active re-anchoring _snap_to_terrain() does for solid ground,
	# applied to a cloud top instead -- see on_cloud's own comment above for
	# why a cloud's own bumpy, multi-puff surface needs this (a loose
	# proximity tolerance alone let the player's foothold height and the
	# cloud's own real height under them drift apart while walking, reading
	# as falling through).
	if grounded and on_cloud and not surface_walking and not jumped_this_frame and not buoyant and not _giant_surface_grounded:
		_snap_to_cloud(delta)
	_store_giant_attachment()

	# _is_near_ground() alone only ever fires near the analytic terrain
	# height, so landing on anything elevated -- the fountain rim, a stall
	# counter, a building floor -- never satisfied it, leaving _jumping
	# stuck true forever and permanently blocking grounded (see its "and not
	# _jumping" above), which silently disabled jumping again from up there.
	# is_on_floor() covers that: it's real collision contact, so it fires
	# the instant the character actually lands on anything solid, elevated
	# platform or not.
	if _jumping and velocity.y <= 0.0 and (is_on_floor() or _is_near_ground() or _giant_surface_grounded):
		_jumping = false
		_giant_surface_jump_in_progress = false

	# Edge-detected off the same `grounded` _animate_walk already receives
	# (not a fresh is_on_floor() check), so it fires exactly when the walk
	# animation itself starts treating the character as grounded again --
	# grounded stays false for one extra frame right at touchdown (it was
	# computed above, before _jumping just cleared), so this actually fires
	# one frame after the true physical landing. Imperceptible for a "split
	# second" reaction, and simpler than a second, separately-timed check.
	if grounded and not _prev_grounded:
		_landing_timer = LANDING_DURATION
		_walk_cycle_recovery = 0.0
	_prev_grounded = grounded


## Lava is traversable terrain only with two fully worn fire blorbs on the
## legs. A high jump/flight may pass over it; contact without the complete
## pair returns the player to the nearest solid edge. The same rule catches
## removing either leg while already standing out in the pool.
func _enforce_lava_access() -> void:
	if (
		terrain == null
		or not terrain.has_method("is_lava_area")
		or not terrain.has_method("get_lava_surface_height")
		or not terrain.has_method("get_lava_escape_position")
	):
		return
	var xz := Vector2(global_position.x, global_position.z)
	if not terrain.is_lava_area(xz) or _blorb_suit.has_lava_safe_legs():
		return
	var lava_surface: float = terrain.get_lava_surface_height(xz)
	if global_position.y - FOOT_OFFSET > lava_surface + LAVA_CONTACT_TOLERANCE:
		return
	var safe_position: Vector3 = terrain.get_lava_escape_position(xz)
	global_position = safe_position + Vector3.UP * FOOT_OFFSET
	velocity = Vector3.ZERO
	_jumping = false
	if _lava_warning_cooldown <= 0.0:
		# Plain reaction, not an explanation of the requirement -- see
		# CLAUDE.md's "In-game text and player guidance" rule.
		Hud.show_message("The heat drives you back.")
		_lava_warning_cooldown = LAVA_WARNING_COOLDOWN


## Detects landing on top of a blorb via this frame's move_and_slide()
## collisions, rather than a distance/height check like the terrain snap
## uses -- a blorb can be standing (or gliding) anywhere, so there's no
## single fixed spot to test against the way terrain height works.
func _check_creature_bounce(was_grounded: bool, pre_move_feet_y: float) -> void:
	if was_grounded:
		return
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if not collider is Node or collision.get_normal().y <= BLORB_BOUNCE_NORMAL_MIN:
			continue
		var creature := collider as Node
		if creature.is_in_group("blorbs"):
			var blorb := creature as Blorb
			var blorb_surface: Variant = blorb.bounce_surface_height_at(global_position.x, global_position.z)
			if blorb_surface != null:
				global_position.y = (blorb_surface as float) + FOOT_OFFSET
				_bounce_off_blorb(blorb)
				return
		elif creature.is_in_group("npcs") and creature.has_method("head_bounce_surface_height_at"):
			var npc_surface: Variant = creature.head_bounce_surface_height_at(global_position.x, global_position.z)
			if npc_surface != null:
				global_position.y = (npc_surface as float) + FOOT_OFFSET
				_bounce_off_blorb(creature)
				return
	# The slide-collision list above misses landings the same way it does for
	# the rising air blorb below: falling fast enough to cross a curved goo
	# crown in one physics step can skip reporting any collision at all, and
	# even when it does report one, a landing near the crown's edge can have
	# a normal shallow enough to fail BLORB_BOUNCE_NORMAL_MIN even though the
	# player visibly landed on top. Per direct report, this was making blorb
	# bounces choppy -- landing would sometimes just silently fail to launch,
	# leaving the player resting on the blorb's head (real collision holding
	# them up) and the blorb still visibly squashed from its own idle/hop
	# state. A geometric crossing check, mirroring the cloud/canopy catch
	# above and _check_rising_air_blorb_bounce below, catches exactly the
	# cases the collision list misses.
	if velocity.y > 0.1:
		return
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not candidate is Blorb:
			continue
		var blorb := candidate as Blorb
		var blorb_surface: Variant = blorb.bounce_surface_height_at(global_position.x, global_position.z)
		if blorb_surface == null:
			continue
		var surface_y := blorb_surface as float
		if pre_move_feet_y >= surface_y and global_position.y - FOOT_OFFSET <= surface_y:
			global_position.y = surface_y + FOOT_OFFSET
			_bounce_off_blorb(blorb)
			return


## A hovering air blorb is a manually moved StaticBody3D. When it rises into
## nearly stationary feet, Godot can resolve the overlap without reporting a
## slide collision; detect that narrow top-contact case geometrically so the
## player visibly meets the crown and enters the normal trampoline bounce.
func _check_rising_air_blorb_bounce(was_grounded: bool) -> bool:
	if was_grounded or velocity.y > 0.1 or _is_suit_flight_active() or _is_powered_hover_active():
		return false
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not candidate is Blorb:
			continue
		var blorb := candidate as Blorb
		if blorb.element_state != "air" or blorb.is_worn:
			continue
		var surface: Variant = blorb.bounce_surface_height_at(global_position.x, global_position.z)
		if surface == null:
			continue
		var contact_y := surface as float
		var feet_gap := global_position.y - contact_y
		if feet_gap >= -0.04 and feet_gap <= 0.08:
			# Resolve the visual contact before launching. This removes the old
			# hovering gap while retaining the existing squash/bounce response.
			global_position.y = contact_y + FOOT_OFFSET
			_bounce_off_blorb(blorb)
			return true
	return false


## Launches the player back into the jump arc instead of settling, using the
## same _jumping/_landing_timer machinery an ordinary jump/landing already
## drives -- velocity.y staying positive here is what keeps `grounded` false
## afterward (see its "and not _jumping" condition above), so the very next
## frame's animation falls through to the impact crouch and then the
## airborne pose exactly like a real jump would.
func _bounce_off_blorb(blorb: Node) -> void:
	var super_jump := _jump_buffer_timer > 0.0
	_jump_buffer_timer = 0.0
	_apply_blorb_bounce_velocity(super_jump)
	_jumping = true
	_landing_timer = LANDING_DURATION
	_walk_cycle_recovery = 0.0
	if blorb.has_method("trigger_bounce_squash"):
		blorb.trigger_bounce_squash()
	# An ordinary bounce still leaves a short window open for a late press
	# to upgrade it -- see BLORB_SUPER_JUMP_GRACE_WINDOW's own comment. A
	# same-frame-or-earlier super jump has nothing left to upgrade.
	_blorb_super_jump_grace = 0.0 if super_jump else BLORB_SUPER_JUMP_GRACE_WINDOW


func _apply_blorb_bounce_velocity(super_jump: bool) -> void:
	var height_multiplier := SUPER_JUMP_HEIGHT_MULTIPLIER if super_jump else 1.0
	var jump_speed_scale := TEMP_MONKEY_JUMP_MULTIPLIER if _piloting_xiao_hou_zi else 1.0
	velocity.y = jump_velocity * jump_speed_scale * sqrt(height_multiplier)
	_jump_takeoff_speed = absf(velocity.y)


## Whether the player is currently airborne (jumping or falling) rather than
## standing/walking on solid ground -- exposed for blorb.gd's player-push
## behavior, which per direct instruction should be much weaker while the
## player's mid-air (e.g. trying to land on top of a blorb for the
## trampoline bounce) than while just walking into one on the ground.
func is_airborne() -> bool:
	return _jumping


func is_air_flight_active() -> bool:
	return _is_suit_flight_active()


## _piloting_xiao_hou_zi early-return: per direct instruction, Xiao Hou Zi
## has no damage/HP concept of his own at all (xiao_hou_zi.gd carries none),
## and reskinning this CharacterBody as him (see that var's own doc comment)
## shouldn't let skeleton attacks reach through to the human's HP pool while
## he's the one on screen taking the punches.
func take_damage(amount: float) -> void:
	if amount <= 0.0 or _piloting_xiao_hou_zi:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_hp_regen_delay = HP_REGEN_DELAY
	hp_changed.emit(current_hp, MAX_HP)


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	var before := current_hp
	current_hp = minf(current_hp + amount, MAX_HP)
	if current_hp != before:
		hp_changed.emit(current_hp, MAX_HP)


func _update_hp_regen(delta: float) -> void:
	_hp_regen_delay = maxf(_hp_regen_delay - delta, 0.0)
	if _hp_regen_delay <= 0.0 and current_hp < MAX_HP:
		current_hp = minf(current_hp + HP_REGEN_PER_SECOND * delta, MAX_HP)
		hp_changed.emit(current_hp, MAX_HP)


func _process(delta: float) -> void:
	# SpringArm3D resolves its own child position as part of the engine's
	# physics step, at a point that runs after _physics_process -- clamping
	# there got silently overwritten every frame. _process() runs after all
	# physics processing for the frame, right before rendering, so this is
	# the last word on camera position each frame.
	_update_possession_camera()
	_clamp_camera_above_ground()
	_update_head_look(delta)
	if not _player_following_blorbus and not _player_following_manchego:
		_update_throw_input()
	_update_suit_input(delta)
	_update_hp_regen(delta)
	EyeBlink.apply(_eye_blink, delta, _eyes)
	# _piloting_xiao_hou_zi: re-loft the monkey's limb tubes from the
	# (already-animated-this-frame) pivots' live global_position, the same
	# per-frame noodle-rebuild pattern BlorbSuitController uses for worn
	# blorb limbs -- see monkey_figure.gd's own rebuild_limbs().
	if _piloting_xiao_hou_zi:
		MonkeyFigure.rebuild_limbs(_monkey_pivots, visuals, delta)


func _toggle_blorbus_control() -> void:
	if _piloting_xiao_hou_zi:
		# Xiao Hou Zi is the last stop in the cycle -- one more press returns
		# control to the human player.
		_end_xiao_hou_zi_control()
		return
	if _player_following_blorbus:
		# Currently piloting Blorbus (or the giant he merged into) -- advance to
		# Xiao Hou Zi if he's joined the party, otherwise this press just ends
		# possession same as the old two-state toggle did.
		if not _try_start_xiao_hou_zi_control():
			_end_blorbus_control()
		return
	if _try_start_blorbus_control():
		return
	if _try_start_xiao_hou_zi_control():
		return
	Hud.show_message("Blorbus hasn't awakened yet.")


func _try_start_blorbus_control() -> bool:
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if candidate is Blorb and (candidate as Blorb).is_blorbus:
			var blorbus := candidate as Blorb
			if blorbus.is_melted:
				Hud.show_message("Blorbus is recovering.")
				return true
			if blorbus.is_worn:
				Hud.show_message("Blorbus can't switch while he is part of the blorb suit.")
				return true
			_controlled_blorbus = blorbus
			_controlled_blorbus.is_player_controlled = true
			_player_following_blorbus = true
			camera_rig.top_level = true
			Hud.show_message("You are now controlling Blorbus.")
			return true
	return false


## Possesses Xiao Hou Zi by reskinning THIS CharacterBody as him, rather than
## driving a separate NPC body the way _try_start_blorbus_control() does --
## see _piloting_xiao_hou_zi's own doc comment at the top of the file for
## why: it's what makes swimming, flight, and the blorb suit work for him
## for free, unmodified. Neither body moves at all when control switches
## (per direct correction -- "both the player character and Xiao Hou Zi
## should keep their existing position throughout any switches, just as
## blorbus and the player do"): this CharacterBody stays exactly where it's
## standing, and the standalone NPC likewise stays exactly where it's
## standing and just reskins AS the human in place (see begin_possession()),
## then keeps running its own independent AI, which -- since he's already
## in_party by now -- makes him idle in place and then trail after this
## CharacterBody exactly like an ordinary recruited party member. So the
## human never disappears, he just switches from directly controlled to
## AI-followed, mirroring what this CharacterBody itself already does while
## the player is off piloting Blorbus (see _update_blorbus_control()) --
## same zero-teleport contract, just applied to both sides this time since
## there's no separate driven body to lean on.
func _try_start_xiao_hou_zi_control() -> bool:
	var monkey: XiaoHouZi = null
	for candidate in get_tree().get_nodes_in_group("xiao_hou_zi"):
		if candidate is XiaoHouZi and (candidate as XiaoHouZi).in_party:
			monkey = candidate as XiaoHouZi
			break
	if monkey == null:
		return false
	_release_blorbus_and_giant_possession()
	monkey.begin_possession()
	_controlled_xiao_hou_zi = monkey
	_piloting_xiao_hou_zi = true
	_rebuild_visuals_rig(true)
	Hud.show_message("You are now controlling Xiao Hou Zi.")
	return true


## Mirror of _end_blorbus_control(), but for the reskin-in-place possession
## _try_start_xiao_hou_zi_control() sets up rather than that function's
## separate-body one -- restores the human rig on this same CharacterBody
## right where it's standing, then reskins the NPC (which has been AI-
## following this CharacterBody the whole time, standing in as the human --
## see xiao_hou_zi.gd's own class doc comment) back to himself in place,
## resuming his independent roam/follow AI from wherever he ended up.
func _end_xiao_hou_zi_control() -> void:
	_piloting_xiao_hou_zi = false
	_rebuild_visuals_rig(false)
	if is_instance_valid(_controlled_xiao_hou_zi):
		_controlled_xiao_hou_zi.end_possession()
	_controlled_xiao_hou_zi = null
	Hud.show_message("You are now controlling the player.")


## Shared by _end_blorbus_control() (returning fully to the human) and
## _try_start_xiao_hou_zi_control() (advancing straight from Blorbus/the
## giant into Xiao Hou Zi without passing back through human control) --
## either way, a possessed giant/Blorbus needs to let go and Blorbus needs
## to physically re-emerge if he was merged and invisible.
func _release_blorbus_and_giant_possession() -> void:
	if is_instance_valid(_controlled_giant):
		_controlled_giant.is_player_controlled = false
		if is_instance_valid(_controlled_blorbus):
			var emerge_direction := global_position - _controlled_giant.global_position
			emerge_direction.y = 0.0
			if emerge_direction.length() < 0.01:
				emerge_direction = Vector3.FORWARD
			emerge_direction = emerge_direction.normalized()
			var emerge_radius := Blorb.RADIUS * _controlled_giant.size_multiplier + 1.0
			var emerge_pos := _controlled_giant.global_position + emerge_direction * emerge_radius
			emerge_pos.y = terrain.get_mesh_height(emerge_pos.x, emerge_pos.z)
			_controlled_blorbus.global_position = emerge_pos
			_controlled_blorbus.visible = true
	_controlled_giant = null
	if is_instance_valid(_controlled_blorbus):
		_controlled_blorbus.is_player_controlled = false
	_controlled_blorbus = null
	# _try_start_blorbus_control() detaches camera_rig from this CharacterBody
	# (top_level = true) so _update_blorbus_control() can freely drive its
	# global_position to follow whichever separate body is being piloted --
	# left on, that global_position (Blorbus/the giant's last tracked spot)
	# would keep the camera pinned there even once nothing is repositioning
	# it anymore. Re-attaching without zeroing position first would just
	# reinterpret that same stale global position as a local offset instead
	# (a bogus, often huge, one), so both have to be reset together. This
	# used to live only in _end_blorbus_control(), which covers returning to
	# the human -- but _try_start_xiao_hou_zi_control() also calls this
	# function when advancing straight from Blorbus into Xiao Hou Zi without
	# passing back through human control, and needs the exact same cleanup:
	# the player and Xiao Hou Zi's own bodies already stay exactly where they
	# were per the zero-teleport contract (see _try_start_xiao_hou_zi_control()
	# 's own doc comment), so the camera should too, snapping back onto
	# whichever body is now driving it (via _apply_camera_framing(), called
	# right after this by both callers) rather than lagging at Blorbus's old
	# spot.
	if camera_rig.top_level:
		camera_rig.top_level = false
		camera_rig.position = Vector3.ZERO


func _end_blorbus_control() -> void:
	_release_blorbus_and_giant_possession()
	_player_following_blorbus = false
	_apply_camera_framing(false)
	Hud.show_message("You are now controlling the player.")


## Entry point for manchego.gd's own "Ride Manchego" Interactable callback --
## unlike Blorbus/Xiao Hou Zi, mounting Manchego is never reached through the
## switch_blorbus cycle, so this is called directly with the specific
## instance the player just interacted with instead of searching a group.
## Releases whatever else might currently be possessed first (the human
## CharacterBody keeps existing/colliding even mid-possession -- see
## _release_blorbus_and_giant_possession()'s own doc comment -- so it's
## possible, if unlikely, to wander into Manchego's prompt while already
## piloting Blorbus or reskinned as Xiao Hou Zi).
func start_riding_manchego(manchego: Manchego) -> void:
	_release_blorbus_and_giant_possession()
	if _piloting_xiao_hou_zi:
		_end_xiao_hou_zi_control()
	_controlled_manchego = manchego
	_controlled_manchego.begin_ride()
	_player_following_manchego = true
	_manchego_dismount_armed = false
	camera_rig.top_level = true
	# Same top_level idiom camera_rig itself uses right above -- lets
	# _apply_manchego_seated_pose() drive `visuals` off Manchego's own live
	# seat transform directly every frame instead of this CharacterBody's
	# own position/rotation.y (which stays a loose, invisible-now follower;
	# see _update_manchego_control()'s own comment for why that's still kept
	# moving underneath).
	visuals.top_level = true
	# Plain state confirmation, matching every other control-switch message
	# in this file (e.g. "You are now controlling Blorbus.") -- none of them
	# spell out the control used to switch back; see CLAUDE.md's "In-game
	# text and player guidance" rule.
	Hud.show_message("Riding Manchego.")


func _end_manchego_control() -> void:
	if is_instance_valid(_controlled_manchego):
		_controlled_manchego.end_ride()
	_controlled_manchego = null
	_player_following_manchego = false
	_manchego_dismount_armed = false
	if camera_rig.top_level:
		camera_rig.top_level = false
		camera_rig.position = Vector3.ZERO
	if visuals.top_level:
		visuals.top_level = false
		# visuals' position/rotation held GLOBAL values a moment ago (that's
		# what top_level means) -- flipping top_level back off re-interprets
		# whatever numbers are already sitting in .transform as LOCAL
		# instead, so it has to be explicitly reset back to its ordinary
		# resting local transform here, or the figure would render wherever
		# those stale global numbers happen to land relative to this
		# CharacterBody. Matches _ready()'s own initial setup exactly.
		visuals.transform = Transform3D(Basis.IDENTITY, Vector3(0, -FOOT_OFFSET, 0))
	# _neck.rotation.x is otherwise ONLY ever touched by
	# _apply_manchego_seated_pose() (see MANCHEGO_HEAD_UPRIGHT_NECK_SHARE's
	# own comment) -- unlike every other pose pivot here, nothing in the
	# ordinary walk/idle/jump code eases it back to rest on its own, so it
	# has to be reset explicitly or it'd stay frozen at its last
	# riding-compensation value after dismounting.
	if _neck != null:
		_neck.rotation = Vector3.ZERO
	# Same reasoning as _neck above -- _elbow_left/_right.rotation.Z is only
	# ever touched by RIDE_ELBOW_INWARD (every OTHER elbow pose in this file
	# only ever animates rotation.x), so it needs the same explicit reset.
	_elbow_left.rotation.z = 0.0
	_elbow_right.rotation.z = 0.0
	_apply_camera_framing(false)
	Hud.show_message("You are now controlling the player.")


## Mirrors _update_blorbus_control() closely -- see that function's own
## comments for the follow-cadence/floor-snap reasoning this reuses
## verbatim. No jump input and no lake/cloud/canopy handling: Manchego is
## ground-only for this first pass (see manchego.gd's own drive_from_player()
## doc comment).
func _update_manchego_control(delta: float) -> void:
	if not is_instance_valid(_controlled_manchego):
		_end_manchego_control()
		return
	if not Input.is_action_pressed("interact"):
		_manchego_dismount_armed = true
	if _manchego_dismount_armed and Input.is_action_just_pressed("interact") and not UIState.modal_open:
		_end_manchego_control()
		return
	var input := _get_move_input()
	var basis := camera_rig.global_transform.basis
	var direction := basis.x * input.x + basis.z * input.y
	direction.y = 0.0
	if direction.length() > 0.001:
		direction = direction.normalized()
	# Same "jump" action the human's own ground jump reads (see
	# _physics_process()'s own jump_pressed line) -- safe to read again here
	# since this function only ever runs from the early-return branch of
	# _physics_process() that skips the human's own jump handling entirely
	# while _player_following_manchego is true.
	var jump_pressed := Input.is_action_just_pressed("jump") and not UIState.modal_open
	_controlled_manchego.drive_from_player(direction, delta, _is_sprinting(), jump_pressed)

	var offset := _controlled_manchego.global_position - global_position
	offset.y = 0.0
	if offset.length() > PLAYER_FOLLOW_DISTANCE:
		var follow_dir := offset.normalized()
		velocity.x = follow_dir.x * move_speed
		velocity.z = follow_dir.z * move_speed
	elif offset.length() < PLAYER_FOLLOW_ARRIVE_DISTANCE:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
	velocity.y = 0.0
	move_and_slide()
	if not is_on_floor():
		global_position.y = terrain.get_mesh_height(global_position.x, global_position.z) + FOOT_OFFSET
	# This CharacterBody keeps loosely following Manchego underneath (the
	# move_and_slide() above), same as before the seated pose existed --
	# still needed so it doesn't get left behind for collision/physics
	# purposes, and so dismounting anywhere near Manchego doesn't strand the
	# human far from where the camera/interactables expect them. It's just
	# no longer what determines where the rider is actually RENDERED: with
	# `visuals` now top_level (see start_riding_manchego()), the old
	# "turn visuals to face actual_motion, then play the walk cycle" pair
	# below is replaced by seating the figure directly on Manchego's own
	# back instead.
	_apply_manchego_seated_pose(delta)


## Seats the rider astride Manchego's back -- see RIDE_HIP_BEND's own doc
## comment for the full angle derivation, and start_riding_manchego()'s own
## comment for why `visuals` is top_level while this runs. Positioning: "the
## bottom of his hip segment [should] sit right on top of the horse's back"
## (per direct instruction) -- ProceduralFigure.HIP_PIVOT_Y is exactly where
## the pelvis mesh's own bottom edge sits, flush against the (unrotated) hip
## pivots, in the rig's own unscaled local units (see that const's own
## comment), so scaling it by this rig's HEIGHT_SCALE and placing THAT point
## at the seat's own live world position is a direct, literal implementation
## of the instruction, not an approximation.
func _apply_manchego_seated_pose(delta: float) -> void:
	var t := RIDE_POSE_SETTLE_SPEED * delta
	_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, -RIDE_HIP_BEND, t)
	_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, -RIDE_HIP_BEND, t)
	_leg_left.rotation.z = lerp_angle(_leg_left.rotation.z, signf(_leg_left.position.x) * RIDE_HIP_SPLAY, t)
	_leg_right.rotation.z = lerp_angle(_leg_right.rotation.z, signf(_leg_right.position.x) * RIDE_HIP_SPLAY, t)
	_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, RIDE_KNEE_BEND, t)
	_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, RIDE_KNEE_BEND, t)
	_spine.rotation.x = lerp_angle(_spine.rotation.x, RIDE_SPINE_LEAN, t)
	# Neck's own half of the head-upright compensation -- see
	# MANCHEGO_HEAD_UPRIGHT_NECK_SHARE's own comment. The head's own half
	# lives in _update_head_look() instead, since that function overwrites
	# _head.rotation.x itself every frame (right after this one runs) and
	# would otherwise stomp anything set here.
	_neck.rotation.x = lerp_angle(_neck.rotation.x, -RIDE_SPINE_LEAN * MANCHEGO_HEAD_UPRIGHT_NECK_SHARE, t)
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, -RIDE_ARM_FORWARD, t)
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, -RIDE_ARM_FORWARD, t)
	# "Angle his forearms close together from the elbows" -- see
	# RIDE_ELBOW_INWARD's own comment for the sign caveat. signf() off each
	# ARM's (not elbow's) own position.x, same reasoning RIDE_HIP_SPLAY's
	# own leg-pivot read uses: the elbow's own local X is just the arm
	# segment's stacking offset (usually ~0), not a side indicator.
	_elbow_left.rotation.z = lerp_angle(_elbow_left.rotation.z, -signf(_arm_left.position.x) * RIDE_ELBOW_INWARD, t)
	_elbow_right.rotation.z = lerp_angle(_elbow_right.rotation.z, -signf(_arm_right.position.x) * RIDE_ELBOW_INWARD, t)

	var seat_transform := _controlled_manchego.get_seat_transform()
	var hip_bottom_local_offset := Vector3(0, ProceduralFigure.HIP_PIVOT_Y, 0) * HEIGHT_SCALE
	visuals.global_transform = Transform3D(
		seat_transform.basis, seat_transform.origin - seat_transform.basis * hip_bottom_local_offset
	)


func _current_controlled_body() -> Node3D:
	if is_instance_valid(_controlled_giant):
		return _controlled_giant
	if is_instance_valid(_controlled_blorbus):
		return _controlled_blorbus
	return null


## Public query for portal.gd: a kingdom gate only opens while Blorbus (or
## the giant he merged into) is the one being directly piloted -- see that
## file's own doc comment for why this is the gate.
func is_piloting_blorbus() -> bool:
	return _current_controlled_body() != null


## Whichever body currently has the player's direct control -- Blorbus, or
## the giant post-merge, or null while playing as the human. Lets a portal
## key its own proximity check off Blorbus's actual position rather than the
## trailing human companion's (see portal.gd's _update_pilot_proximity()) --
## the human only follows within PLAYER_FOLLOW_DISTANCE/ARRIVE_DISTANCE of
## Blorbus, not of whatever Blorbus happens to be standing next to.
func get_controlled_body() -> Node3D:
	return _current_controlled_body()


func _update_blorbus_control(delta: float) -> void:
	var controlled: Node3D = _current_controlled_body()
	if not is_instance_valid(controlled):
		_end_blorbus_control()
		return
	var input := _get_move_input()
	var basis := camera_rig.global_transform.basis
	var direction := basis.x * input.x + basis.z * input.y
	direction.y = 0.0
	if direction.length() > 0.001:
		direction = direction.normalized()
	var jump_pressed := Input.is_action_just_pressed("jump") and not UIState.modal_open
	controlled.drive_from_player(direction, delta, _is_sprinting(), jump_pressed)
	if not is_instance_valid(_controlled_giant):
		_try_merge_blorbus_into_giant()

	# The human follows with the same wait-until-distant / stop-when-close
	# cadence as a party blorb, while retaining CharacterBody collision.
	var offset := controlled.global_position - global_position
	offset.y = 0.0
	if offset.length() > PLAYER_FOLLOW_DISTANCE:
		var follow_dir := offset.normalized()
		velocity.x = follow_dir.x * move_speed
		velocity.z = follow_dir.z * move_speed
	elif offset.length() < PLAYER_FOLLOW_ARRIVE_DISTANCE:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
	velocity.y = 0.0
	var before_move := global_position
	move_and_slide()
	# Reuses the same lake buoyancy the human's own ordinary control uses, so
	# he floats/swims across deep water while following Blorbus instead of
	# snapping straight down to the real lake floor the way plain terrain
	# height would otherwise place him. Only falls back to snapping onto
	# raw terrain height when the water physics found nothing to do AND
	# move_and_slide() didn't already resolve a real standing surface --
	# without that is_on_floor() guard, standing on a dock/ramp above the
	# lake (real collision, well above the analytic lake floor the terrain
	# function reports at that same XZ) got overwritten every frame, so the
	# follower clipped straight down into the water instead of staying put
	# on the dock.
	_update_lake_buoyancy(delta)
	if not (_lake_buoyancy_active or _lake_water_walk_active) and not is_on_floor():
		global_position.y = terrain.get_mesh_height(global_position.x, global_position.z) + FOOT_OFFSET
	# Face the motion that actually occurred, not merely the desired line to
	# Blorbus. Collision sliding and the 7m/3m follow hysteresis can make
	# those differ, which previously produced sideways/backward moonwalking.
	var actual_motion := global_position - before_move
	actual_motion.y = 0.0
	if actual_motion.length_squared() > 0.000001:
		visuals.rotation.y = atan2(actual_motion.x, actual_motion.z)
	_animate_walk(delta, true, 1.0)


## Small vertical slack matching drive_from_player()'s own resting height on
## an analytic surface: Blorbus's _ground_embed_offset() deliberately keeps
## his root a few centimetres above whatever he's standing on, so his mesh's
## lower curve still visibly meets it. Without this tolerance, "standing on
## Humongous" can never satisfy a strict <= surface test -- drive_from_player
## always snaps him to just above the giant's own surface height, never
## exactly onto or below it -- and the merge could never fire from ordinary
## walking, only (unreliably) mid-jump.
const BLORBUS_GIANT_MERGE_TOLERANCE := 0.2


func _try_merge_blorbus_into_giant() -> void:
	if not is_instance_valid(_controlled_blorbus):
		return
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not candidate is Blorb:
			continue
		var giant := candidate as Blorb
		if giant.blorb_type != "size":
			continue
		var surface: Variant = giant.giant_surface_height_at(_controlled_blorbus.global_position.x, _controlled_blorbus.global_position.z)
		if surface != null and _controlled_blorbus.global_position.y <= (surface as float) + BLORBUS_GIANT_MERGE_TOLERANCE:
			_controlled_blorbus.visible = false
			_controlled_blorbus.is_player_controlled = false
			_controlled_giant = giant
			_controlled_giant.is_player_controlled = true
			Hud.show_message("Blorbus psychically merged with Humongous!")
			return


## Blorbus/giant/Manchego only -- see _piloting_xiao_hou_zi's own doc comment
## for why possessing Xiao Hou Zi needs no equivalent branch here: it
## reskins this CharacterBody in place rather than driving a separate body
## camera_rig has to chase in world space, so camera_rig just stays local
## like it does for ordinary human control (see _apply_camera_framing()).
func _update_possession_camera() -> void:
	if _player_following_manchego and is_instance_valid(_controlled_manchego):
		camera_spring_arm.spring_length = 3.6
		camera_rig.global_position = _controlled_manchego.global_position + Vector3.UP * 1.75
		return
	if not _player_following_blorbus:
		return
	var controlled: Blorb = _controlled_giant if is_instance_valid(_controlled_giant) else _controlled_blorbus
	if is_instance_valid(controlled):
		var height := 1.6
		camera_spring_arm.spring_length = 3.5
		if controlled.blorb_type == "size":
			var scaled_height := Blorb.BODY_HEIGHT * controlled.size_multiplier * controlled.vertical_scale
			var crown_height := (Blorb.BODY_HEIGHT - Blorb.EMBED_DEPTH) * controlled.size_multiplier * controlled.vertical_scale
			# Anchor above the crown, then pull back by well over the body's
			# radius so the camera cannot remain buried inside the giant's goo.
			height = crown_height + scaled_height * 0.25
			camera_spring_arm.spring_length = Blorb.RADIUS * controlled.size_multiplier * 1.4
		camera_rig.global_position = controlled.global_position + Vector3.UP * height


## Per direct instruction: pressing "transform" (T / Y / Triangle -- see
## input_map.gd) sends each of the player's own party blorbs leaping onto
## the player's body to become a gelatinous covering over one body part --
## torso, head (worn as a hat), and all four limbs -- keeping each one's own
## elemental color/core/eyes rather than reading as a flat texture swap. No
## powers exist yet to actually grant (see the world bible's own Open
## Threads) -- this only builds the cosmetic layer those will hang off
## later. Pressing it again reverses it. See blorb_suit_controller.gd for
## the actual hop-on/hop-off animation and blorb_suit.gd for the per-slot
## geometry it builds once landed.
func _update_suit_input(delta: float) -> void:
	if Input.is_action_just_pressed("transform") and not UIState.modal_open:
		if _player_following_blorbus:
			Hud.show_message("Return to the player before using the blorb suit.")
		else:
			_blorb_suit.toggle()
	# The head blorb is a normal hat until genuine buoyancy starts. This uses
	# the same state that controls swimming, so stepping onto a wet-looking
	# shore cannot prematurely create the diving helmet.
	_blorb_suit.update(delta)
	# Do this after update(): a head blorb can complete its equip hop during
	# that call and must immediately receive the correct form as well.
	_blorb_suit.set_head_blorb_submerged(_lake_buoyancy_active or _giant_goo_active)
	_portrait.update()


## Per direct instruction: holding "left_arm_power"/"right_arm_power" (Q/E
## -- see input_map.gd) extends that arm forward, a placeholder gesture for
## whatever elemental power that arm's own blorb-suit covering eventually
## casts (no actual power exists yet -- see the world bible's own Open
## Threads). A HELD pose, not a toggle -- picked since these are named
## "*_power" (more of a charge/aim gesture than a standing switch), first
## pass and easy to change to a toggle if that reads better in practice.
##
## Called directly from _physics_process, immediately after _animate_walk
## (see that call site's own comment) -- not from _process, and not just
## "after _animate_walk somewhere" -- per direct instruction that this must
## unconditionally override the walk/run/jump swing cycle rather than just
## usually winning a cross-callback ordering race. _animate_walk's own
## branches (idle/walk/airborne/landing) all funnel through that one call,
## so overriding right after it covers all of them in a single step with
## no gap for anything else to run in between. Releasing the arm key needs
## no special-case return-to-normal logic for the SWING: _animate_walk's
## own lerp keeps running underneath every frame regardless, so it just
## resumes easing from wherever this override last left the value the
## instant this stops overriding it. The hand's own roll (see
## HAND_PALM_ROLL) doesn't get that for free -- nothing else in this
## file ever touches hand.rotation.y -- so _rest_hand_roll() below
## explicitly eases it back to its normal static wrist-twist value
## whenever that arm isn't posing.
##
## Q ("left_arm_power") drives _arm_left/_hand_left, and E
## ("right_arm_power") drives _arm_right/_hand_right -- the plainly-named
## pairing, not swapped. It USED TO be swapped (per an earlier direct
## correction, "Q is making the right arm move... should be switched") --
## that compensated for arm_left/arm_right themselves being built backwards
## in procedural_figure.gd at the time (confirmed and fixed separately, via
## the blorb-suit paper-doll -- see that file's own note, and the figure-
## rig skill's "Confirmed control-mapping facts"). Once the pivot naming
## itself became correct, the compensating swap here became a second wrong
## turn stacked on the first fix, putting it right back to backwards --
## un-swapped to match.
## Shoulder-button arm raises target a true horizontal pose.  Keep this
## independent of the flight gesture calibration below.
const ARM_POWER_POSE_ANGLE := deg_to_rad(90.0)
## Tuned above the old head-line target so the leading arm clears the crown
## in the flight silhouette rather than terminating at face level.
const FLIGHT_AIM_ARM_ANGLE := deg_to_rad(205.0)
const FLIGHT_PALM_DOWN_ROLL := PI * 0.5
const FLIGHT_REAR_ARM_BACK_ANGLE := deg_to_rad(68.0)
const FLIGHT_REAR_ELBOW_BEND := deg_to_rad(122.0)
const ARM_POWER_POSE_SETTLE_SPEED := 10.0
## Rolls the hand around its own wrist-to-fingers axis (rotation.y, ON TOP
## of the static WRIST_INWARD_ANGLE twist already baked in at build time --
## see procedural_figure.gd's own _build_arm), per direct instruction, so
## the palm ends up angled once the arm is extended forward. Applied as
## `rest_twist - side * HAND_PALM_ROLL` at its one use site in
## _pose_extended_arm below -- two rounds of direct-observation correction
## originally landed this at a full 90-degree roll (flat palm-down): a flat
## (non-side-dependent) `+HAND_PALM_ROLL` had the right arm correctly
## rolling palm-down but the left rolling the SAME direction instead of
## mirrored (palm-up); making it `side * HAND_PALM_ROLL` fixed the
## mirroring but flipped BOTH arms to palm-up; negating the whole term is
## what actually landed both palms down, confirmed at 90 degrees.
##
## Reduced from that confirmed 90 down to 60 per a further direct
## instruction ("angled in a bit" instead of flat down) -- since
## rest_twist above already faces the palm inward (toward the body's own
## centerline) before this roll is added on top in the SAME rotational
## direction, a SMALLER roll than the old full 90 lands partway between
## that inward-facing rest orientation and flat-down, i.e. angled in
## rather than either extreme. The exact amount (60, not some other
## partial value) is an ESTIMATE, not reconfirmed by observation at this
## new value -- adjust directly against what's actually seen in-game
## rather than re-deriving the geometry.
const HAND_PALM_ROLL := deg_to_rad(60.0)
const FIRE_JET_ARM_BACK_ANGLE := deg_to_rad(8.0)
const FIRE_JET_ARM_OUTWARD_ANGLE := deg_to_rad(16.0)
const FIRE_JET_ELBOW_BEND := deg_to_rad(10.0)
const FIRE_JET_POSE_SETTLE_SPEED := 11.0


func _apply_arm_power_poses(delta: float) -> void:
	if UIState.modal_open:
		return
	var t := ARM_POWER_POSE_SETTLE_SPEED * delta
	# Excluded while _fire_hand_hover_active -- both arm-power buttons are
	# still physically held then (that's what makes both hands Fire and
	# triggers hovering in the first place), but _apply_fire_jet_pose()
	# (called right after this function, see its own call site) is what
	# should own the arms' pose in that case, not this extended-forward
	# raise. Per direct correction: with both fire competing against that
	# hover pose every frame -- this function pulling toward the raised
	# angle, then the jet pose pulling back toward the hips -- the two
	# lerps never fully resolved, settling the arm at a permanent halfway
	# compromise instead of cleanly canceling the raise.
	var left_power := Input.is_action_pressed("left_arm_power") and not _fire_hand_hover_active
	var right_power := Input.is_action_pressed("right_arm_power") and not _fire_hand_hover_active
	var holding_power := left_power or right_power
	if holding_power:
		_arm_power_recovery = 0.0
	else:
		_arm_power_recovery = minf(_arm_power_recovery + ARM_POWER_POSE_SETTLE_SPEED * delta, 1.0)
	# side values also flipped here (was 1.0 with _arm_right/-1.0 with
	# _arm_left) to match procedural_figure.gd's own build-time convention
	# for THESE specific pivots post-fix (arm_left now built with
	# side=+1.0, arm_right with side=-1.0 -- see that file's own comment).
	# _pose_extended_arm()/_rest_hand_roll() compute rest_twist from this
	# side value using the EXACT SAME formula _build_arm() used to set the
	# hand's rotation.y in the first place; passing the wrong one here
	# doesn't just mirror the pose, it makes rest_twist reproduce the wrong
	# hand orientation entirely -- confirmed as the actual cause of the
	# reported "palm and back of hand mapping flipped" once the underlying
	# pivot-naming fix landed without this call site being updated to match.
	_left_arm_power_blend = move_toward(_left_arm_power_blend, 1.0 if left_power else 0.0, t)
	_right_arm_power_blend = move_toward(_right_arm_power_blend, 1.0 if right_power else 0.0, t)
	if _left_arm_power_blend > 0.001:
		_pose_extended_arm(_arm_left, _elbow_left, _hand_left, 1.0, _left_arm_power_blend)
	else:
		_rest_hand_roll(_hand_left, 1.0, t)
	if _right_arm_power_blend > 0.001:
		_pose_extended_arm(_arm_right, _elbow_right, _hand_right, -1.0, _right_arm_power_blend)
	else:
		_rest_hand_roll(_hand_right, -1.0, t)


## `side` is the ARM being posed (+1 right, -1 left -- ProceduralFigure's
## own convention, matching _build_arm's own parameter), not the input
## action -- see this function's own call sites above for how those two
## get mapped.
func _pose_extended_arm(arm_pivot: Node3D, elbow_pivot: Node3D, hand: Node3D, side: float, weight: float) -> void:
	# Target is the fixed constant -ARM_POWER_POSE_ANGLE, not the current
	# value plus an offset -- per direct instruction, the pose has to land
	# at the same absolute angle regardless of the arm's resting angle at
	# the moment the key was pressed, including mid-jump (where the
	# airborne pose already has the arm raised somewhat via JUMP_ARM_SWING
	# before this ever runs).
	# Final animation layer: it overrides the underlying walk/jump/landing
	# targets while held, but every joint interpolates to avoid any pop.
	arm_pivot.rotation.x = lerp_angle(arm_pivot.rotation.x, -ARM_POWER_POSE_ANGLE, weight)
	arm_pivot.rotation.y = lerp_angle(arm_pivot.rotation.y, 0.0, weight)
	arm_pivot.rotation.z = lerp_angle(arm_pivot.rotation.z, side * ProceduralFigure.ARM_OUTWARD_ANGLE, weight)
	elbow_pivot.rotation.x = lerp_angle(elbow_pivot.rotation.x, 0.0, weight)
	elbow_pivot.rotation.y = lerp_angle(elbow_pivot.rotation.y, 0.0, weight)
	elbow_pivot.rotation.z = lerp_angle(elbow_pivot.rotation.z, 0.0, weight)
	var rest_twist := -side * (PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE)
	hand.rotation.y = lerp_angle(hand.rotation.y, rest_twist - side * HAND_PALM_ROLL, weight)


func _rest_hand_roll(hand: Node3D, side: float, t: float) -> void:
	var rest_twist := -side * (PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE)
	hand.rotation.y = lerp_angle(hand.rotation.y, rest_twist, t)


## Two active Fire hands become downward lift jets rather than two forward
## flamethrowers. Arms stay fixed beside the hips, slightly spread so the
## raised fingertips angle outward, with both palms rolled toward the floor.
## When both Fire feet join them, the legs lock into a straight jet-flight
## silhouette as well; ordinary walk/jump animation continues underneath but
## this final layer wins while all four controls remain powered.
func _apply_fire_jet_pose(delta: float) -> void:
	if not _fire_hand_hover_active:
		return
	var t := minf(FIRE_JET_POSE_SETTLE_SPEED * delta, 1.0)
	_pose_fire_jet_arm(_arm_left, _elbow_left, _hand_left, 1.0, t)
	_pose_fire_jet_arm(_arm_right, _elbow_right, _hand_right, -1.0, t)
	if not _fire_limb_flight_active:
		return
	_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, 0.0, t)
	_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, 0.0, t)
	_leg_left.rotation.y = lerp_angle(_leg_left.rotation.y, 0.0, t)
	_leg_right.rotation.y = lerp_angle(_leg_right.rotation.y, 0.0, t)
	_leg_left.rotation.z = lerp_angle(_leg_left.rotation.z, 0.0, t)
	_leg_right.rotation.z = lerp_angle(_leg_right.rotation.z, 0.0, t)
	_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, 0.0, t)
	_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, 0.0, t)
	_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, 0.0, t)
	_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, 0.0, t)


func _pose_fire_jet_arm(
	arm_pivot: Node3D, elbow_pivot: Node3D, hand: Node3D, side: float, t: float
) -> void:
	arm_pivot.rotation.x = lerp_angle(arm_pivot.rotation.x, FIRE_JET_ARM_BACK_ANGLE, t)
	arm_pivot.rotation.y = lerp_angle(arm_pivot.rotation.y, 0.0, t)
	arm_pivot.rotation.z = lerp_angle(arm_pivot.rotation.z, side * FIRE_JET_ARM_OUTWARD_ANGLE, t)
	elbow_pivot.rotation.x = lerp_angle(elbow_pivot.rotation.x, -FIRE_JET_ELBOW_BEND, t)
	elbow_pivot.rotation.y = lerp_angle(elbow_pivot.rotation.y, 0.0, t)
	elbow_pivot.rotation.z = lerp_angle(elbow_pivot.rotation.z, 0.0, t)
	var rest_twist := -side * (PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE)
	hand.rotation.y = lerp_angle(hand.rotation.y, rest_twist - side * FLIGHT_PALM_DOWN_ROLL, t)


## Holding the run/sprint button while chest-air flight is active becomes a
## Superman-like aiming gesture. The body already turns toward the left
## stick's camera-relative flight direction, so the right arm's local
## forward extension points exactly where the player is travelling.
func _apply_flight_aim_pose(delta: float) -> void:
	if not _air_flight_active or not _is_sprinting() or _aerial_motion_direction.length_squared() <= 0.001:
		return
	var t := ARM_POWER_POSE_SETTLE_SPEED * delta
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, -FLIGHT_AIM_ARM_ANGLE, t)
	_arm_right.rotation.y = lerp_angle(_arm_right.rotation.y, 0.0, t)
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, -ProceduralFigure.ARM_OUTWARD_ANGLE, t)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, 0.0, t)
	_elbow_right.rotation.y = lerp_angle(_elbow_right.rotation.y, 0.0, t)
	_elbow_right.rotation.z = lerp_angle(_elbow_right.rotation.z, 0.0, t)
	# Full palm-down roll, independently of the shoulder-button pose's
	# intentionally partial hand roll.
	var right_rest_twist := PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE
	_hand_right.rotation.y = lerp_angle(_hand_right.rotation.y, right_rest_twist + FLIGHT_PALM_DOWN_ROLL, t)
	# The non-leading arm is not left to the walk cycle: pull its upper arm
	# decisively behind the torso, then fold the forearm tight back toward
	# the body for a compact, aggressive flight pose.
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, FLIGHT_REAR_ARM_BACK_ANGLE, t)
	_arm_left.rotation.y = lerp_angle(_arm_left.rotation.y, 0.0, t)
	_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, ProceduralFigure.ARM_OUTWARD_ANGLE * 0.25, t)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, -FLIGHT_REAR_ELBOW_BEND, t)
	_elbow_left.rotation.y = lerp_angle(_elbow_left.rotation.y, 0.0, t)
	_elbow_left.rotation.z = lerp_angle(_elbow_left.rotation.z, 0.0, t)


func _build_water_streams() -> void:
	_water_stream_left = _make_water_stream("LeftWaterHose")
	_water_stream_right = _make_water_stream("RightWaterHose")
	_fire_stream_left = _make_fire_stream("LeftFlamethrower")
	_fire_stream_right = _make_fire_stream("RightFlamethrower")
	_water_leg_stream_left = _make_water_stream("LeftWaterFootJet")
	_water_leg_stream_right = _make_water_stream("RightWaterFootJet")
	_fire_leg_stream_left = _make_fire_stream("LeftFireFootJet")
	_fire_leg_stream_right = _make_fire_stream("RightFireFootJet")


## Soft particle texture/ramp tuning -- see particle_fx.gd's own class doc
## comment for the general technique this and _make_fire_stream() both use.
const WATER_PARTICLE_SOFTNESS := 2.2
const FIRE_PARTICLE_SOFTNESS := 1.7
## Lower than it might otherwise be -- with angle_min/max now a narrow
## range instead of a full 0-360 spin (see _make_fire_stream()'s own
## comment on particle_flag_align_y), each particle's own rotation varies
## far less, so a strong wobble would read as the same asymmetric shape
## repeating lick to lick rather than organic variety.
const FIRE_PARTICLE_WOBBLE := 0.2


func _make_water_stream(stream_name: String) -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = stream_name
	stream.amount = 180
	stream.lifetime = WATER_STREAM_LIFETIME
	stream.randomness = 0.12
	stream.visibility_aabb = AABB(Vector3(-0.6, -0.6, -7.0), Vector3(1.2, 1.2, 7.4))
	# A soft, alpha-blended billboard instead of a solid-colored SphereMesh
	# -- per direct report, the old sphere read as a hard uniform ball
	# regardless of color, not water.
	var texture := ParticleFX.build_soft_gradient_texture(24, WATER_PARTICLE_SOFTNESS)
	var water_material := ParticleFX.build_billboard_material(texture, Color.WHITE, false, 0.35)
	water_material.vertex_color_use_as_albedo = true
	var droplet := QuadMesh.new()
	droplet.size = Vector2(0.16, 0.16)
	droplet.material = water_material
	var process := ParticleProcessMaterial.new()
	# look_at() below aims local -Z down the character's +Z forward axis.
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 1.0
	# A hose stays almost parallel but has a slight weighty downward arc.
	process.gravity = Vector3(0.0, -1.2, 0.0)
	process.initial_velocity_min = WATER_STREAM_SPEED * 0.9
	process.initial_velocity_max = WATER_STREAM_SPEED * 1.1
	process.scale_min = 0.85
	process.scale_max = 1.3
	# A bright near-white highlight right at the nozzle, settling into the
	# same rich blue every fountain/water blorb already uses, fading to
	# transparent as each droplet reaches the end of its short life -- a
	# flat single color (the earlier approach) read as one uniform, opaque
	# ball; this reads as an actual spray of individual droplets catching
	# the light.
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(0.85, 0.95, 1.0, 0.95)},
		{"offset": 0.35, "color": TownProps.WATER_COLOR},
		{"offset": 1.0, "color": Color(TownProps.WATER_COLOR.r, TownProps.WATER_COLOR.g, TownProps.WATER_COLOR.b, 0.0)},
	])
	stream.process_material = process
	stream.draw_pass_1 = droplet
	stream.emitting = false
	add_child(stream)
	stream.top_level = true
	return stream


func _make_fire_stream(stream_name: String) -> GPUParticles3D:
	var stream := GPUParticles3D.new()
	stream.name = stream_name
	# A dense short-lived, broad cone reads as a continuous flamethrower,
	# unlike the long evenly-spaced droplets used by the water hose.
	stream.amount = 260
	stream.lifetime = 0.34
	stream.randomness = 0.35
	stream.visibility_aabb = AABB(Vector3(-1.5, -1.5, -7.0), Vector3(3.0, 3.0, 7.4))
	# Soft, additively-blended billboards instead of a solid-colored
	# SphereMesh -- per direct report ("look like orange bubbles"). See
	# particle_fx.gd's own class doc comment: overlapping additive
	# particles build up glowing brightness the way real flame does,
	# rather than each one just occluding what's behind it like a solid
	# object would.
	var texture := ParticleFX.build_soft_gradient_texture(24, FIRE_PARTICLE_SOFTNESS, FIRE_PARTICLE_WOBBLE)
	var flame_material := ParticleFX.build_billboard_material(texture, Color.WHITE, true, 0.0)
	flame_material.vertex_color_use_as_albedo = true
	# Elongated (taller than wide), not square -- paired with
	# particle_flag_align_y below, this reads as a streak pointed along
	# each particle's own direction of travel rather than a round puff, so
	# the whole spray reads as a directional jet again. Per direct
	# correction: the earlier square, freely-spinning (angle_min/max 0-360)
	# blob looked like fire, but no longer like it was going anywhere in
	# particular.
	var flame := QuadMesh.new()
	flame.size = Vector2(0.22, 0.5)
	flame.material = flame_material
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, -1.0)
	process.spread = 6.0
	process.gravity = Vector3(0.0, -1.4, 0.0)
	process.initial_velocity_min = 9.0
	process.initial_velocity_max = 14.0
	process.scale_min = 0.5
	process.scale_max = 1.05
	# Aligns each particle's own local Y (the quad's long axis, see
	# flame.size above) to its own velocity direction while still
	# billboarding around that axis to face the camera -- Godot's own
	# standard technique for a directional streak (rain, sparks, jets),
	# rather than a billboard that only ever reads as a flat round puff
	# regardless of how fast or which way it's actually moving.
	process.particle_flag_align_y = true
	# A small range, not a full random spin -- enough per-particle variety
	# that the reused wobble texture (see build_soft_gradient_texture()'s
	# own comment) doesn't look identical lick to lick, without undoing the
	# velocity alignment just set above.
	process.angle_min = -12.0
	process.angle_max = 12.0
	# A real flame cools as it travels outward: bright pale heat at the
	# nozzle, through orange, settling into the same deep red-orange every
	# fire blorb/Fire Gem already uses, fading to transparent as it dies.
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(1.0, 0.95, 0.75, 1.0)},
		{"offset": 0.25, "color": Color(1.0, 0.55, 0.1, 1.0)},
		{"offset": 0.6, "color": Color(0.85, 0.25, 0.05, 0.9)},
		{"offset": 1.0, "color": Color(0.35, 0.06, 0.02, 0.0)},
	])
	# Visibly forms just past the nozzle, then dissipates -- not a fixed
	# size the whole time.
	process.scale_curve = ParticleFX.build_scale_curve(0.6, 1.15, 0.3, 0.7)
	# Organic flicker, but modest -- per direct correction, the original
	# turbulence strength scattered particles enough sideways motion that
	# the spray stopped reading as a coherent jet at all. Kept low enough
	# now to still flicker without visibly dispersing the cone.
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 1.0
	process.turbulence_noise_scale = 2.0
	process.turbulence_influence_min = 0.04
	process.turbulence_influence_max = 0.15
	stream.process_material = process
	stream.draw_pass_1 = flame
	stream.emitting = false
	add_child(stream)
	stream.top_level = true
	return stream


const WATER_POWER_MP_PER_SECOND := 3.0
const FIRE_POWER_MP_PER_SECOND := 4.5

## Player-arm-stream combat tuning -- a separate, parallel constant set from
## blorb.gd's own STREAM_RANGE/STREAM_BASE_DAMAGE_PER_SECOND (see that
## file's _update_elemental_stream()) rather than shared ones, since the two
## code paths aim differently: a blorb's combat stream is locked onto a
## specific _combat_target, while the player's stream just points wherever
## the player is facing, so hitting a skeleton needs an actual facing-cone
## check (STREAM_HALF_ANGLE_COS) that the blorb side has no equivalent of.
## Boosted by the worn arm blorb(s)' own Strength via combat_math.gd's
## rolled_stream_rate(), same as blorb.gd's own stream -- see
## _damage_skeletons_in_stream().
const STREAM_DAMAGE_RANGE := 6.0
const STREAM_BASE_DAMAGE_PER_SECOND := 6.0
const STREAM_HALF_ANGLE_COS := 0.85  # roughly a 32-degree half-angle cone


func _update_limb_power_state(delta: float) -> void:
	_left_arm_water_active = _consume_limb_power("arm_left", "left_arm_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_right_arm_water_active = _consume_limb_power("arm_right", "right_arm_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_left_arm_fire_active = _consume_limb_power("arm_left", "left_arm_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)
	_right_arm_fire_active = _consume_limb_power("arm_right", "right_arm_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)
	_left_leg_water_active = _consume_limb_power("leg_left", "left_leg_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_right_leg_water_active = _consume_limb_power("leg_right", "right_leg_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_left_leg_fire_active = _consume_limb_power("leg_left", "left_leg_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)
	_right_leg_fire_active = _consume_limb_power("leg_right", "right_leg_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)

	_water_leg_hover_active = _left_leg_water_active and _right_leg_water_active
	_fire_hand_hover_active = _left_arm_fire_active and _right_arm_fire_active
	_fire_limb_flight_active = (
		_fire_hand_hover_active and _left_leg_fire_active and _right_leg_fire_active
	)
	_air_foot_hover_active = _blorb_suit.has_air_hover_legs()

	var hovering := _is_powered_hover_active()
	if hovering and not _was_powered_hover_active:
		var ground_height: float = terrain.get_mesh_height(global_position.x, global_position.z)
		_powered_hover_target_y = maxf(
			global_position.y, ground_height + FOOT_OFFSET + POWERED_HOVER_HEIGHT
		)
	_was_powered_hover_active = hovering


func _consume_limb_power(
	slot: String, action: String, element: String, rate: float, delta: float
) -> bool:
	if UIState.modal_open or not Input.is_action_pressed(action):
		return false
	var blorb := _blorb_suit.worn_blorb_in_slot(slot)
	if blorb == null or blorb.element_state != element:
		return false
	return blorb.consume_mp(rate * delta)


func _is_powered_hover_active() -> bool:
	return _water_leg_hover_active or _fire_hand_hover_active or _air_foot_hover_active


func _is_suit_flight_active() -> bool:
	return _air_flight_active or _fire_limb_flight_active or _air_foot_hover_active


func _apply_powered_hover_vertical(delta: float, directional_flight: bool) -> void:
	if not _is_powered_hover_active():
		return
	if directional_flight:
		# Camera-pitched traversal owns elevation while moving. Holding still
		# captures the new level on the next frame instead of drifting back to
		# the activation height.
		_powered_hover_target_y = global_position.y + velocity.y * delta
		return
	var height_error := _powered_hover_target_y - global_position.y
	var target_velocity := clampf(
		height_error * POWERED_HOVER_SETTLE_SPEED,
		-POWERED_HOVER_LIFT_SPEED, POWERED_HOVER_LIFT_SPEED
	)
	velocity.y = move_toward(velocity.y, target_velocity, POWERED_HOVER_SETTLE_SPEED * delta)


func _update_water_streams(delta: float) -> void:
	var forward := visuals.global_transform.basis * Vector3(0.0, 0.0, 1.0)
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	var downward := Vector3.DOWN
	var fire_hand_jet_direction := downward
	if _fire_limb_flight_active:
		var combined_foot_direction := _foot_jet_direction(_ankle_left) + _foot_jet_direction(_ankle_right)
		if combined_foot_direction.length_squared() > 0.001:
			fire_hand_jet_direction = combined_foot_direction.normalized()
	var left_hand_direction := fire_hand_jet_direction if _fire_hand_hover_active else forward
	var right_hand_direction := fire_hand_jet_direction if _fire_hand_hover_active else forward
	_update_water_stream(
		_water_stream_left, _palm_left, forward,
		_left_arm_water_active
	)
	_update_water_stream(
		_water_stream_right, _palm_right, forward,
		_right_arm_water_active
	)
	_update_water_stream(
		_fire_stream_left, _palm_left, left_hand_direction,
		_left_arm_fire_active
	)
	_update_water_stream(
		_fire_stream_right, _palm_right, right_hand_direction,
		_right_arm_fire_active
	)
	_update_water_stream(_water_leg_stream_left, _toe_left, downward, _left_leg_water_active)
	_update_water_stream(_water_leg_stream_right, _toe_right, downward, _right_leg_water_active)
	_update_water_stream(
		_fire_leg_stream_left, _toe_left, _foot_jet_direction(_ankle_left), _left_leg_fire_active
	)
	_update_water_stream(
		_fire_leg_stream_right, _toe_right, _foot_jet_direction(_ankle_right), _right_leg_fire_active
	)
	var forward_stream_active := (
		_left_arm_water_active or _right_arm_water_active
		or ((_left_arm_fire_active or _right_arm_fire_active) and not _fire_hand_hover_active)
	)
	if forward_stream_active:
		_damage_skeletons_in_stream(forward, delta)


## Per direct bug report, the player's own arm-mounted water/fire streams
## (above) never damaged skeletons -- only a free-roaming blorb's separate
## combat stream (blorb.gd's _update_elemental_stream()) did. Distance- and
## facing-cone-based rather than a real particle-collision check, matching
## this codebase's existing convention of proximity checks over physics
## callbacks (see skeleton_nme.gd's own _find_target(), blorb.gd's
## _find_nearest_skeleton()).
func _damage_skeletons_in_stream(forward: Vector3, delta: float) -> void:
	var origin := global_position
	var participants := _active_forward_stream_blorbs()
	# The stream's own damage doesn't stack per active arm (one flat rate
	# whether one or two arms are streaming, same as before) -- Strength
	# scaling picks the strongest contributing arm blorb rather than
	# averaging it down against a weaker second one.
	var strength := 0
	for blorb in participants:
		strength = maxi(strength, blorb.strength)
	var damage_rate := CombatMath.rolled_stream_rate(STREAM_BASE_DAMAGE_PER_SECOND, strength)
	for node in get_tree().get_nodes_in_group("skeletons"):
		var skeleton := node as Node3D
		if skeleton == null or not skeleton.has_method("take_damage"):
			continue
		var to_skeleton := skeleton.global_position - origin
		var dist := to_skeleton.length()
		if dist < 0.001 or dist > STREAM_DAMAGE_RANGE:
			continue
		if forward.dot(to_skeleton / dist) < STREAM_HALF_ANGLE_COS:
			continue
		if skeleton.has_method("register_xp_participant"):
			for blorb in participants:
				skeleton.register_xp_participant(blorb)
		skeleton.take_damage(damage_rate * delta)


func _active_forward_stream_blorbs() -> Array[Blorb]:
	var participants: Array[Blorb] = []
	var active_slots := {
		"arm_left": _left_arm_water_active or (_left_arm_fire_active and not _fire_hand_hover_active),
		"arm_right": _right_arm_water_active or (_right_arm_fire_active and not _fire_hand_hover_active),
	}
	for slot in active_slots:
		if not active_slots[slot]:
			continue
		var blorb := _blorb_suit.worn_blorb_in_slot(slot)
		if blorb != null:
			participants.append(blorb)
	return participants


func _foot_jet_direction(ankle: Node3D) -> Vector3:
	if ankle == null:
		return Vector3.DOWN
	var out_of_sole := -ankle.global_transform.basis.y
	return out_of_sole.normalized() if out_of_sole.length_squared() > 0.001 else Vector3.DOWN


## Angle/speed of the small organic waver applied to a stream's own AIM
## below -- distinct from _make_fire_stream()'s per-particle turbulence
## (which randomizes each particle's own motion once already emitted).
## Following a flamethrower VFX tutorial's own core technique of also
## randomizing the EMITTER's own aim (there, noise-modulated keyframes on
## the held prop's rotation), a real held hose/flamethrower never points
## perfectly still either.
const STREAM_AIM_WOBBLE_ANGLE := deg_to_rad(2.5)
const STREAM_AIM_WOBBLE_SPEED := 3.2


func _update_water_stream(stream: GPUParticles3D, hand: Node3D, forward: Vector3, active: bool) -> void:
	if stream == null or hand == null:
		return
	stream.emitting = active
	if not active:
		return
	var origin := hand.global_position
	stream.global_position = origin
	# Looking exactly down with world-up as the secondary axis is singular.
	# The body's forward supplies a stable roll reference for vertical jets.
	var up_reference := Vector3.UP
	if absf(forward.normalized().dot(up_reference)) > 0.98:
		up_reference = visuals.global_transform.basis.z.normalized()
	# Phased off the stream's own instance ID so the two hands/feet don't
	# wobble in an obviously mirrored, synced way.
	var phase := float(stream.get_instance_id() % 1000) * 0.01
	var t := Time.get_ticks_msec() * 0.001 * STREAM_AIM_WOBBLE_SPEED + phase
	var wobble := Basis(Vector3.UP, sin(t) * STREAM_AIM_WOBBLE_ANGLE) * Basis(Vector3.RIGHT, cos(t * 1.3) * STREAM_AIM_WOBBLE_ANGLE)
	stream.look_at(origin + wobble * forward, up_reference)


## CheatCodes.toggled's handler -- see the _ready() connection above. Only
## _apply_blorb_suit_rig_scale() needs calling here: that alone re-derives
## _current_blorb_suit_rig_scale() (which reads CheatCodes.enabled directly,
## not a locally-cached copy of it) and re-applies it to whatever suit is
## currently worn.
func _on_cheats_toggled(_is_enabled: bool) -> void:
	_apply_blorb_suit_rig_scale()


func _on_held_item_changed() -> void:
	if _held_visual != null:
		_held_visual.queue_free()
		_held_visual = null
	if HeldItem.current.is_empty():
		return
	var entry := ShopCatalog.find(HeldItem.current["name"])
	if entry.is_empty():
		return
	_held_visual = entry["build_visual"].call(HELD_ITEM_SCALE)
	_palm_right.add_child(_held_visual)
	# If the visual authored its own GripPoint (the spot on ITS surface
	# meant to meet the palm), shift the whole visual so that point lands
	# exactly on palm_right's own origin -- grip.position is in the visual's
	# pre-scale local units, so it has to be scaled by the same amount
	# build_visual() just scaled the visual itself to convert that into the
	# palm's own local space. Position-only (not full rotational alignment)
	# -- see the figure-rig skill's guidance on preferring the simple,
	# clearly-derived version over a fancier one that's more likely wrong
	# without being able to see it in-engine. HELD_ITEM_LOCAL_OFFSET is
	# added on top either way (see its own comment for why GripPoint's
	# single-axis alignment alone still isn't enough).
	var grip := _held_visual.get_node_or_null("GripPoint") as Node3D
	if grip != null:
		_held_visual.position = -grip.position * _held_visual.scale + HELD_ITEM_LOCAL_OFFSET
	else:
		_held_visual.position = HELD_ITEM_LOCAL_OFFSET
	# Inherits the whole arm's walk-swing animation (and now the hand's own
	# wrist twist) for free via the parent chain -- a nice incidental
	# "swinging held item" effect, not worth damping.


func _update_throw_input() -> void:
	var pressed := Input.is_action_pressed("throw")
	if (
		pressed and not _prev_throw_pressed
		and not HeldItem.current.is_empty()
		and not UIState.modal_open
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	):
		_throw_held_item()
	_prev_throw_pressed = pressed


func _throw_held_item() -> void:
	var item: Dictionary = HeldItem.current
	var forward := -camera.global_transform.basis.z

	var thrown := ThrownItem.new()
	thrown.item_name = item["name"]
	get_tree().current_scene.add_child(thrown)
	thrown.global_position = camera.global_position + forward * THROW_SPAWN_DISTANCE
	thrown.velocity = forward * THROW_SPEED + Vector3.UP * THROW_LOFT

	Inventory.remove(item["name"])
	HeldItem.clear()


func _update_head_look(delta: float) -> void:
	# Solve the camera direction in the body/neck's LOCAL basis rather than
	# comparing world yaw and horizon pitch separately. This is equivalent
	# while walking, but crucial while diving: the body can freely lean in
	# camera space and the HeadPivot at the skull base still tracks the view
	# within anatomical limits instead of inheriting a horizon-relative nod.
	var local_camera_forward := visuals.global_transform.basis.inverse() * -camera.global_transform.basis.z
	var relative_yaw := atan2(local_camera_forward.x, local_camera_forward.z)
	# Past HEAD_YAW_LIMIT the neck doesn't hold at max twist -- tracking
	# just disengages and the head eases back to level/facing front, as if
	# the camera's swung far enough that it's no longer trying to match the
	# face at all. Pitch disengages right along with yaw here (not judged
	# separately), since "the camera's no longer trying to match the face"
	# is a single concept covering both, not just a left/right one. The
	# snap in the targets here still eases visually since they're
	# lerp_angle'd below, not applied instantly.
	var aerial_head_tracking := _lake_diving_active or _is_suit_flight_active()
	var yaw_limit := AERIAL_HEAD_YAW_LIMIT if aerial_head_tracking else HEAD_YAW_LIMIT
	var pitch_min := -AERIAL_HEAD_PITCH_LIMIT if aerial_head_tracking else -HEAD_PITCH_UP_LIMIT
	var pitch_max := AERIAL_HEAD_PITCH_LIMIT if aerial_head_tracking else HEAD_PITCH_DOWN_LIMIT
	var turn_speed := AERIAL_HEAD_TURN_SPEED if aerial_head_tracking else HEAD_TURN_SPEED
	var tracking_engaged := absf(relative_yaw) <= yaw_limit
	var target_yaw := relative_yaw if tracking_engaged else 0.0
	# Nodding (pitch) is local X after all -- confirmed via a direct
	# headless transform check on the OLD figure.glb-based rig: pitch=+30
	# deg gave front.y=0.5 (a nod, not a roll), and camera_pivot.rotation.x
	# is positive when looking up, so +X head rotation = "looking up" was
	# taken as verified with no sign flip needed.
	#
	# That verification doesn't carry over to the current procedural rig,
	# though, and this was missed when the rig was swapped -- confirmed
	# backwards by direct observation (looking down pitched the head up
	# and vice versa). The old rig's head sat under an ANCESTOR with a
	# static 180-degree Y rotation (correcting the imported model's
	# reversed front); the new rig has no such ancestor. Conjugating a
	# local X rotation by a 180-degree Y rotation negates it (Ry(180) *
	# Rx(th) * Ry(180)^-1 = Rx(-th)) -- removing that ancestor is exactly
	# what flipped the sign this mapping needs. Negated here, with the up/
	# down limits swapped to match (positive _head.rotation.x is now "look
	# down" instead of "look up").
	var target_elevation := 0.0
	if tracking_engaged:
		# Positive head X looks down in the procedural rig, hence the negated
		# local camera Y component. The clamp is the natural neck constraint.
		target_elevation = clampf(-asin(clampf(local_camera_forward.y, -1.0, 1.0)), pitch_min, pitch_max)
	if aerial_head_tracking:
		# Flight/swim direction is the primary head target. Crucially, this is
		# solved in the same local neck frame as grounded head tracking, never
		# by writing a competing world-space transform.
		var travel_direction := _aerial_motion_direction
		if travel_direction.length_squared() <= 0.001:
			# At rest, retain the body's own heading. Do not let a camera orbit
			# manufacture a new head target.
			travel_direction = visuals.global_transform.basis.z
		var local_travel := visuals.global_transform.basis.inverse() * travel_direction.normalized()
		target_yaw = clampf(atan2(local_travel.x, local_travel.z), -yaw_limit, yaw_limit)
		target_elevation = clampf(-asin(clampf(local_travel.y, -1.0, 1.0)), pitch_min, pitch_max)
		# Travel always leads. The camera is merely an optional offset, and it
		# is fully disabled once the camera is physically in front of the face.
		# Test against the head's real world-facing axis, not a pitched/rolled
		# visual-root basis or the camera's own look vector.
		var camera_from_head := camera.global_position - _head.global_position
		var body_forward := visuals.global_transform.basis.z.normalized()
		var camera_behind := camera_from_head.normalized().dot(body_forward) < -0.05
		if _aerial_motion_direction.length_squared() > 0.001 and camera_behind:
			var yaw_offset := wrapf(relative_yaw - target_yaw, -PI, PI)
			target_yaw = clampf(target_yaw + clampf(yaw_offset, -yaw_limit, yaw_limit), -yaw_limit, yaw_limit)
			var camera_elevation := -asin(clampf(local_camera_forward.y, -1.0, 1.0))
			target_elevation = clampf(
				target_elevation + clampf(camera_elevation - target_elevation, -deg_to_rad(45.0), deg_to_rad(45.0)),
				pitch_min, pitch_max
			)
	# Head's own half of the Manchego-riding upright compensation -- see
	# MANCHEGO_HEAD_UPRIGHT_NECK_SHARE's own comment for why this has to
	# live here (this function overwrites _head.rotation.x every frame) and
	# the neck's own matching half. Applied AFTER target_elevation's own
	# pitch_min/pitch_max clamp, deliberately not re-clamped by it: this is
	# canceling a structural bias from _spine's own rest lean, not part of
	# the ordinary look-around range that clamp is meant to limit.
	if _player_following_manchego:
		target_elevation -= RIDE_SPINE_LEAN * (1.0 - MANCHEGO_HEAD_UPRIGHT_NECK_SHARE)
	_head_look_yaw = lerp_angle(_head_look_yaw, target_yaw, turn_speed * delta)
	_head_look_pitch = lerp_angle(_head_look_pitch, target_elevation, turn_speed * delta)
	if aerial_head_tracking:
		# In flight/swimming the body's local Y axis can be almost horizontal.
		# A local Euler yaw therefore swivels around the neck shaft, which
		# reads as a corkscrew/loll rather than a level side-to-side turn.
		#
		# Per direct correction: an earlier fix for that composed the gaze
		# directly as rotations of the rest orientation around the CAMERA
		# frame's own up/right axes (Basis(camera_up, yaw) * Basis(camera_
		# right, pitch) * rest_basis). That fixed the loll, but broke the
		# more fundamental behavior this whole branch exists for -- facing
		# the HEAD (not its crown) toward the travel direction while
		# climbing/diving steeply -- because rotating a rest orientation by
		# a yaw/pitch AMOUNT around external axes doesn't actually aim any
		# particular local axis of the result at a specific target; for a
		# large pitch (a steep climb) that can visibly end up aiming the
		# head's own up/crown axis toward the target instead of its face.
		#
		# This instead rebuilds the exact same body-relative gaze direction
		# _head_look_yaw/_head_look_pitch already describe (the same
		# spherical-to-Cartesian inverse of the atan2()/asin() used to
		# derive target_yaw/target_elevation above) as a WORLD vector, then
		# uses Basis.looking_at() to build the head's orientation directly
		# from it. looking_at() defines its own forward axis as EXACTLY the
		# target direction by construction, so the face -- never the crown
		# -- points there regardless of how steep the angle is, while
		# re-deriving "up" from the camera's own stable up each frame (not
		# the pitched body's) is what actually removes the corkscrew/loll,
		# since the camera's up never itself rotates out of level.
		var local_gaze := Vector3(
			cos(_head_look_pitch) * sin(_head_look_yaw),
			-sin(_head_look_pitch),
			cos(_head_look_pitch) * cos(_head_look_yaw)
		)
		var world_gaze := (visuals.global_transform.basis * local_gaze).normalized()
		var camera_up := camera.global_transform.basis.y.normalized()
		# Looking nearly straight up/down the camera's own up axis is
		# singular for looking_at() (same issue _update_water_stream()
		# already guards against elsewhere in this file, for the same
		# reason) -- the body's own forward is a stable fallback reference
		# in that case.
		if absf(world_gaze.dot(camera_up)) > 0.98:
			camera_up = visuals.global_transform.basis.z.normalized()
		var head_transform := _head.global_transform
		# looking_at()'s own -Z-is-forward convention negated to match this
		# rig's own +Z-forward one (see this file's various "forward = +Z"
		# notes elsewhere).
		head_transform.basis = Basis.looking_at(-world_gaze, camera_up)
		_head.global_transform = head_transform
	else:
		_head.rotation.y = _head_look_yaw
		_head.rotation.x = _head_look_pitch
		# The aerial branch above writes _head's full basis directly (see
		# its own comment -- derived from the CAMERA's own up vector, not
		# the body's), which can leave a real Z roll baked in whenever the
		# camera wasn't exactly level with the body -- practically always,
		# mid-flight. This branch only ever set X/Y, so that roll had
		# nothing to ever clear it once grounded, leaving the head visibly
		# tilted indefinitely after landing/dismounting. Per direct report
		# -- eased back to level here rather than snapped, matching every
		# other head-look transition's own lerp_angle smoothing.
		_head.rotation.z = lerp_angle(_head.rotation.z, 0.0, turn_speed * delta)


func _clamp_camera_above_ground() -> void:
	# SpringArm3D's own collision can still let the camera rest "successfully"
	# right at the terrain surface, which reads as clipping into the ground
	# once perspective/near-plane distortion is factored in, especially when
	# pitched to look up steeply. Clamp against the same exact height
	# function used everywhere else so the camera never renders from
	# underneath the ground.
	var min_y: float = terrain.get_mesh_height(camera.global_position.x, camera.global_position.z) + CAMERA_GROUND_MARGIN
	if camera.global_position.y < min_y:
		camera.global_position.y = min_y


## Picks a fresh idle pose -- see the IDLE_* consts' own comment for the
## reasoning and the caveat that the two new rotation axes here (leg
## abduction, hip drop) aren't visually re-verified in-engine.
func _roll_idle_pose() -> void:
	_idle_elbow_left = -randf_range(IDLE_ELBOW_MIN, IDLE_ELBOW_MAX)
	_idle_elbow_right = -randf_range(IDLE_ELBOW_MIN, IDLE_ELBOW_MAX)
	_idle_leg_variant_active = randf() < IDLE_LEG_VARIANT_CHANCE
	_idle_bent_leg_side = 1.0 if randf() < 0.5 else -1.0
	_idle_knee_bend = randf_range(IDLE_KNEE_MIN, IDLE_KNEE_MAX)


## `traversal_speed_multiplier` removes the blorb-skate boost from the
## animation calculation. The player covers three times the ground while
## skating, but the established run cycle keeps its original pace.
func _animate_walk(delta: float, grounded: bool, traversal_speed_multiplier: float = 1.0) -> void:
	# Lake swimming is neither a jump nor standing: both surface swimming and
	# a motionless underwater diver use the intentionally relaxed descent
	# silhouette. It takes precedence over the transient landing pose so
	# entering water never reads as a land impact.
	if _lake_buoyancy_active:
		_animate_swimming(delta)
		return
	if _air_flight_active or _fire_limb_flight_active or _water_leg_hover_active or _fire_hand_hover_active:
		# Flight shares the relaxed floating silhouette but intentionally does
		# not inherit water's flipper-kick layer. Water jets and hand-fire hover
		# also stay out of the walk cycle; their thrust carries the body.
		_animate_relaxed_floating(delta)
		return
	# Paired Air feet are deliberately different: they suspend the collision
	# body but traversal retains the ordinary walk/run cycle.
	if _air_foot_hover_active:
		grounded = true
	# Landing takes priority over everything else for a brief window --
	# even if the character starts walking again immediately, the impact
	# crouch still plays out first (LANDING_DURATION is short enough that
	# this reads as an impact reaction, not a delay before movement
	# responds).
	if _landing_timer > 0.0:
		_landing_timer -= delta
		_animate_landing(delta)
		return

	if not grounded:
		_animate_airborne(delta)
		return
	# Landing spreads the shoulders briefly to brace the impact. Every
	# ordinary grounded pose returns that spread to its rig-specific rest
	# angle.
	var arm_rest_t := POSE_SETTLE_SPEED * delta
	var left_arm_rest := MonkeyFigure.ARM_OUTWARD_ANGLE if _piloting_xiao_hou_zi else ProceduralFigure.ARM_OUTWARD_ANGLE
	var right_arm_rest := -MonkeyFigure.ARM_OUTWARD_ANGLE if _piloting_xiao_hou_zi else -ProceduralFigure.ARM_OUTWARD_ANGLE
	_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, left_arm_rest, arm_rest_t)
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, right_arm_rest, arm_rest_t)

	var horizontal_speed := Vector2(velocity.x, velocity.z).length() / traversal_speed_multiplier
	if horizontal_speed > 0.1:
		# The cycle's phase keeps advancing normally, but its targets ease in
		# from the impact pose over a short recovery instead of appearing as a
		# single-frame replacement when LANDING_DURATION expires.
		_walk_cycle_recovery = minf(_walk_cycle_recovery + LANDING_WALK_RECOVERY_SPEED * delta, 1.0)
		var cycle_t := _walk_cycle_recovery
		var arm_cycle_t := minf(cycle_t, _arm_power_recovery)
		# Running isn't just walking sped up -- per direct instruction, it
		# needs to read as more dynamic movement, not just a faster cycle.
		# _walk_phase already advances proportionally to horizontal_speed,
		# which alone would make the cycle rate scale linearly with speed
		# (exactly "sped-up walking"); SPRINT_SWING_SPEED_SCALE pulls that
		# back down a bit so some of the speed increase shows up as longer
		# strides instead of pure faster cadence, while SPRINT_SWING_AMOUNT/
		# SPRINT_BEND_SCALE push the swing arc and knee/elbow bend further
		# than walking ever reaches.
		var sprinting := _is_sprinting()
		var cadence_scale := TEMP_MONKEY_WALK_CADENCE_SCALE if _piloting_xiao_hou_zi else 1.0
		var swing_speed := WALK_SWING_SPEED * cadence_scale * (SPRINT_SWING_SPEED_SCALE if sprinting else 1.0)
		var swing_amount := SPRINT_SWING_AMOUNT if sprinting else WALK_SWING_AMOUNT
		var bend_scale := SPRINT_BEND_SCALE if sprinting else 1.0
		_walk_phase += delta * swing_speed * horizontal_speed
		# See SPRINT_STRIDE_EASE's own comment -- warps the phase used for the
		# rest of this cycle (swing, knee/elbow bend, body bob below) so the
		# run stride snaps through the crossing point and hangs at the
		# outstretched extremes, without touching _walk_phase's own linear
		# accumulation above. Equal to _walk_phase while walking, so walking's
		# timing is unchanged.
		var stride_phase := _walk_phase
		if sprinting:
			stride_phase += SPRINT_STRIDE_EASE * sin(2.0 * _walk_phase)
		var swing := sin(stride_phase) * swing_amount
		_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, swing, cycle_t)
		_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, -swing, cycle_t)
		_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, -swing, arm_cycle_t)
		_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, swing, arm_cycle_t)

		# Knee/elbow flex tied to each limb's own swing *velocity*
		# (cos(phase), how fast swing=sin(phase)*AMOUNT is changing), not
		# its position -- bending in step with position peaks the bend at
		# the exact same instant the swing itself peaks, barely
		# distinguishable from the swing alone.
		#
		# Which half of the cycle counts as "forward" isn't something this
		# rotation.x convention states anywhere -- the previous version
		# just picked cos(phase) > 0 = forward without ever confirming it
		# against the actual rendered motion, the same kind of unverified
		# rotation-sign guess this project has been burned by repeatedly
		# elsewhere (see player.gd's own head-look comments). It was
		# backwards: knees bent on the backswing and straightened on the
		# forward swing, and the same inversion read as arms "bending
		# toward the back." Confirmed backwards by direct observation and
		# fixed by swapping which phase each side of the pair uses (i.e.
		# negating cos(phase)) -- maxf(0, ...) now lands on the half of
		# each limb's own cycle that's actually its forward swing.
		var left_knee_target := maxf(0.0, cos(stride_phase + PI)) * ProceduralFigure.KNEE_BEND_AMOUNT * bend_scale
		var right_knee_target := maxf(0.0, cos(stride_phase)) * ProceduralFigure.KNEE_BEND_AMOUNT * bend_scale
		if sprinting:
			# Per direct instruction, a running stride has a second, distinct
			# knee-bend event that walking doesn't: the planted leg keeps
			# bending deeper through ground contact/loading (this is on top
			# of -- not instead of -- the swing-phase bend above, which
			# already covers the OTHER thing that direct instruction
			# described: the recovery leg swinging forward with a
			# moderate/"somewhat" bent knee).
			#
			# Both bumps use the same maxf(0,cos(...)) shape as the swing
			# bump above, just centered half a cycle (PI) later -- each
			# knee's own swing bump peaks when THIS leg's hip crosses
			# forward through the middle of its swing (stride_phase/
			# stride_phase+PI = 0), and the new stance bump peaks half a
			# cycle after that, when this same leg's hip is vertical under
			# the body (stride_phase/stride_phase+PI = PI) -- i.e. mid
			# ground-contact, matches "lands...knee bent, continues to bend
			# a bit more deeply" through to being under the body before the
			# leg starts its push-off/swing back out.
			#
			# KNEE_STANCE_BEND_AMOUNT deliberately is NOT the same constant
			# as KNEE_BEND_AMOUNT: worked out algebraically, maxf(0,cos(x))
			# + maxf(0,cos(x+PI)) is a period-PI function of x -- so if both
			# bumps shared one amplitude, adding a same-size second bump to
			# each knee would produce the exact same combined curve for
			# BOTH knees regardless of which leg is which, erasing the
			# left/right distinction the hip swing otherwise carries (both
			# knees would bend in lockstep instead of alternating). Distinct
			# amplitudes keep the two knees visibly different at any given
			# instant, matching how the swing and stance events actually
			# read as different in character, not just timing.
			left_knee_target += maxf(0.0, cos(stride_phase)) * KNEE_STANCE_BEND_AMOUNT * bend_scale
			right_knee_target += maxf(0.0, cos(stride_phase + PI)) * KNEE_STANCE_BEND_AMOUNT * bend_scale
		_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, left_knee_target, cycle_t)
		_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, right_knee_target, cycle_t)
		# Elbows use a different curve shape from the knees, per direct
		# instruction: a knee stays flat/straight through its entire
		# backswing (weight-bearing stance), but an arm's backswing should
		# mirror its forward swing instead -- bending and easing back to
		# resting the same way on both halves, not just the forward one.
		#
		# Per a further direct correction, the backswing isn't a mirrored
		# peak after all: the backmost point of the backswing should be the
		# LEAST bent, increasing progressively to the MOST bent at the
		# forwardmost point of the swing -- once per cycle, not twice
		# (abs(sin(phase)), the previous formula, peaked equally at BOTH
		# extremes). Since the two arms are always in opposite phase (one
		# forward while the other's back), they can no longer share a single
		# value the way the old symmetric formula could -- each arm now
		# needs its own forward_fraction (0 at that arm's own backmost
		# point, 1 at its own forwardmost).
		#
		# arm_right.rotation.x is `swing` -- but positive rotation.x on this
		# pivot is BACKWARD, not forward (confirmed by direct observation on
		# the jump pose, see _animate_airborne's own comment). An earlier
		# version of this formula assumed the opposite sign, unverified, and
		# got the whole bend curve inverted -- most bend at the backswing's
		# apex, least at the forward apex, exactly backwards from what was
		# asked for. So the right arm's own forward-ness is HIGH when swing
		# is NEGATIVE, and the left arm (rotation.x = -swing) is forward-most
		# when swing is POSITIVE -- the opposite pairing from before.
		var right_forward_fraction := (1.0 - sin(stride_phase)) * 0.5
		var left_forward_fraction := 1.0 - right_forward_fraction
		var elbow_min_fraction := SPRINT_ELBOW_MIN_FRACTION if sprinting else 0.0
		var elbow_bend_range := 1.0 - elbow_min_fraction
		var right_elbow_fraction := elbow_min_fraction + right_forward_fraction * elbow_bend_range
		var left_elbow_fraction := elbow_min_fraction + left_forward_fraction * elbow_bend_range
		var elbow_bend_scale := bend_scale * (SPRINT_ELBOW_EXTRA_BEND if sprinting else 1.0)
		var default_elbow_bend := MonkeyFigure.DEFAULT_ELBOW_BEND if _piloting_xiao_hou_zi else 0.0
		_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, -(default_elbow_bend + right_elbow_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT * elbow_bend_scale), cycle_t)
		_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, -(default_elbow_bend + left_elbow_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT * elbow_bend_scale), cycle_t)

		# Forward spine lean, proportional to speed (full lean only at full
		# move_speed/sprint speed, not a fixed tilt the instant movement
		# starts) -- matches the same "positive rotation.x tilts forward/
		# down" sign player.gd's own head-pitch fix established for this rig
		# (no ancestor 180-degree flip anywhere to invert it), unlike the old
		# figure.glb rig. Sprinting leans further (SPINE_LEAN_MAX_RUN) than
		# walking (SPINE_LEAN_MAX_WALK), per direct instruction.
		var lean_max := SPINE_LEAN_MAX_RUN if sprinting else SPINE_LEAN_MAX_WALK
		var nominal_move_speed := TEMP_MONKEY_MOVE_SPEED if _piloting_xiao_hou_zi else move_speed
		var lean_target := lean_max * clampf(horizontal_speed / nominal_move_speed, 0.0, 1.0)
		_spine.rotation.x = lerp_angle(_spine.rotation.x, lean_target, POSE_SETTLE_SPEED * delta)
		if sprinting:
			# Per direct instruction: the run cycle's ankles actively flex
			# through ground contact, not just settle to neutral -- foot
			# pulled up toward the shin (dorsiflexion) as the planted leg
			# loads, foot pointed back toward the calf (plantarflexion) as
			# that same leg springs off the ground.
			#
			# Sign convention reused from this rig's already-confirmed
			# poses, not re-guessed: _animate_airborne's jump pose points
			# the feet downward with a POSITIVE ANKLE_EXTEND, and
			# _animate_landing's own comment states its ankles are
			# "dorsiflexed the opposite way" using a NEGATIVE
			# LANDING_ANKLE_BEND -- so positive rotation.x = plantarflex
			# (toward the calf), negative = dorsiflex (toward the shin),
			# confirmed by both existing poses agreeing with each other.
			#
			# Same two-bump construction as the stance knee bend above (see
			# its comment for the full derivation): a dorsiflex bump
			# centered on stride_phase = PI (this leg's hip vertical under
			# the body, the loading instant) and a plantarflex bump
			# centered PI/2 later, at stride_phase = 3PI/2 (this leg fully
			# extended back, the toe-off/spring instant). Worked out
			# algebraically for each leg's own phase (stride_phase for the
			# right leg, stride_phase + PI for the left) using cos(x-PI) =
			# -cos(x) and cos(x-3PI/2) = -sin(x). Unlike the knee bumps
			# above, dorsiflex and plantarflex are only PI/2 apart (not PI),
			# so there's no risk of the same left/right-cancelling
			# coincidence that forced the knee bumps to use distinct
			# amplitudes.
			var right_ankle_target := (
				-ANKLE_DORSIFLEX_AMOUNT * maxf(0.0, -cos(stride_phase))
				+ ANKLE_PLANTARFLEX_AMOUNT * maxf(0.0, -sin(stride_phase))
			)
			var left_ankle_target := (
				-ANKLE_DORSIFLEX_AMOUNT * maxf(0.0, cos(stride_phase))
				+ ANKLE_PLANTARFLEX_AMOUNT * maxf(0.0, sin(stride_phase))
			)
			_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, right_ankle_target, cycle_t)
			_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, left_ankle_target, cycle_t)
		else:
			# Ankles aren't part of the ordinary walk cycle -- only ease
			# them back in case a jump/landing pose left them bent.
			_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
			_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		# The idle contrapposto pose's abduction/external-rotation/hip-drop
		# only apply while genuinely idle -- per direct instruction, walking
		# has to reset all three back to level, not leave them frozen at
		# whatever the idle pose last held (the walk cycle above only ever
		# touches rotation.x on the legs, never .y/.z, so without this
		# they'd otherwise just stay wherever idle left them).
		_leg_left.rotation.z = lerp_angle(_leg_left.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)
		_leg_right.rotation.z = lerp_angle(_leg_right.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)
		_leg_left.rotation.y = lerp_angle(_leg_left.rotation.y, 0.0, POSE_SETTLE_SPEED * delta)
		_leg_right.rotation.y = lerp_angle(_leg_right.rotation.y, 0.0, POSE_SETTLE_SPEED * delta)
		_hips.rotation.z = lerp_angle(_hips.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)
		# Upper body height: walking only ever dips (see
		# ProceduralFigure.WALK_BODY_DIP_AMOUNT's own comment for why
		# sin(phase)^2 is the right shape). Set directly, not lerped, like
		# the rest of this phase-driven cycle (swing/knee/elbow above) --
		# it's already a smooth continuous function of _walk_phase, not a
		# discrete target that needs easing into. Applied to the hips too
		# (see _hips_rest_y's own comment), not just the spine -- per direct
		# instruction, the whole upper body should bob together.
		#
		# Running's body-bob per direct instruction: the body is at its
		# LOWEST during ground contact/loading and RISES during the spring/
		# flight phase that follows push-off. cos(2*phase) has the right
		# period (twice per full stride_phase cycle, once per leg's own
		# contact) but the OLD sign had it backwards -- it peaked (rise) at
		# stride_phase=0/PI, which is exactly where the new stance knee/
		# ankle bumps above put ground contact (both legs' hips vertical
		# under the body -- see the stance knee bump's own comment), and
		# dipped at stride_phase=PI/2/3PI/2, roughly where this leg cycle's
		# push-off/flight sits. That's dip-at-flight, rise-at-contact --
		# backwards from what was asked for. Negating it swaps the two:
		# now low at stride_phase=0/PI (contact/loading, matches the knee/
		# ankle bumps peaking at the same points) and high at PI/2/3PI/2
		# (spring/flight).
		var body_motion_scale := TEMP_MONKEY_BODY_MOTION_SCALE if _piloting_xiao_hou_zi else 1.0
		var body_dip := -ProceduralFigure.WALK_BODY_DIP_AMOUNT * body_motion_scale * pow(sin(stride_phase), 2)
		var body_bob := -RUN_BODY_BOB_AMOUNT * body_motion_scale * cos(2.0 * stride_phase)
		var body_offset := body_bob if sprinting else body_dip
		_spine.position.y = _spine_rest_y + body_offset
		# The monkey's pear body is already a child of its spine pivot, unlike
		# the human pelvis. Moving both would apply the offset twice to the body
		# and visibly pull it away from the leg attachments.
		_hips.position.y = _hips_rest_y if _piloting_xiao_hou_zi else _hips_rest_y + body_offset
		_was_moving = true
	else:
		_walk_cycle_recovery = 1.0
		# Re-rolls a fresh idle pose exactly once per moving-to-idle
		# transition (not every idle frame, which would jitter, and not
		# just once at spawn, which would make it a fixed quirk instead
		# of natural variety) -- see _roll_idle_pose().
		if _was_moving:
			_roll_idle_pose()
			_was_moving = false
		var bent_knee := _knee_right if _idle_bent_leg_side > 0.0 else _knee_left
		var straight_knee := _knee_left if _idle_bent_leg_side > 0.0 else _knee_right
		var bent_leg := _leg_right if _idle_bent_leg_side > 0.0 else _leg_left
		var straight_leg := _leg_left if _idle_bent_leg_side > 0.0 else _leg_right
		var knee_target := _idle_knee_bend if _idle_leg_variant_active else 0.0
		# Use the pivot's real X side, not the semantic "bent side" selector:
		# the latter picks a named left/right limb but is not the sign convention
		# for a Z-axis abduction. This keeps the extra idle bend travelling away
		# from the body on either leg instead of occasionally folding inward.
		var leg_z_target := (
			signf(bent_leg.position.x) * IDLE_HIP_OUTWARD_ANGLE if _idle_leg_variant_active else 0.0
		)
		var leg_y_target := (
			signf(bent_leg.position.x) * IDLE_HIP_EXTERNAL_ROTATION if _idle_leg_variant_active else 0.0
		)
		var hip_z_target := (
			-_idle_bent_leg_side * IDLE_HIP_DROP_ANGLE if _idle_leg_variant_active else 0.0
		)

		_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		bent_knee.rotation.x = lerp_angle(bent_knee.rotation.x, knee_target, POSE_SETTLE_SPEED * delta)
		straight_knee.rotation.x = lerp_angle(straight_knee.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		bent_leg.rotation.z = lerp_angle(bent_leg.rotation.z, leg_z_target, POSE_SETTLE_SPEED * delta)
		straight_leg.rotation.z = lerp_angle(straight_leg.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)
		# External rotation (turns the knee/toe themselves outward, not
		# just the whole leg swung sideways) -- per direct correction, a
		# true contrapposto needs both.
		bent_leg.rotation.y = lerp_angle(bent_leg.rotation.y, leg_y_target, POSE_SETTLE_SPEED * delta)
		straight_leg.rotation.y = lerp_angle(straight_leg.rotation.y, 0.0, POSE_SETTLE_SPEED * delta)
		_hips.rotation.z = lerp_angle(_hips.rotation.z, hip_z_target, POSE_SETTLE_SPEED * delta)
		# Very slight, independently-randomized relaxed elbow bend, always on
		# (not gated by IDLE_LEG_VARIANT_CHANCE the way the leg variant is) --
		# per direct instruction, standing idle should never look like both
		# arms hang in perfect lockstep.
		var idle_elbow_base := -MonkeyFigure.DEFAULT_ELBOW_BEND if _piloting_xiao_hou_zi else 0.0
		_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, idle_elbow_base + _idle_elbow_left, POSE_SETTLE_SPEED * delta)
		_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, idle_elbow_base + _idle_elbow_right, POSE_SETTLE_SPEED * delta)
		_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		_spine.rotation.x = lerp_angle(_spine.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		_spine.position.y = lerp(_spine.position.y, _spine_rest_y, POSE_SETTLE_SPEED * delta)
		_hips.position.y = lerp(_hips.position.y, _hips_rest_y, POSE_SETTLE_SPEED * delta)


## Airborne pose follows the jump's actual vertical arc. Legs progressively
## tuck as upward speed burns off, reach the existing maximum fold only at
## the apex, then open into a relaxed-but-bent descent before the impact.
func _animate_airborne(delta: float) -> void:
	var reference_speed := maxf(_jump_takeoff_speed, jump_velocity)
	var apex_fraction: float
	if velocity.y >= 0.0:
		# Take-off (1.0 upward speed) -> 0 tuck; apex (0 upward speed) ->
		# the complete crouched silhouette. smoothstep avoids a robotic,
		# linear joint rotation through the flight.
		apex_fraction = 1.0 - smoothstep(0.0, reference_speed, velocity.y)
	else:
		# The full tuck releases only after the apex. Descending faster than
		# three quarters of the take-off speed settles into the relaxed pose.
		apex_fraction = 1.0 - smoothstep(0.0, reference_speed * 0.75, -velocity.y)
	_apply_airborne_pose(delta, apex_fraction)


## The common relaxed floating pose is precisely the fully-released jump
## descent pose. Keeping it in the same pose function prevents swimming and
## falling from quietly drifting into separate silhouettes over time.
func _animate_relaxed_floating(delta: float) -> void:
	_apply_airborne_pose(delta, 0.0)


## Swimming begins from the same asymmetric relaxed descent pose used at
## rest, then adds a soft, alternating hip->knee->ankle wave only while the
## player is actually moving through water. This covers the surface and
## helmet-enabled diving states identically.
func _animate_swimming(delta: float) -> void:
	_animate_relaxed_floating(delta)
	var t := JUMP_POSE_SETTLE_SPEED * delta
	# Override the descent pose's mild toe-point with the persistent relaxed
	# flipper angle requested for all water states, including motionless
	# surface floating and idle diving.
	_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, SWIM_FLOAT_ANKLE_EXTEND, t)
	_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, SWIM_FLOAT_ANKLE_EXTEND, t)
	var swim_speed := velocity.length()
	if swim_speed <= 0.1:
		return
	var speed_fraction := clampf(swim_speed / maxf(move_speed, LAKE_DIVE_SPEED), 0.0, 1.0)
	# Fast swimming accelerates the kick substantially rather than merely
	# increasing its amplitude.
	_swim_kick_phase += delta * SWIM_KICK_SPEED * lerpf(0.6, 1.8, speed_fraction)
	var left_wave := sin(_swim_kick_phase)
	var right_wave := -left_wave
	# Positive ankle rotation is this rig's established toe/foot extension
	# toward the calf. Keep a small continuous extension, then pulse it with
	# each leg's propulsive downbeat.
	_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, -DESCENT_HIP_BEND + left_wave * SWIM_KICK_HIP_AMOUNT, t)
	_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, -DESCENT_HIP_BEND + right_wave * SWIM_KICK_HIP_AMOUNT, t)
	_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, DESCENT_KNEE_BEND + maxf(0.0, -left_wave) * SWIM_KICK_KNEE_AMOUNT, t)
	_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, DESCENT_KNEE_BEND + maxf(0.0, -right_wave) * SWIM_KICK_KNEE_AMOUNT, t)
	_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, SWIM_FLOAT_ANKLE_EXTEND + maxf(0.0, left_wave) * SWIM_KICK_ANKLE_AMOUNT, t)
	_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, SWIM_FLOAT_ANKLE_EXTEND + maxf(0.0, right_wave) * SWIM_KICK_ANKLE_AMOUNT, t)
	# Positive shoulder X swings a hanging arm backward (-Z) in this rig.
	# Scale the streamlined posture with speed so a slow float stays relaxed.
	var arm_back := SWIM_FAST_ARM_BACK_SWING * speed_fraction
	var elbow_bend := SWIM_FAST_ELBOW_BEND * speed_fraction
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, arm_back, t)
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, arm_back, t)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, -elbow_bend, t)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, -elbow_bend, t)


func _apply_airborne_pose(delta: float, apex_fraction: float) -> void:
	var t := JUMP_POSE_SETTLE_SPEED * delta
	var hip_bend := lerpf(DESCENT_HIP_BEND, JUMP_HIP_BEND, apex_fraction)
	var knee_bend := lerpf(DESCENT_KNEE_BEND, JUMP_KNEE_BEND, apex_fraction)
	var ankle_extend := lerpf(DESCENT_ANKLE_EXTEND, JUMP_ANKLE_EXTEND, apex_fraction)
	# The descent is relaxed rather than mechanically mirrored: preserve a
	# quieter version of the apex's left/right difference all the way down.
	var asymmetry := lerpf(DESCENT_ASYMMETRY_FRACTION, 1.0, apex_fraction)
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, -(JUMP_ARM_SWING - JUMP_ARM_ASYMMETRY), t)
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, -(JUMP_ARM_SWING + JUMP_ARM_ASYMMETRY), t)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, -(JUMP_ELBOW_BEND - JUMP_ELBOW_ASYMMETRY), t)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, -(JUMP_ELBOW_BEND + JUMP_ELBOW_ASYMMETRY), t)
	_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, -(hip_bend - JUMP_HIP_ASYMMETRY * asymmetry), t)
	_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, -(hip_bend + JUMP_HIP_ASYMMETRY * asymmetry), t)
	_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, knee_bend - JUMP_KNEE_ASYMMETRY * asymmetry, t)
	_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, knee_bend + JUMP_KNEE_ASYMMETRY * asymmetry, t)
	_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, ankle_extend - JUMP_ANKLE_ASYMMETRY * asymmetry, t)
	_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, ankle_extend + JUMP_ANKLE_ASYMMETRY * asymmetry, t)
	_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, ProceduralFigure.ARM_OUTWARD_ANGLE, t)
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, -ProceduralFigure.ARM_OUTWARD_ANGLE, t)
	_spine.rotation.x = lerp_angle(_spine.rotation.x, 0.0, t)
	# No body-bob mid-flight -- only the landing impact itself dips the
	# upper body (see _animate_landing below); easing back to rest here
	# just cleans up any dip/bob still decaying from before takeoff.
	_spine.position.y = lerp(_spine.position.y, _spine_rest_y, t)
	_hips.position.y = lerp(_hips.position.y, _hips_rest_y, t)
	# Idle contrapposto (abduction/external rotation/hip drop) only applies
	# while genuinely idle -- jumping straight out of that pose shouldn't
	# carry it into the air.
	_leg_left.rotation.z = lerp_angle(_leg_left.rotation.z, 0.0, t)
	_leg_right.rotation.z = lerp_angle(_leg_right.rotation.z, 0.0, t)
	_leg_left.rotation.y = lerp_angle(_leg_left.rotation.y, 0.0, t)
	_leg_right.rotation.y = lerp_angle(_leg_right.rotation.y, 0.0, t)
	_hips.rotation.z = lerp_angle(_hips.rotation.z, 0.0, t)


## Tilts the rendered body about the base of the skull, where the neck meets
## the head. The collision body still supplies robust movement and collision,
## but this visual anchor means the skull is the point that leads through the
## water while the torso and legs trail naturally behind it. It is deliberately
## named for aerial movement so flying can reuse this exact mechanic later.
func _update_aerial_body_anchor(delta: float) -> void:
	# Air-foot hover travels in the camera's full 3D direction but retains a
	# normal upright walk/run silhouette. Turn its planar facing toward travel
	# without applying the pitched, trailing-body flight anchor below.
	if _air_foot_hover_active and not _air_flight_active and not _fire_limb_flight_active and not _lake_buoyancy_active:
		if _aerial_motion_direction.length_squared() > 0.001:
			var planar_direction := _aerial_motion_direction
			planar_direction.y = 0.0
			if planar_direction.length_squared() > 0.001:
				var target_yaw := atan2(planar_direction.x, planar_direction.z)
				var target_basis := Basis(Vector3.UP, target_yaw)
				var body_transform := visuals.global_transform
				var t := minf(rotation_speed * delta, 1.0)
				body_transform.basis = Basis(
					body_transform.basis.get_rotation_quaternion().slerp(
						target_basis.get_rotation_quaternion(), t
					)
				)
				visuals.global_transform = body_transform
		visuals.position = visuals.position.lerp(Vector3(0.0, -FOOT_OFFSET, 0.0), minf(AERIAL_BODY_LEAN_SPEED * delta, 1.0))
		_aerial_rest_heading_initialized = false
	elif _lake_buoyancy_active or _air_flight_active or _fire_limb_flight_active:
		var skull_anchor := _head.global_position
		if _aerial_motion_direction.length_squared() > 0.001:
			_aerial_was_moving = true
			# This is a CAMERA-SPACE body transform, not a world-space pitch.
			# The fixed trailing angle is therefore measured from the skull's
			# viewed direction regardless of which way gravity/the horizon lies.
			# Visuals faces +Z while a Camera3D views -Z, hence the 180° Y turn.
			# At the surface, movement is deliberately yaw-only, so use the
			# camera rig's level basis. Diving and flight retain the camera's
			# full pitch for true 3D travel.
			var travel_camera_basis := camera.global_transform.basis if (_lake_diving_active or _air_flight_active or _fire_limb_flight_active) else camera_rig.global_transform.basis
			var camera_body_basis := travel_camera_basis * Basis(Vector3.UP, PI)
			# The left stick still chooses the travel-facing direction IN camera
			# space: forward=0, right=+90, back=180, left=-90. Previously the
			# camera-space lean ignored this turn, so backing toward the camera
			# moved correctly but left the body facing away from its travel.
			# Visuals has the camera-facing 180° basis correction above, which
			# mirrors this local yaw convention; negate stick X so forward-left
			# aims the body forward-left rather than its reflected right side.
			var stick_turn := atan2(-_aerial_strafe_input, -_get_move_input().y)
			var travel_turn_basis := Basis(Vector3.UP, stick_turn)
			var trailing_basis := Basis(Vector3.RIGHT, AERIAL_BODY_CRUISE_LEAN)
			var roll_basis := Basis(Vector3.FORWARD, -_aerial_strafe_input * AERIAL_BODY_ROLL_MAX)
			var target_rotation := (camera_body_basis * travel_turn_basis * trailing_basis * roll_basis).get_rotation_quaternion()
			var t := minf(AERIAL_BODY_LEAN_SPEED * delta, 1.0)
			var body_transform := visuals.global_transform
			body_transform.basis = Basis(body_transform.basis.get_rotation_quaternion().slerp(target_rotation, t))
			visuals.global_transform = body_transform
		else:
			# Capture the body's own current planar heading exactly once as input
			# stops. The relaxed pose should return upright around THIS heading,
			# never turn to face the camera merely because the active dive pose
			# was camera-space.
			if _aerial_was_moving or not _aerial_rest_heading_initialized:
				var planar_forward := visuals.global_transform.basis.z
				planar_forward.y = 0.0
				if planar_forward.length_squared() > 0.001:
					_aerial_rest_yaw = atan2(planar_forward.x, planar_forward.z)
				else:
					_aerial_rest_yaw = visuals.rotation.y
				_aerial_was_moving = false
				_aerial_rest_heading_initialized = true
			var t := minf(AERIAL_BODY_REST_SPEED * delta, 1.0)
			var upright_transform := visuals.global_transform
			upright_transform.basis = Basis(Vector3.UP, _aerial_rest_yaw)
			upright_transform.basis = Basis(upright_transform.basis.get_rotation_quaternion())
			var current_transform := visuals.global_transform
			current_transform.basis = Basis(current_transform.basis.get_rotation_quaternion().slerp(upright_transform.basis.get_rotation_quaternion(), t))
			visuals.global_transform = current_transform
		# Rotating Visuals normally pivots around its feet. Restore the head
		# after that rotation, making the neck/head junction the real visual
		# pivot without changing the collision shape's stable feet origin.
		visuals.global_position += skull_anchor - _head.global_position
	else:
		_aerial_rest_heading_initialized = false
		# Leaving water is a hard transition back to gravity: do not retain the
		# deliberately slow buoyant unwind once the body has emerged. Wing-suit
		# removal in midair retains its own short physical recovery instead. That
		# recovery must slerp toward an explicitly upright WORLD basis; clearing
		# local Euler X/Z independently can make a steep flight basis decompose to
		# the opposite Y solution and turn the character around toward the camera.
		if _air_flight_exit_recovery <= 0.0:
			visuals.rotation.x = 0.0
			visuals.rotation.z = 0.0
			visuals.position = Vector3(0.0, -FOOT_OFFSET, 0.0)
		else:
			var t := minf(AERIAL_BODY_LEAN_SPEED * delta, 1.0)
			var upright_basis := Basis(Vector3.UP, _air_flight_exit_yaw)
			var body_transform := visuals.global_transform
			body_transform.basis = Basis(
				body_transform.basis.get_rotation_quaternion().slerp(
					upright_basis.get_rotation_quaternion(), t
				)
			)
			visuals.global_transform = body_transform
			visuals.position = visuals.position.lerp(Vector3(0.0, -FOOT_OFFSET, 0.0), t)
			_air_flight_exit_recovery = maxf(_air_flight_exit_recovery - delta, 0.0)


## Landing impact reaction -- see LANDING_* consts above. Fast-eases into a
## symmetric crouch (hips/knees flexed deeper than the jump pose, ankles
## dorsiflexed the opposite way from it) with a forward spine lean AND an
## actual dip in the upper body's height (LANDING_BODY_DIP_AMOUNT, per
## direct instruction -- rotation alone wasn't selling the impact), then
## _landing_timer running out hands control back to the ordinary grounded
## branches above, which ease everything (including the body height) back
## to neutral -- no separate ease-out state needed since that lerp is
## already gentle.
func _animate_landing(delta: float) -> void:
	var t := LANDING_SETTLE_SPEED * delta
	var landing_motion_scale := TEMP_MONKEY_BODY_MOTION_SCALE if _piloting_xiao_hou_zi else 1.0
	var landing_dip := LANDING_BODY_DIP_AMOUNT * landing_motion_scale
	_spine.rotation.x = lerp_angle(_spine.rotation.x, LANDING_SPINE_LEAN, t)
	_spine.position.y = lerp(_spine.position.y, _spine_rest_y - landing_dip, t)
	# MonkeyFigure's pear body is already beneath the moving spine. Applying
	# the landing offset to both would double its sink and detach it from the
	# short legs, just like the earlier walk-bob issue.
	var hips_landing_y := _hips_rest_y if _piloting_xiao_hou_zi else _hips_rest_y - landing_dip
	_hips.position.y = lerp(_hips.position.y, hips_landing_y, t)
	_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, -LANDING_HIP_BEND, t)
	_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, -LANDING_HIP_BEND, t)
	_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, LANDING_KNEE_BEND, t)
	_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, LANDING_KNEE_BEND, t)
	_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, -LANDING_ANKLE_BEND, t)
	_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, -LANDING_ANKLE_BEND, t)
	# Arms stay in their airborne bend to counter the impact instead of
	# collapsing to the sides. The shoulder spread is the visible brace.
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, -(JUMP_ARM_SWING - JUMP_ARM_ASYMMETRY), t)
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, -(JUMP_ARM_SWING + JUMP_ARM_ASYMMETRY), t)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, -(JUMP_ELBOW_BEND - JUMP_ELBOW_ASYMMETRY), t)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, -(JUMP_ELBOW_BEND + JUMP_ELBOW_ASYMMETRY), t)
	_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, LANDING_ARM_OUTWARD_ANGLE, t)
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, -LANDING_ARM_OUTWARD_ANGLE, t)
	_leg_left.rotation.z = lerp_angle(_leg_left.rotation.z, 0.0, t)
	_leg_right.rotation.z = lerp_angle(_leg_right.rotation.z, 0.0, t)
	_leg_left.rotation.y = lerp_angle(_leg_left.rotation.y, 0.0, t)
	_leg_right.rotation.y = lerp_angle(_leg_right.rotation.y, 0.0, t)
	_hips.rotation.z = lerp_angle(_hips.rotation.z, 0.0, t)


const MAX_TERRAIN_FOLLOW_HEIGHT := 3.0

## Lake buoyancy deliberately shares the giant's direct positional lift
## instead of adding a collision plane. A collision plane would make the
## lake behave like solid ground; this keeps the player visibly immersed and
## simply settles them at a chest-deep swimming height. The giant takes
## precedence should its footprint ever overlap the lake.
func _update_lake_buoyancy(delta: float) -> void:
	_lake_buoyancy_active = false
	_lake_diving_active = false
	_lake_water_walk_active = false
	if _giant_goo_active or terrain == null:
		return
	var water_pos := Vector2(global_position.x, global_position.z)
	if not terrain.is_lake_area(water_pos):
		return
	var water_level: float = terrain.get_lake_water_level()
	var floor_height: float = terrain.get_mesh_height(water_pos.x, water_pos.y)
	# The shallow feathered shoreline stays walkable. Buoyancy begins only
	# once the basin has enough real depth to immerse the character.
	if water_level - floor_height < LAKE_MIN_SWIMMABLE_DEPTH:
		return
	# Dock ramps deliberately start below the swimmer's feet. Once one is
	# beneath the player, let its continuous climbable collision take over
	# rather than pulling the player back down to the swim depth every frame.
	if _is_on_climbable_ramp():
		return
	# A pair of water blorbs worn on the legs makes the lake surface a
	# temporary floor. It intentionally wins over a diving helmet: taking
	# those two leg pieces off is the deliberate way to dive again. Jumps
	# are allowed to break the surface and are caught on descent exactly as
	# ordinary terrain jumps are.
	if _blorb_suit.has_water_walking_legs():
		if _jumping and (velocity.y > 0.0 or global_position.y - FOOT_OFFSET > water_level):
			return
		if global_position.y - FOOT_OFFSET > water_level:
			return
		_jumping = false
		_lake_water_walk_active = true
		global_position.y = water_level + FOOT_OFFSET
		velocity.y = 0.0
		return
	# A landed head blorb is a sealed, inflated diving helmet. It replaces
	# the ordinary chest-deep buoyancy cap with free three-dimensional swim
	# movement, bounded only by the lake floor and the same surface height
	# an unhelmeted swimmer floats at. A worn chest air blorb gets the same
	# treatment while actually submerged: flying must not override swimming,
	# per direct correction. Once its climb carries the player back above
	# the surface, this returns early and hands off to the ordinary flight
	# controller, which can then continue straight up out of the water.
	if _blorb_suit.has_head_diving_helmet() or _blorb_suit.has_chest_air_blorb():
		if global_position.y > water_level:
			return
		_jumping = false
		_lake_buoyancy_active = true
		_lake_diving_active = true
		var dive_floor := floor_height + LAKE_DIVE_FLOOR_CLEARANCE
		var dive_surface := water_level - LAKE_SWIM_FOOT_DEPTH
		global_position.y = clampf(global_position.y, dive_floor, dive_surface)
		return
	var swim_y := water_level - LAKE_SWIM_FOOT_DEPTH
	# Let a jump break the surface normally, but catch the player again as
	# soon as their descending feet re-enter the water. Without clearing this
	# flag, an underwater jump could remain an endless gravity fall all the
	# way to the lake floor.
	if _jumping:
		if velocity.y > 0.0 or global_position.y > water_level:
			return
		_jumping = false
	if global_position.y > water_level:
		return
	_lake_buoyancy_active = true
	global_position.y = move_toward(global_position.y, swim_y, LAKE_BUOYANCY_LIFT_SPEED * delta)
	velocity.y = 0.0


## A chest-mounted air blorb is the first flight prototype. Equipping it
## lifts the player half a metre into a neutral hover; after that, the same
## camera-relative 3D movement path as diving supplies free flight. Runs
## after _update_lake_buoyancy() each frame, so _lake_diving_active already
## reflects whether the player is currently submerged wearing this same
## piece -- the initial hover lift is skipped in that case so equipping the
## chest blorb underwater doesn't yank the player straight up out of the
## lake; swimming still wins until they actually surface on their own.
func _update_air_flight() -> void:
	_air_flight_active = _blorb_suit.has_chest_air_blorb()
	if _air_flight_active:
		_jumping = false
		if not _was_air_flight_active and not _lake_diving_active:
			var ground_height: float = terrain.get_mesh_height(global_position.x, global_position.z)
			global_position.y = maxf(global_position.y, ground_height + FOOT_OFFSET + AIR_FLIGHT_HOVER_HEIGHT)
	_was_air_flight_active = _air_flight_active


func _update_suit_flight_transition() -> void:
	var suit_flight := _is_suit_flight_active()
	if _was_suit_flight_active and not suit_flight:
		# Capture the rendered body's real world-space forward vector BEFORE the
		# aerial anchor is released. Do not use visuals.rotation.y here: flight
		# permits near-vertical pitch and roll, for which the equivalent Euler
		# representation can be 180 degrees away from the visible heading.
		var planar_forward := visuals.global_transform.basis.z
		planar_forward.y = 0.0
		_air_flight_exit_yaw = (
			atan2(planar_forward.x, planar_forward.z)
			if planar_forward.length_squared() > 0.001
			else _aerial_target_yaw
		)
		_air_flight_exit_recovery = AIR_FLIGHT_EXIT_RECOVERY_DURATION
	_was_suit_flight_active = suit_flight


## Finds the sole Size blorb and moves the player through its true
## profile-defined goo volume. The giant occupies only the dedicated thrown-
## item layer (outside the player's collision mask), so this replaces a
## spherical collision/bounce with a viscous lift to its rendered surface.
func _update_giant_goo_state(delta: float) -> void:
	_giant_goo_active = false
	_giant_surface_grounded = false
	var giant: Blorb = null
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if candidate is Blorb and (candidate as Blorb).blorb_type == "size":
			giant = candidate as Blorb
			break
	if giant == null:
		_giant_anchor = null
		return
	# Reconstruct the rider's world position from its last local coordinate
	# before evaluating this frame's goo/surface state. This carries them
	# with the giant's translation and yaw as it slowly glides and turns.
	if _giant_anchor == giant:
		global_position = giant.to_global(_giant_anchor_local_position)
		var yaw_delta := wrapf(giant.global_rotation.y - _giant_anchor_yaw, -PI, PI)
		visuals.rotation.y = wrapf(visuals.rotation.y + yaw_delta, -PI, PI)
		camera_rig.rotation.y = wrapf(camera_rig.rotation.y + yaw_delta, -PI, PI)
	# A hot-reloaded giant can retain the old solid world layer. Restore its
	# throwable-only layer before move_and_slide(): gems still detect it, but
	# the player's layer-1 mask can pass into the goo without obstruction.
	giant.collision_layer = Blorb.GIANT_THROWABLE_LAYER

	var top: Variant = giant.giant_surface_height_at(global_position.x, global_position.z)
	if top == null:
		_giant_anchor = null
		return
	var stand_y := (top as float) + FOOT_OFFSET
	var inside_goo := giant.contains_player_majority(global_position, PLAYER_CAPSULE_HEIGHT)
	# A person walking across the wasteland floor reaches the giant from
	# below its broad, ground-sunken mesh. Crossing into that real visible
	# footprint must begin the lift immediately, even before a full capsule
	# overlap can accumulate on its steep lower curve.
	inside_goo = inside_goo or global_position.y < stand_y
	# The player's capsule midpoint sits above the translucent surface once
	# they have risen out of it, so retain the surface state independently of
	# the volume test that initiated the lift.
	# The upper mesh is curved; a generous tolerance lets normal walking
	# across adjacent triangles remain grounded long enough to re-snap to the
	# exact profile, rather than dropping to an ordinary terrain jump.
	var at_surface := absf(global_position.y - stand_y) < GIANT_SURFACE_SNAP_TOLERANCE
	if not inside_goo and not at_surface:
		_giant_anchor = null
		return
	_giant_anchor = giant
	if _jumping:
		# A superjump that started on the giant returns to its exact mesh
		# surface. A normal jump started from the wasteland floor inside the
		# goo has this flag false, so it can never be teleported upward.
		if _giant_surface_jump_in_progress and velocity.y <= 0.0 and global_position.y <= stand_y:
			# Settle a little way into the gel on landing, then allow the normal
			# viscous lift below to bring the player back to the exact surface.
			global_position.y = stand_y - GIANT_SURFACE_LANDING_SINK_DEPTH
			velocity.y = 0.0
			_jumping = false
			_giant_surface_jump_in_progress = false
			_giant_surface_grounded = true
			_giant_goo_active = true
		return

	_giant_goo_active = true
	if global_position.y < stand_y:
		var lift_speed := GIANT_SURFACE_RECOVERY_SPEED if at_surface else GIANT_GOO_LIFT_SPEED
		if _giant_goo_jump_lift_timer > 0.0:
			_giant_goo_jump_lift_timer = maxf(_giant_goo_jump_lift_timer - delta, 0.0)
			lift_speed = GIANT_GOO_JUMP_LIFT_SPEED
		global_position.y = move_toward(global_position.y, stand_y, lift_speed * delta)
		velocity.y = 0.0
		return
	global_position.y = stand_y
	velocity.y = 0.0
	_giant_surface_grounded = true


## Captures the rider's final position after their own movement for use on
## the next physics frame, when the giant may have moved or turned. Do not
## carry a launched superjumper: once airborne, they are no longer in/on it.
func _store_giant_attachment() -> void:
	if _giant_anchor == null or _jumping:
		if _jumping:
			_giant_anchor = null
		return
	_giant_anchor_local_position = _giant_anchor.to_local(global_position)
	_giant_anchor_yaw = _giant_anchor.global_rotation.y


## Direct mesh-height check used on the exact input frame. This avoids a
## normal jump when the player is visibly on the giant but the previous
## frame's movement has not yet refreshed _giant_surface_grounded.
func _is_on_giant_mesh_surface() -> bool:
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not (candidate is Blorb and (candidate as Blorb).blorb_type == "size"):
			continue
		var giant := candidate as Blorb
		var top: Variant = giant.giant_surface_height_at(global_position.x, global_position.z)
		if top == null:
			return false
		return absf(global_position.y - ((top as float) + FOOT_OFFSET)) < GIANT_SURFACE_SNAP_TOLERANCE
	return false


# Deliberately much tighter than MAX_TERRAIN_FOLLOW_HEIGHT: that threshold is
# for "close enough to snap onto while walking", which a jump arc satisfies
# almost immediately after leaving the ground -- using it to decide when a
# jump has *landed* cleared _jumping at the apex, letting the very next
# physics frame's snap teleport the character straight down instead of
# actually falling. This one only turns true once genuinely near the ground.
const LANDING_HEIGHT_THRESHOLD := 0.3


func _is_near_ground() -> bool:
	var h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	var threshold := (
		LANDING_HEIGHT_THRESHOLD * TEMP_MONKEY_HEIGHT_RATIO
		if _piloting_xiao_hou_zi else LANDING_HEIGHT_THRESHOLD
	)
	return (global_position.y - FOOT_OFFSET) - h < threshold


func _is_touching_terrain() -> bool:
	# Only the ground itself should snap to the terrain height -- standing
	# on a rock, tree stump, or (now that TownProps bakes in real floor/roof
	# collision) a building's upper story or rooftop must NOT get yanked
	# down to ground level just because that's what's under it. This alone
	# only keeps that promise while ALREADY grounded, though -- see the
	# _grounded_grace_timer guard on this function's own call site in
	# _physics_process, and _try_step_up()'s own drift guard, for the two
	# other places that promise still has to be kept.
	# get_slide_collision_count() looks like the more "correct" way to check
	# this, but it only reflects active collision *events* -- once the
	# character comes to rest, it drops to zero even though is_on_floor()
	# stays true via floor snapping, which disabled this entirely right
	# when it was needed. A height-threshold check has no such gap.
	var h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	return (global_position.y - FOOT_OFFSET) - h < MAX_TERRAIN_FOLLOW_HEIGHT


## How far the current position is allowed to already be from the analytic
## terrain height before _try_step_up() below trusts that gap as real
## terrain-following drift worth auto-correcting, rather than the player
## genuinely resting on some taller separate platform (a rock, a roof, an
## upper floor...) that just happens to be within _is_touching_terrain()'s
## own much looser 3m band. Comfortably above any drift a frame of ordinary
## walking could produce, and comfortably below the shortest thing anyone's
## meant to stand on.
const STEP_CORRECT_MAX_DRIFT := 0.5


## Detects the dedicated continuous-ramp collision layer beneath the player's
## feet. Every actual ramp shares it: city fire escapes, village roof ramps,
## and wilderness rock ramps. This short downward probe remains stable through
## one-frame floor-contact flicker at a ramp/landing transition.
func _is_on_climbable_ramp() -> bool:
	var space_state := get_world_3d().direct_space_state
	var from := global_position + Vector3.UP * 0.35
	var to := global_position - Vector3.UP * 0.9
	var query := PhysicsRayQueryParameters3D.create(from, to, TownProps.BLORB_CLIMBABLE_LAYER)
	query.exclude = [self]
	return not space_state.intersect_ray(query).is_empty()


func _try_step_up() -> void:
	# Snapping to the exact height at the CURRENT position first removes any
	# small drift between the collision surface and the snap before the
	# move is even attempted; the lookahead on top pre-lifts for climbs so
	# move_and_slide() doesn't treat the rise ahead as a wall.
	#
	# That snap used to be unconditional -- fine as long as "grounded" could
	# only ever mean "on the analytic terrain surface," but once real,
	# taller platforms (see _is_touching_terrain()'s own comment) entered
	# the picture, an unconditional snap here silently overwrote a correct
	# landing on one of those with the ground height instead, the instant
	# _is_touching_terrain() also happened to be true. See
	# STEP_CORRECT_MAX_DRIFT's own comment for why a large gap means "don't
	# touch this."
	var current_h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	if absf((global_position.y - FOOT_OFFSET) - current_h) > STEP_CORRECT_MAX_DRIFT:
		return
	global_position.y = current_h + FOOT_OFFSET
	velocity.y = 0.0

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() < 0.1:
		return
	var move_dir := horizontal.normalized()
	var probe := global_position + move_dir * STEP_LOOKAHEAD
	var ahead_h: float = terrain.get_mesh_height(probe.x, probe.z)
	var rise := ahead_h - current_h
	if rise <= 0.02:
		return
	if rise / STEP_LOOKAHEAD > GROUND_SNAP_MAX_SLOPE:
		return
	global_position.y += rise


## How high a nearby solid physics object (a canyon slab's edge, and
## similar) can be above the player's current feet before it counts as
## "just step onto it" rather than something that actually needs a jump.
## Comfortably above a canyon floor slab's own exposed height above ground
## (roughly 0.3-0.6m -- thickness 0.4-0.9m, embedded 30% into the ground,
## see NatureProps.build_rock_slab()) so ordinary paving doesn't need a
## hop, while staying well under anything meant to require an actual jump
## (a crate, a hoodoo tier, a ramp's own landing).
const PROP_STEP_MAX_HEIGHT := 0.7
## How far above PROP_STEP_MAX_HEIGHT the downward probe starts from --
## just needs to clear the tallest surface this is willing to step onto.
const PROP_STEP_PROBE_CLEARANCE := 0.3


## Auto-steps the player up onto a real physics object just ahead (a
## slab's edge, and similar) that _try_step_up() above has no way to see,
## since it only ever reads terrain.get_mesh_height() -- the analytic
## ground function, which knows nothing about anything actually built or
## placed on top of it. A short downward raycast just ahead of the
## player's own feet, not a forward raycast against the object's side --
## reading the walkable TOP surface directly is what makes this genuinely
## step onto it rather than just detecting a wall: nothing here touches
## the player's XZ, only pre-lifts Y (same trick _try_step_up() itself
## uses) so move_and_slide() right after resolves the move as walking
## onto a floor instead of bumping into the slab's side.
func _try_step_onto_prop() -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() < 0.1:
		return
	var move_dir := horizontal.normalized()
	var foot_y := global_position.y - FOOT_OFFSET
	var probe := global_position + move_dir * STEP_LOOKAHEAD

	var space_state := get_world_3d().direct_space_state
	var from := Vector3(probe.x, foot_y + PROP_STEP_MAX_HEIGHT + PROP_STEP_PROBE_CLEARANCE, probe.z)
	var to := Vector3(probe.x, foot_y, probe.z)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return

	# Explicit : float, not := -- result is an untyped Dictionary
	# (PhysicsDirectSpaceState3D.intersect_ray()'s own return type), so
	# GDScript can't infer .position's type through dot-access on it any
	# more than it could through a bracket subscript (see blorb.gd's
	# _ground_height_at() and wilderness_scatter.gd's _pave_canyon_floor()
	# for the same pitfall already hit twice this session).
	var hit_y: float = result.position.y
	var rise := hit_y - foot_y
	if rise <= 0.02 or rise > PROP_STEP_MAX_HEIGHT:
		return
	global_position.y += rise
	velocity.y = 0.0


func _snap_to_terrain(delta: float) -> void:
	if not _is_touching_terrain():
		return
	var target_h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	var rise: float = target_h - (global_position.y - FOOT_OFFSET)
	var run := maxf(Vector2(velocity.x, velocity.z).length() * delta, 0.001)
	if absf(rise) / run > GROUND_SNAP_MAX_SLOPE:
		return
	global_position.y = target_h + FOOT_OFFSET
	velocity.y = 0.0


## Same active re-anchoring _snap_to_terrain() does against the analytic
## ground height, but against a cloud's own real support height at the
## player's current (post-move) XZ instead -- called only while already
## grounded on a cloud this frame (see on_cloud's own comment on why a
## multi-puff cloud top needs this: its walkable height can shift from step
## to step near a puff's edge or hand-off, more than a loose proximity
## tolerance alone can track). Returns (falls through to ordinary gravity)
## rather than snapping if there's no cloud directly underneath any more --
## that's a real edge, not a bug to paper over.
func _snap_to_cloud(delta: float) -> void:
	var stand_height: Variant = _cloud_stand_height_at(global_position.x, global_position.z, global_position.y - FOOT_OFFSET + 0.6)
	if stand_height == null:
		return
	var target_h := (stand_height as float) - FOOT_OFFSET
	var rise := target_h - (global_position.y - FOOT_OFFSET)
	var run := maxf(Vector2(velocity.x, velocity.z).length() * delta, 0.001)
	if absf(rise) / run > GROUND_SNAP_MAX_SLOPE:
		return
	global_position.y = stand_height as float
	velocity.y = 0.0


func _is_sprinting() -> bool:
	# "run" (see input_map.gd) covers Option/Alt for keyboard (all
	# platforms, including Mac -- see that file's own comment on why not
	# Command there), the A button for gamepad.
	return Input.is_action_pressed("run")


## Blorb skates only engage while the player is running and both leg
## coverings are visibly equipped; walking with the same two blorbs stays at
## ordinary walking speed.
func _is_blorb_skating() -> bool:
	return _is_sprinting() and _blorb_suit.has_blorb_skates()


## Root Y required to stand slightly embedded in a one-way cloud surface.
## CloudScatter returns only tops no higher than the supplied ceiling, which
## is what preserves pass-through behavior from below.
func _cloud_stand_height_at(x: float, z: float, max_surface_y: float) -> Variant:
	var clouds := get_node_or_null("../Clouds") as CloudScatter
	if clouds == null:
		return null
	var top: Variant = clouds.get_support_height_at(x, z, max_surface_y)
	if top == null:
		return null
	return (top as float) + FOOT_OFFSET - CLOUD_SINK_DEPTH


## Root Y required to stand slightly embedded in a one-way tree canopy --
## same reasoning as _cloud_stand_height_at() above, just a shallower sink
## (see TREE_CANOPY_SINK_DEPTH).
func _tree_canopy_stand_height_at(x: float, z: float, max_surface_y: float) -> Variant:
	# Duck-typed rather than `as WildernessScatter` -- kingdom scenes (see
	# jungle_kingdom_foliage.gd) implement the same get_support_height_at()
	# contract on their own "Scatter" sibling without being a
	# WildernessScatter themselves (that class carries a mountain of
	# outskirts-only logic no kingdom scene needs).
	var scatter := get_node_or_null("../Scatter")
	if scatter == null or not scatter.has_method("get_support_height_at"):
		return null
	var top: Variant = scatter.get_support_height_at(x, z, max_surface_y)
	if top == null:
		return null
	return (top as float) + FOOT_OFFSET - TREE_CANOPY_SINK_DEPTH


func _get_move_input() -> Vector2:
	# "move_left/right/forward/back" (see input_map.gd) cover WASD and the
	# gamepad left stick together; get_vector combines them into one
	# length-1-clamped vector.
	if UIState.modal_open:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_forward", "move_back", joy_deadzone)


func _apply_gamepad_look(delta: float) -> void:
	# Mouse look is handled separately in _unhandled_input (see its own
	# comment on why raw motion can't go through the Input Map) -- this
	# covers the gamepad right stick via "look_left/right/up/down", feeding
	# the same _rotate_camera() the mouse path uses.
	if UIState.modal_open:
		return
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down", joy_deadzone)
	if look != Vector2.ZERO:
		_rotate_camera(-look.x * joy_look_sensitivity * delta, -look.y * joy_look_sensitivity * delta)


func _rotate_camera(yaw_delta: float, pitch_delta: float) -> void:
	camera_rig.rotate_y(yaw_delta)
	var pitch_min := AERIAL_CAMERA_PITCH_MIN if _lake_diving_active else PITCH_MIN
	var pitch_max := AERIAL_CAMERA_PITCH_MAX if _lake_diving_active else PITCH_MAX
	camera_pivot.rotation.x = clampf(camera_pivot.rotation.x + pitch_delta, pitch_min, pitch_max)
