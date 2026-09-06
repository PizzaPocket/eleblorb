extends Node3D

## Let the persistent loading overlay survive world construction, then give
## the renderer one frame with the completed scene before fading it away.
## Also builds the four kingdom-portal gates (see portal.gd) and, when this
## load is a portal arrival rather than the initial boot (see
## kingdom_travel.gd's pending_gate_id), places the returning player/party
## at the matching gate instead of the scene's baked default spawn.

const CITY_KINGDOM_SCENE := "res://scenes/city_kingdom.tscn"
const PRIMATE_KINGDOM_SCENE := "res://scenes/primate_kingdom.tscn"
const OCEAN_KINGDOM_SCENE := "res://scenes/ocean_kingdom.tscn"
const FIRE_KINGDOM_SCENE := "res://scenes/fire_kingdom.tscn"

# Same CITY_CENTER city_generator.gd defines for itself, pulled out to its
# own southern edge so the gate doesn't land inside a generated building.
const CITY_GATE_XZ := Vector2(-540.0, 95.0)
# Same JUNGLE_PLATEAU_CENTER terrain_generator.gd defines (plateau radius
# 70), pulled toward the plateau's near edge -- the side a player actually
# climbs up from.
const PRIMATE_GATE_XZ := Vector2(-500.0, 409.0)
# The ocean gate has no XZ/ground-height constant of its own -- it stands on
# the fishing village's own small portal dock (see floating_village.gd's
# get_portal_anchor()), so it reads as part of that settlement rather than
# a lone gate out on the shore.
# Inside the volcano's lava pool, on the low basalt outcropping built in
# _build_fire_portal_outcropping(). At 57m from VOLCANO_CENTER this remains
# inside even the organic pool edge's smallest possible radius (~67m),
# rather than relying on the nominal 76m radius alone.
const FIRE_GATE_XZ := Vector2(300.0, 393.0)
const FIRE_GATE_OUTCROPPING_SIZE := Vector3(10.0, 1.2, 8.0)

var _portals_by_gate_id: Dictionary = {}


func _ready() -> void:
	_build_portals()
	call_deferred("_finish_loading")


func _finish_loading() -> void:
	await get_tree().process_frame
	var should_play_opening := (
		KingdomTravel.pending_gate_id == "" and not WorldState.opening_wake_completed
	)
	_place_returning_player()
	if should_play_opening:
		var player := get_node("Player") as Player
		player.begin_wake_intro()
	# Xiao Hou Zi is NOT spawned here -- per direct correction, an earlier
	# pass added a spawn for him in this file without realizing
	# wilderness_scatter.gd already spawns him for real (a proper random
	# point on the jungle plateau, registered with the wilderness LOD system
	# -- see that file's own _spawn_xiao_hou_zi()), which was silently
	# producing two of him. Removed here rather than there since that one is
	# the established, more complete implementation.
	LoadingScreen.complete()


func _build_portals() -> void:
	var terrain: Node = get_node("Terrain")
	var city_h: float = terrain.get_mesh_height(CITY_GATE_XZ.x, CITY_GATE_XZ.y)
	var primate_h: float = terrain.get_mesh_height(PRIMATE_GATE_XZ.x, PRIMATE_GATE_XZ.y)
	var fire_anchor := _build_fire_portal_outcropping(terrain)
	_add_portal("city_kingdom", CITY_KINGDOM_SCENE, Vector3(CITY_GATE_XZ.x, city_h, CITY_GATE_XZ.y), Color(0.75, 0.68, 0.42))
	_add_portal("primate_kingdom", PRIMATE_KINGDOM_SCENE, Vector3(PRIMATE_GATE_XZ.x, primate_h, PRIMATE_GATE_XZ.y), Color(0.36, 0.6, 0.32))
	var village: Node = get_node("FloatingWaterVillage")
	_add_portal("ocean_kingdom", OCEAN_KINGDOM_SCENE, village.get_portal_anchor(), Color(0.2, 0.56, 0.66))
	_add_portal("fire_kingdom", FIRE_KINGDOM_SCENE, fire_anchor, Color(0.85, 0.32, 0.08))


## A broad, low rock slab emerging above the molten surface. Its real box
## collision makes both the player and blorbs safe here through their shared
## "support above lava" rule; the gate and a returning player fit together
## on its flat top without relying on the non-colliding lava mesh.
func _build_fire_portal_outcropping(terrain: Node) -> Vector3:
	var base_y: float = terrain.get_mesh_height(FIRE_GATE_XZ.x, FIRE_GATE_XZ.y)
	var outcropping := NatureProps.build_rock_slab(
		FIRE_GATE_OUTCROPPING_SIZE, NatureProps.ROCK_COLOR.darkened(0.32)
	)
	outcropping.name = "FirePortalOutcropping"
	outcropping.position = Vector3(FIRE_GATE_XZ.x, base_y, FIRE_GATE_XZ.y)
	outcropping.rotation.y = deg_to_rad(7.0)
	add_child(outcropping)
	return Vector3(
		FIRE_GATE_XZ.x,
		base_y + FIRE_GATE_OUTCROPPING_SIZE.y,
		FIRE_GATE_XZ.y
	)


func _add_portal(gate_id: String, destination_scene: String, world_position: Vector3, accent_color: Color) -> void:
	var portal := Portal.new()
	portal.name = "Portal_%s" % gate_id
	portal.destination_scene = destination_scene
	portal.gate_id = gate_id
	portal.accent_color = accent_color
	portal.position = world_position
	add_child(portal)
	_portals_by_gate_id[gate_id] = portal


## Only does anything on a load that followed a kingdom portal trip (see
## kingdom_travel.gd) -- an ordinary boot leaves pending_gate_id empty and
## the scene's own baked Player/Blorb1-3 transforms are used untouched, same
## as before this system existed.
func _place_returning_player() -> void:
	var gate_id := KingdomTravel.pending_gate_id
	KingdomTravel.pending_gate_id = ""
	if gate_id == "" or not _portals_by_gate_id.has(gate_id):
		return
	var portal: Node3D = _portals_by_gate_id[gate_id]
	var player := get_node("Player")
	var facing := portal.global_transform.basis.z
	player.global_position = portal.global_position - facing * 3.0
	Party.spawn_into(self, player.global_position, facing)
