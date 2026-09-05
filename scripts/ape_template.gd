class_name ApeTemplate
extends RefCounted

## First-pass base rig for building ape species, per direct instruction --
## "we'll use it to build out some ape species after we get it right." Built
## on ProceduralFigure (the human rig every player/NPC already uses) rather
## than MonkeyFigure, then reshaped:
## - No clothes: skin_color IS the fur color, passed as shirt_color/
##   pants_color too (see ProceduralFigure.build()'s own doc comment --
##   matching colors is what reads as "no clothing at all").
## - The head is torn out and rebuilt using MonkeyFigure's OWN private
##   head-building helpers (_add_face_marking/_add_muzzle/_add_eyes --
##   GDScript doesn't enforce privacy on "_"-prefixed functions, and
##   duplicating that much face-marking/muzzle math here would be a real
##   maintenance risk) at a size scaled up from MonkeyFigure's own head to
##   match ProceduralFigure's much bigger body, per direct instruction
##   ("use the same head as a monkey NPC, scaled up proportionally"). The
##   face marking/muzzle/eyes all now scale their own footprint with
##   head_size too (see monkey_figure.gd's own face_scale fix), so they
##   read as proportionally sized on the ape's bigger head, not pinned at
##   MonkeyFigure's own tiny absolute footprint.
## - Tail opt-in via variant's "has_tail" (default false) -- per direct
##   instruction, apes and monkeys are a firm class distinction (monkeys
##   always have tails, apes never do), but THIS SAME template now builds
##   both: an ape is has_tail=false (plus a bigger display_scale -- apes
##   have a minimum size, monkeys a maximum, without much overlap, see
##   main.gd's own debug-spawn comment), a "primate template" monkey is
##   has_tail=true plus a smaller scale. Reuses MonkeyFigure._build_tail()
##   verbatim when enabled, same as an earlier all-apes-get-a-tail version
##   of this file did before a since-superseded "apes never have tails"
##   correction removed it outright -- restored as a togglable variant
##   once the monkey/ape split (rather than every primate here being an
##   ape) was clarified.
## - A forward lean at the waist that includes the hips, not just the spine
##   above them -- per direct correction. ProceduralFigure.build() puts
##   hips and spine_pivot at two DIFFERENT, INDEPENDENT origins (hips is
##   its own StaticBody-sibling of spine_pivot, not a child of it), so
##   rotating spine_pivot alone only bends the torso above the hips, not
##   the pelvis itself. Fixed by inserting a new LeanPivot at hip height
##   (read directly off the leg pivot's own Y, not recomputed by hand) and
##   reparenting BOTH hips and spine_pivot under it, preserving their
##   original local offsets -- rotating LeanPivot now bends the whole upper
##   body, hips included, as one rigid unit, while the legs (still parented
##   straight to `rig`, per ProceduralFigure's own established convention)
##   stay unaffected by it.
## - The shoulders relax forward with gravity (same derivation MonkeyFigure.
##   _build_arm()'s own doc comment on arm_forward_relax_factor uses --
##   they hang in the exact same "child of a forward-leaning ancestor"
##   arrangement here too), and the head is leveled back out so the face
##   looks ahead instead of at the ground. That leveling compensation is
##   spread across FOUR joints, bottom to top -- a new AbdomenPivot at the
##   abdomen-hip joint, a new ChestPivot at the thorax-abdomen joint, a new
##   NeckPivot at the neck's own base, and head_pivot at the head's own
##   base -- see SPINE_TILT_SHARES' own doc comment. Originally just the
##   last two (per an earlier direct correction: putting the whole
##   compensation on head_pivot alone swung the head far enough that the
##   fixed-in-place neck visibly "jutted out" from underneath it), then
##   widened to all four per a further direct correction, for a gradual
##   natural spine curve instead of one abrupt kink. Each new pivot's own
##   base stays exactly where ProceduralFigure originally anchored that
##   segment; only what's above each one tilts.
## - The leg attachment itself shifted up (further into the hip volume),
##   forward, and wider, with an added static outward splay at the hip
##   socket -- per direct instruction, a wider bowlegged stance instead of
##   the human rig's own narrow one. See HIP_ATTACH_*/HIP_OUTWARD_ROTATION.
## - Permanently bent hip/knee joints for a low, crouched gait -- a REST-
##   pose offset applied once here (not an animated pose on its own, though
##   ApeTemplatePreview's own walk cycle swings around these rests rather
##   than around zero -- see that file). The ankle counter-bends by exactly
##   the hip+knee bend's own net tilt, per direct instruction, so the foot
##   still plants flat despite the crouch. The thigh (upper leg) is
##   shortened per direct instruction -- both its rendered mesh and the
##   knee's own attachment point move up together so there's no gap, and
##   the whole rig is lowered by the same amount so the shortened leg still
##   reaches the ground.
##
## This is a pose/proportion template, not a spawnable creature -- callers
## get back the same kind of pivots dict MonkeyFigure.build() does (same
## key names where the concept exists in both rigs -- a "_tail" key too,
## but only present when "has_tail" was true in the variant passed in), so
## a future species script can drive it with its own animation, the same
## way jungle_villager.gd drives MonkeyFigure. See ape_template_preview.gd
## for a minimal standalone instance to actually look at while tuning this.

## Matches jungle_villager.gd's own HEAD_SIZE_SCALE -- "the same head as a
## monkey NPC" means the elongated villager head specifically, not Xiao Hou
## Zi's own squat one.
const MONKEY_HEAD_SIZE_SCALE := Vector3(1.0, 1.35, 1.08)
## Higher than MonkeyFigure's own HEAD_EPSILON (2.05, "barely
## superelliptical") -- per direct instruction the head should read as
## less round, more superegg. Threaded into every head-surface computation
## below (the mesh itself, the face marking, the muzzle, the eyes) so they
## all agree on the same actual surface -- see monkey_figure.gd's own
## head_epsilon parameter, added for exactly this.
const HEAD_EPSILON := 3.3

## Raised from an initial 1.25 per direct instruction ("a bit longer").
const HAND_LENGTH_SCALE := 1.45
## Extra wrist twist so the back of the hand faces more toward the front
## (see this constant's usage below, in the hand/foot elongation block).
const HAND_TWIST_ANGLE := deg_to_rad(90.0)
## Pitches the fingertip end down and back at the wrist, on top of the
## twist above -- per direct instruction.
const HAND_TIP_DOWN_BACK_ANGLE := deg_to_rad(20.0)
## Brought down from an initial 1.25 per direct instruction ("the feet
## should be shorter too") -- still a bit longer than ProceduralFigure's
## own human proportions (1.0), not shortened past them.
const FOOT_LENGTH_SCALE := 1.05
## Extra forward nudge for the whole foot, on top of the heel-pinning shift
## below -- per direct correction the heel still stuck out the back even
## with the heel pinned exactly at its original (pre-elongation) spot, then
## nudged further per a later direct instruction ("shifted forward
## slightly"). Fraction of ProceduralFigure.FOOT_SIZE.z, first-pass and
## unconfirmed.
const FOOT_FORWARD_SHIFT_EXTRA := 0.42
## Per direct instruction ("make the feet flatter"). Multiplies the foot's
## own rendered vertical half-extent -- see the "Feet less rounded"
## section's own comment for why this has to rebuild the mesh outright
## rather than just scaling it (scaling would also squash the fur pad's
## own flush-surface math out of sync with the rendered mesh).
const FOOT_FLATTEN_SCALE := 0.72
## Per direct instruction ("make the feet less rounded") -- higher than
## SuperEgg.EPSILON_SOFT (3.0, ProceduralFigure's own default for hands/
## feet), short of EPSILON_FLAT (5.5, boxy). The foot's own mesh has to be
## rebuilt with this (epsilon is baked into the mesh at generation, not a
## node property that can be tweaked after the fact), unlike every other
## foot adjustment above which only touches the existing mesh's transform.
const FOOT_EPSILON := 4.5

