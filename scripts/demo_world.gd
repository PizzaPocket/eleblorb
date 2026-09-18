extends Node3D

## The demo world (see DemoWorldTerrain): a playable tour of every suit with a
## clear traversal power, and the testing ground for movement modes. The hero
## wakes in a clearing with two Normal blorbs, Xiao Hou Zi and Manchego, and
## walks east. Each border between biomes is a gate of two portals back to
## back; each suit's blorbs wait beside their portal, and passing through the
## other side's portal swaps suits: the worn blorbs hop off and stay, and the
## waiting ones hop on (see SuitRoster).

const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")
const MANCHEGO_SCENE: PackedScene = preload("res://scenes/manchego.tscn")
const NORMAL_SLOTS: Array[String] = ["leg_left", "leg_right"]
## Half the gap between a gate's two portals: just over CheckpointPortal's
## TUBE_RADIUS (0.11), so their rings touch without intersecting.
const GATE_HALF_GAP := 0.13
## How far past its gate a waiting set idles, on its own side.
const SET_WAIT_OFFSET := 6.0
## The valley runs toward +X. The camera looks east over the hero's shoulder
## once he is up; during the wake intro he faces west, toward the camera.
const EAST_CAMERA_YAW := -PI * 0.5
const WEST_BODY_YAW := -PI * 0.5

@onready var _player: Player = $Player
@onready var _terrain: DemoWorldTerrain = $Terrain
var _roster := SuitRoster.new()


func _ready() -> void:
	_roster.name = "SuitRoster"
	add_child(_roster)
	_roster.setup(_player)
	for border_spec in DemoWorldTerrain.BORDERS:
		var border: Dictionary = border_spec
		var x: float = border["x"]
		_add_portal(border["west"], x - GATE_HALF_GAP)
		_add_portal(border["east"], x + GATE_HALF_GAP)
	call_deferred("_finish_loading")


## Portals face east (their local Z turned to +X); either can be crossed from
## either side, and the roster ignores the one for the suit already worn.
func _add_portal(element: String, x: float) -> void:
	var portal := CheckpointPortal.new()
	portal.name = "Portal_%s_%d" % [element if element != "" else "normal", int(x)]
	portal.element = element
	portal.position = _terrain.get_path_point(x)
	portal.rotation.y = PI * 0.5
	portal.crossed.connect(_roster.switch_to)
	add_child(portal)


func _finish_loading() -> void:
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	var start := _terrain.get_start_point() + Vector3.UP * Player.FOOT_OFFSET
	var recovering := RecoveryManager.has_pending_recovery()
	if recovering:
		# This world rebuilds its whole party below, so the roster captured at
		# the faint must not also be restored. Identity basis: the player's
		# root is never rotated (see the CONVENTION note on Player.camera_rig).
		Party.discard_roster()
		await RecoveryManager.finish_scene_recovery(self, Transform3D(Basis(), start))
	else:
		_player.global_position = start
		_player.set_body_heading(WEST_BODY_YAW)
		_player.camera_rig.rotation.y = EAST_CAMERA_YAW
	_build_party()
	if not recovering and not WorldState.opening_wake_completed:
		_player.begin_wake_intro()
	LoadingScreen.complete()


## Every suit set, waiting on its own side of the first gate that leads into
## its biome, plus the hero's starting pair, Xiao Hou Zi and Manchego.
func _build_party() -> void:
	var normal := SuitLoadout.spawn_set(self, "", "", _player.global_position + Vector3(-2.5, 0.0, 0.0), NORMAL_SLOTS, 1.2)
	_roster.add_set("", normal, NORMAL_SLOTS)
	for border_spec in DemoWorldTerrain.BORDERS:
		var border: Dictionary = border_spec
		var element: String = border["east"]
		var head_item: String = DemoWorldTerrain.HEAD_ITEMS.get(element, "")
		var home := _terrain.get_path_point(float(border["x"]) + SET_WAIT_OFFSET, 5.0)
		var blorbs := SuitLoadout.spawn_set(self, element, head_item, home)
		_roster.add_set(element, blorbs, SuitLoadout.FULL_SUIT_SLOTS)
	_roster.start_with("")
	var monkey := XIAO_HOU_ZI_SCENE.instantiate() as XiaoHouZi
	monkey.in_party = true
	monkey.position = _player.global_position + Vector3(-3.0, 0.0, 2.5)
	add_child(monkey)
	var manchego := MANCHEGO_SCENE.instantiate() as Manchego
	manchego.follows_player = true
	manchego.available_to_player = true
	manchego.position = _player.global_position + Vector3(-4.0, 0.0, -3.0)
	add_child(manchego)
