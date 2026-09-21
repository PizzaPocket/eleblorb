extends Node

## Serialized bonded-companion roster (party blorbs + Xiao Hou Zi + Pandy),
## kept here
## because a kingdom portal's change_scene_to_file() (see kingdom_travel.gd)
## frees the whole scene tree -- party membership otherwise only exists as
## live node state (blorb.gd/xiao_hou_zi.gd's own in_party). capture_from_tree()
## must run right before a scene change; spawn_into() right after, once the
## destination scene's "Player" and "Terrain" siblings exist (blorb.gd and
## xiao_hou_zi.gd both resolve those via get_node("../Player")/("../Terrain"),
## so spawned members are added as children of that same parent).
##
## Deliberately a flat data snapshot, not live node references: a currently-
## worn (blorb suit) or melted (0 HP) blorb still gets carried across. Its
## level, XP, and grown stats persist, while the destination still reforms it
## unworn at full HP/MP; live suit assignments are rebound separately below.

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")
const PANDY_SCENE: PackedScene = preload("res://scenes/pandy.tscn")
const MANCHEGO_SCENE: PackedScene = preload("res://scenes/manchego.tscn")
const SUN_WU_KONG_SCENE: PackedScene = preload("res://scenes/sun_wu_kong.tscn")

## Spread spawned companions out a little so they don't all stack on one
## point; matches no particular formation, just avoids instant overlap jitter.
const SPAWN_SPACING := 1.1

var _roster: Array[Dictionary] = []
var _active_playable_id: String = PartyControl.HUMAN_ID
var _recovery_health_fraction: float = 1.0


func force_recovery_resources(minimum_fraction: float = 1.0) -> void:
	_recovery_health_fraction = clampf(minimum_fraction, 0.0, 1.0)
	_active_playable_id = PartyControl.HUMAN_ID


## Forgets the captured party so the next spawn_into() restores nothing. For a
## world that rebuilds its own party on every load (see demo_world.gd).
func discard_roster() -> void:
	_roster.clear()


func capture_from_tree(tree: SceneTree) -> void:
	_roster.clear()
	_active_playable_id = PartyControl.active_member_id()
	var player := tree.get_first_node_in_group("player") as Player
	var human_suit: BlorbSuitController = player.get_own_blorb_suit() if player != null else null
	var xiao_suit: BlorbSuitController = null
	for xiao_node in tree.get_nodes_in_group("xiao_hou_zi"):
		if xiao_node is XiaoHouZi and (xiao_node as XiaoHouZi).in_party:
			xiao_suit = (xiao_node as XiaoHouZi).get_blorb_suit()
			break
	for node in tree.get_nodes_in_group("blorbs"):
		var blorb := node as Blorb
		if blorb == null or not blorb.in_party or blorb.blorb_type == "size":
			continue
		var human_slot := human_suit.slot_for_assigned_blorb(blorb) if human_suit != null else ""
		var xiao_slot := xiao_suit.slot_for_assigned_blorb(blorb) if xiao_suit != null else ""
		_roster.append({
			"kind": "blorb",
			"element": blorb.element_state,
			"is_shiny": blorb.is_shiny,
			"is_blorbus": blorb.is_blorbus,
			"blorb_name": blorb.blorb_name,
			"core_items": blorb.core_items.duplicate(),
			"progression": blorb.progression_snapshot(),
			"assigned_slot": xiao_slot if xiao_slot != "" else human_slot,
			"assigned_wearer": PartyControl.XIAO_HOU_ZI_ID if xiao_slot != "" else PartyControl.HUMAN_ID,
		})
	for node in tree.get_nodes_in_group("xiao_hou_zi"):
		var monkey := node as XiaoHouZi
		if monkey == null or not monkey.in_party:
			continue
		_roster.append({"kind": "xiao_hou_zi"})
	for node in tree.get_nodes_in_group("pandy"):
		var panda := node as Pandy
		if panda == null or not panda.in_party:
			continue
		_roster.append({"kind": "pandy"})
	for node in tree.get_nodes_in_group("manchego"):
		var manchego := node as Manchego
		if manchego != null and manchego.available_to_player:
			_roster.append({"kind": "manchego"})
	for node in tree.get_nodes_in_group("sun_wu_kong"):
		var sage := node as SunWuKong
		if sage != null and sage.cloud_companion and sage.in_party:
			_roster.append({"kind": "sun_wu_kong"})