## Per direct instruction: an inset "fur pad" patch on the back of each
## hand and the top of each foot, reading as fur against the surrounding
## skin-colored part -- see _add_dorsal_fur_pad()'s own doc comment for
## the geometry. Fractions of that side's own half-extent.
const FUR_PAD_SIDE_INSET := 0.18
## Deeper than the side inset -- per direct instruction, "even more inset
## on the toes [fingertips]" than on the sides.
const FUR_PAD_TIP_INSET := 0.35
## How far the pad's own center bulges out above the bare surface beneath
## it, tapering to 0 at the pad's own rim -- raised through several rounds
## now (0.0006, then 0.0031, as a flat constant offset before the pad
## became a real domed volume; then 0.014 once it was) per repeated direct
## correction it still wasn't clipping out enough to read as visible.
## FUR_PAD_DOME_FALLOFF_EXPONENT below also now keeps most of the pad's own
## area near this full height instead of tapering smoothly from the center
## outward, so the raised area itself reads bigger too, not just taller.
const FUR_PAD_DOME_HEIGHT := 0.032
## How far the pad's own back layer recesses just under the bare surface,
## so the rim connecting it to the domed front has real (if thin)
## thickness instead of a zero-thickness seam.
const FUR_PAD_BACK_EMBED := 0.0004
## Applied to (1 - radius), not radius^2 like a normal dome -- an exponent
## below 1.0 stays close to 1.0 (full FUR_PAD_DOME_HEIGHT) across most of
## the radius and only drops toward 0 sharply right near the rim, reading
## as a raised flat-ish pad with a small rounded edge bevel rather than a
## smooth ball-like bump that only ever reaches full height at one single
## center point.
const FUR_PAD_DOME_FALLOFF_EXPONENT := 0.35

## Per direct instruction: "eyes should be taking the shape of a
## superellipsis more like the human figures, and higher up on the face."
## x_scale/y_scale/epsilon match FigureEyes.gd's own human eye exactly
## (EYE_HEIGHT_RATIO 1.4, EPSILON_SOFT 3.0 -- taller than wide, softly
## superelliptical, not MonkeyFigure's own round circle). eta lifts them
## off the head's equator toward the crown (positive eta = toward +Y, see
## SuperEgg.surface_point()'s own sin(eta) term).
## eta's effect on actual surface height is NOT independent of HEAD_EPSILON:
## surface_point() raises sin(eta) to the power 2/epsilon, so the same eta
## lands much higher on this head (epsilon 3.3) than it would on
## MonkeyFigure's own rounder one (epsilon 2.05) -- a value first tuned
## before HEAD_EPSILON was raised this same round ended up placing the eyes
## far higher than intended, and past the face marking mask's own footprint
## (see MonkeyFigure._add_eyes()'s own comment: outside that footprint the
## flush-to-mask push it does is skipped entirely, since there's no mask
## there to clear). Reduced here to land at roughly the same actual height
## as before, and back within the mask -- not visually reconfirmed yet.
## "omega" adjusts the eyes' own outward splay relative to MonkeyFigure's
## own EYE_OFFSET (17.5 degrees) -- first widened per direct correction
## they weren't splayed enough to follow the face marking mask's own
## outward curve, then brought back down BELOW that original default (not
## just back to it) per a further direct correction that the wider value
## spread them much too far apart. First-pass value, not visually
## confirmed.
## x_scale/y_scale both scaled up 33% from the original human-eye-matched
## values (1.0/1.4) per direct instruction the eyes should read larger
## overall -- same width:height ratio preserved, so the shape itself is
## unchanged, just bigger.
const EYE_SHAPE := {
	"x_scale": 1.33, "y_scale": 1.862, "epsilon": 3.0, "eta": 0.086, "omega": deg_to_rad(14.0)
}

## Per direct instruction: the muzzle elongates a bit further down toward
## the chin. Stretches only MonkeyFigure._muzzle_point()'s own lower
## (chin-side) footprint, leaving the upper/nose-level edge untouched --
## see that function's own chin_extend doc comment.
const MUZZLE_CHIN_EXTEND := 0.4

## Tail reach is expressed as a multiple of the leg's own total length (a
## stand-in for "body size" that stays independent of absolute build
## scale) -- only used when variant's "has_tail" is true (see the tail
## section near the end of build()). MonkeyFigure._build_tail()'s own
## length_scale stretches every point past the anchor proportionally, so
## this converts that target reach into the length_scale that actually
## produces it (see build()'s own comment at the call site for the
## arithmetic).
const TAIL_REACH_FRACTION := 1.6
## MonkeyFigure's own tail radius (0.007) is tuned for that rig's tiny
## scale -- this multiplies it up to read as a real tail thickness on a
## human-scale body.
const TAIL_RADIUS_SCALE := 5.0

## Per direct instruction: the point where the legs meet the hips shifts up
## (further into the hip volume) and forward, and widens out, with the legs
## also rotating outward from the body at the hip socket. Expressed as
## fractions of ProceduralFigure's own HIP_SIZE (up/forward) or a multiple
## of the existing lateral attachment offset (widen), so this stays
## proportional rather than a fixed absolute offset. First-pass values, not
## visually confirmed.
const HIP_ATTACH_RAISE_FRACTION := 0.5  # of ProceduralFigure.HIP_SIZE.y
const HIP_ATTACH_FORWARD_FRACTION := 0.25  # of ProceduralFigure.HIP_SIZE.z
const HIP_ATTACH_WIDEN_SCALE := 1.18
## Additional static outward hip-socket splay, on top of ProceduralFigure's
## own subtle LEG_OUTWARD_ANGLE (2 degrees, baked into a separate LegTilt
## child player.gd/npc.gd never touch). Applied directly to leg_left/
## leg_right's own rotation.z instead -- unlike the human rig, nothing in
## this file's own walk cycle (see ape_template_preview.gd) drives
## rotation.z on these pivots, so a static value set here won't get fought
## back to 0 every frame the way it would need LegTilt's own workaround.
const HIP_OUTWARD_ROTATION := deg_to_rad(10.0)
## Outward YAW at the hip (rotation.y), separate from the Z-axis splay
## above -- per direct instruction, a duck-footed stance with the whole
## leg (feet included) turned outward, not just tipped outward. Same
## sign convention as ProceduralFigure._build_leg()'s own already-
## confirmed TOE_OUT_ANGLE (rotation.y = side * angle turns each foot
## outward correctly on both sides) -- reused rather than re-derived,
## since leg_side here is computed the same way that side parameter is.
const HIP_YAW_OUTWARD := deg_to_rad(12.0)
## Per direct instruction: shoulders angle outward (see the "Arms relax
## forward" section's own comment).
const SHOULDER_OUTWARD_ANGLE := deg_to_rad(10.0)
## Elbows angle inward -- originally set to mirror SHOULDER_OUTWARD_ANGLE
## exactly ("an equal amount"), then increased further per a direct
## correction ("even more") independent of whatever the shoulder ends up
## using.
const ELBOW_INWARD_ANGLE := deg_to_rad(18.0)
## Per direct instruction: arm thickness raised to nearly match the legs'
## own -- see the "Arms thickened" section's own comment. Fraction of the
## leg's OWN ACTUAL thickness (not the raw UPPER_LEG_SIZE.x/z constant --
## see that section's own comment on why this has to track body_type's own
## effect on real leg thickness now), not quite 1.0 so the arms stay a bit
## slimmer than the legs.
const ARM_THICKNESS_TARGET_FRACTION := 0.9

