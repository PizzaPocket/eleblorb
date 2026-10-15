extends Node3D

const FireCalderaAro := preload("res://scripts/fire_caldera_aro.gd")

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
		var threshold := frame.get_node_or_null("CalderaArrivalThreshold")
		_expect(threshold != null, "the live terrain builds the arrival threshold")
		if threshold != null:
			_expect(threshold.get_node_or_null("ArrivalMarkerWest") != null, "the arrival threshold has its west marker")
			_expect(threshold.get_node_or_null("ArrivalMarkerEast") != null, "the arrival threshold has its east marker")
		for entry in FireCalderaPlan.PLOTS:
			if not bool(entry.get("open", false)):
				_expect(frame.get_node_or_null("%sPlinth" % entry["id"]) != null, "the live terrain builds the %s plinth" % entry["id"])
		var coarse_mesh := _terrain.get_node_or_null("TerrainMesh") as MeshInstance3D
		var fine_mesh := frame.get_node_or_null("CalderaGround/GroundMesh") as MeshInstance3D
		_expect(coarse_mesh != null and fine_mesh != null, "both terrain meshes expose their visual material")
		if coarse_mesh != null and fine_mesh != null:
			_expect(coarse_mesh.material_override == fine_mesh.material_override, "the coarse world and fine city use the exact same terrain material resource")
			var material := fine_mesh.material_override as StandardMaterial3D
			_expect(material != null and material.albedo_color.is_equal_approx(FireCalderaGround.ROCK_COLOR), "the shared terrain material is charcoal basalt")
	var centre := FireCalderaPlan.CENTRE_WORLD
	_expect(is_equal_approx(_terrain.get_mesh_height(centre.x, centre.y), FireCalderaGround.height(Vector2.ZERO)), "height queries use the authored reservoir bed")
	_expect(_terrain.is_lava_area(centre), "the live reservoir is registered as lava")
	_expect(is_equal_approx(_terrain.get_lava_surface_height(centre), FireCalderaGround.LAVA_Y), "the live reservoir reports its authored surface height")
	var highline := frame.get_node_or_null("CalderaHighline") if frame != null else null
	_expect(highline != null, "the structural Highline exists independently of the terrain")
	# Sample the south contour away from every private platform's intentional
	# terrain-clearance socket.
	var ring_local := Vector2(0.0, -FireCalderaPlan.HIGHLINE_RADIUS)
	var ring_world := FireCalderaPlan.to_world(ring_local)
	var ring_ground: float = _terrain.get_mesh_height(ring_world.x, ring_world.y)
	_expect(absf(ring_ground - FireCalderaGround.outer_bowl_height(ring_local)) < 0.05, "the natural parabolic bowl remains intact below the Highline")
	_expect(FireCalderaPlan.HIGHLINE_DATUM - ring_ground > 0.5, "the Highline clears its parabolic bowl")
	var lip_world := FireCalderaPlan.to_world(Vector2(0.0, -FireCalderaPlan.RIM_RADIUS))
	_expect(_terrain.is_safe_zone(lip_world), "the NME-free civic safe space reaches the true crater-lip gate")
	var ocean_holes: Array[Dictionary] = _terrain.planetary_ocean_holes()
	_expect(ocean_holes.size() == 6, "the planetary ocean is masked below all six Fire volcano footprints")
	var ocean := PlanetaryOcean.new()
	ocean.configure_holes(ocean_holes)
	add_child(ocean)
	var ocean_material := ocean.material_override as ShaderMaterial
	_expect(ocean_material != null and int(ocean_material.get_shader_parameter("circle_hole_count")) == 6, "the planetary-ocean shader receives every Fire exclusion")
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
	var hit := _ray(space, Vector3(centre.x, FireCalderaGround.LAVA_Y + 4.0, centre.y), Vector3(centre.x, FireCalderaGround.LAVA_Y - FireCalderaGround.BED_DEPTH - 4.0, centre.y), [])
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
	# Add the live village only after the terrain rays, then confirm the retired
	# generic-house settlement layer has not returned around the authored city.
	_village = (load("res://scripts/fire_kingdom_village.gd") as GDScript).new()
	_village.name = "CalderaVillage"
	add_child(_village)
	for _i in 6:
		await get_tree().physics_frame
	var unnamed_legacy_solids := _village.find_children("StaticBody3D", "StaticBody3D", false, false)
	_expect(unnamed_legacy_solids.is_empty(), "the obsolete generic houses, braziers and fountain are absent")
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
				if not floor_hit.is_empty() and (floor_hit["collider"] as Node).name == "CalderaHighline":
					floor_hit = _ray(space, guest.global_transform * local, guest.global_transform * Vector3(local.x, -0.8, local.z), [guest.get_rid(), floor_hit["rid"]])
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
			var hidden_ground := float(_terrain.get_mesh_height(pit_world.x, pit_world.z))
			_expect(hidden_ground < nahl.global_position.y - float(pit["depth"]) - 0.1, "terrain stays below the conversation pit's physical floor")
	if frame != null:
		var aro := frame.get_node_or_null("AROShell") as StaticBody3D
		_expect(aro != null, "the live village builds the Aro thermal works and home")
		if aro != null:
			for child_name in ["L1DescentMarker", "TovanControlMarker", "MiruWorkMarker", "KesWorkMarker", "TovanRestMarker", "MiruRestMarker", "KesRestMarker"]:
				_expect(aro.get_node_or_null(child_name) != null, "the live Aro building has %s" % child_name)
			_expect(aro.find_child("L1Bulkhead", true, false) != null, "the live Aro descent ends at its sealed L1 bulkhead")
			var aro_lava := aro.global_transform * Vector3(FireCalderaAro.BED_CENTRES[0].x, FireCalderaAro.BED_LAVA_Y, FireCalderaAro.BED_CENTRES[0].y)
			_expect(bool(_terrain.is_lava_area(Vector2(aro_lava.x, aro_lava.z))), "the live Aro resting niches register canonical lava")
	# Terrain queries stay below every built foundation. Floors, ramps and roof
	# terraces are stacked architecture and must be owned solely by collision;
	# a single Y-per-XZ query cannot represent them without snapping the player
	# through another storey.
	for entry in FireCalderaPlan.PLOTS:
		var line: Dictionary = _terrain.get_caldera_survey(str(entry["id"]))
		if line.is_empty():
			continue
		var smallest_clearance := INF
		var polygon := FireCalderaPlan.plot_polygon(entry, "footprint")
		var plot_centre := FireCalderaPlan.mass_centre(entry)
		for corner in polygon:
			for t: float in [0.0, 0.5, 0.8]:
				var local := plot_centre.lerp(corner, t)
				var world := FireCalderaPlan.to_world(local)
				smallest_clearance = minf(smallest_clearance, float(line["datum"]) - float(_terrain.get_mesh_height(world.x, world.y)))
		_expect(smallest_clearance >= 0.7, "terrain stays below %s architecture (minimum clearance %.2f m)" % [entry["id"], smallest_clearance])
		if FireCalderaPlan.is_elevated(entry):
			var centre_local: Vector2 = entry["centre"]
			var centre_world := FireCalderaPlan.to_world(centre_local)
			var expected_ground := FireCalderaGround.blend_height(centre_local, _terrain._coarse_mesh_height(centre_world.x, centre_world.y))
			_expect(absf(float(_terrain.get_mesh_height(centre_world.x, centre_world.y)) - expected_ground) < 0.03, "%s platform leaves the natural bowl untouched below it" % entry["id"])
		if bool(entry.get("open", false)) or not bool(entry.get("occupied", false)):
			continue
		# Prove an actual air strip behind the shell, not merely a lowered point
		# somewhere beneath its centre. These samples run across the whole rear
		# wall and outward through the clear retaining reveal.
		var back := FireCalderaPlan.back_point(entry, "footprint")
		var outward := -FireCalderaPlan.facing(entry)
		var across := Vector2(-outward.y, outward.x)
		var rear_clearance := INF
		for side: float in [-0.8, 0.0, 0.8]:
			for distance: float in [0.15, 0.65, 1.05]:
				var rear_local := back + across * side * (entry["footprint"] as Vector2).x * 0.5 + outward * distance
				var rear_world := FireCalderaPlan.to_world(rear_local)
				rear_clearance = minf(rear_clearance, float(line["datum"]) - float(_terrain.get_mesh_height(rear_world.x, rear_world.y)))
		_expect(rear_clearance >= 0.7, "the full rear of %s has a terrain-free inspection strip (minimum clearance %.2f m)" % [entry["id"], rear_clearance])
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
