class_name HorseFigure
extends RefCounted

## First-draft procedural rig for Manchego, the Primate Kingdom's horse mount
## (see docs/world_bible.md's own Mounts section). Built from SuperEgg parts
## like every other figure in this project, but a genuinely new QUADRUPED
## skeleton, not a reskinned biped/primate rig -- per direct correction,
## horse joints are not the same as human/monkey joints, and a horse's own
## front and hind legs are not mirrors of each other either. Real horse leg
## anatomy, and what this rig actually builds:
##
## FRONT (thoracic) leg is a 4-bone chain, top to bottom: shoulder (attach
## point, no separate mesh -- the real scapula isn't modeled) -> bone 1
## HUMERUS (short, mostly hidden against the chest) -> elbow joint -> bone 2
## RADIUS (the visible forearm) -> knee joint (the carpus -- anatomically a
## wrist, not a knee, but "knee" is the everyday name) -> bone 3 Cannon
## (long, thin) -> fetlock joint -> bone 4 hoof bone (pastern+hoof, folded
## into the same single tube as the rest of the leg -- see
## _build_front_leg()'s own comment).
##
## HIND (pelvic) leg is likewise a 4-bone chain, top to bottom: hip (attach
## point) -> bone 1 FEMUR (short, mostly hidden in the haunch) -> stifle
## joint (a true knee, anatomically) -> bone 2 TIBIA (the visible gaskin,
## longer and thicker than the front's radius -- this is what seats the
## hock noticeably higher off the ground than the front knee, real anatomy,
## not a modeling error) -> hock joint (the tarsus -- anatomically an
## ankle) -> bone 3 Cannon -> fetlock joint -> bone 4 hoof bone.
##
## Per direct correction, "the front humerus attaches to the body lower than
## the back femur does" -- SHOULDER_Y sits well below HIP_Y, a real
## anatomical fact (a horse's point of shoulder sits low against the chest,
## while the point of hip sits high in the pelvis near the croup).
##
## Per a full direct bone-by-bone REST-POSE pass (see each *_REST_ANGLE
## const's own comment for the exact instruction and reasoning), every bone
## now has a nonzero standing-pose tilt, not the perfectly vertical first
## draft: bones 1 (humerus/femur, at the shoulder/hip pivots) keep their
## existing dynamic stride swing layered on top of the new rest angle; bones
## 2 and 4 (radius/tibia at elbow/stifle, hoof bone at both fetlocks) are
## now FIXED poses with no per-frame animation at all; bone 3 (cannon, at
## the knee/hock pivots) keeps a dynamic gait flex layered on top of its own
## rest angle -- CONFIRMED backward for both front knee and hind hock by
## direct report (see KNEE_FLEX_AMOUNT's/HOCK_FLEX_AMOUNT's own comments;
## note the front knee's dynamic sign REVERSED partway through this rig's
## history once the elbow bone was inserted above it -- see
## FRONT_CANNON_REST_ANGLE's own comment for why that's not a contradiction).
##
## Per the figure-rig skill's own guidance: nothing in this file had been
## seen in-engine before the corrections above (no Godot editor/CLI access
## while writing the first draft). The front knee's and hind hock's dynamic
## gait flex are directly confirmed; the neck/head tilt is mathematically
## derived; every REST_ANGLE magnitude comes from a direct instruction
## except where noted as a first-draft pick in its own comment; the
## shoulder/hip stride-swing pivots (FRONT/HIND_STRIDE_FORWARD/BACKWARD_
## AMOUNT, i.e. whether the whole leg swings forward/backward correctly
## during a stride, as opposed to how bone 3 FLEXES once lifted) and the
## leg-attach/body-height placement constants below remain unverified
## guesses -- flagged individually where they're used.
##
## Coloring started as a Przewalski's-horse-like dun coat with black lower
## legs and tail and an orangish-brown mane, per direct instruction -- since
## lightened overall, and the separate dark "points" removed entirely (legs
## now match the body), per later direct corrections -- see COAT_COLOR's own
## comment for the current state. Eyes reuse the same round, bulgy SuperEgg
## "goggle eye" technique monkey_figure.gd's _add_eyes() established, shaped
## like Xiao Hou Zi's own eyes per direct instruction, just repositioned/
## resized for a much longer horse head.

## Lighter, sandier than the reference photo's own dun -- per direct
## correction ("more sandy light color"), then lightened again per a
## separate later correction ("his coloring should be lighter"), then
## desaturated/cooled a touch per a further correction ("slightly more
## desaturated, a sandy color that's less warm") -- R and B pulled closer
## together (less orange-yellow bias) and the whole triple pulled slightly
## toward gray.
const COAT_COLOR := Color(0.85, 0.79, 0.70)
## No more separate dark "points" -- per direct correction ("his legs should
## be the same color as his body"), this Przewalski's-style dark-leg const
## is removed; every leg segment (humerus/radius/femur/tibia/cannon/pastern)
## now just uses COAT_COLOR directly, same as the torso. The hoof itself
## used to keep its own separate dark HOOF_COLOR as a distinct rigid piece,
## but that const is gone too now that the hoof folded into the same single
## fur-colored tube as the rest of the leg (see _build_front_leg()'s own
## comment) -- losing the hoof's distinct dark color as a side effect of
## unifying the leg into one form; flag if that color distinction is still
## wanted back some other way.
## Warmer/more orange than the reference photo's black mane, per direct
## instruction. Also used for the tail (see _build_tail()) -- per direct
## correction the tail should match the mane's color rather than having its
## own separate near-black shade. Lightened per a later correction ("his
## mane and tail also a bit lighter").
const MANE_COLOR := Color(0.62, 0.36, 0.16)
const EYE_COLOR := Color(0.11, 0.075, 0.05)
## Per direct correction ("color the bottoms of the legs, just around where
## the bottom domes are, to be a chocolate brown"), baked in as a per-vertex
## color blend on the leg tube's own mesh (see _rebuild_leg_tube()) rather
## than a separate overlapping piece -- the fetlock->hoof segment (the last
## real bone) blends from COAT_COLOR into this, and the hoof-end dome cap
## beyond it is fully this color, so the brown sits right at the bottom of
## each leg with a soft transition just above it.
const LEG_SOCK_COLOR := Color(0.30, 0.18, 0.10)

# ---- Ground-up leg stacking (mirrors the rest of this project's rigs --
# see monkey_figure.gd's own ankle_y/knee_y/hip_y derivation comment) ----
# Per direct correction, remapped from a 2-real-segment approximation to a
# proper 4-bone chain per leg: FRONT is Humerus (shoulder->elbow, short,
# mostly hidden against the chest) -> Radius (elbow->knee/carpus, the
# visible forearm) -> Cannon -> Hoof bone (pastern+hoof, folded into the
# same single tube as the rest of the leg -- see _build_front_leg()'s own
# comment for why that doesn't need its own separate joint or mesh). HIND is
# Femur (hip->stifle, short) -> Tibia (stifle->hock, the visible gaskin) ->
# Cannon -> Hoof bone.
const HOOF_HEIGHT := 0.10
const PASTERN_LEN := 0.15
const FETLOCK_Y := HOOF_HEIGHT + PASTERN_LEN

## Lengthened 5cm total per direct correction ("make the front legs just a
## bit longer by maybe 5cm total, averaging out the increase over the whole
## limbs") -- each of the three front-specific bones grown by the same
## proportion (was 13/22/32cm summing to 67cm; now 14/23.6/34.4cm summing to
## 72cm) rather than adding the full 5cm to any one bone, so the leg's own
## existing bone-to-bone proportions are preserved. FETLOCK_Y (shared with
## the hind legs) is untouched, so the hoof end -- and ground contact --
## stays exactly where it was; the extra length pushes SHOULDER_Y up instead
## (see that const's own derivation), which is the "allowing the top points
## of the legs to rise into the horse body" half of the same request.
const FRONT_CANNON_LEN := 0.344
const FRONT_RADIUS_LEN := 0.236  # elbow -> knee (carpus)
const FRONT_HUMERUS_LEN := 0.14  # shoulder -> elbow

const HIND_CANNON_LEN := 0.36
## Gaskin: stifle -> hock. Longer than the front's radius -- this is what
## seats the hock noticeably higher off the ground than the front knee, a
## real anatomical fact about horses (their hind "second knee" sits higher
## than the front one), not a modeling error.
const HIND_TIBIA_LEN := 0.38  # stifle -> hock
const HIND_FEMUR_LEN := 0.21  # hip -> stifle

const KNEE_Y := FETLOCK_Y + FRONT_CANNON_LEN
const ELBOW_Y := KNEE_Y + FRONT_RADIUS_LEN
## Per direct correction ("the front humerus attaches to the body lower than
## the back femur does"): this is deliberately well below HIP_Y (see the
## real gap between the two below), not merely a couple centimeters apart
## the way the old 2-segment approximation had it -- a horse's actual point
## of shoulder sits low against the chest, well below the point of hip.
const SHOULDER_Y := ELBOW_Y + FRONT_HUMERUS_LEN
const HOCK_Y := FETLOCK_Y + HIND_CANNON_LEN
const STIFLE_Y := HOCK_Y + HIND_TIBIA_LEN
const HIP_Y := STIFLE_Y + HIND_FEMUR_LEN

# Leg radii (tube radii now that each leg is one continuous noodle -- see
# _build_front_leg()'s own comment). Used to vary per segment (thick
# humerus/femur tapering down through a thin cannon to a flared hoof, the
# single most recognizable feature of a real horse leg's silhouette), then
# consolidated to one consistent diameter down each whole leg per direct
# correction ("i just want a consistent diameter all the way down the
# legs"). Per a further direct correction ("keep the back legs this
# thickness but make the front legs about 10% less thick") -- front and
# hind now each get their own single (still internally uniform) radius
# instead of sharing one.
const HIND_LEG_RADIUS := 0.15
const FRONT_LEG_RADIUS := HIND_LEG_RADIUS * 0.9
## Per direct correction ("raise him up a bit off the ground, since with
## these bottom parts of his legs he is now clipping into the ground") --
## _rebuild_leg_tube()'s own rounded dome cap at the hoof end (see that
## function's own comment) extends PAST the anatomical hoof marker by
## roughly that end's own radius, continuing along the leg's own downward
## heading -- so the dome's actual lowest visible point now sits about that
## radius below where the hoof marker itself is, which used to BE ground
## level. Raising the whole rig by that same amount (see build()'s own use
## of this) puts the dome's own rounded bottom back at ground level instead
## of clipping through it. Tied to HIND_LEG_RADIUS specifically (the LARGER
## of the two, now that front and hind differ) -- the hind legs' own bigger
## overshoot is what actually needs the full clearance; the front legs, with
## a smaller overshoot, just end up with a bit of harmless extra headroom.
##
## Per direct correction ("horse looks like it's floating a few centimeters
## off the ground"), pulled back down by a flat 3cm -- HIND_LEG_RADIUS alone
## overshot the real gap, since the dome's own vertical drop is actually
## radius*cos(the hoof bone's net tilt off vertical), not the full radius
## (the tilt shaves a little off, and it's the whole reason this floated
## rather than clipped). First-draft flat offset, adjustable like every
## other unverified magnitude in this rig if the float/clip amount is still
## off after this.
const GROUND_CLEARANCE := HIND_LEG_RADIUS - 0.03

# Where the four legs attach on the body's own local X/Z (rig-local, since
# legs are parented straight to `rig`, not to spine_pivot -- same reasoning
# monkey_figure.gd's own build() uses: legs stay unaffected by any future
# spine/body lean). Per direct correction: brought inward (was 0.24) so the
# legs butt into the torso's own tapered side surface instead of standing
# visibly clear of it. Per a first and then a second direct correction, the
# front and hind pairs have both been drawn in toward each other -- front
# shifted back (was 0.58, then 0.42, then 0.38) and hind shifted forward
# (was -0.58) -- narrowing the stance from both ends. The 0.42 -> 0.38 step
# is a further direct correction ("shift the forelegs back by 4cm"),
# unrelated to the narrowing above -- moving the front pair's attach point
# itself further back along the body, not further inward across it.
const LEG_X := 0.15
const FRONT_LEG_Z := 0.38
const HIND_LEG_Z := -0.46

