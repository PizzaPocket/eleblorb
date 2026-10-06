extends Node

## Sanity-checks the new door/chest/sting streams: length and peak.
func _ready() -> void:
	var checks := {
		"door_open": UISounds._make_door_creak(1), "door_shut": UISounds._make_door_shut(1),
		"chest_open": UISounds._make_chest_open(0), "chest_close": UISounds._make_chest_close(1),
		"special_find": UISounds._make_special_find_sting(),
	}
	for key: String in checks:
		var stream := checks[key] as AudioStreamWAV
		var peak := 0
		var nan_like := 0
		for i in range(0, stream.data.size(), 2):
			var v := stream.data.decode_s16(i)
			peak = maxi(peak, absi(v))
			if v == -32768:
				nan_like += 1
		print("%s: %.2fs peak %.3f clipped %d" % [key, float(stream.data.size() / 2) / 44100.0, float(peak) / 32767.0, nan_like])
	get_tree().quit()
