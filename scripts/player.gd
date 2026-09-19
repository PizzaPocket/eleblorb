class_name Player
extends CharacterBody3D

const SUN_WU_KONG_SCENE: PackedScene = preload("res://scenes/sun_wu_kong.tscn")

## Third-person controller. Movement is camera-relative; the visual mesh turns
## to face the direction of travel. Works with keyboard/mouse (WASD to move,
## mouse to look) and gamepad (left stick to move, right stick to look) via
## the project's own Input Map actions -- see input_map.gd for the full
## control scheme and how each action's keyboard/mouse and gamepad events
## are registered together.

## Fired whenever current_hp changes (damage or explicit healing) so hud.gd can
## drive its HP readout without polling every frame.
signal hp_changed(current: float, max_value: float)

## The persistent human health pool. It never regenerates passively: food,
## inns and faint recovery are the explicit restoration sources.
const MAX_HP := 100.0

var current_hp: float = MAX_HP

## Fired whenever breath changes (draining or refilling) so hud.gd can show
## a breath meter under the HP one. Per direct instruction: an "air supply"
## system -- currently only underwater submersion without the Diving Helmet
## drains it, but named/checked through _has_air_supply()/_in_airless_area()
## below (not e.g. "has_diving_helmet()" inlined everywhere) specifically so
## a future space biome (no atmosphere, a sealed suit) can extend the exact
## same meter and damage-on-empty behavior later without reworking this.
signal breath_changed(current: float, max_value: float)
const MAX_BREATH := 12.0
const BREATH_DRAIN_RATE := 1.0
## A full meter in 0.4 s: surfacing for a gulp of air refills it almost at once.
const BREATH_REFILL_RATE := 30.0
const BREATH_DAMAGE_INTERVAL := 1.1
const BREATH_DAMAGE_AMOUNT := 4.0
var breath: float = MAX_BREATH
var _breath_damage_timer := 0.0
var _last_emitted_breath_int := -1

@export var move_speed: float = 6.0
@export var sprint_multiplier: float = 1.6
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

## ---- Dirt blorb suit: rear wheel ---- Per direct instruction: a landed
## "ground"-element leg pair (BlorbSuitController.has_dirtbike_legs()) grows
## a big wheel between the feet with "no constraints of traveling up even
## very steep angled terrain," while still launching into the air and
## falling under gravity off a ramp/canyon edge. Implemented as narrowly as
## possible against the existing ground-follow system rather than a parallel
## one: _try_step_up()/_snap_to_terrain() are the only two places that ever
## refuse to follow an ASCENDING slope (their own GROUND_SNAP_MAX_SLOPE
## check), so those two get a dirtbike bypass -- see each call site's own
## comment. The DESCENDING half of _snap_to_terrain()'s check is left
## completely untouched even while riding: that is exactly what already
## turns a steep downhill drop (a ramp's far lip, a canyon edge) into "can't
## snap, falls" instead of "glues to a cliff face," and normal gravity/jump
## airborne handling (already slope- and vehicle-agnostic) takes over from
## there with zero new code -- see this const block's own end for why no
## separate momentum system was needed either.
##
## Purely a visual attachment (see _update_dirtbike_state()), not a suit
## piece threaded through BlorbSuit.equip_slot()/rebuild_slot() -- it isn't
## per-limb tube geometry that needs relofting as a joint moves, just one
## shared prop positioned from a pivot pair each frame, same ownership
## pattern this file already uses for the water/fire foot jets
## (_update_water_streams()).
##
## Built as a solid SuperEgg disk (an oblate spheroid: equal X/Z semi-axes,
## a short Y), not a torus/ring -- per direct correction ("the wheels should
## be disks, not rings... the ring's normals are flipped"). Reusing SuperEgg
## sidesteps that winding bug entirely rather than needing to fix it: it's
## the same well-tested builder every other prop in this project already
## uses, no custom triangle-order math of this file's own to get wrong.
## epsilon=2.0 (this project's minimum -- "don't go below 2," see
## superegg.gd's own class doc) is a deliberate choice, not the more common
## EPSILON_SOFT/EPSILON_FLAT: the equatorial cross-section (the wheel's own
## rim, viewed along the axle) always uses epsilon_top per that same class
## doc, and only epsilon=2 traces a TRUE circle there -- anything higher
## bows the rim toward a rounded square instead, wrong for a wheel.
##
## Both wheels share this one radius -- per direct correction ("the diameter
## of both wheels should be the same") -- which is also exactly what makes
## the wheelie's forward lean necessary in the first place: a same-size
## front wheel mounted up at the wrists starts well clear of the ground, and
## only reaches it once the body leans forward by _solve_dirtbike_wheelie_
## pitch()'s own live-solved angle, below.
## Per direct correction ("wheels diameter is too large, reduce by 20%") --
## was 0.55.
const DIRTBIKE_WHEEL_RADIUS := 0.44
const DIRTBIKE_WHEEL_THICKNESS := DIRTBIKE_WHEEL_RADIUS * 0.6
## Matches blorb.gd's own _apply_element_visuals() "ground" body color
## exactly (Color(0.3, 0.2, 0.1, 0.93) there, alpha dropped since this prop
## is solid/opaque rather than a living blorb's own slight translucency) --
## per direct correction ("they should match the color of the ground
## blorbs"). The project's "ground" element glow/core color is a lighter,
## more yellow-brown (see _element_glow_color()) and is NOT what this
## refers to -- the wheel needs the darker loamy BODY tone specifically.
const DIRTBIKE_WHEEL_COLOR := ElementPalette.GROUND_BODY
## How far past its default (~45 degrees) CharacterBody3D.floor_max_angle is
## raised while riding -- a cheap safety net alongside the snap-function
## bypasses above, so move_and_slide()'s own collision response doesn't
## independently treat a steep-but-not-vertical slope as a wall and resist
## the climb before the analytic Y-snap ever gets a say. Deliberately short
## of 90 degrees: a genuine sheer cliff face should stay unclimbable even on
## the wheel, matching "very steep angled terrain," not literal verticals.
const DIRTBIKE_FLOOR_MAX_ANGLE := deg_to_rad(80.0)
## Per direct correction ("when going up an upslope like the top of a peak
## or top of a canyon or ramp, the expected behavior is that momentum would
## continue and give some air, not immediately snap down on the other side
## of the terrain") -- an ordinary downhill slope (never preceded by a
## climb) still uses GROUND_SNAP_MAX_SLOPE's own ratio check below
## unchanged, so a gentle downhill walk still glues normally. The moment
## _snap_to_terrain() sees the terrain go from ascending to descending right
## under the wheel, though, that specific transition (a true crest -- a
## peak, a canyon lip, a ramp top) preserves the complete measured
## world-space velocity from the final supported frame (see
## _dirtbike_surface_velocity's own comment). This naturally includes both
## speed and angle without reconstructing Y from a terrain sample. From
## there, EVERY subsequent frame runs a real gravity-integrated fall
## compared directly against the actual terrain height (see
## _snap_to_terrain()'s own comment on that) rather than a fixed hang-time
## timer -- per a further direct correction ("even when cresting smaller
## hills at speed he should still get airtime... his downward translation
## should never exceed the speed his body would be falling from gravity"),
## since a fixed timer can't scale hang time to hill size the way comparing
## against real gravity naturally does. DIRTBIKE_ASCEND_TRACK_THRESHOLD
## filters out terrain noise from counting as "was climbing" in the first
## place.
const DIRTBIKE_ASCEND_TRACK_THRESHOLD := 0.02
## How fast the standing/riding leg/arm pose blends toward its target --
## eases the transition into/out of the straddle pose (see
## _apply_dirtbike_pose()) instead of a hard cut. The visual lift itself
## (see DIRTBIKE_WHEEL_RADIUS's own comment) eases at SNOW_VISUAL_SINK_SPEED
## instead, since it is one term of _body_base_height() alongside the snow
## sink rather than a separate write.
const DIRTBIKE_POSE_SETTLE_SPEED := 8.0
## First-draft stance angles for straddling the wheel (think a motocross
## rider's neutral standing position: hips back over the axle, knees bent,
## feet forward on pegs) -- unverified in-engine like every other unspecified
## magnitude in this rig, adjustable on report.
const DIRTBIKE_HIP_BACK_ANGLE := deg_to_rad(18.0)
const DIRTBIKE_KNEE_BEND := deg_to_rad(48.0)
const DIRTBIKE_ANKLE_BEND := deg_to_rad(-24.0)
## Straddles the wheel between the legs -- same signf(leg pivot's own local
## X)-keyed outward splay _apply_manchego_seated_pose() already uses for
## RIDE_HIP_SPLAY, reused here since it's the same "sit/stand astride
## something round and wide" problem.
const DIRTBIKE_HIP_SPLAY := deg_to_rad(10.0)
## Per direct correction ("speed of the wheel should be pretty fast, not
## just normal walking speed") -- multiplies HumanoidLocomotion's own ground
## speed the same way skating's own worn_leg_speed_multiplier() already
## does (see current_speed's own assembly in _physics_process). Stacks with
## sprinting like every other speed multiplier here, so sprinting on the
## wheel is faster still. First-draft magnitude, adjustable on report.
const DIRTBIKE_SPEED_MULTIPLIER := 2.2
## Per direct correction ("adding the arm wheels should speed it up even
## more") -- an ADDITIONAL multiplier stacked on top of DIRTBIKE_SPEED_
## MULTIPLIER while the wheelie (front wheel) is also active, not a
## replacement for it.
const DIRTBIKE_WHEELIE_SPEED_MULTIPLIER := 1.35
## Wheel dynamics. Powered travel accelerates toward its target instead of
## reaching full speed on the first input frame. With the drive released,
## gravity along the slope, rolling resistance and quadratic air drag are
## integrated continuously by HumanoidLocomotion.coast_wheel_velocity().
const DIRTBIKE_DRIVE_ACCELERATION := 22.0
## Tire traction is intentionally balanced: ordinary steering carries speed,
## while a perpendicular carve scrubs and a full reversal brakes decisively.
const DIRTBIKE_LATERAL_GRIP := 36.0
const DIRTBIKE_REVERSE_BRAKING := 30.0
const DIRTBIKE_ROLLING_RESISTANCE := 0.16
const DIRTBIKE_AIR_DRAG := 0.011
const DIRTBIKE_ROLL_STOP_SPEED := 0.12
const DIRTBIKE_TERMINAL_ROLL_SPEED := 34.0
const DIRTBIKE_GRADE_RESPONSE := 7.0
## About 12% more vertical takeoff speed (sqrt(1.25)) without altering the
## horizontal component or the terrain-derived launch direction.
const DIRTBIKE_JUMP_HEIGHT_MULTIPLIER := 1.25

## Snowboard: a passive, gravity-driven sibling of the dirtbike movement
## model. Input carves/steers existing momentum but supplies no throttle.
## Strong contact friction makes a board settle decisively on flats and
## shallow run-outs. Low quadratic drag remains separate, so a real descent
## can still accumulate the high speed expected from a long mountain.
const SNOWBOARD_ROLLING_RESISTANCE := 0.075
const SNOWBOARD_ICE_RESISTANCE := 0.075
## Deceleration (m/s^2) when a grounded board is on anything but snow: a
## ~30 km/h run off the snow's edge stops within about a metre.
const SNOWBOARD_OFF_SNOW_BRAKING := 40.0
const SNOWBOARD_AIR_DRAG := 0.00032
const SNOWBOARD_TUCK_DRAG_MULTIPLIER := 0.42
const SNOWBOARD_TUCK_TERMINAL_MULTIPLIER := 1.22
const SNOWBOARD_TURN_RATE := deg_to_rad(105.0)
const SNOWBOARD_CARVE_GRIP := 2.4
const SNOWBOARD_STOP_SPEED := 0.12
const SNOWBOARD_TERMINAL_SPEED := 112.0
## The kingdoms compress a real mountain into a shorter playable run. This
## preserves gravity-led acceleration while letting a sustained steep grade
## build the speed that a full-size descent would have had time to acquire.
const SNOWBOARD_GRAVITY_SCALE := 1.45
const SNOWBOARD_POSE_SETTLE_SPEED := 7.0
## Terrain triangles are sampled across the board's length and their normal
## is damped before reaching either rider or deck. Response softens further
## at speed, representing the board's angular inertia instead of snapping to
## every small change in the height field.
const SNOWBOARD_PITCH_RESPONSE_SLOW := 5.0
const SNOWBOARD_PITCH_RESPONSE_FAST := 2.4
const SNOWBOARD_NORMAL_SAMPLE_DISTANCE := 1.05
## Ankles and knees can let the deck conform to an ordinary grade while the
## torso remains balanced. Beyond this grade the remaining angle belongs to
## the whole rider, pivoting about the planted feet rather than bending the
## board farther away from its two terrain contacts.
const SNOWBOARD_RIDER_PITCH_THRESHOLD := deg_to_rad(17.0)
const SNOWBOARD_RIDER_PITCH_RESPONSE := 5.5
# This authored rig's anatomical left points along local +X (confirmed from
# the live stance), so a regular stance rotates body-forward -90 degrees
# from travel and twists the upper body back toward travel with +Y turns.
const SNOWBOARD_BODY_SIDE_ANGLE := -PI * 0.5
const SNOWBOARD_ABDOMEN_TWIST := deg_to_rad(16.0)
const SNOWBOARD_THORAX_TWIST := deg_to_rad(18.0)
## A real board stance is substantially wider than the ordinary standing
## gait. Hip abduction spreads the feet longitudinally along the board while
## keeping both upper legs seated in their actual hip sockets.
const SNOWBOARD_STANCE_SPLAY := deg_to_rad(15.0)
const SNOWBOARD_HIP_BEND := deg_to_rad(10.0)
const SNOWBOARD_TUCK_HIP_BEND := deg_to_rad(16.0)
const SNOWBOARD_KNEE_BEND := deg_to_rad(25.0)
const SNOWBOARD_TUCK_KNEE_BEND := deg_to_rad(27.0)
const SNOWBOARD_ARM_SPREAD := deg_to_rad(20.0)
const SNOWBOARD_TUCK_ARM_SPREAD := deg_to_rad(12.0)
const SNOWBOARD_ELBOW_BEND := deg_to_rad(10.0)
const SNOWBOARD_TUCK_ELBOW_BEND := deg_to_rad(10.0)
const SNOWBOARD_SPEED_LEAN_MAX := deg_to_rad(-17.0)
const SNOWBOARD_TUCK_LEAN := deg_to_rad(-6.0)
const SNOWBOARD_FULL_LEAN_SPEED := 25.0
const SNOWBOARD_WIDTH := 0.32
const SNOWBOARD_LENGTH := 2.45
const SNOWBOARD_THICKNESS := 0.08
const SNOWBOARD_COLOR := ElementPalette.SNOW_BODY

## Ice-leg skates: powered on real ice, but still physically extend beneath
## the shoes everywhere else. Their runner color is the exact canonical Ice
## body material because elemental constructs are extensions of the blorbs.
const ICE_SKATE_COLOR := ElementPalette.ICE_BODY
const ICE_SKATE_RUNNER_HALF_LENGTH := 0.19
const ICE_SKATE_RUNNER_HALF_WIDTH := 0.022
const ICE_SKATE_RUNNER_HALF_HEIGHT := 0.025
const ICE_SKATE_SUPPORT_HEIGHT := 0.055
const ICE_SKATE_TOTAL_HEIGHT := ICE_SKATE_RUNNER_HALF_HEIGHT * 2.0 + ICE_SKATE_SUPPORT_HEIGHT
const ICE_SKATE_POSE_SETTLE_SPEED := 9.0
const ICE_SKATE_SPEED_MULTIPLIER := 2.55
const ICE_SKATE_DRIVE_ACCELERATION := 16.0
const ICE_SKATE_SPRINT_THRUST_MULTIPLIER := 1.75
const ICE_SKATE_LATERAL_GRIP := 13.0
const ICE_SKATE_REVERSE_BRAKING := 18.0
const ICE_SKATE_ROLLING_RESISTANCE := 0.022
const ICE_SKATE_AIR_DRAG := 0.0018
const ICE_SKATE_STOP_SPEED := 0.10
const ICE_SKATE_TERMINAL_SPEED := 32.0
## Penguin Suit (a full Ice suit under the Penguin Helm): Jump on ice launches
## a low forward dive that lands on the belly and toboggans across the ice.
## The dive is at least this fast forward, and rises to this fraction of an
## ordinary jump's height.
const PENGUIN_DIVE_FORWARD_SPEED := 15.0
const PENGUIN_DIVE_HEIGHT := 0.45
## Landing from the dive onto the belly kicks the slide on this much faster.
const PENGUIN_SLIDE_LANDING_BOOST := 1.2
## Jump while belly sliding hops back up onto the feet: this fraction of an
## ordinary jump's height.
const PENGUIN_STAND_HOP_HEIGHT := 0.35
## The Penguin Suit is formed or unformed by pressing all four limb buttons
## together, within this many seconds of the first. Limb powers wait out the
## window, so a chord never also fires them.
const PENGUIN_CHORD_WINDOW := 0.2
## On foot the formed Penguin Suit waddles: slow, in short quick steps, the
## whole body leaning over whichever foot is planted.
const PENGUIN_WADDLE_SPEED_MULTIPLIER := 0.32
const PENGUIN_WADDLE_CADENCE := 2.1
const PENGUIN_WADDLE_STEP := deg_to_rad(7.0)
const PENGUIN_WADDLE_THIGH_LIFT := deg_to_rad(6.0)
const PENGUIN_WADDLE_KNEE := deg_to_rad(16.0)
const PENGUIN_WADDLE_ROLL := deg_to_rad(7.0)
## Flippers held a little out from the body while waddling.
const PENGUIN_FLIPPER_SPREAD := deg_to_rad(14.0)
## Lying prone, the face lifts forward this far, split between the base of the
## neck and the base of the skull (as the Manchego seat's upright head is).
const PENGUIN_HEAD_LIFT := deg_to_rad(78.0)
const PENGUIN_HEAD_LIFT_NECK_SHARE := 0.5
## Belly-slide deceleration on ice, and off it (snow and ground grab the belly).
const PENGUIN_SLIDE_FRICTION := 1.1
const PENGUIN_SLIDE_OFF_ICE_FRICTION := 12.0
## How quickly the stick bends a belly slide's heading (radians per second).
const PENGUIN_SLIDE_TURN_RATE := 1.3
## Below this speed the penguin stands back up.
const PENGUIN_SLIDE_STOP_SPEED := 0.9
## How quickly the body tips between upright and prone (fraction per second).
const PENGUIN_PRONE_RATE := 5.5
## The body tips about this height above the feet (the belly), and while
## prone that point rests this high above the ground: the Penguin torso's
## belly half-depth, so the belly lies on the ice.
const PENGUIN_BODY_PIVOT_HEIGHT := 0.75
const PENGUIN_BELLY_REST_HEIGHT := 0.34
const ICE_SKATE_PUSH_HIP_BACK := deg_to_rad(25.0)
const ICE_SKATE_GLIDE_HIP_FORWARD := deg_to_rad(13.0)
const ICE_SKATE_RECOVERY_HIP_FORWARD := deg_to_rad(11.0)
const ICE_SKATE_PUSH_OUTWARD := deg_to_rad(18.0)
const ICE_SKATE_SPRINT_PUSH_OUTWARD := deg_to_rad(48.0)
const ICE_SKATE_TOE_OUT := deg_to_rad(24.0)
const ICE_SKATE_PUSH_KNEE := deg_to_rad(13.0)
const ICE_SKATE_GLIDE_KNEE := deg_to_rad(27.0)
const ICE_SKATE_RECOVERY_KNEE := deg_to_rad(20.0)
const ICE_SKATE_BODY_LEAN := deg_to_rad(8.0)
const ICE_SKATE_ARM_SWING := deg_to_rad(18.0)
const ICE_SKATE_ELBOW_BEND := deg_to_rad(38.0)
const ICE_SKATE_SPRINT_BODY_LEAN := deg_to_rad(17.0)
const ICE_SKATE_SPRINT_POSE_MULTIPLIER := 2.0
const ICE_SKATE_SPRINT_ARM_LIFT := deg_to_rad(16.0)
const ICE_SKATE_CADENCE_GLIDE := 1.65
const ICE_SKATE_CADENCE_THRUST := 4.35
const ICE_SKATE_FULL_THRUST_ACCELERATION := 7.5
# Above the human's ordinary 11.3 m/s jump, so a rising ice platform still
# gives a meaningful boost, but bounded well below the old collision-spike
# values that could launch the player into the stratosphere.
const ICE_PLATFORM_LAUNCH_MAX_SPEED := 14.5

## ---- Dirt blorb suit: front wheel / wheelie ---- Per direct instruction:
## ALSO landing a "ground" arm pair (BlorbSuitController.has_dirtbike_arms())
## does nothing on its own ("the condition is that you also have the dirt leg
## blorbs, otherwise the arm power doesn't do anything") -- see
## _update_dirtbike_state()'s own combination of the two. Holding BOTH
## left_arm_power and right_arm_power already raises both arms forward on
## its own, unconditionally, regardless of element or the wheel at all (see
## _apply_arm_power_poses()'s own doc comment: a placeholder gesture for
## whatever an arm's suit covering eventually casts) -- the wheelie only
## adds the front wheel prop itself, between the two now-raised WRISTS (per
## direct correction, "the arm axis should be at the wrists" -- _wrist_left/
## _wrist_right, not _hand_left/_hand_right), plus the forward body lean
## that brings it down to the ground. Releasing EITHER arm button removes
## the front wheel and eases the body back upright, same as the arm-raise
## pose itself already reverts independently per arm.
##
## The lean angle itself is solved live every frame from the rig's own
## current wrist/ankle geometry -- see _solve_dirtbike_wheelie_pitch()'s own
## doc comment for the derivation -- rather than a single guessed constant,
## per direct instruction ("you must figure out the math to keep the back
## wheel touching the ground but also pitch the player's body forward until
## the perimeter of the front wheel also rests on the ground").
const DIRTBIKE_WHEELIE_SETTLE_SPEED := 7.0
## When the rear wheel remains supported but the front wheel has cleared its
## surface, gravity creates a real forward pitching moment about the rear
## contact. This angular acceleration prevents a stopped bike from balancing
## forever with its front tire suspended in the air. Fully airborne travel
## still preserves launch attitude as its separate ballistic rule requires.
const DIRTBIKE_NOSE_DROP_ANGULAR_ACCELERATION := deg_to_rad(115.0)
const DIRTBIKE_NOSE_DROP_MAX_ANGULAR_SPEED := deg_to_rad(150.0)
## Snow yields visually beneath the feet without lowering the collision body.
## Slightly shallower than cloud immersion: packed ground supports weight,
## while a cloud is a deep, fluffy one-way volume.
const SNOW_VISUAL_SINK_DEPTH := 0.075
const SNOW_VISUAL_SINK_SPEED := 0.65
## Shallower than CLOUD_SINK_DEPTH -- a tree canopy is a thin leaf mass, not
## a fluffy cloud bank, so standing on top should read as resting lightly on
## foliage rather than sinking noticeably in.
const TREE_CANOPY_SINK_DEPTH := 0.04

# Frozen-lake traversal deliberately retains horizontal momentum. These are
# world acceleration/friction rates, kept independent of animation cadence
# and every blorb Speed stat.
const ICE_ACCELERATION := 8.5
const ICE_FRICTION := 0.72
const ICE_SUPPORT_TOLERANCE := 0.34
## The lake sheet has physical thickness. Collision recovery can put the feet
## a fraction below its rendered top for one frame; accept and lift that narrow
## band instead of dropping ice mode and leaving the capsule wedged in it.
const ICE_SURFACE_RECOVERY_DEPTH := 0.52

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

# One-shot opening tableau: the hero wakes from the coma described in the
# world bible already lying face-up in the starting field, takes a moment to
# orient, then rises before ordinary control unlocks. The visual rig rotates
# around its feet-on-ground origin while the collision body remains safely
# upright and stationary.
const WAKE_INTRO_REST_DURATION := 0.9
const WAKE_INTRO_EYE_OPEN_DURATION := 0.42
const WAKE_INTRO_RISE_DURATION := 1.65
const WAKE_INTRO_SETTLE_DURATION := 0.65
const WAKE_INTRO_LYING_ANGLE := deg_to_rad(-90.0)
const WAKE_INTRO_VISUAL_HEIGHT := 0.18
const WAKE_INTRO_CAMERA_PITCH := deg_to_rad(-82.0)
const WAKE_INTRO_CAMERA_DISTANCE := 0.48
const WAKE_INTRO_HIP_BEND := deg_to_rad(38.0)
const WAKE_INTRO_KNEE_BEND := deg_to_rad(72.0)
const WAKE_INTRO_SPINE_CURL := deg_to_rad(22.0)
const WAKE_INTRO_LEFT_ARM_REACH := deg_to_rad(52.0)
const WAKE_INTRO_RIGHT_ARM_REACH := deg_to_rad(68.0)
const WAKE_INTRO_ELBOW_BEND := deg_to_rad(48.0)

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
## straight on (CameraRig starts with this body's own rotation, and
## _update_camera_follow() carries any later change to it, so the camera's
## facing is still inherited from THIS node's rotation even though the rig
## is top_level) -- kingdom_bootstrap.gd's arrival spawn must keep
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
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
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
var _thorax: Node3D
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
var _footstep_half_cycle: int = 0
var _footsteps_were_moving: bool = false
var _prev_grounded: bool = true
## Filters single-frame loss of floor contact while terrain step-up and
## ground-snap hand the player between adjacent slope samples. Without this,
## every tiny hand-off looked like a fresh landing and repeatedly restarted
## the crouched landing/jump frame while simply walking uphill.
var _continuous_airborne_time: float = 0.0
const LANDING_MIN_AIRBORNE_TIME := 0.08
var _was_in_water: bool = false
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
## Cached from the cloud support query so landing and stride foley both
## consistently treat soft clouds as silent footing.
var _standing_on_cloud := false
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

var _wake_intro_active: bool = false
var _wake_intro_elapsed: float = 0.0
var _wake_intro_owns_modal_lock: bool = false
var _wake_intro_camera_pitch_rest: float = 0.0
var _wake_intro_final_transform: Transform3D
var _wake_intro_has_final_transform := false

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
# _try_predictive_blorb_bounce()) launches the player straight back into the jump arc
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
var _last_bounced_blorb: Blorb = null
## A grounded platform call is deliberately two-stage: the arriving blorb
## first starts an ordinary player hop, then waits under the arc for the
## normal trampoline contact. This reads as hopping onto the helper rather
## than teleporting onto its crown and guarantees enough clearance.
var _platform_aid_setup_blorb: Blorb = null
var _platform_aid_setup_elapsed := 0.0
const PLATFORM_AID_COMPLETION_DEADLINE := 1.25
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
# Rock legs make the equipped body negatively buoyant; they do not teleport
# it to the sampled terrain height. Acceleration gives the transition weight
# while the terminal speed keeps a deep-ocean descent readable and controllable.
const LAKE_WEIGHTED_SINK_ACCELERATION := 7.5
const LAKE_WEIGHTED_SINK_SPEED := 5.5
const LAKE_FLOOR_LANDING_TOLERANCE := 0.16
const AIR_FLIGHT_SPEED := 6.0
const AIR_FLIGHT_HOVER_HEIGHT := 0.5
const AIR_FLIGHT_EXIT_RECOVERY_DURATION := 0.45
const POWERED_HOVER_HEIGHT := 1.15
const POWERED_HOVER_LIFT_SPEED := 5.0
const POWERED_HOVER_SETTLE_SPEED := 9.0
## Each actively firing Fire foot compounds this multiplier while a chest
## Air blorb is already supplying flight: one leg = 1.35x, two = 1.8225x.
const FIRE_FOOT_FLIGHT_SPEED_MULTIPLIER := 1.35
## Water limbs while swimming jet backward instead: each active Water hand or
## foot multiplies swim speed by this (compounding, as Fire feet do in flight),
## and with the stick released they drive the swimmer straight ahead.
const SWIM_JET_SPEED_MULTIPLIER := FIRE_FOOT_FLIGHT_SPEED_MULTIPLIER
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
## Predict contact from this frame's downward travel before move_and_slide()
## can settle the CharacterBody against the blorb. The small precontact band
## absorbs moving-blorb/physics-tick disagreement; recovery depth catches a
## contact that began a frame earlier without turning side-brushes into jumps.
const BLORB_BOUNCE_PRECONTACT_MARGIN := 0.10
const BLORB_BOUNCE_RECOVERY_DEPTH := 0.22
const BLORB_BOUNCE_RELEASE_CLEARANCE := 0.035
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
# retroactively upgrades it. The remaining launch impulse is blended across
# BLORB_SUPER_JUMP_BOOST_DURATION rather than replacing velocity in one frame,
# so the forgiving input window does not introduce a visible pop in the arc.
const BLORB_SUPER_JUMP_GRACE_WINDOW := 0.18
## A post-impact jump press adds the remaining super-jump impulse over a few
## frames. This preserves the forgiving grace window without the old visible
## one-frame velocity jump.
const BLORB_SUPER_JUMP_BOOST_DURATION := 0.09

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
## Set for one frame when diving ends (surfacing into ordinary chest-Air-
## blorb flight, most commonly) -- see _process()'s own consumption of this
## for why: diving alone permits the wider AERIAL_CAMERA_PITCH_MIN/MAX
## range (see _rotate_camera()), and without an explicit re-clamp here the
## camera could be left at a steep pitch from diving that flight's own
## tighter PITCH_MIN/MAX never actually permits, reading as "off of normal
## position" until the next look input happened to snap it back.
var _lake_diving_just_ended: bool = false
var _lake_floor_walk_active: bool = false
var _lake_weighted_descent_active: bool = false
var _active_swim_surface_height: float = 0.0
var _lava_swimming_active: bool = false
var _lava_surface_walk_active: bool = false
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
## Electric is arms-only (no leg/hover variant -- there's no analogous
## mechanic the way fire/water legs already grant a jet hover), so unlike
## the water/fire flag sets above there's no _left_leg_electric_active.
var _left_arm_electric_active := false
var _right_arm_electric_active := false
## City is arms-only too, same as electric -- see CITY_POWER_MP_PER_SECOND's
## own comment.
var _left_arm_city_active := false
var _right_arm_city_active := false
## Rock/plant are discrete, cooldown-gated attacks rather than a continuous
## per-frame drain (see ROCK_POWER_COOLDOWN/PLANT_PELLET_COOLDOWN's own
## comments) -- these flags mean "button held with that element worn"
## regardless of cooldown state, matching the water/fire flags' own
## semantics for pose/XP-crediting purposes; the cooldown timers below
## separately gate when a shot/eruption actually fires.
var _left_arm_rock_active := false
var _right_arm_rock_active := false
var _left_arm_rock_cooldown := 0.0
var _right_arm_rock_cooldown := 0.0
var _left_leg_rock_cooldown := 0.0
var _right_leg_rock_cooldown := 0.0
var _left_arm_plant_active := false
var _right_arm_plant_active := false
var _left_arm_plant_cooldown := 0.0
var _right_arm_plant_cooldown := 0.0
var _water_leg_hover_active := false
var _fire_hand_hover_active := false
var _fire_leg_hover_active := false
var _fire_limb_flight_active := false
var _air_foot_hover_active := false
var _was_powered_hover_active := false
var _powered_hover_target_y := 0.0
## The snow-sink component only of the body's base height -- eased on its
## own, separately from the dirtbike lift added on top of it in
## _body_base_height().
var _visuals_snow_offset_y := -FOOT_OFFSET
## Dirt blorb suit -- see the DIRTBIKE_* consts' own doc comments.
var _dirtbike_wheel_active := false
## The wheelie's own toggle state -- per direct correction ("let's change
## the arm wheels to a toggle. If both are pressed down then it toggles the
## arm wheel to on. pressing both again toggles it to off"). Forced back to
## false if either prerequisite (the leg wheel, or the ground arm pair)
## drops away, so a stale "on" can't silently persist into a state where it
## no longer even makes sense -- see _update_dirtbike_state()'s own use.
var _dirtbike_wheelie_toggled_on := false
## Edge-detects the two-button chord for the toggle above: true only once
## BOTH left_arm_power and right_arm_power are simultaneously held, false
## the instant either releases -- the toggle fires on the frame this
## transitions false -> true, not on every frame both happen to be held.
var _dirtbike_wheelie_chord_was_pressed := false
## Edge-detects UIState.modal_open closing -- see this field's own use in
## _update_dirtbike_state() ("unpausing holding something should bring out
## of arm wheels").
var _was_modal_open := false
## True exactly when _dirtbike_wheelie_toggled_on is (see
## _update_dirtbike_state()) -- kept as its own field since every other
## dirtbike function already reads this name.
var _dirtbike_wheelie_active := false
var _dirtbike_pose_blend := 0.0
var _dirtbike_wheelie_blend := 0.0
var _dirtbike_default_floor_max_angle := 0.0
var _dirtbike_rear_wheel: MeshInstance3D = null
var _dirtbike_front_wheel: MeshInstance3D = null
## Cresting-a-climb launch state -- see _snap_to_terrain()'s own comment.
var _dirtbike_was_climbing := false
## The body's most recently resolved world-space velocity while constrained
## to terrain. This is measured delta-position/delta-time, not reconstructed
## from a sampled slope, and is preserved intact when support disappears.
var _dirtbike_surface_velocity := Vector3.ZERO
var _dirtbike_smoothed_grade := 0.0
## Last slope for which both wheel contacts were physically plausible. When
## the front tire clears a crest, retaining this tangent prevents a terrain
## sample far below the airborne tire from pulling the bike's nose downward.
var _dirtbike_supported_pitch := 0.0
var _dirtbike_pitch_angular_velocity := 0.0
var _dirtbike_airborne_pitch := 0.0
var _dirtbike_pitch_was_grounded := false
## Matched Snow legs toggle this with a simultaneous leg-button chord.
var _snowboard_toggled_on := false
var _snowboard_chord_was_pressed := false
var _snowboard_active := false
var _snowboard_pose_blend := 0.0
var _snowboard: Node3D = null
var _snowboard_last_heading := Vector3.FORWARD
var _snowboard_smoothed_up := Vector3.UP
var _snowboard_smoothed_rider_grade := 0.0
## Matched Ice legs automatically extend these runners. They remain visible
## off ice while their traversal physics only engage on the frozen lake.
var _ice_skates_active := false
var _ice_skating_active := false
var _ice_skate_pose_blend := 0.0
var _ice_skate_stride_phase := 0.0
var _ice_skate_previous_speed := 0.0
var _ice_skate_smoothed_acceleration := 0.0
var _ice_skate_left: Node3D = null
var _ice_skate_right: Node3D = null
var _ice_skate_was_supported := false
var _ice_skate_airborne := false
var _ice_skate_surface_velocity := Vector3.ZERO
## Penguin Suit dive (airborne, ballistic) and belly slide (grounded on ice).
var _penguin_dive_airborne := false
var _penguin_belly_sliding := false
## 0 upright .. 1 lying on the belly; eased by _compose_body_pose().
var _penguin_prone := 0.0
## Waddle: sideways lean (radians about the body's forward axis, positive over
## the right foot), whether the waddle posed it this frame, and how far the
## stepping has eased in.
var _penguin_waddle_roll := 0.0
var _penguin_waddle_posed := false
var _penguin_waddle_blend := 0.0
## The four-limb chord that forms/unforms the Penguin Suit.
var _penguin_chord_timer := 0.0
var _penguin_chord_consumed := false
var _penguin_chord_pending_legs: Array[bool] = [false, false]
var _penguin_chord_holding := false
## Base height applied by the last _compose_body_pose(). While riding, the
## dirtbike pose applies only the change in base height, so its chassis-pivot
## correction is retained rather than erased on the next frame.
var _dirtbike_visual_base_y := -FOOT_OFFSET
## World-space swim heading, retained for the visual-only aerial anchor pass
## after move_and_slide() has placed the collision body this frame.
var _aerial_motion_direction := Vector3.ZERO
var _aerial_strafe_input := 0.0
var _aerial_target_yaw := 0.0
var _aerial_was_moving: bool = false
var _aerial_rest_yaw := 0.0
var _aerial_rest_heading_initialized: bool = false
## Flight/swim rotates Visuals while CameraRig remains tied to this body.
## Capturing one body-relative skull anchor on entry prevents a transient pose
## error becoming the next frame's anchor and cumulatively drifting away.
var _aerial_skull_body_offset := Vector3.ZERO
var _aerial_skull_anchor_initialized := false
## The body's heading. Steering, throw aim, followers, the snowboard and the
## giant ease or set this; _compose_body_pose() is what applies it.
var _body_yaw := 0.0
## Set when steering turned a vehicle this frame, so the dirtbike pose pivots
## that turn about the rider's spine (see _pose_body_dirtbike()).
var _body_yaw_steered := false
## The capsule's authored standing pose, captured in _ready(). While skull-
## anchored, the same capsule is re-posed to follow the rendered body (see
## _fit_collision_to_body()); releasing the anchor restores this exactly.
var _standing_collision_transform := Transform3D.IDENTITY
## Height of the posed body's lowest point above this CharacterBody's origin.
## Zero while standing. While flying or diving level it rises to about 1.1 m,
## because the skull stays pinned at its standing height above the origin and
## the body hangs level from it. Analytic floors (the lakebed clamp, lava
## contact) add this so they meet the body's real underside, not the origin.
var _body_bottom_height := 0.0
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
var _blorb_super_jump_boost_time: float = 0.0
var _blorb_super_jump_boost_impulse: float = 0.0
var _lava_warning_cooldown: float = 0.0
## Own RandomNumberGenerator instance for combat_math.gd's rolled_attack()
## rolls (rock/plant arm powers) -- this project's established convention
## (see blorb.gd's own _rng) over the global randf()/randi(), so a roll
## never shares/consumes state with an unrelated system's own random draws.
var _rng := RandomNumberGenerator.new()

