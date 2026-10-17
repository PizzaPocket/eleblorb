extends Node3D

const BLORB := preload("res://scenes/blorb.tscn")
var failures: Array[String] = []

class Ground extends Node3D:
	func get_mesh_height(_x: float, _z: float) -> float: return 0.0
	func get_mesh_normal(_x: float, _z: float) -> Vector3: return Vector3.UP
	func is_lake_area(_at: Vector2) -> bool: return false

class Opponent extends StaticBody3D:
	var hits := 0
	var owner_blorb: Blorb
	func take_damage(amount: float, attacker: Blorb = null) -> void:
		if amount > 0.0:
			hits += 1
			owner_blorb = attacker

func _check(ok: bool, text: String) -> void:
	if not ok: failures.append(text)

func _ready() -> void:
	var ground := Ground.new(); ground.name = "Terrain"; add_child(ground)
	get_tree().create_timer(25.0).timeout.connect(func() -> void: get_tree().quit(2))
	_check(not bool(ShopCatalog.find("Boxing Gloves").get("weapon", false)), "loose gloves still use handheld weapon controls")
	_check(ShopCatalog.find("Notched Shortsword").get("weapon", false), "ordinary weapon classification changed")
	for profile in [PlayableCharacterProfile.human(), PlayableCharacterProfile.xiao_hou_zi()]:
		await _test(profile)
	for failure in failures: push_error(failure)
	print("Fighting suit: %d failures" % failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func _test(profile: PlayableCharacterProfile) -> void:
	var body := CharacterBody3D.new(); add_child(body)
	var visuals := Node3D.new(); body.add_child(visuals)
	var compact := profile.suit_limb_fit.has("round_arm_tip")
	var pivots := MonkeyFigure.build(visuals, MonkeyFigure.MONKEY_FUR_COLOR, MonkeyFigure.REFERENCE_BUILD_SCALE) if compact else ProceduralFigure.build(visuals)
	var map: Dictionary = {}
	for side in ["left", "right"]:
		map["arm_%s_shoulder" % side] = pivots["arm_%s" % side]
		map["arm_%s_elbow" % side] = pivots["elbow_%s" % side]
		for part in ["wrist", "fingertip", "back", "hand"]: map["%s_%s" % [part, side]] = pivots["%s_%s" % [part, side]]
	var suit := BlorbSuitController.new(); suit.setup(body, visuals, map, profile.suit_rig_scale, profile.suit_limb_fit)
	var ctx := TraversalContext.new(body, profile, RigAdapter.new(map), suit)
	ctx.visuals = visuals; ctx.delta = 1.0 / 60.0
	var fighters: Array[Blorb] = []
	for side in ["left", "right"]:
		var blorb := BLORB.instantiate() as Blorb
		blorb.portrait_mode = true; blorb.initial_element = "fighting"; add_child(blorb)
		blorb.set_process(false); blorb.in_party = true; blorb.begin_worn(); blorb.finish_worn()
		fighters.append(blorb); suit._wear_on_body("arm_%s" % side, blorb)
	var scaled_glove := (suit._worn[0]["pieces"][0] as Node3D).get_node("BoxingGlove") as Node3D
	_check(is_equal_approx(scaled_glove.scale.x, 1.65 * profile.suit_rig_scale), profile.id + ": whole glove does not follow body scale")
	_check(visuals.find_children("BoxingGlove", "Node3D", true, false).size() == 2, profile.id + ": missing paired suit gloves")
	# Exercise the real driver's generic gesture with an already-raised blend.
	# The earlier standalone pose proof missed this competing animation layer.
	var driver: Node = XiaoHouZi.new() if compact else Player.new()
	driver.set("_blorb_suit", suit)
	if compact:
		driver.set("_pivots", pivots)
		driver.set("_direct_left_arm_power_blend", 1.0)
		driver.set("_direct_right_arm_power_blend", 1.0)
	else:
		driver.set("visuals", visuals)
		for side in ["left", "right"]:
			driver.set("_arm_" + side, pivots["arm_" + side])
			driver.set("_elbow_" + side, pivots["elbow_" + side])
			driver.set("_hand_" + side, pivots["hand_" + side])
		driver.set("_left_arm_power_blend", 1.0)
		driver.set("_right_arm_power_blend", 1.0)
	var rest_transforms: Array[Transform3D] = []
	for side in ["left", "right"]: rest_transforms.append((pivots["hand_" + side] as Node3D).transform)
	Input.action_press("left_arm_power"); Input.action_press("right_arm_power")
	driver.call("_apply_direct_power_pose" if compact else "_apply_arm_power_poses", ctx.delta)
	Input.action_release("left_arm_power"); Input.action_release("right_arm_power")
	for arm in 2:
		var side := "left" if arm == 0 else "right"
		_check((pivots["hand_" + side] as Node3D).transform.is_equal_approx(rest_transforms[arm]), profile.id + ": generic gesture still changes boxing wrist")
		var glove := (suit._worn[arm]["pieces"][0] as Node3D).get_node("BoxingGlove") as Node3D
		_check(float(glove.get_meta("thumb_side")) == (1.0 if arm == 0 else -1.0), profile.id + ": glove thumb not mirrored")
	await _capture(body, profile, "rest")
	var enemy := Opponent.new(); enemy.collision_layer = 1
	var collider := CollisionShape3D.new(); var sphere := SphereShape3D.new(); sphere.radius = ctx.scaled(0.08); collider.shape = sphere
	enemy.add_child(collider); add_child(enemy); enemy.add_to_group("skeletons")
	var mode := FightingPunchMode.new()
	for arm in 2:
		for reset_side in ["left", "right"]:
			for joint in ["shoulder", "elbow"]:
				var key := "arm_%s_%s" % [reset_side, joint]
				ctx.rig.joint(key).rotation = ctx.rig.rest_rotation(key)
		var side := "left" if arm == 0 else "right"
		var shoulder := ctx.rig.joint("arm_%s_shoulder" % side)
		var elbow := ctx.rig.joint("arm_%s_elbow" % side)
		var other := ctx.rig.joint("arm_%s_shoulder" % ("right" if arm == 0 else "left"))
		# Compute the target from the actual fully extended rig, then reset.
		shoulder.rotation = Vector3(-PI * 0.5, 0, signf(shoulder.position.x) * 0.08); elbow.rotation = Vector3.ZERO
		var wrist := ctx.rig.joint("wrist_%s" % side)
		enemy.global_position = wrist.global_position + Vector3.BACK * ctx.scaled(0.10)
		shoulder.rotation = Vector3.ZERO
		var before := enemy.hits
		mode.reset(); mode.requested = [arm == 0, arm == 1]
		var other_start := other.rotation
		var impact_frames := ceili(FightingPunchMode.IMPACT / ctx.delta)
		for frame in impact_frames:
			await get_tree().physics_frame
			mode.update(ctx); mode.pose(ctx)
			if compact: MonkeyFigure.rebuild_limbs(pivots, visuals, ctx.delta)
			suit.update(ctx.delta)
			if frame < impact_frames - 1: _check(enemy.hits == before, profile.id + ": hit before extension")
		_check(enemy.hits == before + 1 and enemy.owner_blorb == fighters[arm], profile.id + ": wrong/missing punch or XP owner for " + side)
		_check(other.rotation.is_equal_approx(other_start), profile.id + ": punch moved opposite arm")
		_check((-elbow.global_basis.y).normalized().dot(Vector3.BACK) > 0.97, profile.id + ": punch extends in wrong direction")
		var glove := (suit._worn[arm]["pieces"][0] as Node3D).get_node("BoxingGlove") as Node3D
		var tip := ctx.rig.joint("fingertip_%s" % side)
		var direction := (tip.global_position - wrist.global_position).normalized()
		var pad := glove.get_child(1) as MeshInstance3D
		var dome_radius := ctx.scaled(0.10) * float(profile.suit_limb_fit.get("arm_wrist", 1.0)) if compact else 0.0
		_check(pad.mesh.get_aabb().has_point(pad.to_local(tip.global_position + direction * dome_radius)), profile.id + ": fingertips protrude beyond glove padding")
		await _capture(body, profile, side + "_punch")
		mode.requested = [false, false]
		for frame in 20:
			mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 1, profile.id + ": repeat damage from one punch")
		# Busy arm, missing accessory, mid-strike unequip and reset cancellation.
		mode.reset(); mode.requested = [arm == 0, arm == 1]
		ctx.left_arm_busy = arm == 0; ctx.right_arm_busy = arm == 1
		for frame in 12: mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 1, profile.id + ": occupied hand punched")
		ctx.left_arm_busy = false; ctx.right_arm_busy = false
		mode.reset(); mode.update(ctx); mode.pose(ctx)
		var entry: Dictionary = suit._worn.pop_at(arm)
		for frame in 12: mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 1, profile.id + ": unequipped arm retained strike")
		suit._worn.insert(arm, entry)
		mode.reset(); mode.update(ctx); mode.pose(ctx); mode.reset(); mode.requested = [false, false]
		for frame in 12: mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 1, profile.id + ": reset retained strike")
		# A full-height wall between shoulder and target must absorb a punch.
		var wall := StaticBody3D.new(); var shape := CollisionShape3D.new(); var box := BoxShape3D.new()
		box.size = Vector3(4, 4, ctx.scaled(0.03)); shape.shape = box; wall.add_child(shape); add_child(wall)
		wall.global_position = shoulder.global_position.lerp(enemy.global_position, 0.5)
		await get_tree().physics_frame
		mode.reset(); mode.requested = [arm == 0, arm == 1]
		for frame in 12: mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 1, profile.id + ": punched through wall")
		wall.free(); enemy.position.z += 10
		mode.reset()
		for frame in 12: mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 1, profile.id + ": punched outside glove reach")
	await _test_taps(ctx, mode, enemy, driver, compact)
	# Repeated held punches must reproduce the exact same basis at impact,
	# including after locomotion/generic-pose updates and a rotated body.
	body.rotation.y = 0.65
	mode.reset(); mode.requested = [true, true]
	var impact_bases: Array[Basis] = []
	var chamber_wrist := Vector3.ZERO
	var full_wrist := Vector3.ZERO
	var impacts := 0
	for frame in 150:
		ctx.delta = 1.0 / 60.0
		for side in ["left", "right"]:
			(pivots["arm_" + side] as Node3D).rotation.x = 0.1 * sin(frame * 0.2)
			(pivots["elbow_" + side] as Node3D).rotation.x = -0.1
		driver.call("_apply_direct_power_pose" if compact else "_apply_arm_power_poses", ctx.delta)
		mode.update(ctx)
		var impact: bool = mode._pending[0]
		mode.pose(ctx); suit.update(ctx.delta)
		if frame == ceili(FightingPunchMode.DURATION / ctx.delta) + 1:
			chamber_wrist = ctx.rig.joint("wrist_left").global_position
			for arm in 2:
				var side := "left" if arm == 0 else "right"
				var sign_side := 1.0 if arm == 0 else -1.0
				var glove := (suit._worn[arm]["pieces"][0] as Node3D).get_node("BoxingGlove") as Node3D
				_check((glove.global_basis.x.normalized() * sign_side).dot(visuals.global_basis.y) > 0.85, profile.id + ": chamber thumb is not upward")
				var shoulder := ctx.rig.joint("arm_%s_shoulder" % side)
				var elbow := ctx.rig.joint("arm_%s_elbow" % side)
				_check(shoulder.rotation.y * sign_side > 0.10 and shoulder.rotation.z * sign_side > 0.20, profile.id + ": chamber shoulder does not open outward")
				_check((elbow.global_position - shoulder.global_position).dot(visuals.global_basis.x * sign_side) > ctx.scaled(0.025), profile.id + ": chamber elbow points straight down")
			await _capture(body, profile, "chamber")
		if impact:
			impacts += 1
			full_wrist = ctx.rig.joint("wrist_left").global_position
			_check(is_zero_approx(ctx.rig.joint("arm_left_shoulder").rotation.y), profile.id + ": chamber yaw remains at impact")
			_check(is_equal_approx(ctx.rig.joint("arm_left_shoulder").rotation.z, 0.08), profile.id + ": established impact angle changed")
			for arm in 2:
				var glove := (suit._worn[arm]["pieces"][0] as Node3D).get_node("BoxingGlove") as Node3D
				var basis := glove.global_basis.orthonormalized()
				if impact_bases.size() < 2: impact_bases.append(basis)
				else: _check(basis.is_equal_approx(impact_bases[arm]), profile.id + ": glove twists between held punches")
				var thumb := glove.get_child(2) as Node3D
				var thumb_direction := thumb.global_position - glove.to_global(Vector3(0, thumb.position.y, thumb.position.z))
				_check(thumb_direction.dot(visuals.global_basis.x * (-1.0 if arm == 0 else 1.0)) > 0, profile.id + ": thumb faces away from body at impact")
				var pad := glove.get_child(1) as Node3D
				_check((thumb.global_position - pad.global_position).dot(visuals.global_basis.y) < 0, profile.id + ": thumb sits above back of glove")
				_check(basis.z.dot(visuals.global_basis.y) > 0.97, profile.id + ": glove back not uppermost at impact")
	_check(impacts >= 4, profile.id + ": held punches did not repeat")
	_check((full_wrist - chamber_wrist).dot(visuals.global_basis.z) > ctx.scaled(0.25), profile.id + ": insufficient whole-arm punch travel")
	driver.free()
	# Both buttons together retain independent strikes and credit.
	var targets: Array[Opponent] = [enemy, Opponent.new()]
	var second_shape := CollisionShape3D.new(); second_shape.shape = sphere.duplicate()
	targets[1].add_child(second_shape); add_child(targets[1]); targets[1].add_to_group("skeletons")
	for arm in 2:
		var side := "left" if arm == 0 else "right"
		var shoulder := ctx.rig.joint("arm_%s_shoulder" % side)
		shoulder.rotation = Vector3(-PI * 0.5, 0, signf(shoulder.position.x) * 0.08)
		ctx.rig.joint("arm_%s_elbow" % side).rotation = Vector3.ZERO
		targets[arm].global_position = ctx.rig.joint("wrist_%s" % side).global_position + Vector3.BACK * ctx.scaled(0.1)
	var counts := [targets[0].hits, targets[1].hits]
	await get_tree().physics_frame
	mode.reset(); mode.requested = [true, true]
	for frame in 10: mode.update(ctx); mode.pose(ctx)
	for arm in 2:
		_check(targets[arm].hits == counts[arm] + 1 and targets[arm].owner_blorb == fighters[arm], profile.id + ": simultaneous arms lost independent hit/credit")
	targets[1].free()
	# Check accessory gating and removal of its rendered glove.
	fighters[0].core_items.clear(); suit.update(ctx.delta)
	var piece := suit._worn[0]["pieces"][0] as Node3D
	_check(not piece.get_node("BoxingGlove").visible, profile.id + ": removed accessory still rendered")
	_check(mode._fighter(ctx, 0) == null, profile.id + ": Fighting type alone grants punch without gloves")
	print(profile.id, ": left/right glove fit, impact, owner, cancellation, cover and reach checked")
	enemy.free(); body.queue_free()
	for fighter in fighters: fighter.queue_free()
	await get_tree().process_frame

