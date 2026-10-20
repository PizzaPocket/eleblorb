extends Node3D

## Reproducible rendered Moy benchmark. Run windowed; headless/dummy results are
## retained for diagnosis but explicitly fail rendering-evidence validation.
const MAIN := preload("res://scenes/main.tscn")
const QA := preload("res://scenes/moy_city_qa.tscn")
const DEFAULT_DURATION := 30.0
const DEFAULT_WARMUP := 5.0
const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const FRAME_WIDTH := 13
const REQUIRED_CROSSROADS_SAMPLES := ["crossroads_spawn", "old_moy_street", "old_moy_rooftop",
	"downtown_up", "estate_court", "crossing_east_gate", "east_gate_train_hall"]
const P3_SAMPLE_NAMES := ["market", "southst", "arcade", "lamplane"]
const P4_SAMPLE_NAMES := ["oldmoy", "wellquarter", "cinemasq", "oldhigh", "oldcourt", "oldroofs"]
const ROUTE_SAMPLE_NAMES := REQUIRED_CROSSROADS_SAMPLES + P3_SAMPLE_NAMES + P4_SAMPLE_NAMES
const DEFAULT_ROUTE := "crossroads_spawn,old_moy_street,old_moy_rooftop,downtown_up,estate_court,crossing_east_gate,east_gate_train_hall"
const REQUIRED_CONTROLLED_ROUTE_PROOFS := ["moving_train_ride", "four_gate_entries", "vine_handover",
	"occupied_support_thresholds", "xiao_hou_zi_entry", "alternate_body_entry", "hotel_annulus_hold",
	"rapid_reentry", "three_warm_traversals"]
var _config: Dictionary = {}
var _raw: Dictionary = {}
var _output_path := ""
var _frames_path := ""
var _world: Node3D
var _player: Player
var _terrain: Node
var _city: Node
var _failed := false
var _contract_test_mode := false
var _route_proofs: Dictionary = {}
var _route_proof_measurements: Dictionary = {}

func _ready() -> void:
	_config = _parse_config(OS.get_cmdline_user_args())
	var args: Array = OS.get_cmdline_user_args()
	var qa_mode := "--qa" in args
	var run_id := String(_config.run_id)
	_output_path = "res://docs/diagnostics/raw/%s-moy-P2-%s.json" % [Time.get_date_string_from_system(), run_id]
	_frames_path = "res://docs/diagnostics/raw/%s-moy-P2-%s.frames.jsonl" % [Time.get_date_string_from_system(), run_id]
	if args_has_contract_test(args):
		_run_contract_negative_case(String(_arg_value(args, "contract-test")))
		return
	var route_error := _validate_requested_route(String(_config.route))
	if not route_error.is_empty():
		_write_early_failure("invalid_route", route_error)
		get_tree().quit(2)
		return
	var normalized_route: Array[String] = []
	for route_name in String(_config.route).split(",", true): normalized_route.append(String(route_name).strip_edges())
	_config.route = ",".join(normalized_route)
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
	_route_proofs = _load_route_proofs(String(_config.get("route_proof_file", "")))
	_apply_display_settings()
	_config["resolution"] = [_config.resolution.x, _config.resolution.y]
	await get_tree().process_frame
	_raw = {"schema":2, "config":_config, "samples":[], "transitions":[], "activation":[], "errors":[],
		"frame_data_format":"one JSON object per raw frame interval; see each sample.frame_data_path"}
	_write_partial()
	var start_usec := Time.get_ticks_usec()
	_world = (QA if qa_mode else MAIN).instantiate() as Node3D
	var telemetry_city := _world.get_node_or_null("WesternCity")
	if telemetry_city and telemetry_city.has_method("set_moy_performance_telemetry"):
		telemetry_city.call("set_moy_performance_telemetry", true)
	add_child(_world)
	await LoadingScreen.wait_for_world_builds()
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
		_raw["request_drain_stages"] = (_city.get("_moy_request_drain_records") as Array).duplicate(true)
	var valid_samples: bool = _raw.get("samples", []).size() > 0
	var visible := false
	for sample in _raw.samples:
		if sample.get("draws_peak") != null and sample.get("triangles_peak") != null and float(sample.draws_peak) > 0.0 and float(sample.triangles_peak) > 0.0:
			visible = true
	_finalize_acceptance(qa_mode, visible, valid_samples)
	_write_partial()
	if not bool(_raw.validation.acceptance_passed):
		push_error("MOY_PERF_ACCEPTANCE_FAILED reasons=%s" % str(_raw.validation.failures))
		get_tree().quit(1)
	else:
		print("MOY_PERF_ACCEPTANCE_PASSED output=", _output_path)
		get_tree().quit(0)