## Per direct instruction: body build varies from ectomorph (0.0) through
## this file's own established default proportions (0.5 -- "this body type
## is more the mesomorph type" already, before any of this existed) to an
## even more extreme mesomorph (1.0). Reuses ProceduralFigure's own
## existing chest_build_scale/abdomen_width_scale knobs (already built for
## exactly this kind of build variance on the human rig -- see that file's
## own doc comment on them) rather than new geometry: chest_build_scale
## alone already makes the chest's FRONT depth grow without touching its
## back depth (see ProceduralFigure.build()'s own chest_front_depth/
## chest_back_depth split), which is exactly a forward-protruding "barrel
## chest," and abdomen_width_scale already feeds into arm/leg thickness
## too via ProceduralFigure's own LIMB_BULK_RESPONSE. Pushed well past
## town_generator.gd's own human NPC range (chest_build_scale 0.88-1.18,
## abdomen_width_scale 1.0-1.32) at both ends, per direct instruction
## ("pushed a bit more to the extreme"). hip_build_scale is deliberately
## left alone (always 1.0) -- not asked for, and this rig already has its
## own separate hip-width system (HIP_ATTACH_WIDEN_SCALE) that a second
## independent hip-width knob would just fight with.
const CHEST_BUILD_SCALE_ECTOMORPH := 0.68
const CHEST_BUILD_SCALE_MESOMORPH := 1.45
const ABDOMEN_WIDTH_SCALE_ECTOMORPH := 0.85
const ABDOMEN_WIDTH_SCALE_MESOMORPH := 1.4
## Per direct instruction: "mesomorphs should have much thicker necks."
## ProceduralFigure's own neck_size ALREADY tracks chest_build_scale
## directly (see that file's own build(), the neck_size.x/z line), so a
## mesomorph's neck is already somewhat thicker for free -- but only by
## the same ~1.45x chest_build_scale itself tops out at, which isn't the
## "MUCH thicker" this asked for. This multiplies neck thickness AGAIN, on
## top of that existing tie, applied directly to the already-built neck
## mesh's own scale.x/z (see the "Neck thickened" section below) the same
## post-hoc way ARM_THICKNESS_TARGET_FRACTION works.
const NECK_THICKNESS_SCALE_ECTOMORPH := 0.85
## Brought down from an initial 1.9 per direct correction -- combined with
## ProceduralFigure's own existing chest_build_scale tie (up to ~1.45x on
## top of this), 1.9 pushed the neck's own front surface out past the
## face (see NECK_HEIGHT_SCALE's own doc comment on why scaling this
## mesh's scale.x/z, rather than resizing+repositioning it, grows the
## front and back surfaces symmetrically around the neck's own center).
const NECK_THICKNESS_SCALE_MESOMORPH := 1.25
## Per direct instruction: "all the necks can actually be a bit taller,
## maybe twice as tall, [but] button that much into the bottom of the
## ape's head" -- uniform across every ape (not body_type-driven), and
## anchored so all the added length embeds upward into the head rather
## than pushing the neck's own base down into the chest -- see the "Neck
## taller too" section's own comment for the position-compensation math.
const NECK_HEIGHT_SCALE := 2.0

## radians -- thigh angled forward/down from the hip socket. Raised from an
## initial 0.4 (~23 deg) per direct instruction ("bend the legs forward at
## the hips more in resting"). ankle_rest_x and the floating-fix vertical-
## reach compensation below both derive from this constant directly, so
## raising it alone keeps the foot planted flat and grounded without any
## separate adjustment.
const HIP_CROUCH_BEND := 0.55  # ~31.5 deg
const KNEE_CROUCH_BEND := 0.95  # radians (~54 deg) -- past ProceduralFigure's own 0.55 walking-peak KNEE_BEND_AMOUNT, per direct instruction ("significantly bent")
## Per direct instruction: shortens the thigh (upper leg) segment -- both
## its rendered mesh and the knee's own attachment point, so there's no
## gap between the shrunk thigh and where the shin now starts.
const THIGH_LENGTH_SCALE := 0.72

## How the total upward head-tilt compensation splits across the spine,
## bottom to top: the abdomen-hip joint (spine_pivot's own base), the
## thorax-abdomen joint (ChestPivot), the neck's own base (NeckPivot), and
## the head's own base (head_pivot). Per direct correction, concentrating
## the whole compensation on just the neck/head pair (the original two-way
## NECK_TILT_SHARE split) read as an abrupt kink instead of a natural
## curve; spreading it further down through the torso's own joints gives
## a gradual bend across the whole spine instead. Equal quarters is a
## first-pass "spread it out evenly" choice, not tuned per-joint.
const SPINE_TILT_SHARES: Array[float] = [0.25, 0.25, 0.25, 0.25]


