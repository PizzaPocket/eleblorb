extends StaticBody3D

## Wanders idly around a fixed center point, alternating standing still and
## walking to a random nearby spot.
##
## The figure is built procedurally at spawn time (see _build_figure(),
## ProceduralFigure.build()) rather than loaded from an imported asset --
## body_scale/skin_color give town_generator.gd a way to vary NPCs visually
## (replacing the old per-instance Kenney figurine variant picks) without a
## second rig implementation.

## Set by town_generator.gd per spawn for visual variety -- see its
## NPC_FEMALE_BODY_SCALES/NPC_MALE_BODY_SCALES/NPC_SKIN_COLORS/
## NPC_SHIRT_COLORS/NPC_PANTS_COLORS/NPC_SHOE_COLORS/NPC_*_CHEST_BUILD_SCALES/
## NPC_*_HIP_BUILD_SCALES/NPC_ABDOMEN_WIDTH_SCALES/
## NPC_SLEEVELESS_CHANCE/NPC_SHORT_SLEEVE_CHANCE.
@export var body_scale: float = 1.0
@export var skin_color: Color = ProceduralFigure.SKIN_COLOR
@export var shirt_color: Color = ProceduralFigure.SKIN_COLOR
@export var pants_color: Color = ProceduralFigure.SKIN_COLOR
@export var shoe_color: Color = Color(0.32, 0.12, 0.06)
## One of ProceduralFigure's SLEEVE_STYLE_LONG/SLEEVE_STYLE_SHORT/
## SLEEVE_STYLE_NONE constants -- see town_generator.gd's
## _assign_figure_variant() for how this gets picked per spawn.
@export var sleeve_style: String = ProceduralFigure.SLEEVE_STYLE_LONG
## Chest and hip width-depth variance are separate knobs (not one shared
## build_scale) and abdomen width-depth variance is a much wider range --
## 1.0 is the skinny/base end, never smaller, only broader -- see
## ProceduralFigure.build()'s own params of the same name for the full
## reasoning, including why chest/hip split (only males get broad chests;
## females tend wider in the hips instead) and why leg width always
## follows hip_build_scale specifically.
@export var chest_build_scale: float = 1.0
@export var hip_build_scale: float = 1.0
@export var abdomen_width_scale: float = 1.0
## Hair variety -- see town_generator.gd's NPC_HAIR_COLORS/NPC_HAIR_STYLES
## and _assign_figure_variant() for how these get picked per spawn
## (hair_style is one of FigureHair's STYLE_* string constants; is_female
## gates eligibility for FigureHair.STYLE_BUN specifically, and comes from
## VILLAGER_IDENTITIES via _assign_villager_identity() rather than being
## picked here). hair_length_variance only matters for STYLE_LONG.
@export var hair_color: Color = FigureHair.DEFAULT_HAIR_COLOR
@export var hair_style: String = FigureHair.STYLE_BUZZCUT
@export var hair_length_variance: float = 0.0
## Optional lensless superellipse frames. Assignment is left to NPC
## generators/authored instances so glasses can be selected independently
## from hair and body variants.
@export var has_glasses: bool = false
@export var is_female: bool = false
## Optional reusable dress garment. Dress wearers build their articulated leg
## segments in skin color, recolor the hips to dress_color, and add a rounded-
## crown/flat-hem superegg skirt through FigureDress.
@export var wears_dress: bool = false
@export var dress_color: Color = Color(0.0, 0.0, 0.0, 0.0)
## Skips all wander/idle-cycle behavior and just stands facing
## facing_degrees -- for NPCs planted at a fixed spot, like a vendor
## manning a stall.
@export var stationary: bool = false
@export var facing_degrees: float = 0.0
## Swaps in vendor_lines below instead of talk_lines, and adds the
## "Browse Wares" dialog action -- set true on stall vendors (see
## town_generator.gd's _build_shop_stall).
@export var is_vendor: bool = false
## Shown as the speaker name in DialogUI.
@export var display_name: String = "Villager"
## This NPC's own lines, set per-instance by town_generator.gd (see its
## VILLAGER_IDENTITIES) rather than drawn from one pool every villager
## shares -- sharing a pool was the actual bug behind villagers not
## reading as independent people, not anything about the figure/rig work.
## Ignored when is_vendor is true (vendor_lines below is used instead).
@export var talk_lines: Array[String] = ["..."]
## Shop-flavored talk lines, set per-instance by town_generator.gd -- one
## stall vendor per shop_category, each with its own flavor. Defaults to
## the antique dealer's own lines so nothing else needs to set this
## explicitly.
@export var vendor_lines: Array[String] = [
	"Welcome, welcome. Everything in here's older than it looks. Myself included.",
	"That fire gem isn't cheap, but it's the real thing. Whatever's cheap on gems around here usually isn't.",
	"The compass hasn't pointed north once since I've owned it. Stopped trying to fix it years ago.",
	"Don't ask me to open the locket. Believe me, I've tried.",
]
## Which ShopCatalog "shop" category this vendor's "Browse Wares" action
## opens (see ShopCatalog.get_items_for_shop()) -- antique/red/green.
@export var shop_category: String = "antique"
## Set by floating-platform settlements. Ordinary NPCs keep sampling terrain.
@export var fixed_ground_y: float = INF

