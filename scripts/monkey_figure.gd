class_name MonkeyFigure
extends RefCounted

## First-draft procedural rig for Xiao Hou Zi, the jungle biome's resident
## monkey (see docs/world_bible.md) -- 20cm tall, built per exact spec:
## SuperEgg head/ears (reusing figure_ears.gd directly, since it's already
## generic off head semi_axes), eyes bigger/closer-together than the human
## figure's own subtle oval marks (more like the blorb suit's own round
## "goggle" eyes, per direct instruction), no mouth, no neck (head sits
## straight on the body), a pear-shaped body that is deliberately NOT a
## SuperEgg, invisible bone-pivot arms/legs whose only visible trace is a
## blorb-suit-noodle-style tube mesh (see blorb_suit.gd's build_limb_tube())
## with no separate hand/foot segment, and a tail.
##
## Explicitly a first draft, per direct instruction -- proportions below are
## reasoned out to hit the 20cm total height target and read as a plausible
## small-monkey silhouette, but none of this has been seen in-engine yet
## (no Godot CLI/editor available while writing this -- see the figure-rig
## skill's own guidance on flagging unverified guesses rather than
## presenting them as settled).
##
## build()'s return dict deliberately mirrors procedural_figure.gd's own
## build() key-for-key (spine/head/eyes/hips/arm_left/arm_right/elbow_left/
## elbow_right/leg_left/leg_right/knee_left/knee_right/ankle_left/
## ankle_right/toe_left/toe_right/hand_left/hand_right/palm_left/palm_right/
## back_left/back_right/wrist_left/wrist_right/fingertip_left/
## fingertip_right) so player.gd's existing movement/camera/walk-cycle/
## blorb-suit code can drive this rig completely unmodified (see player.gd's
## own TEMP_PLAY_AS_XIAO_HOU_ZI flag) -- this rig just doesn't build a
## separate mesh for the hand/foot-equivalent nodes, only a plain Node3D
## marker, since the spec calls for no hand/foot segments. Since none of
## those markers have a real hand/foot mesh to derive a palm/back-of-hand
## facing from, palm_X/back_X/wrist_X/fingertip_X (and ankle_X/toe_X) are
## the SAME node reused under multiple keys rather than fabricated separate
## anatomy -- a deliberate simplification, not an oversight.

const MONKEY_FUR_COLOR := Color(0.62, 0.46, 0.30)  # light brown, per spec

# Ground-up stack (mirrors procedural_figure.gd's own ankle_y/knee_y/hip_y
# derivation), sized to land the top of the head at ~0.20m total height.
const ANKLE_GROUND_CLEARANCE := 0.005  # no foot mesh to provide this lift, so a small fixed clearance stands in for it
const LEG_LOWER_LEN := 0.0225
const LEG_UPPER_LEN := 0.0225
# Set the legs broadly beneath the pear body's lower left/right flanks. At
# 78% of BODY_RADIUS the hip nodes read as two distinct attachments across
# its wide base instead of a close-set pair emerging near the center pole.
const HIP_X := 0.035  # approximately 78% of BODY_RADIUS
# Lift the joint into the body's broad lower bulge. _build_leg adds this
# same amount to its upper span, keeping the ankle exactly on the ground.
const HIP_ATTACH_RAISE := 0.018

const BODY_RADIUS := 0.045
## Full height of the pear body, bottom pole to top pole -- built from
## BlorbBodyShape (the SAME lathe silhouette blorb.gd's own body and the
## blorb suit's hat already use), NOT SuperEgg, per direct instruction. Its
## wide-rounded-bottom-tapering-to-a-narrower-rounded-top profile already
## reads as pear-shaped without needing a bespoke profile function.
const BODY_HEIGHT := 0.09

# Twenty percent larger on every axis than the previous near-sphere, with
# a further modest width increase on X so the face reads slightly broad.
const HEAD_SIZE := Vector3(0.038, 0.036, 0.0348)
const HEAD_EPSILON := 2.05  # 2.0 is a perfect ellipsoid; only barely superelliptical
## How far the head sinks down into the body's own narrow top, per the same
## "bury the pinch in an overlap" reasoning procedural_figure.gd's joints
## use, in place of a neck segment.
const HEAD_EMBED := 0.015

## The extra display-size multiplier applied when this rig is actually
## instantiated in the world -- xiao_hou_zi.gd's own DISPLAY_SCALE and
## player.gd's own TEMP_MONKEY_SCALE are both currently 2.3585 and get
## passed in as build()'s own `scale` argument (see build()'s call sites in
## those two files), stretching the raw ~20cm-tall rig the consts above
## describe up to a more visible/practical party-member size. Duplicated
## here rather than read from either of those files because xiao_hou_zi.gd
## already depends on MonkeyFigure (calls MonkeyFigure.build()) -- a reverse
## reference back out of this file would be a dependency cycle.
## BLORB_SUIT_RIG_SCALE below needs it to compare this rig's actual
## DISPLAYED size against ProceduralFigure's own build (which is never
## display-scaled -- the player character's meters ARE its world size).
const REFERENCE_BUILD_SCALE := 2.3585

## This rig's own standing height (ground to head crown) at raw, unscaled
## build() dimensions -- mirrors build()'s own ankle_y/knee_y/hip_y stacking
## plus the head_pivot/head_mesh placement below it, just expressed as a
## compile-time const instead of a local var so BLORB_SUIT_RIG_SCALE can be
## derived from it directly.
const _STANDING_HEIGHT_RAW := (
	ANKLE_GROUND_CLEARANCE + LEG_LOWER_LEN + LEG_UPPER_LEN
	+ BODY_HEIGHT - HEAD_EMBED + HEAD_SIZE.y * 2.0
)

## ProceduralFigure's own standing height (ground to head crown) at its
## default build() proportions -- chest_build_scale/hip_build_scale/
## abdomen_width_scale all 1.0, the only case that matters here since those
## three knobs only ever widen hip_size/abdomen_size/chest_size on X/Z, never
## touch their Y (see that file's own build()), so each *_SIZE const's own Y
## component is already exactly what a default-proportioned build produces.
## Mirrors that build()'s own ankle_y/knee_y/hip_y/abdomen_y/chest_y/neck_y/
## total_height stacking as a compile-time const.
const _HUMAN_STANDING_HEIGHT := (
	ProceduralFigure.FOOT_SIZE.y * 2.0 + ProceduralFigure.LOWER_LEG_SIZE.y * 2.0
	+ ProceduralFigure.UPPER_LEG_SIZE.y * 2.0 + ProceduralFigure.HIP_SIZE.y * 2.0
	+ ProceduralFigure.ABDOMEN_SIZE.y * 2.0 + ProceduralFigure.CHEST_SIZE.y * 2.0
	+ ProceduralFigure.HEAD_SIZE.y * 2.0 + ProceduralFigure.HEAD_RAISE
)

## How much smaller every blorb-suit-piece dimension (see blorb_suit.gd's
## own `rig_scale` parameter, threaded through every ProceduralFigure-
## derived radius/offset in that file) needs to be to fit snugly onto this
## rig's own much smaller frame -- derived by comparing this rig's actual
## DISPLAYED standing height (its raw height above, times
## REFERENCE_BUILD_SCALE, matching how it's actually instantiated in-game)
## against ProceduralFigure's own undisplayed (build-time meters, scale 1.0)
## standing height. A principled ratio of the two rigs' own real proportions
## rather than an eyeballed single-limb guess, per direct instruction that
## the suit should "scale down proportionally to his frame... to the size of
## his limbs." Joint POSITIONS never need this factor -- blorb_suit.gd
## already builds every piece from this rig's own live, correctly-
## proportioned pivots -- only each piece's own THICKNESS and the small flat
## cm-offsets (hand bulges, hat droop, etc.) that were otherwise sized for
## the much bigger human rig those formulas are natively written in terms
## of. Passed through BlorbSuitController.setup() by player.gd; see that
## file's own _piloting_xiao_hou_zi section for where.
const BLORB_SUIT_RIG_SCALE := (_STANDING_HEIGHT_RAW * REFERENCE_BUILD_SCALE) / _HUMAN_STANDING_HEIGHT

const EYE_RADIUS_FACTOR := 0.34 * 0.30  # reduced 70%, retaining 30% of the previous circular eye size
const EYE_OFFSET := deg_to_rad(17.5)  # 75% wider than the previous 10-degree spacing
const EYE_FLATTEN := 0.55  # rounder/bulgier than figure_eyes.gd's near-flat 0.1 -- reads more like a blorb's own eye than a painted mark
## Extra clearance beyond the face-marking mask's own raised surface (see
## _face_marking_relief_at) an eye's front face is pushed out to, so it
## reads as sitting proud on top of the mask's crown bump instead of just
## barely poking clear of it.
const EYE_MASK_CLEARANCE_MARGIN := 0.0004
const EYE_COLOR := Color(0.12, 0.08, 0.05)
const MARKING_COLOR := Color(0.91, 0.79, 0.58)
const NOSE_COLOR := Color(0.10, 0.075, 0.055)
const CHEEK_DOT_COLOR := Color(1.0, 0.82, 0.18)
## A real-world-primate-plausible spread of face/mask ("skin") tones --
## sandy, pink, ruddy, deep brown, near-black, grey -- for any caller that
## wants random marking_color variety instead of always MARKING_COLOR's own
## single sandy default. Per direct correction: picking between just that
## one default and one dark alternative read as "almost exactly the same"
## across a batch of NPCs, both for the ape template's own debug spawn
## (main.gd) and jungle_villager.gd's monkey NPCs -- centralized here
## rather than duplicated in both so the two stay in sync.
const MARKING_COLOR_PALETTE := [
	MARKING_COLOR,
	Color(0.86, 0.70, 0.66),
	Color(0.68, 0.42, 0.30),
	Color(0.55, 0.38, 0.28),
	Color(0.35, 0.24, 0.20),
	Color(0.58, 0.52, 0.48),
	Color(0.12, 0.10, 0.09),
]

