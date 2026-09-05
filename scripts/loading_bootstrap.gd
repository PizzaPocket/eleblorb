extends Node

## Keeps the first scene deliberately tiny, so LoadingScreen can render before
## the asset-heavy world scene is read and instantiated.
const WORLD_SCENE := "res://scenes/main.tscn"

var _requested := false
var _changing_scene := false


func _ready() -> void:
	LoadingScreen.set_phase("Loading the world…", 0.90)
	var result := ResourceLoader.load_threaded_request(WORLD_SCENE)
	_requested = result == OK
	if not _requested:
		# This only happens if threaded loading is unavailable on a platform;
		# the persistent overlay still prevents a blank window during fallback.
		call_deferred("_load_world_synchronously")


func _process(_delta: float) -> void:
	if not _requested or _changing_scene:
		return
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(WORLD_SCENE, progress)
	if not progress.is_empty():
		LoadingScreen.set_world_load_progress(float(progress[0]))
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_changing_scene = true
		LoadingScreen.set_phase("Building the world…", 0.97)
		var world := ResourceLoader.load_threaded_get(WORLD_SCENE) as PackedScene
		if world != null:
			get_tree().change_scene_to_packed(world)
		else:
			_load_world_synchronously()
	elif status == ResourceLoader.THREAD_LOAD_FAILED:
		_changing_scene = true
		_load_world_synchronously()


func _load_world_synchronously() -> void:
	if get_tree().current_scene != self:
		return
	get_tree().change_scene_to_file(WORLD_SCENE)
