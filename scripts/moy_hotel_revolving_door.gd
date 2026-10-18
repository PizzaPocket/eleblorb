extends AnimatableBody3D

## Slow, four wing hotel entrance door. Baked as a separate moving body.
@export var revolutions_per_minute := 2.0

func _ready() -> void:
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	rotation.y = wrapf(rotation.y + TAU * revolutions_per_minute / 60.0 * delta, 0.0, TAU)
