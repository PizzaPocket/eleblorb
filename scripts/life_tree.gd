extends StaticBody3D

## Persistent planting bed in the magical starting clearing. The seed grows
## by mornings, not by time spent standing nearby: planted -> next morning
## sprout -> following morning mature and able to yield one slime per day.
const SOIL_COLOR := Color(0.53,0.37,0.21)
const LEAF_COLOR := Color(0.24,0.72,0.34)
const FLOWER_COLORS := [Color(0.95,0.42,0.55),Color(0.95,0.78,0.25),Color(0.58,0.45,0.92)]
## Half of the starting clearing's 25-unit flat radius.
const FAIRY_RING_RADIUS := 12.5
const FAIRY_RING_CLUSTERS := 15
const SOIL_SURFACE_LIFT := 0.025
const PETAL_SURFACE_LIFT := 0.018

var _growth_root: Node3D
var _harvest_area: Area3D
var _shown_stage := -2
var _terrain: Node

func _ready() -> void:
	collision_layer = 1
	_terrain = get_node("../Terrain")
	position.y = float(_terrain.get_mesh_height(position.x,position.z))
	_build_bed_and_flowers()
	_refresh_growth()

func _process(_delta: float) -> void:
	_refresh_growth()

func receive_thrown_item(item_name: String) -> bool:
	if item_name not in ["Seed of Life","Bean of Life"] or WorldState.seed_of_life_planted_day >= 0:
		return false
	WorldState.seed_of_life_planted_day = WorldState.calendar_day
	Hud.show_message("The Seed of Life takes root in the magical clearing.")
	_refresh_growth(true)
	return true

func _stage() -> int:
	if WorldState.seed_of_life_planted_day < 0: return -1
	return clampi(WorldState.calendar_day-WorldState.seed_of_life_planted_day,0,2)

func _refresh_growth(force: bool = false) -> void:
	var stage := _stage()
	if not force and stage == _shown_stage: return
	_shown_stage = stage
	if _growth_root != null: _growth_root.queue_free()
	_growth_root = Node3D.new()
	_growth_root.name = "TreeOfLifeGrowth"
	add_child(_growth_root)
	if stage == 0:
		_add_part(Vector3(0.08,0.18,0.08),Vector3(0,0.18,0),LEAF_COLOR)
	elif stage == 1:
		_add_part(Vector3(0.13,0.55,0.13),Vector3(0,0.55,0),NatureProps.TRUNK_COLOR)
		_add_part(Vector3(0.55,0.32,0.55),Vector3(0,1.05,0),LEAF_COLOR)
	elif stage >= 2:
		_add_part(Vector3(0.48,2.4,0.48),Vector3(0,2.4,0),NatureProps.TRUNK_COLOR)
		for offset in [Vector3(0,4.8,0),Vector3(1.1,4.2,0.3),Vector3(-1.0,4.15,-0.25)]:
			_add_part(Vector3(1.45,0.9,1.35),offset,LEAF_COLOR)
		if _harvest_area == null:
			_harvest_area = Interactable.attach(self,"Gather Blorb Slime",3.0,_harvest)

func _harvest() -> void:
	if _stage() < 2: return
	if WorldState.life_tree_last_harvest_day == WorldState.calendar_day:
		Hud.show_message("The Tree of Life needs until another morning to make more slime.")
		return
	WorldState.life_tree_last_harvest_day = WorldState.calendar_day
	Inventory.add("Blorb Slime",ShopCatalog.BLORB_SLIME_COLOR)
	Hud.show_message("Gathered rare Blorb Slime.")

func _build_bed_and_flowers() -> void:
	var soil := MeshInstance3D.new()
	soil.mesh = _build_soil_mound_mesh()
	soil.position.y = SOIL_SURFACE_LIFT
	add_child(soil)
	var mound_collision := CollisionShape3D.new()
	var mound_shape := CylinderShape3D.new()
	mound_shape.radius = 1.45
	mound_shape.height = 0.12
	mound_collision.shape = mound_shape
	mound_collision.position.y = 0.04
	add_child(mound_collision)
	_build_fairy_ring_petals()


