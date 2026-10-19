extends Node

class FixtureTerrain:
	extends Node
	func get_mesh_height(_x:float,_z:float)->float: return 0.0

## Headless walk-surface audit. World geometry is read from collision shapes;
## visual-only meshes are read separately so the checks do not confuse a
## pretty floor with a floor a character can stand on.
const CHECKS := ["overlap","buried","water","reach","trap","headroom","underside","solid","guard"]
const DEFAULT_AREA := Vector4(-790.0,-210.0,-330.0,210.0)
const WALK_GRID_STEP := 0.5
const OVERLAP_GRID_STEP := 0.25
const WALKER_RADIUS := 0.45
const WALKER_HEIGHT := 2.0
const STEP_HEIGHT := 0.7 # Matches Player.PROP_STEP_MAX_HEIGHT.
const COLUMN_HIT_LIMIT := 24
var _area := DEFAULT_AREA
var _only_checks: Array[String] = []
var _findings: Array[Dictionary] = []
var _timings: Dictionary = {}
var _world: Node3D
var _terrain: Node
var _static_mask := 0
var _dynamic_excludes:Array[RID] = []
var _walk_grid: Dictionary = {}
var _walk_cells: Array[Dictionary] = []
var _overlap_grid: Dictionary = {}
var _walkable_slope_dot := 0.70710678
var _grid_step := WALK_GRID_STEP
var _graph: Dictionary = {}
var _reverse_graph: Dictionary = {}
var _cell_by_id: Dictionary = {}
var _reachable: Dictionary = {}
var _reached_buckets:Dictionary = {}
var _reverse_reachable: Dictionary = {}
var _clearance_cache: Dictionary = {}
var _debug_key := Vector2i(999999, 999999)
var _cli_opts:Dictionary = {}
var _player_start: Vector3 = Vector3.ZERO
var _reach_start_position: Vector3 = Vector3.ZERO
var _reach_start_cell: Dictionary = {}
var _broken_reach_links: Array[Dictionary] = []
var _sample_stats := {"grid_step_m": WALK_GRID_STEP, "columns": 0, "walk_cells": 0}
var _mesh_buckets:Dictionary = {}
var _mesh_bounds:Dictionary = {}
var _mesh_face_cache:Dictionary = {}
var _body_collision_shapes:Dictionary = {}
var _suite_started_usec:int = 0

func _ready() -> void:
	if bool(get_meta("library_mode", false)): return
	call_deferred("_run")

func _run() -> void:
	_suite_started_usec = Time.get_ticks_usec()
	var opts := _parse_options(OS.get_cmdline_user_args())
	_cli_opts = opts
	if opts.has("area"):
		var values := String(opts.area).split(",")
		if values.size()==4: _area=Vector4(float(values[0]),float(values[1]),float(values[2]),float(values[3]))
	if opts.has("checks"):
		for check in String(opts.checks).split(","): _only_checks.append(check)
	if opts.has("debug-cell"):
		var dv := String(opts["debug-cell"]).split(",")
		if dv.size() == 2: _debug_key = Vector2i(roundi(float(dv[0]) / WALK_GRID_STEP), roundi(float(dv[1]) / WALK_GRID_STEP))
	if opts.has("fixtures"):
		await _run_fixture_suite()
		return
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	# The audit needs only Moy, its terrain and the player physics settings.
	# Prune other kingdoms and the Ohio village before entering the tree so
	# their unrelated procedural meshes do not run in the headless renderer.
	main.set_script(null)
	var keep := ["WorldEnvironment","DirectionalLight3D","Terrain","WesternCity","Player"]
	for child in main.get_children():
		if child.name not in keep: main.remove_child(child); child.free()
	var player:=main.get_node_or_null("Player") as Node3D
	if player!=null:
		player.position=Vector3((_area.x+_area.z)*0.5,-58.0,(_area.y+_area.w)*0.5)
		player.set_physics_process(false)
		_player_start = player.position
		_walkable_slope_dot = cos(player.floor_max_angle)
	get_tree().root.add_child(main); get_tree().current_scene=main; _world=main
	await get_tree().process_frame
	await LoadingScreen.wait_for_world_builds()
	_terrain=main.get_node_or_null("Terrain")
	var city:=main.get_node_or_null("WesternCity")
	var deadline:=Time.get_ticks_msec()+240000
	while city!=null and city.has_method("moy_packs_ready") and not city.moy_packs_ready() and Time.get_ticks_msec()<deadline:
		await get_tree().create_timer(0.25).timeout
	await get_tree().physics_frame
	var meshes:Array[MeshInstance3D]=[]; var shapes:Array[CollisionShape3D]=[]; _collect(main,meshes,shapes)
	var grid_started := Time.get_ticks_usec()
	var bounds := _scene_y_bounds(shapes)
	_walk_grid = _build_walk_grid(WALK_GRID_STEP, bounds.x, bounds.y)
	_grid_step = WALK_GRID_STEP
	_sample_stats["columns"] = _grid_column_count(WALK_GRID_STEP)
	_sample_stats["walk_cells"] = _walk_cells.size()
	_timings["walk_grid"] = (Time.get_ticks_usec() - grid_started) / 1000.0
	var graph_started := Time.get_ticks_usec()
	_build_reach_graph(main)
	_timings["reach_graph"] = (Time.get_ticks_usec() - graph_started) / 1000.0
	if opts.has("reach-map"): _print_reach_map(String(opts["reach-map"]))
	if opts.has("cell-probe"): _print_cell_probe(String(opts["cell-probe"]))
	for check in CHECKS:
		if not _only_checks.is_empty() and check not in _only_checks: continue
		var started:=Time.get_ticks_usec()
		match check:
			"overlap": _check_overlap(bounds.x, bounds.y)
			"buried": _check_buried()
			"water": _check_water(main)
			"reach": _check_reach(main)
			"trap": _check_traps(main)
			"headroom": _check_headroom()
			"underside": _check_underside(meshes,shapes)
			"solid": _check_solid(meshes,shapes)
			"guard": _check_guard()
		_timings[check]=(Time.get_ticks_usec()-started)/1000.0
	_write_report(String(opts.get("kingdom","moy")),String(opts.get("date","2026-10-18")))
	print("WORLD_CHECKS findings=",_findings.size()," elapsed_ms=",Time.get_ticks_usec()-_suite_started_usec," timings_ms=",_timings)
	get_tree().quit(1 if _has_blocking_finding() else 0)

func _print_cell_probe(spec:String)->void:
	# --cell-probe=x,z[;x,z...]: every walk cell in that grid column, bottom to top.
	for point in spec.split(";"):
		var v := point.split(",")
		if v.size() != 2: continue
		var key := Vector2i(roundi(float(v[0]) / _grid_step), roundi(float(v[1]) / _grid_step))
		print("WORLD_CELL_PROBE column ", float(key.x) * _grid_step, ",", float(key.y) * _grid_step)
		var cells:Array = _walk_grid.get(key, [])
		cells.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.y) < float(b.y))
		for cell in cells:
			var head_hit := ""
			var head_query := PhysicsRayQueryParameters3D.create(cell.position + Vector3.UP * 0.05, cell.position + Vector3.UP * (WALKER_HEIGHT - 0.05), _static_mask)
			head_query.exclude = _dynamic_excludes.duplicate()
			head_query.exclude.append((cell.body as CollisionObject3D).get_rid())
			var head_result := get_viewport().world_3d.direct_space_state.intersect_ray(head_query)
			if not head_result.is_empty(): head_hit = "%s at +%.2f" % [String((head_result.collider as Node).name), float(head_result.position.y) - float(cell.y)]
			print("  y=%.3f reached=%s clear=%s head=%s body=%s shape=%s support=%.2f" % [float(cell.y), _reachable.has(String(cell.id)), _cell_clearance(cell), head_hit, String(cell.body.name), String(cell.get("shape_name","")), float(cell.get("support_width", INF))])

func _print_reach_map(spec:String)->void:
	# --reach-map=x0,z0,x1,z1,y0,y1: one character per walk-grid cell whose height
	# lies in [y0, y1]: R reached from a start, u not reached, . no walk cell.
	# Rows run along z, columns along x.
	var v := spec.split(",")
	if v.size() != 6: return
	var x0 := float(v[0]); var z0 := float(v[1]); var x1 := float(v[2]); var z1 := float(v[3]); var y0 := float(v[4]); var y1 := float(v[5])
	print("WORLD_REACH_MAP x ", x0, "..", x1, " z ", z0, "..", z1, " y ", y0, "..", y1, " step ", _grid_step)
	var z := z0
	while z <= z1 + 0.001:
		var row := ""
		var x := x0
		while x <= x1 + 0.001:
			var key := Vector2i(roundi(x / _grid_step), roundi(z / _grid_step))
			var mark := "."
			for cell in _walk_grid.get(key, []):
				if float(cell.y) < y0 or float(cell.y) > y1: continue
				mark = "R" if _reachable.has(String(cell.id)) else "u"
				if mark == "R": break
			row += mark
			x += _grid_step
		print("WORLD_REACH_ROW %7.1f %s" % [z, row])
		z += _grid_step

func _parse_options(args:PackedStringArray)->Dictionary:
	var result:Dictionary={}
	for arg in args:
		if String(arg).begins_with("--") and String(arg).contains("="):
			var pair:=String(arg).trim_prefix("--").split("=",false,1); result[pair[0]]=pair[1]
	return result

func _collect(node:Node,meshes:Array[MeshInstance3D],shapes:Array[CollisionShape3D])->void:
	if node is MeshInstance3D and (node as Node3D).visible: meshes.append(node as MeshInstance3D)
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled: shapes.append(node as CollisionShape3D)
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		if body is StaticBody3D or body is AnimatableBody3D:
			_static_mask |= body.collision_layer
	for child in node.get_children(): _collect(child,meshes,shapes)

func _scene_y_bounds(shapes:Array[CollisionShape3D])->Vector2:
	var low := -120.0
	var high := 320.0
	for shape in shapes:
		if shape.shape == null: continue
		var box := _world_aabb(shape)
		low = minf(low, box.position.y - 2.0)
		high = maxf(high, box.end.y + 2.0)
	return Vector2(low, high)

func _grid_column_count(step:float)->int:
	var x_count := int(ceil((_area.z - _area.x) / step)) + 1
	var z_count := int(ceil((_area.w - _area.y) / step)) + 1
	return x_count * z_count

