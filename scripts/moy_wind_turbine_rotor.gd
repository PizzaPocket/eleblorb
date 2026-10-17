extends Node3D

## Animated rotor plane faces the documented prevailing westerly wind.
@export var turns_per_minute := 2.0

func _ready() -> void:
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	rotation.z = fposmod(rotation.z + TAU * turns_per_minute / 60.0 * delta, TAU)