## variant mirrors MonkeyFigure.build()'s own contract where the concept
## exists in both rigs:
## - "marking_color": Color, the face marking's/muzzle's own base color
##   (see MonkeyFigure.build()'s own doc comment on the same key)
## - "has_face_marking": bool
## - "spine_forward_bend": float (radians) -- the waist/hip lean; also
##   drives the arm/head counter-rotation below, scaled by these two:
## - "arm_forward_relax_factor": float
## - "head_tilt_factor": float
## - "body_type": float, 0.0 (ectomorph) - 1.0 (extreme mesomorph), 0.5 is
##   this file's own established default build -- see CHEST_BUILD_SCALE_*/
##   ABDOMEN_WIDTH_SCALE_*'s own doc comment
## - "head_height_scale": float, multiplies MONKEY_HEAD_SIZE_SCALE.y (1.0 =
##   this file's own established default head proportions)
## - "has_tail": bool, false = ape, true = "primate template" monkey (see
##   TAIL_REACH_FRACTION's own doc comment)
## - "tail_length_scale": float, multiplies TAIL_REACH_FRACTION (only
##   meaningful when "has_tail" is true)
## - "skeleton_mode": bool, default false -- a bony variant for an undead
##   primate NME: the abdomen becomes a visible spine column (same
##   ProceduralFigure.build_spine_column() technique the human skeleton_nme.
##   gd rig already uses for its own abdomen, applied here to this rig's
##   equivalent torso segment) and ears are skipped. Everything else
##   (chest, limbs, muzzle, face marking, eyes, tail) is unchanged in shape
##   -- only recolored, same as the human skeleton, by the caller passing a
##   bone-white fur_color/marking_color rather than this flag changing any
##   color itself.
static func build(
	parent: Node3D, fur_color: Color = MonkeyFigure.MONKEY_FUR_COLOR, scale: float = 1.0, variant: Dictionary = {}
) -> Dictionary:
	# has_tail (see the tail section near the end of this function) is what
	# actually decides ape vs "primate template" monkey -- per direct
	# instruction ("monkeys should not get the mesomorph body type, only
	# apes can"), body_type is forced to the neutral baseline (0.5, which
	# _lerp_body_type resolves to chest_build_scale/abdomen_width_scale of
	# exactly 1.0 each) for monkeys, enforced here structurally rather than
	# left to callers to remember not to pass a body_type for one.
	var has_tail: bool = variant.get("has_tail", false)
	var skeleton_mode: bool = variant.get("skeleton_mode", false)
	var body_type: float = 0.5 if has_tail else variant.get("body_type", 0.5)
	var chest_build_scale := _lerp_body_type(CHEST_BUILD_SCALE_ECTOMORPH, CHEST_BUILD_SCALE_MESOMORPH, body_type)
	var abdomen_width_scale := _lerp_body_type(
		ABDOMEN_WIDTH_SCALE_ECTOMORPH, ABDOMEN_WIDTH_SCALE_MESOMORPH, body_type
	)
	var pivots := ProceduralFigure.build(
		parent, fur_color, fur_color, fur_color, ProceduralFigure.SLEEVE_STYLE_NONE, scale,
		chest_build_scale, 1.0, abdomen_width_scale
	)
	var spine_pivot := pivots["spine"] as Node3D
	var rig := spine_pivot.get_parent() as Node3D
	var spine_forward_bend: float = variant.get("spine_forward_bend", 0.0)
	# Declared early (moved up from the head-swap section below) so the
	# hand/foot skin-color section can read it too -- see that section's
	# own comment.
	var marking_color: Color = variant.get("marking_color", MonkeyFigure.MARKING_COLOR)

	# --- Leg attachment: shifted up/forward and widened, with an extra
	# outward hip-socket splay (see HIP_ATTACH_*/HIP_OUTWARD_ROTATION's own
	# doc comments). Done before hip_y is read below so the lean pivot
	# picks up the raised height too. ---
	var leg_left := pivots["leg_left"] as Node3D
	var leg_right := pivots["leg_right"] as Node3D
	var hip_attach_raise := ProceduralFigure.HIP_SIZE.y * HIP_ATTACH_RAISE_FRACTION
	var hip_attach_forward := ProceduralFigure.HIP_SIZE.z * HIP_ATTACH_FORWARD_FRACTION
	for leg_pivot_node in [leg_left, leg_right]:
		var leg_side := signf(leg_pivot_node.position.x)
		leg_pivot_node.position.x *= HIP_ATTACH_WIDEN_SCALE
		leg_pivot_node.position.y += hip_attach_raise
		leg_pivot_node.position.z += hip_attach_forward
		leg_pivot_node.rotation.z = leg_side * HIP_OUTWARD_ROTATION
		leg_pivot_node.rotation.y = leg_side * HIP_YAW_OUTWARD
	# Raising the attachment point raises the whole leg (and its foot) by
	# the same amount, same reasoning as the thigh-shortening compensation
	# below -- undone there together with that other vertical adjustment.

	# --- Hip-inclusive lean: a new pivot at hip height carries hips AND
	# spine_pivot together (see this file's own class doc comment). ---
	var hip_y: float = (pivots["leg_left"] as Node3D).position.y
	var lean_pivot := Node3D.new()
	lean_pivot.name = "LeanPivot"
	lean_pivot.position = Vector3(0, hip_y, 0)
	rig.add_child(lean_pivot)
	var hips := pivots["hips"] as Node3D
	# A reusable anatomical mount point at the actual bottom of the pelvis.
	# Unlike ProceduralFigure.HIP_PIVOT_Y, this remains correct after this
	# template's scale, ground-clearance, and hip-inclusive lean changes.
	var hip_bottom := Node3D.new()
	hip_bottom.name = "HipBottomMount"
	hip_bottom.position = Vector3(0, -ProceduralFigure.HIP_SIZE.y, 0)
	hips.add_child(hip_bottom)
	pivots["hip_bottom"] = hip_bottom
	_reparent_keep_local(hips, lean_pivot, lean_pivot.position)
	_reparent_keep_local(spine_pivot, lean_pivot, lean_pivot.position)
	lean_pivot.rotation.x = spine_forward_bend

	# --- Upward-tilt compensation, spread across the whole spine (see
	# SPINE_TILT_SHARES' own doc comment) instead of concentrated at the
	# neck/head alone, for a gradual natural curve -- per direct correction.
	# Four joints share it, bottom to top: a new AbdomenPivot (abdomen-hip
	# joint), a new ChestPivot (thorax-abdomen joint), NeckPivot (neck
	# base), and head_pivot (head base). ---
	var head_tilt_factor: float = variant.get("head_tilt_factor", 0.0)
	var total_tilt := -spine_forward_bend * (1.0 + head_tilt_factor)
	var head_pivot := pivots["head"] as Node3D
	# spine_pivot's children, by ProceduralFigure.build()'s own fixed
	# construction order: abdomen, chest, then a NeckPivot of ITS OWN
	# (added for player.gd's Manchego-seated-pose head/neck split -- see
	# that file's own neck_pivot comment), which in turn parents the neck
	# mesh AND head_pivot together (head_pivot used to be a direct
	# spine_pivot child alongside neck; both moved under this pivot in a
	# procedural_figure.gd change made after this section was originally
	# written, which is what broke this file with a Nil-position crash --
	# get_child(2) started returning that pivot instead of the neck mesh
	# itself). arm_right/arm_left are still direct spine_pivot children,
	# added after -- reached via pivots[], not indices, so unaffected.
	var abdomen := spine_pivot.get_child(0) as MeshInstance3D
	var chest := spine_pivot.get_child(1) as MeshInstance3D
	var proc_neck_pivot := spine_pivot.get_child(2) as Node3D
	var neck := proc_neck_pivot.get_child(0) as MeshInstance3D
	var arm_right := pivots["arm_right"] as Node3D
	var arm_left := pivots["arm_left"] as Node3D
	# A dedicated pivot for the abdomen-hip joint, kept separate from
	# spine_pivot itself so this stays the same "wrap the segment in its
	# own pivot" pattern as every other joint here -- sits at spine_pivot's
	# own origin, exactly where the abdomen's own base already is, so this
	# reparent is a trivial (zero-offset) one.
	var abdomen_pivot := Node3D.new()
	abdomen_pivot.name = "AbdomenPivot"
	spine_pivot.add_child(abdomen_pivot)
	# Captured before the skeleton_mode branch below might free the mesh --
	# chest_pivot's own placement further down depends on this regardless of
	# which branch runs.
	var abdomen_local_y := abdomen.position.y
	if skeleton_mode:
		# Same technique procedural_figure.gd's own skeleton_mode already
		# uses for its abdomen (see that file's build_spine_column()) --
		# reading this rig's own actual built abdomen size/offset back out,
		# rather than re-deriving CHEST_BUILD_SCALE_*/ABDOMEN_WIDTH_SCALE_*
		# math independently, keeps this correct even if that math changes
		# later. abdomen_pivot sits at abdomen's own undisplaced local origin
		# (the same zero-offset reparent the non-skeleton branch uses below),
		# so building the spine column directly as its child, using
		# abdomen's own already-known local geometry, occupies exactly the
		# same space the solid mesh would have.
		var abdomen_semi_axes := abdomen.mesh.get_aabb().size * 0.5
		var abdomen_z_offset := abdomen.position.z
		abdomen.free()
		ProceduralFigure.build_spine_column(abdomen_pivot, abdomen_semi_axes, fur_color, abdomen_z_offset)
	else:
		_reparent_keep_local(abdomen, abdomen_pivot, Vector3.ZERO)
	# abdomen's own mesh sits (or, in skeleton_mode, its spine column
	# occupies the same span) with its base flush at abdomen_pivot's local
	# origin (position.y == its own half-height, see ProceduralFigure.
	# build()'s own abdomen.position line) -- so its TOP edge, i.e. the
	# thorax-abdomen joint, is exactly twice that.
	var chest_pivot := Node3D.new()
	chest_pivot.name = "ChestPivot"
	chest_pivot.position = Vector3(0, abdomen_local_y * 2.0, 0)
	abdomen_pivot.add_child(chest_pivot)
	# The shoulders attach to the chest (both were originally direct,
	# un-rotated siblings under spine_pivot, so their relative offsets held
	# them together automatically) -- once the chest picks up its own
	# extra tilt below, the shoulders have to move with it too or they
	# visibly detach from it -- per direct correction. So arm_right/
	# arm_left get reparented under chest_pivot alongside chest itself;
	# the "Arms relax forward" section below then subtracts that same
	# extra tilt back out of their OWN local rotation so their net angle
	# relative to lean_pivot -- the actually-calibrated, already-confirmed
	# "relaxed forward" pose -- is unchanged.
	#
	# chest/arm_right/arm_left's own .position values are still expressed
	# in spine_pivot's own frame at this point, and so is chest_pivot's
	# (abdomen_pivot, its actual parent, sits at a zero offset AND zero
	# rotation from spine_pivot -- see above), so those three reparent
	# straight to chest_pivot.position with no extra conversion. neck and
	# head_pivot are different: they're currently children of
	# proc_neck_pivot, not spine_pivot directly, so their own .position is
	# in ITS frame instead -- proc_neck_pivot.position is spine_pivot's own
	# offset to that frame (proc_neck_pivot itself carries zero rotation
	# here, so this is a plain subtraction, not a general transform),
	# subtracted out to convert chest_pivot's own spine_pivot-frame
	# position into the equivalent offset FROM proc_neck_pivot's frame.
	_reparent_keep_local(chest, chest_pivot, chest_pivot.position)
	_reparent_keep_local(neck, chest_pivot, chest_pivot.position - proc_neck_pivot.position)
	_reparent_keep_local(head_pivot, chest_pivot, chest_pivot.position - proc_neck_pivot.position)
	_reparent_keep_local(arm_right, chest_pivot, chest_pivot.position)
	_reparent_keep_local(arm_left, chest_pivot, chest_pivot.position)
	# Now empty (both its own children just moved out above) and otherwise
	# inert -- freed rather than left as dead weight in the tree.
	proc_neck_pivot.free()
	var neck_logical_half_height := ProceduralFigure.HEAD_RAISE * 0.5
	var neck_pivot := Node3D.new()
	neck_pivot.name = "NeckPivot"
	# neck.position is already expressed in chest_pivot's own local frame
	# (just reparented above), so this reads identically to before.
	neck_pivot.position = neck.position - Vector3(0, neck_logical_half_height, 0)
	chest_pivot.add_child(neck_pivot)
	_reparent_keep_local(neck, neck_pivot, neck_pivot.position)
	_reparent_keep_local(head_pivot, neck_pivot, neck_pivot.position)
	abdomen_pivot.rotation.x = total_tilt * SPINE_TILT_SHARES[0]
	chest_pivot.rotation.x = total_tilt * SPINE_TILT_SHARES[1]
	neck_pivot.rotation.x = total_tilt * SPINE_TILT_SHARES[2]
	head_pivot.rotation.x = total_tilt * SPINE_TILT_SHARES[3]

	# --- Arms relax forward with gravity instead of staying pulled back
	# toward the now-leaning hips (same derivation MonkeyFigure._build_arm()
	# uses). arm_rest_x is calibrated as the arm's angle relative to
	# lean_pivot -- but arm_right/arm_left are now children of chest_pivot
	# (see above), which itself already contributes abdomen_pivot's +
	# chest_pivot's own share of total_tilt on the way down from
	# lean_pivot. Subtracting that share back out of the arm's own local
	# rotation keeps the NET angle relative to lean_pivot at exactly
	# arm_rest_x, same as when arms hung directly off spine_pivot. ---
	var arm_relax: float = variant.get("arm_forward_relax_factor", 0.0)
	var arm_rest_x := -spine_forward_bend * (1.0 + arm_relax)
	var shoulder_inherited_tilt := total_tilt * (SPINE_TILT_SHARES[0] + SPINE_TILT_SHARES[1])
	arm_left.rotation.x = arm_rest_x - shoulder_inherited_tilt
	arm_right.rotation.x = arm_rest_x - shoulder_inherited_tilt
	# Per direct instruction: shoulders angle outward from the body, elbows
	# angle inward (a zigzag arm shape) -- originally an equal amount,
	# then the elbow's own share increased further per a direct correction
	# (see ELBOW_INWARD_ANGLE's own doc comment), so the two are now
	# separate constants rather than one mirrored value. Same signed-by-
	# side pattern as HIP_OUTWARD_ROTATION above (side read straight off
	# each pivot's own position.x, not hardcoded, since left/right sit on
	# opposite sides). Elbow's own local Z axis is assumed to still align
	# with the shoulder's (nothing between them applies its own twist) --
	# not visually confirmed. arm_left/arm_right ADD to their rotation.z
	# here, not replace it -- ProceduralFigure._build_arm() already bakes
	# a small ARM_OUTWARD_ANGLE onto this same axis (arm_pivot.rotation.z
	# = side * ARM_OUTWARD_ANGLE), and overwriting it would silently erase
	# that.
	var elbow_left := pivots["elbow_left"] as Node3D
	var elbow_right := pivots["elbow_right"] as Node3D
	var shoulder_side_left := signf(arm_left.position.x)
	var shoulder_side_right := signf(arm_right.position.x)
	arm_left.rotation.z += shoulder_side_left * SHOULDER_OUTWARD_ANGLE
	arm_right.rotation.z += shoulder_side_right * SHOULDER_OUTWARD_ANGLE
	elbow_left.rotation.z = -shoulder_side_left * ELBOW_INWARD_ANGLE
	elbow_right.rotation.z = -shoulder_side_right * ELBOW_INWARD_ANGLE

	# --- Crouch: hip + knee bend, ankle compensates so the foot plants
	# flat, thigh shortened with the knee/rig repositioned to match.
	# leg_left/leg_right themselves already declared above (leg attachment
	# adjustment). ---
	var knee_left := pivots["knee_left"] as Node3D
	var knee_right := pivots["knee_right"] as Node3D
	leg_left.rotation.x = -HIP_CROUCH_BEND
	leg_right.rotation.x = -HIP_CROUCH_BEND
	knee_left.rotation.x = KNEE_CROUCH_BEND
	knee_right.rotation.x = KNEE_CROUCH_BEND
	# The shin's own net world tilt is the hip bend plus the knee bend
	# (both local rotations around the same X axis, so they add); the
	# ankle needs exactly the opposite to bring the foot back level.
	var ankle_rest_x := -(-HIP_CROUCH_BEND + KNEE_CROUCH_BEND)
	var ankle_left := pivots["ankle_left"] as Node3D
	var ankle_right := pivots["ankle_right"] as Node3D
	ankle_left.rotation.x = ankle_rest_x
	ankle_right.rotation.x = ankle_rest_x
	# leg_left/leg_right's own HIP_OUTWARD_ROTATION (rotation.z, set above)
	# rolls the entire leg chain beneath it, foot included, away from flat
	# -- per direct correction, the foot should still plant with its sole
	# pointed straight down at rest. Same cancellation technique as the
	# ankle's own X-axis compensation just above: the negative of exactly
	# what was applied higher up in the same chain brings the foot's own
	# roll back to level.
	ankle_left.rotation.z = -leg_left.rotation.z
	ankle_right.rotation.z = -leg_right.rotation.z

	_shorten_thigh(leg_left, THIGH_LENGTH_SCALE)
	_shorten_thigh(leg_right, THIGH_LENGTH_SCALE)
	# Bending a joint folds the leg, shortening its own vertical reach --
	# per direct feedback the ape was floating above the ground, exactly
	# this effect uncompensated. Forward kinematics: a segment of length L
	# hanging straight down (local -Y) then rotated by angle theta around X
	# has vertical extent L*cos(theta) (see kingdom_bootstrap.gd's own
	# rotation-matrix-derivation precedent for this same cos/sin technique).
	# ProceduralFigure.build() placed the ankle assuming the FULL straight,
	# unshortened leg reached the ground; the actual (bent, shortened) leg
	# reaches less far, by exactly this much -- so the whole rig drops by
	# the difference to bring the feet back down to local Y=0.
	var upper_leg_len := ProceduralFigure.UPPER_LEG_SIZE.y * 2.0 * THIGH_LENGTH_SCALE
	var lower_leg_len := ProceduralFigure.LOWER_LEG_SIZE.y * 2.0
	var shin_net_tilt := absf(-HIP_CROUCH_BEND + KNEE_CROUCH_BEND)
	var actual_vertical_reach := upper_leg_len * cos(HIP_CROUCH_BEND) + lower_leg_len * cos(shin_net_tilt)
	var assumed_vertical_reach := ProceduralFigure.UPPER_LEG_SIZE.y * 2.0 + ProceduralFigure.LOWER_LEG_SIZE.y * 2.0
	# hip_attach_raise (leg attachment adjustment, above) also needs
	# undoing here: raising the pivot the leg hangs from, with the leg's
	# own reach unchanged, lifts the foot by that same amount on top of
	# the bend-shortening effect this block otherwise compensates for.
	#
	# Multiplied by `scale` -- per direct bug report, small (has_tail=true
	# "primate template" monkey) instances were clipping their feet into
	# the ground. This whole compensation is computed from ProceduralFigure
	# reference constants (UPPER_LEG_SIZE etc, defined at build_scale=1.0),
	# but rig.position.y itself is set in rig's PARENT frame -- unlike
	# every other position offset in this file, which lands on some
	# descendant of `rig` and so gets `rig.scale` applied automatically by
	# ordinary node-transform composition when rendered, this one has to be
	# scaled by hand or it overcorrects at any scale other than 1.0 (at
	# small scale, subtracting the full reference-unit amount from an
	# unscaled position pushes the whole rig down far more than the
	# actually-shrunk geometry needs).
	rig.position.y -= (assumed_vertical_reach - actual_vertical_reach + hip_attach_raise) * scale

	# --- Arms thickened to nearly match the legs' own thickness -- per
	# direct instruction. ProceduralFigure's own UPPER_ARM_SIZE/FOREARM_SIZE
	# (0.05/0.045) are notably thinner than UPPER_LEG_SIZE/LOWER_LEG_SIZE
	# (both 0.075); ARM_THICKNESS_TARGET_FRACTION expresses the target as a
	# fraction of the leg's own thickness rather than a flat multiplier, so
	# both arm segments (despite starting from different base thicknesses)
	# land at the same real-world thickness relative to the leg. Same child-
	# index access pattern _shorten_thigh() uses for the leg's own mesh
	# (arm_pivot's first child is the upper-arm mesh, same as leg_tilt's
	# first child is the upper-leg mesh; ProceduralFigure._build_arm() has
	# no ArmTilt equivalent to the leg's LegTilt, so there's one less level
	# of nesting here). Only scale.x/scale.z (thickness), not .y (length).
	# Target is based on the leg's own ACTUAL thickness, not the raw
	# UPPER_LEG_SIZE.x constant -- hip_build_scale is always 1.0 on this
	# rig (see CHEST_BUILD_SCALE_*'s own doc comment), but leg_build_scale
	# inside ProceduralFigure.build() also picks up abdomen_width_scale's
	# own LIMB_BULK_RESPONSE contribution, so the leg is already thicker
	# than the raw constant for a fuller-bodied (higher body_type) ape.
	# Recomputing that same contribution here (rather than reading it back
	# off the built leg mesh) keeps this a pure function of body_type,
	# matching how chest_build_scale/abdomen_width_scale were derived
	# above.
	var leg_build_scale := 1.0 + (abdomen_width_scale - 1.0) * ProceduralFigure.LIMB_BULK_RESPONSE
	var arm_thickness_target := ProceduralFigure.UPPER_LEG_SIZE.x * leg_build_scale * ARM_THICKNESS_TARGET_FRACTION
	var upper_arm_thickness_scale := arm_thickness_target / ProceduralFigure.UPPER_ARM_SIZE.x
	var forearm_thickness_scale := arm_thickness_target / ProceduralFigure.FOREARM_SIZE.x
	for shoulder in [arm_left, arm_right]:
		var upper_arm_mesh := shoulder.get_child(0) as MeshInstance3D
		if upper_arm_mesh != null:
			upper_arm_mesh.scale.x *= upper_arm_thickness_scale
			upper_arm_mesh.scale.z *= upper_arm_thickness_scale
	for elbow in [elbow_left, elbow_right]:
		var forearm_mesh := elbow.get_child(0) as MeshInstance3D
		if forearm_mesh != null:
			forearm_mesh.scale.x *= forearm_thickness_scale
			forearm_mesh.scale.z *= forearm_thickness_scale

	# --- Neck thickened further by body_type, on top of ProceduralFigure's
	# own existing chest_build_scale tie -- see NECK_THICKNESS_SCALE_*'s
	# own doc comment. `neck` still refers to the same mesh reparented
	# under chest_pivot/neck_pivot earlier in this function (GDScript's
	# var scope is the whole function, not just that section's own block).
	var neck_thickness_scale := _lerp_body_type(
		NECK_THICKNESS_SCALE_ECTOMORPH, NECK_THICKNESS_SCALE_MESOMORPH, body_type
	)
	neck.scale.x *= neck_thickness_scale
	neck.scale.z *= neck_thickness_scale
	# --- Neck taller too, per direct instruction ("all the necks can
	# actually be a bit taller, maybe twice as tall"), applied uniformly
	# (not body_type-driven, unlike thickness above). scale.y alone would
	# grow the mesh symmetrically around its own center -- half the added
	# length pushing UP into the head, half pushing DOWN into the chest --
	# but the ask was for it to "button... into the bottom of the ape's
	# head," i.e. the bottom (where the neck meets the chest) has to stay
	# exactly where ProceduralFigure originally anchored it, with ALL the
	# added length going up. Same "shift by the added half-length to pin
	# one edge" technique the foot's own heel-pinning fix above uses.
	# neck_half_height comes from the mesh's own actual built AABB rather
	# than ProceduralFigure's private neck-height constants, so this stays
	# correct even if that formula changes later.
	var neck_half_height := neck.mesh.get_aabb().size.y * 0.5
	neck.scale.y *= NECK_HEIGHT_SCALE
	neck.position.y += neck_half_height * (NECK_HEIGHT_SCALE - 1.0)

	# --- Body material matched to the head's own -- per direct correction,
	# the two weren't reading as the same material. ProceduralFigure's own
	# SuperEgg.build_part() gives chest/abdomen/hips/neck/limbs a plain
	# generic material (roughness 0.6, specular left at its default), while
	# the head uses MonkeyFigure._build_fur_material() (inherited from
	# building the head out of Xiao Hou Zi's own head-building code --
	# roughness 0.95, specular disabled, tuned specifically for that fur
	# look), so the head visibly read glossier/different from the body.
	# Overriding the body's own materials to the SAME _build_fur_material()
	# call the head already uses (one shared instance -- StandardMaterial3D
	# can be safely reused across multiple surfaces) makes the two match
	# exactly instead of just looking similar. Hands/feet are deliberately
	# excluded -- those already got their own intentional "skin," not fur,
	# material earlier (see that section's own comment). ---
	var body_fur_material := MonkeyFigure._build_fur_material(fur_color)
	# abdomen is a freed, dangling reference in skeleton_mode (replaced by a
	# spine column above, which keeps its own plain material -- same as the
	# human skeleton's own spine segments, see build_spine_column()) --
	# matching it into the fur-material list here would call a method on a
	# freed Object.
	var fur_material_parts: Array[MeshInstance3D] = [hips as MeshInstance3D, chest, neck]
	if not skeleton_mode:
		fur_material_parts.append(abdomen)
	for leg_pivot_node in [leg_left, leg_right]:
		var leg_tilt := leg_pivot_node.get_child(0) as Node3D
		var knee_pivot := leg_tilt.get_child(1) as Node3D
		fur_material_parts.append(leg_tilt.get_child(0) as MeshInstance3D)
		fur_material_parts.append(knee_pivot.get_child(0) as MeshInstance3D)
	for shoulder in [arm_left, arm_right]:
		fur_material_parts.append(shoulder.get_child(0) as MeshInstance3D)
	for elbow in [elbow_left, elbow_right]:
		fur_material_parts.append(elbow.get_child(0) as MeshInstance3D)
	for part in fur_material_parts:
		if part != null:
			part.set_surface_override_material(0, body_fur_material)

	# --- Hands/feet a bit longer (see this file's own class doc comment). ---
	var hand_left := pivots["hand_left"] as MeshInstance3D
	var hand_right := pivots["hand_right"] as MeshInstance3D
	hand_left.scale.y *= HAND_LENGTH_SCALE
	hand_right.scale.y *= HAND_LENGTH_SCALE
	# Per direct instruction: twist the wrists so the back of the hand
	# faces more toward the front, matching a real ape's forward-hanging
	# arm posture instead of ProceduralFigure's own human "palm toward the
	# thigh" resting twist (hand.rotation.y, baked in by _build_arm()).
	# Left/right get opposite twists by construction (mirror symmetry) --
	# the ABSOLUTE direction isn't visually verified, so if this reads as
	# twisting the wrong way, negate HAND_TWIST_ANGLE.
	hand_left.rotation.y += HAND_TWIST_ANGLE
	hand_right.rotation.y -= HAND_TWIST_ANGLE
	# Per direct instruction: angle the fingertip end down and back. The
	# hand is elongated along its own local -Y (see HAND_LENGTH_SCALE
	# above -- it hangs fingertip-down from the wrist), so this is a pitch
	# (rotation.x) on top of the wrist twist above, not a further twist.
	# Same "chain hanging below a pivot swings opposite the pivot's own
	# tip" sign convention this file already relies on elsewhere (see the
	# class doc comment's own derivation note): a POSITIVE rotation.x here
	# should swing the (local -Y) fingertip toward -Z, this rig's own
	# "back" -- not visually confirmed.
	hand_left.rotation.x += HAND_TIP_DOWN_BACK_ANGLE
	hand_right.rotation.x += HAND_TIP_DOWN_BACK_ANGLE
	var foot_left := (pivots["ankle_left"] as Node3D).get_child(0) as MeshInstance3D
	var foot_right := (pivots["ankle_right"] as Node3D).get_child(0) as MeshInstance3D
	# scale.z alone stretches the foot mesh around ITS OWN origin, which
	# procedural_figure.gd already offsets forward of the ankle by
	# FOOT_SIZE.z * 0.35 (so the heel reads as sitting under the shin --
	# see that file's own comment at the foot's position line). Stretching
	# around that off-center origin pushes the heel backward by the same
	# amount it pushes the toe forward, so the heel ends up sticking out
	# the back -- per direct correction. Shifting the foot forward by the
	# added half-length keeps the heel pinned at its original spot and
	# puts all of the added length where a real elongated ape foot should
	# have it: extending the toe. Per a further direct correction, the
	# heel still read as sticking out even at that pinned-in-place spot --
	# FOOT_FORWARD_SHIFT_EXTRA nudges the whole foot forward past just
	# pinning the heel, an additional first-pass amount not derived from
	# anything else in this file.
	var foot_length_added := (FOOT_LENGTH_SCALE - 1.0) * ProceduralFigure.FOOT_SIZE.z
	var foot_forward_total := foot_length_added + ProceduralFigure.FOOT_SIZE.z * FOOT_FORWARD_SHIFT_EXTRA
	if foot_left != null:
		foot_left.scale.z *= FOOT_LENGTH_SCALE
		foot_left.position.z += foot_forward_total
	if foot_right != null:
		foot_right.scale.z *= FOOT_LENGTH_SCALE
		foot_right.position.z += foot_forward_total

	# --- Feet less rounded and flatter: epsilon and the vertical half-
	# extent are both baked into the mesh at generation, not transform
	# properties, so this rebuilds the geometry outright (same render size
	# ProceduralFigure._build_leg() originally used, just a higher epsilon
	# and a shorter Y) rather than adjusting the existing mesh -- per
	# direct instruction. ---
	var foot_half_height_old := ProceduralFigure.FOOT_SIZE.y + ProceduralFigure.JOINT_OVERLAP * 0.5
	var foot_half_height_new := foot_half_height_old * FOOT_FLATTEN_SCALE
	var foot_flatten_delta := foot_half_height_old - foot_half_height_new
	var foot_render_size := Vector3(ProceduralFigure.FOOT_SIZE.x, foot_half_height_new, ProceduralFigure.FOOT_SIZE.z)
	if foot_left != null:
		foot_left.mesh = SuperEgg.build_mesh(foot_render_size, FOOT_EPSILON, FOOT_EPSILON)
		# Shift the (now thinner) mesh UP by the flatten delta, relative to
		# ankle_pivot, so its own TOP surface stays exactly where
		# ProceduralFigure originally put it (flush against the ankle)
		# instead of dropping away and opening a gap there as the foot gets
		# thinner. rig.position.y below is what actually reads as "the body
		# lowered down at the ankle toward the heel" -- this shift is what
		# keeps that drop from ALSO pulling the ankle away from the foot's
		# own top surface at the same time.
		foot_left.position.y += foot_flatten_delta
	if foot_right != null:
		foot_right.mesh = SuperEgg.build_mesh(foot_render_size, FOOT_EPSILON, FOOT_EPSILON)
		foot_right.position.y += foot_flatten_delta
	# Two effects both need undoing at the rig level to keep the sole flush
	# on the ground: the flatten itself (shrinks the mesh's own downward
	# reach by foot_flatten_delta) AND the upward per-foot shift just above
	# (which raises the sole by that same amount again, on top of the
	# flatten's own effect) -- so twice foot_flatten_delta altogether. This
	# is what actually reads as "the body lowered down at the ankle toward
	# the heel of the feet," per direct instruction: the whole rig (ankle
	# included) drops to meet the flatter, now-lower-sitting foot, while
	# the foot's own top surface stays snug against the ankle instead of a
	# gap opening up there. Multiplied by `scale` for the same reason the
	# earlier rig.position.y compensation above now is -- see that line's
	# own comment.
	rig.position.y -= 2.0 * foot_flatten_delta * scale

	# --- Hand/foot skin color: the same "skin" as the face mask, i.e.
	# marking_color -- not fur_color, ProceduralFigure's own default for
	# both (standing in for "no clothes" everywhere else on this rig,
	# but hands/feet read as bare skin on a real primate, not fur). Reads
	# marking_color off the same variant key every other marking-colored
	# part on this rig already uses (see this function's own top, where
	# it's now declared early specifically so this section can reach it),
	# so any future species built through this same template (per this
	# file's own class doc comment) gets matching hand/foot skin for free
	# from its own marking_color, with no separate wiring needed. ---
	var limb_skin_material := MonkeyFigure._build_marking_material(marking_color)
	hand_left.set_surface_override_material(0, limb_skin_material)
	hand_right.set_surface_override_material(0, limb_skin_material)
	if foot_left != null:
		foot_left.set_surface_override_material(0, limb_skin_material)
	if foot_right != null:
		foot_right.set_surface_override_material(0, limb_skin_material)

	# --- Inset fur pad on the back of each hand / top of each foot -- see
	# _add_dorsal_fur_pad()'s own doc comment for the geometry and for how
	# outward_axis/proximal_axis/proximal_sign were derived for each. ---
	var hand_render_size := Vector3(
		ProceduralFigure.HAND_SIZE.x + ProceduralFigure.HAND_THUMB_EXTEND * 0.5,
		ProceduralFigure.HAND_SIZE.y,
		ProceduralFigure.HAND_SIZE.z
	)
	# Hand: outward = local Z (the "back of hand" thickness axis, per
	# ProceduralFigure._build_arm()'s own comment: "HAND_SIZE's own
	# thickness axis (z) starts out facing forward/back... reading as the
	# palm facing backward" -- i.e. +Z is the back, -Z the palm, in the
	# mesh's own unrotated local space, independent of whatever hand.
	# rotation.y this file or ProceduralFigure applies on top). Proximal =
	# local Y, sign +1.0 (wrist at +Y, fingertip at -Y, per
	# HAND_TIP_DOWN_BACK_ANGLE's own already-established convention).
	_add_dorsal_fur_pad(hand_left, hand_render_size, fur_color, SuperEgg.EPSILON_SOFT, 2, 1, 1.0)
	_add_dorsal_fur_pad(hand_right, hand_render_size, fur_color, SuperEgg.EPSILON_SOFT, 2, 1, 1.0)
	# Foot: outward = local Y (top of the foot). Proximal = local Z, sign
	# -1.0 (the foot's own local +Z is the toe direction -- see this
	# file's own foot-forward-shift comments above -- so the ankle/heel
	# side, this pad's flush edge, is -Z).
	if foot_left != null:
		_add_dorsal_fur_pad(foot_left, foot_render_size, fur_color, FOOT_EPSILON, 1, 2, -1.0)
	if foot_right != null:
		_add_dorsal_fur_pad(foot_right, foot_render_size, fur_color, FOOT_EPSILON, 1, 2, -1.0)

	# --- Head swap: tear out ProceduralFigure's own human head (mesh, eyes,
	# ears, hair -- all descendants of this single head_mesh child) and
	# rebuild a monkey-style one, scaled up, in its place. head_pivot's own
	# position already sits at the correct neck-top height regardless of
	# head size, so nothing else here needs to move. ---
	var notch_strength: float = variant.get("face_marking_notch_strength", 1.0)
	for child in head_pivot.get_children():
		child.free()
	# head_height_scale (default 1.0, unchanged) lets individual apes grow
	# noticeably taller heads within a range -- per direct instruction.
	# Only .y (height), not the whole MONKEY_HEAD_SIZE_SCALE vector, so a
	# taller head doesn't also widen/deepen at the same time.
	#
	# Per a further direct correction, the stretch must touch ONLY the
	# head's own mesh shape -- not the eyes/ears/face marking/muzzle, which
	# all have to stay exactly where they'd sit on an unstretched head
	# (same size, same position relative to the body). So there are now
	# TWO head sizes: head_size_base (head_height_scale always 1.0) feeds
	# every feature below, while head_size (the real, possibly-stretched
	# one) feeds ONLY the head_mesh geometry itself. head_mesh.position.y
	# is deliberately anchored using head_size_base too, not head_size --
	# so the mesh's own fixed anchor point never moves, and a taller head
	# grows symmetrically around that fixed point (extending both further
	# up AND slightly further down into the neck) rather than dragging
	# everything positioned relative to it upward along with it.
	var head_height_scale: float = variant.get("head_height_scale", 1.0)
	var head_size_scale := MONKEY_HEAD_SIZE_SCALE * Vector3(1.0, head_height_scale, 1.0)
	var monkey_head_size := MonkeyFigure.HEAD_SIZE * head_size_scale
	var monkey_head_size_base := MonkeyFigure.HEAD_SIZE * MONKEY_HEAD_SIZE_SCALE
	# Uniform rescale (preserves the villager head's own elongated
	# proportions) so its overall size matches ProceduralFigure's own much
	# bigger head instead of looking like a tiny monkey skull glued onto a
	# human body -- per direct instruction ("scaled up proportionally to
	# the regular figure's head size"). Vector length is a simple, order-
	# independent stand-in for "overall size" here. The SAME scale factor
	# (derived from the unstretched head, not the stretched one) is reused
	# for both head_size and head_size_base below, so head_height_scale
	# alone still controls how much taller the real head_size ends up
	# relative to head_size_base -- computing this ratio separately for
	# each would let the uniform-rescale step itself dilute or amplify
	# head_height_scale's own effect.
	var head_rescale := ProceduralFigure.HEAD_SIZE.length() / monkey_head_size_base.length()
	var head_size_base := monkey_head_size_base * head_rescale
	var head_size := monkey_head_size * head_rescale
	var head_mesh := SuperEgg.build_part(head_size, fur_color, HEAD_EPSILON, HEAD_EPSILON)
	head_mesh.material_override = MonkeyFigure._build_fur_material(fur_color)
	head_mesh.position = Vector3(0, head_size_base.y, 0)
	head_pivot.add_child(head_mesh)
	if variant.get("has_face_marking", true):
		MonkeyFigure._add_face_marking(head_mesh, notch_strength, head_size_base, marking_color, HEAD_EPSILON)
	# has_nose=false per direct instruction ("get rid of the nose").
	MonkeyFigure._add_muzzle(
		head_mesh, false, head_size_base, marking_color, HEAD_EPSILON, MUZZLE_CHIN_EXTEND, false
	)
	var eye_shape: Dictionary = variant.get("eye_shape", EYE_SHAPE)
	# Per direct instruction: eye color uses the same skin-relative
	# derivation FigureEyes.gd uses for the human figures (base_color.
	# darkened(0.25)), but based on the face mask's own color rather than
	# fur_color -- the mask is what actually surrounds the eyes here, the
	# same way skin does on a human face.
	var eye_color := marking_color.darkened(0.25)
	var eyes := MonkeyFigure._add_eyes(
		head_mesh, fur_color, notch_strength, head_size_base, eye_shape, HEAD_EPSILON, eye_color
	)
	# vertical_shift_fraction=0.12 per direct instruction ("shift the ears
	# upwards on the head by 12%"). pad_color=marking_color per further
	# direct instruction: an inset skin-colored ear pad, the same "skin" as
	# the face mask/hands/feet. head_size_base (not head_size) per the
	# no-stretch-for-features correction above. Skipped entirely in
	# skeleton_mode, per direct instruction ("no ears") -- a bare skull has
	# no external ear at all, not just a recolored one.
	if not skeleton_mode:
		FigureEars.add_ears(head_mesh, head_size_base, fur_color, true, 0.12, marking_color)
	pivots["eyes"] = eyes

	# --- Tail, opt-in via "has_tail" (default false) -- per direct
	# correction, this same template now builds BOTH classes described in
	# docs/world_bible.md's own Primate taxonomy note: apes (no tail) and
	# "primate template" monkeys (tailed, smaller -- see main.gd's own
	# debug-spawn comment for the size-range split). Reuses MonkeyFigure's
	# own tail builder verbatim, same as an earlier version of this file
	# did unconditionally before the no-tail-for-apes correction removed
	# it -- see this file's own class doc comment. ---
	if has_tail:
		var leg_total_length := (
			ProceduralFigure.UPPER_LEG_SIZE.y * 2.0 * THIGH_LENGTH_SCALE + ProceduralFigure.LOWER_LEG_SIZE.y * 2.0
		)
		var tail_hip_depth := ProceduralFigure.HIP_SIZE.z
		# _build_tail()'s own unscaled (length_scale=1.0) reach tops out at
		# body_radius*3.4 (see that function). Solving for the length_scale
		# that turns that into TAIL_REACH_FRACTION*leg_total_length.
		var base_reach := tail_hip_depth * 3.4
		var tail_length_scale := (
			(leg_total_length * TAIL_REACH_FRACTION) / base_reach * (variant.get("tail_length_scale", 1.0) as float)
		)
		# A dedicated pivot, not hips directly -- droops down rather than
		# rigidly inheriting the hips' own forward lean, same derivation
		# (and the same tuned angle) as this file's earlier tail did.
		var tail_pivot := Node3D.new()
		tail_pivot.name = "TailPivot"
		hips.add_child(tail_pivot)
		tail_pivot.rotation.x = deg_to_rad(-22.5)
		pivots["_tail"] = MonkeyFigure._build_tail(
			tail_pivot, fur_color, tail_length_scale, 0.0, tail_hip_depth, TAIL_RADIUS_SCALE
		)

	return pivots


