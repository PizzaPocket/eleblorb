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


## A HOLLOW superegg: an outer surface, an inner surface `wall_thickness`
## beneath it, and a superellipse aperture punched through one side, with the
## cut's rim closing the two surfaces together so the shell reads as real
## walls with real thickness rather than a paper skin.
##
## Each aperture is a superellipse prism used as a negative: centred at
## `center` (local Y/Z, on the +X side of the shell), with half-extents `half`
## (Y then Z) and squareness `exponent`, subtracted straight through the +X
## wall only -- the wall behind it stays whole. Anything a cut removes is
## replaced by rim geometry joining the outer surface to the inner one, so a
## character can walk in through a real doorway in a real hull.
##
## `wall_thickness` shrinks the semi-axes rather than offsetting each surface
## point along its own normal: on an anisotropic shell the wall is therefore a
## little thicker across the short axes than the long one, which is the
## convincing way round for a hull and cannot self-intersect as a true offset
## can. Keep it well under the smallest semi-axis.
##
## Denser than the solid builder by default: a doorway's rim shows the grid.
## How finely a cell the opening's edge runs through is subdivided before
## being clipped. Only those cells pay for it, so an outline can be sampled
## many times more densely than the shell's own grid for very little.
const EDGE_SUBDIVISION := 9


static func build_hollow_shell_mesh(
	semi_axes: Vector3, wall_thickness: float, apertures: Array[Dictionary],
	epsilon_top: float = EPSILON_SOFT, epsilon_bottom: float = EPSILON_SOFT,
	rings: int = RINGS * 2, segments: int = SEGMENTS * 2, keep_cut: bool = false,
	edge_subdivision: int = EDGE_SUBDIVISION
) -> ArrayMesh:
	var inner_axes := Vector3(
		maxf(semi_axes.x - wall_thickness, 0.01),
		maxf(semi_axes.y - wall_thickness, 0.01),
		maxf(semi_axes.z - wall_thickness, 0.01)
	)
	var outer: Array = []
	var inner: Array = []
	for ring_index in rings + 1:
		var eta := -PI * 0.5 + PI * float(ring_index) / float(rings)
		var outer_ring: Array[Vector3] = []
		var inner_ring: Array[Vector3] = []
		for segment in segments:
			var omega := TAU * float(segment) / float(segments)
			outer_ring.append(surface_point(semi_axes, eta, omega, epsilon_top, epsilon_bottom))
			inner_ring.append(surface_point(inner_axes, eta, omega, epsilon_top, epsilon_bottom))
		outer.append(outer_ring)
		inner.append(inner_ring)

	# How deep inside an opening each grid vertex lies. Cells are not kept or
	# dropped whole: one that straddles an edge is CLIPPED to it, so the
	# silhouette follows the opening's own curve however coarse the grid
	# beneath it. Dropping whole cells is what made every port and doorway
	# read as a staircase.
	var depth: Array = []
	for ring_index in rings + 1:
		var row: Array[float] = []
		for segment in segments:
			row.append(_aperture_depth(outer[ring_index][segment], apertures))
		depth.append(row)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring_index in rings:
		for segment in segments:
			var next_segment := (segment + 1) % segments
			# The cell's four corners, in a loop, and how deep each one is.
			var corner_depth: Array[float] = [
				depth[ring_index][segment], depth[ring_index][next_segment],
				depth[ring_index + 1][next_segment], depth[ring_index + 1][segment],
			]
			var outer_corner: Array[Vector3] = [
				outer[ring_index][segment], outer[ring_index][next_segment],
				outer[ring_index + 1][next_segment], outer[ring_index + 1][segment],
			]
			var inner_corner: Array[Vector3] = [
				inner[ring_index][segment], inner[ring_index][next_segment],
				inner[ring_index + 1][next_segment], inner[ring_index + 1][segment],
			]
			# Keeping the shell means keeping what lies OUTSIDE the opening;
			# building the piece an opening removed keeps the inside instead.
			var inside_count := 0
			for corner in 4:
				if corner_depth[corner] >= 0.0:
					inside_count += 1
			if inside_count == 4 and not keep_cut:
				continue
			if inside_count == 0 and keep_cut:
				continue
			# A cell nowhere near an edge is emitted whole. A cell the edge
			# runs through is subdivided first and each piece clipped, so the
			# outline is sampled far more densely than the hull's own grid
			# without making the whole hull finer. The chord from one crossing
			# to the next is what reads as a flat, and that is a question of
			# how often the edge is sampled, not of how exactly each sample
			# sits on the curve.
			var steps := 1 if inside_count == 0 or inside_count == 4 else maxi(edge_subdivision, 1)
			for row in steps:
				for column in steps:
					var patch_weights: Array = [
						_cell_weights(float(row) / float(steps), float(column) / float(steps)),
						_cell_weights(float(row + 1) / float(steps), float(column) / float(steps)),
						_cell_weights(float(row + 1) / float(steps), float(column + 1) / float(steps)),
						_cell_weights(float(row) / float(steps), float(column + 1) / float(steps)),
					]
					var patch_outer: Array[Vector3] = []
					var patch_inner: Array[Vector3] = []
					var patch_depth: Array[float] = []
					for weights in patch_weights:
						var at := _blend_corners(outer_corner, weights as Array)
						patch_outer.append(at)
						patch_inner.append(_blend_corners(inner_corner, weights as Array))
						# The field itself at this point, rather than the coarse
						# cell's corners interpolated, so every sample lands on
						# the curve instead of near it.
						patch_depth.append(_aperture_depth(at, apertures))
					var kept := _clip_cell(patch_depth, keep_cut)
					if kept.size() < 3:
						continue
					var outer_loop: Array[Vector3] = []
					var inner_loop: Array[Vector3] = []
					for weights in kept:
						outer_loop.append(_blend_corners(patch_outer, weights as Array))
						inner_loop.append(_blend_corners(patch_inner, weights as Array))
					for step in range(1, kept.size() - 1):
						st.add_vertex(outer_loop[0])
						st.add_vertex(outer_loop[step])
						st.add_vertex(outer_loop[step + 1])
						# The inner surface faces the cabin: winding reverses.
						st.add_vertex(inner_loop[0])
						st.add_vertex(inner_loop[step + 1])
						st.add_vertex(inner_loop[step])
					# The rim: every edge the clip produced, closed straight
					# across the wall from the outer surface to the inner one.
					# A flat cap, square to both.
					for index in kept.size():
						var here: Array = kept[index]
						var after: Array = kept[(index + 1) % kept.size()]
						if bool(here[4]) and bool(after[4]):
							_add_rim(
								st, outer_loop[index], outer_loop[(index + 1) % kept.size()],
								inner_loop[index], inner_loop[(index + 1) % kept.size()]
							)
	st.generate_normals()
	return st.commit()


