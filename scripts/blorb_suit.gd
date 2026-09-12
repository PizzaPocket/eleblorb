class_name BlorbSuit
extends RefCounted

## Geometry toolkit for the blorb suit's worn pieces -- stateless (every
## function is static; blorb_suit_controller.gd is the stateful half that
## drives the equip/unequip hop animation and calls into this every frame).
## Per direct instruction, each worn slot is now a SINGLE flexible piece,
## not the segmented-per-body-part version an earlier pass built:
##
## - Arm/leg: a "noodle" -- one continuous tube lofted through the real
##   joint positions (shoulder/elbow/hand, hip/knee/ankle/toe), rebuilt
##   every frame from those joints' live global positions (see
##   rebuild_slot()) so it bends with the actual walk/run/jump animation
##   instead of needing its own skeleton.
## - Torso: one big oval (a SuperEgg ellipsoid, epsilon=2 -- see
##   superegg.gd's own note that epsilon=2 is a plain ellipse) covering the
##   thorax, no separate abdomen segment.
## - Head: the SAME lathe silhouette blorb.gd's own body uses (see
##   BlorbBodyShape), just bigger and worn like a hat -- the player's own
##   head embeds up into its underside, and its back droops down since
##   there's no ground for its underside to rest flush against the way an
##   ordinary blorb's does.
##
## Every piece is tinted/lit from `blorb.body_visual_snapshot()` (color,
## gloss, emission, whether its element gives off real light) rather than
## re-deriving blorb.gd's own per-element match statement a second time.

## How much bigger than the real limb's own thickness the noodle renders --
## "thick, encapsulating the arms," per direct correction (raised from an
## initial, too-thin 1.5 pass).
const LIMB_INFLATE := 2.1
const LIMB_RADIAL_SEGMENTS := 14
const RINGS_PER_SEGMENT := 6
## Fraction of the tube's own total length spent easing each end down to a
## point (a plain sin() quarter-ease, zero slope at the very tip, so it
## rounds off instead of coming to a sharp cone) -- see _cap_taper().
const TUBE_CAP_FRACTION := 0.1

## How far the arm noodle's wrist/tip control points shift outward (see
## rebuild_arm()), per direct instruction -- "a bit bulkier" at the hand
## end, applied as a control-point shift rather than a radius increase
## specifically so it only grows the intended direction (outward) instead
## of also reaching into the tight space against the body. The leg noodle
## had an equivalent forward bulge at the foot; dropped per direct
## correction (see rebuild_leg()'s own comment) to simplify back to a
## plain baseline shape.
const HAND_BULGE_OUTWARD := 0.03
## How far past the real fingertip/toe the tube's own last control point
## reaches (see rebuild_arm()'s/rebuild_leg()'s own comments) -- gives the
## cap taper's zero-radius point somewhere to shrink to that isn't exactly
## on top of the real fingertip/toe.
const FINGERTIP_REACH_MARGIN := 0.025
const TOE_REACH_MARGIN := 0.025

## Raised 20% per direct correction ("should totally encapsulate the
## thorax") on top of the earlier 1.25 pass -- 1.25 * 1.2.
const TORSO_INFLATE := 1.5
## Height gets the same 20% growth the width/depth just did (via
## TORSO_INFLATE above), applied separately since the chest's own Y span
## (see build_torso()) isn't run through TORSO_INFLATE at all -- grown
## symmetrically around the same center so the oval overshoots the real
## chest's own top/bottom edges a little on both ends instead of just
## matching them exactly, which is what "totally encapsulate" needs.
const TORSO_HEIGHT_INFLATE := 1.2
## Extends only the BOTTOM edge of the chest oval further down, per direct
## instruction ("extend the bottom of the chest piece downards by about
## 4cm") -- the top edge must stay exactly where TORSO_HEIGHT_INFLATE left
## it, so this is applied asymmetrically in build_torso() (half onto
## half_height, half onto center_y) rather than folded into
## TORSO_HEIGHT_INFLATE itself. 0.01 units = 1cm, per this project's
## established scale convention (see HAT_LOWER_SHIFT etc. below).
const CHEST_BOTTOM_EXTEND := 0.04

## Bumped up from an earlier, much smaller pass per direct correction
## ("you made them too tiny to see") -- limb eyes/cores read clearly now
## rather than needing to be hunted for. Pulled back down 10% per a
## further direct correction ("hands and feet... 10% smaller") -- both
## ARM_EYE_RADIUS_FRACTION and LEG_EYE_RADIUS_FRACTION derive from it
## below, so this one change covers both.
const EYE_RADIUS_FRACTION := 0.24 * 0.9
const CORE_RADIUS_FRACTION := 0.34
## Per direct instruction ("reduce the size by 15%") -- legs get their own
## dedicated fraction instead of sharing EYE_RADIUS_FRACTION directly, the
## same reason ARM_EYE_RADIUS_FRACTION already has its own (this change
## must not also shrink the arm's own eyes, which derive from
## EYE_RADIUS_FRACTION independently).
const LEG_EYE_RADIUS_FRACTION := EYE_RADIUS_FRACTION * 0.85
## The torso surface is much bigger than a limb, so the SAME fraction the
## limbs use would read as huge -- went through a couple of independently-
## guessed corrections (0.42 -> "way way too big" -> 0.16 -> "about 12%
## smaller than they are now"), then a principled derivation instead of
## another guess ("proportional to this mass of blorb": blorb_face.gd's
## own real eyes are sized as 0.16 * 0.5 of "radius at eye height," and
## applying that SAME fraction to the torso's own half_width -- itself
## already a stand-in for how much blorb mass this covering represents --
## is the size a real blorb's eyes would be scaled down to this covering's
## own size). That principled value then still read as "a little too
## small" per direct correction, so doubled from there on top, then pulled
## back down 10% per a further direct correction ("chest... 10% smaller"),
## then a further 10% per a later direct instruction ("reduce the size by
## 10%").
const TORSO_EYE_RADIUS_FRACTION := 0.16 * 0.5 * 2.0 * 0.9 * 0.9
const TORSO_CORE_RADIUS_FRACTION := 0.12
## How flat the eye discs render (scale.z -- see _update_face()) -- the
## default (EYE_FLATTEN) matches blorb_face.gd's own ordinary blorb eyes.
## Per direct correction ("too 3 dimensional, only their front face should
## really be maintained") the chest eyes went much flatter than that
## first, then flatter again per a further direct correction ("reduce the
## depth") -- only scale.z (depth) is ever touched by this, x/y (the
## front-facing silhouette) stay untouched regardless, so flattening
## further never shrinks the front face itself. All doubled again per a
## further direct correction ("slightly thicker to compensate in case the
## curve of the skin would expose them") -- a curved or angled surface can
## otherwise reveal a razor-thin disc's own edge/backside past its
## embedded front face.
const EYE_FLATTEN := 0.4 * 2.0
const TORSO_EYE_FLATTEN := 0.06 * 2.0
## How far apart the two eyes sit (a multiple of the eye's own radius --
## see _update_face()) -- the default matches blorb_face.gd's own ordinary
## spacing. Per direct correction ("space them out from each other more")
## the chest eyes sit further apart than that.
const EYE_SPACING := 2.3
const TORSO_EYE_SPACING := 3.4
## Per direct instruction ("blorbs eyes should never protrude out from
## their skin, they should sit flush... just emerged enough to be
## visible") -- matches blorb_face.gd's own EMBED_DEPTH_FRACTION exactly
## (real blorb eyes sink INWARD from the true surface by this fraction of
## their own radius, `surface - outward * (eye_radius * 0.35)`).
## _update_face()'s eyes now do the same, given a true surface point by
## each caller -- an earlier version pushed OUTWARD from `center` instead
## (the opposite sign from blorb_face.gd's own established convention),
## which is exactly what read as protruding.
const EYE_EMBED_FRACTION := 0.35
## Per direct correction ("flatter and about 15% smaller") -- the arm's
## own eyes get their own dedicated fraction/flatten rather than sharing
## the general limb default above, which legs still use unchanged. Flatten
## doubled again alongside EYE_FLATTEN/TORSO_EYE_FLATTEN (see that
## comment).
const ARM_EYE_RADIUS_FRACTION := EYE_RADIUS_FRACTION * 0.85
const ARM_EYE_FLATTEN := 0.18 * 2.0
## Per direct instruction ("give those [feet] eyes the same thickness")
## -- legs now match the arm's own flatten instead of falling through to
## the much-thicker general default above.
const LEG_EYE_FLATTEN := ARM_EYE_FLATTEN
## Rotates each eye outward (around `up`, away from the other) by this
## angle, per direct instruction ("adjust for the curve of the chest
## shape"/"rotate them each outward... to fit more the curve of the blorb
## skin") -- the surface curves away from a flat tangent at the eyes' own
## position (same "sticker on a ball" issue blorb_face.gd's own docstring
## describes for the real body), and this small extra splay compensates.
## The arm/leg tubes curve more sharply (a smaller local radius) than the
## torso's own broader, flatter chest face, so their own tilt is bigger.
##
## Originally 1/1/3 degrees -- per direct report ("I don't see that the
## eye splay has taken effect at all"), re-checked the rotation logic
## itself (Basis.rotated() pre-multiplies, so `up` is applied in the same
## local frame `facing`/`right` already are -- no frame mismatch found)
## and found no bug there. This project has hit this exact failure mode
## before, twice: TOE_OUT_ANGLE and WRIST_INWARD_ANGLE were both
## originally 1 degree and both turned out completely imperceptible at
## normal camera distance, needing roughly a 7x bump each to actually
## read. On top of that, these eyes are already scaled quite thin along
## the very axis being rotated (see EYE_FLATTEN/TORSO_EYE_FLATTEN), which
## makes an already-small rotation even harder to see. Raised well past
## the earlier values on that same precedent rather than a small nudge.
const TORSO_EYE_OUTWARD_TILT := deg_to_rad(10.0)
## How far past the true chest surface the eyes push out, per direct
## instruction -- a further translation on top of _update_face's own
## (fixed, EYE_EMBED_FRACTION-based) embed, not a change to that embed
## itself.
const TORSO_EYE_FORWARD_PUSH := 0.005
const ARM_EYE_OUTWARD_TILT := deg_to_rad(12.0)
## Splayed a further 4 degrees per a later direct instruction ("splay them
## another 4 degrees") on top of the original 12.
const LEG_EYE_OUTWARD_TILT := deg_to_rad(12.0 + 4.0)
## Per direct instruction ("lower the eyes and core downward by about
## 4cm") -- a flat shift on top of the foot's own "above the tip of the
## boot" reach (see rebuild_leg()'s own eye_anchor).
const FOOT_EYE_LOWER := 0.04
## Tilts the foot's own eye/core-facing direction back and up toward the
## sky, per direct instruction, rather than the plain forward-facing FRONT
## every other limb uses -- see rebuild_leg()'s own eye_facing for the
## (unconfirmed-in-engine) sign derivation. Tilted a further 5 degrees per
## a later direct instruction ("rotate them back toward the sky another 5
## degrees") on top of the original 15.
const FOOT_EYE_TILT_BACK := deg_to_rad(15.0 + 5.0)
## The core sits this much further below the eyes specifically, per direct
## instruction ("the core should shift down another cm") -- on top of
## FOOT_EYE_LOWER above, which moves the eyes AND the core's own shared
## anchor together; this is the core-only extra on top of that shared
## shift (see rebuild_leg()'s own core_offset).
const FOOT_CORE_EXTRA_LOWER := 0.01
## How far back (toward the ankle/shin, opposite the foot's own live
## forward/toe direction) the leg's own core shifts from its shared anchor
## with the eyes, per direct instruction ("move the cores in his legs back
## toward his legs a few cm") -- same "0.01 = 1cm" scale convention as the
## other flat shifts above.
const LEG_CORE_BACK_SHIFT := 0.03
## How far up (world/root-local +Y) the arm's own eyes shift from their
## plain resting anchor (hand_surface, see rebuild_arm()), per direct
## instruction -- only the eyes, not the core, hence passed as
## _update_face()'s own separate eye_offset rather than moving hand_surface
## itself (which the core position also derives from).
const ARM_EYE_RAISE := 0.02

## Core sizing/submersion -- see _update_face()'s own comment for why this
## is now fully independent of the eyes' own radius. CORE_MAX_REF_FRACTION
## caps the core's own radius well under ref_size (the piece's available
## thickness) so it can always fit submerged with room to spare;
## CORE_SUBMERGE_MARGIN insets it by more than its own radius (not
## exactly its own radius), so its near edge sits safely inside the true
## surface rather than just tangent to it.
const CORE_MAX_REF_FRACTION := 0.5
const CORE_SUBMERGE_MARGIN := 1.25

## Per direct instruction ("way too thick all around, reduce the
## circumference by 25%") -- applied to every leg radius uniformly.
const LEG_RADIUS_SCALE := 0.75
## r_tip = r_wrist * this (rebuild_arm), r_toe = r_ankle * this
## (rebuild_leg) -- named here (not left as inline literals at their own
## use sites) purely so _CORE_MATCH_R_WRIST/_CORE_MATCH_R_ANKLE below can
## reference the exact same ratio rather than a second hardcoded copy.
const HAND_TIP_RADIUS_RATIO := 0.7
const FOOT_TOE_RADIUS_RATIO := 0.8
## Where along wrist->tip / ankle->toe each limb's own eye/core anchor
## sits (see rebuild_arm()'s HAND_EYE_T / rebuild_leg()'s BOOT_EYE_T) --
## same reason as the ratios above: shared here so the core-size match
## derivation below uses the exact real value.
const HAND_EYE_T := 0.55
const BOOT_EYE_T := 0.8
## Eye/core frame is now measured directly back from ToeAttach, rather than
## interpolated from the ankle, so it remains locked to the live foot tip.
const BOOT_EYE_BACK_FROM_TOE := 0.12

