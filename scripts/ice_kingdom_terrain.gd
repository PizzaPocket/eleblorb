extends StaticBody3D

## Terrain-first Ice Kingdom. One triangulated heightfield supplies its
## visible snow, collision, normals and gameplay height queries.

const TOKOIN_SCENE: PackedScene = preload("res://scenes/tokoin.tscn")
const HALF_SIZE := 900.0
const RESOLUTION := 121
const VILLAGE_CENTER := Vector2(-135.0, -75.0)
const VILLAGE_RADIUS := 62.0
const LAKE_CENTER := Vector2(145.0, 95.0)
const LAKE_RADIUS := 72.0
const LAKE_EDGE_VARIATION := 10.0
const LAKE_DEPTH := 17.0
const ICE_LEVEL := -3.35
const WATER_LEVEL := -3.80
const ICE_THICKNESS := 0.38
## The heightfield is sampled every 15 units. Extend both flat lake layers
## beneath the bank by more than half a cell so interpolation can never expose
## a dry crescent between the organic shore and the ice/water meshes.
const LAKE_SURFACE_OVERLAP := 11.0
const FISHING_HOLE_CENTER := LAKE_CENTER + Vector2(-18.0, 5.0)
const FISHING_HOLE_RADIUS := 3.2
const SNOW_RADIUS := 360.0
const PINE_COUNT := 105
const SPIRE_COUNT := 34

var _noise := FastNoiseLite.new()
var _mountain_noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_noise.seed = 20260910
	_noise.frequency = 0.011
	_noise.fractal_octaves = 4
	_mountain_noise.seed = 20261910
	_mountain_noise.frequency = 0.006
	_mountain_noise.fractal_octaves = 4
	_rng.seed = 20260910
	_build_mesh_and_collision()
	_build_lake_surfaces()
	_scatter_snow_forest()
	_scatter_ice_spires()
	_scatter_frost_bushes()
	_scatter_frozen_lake_floor_tokoins.call_deferred()
	WorldState.ice_kingdom_visited = true


## A loose trail of coins across the real lake bottom. It begins beneath the
## fishing hole so the route is discoverable, then bends into deeper water.
## Tokoin._ready() snaps every pickup to get_mesh_height(), not ICE_LEVEL.
func _scatter_frozen_lake_floor_tokoins() -> void:
	var scene_root: Node = get_parent()
	var offsets: Array[Vector2] = [
		Vector2(-18.0, 5.0), Vector2(-13.0, 2.0), Vector2(-8.0, -3.0),
		Vector2(-2.0, -8.0), Vector2(6.0, -10.0), Vector2(14.0, -7.0),
		Vector2(20.0, -1.0), Vector2(18.0, 8.0), Vector2(10.0, 14.0),
		Vector2(0.0, 17.0), Vector2(-10.0, 14.0),
	]
	for offset in offsets:
		var point: Vector2 = LAKE_CENTER + offset
		var tokoin := TOKOIN_SCENE.instantiate() as Area3D
		tokoin.position = Vector3(point.x, 0.0, point.y)
		scene_root.add_child(tokoin)


func _terrain_height(x: float, z: float) -> float:
	var pos := Vector2(x, z)
	var hills: float = _noise.get_noise_2d(x, z) * 7.0
	hills *= smoothstep(0.0, 38.0, pos.length())
	hills *= smoothstep(VILLAGE_RADIUS, VILLAGE_RADIUS + 32.0, pos.distance_to(VILLAGE_CENTER))
	var lake: float = _lake_coverage(pos)
	var lake_bank: float = 1.0 - smoothstep(LAKE_RADIUS, LAKE_RADIUS + 24.0, pos.distance_to(LAKE_CENTER))
	var edge: float = smoothstep(650.0, 850.0, pos.length())
	var mountains: float = maxf(_mountain_noise.get_noise_2d(x, z) + 0.28, 0.0) * 82.0 * edge
	var banked_ground: float = lerpf(hills + mountains, ICE_LEVEL, lake_bank)
	return lerpf(banked_ground, ICE_LEVEL - LAKE_DEPTH * lake, lake)


