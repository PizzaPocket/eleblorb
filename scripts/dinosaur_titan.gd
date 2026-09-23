class_name DinosaurTitan
extends StaticBody3D

## A living, platformable titan body -- refined from the first rudimentary
## prototype into a quadruped with a real leg rig, a single tapering tail
## pipe, and a proper eyed skull sitting on a long muzzle. Kept on the
## fossil's original scale; articulated motion grows from this rig without
## changing the resurrection API.

## Electric lime -- one consistent body color everywhere (no separate skin/
## belly tones). Only the eyes and eyelids read as separate markings, same
## as every other creature in the game.
## How large this titan stands, wherever it appears. The demo world used to
## set a scale of its own while its own kingdom built one at 1.0, so the same
## creature was two different sizes depending on where you met it. Raised by
## half again per direct instruction, to stand alongside Humongous.
const DISPLAY_SCALE := 3.0

const BODY_COLOR := Color(0.68, 1.0, 0.05)
const BODY_EPSILON_TOP := 2.5
const BODY_EPSILON_BOTTOM := 2.8

const TORSO_HALF := Vector3(8.5, 4.3, 4.0)
## Per direct correction ("body is floating way up above the legs... come
## way down so the tops of the legs are embedded in the body") -- the old
## value placed the torso's own bottom surface EXACTLY at LEG_HEIGHT (a
## tangent touch, not an overlap). BODY_LEG_EMBED below is how far the torso
## now drops PAST that point, so LEG_HEIGHT (where each hip pivot actually
## sits) lands inside the torso's own vertical span instead of right at its
## edge. SKULL_POS/SNOUT_POS/TAIL_BASE all shift down by this same amount
## (see each's own comment) to stay in the same place relative to the torso.
const BODY_LEG_EMBED := 1.5
const TORSO_POS := Vector3(-7.0, 8.3 - BODY_LEG_EMBED, 0.0)

## Pulled back further and raised further per direct correction -- its own
## back edge (SNOUT_POS.x + SNOUT_HALF.x = -13.0) now overlaps well past the
## torso's own front edge (TORSO_POS.x - TORSO_HALF.x = -15.5), a firm
## "butts into the body" connection rather than a light touch. Y dropped by
## BODY_LEG_EMBED along with TORSO_POS (see that const's own comment).
const SNOUT_HALF := Vector3(5.0, 3.2, 2.6)
const SNOUT_POS := Vector3(-18.0, 8.5 - BODY_LEG_EMBED, 0.0)

## "Face segment" -- 30% smaller again per an earlier direct correction,
## sitting up behind/above the muzzle's own rear-top. Per a later direct
## correction ("face segment needs to sink down halfway into his muzzle
## segment"), Y is now pinned so exactly half of the skull's own height sits
## below the snout's flat (pre-taper) top-surface estimate (SNOUT_POS.y +
## SNOUT_HALF.y) and half pokes up above it, rather than clearing that line
## entirely -- a literal "sinks halfway into" embed. Computed by hand (not a
## const expression) since SNOUT_POS/SNOUT_HALF are declared above already
## drop by BODY_LEG_EMBED: (8.5 - 1.5) + 3.2 - 1.4*0.5 = 9.5.
const SKULL_HALF := Vector3(1.5, 1.4, 1.4)
const SKULL_POS := Vector3(-14.5, 9.5, 0.0)

