class_name RockCrag
extends StaticBody3D

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
var _hold_duration: float = HOLD_DURATION
var _support_top_offset: float = 0.0


## Convenience constructor matching this codebase's existing spawn-helper
## convention (e.g. Portal.new()-style direct instancing elsewhere) --
## builds the crag, places it at `world_position` (ground height), and adds
## it to `parent` in one call.
static func spawn(
	parent: Node, world_position: Vector3, rng: RandomNumberGenerator,
	level: int = 1, platform_scale: float = 1.0,
	visual_color: Color = NatureProps.ROCK_COLOR
) -> RockCrag:
	var crag := RockCrag.new()
	crag.collision_layer = 1
	crag.collision_mask = 0
	crag._rest_y = world_position.y
	crag._hold_duration = HOLD_DURATION + minf(float(level - 1) * 0.12, 3.0)
	parent.add_child(crag)
	crag.global_position = Vector3(world_position.x, world_position.y - RockCrag.BURIAL_DEPTH, world_position.z)
	UISounds.play_foley(&"rock_erupt", 0.64, crag.get_instance_id())
	var radius := rng.randf_range(0.55, 0.75) * (1.0 + minf(float(level - 1) * 0.055, 1.2)) * platform_scale
	var visuals := NatureProps.build_rock(radius, false, visual_color)
	crag.add_child(visuals)
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	# NatureProps.build_rock()'s main lobe reaches 1.45 radii high
	# (0.70 centre + 0.75 half-height). Match that visible crown exactly;
	# the former 1.325-radii collider top buried feet inside the rock.
	shape.radius = radius * 0.95
	shape.height = radius * 1.50
	collider.shape = shape
	collider.position.y = radius * 0.70
	crag.add_child(collider)
	crag._support_top_offset = radius*1.45
	crag.add_to_group("power_platforms")
	crag.set_meta("support_radius",radius*0.95)
	return crag


func get_support_top_y() -> float:
	return global_position.y+_support_top_offset


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
			if _elapsed >= _hold_duration:
				_state = State.SINKING
				_elapsed = 0.0
				remove_from_group("power_platforms")
				UISounds.play_foley(&"rock_retract", 0.38, get_instance_id())
		State.SINKING:
			var t := clampf(_elapsed / SINK_DURATION, 0.0, 1.0)
			global_position.y = lerp(_rest_y, _rest_y - BURIAL_DEPTH, ease(t, 1.8))
			if t >= 1.0:
				queue_free()
