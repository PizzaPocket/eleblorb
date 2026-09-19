class_name NautilusCrown
extends RefCounted

## The Nautilus Crown's shape, shared by the living helm a blorb becomes after
## binding it (BlorbSuit._build_nautilus_crown()) and the loose item. Two
## parts of one living mass:
##
## - The cap: a thick, rounded blorb shell sitting on the head from just
##   above the eyes over the crown, its edge a rolled lip rather than a cut,
##   the blorb's eyes on its brow. It covers the whole top and back of the
##   skull, so nothing of the head shows through the shell above it.
## - The shell: a nautilus spiral growing from the top of the cap and coiling
##   back and up behind the head, so its mass sits clear of the skull. As in
##   a real nautilus it is one solid body: every whorl is thick enough to
##   overlap the one inside it, leaving no valleys between the turns, and it
##   winds in until it closes at its centre. Broad where it leaves the cap, it
##   narrows smoothly to the back of the head and holds that width after.
##
## Worn, it gives the same air supply as the Diving Helmet; over two Water
## leg blorbs it commands the mermaid tail (see BlorbSuitController).

const SHELL_COLOR := Color(0.36, 0.88, 0.74)

## The cap: its rim this far above the head's centre (a fraction of the head's
## half-height: just above the eyes), its inside this much wider and deeper
## than the head, reaching this far above the top of the head (a fraction of
## its height), and this thick (a fraction of the head's half-width).
const CAP_RIM := 0.22
const CAP_MARGIN := Vector2(1.08, 1.1)
const CAP_CROWN_CLEARANCE := 0.05
const CAP_THICKNESS := 0.3
const CAP_SEGMENTS := 28

## The spiral's centre: behind the head (a fraction of its half-depth beyond
## the back of the skull) and above its centre (a fraction of half-height).
## It starts on the top of the cap this far forward of the head's centre (a
## fraction of half-depth).
const COIL_BEHIND := 0.6
const COIL_UP := 0.55
const START_FORWARD := 0.0
## How fast the spiral tightens (its radius falls by exp(-DECAY * TAU) each
## turn), and how much each whorl overlaps the one inside it.
const DECAY := 0.16
const WHORL_OVERLAP := 1.2
## Width where it leaves the cap and after it reaches the back of the head
## (fractions of the head's half-width).
const START_WIDTH := 1.05
const BACK_WIDTH := 0.72
## The spiral winds in until its centreline is this close to the centre.
const CLOSING_RADIUS := 0.006
const CENTRE_THICKNESS := 0.012
const MAX_TURNS := 8.0
const SAMPLES := 180
const SEGMENTS := 20


## The cap for a head whose bounds are `contents`.
static func cap(contents: AABB) -> Dictionary:
	var center := contents.get_center()
	var half := contents.size * 0.5
	var rim := center.y + half.y * CAP_RIM
	var inner := Vector2(half.x * CAP_MARGIN.x, half.z * CAP_MARGIN.y)
	var inner_height := contents.end.y + contents.size.y * CAP_CROWN_CLEARANCE - rim
	return {
		"center": Vector2(center.x, center.z), "rim": rim, "inner": inner,
		"inner_height": inner_height, "thickness": half.x * CAP_THICKNESS,
	}


## The cap's outer surface at `lift` (0 at the rim, 1 at the crown) and
## `around` (radians round from the front, +Z), and its outward normal there.
static func cap_surface(shell_cap: Dictionary, lift: float, around: float) -> Dictionary:
	var thickness: float = shell_cap["thickness"]
	var inner: Vector2 = shell_cap["inner"]
	var semi := Vector3(inner.x + thickness, float(shell_cap["inner_height"]) + thickness, inner.y + thickness)
	var phi := lift * PI * 0.5
	var local := Vector3(sin(around) * semi.x * cos(phi), sin(phi) * semi.y, cos(around) * semi.z * cos(phi))
	var center: Vector2 = shell_cap["center"]
	var normal := Vector3(local.x / (semi.x * semi.x), local.y / (semi.y * semi.y), local.z / (semi.z * semi.z)).normalized()
	return {"point": Vector3(center.x, float(shell_cap["rim"]), center.y) + local, "normal": normal}


## The cap as one closed, lathed shell: down the inside from the crown, round
## the rolled lip at the rim, and back up the outside to the crown.
static func build_cap_mesh(shell_cap: Dictionary) -> ArrayMesh:
	var inner: Vector2 = shell_cap["inner"]
	var thickness: float = shell_cap["thickness"]
	var inner_height: float = shell_cap["inner_height"]
	var rim: float = shell_cap["rim"]
	var center: Vector2 = shell_cap["center"]
	var outer := inner + Vector2(thickness, thickness)
	# Each profile entry: half-widths (x across, y front to back) and height.
	var profile: Array = []
	for index in 11:
		var phi := PI * 0.5 * (1.0 - float(index) / 10.0)
		profile.append([inner * cos(phi), rim + sin(phi) * inner_height])
	for index in range(1, 10):
		var s := PI * float(index) / 10.0
		profile.append([inner.lerp(outer, (1.0 - cos(s)) * 0.5), rim - sin(s) * thickness * 0.5])
	for index in 15:
		var phi := PI * 0.5 * float(index) / 14.0
		profile.append([outer * cos(phi), rim + sin(phi) * (inner_height + thickness)])
	var rings: Array = []
	for entry in profile:
		var widths: Vector2 = entry[0]
		var height: float = entry[1]
		var ring: Array[Vector3] = []
		for segment in CAP_SEGMENTS:
			var angle := TAU * float(segment) / float(CAP_SEGMENTS)
			ring.append(Vector3(center.x + cos(angle) * widths.x, height, center.y + sin(angle) * widths.y))
		rings.append(ring)
	return BlorbBodyShape.build_mesh_from_rings(rings)


