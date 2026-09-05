class_name SuperEgg
extends RefCounted

## General-purpose superellipsoid ("superegg") mesh builder -- every body
## part of the procedural figure rig (procedural_figure.gd) is one of
## these, tuned per part via anisotropic semi_axes and a per-part
## "squareness" exponent.
##
## The surface is parametrized by latitude eta (-PI/2 bottom pole to PI/2
## top pole) and longitude omega (around the vertical axis, 0 = local +Z,
## matching this project's own "+Z is forward" convention used everywhere
## else -- visuals.rotation.y's atan2(x, z), etc). epsilon is the exponent
## in the superellipse equation |x|^epsilon + |y|^epsilon = 1 that each
## axis pair traces: epsilon=2 is a plain ellipse: EPSILON_SOFT (>2) bows
## the profile out toward the corners -- boxier, flatter faces, softly
## rounded edges. Numbers well below 2 pull the curve in between the axis
## points instead -- pinched/star-shaped, not boxier -- verified
## numerically earlier in this project after a first attempt at a
## flat-bottomed head got that backwards and produced a witch's-hat cone
## instead of a flat "superegg" base. Don't go below 2 here.
##
## epsilon_top/epsilon_bottom let the LATITUDE profile (not the equatorial
## cross-section, which always uses epsilon_top) use a different exponent
## above vs. below the equator -- e.g. EPSILON_FLAT on both ends for a
## torso segment that needs to read as a distinct block with flat seams
## where it meets its neighbors, or EPSILON_SOFT on both for a limb
## segment that should read as a smooth capsule-like "post" instead.

const RINGS := 18
const SEGMENTS := 24

## Default "soft rounded cube" roundness -- most parts (limb segments,
## torso segment sides, the head's crown).
const EPSILON_SOFT := 3.0
## Boxier still -- used for a flat seam where one part's face should read
## as distinctly flat against its neighbor (torso segment tops/bottoms,
## the head's neck base).
const EPSILON_FLAT := 5.5


static func surface_point(
	semi_axes: Vector3, eta: float, omega: float,
	epsilon_top: float = EPSILON_SOFT, epsilon_bottom: float = EPSILON_SOFT
) -> Vector3:
	var lat_epsilon := epsilon_bottom if eta < 0.0 else epsilon_top
	var ce := _pow_sign(cos(eta), lat_epsilon)
	var se := _pow_sign(sin(eta), lat_epsilon)
	var so := _pow_sign(sin(omega), epsilon_top)
	var co := _pow_sign(cos(omega), epsilon_top)
	return Vector3(semi_axes.x * ce * so, semi_axes.y * se, semi_axes.z * ce * co)


static func _pow_sign(value: float, epsilon: float) -> float:
	return signf(value) * pow(absf(value), 2.0 / epsilon)


