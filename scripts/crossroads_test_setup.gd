extends Node

## TEMPORARY test scaffold. Normal loading still enters the Crossroads, then
## this gives a fresh run a Blorbus already wearing the Bird Helm on his head
## (Blorbaka's own core item -- see blorb_suit.gd/false_hero_nme.gd) and an
## Air blorb on his chest, so the Sky Kingdom's visibility gate and the Bird
## Helm's own design can both be playtested immediately without first
## fighting through the false hero for real. WorldState prevents the payload
## duplicating after kingdom travel.
const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")
const TEST_LEVEL := 30

func _ready() -> void:
	call_deferred("_install_test_loadout")

func _install_test_loadout() -> void:
	if WorldState.debug_crossroads_loadout_applied:
		return
	await get_tree().create_timer(0.15).timeout
	var world := get_parent()
	var player := world.get_node("Player") as Player
	var origin := player.global_position

	var blorbus: Blorb = null
	for node_name in ["Blorb1", "Blorb2", "Blorb3"]:
		var starter := world.get_node_or_null(node_name) as Blorb
		if starter != null:
			blorbus = starter
			break
	if blorbus == null:
		blorbus = BLORB_SCENE.instantiate() as Blorb
		blorbus.in_party = true
		blorbus.position = origin + Vector3(-1.15, 0, -2.5)
		world.add_child(blorbus)
	blorbus.is_starter_trio = false
	blorbus.become_blorbus()
	blorbus.add_core_item("Bird Helm")
	_set_test_level(blorbus)

	var air_blorb := BLORB_SCENE.instantiate() as Blorb
	air_blorb.in_party = true
	air_blorb.initial_element = "air"
	air_blorb.position = origin + Vector3(1.15, 0, -2.5)
	world.add_child(air_blorb)
	_set_test_level(air_blorb)

	# Per direct request, so flight/swim can be A/B tested between the human
	# and Xiao Hou Zi without first fighting through the jungle to recruit
	# him for real. Only the "in_party" flag actually matters for
	# _try_start_xiao_hou_zi_control()'s own eligibility check (see
	# player.gd) -- everything else (groups, PartyControl registration) is
	# handled by his own _ready(), same as any real recruitment moment.
	if world.get_node_or_null("DebugXiaoHouZi") == null:
		var monkey := XIAO_HOU_ZI_SCENE.instantiate() as XiaoHouZi
		monkey.name = "DebugXiaoHouZi"
		monkey.in_party = true
		monkey.position = origin + Vector3(0.0, 0, -3.6)
		world.add_child(monkey)

	# Debug setup belongs to the human character regardless of which playable
	# PartyControl may have restored as the current perspective -- same
	# reasoning as ice_kingdom_test_setup.gd's own identical comment.
	var suit := player.get_own_blorb_suit()
	suit.equip_to_slot(blorbus, "head")
	suit.equip_to_slot(air_blorb, "torso")
	# Per direct correction, the suit starts OFF (not toggled on) -- the
	# wake-up/stand-up camera intro was getting cut short specifically when
	# the run began already wearing a suit. The assignments above are still
	# in place, so the player can toggle the suit on themselves once ready.
	WorldState.debug_crossroads_loadout_applied = true

func _set_test_level(blorb: Blorb) -> void:
	if blorb == null or blorb.level >= TEST_LEVEL:
		return
	var snapshot := blorb.progression_snapshot()
	for next_level in range(blorb.level+1,TEST_LEVEL+1):
		snapshot["strength"] = int(snapshot["strength"])+1+(1 if next_level%4 == 0 else 0)
		snapshot["defense"] = int(snapshot["defense"])+1+(1 if next_level%5 == 0 else 0)
		snapshot["speed"] = int(snapshot["speed"])+1+(1 if next_level%6 == 0 else 0)
		snapshot["max_hp"] = int(snapshot["max_hp"])+4+ceili(float(next_level)/5.0)
		snapshot["max_mp"] = int(snapshot["max_mp"])+2+ceili(float(next_level)/8.0)
	snapshot["level"] = TEST_LEVEL
	snapshot["experience"] = 0
	blorb.restore_progression(snapshot)