func _build_walk_grid(step:float, low:float, high:float, candidate_columns:Variant = null)->Dictionary:
	var grid:Dictionary = {}
	var cells:Array[Dictionary] = []
	var x_min := int(ceil(_area.x / step))
	var x_max := int(floor(_area.z / step))
	var z_min := int(ceil(_area.y / step))
	var z_max := int(floor(_area.w / step))
	_dynamic_excludes.clear()
	for node in _walk(_world):
		if node is CollisionObject3D and not (node is StaticBody3D) and not (node is AnimatableBody3D):
			_dynamic_excludes.append((node as CollisionObject3D).get_rid())
	var space := get_viewport().world_3d.direct_space_state
	for ix in range(x_min, x_max + 1):
		var x := float(ix) * step
		for iz in range(z_min, z_max + 1):
			if candidate_columns != null and not candidate_columns.has(Vector2i(ix,iz)): continue
			var z := float(iz) * step
			var from := Vector3(x, high, z)
			var to := Vector3(x, low, z)
			var excluded := _dynamic_excludes.duplicate()
			var seen_heights:Dictionary = {}
			var ray_from := from
			for _hit_index in COLUMN_HIT_LIMIT:
				var query := PhysicsRayQueryParameters3D.create(ray_from, to, _static_mask, excluded)
				query.hit_back_faces = true
				var hit := space.intersect_ray(query)
				if hit.is_empty(): break
				var body := hit.get("collider") as CollisionObject3D
				if body == null: break
				var rid := body.get_rid()
				if rid in excluded: break
				# A glass rail or other box top narrower than the walker is not a surface to stand on: carry on down
				# through this body to what it stands on (a balustrade must not hide its escalator belt).
				if _hit_is_thin_box_top(body, hit):
					ray_from = (hit.position as Vector3) + Vector3.DOWN * 0.03
					continue
				excluded.append(rid)
				var normal:Vector3 = hit.normal
				if normal.y < _walkable_slope_dot: continue
				var position:Vector3 = hit.position
				var height_key := "%d:%d" % [body.get_instance_id(), roundi(position.y * 50.0)]
				if seen_heights.has(height_key): continue
				seen_heights[height_key] = true
				var key := Vector2i(ix, iz)
				var shape_name := ""
				var support_width := INF
				var shape_index := int(hit.get("shape", -1))
				if shape_index >= 0:
					var shape_owner := body.shape_owner_get_owner(body.shape_find_owner(shape_index))
					if shape_owner is CollisionShape3D:
						var collision_shape := shape_owner as CollisionShape3D
						shape_name = collision_shape.get_class()
						if collision_shape.shape is BoxShape3D: shape_name = "box %.2f x %.2f x %.2f at local y %.2f" % [(collision_shape.shape as BoxShape3D).size.x, (collision_shape.shape as BoxShape3D).size.y, (collision_shape.shape as BoxShape3D).size.z, collision_shape.position.y]
						elif collision_shape.shape != null: shape_name = collision_shape.shape.get_class()
						if collision_shape.shape is BoxShape3D:
							var box_shape := collision_shape.shape as BoxShape3D
							var axes:Array[Vector3] = [collision_shape.global_transform.basis.x, collision_shape.global_transform.basis.y, collision_shape.global_transform.basis.z]
							var dims:Array[float] = [box_shape.size.x, box_shape.size.y, box_shape.size.z]
							var top_axis := 0
							var best_alignment := -1.0
							for axis_index in 3:
								var alignment := absf(axes[axis_index].normalized().dot(normal))
								if alignment > best_alignment:
									best_alignment = alignment
									top_axis = axis_index
							var widths:Array[float] = []
							for axis_index in 3:
								if axis_index != top_axis: widths.append(dims[axis_index] * axes[axis_index].length())
							support_width = minf(widths[0], widths[1])
				var cell := {"key": key, "x": x, "z": z, "y": position.y, "position": position, "normal": normal, "body": body, "body_path": str(body.get_path()), "shape_name": shape_name, "support_width": support_width, "id": _cell_id(key, position.y, body)}
				if not grid.has(key): grid[key] = []
				grid[key].append(cell)
				cells.append(cell)
		if (ix-x_min) % 200 == 0: print("WORLD_CHECKS grid_columns=", ix-x_min, "/", x_max-x_min+1, " cells=", cells.size())
	_walk_cells = _apply_radius_filter(cells, grid, step)
	var filtered:Dictionary = {}
	for cell in _walk_cells:
		var key:Vector2i = cell.key
		if not filtered.has(key): filtered[key] = []
		filtered[key].append(cell)
	return filtered

func _hit_is_thin_box_top(body:CollisionObject3D, hit:Dictionary)->bool:
	var shape_index := int(hit.get("shape", -1))
	if shape_index < 0: return false
	var shape_owner := body.shape_owner_get_owner(body.shape_find_owner(shape_index))
	if not (shape_owner is CollisionShape3D) or not ((shape_owner as CollisionShape3D).shape is BoxShape3D): return false
	var collision_shape := shape_owner as CollisionShape3D
	var box_shape := collision_shape.shape as BoxShape3D
	var axes:Array[Vector3] = [collision_shape.global_transform.basis.x, collision_shape.global_transform.basis.y, collision_shape.global_transform.basis.z]
	var dims:Array[float] = [box_shape.size.x, box_shape.size.y, box_shape.size.z]
	var top_axis := 0
	var best_alignment := -1.0
	for axis_index in 3:
		var alignment := absf(axes[axis_index].normalized().dot(hit.normal))
		if alignment > best_alignment:
			best_alignment = alignment
			top_axis = axis_index
	var widths:Array[float] = []
	for axis_index in 3:
		if axis_index != top_axis: widths.append(dims[axis_index] * axes[axis_index].length())
	return minf(widths[0], widths[1]) < WALKER_RADIUS

func _apply_radius_filter(cells:Array[Dictionary], grid:Dictionary, step:float)->Array[Dictionary]:
	var result:Array[Dictionary] = []
	var offsets:Array[Vector2i] = [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]
	for cell in cells:
		if cell.key == _debug_key:
			var present_report := ""
			for offset in offsets:
				var neighbour_key_dbg:Vector2i = cell.key + offset
				present_report += "%s:%s " % [offset, grid.has(neighbour_key_dbg) and _has_nearby_height(grid[neighbour_key_dbg], float(cell.y), STEP_HEIGHT)]
			print("WORLD_DEBUG_CELL y=%.3f body=%s neighbours %s ray_support=%s" % [float(cell.y), String(cell.body.name), present_report, _supported_at_walker_radius(cell, grid, step)])
		var supported := true
		for offset in offsets:
			var neighbour_key:Vector2i = cell.key + offset
			if not grid.has(neighbour_key) or not _has_nearby_height(grid[neighbour_key], float(cell.y), STEP_HEIGHT):
				supported = false
				break
		if supported:
			result.append(cell)
		elif step > 0.4 and _supported_at_walker_radius(cell, grid, step):
			result.append(cell)
	return result

func _supported_at_walker_radius(cell:Dictionary, grid:Dictionary, step:float)->bool:
	# The grid test asks for a walkable neighbour 0.5 m away on every side, so a
	# 1.1 m belt (an escalator lane) keeps at most one borderline column. Cells that
	# fail it narrowly are tested again at the walker's real radius, 0.45 m.
	var present := 0
	for offset in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
		var neighbour_key:Vector2i = cell.key + offset
		if grid.has(neighbour_key) and _has_nearby_height(grid[neighbour_key], float(cell.y), STEP_HEIGHT): present += 1
	if present < 1: return false
	var state := get_viewport().world_3d.direct_space_state
	var base:Vector3 = cell.position
	for offset in [Vector3(WALKER_RADIUS,0.0,0.0),Vector3(-WALKER_RADIUS,0.0,0.0),Vector3(0.0,0.0,WALKER_RADIUS),Vector3(0.0,0.0,-WALKER_RADIUS)]:
		var from:Vector3 = base + offset + Vector3.UP * 0.35
		var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * (STEP_HEIGHT + 0.35 + 0.3), _static_mask)
		query.exclude = _dynamic_excludes
		query.hit_back_faces = true
		var hit := state.intersect_ray(query)
		if hit.is_empty(): return false
		if (hit.normal as Vector3).y < _walkable_slope_dot: return false
		if absf(float(hit.position.y) - float(base.y)) > STEP_HEIGHT: return false
	return true

func _has_nearby_height(cells:Array, target_height:float, tolerance:float)->bool:
	for cell in cells:
		if absf(float(cell.y) - target_height) <= tolerance: return true
	return false

func _cell_id(key:Vector2i, height:float, body:CollisionObject3D)->String:
	return "%d,%d:%.2f:%s" % [key.x, key.y, height, str(body.get_path())]

func _inside_area(point:Vector3)->bool:
	return point.x>=_area.x and point.x<=_area.z and point.z>=_area.y and point.z<=_area.w

func _record(check:String,node:Node,point:Vector3,detail:String,blocking:=false,other:Node=null,kind:String="")->void:
	_findings.append({"check_id":check,"kind":kind if not kind.is_empty() else check,"blocking":blocking,"position":{"x":point.x,"y":point.y,"z":point.z},"node_path":str(node.get_path()) if node!=null else "", "other_path":str(other.get_path()) if other!=null else "", "detail":detail})

func _world_aabb(shape:CollisionShape3D)->AABB:
	var debug_mesh:=shape.shape.get_debug_mesh()
	if debug_mesh==null: return AABB(shape.global_position,Vector3.ZERO)
	return shape.global_transform*debug_mesh.get_aabb()

func _node_world_aabb(node:Node3D)->AABB:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		if mesh.mesh != null: return mesh.global_transform * mesh.mesh.get_aabb()
	if node is CollisionShape3D: return _world_aabb(node as CollisionShape3D)
	var found := false
	var bounds := AABB()
	var stack:Array[Node] = [node]
	while not stack.is_empty():
		var current:Node = stack.pop_back()
		if current is MeshInstance3D or current is CollisionShape3D:
			var part := _world_aabb(current as CollisionShape3D) if current is CollisionShape3D else _node_world_aabb(current as Node3D)
			if not found: bounds = part; found = true
			else: bounds = bounds.merge(part)
		for child in current.get_children(): stack.append(child)
	return bounds if found else AABB(node.global_position, Vector3.ZERO)

func _body_has_meta(node:Node, key:StringName)->bool:
	var current:Node = node
	while current != null:
		if current.has_meta(key) and bool(current.get_meta(key)): return true
		current = current.get_parent()
	return false

func _collision_is_decorative(node:Node)->bool:
	var current:Node = node
	while current != null:
		if String(current.get_meta("collision_policy", "")) == "decorative": return true
		current = current.get_parent()
	return false

func _emit_cell_clusters(check:String, cells:Array[Dictionary], detail_template:String, blocking:bool, override_node:Node=null)->void:
	var remaining:Dictionary = {}
	var seed_ids:Array = []
	for cell in cells:
		var body_path := str(override_node.get_path()) if override_node != null else String(cell.body_path)
		var id := "%s|%s" % [body_path, str(cell.key)]
		if not remaining.has(id): seed_ids.append(id); remaining[id] = cell
	var seed_index := 0
	while not remaining.is_empty():
		while seed_index < seed_ids.size() and not remaining.has(seed_ids[seed_index]): seed_index += 1
		if seed_index >= seed_ids.size(): break
		var seed_id:String = seed_ids[seed_index]
		seed_index += 1
		var seed:Dictionary = remaining[seed_id]
		var queue:Array[Dictionary] = [seed]
		var queue_index := 0
		remaining.erase(seed_id)
		var cluster:Array[Dictionary] = []
		while queue_index < queue.size():
			var current:Dictionary = queue[queue_index]
			queue_index += 1
			cluster.append(current)
			for dx in range(-1, 2):
				for dz in range(-1, 2):
					var next_key:Vector2i = current.key + Vector2i(dx, dz)
					var body_path := str(override_node.get_path()) if override_node != null else String(current.body_path)
					var next_id := "%s|%s" % [body_path, str(next_key)]
					if remaining.has(next_id):
						queue.append(remaining[next_id])
						remaining.erase(next_id)
		var center := Vector3.ZERO
		for cell in cluster: center += cell.position
		center /= float(cluster.size())
		var source:Node = override_node if override_node != null else seed.body
		var detail := detail_template % cluster.size() if "%" in detail_template else detail_template
		_record(check, source, center, detail, blocking)