## `parent` must be the destination scene's root (the same node "Player" and
## "Terrain" hang off of). `near_position`/`facing` place the roster just
## behind wherever the player is arriving, facing the same way they are.
func spawn_into(parent: Node, near_position: Vector3, facing: Vector3) -> void:
	# The outskirts scene contains its starter trio as baked boot content. On
	# a return trip, replace those defaults with the captured party rather
	# than duplicating the same companions beside them.
	if not _roster.is_empty():
		for existing in parent.get_tree().get_nodes_in_group("blorbs"):
			var existing_blorb := existing as Blorb
			if existing_blorb != null and existing_blorb.in_party and existing_blorb.get_parent() == parent:
				existing_blorb.free()
	var flat_facing := Vector3(facing.x, 0.0, facing.z)
	if flat_facing.length() < 0.01:
		flat_facing = Vector3.BACK
	flat_facing = flat_facing.normalized()
	var index := 0
	var restored_human_assignments: Dictionary = {}
	var restored_xiao_assignments: Dictionary = {}
	for entry in _roster:
		var lateral := flat_facing.rotated(Vector3.UP, PI * 0.5) * (float(index) - float(_roster.size() - 1) * 0.5)
		var spawn_pos := near_position - flat_facing * 2.0 + lateral * SPAWN_SPACING
		match entry.get("kind", ""):
			"blorb":
				var spawned := _spawn_blorb(entry, parent, spawn_pos)
				var assigned_slot := entry.get("assigned_slot", "") as String
				if assigned_slot != "" and spawned != null:
					if String(entry.get("assigned_wearer", PartyControl.HUMAN_ID)) == PartyControl.XIAO_HOU_ZI_ID:
						restored_xiao_assignments[assigned_slot] = spawned
					else:
						restored_human_assignments[assigned_slot] = spawned
			"xiao_hou_zi":
				_spawn_xiao_hou_zi(parent, spawn_pos)
			"pandy":
				_spawn_pandy(parent, spawn_pos)
			"manchego":
				_spawn_manchego(parent, spawn_pos)
			"sun_wu_kong":
				_spawn_sun_wu_kong(parent, spawn_pos)
		index += 1
	var player := parent.get_tree().get_first_node_in_group("player") as Player
	if player != null:
		var human_suit := player.get_own_blorb_suit()
		human_suit.restore_assignments(restored_human_assignments)
		human_suit.auto_assign_new_members.call_deferred()
		for xiao_node in parent.get_tree().get_nodes_in_group("xiao_hou_zi"):
			if xiao_node is XiaoHouZi and (xiao_node as XiaoHouZi).in_party:
				(xiao_node as XiaoHouZi).get_blorb_suit().restore_assignments(restored_xiao_assignments)
				break
		player.restore_active_party_member.call_deferred(_active_playable_id)


func _spawn_blorb(entry: Dictionary, parent: Node, spawn_pos: Vector3) -> Blorb:
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
	blorb.restore_progression(entry.get("progression", {}))
	blorb.restore_for_recovery(_recovery_health_fraction)
	if entry.get("is_blorbus", false):
		blorb.become_blorbus()
	return blorb


func _spawn_xiao_hou_zi(parent: Node, spawn_pos: Vector3) -> void:
	var monkey: XiaoHouZi = XIAO_HOU_ZI_SCENE.instantiate()
	monkey.in_party = true
	monkey.position = spawn_pos
	parent.add_child(monkey)


func _spawn_pandy(parent: Node, spawn_pos: Vector3) -> void:
	var panda: Pandy = PANDY_SCENE.instantiate()
	panda.in_party = true
	panda.position = spawn_pos
	parent.add_child(panda)


func _spawn_manchego(parent: Node, spawn_pos: Vector3) -> void:
	var manchego: Manchego = MANCHEGO_SCENE.instantiate()
	manchego.follows_player = true
	manchego.available_to_player = true
	manchego.position = spawn_pos
	parent.add_child(manchego)


func _spawn_sun_wu_kong(parent: Node, spawn_pos: Vector3) -> void:
	var sage := SUN_WU_KONG_SCENE.instantiate() as SunWuKong
	sage.configure_as_jindouyun_companion(true)
	sage.position = spawn_pos + Vector3.UP * 1.5
	parent.add_child(sage)