## The piece one aperture removes from a shell, built from the same grid and
## the same cut test as the hole itself, so it fits that hole exactly rather
## than by matching numbers by hand. Fill a window with one of these in glass
## and it sits flush in its own opening; every argument must match the call
## that cut the shell.
static func build_shell_patch_mesh(
	semi_axes: Vector3, wall_thickness: float, aperture: Dictionary,
	epsilon_top: float = EPSILON_SOFT, epsilon_bottom: float = EPSILON_SOFT,
	rings: int = RINGS * 2, segments: int = SEGMENTS * 2
) -> ArrayMesh:
	var only: Array[Dictionary] = [aperture]
	return build_hollow_shell_mesh(
		semi_axes, wall_thickness, only, epsilon_top, epsilon_bottom, rings, segments, true
	)


## One cell clipped to an opening's edge, as bilinear weights over its four
## corners. Each entry is [w0, w1, w2, w3, on_edge]; on_edge marks a point the
## clip itself produced, which is where the rim wall goes.
## The bilinear weights of the point at (u, v) inside a cell whose corners are
## given in a loop.
static func _cell_weights(u: float, v: float) -> Array:
	return [(1.0 - u) * (1.0 - v), u * (1.0 - v), u * v, (1.0 - u) * v, false]


static func _clip_cell(corner_depth: Array[float], keep_inside: bool) -> Array:
	var polygon: Array = []
	for index in 4:
		var weights := [0.0, 0.0, 0.0, 0.0, false]
		weights[index] = 1.0
		polygon.append(weights)
	var keep_sign := 1.0 if keep_inside else -1.0
	var clipped: Array = []
	for index in polygon.size():
		var here: Array = polygon[index]
		var after: Array = polygon[(index + 1) % polygon.size()]
		var here_depth := keep_sign * _weighted_depth(corner_depth, here)
		var after_depth := keep_sign * _weighted_depth(corner_depth, after)
		if here_depth >= 0.0:
			clipped.append(here)
		if (here_depth >= 0.0) != (after_depth >= 0.0):
			var t := clampf(
				here_depth / maxf(here_depth - after_depth, 0.000001), 0.0, 1.0
			)
			var crossing := [0.0, 0.0, 0.0, 0.0, true]
			for corner in 4:
				crossing[corner] = lerpf(float(here[corner]), float(after[corner]), t)
			clipped.append(crossing)
	return clipped


static func _weighted_depth(corner_depth: Array[float], weights: Array) -> float:
	var total := 0.0
	for index in 4:
		total += corner_depth[index] * float(weights[index])
	return total


