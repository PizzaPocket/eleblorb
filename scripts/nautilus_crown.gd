class_name NautilusCrown
extends RefCounted

## The Nautilus Crown's shape, shared by the living helm a blorb becomes after
## binding it (BlorbSuit._build_nautilus_crown()) and the loose item. One
## continuous piped curve, in the head's side-on (Y-Z) plane:
##
## - The base: a smoothly rounded nose just in front of the forehead, the
##   headwear's front face with the blorb's eyes on it. Behind it the tube,
##   fat and nearly round in cross-section, sinks back into the head.
## - The rise: from there it arcs back and quickly down round the back of
##   the head.
## - The spiral: it winds inward round a centre just behind the head as
##   a logarithmic spiral, its cross-section flattening to a broad oval whose
##   thickness across the curl exactly fills the gap to the next whorl in, so
##   the turns stack into one solid mass with no valleys, until it closes.
##
## Its width holds through the base, tapers as it arches back and curls, and
## the innermost whorls may press back into the base: one solid mass.
## Worn, it gives the same air supply as the Diving Helmet; over two Water
## leg blorbs it commands the mermaid tail (see BlorbSuitController).

const SHELL_COLOR := Color(0.36, 0.88, 0.74)

## The base's half-width, a fraction of the head's half-width, and its
## thickness out of the head as a fraction of that width: nearly round.
const BASE_WIDTH := 1.25
const BASE_ROUNDNESS := 0.85
## The base sits like a band over the brow, from its nose just above the
## eyes (angle up from the front, round the head's centre) back over the
## front of the head. Its
## centreline starts at 1 + BASE_FRONT_GAP of the head's radius, just inside
## the forehead so the tube's rounded front face stands just ahead of it, and
## sinks to BASE_SINK of the head's radius at its back end, burying the rear
## of the base in the head.
const BASE_FROM := deg_to_rad(4.0)
const BASE_TO := deg_to_rad(62.0)
const BASE_FRONT_GAP := -0.12
const BASE_SINK := 0.72
const BASE_SAMPLES := 18
## The spiral's centre, just behind the head and barely above its middle
## (fractions of the head's half-height and half-depth from its centre), so
## the rise arcs back and down quickly and the spiral's bulk sits low round
## the back of the head.
const COIL_UP := 0.15
const COIL_BACK := 1.0
## How fast the spiral tightens (its radius falls by exp(-DECAY * TAU) each
## turn), how much each whorl overlaps the one inside it, and where it
## closes.
const DECAY := 0.2
const WHORL_OVERLAP := 1.2
const CLOSING_RADIUS := 0.006
const CENTRE_THICKNESS := 0.01
const MAX_TURNS := 8.0
const SPIRAL_SAMPLES := 170
## Width after the taper (a fraction of the head's half-width), reached where
## the curve points straight back (the spiral's angle PI).
const BACK_WIDTH := 0.72
## The rounded nose: over this much of the base's width the tube swells from
## a point to full size.
const NOSE_LENGTH := 1.0
## Passes of smoothing over the join between the base and the spiral, so the
## rise is one flowing arc.
const JOIN_SMOOTHING := 8
const SEGMENTS := 22


## The whole curve for a head whose bounds are `contents`: per sample, the
## centreline point, the half-width across the head and the half-thickness
## across the curl.
static func shape(contents: AABB) -> Dictionary:
	var center := contents.get_center()
	var half := contents.size * 0.5
	var base_width := half.x * BASE_WIDTH
	var base_thickness := base_width * BASE_ROUNDNESS
	var points: Array[Vector3] = []
	var widths: Array[float] = []
	var thicknesses: Array[float] = []
	# The base, nearly round, from just ahead of the forehead back into the
	# head.
	for index in BASE_SAMPLES:
		var along := float(index) / float(BASE_SAMPLES)
		var angle := lerpf(BASE_FROM, BASE_TO, along)
		var reach := lerpf(1.0 + BASE_FRONT_GAP, BASE_SINK, smoothstep(0.0, 1.0, along))
		points.append(center + Vector3(0.0, sin(angle) * half.y, cos(angle) * half.z) * reach)
		widths.append(base_width)
		thicknesses.append(base_thickness)
	# The rise and spiral, round a centre just behind the head,
	# starting where the base ends.
	var coil := center + Vector3(0.0, half.y * COIL_UP, -half.z * COIL_BACK)
	var start := center + Vector3(0.0, sin(BASE_TO) * half.y, cos(BASE_TO) * half.z) * BASE_SINK
	var start_angle := atan2(start.y - coil.y, start.z - coil.z)
	var start_radius := Vector2(start.z - coil.z, start.y - coil.y).length()
	var winding := minf(log(start_radius / CLOSING_RADIUS) / DECAY, TAU * MAX_TURNS)
	var shrink := exp(-DECAY * TAU)
	var back_width := half.x * BACK_WIDTH
	for index in SPIRAL_SAMPLES + 1:
		var angle := start_angle + winding * float(index) / float(SPIRAL_SAMPLES)
		var radius := start_radius * exp(-DECAY * (angle - start_angle))
		points.append(coil + Vector3(0.0, sin(angle), cos(angle)) * radius)
		# Full and nearly round as it leaves the base, tapering in width and
		# flattening into the stacked whorls as it arches back and curls.
		var toward_back := smoothstep(start_angle, PI, angle)
		var width := lerpf(base_width, back_width, toward_back)
		var packed := maxf(radius * (1.0 - shrink) / (1.0 + shrink) * WHORL_OVERLAP, CENTRE_THICKNESS)
		widths.append(width)
		thicknesses.append(lerpf(base_thickness, minf(packed, width), toward_back))
	# One flowing arc where the base turns up into the rise.
	for _pass in JOIN_SMOOTHING:
		for index in range(BASE_SAMPLES - 6, BASE_SAMPLES + 10):
			points[index] = (points[index - 1] + points[index] * 2.0 + points[index + 1]) * 0.25
	return {"points": points, "widths": widths, "thicknesses": thicknesses, "head_center": center, "base_width": base_width}