var _held_visual: Node3D = null
var _hand_right: Node3D
var _hand_left: Node3D
var _wrist_right: Node3D
var _wrist_left: Node3D
var _hand_wrist_anchors: Dictionary = {}
var _hand_wrist_offsets: Dictionary = {}
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
## LightningBolt, not GPUParticles3D -- see lightning_fx.gd's own class doc
## comment for why electric/city need a genuinely different rendering
## technique from the water/fire particle-spray streams above.
var _electric_stream_left: LightningBolt
var _electric_stream_right: LightningBolt
var _city_stream_left: LightningBolt
var _city_stream_right: LightningBolt
var _throw_aim_active: bool = false
## 0 = ordinary follow framing, 1 = the closer over-the-shoulder aim framing.
## Eased by _update_camera_follow() so both entering and leaving aim blend.
var _throw_camera_blend: float = 0.0
## This body's yaw as of the last camera update. The rig is top_level, so a
## teleport that turns this body (a recovery wake at an inn bed) would no
## longer turn the view with it; _update_camera_follow() carries the change.
var _camera_follow_root_yaw: float = 0.0
## Switching the followed body to one close by (mounting, dismounting, a
## nearby companion) glides the camera across instead of cutting. Farther
## switches still cut, since a long swoop across the map would disorient.
const CAMERA_HANDOFF_DURATION := 0.4
const CAMERA_HANDOFF_MAX_DISTANCE := 8.0
var _camera_subject: Node3D = null
var _camera_handoff_remaining: float = 0.0
var _camera_handoff_from_focus: Vector3 = Vector3.ZERO
var _camera_handoff_from_distance: float = 0.0
var _camera_last_distance: float = 0.0
var _throw_pose_blend: float = 0.0
var _throw_arm_start_rotation: Vector3 = Vector3.ZERO
var _throw_elbow_start_rotation: Vector3 = Vector3.ZERO
var _throw_hand_start_rotation: Vector3 = Vector3.ZERO
var _weapon_swing_active: bool = false
var _weapon_swing_elapsed: float = 0.0
var _weapon_swing_has_hit: bool = false
var _weapon_swing_inward: bool = false
var _next_weapon_swing_inward: bool = false
const WEAPON_SWING_DURATION := 0.46
const WEAPON_HIT_TIME := 0.46
const STOMP_DAMAGE := 16.0
const STOMP_REBOUND_SCALE := 0.78
const THROW_ABDOMEN_WINDUP := deg_to_rad(-3.0)
const THROW_THORAX_WINDUP := deg_to_rad(-4.0)

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
var _controlled_generic_member: Node3D = null
var _sun_wu_kong_summon: SunWuKong = null
const SUN_WU_KONG_SUMMON_TRIGGER_RADIUS := 18.0
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
var _mounted_rider: Node3D = null
var _player_following_manchego := false
## Dismounting climbs the rider down beside Manchego over
## MANCHEGO_DISMOUNT_DURATION rather than snapping the figure to wherever the
## unseen follower body happened to trail. -1.0 while not dismounting.
var _manchego_dismount_elapsed := -1.0
var _manchego_dismount_from := Transform3D()
var _manchego_dismount_yaw := 0.0
const MANCHEGO_DISMOUNT_DURATION := 0.45
## Small rise at the middle of the step down, so it reads as swinging a leg
## over and dropping rather than sliding through the saddle.
const MANCHEGO_DISMOUNT_HOP := 0.18
## Horizontal distance from the seat to where the rider lands at his side,
## and the farther fallback directly behind him.
const MANCHEGO_DISMOUNT_SIDE_OFFSET := 0.95
const MANCHEGO_DISMOUNT_BEHIND_OFFSET := 1.7

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
var _playable_profile := PlayableCharacterProfile.human()


## Read-only access to the suit controller. InventoryUI edits its persistent
## assignment map; PlayerPortrait renders that map on a separate figure.
func get_blorb_suit() -> BlorbSuitController:
	var active := PartyControl.active_member()
	if active != null and active != self and active.has_method("get_blorb_suit"):
		return active.get_blorb_suit()
	return _blorb_suit


func get_own_blorb_suit() -> BlorbSuitController:
	return _blorb_suit


## Universal rule: the blorb suit rides on whichever character is being
## controlled. When control passes to a character who can wear one, every
## other wearer's suit (worn pieces and paper-doll assignments) moves onto
## them at once, with no hops. Passing control to one who cannot (Blorbus, a
## mount) leaves the suit where it is until a wearer is controlled again.
func _on_active_member_changed(_previous: Node3D, current: Node3D) -> void:
	if current == null or not PartyControl.member_capability(current, &"wear_blorb_suit"):
		return
	if not current.has_method("get_own_blorb_suit"):
		return
	var receiver: BlorbSuitController = current.get_own_blorb_suit()
	for candidate in get_tree().get_nodes_in_group("party_playable_candidates"):
		if candidate == current or not candidate.has_method("get_own_blorb_suit"):
			continue
		var giver: BlorbSuitController = candidate.get_own_blorb_suit()
		if giver != null:
			giver.transfer_suit_to(receiver)


func _active_portrait() -> PlayerPortrait:
	var active := PartyControl.active_member()
	if active != null and active != self and active.has_method("get_portrait"):
		return active.get_portrait()
	return _portrait


## InventoryUI grabs this once (it's a live ViewportTexture, always
## current -- see player_portrait.gd) rather than requesting a fresh
## capture per refresh.
func get_portrait_texture() -> Texture2D:
	return _active_portrait().get_texture()


## InventoryUI calls this as its Blorbs tab opens/closes -- see
## PlayerPortrait.set_active()'s own comment for why the live camera
## shouldn't render every frame while nobody's actually looking at it.
func set_portrait_active(active: bool) -> void:
	_active_portrait().set_active(active)


func refresh_portrait_assignments() -> void:
	_active_portrait().refresh(get_blorb_suit().assignment_snapshot())


func pick_portrait_slot(viewport_position: Vector2) -> String:
	return _active_portrait().pick_slot(viewport_position)


func set_portrait_highlighted_slot(slot: String) -> void:
	_active_portrait().set_highlighted_slot(slot)


func set_portrait_selected_blorb(blorb: Blorb) -> void:
	_active_portrait().set_selected_blorb(blorb)


func set_portrait_focused_blorb(blorb: Blorb) -> void:
	_active_portrait().set_focused_blorb(blorb)


func set_portrait_body_focus_active(active: bool) -> void:
	_active_portrait().set_body_focus_active(active)


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
	_thorax = pivots.get("thorax")
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
	_wrist_right = pivots["wrist_right"]
	_wrist_left = pivots["wrist_left"]
	_hand_wrist_anchors.clear()
	_hand_wrist_offsets.clear()
	_cache_hand_wrist(_hand_right, _wrist_right)
	_cache_hand_wrist(_hand_left, _wrist_left)
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


## Camera framing contract, shared by every body the player can control
## (see XiaoHouZi, Blorb and Manchego's own copies): the world point the camera
## orbits, near the head, and the spring arm's resting length.
## _update_camera_follow() asks whichever body PartyControl reports as
## controlled, so no possession or mount path positions the camera itself.
## While skull-anchored (flight, diving), the orbit point is the pinned skull
## rather than a fixed height above the feet, which keeps the head a constant
## distance from the camera at every pitch.
func camera_focus_point() -> Vector3:
	if _aerial_skull_anchor_initialized:
		return global_position + _aerial_skull_body_offset
	return global_position + Vector3.UP * _playable_profile.camera_height


func camera_follow_distance() -> float:
	return _playable_profile.camera_distance


## The human's own suit is always authored at the ProceduralFigure scale.
## Xiao Hou Zi owns a separate controller with his MonkeyFigure fit profile.
func _current_blorb_suit_rig_scale() -> float:
	return 1.0


## Re-applies BlorbSuitController's own rig_scale without rebuilding the
## visible rig or touching which slots are worn -- called whenever
## CheatCodes.enabled toggles (see the _ready() connection to CheatCodes.
## toggled below), so a suit already worn on Xiao Hou Zi visibly resizes the
## instant the Konami Code lands instead of waiting for the next possession
## swap or a fresh equip.
func _apply_blorb_suit_rig_scale() -> void:
	_blorb_suit.setup(self, visuals, _blorb_suit_pivot_map(_visuals_pivots), _current_blorb_suit_rig_scale())


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
const THROW_MAX_AIM_DISTANCE := 45.0
## Aiming above the horizon usually hits nothing, leaving the aim point far
## up the camera ray; solving an arc to reach it demanded a catapult-like
## heave. Capping the upward launch speed turns those into a high lob (apex
## ~v^2 / 2g = 7 m), while ordinary aimed throws never need this much.
const THROW_MAX_UPWARD_SPEED := 12.0
const THROW_CAMERA_DISTANCE_SCALE := 0.60
## Per direct report, 1.05 shifted the camera over the shoulder far enough
## that his own head blocked the reticle rather than clearing it -- reduced
## to only clear the head's own width beside the spring arm's centerline,
## not visually verified in-engine (see the figure-rig skill's guidance on
## flagging unverified placement), tunable on report.
const THROW_CAMERA_RIGHT_OFFSET := 0.45
const THROW_CAMERA_BLEND_SPEED := 7.0
const THROW_POSE_SETTLE_SPEED := 11.0
const THROW_ARM_BACK_ANGLE := deg_to_rad(142.0)
const THROW_ARM_OUTWARD_ANGLE := deg_to_rad(24.0)
const THROW_ELBOW_BEND := deg_to_rad(104.0)
const THROW_HAND_COCK := deg_to_rad(18.0)


func _ready() -> void:
	current_hp = clampf(WorldState.player_current_hp, 0.0, MAX_HP)
	_rng.randomize()
	_dirtbike_default_floor_max_angle = floor_max_angle
	# Scene-exported tuning remains authoritative. The shared profile mirrors
	# it so composition never replaces an inspector adjustment with defaults.
	_playable_profile.move_speed = move_speed
	_playable_profile.sprint_multiplier = sprint_multiplier
	_playable_profile.jump_speed = jump_velocity
	# Hud (an autoload, not a scene sibling like blorb.gd's own "../Player")
	# has no relative path to reach this node -- the wild-blorb direction
	# hint looks it up by group instead (see hud.gd's _find_player()).
	add_to_group("player")
	add_to_group("party_playable_candidates")
	PartyControl.register_member(self)
	PartyControl.active_member_changed.connect(_on_active_member_changed)
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
	_standing_collision_transform = _collision_shape.transform

	# The rig never inherits this body's transform. _update_camera_follow()
	# places it on whichever body is being controlled, every frame; this only
	# avoids a first frame framed at the world origin.
	camera_rig.top_level = true
	_camera_follow_root_yaw = global_rotation.y
	camera_rig.global_position = camera_focus_point()
	camera_spring_arm.spring_length = camera_follow_distance()

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
	# so a future default-as-monkey debug session would still fit the suit.
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
	if _throw_aim_active and event.is_action_pressed("ui_cancel"):
		cancel_throw_preparation()
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(_controlled_giant) and event.is_action_pressed("ui_cancel") and not UIState.modal_open:
		HumongousState.show_merge_exit(self)
		get_viewport().set_input_as_handled()
		return
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
	_update_throw_input()
	if Input.is_action_just_pressed("platform_aid") and not UIState.modal_open:
		_call_platform_aid()
	if not UIState.modal_open and not _player_following_manchego:
		if Input.is_action_just_pressed("switch_character_previous"):
			if is_instance_valid(_controlled_giant):
				HumongousState.show_merge_exit(self)
			else:
				_cycle_playable_character(-1)
		elif Input.is_action_just_pressed("switch_character_next"):
			if is_instance_valid(_controlled_giant):
				HumongousState.show_merge_exit(self)
			else:
				_cycle_playable_character(1)
	_update_sun_wu_kong_summon()
	# Every branch below hands control to another body and skips
	# _compose_body_pose(). Starting one mid-flight must not leave the
	# human following along with a capsule still posed level.
	if _player_following_manchego or _piloting_xiao_hou_zi or is_instance_valid(_controlled_generic_member) or _player_following_blorbus:
		_release_skull_anchor()
	if _manchego_dismount_elapsed >= 0.0:
		_update_manchego_dismount(delta)
		return
	if _player_following_manchego:
		_update_manchego_control(delta)
		return
	if _piloting_xiao_hou_zi:
		_update_xiao_hou_zi_control(delta)
		return
	if is_instance_valid(_controlled_generic_member):
		_update_generic_party_control(delta)
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
			_begin_blorb_super_jump_boost()
			_blorb_super_jump_grace = 0.0
		else:
			_blorb_super_jump_grace = maxf(_blorb_super_jump_grace - delta, 0.0)

	_update_giant_goo_state(delta)
	var water_entry_speed := maxf(-velocity.y, 0.0)
	var was_diving := _lake_diving_active
	_update_lake_buoyancy(delta)
	_update_breath(delta)
	if was_diving and not _lake_diving_active:
		_lake_diving_just_ended = true
	var in_water_now := _lake_buoyancy_active
	if in_water_now and not _was_in_water and not _lava_swimming_active:
		UISounds.play_foley(
			&"water_splash" if water_entry_speed > 3.0 else &"water_wade",
			clampf(0.35 + water_entry_speed / 14.0, 0.35, 0.9),
			get_instance_id()
		)
	_was_in_water = in_water_now
	_update_air_flight()
	_update_dirtbike_state(delta)
	_update_snowboard_state()
	_update_penguin_state()
	_update_ice_skate_state()
	_update_limb_power_state(delta)
	_update_suit_flight_transition()
	var powered_hover := _is_powered_hover_active()
	var suit_flight := _is_suit_flight_active()
	var buoyant := _giant_goo_active or (_lake_buoyancy_active and not _lake_floor_walk_active) or suit_flight or powered_hover
	var giant_jump_ready := _giant_surface_grounded or _is_on_giant_mesh_surface()
	# A helmeted swimmer is still allowed to breach once they have reached
	# the same surface limit as an ordinary swimmer. Deeper diving must not
	# accidentally turn Jump into an unrestricted underwater vertical boost.
	var water_exit_jump_ready := false
	if _lake_buoyancy_active and not _lake_floor_walk_active and not _lake_weighted_descent_active:
		if not _lake_diving_active:
			water_exit_jump_ready = true
		elif terrain != null:
			var dive_surface: float = _active_swim_surface_height - LAKE_SWIM_FOOT_DEPTH
			water_exit_jump_ready = global_position.y >= dive_surface - 0.08

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
	# Ground grace belongs only to the procedural terrain it was invented to
	# smooth. A raised slab/roof can also make is_on_floor() true, but banking
	# grace there lets the far-below analytic terrain suppress gravity after
	# the character walks beyond the platform edge—the canyon hover artefact.
	if is_on_floor() and _is_aligned_with_terrain():
		_grounded_grace_timer = GROUNDED_GRACE_DURATION
	elif is_on_floor():
		_grounded_grace_timer = 0.0
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
	_standing_on_cloud = on_cloud
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
	# The frozen lake is a separate collision sheet above its submerged terrain.
	# Its analytic contact band remains stable when ConcavePolygon floor contact
	# flickers at the organically triangulated shoreline, so it must count as a
	# real grounded support for the jump gate as well as for skating physics.
	var on_ice_support:=_is_supported_by_ice()
	# One-way supports do not produce an is_on_floor() contact. If their
	# analytic surface says a descending jumper is already resting on one,
	# that is a completed landing and must end the jump state before grounded
	# is derived below. Otherwise `_jumping` keeps grounded false forever and
	# gravity pulls the character through on the following frame.
	if _jumping and velocity.y <= 0.0 and (on_cloud or on_canopy):
		_jumping = false
		_giant_surface_jump_in_progress = false
	var grounded := (_giant_surface_grounded or _lake_floor_walk_active or _lava_surface_walk_active or on_climbable_ramp or (
		is_on_floor() or _is_near_ground() or (_is_aligned_with_terrain() and _grounded_grace_timer > 0.0)
	) or on_cloud or on_canopy or on_ice_support) and not _jumping
	if suit_flight or powered_hover:
		grounded = false
	# grounded is fixed at the top of the frame, before the jump decision
	# below -- so on the exact frame a jump starts, it's still stale-true
	# and would otherwise let the step-up/snap calls further down cancel
	# the jump velocity they just set. This one-frame guard covers that.
	var jumped_this_frame := false

	if not grounded and not buoyant:
		if (_dirtbike_wheel_active or _snowboard_active or _ice_skate_airborne or _penguin_dive_airborne) and _jumping:
			velocity=HumanoidLocomotion.ballistic_step(
				velocity,delta,_playable_profile,TERMINAL_FALL_SPEED
			)
		else:
			velocity.y = HumanoidLocomotion.apply_gravity(velocity.y, delta, _playable_profile, TERMINAL_FALL_SPEED)
	elif jump_pressed and _giant_goo_active and not giant_jump_ready:
		# Goo is buoyant, not a fallable jump arc: pressing Jump while inside
		# it becomes a temporary fast upward swim toward the surface.
		_giant_goo_jump_lift_timer = GIANT_GOO_JUMP_LIFT_DURATION
		velocity.y = 0.0
		_jumping = false
	elif jump_pressed and grounded and not buoyant and _penguin_belly_sliding:
		_stand_from_belly_slide()
		jumped_this_frame = true
	elif jump_pressed and grounded and on_ice_support and not buoyant and _blorb_suit.penguin_form_active():
		_begin_penguin_dive()
		jumped_this_frame = true
	elif jump_pressed and (grounded or water_exit_jump_ready) and not _lake_floor_walk_active and not _lake_weighted_descent_active:
		var jump_height_multiplier := GIANT_SUPER_JUMP_HEIGHT_MULTIPLIER if giant_jump_ready else 1.0
		if _lake_buoyancy_active and not _lake_diving_active:
			jump_height_multiplier = WATER_EXIT_JUMP_HEIGHT_MULTIPLIER
		elif _dirtbike_wheel_active or _snowboard_active:
			jump_height_multiplier *= DIRTBIKE_JUMP_HEIGHT_MULTIPLIER
		velocity.y = HumanoidLocomotion.jump_speed(_playable_profile, jump_height_multiplier)
		if _ice_skates_active:
			# A deliberate skating jump is player-authored, not an inherited
			# platform impulse. It must never be reduced below the character's
			# normal jump merely because the ice-support handoff occurs nearby.
			velocity.y=maxf(velocity.y,HumanoidLocomotion.jump_speed(_playable_profile))
		_jump_takeoff_speed = absf(velocity.y)
		_giant_surface_jump_in_progress = giant_jump_ready
		_jumping = true
		jumped_this_frame = true
		if _ice_skates_active and _ice_skate_was_supported:
			_ice_skate_airborne=true
			_ice_skating_active=false
		UISounds.play_foley(&"jump", 0.52, get_instance_id())
	_update_blorb_super_jump_boost(delta)

	var input_dir := _get_move_input()
	# Water jets drive a swimmer ahead even with the stick released.
	if _swim_jet_count() > 0 and input_dir.length_squared() < 0.0001:
		input_dir = Vector2(0.0, -1.0)
	_aerial_motion_direction = Vector3.ZERO
	_aerial_strafe_input = 0.0
	# On land movement stays yaw-only. Inside a head-blorb dive, use the
	# pitched camera basis so looking up/down and swimming forward controls
	# ascent/descent naturally.
	var aerial_active := _lake_diving_active or suit_flight
	# Surface swimming keeps ordinary horizontal controls, but its body still
	# needs the same neck-led travel lean as diving.
	var neck_led_travel := (_lake_buoyancy_active and not _lake_floor_walk_active and not _lake_weighted_descent_active) or suit_flight
	var cam_basis := camera.global_transform.basis if aerial_active else camera_rig.global_transform.basis
	var direction := cam_basis.x * input_dir.x + cam_basis.z * input_dir.y
	if not aerial_active:
		direction.y = 0.0
	# Dirt-bike air is intentionally ballistic. Input remains available below
	# for facing, but neither it nor the live sprint modifier may rewrite the
	# launch vector until a real landing ends the arc.
	var dirtbike_ballistic:=_dirtbike_wheel_active and (not grounded or jumped_this_frame) and not buoyant
	# `grounded` is deliberately cached before jump handling, so it remains
	# true on the takeoff frame. Include jumped_this_frame or ordinary ground
	# movement would rewrite the skate's horizontal launch speed once before
	# ballistic preservation begins on the following frame.
	var skate_ballistic:=_ice_skate_airborne and (not grounded or jumped_this_frame) and not buoyant
	# The penguin's dive keeps its launch like a skate jump, and its belly
	# slide owns the planar velocity (_penguin_belly_slide_step()).
	var penguin_owns_velocity:=(_penguin_dive_airborne and (not grounded or jumped_this_frame) and not buoyant) or (_penguin_belly_sliding and grounded)

	var skating := _is_blorb_skating() and not _ice_skates_active
	var skate_speed_multiplier := worn_leg_speed_multiplier() if skating else 1.0
	var ground_move_speed := _playable_profile.move_speed
	# Sprint remains ordinary powered throttle while the tires are supported.
	# Only the dirt-bike ballistic carve-out freezes the launch speed.
	var speed_sprinting := _is_sprinting() and not dirtbike_ballistic and not _snowboard_active
	var current_speed := HumanoidLocomotion.ground_speed(_playable_profile, speed_sprinting)
	if skating:
		current_speed *= skate_speed_multiplier
	# Per direct correction ("speed of the wheel should be pretty fast, not
	# just normal walking speed... adding the arm wheels should speed it up
	# even more") -- stacks on top of ordinary walk/sprint speed the same
	# way skating's own multiplier just did, then the wheelie adds a further
	# multiplier on top of that rather than replacing it.
	if _dirtbike_wheel_active:
		current_speed *= DIRTBIKE_SPEED_MULTIPLIER
		if _dirtbike_wheelie_active:
			current_speed *= DIRTBIKE_WHEELIE_SPEED_MULTIPLIER
	if _lake_diving_active:
		current_speed = LAKE_DIVE_SPEED * worn_swim_speed_multiplier()
	elif _lake_floor_walk_active:
		current_speed *= 0.82
	elif _lake_weighted_descent_active:
		current_speed *= 0.82
	elif _air_flight_active or _fire_limb_flight_active:
		current_speed = AIR_FLIGHT_SPEED * worn_flight_speed_multiplier()
	elif _lake_buoyancy_active:
		current_speed *= worn_swim_speed_multiplier()
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
	var swim_jets := _swim_jet_count()
	if swim_jets > 0:
		current_speed *= pow(SWIM_JET_SPEED_MULTIPLIER, swim_jets)
	if _penguin_waddling():
		current_speed *= PENGUIN_WADDLE_SPEED_MULTIPLIER
	# Leg Speed replaces the old fixed skate multiplier. High-Speed legs reach
	# and surpass that former very-fast reference through progression itself.
	var sliding_on_ice := grounded and _is_supported_by_ice() and not _snowboard_active and not _ice_skating_active
	# Ice changes world traversal, not the authored gait. While the body
	# accelerates or coasts under ice momentum, animate from current control
	# intent at the ordinary walk/run rate; releasing the stick therefore
	# returns to idle even if momentum continues carrying the player.
	var ice_animation_speed := -1.0
	if sliding_on_ice:
		ice_animation_speed = (
			ground_move_speed * (sprint_multiplier if _is_sprinting() else 1.0)
			if direction.length() > 0.001
			else 0.0
		)
	if _penguin_belly_sliding and grounded and not jumped_this_frame:
		ice_animation_speed = 0.0
		_penguin_belly_slide_step(direction, delta)
	elif _snowboard_active and grounded and not _is_snowboard_surface():
		# Off snow the board does not slide at all: it grinds to a halt, and
		# neither slope nor steering can push it.
		ice_animation_speed = 0.0
		var stopped:=Vector2(velocity.x,velocity.z).move_toward(Vector2.ZERO,SNOWBOARD_OFF_SNOW_BRAKING*delta)
		velocity.x=stopped.x
		velocity.z=stopped.y
	elif _snowboard_active and grounded:
		ice_animation_speed = 0.0
		var aerodynamic_tuck:=_is_sprinting()
		var support_normal: Vector3=terrain.get_mesh_normal(global_position.x,global_position.z)
		if _is_supported_by_ice():
			support_normal=Vector3.UP
		var steering:=Vector2(direction.x,direction.z)
		var board_velocity:=HumanoidLocomotion.gravity_surface_glide(
			Vector2(velocity.x,velocity.z),support_normal,steering,delta,
			SNOWBOARD_ICE_RESISTANCE if _is_supported_by_ice() else SNOWBOARD_ROLLING_RESISTANCE,
			SNOWBOARD_AIR_DRAG*(SNOWBOARD_TUCK_DRAG_MULTIPLIER if aerodynamic_tuck else 1.0),
			SNOWBOARD_TURN_RATE,SNOWBOARD_CARVE_GRIP,SNOWBOARD_STOP_SPEED,
			SNOWBOARD_TERMINAL_SPEED*(SNOWBOARD_TUCK_TERMINAL_MULTIPLIER if aerodynamic_tuck else 1.0),
			SNOWBOARD_GRAVITY_SCALE
		)
		velocity.x=board_velocity.x
		velocity.z=board_velocity.y
		var carve_amount:=0.0
		if board_velocity.length_squared()>0.01 and steering.length_squared()>0.01:
			carve_amount=absf(board_velocity.normalized().cross(steering.normalized()))
		UISounds.pulse_snowboard(
			get_instance_id(),board_velocity.length(),carve_amount,
			0.0 if _is_supported_by_ice() else 1.0
		)
	elif _ice_skating_active and grounded:
		ice_animation_speed=0.0
		var steering:=Vector2(direction.x,direction.z)
		var skating_velocity:=Vector2(velocity.x,velocity.z)
		var skate_speed_before:=skating_velocity.length()
		if steering.length_squared()>0.001:
			var skate_target_speed:=HumanoidLocomotion.ground_speed(
				_playable_profile,_is_sprinting()
			)*ICE_SKATE_SPEED_MULTIPLIER*worn_leg_speed_multiplier()
			skating_velocity=HumanoidLocomotion.drive_wheel_velocity(
				skating_velocity,steering,skate_target_speed,delta,
				ICE_SKATE_DRIVE_ACCELERATION*(ICE_SKATE_SPRINT_THRUST_MULTIPLIER if _is_sprinting() else 1.0),ICE_SKATE_LATERAL_GRIP,
				ICE_SKATE_REVERSE_BRAKING,ICE_SKATE_STOP_SPEED
			)
		else:
			skating_velocity=HumanoidLocomotion.coast_wheel_velocity(
				skating_velocity,0.0,delta,ICE_SKATE_ROLLING_RESISTANCE,
				ICE_SKATE_AIR_DRAG,ICE_SKATE_STOP_SPEED,ICE_SKATE_TERMINAL_SPEED
			)
		if skating_velocity.length()>ICE_SKATE_TERMINAL_SPEED:
			skating_velocity=skating_velocity.normalized()*ICE_SKATE_TERMINAL_SPEED
		velocity.x=skating_velocity.x
		velocity.z=skating_velocity.y
		var skate_acceleration:=maxf((skating_velocity.length()-skate_speed_before)/maxf(delta,0.0001),0.0)
		var sound_cycle:=fposmod(_ice_skate_stride_phase/TAU,1.0)
		var sound_left:=ice_skate_stroke(sound_cycle)
		var sound_right:=ice_skate_stroke(fposmod(sound_cycle+0.5,1.0))
		UISounds.pulse_ice_skates(
			get_instance_id(),skating_velocity.length(),skate_acceleration,
			1.0-sound_left.y,1.0-sound_right.y
		)

	if direction.length() > 0.001:
		direction = direction.normalized()
		# Per direct correction, the wheelie's own head tracking (see
		# aerial_head_tracking's own comment in _update_head_look()) needs a
		# travel direction to aim at too -- deliberately only this ONE
		# neck_led_travel-gated line, not the velocity.y/_aerial_target_yaw
		# branches below: the dirtbike stays an ordinary ground vehicle
		# (normal yaw-facing, no camera-pitch-driven vertical movement),
		# only the HEAD borrows flight's own tracking behavior.
		if neck_led_travel or _dirtbike_wheelie_active:
			_aerial_motion_direction = direction
			_aerial_strafe_input = input_dir.x
		if dirtbike_ballistic or skate_ballistic or penguin_owns_velocity or _snowboard_active or _ice_skating_active:
			pass
		elif sliding_on_ice and not neck_led_travel:
			velocity.x = move_toward(velocity.x, direction.x * current_speed, ICE_ACCELERATION * delta)
			velocity.z = move_toward(velocity.z, direction.z * current_speed, ICE_ACCELERATION * delta)
		elif _dirtbike_wheel_active and not neck_led_travel:
			var driven_planar:=HumanoidLocomotion.drive_wheel_velocity(
				Vector2(velocity.x,velocity.z),Vector2(direction.x,direction.z),
				current_speed,delta,DIRTBIKE_DRIVE_ACCELERATION,
				DIRTBIKE_LATERAL_GRIP,DIRTBIKE_REVERSE_BRAKING,
				DIRTBIKE_ROLL_STOP_SPEED
			)
			velocity.x=driven_planar.x
			velocity.z=driven_planar.y
		else:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		if neck_led_travel:
			velocity.y = direction.y * current_speed
		var target_angle := atan2(direction.x, direction.z)
		if _snowboard_active:
			target_angle += SNOWBOARD_BODY_SIDE_ANGLE
		if neck_led_travel:
			# All three visual axes must be applied inside the skull-anchored
			# pass below. Applying yaw here would still rotate around the feet.
			_aerial_target_yaw = target_angle
		elif penguin_owns_velocity:
			# The dive and belly slide face along their own travel instead.
			pass
		elif _dirtbike_wheel_active or _snowboard_active or _ice_skating_active or skate_ballistic:
			# Vehicles turn about the rider's centre of mass rather than the
			# feet/rear axle; _pose_body_dirtbike() applies that pivot. This
			# remains the visual-only steering while ballistic: input can aim
			# the rider, but cannot bend the preserved launch velocity.
			_body_yaw = lerp_angle(_body_yaw, target_angle, rotation_speed * delta)
			_body_yaw_steered = true
		else:
			_body_yaw = lerp_angle(_body_yaw, target_angle, rotation_speed * delta)
	else:
		if _snowboard_active or _ice_skating_active or skate_ballistic or penguin_owns_velocity:
			pass
		elif sliding_on_ice:
			velocity.x = move_toward(velocity.x, 0.0, ICE_FRICTION * delta)
			velocity.z = move_toward(velocity.z, 0.0, ICE_FRICTION * delta)
		elif dirtbike_ballistic:
			# No throttle, braking, sprint rescale, or air steering force.
			# HumanoidLocomotion.ballistic_step() already advanced gravity.
			pass
		elif _dirtbike_wheel_active:
			var rolling:=Vector2(velocity.x,velocity.z)
			var sampled_grade:=_dirtbike_slope_along(rolling) if grounded else 0.0
			_dirtbike_smoothed_grade=lerpf(
				_dirtbike_smoothed_grade,sampled_grade,
				minf(DIRTBIKE_GRADE_RESPONSE*delta,1.0)
			)
			rolling=HumanoidLocomotion.coast_wheel_velocity(
				rolling,_dirtbike_smoothed_grade if grounded else 0.0,delta,
				DIRTBIKE_ROLLING_RESISTANCE if grounded else 0.0,DIRTBIKE_AIR_DRAG,
				DIRTBIKE_ROLL_STOP_SPEED,DIRTBIKE_TERMINAL_ROLL_SPEED
			)
			velocity.x=rolling.x
			velocity.z=rolling.y
		else:
			velocity.x = move_toward(velocity.x, 0.0, current_speed)
			velocity.z = move_toward(velocity.z, 0.0, current_speed)
		if aerial_active:
			velocity.y = move_toward(velocity.y, 0.0, current_speed)

	# Water-leg, dual-hand Fire, and dual-leg Fire hover are level traversal modes: their
	# camera-relative direction has no Y component, so the jets own vertical
	# lift. Air feet and four-limb Fire flight instead use camera-pitched
	# direction above; with no input they hold the last elevation here.
	_apply_powered_hover_vertical(delta, direction.length() > 0.001 and aerial_active)
	_face_snowboard_heading(delta)
	# Resolve a normal blorb landing before physics can convert it into a
	# stationary floor contact. This also lets the launch velocity influence
	# the pose and the very same move_and_slide() call, eliminating the old
	# one-frame stick/hover between impact and takeoff.
	var bounced_before_move := _try_predictive_blorb_bounce(delta, grounded)

	# Air-foot hover still traverses at the paired-leg skate speed, but that
	# boost must be divided back out of gait timing just like grounded skates.
	# `powered_hover` changes contact/foley, not animation cadence.
	_animate_walk(delta, grounded, skate_speed_multiplier if skating else 1.0, ice_animation_speed)
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
	_apply_swim_jet_pose(delta)
	_apply_throw_aim_pose(delta)
	_apply_weapon_swing_pose(delta)
	_apply_throw_facing(delta)
	_update_water_streams(delta)
	_apply_dirtbike_pose(delta)
	_apply_snowboard_pose(delta)
	_apply_ice_skate_pose(delta)

	# Capture before either terrain helper pre-lifts the body. Dirt-bike launch
	# velocity must include that complete vertical displacement, not merely the
	# smaller remainder left after the helper has already raised the chassis.
	var pre_move_position := global_position
	if grounded and not on_climbable_ramp and not jumped_this_frame and not buoyant and not _giant_surface_grounded and _is_touching_terrain():
		_try_step_up()
	# Not gated behind _is_touching_terrain() the way _try_step_up() is --
	# that check is specifically "close to the analytic ground function,"
	# which a slab's own raised surface has nothing to do with; grounded
	# and not jumped_this_frame alone (the same "don't fight an active
	# jump" guard every other step/snap call here uses) is what actually
	# matters for this one.
	if grounded and not on_climbable_ramp and not jumped_this_frame and not buoyant and not _giant_surface_grounded:
		_try_step_onto_prop(delta)
	var pre_move_feet_y := global_position.y - FOOT_OFFSET
	move_and_slide()
	_resolve_ice_surface_contact(pre_move_feet_y)
	_update_ice_skate_airtime(delta,pre_move_position)
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
		# The desired foot plane sits CLOUD_SINK_DEPTH below the visible puff
		# top. Include that full separation in the one-way query ceiling; the
		# former +2cm ceiling could reject the cloud during the only frame the
		# feet crossed their recessed landing plane, causing a permanent miss.
		var cloud_landing_height: Variant = _cloud_stand_height_at(
			global_position.x,global_position.z,pre_move_feet_y+CLOUD_SINK_DEPTH+0.04
		)
		var cloud_feet_height := (cloud_landing_height as float) - FOOT_OFFSET if cloud_landing_height != null else 0.0
		if cloud_landing_height != null and pre_move_feet_y >= cloud_feet_height and global_position.y - FOOT_OFFSET <= cloud_feet_height:
			_complete_one_way_support_landing(cloud_landing_height as float)
		# Tree canopies (round/pine/palm/banana/banyan/baobab foliage) are
		# the same kind of one-way support as clouds above -- walkable
		# underneath and through the sides, landable only when already above
		# the leaf mass and descending onto it. See
		# NatureProps._add_canopy_blob() and
		# WildernessScatter.get_support_height_at().
		var canopy_landing_height: Variant = _tree_canopy_stand_height_at(
			global_position.x,global_position.z,pre_move_feet_y+TREE_CANOPY_SINK_DEPTH+0.04
		)
		var canopy_feet_height := (canopy_landing_height as float) - FOOT_OFFSET if canopy_landing_height != null else 0.0
		if canopy_landing_height != null and pre_move_feet_y >= canopy_feet_height and global_position.y - FOOT_OFFSET <= canopy_feet_height:
			_complete_one_way_support_landing(canopy_landing_height as float)
	# Uses `grounded` as computed at the top of this frame (before this jump/
	# landing was resolved), same as the terrain step-up/snap calls around
	# it -- so this only ever fires while the frame started airborne, not on
	# every ground-level bump into a blorb's side.
	if not bounced_before_move and not _check_rising_air_blorb_bounce(grounded):
		_check_creature_bounce(grounded, pre_move_feet_y)
	# Last-resort invariant for a missed collision/crossing frame: an active
	# descending jump may never settle on a normal blorb crown. This catches
	# the reported frozen hop pose (including slope-assisted approaches) even
	# when move_and_slide() has already zeroed the vertical velocity and the
	# predictive crossing test can no longer reconstruct the prior crossing.
	_recover_stalled_blorb_bounce()
	_enforce_no_blorb_support_stall()
	_enforce_platform_aid_completion(delta)
	if grounded and not on_climbable_ramp and not jumped_this_frame and not buoyant and not _giant_surface_grounded and _is_touching_terrain():
		_snap_to_terrain(delta,pre_move_position)
	# Same active re-anchoring _snap_to_terrain() does for solid ground,
	# applied to a cloud top instead -- see on_cloud's own comment above for
	# why a cloud's own bumpy, multi-puff surface needs this (a loose
	# proximity tolerance alone let the player's foothold height and the
	# cloud's own real height under them drift apart while walking, reading
	# as falling through).
	if grounded and on_cloud and not jumped_this_frame and not buoyant and not _giant_surface_grounded:
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
	if _jumping and velocity.y <= 0.0 and (is_on_floor() or _is_near_ground() or _giant_surface_grounded or on_cloud or on_canopy):
		_jumping = false
		_giant_surface_jump_in_progress = false

	# Edge-detected off the same `grounded` _animate_walk already receives
	# (not a fresh is_on_floor() check), so it fires exactly when the walk
	# animation itself starts treating the character as grounded again --
	# grounded stays false for one extra frame right at touchdown (it was
	# computed above, before _jumping just cleared), so this actually fires
	# one frame after the true physical landing. Imperceptible for a "split
	# second" reaction, and simpler than a second, separately-timed check.
	if grounded and not _prev_grounded and _continuous_airborne_time >= LANDING_MIN_AIRBORNE_TIME:
		_landing_timer = LANDING_DURATION
		_walk_cycle_recovery = 0.0
		# Air-foot hover deliberately retains a walk/run animation while making
		# no ground contact; suppress its landing cue for the same reason its
		# stride contacts are silent below.
		if not _air_foot_hover_active and not _lake_buoyancy_active and not on_cloud and not _is_on_lava_surface():
			UISounds.play_landing(get_instance_id())
	if grounded:
		_continuous_airborne_time = 0.0
	else:
		_continuous_airborne_time += delta
	# Movement, bounces and ground snapping have all moved the collision body
	# for this frame; now place the rendered body on it, once.
	_compose_body_pose(delta, grounded, on_cloud or on_canopy, buoyant)
	_update_dirtbike_wheels(delta)
	_update_snowboard_visual()
	_prev_grounded = grounded


