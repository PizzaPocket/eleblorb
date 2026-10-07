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
var _village: Node3D


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
		for entry in FireCalderaPlan.PLOTS:
			if not bool(entry.get("open", false)):
				_expect(frame.get_node_or_null("%sPlinth" % entry["id"]) != null, "the live terrain builds the %s plinth" % entry["id"])
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
		for entry in FireCalderaPlan.PLOTS:
			if bool(entry.get("open", false)):
				continue
			var datum := float(_terrain.get_caldera_survey(str(entry["id"]))["datum"])
			var local:Vector2 = entry["centre"]
			var top := frame.global_transform * Vector3(local.x, datum + 0.25, local.y)
			var bottom := frame.global_transform * Vector3(local.x, datum - 3.0, local.y)
			var floor_hit := _ray(space, top, bottom, [])
			_expect(not floor_hit.is_empty() and (floor_hit["collider"] as Node).name == "%sPlinth" % entry["id"], "%s socket has its plinth as the live floor" % entry["id"])
	# Add the transitional village only after the terrain rays: its old lava
	# fountain still occupies the reservoir centre until the remaining city
	# buildings replace it, and must not masquerade as the basin collider.
	_village = (load("res://scripts/fire_kingdom_village.gd") as GDScript).new()
	_village.name = "CalderaVillage"
	add_child(_village)
	for _i in 6:
		await get_tree().physics_frame
	if frame != null:
		var guest := frame.get_node_or_null("GUESTShell") as StaticBody3D
		_expect(guest != null, "the live village builds the finished guest house")
		if guest != null:
			for child_name in ["DryGuestTerrace", "EntryFin", "WakeMarker", "StandMarker", "GatherMarker", "KeeperStand", "LowPitchSkylightRoof", "ErisNahl"]:
				_expect(guest.get_node_or_null(child_name) != null, "the live guest house has %s" % child_name)
			var guest_plinth := frame.get_node_or_null("GUESTPlinth") as StaticBody3D
			for local: Vector3 in [
				Vector3(-7.0, 0.35, 7.1), Vector3(-5.75, 0.35, 7.1), Vector3(0.0, 0.35, 7.1), Vector3(7.0, 0.35, 7.1),
				Vector3(-5.75, 0.35, 5.5), Vector3(0.0, 0.35, 5.5),
				Vector3(-5.0, 0.35, -1.0), Vector3(0.0, 0.35, -1.0), Vector3(5.0, 0.35, -1.0),
			]:
				var floor_hit := _ray(space, guest.global_transform * local, guest.global_transform * Vector3(local.x, -0.8, local.z), [guest.get_rid()])
				_expect(not floor_hit.is_empty() and floor_hit["collider"] == guest_plinth, "guest floor lane (%.1f, %.1f) lands on the visible plinth" % [local.x, local.z])
			var eris := guest.get_node_or_null("ErisNahl")
			if eris != null:
				var actions:Array = eris.dialog_actions_provider.call()
				_expect(actions.size() == 1 and int(actions[0].get("price", -1)) == 25, "Eris offers the 25-Tokoin rest action")
	if frame != null:
		var nahl := frame.get_node_or_null("NAHLShell") as StaticBody3D
		_expect(nahl != null, "the live village builds the Nahl tempering hall")
		if nahl != null:
			for child_name in ["MoltenFloor", "LavaBed", "ErisRestMarker", "ErisWorkMarker", "HeatedStone"]:
				_expect(nahl.find_child(child_name, false, false) != null, "the live Nahl hall has %s" % child_name)
			var molten := nahl.global_transform * Vector3(FireCalderaNahl.MOLTEN_BAY.get_center().x, 0.0, FireCalderaNahl.MOLTEN_BAY.get_center().y)
			_expect(bool(_terrain.is_lava_area(Vector2(molten.x, molten.z))), "the molten floor is lava to the terrain")
			var hall := nahl.global_transform * Vector3(-1.0, 0.0, 3.0)
			_expect(not bool(_terrain.is_lava_area(Vector2(hall.x, hall.z))), "the hall's floor is not lava")
			var pit: Dictionary = (FireCalderaPlan.plot("NAHL")["pits"] as Array)[0]
			var pit_world := nahl.global_transform * Vector3((pit["at"] as Vector2).x, 0.0, (pit["at"] as Vector2).y)
			var pit_floor := float(_terrain.get_mesh_height(pit_world.x, pit_world.z))
			_expect(absf(pit_floor - (nahl.global_position.y - float(pit["depth"]))) < 0.02, "the height query meets the conversation pit's floor")
	# The height query meets every floor: the player snaps to it, so inside a
	# plot it must return the plinth's top, not the natural slope.
	for entry in FireCalderaPlan.PLOTS:
		var line: Dictionary = _terrain.get_caldera_survey(str(entry["id"]))
		if line.is_empty():
			continue
		var worst := 0.0
		var polygon := FireCalderaPlan.plot_polygon(entry, "footprint")
		var plot_centre := FireCalderaPlan.mass_centre(entry)
		var pits := FireCalderaPlan.pit_outlines(entry)
		for corner in polygon:
			for t: float in [0.0, 0.5, 0.8]:
				var local := plot_centre.lerp(corner, t)
				var expected := float(line["datum"])
				for pit in pits:
					if Geometry2D.is_point_in_polygon(local, pit["outline"]):
						expected -= float(pit["depth"])
				var raised := FireCalderaPlan.level_height(entry, local)
				if not is_nan(raised):
					expected += raised
				var world := FireCalderaPlan.to_world(local)
				worst = maxf(worst, absf(float(_terrain.get_mesh_height(world.x, world.y)) - expected))
		_expect(worst < 0.02, "the height query inside %s meets its floor (off by %.2f m)" % [entry["id"], worst])
	var registered:Dictionary = RecoveryManager.get("_registered_points")
	_expect(registered.has("fire_kingdom:caldera_village_inn"), "the live guest house registers its recovery point")
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
