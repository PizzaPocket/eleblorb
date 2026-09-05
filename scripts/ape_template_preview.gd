class_name ApeTemplatePreview
extends StaticBody3D

## Standalone instance of ApeTemplate -- started as a pose/proportion review
## harness ("we'll use it to build out some ape species after we get it
## right"), now also the real ape/"primate template" monkey NPC class the
## Primate Kingdom's village uses (see jungle_kingdom_village.gd), the same
## way jungle_villager.gd graduated from an early monkey pass into the
## stuffed-animal-monkey species' own real script. Wanders a small radius
## around its own spawn point, plus idle blink and (when has_tail is true)
## the tail's own idle sway, or seats on a live Manchego instance via
## mount_on() instead of roaming. Talk prompt/dialogue (display_name/
## talk_lines/dialog_actions_provider below) mirrors jungle_villager.gd's own
## Interactable + DialogUI pattern.

@export var fur_color: Color = MonkeyFigure.MONKEY_FUR_COLOR
@export var marking_color: Color = MonkeyFigure.MARKING_COLOR
@export var display_scale: float = 1.0
## false = ape, true = ApeTemplate's own "primate template" monkey variant
## (has a tail -- see that file's own class doc comment on the monkey/ape
## class split).
@export var has_tail: bool = false
## 0.0 (ectomorph) - 1.0 (extreme mesomorph), 0.5 is ApeTemplate's own
## established default build -- see that file's own CHEST_BUILD_SCALE_*
## doc comment.
@export var body_type: float = 0.5
## Multiplies ApeTemplate's own MONKEY_HEAD_SIZE_SCALE.y -- 1.0 is that
## file's own established default head proportions, higher grows a taller
## head within a range, per direct instruction.
@export var head_height_scale: float = 1.0
## Defaults per direct instruction ("leaning quite a bit forward at the
## hips... significantly bent [leg joints]... head tilted upward"). Per a
## later correction, the upward tilt should land exactly level with the
## horizon (simple cancellation of the spine lean), not past level -- see
## ApeTemplate's own SPINE_TILT_SHARES/total_tilt comment for how this
## factor is used (0.0 = cancel the lean exactly; >0.0 would tilt past
## level).
@export var spine_forward_bend: float = deg_to_rad(45.0)
## 0.0 here would hang the arm exactly straight down (fully canceling the
## spine lean, see ApeTemplate.build()'s own arm_rest_x formula); this
## tips it further forward past straight-down by this fraction of the
## lean angle. Brought down from an initial 0.35 per direct feedback that
## the arms hung too far forward for a natural resting pose.
@export var arm_forward_relax_factor: float = 0.15
@export var head_tilt_factor: float = 0.0
## Shown as the speaker name in DialogUI -- see npc.gd's/jungle_villager.gd's
## own identically-named export.
@export var display_name: String = "Primate"
## This NPC's own lines -- set per-instance by whatever spawns it (see
## jungle_kingdom_village.gd's identity rosters), same "no shared pool"
## reasoning npc.gd's own talk_lines doc comment gives.
@export var talk_lines: Array[String] = ["..."]
## Extra multiplier on top of the ordinary display_scale-proportional speed
## scaling below (_move_speed/_swing_speed) -- see blorb.gd's own identically
## -purposed movement_speed_multiplier (used at 0.1 for the wasteland giant,
## Humongous) for the convention this mirrors. Left at 1.0 (a no-op) for
## every ordinary-sized ape/monkey; a giant-scale instance (see
## primate_kingdom_gorilla.gd) sets this well below 1.0 on top of its own
## already-slower per-scale swing cadence, so its sheer size doesn't
## ALSO make it move proportionally faster in absolute terms -- a real giant
## should lumber, not cover ground quickly just because its strides are long.
@export var movement_speed_multiplier: float = 1.0
## Separate cadence control for landmark-scale creatures. Their translation
## and visible stride must be tunable independently to prevent foot sliding.
@export var gait_speed_multiplier: float = 1.0
@export var roam_radius: float = ROAM_RADIUS
## Uses articulated, pose-following collision shapes so a giant creature is
## a traversable piece of the world rather than one oversized blocking pill.
@export var parkour_collision: bool = false

