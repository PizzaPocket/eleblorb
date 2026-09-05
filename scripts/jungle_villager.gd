class_name JungleVillager
extends StaticBody3D

## Ambient primate villager populating the primate kingdom's treehouse
## village (see jungle_kingdom_village.gd, which spawns these). A second
## primate species built on the same MonkeyFigure rig Xiao Hou Zi uses, but
## with a variant dict tuned per direct instruction, revised twice since the
## first pass: larger and taller, no yellow cheek dots, hips a bit closer
## together, limbs that taper less toward the hands/feet, no foot pads, and
## a torso that reads less sharply pear-shaped than Xiao Hou Zi's own. The
## heart-shaped face marking (dropped in the first pass) is back on, per
## direct correction, just with its center "widow's peak" dip softened
## toward a rounder top. Per a further correction, torsos and limbs are now
## elongated much more than the first pass's proportions, with a static
## forward stoop at the waist for a more ape-like posture. Height/limb
## length/tail length/fur color vary per instance within a fixed range --
## per direct instruction -- everything else about the variant (hip
## spacing, limb taper, body taper/height, markings, pads, waist bend) is a
## fixed species trait, not randomized.
##
## Unlike Xiao Hou Zi these are ambient wildlife with no join/possession
## mechanic -- just a "Talk" prompt -- and either a gentle ground-level roam
## or a fixed anchored pose (for the ones jungle_kingdom_village.gd plants on
## a treehouse deck) depending on the `roams` flag the spawner sets. Each
## instance now gets its own name and its own two lines from
## jungle_kingdom_village.gd's JUNGLE_VILLAGER_IDENTITIES, assigned before
## add_child the same way town_generator.gd's VILLAGER_IDENTITIES works for
## town villagers -- see that file's own comment for why a shared pool reads
## as generic instead of individuated. TALK_LINES below only fires as a
## fallback if a spawner forgets to assign display_name/talk_lines.

const INTERACT_RADIUS := 2.0
const HEAD_YAW_LIMIT := deg_to_rad(70.0)
const HEAD_TURN_SPEED := 8.0

const ROAM_PAUSE_MIN := 2.0
const ROAM_PAUSE_MAX := 5.0
const ROAM_ARRIVE_DISTANCE := 0.3
const ROAM_MOVE_SPEED := 1.1
const ROTATION_SPEED := 5.0
const GROUND_SETTLE_SPEED := 8.0

const WALK_SWING_SPEED := 7.0
const WALK_SWING_AMOUNT := 0.5
const POSE_SETTLE_SPEED := 8.0

## Fallback only -- see class doc comment above. Normal spawns overwrite
## talk_lines (and display_name) with an identity from
## jungle_kingdom_village.gd before add_child.
const TALK_LINES := [
	"The elders keep to the tallest trees. The rest of us just try to keep our footing.",
	"Mind the ramps after rain -- they get slick where the bark's worn smooth.",
	"Xiao Hou Zi? Down in the lowland jungle, last I heard. Always wandering off.",
	"We don't get many visitors up here. Most people can't climb this high.",
	"Watch your step past the third landing. That one's been loose for a season.",
]

## Fur color palette per direct instruction -- "a range of monkey fur
## colors from dark charcoal to grey to light grey to shades of brown."
const FUR_COLORS := [
	Color(0.14, 0.13, 0.13),
	Color(0.22, 0.21, 0.21),
	Color(0.42, 0.41, 0.40),
	Color(0.62, 0.61, 0.59),
	Color(0.55, 0.42, 0.28),
	Color(0.40, 0.28, 0.16),
	Color(0.26, 0.18, 0.11),
]
## Per further direct correction: choosing between just the one default
## sandy tone and one dark alternative read as "almost exactly the same"
## across a batch of villagers -- now picks from MonkeyFigure's own shared
## MARKING_COLOR_PALETTE instead (see that constant's own doc comment for
## why it's centralized there rather than duplicated here).

