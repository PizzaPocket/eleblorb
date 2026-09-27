class_name VineSwingMode
extends TraversalMode

## Vine swinging, shared by every character (see
## docs/traversal_powers_architecture.md). A complete Plant suit commanded by
## the Leaf Hat throws a living vine at anything tall enough overhead and
## swings from it, hand over hand, without touching the ground.
##
## Jump is the whole control. Press it with the hat on and a support in reach
## and the vine takes hold; press it again and the hand opens, keeping every
## bit of the speed the arc had gathered. There is no separate toggle: a
## traversal the player enters by jumping at a tree needs no mode switch, and
## the failed throw is its own report (no vine appears).
##
## The lengths here are deliberately NOT scaled to the body. Every other power
## in this project scales, because it acts on the character's own limbs. This
## one acts on the world's trees: the same forty-metre emergent canopy has to
## be reachable by the human and by a monkey a quarter his height, so the
## reach, the rope and the cast impulse stay in world units and only the
## throwing hand's own height above the feet follows the rig.

## The rope's working length. An anchor further away than MAX_ROPE is refused
## rather than clamped: clamping one would snap the body the difference in a
## single frame, which reads as a teleport into the tree. One nearer than
## MIN_ROPE is refused too: a vine is not a grappling hook onto the nearest bush,
## so a support has to be genuinely away from the thrower before it will hold.
const MIN_ROPE := 12.0
const MAX_ROPE := 52.0
## Steering authority while hanging, then the pickup a first throw grants so
## the swing visibly lifts into its first descending arc. The lift is stated as
## a multiple of this character's OWN jump height rather than as a speed, both
## so it scales to any rig and so it can be read as what it is: a throw that
## catches launches the swinger well clear of the ground, onto a high first arc.
const STEER_ACCELERATION := 5.5
const CAST_JUMP_HEIGHT := 2.5
const CAST_FORWARD := 8.5
## Above this horizontal speed a throw is a continuation rather than a start, so
## it adds nothing and simply catches.
const PICKUP_SPEED_LIMIT := 6.0
## The shortest a grip can last, so one apex cannot fire two throws, and how
## long an opened hand stays open before it can catch again.
const MIN_GRIP := 0.25
const RELATCH_DELAY := 0.28
## The free hand throws once this vine has given all the forward progress it has
## to give: the body has swung PAST its own anchor in the direction being asked
## for, and the rope is out near its full length. That is the far end of the arc,
## geometrically, and it needs no apex to be detected.
##
## Two earlier triggers both failed for the same underlying reason, which was
## trying to infer the moment from vertical speed. "Vertical speed near zero" is
## true through the whole descending half of an arc, so the hands alternated like
## a metronome. Waiting for the climb to actually stop threw from a body that had
## already stalled, and in practice hardly threw at all.
## When this vine stops being able to carry him the way he is asking to go, the
## free hand throws for the next one. That is the whole rule, and it is a fact
## about the rope rather than a moment to be guessed at: a rope holds him on a
## sphere around its anchor, so once he is out past that anchor in the direction
## he wants AND has stopped gaining ground that way, this vine has given
## everything it has. He is at the far end of his arc, reaching, which is exactly
## where a hand goes out for the next tree.
##
## Two earlier rules failed by testing the wrong thing. One watched vertical speed
## for an apex, which is true through half of every arc. The other watched for
## rising-and-moving-forward, which the cast's own lift satisfies on the FIRST
## frame (it launches him at 64 degrees), so he threw a vine and let go of it
## immediately.
## Waiting for that progress to reach ZERO is waiting too long: that is the
## instant before the rope hauls him back the other way, so a throw that finds
## nothing there leaves him being dragged off the way he asked to go. He throws
## while the arc is still carrying him, once its forward speed has fallen to this
## fraction of the fastest it reached on this grip. Past the anchor, still moving,
## and before the swing back.
const HANDOFF_CARRY_FRACTION := 0.55
## Below this a swing is not really carrying him anywhere, so the fraction above
## would fire on noise.
const FORWARD_SPENT_SPEED := 1.6
## How far ahead of him the next support has to stand to be worth taking.
const CATCH_MIN_AHEAD := 6.0
const TERMINAL_FALL := 60.0

