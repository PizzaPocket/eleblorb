extends Node

## Headless walk-surface audit. World geometry is read from collision shapes;
## visual-only meshes are read separately so the checks do not confuse a
## pretty floor with a floor a character can stand on.
const CHECKS := ["overlap","buried","water","reach","trap","headroom","underside","solid","guard"]
const DEFAULT_AREA := Vector4(-763.0,-203.0,-357.0,203.0)
var _area := DEFAULT_AREA
var _only_checks: Array[String] = []
var _findings: Array[Dictionary] = []
var _timings: Dictionary = {}
var _world: Node3D
var _terrain: Node

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var opts := _parse_options(OS.get_cmdline_user_args())
	if opts.has("area"):
		var values := String(opts.area).split(",")
		if values.size()==4: _area=Vector4(float(values[0]),float(values[1]),float(values[2]),float(values[3]))
	if opts.has("checks"):
		for check in String(opts.checks).split(","): _only_checks.append(check)
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate() as Node3D
	get_tree().root.add_child(main); get_tree().current_scene=main; _world=main
	await get_tree().process_frame
	_terrain=main.get_node_or_null("Terrain")
	var player:=main.get_node_or_null("Player") as Node3D
	if player!=null:
		player.global_position=Vector3((_area.x+_area.z)*0.5,-58.0,(_area.y+_area.w)*0.5)
		player.set_physics_process(false)
	var city:=main.get_node_or_null("WesternCity")
	var deadline:=Time.get_ticks_msec()+240000
	while city!=null and city.has_method("moy_packs_ready") and not city.moy_packs_ready() and Time.get_ticks_msec()<deadline:
		await get_tree().create_timer(0.25).timeout
	await get_tree().physics_frame
	var meshes:Array[MeshInstance3D]=[]; var shapes:Array[CollisionShape3D]=[]; _collect(main,meshes,shapes)
	for check in CHECKS:
		if not _only_checks.is_empty() and check not in _only_checks: continue
		var started:=Time.get_ticks_usec()
		match check:
			"overlap": _check_overlap(shapes)
			"buried": _check_buried(shapes)
			"water": _check_water(main)
			"reach": _check_reach(main,shapes)
			"trap": _check_traps(main)
			"headroom": _check_headroom(shapes)
			"underside": _check_underside(meshes,shapes)
			"solid": _check_solid(meshes,shapes)
			"guard": _check_guard(shapes)
		_timings[check]=(Time.get_ticks_usec()-started)/1000.0
	_write_report(String(opts.get("kingdom","moy")),String(opts.get("date","2026-10-18")))
	print("WORLD_CHECKS findings=",_findings.size()," timings_ms=",_timings)
	get_tree().quit(1 if _has_blocking_finding() else 0)

func _parse_options(args:PackedStringArray)->Dictionary:
	var result:Dictionary={}
	for arg in args:
		if String(arg).begins_with("--") and String(arg).contains("="):
			var pair:=String(arg).trim_prefix("--").split("=",false,1); result[pair[0]]=pair[1]
	return result

func _collect(node:Node,meshes:Array[MeshInstance3D],shapes:Array[CollisionShape3D])->void:
	if node is MeshInstance3D and (node as Node3D).visible: meshes.append(node as MeshInstance3D)
	if node is CollisionShape3D and not (node as CollisionShape3D).disabled: shapes.append(node as CollisionShape3D)
	for child in node.get_children(): _collect(child,meshes,shapes)

func _inside_area(point:Vector3)->bool:
	return point.x>=_area.x and point.x<=_area.z and point.z>=_area.y and point.z<=_area.w

func _record(check:String,node:Node,point:Vector3,detail:String,blocking:=false,other:Node=null)->void:
	_findings.append({"check_id":check,"blocking":blocking,"position":{"x":point.x,"y":point.y,"z":point.z},"node_path":str(node.get_path()) if node!=null else "", "other_path":str(other.get_path()) if other!=null else "", "detail":detail})

func _world_aabb(shape:CollisionShape3D)->AABB:
	var debug_mesh:=shape.shape.get_debug_mesh()
	if debug_mesh==null: return AABB(shape.global_position,Vector3.ZERO)
	return shape.global_transform*debug_mesh.get_aabb()

func _check_overlap(shapes:Array[CollisionShape3D])->void:
	var surfaces:Array[Dictionary]=[]
	for shape in shapes:
		var bounds:=_world_aabb(shape)
		if bounds.size.x<0.4 or bounds.size.z<0.4 or not _inside_area(bounds.get_center()): continue
		surfaces.append({"node":shape,"bounds":bounds,"top":bounds.end.y})
	for i in surfaces.size():
		for j in range(i+1,surfaces.size()):
			var a:Dictionary=surfaces[i]; var b:Dictionary=surfaces[j]
			var na:=a.node as CollisionShape3D; var nb:=b.node as CollisionShape3D
			if na.get_parent()==nb.get_parent() or absf(float(a.top)-float(b.top))>0.02: continue
			var aa:=a.bounds as AABB; var bb:=b.bounds as AABB
			if aa.intersects(bb) and (aa.size.x>0.6 and aa.size.z>0.6): _record("overlap",na,(aa.get_center()+bb.get_center())*0.5,"overlapping upward surfaces within 0.02 m",false,nb)

func _check_buried(shapes:Array[CollisionShape3D])->void:
	if _terrain==null or not _terrain.has_method("get_mesh_height"): return
	for shape in shapes:
		var a:=_world_aabb(shape)
		if not _inside_area(a.get_center()) or a.size.x<0.5 or a.size.z<0.5: continue
		var ground:=float(_terrain.get_mesh_height(a.get_center().x,a.get_center().z))
		if ground>a.end.y+0.02 and a.end.y-ground>-2.0: _record("buried",shape,a.get_center(),"surface top is below sampled terrain",true)

