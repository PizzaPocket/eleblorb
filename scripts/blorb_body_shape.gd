class_name BlorbBodyShape
extends RefCounted

## Shared "classic slime silhouette" lathe-body builder -- the exact same
## squashed-sphere-with-BULGE_T-biased profile blorb.gd's own body uses,
## factored out so blorb_suit.gd's head/hat covering (see
## its build_head()) can reuse the identical silhouette at a different
## scale instead of duplicating the profile math a second time. blorb.gd
## itself now calls into this too (see its _build_body_mesh()) rather than
## keeping its own private copy.
##
## Split into build_rings()/build_mesh_from_rings() (rather than a single
## build_mesh()) specifically so a caller can post-process the raw ring
## points before triangulating -- blorb_suit.gd's hat needs an asymmetric
## back droop a plain surface of revolution can't express on its own (see
## that file's own _build_hat_rings()).

const BULGE_T := 0.30
const RING_COUNT := 20
const RADIAL_SEGMENTS := 24
const EYE_SURFACE_T_DELTA := 0.01
## Only the final crown needs softening. A full ellipse made the entire upper
## half too broad; this restrained blend keeps the original taper dominant.
const TOP_ROUNDING_BLEND := 0.22


## upper_taper_blend only softens the UPPER half's narrowing (t >= BULGE_T,
## the "hips to shoulders" taper) toward staying full-width, leaving the
## lower rounded bulge untouched -- added for monkey_figure.gd's villager
## variant, whose bodies read as too extreme a pear shape (a wide bulge
## narrowing sharply to the shoulders) per direct feedback. Default 1.0
## reproduces the exact original profile for every existing caller (blorb.gd,
## blorb_suit.gd) unchanged.
static func profile_radius(t: float, upper_taper_blend: float = 1.0) -> float:
	# The lower quarter-ellipse removes the underside's shallow cone. Above
	# the bulge, retain the original narrow sine taper and blend in only a
	# little ellipse curvature: enough to soften the very tip without turning
	# the whole crown broad and dome-like.
	var clamped_t := clampf(t, 0.0, 1.0)
	if clamped_t < BULGE_T:
		var lower_t := clamped_t / BULGE_T
		return sqrt(maxf(0.0, 1.0 - (1.0 - lower_t) * (1.0 - lower_t)))
	var upper_t := (clamped_t - BULGE_T) / (1.0 - BULGE_T)
	var original_taper := cos(upper_t * PI * 0.5)
	var rounded_taper := sqrt(maxf(0.0, 1.0 - upper_t * upper_t))
	var raw := lerpf(original_taper, rounded_taper, TOP_ROUNDING_BLEND)
	return lerpf(1.0, raw, upper_taper_blend)


## Ungenerated ring points (bottom pole..top pole), radius/height scaled --
## a caller wanting the plain, unmodified silhouette should feed this
## straight into build_mesh_from_rings(); build_mesh() below does exactly
## that as a convenience.
static func build_rings(radius: float, height: float, upper_taper_blend: float = 1.0) -> Array:
	var rings: Array = []
	for ring_i in RING_COUNT + 1:
		var t := float(ring_i) / RING_COUNT
		var r := profile_radius(t, upper_taper_blend) * radius
		var y := t * height
		var points: Array[Vector3] = []
		for seg in RADIAL_SEGMENTS:
			var angle := (float(seg) / RADIAL_SEGMENTS) * TAU
			points.append(Vector3(cos(angle) * r, y, sin(angle) * r))
		rings.append(points)
	return rings


## Segment count is read off each ring's own size rather than assumed to be
## RADIAL_SEGMENTS -- every caller in this file still builds RADIAL_SEGMENTS
## -sized rings so this is unchanged for them, but blorb_suit.gd's limb
## tubes (see its build_limb_tube()) use a different, coarser count and
## reuse this same strip-triangulation instead of duplicating it.
## ring_colors is optional (parallel to `rings`, one Color per ring) --
## per direct correction ("color the bottoms of the legs... without this
## being another additional piece, just change the color of that area of
## the objects"), horse_figure.gd's leg tubes now pass a per-ring color so
## the single existing mesh can shade its own bottom end a different color,
## rather than adding a second overlapping mesh. Every other caller
## (blorb head/hat/torso, the knight helm, monkey_figure.gd's own limbs)
## still calls this with no ring_colors at all, which leaves the mesh with
## no COLOR array whatsoever -- identical to this function's behavior
## before this param existed, since a material with vertex_color_use_as_
## albedo left off (every existing material) just ignores it anyway.
static func build_mesh_from_rings(rings: Array, ring_colors: Array[Color] = []) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_colors := not ring_colors.is_empty()
	for ring_i in rings.size() - 1:
		var ring_a: Array = rings[ring_i]
		var ring_b: Array = rings[ring_i + 1]
		var segments: int = ring_a.size()
		var color_a: Color = ring_colors[ring_i] if has_colors else Color.WHITE
		var color_b: Color = ring_colors[ring_i + 1] if has_colors else Color.WHITE
		for seg in segments:
			var seg_next := (seg + 1) % segments
			var a0: Vector3 = ring_a[seg]
			var a1: Vector3 = ring_a[seg_next]
			var b0: Vector3 = ring_b[seg]
			var b1: Vector3 = ring_b[seg_next]
			_add_colored_vertex(st, a0, color_a, has_colors)
			_add_colored_vertex(st, b0, color_b, has_colors)
			_add_colored_vertex(st, a1, color_a, has_colors)
			_add_colored_vertex(st, a1, color_a, has_colors)
			_add_colored_vertex(st, b0, color_b, has_colors)
			_add_colored_vertex(st, b1, color_b, has_colors)
	# Most blorb profiles close into zero-radius poles. A few deliberately
	# shaped forms (the knight helm's flat crown/guard) terminate in a real
	# ring instead; cap only those rings so they remain a single closed mesh
	# rather than needing a visually separate lid piece.
	if not rings.is_empty():
		var cap_color_a: Color = ring_colors[0] if has_colors else Color.WHITE
		var cap_color_b: Color = ring_colors[ring_colors.size() - 1] if has_colors else Color.WHITE
		_add_ring_cap(st, rings[0] as Array, true, cap_color_a, has_colors)
		_add_ring_cap(st, rings[rings.size() - 1] as Array, false, cap_color_b, has_colors)
	st.generate_normals()
	return st.commit()


