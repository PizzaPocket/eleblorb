extends Node

func _ready() -> void:
	# Usage: ... tools/npc_motion_probe.tscn -- --world=snow   (default: ohio)
	var snow := "--world=snow" in OS.get_cmdline_user_args()
	var world := (load("res://scenes/ice_kingdom.tscn" if snow else "res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 30:
		await get_tree().process_frame
	var town := world.get_node("SnowVillage" if snow else "Town")
	var npcs: Array = []
	for n in get_tree().get_nodes_in_group("npcs"):
		if town.is_ancestor_of(n):
			npcs.append(n)
	print("NPC count under Town: ", npcs.size(), "  game hour ", WorldState.game_time_hours)
	var start := {}
	for n in npcs:
		start[n] = Vector2(n.global_position.x, n.global_position.z)
	for _i in 900:
		await get_tree().physics_frame
	var moved := 0
	for n in npcs:
		var d: float = Vector2(n.global_position.x, n.global_position.z).distance_to(start[n])
		var st = n.get("_state")
		print("%-16s moved %.2f  state %s  phase %s  hour %.2f  stationary %s" % [str(n.get("display_name")), d, str(st), str(n.get("_schedule_phase")), WorldState.game_time_hours, str(n.get("stationary"))])
		if d > 0.3:
			moved += 1
	print("moved >0.3 m in 15 s: ", moved, " of ", npcs.size())
	get_tree().quit()