func _build_soil_mound_mesh() -> ArrayMesh:
	# A shallow radial dome emerging from the ground, built as an inexpensive
	# top shell. Unlike the former rectangular superellipse, it has no slab
	# walls and becomes flush at its irregular elliptical perimeter.
	const SEGMENTS := 28
	const RINGS := 4
	var ring_radii := [0.0,0.38,0.72,1.0]
	var ring_heights := [0.22,0.175,0.085,0.0]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in range(RINGS-1):
		for segment in SEGMENTS:
			var next_segment := (segment+1)%SEGMENTS
			var a := _soil_mound_vertex(float(ring_radii[ring]),float(ring_heights[ring]),segment,SEGMENTS)
			var b := _soil_mound_vertex(float(ring_radii[ring]),float(ring_heights[ring]),next_segment,SEGMENTS)
			var c := _soil_mound_vertex(float(ring_radii[ring+1]),float(ring_heights[ring+1]),segment,SEGMENTS)
			var d := _soil_mound_vertex(float(ring_radii[ring+1]),float(ring_heights[ring+1]),next_segment,SEGMENTS)
			for vertex in [a,b,c,b,d,c]:
				surface.add_vertex(vertex)
	surface.generate_normals()
	var material := StandardMaterial3D.new()
	material.albedo_color = SOIL_COLOR
	material.roughness = 0.94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.set_material(material)
	return surface.commit()


func _soil_mound_vertex(radius: float,height: float,index: int,segments: int) -> Vector3:
	var angle := TAU*float(index)/float(segments)
	var edge_variation := 1.0+sin(angle*3.0+0.7)*0.035+sin(angle*7.0)*0.018
	return Vector3(cos(angle)*1.65*radius*edge_variation,height,sin(angle)*1.25*radius*edge_variation)


func _build_fairy_ring_petals() -> void:
	# Each decoration is one small, stemless petal form. All petals share one
	# mesh and draw call, while their clustered placement makes a broken ring
	# halfway between the clearing centre and its outer edge.
	var petal_mesh := SphereMesh.new()
	petal_mesh.radius = 0.5
	petal_mesh.height = 1.0
	petal_mesh.radial_segments = 8
	petal_mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.82
	petal_mesh.material = material
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260913
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var clearing_center_local: Vector2 = Vector2(-position.x,-position.z)
	for cluster_index in FAIRY_RING_CLUSTERS:
		var cluster_angle: float = TAU*float(cluster_index)/float(FAIRY_RING_CLUSTERS)+rng.randf_range(-0.105,0.105)
		var cluster_center: Vector2 = clearing_center_local+Vector2(cos(cluster_angle),sin(cluster_angle))*(FAIRY_RING_RADIUS+rng.randf_range(-0.8,0.8))
		var flower_count: int = rng.randi_range(4,8)
		for flower_index in flower_count:
			var scatter_angle: float = rng.randf_range(0.0,TAU)
			var flower_center: Vector2 = cluster_center+Vector2(cos(scatter_angle),sin(scatter_angle))*rng.randf_range(0.08,1.25)
			var petal_color: Color = FLOWER_COLORS[(cluster_index+flower_index)%FLOWER_COLORS.size()]
			var petal_angle: float = rng.randf_range(0.0,TAU)
			var basis: Basis = Basis(Vector3.UP,-petal_angle)
			basis = basis.scaled(Vector3(0.09,0.014,0.06)*rng.randf_range(0.84,1.16))
			var world_x: float = position.x+flower_center.x
			var world_z: float = position.z+flower_center.y
			var ground_y: float = float(_terrain.get_mesh_height(world_x,world_z))
			var local_y: float = ground_y-position.y+PETAL_SURFACE_LIFT
			transforms.append(Transform3D(basis,Vector3(flower_center.x,local_y,flower_center.y)))
			colors.append(petal_color)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = petal_mesh
	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index,transforms[index])
		multimesh.set_instance_color(index,colors[index])
	var petals := MultiMeshInstance3D.new()
	petals.name = "FairyRingPetals"
	petals.multimesh = multimesh
	add_child(petals)

func _add_part(size: Vector3,pos: Vector3,color: Color) -> void:
	var part := SuperEgg.build_part(size,color,2.5,2.8)
	part.position = pos
	_growth_root.add_child(part)
