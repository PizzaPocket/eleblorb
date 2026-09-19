extends Node3D

## The demo world (see DemoWorldTerrain): a playable tour of every suit with a
## clear traversal power, and the testing ground for movement modes. The hero
## wakes on the floor of a pit with five Normal blorbs and Xiao Hou Zi, climbs
## out by bouncing on his blorbs up the ledges of its wall, and finds Manchego
## and Pandy stationed beside the shiny portal on the plain above; passing
## through it brings them into the party. Beyond lie forest plains where wild
## shiny blorbs roam, and the course runs on east. Each border between
## biomes is a gate of two one-way portals back to back, facing apart: each
## biome's portal stands on the side you enter it from, facing you, and its
## blorbs wait just beyond it, inside the biome. Walking or riding through a
## portal's face swaps suits (the worn blorbs hop off, the waiting ones join
## and hop on; see SuitRoster); passing through the back of the other portal
## does nothing. The party only grows: blorbs that hop off keep following.

const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")
const JUNGLE_KINGDOM_FOLIAGE := preload("res://scripts/jungle_kingdom_foliage.gd")
const MANCHEGO_SCENE: PackedScene = preload("res://scenes/manchego.tscn")
const PANDY_SCENE: PackedScene = preload("res://scenes/pandy.tscn")
## The hero's five starting Normal blorbs, assigned everywhere but the head.
const NORMAL_SLOTS: Array[String] = ["leg_left", "leg_right", "arm_left", "arm_right", "torso"]
## Wild shiny blorbs roaming the forest plains (as in the Crossroads field).
const FOREST_SHINY_COUNT := 5
## The demo's portals span most of the valley floor, with piping to match.
const PORTAL_TUBE_RADIUS := 0.35
## Half the gap between a gate's two portals: just over PORTAL_TUBE_RADIUS,
## so their rings touch without intersecting.
const GATE_HALF_GAP := 0.37
## Where Manchego and Pandy wait, just past the shiny portal on the plain.
const MANCHEGO_STATION := Vector2(78.0, -12.0)
const PANDY_STATION := Vector2(78.0, 12.0)
## How far past its portal (inside the biome it opens onto) a waiting set idles.
const SET_WAIT_OFFSET := 6.0
## The valley runs toward +X. The camera looks east over the hero's shoulder
## once he is up; during the wake intro he faces west, toward the camera.
const EAST_CAMERA_YAW := -PI * 0.5
const WEST_BODY_YAW := -PI * 0.5

@onready var _player: Player = $Player
@onready var _terrain: DemoWorldTerrain = $Terrain
var _roster := SuitRoster.new()
var _manchego: Manchego
var _pandy: Pandy


func _ready() -> void:
	# Wild blorbs (the forest's shinies) only offer to join once Blorbus has
	# awakened; the demo starts past that point so they can be recruited.
	WorldState.blorbus_unlocked = true
	_roster.name = "SuitRoster"
	add_child(_roster)
	_roster.setup(_player)
	for border_spec in DemoWorldTerrain.BORDERS:
		var border: Dictionary = border_spec
		var x: float = border["x"]
		# Walking east you meet the eastern biome's portal face first; walking
		# west, the western biome's.
		var gate_scale: float = border.get("portal_scale", 1.0)
		_add_portal(border["east"], x - GATE_HALF_GAP * gate_scale, -PI * 0.5, "", gate_scale)
		_add_portal(border["west"], x + GATE_HALF_GAP * gate_scale, PI * 0.5, "", gate_scale)
	# The Nautilus portal on the seabed, facing west like the water portal.
	var nautilus_portal := _add_portal("water", DemoWorldTerrain.NAUTILUS_PORTAL_X, -PI * 0.5, "nautilus")
	nautilus_portal.position = _terrain.nautilus_portal_point()
	# The Crystal Skates portal, standing on the frozen lake's ice.
	var crystal_portal := _add_portal("ice", DemoWorldTerrain.CRYSTAL_PORTAL_X, -PI * 0.5, "crystal", 1.0, CrystalTrack.CRYSTAL_TINT)
	crystal_portal.position.y = DemoWorldTerrain.ICE_SURFACE_LEVEL
	_add_plant_jungle()
	call_deferred("_finish_loading")


## The Primate Kingdom's own jungle scatter, windowed onto the plant biome at
## the same spot DemoWorldTerrain shows that kingdom's ground. Named Scatter,
## the sibling characters query for walkable tree-canopy support.
func _add_plant_jungle() -> void:
	var jungle: Node3D = JUNGLE_KINGDOM_FOLIAGE.new()
	jungle.name = "Scatter"
	jungle.window_enabled = true
	jungle.window_source_center = DemoWorldTerrain.PLANT_SOURCE
	jungle.window_half_size = DemoWorldTerrain.PLANT_HALF
	jungle.window_target_center = DemoWorldTerrain.PLANT_CENTER
	add_child(jungle)