func _finalize_acceptance(qa_mode: bool, visible: bool, valid_samples: bool) -> void:
	var render_valid := (_backend_is_rendered() or _contract_test_mode) and visible and valid_samples
	var full_route := not qa_mode and _is_full_route(String(_config.route))
	var got_names: Array[String] = []
	for sample in _raw.get("samples", []): got_names.append(String(sample.get("name", "")))
	var route_complete := full_route and got_names.size() == REQUIRED_CROSSROADS_SAMPLES.size()
	var unique_names: Dictionary = {}
	for name in got_names:
		if unique_names.has(name): route_complete = false
		unique_names[name] = true
	for required_name in REQUIRED_CROSSROADS_SAMPLES:
		if not got_names.has(required_name): route_complete = false
	var controlled_route_results: Dictionary = {}
	var controlled_routes_complete := true
	for proof_name in REQUIRED_CONTROLLED_ROUTE_PROOFS:
		var passed := bool(_route_proofs.get(proof_name, false))
		controlled_route_results[proof_name] = {"passed": passed, "status": "passed" if passed else "unrun_or_failed"}
		if not passed: controlled_routes_complete = false
	var travel_p95: Variant = _route_proof_measurements.get("travel_p95_ms")
	var travel_over_100: Variant = _route_proof_measurements.get("travel_frames_over_100ms")
	var travel_frame_budget_pass := travel_p95 != null and float(travel_p95) <= 33.3
	var travel_stall_gate_pass := travel_over_100 != null and int(travel_over_100) < 2
	if not travel_frame_budget_pass or not travel_stall_gate_pass: controlled_routes_complete = false
	var cycles: Array = []
	for transition in _raw.get("transitions", []):
		if String(transition.get("phase", "")) == "unload_reload": cycles.append(transition)
	var cycles_complete := cycles.size() == 2
	for cycle in cycles:
		if not bool(cycle.get("ready", false)) or not bool(cycle.get("unload_settled", false)):
			cycles_complete = false
	var frame_budget_pass := true
	for sample in _raw.get("samples", []):
		if float(sample.get("p95_ms", INF)) > 33.3: frame_budget_pass = false
	var severe_stalls: Array = []
	for event in _raw.get("activation", []):
		if float(event.get("frame_ms", 0.0)) > 100.0: severe_stalls.append(event)
	var stall_gate_pass := severe_stalls.size() < 2
	var failures: Array[String] = []
	if not render_valid: failures.append("rendering_evidence_invalid")
	if not route_complete and not qa_mode: failures.append("required_stationary_samples_incomplete")
	if not controlled_routes_complete and not qa_mode: failures.append("required_controlled_route_proofs_missing")
	if not travel_frame_budget_pass and not qa_mode: failures.append("controlled_travel_p95_missing_or_over_budget")
	if not travel_stall_gate_pass and not qa_mode: failures.append("controlled_travel_repeated_over_100ms_stalls")
	if not valid_samples: failures.append("no_completed_samples")
	if not cycles_complete and not qa_mode: failures.append("unload_cycles_incomplete_or_unsettled")
	if not frame_budget_pass and not qa_mode: failures.append("required_p95_frame_budget_missed")
	if not stall_gate_pass and not qa_mode: failures.append("repeated_over_100ms_activation_stalls")
	if _failed or not _raw.get("errors", []).is_empty(): failures.append("benchmark_readiness_or_runtime_failure")
	_raw["validation"] = {
		"rendered_backend": _backend_is_rendered(),
		"visible_geometry": visible,
		"completed_samples": valid_samples,
		"rendering_evidence_valid": render_valid,
		"accepted_rendering_evidence": render_valid,
		"suite_scope": "diagnostic_qa" if qa_mode else ("full" if full_route and controlled_routes_complete else ("stationary_only" if full_route else "partial")),
		"full_route_complete": route_complete,
		"required_controlled_route_proofs": controlled_route_results,
		"controlled_routes_complete": controlled_routes_complete,
		"controlled_travel_performance":{"p95_ms":travel_p95,
			"p95_budget_ms":33.3,"p95_pass":travel_frame_budget_pass,
			"frames_over_100ms":travel_over_100,"repeated_stall_pass":travel_stall_gate_pass},
		"required_samples": REQUIRED_CROSSROADS_SAMPLES,
		"actual_samples": got_names,
		"cycles_complete_and_settled": cycles_complete,
		"required_p95_frame_budget_pass": frame_budget_pass,
		"repeated_over_100ms_activation_stalls_pass": stall_gate_pass,
		"over_100ms_transition_count": severe_stalls.size(),
		"acceptance_passed": failures.is_empty(),
		"failures": failures,
		"failed": not failures.is_empty()
	}
	if not failures.is_empty(): _failed = true


