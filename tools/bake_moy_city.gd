extends Node

const BUILDER := preload("res://scripts/moy_city_bake_builder.gd")
const OUTPUT := "res://assets/generated/moy_city"


func _ready() -> void:
	var absolute := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(absolute)
	var packs: Dictionary = BUILDER.build_packs()
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
	for source in ["res://scripts/city_plan.gd", "res://scripts/moy_city_bake_builder.gd", "res://scripts/moy_ride_train.gd", "res://scripts/moy_wind_turbine_rotor.gd", "res://scripts/moy_timekeeper.gd", "res://scripts/moy_lift_platform.gd", "res://scripts/moy_escalator.gd", "res://shaders/moy_pond_water.gdshader", "res://tools/city_layout.py"]:
		hashes[source] = _sha256(ProjectSettings.globalize_path(source))
	var manifest := {"format":1,"datum":BUILDER.DATUM,"cell_size":BUILDER.CELL,"counts":{"streets":BUILDER.PLAN.STREETS.size(),"buildings":BUILDER.PLAN.BUILDINGS.size(),"lots":BUILDER.PLAN.LOTS.size(),"old_houses":BUILDER.PLAN.OLD_HOUSES.size()},"sources":hashes,"silhouette":"res://assets/generated/moy_city/silhouette.tscn","packs":files}
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
	for key in ["DECK","WALL","CROSS","CROSSING","PARK","ESTATE","HOTEL","TIMEKEEPER","TURBINES"]: rows.append({"key":"infrastructure:%s"%key.to_lower(),"source":key,"collision_owner":"Moy infrastructure geometry","composite":true})
	return rows