## The body's resting height above this CharacterBody's origin this frame:
## the snow sink (a slow ease, so feet settle into snow), the dirt blorb
## suit's rear-wheel lift (see DIRTBIKE_WHEEL_RADIUS: the ankles ride on top
## of the wheel, raising the whole figure by its radius, eased by
## _dirtbike_pose_blend), and the ice skates' blade lift. Pure: returns the
## height for _compose_body_pose() and only advances the snow ease.
func _body_base_height(delta: float, grounded: bool, on_soft_aerial_support: bool, buoyant: bool) -> float:
	var on_snow: bool = (
		grounded
		and not on_soft_aerial_support
		and not buoyant
		and not _snowboard_active
		and not _ice_skates_active
		and terrain != null
		and terrain.has_method("is_snow_footstep_surface")
		and terrain.is_snow_footstep_surface(Vector2(global_position.x,global_position.z))
	)
	var snow_target_y: float = -FOOT_OFFSET - (SNOW_VISUAL_SINK_DEPTH if on_snow else 0.0)
	_visuals_snow_offset_y = move_toward(_visuals_snow_offset_y, snow_target_y, SNOW_VISUAL_SINK_SPEED*delta)
	return (
		_visuals_snow_offset_y
		+ DIRTBIKE_WHEEL_RADIUS*_dirtbike_pose_blend
		+ (ice_skate_visual_lift() if _ice_skates_active else 0.0)
	)


func _is_supported_by_ice() -> bool:
	if _jumping:
		return false
	# Ice power platforms are genuine skateable ice too. Prefer the actual
	# floor collision before consulting the kingdom's analytic lake surface.
	for collision_index in get_slide_collision_count():
		var collision:=get_slide_collision(collision_index)
		if collision.get_normal().y>0.45 and collision.get_collider() is IceCrag:
			return true
	# A settled CharacterBody may produce no new slide collision at all. Probe
	# the small support band below the feet so a stationary or gently moving
	# skater continues to recognize a player-created IceCrag.
	var probe_from:=global_position+Vector3.UP*0.18
	var probe_to:=global_position-Vector3.UP*0.62
	var probe:=PhysicsRayQueryParameters3D.create(probe_from,probe_to,1)
	probe.exclude=[self]
	var support_hit:=get_world_3d().direct_space_state.intersect_ray(probe)
	if not support_hit.is_empty() and support_hit.get("collider") is IceCrag:
		return true
	if (
		terrain == null
		or not terrain.has_method("is_ice_surface")
		or not terrain.has_method("get_ice_level")
	):
		return false
	var xz := Vector2(global_position.x, global_position.z)
	if not terrain.is_ice_surface(xz):
		return false
	var ice_level: float = terrain.get_ice_level()
	var feet_delta := global_position.y - FOOT_OFFSET - ice_level
	return feet_delta >= -ICE_SURFACE_RECOVERY_DEPTH and feet_delta <= ICE_SUPPORT_TOLERANCE


## Captures the complete resolved surface vector, including vertical motion
## imparted by a rising Ice crag. When its support falls away, that vector is
## promoted to a true ballistic arc instead of terrain-following the body
## back down or allowing ordinary mid-air input to rewrite it.
func _update_ice_skate_airtime(delta: float,pre_move_position: Vector3) -> void:
	if not _ice_skates_active:
		_ice_skate_was_supported=false
		_ice_skate_airborne=false
		return
	var supported_now:=_is_supported_by_ice()
	if supported_now:
		_ice_skate_surface_velocity=HumanoidLocomotion.resolved_velocity(
			pre_move_position,global_position,delta
		)
		# Preserve the horizontal skate speed when a perfectly flat collision
		# produces a near-zero measured delta during a brief contact frame.
		if Vector2(_ice_skate_surface_velocity.x,_ice_skate_surface_velocity.z).length()<0.05:
			_ice_skate_surface_velocity.x=velocity.x
			_ice_skate_surface_velocity.z=velocity.z
		_ice_skate_was_supported=true
		if not _jumping:
			_ice_skate_airborne=false
		return
	if _ice_skate_was_supported:
		_ice_skate_was_supported=false
		_ice_skate_airborne=true
		if not _jumping:
			velocity=_ice_skate_surface_velocity
			# A moving crag can physically carry the skater upward, but collision
			# correction over one frame is not a meaningful launch velocity. Cap
			# the inherited lift to an authored platforming impulse so it cannot
			# catapult the player into the clouds.
			velocity.y=clampf(velocity.y,0.0,ICE_PLATFORM_LAUNCH_MAX_SPEED)
			_jump_takeoff_speed=absf(velocity.y)
			_jumping=true


## Frozen lake collision is a one-way standing surface from above. If the
## physics solver leaves the capsule fractionally embedded in the sheet, put
## its feet back on the exact visible top. A genuinely submerged player stays
## underwater: both their previous and current feet are below the recovery
## band, and the fishing hole is excluded by terrain.is_ice_surface().
func _resolve_ice_surface_contact(previous_feet_y: float) -> void:
	if (
		terrain == null
		or _jumping
		or velocity.y > 0.1
		or not terrain.has_method("is_ice_surface")
		or not terrain.has_method("get_ice_level")
	):
		return
	var xz := Vector2(global_position.x, global_position.z)
	if not terrain.is_ice_surface(xz):
		return
	var ice_level: float = terrain.get_ice_level()
	var current_feet_y := global_position.y - FOOT_OFFSET
	var came_from_surface_band := previous_feet_y >= ice_level - ICE_SURFACE_RECOVERY_DEPTH
	var remains_near_surface := current_feet_y >= ice_level - ICE_SURFACE_RECOVERY_DEPTH
	if not came_from_surface_band or not remains_near_surface:
		return
	if current_feet_y <= ice_level + ICE_SUPPORT_TOLERANCE:
		global_position.y = ice_level + FOOT_OFFSET
		velocity.y = 0.0


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
	if not terrain.is_lava_area(xz) or _blorb_suit.has_lava_safe_legs() or _blorb_suit.has_full_lava_suit():
		return
	var lava_surface: float = terrain.get_lava_surface_height(xz)
	# The body's underside, not the origin: a level flier's origin hangs up to
	# ~1.1 m below the visible body (see _body_bottom_height).
	if global_position.y - FOOT_OFFSET + _body_bottom_height > lava_surface + LAVA_CONTACT_TOLERANCE:
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


## Predicts whether this frame's motion will cross a blorb's rendered crown.
## Resolving the contact before move_and_slide() prevents the character body
## from being settled into a floor contact for a frame before the launch.
func _try_predictive_blorb_bounce(delta: float, was_grounded: bool) -> bool:
	if (
		was_grounded
		or velocity.y > 0.1
		or _giant_goo_active
		or _lake_buoyancy_active
		or _is_suit_flight_active()
		or _is_powered_hover_active()
	):
		return false
	var current_feet_y := global_position.y - FOOT_OFFSET
	var projected_xz := Vector2(
		global_position.x + velocity.x * delta,
		global_position.z + velocity.z * delta
	)
	var projected_feet_y := current_feet_y + velocity.y * delta
	var best_blorb: Blorb = null
	var best_surface_y := -INF
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not candidate is Blorb:
			continue
		var blorb := candidate as Blorb
		var surface: Variant = blorb.bounce_surface_height_at(projected_xz.x, projected_xz.y)
		if surface == null:
			continue
		var surface_y := surface as float
		if current_feet_y < surface_y - BLORB_BOUNCE_RECOVERY_DEPTH:
			continue
		if projected_feet_y > surface_y + BLORB_BOUNCE_PRECONTACT_MARGIN:
			continue
		if surface_y > best_surface_y:
			best_surface_y = surface_y
			best_blorb = blorb
	if best_blorb == null:
		return false
	global_position.y = best_surface_y + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
	_bounce_off_blorb(best_blorb)
	return true


## Post-movement recovery path for NPC heads and any blorb contact whose
## surface moved unexpectedly during this physics tick. Ordinary blorb
## landings should normally be resolved by the predictive pass above.
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
				global_position.y = (
					(blorb_surface as float) + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
				)
				_bounce_off_blorb(blorb)
				return
		elif creature.is_in_group("skeletons") and creature.has_method("take_damage"):
			_stomp_nme(creature)
			return
		elif creature.is_in_group("npcs") and creature.has_method("head_bounce_surface_height_at"):
			var npc_surface: Variant = creature.head_bounce_surface_height_at(global_position.x, global_position.z)
			if npc_surface != null:
				global_position.y = (npc_surface as float) + FOOT_OFFSET
				if creature.has_method("is_demon_agent_combat_active") and bool(creature.is_demon_agent_combat_active()):
					creature.take_damage(18.0, self)
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
			global_position.y = surface_y + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
			_bounce_off_blorb(blorb)
			return


func _stomp_nme(nme: Node) -> void:
	nme.take_damage(STOMP_DAMAGE, null)
	velocity.y = jump_velocity * STOMP_REBOUND_SCALE
	_jump_takeoff_speed = absf(velocity.y)
	_jumping = true
	_landing_timer = 0.0
	_walk_cycle_recovery = 0.0
	UISounds.play_foley(&"stomp_hit", 0.72, get_instance_id())


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
		var feet_gap := global_position.y - FOOT_OFFSET - contact_y
		if feet_gap >= -0.04 and feet_gap <= 0.08:
			# Resolve the visual contact before launching. This removes the old
			# hovering gap while retaining the existing squash/bounce response.
			global_position.y = contact_y + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
			_bounce_off_blorb(blorb)
			return true
	return false


func _recover_stalled_blorb_bounce() -> bool:
	# This is deliberately independent of `_jumping`. A collision-resolution
	# path can clear that animation/state flag while leaving the capsule resting
	# on the Blorb; requiring it here was the loophole that allowed a permanent
	# jump pose over a permanently compressed companion.
	if velocity.y > 0.1 or _giant_goo_active or _lake_buoyancy_active or _is_suit_flight_active() or _is_powered_hover_active():
		return false
	var feet_y := global_position.y - FOOT_OFFSET
	for candidate in get_tree().get_nodes_in_group("blorbs"):
		if not candidate is Blorb:
			continue
		var blorb := candidate as Blorb
		var surface: Variant = blorb.bounce_surface_height_at(global_position.x, global_position.z)
		if surface == null:
			continue
		var surface_y := surface as float
		# Tight enough to exclude side brushes, but deliberately extends below
		# the visible crown so a physics depenetration or squashed render frame
		# cannot strand the feet just beneath the analytic surface.
		if feet_y >= surface_y - 0.38 and feet_y <= surface_y + 0.18:
			global_position.y = surface_y + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
			_bounce_off_blorb(blorb)
			return true
	return false


## Absolute trampoline invariant: an ordinary Blorb may never act as a stable
## floor for the player. The analytic crown recovery above is the visually
## precise path; this collision-backed fallback covers a collider/rendered-
## surface disagreement, a squash frame, or a slope depenetration that places
## the feet just outside that analytic radius. Any upward physical support
## from a Blorb is converted into a launch during the same physics tick.
func _enforce_no_blorb_support_stall() -> bool:
	if velocity.y > 0.1 or _giant_goo_active or _lake_buoyancy_active or _is_suit_flight_active() or _is_powered_hover_active():
		return false
	for collision_index in get_slide_collision_count():
		var collision := get_slide_collision(collision_index)
		if collision.get_normal().y < 0.2:
			continue
		var collider := collision.get_collider() as Node
		if collider == null or not collider.is_in_group("blorbs") or not collider is Blorb:
			continue
		var blorb := collider as Blorb
		if blorb.blorb_type == "size" or blorb.is_worn or blorb.is_melted:
			continue
		var surface: Variant = blorb.bounce_surface_height_at(global_position.x, global_position.z)
		if surface != null:
			global_position.y = maxf(
				global_position.y,
				(surface as float) + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
			)
		else:
			# Outside the rendered crown but still physically supported by its
			# collider: separate upward before launching so the next frame cannot
			# immediately resolve the capsule back to zero vertical velocity.
			global_position.y += BLORB_BOUNCE_RELEASE_CLEARANCE + 0.08
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
	if blorb is Blorb:
		_last_bounced_blorb = blorb as Blorb
		if _platform_aid_setup_blorb == blorb:
			_platform_aid_setup_blorb = null
			_platform_aid_setup_elapsed = 0.0
		_last_bounced_blorb.finish_platform_aid()
	var super_jump := _jump_buffer_timer > 0.0
	_jump_buffer_timer = 0.0
	_blorb_super_jump_boost_time = 0.0
	_blorb_super_jump_boost_impulse = 0.0
	_apply_blorb_bounce_velocity(super_jump)
	_jumping = true
	# A trampoline launch is already leaving the surface. Replaying the
	# grounded impact pose during its ascent was the source of the apparent
	# frozen/repeating jump frame above a still-squashed blorb.
	_landing_timer = 0.0
	_walk_cycle_recovery = 0.0
	if blorb.has_method("trigger_bounce_squash"):
		blorb.trigger_bounce_squash()
	UISounds.play_blorb_bounce(super_jump, get_instance_id())
	# An ordinary bounce still leaves a short window open for a late press
	# to upgrade it -- see BLORB_SUPER_JUMP_GRACE_WINDOW's own comment. A
	# same-frame-or-earlier super jump has nothing left to upgrade.
	_blorb_super_jump_grace = 0.0 if super_jump else BLORB_SUPER_JUMP_GRACE_WINDOW


func _call_platform_aid() -> void:
	# The helper belongs to the currently controlled party member, regardless
	# of concrete character type. This keeps D-pad-down extensible instead of
	# silently routing future characters back to the human body.
	var platform_target: Node3D = PartyControl.active_control_body()
	if not is_instance_valid(platform_target):
		platform_target = self
	var chosen := _last_bounced_blorb
	if chosen == null or not is_instance_valid(chosen) or chosen == platform_target or not chosen.in_party or chosen.is_worn or chosen.is_melted:
		chosen = null
		for node in get_tree().get_nodes_in_group("blorbs"):
			var candidate := node as Blorb
			if candidate != null and candidate != platform_target and candidate.in_party and not candidate.is_worn and not candidate.is_melted:
				chosen = candidate
				break
	if chosen != null:
		var support_y := _platform_aid_support_height(platform_target)
		if chosen.element_state != "air" and is_nan(support_y):
			return
		_last_bounced_blorb = chosen
		_platform_aid_setup_blorb = null
		_platform_aid_setup_elapsed = 0.0
		chosen.call_as_platform_aid(platform_target, support_y)


## Finds the actual collider immediately below the controlled body. This is
## deliberately a physics query rather than terrain.get_mesh_height(): roofs,
## ships, rocks, palace floors, clouds with collision, and other raised
## platforms must retain their own height instead of resolving to the world
## terrain underneath them.
func _platform_aid_support_height(target: Node3D) -> float:
	var space_state := get_world_3d().direct_space_state
	var from := target.global_position + Vector3.UP * 0.4
	var terrain_y: float = terrain.get_mesh_height(target.global_position.x, target.global_position.z)
	var to := Vector3(target.global_position.x, terrain_y - 8.0, target.global_position.z)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | TownProps.BLORB_CLIMBABLE_LAYER)
	query.exclude = [self.get_rid()]
	if target is CollisionObject3D and target != self:
		query.exclude.append((target as CollisionObject3D).get_rid())
	for node in get_tree().get_nodes_in_group("blorbs"):
		if node is CollisionObject3D:
			query.exclude.append((node as CollisionObject3D).get_rid())
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return NAN
	return (hit["position"] as Vector3).y


func receive_platform_aid_bounce(platform: Blorb) -> void:
	if platform != null and not _player_following_blorbus:
		var planted := (
			not _jumping
			and velocity.y <= 0.1
			and (is_on_floor() or _is_near_ground())
		)
		# From a planted stance, begin a genuine hop when the helper arrives and
		# leave it waiting below. The descending crossing then uses the exact
		# same bounce path as a manually aimed jump onto a blorb.
		if planted and _platform_aid_setup_blorb == null:
			_platform_aid_setup_blorb = platform
			_platform_aid_setup_elapsed = 0.0
			velocity.y = jump_velocity
			_jump_takeoff_speed = absf(velocity.y)
			_jumping = true
			_landing_timer = 0.0
			UISounds.play_foley(&"jump", 0.52, get_instance_id())
			return
		if _platform_aid_setup_blorb == platform and velocity.y > 0.0:
			return
		# The early approach callback above intentionally occurs before the
		# helper is horizontally beneath the player. Only the actual descending
		# contact phase needs a valid point on its rendered crown.
		var surface: Variant = platform.bounce_surface_height_at(global_position.x, global_position.z)
		if surface == null:
			return
		var feet_y := global_position.y - FOOT_OFFSET
		if feet_y <= (surface as float) + 0.35:
			global_position.y = (surface as float) + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
			_bounce_off_blorb(platform)


func _enforce_platform_aid_completion(delta: float) -> void:
	if _platform_aid_setup_blorb == null:
		_platform_aid_setup_elapsed = 0.0
		return
	if not is_instance_valid(_platform_aid_setup_blorb):
		_platform_aid_setup_blorb = null
		_platform_aid_setup_elapsed = 0.0
		return
	_platform_aid_setup_elapsed += delta
	if _platform_aid_setup_elapsed < PLATFORM_AID_COMPLETION_DEADLINE:
		return
	# A timeout may cancel the setup, but it must never teleport either actor
	# through a platform to manufacture a bounce. A real crown contact is the
	# only successful completion path.
	var platform := _platform_aid_setup_blorb
	var surface: Variant = platform.bounce_surface_height_at(global_position.x, global_position.z)
	var feet_y := global_position.y - FOOT_OFFSET
	if surface != null and feet_y >= (surface as float) - 0.08 and feet_y <= (surface as float) + 0.38:
		global_position.y = (surface as float) + FOOT_OFFSET + BLORB_BOUNCE_RELEASE_CLEARANCE
		_bounce_off_blorb(platform)
	else:
		platform.finish_platform_aid()
		_platform_aid_setup_blorb = null
		_platform_aid_setup_elapsed = 0.0


func _apply_blorb_bounce_velocity(super_jump: bool) -> void:
	velocity.y = _blorb_bounce_launch_speed(super_jump)
	_jump_takeoff_speed = absf(velocity.y)


func _blorb_bounce_launch_speed(super_jump: bool) -> float:
	var height_multiplier := SUPER_JUMP_HEIGHT_MULTIPLIER if super_jump else 1.0
	var jump_speed_scale := TEMP_MONKEY_JUMP_MULTIPLIER if _piloting_xiao_hou_zi else 1.0
	return jump_velocity * jump_speed_scale * sqrt(height_multiplier)


func _begin_blorb_super_jump_boost() -> void:
	if not _jumping:
		return
	UISounds.play_blorb_bounce(true, get_instance_id())
	var target_speed := _blorb_bounce_launch_speed(true)
	_blorb_super_jump_boost_impulse = maxf(target_speed - velocity.y, 0.0)
	_blorb_super_jump_boost_time = (
		BLORB_SUPER_JUMP_BOOST_DURATION
		if _blorb_super_jump_boost_impulse > 0.0
		else 0.0
	)


func _update_blorb_super_jump_boost(delta: float) -> void:
	if _blorb_super_jump_boost_time <= 0.0:
		return
	if not _jumping:
		_blorb_super_jump_boost_time = 0.0
		_blorb_super_jump_boost_impulse = 0.0
		return
	var fraction := minf(delta / _blorb_super_jump_boost_time, 1.0)
	var impulse := _blorb_super_jump_boost_impulse * fraction
	velocity.y += impulse
	_blorb_super_jump_boost_impulse -= impulse
	_blorb_super_jump_boost_time = maxf(_blorb_super_jump_boost_time - delta, 0.0)
	if _blorb_super_jump_boost_time <= 0.0:
		_jump_takeoff_speed = maxf(_jump_takeoff_speed, _blorb_bounce_launch_speed(true))


## Whether the player is currently airborne (jumping or falling) rather than
## standing/walking on solid ground -- exposed for blorb.gd's player-push
## behavior, which per direct instruction should be much weaker while the
## player's mid-air (e.g. trying to land on top of a blorb for the
## trampoline bounce) than while just walking into one on the ground.
func is_airborne() -> bool:
	return _jumping


func is_air_flight_active() -> bool:
	return _is_suit_flight_active()


## This HP belongs to the persistent human body, independently of whichever
## party member currently owns the camera. Xiao Hou Zi ignores attacks in
## his own take_damage(), while damage that genuinely reaches this body can
## still trigger a faint even while another member is being controlled.
func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return
	current_hp = maxf(current_hp - CombatMath.mitigated_damage(amount, current_defense()), 0.0)
	WorldState.player_current_hp = current_hp
	UISounds.play_foley(&"player_hurt", clampf(amount / 24.0, 0.3, 0.9), get_instance_id())
	hp_changed.emit(current_hp, MAX_HP)
	if current_hp <= 0.0:
		RecoveryManager.faint_player.call_deferred()


## Used by engulfing hazards that eject the hero rather than leaving the
## CharacterBody trapped inside their collision volume.
func escape_from_lethal_hazard(safe_position: Vector3) -> void:
	current_hp = 0.0
	WorldState.player_current_hp = current_hp
	hp_changed.emit(current_hp, MAX_HP)
	global_position = safe_position
	velocity = Vector3.ZERO
	_jumping = false
	RecoveryManager.faint_player.call_deferred()


const BASE_DEFENSE := 5
# Speed affects only special blorb traversal modes (skating, flight and
# swimming), never the ordinary walk/run pace or animation cadence.
const SPECIAL_MOVEMENT_SPEED_PER_POINT := 0.025


func current_defense() -> int:
	var total := BASE_DEFENSE
	if _blorb_suit == null:
		return total
	for blorb in _blorb_suit.worn_blorbs():
		total += blorb.effective_defense()
	return total


func worn_leg_speed_multiplier() -> float:
	if _blorb_suit == null:
		return 1.0
	if not _blorb_suit.has_blorb_skates():
		return 1.0
	var points := 0
	for slot in ["leg_left", "leg_right"]:
		var blorb := _blorb_suit.worn_blorb_for_slot(slot)
		if blorb != null:
			points += blorb.speed
	return 1.0 + float(points) * SPECIAL_MOVEMENT_SPEED_PER_POINT


func worn_flight_speed_multiplier() -> float:
	if _blorb_suit == null:
		return 1.0
	if _air_flight_active:
		var chest := _blorb_suit.worn_blorb_for_slot("torso")
		if chest != null and chest.element_state == "air":
			return 1.0 + float(chest.speed) * SPECIAL_MOVEMENT_SPEED_PER_POINT
	if _fire_limb_flight_active:
		var leg_points := 0
		for slot in ["leg_left", "leg_right"]:
			var leg := _blorb_suit.worn_blorb_for_slot(slot)
			if leg != null and leg.element_state == "fire":
				leg_points += leg.speed
		return 1.0 + float(leg_points) * SPECIAL_MOVEMENT_SPEED_PER_POINT
	return 1.0


func worn_swim_speed_multiplier() -> float:
	if _blorb_suit == null:
		return 1.0
	var points := 0
	var contributors := 0
	for slot in ["head", "leg_left", "leg_right"]:
		var blorb := _blorb_suit.worn_blorb_for_slot(slot)
		if blorb != null:
			points += blorb.speed
			contributors += 1
	if contributors == 0:
		return 1.0
	return 1.0 + (float(points) / float(contributors)) * SPECIAL_MOVEMENT_SPEED_PER_POINT


func heal(amount: float) -> void:
	if amount <= 0.0:
		return
	var before := current_hp
	current_hp = minf(current_hp + amount, MAX_HP)
	WorldState.player_current_hp = current_hp
	if current_hp != before:
		hp_changed.emit(current_hp, MAX_HP)


func _process(delta: float) -> void:
	# SpringArm3D resolves its own child position as part of the engine's
	# physics step, at a point that runs after _physics_process -- clamping
	# there got silently overwritten every frame. _process() runs after all
	# physics processing for the frame, right before rendering, so this is
	# the last word on camera position each frame.
	_update_camera_follow(delta)
	_update_wake_intro(delta)
	_clamp_camera_above_ground()
	if _lake_diving_just_ended:
		_lake_diving_just_ended = false
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, PITCH_MIN, PITCH_MAX)
	if not _wake_intro_active:
		_update_head_look(delta)
	if not _piloting_xiao_hou_zi:
		_update_suit_input(delta)
	if _wake_intro_active:
		_apply_wake_intro_eyes()
	else:
		EyeBlink.apply(_eye_blink, delta, _eyes)


## Called by main.gd only for the first, non-portal arrival. Acquiring a
## separate modal lock before LoadingScreen releases its own makes the fade
## hand off seamlessly to this animation with no frame of live controls.
func begin_wake_intro() -> void:
	if _wake_intro_active or WorldState.opening_wake_completed:
		return
	_wake_intro_active = true
	_wake_intro_elapsed = 0.0
	_wake_intro_camera_pitch_rest = camera_pivot.rotation.x
	UIState.push_modal()
	_wake_intro_owns_modal_lock = true
	_apply_wake_intro_pose(0.0)
	_set_eye_openness(EyeBlink.CLOSED_OPENNESS)


func begin_recovery_wake(final_transform: Transform3D = global_transform) -> void:
	if _wake_intro_active:
		return
	_wake_intro_active = true
	_wake_intro_elapsed = 0.0
	_wake_intro_camera_pitch_rest = camera_pivot.rotation.x
	_wake_intro_final_transform = final_transform
	_wake_intro_has_final_transform = true
	UIState.push_modal()
	_wake_intro_owns_modal_lock = true
	_apply_wake_intro_pose(0.0)
	_set_eye_openness(EyeBlink.CLOSED_OPENNESS)


func restore_for_recovery(minimum_fraction: float = 1.0) -> void:
	current_hp = maxf(current_hp, MAX_HP * clampf(minimum_fraction, 0.0, 1.0))
	WorldState.player_current_hp = current_hp
	hp_changed.emit(current_hp, MAX_HP)


func force_human_control(show_feedback: bool = true) -> void:
	if is_instance_valid(_controlled_manchego):
		_end_manchego_control()
	if is_instance_valid(_controlled_xiao_hou_zi):
		_end_xiao_hou_zi_control()
	elif is_instance_valid(_controlled_generic_member):
		_end_generic_party_control()
	elif is_instance_valid(_controlled_blorbus) or is_instance_valid(_controlled_giant):
		_end_blorbus_control()
	PartyControl.set_active_member(self)
	if show_feedback:
		Hud.show_message("You are now controlling the player.")


