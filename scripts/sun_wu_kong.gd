class_name SunWuKong
extends StaticBody3D


func party_role_capabilities() -> Dictionary:
	return {"playable": false, "mount": false, "summon": true, "companion": true}

## Sun Wu Kong lives in the Chinese village, first sealed beneath a rock.
## Xiao Hou Zi can free him; returning the Jingu Bang then unlocks a combat
## summon. At the Sky Portal he can also join as a persistent companion,
## riding the Jindouyun rather than walking: that live body follows the
## currently controlled party member in all three dimensions. Temporary
## combat summons remain separate instances which arrive and depart in smoke.
##
## Built on MonkeyFigure directly, the same rig family as Xiao Hou Zi, with
## distinct golden fur and red clothing.

const DISPLAY_SCALE := 2.3585  # matches xiao_hou_zi.gd's own -- same species/size
## Golden, distinct from MonkeyFigure.MONKEY_FUR_COLOR's own plain light
## brown -- reads as a legendary individual rather than an ordinary monkey.
const FUR_COLOR := Color(0.85, 0.68, 0.16)
## Recolors the torso mesh MonkeyFigure.build() already returns (see
## _apply_clothing() below) rather than adding new clothing geometry of its
## own -- per direct instruction ("wearing clothing... parts of his figure
## should be colored red like red clothing").
const CLOTHING_COLOR := Color(0.72, 0.1, 0.08)
const INTERACT_RADIUS := 2.0
const ROTATION_SPEED := 6.0
const SUMMON_ATTACK_RANGE := 1.5
const SUMMON_MOVE_SPEED := 8.0
const SUMMON_ATTACK_COOLDOWN := 0.7
const SUMMON_DAMAGE := 14.0
const SUMMON_COMBAT_RADIUS := 24.0
const SUMMON_LINGER_DURATION := 2.5
## Jindouyun is supposed to keep pace with sprinting suit flight. The ordinary
## chase speed is already above the demo Air suit's fast cruise, then scales
## elastically with separation so a sharp dive or direction change does not
## leave a supposedly legendary cloud kilometres behind.
const CLOUD_FOLLOW_DISTANCE := 4.8
const CLOUD_FOLLOW_SPEED := 30.0
const CLOUD_CATCHUP_SPEED := 54.0
const CLOUD_TELEPORT_DISTANCE := 120.0
const CLOUD_TURN_SPEED := 7.0

## The Inventory item name for his legendary staff -- see chinese_village.gd's
## own _build_jingu_bang_pickup(), where the physical item is hidden among
## the loose sticks at the base of the kids' own play hut, per direct
## instruction ("Hiding there in the sticks is Sun Wu Kong's famous weapon
## Jingu Bang"). Found in a different scene from Sun Wu Kong himself (the
## outskirts Chinese village vs. the Plant Kingdom), so it travels as an
## ordinary Inventory item (same convention as jungle_kingdom_village.gd's
## own SPECIAL_BANANA_ITEM_NAME) rather than anything scene-local.
const JINGU_BANG_ITEM_NAME := "Jingu Bang"

## Duplicated from terrain_generator.gd's own CHINESE_VILLAGE_CENTER/
## CHINESE_VILLAGE_ABYSS_RADIUS/CHINESE_VILLAGE_ABYSS_TRANSITION, same
## reasoning wilderness_scatter.gd's own duplicate copy already gives --
## see _ground_y() below for why this specific companion needs to know
## about it: he's freed standing on one of chinese_village.gd's own
## floating islands, where the real ground far below is the Abyss of
## Impending Doom, not anywhere he should actually walk down onto once he
## starts following.
const CHINESE_VILLAGE_CENTER := Vector2(250.0, -650.0)
const CHINESE_VILLAGE_ABYSS_SAFE_RADIUS := 225.0
const CHINESE_VILLAGE_ISLAND_Y := -55.0