const INTERACT_RADIUS := 2.0
const HEAD_YAW_LIMIT := deg_to_rad(70.0)
const HEAD_TURN_SPEED := 8.0

const ROAM_RADIUS := 10.0
const ROAM_PAUSE_MIN := 2.0
const ROAM_PAUSE_MAX := 5.0
const ROAM_ARRIVE_DISTANCE := 0.3
const ROAM_MOVE_SPEED := 1.3
const ROTATION_SPEED := 5.0
const GROUND_SETTLE_SPEED := 8.0

const WALK_SWING_SPEED := 6.0
const WALK_SWING_AMOUNT := 0.4
const POSE_SETTLE_SPEED := 8.0
## Mounted review pose. These reuse the player's established Manchego
## angles rather than inventing a second riding language for an ape.
const MOUNT_HIP_BEND := Player.RIDE_HIP_BEND
const MOUNT_HIP_SPLAY := Player.RIDE_HIP_SPLAY
const MOUNT_KNEE_BEND := Player.RIDE_KNEE_BEND
const MOUNT_ARM_FORWARD := Player.RIDE_ARM_FORWARD
const MOUNT_ELBOW_INWARD := Player.RIDE_ELBOW_INWARD
## Knee/elbow bend curves below are ported straight from player.gd's own
## walk cycle (_animate_walk() there) rather than reinvented -- per direct
## instruction this rig's own cycle read as "very very simplified" next to
## the human figures'. Reused as relative offsets on top of THIS rig's own
## rest angles (permanent crouch/lean, captured below) instead of toward
## zero, and with the sprint-only pieces (stride easing, stance-phase knee
## bump, dorsiflex/plantarflex ankles, run body-bob) left out entirely --
## this rig has no sprint state to drive them. Swing/arm-swing were already
## a direct port (same sign convention, confirmed by player.gd's own
## already-verified comments); knee bend and elbow bend below are the new
## ports.

var _pivots: Dictionary
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()

var _terrain: Node
var _roam_center: Vector2
var _wander_target: Vector2
var _has_wander_target := false
var _pause_timer := 0.0
var _walk_phase := 0.0
var _rng := RandomNumberGenerator.new()
var _mounted_on: Manchego = null
var _collision_shape: CollisionShape3D
var _parkour_colliders: Array[Dictionary] = []
var _look_target: Node3D = null
## Optional hook: when valid, called from _on_talk() with no arguments and
## expected to return an Array[Dictionary] of extra DialogUI actions (same
## {"label", "callback"} shape npc.gd's own vendor actions use) to append
## after the ordinary talk line -- lets a spawner (jungle_kingdom_village.gd,
## for the quest-giving ape) wire in one-off dialog behavior (a quest prompt,
## a turn-in check against Inventory) without this general-purpose template
## needing to know anything about quests itself.
var dialog_actions_provider: Callable = Callable()

## Captured from the freshly-built rig, not hardcoded to 0.0 -- ApeTemplate.
## build() gives every one of these its own rest rotation.x for the crouch/
## lean pose (see that file's own doc comment); the walk cycle below must
## swing/settle around THESE values, not zero, or an idle lerp toward a
## hardcoded 0.0 would slowly undo the rest pose every time the ape stops
## moving (exactly the bug jungle_villager.gd's own _arm_rest_x fixes for
## the monkey NPCs).
var _leg_rest_x := 0.0
var _knee_rest_x := 0.0
var _ankle_rest_x := 0.0
var _arm_rest_x := 0.0
## Per direct instruction: the gait should be proportional to the
## instance's own relative size, not the same fixed ROAM_MOVE_SPEED/
## WALK_SWING_SPEED for every ape AND monkey regardless of how small the
## "primate template" monkey variant (has_tail=true) can get. Move speed
## scales DOWN with display_scale (a smaller body has shorter legs, so
## covers less ground per stride at the same cadence -- moving at the
## same fixed absolute speed as a much taller ape would either slide the
## feet or read as gliding); swing speed (cadence) scales UP inversely --
## real small animals take quicker, choppier steps, not slower ones.
## Computed once in _ready() from this instance's own display_scale, with
## 1.0 (roughly the ape range's own center) as the reference where both
## reduce to the original fixed constants unchanged.
var _move_speed := ROAM_MOVE_SPEED
var _swing_speed := WALK_SWING_SPEED
## No permanent elbow bend on this rig (unlike hip/knee/ankle) -- 0.0
## matches ProceduralFigure's own human elbow rest.
var _elbow_rest_x := 0.0
## Unlike _elbow_rest_x, THIS one isn't 0 -- ApeTemplate.build() gives the
## elbow its own permanent inward rest angle (ELBOW_INWARD_ANGLE, opposite-
## signed per side), so this has to be captured per side, same reasoning
## as every other _*_rest_* var above.
var _elbow_rest_z_left := 0.0
var _elbow_rest_z_right := 0.0