## The holding arm follows the rope, using the SAME shoulder rotation the
## arm-power raise uses and simply carrying it further. That raise is the known
## good one: player.gd commands `rotation.x = -ARM_POWER_POSE_ANGLE` (90
## degrees) and the arm lands forward and horizontal. So the shoulder here is
## driven on that same axis, scaled by how high the rope actually runs: zero at
## rest with the arm down, a quarter turn with the rope horizontal, and a half
## turn with the rope straight overhead, which is as far as a shoulder goes.
##
## An earlier pass aimed the shoulder by building a basis instead, to sidestep
## an old note that this pivot under-turned by a factor of 1.6. That note is
## stale; the constant reads 90 degrees today and the pivot turns by what it is
## given. Driving the same axis the working raise drives is both simpler and
## the thing actually asked for.
const SHOULDER_STRAIGHT_UP := PI
## These joints are written ABSOLUTELY, because the driver runs its own animation
## every frame and this pose after it: a pose that only eased partway toward its
## target got pulled back the next frame and the two settled at a permanent
## halfway compromise (the shoulder never passing 45 degrees, the wrist reading
## as unbent). player.gd's arm-power pose records the identical failure against
## the fire-jet pose.
##
## But a limb must never appear somewhere new: it travels from where it is. So
## what gets written is this pose's OWN eased state, seeded from wherever the
## joint actually was when the pose first touched it and moved at these rates
## from there. Writing the raw target absolutely is what snapped, and it snapped
## hardest at a hand-over, where the free arm becomes the holding arm and the
## legs trade lead for trail, so every one of those targets changes at once.
const SHOULDER_RATE := 9.0
const HAND_RATE := 10.0
const LEG_RATE := 6.5
## The free arm's own hang: a little forward of straight down with a soft elbow,
## which is where an unoccupied arm sits on a body that is not walking.
const RELAXED_SHOULDER := deg_to_rad(14.0)
const RELAXED_ELBOW := deg_to_rad(18.0)
## The wrist's bend is the arm-power raise's own, held RELATIVE TO THE FOREARM
## rather than to the world, so it is the same bend at every arm angle. Holding
## it relative to the world instead made the bend shrink as the arm rose, until
## an arm straight overhead had no bend left.
##
## This is that pose's hand orientation in the forearm's own frame, worked out
## from the two things it is built from. The arm-power raise commands the
## shoulder -90 degrees about X, which turns the arm's own -Y from straight down
## to straight forward, so the forearm's frame there has columns X=(1,0,0),
## Y=(0,0,-1), Z=(0,1,0). The hand's wanted world orientation there is
## Basis(-body.x, -body.y, body.z) (palm to the front, fingertips at the sky,
## per _pose_extended_arm). Transposing the first into the second leaves:
const ARM_POWER_HAND := Basis(
	Vector3(-1.0, 0.0, 0.0), Vector3(0.0, 0.0, -1.0), Vector3(0.0, -1.0, 0.0)
)
## Then the whole forearm rolls half a turn about its own length, which in that
## same frame is -Y. Half a turn is its own mirror, so there is no inward or
## outward sign to get wrong. The fingertips, perpendicular to the forearm
## either way, swap to the far side: pointing at the sky with the arm forward
## becomes pointing at the toes.
const FOREARM_AXIS := Vector3(0.0, -1.0, 0.0)
const FOREARM_ROLL := PI
## How far off the forearm's own line the fingers finally sit. The arm-power
## raise's bend is a right angle; half of that reads as a hand hanging from a
## vine rather than one cranked over. The basis above is rotated by
## (WRIST_BEND - a right angle) about the forearm frame's X to get there, which
## is zero at a right angle and opens the wrist as the bend shrinks.
const WRIST_BEND := deg_to_rad(45.0)
## The opposite leg to the holding hand leads the swing, the same leg the arm
## would answer in a stride. Hip FORWARD is negative rotation.x and the knee's
## own bend is POSITIVE: both taken from _apply_airborne_pose() in player.gd,
## which applies -(hip_bend) and +knee_bend after that shoulder/hip sign was
## found backwards once by direct observation. Reused, not re-derived.
## Both hips bend FORWARD, the trailing one simply much less. It used to bend
## backwards, which with a knee folded this far put the trailing foot further
## behind than any stride reaches; bending forward less already carries that foot
## well back, because the calf is folded up behind the thigh.
const SWING_HIP_LEAD := deg_to_rad(84.0)
const SWING_HIP_TRAIL := deg_to_rad(17.0)
## The knees keep the airborne pose's own fold (JUMP_KNEE_BEND is 130 degrees);
## only the hips are the swing's own.
const SWING_KNEE_BEND := deg_to_rad(130.0)
## How quickly the joints this mode wrote hand themselves back afterwards.
const RELEASE_BLEND := 11.0

