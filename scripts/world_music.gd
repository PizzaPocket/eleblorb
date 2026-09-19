class_name WorldMusic
extends AudioStreamPlayer

## A world's background music. A world scene that wants music adds one of
## these with its track (see demo_world.gd): it fades in as the world starts,
## loops for as long as the world is loaded, and stops with it, so each
## world plays exactly the music it asks for and no other. It keeps playing
## through the pause menu. Routed to a "Music" audio bus when the project
## has one, so music can later get its own volume setting.

const MUSIC_BUS := &"Music"

## The music to play, and how loud once faded in.
@export var track: AudioStream
@export var music_volume_db := -8.0
## Seconds to fade in from silence.
@export var fade_in := 2.5


func _init(music_track: AudioStream = null, volume := -8.0) -> void:
	name = "WorldMusic"
	track = music_track
	music_volume_db = volume


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index(MUSIC_BUS) != -1:
		bus = MUSIC_BUS
	if track == null:
		return
	if track is AudioStreamMP3:
		(track as AudioStreamMP3).loop = true
	elif track is AudioStreamOggVorbis:
		(track as AudioStreamOggVorbis).loop = true
	stream = track
	volume_db = -60.0
	play()
	create_tween().tween_property(self, "volume_db", music_volume_db, fade_in)