## The foot's own r_ankle (see rebuild_leg()) is noticeably bigger than
## the arm's own r_wrist (see rebuild_arm()) -- FOOT_SIZE's own average
## half-extent is bigger than HAND_SIZE's -- so sharing the plain
## CORE_RADIUS_FRACTION for both (the same FRACTION of a bigger ref_size)
## gave the foot a visibly bigger core in absolute terms even though nothing
## about the foot's own core was deliberately sized up. Per direct
## instruction ("reduced... to be around the same size as the one in the
## arm"), this is solved for algebraically rather than re-guessed: choosing
## LEG_CORE_RADIUS_FRACTION so that (the leg's own eye/core ref_size) *
## LEG_CORE_RADIUS_FRACTION equals (the arm's own eye/core ref_size) *
## CORE_RADIUS_FRACTION exactly. ref_size for each is the tube's LOCAL
## radius at its own eye/core anchor point (HAND_EYE_T/BOOT_EYE_T lerped
## toward the smaller tip/toe radius), not the raw wrist/ankle radius --
## see rebuild_arm()'s/rebuild_leg()'s own r_local, which these mirror.
## Kept as a const expression (not hardcoded numbers) specifically so it
## stays correct automatically if LIMB_INFLATE or any of the ratios/
## multipliers above ever change.
const _CORE_MATCH_R_WRIST := (
	(ProceduralFigure.HAND_SIZE.x + ProceduralFigure.HAND_SIZE.z) * 0.5 * LIMB_INFLATE * 1.2
	* ((1.0 - HAND_EYE_T) + HAND_TIP_RADIUS_RATIO * HAND_EYE_T)
)
const _CORE_MATCH_R_ANKLE := (
	(ProceduralFigure.FOOT_SIZE.x + ProceduralFigure.FOOT_SIZE.z) * 0.5 * LIMB_INFLATE * 1.1 * LEG_RADIUS_SCALE
	* ((1.0 - BOOT_EYE_T) + FOOT_TOE_RADIUS_RATIO * BOOT_EYE_T)
)
const LEG_CORE_RADIUS_FRACTION := CORE_RADIUS_FRACTION * _CORE_MATCH_R_WRIST / _CORE_MATCH_R_ANKLE

## Raised 10% per direct correction ("increase its size by 10%") on top of
## the earlier 1.55 pass -- 1.55 * 1.1. HAT_HEIGHT_SCALE doesn't need its
## own separate bump: hat_height is derived as hat_radius * HAT_HEIGHT_
## SCALE (see build_head()), so it already grows the same 10% for free
## alongside hat_radius.
const HAT_RADIUS_SCALE := 1.55 * 1.1
const HAT_HEIGHT_SCALE := 1.25
## How far the hat's back sags down (as a fraction of its own radius) at
## its most-negative-Z point, per direct instruction ("since the bottom of
## the slime isn't on the ground it can slope down a bit in the back").
## Reduced modestly so the rear still settles lower without forming such a
## deep hanging lobe.
const HAT_DROOP_FRACTION := 0.48
## How far down over the head's own crown the hat's bottom pole sinks --
## the same "head butts up into it" overlap idea figure_hair.gd's own
## buzzcut uses for the real hair, per direct instruction.
const HAT_EMBED_FRACTION := 0.32
const HAT_EYE_T := 0.42  # matches blorb.gd's own EYE_T -- the same relative face height every blorb uses
## Per direct instruction ("reduce the size of the head core by 33%") --
## the hat's own core gets a dedicated scale-down on top of the shared
## CORE_RADIUS_FRACTION (see build_head()) rather than touching that
## fraction itself, which the torso/arm/leg cores all also derive from.
const HAT_CORE_RADIUS_SCALE := 1.0 - 0.33
## Lowered 1cm, then another 2cm, then another 1cm, then another 1cm (0.05
## total), and shifted back 1cm then another 1cm (0.02 total) -- flat
## translations on top of HAT_EMBED_FRACTION's own embed, same "0.01 = 1cm"
## convention figure_hair.gd's own FLAT_TOP_BACK_SHIFT/HERO_UP_SHIFT use.
## Back is -Z, this project's own "+Z is forward" convention.
const HAT_LOWER_SHIFT := 0.05
const HAT_BACK_SHIFT := 0.02

## Which body part a limited-size party gets covered on first. The starter
## trio deliberately becomes a hood plus a pair of blorb skates: the head
## and both legs fill before any torso or arm slot. Later party members then
## fill the remaining slots in a stable, predictable order.
const SLOT_ORDER := ["head", "leg_left", "leg_right", "torso", "arm_left", "arm_right"]
const DYNAMIC_SLOTS := ["arm_left", "arm_right", "leg_left", "leg_right"]
const AIR_WING_BASE_PITCH := deg_to_rad(110.0)
const AIR_WING_BOOK_OPEN_ANGLE := deg_to_rad(22.0)

## Human-readable slot names for UI display (InventoryUI's blorb rows) --
## "Left Arm"/"Right Leg", not slot.capitalize()'s literal "Arm_left"/
## "Leg_right". Side word FIRST, per direct instruction: this project always
## names a limb by the character's own anatomical side (see procedural_
## figure.gd's own note on this, and the figure-rig skill), and English
## puts that adjective before the body part it describes ("left arm," never
## "arm left").
const SLOT_DISPLAY_NAMES := {
	"torso": "Torso",
	"head": "Head",
	"arm_left": "Left Arm",
	"arm_right": "Right Arm",
	"leg_left": "Left Leg",
	"leg_right": "Right Leg",
}


static func is_dynamic_slot(slot: String) -> bool:
	return slot in DYNAMIC_SLOTS


static func slot_display_name(slot: String) -> String:
	return SLOT_DISPLAY_NAMES.get(slot, slot.capitalize())


## Floored well above the true geometric ratio (see slot_shrink_scale()
## below) so a flying blorb still reads as a blorb right up to the moment
## it lands, rather than shrinking to an imperceptible speck.
const SLOT_SHRINK_MIN := 0.32


## A rough "how big does this slot's own covering read as, compared to a
## whole ordinary blorb" ratio -- purely cosmetic, driving the shrink-in/
## grow-back scale as a blorb hops onto/off of its slot (see
## blorb_suit_controller.gd's own hop update), per direct instruction that
## it should visibly shrink to match the mass of the part it's becoming.
## Not used by the actual per-slot geometry above -- just a characteristic
## radius for each slot, relative to Blorb.RADIUS (the whole-blorb body's
## own radius). `rig_scale` (see rebuild_arm()/rebuild_leg()/build_torso()/
## build_head()'s own param of the same name) shrinks characteristic_radius
## the same way it shrinks the actual worn geometry, so a blorb hopping onto
## a much smaller rig (Xiao Hou Zi's) settles down to a correspondingly
## smaller size instead of always shrinking to the fixed human-sized target.
static func slot_shrink_scale(slot: String, rig_scale: float = 1.0) -> float:
	var characteristic_radius: float
	match slot:
		"arm_left", "arm_right":
			characteristic_radius = _avg_xz(ProceduralFigure.UPPER_ARM_SIZE) * LIMB_INFLATE * rig_scale
		"leg_left", "leg_right":
			characteristic_radius = _avg_xz(ProceduralFigure.UPPER_LEG_SIZE) * LIMB_INFLATE * rig_scale
		"torso":
			characteristic_radius = ProceduralFigure.CHEST_SIZE.x * TORSO_INFLATE * rig_scale
		"head":
			characteristic_radius = maxf(ProceduralFigure.HEAD_SIZE.x, ProceduralFigure.HEAD_SIZE.z) * HAT_RADIUS_SCALE * rig_scale
		_:
			characteristic_radius = Blorb.RADIUS
	return maxf(characteristic_radius / Blorb.RADIUS, SLOT_SHRINK_MIN)


## Called once, right when a blorb's landing hop completes (see
## blorb_suit_controller.gd). Torso/head are single-pivot pieces -- fully
## built here and left alone from then on, since parenting onto that one
## pivot already gives them its real animation for free. Limb slots
## (arm_*/leg_*) instead get an empty MeshInstance3D parented onto `root`
## (the player's own stable, non-per-joint-rotated Visuals root) -- the
## controller calls rebuild_slot() on it every frame afterward, since a
## noodle spanning multiple independently-moving joints has to be
## regenerated from their live positions rather than just inheriting one
## pivot's transform.
static func equip_slot(slot: String, pivots: Dictionary, root: Node3D, blorb: Blorb, rig_scale: float = 1.0, lava_helm_command: bool = false) -> Array[Node3D]:
	var pieces: Array[Node3D] = []
	match slot:
		"arm_left", "arm_right", "leg_left", "leg_right":
			var mesh_instance := MeshInstance3D.new()
			root.add_child(mesh_instance)
			rebuild_slot(mesh_instance, slot, pivots, root, blorb, rig_scale, lava_helm_command)
			pieces.append(mesh_instance)
		"torso":
			pieces = build_torso(pivots["spine"] as Node3D, blorb, rig_scale, lava_helm_command)
		"head":
			pieces = build_head(pivots["head"] as Node3D, blorb, rig_scale)
	if blorb.element_state == "air":
		var wing_anchor: Node3D = pivots.get(_air_wing_anchor_key(slot), root) as Node3D
		var wing_attachment := _air_wing_attachment(slot, rig_scale)
		var arm_wings := slot == "arm_left" or slot == "arm_right"
		pieces.append(build_air_wings(wing_anchor, _air_wing_scale(slot) * rig_scale, wing_attachment, arm_wings))
	# Head-fit measurement and visual hiding must distinguish original figure
	# geometry from suit geometry that is still queued for deletion during a
	# rapid remove/re-equip cycle. Mark every returned root once, centrally.
	for piece in pieces:
		piece.set_meta("blorb_suit_piece", true)
	return pieces


static func _air_wing_anchor_key(slot: String) -> String:
	match slot:
		"torso": return "spine"
		"head": return "head"
		# BackAttach is the live, outward-facing hand/blorb surface. Using it
		# as the root eliminates the floating gap from wrist-relative offsets.
		"arm_left": return "back_left"
		"arm_right": return "back_right"
		"leg_left": return "leg_left_ankle"
		"leg_right": return "leg_right_ankle"
	return "spine"


static func _air_wing_scale(slot: String) -> float:
	if slot == "torso":
		return 1.0
	if slot == "head":
		# Hat radius is about one quarter of a free blorb's radius; preserve
		# that same wing-to-body proportion instead of reusing limb scale.
		return 0.15
	if slot == "leg_left" or slot == "leg_right":
		# Foot wings are 30% smaller than the ordinary limb-wing prototype.
		return 0.46 * 0.7
	if slot == "arm_left" or slot == "arm_right":
		# Wrist wings are deliberately a quarter of the old limb scale.
		return 0.46 * 0.25
	return 0.46


static func _air_wing_attachment(slot: String, rig_scale: float = 1.0) -> Vector3:
	if slot == "torso":
		# The chest blorb's back surface is its actual inflated half-depth;
		# root the wing there instead of leaving a visible gap behind it.
		var chest_back := ProceduralFigure.CHEST_SIZE.z * TORSO_INFLATE * 1.2 * rig_scale
		return Vector3(0.0, 0.20 * rig_scale, -chest_back)
	if slot == "head":
		# Match build_head()'s ordinary hat form: base is embedded into the
		# crown, then the wing root sits on the tapered back surface around
		# mid-height. The visible back at this drooped height comes from roughly
		# t=0.72 of the undrooped profile; using the full maximum radius (and an
		# extra rear gap) left the wings floating well behind the hat.
		var head_extent := maxf(ProceduralFigure.HEAD_SIZE.x, ProceduralFigure.HEAD_SIZE.z) * rig_scale
		var radius := head_extent * HAT_RADIUS_SCALE
		var height := radius * HAT_HEIGHT_SCALE
		var hat_base_y := ProceduralFigure.HEAD_SIZE.y * 2.0 * rig_scale - height * HAT_EMBED_FRACTION - HAT_LOWER_SHIFT * rig_scale
		var back_surface_radius := BlorbBodyShape.profile_radius(0.72) * radius
		return Vector3(0.0, hat_base_y + height * 0.55, -back_surface_radius - HAT_BACK_SHIFT * rig_scale)
	if slot == "leg_left" or slot == "leg_right":
		# The leg blorb's widest rear surface at the ankle is r_ankle from
		# rebuild_leg(). Anchor directly to it rather than 36 cm behind it.
		var ankle_radius := _avg_xz(ProceduralFigure.FOOT_SIZE) * LIMB_INFLATE * 1.1 * LEG_RADIUS_SCALE * rig_scale
		return Vector3(0.0, 0.0, -ankle_radius)
	if slot == "arm_left" or slot == "arm_right":
		return Vector3.ZERO
	return Vector3(0.0, 0.0, -0.36 * rig_scale)