# ---- Torso ----
## Widened 10cm total per direct correction -- symmetric left/right, so
## (unlike TORSO_BELLY_EXTEND/TORSO_HAUNCH_EXTEND below) no position shift
## is needed: half the increase (5cm) on each side keeps the centerline
## fixed while the total width grows by the full 10cm.
const TORSO_HALF_WIDTH := 0.35
const TORSO_HALF_HEIGHT := 0.32
const TORSO_HALF_LENGTH := 0.62
const TORSO_EPSILON := SuperEgg.EPSILON_SOFT
## Per direct correction ("make the bottom of the body extend down about
## 8cm, and the back (butt) extend back about 8cm along with the position
## of the tail") -- a SuperEgg is symmetric around its own center on every
## axis, so widening TORSO_HALF_HEIGHT/LENGTH directly would extend BOTH
## the top and bottom (or BOTH the front and back) equally, not just one
## side. Same "widen the half-extent by half, shift the position by half
## the other way" trick already used for the neck's own base embed
## (NECK_EMBED) -- see build()'s own use of these for the exact math: the
## TOP and FRONT surfaces stay exactly where they were, only the BOTTOM
## extends down and the BACK extends back, by the full amount each.
const TORSO_BELLY_EXTEND := 0.08
const TORSO_HAUNCH_EXTEND := 0.08
## How far spine_pivot (and everything hanging off it -- torso/neck/head/
## tail) sits BELOW HIP_Y, i.e. subtracted from it directly (see build()'s
## own use of this). Renamed from BODY_SIT_LOWER per direct request -- that
## name described the body "sitting lower," but nearly every actual edit to
## this value has been someone asking to RAISE the body, which means
## DECREASING a "how much lower" quantity -- confusing enough that it was
## worth a name with no baked-in direction at all. Still just a plain drop
## distance from HIP_Y; SHOULDER_Y/HIP_Y themselves are never touched by
## this, so the legs stay exactly the length they are regardless of this
## value -- only the body's own height on top of them changes.
##
## History, for the actual numbers: originally expressed off SHOULDER_Y
## instead of HIP_Y, before the leg remap added the humerus/femur bones;
## SHOULDER_Y dropped sharply once "the front humerus attaches lower than
## the back femur" was implemented (see SHOULDER_Y's own comment), so this
## was retargeted to HIP_Y (which barely moved) and retuned (0.16 -> 0.26)
## to land spine_pivot at the SAME absolute height as before (0.94) -- a
## leg-structure change, not a request to re-lower the body. Reduced again
## (0.26 -> 0.22, then 0.22 -> 0.15, then 0.15 -> 0.10, then flattened to 0.0
## entirely -- "honestly just set it to zero at this point too") across four
## separate direct requests to raise the body further. At 0.0, spine_pivot
## sits exactly at HIP_Y with no drop at all.
const SPINE_DROP_FROM_HIP := 0.0

## ---- Rider seat mount ---- Per direct correction ("add the player riding
## the horse... keep in mind [it] should be reusable for Xiao Hou Zi and
## Blorbus too") -- a single named attach point, not anything rider-specific,
## so any future rider can read the same live transform this file already
## needs to expose for the human. Parented to spine_pivot (see build()'s own
## use), NOT to `rig` directly, for the same reason legs deliberately are
## NOT: it should track the torso's own orientation/lean if spine_pivot ever
## leans in the future, the way the neck/tail already do.
##
## Y: build()'s own "widen half + shift half" torso math (see
## TORSO_BELLY_EXTEND's own comment) keeps the torso's TOP surface fixed at
## exactly spine_pivot's own local Y + TORSO_HALF_HEIGHT regardless of how
## much belly/haunch extension is added underneath/behind -- so this is an
## EXACT value, not an estimate, for a point directly above spine_pivot's
## own Z=0.
const SEAT_Y := TORSO_HALF_HEIGHT
## Z: forward of center, roughly over the withers (a real horse's own
## saddle position, just behind the shoulder) rather than dead-center or
## over the haunches. Uses a flat fraction of TORSO_HALF_LENGTH rather than
## a true surface-point derivation (see EYE_ETA's own comment for that
## technique elsewhere in this file) -- close enough to the spine's own
## centerline that the torso's dorsal surface is still close to flat here,
## and simple/adjustable per this rig's own established practice for a
## first-draft attach point (see NECK_ATTACH_Y/NECK_ATTACH_Z for the same
## kind of flat-fraction guess). First-draft, unverified in-engine.
##
## Shifted back a further flat 25cm per direct correction ("shift him back
## 25cm on the horse's back").
const SEAT_Z := TORSO_HALF_LENGTH * 0.3 - 0.25

# ---- Neck + head ----
const NECK_HALF_LEN := 0.30
## How far the neck's own base extends past neck_pivot's origin, into the
## torso, per direct correction ("the base of the neck should extend
## completely into the body by maybe 10 centimeters"). Implemented by
## widening the neck mesh's own Z half-extent by half this amount and
## shifting its position back by the same half-amount (see
## _build_neck_and_head()) -- that combination extends the BASE end further
## back while leaving the FAR end (where head_pivot attaches) exactly where
## it already was, so the head's own position doesn't shift as a side effect.
## Extended a few more centimeters (0.10 -> 0.14) per a later direct
## correction ("you can extend the butt of the neck even a few cm more down
## into the body").
const NECK_EMBED := 0.14
## Thickened per direct correction ("the neck itself should be thicker").
const NECK_RADIUS := 0.17
## CORRECTED AXIS BUG, per direct report ("the mane isn't yet curving over
## the top face of the neck"): SuperEgg's eta parameter always spans "bottom
## pole to top pole" along local Y, REGARDLESS of which semi_axes component
## is largest (see SuperEgg's own class doc: "0 = local +Z" only describes
## omega's zero point, eta/Y is unconditional). The neck mesh used to put its
## LENGTH in semi_axes.z with only NECK_RADIUS in Y -- meaning it didn't
## build a tube running along Z at all; it built a lemon/rugby-ball shape,
## circular in cross-section at its Y-midpoint (Z=0) but TAPERING TO AN
## ACTUAL POINT at both its base (near the torso) and its tip (near the
## head), since both of those sit at large |Z|, near the mesh's own pole.
## There was never a continuous dorsal ridge for the mane to sit on. Fixed
## by rebuilding the neck with LENGTH IN SEMI_AXES.Y instead (see
## _build_neck_and_head()) -- the same convention every leg bone already
## used correctly (e.g. _build_front_leg()'s humerus/radius), which is
## exactly why the legs never had this problem.
##
## Tilt off vertical -- derived, not guessed, but RE-DERIVED for the new
## Y-long convention: rotating a local +Y-elongated part by rotation.x=theta
## sends its far pole to (y=cos(theta), z=sin(theta)) under Godot's standard
## right-handed X-rotation matrix (contrast the OLD +Z-elongated formula,
## y=-sin(theta), z=cos(theta), which the head still uses -- see
## HEAD_DOWN_ANGLE's own comment, unaffected by this fix). A POSITIVE theta
## is what tips a +Y-pointing neck toward +Z (forward) now -- theta itself
## IS the angle from true vertical for a Y-long part (since the Y-component
## of the result is cos(theta) directly), so 38 degrees here reproduces the
## exact same 38-degree-from-vertical tilt the old (broken-shape) neck had
## at its old value of 52 degrees under the old formula (cos(52 deg away
## from the OLD formula's own -sin/cos pairing) worked out to the same
## effective tilt) -- chosen to preserve the already-tuned visual angle
## rather than arbitrarily picking a new one now that the shape is fixed.
const NECK_TILT_ANGLE := deg_to_rad(38.0)
const NECK_ATTACH_Y := TORSO_HALF_HEIGHT * 0.55
## Pulled back from 0.92 per direct correction ("the neck... should be
## shifted more to butt farther into the body") -- the neck's own base now
## sits well inside the torso's own front half rather than right at its
## very tip, so more of the neck mesh's base end overlaps/buries into the
## torso instead of just grazing its surface.
const NECK_ATTACH_Z := TORSO_HALF_LENGTH * 0.75

## The poll (where the skull meets the neck) bends the head back down --
## per direct correction, giving head_pivot no rotation of its own left it
## simply inheriting neck_pivot's full upward tilt, nose and all, which is
## exactly the reported "facing up into the sky" bug. head_pivot is a CHILD
## of neck_pivot, and since neck_pivot only ever rotates about X, head_
## pivot's own local X stays parallel to world X -- so the two rotations
## compose by simple addition, both being plain rotations about that same
## axis: total_angle = neck_pivot.rotation.x + head_pivot.rotation.x. The
## HEAD mesh itself is still Z-long (this fix only touched the neck's own
## shape, not the head's -- see NECK_TILT_ANGLE's own comment), so it still
## uses the OLD local+Z-pole formula: local+Z maps to world
## (y=-sin(total), z=cos(total)) -- NEGATIVE total_angle points the nose up,
## POSITIVE points it down. The target is unchanged from before the neck fix
## (nose ends up HEAD_DOWN_ANGLE degrees past level): total_angle should
## equal +HEAD_DOWN_ANGLE. Since neck_pivot.rotation.x is now +NECK_TILT_ANGLE
## (positive, under the neck's own NEW Y-long formula -- see that constant's
## own comment) rather than the old -NECK_TILT_ANGLE, canceling it now needs
## SUBTRACTION instead of addition: head_pivot.rotation.x =
## HEAD_DOWN_ANGLE - NECK_TILT_ANGLE, not NECK_TILT_ANGLE + HEAD_DOWN_ANGLE.
## Increased again per a later direct correction ("the head should pitch
## down even more") -- was 20, then 32.
const HEAD_DOWN_ANGLE := deg_to_rad(44.0)
## head_pivot's own fixed local rotation.x (relative to neck_pivot) -- named
## so manchego.gd's own look-turn code can reuse the exact same value rather
## than duplicating the sum. See manchego.gd's own _update_head_look() doc
## comment for why the dynamic look-yaw can't just be layered onto this same
## node's rotation.y directly (a real bug, reported as "simply tilting his
## head side to side" instead of turning): Godot's rotation Vector3 composes
## Euler angles as Ry*Rx*Rz, so a nonzero rotation.y on a node that ALSO has
## a large rotation.x ends up rotating around the PARENT's own Y axis (here,
## neck_pivot's, tilted ~38 degrees off true vertical by NECK_TILT_ANGLE),
## not a clean world-vertical turn -- regardless of this constant's own
## value, mixing a dynamic Y rotation onto a node that already carries a
## large static X rotation is the wrong technique in general.
const HEAD_REST_PITCH := HEAD_DOWN_ANGLE - NECK_TILT_ANGLE

## 15% larger than the first draft, per direct correction. X (half-width) is
## pinned to NECK_RADIUS per a later direct correction ("the head piece
## should be broader, the same width as the neck"). Y (half-height, "top to
## chin") enlarged again slightly per a further correction.
const HEAD_SIZE := Vector3(NECK_RADIUS, 0.095 * 1.15 * 1.2, 0.205 * 1.15)
const HEAD_EPSILON := 2.3
## Enlarged 15% per direct correction, then a further 5% per a later direct
## correction ("increase ear size by 5%") -- 1.15 * 1.05.
const EAR_SIZE := Vector3(0.028, 0.075, 0.02) * 1.2075
const EAR_EPSILON := 2.6

