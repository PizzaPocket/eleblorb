extends Node

## Serialized bonded-companion roster (party blorbs + Xiao Hou Zi), kept here
## because a kingdom portal's change_scene_to_file() (see kingdom_travel.gd)
## frees the whole scene tree -- party membership otherwise only exists as
## live node state (blorb.gd/xiao_hou_zi.gd's own in_party). capture_from_tree()
## must run right before a scene change; spawn_into() right after, once the
## destination scene's "Player" and "Terrain" siblings exist (blorb.gd and
## xiao_hou_zi.gd both resolve those via get_node("../Player")/("../Terrain"),
## so spawned members are added as children of that same parent).
##
## Deliberately a flat data snapshot, not live node references: a currently-
## worn (blorb suit) or melted (0 HP) blorb still gets carried across, just
## respawned in its ordinary unworn/full-HP form on arrival -- simpler than
## reconstructing blorb_suit_controller's own equip state across a scene
## boundary, and not something a player is likely to notice or mind.

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")

## Spread spawned companions out a little so they don't all stack on one
## point; matches no particular formation, just avoids instant overlap jitter.
const SPAWN_SPACING := 1.1

var _roster: Array[Dictionary] = []


func capture_from_tree(tree: SceneTree) -> void:
	_roster.clear()
	for node in tree.get_nodes_in_group("blorbs"):
		var blorb := node as Blorb
		if blorb == null or not blorb.in_party or blorb.blorb_type == "size":
			continue
		_roster.append({
			"kind": "blorb",
			"element": blorb.element_state,
			"is_shiny": blorb.is_shiny,
			"is_blorbus": blorb.is_blorbus,
			"blorb_name": blorb.blorb_name,
			"core_items": blorb.core_items.duplicate(),
		})
	for node in tree.get_nodes_in_group("xiao_hou_zi"):
		var monkey := node as XiaoHouZi
		if monkey == null or not monkey.in_party:
			continue
		_roster.append({"kind": "xiao_hou_zi"})


## `parent` must be the destination scene's root (the same node "Player" and
## "Terrain" hang off of). `near_position`/`facing` place the roster just
## behind wherever the player is arriving, facing the same way they are.
func spawn_into(parent: Node, near_position: Vector3, facing: Vector3) -> void:
	var flat_facing := Vector3(facing.x, 0.0, facing.z)
	if flat_facing.length() < 0.01:
		flat_facing = Vector3.BACK
	flat_facing = flat_facing.normalized()
	var index := 0
	for entry in _roster:
		var lateral := flat_facing.rotated(Vector3.UP, PI * 0.5) * (float(index) - float(_roster.size() - 1) * 0.5)
		var spawn_pos := near_position - flat_facing * 2.0 + lateral * SPAWN_SPACING
		match entry.get("kind", ""):
			"blorb":
				_spawn_blorb(entry, parent, spawn_pos)
			"xiao_hou_zi":
				_spawn_xiao_hou_zi(parent, spawn_pos)
		index += 1


func _spawn_blorb(entry: Dictionary, parent: Node, spawn_pos: Vector3) -> void:
	var blorb: Blorb = BLORB_SCENE.instantiate()
	blorb.in_party = true
	blorb.is_starter_trio = false
	blorb.is_shiny = entry.get("is_shiny", false)
	blorb.blorb_name = entry.get("blorb_name", "")
	var core_items: Array[String] = []
	core_items.assign(entry.get("core_items", []))
	blorb.core_items = core_items
	blorb.initial_element = entry.get("element", "")
	blorb.position = spawn_pos
	parent.add_child(blorb)
	if entry.get("is_blorbus", false):
		blorb.become_blorbus()


func _spawn_xiao_hou_zi(parent: Node, spawn_pos: Vector3) -> void:
	var monkey: XiaoHouZi = XIAO_HOU_ZI_SCENE.instantiate()
	monkey.in_party = true
	monkey.position = spawn_pos
	parent.add_child(monkey)
