class_name ProceduralFigure
extends RefCounted

## Builds an entire humanoid figure from scratch out of SuperEgg body
## segments, per direct instruction -- replacing the earlier imported-GLB
## rig (figure.glb for the player, the Kenney prototype-kit figurine
## variants for NPCs) for both.
##
## Spine: hips (root) -> abdomen -> chest, each a torso SuperEgg with flat
## top/bottom seams (SuperEgg.EPSILON_FLAT) so they read as distinct
## stacked segments rather than blending into one blob -- flat faces mate
## flush against each other with no gap, unlike two rounded caps meeting
## at a point (see below). Chest is the widest, abdomen narrower, hips a
## bit wider than the abdomen but shorter, per spec.
##
## Limb segments (upper/lower arm and leg, hands, feet) use a symmetric
## soft-rounded profile instead (SuperEgg.EPSILON_SOFT both ends), which
## DOES pinch to a point at each pole -- two such segments just touching
## at a shared joint point reads as a visible pinch/gap right at the
## joint, which is exactly why an earlier version filled that gap with a
## small sphere at each joint. Per direct instruction those spheres are
## gone now (joints should be plain pivot points, not their own visible
## segment); most joints instead use _build_overlapping_segment(), which
## renders a segment slightly longer than its *logical* length and shifts
## it so the extra length overlaps into its neighbor, burying the pinch in
## the overlap (JOINT_OVERLAP for ordinary joints; HIP_SOCKET_EMBED is
## deliberately much larger for the hip, so the thigh visibly pokes up
## into the hip volume like a real ball-and-socket, not just avoiding a
## pinch). The shoulder is the one deliberate exception -- per direct
## instruction the upper arm attaches to the *outside* of the chest with
## no overlap treatment, and the resulting pinch there is fine.
##
## No ancestor-rotation correction anywhere here (contrast the old
## figure.glb/npc.gd rig, which needed a static 180-degree turn to fix an
## imported model's reversed native front) -- every part is built directly
## in this project's own "+Z is forward" convention, since there's no
## external asset in the chain with a conflicting one of its own.
##
## build() returns the pivots player.gd/npc.gd need for animation:
## head/arm_left/arm_right/leg_left/leg_right (rotating one of these
## swings that whole limb from the shoulder/hip, as before) plus
## elbow_left/elbow_right/knee_left/knee_right (rotating one of these
## bends just the forearm/hand or shin/foot, for the walk cycle's subtle
## knee/elbow articulation -- see player.gd/npc.gd's _animate_walk),
## ankle_left/ankle_right (rotating one of these tips just the foot,
## unused by the ordinary walk cycle but needed for player.gd's jump/
## landing pose), spine (the abdomen/chest/head/arms all hang off this,
## but NOT the legs -- rotating it leans the upper body forward while
## walking, the way a real person's spine does, without tilting the legs
## too), and hips (the pelvis mesh itself -- rotating its Z tilts it
## side-to-side, e.g. for an idle "weight on one leg" pose's hip drop; see
## player.gd/npc.gd's idle-pose comments). Also hand_left/hand_right (the
## hand's own built MeshInstance3D) and palm_left/palm_right/back_left/
## back_right (plain Node3Ds sitting on the hand's own palm- and
## back-facing surfaces respectively, each a child of `hand` so it inherits
## the hand's wrist twist automatically -- see _build_arm's own PalmAttach/
## BackAttach comments for the confirmed-by-observation derivation of which
## side is which). player.gd parents the held-item visual to the palm
## point specifically, so it actually rests against the palm surface
## rather than being centered inside the hand volume or hung off an
## independently-guessed shoulder offset; back_left/back_right exist for
## future pose/animation work that needs to reason about the back of the
## hand specifically. Also wrist_left/wrist_right and fingertip_left/
## fingertip_right (plain Node3Ds at the hand segment's own true logical
## boundaries along its length axis -- see _build_arm's own WristAttach/
## FingertipAttach comment for why hand's own origin is neither of those),
## and toe_left/toe_right (a plain Node3D at the
## foot's own true forward tip -- see _build_leg's own ToeAttach comment
## for the derivation -- a child of `foot` so it inherits both the foot's
## position offset and its toe-out yaw automatically), which
## blorb_suit.gd's own leg noodle routes through directly (hip -> knee ->
## ankle -> toe) instead of approximating the tip's position by hand.

# Torso, ground-up: hips are the widest-below-the-waist segment (a bit
# wider than the abdomen, per spec) but shorter than it; abdomen narrower
# than both neighbors; chest the widest segment overall.
const ABDOMEN_SIZE := Vector3(0.155, 0.12, 0.10)
# The hips' front should sit flush with the abdomen's front above it (per
# direct instruction -- the hips/waist were protruding further forward
# than the abdomen), but the BACK protrusion is the posterior and was
# never the problem -- it stays at the original symmetric depth. Since a
# SuperEgg's z is a half-depth around its own local Z=0, an asymmetric
# front/back needs a widened half-depth spanning both extents, plus a
# small backward position offset (HIP_BACK_OFFSET, applied in build()) to
# land them in the right place rather than centered.
const HIP_FRONT_DEPTH := ABDOMEN_SIZE.z
const HIP_BACK_DEPTH := 0.12  # the original, unchanged, symmetric depth
const HIP_SIZE := Vector3(0.17, 0.09, (HIP_FRONT_DEPTH + HIP_BACK_DEPTH) * 0.5)
const HIP_BACK_OFFSET := (HIP_FRONT_DEPTH - HIP_BACK_DEPTH) * 0.5
# Height (y) reduced from 0.19 per direct instruction -- brings shoulder_y
# (computed off this below) down with it, letting the arms hang and swing
# lower, which reads more natural than shoulders sitting high on a tall
# chest.
const CHEST_SIZE := Vector3(0.205, 0.15, 0.12)
## How far the abdomen's front can protrude past the chest's own front depth
## at the top of abdomen_width_scale's range -- per direct instruction, a
## broad abdomen should be allowed a slight belly out front even once its
## width and back depth are capped flush with the chest above it (see
## build()'s abdomen_front_depth/abdomen_back_depth).
const ABDOMEN_FRONT_OVERHANG_MAX := 1.12
## How much of abdomen_width_scale's broadness carries over into arm/leg
## thickness -- see build()'s limb_build_scale derivation for the full
## reasoning. A fraction, not 1:1: at abdomen_width_scale's own top of
## ~1.3, a response of 0.35 gives roughly an 11% limb-thickness increase,
## "a bit thicker," not a proportional match to the abdomen's own growth.
const LIMB_BULK_RESPONSE := 0.35

# Narrower than the original superellipsoid-head pass (per earlier direct
# instruction), then scaled up 15% overall (per direct instruction, to
# compensate visually for the chest height reduction above), then widened
# again (x: 0.085 -> 0.105, per a further direct correction -- the earlier
# narrowing had gone too far) so width now roughly matches depth instead of
# sitting well under it, then scaled up another 10% overall (per direct
# instruction, applying to everyone -- player and NPCs alike, since this
# is the shared base size every build() call starts from).
const HEAD_SIZE := Vector3(0.105, 0.125, 0.10) * 1.15 * 1.10
## Epsilon for the head's crown AND underside -- rounder than
## SuperEgg.EPSILON_SOFT (per direct instruction, "more curved"), but kept
## above 2.0 so it stays softly rounded rather than crossing into the
## pinched/star-shaped territory below that (see superegg.gd's own
## epsilon-direction note). Used for BOTH epsilon_top and epsilon_bottom in
## the head's own build_part() call below -- an earlier version kept the
## bottom at SuperEgg.EPSILON_FLAT (copied from the general torso-segment
## seam convention), which read as visibly flatter on the bottom than the
## top once the top was rounded further; per direct correction the two
## needed to match.
const HEAD_EPSILON_TOP := 2.5