func _check_overlap(low:float, high:float)->void:
	var base_grid := _walk_grid
	var base_cells := _walk_cells
	var candidates:Dictionary = {}
	for key in base_grid:
		var column:Array = base_grid[key]
		var possible := false
		for i in column.size():
			for j in range(i+1,column.size()):
				if column[i].body != column[j].body and absf(float(column[i].y)-float(column[j].y)) <= 0.02 and not _same_walk_run(column[i].body,column[j].body):
					possible = true; break
			if possible: break
		if possible:
			for dx in range(-1,2):
				for dz in range(-1,2):
					if not base_grid.has(key+Vector2i(dx,dz)): continue
					for fx in range(-1,2):
						for fz in range(-1,2): candidates[(key+Vector2i(dx,dz))*2+Vector2i(fx,fz)] = true
	var started := Time.get_ticks_usec()
	_overlap_grid = _build_walk_grid(OVERLAP_GRID_STEP, low, high, candidates)
	var overlap_cells := _walk_cells
	_walk_grid = base_grid
	_walk_cells = base_cells
	_timings["overlap_grid"] = (Time.get_ticks_usec() - started) / 1000.0
	var contacts:Dictionary = {}
	for key in _overlap_grid:
		var at_column:Array = _overlap_grid[key]
		for i in at_column.size():
			for j in range(i + 1, at_column.size()):
				var a:Dictionary = at_column[i]
				var b:Dictionary = at_column[j]
				if a.body == b.body or absf(float(a.y) - float(b.y)) > 0.02: continue
				if _same_walk_run(a.body, b.body): continue
				var a_path:String = String(a.body_path)
				var b_path:String = String(b.body_path)
				var first:Dictionary = a if a_path < b_path else b
				var second:Dictionary = b if a_path < b_path else a
				var pair_key := "%s||%s" % [first.body_path, second.body_path]
				if not contacts.has(pair_key):
					var terrain_pair := _is_terrain_body(first.body) or _is_terrain_body(second.body)
					contacts[pair_key] = {"a": first.body, "b": second.body, "cells": {}, "terrain_pair": terrain_pair}
				contacts[pair_key].cells[key] = Vector3(a.x, (a.y + b.y) * 0.5, a.z)
	for pair_key in contacts:
		var contact:Dictionary = contacts[pair_key]
		var remaining:Dictionary = contact.cells.duplicate()
		var seed_keys:Array = remaining.keys()
		var seed_index := 0
		while not remaining.is_empty():
			while seed_index < seed_keys.size() and not remaining.has(seed_keys[seed_index]): seed_index += 1
			if seed_index >= seed_keys.size(): break
			var seed:Vector2i = seed_keys[seed_index]
			seed_index += 1
			var queue:Array[Vector2i] = [seed]
			var queue_index := 0
			var cluster:Array[Vector3] = []
			remaining.erase(seed)
			while queue_index < queue.size():
				var current:Vector2i = queue[queue_index]
				queue_index += 1
				cluster.append(contact.cells[current])
				for dx in range(-1, 2):
					for dz in range(-1, 2):
						var next := current + Vector2i(dx, dz)
						if remaining.has(next):
							remaining.erase(next)
							queue.append(next)
			var center := Vector3.ZERO
			for point in cluster: center += point
			center /= float(cluster.size())
			if contact.terrain_pair:
				_record("overlap", contact.a, center, "flush with terrain: walk cells share height within 0.02 m (%d cells)" % cluster.size(), true, contact.b, "flush_with_terrain")
			else:
				_record("overlap", contact.a, center, "walk cells on different bodies share height within 0.02 m (%d cells)" % cluster.size(), true, contact.b, "surface_overlap")
	if overlap_cells.is_empty(): _sample_stats["overlap_walk_cells"] = 0
	else: _sample_stats["overlap_walk_cells"] = overlap_cells.size()

func _same_walk_run(a:CollisionObject3D, b:CollisionObject3D)->bool:
	return a.has_meta("walk_run_id") and b.has_meta("walk_run_id") and a.get_meta("walk_run_id") == b.get_meta("walk_run_id")

func _is_terrain_body(body:CollisionObject3D)->bool:
	var current:Node = body
	while current != null:
		if current == _terrain or String(current.name).to_lower() == "terrain": return true
		current = current.get_parent()
	return false

func _check_buried()->void:
	if _terrain==null or not _terrain.has_method("get_mesh_height"): return
	var buried:Array[Dictionary] = []
	for cell in _walk_cells:
		var ground := float(_terrain.get_mesh_height(float(cell.x), float(cell.z)))
		if ground > float(cell.y) + 0.02:
			buried.append(cell)
	_emit_cell_clusters("buried", buried, "terrain stands above walk surface (%d samples)", true)

func _check_water(root:Node)->void:
	for node in _walk(root):
		if not node.has_meta("water_surface_y"): continue
		var p:=node as Node3D
		if p==null or not _inside_area(p.global_position): continue
		var water_y:=float(node.get_meta("water_surface_y"))
		var water_mesh:MeshInstance3D = null
		for child in _walk(node):
			if child is MeshInstance3D: water_mesh = child as MeshInstance3D; break
		if water_mesh == null or not _uses_shared_water_material(water_mesh):
			_record("water",node,p.global_position,"water mesh does not use the shared water shader material",true)
		if _terrain==null or not _terrain.has_method("get_mesh_height") or water_mesh == null: continue
		var bounds := _node_world_aabb(water_mesh)
		var samples:Array[Vector2] = []
		var step := 0.5
		var x0 := bounds.position.x - step; var x1 := bounds.end.x + step
		var z0 := bounds.position.z - step; var z1 := bounds.end.z + step
		var nx := maxi(1, int(ceil((x1-x0)/step))); var nz := maxi(1, int(ceil((z1-z0)/step)))
		for i in range(nx+1):
			var x := lerpf(x0,x1,float(i)/float(nx)); samples.append(Vector2(x,z0)); samples.append(Vector2(x,z1))
		for i in range(1,nz):
			var z := lerpf(z0,z1,float(i)/float(nz)); samples.append(Vector2(x0,z)); samples.append(Vector2(x1,z))
		for point in samples:
			var ground := float(_terrain.get_mesh_height(point.x,point.y))
			if ground < water_y-0.02 and not node.has_meta("water_weir") and not node.has_meta("water_spout"):
				_record("water",node,Vector3(point.x,water_y,point.y),"water stands %.2f m above bank at 0.5 m outside its outline" % (water_y-ground),true)
				break

func _uses_shared_water_material(mesh:MeshInstance3D)->bool:
	for i in mesh.mesh.get_surface_count() if mesh.mesh != null else 0:
		var material := mesh.get_active_material(i)
		if material is ShaderMaterial and (material as ShaderMaterial).shader == VillageWorks.SHARED_WATER_SHADER: return true
	if mesh.material_override is ShaderMaterial and (mesh.material_override as ShaderMaterial).shader == VillageWorks.SHARED_WATER_SHADER: return true
	return false

func _build_reach_graph(root:Node)->void:
	_graph.clear(); _reverse_graph.clear(); _cell_by_id.clear()
	for cell in _walk_cells:
		var id:String = cell.id
		_cell_by_id[id] = cell
		_graph[id] = []
		_reverse_graph[id] = []
	for cell in _walk_cells:
		var id:String = cell.id
		var key:Vector2i = cell.key
		var neighbours:Array = []
		for dx in range(-1, 2):
			for dz in range(-1, 2):
				if dx == 0 and dz == 0: continue
				var next_key := key + Vector2i(dx, dz)
				if _walk_grid.has(next_key): neighbours.append_array(_walk_grid[next_key])
		if _walk_grid.has(key):
			for stacked in _walk_grid[key]:
				if stacked.id != id: neighbours.append(stacked)
		for next_cell in neighbours:
			if not _can_step_between(cell, next_cell): continue
			_add_graph_edge(id, String(next_cell.id))
	# Transport endpoints with the same id are explicit graph links (lift,
	# escalator, or train). They are authored on markers so the checker remains
	# kingdom-agnostic.
	var links:Dictionary = {}
	_broken_reach_links.clear()
	for node in _walk(root):
		if not node.has_meta("reach_link_id") or not node is Node3D: continue
		var link_id := str(node.get_meta("reach_link_id"))
		var cell := _nearest_cell((node as Node3D).global_position, 3.0)
		if cell.is_empty():
			_broken_reach_links.append({"node": node, "link_id": link_id, "position": (node as Node3D).global_position})
			continue
		if not links.has(link_id): links[link_id] = {"cells": {}, "nodes": []}
		links[link_id].cells[String(cell.id)] = true
		links[link_id].nodes.append(node)
	for link_id in links:
		var endpoints:Array = links[link_id].cells.keys()
		if endpoints.size() < 2:
			for node in links[link_id].nodes:
				_broken_reach_links.append({"node": node, "link_id": String(link_id), "position": (node as Node3D).global_position, "detail": "reach link has fewer than two distinct walkable endpoints"})
			continue
		for a in endpoints:
			for b in endpoints:
				if a != b: _add_graph_edge(String(a), String(b))
	var starts:Array[String] = []
	var primary_start:Dictionary = {}
	for node in _walk(root):
		if not node is Node3D: continue
		if node.has_meta("reach_start"):
			var cell := _nearest_cell((node as Node3D).global_position, 3.0)
			if not cell.is_empty():
				if primary_start.is_empty():
					primary_start = cell
					_reach_start_position = (node as Node3D).global_position
				if String(cell.id) not in starts: starts.append(String(cell.id))
	if primary_start.is_empty():
		primary_start = _nearest_cell(_player_start, 3.0)
		_reach_start_position = _player_start
		if not primary_start.is_empty(): starts.append(String(primary_start.id))
	_reach_start_cell = primary_start
	_sample_stats["reach_start"] = [_reach_start_position.x, _reach_start_position.y, _reach_start_position.z]
	for node in _walk(root):
		if not node is Node3D or not node.has_meta("station_platform"): continue
		var cell := _nearest_cell((node as Node3D).global_position, 3.0)
		if not cell.is_empty() and String(cell.id) not in starts: starts.append(String(cell.id))
	_reachable = _flood_graph(starts, _graph)
	_sample_stats["reachable_cells"] = _reachable.size()
	_reached_buckets.clear()
	for id in _reachable:
		var cell:Dictionary = _cell_by_id[id]
		var bucket := Vector2i(floori(float(cell.x)/16.0),floori(float(cell.z)/16.0))
		if not _reached_buckets.has(bucket): _reached_buckets[bucket] = []
		_reached_buckets[bucket].append(cell)
	var primary_seeds:Array[String] = []
	if not primary_start.is_empty(): primary_seeds.append(String(primary_start.id))
	_reverse_reachable = _flood_graph(primary_seeds, _reverse_graph)

func _add_graph_edge(from_id:String, to_id:String)->void:
	if not _graph.has(from_id) or not _graph.has(to_id): return
	if to_id not in _graph[from_id]: _graph[from_id].append(to_id)
	if from_id not in _reverse_graph[to_id]: _reverse_graph[to_id].append(from_id)

func _flood_graph(starts:Array[String], edges:Dictionary)->Dictionary:
	var visited:Dictionary = {}
	var queue:Array[String] = []
	for start in starts:
		if _cell_by_id.has(start) and not visited.has(start): visited[start] = true; queue.append(start)
	var queue_index := 0
	while queue_index < queue.size():
		var current:String = queue[queue_index]
		queue_index += 1
		for next in edges.get(current, []):
			if visited.has(next): continue
			if not _cell_clearance(_cell_by_id[next]): continue
			visited[next] = true
			queue.append(next)
	return visited

func _can_step_between(a:Dictionary, b:Dictionary)->bool:
	var rise := float(b.y) - float(a.y)
	if rise > STEP_HEIGHT or rise < -1.0: return false
	if float(a.normal.y) < _walkable_slope_dot or float(b.normal.y) < _walkable_slope_dot: return false
	if a.body == b.body: return true
	var from:Vector3 = a.position + Vector3.UP * 0.8
	var to:Vector3 = b.position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(from,to,_static_mask)
	query.exclude = _dynamic_excludes.duplicate()
	query.exclude.append((a.body as CollisionObject3D).get_rid())
	query.exclude.append((b.body as CollisionObject3D).get_rid())
	if not get_viewport().world_3d.direct_space_state.intersect_ray(query).is_empty(): return false
	return true

func _cell_clearance(cell:Dictionary)->bool:
	var id:String = cell.id
	if _clearance_cache.has(id): return bool(_clearance_cache[id])
	var point:Vector3 = cell.position
	var state := get_viewport().world_3d.direct_space_state
	var from := point + Vector3.UP * 0.05
	var to := from + Vector3.UP * (WALKER_HEIGHT - 0.1)
	var query := PhysicsRayQueryParameters3D.create(from, to, _static_mask)
	query.exclude = _dynamic_excludes.duplicate()
	query.exclude.append((cell.body as CollisionObject3D).get_rid())
	var clear := state.intersect_ray(query).is_empty()
	# A cell inside another solid (a deck buried in a block or under a skirt) is not a place to stand, and a ray that
	# starts inside a convex shape sees nothing: ask the point itself.
	if clear and not _cli_opts.has("no-burial-test"):
		var inside := PhysicsPointQueryParameters3D.new()
		inside.position = point + Vector3.UP * 0.15   # a lip under 15 cm is a step, not a burial
		inside.collision_mask = _static_mask
		inside.exclude = query.exclude
		clear = true
		for result in state.intersect_point(inside, 8):
			# Only a body tagged solid_fill (a skirt under a flight, a fill under a helix) buries a cell. A general test
			# rejects every deck a few centimetres under an overlapping neighbour and halves the reached cells.
			var holder := result.get("collider") as Node
			if holder != null and _body_has_meta(holder, &"solid_fill"):
				clear = false
				break
	_clearance_cache[id] = clear
	return clear

func _nearest_cell(point:Vector3, max_distance:float)->Dictionary:
	var best:Dictionary = {}
	var best_distance := max_distance
	var radius := ceili(max_distance/_grid_step)
	var center := Vector2i(roundi(point.x/_grid_step),roundi(point.z/_grid_step))
	for dx in range(-radius,radius+1):
		for dz in range(-radius,radius+1):
			for cell in _walk_grid.get(center+Vector2i(dx,dz),[]):
				var distance := point.distance_to(cell.position)
				if distance <= best_distance: best_distance = distance; best = cell
	return best

func _check_reach(root:Node)->void:
	for broken in _broken_reach_links:
		var detail := String(broken.get("detail", "reach link endpoint has no walk cell within 3 m"))
		_record("reach", broken.node, broken.position, "%s (link %s)" % [detail, broken.link_id], true)
	var targets:Array[Node] = []
	for node in _walk(root):
		if node.has_meta("reach_target") and node is Node3D and _inside_area((node as Node3D).global_position): targets.append(node)
	for target in targets:
		var already_reported := false
		for broken in _broken_reach_links:
			if broken.node == target: already_reported = true; break
		if already_reported: continue
		var point := (target as Node3D).global_position
		var cell := _nearest_cell(point, 2.0)
		if cell.is_empty():
			_record("reach", target, point, "no walk cell lies within 2 m of the target", true)
		elif not _reachable.has(String(cell.id)) and not _reached_within(point, 0.8):
			var nearest := _nearest_reached(point)
			_record("reach", target, point, "target is disconnected from spawn/stations; nearest reached cell: %s" % (str(nearest.position.round()) if not nearest.is_empty() else "none"), true)

func _reached_within(point:Vector3, radius:float)->bool:
	# A player standing at a marker can use any reached cell within a stride of it,
	# so a low-headroom cell under a ramp beside it does not make it unreachable.
	var base := Vector2i(floori(point.x / 16.0), floori(point.z / 16.0))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			for cell in _reached_buckets.get(base + Vector2i(dx, dz), []):
				if point.distance_to(cell.position) <= radius: return true
	return false

func _nearest_reached(point:Vector3)->Dictionary:
	var best:Dictionary = {}
	var best_distance := INF
	for bucket in _reached_buckets:
		var center := Vector3((float(bucket.x)+0.5)*16.0,point.y,(float(bucket.y)+0.5)*16.0)
		var lower_bound := Vector2(center.x-point.x,center.z-point.z).length()-11.4
		if lower_bound > best_distance: continue
		for cell in _reached_buckets[bucket]:
			var distance := point.distance_to(cell.position)
			if distance < best_distance: best_distance = distance; best = cell
	return best

func _check_traps(root:Node)->void:
	var one_way:Array[Dictionary] = []
	for id in _reachable:
		if not _reverse_reachable.has(id): one_way.append(_cell_by_id[id])
	_sample_stats["trapped_cells"] = one_way.size()
	_sample_stats["trapped_share"] = float(one_way.size()) / maxf(float(_reachable.size()), 1.0)
	_emit_cell_clusters("trap", one_way, "reachable pocket cannot return to spawn (%d walk samples)", true)
	var shells:Array[Node3D] = []
	for node in _walk(root):
		if node is Node3D and node.has_meta("closed_shell") and bool(node.get_meta("closed_shell")) and not bool(node.get_meta("enterable", false)):
			shells.append(node as Node3D)
	for shell in shells:
		var bounds := _node_world_aabb(shell)
		var inside:Array[Dictionary] = []
		for cell_id in _reachable:
			var cell:Dictionary = _cell_by_id[cell_id]
			if bounds.has_point(cell.position): inside.append(cell)
		_emit_cell_clusters("trap", inside, "reachable cells inside an untagged shell (%d samples)", true, shell)

func _check_headroom()->void:
	var groups:Dictionary = {}
	var state := get_viewport().world_3d.direct_space_state
	for id in _reachable:
		var cell:Dictionary = _cell_by_id[id]
		var point:Vector3 = cell.position
		var from := point + Vector3.UP * 0.05
		var distance := 2.4 if _body_has_meta(cell.body, &"flight") else 2.2
		var query := PhysicsRayQueryParameters3D.create(from, from + Vector3.UP * distance, _static_mask)
		query.exclude = [(cell.body as CollisionObject3D).get_rid()]
		var hit := state.intersect_ray(query)
		if hit.is_empty(): continue
		var obstacle := hit.get("collider") as Node
		if obstacle == null: continue
		var key := str(obstacle.get_path())
		if not groups.has(key): groups[key] = {"node": obstacle, "cells": []}
		groups[key].cells.append(cell)
	for key in groups:
		var group:Dictionary = groups[key]
		var blocking := _body_has_meta(group.node, &"flight") or _body_has_meta(group.node, &"doorway") or _body_has_meta(group.node, &"ways_out")
		var typed_cells:Array[Dictionary] = []
		for cell in group.cells: typed_cells.append(cell)
		_emit_cell_clusters("headroom", typed_cells, "solid geometry within standing height (%d samples)", blocking, group.node)

func _check_underside(meshes:Array[MeshInstance3D], shapes:Array[CollisionShape3D])->void:
	_build_mesh_buckets(meshes)
	_mesh_face_cache.clear()
	var body_cells:Dictionary = {}
	for cell in _walk_cells:
		var body_path:String = cell.body_path
		if not body_cells.has(body_path): body_cells[body_path] = {"body": cell.body, "cells": [], "shapes": [], "missing_visual": []}
		body_cells[body_path].cells.append(cell)
	var static_bodies:Dictionary = {}
	for shape in shapes:
		var owner := _collision_owner_for_node(shape)
		var body_path := str(owner.get_path()) if owner != null else ""
		if owner == null: continue
		static_bodies[owner.get_instance_id()] = owner
		if body_cells.has(body_path): body_cells[body_path].shapes.append(shape)
	var mesh_results:Dictionary = {}
	var body_ray_excludes:Dictionary = {}
	for body_path in body_cells:
		var entry:Dictionary = body_cells[body_path]
		if not _is_walk_deck(entry.body): continue
		for cell in entry.cells:
			var candidates := _meshes_at_walk_cell(meshes, cell)
			var has_matching_visual := false
			for mesh in candidates:
				if _collision_owner_for_node(mesh) != entry.body: continue
				if _is_underside_visual_only(mesh): continue
				var sample_xz := Vector2(float(cell.x),float(cell.z))
				var visual_top:float = _surface_y_at(mesh,sample_xz)
				if is_nan(visual_top) or absf(visual_top-float(cell.y)) > 0.08: continue
				has_matching_visual = true
				var mesh_id := mesh.get_instance_id()
				var sample:Vector3 = cell.position
				var thickness:float = _underside_thickness(mesh, sample_xz, visual_top, entry.shapes)
				var has_visible_face := _has_visible_underside(mesh, Vector3(sample.x,visual_top,sample.z), thickness)
				# Start from the physics sample, not the visual surface: the two
				# may differ by the allowed 8 cm and a start inside a box is missed.
				var ray_from:Vector3 = cell.position - Vector3.UP * thickness
				var ray_to:Vector3 = cell.position + Vector3.UP * 0.05
				var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to, _static_mask)
				query.hit_back_faces = true
				if not body_ray_excludes.has(body_path):
					var excludes:Array[RID] = _dynamic_excludes.duplicate()
					for other_body in static_bodies.values():
						if other_body != entry.body: excludes.append((other_body as CollisionObject3D).get_rid())
					body_ray_excludes[body_path] = excludes
				query.exclude = body_ray_excludes[body_path]
				var hit := get_viewport().world_3d.direct_space_state.intersect_ray(query)
				var collider_present:bool = not hit.is_empty() and hit.get("collider") == entry.body
				if not mesh_results.has(mesh_id):
					mesh_results[mesh_id] = {"mesh": mesh, "body": entry.body, "position": sample, "visible": true, "collider": true, "cell_count": 0, "face_bad": 0, "ray_bad": 0, "bad_y_min": INF, "bad_y_max": -INF, "bad_position": sample, "has_bad_position": false}
				var result:Dictionary = mesh_results[mesh_id]
				result.cell_count += 1
				if not has_visible_face:
					result.visible = false
					result.face_bad += 1
				if not collider_present:
					result.collider = false
					result.ray_bad += 1
				if not has_visible_face or not collider_present:
					result.bad_y_min = minf(float(result.bad_y_min), float(sample.y))
					result.bad_y_max = maxf(float(result.bad_y_max), float(sample.y))
					if not result.has_bad_position:
						result.bad_position = sample
						result.has_bad_position = true
			# A rail top or other face narrower than the character's radius is not a
			# deck: it needs no visual of its own.
			if not has_matching_visual and float(cell.get("support_width", INF)) >= 0.45: entry.missing_visual.append(cell)
	for mesh_id in mesh_results:
		var issue:Dictionary = mesh_results[mesh_id]
		if issue.visible and issue.collider: continue
		var reasons:Array[String] = []
		var total := maxf(float(issue.cell_count), 1.0)
		if not issue.visible: reasons.append("no underside-facing face at %d of %d sampled cells (%d%%)" % [int(issue.face_bad), int(issue.cell_count), roundi(100.0 * float(issue.face_bad) / total)])
		if not issue.collider: reasons.append("upward ray did not hit this deck's collider at %d of %d sampled cells (%d%%)" % [int(issue.ray_bad), int(issue.cell_count), roundi(100.0 * float(issue.ray_bad) / total)])
		reasons.append("failing cells span y %.2f to %.2f" % [float(issue.bad_y_min), float(issue.bad_y_max)])
		_record("underside", issue.mesh, issue.bad_position, "; ".join(reasons), true, issue.body)
	for body_path in body_cells:
		var entry:Dictionary = body_cells[body_path]
		if not _is_walk_deck(entry.body) or entry.missing_visual.is_empty(): continue
		var missing:Array = entry.missing_visual
		var shape_counts:Dictionary = {}
		for missing_cell in missing: shape_counts[str(missing_cell.get("shape_name",""))] = int(shape_counts.get(str(missing_cell.get("shape_name","")),0)) + 1
		var shape_parts:Array[String] = []
		for shape_key in shape_counts: shape_parts.append("%s x%d" % [shape_key if not String(shape_key).is_empty() else "?", int(shape_counts[shape_key])])
		_record("underside", entry.body, missing[0].position, "walkable deck collider has no visual within 0.08 m at %d sampled cells (collision shapes: %s)" % [missing.size(), ", ".join(shape_parts)], true, null, "deck_visual_missing")
	_check_inward_winding(meshes)

func _is_walk_deck(body:Node)->bool:
	return _body_has_meta(body,&"walk_deck") or _body_has_meta(body,&"flight")

func _build_mesh_buckets(meshes:Array[MeshInstance3D])->void:
	_mesh_buckets.clear(); _mesh_bounds.clear()
	const bucket_size := 8.0
	for mesh in meshes:
		if mesh.mesh == null or String(mesh.get_meta("collision_policy", "")) == "decorative": continue
		var bounds := _node_world_aabb(mesh)
		if bounds.size.x > 256.0 or bounds.size.z > 256.0: continue
		var min_x := int(floor(bounds.position.x / bucket_size)); var max_x := int(floor(bounds.end.x / bucket_size))
		var min_z := int(floor(bounds.position.z / bucket_size)); var max_z := int(floor(bounds.end.z / bucket_size))
		var mesh_id := mesh.get_instance_id()
		_mesh_bounds[mesh_id] = bounds
		for bx in range(min_x, max_x + 1):
			for bz in range(min_z, max_z + 1):
				var bucket_key := Vector2i(bx, bz)
				if not _mesh_buckets.has(bucket_key): _mesh_buckets[bucket_key] = []
				_mesh_buckets[bucket_key].append(mesh)

func _meshes_at_walk_cell(meshes:Array[MeshInstance3D], cell:Dictionary)->Array[MeshInstance3D]:
	var candidates:Array[MeshInstance3D] = []
	var bucket_key := Vector2i(int(floor(float(cell.x) / 8.0)), int(floor(float(cell.z) / 8.0)))
	for mesh in _mesh_buckets.get(bucket_key, []):
		var bounds:AABB = _mesh_bounds[mesh.get_instance_id()]
		if float(cell.x) < bounds.position.x - 0.01 or float(cell.x) > bounds.end.x + 0.01: continue
		if float(cell.z) < bounds.position.z - 0.01 or float(cell.z) > bounds.end.z + 0.01: continue
		if float(cell.y) < bounds.position.y - 0.08 or float(cell.y) > bounds.end.y + 0.08: continue
		if bounds.size.x < 0.25 or bounds.size.z < 0.25: continue
		candidates.append(mesh)
	return candidates

func _collision_owner_for_node(node:Node)->CollisionObject3D:
	var ancestor:Node = node.get_parent()
	while ancestor != null:
		if ancestor is CollisionObject3D: return ancestor as CollisionObject3D
		ancestor = ancestor.get_parent()
	return null

func _is_underside_visual_only(mesh:MeshInstance3D)->bool:
	# belt_distance and helix_fraction are authored only on the moving stair
	# treads. Recognize them in the current bake while the explicit tag is added
	# by the builder for subsequent bakes.
	return bool(mesh.get_meta("underside_visual_only",false)) or mesh.has_meta("belt_distance") or mesh.has_meta("helix_fraction")

func _underside_thickness(mesh:MeshInstance3D, point:Vector2, top_y:float, body_shapes:Array)->float:
	# Select the box whose top face supports this sample. This avoids borrowing
	# the height of a rail or another box elsewhere on the same body.
	var best_thickness := INF
	var best_top_error := INF
	for node in body_shapes:
		if not node is CollisionShape3D: continue
		var box := node as CollisionShape3D
		if not box.shape is BoxShape3D: continue
		var box_shape := box.shape as BoxShape3D
		var local_point:Vector3 = box.global_transform.affine_inverse() * Vector3(point.x,top_y,point.y)
		var half := box_shape.size * 0.5
		if absf(local_point.x) > half.x + 0.12 or absf(local_point.z) > half.z + 0.12: continue
		var top_error := absf(local_point.y-half.y)
		if top_error > 0.12 or top_error >= best_top_error: continue
		var y_axis := box.global_transform.basis.y
		var vertical_projection := absf(y_axis.normalized().y)
		var thickness := box_shape.size.y * y_axis.length() / maxf(vertical_projection,0.1) + 0.03
		best_top_error = top_error
		best_thickness = maxf(0.05,thickness)
	if not is_inf(best_thickness): return best_thickness
	# Curved concave decks (the helix hands): measure the deck's own section from
	# the nearest down face straight under the sample, up to 1.5 m. A deck with no
	# such face keeps the conservative cap, so a missing soffit still fails.
	var section_depth := _own_down_face_depth(mesh, point, top_y, 1.5)
	if not is_nan(section_depth): return section_depth + 0.03
	var bounds := _node_world_aabb(mesh)
	return minf(maxf(bounds.size.y, 0.15), 0.75)

func _own_down_face_depth(mesh:MeshInstance3D, point:Vector2, top_y:float, max_depth:float)->float:
	if mesh.mesh == null: return NAN
	var nearest := NAN
	var faces := _mesh_triangles(mesh)
	for i in range(0,faces.size(),3):
		var a:Vector3 = mesh.global_transform * faces[i]
		var b:Vector3 = mesh.global_transform * faces[i+1]
		var c:Vector3 = mesh.global_transform * faces[i+2]
		if (c-a).cross(b-a).normalized().y > -0.5: continue
		var y := _triangle_height_xz(point,a,b,c)
		if is_nan(y) or y >= top_y-0.005 or top_y-y > max_depth: continue
		if is_nan(nearest) or y > nearest: nearest = y
	return NAN if is_nan(nearest) else top_y - nearest

func _has_visible_underside(mesh:MeshInstance3D, sample:Vector3, max_drop:float=0.75)->bool:
	if mesh.mesh == null: return false
	if _mesh_is_two_sided(mesh): return true
	# A soffit straight under the sample, within the deck's thickness. On a
	# sloped deck the perpendicular foot of a top point near the high end falls
	# past the end of the soffit, so the 3D test below would miss that cell.
	if not is_nan(_own_down_face_depth(mesh, Vector2(sample.x,sample.z), sample.y, max_drop + 0.05)): return true
	var faces := _mesh_triangles(mesh)
	for i in range(0, faces.size(), 3):
		var a:Vector3 = mesh.global_transform * faces[i]
		var b:Vector3 = mesh.global_transform * faces[i + 1]
		var c:Vector3 = mesh.global_transform * faces[i + 2]
		var normal := (c - a).cross(b - a).normalized()
		if normal.y > -0.5: continue
		# On a slope the bottom face is displaced sideways from the top point.
		# Compare in 3D within the deck's physical thickness instead of asking
		# for a face directly beneath the same XZ coordinate.
		var distance := _point_triangle_distance_3d(sample,a,b,c)
		if distance <= max_drop * absf(normal.y) + 0.02: return true
	return false

func _point_triangle_distance_3d(point:Vector3,a:Vector3,b:Vector3,c:Vector3)->float:
	return point.distance_to(_closest_point_on_triangle_3d(point,a,b,c))

func _closest_point_on_triangle_3d(point:Vector3,a:Vector3,b:Vector3,c:Vector3)->Vector3:
	var ab:=b-a; var ac:=c-a; var normal:=ab.cross(ac).normalized()
	if normal.length_squared() < 0.5:
		var nearest_degenerate:=a
		for candidate in [b,c]:
			if point.distance_squared_to(candidate) < point.distance_squared_to(nearest_degenerate): nearest_degenerate=candidate
		return nearest_degenerate
	var projected:=point-normal*normal.dot(point-a)
	var v0:=ab; var v1:=ac; var v2:=projected-a
	var d00:=v0.dot(v0); var d01:=v0.dot(v1); var d11:=v1.dot(v1); var d20:=v2.dot(v0); var d21:=v2.dot(v1)
	var denominator:=d00*d11-d01*d01
	if absf(denominator) > 0.000001:
		var v:float=(d11*d20-d01*d21)/denominator
		var w:float=(d00*d21-d01*d20)/denominator
		if v >= -0.001 and w >= -0.001 and v+w <= 1.001: return projected
	var nearest:=_closest_point_on_segment_3d(point,a,b)
	var candidate:=_closest_point_on_segment_3d(point,b,c)
	if point.distance_squared_to(candidate) < point.distance_squared_to(nearest): nearest=candidate
	candidate=_closest_point_on_segment_3d(point,c,a)
	if point.distance_squared_to(candidate) < point.distance_squared_to(nearest): nearest=candidate
	return nearest

func _closest_point_on_segment_3d(point:Vector3,a:Vector3,b:Vector3)->Vector3:
	var segment:=b-a; var t:=clampf((point-a).dot(segment)/maxf(segment.length_squared(),0.000001),0.0,1.0)
	return a+segment*t

func _underside_y_at(mesh:MeshInstance3D, point:Vector2, top_y:float, max_drop:float)->float:
	if mesh.mesh == null: return NAN
	if _mesh_is_two_sided(mesh): return top_y - minf(max_drop,0.05)
	var sample:=Vector3(point.x,top_y,point.y)
	var best_distance:=INF
	var best_y:=NAN
	var faces := _mesh_triangles(mesh)
	for i in range(0,faces.size(),3):
		var a:Vector3 = mesh.global_transform * faces[i]
		var b:Vector3 = mesh.global_transform * faces[i+1]
		var c:Vector3 = mesh.global_transform * faces[i+2]
		var normal:Vector3=(c-a).cross(b-a).normalized()
		if normal.y > -0.5: continue
		var nearest:=_closest_point_on_triangle_3d(sample,a,b,c)
		var distance:=sample.distance_to(nearest)
		if distance > max_drop*absf(normal.y)+0.02 or distance >= best_distance: continue
		best_distance=distance; best_y=nearest.y
	return best_y

func _surface_y_at(mesh:MeshInstance3D, point:Vector2)->float:
	if mesh.mesh == null: return NAN
	var best := NAN
	var faces := _mesh_triangles(mesh)
	for i in range(0,faces.size(),3):
		var a:Vector3 = mesh.global_transform * faces[i]
		var b:Vector3 = mesh.global_transform * faces[i+1]
		var c:Vector3 = mesh.global_transform * faces[i+2]
		if (c-a).cross(b-a).normalized().y < 0.5: continue
		var y := _triangle_height_xz(point,a,b,c)
		if not is_nan(y) and (is_nan(best) or y > best): best = y
	return best

func _down_face_height_at(point:Vector2,a:Vector3,b:Vector3,c:Vector3,top_y:float,max_drop:float)->float:
	var normal := (c-a).cross(b-a).normalized()
	if normal.y > -0.5: return NAN
	var y := _triangle_height_xz(point,a,b,c)
	if is_nan(y) or y >= top_y-0.005 or top_y-y > max_drop: return NAN
	return y

func _mesh_triangles(mesh:MeshInstance3D)->PackedVector3Array:
	var mesh_id := mesh.get_instance_id()
	if _mesh_face_cache.has(mesh_id): return _mesh_face_cache[mesh_id]
	var source:Mesh = mesh.mesh
	if source == null or not is_instance_valid(source): return PackedVector3Array()
	var faces := source.get_faces()
	_mesh_face_cache[mesh_id] = faces
	return faces

func _triangle_height_xz(point:Vector2, a:Vector3, b:Vector3, c:Vector3)->float:
	var p0 := Vector2(a.x,a.z); var p1 := Vector2(b.x,b.z); var p2 := Vector2(c.x,c.z)
	if not _point_in_triangle_xz(point,p0,p1,p2): return NAN
	var denominator := (p1-p0).cross(p2-p0)
	if absf(denominator) < 0.000001: return NAN
	var u := (point-p0).cross(p2-p0) / denominator
	var v := (p1-p0).cross(point-p0) / denominator
	return a.y + u * (b.y-a.y) + v * (c.y-a.y)

func _mesh_is_two_sided(mesh:MeshInstance3D)->bool:
	var materials:Array[Material] = []
	if mesh.material_override != null: materials.append(mesh.material_override)
	if mesh.mesh != null:
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if material != null: materials.append(material)
	for material in materials:
		if material is BaseMaterial3D and (material as BaseMaterial3D).cull_mode == BaseMaterial3D.CULL_DISABLED: return true
	return false

func _point_in_triangle_xz(p:Vector2, a:Vector2, b:Vector2, c:Vector2)->bool:
	var v0 := c-a; var v1 := b-a; var v2 := p-a
	var dot00 := v0.dot(v0); var dot01 := v0.dot(v1); var dot02 := v0.dot(v2)
	var dot11 := v1.dot(v1); var dot12 := v1.dot(v2)
	var denominator := dot00 * dot11 - dot01 * dot01
	if absf(denominator) < 0.000001: return false
	var u := (dot11 * dot02 - dot01 * dot12) / denominator
	var v := (dot00 * dot12 - dot01 * dot02) / denominator
	return u >= -0.001 and v >= -0.001 and u + v <= 1.001

func _check_inward_winding(meshes:Array[MeshInstance3D])->void:
	for mesh in meshes:
		if not _body_has_meta(mesh,&"closed_shell") or mesh.mesh == null or mesh.mesh.get_surface_count() == 0: continue
		var faces := _mesh_triangles(mesh)
		if faces.size() < 36: continue
		var bounds := _node_world_aabb(mesh)
		var center := bounds.get_center()
		var inward := 0; var outward := 0
		for i in range(0, faces.size(), 3):
			var a:Vector3 = mesh.global_transform * faces[i]
			var b:Vector3 = mesh.global_transform * faces[i + 1]
			var c:Vector3 = mesh.global_transform * faces[i + 2]
			var normal := (c-a).cross(b-a).normalized()
			var direction := (a+b+c)/3.0-center
			if normal.length_squared() < 0.5 or direction.length_squared() < 0.01: continue
			if normal.dot(direction) < 0.0: inward += 1
			else: outward += 1
		if inward > 0 and inward > outward * 4:
			_record("underside", mesh, center, "closed mesh winding faces inward (%d inward, %d outward triangles)" % [inward, outward], true)

func _check_solid(meshes:Array[MeshInstance3D],shapes:Array[CollisionShape3D])->void:
	var excluded:Array[RID] = _dynamic_excludes.duplicate()
	var candidates:Array[CollisionShape3D] = []
	for shape in shapes:
		var box := _world_aabb(shape)
		if maxf(box.size.x,maxf(box.size.y,box.size.z)) > 64.0:
			var owner := shape.get_parent() as CollisionObject3D
			if owner != null: excluded.append(owner.get_rid())
		else: candidates.append(shape)
	var state := get_viewport().world_3d.direct_space_state
	for mesh in meshes:
		var a:=_node_world_aabb(mesh)
		var substantial_dimensions := 0
		for dimension in [a.size.x,a.size.y,a.size.z]:
			if float(dimension) > 1.5: substantial_dimensions += 1
		if not _inside_area(a.get_center()) or _collision_is_decorative(mesh) or substantial_dimensions < 2: continue
		var query_shape := BoxShape3D.new(); query_shape.size = a.size + Vector3.ONE * 0.1
		var query := PhysicsShapeQueryParameters3D.new(); query.shape = query_shape; query.transform = Transform3D(Basis.IDENTITY,a.get_center()); query.collision_mask = _static_mask; query.exclude = excluded
		var hits := state.intersect_shape(query,64)
		var near := not hits.is_empty()
		if not near: _record("solid",mesh,a.get_center(),"substantial visual has no collider within 0.05 m",false)

func _check_guard()->void:
	var unguarded:Array[Dictionary] = []
	var body_edges:Dictionary = {}
	var directions:Array[Vector2i] = [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]
	for cell in _walk_cells:
		var key:Vector2i = cell.key
		for direction in directions:
			var neighbour_key := key + direction
			if _has_walk_neighbour(neighbour_key, float(cell.y), 1.0):
				for neighbour in _walk_grid.get(neighbour_key, []):
					if absf(float(neighbour.y) - float(cell.y)) <= 1.0 and neighbour.body != cell.body:
						var connected_path := String(cell.body_path)
						if not body_edges.has(connected_path): body_edges[connected_path] = {"body":cell.body,"total":0,"guarded":0,"way_out":false,"cells":[]}
						body_edges[connected_path].way_out = true
				continue
			var neighbor_x := float(cell.x) + float(direction.x) * _grid_step
			var neighbor_z := float(cell.z) + float(direction.y) * _grid_step
			var ground := float(_terrain.get_mesh_height(neighbor_x, neighbor_z)) if _terrain != null and _terrain.has_method("get_mesh_height") else float(cell.y) - 2.0
			if ground > float(cell.y) - 1.0: continue
			var edge := Vector3(float(cell.x), float(cell.y), float(cell.z)) + Vector3(direction.x,0,direction.y) * (_grid_step * 0.5)
			var guarded := _edge_has_guard(edge, Vector3(direction.x,0,direction.y), cell.body)
			var body_path:String = cell.body_path
			if not body_edges.has(body_path): body_edges[body_path] = {"body":cell.body,"total":0,"guarded":0,"way_out":false,"cells":[]}
			body_edges[body_path].total += 1
			if guarded: body_edges[body_path].guarded += 1
			else: unguarded.append(cell)
	_emit_cell_clusters("guard", unguarded, "drop of at least 1 m without a guard within 0.3 m (%d edge samples)", false)
	for body_path in body_edges:
		var edges:Dictionary = body_edges[body_path]
		var body:Node = edges.body
		if int(edges.total) == 0 or int(edges.guarded) != int(edges.total) or bool(edges.way_out): continue
		if _body_has_meta(body, &"ways_out") or _body_has_meta(body, &"flight") or _body_has_meta(body, &"reach_target"): continue
		_record("guard", body, (body as Node3D).global_position, "walkable outline is fully guarded and has no tagged way through", false)

func _has_walk_neighbour(key:Vector2i, height:float, tolerance:float)->bool:
	if not _walk_grid.has(key): return false
	for cell in _walk_grid[key]:
		if absf(float(cell.y) - height) <= tolerance: return true
	return false

func _edge_has_guard(edge:Vector3, direction:Vector3, source_body:Node)->bool:
	var from := edge - direction * 0.3 + Vector3.UP * 0.8
	var to := edge + direction * 0.3 + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(from, to, _static_mask)
	query.exclude = _dynamic_excludes.duplicate()
	if source_body is CollisionObject3D: query.exclude.append((source_body as CollisionObject3D).get_rid())
	return not get_viewport().world_3d.direct_space_state.intersect_ray(query).is_empty()

func _run_fixture_suite()->void:
	var root := Node3D.new(); root.name = "WorldChecksTemporaryFixtures"
	get_tree().root.add_child(root); get_tree().current_scene = root; _world = root
	_terrain = FixtureTerrain.new()
	var floor := _fixture_box(root,"FixtureGround",Vector3(100,1,24),Vector3(40,-0.5,0),true)
	floor.set_meta("collision_policy","decorative")
	_fixture_overlap(root)
	_fixture_buried(root)
	_fixture_water(root)
	_fixture_reach(root)
	_fixture_narrow_belt(root)
	_fixture_trap(root)
	_fixture_headroom(root)
	_fixture_underside(root)
	_fixture_solid(root)
	_fixture_guard(root)
	await get_tree().process_frame
	await get_tree().physics_frame
	var fixture_path := "res://tools/world_checks_fixtures/temporary_suite.tscn"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tools/world_checks_fixtures"))
	_set_fixture_owners(root,root)
	var packed := PackedScene.new()
	var pack_error := packed.pack(root)
	if pack_error == OK: pack_error = ResourceSaver.save(packed,fixture_path)
	if pack_error != OK:
		push_error("Could not create temporary world-check fixtures: %s" % error_string(pack_error))
		root.queue_free(); get_tree().quit(1); return
	root.queue_free(); await get_tree().process_frame
	root = (load(fixture_path) as PackedScene).instantiate() as Node3D
	get_tree().root.add_child(root); get_tree().current_scene = root; _world = root
	_terrain = FixtureTerrain.new(); root.add_child(_terrain)
	await get_tree().process_frame; await get_tree().physics_frame
	var meshes:Array[MeshInstance3D] = []; var shapes:Array[CollisionShape3D] = []; _collect(root,meshes,shapes)
	var cases := [
		["overlap",Vector4(-3,-3,4,3),Vector3.ZERO,"FixtureOverlapA","share height","FixtureOverlapClean"],
		["buried",Vector4(7,-3,13,3),Vector3(10,0,0),"FixtureBuriedSlab","terrain stands above","FixtureBuriedClean"],
		["water",Vector4(17,-3,23,3),Vector3(20,0,0),"FixtureWaterFourTenthsOverBank","0.40 m above bank","FixtureWaterClean"],
		["reach",Vector4(27,-3,35,3),Vector3(28,0.2,0),"FixtureDisconnectedPlatform","disconnected from spawn","FixtureReachClean"],
		["reach",Vector4(150,-8,172,8),Vector3(151,0.2,0),"FixtureNarrowBeltGapTarget","disconnected from spawn","FixtureNarrowBeltTarget"],
		["trap",Vector4(37,-3,45,3),Vector3(44,0.2,0),"FixtureOneWayPocket","cannot return to spawn","FixtureTrapClean"],
		["headroom",Vector4(47,-3,53,3),Vector3(50,0.2,0),"FixtureHeadroomBeam","standing height","FixtureHeadroomClean"],
		["underside",Vector4(57,-3,150,3),Vector3(60,0.2,0),"FixtureUndersideTopOnlyVisual","no underside-facing face","FixtureUndersideClean"],
		["solid",Vector4(67,-3,77,3),Vector3(70,0,0),"FixtureUncollidedSolid","no collider within 0.05 m","FixtureSolidClean"],
		["guard",Vector4(77,-3,86,3),Vector3(80,2.2,0),"FixtureGuardPad","fully guarded and has no tagged way through","FixtureGuardClean"],
	]
	var failed:Array[String] = []
	for test in cases:
		var check:String = test[0]; _area = test[1]; _player_start = test[2]; _findings.clear(); _clearance_cache.clear()
		var bounds := _scene_y_bounds(shapes)
		_walk_grid = _build_walk_grid(WALK_GRID_STEP,bounds.x,bounds.y); _grid_step = WALK_GRID_STEP
		_build_reach_graph(root)
		if _cli_opts.has("reach-map") and check == "reach": _print_reach_map(String(_cli_opts["reach-map"]))
		match check:
			"overlap": _check_overlap(bounds.x,bounds.y)
			"buried": _check_buried()
			"water": _check_water(root)
			"reach": _check_reach(root)
			"trap": _check_traps(root)
			"headroom": _check_headroom()
			"underside": _check_underside(meshes,shapes)
			"solid": _check_solid(meshes,shapes)
			"guard": _check_guard()
		var caught := false
		var clean_caught := false
		for finding in _findings:
			if finding.check_id != check: continue
			var path := String(finding.node_path)
			if String(test[3]) in path and String(test[4]) in String(finding.detail): caught = true
			if check == "trap" and "FixtureShellGap" in path and "inside an untagged shell" in String(finding.detail): clean_caught = false
			if String(test[5]) in path: clean_caught = true
		var second_trap_caught := check != "trap"
		var broken_link_caught := check != "reach" or String(test[3]) != "FixtureDisconnectedPlatform"
		var partial_underside_caught := check != "underside"
		var partial_twin_clean := true
		var stepped_underside_caught := check != "underside"
		var stepped_twin_clean := true
		var concave_underside_caught := check != "underside"
		var concave_twin_clean := true
		var no_visual_caught := check != "underside"
		var no_visual_twin_clean := true
		if check == "reach":
			for finding in _findings:
				if finding.check_id == "reach" and "FixtureBrokenReachLinkEndpoint" in String(finding.node_path) and "no walk cell within 3 m" in String(finding.detail): broken_link_caught = true
		if check == "trap":
			for finding in _findings:
				if finding.check_id == "trap" and "FixtureShellGap" in String(finding.node_path) and "inside an untagged shell" in String(finding.detail): second_trap_caught = true
		if check == "underside":
			for finding in _findings:
				if finding.check_id != "underside": continue
				var path := String(finding.node_path)
				var detail := String(finding.detail)
				if "FixtureUndersidePartialVisual" in path and "no underside-facing face" in detail: partial_underside_caught = true
				if "FixtureUndersidePartialCleanTwin" in path: partial_twin_clean = false
				if "FixtureSteppedFlightNoBottom" in path and "no underside-facing face" in detail: stepped_underside_caught = true
				if "FixtureSteppedFlightCleanTwin" in path: stepped_twin_clean = false
				if "FixtureConcaveNoSoffit" in path and "no underside-facing face" in detail: concave_underside_caught = true
				if "FixtureConcaveClosedTwin" in path: concave_twin_clean = false
				if "FixtureDeckNoVisual" in path and String(finding.kind) == "deck_visual_missing": no_visual_caught = true
				if "FixtureDeckWithVisualTwin" in path: no_visual_twin_clean = false
		var underside_fixtures_ok := partial_underside_caught and partial_twin_clean and stepped_underside_caught and stepped_twin_clean and concave_underside_caught and concave_twin_clean and no_visual_caught and no_visual_twin_clean
		if caught and second_trap_caught and broken_link_caught and not clean_caught and underside_fixtures_ok:
			var extra := ""
			if check == "underside": extra = " partial_deck=%s partial_twin_clean=%s stepped_flight=%s stepped_twin_clean=%s concave_no_soffit=%s concave_twin_clean=%s deck_no_visual=%s deck_visual_twin_clean=%s" % [partial_underside_caught,partial_twin_clean,stepped_underside_caught,stepped_twin_clean,concave_underside_caught,concave_twin_clean,no_visual_caught,no_visual_twin_clean]
			print("WORLD_CHECK_FIXTURE PASS ",check," fault=",test[3]," clean=",test[5],extra)
		else:
			print("WORLD_CHECK_FIXTURE FAIL ",check," expected_fault=",caught," clean_twin_clear=",not clean_caught," partial_deck=",partial_underside_caught," partial_twin_clean=",partial_twin_clean," stepped_flight=",stepped_underside_caught," stepped_twin_clean=",stepped_twin_clean," concave_no_soffit=",concave_underside_caught," concave_twin_clean=",concave_twin_clean)
			for finding in _findings:
				if finding.check_id == check: print("  finding ",finding.node_path," :: ",finding.detail)
			failed.append(check)
	root.queue_free(); await get_tree().process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	var uid_path := ProjectSettings.globalize_path(fixture_path+".uid")
	if FileAccess.file_exists(fixture_path+".uid"): DirAccess.remove_absolute(uid_path)
	print("WORLD_CHECK_FIXTURES passed=",cases.size()-failed.size(),"/",cases.size()," failed=",failed)
	get_tree().quit(1 if not failed.is_empty() else 0)