var summoned: bool = false
## Persistent party form. Kept independent from `summoned`: a combat summon
## still has its short encounter lifetime, while this body and its Jindouyun
## are captured by Party across world travel.
var cloud_companion: bool = false
var in_party: bool = false
## Authored landmark placement may pin the resident sage above ordinary
## island ground (the sealing rock now crowns the Emperor's castle).
var fixed_ground_y: float = INF
var _player: Node3D
var _terrain: Node
var _rock_visual: Node3D
var _rng := RandomNumberGenerator.new()
var _summoner: Node3D
var _attack_cooldown: float = 0.0
var _without_target: float = 0.0
var _dismissing: bool = false
var _arm_right: Node3D
var _elbow_right: Node3D
var _palm_right: Node3D
var _jindouyun: Node3D
var _cloud_time := 0.0
var _cloud_rest_position := Vector3.ZERO


func _ready() -> void:
	_rng.randomize()
	var pivots := MonkeyFigure.build(self, FUR_COLOR, DISPLAY_SCALE)
	_apply_clothing(pivots)
	_arm_right = pivots.get("arm_right") as Node3D
	_elbow_right = pivots.get("elbow_right") as Node3D
	_palm_right = pivots.get("palm_right") as Node3D
	add_to_group("sun_wu_kong")
	_player = get_node_or_null("../Player")
	_terrain = get_node_or_null("../Terrain")
	if not cloud_companion:
		global_position.y = _ground_y(global_position.x, global_position.z)

	var collision_shape := CollisionShape3D.new()
	var collider := SphereShape3D.new()
	collider.radius = 0.08 * DISPLAY_SCALE
	collision_shape.shape = collider
	collision_shape.position = Vector3(0, 0.09 * DISPLAY_SCALE, 0)
	add_child(collision_shape)
	collision_layer = 1
	collision_mask = 0

	if summoned:
		_build_staff(pivots)
		_spawn_smoke.call_deferred()
	elif cloud_companion:
		_build_staff(pivots)
		_build_jindouyun()
	else:
		if not WorldState.sun_wu_kong_freed:
			_build_sealing_rock()
		if WorldState.sun_wu_kong_has_jingu_bang:
			_build_staff(pivots)
		Interactable.attach(self, "Talk", INTERACT_RADIUS, _on_interact)


func configure_as_summon(summoner: Node3D) -> void:
	summoned = true
	_summoner = summoner


func configure_as_jindouyun_companion(joined: bool = false) -> void:
	cloud_companion = true
	in_party = joined


func join_party() -> void:
	in_party = true


## A small personal cloud, not an Air-blorb body. Its overlapping soft lobes
## use the same atmospheric blue-white family as CloudPlatform, scaled to the
## monkey rather than large enough to become a general parkour platform.
func _build_jindouyun() -> void:
	_jindouyun = Node3D.new()
	_jindouyun.name = "Jindouyun"
	_jindouyun.position = Vector3(0.0, -0.08, 0.0)
	_cloud_rest_position = _jindouyun.position
	add_child(_jindouyun)
	var lobe_specs := [
		[Vector3(0.48, 0.15, 0.28), Vector3(0.0, 0.0, 0.0)],
		[Vector3(0.30, 0.13, 0.24), Vector3(-0.34, 0.015, 0.01)],
		[Vector3(0.32, 0.14, 0.22), Vector3(0.34, 0.025, -0.01)],
		[Vector3(0.31, 0.12, 0.20), Vector3(-0.10, 0.035, -0.19)],
		[Vector3(0.28, 0.12, 0.19), Vector3(0.16, 0.025, 0.18)],
	]
	for spec in lobe_specs:
		var lobe_size: Vector3 = spec[0]
		var lobe_position: Vector3 = spec[1]
		var lobe := SuperEgg.build_part(
			lobe_size, Color(0.88, 0.94, 0.99, 0.88),
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		lobe.position = lobe_position
		var material := lobe.get_surface_override_material(0) as StandardMaterial3D
		if material != null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.roughness = 0.9
		_jindouyun.add_child(lobe)


func dismiss() -> void:
	if _dismissing:
		return
	_dismissing = true
	_spawn_smoke()
	visible = false
	queue_free()


func _build_staff(pivots: Dictionary) -> void:
	var hand := pivots.get("palm_right") as Node3D
	if hand == null:
		return
	var staff := ShopCatalog.build_jingu_bang_visual(0.55)
	staff.rotation_degrees = Vector3(0.0, 0.0, 90.0)
	staff.position = Vector3(0.0, 0.05, 0.0)
	hand.add_child(staff)


func _spawn_smoke() -> void:
	var smoke := GPUParticles3D.new()
	smoke.one_shot = true
	smoke.amount = 22
	smoke.lifetime = 0.65
	smoke.explosiveness = 0.85
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = 0.28
	process.direction = Vector3.UP
	process.spread = 180.0
	process.initial_velocity_min = 0.5
	process.initial_velocity_max = 1.5
	process.gravity = Vector3(0.0, 0.6, 0.0)
	process.scale_min = 0.35
	process.scale_max = 0.8
	process.color = Color(0.88, 0.9, 0.92, 0.72)
	smoke.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.9, 0.92, 0.94, 0.65)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	smoke.draw_pass_1 = mesh
	get_parent().add_child(smoke)
	smoke.global_position = global_position + Vector3.UP * 0.4
	smoke.emitting = true
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(smoke.queue_free)


