extends Node3D

## The demo world (see DemoWorldTerrain): a playable tour of every suit with a
## clear traversal power, and the testing ground for movement modes. The hero
## wakes on the floor of a pit with five Normal blorbs, climbs
## out by bouncing on his blorbs up the ledges of its wall, and finds Manchego
## and Pandy stationed beside the shiny portal on the plain above; passing
## through it brings them into the party. Xiao Hou Zi instead waits at the
## Plant portal and joins only when that portal is crossed. Beyond lie forest
## plains where wild shiny blorbs roam, and the course runs on east. Each border between
## biomes is a gate of two one-way portals back to back, facing apart: each
## biome's portal stands on the side you enter it from, facing you, and its
## blorbs wait just beyond it, inside the biome. Walking or riding through a
## portal's face swaps suits (the worn blorbs hop off, the waiting ones join
## and hop on; see SuitRoster); passing through the back of the other portal
## does nothing. The party only grows: blorbs that hop off keep following.

const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")
const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const JUNGLE_KINGDOM_FOLIAGE := preload("res://scripts/jungle_kingdom_foliage.gd")
const MANCHEGO_SCENE: PackedScene = preload("res://scenes/manchego.tscn")
const PANDY_SCENE: PackedScene = preload("res://scenes/pandy.tscn")
const SUN_WU_KONG_SCENE: PackedScene = preload("res://scenes/sun_wu_kong.tscn")
const DA_HOU_ZI_SCENE: PackedScene = preload("res://scenes/ape_template_preview.tscn")
const DA_HOU_ZI_CONFIG := preload("res://scripts/primate_kingdom_gorilla.gd")
## The demo world's two-song playlist and reusable WorldMusic system remain
## available for the later music pass. Playback is intentionally disabled in
## _ready() for now so movement, ambience, powers and other foley can be heard
## and tuned without musical masking.
const MUSIC_PLAYLIST: Array[AudioStream] = [
	preload("res://assets/audio/music/demo_song2.mp3"),
	preload("res://assets/audio/music/demo_song3.mp3"),
]
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
const SPACE_PORTAL_Y := 750.0
const SPACESHIP_Y := 900.0
const SPACE_TINT := Color(0.12, 0.045, 0.22)

@onready var _player: Player = $Player
@onready var _terrain: DemoWorldTerrain = $Terrain
var _roster := SuitRoster.new()
var _manchego: Manchego
var _pandy: Pandy
var _sun_wu_kong: SunWuKong
var _xiao_hou_zi: XiaoHouZi
var _spaceship: DemoSpaceship
var _space_blorbus: Blorb