const INTERACT_RADIUS := 2.0
# Same axial range of motion as player.gd's head tracking -- ~80 deg each
# way. No pitch limit needed: NPCs only turn to look, they don't tilt.
const HEAD_YAW_LIMIT := deg_to_rad(80.0)
const HEAD_TURN_SPEED := 10.0

const MOVE_SPEED := 1.4
const WANDER_RADIUS := 9.0
const ARRIVE_DISTANCE := 0.3
const ROTATION_SPEED := 6.0
const WALK_SWING_SPEED := 7.0
const WALK_SWING_AMOUNT := 0.5
const POSE_SETTLE_SPEED := 8.0
# Fountain/stalls/buildings/lanterns are all on collision layer 1 -- a
# candidate wander target is only accepted if a straight raycast to it
# doesn't hit any of that, so NPCs stop picking spots that walk them
# straight through the fountain.
const OBSTACLE_MASK := 1
const PATH_CHECK_HEIGHT := 0.9
const PATH_CHECK_LOW := 0.35
const PATH_CHECK_ATTEMPTS := 6

enum State { IDLE, WALK }

## Set by town_generator.gd right after instancing, before add_child() --
## NPCs now spawn under Town's regenerated "Generated" container, whose
## nesting depth isn't a fixed relative path town_generator.gd can rely on
## staying constant. Falls back to the old relative lookup for an npc.tscn
## dropped directly into a scene by hand, one level under something with a
## "Terrain" sibling.
# `terrain` is a built-in engine property name on some physics-node paths;
# using it for the injected world reference prevents assignment on packed NPC
# instances. Keep the world reference explicitly named instead.
var terrain_ref: Node = null


## Packed NPC scenes expose their script methods reliably during procedural
## generation; inject the world surface through this API rather than a dynamic
## property assignment before the instance has entered the scene tree.
func set_terrain_reference(world_terrain: Node) -> void:
	terrain_ref = world_terrain
@onready var visuals: Node3D = $Visuals

var _leg_left: Node3D
var _leg_right: Node3D
var _arm_left: Node3D
var _arm_right: Node3D
var _knee_left: Node3D
var _knee_right: Node3D
var _elbow_left: Node3D
var _elbow_right: Node3D
var _spine: Node3D
var _head: Node3D
var _hips: Node3D
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()
var _look_target: Node3D = null
## _spine's own local Y at rest -- see player.gd's identical
## _spine_rest_y for why this is cached rather than assumed to be 0.0.
var _spine_rest_y: float = 0.0
## Same idea, for the hips -- see player.gd's identical _hips_rest_y for
## why the walk-cycle body dip moves the hips together with the spine.
var _hips_rest_y: float = 0.0
## Idle-pose variety, re-rolled on every _enter_idle() -- see player.gd's
## own identical fields and IDLE_* consts for the full reasoning (shared
## rig, same idea, just re-rolled off this file's own State.IDLE
## transition instead of a velocity-based moving/idle check).
var _idle_elbow_left: float = 0.0
var _idle_elbow_right: float = 0.0
var _idle_leg_variant_active: bool = false
var _idle_bent_leg_side: float = 1.0
var _idle_knee_bend: float = 0.0