## MonkeyFigure's own "hips" pivots-dict entry is actually the torso mesh
## itself (see monkey_figure.gd's own build() comment, "no separate pelvis
## mesh") -- overriding its material here is the whole "red clothing" effect,
## no new geometry needed.
func _apply_clothing(pivots: Dictionary) -> void:
	var body := pivots.get("hips") as MeshInstance3D
	if body == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = CLOTHING_COLOR
	material.roughness = 0.6
	# MonkeyFigure's procedural torso is intentionally double-sided (its
	# generated winding is shared with the fur material). Replacing that
	# material without carrying over the cull mode made the red torso appear
	# inside-out.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	body.material_override = material


func _build_sealing_rock() -> void:
	# NatureProps.build_rock() already places its lobes around the supplied
	# ground origin. The former extra upward offset exposed the monkey's entire
	# lower body beneath it. Keep the rock seated just through the roof surface
	# so its solid silhouette encloses him from feet through crown.
	_rock_visual = NatureProps.build_rock(0.36 * DISPLAY_SCALE, false)
	_rock_visual.position = Vector3(0, -0.025 * DISPLAY_SCALE, 0)
	add_child(_rock_visual)


## True ordinary terrain height everywhere except within the Chinese
## village's own floating-island footprint, where the real ground is the
## Abyss of Impending Doom far below -- see CHINESE_VILLAGE_* consts' own
## doc comment above. Checked fresh every call (not cached) so walking back
## into the village later re-engages the island height just as correctly as
## leaving it re-engages ordinary terrain-following.
func _ground_y(x: float, z: float) -> float:
	if fixed_ground_y < INF:
		return fixed_ground_y
	if Vector2(x, z).distance_to(CHINESE_VILLAGE_CENTER) < CHINESE_VILLAGE_ABYSS_SAFE_RADIUS:
		if _terrain != null and _terrain.has_method("get_chinese_village_island_surface_y"):
			return _terrain.get_chinese_village_island_surface_y()
		return CHINESE_VILLAGE_ISLAND_Y
	if _terrain != null and _terrain.has_method("get_mesh_height"):
		return _terrain.get_mesh_height(x, z)
	return global_position.y


func _xiao_hou_zi_in_party() -> bool:
	for node in get_tree().get_nodes_in_group("xiao_hou_zi"):
		if node.in_party:
			return true
	return false


