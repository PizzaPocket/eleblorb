extends Node

## Lists what the Chinese Village actually built (islands, bridges, buildings,
## residents) with positions relative to the village centre, so the audit works
## from measurements. Headless is fine.
##   Godot --headless --path . tools/audit_china.tscn

const CENTER := Vector2(250.0, -650.0)


func _ready() -> void:
	var world := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	for _i in 20:
		await get_tree().process_frame
	var village := world.get_node("ChineseVillage")
	print("surface y ", village.get("_island_surface_y"))
	var counts := {}
	for child in village.get_children():
		var kind := str(child.get_class()) + ":" + str(child.name).rstrip("0123456789@")
		counts[kind] = int(counts.get(kind, 0)) + 1
	print("child kinds: ", counts)
	print("--- islands (walk_radius meta) and NPCs")
	for child in village.get_children():
		if child is Node3D and child.has_meta("walk_radius"):
			var p := Vector2(child.global_position.x, child.global_position.z) - CENTER
			print("island at (%.1f, %.1f) walk_radius %.1f children %d" % [p.x, p.y, float(child.get_meta("walk_radius")) / 0.82, child.get_child_count()])
	print("--- named things under islands/palace")
	for child in village.get_children():
		if child is Node3D and child.has_meta("walk_radius"):
			var p := Vector2(child.global_position.x, child.global_position.z) - CENTER
			var names: Array[String] = []
			for grand in child.get_children():
				var n := str(grand.name)
				if not (n.begins_with("@") or n in ["CollisionShape3D", "MeshInstance3D"]):
					names.append("%s(%.0f,%.0f)" % [n.rstrip("0123456789@"), grand.position.x, grand.position.z] if grand is Node3D else n)
			print("  island (%.0f, %.0f): %s" % [p.x, p.y, ", ".join(names.slice(0, 40))])
	print("--- NPCs")
	for npc in get_tree().get_nodes_in_group("npcs"):
		var p := Vector2(npc.global_position.x, npc.global_position.z) - CENTER
		if p.length() < 300.0:
			print("  %s at (%.1f, %.1f)" % [str(npc.get("display_name")), p.x, p.y])
	print("--- top-level village children that are not islands")
	for child in village.get_children():
		if not (child is Node3D and child.has_meta("walk_radius")):
			var pos := Vector2.ZERO
			if child is Node3D:
				pos = Vector2(child.global_position.x, child.global_position.z) - CENTER
			print("  %s %s (%.0f, %.0f)" % [child.get_class(), child.name, pos.x, pos.y])
	get_tree().quit()
