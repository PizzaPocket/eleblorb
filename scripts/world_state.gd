extends Node

## Small pieces of campaign state that must outlive any one world scene:
## unique-pickup claims and progression gates such as Blorbus's awakening.
## portal.gd/kingdom_travel.gd's change_scene_to_file() frees and later
## reloads the outskirts scene on every round trip, so neither belongs on a
## scene-local actor. Unique pickups opt in through a stable id; "" means
## "not unique" and is never recorded.

var _collected_ids: Dictionary = {}

## Wild blorbs only begin noticing and bonding with the party once the
## starter trio's psychic Blorbus has awakened. As an autoload this survives
## kingdom scene changes; Party's restore path also reasserts it when it
## rebuilds Blorbus from the serialized roster.
var blorbus_unlocked: bool = false

## The coma-awakening tableau belongs only to the first arrival in the
## starting field. Keep its completion outside the scene so returning from a
## kingdom (which reloads main.tscn) can never replay the opening.
var opening_wake_completed: bool = false

## A permanent, one-time story beat -- once True, town_generator.gd never
## spawns False Hero again (see false_hero_should_appear() below). Lives
## here rather than on the NPC instance itself since main.tscn reloads
## (and every NPC with it) on each kingdom portal round trip.
var false_hero_defeated: bool = false

## Set once False Hero is defeated -- "" means no title yet. A plain string
## rather than an enum/id: nothing else reads this except whatever surfaces
## it to the player (Hud), and there's only ever been the one title so far.
var player_title: String = ""


func is_collected(id: String) -> bool:
	return id != "" and _collected_ids.has(id)


func mark_collected(id: String) -> void:
	if id != "":
		_collected_ids[id] = true


## False Hero only ever appears once Blorbus has awakened AND the party has
## enough in-party, non-melted blorbs to fill every slot of a real blorb
## suit -- per direct instruction, before that villagers get their normal,
## unrelated dialogue and he simply isn't there. Computed fresh each call
## (this project's own established convention -- see e.g. blorb_suit_
## controller.gd's own auto_assign_new_members(), which scans the same
## "blorbs" group with the same in_party/is_melted filter) rather than
## cached, so it can't go stale across a party change mid-session.
func false_hero_should_appear(tree: SceneTree) -> bool:
	if false_hero_defeated or not blorbus_unlocked:
		return false
	var in_party_count := 0
	for node in tree.get_nodes_in_group("blorbs"):
		if node.in_party and not node.is_melted:
			in_party_count += 1
	return in_party_count >= BlorbSuit.SLOT_ORDER.size()