func _lake_coverage(pos: Vector2) -> float:
	var edge_radius := _lake_edge_radius(pos - LAKE_CENTER)
	return 1.0 - smoothstep(edge_radius - 18.0, edge_radius, pos.distance_to(LAKE_CENTER))


func _lake_edge_radius(relative: Vector2) -> float:
	if relative.length_squared() < 0.001:
		return LAKE_RADIUS
	var angle := atan2(relative.y, relative.x)
	var organic := _noise.get_noise_2d(cos(angle) * 93.0 + 410.0, sin(angle) * 93.0 - 280.0)
	organic += sin(angle * 3.0 + 0.7) * 0.34 + sin(angle * 5.0 - 1.1) * 0.18
	return LAKE_RADIUS + organic * LAKE_EDGE_VARIATION


func get_mesh_height(x: float, z: float) -> float:
	var spacing: float = HALF_SIZE * 2.0 / float(RESOLUTION - 1)
	var fx: float = clampf((x + HALF_SIZE) / spacing, 0.0, float(RESOLUTION - 1) - 0.001)
	var fz: float = clampf((z + HALF_SIZE) / spacing, 0.0, float(RESOLUTION - 1) - 0.001)
	var ix: int = clampi(int(fx), 0, RESOLUTION - 2)
	var iz: int = clampi(int(fz), 0, RESOLUTION - 2)
	var tx: float = fx - float(ix)
	var tz: float = fz - float(iz)
	var a := _grid_vertex(ix, iz, spacing)
	var b := _grid_vertex(ix + 1, iz, spacing)
	var c := _grid_vertex(ix, iz + 1, spacing)
	var d := _grid_vertex(ix + 1, iz + 1, spacing)
	return _plane_height(a, c, b, x, z) if tx + tz <= 1.0 else _plane_height(b, c, d, x, z)


func _grid_vertex(ix: int, iz: int, spacing: float) -> Vector3:
	var x: float = -HALF_SIZE + float(ix) * spacing
	var z: float = -HALF_SIZE + float(iz) * spacing
	return Vector3(x, _terrain_height(x, z), z)