## Piecewise, not a single lerp across the full 0..1 range: body_type=0.5
## (this file's own established default proportions) has to land on
## exactly `baseline` (1.0 for both CHEST_BUILD_SCALE/ABDOMEN_WIDTH_SCALE's
## own callers), which a single ecto-to-meso lerp wouldn't hit unless the
## two endpoints happened to average to exactly 1.0.
static func _lerp_body_type(ectomorph: float, mesomorph: float, body_type: float) -> float:
	if body_type < 0.5:
		return lerpf(ectomorph, 1.0, body_type * 2.0)
	return lerpf(1.0, mesomorph, (body_type - 0.5) * 2.0)


## Shortens leg_pivot's own thigh (the upper-leg mesh built as leg_tilt's
## first child) and moves the knee up to match, so the shortened thigh and
## the (unchanged-length) shin reconnect with no gap. Doesn't touch overall
## rig height -- see build()'s own forward-kinematics vertical-reach
## compensation, which accounts for this shortening together with the
## crouch rotation in one combined calculation.
static func _shorten_thigh(leg_pivot: Node3D, thigh_scale: float) -> void:
	var leg_tilt := leg_pivot.get_child(0) as Node3D
	var knee_pivot := leg_tilt.get_child(1) as Node3D
	var upper_leg_mesh := leg_tilt.get_child(0) as MeshInstance3D
	knee_pivot.position.y *= thigh_scale
	if upper_leg_mesh != null:
		upper_leg_mesh.scale.y *= thigh_scale