func _press(driver: Node, arm: int) -> void:
	var event := InputEventAction.new()
	event.action = "left_arm_power" if arm == 0 else "right_arm_power"
	event.pressed = true
	driver.call("_unhandled_input", event)
	# Press and release occur between mode updates: the event must survive
	# even though Input.is_action_pressed would already be false.
	event = InputEventAction.new(); event.action = "left_arm_power" if arm == 0 else "right_arm_power"
	event.pressed = false; driver.call("_unhandled_input", event)

func _test_taps(ctx: TraversalContext, mode: FightingPunchMode, enemy: Opponent, driver: Node, compact: bool) -> void:
	driver.set("_fighting_punch", mode)
	if compact: driver.set("is_player_controlled", true)
	ctx.delta = 1.0 / 60.0
	var impact_frames := ceili(FightingPunchMode.IMPACT / ctx.delta)
	for arm in 2:
		var side := "left" if arm == 0 else "right"
		mode.reset(); mode.requested = [false, false]
		mode._elapsed[arm] = FightingPunchMode.IMPACT; mode._guard[arm] = 1.0
		mode.pose(ctx)
		enemy.global_position = ctx.rig.joint("wrist_" + side).global_position + Vector3.BACK * ctx.scaled(0.1)
		await get_tree().physics_frame
		mode.reset(); mode.requested = [false, false]
		var before := enemy.hits
		for tap in 6:
			_press(driver, arm)
			_check(mode._presses[arm] == 1, ctx.profile.id + ": driver lost/doubled tap event")
			for frame in 6:
				mode.update(ctx); mode.pose(ctx)
				if frame == impact_frames - 1:
					_check(enemy.hits == before + tap + 1, ctx.profile.id + ": rapid tap waited for hold cooldown")
		_check(enemy.hits == before + 6, ctx.profile.id + ": rapid taps lost or duplicated punches")
		for frame in 30: mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 6, ctx.profile.id + ": released taps became automatic punches")
		# Faster taps within a strike's brief wind-up retain both strikes.
		mode.reset(); mode.requested = [false, false]
		_press(driver, arm); mode.update(ctx); mode.pose(ctx)
		_press(driver, arm)
		for frame in impact_frames * 2:
			mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 8, ctx.profile.id + ": tap during wind-up cancelled/lost a strike")
		# Reset/control loss must discard buffered input, just like a live strike.
		_press(driver, arm); mode.reset(); mode.requested = [false, false]
		for frame in 20: mode.update(ctx); mode.pose(ctx)
		_check(enemy.hits == before + 8, ctx.profile.id + ": reset retained queued tap")
	print(ctx.profile.id, ": rapid 10 Hz taps, short event pairs and wind-up buffer checked")

func _capture(body: Node3D, profile: PlayableCharacterProfile, label_text: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	for layer in get_tree().root.get_children():
		if layer is CanvasLayer: layer.visible = false
	var env := WorldEnvironment.new(); var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR; settings.background_color = Color(0.12, 0.15, 0.18)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; settings.ambient_light_color = Color(0.9, 0.94, 1); settings.ambient_light_energy = 0.8
	env.environment = settings; add_child(env)
	var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-40, -30, 0); add_child(light)
	var camera := Camera3D.new(); camera.fov = 30; add_child(camera)
	var height := profile.standing_height
	camera.position = body.position + Vector3(1.4, 0.8, 2.3) * height
	camera.look_at(body.position + Vector3.UP * height * 0.53); camera.make_current()
	for frame in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var output := "res://wip/diagnostics/2026-10-17-fighting-suit"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	get_viewport().get_texture().get_image().save_png(output + "/" + profile.id + "_" + label_text + ".png")
	camera.free(); light.free(); env.free()
