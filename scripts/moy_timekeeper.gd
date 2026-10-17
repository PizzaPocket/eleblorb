extends Node3D

## The two annular, physics-synchronized rings follow local time. The fixed
## bezel stays open for the high line through its centre.
var _clock_poll := 0.0

func _ready() -> void:
	_update_clock()

func _physics_process(delta: float) -> void:
	_clock_poll += delta
	if _clock_poll >= 1.0:
		_clock_poll = fposmod(_clock_poll,1.0)
		_update_clock()

func _update_clock() -> void:
	var now := Time.get_datetime_dict_from_system()
	var hour := fposmod(float(now.hour),12.0)+float(now.minute)/60.0+float(now.second)/3600.0
	var minute := float(now.minute)+float(now.second)/60.0
	var hour_ring := get_node_or_null("Timekeeper_hour") as AnimatableBody3D
	var minute_ring := get_node_or_null("Timekeeper_minute") as AnimatableBody3D
	if hour_ring: hour_ring.rotation.x=hour/12.0*TAU
	if minute_ring: minute_ring.rotation.x=minute/60.0*TAU
	var bead:=get_node_or_null("TimekeeperSecondsBead") as MeshInstance3D
	if bead:
		var seconds:=float(now.second)+float(now.minute)*60.0
		var angle:=fposmod(seconds,60.0)/60.0*TAU
		var radius:=14.1
		bead.position=Vector3(0,cos(angle)*radius,sin(angle)*radius)