## This is monkeys' own MAXIMUM size (villagers, this class -- Xiao Hou Zi
## is a separate "stuffed animal monkey" class of his own, not part of
## this size contract) -- per direct instruction, apes (ApeTemplate) have
## a MINIMUM size instead, without much overlap between the two. In real
## rendered terms this reads as roughly 0.6-0.8m tall at this range's own
## max, well under main.gd's own APE_DEBUG_SCALE_MIN (roughly 1.7m even at
## ITS minimum) -- see that constant's own doc comment for the full
## MonkeyFigure-vs-ProceduralFigure reference-height derivation, since the
## two rigs' own "scale" units aren't comparable directly.
const DISPLAY_SCALE_MIN := 2.55
const DISPLAY_SCALE_MAX := 3.15
## Bumped well past the original 1.2-1.45 range -- per direct feedback the
## limbs should read as "much more elongated," not just somewhat longer.
const LIMB_LENGTH_SCALE_MIN := 1.6
const LIMB_LENGTH_SCALE_MAX := 1.9
const TAIL_LENGTH_SCALE_MIN := 0.8
const TAIL_LENGTH_SCALE_MAX := 1.3

## Fixed species traits -- not randomized per instance, see this file's own
## class doc comment for which is which.
const HIP_SCALE := 0.8
const LIMB_TAPER_SCALE := 0.3
## Lowered further (from 0.55) -- per direct feedback the lower body still
## read as too thick/pear-shaped; more uniform top-to-bottom width now.
const BODY_TAPER_BLEND := 0.4
## Per direct feedback: torsos "much more elongated" (raised again from an
## already-elongated 1.55) and "slightly thinner," plus a forward stoop at
## the waist (see MonkeyFigure.build()'s own variant doc comment for
## spine_forward_bend's rotation-sign reasoning).
const BODY_HEIGHT_SCALE := 1.7
const BODY_RADIUS_SCALE := 0.85
## Brought down from an initial 16 degrees per direct correction ("adjust
## those guys so that they don't lean forward so much").
const SPINE_FORWARD_BEND := deg_to_rad(8.0)
## How far the arms counter-rotate past merely canceling the waist bend --
## per direct feedback the arms were left "pulled back toward their hips"
## once the waist gained its forward stoop, instead of relaxing forward
## with gravity. See MonkeyFigure._build_arm()'s own doc comment for why a
## positive spine bend needs a NEGATIVE shoulder counter-rotation, and by
## more than just the cancelling amount, to swing the arm forward of
## vertical rather than just back to it. Brought down from an initial 0.35
## alongside SPINE_FORWARD_BEND's own reduction above, per the same direct
## correction ("adjust their resting arm angle accordingly") -- the
## formula (arm_rest_x = -SPINE_FORWARD_BEND*(1+this)) already shrinks the
## arm's own absolute rest angle proportionally as the lean itself shrinks,
## but a real relaxed arm hang isn't purely proportional to torso lean, so
## this fraction itself was retuned too rather than just left to inherit.
const ARM_FORWARD_RELAX_FACTOR := 0.2
## Per direct follow-up ("make sure the forward lean of the monkeys is also
## offset similarly to their lean") -- the head must counter-rotate against
## SPINE_FORWARD_BEND the same way the arms do, or it inherits the spine's
## own forward tilt and stares at the ground. 0.25 tilts it a bit past
## level, an alert upward look rather than a merely neutral one.
const HEAD_TILT_FACTOR := 0.25
## Raised from 0.72 -- per direct feedback to raise the shoulders up the
## body.
const SHOULDER_HEIGHT_FRACTION := 0.80
## Raised from the 0.2 default that reproduces Xiao Hou Zi's own stubby
## attachment -- per direct feedback the leg's own top was starting below
## the body instead of tucking into its hip bulge; this seats it deeper in
## (BlorbBodyShape's own profile peaks around t=0.3 of body_height) and, as
## a direct consequence (ankle/knee stay put, only the top rises), reads as
## a longer leg too -- a wanted side effect per that same feedback.
const HIP_ATTACH_RAISE_FRACTION := 0.42
## Per direct feedback: "the legs can be a bit thinner than they are now."
const LEG_RADIUS_SCALE := 0.78
## Per direct feedback: head "a bit more elongated" than Xiao Hou Zi's own
## squat shape -- mostly a vertical stretch, small depth bump for a less
## flat profile, width left alone. _face_marking_point()/_muzzle_point()/
## _add_eyes() all take this same head_size so the mask, muzzle, and eyes
## stay flush on the resized surface -- see MonkeyFigure.build()'s own
## "head_size_scale" doc comment.
const HEAD_SIZE_SCALE := Vector3(1.0, 1.35, 1.08)
## Per direct feedback: eyes should be "a more superellipse shape, slightly
## oblong" instead of Xiao Hou Zi's own perfect circle -- x_scale/y_scale
## widen the eye horizontally more than they narrow it vertically (a
## gentle oblong, not a slit), epsilon above 2.0 (a true ellipse) softens
## the corners toward a rounder superellipse instead of a sharper lens.
const EYE_SHAPE := {"x_scale": 1.15, "y_scale": 0.88, "epsilon": 2.4}
## Restored per direct correction (an earlier pass dropped this entirely) --
## keep the heart-shaped marking but soften its "widow's peak" center dip.
## Cheek dots stay off; that removal was correct.
const FACE_MARKING_NOTCH_STRENGTH := 0.5

