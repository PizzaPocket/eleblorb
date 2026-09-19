class_name Kraken
extends AnimatableBody3D

## The twelve-tentacled Kraken: a colossal living landmark patrolling an
## ellipse of deep sea, idling a while then swimming on round its route, its
## crown riding just below the surface and its relaxed tentacles hanging
## deep. Solid (every visual part carries a matching convex collider) so it
## can be climbed, and its toothed mouth throws out anyone who falls in.
## First found in the Ocean Kingdom (ocean_kingdom_denizens.gd), and placed
## by any world with a sea deep enough to hold it.

const KRAKEN := Color(0.82, 0.24, 0.09)
const KRAKEN_SPLOTCH := Color(0.05, 0.52, 0.52)
const IDLE_DURATION := 18.0
const SWIM_DURATION := 12.0
## How far below the surface the body idles, and the least clearance its
## hanging tentacles keep above the sea floor.
const IDLE_DEPTH := 8.0
const FLOOR_CLEARANCE := 29.0

## The patrol: an ellipse of these radii round this centre (world XZ), at
## this angular speed while swimming.
@export var route_center := Vector2.ZERO
@export var route_radius := Vector2(250.0, 205.0)
@export var route_angular_speed := 0.006
## The sea's surface height.
@export var water_level := 0.0
## Answers get_mesh_height(); the sea floor it must clear.
var terrain: Node

var _tentacle_roots: Array[Node3D] = []
## Kraken visuals articulate below ordinary Node3D pivots, but Godot only
## activates CollisionShape3D nodes that are direct children of a
## CollisionObject3D. Keep mesh/collider pairs here and mirror each visual's
## live transform onto a direct child of the body every physics tick.
var _colliders: Array[Dictionary] = []
var _mantle: Node3D
var _eye: MeshInstance3D
var _eye_blink := EyeBlink.new_state()
var _route_angle := 0.0
var _swim_elapsed := 0.0
var _time := 0.0


func _init() -> void:
	name = "TwelveTentacledKraken"
	collision_layer = 1
	# This script drives the body directly on physics ticks. Register it in
	# the physics world at its real route position from the outset rather than
	# briefly constructing the entire landmark at the origin; the
	# AnimatableBody synchronization cache could otherwise retain that origin.
	sync_to_physics = false


func _ready() -> void:
	position = Vector3(route_center.x + route_radius.x, water_level - IDLE_DEPTH, route_center.y)
	_build()
	_update(0.0, 0.0)


func _physics_process(delta: float) -> void:
	_time += delta
	_update(_time, delta)


func _update(time: float, delta: float) -> void:
	var cycle_time := fmod(time, IDLE_DURATION + SWIM_DURATION)
	var swimming := cycle_time >= IDLE_DURATION
	if swimming:
		_route_angle += route_angular_speed * delta
		_swim_elapsed += delta
	var x: float = route_center.x + cos(_route_angle) * route_radius.x
	var z: float = route_center.y + sin(_route_angle) * route_radius.y
	var floor_height: float = float(terrain.get_mesh_height(x, z)) if terrain != null else water_level - 42.0
	# The full relaxed tentacle fan reaches roughly 26 metres below the
	# body's origin. Floor-aware clearance makes clipping impossible even
	# if its route later crosses a shallower ridge.
	var y: float = maxf(water_level - IDLE_DEPTH + sin(time * 0.22) * 0.45, floor_height + FLOOR_CLEARANCE)
	position = Vector3(x, y, z)
	var route_velocity := Vector2(
		-sin(_route_angle) * route_radius.x,
		cos(_route_angle) * route_radius.y
	).normalized()
	if _mantle != null:
		var target_basis := Basis.IDENTITY
		if swimming:
			# The mantle's local +Y axis is its crown. Aim that axis along the
			# route while swimming; at rest it eases upright again.
			var heading := Vector3(route_velocity.x, 0.0, route_velocity.y).normalized()
			var right := Vector3.UP.cross(heading).normalized()
			target_basis = Basis(right, heading, right.cross(heading)).orthonormalized()
		var current_rotation := _mantle.basis.get_rotation_quaternion()
		var target_rotation := target_basis.get_rotation_quaternion()
		_mantle.basis = Basis(current_rotation.slerp(target_rotation, clampf(delta * 0.75, 0.0, 1.0)))
	for index in _tentacle_roots.size():
		var root := _tentacle_roots[index]
		root.rotation.y = TAU * float(index) / 12.0 + sin(time * 0.34 + index * 0.73) * (0.06 if swimming else 0.11)
		root.rotation.x = sin(time * 0.46 + index) * (0.04 if swimming else 0.075)
		root.rotation.z = cos(time * 0.39 + index * 0.61) * (0.04 if swimming else 0.075)
		if swimming:
			# A squid-like propulsion beat: the crown advances as the arms
			# gather inward, then the tentacles relax and extend behind it.
			var thrust_cycle := 0.5 + 0.5 * sin(_swim_elapsed * TAU * 0.28)
			var gather := pow(thrust_cycle, 2.0)
			root.scale = Vector3(lerpf(1.0, 0.72, gather), lerpf(1.0, 0.64, gather), lerpf(1.0, 0.76, gather))
		else:
			root.scale = root.scale.lerp(Vector3.ONE, clampf(delta * 0.8, 0.0, 1.0))
	_sync_colliders()
	EyeBlink.apply(_eye_blink, delta, [_eye])