func _ready() -> void:
	# Wild blorbs (the forest's shinies) only offer to join once Blorbus has
	# awakened; the demo starts past that point so they can be recruited.
	WorldState.blorbus_unlocked = true
	_roster.name = "SuitRoster"
	add_child(_roster)
	_roster.setup(_player)
	var atmosphere := AtmosphereLayer.new()
	atmosphere.name = "AtmosphereLayer"
	add_child(atmosphere)
	for border_spec in DemoWorldTerrain.BORDERS:
		var border: Dictionary = border_spec
		var x: float = border["x"]
		# Walking east you meet the eastern biome's portal face first; walking
		# west, the western biome's.
		var gate_scale: float = border.get("portal_scale", 1.0)
		var gate_width: float = border.get("portal_width_scale", gate_scale)
		var gate_height: float = border.get("portal_height_scale", gate_scale)
		var bend := DemoWorldTerrain.path_yaw(x)
		# A border is one architectural gate: derive both directional membranes
		# from one centre, tangent and size. They sit a small equal distance on
		# opposite sides of that centre (back-to-back, never coplanar), while the
		# shared centre prevents curved-path sampling from making a pair drift.
		var east_portal := _add_portal(border["east"], x, -PI * 0.5 + bend, "", gate_width, Color(0, 0, 0, 0), gate_height)
		var west_portal := _add_portal(border["west"], x, PI * 0.5 + bend, "", gate_width, Color(0, 0, 0, 0), gate_height)
		var gate_center := east_portal.position
		var path_tangent := Vector3(cos(bend), 0.0, -sin(bend)).normalized()
		var pair_offset := path_tangent * GATE_HALF_GAP * gate_width
		east_portal.position = gate_center - pair_offset
		west_portal.position = gate_center + pair_offset
		if border.has("hover_y"):
			east_portal.position.y = float(border["hover_y"])
			west_portal.position.y = float(border["hover_y"])
	# The Nautilus portal on the seabed, facing west like the water portal.
	var nautilus_portal := _add_portal("water", DemoWorldTerrain.NAUTILUS_PORTAL_X, -PI * 0.5, "nautilus")
	nautilus_portal.position = _terrain.nautilus_portal_point()
	# The Crystal Skates portal, standing on the frozen lake's ice.
	var crystal_portal := _add_portal("ice", DemoWorldTerrain.CRYSTAL_PORTAL_X, -PI * 0.5, "crystal", 1.0, CrystalTrack.CRYSTAL_TINT)
	crystal_portal.position.y = DemoWorldTerrain.ICE_SURFACE_LEVEL
	_add_space_zone()
	# The reusable two-song music system remains available, but playback is
	# intentionally disabled during the current movement/foley testing pass.
	# Re-enable with: add_child(WorldMusic.playlist(MUSIC_PLAYLIST, -10.0))
	# The Ocean Kingdom's Kraken, patrolling the sea's deep middle.
	var kraken := Kraken.new()
	kraken.route_center = _terrain.kraken_route_center()
	kraken.route_radius = DemoWorldTerrain.kraken_route_radius()
	kraken.water_level = DemoWorldTerrain.WATER_LEVEL
	kraken.terrain = _terrain
	add_child(kraken)
	_add_plant_jungle()
	_add_demo_titans()
	call_deferred("_finish_loading")


func _add_space_zone() -> void:
	# Local +Z faces downward after this rotation, so an upward-moving body
	# enters through the one-way face and descending through its back does not
	# replace the Space suit.
	var portal := CheckpointPortal.new()
	portal.name = "Portal_space_ascent"
	portal.element = "space"
	portal.tint_override = SPACE_TINT
	portal.one_way = true
	portal.half_width = 15.0
	portal.half_height = 15.0
	portal.tube_radius = 0.28
	# CheckpointPortal's authored origin is the bottom of its upright opening;
	# once laid flat, offset by half-height so the membrane centre—not its rim—
	# is directly over the volcano mouth.
	portal.position = Vector3(
		DemoWorldTerrain.VOLCANO_CENTER.x, SPACE_PORTAL_Y,
		DemoWorldTerrain.VOLCANO_CENTER.y - portal.half_height
	)
	portal.rotation.x = PI * 0.5
	portal.crossed.connect(_roster.switch_to)
	add_child(portal)

	_spaceship = DemoSpaceship.new()
	_spaceship.name = "ASANSpaceship"
	# West of the ascent portal, so its doorway (on the hull's +X flank) faces
	# back toward whoever rises through it.
	_spaceship.position = Vector3(DemoWorldTerrain.VOLCANO_CENTER.x - 58.0, SPACESHIP_Y, DemoWorldTerrain.VOLCANO_CENTER.y)
	_spaceship.cabin_entered.connect(_on_spaceship_cabin_entered)
	add_child(_spaceship)
	# The pod exists once the ship has built itself, so this follows the add.
	# It rides back down to the ground beside Humongous.
	var landing := DemoWorldTerrain.HUMONGOUS_CLEARING
	_spaceship.escape_pod.landing_point = Vector3(
		landing.x + 22.0,
		_terrain.get_mesh_height(landing.x + 22.0, landing.y + 16.0) + EscapePod.POD_HALF_LENGTH,
		landing.y + 16.0
	)
	_spaceship.escape_pod.impacted.connect(_on_escape_pod_impact)


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
	# Da Hou Zi roams his clearing (see _add_demo_titans()): no trees or rocks
	# for him to walk through.
	var keep_clear: Array[Vector3] = [Vector3(
		DemoWorldTerrain.DA_HOU_ZI_CLEARING.x, DemoWorldTerrain.DA_HOU_ZI_CLEARING.y, DemoWorldTerrain.DA_HOU_ZI_CLEAR_RADIUS
	)]
	jungle.window_keep_clear = keep_clear
	add_child(jungle)


