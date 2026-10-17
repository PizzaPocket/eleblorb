class_name FightingPunchMode
extends TraversalMode

## Independent arm strikes layered over locomotion. Drivers supply held inputs
## and busy hands, then call update/pose after ordinary animation and before
## their suit mesh rebuild. The worn blorb supplies Strength and XP ownership.
const DURATION := 0.26
const IMPACT := 0.06
const REPEAT_DELAY := 0.32
var requested := [false, false]
var _elapsed := [-1.0, -1.0]
var _cooldown := [0.0, 0.0]
var _owners: Array[Blorb] = [null, null]
var _pending := [false, false]
var _guard := [0.0, 0.0]
var _presses := [0, 0]
var _was_requested := [false, false]
var _rng := RandomNumberGenerator.new()

func id() -> StringName:
	return &"fighting_punch"

func is_available(ctx: TraversalContext) -> bool:
	return _fighter(ctx, 0) != null or _fighter(ctx, 1) != null

## Input events preserve quick press/release pairs between rendered frames.
## Each tap may interrupt recovery, but an unlanded strike finishes first.
func queue_press(arm: int) -> void:
	if arm >= 0 and arm < 2: _presses[arm] += 1

func reset() -> void:
	for arm in 2:
		_elapsed[arm] = -1.0
		_cooldown[arm] = 0.0
		_owners[arm] = null
		_pending[arm] = false
		_guard[arm] = 0.0
		_presses[arm] = 0
		_was_requested[arm] = false

## Dedicated poses replace the generic palm-forward gesture for these arms.
static func owns_arm(suit: BlorbSuitController, side: String) -> bool:
	if suit == null: return false
	var blorb := suit.worn_blorb_in_slot("arm_" + side)
	return is_instance_valid(blorb) and not blorb.is_melted and blorb.element_state == "fighting" and blorb.has_core_item("Boxing Gloves")

func _fighter(ctx: TraversalContext, arm: int) -> Blorb:
	if ctx.suit == null: return null
	var blorb := ctx.suit.worn_blorb_in_slot("arm_left" if arm == 0 else "arm_right")
	return blorb if is_instance_valid(blorb) and not blorb.is_melted and blorb.element_state == "fighting" and blorb.has_core_item("Boxing Gloves") else null

func update(ctx: TraversalContext) -> bool:
	for arm in 2:
		_cooldown[arm] = maxf(0.0, _cooldown[arm] - ctx.delta)
		# Rising held state also supports synthetic/direct mode drivers. Do
		# not double-count a press already delivered by the input callback.
		if requested[arm] and not _was_requested[arm] and _presses[arm] == 0:
			_presses[arm] = 1
		_was_requested[arm] = requested[arm]
		var fighter := _fighter(ctx, arm)
		var busy := ctx.left_arm_busy if arm == 0 else ctx.right_arm_busy
		if UIState.modal_open or busy or fighter == null or (is_instance_valid(_owners[arm]) and _owners[arm] != fighter):
			_elapsed[arm] = -1.0
			_owners[arm] = null
			_pending[arm] = false
			_guard[arm] = 0.0
			_presses[arm] = 0
			continue
		var tap: bool = _presses[arm] > 0 and (_elapsed[arm] < 0.0 or _elapsed[arm] >= IMPACT) and not _pending[arm]
		var repeat: bool = _elapsed[arm] < 0.0 and requested[arm] and _cooldown[arm] <= 0.0
		if tap or repeat:
			if tap: _presses[arm] -= 1
			_owners[arm] = fighter
			_elapsed[arm] = 0.0
			_cooldown[arm] = REPEAT_DELAY
		var before: float = _elapsed[arm]
		if before >= 0.0:
			_elapsed[arm] += ctx.delta
			if before < IMPACT and _elapsed[arm] >= IMPACT: _pending[arm] = true
		_guard[arm] = move_toward(_guard[arm], 1.0 if requested[arm] or _elapsed[arm] >= 0.0 else 0.0, ctx.delta * 24.0)
	# Arm powers do not take ownership of the body's movement.
	return false