# See player.gd's own SPINE_LEAN_MAX_WALK -- same forward-lean-while-walking
# treatment, just using MOVE_SPEED (this file's own walk speed constant)
# for the proportional ramp instead of move_speed. NPCs only ever walk (no
# sprint state), so this matches player.gd's walking lean, not its running
# one.
const SPINE_LEAN_MAX := deg_to_rad(3.0)

# See player.gd's own identical consts for the full reasoning (a shared
# rig gets a shared idle-pose treatment).
const IDLE_ELBOW_MIN := deg_to_rad(3.0)
const IDLE_ELBOW_MAX := deg_to_rad(9.0)
const IDLE_LEG_VARIANT_CHANCE := 0.5
const IDLE_KNEE_MIN := deg_to_rad(6.0)
const IDLE_KNEE_MAX := deg_to_rad(14.0)
const IDLE_HIP_OUTWARD_ANGLE := deg_to_rad(5.0)
const IDLE_HIP_EXTERNAL_ROTATION := deg_to_rad(12.0)
const IDLE_HIP_DROP_ANGLE := deg_to_rad(4.0)

var _state: State = State.IDLE
var _state_timer: float = 0.0
var _target: Vector2
var _wander_center: Vector2
var _walk_phase: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("npcs")
	if terrain_ref == null:
		terrain_ref = get_node("../../Terrain")
	_rng.randomize()
	_build_figure()

	_wander_center = Vector2(global_position.x, global_position.z)
	# get_mesh_height(), not get_height() -- matches the exact rendered/
	# collision surface rather than the raw continuous noise function,
	# which can visibly disagree with it between the terrain's ~8m grid
	# vertices (see terrain_generator.gd's get_mesh_height() doc comment).
	global_position.y = fixed_ground_y if fixed_ground_y < INF else terrain_ref.get_mesh_height(global_position.x, global_position.z)

	Interactable.attach(
		self,
		"Talk",
		INTERACT_RADIUS,
		_on_talk,
		func(body: Node3D) -> void: _look_target = body,
		func(body: Node3D) -> void:
			if _look_target == body:
				_look_target = null
	)

	if stationary:
		visuals.rotation.y = deg_to_rad(facing_degrees)
		# This early return meant _enter_idle() below never ran for a
		# stationary NPC (the vendor), so _roll_idle_pose() never fired
		# either -- _idle_elbow_left/right and the rest stayed at their
		# default 0.0/false forever, which is why _physics_process's own
		# stationary-branch _settle_pose() call (see its comment) had
		# nothing but zeroes to ease toward. Called directly here, since
		# _enter_idle()'s other job (starting the wander state machine) is
		# meaningless for a character that never walks.
		_roll_idle_pose()
		return

	_enter_idle()


## Exact gameplay height used when a player or blorb lands on this figure's
## head. The radial gate prevents a torso/shoulder collision from counting
## as a head bounce.
func head_bounce_surface_height_at(world_x: float, world_z: float) -> Variant:
	var radius := 0.34 * body_scale
	if Vector2(world_x - global_position.x, world_z - global_position.z).length() > radius:
		return null
	return global_position.y + 1.9 * body_scale


func _build_figure() -> void:
	var leg_color: Color = skin_color if wears_dress else pants_color
	var pivots := ProceduralFigure.build(
		visuals, skin_color, shirt_color, leg_color, sleeve_style,
		body_scale, chest_build_scale, hip_build_scale, abdomen_width_scale,
		Color(0.0, 0.0, 0.0, 0.0),  # chest_emblem_color -- NPCs don't get one, only the hero does
		hair_color, hair_style, hair_length_variance, shoe_color,
		false,  # skeleton_mode
		has_glasses
	)
	_leg_left = pivots["leg_left"]
	_leg_right = pivots["leg_right"]
	_arm_left = pivots["arm_left"]
	_arm_right = pivots["arm_right"]
	_knee_left = pivots["knee_left"]
	_knee_right = pivots["knee_right"]
	_elbow_left = pivots["elbow_left"]
	_elbow_right = pivots["elbow_right"]
	_spine = pivots["spine"]
	_spine_rest_y = _spine.position.y
	_head = pivots["head"]
	_eyes = pivots["eyes"]
	_hips = pivots["hips"]
	_hips_rest_y = _hips.position.y
	if wears_dress:
		var resolved_dress_color: Color = pants_color if is_zero_approx(dress_color.a) else dress_color
		FigureDress.add_to_figure(pivots["root"] if pivots.has("root") else visuals, _hips, resolved_dress_color, hip_build_scale)


