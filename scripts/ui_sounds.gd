extends Node

## Shared synthesized UI feedback: a dry focus tick, a soft two-note
## confirmation, and a low falling response for back/decline.

const SAMPLE_RATE := 44100
const SELECTION_COOLDOWN := 0.035
const POWER_LOOP_HOLD_MSEC := 140
const BLORB_GLIDE_HOLD_MSEC := 150
# Just enough tolerance for an occasional missed physics frame. This is a
# contact signal, not a release envelope: once grounded board pulses cease the
# scrape must disappear with the board/snow contact.
const SNOWBOARD_HOLD_MSEC := 45
const ICE_SKATE_HOLD_MSEC := 45
const FOLEY_POOL_SIZE := 3

var enabled: bool = true
var _selection_player: AudioStreamPlayer
var _action_player: AudioStreamPlayer
var _back_player: AudioStreamPlayer
var _crt_off_player: AudioStreamPlayer
var _crt_on_player: AudioStreamPlayer
var _blorb_bounce_player: AudioStreamPlayer
var _blorb_jump_player: AudioStreamPlayer
var _footstep_left_player: AudioStreamPlayer
var _footstep_right_player: AudioStreamPlayer
var _snow_footstep_left_player: AudioStreamPlayer
var _snow_footstep_right_player: AudioStreamPlayer
var _landing_player: AudioStreamPlayer
var _blorb_body_hit_player: AudioStreamPlayer
var _nme_hit_players: Array[AudioStreamPlayer] = []
var _seed_eject_players: Array[AudioStreamPlayer] = []
var _power_loop_players: Dictionary = {}
var _power_loop_claims: Dictionary = {}
var _fire_playback: AudioStreamGeneratorPlayback
var _fire_rng := RandomNumberGenerator.new()
var _fire_clock := 0.0
var _fire_low_noise := 0.0
var _fire_mid_noise := 0.0
var _fire_fast_noise := 0.0
var _fire_crackle_envelope := 0.0
var _water_playback: AudioStreamGeneratorPlayback
var _water_rng := RandomNumberGenerator.new()
var _water_clock := 0.0
var _water_low_noise := 0.0
var _water_mid_noise := 0.0
var _water_fast_noise := 0.0
var _water_droplets: Array[Dictionary] = []
var _blorb_glide_player: AudioStreamPlayer
var _blorb_glide_playback: AudioStreamGeneratorPlayback
var _blorb_glide_source_id := 0
var _blorb_glide_last_pulse_msec := -10000
var _blorb_glide_rng := RandomNumberGenerator.new()
var _blorb_glide_clock := 0.0
var _blorb_glide_body := 0.0
var _blorb_glide_texture := 0.0
var _snowboard_player: AudioStreamPlayer
var _snowboard_playback: AudioStreamGeneratorPlayback
var _snowboard_source_id := 0
var _snowboard_last_pulse_msec := -10000
var _snowboard_speed_target := 0.0
var _snowboard_speed := 0.0
var _snowboard_carve_target := 0.0
var _snowboard_carve := 0.0
var _snowboard_snow_mix := 1.0
var _snowboard_rng := RandomNumberGenerator.new()
var _snowboard_low_noise := 0.0
var _snowboard_mid_noise := 0.0
var _snowboard_fast_noise := 0.0
var _snowboard_crunch_envelope := 0.0
var _ice_skate_player: AudioStreamPlayer
var _ice_skate_playback: AudioStreamGeneratorPlayback
var _ice_skate_source_id := 0
var _ice_skate_last_pulse_msec := -10000
var _ice_skate_speed := 0.0
var _ice_skate_acceleration := 0.0
var _ice_skate_left_contact := 0.0
var _ice_skate_right_contact := 0.0
var _ice_skate_previous_left_contact := 0.0
var _ice_skate_previous_right_contact := 0.0
var _ice_skate_rng := RandomNumberGenerator.new()
var _ice_skate_slow_noise := 0.0
var _ice_skate_mid_noise := 0.0
var _ice_skate_fast_noise := 0.0
var _ice_skate_left_load_envelope := 0.0
var _ice_skate_right_load_envelope := 0.0
var _ice_skate_recontact_envelope := 0.0
var _foley_pools: Dictionary = {}
var _foley_pool_indices: Dictionary = {}
var _event_last_played: Dictionary = {}
var _last_selection_msec: int = 0
var _nme_hit_index: int = 0
var _seed_eject_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_selection_player = _make_player(_make_tone(0.035, 510.0, 650.0, 0.085), &"UI")
	_action_player = _make_player(_make_tone(0.065, 470.0, 720.0, 0.10), &"UI")
	_back_player = _make_player(_make_tone(0.07, 420.0, 285.0, 0.085), &"UI")
	_crt_off_player = _make_player(_make_crt_transition(false), &"UI")
	_crt_on_player = _make_player(_make_crt_transition(true), &"UI")
	_blorb_bounce_player = _make_player(_make_blorb_squish(false))
	_blorb_jump_player = _make_player(_make_blorb_squish(true))
	_footstep_left_player = _make_player(_make_footstep(false, false))
	_footstep_right_player = _make_player(_make_footstep(true, false))
	_snow_footstep_left_player = _make_player(_make_footstep(false, true))
	_snow_footstep_right_player = _make_player(_make_footstep(true, true))
	_landing_player = _make_player(_make_landing())
	_blorb_body_hit_player = _make_player(_make_body_hit(true, false))
	_nme_hit_players = [
		_make_player(_make_body_hit(false, false)),
		_make_player(_make_body_hit(false, true)),
	]
	_seed_eject_players = [
		_make_player(_make_seed_eject(false)),
		_make_player(_make_seed_eject(true)),
	]
	_water_rng.seed = 0xA73E_5102
	_fire_rng.seed = 0xF1A4_E203
	_blorb_glide_rng.seed = 0xB10B_610D
	_snowboard_rng.seed = 0x5A0B_04D1
	_ice_skate_rng.seed = 0x1CE5_CA7E
	_blorb_glide_player = _make_turbulence_stream_player()
	_snowboard_player = _make_turbulence_stream_player()
	_ice_skate_player = _make_turbulence_stream_player()
	for kind in [&"fire", &"water", &"electric"]:
		_power_loop_players[kind] = _make_turbulence_stream_player() if kind in [&"fire", &"water"] else _make_player(_make_power_loop(kind))
		_power_loop_claims[kind] = {}
	for event_name in [
		&"jump", &"water_wade", &"water_splash", &"npc_step", &"plush_step", &"giant_step", &"npc_paw", &"horse_land",
		&"horse_jump", &"player_hurt", &"blorb_hurt", &"damage_dealt",
		&"blorb_melt", &"blorb_glide", &"giant_move", &"giant_jump", &"giant_land", &"equip_launch", &"equip_settle", &"equip_release",
		&"transform_rise", &"transform_flash", &"transform_reveal", &"pickup",
		&"tokoin_pickup", &"throw_release", &"throw_impact", &"stomp_hit",
		&"rock_erupt", &"rock_retract",
	]:
		_register_foley(event_name, _make_foley(event_name))
	# The reference swipe is a compact 144ms broadband air movement. Weapons
	# use independently synthesized variants rather than three players sharing
	# one identical WAV. Separate inward/outward families mirror the motion's
	# spectral travel while retaining one coherent weapon language.
	# Hoof variants cycle through the pool, so consecutive hooves in a stride
	# never replay one identical waveform. See _make_hoof_step().
	var hoof_steps: Array[AudioStreamWAV] = []
	for variant in HOOF_STEP_VARIANTS:
		hoof_steps.append(_make_hoof_step(variant))
	_register_foley_variants(&"horse_step", hoof_steps)
	_register_foley_variants(&"weapon_swing_outward", [
		_make_weapon_swipe(0, false), _make_weapon_swipe(1, false), _make_weapon_swipe(2, false),
	])
	_register_foley_variants(&"weapon_swing_inward", [
		_make_weapon_swipe(0, true), _make_weapon_swipe(1, true), _make_weapon_swipe(2, true),
	])
	get_tree().node_added.connect(_on_node_added)
	_connect_existing(get_tree().root)


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	_update_blorb_glide(delta, now)
	_update_snowboard_sound(delta,now)
	_update_ice_skate_sound(now)
	for kind in _power_loop_players:
		var claims: Dictionary = _power_loop_claims[kind]
		for source_id in claims.keys():
			if now - int(claims[source_id]) > POWER_LOOP_HOLD_MSEC:
				claims.erase(source_id)
		var player: AudioStreamPlayer = _power_loop_players[kind]
		if enabled and not claims.is_empty():
			var nearest_distance := INF
			var listener_position := _listener_position()
			for source_id in claims.keys():
				var source := instance_from_id(int(source_id)) as Node3D
				if source != null and is_instance_valid(source):
					nearest_distance = minf(nearest_distance, source.global_position.distance_to(listener_position))
			var distance_db := (
				_world_distance_db_for_distance(nearest_distance, 38.0)
				if nearest_distance < INF
				else -42.0
			)
			if not player.playing:
				player.volume_db = -42.0
				player.play()
				if kind == &"water":
					_water_playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
				elif kind == &"fire":
					_fire_playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
			player.volume_db = move_toward(player.volume_db, distance_db, (210.0 if kind == &"water" else 110.0) * delta)
		elif player.playing:
			player.volume_db = move_toward(player.volume_db, -42.0, 140.0 * delta)
			if player.volume_db <= -41.5:
				player.stop()
	if _water_playback != null and (_power_loop_players[&"water"] as AudioStreamPlayer).playing:
		_fill_water_stream()
	if _fire_playback != null and (_power_loop_players[&"fire"] as AudioStreamPlayer).playing:
		_fill_fire_stream()
	if _blorb_glide_playback != null and _blorb_glide_player.playing:
		_fill_blorb_glide_stream()
	if _snowboard_playback != null and _snowboard_player.playing:
		_fill_snowboard_stream()
	if _ice_skate_playback != null and _ice_skate_player.playing:
		_fill_ice_skate_stream()