## A fixed absolute radius, NOT a factor of HEAD_SIZE.x -- per direct
## correction ("why did you enlarge the eyes, put them back to the size they
## were before... when you broadened the head"). Broadening HEAD_SIZE.x for
## the head-width correction silently scaled the eyes up too, since they
## used to be computed as HEAD_SIZE.x * a factor -- decoupling them here so
## a future head-width change can't do that again. Value matches exactly
## what that factor produced before the broadening (HEAD_SIZE.x was
## 0.085*1.15 ~= 0.098 back then, factor 0.30 -> ~0.0293).
const EYE_RADIUS := 0.0293
## SuperEgg's own omega convention: 0 = local +Z (the snout-tip direction).
## Real horse eyes sit well back and to the side of the head, so this is
## much wider than monkey_figure.gd's own 17.5-degree spacing -- past 90
## degrees, into the "rear-lateral" part of the head surface.
const EYE_OFFSET := deg_to_rad(100.0)
## Latitude on the head's own superegg -- eta=0 is the equator (straight out
## the side), positive eta moves toward the TOP pole (+Y, "top to chin" per
## HEAD_SIZE's own comment), i.e. toward the dorsal ridge running from the
## nose over the crown to the back of the head. Increased per direct
## correction ("the eyes are a little too far down the sides of his head...
## shift them toward the 'top' side") -- was 0.12 rad (~7 degrees, barely
## off the equator), now ~20 degrees, estimated to move each eye roughly
## 3cm further up the head's own surface (HEAD_SIZE.y ~= 0.131: eta=0.12
## put the eye ~2cm above center, eta=20deg puts it ~5cm above center).
const EYE_ETA := deg_to_rad(20.0)
const EYE_FLATTEN := 0.55

# ---- Tail ----
const TAIL_BASE_RADIUS := 0.05
const TAIL_DOME_STEPS := 4
const LIMB_RADIAL_SEGMENTS := BlorbSuit.LIMB_RADIAL_SEGMENTS
const LIMB_RINGS_PER_SEGMENT := BlorbSuit.RINGS_PER_SEGMENT
## NO LONGER USED for the legs (see _rebuild_leg_tube()'s own comment for
## why build_limb_tube()'s own cap_fraction taper -- a straight-line pinch
## to a point -- was replaced with a manual rounded dome cap at the hoof
## end, per direct correction "be sure the bottom of the tube is rounded,
## not tapered or flat"). Kept only as a reference value/name match to
## monkey_figure.gd's own identically-named, differently-used constant.
const LIMB_CAP_FRACTION := BlorbSuit.TUBE_CAP_FRACTION
## How many extra loft points approximate the hoof end's rounded dome --
## same technique and same step count as this file's own tail
## (TAIL_DOME_STEPS) and monkey_figure.gd's tail before it -- see
## _rebuild_leg_tube()'s own comment for the full reasoning.
const LEG_HOOF_DOME_STEPS := 4

# ---- Gait ----
## UNVERIFIED GUESS (per this file's own class doc comment and the
## figure-rig skill's rule 4): reuses player.gd's own confirmed hip/shoulder
## fact ("positive rotation.x = backward, negative = forward") as the
## starting hypothesis for these brand-new shoulder/hip pivots, since they're
## built the same plain-Node3D, forward=+Z way every other pivot in this
## project is. Not independently confirmed for THIS rig -- flag to the user
## once Manchego is actually seen moving.
##
## Split into four separate, ASYMMETRIC amounts per direct correction ("the
## swing of the hind legs is swinging way too far back... please cap the
## backwards swing by quite a bit. And I think the swing of the forelegs
## isn't coming forward quite enough") -- a single shared STRIDE_SWING_AMOUNT
## (was 48 degrees both directions, both limb types) couldn't express "front
## needs more forward, hind needs less backward" as two independent facts.
## HIND_STRIDE_FORWARD_AMOUNT keeps the old 48-degree value since it was
## never reported wrong. FRONT_STRIDE_BACKWARD_AMOUNT was ALSO left at 48
## initially (not reported wrong at the time), but a later, separate direct
## correction ("the backswing of his front legs is way too far back, the
## front swing is fine") capped it the same way the hind backswing already
## was -- FRONT_STRIDE_FORWARD_AMOUNT (the "front swing" confirmed fine AT
## THE TIME) was left untouched by that pass.
## Per a still later, separate direct correction ("the front legs don't need
## to swing forward quite this much either"), which supersedes that earlier
## "confirmed fine" -- capped down from 68 to 50 degrees. First-draft
## reduction amount (no specific degree given), adjustable like every other
## unspecified magnitude in this rig.
const FRONT_STRIDE_FORWARD_AMOUNT := deg_to_rad(50.0)
const FRONT_STRIDE_BACKWARD_AMOUNT := deg_to_rad(20.0)
const HIND_STRIDE_FORWARD_AMOUNT := deg_to_rad(48.0)
const HIND_STRIDE_BACKWARD_AMOUNT := deg_to_rad(20.0)

## ---- Per-bone REST angles, per direct correction (a full bone-by-bone
## pass specifying each of the 4 bones per leg) ----
## Bone 1 (humerus, the shoulder pivot's own rotation): "should angle back
## substantially, by maybe 20 degrees." This is a STANDING-POSE bias, not a
## gait animation -- shoulder's existing STRIDE_SWING_AMOUNT dynamic swing
## (whole-leg forward/back during a stride) still applies ON TOP of this,
## unchanged; this only shifts what angle the leg swings AROUND.
const FRONT_HUMERUS_REST_ANGLE := deg_to_rad(20.0)
## Bone 2 (radius, the elbow pivot's own rotation): "should angle forward to
## compensate" -- same magnitude as bone 1's own back-angle, opposite sign,
## so the leg's net line returns close to vertical. Unlike bone 1, no
## dynamic gait component was specified for this bone -- baked once at build
## time as a fixed pose (see _build_front_leg()), not touched per-frame.
const FRONT_RADIUS_REST_ANGLE := deg_to_rad(-20.0)
## Bone 3 (cannon, the knee/carpus pivot's own rotation): "should angle back
## subtly and bend back when walking" -- a small backward rest bias PLUS a
## dynamic backward flex during the gait's lift phase (see
## _animate_front_leg()). This dynamic direction is a REVERSAL from this
## rig's own earlier "front knee flexes forward" finding -- not a
## contradiction, but a consequence of the leg remap: this same pivot's
## visual result depends on its PARENT's orientation (see KNEE_FLEX_AMOUNT's
## own comment for the general rule), and its parent is now the elbow's
## newly rest-tilted frame rather than the shoulder's, so the sign that
## reads as "backward" has legitimately changed. Trusting this newer, more
## specific direct instruction over the older one.
const FRONT_CANNON_REST_ANGLE := deg_to_rad(8.0)
## Bone 4 (hoof bone, the fetlock pivot's own rotation): "should angle
## forward." No dynamic gait component was specified (unlike bone 3) -- per
## the same pattern as bone 2, baked once at build time as a fixed pose. No
## magnitude was given; 15 degrees is a first-draft pick, adjustable on
## report like every other unspecified magnitude in this rig.
const FRONT_HOOF_REST_ANGLE := deg_to_rad(-15.0)

## Bone 1 (femur, the hip pivot's own rotation): "should angle forward by
## maybe 12 degrees." Same STRIDE_SWING_AMOUNT-still-applies-on-top
## reasoning as the front humerus.
const HIND_FEMUR_REST_ANGLE := deg_to_rad(-12.0)
## Bone 2 (tibia, the stifle pivot's own rotation): "should angle back to
## compensate and then some" -- MORE than bone 1's 12 degrees, per "and then
## some." No dynamic component specified -- baked once at build time, same
## pattern as the front radius.
const HIND_TIBIA_REST_ANGLE := deg_to_rad(22.0)
## Bone 3 (cannon, the hock pivot's own rotation): "should angle forward."
## Unlike the front leg's own bone 3, no "bend when walking" was specified
## here in this same message -- but the hock's own dynamic backward flex
## during the gait's lift phase (HOCK_FLEX_AMOUNT, below) was independently
## CONFIRMED by an earlier direct report and nothing here contradicts or
## withdraws that, so it stays layered on top of this new rest bias rather
## than being removed.
const HIND_CANNON_REST_ANGLE := deg_to_rad(-10.0)
## Bone 4 (hoof bone, the fetlock pivot's own rotation): "should also angle
## forward." Same rest-only treatment as the front hoof bone -- no dynamic
## gait component, baked once at build time.
const HIND_HOOF_REST_ANGLE := deg_to_rad(-12.0)

## Front knee/carpus dynamic flex magnitude, layered on top of
## FRONT_CANNON_REST_ANGLE during the gait's lift phase -- see that
## constant's own comment for why the sign is now POSITIVE (backward),
## reversed from this rig's earlier "flexes forward" finding.
const KNEE_FLEX_AMOUNT := deg_to_rad(45.0)
## Hind hock dynamic flex magnitude, layered on top of HIND_CANNON_REST_ANGLE
## during the gait's lift phase. CONFIRMED BACKWARDS by earlier direct
## report ("the knees of his back legs should angle back not forward") --
## applied with a POSITIVE sign (backward), unchanged by this rest-angle
## pass since nothing here contradicts that earlier finding.
const HOCK_FLEX_AMOUNT := deg_to_rad(45.0)

## Per direct correction ("give him a running gait too, which should not
## only be increased limb speed but also amplify in the bend degree of all
## his limbs in the strides") -- the actual per-frame cycle SPEED lives in
## manchego.gd (see its own RUN_CYCLE_SPEED_MULTIPLIER, applied to how fast
## `phase` advances, upstream of this file entirely), so this only covers
## the second half of that instruction: scales every dynamic bend this
## file's own animate_gait() applies -- both stride swing (FRONT/HIND_
## STRIDE_FORWARD/BACKWARD_AMOUNT) and lift flex (KNEE_FLEX_AMOUNT/
## HOCK_FLEX_AMOUNT) -- up together while running, so a run doesn't just
## replay the walk faster but genuinely strides and flexes harder too.
## First-draft magnitude, unverified in-engine like every other unspecified
## number in this rig -- adjustable on report.
const RUN_BEND_MULTIPLIER := 1.4

## ---- Jump ---- Per direct correction ("we'll want to add a jump ability...
## think how the player jumps, that he bends all his leg joints gradually
## until the bend is most extreme at the top of his jump, then relaxes back
## down, and then has an impact when hitting the ground") -- mirrors
## player.gd's own _apply_airborne_pose()/_animate_landing() shape (an
## `apex_fraction` that peaks at the jump's apex and eases both directions,
## then a separate brief held landing pose), applied to this rig's own
## joints instead of a biped's hip/knee/ankle. The takeoff/gravity/landing
## PHYSICS live in manchego.gd (see its own JUMP_VELOCITY/JUMP_GRAVITY) --
## this file only owns what the LEGS do once airborne.
##
## All four legs tuck TOGETHER here (no per-leg phase offset the way
## animate_gait() staggers them) -- a horse jumping an obstacle folds every
## leg up under itself roughly at once, not in a walking sequence.
##
## Sign reuse, not new guesses, for the KNEE/hock terms: the front knee
## reuses KNEE_FLEX_AMOUNT's own already-confirmed "positive knee
## rotation.x = lifting the foot" direction (a jump tuck IS an exaggerated
## foot-lift), and the hind tuck reuses the gait's own confirmed "negative
## hip rotation.x = forward/up" swing direction plus HOCK_FLEX_AMOUNT's own
## confirmed positive lift direction -- see KNEE_FLEX_AMOUNT's/
## HOCK_FLEX_AMOUNT's own comments and _animate_hind_leg()'s own swing
## formula for where each of those was established.
##
## The SHOULDER term (JUMP_SHOULDER_TUCK, below) is applied as a FORWARD
## bend now (see _apply_front_tuck()'s own comment), per direct correction
## ("the bend in the legs should also include a forward bend at the upper
## end of the forelegs") -- reuses FRONT_RADIUS_REST_ANGLE's own confirmed
## "negative rotation.x = forward" sign for this same pivot chain, not a
## fresh guess either, even though the ORIGINAL first-draft direction here
## (backward) was.
const JUMP_SHOULDER_TUCK := deg_to_rad(35.0)
const JUMP_KNEE_TUCK := deg_to_rad(70.0)
const JUMP_HIP_TUCK := deg_to_rad(30.0)
const JUMP_HOCK_TUCK := deg_to_rad(70.0)
## How fast the tuck itself eases toward its current apex_fraction-scaled
## target -- deliberately slower than LEG_SETTLE_SPEED (which is for
## snapping OUT of a stride back to rest) so the tuck reads as a gradual
## fold through the flight, matching "bends... gradually," not a snap.
const JUMP_POSE_SETTLE_SPEED := 6.0

