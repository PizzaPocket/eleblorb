extends Node

## Runs one title-screen test start inside its kingdom and prints the suit.
##   Godot --headless --path . tools/debug_start_probe.tscn -- --loadout=snow
func _ready() -> void:
	var loadout := "snow"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--loadout="):
			loadout = arg.trim_prefix("--loadout=")
	KingdomTravel.debug_loadout = loadout
	KingdomTravel.debug_loadout_in_use = false
	var world := (load(DebugKingdomStart.LOADOUTS[loadout]["scene"]) as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 60:
		await get_tree().process_frame
	var player := world.get_node("Player") as Player
	var suit := player.get_own_blorb_suit()
	for slot in BlorbSuit.SLOT_ORDER:
		var blorb := suit.assigned_blorb_in_slot(slot)
		if blorb == null:
			print(slot, ": (empty)")
		else:
			print("%s: %s %s level %d items %s" % [slot, blorb.blorb_name if blorb.blorb_name != "" else "blorb", blorb.element_state, blorb.level, blorb.core_items])
	var members: Array[String] = []
	for node in get_tree().get_nodes_in_group("blorbs"):
		var b := node as Blorb
		if b != null and b.in_party:
			members.append("%s/%s" % [b.blorb_name if b.blorb_name != "" else "blorb", b.element_state])
	print("party blorbs: ", members)
	print("xiao hou zi: ", world.get_node_or_null("DebugXiaoHouZi") != null, " tokoins ", TokoinWallet.value)
	get_tree().quit()
