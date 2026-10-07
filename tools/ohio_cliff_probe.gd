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
	get_tree().quit()