func _validate_requested_route(route: String) -> String:
	if route.strip_edges().is_empty(): return "route list is empty"
	var names := route.split(",", true)
	var seen: Dictionary = {}
	for raw_name in names:
		var name := String(raw_name).strip_edges()
		if name.is_empty(): return "route contains an empty sample name"
		if not ROUTE_SAMPLE_NAMES.has(name): return "unknown route sample: %s" % name
		if seen.has(name): return "duplicate route sample: %s" % name
		seen[name] = true
	if not seen.has("crossroads_spawn"): return "route must include crossroads_spawn for an equivalent asleep baseline"
	return ""


func _is_full_route(route: String) -> bool:
	var actual := route.split(",", true)
	for i in actual.size(): actual[i] = String(actual[i]).strip_edges()
	if actual.size() != REQUIRED_CROSSROADS_SAMPLES.size(): return false
	for name in REQUIRED_CROSSROADS_SAMPLES:
		if not actual.has(name): return false
	return true


func args_has_contract_test(args: Array) -> bool:
	return not _arg_value(args, "contract-test").is_empty()


func _arg_value(args: Array, key: String) -> String:
	for arg in args:
		var prefix := "--%s=" % key
		if String(arg).begins_with(prefix): return String(arg).trim_prefix(prefix)
	return ""


func _write_early_failure(kind: String, message: String) -> void:
	_raw = {"schema": 2, "config": _config, "samples": [], "transitions": [], "activation": [],
		"errors": [{"kind": kind, "message": message}], "validation": {
		"suite_scope": "invalid", "acceptance_passed": false, "failed": true, "failures": [message]}}
	_write_partial()
	push_error("MOY_PERF_FAILURE " + message)


func _run_contract_negative_case(case_name: String) -> void:
	_contract_test_mode = true
	_config["route"] = DEFAULT_ROUTE
	var base_samples: Array[Dictionary] = []
	for sample_name in REQUIRED_CROSSROADS_SAMPLES:
		base_samples.append({"name":sample_name,"p95_ms":20.0})
	var base_cycles: Array[Dictionary] = [
		{"phase":"unload_reload","ready":true,"unload_settled":true},
		{"phase":"unload_reload","ready":true,"unload_settled":true}]
	var test_raw := {"samples": base_samples, "transitions": base_cycles, "activation": [], "errors": []}
	_failed = false
	match case_name:
		"frame_budget": test_raw.samples[4].p95_ms = 58.0
		"activation_stall": test_raw.activation = [{"frame_ms":101.0}, {"frame_ms":113.0}]
		"missing_route": test_raw.samples.remove_at(test_raw.samples.size()-1)
		"readiness_timeout": _failed = true
		"unload_timeout": test_raw.transitions[0].unload_settled = false
		"incomplete_controlled_routes": _route_proofs.clear()
		"travel_budget": _route_proof_measurements = {"travel_p95_ms": 35.0, "travel_frames_over_100ms": 0}
		"success":
			for proof_name in REQUIRED_CONTROLLED_ROUTE_PROOFS: _route_proofs[proof_name] = true
			_route_proof_measurements = {"travel_p95_ms": 20.0, "travel_frames_over_100ms": 0}
			_raw = test_raw
			_finalize_acceptance(false, true, true)
			get_tree().quit(0 if _raw.validation.acceptance_passed else 1)
			return
		_:
			push_error("Unknown contract test: %s" % case_name)
			get_tree().quit(2)
			return
	_raw = test_raw
	_finalize_acceptance(false, true, true)
	print("MOY_PERF_CONTRACT_TEST case=", case_name, " acceptance_passed=", _raw.validation.acceptance_passed, " failures=", _raw.validation.failures)
	get_tree().quit(1 if not _raw.validation.acceptance_passed else 0)