## Neck -- see build()'s own neck-construction comment for the full
## derivation. HEAD_RAISE is both how much the head lifts above where it
## used to sit flush against the chest AND the neck's own logical
## (pre-overlap) length, so the two stay exactly in sync by construction.
const HEAD_RAISE := 0.01
## How far in from the chest's own back edge the neck sits -- in line with
## the spine (which runs along the back of the torso), not centered
## front-to-back, per direct instruction.
const NECK_BACK_INSET := 0.01
## Shifts the neck forward (anterior, +Z) from NECK_BACK_INSET's own
## position, per direct correction -- 0.03 initially, then another 0.03
## (0.06 total), then back 0.01 (0.05 total) to balance it properly.
const NECK_ANTERIOR_SHIFT := 0.05
## How far the neck's rendered mesh extends past its logical span into the
## head/chest on each end -- deliberately much deeper than the ordinary
## JOINT_OVERLAP used everywhere else, since the neck should visibly butt
## well up into the head and down into the thorax, not just hide a seam.
const NECK_OVERLAP := 0.06

const UPPER_ARM_SIZE := Vector3(0.05, 0.155, 0.05)
const FOREARM_SIZE := Vector3(0.045, 0.14, 0.045)
## How much wider than the arm's own half-extent (x/z) a short sleeve's cap
## mesh is, per direct instruction ("larger than the arms offset by
## 1.5cm") -- a flat constant, not scaled by build_scale, same "0.01ish =
## 1cm-ish" convention HIP_OUTWARD_SHIFT/WRIST_INWARD_ANGLE already use. See
## _build_short_sleeve for the full shape derivation.
const SLEEVE_OFFSET := 0.015
## How far past the shoulder (arm_pivot's own y=0) a short sleeve's TOP
## edge extends, per direct instruction ("extend the top of the sleeve by
## 3cm") -- the bottom hem doesn't move, only the top, same asymmetric
## extra_top-only treatment _build_overlapping_segment gives ordinary
## joints (see _build_short_sleeve for the derivation, done by hand there
## rather than via that helper since it also needs a custom epsilon_bottom
## for the flat hem, which _build_overlapping_segment doesn't expose).
const SLEEVE_TOP_EXTEND := 0.03
## Uniform scale-up applied to the whole short-sleeve cap (all of x/y/z)
## AFTER the top-extension above, per a further direct instruction ("then
## enlarge it by 12%") -- grows the mesh symmetrically around its own
## (already top-extended) center, the same effect a plain node.scale would
## have, just baked into the explicit semi_axes/position this file always
## computes directly instead of using engine-level node scale on individual
## body parts.
const SLEEVE_ENLARGE_SCALE := 1.12
## Shifts the whole short-sleeve cap straight down by this much, per a
## further direct instruction ("lower it by one cm") -- applied AFTER the
## enlarge above, so it moves the already-enlarged shape as a whole (both
## edges move down together, size unchanged), not a re-anchoring of any
## earlier step.
const SLEEVE_LOWER := 0.01
## How far past its current (lowered) bottom edge a short sleeve's BOTTOM
## extends, per a further direct instruction ("extend the bottom by 6cm")
## -- same asymmetric extra-length-on-one-end treatment SLEEVE_TOP_EXTEND
## uses, mirrored to the bottom: only the bottom edge moves (down by this
## amount), the top edge stays exactly where the prior steps left it.
## Originally 0.06 (6cm); a later direct instruction ("raise the bottom
## edge back up by 3cm") pulled it back in by 3cm, net 0.03 -- since
## raising the bottom edge by R is mathematically the exact same
## half_height/position adjustment as this constant itself, just with the
## opposite sign, that correction was folded directly into this single
## constant (0.06 - 0.03 = 0.03) rather than kept as a second, separate
## step in the build function below.
const SLEEVE_BOTTOM_EXTEND := 0.03
## How round the short sleeve's TOP is, per a further direct instruction
## ("make the top side rounder") -- supersedes the earlier "match the arm's
## own roundness" instruction (which used SuperEgg's default EPSILON_SOFT,
## 3.0). Lower epsilon reads as rounder (see this file's own class doc:
## epsilon near 2 traces a plain ellipse; higher values bow the profile out
## toward the corners, boxier), so this is BELOW EPSILON_SOFT -- same 2.5
## value HEAD_EPSILON_TOP already uses for the same "more curved than the
## default soft-rounded-cube look" request, kept above 2.0 per this file's
## own epsilon-direction warning (below 2 pinches into a star shape
## instead of rounding further).
const SLEEVE_TOP_EPSILON := 2.5
## How sharp the short sleeve's BOTTOM hem is, per a further direct
## instruction ("make the bottom edge even sharper") -- above
## EPSILON_FLAT (5.5, the "boxy" value used for torso seams elsewhere in
## this file), since epsilon has no real ceiling: it keeps bowing the
## profile further out toward the corners as it rises, asymptotically
## approaching a perfectly flat-topped cylinder (a hard 90-degree edge) as
## epsilon -> infinity. 9.0 is just a further step in that same direction,
## not a limit being hit -- raise it more if the hem should read sharper
## still.
const SLEEVE_BOTTOM_EPSILON := 9.0
## x=width(thumb-to-pinky)/2, y=height(wrist-to-fingertip)/2 -- close to x
## for a "roughly square" palm face -- z=thickness/2, notably thinner than
## either, like a real (flat) hand.
const HAND_SIZE := Vector3(0.052, 0.058, 0.028)
## How much further the thumb side reaches than the pinky side, and how
## much extra the wrist twists the thumb side inward beyond the base
## palm-orientation twist -- see _build_arm's own hand-building comments
## for the full derivation of which local direction is "thumb" and why
## these signs were chosen.
const HAND_THUMB_EXTEND := 0.02
# 1 degree (the originally-requested amount) turned out imperceptible at
# normal camera distance on a hand this size -- per direct correction,
# raised enough to actually read as a tilt.
const WRIST_INWARD_ANGLE := deg_to_rad(7.0)

## Same width as LOWER_LEG_SIZE, per direct instruction -- only the length
## (y) differs between the two leg segments now.
const UPPER_LEG_SIZE := Vector3(0.075, 0.23, 0.075)
const LOWER_LEG_SIZE := Vector3(0.075, 0.21, 0.075)
## Same stacking build() computes into its own local hip_y var (ankle_y +
## LOWER_LEG_SIZE.y*2 + UPPER_LEG_SIZE.y*2) -- exposed here as a real const,
## rather than staying build()-local, because player.gd's own Manchego-seat
## pose math (see start_riding_manchego()'s own comment) needs to know
## exactly where the hip pivot -- and the flush-against-it bottom edge of
## the pelvis mesh, see build()'s own "hips.position = Vector3(0, hip_y +
## hip_size.y, ...)" -- sits, in this rig's own unscaled local units,
## without duplicating this formula a second place.
const HIP_PIVOT_Y := FOOT_SIZE.y * 2.0 + LOWER_LEG_SIZE.y * 2.0 + UPPER_LEG_SIZE.y * 2.0
## x=width/2 (widened -- read as too narrow at the previous value), y=
## height/2 (small -- flat like a real foot), z=length/2 (the largest
## axis -- feet extend forward, not round underfoot).
const FOOT_SIZE := Vector3(0.07, 0.035, 0.13)

## Real feet aren't perfectly parallel -- a small fixed outward yaw on each
## foot, per direct instruction. Static (built once, not animated), unlike
## every other angle in this file. 1 degree (the originally-requested
## amount) turned out imperceptible at normal camera distance on a foot
## this size -- per direct correction, raised enough to actually read.
const TOE_OUT_ANGLE := deg_to_rad(7.0)