func _on_interact() -> void:
	# Per direct instruction ("Sun Wu Kong also speaks only Chinese"), every
	# message he prompts is Chinese text only, no English -- same choice
	# CLAUDE.md's "In-game text and player guidance" rule already steers
	# these messages toward anyway (plain state description, not an
	# explanation of the mechanic -- matches portal.gd's own "The gate
	# stays still." style).
	if not WorldState.sun_wu_kong_freed:
		if not _xiao_hou_zi_in_party():
			Hud.show_message("石头纹丝不动。")
			return
		WorldState.sun_wu_kong_freed = true
		if _rock_visual != null:
			_rock_visual.queue_free()
			_rock_visual = null
		Hud.show_message("孙悟空从石下站了起来。")
		return
	if not WorldState.sun_wu_kong_has_jingu_bang and Inventory.has(JINGU_BANG_ITEM_NAME):
		Inventory.remove(JINGU_BANG_ITEM_NAME)
		WorldState.sun_wu_kong_has_jingu_bang = true
		WorldState.sun_wu_kong_summon_unlocked = true
		_build_staff({"palm_right": _palm_right})
		Hud.show_message("孙悟空接过金箍棒，笑道：小猴子若遇强敌，只管唤我。")
		return
	Hud.show_message("孙悟空咧嘴一笑,什么也没说。")


func _process(delta: float) -> void:
	if cloud_companion:
		_update_cloud_companion(delta)
		return
	if not summoned or _dismissing:
		return
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	var target := _nearest_target()
	if target == null:
		_without_target += delta
		if _without_target >= SUMMON_LINGER_DURATION:
			dismiss()
		return
	_without_target = 0.0
	var here := Vector2(global_position.x, global_position.z)
	var target_here := Vector2(target.global_position.x, target.global_position.z)
	var to_target := target_here - here
	if to_target.length() <= SUMMON_ATTACK_RANGE:
		if _attack_cooldown <= 0.0:
			_attack_cooldown = SUMMON_ATTACK_COOLDOWN
			target.take_damage(SUMMON_DAMAGE)
			if _arm_right != null:
				_arm_right.rotation.x = -1.0
			if _elbow_right != null:
				_elbow_right.rotation.x = -0.7
		return
	var step := to_target.limit_length(SUMMON_MOVE_SPEED * delta)
	var new_here := here + step
	global_position.x = new_here.x
	global_position.z = new_here.y
	global_position.y = _ground_y(new_here.x, new_here.y)
	if to_target.length() > 0.01:
		var target_angle := atan2(to_target.x, to_target.y)
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)


func _update_cloud_companion(delta: float) -> void:
	_cloud_time += delta
	if _jindouyun != null:
		_jindouyun.position = _cloud_rest_position + Vector3.UP * sin(_cloud_time * 2.1) * 0.035
	if not in_party:
		# Waiting at the portal: crown held proudly upward, with only the cloud's
		# own gentle float. Recruitment never starts merely from proximity.
		return
	var target := PartyControl.active_control_body()
	if target == null:
		target = _player
	if target == null or target == self:
		return
	var target_position := target.global_position
	if target.has_method("camera_focus_point"):
		target_position = target.camera_focus_point()
	var heading := target.global_transform.basis.z
	heading.y = 0.0
	if heading.length_squared() < 0.001:
		heading = Vector3.BACK
	heading = heading.normalized()
	var side := Vector3.UP.cross(heading).normalized()
	var desired := target_position - heading * CLOUD_FOLLOW_DISTANCE + side * 1.7 + Vector3.UP * 0.45
	var offset := desired - global_position
	var distance := offset.length()
	if distance > CLOUD_TELEPORT_DISTANCE:
		global_position = desired
		return
	if distance > 0.02:
		var catchup := clampf(distance / 18.0, 0.0, 1.0)
		var speed := lerpf(CLOUD_FOLLOW_SPEED, CLOUD_CATCHUP_SPEED, catchup)
		global_position += offset.limit_length(speed * delta)
		var target_angle := atan2(offset.x, offset.z)
		rotation.y = lerp_angle(rotation.y, target_angle, minf(1.0, CLOUD_TURN_SPEED * delta))


func _nearest_target() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := SUMMON_COMBAT_RADIUS
	for node in get_tree().get_nodes_in_group("skeletons"):
		var candidate := node as Node3D
		if candidate == null or not candidate.has_method("take_damage"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest
