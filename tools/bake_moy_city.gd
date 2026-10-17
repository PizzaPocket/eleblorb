extends Node

const BUILDER := preload("res://scripts/moy_city_bake_builder.gd")
const OUTPUT := "res://assets/generated/moy_city"


func _ready() -> void:
	var absolute := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(absolute)
	var packs: Dictionary = BUILDER.build_packs()
	_split_heavy_packs(packs, 160)
	var names: Array = packs.keys(); names.sort()
	var files: Array[String] = []
	for key in names:
		var scene := PackedScene.new()
		_set_scene_owners(packs[key], packs[key])
		var err := scene.pack(packs[key])
		if err != OK:
			push_error("Moy bake pack failed: %s (%s)" % [key, error_string(err)])
			get_tree().quit(1); return
		var path := "%s/cell_%s.tscn" % [OUTPUT, key]
		err = ResourceSaver.save(scene, path)
		if err != OK:
			push_error("Moy bake save failed: %s (%s)" % [path, error_string(err)])
			get_tree().quit(1); return
		files.append("res://assets/generated/moy_city/cell_%s.tscn" % key)
		packs[key].free()
	var silhouette_scene := PackedScene.new()
	var silhouette_root: Node3D = BUILDER.build_silhouette()
	_set_scene_owners(silhouette_root, silhouette_root)
	var silhouette_err := silhouette_scene.pack(silhouette_root)
	if silhouette_err != OK:
		push_error("Moy silhouette bake failed: %s" % error_string(silhouette_err)); get_tree().quit(1); return
	var silhouette_path := OUTPUT + "/silhouette.tscn"
	silhouette_err=ResourceSaver.save(silhouette_scene,silhouette_path)
	if silhouette_err != OK:
		push_error("Moy silhouette save failed: %s" % error_string(silhouette_err)); get_tree().quit(1); return
	silhouette_root.free()
	var hashes := {}
	for source in ["res://scripts/city_plan.gd", "res://scripts/moy_city_bake_builder.gd", "res://scripts/moy_ride_train.gd", "res://scripts/moy_wind_turbine_rotor.gd", "res://scripts/moy_timekeeper.gd", "res://scripts/moy_hotel_lift.gd", "res://scripts/moy_lift_platform.gd", "res://scripts/moy_escalator.gd", "res://shaders/moy_pond_water.gdshader", "res://tools/city_layout.py", "res://tools/bake_moy_city.gd"]:
		hashes[source] = _sha256(ProjectSettings.globalize_path(source))
	var spine: Dictionary={}
	var meridian: Dictionary={}
	for service in BUILDER.PLAN.CROSS.services:
		if String(service.line)=="Spine Line": spine=service
		if String(service.line)=="Meridian Line": meridian=service
	var access_count:=0
	for station in BUILDER.PLAN.CROSS.stations: access_count+=station.get("_access",[]).size()
	var first_timetable_line: Dictionary=BUILDER.PLAN.TIMETABLE.lines.values()[0]
	var hotel_packs: Array[String] = []
	for path in files:
		if path.get_file().begins_with("cell_hotel_interior"):
			hotel_packs.append(path)
	var manifest := {"format":3,"datum":BUILDER.DATUM,"cell_size":BUILDER.CELL,"counts":{"streets":BUILDER.PLAN.STREETS.size(),"buildings":BUILDER.PLAN.BUILDINGS.size(),"lots":BUILDER.PLAN.LOTS.size(),"old_houses":BUILDER.PLAN.OLD_HOUSES.size()},"prototype_counts":{"crossing_towers":BUILDER.PLAN.CROSSING.towers.size(),"deck_columns":BUILDER.PLAN.DECK.columns.size(),"deck_parapets":BUILDER.PLAN.DECK.parapets.size(),"deck_beds":BUILDER.PLAN.DECK.beds.size(),"deck_trees":BUILDER.PLAN.DECK.trees.size(),"park_trees":BUILDER.PLAN.PARK.trees.size(),"shrubs":BUILDER.PLAN.PARK.shrubs.size(),"reed_clumps":BUILDER.PLAN.PARK.reeds.size(),"rocks":BUILDER.PLAN.PARK.rocks.size(),"agave":BUILDER.PLAN.PARK.agave.size(),"climber_panels":BUILDER.PLAN.CROSSING.climbers.size(),"meridian_piers":meridian.piers.size(),"spine_frames":spine.frames.size(),"station_escalator_sets":access_count,"trains_per_service":int(first_timetable_line.trains),"service_lines":BUILDER.PLAN.TIMETABLE.lines.size(),"deck_escalator_pairs":BUILDER.PLAN.DECK.escalators.size(),"deck_ramp_towers":BUILDER.PLAN.DECK.ramps.size(),"city_clocks":4,"city_bells":1,"timekeepers":0},"sources":hashes,"silhouette":"res://assets/generated/moy_city/silhouette.tscn","packs":files,"hotel_packs":hotel_packs}
	var coverage := _coverage_ledger()
	manifest["coverage"] = "res://assets/generated/moy_city/coverage.json"
	var f := FileAccess.open(OUTPUT + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t")); f.close()
	var ledger_file := FileAccess.open(OUTPUT + "/coverage.json", FileAccess.WRITE)
	ledger_file.store_string(JSON.stringify(coverage, "\t")); ledger_file.close()
	print("MOY_BAKE packs=", files.size(), " streets=", BUILDER.PLAN.STREETS.size(), " buildings=", BUILDER.PLAN.BUILDINGS.size(), " lots=", BUILDER.PLAN.LOTS.size(), " old_houses=", BUILDER.PLAN.OLD_HOUSES.size())
	get_tree().quit(0)


func _set_scene_owners(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner=root
		_set_scene_owners(child,root)


func _body_weight(node: Node) -> int:
	var total := 1
	for child in node.get_children(): total += _body_weight(child)
	return total


func _split_heavy_packs(packs: Dictionary, limit: int) -> void:
	# Large spatial cells are staged as additional scenes. Split oversized
	# decorative/structural parents first while retaining their exact transform.
	for pack in packs.values():
		for child in pack.get_children(): _split_node_children(child, limit)
	var additions: Dictionary = {}
	for key in packs.keys():
		var root: Node3D = packs[key]
		var groups: Array[Array] = [[]]
		var weights: Array[int] = [0]
		for child in root.get_children():
			var weight := _body_weight(child)
			if weights[-1] > 0 and weights[-1] + weight > limit:
				groups.append([]); weights.append(0)
			groups[-1].append(child); weights[-1] += weight
		if groups.size() <= 1: continue
		for group_index in range(1, groups.size()):
			var part := Node3D.new(); part.name = "%s_Part_%02d" % [root.name, group_index]
			for child in groups[group_index]: child.reparent(part, false)
			additions["%s_p%02d" % [String(key), group_index]] = part
	for key in additions: packs[key] = additions[key]


func _split_node_children(node: Node, limit: int) -> void:
	if node is PhysicsBody3D or bool(node.get_meta("moy_keep_children",false)) or node.get_child_count() <= 1: return
	var total := 0
	for child in node.get_children(): total += _body_weight(child)
	if total > limit and node is Node3D:
		var groups: Array[Array] = [[]]
		var weights: Array[int] = [0]
		for child in node.get_children():
			var weight := _body_weight(child)
			if weights[-1] > 0 and weights[-1] + weight > limit:
				groups.append([]); weights.append(0)
			groups[-1].append(child); weights[-1] += weight
		for group_index in range(1, groups.size()):
			var part := Node3D.new(); part.name = "%s_Part_%02d" % [node.name, group_index]; part.transform = (node as Node3D).transform
			var parent := node.get_parent(); parent.add_child(part)
			for child in groups[group_index]:
				child.reparent(part, false)
				_split_node_children(child, limit)
	for child in node.get_children(): _split_node_children(child, limit)


func _sha256(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return "MISSING"
	var ctx := HashingContext.new(); ctx.start(HashingContext.HASH_SHA256); ctx.update(f.get_buffer(f.get_length()))
	return ctx.finish().hex_encode()


func _coverage_ledger() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for i in BUILDER.PLAN.BUILDINGS.size():
		var b: Dictionary = BUILDER.PLAN.BUILDINGS[i]
		var base: Dictionary = {"key":"building:%d"%int(b.n),"source":"BUILDINGS[%d]"%i,"rotation_deg":float(b.angle),"collision_owner":"Building_%02d"%int(b.n),"composite":false}
		if b.rect == null:
			base["footprint"] = null; base["top_y"] = BUILDER.DATUM+float(b.height); base["collision_owner"] = "PARK playground composite"; base["composite"] = true
		else:
			var r: Rect2 = b.rect
			base["footprint"] = [r.position.x,r.position.y,r.size.x,r.size.y]
			base["top_y"] = BUILDER.DATUM+float(b.height)+(18.0 if int(b.n)==12 else (62.0 if int(b.n)==13 else 0.0))
			if int(b.n)==1: base["collision_owner"]="Grand Hotel composite wings and tower"; base["composite"]=true
		rows.append(base)
	for i in BUILDER.PLAN.LOTS.size():
		var lot: Array=BUILDER.PLAN.LOTS[i]; var r: Rect2=lot[0]
		var h:=float(lot[1])*float(BUILDER.PLAN.STOREY[lot[2]])
		rows.append({"key":"lot:%d"%i,"source":"LOTS[%d]"%i,"footprint":[r.position.x,r.position.y,r.size.x,r.size.y],"rotation_deg":0.0,"top_y":BUILDER.DATUM+h,"collision_owner":"Lot_%03d"%i,"composite":false})
	for i in BUILDER.PLAN.OLD_HOUSES.size():
		var h: Dictionary=BUILDER.PLAN.OLD_HOUSES[i]
		rows.append({"key":"old_house:%d"%i,"source":"OLD_HOUSES[%d]"%i,"footprint":h.corners,"rotation_deg":0.0,"top_y":BUILDER.DATUM+float(h.storeys)*3.25,"collision_owner":"OldHouse_%02d"%i,"composite":false})
	for s in BUILDER.PLAN.STREETS: rows.append({"key":"street:%s"%String(s.name),"source":"STREETS","footprint":[s.rect.position.x,s.rect.position.y,s.rect.size.x,s.rect.size.y],"top_y":BUILDER.DATUM,"collision_owner":"Street_%s"%String(s.name)})
	for o in BUILDER.PLAN.OPENS: rows.append({"key":"open:%s"%String(o.name),"source":"OPENS","footprint":[o.rect.position.x,o.rect.position.y,o.rect.size.x,o.rect.size.y],"top_y":BUILDER.DATUM,"collision_owner":"Open_%s"%String(o.name)})
	for i in BUILDER.PLAN.OLD_TOWN.lanes.size(): rows.append({"key":"infrastructure:old_lane:%d"%i,"source":"OLD_TOWN.lanes[%d]"%i,"footprint":BUILDER.PLAN.OLD_TOWN.lanes[i].pts,"top_y":BUILDER.DATUM,"collision_owner":"OldLane_%d"%i})
	for key in ["DECK","WALL","CROSS","CROSSING","PARK","ESTATE","HOTEL","CROSSING.dome","TURBINES"]: rows.append({"key":"infrastructure:%s"%key.to_lower(),"source":key,"collision_owner":"Moy infrastructure geometry","composite":true})
	return rows
