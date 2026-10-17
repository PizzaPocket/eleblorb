extends Node3D

## Reusable town music source. The stream keeps looping while inaudible so
## approaching the town changes only its volume, never restarts the music.

const MUSIC_BUS := &"Music"

@export var track: AudioStream
@export var player_path: NodePath = NodePath("../../Player")
@export var full_volume_radius := 42.0
@export var silent_radius := 112.0
# Keep the score behind dialogue and gameplay sounds; the distance fade
# attenuates from this in-town level as the listener leaves Ohio.
@export var volume_db := -18.0

var _player: AudioStreamPlayer
var _listener: Node3D


func _ready() -> void:
	if track == null:
		return
	var loop_track := track.duplicate() as AudioStreamWAV
	if loop_track == null:
		push_error("DistanceMusic expects an AudioStreamWAV track.")
		return
	loop_track.loop_mode = AudioStreamWAV.LOOP_FORWARD
	# Imported non-looping WAVs have loop_end == 0. Enabling looping alone
	# repeats the first sample instead of playing the composition.
	loop_track.loop_begin = 0
	loop_track.loop_end = roundi(loop_track.get_length() * loop_track.mix_rate)
	_player = AudioStreamPlayer.new()
	_player.name = "LoopingTrack"
	_player.stream = loop_track
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(MUSIC_BUS) != -1:
		_player.bus = MUSIC_BUS
	add_child(_player)
	_listener = get_node_or_null(player_path) as Node3D
	_player.volume_db = -80.0
	_player.play()


func _process(_delta: float) -> void:
	if _player == null:
		return
	if not is_instance_valid(_listener):
		_player.volume_db = -80.0
		return
	# Recover if the audio device was not ready when the town scene entered.
	if not _player.playing:
		_player.play()
	var here := global_position
	var listener := _listener.global_position
	var distance := Vector2(here.x - listener.x, here.z - listener.z).length()
	var audible_range := maxf(silent_radius - full_volume_radius, 0.001)
	var fade_position := clampf((distance - full_volume_radius) / audible_range, 0.0, 1.0)
	var fade := 1.0 - fade_position * fade_position * (3.0 - 2.0 * fade_position)
	_player.volume_db = volume_db + linear_to_db(maxf(fade, 0.0001))
