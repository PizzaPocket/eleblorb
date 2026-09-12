extends StaticBody3D

const TOKOIN_SCENE: PackedScene = preload("res://scenes/tokoin.tscn")
const HALF_SIZE := 900.0
const RESOLUTION := 121
const CRATER_CENTER := Vector2(155.0, 85.0)
const CRATER_FLOOR_RADIUS := 72.0
const CRATER_RIM_RADIUS := 112.0
const CRATER_OUTER_RADIUS := 205.0
const CRATER_FLOOR_Y := -16.0
const CRATER_RIM_Y := 48.0
const VILLAGE_RADIUS := 58.0
const GATE_CENTER := Vector2(0.0, -3.0)
const GATE_CLEAR_RADIUS := 22.0
const GATE_BLEND_RADIUS := 38.0
const GATE_GROUND_Y := 0.0
const LAVA_POOLS: Array[Vector2] = [Vector2(-190,-145), Vector2(-315,175), Vector2(335,-210)]
const SECONDARY_VOLCANO_CENTERS: Array[Vector2] = [Vector2(50,-350),Vector2(410,180)]
const LAVA_RADIUS := 31.0
## Where each lava pool's own raised rim starts (_terrain_height() ramps the
## ground up to full rim height by here) and where it finishes blending back
## into the surrounding noisy terrain. Named and pulled out of _terrain_
## height() specifically so LAVA_MOUTH_RADIUS below can be defined relative
## to LAVA_RIM_START_RADIUS instead of an independently-guessed number --
## per direct correction, the visible lava sheet (LAVA_MOUTH_RADIUS) not
## reaching all the way to where the ground actually starts climbing left a
## gap that a coarse ~15-unit terrain grid renders inconsistently (visible
## at some angles, hidden at others) rather than as one uniform ring.
const LAVA_RIM_START_RADIUS := 58.0
const LAVA_RIM_END_RADIUS := 135.0
## Deliberately overlaps LAVA_RIM_START_RADIUS by a real margin (not just
## matching it exactly) so the mesh grid's own coarseness can't reopen the
## gap this was already once nudged wider to close (51 -> still gapped at
## the mouth's farthest-back points).
const LAVA_MOUTH_RADIUS := LAVA_RIM_START_RADIUS + 12.0
const LAVA_FLOOR_Y := -18.0
const VOLCANO_LAVA_SURFACE_Y := 27.0
const RIVER_LAVA_SURFACE_Y := -2.0
## Keep the river deep enough to swim through rather than reading as a thin
## decal laid over a shallow groove.  The visible lava deliberately extends
## well beneath the banks: the terrain mesh is sampled on a 15-unit grid, so a
## small overlap can expose wedges of the carved channel between samples.
const RIVER_FLOOR_Y := -19.0
const RIVER_HALF_WIDTH := 9.5
const RIVER_SHORE_SOFTNESS := 4.5
const RIVER_SURFACE_OVERLAP := 17.0
const RIVER_MEANDER_AMPLITUDE := 18.0
## A vent's bubble grows from this radius up to a per-cycle random peak
## (BUBBLE_PEAK_RANGE) over the same cooldown that paces its next spray, then
## pops (instantly hides) right as that cooldown elapses. Below
## BUBBLE_SPRAY_THRESHOLD, popping is all that happens -- a small bubble
## just fizzles, no spray -- at or above it, the pop and the spray land on
## the same frame.
const BUBBLE_START_RADIUS := 0.05
const BUBBLE_PEAK_RANGE := Vector2(0.35, 2.0)
const BUBBLE_SPRAY_THRESHOLD := 1.15
const RIVER_PATHS: Array = [
	[Vector2(-760,360),Vector2(-600,330),Vector2(-470,280),Vector2(-350,285),Vector2(-210,275),Vector2(-80,250),Vector2(70,235),Vector2(235,250),Vector2(355,105),Vector2(500,20),Vector2(710,-95)],
	[Vector2(-690,-430),Vector2(-560,-350),Vector2(-450,-265),Vector2(-355,-155),Vector2(-300,-45),Vector2(-230,70),Vector2(-150,180),Vector2(-80,250)],
	[Vector2(730,-470),Vector2(610,-385),Vector2(510,-335),Vector2(430,-305),Vector2(430,-165),Vector2(475,-70),Vector2(500,20)],
]
var _noise:=FastNoiseLite.new()
var _mountain_noise:=FastNoiseLite.new()
var _rng:=RandomNumberGenerator.new()
var _fire_vents:Array[Dictionary]=[]
var _river_centerlines:Array[PackedVector2Array]=[]
## Precomputed once in _build_river_centerlines() -- see that function's own
## comment. Parallel to _river_centerlines: _river_point_allowed[p][i]
## matches _river_centerlines[p][i], _river_segment_allowed[p][i] matches
## the segment from _river_centerlines[p][i] to [p][i+1].
var _river_point_allowed:Array[PackedByteArray]=[]
var _river_segment_allowed:Array[PackedByteArray]=[]
## Additional authored molten surfaces (for example the village fountain)
## register here so traversal, damage, ambience and immersion all consult the
## same lava query instead of each prop inventing a separate contact rule.
var _registered_lava_surfaces:Array[Dictionary]=[]
var _under_lava_environment:Environment
var _lava_camera:Camera3D

