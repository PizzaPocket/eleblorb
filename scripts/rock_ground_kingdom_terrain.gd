extends StaticBody3D

## Terrain-first badlands kingdom. One heightfield owns rendering, collision,
## normals, and gameplay height queries.
const HALF_SIZE := 620.0
const RESOLUTION := 141
const TOWN_CENTER := Vector2(-155.0, 92.0)
const TOWN_RADIUS := 68.0
const FOSSIL_CENTER := Vector2(185.0, -145.0)
const FOSSIL_BASIN_RADIUS := 72.0
const SAND := Color(0.58, 0.39, 0.22)
const TERRACE_TOP := Color(0.67, 0.49, 0.28)
const CANYON_FLOOR := Color(0.43, 0.27, 0.17)
const ROCK_COUNT := 72
const SPIRE_COUNT := 22
const SCRUB_COUNT := 95
const ELEMENT_DIVIDE_X := 25.0
## Per direct correction, the western "Rock" half is meant to read at
## wilderness_scatter.gd's own canyon-biome density -- the original flat
## pass (54 slabs/14 hoodoos/5 arches sampled individually across the whole
## ~542,000 sq-unit half) worked out to roughly 20-30x sparser than that
## biome's own ~90 landmarks packed into a single 72-radius zone. Rather
## than scale those counts up to an absurd total spread thin over the same
## huge area, this repeats several canyon-density CLUSTERS across the half
## instead -- closer to how real badlands actually read (clustered rock
## formations, not a uniform haze of individual boulders) -- see
## _scatter_rock_half_landmarks().
const ROCK_SIDE_CLUSTER_COUNT := 9
const ROCK_SIDE_CLUSTER_RADIUS := 39.0
const ROCK_SIDE_CLUSTER_SLABS := 23
const ROCK_SIDE_CLUSTER_HOODOOS := 5
const ROCK_SIDE_CLUSTER_ARCH_CHANCE := 0.6
## NatureProps.build_rock_ramp() -- the same climbable/jumpable tilted slab
## the real canyon biome already uses for its own ramp moments -- per direct
## request ("make the rocks into fun parkour/dirtbike-ramp features").
const ROCK_SIDE_CLUSTER_RAMPS := 4
const ROCK_SIDE_CLUSTER_FILLER_ROCKS := 22
var _broad_noise := FastNoiseLite.new()
var _detail_noise := FastNoiseLite.new()
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_broad_noise.seed = 20260917
	_broad_noise.frequency = 0.006
	_broad_noise.fractal_octaves = 4
	_detail_noise.seed = 20261917
	_detail_noise.frequency = 0.019
	_detail_noise.fractal_octaves = 3
	_rng.seed = 20260917
	_build_mesh_and_collision()
	_scatter_landscape()

func _raw_height(x: float, z: float) -> float:
	var point := Vector2(x, z)
	var broad: float = (_broad_noise.get_noise_2d(x, z) + 0.32) * 31.0
	var shelf: float = floor(broad / 7.0) * 7.0
	var remainder: float = fposmod(broad, 7.0)
	var height: float = lerpf(shelf, shelf + 7.0, smoothstep(0.7, 2.4, remainder))
	height += _detail_noise.get_noise_2d(x, z) * 1.35
	# Connected winding washes with broad floors and steep cliff shoulders.
	var channel_a: float = absf(z - (sin(x * 0.010) * 54.0 - 92.0))
	var channel_b: float = absf(x - (cos(z * 0.012 + 0.8) * 70.0 + 62.0))
	var channel_c: float = absf((z + x * 0.34) - sin(x * 0.017) * 32.0 - 185.0)
	var canyon: float = maxf(1.0-smoothstep(18.0,42.0,channel_a),maxf(1.0-smoothstep(16.0,38.0,channel_b),1.0-smoothstep(15.0,34.0,channel_c)))
	height -= canyon * 24.0
	# Terrain-native half-pipe canyons on the Rock side. The inner wall rises
	# roughly 38m over one terrain cell: close to vertical, while remaining
	# beneath the bike controller's 80-degree supported-slope ceiling.
	height = _halfpipe_height(height,point,Vector2(-330.0,155.0),0.08,150.0,38.0)
	height = _halfpipe_height(height,point,Vector2(-270.0,-285.0),0.58,118.0,34.0)
	# Deliberate level shelves for arrival, town, and dormant titan fossil.
	height = lerpf(height,0.0,1.0-smoothstep(30.0,52.0,point.length()))
	height = lerpf(height,8.0,1.0-smoothstep(TOWN_RADIUS,TOWN_RADIUS+26.0,point.distance_to(TOWN_CENTER)))
	height = lerpf(height,-12.0,1.0-smoothstep(FOSSIL_BASIN_RADIUS,FOSSIL_BASIN_RADIUS+28.0,point.distance_to(FOSSIL_CENTER)))
	var edge: float = smoothstep(HALF_SIZE*0.72,HALF_SIZE*0.97,point.length())
	height += edge * maxf(_broad_noise.get_noise_2d(x+800.0,z-500.0)+0.48,0.0)*86.0
	return height


