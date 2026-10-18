extends Node3D

var failures: Array[String] = []

class Suit extends BlorbSuitController:
	var chest := false
	var feet := false
	var slots := {}
	func has_chest_air_blorb() -> bool: return chest
	func has_air_hover_legs() -> bool: return feet
	func worn_blorb_in_slot(slot: String) -> Blorb: return slots.get(slot) as Blorb

class Basin extends Node3D:
	func get_mesh_height(_x: float, _z: float) -> float: return -10.0
	func is_lake_area(_at: Vector2) -> bool: return true
	func get_lake_water_level() -> float: return 0.0

func _check(ok: bool, label: String) -> void:
	if not ok: failures.append(label)

func _ready() -> void:
	var basin := Basin.new(); basin.name = "Terrain"; add_child(basin)
	for profile in [PlayableCharacterProfile.human(), PlayableCharacterProfile.xiao_hou_zi()]:
		await _steps(profile, 0.15, false, true)
		await _steps(profile, 0.8, false, false)
		await _steps(profile, 0.25, true, false)
		await _ramp(profile)
		await _bank(profile)
		await _liquid(profile)
		_flight(profile)
	await _drivers()
	for failure in failures: push_error(failure)
	print("MOBILITY_TRANSITIONS failures=", failures.size())
	get_tree().quit(0 if failures.is_empty() else 1)