## Eyes + eyelids copied from ocean_kingdom_denizens.gd's own
## _add_kraken_eyes() -- same relative proportions and the same eye-to-lid
## offset, just uniformly rescaled to fit this skull and re-expressed
## directly in this body's own axes (forward is -X here, not the Kraken's
## +Z) rather than needing a per-eye surface-gradient computation, since
## both the skull and the Kraken's own eye placement are fixed local
## offsets on a rigid part, not swept surfaces.
##
## Kraken's own eye semi_axes (0.82, 1.05, 0.34) [right, up, forward] and
## lid semi_axes (1.02, 0.55, 0.42), lid offset from eye (0, +0.9, +0.13)
## [right, up, forward], scaled by EYE_SCALE and remapped so this body's
## forward (-X) takes the "forward" slot: mine = (kraken.forward,
## kraken.up, kraken.right) with the offset's forward component negated
## (this body's forward is -X, not +X).
const EYE_SCALE := 0.5
const EYE_SEMI_AXES := Vector3(0.34, 1.05, 0.82) * EYE_SCALE
const EYE_COLOR_DARKEN := 0.42
## Shrunk 25% per direct correction ("reduce the size of the lids a bit") --
## they were reading as burying the eyes rather than framing them.
const LID_SEMI_AXES := Vector3(0.42, 0.55, 1.02) * EYE_SCALE * 0.75
const LID_OFFSET_FROM_EYE := Vector3(-0.13, 0.9, 0.0) * EYE_SCALE
## Local offset from SKULL_POS to the left eye's own center; the right eye
## mirrors this in Z. Forward (-X) and up, near the skull's own front-top,
## clear of the muzzle's top surface below it. Z widened (0.55 -> 0.95,
## still inside SKULL_HALF.z's own 1.4 half-width) per direct correction
## ("eyes are not splayed enough and are as a result mostly buried in the
## face").
const EYE_OFFSET_FROM_SKULL := Vector3(-1.1, 0.5, -0.95)

## Per direct correction, one stubby segment each (think Pandy's own single
## short leg part), not the earlier two-segment hip/knee chain. Hind legs
## are thicker than front; only hind legs get feet.
const HIND_LEG_HALF := Vector3(1.6, 2.35, 1.6)
const FRONT_LEG_HALF := Vector3(1.2, 2.5, 1.2)
const FOOT_HALF := Vector3(1.4, 0.55, 1.1)
const FOOT_OFFSET := Vector3(-0.3, -0.5, 0.0)
## The lower hind-leg end intentionally enters the foot instead of merely
## touching its crown. This makes the two procedural volumes read as one
## articulated limb with no daylight at the joint.
const HIND_LEG_FOOT_OVERLAP := 0.35
## Front legs end directly at the ground datum. Hind legs carry feet below
## their leg segments, so their hips need a separate, higher pivot. Derive
## that height from the actual foot geometry: the foot's lowest point lands
## exactly at y=0 without moving the torso or the Dinosaur root.
const FRONT_HIP_HEIGHT := FRONT_LEG_HALF.y * 2.0
const HIND_HIP_HEIGHT := (
	HIND_LEG_HALF.y * 2.0 - FOOT_OFFSET.y - HIND_LEG_FOOT_OVERLAP + FOOT_HALF.y
)

const HIP_X := -1.0
## This body faces -X and its tail extends toward +X. Moving the front-leg
## roots toward +X seats them farther inside the torso instead of leaving
## them tangent to its rounded forward shoulder.
const SHOULDER_X := -12.0
const LEG_SIDE_Z := 3.2

## Per direct correction, forward/backward swing, not an outward hinge --
## this body faces -X (see SNOUT_POS vs TORSO_POS), and rotating around a
## pivot's local X axis swings within the Y-Z plane (sideways relative to
## -X), not the X-Y plane a forward/back stride actually needs. Pandy's own
## identical leg-swing code correctly uses rotation.x because Pandy's own
## face (and forward) is authored toward Z, not X -- see pandy.gd's own
## comment on that. rotation.z is this body's equivalent, since it swings
## within the X-Y plane.
const LEG_SWING_SPEED := 2.2
const LEG_SWING_AMPLITUDE := deg_to_rad(26.0)
## Per direct correction ("proper walk animation and rest state... really
## give consideration to his realistic leg movement cycle and timing, like
## we did for manchego.gd") -- swing only runs while actually walking
## toward a wander target (see _physics_process()); while standing, each leg
## eases back toward this rest pose instead of holding wherever the sine
## last left it, avoiding a hitch when the gait starts/stops.
const LEG_REST_SETTLE_SPEED := 6.0