func _update_wake_intro(delta: float) -> void:
	if not _wake_intro_active:
		return
	_wake_intro_elapsed += delta
	var rise_time := _wake_intro_elapsed - WAKE_INTRO_REST_DURATION
	var rise_linear := clampf(rise_time / WAKE_INTRO_RISE_DURATION, 0.0, 1.0)
	var rise := smoothstep(0.0, 1.0, rise_linear)
	_apply_wake_intro_pose(rise)
	var total_duration := (
		WAKE_INTRO_REST_DURATION
		+ WAKE_INTRO_RISE_DURATION
		+ WAKE_INTRO_SETTLE_DURATION
	)
	if _wake_intro_elapsed >= total_duration:
		_finish_wake_intro()


func _apply_wake_intro_pose(rise: float) -> void:
	# Root motion supplies the readable lie-to-stand arc. A temporary curl at
	# the middle of the rise breaks the rigid-plank silhouette: knees draw in,
	# the torso folds, and the two arms reach by slightly different amounts.
	var brace := sin(rise * PI)
	visuals.rotation.x = lerp_angle(WAKE_INTRO_LYING_ANGLE, 0.0, rise)
	visuals.rotation.z = 0.0
	visuals.position.y = lerpf(WAKE_INTRO_VISUAL_HEIGHT, -FOOT_OFFSET, rise)
	_leg_left.rotation.x = -WAKE_INTRO_HIP_BEND * brace
	_leg_right.rotation.x = -WAKE_INTRO_HIP_BEND * brace
	_knee_left.rotation.x = WAKE_INTRO_KNEE_BEND * brace
	_knee_right.rotation.x = WAKE_INTRO_KNEE_BEND * brace
	_ankle_left.rotation.x = -deg_to_rad(10.0) * brace
	_ankle_right.rotation.x = -deg_to_rad(10.0) * brace
	_arm_left.rotation.x = -WAKE_INTRO_LEFT_ARM_REACH * brace
	_arm_right.rotation.x = -WAKE_INTRO_RIGHT_ARM_REACH * brace
	_arm_left.rotation.y = 0.0
	_arm_right.rotation.y = 0.0
	_arm_left.rotation.z = ProceduralFigure.ARM_OUTWARD_ANGLE
	_arm_right.rotation.z = -ProceduralFigure.ARM_OUTWARD_ANGLE
	_elbow_left.rotation.x = -WAKE_INTRO_ELBOW_BEND * brace
	_elbow_right.rotation.x = -WAKE_INTRO_ELBOW_BEND * brace
	_elbow_left.rotation.y = 0.0
	_elbow_right.rotation.y = 0.0
	_elbow_left.rotation.z = 0.0
	_elbow_right.rotation.z = 0.0
	_spine.rotation.x = WAKE_INTRO_SPINE_CURL * brace
	_spine.position.y = _spine_rest_y
	_hips.rotation.z = 0.0
	_hips.position.y = _hips_rest_y
	_head.rotation.x = 0.0
	_head.rotation.y = 0.0
	_head_look_pitch = 0.0
	_head_look_yaw = 0.0

	# Track the centre of the face throughout the whole get-up motion. The
	# camera orientation follows the body's lie-to-stand angle, keeping the
	# close-up face-on rather than leaving the head to travel out of frame.
	var face_world := _head.to_global(Vector3(0.0, ProceduralFigure.HEAD_SIZE.y, 0.0))
	var close_pitch := lerp_angle(WAKE_INTRO_CAMERA_PITCH, 0.0, rise)
	var settle_time := (
		_wake_intro_elapsed - WAKE_INTRO_REST_DURATION - WAKE_INTRO_RISE_DURATION
	)
	var settle_linear := clampf(
		settle_time / WAKE_INTRO_SETTLE_DURATION, 0.0, 1.0
	)
	var camera_settle := smoothstep(0.0, 1.0, settle_linear)
	# _update_camera_follow() has already placed this frame's ordinary
	# framing, so the close-up settles back into exactly what follow will
	# keep producing once the intro ends.
	camera_rig.global_position = face_world.lerp(camera_rig.global_position, camera_settle)
	camera_pivot.rotation.x = lerp_angle(
		close_pitch, _wake_intro_camera_pitch_rest, camera_settle
	)
	camera_spring_arm.spring_length = lerpf(
		WAKE_INTRO_CAMERA_DISTANCE, camera_spring_arm.spring_length, camera_settle
	)


func _apply_wake_intro_eyes() -> void:
	# Keep the close-up unmistakably asleep through the opening hold, then
	# open the eyes before the body begins most of its rise. This runs after
	# the normal animation updates, so the ambient blink clock cannot stamp
	# them open again during the wake tableau.
	var opening_time: float = _wake_intro_elapsed - WAKE_INTRO_REST_DURATION
	var opening: float = smoothstep(
		0.0, 1.0, clampf(opening_time / WAKE_INTRO_EYE_OPEN_DURATION, 0.0, 1.0)
	)
	_set_eye_openness(lerpf(EyeBlink.CLOSED_OPENNESS, 1.0, opening))


func _set_eye_openness(openness: float) -> void:
	for eye in _eyes:
		if is_instance_valid(eye):
			(eye as Node3D).scale.y = openness


func _finish_wake_intro() -> void:
	visuals.rotation.x = 0.0
	visuals.rotation.z = 0.0
	visuals.position.y = -FOOT_OFFSET
	camera_pivot.rotation.x = _wake_intro_camera_pitch_rest
	_set_eye_openness(1.0)
	if _wake_intro_has_final_transform:
		global_transform = _wake_intro_final_transform
		_wake_intro_has_final_transform = false
	_wake_intro_active = false
	WorldState.opening_wake_completed = true
	if _wake_intro_owns_modal_lock:
		UIState.pop_modal()
		_wake_intro_owns_modal_lock = false


func _exit_tree() -> void:
	# Defensive cleanup if the scene is ever replaced externally during the
	# opening; an autoloaded modal counter must not retain this player's lock.
	if _wake_intro_owns_modal_lock:
		UIState.pop_modal()
		_wake_intro_owns_modal_lock = false


func _toggle_blorbus_control() -> void:
	_cycle_playable_character(1)


func playable_switch_order() -> int:
	return _playable_profile.switch_order


func _cycle_playable_character(direction: int) -> void:
	var target: Node3D = PartyControl.adjacent_switchable_member(get_tree(), direction)
	if target == null or target == PartyControl.active_member():
		return
	var target_id: String = String(target.playable_id())
	if is_instance_valid(_controlled_generic_member):
		_end_generic_party_control()
	match target_id:
		PartyControl.HUMAN_ID:
			if _piloting_xiao_hou_zi:
				_end_xiao_hou_zi_control()
			elif _player_following_blorbus:
				_end_blorbus_control()
		PartyControl.BLORBUS_ID:
			if _piloting_xiao_hou_zi:
				_end_xiao_hou_zi_control()
			_try_start_blorbus_control()
		PartyControl.XIAO_HOU_ZI_ID:
			_try_start_xiao_hou_zi_control()
		_:
			_start_generic_party_control(target)


func _start_generic_party_control(member: Node3D) -> bool:
	if member == null or not member.has_method("drive_from_player"):
		push_warning("Playable roster member has no movement adapter: %s" % String(member.playable_id()))
		return false
	if _piloting_xiao_hou_zi:
		_end_xiao_hou_zi_control()
	elif _player_following_blorbus:
		_release_blorbus_and_giant_possession()
		_player_following_blorbus = false
	_controlled_generic_member = member
	_begin_following_as_shell()
	collision_layer = 0
	PartyControl.set_active_member(member)
	return true


func _end_generic_party_control() -> void:
	_controlled_generic_member = null
	collision_layer = 2
	PartyControl.set_active_member(self)


func _update_generic_party_control(delta: float) -> void:
	var member := _controlled_generic_member
	if not is_instance_valid(member):
		_end_generic_party_control()
		return
	if member.has_method("prepare_direct_control_environment"):
		member.prepare_direct_control_environment(delta)
	var pitched: bool = member.has_method("uses_pitched_movement_input") and bool(member.uses_pitched_movement_input())
	var input := _get_move_input()
	var basis: Basis = camera.global_transform.basis if pitched else camera_rig.global_transform.basis
	var direction: Vector3 = basis.x * input.x + basis.z * input.y
	if not pitched:
		direction.y = 0.0
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	var jump_pressed: bool = Input.is_action_just_pressed("jump") and not UIState.modal_open
	member.drive_from_player(direction, delta, _is_sprinting(), jump_pressed)
	_follow_controlled_party_body(member, delta)


func _legacy_toggle_blorbus_control() -> void:
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
			PartyControl.set_active_member(blorbus)
			_player_following_blorbus = true
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
	_player_following_blorbus = false
	_controlled_xiao_hou_zi = monkey
	_piloting_xiao_hou_zi = true
	_begin_following_as_shell()
	# Only the currently controlled pawn should activate proximity areas.
	# The human remains solid to the world through collision_mask, but stops
	# presenting itself as the interaction body while following Xiao.
	collision_layer = 0
	PartyControl.set_active_member(monkey)
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
	if is_instance_valid(_sun_wu_kong_summon):
		_sun_wu_kong_summon.dismiss()
	_sun_wu_kong_summon = null
	_piloting_xiao_hou_zi = false
	if is_instance_valid(_controlled_xiao_hou_zi):
		_controlled_xiao_hou_zi.end_direct_control()
	_controlled_xiao_hou_zi = null
	collision_layer = 2
	PartyControl.set_active_member(self)
	Hud.show_message("You are now controlling the player.")


## Once the Jingu Bang has been returned, Xiao Hou Zi calls Sun Wu Kong at
## the first sign of active combat. The summoned actor owns the fight and
## dismisses itself after the last nearby NME is gone.
func _update_sun_wu_kong_summon() -> void:
	if not _piloting_xiao_hou_zi or not WorldState.sun_wu_kong_summon_unlocked:
		return
	if is_instance_valid(_sun_wu_kong_summon):
		return
	for node in get_tree().get_nodes_in_group("skeletons"):
		var enemy := node as Node3D
		if enemy == null or _controlled_xiao_hou_zi.global_position.distance_to(enemy.global_position) > SUN_WU_KONG_SUMMON_TRIGGER_RADIUS:
			continue
		var summon: SunWuKong = SUN_WU_KONG_SCENE.instantiate()
		summon.configure_as_summon(_controlled_xiao_hou_zi)
		summon.position = _controlled_xiao_hou_zi.global_position + _controlled_xiao_hou_zi.global_transform.basis.x * 1.5
		get_parent().add_child(summon)
		_sun_wu_kong_summon = summon
		return


## Shared by _end_blorbus_control() (returning fully to the human) and
## _try_start_xiao_hou_zi_control() (advancing straight from Blorbus/the
## giant into Xiao Hou Zi without passing back through human control) --
## either way, a possessed giant/Blorbus needs to let go and Blorbus needs
## to physically re-emerge if he was merged and invisible.
func _release_blorbus_and_giant_possession() -> void:
	if is_instance_valid(_controlled_giant):
		end_humongous_mind_merge()
	if is_instance_valid(_controlled_blorbus):
		_controlled_blorbus.is_player_controlled = false
	_controlled_blorbus = null


func _end_blorbus_control() -> void:
	_release_blorbus_and_giant_possession()
	_player_following_blorbus = false
	PartyControl.set_active_member(self)
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
	if _manchego_dismount_elapsed >= 0.0:
		_finish_manchego_dismount()
	_release_blorbus_and_giant_possession()
	_mounted_rider = PartyControl.active_member()
	if _mounted_rider == null or not PartyControl.member_capability(_mounted_rider, &"ride_mount"):
		return
	_controlled_manchego = manchego
	PartyControl.set_control_override(manchego)
	_controlled_manchego.begin_ride()
	_player_following_manchego = true
	# top_level lets _apply_manchego_seated_pose() drive `visuals` off Manchego's own live
	# seat transform directly every frame instead of this CharacterBody's
	# own position/rotation.y (which stays a loose, invisible-now follower;
	# see _update_manchego_control()'s own comment for why that's still kept
	# moving underneath).
	if _mounted_rider == self:
		visuals.top_level = true
	elif _mounted_rider.has_method("begin_mounted"):
		_mounted_rider.begin_mounted(manchego)
	# Plain state confirmation, matching every other control-switch message
	# in this file (e.g. "You are now controlling Blorbus.") -- none of them
	# spell out the control used to switch back; see CLAUDE.md's "In-game
	# text and player guidance" rule.
	Hud.show_message("Riding Manchego.")


func _end_manchego_control() -> void:
	# The human rider climbs down beside the horse (see _update_manchego_
	# dismount()). Anything else -- Xiao Hou Zi riding, or Manchego freed
	# mid-ride -- restores at once.
	var climb_down := _mounted_rider == self and visuals.top_level and is_instance_valid(_controlled_manchego)
	if climb_down:
		_place_beside_mount(_controlled_manchego)
		_manchego_dismount_from = visuals.global_transform
		var horse_forward := _controlled_manchego.global_basis.z
		_manchego_dismount_yaw = atan2(horse_forward.x, horse_forward.z)
	if is_instance_valid(_controlled_manchego):
		_controlled_manchego.end_ride()
	_controlled_manchego = null
	PartyControl.clear_control_override()
	_player_following_manchego = false
	if is_instance_valid(_mounted_rider) and _mounted_rider != self and _mounted_rider.has_method("end_mounted"):
		_mounted_rider.end_mounted()
	Hud.show_message("Dismounted.")
	if climb_down:
		_manchego_dismount_elapsed = 0.0
		velocity = Vector3.ZERO
		return
	_finish_manchego_dismount()


## Puts this CharacterBody's feet on the ground at Manchego's left side (the
## traditional near side), else his right, else behind him: the first spot
## where the standing capsule fits. The unseen follower body may be several
## metres behind the horse while riding; this is where the rider really lands.
func _place_beside_mount(mount: Manchego) -> void:
	var seat := mount.get_seat_transform().origin
	var left := mount.global_basis.x
	left.y = 0.0
	left = left.normalized()
	var behind := -mount.global_basis.z
	behind.y = 0.0
	behind = behind.normalized()
	var candidates: Array[Vector3] = [
		seat + left * MANCHEGO_DISMOUNT_SIDE_OFFSET,
		seat - left * MANCHEGO_DISMOUNT_SIDE_OFFSET,
		seat + behind * MANCHEGO_DISMOUNT_BEHIND_OFFSET,
	]
	for index in candidates.size():
		var spot := candidates[index]
		spot.y = float(terrain.get_mesh_height(spot.x, spot.z)) + FOOT_OFFSET
		if index == candidates.size() - 1 or _standing_space_clear(spot, mount):
			global_position = spot
			return


func _standing_space_clear(feet: Vector3, mount: Node3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _collision_shape.shape
	query.transform = Transform3D(_standing_collision_transform.basis, feet + _standing_collision_transform.origin)
	query.collision_mask = collision_mask
	var excluded: Array[RID] = [get_rid()]
	if mount is CollisionObject3D:
		excluded.append((mount as CollisionObject3D).get_rid())
	if terrain is CollisionObject3D:
		excluded.append((terrain as CollisionObject3D).get_rid())
	query.exclude = excluded
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


## Carries the still-top_level figure from the saddle to standing on the
## landing spot _place_beside_mount() chose, easing the riding pose out as it
## goes. Control resumes when it lands.
func _update_manchego_dismount(delta: float) -> void:
	_manchego_dismount_elapsed += delta
	var t := clampf(_manchego_dismount_elapsed / MANCHEGO_DISMOUNT_DURATION, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, t)
	var standing_basis := Basis(Vector3.UP, _manchego_dismount_yaw)
	var standing_origin := global_position + Vector3.DOWN * FOOT_OFFSET
	var from_rotation := _manchego_dismount_from.basis.get_rotation_quaternion()
	visuals.global_transform = Transform3D(
		Basis(from_rotation.slerp(standing_basis.get_rotation_quaternion(), eased)),
		_manchego_dismount_from.origin.lerp(standing_origin, eased) + Vector3.UP * sin(PI * t) * MANCHEGO_DISMOUNT_HOP
	)
	velocity = Vector3.ZERO
	_animate_walk(delta, true, 1.0)
	# The two riding-only twists the ordinary gait never touches.
	var settle := minf(RIDE_POSE_SETTLE_SPEED * delta, 1.0)
	if _neck != null:
		_neck.rotation = _neck.rotation.lerp(Vector3.ZERO, settle)
	_elbow_left.rotation.z = lerp_angle(_elbow_left.rotation.z, 0.0, settle)
	_elbow_right.rotation.z = lerp_angle(_elbow_right.rotation.z, 0.0, settle)
	if t >= 1.0:
		_finish_manchego_dismount()


func _finish_manchego_dismount() -> void:
	_manchego_dismount_elapsed = -1.0
	if _mounted_rider == self and visuals.top_level:
		# Keep the heading the figure already shows (the climb-down ends
		# facing the horse's direction) rather than snapping to world +Z.
		var forward := visuals.global_basis.z
		var yaw := atan2(forward.x, forward.z)
		visuals.top_level = false
		# visuals' position/rotation held GLOBAL values a moment ago (that's
		# what top_level means) -- flipping top_level back off re-interprets
		# whatever numbers are already sitting in .transform as LOCAL
		# instead, so it has to be explicitly reset back to its ordinary
		# resting local transform here.
		visuals.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(0, -FOOT_OFFSET, 0))
		_body_yaw = yaw
	# _neck.rotation.x is otherwise ONLY ever touched by
	# _apply_manchego_seated_pose() (see MANCHEGO_HEAD_UPRIGHT_NECK_SHARE's
	# own comment) -- nothing in the ordinary walk/idle/jump code eases it
	# back to rest on its own. The same holds for the elbows' rotation.z
	# (RIDE_ELBOW_INWARD). The climb-down eases both; this makes them exact.
	if _mounted_rider == self:
		if _neck != null:
			_neck.rotation = Vector3.ZERO
		_elbow_left.rotation.z = 0.0
		_elbow_right.rotation.z = 0.0
	_mounted_rider = null


## Mirrors _update_blorbus_control() closely -- see that function's own
## comments for the follow-cadence/floor-snap reasoning this reuses
## verbatim. No jump input and no lake/cloud/canopy handling: Manchego is
## ground-only for this first pass (see manchego.gd's own drive_from_player()
## doc comment).
func _update_manchego_control(delta: float) -> void:
	if not is_instance_valid(_controlled_manchego):
		_end_manchego_control()
		return
	# The back button (see input_map.gd's "dismount"), not Interact, so the
	# press that mounted can never be read again as a dismount.
	if Input.is_action_just_pressed("dismount") and not UIState.modal_open:
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
	if _mounted_rider == self:
		_apply_manchego_seated_pose(delta)
	elif is_instance_valid(_mounted_rider) and _mounted_rider.has_method("update_mounted_pose"):
		_mounted_rider.update_mounted_pose(_controlled_manchego.get_seat_transform(), delta)


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
	if is_instance_valid(_controlled_xiao_hou_zi):
		return _controlled_xiao_hou_zi
	return null


func playable_id() -> String:
	return _playable_profile.id


func playable_profile() -> PlayableCharacterProfile:
	return _playable_profile


func is_playable_available() -> bool:
	return true


func has_playable_capability(capability: StringName) -> bool:
	return bool(_playable_profile.capabilities.get(String(capability), false))


func begin_direct_control() -> void:
	pass


func end_direct_control() -> void:
	pass


func restore_active_party_member(member_id: String) -> void:
	match member_id:
		PartyControl.BLORBUS_ID:
			_try_start_blorbus_control()
		PartyControl.XIAO_HOU_ZI_ID:
			_try_start_xiao_hou_zi_control()
		_:
			PartyControl.set_active_member(self)


## Public query for portal.gd: a kingdom gate only opens while Blorbus (or
## the giant he merged into) is the one being directly piloted -- see that
## file's own doc comment for why this is the gate.
func is_piloting_blorbus() -> bool:
	return is_instance_valid(_controlled_blorbus) or is_instance_valid(_controlled_giant)


## Whichever body currently has the player's direct control -- Blorbus, or
## the giant post-merge, or null while playing as the human. Lets a portal
## key its own proximity check off Blorbus's actual position rather than the
## trailing human companion's (see portal.gd's _update_pilot_proximity()) --
## the human only follows within PLAYER_FOLLOW_DISTANCE/ARRIVE_DISTANCE of
## Blorbus, not of whatever Blorbus happens to be standing next to.
func get_controlled_body() -> Node3D:
	var controlled := PartyControl.active_control_body()
	return controlled if controlled != self else null


func _update_xiao_hou_zi_control(delta: float) -> void:
	if not is_instance_valid(_controlled_xiao_hou_zi):
		_end_xiao_hou_zi_control()
		return
	var input := _get_move_input()
	_controlled_xiao_hou_zi.prepare_direct_control_environment(delta)
	var basis := (
		camera.global_transform.basis
		if _controlled_xiao_hou_zi.uses_pitched_movement_input()
		else camera_rig.global_transform.basis
	)
	var direction := basis.x * input.x + basis.z * input.y
	if not _controlled_xiao_hou_zi.uses_pitched_movement_input():
		direction.y = 0.0
	if direction.length_squared() > 0.0001:
		direction = direction.normalized()
	var jump_pressed := Input.is_action_just_pressed("jump") and not UIState.modal_open
	_controlled_xiao_hou_zi.drive_from_player(direction, delta, _is_sprinting(), jump_pressed)
	_follow_controlled_party_body(_controlled_xiao_hou_zi, delta)


## The human hands control to a party member and starts following it (see
## _follow_controlled_party_body()). Drops any run or jump in progress: the
## follow code leaves velocity untouched between its arrive and follow
## distances, so a run would otherwise carry on as a slide, and a stale jump
## would cost a frame of grounding when control comes back.
func _begin_following_as_shell() -> void:
	_jumping = false
	velocity = Vector3.ZERO


func _follow_controlled_party_body(target: Node3D, delta: float) -> void:
	var offset := target.global_position - global_position
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
	if not is_on_floor():
		global_position.y = terrain.get_mesh_height(global_position.x, global_position.z) + FOOT_OFFSET
	var actual_motion := global_position - before_move
	actual_motion.y = 0.0
	if actual_motion.length_squared() > 0.000001:
		_body_yaw = atan2(actual_motion.x, actual_motion.z)
	# Following is always an upright walk (any flight tilt is released), and
	# the body was just snapped to the ground above, so it is grounded whether
	# or not it moved; idling here must not play the airborne pose.
	_pose_body_ground(-FOOT_OFFSET)
	_animate_walk(delta, true, 1.0)


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
	if not _lake_buoyancy_active and not is_on_floor():
		global_position.y = terrain.get_mesh_height(global_position.x, global_position.z) + FOOT_OFFSET
	# Face the motion that actually occurred, not merely the desired line to
	# Blorbus. Collision sliding and the 7m/3m follow hysteresis can make
	# those differ, which previously produced sideways/backward moonwalking.
	var actual_motion := global_position - before_move
	actual_motion.y = 0.0
	if actual_motion.length_squared() > 0.000001:
		_body_yaw = atan2(actual_motion.x, actual_motion.z)
	_pose_body_ground(-FOOT_OFFSET)
	_animate_walk(delta, true, 1.0)


func begin_humongous_mind_merge(giant: Blorb) -> bool:
	if giant == null or not is_instance_valid(giant):
		return false
	if not is_instance_valid(_controlled_blorbus):
		var active := PartyControl.active_member()
		if active is Blorb and (active as Blorb).is_blorbus:
			_controlled_blorbus = active as Blorb
	if not is_instance_valid(_controlled_blorbus):
		return false
	if not giant.begin_psychic_control(_controlled_blorbus):
		return false
	_controlled_blorbus.visible = false
	_controlled_blorbus.end_direct_control()
	_controlled_giant = giant
	_player_following_blorbus = true
	PartyControl.set_control_override(giant, _controlled_blorbus)
	HumongousState.mark_merged()
	Hud.show_message("Blorbus's mind joined Humongous.")
	return true


func end_humongous_mind_merge() -> void:
	if not is_instance_valid(_controlled_giant):
		return
	var giant := _controlled_giant
	giant.end_psychic_control(_controlled_blorbus)
	PartyControl.clear_control_override(giant)
	if is_instance_valid(_controlled_blorbus):
		var emerge_direction := global_position - giant.global_position
		emerge_direction.y = 0.0
		if emerge_direction.length_squared() < 0.01:
			emerge_direction = giant.global_transform.basis.z
		emerge_direction.y = 0.0
		emerge_direction = emerge_direction.normalized()
		var emerge_pos := giant.global_position + emerge_direction * (Blorb.RADIUS * giant.size_multiplier + 1.0)
		emerge_pos.y = terrain.get_mesh_height(emerge_pos.x, emerge_pos.z)
		_controlled_blorbus.global_position = emerge_pos
		_controlled_blorbus.visible = true
		_controlled_blorbus.begin_direct_control()
	_controlled_giant = null
	HumongousState.mark_released()
	Hud.show_message("Blorbus released the mind merge.")


## The only writer of the camera rig's placement and the spring arm's length
## and offset (the wake intro's close-up is a cinematic layered on top, see
## _apply_wake_intro_pose()). Runs in _process(), after physics has moved
## every body this frame. Framing always comes from whichever body
## PartyControl reports as controlled, via the camera_focus_point() /
## camera_follow_distance() contract, so switching characters, mounting, or
## a mind merge never has to move the camera itself.
func _update_camera_follow(delta: float) -> void:
	var subject := PartyControl.active_control_body()
	if not is_instance_valid(subject) or not subject.has_method("camera_focus_point"):
		subject = self
	var distance: float = subject.camera_follow_distance()
	var focus: Vector3 = subject.camera_focus_point()
	if subject != _camera_subject:
		if _camera_subject != null and camera_rig.global_position.distance_to(focus) < CAMERA_HANDOFF_MAX_DISTANCE:
			_camera_handoff_from_focus = camera_rig.global_position
			_camera_handoff_from_distance = _camera_last_distance
			_camera_handoff_remaining = CAMERA_HANDOFF_DURATION
		else:
			_camera_handoff_remaining = 0.0
		_camera_subject = subject
		# The spring arm pulls in at anything solid behind the focus. The body
		# being followed is solid too (Manchego, Blorbus): looking up while it
		# faced the camera swung the arm through it and snapped the camera in
		# against the back of the rider's head. Never collide with it.
		camera_spring_arm.clear_excluded_objects()
		camera_spring_arm.add_excluded_object(get_rid())
		if subject is CollisionObject3D:
			camera_spring_arm.add_excluded_object((subject as CollisionObject3D).get_rid())
	if _camera_handoff_remaining > 0.0:
		_camera_handoff_remaining = maxf(_camera_handoff_remaining - delta, 0.0)
		var handoff := smoothstep(0.0, 1.0, 1.0 - _camera_handoff_remaining / CAMERA_HANDOFF_DURATION)
		focus = _camera_handoff_from_focus.lerp(focus, handoff)
		distance = lerpf(_camera_handoff_from_distance, distance, handoff)
	_camera_last_distance = distance
	var root_yaw := global_rotation.y
	if not is_equal_approx(root_yaw, _camera_follow_root_yaw):
		camera_rig.rotate_y(angle_difference(_camera_follow_root_yaw, root_yaw))
		_camera_follow_root_yaw = root_yaw
	_throw_camera_blend = lerpf(
		_throw_camera_blend, 1.0 if _throw_aim_active else 0.0,
		clampf(THROW_CAMERA_BLEND_SPEED * delta, 0.0, 1.0)
	)
	camera_rig.global_position = focus
	camera_spring_arm.spring_length = distance * lerpf(1.0, THROW_CAMERA_DISTANCE_SCALE, _throw_camera_blend)
	# SpringArm3D owns its Camera3D child's local position and rewrites it as
	# collision length resolves, so the aim's shoulder offset moves the arm's
	# own frame instead of fighting that engine update on the camera.
	camera_spring_arm.position = Vector3(THROW_CAMERA_RIGHT_OFFSET * _throw_camera_blend, 0.0, 0.0)


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
			if is_instance_valid(_controlled_blorbus) and HumongousState.is_carried():
				HumongousState.show_carried_actions(self)
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
## wrist flex/twist doesn't get that for free -- nothing else in this
## file normally restores the hand rotations -- so _rest_hand_roll() below
## explicitly eases them back to the normal static wrist orientation
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
	var right_power := (
		Input.is_action_pressed("right_arm_power")
		and not _fire_hand_hover_active
		and not _throw_aim_active
		and not _held_item_is_weapon()
	)
	# Pressing all four limb buttons to form the Penguin Suit is not a power.
	if _penguin_chord_holding:
		left_power = false
		right_power = false
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


## `side` is the ARM being posed (+1 left, -1 right -- ProceduralFigure's
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
	# Use the exact quarter-turn while raised. Keeping the relaxed wrist's
	# additional inward angle here tilts the supposedly vertical fingertips
	# back toward the body's centre line.
	var hand_parent := hand.get_parent() as Node3D
	if hand_parent != null:
		# ProceduralFigure's hand uses local +Z as its palm normal and local
		# -Y from wrist to fingertips. Build the anatomical target explicitly:
		# palm toward the hero's front, fingertips vertically skyward.
		var body_basis := visuals.global_transform.basis.orthonormalized()
		var desired_world_basis := Basis(-body_basis.x, -body_basis.y, body_basis.z)
		var desired_local_basis := (
			hand_parent.global_transform.basis.orthonormalized().inverse()
			* desired_world_basis
		).orthonormalized()
		hand.quaternion = hand.quaternion.slerp(
			desired_local_basis.get_rotation_quaternion(), clampf(weight, 0.0, 1.0)
		)
	_anchor_hand_to_wrist(hand)


func _rest_hand_roll(hand: Node3D, side: float, t: float) -> void:
	var rest_twist := -side * (PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE)
	hand.rotation.x = lerp_angle(hand.rotation.x, 0.0, t)
	hand.rotation.y = lerp_angle(hand.rotation.y, rest_twist, t)
	hand.rotation.z = lerp_angle(hand.rotation.z, 0.0, t)
	_anchor_hand_to_wrist(hand)


## ProceduralFigure's visible hand node is centred within the hand mesh, not
## located at the wrist. Preserve the authored WristAttach point while the
## hand flexes so a 90-degree palm-forward pose bends cleanly at the joint
## instead of rotating the mesh around its middle and pulling it loose from
## the forearm. MonkeyFigure already returns its endpoint as both hand and
## wrist, so that rig correctly needs no compensation.
func _cache_hand_wrist(hand: Node3D, wrist: Node3D) -> void:
	if hand == null or wrist == null or hand == wrist:
		return
	var key := hand.get_instance_id()
	_hand_wrist_offsets[key] = wrist.position
	_hand_wrist_anchors[key] = hand.position + hand.basis * wrist.position


func _anchor_hand_to_wrist(hand: Node3D) -> void:
	var key := hand.get_instance_id()
	if not _hand_wrist_anchors.has(key):
		return
	var wrist_offset: Vector3 = _hand_wrist_offsets[key]
	hand.position = (_hand_wrist_anchors[key] as Vector3) - hand.basis * wrist_offset


## Straddle pose for the dirt blorb suit's rear wheel, plus the wheelie's
## forward body lean -- called last in the per-frame pose chain (after
## _apply_arm_power_poses(), same reasoning as that function's own doc
## comment: it has to override whatever _animate_walk() set unconditionally,
## with no gap). The leg joints need no explicit "ease back to normal" branch
## here: _animate_walk() already drives them every single frame regardless
## (see _apply_arm_power_poses()'s own comment on this exact point), so once
## _dirtbike_pose_blend decays to 0 and this stops touching them, that
## already-running normal pose simply resumes untouched. `visuals.rotation.x`
## has no such standing owner during ordinary grounded movement, though, so
## the wheelie pitch DOES need its own explicit two-target ease.
func _apply_dirtbike_pose(delta: float) -> void:
	var pose_t := DIRTBIKE_POSE_SETTLE_SPEED * delta
	_dirtbike_pose_blend = move_toward(_dirtbike_pose_blend, 1.0 if _dirtbike_wheel_active else 0.0, pose_t)
	# Computed here (not down by the front wheel's own presence check below)
	# since the arm pose right below now needs it too -- see that block's
	# own comment.
	_dirtbike_wheelie_blend = move_toward(
		_dirtbike_wheelie_blend, 1.0 if _dirtbike_wheelie_active else 0.0, DIRTBIKE_WHEELIE_SETTLE_SPEED * delta
	)
	if _dirtbike_pose_blend > 0.001:
		var w := _dirtbike_pose_blend
		_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, -DIRTBIKE_HIP_BACK_ANGLE, w)
		_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, -DIRTBIKE_HIP_BACK_ANGLE, w)
		_leg_left.rotation.z = lerp_angle(_leg_left.rotation.z, signf(_leg_left.position.x) * DIRTBIKE_HIP_SPLAY, w)
		_leg_right.rotation.z = lerp_angle(_leg_right.rotation.z, signf(_leg_right.position.x) * DIRTBIKE_HIP_SPLAY, w)
		_knee_left.rotation.x = lerp_angle(_knee_left.rotation.x, DIRTBIKE_KNEE_BEND, w)
		_knee_right.rotation.x = lerp_angle(_knee_right.rotation.x, DIRTBIKE_KNEE_BEND, w)
		_ankle_left.rotation.x = lerp_angle(_ankle_left.rotation.x, DIRTBIKE_ANKLE_BEND, w)
		_ankle_right.rotation.x = lerp_angle(_ankle_right.rotation.x, DIRTBIKE_ANKLE_BEND, w)
		# Per direct correction ("I still see the up and down movement of his
		# upper body as an artefact from the walk cycle") -- _animate_walk()
		# (called earlier this same frame) sets _spine/_hips.position.y to a
		# per-stride bob every frame regardless of dirtbike state; nothing
		# else ever eases it back to rest on its own the way the leg/arm
		# rotations above get resumed by _animate_walk() itself once this
		# stops touching them (rotations vs. this literal Y-position offset
		# are different properties, so there's no equivalent "already
		# running" owner to fall back on here -- this has to do it directly).
		_spine.position.y = lerpf(_spine.position.y, _spine_rest_y, w)
		_hips.position.y = lerpf(_hips.position.y, _hips_rest_y, w)
		# Per direct correction, the wheelie is now a TOGGLE ("if both are
		# pressed down then it toggles the arm wheel to on. pressing both
		# again toggles it to off") rather than held -- see
		# _dirtbike_wheelie_toggled_on's own doc comment. That means the
		# arms have to stay raised for as long as the toggle is on even
		# after the player lets go of both buttons, which
		# _apply_arm_power_poses() (called earlier this same frame) has no
		# way to know about -- it only ever reacts to the buttons
		# themselves being currently held. So while toggled on, this drives
		# the SAME extended-arm pose that function uses directly, taking
		# over regardless of the buttons' live state.
		if _dirtbike_wheelie_active:
			_pose_extended_arm(_arm_left, _elbow_left, _hand_left, 1.0, _dirtbike_wheelie_blend)
			_pose_extended_arm(_arm_right, _elbow_right, _hand_right, -1.0, _dirtbike_wheelie_blend)
		else:
			# Per direct correction ("arm motion should not run when
			# traversing with the wheel legs, they should remain in resting
			# position") -- each arm rests independently of the other, so
			# this never fights _apply_arm_power_poses() for whichever arm
			# IS actively raised for some other elemental arm power.
			# Originally gated on BOTH blends being zero together, which
			# meant holding just one arm button left the OTHER, untouched
			# arm with nothing overriding _animate_walk()'s own walk-cycle
			# swing on it at all -- confirmed backwards by direct report
			# ("only one arm is held down, the other arm seems to still be
			# wanting to wiggle like in the walk or run animation as if
			# it's leaking through").
			if _left_arm_power_blend <= 0.001:
				_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, 0.0, w)
				_arm_left.rotation.y = lerp_angle(_arm_left.rotation.y, 0.0, w)
				_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, 0.0, w)
				_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, 0.0, w)
			if _right_arm_power_blend <= 0.001:
				_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, 0.0, w)
				_arm_right.rotation.y = lerp_angle(_arm_right.rotation.y, 0.0, w)
				_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, 0.0, w)
				_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, 0.0, w)