static func _add_colored_vertex(st: SurfaceTool, pos: Vector3, color: Color, has_color: bool) -> void:
	if has_color:
		st.set_color(color)
	st.add_vertex(pos)


static func _add_ring_cap(st: SurfaceTool, ring: Array, bottom: bool, color: Color = Color.WHITE, has_color: bool = false) -> void:
	if ring.is_empty() or ring[0].length_squared() < 0.000001:
		return
	var center := Vector3.ZERO
	for raw_point in ring:
		center += raw_point as Vector3
	center /= float(ring.size())
	for i in ring.size():
		var next := (i + 1) % ring.size()
		if bottom:
			_add_colored_vertex(st, center, color, has_color)
			_add_colored_vertex(st, ring[next] as Vector3, color, has_color)
			_add_colored_vertex(st, ring[i] as Vector3, color, has_color)
		else:
			_add_colored_vertex(st, center, color, has_color)
			_add_colored_vertex(st, ring[i] as Vector3, color, has_color)
			_add_colored_vertex(st, ring[next] as Vector3, color, has_color)


static func build_mesh(radius: float, height: float, upper_taper_blend: float = 1.0) -> ArrayMesh:
	return build_mesh_from_rings(build_rings(radius, height, upper_taper_blend))


## Eye-line surface data at parametric height t (0=bottom pole, 1=top
## pole) -- the same finite-difference dr_dy derivation blorb.gd's own
## _build_visuals() uses for its real eyes (see blorb_face.gd's own
## docstring for why the true surface normal isn't purely horizontal),
## factored out here so any lathe body built from this class -- blorb.gd's
## real body, or blorb_suit.gd's differently-scaled hat -- can place
## BlorbFace eyes without re-deriving this twice.
static func eye_surface(t: float, radius: float, height: float) -> Dictionary:
	var r_before := profile_radius(t - EYE_SURFACE_T_DELTA) * radius
	var r_after := profile_radius(t + EYE_SURFACE_T_DELTA) * radius
	var dr_dy := (r_after - r_before) / (EYE_SURFACE_T_DELTA * 2.0 * height)
	return {
		"y": t * height,
		"radius": profile_radius(t) * radius,
		"dr_dy": dr_dy,
	}


## The exact "translucent goo" material treatment blorb.gd's own body uses
## -- factored out so blorb.gd's _build_visuals() and blorb_suit.gd's worn
## pieces build their materials from this ONE shared function instead of
## two hand-kept-in-sync copies. Per direct instruction that worn pieces
## should react to lighting (sun color/energy shifting through the day/
## night cycle, etc) exactly like an ordinary blorb -- sharing the actual
## construction code is what guarantees that, rather than trying to keep
## two separate property lists identical by eye. Neither this material nor
## blorb.gd's own gets any lighting-specific handling beyond this -- day_
## night_cycle.gd only ever touches the scene's DirectionalLight3D/sky/fog
## globally, so any ordinary lit StandardMaterial3D in the scene (this one
## included) already reacts automatically, no per-object hookup needed.
static func build_body_material(
	albedo: Color, roughness: float, metallic: float,
	emission_enabled: bool, emission: Color, emission_energy: float
) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.metallic = metallic
	mat.roughness = roughness
	mat.rim_enabled = true
	mat.rim = 0.45
	mat.rim_tint = 0.6
	# ALPHA_DEPTH_PRE_PASS, not plain ALPHA -- see blorb.gd's own original
	# comment: a plain alpha-blend material doesn't write depth, and
	# Godot's shadow pass is depth-based, so the body would cast no shadow
	# at all without this.
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emission_enabled:
		mat.emission_enabled = true
		mat.emission = emission
		mat.emission_energy_multiplier = emission_energy
	return mat