## Movement calls this every frame rather than retriggering a short sample.
## The hold window converts those pulses into one smoothly gated procedural
## texture with no regular attacks that could be perceived as footsteps.
func pulse_blorb_glide(source_id: int) -> void:
	if not _selected_movement_source(source_id):
		return
	_blorb_glide_source_id = source_id
	_blorb_glide_last_pulse_msec = Time.get_ticks_msec()


func _update_blorb_glide(delta: float, now: int) -> void:
	var active := enabled and now-_blorb_glide_last_pulse_msec<=BLORB_GLIDE_HOLD_MSEC
	if active:
		var target_db := -9.5 + world_distance_db(_blorb_glide_source_id)
		if not _blorb_glide_player.playing:
			_blorb_glide_player.volume_db = -42.0
			_blorb_glide_player.play()
			_blorb_glide_playback = _blorb_glide_player.get_stream_playback() as AudioStreamGeneratorPlayback
		_blorb_glide_player.volume_db = move_toward(_blorb_glide_player.volume_db,target_db,95.0*delta)
	elif _blorb_glide_player.playing:
		_blorb_glide_player.volume_db = move_toward(_blorb_glide_player.volume_db,-42.0,70.0*delta)
		if _blorb_glide_player.volume_db<=-41.5:
			_blorb_glide_player.stop()
			_blorb_glide_playback = null


func _fill_blorb_glide_stream() -> void:
	var frames := _blorb_glide_playback.get_frames_available()
	for _frame in frames:
		var dt := 1.0/float(SAMPLE_RATE)
		_blorb_glide_clock += dt
		var white := _blorb_glide_rng.randf_range(-1.0,1.0)
		_blorb_glide_body = lerpf(_blorb_glide_body,white,0.006)
		_blorb_glide_texture = lerpf(_blorb_glide_texture,white,0.09)
		# Overlapping unrelated drifts keep the soft gel/cloth friction alive
		# without establishing a repeating locomotion beat.
		var movement := 0.86+sin(TAU*0.43*_blorb_glide_clock+0.4)*0.08+sin(TAU*0.71*_blorb_glide_clock+2.1)*0.05
		var sample := (_blorb_glide_body*0.72+(_blorb_glide_texture-_blorb_glide_body)*0.22)*movement*0.24
		_blorb_glide_playback.push_frame(Vector2(sample,sample*0.985))


## Called every grounded board frame. Speed controls loudness and spectral
## brightness; carve measures sideways edge load; snow_mix distinguishes a
## granular snow bed from a smoother ice scrape. Nothing restarts a sample,
## so acceleration and steering remain seamless and never expose a loop.
func pulse_snowboard(source_id: int,speed: float,carve: float,snow_mix: float = 1.0) -> void:
	if not _selected_movement_source(source_id):
		return
	_snowboard_source_id=source_id
	_snowboard_speed_target=maxf(speed,0.0)
	_snowboard_carve_target=clampf(carve,0.0,1.0)
	_snowboard_snow_mix=clampf(snow_mix,0.0,1.0)
	_snowboard_last_pulse_msec=Time.get_ticks_msec()


func _update_snowboard_sound(delta: float,now: int) -> void:
	var active:=enabled and now-_snowboard_last_pulse_msec<=SNOWBOARD_HOLD_MSEC and _snowboard_speed_target>0.18
	# Board velocity is already physically continuous. Mirroring it directly
	# means acceleration from rest naturally raises the sound, while landing
	# from a hop at speed immediately resumes the correct loudness/brightness.
	_snowboard_speed=_snowboard_speed_target
	_snowboard_carve=move_toward(_snowboard_carve,_snowboard_carve_target,5.0*delta)
	if active:
		var speed_mix:=clampf(_snowboard_speed/28.0,0.0,1.0)
		var target_db:=lerpf(-29.0,-8.5,sqrt(speed_mix))+world_distance_db(_snowboard_source_id)
		if not _snowboard_player.playing:
			_snowboard_player.volume_db=target_db
			_snowboard_player.play()
			_snowboard_playback=_snowboard_player.get_stream_playback() as AudioStreamGeneratorPlayback
		_snowboard_player.volume_db=target_db
	elif _snowboard_player.playing:
		_snowboard_player.stop()
		_snowboard_playback=null


func _fill_snowboard_stream() -> void:
	var frames:=_snowboard_playback.get_frames_available()
	var speed_mix:=clampf(_snowboard_speed/28.0,0.0,1.0)
	for _frame in frames:
		var white:=_snowboard_rng.randf_range(-1.0,1.0)
		_snowboard_low_noise=lerpf(_snowboard_low_noise,white,0.0035+speed_mix*0.002)
		_snowboard_mid_noise=lerpf(_snowboard_mid_noise,white,0.035+speed_mix*0.055)
		_snowboard_fast_noise=lerpf(_snowboard_fast_noise,white,0.15+speed_mix*0.24)
		# The reference's core is broadband sliding friction: a soft pressure
		# bed under dry, irregular crystals—not a pitched motor or repeating beat.
		var pressure:=_snowboard_low_noise*0.46
		var scrape:=(_snowboard_mid_noise-_snowboard_low_noise)*(0.62+speed_mix*0.34)
		var spray:=(_snowboard_fast_noise-_snowboard_mid_noise)*(0.10+speed_mix*0.17)
		var crunch_rate:=4.0+(18.0*speed_mix+24.0*_snowboard_carve)*_snowboard_snow_mix
		if _snowboard_rng.randf()<crunch_rate/float(SAMPLE_RATE):
			_snowboard_crunch_envelope=maxf(
				_snowboard_crunch_envelope,
				_snowboard_rng.randf_range(0.08,0.22)*(0.45+0.55*_snowboard_carve)
			)
		_snowboard_crunch_envelope*=0.9962
		var crystals:=(_snowboard_fast_noise-_snowboard_low_noise)*_snowboard_crunch_envelope
		var ice_sheen:=(_snowboard_fast_noise-_snowboard_mid_noise)*(1.0-_snowboard_snow_mix)*0.12
		var sample:=(pressure+scrape+spray+crystals+ice_sheen)*(0.035+speed_mix*0.075)
		_snowboard_playback.push_frame(Vector2(sample,sample*0.985))


