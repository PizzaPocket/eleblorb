extends Node3D

## The Ocean Kingdom's two moving parkour landmarks (its Kraken, see Kraken,
## and a sailing pirate ship) plus its first NME pack.
## Everything is procedural so it shares Eleblorbs' rounded toy-like world.

const NPC_SCENE := preload("res://scenes/npc.tscn")
const FISH_GOBLIN_SCENE := preload("res://scenes/fish_goblin_nme.tscn")
const WOOD := Color(0.30, 0.12, 0.045)
const SAIL := Color(0.86, 0.79, 0.62)
# Keep the two landmark patrols in opposite halves of the ocean. The old
# ship path crossed nearly the full world independently of the Kraken loop;
# different phases could therefore bring two enormous collision footprints
# onto the same water. These closed, disjoint bands make separation a route
# invariant rather than merely choosing two different spawn points.
const KRAKEN_ROUTE_CENTER := Vector2.ZERO
## Widened alongside the kraken itself (see Kraken.DISPLAY_SCALE), so a
## larger body still has its own sea room to swim in.
const KRAKEN_ROUTE_RADIUS := Vector2(430.0, 350.0)
const SHIP_ROUTE_CENTER := Vector2.ZERO
const SHIP_ROUTE_RADIUS := Vector2(350.0, 285.0)
const SHIP_ROUTE_ANGULAR_SPEED := 0.018
const SHIP_ROUTE_START_ANGLE := -PI * 0.5
var _kraken: Kraken
var _ship: AnimatableBody3D
var _time := 0.0
var _terrain: Node


func _ready() -> void:
	_terrain = get_node_or_null("../Terrain")
	_kraken = Kraken.new()
	_kraken.route_center = KRAKEN_ROUTE_CENTER
	_kraken.route_radius = KRAKEN_ROUTE_RADIUS
	_kraken.water_level = 0.0
	_kraken.terrain = _terrain
	add_child(_kraken)
	_build_ship()
	_update_landmarks(0.0, 0.0)
	_spawn_fish_goblins()


func _physics_process(delta: float) -> void:
	_time += delta
	_update_landmarks(_time, delta)


func _update_landmarks(time: float, delta: float) -> void:
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
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position = position
	collision.basis = basis
	body.add_child(collision)


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
		goblin.position = Vector3(KRAKEN_ROUTE_CENTER.x + cos(angle) * 410.0, -14.0, KRAKEN_ROUTE_CENTER.y + sin(angle) * 365.0)
