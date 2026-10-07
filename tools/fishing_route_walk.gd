extends Node

## Walks every route in FishingVillagePlan.ROUTES at the three playable body
## sizes (the settlement backlog's shared gate: "walk every route at player,
## Blorbus and mount scale"). Every half metre along a route's centre line it
## checks, for each body, that:
##   - there is deck underfoot, near the route's planned height;
##   - there is deck under both of the body's sides (no gap to fall through);
##   - nothing solid stands where the body would be (a post, a rail, a crate),
##     the body lifted by a step's height so a deck seam does not count.
## Headless: prints each failure and a total, and quits non-zero on any.
##
##   Godot --headless --path . tools/fishing_route_walk.tscn

## name -> [shape, half width, centre height above the floor]
var _bodies := {}
var _failures := 0
const STEP := 0.5
const LIFT := 0.3


func _ready() -> void:
	get_tree().create_timer(240.0).timeout.connect(func() -> void:
		print("FAIL route walk watchdog")
		get_tree().quit(2))
	var human := CapsuleShape3D.new()
	human.radius = 0.4
	human.height = 1.8
	var blorbus := SphereShape3D.new()
	blorbus.radius = Blorb.COLLIDER_RADIUS
	var monkey := SphereShape3D.new()
	monkey.radius = 0.08 * 2.3585
	_bodies = {
		"human": [human, 0.4, 0.9],
		"Blorbus": [blorbus, Blorb.COLLIDER_RADIUS, Blorb.COLLIDER_RADIUS],
		"Xiao Hou Zi": [monkey, monkey.radius, monkey.radius],
	}
	_run.call_deferred()


func _run() -> void:
	var world := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 10:
		await get_tree().physics_frame
	var water: float = world.get_node("Terrain").get_lake_water_level()
	var space := (world as Node3D).get_world_3d().direct_space_state
	var npcs: Array[RID] = []
	for npc in get_tree().get_nodes_in_group("npcs"):
		if npc is CollisionObject3D:
			npcs.append((npc as CollisionObject3D).get_rid())
	for route: Dictionary in FishingVillagePlan.ROUTES:
		var points: Array = route["points"]
		var problems := {}
		for i in points.size() - 1:
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var steps := maxi(int(a.distance_to(b) / STEP), 1)
			var across := Vector2(-(b - a).normalized().y, (b - a).normalized().x)
			for k in steps + 1:
				var plan := a.lerp(b, float(k) / float(steps))
				var at := FishingVillagePlan.WORLD_CENTER + plan
				var floor_y := _floor(space, at, water)
				if is_nan(floor_y):
					_note(problems, "no deck underfoot", plan)
					continue
				for body_name: String in _bodies:
					var body: Array = _bodies[body_name]
					var half := float(body[1])
					for side: float in [-1.0, 1.0]:
						var edge := at + across * side * half * 0.9
						var edge_y := _floor(space, edge, water)
						if is_nan(edge_y) or absf(edge_y - floor_y) > LIFT:
							_note(problems, "%s: no deck under its %s side" % [body_name, "left" if side < 0.0 else "right"], plan)
					var query := PhysicsShapeQueryParameters3D.new()
					query.shape = body[0]
					query.transform = Transform3D(Basis(), Vector3(at.x, floor_y + float(body[2]) + LIFT, at.y))
					query.collision_mask = 1
					query.exclude = npcs
					for hit in space.intersect_shape(query, 4):
						_note(problems, "%s: blocked by %s" % [body_name, _name(hit["collider"] as Node)], plan)
		if problems.is_empty():
			print("ok   %s" % route["name"])
		else:
			for problem: String in problems:
				var first: Array = problems[problem]
				print("FAIL %s: %s at %s%s" % [route["name"], problem, _fmt(first[0]), "" if int(first[1]) == 0 else " (and %d more samples)" % int(first[1])])
				_failures += 1
	print("---- fishing_route_walk: %d FAIL" % _failures)
	get_tree().quit(1 if _failures > 0 else 0)


## The walking surface at a world plan point: the highest floor within a deck's
## reach of the water (not a roof above, not the shelf below).
func _floor(space: PhysicsDirectSpaceState3D, at: Vector2, water: float) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, water + 1.6, at.y), Vector3(at.x, water - 0.6, at.y))
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return NAN
	return float(hit["position"].y)


## Groups repeats of one problem along a stretch into a single line: the
## problem, where it first appears, and how many more samples share it.
func _note(problems: Dictionary, problem: String, plan: Vector2) -> void:
	if problems.has(problem):
		problems[problem][1] = int(problems[problem][1]) + 1
	else:
		problems[problem] = [plan, 0]


func _name(node: Node) -> String:
	var parts: Array[String] = []
	var current := node
	for _i in 3:
		if current == null:
			break
		parts.push_front(str(current.name))
		current = current.get_parent()
	return "/".join(parts)


func _fmt(plan: Vector2) -> String:
	return "(%.1f, %.1f)" % [plan.x, plan.y]