func _box(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new(); body.position = at; body.collision_layer = 1; body.collision_mask = 0
	var collision := CollisionShape3D.new(); var shape := BoxShape3D.new(); shape.size = size; collision.shape = shape
	body.add_child(collision); parent.add_child(body)
	return body

func _body(parent: Node3D, profile: PlayableCharacterProfile) -> CharacterBody3D:
	var ratio := profile.standing_height / 1.896
	var body := CharacterBody3D.new(); body.collision_layer = 2; body.collision_mask = 1
	body.floor_max_angle = deg_to_rad(50.0); body.safe_margin = 0.001 * ratio; body.floor_snap_length = 0.1 * ratio
	var collision := CollisionShape3D.new(); var shape := CapsuleShape3D.new(); shape.height = 1.8 * ratio; shape.radius = 0.4 * ratio
	collision.position.y = 0.9 * ratio; collision.shape = shape; body.add_child(collision); parent.add_child(body)
	return body

func _steps(profile: PlayableCharacterProfile, height: float, ceiling: bool, should_cross: bool) -> void:
	var root := Node3D.new(); add_child(root)
	var r := profile.standing_height / 1.896
	_box(root, Vector3(0, -0.1, 0) * r, Vector3(12, 0.2, 4) * r)
	_box(root, Vector3(2, height * 0.5, 0) * r, Vector3(4, height, 4) * r)
	if ceiling: _box(root, Vector3(0, 1.9, 0) * r, Vector3(6, 0.1, 4) * r)
	var body := _body(root, profile); body.position = Vector3(-1.0, 0.01, 0) * r
	var ctx := TraversalContext.new(body, profile, null); ctx.delta = 1.0 / 60.0
	for i in 75:
		await get_tree().physics_frame
		body.velocity = Vector3(2.0 * r, -2.0 * r, 0)
		ctx.grounded = body.is_on_floor()
		WorldSupport.try_step_up(ctx)
		body.move_and_slide()
	_check((body.position.x > 0.5 * r) == should_cross, "%s step %.2f ceiling=%s x=%.3f" % [profile.id, height, ceiling, body.position.x/r])
	# Falling and rising bodies must never be pulled onto a ledge.
	body.position = Vector3(-0.45, height + 0.1, 0) * r; body.velocity = Vector3(2, -2, 0) * r; ctx.grounded = false
	var before := body.position
	_check(not WorldSupport.try_step_up(ctx) and body.position == before, "airborne auto-step " + profile.id)
	root.free()

func _ramp(profile: PlayableCharacterProfile) -> void:
	var root := Node3D.new(); add_child(root)
	var r := profile.standing_height / 1.896
	_box(root, Vector3(0,-0.1,0)*r, Vector3(14,0.2,4)*r)
	var angle := deg_to_rad(15.0)
	var ramp := _box(root, Vector3(2,0.1+2*tan(angle)-0.1/cos(angle),0)*r, Vector3(4/cos(angle),0.2,4)*r)
	ramp.rotation.z = angle; ramp.collision_layer |= TownProps.BLORB_CLIMBABLE_LAYER
	var top := 0.1 + 4*tan(angle) + 0.15
	_box(root, Vector3(6,top*0.5,0)*r, Vector3(4,top,4)*r)
	var body := _body(root,profile); body.position = Vector3(-1,0.01,0)*r
	var ctx := TraversalContext.new(body,profile,null); ctx.delta=1.0/60.0
	for i in 240:
		await get_tree().physics_frame
		body.velocity=Vector3(2*r,-0.3*r,0); ctx.grounded=body.is_on_floor()
		WorldSupport.try_step_up(ctx); body.move_and_slide()
	_check(body.position.x>4.5*r and body.position.y>=top*r-0.02*r,"tagged ramp and raised landing %s pos=%s top=%.2f" % [profile.id, body.position/r,top])
	root.free()


func _bank(profile: PlayableCharacterProfile) -> void:
	var root := Node3D.new(); add_child(root)
	var r := profile.standing_height / 1.896
	_box(root, Vector3(2, -1.2, 0) * r, Vector3(4, 0.2, 4) * r)
	var body := _body(root, profile); body.position = Vector3(-1.0, -1.4, 0) * r
	var liquid := LiquidEnvironment.new(); liquid.liquid = LiquidEnvironment.Liquid.WATER; liquid.surface_height = 0
	var ctx := TraversalContext.new(body, profile, null); ctx.delta = 1.0/60.0; ctx.direction = Vector3.RIGHT
	var stood := false
	for i in 100:
		await get_tree().physics_frame
		liquid.floor_height = -10
		var standing := liquid.try_stand(ctx, 0, 1.596*r)
		stood = stood or standing
		body.velocity = Vector3(2*r, -0.5*r if standing else 0.0, 0)
		body.move_and_slide()
	_check(stood and body.position.x > r and body.position.y >= -1.11*r, "swim onto bank lip " + profile.id)
	root.free()


func _liquid(profile: PlayableCharacterProfile) -> void:
	var root := Node3D.new(); add_child(root)
	var r := profile.standing_height / 1.896
	var body := _body(root, profile); body.position = Vector3(0, 0.2, 0) * r
	var floor := _box(root, Vector3(0, 0.3, 0) * r, Vector3(5, 0.2, 5) * r)
	var liquid := LiquidEnvironment.new(); liquid.liquid = LiquidEnvironment.Liquid.WATER; liquid.surface_height = 1.6 * r; liquid.floor_height = -10
	var ctx := TraversalContext.new(body, profile, null); ctx.delta = 1.0 / 60.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	body.velocity.y = 2*r
	_check(liquid.try_stand(ctx, 0.0, 1.596 * r), "untagged shallow landing " + profile.id)
	_check(is_zero_approx(body.velocity.y), "standing retains upward swim velocity " + profile.id)
	_check(not liquid.deep_enough_to_swim(1.596 * r), "physical floor overrides lakebed " + profile.id)
	body.position.y = 0.2 * r; liquid.surface_height = 3 * r
	_check(not liquid.try_stand(ctx, 0, 1.596 * r), "deep underwater floor became standing " + profile.id)
	_check(liquid.deep_enough_to_swim(1.596*r), "deep water failed to switch back to swimming " + profile.id)
	liquid.surface_height = 1.6 * r
	_box(root, Vector3(0, 2.05, 0) * r, Vector3(5, 0.1, 5) * r)
	await get_tree().physics_frame
	_check(not liquid.try_stand(ctx, 0, 1.596 * r), "standing lifted through ceiling " + profile.id)
	floor.rotation.z = deg_to_rad(70)
	await get_tree().physics_frame
	_check(not liquid.try_stand(ctx, 0, 1.596 * r), "steep face became standing " + profile.id)
	root.free()

func _flight(profile: PlayableCharacterProfile) -> void:
	var body := CharacterBody3D.new(); add_child(body)
	var suit := Suit.new(); suit.chest = true
	var ctx := TraversalContext.new(body, profile, null, suit); ctx.direction = Vector3.UP
	var r := ctx.height_ratio(); var head := 1.596 * r
	var liquid := LiquidEnvironment.new(); liquid.liquid = LiquidEnvironment.Liquid.WATER; liquid.surface_height = 0
	var mode := FlightMode.new(); body.position.y = -3 * r
	_check(not mode.update_liquid_exit(ctx, liquid, head, 0), "air flight activated deep underwater " + profile.id)
	body.position.y = -LiquidEnvironment.float_depth(head)
	_check(mode.update_liquid_exit(ctx, liquid, head, 0), "surface flight exit unavailable " + profile.id)
	body.position.y += 0.4 * r
	_check(mode.update_liquid_exit(ctx, liquid, head, 0), "surface clamp recaptured ascent " + profile.id)
	mode.apply_liquid_exit(ctx)
	_check(body.velocity.y > 0, "exit has no upward propulsion " + profile.id)
	ctx.direction = Vector3.DOWN
	_check(not mode.update_liquid_exit(ctx, liquid, head, 0), "dive retained flight escape " + profile.id)
	suit.chest = false; suit.feet = true; ctx.direction = Vector3.UP
	_check(mode.update_liquid_exit(ctx, liquid, head, 0), "Air feet cannot exit " + profile.id)
	suit.feet = false
	var left := Blorb.new(); left.element_state = "fire"; left.current_mp = 20
	var right := Blorb.new(); right.element_state = "fire"; right.current_mp = 20
	suit.slots = {"arm_left": left, "arm_right": right}
	Input.action_press("left_arm_power"); Input.action_press("right_arm_power")
	mode.reset()
	_check(not mode.suppress_fire(liquid, false), "wading incorrectly suppresses Fire " + profile.id)
	var powers := SuitPowers.new(); powers.update(suit, 0.016, true, false, false, 0, mode.suppress_fire(liquid, true))
	_check(not powers.any_fire() and not powers.powered_hover_active(), "Fire powered underwater in water " + profile.id)
	_check(mode.update_liquid_exit(ctx, liquid, head, 0), "surface Fire exit unavailable " + profile.id)
	liquid.liquid = LiquidEnvironment.Liquid.LAVA
	_check(mode.update_liquid_exit(ctx, liquid, head, 0), "lava Fire exit unavailable " + profile.id)
	powers.update(suit, 0.016, true)
	_check(powers.fire_hand_hover, "Fire propulsion disabled in lava " + profile.id)
	Input.action_release("left_arm_power"); Input.action_release("right_arm_power")
	left.free(); right.free(); body.free()

func _drivers() -> void:
	var player := preload("res://scenes/player.tscn").instantiate() as Player
	add_child(player); player.set_physics_process(false); player.set_process(false)
	var monkey := preload("res://scenes/xiao_hou_zi.tscn").instantiate() as XiaoHouZi
	add_child(monkey); monkey.set_physics_process(false); monkey.set_process(false)
	for body: CharacterBody3D in [player, monkey]:
		var profile: PlayableCharacterProfile = body.get("_playable_profile")
		var r := profile.standing_height / 1.896
		var head: float = body.call("_head_height")
		var floor := _box(self, Vector3(20, -head * 0.85 - 0.1*r, 0), Vector3(4, 0.2 * r, 4))
		body.global_position = Vector3(20, -head * 0.877 + (Player.FOOT_OFFSET if body == player else 0.0), 0); body.velocity = Vector3.ZERO
		await get_tree().physics_frame
		await get_tree().physics_frame
		if body == player:
			player.call("_update_lake_buoyancy", 0.016)
			_check(not bool(player.get("_lake_buoyancy_active")), "human driver still swims above a shallow built floor")
		else:
			monkey.prepare_direct_control_environment(0.016)
			_check(not bool(monkey.get("_direct_diving")), "Xiao driver still swims above a shallow built floor")
		floor.free()
		var original_suit: BlorbSuitController = body.get("_blorb_suit")
		var flight_suit := Suit.new(); flight_suit.chest = true; body.set("_blorb_suit", flight_suit)
		body.position = Vector3(20, -head * 3.0, 0)
		if body == player:
			player.call("_update_lake_buoyancy", 0.016)
			player.call("_update_air_flight")
			_check(bool(player.get("_lake_buoyancy_active")) and not bool(player.get("_air_flight_active")), "human chest flies deep underwater")
		else:
			monkey.prepare_direct_control_environment(0.016, Vector3.UP)
			_check(bool(monkey.get("_direct_diving")) and not bool(monkey.get("_direct_flying")), "Xiao chest flies deep underwater")
		body.position.y = -head * 0.877 + (Player.FOOT_OFFSET if body == player else 0.0)
		if body == player:
			player.camera.global_basis = Basis(Vector3.RIGHT, -PI/4)
			Input.action_press("move_back")
			player.call("_update_lake_buoyancy", 0.016)
			player.call("_update_air_flight")
			_check(not bool(player.get("_lake_buoyancy_active")) and bool(player.get("_air_flight_active")), "human surface flight remains swimming")
			Input.action_release("move_back")
		else:
			monkey.prepare_direct_control_environment(0.016, Vector3.UP)
			_check(not bool(monkey.get("_direct_diving")) and bool(monkey.get("_direct_flying")), "Xiao surface flight remains swimming")
		body.set("_blorb_suit", original_suit)
		if body == player:
			var collider: CollisionShape3D = player.get("_collision_shape")
			var rest: Transform3D = player.get("_standing_collision_transform")
			collider.transform = Transform3D(Basis(Vector3.FORWARD, PI/2), Vector3(0,0.4,0))
			var water_head: float = player.call("_head_height")
			player.position = Vector3(30,-water_head*0.877 + Player.FOOT_OFFSET,0)
			var floor_y := -water_head*0.85
			var support := _box(self,Vector3(30,floor_y-0.1,0),Vector3(4,0.2,4))
			var roof := _box(self,Vector3(30,floor_y+1.55,0),Vector3(4,0.1,4))
			await get_tree().physics_frame
			await get_tree().physics_frame
			player.call("_update_lake_buoyancy",0.016)
			_check(bool(player.get("_lake_buoyancy_active")),"horizontal swimmer stood into a low ceiling")
			collider.transform=rest; support.free(); roof.free()
	player.free(); monkey.free()
