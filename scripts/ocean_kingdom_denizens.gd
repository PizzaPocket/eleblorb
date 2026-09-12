extends Node3D

## The Ocean Kingdom's two moving parkour landmarks plus its first NME pack.
## Everything is procedural so it shares Eleblorbs' rounded toy-like world.

const NPC_SCENE := preload("res://scenes/npc.tscn")
const FISH_GOBLIN_SCENE := preload("res://scenes/fish_goblin_nme.tscn")
const WOOD := Color(0.30, 0.12, 0.045)
const SAIL := Color(0.86, 0.79, 0.62)
const KRAKEN := Color(0.82, 0.24, 0.09)
const KRAKEN_SPLOTCH := Color(0.05, 0.52, 0.52)
# Keep the two landmark patrols in opposite halves of the ocean. The old
# ship path crossed nearly the full world independently of the Kraken loop;
# different phases could therefore bring two enormous collision footprints
# onto the same water. These closed, disjoint bands make separation a route
# invariant rather than merely choosing two different spawn points.
const KRAKEN_ROUTE_CENTER := Vector2.ZERO
const KRAKEN_ROUTE_RADIUS := Vector2(250.0, 205.0)
const KRAKEN_ROUTE_ANGULAR_SPEED := 0.006
const KRAKEN_IDLE_DURATION := 18.0
const KRAKEN_SWIM_DURATION := 12.0
const SHIP_ROUTE_CENTER := Vector2.ZERO
const SHIP_ROUTE_RADIUS := Vector2(350.0, 285.0)
const SHIP_ROUTE_ANGULAR_SPEED := 0.018
const SHIP_ROUTE_START_ANGLE := -PI * 0.5
var _kraken: AnimatableBody3D
var _ship: AnimatableBody3D
var _tentacle_roots: Array[Node3D] = []
## Kraken visuals articulate below ordinary Node3D pivots, but Godot only
## activates CollisionShape3D nodes that are direct children of a
## CollisionObject3D. Keep mesh/collider pairs here and mirror each visual's
## live transform onto a direct child of _kraken every physics tick.
var _kraken_colliders: Array[Dictionary] = []
var _kraken_mantle: Node3D
var _kraken_eye: MeshInstance3D
var _kraken_eye_blink := EyeBlink.new_state()
var _kraken_route_angle := 0.0
var _kraken_swim_elapsed := 0.0
var _time := 0.0
var _terrain: Node


func _ready() -> void:
	_terrain = get_node_or_null("../Terrain")
	_build_kraken()
	_build_ship()
	_update_landmarks(0.0, 0.0)
	_spawn_fish_goblins()


func _physics_process(delta: float) -> void:
	_time += delta
	_update_landmarks(_time, delta)