func _on_talk() -> void:
	# Explicit : Array[String], not := -- a ternary's static type doesn't
	# get inferred as Array[String] even when both branches already are
	# one, so := here would type lines as Variant and trigger "type is
	# being inferred from a Variant value" as an error.
	var lines: Array[String] = vendor_lines if is_vendor else talk_lines
	var line: String = lines[_rng.randi_range(0, lines.size() - 1)]
	var actions: Array[Dictionary] = []
	if is_vendor:
		actions.append({
			"label": "Let me see your wares.",
			# Closes the dialog before opening the shop -- otherwise the
			# dialog's own modal push (from having an action button) stays
			# live underneath, and closing the shop alone leaves the game
			# still modal-locked with the mouse never re-captured.
			"callback": func():
				DialogUI.hide_dialog()
				ShopUI.open(ShopCatalog.get_items_for_shop(shop_category)),
		})
	DialogUI.show_line(display_name, line, actions)


func _process(delta: float) -> void:
	_update_head_look(delta)
	EyeBlink.apply(_eye_blink, delta, _eyes)


func _update_head_look(delta: float) -> void:
	var target_yaw := 0.0
	if _look_target != null:
		var head_parent := _head.get_parent()
		var local_target: Vector3 = head_parent.global_transform.affine_inverse() * _look_target.global_position
		var dir := local_target - _head.position
		# Matches the atan2(x, z) convention _process_walk already uses for
		# visuals.rotation.y -- local +Z is genuinely this rig's front (see
		# procedural_figure.gd/figure_eyes.gd: there's no imported-model
		# ancestor rotation to compensate for anymore, unlike the old
		# figure.glb-based rig this replaced).
		target_yaw = clampf(atan2(dir.x, dir.z), -HEAD_YAW_LIMIT, HEAD_YAW_LIMIT)
	_head.rotation.y = lerp_angle(_head.rotation.y, target_yaw, HEAD_TURN_SPEED * delta)
	# Deliberately no pitch (rotation.x) here -- NPCs turn to look but keep
	# their head level, per direct instruction, unlike the player's own
	# camera-driven head look in player.gd.


func _enter_idle() -> void:
	_state = State.IDLE
	_state_timer = _rng.randf_range(2.5, 6.0)
	_roll_idle_pose()


## Picks a fresh idle pose -- see player.gd's identical function and its
## IDLE_* consts for the full reasoning and the caveat that leg abduction/
## hip drop aren't visually re-verified in-engine.
func _roll_idle_pose() -> void:
	_idle_elbow_left = -_rng.randf_range(IDLE_ELBOW_MIN, IDLE_ELBOW_MAX)
	_idle_elbow_right = -_rng.randf_range(IDLE_ELBOW_MIN, IDLE_ELBOW_MAX)
	_idle_leg_variant_active = _rng.randf() < IDLE_LEG_VARIANT_CHANCE
	_idle_bent_leg_side = 1.0 if _rng.randf() < 0.5 else -1.0
	_idle_knee_bend = _rng.randf_range(IDLE_KNEE_MIN, IDLE_KNEE_MAX)


func _enter_walk() -> void:
	var current := Vector2(global_position.x, global_position.z)
	for attempt in PATH_CHECK_ATTEMPTS:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(WANDER_RADIUS * 0.3, WANDER_RADIUS)
		var candidate := _wander_center + Vector2(cos(angle), sin(angle)) * r
		if _path_clear(current, candidate):
			_state = State.WALK
			_target = candidate
			return
	# No clear spot found nearby -- just wait and try again on the next
	# idle timer instead of forcing a path through an obstacle.
	_enter_idle()