## Small constant outward tilt for both arms and legs, per direct
## instruction -- needed so the blorb suit's own added bulk (see
## blorb_suit.gd) doesn't read as the limbs crowding in against the body/
## each other. Reuses the SAME "rotation.z = side * angle is outward" sign
## player.gd's own idle contrapposto (IDLE_HIP_OUTWARD_ANGLE) already
## confirmed by direct observation for the leg pivot specifically -- not
## independently re-verified here for the ARM pivot, so if the arms read
## as tilting INWARD instead, negate ARM_OUTWARD_ANGLE's sign at its one
## use site in _build_arm. The subtle original angles were overwhelmed by
## the animated limbs and read as crowding inward, so both are intentionally
## large enough to remain visible in idle, walk, and run silhouettes.
const ARM_OUTWARD_ANGLE := deg_to_rad(8.0)
const LEG_OUTWARD_ANGLE := deg_to_rad(2.0)
## 1cm further out than HIP_X's own base 0.55 fraction, per direct
## instruction ("shift the hip nodes another centimeter outwards") -- same
## "0.01 = 1cm" convention figure_hair.gd's own FLAT_TOP_BACK_SHIFT/
## HERO_UP_SHIFT use.
const HIP_OUTWARD_SHIFT := 0.01

const JOINT_OVERLAP := 0.02
## Much larger than JOINT_OVERLAP on purpose: the thigh should visibly
## extend up into the hip volume, not just avoid a pinch where they meet.
const HIP_SOCKET_EMBED := 0.06

# Bumped up from an initial pass that used the same numbers but tied to
# swing *position* (sin(phase)) instead of swing *velocity* (cos(phase))
# -- peaking in sync with the swing itself made the bend read as barely
# distinguishable from the swing alone even at these amounts. Velocity-
# based timing (see player.gd/npc.gd's _animate_walk) makes the bend
# visually distinct from the swing, so it can afford to be clearer too.
const KNEE_BEND_AMOUNT := 0.55  # radians (~31 degrees)
# Raised per direct correction -- the elbow's bend already peaked at the
# swing's forward apex (see player.gd/npc.gd's _animate_walk, timed via
# abs(sin(phase))), but the amount there read as too subtle; the apex is
# confirmed as the right moment for it, it just needed to bend further at
# that moment.
const ELBOW_BEND_AMOUNT := 0.72  # radians (~41 degrees)

# How far the upper body (spine_pivot -- abdomen/chest/head/arms) sinks
# below its resting height at the point in the walk cycle where the legs
# are most spread apart (real gait: hip height is highest when the
# supporting leg is roughly vertical, lowest when the legs are scissored
# apart), easing back to full height exactly when the legs cross beneath --
# per direct instruction, a subtle realism touch, not a visible bob. Shared
# by player.gd/npc.gd's walk cycles; running uses its own larger, different-
# shaped bob (see player.gd's RUN_BODY_BOB_AMOUNT) since a run's flight
# phase is a distinct motion, not just a faster walk dip.
const WALK_BODY_DIP_AMOUNT := 0.006

const SKIN_COLOR := Color(0.85, 0.68, 0.52)

## build()'s sleeve_style options -- LONG covers the whole arm in
## shirt_color (the old default `sleeveless=false` behavior); NONE leaves
## the whole arm skin_color with no separate mesh, like bare arms (the old
## `sleeveless=true`); SHORT is a newer third option: bare skin_color arms
## like NONE, plus a separate short-sleeve cap mesh over the top half of
## the upper arm only -- see _build_arm's own sleeve-building comment for
## the shape/sizing derivation.
const SLEEVE_STYLE_LONG := "long"
const SLEEVE_STYLE_SHORT := "short"
const SLEEVE_STYLE_NONE := "sleeveless"