func _set_fixture_owners(node:Node,owner:Node)->void:
	for child in node.get_children(): child.owner = owner; _set_fixture_owners(child,owner)

func _fixture_box(parent:Node3D,label:String,size:Vector3,center:Vector3,with_mesh:bool)->StaticBody3D:
	var body := StaticBody3D.new(); body.name = label; body.collision_layer = 1; body.collision_mask = 1; body.position = center
	var shape := BoxShape3D.new(); shape.size = size; var collision := CollisionShape3D.new(); collision.shape = shape; body.add_child(collision)
	if with_mesh:
		var mesh := BoxMesh.new(); mesh.size = size; var visual := MeshInstance3D.new(); visual.mesh = mesh; visual.material_override = StandardMaterial3D.new(); body.add_child(visual)
	parent.add_child(body); return body

func _fixture_overlap(root:Node3D)->void:
	_fixture_box(root,"FixtureOverlapA",Vector3(2,0.2,2),Vector3(0,0.1,0),true)
	_fixture_box(root,"FixtureOverlapB",Vector3(2,0.2,2),Vector3(0,0.1,0),true)
	_fixture_box(root,"FixtureOverlapCleanA",Vector3(0.8,0.2,0.8),Vector3(2.0,0.1,0),true)
	_fixture_box(root,"FixtureOverlapCleanB",Vector3(0.8,0.2,0.8),Vector3(3.0,0.1,0),true)

func _fixture_buried(root:Node3D)->void:
	_fixture_box(root,"FixtureBuriedSlab",Vector3(2,0.2,2),Vector3(10,-0.2,0),true)
	_fixture_box(root,"FixtureBuriedCleanSlab",Vector3(1,0.2,1),Vector3(12,0.2,0),true)

func _fixture_water(root:Node3D)->void:
	var water := Node3D.new(); water.name = "FixtureWaterFourTenthsOverBank"; water.position = Vector3(20,0,0); water.set_meta("water_surface_y",0.4); root.add_child(water)
	var visual := MeshInstance3D.new(); var plane := PlaneMesh.new(); plane.size = Vector2(2,2); visual.mesh = plane
	var material := ShaderMaterial.new(); material.shader = VillageWorks.SHARED_WATER_SHADER; visual.material_override = material; visual.position.y = 0.4; water.add_child(visual)
	var clean := Node3D.new(); clean.name = "FixtureWaterCleanUnderBank"; clean.position = Vector3(22,0,0); clean.set_meta("water_surface_y",-0.1); root.add_child(clean)
	var clean_visual := MeshInstance3D.new(); var clean_plane := PlaneMesh.new(); clean_plane.size = Vector2(0.8,0.8); clean_visual.mesh = clean_plane; clean_visual.position.y = -0.1; clean_visual.material_override = material; clean.add_child(clean_visual)

func _fixture_reach(root:Node3D)->void:
	var platform := _fixture_box(root,"FixtureDisconnectedPlatform",Vector3(2,0.2,2),Vector3(32,4.1,0),true)
	platform.set_meta("reach_target",true)
	var clean := _fixture_box(root,"FixtureReachCleanTarget",Vector3(1,0.2,1),Vector3(28,0.1,0),true); clean.set_meta("reach_target",true)
	var broken := Node3D.new(); broken.name="FixtureBrokenReachLinkEndpoint"; broken.position=Vector3(34,20,0); broken.set_meta("reach_link_id","FixtureBrokenPair"); root.add_child(broken)

func _fixture_belt(root:Node3D, label:String, z:float, x0:float, x1:float, rise:float)->StaticBody3D:
	# An escalator-like belt: a 0.9 m deep, 1.1 m wide ramp whose body also carries a
	# glass rail box along each edge, 1.4 m tall and 0.11 m thick. The rails are part
	# of the same body, so a walk grid that stops at the first thing it hits sees only
	# their tops and never the belt.
	var run := x1 - x0
	var length := sqrt(run * run + rise * rise)
	var angle := atan2(rise, run)
	var normal := Vector2(-sin(angle), cos(angle))
	var top_mid := Vector2((x0 + x1) * 0.5, rise * 0.5)
	var center := top_mid - normal * 0.45
	var body := StaticBody3D.new()
	body.name = label
	body.collision_layer = 1
	body.collision_mask = 1
	body.position = Vector3(center.x, center.y, z)
	body.rotation.z = angle
	var belt_shape := BoxShape3D.new()
	belt_shape.size = Vector3(length, 0.9, 1.1)
	var belt_collision := CollisionShape3D.new()
	belt_collision.shape = belt_shape
	body.add_child(belt_collision)
	for side in [-1.0, 1.0]:
		var rail_shape := BoxShape3D.new()
		rail_shape.size = Vector3(length, 1.4, 0.11)
		var rail_collision := CollisionShape3D.new()
		rail_collision.shape = rail_shape
		rail_collision.position = Vector3(0.0, 0.45 + 0.7, side * 0.495)
		body.add_child(rail_collision)
	var belt_mesh := BoxMesh.new()
	belt_mesh.size = belt_shape.size
	var visual := MeshInstance3D.new()
	visual.mesh = belt_mesh
	visual.material_override = StandardMaterial3D.new()
	body.add_child(visual)
	body.set_meta("walk_deck", true)
	body.set_meta("flight", true)
	root.add_child(body)
	return body

func _fixture_narrow_belt(root:Node3D)->void:
	var ground := _fixture_box(root,"FixtureBeltGround",Vector3(26,1,20),Vector3(161,-0.5,0),true)
	ground.set_meta("collision_policy","decorative")
	# Clean: ground, a 1.1 m belt with glass rails, a landing at its head (its top 0.4 m under the belt's end, as the
	# city's flights meet their decks). Its target must read as reached.
	_fixture_belt(root,"FixtureNarrowBeltRamp",-4.0,154.0,162.0,4.0)
	var landing := _fixture_box(root,"FixtureNarrowBeltTarget",Vector3(3.4,0.2,2.4),Vector3(163.3,3.5,-4.0),true)
	landing.set_meta("reach_target",true)
	# Fault: the same, with the belt stopping 4 m short of its landing.
	_fixture_belt(root,"FixtureNarrowBeltShort",4.0,154.0,158.0,2.0)
	var unreached := _fixture_box(root,"FixtureNarrowBeltGapTarget",Vector3(3.4,0.2,2.4),Vector3(163.3,3.5,4.0),true)
	unreached.set_meta("reach_target",true)

func _fixture_trap(root:Node3D)->void:
	var pocket := Node3D.new(); pocket.name="FixtureOneWayPocket"; pocket.position=Vector3(40,0,0); root.add_child(pocket)
	_fixture_box(pocket,"FixturePocketFloor",Vector3(2,0.2,2),Vector3(0,0.1,0),true)
	# The ring is a roof with an open top. Its 0.9 m drop is walkable down,
	# while the climb back exceeds the 0.7 m step-up limit.
	var high_roof := _fixture_box(pocket,"FixturePocketRoofNorth",Vector3(4,0.2,1),Vector3(0,1.0,-1.5),true); high_roof.set_meta("station_platform",true)
	_fixture_box(pocket,"FixturePocketRoofSouth",Vector3(4,0.2,1),Vector3(0,1.0,1.5),true)
	_fixture_box(pocket,"FixturePocketRoofEast",Vector3(1,0.2,2),Vector3(1.5,1.0,0),true)
	_fixture_box(pocket,"FixturePocketRoofWest",Vector3(1,0.2,2),Vector3(-1.5,1.0,0),true)
	for side in [-1.0,1.0]:
		_fixture_box(pocket,"FixturePocketOuterWallX",Vector3(0.2,2,4),Vector3(side*2,1,0),true)
		_fixture_box(pocket,"FixturePocketOuterWallZ",Vector3(4,2,0.2),Vector3(0,1,side*2),true)
	var shell := Node3D.new(); shell.name="FixtureShellGap"; shell.position=Vector3(43,0,0); shell.set_meta("closed_shell",true); root.add_child(shell)
	var shell_floor := _fixture_box(shell,"FixtureShellGapFloor",Vector3(2,0.2,2),Vector3.ZERO,true); shell_floor.set_meta("station_platform",true)
	_fixture_box(shell,"FixtureShellGapWallNorth",Vector3(2,2,0.2),Vector3(0,1,-1),true)
	_fixture_box(shell,"FixtureShellGapWallSouth",Vector3(2,2,0.2),Vector3(0,1,1),true)
	_fixture_box(shell,"FixtureShellGapWallWest",Vector3(0.2,2,2),Vector3(-1,1,0),true)
	var clean_shell := Node3D.new(); clean_shell.name="FixtureTrapCleanEnterableShell"; clean_shell.position=Vector3(44,0,0); clean_shell.set_meta("closed_shell",true); clean_shell.set_meta("enterable",true); root.add_child(clean_shell)
	_fixture_box(clean_shell,"FixtureTrapCleanEnterableFloor",Vector3(1.5,0.2,1.5),Vector3.ZERO,true)
	_fixture_box(clean_shell,"FixtureTrapCleanWallNorth",Vector3(1.5,1.5,0.12),Vector3(0,0.75,-0.75),true)
	_fixture_box(clean_shell,"FixtureTrapCleanWallSouth",Vector3(1.5,1.5,0.12),Vector3(0,0.75,0.75),true)
	_fixture_box(clean_shell,"FixtureTrapCleanWallWest",Vector3(0.12,1.5,1.5),Vector3(-0.75,0.75,0),true)

func _fixture_headroom(root:Node3D)->void:
	_fixture_box(root,"FixtureHeadroomBeam",Vector3(3,0.2,2),Vector3(50,1.8,0),true)
	_fixture_box(root,"FixtureHeadroomCleanWalk",Vector3(1,0.2,1),Vector3(52,0.1,0),true)

