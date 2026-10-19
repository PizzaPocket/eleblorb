extends Node3D

## Reproducible rendered Moy benchmark. Run windowed; headless/dummy results are
## retained for diagnosis but explicitly fail rendering-evidence validation.
const MAIN := preload("res://scenes/main.tscn")
const QA := preload("res://scenes/moy_city_qa.tscn")
const DEFAULT_DURATION := 30.0
const DEFAULT_WARMUP := 5.0
const DEFAULT_RESOLUTION := Vector2i(1280, 720)
var _config: Dictionary = {}
var _raw: Dictionary = {}
var _output_path := ""
var _world: Node3D
var _player: Player
var _terrain: Node
var _city: Node
var _failed := false
var _startup_timed_out := false

func _ready() -> void:
	_config = _parse_config(OS.get_cmdline_user_args())
	var args: Array = OS.get_cmdline_user_args()
	var qa_mode := "--qa" in args
	var run_id := String(_config.run_id)
	_output_path = "res://docs/diagnostics/raw/%s-moy-P2-%s.json" % [Time.get_date_string_from_system(), run_id]
	_seed_world()
	_config["mode"] = "qa" if qa_mode else "crossroads"
	_config["godot_version"] = Engine.get_version_info()
	_config["os"] = OS.get_name()
	_config["os_version"] = OS.get_version()
	_config["cpu"] = OS.get_processor_name()
	_config["cpu_cores"] = OS.get_processor_count()
	_config["memory_info"] = OS.get_memory_info()
	_config["renderer"] = RenderingServer.get_current_rendering_method()
	_config["renderer_adapter"] = RenderingServer.get_video_adapter_name()
	_config["resolution_requested"] = [_config.resolution.x, _config.resolution.y]
	_config["vsync_mode"] = _config.vsync
	_config["fps_cap"] = _config.fps_cap
	_config["seed"] = _config.seed
	_config["game_time_hours"] = _config.game_time_hours
	_config["warmup_seconds"] = _config.warmup
	_config["sample_seconds"] = _config.duration
	_config["command_line"] = OS.get_cmdline_args() + OS.get_cmdline_user_args()
	_config["commit"] = _git_commit()
	_config["source_hashes"] = _source_hashes()
	_apply_display_settings()
	_config["resolution"] = [_config.resolution.x, _config.resolution.y]
	await get_tree().process_frame
	_raw = {"schema":1, "config":_config, "samples":[], "transitions":[], "activation":[], "errors":[]}
	_write_partial()
	var startup_timer := get_tree().create_timer(300.0)
	startup_timer.timeout.connect(_on_startup_timeout)
	var start_usec := Time.get_ticks_usec()
	_world = (QA if qa_mode else MAIN).instantiate() as Node3D
	add_child(_world)
	await LoadingScreen.wait_for_world_builds()
	if _startup_timed_out: return
	startup_timer.timeout.disconnect(_on_startup_timeout)
	_player = _world.get_node_or_null("Player") as Player
	_terrain = _world.get_node_or_null("Terrain")
	_city = _world.get_node_or_null("WesternCity")
	_config["startup_to_control_ready_ms"] = float(Time.get_ticks_usec() - start_usec) / 1000.0
	_config["actual_resolution"] = [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y]
	_config["actual_viewport_resolution"] = [get_viewport().size.x, get_viewport().size.y]
	_config["resolution_valid"] = DisplayServer.get_name() == "headless" or DisplayServer.window_get_size() == Vector2i(_config.resolution_requested[0], _config.resolution_requested[1])
	if not bool(_config.resolution_valid):
		_failed = true
		_raw.errors.append({"kind":"resolution_mismatch","requested":_config.resolution_requested,"actual":_config.actual_resolution})
		push_error("MOY_PERF_FAILURE resolution mismatch requested=%s actual=%s" % [_config.resolution_requested,_config.actual_resolution])
	_raw["config"] = _config
	_config["backend_is_rendered"] = _backend_is_rendered()
	_config["vsync_supported"] = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED if DisplayServer.get_name() != "headless" else false
	for child in get_tree().root.get_children():
		if child is CanvasLayer: child.visible = false
	var camera := Camera3D.new()
	camera.name = "MoyPerfCamera"
	camera.far = 1800.0
	camera.fov = float(_config.fov)
	add_child(camera)
	camera.make_current()
	if qa_mode:
		await _run_qa(camera)
	else:
		await _run_crossroads(camera)
	if _city:
		_raw["activation_stages"] = (_city.get("_moy_stage_records") as Array).duplicate(true)
		_raw["activation_frames"] = (_city.get("_moy_activation_frame_records") as Array).duplicate(true)
		_raw["release_stages"] = (_city.get("_moy_release_records") as Array).duplicate(true)
	var valid_samples: bool = _raw.get("samples", []).size() > 0
	var visible := false
	for sample in _raw.samples:
		if sample.get("draws_peak") != null and sample.get("triangles_peak") != null and float(sample.draws_peak) > 0.0 and float(sample.triangles_peak) > 0.0:
			visible = true
	_raw["validation"] = {
		"rendered_backend": _backend_is_rendered(),
		"visible_geometry": visible,
		"completed_samples": valid_samples,
		"accepted_rendering_evidence": _backend_is_rendered() and visible and valid_samples and not _failed,
		"failed": _failed
	}
	_write_partial()
	if not bool(_raw.validation.accepted_rendering_evidence):
		push_error("MOY_PERF_INVALID_RENDER_EVIDENCE backend=%s adapter=%s visible=%s samples=%d" % [RenderingServer.get_current_rendering_method(), RenderingServer.get_video_adapter_name(), visible, _raw.samples.size()])
		get_tree().quit(1)
	else:
		print("MOY_PERF_COMPLETE output=", _output_path)
		get_tree().quit(0)

