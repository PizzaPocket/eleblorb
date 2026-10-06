extends Node

## Confirms the Ice Kingdom has exactly one planetary sea and that it is cut
## out over the lake basin. Run: ... tools/ice_ocean_probe.tscn

func _ready() -> void:
	var world := (load("res://scenes/ice_kingdom.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 20:
		await get_tree().process_frame
	var seas: Array[Node] = []
	for child in world.get_children():
		if child is PlanetaryOcean:
			seas.append(child)
	print("planetary seas under the kingdom: ", seas.size())
	for sea: PlanetaryOcean in seas:
		print("  level ", sea.surface_level, " hole ", sea.hole_enabled, " from ", sea.hole_from, " radius ", sea.hole_radius)
	var terrain := world.get_node("Terrain")
	var worst := INF
	var worst_angle := 0.0
	for i in 360:
		var angle := TAU * float(i) / 360.0
		var at: Vector2 = Vector2(235.0, 105.0) + Vector2(cos(angle), sin(angle)) * 187.0
		var y: float = terrain.get_mesh_height(at.x, at.y)
		if y < worst:
			worst = y
			worst_angle = rad_to_deg(angle)
	print("lowest ground on the hole's edge ring: %.2f m at %.0f deg (sea is at -12.0; must be above)" % [worst, worst_angle])
	get_tree().quit()