## skin_color/scale let town_generator.gd give NPCs some visual variety
## (replacing the old per-variant GLB/scale picks) without needing a
## second full rig implementation. shirt_color covers the chest/abdomen
## (and the arms too, when sleeve_style is SLEEVE_STYLE_LONG -- otherwise
## the arms are skin_color instead, like bare arms, with SLEEVE_STYLE_SHORT
## additionally adding a shirt_color sleeve cap mesh over just the top half
## of the upper arm); pants_color covers the hips and legs. shoe_color is
## optional and defaults to pants_color, preserving the uniform trouser-and-
## shoe look for callers that do not specify it. Both clothing colors default
## to skin_color, which reads as no clothing at all (a uniform-toned figure).
##
## chest_build_scale/hip_build_scale/abdomen_width_scale vary body WIDTH/
## DEPTH only (never height -- the vertical stacking below is computed
## from the unscaled *_SIZE consts' own .y components throughout, so these
## never disturb where anything ends up standing) -- per direct
## instruction, everyone defaulted to the same skinny build.
## abdomen_width_scale gets a much wider range than the other two
## deliberately: 1.0 (this file's own base ABDOMEN_SIZE) is the *narrow*
## end of the range, never scaled down further, broadening up from there;
## chest_build_scale/hip_build_scale are each a smaller, subtler variation
## around 1.0 in both directions. The actual ranges live in
## town_generator.gd's NPC_*_BUILD_SCALES/NPC_ABDOMEN_WIDTH_SCALES; all
## three simply default to 1.0 (this file's base proportions) for any
## caller -- e.g. the player -- that doesn't care about this.
##
## chest_build_scale and hip_build_scale are deliberately SEPARATE knobs
## (an earlier version used one shared build_scale for both), per direct
## instruction: chest broadness and hip broadness need to vary
## independently (e.g. broad chests only for some NPCs, wider hips only
## for others) rather than always moving together. Leg width always
## tracks hip_build_scale specifically (not its own independent scale, and
## not chest_build_scale) -- per direct instruction, "the width of the
## upper leg nodes should correspond to the width of the hip segment
## always." Arm width tracks chest_build_scale instead, which was already
## implicitly true before this split (arms hang off the shoulder/chest).
static func build(
	parent: Node3D,
	skin_color: Color = SKIN_COLOR,
	shirt_color: Color = SKIN_COLOR,
	pants_color: Color = SKIN_COLOR,
	sleeve_style: String = SLEEVE_STYLE_LONG,
	scale: float = 1.0,
	chest_build_scale: float = 1.0,
	hip_build_scale: float = 1.0,
	abdomen_width_scale: float = 1.0,
	chest_emblem_color: Color = Color(0.0, 0.0, 0.0, 0.0),
	hair_color: Color = FigureHair.DEFAULT_HAIR_COLOR,
	hair_style: String = FigureHair.STYLE_BUZZCUT,
	hair_length_variance: float = 0.0,
	shoe_color: Color = Color(0.0, 0.0, 0.0, 0.0),
	skeleton_mode: bool = false,
	has_glasses: bool = false,
	leg_thickness_scale: float = 1.0,
	has_ears: bool = true,
	hand_color_override: Color = Color(0.0, 0.0, 0.0, 0.0)
) -> Dictionary:
	var arm_color := shirt_color if sleeve_style == SLEEVE_STYLE_LONG else skin_color
	var hand_color: Color = skin_color if is_zero_approx(hand_color_override.a) else hand_color_override
	var resolved_shoe_color := pants_color if is_zero_approx(shoe_color.a) else shoe_color

	var rig := Node3D.new()
	rig.name = "ProceduralFigure"
	rig.scale = Vector3.ONE * scale
	parent.add_child(rig)

	# Width/depth only, per the note above -- .y (height) always comes
	# straight from the unscaled consts.
	#
	# Chest: widening for a burlier build (chest_build_scale > 1.0) should
	# read as a broader chest and a fuller front, not spreading backward
	# into where the spine itself runs -- per direct instruction, the back
	# stays anchored at the base depth and only the front (and width, which
	# already scales via chest_build_scale on chest_size.x) grows past it.
	# Below 1.0, front and back still shrink together symmetrically (no
	# special-casing a narrower build) -- only the burly direction is
	# restrained on the back.
	var chest_back_depth := CHEST_SIZE.z * minf(chest_build_scale, 1.0)
	var chest_front_depth := CHEST_SIZE.z * chest_build_scale
	var chest_size := Vector3(
		CHEST_SIZE.x * chest_build_scale, CHEST_SIZE.y, (chest_front_depth + chest_back_depth) * 0.5
	)
	var chest_z_offset := (chest_front_depth - chest_back_depth) * 0.5

	# Abdomen: width and back depth are both capped at the chest's own
	# dimensions (computed above) so the broadest abdomen still reads as
	# flush with the chest above it, never bulging past it -- per direct
	# correction, the top of NPC_ABDOMEN_WIDTH_SCALES was visibly wider and
	# deeper-in-back than the chest. Front depth is allowed a small overhang
	# past the chest's own front (ABDOMEN_FRONT_OVERHANG_MAX) -- a slight
	# belly, not a flat match -- since only the back and sides need to stay
	# flush.
	var abdomen_x := minf(ABDOMEN_SIZE.x * abdomen_width_scale, chest_size.x)
	var abdomen_back_depth := minf(ABDOMEN_SIZE.z * abdomen_width_scale, chest_size.z)
	var abdomen_front_depth := minf(
		ABDOMEN_SIZE.z * abdomen_width_scale, chest_size.z * ABDOMEN_FRONT_OVERHANG_MAX
	)
	var abdomen_size := Vector3(
		abdomen_x, ABDOMEN_SIZE.y, (abdomen_front_depth + abdomen_back_depth) * 0.5
	)
	var abdomen_z_offset := (abdomen_front_depth - abdomen_back_depth) * 0.5

	# The hips' front still needs to land flush with the abdomen's actual
	# front above it, and the back (posterior) scales with hip_build_scale
	# -- same asymmetric-depth derivation HIP_SIZE/HIP_BACK_OFFSET use, just
	# computed per-instance now that the abdomen's own front depth isn't a
	# fixed const either.
	var hip_front_depth := abdomen_front_depth
	var hip_back_depth := HIP_BACK_DEPTH * hip_build_scale
	var hip_size := Vector3(
		HIP_SIZE.x * hip_build_scale, HIP_SIZE.y, (hip_front_depth + hip_back_depth) * 0.5
	)
	var hip_back_offset := (hip_front_depth - hip_back_depth) * 0.5

	# Ground-up placement, all as height above y=0 (the rig's own
	# feet-on-the-ground reference -- player.gd/npc.gd already handle the
	# small FOOT_OFFSET/terrain-snap separately, this only needs internal
	# consistency).
	var ankle_y := FOOT_SIZE.y * 2.0
	var knee_y := ankle_y + LOWER_LEG_SIZE.y * 2.0
	var hip_y := knee_y + UPPER_LEG_SIZE.y * 2.0

	var hips := SuperEgg.build_part(hip_size, pants_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	hips.position = Vector3(0, hip_y + hip_size.y, hip_back_offset)
	rig.add_child(hips)

	# Everything from the abdomen up (abdomen, chest, head, arms) hangs off
	# a dedicated spine pivot instead of attaching to `rig` directly, so
	# player.gd/npc.gd can lean just the upper body forward while walking
	# (a real person's spine tilts a little; their hips/legs don't) without
	# tilting the legs too. Legs stay parented straight to `rig` below,
	# unaffected by the spine's own rotation.
	#
	# All the *_y values below still stay in the SAME rig-absolute terms
	# they always have (so this reads no differently from before) --
	# spine_pivot.position.y = abdomen_y is what makes a child positioned
	# at (absolute_y - abdomen_y) land at the correct absolute height once
	# it's actually a child of spine_pivot instead of rig.
	var abdomen_y := hip_y + hip_size.y * 2.0
	var spine_pivot := Node3D.new()
	spine_pivot.name = "SpinePivot"
	spine_pivot.position = Vector3(0, abdomen_y, 0)
	rig.add_child(spine_pivot)
	# An identity thorax pivot lets authored poses distribute axial rotation
	# naturally between the waist and ribcage. The abdomen remains attached to
	# SpinePivot; chest, shoulders, neck and head travel with this upper stage.
	var thorax_pivot := Node3D.new()
	thorax_pivot.name = "ThoraxPivot"
	spine_pivot.add_child(thorax_pivot)

	if skeleton_mode:
		build_spine_column(spine_pivot, abdomen_size, shirt_color, abdomen_z_offset)
	else:
		var abdomen := SuperEgg.build_part(abdomen_size, shirt_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		abdomen.position = Vector3(0, abdomen_size.y, abdomen_z_offset)
		spine_pivot.add_child(abdomen)

	var chest_y := abdomen_y + abdomen_size.y * 2.0
	# EPSILON_SOFT on top, not EPSILON_FLAT -- since SuperEgg's equatorial
	# (side) shaping always follows epsilon_top too, a flat top also meant
	# flat/boxy sides, per direct instruction the chest should read as
	# more generously rounded. Bottom stays EPSILON_FLAT for a flush seam
	# against the abdomen below.
	var chest := SuperEgg.build_part(chest_size, shirt_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	chest.position = Vector3(0, chest_y - abdomen_y + chest_size.y, chest_z_offset)
	thorax_pivot.add_child(chest)
	# Alpha 0 (the default) means "no emblem" -- most callers (every NPC)
	# don't want one; per direct instruction this is opt-in per build() call.
	if chest_emblem_color.a > 0.0:
		FigureEmblem.add_chest_emblem(chest, chest_size, chest_emblem_color)

	var neck_y := chest_y + chest_size.y * 2.0
	var total_height := neck_y + HEAD_SIZE.y * 2.0 + HEAD_RAISE
	# Net ~2% of total height below where it'd otherwise sit (a bit below
	# the very top of the chest) -- originally dropped 4% per direct
	# instruction to let the arms hang and swing lower, then raised back
	# up 2% per a direct follow-up correction (net: 2% lower than the
	# original, not 4%).
	var shoulder_y := chest_y + chest_size.y * 1.6 - total_height * 0.02

	# Neck: a SuperEgg about an arm's thickness (UPPER_ARM_SIZE.x/z), per
	# direct instruction. Its LOGICAL (pre-overlap) span exactly bridges
	# the gap HEAD_RAISE creates between the chest's top and the raised
	# head's bottom, but NECK_OVERLAP -- much deeper than the ordinary
	# JOINT_OVERLAP used elsewhere -- extends the rendered mesh well past
	# that on both ends, per a direct correction: the neck should visibly
	# butt way up into the head and down into the thorax, not just hide a
	# seam the way an elbow/knee's overlap does. Sits NECK_BACK_INSET in
	# from the chest's own back edge (not centered front-to-back) since a
	# real neck rises roughly in line with the spine, which runs along the
	# back of the torso, not its center -- then shifted forward
	# (anterior) by NECK_ANTERIOR_SHIFT on top of that, per a further
	# direct correction.
	var neck_logical_half_height := HEAD_RAISE * 0.5
	var neck_render_half_height := neck_logical_half_height + NECK_OVERLAP
	# Thickness (not position -- see neck_back_z below) tracks chest_build_
	# scale, same knob skeleton_mode already passes low to get skinny limbs
	# elsewhere -- a skeleton's neck reads visibly thinner than a normal
	# NPC's without a dedicated new parameter, while normal callers (build_
	# scale 1.0) render identically to before.
	var neck_size := Vector3(
		UPPER_ARM_SIZE.x * chest_build_scale, neck_render_half_height,
		UPPER_ARM_SIZE.z * chest_build_scale
	)
	# Per direct need (player.gd's own Manchego-seated-pose head/neck
	# counter-tilt, see that file's own comment): a real pivot at the base
	# of the neck, not just a static mesh -- lets a caller split a
	# compensating rotation between "base of neck" and "base of skull"
	# (head_pivot below) the same way HorseFigure/manchego.gd already split
	# look-yaw between the horse's own neck and head. Defaults to zero
	# rotation everywhere except that one caller, so this is a pure no-op
	# for every existing walk/jump/swim/idle pose: inserting an
	# identity-transform node between spine_pivot and head_pivot/the neck
	# mesh doesn't change either one's resulting GLOBAL transform at all,
	# only where in the chain a future rotation can be applied.
	var neck_pivot := Node3D.new()
	neck_pivot.name = "NeckPivot"
	neck_pivot.position = Vector3(0, neck_y - abdomen_y, 0)
	thorax_pivot.add_child(neck_pivot)

	var neck_local_y := neck_logical_half_height
	# NECK_BACK_INSET describes where the neck's own BACK SURFACE sits
	# (1cm in from the chest's back edge), not its center -- an earlier
	# version placed the center there instead, which (since the neck's own
	# half-thickness, neck_size.z, wasn't accounted for) let the back HALF
	# of the neck stick out well behind the chest into empty space, plainly
	# visible from behind. Adding neck_size.z shifts from that back-surface
	# reference to the center position build_part() actually needs.
	#
	# Anchored to CHEST_SIZE.z (the constant, unscaled) rather than
	# chest_back_depth (the actual, possibly-scaled depth) -- per a direct
	# bug report, using the scaled depth let a low chest_build_scale (see
	# skeleton_mode's thin torso) drag this same reference point forward
	# along with the thinner chest, which pushed the whole neck's anterior
	# face past the head's own center and out under the chin. The neck's
	# anatomical anchor shouldn't drift just because the chest it's next to
	# got narrower; only its own thickness (neck_size, above) should.
	var neck_back_z := -CHEST_SIZE.z + NECK_BACK_INSET
	var neck_z := neck_back_z + neck_size.z + NECK_ANTERIOR_SHIFT
	var neck := SuperEgg.build_part(neck_size, skin_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	neck.position = Vector3(0, neck_local_y, neck_z)
	neck_pivot.add_child(neck)

	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	# Raised HEAD_RAISE above where it used to sit flush with the chest top
	# (see the neck above, built to exactly fill this same gap), but Z is
	# back to the original 0 (front-to-back rig-center, not the neck's own
	# Z) per a direct correction: an earlier version centered head_pivot on
	# the neck instead, which dragged the whole head noticeably backward
	# with it (plainly visible in-game) rather than keeping it where it
	# anatomically belongs. The head stays where it always sat -- back
	# roughly flush with the chest's own back edge -- while the neck (see
	# above, offset via NECK_BACK_INSET) sits behind the head's own center,
	# not flush with the chest's back either. That's the anatomically
	# correct relationship: the neck sits back-of-center on BOTH the thorax
	# and the head, never exactly flush with either.
	#
	# Now a child of neck_pivot (was spine_pivot directly) -- see
	# neck_pivot's own comment. Position re-expressed relative to
	# neck_pivot's new origin (neck_y - abdomen_y, subtracted out here),
	# leaving just HEAD_RAISE -- numerically identical resulting world
	# position, since neck_pivot itself defaults to zero rotation.
	head_pivot.position = Vector3(0, HEAD_RAISE, 0)
	neck_pivot.add_child(head_pivot)
	var head_mesh := SuperEgg.build_part(HEAD_SIZE, skin_color, HEAD_EPSILON_TOP, HEAD_EPSILON_TOP)
	head_mesh.position = Vector3(0, HEAD_SIZE.y, 0)
	head_pivot.add_child(head_mesh)
	var eyes := FigureEyes.add_eyes(head_mesh, HEAD_SIZE, skin_color)
	if not skeleton_mode and has_ears:
		FigureEars.add_ears(head_mesh, HEAD_SIZE, skin_color)
	if not skeleton_mode:
		FigureHair.add_hair(
			head_mesh, HEAD_SIZE, HEAD_EPSILON_TOP, hair_color, hair_style, hair_length_variance
		)
		if has_glasses:
			FigureGlasses.add_glasses(head_mesh, HEAD_SIZE)

	# A chunkier abdomen should carry through to visibly thicker arms/legs
	# to match that build, not just a wider middle on otherwise-unchanged
	# limbs -- per direct instruction. LIMB_BULK_RESPONSE is a fraction,
	# not 1:1: abdomen_width_scale's full range (1.0 floor to noticeably
	# broader for the chunkiest NPCs) only carries a portion of that width
	# into limb thickness. Multiplies each limb's own build scale (rather
	# than replacing it) and only affects the arm/leg calls below, not
	# chest_size/hip_size/abdomen_size above -- those alone still govern
	# the torso exactly as before.
	#
	# Arms track chest_build_scale, legs track hip_build_scale -- per
	# direct instruction ("the width of the upper leg nodes should
	# correspond to the width of the hip segment always"), not a single
	# shared limb scale the way both used to.
	var limb_bulk_bonus := 1.0 + (abdomen_width_scale - 1.0) * LIMB_BULK_RESPONSE
	var arm_build_scale := chest_build_scale * limb_bulk_bonus
	var leg_build_scale := hip_build_scale * limb_bulk_bonus

	# side=+1.0 for "left", -1.0 for "right" here -- SWAPPED from the
	# opposite, more intuitive-looking pairing, per direct correction. The
	# `side` parameter's own sign conventions everywhere downstream
	# (shoulder_x/hip_x, ARM_OUTWARD_ANGLE, TOE_OUT_ANGLE, the hand's wrist-
	# twist direction, everything) are all still exactly as originally
	# built and internally self-consistent -- swapping which named variable
	# (arm_left vs arm_right) receives which side value doesn't touch any
	# of that geometry, it only corrects which physical side each NAME
	# refers to. Confirmed backwards by direct report on the blorb-suit
	# paper-doll (clicking the region showing his right leg equipped the
	# blorb onto his actual left leg) -- traced through equip_to_slot() ->
	# BlorbSuit.rebuild_slot()'s own slot->pivot-key match (clean, no bug
	# there) -> player.gd's pivots["leg_right"] assignment (clean, a direct
	# pass-through) -> here, the actual construction, where the "leg_right"
	# key was always being built from side=+1.0 while that geometric side
	# was never verified against true anatomical right in the first place
	# (unlike e.g. procedural_figure.gd's own PalmAttach Z-sign, which WAS
	# confirmed this way). See the figure-rig skill's own note on this --
	# recorded there since it's exactly the kind of hard-to-notice mistake
	# that skill exists to flag for future rig work.
	var arm_right := _build_arm(thorax_pivot, chest_size, shoulder_y - abdomen_y, -1.0, arm_color, hand_color, arm_build_scale, sleeve_style, shirt_color)
	var arm_left := _build_arm(thorax_pivot, chest_size, shoulder_y - abdomen_y, 1.0, arm_color, hand_color, arm_build_scale, sleeve_style, shirt_color)
	var leg_right := _build_leg(rig, hip_size, hip_y, -1.0, pants_color, resolved_shoe_color, leg_build_scale, leg_thickness_scale)
	var leg_left := _build_leg(rig, hip_size, hip_y, 1.0, pants_color, resolved_shoe_color, leg_build_scale, leg_thickness_scale)

	return {
		"spine": spine_pivot,
		"thorax": thorax_pivot,
		"neck": neck_pivot,
		"head": head_pivot,
		"head_mesh": head_mesh,
		"eyes": eyes,
		"hips": hips,
		"arm_left": arm_left["pivot"],
		"arm_right": arm_right["pivot"],
		"elbow_left": arm_left["joint"],
		"elbow_right": arm_right["joint"],
		"leg_left": leg_left["pivot"],
		"leg_right": leg_right["pivot"],
		"knee_left": leg_left["joint"],
		"knee_right": leg_right["joint"],
		"ankle_left": leg_left["ankle"],
		"ankle_right": leg_right["ankle"],
		"toe_left": leg_left["toe"],
		"toe_right": leg_right["toe"],
		"hand_left": arm_left["hand"],
		"hand_right": arm_right["hand"],
		"palm_left": arm_left["palm"],
		"palm_right": arm_right["palm"],
		"back_left": arm_left["back"],
		"back_right": arm_right["back"],
		"wrist_left": arm_left["wrist"],
		"wrist_right": arm_right["wrist"],
		"fingertip_left": arm_left["fingertip"],
		"fingertip_right": arm_right["fingertip"],
	}


## Skeleton-mode replacement for the single abdomen box: a short stack of
## small SuperEgg segments standing in for a visible spine, running through
## the same vertical span the abdomen would otherwise occupy but offset
## toward the back (-Z) and each tilted back slightly, since a real spine
## runs along the back of the torso rather than through its center.
##
## Public (not "_"-prefixed) since ape_template.gd's own skeleton_mode
## support (see that file's "skeleton_mode" variant key) reuses this
## directly rather than re-deriving the same geometry independently --
## ApeTemplate.build() can't safely pass skeleton_mode down into its own
## inner build() call here (doing so would replace the single abdomen mesh
## its own reparenting logic indexes by child position, breaking that
## indexing), so it instead builds its ordinary single-mesh abdomen first,
## reads that mesh's own real size/offset back out, frees it, and calls
## this directly in its place -- see that file's own comment where it does.
static func build_spine_column(
	spine_pivot: Node3D, abdomen_size: Vector3, bone_color: Color, abdomen_z_offset: float
) -> void:
	var segment_count := 5
	var total_height := abdomen_size.y * 2.0
	var segment_height := total_height / float(segment_count)
	var segment_size := Vector3(abdomen_size.x * 0.35, segment_height * 0.5, abdomen_size.z * 0.5)
	var spine_z := abdomen_z_offset - abdomen_size.z * 0.5
	for i in range(segment_count):
		var segment := SuperEgg.build_part(
			segment_size, bone_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		segment.position = Vector3(0, segment_height * (float(i) + 0.5), spine_z)
		segment.rotation.x = deg_to_rad(-6.0)
		spine_pivot.add_child(segment)


static func _build_arm(
	rig: Node3D, chest_size: Vector3, shoulder_y: float, side: float,
	arm_color: Color, hand_color: Color, build_scale: float,
	sleeve_style: String = SLEEVE_STYLE_LONG, sleeve_color: Color = SKIN_COLOR
) -> Dictionary:
	var upper_arm_size := _scaled_xz(UPPER_ARM_SIZE, build_scale)
	var forearm_size := _scaled_xz(FOREARM_SIZE, build_scale)
	var hand_size := _scaled_xz(HAND_SIZE, build_scale)

	# On the outside of the chest, per direct instruction -- a visible
	# pinch where the (rounded) upper arm meets the (flat-sided) chest is
	# fine here, unlike the other joints _build_overlapping_segment()
	# still smooths over.
	var shoulder_x := side * (chest_size.x + upper_arm_size.x * 0.5)

	var arm_pivot := Node3D.new()
	arm_pivot.name = "ArmPivot"
	arm_pivot.position = Vector3(shoulder_x, shoulder_y, 0)
	# Safe to bake directly onto arm_pivot's own rotation.z (unlike the leg
	# pivot below, see _build_leg's own LegTilt node) -- neither player.gd
	# nor npc.gd ever animate that axis on an arm pivot, only rotation.x
	# for the walk/jump swing.
	arm_pivot.rotation.z = side * ARM_OUTWARD_ANGLE
	rig.add_child(arm_pivot)

	_build_overlapping_segment(arm_pivot, upper_arm_size, arm_color, 0.0, JOINT_OVERLAP, JOINT_OVERLAP)
	if sleeve_style == SLEEVE_STYLE_SHORT:
		_build_short_sleeve(arm_pivot, upper_arm_size, sleeve_color)
	var elbow_y := -upper_arm_size.y * 2.0

	var elbow_pivot := Node3D.new()
	elbow_pivot.name = "ElbowPivot"
	elbow_pivot.position = Vector3(0, elbow_y, 0)
	arm_pivot.add_child(elbow_pivot)

	_build_overlapping_segment(elbow_pivot, forearm_size, arm_color, 0.0, JOINT_OVERLAP, JOINT_OVERLAP)
	var hand_y := -forearm_size.y * 2.0
	# Hands are always skin-colored (bare hands), independent of sleeve
	# length -- hand_color is passed separately from arm_color for exactly
	# this reason.
	#
	# A one-sided "thumb reaches further than the pinky" asymmetry (per an
	# earlier direct instruction) turned out to be the wrong tool here: the
	# same asymmetric-extent-plus-offset technique the torso's front/back
	# depth uses (see build()'s abdomen_front_depth/abdomen_back_depth)
	# shifts the segment's whole POSITION, not just its shape -- fine for
	# the torso (nothing else needs to stay centered relative to it), but
	# for a hand it visibly dragged the entire hand sideways off the
	# forearm's own centerline (elbow_pivot's local x=0), reported as
	# "hands positioned to the outside." Per direct correction, back to a
	# hand that's centered on the forearm -- HAND_THUMB_EXTEND still widens
	# it, just symmetrically on both sides (no offset), rather than
	# genuinely favoring one edge. Real one-sided asymmetry while staying
	# centered isn't achievable with a single symmetric SuperEgg build_part
	# call; would need a more involved construction if that's wanted later.
	var hand_half_width := hand_size.x + HAND_THUMB_EXTEND * 0.5
	var hand_render_size := Vector3(hand_half_width, hand_size.y, hand_size.z)
	var hand := _build_overlapping_segment(
		elbow_pivot, hand_render_size, hand_color, hand_y, JOINT_OVERLAP, 0.0
	)
	# HAND_SIZE's own thickness axis (z) starts out facing forward/back
	# (local Z, unrotated) -- reading as the palm facing backward, per
	# direct correction. Twisting 90 degrees around the (vertical) arm's
	# own Y axis turns that thickness-facing direction to point sideways
	# instead: toward the body's centerline for each arm (mirrored by
	# side, so the two hands face each other) rather than forward/back.
	# WRIST_INWARD_ANGLE adds a further small twist in the SAME direction
	# (per direct instruction: tilt the thumb side in towards the body) --
	# `-side * (PI*0.5 + angle)` is more negative than -side*PI*0.5 for the
	# right hand and more positive for the left, both of which (worked out
	# the same way as the base 90-degree twist above) swing the thumb side
	# slightly toward the body's centerline rather than away from it.
	hand.rotation.y = -side * (PI * 0.5 + WRIST_INWARD_ANGLE)

	# A real attachment point sitting ON the palm's own surface, not the
	# hand volume's center -- per direct correction, a held item parented
	# to the hand's own origin (the earlier version) sits buried inside the
	# hand mesh instead of resting against it. Palm is a plain Node3D child
	# of `hand`, so it inherits the hand's own rotation.y twist (including
	# WRIST_INWARD_ANGLE above) automatically -- no separate rotation math
	# needed here.
	#
	# Position sign (Z): an initial pass read the comment right above this
	# ("the thickness axis... reading as the palm facing backward" -- a
	# description of an old BUG being fixed by the twist, not a clean
	# statement of which raw local axis is which) as meaning palm = -Z, and
	# placed this at -hand_size.z. Confirmed backwards by direct
	# observation: a held item showed up embedded in and emerging from the
	# BACK of the hand, not resting on the palm. +hand_size.z is the
	# actually-confirmed palm side.
	#
	# Position (Y): every segment in this arm chain stacks toward the
	# fingers along -Y within its own local space (see elbow_y/hand_y right
	# above -- both negative, "further down the chain" always more
	# negative), so Y=0 (this node's original placement) sits at the hand
	# segment's own vertical center, not specifically near the wrist -- but
	# per direct correction it read as sitting almost up at the wrist in
	# practice, so nudged 0.025 (2.5cm, this project's real-world-ish scale)
	# further toward the fingers, i.e. more negative.
	var palm := Node3D.new()
	palm.name = "PalmAttach"
	palm.position = Vector3(0, -0.025, hand_size.z)
	hand.add_child(palm)

	# Mirror of PalmAttach on the hand's opposite face -- per direct
	# instruction, a marker for future pose/animation work (e.g. resting
	# something on the back of the hand, or reasoning about which way the
	# back of the hand faces mid-pose) that needs the same "already
	# confirmed, don't re-derive" treatment PalmAttach itself got. Same Y
	# nudge as PalmAttach for consistency (both sit at the same height
	# along the hand, just opposite faces), negated Z since -hand_size.z is
	# the confirmed back-of-hand side (see PalmAttach's own comment above
	# for the derivation).
	var back := Node3D.new()
	back.name = "BackAttach"
	back.position = Vector3(0, -0.025, -hand_size.z)
	hand.add_child(back)

	# `hand`'s OWN origin sits at the rendered segment's CENTER (see
	# _build_overlapping_segment's own half_height/top_y math), not at the
	# wrist -- a caller that assumed otherwise (blorb_suit.gd's own arm
	# noodle originally did) ends up anchoring "the wrist" a couple
	# centimeters down toward the fingers, and everything downstream of
	# that (its own guessed fingertip point, in turn) drifts even further,
	# reported as eyes landing near the fingertips instead of the back of
	# the hand. These two explicit markers replace that guesswork.
	# WristAttach subtracts back out the JOINT_OVERLAP this segment's own
	# top edge was extended by (see the _build_overlapping_segment call
	# above: extra_top=JOINT_OVERLAP, extra_bottom=0.0) to land on the true
	# logical boundary, not the overlap-extended render edge;
	# FingertipAttach doesn't need that correction since extra_bottom is 0
	# there, so the render edge already IS the logical edge.
	var wrist := Node3D.new()
	wrist.name = "WristAttach"
	wrist.position = Vector3(0, hand_size.y - JOINT_OVERLAP * 0.5, 0)
	hand.add_child(wrist)

	var fingertip := Node3D.new()
	fingertip.name = "FingertipAttach"
	fingertip.position = Vector3(0, -(hand_size.y + JOINT_OVERLAP * 0.5), 0)
	hand.add_child(fingertip)

	return {
		"pivot": arm_pivot, "joint": elbow_pivot, "hand": hand, "palm": palm, "back": back,
		"wrist": wrist, "fingertip": fingertip,
	}


## Short-sleeve cap mesh for sleeve_style == SLEEVE_STYLE_SHORT, a child of
## arm_pivot alongside (not replacing) the bare-skin upper arm segment
## _build_arm already built just above this call. Base shape per direct
## instruction: half the upper arm's own logical length, wider than the arm
## by SLEEVE_OFFSET on both x/z, round on top to match the arm's own
## SuperEgg roundness, flat-edged on the bottom -- then reshaped by four
## further direct instructions applied in order below: top extended by
## SLEEVE_TOP_EXTEND, whole cap enlarged by SLEEVE_ENLARGE_SCALE, whole cap
## lowered by SLEEVE_LOWER, bottom extended by SLEEVE_BOTTOM_EXTEND. Order
## matters -- each step below acts on whatever the previous step left
## behind, not on the original base shape.
##
## Length: upper_arm_size.y is the arm's own HALF-length (every *_SIZE
## const in this file is a half-extent, per SuperEgg's semi_axes
## convention), so the arm's full logical length is upper_arm_size.y * 2
## and half of that is upper_arm_size.y -- the sleeve's own base FULL
## length before any of the steps below, i.e. sleeve_half_height =
## upper_arm_size.y * 0.5.
##
## Base position: sits flush against the shoulder, i.e. from arm_pivot's
## own y=0 (the same top the upper arm segment itself starts from)
## downward. No overlap treatment the way _build_overlapping_segment gives
## ordinary joints -- the shoulder already accepts a visible pinch by
## design (see this file's own class doc), and this mesh's bottom edge is
## a deliberate flat hem to show, not a pinch to bury in overlap.
##
## 1. Top extend: SLEEVE_TOP_EXTEND is added to the render half-height and
## the center shifted up by half that amount -- the same asymmetric-extent
## math _build_overlapping_segment uses (extra_top only, extra_bottom=0),
## worked out by hand here since that helper doesn't expose per-end
## epsilon. Moves ONLY the top edge (up past the shoulder); the bottom hem
## stays exactly where the base shape put it.
##
## 2. Enlarge: SLEEVE_ENLARGE_SCALE multiplies the resulting size (x, the
## extended half-height, and z) uniformly, position unchanged -- grows the
## whole cap symmetrically around its own (already top-extended) center, so
## this step moves BOTH edges outward again, on top of the top-only move
## in step 1.
##
## 3. Lower: SLEEVE_LOWER subtracts from the center position directly, size
## unchanged -- shifts the already-enlarged cap straight down as a rigid
## whole (both edges move down together by the same amount).
##
## 4. Bottom extend: SLEEVE_BOTTOM_EXTEND is added to the half-height and
## the center shifted DOWN by half that amount -- the mirror-image of step
## 1's math, extra length on the bottom end instead of the top. Moves ONLY
## the bottom edge (further down); the top edge stays exactly where steps
## 1-3 left it.
##
## Roundness: epsilon_top uses SLEEVE_TOP_EPSILON -- originally matched the
## upper arm segment's own top (SuperEgg's default EPSILON_SOFT) per direct
## instruction, but a later direct instruction ("make the top side
## rounder") deliberately broke that match; see SLEEVE_TOP_EPSILON's own
## comment. epsilon_bottom uses SLEEVE_BOTTOM_EPSILON for the flat hem --
## started at EPSILON_FLAT (5.5, the general torso-seam flat value) per
## direct instruction, then raised further per a later direct instruction
## ("make the bottom edge even sharper"); see SLEEVE_BOTTOM_EPSILON's own
## comment for why that's a dial, not a hard limit.
static func _build_short_sleeve(arm_pivot: Node3D, upper_arm_size: Vector3, sleeve_color: Color) -> void:
	var sleeve_half_height := upper_arm_size.y * 0.5
	var half_height := sleeve_half_height + SLEEVE_TOP_EXTEND * 0.5
	var position_y := SLEEVE_TOP_EXTEND * 0.5 - sleeve_half_height
	half_height *= SLEEVE_ENLARGE_SCALE
	position_y -= SLEEVE_LOWER
	half_height += SLEEVE_BOTTOM_EXTEND * 0.5
	position_y -= SLEEVE_BOTTOM_EXTEND * 0.5
	var sleeve_size := Vector3(
		(upper_arm_size.x + SLEEVE_OFFSET) * SLEEVE_ENLARGE_SCALE,
		half_height,
		(upper_arm_size.z + SLEEVE_OFFSET) * SLEEVE_ENLARGE_SCALE
	)
	var sleeve := SuperEgg.build_part(
		sleeve_size, sleeve_color, SLEEVE_TOP_EPSILON, SLEEVE_BOTTOM_EPSILON
	)
	sleeve.position = Vector3(0, position_y, 0)
	arm_pivot.add_child(sleeve)


## Scales a size Vector3's width/depth (x/z) by factor, leaving height (y)
## untouched -- the shared pattern chest_build_scale/hip_build_scale/
## abdomen_width_scale all use to vary body proportions without disturbing
## the height-stacking math anywhere.
static func _scaled_xz(size: Vector3, factor: float) -> Vector3:
	return Vector3(size.x * factor, size.y, size.z * factor)


static func _build_leg(
	rig: Node3D, hip_size: Vector3, hip_y: float, side: float, pants_color: Color, shoe_color: Color,
	build_scale: float, leg_thickness_scale: float = 1.0
) -> Dictionary:
	# Bare legs beneath a skirt do not carry the extra silhouette thickness
	# that the standard trouser geometry implies. Shoes retain their normal
	# scale so this changes anatomy/clothing read without shrinking footwear.
	var limb_scale := build_scale * leg_thickness_scale
	var upper_leg_size := _scaled_xz(UPPER_LEG_SIZE, limb_scale)
	var lower_leg_size := _scaled_xz(LOWER_LEG_SIZE, limb_scale)
	var foot_size := _scaled_xz(FOOT_SIZE, build_scale)

	var hip_x := side * (hip_size.x * 0.55 + HIP_OUTWARD_SHIFT)

	var leg_pivot := Node3D.new()
	leg_pivot.name = "LegPivot"
	leg_pivot.position = Vector3(hip_x, hip_y, 0)
	rig.add_child(leg_pivot)

	# A small constant outward tilt, baked in UNDER leg_pivot's own
	# animated rotation via this dedicated child node rather than directly
	# on leg_pivot itself -- player.gd/npc.gd continuously drive leg_pivot.
	# rotation.z every frame (walk resets it to 0, idle contrapposto lerps
	# it toward its own abduction target), so a static tilt placed there
	# directly would just get fought back toward 0 immediately. Everything
	# below (upper leg, knee, lower leg, ankle, foot) hangs off leg_tilt
	# instead of leg_pivot now, so the whole chain tilts together as one
	# rigid unit underneath whatever leg_pivot's own animation is doing.
	var leg_tilt := Node3D.new()
	leg_tilt.name = "LegTilt"
	leg_tilt.rotation.z = side * LEG_OUTWARD_ANGLE
	leg_pivot.add_child(leg_tilt)

	# Ball-and-socket: the thigh's top pokes up into the hip volume by
	# HIP_SOCKET_EMBED (well past the hip's own bottom edge, where
	# leg_pivot sits), rather than hanging from directly underneath it.
	_build_overlapping_segment(leg_tilt, upper_leg_size, pants_color, 0.0, HIP_SOCKET_EMBED, JOINT_OVERLAP)
	var knee_y := -upper_leg_size.y * 2.0

	var knee_pivot := Node3D.new()
	knee_pivot.name = "KneePivot"
	knee_pivot.position = Vector3(0, knee_y, 0)
	leg_tilt.add_child(knee_pivot)

	_build_overlapping_segment(knee_pivot, lower_leg_size, pants_color, 0.0, JOINT_OVERLAP, JOINT_OVERLAP)
	var ankle_y := -lower_leg_size.y * 2.0

	# A real pivot now (needed for the jump/landing pose's ankle flex --
	# see player.gd's _animate_airborne/_animate_landing), not just a fixed
	# offset straight off knee_pivot the way the foot used to hang.
	var ankle_pivot := Node3D.new()
	ankle_pivot.name = "AnklePivot"
	ankle_pivot.position = Vector3(0, ankle_y, 0)
	knee_pivot.add_child(ankle_pivot)

	var foot_half_height := foot_size.y + JOINT_OVERLAP * 0.5
	var foot := SuperEgg.build_part(Vector3(foot_size.x, foot_half_height, foot_size.z), shoe_color)
	# Feet still extend forward from the ankle overall (local +Z, this
	# rig's forward), but shifted back from the previous offset so the
	# heel (the back of the foot) sits under the ankle/shin instead of the
	# ankle landing near the foot's middle with nothing behind it to read
	# as weight-bearing support. Position is now relative to ankle_pivot
	# (which already sits at ankle_y), not knee_pivot directly.
	foot.position = Vector3(0, -foot_size.y * 0.6 + JOINT_OVERLAP * 0.5, foot_size.z * 0.35)
	# A slight toe-out stance, per direct instruction -- real feet aren't
	# perfectly parallel. `side` is +1 for the right leg (positioned at
	# +X) and -1 for the left (-X); a positive local Y rotation tips the
	# foot's forward (+Z) direction toward +X (worked out the same way as
	# the village corner-piece rotation fix -- x' = cos*x + sin*z for a
	# +yaw turn -- not re-verified in-engine here, so if this reads as
	# toeing IN instead of out, negate TOE_OUT_ANGLE's sign below). Right
	# foot: rotation.y = +side*angle turns toward +X (outward, correct).
	# Left foot: side=-1 turns toward -X (also outward, correct) -- same
	# formula mirrors automatically.
	foot.rotation.y = side * TOE_OUT_ANGLE
	ankle_pivot.add_child(foot)

	# The true forward tip of the foot mesh, in the foot's own local space
	# -- SuperEgg's own surface parametrization lands eta=0/omega=0 (its
	# "local +Z" pole, see superegg.gd's own docstring) exactly at
	# (0, 0, semi_axes.z), so this is the actual geometric tip, not an
	# approximation. A plain Node3D child of `foot`, so it inherits both
	# the foot's own position offset AND its toe-out yaw automatically --
	# per direct instruction, a marker for blorb_suit.gd's own leg noodle
	# routing (hip -> knee -> ankle -> toe) so it can reach exactly to the
	# toe instead of approximating the tip's position by hand, which
	# needed excessive flaring at the bottom of the suit's own shape to
	# reliably cover it.
	var toe := Node3D.new()
	toe.name = "ToeAttach"
	toe.position = Vector3(0, 0, foot_size.z)
	foot.add_child(toe)

	return {"pivot": leg_pivot, "joint": knee_pivot, "ankle": ankle_pivot, "toe": toe}


## Builds a limb segment slightly longer than its *logical* size at one or
## both ends (extra_top/extra_bottom), so it overlaps into whatever's on
## the other side of the joint instead of two independently-rounded caps
## just touching at a point. top_y is where the segment's un-extended top
## would sit in the parent's local space; the segment hangs downward from
## there. size.y stays the logical half-height used for any further
## position math below this segment (knee_y, ankle_y, etc) -- only the
## rendered mesh is stretched.
static func _build_overlapping_segment(
	parent: Node3D, size: Vector3, color: Color, top_y: float, extra_top: float, extra_bottom: float,
	x_offset: float = 0.0
) -> MeshInstance3D:
	var half_height := size.y + (extra_top + extra_bottom) * 0.5
	var render_size := Vector3(size.x, half_height, size.z)
	var part := SuperEgg.build_part(render_size, color)
	part.position = Vector3(x_offset, top_y + extra_top - half_height, 0)
	parent.add_child(part)
	return part
