extends Node3D

## Shared setup for every kingdom scene reached through an outskirts portal
## (see portal.gd/kingdom_travel.gd). Each kingdom .tscn instances this same
## script with a different kingdom_name/accent_color/return_gate_id, so the
## placeholder interiors stay trivial to keep in sync while their real
## content (city streets, jungle ruins, ocean floor, ...) gets built out
## scene by scene later -- this only guarantees a working arrival: the
## player lands at ReturnPortal and the party roster reassembles behind them.

@export var kingdom_name: String = "Kingdom"
@export var accent_color: Color = Color(0.6, 0.6, 0.9)
## Must match the gate_id the outskirts portal leading here passes to
## KingdomTravel.travel_to() -- see main.gd's _portals_by_gate_id.
@export var return_gate_id: String = ""

@onready var _player: Node3D = $Player
@onready var _return_portal: Node3D = $ReturnPortal


func _ready() -> void:
	_return_portal.destination_scene = "res://scenes/main.tscn"
	_return_portal.gate_id = return_gate_id
	_return_portal.accent_color = accent_color
	call_deferred("_finish_arrival")


func _finish_arrival() -> void:
	await get_tree().process_frame
	_snap_portal_to_ground()
	# Negated from the portal's own basis.z -- see player.gd's own doc
	# comment on camera_rig for why: the player's rotation is never touched
	# here (a first attempt did, and it reversed movement/animation -- see
	# that comment for the full story). Every kingdom's ReturnPortal is
	# unrotated in its own .tscn, so the portal always ended up on the same
	# world side as the fixed camera-in-front-of-face spawn framing,
	# visually blocking it. Negating which side of the portal the player
	# lands on flips the portal to the opposite side instead -- out of the
	# camera's way -- with zero rotation changes anywhere.
	var facing := -_return_portal.global_transform.basis.z
	_player.global_position = _return_portal.global_position - facing * 3.0
	Party.spawn_into(self, _player.global_position, facing)
	KingdomTravel.pending_gate_id = ""
	LoadingScreen.complete()


## Kingdom terrains that aren't a flat placeholder (see
## jungle_kingdom_terrain.gd) undulate, so a ReturnPortal Y baked in the
## .tscn can't be guaranteed to sit exactly on the ground the way it can
## against flat_ground.gd's always-0 height. Skipped over water (is_lake_area
## true at the portal's own XZ) since a floating dock's height is
## deliberately NOT the lake floor's -- see floating_village.gd's own
## get_portal_anchor(), which bakes dock height explicitly instead.
func _snap_portal_to_ground() -> void:
	var terrain := get_node_or_null("Terrain")
	if terrain == null or not terrain.has_method("get_mesh_height"):
		return
	var xz := Vector2(_return_portal.global_position.x, _return_portal.global_position.z)
	if terrain.has_method("is_lake_area") and terrain.is_lake_area(xz):
		return
	_return_portal.global_position.y = terrain.get_mesh_height(xz.x, xz.y)