func _halfpipe_height(
	current_height: float,point: Vector2,center: Vector2,angle: float,
	half_length: float,wall_height: float
) -> float:
	var local: Vector2 = (point-center).rotated(-angle)
	var across: float = absf(local.x)
	var along: float = absf(local.y)
	var longitudinal_mask: float = 1.0-smoothstep(half_length,half_length+28.0,along)
	var outer_mask: float = 1.0-smoothstep(27.0,39.0,across)
	var influence: float = longitudinal_mask*outer_mask
	if influence<=0.0:
		return current_height
	var wall_fraction: float = smoothstep(14.0,23.0,across)
	var target_height: float = -18.0+wall_height*wall_fraction
	return lerpf(current_height,target_height,influence)

func get_mesh_height(x: float, z: float) -> float:
	var spacing: float = HALF_SIZE*2.0/float(RESOLUTION-1)
	var fx: float = clampf((x+HALF_SIZE)/spacing,0.0,float(RESOLUTION-1)-0.001)
	var fz: float = clampf((z+HALF_SIZE)/spacing,0.0,float(RESOLUTION-1)-0.001)
	var ix: int = clampi(int(fx),0,RESOLUTION-2)
	var iz: int = clampi(int(fz),0,RESOLUTION-2)
	var tx: float = fx-float(ix)
	var tz: float = fz-float(iz)
	var a := _grid_vertex(ix,iz,spacing)
	var b := _grid_vertex(ix+1,iz,spacing)
	var c := _grid_vertex(ix,iz+1,spacing)
	var d := _grid_vertex(ix+1,iz+1,spacing)
	return _plane_height(a,c,b,x,z) if tx+tz<=1.0 else _plane_height(b,c,d,x,z)

func get_mesh_normal(x: float, z: float) -> Vector3:
	const D := 0.7
	return Vector3(get_mesh_height(x-D,z)-get_mesh_height(x+D,z),D*2.0,get_mesh_height(x,z-D)-get_mesh_height(x,z+D)).normalized()

func is_lake_area(_world_pos: Vector2) -> bool: return false
func get_lake_water_level() -> float: return 0.0
func is_safe_zone(pos: Vector2) -> bool: return pos.distance_to(TOWN_CENTER)<TOWN_RADIUS+18.0 or pos.length()<36.0
func get_village_center() -> Vector2: return TOWN_CENTER
func get_village_radius() -> float: return TOWN_RADIUS
func get_fossil_center() -> Vector2: return FOSSIL_CENTER

func _grid_vertex(ix: int, iz: int, spacing: float) -> Vector3:
	var x: float = -HALF_SIZE+float(ix)*spacing
	var z: float = -HALF_SIZE+float(iz)*spacing
	return Vector3(x,_raw_height(x,z),z)

