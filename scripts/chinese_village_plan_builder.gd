extends RefCounted

## Turns the authored ChinesePlan data into the walkable settlement. Plan
## coordinates stay village-local throughout; the drawing, terrain, islands,
## paths, bridges and buildings all read the same generated arrays.

const PLAN := preload("res://scripts/chinese_plan.gd")
const ARCHITECTURE := preload("res://scripts/chinese_architecture.gd")
const WATER := preload("res://scripts/chinese_water.gd")
const INFRASTRUCTURE := preload("res://scripts/chinese_infrastructure.gd")
const VEGETATION := preload("res://scripts/chinese_vegetation.gd")
const WORLD_DOOR_SCRIPT := preload("res://scripts/world_door.gd")
const BAKE := preload("res://scripts/settlement_bake.gd")

const GRASS := Color(0.19, 0.43, 0.25)
const ROCK := Color(0.28, 0.25, 0.22)
const BRIDGE_WOOD := Color(0.31, 0.20, 0.12)
const BRICK := Color(0.48, 0.29, 0.22)
const SHIHU_BRICK := Color(0.43, 0.42, 0.39)
const SHIHU_PLASTER := Color(0.85, 0.83, 0.76)
const FLAG := Color(0.58, 0.55, 0.49)
const EARTH := Color(0.39, 0.29, 0.19)
const PALACE := Color(0.70, 0.48, 0.12)
const WALL := Color(0.73, 0.66, 0.52)
const ROOF := Color(0.34, 0.35, 0.34)
const PLASTER := Color(0.84, 0.81, 0.73)
const IMPERIAL_RED := Color(0.62, 0.12, 0.09)
const STRUCTURAL_EPSILON := SuperEgg.EPSILON_FLAT
const ORGANIC_EPSILON := SuperEgg.EPSILON_SOFT

static func build(parent: Node3D, village_center: Vector2, surface_y: float, civic_state: bool = false) -> Dictionary:
	var root := Node3D.new()
	root.name = "LinyuanPlan"
	parent.add_child(root)
	var centers: Dictionary = {}
	var islands: Dictionary = {}
	var items: Dictionary = {}
	for island_data in PLAN.ISLANDS:
		var key: String = island_data.key
		var center := Vector2(island_data.c[0], island_data.c[1])
		centers[key] = center
		var island := _build_island(root, village_center, surface_y, island_data, center)
		islands[key] = island
	for fragment in PLAN.FRAGMENTS:
		_build_fragment(root, village_center, surface_y, fragment)
	_build_bridges(root, village_center, surface_y)
	for item in PLAN.ITEMS:
		var node := _build_item(root, village_center, surface_y, item, centers)
		if node != null:
			items[item.key] = node
	_build_opening_frames(root,village_center,surface_y,civic_state)
	_build_paths(root, village_center, surface_y)
	_build_edge_parapets(root, village_center, surface_y, centers)
	_build_plan_details(root, village_center, surface_y, centers, items, civic_state)
	_build_landscape_pines(root,village_center,surface_y)
	return {"root": root, "islands": islands, "items": items, "centers": centers}


static func from_bake(parent: Node3D, packed: PackedScene, surface_y: float, civic: bool) -> Dictionary:
	var root := Node3D.new()
	root.name="LinyuanPlan"
	parent.add_child(root)
	var geometry := packed.instantiate() as Node3D
	geometry.name="BakedArchitecture"
	geometry.position.y=surface_y
	root.add_child(geometry)
	BAKE.restore_doors(geometry)
	BAKE.restore_instances(geometry)
	var islands := {}
	var items := {}
	var centers := {}
	for island in PLAN.ISLANDS:
		islands[island.key]=geometry.find_child("Island_%s" % island.key,true,false)
		centers[island.key]=Vector2(island.c[0],island.c[1])
	for item in PLAN.ITEMS:
		var node := geometry.find_child("PlanItem_%s" % item.key,true,false)
		if node!=null: items[item.key]=node
	set_palace_state(items,civic)
	return {"root":root,"islands":islands,"items":items,"centers":centers}


static func build_proxy(parent: Node3D, village_center: Vector2, surface_y: float) -> Node3D:
	var root := Node3D.new()
	root.name="DistantLinyuan"
	parent.add_child(root)
	for island in PLAN.ISLANDS:
		var simplified: Dictionary=island.duplicate(true)
		var outline: Array=[]
		for i in range(0,island.outline.size()-1,24): outline.append(island.outline[i])
		outline.append(outline[0])
		simplified.outline=outline
		var land := _build_island(root,village_center,surface_y,simplified,Vector2(island.c[0],island.c[1]),false)
		# The proxy is a visual landmark. Authored collision arrives with detail
		# well before the party reaches the settlement's outermost bridge.
		var collision := land.get_node("IslandCollision")
		land.remove_child(collision)
		collision.free()
	for item in PLAN.ITEMS:
		if item.kind not in ["building","compound"]: continue
		var size := Vector2(item.rect[2],item.rect[3])
		var base := float(item.get("height",0.0))
		var eave := 3.25*float(item.get("storeys",1))
		if ARCHITECTURE.SPECS.has(item.key): eave=float(ARCHITECTURE.SPECS[item.key].column_height)+1.5
		var roof := _box(Vector3(size.x,0.8,size.y),Vector3(village_center.x+item.centre[0],surface_y+base+eave,village_center.y+item.centre[1]),PALACE if item.style=="palace" else ROOF,false)
		root.add_child(roof)
	for bridge in PLAN.BRIDGES:
		var a := Vector2(bridge.ends[0][0],bridge.ends[0][1])
		var b := Vector2(bridge.ends[1][0],bridge.ends[1][1])
		var midpoint := (a+b)*0.5
		var deck := _box(Vector3(float(bridge.width),0.25,a.distance_to(b)),Vector3(village_center.x+midpoint.x,surface_y,village_center.y+midpoint.y),BRIDGE_WOOD,false)
		deck.rotation.y=atan2(b.x-a.x,b.y-a.y)
		root.add_child(deck)
	StaticMerge.merge(root)
	return root


static func _build_island(parent: Node3D, village_center: Vector2, surface_y: float, data: Dictionary, center: Vector2, detail: bool = true) -> Node3D:
	var node := Node3D.new()
	node.name = "Island_%s" % data.key
	node.position = Vector3(village_center.x + center.x, surface_y, village_center.y + center.y)
	node.set_meta("plan_center", center)
	node.set_meta("walk_outline", data.outline)
	parent.add_child(node)
	var outline: Array = data.outline
	var polygon := PackedVector2Array()
	for p in outline:
		polygon.append(Vector2(float(p[0]) - center.x, float(p[1]) - center.y))
	if polygon.size() > 2 and polygon[0].is_equal_approx(polygon[polygon.size() - 1]):
		polygon.remove_at(polygon.size() - 1)
	var indices := Geometry2D.triangulate_polygon(polygon)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices := PackedVector3Array()
	for i in indices:
		var p := polygon[i]
		vertices.append(Vector3(p.x, 0.0, p.y))
		st.set_color(GRASS)
		st.add_vertex(Vector3(p.x, 0.0, p.y))
	st.generate_normals()
	var mesh := st.commit()
	var top := MeshInstance3D.new()
	top.name = "PlanGround"
	GroundPaint.mark_terrain(top)
	top.mesh = mesh
	var grass := StandardMaterial3D.new()
	grass.albedo_color = GRASS
	grass.roughness = 1.0
	grass.cull_mode = BaseMaterial3D.CULL_DISABLED
	top.material_override = grass
	node.add_child(top)
	top.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	var body := StaticBody3D.new()
	body.name = "IslandCollision"
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	collision.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(collision)
	node.add_child(body)
	if detail:
		var ponds: Array[Dictionary]=[]
		for pond in WATER.definitions():
			if pond.island==data.key: ponds.append(pond)
		if not ponds.is_empty():
			node.remove_child(top)
			top.free()
			node.remove_child(body)
			body.free()
			var cut := WATER.cut_floor(node,polygon,ponds,center,GRASS,"PlanGround")
			cut.layers|=GroundPaint.PAINT_LAYER
	var radial_size := 0.0
	for point in polygon:
		radial_size = maxf(radial_size,point.length())
	var keel_depth := radial_size*(0.9+posmod(float(abs(hash(data.key))),500.0)/1000.0)
	var keel_tip := Vector2(float(posmod(float(abs(hash(data.key+"x"))),1000.0)/1000.0-0.5),float(posmod(float(abs(hash(data.key+"z"))),1000.0)/1000.0-0.5))*radial_size*0.5
	_build_keel(node, polygon, keel_tip, keel_depth)
	return node