var swinging := false
## The velocity the body had when the swing let go, for the driver to hand back to
## ordinary movement. Without it the driver recomputed horizontal velocity from
## the stick and the arc's speed was simply thrown away, so letting go dropped him
## like a stone instead of launching him.
var exit_velocity := Vector3.ZERO
var anchor := Vector3.ZERO
## The body the rope is tied to, so the search for the NEXT support can look past
## it. Hanging from a trunk, that trunk is the first thing every forward ray hits.
var anchor_rid := RID()
var rope_length := 0.0
## Which hand carries the load. The other one is the one that throws next.
var left_hand := true
var grip_timer := 0.0
var relatch_timer := 0.0
## Whether this grip has climbed yet, which is what makes the next stop
## climbing an apex rather than just a slow moment.

## This pose's own eased value per joint, keyed by instance id: a Vector3 of
## Euler angles, or a Quaternion for the hand. Absent means the pose has not
## touched that joint yet and should start from wherever it now is.
var _eased: Dictionary = {}
## Which hand the pose last ran for, so a hand-over can re-seed from the arms'
## real positions rather than easing on from the other arm's numbers.
var _posed_left := true
## Where each posed hand's wrist belongs in its parent's frame, and where that
## hand itself sat before the pose moved it. See _pose_arm().
var _wrist_anchor: Dictionary = {}
var _hand_rest_position: Dictionary = {}
## Every joint this mode wrote, with the rotation it found there, so leaving the
## swing puts back what the ordinary animation does not itself rewrite (it
## drives rotation.x each frame and leaves y and z alone, which is exactly
## where an aimed basis leaves its residue).
var _borrowed: Dictionary = {}
var _releasing := false
## The fastest this grip has carried him toward what the stick is asking for,
## which HANDOFF_CARRY_FRACTION is a fraction of.
var _peak_carry := 0.0
## The drawn vine, and the spent ones still retracting. Presentation only, and
## its own class: see VineCord.
var _cord := VineCord.new()


func id() -> StringName:
	return &"vine_swing"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null and ctx.suit.has_vine_swing_suit()


## The whole power for one frame. `aim` is the world direction the thrower is
## looking or travelling, horizontal. Returns true when the swing owned the
## frame, in which case the caller has already been moved and must not run its
## own locomotion.
func swing(ctx: TraversalContext, aim: Vector3, jump_pressed: bool) -> bool:
	_cord.advance(ctx)
	if not is_available(ctx):
		if swinging:
			_open_hand()
		relatch_timer = 0.0
		_hand_back(ctx)
		return false
	relatch_timer = maxf(relatch_timer - ctx.delta, 0.0)
	if swinging:
		if jump_pressed:
			# Jump is a deliberate exit: it ends the chain rather than continuing
			# it, and no throw follows until he asks for one. The arc's own
			# momentum goes with him.
			exit_velocity = ctx.body.velocity
			_open_hand()
			relatch_timer = RELATCH_DELAY
			return false
		_hang(ctx, aim)
		return true
	_hand_back(ctx)
	if jump_pressed and relatch_timer <= 0.0 and _throw(ctx, aim, true):
		_hang(ctx, aim)
		return true
	return false


## Lets go without ending the power: the next jump throws again. A vine let go
## of on purpose is gone at once rather than retracting on its own time, which
## left a line trailing back to a tree the swinger had already left.
func _open_hand() -> void:
	swinging = false
	_eased.clear()
	_cord.release()
	_releasing = true


func reset() -> void:
	swinging = false
	relatch_timer = 0.0
	grip_timer = 0.0
	_cord.clear()
	_eased.clear()
	_releasing = true