## Landing impact -- a brief echo of the same tuck direction (shock
## absorption reads the same way a jump lift does on these joints, just
## shorter), held for manchego.gd's own LANDING_DURATION before handing back
## to normal gait/rest. Faster settle than the jump tuck itself so the
## impact reads as a snap, not another gradual fold.
##
## Cut roughly to a third (22/38/18/38 -> 7/12/6/12) per direct correction
## ("the bend of the legs on impact is way too extreme, it should be
## subtle") -- the BODY's own dip/rise (LANDING_BODY_DIP_AMOUNT below) now
## carries most of the impact's visual weight instead, matching how
## player.gd's own landing splits the reaction between a leg bend AND a
## body-height dip rather than putting it all on the legs.
const LANDING_SHOULDER_BEND := deg_to_rad(7.0)
const LANDING_KNEE_BEND := deg_to_rad(12.0)
const LANDING_HIP_BEND := deg_to_rad(6.0)
const LANDING_HOCK_BEND := deg_to_rad(12.0)
const LANDING_SETTLE_SPEED := 16.0
## Per direct correction ("his body should lower and raise back up to
## resting just like the player's does") -- same idea as player.gd's own
## LANDING_BODY_DIP_AMOUNT: spine_pivot dips by this much during the
## landing hold (see animate_landing()), then eases back up to its own rest
## Y once normal gait/airborne animation resumes (see animate_gait()'s and
## animate_airborne()'s own use of this same rest-Y recovery). First-draft
## magnitude, unverified in-engine.
const LANDING_BODY_DIP_AMOUNT := 0.08


## variant is currently unused (no villager-style palette swap exists yet
## for Manchego -- just one instance in the world), kept only so a future
## caller can retint/rescale without reshaping this function's signature.
static func build(parent: Node3D, variant: Dictionary = {}) -> Dictionary:
	var rig := Node3D.new()
	rig.name = "HorseFigure"
	# See GROUND_CLEARANCE's own comment -- compensates for the leg tubes'
	# own rounded hoof-end dome cap extending past the anatomical hoof
	# marker, which otherwise clips through the ground.
	rig.position.y = GROUND_CLEARANCE
	parent.add_child(rig)

	var spine_pivot := Node3D.new()
	spine_pivot.name = "HorseSpinePivot"
	# See SPINE_DROP_FROM_HIP's own comment -- HIP_Y still anchors the legs' own
	# attach heights directly (unchanged), only the body sinks lower here.
	spine_pivot.position = Vector3(0, HIP_Y - SPINE_DROP_FROM_HIP, 0)
	rig.add_child(spine_pivot)

	# See TORSO_BELLY_EXTEND's/TORSO_HAUNCH_EXTEND's own comment for the
	# widen-half-shift-half math -- keeps the top and front surfaces fixed
	# while the bottom extends down and the back extends back.
	var torso := SuperEgg.build_part(
		Vector3(
			TORSO_HALF_WIDTH,
			TORSO_HALF_HEIGHT + TORSO_BELLY_EXTEND * 0.5,
			TORSO_HALF_LENGTH + TORSO_HAUNCH_EXTEND * 0.5,
		),
		COAT_COLOR, TORSO_EPSILON
	)
	torso.name = "Torso"
	torso.position = Vector3(0, -TORSO_BELLY_EXTEND * 0.5, -TORSO_HAUNCH_EXTEND * 0.5)
	# spine_pivot sits at HIP_Y - SPINE_DROP_FROM_HIP; the front SHOULDER_Y is now
	# well below that (see SHOULDER_Y's own comment on the humerus attaching
	# low against the chest), but still well inside the torso's own
	# half-height below spine_pivot, so the shoulder attachment stays
	# visually buried in the body without needing a separate pitch/offset.
	spine_pivot.add_child(torso)

	# See SEAT_Y's/SEAT_Z's own comments -- a plain marker Node3D, no mesh,
	# no rotation of its own (its world orientation is purely spine_pivot's
	# own, inherited for free), just a live transform a rider can read every
	# frame the same way manchego.gd itself reads head/neck for look-yaw.
	var seat := Node3D.new()
	seat.name = "HorseSeatMount"
	seat.position = Vector3(0, SEAT_Y, SEAT_Z)
	spine_pivot.add_child(seat)

	var head_parts := _build_neck_and_head(spine_pivot)

	var front_left := _build_front_leg(rig, 1.0)
	var front_right := _build_front_leg(rig, -1.0)
	var hind_left := _build_hind_leg(rig, 1.0)
	var hind_right := _build_hind_leg(rig, -1.0)

	var tail := _build_tail(spine_pivot)

	var pivots := {
		"_rig": rig,
		"spine": spine_pivot,
		"seat": seat,
		"neck": head_parts["neck_pivot"],
		"head": head_parts["head_pivot"],
		"eyes": head_parts["eyes"],
		"legs": {
			"front_left": front_left, "front_right": front_right,
			"hind_left": hind_left, "hind_right": hind_right,
		},
		"_tail": tail,
	}
	# Frame-0 loft for the four leg noodle tubes -- same reasoning
	# monkey_figure.gd's own build() ends with an identical
	# rebuild_limbs(pivots, rig, 0.0) call: the tube MeshInstance3Ds were
	# just created with no mesh assigned yet (see _build_front_leg()'s/
	# _build_hind_leg()'s own comment), so without this they'd render as
	# nothing until the first per-frame rebuild_limbs() call from
	# manchego.gd actually happens.
	rebuild_limbs(pivots)
	return pivots


static func _build_neck_and_head(spine_pivot: Node3D) -> Dictionary:
	var neck_pivot := Node3D.new()
	neck_pivot.name = "HorseNeckPivot"
	neck_pivot.position = Vector3(0, NECK_ATTACH_Y, NECK_ATTACH_Z)
	# POSITIVE now, under the neck's own corrected Y-long formula -- see
	# NECK_TILT_ANGLE's own comment for the full derivation and why this
	# flipped sign from the old (wrongly-shaped) neck's -NECK_TILT_ANGLE.
	neck_pivot.rotation.x = NECK_TILT_ANGLE
	spine_pivot.add_child(neck_pivot)

	var neck := SuperEgg.build_part(
		Vector3(NECK_RADIUS, NECK_HALF_LEN + NECK_EMBED * 0.5, NECK_RADIUS), COAT_COLOR, SuperEgg.EPSILON_SOFT
	)
	neck.name = "Neck"
	# LENGTH IN Y now (see NECK_TILT_ANGLE's own comment for why -- this is
	# the actual shape fix). Base pole sits NECK_EMBED behind neck_pivot's
	# own origin (see NECK_EMBED's own comment) -- widening the mesh's own
	# half-extent by half that amount and shifting the whole mesh back
	# (along Y now, not Z) by the same half-amount keeps the FAR pole (where
	# head_pivot attaches, at exactly NECK_HALF_LEN*2.0 above) fixed in place
	# while only the base end extends further back into the torso. Matches
	# monkey_figure.gd's own head_pivot-offset idiom otherwise, and matches
	# how every leg bone in this file already builds its own length in Y.
	neck.position = Vector3(0, NECK_HALF_LEN - NECK_EMBED * 0.5, 0)
	neck_pivot.add_child(neck)

	var head_pivot := Node3D.new()
	head_pivot.name = "HorseHeadPivot"
	# Along neck_pivot's own local Y now, matching the neck mesh's corrected
	# long axis -- was local Z. Raised 1cm further out per direct correction
	# ("raise up the head on the neck by 1cm").
	head_pivot.position = Vector3(0, NECK_HALF_LEN * 2.0 + 0.01, 0)
	# See HEAD_DOWN_ANGLE/HEAD_REST_PITCH's own comments -- bends the head
	# back down at the poll instead of letting it inherit the neck's own
	# upward tilt. This is only the REST value -- manchego.gd's own look-turn
	# code recomputes this same pitch fresh every frame it's driving the
	# head at all (see HEAD_REST_PITCH's own comment for why), so this
	# assignment mainly matters before that first _process() call runs.
	head_pivot.rotation.x = HEAD_REST_PITCH
	neck_pivot.add_child(head_pivot)

	var head := SuperEgg.build_part(HEAD_SIZE, COAT_COLOR, HEAD_EPSILON)
	head.name = "Head"
	# Shifted forward (0.7 -> 0.82 of HEAD_SIZE.z) and down (-0.02 local Y)
	# within head_pivot's own frame, per direct correction ("positioned a bit
	# forward and downward on the neck") -- then down further still (-0.02 ->
	# -0.06, then -0.06 -> -0.11, five more centimeters) per two later
	# corrections ("lower the head down a bit more on the neck" / "try 5
	# more cm"). Shifted back 3cm more (a straight -0.03 on the Z offset,
	# moving the whole head, nose included) per a further direct correction
	# ("the back of the head can extend back into the neck a bit more, by
	# maybe 3cm").
	head.position = Vector3(0, -0.11, HEAD_SIZE.z * 0.82 - 0.03)
	head_pivot.add_child(head)

	_add_ears(head_pivot)
	var eyes := _add_eyes(head)
	_build_mane(neck_pivot, head_pivot)
	return {"neck_pivot": neck_pivot, "head_pivot": head_pivot, "eyes": eyes}