func _load_route_proofs(path: String) -> Dictionary:
	if path.is_empty(): return {}
	if not FileAccess.file_exists(path):
		push_warning("Controlled-route proof file is missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or int(parsed.get("schema", 0)) != 1:
		push_warning("Controlled-route proof file is malformed: %s" % path)
		return {}
	if String(parsed.get("commit", "")) != String(_config.get("commit", "")):
		push_warning("Controlled-route proof commit does not match the benchmark source")
		return {}
	var source_hashes: Dictionary = parsed.get("source_hashes", {})
	for source_path in ["res://tools/moy_performance_probe.gd", "res://scripts/city_generator.gd", "res://scripts/moy_ride_train.gd"]:
		if String(source_hashes.get(source_path, "")) != String(_config.get("source_hashes", {}).get(source_path, "")):
			push_warning("Controlled-route proof source hash mismatch: %s" % source_path)
			return {}
	var coverage: Dictionary = parsed.get("coverage", {})
	var result: Dictionary = {}
	for proof_name in REQUIRED_CONTROLLED_ROUTE_PROOFS:
		result[proof_name] = int(parsed.get("warm_traversals", 0)) >= 3 if proof_name == "three_warm_traversals" else bool(coverage.get(proof_name, false))
	_route_proof_measurements = {"travel_p95_ms":parsed.get("travel_p95_ms"),
		"travel_frames_over_100ms":parsed.get("travel_frames_over_100ms")}
	return result

func _parse_config(args: Array) -> Dictionary:
	var cfg := {"run_id": "run1", "duration": DEFAULT_DURATION, "warmup": DEFAULT_WARMUP,
		"resolution": DEFAULT_RESOLUTION, "vsync": DisplayServer.VSYNC_DISABLED,
		"fps_cap": 0, "seed": 20261019, "game_time_hours": 12.0,
		"fov": 70.0, "route": DEFAULT_ROUTE}
	cfg["route_proof_file"] = ""
	for arg in args:
		var arg_text := String(arg)
		if arg_text == "--route":
			cfg.route = ""
			continue
		if arg_text.begins_with("--route="):
			cfg.route = arg_text.trim_prefix("--route=")
			continue
		var pair := arg_text.trim_prefix("--").split("=", false, 1)
		if pair.size() != 2: continue
		match pair[0]:
			"run-id": cfg.run_id = pair[1]
			"route-proof-file": cfg.route_proof_file = pair[1]
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
		{"name":"east_gate_train_hall", "camera":Vector3(-351,-34,-20), "look":Vector3(-351,-45,0), "player":Vector2(-351,0)},
		# P3's performance views are the Moy atlas places translated into world
		# coordinates. The same P2 sampler/settings run these before and after.
		{"name":"market", "camera":Vector3(-550,50,290), "look":Vector3(-670,-45,130), "player":Vector2(-650,130)},
		{"name":"southst", "camera":Vector3(-558.5,-58.2,132), "look":Vector3(-563,-51,205), "player":Vector2(-560,140)},
		{"name":"arcade", "camera":Vector3(-690,-58.2,128), "look":Vector3(-690,-53,205), "player":Vector2(-690,130)},
		{"name":"lamplane", "camera":Vector3(-630,-58.2,172), "look":Vector3(-530,-56,172), "player":Vector2(-600,172)}]
	views.append_array([
		{"name":"oldmoy", "camera":Vector3(-580,35,120), "look":Vector3(-705,-50,-20), "player":Vector2(-718,25)},
		{"name":"wellquarter", "camera":Vector3(-652,60,-160), "look":Vector3(-710,-55,-30), "player":Vector2(-730,-60)},
		{"name":"cinemasq", "camera":Vector3(-714,-56.8,7), "look":Vector3(-725,-57,23), "player":Vector2(-720,8)},
		{"name":"oldhigh", "camera":Vector3(-724,-46,2), "look":Vector3(-709,-48,-50), "player":Vector2(-720,-20)},
		{"name":"oldcourt", "camera":Vector3(-664,-58,-64), "look":Vector3(-694,-58,-31), "player":Vector2(-685,-35)},
		{"name":"oldroofs", "camera":Vector3(-670,-74,-70), "look":Vector3(-705,-98,-40), "player":Vector2(-690,-60)}])
	var requested: Array = String(_config.route).split(",", true)
	for view in views:
		if String(view.name) not in requested: continue
		var p: Vector2 = view.player
		var y := float(_terrain.call("get_mesh_height", p.x, p.y)) + 0.5
		_player.global_position = Vector3(p.x, y, p.y)
		await _sample(camera, String(view.name), view.camera, view.look, p, "stationary view after approach")
	var previous_reload_inventory: Dictionary = {}
	for cycle in 2:
		var cycle_start_state := _stream_state()
		# Return to the protected Crossroads clearing to trigger city unload
		# without entering the open-wasteland encounter zone.
		var away_y := float(_terrain.call("get_mesh_height", 0.0, 0.0))
		_player.global_position = Vector3(0.0, away_y + 0.5, 0.0)
		var started := Time.get_ticks_usec()
		var elapsed := 0.0
		while elapsed < 45.0 and int(_city.get("_moy_active").size()) > 0:
			await get_tree().process_frame
			elapsed = float(Time.get_ticks_usec() - started) / 1000000.0
			_capture_transition_frame("unload_%d" % (cycle+1), int(elapsed*1000.0))
		var unload_deadline := Time.get_ticks_msec() + 45000
		var settled_frames := 0
		var previous_settle_state: Dictionary = {}
		while Time.get_ticks_msec() < unload_deadline and settled_frames < 2:
			await get_tree().process_frame
			await get_tree().physics_frame
			var settle_state := _stream_state()
			var equivalent_actor_state: bool = not previous_settle_state.is_empty() and settle_state.city_actor_group_identities.size() == previous_settle_state.city_actor_group_identities.size()
			var equivalent_node_state: bool = not previous_settle_state.is_empty() and int(settle_state.nodes) == int(previous_settle_state.nodes)
			if int(settle_state.active_packs) == 0 and int(settle_state.requested_packs) == 0 and int(settle_state.pending_exits) == 0 and equivalent_actor_state and equivalent_node_state:
				settled_frames += 1
			else:
				settled_frames = 0
			previous_settle_state = settle_state
		var after_unload := _compact_stream_state(_stream_state())
		var unload_settled := settled_frames >= 2
		var near_y := float(_terrain.call("get_mesh_height", -600.0, 0.0))
		_player.global_position = Vector3(-600.0, near_y + 0.5, 0.0)
		var reload_start := Time.get_ticks_usec()
		var frames := 0
		while frames < 2400 and not _city_control_ready():
			await get_tree().process_frame
			frames += 1
			_capture_transition_frame("reload_%d" % (cycle+1), frames)
		var complete := _city_control_ready()
		var settled_state := _stream_state(true, true)
		var transition := {"phase":"unload_reload", "cycle":cycle+1,
			"before_unload_state":_compact_stream_state(cycle_start_state), "unload_state":after_unload,
			"reload_ms":float(Time.get_ticks_usec()-reload_start)/1000.0, "reload_frames":frames,
			"unload_settled":unload_settled, "unload_settle_frames":settled_frames,
			"ready":complete, "settled_state":_compact_stream_state(settled_state)}
		if not previous_reload_inventory.is_empty():
			transition["settled_node_path_delta_vs_previous_cycle"] = _diff_node_inventories(previous_reload_inventory, settled_state["node_inventory"])
		previous_reload_inventory = settled_state["node_inventory"]
		_raw.transitions.append(transition)
		if not unload_settled: _fail("unload cycle %d did not settle within 45 seconds" % (cycle+1))
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
	camera.make_current()
	camera.force_update_transform()
	if _player and _terrain and body_position != Vector2.ZERO:
		var y := float(_terrain.call("get_mesh_height", body_position.x, body_position.y)) + 0.5
		_player.global_position = Vector3(body_position.x, y, body_position.y)
		var readiness_frames := 0
		while readiness_frames < 2400 and not _city_control_ready():
			await get_tree().process_frame
			readiness_frames += 1
		if not _city_control_ready():
			_fail("local pack/support readiness timed out for view: %s" % label)
			return
	var warmup_started := Time.get_ticks_usec()
	while float(Time.get_ticks_usec() - warmup_started) < float(_config.warmup) * 1000000.0:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
	var frames := PackedFloat64Array()
	var started := Time.get_ticks_usec()
	var previous := started
	while float(Time.get_ticks_usec()-started) < float(_config.duration) * 1000000.0:
		await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var now := Time.get_ticks_usec()
		var sample := _monitor_frame(float(now-previous)/1000.0)
		var body := _player.global_position if _player else Vector3.ZERO
		frames.append(float(sample.frame_ms))
		for key in ["draws", "triangles", "static_mib", "video_mib", "nodes", "physics_objects", "active_packs", "requested_packs", "retained_resources"]:
			var value: Variant = sample[key]
			frames.append(float(value) if value != null else NAN)
		frames.append(body.x); frames.append(body.y); frames.append(body.z)
		previous = now
	var summary := _summarize(label, frames, camera.global_position, target, phase)
	var raw_path := _write_frame_rows(label, phase, camera, target, frames)
	summary["frame_data_path"] = raw_path
	summary["probe_frame_buffer_bytes"] = frames.size() * 8
	_raw.samples.append(summary)
	_write_partial()
	print("MOY_PERF_SAMPLE name=%s frames=%d p50_ms=%.3f p95_ms=%.3f p99_ms=%.3f worst_ms=%.3f draws_peak=%s triangles_peak=%s active_packs=%d" % [label, summary.frames, summary.p50_ms, summary.p95_ms, summary.p99_ms, summary.worst_ms, summary.draws_peak, summary.triangles_peak, summary.active_packs])

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


