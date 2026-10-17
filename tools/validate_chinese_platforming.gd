extends Node3D

const PLAN=preload("res://scripts/chinese_plan.gd")
var problems: Array[String]=[]
var checks:=0

func _ready() -> void:
	var world:=load("res://scenes/chinese_village_qa.tscn").instantiate() as Node3D
	add_child(world)
	await LoadingScreen.wait_for_world_builds()
	for frame in 8: await get_tree().physics_frame
	var village:=world.get_node("ChineseVillage")
	var items: Dictionary=village.get("_plan_items")
	for door in village.find_children("*","Node3D",true,false):
		if door.has_method("set_open_state"): door.set_open_state(true)
	for frame in 3: await get_tree().physics_frame
	var ground: float=village.get("_island_surface_y")
	for path in PLAN.PATHS:
		for i in path.pts.size()-1:
			var a: Array=path.pts[i]
			var b: Array=path.pts[i+1]
			check_route(world,Vector3(250+a[0],ground,-650+a[1]),Vector3(250+b[0],ground,-650+b[1]),"outdoor path "+str(path.to)+" "+str(i))
	for opening in PLAN.OPENINGS:
		if not opening.get("passage",false): continue
		var edge:=Vector3(250+opening.edge[0],ground+opening.level,-650+opening.edge[1])
		var normal:=Vector3(opening.normal[0],0,opening.normal[1])
		check_route(world,edge-normal*0.9,edge+normal*1.2,"doorway "+str(opening.item)+" "+str(opening.side))
	# Exercise ALL authored interior walk lanes, rather than ignoring the shell
	# that owns a ramp (which would hide a blocking floor or wall on that body).
	for body in village.find_children("*","Node3D",true,false):
		for lane in body.get_meta(ClearZones.LANES_META,[]):
			var points: Array=lane.points
			for i in points.size()-1:
				var from: Vector3=body.to_global(points[i])
				var to: Vector3=body.to_global(points[i+1])
				check_route(world,from,to,"%s / %s"%[body.get_path(),lane.label])
	await check_roof_movement(world,village,items)
	await check_step_headroom(world)
	# The pen is a route into a building, not just an open patch inside rails.
	var pen: Node3D=items.pen
	check_route(world,pen.to_global(Vector3(0,0,-4.9)),pen.to_global(Vector3(0,0,2.7)),"Pandy pen to shed")
	# Check visible swept roof facets against their physical backing and normal.
	for record in PLAN.ITEMS:
		if record.kind not in ["building","compound"]: continue
		var item: Node3D=items.get(record.key)
		if item==null: continue
		for offset in [Vector2(0.7,0.7),Vector2(-1.2,-1.2),Vector2(1.2,-1.2)]:
			var point:=Vector3(250+record.centre[0]+offset.x,0,-650+record.centre[1]+offset.y)

			var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*(ground+75),point+Vector3.UP*ground,1)
			query.hit_back_faces=true
			var hit:=get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty():
				checks+=1
				if hit.normal.y<0.05: problems.append("roof ray has inward/vertical normal: "+str(record.key)+" "+str(hit.normal))
	print("China platforming survey: ",checks," samples; ",problems.size()," failures")
	for problem in problems: print("FAIL ",problem)
	get_tree().quit(1 if not problems.is_empty() else 0)

func check_route(world: Node3D, from: Vector3, to: Vector3, label_text: String) -> void:
	var capsule:=CapsuleShape3D.new();capsule.radius=0.34;capsule.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.collision_mask=1
	var samples:=maxi(2,ceili(from.distance_to(to)/0.20))
	for i in samples+1:
		# Slope clearance begins above the walk; capsule rounded ends clear its
		# rising underside without excluding any shell collisions.
		var foot:=from.lerp(to,float(i)/samples)
		var support:=PhysicsRayQueryParameters3D.create(foot+Vector3.UP*0.72,foot-Vector3.UP*0.18,1)
		var floor_hit:=world.get_world_3d().direct_space_state.intersect_ray(support)
		if not floor_hit.is_empty() and floor_hit.normal.y>0.64:
			foot.y=maxf(foot.y,float(floor_hit.position.y))
		query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*1.10)
		var hits:=world.get_world_3d().direct_space_state.intersect_shape(query)
		checks+=1
		if not hits.is_empty():
			var names: Array[String]=[]
			for hit in hits:
				var object: Node=hit.collider
				var shape: Node=object.shape_owner_get_owner(object.shape_find_owner(hit.shape)) if object is CollisionObject3D else object
				names.append(str(shape.get_path()))
			problems.append(label_text+" blocked at "+str(foot)+" by "+str(names))
			return