## Throws for a support. `with_pickup` marks a standing start, which gets the
## one modest impulse; a mid-arc hand-off keeps the trajectory it already has.
func _throw(ctx: TraversalContext, aim: Vector3, with_pickup: bool) -> bool:
	var found := find_anchor(ctx, aim)
	if found == null:
		# Nothing overhead took the throw. The vine simply does not appear,
		# which is the whole report: naming what it wanted would be telling
		# the player where to stand.
		return false
	anchor = found.point
	anchor_rid = found.body
	rope_length = clampf(
		ctx.body.global_position.distance_to(anchor), MIN_ROPE, MAX_ROPE
	)
	grip_timer = MIN_GRIP
	_peak_carry = 0.0
	_cord.release()
	# The pickup is for a standing start. A throw made mid-flight, off the
	# momentum of the arc just released, keeps the trajectory it already has:
	# adding the launch on top would wipe out the very speed being carried, which
	# is the whole point of releasing and throwing again.
	var moving := Vector3(ctx.body.velocity.x, 0.0, ctx.body.velocity.z).length()
	if with_pickup and moving <= PICKUP_SPEED_LIMIT:
		left_hand = true
		var forward := _horizontal(aim, ctx)
		ctx.body.velocity += forward * CAST_FORWARD
		ctx.body.velocity.y = maxf(
			ctx.body.velocity.y,
			HumanoidLocomotion.jump_speed(ctx.profile, CAST_JUMP_HEIGHT)
		)
	swinging = true
	return true


## The best support to throw at right now, or null. The sweep and the judging are
## VineAnchorSearch's; the rope's own window is this mode's, so it is handed over
## rather than duplicated. `reach_out` is for a hand-over, which wants distance
## counted in a candidate's favour.
func find_anchor(
	ctx: TraversalContext, aim: Vector3, reach_out: bool = false, skip: RID = RID()
) -> VineAnchorSearch.Found:
	return VineAnchorSearch.best(
		ctx, VineCord.hand_point(ctx, left_hand), _horizontal(aim, ctx),
		Vector2(MIN_ROPE, MAX_ROPE), reach_out, skip
	)


## One frame on the rope: gravity and steering, then the rope's own
## constraint. The rope cannot stretch, so the component of velocity trying to
## lengthen it is removed while inward velocity is kept, which is what lets a
## fresh throw climb before it falls. Near the top of an arc the free hand
## throws for the next support; failing costs nothing, since the vine already
## held is still load-bearing.
func _hang(ctx: TraversalContext, aim: Vector3) -> void:
	var body := ctx.body
	grip_timer = maxf(grip_timer - ctx.delta, 0.0)
	body.velocity += ctx.direction * STEER_ACCELERATION * ctx.delta
	body.velocity.y = HumanoidLocomotion.apply_gravity(
		body.velocity.y, ctx.delta, ctx.profile, TERMINAL_FALL
	)
	var radial := body.global_position - anchor
	if radial.length_squared() > 0.001:
		var outward := radial.normalized()
		var stretching := body.velocity.dot(outward)
		if stretching > 0.0:
			body.velocity -= outward * stretching
	body.move_and_slide()
	radial = body.global_position - anchor
	if radial.length() > rope_length:
		body.global_position = anchor + radial.normalized() * rope_length
	# The stick is what asks for the next vine. Hold a direction and the free hand
	# throws that way the moment this vine has carried the body as far that way as
	# it can; hold nothing and the grip keeps, and the swing simply swings. The
	# rhythm belongs to the player rather than to a timer.
	var steered := ctx.direction.length_squared() > 0.0001
	var wanted := ctx.direction.normalized() if steered else Vector3.ZERO
	# The arc is followed all the way through, and only at its far end, where this
	# vine can carry him no further the way he is asking to go, does the free hand
	# reach for the next one. Failing to find one costs nothing: the vine he has
	# is still load-bearing and the swing carries on.
	if steered and grip_timer <= 0.0 and _spent_toward(ctx, wanted):
		_catch_next(ctx, wanted)
	_cord.grow(ctx, anchor, left_hand)


## Whether this vine has given all it can toward `wanted`: he is out past its
## anchor that way and no longer gaining ground. Being past the anchor is what
## keeps the launch from counting, since a throw begins with him behind or beneath
## it, swinging toward it rather than away.
func _spent_toward(ctx: TraversalContext, wanted: Vector3) -> bool:
	var carrying := Vector3(
		ctx.body.velocity.x, 0.0, ctx.body.velocity.z
	).dot(wanted)
	_peak_carry = maxf(_peak_carry, carrying)
	var out_from_anchor := ctx.body.global_position - anchor
	out_from_anchor.y = 0.0
	if out_from_anchor.dot(wanted) <= 0.0:
		return false
	if _peak_carry <= FORWARD_SPENT_SPEED:
		return false
	return carrying <= _peak_carry * HANDOFF_CARRY_FRACTION


