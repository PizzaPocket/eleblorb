extends Node

## Persists which world-placed unique pickups (gems, one-off shop stock,
## etc.) have already been claimed, independent of any single scene's
## lifetime. A pickup's own local "collected" bool (see gem.gd) is normally
## enough, but portal.gd/kingdom_travel.gd's change_scene_to_file() frees
## and later reloads the outskirts scene on every round trip, which would
## otherwise respawn anything unique. Opt-in via a stable id string set on
## the pickup itself -- "" means "not unique," never checked here.

var _collected_ids: Dictionary = {}


func is_collected(id: String) -> bool:
	return id != "" and _collected_ids.has(id)


func mark_collected(id: String) -> void:
	if id != "":
		_collected_ids[id] = true
