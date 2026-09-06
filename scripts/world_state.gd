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

## Set once, the first time the player's own Ice Kingdom scene builds (see
## ice_kingdom_terrain.gd's own _ready()). Gates the Wood Kingdom reveal
## back in the Plant Kingdom (see jungle_kingdom_village.gd's own
## _build_wood_kingdom_area()) -- the first WorldState-gated kingdom
## generator in the project; every kingdom scene otherwise rebuilds
## identically from scratch on every visit.
var ice_kingdom_visited: bool = false

## Set once the player bribes the Chinese village's Emperor with 150
## tokoins (see chinese_village.gd's own _build_emperor()) -- gates his own
## post-bribery dialogue and the farmer's follow-up "delegate rule to him"
## action (see _build_farmer_and_pandy_quest()), which is what actually
## hands over Pandy. Lives here rather than on the Emperor NPC instance
## itself for the same reason false_hero_defeated does: main.tscn (and
## ChineseVillage with it) reloads on every kingdom portal round trip.
var chinese_village_emperor_deposed: bool = false

## The farmer has accepted stewardship of the village and Pandy has been
## entrusted to the player's party. Kept separately from the Emperor's
## departure so the two-step conversation survives world travel cleanly.
var chinese_village_rule_delegated: bool = false
var pandy_joined: bool = false

## Sun Wu Kong remains a resident of the Chinese village. Returning the
## Jingu Bang unlocks Xiao Hou Zi's ability to call him into a fight; he is
## never serialized as a walking party member.
var sun_wu_kong_freed: bool = false
var sun_wu_kong_has_jingu_bang: bool = false
var sun_wu_kong_summon_unlocked: bool = false


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