const SHOULDER_Y_LOCAL := BODY_HEIGHT * 0.72  # relative to spine_pivot (= hip_y in absolute terms) -- raised from 0.65 per direct correction that the arms/shoulders should start higher up the body
# Slightly inset into the body's surface so the narrow tube cap remains
# buried and reads as a snug shoulder attachment rather than a pinched gap.
const SHOULDER_X := BODY_RADIUS * 0.78
const UPPER_ARM_LEN := 0.035
const FOREARM_LEN := 0.035
## Separate the upper arms from the torso at the shoulders; the elbow bend
## keeps the resulting pose relaxed rather than forming rigid straight arms.
const ARM_OUTWARD_ANGLE := deg_to_rad(15.0)
const DEFAULT_ELBOW_BEND := deg_to_rad(25.0)

# Strong continuous flare from a fine shoulder root into the broad lower
# noodle, with no intermediate narrowing.
const ARM_RADIUS_SHOULDER := 0.0055
const ARM_RADIUS_ELBOW := 0.009
const ARM_RADIUS_WRIST := 0.0135
# The leg widens continuously from its top into the foot bulb. Keeping each
# successive control radius larger prevents a sudden bell at the ankle.
const LEG_RADIUS_HIP := 0.013
const LEG_RADIUS_KNEE := 0.016
const FOOT_BULB_RADIUS := 0.022
const FOOT_BULB_FORWARD := 0.010
const FOOT_BULB_CENTER_Y := 0.020
const FOOT_BOTTOM_RADIUS := 0.013

# Match the blorb suit's noodle tessellation and rounded end treatment so
# Xiao Hou Zi's limbs share that same smooth, continuous general silhouette.
const LIMB_RADIAL_SEGMENTS := BlorbSuit.LIMB_RADIAL_SEGMENTS
const LIMB_RINGS_PER_SEGMENT := BlorbSuit.RINGS_PER_SEGMENT
## Deliberately NOT hidden inside the body the way the tail's own base point
## is (see _build_tail) -- per direct instruction the shoulder is allowed a
## visible pinch where a limb meets the torso (procedural_figure.gd's own
## _build_arm has the identical exception, "the resulting pinch there is
## fine"), so the tube's own end-taper landing right at the shoulder/hip
## pivot is accepted here too rather than adding embed math for a first
## draft.
const LIMB_CAP_FRACTION := BlorbSuit.TUBE_CAP_FRACTION

## Tail: a short tube curving up and back from low on the body's back, per
## spec. Points/radii are expressed directly in spine_pivot's own local
## space (spine_pivot's origin already sits at absolute hip_y, so these
## don't need a separate offset the way the limb tubes -- built from LIVE
## global positions every frame -- do). p0 is embedded INTO the belly
## (past its actual surface) so the base end lands hidden inside the body
## mesh instead of leaving a visible gap where a free-hanging appendage
## meets the torso -- the tail has no joint chain to justify a pinch the
## way a limb does, so it gets the embed treatment the tail deserves
## instead.
##
## Per direct correction, this is now a constant-radius pipe with a
## rounded cap at the tip, NOT a tapered whip -- see _build_tail's own
## comments for why TAIL_CAP_FRACTION is 0.0 (switching off
## blorb_suit.gd's shared _cap_taper end-shrink entirely) and why the cap
## is now a few extra points folded into the SAME loft rather than a
## separate primitive glued on afterward. A first pass used a separate
## SuperEgg sphere positioned at the tip; even sized to match TAIL_RADIUS
## exactly, per direct report it still read as "a weird ball" -- two
## independently-built meshes meeting at a seam get independent vertex
## normals on each side of that seam, so shading (even fully matte
## shading, not just specular) can still snap abruptly right at the
## boundary in a way a single continuous surface never would. Extending
## the SAME tube mesh with a few more Catmull-Rom points that taper its
## radius down to zero following a quarter-circle profile keeps every
## vertex on one continuous surface with continuous normals straight
## through the cap, so there's no seam left to read as a stuck-on shape.
const TAIL_BASE_Y := BODY_HEIGHT * 0.25
const TAIL_CAP_FRACTION := 0.0
const TAIL_FLATTEN_X := 0.65
const TAIL_RADIUS := 0.007
## How many extra loft points approximate the tip's rounded dome -- more
## steps means a smoother quarter-circle radius profile (each step is
## still linearly interpolated both in position and radius between its
## neighbors, so too few would facet the dome into visible flats).
const TAIL_DOME_STEPS := 4
## Optional tip marking (see _build_tail()'s own `tip_marking_color` param,
## added for Yogi -- docs/world_bible.md's own Creatures/Cats entry): how
## many alternating marking/fur colinear sub-segments the final real tail
## segment gets divided into, purely for coloring (same "insert a colinear
## point, which doesn't bend a Catmull-Rom curve" trick _rebuild_leg_tube()
## already uses in horse_figure.gd for its own sock cut). Odd count so the
## pattern starts AND ends on a marking band -- the last one flows straight
## into the fully-marking-colored dome cap appended after it, reading as "a
## few rings... with that color as the cap of the tail."
const TAIL_TIP_RING_BANDS := 5

## Idle tail life: droop/perk/sway is a rigid bend applied on top of the
## rest-pose points above, weighted by TAIL_BEND_EXPONENT so the base (the
## point embedded in the belly) never moves while the tip swings the most
## -- see _rebuild_tail()'s own comment for the full scheme. Pitch (droop/
## perk) and yaw (side sway) each retarget on their own independently
## randomized timer, so the two never fall into a repeating lockstep cycle.
const TAIL_DROOP_ANGLE := deg_to_rad(38.0)
const TAIL_PERK_ANGLE := deg_to_rad(24.0)
const TAIL_SWAY_YAW_RANGE := deg_to_rad(16.0)
const TAIL_BEND_EXPONENT := 1.6
## Exponential-smoothing rate current values ease toward their retargeted
## value at -- higher settles faster. Using this (rather than a flat lerp
## fraction) keeps the ease rate the same regardless of frame rate.
const TAIL_ANIM_EASE_RATE := 1.4
const TAIL_ANIM_PITCH_HOLD_MIN := 1.0
const TAIL_ANIM_PITCH_HOLD_MAX := 3.2
const TAIL_ANIM_YAW_HOLD_MIN := 1.4
const TAIL_ANIM_YAW_HOLD_MAX := 3.8