func _update_landmarks(time: float, delta: float) -> void:
	if _kraken != null:
		var cycle_time := fmod(time, KRAKEN_IDLE_DURATION + KRAKEN_SWIM_DURATION)
		var swimming := cycle_time >= KRAKEN_IDLE_DURATION
		if swimming:
			_kraken_route_angle += KRAKEN_ROUTE_ANGULAR_SPEED * delta
			_kraken_swim_elapsed += delta
		var kraken_angle := _kraken_route_angle
		var kraken_x: float = KRAKEN_ROUTE_CENTER.x + cos(kraken_angle) * KRAKEN_ROUTE_RADIUS.x
		var kraken_z: float = KRAKEN_ROUTE_CENTER.y + sin(kraken_angle) * KRAKEN_ROUTE_RADIUS.y
		var kraken_floor: float = float(_terrain.get_mesh_height(kraken_x, kraken_z)) if _terrain != null else -42.0
		# The full relaxed tentacle fan reaches roughly 26 metres below the
		# body's origin. Floor-aware clearance makes clipping impossible even
		# if its route later crosses a shallower ridge.
		var kraken_y: float = maxf(-8.0 + sin(time * 0.22) * 0.45, kraken_floor + 29.0)
		_kraken.position = Vector3(kraken_x, kraken_y, kraken_z)
		var route_velocity := Vector2(
			-sin(kraken_angle) * KRAKEN_ROUTE_RADIUS.x,
			cos(kraken_angle) * KRAKEN_ROUTE_RADIUS.y
		).normalized()
		if _kraken_mantle != null:
			var target_basis := Basis.IDENTITY
			if swimming:
				# The mantle's local +Y axis is its crown. Aim that axis along the
				# route while swimming; at rest it eases upright again.
				var heading := Vector3(route_velocity.x, 0.0, route_velocity.y).normalized()
				var right := Vector3.UP.cross(heading).normalized()
				target_basis = Basis(right, heading, right.cross(heading)).orthonormalized()
			var current_rotation := _kraken_mantle.basis.get_rotation_quaternion()
			var target_rotation := target_basis.get_rotation_quaternion()
			_kraken_mantle.basis = Basis(current_rotation.slerp(target_rotation, clampf(delta * 0.75, 0.0, 1.0)))
		for index in _tentacle_roots.size():
			var root := _tentacle_roots[index]
			root.rotation.y = TAU * float(index) / 12.0 + sin(time * 0.34 + index * 0.73) * (0.06 if swimming else 0.11)
			root.rotation.x = sin(time * 0.46 + index) * (0.04 if swimming else 0.075)
			root.rotation.z = cos(time * 0.39 + index * 0.61) * (0.04 if swimming else 0.075)
			if swimming:
				# A squid-like propulsion beat: the crown advances as the arms
				# gather inward, then the tentacles relax and extend behind it.
				var thrust_cycle := 0.5 + 0.5 * sin(_kraken_swim_elapsed * TAU * 0.28)
				var gather := pow(thrust_cycle, 2.0)
				root.scale = Vector3(lerpf(1.0, 0.72, gather), lerpf(1.0, 0.64, gather), lerpf(1.0, 0.76, gather))
			else:
				root.scale = root.scale.lerp(Vector3.ONE, clampf(delta * 0.8, 0.0, 1.0))
		_sync_kraken_colliders()
		EyeBlink.apply(_kraken_eye_blink, delta, [_kraken_eye])
	if _ship != null:
		var ship_angle := SHIP_ROUTE_START_ANGLE + time * SHIP_ROUTE_ANGULAR_SPEED
		var route_x := SHIP_ROUTE_CENTER.x + cos(ship_angle) * SHIP_ROUTE_RADIUS.x
		var route_z := SHIP_ROUTE_CENTER.y + sin(ship_angle) * SHIP_ROUTE_RADIUS.y
		var forward := Vector2(
			-sin(ship_angle) * SHIP_ROUTE_RADIUS.x,
			cos(ship_angle) * SHIP_ROUTE_RADIUS.y
		).normalized()
		_ship.position = Vector3(route_x, 0.0, route_z)
		_ship.rotation.y = atan2(forward.x, forward.y)
		_ship.rotation.z = sin(time * 0.55) * deg_to_rad(1.8)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	return material