## The curve's frame at sample `index`: its direction, the across-the-head
## axis, and the out-from-the-head axis across the curl (pointing away from
## the head's centre on the base).
static func frame(curve: Dictionary, index: int) -> Dictionary:
	var points: Array[Vector3] = curve["points"]
	var before := points[maxi(index - 1, 0)]
	var after := points[mini(index + 1, points.size() - 1)]
	var tangent := (after - before).normalized()
	var side := Vector3.RIGHT
	# Same frame orientation as BlorbSuit.build_limb_tube(): side x up = tangent.
	var up := tangent.cross(side)
	return {"tangent": tangent, "side": side, "up": up}


## The tube's size at sample `index`, including the nose's rounding: the
## base swells from a point at the brow like the end of any blorb.
static func size_at(curve: Dictionary, index: int) -> Vector2:
	var points: Array[Vector3] = curve["points"]
	var along := 0.0
	for step in index:
		along += points[step].distance_to(points[step + 1])
	var nose := float(curve["base_width"]) * NOSE_LENGTH
	var rounding := sqrt(maxf(0.0, 1.0 - pow(1.0 - clampf(along / nose, 0.0, 1.0), 2.0)))
	return Vector2(float(curve["widths"][index]), float(curve["thicknesses"][index])) * rounding


## A point on the tube's surface at sample `index`, `around` radians round
## its cross-section (0 across to +X, PI/2 along "up"), and the outward
## normal there.
static func surface(curve: Dictionary, index: int, around: float) -> Dictionary:
	var axes := frame(curve, index)
	var size := size_at(curve, index)
	var side: Vector3 = axes["side"]
	var up: Vector3 = axes["up"]
	var center: Vector3 = (curve["points"] as Array[Vector3])[index]
	var point := center + side * cos(around) * size.x + up * sin(around) * size.y
	var normal := (side * cos(around) / maxf(size.x, 0.0001) + up * sin(around) / maxf(size.y, 0.0001)).normalized()
	return {"point": point, "normal": normal}


static func build_mesh(curve: Dictionary) -> ArrayMesh:
	var rings: Array = []
	var points: Array[Vector3] = curve["points"]
	for index in points.size():
		var axes := frame(curve, index)
		var size := size_at(curve, index)
		var side: Vector3 = axes["side"]
		var up: Vector3 = axes["up"]
		var ring: Array[Vector3] = []
		for segment in SEGMENTS:
			var around := TAU * float(segment) / float(SEGMENTS)
			ring.append(points[index] + side * cos(around) * size.x + up * sin(around) * size.y)
		rings.append(ring)
	return BlorbBodyShape.build_mesh_from_rings(rings)


## Which way round the base's cross-section faces out of the head: +PI/2 or
## -PI/2 along the frame's up axis at sample `index`.
static func outward_around(curve: Dictionary, index: int) -> float:
	var axes := frame(curve, index)
	var center: Vector3 = (curve["points"] as Array[Vector3])[index]
	var away := center - (curve["head_center"] as Vector3)
	return PI * 0.5 if (axes["up"] as Vector3).dot(away) >= 0.0 else -PI * 0.5


## Standalone shop/inventory visual: sized off the figure's generic head.
static func build_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "NautilusCrown"
	var head_size := ProceduralFigure.HEAD_SIZE * item_scale
	var material := StandardMaterial3D.new()
	material.albedo_color = SHELL_COLOR
	material.roughness = 0.35
	var shell := MeshInstance3D.new()
	shell.name = "Shell"
	shell.mesh = build_mesh(shape(AABB(Vector3(-head_size.x, 0.0, -head_size.z), head_size * 2.0)))
	shell.material_override = material
	root.add_child(shell)
	return root