func _parse_config(args: Array) -> Dictionary:
	var cfg := {"run_id": "run1", "duration": DEFAULT_DURATION, "warmup": DEFAULT_WARMUP,
		"resolution": DEFAULT_RESOLUTION, "vsync": DisplayServer.VSYNC_DISABLED,
		"fps_cap": 0, "seed": 20261019, "game_time_hours": 12.0,
		"fov": 70.0, "route": "crossroads_spawn,old_moy_street,old_moy_rooftop,downtown_up,estate_court,crossing_east_gate,train_hall_static"}
	for arg in args:
		var pair := String(arg).trim_prefix("--").split("=", false, 1)
		if pair.size() != 2: continue
		match pair[0]:
			"run-id": cfg.run_id = pair[1]
			"duration": cfg.duration = maxf(30.0, float(pair[1]))
			"warmup": cfg.warmup = maxf(5.0, float(pair[1]))
			"resolution":
				var dims := pair[1].split("x")
				if dims.size() == 2: cfg.resolution = Vector2i(int(dims[0]), int(dims[1]))
			"vsync": cfg.vsync = DisplayServer.VSYNC_ENABLED if pair[1] == "on" else DisplayServer.VSYNC_DISABLED
			"fps-cap": cfg.fps_cap = int(pair[1])
			"seed": cfg.seed = int(pair[1])
			"time": cfg.game_time_hours = float(pair[1])
			"fov": cfg.fov = float(pair[1])
			"route": cfg.route = pair[1]
	return cfg

func _apply_display_settings() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_config.resolution)
		DisplayServer.window_set_vsync_mode(int(_config.vsync))
	Engine.max_fps = int(_config.fps_cap)

func _seed_world() -> void:
	seed(int(_config.seed))
	WorldState.opening_wake_completed = true
	WorldState.game_time_hours = float(_config.game_time_hours)

func _backend_is_rendered() -> bool:
	var renderer := RenderingServer.get_current_rendering_method().to_lower()
	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	return DisplayServer.get_name() != "headless" and renderer != "dummy" and adapter != "dummy" and not adapter.is_empty()

