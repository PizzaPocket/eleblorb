extends Node

## Loads the starting world and casts rays down onto the fishing islets, to
## confirm their rock and shelf collide at the heights the layout plan gives.
## Shelf rays start just under the surface so the old village's decks, which
## stand over the shelves until the rebuild replaces them, do not answer first.
##
##   Godot --headless --path . tools/fishing_islet_probe.tscn

const PROBES := {
	"Anvil crown": [Vector2(-4, -30), 34.0],
	"Anvil south shelf": [Vector2(-10, 0), -3.2],
	"Anvil arrival foot": [Vector2(-38, -6), -3.2],
	"Anvil east shelf end": [Vector2(14, -2), -3.2],
	"Heron crown": [Vector2(30, 10), 21.0],
	"Heron shelf (north, off the Vale houseboat)": [Vector2(28, -2), -3.2],
	"Heron shelf (catch deck)": [Vector2(42, 10), -3.2],
	"Heron shelf (portal landing)": [Vector2(30, 22), -3.2],
	"Open water, no shelf": [Vector2(60, 40), null],
	"Jetty spine deck": [Vector2(-10, -7), 0.5],
	"Heron landing deck": [Vector2(21, 0), 0.5],
	"Portal gate spot": [Vector2(30, 20), 0.5],
	"Behind the gate (3 m)": [Vector2(32.1, 22.1), 0.5],
	"Exit 1 top (landing edge)": [Vector2(-36.3, 1.6), 0.5],
	"Exit 1 foot": [Vector2(-36.3, 10.2), -1.5],
	"Exit 2 foot": [Vector2(-2.0, 12.2), -1.5],
	"Exit 3 foot": [Vector2(29.7, 32.2), -1.5],
	"Houseboat west deck": [Vector2(-24.5, 11), 0.35],
	"Gangway mid": [Vector2(-22, 6), 0.43],
	"Pavilion floor": [Vector2(-2, 0), 0.5],
	"Venn veranda floor": [Vector2(-29.5, -14.0), 0.75, 2.5],
	"Venn living room floor": [Vector2(-29.5, -16.6), 0.75, 3.0],
	"Venn threshold ramp": [Vector2(-31.0, -12.5), 0.62],
}

var _failures := 0


func _ready() -> void:
	# A script error in an await chain stops _ready before quit(), which looked
	# like a hang; the watchdog ends the run instead.
	get_tree().create_timer(240.0).timeout.connect(func() -> void:
		print("FAIL probe watchdog: did not finish in 240 s")
		get_tree().quit(2))
	var world := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 10:
		await get_tree().physics_frame
	var terrain := world.get_node("Terrain")
	var water: float = terrain.get_lake_water_level()
	var space := (world as Node3D).get_world_3d().direct_space_state
	for name: String in PROBES:
		var local: Vector2 = PROBES[name][0]
		var expected: Variant = PROBES[name][1]
		var at := FishingVillagePlan.WORLD_CENTER + local
		# A third value starts the ray at that height (under a roof or ceiling).
		var start: float = float(PROBES[name][2]) if PROBES[name].size() > 2 else (80.0 if expected == null or float(expected) > 0.6 else (4.0 if float(expected) > 0.0 else -0.3))
		var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, water + start, at.y), Vector3(at.x, water - 200.0, at.y))
		query.collision_mask = 1
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			print("FAIL %s: no hit" % name)
			_failures += 1
			continue
		var rel: float = hit["position"].y - water
		if expected == null:
			var ok := rel < -20.0
			print("%s %s: hit at W%+.2f (expected the deep lake bed)" % ["ok  " if ok else "FAIL", name, rel])
			_failures += 0 if ok else 1
		else:
			var ok := absf(rel - float(expected)) < 1.0
			print("%s %s: hit at W%+.2f (expected W%+.1f)" % ["ok  " if ok else "FAIL", name, rel, expected])
			_failures += 0 if ok else 1
	for body_name in ["FishingIslets", "Piles", "VennHouse"]:
		var body := world.find_child(body_name, true, false)
		if body == null or (body is StaticBody3D and not CollisionPolicy.validate_body(body as StaticBody3D)):
			print("FAIL %s missing or its visuals and colliders do not pair" % body_name)
			_failures += 1
	var rock := world.find_child("SealingRock", true, false)
	if rock == null:
		print("FAIL The sealing rock is not on Lantern Row")
		_failures += 1
	else:
		var sage := get_tree().get_first_node_in_group("sun_wu_kong") as Node3D
		var apart := sage.global_position.distance_to((rock as Node3D).global_position) if sage != null else -1.0
		print("ok   sealing rock at %s, Sun Wu Kong %.1f m from it" % [(rock as Node3D).global_position, apart])
		if sage == null or apart > 3.0:
			print("FAIL Sun Wu Kong is not pinned at the rock")
			_failures += 1
	for kind in ToiletFixtures.KINDS:
		var fixture := ToiletFixtures.build(kind)
		var colliders := fixture.find_children("*", "CollisionShape3D", true, false).size()
		var parts := fixture.find_children("*", "MeshInstance3D", true, false).size()
		if colliders < 1 or parts < 3:
			print("FAIL toilet fixture %s has %d colliders and %d parts" % [kind, colliders, parts])
			_failures += 1
		fixture.free()
	if not RecoveryManager._registered_points.has("outskirts:fishing_village_houseboat"):
		print("FAIL The Mor houseboat rest point is not registered")
		_failures += 1
	var leena_found := false
	for node in world.find_children("*", "Node3D", true, false):
		if str(node.get("display_name")) == "Leena Mor":
			leena_found = true
	if not leena_found:
		print("FAIL Leena Mor is not aboard the houseboat")
		_failures += 1
	var vendor_found := false
	for npc in get_tree().get_nodes_in_group("npcs"):
		if str(npc.get("display_name")) == "Nara Venn":
			vendor_found = true
	if not vendor_found:
		for node in world.find_children("*", "Node3D", true, false):
			if str(node.get("display_name")) == "Nara Venn":
				vendor_found = true
	if not vendor_found:
		print("FAIL Nara Venn, the lake vendor, is not in the world")
		_failures += 1
	print("---- fishing_islet_probe: %d FAIL" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)