## REDESIGNED from scratch per direct instruction, after repeated reports
## that the previous centerline-tube approach still wasn't reading as "on
## top of the neck" -- rather than continuing to tune a single tube whose
## points chase the neck's own tapering superellipsoid surface, this now
## runs a pipe through three EXPLICIT real surface anchor points: (A) the
## base of the neck at the torso, (B) the top of the neck near the head, and
## (C) the top of the head between the ears. All three are on the DORSAL
## (top, once tilted) side -- local -Z for A/B, derived from first
## principles (a point at local (x, y0, z) on the neck's own circular
## cross-section at height y0 maps, under neck_pivot.rotation.x=theta
## (theta>0), to world_y = y0*cos(theta) - z*sin(theta), maximized when z is
## most NEGATIVE) -- and the head's own local +Y (its "up," the same
## direction the ears themselves are seated along) for C, converted into
## neck_pivot's local space via head_pivot's own REST transform (already set
## by the time this is called -- see _build_neck_and_head()'s own call
## order -- and untouched again during build; only manchego.gd's runtime
## look-turn code ever changes it afterward).
##
## "Meeting those points along its bottom so that it fans upwards... like a
## mohawk": build_limb_tube() centers its tube ON each control point, so a
## point placed exactly at the anchor would bury half the tube INSIDE the
## body. Instead each anchor is pushed outward (away from the surface -- the
## same "up" direction used to locate it) by that point's own radius, so the
## tube's own lower surface comes back down to touch the anchor, and the
## rest of its round cross-section fans upward from there, the "rooted at a
## line, fanning up" mohawk silhouette. Per a later direct correction ("its
## bottom should disappear butting into the horse's form"), that outward
## push is now reduced further (see MANE_EMBED_ADJUST below) so the tube
## actually buries into the surface a bit rather than just grazing it.
static func _build_mane(neck_pivot: Node3D, head_pivot: Node3D) -> MeshInstance3D:
	# A: base of the neck, at the torso -- a little short of NECK_EMBED's own
	# full depth so it stays on real (not fully torso-buried) neck surface.
	var anchor_a := Vector3(0, 0.04, -NECK_RADIUS)
	# B: top of the neck, near the head -- short of the neck's own far pole
	# (NECK_HALF_LEN*2.0) for the same reason previous attempts pulled in
	# from the poles: a superellipsoid's cross-section has already tapered
	# toward nothing right at the pole itself (see this function's own
	# derivation comment above).
	var anchor_b := Vector3(0, NECK_HALF_LEN * 2.0 - 0.08, -NECK_RADIUS)
	# C: top of the head, between the ears -- in head_pivot's own local
	# space this sits at the same rough Z the ears themselves are seated at
	# (see _add_ears()), just centered on X=0 instead of offset to a side.
	# Y lowered per direct report ("the top is hovering off his head, lower
	# it down several cm") -- was 0.665 (close to the ears' own PRE-lowering
	# factor, before their own two separate lower-into-the-head corrections
	# this point never tracked), now a flat lower value.
	var head_local_c := Vector3(0, HEAD_SIZE.y * 0.42, HEAD_SIZE.z * 0.15)
	var head_rest_basis := Basis(Vector3.RIGHT, head_pivot.rotation.x)
	var anchor_c: Vector3 = head_pivot.position + head_rest_basis * head_local_c

	var out_ab := Vector3(0, 0, -1.0)
	var out_c := (head_rest_basis * Vector3.UP).normalized()

	# C's own outward push (how far the tube's centerline sits proud of this
	# anchor) also reduced (0.05 -> 0.035) -- less of the tube reaching
	# further up/out past the head's own surface at that point.
	var anchor_radii: Array[float] = [0.05, 0.075, 0.035]
	var anchors: Array[Vector3] = [anchor_a, anchor_b, anchor_c]
	var outward_dirs: Array[Vector3] = [out_ab, out_ab, out_c]

	# Per direct correction ("lower the mane maybe 5cm more, its bottom
	# should disappear butting into the horse's form") -- previously each
	# point sat exactly ITS OWN radius proud of the anchor, so the tube's
	# lower surface came back down to JUST touch the anchor precisely. This
	# subtracts a flat 5cm from that outward push instead, so the centerline
	# sits closer to (and, for the smaller-radius anchors, past) the surface
	# -- both a lower position AND a real embed/overlap where the tube's own
	# lower half now buries into the body instead of merely grazing it.
	const MANE_EMBED_ADJUST := 0.05
	var points: Array[Vector3] = []
	var radii: Array[float] = []
	for i in anchors.size():
		points.append(anchors[i] + outward_dirs[i] * (anchor_radii[i] - MANE_EMBED_ADJUST))
		radii.append(anchor_radii[i])

	var mane := MeshInstance3D.new()
	mane.name = "Mane"
	# A gentler cap on this shorter 3-point run than the tail's own 0.0 (a
	# free-hanging tip that needs the full dome-cap treatment) -- reads as a
	# rounded crest blending into both the withers and the poll rather than
	# a bare flat-cut strip.
	mane.mesh = BlorbSuit.build_limb_tube(points, radii, LIMB_RADIAL_SEGMENTS, LIMB_RINGS_PER_SEGMENT, 0.12)
	# Flattens local X (this pipe's own "side-to-side" ring axis) for a
	# ridge-like profile rather than a round rope, same idea as the tail's
	# own flatten.
	mane.scale.x = 0.68
	_apply_fur_material(mane, MANE_COLOR)
	neck_pivot.add_child(mane)
	return mane


## CONFIRMED ROOT CAUSE, per direct report ("both the tail and the mane are
## taking the blorb body's visual properties... we also saw this problem
## for several turns when we were modeling Xiao Hou Zi's body... and it was
## finally fixed and resolved"). Parts built via BlorbSuit.build_limb_tube()
## (the mane and tail here) don't guarantee consistent single-sided winding
## on every triangle -- blorb_suit.gd's own consumers of that same shared
## geometry never noticed because their material is ALREADY alpha-blended
## translucent goo (see BlorbSuit._build_goo_material()) by design, which
## masks the winding issue. monkey_figure.gd hit this exact problem as the
## first OPAQUE consumer of that geometry (its own arm/leg/tail tubes) and
## fixed it with the material recipe below -- reused verbatim (see that
## file's own _build_fur_material()) rather than re-deriving it, except
## roughness, which stays at 0.6 to match every other SuperEgg-built part of
## THIS body (torso/legs/head) rather than monkey's own fur value (0.95).
static func _apply_fur_material(mesh_instance: MeshInstance3D, color: Color) -> void:
	mesh_instance.material_override = _build_fur_material(color)