## Regular (left-foot-forward) snowboard stance. The lower body stays
## side-on to the board while abdomen and thorax share the turn toward the
## downhill gaze, leaving the neck only the final natural portion.
func _apply_snowboard_pose(delta: float) -> void:
	_snowboard_pose_blend=move_toward(
		_snowboard_pose_blend,1.0 if _snowboard_active else 0.0,
		SNOWBOARD_POSE_SETTLE_SPEED*delta
	)
	if _snowboard_pose_blend<=0.001:
		_spine.rotation.z=lerp_angle(_spine.rotation.z,0.0,minf(SNOWBOARD_POSE_SETTLE_SPEED*delta,1.0))
		if _thorax!=null:
			_thorax.rotation.z=lerp_angle(_thorax.rotation.z,0.0,minf(SNOWBOARD_POSE_SETTLE_SPEED*delta,1.0))
		return
	var w:=_snowboard_pose_blend
	var tuck:=1.0 if _is_sprinting() and _snowboard_active else 0.0
	var speed_ratio:=clampf(Vector2(velocity.x,velocity.z).length()/SNOWBOARD_FULL_LEAN_SPEED,0.0,1.0)
	var forward_lean:=(SNOWBOARD_SPEED_LEAN_MAX*speed_ratio+SNOWBOARD_TUCK_LEAN*tuck)*w
	var hip_target:=-(SNOWBOARD_HIP_BEND+SNOWBOARD_TUCK_HIP_BEND*tuck)
	_leg_left.rotation.x=lerp_angle(_leg_left.rotation.x,hip_target,w)
	_leg_right.rotation.x=lerp_angle(_leg_right.rotation.x,hip_target,w)
	_leg_left.rotation.z=lerp_angle(
		_leg_left.rotation.z,signf(_leg_left.position.x)*SNOWBOARD_STANCE_SPLAY,w
	)
	_leg_right.rotation.z=lerp_angle(
		_leg_right.rotation.z,signf(_leg_right.position.x)*SNOWBOARD_STANCE_SPLAY,w
	)
	var knee_target:=SNOWBOARD_KNEE_BEND+SNOWBOARD_TUCK_KNEE_BEND*tuck
	_knee_left.rotation.x=lerp_angle(_knee_left.rotation.x,knee_target,w)
	_knee_right.rotation.x=lerp_angle(_knee_right.rotation.x,knee_target,w)
	_ankle_left.rotation.x=lerp_angle(_ankle_left.rotation.x,0.0,w)
	_ankle_right.rotation.x=lerp_angle(_ankle_right.rotation.x,0.0,w)
	# Balance arms are wider than idle and open further in the aerodynamic
	# crouch. An actively commanded arm power retains precedence.
	var arm_spread:=SNOWBOARD_ARM_SPREAD+SNOWBOARD_TUCK_ARM_SPREAD*tuck
	var elbow_bend:=SNOWBOARD_ELBOW_BEND+SNOWBOARD_TUCK_ELBOW_BEND*tuck
	if _left_arm_power_blend<=0.001:
		_arm_left.rotation.x=lerp_angle(_arm_left.rotation.x,0.0,w)
		_arm_left.rotation.z=lerp_angle(_arm_left.rotation.z,signf(_arm_left.position.x)*arm_spread,w)
		_elbow_left.rotation.x=lerp_angle(_elbow_left.rotation.x,-elbow_bend,w)
	if _right_arm_power_blend<=0.001 and HeldItem.current.is_empty():
		_arm_right.rotation.x=lerp_angle(_arm_right.rotation.x,0.0,w)
		_arm_right.rotation.z=lerp_angle(_arm_right.rotation.z,signf(_arm_right.position.x)*arm_spread,w)
		_elbow_right.rotation.x=lerp_angle(_elbow_right.rotation.x,-elbow_bend,w)
	_spine.rotation.y=lerp_angle(_spine.rotation.y,SNOWBOARD_ABDOMEN_TWIST,w)
	_spine.rotation.z=lerp_angle(_spine.rotation.z,forward_lean,minf(SNOWBOARD_POSE_SETTLE_SPEED*delta,1.0))
	if _thorax!=null:
		_thorax.rotation.y=lerp_angle(_thorax.rotation.y,SNOWBOARD_THORAX_TWIST,w)
		_thorax.rotation.z=lerp_angle(_thorax.rotation.z,forward_lean*0.35,minf(SNOWBOARD_POSE_SETTLE_SPEED*delta,1.0))
	_spine.position.y=lerpf(_spine.position.y,_spine_rest_y,w)
	_hips.position.y=lerpf(_hips.position.y,_hips_rest_y,w)
	# Joint flexion lowers the pelvis naturally. Preserve the actual midpoint
	# between the two ankles after posing so the stance sinks around planted
	# feet instead of translating the rider toward either board edge.


## Alternating speed-skating stroke: one leg glides under the body's weight
## while the other pushes diagonally back/out, then the roles cross-fade.
## This runs after the ordinary gait so no walk cycle leaks through the
## skate silhouette, and eases away cleanly when the runners leave the ice.
func _apply_ice_skate_pose(delta: float) -> void:
	var planar_speed:=Vector2(velocity.x,velocity.z).length()
	var moving: bool=_ice_skating_active and planar_speed>0.12
	_ice_skate_pose_blend=move_toward(
		_ice_skate_pose_blend,1.0 if moving else 0.0,
		ICE_SKATE_POSE_SETTLE_SPEED*delta
	)
	if not moving:
		_ice_skate_previous_speed=planar_speed
		_ice_skate_smoothed_acceleration=0.0
		# Once ice support is gone, _animate_walk() has already run earlier
		# this frame and owns the correct walk/idle/jump targets. Do not write
		# a fading skating target over those freshly restored rotations: the
		# old path did exactly that until an arbitrarily tiny blend, then
		# returned and could strand a residual forward lean indefinitely.
		if _ice_skating_active:
			# While stopped but still on ice, ordinary gait is intentionally
			# suppressed, so this layer itself must settle its torso to neutral.
			var rest_t:=minf(ICE_SKATE_POSE_SETTLE_SPEED*delta,1.0)
			_spine.rotation.x=lerp_angle(_spine.rotation.x,0.0,rest_t)
			if _thorax!=null:
				_thorax.rotation.x=lerp_angle(_thorax.rotation.x,0.0,rest_t)
		return
	# Preserve the feet's physical contact while the deeper sprint flexion
	# lowers the body through the hip and knee chain.
	var w:=_ice_skate_pose_blend
	# Pose strength and temporal interpolation are distinct. Using w itself as
	# lerp weight became a literal one-frame snap once the blend reached 1.0.
	var pose_t:=minf(ICE_SKATE_POSE_SETTLE_SPEED*delta,1.0)*w
	var sprinting:=_is_sprinting()
	var effort:=ICE_SKATE_SPRINT_POSE_MULTIPLIER if sprinting else 1.0
	var raw_acceleration:=maxf((planar_speed-_ice_skate_previous_speed)/maxf(delta,0.0001),0.0)
	_ice_skate_previous_speed=planar_speed
	_ice_skate_smoothed_acceleration=lerpf(
		_ice_skate_smoothed_acceleration,raw_acceleration,
		1.0-exp(-5.0*delta)
	)
	var thrust_mix:=clampf(_ice_skate_smoothed_acceleration/ICE_SKATE_FULL_THRUST_ACCELERATION,0.0,1.0)
	var cadence:=lerpf(ICE_SKATE_CADENCE_GLIDE,ICE_SKATE_CADENCE_THRUST,smoothstep(0.0,1.0,thrust_mix))
	_ice_skate_stride_phase+=delta*cadence
	var cycle:=fposmod(_ice_skate_stride_phase/TAU,1.0)
	var left_stroke:=ice_skate_stroke(cycle)
	var right_stroke:=ice_skate_stroke(fposmod(cycle+0.5,1.0))
	var left_push:=left_stroke.x
	var right_push:=right_stroke.x
	var left_recovery:=left_stroke.y
	var right_recovery:=right_stroke.y
	var left_support:=left_stroke.z
	var right_support:=right_stroke.z
	var left_knee:=(ICE_SKATE_GLIDE_KNEE*left_support+ICE_SKATE_PUSH_KNEE*left_push+ICE_SKATE_RECOVERY_KNEE*left_recovery)*effort
	var right_knee:=(ICE_SKATE_GLIDE_KNEE*right_support+ICE_SKATE_PUSH_KNEE*right_push+ICE_SKATE_RECOVERY_KNEE*right_recovery)*effort
	# Positive X is backward for this procedural leg rig (the same verified
	# convention used by the run arms). The old negative push kicked forward.
	var left_hip_x:=ICE_SKATE_PUSH_HIP_BACK*left_push*effort-ICE_SKATE_RECOVERY_HIP_FORWARD*left_recovery-ICE_SKATE_GLIDE_HIP_FORWARD*left_support*effort
	var right_hip_x:=ICE_SKATE_PUSH_HIP_BACK*right_push*effort-ICE_SKATE_RECOVERY_HIP_FORWARD*right_recovery-ICE_SKATE_GLIDE_HIP_FORWARD*right_support*effort
	_leg_left.rotation.x=lerp_angle(_leg_left.rotation.x,left_hip_x,pose_t)
	_leg_right.rotation.x=lerp_angle(_leg_right.rotation.x,right_hip_x,pose_t)
	# This rig's local yaw signs are opposite the earlier assumption: positive
	# on the left and negative on the right open the toes, not the heels.
	_leg_left.rotation.y=lerp_angle(_leg_left.rotation.y,ICE_SKATE_TOE_OUT*left_push*effort,pose_t)
	_leg_right.rotation.y=lerp_angle(_leg_right.rotation.y,-ICE_SKATE_TOE_OUT*right_push*effort,pose_t)
	_knee_left.rotation.x=lerp_angle(_knee_left.rotation.x,left_knee,pose_t)
	_knee_right.rotation.x=lerp_angle(_knee_right.rotation.x,right_knee,pose_t)
	# Resolve lateral extension after the sprint hip, toe, and knee pose is
	# present. Deep flex changes the combined Euler result substantially, so
	# measuring before these joints were posed could select a value that read
	# correctly at normal effort but folded inward during sprint.
	var outward_amount:=ICE_SKATE_SPRINT_PUSH_OUTWARD if sprinting else ICE_SKATE_PUSH_OUTWARD
	_leg_left.rotation.z=lerp_angle(
		_leg_left.rotation.z,_ice_skate_outward_roll(_leg_left,_ankle_left,outward_amount)*left_push,pose_t
	)
	_leg_right.rotation.z=lerp_angle(
		_leg_right.rotation.z,_ice_skate_outward_roll(_leg_right,_ankle_right,outward_amount)*right_push,pose_t
	)
	# Counter the complete support-leg chain at the ankle. This keeps the
	# weighted front runner parallel to the ice instead of pitching with the
	# deeply bent knee; the pushing/recovering runner is allowed to articulate.
	_ankle_left.rotation.x=lerp_angle(_ankle_left.rotation.x,-(left_hip_x+left_knee)*left_support,pose_t)
	_ankle_right.rotation.x=lerp_angle(_ankle_right.rotation.x,-(right_hip_x+right_knee)*right_support,pose_t)
	# Run-like opposition, held on exactly the same support weights as the
	# legs: left glide leg pairs with the bent right arm forward and vice versa.
	var sprint_arm_lift:=ICE_SKATE_SPRINT_ARM_LIFT if sprinting else 0.0
	_arm_left.rotation.x=lerp_angle(_arm_left.rotation.x,(-ICE_SKATE_ARM_SWING*right_support+ICE_SKATE_ARM_SWING*0.55*left_support)*effort-sprint_arm_lift,pose_t)
	_arm_right.rotation.x=lerp_angle(_arm_right.rotation.x,(-ICE_SKATE_ARM_SWING*left_support+ICE_SKATE_ARM_SWING*0.55*right_support)*effort-sprint_arm_lift,pose_t)
	_elbow_left.rotation.x=lerp_angle(_elbow_left.rotation.x,-ICE_SKATE_ELBOW_BEND*right_support*effort,pose_t)
	_elbow_right.rotation.x=lerp_angle(_elbow_right.rotation.x,-ICE_SKATE_ELBOW_BEND*left_support*effort,pose_t)
	var skate_lean:=ICE_SKATE_BODY_LEAN+(ICE_SKATE_SPRINT_BODY_LEAN if sprinting else 0.0)
	_spine.rotation.x=lerp_angle(_spine.rotation.x,skate_lean,pose_t)
	if _thorax!=null:
		_thorax.rotation.x=lerp_angle(_thorax.rotation.x,skate_lean*0.35,pose_t)
	# Do not translate the torso and pelvis independently: that visually
	# disconnects them from the fixed hip sockets. (A foot-anchor shift here
	# once meant to lower the whole rig with the bent legs, but the ground
	# pose reset it every frame, so it never took effect and was removed;
	# the body height comes from _body_base_height() alone.)
	_spine.position.y=lerpf(_spine.position.y,_spine_rest_y,pose_t)
	_hips.position.y=lerpf(_hips.position.y,_hips_rest_y,pose_t)


## Resolve lateral hip roll from the live posed hierarchy instead of relying
## on a left/right sign convention. Several playable rigs use different
## local bases; the correct candidate is simply the one that puts the ankle
## farther from the character's centre along that leg's actual side.
func _ice_skate_outward_roll(leg: Node3D,ankle: Node3D,amount: float) -> float:
	var original:=leg.rotation.z
	var right:=visuals.global_transform.basis.x.normalized()
	var side:=signf((leg.global_position-_spine.global_position).dot(right))
	if is_zero_approx(side):
		side=signf(leg.position.x)
	var best_angle:=0.0
	var best_score:=-INF
	# Search the complete safe arc. Merely comparing +/-amount can choose the
	# less-inward endpoint when deep X/Y sprint flex makes both extremes fold
	# toward the centre. Scoring the real ankle endpoint makes the requested
	# left/back-left and right/back-right trajectories explicit.
	for sample in 17:
		var candidate:=lerpf(-amount,amount,float(sample)/16.0)
		leg.rotation.z=candidate
		leg.force_update_transform()
		ankle.force_update_transform()
		var score:=side*(ankle.global_position-leg.global_position).dot(right)
		if score>best_score:
			best_score=score
			best_angle=candidate
	leg.rotation.z=original
	return best_angle


## One skate's support -> push -> forward recovery cycle. The other leg uses
## the same curve half a cycle later. Components are (push, recovery, support)
## and always sum to one, preventing the old side-to-side pendulum motion.
static func ice_skate_stroke(cycle: float) -> Vector3:
	var p:=fposmod(cycle,1.0)
	# Spend most of the first half planted in the glide. Weight transfers
	# quickly into a rearward thrust, the extension hangs briefly, then that
	# leg recovers forward slowly in preparation for its next planted phase.
	var support:=1.0-smoothstep(0.38,0.50,p)+smoothstep(0.88,1.0,p)
	var push:=smoothstep(0.42,0.52,p)*(1.0-smoothstep(0.70,0.88,p))
	var recovery:=smoothstep(0.68,0.80,p)*(1.0-smoothstep(0.90,1.0,p))
	var total:=maxf(push+recovery+support,0.001)
	return Vector3(push,recovery,support)/total


## Called only by _pose_body_dirtbike(), as the last step of placing the
## body (see _compose_body_pose()), not from _apply_dirtbike_pose() alongside
## the leg/arm pose above: the wheelie pitches the already-placed body about
## the rear axle.
func _apply_dirtbike_wheelie_pitch(delta: float,grounded: bool) -> void:
	# Ordinary ground/aerial presentation owns pitch whenever the front wheel
	# is absent. Writing a zero target here was flattening air-chest flight
	# after its camera-space body pose had already been applied.
	if not _dirtbike_wheelie_active:
		_dirtbike_pitch_angular_velocity=0.0
		return
	var wheelie_t: float = minf(DIRTBIKE_WHEELIE_SETTLE_SPEED * delta,1.0)
	var wheelie_target: float = _solve_dirtbike_wheelie_pitch()
	if grounded:
		wheelie_target += _dirtbike_terrain_pitch(delta)
	elif _dirtbike_pitch_was_grounded:
		_dirtbike_pitch_angular_velocity=0.0
		_dirtbike_airborne_pitch = visuals.rotation.x
		wheelie_target = _dirtbike_airborne_pitch
	else:
		_dirtbike_pitch_angular_velocity=0.0
		wheelie_target = _dirtbike_airborne_pitch

	# Pitch activation deliberately hinges around the planted rear axle so the
	# rider and front wheel visibly rotate down into two-wheel mode. Steering
	# yaw remains centre-of-mass anchored in the movement pass; pitch and yaw
	# are separate rotations with separate physical pivots.
	var rear_anchor: Vector3 = (_ankle_left.global_position+_ankle_right.global_position)*0.5
	visuals.rotation.x = lerp_angle(visuals.rotation.x,wheelie_target,wheelie_t)
	var moved_rear: Vector3 = (_ankle_left.global_position+_ankle_right.global_position)*0.5
	visuals.global_position += rear_anchor-moved_rear
	if grounded:
		_settle_dirtbike_rear_wheel_on_terrain()
	_dirtbike_pitch_was_grounded = grounded


## Keeps the rear rim exactly planted throughout the eased transition. Since
## the target pitch is solved from both terrain samples, the front rim meets
## its own surface naturally as the rotation finishes instead of teleporting.
func _settle_dirtbike_rear_wheel_on_terrain() -> void:
	var rear: Vector3 = (_ankle_left.global_position+_ankle_right.global_position)*0.5
	var support: Variant = _dirtbike_wheel_support_height(rear)
	if support == null:
		return
	var rear_contact_y := support as float
	var rear_error: float = rear_contact_y+DIRTBIKE_WHEEL_RADIUS-rear.y
	visuals.global_position.y += rear_error


## Solves the forward lean angle that brings the front wheel (axle at the
## wrists) down to the same height as the rear wheel (axle at the ankles),
## given both wheels share one radius (DIRTBIKE_WHEEL_RADIUS) -- per direct
## instruction ("you must figure out the math to keep the back wheel
## touching the ground but also pitch the player's body forward until the
## perimeter of the front wheel also rests on the ground"). Solved fresh
## from the rig's own current geometry every frame, so it automatically
## tracks the arm-raise pose as it eases in, rather than a single guessed
## fixed angle.
##
## Both wrist/ankle positions are read via global_transform.affine_inverse()
## -- true LOCAL coordinates relative to `visuals`, which by definition
## don't depend on whatever pitch `visuals` itself currently has (unlike its
## global position, which is already pitched by last frame's own result).
## Rotating a local point by an angle around the local X axis maps its Y/Z
## as Y' = Y*cos(angle) - Z*sin(angle) -- Godot's own X-rotation matrix,
## already confirmed for this project (see horse_figure.gd's
## BODY_PITCH_TAKEOFF_AMOUNT for the identical derivation). Solving Y'=0
## (front axle level with the rear one, since equal radii cancel out of that
## equation entirely) gives angle = atan2(rel.y, rel.z) directly. No
## separate sign/quadrant guess is needed the way a fixed constant would --
## rel.y and rel.z's own actual signs (the wrist sits above and in front of
## the ankle once the arms are raised) already pick the one physically
## correct forward-leaning solution on their own. A pure local-X rotation
## never touches the local X (left/right) component, and a world Y (yaw)
## never changes height either, so this result holds regardless of which
## direction the character is currently facing.
func _solve_dirtbike_wheelie_pitch() -> float:
	if not is_instance_valid(_wrist_left) or not is_instance_valid(_wrist_right):
		return 0.0
	if not is_instance_valid(_ankle_left) or not is_instance_valid(_ankle_right):
		return 0.0
	var to_local := visuals.global_transform.affine_inverse()
	var wrist_local: Vector3 = to_local * ((_wrist_left.global_position + _wrist_right.global_position) * 0.5)
	var ankle_local: Vector3 = to_local * ((_ankle_left.global_position + _ankle_right.global_position) * 0.5)
	var rel := wrist_local - ankle_local
	if absf(rel.y) < 0.001 and absf(rel.z) < 0.001:
		return 0.0
	return atan2(rel.y, rel.z)


## Adds the actual terrain angle between the rear and front wheel contacts
## to the rig's flat-ground wheelie solution. Positive local X rotation
## lowers the character's local +Z (front), hence an uphill surface needs
## the negative of atan2(front rise, wheelbase).
func _dirtbike_terrain_pitch(delta: float) -> float:
	if terrain == null:
		return 0.0
	if not is_instance_valid(_wrist_left) or not is_instance_valid(_wrist_right):
		return 0.0
	if not is_instance_valid(_ankle_left) or not is_instance_valid(_ankle_right):
		return 0.0
	var front: Vector3 = (_wrist_left.global_position+_wrist_right.global_position)*0.5
	var rear: Vector3 = (_ankle_left.global_position+_ankle_right.global_position)*0.5
	var wheelbase: float = Vector2(front.x-rear.x,front.z-rear.z).length()
	if wheelbase < 0.05:
		return 0.0
	var front_support: Variant = _dirtbike_wheel_support_height(front)
	var rear_support: Variant = _dirtbike_wheel_support_height(rear)
	if rear_support == null:
		return _dirtbike_supported_pitch
	var rear_height := rear_support as float
	var front_bottom: float = front.y-DIRTBIKE_WHEEL_RADIUS
	if front_support != null:
		var front_height := front_support as float
		if front_bottom-front_height<=0.28:
			_dirtbike_pitch_angular_velocity=0.0
			_dirtbike_supported_pitch=-atan2(front_height-rear_height,wheelbase)
			return _dirtbike_supported_pitch

	# Only the rear wheel is carrying the bike. Integrate the forward pitching
	# moment instead of retaining the last two-wheel angle forever. Contact is
	# checked again every frame, so the fall stops as soon as the front rim
	# reaches rock, ramp, architecture, or terrain.
	_dirtbike_pitch_angular_velocity=minf(
		_dirtbike_pitch_angular_velocity+DIRTBIKE_NOSE_DROP_ANGULAR_ACCELERATION*delta,
		DIRTBIKE_NOSE_DROP_MAX_ANGULAR_SPEED
	)
	# Do not stop at horizontal or at an arbitrary maximum forward pitch. If
	# the surface under the front half is lower, the front wheel is allowed to
	# rotate below the rear axle and keeps falling until its rim actually
	# reaches support. If the rear subsequently leaves support, the normal
	# airborne branch above takes over and preserves that launch attitude.
	_dirtbike_supported_pitch+=_dirtbike_pitch_angular_velocity*delta
	return _dirtbike_supported_pitch