static func _build_keel(parent: Node3D, outline: PackedVector2Array, tip: Vector2, depth: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var material := StandardMaterial3D.new()
	material.albedo_color = ROCK
	material.roughness = 1.0
	material.vertex_color_use_as_albedo = true
	var strata := [
		{"t":0.0,"color":Color(0.31,0.29,0.27)},
		{"t":0.20,"color":Color(0.39,0.36,0.32)},
		{"t":0.43,"color":Color(0.27,0.26,0.25)},
		{"t":0.68,"color":Color(0.36,0.32,0.29)},
		{"t":0.86,"color":Color(0.24,0.24,0.23)},
		{"t":1.0,"color":Color(0.30,0.28,0.26)},
	]
	for i in outline.size():
		var a := outline[i]
		var b := outline[(i + 1) % outline.size()]
		for band in strata.size()-1:
			var t0 := float(strata[band].t)
			var t1 := float(strata[band+1].t)
			var top_scale := 1.0-pow(t0,0.62)
			var low_scale := 1.0-pow(t1,0.62)
			var top_a := Vector3(tip.x+(a.x-tip.x)*top_scale,lerpf(-0.05,-depth,t0),tip.y+(a.y-tip.y)*top_scale)
			var top_b := Vector3(tip.x+(b.x-tip.x)*top_scale,lerpf(-0.05,-depth,t0),tip.y+(b.y-tip.y)*top_scale)
			var low_a := Vector3(tip.x+(a.x-tip.x)*low_scale,lerpf(-0.05,-depth,t1),tip.y+(a.y-tip.y)*low_scale)
			var low_b := Vector3(tip.x+(b.x-tip.x)*low_scale,lerpf(-0.05,-depth,t1),tip.y+(b.y-tip.y)*low_scale)
			var band_color: Color = strata[band].color
			for v in [top_a,low_a,top_b,top_b,low_a,low_b]:
				st.set_color(band_color)
				st.add_vertex(v)
	st.generate_normals()
	var visual := MeshInstance3D.new()
	visual.name = "BrokenRockKeel"
	visual.mesh = st.commit()
	visual.material_override = material
	CollisionPolicy.mark_decorative(visual)
	parent.add_child(visual)


static func _build_fragment(parent: Node3D, village_center: Vector2, surface_y: float, data: Dictionary) -> void:
	var points := PackedVector2Array()
	for p in data.outline:
		points.append(Vector2(p[0], p[1]))
	if points.size() > 2 and points[0].is_equal_approx(points[points.size() - 1]):
		points.remove_at(points.size() - 1)
	if points.size() < 3:
		return
	var center := Vector2(data.c[0], data.c[1])
	var tris := Geometry2D.triangulate_polygon(points)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in tris:
		var p := points[i]
		st.set_color(ROCK)
		st.add_vertex(Vector3(p.x - center.x, 0.0, p.y - center.y))
	st.generate_normals()
	var shard := Node3D.new()
	shard.name = "DriftingFragment_%s" % data.key
	shard.position = Vector3(village_center.x + center.x, surface_y + float(data.dy), village_center.y + center.y)
	parent.add_child(shard)
	var mesh_node := MeshInstance3D.new()
	mesh_node.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ROCK
	mesh_node.material_override = mat
	shard.add_child(mesh_node)
	var collision_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = mesh_node.mesh.create_trimesh_shape()
	shape.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	collision_body.add_child(shape)
	shard.add_child(collision_body)


static func bridge_height(bridge: Dictionary, t: float) -> float:
	if bridge.kind!="chain": return 0.12+0.6*sin(PI*t)
	# The ends are bearing tails embedded in the banks. Sag belongs only to
	# the clear span; starting it inside the island buries the deck in ground.
	var start := float(bridge.bearing_start)
	var end := float(bridge.bearing_end)
	var u := clampf((t-start)/(1.0-start-end),0,1)
	return 0.12-float(bridge.sag)*4*u*(1-u)


static func _build_bridges(parent: Node3D, village_center: Vector2, surface_y: float) -> void:
	for bridge in PLAN.BRIDGES:
		var a := Vector2(bridge.ends[0][0],bridge.ends[0][1])
		var b := Vector2(bridge.ends[1][0],bridge.ends[1][1])
		var direction := (b-a).normalized()
		var side := Vector2(-direction.y,direction.x)
		var width := float(bridge.width)
		var root := Node3D.new()
		root.name="Bridge_%s_%s" % [bridge.a,bridge.b]
		root.position=Vector3(village_center.x,0,village_center.y)
		root.set_meta("bridge_kind",bridge.kind)
		root.set_meta("midspan_height",bridge_height(bridge,0.5))
		parent.add_child(root)
		var strips := maxi(24,ceili(a.distance_to(b)/0.65))
		for i in strips:
			var t0 := float(i)/strips
			var t1 := float(i+1)/strips
			var p0 := a.lerp(b,t0)
			var p1 := a.lerp(b,t1)
			var top0 := Vector3(p0.x,surface_y+bridge_height(bridge,t0),p0.y)
			var top1 := Vector3(p1.x,surface_y+bridge_height(bridge,t1),p1.y)
			var z_axis := (top1-top0).normalized()
			var x_axis := Vector3.UP.cross(z_axis).normalized()
			var normal := z_axis.cross(x_axis).normalized()
			var slab := _box(Vector3(width,0.24,top0.distance_to(top1)+0.025),(top0+top1)*0.5-normal*0.12,BRIDGE_WOOD.lightened(0.02*float(i%3)),true,STRUCTURAL_EPSILON,false)
			slab.name="BridgeDeckSegment"
			slab.basis=Basis(x_axis,normal,z_axis)
			root.add_child(slab)
		for edge in [-1.0,1.0]:
			var edge_points: Array[Vector3]=[]
			for i in strips+1:
				var t := float(i)/strips
				var p: Vector2=a.lerp(b,t)+side*edge*width*0.5
				edge_points.append(Vector3(p.x,surface_y+bridge_height(bridge,t)-0.10,p.y))
			INFRASTRUCTURE.deck_edge(root,edge_points,BRIDGE_WOOD.darkened(0.12))
		if bridge.kind=="chain":
			_build_chain_bridge_rails(root,a,b,side,width,surface_y,bridge)
			for end in [0,1]:
				var outward := direction if end==0 else -direction
				var point := a if end==0 else b
				INFRASTRUCTURE.anchorage(root,Vector3(point.x-outward.x*2.5,surface_y,point.y-outward.y*2.5),outward,width)
		else:
			_build_cantilever_bridge_gallery(root,a,b,direction,side,width,surface_y)
		_build_bridge_abutments(root,bridge,village_center,surface_y)


static func _build_stone_arch_bridge(root: Node3D, a: Vector2, b: Vector2, side: Vector2, width: float, surface_y: float, crown: float) -> void:
	# Short humpback bridge: a shallow crowned deck carried by visible stone
	# arch rings, with voussoir joints and solid parapets at the approaches.
	var length := a.distance_to(b)
	var stone := Color(0.52,0.51,0.47)
	var joints := Color(0.31,0.30,0.28)
	var blocks := maxi(12,ceili(length/0.52))
	for edge in [-1.0,1.0]:
		for i in blocks:
			var t0 := float(i)/blocks
			var t1 := float(i+1)/blocks
			var p0: Vector2 = a.lerp(b,t0)+side*edge*(width*0.5-0.16)
			var p1: Vector2 = a.lerp(b,t1)+side*edge*(width*0.5-0.16)
			var y0 := surface_y+crown*4.0*t0*(1.0-t0)-0.34
			var y1 := surface_y+crown*4.0*t1*(1.0-t1)-0.34
			var block := _beam_between(root,Vector3(p0.x,y0,p0.y),Vector3(p1.x,y1,p1.y),0.34,stone,false,STRUCTURAL_EPSILON)
			block.name = "ArchVoussoir_%d_%d" % [int(edge),i]
		for i in 12:
			var t0 := float(i)/12.0
			var t1 := float(i+1)/12.0
			var p0: Vector2 = a.lerp(b,t0)+side*edge*(width*0.5-0.12)
			var p1: Vector2 = a.lerp(b,t1)+side*edge*(width*0.5-0.12)
			var y0 := surface_y+crown*4.0*t0*(1.0-t0)+0.34
			var y1 := surface_y+crown*4.0*t1*(1.0-t1)+0.34
			_build_beam_between(root,Vector3(p0.x,y0,p0.y),Vector3(p1.x,y1,p1.y),Vector2(0.16,0.34),joints,true)



static func _build_chain_bridge_rails(root: Node3D, a: Vector2, b: Vector2, side: Vector2, width: float, surface_y: float, bridge: Dictionary) -> void:
	var length := a.distance_to(b)
	var link_count := maxi(12, ceili(length / 0.62))
	var rail_offset := (width - 0.18) * 0.5
	var iron := Color(0.22, 0.23, 0.22)
	var transforms: Array[Transform3D]=[]
	for edge in [-1.0, 1.0]:
		var previous := Vector3.ZERO
		for i in link_count + 1:
			var t := float(i) / float(link_count)
			var p: Vector2 = a.lerp(b, t) + side * edge * rail_offset
			var deck_y := surface_y+bridge_height(bridge,t)
			var point := Vector3(p.x, deck_y + 1.02, p.y)
			if i > 0:
				# Alternate forged oval links in vertical and horizontal planes.
				# The holes are real ring geometry; their tube meets the neighbor.
				var axis := (point-previous).normalized()
				var second := Vector3.UP if i%2==0 else Vector3(side.x,0,side.y)
				second=(second-axis*second.dot(axis)).normalized()
				var link_basis := Basis(axis*(previous.distance_to(point)*0.63/0.40),second,axis.cross(second))
				transforms.append(Transform3D(link_basis,(previous+point)*0.5))
			previous = point
		# The chain detail stays decorative; a continuous run of simple box
		# colliders carries the guard load without matching the link geometry.
		for i in 12:
			var t0 := float(i) / 12.0
			var t1 := float(i + 1) / 12.0
			var p0: Vector2 = a.lerp(b, t0) + side * edge * rail_offset
			var p1: Vector2 = a.lerp(b, t1) + side * edge * rail_offset
			var y0 := surface_y+bridge_height(bridge,t0)+1.02
			var y1 := surface_y+bridge_height(bridge,t1)+1.02
			var guard := _build_beam_between(root, Vector3(p0.x,y0,p0.y), Vector3(p1.x,y1,p1.y), Vector2(0.16,0.22), iron, true)
			guard.get_child(0).visible=false # Simple collision behind the open chain links.
		# Short hangers tie the chain rail back to the deck edge at regular bays.
		var hanger_count := maxi(4, ceili(length / 1.2))
		for i in range(1, hanger_count):
			var t := float(i) / float(hanger_count)
			var p: Vector2 = a.lerp(b,t) + side * edge * rail_offset
			var deck_y := surface_y+bridge_height(bridge,t)+0.10
			var rail_y := deck_y + 0.86
			_beam_between(root,Vector3(p.x,deck_y,p.y),Vector3(p.x,rail_y,p.y),0.075,iron,false,STRUCTURAL_EPSILON)


	# One shared ring mesh: detailing chains must not duplicate hundreds of
	# identical meshes in the settlement's static bake.
	var chain := MultiMeshInstance3D.new()
	chain.name="ForgedChainLinks"
	chain.multimesh=MultiMesh.new()
	chain.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	chain.multimesh.mesh=OpeningTrim.piped_mesh(OpeningTrim.window_loop(0.40,0.14,3.2,16),0.038,true)
	chain.multimesh.instance_count=transforms.size()
	# Visibility distance is measured at the instance origin. Bridge authoring
	# uses absolute island height, so keep the batch origin beside its links,
	# rather than at village Y=0 far below the floating settlement.
	var batch_origin := Vector3((a.x+b.x)*0.5,surface_y+bridge_height(bridge,0.5)+1.02,(a.y+b.y)*0.5)
	chain.position=batch_origin
	for i in transforms.size():
		var transform := transforms[i]
		transform.origin-=batch_origin
		transforms[i]=transform
	BAKE.store_instance_data(chain,transforms)
	var material := StandardMaterial3D.new()
	material.albedo_color=iron
	material.roughness=0.70
	material.metallic=0.35
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	chain.material_override=material
	chain.visibility_range_end=300.0
	chain.visibility_range_end_margin=20.0
	CollisionPolicy.mark_decorative(chain)
	root.add_child(chain)


static func _build_cantilever_bridge_gallery(root: Node3D, a: Vector2, b: Vector2, direction: Vector2, side: Vector2, width: float, surface_y: float) -> void:
	var length := a.distance_to(b)
	var edge_offset := width * 0.5 - 0.10
	var eave_height := 3.6
	var peak_height := 4.65
	var post_count := maxi(2, ceili(length / 3.5))
	var timber := Color(0.25, 0.16, 0.09)
	var roof_color := Color(0.22, 0.27, 0.24)
	for edge in [-1.0, 1.0]:
		var last_eave := Vector3.ZERO
		for i in post_count + 1:
			var t := float(i) / float(post_count)
			var p: Vector2 = a.lerp(b,t) + side * edge * edge_offset
			var foot := Vector3(p.x,surface_y + 0.12+0.6*sin(PI*t),p.y)
			var eave := Vector3(p.x,surface_y + eave_height,p.y)
			var post := _beam_between(root,foot,eave,0.22,timber,true,STRUCTURAL_EPSILON)
			post.name = "GalleryPost_%d_%d" % [int(edge),i]
			if i > 0:
				_build_beam_between(root,last_eave,eave,Vector2(0.22,0.22),timber,true)
			last_eave = eave
		# Cantilever log stacks originate behind each masonry face, not at
		# unsupported quarter-span points. Longitudinal trusses connect them.
		for end in [0,1]:
			var anchor := a if end==0 else b
			var outward := direction if end==0 else -direction
			for tier in 4:
				var reach := 1.5+float(tier)*2.2
				var p0: Vector2=anchor-outward*2.0+side*edge*edge_offset
				var p1: Vector2=anchor+outward*reach+side*edge*edge_offset
				var beam := _build_beam_between(root,Vector3(p0.x,surface_y-2.3+float(tier)*0.55,p0.y),Vector3(p1.x,surface_y-2.3+float(tier)*0.55,p1.y),Vector2(0.38,0.50),timber,true)
				beam.name="EmbeddedCantileverLog"
				var shoe := _box(Vector3(0.46,0.57,0.20),Vector3(p1.x,surface_y-2.3+float(tier)*0.55,p1.y),timber.darkened(0.12),true,STRUCTURAL_EPSILON,true)
				shoe.rotation.y=atan2(direction.x,direction.y)
				shoe.name="CantileverEndShoe"
				root.add_child(shoe)
		var bays := maxi(4,ceili(length/4.0))
		for i in bays:
			var t0 := float(i)/bays
			var t1 := float(i+1)/bays
			var p0: Vector2 = a.lerp(b,t0)+side*edge*edge_offset
			var p1: Vector2 = a.lerp(b,t1)+side*edge*edge_offset
			var y0 := surface_y-0.18+0.6*sin(PI*t0)
			var y1 := surface_y-0.18+0.6*sin(PI*t1)
			_build_beam_between(root,Vector3(p0.x,y0,p0.y),Vector3(p1.x,y1,p1.y),Vector2(0.22,0.32),timber,true)
			_build_beam_between(root,Vector3(p0.x,y0-1.6,p0.y),Vector3(p1.x,y1-1.6,p1.y),Vector2(0.22,0.30),timber,true)
			_build_beam_between(root,Vector3(p0.x,y0-1.6,p0.y),Vector3(p1.x,y1,p1.y),Vector2(0.18,0.20),timber,true)
	# Repeated paired rafters and SuperEgg roof slabs form a covered gabled gallery.
	var rafter_count := maxi(2, ceili(length / 2.8))
	for i in rafter_count + 1:
		var t := float(i) / float(rafter_count)
		var center := a.lerp(b,t)
		var ridge := Vector3(center.x,surface_y + peak_height,center.y)
		for edge in [-1.0,1.0]:
			var eave_2d: Vector2 = center + side * edge * (edge_offset + 0.75)
			var eave := Vector3(eave_2d.x,surface_y + eave_height,eave_2d.y)
			_build_beam_between(root,ridge,eave,Vector2(0.13,0.16),timber,false)
	# Narrow timber benches occupy the gallery edges; their back rails sit
	# below the guard line, leaving the center aisle open for traffic.
	for i in post_count:
		var t0 := float(i) / float(post_count)
		var t1 := float(i+1) / float(post_count)
		for edge in [-1.0,1.0]:
			var offset := edge_offset - 0.34
			var p0: Vector2 = a.lerp(b,t0) + side * edge * offset
			var p1: Vector2 = a.lerp(b,t1) + side * edge * offset
			var seat_a := Vector3(p0.x,surface_y+0.62+0.6*sin(PI*t0),p0.y)
			var seat_b := Vector3(p1.x,surface_y+0.62+0.6*sin(PI*t1),p1.y)
			_build_beam_between(root,seat_a,seat_b,Vector2(0.44,0.14),timber,true)
			var back_a := Vector3(p0.x+side.x*edge*0.16,surface_y+1.02+0.6*sin(PI*t0),p0.y+side.y*edge*0.16)
			var back_b := Vector3(p1.x+side.x*edge*0.16,surface_y+1.02+0.6*sin(PI*t1),p1.y+side.y*edge*0.16)
			_build_beam_between(root,back_a,back_b,Vector2(0.12,0.14),timber,true)
	var roof_half_width := edge_offset + 0.75
	var slope_length := Vector2(roof_half_width,peak_height-eave_height).length()
	for edge in [-1.0,1.0]:
		var eave_mid_2d: Vector2 = (a+b)*0.5 + side * edge * roof_half_width
		var eave_mid := Vector3(eave_mid_2d.x,surface_y + eave_height,eave_mid_2d.y)
		var ridge_mid := Vector3((a.x+b.x)*0.5,surface_y + peak_height,(a.y+b.y)*0.5)
		var span_axis := Vector3(direction.x,0.0,direction.y)
		var slope_axis := (eave_mid-ridge_mid).normalized()
		var normal_axis := slope_axis.cross(span_axis).normalized()
		var slab := TownProps.roof_slab(Vector3(length*0.5 + 0.35,0.11,slope_length*0.5 + 0.08),roof_color)
		slab.name = "GalleryRoofSlab_%d" % int(edge)
		slab.position = (eave_mid+ridge_mid)*0.5
		slab.basis = Basis(span_axis,normal_axis,slope_axis)
		root.add_child(slab)
		var roof_collider := _box(Vector3(length+0.7,0.16,slope_length+0.16),Vector3.ZERO,roof_color,true,STRUCTURAL_EPSILON,false)
		roof_collider.position = slab.position
		roof_collider.basis = slab.basis
		root.add_child(roof_collider)


static func _build_beam_between(root: Node3D, a: Vector3, b: Vector3, cross_section: Vector2, color: Color, collidable: bool) -> Node3D:
	return _beam_between_cross(root,a,b,cross_section,color,collidable,STRUCTURAL_EPSILON)


static func _beam_between(root: Node3D, a: Vector3, b: Vector3, thickness: float, color: Color, collidable: bool, epsilon: float) -> Node3D:
	var delta := b-a
	var length := delta.length()
	if length < 0.02:
		return Node3D.new()
	var z_axis := delta / length
	var x_axis := Vector3.UP.cross(z_axis).normalized()
	if x_axis.length_squared() < 0.01:
		x_axis = Vector3.RIGHT
	var y_axis := z_axis.cross(x_axis).normalized()
	var beam := _box(Vector3(thickness,thickness,length), (a+b)*0.5, color, collidable, epsilon, true)
	beam.basis = Basis(x_axis,y_axis,z_axis)
	root.add_child(beam)
	return beam


static func _beam_between_cross(root: Node3D, a: Vector3, b: Vector3, cross_section: Vector2, color: Color, collidable: bool, epsilon: float) -> Node3D:
	var delta := b-a
	var length := delta.length()
	if length < 0.02:
		return Node3D.new()
	var z_axis := delta / length
	var x_axis := Vector3.UP.cross(z_axis).normalized()
	if x_axis.length_squared() < 0.01:
		x_axis = Vector3.RIGHT
	var y_axis := z_axis.cross(x_axis).normalized()
	var beam := _box(Vector3(cross_section.x,cross_section.y,length),(a+b)*0.5,color,collidable,epsilon,true)
	beam.basis = Basis(x_axis,y_axis,z_axis)
	root.add_child(beam)
	return beam


static func _build_bridge_abutments(parent: Node3D, bridge: Dictionary, village_center: Vector2, surface_y: float) -> void:
	for abutment in PLAN.ABUTMENTS:
		if abutment.bridge != ("%s-%s" % [bridge.a,bridge.b]):
			continue
		var face := Vector2(abutment.face[0],abutment.face[1])
		var axis := Vector2(abutment.axis[0],abutment.axis[1])
		var frame := Node3D.new()
		frame.name="AbutmentBearing"
		frame.position=Vector3(face.x,surface_y,face.y)
		frame.rotation.y=atan2(axis.x,axis.y)
		parent.add_child(frame)
		_add_box(frame,Vector3(float(abutment.width)+0.2,0.18,0.5),Vector3(0,0.01,-0.25),FLAG,true)
		for course in range(1,5):
			_add_box(frame,Vector3(float(abutment.width),0.06,0.06),Vector3(0,-float(abutment.drop)*float(course)/5.0,0.02),ROCK.darkened(0.1),false)
		_add_box(frame,Vector3(float(abutment.width)*0.8,float(abutment.drop)*0.6,2.2),Vector3(0,-float(abutment.drop)*1.0,-1.4),ROCK,true)
		var outline := PackedVector2Array()
		for p in abutment.outline:
			outline.append(Vector2(p[0],p[1]))
		if outline.size()>2 and outline[0].is_equal_approx(outline[outline.size()-1]):
			outline.remove_at(outline.size()-1)
		if outline.size() < 3:
			continue
		var indices := Geometry2D.triangulate_polygon(outline)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in indices:
			var p := outline[i]
			st.set_color(BRICK)
			st.add_vertex(Vector3(p.x,-0.02,p.y))
		var drop := float(abutment.drop)
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i+1)%outline.size()]
			var top_a := Vector3(a.x,-0.02,a.y)
			var top_b := Vector3(b.x,-0.02,b.y)
			var bottom_a := Vector3(a.x,-drop,a.y)
			var bottom_b := Vector3(b.x,-drop,b.y)
			for vertex in [top_a,bottom_a,top_b,top_b,bottom_a,bottom_b]:
				st.set_color(BRICK)
				st.add_vertex(vertex)
		st.generate_normals()
		var mesh := MeshInstance3D.new()
		mesh.mesh = st.commit()
		var mat := StandardMaterial3D.new()
		mat.albedo_color = BRICK
		mesh.material_override = mat
		mesh.position.y = surface_y
		mesh.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
		parent.add_child(mesh)
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		collision.shape = mesh.mesh.create_trimesh_shape()
		collision.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
		body.add_child(collision)
		body.position.y = surface_y
		parent.add_child(body)