func _ready()->void:
	collision_layer=1;collision_mask=0
	_noise.seed=20260912;_noise.frequency=0.012;_noise.fractal_octaves=4
	_mountain_noise.seed=20261912;_mountain_noise.frequency=0.006;_mountain_noise.fractal_octaves=4
	_rng.seed=20260912
	_build_river_centerlines()
	_build_mesh_and_collision();_build_lava_pools();_build_lava_rivers();_build_fire_vents();_scatter_volcanic_rocks()
	_scatter_volcano_floor_tokoins.call_deferred()
	_prepare_under_lava_environment()
	set_process(true)


## Small treasure rings on the true rock floor of every filled volcano.
## Tokoin._ready() samples this terrain's mesh height after it enters the
## kingdom root, so these sit at the bottom rather than on the lava surface.
func _scatter_volcano_floor_tokoins() -> void:
	var scene_root: Node = get_parent()
	for volcano_index in LAVA_POOLS.size():
		var center: Vector2 = LAVA_POOLS[volcano_index]
		for coin_index in 5:
			var angle: float = TAU * float(coin_index) / 5.0 + float(volcano_index) * 0.47
			var radius: float = 7.0 + float((coin_index + volcano_index) % 2) * 4.5
			var point := center + Vector2(cos(angle), sin(angle)) * radius
			var tokoin := TOKOIN_SCENE.instantiate() as Area3D
			tokoin.position = Vector3(point.x, 0.0, point.y)
			scene_root.add_child(tokoin)

func _process(delta:float)->void:
	_update_camera_immersion()
	for vent in _fire_vents:
		var timer:float=float(vent["timer"])-delta
		vent["timer"]=timer
		var total:float=float(vent["total"])
		var bubble:=vent["bubble"] as MeshInstance3D
		var peak:float=float(vent["peak"])
		# Eased growth (smoothstep, not linear) reads as a bubble actually
		# swelling under pressure rather than inflating at a constant rate.
		var progress:=smoothstep(0.0,1.0,clampf(1.0-timer/total,0.0,1.0))
		var radius:=lerpf(BUBBLE_START_RADIUS,peak,progress)
		bubble.scale=Vector3.ONE*radius
		if timer<=0.0:
			bubble.scale=Vector3.ZERO
			if peak>=BUBBLE_SPRAY_THRESHOLD:
				var particles:=vent["particles"] as GPUParticles3D
				particles.restart()
				particles.emitting=true
			var new_total:=_rng.randf_range(2.4,8.5)
			vent["timer"]=new_total
			vent["total"]=new_total
			vent["peak"]=_rng.randf_range(BUBBLE_PEAK_RANGE.x,BUBBLE_PEAK_RANGE.y)