func _ready() -> void:
	_rng.randomize()
	_move_speed = ROAM_MOVE_SPEED * display_scale * movement_speed_multiplier
	# CORRECTED per direct report ("I don't see the giant gorilla walking,
	# he's just sliding around and frozen in one position when traveling") --
	# an earlier version also multiplied movement_speed_multiplier into the
	# swing CADENCE here, reasoned as avoiding a "rapid tiny steps" artifact,
	# but that reasoning didn't account for _swing_speed ALREADY carrying its
	# own size-based slowdown (WALK_SWING_SPEED / display_scale, right below
	# -- "real small animals take quicker, choppier steps," see this same
	# var's own doc comment above). Stacking movement_speed_multiplier on TOP
	# of that (16x from scale, then ANOTHER 10x from the giant's own 0.1
	# multiplier) pushed the stride period out to well over two minutes --
	# not slow, effectively frozen -- while _move_speed (which SHOULD carry
	# movement_speed_multiplier, per blorb.gd's own "scales every self-
	# directed motion" convention for Humongous) kept translating the body
	# normally, producing exactly the reported "legs frozen, body sliding"
	# symptom. movement_speed_multiplier now only governs how much ground is
	# actually covered (translation), not the cadence -- the existing size-
	# based term alone already gives a giant an appropriately slow, ponderous
	# stride without needing a second slowdown layered on top of it.
	_swing_speed = WALK_SWING_SPEED / display_scale * gait_speed_multiplier
	var variant := {
		"marking_color": marking_color,
		"spine_forward_bend": spine_forward_bend,
		"arm_forward_relax_factor": arm_forward_relax_factor,
		"head_tilt_factor": head_tilt_factor,
		"body_type": body_type,
		"head_height_scale": head_height_scale,
		"has_tail": has_tail,
	}
	_pivots = ApeTemplate.build(self, fur_color, display_scale, variant)
	_eyes = _pivots["eyes"]
	_leg_rest_x = (_pivots["leg_left"] as Node3D).rotation.x
	_knee_rest_x = (_pivots["knee_left"] as Node3D).rotation.x
	_ankle_rest_x = (_pivots["ankle_left"] as Node3D).rotation.x
	_arm_rest_x = (_pivots["arm_left"] as Node3D).rotation.x
	_elbow_rest_z_left = (_pivots["elbow_left"] as Node3D).rotation.z
	_elbow_rest_z_right = (_pivots["elbow_right"] as Node3D).rotation.z

	_terrain = get_node_or_null("../Terrain")
	if _terrain != null and _terrain.has_method("get_mesh_height"):
		global_position.y = _terrain.get_mesh_height(global_position.x, global_position.z)
	_roam_center = Vector2(global_position.x, global_position.z)
	_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)

	if parkour_collision:
		_build_parkour_collision()
	else:
		_collision_shape = CollisionShape3D.new()
		var collider := CapsuleShape3D.new()
		collider.radius = 0.35 * display_scale
		collider.height = 1.5 * display_scale
		_collision_shape.shape = collider
		_collision_shape.position = Vector3(0, 0.9 * display_scale, 0)
		add_child(_collision_shape)
	collision_layer = 1
	collision_mask = 0

	Interactable.attach(
		self, "Talk", INTERACT_RADIUS, _on_talk,
		func(body: Node3D) -> void: _look_target = body,
		func(body: Node3D) -> void:
			if _look_target == body:
				_look_target = null
	)