static func _build_item(parent: Node3D, village_center: Vector2, surface_y: float, item: Dictionary, centers: Dictionary) -> Node3D:
	var kind: String = item.kind
	var rect: Array = item.rect
	var center := Vector2(item.centre[0], item.centre[1])
	var width := float(rect[2])
	var depth := float(rect[3])
	var key: String = item.key
	if kind == "grove":
		_build_bamboo(parent, village_center, surface_y, center, width, depth)
		return null
	if kind == "field":
		_build_field(parent, village_center, surface_y, center, width, depth, key, item.get("outline", []))
		return null
	var node := Node3D.new()
	node.name = "PlanItem_%s" % key
	var item_height := float(item.get("height", 0.0)) if kind == "building" else 0.0
	node.position = Vector3(village_center.x + center.x, surface_y + item_height, village_center.y + center.y)
	var island_center: Vector2 = centers[item.island]
	node.set_meta("island_center", island_center)
	parent.add_child(node)
	var yaw := _door_yaw(String(item.get("door", "+z")))
	var floors := int(item.get("storeys", 1))
	# A compound's authored door defines its local frame. Rotate the complete
	# yard so its gate, house facade, walls and side room agree with the plan.
	# For east/west-facing yards that frame swaps its local width and depth.
	var compound_width := depth if String(item.get("door", "+z")) in ["+x", "-x"] else width
	var compound_depth := width if String(item.get("door", "+z")) in ["+x", "-x"] else depth
	if kind == "compound":
		# The plan's local +Z axis points toward the gate. Building shells
		# face local -Z, so their yaw differs from the enclosing yard frame by PI.
		node.rotation.y = yaw+PI
	var color := PALACE if item.island == "palace" else ROOF
	if key == "gatehouse":
		var gate := INFRASTRUCTURE.gatehouse(width,depth)
		gate.rotation.y=yaw+PI
		node.add_child(gate)
		return node
	if key == "inn":
		# Recreate the model's full 22 × 28 m compound around the separate
		# VillageInn gameplay shell: hall, west-front guest wing, north kitchen,
		# latrine, water jars, screen, partition moon gate and garden link.
		_build_compound_walls(node,item,width,depth)
		var court := _box(Vector3(width,0.08,depth),Vector3(0,0.04,0),Color(0.48,0.47,0.44),true)
		court.name = "InnFullCourtPaving"
		node.add_child(court)
		_build_inn_lattice_screen(node,width,depth)
		var guest_wing := _build_inn_outbuilding("InnGuestWing",6.5,4.4,Vector3(-8.4,0.0,9.4),PI/2)
		node.add_child(guest_wing)
		var kitchen := _build_inn_outbuilding("InnBackCourtKitchen",12.0,4.0,Vector3(-2.0,0.0,-11.6),0.0)
		node.add_child(kitchen)
		var latrine := _build_inn_outbuilding("InnLatrineCloset",2.4,2.2,Vector3(8.8,0.0,-12.2),0.0)
		node.add_child(latrine)
		Furnishings.piece(latrine,Vector3(0.28,0.25,0.28),Color(0.35,0.24,0.15),Vector3(0.0,0.26,0.0),0.0,true)
		Furnishings.washstand(latrine,Vector3(0.55,0.0,-0.2),0.0)
		for jar_index in 3:
			var jar := _build_inn_water_jar(Vector3(3.0+float(jar_index),0.0,-8.6))
			jar.name = "InnRoofWaterJar%d" % (jar_index+1)
			node.add_child(jar)
		_build_inn_back_partition(node,width)
		_build_inn_garden_connector(node,width)
		return node
	if kind in ["building", "compound"]:
		var style := String(item.get("style", "home"))
		var palace_service := style == "palace_service"
		var shell_width := compound_width if kind=="building" else compound_width-0.2
		var shell_depth := compound_depth if kind=="building" else 5.2
		if key == "pen":
			shell_width = width*0.62
			shell_depth = depth*0.52
		var cells_w := maxi(2, roundi(shell_width / TownProps.CELL_SIZE))
		var cells_d := maxi(2, roundi(shell_depth / TownProps.CELL_SIZE))
		var roof_family := String(item.get("roof","xieshan"))
		var green_roof := roof_family == "hard_gable_green"
		var roof_form: Dictionary = {}
		if roof_family in ["wudian2","cuanjian2"]:
			roof_form["hip_all"] = true
			if roof_family == "cuanjian2":
				roof_form["hip_inset"] = float(maxi(cells_w,cells_d))*TownProps.CELL_SIZE*0.5-0.18
		elif roof_family == "xieshan":
			roof_form["half_hip"] = -1.0
		var back_door_x := 0.0 if kind == "building" and bool(item.get("through",false)) else TownProps.NO_BACK_DOOR
		var ground_wall := PLASTER if style in ["home","shop","shed","gatehouse","palace_service"] else (IMPERIAL_RED if style=="palace" else WALL)
		var upper_wall := PLASTER if style in ["home","shop","shed","gatehouse","inn","palace_service"] else (IMPERIAL_RED if style=="palace" else WALL)
		var trim_color := Color(0.24,0.16,0.10) if style in ["home","shop","shed","gatehouse","palace_service"] else Color(0.45,0.13,0.07)
		var roof_mat := Color(0.17,0.31,0.23) if green_roof else (ROOF if palace_service else color)
		var entry_style := "civic" if key == "kitchen" else "door"
		var shell: StaticBody3D
		if kind=="compound":
			shell=ARCHITECTURE.build_home(shell_width,shell_depth)
			shell.rotation.y=yaw
		elif style=="palace" and ARCHITECTURE.SPECS.has(key):
			shell=ARCHITECTURE.build_hall(key,shell_width,shell_depth)
			# Authored halls face local +Z; TownProps shells face local -Z.
			shell.rotation.y=yaw+PI
		else:
			var x_scale:=shell_width/(cells_w*TownProps.CELL_SIZE)
			var clear_width:=2.2 if key=="pen" else 1.8
			var facade: Array=[{"wall":"south","floor":0,"replace_openings":[{"kind":"door","center":0.0,"width":clear_width/x_scale,"inward":key=="kitchen","bottom":0.0,"top":2.4,"leaves":2,"exponent":5.5,"interior":true}]}]
			shell=TownProps.build_building(cells_w,cells_d,floors,roof_mat,ground_wall,upper_wall,TownProps.FLOOR_COLOR,trim_color,"continuous_panel",false,entry_style,back_door_x,"lattice",roof_form,[],facade)
			shell.scale=Vector3(shell_width/(cells_w*TownProps.CELL_SIZE),1.0,shell_depth/(cells_d*TownProps.CELL_SIZE))
			shell.rotation.y=yaw
			_build_chinese_roof_details(shell,float(cells_w)*TownProps.CELL_SIZE,float(cells_d)*TownProps.CELL_SIZE,floors,roof_mat,style,roof_family)
		shell.name="PlanStructure"
		shell.set_meta("authored_footprint",Vector2(shell_width,shell_depth))
		if key=="pen":
			shell.position.z=depth*0.20
		if kind!="compound" and style in ["home","shop","shed","gatehouse","palace_service"]:
			_build_house_rank_details(shell,float(cells_w)*TownProps.CELL_SIZE,float(cells_d)*TownProps.CELL_SIZE,floors,not palace_service)
		if kind == "compound":
			_build_house_interior(shell,shell_width,shell_depth,key)
		if kind=="compound":
			# The three-bay main room occupies the north side of the court. Its
			# open timber-and-lattice front faces the entry court to the south.
			shell.position = Vector3(0.0,0.45,-compound_depth*0.5+shell_depth*0.5)
			shell.rotation.y = PI
		node.add_child(shell)
		if key == "pen":
			_build_animal_pen(node,width,depth)
		if kind == "compound":
			var compound_frame := item.duplicate(true)
			compound_frame.centre = [center.x,center.y]
			_build_compound_walls(node,compound_frame,compound_width,compound_depth)
			var shed_width := minf(5.5,compound_depth-5.2-3.5)
			var shed_depth := 3.2
			var shed_w_cells := maxi(1,roundi(shed_width/TownProps.CELL_SIZE))
			var shed_d_cells := maxi(2,roundi(shed_depth/TownProps.CELL_SIZE))
			var shed_x_scale := shed_width/(float(shed_w_cells)*TownProps.CELL_SIZE)
			var shed_facade: Array=[{"wall":"south","floor":0,"replace_openings":[{"kind":"door","center":0.0,"width":1.8/shed_x_scale,"bottom":0.0,"top":2.4,"leaves":2,"exponent":5.5,"interior":true}]}]
			var shed := TownProps.build_building(shed_w_cells,shed_d_cells,1,ROOF,PLASTER,PLASTER,TownProps.FLOOR_COLOR,Color(0.24,0.16,0.10),"continuous_panel",false,"door",TownProps.NO_BACK_DOOR,"lattice",{},[],shed_facade)
			shed.name = "EastYardSideShed"
			shed.scale = Vector3(shed_width/(shed_w_cells*TownProps.CELL_SIZE),1.0,shed_depth/(shed_d_cells*TownProps.CELL_SIZE))
			_build_chinese_roof_details(shed,float(shed_w_cells)*TownProps.CELL_SIZE,float(shed_d_cells)*TownProps.CELL_SIZE,1,ROOF,"shed","hard_gable")
			var z_court := -compound_depth*0.5+5.2
			var shed_z := z_court+0.6+shed_width*0.5
			shed.position = Vector3(compound_width*0.5-1.8,0.0,shed_z)
			shed.rotation.y = PI*0.5
			node.add_child(shed)
			# The household path is only where feet repeatedly pass: a narrow
			# brick walk from gate to the main-room threshold, with a cross-run to
			# the side shed; the rest of the court remains packed earth.
			var walk_start := -compound_depth*0.5+shell_depth+0.80
			var walk_end := compound_depth*0.5-0.05
			var walk_length := walk_end-walk_start
			var walk := _box(Vector3(1.5,0.035,walk_length),Vector3(0,0.0475,(walk_start+walk_end)*0.5),BRICK,false)
			walk.name = "CourtyardBrickCrossWalk"
			var walk_visual := walk.get_child(0) as MeshInstance3D
			walk_visual.material_override = _path_surface_material("brick",Vector2(1.2,walk_length))
			node.add_child(walk)
			# Butt the side run to the main walk without coplanar overlap. Its
			# other end meets the side shed's actual rotated doorway.
			var side_end := compound_width*0.5-1.8-shed_depth*0.5
			if side_end>0.75:
				var side_walk := _box(Vector3(side_end-0.75,0.035,1.5),Vector3((side_end+0.75)*0.5,0.0475,shed_z),BRICK,false)
				side_walk.name="CourtyardShedWalk"
				(side_walk.get_child(0) as MeshInstance3D).material_override=_path_surface_material("brick",Vector2.ONE)
				node.add_child(side_walk)
			var stores := StaticBody3D.new()
			stores.name="HouseholdYardStores"
			node.add_child(stores)
			Furnishings.log_basket(stores,Vector3(-compound_width*0.5+0.9,0,shed_z))
			var jar := _build_inn_water_jar(Vector3(-compound_width*0.5+1.1,0,compound_depth*0.5-1.2))
			jar.name="HouseholdWaterJar"
			node.add_child(jar)
			_build_household_workyard(node,compound_width,compound_depth,key)
		if key=="gate_pavilion":
			_add_box(node,Vector3(width,1.2,11.0),Vector3(0,-0.6,0),ARCHITECTURE.MARBLE,true)
		if key == "apartments":
			_build_raised_piers(node,width,depth,float(item_height))
		elif key == "high_pavilion":
			_build_tapered_mound(node,width,depth,float(item_height))
			_add_box(node,Vector3(width+2.4,0.25,depth+2.4),Vector3(0,-0.125,0),ARCHITECTURE.MARBLE,true)
			ARCHITECTURE.balustrade(node,[Vector3(-6,0,6),Vector3(-6,0,-6),Vector3(6,0,-6),Vector3(6,0,6)],[Vector3(5.7,6,2.2)],1.05)
	elif kind == "platform":
		var height := float(item.get("height", 0.25))
		if key=="throne_terrace":
			_build_throne_terrace(node,width,depth)
		else:
			_add_box(node,Vector3(width,height,depth),Vector3(0,height*0.5,0),Color(0.78,0.75,0.68),true)
			ARCHITECTURE.platform_edges(node,width,depth,0.0,height)
			if key=="inner_court":
				ARCHITECTURE.balustrade(node,[Vector3(-width*0.5+0.2,height,depth*0.5-0.2),Vector3(-width*0.5+0.2,height,-depth*0.5+0.2),Vector3(width*0.5-0.2,height,-depth*0.5+0.2),Vector3(width*0.5-0.2,height,depth*0.5-0.2)],[Vector3(-6,-depth*0.5,2.4),Vector3(-width*0.5,0,3.0),Vector3(width*0.5,-5.2,2.6)])
				ARCHITECTURE.balustrade(node,[Vector3(-width*0.5+0.2,height,depth*0.5-0.2),Vector3(width*0.5-0.2,height,depth*0.5-0.2)],[Vector3(-16,depth*0.5,2.2),Vector3(16,depth*0.5,2.2)])

	elif kind == "court":
		var paving_kind := String(item.get("paving", "earth"))
		if paving_kind in ["earth","threshing"]: return node # Island ground paint owns these unraised yards.
		var paving := _surface_color(paving_kind, bool(item.get("island", "") == "palace"))
		var court_floor := _box(Vector3(width, 0.06, depth), Vector3(0, 0.035, 0), paving, false)
		court_floor.name = "CourtPaving_%s" % paving_kind
		var floor_visual := court_floor.get_child(0) as MeshInstance3D
		floor_visual.material_override = _path_surface_material(paving_kind, Vector2(width, depth))
		if key in ["market_square","gate_forecourt"]:
			# Unenclosed courts have a softly squared outline, not a raw plate.
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for i in 96:
				var ring: Array[Vector3]=[]
				for j in [i,i+1]:
					var angle := TAU*float(j)/96.0
					ring.append(Vector3(signf(cos(angle))*pow(absf(cos(angle)),2.0/5.5)*width*0.5,0.03,signf(sin(angle))*pow(absf(sin(angle)),2.0/5.5)*depth*0.5))
				for point in [Vector3(0,0.03,0),ring[0],ring[1]]:
					st.set_normal(Vector3.UP)
					st.add_vertex(point)
			floor_visual.mesh=st.commit()
			floor_visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		if key in ["inn_garden","pond_court"]:
			court_floor.free()
			var ponds: Array[Dictionary]=[]
			for pond in WATER.definitions():
				if pond.key==key: ponds.append(pond)
			var shape := PackedVector2Array([Vector2(-width*0.5,-depth*0.5),Vector2(width*0.5,-depth*0.5),Vector2(width*0.5,depth*0.5),Vector2(-width*0.5,depth*0.5)])
			var cut := WATER.cut_floor(node,shape,ponds,center,paving,"CourtPaving_"+paving_kind)
			cut.position.y=0.065-0.35
			cut.material=_path_surface_material(paving_kind,Vector2(width,depth))
		else:
			node.add_child(court_floor)
		if paving_kind == "imperial":
			var axis := _box(Vector3(minf(5.0, width * 0.30), 0.13, depth * 0.94), Vector3(0, 0.12, 0), Color(0.78, 0.76, 0.70), true)
			axis.name = "RaisedImperialMarbleWay"
			node.add_child(axis)
		if bool(item.get("garden",false)):
			_build_compound_walls(node,item,width,depth)
			_build_garden_court(node,width,depth,key)
	elif kind == "feature":
		if key == "well":
			_build_well(node)
		elif key == "sealing_rock":
			pass
		elif key == "chen_stall":
			var stall := TownProps.build_stall(Color(0.58,0.13,0.09))
			var body: StaticBody3D = stall["body"]
			body.set_meta("counter_y",float(stall["counter_y"]))
			body.scale = Vector3(width/4.8,1.0,depth/3.2)
			node.add_child(body)
		else:
			_add_box(node,Vector3(width,0.5,depth),Vector3(0,0.25,0),ROCK,true,ORGANIC_EPSILON)
	return node


static func _build_throne_terrace(parent: Node3D, width: float, depth: float) -> void:
	var north := -depth*0.5
	for tier in 3:
		var half_width := width*0.5-float(tier)*2.5
		# Each 1.4 m rise needs 2.24 m of flight plus a 1.2 m landing.
		var south := depth*0.5-float(tier)*3.44
		var y := float(tier+1)*1.4
		var course := _box(Vector3(half_width*2.0,1.4,south-north),Vector3(0,y-0.7,(south+north)*0.5),ARCHITECTURE.MARBLE,true)
		course.name="MarbleTerraceTier%d" % (tier+1)
		parent.add_child(course)
		ARCHITECTURE.platform_edges(parent,half_width*2.0,south-north,y-1.4,1.4,Vector2(0,(south+north)*0.5))
		ARCHITECTURE.balustrade(parent,[Vector3(-half_width+0.2,y,north+0.2),Vector3(-half_width+0.2,y,south-0.2),Vector3(half_width-0.2,y,south-0.2),Vector3(half_width-0.2,y,north+0.2)],[Vector3(0,south,2.1)])
		if tier==2:
			ARCHITECTURE.balustrade(parent,[Vector3(-half_width+0.2,y,north+0.2),Vector3(half_width-0.2,y,north+0.2)],[Vector3(-16,north,2.2),Vector3(16,north,2.2)])


