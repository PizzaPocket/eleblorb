extends Node3D

## The Ocean Kingdom's two moving parkour landmarks plus its first NME pack.
## Everything is procedural so it shares Eleblorbs' rounded toy-like world.

const NPC_SCENE := preload("res://scenes/npc.tscn")
const FISH_GOBLIN_SCENE := preload("res://scenes/fish_goblin_nme.tscn")
const WOOD := Color(0.30, 0.12, 0.045)
const SAIL := Color(0.86, 0.79, 0.62)
const KRAKEN := Color(0.15, 0.55, 0.57)
var _kraken: AnimatableBody3D
var _ship: AnimatableBody3D
var _tentacle_roots: Array[Node3D] = []
var _time := 0.0


func _ready() -> void:
	_build_kraken()
	_build_ship()
	_spawn_fish_goblins()


func _process(delta: float) -> void:
	_time += delta
	if _kraken != null:
		var kraken_angle := _time * 0.035
		_kraken.position = Vector3(145.0 + cos(kraken_angle) * 42.0, -4.0 + sin(_time * 0.16) * 5.2, 70.0 + sin(kraken_angle) * 42.0)
		_kraken.rotation.y = -kraken_angle + PI * 0.5
		for index in _tentacle_roots.size():
			_tentacle_roots[index].rotation.y = sin(_time * 0.7 + index * 0.73) * 0.3
			_tentacle_roots[index].rotation.x = sin(_time * 0.9 + index) * 0.18
	if _ship != null:
		var ship_angle := _time * 0.018
		_ship.position = Vector3(-125.0 + cos(ship_angle) * 65.0, 0.0, 95.0 + sin(ship_angle) * 65.0)
		_ship.rotation.y = -ship_angle
		_ship.rotation.z = sin(_time * 0.55) * deg_to_rad(1.8)


func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	return material


func _add_box(body: Node3D, position: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> Node3D:
	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	part.mesh = mesh
	part.position = position
	part.rotation = rotation
	part.material_override = _material(color)
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
	var part := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	part.mesh = mesh
	part.position = position
	part.basis = basis
	part.material_override = _material(color)
	body.add_child(part)
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position = position
	collision.basis = basis
	body.add_child(collision)


func _build_kraken() -> void:
	_kraken = AnimatableBody3D.new()
	_kraken.name = "TwelveTentacledKraken"
	_kraken.collision_layer = 1
	add_child(_kraken)
	_add_capsule(_kraken, Vector3(0, 6.0, 0), 4.8, 13.0, KRAKEN)
	_add_box(_kraken, Vector3(0, 11.5, -0.5), Vector3(7.0, 5.0, 5.5), KRAKEN.lightened(0.05))
	for index in 12:
		var root := Node3D.new()
		root.name = "Tentacle%02d" % (index + 1)
		root.rotation.y = TAU * float(index) / 12.0
		_kraken.add_child(root)
		_tentacle_roots.append(root)
		for segment in 5:
			var length := 4.8 - segment * 0.55
			var radius := 0.95 - segment * 0.12
			var distance := 4.0 + segment * 3.6
			var rise := sin(float(segment) * 0.8 + index) * 1.4
			_add_capsule(root, Vector3(0, rise, distance), radius, length, KRAKEN.lightened(segment * 0.025), Basis(Vector3.RIGHT, deg_to_rad(82.0)))


func _build_ship() -> void:
	_ship = AnimatableBody3D.new()
	_ship.name = "SailingPirateShip"
	_ship.collision_layer = 1
	add_child(_ship)
	# Tall layered hull and two walkable decks.
	_add_box(_ship, Vector3(0, 1.6, 0), Vector3(11, 3.2, 29), WOOD)
	_add_box(_ship, Vector3(0, 3.35, 0), Vector3(10, 0.55, 27), WOOD.lightened(0.12))
	_add_box(_ship, Vector3(0, 5.0, 9.5), Vector3(9, 2.8, 7), WOOD.lightened(0.08))
	_add_box(_ship, Vector3(0, 6.55, 9.5), Vector3(8.5, 0.5, 7), WOOD.lightened(0.15))
	# Exterior parkour stairs begin below waterline and climb to the main deck.
	for side in [-1.0, 1.0]:
		for step in 10:
			_add_box(_ship, Vector3(side * 6.0, -0.4 + step * 0.42, -3.0 + step * 0.32), Vector3(2.4, 0.38, 1.25), WOOD.lightened(0.1))
	# Three masts, yards, and multiple broad sails after the reference's silhouette.
	for mast_data in [[-7.0, 18.0], [2.0, 23.0], [10.0, 16.0]]:
		var z := float(mast_data[0])
		var mast_height := float(mast_data[1])
		_add_capsule(_ship, Vector3(0, 3.5 + mast_height * 0.5, z), 0.34, mast_height, WOOD.lightened(0.08))
		for sail_level in 3:
			var width := 9.0 - sail_level * 1.35
			var y := 9.0 + sail_level * 4.6
			_add_box(_ship, Vector3(0, y, z), Vector3(width, 3.4, 0.16), SAIL)
	for index in 3:
		var pirate := NPC_SCENE.instantiate()
		pirate.display_name = ["Captain Brine", "Mara Reef", "Old Kelp"][index]
		pirate.stationary = true
		pirate.shirt_color = Color(0.28, 0.04, 0.05)
		pirate.pants_color = Color(0.08, 0.1, 0.16)
		pirate.talk_lines = ["Keep your footing. The sea likes an overconfident sailor."]
		_ship.add_child(pirate)
		pirate.position = Vector3(-2.5 + index * 2.5, 3.8, -2.0 + index * 4.0)


func _spawn_fish_goblins() -> void:
	for index in 8:
		var goblin := FISH_GOBLIN_SCENE.instantiate()
		add_child(goblin)
		var angle := TAU * float(index) / 8.0
		goblin.position = Vector3(145.0 + cos(angle) * 28.0, -14.0, 70.0 + sin(angle) * 28.0)
