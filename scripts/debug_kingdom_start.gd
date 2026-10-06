class_name DebugKingdomStart
extends Node

## TEMPORARY test starts, launched from the title screen's debug buttons: begin a
## fresh run directly inside a kingdom with a ready-made suit, so a kingdom can be
## tested without playing to it. Remove with the buttons (start_screen.gd).
##
## A loadout names the kingdom scene, and what each suit slot holds: "blorbus"
## for the hero's own blorb, or an element for a freshly raised blorb. A head can
## also carry a core item (a helm).

const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")
const TEST_LEVEL := 30
const SPAWN_SPACING := 1.15
const TEST_TOKOINS := 100

const LOADOUTS := {
	"snow": {
		"label": "Snow Kingdom",
		"scene": "res://scenes/ice_kingdom.tscn",
		"slots": {
			"head": "blorbus", "leg_left": "snow", "leg_right": "snow",
			"torso": "ice", "arm_left": "ice", "arm_right": "ice",
		},
	},
	"ocean": {
		"label": "Ocean Kingdom",
		"scene": "res://scenes/ocean_kingdom.tscn",
		"slots": {
			"head": "blorbus", "leg_left": "water", "leg_right": "water",
			"torso": "water", "arm_left": "water", "arm_right": "water",
		},
	},
	"plant": {
		"label": "Plant Kingdom",
		"scene": "res://scenes/primate_kingdom.tscn",
		# The Leaf Hat only works on a plant head, so the whole suit is plant and
		# Blorbus walks beside it. Xiao Hou Zi joins the party.
		"slots": {
			"head": "plant", "leg_left": "plant", "leg_right": "plant",
			"torso": "plant", "arm_left": "plant", "arm_right": "plant",
		},
		"head_item": "Leaf Hat",
		"xiao_hou_zi": true,
	},
	"lava": {
		"label": "Lava Kingdom",
		"scene": "res://scenes/fire_kingdom.tscn",
		# A full lava suit with no Lava Helm.
		"slots": {
			"head": "fire", "leg_left": "fire", "leg_right": "fire",
			"torso": "fire", "arm_left": "fire", "arm_right": "fire",
		},
	},
}

var loadout_id := ""


func _ready() -> void:
	apply.call_deferred()


func apply() -> void:
	if not LOADOUTS.has(loadout_id):
		return
	var loadout: Dictionary = LOADOUTS[loadout_id]
	# KingdomBootstrap restores the saved party only after the world-build
	# barrier; making this authoritative before then would be overwritten.
	await LoadingScreen.wait_for_world_builds()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var kingdom := get_parent()
	var player := kingdom.get_node("Player") as Player
	var origin := player.global_position
	TokoinWallet.set_value(TEST_TOKOINS)
	var blorbus: Blorb = BLORB_SCENE.instantiate()
	blorbus.in_party = true
	blorbus.position = origin + Vector3(-4.0 * SPAWN_SPACING, 0.0, -2.0)
	kingdom.add_child(blorbus)
	blorbus.become_blorbus()
	SuitLoadout.raise_to_level(blorbus, TEST_LEVEL)
	var suit := player.get_own_blorb_suit()
	var assignments: Dictionary = {}
	var index := 0
	var slots: Dictionary = loadout["slots"]
	for slot: String in BlorbSuit.SLOT_ORDER:
		var kind := str(slots.get(slot, ""))
		if kind == "":
			continue
		if kind == "blorbus":
			assignments[slot] = blorbus
			continue
		var blorb: Blorb = BLORB_SCENE.instantiate()
		blorb.in_party = true
		blorb.initial_element = kind
		blorb.position = origin + Vector3((float(index) - 2.0) * SPAWN_SPACING, 0.0, -2.0)
		kingdom.add_child(blorb)
		SuitLoadout.raise_to_level(blorb, TEST_LEVEL)
		assignments[slot] = blorb
		index += 1
	if loadout.has("head_item") and assignments.has("head"):
		(assignments["head"] as Blorb).add_core_item(str(loadout["head_item"]))
	# Build the whole map first, then replace the provisional auto-assignment once.
	suit.restore_assignments(assignments)
	suit.toggle()
	if bool(loadout.get("xiao_hou_zi", false)) and kingdom.get_node_or_null("DebugXiaoHouZi") == null:
		var monkey := XIAO_HOU_ZI_SCENE.instantiate() as XiaoHouZi
		monkey.name = "DebugXiaoHouZi"
		monkey.in_party = true
		monkey.position = origin + Vector3(2.0, 0.0, -3.6)
		kingdom.add_child(monkey)