## ---- Wander AI ---- Per direct correction ("movement right now seems to
## be only pivoting, rotating in a circle... he should change direction as
## he likes when walking, just like another NPC") -- the old code walked a
## perfect circle at a fixed radius, so translation and rotation were always
## the same fixed shape rather than the creature actually choosing to walk
## somewhere and turning to face it. Rebuilt as the same pick-a-nearby-point-
## and-pause wander shape manchego.gd's own _update_idle() uses, anchored on
## his own resting spot (local origin, i.e. wherever DinosaurFossil placed
## him) instead of chasing the player. First-draft magnitudes, unverified in
## engine like every other unspecified number in this rig -- a much heavier,
## slower gait than Manchego's own since this is a titan, not a horse.
const WANDER_RADIUS := 10.0
const WANDER_MOVE_SPEED := 1.3
const WANDER_ARRIVE_DISTANCE := 0.4
const WANDER_PAUSE_MIN := 3.0
const WANDER_PAUSE_MAX := 8.0
## A titan turns deliberately rather than snapping toward every new wander
## point. Rotation is applied around TURN_PIVOT_LOCAL below, not this scene
## root (which sits near the rear legs for historical fossil placement).
const WANDER_ROTATION_SPEED := 0.45
const TURN_PIVOT_LOCAL := Vector3(TORSO_POS.x, 0.0, TORSO_POS.z)

## One continuous swept pipe -- not a SuperEgg and not a chain of visible
## segments. It begins by descending 38 degrees, gently levels toward its
## end, and tapers from the moment it leaves the body. The final short span
## is a hemispherical cap: axial position follows sin() while radius follows
## cos(), producing a plainly rounded end rather than either a sharp point
## or a bulb.
## Y dropped by BODY_LEG_EMBED along with TORSO_POS (see that const's own
## comment) to stay in the same place relative to the now-lower body.
const TAIL_BASE := Vector3(-4.0, 9.5 - BODY_LEG_EMBED, 0.0)
## Fifteen percent shorter than the preceding 11-unit pass.
const TAIL_LENGTH := 9.35
## Thirty percent wider at the root than the preceding 1.3-unit pass. The
## radius still begins decreasing immediately in _tail_radius().
const TAIL_BASE_RADIUS := 1.69
const TAIL_BASE_DOWN_ANGLE := deg_to_rad(38.0)
const TAIL_ROUND_START_T := 0.9
const TAIL_CAP_RADIUS := 0.22
const TAIL_WAG := 0.8
const TAIL_RING_COUNT := 32
const TAIL_RADIAL_SEGMENTS := 14

## 8 flattened SuperEggs, sharper (boxier) than the body proper so they
## read as distinct angular ridges. Per direct correction, X and Y (not Y
## and Z) are the matched pair rolled 45 degrees around Z: this puts the
## diamond itself in the X-Y plane, so it's clearly visible from the side
## (running down the back) with a corner pointing straight up, rather than
## the diamond sitting in the Y-Z plane (only visible face-on from directly
## ahead or behind, reading as thin sideways slivers from everywhere else).
## Z is the genuinely thin dimension now (left-right).
const SPINE_EPSILON := 5.5
const SPINE_COUNT := 8
const SPINE_ROW_START_X := -12.5
## Extended to TAIL_BASE.x's own -4.0 (was -4.5, stopping short) per direct
## correction ("spines are not running the full length of his back, can they
## continue all the way to the base of his tail").
const SPINE_ROW_END_X := -4.0
const SPINE_HALF := Vector3(0.75, 0.9, 0.22)
## Approximates the torso's own top surface height (a flattish plateau,
## given BODY_EPSILON_TOP's moderate boxiness) across the row's X range --
## good enough for a decorative row, not exact per-vertex surface sampling.
## Centering each spine exactly here, rather than fully above it, is the
## "inset halfway into his actual back" per direct correction: half of the
## diamond's own vertical corner-to-corner reach sinks below this line into
## the torso, half rises above it.
const SPINE_SURFACE_Y := TORSO_POS.y + TORSO_HALF.y * 0.9