## variant lets other primate species reuse this same rig with different
## proportions/markings instead of forking the whole builder -- see
## jungle_villager.gd, whose whole design brief ("based on Xiao Hou Zi, but
## ...") is expressed entirely as these keys. Every key defaults to exactly
## Xiao Hou Zi's own current look, so existing callers that don't pass a
## variant (this file's own doc comment on _build_leg()/_build_arm() below
## still assumes his proportions unless told otherwise) are unaffected:
## - "has_cheek_dots": bool, the yellow muzzle dots (see _add_muzzle_features())
## - "has_face_marking": bool, the heart-shaped facial field (see _add_face_marking())
## - "face_marking_notch_strength": float, how deep the heart's center
##   "widow's peak" dip cuts between its two crown lobes -- 1.0 is Xiao Hou
##   Zi's own original depth, lower softens it toward a rounder top
## - "hip_scale": float, multiplies HIP_X (leg spacing)
## - "limb_length_scale": float, multiplies every limb segment length
## - "limb_taper_scale": float 0..1, how much the arm/leg widens toward the
##   hand/foot -- 1.0 reproduces Xiao Hou Zi's own full flare, 0.0 keeps the
##   limb the same radius as its elbow/knee all the way to the tip
## - "has_foot_pads": bool, whether the foot's underside gets a distinct
##   sole-colored patch or just continues as ordinary fur
## - "body_taper_blend": float 0..1, how much the torso narrows from hips to
##   shoulders -- 1.0 is Xiao Hou Zi's own full pear-shaped taper, lower
##   values keep the upper body closer to full width (see
##   BlorbBodyShape.profile_radius()'s own doc comment)
## - "tail_length_scale": float, multiplies how far the tail reaches from
##   its base at the body
## - "body_height_scale": float, multiplies the torso's own height (and
##   with it, where the shoulders/head/tail-base sit up the body)
## - "spine_forward_bend": float (radians), a static forward stoop at the
##   waist -- 0.0 is Xiao Hou Zi's own fully upright posture
## - "body_radius_scale": float, multiplies the torso's own width (and with
##   it, the shoulder attachment's outward offset and the tail's anchor)
## - "shoulder_height_fraction": float, how far up the (possibly elongated)
##   body_height the shoulders sit -- 0.72 is Xiao Hou Zi's own value
## - "hip_attach_raise_fraction": float, how far up the (possibly elongated)
##   body_height the leg's own top tucks into the body -- 0.2 reproduces
##   Xiao Hou Zi's own current HIP_ATTACH_RAISE exactly; higher values seat
##   the leg deeper into the body's hip bulge (see _build_leg()'s own doc
##   comment) instead of near the body's narrow bottom point, which also
##   lengthens the visible leg tube since the ankle/knee stay put
## - "leg_radius_scale": float, multiplies every leg radius uniformly (hip
##   through the foot bulb) -- separate from limb_taper_scale, which only
##   controls how much extra the foot bulb flares past the base radius
## - "arm_forward_relax_factor": float, how much the arms counter-rotate
##   past merely canceling out spine_forward_bend -- 0.0 leaves the arms
##   hanging bolt vertical in world space regardless of the waist bend;
##   see _build_arm()'s own doc comment for the sign derivation
## - "head_size_scale": Vector3, per-axis multiplier on HEAD_SIZE -- see
##   _add_face_marking()/_add_muzzle()/_add_eyes()'s own doc comments for
##   why every head-surface-following computation takes the actual resized
##   head_size as a parameter instead of reading the HEAD_SIZE constant
##   directly, so the mask/muzzle/eyes stay flush on a resized head
## - "eye_shape": Dictionary {"x_scale": float, "y_scale": float, "epsilon":
##   float}, all defaulting to Xiao Hou Zi's own round eye (1.0, 1.0, 2.0)
## - "head_tilt_factor": float, how far the head counter-rotates past just
##   canceling spine_forward_bend -- 0.0 keeps the head level regardless of
##   waist bend, positive tilts it upward past level (see the head_pivot
##   rotation comment above for the same counter-rotation derivation
##   _build_arm()'s own arm_forward_relax_factor uses)
## - "marking_color": Color, the face marking's/muzzle's own base color --
##   defaults to MARKING_COLOR (Xiao Hou Zi's own sandy tone). Per direct
##   instruction real fur variation sometimes runs light-bodied with a dark
##   face/muzzle (like a real-world colobus or mandrill), so this can be set
##   noticeably darker than fur_color for that look instead of always
##   matching it
static func build(
	parent: Node3D, fur_color: Color = MONKEY_FUR_COLOR, scale: float = 1.0, variant: Dictionary = {}
) -> Dictionary:
	var rig := Node3D.new()
	rig.name = "MonkeyFigure"
	rig.scale = Vector3.ONE * scale
	parent.add_child(rig)

	var body_height := BODY_HEIGHT * (variant.get("body_height_scale", 1.0) as float)
	var body_radius := BODY_RADIUS * (variant.get("body_radius_scale", 1.0) as float)
	var hip_scale: float = variant.get("hip_scale", 1.0)
	var limb_length_scale: float = variant.get("limb_length_scale", 1.0)
	var hip_attach_raise := body_height * (variant.get("hip_attach_raise_fraction", 0.2) as float)
	var leg_upper_len := LEG_UPPER_LEN * limb_length_scale
	var leg_lower_len := LEG_LOWER_LEN * limb_length_scale

	var ankle_y := ANKLE_GROUND_CLEARANCE
	var knee_y := ankle_y + leg_lower_len
	var hip_y := knee_y + leg_upper_len

	var leg_left := _build_leg(
		rig, hip_y, 1.0, fur_color, hip_scale, leg_upper_len, leg_lower_len, hip_attach_raise
	)
	var leg_right := _build_leg(
		rig, hip_y, -1.0, fur_color, hip_scale, leg_upper_len, leg_lower_len, hip_attach_raise
	)

	# Everything above the hips (body, head, arms) hangs off spine_pivot,
	# same reasoning as procedural_figure.gd's own spine_pivot -- the legs
	# stay parented straight to `rig`, unaffected by any future spine lean.
	var spine_pivot := Node3D.new()
	spine_pivot.name = "SpinePivot"
	spine_pivot.position = Vector3(0, hip_y, 0)
	# A static forward stoop at the waist, per direct feedback -- rotates
	# everything above the hips (body/head/arms/tail) as one rigid unit
	# around spine_pivot's own origin (= the hip point), same idea as
	# ProceduralFigure's own spine lean. +X tips the spine's local +Y (its
	# own "up the torso" axis) toward +Z, which is this rig's own forward
	# (see the walk-animation convention: rotation.y = atan2(motion.x,
	# motion.z), i.e. moving toward world +Z is this figure's "straight
	# ahead" at rest) -- a positive angle here is a forward lean, not
	# backward, by the standard right-handed rotation-around-X rule.
	var spine_forward_bend: float = variant.get("spine_forward_bend", 0.0)
	spine_pivot.rotation.x = spine_forward_bend
	rig.add_child(spine_pivot)

	var body := MeshInstance3D.new()
	body.name = "Body"
	body.mesh = BlorbBodyShape.build_mesh(body_radius, body_height, variant.get("body_taper_blend", 1.0))
	body.material_override = _build_fur_material(fur_color)
	spine_pivot.add_child(body)

	var head_size: Vector3 = HEAD_SIZE * (variant.get("head_size_scale", Vector3.ONE) as Vector3)
	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	# BlorbSuit.build_head() must fit this actual head, not approximate it by
	# applying the monkey's whole-body scale ratio to human head constants.
	# Monkey heads occupy a deliberately different share of their anatomy.
	head_pivot.set_meta("blorb_suit_head_size", head_size)
	head_pivot.position = Vector3(0, body_height - HEAD_EMBED, 0)
	# Counters the inherited spine tilt the same way _build_arm()'s own
	# shoulder counter-rotation does (see that function's doc comment for
	# the derivation) -- head_pivot has no rotation.x of its own by default,
	# so with a forward-leaning spine it would otherwise inherit that tilt
	# directly, aiming the face down at the ground instead of ahead. 0.0
	# brings it back to level; positive tilts it up past level, per direct
	# instruction ("their head should be tilted upward... since they're
	# leaning forward so much").
	head_pivot.rotation.x = -spine_forward_bend * (1.0 + (variant.get("head_tilt_factor", 0.0) as float))
	spine_pivot.add_child(head_pivot)
	var head_mesh := SuperEgg.build_part(head_size, fur_color, HEAD_EPSILON, HEAD_EPSILON)
	head_mesh.material_override = _build_fur_material(fur_color)
	head_mesh.position = Vector3(0, head_size.y, 0)
	head_pivot.add_child(head_mesh)
	var notch_strength: float = variant.get("face_marking_notch_strength", 1.0)
	var marking_color: Color = variant.get("marking_color", MARKING_COLOR)
	if variant.get("has_face_marking", true):
		_add_face_marking(head_mesh, notch_strength, head_size, marking_color)
	_add_muzzle(head_mesh, variant.get("has_cheek_dots", true), head_size, marking_color)
	var eye_shape: Dictionary = variant.get("eye_shape", {})
	var eyes := _add_eyes(head_mesh, fur_color, notch_strength, head_size, eye_shape)
	FigureEars.add_ears(head_mesh, head_size, fur_color, true)

	var shoulder_height_fraction: float = variant.get("shoulder_height_fraction", 0.72)
	var arm_left := _build_arm(
		rig, spine_pivot, 1.0, fur_color, limb_length_scale, body_height, body_radius,
		spine_forward_bend, variant.get("arm_forward_relax_factor", 0.0), shoulder_height_fraction
	)
	var arm_right := _build_arm(
		rig, spine_pivot, -1.0, fur_color, limb_length_scale, body_height, body_radius,
		spine_forward_bend, variant.get("arm_forward_relax_factor", 0.0), shoulder_height_fraction
	)

	var tail := _build_tail(
		spine_pivot, fur_color, variant.get("tail_length_scale", 1.0), body_height, body_radius
	)

	var pivots := {
		"spine": spine_pivot,
		"head": head_pivot,
		"eyes": eyes,
		"hips": body,  # no separate pelvis mesh -- see this file's own class doc
		"arm_left": arm_left["pivot"],
		"arm_right": arm_right["pivot"],
		"elbow_left": arm_left["joint"],
		"elbow_right": arm_right["joint"],
		"leg_left": leg_left["pivot"],
		"leg_right": leg_right["pivot"],
		"knee_left": leg_left["joint"],
		"knee_right": leg_right["joint"],
		"ankle_left": leg_left["end"],
		"ankle_right": leg_right["end"],
		"toe_left": leg_left["end"],
		"toe_right": leg_right["end"],
		"hand_left": arm_left["end"],
		"hand_right": arm_right["end"],
		"palm_left": arm_left["end"],
		"palm_right": arm_right["end"],
		"back_left": arm_left["end"],
		"back_right": arm_right["end"],
		"wrist_left": arm_left["end"],
		"wrist_right": arm_right["end"],
		"fingertip_left": arm_left["end"],
		"fingertip_right": arm_right["end"],
		# Internal-only keys, not part of procedural_figure.gd's own
		# contract -- consumed by rebuild_limbs() below.
		"_limb_mesh_arm_left": arm_left["mesh"],
		"_limb_mesh_arm_right": arm_right["mesh"],
		"_limb_mesh_leg_left": leg_left["mesh"],
		"_limb_mesh_leg_right": leg_right["mesh"],
		"_sole_left": leg_left["sole"],
		"_sole_right": leg_right["sole"],
		"_tail": tail,
		"_rig": rig,
		"_taper_scale": variant.get("limb_taper_scale", 1.0),
		"_has_foot_pads": variant.get("has_foot_pads", true),
		"_leg_radius_scale": variant.get("leg_radius_scale", 1.0),
	}
	rebuild_limbs(pivots, rig, 0.0)
	return pivots


## hip_attach_raise (default HIP_ATTACH_RAISE, Xiao Hou Zi's own value)
## controls how far the leg's own top mesh point tucks upward into the
## body -- per direct feedback that the leg was visibly starting below the
## body's own hip bulge (BlorbBodyShape's profile peaks around t=BULGE_T=
## 0.3 of body_height, well above hip_y, while the un-raised leg top sat
## almost exactly at hip_y, the body's narrow bottom point). Raising this
## only moves the hip_pivot's own attachment point -- see the cancellation
## below -- so the knee/ankle stay exactly where limb_length_scale already
## puts them, and the visible leg tube simply reads as longer, spanning
## from higher in the body down to the same ankle.
static func _build_leg(
	rig: Node3D, hip_y: float, side: float, fur_color: Color,
	hip_scale: float = 1.0, leg_upper_len: float = LEG_UPPER_LEN, leg_lower_len: float = LEG_LOWER_LEN,
	hip_attach_raise: float = HIP_ATTACH_RAISE
) -> Dictionary:
	var hip_pivot := Node3D.new()
	hip_pivot.name = "MonkeyHipPivot"
	hip_pivot.position = Vector3(side * HIP_X * hip_scale, hip_y + hip_attach_raise, 0)
	rig.add_child(hip_pivot)

	var knee_pivot := Node3D.new()
	knee_pivot.name = "MonkeyKneePivot"
	# Counter the raised attachment in the segment length so knee and ankle
	# retain their established ground-relative positions.
	knee_pivot.position = Vector3(0, -(leg_upper_len + hip_attach_raise), 0)
	hip_pivot.add_child(knee_pivot)

	var ankle_marker := Node3D.new()
	ankle_marker.name = "MonkeyAnkleMarker"
	ankle_marker.position = Vector3(0, -leg_lower_len, 0)
	knee_pivot.add_child(ankle_marker)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "LegTube"
	_apply_fur_material(mesh_instance, fur_color)
	rig.add_child(mesh_instance)

	var sole := MeshInstance3D.new()
	sole.name = "SandySole"
	sole.material_override = _build_sole_material()
	rig.add_child(sole)

	return {
		"pivot": hip_pivot, "joint": knee_pivot, "end": ankle_marker,
		"mesh": mesh_instance, "sole": sole,
	}