static func _build_chinese_roof_details(shell: StaticBody3D, width: float, depth: float, floors: int, roof_color: Color, style: String, roof_family: String) -> void:
	var wall_top := float(floors) * TownProps.FLOOR_HEIGHT
	var eave_z := depth * 0.5 + TownProps.ROOF_EAVE_OVERHANG
	var ridge_y := TownProps.roof_center_y(wall_top, depth * 0.5, 0.0)
	var timber := Color(0.24,0.16,0.10) if style in ["home", "shop", "shed", "gatehouse", "palace_service"] else Color(0.48,0.16,0.07)
	var imperial := style == "palace"
	var inn := style == "inn"
	var bracketed := imperial or inn
	var eave_color := roof_color.lightened(0.12) if imperial else roof_color.darkened(0.08)
	# Cross courses catch light on grey tile and break the reused shell roof into
	# the smaller, weathered runs shown in the village model.
	for side in [-1.0,1.0]:
		var course_count := maxi(4,ceili(depth*0.5/0.55))
		for index in course_count:
			var distance := 0.42+float(index)*maxf(0.0,(depth*0.5+TownProps.ROOF_EAVE_OVERHANG-0.52)/float(maxi(1,course_count-1)))
			var course := _flat_box_mesh(Vector3(width+0.34,0.026,0.055),roof_color.darkened(0.12))
			course.position = Vector3(0,ridge_y-distance*tan(TownProps.ROOF_PITCH),side*distance)
			course.rotation.x = side*TownProps.ROOF_PITCH
			shell.add_child(course)
			CollisionPolicy.mark_decorative(course)
	# Eave fascia and the exposed rafter rhythm make the ordinary hard-gable
	# roofs read as built timber under grey tile. The inn and palace earn deeper,
	# supported eaves from their rank charter.
	for side in [-1.0, 1.0]:
		var fascia := SuperEgg.build_part(Vector3(width * 0.5 + 0.30,0.07,0.08),eave_color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		fascia.position = Vector3(0,wall_top+0.04,side*eave_z)
		shell.add_child(fascia)
		CollisionPolicy.mark_decorative(fascia)
		var rafter_count := maxi(5,ceili(width/0.85))
		for i in rafter_count+1:
			var x := lerpf(-width*0.5,width*0.5,float(i)/float(rafter_count))
			var rafter := SuperEgg.build_part(Vector3(0.045,0.045,0.13),timber,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
			rafter.position = Vector3(x,wall_top-0.09,side*(depth*0.5+0.10))
			shell.add_child(rafter)
			CollisionPolicy.mark_decorative(rafter)
		if bracketed:
			var bay_count := maxi(2,ceili(width/3.2))
			for i in bay_count+1:
				var x := lerpf(-width*0.5,width*0.5,float(i)/float(bay_count))
				var corbel := SuperEgg.build_part(Vector3(0.22,0.055,0.10),timber,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
				corbel.position = Vector3(x,wall_top-0.20,side*(depth*0.5-0.08))
				shell.add_child(corbel)
				CollisionPolicy.mark_decorative(corbel)
				var brace := _local_beam(shell,Vector3(x,wall_top-0.38,side*(depth*0.5-0.15)),Vector3(x,wall_top+0.04,side*eave_z),0.075,timber)
				CollisionPolicy.mark_decorative(brace)
	if roof_family in ["wudian2","cuanjian2"]:
		# Double-eave palace roofs have a real lower skirt of four sloped
		# roof planes. The previous thin horizontal bars read as trim, not a
		# second roof tier. The base hipped roof above remains the upper tier.
		var lower_y := wall_top-0.18
		var lower_run := 1.8
		var lower_pitch := deg_to_rad(24.0)
		var outer_x := width*0.5+1.10
		var outer_z := depth*0.5+1.10
		var panel_y := lower_y+tan(lower_pitch)*lower_run*0.5
		for side in [-1.0,1.0]:
			var z_panel := _box(Vector3(width+2.2,0.24,lower_run),Vector3(0,panel_y,side*(outer_z-lower_run*0.5)),roof_color,true)
			z_panel.name = "LowerDoubleEaveRoofPlane"
			z_panel.rotation.x = side*lower_pitch
			shell.add_child(z_panel)
			var x_panel := _box(Vector3(lower_run,0.24,depth+2.2),Vector3(side*(outer_x-lower_run*0.5),panel_y,0),roof_color,true)
			x_panel.name = "LowerDoubleEaveEndPlane"
			x_panel.rotation.z = -side*lower_pitch
			shell.add_child(x_panel)
			var lower_bays := maxi(2,ceili(width/3.2))
			for i in lower_bays+1:
				var x := lerpf(-width*0.5,width*0.5,float(i)/float(lower_bays))
				var brace := _local_beam(shell,Vector3(x,lower_y-0.28,side*(depth*0.5-0.08)),Vector3(x,panel_y,side*outer_z),0.10,timber)
				CollisionPolicy.mark_decorative(brace)
	# Ridge caps are continuous load-spreading timbers with ceramic end pieces.
	var ridge_color := Color(0.18,0.40,0.28) if roof_family == "hard_gable_green" else eave_color
	# TownProps pitches its roof across Z; the ridge therefore runs along X.
	# Use a glazed cap strip in the correct roof plane, not a rounded beam.
	var ridge := _flat_box_mesh(Vector3(width+0.52,0.18,0.28),ridge_color)
	ridge.position = Vector3(0,TownProps.roof_top_y(wall_top,depth*0.5,0.0)+0.08,0)
	shell.add_child(ridge)
	CollisionPolicy.mark_decorative(ridge)
	for x_sign in [-1.0,1.0]:
		var end_color := Color(0.70,0.55,0.24) if imperial else ridge_color
		var endcap := SuperEgg.build_part(Vector3(0.18,0.16,0.20),end_color,2.2,2.2)
		endcap.position = Vector3(x_sign*(width*0.5+0.28),TownProps.roof_top_y(wall_top,depth*0.5,0.0)+0.08,0)
		shell.add_child(endcap)
		CollisionPolicy.mark_decorative(endcap)
	# The vernacular charter calls for restrained, nearly straight eaves. Keep
	# their gable ends square; only palace-rank roofs receive a modest corner
	# lift. A village-wide turned-up tail would read as generic pagoda trim.
	for x_sign in [-1.0,1.0]:
		for z_sign in [-1.0,1.0]:
			var p0 := Vector3(x_sign*(width*0.5-0.12),wall_top+0.03,z_sign*(depth*0.5+0.10))
			var lift := 0.14 if imperial else 0.0
			var p1 := p0+Vector3(x_sign*0.24,lift*0.45,z_sign*0.20)
			var p2 := p1+Vector3(x_sign*0.16,lift*0.55,z_sign*0.14)
			_local_beam(shell,p0,p1,0.12,timber)
			if imperial:
				_local_beam(shell,p1,p2,0.10,eave_color)
			if bracketed:
				var support := _local_beam(shell,p0+Vector3(0,-0.48,0),p1,0.07,timber)
				CollisionPolicy.mark_decorative(support)
	if roof_family == "cuanjian2":
		var finial := SuperEgg.build_part(Vector3(0.20,0.42,0.20),Color(0.78,0.60,0.18),2.0,2.0)
		finial.position = Vector3(0,ridge_y+0.38,0)
		shell.add_child(finial)
		CollisionPolicy.mark_decorative(finial)


static func _local_beam(parent: Node3D, start: Vector3, finish: Vector3, thickness: float, color: Color) -> MeshInstance3D:
	var delta := finish-start
	var beam := SuperEgg.build_part(Vector3(thickness,delta.length()*0.5,thickness),color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	beam.position = (start+finish)*0.5
	beam.quaternion = Quaternion(Vector3.UP,delta.normalized())
	parent.add_child(beam)
	return beam


static func _build_house_rank_details(shell: StaticBody3D, width: float, depth: float, floors: int = 1, add_couplets: bool = true) -> void:
	var brick := Color(0.43,0.41,0.38)
	var timber := Color(0.25,0.17,0.11)
	var half_w := width*0.5
	var half_d := depth*0.5
	var gable_y := TownProps.roof_center_y(float(floors)*TownProps.FLOOR_HEIGHT,half_d,0.0)
	# Brick end walls close the hard-gable triangles, a key Chinese village
	# profile absent from the shared Ohio-style plaster gable infill.
	for side in [-1.0,1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for point: Vector3 in [Vector3(side*(half_w+0.015),float(floors)*TownProps.FLOOR_HEIGHT,-half_d),Vector3(side*(half_w+0.015),float(floors)*TownProps.FLOOR_HEIGHT,half_d),Vector3(side*(half_w+0.015),gable_y,0.0)]:
			st.set_color(brick)
			st.add_vertex(point)
		st.generate_normals()
		var gable := MeshInstance3D.new()
		gable.name = "BrickHardGableEnd"
		gable.mesh = st.commit()
		var gable_material := StandardMaterial3D.new()
		gable_material.albedo_color = brick
		gable_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		gable_material.roughness = 1.0
		gable.material_override = gable_material
		shell.add_child(gable)
		CollisionPolicy.mark_decorative(gable)
	var plinth_h := 0.90
	var door_half := 1.15
	# Brick weathering course around the base; leave a broad clear threshold on
	# the south-facing entrance so the raised sill does not become a step wall.
	var segments := [
		{"size":Vector3(maxf(0.0,half_w-door_half),plinth_h,0.24),"at":Vector3((-half_w-door_half)*0.5,plinth_h*0.5,-half_d-0.08)},
		{"size":Vector3(maxf(0.0,half_w-door_half),plinth_h,0.24),"at":Vector3((half_w+door_half)*0.5,plinth_h*0.5,-half_d-0.08)},
		{"size":Vector3(width,plinth_h,0.24),"at":Vector3(0,plinth_h*0.5,half_d+0.08)},
		{"size":Vector3(0.24,plinth_h,depth),"at":Vector3(-half_w-0.08,plinth_h*0.5,0)},
		{"size":Vector3(0.24,plinth_h,depth),"at":Vector3(half_w+0.08,plinth_h*0.5,0)},
	]
	for segment in segments:
		var size: Vector3 = segment.size
		if size.x<0.1 or size.z<0.1:
			continue
		var visual := _flat_box_mesh(size,brick)
		visual.position = segment.at
		shell.add_child(visual)
		CollisionPolicy.add_box(shell,visual,size,visual.position,Basis.IDENTITY,false)
	# Brick corner piers carry the eaves and frame the white plaster panels.
	for x_sign in [-1.0,1.0]:
		for z_sign in [-1.0,1.0]:
			var size := Vector3(0.34,2.55,0.34)
			var at := Vector3(x_sign*(half_w-0.20),1.26,z_sign*(half_d-0.20))
			var pier := _flat_box_mesh(size,brick)
			pier.position = at
			shell.add_child(pier)
			CollisionPolicy.add_box(shell,pier,size,at,Basis.IDENTITY,false)
	# Unlettered red couplet boards flank each main door. A thin crossbar reads
	# as painted timber, with no readable in-world writing.
	if add_couplets:
		for x_sign in [-1.0,1.0]:
			var board := SuperEgg.build_part(Vector3(0.11,0.82,0.035),Color(0.64,0.10,0.075),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
			board.position = Vector3(x_sign*(door_half+0.25),1.36,-half_d-0.17)
			shell.add_child(board)
			CollisionPolicy.mark_decorative(board)
	var lintel := SuperEgg.build_part(Vector3(door_half+0.28,0.075,0.06),timber,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	lintel.position = Vector3(0,2.42,-half_d-0.16)
	shell.add_child(lintel)
	CollisionPolicy.mark_decorative(lintel)


static func _build_animal_pen(parent: Node3D, width: float, depth: float) -> void:
	var half_w := width*0.40
	var front_z := -depth*0.44
	var back_z := -depth*0.10
	var timber := Color(0.34,0.24,0.15)
	for x in [-half_w,0.0,half_w]:
		for z in [front_z,back_z]:
			if is_zero_approx(x): continue
			var post := _box(Vector3(0.16,1.15,0.16),Vector3(x,0.58,z),timber,true)
			post.name = "PandyPenPost"
			parent.add_child(post)
	for side in [-1.0,1.0]:
		for y in [0.40,0.88]:
			var rail := _box(Vector3(0.12,0.12,back_z-front_z),Vector3(side*half_w,y,(front_z+back_z)*0.5),timber,true)
			parent.add_child(rail)
	# The south side is gated, leaving a clear opening to the farm path.
	for side in [-1.0,1.0]:
		var rail_width := half_w-0.82
		for y in [0.40,0.88]:
			var rail := _box(Vector3(rail_width,0.12,0.12),Vector3(side*(0.82+rail_width*0.5),y,front_z),timber,true)
			parent.add_child(rail)
	var trough := _box(Vector3(1.35,0.42,0.48),Vector3(-half_w+0.9,0.25,(front_z+back_z)*0.5),Color(0.38,0.28,0.18),true)
	trough.name = "PandyFeedTrough"
	parent.add_child(trough)
	for index in 3:
		var hay := SuperEgg.build_part(Vector3(0.28,0.20,0.25),Color(0.66,0.55,0.30),2.6,3.0)
		hay.position = Vector3(half_w-0.7,0.25,back_z-0.45-float(index)*0.55)
		parent.add_child(hay)
		CollisionPolicy.mark_decorative(hay)


static func _build_house_interior(shell: StaticBody3D, width: float, depth: float, key: String) -> void:
	var dark_wood := Color(0.25,0.17,0.11)
	# A low brick kang and a small firebox establish the household's warm,
	# shared sleeping and eating room without crowding its doorway.
	var kang := Furnishings.piece(shell,Vector3(minf(1.45,width*0.28),0.28,minf(0.78,depth*0.19)),Color(0.50,0.36,0.25),Vector3(-width*0.22,0.30,depth*0.23),0.0,true)
	kang.name = "BrickKang"
	Furnishings.table(shell,Vector3(width*0.16,0.0,-depth*0.06),0.0,1.25,0.78,"benches",dark_wood)
	Furnishings.piece(shell,Vector3(0.34,0.40,0.30),Color(0.38,0.25,0.16),Vector3(width*0.30,0.42,depth*0.20),0.0,true,2.5)
	Furnishings.piece(shell,Vector3(0.42,0.06,0.35),Color(0.22,0.16,0.11),Vector3(width*0.30,0.88,depth*0.20),0.0,false)
	Furnishings.piece(shell,Vector3(0.24,0.32,0.24),Color(0.35,0.25,0.15),Vector3(-width*0.30,1.65,-depth*0.28),0.0,false)
	if key in ["lantern_home", "tile_home", "bao_house", "roofer_home"]:
		var shelf := Furnishings.piece(shell,Vector3(minf(0.80,width*0.17),0.07,0.22),Color(0.30,0.20,0.13),Vector3(width*0.28,1.45,-depth*0.28),0.0,true)
		shelf.name = "HouseholdTradeShelf"
	if key == "bao_house":
		TradeFurnishings.kneading_table(shell,Vector3(-width*0.25,0.0,-depth*0.20),0.0,1.5)
		TradeFurnishings.loaf_rack(shell,Vector3(width*0.30,0.0,-depth*0.22),0.0,1.1)
	elif key == "lantern_home":
		TradeFurnishings.workbench(shell,Vector3(width*0.25,0.0,-depth*0.20),0.0,1.5)
	elif key == "roofer_home" or key == "tile_home":
		TradeFurnishings.timber_rack(shell,Vector3(width*0.27,0.0,-depth*0.22),0.0,1.3)


static func _build_paths(parent: Node3D, village_center: Vector2, surface_y: float) -> void:
	for island in PLAN.ISLANDS:
		var strokes: Array=[]
		var blobs: Array=[]
		for item in PLAN.ITEMS:
			if item.island!=island.key: continue
			if item.kind=="compound" or (item.kind=="court" and item.get("paving","") in ["earth","threshing"]):
				blobs.append({"center":village_center+Vector2(item.centre[0],item.centre[1]),"radii":Vector2(item.rect[2]*0.48,item.rect[3]*0.48)})
		for path in PLAN.PATHS:
			if path.island!=island.key or path.surface not in ["earth","slab"]: continue
			var line: Array[Vector2]=[]
			for point in path.pts: line.append(village_center+Vector2(point[0],point[1]))
			strokes.append({"points":line,"width":float(path.width)})
		if not strokes.is_empty() or not blobs.is_empty():
			var paint := GroundPaint.paint(parent,strokes,blobs,surface_y,"LinyuanWornGround_"+String(island.key),Color(0.49,0.40,0.28),Color(0.65,0.55,0.39),0.88,710+String(island.key).length())
			paint.size.y=0.5
	# Plan-time union and constrained triangulation supply clean junctions and
	# holes. Never draw one ribbon per route over another route or court.
	for network in PLAN.PAVING_NETWORK:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in network.triangles:
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(village_center.x+point[0],surface_y+0.065,village_center.y+point[1]))
		var visual := MeshInstance3D.new()
		visual.name="ConstructedWalk_"+String(network.island)
		visual.mesh=st.commit()
		visual.material_override=_path_surface_material("flag",Vector2.ONE)
		visual.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		CollisionPolicy.mark_decorative(visual) # Unraised finish on physical island ground.
		parent.add_child(visual)
	for path in PLAN.PATHS:
		if path.surface=="bund":
			var bank_line: Array[Vector2]=[]
			for point in path.pts: bank_line.append(village_center+Vector2(point[0],point[1]))
			INFRASTRUCTURE.raised_bank(parent,bank_line,float(path.width),surface_y)
		if String(path.get("kind", ""))=="corridor":
			_build_covered_corridor(parent,path.pts,village_center,surface_y,float(path.width))


## Plain material by design: the owner rejected printed repeating paving.
static func _path_surface_material(surface: String, _dimensions: Vector2) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(0.50,0.51,0.47) if surface in ["garden","pebble","imperial"] else Color(0.56,0.55,0.50)
	mat.roughness=0.94
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	return mat


static func _build_covered_corridor(parent: Node3D, points: Array, village_center: Vector2, surface_y: float, width: float) -> void:
	for index in points.size()-1:
		var a := Vector2(points[index][0],points[index][1])
		var b := Vector2(points[index+1][0],points[index+1][1])
		var length := a.distance_to(b)
		if length<0.1: continue
		var direction := (b-a)/length
		var gallery := StaticBody3D.new()
		gallery.name="CoveredGardenWalk"
		gallery.position=Vector3(village_center.x+(a.x+b.x)*0.5,surface_y,village_center.y+(a.y+b.y)*0.5)
		gallery.rotation.y=atan2(-direction.y,direction.x)
		parent.add_child(gallery,true)
		var green := Color(0.16,0.30,0.25)
		var stone := Color(0.53,0.52,0.47)
		var bays := maxi(1,ceili(length/2.4))
		for i in bays+1:
			var x := -length*0.5+length*float(i)/float(bays)
			for side in [-1.0,1.0]:
				var z: float=side*width*0.43
				var world_point:=Vector2((gallery.transform*Vector3(x,0,z)).x-village_center.x,(gallery.transform*Vector3(x,0,z)).z-village_center.y)
				var doorway_clear:=false
				for opening in PLAN.OPENINGS:
					if opening.get("passage",false) and world_point.distance_to(Vector2(opening.edge[0],opening.edge[1]))<1.2: doorway_clear=true
				if doorway_clear: continue
				ARCHITECTURE.block(gallery,"GalleryStoneShoe",Vector3(0.38,0.22,0.38),Vector3(x,0.11,z),stone,true)
				ARCHITECTURE.block(gallery,"GalleryColumn",Vector3(0.22,2.75,0.22),Vector3(x,1.56,z),green,true)
			ARCHITECTURE.block(gallery,"GalleryCrossTie",Vector3(0.19,0.24,width+0.12),Vector3(x,2.91,0),green,true)
		for side in [-1.0,1.0]:
			ARCHITECTURE.block(gallery,"GalleryEaveBeam",Vector3(length+0.25,0.26,0.23),Vector3(0,2.94,side*width*0.43),green,true)
		ARCHITECTURE._frustum(gallery,length*0.5+0.25,width*0.5+0.30,maxf(0.001,length*0.5-width*0.5),0.001,3.08,0.85,PALACE,"GardenGalleryHipRoof")
		ARCHITECTURE.block(gallery,"GalleryRidgeCap",Vector3(maxf(0.40,length-width+0.35),0.20,0.26),Vector3(0,3.98,0),PALACE,false)
		StaticMerge.merge(gallery)


static func _build_opening_frames(parent: Node3D, village_center: Vector2, surface_y: float, civic_state: bool) -> void:
	for opening in PLAN.OPENINGS:
		if opening.item in ["gatehouse","gate_pavilion"]: continue # The four-metre arch is the opening.
		var edge := Vector2(opening.edge[0],opening.edge[1])
		var normal := Vector2(opening.normal[0],opening.normal[1]).normalized()
		var width := float(opening.width)
		var kind := String(opening.get("kind","door"))
		var floor_y := surface_y+float(opening.get("level",0.0))
		var color := Color(0.71,0.67,0.58) if opening.island=="palace" else BRICK
		var frame: MeshInstance3D
		if not bool(opening.get("passage",false)):
			var loop := OpeningTrim.window_loop(width*0.5,width*0.5,2.6)
			frame = OpeningTrim.piped_frame(loop,0.10,color,true)
			var frame_position := Vector3(village_center.x+edge.x,floor_y+1.45,village_center.y+edge.y)
			frame.position = frame_position
			frame.rotation.y = atan2(normal.x,normal.y)
			parent.add_child(frame)
			if kind == "round":
				# Small circular paper windows use a calm square lattice. The bars
				# stay within the opening and share its wall-facing plane.
				var lattice_color := Color(0.24,0.16,0.10)
				for index in 3:
					var offset := (float(index)-1.0)*width*0.20
					var upright := SuperEgg.build_part(Vector3(0.025,width*0.37,0.025),lattice_color,STRUCTURAL_EPSILON,STRUCTURAL_EPSILON)
					upright.position = frame_position+Basis(Vector3.UP,frame.rotation.y)*Vector3(offset,0.0,0.0)
					upright.rotation.y = frame.rotation.y
					parent.add_child(upright)
					CollisionPolicy.mark_decorative(upright)
					var crossbar := SuperEgg.build_part(Vector3(width*0.37,0.025,0.025),lattice_color,STRUCTURAL_EPSILON,STRUCTURAL_EPSILON)
					crossbar.position = frame_position+Basis(Vector3.UP,frame.rotation.y)*Vector3(0.0,offset,0.0)
					crossbar.rotation.y = frame.rotation.y
					parent.add_child(crossbar)
					CollisionPolicy.mark_decorative(crossbar)
			continue
		var height := width if kind=="moon" else (2.75 if kind=="gate" else 2.45)
		var exponent := 2.0 if kind=="moon" else (3.5 if kind=="oct" else 5.5)
		var arch := OpeningTrim.door_arch(width*0.5,height,exponent,0.55,0.02)
		frame = OpeningTrim.piped_frame(arch,0.11,color,false)
		frame.position = Vector3(village_center.x+edge.x,floor_y,village_center.y+edge.y)
		frame.rotation.y = atan2(normal.x,normal.y)
		parent.add_child(frame)
		if opening.item == "rock_garden" and opening.side == "w" and kind == "moon":
			# The western garden moon gate is a real stateful pair of leaves. It
			# is closed while Liang Zhen keeps the garden private and opens with
			# the palace's civic conversion.
			var gate = WORLD_DOOR_SCRIPT.new()
			gate.name = "WestGardenMoonGate"
			gate.position = Vector3(village_center.x+edge.x,floor_y,village_center.y+edge.y)
			gate.rotation.y = atan2(normal.x,normal.y)
			parent.add_child(gate)
			gate.configure(width*0.5,height,2,Color(0.28,0.18,0.12),civic_state)
		if String(opening.item) in ["inn", "roofer_home", "westend_home", "lantern_home", "tile_home", "bao_house", "carrier_home", "farm_home"]:
			# Plain tile coping makes the threshold legible without giving a home
			# the palace's bracket or lacquer treatment.
			var lintel := SuperEgg.build_part(Vector3(width * 0.58, 0.075, 0.10), Color(0.36,0.34,0.30), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			lintel.position = Vector3(village_center.x+edge.x,floor_y+height+0.08,village_center.y+edge.y)
			lintel.rotation.y = atan2(normal.x,normal.y)
			parent.add_child(lintel)
			CollisionPolicy.mark_decorative(lintel)


static func _build_compound_walls(parent: Node3D, item: Dictionary, width: float, depth: float) -> void:
	var shihu_wall := String(item.key) in ["inn", "inn_garden"]
	var garden_wall := String(item.key) in ["moon_court", "pond_court", "rock_garden", "bamboo_court"]
	var household_wall := String(item.key) in ["roofer_home","westend_home","lantern_home","tile_home","bao_house","carrier_home","farm_home"]
	# The palace borrows Shihu openings but keeps its imperial material rank:
	# vermilion panels, pale dado and yellow coping. Domestic gardens retain
	# grey brick and lime plaster.
	var mixed_wall := shihu_wall or garden_wall or household_wall
	var wall_coping := shihu_wall or garden_wall or bool(item.get("wave_coping",false))
	var wall_height := 2.8 if item.key=="inn" else (2.6 if item.key=="inn_garden" else 2.4)
	var openings: Array = []
	for opening in PLAN.OPENINGS:
		if opening.island == item.island and opening.item == item.key and bool(opening.get("passage",false)):
			openings.append(opening)
	for side in ["w","e","n","s"]:
		# In the household courtyard plan the main room forms the north edge of
		# the yard. Its back wall replaces a north compound wall, and the side
		# garden walls begin at the house's south facade instead of passing through it.
		var household_compound := String(item.key) in ["roofer_home","westend_home","lantern_home","tile_home","bao_house","carrier_home","farm_home"]
		if household_compound and side=="n":
			continue
		var along_x: bool = side in ["n","s"]
		var half := width*0.5 if along_x else depth*0.5
		var edge_z := -depth*0.5 if side=="n" else depth*0.5
		var edge_x := width*0.5 if side=="e" else -width*0.5
		var cuts: Array[Vector2] = []
		for opening in openings:
			if opening.side != side:
				continue
			var offset := float(opening.at)
			if opening.side in ["n", "e"]:
				offset = -offset
			var aperture := float(opening.width)
			cuts.append(Vector2(maxf(-half,offset-aperture*0.5),minf(half,offset+aperture*0.5)))
		cuts.sort_custom(func(a: Vector2,b: Vector2)->bool: return a.x < b.x)
		var cursor := -half
		if household_compound and side in ["w","e"]:
			cursor = maxf(cursor,-depth*0.5+5.2)
		for cut in cuts:
			if cut.x > cursor+0.25 and cut.y > cursor:
				_add_wall_segment(parent,along_x,cursor,cut.x,edge_x,edge_z,width,depth,wall_coping,mixed_wall,wall_height,garden_wall)
			cursor = maxf(cursor,cut.y)
		if cursor < half-0.25:
			_add_wall_segment(parent,along_x,cursor,half,edge_x,edge_z,width,depth,wall_coping,mixed_wall,wall_height,garden_wall)
		for cut in cuts:
			for end in [cut.x,cut.y]:
				var pillar_pos := Vector3(end,1.15,edge_z) if along_x else Vector3(edge_x,1.15,end)
				pillar_pos.y = wall_height*0.5
				var pillar_size := Vector3(0.34,wall_height-0.12,0.34)
				_add_box(parent,pillar_size,pillar_pos,SHIHU_BRICK if mixed_wall else BRICK,true)


static func _add_wall_segment(parent: Node3D, along_x: bool, start: float, finish: float, edge_x: float, edge_z: float, _width: float, _depth: float, wave_coping: bool = false, mixed_wall: bool = false, wall_height: float = 2.4, imperial: bool = false) -> void:
	var length := finish-start
	var size := Vector3(length,wall_height,0.28) if along_x else Vector3(0.28,wall_height,length)
	var pos := Vector3((start+finish)*0.5,wall_height*0.5,edge_z) if along_x else Vector3(edge_x,wall_height*0.5,(start+finish)*0.5)
	_add_box(parent,size,pos,ARCHITECTURE.MARBLE if imperial else (SHIHU_BRICK if mixed_wall else BRICK),true)
	if mixed_wall:
		# Grey brick weathering dado and piers frame lime-plaster wall panels.
		var dado_h := 0.82
		var panel_h := wall_height-dado_h-0.30
		var panel_count := maxi(1,ceili(length/3.2))
		for i in panel_count:
			var panel_center := lerpf(start+0.34,finish-0.34,(float(i)+0.5)/float(panel_count))
			var panel_length := (length-0.68)/float(panel_count)-0.18
			if panel_length <= 0.22:
				continue
			var panel_size := Vector3(panel_length,panel_h,0.10) if along_x else Vector3(0.10,panel_h,panel_length)
			var panel_face := (signf(edge_z) if along_x else signf(edge_x))*0.16
			var panel_pos := Vector3(panel_center,dado_h+panel_h*0.5,edge_z+panel_face) if along_x else Vector3(edge_x+panel_face,dado_h+panel_h*0.5,panel_center)
			_add_box(parent,panel_size,panel_pos,IMPERIAL_RED if imperial else SHIHU_PLASTER,false,STRUCTURAL_EPSILON,false)
			# Both faces are finished, including the view from inside the court.
			var inner_pos := panel_pos
			if along_x: inner_pos.z=edge_z-panel_face
			else: inner_pos.x=edge_x-panel_face
			_add_box(parent,panel_size,inner_pos,IMPERIAL_RED if imperial else SHIHU_PLASTER,false,STRUCTURAL_EPSILON,false)
		# Regular brick piers carry the coping and make each plaster bay legible.
		for i in range(panel_count+1):
			var pier_at := lerpf(start+0.17,finish-0.17,float(i)/float(panel_count))
			var pier_size := Vector3(0.32,wall_height-0.12,0.34) if along_x else Vector3(0.34,wall_height-0.12,0.32)
			var pier_pos := Vector3(pier_at,(wall_height-0.12)*0.5,edge_z) if along_x else Vector3(edge_x,(wall_height-0.12)*0.5,pier_at)
			_add_box(parent,pier_size,pier_pos,ARCHITECTURE.MARBLE if imperial else SHIHU_BRICK,true)
	for end in [start,finish]:
		var end_pos := Vector3(end,wall_height*0.5,edge_z) if along_x else Vector3(edge_x,wall_height*0.5,end)
		_add_box(parent,Vector3(0.42,wall_height+0.10,0.42),end_pos,ARCHITECTURE.MARBLE if imperial else SHIHU_BRICK,true)
		_add_box(parent,Vector3(0.52,0.18,0.52),end_pos+Vector3.UP*(wall_height*0.5+0.10),ARCHITECTURE.GLAZE if imperial else ROOF,true)
	if wave_coping:
		var count := maxi(1,ceili(length/0.72))
		for i in count:
			var along := lerpf(start,finish,(float(i)+0.5)/float(count))
			var tile := SuperEgg.build_part(Vector3(length/float(count)*0.54,0.10,0.24),ARCHITECTURE.GLAZE if imperial else Color(0.38,0.40,0.39),STRUCTURAL_EPSILON,STRUCTURAL_EPSILON,6,10)
			if not along_x: tile.rotation.y=PI*0.5
			tile.position = Vector3(along,wall_height+0.06+((i%2)*0.035),edge_z) if along_x else Vector3(edge_x,wall_height+0.06+((i%2)*0.035),along)
			parent.add_child(tile)
			CollisionPolicy.mark_decorative(tile)
	else:
		var cap_size := Vector3(length,0.14,0.42) if along_x else Vector3(0.42,0.14,length)
		var cap_pos := Vector3((start+finish)*0.5,wall_height+0.07,edge_z) if along_x else Vector3(edge_x,wall_height+0.07,(start+finish)*0.5)
		var cap := SuperEgg.build_part(cap_size*0.5,Color(0.37,0.39,0.38),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		cap.position = cap_pos
		parent.add_child(cap)
		CollisionPolicy.mark_decorative(cap)


static func _build_inn_lattice_screen(parent: Node3D, _width: float, depth: float) -> void:
	# An open masonry lattice: the old solid visible backing plugged every
	# aperture. The continuous collision guard represents openings too small
	# for a body, while the actual screen remains visibly punched through.
	var body := StaticBody3D.new()
	body.name="InnBrickLatticeScreen"
	body.position=Vector3(0,0,depth*0.5-3.2)
	parent.add_child(body)
	ARCHITECTURE.block(body,"ScreenPlinth",Vector3(6.1,0.32,0.36),Vector3(0,0.16,0),SHIHU_BRICK,true)
	for side in [-1.0,1.0]:
		ARCHITECTURE.block(body,"ScreenEndPier",Vector3(0.30,2.4,0.34),Vector3(side*2.95,1.2,0),SHIHU_BRICK,true)
	ARCHITECTURE.block(body,"ScreenCoping",Vector3(6.25,0.20,0.44),Vector3(0,2.4,0),ROOF,true)
	for i in range(1,10):
		ARCHITECTURE.block(body,"BrickLatticeUpright",Vector3(0.13,2.06,0.20),Vector3(-3.0+float(i)*0.6,1.33,0),SHIHU_BRICK.lightened(0.06),false)
	for i in 5:
		ARCHITECTURE.block(body,"BrickLatticeCourse",Vector3(5.9,0.13,0.20),Vector3(0,0.53+float(i)*0.45,0),SHIHU_BRICK.lightened(0.06),false)
	var guard := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=Vector3(6.0,2.4,0.20)
	guard.shape=shape
	guard.position.y=1.2
	guard.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(guard)


static func _build_inn_outbuilding(label: String, width: float, depth: float, at: Vector3, yaw: float) -> StaticBody3D:
	var cells_w := maxi(1,roundi(width/TownProps.CELL_SIZE))
	var cells_d := maxi(1,roundi(depth/TownProps.CELL_SIZE))
	var shell := TownProps.build_building(cells_w,cells_d,1,ROOF,PLASTER,PLASTER,TownProps.FLOOR_COLOR,Color(0.28,0.16,0.11),"continuous_panel",false,"door",TownProps.NO_BACK_DOOR,"lattice")
	shell.name = label
	shell.scale = Vector3(width/(float(cells_w)*TownProps.CELL_SIZE),1.0,depth/(float(cells_d)*TownProps.CELL_SIZE))
	shell.position = at
	shell.rotation.y = yaw
	_build_house_rank_details(shell,float(cells_w)*TownProps.CELL_SIZE,float(cells_d)*TownProps.CELL_SIZE)
	_build_chinese_roof_details(shell,float(cells_w)*TownProps.CELL_SIZE,float(cells_d)*TownProps.CELL_SIZE,1,ROOF,"inn","hard_gable")
	return shell


static func _build_inn_water_jar(at: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var vessel := CylinderMesh.new()
	vessel.top_radius = 0.27
	vessel.bottom_radius = 0.36
	vessel.height = 0.84
	vessel.radial_segments = 12
	var visual := MeshInstance3D.new()
	visual.mesh = vessel
	visual.position.y = 0.42
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.39,0.35,0.30)
	mat.roughness = 0.82
	visual.material_override = mat
	body.add_child(visual)
	var rim := OpeningTrim.piped_frame(OpeningTrim.window_loop(0.28,0.28,2.5),0.045,Color(0.34,0.30,0.27),true)
	rim.rotation.x=PI*0.5
	rim.position.y=0.82
	body.add_child(rim)
	CollisionPolicy.mark_decorative(rim)
	var interior := SuperEgg.build_part(Vector3(0.245,0.014,0.245),Color(0.12,0.11,0.09),2.5,2.5,4,24)
	interior.position.y=0.815
	body.add_child(interior)
	CollisionPolicy.mark_decorative(interior)
	var collider := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.38
	shape.height = 0.88
	collider.shape = shape
	collider.position.y = 0.44
	collider.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.SOLID)
	body.add_child(collider)
	visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.SOLID)
	body.position = at
	return body


static func _build_inn_back_partition(parent: Node3D, width: float) -> void:
	# This cross-wall separates the front and service courts. Its 2.2 m moon
	# gate is the direct continuation of the common-room passage.
	var z := -0.5
	var wall_height := 2.8
	var opening_half := 1.1
	var start_x := width*0.5-4.4+0.2
	var end_x := width*0.5
	for span in [Vector2(start_x,8.9-opening_half),Vector2(8.9+opening_half,end_x)]:
		if span.y <= span.x:
			continue
		_add_box(parent,Vector3(span.y-span.x,wall_height,0.34),Vector3((span.x+span.y)*0.5,wall_height*0.5,z),SHIHU_BRICK,true)
		_add_box(parent,Vector3(span.y-span.x-0.30,wall_height-0.95,0.10),Vector3((span.x+span.y)*0.5,0.95+(wall_height-0.95)*0.5,z-0.20),SHIHU_PLASTER,false,STRUCTURAL_EPSILON,false)
	var arch := OpeningTrim.door_arch(opening_half,2.2,2.0,0.55,0.02)
	var trim := OpeningTrim.piped_frame(arch,0.12,SHIHU_BRICK,true)
	trim.position = Vector3(8.9,0.0,z)
	parent.add_child(trim)


static func _build_inn_garden_connector(parent: Node3D, _width: float) -> void:
	# The plan puts the two aligned moon gates 3.5 m apart. A short covered
	# corridor joins their thresholds instead of leaving the garden detached.
	var x0 := 11.0
	var x1 := 14.5
	var center_x := (x0+x1)*0.5
	var gate_z := -9.0
	_add_box(parent,Vector3(x1-x0,0.08,2.2),Vector3(center_x,0.04,gate_z),Color(0.47,0.46,0.43),true)
	for side in [-1.0,1.0]:
		var wall := _add_box(parent,Vector3(x1-x0,2.35,0.22),Vector3(center_x,1.18,gate_z+side*1.1),SHIHU_BRICK,true)
		wall.name = "InnGardenLinkWall"
		var panel := _add_box(parent,Vector3(x1-x0-0.3,1.30,0.08),Vector3(center_x,1.37,gate_z+side*1.24),SHIHU_PLASTER,false,STRUCTURAL_EPSILON,false)
		panel.name = "InnGardenLinkPlaster"
	for x in [x0,x1]:
		for side in [-1.0,1.0]:
			_add_box(parent,Vector3(0.20,2.65,0.20),Vector3(x,1.32,gate_z+side*1.0),Color(0.45,0.17,0.10),true)
	var roof_frame := StaticBody3D.new()
	roof_frame.name="InnToGardenCoveredGalleryRoof"
	roof_frame.position=Vector3(center_x,0,gate_z)
	parent.add_child(roof_frame)
	ARCHITECTURE._frustum(roof_frame,(x1-x0)*0.5+0.30,1.43,0.30,0.001,2.78,0.75,ROOF,"InnGalleryHipRoof")
	ARCHITECTURE.block(roof_frame,"InnGalleryRidge",Vector3(0.85,0.20,0.27),Vector3(0,3.57,0),ROOF,false)


static func _build_edge_parapets(parent: Node3D, village_center: Vector2, surface_y: float, _centers: Dictionary) -> void:
	# The generator already clips these polylines around paths, doorways and
	# every bridge apron; render those authored segments directly.
	for record in PLAN.PARAPETS:
		var points: Array = record.pts
		var color := Color(0.67,0.64,0.57) if record.kind=="marble" else (Color(0.31,0.22,0.15) if record.kind=="fence" else SHIHU_BRICK)
		if record.kind=="marble":
			var vertices: Array[Vector3]=[]
			for point in points: vertices.append(Vector3(village_center.x+point[0],surface_y,village_center.y+point[1]))
			ARCHITECTURE.balustrade(parent,vertices,[],1.05)
			continue
		for i in points.size()-1:
			var a := Vector2(points[i][0],points[i][1])
			var b := Vector2(points[i+1][0],points[i+1][1])
			var length := a.distance_to(b)
			if length < 0.3:
				continue
			var rail := _box(Vector3(0.24,0.78,length),Vector3(village_center.x+(a.x+b.x)*0.5,surface_y+0.40,village_center.y+(a.y+b.y)*0.5),color,true)
			rail.rotation.y = atan2(b.x-a.x,b.y-a.y)
			parent.add_child(rail)
			var from := Vector3(village_center.x+a.x,surface_y+0.83,village_center.y+a.y)
			var to := Vector3(village_center.x+b.x,surface_y+0.83,village_center.y+b.y)
			_build_beam_between(parent,from,to,Vector2(0.38,0.16),ROOF,true)
			for at in [from,to]:
				_add_box(parent,Vector3(0.36,0.88,0.36),at-Vector3.UP*0.39,color,true,STRUCTURAL_EPSILON,true)


static func _near_landing(point: Vector2, island: String) -> bool:
	for bridge in PLAN.BRIDGES:
		for side in [0,1]:
			var key: String = bridge.a if side==0 else bridge.b
			if key != island:
				continue
			var end: Array = bridge.ends[side]
			if point.distance_to(Vector2(end[0],end[1])) < float(bridge.width)+5.5:
				return true
	return false


static func _build_plan_details(parent: Node3D, village_center: Vector2, surface_y: float, centers: Dictionary, items: Dictionary, civic_state: bool) -> void:
	# The model's pavilion forecourt is a real raised platform, not only a
	# node in the plan's route graph. Its top joins the inner court at +5.6 m.
	var palace: Vector2=centers["palace"]
	var plinth := _box(Vector3(14.9,5.6,7.0),Vector3(village_center.x+palace.x-0.05,surface_y+2.8,village_center.y+palace.y-34.5),ARCHITECTURE.MARBLE,true)
	plinth.name="PavilionForecourtPlinth"
	parent.add_child(plinth)
	ARCHITECTURE.platform_edges(parent,14.9,7.0,surface_y,5.6,village_center+palace+Vector2(-0.05,-34.5))
	var levels := {"gate base":1.2,"ground":0.0,"terrace":4.2,"inner court":5.6,"pavilion plinth":5.6,"mound":9.8}
	for ramp in PLAN.RAMPS:
		var a := Vector2(ramp.foot[0],ramp.foot[1])
		var b := Vector2(ramp.head[0],ramp.head[1])
		var length := a.distance_to(b)
		var from_y := float(levels.get(String(ramp.a),0.0))
		var to_y := float(levels.get(String(ramp.b),0.0))
		var yaw := atan2(b.x-a.x,b.y-a.y) if length>0.01 else 0.0
		if length < 0.1:
			continue
		var sections: Array = ramp.get("segments",[])
		if not sections.is_empty():
			for section in sections:
				var section_a := Vector2(float(section.a[0]),float(section.a[1]))
				var section_b := Vector2(float(section.b[0]),float(section.b[1]))
				var section_length := section_a.distance_to(section_b)
				if section_length < 0.1:
					continue
				var section_yaw := atan2(section_b.x-section_a.x,section_b.y-section_a.y)
				if String(section.kind) == "flight":
					_build_plan_ramp_flight(parent,village_center,surface_y,section_a,section_b,float(section.from_y),float(section.to_y),float(ramp.width),section_yaw)
				else:
					var landing := _box(Vector3(float(ramp.width),0.16,section_length),Vector3(village_center.x+(section_a.x+section_b.x)*0.5,surface_y+float(section.height)-0.08,village_center.y+(section_a.y+section_b.y)*0.5),Color(0.78,0.76,0.71),true)
					landing.name = "PlanRampLanding"
					landing.rotation.y = section_yaw
					parent.add_child(landing)
					if ramp.drawn=="kitchen" and float(section.height)>0.16:
						var height := float(section.height)-0.16
						var base := _box(Vector3(float(ramp.width),height,section_length),Vector3(village_center.x+(section_a.x+section_b.x)*0.5,surface_y+height*0.5,village_center.y+(section_a.y+section_b.y)*0.5),Color(0.66,0.64,0.60),true)
						base.name="LandingMasonrySupport"
						base.rotation.y=section_yaw
						parent.add_child(base)
			continue
		var landing_length := minf(float(ramp.get("landing_length",0.0)),length*0.35)
		if landing_length > 0.1 and not is_equal_approx(from_y,to_y):
			var direction := (b-a).normalized()
			var flight_length := (length-landing_length)*0.5
			var mid_a := a+direction*flight_length
			var mid_b := mid_a+direction*landing_length
			var mid_y := (from_y+to_y)*0.5
			_build_plan_ramp_flight(parent,village_center,surface_y,a,mid_a,from_y,mid_y,float(ramp.width),yaw)
			var landing := _box(Vector3(float(ramp.width),0.16,landing_length),Vector3(village_center.x+(mid_a.x+mid_b.x)*0.5,surface_y+mid_y-0.08,village_center.y+(mid_a.y+mid_b.y)*0.5),Color(0.70,0.67,0.60),true)
			landing.name = "PlanRampLanding"
			landing.rotation.y = yaw
			parent.add_child(landing)
			_build_plan_ramp_flight(parent,village_center,surface_y,mid_b,b,mid_y,to_y,float(ramp.width),yaw)
			continue
		var slope := atan2(to_y-from_y,length)
		var midpoint := (a+b)*0.5
		var ramp_body := _box(Vector3(float(ramp.width),0.16,length/cos(slope)),Vector3(village_center.x+midpoint.x,surface_y+(from_y+to_y)*0.5-0.08/cos(slope),village_center.y+midpoint.y),Color(0.70,0.67,0.60),true)
		ramp_body.name = "AccessiblePlanRamp"
		ramp_body.rotation = Vector3(-slope,yaw,0.0)
		parent.add_child(ramp_body)
	_build_plan_program_details(items)
	set_palace_state(items, civic_state)


static func _build_plan_ramp_flight(parent: Node3D, village_center: Vector2, surface_y: float, foot: Vector2, head: Vector2, from_y: float, to_y: float, width: float, yaw: float) -> void:
	var run := foot.distance_to(head)
	if run < 0.1:
		return
	var slope := atan2(to_y-from_y,run)
	var midpoint := (foot+head)*0.5
	var body := _box(Vector3(width,0.16,run/cos(slope)),Vector3(village_center.x+midpoint.x,surface_y+(from_y+to_y)*0.5-0.08/cos(slope),village_center.y+midpoint.y),Color(0.78,0.76,0.71),true)
	body.name = "AccessiblePlanRampFlight"
	body.rotation = Vector3(-slope,yaw,0.0)
	parent.add_child(body)
	var direction := (head-foot).normalized()
	var side := Vector2(-direction.y,direction.x)*(width*0.5-0.12)
	for sign_value in [-1.0,1.0]:
		ARCHITECTURE.balustrade(parent,[Vector3(village_center.x+foot.x+side.x*sign_value,surface_y+from_y,village_center.y+foot.y+side.y*sign_value),Vector3(village_center.x+head.x+side.x*sign_value,surface_y+to_y,village_center.y+head.y+side.y*sign_value)],[],1.05)
	_build_ramp_support(parent,village_center,surface_y,foot,head,from_y,to_y,width)



static func _build_ramp_support(parent: Node3D, village_center: Vector2, surface_y: float, a: Vector2, b: Vector2, ay: float, by: float, width: float) -> void:
	var side := (b-a).orthogonal().normalized()*width*0.5
	var corners := [a+side,b+side,b-side,a-side]
	var heights := [maxf(0.0,ay-0.18),maxf(0.0,by-0.18),maxf(0.0,by-0.18),maxf(0.0,ay-0.18)]
	var top: Array[Vector3]=[]
	var bottom: Array[Vector3]=[]
	for i in 4:
		top.append(Vector3(village_center.x+corners[i].x,surface_y+heights[i],village_center.y+corners[i].y))
		bottom.append(Vector3(village_center.x+corners[i].x,surface_y-0.2,village_center.y+corners[i].y))
	var points := PackedVector3Array()
	for i in 4:
		var j := (i+1)%4
		points.append_array([bottom[i],top[j],bottom[j],bottom[i],top[i],top[j]])
	points.append_array([top[0],top[2],top[1],top[0],top[3],top[2],bottom[0],bottom[1],bottom[2],bottom[0],bottom[2],bottom[3]])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in points: st.add_vertex(point)
	st.generate_normals()
	var support := StaticBody3D.new()
	support.name="RampMasonrySupport"
	support.collision_layer=1
	support.collision_mask=0
	var visual := MeshInstance3D.new()
	visual.mesh=st.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color=Color(0.66,0.64,0.60)
	visual.material_override=material
	support.add_child(visual)
	visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.SOLID)
	var collider := CollisionShape3D.new()
	collider.shape=visual.mesh.create_trimesh_shape()
	collider.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.SOLID)
	support.add_child(collider)
	parent.add_child(support)


static func set_palace_state(items: Dictionary, civic: bool) -> void:
	# The palace shell is shared by both story states. Only these contained
	# fittings change when Liang Zhen gives up the imperial office.
	for key in ["gate_pavilion", "throne_hall", "dining_hall", "apartments", "chef_quarters", "high_pavilion"]:
		var item: Node3D = items.get(key)
		if not is_instance_valid(item):
			continue
		var shell := item.get_node_or_null("PlanStructure") as StaticBody3D
		if shell == null:
			continue
		var open := civic
		if key == "chef_quarters":
			open = true
		for descendant in shell.find_children("*", "Node", true, false):
			if descendant.has_method("set_open_state"):
				descendant.set_open_state(open)
		if key == "gate_pavilion":
			continue
		var old := shell.get_node_or_null("PalaceStateFurniture")
		if old != null:
			old.queue_free()
		var furniture := StaticBody3D.new()
		furniture.name = "PalaceStateFurniture"
		furniture.collision_layer = 1
		furniture.collision_mask = 0
		shell.add_child(furniture)
		match key:
			"throne_hall": _dress_throne_hall(furniture, civic)
			"dining_hall": _dress_palace_dining(furniture, civic)
			"apartments": _dress_apartments(furniture, civic)
			"chef_quarters": _dress_former_chef_room(furniture, civic)
			"high_pavilion": _dress_viewing_pavilion(furniture, civic)
	var yard: Node3D = items.get("service_yard")
	if is_instance_valid(yard) and yard.get_node_or_null("PalaceWaterAndSanitation") == null:
		var service := Node3D.new()
		service.name = "PalaceWaterAndSanitation"
		yard.add_child(service)
		_build_well(service)
		var closet := TownProps.build_building(1,1,1,Color(0.31,0.32,0.30),PLASTER,PLASTER,TownProps.FLOOR_COLOR,BRIDGE_WOOD,"continuous_panel",false,"door")
		closet.name = "ServiceYardLatrineCloset"
		closet.position = Vector3(2.9,0.0,-10.4)
		service.add_child(closet)
		Furnishings.piece(closet,Vector3(0.28,0.24,0.28),Color(0.35,0.24,0.15),Vector3(0.0,0.24,0.0),0.0,true)
		Furnishings.washstand(closet,Vector3(0.0,0.0,0.65),PI)


static func _dress_throne_hall(body: StaticBody3D, civic: bool) -> void:
	if civic:
		Furnishings.piece(body,Vector3(1.45,0.28,0.72),Color(0.54,0.39,0.26),Vector3(0.0,0.32,-5.0),0.0,true)
		for x in [-8.5,-5.4,-2.3,2.3,5.4,8.5]:
			Furnishings.bench(body,Vector3(x,0.0,-2.4),0.0,2.55)
		for z in [0.5,3.2]:
			Furnishings.bench(body,Vector3(-10.2,0.0,z),PI*0.5,2.2)
			Furnishings.bench(body,Vector3(10.2,0.0,z),-PI*0.5,2.2)
		Furnishings.table(body,Vector3(0.0,0.0,4.1),0.0,2.8,1.25,"benches",Color(0.28,0.18,0.12))
		var vase := _box(Vector3(0.42,0.74,0.42),Vector3(4.0,0.37,-4.0),Color(0.44,0.23,0.13),true)
		body.add_child(vase)
		for x in [3.78,4.0,4.22]:
			var bamboo := _cylinder(1.7,0.035,Vector3(x,1.55,-4.0),Color(0.27,0.43,0.20),false)
			body.add_child(bamboo)
	else:
		var dais := _box(Vector3(5.0,0.46,2.8),Vector3(0,0.23,-5.2),Color(0.55,0.40,0.28),true)
		dais.name = "ThroneDais"
		body.add_child(dais)
		Furnishings.armchair(body,Vector3(0.0,0.46,-5.5),PI,Color(0.64,0.13,0.08))
		var screen := _box(Vector3(5.4,3.2,0.16),Vector3(0.0,2.1,-7.0),Color(0.29,0.09,0.07),false)
		screen.name = "CarvedThroneScreen"
		body.add_child(screen)
		Furnishings.hanging_lamp(body,Vector3(-5.4,2.85,0.0),0.35,4.0)
		Furnishings.hanging_lamp(body,Vector3(5.4,2.85,0.0),0.35,4.0)


static func _dress_palace_dining(body: StaticBody3D, civic: bool) -> void:
	if civic:
		for z in [-5.2,-1.8,1.8,5.2]:
			Furnishings.table(body,Vector3(0.0,0.0,z),0.0,3.1,1.2,"benches",Color(0.30,0.20,0.13))
		Furnishings.hanging_lamp(body,Vector3(0.0,2.85,0.0),0.6,5.0)
	else:
		Furnishings.table(body,Vector3(0.0,0.0,-1.2),0.0,2.7,1.25,"stools",Color(0.31,0.20,0.12))
		Furnishings.armchair(body,Vector3(0.0,0.0,1.0),PI,Color(0.60,0.14,0.08))
		for x in [-2.4,2.4]:
			var tray := _box(Vector3(0.48,0.16,0.42),Vector3(x,0.45,-1.1),Color(0.71,0.47,0.26),false)
			tray.name = "RejectedBaoTrialTray"
			body.add_child(tray)


static func _dress_apartments(body: StaticBody3D, civic: bool) -> void:
	# Static partitions and three gallery doors are authored in the hall
	# shell. Only these furnishings change when the palace becomes civic.
	if not civic:
		_build_canopy_bed(body,Vector3(-6.2,0.0,-2.0))
		Furnishings.table(body,Vector3(0.0,0.0,-1.0),0.0,1.8,1.1,"stools",Color(0.29,0.18,0.11))
		Furnishings.shelf(body,Vector3(0.0,0.0,-4.9),0.0,2.2,3,"crocks")
		var wardrobe := _box(Vector3(1.15,1.9,0.62),Vector3(6.2,0.95,-4.8),Color(0.31,0.19,0.11),true)
		wardrobe.name="ImperialRobeCabinet"
		body.add_child(wardrobe)
	else:
		Furnishings.table(body,Vector3(-6.2,0.0,-1.8),0.0,2.2,1.2,"benches",Color(0.29,0.18,0.11))
		Furnishings.shelf(body,Vector3(-6.2,0.0,-4.9),0.0,2.0,4,"boxes")
		Furnishings.table(body,Vector3(0.0,0.0,-1.8),0.0,2.4,1.2,"benches",Color(0.29,0.18,0.11))
		Furnishings.shelf(body,Vector3(0.0,0.0,-4.9),0.0,2.2,4,"books")
		for i in 4:
			Furnishings.piece(body,Vector3(0.46,0.035,0.42),Color(0.36,0.24,0.14),Vector3(5.2+float(i%2)*1.1,0.48,-2.0+float(i/2)*1.0),0.0,true)
		var stand := _box(Vector3(0.52,0.42,0.52),Vector3(7.4,0.21,-4.7),Color(0.33,0.22,0.14),true)
		stand.name="RetiredCrownStand"
		body.add_child(stand)
		var crown := _box(Vector3(0.52,0.38,0.52),Vector3(7.4,0.64,-4.7),Color(0.74,0.57,0.19),false,ORGANIC_EPSILON)
		crown.name="RetiredCrown"
		body.add_child(crown)


static func _dress_former_chef_room(body: StaticBody3D, civic: bool) -> void:
	_build_canopy_bed(body,Vector3(-0.5,0.0,-0.6))
	Furnishings.shelf(body,Vector3(1.0,0.0,1.4),0.0,1.0,2,"crocks" if not civic else "books")
	if civic:
		var herbs := _box(Vector3(0.48,0.36,0.42),Vector3(-1.4,0.2,1.5),Color(0.28,0.40,0.20),false)
		herbs.name = "LiangZhenWindowHerbs"
		body.add_child(herbs)


static func _dress_viewing_pavilion(body: StaticBody3D, civic: bool) -> void:
	Furnishings.bench(body,Vector3(0.0,0.0,-2.2),0.0,2.5 if civic else 1.7)
	Furnishings.table(body,Vector3(0.0,0.0,1.8),0.0,1.1,0.8,"stools",Color(0.30,0.20,0.13))
	if civic:
		Furnishings.bench(body,Vector3(0.0,TownProps.FLOOR_HEIGHT,-2.2),0.0,2.5)


static func _build_canopy_bed(body: StaticBody3D, at: Vector3) -> void:
	var base := _box(Vector3(2.0,0.36,2.45),at+Vector3(0.0,0.28,0.0),Color(0.36,0.23,0.14),true)
	base.name = "CanopyBedBase"
	body.add_child(base)
	var mattress := _box(Vector3(1.78,0.18,2.18),at+Vector3(0.0,0.55,0.0),Color(0.69,0.57,0.43),false)
	body.add_child(mattress)
	for x in [-0.92,0.92]:
		for z in [-1.12,1.12]:
			var post := _box(Vector3(0.08,2.05,0.08),at+Vector3(x,1.05,z),BRIDGE_WOOD,false)
			body.add_child(post)
	for z in [-1.12,1.12]:
		var beam := _box(Vector3(1.95,0.09,0.09),at+Vector3(0.0,2.02,z),BRIDGE_WOOD,false)
		body.add_child(beam)


static func _build_plan_program_details(items: Dictionary) -> void:
	var roof_yard: Node3D = items.get("roof_yard")
	if is_instance_valid(roof_yard):
		_build_roof_yard(roof_yard)
	var carrier: Node3D = items.get("carrier_home")
	if is_instance_valid(carrier):
		_build_carrier_loading_frame(carrier)
	var shed: Node3D = items.get("field_shed")
	if is_instance_valid(shed):
		var structure := shed.get_node_or_null("PlanStructure") as StaticBody3D
		if structure != null:
			TradeFurnishings.grain_bin(structure,Vector3(-1.1,0.0,0.3),0.0,Color(0.74,0.63,0.37))
			TradeFurnishings.peel_and_rake(structure,Vector3(0.8,0.0,-0.2),0.0)
			TradeFurnishings.tool_rack(structure,Vector3(0.0,0.0,1.0),0.0,1.2)


static func _build_roof_yard(yard: Node3D) -> void:
	# Grey roof tile is stacked flat on timber bearers. Beside it, the practice
	# frame lets Wen Zhao check pitch and ridge joints before repairing a roof.
	var layout: Dictionary=PLAN.WORKYARDS.roof_yard
	var frame_z: float=layout.frame_center[1]
	for stack in 3:
		var x: float=layout.tile_center[0]-1.0+float(stack)
		for layer in 3:
			var tile := _box(Vector3(0.84,0.11,2.0),Vector3(x,0.18+float(layer)*0.13,layout.tile_center[1]),Color(0.42,0.43,0.42),true)
			tile.rotation.x = -0.06
			yard.add_child(tile)
	var timber := Color(0.25,0.17,0.11)
	for x in [-1.4,1.4]:
		var post := _beam_between(yard,Vector3(x,0.0,frame_z+0.8),Vector3(x,2.35,frame_z+0.8),0.18,timber,true,STRUCTURAL_EPSILON)
		post.name = "PracticeRoofFramePost"
	for x in [-1.4,0.0,1.4]:
		var eave := Vector3(x,1.45,frame_z+0.8)
		var ridge := Vector3(0.0,2.35,frame_z+0.8)
		var beam := _beam_between(yard,eave,ridge,0.14,timber,true,STRUCTURAL_EPSILON)
		beam.name = "PracticeRoofFrameRafter"
		if x != 0.0:
			var keep := _beam_between(yard,ridge,Vector3(x,1.45,frame_z-0.8),0.11,timber,false,STRUCTURAL_EPSILON)
			CollisionPolicy.mark_decorative(keep)
	var ridge_beam := _beam_between(yard,Vector3(-1.4,2.35,frame_z+0.8),Vector3(1.4,2.35,frame_z+0.8),0.16,timber,true,STRUCTURAL_EPSILON)
	ridge_beam.name = "PracticeRoofFrameRidge"
	var rack := StaticBody3D.new()
	rack.name = "RooferTimberRack"
	rack.collision_layer = 1
	rack.collision_mask = 0
	yard.add_child(rack)
	TradeFurnishings.timber_rack(rack,Vector3(layout.rack_center[0],0.0,layout.rack_center[1]),0.0,2.3)


static func _build_carrier_loading_frame(compound: Node3D) -> void:
	var frame := StaticBody3D.new()
	frame.name = "CarrierLoadingFrame"
	frame.collision_layer = 1
	frame.collision_mask = 0
	frame.position = Vector3(7.5,0.0,1.5)
	compound.add_child(frame)
	for x in [-1.35,1.35]:
		var post := _beam_between(frame,Vector3(x,0.0,0.0),Vector3(x,2.25,0.0),0.18,BRIDGE_WOOD,true,STRUCTURAL_EPSILON)
		post.name = "CarrierFramePost"
	_beam_between(frame,Vector3(-1.55,2.25,0.0),Vector3(1.55,2.25,0.0),0.18,BRIDGE_WOOD,true,STRUCTURAL_EPSILON)
	_beam_between(frame,Vector3(-1.55,2.1,-1.1),Vector3(1.55,2.1,-1.1),0.12,BRIDGE_WOOD,true,STRUCTURAL_EPSILON)
	Furnishings.sacks(frame,Vector3(-0.65,0.0,-0.55),2)
	TradeFurnishings.grain_bin(frame,Vector3(0.8,0.0,-0.5),0.0,Color(0.72,0.60,0.35))
	var crate := _box(Vector3(0.9,0.7,0.75),Vector3(0.0,0.38,1.2),Color(0.38,0.27,0.17),true)
	frame.add_child(crate)


static func _build_field(parent: Node3D, village_center: Vector2, surface_y: float, center: Vector2, width: float, depth: float, key: String, outline: Array = []) -> void:
	if key == "pits":
		_build_service_pits(parent,village_center,surface_y,center,width,depth)
		return
	if not (key.begins_with("plot") or key.begins_with("strip") or key.begins_with("terrace")):
		return
	var field_polygon := PackedVector2Array()
	for point in outline:
		field_polygon.append(Vector2(float(point[0]),float(point[1])))
	var row_spacing := 1.55 if key.begins_with("plot") else (1.30 if key.begins_with("terrace") else 1.15)
	var plant_spacing := 0.72 if key.begins_with("plot") else (0.50 if key.begins_with("terrace") else 0.58)
	var row_count := maxi(1,ceili(depth*0.78/row_spacing))
	var plant_count := maxi(1,ceili(width*0.78/plant_spacing))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key) ^ 0x4C494E59
	var species := "soy" if key.begins_with("terrace") or key == "strip3" else ("wheat" if key == "strip2" else "millet")
	var transforms: Array[Transform3D] = []
	var batch_origin := Vector3(village_center.x+center.x,surface_y+0.035,village_center.y+center.y)
	for row in row_count:
		var z := center.y-depth*0.39+(float(row)+0.5)*depth*0.78/float(row_count)
		for plant_index in plant_count:
			var x := center.x-width*0.39+(float(plant_index)+0.5)*width*0.78/float(plant_count)
			var point := Vector2(x,z)
			if field_polygon.size() >= 3 and not Geometry2D.is_point_in_polygon(point,field_polygon):
				continue
			point += Vector2(rng.randf_range(-0.10,0.10),rng.randf_range(-0.07,0.07))
			if field_polygon.size() >= 3 and not Geometry2D.is_point_in_polygon(point,field_polygon):
				continue
			var height := rng.randf_range(0.62,0.90) if species != "soy" else rng.randf_range(0.42,0.60)
			transforms.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1,height,1)),Vector3(point.x-center.x,0,point.y-center.y)))
	VEGETATION.batch(parent,"Crops_%s" % key,VEGETATION.crop_mesh(species),transforms,batch_origin)
	if key.begins_with("terrace"):
		var boundary := _box(Vector3(width*0.94,0.16,0.32),Vector3(village_center.x+center.x,surface_y+0.04,village_center.y+center.y+depth*0.5),Color(0.42,0.39,0.32),true)
		boundary.name = "BeanTerraceRetainingStone"
		parent.add_child(boundary)