func _plane_height(a: Vector3, b: Vector3, c: Vector3, x: float, z: float) -> float:
	var denom: float = (b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
	var wa: float = ((b.z-c.z)*(x-c.x)+(c.x-b.x)*(z-c.z))/denom
	var wb: float = ((c.z-a.z)*(x-c.x)+(a.x-c.x)*(z-c.z))/denom
	return wa*a.y + wb*b.y + (1.0-wa-wb)*c.y


func get_mesh_normal(x: float, z: float) -> Vector3:
	const D := 0.5
	return Vector3(get_mesh_height(x-D,z)-get_mesh_height(x+D,z), D*2.0, get_mesh_height(x,z-D)-get_mesh_height(x,z+D)).normalized()


func is_lake_area(pos: Vector2) -> bool:
	return _lake_coverage(pos) > 0.08


func is_ice_surface(pos: Vector2) -> bool:
	return _lake_coverage(pos) > 0.08 and pos.distance_to(FISHING_HOLE_CENTER) > FISHING_HOLE_RADIUS


func get_lake_water_level() -> float:
	return WATER_LEVEL


func is_snow_zone(pos: Vector2) -> bool:
	return pos.length() < SNOW_RADIUS


func is_snow_footstep_surface(pos: Vector2) -> bool:
	return not is_lake_area(pos)


func get_snow_radius() -> float:
	return SNOW_RADIUS


func is_safe_zone(pos: Vector2) -> bool:
	return pos.distance_to(VILLAGE_CENTER) < VILLAGE_RADIUS + 18.0


func is_nme_hazard(pos: Vector2) -> bool:
	return is_lake_area(pos)


func get_village_center() -> Vector2:
	return VILLAGE_CENTER


func get_village_radius() -> float:
	return VILLAGE_RADIUS


func get_fishing_hole_center() -> Vector2:
	return FISHING_HOLE_CENTER


func get_ice_level() -> float:
	return ICE_LEVEL


func _height_color(pos: Vector2) -> Color:
	if _lake_coverage(pos) > 0.12:
		return Color(0.48, 0.62, 0.72)
	return Color(0.94, 0.965, 1.0).lerp(Color(0.78, 0.87, 0.94), clampf(pos.length()/HALF_SIZE, 0.0, 1.0))


func _build_mesh_and_collision() -> void:
	var spacing: float = HALF_SIZE * 2.0 / float(RESOLUTION - 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in RESOLUTION:
		for ix in RESOLUTION:
			var v := _grid_vertex(ix, iz, spacing)
			st.set_color(_height_color(Vector2(v.x, v.z)))
			st.set_normal(get_mesh_normal(v.x, v.z))
			st.add_vertex(v)
	for iz in RESOLUTION - 1:
		for ix in RESOLUTION - 1:
			var i0: int = iz * RESOLUTION + ix
			var i1: int = i0 + 1
			var i2: int = i0 + RESOLUTION
			var i3: int = i2 + 1
			for index in [i0, i2, i1, i1, i2, i3]:
				st.add_index(index)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.88
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	var mesh := MeshInstance3D.new()
	mesh.mesh = st.commit()
	add_child(mesh)
	var faces := PackedVector3Array()
	for iz in RESOLUTION - 1:
		for ix in RESOLUTION - 1:
			var v00 := _grid_vertex(ix, iz, spacing)
			var v10 := _grid_vertex(ix + 1, iz, spacing)
			var v01 := _grid_vertex(ix, iz + 1, spacing)
			var v11 := _grid_vertex(ix + 1, iz + 1, spacing)
			for v in [v00, v01, v10, v10, v01, v11]:
				faces.append(v)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)


func _build_lake_surfaces() -> void:
	_build_surface_disc("FrozenLakeIce", ICE_LEVEL, true)
	_build_ice_edge_wall(LAKE_CENTER, LAKE_RADIUS, true)
	_build_ice_edge_wall(FISHING_HOLE_CENTER, FISHING_HOLE_RADIUS)
	_build_surface_disc("LakeWater", WATER_LEVEL, false)


func _build_ice_edge_wall(center: Vector2, radius: float, organic: bool = false) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	const SEGMENTS := 72
	for i in SEGMENTS:
		var a0: float = TAU*float(i)/float(SEGMENTS)
		var a1: float = TAU*float(i+1)/float(SEGMENTS)
		var radius0 := (_lake_edge_radius(Vector2(cos(a0), sin(a0))) + LAKE_SURFACE_OVERLAP) if organic else radius
		var radius1 := (_lake_edge_radius(Vector2(cos(a1), sin(a1))) + LAKE_SURFACE_OVERLAP) if organic else radius
		var top0 := Vector3(center.x+cos(a0)*radius0,ICE_LEVEL,center.y+sin(a0)*radius0)
		var top1 := Vector3(center.x+cos(a1)*radius1,ICE_LEVEL,center.y+sin(a1)*radius1)
		var low0 := top0-Vector3.UP*ICE_THICKNESS
		var low1 := top1-Vector3.UP*ICE_THICKNESS
		for vertex in [top0,low0,top1,top1,low0,low1]:
			st.add_vertex(vertex)
			faces.append(vertex)
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(0.56,0.78,0.9,0.9)
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness=0.12
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	var mesh:=MeshInstance3D.new()
	mesh.mesh=st.commit()
	add_child(mesh)
	var shape:=ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision=true
	var collider:=CollisionShape3D.new()
	collider.shape=shape
	add_child(collider)


func _build_surface_disc(label: String, y: float, solid: bool) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	const RINGS := 28
	const SEGMENTS := 72
	for ring in RINGS:
		var ring_fraction0 := float(ring) / float(RINGS)
		var ring_fraction1 := float(ring + 1) / float(RINGS)
		for i in SEGMENTS:
			var a0: float = TAU * float(i) / float(SEGMENTS)
			var a1: float = TAU * float(i + 1) / float(SEGMENTS)
			var edge0 := _lake_edge_radius(Vector2(cos(a0), sin(a0))) + LAKE_SURFACE_OVERLAP
			var edge1 := _lake_edge_radius(Vector2(cos(a1), sin(a1))) + LAKE_SURFACE_OVERLAP
			var quad: Array[Vector2] = [
				Vector2(cos(a0),sin(a0))*edge0*ring_fraction0,
				Vector2(cos(a1),sin(a1))*edge1*ring_fraction0,
				Vector2(cos(a0),sin(a0))*edge0*ring_fraction1,
				Vector2(cos(a1),sin(a1))*edge1*ring_fraction1,
			]
			var middle: Vector2 = (quad[0]+quad[1]+quad[2]+quad[3])*0.25
			if solid and middle.distance_to(FISHING_HOLE_CENTER-LAKE_CENTER) < FISHING_HOLE_RADIUS:
				continue
			# Counter-clockwise from above: the real front face and generated
			# normal both point upward. The former order was physically inverted.
			for index in [0,1,2,1,3,2]:
				var p: Vector2 = quad[index]
				var vertex := Vector3(LAKE_CENTER.x+p.x,y,LAKE_CENTER.y+p.y)
				st.set_normal(Vector3.UP)
				st.add_vertex(vertex)
				if solid:
					faces.append(vertex)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.68,0.87,0.96,0.84) if solid else Color(0.16,0.42,0.62,0.68)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.12
	mat.metallic = 0.12
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = st.commit()
	add_child(mesh)
	if solid:
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		shape.backface_collision = true
		var collider := CollisionShape3D.new()
		collider.shape = shape
		add_child(collider)


