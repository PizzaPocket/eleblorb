extends Node

class FlightSuit extends BlorbSuitController:
	var equipped := true
	func has_chest_air_blorb() -> bool:
		return equipped

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _ready() -> void:
	call_deferred("run")

func map_rig(p: Dictionary) -> Dictionary:
	var result := {}
	for side in ["left", "right"]:
		for pair in [["hip", "leg"], ["knee", "knee"], ["ankle", "ankle"]]:
			result["leg_" + side + "_" + pair[0]] = p[pair[1] + "_" + side]
		result["arm_" + side + "_shoulder"] = p["arm_" + side]
		result["arm_" + side + "_elbow"] = p["elbow_" + side]
	for name in ["spine", "hips", "head"]:
		result[name] = p[name]
	return result

func shape_height(shape: Shape3D) -> float:
	if shape is SphereShape3D:
		return (shape as SphereShape3D).radius * 2.0
	return float(shape.get("height"))

func mesh_top(body: Node3D) -> float:
	var top := -INF
	for mesh: MeshInstance3D in body.find_children("*", "MeshInstance3D", true, false):
		var bounds := mesh.get_aabb()
		for corner in 8:
			top = maxf(top, (mesh.global_transform * bounds.get_endpoint(corner)).y)
	return top

func run() -> void:
	var flight_body := CharacterBody3D.new()
	get_tree().root.add_child(flight_body)
	var suit := FlightSuit.new()
	var flight_ctx := TraversalContext.new(flight_body, PlayableCharacterProfile.human(), RigAdapter.new(), suit)
	var flight := FlightMode.new()
	check(not flight.toggle(flight_ctx, false), "Chest must not auto-start flight")
	check(flight.toggle(flight_ctx, true) and flight.toggle_consumed, "Jump must toggle flight on and consume input")
	check(flight.toggle(flight_ctx, false), "Flight must persist between presses")
	check(not flight.toggle(flight_ctx, true), "Second jump must toggle flight off")
	check(not flight.toggle(flight_ctx, true, false), "Swimming must not toggle flight")
	flight.toggle(flight_ctx, true)
	suit.equipped = false
	check(not flight.toggle(flight_ctx, false) and not flight.enabled, "Removing chest must clear flight latch")
	flight_body.queue_free()
	for small in [false, true]:
		var body := CharacterBody3D.new()
		get_tree().root.add_child(body)
		body.position.x = 5.0 if small else 0.0
		var pivots: Dictionary = MonkeyFigure.build(body, MonkeyFigure.MONKEY_FUR_COLOR, 2.3585) if small else ProceduralFigure.build(body)
		var rig := RigAdapter.new(map_rig(pivots))
		var ctx := TraversalContext.new(body, PlayableCharacterProfile.xiao_hou_zi() if small else PlayableCharacterProfile.human(), rig)
		var collider := CollisionShape3D.new()
		var shape: Shape3D
		var standing_height := 0.16 * 2.3585 if small else 1.8
		if small:
			var sphere := SphereShape3D.new()
			sphere.radius = standing_height * 0.5
			shape = sphere
		else:
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.4
			capsule.height = standing_height
			shape = capsule
		collider.shape = shape
		collider.position.y = standing_height * 0.5
		body.add_child(collider)
		ctx.standing_collision = collider
		ctx.standing_collision_transform = collider.transform
		ctx.delta = 1.0 / 60.0
		var standing_top := mesh_top(body)
		var crouch := CrouchMode.new()
		var standing_head := (pivots["head"] as Node3D).global_position.y
		var left_foot := (pivots["ankle_left"] as Node3D).global_position
		for frame in 30:
			crouch.prepare(ctx)
			crouch.step(ctx, frame == 0, true)
			crouch.pose(ctx)
		var head := (pivots["head"] as Node3D).global_position.y
		print("Crouch rig=", small, " head=", head, " standing_head=", standing_head, " collider_top=", collider.position.y + shape_height(collider.shape) * 0.5)
		if small:
			MonkeyFigure.rebuild_limbs(pivots, body, ctx.delta)
		var bounds_top := mesh_top(body)
		var visual_tolerance := maxf(0.0, standing_top - standing_height) + ctx.scaled(0.015)
		check(bounds_top <= collider.position.y + shape_height(collider.shape) * 0.5 + visual_tolerance, "Crouched rig must fit its collider's existing visual tolerance")
		check(head < standing_head, "Head must lower on each rig")
		check((pivots["ankle_left"] as Node3D).global_position.distance_to(left_foot) < 0.005, "Foot must remain planted")
		check(absf(crouch.speed_factor() - 0.4) < 0.001, "Crouch must override sprint speed")
		check(absf(collider.position.y - shape_height(collider.shape) * 0.5) < 0.001, "Collider must keep its bottom fixed")
		var roof := StaticBody3D.new()
		var roof_collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0, 0.04, 2.0)
		roof_collision.shape = box
		roof.add_child(roof_collision)
		get_tree().root.add_child(roof)
		roof.position = body.position + Vector3.UP * (shape_height(collider.shape) + 0.04)
		await get_tree().physics_frame
		await get_tree().physics_frame
		var start_x := body.position.x
		for frame in 10:
			body.velocity = Vector3(0.5, 0.0, 0.0)
			body.move_and_slide()
			await get_tree().physics_frame
		check(body.position.x > start_x + 0.05, "Crouch must move beneath a ceiling that blocks standing")
		check(not crouch.can_stand(ctx), "Ceiling must prevent standing")
		crouch.prepare(ctx)
		crouch.step(ctx, true, true)
		check(crouch.active, "Blocked stand must keep crouch active")
		check(not crouch.leave(ctx), "Swing/full-body powers must wait under a low ceiling")
		roof.position.y += 10.0
		await get_tree().physics_frame
		await get_tree().physics_frame
		check(crouch.can_stand(ctx), "Clear space must permit standing")
		# Busy power arms retain their exact firing pose.
		crouch.prepare(ctx)
		ctx.left_arm_busy = true
		var shoulder := rig.joint("arm_left_shoulder")
		shoulder.rotation = Vector3(-1.2, 0.2, 0.3)
		crouch.pose(ctx)
		check(shoulder.rotation.is_equal_approx(Vector3(-1.2, 0.2, 0.3)), "Crouch must preserve firing arms")
		crouch.prepare(ctx)
		crouch.step(ctx, false, false)
		check(not crouch.active and crouch.amount == 0.0, "Entering swimming must release crouch")
		check(is_equal_approx(shape_height(collider.shape), standing_height), "Swimming transition must restore collider")
		body.queue_free()
		roof.queue_free()
	await get_tree().process_frame
	print("Crouch checks: ", failures, " failures")
	get_tree().quit(1 if failures else 0)