func _run_crossroads(camera: Camera3D) -> void:
	await _sample(camera, "crossroads_spawn", Vector3(0, 4, 12), Vector3(0, 2, 0), Vector2.ZERO, "Moy asleep; Crossroads control baseline")
	if _player == null or _terrain == null or _city == null:
		_fail("Crossroads world lacks Player, Terrain or WesternCity")
		return
	_player.set_physics_process(false)
	var ground := float(_terrain.call("get_mesh_height", -600.0, 0.0))
	_player.global_position = Vector3(-600.0, ground + 0.5, 0.0)
	var approach_start := Time.get_ticks_usec()
	var approach_frames := 0
	while approach_frames < 2400 and not _city_control_ready():
		await get_tree().process_frame
		approach_frames += 1
		_capture_transition_frame("approach", approach_frames)
	if not _city_control_ready():
		_fail("Moy pack and actor readiness timed out")
		return
	_raw.transitions.append({"phase":"approach", "elapsed_ms":float(Time.get_ticks_usec()-approach_start)/1000.0,
		"frames":approach_frames, "active_packs":_active_packs(), "requested_packs":_requested_packs()})
	var views := [
		{"name":"old_moy_street", "camera":Vector3(-704,-54,-24), "look":Vector3(-700,-58,0), "player":Vector2(-704,0)},
		{"name":"old_moy_rooftop", "camera":Vector3(-704,-29,-24), "look":Vector3(-700,-42,0), "player":Vector2(-704,0)},
		{"name":"downtown_up", "camera":Vector3(-462,5,-40), "look":Vector3(-462,-25,-20), "player":Vector2(-462,-20)},
		{"name":"estate_court", "camera":Vector3(-535,-38,-125), "look":Vector3(-535,-48,-100), "player":Vector2(-535,-100)},
		{"name":"crossing_east_gate", "camera":Vector3(-560,8,8), "look":Vector3(-560,13.2,0), "player":Vector2(-560,0)},
		{"name":"train_hall_static", "camera":Vector3(-560,-34,-12), "look":Vector3(-560,-45,0), "player":Vector2(-560,0)}]
	var requested: Array = String(_config.route).split(",")
	for view in views:
		if String(view.name) not in requested: continue
		var p: Vector2 = view.player
		var y := float(_terrain.call("get_mesh_height", p.x, p.y)) + 0.5
		_player.global_position = Vector3(p.x, y, p.y)
		await _sample(camera, String(view.name), view.camera, view.look, p, "stationary view after approach")
	for cycle in 2:
		var away_y := float(_terrain.call("get_mesh_height", -1600.0, 0.0))
		_player.global_position = Vector3(-1600.0, away_y + 0.5, 0.0)
		var started := Time.get_ticks_usec()
		var elapsed := 0.0
		while elapsed < 45.0 and int(_city.get("_moy_active").size()) > 0:
			await get_tree().process_frame
			elapsed = float(Time.get_ticks_usec() - started) / 1000000.0
			_capture_transition_frame("unload_%d" % (cycle+1), int(elapsed*1000.0))
		var after_unload := _stream_state()
		var near_y := float(_terrain.call("get_mesh_height", -600.0, 0.0))
		_player.global_position = Vector3(-600.0, near_y + 0.5, 0.0)
		var reload_start := Time.get_ticks_usec()
		var frames := 0
		while frames < 2400 and not _city_control_ready():
			await get_tree().process_frame
			frames += 1
			_capture_transition_frame("reload_%d" % (cycle+1), frames)
		var complete := _city_control_ready()
		_raw.transitions.append({"phase":"unload_reload", "cycle":cycle+1, "unload_state":after_unload,
			"reload_ms":float(Time.get_ticks_usec()-reload_start)/1000.0, "reload_frames":frames,
			"ready":complete, "settled_state":_stream_state()})
		if not complete: _fail("reload cycle %d timed out" % (cycle+1))

func _run_qa(camera: Camera3D) -> void:
	if _player == null or _terrain == null or _city == null:
		_fail("QA world lacks Player, Terrain or WesternCity")
		return
	var y := float(_terrain.call("get_mesh_height", -704.0, 0.0))
	_player.global_position = Vector3(-704.0, y + 0.5, 0.0)
	var frames := 0
	while frames < 2400 and not _city_control_ready():
		await get_tree().process_frame
		frames += 1
		_capture_transition_frame("qa_activation", frames)
	if not _city_control_ready():
		_fail("QA pack activation timed out")
		return
	await _sample(camera, "qa_dense_old_moy", Vector3(-704,-29,-24), Vector3(-700,-42,0), Vector2(-704,0), "isolated QA; actual packs")