func _prepare_under_lava_environment()->void:
	_under_lava_environment=Environment.new()
	_under_lava_environment.background_mode=Environment.BG_COLOR
	_under_lava_environment.background_color=Color(0.20,0.018,0.004)
	_under_lava_environment.background_energy_multiplier=1.15
	_under_lava_environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	_under_lava_environment.ambient_light_color=Color(1.0,0.18,0.025)
	_under_lava_environment.ambient_light_energy=1.15
	_under_lava_environment.fog_enabled=true
	_under_lava_environment.fog_mode=Environment.FOG_MODE_EXPONENTIAL
	_under_lava_environment.fog_light_color=Color(0.72,0.075,0.008)
	_under_lava_environment.fog_light_energy=1.2
	_under_lava_environment.fog_density=0.018
	_under_lava_environment.fog_sky_affect=1.0
	_under_lava_environment.adjustment_enabled=true
	_under_lava_environment.adjustment_brightness=1.08
	_under_lava_environment.adjustment_saturation=1.12

func _update_camera_immersion()->void:
	var camera:=get_viewport().get_camera_3d()
	if camera==null:return
	var xz:=Vector2(camera.global_position.x,camera.global_position.z)
	var immersed:=is_lava_area(xz) and camera.global_position.y<get_lava_surface_height(xz)-0.06
	if immersed:
		if camera.environment!=_under_lava_environment:camera.environment=_under_lava_environment
		_lava_camera=camera
	elif camera.environment==_under_lava_environment:
		camera.environment=null
		_lava_camera=null

func _terrain_height(x:float,z:float)->float:
	var p:=Vector2(x,z)
	var base:float=_noise.get_noise_2d(x,z)*6.0
	base*=smoothstep(0.0,38.0,p.length())
	base+=maxf(_mountain_noise.get_noise_2d(x,z)+0.3,0.0)*78.0*smoothstep(650.0,850.0,p.length())
	for center in LAVA_POOLS:
		var small_d:float=p.distance_to(center)
		if small_d<LAVA_RADIUS:base=LAVA_FLOOR_Y
		elif small_d<LAVA_RIM_START_RADIUS:base=lerpf(LAVA_FLOOR_Y,38.0,smoothstep(LAVA_RADIUS,LAVA_RIM_START_RADIUS,small_d))
		elif small_d<LAVA_RIM_END_RADIUS:base+=lerpf(38.0,0.0,smoothstep(LAVA_RIM_START_RADIUS,LAVA_RIM_END_RADIUS,small_d))
	for center in SECONDARY_VOLCANO_CENTERS:
		base+=maxf(0.0,1.0-p.distance_to(center)/145.0)*42.0
	var river_amount:=_river_coverage(p)
	if river_amount>0.0:
		base=lerpf(base,RIVER_FLOOR_Y,river_amount)
	var d:float=p.distance_to(CRATER_CENTER)
	if d<CRATER_FLOOR_RADIUS:base=CRATER_FLOOR_Y
	elif d<CRATER_RIM_RADIUS:base=lerpf(CRATER_FLOOR_Y,CRATER_RIM_Y,smoothstep(CRATER_FLOOR_RADIUS,CRATER_RIM_RADIUS,d))
	elif d<CRATER_OUTER_RADIUS:base=lerpf(CRATER_RIM_Y,base,smoothstep(CRATER_RIM_RADIUS,CRATER_OUTER_RADIUS,d))
	var gate_distance:=p.distance_to(GATE_CENTER)
	if gate_distance<GATE_BLEND_RADIUS:
		base=lerpf(GATE_GROUND_Y,base,smoothstep(GATE_CLEAR_RADIUS,GATE_BLEND_RADIUS,gate_distance))
	return base