## spine_forward_bend/arm_forward_relax_factor together fix the arm's rest
## pose against the waist's own forward stoop (see build()'s own comment on
## spine_forward_bend for the rotation-sign derivation this reuses). The
## arm chain hangs from shoulder_pivot with no baseline rotation.x of its
## own, so it inherits spine_pivot's forward tilt directly -- and because
## the arm's local "down" direction (0,-1,0) is on the OPPOSITE side of
## spine_pivot's own rotation axis from "up" (where the shoulder attaches),
## it rotates the OPPOSITE way: a positive spine tilt swings the shoulder
## attachment point forward but swings the hanging arm BACKWARD (world -Z),
## toward the hips -- confirmed by direct report ("arms... remained pulled
## back toward their hips") once this rig grew a forward stoop. Giving
## shoulder_pivot its own negative rotation.x, sized to more than cancel
## the inherited parent tilt, brings the arm's hang direction back past
## vertical into an actual forward relax.
static func _build_arm(
	rig: Node3D, spine_pivot: Node3D, side: float, fur_color: Color,
	limb_length_scale: float = 1.0, body_height: float = BODY_HEIGHT, body_radius: float = BODY_RADIUS,
	spine_forward_bend: float = 0.0, arm_forward_relax_factor: float = 0.0,
	shoulder_height_fraction: float = 0.72
) -> Dictionary:
	var shoulder_pivot := Node3D.new()
	shoulder_pivot.name = "MonkeyShoulderPivot"
	# Same 0.78 fraction SHOULDER_X uses for its own X, just off the
	# caller's own (possibly variant-scaled) body_radius rather than the
	# fixed BODY_RADIUS const. Y uses the caller's own
	# shoulder_height_fraction (default 0.72, SHOULDER_Y_LOCAL's own value)
	# off body_height.
	shoulder_pivot.position = Vector3(side * body_radius * 0.78, body_height * shoulder_height_fraction, 0)
	shoulder_pivot.rotation.z = side * ARM_OUTWARD_ANGLE
	shoulder_pivot.rotation.x = -spine_forward_bend * (1.0 + arm_forward_relax_factor)
	spine_pivot.add_child(shoulder_pivot)

	var elbow_pivot := Node3D.new()
	elbow_pivot.name = "MonkeyElbowPivot"
	elbow_pivot.position = Vector3(0, -UPPER_ARM_LEN * limb_length_scale, 0)
	elbow_pivot.rotation.x = -DEFAULT_ELBOW_BEND
	shoulder_pivot.add_child(elbow_pivot)

	var wrist_marker := Node3D.new()
	wrist_marker.name = "MonkeyWristMarker"
	wrist_marker.position = Vector3(0, -FOREARM_LEN * limb_length_scale, 0)
	elbow_pivot.add_child(wrist_marker)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "ArmTube"
	_apply_fur_material(mesh_instance, fur_color)
	# The live tube vertices are expressed in rig-local coordinates. Parenting
	# the mesh to the spine applied the spine's hip-height translation twice,
	# visually lifting the shoulders to the sides of the head.
	rig.add_child(mesh_instance)

	return {"pivot": shoulder_pivot, "joint": elbow_pivot, "end": wrist_marker, "mesh": mesh_instance}


## Builds the tail's rest-pose control points/mesh/material and an initial
## idle-animation state, all handed back for the caller to fold into the
## pivots dict under the "_tail_*" internal keys -- see _rebuild_tail() for
## the per-frame bend that reads these back out and animates them.
## tip_marking_color (default null == no markings, every existing caller's
## behavior unchanged) paints the tail's own tip with a marking color
## instead of the plain fur_color used everywhere else on it -- a few rings
## near the end, then a solid cap right at the tip -- see TAIL_TIP_RING_
## BANDS's own comment for the banding scheme and _rebuild_tail()'s own for
## where it's actually built each frame.
static func _build_tail(
	spine_pivot: Node3D, fur_color: Color, length_scale: float = 1.0,
	body_height: float = BODY_HEIGHT, body_radius: float = BODY_RADIUS, radius_scale: float = 1.0,
	tip_marking_color: Variant = null
) -> Dictionary:
	# Every point scaled outward from the first (the base embedded in the
	# body, which stays put) so length_scale stretches/shrinks the tail's
	# overall reach without moving where it attaches. tail_base_y uses the
	# same 0.25 fraction TAIL_BASE_Y does, off the caller's own (possibly
	# variant-elongated) body_height; the anchor's own Z offset scales with
	# the caller's own (possibly variant-scaled) body_radius the same way.
	var tail_base_y := body_height * 0.25
	var anchor := Vector3(0, tail_base_y, -body_radius * 0.3)
	var base_points: Array[Vector3] = [
		anchor,
		anchor + (Vector3(0, tail_base_y, -body_radius * 1.2) - anchor) * length_scale,
		anchor + (Vector3(0, tail_base_y + 0.015, -body_radius * 2.5) - anchor) * length_scale,
		anchor + (Vector3(0, tail_base_y + 0.020, -body_radius * 3.4) - anchor) * length_scale,
	]
	# Constant TAIL_RADIUS through every REAL control point -- per direct
	# correction, the tail reads as a continuous pipe, not a whip narrowing
	# toward the tip. TAIL_CAP_FRACTION=0.0 also switches off
	# build_limb_tube's own shared _cap_taper end-shrink (see
	# blorb_suit.gd -- it only ever reduces radius when u falls inside a
	# nonzero cap_fraction band at either end, so 0.0 would otherwise leave
	# BOTH ends at full radius, including the tip we still want capped).
	# radius_scale defaults to 1.0, reproducing MonkeyFigure's own TAIL_RADIUS
	# exactly -- ApeTemplate passes a much bigger value here, since a monkey-
	# scale tail thickness would read as a piece of string on a human-scale
	# body.
	var scaled_radius := TAIL_RADIUS * radius_scale
	var radii: Array[float] = [scaled_radius, scaled_radius, scaled_radius, scaled_radius]

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Tail"
	# Flattens only the local X (== this tube's "right" ring axis at rest,
	# since every rest-pose control/dome point above has x=0). A gentle sway
	# now moves points off x=0 too, but TAIL_SWAY_YAW_RANGE stays small
	# enough that this fixed-axis flatten still reads as intended.
	mesh_instance.scale.x = TAIL_FLATTEN_X
	# A plain fur material sets albedo_color directly and ignores vertex
	# colors entirely -- see horse_figure.gd's own _build_leg_fur_material()
	# comment for the full reasoning this mirrors. Only swapped for the
	# vertex-color-aware variant when a marking is actually requested, so
	# every existing (unmarked) tail renders exactly as before.
	if tip_marking_color != null:
		mesh_instance.material_override = _build_marked_fur_material()
	else:
		_apply_fur_material(mesh_instance, fur_color)
	spine_pivot.add_child(mesh_instance)

	var state := {
		"mesh": mesh_instance,
		"base_points": base_points,
		"radii": radii,
		"radius_scale": radius_scale,
		"fur_color": fur_color,
		"tip_marking_color": tip_marking_color,
		"pitch_current": 0.0, "pitch_target": 0.0, "pitch_timer": 0.0,
		"yaw_current": 0.0, "yaw_target": 0.0, "yaw_timer": 0.0,
	}
	_rebuild_tail(state, 0.0)
	return state