## The demo course includes the established living Dinosaur and Da Hou Zi
## rigs in broad terrain clearings, including Humongous beyond the volcano.
func _add_demo_titans() -> void:
	var dinosaur := DinosaurTitan.new()
	dinosaur.name = "Dinosaur"
	dinosaur.scale = Vector3.ONE * 2.0
	dinosaur.position = _terrain.get_path_point(
		DemoWorldTerrain.DINOSAUR_CLEARING.x,
		DemoWorldTerrain.DINOSAUR_CLEARING.y - DemoWorldTerrain.path_center_z(DemoWorldTerrain.DINOSAUR_CLEARING.x)
	)
	add_child(dinosaur)

	var da_hou_zi := DA_HOU_ZI_SCENE.instantiate() as ApeTemplatePreview
	da_hou_zi.name = "DaHouZi"
	da_hou_zi.fur_color = DA_HOU_ZI_CONFIG.GORILLA_FUR_COLOR
	da_hou_zi.eye_color_override = DA_HOU_ZI_CONFIG.MIND_CONTROL_EYE_COLOR
	da_hou_zi.has_tail = false
	da_hou_zi.body_type = 1.0
	da_hou_zi.display_scale = DA_HOU_ZI_CONFIG.GORILLA_DISPLAY_SCALE
	da_hou_zi.movement_speed_multiplier = DA_HOU_ZI_CONFIG.GORILLA_MOVEMENT_SPEED_MULTIPLIER
	da_hou_zi.gait_speed_multiplier = DA_HOU_ZI_CONFIG.GORILLA_GAIT_SPEED_MULTIPLIER
	da_hou_zi.roam_radius = 30.0
	da_hou_zi.parkour_collision = true
	da_hou_zi.display_name = DA_HOU_ZI_CONFIG.GORILLA_TRUE_NAME
	var da_hou_zi_lines: Array[String] = ["Da Hou Zi watches through a strange purple haze."]
	da_hou_zi.talk_lines = da_hou_zi_lines
	da_hou_zi.position = _terrain.get_path_point(
		DemoWorldTerrain.DA_HOU_ZI_CLEARING.x,
		DemoWorldTerrain.DA_HOU_ZI_CLEARING.y - DemoWorldTerrain.path_center_z(DemoWorldTerrain.DA_HOU_ZI_CLEARING.x)
	)
	add_child(da_hou_zi)

	var humongous_at := DemoWorldTerrain.HUMONGOUS_CLEARING
	HumongousState.spawn_demo_body(
		self,
		Vector3(humongous_at.x, _terrain.get_mesh_height(humongous_at.x, humongous_at.y), humongous_at.y)
	)


