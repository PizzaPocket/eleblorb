extends Node3D
## Exports the game's own figures as meshes for the planning drawings
## (docs/drawings/*_3d.html), so a model drawn beside the hero uses his real
## geometry and joints rather than numbers re-derived by hand:
##   hero:  the player's body (Player.build_portrait_body) and every pivot;
##   suit:  a full blorb suit of one element worn on that body (only the
##          suit's own pieces, eyes and cores included);
##   blorb: a free blorb of that element, for its eyes and core;
##   people: with --looks=<json>, each named look built as a real NPC
##           (npc.gd properties; keys starting with "_" are notes, skipped).
## Positions are millimetres in each body's own space (+Y up, +Z forward);
## each part is an unindexed triangle list with its albedo, emission and
## transparency. Run:
##   godot --headless --path . res://tools/export_figure_reference.tscn -- --out=figure.json [--element=city] [--looks=res://docs/architecture/moy_pkg_P17_looks.json]
## then embed it with tools/embed_drawing_data.py <page> figure.json FIGURE.

const BLORB := preload("res://scenes/blorb.tscn")
const NPC := preload("res://scenes/npc.tscn")
var out_path := "figure.json"
var element := "city"
var looks_path := ""

class Ground extends Node3D:
	func get_mesh_height(_x: float, _z: float) -> float: return 0.0
	func get_mesh_normal(_x: float, _z: float) -> Vector3: return Vector3.UP
	func is_lake_area(_at: Vector2) -> bool: return false

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out_path = a.substr(6)
		if a.begins_with("--element="): element = a.substr(10)
		if a.begins_with("--looks="): looks_path = a.substr(8)
	get_tree().create_timer(60.0).timeout.connect(func() -> void: get_tree().quit(2))
	_run.call_deferred()

## The same joint map player.gd's _blorb_suit_pivot_map() hands the suit.
func _suit_map(p: Dictionary) -> Dictionary:
	var m := {"spine": p["spine"], "head": p["head"]}
	for side in ["left", "right"]:
		m["arm_%s_shoulder" % side] = p["arm_" + side]; m["arm_%s_elbow" % side] = p["elbow_" + side]
		m["leg_%s_hip" % side] = p["leg_" + side]; m["leg_%s_knee" % side] = p["knee_" + side]; m["leg_%s_ankle" % side] = p["ankle_" + side]
		for part in ["back", "wrist", "fingertip", "toe", "sole"]: m["%s_%s" % [part, side]] = p["%s_%s" % [part, side]]
	return m

func _material(mi: MeshInstance3D, s: int) -> Array:
	var m: Material = mi.get_surface_override_material(s)
	if m == null: m = mi.material_override
	if m == null: m = mi.mesh.surface_get_material(s)
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		var e: Color = b.emission * b.emission_energy_multiplier if b.emission_enabled else Color.BLACK
		return [b.albedo_color.r, b.albedo_color.g, b.albedo_color.b, b.albedo_color.a, e.r, e.g, e.b, int(b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED)]
	return [0.6, 0.6, 0.6, 1.0, 0.0, 0.0, 0.0, 0]

func _parts(space: Node3D, meshes: Array) -> Array:
	var out := []
	var inv := space.global_transform.affine_inverse()
	for mi: MeshInstance3D in meshes:
		if not mi.is_visible_in_tree() or mi.mesh == null: continue
		var xf := inv * mi.global_transform
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx = arr[Mesh.ARRAY_INDEX]
			var order: Array = Array(idx) if idx != null and idx.size() > 0 else range(vs.size())
			var mm := PackedInt32Array()
			for i in order:
				var w: Vector3 = xf * vs[i]
				mm.append_array([roundi(w.x * 1000.0), roundi(w.y * 1000.0), roundi(w.z * 1000.0)])
			out.append({"name": String(mi.name), "c": _material(mi, s), "v": Array(mm)})
	return out

func _joints(space: Node3D, p: Dictionary) -> Dictionary:
	var inv := space.global_transform.affine_inverse()
	var j := {}
	for k in p:
		if p[k] is Node3D:
			var o := (inv * (p[k] as Node3D).global_transform).origin
			j[k] = [snappedf(o.x, 0.0005), snappedf(o.y, 0.0005), snappedf(o.z, 0.0005)]
	return j

func _blorb() -> Blorb:
	var b := BLORB.instantiate() as Blorb
	b.portrait_mode = true; b.initial_element = element
	add_child(b); b.set_process(false)
	return b

func _meshes(n: Node) -> Array:
	return n.find_children("*", "MeshInstance3D", true, false)

## Each look as a stationary NPC, exported in its own body space.
func _people() -> Dictionary:
	var out := {}
	if looks_path.is_empty(): return out
	var looks: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(looks_path))
	var holder := Node3D.new(); add_child(holder)   # an NPC finds the ground at ../../Terrain
	var x := 30.0
	for who in looks:
		if who.begins_with("_"): continue
		var npc := NPC.instantiate()
		npc.set("stationary", true); npc.position = Vector3(x, 0, 0); x += 10.0
		for k in looks[who]:
			if k.begins_with("_"): continue
			var v = looks[who][k]
			npc.set(k, Color(v[0], v[1], v[2]) if v is Array else v)
		holder.add_child(npc)
		await get_tree().process_frame
		var body: Node3D = npc.get("visuals") if npc.get("visuals") is Node3D else npc
		out[who] = _parts(body, _meshes(npc))
	return out

func _run() -> void:
	var ground := Ground.new(); ground.name = "Terrain"; add_child(ground)
	var body := CharacterBody3D.new(); add_child(body)
	var visuals := Node3D.new(); body.add_child(visuals)
	var pivots := Player.build_portrait_body(visuals)
	await get_tree().process_frame
	var bare := _meshes(visuals)
	var suit := BlorbSuitController.new()
	suit.setup(body, visuals, _suit_map(pivots), 1.0, {})
	for slot in BlorbSuit.SLOT_ORDER:
		var b := _blorb(); b.in_party = true; b.begin_worn(); b.finish_worn()
		suit._wear_on_body(slot, b)
	for i in 4: await get_tree().physics_frame
	suit.call("_update_worn_limbs", false)
	await get_tree().process_frame
	var worn := _meshes(visuals).filter(func(m: Node) -> bool: return not bare.has(m))
	var free := _blorb(); free.position = Vector3(20, 0, 0)
	for i in 3: await get_tree().process_frame
	var result := {"element": element, "hero": _parts(visuals, bare), "joints": _joints(visuals, pivots),
		"suit": _parts(visuals, worn), "blorb": _parts(free, _meshes(free)), "people": await _people()}
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(result)); f.close()
	print("export_figure_reference: hero %d, suit %d, blorb %d parts, people %s" % [result["hero"].size(), result["suit"].size(), result["blorb"].size(), result["people"].keys()])
	get_tree().quit(0)