## Re-lofts the tail every frame from its rest-pose points, bent by a
## slowly-drifting pitch (droop/perk) and yaw (side sway) angle. Both axes
## retarget independently on their own randomized hold timer (see the
## TAIL_ANIM_* consts) and ease toward that target with exponential
## smoothing, so the tail never settles into a fixed pose or a visibly
## repeating cycle. The bend is rigid-rotation-per-point rather than a
## per-segment spring simulation -- simple, but weighting each point's
## rotation by (t^TAIL_BEND_EXPONENT) still reads as organic since the base
## (t=0, embedded in the belly) never moves while the tip sweeps the most,
## the same "more motion further from the anchor" shape a real tail has.
static func _rebuild_tail(state: Dictionary, delta: float) -> void:
	state["pitch_timer"] = (state["pitch_timer"] as float) - delta
	if state["pitch_timer"] <= 0.0:
		state["pitch_target"] = randf_range(-TAIL_DROOP_ANGLE, TAIL_PERK_ANGLE)
		state["pitch_timer"] = randf_range(TAIL_ANIM_PITCH_HOLD_MIN, TAIL_ANIM_PITCH_HOLD_MAX)
	state["yaw_timer"] = (state["yaw_timer"] as float) - delta
	if state["yaw_timer"] <= 0.0:
		state["yaw_target"] = randf_range(-TAIL_SWAY_YAW_RANGE, TAIL_SWAY_YAW_RANGE)
		state["yaw_timer"] = randf_range(TAIL_ANIM_YAW_HOLD_MIN, TAIL_ANIM_YAW_HOLD_MAX)

	var ease := 1.0 - exp(-delta * TAIL_ANIM_EASE_RATE)
	state["pitch_current"] = lerpf(state["pitch_current"] as float, state["pitch_target"] as float, ease)
	state["yaw_current"] = lerpf(state["yaw_current"] as float, state["yaw_target"] as float, ease)
	var pitch := state["pitch_current"] as float
	var yaw := state["yaw_current"] as float

	var base_points: Array[Vector3] = state["base_points"]
	var anchor := base_points[0]
	var last_index := base_points.size() - 1
	var points: Array[Vector3] = []
	for i in base_points.size():
		var weight := pow(float(i) / float(last_index), TAIL_BEND_EXPONENT)
		var rot := Basis(Vector3.UP, yaw * weight) * Basis(Vector3.RIGHT, pitch * weight)
		points.append(anchor + rot * (base_points[i] - anchor))
	var radii: Array[float] = (state["radii"] as Array[float]).duplicate()

	var tip_marking_color: Variant = state.get("tip_marking_color")
	var colors: Array[Color] = []
	if tip_marking_color != null:
		var fur_color: Color = state["fur_color"]
		colors.resize(points.size())
		colors.fill(fur_color)
		# See TAIL_TIP_RING_BANDS's own comment for the banding scheme.
		# Subdivides the tail's final real segment (seg_start->tip) into
		# TAIL_TIP_RING_BANDS colinear sub-segments purely as coloring
		# boundaries -- inserting a point that lies exactly on the existing
		# line between two control points doesn't bend the Catmull-Rom curve
		# through them at all, so this only affects color, never shape.
		var seg_start := points[points.size() - 2]
		var seg_end := points[points.size() - 1]
		var radius_start := radii[radii.size() - 2]
		var radius_end := radii[radii.size() - 1]
		# seg_start's own color becomes the first band -- set directly since
		# that point already exists (no insert needed for band 0).
		colors[colors.size() - 2] = tip_marking_color
		var insert_at := points.size() - 1
		for step in range(1, TAIL_TIP_RING_BANDS):
			var t := float(step) / float(TAIL_TIP_RING_BANDS)
			points.insert(insert_at, seg_start.lerp(seg_end, t))
			radii.insert(insert_at, lerpf(radius_start, radius_end, t))
			# Alternates fur/marking per band; TAIL_TIP_RING_BANDS is odd so
			# this naturally ends on a marking band right at the tip.
			colors.insert(insert_at, fur_color if step % 2 == 1 else tip_marking_color)
			insert_at += 1

	# The rounded tip is a few extra points appended to this SAME point/
	# radius list, continuing past the real (now-bent) tail geometry along
	# its own last heading, so build_limb_tube lofts the cap as part of one
	# unbroken surface instead of a second mesh glued on afterward (see
	# this file's own class-level comment on _build_tail's history for why
	# a separate primitive -- even one sized to match exactly -- still
	# read as "a weird ball" per direct report). Each step moves further
	# along that heading while its radius follows a quarter-circle profile
	# (cos/sin of the same angle) down to a true zero-radius point at the
	# very end, tracing a dome rather than a cone -- a linear taper alone
	# would pinch to a point in a straight line and look faceted, not
	# rounded.
	var tip := points[points.size() - 1]
	var tail_heading := (tip - points[points.size() - 2]).normalized()
	# Matches radii's own radius_scale (see _build_tail's own doc comment) --
	# otherwise a scaled-up tail's dome cap pinches down to MonkeyFigure's
	# own tiny unscaled TAIL_RADIUS instead of tapering from the actual
	# (bigger) tail thickness.
	var dome_radius: float = TAIL_RADIUS * (state.get("radius_scale", 1.0) as float)
	for step in range(1, TAIL_DOME_STEPS + 1):
		var theta := (float(step) / TAIL_DOME_STEPS) * (PI * 0.5)
		points.append(tip + tail_heading * (dome_radius * sin(theta)))
		radii.append(dome_radius * cos(theta))
		# The dome cap itself is the solid "cap of the tail" -- entirely
		# marking-colored, continuing on from the last (marking) ring band
		# built above with no fur gap in between.
		if tip_marking_color != null:
			colors.append(tip_marking_color)

	var mesh_instance := state["mesh"] as MeshInstance3D
	if tip_marking_color != null:
		mesh_instance.mesh = BlorbSuit.build_limb_tube(
			points, radii, LIMB_RADIAL_SEGMENTS, LIMB_RINGS_PER_SEGMENT, TAIL_CAP_FRACTION, colors
		)
	else:
		mesh_instance.mesh = BlorbSuit.build_limb_tube(
			points, radii, LIMB_RADIAL_SEGMENTS, LIMB_RINGS_PER_SEGMENT, TAIL_CAP_FRACTION
		)


## Eyes bigger and rounder than figure_eyes.gd's own subtle marks, and
## closer together, per spec ("sized like the blorb-hat's own eyes but
## positioned closer together") -- same SuperEgg.surface_point placement
## technique figure_eyes.gd/figure_ears.gd already use so they sit exactly
## on the true head surface regardless of head size, just with different
## size/spacing/flatten constants. Their front-facing X/Y axes are equal and
## use ellipse exponent 2.0, making the visible eye face a true circle; only
## local Z is flattened to seat that circle against the curved head.
## head_size lets this stay on the true surface of a variant-resized head
## (see build()'s own "head_size_scale" doc comment) instead of the fixed
## HEAD_SIZE constant. eye_shape {"x_scale","y_scale","epsilon"} reshapes
## the eye itself away from Xiao Hou Zi's own perfect circle (1.0, 1.0, 2.0)
## into a slightly oblong superellipse, per direct instruction -- x_scale/
## y_scale widen/narrow the pre-flatten mesh (the shape actually visible
## once local Z is squashed against the head), epsilon above 2.0 (a true
## ellipse) softens the corners toward a rounder rectangle instead of a
## sharper lens shape.
## head_epsilon lets the eyes seat correctly on a head built with a
## different roundness than MonkeyFigure's own HEAD_EPSILON (see build()'s
## own head_epsilon variant key) -- must match whatever epsilon the actual
## head mesh was built with, or surface_point() would place the eyes on a
## DIFFERENT (imaginary) surface than the one actually rendered. eye_shape's
## own "eta" key (default 0.0, the head's equator) lifts the eyes toward
## the crown, per direct instruction ("higher up on the face"); its "omega"
## key (default EYE_OFFSET) splays them outward in longitude -- per direct
## correction, a head built with a different head_epsilon needs its own
## splay to actually land the eyes against the face marking mask's own
## curvature instead of sitting short of it (EYE_OFFSET alone is tuned for
## MonkeyFigure's own HEAD_EPSILON). eye_color defaults to Xiao Hou Zi's
## own fixed EYE_COLOR -- callers wanting the same skin/mask-relative
## derivation FigureEyes.gd uses for the human figures (eye_color =
## base_color.darkened(0.25)) pass that in explicitly instead.
static func _add_eyes(
	head: MeshInstance3D, fur_color: Color, notch_strength: float = 1.0,
	head_size: Vector3 = HEAD_SIZE, eye_shape: Dictionary = {}, head_epsilon: float = HEAD_EPSILON,
	eye_color: Color = EYE_COLOR
) -> Array[MeshInstance3D]:
	var eye_radius := head_size.x * EYE_RADIUS_FACTOR
	var eye_x_scale: float = eye_shape.get("x_scale", 1.0)
	var eye_y_scale: float = eye_shape.get("y_scale", 1.0)
	var eye_epsilon: float = eye_shape.get("epsilon", 2.0)
	var eta: float = eye_shape.get("eta", 0.0)
	var omega: float = eye_shape.get("omega", EYE_OFFSET)
	var eyes: Array[MeshInstance3D] = []

	for side in [-1.0, 1.0]:
		var surface := SuperEgg.surface_point(
			head_size, eta, side * omega, head_epsilon, head_epsilon
		)

		var eye := MeshInstance3D.new()
		eye.name = "EyeL" if side < 0.0 else "EyeR"
		eye.mesh = SuperEgg.build_mesh(
			Vector3(eye_radius * eye_x_scale, eye_radius * eye_y_scale, eye_radius), eye_epsilon, eye_epsilon
		)
		var material := StandardMaterial3D.new()
		material.albedo_color = eye_color
		material.roughness = 0.4
		eye.set_surface_override_material(0, material)

		var horizontal_outward := Vector3(surface.x, 0.0, surface.z).normalized()
		var up := Vector3.UP
		var right := up.cross(horizontal_outward).normalized()
		eye.basis = Basis(right, up, horizontal_outward)
		eye.scale = Vector3(1.0, 1.0, EYE_FLATTEN)
		# The face marking (see _add_face_marking) is a separately raised
		# relief that happens to sit right where these eyes land -- without
		# accounting for it, an eye's front face lands well short of the
		# mask's own front surface and the eye reads as buried under the
		# mask instead of sitting on it. _face_marking_relief_at gives the
		# mask's outward offset at this exact (x, y); push the eye out by
		# whatever's still needed, beyond its own base placement, to clear
		# that surface plus a small visible margin. Outside the mask's
		# footprint this returns 0 and eyes sit on the bare head exactly as
		# before.
		var base_front_offset := eye_radius * (EYE_FLATTEN - (1.0 - EYE_FLATTEN) * 0.5)
		var mask_front_offset := _face_marking_relief_at(surface.x, surface.y, notch_strength, head_size) + EYE_MASK_CLEARANCE_MARGIN
		var extra_push := maxf(0.0, mask_front_offset - base_front_offset)
		eye.position = (
			surface
			- horizontal_outward * (eye_radius * (1.0 - EYE_FLATTEN) * 0.5)
			+ horizontal_outward * extra_push
		)
		head.add_child(eye)
		eyes.append(eye)

	return eyes


## One continuous curved heart-like facial field, with paired round crowns
## around the eyes and a broad rounded lower area around the muzzle.
static func _add_face_marking(
	head: MeshInstance3D, notch_strength: float = 1.0, head_size: Vector3 = HEAD_SIZE,
	marking_color: Color = MARKING_COLOR, head_epsilon: float = HEAD_EPSILON
) -> void:
	var mask := MeshInstance3D.new()
	mask.name = "FaceMarking"
	mask.mesh = _build_face_marking_mesh(notch_strength, head_size, head_epsilon)
	mask.material_override = _build_marking_material(marking_color)
	head.add_child(mask)