var _leg_phase := 0.0
## Ambient wander state -- see the WANDER_* consts' own comment. _wander_anchor
## is captured once in _ready() (his resting spot) rather than always "wherever
## he currently is," so a long run of wander cycles can't slowly drift him away
## from the fossil site the way re-anchoring every pause would.
var _rng := RandomNumberGenerator.new()
var _wander_anchor := Vector3.ZERO
var _wander_target := Vector3.ZERO
var _has_wander_target := false
var _wander_pause_timer := 0.0
## {"collider": CollisionShape3D, "mesh": MeshInstance3D} -- these track an
## animated pivot, so their local position/basis has to be resynced from
## the mesh's current global transform every physics frame (this body is a
## StaticBody3D; a moving StaticBody3D collider needs its transform driven
## by hand -- AnimatableBody3D was tried and abandoned elsewhere in this
## project for exactly this kind of script-driven movement).
var _animated_colliders: Array[Dictionary] = []


func _ready() -> void:
	scale = Vector3.ONE * DISPLAY_SCALE
	_rng.randomize()
	_wander_anchor = _turn_pivot_parent_position()
	collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
	_build_torso()
	_build_head()
	_build_eyes()
	_build_spines()
	_build_tail()
	for side in [-1.0, 1.0]:
		_build_leg(Vector3(HIP_X, 0.0, side * LEG_SIDE_Z), HIND_LEG_HALF, true, "Hind")
		_build_leg(Vector3(SHOULDER_X, 0.0, side * LEG_SIDE_Z), FRONT_LEG_HALF, false, "Front")


func _physics_process(delta: float) -> void:
	var moving := _update_wander(delta)
	_animate_gait(delta, moving)

	for entry in _animated_colliders:
		var collider := entry["collider"] as CollisionShape3D
		var mesh := entry["mesh"] as MeshInstance3D
		var local_xform := global_transform.affine_inverse() * mesh.global_transform
		collider.position = local_xform.origin
		collider.basis = local_xform.basis


## Picks a nearby point around _wander_anchor, walks to it, pauses, then
## picks another -- same shape as manchego.gd's own _update_idle(), just
## rooted on this titan's own resting spot instead of the player. Returns
## whether he's actually mid-walk this frame, for _animate_gait() to gate
## the leg swing on.
func _update_wander(delta: float) -> bool:
	var moving := false
	var pivot_position := _turn_pivot_parent_position()
	if _has_wander_target and pivot_position.distance_to(_wander_target) > WANDER_ARRIVE_DISTANCE:
		moving = true
	elif _has_wander_target:
		_has_wander_target = false
		_wander_pause_timer = _rng.randf_range(WANDER_PAUSE_MIN, WANDER_PAUSE_MAX)
	else:
		_wander_pause_timer -= delta
		if _wander_pause_timer <= 0.0:
			var angle := _rng.randf_range(0.0, TAU)
			var r := WANDER_RADIUS * sqrt(_rng.randf())
			_wander_target = _wander_anchor + Vector3(cos(angle), 0.0, sin(angle)) * r
			_has_wander_target = true

	if moving:
		var to_target := _wander_target - pivot_position
		to_target.y = 0.0
		var step := to_target.limit_length(WANDER_MOVE_SPEED * delta)
		position += step
		# This body's own forward is local -X (see SNOUT_POS vs TORSO_POS,
		# and LEG_SWING_SPEED's own comment on rotation.z) rather than the
		# +Z convention most other rigs in this project use, so the usual
		# atan2(dir.x, dir.z) heading formula doesn't apply here directly.
		# Re-derived the same way as that rotation.z fix, by mirroring the
		# already-confirmed +Z formula for a -X-forward body: aligning local
		# -X with a direction (dx, dz) needs yaw = atan2(dz, -dx). Not
		# independently confirmed in-engine yet -- flag if he turns to face
		# away from his target instead of toward it.
		if to_target.length() > 0.01:
			var heading := atan2(to_target.z, -to_target.x)
			_rotate_around_center_of_mass(
				lerp_angle(rotation.y, heading, WANDER_ROTATION_SPEED * delta)
			)
	return moving