static func build_mesh(
	semi_axes: Vector3, epsilon_top: float = EPSILON_SOFT, epsilon_bottom: float = EPSILON_SOFT
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings: Array = []
	for ring_i in RINGS + 1:
		var v := float(ring_i) / RINGS
		var eta := -PI * 0.5 + v * PI
		var points: Array[Vector3] = []
		for seg in SEGMENTS:
			var omega := (float(seg) / SEGMENTS) * TAU
			points.append(surface_point(semi_axes, eta, omega, epsilon_top, epsilon_bottom))
		rings.append(points)

	for ring_i in RINGS:
		var ring_a: Array = rings[ring_i]
		var ring_b: Array = rings[ring_i + 1]
		for seg in SEGMENTS:
			var seg_next := (seg + 1) % SEGMENTS
			var a0: Vector3 = ring_a[seg]
			var a1: Vector3 = ring_a[seg_next]
			var b0: Vector3 = ring_b[seg]
			var b1: Vector3 = ring_b[seg_next]
			st.add_vertex(a0)
			st.add_vertex(b0)
			st.add_vertex(a1)
			st.add_vertex(a1)
			st.add_vertex(b0)
			st.add_vertex(b1)

	st.generate_normals()
	return st.commit()


## Convenience: mesh + MeshInstance3D + a StandardMaterial3D in the given
## color, the combination every body-part builder in procedural_figure.gd
## needs.
static func build_part(
	semi_axes: Vector3, color: Color,
	epsilon_top: float = EPSILON_SOFT, epsilon_bottom: float = EPSILON_SOFT
) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = build_mesh(semi_axes, epsilon_top, epsilon_bottom)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	mesh_instance.set_surface_override_material(0, material)
	return mesh_instance


## Vector3's own `[]` operator returns Variant (not float) when indexed by
## a non-constant int, since the static analyzer can't narrow it to a
## specific component at compile time -- these two helpers exist purely so
## build_inset_pad_mesh()'s axis-generic math can stay statically typed
## throughout instead of silently falling back to Variant everywhere.
static func _vec3_axis(v: Vector3, axis: int) -> float:
	match axis:
		0: return v.x
		1: return v.y
		_: return v.z


static func _vec3_set_axis(v: Vector3, axis: int, value: float) -> Vector3:
	match axis:
		0: v.x = value
		1: v.y = value
		_: v.z = value
	return v


## Builds an inset "pad" patch on one flat outward face of a box-shaped
## SuperEgg part, sitting flush against that face's own surface curvature
## (the same "1 - |a|^e - |b|^e" falloff build_mesh() itself uses, applied
## here to a rectangular footprint on two of the three axes instead of the
## whole surface) with a real domed volume -- a front layer that bulges
## outward, peaking at dome_height in the footprint's own center and
## tapering toward its rim, plus a back layer recessed back_embed just
## under the part's own bare surface, connected by a rim wall around the
## footprint's perimeter -- rather than a flat decal. General-purpose (not
## tied to any one figure rig): originally written for ape_template.gd's
## own hand/foot fur pads, then reused as-is for figure_ears.gd's own ear
## pad once that needed the exact same "inset patch flush on one edge,
## domed" shape, so it lives here rather than duplicated in both.
##
## The footprint tapers unevenly along proximal_axis: flush (full extent,
## no inset) at the proximal_sign edge, inset by tip_inset at the opposite
## edge; inset by side_inset on both edges of the third (side) axis.
## - part_size: the half-extents the part's own mesh was ACTUALLY built
##   with (this function's own semi_axes elsewhere in this file) -- must
##   match the real mesh, or the pad won't sit flush on the surface
##   actually rendered.
## - part_epsilon: must match that same actual mesh's own epsilon.
## - outward_axis/proximal_axis: which local axis (0=X, 1=Y, 2=Z) is the
##   part's own outward (face-normal) direction, and which distinguishes
##   the flush edge from the tapered one.
## - proximal_sign: +1.0 or -1.0, which direction along proximal_axis is
##   the flush edge; the opposite direction is the tapered one.
## dome_falloff_exponent applied to (1 - radius), not radius^2 like a
## normal dome -- an exponent below 1.0 stays close to 1.0 (full
## dome_height) across most of the radius and only drops toward 0 sharply
## right near the rim, reading as a raised flat-ish pad with a small
## rounded edge bevel rather than a smooth ball-like bump that only ever
## reaches full height at one single center point.
## Winding order (and so which side of the pad is front-facing) is a
## best-effort guess, not visually confirmed -- callers should disable
## cull_mode on whatever material they apply so the pad renders regardless
## either way.
static func build_inset_pad_mesh(
	part_size: Vector3, part_epsilon: float, outward_axis: int, proximal_axis: int,
	proximal_sign: float, side_inset: float, tip_inset: float, dome_height: float,
	dome_falloff_exponent: float, back_embed: float
) -> ArrayMesh:
	var side_axis := 3 - outward_axis - proximal_axis
	var side_size := _vec3_axis(part_size, side_axis)
	var proximal_size := _vec3_axis(part_size, proximal_axis)
	var outward_size := _vec3_axis(part_size, outward_axis)
	var side_extent := side_size * (1.0 - side_inset)
	var flush_coord := proximal_sign * proximal_size
	var tip_coord := -proximal_sign * proximal_size * (1.0 - tip_inset)

	# Raised from 4 -- per direct report the hand/foot fur pad "doesn't scale
	# up proportionally" at the giant gorilla's own 16x display_scale. The
	# actual scale MATH here is sound (part_size/dome_height/back_embed are
	# all plain values baked into a mesh that's a normal descendant of the
	# rig root, so Godot's own transform composition already scales the
	# whole thing uniformly and proportionally, same as every other part of
	# the figure -- there's no separate scale-dependent term anywhere in
	# this function to get wrong). What DOESN'T scale is polygon COUNT: at
	# ordinary ape size the dome's rounded falloff reads fine through a
	# coarse 5x5 grid, but blown up 16x larger in absolute terms, the exact
	# same facet count becomes individually large and visible, reading as a
	# faceted/blocky shape rather than a smoothly domed one -- plausibly
	# what "doesn't look proportionally right" is actually describing.
	# Raising the resolution here benefits every pad at every scale, not
	# just the giant's; adjustable further on report if this isn't it.
	const SIDE_SEGS := 8
	const PROX_SEGS := 8
	var front_grid: Array = []
	var back_grid: Array = []
	for pi in range(PROX_SEGS + 1):
		var t := float(pi) / float(PROX_SEGS)  # 0 = tapered edge, 1 = flush edge
		# lerpf(), not the generic lerp() -- that one's declared to accept
		# Variant, which trips the same "inferred from Variant"
		# strict-typing error _vec3_axis()/_vec3_set_axis() above exist to
		# avoid.
		var prox_coord := lerpf(tip_coord, flush_coord, t)
		var v := t * 2.0 - 1.0  # -1..1, for the dome's own radius below
		var front_row: Array[Vector3] = []
		var back_row: Array[Vector3] = []
		for si in range(SIDE_SEGS + 1):
			var u := float(si) / float(SIDE_SEGS) * 2.0 - 1.0  # -1..1
			var side_coord := u * side_extent
			var a := absf(side_coord) / side_size
			var b := absf(prox_coord) / proximal_size
			var term := maxf(1.0 - pow(a, part_epsilon) - pow(b, part_epsilon), 0.0)
			var base_coord := outward_size * pow(term, 1.0 / part_epsilon)
			var radius := clampf(sqrt(u * u + v * v), 0.0, 1.0)
			var dome := pow(1.0 - radius, dome_falloff_exponent) * dome_height
			var front_p := Vector3.ZERO
			front_p = _vec3_set_axis(front_p, side_axis, side_coord)
			front_p = _vec3_set_axis(front_p, proximal_axis, prox_coord)
			front_p = _vec3_set_axis(front_p, outward_axis, base_coord + dome)
			var back_p := Vector3.ZERO
			back_p = _vec3_set_axis(back_p, side_axis, side_coord)
			back_p = _vec3_set_axis(back_p, proximal_axis, prox_coord)
			back_p = _vec3_set_axis(back_p, outward_axis, base_coord - back_embed)
			front_row.append(front_p)
			back_row.append(back_p)
		front_grid.append(front_row)
		back_grid.append(back_row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Domed front face.
	for pi in range(PROX_SEGS):
		for si in range(SIDE_SEGS):
			var a: Vector3 = front_grid[pi][si]
			var b: Vector3 = front_grid[pi][si + 1]
			var c: Vector3 = front_grid[pi + 1][si]
			var d: Vector3 = front_grid[pi + 1][si + 1]
			st.add_vertex(a)
			st.add_vertex(c)
			st.add_vertex(b)
			st.add_vertex(b)
			st.add_vertex(c)
			st.add_vertex(d)
	# Rim wall around all four footprint edges, stitching the front dome's
	# own perimeter down to the recessed back layer -- gives the pad real
	# edge thickness instead of a zero-thickness sheet.
	for pi in range(PROX_SEGS):
		var fa: Vector3 = front_grid[pi][0]
		var fb: Vector3 = front_grid[pi + 1][0]
		var ba: Vector3 = back_grid[pi][0]
		var bb: Vector3 = back_grid[pi + 1][0]
		st.add_vertex(fa)
		st.add_vertex(fb)
		st.add_vertex(ba)
		st.add_vertex(fb)
		st.add_vertex(bb)
		st.add_vertex(ba)
		var fa2: Vector3 = front_grid[pi][SIDE_SEGS]
		var fb2: Vector3 = front_grid[pi + 1][SIDE_SEGS]
		var ba2: Vector3 = back_grid[pi][SIDE_SEGS]
		var bb2: Vector3 = back_grid[pi + 1][SIDE_SEGS]
		st.add_vertex(ba2)
		st.add_vertex(bb2)
		st.add_vertex(fa2)
		st.add_vertex(bb2)
		st.add_vertex(fb2)
		st.add_vertex(fa2)
	for si in range(SIDE_SEGS):
		var fa3: Vector3 = front_grid[0][si]
		var fb3: Vector3 = front_grid[0][si + 1]
		var ba3: Vector3 = back_grid[0][si]
		var bb3: Vector3 = back_grid[0][si + 1]
		st.add_vertex(ba3)
		st.add_vertex(bb3)
		st.add_vertex(fa3)
		st.add_vertex(bb3)
		st.add_vertex(fb3)
		st.add_vertex(fa3)
		var fa4: Vector3 = front_grid[PROX_SEGS][si]
		var fb4: Vector3 = front_grid[PROX_SEGS][si + 1]
		var ba4: Vector3 = back_grid[PROX_SEGS][si]
		var bb4: Vector3 = back_grid[PROX_SEGS][si + 1]
		st.add_vertex(fa4)
		st.add_vertex(fb4)
		st.add_vertex(ba4)
		st.add_vertex(fb4)
		st.add_vertex(bb4)
		st.add_vertex(ba4)
	st.generate_normals()
	return st.commit()