func check_roof_movement(world: Node3D, village: Node3D, items: Dictionary) -> void:
	var fixtures: Array[Dictionary]=[]
	var roofs: Dictionary={}
	for key in items:
		var shell: Node3D=items[key].get_node_or_null("PlanStructure")
		if shell!=null: roofs[str(key)]=shell
	var inn: Node3D=village.get("_region_inn")
	roofs["inn"]=inn.get_node("InnBuilding")
	for key in ["pond_court","inn_garden"]:
		roofs[key+"_pavilion"]=items[key].get_node("HexagonalOpenPavilion")
	for key in roofs:
		var shell: Node3D=roofs[key]
		var center:=shell.global_position+shell.global_basis*Vector3(0.8,0,0.8)
		var query:=PhysicsRayQueryParameters3D.create(center+Vector3.UP*60,center,1)
		var hit:=world.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			problems.append("no landable roof surface: "+key);continue
		for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
			var actor:=CharacterBody3D.new()
			actor.collision_layer=2;actor.collision_mask=1;actor.floor_max_angle=deg_to_rad(50.0)
			var collider:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new()
			capsule.radius=0.4;capsule.height=1.8;collider.shape=capsule;collider.position.y=0.9
			actor.add_child(collider);add_child(actor)
			actor.position=hit.position+Vector3.UP*2.0
			fixtures.append({"actor":actor,"key":key,"surface":hit.position,"out":direction})

	for frame in 75:
		await get_tree().physics_frame
		for fixture in fixtures:
			var actor: CharacterBody3D=fixture.actor
			actor.velocity=Vector3(0,actor.velocity.y-20.0/60.0,0)
			actor.move_and_slide()
	for fixture in fixtures:
		var actor: CharacterBody3D=fixture.actor
		checks+=1
		if actor.position.y<fixture.surface.y-0.55: problems.append("fell through roof: "+fixture.key)

		fixture.start=actor.position
		actor.velocity.y=7.0
	for frame in 80:
		await get_tree().physics_frame
		for fixture in fixtures:
			var actor: CharacterBody3D=fixture.actor
			var out: Vector3=fixture.out
			actor.velocity=Vector3(out.x*4,actor.velocity.y-20.0/60.0,out.z*4)
			actor.move_and_slide()
	var escape: Dictionary={}
	for fixture in fixtures:
		checks+=1
		var actor: CharacterBody3D=fixture.actor
		var distance:=Vector2(actor.position.x-fixture.start.x,actor.position.z-fixture.start.z).length()
		escape[fixture.key]=maxf(float(escape.get(fixture.key,0.0)),distance)
		actor.queue_free()
	for key in escape:
		if float(escape[key])<3.0: problems.append("roof jump escape blocked in every direction: "+str(key))
	print("Roof drop/jump escape checks: ",roofs.size()," roofs in four directions")



func check_step_headroom(world: Node3D) -> void:
	var player:=world.get_node("Player") as CharacterBody3D
	player.set_physics_process(false);player.set_process(false)
	var fixture:=StaticBody3D.new();add_child(fixture)
	for spec in [[Vector3(2,0.5,0.7),Vector3(0,100.25,0.7)],[Vector3(4,0.2,4),Vector3(0,102.1,0)]]:
		var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=spec[0];shape.shape=box;shape.position=spec[1];fixture.add_child(shape)
	await get_tree().physics_frame
	player.position=Vector3(0,100.1,0);player.velocity=Vector3(0,0,4)
	var before:=player.position.y
	player.call("_try_step_onto_prop",1.0/60.0)
	checks+=1
	if player.position.y>before+0.01: problems.append("auto-step lifted the player into an overhead solid: "+str(player.position.y-before))
	fixture.queue_free()