## The historical Dinosaur root is close to the rear legs, so changing its
## yaw directly makes the long head whip through a huge arc. Preserve the
## torso centre in parent space while changing yaw: translation still moves
## the whole animal, but turning visibly happens through its centre of mass.
func _rotate_around_center_of_mass(target_yaw: float) -> void:
	var pivot_before := _turn_pivot_parent_position()
	rotation.y = target_yaw
	var pivot_after := _turn_pivot_parent_position()
	position += pivot_before-pivot_after


func _turn_pivot_parent_position() -> Vector3:
	return transform*TURN_PIVOT_LOCAL


## Gates the leg swing on actually walking -- per direct correction ("proper
## walk animation and rest state"), holding still no longer keeps the legs
## mid-stride. While moving, _leg_phase advances and each leg's target
## follows the usual diagonal-pair sine swing; while resting, the target is
## just 0 (straight down) and every leg eases toward it at LEG_REST_SETTLE_
## SPEED instead of snapping, so a stop/start never hitches.
func _animate_gait(delta: float, moving: bool) -> void:
	if moving:
		_leg_phase = fmod(_leg_phase + delta * LEG_SWING_SPEED, TAU)
	for leg in get_children():
		if leg is Node3D and leg.has_meta("leg_phase_offset"):
			var phase_offset: float = leg.get_meta("leg_phase_offset")
			var target_z := sin(_leg_phase + phase_offset) * LEG_SWING_AMPLITUDE if moving else 0.0
			var pivot := leg as Node3D
			pivot.rotation.z = lerp_angle(pivot.rotation.z, target_z, LEG_REST_SETTLE_SPEED * delta)


func _build_torso() -> void:
	_add_static(TORSO_HALF, TORSO_POS, BODY_COLOR, "Torso")


func _build_head() -> void:
	_add_static(SKULL_HALF, SKULL_POS, BODY_COLOR, "Skull")
	_add_static(SNOUT_HALF, SNOUT_POS, BODY_COLOR, "Muzzle")


## Eye + eyelid pair, both copied from ocean_kingdom_denizens.gd's own
## _add_kraken_eyes() -- see the EYE_*/LID_* constants' own doc comment for
## the exact derivation. Fixed local offsets on a rigid skull, same as the
## Kraken's own placement on its mantle -- no per-eye surface-gradient
## computation needed (that technique matters for a swept/curved body like
## a blorb or a bent-pipe head; this skull is a plain axis-aligned box with
## one known, fixed forward direction).
func _build_eyes() -> void:
	var eye_color := BODY_COLOR.darkened(EYE_COLOR_DARKEN)
	for side in [-1.0, 1.0]:
		var eye_pos := SKULL_POS + Vector3(
			EYE_OFFSET_FROM_SKULL.x, EYE_OFFSET_FROM_SKULL.y, side * absf(EYE_OFFSET_FROM_SKULL.z)
		)
		var eye := SuperEgg.build_part(EYE_SEMI_AXES, eye_color, 2.4, 2.4)
		eye.name = "EyeL" if side < 0.0 else "EyeR"
		eye.position = eye_pos
		add_child(eye)
		CollisionPolicy.mark_decorative(eye)

		var lid := SuperEgg.build_part(LID_SEMI_AXES, BODY_COLOR, 2.0, SuperEgg.EPSILON_FLAT)
		lid.name = "EyelidL" if side < 0.0 else "EyelidR"
		lid.position = eye_pos + LID_OFFSET_FROM_EYE
		add_child(lid)
		CollisionPolicy.mark_decorative(lid)