func _on_talk() -> void:
	var line: String = talk_lines[_rng.randi_range(0, talk_lines.size() - 1)]
	var actions: Array[Dictionary] = []
	if dialog_actions_provider.is_valid():
		actions.assign(dialog_actions_provider.call() as Array)
	DialogUI.show_line(display_name, line, actions)


## See jungle_villager.gd's own unmount-equivalent reasoning: clears
## _mounted_on so _process()'s own branch falls through to the ordinary
## roam/animate_walk path next frame, exactly as if this instance had never
## been mounted -- used once the quest-giving ape hands Manchego over (see
## jungle_kingdom_village.gd), so he becomes a normal roaming village NPC
## afterward rather than vanishing.
func unmount() -> void:
	_mounted_on = null
	collision_layer = 1
	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", false)
	_roam_center = Vector2(global_position.x, global_position.z)


func _process(delta: float) -> void:
	EyeBlink.apply(_eye_blink, delta, _eyes)
	if is_instance_valid(_mounted_on):
		_apply_mounted_pose()
	else:
		var moving := _update_roam(delta)
		_animate_walk(delta, moving)
		_update_head_look(delta)
	if parkour_collision:
		_sync_parkour_collision()
	if has_tail:
		MonkeyFigure._rebuild_tail(_pivots["_tail"] as Dictionary, delta)


## Same atan2(x, z)/clamp/lerp_angle pattern jungle_villager.gd's/npc.gd's own
## _update_head_look() already use for their own head pivots -- not run while
## mounted (an ape riding Manchego keeps facing forward, matching how the
## mounted pose otherwise ignores _look_target entirely).
func _update_head_look(delta: float) -> void:
	var head: Node3D = _pivots["head"]
	var target_yaw := 0.0
	if _look_target != null:
		var head_parent := head.get_parent()
		var local_target: Vector3 = head_parent.global_transform.affine_inverse() * _look_target.global_position
		var dir := local_target - head.position
		target_yaw = clampf(atan2(dir.x, dir.z), -HEAD_YAW_LIMIT, HEAD_YAW_LIMIT)
	head.rotation.y = lerp_angle(head.rotation.y, target_yaw, HEAD_TURN_SPEED * delta)


## The world-space position of the very top of the head mesh -- e.g. for
## primate_kingdom_gorilla.gd's own Special Banana pickup, which needs to
## sit exactly on top of the giant gorilla's own head regardless of his
## pose (this rig's own default forward lean skews a "just guess a height
## above the ground" calculation badly), scale, or head_height_scale.
## Reads the head mesh's own actual built AABB, transformed through its
## live global_transform, rather than re-deriving a height from
## ProceduralFigure/ApeTemplate's own private size constants -- same
## "stay correct even if the formula changes" reasoning ape_template.gd's
## own neck-height code already uses (see that file's own comment on
## neck_half_height) for reading a mesh's real built size instead of
## assuming it.
func get_head_top_global_position() -> Vector3:
	var head_pivot: Node3D = _pivots["head"]
	var head_mesh := head_pivot.get_child(0) as MeshInstance3D
	if head_mesh == null or head_mesh.mesh == null:
		return head_pivot.global_position
	var local_aabb := head_mesh.mesh.get_aabb()
	var center := local_aabb.get_center()
	var local_top := Vector3(center.x, local_aabb.position.y + local_aabb.size.y, center.z)
	return head_mesh.global_transform * local_top


## Seats this figure on a live Manchego instance -- used both for the
## Primate Kingdom's real quest-giving ape (see jungle_kingdom_village.gd)
## and, before that, for main.gd's own now-removed debug mount review.
func mount_on(manchego: Manchego) -> void:
	_mounted_on = manchego
	collision_layer = 0
	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", true)
	_apply_mounted_pose()


