extends Node

## Orchestrates one portal trip between the outskirts hub and a kingdom scene
## (see portal.gd) -- captures the party roster (see party.gd) right before
## the swap, reuses LoadingScreen's existing boot overlay for the fade, and
## records which gate this trip is bound to so whichever scene loads next
## knows where to place the arriving player (see main.gd's
## _place_returning_player() and kingdom_bootstrap.gd's _finish_arrival()).

## Always names the OUTSKIRTS-side portal a trip is bound to, regardless of
## which direction it's actually travelling -- read once by the destination
## scene's own arrival code, then cleared.
var pending_gate_id: String = ""

const TRANSITION_COVER_DURATION := 0.35


func travel_to(destination_scene: String, gate_id: String) -> void:
	Party.capture_from_tree(get_tree())
	pending_gate_id = gate_id
	LoadingScreen.begin_transition()
	await get_tree().create_timer(TRANSITION_COVER_DURATION).timeout
	get_tree().change_scene_to_file(destination_scene)
