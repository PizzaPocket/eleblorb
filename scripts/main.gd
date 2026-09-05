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
const CAT_TEMPLATE_PREVIEW_SCENE := "res://scenes/cat_template_preview.tscn"
## Cut from four coat-variant review cats down to just Yogi -- the Primate
## Kingdom's own canonical cat (see docs/world_bible.md's own Creatures/Cats
## entry) -- per direct correction ("leave just one cat on startup for the
## debug and polish, and this cat will be a canonical character named
## Yogi"). Left standing/walking (not resting/sitting) so his ear/sock/tail
## markings are all visible on sight rather than curled out of view.
const DEBUG_SPAWN_CATS_NEAR_PLAYER := true

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
# Inside the volcano's own crater (see terrain_generator.gd's own
# VOLCANO_CENTER), on the level walkable ring around the lava pool rather
# than in the lava itself, up on the crater's inner wall, or out on the
# outer rim -- per direct instruction, "add a warp inside the volcano...
# the portal can be on this level area around the lava." VOLCANO_CENTER
# (300, 450) offset by roughly the level ring's own nominal midpoint radius
# (between get_volcano_lava_radius() ~76 and get_volcano_floor_outer_
# radius() ~99).
const FIRE_GATE_XZ := Vector2(300.0, 363.0)

var _portals_by_gate_id: Dictionary = {}


func _ready() -> void:
	_build_portals()
	call_deferred("_finish_loading")


func _finish_loading() -> void:
	await get_tree().process_frame
	_place_returning_player()
	# Xiao Hou Zi is NOT spawned here -- per direct correction, an earlier
	# pass added a spawn for him in this file without realizing
	# wilderness_scatter.gd already spawns him for real (a proper random
	# point on the jungle plateau, registered with the wilderness LOD system
	# -- see that file's own _spawn_xiao_hou_zi()), which was silently
	# producing two of him. Removed here rather than there since that one is
	# the established, more complete implementation.
	if DEBUG_SPAWN_CATS_NEAR_PLAYER:
		_debug_spawn_cats()
	LoadingScreen.complete()


func _debug_spawn_cats() -> void:
	var packed := load(CAT_TEMPLATE_PREVIEW_SCENE) as PackedScene
	if packed == null:
		return
	var player := get_node("Player")
	var terrain: Node = get_node("Terrain")
	var cat := packed.instantiate() as CatTemplatePreview
	cat.is_yogi = true
	var spawn_pos: Vector3 = player.global_position + Vector3(4.3, 0, -1.2)
	spawn_pos.y = terrain.get_mesh_height(spawn_pos.x, spawn_pos.z)
	# CatTemplatePreview captures its roam center in _ready(), so seed its
	# ordinary local position before it enters the tree.
	cat.position = spawn_pos
	add_child(cat)


func _build_portals() -> void:
	var terrain: Node = get_node("Terrain")
	var city_h: float = terrain.get_mesh_height(CITY_GATE_XZ.x, CITY_GATE_XZ.y)
	var primate_h: float = terrain.get_mesh_height(PRIMATE_GATE_XZ.x, PRIMATE_GATE_XZ.y)
	var fire_h: float = terrain.get_mesh_height(FIRE_GATE_XZ.x, FIRE_GATE_XZ.y)
	_add_portal("city_kingdom", CITY_KINGDOM_SCENE, Vector3(CITY_GATE_XZ.x, city_h, CITY_GATE_XZ.y), Color(0.75, 0.68, 0.42))
	_add_portal("primate_kingdom", PRIMATE_KINGDOM_SCENE, Vector3(PRIMATE_GATE_XZ.x, primate_h, PRIMATE_GATE_XZ.y), Color(0.36, 0.6, 0.32))
	var village: Node = get_node("FloatingWaterVillage")
	_add_portal("ocean_kingdom", OCEAN_KINGDOM_SCENE, village.get_portal_anchor(), Color(0.2, 0.56, 0.66))
	_add_portal("fire_kingdom", FIRE_KINGDOM_SCENE, Vector3(FIRE_GATE_XZ.x, fire_h, FIRE_GATE_XZ.y), Color(0.85, 0.32, 0.08))


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
