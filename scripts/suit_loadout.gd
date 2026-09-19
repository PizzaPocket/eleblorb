class_name SuitLoadout
extends RefCounted

## Builds suit sets: groups of blorbs of one element, one per suit slot, ready
## for a SuitRoster to swap onto the hero. The testing and demo counterpart of
## recruiting, gemming and assigning blorbs by hand.

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
## Special-traversal stats (skating, swimming, flight) scale with worn blorbs'
## Speed; a fresh level-1 suit would under-represent every power being tested.
const TEST_LEVEL := 30
const FULL_SUIT_SLOTS: Array[String] = ["head", "leg_left", "leg_right", "torso", "arm_left", "arm_right"]


## Spawns one `element` blorb per slot in a loose ring around `center`, at
## TEST_LEVEL. `head_item` is bound into the head blorb's core (a helm such as
## the Diving Helmet). An empty element makes plain Normal blorbs, and
## `shiny` makes them the rare shiny variant. Returned in the order of
## `slots`, which is the order a SuitRoster assigns them.
static func spawn_set(
	world: Node, element: String, head_item: String, center: Vector3,
	slots: Array[String] = FULL_SUIT_SLOTS, spread: float = 2.2, shiny: bool = false
) -> Array[Blorb]:
	var created: Array[Blorb] = []
	for index in slots.size():
		var blorb: Blorb = BLORB_SCENE.instantiate()
		blorb.in_party = false
		blorb.is_starter_trio = false
		blorb.initial_element = element
		blorb.is_shiny = shiny
		if slots[index] == "head" and head_item != "":
			var items: Array[String] = [head_item]
			blorb.core_items = items
		var angle := TAU * float(index) / float(slots.size())
		blorb.position = center + Vector3(cos(angle), 0.0, sin(angle)) * spread
		world.add_child(blorb)
		raise_to_level(blorb, TEST_LEVEL)
		created.append(blorb)
	return created


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