func _distance_to_segment(point:Vector2,a:Vector2,b:Vector2)->float:
	var segment:=b-a
	var length_squared:=segment.length_squared()
	if length_squared<=0.0001:return point.distance_to(a)
	var t:=clampf((point-a).dot(segment)/length_squared,0.0,1.0)
	return point.distance_to(a+segment*t)

func _build_river_centerlines()->void:
	_river_centerlines.clear()
	_river_segment_allowed.clear()
	_river_point_allowed.clear()
	for path_index in RIVER_PATHS.size():
		var controls:Array=RIVER_PATHS[path_index]
		var curve:=PackedVector2Array()
		for segment_index in controls.size()-1:
			var p0:Vector2=controls[maxi(segment_index-1,0)] as Vector2
			var p1:Vector2=controls[segment_index] as Vector2
			var p2:Vector2=controls[segment_index+1] as Vector2
			var p3:Vector2=controls[mini(segment_index+2,controls.size()-1)] as Vector2
			var steps:=maxi(5,ceili(p1.distance_to(p2)/14.0))
			for step in steps:
				var t:=float(step)/float(steps)
				var t2:=t*t;var t3:=t2*t
				var point:=0.5*((2.0*p1)+(-p0+p2)*t+(2.0*p0-5.0*p1+4.0*p2-p3)*t2+(-p0+3.0*p1-3.0*p2+p3)*t3)
				# Two offset frequencies introduce broad bends plus smaller natural
				# variation. sin(PI*t) returns the offset to zero at every authored
				# anchor, preserving tributary joins while removing ruler-straight runs.
				var segment_direction:Vector2=(p2-p1).normalized()
				var segment_normal:=Vector2(-segment_direction.y,segment_direction.x)
				var phase:=float(segment_index*3+path_index*5)*0.91
				var meander:float=(sin(TAU*t+phase)*0.68+sin(PI*3.0*t-phase*0.47)*0.32)*sin(PI*t)
				point+=segment_normal*meander*RIVER_MEANDER_AMPLITUDE
				curve.append(_push_river_out_of_highlands(point))
		curve.append(_push_river_out_of_highlands(controls.back() as Vector2))
		_river_centerlines.append(curve)
		# _river_allowed() only depends on fixed static centers, never on the
		# query point's own identity beyond distance -- per-segment/per-point
		# results are exactly the same every call, so compute them once here
		# instead of re-running every one of the ~7 distance checks inside
		# _river_allowed() on every terrain-height sample (hundreds of
		# thousands of calls during mesh/collision generation).
		var point_allowed:=PackedByteArray()
		for point in curve:
			point_allowed.append(1 if _river_allowed(point) else 0)
		_river_point_allowed.append(point_allowed)
		var segment_allowed:=PackedByteArray()
		for i in curve.size()-1:
			segment_allowed.append(1 if _river_allowed((curve[i]+curve[i+1])*0.5) else 0)
		_river_segment_allowed.append(segment_allowed)

func _push_river_out_of_highlands(point:Vector2)->Vector2:
	var result:=point
	var exclusions:Array=[{"center":CRATER_CENTER,"radius":CRATER_OUTER_RADIUS+24.0},{"center":GATE_CENTER,"radius":GATE_BLEND_RADIUS+18.0}]
	for center in LAVA_POOLS:exclusions.append({"center":center,"radius":142.0})
	for center in SECONDARY_VOLCANO_CENTERS:exclusions.append({"center":center,"radius":154.0})
	# Repeat because escaping one overlapping volcanic footprint can enter the
	# next. The resulting densely sampled line follows the lowland perimeter
	# rather than crossing the staggered cones and their raised skirts.
	for _pass in 3:
		for exclusion in exclusions:
			var center:Vector2=exclusion["center"] as Vector2;var radius:float=float(exclusion["radius"]);var offset:=result-center
			if offset.length()<radius:
				result=center+(offset.normalized() if offset.length()>0.01 else Vector2.RIGHT)*radius
	return result

