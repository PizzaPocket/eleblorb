extends Node

## TEMPORARY Ice/Snow Kingdom playtest scaffold, paired with loading_bootstrap
## while this biome is under review. It supplies a medium-level winter suit,
## with Ice blorbs on both legs for skate testing and Snow elsewhere, while
## keeping Blorbus unassigned beside the player.
const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const SNOW_BLORB_COUNT := 6
const TEST_LEVEL := 30
const SPAWN_SPACING := 1.15


func _ready() -> void:
	call_deferred("_spawn_test_party")


func _spawn_test_party() -> void:
	# KingdomBootstrap restores Party's saved assignment map only after the
	# procedural world-build barrier. Building the visible debug suit before
	# that point made the first outfit look correct while its underlying map
	# was subsequently overwritten; the next toggle then wore a different
	# group. Wait through that restoration and one full frame beyond it before
	# making this test configuration authoritative.
	await LoadingScreen.wait_for_world_builds()
	await get_tree().process_frame
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group("blorbs"):
		var existing:=node as Blorb
		if existing!=null and existing.in_party:
			return
	# TEMPORARY purchasing test allowance. Set once with the rest of this
	# fresh-start scaffold so revisiting the kingdom cannot refill the wallet.
	TokoinWallet.set_value(30)

	var kingdom:=get_parent()
	var player:=kingdom.get_node("Player") as Player
	var origin:=player.global_position

	var blorbus: Blorb=BLORB_SCENE.instantiate()
	blorbus.in_party=true
	blorbus.position=origin+Vector3(-4.0*SPAWN_SPACING,0.0,-2.0)
	kingdom.add_child(blorbus)
	blorbus.become_blorbus()

	# Debug setup belongs to the human character regardless of which playable
	# PartyControl may have restored as the current perspective.
	var suit:=player.get_own_blorb_suit()
	var exact_assignments: Dictionary={}
	for i in SNOW_BLORB_COUNT:
		var blorb: Blorb=BLORB_SCENE.instantiate()
		blorb.in_party=true
		blorb.initial_element="ice" if i in [1,2] else "snow"
		blorb.position=origin+Vector3((float(i)-2.5)*SPAWN_SPACING,0.0,-2.0)
		kingdom.add_child(blorb)
		_level_up_to(blorb,TEST_LEVEL)
		# Build the complete map first. Individual add_child() calls can trigger
		# the normal party auto-assignment between iterations; replacing that
		# provisional map once, after every test blorb exists, makes repeated
		# suit removal/equip deterministic.
		exact_assignments[BlorbSuit.SLOT_ORDER[i]]=blorb
	suit.restore_assignments(exact_assignments)
	suit.toggle()


func _level_up_to(blorb: Blorb,target_level: int) -> void:
	while blorb.level<target_level:
		blorb.gain_experience(blorb.xp_to_next_level())
