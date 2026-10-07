extends Node3D

## Checks the live FireKingdomTerrain integration, not only the isolated
## caldera prototype: the fine ground is present in the plan's world frame,
## its outer band meets the coarse crater wall, the old flat floor has no
## collider beneath the reservoir, and the polygon reservoir is registered in
## the canonical lava API.
##
##   Godot --headless --path . tools/fire_caldera_world_probe.tscn

var _failures := 0
var _terrain: StaticBody3D


func _ready() -> void:
	get_tree().create_timer(180.0).timeout.connect(func() -> void:
		print("FAIL fire_caldera_world_probe watchdog")
		get_tree().quit(2))
	_terrain = (load("res://scripts/fire_kingdom_terrain.gd") as GDScript).new()
	_terrain.name = "Terrain"
	add_child(_terrain)
	_run.call_deferred()


func _run() -> void:
	for _i in 6:
		await get_tree().physics_frame
	var frame := _terrain.get_node_or_null("CalderaCityGround") as Node3D
	_expect(frame != null, "the live terrain builds the caldera-city frame")
	if frame != null:
		_expect(frame.get_node_or_null("CalderaGround") != null, "the live terrain builds the fine caldera ground")
		_expect(frame.get_node_or_null("ReservoirLava") != null, "the live terrain builds the reservoir surface")
	var centre := FireCalderaPlan.CENTRE_WORLD
	_expect(is_equal_approx(_terrain.get_mesh_height(centre.x, centre.y), FireCalderaGround.height(Vector2.ZERO)), "height queries use the authored reservoir bed")
	_expect(_terrain.is_lava_area(centre), "the live reservoir is registered as lava")
	_expect(is_equal_approx(_terrain.get_lava_surface_height(centre), FireCalderaGround.LAVA_Y), "the live reservoir reports its authored surface height")
	# Every edge of the fine square is already in the wall-only part of the
	# blend. It must equal the coarse mesh there, so the overlap cannot crack.
	var worst_seam := 0.0
	for i in 17:
		var along := -FireCalderaGround.EXTENT + FireCalderaGround.EXTENT * 2.0 * float(i) / 16.0
		for local in [Vector2(-FireCalderaGround.EXTENT, along), Vector2(FireCalderaGround.EXTENT, along),
				Vector2(along, -FireCalderaGround.EXTENT), Vector2(along, FireCalderaGround.EXTENT)]:
			var world := FireCalderaPlan.to_world(local)
			worst_seam = maxf(worst_seam, absf(_terrain.get_mesh_height(world.x, world.y) - _terrain._coarse_mesh_height(world.x, world.y)))
	_expect(worst_seam < 0.01, "the fine ground meets the coarse crater wall (worst %.3f m)" % worst_seam)
	var space := get_world_3d().direct_space_state
	var hit := _ray(space, Vector3(centre.x, 0.0, centre.y), Vector3(centre.x, FireCalderaGround.LAVA_Y - FireCalderaGround.BED_DEPTH - 4.0, centre.y), [])
	_expect(not hit.is_empty() and (hit["collider"] as Node).name == "CalderaGround", "the authored basin is the first solid below the reservoir")
	if not hit.is_empty():
		_expect(absf(float(hit["position"].y) - FireCalderaGround.height(Vector2.ZERO)) < 0.06, "the basin collider agrees with its height function")
	var ground := frame.get_node_or_null("CalderaGround") as CollisionObject3D if frame != null else null
	if ground != null:
		var beneath := _ray(space, Vector3(centre.x, 0.0, centre.y), Vector3(centre.x, -80.0, centre.y), [ground.get_rid()])
		_expect(beneath.is_empty(), "the coarse placeholder floor is absent below the city")
	print("---- fire_caldera_world_probe: %d FAIL" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


func _ray(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, exclude: Array) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	query.exclude = exclude
	return space.intersect_ray(query)


func _expect(condition: bool, what: String) -> void:
	print(("ok   " if condition else "FAIL ") + what)
	_failures += 0 if condition else 1