static func _build_service_pits(parent: Node3D, village_center: Vector2, surface_y: float, center: Vector2, width: float, depth: float) -> void:
	# The plan puts two small service pits downwind on the fields island's east
	# rim. Keep the ground as island grass: only their stone lips, dark contents
	# and simple timber covers are built, rather than a broad patch of bare dirt.
	var rim_stone := Color(0.43,0.41,0.36)
	var contents := Color(0.25,0.22,0.17)
	var timber := Color(0.26,0.19,0.12)
	var pit_width := minf(1.65,width*0.34)
	var pit_depth := minf(2.1,depth*0.36)
	for index in 2:
		var local := Vector2(center.x-width*0.19+float(index)*width*0.38,center.y)
		var world := Vector3(village_center.x+local.x,surface_y,village_center.y+local.y)
		var bed := _box(Vector3(pit_width-0.3,0.08,pit_depth-0.3),world+Vector3(0,0.07,0),contents,false)
		bed.name = "ServicePitContents_%d" % (index+1)
		parent.add_child(bed)
		var wall_height := 0.38
		for side in [-1.0,1.0]:
			var long_lip := _box(Vector3(pit_width,wall_height,0.18),world+Vector3(0,wall_height*0.5,side*(pit_depth*0.5-0.09)),rim_stone,true)
			long_lip.name = "ServicePitStoneLip"
			parent.add_child(long_lip)
			var end_lip := _box(Vector3(0.18,wall_height,pit_depth-0.24),world+Vector3(side*(pit_width*0.5-0.09),wall_height*0.5,0),rim_stone,true)
			end_lip.name = "ServicePitStoneLip"
			parent.add_child(end_lip)
		# Two spaced slats give each pit a recognizable working cover without
		# turning its opening into a full-height obstruction.
		for slat in 2:
			var cover := _box(Vector3(pit_width*0.82,0.07,0.12),world+Vector3(0,wall_height+0.04,(float(slat)-0.5)*0.48),timber,true)
			cover.name = "ServicePitCoverSlat"
			parent.add_child(cover)


