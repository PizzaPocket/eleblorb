class_name Portal
extends Node3D

## A psychic gateway between the outskirts hub and a kingdom scene --
## conceptually, Blorbus carrying the party's minds through on his own,
## which is why it only opens while he (or the giant he merged into) is the
## one being directly piloted; see player.gd's is_piloting_blorbus() and
## kingdom_travel.gd for the actual scene-swap.
##
## The "Travel" prompt itself has two independent triggers: Interactable's
## own Area3D (below) fires from the trailing human CharacterBody3D walking
## into range, same as any NPC/shop prompt; _update_pilot_proximity() fires
## it directly off whichever body the player is actually piloting (Blorbus,
## or the giant post-merge), since that StaticBody3D doesn't itself trigger
## Interactable's Area3D and the human companion only follows within its own
## 3-7 unit band of Blorbus -- not of the gate -- so relying on the human
## alone left the prompt showing inconsistently right when it mattered most.
##
## Built entirely from SuperEgg parts (project convention -- see
## scripts/superegg.gd) rather than a hand-rolled mesh: two flanking pillars
## and a floating, gently pulsing core.

## Scene path (not a preloaded PackedScene -- kingdom scenes stay unloaded
## until actually entered) this gate leads to.
@export var destination_scene: String = ""
## Always names the OUTSKIRTS-side portal this gate is bound to, whichever
## direction it's placed facing -- see main.gd's _portals_by_gate_id and
## kingdom_bootstrap.gd's return_gate_id.
@export var gate_id: String = ""
@export var accent_color: Color = Color(0.55, 0.7, 0.95)

const INTERACT_RADIUS := 3.0
const PILLAR_HEIGHT := 2.4
const PILLAR_RADIUS := 0.22
const PILLAR_GAP := 1.3
const CORE_RADIUS := 0.34
const PULSE_SPEED := 1.6
const PULSE_AMPLITUDE := 0.25

var _core_material: StandardMaterial3D
var _time := 0.0
var _area: Area3D
var _pilot_in_range := false


func _ready() -> void:
	_build_visual()
	_area = Interactable.attach(self, "Travel", INTERACT_RADIUS, _on_activate)


func _process(delta: float) -> void:
	_time += delta
	if _core_material != null:
		_core_material.emission_energy_multiplier = 1.1 + sin(_time * PULSE_SPEED) * PULSE_AMPLITUDE
	_update_pilot_proximity()


## Keeps the prompt live off Blorbus's (or the giant's) own distance to the
## gate -- see the class doc comment above for why this exists alongside
## Interactable's human-triggered Area3D. enter() is safe to call every
## frame (it just reasserts InteractionManager.current); exit() only fires
## on the falling edge so it doesn't clobber some other prompt that's since
## become current.
func _update_pilot_proximity() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	var controlled: Node3D = player.get_controlled_body() if player != null else null
	var in_range := controlled != null and global_position.distance_to(controlled.global_position) <= INTERACT_RADIUS
	if in_range:
		InteractionManager.enter(_area)
	elif _pilot_in_range:
		InteractionManager.exit(_area)
	_pilot_in_range = in_range


func _on_activate() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or not player.is_piloting_blorbus():
		Hud.show_message("The gate stays still.")
		return
	KingdomTravel.travel_to(destination_scene, gate_id)


func _build_visual() -> void:
	for side in [-1.0, 1.0]:
		var pillar := SuperEgg.build_part(
			Vector3(PILLAR_RADIUS, PILLAR_HEIGHT * 0.5, PILLAR_RADIUS), accent_color.darkened(0.25)
		)
		pillar.position = Vector3(side * PILLAR_GAP, PILLAR_HEIGHT * 0.5, 0.0)
		add_child(pillar)

	var core := SuperEgg.build_part(Vector3(CORE_RADIUS, CORE_RADIUS, CORE_RADIUS), accent_color)
	core.position = Vector3(0.0, PILLAR_HEIGHT * 0.62, 0.0)
	_core_material = core.get_surface_override_material(0)
	_core_material.emission_enabled = true
	_core_material.emission = accent_color
	_core_material.emission_energy_multiplier = 1.2
	add_child(core)
