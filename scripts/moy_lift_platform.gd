extends AnimatableBody3D

## Small public lift platform between street datum and the Moy Deck.
@export var travel_height := 6.5
@export var travel_period := 12.0
@export var base_height := -60.0
@export var stop_levels := PackedFloat32Array()
@export var stop_dwell := 0.8
var _clock := 0.0

func _ready() -> void:
	sync_to_physics = true

func _physics_process(delta: float) -> void:
	if stop_levels.size()>=2:
		_clock=fposmod(_clock+delta,_stop_cycle_duration())
		position.y=base_height+_scheduled_stop_height(_clock)
		return
	_clock=fposmod(_clock+delta,travel_period)
	var u:=_clock/travel_period
	var phase:=u*2.0
	position.y=base_height+travel_height*(phase if phase<=1.0 else 2.0-phase)


func _stop_cycle_duration() -> float:
	var travel_distance:=0.0
	for i in stop_levels.size()-1: travel_distance+=absf(stop_levels[i+1]-stop_levels[i])*2.0
	return travel_period+stop_dwell*float(stop_levels.size()*2-2)


func _scheduled_stop_height(clock: float) -> float:
	var distance:=0.0
	for i in stop_levels.size()-1: distance+=absf(stop_levels[i+1]-stop_levels[i])*2.0
	if distance<=0.001: return stop_levels[0]
	var current_time:=clock
	var waypoints:=PackedFloat32Array()
	for level in stop_levels: waypoints.append(level)
	for i in range(stop_levels.size()-2,0,-1): waypoints.append(stop_levels[i])
	for i in waypoints.size():
		var here:=float(waypoints[i]); var next:=float(waypoints[(i+1)%waypoints.size()])
		if current_time<=stop_dwell: return here
		current_time-=stop_dwell
		var duration:=travel_period*absf(next-here)/distance
		if current_time<=duration: return lerpf(here,next,current_time/maxf(duration,0.001))
		current_time-=duration
	return waypoints[0]