## Set by jungle_kingdom_village.gd before/at spawn -- false plants this
## villager motionless at wherever it was positioned (a treehouse deck or
## doorway); true lets it wander _roam_center/_roam_radius on the ground.
@export var roams: bool = true
@export var roam_center: Vector2 = Vector2.ZERO
@export var roam_radius: float = 14.0
## Set by jungle_kingdom_village.gd before add_child, one unused identity per
## instance -- see class doc comment above and TALK_LINES' own comment.
@export var display_name: String = "Jungle Villager"
var talk_lines: Array[String] = []

var _pivots: Dictionary
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()
var _look_target: Node3D = null
var _rng := RandomNumberGenerator.new()
var _terrain: Node
## Captured from the freshly-built rig, not hardcoded to 0.0 -- MonkeyFigure.
## build() gives the shoulder its own rest rotation.x to counter (and
## relax past) SPINE_FORWARD_BEND (see that function's own doc comment on
## arm_forward_relax_factor); _animate_walk() below must idle/swing around
## THIS rest value, not world-vertical, or its own idle lerp toward a
## hardcoded 0.0 would slowly undo that rest pose back to "pulled back
## toward the hips" every time the villager stops moving.
var _arm_rest_x := 0.0

var _wander_target: Vector2
var _has_wander_target := false
var _pause_timer := 0.0
var _walk_phase := 0.0