func _fixture_underside(root:Node3D)->void:
	var body := _fixture_box(root,"FixtureUndersideDeck",Vector3(2,0.1,2),Vector3(60,1.05,0),false); body.set_meta("walk_deck",true)
	var top_only := _fixture_top_only_mesh(2.0,2.0)
	var visual := MeshInstance3D.new(); visual.name="FixtureUndersideTopOnlyVisual"; visual.mesh = top_only; visual.position.y = 0.05; body.add_child(visual)
	var clean := _fixture_box(root,"FixtureUndersideCleanBoxedDeck",Vector3(1.5,0.1,1.5),Vector3(62,1.05,0),true); clean.set_meta("walk_deck",true)
	var partial := _fixture_box(root,"FixtureUndersidePartialDeck",Vector3(2,0.1,2),Vector3(64,1.05,0),false); partial.set_meta("walk_deck",true)
	var partial_visual := MeshInstance3D.new(); partial_visual.name="FixtureUndersidePartialVisual"; partial_visual.mesh=_fixture_partial_bottom_mesh(); partial.add_child(partial_visual)
	var partial_clean := _fixture_box(root,"FixtureUndersidePartialCleanTwin",Vector3(2,0.1,2),Vector3(66.5,1.05,0),true); partial_clean.set_meta("walk_deck",true)
	var stepped := _fixture_stepped_flight(root,"FixtureSteppedFlightNoBottom",120.0,false)
	var stepped_clean := _fixture_stepped_flight(root,"FixtureSteppedFlightCleanTwin",124.0,true)
	stepped.set_meta("flight",true); stepped_clean.set_meta("flight",true)
	# A curved-deck pair: a closed 0.9 m section, as the helix hands are, and the
	# same top with no soffit. Both carry a concave collider of their own faces.
	_fixture_concave_deck(root,"FixtureConcaveNoSoffit",130.0,false)
	_fixture_concave_deck(root,"FixtureConcaveClosedTwin",134.0,true)
	# A walk deck whose collider has no visual, and its clean twin with one.
	var no_visual := _fixture_box(root,"FixtureDeckNoVisual",Vector3(2,0.1,2),Vector3(140,1.05,0),false)
	no_visual.set_meta("walk_deck",true)
	var with_visual := _fixture_box(root,"FixtureDeckWithVisualTwin",Vector3(2,0.1,2),Vector3(144,1.05,0),true)
	with_visual.set_meta("walk_deck",true)
	# A tagged moving detail is ignored while the supporting flight remains checked.
	var decorative_tread := MeshInstance3D.new(); decorative_tread.name="FixtureTaggedMovingTread"; decorative_tread.mesh=BoxMesh.new(); decorative_tread.set_meta("underside_visual_only",true); decorative_tread.position=Vector3(0,0.08,0); stepped.add_child(decorative_tread)

func _fixture_concave_deck(parent:Node3D,label:String,x:float,closed:bool)->StaticBody3D:
	var half_x := 1.0
	var half_z := 1.0
	var section := 0.9
	var vertices := PackedVector3Array([Vector3(-half_x,0,-half_z),Vector3(-half_x,0,half_z),Vector3(half_x,0,-half_z),Vector3(half_x,0,half_z),Vector3(-half_x,-section,-half_z),Vector3(-half_x,-section,half_z),Vector3(half_x,-section,-half_z),Vector3(half_x,-section,half_z)])
	var indices := [0,2,1,1,2,3]
	if closed: indices.append_array([4,5,6,5,7,6])
	var arrays:Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array(indices)
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var body:=StaticBody3D.new()
	body.name=label
	body.position=Vector3(x,1.1,0)
	body.collision_layer=1
	body.collision_mask=1
	body.set_meta("walk_deck",true)
	parent.add_child(body)
	var visual:=MeshInstance3D.new()
	visual.name=label+"Visual"
	visual.mesh=mesh
	body.add_child(visual)
	var shape:=ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	var collision:=CollisionShape3D.new()
	collision.shape=shape
	body.add_child(collision)
	return body

func _fixture_top_only_mesh(width:float,depth:float)->ArrayMesh:
	var x:=width*0.5; var z:=depth*0.5
	var arrays:Array=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-x,0,-z),Vector3(-x,0,z),Vector3(x,0,-z),Vector3(x,0,z)])
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,2,1,1,2,3])
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays); return mesh

func _fixture_partial_bottom_mesh()->ArrayMesh:
	var vertices := PackedVector3Array([
		Vector3(-1,0.05,-1),Vector3(-1,0.05,1),Vector3(1,0.05,-1),Vector3(1,0.05,1),
		Vector3(-1,-0.05,-1),Vector3(-1,-0.05,1),Vector3(0,-0.05,-1),Vector3(0,-0.05,1)])
	var arrays:Array=[]; arrays.resize(Mesh.ARRAY_MAX); arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,2,1,1,2,3,4,5,6,5,7,6])
	var mesh:=ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays); return mesh

func _fixture_stepped_flight(parent:Node3D,label:String,x:float,complete_bottom:bool)->StaticBody3D:
	var body:=StaticBody3D.new(); body.name=label; body.position.x=x; body.collision_layer=1; body.collision_mask=1; body.set_meta("walk_deck",true); parent.add_child(body)
	for index in 2:
		var size:=Vector3(1.0,0.1,1.4); var center:=Vector3(float(index)*0.5-0.25,0.1+float(index)*0.35,0)
		var collision:=CollisionShape3D.new(); var box:=BoxShape3D.new(); box.size=size; collision.shape=box; collision.position=center; body.add_child(collision)
		var visual:=MeshInstance3D.new(); visual.name="%s_Step_%d"%[label,index]
		if complete_bottom:
			var box_mesh:=BoxMesh.new(); box_mesh.size=size; visual.mesh=box_mesh
		else:
			var top:=ArrayMesh.new(); var step_arrays:Array=[]; step_arrays.resize(Mesh.ARRAY_MAX)
			step_arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([Vector3(-0.5,0.05,-0.7),Vector3(-0.5,0.05,0.7),Vector3(0.5,0.05,-0.7),Vector3(0.5,0.05,0.7)])
			step_arrays[Mesh.ARRAY_INDEX]=PackedInt32Array([0,2,1,1,2,3]); top.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,step_arrays); visual.mesh=top
		visual.position=center; body.add_child(visual)
	return body

func _fixture_solid(root:Node3D)->void:
	var mesh := MeshInstance3D.new(); mesh.name = "FixtureUncollidedSolid"; var box := BoxMesh.new(); box.size = Vector3(3,3,3); mesh.mesh = box; mesh.position = Vector3(70,1.5,0); root.add_child(mesh)
	_fixture_box(root,"FixtureSolidCleanTwin",Vector3(3,3,3),Vector3(75,1.5,0),true)

func _fixture_guard(root:Node3D)->void:
	_fixture_box(root,"FixtureGuardPad",Vector3(4,0.2,4),Vector3(80,1.9,0),true)
	for side in [-1.0,1.0]:
		_fixture_rail(root,"FixtureGuardRailX",Vector3(80+side*2,2.7,0),Vector2(0.12,4),1.4)
		_fixture_rail(root,"FixtureGuardRailZ",Vector3(80,2.7,side*2),Vector2(4,0.12),1.4)
	_fixture_box(root,"FixtureGuardCleanPad",Vector3(3,0.2,3),Vector3(82.5,0.1,0),true)
	_fixture_rail(root,"FixtureGuardCleanRailLeft",Vector3(81,0.9,0),Vector2(0.12,3),1.4)
	_fixture_rail(root,"FixtureGuardCleanRailBack",Vector3(82.5,0.9,-1.5),Vector2(3,0.12),1.4)
	_fixture_rail(root,"FixtureGuardCleanRailFront",Vector3(82.5,0.9,1.5),Vector2(3,0.12),1.4)
	_fixture_box(root,"FixtureGuardCleanLanding",Vector3(2,0.2,3),Vector3(85,0.1,0),true)

func _fixture_rail(parent:Node3D,label:String,center:Vector3,footprint:Vector2,height:float)->void:
	var left := -footprint.x * 0.5; var right := footprint.x * 0.5
	var front := -footprint.y * 0.5; var back := footprint.y * 0.5
	var low := -height * 0.5; var high := height * 0.5
	var faces := PackedVector3Array()
	var quads:Array = [
		[Vector3(left,low,front),Vector3(right,low,front),Vector3(right,high,front),Vector3(left,high,front)],
		[Vector3(right,low,back),Vector3(left,low,back),Vector3(left,high,back),Vector3(right,high,back)],
		[Vector3(left,low,back),Vector3(left,low,front),Vector3(left,high,front),Vector3(left,high,back)],
		[Vector3(right,low,front),Vector3(right,low,back),Vector3(right,high,back),Vector3(right,high,front)]
	]
	for quad in quads:
		faces.append_array([quad[0],quad[1],quad[2],quad[0],quad[2],quad[3]])
	var shape := ConcavePolygonShape3D.new(); shape.set_faces(faces)
	var body := StaticBody3D.new(); body.name=label; body.collision_layer=1; body.collision_mask=1; body.position=center
	var collision := CollisionShape3D.new(); collision.shape=shape; body.add_child(collision); parent.add_child(body)

func _walk(root:Node)->Array[Node]:
	var out:Array[Node]=[root]
	for child in root.get_children(): out.append_array(_walk(child))
	return out

func _has_blocking_finding()->bool:
	for f in _findings:
		if bool(f.blocking): return true
	return false

func _write_report(kingdom:String,date:String)->void:
	var dir="res://docs/diagnostics/checks"; DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var md:="# %s world checks — %s\n\n"%[kingdom,date]
	md+="Area: %.1f, %.1f to %.1f, %.1f. Findings: %d.\n\n"%[_area.x,_area.y,_area.z,_area.w,_findings.size()]
	md+="Walk grid: %.2f m; %d columns; %d walk cells; overlap grid: %.2f m; %d overlap cells.\n\n"%[float(_sample_stats.get("grid_step_m",WALK_GRID_STEP)),int(_sample_stats.get("columns",0)),int(_sample_stats.get("walk_cells",0)),OVERLAP_GRID_STEP,int(_sample_stats.get("overlap_walk_cells",0))]
	var trapped_cells := int(_sample_stats.get("trapped_cells",0)); var trapped_share := float(_sample_stats.get("trapped_share",0.0))
	var start:Array = _sample_stats.get("reach_start", [0.0,0.0,0.0])
	md+="Primary reach start: (%.2f, %.2f, %.2f); reachable cells: %d; trapped cells: %d (%.6f%% of reachable).\n\n"%[float(start[0]),float(start[1]),float(start[2]),int(_sample_stats.get("reachable_cells",0)),trapped_cells,trapped_share*100.0]
	md+="Preflight: walk grid %.1f ms; reach graph %.1f ms.\n\n"%[float(_timings.get("walk_grid",0.0)),float(_timings.get("reach_graph",0.0))]
	md+="Total elapsed: %.1f ms.\n\n"%[(Time.get_ticks_usec()-_suite_started_usec)/1000.0]
	for check in CHECKS:
		if _timings.has(check):
			var group:Array=[]
			for f in _findings:
				if f.check_id==check: group.append(f)
			md+="## %s — %d findings (%.1f ms)\n\n"%[check,group.size(),float(_timings[check])]
			for f in group.slice(0,20): md+="- %s `%s` at (%.2f, %.2f, %.2f): %s\n"%["blocking" if f.blocking else "warning",f.node_path,f.position.x,f.position.y,f.position.z,f.detail]
			md+="\n"
	var stem="%s-%s"%[kingdom,date]
	var json_file:=FileAccess.open(dir+"/"+stem+".json",FileAccess.WRITE); json_file.store_string(JSON.stringify({"kingdom":kingdom,"date":date,"area":[_area.x,_area.y,_area.z,_area.w],"sample_stats":_sample_stats,"elapsed_ms":Time.get_ticks_usec()-_suite_started_usec,"timings_ms":_timings,"findings":_findings},"\t")); json_file.close()
	var md_file:=FileAccess.open(dir+"/"+stem+".md",FileAccess.WRITE); md_file.store_string(md.strip_edges(false,true)+"\n"); md_file.close()
