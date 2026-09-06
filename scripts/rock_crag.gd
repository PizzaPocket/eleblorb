class_name RockCrag
extends Node3D

## A temporary rock crag: erupts from the ground, holds briefly, sinks back
## down and frees itself. Purely cosmetic -- whoever spawns one (player.gd's
## own rock arm power, or a free-roaming rock blorb's own autonomous attack)
## resolves any damage separately and immediately at the moment of spawning,
## the same way blorb.gd's/player.gd's elemental streams keep their own
## particle visuals (_make_combat_stream()/_make_water_stream()) entirely
## separate from the code that actually calls take_damage(). Modeled on
## skeleton_nme.gd's own RISING/SINKING elapsed-timer + ease()-lerp state
## machine (see that file's _process_rising()/_process_sinking()).

const RISE_DURATION := 0.25
const HOLD_DURATION := 0.9
const SINK_DURATION := 0.3
## How far below its own resting height the crag starts/ends -- deep enough
## that the base of the rock shape is never visible poking out of the
## ground before/after the eruption.
const BURIAL_DEPTH := 1.1

enum State { RISING, HOLDING, SINKING }

var _state: State = State.RISING
var _elapsed: float = 0.0
var _rest_y: float = 0.0


## Convenience constructor matching this codebase's existing spawn-helper
## convention (e.g. Portal.new()-style direct instancing elsewhere) --
## builds the crag, places it at `world_position` (ground height), and adds
## it to `parent` in one call.
static func spawn(parent: Node, world_position: Vector3, rng: RandomNumberGenerator) -> RockCrag:
	var crag := RockCrag.new()
	crag._rest_y = world_position.y
	parent.add_child(crag)
	crag.global_position = Vector3(world_position.x, world_position.y - RockCrag.BURIAL_DEPTH, world_position.z)
	var radius := rng.randf_range(0.55, 0.75)
	var visuals := NatureProps.build_rock(radius, false)
	crag.add_child(visuals)
	return crag


func _process(delta: float) -> void:
	_elapsed += delta
	match _state:
		State.RISING:
			var t := clampf(_elapsed / RISE_DURATION, 0.0, 1.0)
			global_position.y = lerp(_rest_y - BURIAL_DEPTH, _rest_y, ease(t, 0.4))
			if t >= 1.0:
				_state = State.HOLDING
				_elapsed = 0.0
		State.HOLDING:
			if _elapsed >= HOLD_DURATION:
				_state = State.SINKING
				_elapsed = 0.0
		State.SINKING:
			var t := clampf(_elapsed / SINK_DURATION, 0.0, 1.0)
			global_position.y = lerp(_rest_y, _rest_y - BURIAL_DEPTH, ease(t, 1.8))
			if t >= 1.0:
				queue_free()