## Contact-driven skate foley. Speed controls the continuous blade friction,
## acceleration adds pressure/grit, and the live animation contacts create
## alternating load accents without replaying a fixed clip.
func pulse_ice_skates(
	source_id: int,speed: float,acceleration: float,
	left_contact: float,right_contact: float
) -> void:
	if not _selected_movement_source(source_id):
		return
	var now:=Time.get_ticks_msec()
	if now-_ice_skate_last_pulse_msec>ICE_SKATE_HOLD_MSEC*2 and speed>1.0:
		# Landing/re-contact at speed starts at the current physical intensity.
		_ice_skate_recontact_envelope=clampf(speed/18.0,0.0,1.0)
	_ice_skate_source_id=source_id
	_ice_skate_speed=maxf(speed,0.0)
	_ice_skate_acceleration=clampf(acceleration,0.0,18.0)
	_ice_skate_left_contact=clampf(left_contact,0.0,1.0)
	_ice_skate_right_contact=clampf(right_contact,0.0,1.0)
	if _ice_skate_left_contact>0.62 and _ice_skate_previous_left_contact<=0.62:
		_ice_skate_left_load_envelope=0.32+0.28*clampf(acceleration/10.0,0.0,1.0)
	if _ice_skate_right_contact>0.62 and _ice_skate_previous_right_contact<=0.62:
		_ice_skate_right_load_envelope=0.32+0.28*clampf(acceleration/10.0,0.0,1.0)
	_ice_skate_previous_left_contact=_ice_skate_left_contact
	_ice_skate_previous_right_contact=_ice_skate_right_contact
	_ice_skate_last_pulse_msec=now


func _update_ice_skate_sound(now: int) -> void:
	var active:=enabled and now-_ice_skate_last_pulse_msec<=ICE_SKATE_HOLD_MSEC and _ice_skate_speed>0.16
	if active:
		var speed_mix:=clampf(_ice_skate_speed/30.0,0.0,1.0)
		var target_db:=lerpf(-31.0,-9.0,sqrt(speed_mix))+world_distance_db(_ice_skate_source_id)
		if not _ice_skate_player.playing:
			_ice_skate_player.volume_db=target_db
			_ice_skate_player.play()
			_ice_skate_playback=_ice_skate_player.get_stream_playback() as AudioStreamGeneratorPlayback
		_ice_skate_player.volume_db=target_db
	elif _ice_skate_player.playing:
		_ice_skate_player.stop()
		_ice_skate_playback=null
		_ice_skate_previous_left_contact=0.0
		_ice_skate_previous_right_contact=0.0


func _fill_ice_skate_stream() -> void:
	var frames:=_ice_skate_playback.get_frames_available()
	var speed_mix:=clampf(_ice_skate_speed/30.0,0.0,1.0)
	var thrust_mix:=clampf(_ice_skate_acceleration/10.0,0.0,1.0)
	var contact_mix:=clampf((_ice_skate_left_contact+_ice_skate_right_contact)*0.62,0.0,1.0)
	for _frame in frames:
		var white:=_ice_skate_rng.randf_range(-1.0,1.0)
		_ice_skate_slow_noise=lerpf(_ice_skate_slow_noise,white,0.018+speed_mix*0.012)
		_ice_skate_mid_noise=lerpf(_ice_skate_mid_noise,white,0.12+speed_mix*0.16)
		_ice_skate_fast_noise=lerpf(_ice_skate_fast_noise,white,0.48+speed_mix*0.28)
		# Thin steel pressure and bright ice crystals: substantially less low
		# body than the snowboard's broad snow friction.
		var steel_scrape:=(_ice_skate_mid_noise-_ice_skate_slow_noise)*(0.54+0.32*speed_mix)
		var ice_hiss:=(_ice_skate_fast_noise-_ice_skate_mid_noise)*(0.18+0.28*speed_mix)
		var chatter_rate:=5.0+34.0*speed_mix+42.0*thrust_mix
		if _ice_skate_rng.randf()<chatter_rate/float(SAMPLE_RATE):
			var accent:=_ice_skate_rng.randf_range(0.08,0.22)*(0.55+0.45*contact_mix)
			if _ice_skate_left_contact>=_ice_skate_right_contact:
				_ice_skate_left_load_envelope=maxf(_ice_skate_left_load_envelope,accent)
			else:
				_ice_skate_right_load_envelope=maxf(_ice_skate_right_load_envelope,accent)
		_ice_skate_left_load_envelope*=0.9960
		_ice_skate_right_load_envelope*=0.9956
		_ice_skate_recontact_envelope*=0.9945
		var left_grit:=(_ice_skate_fast_noise-_ice_skate_slow_noise)*_ice_skate_left_load_envelope*_ice_skate_left_contact
		var right_grit:=(_ice_skate_fast_noise-_ice_skate_slow_noise)*_ice_skate_right_load_envelope*_ice_skate_right_contact
		var landing_cut:=(_ice_skate_mid_noise-_ice_skate_slow_noise)*_ice_skate_recontact_envelope
		var amplitude:=(0.025+0.075*speed_mix)*contact_mix
		var sample:=(steel_scrape+ice_hiss+left_grit+right_grit+landing_cut)*amplitude
		_ice_skate_playback.push_frame(Vector2(sample*0.985,sample))


func _input(event: InputEvent) -> void:
	if enabled and event.is_action_pressed("ui_cancel") and not event.is_echo():
		# Pause and Inventory own a stronger CRT resume transition when Back
		# closes them; don't stack the ordinary decline tone underneath it.
		var pause_open: bool = PauseMenu.has_method("is_open") and PauseMenu.is_open()
		var inventory_open: bool = InventoryUI.has_method("is_open") and InventoryUI.is_open()
		if not pause_open and not inventory_open:
			play_back()