func _river_allowed(p:Vector2)->bool:
	if p.distance_to(GATE_CENTER)<GATE_BLEND_RADIUS+12.0 or p.distance_to(CRATER_CENTER)<CRATER_OUTER_RADIUS+12.0:return false
	for center in LAVA_POOLS:
		if p.distance_to(center)<128.0:return false
	for center in SECONDARY_VOLCANO_CENTERS:
		if p.distance_to(center)<138.0:return false
	return true

func _river_coverage(p:Vector2)->float:
	if p.distance_to(GATE_CENTER)<GATE_BLEND_RADIUS or is_safe_zone(p):return 0.0
	var nearest:=INF
	for path_index in _river_centerlines.size():
		var path:=_river_centerlines[path_index]
		var allowed:=_river_segment_allowed[path_index]
		for i in path.size()-1:
			if allowed[i]==0:continue
			nearest=minf(nearest,_distance_to_segment(p,path[i],path[i+1]))
	return clampf(1.0-smoothstep(RIVER_HALF_WIDTH-RIVER_SHORE_SOFTNESS,RIVER_HALF_WIDTH,nearest),0.0,1.0)

func get_mesh_height(x:float,z:float)->float:
	var s:float=HALF_SIZE*2.0/float(RESOLUTION-1)
	var fx:float=clampf((x+HALF_SIZE)/s,0.0,float(RESOLUTION-1)-0.001);var fz:float=clampf((z+HALF_SIZE)/s,0.0,float(RESOLUTION-1)-0.001)
	var ix:int=clampi(int(fx),0,RESOLUTION-2);var iz:int=clampi(int(fz),0,RESOLUTION-2)
	var a:=_vertex(ix,iz,s);var b:=_vertex(ix+1,iz,s);var c:=_vertex(ix,iz+1,s);var d:=_vertex(ix+1,iz+1,s)
	return _plane(a,c,b,x,z) if fx-float(ix)+fz-float(iz)<=1.0 else _plane(b,c,d,x,z)

func _vertex(ix:int,iz:int,s:float)->Vector3:
	var x:float=-HALF_SIZE+float(ix)*s;var z:float=-HALF_SIZE+float(iz)*s
	return Vector3(x,_terrain_height(x,z),z)