## One-way portals: `facing_yaw` turns the portal's face (its local +Z) to
## face the side you approach it from.
func _add_portal(element: String, x: float, facing_yaw: float, suit_key: String = "", size_scale: float = 1.0, tint: Color = Color(0, 0, 0, 0)) -> CheckpointPortal:
	var portal := CheckpointPortal.new()
	portal.name = "Portal_%s_%d" % [suit_key if suit_key != "" else (element if element != "" else "normal"), int(x)]
	portal.element = element
	portal.suit_key = suit_key
	portal.tint_override = tint
	portal.one_way = true
	portal.half_width = DemoWorldTerrain.PORTAL_HALF_WIDTH * size_scale
	portal.half_height = DemoWorldTerrain.PORTAL_HALF_HEIGHT * size_scale
	portal.tube_radius = PORTAL_TUBE_RADIUS * size_scale
	portal.position = _terrain.get_path_point(x)
	portal.rotation.y = facing_yaw
	portal.crossed.connect(_roster.switch_to)
	if element == "shiny":
		portal.crossed.connect(_on_shiny_portal_crossed)
	add_child(portal)
	return portal


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
## its biome, plus the hero's starting five and Xiao Hou Zi, and Manchego and
## Pandy stationed by the shiny portal.
func _build_party() -> void:
	var normal := SuitLoadout.spawn_set(self, "", "", _player.global_position + Vector3(-3.0, 0.0, 0.0), NORMAL_SLOTS, 1.8)
	_roster.add_set("", normal, NORMAL_SLOTS)
	for border_spec in DemoWorldTerrain.BORDERS:
		var border: Dictionary = border_spec
		var element: String = border["east"]
		var head_item: String = DemoWorldTerrain.HEAD_ITEMS.get(element, "")
		# Just past the portal, inside the biome it opens onto.
		var home := _terrain.get_path_point(float(border["x"]) + SET_WAIT_OFFSET, 5.0)
		var shiny := element == "shiny"
		var blorbs := SuitLoadout.spawn_set(self, "" if shiny else element, head_item, home, SuitLoadout.FULL_SUIT_SLOTS, 2.2, shiny)
		_roster.add_set(element, blorbs, SuitLoadout.FULL_SUIT_SLOTS)
	# One water blorb waiting just past the Nautilus portal on the seabed,
	# wearing the Nautilus Crown: it takes over the head slot alone.
	var nautilus_home := _terrain.nautilus_portal_point() + Vector3(SET_WAIT_OFFSET, 0.0, 5.0)
	var nautilus_head: Array[String] = ["head"]
	_roster.add_overlay("nautilus", SuitLoadout.spawn_set(self, "water", "Nautilus Crown", nautilus_home, nautilus_head, 0.0), nautilus_head)
	# Two Ice blorbs bound with Crystal Skates, waiting on the ice just past
	# the crystal portal: they take over both legs.
	var crystal_home := Vector3(DemoWorldTerrain.CRYSTAL_PORTAL_X + SET_WAIT_OFFSET, DemoWorldTerrain.ICE_SURFACE_LEVEL, 5.0)
	var crystal_legs: Array[String] = ["leg_left", "leg_right"]
	var crystal_items := {"leg_left": "Crystal Skates", "leg_right": "Crystal Skates"}
	_roster.add_overlay("crystal", SuitLoadout.spawn_set(self, "ice", "", crystal_home, crystal_legs, 1.5, false, crystal_items), crystal_legs)
	_roster.start_with("")
	_spawn_forest_shinies()
	var monkey := XIAO_HOU_ZI_SCENE.instantiate() as XiaoHouZi
	monkey.in_party = true
	monkey.position = _player.global_position + Vector3(-3.0, 0.0, 2.5)
	add_child(monkey)
	# Stationed: idling in place, not yet in the party and not yet rideable.
	_manchego = MANCHEGO_SCENE.instantiate() as Manchego
	_manchego.follows_player = false
	_manchego.available_to_player = false
	_manchego.position = _terrain.get_path_point(MANCHEGO_STATION.x, MANCHEGO_STATION.y)
	_manchego.rotation.y = -PI * 0.5
	add_child(_manchego)
	_manchego.set_available_to_player(false)
	_pandy = PANDY_SCENE.instantiate() as Pandy
	_pandy.in_party = false
	_pandy.position = _terrain.get_path_point(PANDY_STATION.x, PANDY_STATION.y)
	add_child(_pandy)


## Passing through the shiny portal brings the stationed pair into the party.
func _on_shiny_portal_crossed(_element: String) -> void:
	if is_instance_valid(_manchego) and not _manchego.follows_player:
		_manchego.follows_player = true
		_manchego.set_available_to_player(true)
	if is_instance_valid(_pandy):
		_pandy.in_party = true


## Wild, recruitable shiny blorbs wandering the forest plains, placed as the
## Crossroads places its own (wilderness_scatter.gd's _place_wild_blorb()).
func _spawn_forest_shinies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260919
	for index in FOREST_SHINY_COUNT:
		var x := rng.randf_range(DemoWorldTerrain.FOREST_ZONE.x + 20.0, DemoWorldTerrain.FOREST_ZONE.y - 20.0)
		var z := rng.randf_range(-80.0, 80.0)
		var shiny: Blorb = SuitLoadout.BLORB_SCENE.instantiate()
		shiny.in_party = false
		shiny.is_shiny = true
		shiny.position = _terrain.get_path_point(x, z)
		add_child(shiny)