func _ensure_audio_buses() -> void:
	for bus_name in [&"Foley", &"UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)


func _make_player(stream: AudioStreamWAV, bus_name: StringName = &"Foley") -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus_name
	add_child(player)
	return player


func _make_turbulence_stream_player() -> AudioStreamPlayer:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.28
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"Foley"
	add_child(player)
	return player


func _fill_fire_stream() -> void:
	var frames := _fire_playback.get_frames_available()
	for _frame in frames:
		var sample := _next_fire_sample()
		_fire_playback.push_frame(Vector2(sample, sample * 0.99))


func _next_fire_sample() -> float:
	var dt := 1.0 / float(SAMPLE_RATE)
	_fire_clock += dt
	var white := _fire_rng.randf_range(-1.0, 1.0)
	# The reference is an unpitched sheet of turbulent combustion: a warm,
	# low-mid pressure body, a broad tearing roar, and restrained high hiss.
	# Differently responsive noise filters create those bands without the
	# stable sine partials that made the former version sound mechanical.
	_fire_low_noise = lerpf(_fire_low_noise, white, 0.0035)
	_fire_mid_noise = lerpf(_fire_mid_noise, white, 0.032)
	_fire_fast_noise = lerpf(_fire_fast_noise, white, 0.19)
	var pressure_body := _fire_low_noise * 0.72
	var turbulent_roar := (_fire_mid_noise - _fire_low_noise) * 1.05
	var flame_hiss := (_fire_fast_noise - _fire_mid_noise) * 0.20
	# Slow non-repeating pressure drift makes the stream breathe naturally.
	var pressure := 0.94 + _fire_low_noise * 0.16 + sin(TAU * 0.41 * _fire_clock) * 0.025
	# Tiny stochastic pops are embedded in the roar, never exposed as sharp
	# clicks. Their exponentially decaying envelope keeps the result plush.
	if _fire_rng.randf() < 13.0 / float(SAMPLE_RATE):
		_fire_crackle_envelope = maxf(_fire_crackle_envelope, _fire_rng.randf_range(0.06, 0.16))
	_fire_crackle_envelope *= 0.9972
	var crackle := (_fire_fast_noise - _fire_low_noise) * _fire_crackle_envelope
	return (pressure_body + turbulent_roar + flame_hiss + crackle) * pressure * 0.105


func _fill_water_stream() -> void:
	var frames := _water_playback.get_frames_available()
	for _frame in frames:
		var sample := _next_water_sample()
		_water_playback.push_frame(Vector2(sample, sample * 0.985))


func _next_water_sample() -> float:
	var dt := 1.0 / float(SAMPLE_RATE)
	_water_clock += dt
	var white := _water_rng.randf_range(-1.0, 1.0)
	# Three differently responsive random layers form actual broadband
	# turbulence instead of the former bank of stable sine frequencies.
	_water_low_noise = lerpf(_water_low_noise, white, 0.012)
	_water_mid_noise = lerpf(_water_mid_noise, white, 0.075)
	_water_fast_noise = lerpf(_water_fast_noise, white, 0.32)
	var body := _water_low_noise * 0.42
	var nozzle_rush := (_water_mid_noise - _water_low_noise) * 0.82
	var fine_spray := (_water_fast_noise - _water_mid_noise) * 0.24
	# Slow, unrelated pressure movements avoid a recognizable pumping loop.
	var pressure := 0.90 + sin(TAU * 0.37 * _water_clock + 0.7) * 0.055 + sin(TAU * 0.83 * _water_clock + 2.4) * 0.025
	if _water_rng.randf() < 8.0 / float(SAMPLE_RATE):
		_water_droplets.append({"age": 0.0, "duration": _water_rng.randf_range(0.018, 0.065), "gain": _water_rng.randf_range(0.025, 0.07)})
	var droplets := 0.0
	for index in range(_water_droplets.size() - 1, -1, -1):
		var droplet: Dictionary = _water_droplets[index]
		var age: float = float(droplet["age"]) + dt
		var duration: float = float(droplet["duration"])
		if age >= duration:
			_water_droplets.remove_at(index)
			continue
		droplet["age"] = age
		_water_droplets[index] = droplet
		var progress := age / duration
		droplets += white * pow(1.0 - progress, 2.4) * float(droplet["gain"])
	return (body + nozzle_rush + fine_spray) * pressure * 0.085 + droplets


func _register_foley(event_name: StringName, stream: AudioStreamWAV) -> void:
	var pool: Array[AudioStreamPlayer] = []
	for i in FOLEY_POOL_SIZE:
		pool.append(_make_player(stream))
	_foley_pools[event_name] = pool
	_foley_pool_indices[event_name] = 0


func _register_foley_variants(event_name: StringName, streams: Array[AudioStreamWAV]) -> void:
	var pool: Array[AudioStreamPlayer] = []
	for stream in streams:
		pool.append(_make_player(stream))
	_foley_pools[event_name] = pool
	_foley_pool_indices[event_name] = 0


## One scalable gameplay-facing entry point. Event names select a catalogue
## entry; callers supply only expressive intensity. Pools preserve close
## overlaps (four hooves, rapid pickups, combat) without unlimited voices.
func play_foley(event_name: StringName, intensity: float = 0.5, source_id: int = 0) -> void:
	if not enabled or not _foley_pools.has(event_name):
		return
	# Movement Foley is the embodied perspective of the selected character,
	# not ordinary world ambience. Followers and unselected party members may
	# still animate, but their steps/glides/landings remain silent. Kova's
	# authored giant_step is deliberately absent: his landmark-scale impacts
	# are environmental sound and remain audible independently.
	if event_name in [
		&"jump", &"npc_step", &"plush_step", &"npc_paw",
		&"horse_step", &"horse_jump", &"horse_land",
		&"blorb_glide", &"giant_move", &"giant_jump", &"giant_land",
	] and not _selected_movement_source(source_id):
		return
	var cooldown_key := "%s:%d" % [event_name, source_id]
	var now := Time.get_ticks_msec()
	var cooldown := 70 if event_name in [&"player_hurt", &"blorb_hurt", &"damage_dealt"] else (720 if event_name == &"giant_move" else (260 if event_name == &"blorb_glide" else 0))
	if cooldown > 0 and now - int(_event_last_played.get(cooldown_key, -10000)) < cooldown:
		return
	_event_last_played[cooldown_key] = now
	var pool: Array = _foley_pools[event_name]
	var index: int = int(_foley_pool_indices[event_name])
	var player := pool[index] as AudioStreamPlayer
	_foley_pool_indices[event_name] = (index + 1) % pool.size()
	var distance_attenuation_db := 0.0
	if source_id != 0:
		var source := instance_from_id(source_id) as Node3D
		if source != null:
			var distance := source.global_position.distance_to(_listener_position())
			# Landmark bodies are meant to be perceived at landmark scale. Their
			# deep, sparse contacts carry farther than ordinary local foley.
			var max_distance := 82.0 if event_name in [&"giant_step", &"giant_move", &"giant_jump", &"giant_land"] else 28.0
			if distance >= max_distance:
				return
			distance_attenuation_db = _world_distance_db_for_distance(distance, max_distance)
	var fixed_twinkle := event_name in [&"tokoin_pickup", &"transform_reveal"]
	# Musical confirmation cues must retain their authored intervals. Random
	# transposition made identical Tokoins sound like different denominations
	# and could push their two-note relationship into a sour interval.
	player.pitch_scale = 1.0 if fixed_twinkle else randf_range(0.965, 1.035)
	var level_variation := 0.0 if fixed_twinkle else randf_range(-0.7, 0.0)
	player.volume_db = lerpf(-5.5, -0.7, clampf(intensity, 0.0, 1.0)) + level_variation + distance_attenuation_db
	player.play()


func _listener_position() -> Vector3:
	# Perceived distance belongs to the listener/camera, not necessarily the
	# controlled player body (over-the-shoulder framing, possession, mounts,
	# and cinematic cameras can all separate the two).
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		return camera.global_position
	var fallback := get_tree().get_first_node_in_group("player") as Node3D
	return fallback.global_position if fallback != null else Vector3.ZERO


func world_distance_db(source_id: int, max_distance: float = 28.0) -> float:
	if source_id == 0:
		return 0.0
	var source := instance_from_id(source_id) as Node3D
	if source == null or not is_instance_valid(source):
		return -42.0
	return _world_distance_db_for_distance(
		source.global_position.distance_to(_listener_position()), max_distance
	)


func _world_distance_db_for_distance(distance: float, max_distance: float) -> float:
	if distance >= max_distance:
		return -42.0
	return -24.0 * smoothstep(3.0, max_distance, distance)


func _make_tone(duration: float, start_hz: float, end_hz: float, amplitude: float) -> AudioStreamWAV:
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase: float = 0.0
	for frame in frame_count:
		var t: float = float(frame) / float(maxi(frame_count - 1, 1))
		var frequency: float = lerpf(start_hz, end_hz, t)
		phase += TAU * frequency / float(SAMPLE_RATE)
		var envelope: float = pow(1.0 - t, 2.4) * minf(t / 0.08, 1.0)
		var sample: int = clampi(int(sin(phase) * envelope * amplitude * 32767.0), -32768, 32767)
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _make_crt_transition(turning_on: bool) -> AudioStreamWAV:
	var duration: float = 0.22 if turning_on else 0.18
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase: float = 0.0
	for frame in frame_count:
		var t: float = float(frame) / float(maxi(frame_count - 1, 1))
		var shaped: float = t * t if turning_on else sqrt(t)
		var frequency: float = lerpf(95.0, 1250.0, shaped) if turning_on else lerpf(1100.0, 70.0, shaped)
		phase += TAU * frequency / float(SAMPLE_RATE)
		var edge: float = sin(phase) * 0.62 + sin(phase * 0.503) * 0.18
		var static_noise: float = sin(float(frame * 7919 % 104729)) * 0.035
		var envelope: float = (sin(PI * t) if turning_on else pow(1.0 - t, 0.65))
		var thump: float = sin(TAU * 58.0 * float(frame) / float(SAMPLE_RATE)) * pow(t, 10.0) if not turning_on else 0.0
		# Pause is a state cue, not a dramatic effect. Keep the CRT identity
		# audible while seating it beneath ordinary gameplay foley.
		var sample: int = clampi(int((edge + static_noise + thump * 0.42) * envelope * 0.037 * 32767.0), -32768, 32767)
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _make_blorb_squish(strong: bool) -> AudioStreamWAV:
	var duration: float = 0.155 if strong else 0.105
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase: float = 0.0
	for frame in frame_count:
		var t: float = float(frame) / float(maxi(frame_count - 1, 1))
		# A low rounded pitch scoop supplies the elastic "boip". The faint
		# inharmonic layer is most audible at impact and quickly disappears,
		# suggesting wet compression without reading as static or a splat.
		var start_hz: float = 138.0 if strong else 166.0
		var end_hz: float = 264.0 if strong else 310.0
		var frequency: float = lerpf(start_hz, end_hz, smoothstep(0.0, 1.0, t))
		phase += TAU * frequency / float(SAMPLE_RATE)
		var attack: float = minf(t / 0.045, 1.0)
		var envelope: float = attack * pow(1.0 - t, 2.15)
		var body: float = sin(phase) * 0.82 + sin(phase * 1.47) * 0.12 * (1.0 - t)
		var compression: float = sin(phase * 1.91) * 0.08 * pow(1.0 - t, 4.0)
		var amplitude: float = 0.105 if strong else 0.078
		var sample: int = clampi(int((body + compression) * envelope * amplitude * 32767.0), -32768, 32767)
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _make_footstep(right_foot: bool, snow: bool) -> AudioStreamWAV:
	# Ground contact is granular and aperiodic. Fixed oscillators made the old
	# version read as a digital drum; filtered deterministic noise instead gives
	# dirt its compact heel/sole compression and snow its longer dry crunch.
	var duration := 0.16 if snow else 0.115
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var noise_seed: int = 0x2457A1 + (0x193D if right_foot else 0) + (0x562B if snow else 0)
	var low_noise := 0.0
	var mid_noise := 0.0
	var softened_contact := 0.0
	for frame in frame_count:
		var seconds := float(frame) / float(SAMPLE_RATE)
		noise_seed = int((noise_seed * 1103515245 + 12345) & 0x7fffffff)
		var raw_noise := float(noise_seed) / 1073741824.0 - 1.0
		low_noise = lerpf(low_noise, raw_noise, 0.022 if snow else 0.035)
		mid_noise = lerpf(mid_noise, raw_noise, 0.10 if snow else 0.075)
		var heel_envelope := minf(seconds / 0.008, 1.0) * exp(-seconds * (31.0 if snow else 42.0))
		var toe_delay := (0.043 if right_foot else 0.047) if snow else (0.030 if right_foot else 0.034)
		var toe_time := maxf(seconds - toe_delay, 0.0)
		var toe_envelope := (
			minf(toe_time / 0.007, 1.0) * exp(-toe_time * (40.0 if snow else 58.0))
			if seconds >= toe_delay else 0.0
		)
		var grit := raw_noise - mid_noise
		var compression := mid_noise - low_noise
		var contact: float
		if snow:
			# Broad granular compression followed by a smaller boot release. Sparse
			# grains keep the crunch detailed without becoming a hiss.
			var grain_gate := 1.0 if noise_seed % 29 < 5 else 0.18
			contact = (compression * 0.68 + grit * 0.12 * grain_gate) * heel_envelope
			contact += (compression * 0.44 + grit * 0.08) * toe_envelope
		else:
			# Dirt is shorter and warmer: packed-earth pressure in the low-mid band
			# plus a restrained sandy scrape, with no stable pitch.
			contact = (low_noise * 0.55 + compression * 0.54 + grit * 0.025) * heel_envelope
			contact += (compression * 0.42 + grit * 0.02) * toe_envelope
		# Final low-pass removes the hard single-sample edges that read as static.
		softened_contact=lerpf(softened_contact,contact,0.18 if snow else 0.11)
		var gain := 0.20 if snow else 0.18
		var sample: int = clampi(int(softened_contact * gain * 32767.0), -32768, 32767)
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _make_landing() -> AudioStreamWAV:
	var duration := 0.12
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase := 0.0
	for frame in frame_count:
		var t := float(frame) / float(maxi(frame_count - 1, 1))
		phase += TAU * lerpf(184.0, 88.0, t) / float(SAMPLE_RATE)
		var envelope := minf(t / 0.018, 1.0) * pow(1.0 - t, 3.5)
		# A rounded two-foot weight cue, deliberately without a sharp click;
		# the landing pose supplies the visual impact while this supplies mass.
		var body := sin(phase) * 0.86 + sin(phase * 1.71) * 0.10
		bytes.encode_s16(frame * 2, clampi(int(body * envelope * 0.082 * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream


func _make_body_hit(blorb_hit: bool, alternate: bool) -> AudioStreamWAV:
	var duration := 0.105 if blorb_hit else 0.075
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase := 0.0
	for frame in frame_count:
		var t := float(frame) / float(maxi(frame_count - 1, 1))
		var start_hz := 192.0 if blorb_hit else (246.0 if alternate else 228.0)
		var end_hz := 104.0 if blorb_hit else (132.0 if alternate else 121.0)
		phase += TAU * lerpf(start_hz, end_hz, t) / float(SAMPLE_RATE)
		var envelope := minf(t / 0.025, 1.0) * pow(1.0 - t, 3.0)
		var body := sin(phase) * 0.82 + sin(phase * (1.63 if blorb_hit else 2.12)) * 0.12
		var amplitude := 0.105 if blorb_hit else 0.075
		bytes.encode_s16(frame * 2, clampi(int(body * envelope * amplitude * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream


func _make_seed_eject(alternate: bool) -> AudioStreamWAV:
	var duration := 0.085
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase := 0.0
	for frame in frame_count:
		var t := float(frame) / float(maxi(frame_count - 1, 1))
		phase += TAU * lerpf(190.0 if alternate else 178.0, 76.0, t) / float(SAMPLE_RATE)
		var envelope := minf(t / 0.018, 1.0) * pow(1.0 - t, 4.2)
		var pipe := sin(phase) * 0.76 + sin(phase * 0.49) * 0.22
		bytes.encode_s16(frame * 2, clampi(int(pipe * envelope * 0.075 * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream


func _make_power_loop(kind: StringName) -> AudioStreamWAV:
	# Every component below completes an integer number of cycles across the
	# buffer. The last sample therefore flows directly into sample zero with
	# no random-state discontinuity or fade pulse at the loop boundary.
	var duration := 1.0
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in frame_count:
		var t := float(frame) / float(frame_count)
		var sample_value := 0.0
		match kind:
			&"fire":
				# A broad gas roar built from periodic midrange bands. No dominant
				# sub-bass oscillator: it should read as flame, not an engine.
				sample_value = sin(TAU * 173.0 * t) * 0.30 + sin(TAU * 239.0 * t) * 0.25 + sin(TAU * 347.0 * t) * 0.19 + sin(TAU * 521.0 * t) * 0.12
			&"water":
				# A pressurized water jet is broadband turbulent flow, not a pitched
				# chord. Build a dense, deterministic spectrum of integer-cycle bins:
				# randomized phases stop them summing as a recognizable note, while
				# integer frequencies keep every component perfectly seamless across
				# this one-second loop. Midrange energy supplies the hose/nozzle rush;
				# the lighter upper band supplies fine spray and aerated droplets.
				var turbulent_rush := 0.0
				for band in 36:
					var band_t := float(band) / 35.0
					var frequency := roundi(170.0 * pow(28.0, band_t))
					var phase_offset := fmod(float((band + 3) * (band + 11) * 1.731), TAU)
					var spectral_weight := lerpf(1.0, 0.32, band_t)
					turbulent_rush += sin(TAU * float(frequency) * t + phase_offset) * spectral_weight
				turbulent_rush /= 9.5
				# Slow pressure variation and two soft, non-tonal eddy pulses keep the
				# stream alive without the conspicuous pumping of a short sound loop.
				var pressure := 0.91 + sin(TAU * 3.0 * t + 0.7) * 0.045 + sin(TAU * 7.0 * t + 2.1) * 0.025
				var eddies := sin(TAU * 89.0 * t + 1.4) * 0.055 + sin(TAU * 137.0 * t + 4.2) * 0.04
				sample_value = turbulent_rush * pressure + eddies
			_:
				# Electric arcs read as irregular, impulsive broadband crackles. A
				# circular-distance envelope makes the deliberately uneven burst
				# pattern seamless at the loop boundary, while a dense carrier avoids
				# the old pitched buzz. The low-mid knock gives each larger discharge
				# a satisfying zap body without turning it into harsh static.
				var crackle_carrier := 0.0
				for band in 18:
					var frequency := 620 + band * 347
					var phase_offset := fmod(float((band + 5) * (band + 17)) * 1.193, TAU)
					crackle_carrier += sin(TAU * float(frequency) * t + phase_offset)
				crackle_carrier /= 6.5
				var burst_envelope := 0.0
				for center in [0.025, 0.083, 0.176, 0.294, 0.337, 0.508, 0.672, 0.731, 0.884, 0.963]:
					var direct_distance := absf(t - float(center))
					var circular_distance := minf(direct_distance, 1.0 - direct_distance)
					burst_envelope += exp(-circular_distance * 92.0)
				burst_envelope = minf(burst_envelope, 1.25)
				var arc_body := sin(TAU * 193.0 * t + 0.4) * burst_envelope * 0.16
				var live_hiss := crackle_carrier * 0.075
				sample_value = crackle_carrier * burst_envelope * 0.78 + arc_body + live_hiss
		var amplitude := 0.052 if kind == &"fire" else (0.047 if kind == &"water" else 0.043)
		bytes.encode_s16(frame * 2, clampi(int(sample_value * amplitude * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = frame_count
	return stream


## Compact procedural stand-ins sharing a rounded, cloth-and-gel palette.
## The catalogue boundary above is intentional: authored recordings can
## replace these streams later without changing any gameplay event calls.
func _make_foley(kind: StringName) -> AudioStreamWAV:
	var duration := 0.12
	var start_hz := 150.0
	var end_hz := 72.0
	var texture := 0.08
	match kind:
		&"jump": duration = 0.11; start_hz = 92.0; end_hz = 210.0; texture = 0.04
		&"water_wade": duration = 0.22; start_hz = 118.0; end_hz = 64.0; texture = 0.26
		&"water_splash": duration = 0.38; start_hz = 145.0; end_hz = 52.0; texture = 0.34
		&"npc_step": duration = 0.065; start_hz = 116.0; end_hz = 64.0; texture = 0.09
		&"plush_step": duration = 0.052; start_hz = 142.0; end_hz = 82.0; texture = 0.035
		&"giant_step": duration = 0.32; start_hz = 54.0; end_hz = 27.0; texture = 0.11
		&"npc_paw": duration = 0.045; start_hz = 152.0; end_hz = 91.0; texture = 0.04
		&"horse_land": duration = 0.18; start_hz = 146.0; end_hz = 72.0; texture = 0.12
		&"horse_jump": duration = 0.14; start_hz = 132.0; end_hz = 248.0; texture = 0.06
		&"player_hurt": duration = 0.13; start_hz = 248.0; end_hz = 118.0; texture = 0.14
		&"blorb_hurt": duration = 0.15; start_hz = 286.0; end_hz = 142.0; texture = 0.05
		&"damage_dealt": duration = 0.075; start_hz = 292.0; end_hz = 156.0; texture = 0.10
		&"blorb_melt": duration = 0.42; start_hz = 244.0; end_hz = 82.0; texture = 0.20
		&"blorb_glide": duration = 0.09; start_hz = 218.0; end_hz = 142.0; texture = 0.04
		&"giant_move": duration = 0.48; start_hz = 47.0; end_hz = 34.0; texture = 0.08
		&"giant_jump": duration = 0.42; start_hz = 38.0; end_hz = 78.0; texture = 0.09
		&"giant_land": duration = 0.58; start_hz = 49.0; end_hz = 22.0; texture = 0.13
		&"equip_launch": duration = 0.15; start_hz = 108.0; end_hz = 224.0; texture = 0.05
		&"equip_settle": duration = 0.13; start_hz = 190.0; end_hz = 72.0; texture = 0.04
		&"equip_release": duration = 0.13; start_hz = 205.0; end_hz = 112.0; texture = 0.05
		&"transform_rise": duration = 0.55; start_hz = 112.0; end_hz = 330.0; texture = 0.025
		&"transform_flash": duration = 0.25; start_hz = 285.0; end_hz = 92.0; texture = 0.03
		&"transform_reveal": duration = 0.42; start_hz = 880.0; end_hz = 1760.0; texture = 0.0
		&"pickup": duration = 0.095; start_hz = 330.0; end_hz = 490.0; texture = 0.02
		&"tokoin_pickup": duration = 0.22; start_hz = 1046.5; end_hz = 1318.5; texture = 0.0
		&"throw_release": duration = 0.11; start_hz = 198.0; end_hz = 102.0; texture = 0.13
		&"throw_impact": duration = 0.09; start_hz = 126.0; end_hz = 59.0; texture = 0.12
		&"stomp_hit": duration = 0.13; start_hz = 178.0; end_hz = 82.0; texture = 0.16
		&"rock_erupt": duration = 0.62; start_hz = 110.0; end_hz = 48.0; texture = 0.34
		&"rock_retract": duration = 0.34; start_hz = 92.0; end_hz = 42.0; texture = 0.22
	var frame_count: int = int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase := 0.0
	var noise_state := 0.0
	var texture_state := 0.0
	var body_state := 0.0
	var procedural_seed: int = 0x31C79 + int(kind.length()) * 7919
	for frame in frame_count:
		var t := float(frame) / float(maxi(frame_count - 1, 1))
		if kind in [&"blorb_glide", &"giant_move"]:
			procedural_seed = int((procedural_seed * 1103515245 + 12345) & 0x7fffffff)
			var raw := float(procedural_seed) / 1073741824.0 - 1.0
			var giant := kind == &"giant_move"
			texture_state = lerpf(texture_state, raw, 0.10 if giant else 0.24)
			body_state = lerpf(body_state, raw, 0.008 if giant else 0.035)
			var attack_time := 0.09 if giant else 0.014
			var envelope := minf((float(frame) / float(SAMPLE_RATE)) / attack_time, 1.0) * pow(1.0 - t, 1.35 if giant else 2.2)
			var granular := texture_state - body_state
			var movement_sample: float
			if giant:
				# Humongous compresses earth and his own enormous gel body: a broad,
				# slow pressure wash with granular ground movement, not a bass note.
				movement_sample = (body_state * 0.82 + granular * 0.22) * envelope * 0.16
			else:
				# Blorbus has no feet. His locomotion is a short soft gel/cloth slide,
				# related to the bounce sound but without a footfall-like attack.
				var swell := sin(PI * t)
				movement_sample = (body_state * 0.56 + granular * 0.30) * envelope * swell * 0.21
			bytes.encode_s16(frame * 2, clampi(int(movement_sample * 32767.0), -32768, 32767))
			continue
		if kind in [&"rock_erupt", &"rock_retract"]:
			var seconds := float(frame) / float(SAMPLE_RATE)
			var emerging := kind == &"rock_erupt"
			var attack := minf(seconds/(0.028 if emerging else 0.045),1.0)
			var envelope := attack*pow(1.0-t,1.15 if emerging else 2.0)
			# The reference is a sustained low earth movement carrying several
			# separate brittle fractures—not a descending synthesized note. Two
			# differently smoothed noise bands supply the rumble and granular
			# scrape; short deterministic impulses add rock cracks over its body.
			procedural_seed = int((procedural_seed*1103515245+12345)&0x7fffffff)
			var raw := float(procedural_seed)/1073741824.0-1.0
			body_state = lerpf(body_state,raw,0.006 if emerging else 0.01)
			texture_state = lerpf(texture_state,raw,0.075 if emerging else 0.045)
			var rumble := body_state*1.7+(texture_state-body_state)*0.42
			var cracks := 0.0
			var crack_centers := [0.075,0.19,0.34,0.51,0.73] if emerging else [0.16,0.43]
			for crack_index in crack_centers.size():
				var distance := absf(t-float(crack_centers[crack_index]))
				var impulse := exp(-distance*(115.0+float(crack_index)*17.0))
				var crack_frequency := 310.0+float(crack_index)*137.0
				cracks += sin(TAU*crack_frequency*seconds+float(crack_index)*1.7)*impulse
			var gain := 0.19 if emerging else 0.085
			var rock_sample := (rumble+cracks*0.48)*envelope*gain
			bytes.encode_s16(frame * 2, clampi(int(rock_sample * 32767.0), -32768, 32767))
			continue
		if kind in [&"tokoin_pickup", &"transform_reveal"]:
			var seconds := float(frame) / float(SAMPLE_RATE)
			var transformation_twinkle := kind == &"transform_reveal"
			# Tokoin: a fixed high C6-E6 major third. Transformation: a longer
			# A-major A-C#-E-A ascent. Every note overlaps slightly like struck
			# glass tubes; none slides in pitch.
			var frequencies: Array[float] = (
				Array([880.0, 1108.73, 1318.51, 1760.0], TYPE_FLOAT, &"", null)
				if transformation_twinkle
				else Array([1046.50, 1318.51], TYPE_FLOAT, &"", null)
			)
			var delays: Array[float] = (
				Array([0.0, 0.052, 0.105, 0.165], TYPE_FLOAT, &"", null)
				if transformation_twinkle
				else Array([0.0, 0.036], TYPE_FLOAT, &"", null)
			)
			var twinkle_sample := 0.0
			for note_index in frequencies.size():
				var note_time := seconds - delays[note_index]
				if note_time < 0.0:
					continue
				var decay := 12.5 + float(note_index) * 1.5 if transformation_twinkle else 18.0 + float(note_index) * 2.0
				var envelope := minf(note_time / 0.005, 1.0) * exp(-note_time * decay)
				var frequency := frequencies[note_index]
				var tube_note := (
					sin(TAU * frequency * note_time) * 0.76
					+ sin(TAU * frequency * 2.0 * note_time) * 0.08 * exp(-note_time * 15.0)
				)
				twinkle_sample += tube_note * envelope
			var twinkle_gain := 0.052 if transformation_twinkle else 0.062
			bytes.encode_s16(frame * 2, clampi(int(twinkle_sample * twinkle_gain * 32767.0), -32768, 32767))
			continue
		phase += TAU * lerpf(start_hz, end_hz, smoothstep(0.0, 1.0, t)) / float(SAMPLE_RATE)
		var raw_noise := sin(float(frame * 3571 % 65521))
		noise_state = lerpf(noise_state, raw_noise, 0.08)
		var attack := minf(t / 0.035, 1.0)
		var envelope := attack * pow(1.0 - t, 2.4)
		if kind in [&"transform_rise", &"transform_reveal"]:
			envelope = sin(PI * t)
		var body := sin(phase) * (1.0 - texture) + noise_state * texture
		var amplitude := 0.085
		bytes.encode_s16(frame * 2, clampi(int(body * envelope * amplitude * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream


## A single hoof on packed ground, modeled on wip/yodguard-horse-walking-
## sound-4-450266.mp3. Measured from that recording: a single crack that is
## mostly gone within 3-5 ms, coloured by a broad resonance (Q ~7-10) centred
## at 900-1000 Hz, then two or three softer settling knocks and scattered grit
## over the next ~150 ms. Nothing in it is pitched. So every layer here is a
## short burst of seeded noise shaped by a resonant band-pass filter, never a
## sine tone: pure tones rang long enough to read as notes, and four fixed
## variants read as four repeating notes. Each variant draws its own
## resonance centres, hoof micro-bounce, knock timing and grit scatter from
## its seed, so no two hooves in a stride share a colour.
const HOOF_STEP_VARIANTS := 10


func _make_hoof_step(variant: int) -> AudioStreamWAV:
	var duration := 0.2
	var frame_count := int(duration * SAMPLE_RATE)
	var shape_seed := [0x6A11 + variant * 104729]
	var draw := func(low: float, high: float) -> float:
		shape_seed[0] = int((int(shape_seed[0]) * 1103515245 + 12345) & 0x7fffffff)
		return lerpf(low, high, float(shape_seed[0]) / 2147483647.0)
	var strike_filter := _band_pass(draw.call(880.0, 1010.0), draw.call(7.0, 10.0))
	var body_filter := _band_pass(draw.call(520.0, 620.0), 3.0)
	var thud_filter := _band_pass(draw.call(140.0, 190.0), 0.9)
	var knock_filter := _band_pass(draw.call(620.0, 820.0), 5.0)
	var grit_filter := _band_pass(draw.call(650.0, 900.0), 1.4)
	# The hoof wall lands, then its toe or heel touches a moment later.
	var bounce_time: float = draw.call(0.0015, 0.0035)
	var bounce_gain: float = draw.call(0.2, 0.45)
	var knock_times: Array[float] = []
	var knock_gains: Array[float] = []
	var knock_time: float = draw.call(0.035, 0.06)
	var knock_count := 2 + int(draw.call(0.0, 1.999))
	for knock in knock_count:
		knock_times.append(knock_time)
		knock_gains.append(draw.call(0.15, 0.38) * pow(0.75, knock))
		knock_time += draw.call(0.03, 0.06)
	var grain_times: Array[float] = []
	var grain_gains: Array[float] = []
	for grain in 8 + int(draw.call(0.0, 7.999)):
		grain_times.append(draw.call(0.004, 0.16))
		grain_gains.append(draw.call(0.03, 0.12))
	var noise_seed := 0x2F00 + variant * 7919
	var samples := PackedFloat32Array()
	samples.resize(frame_count)
	var peak := 0.0
	for frame in frame_count:
		var seconds := float(frame) / float(SAMPLE_RATE)
		noise_seed = int((noise_seed * 1103515245 + 12345) & 0x7fffffff)
		var white := float(noise_seed) / 1073741824.0 - 1.0
		var strike := exp(-seconds * 700.0) * minf(seconds / 0.0003, 1.0)
		if seconds >= bounce_time:
			strike += bounce_gain * exp(-(seconds - bounce_time) * 900.0)
		var knock := 0.0
		for index in knock_times.size():
			var since := seconds - knock_times[index]
			if since >= 0.0:
				knock += knock_gains[index] * exp(-since * 650.0) * minf(since / 0.0004, 1.0)
		var grit := 0.05 * exp(-seconds * 25.0)
		for index in grain_times.size():
			var since := seconds - grain_times[index]
			if since >= 0.0 and since < 0.004:
				grit += grain_gains[index] * exp(-since * 2500.0)
		var strike_excitation := white * strike
		var knock_excitation := white * knock
		var value := (
			strike_filter.step(strike_excitation)
			+ body_filter.step(strike_excitation) * 0.22
			+ thud_filter.step(strike_excitation + knock_excitation * 0.8) * 0.3
			+ knock_filter.step(knock_excitation) * 0.45
			+ grit_filter.step(white * grit) * 0.16
		) * minf((duration - seconds) / 0.02, 1.0)
		samples[frame] = value
		peak = maxf(peak, absf(value))
	# A transient peak, not a sustained tone: this sits at about the loudness
	# of the other footsteps, whose tonal bodies peak near 0.085.
	var gain_to_peak := 0.2 / maxf(peak, 0.0001)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in frame_count:
		bytes.encode_s16(frame * 2, clampi(int(samples[frame] * gain_to_peak * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


## RBJ constant-peak band-pass biquad for _make_hoof_step(). A class rather
## than a packed array of coefficients: its running state must persist between
## calls, and packed arrays are copy-on-write.
class BandPass:
	var b0: float
	var b2: float
	var a1: float
	var a2: float
	var x1 := 0.0
	var x2 := 0.0
	var y1 := 0.0
	var y2 := 0.0

	func _init(center_hz: float, q: float, sample_rate: float) -> void:
		var omega := TAU * center_hz / sample_rate
		var alpha := sin(omega) / (2.0 * q)
		var a0 := 1.0 + alpha
		b0 = alpha / a0
		b2 = -alpha / a0
		a1 = -2.0 * cos(omega) / a0
		a2 = (1.0 - alpha) / a0

	func step(input: float) -> float:
		var output := b0 * input + b2 * x2 - a1 * y1 - a2 * y2
		x2 = x1
		x1 = input
		y2 = y1
		y1 = output
		return output


func _band_pass(center_hz: float, q: float) -> BandPass:
	return BandPass.new(center_hz, q, float(SAMPLE_RATE))


## Short weapon air displacement modeled on the supplied 144ms reference.
## This is intentionally unpitched: two moving low-pass states split seeded
## noise into a warm pressure body and a narrow rushing band. Each variant has
## a slightly different duration, turbulence, peak time, and spectral sweep;
## inward strokes reverse the broad spectral motion rather than replaying the
## outward waveform backwards.
func _make_weapon_swipe(variant: int, inward: bool) -> AudioStreamWAV:
	var durations: Array[float] = [0.138, 0.151, 0.164]
	var duration: float = durations[variant]
	var frame_count := int(duration * SAMPLE_RATE)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var seed := 0x5A17C + variant * 104729 + (0x2719 if inward else 0)
	var pressure_state := 0.0
	var rush_state := 0.0
	var fine_state := 0.0
	var peak_times: Array[float] = [0.42, 0.47, 0.39]
	var peak_time: float = peak_times[variant]
	for frame in frame_count:
		var t := float(frame) / float(maxi(frame_count - 1, 1))
		seed = int((seed * 1103515245 + 12345) & 0x7fffffff)
		var white := float(seed) / 1073741824.0 - 1.0
		# Outward cuts open brighter then settle; inward cuts gather brightness
		# into contact. Neither is a literal reversal, so consecutive strokes do
		# not expose a mechanically mirrored sample.
		var motion_t := 1.0 - t if inward else t
		var rush_response := lerpf(0.24, 0.075, motion_t) * (1.0 + variant * 0.06)
		var fine_response := lerpf(0.48, 0.18, motion_t)
		pressure_state = lerpf(pressure_state, white, 0.012 + variant * 0.0015)
		rush_state = lerpf(rush_state, white, rush_response)
		fine_state = lerpf(fine_state, white, fine_response)
		var broad_air := (rush_state - pressure_state) * 0.74
		var edge_air := (fine_state - rush_state) * (0.17 + variant * 0.018)
		var pressure := pressure_state * 0.26
		var attack := smoothstep(0.0, 0.055 + variant * 0.008, t)
		var distance_from_peak := absf(t - peak_time)
		var swell := exp(-pow(distance_from_peak / (0.27 + variant * 0.015), 2.0))
		var tail := pow(maxf(1.0 - t, 0.0), 1.18 + variant * 0.12)
		var envelope := attack * swell * tail
		# A tiny secondary curl makes the air feel displaced around a physical
		# edge, while remaining subordinate to the single main swipe gesture.
		var curl_center := 0.67 if inward else 0.61
		var curl := exp(-pow((t - curl_center) / 0.11, 2.0)) * pressure_state * 0.12
		var sample_value := ((pressure + broad_air + edge_air) * envelope + curl * tail) * 0.18
		bytes.encode_s16(frame * 2, clampi(int(sample_value * 32767.0), -32768, 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _connect_existing(node: Node) -> void:
	_connect_control(node)
	for child in node.get_children():
		_connect_existing(child)


func _on_node_added(node: Node) -> void:
	# UI lists frequently construct and replace transient controls within the
	# same frame. Passing the Node itself through MessageQueue leaves a stale
	# generic Object argument when one is freed before the deferred call, and
	# Godot rejects it before _connect_control() can even inspect it. An integer
	# instance ID survives the queue safely and resolves to null after deletion.
	_connect_control_by_id.call_deferred(node.get_instance_id())


func _connect_control_by_id(instance_id: int) -> void:
	var object := instance_from_id(instance_id)
	var node := object as Node
	if node != null and is_instance_valid(node):
		_connect_control(node)


func _connect_control(node: Node) -> void:
	var button := node as BaseButton
	if button == null or button.has_meta("ui_sounds_connected"):
		return
	button.set_meta("ui_sounds_connected", true)
	button.focus_entered.connect(play_selection)
	button.mouse_entered.connect(play_selection)
	button.pressed.connect(_on_button_pressed.bind(button))


func _on_button_pressed(button: BaseButton) -> void:
	if button.get_meta("ui_sound_kind", "") == "menu_close":
		return
	var label: String = (button as Button).text.strip_edges().to_lower() if button is Button else ""
	if button.get_meta("ui_sound_kind", "") == "back" or label in ["never mind.", "cancel", "back", "close", "no thanks."]:
		play_back()
	else:
		play_action()


func play_selection() -> void:
	if not enabled:
		return
	var now := Time.get_ticks_msec()
	if now - _last_selection_msec < int(SELECTION_COOLDOWN * 1000.0):
		return
	_last_selection_msec = now
	_selection_player.play()


func play_action() -> void:
	if enabled:
		_action_player.play()


func play_back() -> void:
	if enabled:
		_back_player.play()


func play_crt_off() -> void:
	if enabled:
		_crt_off_player.play()


func play_crt_on() -> void:
	if enabled:
		_crt_on_player.play()


func play_blorb_bounce(strong: bool = false, source_id: int = 0) -> void:
	if not enabled:
		return
	if strong:
		_blorb_jump_player.volume_db = world_distance_db(source_id)
		_blorb_jump_player.play()
	else:
		_blorb_bounce_player.volume_db = world_distance_db(source_id)
		_blorb_bounce_player.play()


func play_footstep(right_foot: bool, running: bool = false, source_id: int = 0, snow: bool = false) -> void:
	if not enabled or not _selected_movement_source(source_id):
		return
	var player := (
		(_snow_footstep_right_player if right_foot else _snow_footstep_left_player)
		if snow else (_footstep_right_player if right_foot else _footstep_left_player)
	)
	# Just enough variation to keep a long walk from sounding like a sample
	# loop, without making the character's weight or footwear seem to change.
	player.pitch_scale = randf_range(0.965, 1.035)
	player.volume_db = (randf_range(-1.2, -0.4) if running else randf_range(-3.4, -2.4)) + world_distance_db(source_id)
	player.play()


func play_landing(source_id: int = 0) -> void:
	if enabled and _selected_movement_source(source_id):
		_landing_player.pitch_scale = randf_range(0.97, 1.025)
		_landing_player.volume_db = randf_range(-1.6, -0.8) + world_distance_db(source_id)
		_landing_player.play()


func _selected_movement_source(source_id: int) -> bool:
	if source_id == 0:
		return false
	var source := instance_from_id(source_id) as Node
	var selected := PartyControl.active_control_body()
	return source != null and selected != null and source == selected


func play_blorb_body_hit(source_id: int = 0) -> void:
	if enabled:
		_blorb_body_hit_player.volume_db = world_distance_db(source_id)
		_blorb_body_hit_player.play()


func play_nme_hit(source_id: int = 0) -> void:
	if not enabled:
		return
	_nme_hit_players[_nme_hit_index].volume_db = world_distance_db(source_id)
	_nme_hit_players[_nme_hit_index].play()
	_nme_hit_index = (_nme_hit_index + 1) % _nme_hit_players.size()


func play_seed_eject(source_id: int = 0) -> void:
	if not enabled:
		return
	_seed_eject_players[_seed_eject_index].volume_db = world_distance_db(source_id)
	_seed_eject_players[_seed_eject_index].play()
	_seed_eject_index = (_seed_eject_index + 1) % _seed_eject_players.size()


func pulse_power_loop(kind: StringName, source_id: int) -> void:
	if kind in _power_loop_claims:
		(_power_loop_claims[kind] as Dictionary)[source_id] = Time.get_ticks_msec()