func _plane(a:Vector3,b:Vector3,c:Vector3,x:float,z:float)->float:
	var den:float=(b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
	var wa:float=((b.z-c.z)*(x-c.x)+(c.x-b.x)*(z-c.z))/den;var wb:float=((c.z-a.z)*(x-c.x)+(a.x-c.x)*(z-c.z))/den
	return wa*a.y+wb*b.y+(1.0-wa-wb)*c.y

func get_mesh_normal(x:float,z:float)->Vector3:
	const D:=0.5
	return Vector3(get_mesh_height(x-D,z)-get_mesh_height(x+D,z),D*2.0,get_mesh_height(x,z-D)-get_mesh_height(x,z+D)).normalized()
func is_lake_area(_p:Vector2)->bool:return false
func get_lake_water_level()->float:return 0.0
func is_safe_zone(p:Vector2)->bool:return p.distance_to(CRATER_CENTER)<VILLAGE_RADIUS+15.0
func is_nme_hazard(p:Vector2)->bool:return is_lava_area(p)
func get_village_center()->Vector2:return CRATER_CENTER
func get_village_radius()->float:return VILLAGE_RADIUS
func is_lava_area(p:Vector2)->bool:
	for surface in _registered_lava_surfaces:
		if p.distance_to(surface["center"] as Vector2)<float(surface["radius"]):return true
	for center in LAVA_POOLS:
		if p.distance_to(center)<LAVA_MOUTH_RADIUS:return true
	if _river_coverage(p)>0.01:return true
	# The rendered river extends beneath its banks to hide terrain-grid gaps.
	# Treat that wider ribbon as liquid only where it is genuinely exposed
	# above the sampled ground; otherwise the player can visibly enter lava at
	# the edge yet remain walking until reaching the old narrow centre volume.
	var surface_radius:float=RIVER_HALF_WIDTH+RIVER_SURFACE_OVERLAP
	var nearest:float=INF
	for path_index in _river_centerlines.size():
		var path:=_river_centerlines[path_index]
		var allowed:=_river_segment_allowed[path_index]
		for i in path.size()-1:
			if allowed[i]==0:continue
			nearest=minf(nearest,_distance_to_segment(p,path[i],path[i+1]))
	if nearest>surface_radius:return false
	return get_mesh_height(p.x,p.y)<RIVER_LAVA_SURFACE_Y+0.15
func get_lava_surface_height(p:Vector2)->float:
	for surface in _registered_lava_surfaces:
		if p.distance_to(surface["center"] as Vector2)<float(surface["radius"]):return float(surface["height"])
	for center in LAVA_POOLS:
		if p.distance_to(center)<LAVA_MOUTH_RADIUS:return VOLCANO_LAVA_SURFACE_Y
	return RIVER_LAVA_SURFACE_Y
func get_lava_escape_position(p:Vector2)->Vector3:
	for surface in _registered_lava_surfaces:
		var surface_center:Vector2=surface["center"] as Vector2
		var surface_radius:float=float(surface["radius"])
		if p.distance_to(surface_center)<surface_radius:
			var outward:Vector2=(p-surface_center).normalized() if p!=surface_center else Vector2.DOWN
			var edge:Vector2=surface_center+outward*(surface_radius+0.8)
			return Vector3(edge.x,get_mesh_height(edge.x,edge.y),edge.y)
	for center in LAVA_POOLS:
		if p.distance_to(center)<LAVA_MOUTH_RADIUS+2.0:
			var outward:Vector2=(p-center).normalized() if p!=center else Vector2.DOWN;var edge:Vector2=center+outward*(LAVA_MOUTH_RADIUS+10.0)
			return Vector3(edge.x,get_mesh_height(edge.x,edge.y),edge.y)
	if _river_coverage(p)>0.01:
		var best_edge:=p
		var best_height:=-INF
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			var candidate:=p+(direction as Vector2)*(RIVER_HALF_WIDTH+5.0)
			var height:=get_mesh_height(candidate.x,candidate.y)
			if not is_lava_area(candidate) and height>best_height:
				best_edge=candidate;best_height=height
		return Vector3(best_edge.x,get_mesh_height(best_edge.x,best_edge.y),best_edge.y)
	return Vector3(p.x,get_mesh_height(p.x,p.y),p.y)

func register_lava_surface(center:Vector2,radius:float,height:float)->void:
	_registered_lava_surfaces.append({"center":center,"radius":radius,"height":height})

func _color(p:Vector2)->Color:
	var heat:=0.0
	for center in LAVA_POOLS:heat=maxf(heat,1.0-smoothstep(LAVA_RADIUS,LAVA_RADIUS+55.0,p.distance_to(center)))
	heat=maxf(heat,_river_coverage(p))
	return Color(0.1,0.085,0.08).lerp(Color(0.34,0.13,0.065),heat)

func _build_mesh_and_collision()->void:
	var s:float=HALF_SIZE*2.0/float(RESOLUTION-1);var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in RESOLUTION:
		for ix in RESOLUTION:
			var v:=_vertex(ix,iz,s);st.set_color(_color(Vector2(v.x,v.z)));st.set_normal(get_mesh_normal(v.x,v.z));st.add_vertex(v)
	for iz in RESOLUTION-1:
		for ix in RESOLUTION-1:
			var i:int=iz*RESOLUTION+ix
			for n in [i,i+RESOLUTION,i+1,i+1,i+RESOLUTION,i+RESOLUTION+1]:st.add_index(n)
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.96;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;st.set_material(mat)
	var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();add_child(mesh)
	var faces:=PackedVector3Array()
	for iz in RESOLUTION-1:
		for ix in RESOLUTION-1:
			var a:=_vertex(ix,iz,s);var b:=_vertex(ix+1,iz,s);var c:=_vertex(ix,iz+1,s);var d:=_vertex(ix+1,iz+1,s)
			for v in [a,c,b,b,c,d]:faces.append(v)
	var shape:=ConcavePolygonShape3D.new();shape.set_faces(faces);shape.backface_collision=true
	var collider:=CollisionShape3D.new();collider.shape=shape;add_child(collider)

func _build_lava_pools()->void:
	for center in LAVA_POOLS:
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);var y:float=VOLCANO_LAVA_SURFACE_Y
		for i in 64:
			var a0:float=TAU*float(i)/64.0;var a1:float=TAU*float(i+1)/64.0
			for v in [Vector3(center.x,y,center.y),Vector3(center.x+cos(a1)*LAVA_MOUTH_RADIUS,y,center.y+sin(a1)*LAVA_MOUTH_RADIUS),Vector3(center.x+cos(a0)*LAVA_MOUTH_RADIUS,y,center.y+sin(a0)*LAVA_MOUTH_RADIUS)]:st.add_vertex(v)
		st.set_material(NatureProps.build_lava_material());var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();add_child(mesh)
		var light:=OmniLight3D.new();light.position=Vector3(center.x,y+2.0,center.y);light.light_color=Color(1.0,0.36,0.08);light.light_energy=2.2;light.omni_range=65.0;add_child(light)

