extends Node3D

## Regression proof for the shared locomotion support handoff. Two adjacent
## authored room slabs deliberately leave a hairline physics seam. The real
## player capsule must still recognize walkable support at and around that seam,
## while a nearby vertical wall with no floor must not count as ground.

var _failures := 0


func _ready() -> void:
	_add_box("RoomFloorWest", Vector3(-2.0025, -0.10, 0.0), Vector3(4.0, 0.20, 4.0))
	_add_box("RoomFloorEast", Vector3(2.0025, -0.10, 0.0), Vector3(4.0, 0.20, 4.0))
	_add_box("WallOnly", Vector3(8.0, 1.0, 0.0), Vector3(0.20, 2.0, 4.0))
	var terrain_stub := Node3D.new()
	terrain_stub.name = "Terrain"
	add_child(terrain_stub)
	var player := preload("res://scenes/player.tscn").instantiate() as Player
	add_child(player)
	player.set_physics_process(false)
	player.set_process(false)
	await get_tree().physics_frame
	for x: float in [-0.30, -0.08, 0.0, 0.08, 0.30]:
		player.global_position = Vector3(x, Player.FOOT_OFFSET, 0.0)
		if not bool(player.call("_has_nearby_walkable_support")):
			_fail("player loses walkable support at the room-floor seam x=%.2f" % x)
	player.global_position = Vector3(7.55, Player.FOOT_OFFSET, 0.0)
	if bool(player.call("_has_nearby_walkable_support")):
		_fail("a vertical wall is incorrectly accepted as walkable support")
	print("---- player_support_handoff_probe: %d FAIL" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _add_box(label: String, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = at
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _fail(message: String) -> void:
	_failures += 1
	print("FAIL ", message)