func pose(ctx: TraversalContext) -> void:
	for arm in 2:
		if _fighter(ctx, arm) == null: continue
		if ctx.left_arm_busy if arm == 0 else ctx.right_arm_busy: continue
		var side := "left" if arm == 0 else "right"
		var shoulder_name := "arm_%s_shoulder" % side
		var elbow_name := "arm_%s_elbow" % side
		if not ctx.rig.articulates(shoulder_name) or not ctx.rig.articulates(elbow_name): continue
		var shoulder := ctx.rig.joint(shoulder_name)
		var elbow := ctx.rig.joint(elbow_name)
		var t: float = IMPACT if _pending[arm] else maxf(0.0, _elapsed[arm])
		var extension := smoothstep(0.0, IMPACT, t) * (1.0 - smoothstep(IMPACT, 0.22, t))
		var weight: float = _guard[arm]
		# Chamber: elbow drawn back beside the ribs, forearm folded forward.
		# Strike: shoulder drives the entire upper arm to horizontal while the
		# elbow unfolds. All targets are absolute, with no accumulated wrist roll.
		shoulder.rotation = shoulder.rotation.lerp(Vector3(lerpf(0.18, -PI * 0.5, extension), signf(shoulder.position.x) * 0.14 * (1.0 - extension), signf(shoulder.position.x) * lerpf(0.28, 0.08, extension)), weight)
		elbow.rotation = elbow.rotation.lerp(Vector3(lerpf(-1.85, 0.0, extension), 0.0, 0.0), weight)
		var hand_name := "hand_%s" % side
		if not ctx.rig.articulates(hand_name): hand_name = "wrist_%s" % side
		if ctx.rig.articulates(hand_name):
			var hand := ctx.rig.joint(hand_name)
			var wrist := ctx.rig.joint("wrist_%s" % side)
			var rest := Basis.from_euler(ctx.rig.rest_rotation(hand_name))
			# Catalog knuckles follow -hand.Y; -hand.Z is the back of the
			# hand. Chamber with the thumb upward, then pronate the fist into
			# the established palm-down impact. The mirrored quarter turn is
			# authored relative to the forearm, so it remains deterministic
			# through retraction instead of projecting against world UP.
			var parent := hand.get_parent() as Node3D
			var roll := PI + signf(shoulder.position.x) * PI * 0.5 * (1.0 - extension)
			var target := parent.global_basis.orthonormalized().inverse() * elbow.global_basis.orthonormalized() * Basis(Vector3.UP, roll)
			hand.quaternion = rest.get_rotation_quaternion().slerp(target.get_rotation_quaternion(), weight)
			hand.position = ctx.rig.rest_position(hand_name)
			if wrist != hand:
				var anchor := ctx.rig.rest_position(hand_name) + rest * wrist.position
				hand.position = anchor - hand.basis * wrist.position
		if _pending[arm]:
			_pending[arm] = false
			_hit(ctx, arm)
		if _elapsed[arm] >= DURATION: _elapsed[arm] = -1.0

func _hit(ctx: TraversalContext, arm: int) -> void:
	var fighter := _fighter(ctx, arm)
	if fighter == null or fighter != _owners[arm]: return
	var side := "left" if arm == 0 else "right"
	var wrist := ctx.rig.joint("wrist_%s" % side)
	var shoulder := ctx.rig.joint("arm_%s_shoulder" % side)
	if wrist == null or shoulder == null: return
	var forward := ctx.visuals.global_basis.z.normalized()
	var fist := wrist.global_position + forward * ctx.scaled(0.08)
	var radius := ctx.scaled(0.24) * float(ctx.profile.suit_limb_fit.get("arm_wrist", 1.0))
	for node in ctx.body.get_tree().get_nodes_in_group("skeletons"):
		var enemy := node as Node3D
		if enemy == null or not enemy.has_method("take_damage"): continue
		if enemy.has_method("is_defeated") and enemy.is_defeated(): continue
		if forward.dot(enemy.global_position - ctx.body.global_position) < 0.0: continue
		var contact := _contact(enemy, fist)
		if fist.distance_to(contact) > radius: continue
		var ray := PhysicsRayQueryParameters3D.create(shoulder.global_position, contact, 1, [ctx.body.get_rid()])
		ray.hit_from_inside = true
		var obstruction := ctx.body.get_world_3d().direct_space_state.intersect_ray(ray)
		if not obstruction.is_empty():
			var collider := obstruction.get("collider") as Node
			if collider != enemy and (collider == null or not enemy.is_ancestor_of(collider)): continue
		var damage := float(ShopCatalog.find("Boxing Gloves").get("punch_damage", 16.0))
		enemy.take_damage(CombatMath.rolled_attack(damage, fighter.strength, _rng)["amount"], fighter)

## Closest point on the target's real primitive body, rather than distance to
## its feet. A small wearer can hit a tall opponent's legs while jumping can
## connect with its torso, without expanding the strike through an entire floor.
static func _contact(enemy: Node3D, fist: Vector3) -> Vector3:
	var nearest := enemy.global_position
	var best := INF
	for node in enemy.find_children("*", "CollisionShape3D", true, false):
		var collider := node as CollisionShape3D
		if collider.disabled or collider.shape == null or not collider.get_parent() is PhysicsBody3D: continue
		var at := collider.to_local(fist)
		var point := at
		if collider.shape is SphereShape3D:
			point = at.limit_length((collider.shape as SphereShape3D).radius)
		elif collider.shape is CapsuleShape3D:
			var capsule := collider.shape as CapsuleShape3D
			var axis := Vector3(0, clampf(at.y, -capsule.height * 0.5 + capsule.radius, capsule.height * 0.5 - capsule.radius), 0)
			point = axis + (at - axis).limit_length(capsule.radius)
		elif collider.shape is BoxShape3D:
			var half := (collider.shape as BoxShape3D).size * 0.5
			point = at.clamp(-half, half)
		else: continue
		point = collider.to_global(point)
		var distance := fist.distance_squared_to(point)
		if distance < best:
			best = distance
			nearest = point
	return nearest