func _ready() -> void:
	_rng.randomize()
	var fur_color: Color = FUR_COLORS[_rng.randi() % FUR_COLORS.size()]
	var marking_color: Color = MonkeyFigure.MARKING_COLOR_PALETTE[
		_rng.randi() % MonkeyFigure.MARKING_COLOR_PALETTE.size()
	]
	var display_scale := _rng.randf_range(DISPLAY_SCALE_MIN, DISPLAY_SCALE_MAX)
	var variant := {
		"has_cheek_dots": false,
		"has_face_marking": true,
		"face_marking_notch_strength": FACE_MARKING_NOTCH_STRENGTH,
		"marking_color": marking_color,
		"hip_scale": HIP_SCALE,
		"limb_length_scale": _rng.randf_range(LIMB_LENGTH_SCALE_MIN, LIMB_LENGTH_SCALE_MAX),
		"limb_taper_scale": LIMB_TAPER_SCALE,
		"leg_radius_scale": LEG_RADIUS_SCALE,
		"has_foot_pads": false,
		"body_height_scale": BODY_HEIGHT_SCALE,
		"body_radius_scale": BODY_RADIUS_SCALE,
		"spine_forward_bend": SPINE_FORWARD_BEND,
		"arm_forward_relax_factor": ARM_FORWARD_RELAX_FACTOR,
		"head_tilt_factor": HEAD_TILT_FACTOR,
		"shoulder_height_fraction": SHOULDER_HEIGHT_FRACTION,
		"hip_attach_raise_fraction": HIP_ATTACH_RAISE_FRACTION,
		"body_taper_blend": BODY_TAPER_BLEND,
		"tail_length_scale": _rng.randf_range(TAIL_LENGTH_SCALE_MIN, TAIL_LENGTH_SCALE_MAX),
		"head_size_scale": HEAD_SIZE_SCALE,
		"eye_shape": EYE_SHAPE,
	}
	_pivots = MonkeyFigure.build(self, fur_color, display_scale, variant)
	_eyes = _pivots["eyes"]
	_arm_rest_x = (_pivots["arm_left"] as Node3D).rotation.x
	_terrain = get_node_or_null("../Terrain")
	if roams and _terrain != null and _terrain.has_method("get_mesh_height"):
		global_position.y = _terrain.get_mesh_height(global_position.x, global_position.z)
	_pause_timer = _rng.randf_range(ROAM_PAUSE_MIN, ROAM_PAUSE_MAX)

	var collision_shape := CollisionShape3D.new()
	var collider := SphereShape3D.new()
	collider.radius = 0.09 * display_scale
	collision_shape.shape = collider
	collision_shape.position = Vector3(0, 0.1 * display_scale, 0)
	add_child(collision_shape)
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
	var lines := talk_lines if not talk_lines.is_empty() else TALK_LINES
	DialogUI.show_line(display_name, lines[_rng.randi_range(0, lines.size() - 1)])


func _process(delta: float) -> void:
	EyeBlink.apply(_eye_blink, delta, _eyes)
	_update_head_look(delta)
	var moving := false
	if roams:
		moving = _update_roam(delta)
	_animate_walk(delta, moving)
	MonkeyFigure.rebuild_limbs(_pivots, self, delta)


func _update_head_look(delta: float) -> void:
	var head: Node3D = _pivots["head"]
	var target_yaw := 0.0
	if _look_target != null:
		var head_parent := head.get_parent()
		var local_target: Vector3 = head_parent.global_transform.affine_inverse() * _look_target.global_position
		var dir := local_target - head.position
		# Same atan2(x, z) convention npc.gd's/xiao_hou_zi.gd's own head
		# tracking uses -- see xiao_hou_zi.gd's identical _update_head_look().
		target_yaw = clampf(atan2(dir.x, dir.z), -HEAD_YAW_LIMIT, HEAD_YAW_LIMIT)
	head.rotation.y = lerp_angle(head.rotation.y, target_yaw, HEAD_TURN_SPEED * delta)


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
		var step := to_target.limit_length(ROAM_MOVE_SPEED * delta)
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
	_wander_target = roam_center + Vector2(cos(angle), sin(angle)) * r
	_has_wander_target = true


func _animate_walk(delta: float, moving: bool) -> void:
	var leg_left: Node3D = _pivots["leg_left"]
	var leg_right: Node3D = _pivots["leg_right"]
	var arm_left: Node3D = _pivots["arm_left"]
	var arm_right: Node3D = _pivots["arm_right"]
	if moving:
		_walk_phase += delta * WALK_SWING_SPEED
		var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
		leg_left.rotation.x = swing
		leg_right.rotation.x = -swing
		# Swings around _arm_rest_x, not 0.0 -- see that var's own comment.
		arm_left.rotation.x = _arm_rest_x - swing
		arm_right.rotation.x = _arm_rest_x + swing
	else:
		leg_left.rotation.x = lerp_angle(leg_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		leg_right.rotation.x = lerp_angle(leg_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
		arm_left.rotation.x = lerp_angle(arm_left.rotation.x, _arm_rest_x, POSE_SETTLE_SPEED * delta)
		arm_right.rotation.x = lerp_angle(arm_right.rotation.x, _arm_rest_x, POSE_SETTLE_SPEED * delta)