func _apply_mounted_pose() -> void:
	if not is_instance_valid(_mounted_on):
		return
	var leg_left := _pivots["leg_left"] as Node3D
	var leg_right := _pivots["leg_right"] as Node3D
	var knee_left := _pivots["knee_left"] as Node3D
	var knee_right := _pivots["knee_right"] as Node3D
	var ankle_left := _pivots["ankle_left"] as Node3D
	var ankle_right := _pivots["ankle_right"] as Node3D
	var arm_left := _pivots["arm_left"] as Node3D
	var arm_right := _pivots["arm_right"] as Node3D
	var elbow_left := _pivots["elbow_left"] as Node3D
	var elbow_right := _pivots["elbow_right"] as Node3D

	leg_left.rotation.x = -MOUNT_HIP_BEND
	leg_right.rotation.x = -MOUNT_HIP_BEND
	leg_left.rotation.z = signf(leg_left.position.x) * MOUNT_HIP_SPLAY
	leg_right.rotation.z = signf(leg_right.position.x) * MOUNT_HIP_SPLAY
	knee_left.rotation.x = MOUNT_KNEE_BEND
	knee_right.rotation.x = MOUNT_KNEE_BEND
	# The standing ankle counter-bend belongs to ApeTemplate's crouch. Once
	# the mounted hip and knee cancel into a downward shin, neutral ankles
	# let the feet hang naturally toward the ground.
	ankle_left.rotation.x = 0.0
	ankle_right.rotation.x = 0.0
	arm_left.rotation.x = -MOUNT_ARM_FORWARD
	arm_right.rotation.x = -MOUNT_ARM_FORWARD
	elbow_left.rotation.z = -signf(arm_left.position.x) * MOUNT_ELBOW_INWARD
	elbow_right.rotation.z = -signf(arm_right.position.x) * MOUNT_ELBOW_INWARD

	# Follow Manchego's animated seat basis, then translate by the exact
	# remaining difference between the ape's pelvis bottom and the seat.
	var seat_transform := _mounted_on.get_seat_transform()
	global_transform = Transform3D(seat_transform.basis, global_position)
	var hip_bottom := _pivots["hip_bottom"] as Node3D
	global_position += seat_transform.origin - hip_bottom.global_position


func _update_roam(delta: float) -> bool:
	var here := Vector2(global_position.x, global_position.z)
	var moving := false
	if _has_wander_target and here.distance_to(_wander_target) > ROAM_ARRIVE_DISTANCE:
		moving = true
	elif _has_wander_target:
		_has_wander_target = false
		_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)
	else:
		_pause_timer -= delta
		if _pause_timer <= 0.0:
			_pick_new_wander_target()

	if moving:
		var to_target := _wander_target - here
		var step := to_target.limit_length(_move_speed * delta)
		var new_pos := here + step
		if to_target.length() > 0.01:
			var target_angle := atan2(to_target.x, to_target.y)
			rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)
		global_position.x = new_pos.x
		global_position.z = new_pos.y

	if _terrain != null and _terrain.has_method("get_mesh_height"):
		var ground_h: float = _terrain.get_mesh_height(global_position.x, global_position.z)
		global_position.y = move_toward(global_position.y, ground_h, GROUND_SETTLE_SPEED * delta)
	return moving


func _pick_new_wander_target() -> void:
	var angle := _rng.randf_range(0.0, TAU)
	var r := roam_radius * sqrt(_rng.randf())
	_wander_target = _roam_center + Vector2(cos(angle), sin(angle)) * r
	_has_wander_target = true


