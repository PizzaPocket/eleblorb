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
@export var glove_color: Color = Color(0.0, 0.0, 0.0, 0.0)
## Fire Kingdom residents use the animated molten material over every body,
## garment and hair mesh while retaining ordinary living eyes.
@export var lava_body: bool = false
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
## Winter profiles use opaque tights/trousers beneath a skirt instead of the
## ordinary bare-leg dress convention.
@export var dress_has_covered_legs: bool = false
## Adds the Chinese Emperor's beard, raised court bun, crown, and gold robe
## details to the same articulated human rig rather than introducing a
## separate character implementation.
@export var wears_emperor_regalia: bool = false
@export_enum("none", "stubble", "full") var beard_style: String = "none"
@export var beard_color: Color = Color(0.06, 0.045, 0.035)
@export var beard_scale: float = 1.0
@export var wears_pirate_captain_hat: bool = false
@export_range(0, 1) var pirate_hat_variant: int = 0
@export var wears_chef_hat: bool = false
@export var chef_hat_color: Color = Color(0.9, 0.87, 0.79)
@export var chef_hat_band_color: Color = Color(0.62, 0.08, 0.055)
@export_enum("none", "left", "right") var hook_hand: String = "none"
@export_enum("none", "left", "right") var peg_leg: String = "none"
@export var cropped_trousers: bool = false
@export var wears_full_boots: bool = false
## Moving-platform NPC mode. Coordinates and roaming stay local to the
## parent deck, so a sailing ship cannot leave its crew behind in world space.
@export var deck_wanderer: bool = false
@export var deck_wander_bounds: Vector2 = Vector2(3.8, 10.5)
@export var deck_wander_center: Vector2 = Vector2.ZERO
@export var deck_surface_y: float = 3.8
@export var at_ship_helm: bool = false
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
## Optional circular limit for floating islands and other bounded walkable
## spaces. INF preserves ordinary town behavior. Both endpoints of an NPC's
## straight walk remain inside the circle, so the whole route stays on land.
@export var wander_boundary_center: Vector2 = Vector2.ZERO
@export var wander_boundary_radius: float = INF
## Optional hook for a caller-supplied array of extra dialogue actions,
## appended after the vendor-only "wares" action (if any) -- mirrors
## ApeTemplatePreview's own field of the same name/shape (that file's own
## quest-ape usage is the precedent this follows). Each returned entry is
## {"label": String, "callback": Callable}, exactly DialogUI.show_line()'s
## own action shape. Left invalid (the default) for every ordinary NPC.
var dialog_actions_provider: Callable = Callable()
## Optional authored first-class conversation handler for story NPCs whose
## interaction changes world state before ordinary dialogue is appropriate.
var talk_override: Callable = Callable()
## Optional hostile phase used by story NPCs that reveal themselves as an
## enemy without swapping to a different visual rig (currently the Royal
## Chef). They only join the ordinary "skeletons" damage-target group during
## that phase, so ambient villagers remain completely unaffected.
var demon_agent_defeated_callback: Callable = Callable()
var _demon_agent_combat_active: bool = false
var _demon_agent_hp: float = 90.0
var _demon_agent_attack_cooldown: float = 0.0

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
var _hips: MeshInstance3D
var _hand_left: MeshInstance3D
var _hand_right: MeshInstance3D
var _holds_fishing_rod := false
var _fishing_target_world := Vector3.ZERO
var _fishing_rod_grip: MeshInstance3D
var _fishing_rod_shaft: MeshInstance3D
var _fishing_line: MeshInstance3D
var _ankle_left: Node3D
var _ankle_right: Node3D
var _skirt: MeshInstance3D
var _skirt_pivot: Node3D
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

	_wander_center = Vector2(position.x, position.z) if deck_wanderer else Vector2(global_position.x, global_position.z)
	# get_mesh_height(), not get_height() -- matches the exact rendered/
	# collision surface rather than the raw continuous noise function,
	# which can visibly disagree with it between the terrain's ~8m grid
	# vertices (see terrain_generator.gd's get_mesh_height() doc comment).
	if deck_wanderer:
		position.y = deck_surface_y
	else:
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
	var leg_color: Color = skin_color if wears_dress and not dress_has_covered_legs else pants_color
	var pivots := ProceduralFigure.build(
		visuals, skin_color, shirt_color, leg_color, sleeve_style,
		body_scale, chest_build_scale, hip_build_scale, abdomen_width_scale,
		Color(0.0, 0.0, 0.0, 0.0),  # chest_emblem_color -- NPCs don't get one, only the hero does
		hair_color, hair_style, hair_length_variance, shoe_color,
		false,  # skeleton_mode
		has_glasses,
		# Bare legs under a skirt don't carry the trouser silhouette's usual
		# thickness -- see ProceduralFigure._build_leg()'s own comment.
		0.72 if wears_dress else 1.0,
		true,
		glove_color
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
	_hand_left = pivots["hand_left"]
	_hand_right = pivots["hand_right"]
	_ankle_left = pivots["ankle_left"]
	_ankle_right = pivots["ankle_right"]
	_hips_rest_y = _hips.position.y
	if wears_dress:
		var resolved_dress_color: Color = pants_color if is_zero_approx(dress_color.a) else dress_color
		var dress_parts := FigureDress.add_to_figure(
			pivots["root"] if pivots.has("root") else visuals, _hips, resolved_dress_color, hip_build_scale
		)
		_skirt = dress_parts["skirt"]
		_skirt_pivot = dress_parts["pivot"]
	if wears_emperor_regalia:
		_add_emperor_regalia()
	elif beard_style != "none":
		_add_beard(beard_style, beard_color, beard_scale)
	if wears_pirate_captain_hat:
		_add_pirate_captain_hat(pirate_hat_variant)
	if wears_chef_hat:
		_add_chef_hat()
	if hook_hand != "none":
		_add_hook_hand(hook_hand)
	if peg_leg != "none":
		_add_peg_leg(peg_leg)
	if cropped_trousers:
		_apply_cropped_trousers()
	if wears_full_boots:
		_apply_full_boots()
	if lava_body:
		var lava_material := NatureProps.build_lava_material()
		_apply_lava_material_recursive(visuals, lava_material)
		var eye_material := StandardMaterial3D.new()
		# Living eyes remain matte, darker markings like every other figure's
		# eyes. The former emissive yellow-orange was almost the same value as
		# the molten face and disappeared against its glow.
		eye_material.albedo_color = Color(0.14, 0.018, 0.008)
		eye_material.roughness = 0.82
		for eye in _eyes:
			if eye is MeshInstance3D:
				(eye as MeshInstance3D).set_surface_override_material(0, eye_material)


func _apply_lava_material_recursive(node: Node, material: Material) -> void:
	# Long/bob-like hair is a CSGCombiner containing CSGMesh3D pieces, not a
	# MeshInstance3D. GeometryInstance3D covers both forms, ensuring the main
	# hair shell and the carved bangs surface receive molten material too.
	# _eyes is intentionally Array[MeshInstance3D]. Never pass an arbitrary
	# GeometryInstance3D into its typed has() check: CSGMesh3D/CSGCombiner3D
	# are valid material targets but cannot be converted to MeshInstance3D,
	# which previously emitted a recursive startup error for every lava NPC.
	var is_eye := node is MeshInstance3D and _eyes.has(node as MeshInstance3D)
	if node is GeometryInstance3D and not is_eye:
		(node as GeometryInstance3D).material_override = material
	for child in node.get_children():
		_apply_lava_material_recursive(child, material)


func _add_emperor_regalia() -> void:
	var red := Color(0.66, 0.055, 0.045)
	var gold := Color(0.95, 0.69, 0.16)
	# A high court bun sits on the crown rather than behind the skull.
	var bun := SuperEgg.build_part(Vector3(0.065, 0.075, 0.06), hair_color, 2.4, 2.4)
	bun.position = Vector3(0.0, 0.285, -0.015)
	_head.add_child(bun)
	# Beard is deliberately sunk into the chin so it reads like the project's
	# hair shapes emerging from the head, not a pasted-on prop.
	_add_beard("full", hair_color, 1.0)
	# Mian-style square crown with ten bead cords at both front and back.
	var crown := SuperEgg.build_part(Vector3(0.18, 0.025, 0.145), red, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	crown.position = Vector3(0.0, 0.34, 0.0)
	_head.add_child(crown)
	for front_sign: float in [-1.0, 1.0]:
		for i in 10:
			var x := lerpf(-0.145, 0.145, float(i) / 9.0)
			var cord := SuperEgg.build_part(Vector3(0.008, 0.095, 0.008), gold, 2.0, 2.0)
			cord.position = Vector3(x, 0.225, front_sign * 0.13)
			_head.add_child(cord)
	# Gold waist and sleeve borders complete the continuous red robe.
	var belt := SuperEgg.build_part(Vector3(0.235, 0.025, 0.145), gold, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	belt.position = Vector3(0.0, -0.21, 0.0)
	_spine.add_child(belt)
	for arm in [_arm_left, _arm_right]:
		var cuff := SuperEgg.build_part(Vector3(0.061, 0.025, 0.061), gold, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		cuff.position = Vector3(0.0, -0.27, 0.0)
		arm.add_child(cuff)


func _add_beard(style: String, color: Color, scale_factor: float) -> void:
	var half_size := Vector3(0.075, 0.16, 0.045) if style == "full" else Vector3(0.082, 0.045, 0.028)
	var beard := SuperEgg.build_part(half_size * scale_factor, color, 2.5, 2.5)
	beard.name = "FullBeard" if style == "full" else "ChinStubble"
	beard.position = Vector3(0.0, 0.015 if style == "full" else 0.035, 0.105)
	beard.rotation.x = deg_to_rad(-8.0)
	_head.add_child(beard)


func _add_pirate_captain_hat(variant: int) -> void:
	var black := Color(0.025, 0.025, 0.03)
	var bone := Color(0.88, 0.84, 0.71)
	var trim := Color(0.93, 0.48, 0.08) if variant == 0 else Color(0.58, 0.38, 0.16)
	var crown_size := Vector3(0.19, 0.095, 0.115) if variant == 0 else Vector3(0.17, 0.145, 0.105)
	var crown := SuperEgg.build_part(crown_size, black, 2.8, SuperEgg.EPSILON_FLAT)
	crown.position = Vector3(0.0, 0.29 if variant == 0 else 0.335, -0.005)
	_head.add_child(crown)
	var brim_count := 2 if variant == 0 else 3
	for index in brim_count:
		var yaw_degrees := 90.0 + float(index) * 180.0 if variant == 0 else float(index) * 120.0
		var brim_size := Vector3(0.235, 0.026, 0.09) if variant == 0 else Vector3(0.205, 0.025, 0.082)
		var brim := SuperEgg.build_part(brim_size, black, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
		brim.position = Vector3(0.0, 0.275, 0.0)
		brim.rotation.y = deg_to_rad(yaw_degrees)
		brim.rotation.x = deg_to_rad(-8.0 if variant == 0 else -17.0)
		_head.add_child(brim)
	for side in [-1.0, 1.0]:
		var edge := SuperEgg.build_part(Vector3(0.018, 0.018, 0.205 if variant == 0 else 0.17), trim, 2.2, 2.2)
		edge.position = Vector3(side * (0.17 if variant == 0 else 0.145), 0.36 if variant == 0 else 0.43, 0.0)
		_head.add_child(edge)
	if variant == 0:
		var band := SuperEgg.build_part(Vector3(0.145, 0.022, 0.112), Color(0.72, 0.045, 0.035), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		band.position = Vector3(0.0, 0.28, 0.0)
		_head.add_child(band)
		for side in [-1.0, 1.0]:
			var tail := SuperEgg.build_part(Vector3(0.025, 0.09, 0.012), Color(0.72, 0.045, 0.035), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			tail.position = Vector3(side * 0.035, 0.19, -0.1)
			tail.rotation.z = side * deg_to_rad(12.0)
			_head.add_child(tail)
	var skull := SuperEgg.build_part(Vector3(0.03, 0.035, 0.012), bone, 2.2, 2.2)
	skull.position = Vector3(0.0, 0.34 if variant == 0 else 0.39, 0.116)
	_head.add_child(skull)
	for angle: float in [-0.7, 0.7]:
		var bone_bar := SuperEgg.build_part(Vector3(0.008, 0.045, 0.008), bone, 2.0, 2.0)
		bone_bar.position = Vector3(0.0, 0.30 if variant == 0 else 0.35, 0.12)
		bone_bar.rotation.z = angle
		_head.add_child(bone_bar)


func _add_chef_hat() -> void:
	# A tall toque keeps the Royal Chef recognizable before and after his
	# reveal. Its authored colors are instance-controlled so it can begin as
	# respectable kitchen whites and blacken with the rest of his disguise.
	var brim := SuperEgg.build_part(
		Vector3(0.19, 0.035, 0.15), chef_hat_color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	brim.name = "ChefHatBrim"
	brim.position = Vector3(0.0, 0.265, 0.0)
	_head.add_child(brim)
	var crown := SuperEgg.build_part(Vector3(0.15, 0.18, 0.125), chef_hat_color, 3.2, 3.2)
	crown.name = "ChefHatCrown"
	crown.position = Vector3(0.0, 0.43, -0.005)
	_head.add_child(crown)
	var band := SuperEgg.build_part(
		Vector3(0.158, 0.022, 0.132), chef_hat_band_color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	band.name = "ChefHatBand"
	band.position = Vector3(0.0, 0.30, 0.0)
	_head.add_child(band)


func _add_hook_hand(side: String) -> void:
	var hand := _hand_left if side == "left" else _hand_right
	var elbow := _elbow_left if side == "left" else _elbow_right
	if hand == null or elbow == null:
		return
	hand.visible = false
	var root := Node3D.new()
	root.name = "PirateHook"
	root.position = hand.position
	elbow.add_child(root)
	var cuff := SuperEgg.build_part(Vector3(0.052, 0.045, 0.052), Color(0.22, 0.11, 0.055), 2.5, 2.5)
	root.add_child(cuff)
	for index in 7:
		var angle := lerpf(-PI * 0.55, PI * 0.62, float(index) / 6.0)
		var hook := SuperEgg.build_part(Vector3(0.012, 0.026, 0.012), Color(0.66, 0.68, 0.7), 2.0, 2.0)
		hook.position = Vector3(cos(angle) * 0.055, -0.04 - float(index) * 0.017, sin(angle) * 0.055)
		root.add_child(hook)


func _add_peg_leg(side: String) -> void:
	var knee := _knee_left if side == "left" else _knee_right
	var ankle := _ankle_left if side == "left" else _ankle_right
	if knee == null or ankle == null:
		return
	for child in knee.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	for child in ankle.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	var peg := SuperEgg.build_part(Vector3(0.038, ProceduralFigure.LOWER_LEG_SIZE.y * 1.05, 0.038), Color(0.31, 0.14, 0.055), 2.2, 2.2)
	peg.name = "WoodenPegLeg"
	peg.position = Vector3(0.0, -ProceduralFigure.LOWER_LEG_SIZE.y, 0.0)
	knee.add_child(peg)


func _apply_cropped_trousers() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = skin_color
	material.roughness = 0.6
	for knee in [_knee_left, _knee_right]:
		for child in knee.get_children():
			if child is MeshInstance3D:
				var lower_leg := child as MeshInstance3D
				lower_leg.material_override = material
				lower_leg.scale.x = 0.78
				lower_leg.scale.z = 0.78
				break


func _apply_full_boots() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = shoe_color
	material.roughness = 0.58
	for leg in [_leg_left, _leg_right]:
		_apply_material_recursive(leg, material)


func _apply_material_recursive(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).material_override = material
	for child in node.get_children():
		_apply_material_recursive(child, material)


func _on_talk() -> void:
	if talk_override.is_valid() and bool(talk_override.call()):
		return
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
	if dialog_actions_provider.is_valid():
		actions.append_array(dialog_actions_provider.call() as Array)
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
	if deck_wanderer:
		_state = State.WALK
		_target = deck_wander_center + Vector2(
			_rng.randf_range(-deck_wander_bounds.x, deck_wander_bounds.x),
			_rng.randf_range(-deck_wander_bounds.y, deck_wander_bounds.y)
		)
		return
	var current := Vector2(global_position.x, global_position.z)
	for attempt in PATH_CHECK_ATTEMPTS:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(WANDER_RADIUS * 0.3, WANDER_RADIUS)
		var candidate := _wander_center + Vector2(cos(angle), sin(angle)) * r
		if candidate.distance_to(wander_boundary_center) > wander_boundary_radius:
			continue
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
	_settle_dress_pose(delta)
	if _demon_agent_combat_active:
		_process_demon_agent_combat(delta)
		return
	if stationary:
		if _holds_fishing_rod:
			_apply_fishing_pose(delta)
			_update_fishing_gear()
			return
		if at_ship_helm:
			_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, -0.72, POSE_SETTLE_SPEED * delta)
			_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, -0.72, POSE_SETTLE_SPEED * delta)
			_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, -0.48, POSE_SETTLE_SPEED * delta)
			_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, -0.48, POSE_SETTLE_SPEED * delta)
			return
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


func begin_demon_agent_battle(on_defeated: Callable) -> void:
	if _demon_agent_combat_active:
		return
	demon_agent_defeated_callback = on_defeated
	_demon_agent_combat_active = true
	_demon_agent_hp = 90.0
	_demon_agent_attack_cooldown = 0.4
	_reveal_demon_agent_form()
	stationary = false
	add_to_group("skeletons")
	for child in get_children():
		if child is Area3D:
			(child as Area3D).set_deferred("monitoring", false)


func _reveal_demon_agent_form() -> void:
	var former_skin := skin_color
	var former_shirt := shirt_color
	var former_pants := pants_color
	var former_hat := chef_hat_color
	skin_color = Color(0.68, 0.055, 0.035)
	shirt_color = Color(0.075, 0.045, 0.065)
	pants_color = Color(0.035, 0.025, 0.04)
	_replace_figure_color(visuals, former_skin, skin_color)
	_replace_figure_color(visuals, former_shirt, shirt_color)
	_replace_figure_color(visuals, former_pants, pants_color)
	_replace_figure_color(visuals, former_hat, Color(0.055, 0.045, 0.055))
	# A brief hot glow makes the change readable as the disguise dropping,
	# rather than the materials merely popping between dialogue frames.
	var tween := create_tween()
	tween.tween_property(visuals, "scale", Vector3(1.1, 1.1, 1.1), 0.12)
	tween.tween_property(visuals, "scale", Vector3.ONE, 0.18)


func _replace_figure_color(node: Node, from_color: Color, to_color: Color) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		var material := mesh_instance.get_active_material(0) as StandardMaterial3D
		if material != null and material.albedo_color.is_equal_approx(from_color):
			var replacement := material.duplicate() as StandardMaterial3D
			replacement.albedo_color = to_color
			mesh_instance.set_surface_override_material(0, replacement)
	for child in node.get_children():
		_replace_figure_color(child, from_color, to_color)


func is_demon_agent_combat_active() -> bool:
	return _demon_agent_combat_active


func take_damage(amount: float, _attacker: Node = null) -> void:
	if not _demon_agent_combat_active or amount <= 0.0:
		return
	_demon_agent_hp = maxf(_demon_agent_hp - amount, 0.0)
	if is_zero_approx(_demon_agent_hp):
		_defeat_demon_agent()


func is_defeated() -> bool:
	return not _demon_agent_combat_active and is_zero_approx(_demon_agent_hp)


func _process_demon_agent_combat(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	_demon_agent_attack_cooldown = maxf(_demon_agent_attack_cooldown - delta, 0.0)
	var offset := player.global_position - global_position
	var flat := Vector2(offset.x, offset.z)
	if flat.length() > 1.35:
		var direction := flat.normalized()
		global_position += Vector3(direction.x, 0.0, direction.y) * 1.85 * delta
		visuals.rotation.y = lerp_angle(visuals.rotation.y, atan2(direction.x, direction.y), ROTATION_SPEED * delta)
		_walk_phase += delta * WALK_SWING_SPEED
		var swing := sin(_walk_phase) * WALK_SWING_AMOUNT
		_leg_left.rotation.x = swing
		_leg_right.rotation.x = -swing
		_arm_left.rotation.x = -swing
		_arm_right.rotation.x = swing
	elif _demon_agent_attack_cooldown <= 0.0:
		player.take_damage(14.0)
		_demon_agent_attack_cooldown = 1.05


func _defeat_demon_agent() -> void:
	_demon_agent_combat_active = false
	set_physics_process(false)
	remove_from_group("skeletons")
	for child in get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).set_deferred("disabled", true)
	if demon_agent_defeated_callback.is_valid():
		demon_agent_defeated_callback.call()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 3.5, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(visuals, "scale", Vector3(0.08, 0.08, 0.08), 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)


## Gives a stationary NPC a real rig-driven fishing setup. The short handle
## spans the two physical hand meshes, the main shaft begins at the hand
## nearest the hole, and the line is rebuilt from that shaft's exact endpoint.
func equip_fishing_rod(target_world: Vector3) -> void:
	_holds_fishing_rod = true
	_fishing_target_world = target_world
	var wood := Color(0.38, 0.22, 0.12)
	_fishing_rod_grip = SuperEgg.build_part(
		Vector3(0.026, 0.25, 0.026), wood,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	_fishing_rod_grip.name = "FishingRodHandle"
	get_tree().current_scene.add_child(_fishing_rod_grip)
	_fishing_rod_shaft = SuperEgg.build_part(
		Vector3(0.021, 0.9, 0.021), wood.lightened(0.08),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	_fishing_rod_shaft.name = "FishingRodShaft"
	get_tree().current_scene.add_child(_fishing_rod_shaft)
	_fishing_line = SuperEgg.build_part(
		Vector3(0.007, 0.5, 0.007), Color(0.78, 0.82, 0.84),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	_fishing_line.name = "FishingLine"
	get_tree().current_scene.add_child(_fishing_line)
	_update_fishing_gear()


func _apply_fishing_pose(delta: float) -> void:
	var t := minf(POSE_SETTLE_SPEED * delta, 1.0)
	# Both shoulders reach forward and slightly inward; the elbows stagger so
	# the hands meet the handle at two distinct points instead of overlapping.
	_arm_left.rotation.x = lerp_angle(_arm_left.rotation.x, -0.88, t)
	_arm_right.rotation.x = lerp_angle(_arm_right.rotation.x, -0.72, t)
	_arm_left.rotation.z = lerp_angle(_arm_left.rotation.z, -0.16, t)
	_arm_right.rotation.z = lerp_angle(_arm_right.rotation.z, 0.16, t)
	_elbow_left.rotation.x = lerp_angle(_elbow_left.rotation.x, -0.72, t)
	_elbow_right.rotation.x = lerp_angle(_elbow_right.rotation.x, -0.92, t)
	_spine.rotation.x = lerp_angle(_spine.rotation.x, deg_to_rad(3.0), t)


func _update_fishing_gear() -> void:
	if (
		not is_instance_valid(_hand_left)
		or not is_instance_valid(_hand_right)
		or not is_instance_valid(_fishing_rod_grip)
		or not is_instance_valid(_fishing_rod_shaft)
		or not is_instance_valid(_fishing_line)
	):
		return
	var left_hand := _hand_left.global_position
	var right_hand := _hand_right.global_position
	_set_thin_part_between(_fishing_rod_grip, left_hand, right_hand)
	var shaft_base := (
		left_hand
		if left_hand.distance_squared_to(_fishing_target_world) < right_hand.distance_squared_to(_fishing_target_world)
		else right_hand
	)
	var toward_target := (_fishing_target_world - shaft_base).normalized()
	# The raised tip keeps the rod visibly arced over the hole while the line
	# itself drops from precisely this endpoint into the water below the ice.
	var rod_tip := shaft_base + toward_target * 1.45 + Vector3.UP * 1.08
	_set_thin_part_between(_fishing_rod_shaft, shaft_base, rod_tip)
	_set_thin_part_between(_fishing_line, rod_tip, _fishing_target_world)


func _set_thin_part_between(part: MeshInstance3D, from: Vector3, to: Vector3) -> void:
	var direction := to - from
	var length := direction.length()
	if length <= 0.001:
		return
	var up := direction / length
	var side := up.cross(Vector3.FORWARD)
	if side.length_squared() < 0.001:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var forward := side.cross(up).normalized()
	part.global_transform = Transform3D(Basis(side, up, forward), (from + to) * 0.5)
	# SuperEgg's authored Y half-extent is normalized by scaling the whole part
	# from its original one-metre full height to the exact endpoint distance.
	var authored_half_height: float = float((part.mesh as ArrayMesh).get_aabb().size.y) * 0.5
	part.scale.y = length / maxf(authored_half_height * 2.0, 0.001)


## Eases the worn hip shell and skirt back to their resting shape every
## frame -- _process_walk() below overrides this with a live stride fit
## whenever this NPC is actually walking. This has to run as a continuous
## per-frame lerp rather than a one-time "on stop" reset because the fit
## itself is a continuous function of the live leg pose (see
## FigureDress.stride_envelope()'s own doc comment).
func _settle_dress_pose(delta: float) -> void:
	if _skirt == null:
		return
	var t := POSE_SETTLE_SPEED * delta
	_hips.scale.x = lerpf(_hips.scale.x, 1.0, t)
	_hips.scale.z = lerpf(_hips.scale.z, 1.0, t)
	_hips.rotation.y = lerp_angle(_hips.rotation.y, 0.0, t)
	_skirt.scale.x = lerpf(_skirt.scale.x, 1.0, t)
	_skirt.scale.z = lerpf(_skirt.scale.z, 1.0, t)
	_skirt.rotation.y = lerp_angle(_skirt.rotation.y, 0.0, t)
	if _skirt_pivot != null:
		_skirt_pivot.rotation.y = lerp_angle(_skirt_pivot.rotation.y, 0.0, t)
		_skirt_pivot.scale.x = lerpf(_skirt_pivot.scale.x, 1.0, t)
		_skirt_pivot.scale.z = lerpf(_skirt_pivot.scale.z, 1.0, t)


func _process_walk(delta: float) -> void:
	var current := Vector2(position.x, position.z) if deck_wanderer else Vector2(global_position.x, global_position.z)
	var to_target := _target - current
	if to_target.length() < ARRIVE_DISTANCE:
		_enter_idle()
		return

	var dir := to_target.normalized()
	current += dir * MOVE_SPEED * delta
	if deck_wanderer:
		position = Vector3(current.x, deck_surface_y, current.y)
	else:
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

	if _skirt != null:
		# Fit the dress-coloured hip shell to the live leg pose first, then the
		# lower skirt shell -- see FigureDress.upper_skirt_envelope()/
		# stride_envelope()'s own doc comments for the two-point stride-box
		# derivation. _skirt_pivot cancels the hip shell's own just-applied
		# rotation/scale back out so the skirt's fit is solved and applied
		# independently rather than compounding with the hip shell's.
		var upper_envelope := FigureDress.upper_skirt_envelope(_hips, _leg_left, _leg_right, _knee_left, _knee_right)
		_hips.rotation.y = float(upper_envelope["yaw"])
		_hips.scale.x = float(upper_envelope["scale_x"])
		_hips.scale.z = float(upper_envelope["scale_z"])
		var envelope := FigureDress.stride_envelope(_skirt, _hips, _knee_left, _knee_right)
		_skirt.rotation.y = float(envelope["yaw"])
		_skirt.scale.x = float(envelope["scale_x"])
		_skirt.scale.z = float(envelope["scale_z"])
		if _skirt_pivot != null:
			_skirt_pivot.basis = _hips.basis.inverse()


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
