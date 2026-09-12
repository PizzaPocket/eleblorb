extends Node

## Continuously synthesized Ocean Kingdom ambience. This deliberately uses
## AudioStreamGenerator rather than a repeating recording: several unrelated
## slow oscillators shape filtered noise into irregular breakers, while a
## separate underwater stream emits stochastic bubbles and water movement.

const SAMPLE_RATE := 44100.0
const WATER_LEVEL := 0.0
const SURFACE_BUS := &"Ocean Surface"
const UNDERWATER_BUS := &"Ocean Underwater"

var _surface_player: AudioStreamPlayer
var _underwater_player: AudioStreamPlayer
var _surface_playback: AudioStreamGeneratorPlayback
var _underwater_playback: AudioStreamGeneratorPlayback
var _surface_filter: AudioEffectLowPassFilter
var _underwater_filter: AudioEffectLowPassFilter
var _rng := RandomNumberGenerator.new()

var _sample_clock := 0.0
var _slow_noise_l := 0.0
var _slow_noise_r := 0.0
var _mid_noise_l := 0.0
var _mid_noise_r := 0.0
var _underwater_noise := 0.0
var _underwater_mix := 0.0
var _bubble_voices: Array[Dictionary] = []


func _ready() -> void:
	_rng.seed = 0x0CEA_4B1E
	_prepare_audio_buses()
	_surface_player = _make_generator_player(SURFACE_BUS)
	_underwater_player = _make_generator_player(UNDERWATER_BUS)
	_surface_player.play()
	_underwater_player.play()
	_surface_playback = _surface_player.get_stream_playback() as AudioStreamGeneratorPlayback
	_underwater_playback = _underwater_player.get_stream_playback() as AudioStreamGeneratorPlayback


func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	var underwater := camera != null and camera.global_position.y < WATER_LEVEL - 0.08
	_underwater_mix = move_toward(_underwater_mix, 1.0 if underwater else 0.0, delta * 1.8)
	# The above-water surf remains physically present below the surface, but
	# loses its air and detail through a smoothly closing low-pass filter.
	_surface_filter.cutoff_hz = lerpf(15500.0, 1050.0, _underwater_mix)
	_surface_player.volume_db = lerpf(-12.5, -19.0, _underwater_mix)
	_underwater_player.volume_db = linear_to_db(maxf(_underwater_mix, 0.001)) - 14.0
	_fill_audio_buffers()


func _prepare_audio_buses() -> void:
	for bus_name in [SURFACE_BUS, UNDERWATER_BUS]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
	var surface_index := AudioServer.get_bus_index(SURFACE_BUS)
	if AudioServer.get_bus_effect_count(surface_index) > 0:
		_surface_filter = AudioServer.get_bus_effect(surface_index, 0) as AudioEffectLowPassFilter
	if _surface_filter == null:
		_surface_filter = AudioEffectLowPassFilter.new()
		AudioServer.add_bus_effect(surface_index, _surface_filter)
	_surface_filter.cutoff_hz = 15500.0
	_surface_filter.resonance = 0.18
	var underwater_index := AudioServer.get_bus_index(UNDERWATER_BUS)
	if AudioServer.get_bus_effect_count(underwater_index) > 0:
		_underwater_filter = AudioServer.get_bus_effect(underwater_index, 0) as AudioEffectLowPassFilter
	if _underwater_filter == null:
		_underwater_filter = AudioEffectLowPassFilter.new()
		_underwater_filter.cutoff_hz = 1850.0
		_underwater_filter.resonance = 0.08
		AudioServer.add_bus_effect(underwater_index, _underwater_filter)


func _make_generator_player(bus_name: StringName) -> AudioStreamPlayer:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.35
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	add_child(player)
	return player


func _fill_audio_buffers() -> void:
	if _surface_playback == null or _underwater_playback == null:
		return
	var frames := mini(
		_surface_playback.get_frames_available(),
		_underwater_playback.get_frames_available()
	)
	for _frame in frames:
		var samples := _next_samples()
		_surface_playback.push_frame(Vector2(samples[0], samples[1]))
		_underwater_playback.push_frame(Vector2(samples[2], samples[3]))


func _next_samples() -> Array[float]:
	var dt := 1.0 / SAMPLE_RATE
	_sample_clock += dt
	var white_l := _rng.randf_range(-1.0, 1.0)
	var white_r := _rng.randf_range(-1.0, 1.0)
	_slow_noise_l = lerpf(_slow_noise_l, white_l, 0.0014)
	_slow_noise_r = lerpf(_slow_noise_r, white_r, 0.0014)
	_mid_noise_l = lerpf(_mid_noise_l, white_l, 0.035)
	_mid_noise_r = lerpf(_mid_noise_r, white_r, 0.035)

	# Incommensurate swells prevent a recognizable repeating period. Squaring
	# the crest produces a gentle rise and a more definite foamy break.
	var swell := (
		0.46
		+ 0.23 * sin(TAU * 0.071 * _sample_clock + 0.4)
		+ 0.17 * sin(TAU * 0.113 * _sample_clock + 2.1)
		+ 0.11 * sin(TAU * 0.037 * _sample_clock + 4.7)
	)
	var crest := pow(clampf(swell, 0.03, 0.98), 2.4)
	var foam_l := white_l - _mid_noise_l
	var foam_r := white_r - _mid_noise_r
	var surface_l := _slow_noise_l * 0.43 + _mid_noise_l * (0.23 + crest * 0.18) + foam_l * crest * 0.065
	var surface_r := _slow_noise_r * 0.43 + _mid_noise_r * (0.23 + crest * 0.18) + foam_r * crest * 0.065

	var movement_noise := (white_l + white_r) * 0.5
	_underwater_noise = lerpf(_underwater_noise, movement_noise, 0.012)
	var water_movement := _underwater_noise * 0.25 + sin(TAU * 58.0 * _sample_clock) * _underwater_noise * 0.025
	if _rng.randf() < 1.65 / SAMPLE_RATE:
		_spawn_bubble()
	var bubbles := _render_bubbles(dt)
	return [surface_l, surface_r, water_movement + bubbles.x, water_movement + bubbles.y]


func _spawn_bubble() -> void:
	if _bubble_voices.size() >= 7:
		return
	var duration := _rng.randf_range(0.085, 0.24)
	_bubble_voices.append({
		"age": 0.0,
		"duration": duration,
		"frequency": _rng.randf_range(220.0, 620.0),
		"phase": _rng.randf_range(0.0, TAU),
		"pan": _rng.randf_range(-0.72, 0.72),
		"gain": _rng.randf_range(0.010, 0.032),
	})


func _render_bubbles(dt: float) -> Vector2:
	var result := Vector2.ZERO
	for index in range(_bubble_voices.size() - 1, -1, -1):
		var bubble: Dictionary = _bubble_voices[index]
		var age: float = float(bubble["age"]) + dt
		var duration: float = float(bubble["duration"])
		if age >= duration:
			_bubble_voices.remove_at(index)
			continue
		bubble["age"] = age
		var progress := age / duration
		var frequency: float = float(bubble["frequency"]) * lerpf(0.88, 1.20, progress)
		var phase: float = float(bubble["phase"]) + TAU * frequency * dt
		bubble["phase"] = phase
		_bubble_voices[index] = bubble
		var envelope := pow(sin(PI * progress), 1.35) * exp(-progress * 1.9)
		var sample := sin(phase) * envelope * float(bubble["gain"])
		var pan: float = float(bubble["pan"])
		result.x += sample * (1.0 - maxf(pan, 0.0))
		result.y += sample * (1.0 + minf(pan, 0.0))
	return result