## Kova's collision follows the same articulated landmark body the player
## sees. Capsule chains give every limb and the torso continuous, standable
## surfaces while a head sphere supplies the quest's final parkour platform.
## Lower-arm segments end at "hand_left"/"hand_right" -- ApeTemplate.build()'s
## own pivots dict has no separate fingertip marker the way ProceduralFigure's
## human rig does (WristAttach/FingertipAttach), so an earlier pass reaching
## for "fingertip_left"/"fingertip_right" here was indexing a key that never
## existed, silently returning null and crashing the very first
## _sync_parkour_collision() call (global_position on a null Node3D) the
## instant any ape/monkey set parkour_collision -- confirmed by reading
## ApeTemplate.build()'s own returned dict, not observed in-engine.
func _build_parkour_collision() -> void:
	_add_segment_collider("TorsoCollision", _pivots["hips"], _pivots["head"], 0.28 * display_scale)
	_add_segment_collider("LeftUpperArmCollision", _pivots["arm_left"], _pivots["elbow_left"], 0.10 * display_scale)
	_add_segment_collider("LeftLowerArmCollision", _pivots["elbow_left"], _pivots["hand_left"], 0.09 * display_scale)
	_add_segment_collider("RightUpperArmCollision", _pivots["arm_right"], _pivots["elbow_right"], 0.10 * display_scale)
	_add_segment_collider("RightLowerArmCollision", _pivots["elbow_right"], _pivots["hand_right"], 0.09 * display_scale)
	_add_segment_collider("LeftUpperLegCollision", _pivots["leg_left"], _pivots["knee_left"], 0.13 * display_scale)
	_add_segment_collider("LeftLowerLegCollision", _pivots["knee_left"], _pivots["ankle_left"], 0.11 * display_scale)
	_add_segment_collider("RightUpperLegCollision", _pivots["leg_right"], _pivots["knee_right"], 0.13 * display_scale)
	_add_segment_collider("RightLowerLegCollision", _pivots["knee_right"], _pivots["ankle_right"], 0.11 * display_scale)

	var head_mesh := (_pivots["head"] as Node3D).get_child(0) as MeshInstance3D
	var head_shape := CollisionShape3D.new()
	head_shape.name = "HeadCollision"
	var sphere := SphereShape3D.new()
	var head_box := head_mesh.get_aabb()
	sphere.radius = maxf(head_box.size.x, maxf(head_box.size.y, head_box.size.z)) * 0.5 * display_scale
	head_shape.shape = sphere
	add_child(head_shape)
	_parkour_colliders.append({"shape": head_shape, "point": head_mesh})
	_sync_parkour_collision()


func _add_segment_collider(collider_name: String, start: Node3D, finish: Node3D, radius: float) -> void:
	var collision := CollisionShape3D.new()
	collision.name = collider_name
	var capsule := CapsuleShape3D.new()
	capsule.radius = radius
	capsule.height = radius * 2.0
	collision.shape = capsule
	add_child(collision)
	_parkour_colliders.append({"shape": collision, "start": start, "finish": finish, "radius": radius})


func _sync_parkour_collision() -> void:
	for entry in _parkour_colliders:
		var collision := entry["shape"] as CollisionShape3D
		if entry.has("point"):
			var point := entry["point"] as Node3D
			collision.position = to_local(point.global_position)
			continue
		var start := entry["start"] as Node3D
		var finish := entry["finish"] as Node3D
		var local_start := to_local(start.global_position)
		var local_finish := to_local(finish.global_position)
		var span := local_finish - local_start
		var radius := entry["radius"] as float
		var capsule := collision.shape as CapsuleShape3D
		capsule.height = maxf(span.length() + radius * 2.0, radius * 2.0)
		collision.position = (local_start + local_finish) * 0.5
		if span.length_squared() > 0.0001:
			collision.quaternion = Quaternion(Vector3.UP, span.normalized())


