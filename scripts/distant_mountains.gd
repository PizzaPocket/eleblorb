@tool
extends Node3D
class_name DistantMountains

## Organic distant relief beyond the playable terrain. The former version was
## one vertical ribbon: a jagged top edge over a perfectly flat wall. This is
## instead a small radial terrain field. Its near foot meets the world's far
## skirt, successive irregular rings form foothills and mountain shoulders,
## and its seaward flank continues below the shared planetary ocean. From the
## playable area the world therefore reads as a large island/landmass, never a
## map plane standing in front of a backdrop card. No collision is warranted
## this far outside the traversable terrain.

const RADIUS := 950.0  # near foot; matches terrain_generator's skirt outside
const OUTER_RADIUS := 1320.0
const SEGMENTS := 128
const RING_FRACTIONS: Array[float] = [0.0,0.18,0.42,0.66,0.84,1.0]
const BASE_HEIGHT := 38.0
const PEAK_VARIATION := 175.0
const MAIN_WORLD_FOOT_Y := -60.0
const OCEAN_BURY_MARGIN := 55.0

var _noise := FastNoiseLite.new()


func _ready() -> void:
	_noise.seed = 20260816
	_noise.frequency = 0.6
	_noise.fractal_octaves = 4
	for c in get_children():
		c.free()
	_build()


func _peak_height(angle: float) -> float:
	var sample := _noise.get_noise_2d(cos(angle) * 83.0, sin(angle) * 83.0)
	var broad := 0.28*sin(angle*3.0+0.6)+0.17*cos(angle*7.0-0.4)
	return BASE_HEIGHT+maxf(sample*0.82+broad,-0.18)*PEAK_VARIATION


func _ocean_level() -> float:
	var cycle:=get_parent().get_node_or_null("DayNightCycle")
	if cycle!=null and cycle.get("planetary_ocean_level")!=null:
		return float(cycle.get("planetary_ocean_level"))
	return -25.0


func _peak_color(h: float) -> Color:
	# Same palette as terrain_generator.gd's _height_color (including its
	# #13A367 grass), just rescaled for this ring's own much taller peak
	# range (BASE_HEIGHT..BASE_HEIGHT + PEAK_VARIATION, vs. the main
	# terrain's 0..45).
	var grass := Color(0.07451, 0.63922, 0.40392)
	var dirt := Color(0.55, 0.42, 0.24)
	var rock := Color(0.58, 0.57, 0.56)
	var snow := ElementPalette.SNOW_BODY
	if h < 60.0:
		return grass.lerp(dirt, smoothstep(30.0, 60.0, h))
	elif h < 130.0:
		return dirt.lerp(rock, smoothstep(60.0, 130.0, h))
	else:
		return rock.lerp(snow, smoothstep(130.0, 190.0, h))


func _build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ocean_floor:=_ocean_level()-OCEAN_BURY_MARGIN
	var rings: Array=[]
	for ring_index in RING_FRACTIONS.size():
		var fraction:float=RING_FRACTIONS[ring_index]
		var ring: Array[Dictionary]=[]
		for i in SEGMENTS:
			var angle:=TAU*float(i)/float(SEGMENTS)
			var angular_noise:=_noise.get_noise_2d(cos(angle)*41.0+float(ring_index)*9.0,sin(angle)*41.0)
			var radius:=lerpf(RADIUS,OUTER_RADIUS,fraction)+angular_noise*lerpf(5.0,20.0,fraction)
			var peak:=_peak_height(angle)
			var height:float
			match ring_index:
				0: height=MAIN_WORLD_FOOT_Y
				1: height=lerpf(MAIN_WORLD_FOOT_Y,peak,0.36)+angular_noise*8.0
				2: height=peak
				3: height=peak*0.58-18.0+angular_noise*12.0
				4: height=lerpf(peak*0.22-55.0,ocean_floor,0.44)
				_: height=ocean_floor
			var flat:=Vector2(cos(angle),sin(angle))*radius
			ring.append({"position":Vector3(flat.x,height,flat.y),"color":_peak_color(height)})
		rings.append(ring)
	for ring_index in rings.size()-1:
		for i in SEGMENTS:
			var next:=(i+1)%SEGMENTS
			var a:Dictionary=rings[ring_index][i]
			var b:Dictionary=rings[ring_index][next]
			var c:Dictionary=rings[ring_index+1][i]
			var d:Dictionary=rings[ring_index+1][next]
			_add_tri(st,a["position"],c["position"],b["position"],a["color"],c["color"],b["color"])
			_add_tri(st,b["position"],c["position"],d["position"],b["color"],c["color"],d["color"])

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = 0.0
	material.roughness = 1.0
	# Winding direction here was never verified against camera-facing
	# convention (viewed from inside the ring, near the origin) -- same
	# low-risk fix as terrain_generator.gd's own ground mesh: disable
	# culling rather than guess.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	add_child(mesh_instance)


func _add_tri(
	st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, c0: Color, c1: Color, c2: Color
) -> void:
	var normal := (p1 - p0).cross(p2 - p0).normalized()
	st.set_normal(normal)
	st.set_color(c0)
	st.add_vertex(p0)
	st.set_normal(normal)
	st.set_color(c1)
	st.add_vertex(p1)
	st.set_normal(normal)
	st.set_color(c2)
	st.add_vertex(p2)
