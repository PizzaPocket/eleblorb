extends AnimatableBody3D

## Small public lift platform between street datum and the Moy Deck.
@export var travel_height := 6.5
@export var travel_period := 12.0
@export var base_height := -60.0
var _clock := 0.0

func _ready() -> void:
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	_clock=fposmod(_clock+delta,travel_period)
	var u:=_clock/travel_period
	var phase:=u*2.0
	position.y=base_height+travel_height*(phase if phase<=1.0 else 2.0-phase)
