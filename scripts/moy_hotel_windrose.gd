extends Node3D

## The Windrose's exterior light ring turns once per game hour. The room remains faux/solid.
@export var radians_per_second := TAU / 60.0

func _process(delta: float) -> void:
	rotation.y = wrapf(rotation.y + radians_per_second * delta, 0.0, TAU)