static func _build_bamboo(parent: Node3D, village_center: Vector2, surface_y: float, center: Vector2, width: float, depth: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x4C494E59
	var clusters := [Vector2(-0.34,-0.28),Vector2(-0.08,-0.34),Vector2(0.25,-0.29),Vector2(-0.36,0.02),Vector2(-0.08,0.02),Vector2(0.28,0.02),Vector2(-0.29,0.30),Vector2(0.02,0.32),Vector2(0.32,0.30)]
	for cluster_index in clusters.size():
		var cluster: Vector2 = clusters[cluster_index]
		var base := center+Vector2(cluster.x*width,cluster.y*depth)
		var origin := Vector3(village_center.x+base.x,surface_y,village_center.y+base.y)
		var stems: Array[Transform3D] = []
		var rings: Array[Transform3D] = []
		var leaves: Array[Transform3D] = []
		var body := StaticBody3D.new()
		body.name = "BambooCollision%d" % cluster_index
		body.position = origin
		body.collision_layer = 1
		body.collision_mask = 0
		parent.add_child(body)
		var dimensions: Array[Vector2] = []
		for stalk_index in rng.randi_range(5,12):
			var p := Vector2(rng.randf_range(-2.6,2.6),rng.randf_range(-2.1,2.1))
			var height := rng.randf_range(7.0,14.0)
			var radius := rng.randf_range(0.04,0.10)
			var lean := Vector2(rng.randf_range(-0.14,0.14),rng.randf_range(-0.14,0.14))
			var rotation := Basis.from_euler(Vector3(-lean.y*0.16,0,lean.x*0.16))
			stems.append(Transform3D(rotation.scaled_local(Vector3(radius,height,radius)),Vector3(p.x+lean.x*0.5,height*0.5,p.y+lean.y*0.5)))
			dimensions.append(Vector2(radius,height))
			for joint in [0.16,0.32,0.51,0.70,0.86]:
				rings.append(Transform3D(Basis.IDENTITY.scaled(Vector3(radius*1.12,0.055,radius*1.12)),Vector3(p.x+lean.x*joint,height*joint,p.y+lean.y*joint)))
			if stalk_index%2==0:
				for leaf_index in 3:
					var angle := rng.randf_range(0.0,TAU)
					var length := rng.randf_range(0.8,1.7)
					var at := Vector3(p.x+lean.x*0.88+cos(angle)*length*0.35,height*0.88+rng.randf_range(-0.15,0.5),p.y+lean.y*0.88+sin(angle)*length*0.35)
					leaves.append(Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.45,0.45),angle,0)).scaled_local(Vector3(0.035,0.025,length)),at))
		var visual := VEGETATION.batch(body,"BambooStems",VEGETATION.colored_mesh(Vector3(1,0.5,1),Color(0.31,0.47,0.20)),stems,Vector3.ZERO,300.0)
		visual.set_meta(StaticMerge.MERGED_PHYSICAL_META,stems.size())
		for i in stems.size():
			var collider := CollisionPolicy.add_cylinder(body,visual,dimensions[i].x,dimensions[i].y,stems[i].origin,true)
			collider.basis = stems[i].basis.orthonormalized()
		VEGETATION.batch(body,"BambooNodes",VEGETATION.colored_mesh(Vector3(1,0.5,1),Color(0.22,0.36,0.15)),rings,Vector3.ZERO,200.0)
		VEGETATION.batch(body,"BambooLeaves",VEGETATION.colored_mesh(Vector3(0.5,0.5,0.5),Color(0.28,0.46,0.19),3.0),leaves,Vector3.ZERO,200.0)