func _add_box(body: Node3D, position: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> Node3D:
	var part := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	part.position = position
	part.rotation = rotation
	body.add_child(part)
	if _is_kraken_visual_parent(body):
		_add_kraken_mesh_collider(part)
	else:
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		collision.position = position
		collision.rotation = rotation
		body.add_child(collision)
	return part


func _add_capsule(body: Node3D, position: Vector3, radius: float, height: float, color: Color, basis := Basis()) -> void:
	var part := SuperEgg.build_part(Vector3(radius, height * 0.5, radius), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	part.position = position
	part.basis = basis
	body.add_child(part)
	if _is_kraken_visual_parent(body):
		_add_kraken_mesh_collider(part)
	else:
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		collision.position = position
		collision.basis = basis
		body.add_child(collision)


func _is_kraken_visual_parent(node: Node3D) -> bool:
	return _kraken != null and node != _kraken and _kraken.is_ancestor_of(node)


func _add_kraken_mesh_collider(part: MeshInstance3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "%sCollision" % part.name
	# Every Kraken construction primitive is convex. A mesh-derived convex
	# hull hugs the rounded SuperEgg itself instead of surrounding it with a
	# box/capsule bubble, which makes feet land on the visible surface.
	collision.shape = part.mesh.create_convex_shape(true, true)
	_kraken.add_child(collision)
	_kraken_colliders.append({"visual": part, "collision": collision})


func _sync_kraken_colliders() -> void:
	var kraken_inverse := _kraken.global_transform.affine_inverse()
	for binding: Dictionary in _kraken_colliders:
		var visual := binding["visual"] as MeshInstance3D
		var collision := binding["collision"] as CollisionShape3D
		if visual != null and collision != null:
			collision.transform = kraken_inverse * visual.global_transform


func _add_capsule_between(body: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
	var direction := to - from
	var length := direction.length()
	if length <= 0.001:
		return
	var up := direction / length
	var side := up.cross(Vector3.FORWARD)
	if side.length() < 0.01:
		side = up.cross(Vector3.RIGHT)
	side = side.normalized()
	var forward := side.cross(up).normalized()
	_add_capsule(body, (from + to) * 0.5, radius, length + radius * 1.5, color, Basis(side, up, forward))


func _build_kraken() -> void:
	_kraken = AnimatableBody3D.new()
	_kraken.name = "TwelveTentacledKraken"
	_kraken.collision_layer = 1
	# This script drives the body directly on physics ticks. Register it in
	# the physics world at its real route position from the outset rather than
	# briefly constructing the entire landmark at the player's origin; the
	# AnimatableBody synchronization cache could otherwise retain that origin.
	_kraken.sync_to_physics = false
	_kraken.position = Vector3(
		KRAKEN_ROUTE_CENTER.x + KRAKEN_ROUTE_RADIUS.x,
		-8.0,
		KRAKEN_ROUTE_CENTER.y
	)
	add_child(_kraken)
	_kraken_mantle = Node3D.new()
	_kraken_mantle.name = "DirectionalMantle"
	_kraken.add_child(_kraken_mantle)
	_add_capsule(_kraken_mantle, Vector3(0, 6.0, 0), 4.8, 13.0, KRAKEN)
	# A flattened, nearly square SuperEgg rotated onto one corner gives the
	# squid's broad diamond fin without introducing a separate triangle mesh.
	_add_box(_kraken_mantle, Vector3(0, 13.2, -0.4), Vector3(7.6, 7.6, 2.5), KRAKEN, Vector3(0.0, 0.0, deg_to_rad(45.0)))
	_add_kraken_splotches()
	_add_kraken_eyes()
	_add_kraken_mouth()
	for index in 12:
		var root := Node3D.new()
		root.name = "Tentacle%02d" % (index + 1)
		root.rotation.y = TAU * float(index) / 12.0
		root.position = Vector3(0.0, 0.8, 0.0)
		_kraken_mantle.add_child(root)
		_tentacle_roots.append(root)
		var previous := Vector3(0.0, 0.0, 2.8)
		for segment in 8:
			var progress := float(segment + 1) / 8.0
			var next := Vector3(
				sin(progress * PI * 1.25 + index * 0.31) * (0.65 + progress * 1.5),
				-progress * 24.0,
				2.8 + progress * 3.8
			)
			var radius := lerpf(1.5, 0.58, progress)
			_add_capsule_between(root, previous, next, radius, KRAKEN.lightened(progress * 0.035))
			if (segment + index) % 2 == 0:
				var spot := SuperEgg.build_part(Vector3(radius * 0.48, radius * 0.62, 0.10), KRAKEN_SPLOTCH, 2.4, 2.4)
				spot.position = (previous + next) * 0.5 + Vector3(0.0, 0.0, radius * 0.92)
				root.add_child(spot)
			previous = next


func _add_kraken_eyes() -> void:
	# One centered living-world eye: a dark skin-derived marking with no white.
	_kraken_eye = SuperEgg.build_part(Vector3(0.82, 1.05, 0.34), KRAKEN.darkened(0.42), 2.4, 2.4)
	_kraken_eye.name = "SingleEye"
	_kraken_eye.position = Vector3(0.0, 4.5, 4.55)
	_kraken_mantle.add_child(_kraken_eye)
	# Skin-coloured upper lid overlaps and encloses the upper third. A flat
	# lower edge and round crown give it the requested heavy semicircle.
	var lid := SuperEgg.build_part(Vector3(1.02, 0.55, 0.42), KRAKEN, 2.0, SuperEgg.EPSILON_FLAT)
	lid.name = "UpperEyelid"
	lid.position = Vector3(0.0, 5.4, 4.68)
	_kraken_mantle.add_child(lid)


func _add_kraken_splotches() -> void:
	for index in 26:
		var angle := TAU * float(index) / 26.0 + sin(float(index) * 2.7) * 0.23
		var y := 1.2 + fmod(float(index) * 2.17, 10.8)
		var radial := Vector3(sin(angle), 0.0, cos(angle))
		var patch := SuperEgg.build_part(
			Vector3(0.42 + fmod(float(index), 4.0) * 0.11, 0.62 + fmod(float(index), 3.0) * 0.14, 0.10),
			KRAKEN_SPLOTCH, 2.5, 2.5
		)
		patch.name = "TealSplotch%02d" % index
		patch.position = radial * 4.72 + Vector3.UP * y
		patch.basis = Basis.looking_at(-radial, Vector3.UP)
		_kraken_mantle.add_child(patch)


func _add_kraken_mouth() -> void:
	var mouth := Area3D.new()
	mouth.name = "ToothedMouth"
	mouth.position = Vector3(0.0, 0.05, 0.0)
	mouth.collision_layer = 0
	mouth.collision_mask = 1
	_kraken_mantle.add_child(mouth)
	var opening := SuperEgg.build_part(Vector3(1.65, 0.16, 1.65), Color(0.18, 0.025, 0.02), 2.0, 2.0)
	mouth.add_child(opening)
	for index in 16:
		var angle := TAU * float(index) / 16.0
		var tooth := SuperEgg.build_part(Vector3(0.18, 0.5, 0.18), Color(0.95, 0.83, 0.62), 0.75, SuperEgg.EPSILON_FLAT)
		tooth.position = Vector3(cos(angle) * 1.15, -0.22, sin(angle) * 1.15)
		tooth.rotation.x = sin(angle) * deg_to_rad(48.0)
		tooth.rotation.z = -cos(angle) * deg_to_rad(48.0)
		mouth.add_child(tooth)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.45
	shape.height = 1.6
	collision.shape = shape
	collision.position = Vector3(0.0, -0.35, 0.0)
	mouth.add_child(collision)
	mouth.body_entered.connect(_on_kraken_mouth_entered)


func _on_kraken_mouth_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null:
		return
	var away := Vector3(player.global_position.x - _kraken.global_position.x, 0.0, player.global_position.z - _kraken.global_position.z)
	if away.length() < 0.1:
		away = Vector3.BACK
	player.escape_from_lethal_hazard(_kraken.global_position + away.normalized() * 13.0 + Vector3.UP * 9.0)


func _build_ship() -> void:
	_ship = AnimatableBody3D.new()
	_ship.name = "SailingPirateShip"
	_ship.collision_layer = 1
	_ship.sync_to_physics = false
	_ship.position = Vector3(
		SHIP_ROUTE_CENTER.x + cos(SHIP_ROUTE_START_ANGLE) * SHIP_ROUTE_RADIUS.x,
		0.0,
		SHIP_ROUTE_CENTER.y + sin(SHIP_ROUTE_START_ANGLE) * SHIP_ROUTE_RADIUS.y
	)
	add_child(_ship)
	_populate_ship(_ship)


func _populate_ship(ship: AnimatableBody3D) -> void:
	# Tall layered hull and two walkable decks.
	_add_box(ship, Vector3(0, 1.6, 0), Vector3(11, 3.2, 29), WOOD)
	_add_box(ship, Vector3(0, 3.35, 0), Vector3(10, 0.55, 27), WOOD.lightened(0.12))
	_add_box(ship, Vector3(0, 5.0, 9.5), Vector3(9, 2.8, 7), WOOD.lightened(0.08))
	_add_box(ship, Vector3(0, 6.55, 9.5), Vector3(8.5, 0.5, 7), WOOD.lightened(0.15))
	# The helm deck rises above the main deck at its aft (-Z) edge. Eight
	# overlapping, collision-backed treads make it continuously reachable
	# without requiring a jump or using the ship's exterior boarding stairs.
	var helm_stair_start_y := 3.625
	var helm_deck_y := 6.8
	var helm_stair_rise := (helm_deck_y - helm_stair_start_y) / 8.0
	for step in 8:
		var tread_top := helm_stair_start_y + float(step + 1) * helm_stair_rise
		_add_box(
			ship,
			Vector3(0.0, tread_top - 0.18, 2.85 + float(step) * 0.43),
			Vector3(2.7, 0.36, 0.92),
			WOOD.lightened(0.16)
		)
	# Exterior parkour stairs begin below waterline and climb to the main deck.
	for side in [-1.0, 1.0]:
		for step in 10:
			_add_box(ship, Vector3(side * 6.0, -0.4 + step * 0.42, -3.0 + step * 0.32), Vector3(2.4, 0.38, 1.25), WOOD.lightened(0.1))
	# Three masts, yards, and multiple broad sails after the reference's silhouette.
	for mast_data in [[-7.0, 18.0], [2.0, 23.0], [10.0, 16.0]]:
		var z := float(mast_data[0])
		var mast_height := float(mast_data[1])
		_add_capsule(ship, Vector3(0, 3.5 + mast_height * 0.5, z), 0.34, mast_height, WOOD.lightened(0.08))
		for sail_level in 3:
			var width := 9.0 - sail_level * 1.35
			var y := 9.0 + sail_level * 4.6
			var sail_height := 3.4
			# Clear the captain/helm sightline under the forward mast's lowest
			# canvas while preserving the full layered sail plan elsewhere.
			if is_equal_approx(z, 10.0) and sail_level == 0:
				y += 2.0
				sail_height = 2.4
			# The yard remains on the mast while the canvas bellies forward in
			# local +Z, making the wind load readable instead of a flat panel
			# embedded through its support.
			_add_capsule_between(ship, Vector3(-width * 0.58, y + sail_height * 0.5, z), Vector3(width * 0.58, y + sail_height * 0.5, z), 0.12, WOOD.lightened(0.08))
			_add_box(ship, Vector3(0, y, z + 0.72), Vector3(width, sail_height, 0.16), SAIL, Vector3(deg_to_rad(-6.0), 0.0, 0.0))
	_build_ship_wheel(ship)
	_add_ship_lanterns(ship)
	for index in 8:
		var pirate := NPC_SCENE.instantiate()
		var names: Array[String] = ["Captain Brine", "Mara Reef", "Old Kelp", "Nell Crow", "Tobias Wake", "Pip Salt", "Rook Gale", "Ada Shoal"]
		pirate.display_name = names[index]
		pirate.stationary = index == 0
		pirate.deck_wanderer = true
		var deck_lane_x := -2.45 if index % 2 == 0 else 2.45
		pirate.deck_wander_center = Vector2(deck_lane_x, 0.0)
		pirate.deck_wander_bounds = Vector2(0.9, 10.2)
		pirate.deck_surface_y = 6.8 if index == 0 else 3.8
		pirate.shirt_color = Color(0.28, 0.04, 0.05)
		pirate.pants_color = Color(0.08, 0.1, 0.16)
		pirate.cropped_trousers = index in [2, 4, 6]
		if index == 0:
			pirate.wears_pirate_captain_hat = true
			pirate.pirate_hat_variant = 0
			pirate.hook_hand = "right"
			pirate.at_ship_helm = true
			# Ship-local +Z is the bow. Stand aft of the wheel and face through
			# it toward the direction of travel rather than ahead of it facing
			# backward into the captain's own crew.
			pirate.facing_degrees = 0.0
			pirate.beard_style = "full"
			pirate.beard_color = Color(0.025, 0.02, 0.018)
			pirate.beard_scale = 1.5
		else:
			pirate.beard_style = "stubble" if index in [2, 5, 7] else "none"
			pirate.beard_color = Color(0.09, 0.065, 0.045)
			if index in [2, 5]:
				pirate.peg_leg = "left" if index % 2 == 0 else "right"
		# npc.gd's own _ready() only falls back to get_node("../../Terrain")
		# when terrain_ref is still null -- that relative path assumes an NPC
		# parented two levels below the same root Terrain lives under, but a
		# pirate here is a child of _ship (itself a child of this node, itself
		# a child of the kingdom root Terrain lives directly under), three
		# levels deep. Setting terrain_ref explicitly before add_child()
		# bypasses that mismatched lookup entirely, confirmed by direct
		# report ("Node not found: ../../Terrain").
		pirate.terrain_ref = _terrain
		# Assigned from a locally-typed Array[String], not a bare array literal
		# directly on the dynamically-typed `pirate` reference -- npc.gd's own
		# talk_lines is a typed Array[String], and Godot's dynamic property
		# setter doesn't coerce a plain untyped Array literal into that on
		# assignment (confirmed by direct report; every other NPC-dialogue
		# call site in this project already routes through a typed local
		# variable first, e.g. town_generator.gd's own `lines: Array[String]`).
		var lines: Array[String] = ["Keep your footing. The sea likes an overconfident sailor."]
		pirate.talk_lines = lines
		ship.add_child(pirate)
		pirate.position = Vector3(0.0, 6.8, 7.55) if index == 0 else Vector3(deck_lane_x, 3.8, -8.5 + float(index) * 2.3)


func _add_ship_lanterns(ship: AnimatableBody3D) -> void:
	# Shared surface-lantern nodes are already driven by DayNightCycle: their
	# real light and emissive globe fade on at dusk and off after sunrise.
	# Parenting locally to the vessel keeps them attached while it sails.
	var positions: Array[Vector3] = [
		Vector3(-4.0, 3.65, -9.0), Vector3(4.0, 3.65, -9.0),
		Vector3(-4.0, 3.65, 4.0), Vector3(4.0, 3.65, 4.0),
		Vector3(-3.25, 6.8, 10.6), Vector3(3.25, 6.8, 10.6),
	]
	for lantern_position: Vector3 in positions:
		var lantern := TownProps.build_lantern()
		lantern.name = "ShipNightLantern"
		lantern.position = lantern_position
		ship.add_child(lantern)


func _build_ship_wheel(ship: AnimatableBody3D) -> void:
	var wheel := Node3D.new()
	wheel.name = "SteeringWheel"
	wheel.position = Vector3(0.0, 7.8, 9.0)
	ship.add_child(wheel)
	var radius := 1.05
	for index in 12:
		var a := TAU * float(index) / 12.0
		var b := TAU * float(index + 1) / 12.0
		_add_capsule_between(wheel, Vector3(cos(a) * radius, sin(a) * radius, 0.0), Vector3(cos(b) * radius, sin(b) * radius, 0.0), 0.095, WOOD.lightened(0.16))
	for index in 8:
		var angle := TAU * float(index) / 8.0
		_add_capsule_between(wheel, Vector3.ZERO, Vector3(cos(angle) * 1.3, sin(angle) * 1.3, 0.0), 0.075, WOOD.lightened(0.2))


func _spawn_fish_goblins() -> void:
	for index in 8:
		var goblin := FISH_GOBLIN_SCENE.instantiate()
		add_child(goblin)
		var angle := TAU * float(index) / 8.0
		goblin.position = Vector3(KRAKEN_ROUTE_CENTER.x + cos(angle) * 235.0, -14.0, KRAKEN_ROUTE_CENTER.y + sin(angle) * 220.0)