func _scatter_snow_forest() -> void:
	var clusters: Array[Vector2] = [Vector2(-260,90),Vector2(-40,210),Vector2(240,-170),Vector2(-330,-260),Vector2(80,-290)]
	for i in PINE_COUNT:
		var p: Vector2
		if i % 9 == 0:
			p = Vector2(_rng.randf_range(-430.0,430.0), _rng.randf_range(-430.0,430.0))
		else:
			var center: Vector2 = clusters[_rng.randi() % clusters.size()]
			var angle: float = _rng.randf_range(0.0,TAU)
			var distance: float = sqrt(_rng.randf()) * _rng.randf_range(25.0,105.0)
			p = center + Vector2(cos(angle),sin(angle)) * distance
		if is_safe_zone(p) or is_lake_area(p) or p.length() < 18.0:
			continue
		var tree := NatureProps.build_pine_tree(_rng.randf_range(5.5,11.0), Color(0.72,0.84,0.88).lerp(Color(0.9,0.95,0.98),_rng.randf()))
		tree.position = Vector3(p.x,get_mesh_height(p.x,p.y),p.y)
		tree.rotation.y = _rng.randf_range(0.0,TAU)
		add_child(tree)


func _scatter_ice_spires() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.58,0.8,0.94)
	mat.roughness = 0.12
	mat.metallic = 0.18
	for i in SPIRE_COUNT:
		var a: float = _rng.randf_range(0.0,TAU)
		var r: float = _rng.randf_range(390.0,620.0)
		var p := Vector2(cos(a),sin(a))*r
		var spire := NatureProps.build_rock_spire(_rng.randf_range(1.2,2.8),_rng.randi_range(3,6),_rng)
		spire.position = Vector3(p.x,get_mesh_height(p.x,p.y),p.y)
		_tint(spire,mat)
		add_child(spire)


func _tint(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).set_surface_override_material(0,mat)
	for child in node.get_children():
		_tint(child,mat)


func _scatter_frost_bushes() -> void:
	for i in 38:
		var p := Vector2(_rng.randf_range(-420.0,420.0),_rng.randf_range(-420.0,420.0))
		if is_safe_zone(p) or is_lake_area(p):
			continue
		var color := Color(0.58,0.76,0.78).lerp(Color(0.8,0.9,0.94),_rng.randf())
		var bush := NatureProps.build_bush(color)
		bush.position = Vector3(p.x,get_mesh_height(p.x,p.y),p.y)
		bush.rotation.y = _rng.randf_range(0.0,TAU)
		add_child(bush)