func _sample(camera: Camera3D, label: String, position: Vector3, target: Vector3, body_position: Vector2, phase: String) -> void:
	camera.global_position = position
	camera.look_at(target)
	if _player and _terrain and body_position != Vector2.ZERO:
		var y := float(_terrain.call("get_mesh_height", body_position.x, body_position.y)) + 0.5
		_player.global_position = Vector3(body_position.x, y, body_position.y)
	var warmup_started := Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - warmup_started) < float(_config.warmup) * 1000000.0:
		await get_tree().process_frame
	var frames: Array[Dictionary] = []
	var started := Time.get_ticks_usec()
	var previous := started
	while float(Time.get_ticks_usec()-started) < float(_config.duration) * 1000000.0:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var sample := _monitor_frame(float(now-previous)/1000.0)
		sample["elapsed_ms"] = float(now-started)/1000.0
		sample["position"] = [camera.global_position.x, camera.global_position.y, camera.global_position.z]
		sample["phase"] = phase
		frames.append(sample)
		previous = now
	var summary := _summarize(label, frames, position, target, phase)
	_raw.samples.append(summary)
	_write_partial()
	print("MOY_PERF_SAMPLE name=%s frames=%d p50_ms=%.3f p95_ms=%.3f p99_ms=%.3f worst_ms=%.3f draws_peak=%s triangles_peak=%s active_packs=%d" % [label, frames.size(), summary.p50_ms, summary.p95_ms, summary.p99_ms, summary.worst_ms, summary.draws_peak, summary.triangles_peak, summary.active_packs])