func _summarize(label: String, frames: PackedFloat64Array, camera_position: Vector3, target: Vector3, phase: String) -> Dictionary:
	var intervals := PackedFloat64Array()
	var draws := PackedFloat64Array()
	var triangles := PackedFloat64Array()
	var static_mem := PackedFloat64Array()
	var video_mem := PackedFloat64Array()
	var nodes := PackedFloat64Array()
	var physics := PackedFloat64Array()
	var over_50: Array[Dictionary] = []
	var over_100: Array[Dictionary] = []
	var frame_count := int(frames.size() / FRAME_WIDTH)
	var buffer_bytes := frames.size() * 8
	var elapsed_ms := 0.0
	for frame_index in frame_count:
		var base := frame_index * FRAME_WIDTH
		var ms := frames[base]
		elapsed_ms += ms
		intervals.append(ms)
		var draws_value := frames[base+1]; var triangles_value := frames[base+2]
		var static_value := frames[base+3]; var video_value := frames[base+4]
		var nodes_value := frames[base+5]; var physics_value := frames[base+6]
		if is_finite(draws_value): draws.append(draws_value)
		if is_finite(triangles_value): triangles.append(triangles_value)
		if is_finite(static_value):
			static_mem.append(static_value)
		if is_finite(video_value): video_mem.append(video_value)
		if is_finite(nodes_value): nodes.append(nodes_value)
		if is_finite(physics_value): physics.append(physics_value)
		if ms > 50.0 or ms > 100.0:
			var frame := {"frame_index":frame_index,"frame_ms":ms,"elapsed_ms":elapsed_ms,
				"position":[frames[base+10],frames[base+11],frames[base+12]],
				"active_packs":int(frames[base+7]),"requested_packs":int(frames[base+8]),"phase":phase}
			if ms > 50.0: over_50.append(frame)
			if ms > 100.0: over_100.append(frame)
	intervals.sort(); draws.sort(); triangles.sort(); static_mem.sort(); video_mem.sort(); physics.sort()
	nodes.sort()
	var result := {"name":label, "phase":phase, "camera":[camera_position.x,camera_position.y,camera_position.z], "target":[target.x,target.y,target.z],
		"fov":float(_config.fov), "camera_far":1800.0, "frames":frame_count, "duration_s":float(_config.duration),
		"p50_ms":_percentile(intervals,0.50), "p95_ms":_percentile(intervals,0.95),
		"p99_ms":_percentile(intervals,0.99), "worst_ms":intervals[intervals.size()-1] if not intervals.is_empty() else null,
		"frames_over_50ms":over_50.size(), "frames_over_100ms":over_100.size(),
		"over_50ms":over_50, "over_100ms":over_100,
		"draws_distribution":_distribution(draws), "draws_peak":draws[draws.size()-1] if not draws.is_empty() else null,
		"triangles_distribution":_distribution(triangles), "triangles_peak":triangles[triangles.size()-1] if not triangles.is_empty() else null,
		"static_mib_distribution_observed":_distribution(static_mem),
		"static_memory_observer_accounting":{"adjustment_applied":false,
			"packed_frame_payload_bytes_exact":buffer_bytes,
			"packed_array_capacity_bytes":null,
			"retained_telemetry_records":_telemetry_record_counts(),
			"other_probe_storage":"activation/release telemetry and inventories are retained; observer allocations are not subtracted"},
		"video_mib_distribution":_distribution(video_mem), "nodes_distribution":_distribution(nodes),
		"physics_objects_distribution":_distribution(physics), "active_packs":_active_packs(),
		"requested_packs":_requested_packs(), "retained_resources":_retained_resources(),
		"raw_frame_buffer_payload_bytes_peak":buffer_bytes}
	return result