## One-way portals: `facing_yaw` turns the portal's face (its local +Z) to
## face the side you approach it from.
func _add_portal(element: String, x: float, facing_yaw: float, suit_key: String = "", width_scale: float = 1.0, tint: Color = Color(0, 0, 0, 0), height_scale: float = -1.0) -> CheckpointPortal:
	var portal := CheckpointPortal.new()
	portal.name = "Portal_%s_%d" % [suit_key if suit_key != "" else (element if element != "" else "normal"), int(x)]
	portal.element = element
	portal.suit_key = suit_key
	portal.tint_override = tint
	portal.one_way = true
	if height_scale < 0.0:
		height_scale = width_scale
	portal.half_width = DemoWorldTerrain.PORTAL_HALF_WIDTH * width_scale
	portal.half_height = DemoWorldTerrain.PORTAL_HALF_HEIGHT * height_scale
	portal.tube_radius = PORTAL_TUBE_RADIUS * width_scale
	portal.position = _terrain.get_path_point(x)
	portal.rotation.y = facing_yaw
	portal.crossed.connect(_roster.switch_to)
	if element == "shiny":
		portal.crossed.connect(_on_shiny_portal_crossed)
	elif element == "plant":
		portal.crossed.connect(_on_plant_portal_crossed)
	elif element == "air":
		# Only the east-facing Ground -> Air membrane recruits Sun Wu Kong.
		# The later Air -> Fire gate's east-facing membrane is Fire, so it cannot
		# accidentally fire this story beat a second time.
		portal.crossed.connect(_on_sky_portal_crossed)
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
## its biome, plus the hero's starting five. Xiao Hou Zi waits at the Plant
## portal; Manchego and Pandy are stationed by the shiny portal.
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
	var space_home := Vector3(DemoWorldTerrain.VOLCANO_CENTER.x, SPACE_PORTAL_Y + 8.0, DemoWorldTerrain.VOLCANO_CENTER.y)
	var space_blorbs := SuitLoadout.spawn_set(self, "space", "Space Helm", space_home, SuitLoadout.FULL_SUIT_SLOTS, 2.2)
	_roster.add_set("space", space_blorbs, SuitLoadout.FULL_SUIT_SLOTS)
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
	_spawn_blorbus_in_spaceship()
	_xiao_hou_zi = XIAO_HOU_ZI_SCENE.instantiate() as XiaoHouZi
	_xiao_hou_zi.in_party = false
	_xiao_hou_zi.auto_join_enabled = false
	_xiao_hou_zi.position = _terrain.get_path_point(DemoWorldTerrain.border_x("plant") + SET_WAIT_OFFSET, -7.0)
	_xiao_hou_zi.rotation.y = -PI * 0.5
	add_child(_xiao_hou_zi)
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
	_spawn_sun_wu_kong_at_sky_portal()


func _spawn_blorbus_in_spaceship() -> void:
	if not is_instance_valid(_spaceship):
		return
	_space_blorbus = BLORB_SCENE.instantiate() as Blorb
	_space_blorbus.blorb_name = "Blorbus"
	_space_blorbus.in_party = false
	_space_blorbus.can_join_party = false
	# Standing on the cabin deck, well inside the pressure threshold and in
	# view of the doorway.
	_space_blorbus.position = _spaceship.to_global(
		Vector3(0.0, DemoSpaceship.DECK_Y + 0.6, 8.0)
	)
	add_child(_space_blorbus)
	_space_blorbus.become_blorbus()
	_space_blorbus.wait_here()


## The pod's arrival. The ground deformation it should punch in waits on the
## terrain collider being split into chunks; for now it announces itself.
func _on_escape_pod_impact(at: Vector3) -> void:
	UISounds.play_foley(&"giant_step", 1.0, get_instance_id())
	print_verbose("Escape pod down at ", at)


func _on_spaceship_cabin_entered() -> void:
	if is_instance_valid(_space_blorbus) and not _space_blorbus.in_party:
		_space_blorbus.rejoin_party()
		Hud.show_message("Blorbus joined the party.")


## Passing through the shiny portal brings the stationed pair into the party.
func _on_shiny_portal_crossed(_element: String) -> void:
	if is_instance_valid(_manchego) and not _manchego.follows_player:
		_manchego.follows_player = true
		_manchego.set_available_to_player(true)
	if is_instance_valid(_pandy):
		_pandy.in_party = true


func _on_plant_portal_crossed(_element: String) -> void:
	if is_instance_valid(_xiao_hou_zi):
		_xiao_hou_zi.in_party = true


## Sun Wu Kong waits visibly in the air just beyond the Ground -> Air portal,
## already carrying the Jingu Bang and standing on his personal Jindouyun.
## The portal crossing, not proximity, is the clean demo-story recruitment.
func _spawn_sun_wu_kong_at_sky_portal() -> void:
	var portal_x := DemoWorldTerrain.CLIFF_EDGE_X + 1.0
	var station := _terrain.get_path_point(portal_x + 13.0, -10.0)
	station.y += 5.0
	_sun_wu_kong = SUN_WU_KONG_SCENE.instantiate() as SunWuKong
	_sun_wu_kong.configure_as_jindouyun_companion(false)
	_sun_wu_kong.position = station
	_sun_wu_kong.rotation.y = -PI * 0.5
	add_child(_sun_wu_kong)


func _on_sky_portal_crossed(_element: String) -> void:
	if is_instance_valid(_sun_wu_kong):
		_sun_wu_kong.join_party()


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