static func _build_fur_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(color.r, color.g, color.b, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
	material.metallic = 0.0
	material.roughness = 0.6
	material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# The actual fix for the reported "see through" look: this shared tube
	# geometry doesn't guarantee correct winding, so default backface
	# culling can show the mesh's own interior surface through in places.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## Leg-only variant -- per direct correction, the leg tubes now carry a
## baked-in per-vertex color blend (COAT_COLOR fading to LEG_SOCK_COLOR near
## the bottom, see _rebuild_leg_tube()) so the "sock" reads as part of the
## same single mesh instead of a separate piece. A plain _build_fur_material
## color sets albedo_color directly and ignores vertex colors entirely, so
## that blend would be invisible without this: albedo_color is left WHITE
## and vertex_color_use_as_albedo is turned on, so the final rendered color
## comes from each vertex's own baked color unmodified (white * vertex_color
## == vertex_color). Every other material recipe/setting (the cull_mode fix
## especially) is identical, reused via _build_fur_material() itself.
static func _apply_leg_fur_material(mesh_instance: MeshInstance3D) -> void:
	mesh_instance.material_override = _build_leg_fur_material()


static func _build_leg_fur_material() -> StandardMaterial3D:
	var material := _build_fur_material(Color.WHITE)
	material.vertex_color_use_as_albedo = true
	# Per direct correction ("the tops of the legs no longer look to match
	# the body color exactly") -- COAT_COLOR was baked into the leg's own
	# vertex colors as the SAME raw numbers _build_fur_material() puts into
	# albedo_color everywhere else (torso, mane, tail), but Godot treats
	# those two color sources differently by default: albedo_color is
	# authored sRGB and auto-converted to linear before lighting, while a
	# mesh's own vertex COLOR array is read as already-linear UNLESS this
	# flag says otherwise -- so the exact same numbers rendered visibly
	# darker/duller here than the torso's own identical COAT_COLOR right
	# next to it. Turning this on tells the renderer to apply that same
	# sRGB->linear conversion to vertex colors too, so a COAT_COLOR vertex
	# and a COAT_COLOR albedo_color now actually match.
	material.vertex_color_is_srgb = true
	return material



static func _add_ears(head_pivot: Node3D) -> void:
	for side in [-1.0, 1.0]:
		var ear := SuperEgg.build_part(EAR_SIZE, COAT_COLOR, EAR_EPSILON)
		ear.name = "EarL" if side < 0.0 else "EarR"
		# Brought down per direct report ("the ears are now floating above
		# the head without touching it, bring them down some") -- Y factor
		# 0.85 -> 0.68, closer to the head's own surface -- then down another
		# flat 1.5cm per a repeat report ("the ears are still floating too
		# high, lower them another 1.5 cm into the head"), then a further flat
		# 3cm per a later direct correction ("lower them to butt into his head
		# more by about 3cm").
		#
		# Z: shifted back (toward the head's own -Z, away from the snout --
		# see EYE_OFFSET's own comment for "0 = local +Z is the snout-tip
		# direction") by a flat 5cm per direct correction ("shift the ears
		# more toward the back of his head by about 5cm"), then a further
		# flat 3cm per a later direct correction ("shift the ears back on
		# his head by a few more cm").
		ear.position = Vector3(
			side * HEAD_SIZE.x * 0.55, HEAD_SIZE.y * 0.68 - 0.045, HEAD_SIZE.z * 0.15 - 0.08
		)
		# X/Z: a slight outward/forward cant, tipped up -- horse ears stand
		# upright and swivel, this is just a plausible static rest pose.
		# CONFIRMED BACKWARDS by direct report ("angled inwards toward each
		# other, they should be angled outward... but only slightly") --
		# under Godot's rotation-around-Z formula (x'=x*cos(t)-y*sin(t)), a
		# Z rotation of side*ANGLE on an ear pointing local +Y (up) swings its
		# tip toward -side*X, i.e. TOWARD the opposite side's ear (inward).
		# Negating to -side*ANGLE swings each tip toward its OWN side instead
		# (outward). Also reduced from 18 to 11 degrees per "only slightly."
		#
		# Y: per direct correction ("twist them outward angling their
		# listening face away from each other... maybe 15 degrees") -- yaws
		# each ear around its own vertical axis so its broad flat face (the
		# ear's thinnest dimension, EAR_SIZE.z, is its face-normal) turns to
		# point outward/sideways instead of straight forward. UNVERIFIED
		# GUESS sign: under Godot's rotation-around-Y formula
		# (x'=x*cos(t)+z*sin(t)), a local +Z-facing normal rotated by
		# side*ANGLE maps toward +side*X -- i.e. the right ear's (side=+1)
		# face turns toward +X (outward) and the left ear's (side=-1) turns
		# toward -X (also outward), which is the intended direction, but
		# this specific pivot's sign hasn't been visually confirmed yet.
		# Increased 15 -> 26 degrees per a repeat direct correction ("yaw
		# them outward from each other more").
		#
		# Z (the outward ROLL confirmed above, -side*ANGLE = outward):
		# increased 11 -> 20 degrees per a further direct correction ("the
		# ears are pointed too straight up from the head, roll them outwards
		# a bit") -- same confirmed sign, just a bigger roll off vertical.
		#
		# X (pitch): per Godot's rotation-around-X formula (y'=y*cos(t)-
		# z*sin(t), z'=y*sin(t)+z*cos(t)), rotating an ear pointing local +Y
		# (straight up) by a NEGATIVE angle sends its tip toward -Z -- and
		# local -Z is "away from the snout" (see EYE_OFFSET's own "0 = local
		# +Z is the snout-tip direction" comment), i.e. backward. The
		# original -10 degrees already pitched back a little under this same
		# reading; increased to -25 per direct correction ("pitch their
		# angle back [more]").
		ear.rotation = Vector3(deg_to_rad(-25.0), side * deg_to_rad(26.0), -side * deg_to_rad(20.0))
		head_pivot.add_child(ear)


## Same SuperEgg.surface_point placement technique monkey_figure.gd's own
## _add_eyes() uses -- see that function's comment for the full derivation
## of the outward-facing basis. head is a MeshInstance3D so eyes can be
## parented directly to it and inherit head_pivot's own look-turn for free.
static func _add_eyes(head: MeshInstance3D) -> Array[MeshInstance3D]:
	var eye_radius := EYE_RADIUS
	var eyes: Array[MeshInstance3D] = []
	for side in [-1.0, 1.0]:
		var surface := SuperEgg.surface_point(HEAD_SIZE, EYE_ETA, side * EYE_OFFSET, HEAD_EPSILON, HEAD_EPSILON)
		var eye := MeshInstance3D.new()
		eye.name = "EyeL" if side < 0.0 else "EyeR"
		eye.mesh = SuperEgg.build_mesh(Vector3(eye_radius, eye_radius, eye_radius), 2.0, 2.0)
		var material := StandardMaterial3D.new()
		material.albedo_color = EYE_COLOR
		material.roughness = 0.4
		eye.set_surface_override_material(0, material)
		var horizontal_outward := Vector3(surface.x, 0.0, surface.z).normalized()
		var up := Vector3.UP
		var right := up.cross(horizontal_outward).normalized()
		eye.basis = Basis(right, up, horizontal_outward)
		eye.scale = Vector3(1.0, 1.0, EYE_FLATTEN)
		eye.position = surface - horizontal_outward * (eye_radius * (1.0 - EYE_FLATTEN) * 0.5)
		head.add_child(eye)
		eyes.append(eye)
	return eyes


## side: +1.0 = anatomical left, -1.0 = right -- matches ProceduralFigure's
## own (corrected) side convention, see the figure-rig skill's "Confirmed
## control-mapping facts" entry on ProceduralFigure's arm_left/arm_right bug.
## Four-bone chain per direct correction: shoulder (attach point, fixed to
## the body) -> HUMERUS -> elbow joint -> RADIUS -> knee (carpus) joint ->
## Cannon -> fetlock joint -> hoof bone. See this file's own class doc
## comment for the anatomical reasoning and which joints bend which way.
##
## Per a further direct correction ("keep the structure of the legs and the
## invisible nodes as the skeleton rigging, and replace the form with
## flexible pipes the same way we did for Xiao Hou Zi's arms and legs") --
## every pivot below is UNCHANGED (still the real skeleton driving
## animation), but the humerus/radius/cannon are no longer separate rigid
## SuperEgg meshes -- they're now ONE continuous flexible tube, re-lofted
## every frame from these same pivots' own live global positions by
## rebuild_limbs() (mirrors monkey_figure.gd's own build-invisible-skeleton-
## plus-one-noodle-mesh pattern exactly, see that file's own _build_arm()/
## _build_leg()/_rebuild_tube() for the reference implementation this
## follows).
##
## Per a follow-up correction ("we wanted a single form covering each leg
## fully, covering all the bone parts; not separated by leg segment") -- the
## hoof bone is now folded into that SAME tube too, as its final control
## point, rather than staying a separate rigid mesh the way a first pass had
## it (that first pass reasoned a hoof is hard keratin, not flexible flesh,
## and so shouldn't share a noodle with the fleshy bones above it -- overruled
## by this direct instruction that the WHOLE leg should read as one
## unbroken form). `fetlock` still carries FRONT_HOOF_REST_ANGLE exactly as
## before, so the hoof-tip marker below inherits that same static tilt for
## free, matching how the old rigid hoof mesh got it as fetlock's own child.
static func _build_front_leg(rig: Node3D, side: float) -> Dictionary:
	var shoulder := Node3D.new()
	shoulder.name = "HorseShoulderPivot"
	shoulder.position = Vector3(side * LEG_X, SHOULDER_Y, FRONT_LEG_Z)
	# Starting rest pose -- animate_gait()'s own per-frame code keeps this
	# pivot updated (swing layered on top of this same rest angle) once
	# moving; this just gets bone 1's angle right before the first frame.
	shoulder.rotation.x = FRONT_HUMERUS_REST_ANGLE
	rig.add_child(shoulder)

	var elbow := Node3D.new()
	elbow.name = "HorseElbowPivot"
	elbow.position = Vector3(0, -FRONT_HUMERUS_LEN, 0)
	# Fixed pose, never touched again -- see FRONT_RADIUS_REST_ANGLE's own
	# comment for why bone 2 has no dynamic gait component.
	elbow.rotation.x = FRONT_RADIUS_REST_ANGLE
	shoulder.add_child(elbow)

	var knee := Node3D.new()
	knee.name = "HorseKneePivot"
	knee.position = Vector3(0, -FRONT_RADIUS_LEN, 0)
	# Starting rest pose -- see shoulder's own comment above, same reasoning.
	knee.rotation.x = FRONT_CANNON_REST_ANGLE
	elbow.add_child(knee)

	var fetlock := Node3D.new()
	fetlock.name = "HorseFetlockPivot"
	fetlock.position = Vector3(0, -FRONT_CANNON_LEN, 0)
	# Fixed pose, never touched again -- see FRONT_HOOF_REST_ANGLE's own
	# comment for why bone 4 has no dynamic gait component.
	fetlock.rotation.x = FRONT_HOOF_REST_ANGLE
	knee.add_child(fetlock)

	# Marker only, no mesh of its own -- the hoof bone is now just the
	# tube's own final control point (see this function's own class doc).
	# Same total reach (PASTERN_LEN + HOOF_HEIGHT) the old separate rigid
	# pastern+hoof pieces spanned together.
	var hoof := Node3D.new()
	hoof.name = "HorseHoofMarker"
	hoof.position = Vector3(0, -(PASTERN_LEN + HOOF_HEIGHT), 0)
	fetlock.add_child(hoof)

	# Parented to `rig`, NOT to any pivot -- rebuild_limbs() expresses this
	# tube's own vertices in rig-local space every frame (via
	# rig.to_local(pivot.global_position)); parenting under a pivot would
	# apply that pivot's own transform a second time. Same reasoning
	# monkey_figure.gd's own _build_arm()/_build_leg() call out explicitly.
	var limb_mesh := MeshInstance3D.new()
	limb_mesh.name = "FrontLegTube"
	_apply_leg_fur_material(limb_mesh)
	rig.add_child(limb_mesh)

	return {
		"shoulder": shoulder, "elbow": elbow, "knee": knee, "fetlock": fetlock, "hoof": hoof,
		"_limb_mesh": limb_mesh,
	}


## Four-bone chain per direct correction: hip (attach point) -> FEMUR ->
## stifle joint -> TIBIA -> hock joint -> Cannon -> fetlock joint -> hoof
## bone. See this file's own class doc comment for the anatomical reasoning,
## and _build_front_leg()'s own comment for why this whole chain, hoof
## included, is now one continuous flexible tube instead of rigid meshes.
static func _build_hind_leg(rig: Node3D, side: float) -> Dictionary:
	var hip := Node3D.new()
	hip.name = "HorseHipPivot"
	hip.position = Vector3(side * LEG_X, HIP_Y, HIND_LEG_Z)
	# Starting rest pose -- see _build_front_leg()'s shoulder comment, same
	# reasoning: animate_gait() keeps swinging around this rest angle.
	hip.rotation.x = HIND_FEMUR_REST_ANGLE
	rig.add_child(hip)

	var stifle := Node3D.new()
	stifle.name = "HorseStiflePivot"
	stifle.position = Vector3(0, -HIND_FEMUR_LEN, 0)
	# Fixed pose, never touched again -- see HIND_TIBIA_REST_ANGLE's own
	# comment for why bone 2 has no dynamic gait component.
	stifle.rotation.x = HIND_TIBIA_REST_ANGLE
	hip.add_child(stifle)

	var hock := Node3D.new()
	hock.name = "HorseHockPivot"
	hock.position = Vector3(0, -HIND_TIBIA_LEN, 0)
	# Starting rest pose -- animate_gait() keeps swinging around this.
	hock.rotation.x = HIND_CANNON_REST_ANGLE
	stifle.add_child(hock)

	var fetlock := Node3D.new()
	fetlock.name = "HorseFetlockPivot"
	fetlock.position = Vector3(0, -HIND_CANNON_LEN, 0)
	# Fixed pose, never touched again -- see HIND_HOOF_REST_ANGLE's own
	# comment for why bone 4 has no dynamic gait component.
	fetlock.rotation.x = HIND_HOOF_REST_ANGLE
	hock.add_child(fetlock)

	# Marker only, no mesh of its own -- see _build_front_leg()'s own
	# identical marker for the full reasoning.
	var hoof := Node3D.new()
	hoof.name = "HorseHoofMarker"
	hoof.position = Vector3(0, -(PASTERN_LEN + HOOF_HEIGHT), 0)
	fetlock.add_child(hoof)

	var limb_mesh := MeshInstance3D.new()
	limb_mesh.name = "HindLegTube"
	_apply_leg_fur_material(limb_mesh)
	rig.add_child(limb_mesh)

	return {
		"hip": hip, "stifle": stifle, "hock": hock, "fetlock": fetlock, "hoof": hoof,
		"_limb_mesh": limb_mesh,
	}


## Re-lofts the four leg noodle tubes from their invisible skeleton pivots'
## CURRENT global positions -- must be called every frame Manchego is
## animated (see manchego.gd's own _animate_gait()), AFTER animate_gait()
## has already updated this frame's joint rotations, the same reasoning
## monkey_figure.gd's own rebuild_limbs() documents (see that file's own
## doc comment): a tube spanning multiple independently-rotating pivots has
## to be re-lofted whenever any of them move, unlike a single rigid mesh
## parented to one pivot. Also called once at the end of build() itself
## (frame 0), same as monkey_figure.gd's own build() does.
static func rebuild_limbs(pivots: Dictionary) -> void:
	var rig: Node3D = pivots["_rig"]
	var legs: Dictionary = pivots["legs"]
	# "hoof" (the marker at fetlock's own local -( PASTERN_LEN+HOOF_HEIGHT ))
	# is now included as the tube's final control point -- see
	# _build_front_leg()'s own comment for why the hoof bone folded into
	# this same single form instead of staying a separate rigid mesh. Each
	# leg type is internally consistent (see FRONT_LEG_RADIUS'/HIND_LEG_
	# RADIUS' own comment: "i just want a consistent diameter all the way
	# down the legs"), just no longer the SAME diameter as each other.
	var front_joint_keys: Array[String] = ["shoulder", "elbow", "knee", "fetlock", "hoof"]
	var front_radii: Array[float] = [
		FRONT_LEG_RADIUS, FRONT_LEG_RADIUS, FRONT_LEG_RADIUS, FRONT_LEG_RADIUS, FRONT_LEG_RADIUS,
	]
	_rebuild_leg_tube(legs["front_left"], rig, front_joint_keys, front_radii)
	_rebuild_leg_tube(legs["front_right"], rig, front_joint_keys, front_radii)
	var hind_joint_keys: Array[String] = ["hip", "stifle", "hock", "fetlock", "hoof"]
	var hind_radii: Array[float] = [
		HIND_LEG_RADIUS, HIND_LEG_RADIUS, HIND_LEG_RADIUS, HIND_LEG_RADIUS, HIND_LEG_RADIUS,
	]
	_rebuild_leg_tube(legs["hind_left"], rig, hind_joint_keys, hind_radii)
	_rebuild_leg_tube(legs["hind_right"], rig, hind_joint_keys, hind_radii)


## The live-global-position-to-local-points technique, generalized to a
## named-key leg dict instead of a flat joint array -- mirrors
## monkey_figure.gd's own _rebuild_tube() (see that function's own doc
## comment for why `rig` and not the mesh's own parent chain is the
## coordinate space this has to build in).
##
## BOTH ends get a real rounded dome cap, per direct correction ("be sure
## that the bottom of the tube is rounded, not tapered or flat" and then,
## after the bottom alone was fixed, "needs to be domed on the top as
## well") -- build_limb_tube()'s own cap_fraction parameter only ever
## produces a straight-line taper to a point (see BlorbSuit._cap_taper()),
## not a rounded dome, so this appends a few extra loft points continuing
## PAST each real end point along that end's own heading, with radius
## following a quarter-circle profile down to zero -- the exact same
## technique this file's own tail (_build_tail()/_reloft_tail()) already
## uses, reused here rather than re-derived (see that function's own
## comment for why a separate capping primitive reads as "a weird ball"
## instead of one continuous surface). cap_fraction is passed as 0.0 to
## build_limb_tube() itself so it doesn't ALSO try to taper these
## manually-computed points. The shoulder/hip end is buried inside the
## torso and never visible either way, but domes it too now for the same
## real reason the hoof end needed it: not just visibility, geometric
## correctness at every open end of the tube.
static func _rebuild_leg_tube(leg: Dictionary, rig: Node3D, joint_keys: Array[String], input_radii: Array[float]) -> void:
	var points: Array[Vector3] = []
	for key in joint_keys:
		var joint: Node3D = leg[key]
		points.append(rig.to_local(joint.global_position))

	# Duplicated, NOT mutated in place -- rebuild_limbs() passes the exact
	# same front_radii/hind_radii array object into both the left and right
	# call for a given leg type, so inserting directly into the parameter
	# would splice a second point into it on the first (e.g. front_left)
	# call, then splice ANOTHER, wrongly-indexed one in on the very next
	# (front_right) call reusing that now-already-mutated array.
	# Explicit Array[float] type, not := -- Array.duplicate()'s own return
	# type is plain untyped Array, so := here would silently lose the
	# element type and break inference on every `radii[i]` read below.
	var radii: Array[float] = input_radii.duplicate()

	# Extra control point, exactly halfway along the straight fetlock->hoof
	# segment -- COLINEAR with the two real joints either side of it, so it
	# doesn't bend the tube's own geometry at all (Catmull-Rom through three
	# colinear points is still a straight line there); it exists purely so
	# _rebuild_leg_tube()'s own SOCK_COLOR cut (below) has a place to land
	# mid-segment. Per direct correction ("you overadjusted where the brown
	# hoof color should begin... split the difference") -- the cut had
	# jumped from the hoof joint itself (too low, per an earlier report) all
	# the way up to the fetlock joint (too high, per this one); this splits
	# it to land exactly between those two.
	var split_index := points.size() - 1
	points.insert(split_index, points[split_index - 1].lerp(points[split_index], 0.5))
	radii.insert(split_index, lerpf(radii[split_index - 1], radii[split_index], 0.5))

	var top_dome_points: Array[Vector3] = []
	var top_dome_radii: Array[float] = []
	var base := points[0]
	var base_heading := (base - points[1]).normalized()
	var base_radius := radii[0]
	# Descending step order builds this list already in far-to-near order
	# (zero-radius tip first, growing toward base_radius just short of the
	# real base point), ready to prepend as-is.
	for step in range(LEG_HOOF_DOME_STEPS, 0, -1):
		var top_theta := (float(step) / LEG_HOOF_DOME_STEPS) * (PI * 0.5)
		top_dome_points.append(base + base_heading * (base_radius * sin(top_theta)))
		top_dome_radii.append(base_radius * cos(top_theta))

	var tip := points[points.size() - 1]
	var tip_heading := (tip - points[points.size() - 2]).normalized()
	var tip_radius := radii[radii.size() - 1]
	var bottom_dome_points: Array[Vector3] = []
	var bottom_dome_radii: Array[float] = []
	for step in range(1, LEG_HOOF_DOME_STEPS + 1):
		var bottom_theta := (float(step) / LEG_HOOF_DOME_STEPS) * (PI * 0.5)
		bottom_dome_points.append(tip + tip_heading * (tip_radius * sin(bottom_theta)))
		bottom_dome_radii.append(tip_radius * cos(bottom_theta))

	var domed_points := top_dome_points + points + bottom_dome_points
	var domed_radii := top_dome_radii + radii + bottom_dome_radii

	# LEG_SOCK_COLOR region -- see that const's own comment. build_limb_tube()
	# colors each ring FLATLY by its own enclosing segment's start point (no
	# lerp, per direct correction -- see that function's own comment), so
	# the cut lands exactly at whichever of `points` FIRST turns SOCK-colored
	# below. `points` now has the extra split_index midpoint spliced in
	# (see this function's own comment above) between fetlock and hoof, so
	# "last 2 of points" below means [split point, hoof] -- the fetlock->
	# split-point half of that old segment stays COAT (fetlock is its own
	# start point), and only the split-point->hoof half turns SOCK, landing
	# the cut halfway up the fetlock->hoof span instead of at either end.
	var top_dome_colors: Array[Color] = []
	top_dome_colors.resize(top_dome_points.size())
	top_dome_colors.fill(COAT_COLOR)
	var point_colors: Array[Color] = []
	for i in points.size():
		point_colors.append(LEG_SOCK_COLOR if i >= points.size() - 2 else COAT_COLOR)
	var bottom_dome_colors: Array[Color] = []
	bottom_dome_colors.resize(bottom_dome_points.size())
	bottom_dome_colors.fill(LEG_SOCK_COLOR)
	var domed_colors := top_dome_colors + point_colors + bottom_dome_colors

	var mesh_instance: MeshInstance3D = leg["_limb_mesh"]
	mesh_instance.mesh = BlorbSuit.build_limb_tube(
		domed_points, domed_radii, LIMB_RADIAL_SEGMENTS, LIMB_RINGS_PER_SEGMENT, 0.0, domed_colors
	)


## How much of the sway/flit yaw bend reaches a given point along the tail,
## weighted by (t^exponent) where t=0 at the anchor (embedded in the body,
## should never visibly move) and t=1 at the tip (should swing the most) --
## same weighting IDEA monkey_figure.gd's own tail uses (see this function's
## own class-level reference below), reused here because it's the right
## shape for "anchored at one end, free at the other," not because the two
## tails share an implementation.
const TAIL_SWAY_BEND_EXPONENT := 1.6
## Continuous, gentle side-to-side swing -- simple accumulating phase, NOT
## monkey_figure.gd's own randomized dual-axis retarget system (per direct
## instruction, "reference the monkey's tail for how we're doing it... but
## this horse tail should have its own unique behaviour"). A steady sine
## wave reads as an idle swish; the FLIT constants below layer a separate,
## occasional, sharper event on top for character.
const TAIL_SWAY_SPEED := 1.1
const TAIL_SWAY_AMOUNT := deg_to_rad(9.0)
## Occasional single flick to one side and back to resting -- distinct from
## the continuous sway above (per direct instruction, "an occasional flit to
## one side and back to resting"). Triggers on a randomized interval, holds
## a wider single-direction bend for TAIL_FLIT_DURATION using an ease-out-
## then-ease-back curve, then goes quiet again until the next random
## interval elapses.
const TAIL_FLIT_INTERVAL_MIN := 3.0
const TAIL_FLIT_INTERVAL_MAX := 8.0
const TAIL_FLIT_DURATION := 0.55
const TAIL_FLIT_AMOUNT := deg_to_rad(24.0)


## The rounded-tip "dome cap" trick (a few extra loft points tapering radius
## toward zero along the tail's own last heading) is copied directly from
## monkey_figure.gd's _rebuild_tail(), which explicitly notes a separate
## capping sphere read as "a weird ball" -- reusing that already-solved
## technique here instead of re-discovering the same problem. Per direct
## correction, the radii now GROW toward the tip instead of tapering down --
## the dome-cap loop still works exactly the same either way, since it only
## ever rounds off whatever the last real radius happens to be into a closed
## dome, so a wide final radius just produces a rounded, flared end instead
## of a tapered one.
##
## Returns a state Dictionary (mesh/base_points/radii/sway+flit timers)
## instead of a bare MeshInstance3D now, so animate_tail() below can re-loft
## it every frame -- mirrors monkey_figure.gd's own build-returns-state,
## animate-consumes-state split for its tail, per direct instruction to use
## that as a reference point.
static func _build_tail(spine_pivot: Node3D) -> Dictionary:
	# Higher up the haunch, per direct correction ("it should start a bit
	# higher up on his butt") -- was 0.25. Pulled forward (less negative Z)
	# per a later direct correction ("you can pull the tail forward into the
	# body a bit") -- was 0.95. Shifted back again by TORSO_HAUNCH_EXTEND per
	# a further direct correction ("the back (butt) extend back about 8cm
	# along with the position of the tail") -- moves the tail's own anchor
	# back by the same amount the haunch's actual surface now extends, so it
	# still starts right at the (now further-back) haunch instead of ending
	# up buried inside the body or floating short of its new surface.
	var anchor := Vector3(0, TORSO_HALF_HEIGHT * 0.6, -TORSO_HALF_LENGTH * 0.85 - TORSO_HAUNCH_EXTEND)
	# Scaled in ~20% from the first draft, per direct correction ("his tail
	# can be a bit shorter").
	var base_points: Array[Vector3] = [
		anchor,
		anchor + Vector3(0, -0.04, -0.14),
		anchor + Vector3(0, -0.24, -0.24),
		anchor + Vector3(0, -0.50, -0.27),
	]
	# Growing, not tapering, per direct correction ("should not taper toward
	# the end, it should be wider at the end actually than the start").
	var radii: Array[float] = [
		TAIL_BASE_RADIUS * 0.5, TAIL_BASE_RADIUS * 0.7, TAIL_BASE_RADIUS * 0.95, TAIL_BASE_RADIUS * 1.3,
	]

	var tail := MeshInstance3D.new()
	tail.name = "Tail"
	# Same color as the mane now, per direct correction -- MANE_COLOR, not a
	# separate TAIL_COLOR (removed). Uses the same _apply_fur_material() fix
	# as the mane now -- see that function's own comment for why (the actual
	# "blorb gel" bug, not just a defensive re-statement of properties this
	# already had).
	_apply_fur_material(tail, MANE_COLOR)
	spine_pivot.add_child(tail)

	var state := {
		"mesh": tail,
		"base_points": base_points,
		"radii": radii,
		"sway_phase": randf_range(0.0, TAU),
		"flit_timer": randf_range(TAIL_FLIT_INTERVAL_MIN, TAIL_FLIT_INTERVAL_MAX),
		"flit_elapsed": -1.0,
		"flit_side": 1.0,
	}
	_reloft_tail(state, 0.0)
	return state


## Called every frame (see manchego.gd's own _process()/drive_from_player())
## to keep the tail's idle sway/flit alive -- mirrors monkey_figure.gd's own
## build-returns-state/animate-consumes-state split for its tail, per direct
## instruction to use that as a reference point for STRUCTURE, not behavior
## (this tail's actual motion -- one continuous sway plus a separate,
## occasional single flick -- is deliberately its own thing, per direct
## instruction: "this horse tail should have its own unique behaviour").
static func animate_tail(state: Dictionary, delta: float) -> void:
	state["sway_phase"] = (state["sway_phase"] as float) + delta * TAIL_SWAY_SPEED
	var sway := sin(state["sway_phase"] as float) * TAIL_SWAY_AMOUNT

	state["flit_timer"] = (state["flit_timer"] as float) - delta
	if (state["flit_elapsed"] as float) >= 0.0:
		state["flit_elapsed"] = (state["flit_elapsed"] as float) + delta
		if (state["flit_elapsed"] as float) >= TAIL_FLIT_DURATION:
			state["flit_elapsed"] = -1.0
	elif (state["flit_timer"] as float) <= 0.0:
		state["flit_elapsed"] = 0.0
		state["flit_side"] = 1.0 if randf() < 0.5 else -1.0
		state["flit_timer"] = randf_range(TAIL_FLIT_INTERVAL_MIN, TAIL_FLIT_INTERVAL_MAX)

	var flit := 0.0
	if (state["flit_elapsed"] as float) >= 0.0:
		# A single smooth 0 -> peak -> 0 hump across the flit's own
		# duration -- quick out, quick back, one clean flick rather than a
		# springy oscillation.
		var t := clampf((state["flit_elapsed"] as float) / TAIL_FLIT_DURATION, 0.0, 1.0)
		flit = sin(PI * t) * TAIL_FLIT_AMOUNT * (state["flit_side"] as float)

	_reloft_tail(state, sway + flit)


## Shared by _build_tail() (yaw=0, the rest pose) and animate_tail() (yaw=
## the current combined sway+flit angle) -- bends base_points around the
## anchor (point 0, which never moves) by yaw*weight, weight growing from 0
## at the anchor to 1 at the tip via TAIL_SWAY_BEND_EXPONENT, then re-lofts
## the mesh including the same rounded dome-cap extension _build_tail()
## used to build fresh (see that function's own comment on why a separate
## capping primitive isn't used).
static func _reloft_tail(state: Dictionary, yaw: float) -> void:
	var base_points: Array[Vector3] = state["base_points"]
	var radii: Array[float] = state["radii"]
	var anchor: Vector3 = base_points[0]
	var last_index := base_points.size() - 1
	var points: Array[Vector3] = []
	for i in base_points.size():
		var weight := pow(float(i) / float(last_index), TAIL_SWAY_BEND_EXPONENT)
		var rot := Basis(Vector3.UP, yaw * weight)
		points.append(anchor + rot * (base_points[i] - anchor))
	var bent_radii: Array[float] = radii.duplicate()

	var tip := points[points.size() - 1]
	var heading := (tip - points[points.size() - 2]).normalized()
	var tip_radius := bent_radii[bent_radii.size() - 1]
	for step in range(1, TAIL_DOME_STEPS + 1):
		var theta := (float(step) / TAIL_DOME_STEPS) * (PI * 0.5)
		points.append(tip + heading * (tip_radius * sin(theta)))
		bent_radii.append(tip_radius * cos(theta))

	var mesh_instance: MeshInstance3D = state["mesh"]
	mesh_instance.mesh = BlorbSuit.build_limb_tube(points, bent_radii, LIMB_RADIAL_SEGMENTS, LIMB_RINGS_PER_SEGMENT, 0.0)


## Per-frame gait. Per direct correction ("the front legs and the back legs
## gait should not be happening in the same cycle... offset the two cycles
## by half"): the previous version was a 2-beat DIAGONAL TROT -- front-left
## shared front-right's exact opposite phase (correct, unchanged: still PI
## apart, below), and separately hind-left/hind-right were also PI apart,
## but the HIND pair's own two phase values {phase, phase+PI} were exactly
## the same SET front's own two values used, just cross-assigned left/right
## -- so a diagonal partner (front-left & hind-right) always shared the
## EXACT same phase, moving in perfect lockstep. That's what read as "the
## same cycle." Now the whole HIND group is shifted by half of the existing
## front-to-front gap (PI * 0.5) relative to front, giving a real 4-beat
## walk sequence -- hind-left(0) -> front-left(90) -> hind-right(180) ->
## front-right(270) -- where NO front leg ever shares a phase with any hind
## leg. Front-left/front-right and hind-left/hind-right each keep their own
## existing PI (half-cycle) internal spacing, unchanged.
## running is optional (default false, every pre-existing call site
## unaffected) -- per direct correction, see RUN_BEND_MULTIPLIER's own
## comment for the full reasoning; just threaded through to each leg here.
static func animate_gait(pivots: Dictionary, delta: float, moving: bool, phase: float, running: bool = false) -> void:
	var legs: Dictionary = pivots["legs"]
	_animate_front_leg(legs["front_left"], delta, moving, phase + PI * 0.5, running)
	_animate_front_leg(legs["front_right"], delta, moving, phase + PI * 1.5, running)
	_animate_hind_leg(legs["hind_left"], delta, moving, phase, running)
	_animate_hind_leg(legs["hind_right"], delta, moving, phase + PI, running)
	_ease_body_height_to_rest(pivots["spine"], delta)


const LEG_SETTLE_SPEED := 8.0


## Airborne jump tuck -- see JUMP_SHOULDER_TUCK's own comment for the full
## reasoning. apex_fraction is 0 at takeoff/landing and 1 at the jump's
## apex; manchego.gd computes it every frame from its own vertical velocity
## (mirroring player.gd's own _animate_airborne()) and passes it straight
## through here. All four legs tuck together -- no gait phase offset.
static func animate_airborne(pivots: Dictionary, delta: float, apex_fraction: float) -> void:
	var legs: Dictionary = pivots["legs"]
	_apply_front_tuck(legs["front_left"], delta, apex_fraction)
	_apply_front_tuck(legs["front_right"], delta, apex_fraction)
	_apply_hind_tuck(legs["hind_left"], delta, apex_fraction)
	_apply_hind_tuck(legs["hind_right"], delta, apex_fraction)
	# No body-height dip mid-flight -- only the landing impact itself dips
	# the body (see animate_landing()) -- this just cleans up any dip still
	# decaying from a landing that happened right before takeoff again (a
	# quick re-jump), same reasoning player.gd's own _apply_airborne_pose()
	# gives for its identical no-op-unless-already-displaced spine/hips ease.
	_ease_body_height_to_rest(pivots["spine"], delta)


static func _apply_front_tuck(leg: Dictionary, delta: float, apex_fraction: float) -> void:
	var shoulder: Node3D = leg["shoulder"]
	var knee: Node3D = leg["knee"]
	var t := JUMP_POSE_SETTLE_SPEED * delta
	# CORRECTED per direct correction ("the bend in the legs should also
	# include a forward bend at the upper end of the forelegs") -- was
	# `+ apex_fraction * JUMP_SHOULDER_TUCK` (backward, same direction as
	# FRONT_HUMERUS_REST_ANGLE's own "angle back" rest bias), now negated to
	# a forward bend instead, reusing the same "negative rotation.x =
	# forward" sign FRONT_RADIUS_REST_ANGLE's own comment already
	# establishes for this exact pivot chain. Matches real jump biomechanics
	# too: the humerus rotates forward to bring the knee up and forward
	# toward the chest, not backward.
	shoulder.rotation.x = lerp_angle(shoulder.rotation.x, FRONT_HUMERUS_REST_ANGLE - apex_fraction * JUMP_SHOULDER_TUCK, t)
	knee.rotation.x = lerp_angle(knee.rotation.x, FRONT_CANNON_REST_ANGLE + apex_fraction * JUMP_KNEE_TUCK, t)


static func _apply_hind_tuck(leg: Dictionary, delta: float, apex_fraction: float) -> void:
	var hip: Node3D = leg["hip"]
	var hock: Node3D = leg["hock"]
	var t := JUMP_POSE_SETTLE_SPEED * delta
	hip.rotation.x = lerp_angle(hip.rotation.x, HIND_FEMUR_REST_ANGLE - apex_fraction * JUMP_HIP_TUCK, t)
	hock.rotation.x = lerp_angle(hock.rotation.x, HIND_CANNON_REST_ANGLE + apex_fraction * JUMP_HOCK_TUCK, t)


## Landing impact -- see LANDING_SHOULDER_BEND's own comment. Caller (see
## manchego.gd's own _landing_timer) holds this for a brief fixed duration
## right after touchdown, then resumes animate_gait()/rest as normal; this
## function itself has no notion of "how long," it just eases every joint
## toward the fixed landing-bend target each frame it's called.
static func animate_landing(pivots: Dictionary, delta: float) -> void:
	var legs: Dictionary = pivots["legs"]
	var t := LANDING_SETTLE_SPEED * delta
	for key in ["front_left", "front_right"]:
		var leg: Dictionary = legs[key]
		var shoulder: Node3D = leg["shoulder"]
		var knee: Node3D = leg["knee"]
		shoulder.rotation.x = lerp_angle(shoulder.rotation.x, FRONT_HUMERUS_REST_ANGLE + LANDING_SHOULDER_BEND, t)
		knee.rotation.x = lerp_angle(knee.rotation.x, FRONT_CANNON_REST_ANGLE + LANDING_KNEE_BEND, t)
	for key in ["hind_left", "hind_right"]:
		var leg: Dictionary = legs[key]
		var hip: Node3D = leg["hip"]
		var hock: Node3D = leg["hock"]
		hip.rotation.x = lerp_angle(hip.rotation.x, HIND_FEMUR_REST_ANGLE - LANDING_HIP_BEND, t)
		hock.rotation.x = lerp_angle(hock.rotation.x, HIND_CANNON_REST_ANGLE + LANDING_HOCK_BEND, t)
	var spine_pivot: Node3D = pivots["spine"]
	spine_pivot.position.y = lerp(spine_pivot.position.y, (HIP_Y - SPINE_DROP_FROM_HIP) - LANDING_BODY_DIP_AMOUNT, t)


## Shared by animate_gait()/animate_airborne() -- eases spine_pivot (and
## everything hanging off it: torso/neck/head/tail) back up to its own
## resting height, recovering from whatever dip animate_landing() left
## behind. A no-op once already at rest, so calling this unconditionally
## every frame from both functions is harmless.
static func _ease_body_height_to_rest(spine_pivot: Node3D, delta: float) -> void:
	spine_pivot.position.y = lerp(spine_pivot.position.y, HIP_Y - SPINE_DROP_FROM_HIP, LEG_SETTLE_SPEED * delta)


## elbow/fetlock are deliberately NOT touched here -- both are fixed poses
## baked once in _build_front_leg() (see FRONT_RADIUS_REST_ANGLE's and
## FRONT_HOOF_REST_ANGLE's own comments for why bones 2 and 4 have no
## dynamic gait component). Only bone 1 (shoulder) and bone 3 (knee) animate,
## each swinging/flexing around its own REST_ANGLE rather than around zero.
static func _animate_front_leg(leg: Dictionary, delta: float, moving: bool, phase: float, running: bool = false) -> void:
	var shoulder: Node3D = leg["shoulder"]
	var knee: Node3D = leg["knee"]
	if moving:
		var bend_scale := RUN_BEND_MULTIPLIER if running else 1.0
		var swing := sin(phase)
		# UNVERIFIED GUESS sign (see class doc/const comments above): negative
		# rotation.x = forward under this rig's inherited base convention, so
		# multiplying by -1 makes a positive `swing` move the leg forward.
		# Swings around FRONT_HUMERUS_REST_ANGLE, not zero. ASYMMETRIC per
		# direct correction -- see FRONT_STRIDE_FORWARD_AMOUNT's own comment.
		var front_swing_amount := FRONT_STRIDE_FORWARD_AMOUNT if swing > 0.0 else FRONT_STRIDE_BACKWARD_AMOUNT
		shoulder.rotation.x = FRONT_HUMERUS_REST_ANGLE - swing * front_swing_amount * bend_scale
		var lift := maxf(swing, 0.0)
		# See FRONT_CANNON_REST_ANGLE's own comment for why this dynamic term
		# is POSITIVE (backward) now, reversed from this rig's earlier
		# "flexes forward" finding -- flexes around FRONT_CANNON_REST_ANGLE.
		knee.rotation.x = FRONT_CANNON_REST_ANGLE + lift * KNEE_FLEX_AMOUNT * bend_scale
	else:
		shoulder.rotation.x = lerp_angle(shoulder.rotation.x, FRONT_HUMERUS_REST_ANGLE, LEG_SETTLE_SPEED * delta)
		knee.rotation.x = lerp_angle(knee.rotation.x, FRONT_CANNON_REST_ANGLE, LEG_SETTLE_SPEED * delta)


## stifle/fetlock are deliberately NOT touched here -- both are fixed poses
## baked once in _build_hind_leg() (see HIND_TIBIA_REST_ANGLE's and
## HIND_HOOF_REST_ANGLE's own comments). Only bone 1 (hip) and bone 3 (hock)
## animate, each around its own REST_ANGLE rather than around zero.
static func _animate_hind_leg(leg: Dictionary, delta: float, moving: bool, phase: float, running: bool = false) -> void:
	var hip: Node3D = leg["hip"]
	var hock: Node3D = leg["hock"]
	if moving:
		var bend_scale := RUN_BEND_MULTIPLIER if running else 1.0
		var swing := sin(phase)
		# ASYMMETRIC per direct correction -- see HIND_STRIDE_BACKWARD_AMOUNT's
		# own comment ("the swing of the hind legs is swinging way too far
		# back... cap the backwards swing").
		var hind_swing_amount := HIND_STRIDE_FORWARD_AMOUNT if swing > 0.0 else HIND_STRIDE_BACKWARD_AMOUNT
		hip.rotation.x = HIND_FEMUR_REST_ANGLE - swing * hind_swing_amount * bend_scale
		var lift := maxf(swing, 0.0)
		# Confirmed backwards by earlier direct report ("the knees of his
		# back legs should angle back not forward") -- POSITIVE (backward),
		# now flexing around HIND_CANNON_REST_ANGLE instead of zero.
		hock.rotation.x = HIND_CANNON_REST_ANGLE + lift * HOCK_FLEX_AMOUNT * bend_scale
	else:
		hip.rotation.x = lerp_angle(hip.rotation.x, HIND_FEMUR_REST_ANGLE, LEG_SETTLE_SPEED * delta)
		hock.rotation.x = lerp_angle(hock.rotation.x, HIND_CANNON_REST_ANGLE, LEG_SETTLE_SPEED * delta)