func _check_water(root:Node)->void:
	for node in _walk(root):
		if not node.has_meta("water_surface_y"): continue
		var p:=node as Node3D
		if p==null or not _inside_area(p.global_position): continue
		var water_y:=float(node.get_meta("water_surface_y"))
		if _terrain!=null and _terrain.has_method("get_mesh_height"):
			var edge_ground:=float(_terrain.get_mesh_height(p.global_position.x,p.global_position.z))
			if edge_ground<water_y-0.02 and not node.has_meta("water_weir"): _record("water",node,p.global_position,"water surface stands above edge ground",true)

func _check_reach(root:Node,shapes:Array[CollisionShape3D])->void:
	var targets:Array[Node]=[]
	for n in _walk(root):
		if n.has_meta("reach_target") and _inside_area((n as Node3D).global_position): targets.append(n)
	# Walkable surface connectivity is measured by shared top heights and
	# touching footprints. Tagged destinations must have a nearby walk surface.
	for target in targets:
		var p:Vector3=(target as Node3D).global_position
		var found:=false
		for shape in shapes:
			var a:=_world_aabb(shape)
			if a.has_point(Vector3(p.x,p.y-0.2,p.z)) or (absf(a.end.y-p.y)<1.0 and absf(a.get_center().x-p.x)<5.0 and absf(a.get_center().z-p.z)<5.0): found=true; break
		if not found: _record("reach",target,p,"tagged target has no nearby walk surface",true)

func _check_traps(root:Node)->void:
	for node in _walk(root):
		if node.has_meta("enterable") and bool(node.get_meta("enterable")) and node.has_meta("closed_shell") and bool(node.get_meta("closed_shell")):
			_record("trap",node,(node as Node3D).global_position,"enterable closed shell is not marked with a ways_out connection",true)

func _check_headroom(shapes:Array[CollisionShape3D])->void:
	var space:=get_viewport().world_3d.direct_space_state
	for shape in shapes:
		var a:=_world_aabb(shape)
		if not _inside_area(a.get_center()) or a.size.x<0.45 or a.size.z<0.45: continue
		var from:=Vector3(a.get_center().x,a.end.y+0.05,a.get_center().z)
		# Start above the source shape, so an exclusion RID is unnecessary.
		var query:=PhysicsRayQueryParameters3D.create(from,from+Vector3.UP*2.2,1)
		var hit:=space.intersect_ray(query)
		if not hit.is_empty(): _record("headroom",shape,hit.position,"solid geometry within 2.2 m above walk",false,hit.collider as Node)

func _check_underside(meshes:Array[MeshInstance3D],shapes:Array[CollisionShape3D])->void:
	for mesh in meshes:
		var a:=mesh.get_aabb(); var world_a:=mesh.global_transform*a
		if not _inside_area(world_a.get_center()) or world_a.size.x<1.5 or world_a.size.z<1.5: continue
		var has_collider:=false
		for shape in shapes:
			var sa:=_world_aabb(shape)
			if sa.intersects(world_a): has_collider=true; break
		if not has_collider: _record("underside",mesh,world_a.get_center(),"walk-sized mesh has no collider beneath its footprint",true)

func _check_solid(meshes:Array[MeshInstance3D],shapes:Array[CollisionShape3D])->void:
	for mesh in meshes:
		var a:=mesh.global_transform*mesh.get_aabb()
		if not _inside_area(a.get_center()) or int(mesh.get_meta("collision_policy",0))==1 or minf(a.size.x,a.size.y)<1.5: continue
		var near:=false
		for shape in shapes:
			if _world_aabb(shape).grow(0.05).intersects(a): near=true; break
		if not near: _record("solid",mesh,a.get_center(),"substantial visual has no nearby collision",false)

func _check_guard(shapes:Array[CollisionShape3D])->void:
	for shape in shapes:
		var a:=_world_aabb(shape)
		if not _inside_area(a.get_center()) or a.size.x<1.5 or a.size.z<1.5 or a.size.y>1.0: continue
		if a.end.y<0.0: continue
		var perimeter:=2.0*(a.size.x+a.size.z); var guards:=0
		for other in shapes:
			if other==shape: continue
			var b:=_world_aabb(other)
			if b.end.y>a.end.y+0.7 and b.position.y<a.end.y+1.7 and a.grow(0.3).intersects(b): guards+=1
		if guards>=4: _record("guard",shape,a.get_center(),"walkable surface is fully enclosed by nearby guards",false)

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
	for check in CHECKS:
		if _timings.has(check):
			var group:Array=[]
			for f in _findings:
				if f.check_id==check: group.append(f)
			md+="## %s — %d findings (%.1f ms)\n\n"%[check,group.size(),float(_timings[check])]
			for f in group.slice(0,20): md+="- %s `%s` at (%.2f, %.2f, %.2f): %s\n"%["blocking" if f.blocking else "warning",f.node_path,f.position.x,f.position.y,f.position.z,f.detail]
			md+="\n"
	var stem="%s-%s"%[kingdom,date]
	var json_file:=FileAccess.open(dir+"/"+stem+".json",FileAccess.WRITE); json_file.store_string(JSON.stringify({"kingdom":kingdom,"date":date,"area":[_area.x,_area.y,_area.z,_area.w],"timings_ms":_timings,"findings":_findings},"\t")); json_file.close()
	var md_file:=FileAccess.open(dir+"/"+stem+".md",FileAccess.WRITE); md_file.store_string(md); md_file.close()