func _build_spines() -> void:
	for i in SPINE_COUNT:
		var t := float(i) / float(SPINE_COUNT - 1)
		var x := lerpf(SPINE_ROW_START_X, SPINE_ROW_END_X, t)
		var spine := SuperEgg.build_part(SPINE_HALF, BODY_COLOR, SPINE_EPSILON, SPINE_EPSILON)
		spine.name = "Spine%d" % i
		spine.position = Vector3(x, SPINE_SURFACE_Y, 0.0)
		spine.rotation.z = deg_to_rad(45.0)
		add_child(spine)
		CollisionPolicy.mark_decorative(spine)


## A single bent pipe. The base is a real ring nested inside the torso. The
## last short span uses matched sin/cos axial and radial curves to close as
## a rounded dome.
func _build_tail() -> void:
	var rings: Array = []
	for ring_index in TAIL_RING_COUNT + 1:
		var t := float(ring_index) / float(TAIL_RING_COUNT)
		var radius := _tail_radius(t)
		var center := TAIL_BASE + _tail_center(t)
		var tangent := _tail_tangent(t)
		var right := tangent.cross(Vector3.UP)
		right = right.normalized() if right.length() > 0.001 else Vector3.RIGHT
		var up := right.cross(tangent).normalized()
		var ring: Array[Vector3] = []
		for segment in TAIL_RADIAL_SEGMENTS:
			var angle := TAU * float(segment) / float(TAIL_RADIAL_SEGMENTS)
			# Per direct correction (confirmed backwards by direct report),
			# the opposite sign from lava_slide.gd's own head -- that fix
			# isn't universal across every bent-pipe shape in this project,
			# just confirmed correct for that specific one.
			ring.append(center + (right * cos(angle) + up * sin(angle)) * radius)
		rings.append(ring)
	var tail := MeshInstance3D.new()
	tail.name = "Tail"
	tail.mesh = BlorbBodyShape.build_mesh_from_rings(rings)
	var material := StandardMaterial3D.new()
	material.albedo_color = BODY_COLOR
	material.roughness = 0.6
	tail.material_override = material
	add_child(tail)

	# Three oriented box colliders sampled along the curve stand in for the
	# tail's own tapering, bending shape -- coarse, but this is a secondary
	# appendage, not a platforming-critical silhouette (see this project's
	# own collision-design guidance on reserving close mesh collision for
	# where accuracy truly matters).
	for sample_t in [0.15, 0.45, 0.85]:
		var radius := _tail_radius(sample_t)
		var center := TAIL_BASE + _tail_center(sample_t)
		var tangent := _tail_tangent(sample_t)
		var right := tangent.cross(Vector3.UP)
		right = right.normalized() if right.length() > 0.001 else Vector3.RIGHT
		var up := right.cross(tangent).normalized()
		var box_basis := Basis(right, up, tangent)
		var segment_length: float = TAIL_LENGTH / 3.0
		CollisionPolicy.add_box(
			self, tail, Vector3(radius * 1.8, radius * 1.8, segment_length),
			center, box_basis, true
		)


func _tail_center(t: float) -> Vector3:
	var x := _tail_axial_position(t)
	var distance_fraction := x / TAIL_LENGTH
	# y'(x) starts at -tan(30 degrees), then eases continuously to zero at
	# the tip. This makes the base direction exact while preventing the far
	# end from continuing to spear downward.
	var y := -TAIL_LENGTH * tan(TAIL_BASE_DOWN_ANGLE) * (
		distance_fraction - 0.5 * distance_fraction * distance_fraction
	)
	return Vector3(x, y, TAIL_WAG * sin(distance_fraction * PI))


func _tail_axial_position(t: float) -> float:
	var body_length := TAIL_LENGTH - TAIL_CAP_RADIUS
	if t < TAIL_ROUND_START_T:
		return body_length * t / TAIL_ROUND_START_T
	var cap_t := (t - TAIL_ROUND_START_T) / (1.0 - TAIL_ROUND_START_T)
	return body_length + TAIL_CAP_RADIUS * sin(cap_t * PI * 0.5)


func _tail_tangent(t: float) -> Vector3:
	const STEP := 0.01
	return (
		_tail_center(minf(t + STEP, 1.0)) - _tail_center(maxf(t - STEP, 0.0))
	).normalized()