static func _cylinder(height: float, radius: float, position: Vector3, color: Color, collidable: bool) -> Node3D:
	var root := Node3D.new()
	root.position = position
	var visual := MeshInstance3D.new()
	visual.mesh = SuperEgg.build_mesh(Vector3(radius,height*0.5,radius),2.0,2.0,12,12)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	visual.material_override = material
	root.add_child(visual)
	if collidable:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		CollisionPolicy.add_cylinder(body,visual,radius,height,Vector3.ZERO,true)
		root.add_child(body)
	else:
		CollisionPolicy.mark_decorative(visual)
	return root

static func _build_garden_court(parent: Node3D, width: float, depth: float, key: String) -> void:
	if key == "moon_court":
		var pomegranate := _cylinder(2.5,0.14,Vector3(0,1.25,-depth*0.12),Color(0.32,0.21,0.13),true)
		parent.add_child(pomegranate)
		for tier in 3:
			var cloud := SuperEgg.build_part(Vector3(1.05-0.12*float(tier),0.34,0.82-0.08*float(tier)),Color(0.18,0.35,0.19),3.0,3.3)
			cloud.position = Vector3(0,1.55+float(tier)*0.52,-depth*0.12)
			parent.add_child(cloud)
			CollisionPolicy.mark_decorative(cloud)
		for index in 9:
			var angle := TAU*float(index)/9.0
			var fruit := SuperEgg.build_part(Vector3(0.10,0.12,0.10),Color(0.68,0.16,0.11),2.0,2.0)
			fruit.position = Vector3(cos(angle)*0.78,2.2+float(index%3)*0.35,-depth*0.12+sin(angle)*0.66)
			parent.add_child(fruit)
			CollisionPolicy.mark_decorative(fruit)
		var seat := _box(Vector3(2.4,0.16,0.46),Vector3(0,0.42,depth*0.27),Color(0.31,0.22,0.15),true)
		parent.add_child(seat)
		return
	if key == "rock_garden":
		var gravel := _box(Vector3(width*0.82,0.04,depth*0.82),Vector3(0,0.07,0),Color(0.47,0.45,0.40),false,STRUCTURAL_EPSILON,false)
		parent.add_child(gravel)
		for index in 5:
			var x := -width*0.28+float(index)*width*0.14
			var z := -depth*0.12+sin(float(index)*1.7)*depth*0.24
			var plinth := _box(Vector3(0.72,0.34,0.68),Vector3(x,0.22,z),Color(0.53,0.50,0.43),true)
			parent.add_child(plinth)
			var rock := _box(Vector3(0.58+float(index%2)*0.22,1.25+float(index%3)*0.22,0.55),Vector3(x,1.04,z),Color(0.34,0.33,0.30),true,3.2,true)
			rock.rotation.z = -0.14+float(index%3)*0.10
			parent.add_child(rock)
		return
	if key == "bamboo_court":
		for x in [-width*0.36,-width*0.12,width*0.12,width*0.36]:
			var screen_post := _cylinder(2.4,0.065,Vector3(x,1.2,-depth*0.18),Color(0.28,0.43,0.22),true)
			parent.add_child(screen_post)
			var screen_leaf := _box(Vector3(0.04,1.65,1.6),Vector3(x,1.35,-depth*0.18),Color(0.29,0.45,0.23),false,ORGANIC_EPSILON)
			parent.add_child(screen_leaf)
		var bench := _box(Vector3(2.6,0.18,0.48),Vector3(0,0.48,depth*0.28),Color(0.29,0.20,0.13),true)
		parent.add_child(bench)
		return
	INFRASTRUCTURE.garden(parent,width,depth,key)
	var layout: Dictionary=PLAN.GARDENS[key]
	_build_open_pavilion(parent,parent.get_meta("garden_pavilion"),PALACE if key=="pond_court" else ROOF,float(layout.pavilion_yaw),key=="pond_court")


static func _build_open_pavilion(parent: Node3D, at: Vector3, roof_color: Color = ROOF, yaw: float = 0.0, waterside: bool = false) -> void:
	var pavilion := Node3D.new()
	pavilion.name = "HexagonalOpenPavilion"
	pavilion.position = at
	pavilion.rotation.y=yaw
	parent.add_child(pavilion)
	var timber := Color(0.21,0.43,0.31)
	var tile := roof_color
	var radius := 2.25
	var post_radius := 1.68
	var eave_y := 3.15
	var ridge_y := 4.27
	var corners: Array[Vector3] = []
	for i in 6:
		var angle := TAU*float(i)/6.0-PI*0.5
		corners.append(Vector3(cos(angle)*radius,eave_y,sin(angle)*radius))
	var floor := CylinderMesh.new()
	floor.top_radius = 1.76
	floor.bottom_radius = 1.76
	floor.height = 0.45
	floor.radial_segments = 6
	var floor_node := MeshInstance3D.new()
	floor_node.name = "StoneHexagonalFloor"
	floor_node.mesh = floor
	floor_node.position.y = 0.225
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.54,0.52,0.47)
	floor_node.material_override = floor_material
	pavilion.add_child(floor_node)
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_collision := CollisionShape3D.new()
	floor_collision.shape=floor_node.mesh.create_convex_shape()
	floor_collision.position=floor_node.position
	floor_collision.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	floor_node.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	floor_body.add_child(floor_collision)
	pavilion.add_child(floor_body)
	if waterside:
		# The pavilion is deliberately set clear of the battered tower footing.
		# Its waterside floor bears on stone piers reaching the basin bed.
		for x in [-1.1,1.1]:
			for z in [-0.7,0.7]:
				ARCHITECTURE.block(floor_body,"PavilionWaterFoundation",Vector3(0.40,2.5,0.40),Vector3(x,-1.2,z),Color(0.48,0.48,0.43),true)
	else:
		var entrance_size := Vector3(1.5,0.14,sqrt(0.9*0.9+0.45*0.45))
		var entrance := ARCHITECTURE.block(floor_body,"GardenPavilionThresholdRamp",entrance_size,Vector3(1.95,0.225-0.07/cos(atan2(0.45,0.9)),0),Color(0.54,0.52,0.47),false,false)
		entrance.rotation=Vector3(-atan2(0.45,0.9),PI*0.5,0)
		CollisionPolicy.add_box(floor_body,entrance,entrance_size,entrance.position,entrance.basis,true)
	for i in 6:
		var angle := TAU*float(i)/6.0-PI*0.5
		var foot := Vector3(cos(angle)*post_radius,1.73,sin(angle)*post_radius)
		var post_body := StaticBody3D.new()
		post_body.name="PavilionColumn_%d" % i
		pavilion.add_child(post_body)
		ARCHITECTURE.block(post_body,"ColumnStoneShoe",Vector3(0.40,0.16,0.40),Vector3(foot.x,0.53,foot.z),Color(0.53,0.52,0.47),true)
		ARCHITECTURE.block(post_body,"PaintedTimberColumn",Vector3(0.28,2.56,0.28),foot,timber,true)
		ARCHITECTURE.block(post_body,"ColumnCapital",Vector3(0.42,0.16,0.42),Vector3(foot.x,2.97,foot.z),timber,true)
		_build_beam_between(pavilion,foot+Vector3(0,1.28,0),Vector3(0,3.13,0),Vector2(0.14,0.18),timber,true)
	# Swept roof bays share rings and a sealed soffit. The upturn belongs
	# to the roof section, rather than six detached decorative sticks.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 6:
		var a: Vector3=corners[i]
		var b: Vector3=corners[(i+1)%6]
		for band in 10:
			var t0 := float(band)/10.0
			var t1 := float(band+1)/10.0
			var y0 := eave_y+(ridge_y-eave_y)*(0.62*t0+0.38*t0*t0)+0.12*pow(1.0-t0,6)
			var y1 := eave_y+(ridge_y-eave_y)*(0.62*t1+0.38*t1*t1)+0.12*pow(1.0-t1,6)
			var p0 := Vector3(a.x*(1-t0),y0,a.z*(1-t0))
			var p1 := Vector3(a.x*(1-t1),y1,a.z*(1-t1))
			var q0 := Vector3(b.x*(1-t0),y0,b.z*(1-t0))
			var q1 := Vector3(b.x*(1-t1),y1,b.z*(1-t1))
			ARCHITECTURE._roof_quad(st,p0,p1,q1,q0,tile)
			ARCHITECTURE._roof_quad(st,q0-Vector3.UP*0.14,q1-Vector3.UP*0.14,p1-Vector3.UP*0.14,p0-Vector3.UP*0.14,tile,Vector3.DOWN)
		ARCHITECTURE._roof_quad(st,a+Vector3.UP*0.12,b+Vector3.UP*0.12,b-Vector3.UP*0.02,a-Vector3.UP*0.02,tile,Vector3(a.x+b.x,0,a.z+b.z))
	st.generate_normals()
	var roof := MeshInstance3D.new()
	roof.name = "HexagonalTiledRoof"
	roof.mesh = st.commit()
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = tile
	roof_material.roughness = 1.0
	roof_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	roof.material_override = roof_material
	pavilion.add_child(roof)
	var roof_body := StaticBody3D.new()
	var roof_collision := CollisionShape3D.new()
	roof_collision.shape=roof.mesh.create_trimesh_shape()
	roof_collision.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	roof_body.add_child(roof_collision)
	pavilion.add_child(roof_body)
	roof.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	for i in 6:
		var a: Vector3 = corners[i]
		var b: Vector3 = corners[(i+1)%6]
		_build_beam_between(pavilion,a,b,Vector2(0.16,0.20),timber,false)
		if i!=1:
			var foot_a := Vector3(a.x,0.45,a.z)*Vector3(post_radius/radius,1,post_radius/radius)
			var foot_b := Vector3(b.x,0.45,b.z)*Vector3(post_radius/radius,1,post_radius/radius)
			var garden_rail := ARCHITECTURE.balustrade(pavilion,[foot_a,foot_b],[],0.70)
			for member in garden_rail.find_children("*","MeshInstance3D",true,false):
				var paint := (member as MeshInstance3D).material_override as StandardMaterial3D
				if paint!=null: paint.albedo_color=Color(0.54,0.14,0.10)
		_build_beam_between(pavilion,a+Vector3.UP*0.05,b+Vector3.UP*0.05,Vector2(0.12,0.16),tile,false)
	var finial := SuperEgg.build_part(Vector3(0.12,0.24,0.12),tile,3.0,3.0)
	finial.name="PavilionRoofFinial"
	finial.position=Vector3(0,ridge_y+0.17,0)
	pavilion.add_child(finial)
	CollisionPolicy.mark_decorative(finial)