func _telemetry_record_counts() -> Dictionary:
	if _city == null: return {"activation_stages":0,"activation_frames":0,"release_stages":0}
	return {"activation_stages":(_city.get("_moy_stage_records") as Array).size(),
		"activation_frames":(_city.get("_moy_activation_frame_records") as Array).size(),
		"release_stages":(_city.get("_moy_release_records") as Array).size()}

func _write_frame_rows(label: String, phase: String, camera: Camera3D, target: Vector3, frames: PackedFloat64Array) -> String:
	var path := _output_path.trim_suffix(".json") + ".%s.frames.jsonl" % label
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_fail("could not write raw frame file: %s" % path)
		return ""
	var count := int(frames.size() / FRAME_WIDTH)
	var elapsed_ms := 0.0
	for frame_index in count:
		var base := frame_index * FRAME_WIDTH
		elapsed_ms += frames[base]
		file.store_line(JSON.stringify({"sample":label,"frame_index":frame_index,"phase":phase,
			"frame_ms":frames[base],"elapsed_ms":elapsed_ms,"camera":[camera.global_position.x,camera.global_position.y,camera.global_position.z],
			"target":[target.x,target.y,target.z],"fov":float(_config.fov),"camera_far":camera.far,
			"draws":_frame_number(frames[base+1]),"triangles":_frame_number(frames[base+2]),
			"static_mib_observed":_frame_number(frames[base+3]),"video_mib":_frame_number(frames[base+4]),
			"nodes":_frame_number(frames[base+5]),"physics_objects":_frame_number(frames[base+6]),
			"active_packs":_frame_number(frames[base+7]),"requested_packs":_frame_number(frames[base+8]),
			"retained_resources":_frame_number(frames[base+9]),"player_position":[frames[base+10],frames[base+11],frames[base+12]]}))
	file.close()
	return path