func _animate_walk(delta: float, moving: bool) -> void:
	var leg_left := _pivots["leg_left"] as Node3D
	var leg_right := _pivots["leg_right"] as Node3D
	var knee_left := _pivots["knee_left"] as Node3D
	var knee_right := _pivots["knee_right"] as Node3D
	var ankle_left := _pivots["ankle_left"] as Node3D
	var ankle_right := _pivots["ankle_right"] as Node3D
	var arm_left := _pivots["arm_left"] as Node3D
	var arm_right := _pivots["arm_right"] as Node3D
	var elbow_left := _pivots["elbow_left"] as Node3D
	var elbow_right := _pivots["elbow_right"] as Node3D
	if moving:
		_walk_phase += delta * _swing_speed
		var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
		leg_left.rotation.x = _leg_rest_x + swing
		leg_right.rotation.x = _leg_rest_x - swing
		arm_left.rotation.x = _arm_rest_x - swing
		arm_right.rotation.x = _arm_rest_x + swing
		# Knee flex tied to each leg's own swing VELOCITY (cos of phase),
		# not position -- ported from player.gd's own walk cycle (see that
		# file's own comment: bending in step with position alone barely
		# reads as distinct from the swing itself). Same phase convention
		# as player.gd's already-confirmed left/right pairing (this rig's
		# leg_left uses +swing, matching player.gd's _leg_left, so the
		# same cos(phase+PI)/cos(phase) split applies unchanged) -- added
		# on top of this rig's own permanent crouch rest instead of
		# player.gd's near-straight rest.
		var left_knee_bump := maxf(0.0, cos(_walk_phase + PI)) * ProceduralFigure.KNEE_BEND_AMOUNT
		var right_knee_bump := maxf(0.0, cos(_walk_phase)) * ProceduralFigure.KNEE_BEND_AMOUNT
		knee_left.rotation.x = _knee_rest_x + left_knee_bump
		knee_right.rotation.x = _knee_rest_x + right_knee_bump
		ankle_left.rotation.x = _ankle_rest_x - swing * 0.3
		ankle_right.rotation.x = _ankle_rest_x + swing * 0.3
		# Elbow's own contribution to the stride, per direct correction: NOT
		# a forward/back bend (rotation.x, the original ported-from-player.
		# gd curve) any more -- the forearm now swings further INWARD
		# (toward the body) and back to resting instead, on rotation.z, the
		# same axis ELBOW_INWARD_ANGLE's own permanent rest pose already
		# uses (ape_template.gd's build()). "Further inward" = more of
		# whatever sign that rest pose already is, so multiplying by
		# signf(_elbow_rest_z_*) keeps this correct on both sides without
		# hardcoding which side is positive. rotation.x itself just stays
		# at rest the whole time now (also true in the idle branch below),
		# no longer animated during the stride at all. Reuses the same
		# forward_fraction shape (least at each arm's own backmost swing
		# point, most at its own forwardmost) and the same ELBOW_BEND_
		# AMOUNT magnitude the old curve used, just applied to a different
		# axis -- not visually confirmed.
		var right_forward_fraction := (1.0 - sin(_walk_phase)) * 0.5
		var left_forward_fraction := 1.0 - right_forward_fraction
		elbow_right.rotation.x = _elbow_rest_x
		elbow_left.rotation.x = _elbow_rest_x
		elbow_right.rotation.z = (
			_elbow_rest_z_right
			+ right_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT * signf(_elbow_rest_z_right)
		)
		elbow_left.rotation.z = (
			_elbow_rest_z_left
			+ left_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT * signf(_elbow_rest_z_left)
		)
	else:
		leg_left.rotation.x = lerp_angle(leg_left.rotation.x, _leg_rest_x, POSE_SETTLE_SPEED * delta)
		leg_right.rotation.x = lerp_angle(leg_right.rotation.x, _leg_rest_x, POSE_SETTLE_SPEED * delta)
		knee_left.rotation.x = lerp_angle(knee_left.rotation.x, _knee_rest_x, POSE_SETTLE_SPEED * delta)
		knee_right.rotation.x = lerp_angle(knee_right.rotation.x, _knee_rest_x, POSE_SETTLE_SPEED * delta)
		ankle_left.rotation.x = lerp_angle(ankle_left.rotation.x, _ankle_rest_x, POSE_SETTLE_SPEED * delta)
		ankle_right.rotation.x = lerp_angle(ankle_right.rotation.x, _ankle_rest_x, POSE_SETTLE_SPEED * delta)
		arm_left.rotation.x = lerp_angle(arm_left.rotation.x, _arm_rest_x, POSE_SETTLE_SPEED * delta)
		arm_right.rotation.x = lerp_angle(arm_right.rotation.x, _arm_rest_x, POSE_SETTLE_SPEED * delta)
		elbow_left.rotation.x = lerp_angle(elbow_left.rotation.x, _elbow_rest_x, POSE_SETTLE_SPEED * delta)
		elbow_right.rotation.x = lerp_angle(elbow_right.rotation.x, _elbow_rest_x, POSE_SETTLE_SPEED * delta)
		elbow_left.rotation.z = lerp_angle(elbow_left.rotation.z, _elbow_rest_z_left, POSE_SETTLE_SPEED * delta)
		elbow_right.rotation.z = lerp_angle(elbow_right.rotation.z, _elbow_rest_z_right, POSE_SETTLE_SPEED * delta)