## Returns the nearest real platform surface under a wheel axle. Unlike a
## terrain height-function sample, this sees boulders, rock slabs, ramps,
## roofs, ship decks, and every other solid platform. The probe begins just
## above the axle so it cannot select an overhead floor as wheel support.
func _dirtbike_wheel_support_height(axle: Vector3) -> Variant:
	if terrain == null:
		return null
	var terrain_height: float = terrain.get_mesh_height(axle.x,axle.z)
	var from := axle+Vector3.UP*(DIRTBIKE_WHEEL_RADIUS+0.18)
	var to := Vector3(axle.x,terrain_height-3.0,axle.z)
	var query := PhysicsRayQueryParameters3D.create(
		from,to,1 | TownProps.BLORB_CLIMBABLE_LAYER
	)
	query.exclude=[get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	return (hit["position"] as Vector3).y


## Terrain rise/run directly beneath the wheel, sampled along `dir_xz`
## (typically the current velocity direction) -- positive means the ground
## climbs in that direction. Shared by the uphill roll-to-a-stop
## deceleration and could equally serve any other dirtbike slope query.
func _dirtbike_slope_along(dir_xz: Vector2) -> float:
	if terrain == null or dir_xz.length_squared() < 0.0001:
		return 0.0
	var dir := dir_xz.normalized()
	const SAMPLE_DIST := 0.6
	var h0: float = terrain.get_mesh_height(global_position.x, global_position.z)
	var h1: float = terrain.get_mesh_height(global_position.x + dir.x * SAMPLE_DIST, global_position.z + dir.y * SAMPLE_DIST)
	return (h1 - h0) / SAMPLE_DIST


## Two active Fire hands become downward lift jets rather than two forward
## flamethrowers. Arms stay fixed beside the hips, slightly spread so the
## raised fingertips angle outward, with both palms rolled toward the floor.
## When both Fire feet join them, the legs lock into a straight jet-flight
## silhouette as well; ordinary walk/jump animation continues underneath but
## this final layer wins while all four controls remain powered.
## Swimming (at the surface or diving), not wading on the lakebed.
func _is_swimming() -> bool:
	return _lake_buoyancy_active and not _lake_floor_walk_active and not _lake_weighted_descent_active


## How many Water hands and feet are jetting the swimmer along: 0 out of water.
func _swim_jet_count() -> int:
	if not _is_swimming():
		return 0
	return int(_left_arm_water_active) + int(_right_arm_water_active) + int(_left_leg_water_active) + int(_right_leg_water_active)


## Swimming Water jets, posed like the Fire suit's: jetting hands swept back
## beside the hips and jetting legs held straight, both streaming behind.
func _apply_swim_jet_pose(delta: float) -> void:
	if _swim_jet_count() == 0:
		return
	var t := minf(FIRE_JET_POSE_SETTLE_SPEED * delta, 1.0)
	if _left_arm_water_active:
		_pose_fire_jet_arm(_arm_left, _elbow_left, _hand_left, 1.0, t)
	if _right_arm_water_active:
		_pose_fire_jet_arm(_arm_right, _elbow_right, _hand_right, -1.0, t)
	if not (_left_leg_water_active or _right_leg_water_active):
		return
	for joint in [_leg_left, _leg_right, _knee_left, _knee_right, _ankle_left, _ankle_right]:
		var pivot := joint as Node3D
		pivot.rotation = pivot.rotation.lerp(Vector3.ZERO, t)


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
	_fire_stream_left.local_coords = true
	_fire_stream_right.local_coords = true
	_water_leg_stream_left = _make_water_stream("LeftWaterFootJet")
	_water_leg_stream_right = _make_water_stream("RightWaterFootJet")
	_fire_leg_stream_left = _make_fire_stream("LeftFireFootJet")
	_fire_leg_stream_right = _make_fire_stream("RightFireFootJet")
	# Fire jets remain attached to their animated emitters. World-space
	# simulation abandoned each flame at an old hand/foot position whenever
	# the player moved quickly.
	_fire_leg_stream_left.local_coords = true
	_fire_leg_stream_right.local_coords = true
	# Water foot jets are jets too (hover or, swimming, propulsion): kept
	# attached the same way. Water hands switch to this only while swimming
	# (see _update_water_streams()); on land the hose keeps world-space
	# droplets so its arc hangs in the air behind a sweep.
	_water_leg_stream_left.local_coords = true
	_water_leg_stream_right.local_coords = true
	_electric_stream_left = LightningBolt.spawn(self, LightningBolt.ELECTRIC_LIGHTNING_COLOR)
	_electric_stream_right = LightningBolt.spawn(self, LightningBolt.ELECTRIC_LIGHTNING_COLOR)
	_city_stream_left = LightningBolt.spawn(self, LightningBolt.CITY_LIGHTNING_COLOR)
	_city_stream_right = LightningBolt.spawn(self, LightningBolt.CITY_LIGHTNING_COLOR)


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
	# Water leaves a moving nozzle carrying the nozzle's own speed, so a
	# running hose's stream keeps pace instead of being outrun.
	process.inherit_velocity_ratio = 1.0
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




## Same position/look_at()/wobble aiming _update_water_stream() applies to a
## GPUParticles3D stream, just typed for LightningBolt instead -- GDScript
## has no structural typing, so a plain Node3D-typed LightningBolt can't be
## passed into that function's GPUParticles3D-typed parameter, and this
## small duplicate is simpler than forcing an artificial shared base type
## across two otherwise-unrelated node kinds.
func _update_lightning_bolt(bolt: LightningBolt, hand: Node3D, forward: Vector3, active: bool) -> void:
	if bolt == null or hand == null:
		return
	bolt.emitting = active
	if not active:
		return
	var origin := hand.global_position
	bolt.global_position = origin
	var up_reference := Vector3.UP
	if absf(forward.normalized().dot(up_reference)) > 0.98:
		up_reference = visuals.global_transform.basis.z.normalized()
	var phase := float(bolt.get_instance_id() % 1000) * 0.01
	var t := Time.get_ticks_msec() * 0.001 * STREAM_AIM_WOBBLE_SPEED + phase
	var wobble := Basis(Vector3.UP, sin(t) * STREAM_AIM_WOBBLE_ANGLE) * Basis(Vector3.RIGHT, cos(t * 1.3) * STREAM_AIM_WOBBLE_ANGLE)
	bolt.look_at(origin + wobble * forward, up_reference)


const WATER_POWER_MP_PER_SECOND := 3.0
const FIRE_POWER_MP_PER_SECOND := 4.5
const ELECTRIC_POWER_MP_PER_SECOND := 4.0
## City is arms-only too, folding into the same forward-stream damage
## pipeline as electric -- see combat_math.gd's own HASTE_WEAKEN_DURATION
## comment for the status effect its own damage tick also applies.
const CITY_POWER_MP_PER_SECOND := 4.0

## Rock/plant are discrete, cooldown-gated attacks (see the flag/cooldown
## fields' own comment) rather than a continuous per-second drain, so their
## cost is per-shot rather than a rate.
const ROCK_POWER_MP_PER_SHOT := 8.0
const ROCK_POWER_COOLDOWN := 1.1
const ROCK_CRAG_DAMAGE_BASE := 18.0
const ROCK_CRAG_RADIUS := 1.6
const ROCK_CRAG_SPAWN_DISTANCE := 3.0

const PLANT_POWER_MP_PER_SHOT := 2.0
## ~2.5 shots/sec -- "not too fast," per direct instruction.
const PLANT_PELLET_COOLDOWN := 0.4
const PLANT_PELLET_DAMAGE_BASE := 6.0
const PLANT_PELLET_SPEED := 14.0

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
	_penguin_chord_holding = _update_penguin_chord(delta)
	_left_arm_water_active = _consume_limb_power("arm_left", "left_arm_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_right_arm_water_active = false if _throw_aim_active or _held_item_is_weapon() else _consume_limb_power("arm_right", "right_arm_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_left_arm_fire_active = _consume_limb_power("arm_left", "left_arm_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)
	_right_arm_fire_active = false if _throw_aim_active or _held_item_is_weapon() else _consume_limb_power("arm_right", "right_arm_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)
	_left_arm_electric_active = _consume_limb_power("arm_left", "left_arm_power", "electric", ELECTRIC_POWER_MP_PER_SECOND, delta)
	_right_arm_electric_active = false if _throw_aim_active or _held_item_is_weapon() else _consume_limb_power("arm_right", "right_arm_power", "electric", ELECTRIC_POWER_MP_PER_SECOND, delta)
	_left_arm_city_active = _consume_limb_power("arm_left", "left_arm_power", "city", CITY_POWER_MP_PER_SECOND, delta)
	_right_arm_city_active = false if _throw_aim_active or _held_item_is_weapon() else _consume_limb_power("arm_right", "right_arm_power", "city", CITY_POWER_MP_PER_SECOND, delta)
	_left_leg_water_active = _consume_limb_power("leg_left", "left_leg_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_right_leg_water_active = _consume_limb_power("leg_right", "right_leg_power", "water", WATER_POWER_MP_PER_SECOND, delta)
	_left_leg_fire_active = _consume_limb_power("leg_left", "left_leg_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)
	_right_leg_fire_active = _consume_limb_power("leg_right", "right_leg_power", "fire", FIRE_POWER_MP_PER_SECOND, delta)
	if _left_arm_water_active or _right_arm_water_active or _left_leg_water_active or _right_leg_water_active:
		UISounds.pulse_power_loop(&"water", get_instance_id())
	if _left_arm_fire_active or _right_arm_fire_active or _left_leg_fire_active or _right_leg_fire_active:
		UISounds.pulse_power_loop(&"fire", get_instance_id())
	if _left_arm_electric_active or _right_arm_electric_active or _left_arm_city_active or _right_arm_city_active:
		UISounds.pulse_power_loop(&"electric", get_instance_id())

	# In the water, Water feet jet backward to swim (see _swim_jet_count())
	# rather than downward to hover.
	_water_leg_hover_active = _left_leg_water_active and _right_leg_water_active and not _is_swimming()
	_fire_hand_hover_active = _left_arm_fire_active and _right_arm_fire_active
	# A matched pair of downward foot jets supplies the same basic lift and
	# fall braking as the matched hand jets. It remains a level hover on its
	# own; combining both pairs below upgrades that lift into directional
	# four-limb flight.
	_fire_leg_hover_active = _left_leg_fire_active and _right_leg_fire_active
	_fire_limb_flight_active = (
		_fire_hand_hover_active and _fire_leg_hover_active
	)
	_air_foot_hover_active = _blorb_suit.has_air_hover_legs()

	var hovering := _is_powered_hover_active()
	if hovering and not _was_powered_hover_active:
		var ground_height: float = terrain.get_mesh_height(global_position.x, global_position.z)
		_powered_hover_target_y = maxf(
			global_position.y, ground_height + FOOT_OFFSET + POWERED_HOVER_HEIGHT
		)
	_was_powered_hover_active = hovering

	if not _penguin_chord_holding:
		_update_discrete_arm_powers(delta)
		_update_rock_leg_powers(delta)


func _update_rock_leg_powers(delta: float) -> void:
	_left_leg_rock_cooldown = maxf(_left_leg_rock_cooldown - delta, 0.0)
	_right_leg_rock_cooldown = maxf(_right_leg_rock_cooldown - delta, 0.0)
	if UIState.modal_open:
		return
	if Input.is_action_just_pressed("left_leg_power") and _left_leg_rock_cooldown <= 0.0:
		if _raise_rock_platform("leg_left"):
			_left_leg_rock_cooldown = ROCK_POWER_COOLDOWN
	if Input.is_action_just_pressed("right_leg_power") and _right_leg_rock_cooldown <= 0.0:
		if _raise_rock_platform("leg_right"):
			_right_leg_rock_cooldown = ROCK_POWER_COOLDOWN


func _raise_rock_platform(slot: String) -> bool:
	var blorb := _blorb_suit.worn_blorb_in_slot(slot)
	if blorb == null or blorb.element_state not in ["rock", "ice", "air"]:
		return false
	var here := Vector2(global_position.x, global_position.z)
	if blorb.element_state == "rock" and terrain.has_method("is_ice_surface") and terrain.is_ice_surface(here):
		return false
	if not blorb.consume_mp(ROCK_POWER_MP_PER_SHOT):
		return false
	if blorb.element_state == "air":
		# Player origin is the feet. Put the cloud's solid top just beneath
		# them so a foot power is an immediate aerial stepping stone.
		CloudPlatform.spawn(get_tree().current_scene,global_position-Vector3.UP*0.17,_rng,blorb.level,1.15)
		return true
	var ground_y: float = _crag_surface_height(blorb, here)
	if blorb.element_state == "ice":
		IceCrag.spawn(get_tree().current_scene, Vector3(global_position.x, ground_y, global_position.z), _rng, blorb.level, 1.35)
	else:
		RockCrag.spawn(
			get_tree().current_scene,
			Vector3(global_position.x, ground_y, global_position.z),
			_rng, blorb.level, 1.35, _rock_crag_color(here)
		)
	return true


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
	return _water_leg_hover_active or _fire_hand_hover_active or _fire_leg_hover_active or _air_foot_hover_active


## Rock/plant share the same "held + correct element worn, gated by a
## per-shot cooldown rather than a per-second drain" shape (see their flag/
## cooldown fields' own comment) -- handled together here rather than
## folded into _consume_limb_power(), whose per-second rate model doesn't
## fit a per-shot cost.
func _update_discrete_arm_powers(delta: float) -> void:
	var left_rock := _update_discrete_power("arm_left", "left_arm_power", "platform", _left_arm_rock_cooldown, delta)
	_left_arm_rock_active = left_rock["active"]
	_left_arm_rock_cooldown = left_rock["cooldown"]
	if left_rock["active"] and _left_arm_rock_cooldown <= 0.0 and _fire_rock_power("arm_left", _palm_left):
		_left_arm_rock_cooldown = ROCK_POWER_COOLDOWN

	var right_rock := (
		{"active": false, "cooldown": _right_arm_rock_cooldown} if _throw_aim_active or _held_item_is_weapon()
		else _update_discrete_power("arm_right", "right_arm_power", "platform", _right_arm_rock_cooldown, delta)
	)
	_right_arm_rock_active = right_rock["active"]
	_right_arm_rock_cooldown = right_rock["cooldown"]
	if right_rock["active"] and _right_arm_rock_cooldown <= 0.0 and _fire_rock_power("arm_right", _palm_right):
		_right_arm_rock_cooldown = ROCK_POWER_COOLDOWN

	var left_plant := _update_discrete_power("arm_left", "left_arm_power", "plant", _left_arm_plant_cooldown, delta)
	_left_arm_plant_active = left_plant["active"]
	_left_arm_plant_cooldown = left_plant["cooldown"]
	if left_plant["active"] and _left_arm_plant_cooldown <= 0.0 and _arm_fully_raised(_arm_left, _elbow_left) and _fire_plant_power("arm_left", _palm_left):
		_left_arm_plant_cooldown = PLANT_PELLET_COOLDOWN

	var right_plant := (
		{"active": false, "cooldown": _right_arm_plant_cooldown} if _throw_aim_active or _held_item_is_weapon()
		else _update_discrete_power("arm_right", "right_arm_power", "plant", _right_arm_plant_cooldown, delta)
	)
	_right_arm_plant_active = right_plant["active"]
	_right_arm_plant_cooldown = right_plant["cooldown"]
	if right_plant["active"] and _right_arm_plant_cooldown <= 0.0 and _arm_fully_raised(_arm_right, _elbow_right) and _fire_plant_power("arm_right", _palm_right):
		_right_arm_plant_cooldown = PLANT_PELLET_COOLDOWN


## Whether `action` is held with `element` worn in `slot` right now
## (regardless of cooldown -- see the rock/plant flag fields' own comment),
## plus that slot's cooldown ticked down by `delta`. Returns a Dictionary
## rather than mutating a passed-in field directly since GDScript has no
## by-reference float parameters.
func _update_discrete_power(
	slot: String, action: String, element: String, cooldown: float, delta: float
) -> Dictionary:
	var active := false
	if not UIState.modal_open and Input.is_action_pressed(action):
		var blorb := _blorb_suit.worn_blorb_in_slot(slot)
		active = blorb != null and (blorb.element_state in ["rock", "ice", "air"] if element == "platform" else blorb.element_state == element)
	return {"active": active, "cooldown": maxf(cooldown - delta, 0.0)}


## Erupts a cosmetic RockCrag (see that script's own class doc comment -- it
## deals no damage itself) a short distance ahead of the player, then
## immediately resolves a plain radius check against the "skeletons" group
## for the actual hit -- an eruption is immediate/local rather than an aimed
## beam, so a simple radius check fits better here than the streams' own
## forward-cone check. Returns false (and spends no MP/cooldown) if the worn
## blorb can't afford ROCK_POWER_MP_PER_SHOT.
func _fire_rock_power(slot: String, hand: Node3D) -> bool:
	var blorb := _blorb_suit.worn_blorb_in_slot(slot)
	if blorb == null or blorb.element_state not in ["rock", "ice", "air"]:
		return false
	var hand_xz := Vector2(hand.global_position.x, hand.global_position.z)
	if blorb.element_state == "rock" and terrain.has_method("is_ice_surface") and terrain.is_ice_surface(hand_xz):
		return false
	if not blorb.consume_mp(ROCK_POWER_MP_PER_SHOT):
		return false
	var forward := visuals.global_transform.basis * Vector3(0.0, 0.0, 1.0)
	forward = forward.normalized() if forward.length_squared() > 0.001 else Vector3.FORWARD
	if blorb.element_state == "air":
		var shoulder_y := _thorax.global_position.y if _thorax != null else global_position.y+1.45
		var cloud_center := Vector3(global_position.x,shoulder_y,global_position.z)+forward*ROCK_CRAG_SPAWN_DISTANCE
		CloudPlatform.spawn(get_tree().current_scene,cloud_center,_rng,blorb.level)
		return true
	var spawn_xz := Vector2(hand.global_position.x, hand.global_position.z) + Vector2(forward.x, forward.z) * ROCK_CRAG_SPAWN_DISTANCE
	var spawn_y: float = _crag_surface_height(blorb, spawn_xz)
	var spawn_point := Vector3(spawn_xz.x, spawn_y, spawn_xz.y)
	var rock_count: int = mini(1 + (blorb.level - 1) / 5, 4)
	for i in rock_count:
		var angle: float = TAU * float(i) / float(rock_count)
		var offset := Vector3(cos(angle), 0.0, sin(angle)) * (0.55 if i > 0 else 0.0)
		if blorb.element_state == "ice":
			IceCrag.spawn(get_tree().current_scene, spawn_point + offset, _rng, blorb.level)
		else:
			RockCrag.spawn(
				get_tree().current_scene, spawn_point + offset, _rng,
				blorb.level, 1.0, _rock_crag_color(spawn_xz)
			)
	var level_damage_scale: float = 1.0 + float(blorb.level - 1) * 0.08
	var roll := CombatMath.rolled_attack(ROCK_CRAG_DAMAGE_BASE * level_damage_scale, blorb.strength, _rng)
	var credit_blorbs := _active_powered_blorbs()
	for node in get_tree().get_nodes_in_group("skeletons"):
		var skeleton := node as Node3D
		if skeleton == null or not skeleton.has_method("take_damage"):
			continue
		if skeleton.global_position.distance_to(spawn_point) > ROCK_CRAG_RADIUS:
			continue
		if skeleton.has_method("register_xp_participant"):
			for participant in credit_blorbs:
				skeleton.register_xp_participant(participant)
		var defender_element: String = (
			skeleton.current_combat_element() if skeleton.has_method("current_combat_element") else ""
		)
		var final_damage: float = roll["amount"] * CombatMath.type_multiplier(blorb.element_state, defender_element)
		skeleton.take_damage(final_damage)
	return true


## Ice is a real raised support above the lakebed, not a terrain color. Ice
## crags therefore erupt from the frozen sheet's own top elevation wherever
## that sheet exists (excluding the fishing hole). Rock and off-lake ice keep
## using ordinary terrain, preserving the existing rock-power rules.
func _crag_surface_height(blorb: Blorb, pos: Vector2) -> float:
	var base_height: float
	if (
		blorb.element_state == "ice"
		and terrain.has_method("is_ice_surface")
		and terrain.is_ice_surface(pos)
		and terrain.has_method("get_ice_level")
	):
		base_height = terrain.get_ice_level()
	else:
		base_height = terrain.get_mesh_height(pos.x, pos.y)
	# Existing temporary crags are real foundations too. Selecting the highest
	# supporting top beneath this XZ lets repeated casts build stable towers.
	for platform in get_tree().get_nodes_in_group("power_platforms"):
		var body := platform as Node3D
		if body == null:
			continue
		var radius := float(body.get_meta("support_radius",0.0))
		if Vector2(body.global_position.x,body.global_position.z).distance_to(pos) <= radius*0.88:
			var support_top := (
				float(body.call("get_support_top_y"))
				if body.has_method("get_support_top_y")
				else float(body.get_meta("support_top_y",-INF))
			)
			base_height = maxf(base_height,support_top)
	return base_height


## Rock cast through water originates in the sandy floor rather than treating
## the liquid sheet as stone. Keeping this visual decision beside the shared
## surface-height resolver makes hand and leg casts agree.
func _rock_crag_color(pos: Vector2) -> Color:
	return NatureProps.ROCK_COLOR


## Within this of the arm-power pose (shoulder raised, elbow straight), an arm
## counts as fully extended and its pea shooter may fire.
const ARM_RAISED_TOLERANCE := deg_to_rad(6.0)


## True once the arm-power raise (see _apply_arm_power_poses()) has brought
## this arm level and straight, so a shot leaves an outstretched arm rather
## than one still swinging up.
func _arm_fully_raised(arm_pivot: Node3D, elbow_pivot: Node3D) -> bool:
	return (
		absf(angle_difference(arm_pivot.rotation.x, -ARM_POWER_POSE_ANGLE)) <= ARM_RAISED_TOLERANCE
		and absf(angle_difference(elbow_pivot.rotation.x, 0.0)) <= ARM_RAISED_TOLERANCE
	)


## Fires a single SeedPellet forward from `hand` -- see that script's own
## class doc comment for how it resolves its own hit asynchronously once it
## actually connects. Returns false (and spends no MP/cooldown) if the worn
## blorb can't afford PLANT_POWER_MP_PER_SHOT.
func _fire_plant_power(slot: String, hand: Node3D) -> bool:
	var blorb := _blorb_suit.worn_blorb_in_slot(slot)
	if blorb == null or not blorb.consume_mp(PLANT_POWER_MP_PER_SHOT):
		return false
	var forward := visuals.global_transform.basis * Vector3(0.0, 0.0, 1.0)
	forward = forward.normalized() if forward.length_squared() > 0.001 else Vector3.FORWARD
	var pellet := SeedPellet.new()
	# Launched from a moving arm, the pea carries the shooter's own velocity,
	# so a running hero never outruns his own shots.
	pellet.velocity = forward * PLANT_PELLET_SPEED + velocity
	pellet.damage = CombatMath.rolled_attack(PLANT_PELLET_DAMAGE_BASE, blorb.strength, _rng)["amount"]
	pellet.attacker_element = "plant"
	# Snapshotted at fire time, not read back at hit time -- a pellet in
	# flight still credits whoever was contributing when it launched even if
	# that arm stops holding its power before the pellet lands.
	pellet.credit_blorbs = _active_powered_blorbs()
	get_tree().current_scene.add_child(pellet)
	pellet.global_position = hand.global_position
	UISounds.play_seed_eject(get_instance_id())
	return true


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
	# Swimming, Water hands and feet jet straight back against the travel.
	var swimming := _is_swimming()
	var backward := -forward
	if velocity.length_squared() > 0.25:
		backward = -velocity.normalized()
	var water_hand_direction := backward if swimming else forward
	var water_foot_direction := backward if swimming else downward
	# Swimming jets stay attached to the hands like the Fire jets; a fast
	# swimmer would otherwise leave each jet's start behind in the water.
	if is_instance_valid(_water_stream_left):
		_water_stream_left.local_coords = swimming
		_water_stream_right.local_coords = swimming
	_update_water_stream(
		_water_stream_left, _palm_left, water_hand_direction,
		_left_arm_water_active
	)
	_update_water_stream(
		_water_stream_right, _palm_right, water_hand_direction,
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
	_update_water_stream(_water_leg_stream_left, _toe_left, water_foot_direction, _left_leg_water_active)
	_update_water_stream(_water_leg_stream_right, _toe_right, water_foot_direction, _right_leg_water_active)
	_update_water_stream(
		_fire_leg_stream_left, _toe_left, _foot_jet_direction(_ankle_left), _left_leg_fire_active
	)
	_update_water_stream(
		_fire_leg_stream_right, _toe_right, _foot_jet_direction(_ankle_right), _right_leg_fire_active
	)
	_update_lightning_bolt(_electric_stream_left, _palm_left, forward, _left_arm_electric_active)
	_update_lightning_bolt(_electric_stream_right, _palm_right, forward, _right_arm_electric_active)
	_update_lightning_bolt(_city_stream_left, _palm_left, forward, _left_arm_city_active)
	_update_lightning_bolt(_city_stream_right, _palm_right, forward, _right_arm_city_active)
	var forward_stream_active := (
		((_left_arm_water_active or _right_arm_water_active) and not swimming)
		or _left_arm_electric_active or _right_arm_electric_active
		or _left_arm_city_active or _right_arm_city_active
		or ((_left_arm_fire_active or _right_arm_fire_active) and not _fire_hand_hover_active)
	)
	# Runs on a hover-only frame too (no forward stream at all) so a purely
	# hovering worn blorb still gets an XP-participation chance -- see
	# _damage_skeletons_in_stream()'s own `dealing_damage` param, which
	# keeps actual damage-dealing gated on forward_stream_active alone.
	if forward_stream_active or _is_powered_hover_active():
		_damage_skeletons_in_stream(forward, delta, forward_stream_active)


## Per direct bug report, the player's own arm-mounted water/fire streams
## (above) never damaged skeletons -- only a free-roaming blorb's separate
## combat stream (blorb.gd's _update_elemental_stream()) did. Distance- and
## facing-cone-based rather than a real particle-collision check, matching
## this codebase's existing convention of proximity checks over physics
## callbacks (see skeleton_nme.gd's own _find_target(), blorb.gd's
## _find_nearest_skeleton()).
func _damage_skeletons_in_stream(forward: Vector3, delta: float, dealing_damage: bool) -> void:
	var origin := global_position
	var damage_participants := _active_forward_stream_blorbs()
	var powered_participants := _active_powered_blorbs()
	# The stream's own damage doesn't stack per active arm (one flat rate
	# whether one or two arms are streaming, same as before) -- Strength
	# scaling (and, per direct instruction, the type-effectiveness element
	# used below) picks the strongest contributing arm blorb rather than
	# averaging it down against a weaker second one.
	var strength := 0
	var attacker_element := ""
	for blorb in damage_participants:
		if blorb.strength >= strength:
			strength = blorb.strength
			attacker_element = blorb.element_state
	var damage_rate := CombatMath.rolled_stream_rate(STREAM_BASE_DAMAGE_PER_SECOND, strength)
	for node in get_tree().get_nodes_in_group("skeletons"):
		var skeleton := node as Node3D
		if skeleton == null or not skeleton.has_method("take_damage"):
			continue
		var to_skeleton := skeleton.global_position - origin
		var dist := to_skeleton.length()
		if dist < 0.001 or dist > STREAM_DAMAGE_RANGE:
			continue
		# Registration is broader than damage-dealing -- any nearby enemy
		# credits every actively-powered worn blorb (see _active_powered_
		# blorbs()' own comment), not just whichever arm happens to be
		# forward-streaming at this exact moment. Hovering isn't "aimed"
		# the way a stream is, so it doesn't need the same forward-cone
		# check damage itself still does right below.
		if skeleton.has_method("register_xp_participant"):
			for blorb in powered_participants:
				skeleton.register_xp_participant(blorb)
		if not dealing_damage:
			continue
		if forward.dot(to_skeleton / dist) < STREAM_HALF_ANGLE_COS:
			continue
		# Type effectiveness (see combat_math.gd's own doc comment) --
		# neutral (1.0x) whenever either side has no element, which covers
		# every ordinary skeleton today; a target that exposes its own
		# current_combat_element() (e.g. an elementally-phased boss) makes
		# this live.
		# Explicit : String, not := -- skeleton is a loosely-typed Node3D, so
		# the dynamic current_combat_element() call has no static return
		# type for := to infer from (same pitfall this project has already
		# hit with Dictionary/Array dynamic access elsewhere).
		var defender_element: String = skeleton.current_combat_element() if skeleton.has_method("current_combat_element") else ""
		var final_rate := damage_rate * CombatMath.type_multiplier(attacker_element, defender_element)
		skeleton.take_damage(final_rate * delta)
		# Electric's own stun / City's own haste-weaken -- see combat_math.gd's
		# own STUN_DURATION/HASTE_WEAKEN_DURATION comment. Re-applied every
		# frame the stream keeps hitting (refresh-to-max, not additive -- see
		# each NME's own apply_stun()/apply_haste_weaken()), so the effect
		# simply persists for its own duration past the last tick rather than
		# stacking into something permanent.
		match attacker_element:
			"electric":
				if skeleton.has_method("apply_stun"):
					skeleton.apply_stun(CombatMath.STUN_DURATION)
			"city":
				if skeleton.has_method("apply_haste_weaken"):
					skeleton.apply_haste_weaken(CombatMath.HASTE_WEAKEN_DURATION)


func _active_forward_stream_blorbs() -> Array[Blorb]:
	var participants: Array[Blorb] = []
	var active_slots := {
		"arm_left": _left_arm_water_active or _left_arm_electric_active or _left_arm_city_active or (_left_arm_fire_active and not _fire_hand_hover_active),
		"arm_right": _right_arm_water_active or _right_arm_electric_active or _right_arm_city_active or (_right_arm_fire_active and not _fire_hand_hover_active),
	}
	for slot in active_slots:
		if not active_slots[slot]:
			continue
		var blorb := _blorb_suit.worn_blorb_in_slot(slot)
		if blorb != null:
			participants.append(blorb)
	return participants


## Every currently-worn blorb whose own power is actively engaged right
## now -- broader than _active_forward_stream_blorbs() above (which stays
## narrow since only those two slots actually deal stream damage), so XP
## participation also credits a blorb that spent the fight hovering
## (either leg, or a fire-hand-hover arm) instead of only ever crediting
## whichever blorb happened to be forward-streaming at the exact moment of
## a kill. Per direct instruction: "any blorbs you wore on your body during
## a fight which you physically contributed to" -- actively drawing on its
## own power counts as contributing. Head/torso blorbs are left out: no
## combat-relevant power exists for either slot today (has_head_blorb()/
## has_chest_air_blorb() gate diving/flight only), so crediting them would
## invent a rule with no real gameplay basis behind it.
func _active_powered_blorbs() -> Array[Blorb]:
	var participants: Array[Blorb] = []
	var active_slots := {
		"arm_left": (
			_left_arm_water_active or _left_arm_fire_active or _left_arm_electric_active
			or _left_arm_city_active or _left_arm_rock_active or _left_arm_plant_active
		),
		"arm_right": (
			_right_arm_water_active or _right_arm_fire_active or _right_arm_electric_active
			or _right_arm_city_active or _right_arm_rock_active or _right_arm_plant_active
		),
		"leg_left": _left_leg_water_active or _left_leg_fire_active,
		"leg_right": _right_leg_water_active or _right_leg_fire_active,
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
	if _throw_aim_active:
		cancel_throw_preparation()
	_weapon_swing_active = false
	_weapon_swing_elapsed = 0.0
	if _held_visual != null:
		_held_visual.queue_free()
		_held_visual = null
	if HeldItem.current.is_empty():
		return
	var entry := ShopCatalog.find(HeldItem.current["name"])
	if entry.is_empty():
		return
	# Equipment authored at its actual usable dimensions (the sword) opts out
	# of the generic small-prop reduction. Objects without held_scale retain the
	# established inventory-object size, while each weapon can be balanced
	# independently without changing its shop or ground display copy.
	var held_scale: float = float(entry.get("held_scale", HELD_ITEM_SCALE))
	_held_visual = entry["build_visual"].call(held_scale)
	_palm_right.add_child(_held_visual)
	ShopCatalog.fit_visual_to_hand(_held_visual,HELD_ITEM_LOCAL_OFFSET)
	# Inherits the whole arm's walk-swing animation (and now the hand's own
	# wrist twist) for free via the parent chain -- a nice incidental
	# "swinging held item" effect, not worth damping.


## An equipped item claims the ordinary right-hand control: hold E/right
## shoulder to enter the prepared pose, aim with the existing camera, and
## release to throw. With no held item the exact same input continues to be
## the right-arm blorb power/ordinary arm raise. ui_cancel backs out without
## consuming the item.
func _update_throw_input() -> void:
	if _held_item_is_weapon():
		if _throw_aim_active:
			cancel_throw_preparation()
		if (
			Input.is_action_just_pressed("right_arm_power")
			and not _weapon_swing_active
			and not UIState.modal_open
			and not _player_following_blorbus
			and not _player_following_manchego
		):
			_weapon_swing_active = true
			_weapon_swing_elapsed = 0.0
			_weapon_swing_has_hit = false
			_weapon_swing_inward = _next_weapon_swing_inward
			_next_weapon_swing_inward = not _next_weapon_swing_inward
			UISounds.play_foley(
				&"weapon_swing_inward" if _weapon_swing_inward else &"weapon_swing_outward",
				0.48,
				get_instance_id()
			)
		return
	var right_hand_pressed := Input.is_action_pressed("right_arm_power")
	if _throw_aim_active:
		if (
			UIState.modal_open
			or HeldItem.current.is_empty()
			or _player_following_blorbus
			or _player_following_manchego
		):
			cancel_throw_preparation()
		elif not right_hand_pressed:
			_throw_held_item()
		return
	if (
		Input.is_action_just_pressed("right_arm_power")
		and not HeldItem.current.is_empty()
		and not UIState.modal_open
		and not _player_following_blorbus
		and not _player_following_manchego
		and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	):
		_begin_throw_preparation()


func _held_item_is_weapon() -> bool:
	if HeldItem.current.is_empty():
		return false
	return bool(ShopCatalog.find(str(HeldItem.current.get("name", ""))).get("weapon", false))


func _apply_weapon_swing_pose(delta: float) -> void:
	if not _weapon_swing_active:
		return
	_weapon_swing_elapsed += delta
	var progress := clampf(_weapon_swing_elapsed / WEAPON_SWING_DURATION, 0.0, 1.0)
	# Alternate a cut away from the body with its mirrored return cut. Both the
	# sword and Jingu Bang use this shared weapon path, so repeated attacks form
	# a deliberate outward/inward rhythm rather than replaying one swipe.
	var arc := sin(progress * PI)
	var start_x := -0.23 if _weapon_swing_inward else -1.28
	var end_x := -1.28 if _weapon_swing_inward else -0.23
	var start_z := -0.83 if _weapon_swing_inward else 0.72
	var end_z := 0.72 if _weapon_swing_inward else -0.83
	var wrist_start := PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE - 1.15 if _weapon_swing_inward else PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE
	var wrist_end := PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE if _weapon_swing_inward else PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE - 1.15
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, lerpf(start_x, end_x, progress), minf(1.0, delta * 18.0))
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, lerpf(start_z, end_z, progress), minf(1.0, delta * 18.0))
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, -0.82 + arc * 0.34, minf(1.0, delta * 18.0))
	_hand_right.rotation.y = lerp_angle(_hand_right.rotation.y, lerpf(wrist_start, wrist_end, progress), minf(1.0, delta * 20.0))
	_anchor_hand_to_wrist(_hand_right)
	if not _weapon_swing_has_hit and progress >= WEAPON_HIT_TIME:
		_weapon_swing_has_hit = true
		_apply_weapon_hit()
	if progress >= 1.0:
		_weapon_swing_active = false


func _apply_weapon_hit() -> void:
	var entry := ShopCatalog.find(str(HeldItem.current.get("name", "")))
	if entry.is_empty() or not bool(entry.get("weapon", false)):
		return
	var reach: float = float(entry.get("weapon_reach", 1.5))
	var damage: float = float(entry.get("weapon_damage", 12.0))
	var forward := visuals.global_transform.basis.z.normalized()
	for node in get_tree().get_nodes_in_group("skeletons"):
		var nme := node as Node3D
		if nme == null or not nme.has_method("take_damage"):
			continue
		var offset := nme.global_position - global_position
		var flat := Vector3(offset.x, 0.0, offset.z)
		if flat.length() > reach or flat.length_squared() <= 0.0001:
			continue
		if forward.dot(flat.normalized()) < -0.05:
			continue
		nme.take_damage(damage, null)


func _begin_throw_preparation() -> void:
	_throw_aim_active = true
	# Capture once, before any walk/run pose can be applied this frame. The
	# throw layer interpolates from these fixed rotations instead of from the
	# newly animated arm every frame, which prevents gait motion leaking into
	# the held prop as a persistent jitter.
	_throw_pose_blend = 0.0
	_throw_arm_start_rotation = _arm_right.rotation
	_throw_elbow_start_rotation = _elbow_right.rotation
	_throw_hand_start_rotation = _hand_right.rotation
	_right_arm_water_active = false
	_right_arm_fire_active = false
	Hud.set_throw_aiming(true)


func cancel_throw_preparation() -> void:
	if not _throw_aim_active:
		return
	_finish_throw_preparation()


func _finish_throw_preparation() -> void:
	_throw_aim_active = false
	Hud.set_throw_aiming(false)


## Highest-priority right-arm animation layer. It is applied after walk,
## jump, flight and fire-jet poses, so none of those can move the arm or the
## equipped prop while the player adjusts their aim.
func _apply_throw_aim_pose(delta: float) -> void:
	if not _throw_aim_active:
		# This layer owns only torso yaw. Ease both stages back to anatomical
		# neutral after a release/cancel without disturbing gait's forward lean.
		_spine.rotation.y = lerp_angle(_spine.rotation.y, 0.0, minf(1.0, THROW_POSE_SETTLE_SPEED * delta))
		if _thorax != null:
			_thorax.rotation.y = lerp_angle(_thorax.rotation.y, 0.0, minf(1.0, THROW_POSE_SETTLE_SPEED * delta))
		return
	_throw_pose_blend = minf(_throw_pose_blend + THROW_POSE_SETTLE_SPEED * delta, 1.0)
	var weight := smoothstep(0.0, 1.0, _throw_pose_blend)
	# Pull the throwing-side shoulder subtly behind the body. The lower share
	# rotates the abdomen and everything above it; the second share adds a
	# smaller ribcage turn so the wind-up bends through the torso instead of
	# looking like one rigid swivel at the waist.
	_spine.rotation.y = lerp_angle(0.0, THROW_ABDOMEN_WINDUP, weight)
	if _thorax != null:
		_thorax.rotation.y = lerp_angle(0.0, THROW_THORAX_WINDUP, weight)
	else:
		_spine.rotation.y = lerp_angle(0.0, THROW_ABDOMEN_WINDUP + THROW_THORAX_WINDUP, weight)
	# These assignments deliberately start from the captured pose, not the
	# current one: _animate_walk() may still calculate the rest of the gait,
	# but it can no longer move this shoulder/elbow/hand chain while aiming.
	_arm_right.rotation.x = lerp_angle(_throw_arm_start_rotation.x, -THROW_ARM_BACK_ANGLE, weight)
	_arm_right.rotation.y = lerp_angle(_throw_arm_start_rotation.y, 0.0, weight)
	_arm_right.rotation.z = lerp_angle(_throw_arm_start_rotation.z, -THROW_ARM_OUTWARD_ANGLE, weight)
	_elbow_right.rotation.x = lerp_angle(_throw_elbow_start_rotation.x, -THROW_ELBOW_BEND, weight)
	_elbow_right.rotation.y = lerp_angle(_throw_elbow_start_rotation.y, 0.0, weight)
	_elbow_right.rotation.z = lerp_angle(_throw_elbow_start_rotation.z, 0.0, weight)
	_hand_right.rotation.x = lerp_angle(_throw_hand_start_rotation.x, THROW_HAND_COCK, weight)
	var rest_twist := PI * 0.5 + ProceduralFigure.WRIST_INWARD_ANGLE
	_hand_right.rotation.y = lerp_angle(_throw_hand_start_rotation.y, rest_twist, weight)
	_hand_right.rotation.z = lerp_angle(_throw_hand_start_rotation.z, 0.0, weight)
	_anchor_hand_to_wrist(_hand_right)


## While aiming a throw, the camera's own yaw drives the body's facing
## directly. The ordinary movement-direction turn above only runs while
## direction.length() > 0.001, so standing still and aiming (the common
## case for lining up a throw) would otherwise leave the body facing
## wherever it last walked while the camera swings freely around it.
## Called after _apply_throw_aim_pose() so it overrides that stale facing
## unconditionally, matching the same lerp_angle/rotation_speed pairing the
## movement branch above uses for every other body-yaw turn.
func _apply_throw_facing(delta: float) -> void:
	if not _throw_aim_active:
		return
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return
	var target_angle := atan2(forward.x, forward.z)
	_body_yaw = lerp_angle(_body_yaw, target_angle, rotation_speed * delta)


func _throw_held_item() -> void:
	var item: Dictionary = HeldItem.current
	if item.is_empty():
		cancel_throw_preparation()
		return

	# Aim from the actual centre-screen ray, but launch from the prop's live
	# hand position. A ballistic solution makes that hand-origin arc intersect
	# the reticle point instead of merely flying parallel to the camera ray.
	var ray_origin := camera.global_position
	var ray_end := ray_origin - camera.global_transform.basis.z * THROW_MAX_AIM_DISTANCE
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = 1 | Blorb.GIANT_THROWABLE_LAYER
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var target: Vector3 = hit["position"] if not hit.is_empty() else ray_end
	var launch_origin := _palm_right.global_position
	var carried_visual := _held_visual
	if carried_visual != null:
		launch_origin = carried_visual.global_position

	var thrown := ThrownItem.new()
	thrown.item_name = item["name"]
	get_tree().current_scene.add_child(thrown)
	thrown.global_position = launch_origin
	if carried_visual != null:
		var carried_transform := carried_visual.global_transform
		_held_visual = null
		carried_visual.reparent(thrown)
		carried_visual.global_transform = carried_transform
		thrown.adopt_visual(carried_visual)

	var displacement := target - launch_origin
	var horizontal := Vector3(displacement.x, 0.0, displacement.z)
	var travel_time := maxf(horizontal.length() / THROW_SPEED, 0.15)
	thrown.velocity = horizontal / travel_time
	thrown.velocity.y = minf(
		(displacement.y + 0.5 * ThrownItem.GRAVITY * travel_time * travel_time) / travel_time,
		THROW_MAX_UPWARD_SPEED
	)

	_finish_throw_preparation()
	UISounds.play_foley(&"throw_release", 0.55, get_instance_id())
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
	# Air-foot hovering deliberately keeps the ordinary walking head behavior.
	# Per direct correction ("when the hand wheel is activated... the head
	# should behave like when flying, keeping it lifted up and pointing in
	# the direction he's heading") -- the wheelie pitches `visuals` forward
	# by a real, possibly steep angle (see _solve_dirtbike_wheelie_pitch()),
	# and without this the head would just passively inherit that pitch and
	# stare down at the ground the same way it would on any other steeply
	# pitched body. Reusing this exact flight/dive branch (rather than a
	# separate one) is deliberate: it's already built for exactly "counter
	# a steep body pitch and track the travel direction instead."
	var aerial_head_tracking := (
		_lake_diving_active or _air_flight_active or _fire_limb_flight_active or _dirtbike_wheelie_active
	)
	var surface_swimming := _lake_buoyancy_active and not _lake_diving_active and not _lake_floor_walk_active and not _lake_weighted_descent_active
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
	if surface_swimming:
		# Counter the swimming lean so the face aims along travel and remains
		# clear of the surface rather than nodding into the water.
		var travel_direction := _aerial_motion_direction
		if travel_direction.length_squared() <= 0.001:
			travel_direction = visuals.global_transform.basis.z
		var local_travel := visuals.global_transform.basis.inverse() * travel_direction.normalized()
		target_yaw = clampf(atan2(local_travel.x, local_travel.z), -yaw_limit, yaw_limit)
		target_elevation = -deg_to_rad(32.0)
	elif _snowboard_active:
		# The body is side-on (left side leading); the torso supplies part of
		# the rotation and the neck completes a constrained downhill gaze.
		var board_travel:=_snowboard_last_heading
		if Vector2(velocity.x,velocity.z).length_squared()>0.01:
			board_travel=Vector3(velocity.x,0.0,velocity.z).normalized()
		var local_board_travel:=visuals.global_transform.basis.inverse()*board_travel
		var torso_twist:=SNOWBOARD_ABDOMEN_TWIST+(SNOWBOARD_THORAX_TWIST if _thorax!=null else 0.0)
		target_yaw=clampf(
			atan2(local_board_travel.x,local_board_travel.z)-torso_twist,
			-HEAD_YAW_LIMIT,HEAD_YAW_LIMIT
		)
		target_elevation=0.0
	elif _ice_skating_active:
		# Counter the gait's forward torso pitch so the gaze remains level in
		# the direction of travel, with the deeper sprint crouch compensated too.
		target_yaw=0.0
		target_elevation=-(ICE_SKATE_BODY_LEAN+(ICE_SKATE_SPRINT_BODY_LEAN if _is_sprinting() else 0.0))*0.72
	elif aerial_head_tracking:
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
		var camera_behind := camera_from_head.normalized().dot(body_forward) < -0.65
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
	# Lying prone in the Penguin Suit the face lifts forward, off the ice, the
	# same way: split between the base of the neck and the base of the skull
	# (PENGUIN_HEAD_LIFT_NECK_SHARE), and in place of camera tracking, which
	# would read "forward" as straight up out of the tipped body.
	var penguin_prone := smoothstep(0.0, 1.0, _penguin_prone)
	if penguin_prone > 0.0:
		target_yaw *= 1.0 - penguin_prone
		target_elevation = lerpf(target_elevation, 0.0, penguin_prone) - PENGUIN_HEAD_LIFT * penguin_prone * (1.0 - PENGUIN_HEAD_LIFT_NECK_SHARE)
	if _neck != null and not _player_following_manchego and _mounted_rider != self and _manchego_dismount_elapsed < 0.0:
		_neck.rotation.x = lerp_angle(
			_neck.rotation.x, -PENGUIN_HEAD_LIFT * penguin_prone * PENGUIN_HEAD_LIFT_NECK_SHARE, minf(turn_speed * delta, 1.0)
		)
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


## The formed Penguin Suit's gait, in place of the walk cycle, whose stride
## would swing the legs out through the long penguin body: short quick steps
## that barely lift each foot, the whole body leaning over the planted foot
## (_penguin_waddle_roll, applied by _pose_body_penguin()), flippers held a
## little out. Standing still, the steps and lean ease away.
func _animate_penguin_waddle(delta: float) -> void:
	var t := minf(POSE_SETTLE_SPEED * delta, 1.0)
	var speed := Vector2(velocity.x, velocity.z).length()
	var stepping := speed > 0.1 and _get_move_input().length_squared() > 0.01
	_penguin_waddle_blend = move_toward(_penguin_waddle_blend, 1.0 if stepping else 0.0, 4.0 * delta)
	if stepping:
		var pace := HumanoidLocomotion.ground_speed(_playable_profile, false) * PENGUIN_WADDLE_SPEED_MULTIPLIER
		_walk_phase += TAU * PENGUIN_WADDLE_CADENCE * clampf(speed / maxf(pace, 0.01), 0.6, 1.8) * delta
	var phase := _walk_phase
	var blend := _penguin_waddle_blend
	# Negative hip X swings a leg forward, and each foot lifts on its way
	# forward (see _animate_walk()'s knee timing).
	var left_lift := maxf(0.0, cos(phase)) * blend
	var right_lift := maxf(0.0, -cos(phase)) * blend
	var swing := -sin(phase) * PENGUIN_WADDLE_STEP * blend
	_leg_left.rotation = _leg_left.rotation.lerp(Vector3(swing - left_lift * PENGUIN_WADDLE_THIGH_LIFT, 0.0, 0.0), t)
	_leg_right.rotation = _leg_right.rotation.lerp(Vector3(-swing - right_lift * PENGUIN_WADDLE_THIGH_LIFT, 0.0, 0.0), t)
	_knee_left.rotation = _knee_left.rotation.lerp(Vector3(left_lift * PENGUIN_WADDLE_KNEE, 0.0, 0.0), t)
	_knee_right.rotation = _knee_right.rotation.lerp(Vector3(right_lift * PENGUIN_WADDLE_KNEE, 0.0, 0.0), t)
	_ankle_left.rotation = _ankle_left.rotation.lerp(Vector3.ZERO, t)
	_ankle_right.rotation = _ankle_right.rotation.lerp(Vector3.ZERO, t)
	var arm_t := minf(t, _arm_power_recovery)
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, 0.0, arm_t)
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, 0.0, arm_t)
	_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, ProceduralFigure.ARM_OUTWARD_ANGLE + PENGUIN_FLIPPER_SPREAD, arm_t)
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, -ProceduralFigure.ARM_OUTWARD_ANGLE - PENGUIN_FLIPPER_SPREAD, arm_t)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, 0.0, arm_t)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, 0.0, arm_t)
	# Lifting the left foot plants the right: lean right (positive roll).
	_penguin_waddle_roll = PENGUIN_WADDLE_ROLL * cos(phase) * blend
	_penguin_waddle_posed = true
	_update_footsteps(phase, stepping, false)


