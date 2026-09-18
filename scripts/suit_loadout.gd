class_name SuitLoadout
extends RefCounted

## Assembles a complete single-element blorb suit on the player: the testing
## and demo counterpart of recruiting, gemming and assigning six blorbs by
## hand. Used by CheckpointPortal and the demo world's opening loadout.

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
## Special-traversal stats (skating, swimming, flight) scale with worn blorbs'
## Speed; a fresh level-1 suit would under-represent every power being tested.
const TEST_LEVEL := 30


## Drops every current party blorb (Blorbus excepted: he is a character, not
## suit material), then gives the player six new `element` blorbs assigned to
## every slot and puts the suit on, so they visibly hop onto the body.
## `head_item` is bound into the head blorb's core (a helm such as the Diving
## Helmet or Lava Helm). An empty element makes plain Normal blorbs.
static func assemble(player: Player, element: String, head_item: String = "") -> void:
	var tree := player.get_tree()
	var world := player.get_parent()
	var suit := player.get_own_blorb_suit()
	# Instant teardown of any worn suit, keeping nothing: the old blorbs leave.
	suit.suspend_for_story()
	suit.resume_after_story()
	for slot in BlorbSuit.SLOT_ORDER:
		suit.unequip_slot(slot)
	for node in tree.get_nodes_in_group("blorbs"):
		var old := node as Blorb
		if old == null or not old.in_party or old.blorb_type == "size" or old.is_blorbus:
			continue
		for wearer in tree.get_nodes_in_group("party_playable_candidates"):
			if wearer.has_method("get_own_blorb_suit"):
				(wearer.get_own_blorb_suit() as BlorbSuitController).remove_assignment_for_blorb(old)
		old.queue_free()
	var created: Array[Blorb] = []
	for index in BlorbSuit.SLOT_ORDER.size():
		var slot: String = BlorbSuit.SLOT_ORDER[index]
		var blorb: Blorb = BLORB_SCENE.instantiate()
		blorb.in_party = true
		blorb.is_starter_trio = false
		blorb.initial_element = element
		if slot == "head" and head_item != "":
			var items: Array[String] = [head_item]
			blorb.core_items = items
		# A ring around the player, so the hop onto the body reads clearly.
		var angle := TAU * float(index) / float(BlorbSuit.SLOT_ORDER.size())
		blorb.position = player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 1.8
		world.add_child(blorb)
		raise_to_level(blorb, TEST_LEVEL)
		created.append(blorb)
	# Let the new blorbs finish _ready() (element, body, party registration)
	# before assigning them, and let the freed ones leave the tree.
	await tree.process_frame
	for index in created.size():
		if is_instance_valid(created[index]):
			suit.equip_to_slot(created[index], BlorbSuit.SLOT_ORDER[index])
	suit.toggle()


## Raises a blorb to `level` with the same per-level stat growth as earning it.
static func raise_to_level(blorb: Blorb, level: int) -> void:
	if blorb == null or blorb.level >= level:
		return
	var snapshot := blorb.progression_snapshot()
	for next_level in range(blorb.level + 1, level + 1):
		snapshot["strength"] = int(snapshot["strength"]) + 1 + (1 if next_level % 4 == 0 else 0)
		snapshot["defense"] = int(snapshot["defense"]) + 1 + (1 if next_level % 5 == 0 else 0)
		snapshot["speed"] = int(snapshot["speed"]) + 1 + (1 if next_level % 6 == 0 else 0)
		snapshot["max_hp"] = int(snapshot["max_hp"]) + 4 + ceili(float(next_level) / 5.0)
		snapshot["max_mp"] = int(snapshot["max_mp"]) + 2 + ceili(float(next_level) / 8.0)
	snapshot["level"] = level
	snapshot["experience"] = 0
	blorb.restore_progression(snapshot)