func _build_lava_rivers()->void:
	for path_index in _river_centerlines.size():
		var path:=_river_centerlines[path_index]
		var segment_allowed:=_river_segment_allowed[path_index]
		var point_allowed:=_river_point_allowed[path_index]
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var surface_radius:float=RIVER_HALF_WIDTH+RIVER_SURFACE_OVERLAP
		for i in path.size()-1:
			var a:=path[i];var b:=path[i+1]
			if segment_allowed[i]==0:continue
			var tangent:=(b-a).normalized();var side:=Vector2(-tangent.y,tangent.x)*surface_radius
			var a_left:=Vector3(a.x,RIVER_LAVA_SURFACE_Y,a.y)+Vector3(side.x,0.0,side.y)
			var a_right:=Vector3(a.x,RIVER_LAVA_SURFACE_Y,a.y)-Vector3(side.x,0.0,side.y)
			var b_left:=Vector3(b.x,RIVER_LAVA_SURFACE_Y,b.y)+Vector3(side.x,0.0,side.y)
			var b_right:=Vector3(b.x,RIVER_LAVA_SURFACE_Y,b.y)-Vector3(side.x,0.0,side.y)
			for v in [a_left,b_left,a_right,a_right,b_left,b_right]:st.set_normal(Vector3.UP);st.add_vertex(v)
		## Rounded patches at the sampled centreline nodes close the triangular
		## gaps that otherwise appear on the outside of curved river bends.
		for point_index in path.size():
			if point_allowed[point_index]==0:continue
			var point:=path[point_index]
			var center:=Vector3(point.x,RIVER_LAVA_SURFACE_Y,point.y)
			for section in 12:
				var angle_a:=TAU*float(section)/12.0
				var angle_b:=TAU*float(section+1)/12.0
				var edge_a:=center+Vector3(cos(angle_a)*surface_radius,0.0,sin(angle_a)*surface_radius)
				var edge_b:=center+Vector3(cos(angle_b)*surface_radius,0.0,sin(angle_b)*surface_radius)
				for v in [center,edge_b,edge_a]:st.set_normal(Vector3.UP);st.add_vertex(v)
		st.set_material(NatureProps.build_lava_material());var mesh:=MeshInstance3D.new();mesh.mesh=st.commit();add_child(mesh)