## The body begins tapering immediately and reaches the cap radius just
## before the end. Only that small final radius collapses steeply, using a
## cosine matched to the cap's sine-shaped axial advance.
func _tail_radius(t: float) -> float:
	if t < TAIL_ROUND_START_T:
		return lerpf(TAIL_BASE_RADIUS, TAIL_CAP_RADIUS, t / TAIL_ROUND_START_T)
	var cap_t := (t - TAIL_ROUND_START_T) / (1.0 - TAIL_ROUND_START_T)
	return TAIL_CAP_RADIUS * cos(cap_t * PI * 0.5)


## One hip/shoulder pivot -> single stubby segment -> (hind only) foot, per
## direct correction (a single segment, not the earlier hip/knee chain --
## think Pandy's own single leg part). `hip_pos` is expressed with y=0; the
## front pivot remains at FRONT_HIP_HEIGHT while the hind pivot is raised by its
## foot's complete below-leg reach, leaving the torso itself untouched.
func _build_leg(hip_pos: Vector3, leg_half: Vector3, has_foot: bool, label: String) -> void:
	var hip := Node3D.new()
	hip.name = label + "Hip"
	var hip_height := HIND_HIP_HEIGHT if has_foot else FRONT_HIP_HEIGHT
	hip.position = Vector3(hip_pos.x, hip_height, hip_pos.z)
	# Front and back legs on the same side swing together (a two-beat trot);
	# the two sides are opposite phase.
	var side_sign := signf(hip_pos.z)
	var pair_offset := 0.0 if label == "Hind" else PI
	hip.set_meta("leg_phase_offset", pair_offset + (0.0 if side_sign < 0.0 else PI))
	add_child(hip)

	var leg := SuperEgg.build_part(leg_half, BODY_COLOR, BODY_EPSILON_TOP, BODY_EPSILON_BOTTOM)
	leg.name = label + "Leg"
	leg.position = Vector3(0.0, -leg_half.y, 0.0)
	hip.add_child(leg)
	_add_animated_box_collider(leg, leg_half * 2.0)

	if has_foot:
		var foot := SuperEgg.build_part(FOOT_HALF, BODY_COLOR, BODY_EPSILON_TOP, BODY_EPSILON_BOTTOM)
		foot.name = label + "Foot"
		foot.position = Vector3(
			FOOT_OFFSET.x,
			-leg_half.y * 2.0 + FOOT_OFFSET.y + HIND_LEG_FOOT_OVERLAP,
			FOOT_OFFSET.z
		)
		hip.add_child(foot)
		_add_animated_box_collider(foot, FOOT_HALF * 2.0)


## Registers a box collider that tracks `mesh`'s live global transform every
## physics frame (see _physics_process()) instead of the fixed local
## position/basis CollisionPolicy.add_box() normally expects -- necessary
## because this mesh hangs off an animated hip pivot, not a static offset
## from this StaticBody3D root.
func _add_animated_box_collider(mesh: MeshInstance3D, size: Vector3) -> void:
	# mesh.position/.basis are relative to its own parent (the hip pivot),
	# not to this StaticBody3D root the collider actually attaches under --
	# resolve the real initial local transform the same way
	# _physics_process()'s own per-frame resync does, so there's no
	# momentarily-wrong collider placement before the first physics tick.
	var local_xform := global_transform.affine_inverse() * mesh.global_transform
	var collider := CollisionPolicy.add_box(self, mesh, size, local_xform.origin, local_xform.basis, true)
	_animated_colliders.append({"collider": collider, "mesh": mesh})


func _add_static(half_size: Vector3, pos: Vector3, color: Color, label: String) -> void:
	var part := SuperEgg.build_part(half_size, color, BODY_EPSILON_TOP, BODY_EPSILON_BOTTOM)
	part.name = label
	part.position = pos
	add_child(part)
	CollisionPolicy.add_box(self, part, half_size * 2.0, pos, part.basis, true)