## Picks a fresh idle pose -- see the IDLE_* consts' own comment for the
## reasoning and the caveat that the two new rotation axes here (leg
## abduction, hip drop) aren't visually re-verified in-engine.
func _roll_idle_pose() -> void:
	_idle_elbow_left = -randf_range(IDLE_ELBOW_MIN, IDLE_ELBOW_MAX)
	_idle_elbow_right = -randf_range(IDLE_ELBOW_MIN, IDLE_ELBOW_MAX)
	_idle_leg_variant_active = randf() < IDLE_LEG_VARIANT_CHANCE
	_idle_bent_leg_side = 1.0 if randf() < 0.5 else -1.0
	_idle_knee_bend = randf_range(IDLE_KNEE_MIN, IDLE_KNEE_MAX)


func _update_footsteps(stride_phase: float, audible: bool, running: bool) -> void:
	# Blorbus has no feet and owns his own soft glide cue; Humongous likewise
	# owns a scaled movement-pressure cue. Never let the hidden/following human
	# rig leak its stride sounds into either possession mode.
	if _player_following_blorbus or _player_following_manchego:
		_footsteps_were_moving = false
		return
	# The dirt-bike wheels own ground contact even though the underlying rig
	# still evaluates a locomotion cycle for posing. Never translate that hidden
	# leg cycle into audible human footfalls.
	# Extended skate blades suppress steps only while they actually own the
	# movement contact on ice (or are airborne from an ice-skating launch).
	# Off ice they are passive hardware under an ordinary walking gait, so
	# snow still produces its normal left/right footfall texture.
	if _dirtbike_wheel_active or _snowboard_active or _ice_skating_active or _ice_skate_airborne:
		_footsteps_were_moving = false
		return
	if _standing_on_cloud:
		_footsteps_were_moving = false
		return
	if _is_on_lava_surface():
		_footsteps_were_moving = false
		return
	var half_cycle: int = floori(stride_phase / PI)
	if not audible:
		_footsteps_were_moving = false
		_footstep_half_cycle = half_cycle
		return
	if not _footsteps_were_moving:
		_footsteps_were_moving = true
		_footstep_half_cycle = half_cycle
		return
	if half_cycle == _footstep_half_cycle:
		return
	_footstep_half_cycle = half_cycle
	# stride_phase 0 and PI are the two planted-foot/loading moments used by
	# the run body's own contact bob and stance-knee curves below.
	var snow_surface: bool = (
		terrain != null
		and terrain.has_method("is_snow_footstep_surface")
		and terrain.is_snow_footstep_surface(Vector2(global_position.x, global_position.z))
	)
	UISounds.play_footstep(posmod(half_cycle, 2) == 1, running, get_instance_id(), snow_surface)


func _is_on_lava_surface() -> bool:
	if terrain == null or not terrain.has_method("is_lava_area"):
		return false
	var xz := Vector2(global_position.x, global_position.z)
	if not bool(terrain.is_lava_area(xz)) or _lava_swimming_active:
		return false
	if not terrain.has_method("get_lava_surface_height"):
		return false
	var lava_y: float = terrain.get_lava_surface_height(xz)
	return absf((global_position.y - FOOT_OFFSET) - lava_y) <= 0.28


## `traversal_speed_multiplier` removes the blorb-skate boost from the
## animation calculation. The player covers three times the ground while
## skating, but the established run cycle keeps its original pace.
func _animate_walk(
	delta: float, grounded: bool, traversal_speed_multiplier: float = 1.0,
	animation_speed_override: float = -1.0
) -> void:
	# Ice skating owns every locomotion joint and the body-height offsets in
	# its dedicated final pose layer. Letting the ordinary zero-speed gait
	# settle those same joints toward standing first made the two animators
	# fight every frame and visually erased most of the sprint crouch.
	if _ice_skating_active:
		_footsteps_were_moving=false
		return
	# Lake swimming is neither a jump nor standing: both surface swimming and
	# a motionless underwater diver use the intentionally relaxed descent
	# silhouette. It takes precedence over the transient landing pose so
	# entering water never reads as a land impact.
	if _lake_buoyancy_active and not _lake_floor_walk_active and not _lake_weighted_descent_active:
		_footsteps_were_moving = false
		_animate_swimming(delta)
		return
	if _air_flight_active or _fire_limb_flight_active or _water_leg_hover_active or _fire_hand_hover_active or _fire_leg_hover_active:
		_footsteps_were_moving = false
		# Flight shares the relaxed floating silhouette but intentionally does
		# not inherit water's flipper-kick layer. Water jets and either paired
		# Fire-jet hover also stay out of the walk cycle; thrust carries the body.
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
		_footsteps_were_moving = false
		_landing_timer -= delta
		_animate_landing(delta)
		return

	if not grounded:
		_footsteps_were_moving = false
		_animate_airborne(delta)
		return
	if _penguin_waddling():
		_animate_penguin_waddle(delta)
		return
	# Landing spreads the shoulders briefly to brace the impact. Every
	# ordinary grounded pose returns that spread to its rig-specific rest
	# angle.
	var arm_rest_t := POSE_SETTLE_SPEED * delta
	var left_arm_rest := ProceduralFigure.ARM_OUTWARD_ANGLE
	var right_arm_rest := -ProceduralFigure.ARM_OUTWARD_ANGLE
	_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, left_arm_rest, arm_rest_t)
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, right_arm_rest, arm_rest_t)

	var horizontal_speed := (
		animation_speed_override
		if animation_speed_override >= 0.0
		else Vector2(velocity.x, velocity.z).length() / traversal_speed_multiplier
	)
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
		var cadence_scale := 1.0
		var swing_speed := WALK_SWING_SPEED * cadence_scale * (SPRINT_SWING_SPEED_SCALE if sprinting else 1.0)
		var swing_amount := SPRINT_SWING_AMOUNT if sprinting else WALK_SWING_AMOUNT
		var bend_scale := SPRINT_BEND_SCALE if sprinting else 1.0
		_walk_phase += HumanoidLocomotion.walk_phase_step(
			delta, WALK_SWING_SPEED, horizontal_speed, _playable_profile,
			SPRINT_SWING_SPEED_SCALE if sprinting else 1.0
		)
		# See SPRINT_STRIDE_EASE's own comment -- warps the phase used for the
		# rest of this cycle (swing, knee/elbow bend, body bob below) so the
		# run stride snaps through the crossing point and hangs at the
		# outstretched extremes, without touching _walk_phase's own linear
		# accumulation above. Equal to _walk_phase while walking, so walking's
		# timing is unchanged.
		var stride_phase := _walk_phase
		if sprinting:
			stride_phase += SPRINT_STRIDE_EASE * sin(2.0 * _walk_phase)
		_update_footsteps(
			stride_phase,
			not _air_foot_hover_active and traversal_speed_multiplier <= 1.001,
			sprinting
		)
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
		var default_elbow_bend := 0.0
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
		var nominal_move_speed := move_speed
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
		var body_motion_scale := 1.0
		var body_dip := -ProceduralFigure.WALK_BODY_DIP_AMOUNT * body_motion_scale * pow(sin(stride_phase), 2)
		var body_bob := -RUN_BODY_BOB_AMOUNT * body_motion_scale * cos(2.0 * stride_phase)
		var body_offset := body_bob if sprinting else body_dip
		_spine.position.y = _spine_rest_y + body_offset
		# The monkey's pear body is already a child of its spine pivot, unlike
		# the human pelvis. Moving both would apply the offset twice to the body
		# and visibly pull it away from the leg attachments.
		_hips.position.y = _hips_rest_y + body_offset
		_was_moving = true
	else:
		_footsteps_were_moving = false
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
		var idle_elbow_base := 0.0
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


## THE ONLY PER-FRAME WRITER OF `visuals`' TRANSFORM (the rendered body's
## placement on this CharacterBody). Everything else feeds it inputs:
## steering, throw aim, followers and the giant turn _body_yaw; the snow sink
## and dirtbike/skate lifts come in through _body_base_height(); each mode
## below owns its tilt. Several earlier writers each "fixed" a landmark by
## shifting the body after some other writer had run, and the last one each
## frame silently won (the snow sink overwrote flight's skull pin that way),
## so there is one placement pass, run after movement, bounces and ground
## snapping have finished moving the collision body.
##
## Exactly one mode places the body each frame, by what it pivots on:
##   foot hover   - feet; yaw toward travel (air legs keep a walking body)
##   skull        - base of the skull; flight and deep swimming
##   flight exit  - feet; eases a flying body upright after flight ends
##   dirtbike     - spine over the wheel for steering, rear axle for wheelies
##   ground       - feet (skates included), plus the snowboard's slope tilt
## Riding a mount and the wake intro own the transform outright (see
## start_riding_manchego() and _apply_wake_intro_pose()), so this yields.
func _compose_body_pose(delta: float, grounded: bool, on_soft_aerial_support: bool, buoyant: bool) -> void:
	if _wake_intro_active or visuals.top_level:
		return
	var base_y := _body_base_height(delta, grounded, on_soft_aerial_support, buoyant)
	if _air_foot_hover_active and not _air_flight_active and not _fire_limb_flight_active and not _lake_buoyancy_active:
		_release_skull_anchor()
		_aerial_rest_heading_initialized = false
		_pose_body_foot_hover(delta, base_y)
	elif (_lake_buoyancy_active and not _lake_floor_walk_active and not _lake_weighted_descent_active) or _air_flight_active or _fire_limb_flight_active:
		_pose_body_skull_anchored(delta)
	else:
		_release_skull_anchor()
		_aerial_rest_heading_initialized = false
		if _air_flight_exit_recovery > 0.0:
			_pose_body_flight_exit(delta, base_y)
		elif _dirtbike_wheel_active:
			_pose_body_dirtbike(delta, grounded, base_y)
		elif _update_penguin_prone(delta) > 0.0 or absf(_penguin_waddle_roll) > 0.0001:
			_pose_body_penguin(base_y)
		else:
			_pose_body_ground(base_y)
			if _snowboard_active:
				_apply_snowboard_surface_orientation(delta, grounded)
				# The slope tilt persists through its own heading, the same
				# Euler yaw the next frame's ground pose starts from.
				_body_yaw = visuals.rotation.y
	_dirtbike_visual_base_y = base_y
	_body_yaw_steered = false


## Eases _penguin_prone toward lying down while the Penguin Suit dives or
## belly-slides, and back upright otherwise. Returns the new value.
func _update_penguin_prone(delta: float) -> float:
	var target := 1.0 if (_penguin_dive_airborne or _penguin_belly_sliding) else 0.0
	_penguin_prone = move_toward(_penguin_prone, target, PENGUIN_PRONE_RATE * delta)
	# A waddle lean the gait did not refresh this frame settles upright.
	if not _penguin_waddle_posed:
		_penguin_waddle_roll = move_toward(_penguin_waddle_roll, 0.0, PENGUIN_WADDLE_ROLL * 4.0 * delta)
	_penguin_waddle_posed = false
	return _penguin_prone


## The Penguin Suit's body poses. Diving and belly sliding, the body tips
## forward about its belly, head leading, until it lies flat with the belly
## resting on the ice. Waddling, it leans side to side about the feet
## (_penguin_waddle_roll). The collision capsule stays upright.
func _pose_body_penguin(base_y: float) -> void:
	var tip := smoothstep(0.0, 1.0, _penguin_prone)
	var tipped := Basis(Vector3.UP, _body_yaw) * Basis(Vector3.RIGHT, tip * PI * 0.5)
	var pivot_height := lerpf(PENGUIN_BODY_PIVOT_HEIGHT, PENGUIN_BELLY_REST_HEIGHT, tip)
	# The lean is applied innermost, so it turns about the feet (the origin).
	visuals.basis = tipped * Basis(Vector3.BACK, _penguin_waddle_roll)
	visuals.position = Vector3(0.0, base_y + pivot_height, 0.0) - tipped * (Vector3.UP * PENGUIN_BODY_PIVOT_HEIGHT)


## Upright on the feet at the given height, facing _body_yaw.
func _pose_body_ground(base_y: float) -> void:
	visuals.rotation = Vector3(0.0, _body_yaw, 0.0)
	visuals.position = Vector3(0.0, base_y, 0.0)


## Air-foot hover travels in the camera's full 3D direction but keeps an
## ordinary upright walk/run silhouette: turn the body toward the planar
## travel direction without the pitched, trailing flight body.
func _pose_body_foot_hover(delta: float, base_y: float) -> void:
	visuals.rotation.y = _body_yaw
	if _aerial_motion_direction.length_squared() > 0.001:
		var planar_direction := _aerial_motion_direction
		planar_direction.y = 0.0
		if planar_direction.length_squared() > 0.001:
			var target_basis := Basis(Vector3.UP, atan2(planar_direction.x, planar_direction.z))
			var t := minf(rotation_speed * delta, 1.0)
			visuals.basis = Basis(visuals.basis.get_rotation_quaternion().slerp(target_basis.get_rotation_quaternion(), t))
	var settle := visuals.position.lerp(Vector3(0.0, -FOOT_OFFSET, 0.0), minf(AERIAL_BODY_LEAN_SPEED * delta, 1.0))
	visuals.position = Vector3(settle.x, base_y, settle.z)
	_sync_body_yaw_from_visuals()


## Flight and deep swimming: the body pivots about the base of the skull, so
## the skull leads through the air or water while the torso and legs trail,
## and the camera (which orbits this same point, see camera_focus_point())
## stays a constant distance from the head at every pitch. The collision
## body keeps its feet origin; only the rendered body and the capsule pose
## (_fit_collision_to_body()) follow the skull.
func _pose_body_skull_anchored(delta: float) -> void:
	if not _aerial_skull_anchor_initialized:
		_aerial_skull_body_offset = _head.global_position-global_position
		_aerial_skull_anchor_initialized = true
	var skull_anchor := global_position+_aerial_skull_body_offset
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
		# space: forward=0, right=+90, back=180, left=-90. Visuals has the
		# camera-facing 180° basis correction above, which mirrors this local
		# yaw convention; negate stick X so forward-left aims the body
		# forward-left rather than its reflected right side.
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
				_aerial_rest_yaw = _body_yaw
			_aerial_was_moving = false
			_aerial_rest_heading_initialized = true
		var t := minf(AERIAL_BODY_REST_SPEED * delta, 1.0)
		var upright := Basis(Vector3.UP, _aerial_rest_yaw).get_rotation_quaternion()
		var current_transform := visuals.global_transform
		current_transform.basis = Basis(current_transform.basis.get_rotation_quaternion().slerp(upright, t))
		visuals.global_transform = current_transform
	# Rotating Visuals normally pivots around its feet. Restore the head
	# after that rotation, making the neck/head junction the real visual
	# pivot without changing the collision body's stable feet origin.
	visuals.global_position += skull_anchor - _head.global_position
	# The capsule follows the rendered body rather than standing upright
	# under the pinned skull. A level flier can therefore skim the ground
	# and slide along walls with its real silhouette, and a body swinging
	# upright near the ground is pushed up onto its feet by ordinary
	# collision recovery.
	_fit_collision_to_body()
	_sync_body_yaw_from_visuals()


## Removing the flight suit mid-air eases the body upright toward the heading
## it was flying, about the feet, rather than snapping. It slerps toward an
## explicitly upright WORLD basis: clearing Euler X/Z independently could make
## a steep flight basis decompose to the opposite Y solution and turn the
## character around toward the camera.
func _pose_body_flight_exit(delta: float, base_y: float) -> void:
	visuals.rotation.y = _body_yaw
	var t := minf(AERIAL_BODY_LEAN_SPEED * delta, 1.0)
	var upright := Basis(Vector3.UP, _air_flight_exit_yaw).get_rotation_quaternion()
	visuals.basis = Basis(visuals.basis.get_rotation_quaternion().slerp(upright, t))
	var settle := visuals.position.lerp(Vector3(0.0, -FOOT_OFFSET, 0.0), t)
	visuals.position = Vector3(settle.x, base_y, settle.z)
	_air_flight_exit_recovery = maxf(_air_flight_exit_recovery - delta, 0.0)
	_sync_body_yaw_from_visuals()


## The dirt blorb suit's body, in the order its pivots depend on each other:
## 1. Steering turns about the rider's centre of mass, not the rear axle that
##    Visuals' own origin sits on once lifted: after the turn, shift so the
##    spine's planar centre is back over the CharacterBody (per direct
##    correction, "shift it forward to his center of mass").
## 2. Out of a wheelie, pitch and any steering drift ease back to level.
## 3. The wheel lift follows _body_base_height() as a change in height, so
##    the translation from rotating about the spine or axle is preserved.
## 4. The wheelie pitches about the rear axle (_apply_dirtbike_wheelie_pitch()).
func _pose_body_dirtbike(delta: float, grounded: bool, base_y: float) -> void:
	var spine_height_before := _spine.global_position.y
	visuals.rotation.y = _body_yaw
	if _body_yaw_steered:
		var pivot := Vector3(global_position.x, spine_height_before, global_position.z)
		visuals.global_position += pivot - _spine.global_position
	if not _dirtbike_wheelie_active:
		var rest_t := minf(DIRTBIKE_WHEELIE_SETTLE_SPEED*delta, 1.0)
		visuals.rotation.x = lerp_angle(visuals.rotation.x, 0.0, rest_t)
		visuals.position = visuals.position.lerp(Vector3(0.0, _dirtbike_visual_base_y, 0.0), rest_t)
	visuals.rotation.z = 0.0
	visuals.position.y += base_y - _dirtbike_visual_base_y
	_apply_dirtbike_wheelie_pitch(delta, grounded)


func _sync_body_yaw_from_visuals() -> void:
	var planar_forward := visuals.global_basis.z
	planar_forward.y = 0.0
	if planar_forward.length_squared() > 0.001:
		_body_yaw = atan2(planar_forward.x, planar_forward.z)


## The centre of the body's mass in world space: the collision capsule's
## centre, which stands upright on the feet but follows the rendered body
## level while flying or swimming (see _fit_collision_to_body()). World
## triggers that care about "most of the body passed through" read this.
func body_center() -> Vector3:
	return _collision_shape.global_position


## Where the hero's own body is, for world triggers that care about the
## suit-wearing hero passing through them (CheckpointPortal): his body centre
## on foot, or his torso above the saddle while he rides a mount. null while
## control rests with another body (Blorbus, Xiao Hou Zi, a party member).
func suit_wearer_center() -> Variant:
	if PartyControl.active_control_body() == self:
		return body_center()
	if _player_following_manchego and _mounted_rider == self and is_instance_valid(_controlled_manchego):
		return _controlled_manchego.get_seat_transform().origin + Vector3.UP * RIDER_TORSO_ABOVE_SEAT
	return null


## A seated rider's centre of mass sits about this far above the saddle.
const RIDER_TORSO_ABOVE_SEAT := 0.5


## Turns the body to face `yaw` at once, for scripted placement (a spawn, a
## test setup). Gameplay turning eases _body_yaw instead.
func set_body_heading(yaw: float) -> void:
	_body_yaw = yaw
	visuals.rotation.y = yaw


## Re-poses the standing capsule so it follows the rendered body, keeping the
## capsule's authored placement relative to the rig. Standing upright, this
## reproduces _standing_collision_transform exactly.
func _fit_collision_to_body() -> void:
	var standing_visuals := Transform3D(Basis(), Vector3(0.0, -FOOT_OFFSET, 0.0))
	var body := Transform3D(visuals.transform.basis.orthonormalized(), visuals.transform.origin)
	_collision_shape.transform = body * standing_visuals.affine_inverse() * _standing_collision_transform
	var capsule := _collision_shape.shape as CapsuleShape3D
	var half_segment := maxf(capsule.height * 0.5 - capsule.radius, 0.0)
	var axis_rise := absf(_collision_shape.transform.basis.y.normalized().y)
	_body_bottom_height = _collision_shape.transform.origin.y - axis_rise * half_segment - capsule.radius


## Ends skull anchoring: restores the standing capsule and clears the anchor
## state. A level body skimming the ground has this CharacterBody's origin
## up to ~1.1 m below the surface, so the origin is first lifted just enough
## for the restored standing capsule to start above the analytic ground
## (never above where the body's underside already was). Mid-air there is
## nothing to clear, so nothing moves.
func _release_skull_anchor() -> void:
	if not _aerial_skull_anchor_initialized:
		return
	_aerial_skull_anchor_initialized = false
	_collision_shape.transform = _standing_collision_transform
	if terrain != null and _body_bottom_height > 0.0:
		var ground_y: float = terrain.get_mesh_height(global_position.x, global_position.z)
		var lift := clampf(ground_y + FOOT_OFFSET - global_position.y, 0.0, _body_bottom_height)
		global_position.y += lift
	_body_bottom_height = 0.0


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
	var landing_motion_scale := 1.0
	var landing_dip := LANDING_BODY_DIP_AMOUNT * landing_motion_scale
	_spine.rotation.x = lerp_angle(_spine.rotation.x, LANDING_SPINE_LEAN, t)
	_spine.position.y = lerp(_spine.position.y, _spine_rest_y - landing_dip, t)
	# MonkeyFigure's pear body is already beneath the moving spine. Applying
	# the landing offset to both would double its sink and detach it from the
	# short legs, just like the earlier walk-bob issue.
	var hips_landing_y := _hips_rest_y - landing_dip
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

## Generalized "has a sealed air supply" check -- currently just the Diving
## Helmet, kept as its own function (not inlined at each call site) so a
## future space biome's own sealed suit can extend this later without
## touching every place breath is checked. Per direct instruction: equipping
## the helmet while already out of breath recovers it immediately, which
## falls out naturally here -- _update_breath() below only ever looks at
## this function's CURRENT return value, never a cached one.
func _has_air_supply() -> bool:
	return _blorb_suit.has_head_diving_helmet()


## Set every frame at the top of _update_lake_buoyancy(), before breath's own
## check runs later that same frame.
var _in_lava_area_now: bool = false


## Generalized "no air here" hazard area -- currently only underwater
## submersion. Lava is excluded entirely, in every one of its own sub-states
## (fully suited swimming, protected surface walking, or even just standing
## in unprotected lava) -- per direct instruction ("I don't want lava to
## take away your breath... assume the lava helm takes care of it. You
## shouldn't be running out of breath in lava ever"); it already has its own
## separate heat-damage handling, so this isn't double-dipping, it's a
## deliberate carve-out. A future space/vacuum biome would extend this the
## same way, alongside water, not lava.
func _in_airless_area() -> bool:
	if not has_playable_capability(&"needs_breath"):
		return false
	return _lake_buoyancy_active and not _in_lava_area_now and not _face_above_water()


## Every water state (surface swimming included) runs through lake buoyancy,
## so being in the water alone must not count as airless. The face centre is
## the same point the wake intro frames. While swimming at the surface the
## skull is pinned just above the waterline, so this breathes there.
func _face_above_water() -> bool:
	var face := _head.to_global(Vector3(0.0, ProceduralFigure.HEAD_SIZE.y, 0.0))
	return face.y >= _active_swim_surface_height


## Per direct instruction: a breath meter that drains while in an airless
## area without an air supply, refills quickly once either clears, and
## deals periodic HP damage once it's fully empty until air is regained or
## HP reaches zero (current_hp's own <= 0.0 check in take_damage() already
## triggers the faint). The rounded-int gate on emitting breath_changed
## keeps hud.gd from rebuilding its meter 60 times a second while breath is
## merely trickling between two displayed integers.
func _update_breath(delta: float) -> void:
	var needs_air := _in_airless_area() and not _has_air_supply()
	if needs_air:
		breath = maxf(breath - BREATH_DRAIN_RATE * delta, 0.0)
	else:
		breath = minf(breath + BREATH_REFILL_RATE * delta, MAX_BREATH)
	var rounded := roundi(breath)
	if rounded != _last_emitted_breath_int:
		_last_emitted_breath_int = rounded
		breath_changed.emit(breath, MAX_BREATH)
	if needs_air and breath <= 0.0:
		_breath_damage_timer -= delta
		if _breath_damage_timer <= 0.0:
			_breath_damage_timer = BREATH_DAMAGE_INTERVAL
			take_damage(BREATH_DAMAGE_AMOUNT)
	else:
		_breath_damage_timer = BREATH_DAMAGE_INTERVAL


## Lake buoyancy deliberately shares the giant's direct positional lift
## instead of adding a collision plane. A collision plane would make the
## lake behave like solid ground; this keeps the player visibly immersed and
## simply settles them at a chest-deep swimming height. The giant takes
## precedence should its footprint ever overlap the lake.
func _update_lake_buoyancy(delta: float) -> void:
	_lake_buoyancy_active = false
	_lake_diving_active = false
	_lake_floor_walk_active = false
	_lake_weighted_descent_active = false
	_lava_swimming_active = false
	_lava_surface_walk_active = false
	_in_lava_area_now = false
	if _giant_goo_active or terrain == null:
		return
	var water_pos := Vector2(global_position.x, global_position.z)
	var in_lava_area: bool = (
		terrain.has_method("is_lava_area")
		and terrain.has_method("get_lava_surface_height")
		and terrain.is_lava_area(water_pos)
	)
	_in_lava_area_now = in_lava_area
	var in_lava_volume: bool = in_lava_area and _blorb_suit.has_full_lava_suit()
	var in_water_volume: bool = terrain.has_method("is_lake_area") and terrain.is_lake_area(water_pos)
	if not in_water_volume and not in_lava_area:
		return
	var water_level: float = terrain.get_lava_surface_height(water_pos) if in_lava_area else terrain.get_lake_water_level()
	_active_swim_surface_height = water_level
	_lava_swimming_active = in_lava_volume
	# Two landed fire leg blorbs protect an ordinary suit by supporting it on
	# the molten surface. Only the complete Lava Helm formation replaces this
	# support with immersion/swimming. Preserve a real jump above the surface,
	# then catch descending feet exactly at the liquid plane.
	if in_lava_area and not in_lava_volume and _blorb_suit.has_lava_safe_legs():
		var feet_y:float=global_position.y-FOOT_OFFSET
		if _jumping and (velocity.y>0.0 or feet_y>water_level):
			return
		# Do not pull a falling player down from above. The ordinary gravity arc
		# continues until the feet actually reach the molten surface band.
		if feet_y>water_level+LAVA_CONTACT_TOLERANCE:
			return
		_lava_surface_walk_active=true
		global_position.y=water_level+FOOT_OFFSET
		velocity.y=0.0
		_jumping=false
		return
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
	# Two Rock legs convert the seabed into an ordinary walkable floor --
	# per direct correction, no longer gated on the Diving Helmet too (see
	# _has_air_supply()'s own doc comment: walking the bottom without the
	# helmet still works, it just drains breath while doing it). Becoming
	# heavy starts a physical descent; only real contact with the seabed
	# changes into the planar walking state.
	if not in_lava_volume and _blorb_suit.has_rock_walking_legs():
		_jumping = false
		_lake_buoyancy_active = true
		var floor_target: float = floor_height + FOOT_OFFSET
		var reached_floor := is_on_floor() or global_position.y <= floor_target + LAKE_FLOOR_LANDING_TOLERANCE
		if reached_floor:
			_lake_floor_walk_active = true
			global_position.y = maxf(global_position.y, floor_target)
			velocity.y = 0.0
		else:
			_lake_weighted_descent_active = true
			velocity.y = move_toward(velocity.y, -LAKE_WEIGHTED_SINK_SPEED, LAKE_WEIGHTED_SINK_ACCELERATION * delta)
		return
	# Free three-dimensional dive/swim movement, bounded only by the lake
	# floor and the same surface height an unhelmeted swimmer used to float
	# at. Per direct correction ("no matter what the player is wearing...
	# he can use diving physics and go underwater"), this is no longer
	# gated on the Diving Helmet for ordinary water -- only breath (see
	# _has_air_supply()) depends on the helmet now. Lava keeps its own
	# original rule (only a full suit gets real immersion; see the
	# unprotected-lava fallback below, still reached exactly when
	# `in_lava_area and not in_lava_volume` and there's no other lava
	# handling above). A worn chest air blorb gets the same treatment while
	# actually submerged: flying must not override swimming, per direct
	# correction. Once its climb carries the player back above the surface,
	# this returns early and hands off to the ordinary flight controller,
	# which can then continue straight up out of the water.
	if not in_lava_area or in_lava_volume:
		if global_position.y > water_level:
			return
		# Once a surface jump has launched, do not let the diving clamp erase
		# its upward velocity on the following frame. The ordinary airborne
		# path takes over until descending feet meet the water again.
		if _jumping and velocity.y > 0.0:
			return
		_jumping = false
		_lake_buoyancy_active = true
		_lake_diving_active = true
		# Measured to the body's underside, so a level diver can glide just
		# above the lakebed instead of hovering a body-length over it.
		var dive_floor := floor_height + LAKE_DIVE_FLOOR_CLEARANCE - _body_bottom_height
		var dive_surface := water_level - LAKE_SWIM_FOOT_DEPTH
		global_position.y = clampf(global_position.y, dive_floor, dive_surface)
		return
	# Per direct instruction ("we no longer even need the mechanics of
	# swimming at the surface of water... don't delete it entirely, just
	# change it") -- ordinary water always resolves through the free-dive
	# branch above now, so this plain chest-deep-only float is only ever
	# reached for its one remaining real case: stepping into lava without a
	# full suit and without Rock legs (Rock legs alone already return via
	# the floor-walk branch above, full-suit lava returns via the dive
	# branch above). Kept, not deleted, for exactly that case.
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


## A chest-mounted air blorb supplies free flight in air, but never turns
## into underwater propulsion. Ordinary buoyancy keeps its wearer swimming
## at the surface until a real Diving Helmet is present.
func _update_air_flight() -> void:
	_air_flight_active = _blorb_suit.has_chest_air_blorb() and not _lake_buoyancy_active
	if _air_flight_active:
		_jumping = false
		if not _was_air_flight_active and not _lake_diving_active:
			var ground_height: float = terrain.get_mesh_height(global_position.x, global_position.z)
			global_position.y = maxf(global_position.y, ground_height + FOOT_OFFSET + AIR_FLIGHT_HOVER_HEIGHT)
	_was_air_flight_active = _air_flight_active