## Builds a hand/foot "fur pad" and adds it as a child of `part`, using
## SuperEgg.build_inset_pad_mesh() for the geometry (see that function's
## own doc comment for the full derivation -- general-purpose, not specific
## to this rig, so it lives there rather than duplicated here) and this
## file's own FUR_PAD_* constants for the shaping.
static func _add_dorsal_fur_pad(
	part: MeshInstance3D, part_size: Vector3, fur_color: Color, part_epsilon: float,
	outward_axis: int, proximal_axis: int, proximal_sign: float
) -> void:
	var pad := MeshInstance3D.new()
	pad.name = "FurPad"
	pad.mesh = SuperEgg.build_inset_pad_mesh(
		part_size, part_epsilon, outward_axis, proximal_axis, proximal_sign,
		FUR_PAD_SIDE_INSET, FUR_PAD_TIP_INSET, FUR_PAD_DOME_HEIGHT,
		FUR_PAD_DOME_FALLOFF_EXPONENT, FUR_PAD_BACK_EMBED
	)
	var material := MonkeyFigure._build_fur_material(fur_color)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pad.material_override = material
	part.add_child(pad)


## Moves `node` to `new_parent`, adjusting its own local position by
## `new_parent_offset` (new_parent's own position, in the coordinate frame
## `node.position` was already expressed in) so its world transform is
## unchanged by the reparent -- valid as long as neither the old nor the
## new parent carries any rotation yet at the time this runs, which is true
## everywhere this is called (before any lean/tilt rotation is applied).
static func _reparent_keep_local(node: Node3D, new_parent: Node3D, new_parent_offset: Vector3) -> void:
	var old_local := node.position
	node.get_parent().remove_child(node)
	new_parent.add_child(node)
	node.position = old_local - new_parent_offset