## The spiral for a head whose bounds are `contents`, starting on `shell_cap`.
## Angles run in the Y-Z plane from +Z (forward) toward +Y (up).
static func spiral(contents: AABB, shell_cap: Dictionary) -> Dictionary:
	var center := contents.get_center()
	var half := contents.size * 0.5
	var coil := center + Vector3(0.0, COIL_UP * half.y, -half.z * (1.0 + COIL_BEHIND))
	var cap_top := float(shell_cap["rim"]) + float(shell_cap["inner_height"]) + float(shell_cap["thickness"])
	var start := Vector3(0.0, cap_top, center.z + half.z * START_FORWARD)
	var start_angle := atan2(start.y - coil.y, start.z - coil.z)
	var start_radius := Vector2(start.z - coil.z, start.y - coil.y).length()
	var winding := minf(log(start_radius / CLOSING_RADIUS) / DECAY, TAU * MAX_TURNS)
	return {
		"coil": coil, "start_angle": start_angle, "start_radius": start_radius,
		"end_angle": start_angle + winding,
		"start_width": half.x * START_WIDTH, "back_width": half.x * BACK_WIDTH,
	}


static func _radius_at(shape: Dictionary, angle: float) -> float:
	return float(shape["start_radius"]) * exp(-DECAY * (angle - float(shape["start_angle"])))


static func point_at(shape: Dictionary, angle: float) -> Vector3:
	return (shape["coil"] as Vector3) + Vector3(0.0, sin(angle), cos(angle)) * _radius_at(shape, angle)


static func width_at(shape: Dictionary, angle: float) -> float:
	var taper := smoothstep(float(shape["start_angle"]), PI, angle)
	return lerpf(float(shape["start_width"]), float(shape["back_width"]), taper)


## Half the shell's thickness across the curl at `angle`. A whorl at radius r
## and the next one in, at r * q (q = exp(-DECAY * TAU)), meet when
## r - h(r) = r*q + h(r*q), giving h = r * (1 - q) / (1 + q); WHORL_OVERLAP
## thickens that so the turns overlap into one mass.
static func thickness_at(shape: Dictionary, angle: float) -> float:
	var shrink := exp(-DECAY * TAU)
	return maxf(_radius_at(shape, angle) * (1.0 - shrink) / (1.0 + shrink) * WHORL_OVERLAP, CENTRE_THICKNESS)


static func build_shell_mesh(shape: Dictionary) -> ArrayMesh:
	var rings: Array = []
	var start_angle := float(shape["start_angle"])
	var end_angle := float(shape["end_angle"])
	for sample in SAMPLES + 1:
		var angle := lerpf(start_angle, end_angle, float(sample) / float(SAMPLES))
		var center := point_at(shape, angle)
		var tangent := (point_at(shape, angle + 0.01) - point_at(shape, angle - 0.01)).normalized()
		var side := Vector3.RIGHT
		# Same frame orientation as BlorbSuit.build_limb_tube(): side x up = tangent.
		var up := tangent.cross(side)
		var width := width_at(shape, angle)
		var thickness := thickness_at(shape, angle)
		# Where it grows out of the cap the shell swells in from nothing,
		# rounding into the cap rather than starting as a flat cut.
		var emerge := sin(clampf(float(sample) / 8.0, 0.0, 1.0) * PI * 0.5)
		var ring: Array[Vector3] = []
		for segment in SEGMENTS:
			var around := TAU * float(segment) / float(SEGMENTS)
			ring.append(center + side * cos(around) * width * emerge + up * sin(around) * thickness * emerge)
		rings.append(ring)
	return BlorbBodyShape.build_mesh_from_rings(rings)


## Standalone shop/inventory visual: sized off the figure's generic head.
static func build_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "NautilusCrown"
	var head_size := ProceduralFigure.HEAD_SIZE * item_scale
	var contents := AABB(Vector3(-head_size.x, 0.0, -head_size.z), head_size * 2.0)
	var shell_cap := cap(contents)
	var material := StandardMaterial3D.new()
	material.albedo_color = SHELL_COLOR
	material.roughness = 0.35
	for mesh in [build_cap_mesh(shell_cap), build_shell_mesh(spiral(contents, shell_cap))]:
		var part := MeshInstance3D.new()
		part.mesh = mesh
		part.material_override = material
		root.add_child(part)
	return root
