class_name WorldMusic
extends AudioStreamPlayer

## A world's background music. A world scene can supply one looping track or
## an ordered playlist (see demo_world.gd). It fades in as the world starts,
## advances through playlist tracks without repeating the same song forever,
## and stops with the world. It keeps playing through the pause menu. Routed
## to a "Music" audio bus when the project has one, so music can later get its
## own volume setting.

const MUSIC_BUS := &"Music"

## The music to play, and how loud once faded in.
@export var track: AudioStream
var tracks: Array[AudioStream] = []
@export var music_volume_db := -8.0
## Seconds to fade in from silence.
@export var fade_in := 2.5
var _track_index := 0


func _init(music_track: AudioStream = null, volume := -8.0) -> void:
	name = "WorldMusic"
	track = music_track
	music_volume_db = volume


static func playlist(music_tracks: Array[AudioStream], volume := -8.0) -> WorldMusic:
	var player := WorldMusic.new(null, volume)
	player.tracks.assign(music_tracks)
	return player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(MUSIC_BUS) != -1:
		bus = MUSIC_BUS
	if tracks.is_empty() and track != null:
		tracks.append(track)
	if tracks.is_empty():
		return
	finished.connect(_advance_track)
	_play_track(0)
	volume_db = -60.0
	create_tween().tween_property(self, "volume_db", music_volume_db, fade_in)


func _play_track(index: int) -> void:
	_track_index = posmod(index, tracks.size())
	stream = tracks[_track_index]
	# A one-song world loops seamlessly. A playlist advances on `finished`,
	# allowing each complete composition to play before the next begins.
	var should_loop := tracks.size() == 1
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = should_loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = should_loop
	play()


func _advance_track() -> void:
	_play_track(_track_index + 1)