func _frame_number(value: float) -> Variant:
	return value if is_finite(value) else null


func _distribution(values: PackedFloat64Array) -> Variant:
	if values.is_empty(): return null
	return {"count":values.size(), "min":values[0], "p50":_percentile(values,0.5), "p95":_percentile(values,0.95), "p99":_percentile(values,0.99), "max":values[values.size()-1]}

func _percentile(values: PackedFloat64Array, quantile: float) -> Variant:
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

func _stream_state(include_paths: bool = false, include_actor_paths: bool = false) -> Dictionary:
	var class_counts: Dictionary = {}
	var actor_ids: Array[String] = []
	var moy_node_count: Array[int] = [0]
	if _city: _collect_lifetime_state(_city, class_counts, actor_ids, moy_node_count)
	actor_ids.sort()
	var tree := get_tree()
	var root_node_count := _count_nodes(tree.root) if tree != null else -1
	var global_class_counts: Dictionary = {}
	var city_actor_ids: Array[String] = []
	if tree != null:
		_collect_global_class_counts(tree.root, global_class_counts)
		if _city: _collect_city_actor_ids(_city, city_actor_ids)
	city_actor_ids.sort()
	var result := {"active_packs":_active_packs(), "requested_packs":_requested_packs(),
		"nodes":root_node_count, "moy_nodes":moy_node_count[0],
		"pending_exits":int(_city.get("_moy_unload_pending").size()) if _city else -1, "class_counts":class_counts,
		"global_class_counts":global_class_counts, "actor_group_identities":actor_ids,
		"city_actor_group_identities":city_actor_ids,
		"static_mib":_monitor_mib(Performance.MEMORY_STATIC),
		"retained_manifest_refs":_retained_resources(), "actors_ready":bool(_city.call("moy_actors_ready")) if _city and _city.has_method("moy_actors_ready") else false}
	if _city:
		var pending_requests: Array[Dictionary] = []
		for path_variant in _city.get("_moy_requested").keys():
			var path := String(path_variant)
			var record: Dictionary = _city.get("_moy_requested")[path_variant]
			pending_requests.append({"path":path.get_file(),
				"loader_status":ResourceLoader.load_threaded_get_status(path),
				"age_ms":float(Time.get_ticks_usec() - int(record.get("requested_usec", Time.get_ticks_usec()))) / 1000.0})
		result["pending_request_details"] = pending_requests
	if include_paths and tree != null:
		var node_inventory: Dictionary = {}
		_collect_node_inventory(tree.root, node_inventory)
		result["node_inventory"] = node_inventory
	if include_actor_paths and tree != null:
		var actor_inventory: Dictionary = {}
		_collect_actor_inventory(tree.root, actor_inventory, false)
		result["actor_node_inventory"] = actor_inventory
	return result

