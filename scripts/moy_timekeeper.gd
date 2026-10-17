extends Node3D

## Uses the shared game clock (24 game hours per 24 real minutes). The sound
## asset is intentionally a named placeholder until the project gains a bell.
@export var game_clock_path: NodePath
@export var bell_path: NodePath
var _last_hour := -1.0
var _bell_rest_rotation := Vector3.ZERO
var _bell: Node3D
var _strikes_left := 0
var _strike_cooldown := 0.0
var _swing_offset := 0.0

func _ready() -> void:
	_bell = get_node_or_null(bell_path) as Node3D if not bell_path.is_empty() else null
	if _bell: _bell_rest_rotation = _bell.rotation
	_update_clock()

func _process(_delta: float) -> void:
	_update_clock()
	if _bell:
		_strike_cooldown -= _delta
		if _strikes_left > 0 and _strike_cooldown <= 0.0:
			_strikes_left -= 1
			_strike_cooldown = 0.45
			_swing_offset = -0.09 if _swing_offset >= 0.0 else 0.09
		else:
			_swing_offset = move_toward(_swing_offset, 0.0, _delta * 0.32)
		_bell.rotation.z = _bell_rest_rotation.z + _swing_offset

func _update_clock() -> void:
	var hour := float(WorldState.game_time_hours)
	for face in get_children():
		if not face.name.begins_with("ClockFace_"): continue
		for ring_name in ["hour", "minute"]:
			var ring := face.get_node_or_null("CityClock_%s_%s" % [ring_name, face.name.trim_prefix("ClockFace_")]) as Node3D
			if ring == null: continue
			var phase := fposmod(hour, 12.0) / 12.0 if ring_name == "hour" else fposmod(hour, 1.0)
			# Looking outward, both hands move clockwise.
			ring.rotation.z = -phase * TAU
	_ring_bell_if_needed(hour)

func _ring_bell_if_needed(hour: float) -> void:
	if _last_hour < 0.0:
		_last_hour = hour
		return
	var previous_minute := int(floor(_last_hour * 60.0))
	var current_minute := int(floor(hour * 60.0))
	if current_minute < previous_minute:
		previous_minute -= 1440
		current_minute += 1440
	for minute in range(previous_minute + 1, current_minute + 1):
		var day_minute := posmod(minute, 1440)
		if day_minute == 300 or day_minute == 1170:
			_strikes_left = 18
			_strike_cooldown = 0.0
		elif day_minute == 720:
			_strikes_left = 12
			_strike_cooldown = 0.0
	_last_hour = hour