## Prototype wings are soft SuperEgg slabs, not flat cards. Each slab's
## inner lower corner is placed at the supplied host-surface attachment;
## their parent is the appropriate live figure pivot, so they inherit the
## character's existing animation for free.
static func build_air_wings(
	anchor: Node3D, scale_factor: float, attachment_position := Vector3(0.0, 0.0, -0.16), upside_down := false
) -> Node3D:
	var wings := Node3D.new()
	wings.name = "AirBlorbWings"
	wings.position = attachment_position
	wings.set_meta("upside_down", upside_down)
	# Arm blorbs face down with relaxed arms. Flip the wing frame with that
	# face, so its own up side also aims downward rather than world-up.
	if upside_down:
		wings.rotation.z = PI
	anchor.add_child(wings)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.72, 0.9, 1.0, 0.78)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = Color(0.35, 0.7, 1.0)
	material.emission_energy_multiplier = 0.4
	for side in [-1.0, 1.0]:
		var hinge := Node3D.new()
		# These must have distinct sibling names. A generic duplicate name can
		# be auto-renamed by Godot, which previously made the exact-name flap
		# filter update only one side.
		hinge.name = "WingHingeLeft" if side < 0.0 else "WingHingeRight"
		hinge.set_meta("wing_side", side)
		wings.add_child(hinge)
		# This hinge stays in the unrotated figure frame: +Y is truly up and
		# -Z is the figure's back. It is the shared vertical spine of the
		# open-book motion.
		hinge.rotation.y = side * AIR_WING_BOOK_OPEN_ANGLE
		var pitch := Node3D.new()
		pitch.name = "WingPitch"
		pitch.rotation.x = AIR_WING_BASE_PITCH
		hinge.add_child(pitch)
		var wing := MeshInstance3D.new()
		wing.name = "Wing"
		var half_span := 0.52 * scale_factor
		var half_height := 0.055 * scale_factor
		var half_depth := 0.38 * scale_factor
		wing.mesh = SuperEgg.build_mesh(
			Vector3(half_span, half_height, half_depth), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		wing.set_surface_override_material(0, material)
		# Center the slab one half-span out from the attachment, making its
		# inner lower corner touch the host while the outer end sweeps up/out.
		wing.position = Vector3(side * half_span, half_height, 0.0)
		# The slab spans local X, has a thin local-Y axis, and its chord is
		# local Z. Its pitch is deliberately applied AFTER the upright hinge.
		pitch.add_child(wing)
	return wings


## Shared wing articulation. The root remains attached at its inner corner.
static func animate_air_wings(wings: Node3D, flap_angle: float) -> void:
	# The actual beat is a symmetric book open/close around the figure's real
	# vertical axis: both outer tips travel rearward as it opens.
	# Reset legacy roots made before the hinge/pitch split. This also means a
	# running session upgrades both wings immediately rather than leaving one
	# side in an old, tilted transform until the suit is re-equipped.
	wings.rotation = Vector3(0.0, 0.0, PI if wings.get_meta("upside_down", false) else 0.0)
	for child in wings.get_children():
		# Metadata is the stable semantic identity. It works for both newly
		# built explicit Left/Right hinges and any legacy generic-name nodes.
		if child is Node3D and (child as Node3D).has_meta("wing_side"):
			var hinge := child as Node3D
			var side := hinge.get_meta("wing_side") as float
			var pitch := hinge.get_node_or_null("WingPitch") as Node3D
			if pitch == null:
				# Convert a pre-split wing safely, retaining its local slab
				# placement while moving the shared pitch below the true hinge.
				pitch = Node3D.new()
				pitch.name = "WingPitch"
				hinge.add_child(pitch)
				var legacy_wing := hinge.get_node_or_null("Wing") as Node3D
				if legacy_wing != null:
					var slab_transform := legacy_wing.transform
					hinge.remove_child(legacy_wing)
					pitch.add_child(legacy_wing)
					legacy_wing.transform = slab_transform
			pitch.rotation = Vector3(AIR_WING_BASE_PITCH, 0.0, 0.0)
			hinge.rotation.x = 0.0
			hinge.rotation.z = 0.0
			hinge.rotation.y = side * (AIR_WING_BOOK_OPEN_ANGLE + flap_angle)


## Per-frame geometry rebuild for limb slots -- see equip_slot()'s own
## comment for why only these need it. No-op (safe to call, just does
## nothing useful) for torso/head, which the controller never calls this
## for anyway (see is_dynamic_slot()).
static func rebuild_slot(mesh_instance: MeshInstance3D, slot: String, pivots: Dictionary, root: Node3D, blorb: Blorb, rig_scale: float = 1.0, lava_helm_command: bool = false) -> void:
	match slot:
		"arm_left":
			rebuild_arm(
				mesh_instance, root,
				pivots["arm_left_shoulder"] as Node3D, pivots["arm_left_elbow"] as Node3D,
				pivots["wrist_left"] as Node3D, pivots["fingertip_left"] as Node3D,
				pivots["back_left"] as Node3D, blorb, rig_scale, lava_helm_command
			)
		"arm_right":
			rebuild_arm(
				mesh_instance, root,
				pivots["arm_right_shoulder"] as Node3D, pivots["arm_right_elbow"] as Node3D,
				pivots["wrist_right"] as Node3D, pivots["fingertip_right"] as Node3D,
				pivots["back_right"] as Node3D, blorb, rig_scale, lava_helm_command
			)
		"leg_left":
			rebuild_leg(
				mesh_instance, root,
				pivots["leg_left_hip"] as Node3D, pivots["leg_left_knee"] as Node3D,
				pivots["leg_left_ankle"] as Node3D, pivots["toe_left"] as Node3D, blorb, rig_scale, lava_helm_command
			)
		"leg_right":
			rebuild_leg(
				mesh_instance, root,
				pivots["leg_right_hip"] as Node3D, pivots["leg_right_knee"] as Node3D,
				pivots["leg_right_ankle"] as Node3D, pivots["toe_right"] as Node3D, blorb, rig_scale, lava_helm_command
			)


## Noodle from shoulder through elbow through wrist through fingertip.
## `wrist`/`fingertip` are procedural_figure.gd's own WristAttach/
## FingertipAttach points -- the hand segment's real logical boundaries
## (see that file's own derivation). An earlier version used `hand`'s own
## global_position for "the wrist," which is actually the segment's
## rendered CENTER, not either boundary -- that mistake pulled the whole
## tube's own wrist control point (and everything anchored off it, like
## the eye placement below) down toward the fingers, reported as the eyes
## showing up near the fingertips instead of the back of the hand.
## `rig_scale` rescales every ProceduralFigure-derived radius/offset below to
## fit whichever rig's own live joint positions (shoulder/elbow/wrist/
## fingertip/back) this is actually being lofted onto -- 1.0 for the human
## rig those formulas are natively written in terms of, something smaller
## for Xiao Hou Zi's much smaller MonkeyFigure rig (see
## MonkeyFigure.BLORB_SUIT_RIG_SCALE, the value player.gd actually passes
## through BlorbSuitController.setup()). The joint POSITIONS themselves
## never need correcting -- they're already the real, correctly-proportioned
## live pivots for whichever rig is worn -- only the tube's own THICKNESS
## and the small flat cm-offsets (HAND_BULGE_OUTWARD, FINGERTIP_REACH_MARGIN,
## ARM_EYE_RAISE) that were otherwise sized for the human's much bigger arm.
static func rebuild_arm(
	mesh_instance: MeshInstance3D, root: Node3D, shoulder: Node3D, elbow: Node3D,
	wrist: Node3D, fingertip: Node3D, back: Node3D, blorb: Blorb, rig_scale: float = 1.0,
	lava_helm_command: bool = false
) -> void:
	var vis: Dictionary = blorb.body_visual_snapshot()
	var sealed_lava := blorb.element_state == "fire" and lava_helm_command
	var sealed_lava_radius := 1.32 if sealed_lava else 1.0

	var shoulder_pos := root.to_local(shoulder.global_position)
	var elbow_pos := root.to_local(elbow.global_position)
	var wrist_pos := root.to_local(wrist.global_position)
	# Extended past the real fingertip marker, per direct instruction --
	# the tube's own cap taper (see _cap_taper()) shrinks its radius to
	# exactly ZERO right at the last control point, so placing that point
	# exactly AT the real fingertip left no room for the covering to
	# actually enclose it before pinching off, reported as the fingertip
	# clipping out through the tip of the noodle. Reaching a bit further
	# along the same wrist-to-fingertip direction moves that zero-point
	# past the real hand instead.
	var raw_tip_pos := root.to_local(fingertip.global_position)
	var reach_dir := (raw_tip_pos - wrist_pos).normalized()
	var tip_pos := raw_tip_pos + reach_dir * FINGERTIP_REACH_MARGIN * rig_scale

	# `back` is procedural_figure.gd's own BackAttach point -- already
	# confirmed-by-observation to sit right on the true back-of-hand
	# surface (see that file's own PalmAttach/BackAttach derivation), per
	# direct instruction to use it here rather than re-deriving the
	# direction independently. It carries no rotation of its own (a plain
	# positional child of `hand`), so its own local -Z is exactly "away
	# from the hand" -- the outward, external side facing away from the
	# body at rest (the palm, +Z, faces INWARD toward the body at rest;
	# this is its mirror). At rest facing north, this makes the right
	# arm's eyes look east and the left arm's look west, per direct
	# instruction.
	var outward_dir := _to_local_dir(root, back.global_transform.basis * Vector3(0, 0, -1))

	# Bulkier at the hand end, but only toward the OUTSIDE, per direct
	# instruction -- growing the tube's own uniform circular radius
	# instead would bulge inward too, into the tight space between the
	# arm and the torso. Shifting the wrist/tip control points themselves
	# outward (rather than the radius) pushes that whole end of the tube
	# further out without also reaching further in.
	var wrist_bulged := wrist_pos + outward_dir * (HAND_BULGE_OUTWARD * 0.5 * rig_scale)
	var tip_bulged := tip_pos + outward_dir * (HAND_BULGE_OUTWARD * rig_scale)

	var r_shoulder := _avg_xz(ProceduralFigure.UPPER_ARM_SIZE) * LIMB_INFLATE * sealed_lava_radius * rig_scale
	var r_elbow := _avg_xz(ProceduralFigure.FOREARM_SIZE) * LIMB_INFLATE * sealed_lava_radius * rig_scale
	var r_wrist := _avg_xz(ProceduralFigure.HAND_SIZE) * LIMB_INFLATE * 1.2 * sealed_lava_radius * rig_scale
	var r_tip := r_wrist * HAND_TIP_RADIUS_RATIO
	var points: Array[Vector3] = [shoulder_pos, elbow_pos, wrist_bulged, tip_bulged]
	var radii: Array[float] = [r_shoulder, r_elbow, r_wrist, r_tip]
	if sealed_lava:
		# Carry a rounded dome well beneath the cuirass instead of terminating
		# the raised arm shell in the full-radius planar cut used previously.
		# The intermediate ring reaches full shoulder width before the live
		# pivot, while the farther hidden point gives the start taper room to
		# round closed without exposing skin during articulation.
		var inward := -(elbow_pos - shoulder_pos).normalized()
		var shoulder_overlap := shoulder_pos + inward * 0.035 * rig_scale
		var shoulder_dome_tip := shoulder_pos + inward * 0.12 * rig_scale
		points.push_front(shoulder_overlap)
		radii.push_front(r_shoulder * 1.08)
		points.push_front(shoulder_dome_tip)
		radii.push_front(r_shoulder * 0.72)

	mesh_instance.mesh = build_limb_tube(points, radii, LIMB_RADIAL_SEGMENTS, RINGS_PER_SEGMENT, TUBE_CAP_FRACTION)
	mesh_instance.set_surface_override_material(0, _build_goo_material(vis))

	# Uses the SAME bulged points the tube itself was just built from, so
	# the eye's own surface estimate stays consistent with where the
	# tube's real (now outward-shifted) surface actually is.
	var hand_center := wrist_bulged.lerp(tip_bulged, HAND_EYE_T)
	# The tube's own LOCAL radius at hand_center, not r_wrist -- an earlier
	# version pushed out by the full r_wrist, but hand_center sits partway
	# toward the tapered tip (r_tip, smaller than r_wrist), so the tube's
	# TRUE local radius there is smaller than r_wrist too. Reaching out by
	# the bigger r_wrist overshot PAST the tube's real surface at that
	# point, which is what actually read as "the core is protruding" and
	# "the eyes are hovering 2cm past the skin" -- center itself was never
	# on the true surface to begin with, so no embed fraction could have
	# fixed it. This is also what both the eyes' AND the core's own
	# sizing/submersion below key off (ref_size), so both get proportioned
	# to the tube's real local thickness here, not the wrist's bigger one.
	var r_local := lerpf(r_wrist, r_tip, HAND_EYE_T)
	var hand_surface := hand_center + outward_dir * r_local

	# Ground truth for the eye frame, straight off the hand's own CURRENT
	# rotation rather than anything carried over from a previous frame --
	# see _update_face()'s own comment for why that's necessary (fixes a
	# compounding drift bug). `back` carries no rotation of its own (a
	# plain positional child of `hand`, see procedural_figure.gd's own
	# BackAttach derivation), so its basis IS the hand's live rotation.
	# Local X is the hand's own "width" axis (thumb-to-pinky, orthogonal to
	# the thickness/palm-normal axis outward_dir above already uses) --
	# the natural axis to spread the two eyes across, same as spacing them
	# left/right across a face.
	var right_hint := _to_local_dir(root, back.global_transform.basis * Vector3(1, 0, 0))
	_update_face(
		mesh_instance, hand_surface, outward_dir, r_local, vis,
		ARM_EYE_RADIUS_FRACTION, CORE_RADIUS_FRACTION, ARM_EYE_FLATTEN, EYE_SPACING, ARM_EYE_OUTWARD_TILT,
		right_hint, Vector3.ZERO, Vector3(0, ARM_EYE_RAISE * rig_scale, 0)
	)


## Noodle from hip through knee through ankle through toe. `rig_scale` -- see
## rebuild_arm()'s own doc comment for the full rationale, identical here.
static func rebuild_leg(mesh_instance: MeshInstance3D, root: Node3D, hip: Node3D, knee: Node3D, ankle: Node3D, toe: Node3D, blorb: Blorb, rig_scale: float = 1.0, lava_helm_command: bool = false) -> void:
	var vis: Dictionary = blorb.body_visual_snapshot()
	var sealed_lava := blorb.element_state == "fire" and lava_helm_command
	var sealed_lava_radius := 1.34 if sealed_lava else 1.0

	var hip_pos := root.to_local(hip.global_position)
	var knee_pos := root.to_local(knee.global_position)
	var ankle_pos := root.to_local(ankle.global_position)
	# `toe` is procedural_figure.gd's own ToeAttach point -- the foot
	# mesh's true forward tip (see that file's own derivation), not an
	# approximation, so the noodle can route exactly to it instead of
	# needing excessive flaring at the bottom of the shape to reliably
	# cover an under-reaching guess.
	#
	# Extended past the real toe, same reasoning as rebuild_arm's own
	# FINGERTIP_REACH_MARGIN fix -- the tube's own cap taper (see
	# _cap_taper()) shrinks its radius to exactly ZERO right at the last
	# control point, so leaving that point exactly on the real toe would
	# clip it the same way the fingertip clipped before that fix.
	var raw_toe_pos := root.to_local(toe.global_position)
	var reach_dir := (raw_toe_pos - ankle_pos).normalized()
	var toe_pos := raw_toe_pos + reach_dir * TOE_REACH_MARGIN * rig_scale

	# All radii scaled down 25% overall, per direct instruction ("way too
	# thick all around").
	var r_hip := _avg_xz(ProceduralFigure.UPPER_LEG_SIZE) * LIMB_INFLATE * LEG_RADIUS_SCALE * sealed_lava_radius * rig_scale
	var r_knee := _avg_xz(ProceduralFigure.LOWER_LEG_SIZE) * LIMB_INFLATE * LEG_RADIUS_SCALE * sealed_lava_radius * rig_scale
	var r_ankle := _avg_xz(ProceduralFigure.FOOT_SIZE) * LIMB_INFLATE * 1.1 * LEG_RADIUS_SCALE * sealed_lava_radius * rig_scale
	var r_toe := r_ankle * FOOT_TOE_RADIUS_RATIO

	# An extra control point partway down the shin, per direct instruction
	# ("the enlargement is starting abruptly from the knee... should more
	# bell out as it gets toward the bottom"). Positioned well down toward
	# the ankle (SHIN_POSITION_T) but with a radius only a SMALL fraction
	# of the way toward r_ankle (SHIN_RADIUS_T, well below SHIN_POSITION_T)
	# -- since build_limb_tube() interpolates radius linearly between
	# consecutive control points, this keeps the growth slow through the
	# upper shin (knee -> shin) and lets most of the actual widening happen
	# only in the lower shin (shin -> ankle), reading as a gradual bell
	# rather than a step change right at the knee.
	const SHIN_POSITION_T := 0.65
	const SHIN_RADIUS_T := 0.25
	var shin_pos := knee_pos.lerp(ankle_pos, SHIN_POSITION_T)
	var r_shin := lerpf(r_knee, r_ankle, SHIN_RADIUS_T)

	# Simplified back to the plain (unshifted) ankle/toe positions, per
	# direct instruction -- an earlier pass also shifted these forward
	# ("bulge") and up ("sole clearance") to shape the boot and keep it off
	# the ground, but per direct correction that's being dropped for now to
	# see the shape/eye/core placement on its own simpler baseline first.
	var points: Array[Vector3] = [hip_pos, knee_pos, shin_pos, ankle_pos, toe_pos]
	var radii: Array[float] = [r_hip, r_knee, r_shin, r_ankle, r_toe]
	if sealed_lava:
		# The hip closure follows the rounded shoulder construction above. Its
		# dome closes high inside the diaper-length torso rather than showing a
		# flat circular lid at the top of the leg.
		var upward := -(knee_pos - hip_pos).normalized()
		var hip_overlap := hip_pos + upward * 0.04 * rig_scale
		var hip_dome_tip := hip_pos + upward * 0.14 * rig_scale
		points.push_front(hip_overlap)
		radii.push_front(r_hip * 1.08)
		points.push_front(hip_dome_tip)
		radii.push_front(r_hip * 0.72)

	mesh_instance.mesh = build_limb_tube(points, radii, LIMB_RADIAL_SEGMENTS, RINGS_PER_SEGMENT, TUBE_CAP_FRACTION)
	mesh_instance.set_surface_override_material(0, _build_goo_material(vis))

	# "Above the tip of the boot," per direct instruction -- BOOT_EYE_T of
	# the way from ankle to toe (not the very tip, which the cap taper
	# narrows down toward a point), reached UP onto the boot's own top
	# surface. Anchored on the tube's own centerline, then reach out by the
	# tube's own LOCAL radius there (r_local, not the bigger r_ankle) to
	# actually land on the true surface, letting _update_face's own embed
	# handle sinking the eyes back in from there -- same technique
	# rebuild_arm's own hand_surface uses, but reaching UP (+Y), not
	# FORWARD (+Z), per direct correction ("floating a good 10cm forward
	# in front of his toes"). +Z is genuinely a RADIAL (out-from-centerline)
	# direction for the arm's own tube, which runs mostly vertically -- but
	# the leg's tube runs mostly forward/toe-ward, so pushing further along
	# +Z from a point already most of the way down that same length just
	# kept going past the real toe instead of reaching a side surface. +Y
	# is the genuinely radial direction here instead. Fixing this also
	# fixes the core, which is positioned relative to this same anchor.

	# Pinned to the toe's own live rotation, the same technique
	# rebuild_arm() uses for the hand's BackAttach, per direct instruction.
	# `toe` (ToeAttach) carries no rotation of its own (a plain positional
	# child of `foot`, see procedural_figure.gd's own ToeAttach
	# derivation), so its basis IS the foot's own live rotation (ankle
	# flex, walk-cycle roll, the static toe-out yaw, everything up the
	# chain), recomputed fresh every frame with nothing carried over from
	# a previous one. Local +Z is the foot's own forward/toe direction
	# (see procedural_figure.gd's own "feet extend forward, local +Z"
	# comment); local +Y is the foot's own vertical -- the genuinely
	# radial "reach up to the boot's true surface" direction (see the
	# older fixed-Vector3(0,1,0) version's own comment for why +Y, not
	# +Z, is radial here -- that reasoning is unchanged, just now sourced
	# from the foot's live orientation instead of a world-fixed guess);
	# local +X is the foot's own side-to-side axis, the natural eye-
	# spacing direction, mirroring how right_hint uses the hand's own
	# local X in rebuild_arm().
	var toe_basis := toe.global_transform.basis
	var toe_up := _to_local_dir(root, toe_basis * Vector3(0, 1, 0))
	var toe_forward := _to_local_dir(root, toe_basis * Vector3(0, 0, 1))
	var right_hint := _to_local_dir(root, toe_basis * Vector3(1, 0, 0))
	# The toe's own live transform is the positional AND rotational source
	# of truth. A fixed local-back offset keeps the face/core at the same
	# place on the boot even as ankle and knee animation reshape the leg.
	var boot_centerline := raw_toe_pos - toe_forward * (BOOT_EYE_BACK_FROM_TOE * rig_scale)
	var r_local := lerpf(r_ankle, r_toe, BOOT_EYE_T)

	var eye_anchor := boot_centerline + toe_up * r_local
	# Flat downward shift on top of the reach above, per direct instruction
	# -- same "0.01 = 1cm" scale convention as CHEST_BOTTOM_EXTEND/
	# HAT_LOWER_SHIFT. World-relative (not toe_up-relative) since "lower...
	# downward" was specified in the plain gravity sense, not relative to
	# however the foot happens to be currently angled.
	eye_anchor.y -= FOOT_EYE_LOWER * rig_scale
	# Tilts the eyes' own facing direction back and up (toward the sky)
	# instead of the plain forward-facing FRONT the other limbs use, per
	# direct instruction -- rotated around the toe's own LIVE side axis
	# (right_hint) rather than a fixed world axis, so the tilt stays
	# correct relative to the foot no matter how it's currently posed.
	# Worked out mathematically -- rotating the live forward vector around
	# the live side axis by a NEGATIVE angle lifts its own Y component
	# positive (toward the sky) rather than negative (into the ground) --
	# but not independently confirmed in-engine; if this reads as tilting
	# downward instead, negate the sign on FOOT_EYE_TILT_BACK below.
	var eye_facing := toe_forward.rotated(right_hint, -FOOT_EYE_TILT_BACK)

	# The core sits a further FOOT_CORE_EXTRA_LOWER below wherever the
	# eyes land, per direct instruction -- passed as its own offset rather
	# than folded into eye_anchor/FOOT_EYE_LOWER above since that shift is
	# meant for the eyes specifically, not the core too. Also pulled back
	# along the NEGATIVE of the foot's own live forward/toe direction, per
	# a later direct instruction ("move the cores in his legs back toward
	# his legs a few cm") -- toe_forward points toward the toes, so
	# subtracting it moves the core the opposite way, back toward the
	# ankle/shin (the leg itself), same live-orientation source as the eye
	# frame above rather than a fixed axis.
	var core_offset := Vector3(0, -FOOT_CORE_EXTRA_LOWER * rig_scale, 0) - toe_forward * (LEG_CORE_BACK_SHIFT * rig_scale)
	_update_face(
		mesh_instance, eye_anchor, eye_facing, r_local, vis,
		LEG_EYE_RADIUS_FRACTION, LEG_CORE_RADIUS_FRACTION, LEG_EYE_FLATTEN, EYE_SPACING, LEG_EYE_OUTWARD_TILT,
		right_hint, core_offset
	)


## One big oval covering just the upper chest area of the thorax -- no
## abdomen coverage at all, per direct correction. A SuperEgg with
## epsilon=2 (a plain ellipse cross-section, see superegg.gd's own note)
## rather than the boxier default SuperEgg roundness the earlier segmented
## version used.
## `rig_scale` -- see rebuild_arm()'s own doc comment for the full rationale.
## spine_pivot is already the correct live joint for whichever rig this is
## being dressed onto; every OTHER measurement here (how far above it the
## oval sits, how big it is) is expressed in ProceduralFigure's own human
## terms and needs rescaling to actually land on/around a smaller rig's
## much shorter, narrower chest.
static func build_torso(spine_pivot: Node3D, blorb: Blorb, rig_scale: float = 1.0, lava_helm_command: bool = false) -> Array[Node3D]:
	var vis: Dictionary = blorb.body_visual_snapshot()
	var sealed_lava := blorb.element_state == "fire" and lava_helm_command

	# Spans only the CHEST's own local Y range (from where the abdomen
	# ends to the top of the chest) -- per direct correction, "only in the
	# upper chest area of the thorax segment, forget the abdomen segment."
	var chest_bottom := ProceduralFigure.ABDOMEN_SIZE.y * 2.0 * rig_scale
	var chest_top := chest_bottom + ProceduralFigure.CHEST_SIZE.y * 2.0 * rig_scale
	var half_height := (chest_top - chest_bottom) * 0.5 * TORSO_HEIGHT_INFLATE
	var center_y := (chest_top + chest_bottom) * 0.5
	if sealed_lava:
		# A lava torso is the suit's continuous cuirass. spine_pivot's origin is
		# the TOP of the pelvis (ProceduralFigure.build() places it at abdomen_y),
		# while the hip mesh is centred one HIP_SIZE.y below that and has another
		# HIP_SIZE.y of half-height below its centre.  Its exact lower edge in
		# spine-local space is therefore -2 * HIP_SIZE.y -- not the former 0.55
		# approximation, which stopped high inside the pelvis.  The shared
		# CHEST_BOTTOM_EXTEND applied immediately below then carries the shell a
		# further 4 cm past that edge, giving the requested diaper-like overlap
		# even while the independently animated hips bob beneath the spine.
		var sealed_bottom: float = -ProceduralFigure.HIP_SIZE.y * 2.0 * rig_scale
		var sealed_top: float = chest_top + ProceduralFigure.HEAD_RAISE * 1.35 * rig_scale
		half_height = (sealed_top - sealed_bottom) * 0.5
		center_y = (sealed_top + sealed_bottom) * 0.5
	# Extends the BOTTOM edge down by CHEST_BOTTOM_EXTEND while leaving the
	# top edge exactly where it was, per direct instruction -- the standard
	# asymmetric-extent-plus-offset technique (grow the half-extent by half
	# the extension, shift the center by that same half, in the direction
	# of the growth) already established elsewhere in this project for a
	# one-sided extent change -- see the figure-rig skill's own "durable
	# structural patterns" section for the general derivation.
	half_height += CHEST_BOTTOM_EXTEND * 0.5 * rig_scale
	center_y -= CHEST_BOTTOM_EXTEND * 0.5 * rig_scale
	# Xiao Hou Zi's rig has no separate abdomen/chest segments to derive this
	# offset from -- he's one unified pear-shaped body (see MonkeyFigure's
	# own class doc). Scaling the human's abdomen+chest stack by rig_scale
	# only rescales its THICKNESS; the position it lands at is still stacked
	# on human proportions, which puts it almost at his head. Per direct
	# correction, re-anchor to the actual vertical center of his own body
	# mesh instead -- an absolute offset in spine_pivot's local space, not
	# something rig_scale (a pure size ratio) should touch. Detected the
	# same way the rest of this file already keys "is this Xiao Hou Zi" off
	# rig_scale, since he's the only rig that ever passes a non-1.0 value.
	if not sealed_lava and is_equal_approx(rig_scale, MonkeyFigure.BLORB_SUIT_RIG_SCALE):
		center_y = MonkeyFigure.BODY_HEIGHT * 0.5
	var torso_seal_scale := 1.1 if sealed_lava else 1.0
	var half_width := ProceduralFigure.CHEST_SIZE.x * TORSO_INFLATE * torso_seal_scale * rig_scale
	var half_depth := ProceduralFigure.CHEST_SIZE.z * TORSO_INFLATE * 1.2 * torso_seal_scale * rig_scale
	if blorb.has_core_item("Dented Breastplate") and not sealed_lava:
		return [_build_knight_breastplate(
			spine_pivot, blorb, center_y, half_width, half_height, half_depth, rig_scale
		)] as Array[Node3D]

	var torso := MeshInstance3D.new()
	# Back to a proper SuperEgg roundness (EPSILON_SOFT) per direct
	# correction -- an earlier pass had used epsilon=2.0 (a plain
	# ellipsoid, see superegg.gd's own note that epsilon=2 traces a plain
	# ellipse), but that's being reverted in favor of the boxier-cornered
	# "soft rounded cube" silhouette most other body segments in this
	# project already use.
	torso.mesh = SuperEgg.build_mesh(
		Vector3(half_width, half_height, half_depth), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	torso.set_surface_override_material(0, _build_goo_material(vis))
	torso.position = Vector3(0, center_y, 0)
	spine_pivot.add_child(torso)

	# "Looking forward, as if looking out from the hero's chest," per
	# direct instruction -- see TORSO_EYE_RADIUS_FRACTION/TORSO_EYE_FLATTEN
	# for the (corrected-down) sizing. Z is the true front surface extent
	# (half_depth) now, not a pulled-in approximation of it -- _update_face
	# handles sinking the eyes back in from the true surface by its own
	# small, fixed embed fraction (see EYE_EMBED_FRACTION), matching
	# blorb_face.gd's own real-eye technique, so this should represent the
	# actual surface, not an already-embedded guess.
	var eye_center := Vector3(0, half_height * 0.1, half_depth + TORSO_EYE_FORWARD_PUSH * rig_scale)
	_update_face(
		torso, eye_center, Vector3(0, 0, 1), half_width, vis,
		TORSO_EYE_RADIUS_FRACTION, TORSO_CORE_RADIUS_FRACTION, TORSO_EYE_FLATTEN, TORSO_EYE_SPACING,
		TORSO_EYE_OUTWARD_TILT
	)

	return [torso] as Array[Node3D]


## The absorbed breastplate is the torso counterpart to Knight's Helm: the
## Blorb itself becomes a rounded medieval cuirass in its own material, with
## broad upper armor, a guarded lower flare, an integrated collar, and its
## living face still embedded in the front rather than covered by a prop.
static func _build_knight_breastplate(
	spine_pivot: Node3D, blorb: Blorb, center_y: float,
	half_width: float, half_height: float, half_depth: float, rig_scale: float
) -> Node3D:
	var vis: Dictionary = blorb.body_visual_snapshot()
	var root := Node3D.new()
	root.name = "TorsoBlorbKnightBreastplate"
	root.position.y = center_y
	spine_pivot.add_child(root)

	var plate_csg := CSGCombiner3D.new()
	plate_csg.name = "KnightBreastplateCSG"
	root.add_child(plate_csg)
	var plate := CSGMesh3D.new()
	plate.name = "KnightBreastplateBlorbBody"
	plate.mesh = BlorbBodyShape.build_mesh_from_rings(
		_build_knight_breastplate_rings(half_width, half_height, half_depth)
	)
	plate.material = _build_goo_material(vis)
	plate_csg.add_child(plate)
	var dent_cutter := CSGMesh3D.new()
	dent_cutter.name = "ImpactDent"
	var dent_sphere := SphereMesh.new()
	dent_sphere.radius = half_width * 0.145
	dent_sphere.height = half_width * 0.29
	dent_sphere.radial_segments = 14
	dent_sphere.rings = 8
	dent_cutter.mesh = dent_sphere
	dent_cutter.material = _build_goo_material(vis)
	dent_cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
	dent_cutter.position = Vector3(half_width * 0.34, half_height * 0.27, half_depth * 1.10)
	dent_cutter.scale = Vector3(1.0, 0.82, 0.62)
	plate_csg.add_child(dent_cutter)

	# A raised collar and central keel repeat the helm's close-fitting, rounded
	# construction without turning the Blorb into a stack of ordinary metal.
	var collar := SuperEgg.build_part(
		Vector3(half_width * 0.62, half_height * 0.14, half_depth * 0.72),
		vis["albedo"] as Color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	collar.material_override = _build_goo_material(vis)
	collar.position = Vector3(0.0, half_height * 0.82, -half_depth * 0.02)
	root.add_child(collar)
	var keel := SuperEgg.build_part(
		Vector3(half_width * 0.055, half_height * 0.68, half_depth * 0.055),
		vis["albedo"] as Color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	keel.material_override = _build_goo_material(vis)
	keel.position = Vector3(0.0, -half_height * 0.02, half_depth * 1.02)
	root.add_child(keel)

	var eye_center := Vector3(0.0, half_height * 0.05, half_depth * 1.09 + TORSO_EYE_FORWARD_PUSH * rig_scale)
	_update_face(
		plate, eye_center, Vector3(0, 0, 1), half_width, vis,
		TORSO_EYE_RADIUS_FRACTION, TORSO_CORE_RADIUS_FRACTION,
		TORSO_EYE_FLATTEN, TORSO_EYE_SPACING, TORSO_EYE_OUTWARD_TILT
	)
	return root


static func _build_knight_breastplate_rings(
	half_width: float, half_height: float, half_depth: float
) -> Array:
	# Bottom-to-top profile: guarded skirt, drawn waist, broad shoulder plate,
	# then a rounded close around the neck. Zero-radius poles keep it watertight.
	var profile: Array[Vector2] = [
		Vector2(-1.0, 0.0), Vector2(-0.92, 0.78), Vector2(-0.72, 0.96),
		Vector2(-0.42, 0.84), Vector2(0.18, 0.96), Vector2(0.58, 1.12),
		Vector2(0.80, 1.02), Vector2(0.94, 0.68), Vector2(1.0, 0.0),
	]
	var rings: Array = []
	for profile_point in profile:
		var ring: Array[Vector3] = []
		for segment in BlorbBodyShape.RADIAL_SEGMENTS:
			var angle := TAU * float(segment) / float(BlorbBodyShape.RADIAL_SEGMENTS)
			var radius_scale := profile_point.y
			# The upper front projects into a breastplate/visor-like chest guard,
			# echoing the matching helm's own forward lower-face extension.
			var upper_guard := smoothstep(0.05, 0.72, profile_point.x)
			var front_weight := maxf(sin(angle), 0.0)
			ring.append(Vector3(
				cos(angle) * half_width * radius_scale,
				profile_point.x * half_height,
				sin(angle) * half_depth * radius_scale * (1.0 + upper_guard * front_weight * 0.12)
			))
		rings.append(ring)
	return rings


## A head blorb has two forms: its ordinary drooping hat while on dry land,
## and a spherical diving helmet only while its wearer is buoyant in water
## or giant-blorb goo. Both are built once and the controller toggles their
## visibility, avoiding a mesh rebuild or a pop in the middle of swimming.
## `rig_scale` rescales every ProceduralFigure-derived extent/offset below (see
## rebuild_arm()'s doc comment for the general rationale) so the hat/helmet
## fit whichever rig's own head_pivot this is actually being lofted onto.
static func build_head(head_pivot: Node3D, blorb: Blorb, rig_scale: float = 1.0) -> Array[Node3D]:
	var vis: Dictionary = blorb.body_visual_snapshot()
	# Rigs with non-human proportions publish their real local head dimensions
	# on the pivot. In particular, Xiao Hou Zi's head is proportionally much
	# larger than a scaled-down human head; applying only the whole-rig ratio
	# made his worn head piece look like it had shrunk his skull.
	var fallback_head_size := ProceduralFigure.HEAD_SIZE * rig_scale
	var head_size: Vector3 = head_pivot.get_meta("blorb_suit_head_size", fallback_head_size) as Vector3
	var head_extent := maxf(head_size.x, head_size.z)
	# Measure the actual live head subtree before adding any suit geometry.
	# This includes tall hair and ornaments, which a generic head-size formula
	# can never reliably enclose.
	var worn_head_bounds := _measure_head_contents(head_pivot)
	var albedo := vis["albedo"] as Color
	var hat_radius := head_extent * HAT_RADIUS_SCALE
	var hat_height := hat_radius * HAT_HEIGHT_SCALE
	var hat := MeshInstance3D.new()
	hat.name = "HeadBlorbHat"
	hat.mesh = BlorbBodyShape.build_mesh_from_rings(_build_hat_rings(
		hat_radius, hat_height, hat_radius * HAT_DROOP_FRACTION
	))
	hat.set_surface_override_material(0, _build_goo_material(vis))
	# The hat's bottom pole is embedded slightly into the crown, with the
	# authored lower/back adjustments retained from the original hat form.
	hat.position = Vector3(
		0.0,
		head_size.y * 2.0 - hat_height * HAT_EMBED_FRACTION - HAT_LOWER_SHIFT * rig_scale,
		-HAT_BACK_SHIFT * rig_scale
	)
	head_pivot.add_child(hat)
	var hat_eye: Dictionary = BlorbBodyShape.eye_surface(HAT_EYE_T, hat_radius, hat_height)
	var hat_eye_y := hat_eye["y"] as float
	var hat_eye_radius := hat_eye["radius"] as float
	BlorbFace.add_eyes(
		hat, hat_eye_radius, hat_eye_y, hat_eye["dr_dy"] as float, albedo
	)
	var hat_core := BlorbCore.build(hat_radius * CORE_RADIUS_FRACTION * HAT_CORE_RADIUS_SCALE, vis["core_color"] as Color, vis["core_emissive"] as bool)
	if vis["core_emissive"] as bool:
		var hat_core_material: StandardMaterial3D = hat_core.get_meta("material")
		hat_core_material.emission = vis["core_emission"] as Color
		hat_core_material.emission_energy_multiplier = vis["core_emission_energy"] as float
	hat_core.position = Vector3(0.0, hat_eye_y, hat_eye_radius * 0.3)
	hat.add_child(hat_core)
	_add_head_core_light(hat_core, vis)
	if blorb.has_core_item("Nautilus Crown"):
		_add_nautilus_pirate_hat(hat, hat_radius, vis)
		return [hat] as Array[Node3D]
	if blorb.has_core_item("Knight's Helm"):
		hat.queue_free()
		return [_build_knights_helm(head_pivot, head_extent, vis, rig_scale)] as Array[Node3D]
	# Fire-only, per direct instruction -- thrown_item.gd now refuses the item
	# on any other element before it ever reaches core_items, but this guard
	# also covers a blorb that picked it up before that restriction existed.
	if blorb.has_core_item("Lava Helm") and blorb.element_state == "fire":
		hat.queue_free()
		return [_build_lava_helm(head_pivot, worn_head_bounds, vis)] as Array[Node3D]

	# Only a blorb that has absorbed the Diving Helmet item can transform
	# into the sealed underwater form. Every other head blorb stays a hat.
	if not blorb.has_core_item("Diving Helmet"):
		return [hat] as Array[Node3D]
	var helmet_radius := maxf(head_extent * 1.9, head_size.y * 1.55)
	var helmet := MeshInstance3D.new()
	helmet.name = "HeadBlorbHelmet"
	var sphere := SphereMesh.new()
	sphere.radius = helmet_radius
	sphere.height = helmet_radius * 2.0
	sphere.radial_segments = 28
	sphere.rings = 16
	helmet.mesh = sphere
	helmet.set_surface_override_material(0, _build_goo_material(vis))
	# The figure head mesh is centered at HEAD_SIZE.y under HeadPivot, so
	# the sphere shares that center and fully encloses its crown, face, and
	# back of skull with a generous breathing-space margin.
	helmet.position = Vector3(0, head_size.y, 0)
	head_pivot.add_child(helmet)

	# Sphere surface data at a slightly raised forward eye line. BlorbFace
	# needs the local radius and profile derivative so its eyes remain sunk
	# into the helmet rather than sitting as floating buttons.
	var eye_y := helmet_radius * 0.12
	var eye_radius_at_h := sqrt(maxf(helmet_radius * helmet_radius - eye_y * eye_y, 0.001))
	var eye_slope := -eye_y / eye_radius_at_h
	BlorbFace.add_eyes(
		helmet, eye_radius_at_h, eye_y, eye_slope, albedo
	)

	var core_radius := helmet_radius * CORE_RADIUS_FRACTION * HAT_CORE_RADIUS_SCALE
	var core_color := vis["core_color"] as Color
	var core_emissive := vis["core_emissive"] as bool
	var core := BlorbCore.build(core_radius, core_color, core_emissive)
	if core_emissive:
		var core_material: StandardMaterial3D = core.get_meta("material")
		core_material.emission = vis["core_emission"] as Color
		core_material.emission_energy_multiplier = vis["core_emission_energy"] as float
	core.position = Vector3(0, eye_y, eye_radius_at_h * 0.3)
	helmet.add_child(core)

	_add_head_core_light(core, vis)
	# Dry land defaults to the normal hat. The controller reveals this form
	# when actual lake/goo buoyancy begins.
	helmet.visible = false

	return [hat, helmet] as Array[Node3D]


static func _measure_head_contents(head_pivot: Node3D) -> AABB:
	var found := false
	var bounds := AABB()
	for descendant in head_pivot.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		if (
			mesh_instance == null
			or mesh_instance.mesh == null
			or mesh_instance.name.begins_with("HeadBlorb")
			or _is_suit_geometry(mesh_instance, head_pivot)
		):
			continue
		var source := mesh_instance.mesh.get_aabb()
		for corner_index in 8:
			var corner := source.position + Vector3(
				source.size.x if (corner_index & 1) != 0 else 0.0,
				source.size.y if (corner_index & 2) != 0 else 0.0,
				source.size.z if (corner_index & 4) != 0 else 0.0
			)
			var local_point := head_pivot.to_local(mesh_instance.to_global(corner))
			if not found:
				bounds = AABB(local_point, Vector3.ZERO)
				found = true
			else:
				bounds = bounds.expand(local_point)
	if not found:
		var fallback := ProceduralFigure.HEAD_SIZE
		return AABB(Vector3(-fallback.x, 0.0, -fallback.z), fallback * 2.0)
	return bounds


## A released suit piece remains in the SceneTree until queue_free resolves at
## frame end. Walk ancestors rather than checking only the mesh itself because
## compound pieces such as the Lava Helm mark their returned root while their
## visible mesh lives below it.
static func _is_suit_geometry(node: Node, boundary: Node) -> bool:
	var current: Node = node
	while current != null and current != boundary:
		if current.has_meta("blorb_suit_piece"):
			return true
		current = current.get_parent()
	return false


static func _build_lava_helm(head_pivot: Node3D, contents: AABB, vis: Dictionary) -> Node3D:
	# Per direct correction, the real head stays visible underneath -- a
	# translucent goo overlay over the real body part is how every other
	# suit slot already works (no other slot in this file ever sets a real
	# body-part visual's `visible` to false; this used to be the one
	# exception). `protected_visual_scales` below guards against some other
	# system (a future preview or suit animation change) resetting one of
	# these visuals' scale while this piece is worn -- unrelated to that old
	# hiding, and to head_pivot's own scale (see preserve_covered_head_
	# scale()'s own comment: nothing in this codebase actually scales
	# head_pivot itself, so protecting it was dead defensive code, removed).
	var protected_visual_scales: Array[Dictionary] = []
	for descendant in head_pivot.find_children("*", "VisualInstance3D", true, false):
		var original_visual := descendant as VisualInstance3D
		if (
			original_visual != null
			and original_visual.visible
			and not _is_suit_geometry(original_visual, head_pivot)
		):
			protected_visual_scales.append({
				"visual": original_visual,
				"scale": original_visual.scale,
			})
	var root := Node3D.new()
	root.name = "HeadBlorbLavaHelm"
	root.set_meta("protected_visual_scales", protected_visual_scales)
	head_pivot.add_child(root)

	# Per direct correction, this is Lava Slide's own cashew/bent-pipe head
	# shape, not a dome -- see _build_lava_helm_rings()'s own doc comment
	# for how its single "face" bulge is sized and placed to guarantee full
	# enclosure of `contents` (the actual measured head+hair bounds).
	var shape := _lava_helm_shape(contents)
	var origin: Vector3 = shape["origin"]
	var face_forward: float = shape["face_forward"]
	var bulb_radius: float = shape["bulb_radius"]
	# The pipe's own face point (s=0), i.e. the true center of the
	# enclosing bulge -- not `origin`, which is offset behind it.
	var face_center := origin + Vector3(0.0, 0.0, face_forward)

	var helm := MeshInstance3D.new()
	helm.name = "LavaHelmBlorbBody"
	# Rings come back already in head_pivot's own local space (the same
	# space `contents` was measured in), so the mesh instance itself needs
	# no separate position offset.
	helm.mesh = BlorbBodyShape.build_mesh_from_rings(_build_lava_helm_rings(contents))
	helm.material_override = _build_goo_material(vis)
	root.add_child(helm)
	_add_lava_helm_eyes(helm, contents, vis["albedo"] as Color)

	var core := BlorbCore.build(bulb_radius * CORE_RADIUS_FRACTION * HAT_CORE_RADIUS_SCALE, vis["core_color"] as Color, vis["core_emissive"] as bool)
	core.position = Vector3(face_center.x, face_center.y - bulb_radius * 0.1, face_center.z + bulb_radius * 0.31)
	helm.add_child(core)
	_add_head_core_light(core, vis)
	_add_lava_mohawk(helm, bulb_radius)
	# _add_lava_mohawk() (shared with the player's own worn Lava Helm hat)
	# positions its flame assuming the parent's own origin sits at the
	# object's center -- true there, but our own origin is head_pivot's,
	# offset from the bulge's own center by however the actual head/hair
	# sit within it.
	var mohawk := helm.get_node_or_null("BurningMohawk") as Node3D
	if mohawk != null:
		mohawk.position += face_center

	# The helmet is a covering attached beneath the head pivot. Its calculated
	# shell radius must never become a scale operation on the wearer's anatomy.
	preserve_covered_head_scale(root)
	return root


## Reasserts each of the real head's own visible meshes at their originally
## authored scale while a Lava Helm is worn -- protects them from some other
## system (a future preview or suit animation change) resetting one along
## the way, independent of helmet sizing. Per direct correction, this used
## to also reassert head_pivot's own scale, but nothing in this codebase
## ever actually sets that to anything else; that half was dead defensive
## code and has been removed.
static func preserve_covered_head_scale(piece: Node3D) -> void:
	if piece == null:
		return
	# is_instance_valid() must run on a raw, UNTYPED reference. Even just
	# assigning an already-freed Object into a statically-typed `Object`
	# variable (not only an `as` cast) makes GDScript's own type coercion
	# throw "Trying to assign invalid previously freed instance" right at
	# that assignment -- confirmed the hard way. This reference can go stale
	# between this piece's build time (when it was captured) and any later
	# frame this runs on.
	var visual_states: Array = piece.get_meta("protected_visual_scales", []) as Array
	for state_value in visual_states:
		var state := state_value as Dictionary
		var visual_ref = state.get("visual")
		if is_instance_valid(visual_ref):
			(visual_ref as VisualInstance3D).scale = state.get("scale") as Vector3


## Frees are owned by BlorbSuitController, but special pieces may have visual
## state to unwind first. Keeping that cleanup beside the builder prevents an
## unequip, assignment change, or story suspension from leaving the real
## head's scale still overridden after the Lava Helm disappears.
static func release_piece(piece: Node3D) -> void:
	if piece == null:
		return
	preserve_covered_head_scale(piece)
	# queue_free is intentionally retained because callers can release during a
	# tree update, but hide immediately so stale geometry cannot flash or enter
	# another visible-subtree query before frame-end deletion.
	piece.visible = false
	piece.queue_free()


## Per direct correction, NOT a dome fused to a separate boomerang crest --
## this is the exact same single bent-pipe cashew technique as Lava Slide's
## own living head (see lava_slide.gd's _build_lava_slide_head_rings()):
## fattest at one "face" cross section, then narrowing gradually and
## smoothly (never a hard taper) into two rounded tips swept up and back.
## The only thing this version does differently is size and place that face
## bulge from `contents` -- the actual measured head+hair bounds -- instead
## of a fixed authored size, since it has to actually enclose an arbitrary
## wearer's head rather than just look like one.
##
## Sizing: BULB_RADIUS is set to (at least) `contents`' own half-diagonal,
## so a sphere of that radius centered on `contents`' own center always
## contains the whole box, whatever its proportions -- and the face cross
## section at s=0 is approximately exactly that sphere (radius stays within
## cos(small angle) of BULB_RADIUS for s near 0, and the pipe's other two
## span/back/lift dimensions move so little near s=0 that this reads as a
## true sphere there, not just "close enough"). Every other shape constant
## is expressed as a ratio against BULB_RADIUS, copied directly from Lava
## Slide's own tuned proportions (each of his HEAD_* constants divided by
## his own HEAD_PIPE_RADIUS), so this reads as the same cashew silhouette
## uniformly rescaled to whatever this wearer's head needs -- not a
## differently-shaped helm that merely shares the technique.
## Cut from 1.15 per direct correction ("massively big") -- 1.04 is a much
## tighter fit, a 4% safety buffer over the mathematically exact minimum
## enclosing sphere rather than 15% of headroom to spare.
const LAVA_HELM_ENCLOSE_MARGIN := 1.04
const LAVA_HELM_SPAN_RATIO := 0.16 / 0.09
## Cut from Lava Slide's own 0.13/0.09 ratio per direct correction ("shorten
## the distance the pipe extends behind him"), then cut again from 0.8, then
## again from 0.5, per further direct corrections ("the lobes are going back
## too far" / "still too far back").
const LAVA_HELM_BACK_RATIO := 0.3
const LAVA_HELM_LIFT_RATIO := 0.11 / 0.09
const LAVA_HELM_FACE_FORWARD_RATIO := 0.17 / 0.09
## Past this |s|, an extra shrink factor (on top of the ordinary cos(phi)
## taper every ring already gets) ramps in -- see _lava_helm_radius_at().
## Per direct correction (twice now), pushed down again from 0.1 to
## start almost immediately past the face bulge itself -- the exact
## enclosing sphere is only strictly needed AT s=0; the real head's own
## cross section is narrower than that everywhere else, so tapering can
## start shrinking well before the shell has fully "cleared" the head and
## still enclose it.
const LAVA_HELM_CLEAR_S := 0.04
## How much extra shrink (beyond the ordinary cos(phi) taper) has fully
## ramped in by the very tip (|s|=1). Per direct correction (twice now),
## raised again from 0.35 for a more pronounced shrink overall, spread
## smoothly (smoothstep, not a hard cutoff) across nearly this whole
## s=0.04..1.0 span. The actual point-free cashew closing at the tip still
## comes from cos(phi) alone hitting zero there regardless of this value.
const LAVA_HELM_EXTRA_TAPER := 0.6


## Every shape constant this pipe needs, derived once from `contents` so
## _build_lava_helm_rings() and _add_lava_helm_eyes() can't drift apart from
## each other. `origin` is the offset that lands the pipe's own s=0 face
## point (which sits BULB_FACE_FORWARD ahead of the pipe's local origin, per
## _lava_helm_pipe_center()'s own (0,0,face_forward) at s=0) exactly on
## `contents`' measured center.
static func _lava_helm_shape(contents: AABB) -> Dictionary:
	var center := contents.position + contents.size * 0.5
	var bulb_radius := contents.size.length() * 0.5 * LAVA_HELM_ENCLOSE_MARGIN
	var face_forward := bulb_radius * LAVA_HELM_FACE_FORWARD_RATIO
	return {
		"bulb_radius": bulb_radius,
		"span": bulb_radius * LAVA_HELM_SPAN_RATIO,
		"back": bulb_radius * LAVA_HELM_BACK_RATIO,
		"lift": bulb_radius * LAVA_HELM_LIFT_RATIO,
		"face_forward": face_forward,
		"origin": center - Vector3(0.0, 0.0, face_forward),
	}


## Identical in structure to lava_slide.gd's own _head_pipe_center(), just
## taking its span/back/lift/face_forward as parameters instead of reading
## fixed constants, since this shape's own scale varies per wearer.
static func _lava_helm_pipe_center(s: float, span: float, back: float, lift: float, face_forward: float) -> Vector3:
	return Vector3(s * span, lift * s * s, face_forward * (1.0 - s * s) - back * s * s)


static func _lava_helm_pipe_tangent(s: float, span: float, back: float, lift: float, face_forward: float) -> Vector3:
	const STEP := 0.01
	return (
		_lava_helm_pipe_center(minf(s + STEP, 1.0), span, back, lift, face_forward)
		- _lava_helm_pipe_center(maxf(s - STEP, -1.0), span, back, lift, face_forward)
	).normalized()


## The ordinary cos(phi) taper every ring gets, further multiplied by an
## extra shrink factor once |s| passes LAVA_HELM_CLEAR_S -- per direct
## correction, the shell stayed just as fat all the way out to the tips as
## it needed to be near the face to actually enclose the head, when it only
## needs to be that fat near the face. Shared by the ring builder and the
## eye placer so they never taper against different curves.
static func _lava_helm_radius_at(s: float, bulb_radius: float) -> float:
	var phi := asin(clampf(s, -1.0, 1.0))
	var base := bulb_radius * cos(phi)
	var clear_t := clampf(inverse_lerp(LAVA_HELM_CLEAR_S, 1.0, absf(s)), 0.0, 1.0)
	var extra := 1.0 - smoothstep(0.0, 1.0, clear_t) * LAVA_HELM_EXTRA_TAPER
	return base * extra


static func _build_lava_helm_rings(contents: AABB) -> Array:
	var shape := _lava_helm_shape(contents)
	var origin: Vector3 = shape["origin"]
	var span: float = shape["span"]
	var back: float = shape["back"]
	var lift: float = shape["lift"]
	var face_forward: float = shape["face_forward"]
	var bulb_radius: float = shape["bulb_radius"]
	const RING_COUNT := 32
	const RADIAL_SEGMENTS := 16
	var rings: Array = []
	for ring_index in RING_COUNT + 1:
		var phi: float = -PI * 0.5 + PI * float(ring_index) / float(RING_COUNT)
		var s := sin(phi)
		var radius := _lava_helm_radius_at(s, bulb_radius)
		var center := origin + _lava_helm_pipe_center(s, span, back, lift, face_forward)
		var tangent := _lava_helm_pipe_tangent(s, span, back, lift, face_forward)
		var right := tangent.cross(Vector3.UP)
		right = right.normalized() if right.length() > 0.001 else Vector3.RIGHT
		var up := right.cross(tangent).normalized()
		var ring: Array[Vector3] = []
		for segment in RADIAL_SEGMENTS:
			var angle: float = TAU * float(segment) / float(RADIAL_SEGMENTS)
			# Negated sin term -- see lava_slide.gd's identical fix; this
			# builder shares the same winding otherwise.
			ring.append(center + (right * cos(angle) - up * sin(angle)) * radius)
		rings.append(ring)
	return rings


## Same construction as lava_slide.gd's _head_pipe_surface_sample()/
## _place_eye_on_head() (that file's own doc comments have the full
## reasoning): each eye samples the pipe's REAL generated surface at a
## small lateral offset from the face point, using the exact center/
## tangent/radius math the mesh itself is built from, so it lands exactly
## on the surface rather than at an independently-guessed offset.
static func _add_lava_helm_eyes(helm: Node3D, contents: AABB, body_color: Color) -> void:
	const EYE_S_OFFSET := 0.18
	const EMBED_FRACTION := 0.35
	var shape := _lava_helm_shape(contents)
	var origin: Vector3 = shape["origin"]
	var span: float = shape["span"]
	var back: float = shape["back"]
	var lift: float = shape["lift"]
	var face_forward: float = shape["face_forward"]
	var bulb_radius: float = shape["bulb_radius"]
	var eye_radius := bulb_radius * 0.16 * 0.5 * 1.28
	var eye_color := body_color.darkened(0.25)
	for side in [-1.0, 1.0]:
		# Explicit `: float =` rather than `:=` -- `side`'s own static type
		# from the untyped array literal above is Variant, which `:=`
		# inference can't resolve into a concrete type (unlike figure_eyes.gd
		# /BlorbFace.add_eyes()'s identical loop, which uses this same
		# explicit-type pattern for exactly this reason).
		var s: float = side * EYE_S_OFFSET
		var radius := _lava_helm_radius_at(s, bulb_radius)
		var center := origin + _lava_helm_pipe_center(s, span, back, lift, face_forward)
		var tangent := _lava_helm_pipe_tangent(s, span, back, lift, face_forward)
		var outward := tangent.cross(Vector3.UP)
		outward = outward.normalized() if outward.length() > 0.001 else Vector3.RIGHT
		var surface := center + outward * radius
		var eye := MeshInstance3D.new()
		eye.name = "EyeL" if side < 0.0 else "EyeR"
		eye.mesh = SuperEgg.build_mesh(
			Vector3(eye_radius, eye_radius * 1.15, eye_radius), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		var material := StandardMaterial3D.new()
		material.albedo_color = eye_color
		material.roughness = 0.8
		eye.set_surface_override_material(0, material)
		eye.basis = Basis.looking_at(-outward, Vector3.UP)
		eye.scale = Vector3(1.0, 1.0, 0.4)
		eye.position = surface - outward * (eye_radius * EMBED_FRACTION)
		helm.add_child(eye)


static func _add_lava_mohawk(parent: Node3D, radius: float) -> void:
	var fire := GPUParticles3D.new()
	fire.name = "BurningMohawk"
	# Helmet-local simulation keeps the flame rooted to a moving wearer. The
	# old world-space particles stayed behind at every previous head position,
	# producing a smoke-trail ribbon rather than fire attached to a mohawk.
	fire.local_coords = true
	fire.amount = 86
	fire.lifetime = 0.46
	fire.randomness = 0.55
	fire.visibility_aabb = AABB(Vector3(-radius, -radius, -radius), Vector3(radius * 2.0, radius * 3.0, radius * 2.0))
	var texture := ParticleFX.build_soft_gradient_texture(32, 1.4, 0.22)
	var quad := QuadMesh.new()
	quad.size = Vector2(radius * 0.34, radius * 0.72)
	var flame_material := ParticleFX.build_billboard_material(texture, Color.WHITE, true, 0.0)
	flame_material.vertex_color_use_as_albedo = true
	quad.material = flame_material
	fire.draw_pass_1 = quad
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(radius * 0.05, radius * 0.04, radius * 0.76)
	# Sweep toward the helmet's rear (-Z) instead of rising toward its face.
	# Retain a smaller upward component so it reads as a wind-combed flame
	# crest, not a flamethrower jet fired horizontally from the scalp.
	process.direction = Vector3(0.0, 0.48, -0.88).normalized()
	process.spread = 16.0
	process.initial_velocity_min = 1.3
	process.initial_velocity_max = 2.25
	process.gravity = Vector3(0.0, 0.4, 0.0)
	process.particle_flag_align_y = true
	process.angle_min = -12.0
	process.angle_max = 12.0
	process.scale_curve = ParticleFX.build_scale_curve(0.45, 1.12, 0.28, 0.18)
	process.turbulence_enabled = true
	process.turbulence_noise_strength = 0.8
	process.turbulence_noise_scale = 2.0
	process.turbulence_influence_min = 0.03
	process.turbulence_influence_max = 0.12
	process.color_ramp = ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(1.0, 0.92, 0.34, 0.95)},
		{"offset": 0.42, "color": Color(1.0, 0.25, 0.025, 0.82)},
		{"offset": 1.0, "color": Color(0.4, 0.015, 0.005, 0.0)},
	])
	fire.process_material = process
	fire.position = Vector3(0.0, radius * 1.04, -radius * 0.08)
	parent.add_child(fire)


static func _add_nautilus_pirate_hat(hat: Node3D, radius: float, vis: Dictionary) -> void:
	var material := _build_goo_material(vis)
	var crown := MeshInstance3D.new()
	crown.name = "NautilusPirateCrown"
	crown.mesh = SuperEgg.build_mesh(Vector3(radius * 1.05, radius * 0.42, radius * 0.78), 2.5, SuperEgg.EPSILON_FLAT)
	crown.material_override = material
	crown.position = Vector3(0.0, radius * 1.24, 0.0)
	hat.add_child(crown)
	for yaw_degrees: float in [0.0, 120.0, 240.0]:
		var brim := MeshInstance3D.new()
		brim.mesh = SuperEgg.build_mesh(Vector3(radius * 1.38, radius * 0.12, radius * 0.54), 2.5, SuperEgg.EPSILON_FLAT)
		brim.material_override = material
		brim.position = Vector3(0.0, radius * 1.02, 0.0)
		brim.rotation.y = deg_to_rad(yaw_degrees)
		hat.add_child(brim)
	# The nautilus spiral is embossed in the same living goo color.
	for index in 8:
		var t := float(index) / 7.0
		var angle := t * TAU * 1.4
		var spiral := MeshInstance3D.new()
		spiral.mesh = SuperEgg.build_mesh(Vector3(radius * 0.09, radius * 0.09, radius * 0.035), 2.2, 2.2)
		spiral.material_override = material
		spiral.position = Vector3(cos(angle) * radius * 0.36 * t, radius * 1.28 + sin(angle) * radius * 0.36 * t, radius * 0.79)
		hat.add_child(spiral)


## `head_extent` arrives already scaled by the caller's own `rig_scale` (see
## build_head()), so `radius` below inherits correct sizing for free; the one
## remaining direct ProceduralFigure reference (the helm's own vertical seat
## on head_pivot) needs `rig_scale` applied explicitly here.
static func _build_knights_helm(head_pivot: Node3D, head_extent: float, vis: Dictionary, rig_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "HeadBlorbKnightHelm"
	head_pivot.add_child(root)
	# The helm is the blorb itself reshaped into one continuous, reference-
	# inspired medieval profile: flared lower guard, broad visor zone, then
	# a rounded dome tapering into a crown. It is a single goo body, not a
	# generic egg or a stack of separate metal props.
	# A real helm sits close to the skull; the previous nearly 2x radius
	# doubled the apparent head size instead of reading as wearable armour.
	var radius := head_extent * 1.24
	var helm := MeshInstance3D.new()
	helm.name = "KnightHelmBlorbBody"
	helm.mesh = BlorbBodyShape.build_mesh_from_rings(_build_knight_helm_rings(radius))
	helm.set_surface_override_material(0, _build_goo_material(vis))
	helm.position = Vector3(0, ProceduralFigure.HEAD_SIZE.y * 1.08 * rig_scale, 0)
	root.add_child(helm)
	# Eyes remain embedded directly in the transformed blorb surface.
	var eye_y := -radius * 0.18
	# This silhouette's visor projects beyond its nominal radial profile.
	# Supply that real front reach to the shared eye builder so its normal
	# embed lands ON the mesh instead of burying the eyes inside the helm.
	BlorbFace.add_eyes(helm, radius * 1.15, eye_y, 0.0, vis["albedo"] as Color, 1.33)
	# A curved sagittal fin follows the crown from top toward the back: a
	# true mohawk/ridge, not a small oval resting flat on the head.
	var crest := MeshInstance3D.new()
	crest.name = "KnightHelmBlorbCrest"
	crest.mesh = _build_knight_helm_crest_mesh(radius)
	crest.set_surface_override_material(0, _build_goo_material(vis))
	helm.add_child(crest)
	var core := BlorbCore.build(radius * CORE_RADIUS_FRACTION * HAT_CORE_RADIUS_SCALE, vis["core_color"] as Color, vis["core_emissive"] as bool)
	core.position = Vector3(0, eye_y, radius * 0.3)
	helm.add_child(core)
	_add_head_core_light(core, vis)
	return root


## One lathed, organic helmet body. The asymmetric forward extension around
## the lower visor gives a face-guard silhouette while retaining a smooth
## uninterrupted surface for the blorb's own eyes and material.
static func _build_knight_helm_rings(radius: float) -> Array:
	var profile: Array[Vector2] = [
		# The first two rings deliberately broaden outward into a shallow,
		# rounded neck flare before drawing back into the cheek/visor volume.
		Vector2(-1.04 - 0.04 / radius, 0.68), Vector2(-0.92, 0.84), Vector2(-0.68, 0.8),
		Vector2(-0.28, 1.03), Vector2(0.12, 1.04),
	]
	# A true elliptical dome: broad at the brow and continuously rounded to
	# the crown. This replaces the narrow cap/funnel altogether.
	var dome_base := 0.12 * radius
	var dome_height := 1.5 * radius - 0.04
	for fraction in [0.3, 0.55, 0.75, 0.9, 0.98, 1.0]:
		var f: float = fraction
		var dome_radius := 1.04 * sqrt(maxf(0.0, 1.0 - f * f))
		profile.append(Vector2((dome_base + dome_height * f) / radius, dome_radius))
	var rings: Array = []
	for profile_point in profile:
		var y: float = profile_point.x * radius
		var ring_radius: float = profile_point.y * radius
		var lower_guard := clampf((-profile_point.x - 0.1) / 0.94, 0.0, 1.0)
		var ring: Array[Vector3] = []
		for segment in BlorbBodyShape.RADIAL_SEGMENTS:
			var angle: float = float(segment) / float(BlorbBodyShape.RADIAL_SEGMENTS) * TAU
			var front_weight := maxf(sin(angle), 0.0)
			# The front is gently pushed out around the lower visor/face guard,
			# while the crown remains a clean rounded dome.
			var z_radius := ring_radius * (1.0 + front_weight * lower_guard * 0.16)
			ring.append(Vector3(cos(angle) * ring_radius, y, sin(angle) * z_radius))
		rings.append(ring)
	return rings


## Thin curved fin over the sagittal (front-back) line of the dome. Its
## bottom edge follows the helmet curve and its top edge follows the same
## curve at a small offset, producing a mohawk-shaped disk segment.
static func _build_knight_helm_crest_mesh(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var centers: Array[Vector3] = []
	# The rear two points carry the ridge down the helmet's back instead of
	# ending at the crown.  Derive their height from the same ellipse as the
	# helmet dome so the strip remains seated on that curve.
	var dome_base := radius * 0.12
	var dome_height := radius * 1.5 - 0.04
	for z_fraction in [-1.02, -0.86, -0.58, -0.28, 0.0, 0.35, 0.62]:
		var z: float = float(z_fraction) * radius
		# Keep the ridge inside the helmet silhouette while carrying it nearly
		# to the rear edge of the dome.
		var dome_fraction := minf(absf(float(z_fraction)) / 1.04, 0.999)
		var dome_y := dome_base + dome_height * sqrt(maxf(0.0, 1.0 - dome_fraction * dome_fraction))
		centers.append(Vector3(0.0, dome_y, z))
	var half_width := radius * 0.11
	var crest_height := radius * 0.34
	for i in centers.size() - 1:
		var a := centers[i]
		var b := centers[i + 1]
		# Let the crest stand distinctly higher at the rear, rather than
		# lengthening it down into the neck guard.
		var a_rear := clampf((-a.z / radius - 0.2) / 0.84, 0.0, 1.0)
		var b_rear := clampf((-b.z / radius - 0.2) / 0.84, 0.0, 1.0)
		var a_height := crest_height * lerpf(1.0, 1.6, a_rear)
		var b_height := crest_height * lerpf(1.0, 1.6, b_rear)
		var al := a + Vector3(-half_width, 0, 0)
		var ar := a + Vector3(half_width, 0, 0)
		var atl := al + Vector3(0, a_height, 0)
		var atr := ar + Vector3(0, a_height, 0)
		var bl := b + Vector3(-half_width, 0, 0)
		var br := b + Vector3(half_width, 0, 0)
		var btl := bl + Vector3(0, b_height, 0)
		var btr := br + Vector3(0, b_height, 0)
		# left/right faces, top, and the thin base attached to the dome.
		for face in [[al, bl, atl, btl], [ar, atr, br, btr], [atl, btl, atr, btr], [al, ar, bl, br]]:
			st.add_vertex(face[0] as Vector3)
			st.add_vertex(face[1] as Vector3)
			st.add_vertex(face[2] as Vector3)
			st.add_vertex(face[2] as Vector3)
			st.add_vertex(face[1] as Vector3)
			st.add_vertex(face[3] as Vector3)
	st.generate_normals()
	return st.commit()


static func _add_head_core_light(core: Node3D, vis: Dictionary) -> void:
	if vis["has_light"] as bool:
		var light := OmniLight3D.new()
		light.light_color = vis["light_color"] as Color
		light.omni_range = 1.2
		light.shadow_enabled = false
		core.add_child(light)


## Droops the BACK half (local -Z) of a plain BlorbBodyShape silhouette
## down and slightly in, per direct instruction -- there's no ground for a
## hat-worn blorb's underside to rest flush against the way an ordinary
## blorb's EMBED_DEPTH assumes, so the back is allowed to sag instead of
## staying a clean round bottom. Tapers off toward the crown (height_t
## close to 1) so only the lower-back region visibly sags.
##
## back_amount uses smoothstep(), not a plain linear ramp, specifically
## because the FRONT half (z >= 0) is never touched at all -- droop_amount
## there is implicitly a flat, unchanging 0. A linear ramp starting at
## z=0 has a nonzero slope right at that boundary, so the droop function's
## own slope jumps discontinuously the instant z crosses 0 -- a real kink
## in the surface, reported as "flat in front, then a sharp corner where
## it starts to angle downwards." smoothstep(0, radius, -z) has ZERO slope
## at z=0 (and again at z=-radius), matching the flat front's own zero
## slope exactly, so the whole transition reads as one continuous curve.
static func _build_hat_rings(radius: float, height: float, droop: float) -> Array:
	var rings: Array = BlorbBodyShape.build_rings(radius, height)
	for ring in rings:
		for i in ring.size():
			var point: Vector3 = ring[i]
			if point.z < 0.0:
				var back_amount := smoothstep(0.0, radius, -point.z)
				var height_t := clampf(point.y / height, 0.0, 1.0)
				var droop_amount := back_amount * (1.0 - height_t * 0.6)
				point.y -= droop_amount * droop
				ring[i] = point
	return rings


## Average of a ProceduralFigure size const's width/depth (x/z) -- the
## "thickness" a limb segment's own radius is derived from.
static func _avg_xz(size: Vector3) -> float:
	return (size.x + size.z) * 0.5


## Builds one continuous tube through `control_points`, each with its own
## `control_radii` entry, as a Catmull-Rom spline (smooth through every
## control point, unlike a straight-line loft which would visibly crease
## at each joint) -- the actual "flexible long pill or noodle" geometry.
## Reuses BlorbBodyShape.build_mesh_from_rings() for the strip
## triangulation between rings (same technique blorb.gd's own body uses,
## just with THIS shape's own variable per-ring radius instead of that
## file's fixed profile).
## control_colors is optional (parallel to control_points, one Color per
## point) -- per direct correction (horse_figure.gd's leg tubes need a
## chocolate-brown region "just around where the bottom domes are" without
## adding a separate piece), lets a caller bake a color directly into this
## single tube's own vertices. Per a further direct correction ("shouldn't
## be a gradient, should be a sharp change"), each ring just takes its own
## enclosing segment's flat color (control_colors[seg], see the loop below)
## rather than lerping toward the next point the way control_radii's own
## per-ring value does -- a real per-segment step, not a blend. Left empty
## by every existing caller (tail, mane, monkey_figure.gd's limbs), which
## reproduces the exact prior behavior: no COLOR array on the mesh at all.
static func build_limb_tube(
	control_points: Array[Vector3], control_radii: Array[float],
	radial_segments: int, rings_per_segment: int, cap_fraction: float,
	control_colors: Array[Color] = [], taper_start: bool = true
) -> ArrayMesh:
	var n := control_points.size()
	var p_start: Vector3 = control_points[0] * 2.0 - control_points[1]
	var p_end: Vector3 = control_points[n - 1] * 2.0 - control_points[n - 2]
	var ext_points: Array[Vector3] = [p_start]
	ext_points.append_array(control_points)
	ext_points.append(p_end)

	var total_rings := (n - 1) * rings_per_segment + 1
	var rings: Array = []
	var ring_index := 0
	# Rotation-minimizing frame, propagated ring-to-ring (see
	# _transport_frame()) rather than each ring independently recomputing
	# its own right/up from a fixed UP/FORWARD reference (the old
	# _ring_basis() approach). An independent-per-ring basis flips its own
	# reference axis the instant the tangent direction crosses
	# _ring_basis()'s own 0.9-dot threshold -- which happens naturally as
	# a limb bends -- snapping the ring's whole orientation by roughly 90
	# degrees right at that one pose and reading as a sudden twist/seam,
	# exactly the "looks like segments getting separated" symptom reported.
	# Propagating instead keeps every ring's own twist perfectly
	# continuous no matter how the limb bends, which is also what actually
	# sells a stretch rather than an articulated-segment feel.
	var prev_tangent := Vector3.ZERO
	var prev_right := Vector3.ZERO
	var prev_up := Vector3.ZERO
	var has_colors := not control_colors.is_empty()
	var ring_colors: Array[Color] = []
	for seg in n - 1:
		var steps := rings_per_segment + 1 if seg == n - 2 else rings_per_segment
		for step in steps:
			var t := float(step) / rings_per_segment
			var pos := _catmull_rom(ext_points[seg], ext_points[seg + 1], ext_points[seg + 2], ext_points[seg + 3], t)
			var tangent := _catmull_rom_tangent(
				ext_points[seg], ext_points[seg + 1], ext_points[seg + 2], ext_points[seg + 3], t
			)
			var radius := lerpf(control_radii[seg], control_radii[seg + 1], t)
			var u := float(ring_index) / float(total_rings - 1)
			radius *= _cap_taper(u, cap_fraction, taper_start)

			var right: Vector3
			var up: Vector3
			if ring_index == 0:
				var basis0 := _ring_basis(tangent)
				right = basis0.x
				up = basis0.y
			else:
				var frame := _transport_frame(prev_tangent, prev_right, prev_up, tangent)
				right = frame[0] as Vector3
				up = frame[1] as Vector3

			rings.append(_build_ring(pos, right, up, radius, radial_segments))
			if has_colors:
				# Flat per-segment color (the segment's OWN start point,
				# control_colors[seg]) rather than lerping toward
				# control_colors[seg + 1] the way radius lerps toward
				# control_radii[seg + 1] just above -- per direct correction
				# ("shouldn't be a gradient, should be a sharp change"), a
				# smooth blend read as too soft for a marking like a horse's
				# sock. This also means the cut lands exactly AT each control
				# point rather than partway through the following segment --
				# see horse_figure.gd's own _rebuild_leg_tube() for why that
				# puts the horse leg's own cut right at the hoof point/dome.
				ring_colors.append(control_colors[seg])
			prev_tangent = tangent
			prev_right = right
			prev_up = up
			ring_index += 1

	return BlorbBodyShape.build_mesh_from_rings(rings, ring_colors)


static func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1)
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


static func _catmull_rom_tangent(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var tangent := 0.5 * (
		(-p0 + p2)
		+ 2.0 * (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t
		+ 3.0 * (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t2
	)
	if tangent.length() < 0.0001:
		return (p2 - p1).normalized()
	return tangent.normalized()


## Smoothly eases the tube's own radius profile down to a point at each
## end (u=0/u=1) over cap_fraction of its total length -- a quarter-sine
## taper that keeps the tube ends from terminating as full-radius cuts.
## Flat (1.0, no taper) through the middle.
static func _cap_taper(u: float, cap_fraction: float, taper_start: bool = true) -> float:
	if taper_start and u < cap_fraction:
		return sin((u / cap_fraction) * PI * 0.5)
	if u > 1.0 - cap_fraction:
		return sin(((1.0 - u) / cap_fraction) * PI * 0.5)
	return 1.0


## Orthonormal ring basis for a tube cross-section at a point with the
## given tangent -- right/up span the ring plane, tangent is "along the
## tube." Only ever called for the tube's very first ring (see
## build_limb_tube()) -- every ring after that propagates from this one
## via _transport_frame() instead of recomputing independently. Picks
## whichever of UP/FORWARD is less parallel to tangent as the reference
## axis (limb tangents point mostly vertically, so a fixed UP reference
## alone would go degenerate near-parallel at points where the tube runs
## straight up/down).
static func _ring_basis(tangent: Vector3) -> Basis:
	var reference := Vector3.UP
	if absf(tangent.dot(Vector3.UP)) > 0.9:
		reference = Vector3.FORWARD
	var right := tangent.cross(reference).normalized()
	var up := right.cross(tangent).normalized()
	return Basis(right, up, tangent)


## Carries a ring's own (right, up) frame forward to a new tangent by the
## minimal rotation that takes prev_tangent to tangent (axis = their cross
## product, angle = the angle between them) -- a standard rotation-
## minimizing-frame step. Re-orthogonalizes the result against the NEW
## tangent afterward to correct any numerical drift accumulating ring over
## ring across a long tube. Returns [right, up] rather than a Basis since
## the caller needs the two vectors individually for _build_ring() anyway.
static func _transport_frame(
	prev_tangent: Vector3, prev_right: Vector3, prev_up: Vector3, tangent: Vector3
) -> Array[Vector3]:
	var axis := prev_tangent.cross(tangent)
	var axis_len := axis.length()
	if axis_len < 0.0001:
		return [prev_right, prev_up] as Array[Vector3]
	axis /= axis_len
	var angle := acos(clampf(prev_tangent.dot(tangent), -1.0, 1.0))
	var rot := Basis(axis, angle)
	var right: Vector3 = (rot * prev_right)
	right = (right - tangent * right.dot(tangent)).normalized()
	var up := right.cross(tangent).normalized()
	return [right, up] as Array[Vector3]


static func _build_ring(center: Vector3, right: Vector3, up: Vector3, radius: float, radial_segments: int) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for seg in radial_segments:
		var angle := (float(seg) / radial_segments) * TAU
		points.append(center + right * cos(angle) * radius + up * sin(angle) * radius)
	return points
## Converts a WORLD-space direction (not a point) into root-local space --
## Node3D.to_local() is for points (it includes translation); a direction
## only needs the rotation part of root's own transform inverted. Assumes
## root carries no non-uniform scale (true for player.gd's own `visuals`,
## which only ever has its rotation.y touched -- see player.gd's own
## _physics_process).
static func _to_local_dir(root: Node3D, world_dir: Vector3) -> Vector3:
	return (root.global_transform.basis.inverse() * world_dir).normalized()


## Built through the SAME shared function blorb.gd's own body uses (see
## BlorbBodyShape.build_body_material()'s own doc comment) -- guarantees a
## worn piece reacts to scene lighting (day/night sun color, sunset, etc)
## exactly like an ordinary blorb, since it's literally the same material-
## construction code rather than a second hand-kept-in-sync copy.
static func _build_goo_material(vis: Dictionary) -> StandardMaterial3D:
	# Free Rock blorbs remain living creatures; only their worn armor form
	# hardens into the same opaque, dry stone used by natural boulders.
	if (vis.get("element", "") as String) == "rock":
		var rock_material := StandardMaterial3D.new()
		rock_material.albedo_color = NatureProps.ROCK_COLOR
		rock_material.roughness = 0.96
		rock_material.metallic = 0.0
		return rock_material
	var albedo := vis["albedo"] as Color
	return BlorbBodyShape.build_body_material(
		Color(albedo.r, albedo.g, albedo.b, maxf(albedo.a, 0.88)),
		vis["roughness"] as float, vis["metallic"] as float,
		vis["emission_enabled"] as bool, vis["emission"] as Color, vis["emission_energy"] as float
	)


## Two small flattened eyes plus a BlorbCore just behind them, matching
## blorb.gd/blorb_face.gd's own "core sits behind the eyes" arrangement.
## Idempotent -- creates EyeL/EyeR/Core/Light the first time it's called on
## a given `piece` (looked up by fixed node name), and just repositions/
## re-tints them on every subsequent call, so limb pieces (rebuilt every
## frame -- see rebuild_arm()/rebuild_leg()) don't rebuild these small
## meshes from scratch 60 times a second for no visual benefit.
## `center`/`facing` are in the PIECE's own local space.
static func _update_face(
	piece: Node3D, center: Vector3, facing: Vector3, ref_size: float, vis: Dictionary,
	eye_fraction: float = EYE_RADIUS_FRACTION, core_fraction: float = CORE_RADIUS_FRACTION,
	flatten: float = EYE_FLATTEN, spacing: float = EYE_SPACING, outward_tilt: float = 0.0,
	right_hint: Vector3 = Vector3.ZERO, core_offset: Vector3 = Vector3.ZERO, eye_offset: Vector3 = Vector3.ZERO
) -> void:
	var albedo := vis["albedo"] as Color
	# Matches blorb_face.gd/figure_eyes.gd's own darkened(0.25) -- an
	# earlier darkened(0.55) here (before that inconsistency was caught and
	# fixed project-wide) read as near-black against light body colors.
	var eye_color := albedo.darkened(0.25)
	var eye_radius := ref_size * eye_fraction

	# right/up used to be carried forward (parallel-transported) from the
	# PREVIOUS call on this same `piece`, the same technique
	# build_limb_tube()'s own ring basis uses (see _transport_frame()) --
	# meant to fix the eyes "spinning like a compass" when a threshold-
	# based pick (facing.cross(UP), snapping the instant `facing` crossed
	# a fixed reference threshold) flipped mid-motion during the raised-arm
	# power pose.
	#
	# That fix introduced a WORSE bug of its own: parallel transport is
	# inherently path-dependent (holonomic) -- carrying a frame around a
	# CLOSED LOOP in facing-direction space (exactly what raising an arm
	# and then lowering it back down traces out) does not generally return
	# the frame to its own starting orientation, leaving a small residual
	# twist behind every single cycle. Reported as the eyes' own resting
	# orientation rotating a little further each time the arm was raised
	# and lowered a few times -- a compounding drift, not a one-off
	# glitch, and the "each time a bit more" pattern is exactly what
	# holonomic drift looks like.
	#
	# Fixed by dropping the incremental/historical approach for any caller
	# that can supply `right_hint` -- a direction straight off a real,
	# already-rotated node's OWN current transform (rebuild_arm() passes
	# the hand's own BackAttach basis), recomputed fresh from the actual
	# live pose every frame with zero dependency on any previous frame or
	# path taken to get there. Returning to the same hand rotation always
	# yields bit-for-bit the same right_hint, so there is nothing left to
	# accumulate. Callers whose `facing` never changes frame-to-frame
	# (torso/legs -- always a fixed constant direction, see build_torso()/
	# rebuild_leg()) have nothing to snap OR drift on in the first place,
	# so they keep falling through to the plain threshold-based pick.
	var right: Vector3
	var up: Vector3
	if right_hint.length() > 0.01:
		right = (right_hint - facing * facing.dot(right_hint)).normalized()
	else:
		right = facing.cross(Vector3.UP)
		if right.length() < 0.01:
			right = Vector3.RIGHT
		right = right.normalized()
	up = right.cross(facing).normalized()

	for side in [-1.0, 1.0]:
		var eye_name := "EyeL" if side < 0.0 else "EyeR"
		var eye: MeshInstance3D = piece.get_node_or_null(eye_name)
		if eye == null:
			eye = MeshInstance3D.new()
			eye.name = eye_name
			eye.mesh = SuperEgg.build_mesh(
				Vector3(eye_radius, eye_radius * 1.15, eye_radius), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
			)
			var eye_material := StandardMaterial3D.new()
			# Matte, not glossy -- see blorb_face.gd's identical change for
			# why (a bright capture rig's stacked lighting can blow a
			# glossy, tightly-curved eye surface out to solid white).
			eye_material.roughness = 0.8
			eye.set_surface_override_material(0, eye_material)
			piece.add_child(eye)
		(eye.get_surface_override_material(0) as StandardMaterial3D).albedo_color = eye_color
		# .basis assigns Godot's WHOLE rotation+scale matrix at once --
		# Basis.looking_at() returns a pure orthonormal (unscaled) basis,
		# so setting it AFTER .scale (an earlier version did, and only
		# ever at creation) silently discards the flatten scale on every
		# single call. That's what actually read as "extruding way too
		# far": eyes were rendering at their full, unflattened radius
		# everywhere, not the intended thin disc. .scale has to be
		# reapplied AFTER .basis, every call, not just once at creation.
		#
		# outward_tilt (torso only, see TORSO_EYE_OUTWARD_TILT) splays each
		# eye's own facing away from the other by rotating around `up`.
		# Worked out mathematically (right = facing x UP_world, up = right
		# x facing -- so up x facing = -right, meaning rotating facing
		# around +up by a small positive angle shifts it toward -right) --
		# not independently confirmed in-engine, so if this reads as
		# splaying the eyes INWARD (toward each other) instead, negate the
		# sign on `side` below.
		eye.basis = Basis.looking_at(-facing, up).rotated(up, -side * outward_tilt)
		eye.scale = Vector3(1.0, 1.0, flatten)
		eye.position = center + right * (side * eye_radius * spacing) - facing * (eye_radius * EYE_EMBED_FRACTION) + eye_offset

	# The core's own position/size is fully independent of the eyes' own
	# (much smaller) radius now -- an earlier version anchored it at
	# `eye_radius * 1.8` inward from the surface, but the core's own
	# radius (core_fraction, usually much bigger than any eye fraction)
	# could still poke its OWN near edge out past the true surface even
	# while the eyes themselves sat correctly, per direct instruction
	# ("the core is protruding out... divorce the position of the core
	# from the eyes"). Capped to a fraction of ref_size and inset by its
	# own radius (plus a margin) instead, so its near edge always lands
	# inside the true surface regardless of how big it is, and shrinks if
	# it wouldn't otherwise fit within the piece's own available thickness.
	var core_emissive := vis["core_emissive"] as bool
	var core_color := vis["core_color"] as Color
	var core_radius := minf(ref_size * core_fraction, ref_size * CORE_MAX_REF_FRACTION)
	var core_inset := core_radius * CORE_SUBMERGE_MARGIN
	var core: MeshInstance3D = piece.get_node_or_null("Core")
	if core == null:
		core = BlorbCore.build(core_radius, core_color, core_emissive)
		core.name = "Core"
		piece.add_child(core)
	else:
		var core_material: StandardMaterial3D = core.get_meta("material")
		core_material.albedo_color = core_color
		core_material.emission_enabled = core_emissive
	if core_emissive:
		var emissive_material: StandardMaterial3D = core.get_meta("material")
		emissive_material.emission = vis["core_emission"] as Color
		emissive_material.emission_energy_multiplier = vis["core_emission_energy"] as float
	core.position = center - facing * core_inset + core_offset

	var light: OmniLight3D = core.get_node_or_null("Light")
	if vis["has_light"] as bool:
		if light == null:
			light = OmniLight3D.new()
			light.name = "Light"
			light.omni_range = 1.2
			light.shadow_enabled = false
			core.add_child(light)
		light.light_color = vis["light_color"] as Color
	elif light != null:
		light.queue_free()
