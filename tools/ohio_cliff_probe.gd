extends Node

## Measures the ground under Ohio's aqueduct fall and around the overlook, so
## the flume, the fall and the overlook's foundation are designed on the real
## cliff rather than guessed.
##
##   Godot --headless --path . tools/ohio_cliff_probe.tscn


func _ready() -> void:
	get_tree().create_timer(240.0).timeout.connect(func() -> void: get_tree().quit(2))
	var world := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	var town := world.find_child("Town", true, false)
	var plan: Dictionary = town._waterworks_plan()
	var samples: Array = plan["samples"]
	var beds: Array[float] = town._aqueduct_beds(samples)
	var start: Vector2 = samples[samples.size() - 1]
	var dir: Vector2 = plan["dir"]
	var shore: float = town.terrain.get_lake_water_level()
	print("aqueduct end %s dir %s bed %.2f water %.2f lake %.2f" % [start, dir, beds[beds.size() - 1], beds[beds.size() - 1] + VillageWorks.WATER_LEVEL, shore])
	for step in range(0, 71, 2):
		var at: Vector2 = start + dir * float(step)
		print("  +%2d m  ground %.2f" % [step, town._ground_y(at)])
	var centre: Vector2 = OhioPlan.OVERLOOK["at"]
	var radius: float = OhioPlan.OVERLOOK["radius"]
	print("overlook at %s radius %.1f centre ground %.2f" % [centre, radius, town._ground_y(centre)])
	for i in 12:
		var angle := TAU * float(i) / 12.0
		for r: float in [radius * 0.5, radius]:
			var at := centre + Vector2(cos(angle), sin(angle)) * r
			print("  %3d deg r %.1f  ground %.2f" % [i * 30, r, town._ground_y(at)])
	# Paths near the rim: does either edge of the worn way run over the drop?
	for path: Dictionary in OhioPlan.WAYS:
		if path["name"] not in ["east road", "edge walk"]:
			continue
		var points: Array = path["points"]
		var half: float = float(path["width"]) * 0.5
		for i in points.size() - 1:
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			var steps := maxi(int(a.distance_to(b)), 1)
			for k in steps + 1:
				var at := a.lerp(b, float(k) / float(steps))
				var side := Vector2(-(b - a).normalized().y, (b - a).normalized().x)
				var centre_y: float = town._ground_y(at)
				for sd: float in [-1.0, 1.0]:
					var edge_y: float = town._ground_y(at + side * sd * (half + 0.5))
					if centre_y - edge_y > 1.0:
						print("  %s over the edge at %s (side %+d): ground falls %.1f m" % [path["name"], at, int(sd), centre_y - edge_y])
	# Where each edge-walk point must move (west, inland) to keep its whole width
	# and a metre's margin on top of the rim.
	for path: Dictionary in OhioPlan.WAYS:
		if path["name"] != "edge walk":
			continue
		var half: float = float(path["width"]) * 0.5
		var fixed: Array[String] = []
		var dense: Array[Vector2] = []
		var pts: Array = path["points"]
		for i in pts.size() - 1:
			var steps := maxi(int((pts[i] as Vector2).distance_to(pts[i + 1]) / 2.0), 1)
			for k in steps:
				dense.append((pts[i] as Vector2).lerp(pts[i + 1], float(k) / float(steps)))
		dense.append(pts[pts.size() - 1])
		for p: Vector2 in dense:
			var at := p
			for i in 40:
				var y: float = town._ground_y(at)
				var clear := true
				for probe_x: float in [0.5, 1.0, 1.5, 2.0]:
					if y - float(town._ground_y(at + Vector2(half + probe_x - 0.5 + 0.5, 0.0))) > 0.6:
						clear = false
				if clear:
					break
				at.x -= 0.5
			fixed.append("Vector2(%.1f,%.1f)" % [at.x, at.y])
		print("edge walk inland: [%s]" % ", ".join(fixed))
	get_tree().quit()