static func _blend_corners(corners: Array[Vector3], weights: Array) -> Vector3:
	var point := Vector3.ZERO
	for index in 4:
		point += corners[index] * float(weights[index])
	return point


## How far inside an opening a point lies: positive inside, negative outside,
## zero exactly on its edge. The clip interpolates along this, so the edge it
## finds is the opening's own curve rather than the nearest grid line.
static func _aperture_depth(point: Vector3, apertures: Array[Dictionary]) -> float:
	var deepest := -1.0
	for aperture in apertures:
		var side: float = aperture.get("side", 1.0)
		if point.x * side <= 0.0:
			continue
		var measure := 2.0
		if aperture.has("sphere_center"):
			var sphere_centre: Vector3 = aperture["sphere_center"]
			measure = point.distance_to(sphere_centre) / maxf(float(aperture["sphere_radius"]), 0.0001)
		else:
			var centre: Vector2 = aperture["center"]
			var half: Vector2 = aperture["half"]
			var exponent: float = aperture.get("exponent", EPSILON_SOFT)
			var across := absf(point.y - centre.x) / maxf(half.x, 0.001)
			var along := absf(point.z - centre.y) / maxf(half.y, 0.001)
			# The exponent-th root, so this reads as a distance and
			# interpolates evenly from one grid vertex to the next.
			measure = pow(pow(across, exponent) + pow(along, exponent), 1.0 / exponent)
		deepest = maxf(deepest, 1.0 - measure)
	return deepest


static func _inside_any_aperture(point: Vector3, apertures: Array[Dictionary]) -> bool:
	for aperture in apertures:
		var side: float = aperture.get("side", 1.0)
		if point.x * side <= 0.0:
			continue
		# A solid mass can cut the opening instead of a flat outline: the hole
		# is then exactly where that mass meets this shell, which is how two
		# hulls are made to seal against each other.
		if aperture.has("sphere_center"):
			var sphere_centre: Vector3 = aperture["sphere_center"]
			if point.distance_to(sphere_centre) <= float(aperture["sphere_radius"]):
				return true
			continue
		var centre: Vector2 = aperture["center"]
		var half: Vector2 = aperture["half"]
		var exponent: float = aperture.get("exponent", EPSILON_SOFT)
		var across := absf(point.y - centre.x) / maxf(half.x, 0.001)
		var along := absf(point.z - centre.y) / maxf(half.y, 0.001)
		if pow(across, exponent) + pow(along, exponent) <= 1.0:
			return true
	return false


## Whether `point` lies inside the superellipsoid of `semi_axes`, by the same
## profile the surface is drawn from. The solid answer to "is this inside the
## body", for anything that needs the real volume rather than a box around it.
static func contains_point(
	semi_axes: Vector3, point: Vector3,
	epsilon_top: float = EPSILON_SOFT, epsilon_bottom: float = EPSILON_SOFT
) -> bool:
	var ax := maxf(absf(semi_axes.x), 0.0001)
	var ay := maxf(absf(semi_axes.y), 0.0001)
	var az := maxf(absf(semi_axes.z), 0.0001)
	var epsilon: float = epsilon_top if point.y >= 0.0 else epsilon_bottom
	var around := (
		pow(absf(point.x / ax), epsilon) + pow(absf(point.z / az), epsilon)
	)
	return pow(around, epsilon / epsilon) + pow(absf(point.y / ay), epsilon) <= 1.0


static func _add_quad(st: SurfaceTool, a0: Vector3, b0: Vector3, a1: Vector3, b1: Vector3) -> void:
	st.add_vertex(a0)
	st.add_vertex(b0)
	st.add_vertex(a1)
	st.add_vertex(a1)
	st.add_vertex(b0)
	st.add_vertex(b1)


## One rim quad joining an outer edge to the matching inner edge, wound so it
## faces into the doorway rather than into the wall it closes.
static func _add_rim(st: SurfaceTool, outer_a: Vector3, outer_b: Vector3, inner_a: Vector3, inner_b: Vector3) -> void:
	var normal := (outer_b - outer_a).cross(inner_a - outer_a)
	var toward_wall := (outer_a + outer_b) * 0.5
	if normal.dot(toward_wall) > 0.0:
		st.add_vertex(outer_a)
		st.add_vertex(outer_b)
		st.add_vertex(inner_a)
		st.add_vertex(inner_a)
		st.add_vertex(outer_b)
		st.add_vertex(inner_b)
		return
	st.add_vertex(outer_a)
	st.add_vertex(inner_a)
	st.add_vertex(outer_b)
	st.add_vertex(outer_b)
	st.add_vertex(inner_a)
	st.add_vertex(inner_b)
