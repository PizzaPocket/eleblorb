extends SceneTree

## Prints the islet ground height (relative to the lake surface W) over a plan
## rectangle, one row per metre of z, so a building against the rock can be
## drawn on the real face. FishingIslets reads only the plan and a terrain.
##
##   Godot --headless --path . --script tools/fishing_rock_section.gd -- -6 2 -24 -12


class StubTerrain:
	extends Node
	func get_lake_water_level() -> float:
		return 0.0
	func get_mesh_height(_x: float, _z: float) -> float:
		return -135.0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var x0 := float(args[0])
	var x1 := float(args[1])
	var z0 := float(args[2])
	var z1 := float(args[3])
	var stub := StubTerrain.new()
	FishingIslets._make_noise()
	var header := "   z \\ x"
	var x := x0
	while x <= x1 + 0.01:
		header += "%7.1f" % x
		x += 1.0
	print(header)
	var z := z0
	while z <= z1 + 0.01:
		var line := "%7.1f " % z
		x = x0
		while x <= x1 + 0.01:
			line += "%7.2f" % FishingIslets._height(Vector2(x, z), stub, 0.0)
			x += 1.0
		print(line)
		z += 1.0
	stub.free()
	quit()