static func _build_face_marking_mesh(
	notch_strength: float = 1.0, head_size: Vector3 = HEAD_SIZE, head_epsilon: float = HEAD_EPSILON
) -> ArrayMesh:
	const RINGS := 8
	const SEGMENTS := 40
	var front_rings: Array = [[_face_marking_point(0.0, 0.0, true, notch_strength, head_size, head_epsilon)]]
	var back_rings: Array = [[_face_marking_point(0.0, 0.0, false, notch_strength, head_size, head_epsilon)]]
	for ring_i in range(1, RINGS + 1):
		var radius := float(ring_i) / float(RINGS)
		var front_ring: Array[Vector3] = []
		var back_ring: Array[Vector3] = []
		for seg in SEGMENTS:
			var angle := TAU * float(seg) / float(SEGMENTS)
			front_ring.append(_face_marking_point(radius, angle, true, notch_strength, head_size, head_epsilon))
			back_ring.append(_face_marking_point(radius, angle, false, notch_strength, head_size, head_epsilon))
		front_rings.append(front_ring)
		back_rings.append(back_ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for seg in SEGMENTS:
		var next := (seg + 1) % SEGMENTS
		_add_mesh_triangle(st, front_rings[0][0], front_rings[1][seg], front_rings[1][next])
		_add_mesh_triangle(st, back_rings[0][0], back_rings[1][next], back_rings[1][seg])
	for ring_i in range(1, RINGS):
		for seg in SEGMENTS:
			var next := (seg + 1) % SEGMENTS
			var fa: Vector3 = front_rings[ring_i][seg]
			var fb: Vector3 = front_rings[ring_i][next]
			var fc: Vector3 = front_rings[ring_i + 1][seg]
			var fd: Vector3 = front_rings[ring_i + 1][next]
			_add_mesh_triangle(st, fa, fc, fb)
			_add_mesh_triangle(st, fb, fc, fd)
			var ba: Vector3 = back_rings[ring_i][seg]
			var bb: Vector3 = back_rings[ring_i][next]
			var bc: Vector3 = back_rings[ring_i + 1][seg]
			var bd: Vector3 = back_rings[ring_i + 1][next]
			_add_mesh_triangle(st, ba, bb, bc)
			_add_mesh_triangle(st, bb, bd, bc)
	var front_edge: Array = front_rings[RINGS]
	var back_edge: Array = back_rings[RINGS]
	for seg in SEGMENTS:
		var next := (seg + 1) % SEGMENTS
		_add_mesh_triangle(st, front_edge[seg], back_edge[seg], front_edge[next])
		_add_mesh_triangle(st, front_edge[next], back_edge[seg], back_edge[next])
	st.generate_normals()
	return st.commit()


## notch_strength scales only the center dip between the two crown lobes --
## the heart shape's "widow's peak" -- 1.0 is Xiao Hou Zi's own original
## depth, lower values soften it toward a rounder, less pointed top per
## direct feedback on the villager variant. Left at 1.0 for every existing
## caller.
## head_size lets this stay flush on the true surface of a variant-resized
## head (see build()'s own "head_size_scale" doc comment) AND scales the
## mask's own footprint proportionally with it -- per direct correction, an
## earlier version only fixed the flush-to-surface depth math and left the
## mask pinned at MonkeyFigure's own tiny absolute footprint, reading as a
## small sticker lost on a much bigger ape head instead of scaling with it.
## face_scale (head_size / HEAD_SIZE, per axis) converts every footprint
## constant below from "reference monkey-head units" to the caller's actual
## head size: the shape math (crown/notch positions, all in normalized -1..1
## nx/ny space) runs completely unchanged, only the final conversion to real
## units picks up the scale.
static func _face_marking_point(
	radius: float, angle: float, front: bool, notch_strength: float = 1.0, head_size: Vector3 = HEAD_SIZE,
	head_epsilon: float = HEAD_EPSILON
) -> Vector3:
	var face_scale := head_size / HEAD_SIZE
	var nx := cos(angle) * radius
	var ny := sin(angle) * radius
	var x := nx * 0.026  # reference-head units
	var upper := maxf(ny, 0.0)
	var left_crown := exp(-pow((nx + 0.44) / 0.36, 2.0))
	var right_crown := exp(-pow((nx - 0.44) / 0.36, 2.0))
	var center_notch := exp(-pow(nx / 0.24, 2.0))
	# Keep this continuous field concentrated around the eyes. Its rounded
	# lower point only tucks slightly behind the separately modeled muzzle,
	# instead of extending through the entire mouth area and visually merging
	# both sandy forms into one flat mask.
	var y := (
		0.006 + ny * 0.016
		+ upper * ((left_crown + right_crown) * 0.0022 - center_notch * 0.0024 * notch_strength)
	)  # reference-head units
	var real_x := x * face_scale.x
	var real_y := y * face_scale.y
	var head_term := maxf(
		1.0
		- pow(absf(real_x) / head_size.x, head_epsilon)
		- pow(absf(real_y) / head_size.y, head_epsilon),
		0.0
	)
	var face_z := head_size.z * pow(head_term, 1.0 / head_epsilon)
	var back_z := face_z + 0.0005 * face_scale.z
	if not front:
		return Vector3(real_x, real_y, back_z)
	# A real raised relief, not a floating painted sheet: thickness remains
	# visible at the perimeter and swells gently toward the center. Pulled
	# back slightly closer to the skull (reduced from 0.0022/0.0012) per
	# direct correction that the mask sat too far off the face.
	var relief_depth := (0.0018 + (1.0 - radius * radius) * 0.0009) * face_scale.z
	return Vector3(real_x, real_y, back_z + relief_depth)


## Inverse of _face_marking_point's own (radius, angle) -> (x, y) mapping:
## given a real head-local (x, y), returns how far outward (extra +z, on
## top of the bare head surface) the raised mask sits there, or 0.0 if that
## point falls outside the mask's footprint entirely. Only _add_eyes calls
## this today (so the eyes clear the mask instead of getting buried under
## it -- see that function's own comment), but it's kept alongside
## _face_marking_point, not inlined there, so the two stay obviously in
## sync if the mask's shaping constants (0.026, 0.44, 0.36, 0.24, the 0.006/
## 0.016 baseline) are ever retuned again.
## head_size (see _face_marking_point()'s own identical doc comment) --
## converts the real (x, y) back to reference-head units first, runs the
## exact original (unscaled) inverse math against that, then scales the
## resulting depth back up by face_scale.z at the very end.
static func _face_marking_relief_at(x: float, y: float, notch_strength: float = 1.0, head_size: Vector3 = HEAD_SIZE) -> float:
	var face_scale := head_size / HEAD_SIZE
	var ref_x := x / face_scale.x
	var ref_y := y / face_scale.y
	var nx := ref_x / 0.026
	var left_crown := exp(-pow((nx + 0.44) / 0.36, 2.0))
	var right_crown := exp(-pow((nx - 0.44) / 0.36, 2.0))
	var center_notch := exp(-pow(nx / 0.24, 2.0))
	var crown_term := (left_crown + right_crown) * 0.0022 - center_notch * 0.0024 * notch_strength
	# Try the upper-half branch (ny >= 0, where crown_term applies) first;
	# it's only the correct inverse if it's self-consistent, i.e. actually
	# comes out non-negative. Otherwise fall back to the plain lower-half
	# linear mapping.
	var ny := (ref_y - 0.006) / (0.016 + crown_term)
	if ny < 0.0:
		ny = (ref_y - 0.006) / 0.016
	var radius := sqrt(nx * nx + ny * ny)
	if radius > 1.0:
		return 0.0
	var relief_depth := 0.0018 + (1.0 - radius * radius) * 0.0009
	return (0.0005 + relief_depth) * face_scale.z


## A single closed potato-like muzzle: elliptical/round underneath, with
## three very soft rises along its upper edge (left cheek, nose, right
## cheek). Its back vertices follow the head's near-ellipsoidal face while
## the front receives a shallow dome, so it grows naturally out of the
## sandy facial field rather than reading as a flat plate.
static func _add_muzzle(
	head: MeshInstance3D, has_cheek_dots: bool = true, head_size: Vector3 = HEAD_SIZE,
	marking_color: Color = MARKING_COLOR, head_epsilon: float = HEAD_EPSILON, chin_extend: float = 0.0,
	has_nose: bool = true
) -> void:
	var muzzle := MeshInstance3D.new()
	muzzle.name = "Muzzle"
	muzzle.mesh = _build_muzzle_mesh(head_size, head_epsilon, chin_extend)
	muzzle.material_override = _build_marking_material(marking_color)
	head.add_child(muzzle)
	_add_muzzle_features(muzzle, has_cheek_dots, head_size, head_epsilon, chin_extend, has_nose)


## face_scale (see _face_marking_point()'s own identical doc comment)
## scales each detail's position/size proportionally with head_size --
## depth_scale is left alone (a dimensionless flatten RATIO on the detail's
## own mesh, applied via .scale.z, not an absolute size) but surface_offset
## (a real clearance distance above the muzzle surface) scales with
## face_scale.z the same way every other depth offset in this file does.
static func _add_muzzle_features(
	muzzle: MeshInstance3D, has_cheek_dots: bool = true, head_size: Vector3 = HEAD_SIZE,
	head_epsilon: float = HEAD_EPSILON, chin_extend: float = 0.0, has_nose: bool = true
) -> void:
	var face_scale := head_size / HEAD_SIZE
	var xy_scale := Vector2(face_scale.x, face_scale.y)
	# Small horizontal oval near the center-top swell. depth_scale/surface_
	# offset trimmed further (from 0.015/0.00002) per direct correction that
	# it still read as too thick/raised off the muzzle.
	if has_nose:
		_add_muzzle_detail(
			muzzle, "Nose", Vector2(0, -0.0085) * xy_scale, Vector2(0.003, 0.00165) * xy_scale, NOSE_COLOR,
			0.010, 0.000012 * face_scale.z, head_size, head_epsilon, chin_extend
		)
	if not has_cheek_dots:
		return
	# One warm-yellow cheek dot per side, just under the eye's own radius.
	# These read as flat pigment spots, not raised bumps, so depth_scale is
	# cut hard (0.03 -> 0.02 -> 0.006) and surface_offset brought down to a
	# near-flush sliver (0.00003 -> 0.00002 -> 0.000004) per repeated direct
	# correction that they still looked like marbles poking off the face.
	for side in [-1.0, 1.0]:
		_add_muzzle_detail(
			muzzle, "CheekDot", Vector2(side * 0.0135, -0.0100) * xy_scale, Vector2.ONE * 0.0033 * xy_scale,
			CHEEK_DOT_COLOR, 0.006, 0.000004 * face_scale.z, head_size, head_epsilon, chin_extend
		)


static func _add_muzzle_detail(
	muzzle: MeshInstance3D, detail_name: String, xy: Vector2,
	half_size: Vector2, color: Color, depth_scale: float, surface_offset: float,
	head_size: Vector3 = HEAD_SIZE, head_epsilon: float = HEAD_EPSILON, chin_extend: float = 0.0
) -> void:
	var detail := MeshInstance3D.new()
	detail.name = detail_name
	detail.mesh = SuperEgg.build_mesh(
		Vector3(half_size.x, half_size.y, minf(half_size.x, half_size.y)), 2.0, 2.0
	)
	detail.scale.z = depth_scale
	detail.material_override = _build_fur_material(color)
	var sample_step := 0.0002
	var z := _muzzle_front_z(xy.x, xy.y, head_size, head_epsilon, chin_extend)
	var dz_dx := (
		_muzzle_front_z(xy.x + sample_step, xy.y, head_size, head_epsilon, chin_extend)
		- _muzzle_front_z(xy.x - sample_step, xy.y, head_size, head_epsilon, chin_extend)
	) / (sample_step * 2.0)
	var dz_dy := (
		_muzzle_front_z(xy.x, xy.y + sample_step, head_size, head_epsilon, chin_extend)
		- _muzzle_front_z(xy.x, xy.y - sample_step, head_size, head_epsilon, chin_extend)
	) / (sample_step * 2.0)
	var normal := Vector3(-dz_dx, -dz_dy, 1.0).normalized()
	var right := Vector3(1.0, 0.0, dz_dx).normalized()
	var up := normal.cross(right).normalized()
	detail.basis = Basis(right, up, normal)
	detail.position = Vector3(xy.x, xy.y, z) + normal * surface_offset
	muzzle.add_child(detail)


## x/y are real head-local coordinates (matches _add_muzzle_detail's own
## call). face_scale converts to reference-head units for the nx/ny inverse
## (see _face_marking_point()'s identical doc comment on this split); the
## head_term surface test needs real x/y/head_size, unchanged.
static func _muzzle_front_z(
	x: float, y: float, head_size: Vector3 = HEAD_SIZE, head_epsilon: float = HEAD_EPSILON,
	chin_extend: float = 0.0
) -> float:
	var face_scale := head_size / HEAD_SIZE
	var nx := (x / face_scale.x) / 0.021
	# Same branch-then-fall-back inverse technique _face_marking_relief_at
	# uses for its own piecewise mapping: try the un-stretched (upper-half)
	# scale first, and if that comes out negative (meaning the point is
	# actually in the chin-extended lower half), redo it with that half's
	# own stretched scale instead.
	var ny := ((y / face_scale.y) + 0.011) / 0.012
	if ny < 0.0:
		ny = ((y / face_scale.y) + 0.011) / (0.012 * (1.0 + chin_extend))
	var radius := clampf(Vector2(nx, ny).length(), 0.0, 1.0)
	var upper_weight := maxf(ny, 0.0)
	var cheek_left := exp(-pow((nx + 0.62) / 0.34, 2.0))
	var nose := exp(-pow(nx / 0.30, 2.0))
	var cheek_right := exp(-pow((nx - 0.62) / 0.34, 2.0))
	var three_swells := cheek_left + nose * 0.8 + cheek_right
	var head_term := maxf(
		1.0
		- pow(absf(x) / head_size.x, head_epsilon)
		- pow(absf(y) / head_size.y, head_epsilon),
		0.0
	)
	var z_back := head_size.z * pow(head_term, 1.0 / head_epsilon) + 0.0008 * face_scale.z
	# Kept in sync with _muzzle_point's own front branch -- see its comment.
	var dome := (1.0 - radius * radius) * 0.0052 * face_scale.z
	var crown_bulge := upper_weight * three_swells * (1.0 - radius * 0.65) * 0.0007 * face_scale.z
	return z_back + 0.0012 * face_scale.z + dome + crown_bulge


static func _build_muzzle_mesh(
	head_size: Vector3 = HEAD_SIZE, head_epsilon: float = HEAD_EPSILON, chin_extend: float = 0.0
) -> ArrayMesh:
	const RINGS := 6
	const SEGMENTS := 32
	var front_rings: Array = []
	var back_rings: Array = []
	front_rings.append([_muzzle_point(0.0, 0.0, true, head_size, head_epsilon, chin_extend)])
	back_rings.append([_muzzle_point(0.0, 0.0, false, head_size, head_epsilon, chin_extend)])
	for ring_i in range(1, RINGS + 1):
		var radius := float(ring_i) / float(RINGS)
		var front_ring: Array[Vector3] = []
		var back_ring: Array[Vector3] = []
		for seg in SEGMENTS:
			var angle := TAU * float(seg) / float(SEGMENTS)
			front_ring.append(_muzzle_point(radius, angle, true, head_size, head_epsilon, chin_extend))
			back_ring.append(_muzzle_point(radius, angle, false, head_size, head_epsilon, chin_extend))
		front_rings.append(front_ring)
		back_rings.append(back_ring)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for seg in SEGMENTS:
		var next := (seg + 1) % SEGMENTS
		_add_mesh_triangle(st, front_rings[0][0], front_rings[1][seg], front_rings[1][next])
		_add_mesh_triangle(st, back_rings[0][0], back_rings[1][next], back_rings[1][seg])
	for ring_i in range(1, RINGS):
		for seg in SEGMENTS:
			var next := (seg + 1) % SEGMENTS
			var fa: Vector3 = front_rings[ring_i][seg]
			var fb: Vector3 = front_rings[ring_i][next]
			var fc: Vector3 = front_rings[ring_i + 1][seg]
			var fd: Vector3 = front_rings[ring_i + 1][next]
			_add_mesh_triangle(st, fa, fc, fb)
			_add_mesh_triangle(st, fb, fc, fd)
			var ba: Vector3 = back_rings[ring_i][seg]
			var bb: Vector3 = back_rings[ring_i][next]
			var bc: Vector3 = back_rings[ring_i + 1][seg]
			var bd: Vector3 = back_rings[ring_i + 1][next]
			_add_mesh_triangle(st, ba, bb, bc)
			_add_mesh_triangle(st, bb, bd, bc)
	var front_edge: Array = front_rings[RINGS]
	var back_edge: Array = back_rings[RINGS]
	for seg in SEGMENTS:
		var next := (seg + 1) % SEGMENTS
		_add_mesh_triangle(st, front_edge[seg], back_edge[seg], front_edge[next])
		_add_mesh_triangle(st, front_edge[next], back_edge[seg], back_edge[next])
	st.generate_normals()
	return st.commit()


## head_size lets this stay flush on a variant-resized head's true surface
## -- see _face_marking_point()'s own identical doc comment; same split
## (only head_term/z_back needs it, the muzzle's own footprint constants
## stay absolute).
## head_size scales the muzzle's own footprint proportionally with it -- see
## _face_marking_point()'s own identical doc comment for the reference-
## units-then-scale-the-output technique this uses.
## chin_extend (default 0.0, MonkeyFigure's own original footprint)
## stretches only the LOWER half of the muzzle's footprint (ny < 0, toward
## the chin) further down -- per direct instruction to elongate the muzzle
## "a bit down toward the chin" without moving its upper (nose/eye-level)
## edge.
static func _muzzle_point(
	radius: float, angle: float, front: bool, head_size: Vector3 = HEAD_SIZE, head_epsilon: float = HEAD_EPSILON,
	chin_extend: float = 0.0
) -> Vector3:
	var face_scale := head_size / HEAD_SIZE
	var nx := cos(angle) * radius
	var ny := sin(angle) * radius
	# Three broad Gaussians gently scallop only the upper silhouette.
	var upper_weight := maxf(ny, 0.0)
	var cheek_left := exp(-pow((nx + 0.62) / 0.34, 2.0))
	var nose := exp(-pow(nx / 0.30, 2.0))
	var cheek_right := exp(-pow((nx - 0.62) / 0.34, 2.0))
	var three_swells := cheek_left + nose * 0.8 + cheek_right
	var x := nx * 0.021  # reference-head units
	var y_scale := (1.0 + chin_extend) if ny < 0.0 else 1.0
	var y := -0.011 + ny * 0.012 * y_scale + upper_weight * three_swells * 0.0012  # reference-head units
	var real_x := x * face_scale.x
	var real_y := y * face_scale.y
	# Seat the rear surface on the actual near-round head instead of a plane.
	var head_term := maxf(
		1.0
		- pow(absf(real_x) / head_size.x, head_epsilon)
		- pow(absf(real_y) / head_size.y, head_epsilon),
		0.0
	)
	var z_back := head_size.z * pow(head_term, 1.0 / head_epsilon) + 0.0008 * face_scale.z
	if not front:
		return Vector3(real_x, real_y, z_back)
	# Front-only additions (base offset + dome) bumped up from 0.0008/0.0045
	# per direct correction that the muzzle should extrude out from the face
	# a bit more; z_back's own embed stays untouched.
	var dome := (1.0 - radius * radius) * 0.0052 * face_scale.z
	var crown_bulge := upper_weight * three_swells * (1.0 - radius * 0.65) * 0.0007 * face_scale.z
	return Vector3(real_x, real_y, z_back + 0.0012 * face_scale.z + dome + crown_bulge)


static func _add_mesh_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _apply_fur_material(mesh_instance: MeshInstance3D, fur_color: Color) -> void:
	mesh_instance.material_override = _build_fur_material(fur_color)


static func _build_fur_material(fur_color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	# Monkey fur is a solid surface, not goo: discard any supplied alpha and
	# explicitly select the opaque depth path rather than relying on defaults.
	material.albedo_color = Color(fur_color.r, fur_color.g, fur_color.b, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	material.metallic = 0.0
	material.roughness = 0.95
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# The body/limb geometry comes from the same shared lathe/tube builders
	# (BlorbBodyShape, BlorbSuit.build_limb_tube) every other consumer in the
	# codebase renders with cull_mode disabled -- for THEM that's read as
	# serving their alpha-blend goo look, but it's also quietly covering for
	# those builders not guaranteeing single-sided-correct winding on every
	# triangle. This fur material was the first opaque, default-cull consumer
	# of that geometry, which is what let backface culling show the inside
	# of the body/limbs through as an apparent "see-through" body.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _build_marking_material(marking_color: Color = MARKING_COLOR) -> StandardMaterial3D:
	return _build_fur_material(marking_color)


## Per-vertex-colored variant -- see horse_figure.gd's own
## _build_leg_fur_material() for the full reasoning this mirrors exactly:
## albedo_color left WHITE with vertex_color_use_as_albedo on so the
## rendered color comes from each vertex's own baked color, and
## vertex_color_is_srgb on so that baked color matches a plain _build_
## fur_material() albedo_color using the same raw numbers (Godot otherwise
## reads a mesh's own vertex COLOR array as already-linear, rendering it
## visibly darker/duller than an albedo_color built from identical values).
static func _build_marked_fur_material() -> StandardMaterial3D:
	var material := _build_fur_material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	return material


static func _build_sole_material() -> StandardMaterial3D:
	var material := _build_marking_material()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Re-lofts the four limb tubes from their invisible bone pivots' CURRENT
## global positions -- must be called every frame the rig is animated (see
## player.gd's own per-frame call next to _blorb_suit.update()), the same
## reason blorb_suit.gd's own noodles get rebuilt every frame instead of
## being built once: a tube spanning multiple independently-rotating pivots
## has to be re-lofted whenever any of them move, unlike a single rigid mesh
## parented to one pivot.
static func rebuild_limbs(pivots: Dictionary, root: Node3D, delta: float = 0.0) -> void:
	# Callers own the outer Visuals node, but tube geometry and tube meshes
	# both live inside the uniformly-scaled monkey rig. Always rebuild in that
	# shared local space or the rig scale gets baked into vertices and applied
	# a second time by the scene tree.
	root = pivots["_rig"] as Node3D
	var taper_scale: float = pivots.get("_taper_scale", 1.0)
	var has_pads: bool = pivots.get("_has_foot_pads", true)
	var leg_radius_scale: float = pivots.get("_leg_radius_scale", 1.0)
	var wrist_radius := lerpf(ARM_RADIUS_ELBOW, ARM_RADIUS_WRIST, taper_scale)
	_rebuild_tube(
		pivots["_limb_mesh_arm_left"] as MeshInstance3D, root,
		[pivots["arm_left"] as Node3D, pivots["elbow_left"] as Node3D, pivots["wrist_left"] as Node3D],
		[ARM_RADIUS_SHOULDER, ARM_RADIUS_ELBOW, wrist_radius]
	)
	_rebuild_tube(
		pivots["_limb_mesh_arm_right"] as MeshInstance3D, root,
		[pivots["arm_right"] as Node3D, pivots["elbow_right"] as Node3D, pivots["wrist_right"] as Node3D],
		[ARM_RADIUS_SHOULDER, ARM_RADIUS_ELBOW, wrist_radius]
	)
	_rebuild_footed_leg(
		pivots["_limb_mesh_leg_left"] as MeshInstance3D, root,
		pivots["leg_left"] as Node3D, pivots["knee_left"] as Node3D,
		pivots["ankle_left"] as Node3D, pivots["_sole_left"] as MeshInstance3D,
		taper_scale, has_pads, leg_radius_scale
	)
	_rebuild_footed_leg(
		pivots["_limb_mesh_leg_right"] as MeshInstance3D, root,
		pivots["leg_right"] as Node3D, pivots["knee_right"] as Node3D,
		pivots["ankle_right"] as Node3D, pivots["_sole_right"] as MeshInstance3D,
		taper_scale, has_pads, leg_radius_scale
	)
	_rebuild_tail(pivots["_tail"] as Dictionary, delta)


static func _rebuild_tube(
	mesh_instance: MeshInstance3D, root: Node3D, joints: Array[Node3D], radii: Array[float]
) -> void:
	var points: Array[Vector3] = []
	for joint in joints:
		points.append(root.to_local(joint.global_position))
	mesh_instance.mesh = BlorbSuit.build_limb_tube(
		points, radii, LIMB_RADIAL_SEGMENTS, LIMB_RINGS_PER_SEGMENT, LIMB_CAP_FRACTION
	)


static func _rebuild_footed_leg(
	mesh_instance: MeshInstance3D, root: Node3D,
	hip: Node3D, knee: Node3D, ankle: Node3D, sole: MeshInstance3D,
	taper_scale: float = 1.0, has_pad: bool = true, leg_radius_scale: float = 1.0
) -> void:
	var hip_pos := root.to_local(hip.global_position)
	var knee_pos := root.to_local(knee.global_position)
	var ankle_pos := root.to_local(ankle.global_position)
	# The compatibility ankle marker still receives the shared human
	# controller's ankle rotations, but visible monkey geometry must remain a
	# single knee-driven pear. Build its lower frame from the knee basis and
	# ankle POSITION only, deliberately ignoring ankle.global_transform.basis.
	var root_basis_inverse := root.global_transform.basis.inverse()
	var lower_up := (root_basis_inverse * (knee.global_transform.basis * Vector3.UP)).normalized()
	var lower_forward := (
		root_basis_inverse * (knee.global_transform.basis * Vector3(0, 0, 1))
	).normalized()
	# A strictly descending sequence with small progressive forward shifts:
	# this is one continuous pear profile, not a leg followed by a foot bend.
	var transition_pos := (
		ankle_pos + lower_up * 0.018 + lower_forward * (FOOT_BULB_FORWARD * 0.3)
	)
	var bulb_pos := (
		ankle_pos
		+ lower_up * (FOOT_BULB_CENTER_Y - ANKLE_GROUND_CLEARANCE)
		+ lower_forward * FOOT_BULB_FORWARD
	)
	var bottom_pos := (
		ankle_pos - lower_up * ANKLE_GROUND_CLEARANCE + lower_forward * FOOT_BULB_FORWARD
	)
	var points: Array[Vector3] = [hip_pos, knee_pos, transition_pos, bulb_pos, bottom_pos]
	# taper_scale eases the bulge itself (and the point partway toward it)
	# back toward the knee's own radius -- FOOT_BOTTOM_RADIUS is left alone
	# since the toe tip's own pinch is a separate detail, not the "widens
	# out at the end" flare per direct feedback this exists to soften.
	var radii: Array[float] = [
		LEG_RADIUS_HIP * leg_radius_scale, LEG_RADIUS_KNEE * leg_radius_scale,
		lerpf(LEG_RADIUS_KNEE, 0.019, taper_scale) * leg_radius_scale,
		lerpf(LEG_RADIUS_KNEE, FOOT_BULB_RADIUS, taper_scale) * leg_radius_scale,
		FOOT_BOTTOM_RADIUS * leg_radius_scale,
	]
	mesh_instance.mesh = BlorbSuit.build_limb_tube(
		points, radii, LIMB_RADIAL_SEGMENTS, LIMB_RINGS_PER_SEGMENT, LIMB_CAP_FRACTION
	)
	if has_pad:
		_rebuild_sole_from_leg_mesh(
			sole, mesh_instance.mesh as ArrayMesh, ankle_pos, lower_up, lower_forward
		)
	elif sole.mesh != null:
		sole.mesh = null


## The sole is not an independently guessed primitive. It copies the live
## foot tube's actual downward-facing triangles, so its curvature and every
## animated deformation are mathematically identical to the brown surface.
static func _rebuild_sole_from_leg_mesh(
	sole: MeshInstance3D, leg_mesh: ArrayMesh, ankle_pos: Vector3,
	lower_up: Vector3, lower_forward: Vector3
) -> void:
	var arrays := leg_mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	# SurfaceTool commits this tube without an index buffer, in which case
	# Godot stores NIL in ARRAY_INDEX rather than an empty PackedInt32Array.
	var indices := PackedInt32Array()
	var raw_indices: Variant = arrays[Mesh.ARRAY_INDEX]
	if raw_indices != null:
		indices = raw_indices as PackedInt32Array
	var triangle_count := int(indices.size() / 3) if not indices.is_empty() else int(vertices.size() / 3)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var copied := 0
	for triangle_i in triangle_count:
		var ids: Array[int] = []
		for corner in 3:
			ids.append(indices[triangle_i * 3 + corner] if not indices.is_empty() else triangle_i * 3 + corner)
		var center := (vertices[ids[0]] + vertices[ids[1]] + vertices[ids[2]]) / 3.0
		var average_normal := (normals[ids[0]] + normals[ids[1]] + normals[ids[2]]).normalized()
		var relative := center - ankle_pos
		var height_from_ankle := relative.dot(lower_up)
		var forward_from_ankle := relative.dot(lower_forward)
		# Widened from the original 0.006/0.35/-0.15: those three thresholds
		# stacked together left the filter matching zero triangles in
		# practice, so no pad ever appeared. The likely reason is that
		# generate_normals() (called inside BlorbSuit.build_limb_tube's own
		# BlorbBodyShape.build_mesh_from_rings) SMOOTHS each vertex normal
		# across every face sharing it -- around the foot tube's tightly
		# curving tip cap, that averaging shallows the normal well short of
		# straight down, so the strict -0.15 cutoff never let anything
		# through. Loosening the position window and the normal cutoff still
		# keeps this to the underside of the foot bulb/cap, just without
		# requiring an implausibly steep averaged normal to get there.
		if height_from_ankle > 0.012 or forward_from_ankle < FOOT_BULB_FORWARD * 0.15:
			continue
		if average_normal.dot(lower_up) > 0.05:
			continue
		for id in ids:
			var normal: Vector3 = normals[id]
			st.set_normal(normal)
			st.add_vertex(vertices[id] + normal * 0.00015)
		copied += 1
	if copied > 0:
		sole.mesh = st.commit()
	sole.transform = Transform3D.IDENTITY