func _compact_stream_state(state: Dictionary) -> Dictionary:
	var compact := state.duplicate(true)
	compact.erase("node_inventory")
	return compact

func _diff_node_inventories(before: Dictionary, after: Dictionary) -> Dictionary:
	var added: Dictionary = {}
	var removed: Dictionary = {}
	for path in after:
		if not before.has(path): added[path] = after[path]
	for path in before:
		if not after.has(path): removed[path] = before[path]
	return {"added_count":added.size(), "removed_count":removed.size(), "added":added, "removed":removed}

func _collect_lifetime_state(node: Node, class_counts: Dictionary, actor_ids: Array[String], moy_nodes: Array[int]) -> void:
	class_counts[node.get_class()] = int(class_counts.get(node.get_class(), 0)) + 1
	moy_nodes[0] += 1
	for group_name in node.get_groups():
		if String(group_name).contains("actor") or String(group_name).contains("resident") or String(group_name).contains("vendor") or String(group_name).contains("npc"):
			actor_ids.append("%s|%s|%s" % [String(group_name), str(node.get_path()), node.get_class()])
	for child in node.get_children(): _collect_lifetime_state(child, class_counts, actor_ids, moy_nodes)

func _collect_city_actor_ids(node: Node, result: Array[String]) -> void:
	if node.is_in_group("city_npcs") or node.is_in_group("moy_actors") or node.is_in_group("moy_vendors"):
		result.append("%s|%s" % [str(node.get_path()), node.get_class()])
	for child in node.get_children(): _collect_city_actor_ids(child, result)

func _collect_global_class_counts(node: Node, counts: Dictionary) -> void:
	counts[node.get_class()] = int(counts.get(node.get_class(), 0)) + 1
	for child in node.get_children(): _collect_global_class_counts(child, counts)

func _collect_node_inventory(node: Node, inventory: Dictionary) -> void:
	var owner_path := String(node.owner.get_path()) if node.owner != null else ""
	var position: Variant = null
	if node is Node3D:
		var node_position := (node as Node3D).global_position
		position = [node_position.x, node_position.y, node_position.z]
	inventory[String(node.get_path())] = {"name":String(node.name), "class":node.get_class(),
		"owner":owner_path, "groups":node.get_groups(), "position":position}
	for child in node.get_children(): _collect_node_inventory(child, inventory)

func _collect_actor_inventory(node: Node, inventory: Dictionary, inside_actor: bool) -> void:
	var actor_root := inside_actor
	for group_name in node.get_groups():
		var group_text := String(group_name)
		if group_text.contains("actor") or group_text.contains("resident") or group_text.contains("vendor") or group_text.contains("npc"):
			actor_root = true
			break
	if actor_root:
		var owner_path := String(node.owner.get_path()) if node.owner != null else ""
		var position: Variant = null
		if node is Node3D:
			var node_position := (node as Node3D).global_position
			position = [node_position.x, node_position.y, node_position.z]
		inventory[String(node.get_path())] = {"name":String(node.name), "class":node.get_class(), "owner":owner_path,
			"groups":node.get_groups(), "position":position}
	for child in node.get_children(): _collect_actor_inventory(child, inventory, actor_root)

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

func _write_partial() -> void:
	if _raw.is_empty(): _raw = {"schema":1, "config":_config, "samples":[], "transitions":[], "activation":[], "errors":[]}
	var absolute := ProjectSettings.globalize_path(_output_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var file := FileAccess.open(_output_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_raw, "\t"))
		file.close()