func _monitor_frame(frame_ms: float) -> Dictionary:
	var position := _player.global_position if _player else Vector3.ZERO
	return {"frame_ms":frame_ms, "position":[position.x,position.y,position.z],
		"draws":_monitor_or_null(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"triangles":_monitor_or_null(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"static_mib":_monitor_mib(Performance.MEMORY_STATIC),
		"video_mib":_monitor_mib(Performance.RENDER_VIDEO_MEM_USED),
		"nodes":_monitor_or_null(Performance.OBJECT_NODE_COUNT),
		"physics_objects":_monitor_or_null(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
		"active_packs":_active_packs(), "requested_packs":_requested_packs(),
		"retained_resources":_retained_resources()}

func _summarize(label: String, frames: Array[Dictionary], camera: Vector3, target: Vector3, phase: String) -> Dictionary:
	var intervals: Array[float] = []
	var draws: Array[float] = []
	var triangles: Array[float] = []
	var static_mem: Array[float] = []
	var video_mem: Array[float] = []
	var physics: Array[float] = []
	var over_50: Array[Dictionary] = []
	var over_100: Array[Dictionary] = []
	for frame in frames:
		var ms := float(frame.frame_ms)
		intervals.append(ms)
		if frame.draws != null: draws.append(float(frame.draws))
		if frame.triangles != null: triangles.append(float(frame.triangles))
		if frame.static_mib != null: static_mem.append(float(frame.static_mib))
		if frame.video_mib != null: video_mem.append(float(frame.video_mib))
		if frame.physics_objects != null: physics.append(float(frame.physics_objects))
		if ms > 50.0: over_50.append(frame)
		if ms > 100.0: over_100.append(frame)
	intervals.sort(); draws.sort(); triangles.sort(); static_mem.sort(); video_mem.sort(); physics.sort()
	var result := {"name":label, "phase":phase, "camera":[camera.x,camera.y,camera.z], "target":[target.x,target.y,target.z],
		"fov":float(_config.fov), "frames":frames.size(), "duration_s":float(_config.duration),
		"p50_ms":_percentile(intervals,0.50), "p95_ms":_percentile(intervals,0.95),
		"p99_ms":_percentile(intervals,0.99), "worst_ms":intervals.back() if not intervals.is_empty() else null,
		"frames_over_50ms":over_50.size(), "frames_over_100ms":over_100.size(),
		"over_50ms":over_50, "over_100ms":over_100,
		"draws_distribution":_distribution(draws), "draws_peak":draws.back() if not draws.is_empty() else null,
		"triangles_distribution":_distribution(triangles), "triangles_peak":triangles.back() if not triangles.is_empty() else null,
		"static_mib_distribution":_distribution(static_mem), "video_mib_distribution":_distribution(video_mem),
		"physics_objects_distribution":_distribution(physics), "active_packs":_active_packs(),
		"requested_packs":_requested_packs(), "retained_resources":_retained_resources(), "raw_frames":frames}
	return result

func _distribution(values: Array[float]) -> Variant:
	if values.is_empty(): return null
	return {"count":values.size(), "min":values.front(), "p50":_percentile(values,0.5), "p95":_percentile(values,0.95), "p99":_percentile(values,0.99), "max":values.back()}

func _percentile(values: Array[float], quantile: float) -> Variant:
	if values.is_empty(): return null
	return values[clampi(ceili(float(values.size()-1)*quantile),0,values.size()-1)]

func _monitor_or_null(monitor: int) -> Variant:
	var value := Performance.get_monitor(monitor)
	if DisplayServer.get_name() == "headless" or RenderingServer.get_current_rendering_method().to_lower() == "dummy": return null
	return value

func _monitor_mib(monitor: int) -> Variant:
	var value: Variant = _monitor_or_null(monitor)
	return null if value == null else float(value)/1048576.0

func _active_packs() -> int:
	return int(_city.call("get_active_moy_pack_count")) if _city and _city.has_method("get_active_moy_pack_count") else -1

func _city_control_ready() -> bool:
	return _city != null and bool(_city.call("moy_packs_ready")) and bool(_city.call("moy_actors_ready"))

func _requested_packs() -> int:
	return int(_city.get("_moy_requested").size()) if _city else -1

func _retained_resources() -> int:
	if _city == null: return 0
	var cached := 0
	for path in _city.get("_moy_paths"):
		if ResourceLoader.has_cached(String(path)): cached += 1
	return cached

func _stream_state() -> Dictionary:
	return {"active_packs":_active_packs(), "requested_packs":_requested_packs(),
		"nodes":_count_nodes(get_tree().root), "static_mib":_monitor_mib(Performance.MEMORY_STATIC),
		"retained_manifest_refs":_retained_resources(), "actors_ready":bool(_city.call("moy_actors_ready")) if _city and _city.has_method("moy_actors_ready") else false}

func _count_nodes(node: Node) -> int:
	var count := 1
	for child in node.get_children(): count += _count_nodes(child)
	return count

func _capture_transition_frame(phase: String, frame: int) -> void:
	var ms := float(get_process_delta_time())*1000.0
	if ms <= 50.0: return
	var pos := _player.global_position if _player else Vector3.ZERO
	var event := {"phase":phase, "frame":frame, "frame_ms":ms, "position":[pos.x,pos.y,pos.z],
		"active_packs":_active_packs(), "requested_packs":_requested_packs()}
	_raw.activation.append(event)
	if ms > 100.0: _raw.errors.append({"kind":"travel_frame_over_100ms", "event":event})

func _git_commit() -> String:
	var output: Array = []
	var code := OS.execute("git", ["rev-parse", "HEAD"], output, true)
	return String(output[0]).strip_edges() if code == 0 and not output.is_empty() else "unavailable"

func _source_hashes() -> Dictionary:
	var paths := ["res://tools/moy_performance_probe.gd", "res://scripts/city_generator.gd",
		"res://scripts/moy_city_bake_builder.gd", "res://scripts/city_plan.gd",
		"res://scripts/moy_ride_train.gd", "res://assets/generated/moy_city/manifest.json",
		"res://assets/generated/moy_city/cell_05_04_p01.tscn"]
	var result: Dictionary = {}
	for path in paths:
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			result[path] = "missing"
			continue
		var hash := HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(file.get_buffer(file.get_length()))
		result[path] = hash.finish().hex_encode()
	return result

func _fail(message: String) -> void:
	_failed = true
	_raw.errors.append({"kind":"benchmark_failure", "message":message})
	push_error("MOY_PERF_FAILURE " + message)

func _on_startup_timeout() -> void:
	if not is_inside_tree() or _raw.get("validation", {}).get("completed_samples", false): return
	_startup_timed_out = true
	_failed = true
	_raw.errors.append({"kind":"startup_timeout", "message":"control-ready world build exceeded 300 seconds"})
	_write_partial()
	get_tree().quit(1)

func _write_partial() -> void:
	if _raw.is_empty(): _raw = {"schema":1, "config":_config, "samples":[], "transitions":[], "activation":[], "errors":[]}
	var absolute := ProjectSettings.globalize_path(_output_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_raw, "\t"))
		file.close()