func _path_clear(from: Vector2, to: Vector2) -> bool:
	# Two heights, not just one -- a single ray at PATH_CHECK_HEIGHT (torso
	# height) can pass clean over a low obstacle (a stall counter, the
	# fountain rim) that only actually blocks lower down, letting an NPC
	# walk a path that reads as "clear" but isn't really. PATH_CHECK_LOW
	# catches that; both have to come back clear.
	for height in [PATH_CHECK_HEIGHT, PATH_CHECK_LOW]:
		var space_state := get_world_3d().direct_space_state
		var from3 := Vector3(from.x, global_position.y + height, from.y)
		var to3 := Vector3(to.x, global_position.y + height, to.y)
		var query := PhysicsRayQueryParameters3D.create(from3, to3)
		query.collision_mask = OBSTACLE_MASK
		query.exclude = [self]
		var result := space_state.intersect_ray(query)
		if not result.is_empty():
			return false
	return true


func _physics_process(delta: float) -> void:
	if stationary:
		# Per direct instruction: a stationary NPC (the vendor) should still
		# settle into the idle contrapposto pose rolled once at _ready()'s
		# _enter_idle() call, not stand perfectly rigid just because it
		# never walks. Never re-rolled again (stationary NPCs have no
		# further state transitions to trigger that), so it settles into
		# one natural resting stance and stays there -- fine for a
		# character that's permanently planted in one spot anyway.
		_settle_pose(delta)
		return
	match _state:
		State.IDLE:
			_state_timer -= delta
			_settle_pose(delta)
			if _state_timer <= 0.0:
				_enter_walk()
		State.WALK:
			_process_walk(delta)


func _process_walk(delta: float) -> void:
	var current := Vector2(global_position.x, global_position.z)
	var to_target := _target - current
	if to_target.length() < ARRIVE_DISTANCE:
		_enter_idle()
		return

	var dir := to_target.normalized()
	current += dir * MOVE_SPEED * delta
	global_position.x = current.x
	global_position.z = current.y
	global_position.y = fixed_ground_y if fixed_ground_y < INF else terrain_ref.get_mesh_height(current.x, current.y)

	var target_angle := atan2(dir.x, dir.y)
	visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, ROTATION_SPEED * delta)

	_walk_phase += delta * WALK_SWING_SPEED
	var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
	_leg_left.rotation.x = swing
	_leg_right.rotation.x = -swing
	_arm_left.rotation.x = -swing
	_arm_right.rotation.x = swing
	# The idle contrapposto pose's abduction/external-rotation/hip-drop
	# only apply while genuinely idle -- per direct correction, walking has
	# to reset all three back to level, not leave them frozen at whatever
	# the idle pose last held (this walk cycle only ever touches
	# rotation.x on the legs, never .y/.z, so without this an NPC that had
	# settled into the contrapposto variant would walk off with one leg
	# still splayed out at an odd angle). See player.gd's identical fix.
	_leg_left.rotation.z = lerp_angle(_leg_left.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)
	_leg_right.rotation.z = lerp_angle(_leg_right.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)
	_leg_left.rotation.y = lerp_angle(_leg_left.rotation.y, 0.0, POSE_SETTLE_SPEED * delta)
	_leg_right.rotation.y = lerp_angle(_leg_right.rotation.y, 0.0, POSE_SETTLE_SPEED * delta)
	_hips.rotation.z = lerp_angle(_hips.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)

	# Knee/elbow flex tied to each limb's swing *velocity* (cos(phase)),
	# not its position -- see player.gd's _animate_walk for the full
	# reasoning and for why the sign here is swapped from an earlier
	# version: which half-cycle counts as "forward" was an unverified
	# guess that turned out backwards (confirmed by direct observation --
	# knees were bending on the backswing and arms read as bending toward
	# the back), fixed by negating cos(phase) for each side.
	_knee_left.rotation.x = maxf(0.0, cos(_walk_phase + PI)) * ProceduralFigure.KNEE_BEND_AMOUNT
	_knee_right.rotation.x = maxf(0.0, cos(_walk_phase)) * ProceduralFigure.KNEE_BEND_AMOUNT
	# Elbows use a different curve shape from the knees, and the bend is
	# LEAST at the back of the backswing, increasing progressively to its
	# MOST at the forwardmost point of the swing -- once per cycle, see
	# player.gd's _animate_walk for the full reasoning (including why the
	# two arms need their own separate forward_fraction rather than sharing
	# one value, now that the curve isn't symmetric between the two
	# extremes, and why right's fraction uses (1 - sin)/2 rather than
	# (sin + 1)/2 -- positive arm_pivot.rotation.x is BACKWARD, not
	# forward, confirmed on player.gd's jump pose; an earlier version here
	# assumed the opposite and had the whole bend curve inverted). NPCs
	# only ever walk (no sprint state), so unlike player.gd there's no
	# nonzero floor at the backswing's back -- it eases fully straight
	# there.
	var right_forward_fraction := (1.0 - sin(_walk_phase)) * 0.5
	var left_forward_fraction := 1.0 - right_forward_fraction
	_elbow_right.rotation.x = -right_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT
	_elbow_left.rotation.x = -left_forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT

	# Forward spine lean while walking -- see player.gd's own SPINE_LEAN_MAX.
	# NPCs walk at one constant MOVE_SPEED (no variable speed to ramp
	# against), so this just eases toward the full lean while in WALK
	# state and back to 0 in _settle_pose() below while idle.
	_spine.rotation.x = lerp_angle(_spine.rotation.x, SPINE_LEAN_MAX, POSE_SETTLE_SPEED * delta)
	# Upper body height dip -- see ProceduralFigure.WALK_BODY_DIP_AMOUNT's
	# own comment. Set directly, not lerped, same as the rest of this
	# phase-driven cycle above (it's already a smooth continuous function
	# of _walk_phase). Applied to the hips too, not just the spine -- per
	# direct instruction, the whole upper body should bob together.
	var body_dip := -ProceduralFigure.WALK_BODY_DIP_AMOUNT * pow(sin(_walk_phase), 2)
	_spine.position.y = _spine_rest_y + body_dip
	_hips.position.y = _hips_rest_y + body_dip