func _build_fire_vents()->void:
	var positions:Array[Vector3]=[]
	for center in LAVA_POOLS:
		for j in 2:
			var offset:=Vector2.from_angle(_rng.randf_range(0.0,TAU))*_rng.randf_range(5.0,LAVA_RADIUS-5.0)
			positions.append(Vector3(center.x+offset.x,VOLCANO_LAVA_SURFACE_Y,center.y+offset.y))
	for path_index in _river_centerlines.size():
		var path:=_river_centerlines[path_index]
		var point_allowed:=_river_point_allowed[path_index]
		for fraction in [0.28,0.58,0.82]:
			var index:=clampi(roundi(float(path.size()-1)*fraction),0,path.size()-1);var p:=path[index]
			if point_allowed[index]==1:positions.append(Vector3(p.x,RIVER_LAVA_SURFACE_Y,p.y))
	for pos in positions:
		var particles:=_make_fire_burst();particles.position=pos;add_child(particles)
		# Sphere centered exactly on the same surface point the particles use
		# -- half above, half below the lava surface, per direct instruction.
		var bubble:=_make_lava_bubble();bubble.position=pos;add_child(bubble)
		var total:=_rng.randf_range(0.8,6.0)
		_fire_vents.append({
			"particles":particles,"bubble":bubble,
			"timer":total,"total":total,
			"peak":_rng.randf_range(BUBBLE_PEAK_RANGE.x,BUBBLE_PEAK_RANGE.y),
		})

func _make_lava_bubble()->MeshInstance3D:
	var bubble:=MeshInstance3D.new()
	var sphere:=SphereMesh.new();sphere.radius=1.0;sphere.height=2.0;sphere.radial_segments=12;sphere.rings=8
	bubble.mesh=sphere
	bubble.material_override=NatureProps.build_lava_material()
	bubble.scale=Vector3.ZERO
	return bubble

func _make_fire_burst()->GPUParticles3D:
	var particles:=GPUParticles3D.new();particles.amount=90;particles.lifetime=0.62;particles.one_shot=true;particles.explosiveness=0.76
	var process:=ParticleProcessMaterial.new();process.direction=Vector3.UP;process.spread=18.0;process.initial_velocity_min=6.0;process.initial_velocity_max=12.0;process.gravity=Vector3(0.0,1.5,0.0);process.scale_min=0.7;process.scale_max=1.5
	process.particle_flag_align_y=true;process.angle_min=-12.0;process.angle_max=12.0;process.turbulence_enabled=true;process.turbulence_noise_strength=1.0;process.turbulence_noise_scale=2.0;process.turbulence_influence_min=0.04;process.turbulence_influence_max=0.15
	process.color_ramp=ParticleFX.build_color_ramp([{"offset":0.0,"color":Color(1.0,0.95,0.75,1.0)},{"offset":0.25,"color":Color(1.0,0.55,0.1,1.0)},{"offset":0.6,"color":Color(0.85,0.25,0.05,0.9)},{"offset":1.0,"color":Color(0.35,0.06,0.02,0.0)}]);process.scale_curve=ParticleFX.build_scale_curve(0.2,1.15,0.3,0.12);particles.process_material=process
	var flame_material:=ParticleFX.build_billboard_material(ParticleFX.build_soft_gradient_texture(32,1.7,0.2),Color.WHITE,true,0.0);flame_material.vertex_color_use_as_albedo=true
	var quad:=QuadMesh.new();quad.size=Vector2(0.8,1.7);quad.material=flame_material;particles.draw_pass_1=quad
	particles.visibility_aabb=AABB(Vector3(-12,0,-12),Vector3(24,18,24));return particles

func _scatter_volcanic_rocks()->void:
	for i in 70:
		var p:=Vector2(_rng.randf_range(-560.0,560.0),_rng.randf_range(-560.0,560.0))
		if is_safe_zone(p) or is_lava_area(p) or p.length()<18.0:continue
		var rock:=NatureProps.build_rock(_rng.randf_range(0.5,2.5),true);rock.position=Vector3(p.x,get_mesh_height(p.x,p.y),p.y);rock.rotation.y=_rng.randf_range(0.0,TAU);add_child(rock)
