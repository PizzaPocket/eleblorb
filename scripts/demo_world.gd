extends Node3D

## The demo world (see DemoWorldTerrain): a playable tour of every suit with a
## clear traversal power, and the testing ground for movement modes. The hero
## wakes in a clearing with two Normal blorbs and walks east, where each
## biome begins at a CheckpointPortal that swaps in that biome's suit.

const START_BLORB_SLOTS: Array[String] = ["leg_left", "leg_right"]
## The valley runs toward +X. The camera looks east over the hero's shoulder
## once he is up; during the wake intro he faces west, toward the camera.
const EAST_CAMERA_YAW := -PI * 0.5
const WEST_BODY_YAW := -PI * 0.5

@onready var _player: Player = $Player
@onready var _terrain: DemoWorldTerrain = $Terrain


func _ready() -> void:
	for portal_spec in DemoWorldTerrain.PORTALS:
		var spec: Dictionary = portal_spec
		var portal := CheckpointPortal.new()
		portal.name = "Portal_%s" % String(spec["element"])
		portal.element = spec["element"]
		portal.head_item = spec["head_item"]
		portal.position = _terrain.get_portal_position(spec)
		# The opening faces along local Z; turn that to face east (+X).
		portal.rotation.y = PI * 0.5
		add_child(portal)
	call_deferred("_finish_loading")


func _finish_loading() -> void:
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	var start := _terrain.get_start_point() + Vector3.UP * Player.FOOT_OFFSET
	if RecoveryManager.has_pending_recovery():
		# Identity basis: the player's root must never be rotated (see the
		# CONVENTION note on Player.camera_rig).
		await RecoveryManager.finish_scene_recovery(self, Transform3D(Basis(), start))
		LoadingScreen.complete()
		return
	_player.global_position = start
	_player.set_body_heading(WEST_BODY_YAW)
	_player.camera_rig.rotation.y = EAST_CAMERA_YAW
	_spawn_starting_blorbs()
	if not WorldState.opening_wake_completed:
		_player.begin_wake_intro()
	LoadingScreen.complete()


## Two Normal blorbs, assigned to the legs with the suit off: the opening's
## plain companions before the first portal.
func _spawn_starting_blorbs() -> void:
	var created: Array[Blorb] = []
	for index in START_BLORB_SLOTS.size():
		var blorb: Blorb = SuitLoadout.BLORB_SCENE.instantiate()
		blorb.in_party = true
		blorb.is_starter_trio = false
		blorb.position = _player.global_position + Vector3(-2.5, 0.0, -1.2 + 2.4 * float(index))
		add_child(blorb)
		created.append(blorb)
	await get_tree().process_frame
	var suit := _player.get_own_blorb_suit()
	for index in created.size():
		suit.equip_to_slot(created[index], START_BLORB_SLOTS[index])
