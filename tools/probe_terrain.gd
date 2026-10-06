extends Node

## Prints the crossroads terrain around the town (town-local metres): ground
## height, lake coverage and distance beyond the plateau rim, for planning
## geography (pond, mill, aqueduct, waterfall).
##   Godot --headless --path . tools/probe_terrain.tscn

func _ready() -> void:
	var terrain: Node = load("res://scripts/terrain_generator.gd").new()
	var natural: bool = OS.get_cmdline_user_args().has("--natural")
	terrain.town_pond_enabled = not natural
	var town: Vector2 = terrain.town_center
	print("town_center ", town)
	var header := "z\\x   "
	for x in range(-100, 181, 20):
		header += "%6d" % x
	print("HEIGHT (rows z from -160 to 120, columns x -100..180)")
	print(header)
	for z in range(-160, 121, 20):
		var row := "%5d " % z
		for x in range(-100, 181, 20):
			var p := town + Vector2(x, z)
			row += "%6.1f" % terrain.get_height(p.x, p.y)
		print(row)
	print("FINE HEIGHT (natural), x 0..120 step 10 across, z -200..-60 step 10 down")
	var fine_header := "z\\x  "
	for x in range(0, 121, 10):
		fine_header += "%6d" % x
	print(fine_header)
	for z in range(-200, -59, 10):
		var row := "%5d " % z
		for x in range(0, 121, 10):
			var p := town + Vector2(x, z)
			row += "%6.1f" % terrain.get_height(p.x, p.y)
		print(row)
	print("MESH LATTICE (local x 12..138 step 18, z -178..-52 step 18)")
	var lattice_header := "z\\x  "
	for x in range(12, 139, 18):
		lattice_header += "%7d" % x
	print(lattice_header)
	for z in range(-178, -51, 18):
		var row := "%5d " % z
		for x in range(12, 139, 18):
			var p := town + Vector2(x, z)
			row += "%7.1f" % terrain.get_height(p.x, p.y)
		print(row)
	print("LAKE coverage (x -100..180)")
	for z in range(-160, 121, 20):
		var row := "%5d " % z
		for x in range(-100, 181, 20):
			var p := town + Vector2(x, z)
			row += "%6.2f" % terrain.lake_coverage(p.x, p.y)
		print(row)
	print("RIM radius by angle (deg: edge, world point, local point)")
	for deg in range(-60, 91, 10):
		var angle := deg_to_rad(float(deg))
		var edge: float = terrain.get_plateau_edge_radius(angle)
		var world := Vector2(cos(angle), sin(angle)) * edge
		print("%4d: %.1f world(%.0f, %.0f) local(%.0f, %.0f) lake@+60 %.2f" % [
			deg, edge, world.x, world.y, world.x - town.x, world.y - town.y,
			terrain.lake_coverage(cos(angle) * (edge + 60.0), sin(angle) * (edge + 60.0))
		])
	get_tree().quit()