func _add_box(parent: Node3D, part_position: Vector3, size: Vector3, color: Color, part_rotation := Vector3.ZERO) -> Node3D:
	var part := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	part.position = part_position
	part.rotation = part_rotation
	parent.add_child(part)
	_add_mesh_collider(part)
	return part


func _add_capsule(parent: Node3D, part_position: Vector3, radius: float, height: float, color: Color, part_basis := Basis()) -> void:
	var part := SuperEgg.build_part(Vector3(radius, height * 0.5, radius), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	part.position = part_position
	part.basis = part_basis
	parent.add_child(part)
	_add_mesh_collider(part)


func _add_capsule_between(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color) -> void:
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
	_add_capsule(parent, (from + to) * 0.5, radius, length + radius * 1.5, color, Basis(side, up, forward))


func _add_mesh_collider(part: MeshInstance3D) -> void:
	var collision := CollisionShape3D.new()
	collision.name = "%sCollision" % part.name
	# Every Kraken construction primitive is convex. A mesh-derived convex
	# hull hugs the rounded SuperEgg itself instead of surrounding it with a
	# box/capsule bubble, which makes feet land on the visible surface.
	collision.shape = part.mesh.create_convex_shape(true, true)
	add_child(collision)
	_colliders.append({"visual": part, "collision": collision})


func _sync_colliders() -> void:
	var kraken_inverse := global_transform.affine_inverse()
	for binding: Dictionary in _colliders:
		var visual := binding["visual"] as MeshInstance3D
		var collision := binding["collision"] as CollisionShape3D
		if visual != null and collision != null:
			collision.transform = kraken_inverse * visual.global_transform


func _build() -> void:
	_mantle = Node3D.new()
	_mantle.name = "DirectionalMantle"
	add_child(_mantle)
	_add_capsule(_mantle, Vector3(0, 6.0, 0), 4.8, 13.0, KRAKEN)
	# A flattened, nearly square SuperEgg rotated onto one corner gives the
	# squid's broad diamond fin without introducing a separate triangle mesh.
	_add_box(_mantle, Vector3(0, 13.2, -0.4), Vector3(7.6, 7.6, 2.5), KRAKEN, Vector3(0.0, 0.0, deg_to_rad(45.0)))
	_add_splotches()
	_add_eyes()
	_add_mouth()
	for index in 12:
		var root := Node3D.new()
		root.name = "Tentacle%02d" % (index + 1)
		root.rotation.y = TAU * float(index) / 12.0
		root.position = Vector3(0.0, 0.8, 0.0)
		_mantle.add_child(root)
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


func _add_eyes() -> void:
	# One centered living-world eye: a dark skin-derived marking with no white.
	_eye = SuperEgg.build_part(Vector3(0.82, 1.05, 0.34), KRAKEN.darkened(0.42), 2.4, 2.4)
	_eye.name = "SingleEye"
	_eye.position = Vector3(0.0, 4.5, 4.55)
	_mantle.add_child(_eye)
	# Skin-coloured upper lid overlaps and encloses the upper third. A flat
	# lower edge and round crown give it the requested heavy semicircle.
	var lid := SuperEgg.build_part(Vector3(1.02, 0.55, 0.42), KRAKEN, 2.0, SuperEgg.EPSILON_FLAT)
	lid.name = "UpperEyelid"
	lid.position = Vector3(0.0, 5.4, 4.68)
	_mantle.add_child(lid)


func _add_splotches() -> void:
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
		_mantle.add_child(patch)


func _add_mouth() -> void:
	var mouth := Area3D.new()
	mouth.name = "ToothedMouth"
	mouth.position = Vector3(0.0, 0.05, 0.0)
	mouth.collision_layer = 0
	mouth.collision_mask = 1
	_mantle.add_child(mouth)
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
	mouth.body_entered.connect(_on_mouth_entered)


func _on_mouth_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null:
		return
	var away := Vector3(player.global_position.x - global_position.x, 0.0, player.global_position.z - global_position.z)
	if away.length() < 0.1:
		away = Vector3.BACK
	player.escape_from_lethal_hazard(global_position + away.normalized() * 13.0 + Vector3.UP * 9.0)