## The next support in the direction being asked for, taken hand over hand. It has
## to lie AHEAD of him: catching something level or behind would stop the run
## rather than continue it.
func _catch_next(ctx: TraversalContext, wanted: Vector3) -> bool:
	var found: Variant = find_anchor(ctx, wanted, true, anchor_rid)
	if found == null:
		return false
	var next := found as Vector3
	var ahead := Vector3(
		next.x - ctx.body.global_position.x, 0.0, next.z - ctx.body.global_position.z
	).dot(wanted)
	if ahead < CATCH_MIN_AHEAD:
		return false
	var held := anchor
	var hand_was := left_hand
	anchor = next
	anchor_rid = found.body
	rope_length = clampf(
		ctx.body.global_position.distance_to(anchor), MIN_ROPE, MAX_ROPE
	)
	left_hand = not left_hand
	# The spent vine retracts to the hand that threw it while the other hand's
	# own throw is already on its way out.
	_cord.retire(held, hand_was)
	grip_timer = MIN_GRIP
	_peak_carry = 0.0
	return true


## Which way the body should be facing: where the stick is asking to go, else
## where the arc is actually carrying it. A swinger should never be left facing
## sideways or backwards because the aim changed under him, so this is offered
## for the driver to turn its own body toward, the same as any other movement.
## Returns ZERO when there is nothing to say, and the driver keeps its heading.
func heading(ctx: TraversalContext) -> Vector3:
	if ctx.direction.length_squared() > 0.0001:
		var steer := ctx.direction
		steer.y = 0.0
		if steer.length_squared() > 0.0001:
			return steer.normalized()
	var travel := ctx.body.velocity
	travel.y = 0.0
	if travel.length_squared() > 0.25:
		return travel.normalized()
	return Vector3.ZERO


## Where the next throw looks. The stick comes first: a player holding a
## direction at the apex is saying which way to carry on, and the ray fan scores
## its forward rays highest, so that direction is what the throw biases toward.
## Failing a stick, the travel, which is where the arc is already going.
func _swing_aim(ctx: TraversalContext, aim: Vector3) -> Vector3:
	if ctx.direction.length_squared() > 0.0001:
		return _horizontal(ctx.direction, ctx)
	var travel := ctx.body.velocity
	travel.y = 0.0
	if travel.length_squared() > 1.0:
		return travel.normalized()
	return _horizontal(aim, ctx)


func _horizontal(aim: Vector3, ctx: TraversalContext) -> Vector3:
	var flat := aim
	flat.y = 0.0
	if flat.length_squared() > 0.0001:
		return flat.normalized()
	if ctx.visuals != null:
		# The rendered body faces its own +Z in this project, not -Z as a
		# Camera3D does (see the 180 degree turn player.gd applies for exactly
		# this reason). Taking -Z here aimed every fallback throw backwards.
		flat = ctx.visuals.global_transform.basis.z
		flat.y = 0.0
		if flat.length_squared() > 0.0001:
			return flat.normalized()
	return Vector3.FORWARD