func _settle_pose(delta: float) -> void:
	var bent_knee := _knee_right if _idle_bent_leg_side > 0.0 else _knee_left
	var straight_knee := _knee_left if _idle_bent_leg_side > 0.0 else _knee_right
	var bent_leg := _leg_right if _idle_bent_leg_side > 0.0 else _leg_left
	var straight_leg := _leg_left if _idle_bent_leg_side > 0.0 else _leg_right
	var knee_target := _idle_knee_bend if _idle_leg_variant_active else 0.0
	# Abduction's Z sign comes from the limb's actual X side. The old
	# idle-selector sign could oppose the shared outward stance on one leg,
	# making it visibly angle toward the body instead.
	var leg_z_target := (
		signf(bent_leg.position.x) * IDLE_HIP_OUTWARD_ANGLE if _idle_leg_variant_active else 0.0
	)
	var leg_y_target := (
		signf(bent_leg.position.x) * IDLE_HIP_EXTERNAL_ROTATION if _idle_leg_variant_active else 0.0
	)
	var hip_z_target := (
		-_idle_bent_leg_side * IDLE_HIP_DROP_ANGLE if _idle_leg_variant_active else 0.0
	)

	_leg_left.rotation.x = lerp_angle(_leg_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
	_leg_right.rotation.x = lerp_angle(_leg_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
	bent_knee.rotation.x = lerp_angle(bent_knee.rotation.x, knee_target, POSE_SETTLE_SPEED * delta)
	straight_knee.rotation.x = lerp_angle(straight_knee.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
	bent_leg.rotation.z = lerp_angle(bent_leg.rotation.z, leg_z_target, POSE_SETTLE_SPEED * delta)
	straight_leg.rotation.z = lerp_angle(straight_leg.rotation.z, 0.0, POSE_SETTLE_SPEED * delta)
	# External rotation (turns the knee/toe themselves outward, not just
	# the whole leg swung sideways) -- see player.gd's identical addition
	# for the full reasoning.
	bent_leg.rotation.y = lerp_angle(bent_leg.rotation.y, leg_y_target, POSE_SETTLE_SPEED * delta)
	straight_leg.rotation.y = lerp_angle(straight_leg.rotation.y, 0.0, POSE_SETTLE_SPEED * delta)
	_hips.rotation.z = lerp_angle(_hips.rotation.z, hip_z_target, POSE_SETTLE_SPEED * delta)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, _idle_elbow_left, POSE_SETTLE_SPEED * delta)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, _idle_elbow_right, POSE_SETTLE_SPEED * delta)
	_spine.rotation.x = lerp_angle(_spine.rotation.x, 0.0, POSE_SETTLE_SPEED * delta)
	_spine.position.y = lerp(_spine.position.y, _spine_rest_y, POSE_SETTLE_SPEED * delta)
