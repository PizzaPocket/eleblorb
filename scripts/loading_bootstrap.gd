extends Node

## Keeps the first scene deliberately tiny, so LoadingScreen can render before
## the asset-heavy world scene is read and instantiated.
const WORLD_SCENE := "res://scenes/main.tscn"

var _requested := false
var _changing_scene := false


func _ready() -> void:
	LoadingScreen.set_phase("Loading the world…", 0.90)
	# Do not even request the world until the lightweight loading scene has
	# completed a real draw. Awaiting only process_frame is insufficient: the
	# main thread can begin a synchronous resource load before the renderer has
	# presented the UI, leaving the native window grey throughout construction.
	call_deferred("_request_world_load_after_first_draw")


func _request_world_load_after_first_draw() -> void:
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if get_tree().current_scene != self:
		return
	var result := ResourceLoader.load_threaded_request(WORLD_SCENE)
	_requested = result == OK
	if not _requested:
		_load_world_synchronously()


func _process(_delta: float) -> void:
	if not _requested or _changing_scene:
		return
	var progress: Array = []
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
	# A failed threaded request can leave a failed entry in ResourceLoader's
	# cache. Bypass that entry for the recovery load; change_scene_to_file()
	# would otherwise consult the same poisoned cache and fail a second time.
	var world := ResourceLoader.load(
		WORLD_SCENE, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE
	) as PackedScene
	if world != null:
		get_tree().change_scene_to_packed(world)
	else:
		push_error("Unable to load the main world scene: %s" % WORLD_SCENE)