## The holding arm follows the rope, the wrist turns the fingers back down over
## it, and the opposite leg leads the swing.
func pose(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	if rig == null or not swinging or ctx.visuals == null:
		return
	if _posed_left != left_hand:
		# The hands have changed over. Every target moved at once, so drop the
		# eased state and let each joint set off again from where it really is.
		_eased.clear()
		_posed_left = left_hand
	var busy := ctx.left_arm_busy if left_hand else ctx.right_arm_busy
	if not busy:
		_pose_arm(ctx)
	_relax_arm(ctx, not left_hand)
	_pose_legs(ctx)


## The arm-power raise, carried as far up as the rope runs, and the arm-power
## wrist rolled half a turn so the fingers hang toward the toes.
func _pose_arm(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	var prefix := "arm_left" if left_hand else "arm_right"
	var shoulder := rig.joint("%s_shoulder" % prefix)
	if shoulder == null:
		return
	# Left is +1 and right is -1 for the outward tilt, matching the airborne
	# pose's own two literals rather than being derived again.
	var side := 1.0 if left_hand else -1.0
	var raise_angle := _rope_raise(ctx, shoulder.global_position)
	_borrow(shoulder)
	_ease_rotation(shoulder, Vector3(
		-raise_angle, 0.0, side * ProceduralFigure.ARM_OUTWARD_ANGLE
	), SHOULDER_RATE, ctx.delta)
	var elbow := rig.joint("%s_elbow" % prefix)
	if elbow != null:
		# Straight: the arm hangs from the vine rather than pulling on it.
		_borrow(elbow)
		_ease_rotation(elbow, Vector3.ZERO, SHOULDER_RATE, ctx.delta)
	# The hand SEGMENT, not one of its attachment markers: a marker is a point on
	# the hand, so rotating it moves nothing. An ALIASED hand is accepted rather
	# than refused, because on Xiao Hou Zi's rig one node genuinely serves both
	# "hand" and "wrist" and rotating it does bend his hand; only a missing one
	# is a reason to stop.
	var hand := rig.joint("hand_left" if left_hand else "hand_right")
	if hand == null:
		hand = rig.joint("wrist_left" if left_hand else "wrist_right")
	if hand == null:
		return
	# The arm-power raise's own wrist bend, in the forearm's own frame so it is
	# the same bend whatever angle the arm is carried to, rolled half a turn
	# about the forearm's length. See ARM_POWER_HAND.
	_borrow(hand)
	var rolled := Basis(FOREARM_AXIS, FOREARM_ROLL) * ARM_POWER_HAND
	var wanted := (
		Basis(Vector3.RIGHT, WRIST_BEND - PI * 0.5) * rolled
	).get_rotation_quaternion()
	var id := hand.get_instance_id()
	# The hand's own node origin is the centre of its rendered segment, not the
	# wrist (see the PalmAttach/WristAttach comments in procedural_figure.gd), so
	# turning it swings the wrist end away and the butt of the palm stops meeting
	# the wrist. Where the wrist sits in the forearm's frame is captured before
	# anything is written and then held: the hand is placed each frame so its own
	# wrist marker returns there. player.gd's arm-power pose does the same thing
	# through _anchor_hand_to_wrist(); this is that, without the cache.
	var wrist := rig.joint("wrist_left" if left_hand else "wrist_right")
	if wrist != null and not _wrist_anchor.has(id):
		_wrist_anchor[id] = hand.position + hand.basis * wrist.position
		_hand_rest_position[id] = hand.position
	var current: Quaternion = _eased[id] if _eased.has(id) else hand.quaternion
	current = current.slerp(wanted, minf(HAND_RATE * ctx.delta, 1.0))
	_eased[id] = current
	hand.quaternion = current
	if wrist != null and _wrist_anchor.has(id):
		hand.position = (_wrist_anchor[id] as Vector3) - hand.basis * wrist.position


## The arm that is NOT holding the vine. Left to itself it kept whatever the last
## hand-over abandoned it in, hand still turned palm-up, reading as an arm frozen
## mid-gesture. It hangs relaxed instead, and its hand is given back the rotation
## and the position this pose borrowed, so nothing of the grip is left on it.
func _relax_arm(ctx: TraversalContext, free_left: bool) -> void:
	var rig := ctx.rig
	if free_left and ctx.left_arm_busy:
		return
	if not free_left and ctx.right_arm_busy:
		return
	var prefix := "arm_left" if free_left else "arm_right"
	var side := 1.0 if free_left else -1.0
	var shoulder := rig.joint("%s_shoulder" % prefix)
	if shoulder != null:
		_borrow(shoulder)
		_ease_rotation(shoulder, Vector3(
			-RELAXED_SHOULDER, 0.0, side * ProceduralFigure.ARM_OUTWARD_ANGLE
		), SHOULDER_RATE, ctx.delta)
	var elbow := rig.joint("%s_elbow" % prefix)
	if elbow != null:
		_borrow(elbow)
		_ease_rotation(elbow, Vector3(-RELAXED_ELBOW, 0.0, 0.0), SHOULDER_RATE, ctx.delta)
	var hand := rig.joint("hand_left" if free_left else "hand_right")
	if hand == null:
		return
	var id := hand.get_instance_id()
	if _hand_rest_position.has(id):
		hand.position = _hand_rest_position[id] as Vector3
	if _borrowed.has(id):
		_ease_rotation(hand, _borrowed[id] as Vector3, HAND_RATE, ctx.delta)


## How far the shoulder has to carry the arm for it to lie along the rope, in
## the same units the arm-power raise is commanded in: nothing with the rope
## straight down, a quarter turn with it level, a half turn with it overhead.
func _rope_raise(ctx: TraversalContext, from: Vector3) -> float:
	var rope := anchor - from
	if rope.length_squared() < 0.0001:
		return SHOULDER_STRAIGHT_UP
	var up: Vector3 = ctx.visuals.global_transform.basis.orthonormalized().y
	# The angle away from straight down, which runs 0 to a half turn whichever
	# way the rope leans. Leaning back never folds the joint backwards; it just
	# reads as the same elevation in front, which is the shoulder's own limit.
	var elevation := clampf(rope.normalized().dot(up), -1.0, 1.0)
	return clampf(acos(-elevation), 0.0, SHOULDER_STRAIGHT_UP)


## The leg opposite the holding hand leads, the other trails, and the knees keep
## the airborne pose's own fold. Hip forward is negative rotation.x, the knee's
## bend positive: see SWING_HIP_LEAD.
func _pose_legs(ctx: TraversalContext) -> void:
	var rig := ctx.rig
	var lead_is_left := not left_hand
	for side in 2:
		var prefix := "leg_left" if side == 0 else "leg_right"
		var leads := (side == 0) == lead_is_left
		var hip := rig.joint("%s_hip" % prefix)
		if hip != null:
			_borrow(hip)
			_ease_rotation(hip, Vector3(
				-SWING_HIP_LEAD if leads else -SWING_HIP_TRAIL, 0.0, 0.0
			), LEG_RATE, ctx.delta)
		var knee := rig.joint("%s_knee" % prefix)
		if knee != null:
			_borrow(knee)
			_ease_rotation(knee, Vector3(SWING_KNEE_BEND, 0.0, 0.0), LEG_RATE, ctx.delta)


## Writes a joint absolutely, from this pose's own eased value rather than from
## the target, so the joint travels there instead of appearing there. Seeded from
## wherever the joint actually is the first time it is touched.
##
## The pitch uses plain lerpf, not lerp_angle: the shoulder's own target runs to
## a half turn, and lerp_angle takes the shortest arc, which at that magnitude
## goes the wrong way round.
func _ease_rotation(joint: Node3D, target: Vector3, rate: float, delta: float) -> void:
	var id := joint.get_instance_id()
	var current: Vector3 = _eased[id] if _eased.has(id) else joint.rotation
	var t := minf(rate * delta, 1.0)
	current = Vector3(
		lerpf(current.x, target.x, t),
		lerp_angle(current.y, target.y, t),
		lerp_angle(current.z, target.z, t)
	)
	_eased[id] = current
	joint.rotation = current


## Records a joint's rotation the first time this mode touches it.
func _borrow(joint: Node3D) -> void:
	var id := joint.get_instance_id()
	if not _borrowed.has(id):
		_borrowed[id] = joint.rotation


## Gives back what the ordinary animation will not rewrite itself. It drives
## rotation.x on these joints every frame and leaves y and z alone, and an aimed
## basis leaves its residue in exactly those two, so those are what this puts
## back. Leaving x to the ordinary pose avoids fighting it for one frame.
func _hand_back(ctx: TraversalContext) -> void:
	if not _releasing:
		return
	var t := minf(RELEASE_BLEND * ctx.delta, 1.0)
	var settled := true
	for id: int in _hand_rest_position.keys():
		var moved := instance_from_id(id) as Node3D
		if moved != null and is_instance_valid(moved):
			moved.position = _hand_rest_position[id] as Vector3
	for id: int in _borrowed.keys():
		var joint := instance_from_id(id) as Node3D
		if joint == null or not is_instance_valid(joint):
			continue
		var rest: Vector3 = _borrowed[id]
		joint.rotation.y = lerp_angle(joint.rotation.y, rest.y, t)
		joint.rotation.z = lerp_angle(joint.rotation.z, rest.z, t)
		if absf(angle_difference(joint.rotation.y, rest.y)) > 0.01:
			settled = false
		if absf(angle_difference(joint.rotation.z, rest.z)) > 0.01:
			settled = false
	if settled:
		_borrowed.clear()
		_wrist_anchor.clear()
		_hand_rest_position.clear()
		_releasing = false
