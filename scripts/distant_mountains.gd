@tool
extends Node3D

## A single ring of jagged, noise-varied peaks far beyond the playable
## plateau/gorge (see terrain_generator.gd) -- a cheap backdrop silhouette
## rather than real distant terrain, so the gorge doesn't just fade into
## empty sky. Colored with the same grass/dirt/rock/snow height gradient as
## the main terrain (scaled up for its own taller peaks) so it reads as a
## lush mountain range continuing into the distance rather than a flat
## painted wall. No collision -- nothing out here is reachable, it's well
## past terrain_generator.gd's edge barrier, and fog (see main.tscn) does
## most of the work of blending it into the sky.

const RADIUS := 950.0  # matches terrain_generator.gd's SKIRT_OUTER_RADIUS
const SEGMENTS := 96
const BASE_HEIGHT := 40.0
const PEAK_VARIATION := 160.0
const BOTTOM_Y := -150.0

var _noise := FastNoiseLite.new()


func _ready() -> void:
	_noise.seed = 20260816
	_noise.frequency = 0.6
	_noise.fractal_octaves = 4
	for c in get_children():
		c.free()
	_build()


func _peak_height(angle: float) -> float:
	var sample := _noise.get_noise_2d(cos(angle) * RADIUS * 0.1, sin(angle) * RADIUS * 0.1)
	# Floor the low end so there's always some semblance of a range instead
	# of gaps of flat nothing between peaks.
	return BASE_HEIGHT + maxf(sample, -0.2) * PEAK_VARIATION


func _peak_color(h: float) -> Color:
	# Same palette as terrain_generator.gd's _height_color (including its
	# #13A367 grass), just rescaled for this ring's own much taller peak
	# range (BASE_HEIGHT..BASE_HEIGHT + PEAK_VARIATION, vs. the main
	# terrain's 0..45).
	var grass := Color(0.07451, 0.63922, 0.40392)
	var dirt := Color(0.55, 0.42, 0.24)
	var rock := Color(0.58, 0.57, 0.56)
	var snow := Color(0.96, 0.97, 1.0)
	if h < 60.0:
		return grass.lerp(dirt, smoothstep(30.0, 60.0, h))
	elif h < 130.0:
		return dirt.lerp(rock, smoothstep(60.0, 130.0, h))
	else:
		return rock.lerp(snow, smoothstep(130.0, 190.0, h))


func _build() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var heights: Array[float] = []
	for i in SEGMENTS + 1:
		heights.append(_peak_height((float(i) / SEGMENTS) * TAU))

	for i in SEGMENTS:
		var a0 := (float(i) / SEGMENTS) * TAU
		var a1 := (float(i + 1) / SEGMENTS) * TAU
		var p0 := Vector2(cos(a0), sin(a0)) * RADIUS
		var p1 := Vector2(cos(a1), sin(a1)) * RADIUS
		var h0 := heights[i]
		var h1 := heights[i + 1]

		var top0 := Vector3(p0.x, h0, p0.y)
		var top1 := Vector3(p1.x, h1, p1.y)
		var bottom0 := Vector3(p0.x, BOTTOM_Y, p0.y)
		var bottom1 := Vector3(p1.x, BOTTOM_Y, p1.y)

		var c0 := _peak_color(h0)
		var c1 := _peak_color(h1)

		_add_tri(st, bottom0, top0, top1, c0, c0, c1)
		_add_tri(st, bottom0, top1, bottom1, c0, c1, c1)

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