## Dirt blorb suit gate + wheel visuals. Purely reads suit/input state and
## drives the two wheel props here -- the actual movement consequences (no
## uphill slope limit) live in _try_step_up()/_snap_to_terrain(), and the
## leg/body pose lives in _apply_dirtbike_pose(), both of which just read
## the two bools this sets.
func _update_dirtbike_state(delta: float) -> void:
	_dirtbike_wheel_active = _blorb_suit.has_dirtbike_legs()
	floor_max_angle = DIRTBIKE_FLOOR_MAX_ANGLE if _dirtbike_wheel_active else _dirtbike_default_floor_max_angle

	# Per direct correction ("if paused during arm wheels, unpausing holding
	# something should bring out of arm wheels") -- edge-detects the modal
	# (pause/menu) closing, same idiom as _dirtbike_wheelie_chord_was_pressed/
	# _was_air_flight_active elsewhere in this file. A player can open a
	# menu while the wheelie is toggled on and pick up/equip a held item
	# from it; nothing else re-checks that combination once they close the
	# menu, so this is the one place that has to.
	if _was_modal_open and not UIState.modal_open and not HeldItem.current.is_empty():
		_dirtbike_wheelie_toggled_on = false
	_was_modal_open = UIState.modal_open

	# Per direct correction, a TOGGLE now: the chord (both arm-power buttons
	# together) flips _dirtbike_wheelie_toggled_on on the frame it first
	# forms, not "active for as long as both stay held" any more -- see that
	# field's own doc comment. Per a further direct correction ("if holding
	# an object, which disables blorb powers, it should prevent from going
	# into arm wheels") -- HeldItem.current.is_empty() is this project's own
	# established "is the player holding anything" check (see
	# _held_item_is_weapon()'s and _update_throw_input()'s own use of it);
	# folded into chord_pressed itself so holding something doesn't just
	# fail to fire the toggle, it can't even register as forming the chord.
	var has_arms := _blorb_suit.has_dirtbike_arms()
	var chord_pressed := (
		not UIState.modal_open
		and HeldItem.current.is_empty()
		and Input.is_action_pressed("left_arm_power")
		and Input.is_action_pressed("right_arm_power")
	)
	var chord_just_formed := chord_pressed and not _dirtbike_wheelie_chord_was_pressed
	_dirtbike_wheelie_chord_was_pressed = chord_pressed
	if not _dirtbike_wheel_active or not has_arms:
		_dirtbike_wheelie_toggled_on = false
		_dirtbike_supported_pitch = 0.0
	elif chord_just_formed:
		_dirtbike_wheelie_toggled_on = not _dirtbike_wheelie_toggled_on
	_dirtbike_wheelie_active = _dirtbike_wheelie_toggled_on
	if not _dirtbike_wheelie_active:
		_dirtbike_supported_pitch = 0.0
		_dirtbike_pitch_was_grounded = false

	# Only lifecycle (build/free) here, deliberately not positioning -- this
	# runs early in _physics_process (alongside _update_air_flight()), before
	# _animate_walk()/_apply_dirtbike_pose() have posed this frame's ankle/
	# wrist pivots (or _compose_body_pose() lifted the body onto the wheel) yet.
	# Positioning happens at the very end of _physics_process instead (see
	# _update_dirtbike_wheels(), called last), so the wheel reads this
	# frame's fully-resolved pose rather than last frame's.
	if _dirtbike_wheel_active:
		if _dirtbike_rear_wheel == null:
			_dirtbike_rear_wheel = _build_dirtbike_wheel()
	elif _dirtbike_rear_wheel != null:
		_dirtbike_rear_wheel.queue_free()
		_dirtbike_rear_wheel = null

	if _dirtbike_wheelie_active:
		if _dirtbike_front_wheel == null:
			_dirtbike_front_wheel = _build_dirtbike_wheel()
	elif _dirtbike_front_wheel != null:
		_dirtbike_front_wheel.queue_free()
		_dirtbike_front_wheel = null


## A simultaneous Snow-leg chord toggles the board as equipment state, not as
## a ground-contact state. It can be deployed/retracted during a jump and
## remains deployed through falls, landings, and temporary travel over a
## non-snow surface. Only another chord or losing the required Snow legs may
## remove it; terrain decides where it glides, never whether it exists.
func _update_snowboard_state() -> void:
	var has_legs:=_blorb_suit.has_snowboard_legs()
	var chord_pressed:=(
		has_legs
		and not UIState.modal_open
		and HeldItem.current.is_empty()
		and Input.is_action_pressed("left_leg_power")
		and Input.is_action_pressed("right_leg_power")
	)
	var chord_just_formed:=chord_pressed and not _snowboard_chord_was_pressed
	_snowboard_chord_was_pressed=chord_pressed
	var supported:=_is_snowboard_surface()
	if not has_legs:
		_snowboard_toggled_on=false
	elif chord_just_formed:
		_snowboard_toggled_on=not _snowboard_toggled_on
	var was_active:=_snowboard_active
	_snowboard_active=_snowboard_toggled_on and has_legs
	if _snowboard_active:
		floor_max_angle=DIRTBIKE_FLOOR_MAX_ANGLE
		if not was_active:
			# Midair deployment must not sample a distant mountain surface and
			# snap the new deck toward it. It begins neutral and the ballistic
			# visual pass aligns it with live travel until a real landing.
			_snowboard_smoothed_up=_snowboard_surface_up() if supported else Vector3.UP
	if was_active and not _snowboard_active:
		# Board momentum belongs to this particular ride, not to the player or
		# the next board instance. Unequipping must therefore end the ride
		# completely instead of preserving a stale glide for the next toggle.
		velocity.x=0.0
		velocity.z=0.0
		var heading:=_snowboard_last_heading
		if heading.length_squared()>0.001:
			_body_yaw=atan2(heading.x,heading.z)
		_snowboard_smoothed_up=Vector3.UP
		_snowboard_smoothed_rider_grade=0.0
	if _snowboard_active:
		if _snowboard==null:
			_snowboard=_build_snowboard()
	elif _snowboard!=null:
		_snowboard.queue_free()
		_snowboard=null


## Ends the dive on touchdown (onto the belly when it lands on ice) and ends
## the belly slide once it leaves the ground or the suit breaks up. The slide
## itself stops in _penguin_belly_slide_step() when it runs out of speed.
func _update_penguin_state() -> void:
	if not _blorb_suit.penguin_form_active():
		_penguin_dive_airborne = false
		_penguin_belly_sliding = false
		return
	var on_ice := _is_supported_by_ice()
	if _penguin_dive_airborne and not _jumping and velocity.y <= 0.0 and (is_on_floor() or on_ice or _is_near_ground()):
		_penguin_dive_airborne = false
		_penguin_belly_sliding = on_ice
		if on_ice:
			velocity.x *= PENGUIN_SLIDE_LANDING_BOOST
			velocity.z *= PENGUIN_SLIDE_LANDING_BOOST
			UISounds.play_foley(&"blorb_glide", 0.5, get_instance_id())
	elif _penguin_belly_sliding and not on_ice and not (is_on_floor() or _is_near_ground()):
		_penguin_belly_sliding = false


## Jump on ice in the Penguin Suit: a low ballistic dive forward, toward the
## stick if it is held, otherwise the way the body faces, and never slower
## than PENGUIN_DIVE_FORWARD_SPEED.
func _begin_penguin_dive() -> void:
	var stick := _get_move_input()
	var rig_basis := camera_rig.global_transform.basis
	var heading := rig_basis.x * stick.x + rig_basis.z * stick.y
	heading.y = 0.0
	if heading.length_squared() < 0.0001:
		heading = Vector3(sin(_body_yaw), 0.0, cos(_body_yaw))
	heading = heading.normalized()
	var speed := maxf(Vector2(velocity.x, velocity.z).length(), PENGUIN_DIVE_FORWARD_SPEED)
	velocity.x = heading.x * speed
	velocity.z = heading.z * speed
	velocity.y = HumanoidLocomotion.jump_speed(_playable_profile, PENGUIN_DIVE_HEIGHT)
	_body_yaw = atan2(heading.x, heading.z)
	_jump_takeoff_speed = absf(velocity.y)
	_jumping = true
	_penguin_dive_airborne = true
	_penguin_belly_sliding = false
	_ice_skating_active = false
	UISounds.play_foley(&"jump", 0.52, get_instance_id())


## Jump during a belly slide: a small hop back up onto the feet. The slide's
## momentum carries on underfoot.
func _stand_from_belly_slide() -> void:
	_penguin_belly_sliding = false
	velocity.y = HumanoidLocomotion.jump_speed(_playable_profile, PENGUIN_STAND_HOP_HEIGHT)
	_jump_takeoff_speed = absf(velocity.y)
	_jumping = true
	UISounds.play_foley(&"jump", 0.45, get_instance_id())


## On foot in the formed Penguin Suit: neither diving nor sliding.
func _penguin_waddling() -> bool:
	return _blorb_suit.penguin_form_active() and not _penguin_dive_airborne and not _penguin_belly_sliding


## Watches for all four limb buttons pressed together (within
## PENGUIN_CHORD_WINDOW) while the penguin-capable suit is worn, and toggles
## the Penguin Suit. Returns true while limb powers must hold back: during the
## window (leg presses in it are kept and fired if no chord completes) and
## until a completed chord's buttons are all released.
func _update_penguin_chord(delta: float) -> bool:
	const ACTIONS := ["left_arm_power", "right_arm_power", "left_leg_power", "right_leg_power"]
	if UIState.modal_open or not _blorb_suit.has_full_penguin_suit():
		_penguin_chord_timer = 0.0
		_penguin_chord_consumed = false
		_penguin_chord_pending_legs = [false, false]
		return false
	if _penguin_chord_consumed:
		_penguin_chord_consumed = ACTIONS.any(func(action: String) -> bool: return Input.is_action_pressed(action))
		return true
	var pressed_now := ACTIONS.any(func(action: String) -> bool: return Input.is_action_just_pressed(action))
	if pressed_now and _penguin_chord_timer <= 0.0:
		_penguin_chord_timer = PENGUIN_CHORD_WINDOW
	if _penguin_chord_timer <= 0.0:
		return false
	if Input.is_action_just_pressed("left_leg_power"):
		_penguin_chord_pending_legs[0] = true
	if Input.is_action_just_pressed("right_leg_power"):
		_penguin_chord_pending_legs[1] = true
	if ACTIONS.all(func(action: String) -> bool: return Input.is_action_pressed(action)):
		_penguin_chord_timer = 0.0
		_penguin_chord_consumed = true
		_penguin_chord_pending_legs = [false, false]
		if _blorb_suit.toggle_penguin_form():
			UISounds.play_foley(&"transform_reveal", 0.6, get_instance_id())
		return true
	_penguin_chord_timer -= delta
	if _penguin_chord_timer > 0.0:
		return true
	# No chord: the leg presses held during the window act as ordinary presses.
	if _penguin_chord_pending_legs[0] and _left_leg_rock_cooldown <= 0.0 and _raise_rock_platform("leg_left"):
		_left_leg_rock_cooldown = ROCK_POWER_COOLDOWN
	if _penguin_chord_pending_legs[1] and _right_leg_rock_cooldown <= 0.0 and _raise_rock_platform("leg_right"):
		_right_leg_rock_cooldown = ROCK_POWER_COOLDOWN
	_penguin_chord_pending_legs = [false, false]
	return false


## Tobogganing on the belly: ice barely slows it, anything else stops it
## quickly, and the stick only bends its heading. Stands up when slow.
func _penguin_belly_slide_step(steer: Vector3, delta: float) -> void:
	var planar := Vector2(velocity.x, velocity.z)
	var on_ice := _is_supported_by_ice()
	var speed := maxf(planar.length() - (PENGUIN_SLIDE_FRICTION if on_ice else PENGUIN_SLIDE_OFF_ICE_FRICTION) * delta, 0.0)
	if speed < PENGUIN_SLIDE_STOP_SPEED:
		_penguin_belly_sliding = false
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var heading := planar.normalized()
	var wanted := Vector2(steer.x, steer.z)
	if wanted.length_squared() > 0.0001:
		var turn := clampf(heading.angle_to(wanted.normalized()), -PENGUIN_SLIDE_TURN_RATE * delta, PENGUIN_SLIDE_TURN_RATE * delta)
		heading = heading.rotated(turn)
	velocity.x = heading.x * speed
	velocity.z = heading.y * speed
	_body_yaw = lerp_angle(_body_yaw, atan2(heading.x, heading.y), minf(rotation_speed * delta, 1.0))
	UISounds.pulse_snowboard(get_instance_id(), speed, 0.0, 0.0 if on_ice else 1.0)


## A complete pair of Ice legs automatically forms runners, and both leg
## buttons remain available for their ordinary ice-platform powers; only real
## ice grants the skating movement below. The formed Penguin Suit has no
## runners: a penguin waddles (see _animate_penguin_waddle()).
func _update_ice_skate_state() -> void:
	var has_legs: bool=_blorb_suit.has_ice_skate_legs() and not _blorb_suit.penguin_form_active()
	var was_active: bool=_ice_skates_active
	_ice_skates_active=has_legs
	var supported: bool=_ice_skates_active and _is_supported_by_ice()
	if _ice_skate_airborne and is_on_floor() and not _jumping:
		_ice_skate_airborne=false
	_ice_skating_active=supported and not _ice_skate_airborne and not _penguin_dive_airborne and not _penguin_belly_sliding
	if was_active and not _ice_skates_active:
		# Retraction ends this ride. Old skating momentum must never survive a
		# direction change and reappear when a new pair of blades is extended.
		velocity.x=0.0
		velocity.z=0.0
		_ice_skate_stride_phase=0.0
		_ice_skate_previous_speed=0.0
		_ice_skate_smoothed_acceleration=0.0
		_ice_skate_airborne=false
		_ice_skate_was_supported=false
		_ice_skate_surface_velocity=Vector3.ZERO
	_set_ice_skate_visuals_present()


func _set_ice_skate_visuals_present() -> void:
	if _ice_skates_active:
		if not is_instance_valid(_ice_skate_left):
			_ice_skate_left=build_ice_skate_blade(_toe_left,"LeftIceSkate")
		if not is_instance_valid(_ice_skate_right):
			_ice_skate_right=build_ice_skate_blade(_toe_right,"RightIceSkate")
		return
	if is_instance_valid(_ice_skate_left):
		_ice_skate_left.queue_free()
	if is_instance_valid(_ice_skate_right):
		_ice_skate_right.queue_free()
	_ice_skate_left=null
	_ice_skate_right=null


## A narrow continuous runner with two short mounts. The toe marker carries
## every ankle/foot motion, but the attachment depth comes from the worn
## blorb boot surrounding that hidden human shoe. Its mounts therefore begin
## at the visible blorb underside, with the runner below that surface.
static func build_ice_skate_blade(
	toe: Node3D,blade_name: String,scale_factor: float=1.0,sole_offset: float=-1.0
) -> Node3D:
	var root:=Node3D.new()
	root.name=blade_name
	toe.add_child(root)
	var resolved_sole_offset: float=(
		BlorbSuit.worn_boot_sole_depth(scale_factor)
		if sole_offset<0.0 else sole_offset
	)
	var sole_y: float=-resolved_sole_offset
	var support_height: float=ICE_SKATE_SUPPORT_HEIGHT*scale_factor
	var runner_half_height: float=ICE_SKATE_RUNNER_HALF_HEIGHT*scale_factor
	var runner_y: float=sole_y-support_height-runner_half_height
	var runner:=SuperEgg.build_part(
		Vector3(
			ICE_SKATE_RUNNER_HALF_WIDTH*scale_factor,runner_half_height,
			ICE_SKATE_RUNNER_HALF_LENGTH*scale_factor
		),
		ICE_SKATE_COLOR,4.8,4.8
	)
	runner.position=Vector3(0.0,runner_y,-ProceduralFigure.FOOT_SIZE.z*scale_factor)
	root.add_child(runner)
	for unscaled_z: float in [-0.055,-0.205]:
		var mount:=SuperEgg.build_part(
			Vector3(0.032*scale_factor,support_height*0.5,0.028*scale_factor),
			ICE_SKATE_COLOR,3.8,3.8
		)
		mount.position=Vector3(0.0,sole_y-support_height*0.5,unscaled_z*scale_factor)
		root.add_child(mount)
	return root


static func ice_skate_visual_lift(scale_factor: float=1.0) -> float:
	var human_sole_depth: float=(ProceduralFigure.FOOT_SIZE.y+ProceduralFigure.JOINT_OVERLAP*0.5)*scale_factor
	var blorb_sole_depth: float=BlorbSuit.worn_boot_sole_depth(scale_factor)
	return ICE_SKATE_TOTAL_HEIGHT*scale_factor+maxf(blorb_sole_depth-human_sole_depth,0.0)


## The snowboard rides literal snow terrain only (per direct instruction):
## ice, grass, dirt and every other surface give it nothing to glide on.
func _is_snowboard_surface() -> bool:
	if terrain==null:
		return false
	var xz:=Vector2(global_position.x,global_position.z)
	if terrain.has_method("is_ice_surface") and terrain.is_ice_surface(xz):
		return false
	return (
		terrain.has_method("is_snow_footstep_surface")
		and terrain.is_snow_footstep_surface(xz)
		and _is_aligned_with_terrain()
	)


func _build_snowboard() -> Node3D:
	var root:=Node3D.new()
	root.name="Snowboard"
	visuals.add_child(root)
	# One continuous manifold deck. Rounded SuperEgg ends give it a soft
	# nose/tail without the visible seams of separately attached tip pieces.
	var deck:=SuperEgg.build_part(
		Vector3(SNOWBOARD_LENGTH*0.5,SNOWBOARD_THICKNESS,SNOWBOARD_WIDTH),
		SNOWBOARD_COLOR,3.2,3.2
	)
	deck.name="ContinuousDeck"
	root.add_child(deck)
	return root


func _update_snowboard_visual() -> void:
	if _snowboard==null or not is_instance_valid(_ankle_left) or not is_instance_valid(_ankle_right):
		return
	var planar:=Vector3(velocity.x,0.0,velocity.z)
	if planar.length_squared()>0.01:
		_snowboard_last_heading=planar.normalized()
	var supported:=_is_snowboard_surface()
	var up:=_snowboard_smoothed_up
	var forward:=_snowboard_last_heading.normalized()
	# Once airborne, the deck follows the actual ballistic trajectory. Gravity
	# changes velocity continuously, so its pitch naturally arcs down without
	# a terrain-normal snap at the lip or while landing.
	if not supported and velocity.length_squared()>0.01:
		forward=velocity.normalized()
	forward=(forward-up*forward.dot(up)).normalized() if supported else forward
	if forward.length_squared()<0.001:
		forward=Vector3.FORWARD
	var across:=forward.cross(up).normalized()
	if across.length_squared()<0.001:
		across=forward.cross(Vector3.UP if absf(forward.dot(Vector3.UP))<0.95 else Vector3.RIGHT).normalized()
	up=across.cross(forward).normalized()
	_snowboard.global_transform.basis=Basis(forward,up,across)
	var ankle_mid:=(_ankle_left.global_position+_ankle_right.global_position)*0.5
	_snowboard.global_position=ankle_mid-up*0.12


func _face_snowboard_heading(delta: float) -> void:
	if not _snowboard_active:
		return
	var planar:=Vector3(velocity.x,0.0,velocity.z)
	if planar.length_squared()<=0.01:
		return
	_snowboard_last_heading=planar.normalized()
	var target_yaw:=atan2(_snowboard_last_heading.x,_snowboard_last_heading.z)+SNOWBOARD_BODY_SIDE_ANGLE
	_body_yaw=lerp_angle(_body_yaw,target_yaw,rotation_speed*delta)


## The board and rider deliberately have separate pitch owners. Nose and tail
## contacts establish the full deck grade; ankles/knees absorb the first part
## of that grade, and only the excess beyond their stance tolerance pitches
## the complete body. This is the same physical idea as a bike whose free end
## continues rotating around its supported contact, without making a rider
## rigidly copy every small terrain facet.
## Called only by _compose_body_pose(), after the ground pose: tilts the
## already-placed body to the slope while keeping the feet where they were.
func _apply_snowboard_surface_orientation(delta: float,grounded: bool) -> void:
	if not _snowboard_active:
		return
	var supported:=grounded and _is_snowboard_surface()
	if supported:
		var target_up:=_snowboard_surface_up()
		var speed_ratio:=clampf(Vector2(velocity.x,velocity.z).length()/SNOWBOARD_TERMINAL_SPEED,0.0,1.0)
		var response:=lerpf(SNOWBOARD_PITCH_RESPONSE_SLOW,SNOWBOARD_PITCH_RESPONSE_FAST,speed_ratio)
		var damping:=1.0-exp(-response*delta)
		_snowboard_smoothed_up=_snowboard_smoothed_up.slerp(target_up,damping).normalized()
	var planar_forward:=Vector3(_snowboard_last_heading.x,0.0,_snowboard_last_heading.z)
	if planar_forward.length_squared()<0.001:
		return
	planar_forward=planar_forward.normalized()
	var deck_forward:=planar_forward-_snowboard_smoothed_up*planar_forward.dot(_snowboard_smoothed_up)
	if deck_forward.length_squared()<0.001:
		deck_forward=planar_forward
	deck_forward=deck_forward.normalized()
	var deck_grade:=asin(clampf(deck_forward.y,-1.0,1.0))
	var rider_grade:=signf(deck_grade)*maxf(absf(deck_grade)-SNOWBOARD_RIDER_PITCH_THRESHOLD,0.0)
	if not supported and velocity.length_squared()>0.01:
		# Once launched, retain the attitude reached at the lip. Ballistic
		# velocity owns the deck arc; it must not instantly fold the rider.
		rider_grade=_snowboard_smoothed_rider_grade
	var rider_damping:=1.0-exp(-SNOWBOARD_RIDER_PITCH_RESPONSE*delta)
	_snowboard_smoothed_rider_grade=lerp_angle(
		_snowboard_smoothed_rider_grade,rider_grade,rider_damping
	)
	var local_x:=Vector3(
		planar_forward.x*cos(_snowboard_smoothed_rider_grade),
		sin(_snowboard_smoothed_rider_grade),
		planar_forward.z*cos(_snowboard_smoothed_rider_grade)
	).normalized()
	var local_z:=local_x.cross(Vector3.UP).normalized()
	if local_z.length_squared()<0.001:
		return
	var up:=local_z.cross(local_x).normalized()
	var target_basis:=Basis(local_x,up,local_z).orthonormalized()
	var foot_anchor:=(_ankle_left.global_position+_ankle_right.global_position)*0.5
	var transform:=visuals.global_transform
	transform.basis=Basis(transform.basis.get_rotation_quaternion().slerp(
		target_basis.get_rotation_quaternion(),minf(SNOWBOARD_POSE_SETTLE_SPEED*delta,1.0)
	))
	visuals.global_transform=transform
	var posed_foot_anchor:=(_ankle_left.global_position+_ankle_right.global_position)*0.5
	visuals.global_position+=foot_anchor-posed_foot_anchor


## Measure the grade beneath the nose and tail rather than copying a single
## terrain triangle's complete normal. This filters small facets and produces
## the pitch a long board actually spans, while deliberately leaving the
## neutral stance flat across its toe/heel axis; edging belongs to a future
## intentional carve pose, not incidental cross-slope terrain noise.
func _snowboard_surface_up() -> Vector3:
	if terrain==null or not terrain.has_method("get_mesh_height") or _is_supported_by_ice():
		return Vector3.UP
	var heading:=Vector2(_snowboard_last_heading.x,_snowboard_last_heading.z).normalized()
	if heading.length_squared()<0.001:
		heading=Vector2(0.0,1.0)
	var offset:=heading*SNOWBOARD_NORMAL_SAMPLE_DISTANCE
	var nose_height: float=terrain.get_mesh_height(global_position.x+offset.x,global_position.z+offset.y)
	var tail_height: float=terrain.get_mesh_height(global_position.x-offset.x,global_position.z-offset.y)
	var longitudinal:=Vector3(offset.x*2.0,nose_height-tail_height,offset.y*2.0).normalized()
	var across:=longitudinal.cross(Vector3.UP).normalized()
	if across.length_squared()<0.001:
		return Vector3.UP
	var up:=across.cross(longitudinal).normalized()
	return up if up.y>=0.0 else -up


## A solid disk, not a torus -- see DIRTBIKE_WHEEL_RADIUS's own comment for
## why (a torus this file built by hand had its normals flipped; a plain
## SuperEgg part sidesteps that bug entirely by reusing the same builder
## every other prop in the project already trusts).
func _build_dirtbike_wheel() -> MeshInstance3D:
	var semi_axes := Vector3(DIRTBIKE_WHEEL_RADIUS, DIRTBIKE_WHEEL_THICKNESS * 0.5, DIRTBIKE_WHEEL_RADIUS)
	var wheel := SuperEgg.build_part(semi_axes, DIRTBIKE_WHEEL_COLOR, 2.0, 2.0)
	wheel.name = "DirtbikeWheel"
	visuals.add_child(wheel)
	return wheel


## Positions/orients a dirtbike wheel prop so its axle sits exactly at the
## midpoint of `pivot_a`/`pivot_b` (the two ankles for the rear wheel, the
## two wrists for the front -- per direct correction, "the feet axis should
## be at the ankles"/"the arm axis should be at the wrists") -- no terrain
## sampling at all, deliberately: per direct correction ("the wheels must
## stay with the player's body when airborne, not snap to the ground"), a
## terrain-height-derived position (this function's own first draft) kept
## pinning the wheel to the ground even mid-launch, which is exactly wrong
## once the wheel leaves the ground. Reading the pivot's own live position
## instead means the wheel simply goes wherever the rig already is, grounded
## or airborne, with zero extra logic needed for either case. The visible
## "rests on the ground" result for the REAR wheel instead comes from
## the dirtbike lift in _body_base_height() (see DIRTBIKE_WHEEL_
## RADIUS's own comment): once the ankles sit one radius above the ordinary
## foot height, an axle centered exactly on them puts the wheel's own rim
## right back at that ordinary ground contact point. The mesh's own build
## (a SuperEgg oblate spheroid, X/Z semi-axes equal) is fully rotationally
## symmetric about its own local Y, so any orthonormal basis with column
## Y = axle_dir renders identically -- no winding/sign ambiguity to flag
## here the way a non-symmetric bent-pipe shape would need.
func _position_dirtbike_wheel(wheel: MeshInstance3D, pivot_a: Node3D, pivot_b: Node3D, delta: float) -> void:
	if not is_instance_valid(pivot_a) or not is_instance_valid(pivot_b):
		return
	var a := pivot_a.global_position
	var b := pivot_b.global_position
	var mid := (a + b) * 0.5
	var axle_dir := (b - a)
	axle_dir = axle_dir.normalized() if axle_dir.length() > 0.001 else global_transform.basis.x
	var seed := Vector3.FORWARD if absf(axle_dir.dot(Vector3.FORWARD)) < 0.9 else Vector3.UP
	var x_axis := seed.cross(axle_dir).normalized()
	var z_axis := axle_dir.cross(x_axis).normalized()
	wheel.global_position = mid
	wheel.global_transform.basis = Basis(x_axis, axle_dir, z_axis)
	# Rolls the wheel visually as the character actually moves, rather than
	# a spin rate tied to an animation phase -- ground speed is exactly
	# "how far the tire's own circumference has to have rolled" regardless
	# of which movement mode produced it.
	var roll_speed := Vector2(velocity.x, velocity.z).length() / maxf(DIRTBIKE_WHEEL_RADIUS, 0.01)
	wheel.rotate_object_local(Vector3.UP, roll_speed * delta)


## Called last in _physics_process (see that function's own final lines),
## after every pose/pitch/visuals-lift pass this frame has already run --
## see _position_dirtbike_wheel()'s own comment for why the timing matters.
func _update_dirtbike_wheels(delta: float) -> void:
	if _dirtbike_rear_wheel != null:
		_position_dirtbike_wheel(_dirtbike_rear_wheel, _ankle_left, _ankle_right, delta)
	if _dirtbike_front_wheel != null:
		_position_dirtbike_wheel(_dirtbike_front_wheel, _wrist_left, _wrist_right, delta)


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
		_body_yaw = wrapf(_body_yaw + yaw_delta, -PI, PI)
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
const LANDING_HEIGHT_THRESHOLD := 0.10


func _is_near_ground() -> bool:
	var h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	var threshold := LANDING_HEIGHT_THRESHOLD
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


func _is_aligned_with_terrain() -> bool:
	var height: float = terrain.get_mesh_height(global_position.x,global_position.z)
	return absf((global_position.y-FOOT_OFFSET)-height) <= STEP_CORRECT_MAX_DRIFT


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
	# Dirt blorb suit's rear wheel skips the slope gate entirely here -- this
	# whole function only ever handles a RISE (see the guard just above), so
	# there is no separate ascending/descending split to make the way
	# _snap_to_terrain() below needs one. See DIRTBIKE_FLOOR_MAX_ANGLE's own
	# comment for the other half of "no constraints traveling up."
	if rise / STEP_LOOKAHEAD > GROUND_SNAP_MAX_SLOPE and not _dirtbike_wheel_active:
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
func _try_step_onto_prop(delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if horizontal.length() < 0.1:
		return
	var move_dir := horizontal.normalized()
	var foot_y := global_position.y - FOOT_OFFSET
	# A wheel discovers a ledge with its leading arc rather than waiting for
	# the humanoid capsule to touch the wall. It can negotiate a vertical rise
	# somewhat below its diameter; taller faces remain genuine obstacles.
	var probe_distance: float = (
		maxf(STEP_LOOKAHEAD,DIRTBIKE_WHEEL_RADIUS*1.35)
		if _dirtbike_wheel_active else STEP_LOOKAHEAD
	)
	var max_step_height: float = (
		DIRTBIKE_WHEEL_RADIUS*1.85
		if _dirtbike_wheel_active else PROP_STEP_MAX_HEIGHT
	)
	var probe := global_position + move_dir * probe_distance

	var space_state := get_world_3d().direct_space_state
	var from := Vector3(probe.x, foot_y + max_step_height + PROP_STEP_PROBE_CLEARANCE, probe.z)
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
	if rise <= 0.02 or rise > max_step_height:
		return
	if _dirtbike_wheel_active:
		# Resolve the rise progressively from actual wheel travel. This gives a
		# rounded roll-up instead of the ordinary humanoid's one-frame step snap,
		# while pre-lifting enough for move_and_slide() to clear the slab face.
		var climb_step: float = maxf(horizontal.length()*delta*1.4,0.055)
		global_position.y += minf(rise,climb_step)
	else:
		global_position.y += rise
	velocity.y = 0.0


func _snap_to_terrain(delta: float,pre_move_position: Vector3) -> void:
	if not _is_touching_terrain():
		return
	var target_h: float = terrain.get_mesh_height(global_position.x, global_position.z)
	var rise: float = target_h - (global_position.y - FOOT_OFFSET)
	var run := maxf(Vector2(velocity.x, velocity.z).length() * delta, 0.001)

	if _dirtbike_wheel_active or _snowboard_active:
		var horizontal_velocity := Vector2(velocity.x,velocity.z)
		var travel_slope: float = _dirtbike_slope_along(horizontal_velocity)
		# Resolve onto support, then measure the complete motion that actually
		# occurred this frame. In particular, Y is real delta-position/delta-time.
		if travel_slope > DIRTBIKE_ASCEND_TRACK_THRESHOLD:
			_dirtbike_was_climbing = true
			global_position.y = target_h + FOOT_OFFSET
			_dirtbike_surface_velocity = HumanoidLocomotion.resolved_velocity(
				pre_move_position,global_position,delta
			)
			velocity.y = _dirtbike_surface_velocity.y
			return
		# Once the support slope falls away, preserve both the horizontal
		# velocity and the full vertical tangent velocity. Marking this as a
		# genuine jump arc also prevents ground grace from re-snapping the body
		# during the first airborne frames.
		if _dirtbike_was_climbing:
			_dirtbike_was_climbing = false
			velocity = _dirtbike_surface_velocity
			velocity.y *= sqrt(DIRTBIKE_JUMP_HEIGHT_MULTIPLIER)
			_jump_takeoff_speed = absf(velocity.y)
			_jumping = true
			return
		_dirtbike_was_climbing = false
		# Level or rising support that is not a tracked climb remains attached.
		if rise >= 0.0:
			global_position.y = target_h + FOOT_OFFSET
			velocity.y = 0.0
			return
		# Per direct correction ("even when cresting smaller hills at speed
		# he should still get airtime according to the laws of physics --
		# his downward translation should never exceed the speed his body
		# would be falling from gravity") -- every frame from here on is a
		# REAL gravity-integrated fall, compared directly against the actual
		# terrain height, rather than a fixed slope-ratio threshold or a
		# one-shot hang-time timer (both tried and replaced). A slope gentle
		# enough for gravity's own fall rate to keep pace with reads as
		# smoothly hugging the downhill, since the predicted fall lands AT
		# or past the terrain almost every frame; a drop steeper than
		# gravity can match falls behind it, producing real air that scales
		# with exactly how much the terrain outpaces gravity -- which
		# naturally scales to any hill size, small or large, with no
		# separate constant to tune for either case.
		velocity.y = HumanoidLocomotion.apply_gravity(velocity.y, delta, _playable_profile, TERMINAL_FALL_SPEED)
		var predicted_h := (global_position.y - FOOT_OFFSET) + velocity.y * delta
		if predicted_h > target_h:
			global_position.y = predicted_h + FOOT_OFFSET
			return
		global_position.y = target_h + FOOT_OFFSET
		velocity.y = 0.0
		return

	if absf(rise) / run > GROUND_SNAP_MAX_SLOPE:
		return
	global_position.y = target_h + FOOT_OFFSET
	velocity.y = 0.0


## A cloud/canopy catch is a real landing even though these intentionally
## one-way analytic surfaces have no physics collider to set is_on_floor().
## Keep every bit of landing state transition in one place so no caller can
## anchor the body while accidentally leaving it in a permanent jump state.
func _complete_one_way_support_landing(root_height: float) -> void:
	global_position.y = root_height
	velocity.y = 0.0
	_jumping = false
	_giant_surface_jump_in_progress = false


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


func rotate_camera_from_touch(yaw_delta: float, pitch_delta: float) -> void:
	if UIState.modal_open:
		return
	_rotate_camera(yaw_delta, pitch_delta)