static func _build_well(parent: Node3D) -> void:
	var stone := Color(0.46,0.44,0.40)
	for i in 12:
		var angle := TAU*float(i)/12.0
		var block := _box(Vector3(0.56,0.62,0.34),Vector3(cos(angle)*0.82,0.31,sin(angle)*0.82),stone,true)
		block.rotation.y = -angle
		parent.add_child(block)
	var water := _box(Vector3(1.28,0.06,1.28),Vector3(0,-0.17,0),Color(0.08,0.24,0.30),false,STRUCTURAL_EPSILON,false)
	water.name = "SpringWater"
	CollisionPolicy.mark_hazard(water.get_child(0))
	parent.add_child(water)
	for side in [-1.0,1.0]:
		var post := _box(Vector3(0.16,1.9,0.16),Vector3(side*0.86,1.18,0),Color(0.28,0.18,0.11),true)
		parent.add_child(post)
	var crossbeam := _box(Vector3(2.1,0.16,0.16),Vector3(0,2.1,0),Color(0.28,0.18,0.11),true)
	parent.add_child(crossbeam)
	var axle := _cylinder(0.28,0.12,Vector3(0,1.82,0),Color(0.36,0.25,0.15),true)
	axle.rotation.z = PI*0.5
	parent.add_child(axle)
	var rope := _local_beam(parent,Vector3(0,1.72,0),Vector3(0,0.52,0),0.035,Color(0.49,0.36,0.22))
	CollisionPolicy.mark_decorative(rope)
	var bucket := _box(Vector3(0.38,0.42,0.38),Vector3(0,0.42,0),Color(0.39,0.27,0.17),true)
	parent.add_child(bucket)


static func _build_sealing_rock(parent: Node3D, width: float, depth: float) -> void:
	var rock := _box(Vector3(width*0.72,3.4,depth*0.62),Vector3(0,1.7,0),ROCK,true,ORGANIC_EPSILON,true)
	parent.add_child(rock)
	var seal := _box(Vector3(width*0.82,0.22,depth*0.70),Vector3(0,2.25,0),Color(0.80,0.61,0.17),false)
	parent.add_child(seal)


static func _build_raised_piers(parent: Node3D,width: float,depth: float,height: float) -> void:
	for x in [-width*0.42,width*0.42]:
		for z in [-depth*0.42,depth*0.42]:
			var pier := _box(Vector3(0.7,height,0.7),Vector3(x,-height*0.5,z),Color(0.56,0.51,0.43),true)
			parent.add_child(pier)


static func _build_tapered_mound(parent: Node3D,width: float,depth: float,height: float) -> void:
	var bottom_x := width+2.4  # finished top contains the complete hall and apron
	var bottom_z := depth+2.4
	var top_x := width+6.0  # battered footing is broader than the finished top
	var top_z := depth+6.0
	var lower := [Vector2(-bottom_x*0.5,-bottom_z*0.5),Vector2(bottom_x*0.5,-bottom_z*0.5),Vector2(bottom_x*0.5,bottom_z*0.5),Vector2(-bottom_x*0.5,bottom_z*0.5)]
	var upper := [Vector2(-top_x*0.5,-top_z*0.5),Vector2(top_x*0.5,-top_z*0.5),Vector2(top_x*0.5,top_z*0.5),Vector2(-top_x*0.5,top_z*0.5)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stone_color := Color(0.57,0.52,0.44)
	for i in 4:
		var next := (i+1)%4
		var b0 := Vector3(upper[i].x,-height,upper[i].y)
		var b1 := Vector3(upper[next].x,-height,upper[next].y)
		var t0 := Vector3(lower[i].x,0.0,lower[i].y)
		var t1 := Vector3(lower[next].x,0.0,lower[next].y)
		# One weathered rock face, wholly inside the surveyed envelope. Corner
		# and cap samples remain exact; the same relief supplies collision.
		var inward := -Vector3((b0.x+b1.x)*0.5,0,(b0.z+b1.z)*0.5).normalized()
		for row in 14:
			for column in 16:
				var cell: Array[Vector3]=[]
				for uv in [Vector2(column,row),Vector2(column+1,row),Vector2(column+1,row+1),Vector2(column,row+1)]:
					var u: float=uv.x/16.0
					var v: float=uv.y/14.0
					var depth_noise := (0.40+0.27*sin(u*19.0+float(i)*1.7+v*4.0)*sin(v*24.0+u*3.0))*sin(PI*u)*sin(PI*v)
					cell.append(b0.lerp(b1,u).lerp(t0.lerp(t1,u),v)+inward*depth_noise)
				for index in [0,1,2,0,2,3]:
					var vertex := cell[index]
					var variation := 0.045*sin(vertex.y*1.3+vertex.x*0.7+vertex.z*0.9)
					st.set_color(Color(0.45+variation,0.43+variation,0.37+variation))
					st.add_vertex(vertex)
	for vertex in [Vector3(lower[0].x,0.0,lower[0].y),Vector3(lower[1].x,0.0,lower[1].y),Vector3(lower[2].x,0.0,lower[2].y),Vector3(lower[0].x,0.0,lower[0].y),Vector3(lower[2].x,0.0,lower[2].y),Vector3(lower[3].x,0.0,lower[3].y)]:
		st.set_color(stone_color)
		st.add_vertex(vertex)
	st.generate_normals()
	var mesh := st.commit()
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = stone_color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_color=Color.WHITE
	mat.vertex_color_use_as_albedo=true
	mat.vertex_color_is_srgb=true
	mat.roughness=0.95
	visual.material_override=mat
	visual.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	parent.add_child(visual)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_trimesh_shape()
	collision.set_meta(CollisionPolicy.POLICY_META,CollisionPolicy.PARKOUR)
	body.add_child(collision)
	parent.add_child(body)
	# An embedded foot, weathering cap and battered corner piers explain the
	# podium section. They meet the same surveyed top and bottom polygons.
	for i in 4:
		var next := (i+1)%4
		var foot_a := Vector3(upper[i].x,-height+0.18,upper[i].y)
		var foot_b := Vector3(upper[next].x,-height+0.18,upper[next].y)
		var cap_a := Vector3(lower[i].x,-0.12,lower[i].y)
		var cap_b := Vector3(lower[next].x,-0.12,lower[next].y)
		var foot := ARCHITECTURE.block(body,"PodiumFootCourse",Vector3(foot_a.distance_to(foot_b)+0.25,0.42,0.52),(foot_a+foot_b)*0.5,stone_color.darkened(0.12),true)
		foot.rotation.y=atan2(-(foot_b-foot_a).z,(foot_b-foot_a).x)
		# Match collider orientation after rotating the visible course.
		body.get_child(body.get_child_count()-1).basis=foot.basis
		var cap := ARCHITECTURE.block(body,"PodiumWeatheringCap",Vector3(cap_a.distance_to(cap_b)+0.26,0.30,0.54),(cap_a+cap_b)*0.5,ARCHITECTURE.MARBLE,true)
		cap.rotation.y=atan2(-(cap_b-cap_a).z,(cap_b-cap_a).x)
		body.get_child(body.get_child_count()-1).basis=cap.basis
		var corner := ARCHITECTURE.block(body,"BatteredCornerPier",Vector3(0.52,foot_a.distance_to(cap_a)+0.22,0.52),(foot_a+cap_a)*0.5,stone_color.lightened(0.10),true)
		corner.basis=Basis(Quaternion(Vector3.UP,(cap_a-foot_a).normalized()))
		body.get_child(body.get_child_count()-1).basis=corner.basis


static func _surface_color(kind: String, imperial: bool) -> Color:
	match kind:
		"imperial": return Color(0.48,0.49,0.46)
		"flag", "slab": return Color(0.67,0.64,0.58) if imperial or kind=="imperial" else FLAG
		"brick": return SHIHU_BRICK
		"pebble": return Color(0.39,0.38,0.34)
		"bund", "earth", "threshing", "garden": return EARTH if kind!="garden" else Color(0.35,0.34,0.29)
		_: return FLAG


static func _door_vector(side: String) -> Vector2:
	match side:
		"+x": return Vector2.RIGHT
		"-x": return Vector2.LEFT
		"-z": return Vector2.UP
		_: return Vector2.DOWN


static func _door_yaw(side: String) -> float:
	# TownProps building doors face local -Z.
	match side:
		"+x": return -PI*0.5
		"-x": return PI*0.5
		"+z": return PI
		_: return 0.0


static func _island_center(key: String, centers: Dictionary) -> Vector2:
	if key == "rim":
		return Vector2(PLAN.RIM_LANDING[0],PLAN.RIM_LANDING[1])
	return centers.get(key,Vector2.ZERO)


static func _box(
	size: Vector3, position: Vector3, color: Color, collidable: bool,
		epsilon: float = STRUCTURAL_EPSILON, use_superegg: bool = false
) -> Node3D:
	var root := Node3D.new()
	root.position = position
	var visual := MeshInstance3D.new()
	if use_superegg:
		visual.mesh = SuperEgg.build_mesh(size*0.5,epsilon,epsilon,10,12)
	else:
		var mesh := BoxMesh.new()
		mesh.size = size
		visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	visual.material_override = mat
	root.add_child(visual)
	if collidable:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		CollisionPolicy.add_box(body,visual,size,Vector3.ZERO,Basis.IDENTITY,true)
		root.add_child(body)
	else:
		CollisionPolicy.mark_decorative(visual)
	return root


static func _flat_box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	visual.material_override = material
	return visual


static func _add_box(
	parent: Node3D, size: Vector3, position: Vector3, color: Color, collidable: bool,
	epsilon: float = STRUCTURAL_EPSILON, use_superegg: bool = false
) -> Node3D:
	var box := _box(size,position,color,collidable,epsilon,use_superegg)
	parent.add_child(box)
	return box


static func _build_landscape_pines(root: Node3D, village_center: Vector2, surface_y: float) -> void:
	# Like the model, silhouettes occupy selected rim bays. Reject the entire
	# conservative crown radius against plots, routes and bridgehead aprons.
	for island in PLAN.ISLANDS:
		var outline: Array=island.outline
		var center := Vector2(island.c[0],island.c[1])
		var planted: Array[Vector2]=[]
		var step := maxi(1,outline.size()/18)
		for index in range(0,outline.size()-1,step):
			if planted.size()>=6: break
			var rim := Vector2(outline[index][0],outline[index][1])
			var at := rim.move_toward(center,5.5)
			var clear := true
			for item in PLAN.ITEMS:
				if item.island!=island.key: continue
				var c := Vector2(item.centre[0],item.centre[1])
				if absf(at.x-c.x)<float(item.rect[2])*0.5+2.2 and absf(at.y-c.y)<float(item.rect[3])*0.5+2.2: clear=false
			for path in PLAN.PATHS:
				if path.island!=island.key: continue
				for i in path.pts.size()-1:
					var a := Vector2(path.pts[i][0],path.pts[i][1])
					var b := Vector2(path.pts[i+1][0],path.pts[i+1][1])
					if Geometry2D.get_closest_point_to_segment(at,a,b).distance_to(at)<float(path.width)*0.5+2.2: clear=false
			for apron in PLAN.APRONS:
				if apron.island!=island.key: continue
				for p in apron.outline:
					if at.distance_to(Vector2(p[0],p[1]))<5.0: clear=false
			for other in planted:
				if at.distance_to(other)<6.0: clear=false
			if not clear: continue
			var seed_value := int(abs(hash(String(island.key))))%100000+index*71
			var pine := NatureProps.build_chinese_pine(3.2+float(index%5)*0.26,seed_value)
			pine.position=Vector3(village_center.x+at.x,surface_y,village_center.y+at.y)
			pine.name="LandscapeChinesePine_%s_%d" % [island.key,index]
			pine.set_meta("pine_island",island.key)
			pine.set_meta("pine_plan_origin",village_center)
			root.add_child(pine)
			StaticMerge.merge(pine)
			planted.append(at)


## Resolve seeded rim candidates against the physical built envelope before
## baking. The crown boxes include every canopy lobe, not just the trunk.
static func settle_landscape_pines(root: Node3D) -> void:
	await root.get_tree().physics_frame
	var moved := 0
	var omitted := 0
	for tree in root.get_children():
		if not tree.has_meta("pine_island"): continue
		var origin: Vector3=tree.position
		var village_center: Vector2=tree.get_meta("pine_plan_origin")
		var island: String=tree.get_meta("pine_island")
		var outline := PackedVector2Array()
		for record in PLAN.ISLANDS:
			if record.key==island:
				for p in record.outline: outline.append(Vector2(p[0],p[1]))
		var chosen := false
		for trial in 257:
			var offset := Vector3.ZERO
			if trial>0:
				var radius := float(1+(trial-1)/16)*0.5
				var angle := float((trial-1)%16)*TAU/16.0
				offset=Vector3(cos(angle),0,sin(angle))*radius
			var at := Vector2(origin.x+offset.x,origin.z+offset.z)-village_center
			if not _pine_site_clear(at,island,outline): continue
			var clear := true
			for crown in tree.get_meta("pine_crown_boxes"):
				var shape := BoxShape3D.new()
				shape.size=crown.size
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape=shape
				query.transform=Transform3D(tree.global_basis,tree.to_global(crown.position)+offset)
				query.collision_mask=1
				query.exclude=[tree.get_rid()]
				if not root.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
					clear=false
					break
			if not clear: continue
			tree.position=origin+offset
			if trial>0: moved+=1
			chosen=true
			await root.get_tree().physics_frame
			break
		if not chosen:
			tree.free()
			omitted+=1
	print("Pine envelope placement: ",moved," adjusted, ",omitted," unsuitable bays omitted")


static func _pine_site_clear(at: Vector2, island: String, outline: PackedVector2Array) -> bool:
	for offset in [Vector2.ZERO,Vector2(2.5,0),Vector2(-2.5,0),Vector2(0,2.5),Vector2(0,-2.5)]:
		if not Geometry2D.is_point_in_polygon(at+offset,outline): return false
	for item in PLAN.ITEMS:
		if item.island!=island: continue
		if absf(at.x-item.centre[0])<float(item.rect[2])*0.5+2.5 and absf(at.y-item.centre[1])<float(item.rect[3])*0.5+2.5: return false
	for path in PLAN.PATHS:
		if path.island!=island: continue
		for i in path.pts.size()-1:
			var a := Vector2(path.pts[i][0],path.pts[i][1])
			var b := Vector2(path.pts[i+1][0],path.pts[i+1][1])
			if Geometry2D.get_closest_point_to_segment(at,a,b).distance_to(at)<float(path.width)*0.5+2.5: return false
	return true


static func _build_household_workyard(parent: Node3D, width: float, depth: float, key: String) -> void:
	var body := StaticBody3D.new()
	body.name="HouseholdWorkyard_"+key
	parent.add_child(body)
	var at := Vector3(-width*0.5+1.5,0,depth*0.5-3.3)
	parent.set_meta("workyard_anchor",at+Vector3(1.6,0,0))
	var timber := Color(0.29,0.20,0.13)
	match key:
		"lantern_home":
			Furnishings.table(body,at,PI*0.5,1.8,0.75,"none",timber)
			for z in [-1.15,1.15]:
				ARCHITECTURE.block(body,"DryingRackPost",Vector3(0.12,2.2,0.12),at+Vector3(-0.65,1.1,z),timber,true)
			ARCHITECTURE.block(body,"DryingRackBeam",Vector3(0.14,0.14,2.5),at+Vector3(-0.65,2.15,0),timber,true)
			for i in 4:
				var z := -0.80+float(i)*0.53
				ARCHITECTURE.block(body,"DryingPaperSheet",Vector3(0.025,0.66,0.40),at+Vector3(-0.65,1.76,z),Color(0.80,0.73,0.57),false)
				var hoop := OpeningTrim.piped_frame(OpeningTrim.window_loop(0.19,0.25,2.5),0.025,timber,true)
				hoop.position=at+Vector3(0.10,1.05,z)
				hoop.rotation.y=PI*0.5
				body.add_child(hoop)
		"tile_home":
			for i in 3:
				for layer in 5-i:
					ARCHITECTURE.block(body,"GradedRoofTile",Vector3(0.70,0.12,0.46),at+Vector3(0,0.08+float(layer)*0.12,-0.62+float(i)*0.62),ROOF.lightened(float(i)*0.035),true)
		"roofer_home":
			TradeFurnishings.timber_rack(body,at,PI*0.5,2.2)
			TradeFurnishings.tool_rack(body,at+Vector3(-1.26,0,0),-PI*0.5,1.6)
		"carrier_home":
			ARCHITECTURE.block(body,"LoadingDunnage",Vector3(1.8,0.18,2.2),at+Vector3(0,0.09,0),timber,true)
			Furnishings.sacks(body,at+Vector3(-0.45,0.18,-0.45),3)
		"farm_home":
			Furnishings.sacks(body,at,3)
			Furnishings.bench(body,at+Vector3(-0.45,0,-1.15),PI*0.5,1.4)
		"westend_home":
			Furnishings.bench(body,at,PI*0.5,1.5)
		"bao_house":
			var span := width*0.5-2.6
			var center := Vector3(-width*0.5+0.4+span*0.5,0,depth*0.5-3.5)
			parent.set_meta("workyard_anchor",center+Vector3(0,0,-0.9))
			Furnishings.table(body,center,0.0,span,0.80,"none",timber)
			for x in [-1.0,1.0]:
				for z in [-1.05,1.05]:
					ARCHITECTURE.block(body,"BaoCanopyPost",Vector3(0.16,2.65,0.16),center+Vector3(x*(span*0.5-0.12),1.325,z),timber,true)
			var canopy := StaticBody3D.new()
			canopy.position=center
			body.add_child(canopy)
			ARCHITECTURE._frustum(canopy,span*0.5+0.18,1.23,maxf(0.001,span*0.5-0.8),0.001,2.68,0.65,ROOF,"BaoServingCanopy")
			for i in 3:
				var tray := center+Vector3((float(i)-1)*span*0.29,0.85,0)
				for tier in 2:
					var ring := OpeningTrim.piped_frame(OpeningTrim.window_loop(0.26,0.26,2.5),0.045,Color(0.60,0.44,0.25),true)
					ring.rotation.x=PI*0.5
					ring.position=tray+Vector3.UP*float(tier)*0.12
					body.add_child(ring)
				for j in 3:
					var bun := SuperEgg.build_part(Vector3(0.08,0.065,0.075),Color(0.86,0.82,0.69),3.0,3.0,6,12)
					bun.name="SteamedBao"
					bun.position=tray+Vector3((float(j)-1)*0.14,0.19,0)
					body.add_child(bun)
					CollisionPolicy.mark_decorative(bun)
				for stave in 8:
					var angle := float(stave)*TAU/8.0
					ARCHITECTURE.block(body,"SteamerBambooStave",Vector3(0.025,0.15,0.025),tray+Vector3(cos(angle)*0.26,0.06,sin(angle)*0.26),Color(0.60,0.44,0.25),false)