func _plane_height(a: Vector3,b: Vector3,c: Vector3,x: float,z: float) -> float:
	var denominator: float = (b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
	var wa: float = ((b.z-c.z)*(x-c.x)+(c.x-b.x)*(z-c.z))/denominator
	var wb: float = ((c.z-a.z)*(x-c.x)+(a.x-c.x)*(z-c.z))/denominator
	return wa*a.y+wb*b.y+(1.0-wa-wb)*c.y

func _height_color(height: float) -> Color:
	if height < -7.0: return CANYON_FLOOR.lerp(SAND,clampf((height+16.0)/9.0,0.0,1.0))
	return SAND.lerp(TERRACE_TOP,clampf((height+5.0)/55.0,0.0,1.0))

func _build_mesh_and_collision() -> void:
	var spacing: float = HALF_SIZE*2.0/float(RESOLUTION-1)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in RESOLUTION:
		for ix in RESOLUTION:
			var vertex := _grid_vertex(ix,iz,spacing)
			tool.set_color(_height_color(vertex.y))
			tool.set_normal(get_mesh_normal(vertex.x,vertex.z))
			tool.add_vertex(vertex)
	for iz in RESOLUTION-1:
		for ix in RESOLUTION-1:
			var i0: int = iz*RESOLUTION+ix
			for index in [i0,i0+RESOLUTION,i0+1,i0+1,i0+RESOLUTION,i0+RESOLUTION+1]: tool.add_index(index)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.94
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tool.set_material(material)
	var terrain_mesh := MeshInstance3D.new()
	terrain_mesh.mesh = tool.commit()
	add_child(terrain_mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(terrain_mesh.mesh.get_faces())
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	add_child(collider)

func _scatter_landscape() -> void:
	# Dinosaur's eastern half remains a broad dirt/fossil landscape. The
	# western half deliberately speaks the Rock element in the same layered,
	# climbable sandstone language as the Crossroads canyon biome.
	_scatter_rock_half_landmarks()
	for i in ROCK_COUNT:
		var point := _pick_clear_point(32.0, false if i < ROCK_COUNT/2 else true)
		var rock := NatureProps.build_rock(_rng.randf_range(0.65,3.0),true)
		rock.position = Vector3(point.x,get_mesh_height(point.x,point.y),point.y)
		rock.rotation.y = _rng.randf_range(0.0,TAU)
		rock.scale.y = _rng.randf_range(0.55,1.45)
		add_child(rock)
	for i in SPIRE_COUNT:
		var point := _pick_clear_point(74.0, true)
		var spire := NatureProps.build_rock_spire(_rng.randf_range(1.7,3.8),_rng.randi_range(3,6),_rng)
		spire.position = Vector3(point.x,get_mesh_height(point.x,point.y),point.y)
		add_child(spire)
	for i in SCRUB_COUNT:
		var point := _pick_clear_point(25.0, false)
		var scrub := NatureProps.build_bush(Color(0.30,0.37,0.16).lerp(Color(0.48,0.43,0.19),_rng.randf()))
		scrub.position = Vector3(point.x,get_mesh_height(point.x,point.y),point.y)
		scrub.scale = Vector3.ONE*_rng.randf_range(0.45,0.9)
		add_child(scrub)

## Repeats a canyon-density cluster of landmarks around each of
## ROCK_SIDE_CLUSTER_COUNT centers scattered across the western half --
## see this file's own comment on ROCK_SIDE_CLUSTER_COUNT above for why
## clustering replaced the old flat per-half counts. Hoodoos/spires already
## double as parkour staircases (see NatureProps.build_slab_tower()'s own
## doc comment), and each cluster's ramps are the real canyon biome's own
## climbable/jumpable NatureProps.build_rock_ramp() shape.
func _scatter_rock_half_landmarks() -> void:
	for cluster_i in ROCK_SIDE_CLUSTER_COUNT:
		var center := _pick_clear_point(70.0,true)
		for i in ROCK_SIDE_CLUSTER_SLABS:
			var point := _pick_point_near(center,ROCK_SIDE_CLUSTER_RADIUS)
			var size := Vector3(_rng.randf_range(6.0,14.0),_rng.randf_range(0.55,1.15),_rng.randf_range(6.0,14.0))
			var slab := NatureProps.build_rock_slab(size,NatureProps.CANYON_BAND_COLORS[i%NatureProps.CANYON_BAND_COLORS.size()])
			slab.position = Vector3(point.x,get_mesh_height(point.x,point.y)-size.y*0.32,point.y)
			slab.rotation.y = _rng.randf_range(0.0,TAU)
			add_child(slab)
		for i in ROCK_SIDE_CLUSTER_HOODOOS:
			var point := _pick_point_near(center,ROCK_SIDE_CLUSTER_RADIUS)
			var tower: Dictionary = NatureProps.build_slab_tower(_rng.randf_range(3.0,6.2),_rng.randi_range(5,10),_rng)
			var body := tower["body"] as StaticBody3D
			body.position = Vector3(point.x,get_mesh_height(point.x,point.y),point.y)
			add_child(body)
		if _rng.randf()<ROCK_SIDE_CLUSTER_ARCH_CHANCE:
			var point := _pick_point_near(center,ROCK_SIDE_CLUSTER_RADIUS)
			var arch := NatureProps.build_rock_arch(_rng.randf_range(9.0,16.0),_rng)
			arch.position = Vector3(point.x,get_mesh_height(point.x,point.y),point.y)
			arch.rotation.y = _rng.randf_range(0.0,TAU)
			add_child(arch)
		for i in ROCK_SIDE_CLUSTER_RAMPS:
			_place_rock_ramp(_pick_point_near(center,ROCK_SIDE_CLUSTER_RADIUS))
		for i in ROCK_SIDE_CLUSTER_FILLER_ROCKS:
			var point := _pick_point_near(center,ROCK_SIDE_CLUSTER_RADIUS)
			var rock := NatureProps.build_rock(_rng.randf_range(0.6,2.2),true)
			rock.position = Vector3(point.x,get_mesh_height(point.x,point.y),point.y)
			rock.rotation.y = _rng.randf_range(0.0,TAU)
			add_child(rock)


## Same tilted, climbable slab wilderness_scatter.gd's own canyon biome
## uses (_place_rock_ramp()) -- a rider can climb it on the dirt blorb
## suit's wheel and launch off the top.
func _place_rock_ramp(pos: Vector2) -> void:
	var rise := _rng.randf_range(2.5,5.0)
	var run := rise*_rng.randf_range(1.6,2.2)
	var width := _rng.randf_range(2.4,3.4)
	var ramp := NatureProps.build_rock_ramp(width,run,rise)
	ramp.position = Vector3(pos.x,get_mesh_height(pos.x,pos.y),pos.y)
	ramp.rotation.y = _rng.randf_range(0.0,TAU)
	add_child(ramp)


func _pick_clear_point(arrival_clearance: float,rock_half: Variant = null) -> Vector2:
	for attempt in 30:
		var point := Vector2(_rng.randf_range(-HALF_SIZE*0.82,HALF_SIZE*0.82),_rng.randf_range(-HALF_SIZE*0.82,HALF_SIZE*0.82))
		if rock_half != null:
			if bool(rock_half) and point.x > ELEMENT_DIVIDE_X: continue
			if not bool(rock_half) and point.x <= ELEMENT_DIVIDE_X: continue
		if point.length()<arrival_clearance or point.distance_to(TOWN_CENTER)<TOWN_RADIUS+22.0 or point.distance_to(FOSSIL_CENTER)<FOSSIL_BASIN_RADIUS+12.0: continue
		return point
	return Vector2(HALF_SIZE*0.5,HALF_SIZE*0.5)


## Samples within `radius` of `center` (a cluster's own center, itself
## already picked via _pick_clear_point so it's on the correct side of
## ELEMENT_DIVIDE_X) instead of across the whole half -- this is what makes
## a cluster's own landmarks actually sit near each other rather than
## scattering back out across the full map again. Still re-checks the
## arrival/town/fossil clearances since a cluster center near one of those
## boundaries could otherwise place a member past it.
func _pick_point_near(center: Vector2,radius: float) -> Vector2:
	for attempt in 20:
		var angle := _rng.randf_range(0.0,TAU)
		var r := radius*sqrt(_rng.randf())
		var point := center+Vector2(cos(angle),sin(angle))*r
		if point.length()<40.0 or point.distance_to(TOWN_CENTER)<TOWN_RADIUS+22.0 or point.distance_to(FOSSIL_CENTER)<FOSSIL_BASIN_RADIUS+12.0: continue
		return point
	return center
