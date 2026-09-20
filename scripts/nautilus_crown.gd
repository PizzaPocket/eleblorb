class_name NautilusCrown
extends RefCounted

## A literal nautilus shell fitted around the wearer's head: one logarithmic
## whorl in the head's side-profile plane, thick across the head and packed so
## successive coils touch into a single organic shell mass. There is no added
## hat band, brow bridge, or transition piece. The outer aperture is simply
## inserted over the head, and carries the living blorb face.
## Worn, it gives the same air supply as the Diving Helmet; over two Water
## leg blorbs it commands the mermaid tail (see BlorbSuitController).

const SHELL_COLOR := Color(0.36, 0.88, 0.74)

## The forehead band's initial half-width and depth. It begins generously
## enough to read as a hat band, but is already flatter than the old bulb.
const BASE_WIDTH := 1.25
const BASE_ROUNDNESS := 0.55
const BAND_SAMPLES := 42
const BAND_FRONT_HEIGHT := 0.16
const BAND_FRONT_REACH := 0.88
const BAND_REAR_HEIGHT := -0.12
const BAND_REAR_REACH := 1.28
const BAND_FIRST_HANDLE_BACK := 0.62
const BAND_FIRST_HANDLE_RISE := 0.0
const BAND_END_HANDLE := 0.18
## Seat the whole crown modestly farther back on the skull. Expressed as a
## fraction of the measured head depth so the same fit holds for every
## playable-character head rather than baking in human-sized centimetres.
const SEAT_BACK_FRACTION := 0.18
## The spiral's centre, just behind the head and barely above its middle
## (fractions of the head's half-height and half-depth from its centre), so
## the rise arcs back and down quickly and the spiral's bulk sits low round
## the back of the head.
const COIL_UP := 0.08
const COIL_BACK := 0.56
## How fast the spiral tightens (its radius falls by exp(-DECAY * TAU) each
## turn), how much each whorl overlaps the one inside it, and where it
## closes.
const DECAY := 0.2
const WHORL_OVERLAP := 1.2
const CLOSING_RADIUS := 0.006
const CENTRE_THICKNESS := 0.01
const MAX_TURNS := 8.0
const SPIRAL_SAMPLES := 170
const OUTER_RADIUS_RATIO := 0.78
## Move the coil's centre behind the skull while growing its outer radius by
## the same amount.  That preserves the already-approved forehead reach, but
## gives the shell room to rise over the crown and display behind the head.
const REAR_EXTENSION_FRACTION := 0.38
const VERTICAL_STRETCH := 1.16
## The band loses both width and depth almost immediately. The roll remains a
## broad, flat ribbon rather than regaining the old swollen rear mass.
const BACK_WIDTH := 0.58
const INNER_WIDTH := 0.42
const WIDTH_TAPER_REACH := 0.34
const THICKNESS_FLATTEN_REACH := 0.20
const ROLL_FLATNESS := 0.26
## The rounded nose: over this much of the base's width the tube swells from
## a point to full size.
const NOSE_LENGTH := 0.32
const EYE_CAP_ROUNDING := 0.47
const BASE_SHOULDER_MIN := 0.78
const BASE_SHOULDER_SAMPLES := 6.0
const SEGMENTS := 22


## The whole curve for a head whose bounds are `contents`: per sample, the
## centreline point, the half-width across the head and the half-thickness
## across the curl.
static func shape(contents: AABB) -> Dictionary:
	var head_center := contents.get_center()
	var half := contents.size * 0.5
	var old_center_z := head_center.z - half.z * 0.18
	var base_width := half.x * BASE_WIDTH
	var points: Array[Vector3] = []
	var widths: Array[float] = []
	var thicknesses: Array[float] = []
	var shrink := exp(-DECAY * TAU)
	var old_start_radius := half.y * OUTER_RADIUS_RATIO
	var rear_extension := half.z * REAR_EXTENSION_FRACTION
	var start_radius := old_start_radius + rear_extension
	# Keep the actual forward skin surface fixed, not merely the centreline.
	# The larger outer radius also makes its packed tube deeper, while the
	# rounded shoulder below makes its first ring smaller; compensate for both
	# here so polishing the crown never creeps it farther over the face.
	var old_front_depth := old_start_radius * (1.0 - shrink) / (1.0 + shrink) * WHORL_OVERLAP
	var new_front_depth := start_radius * (1.0 - shrink) / (1.0 + shrink) * WHORL_OVERLAP * BASE_SHOULDER_MIN
	var center := head_center + Vector3(
		0.0,
		0.0,
		old_center_z - rear_extension - (new_front_depth - old_front_depth) - head_center.z
	)
	var winding := minf(log(start_radius / CLOSING_RADIUS) / DECAY, TAU * MAX_TURNS)
	for index in SPIRAL_SAMPLES + 1:
		var spiral_t := float(index) / float(SPIRAL_SAMPLES)
		var angle := winding * spiral_t
		var radius := start_radius * exp(-DECAY * angle)
		points.append(center + Vector3(0.0, sin(angle) * VERTICAL_STRETCH, cos(angle)) * radius)
		var width := lerpf(base_width, half.x * 0.24, smoothstep(0.0, 1.0, spiral_t))
		var packed := maxf(radius * (1.0 - shrink) / (1.0 + shrink) * WHORL_OVERLAP, CENTRE_THICKNESS)
		widths.append(width)
		thicknesses.append(packed)
	return {"points": points, "widths": widths, "thicknesses": thicknesses, "head_center": head_center, "base_width": base_width, "outer_radius": start_radius}


static func _cubic_bezier(a: Vector3, b: Vector3, c: Vector3, d: Vector3, t: float) -> Vector3:
	var u := 1.0 - t
	return a * u * u * u + b * 3.0 * u * u * t + c * 3.0 * u * t * t + d * t * t * t


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
	# A short, integral shoulder rounds the otherwise ruler-flat open edge.
	# It is a scale change within this same swept shell, not an added band or
	# decorative piece, and reaches the undisturbed spiral almost immediately.
	var shoulder_t := smoothstep(0.0, BASE_SHOULDER_SAMPLES, float(index))
	var shoulder := lerpf(BASE_SHOULDER_MIN, 1.0, shoulder_t)
	return Vector2(float(curve["widths"][index]), float(curve["thicknesses"][index])) * shoulder


## The nose-cap station whose cross-section has opened far enough that its
## true swept-surface normal splays each eye by the standard Blorb amount.
## Selected by geometry, not a brittle hard-coded ring number.
static func front_eye_sample(curve: Dictionary) -> int:
	var points: Array[Vector3] = curve["points"]
	var nose := float(curve["base_width"]) * NOSE_LENGTH
	var along := 0.0
	var best_index := 1
	var best_error := INF
	for index in range(1, mini(BAND_SAMPLES, points.size())):
		along += points[index - 1].distance_to(points[index])
		var rounding := sqrt(maxf(0.0, 1.0 - pow(1.0 - clampf(along / nose, 0.0, 1.0), 2.0)))
		var error := absf(rounding - EYE_CAP_ROUNDING)
		if error < best_error:
			best_error = error
			best_index = index
	return best_index


static func _surface_point(curve: Dictionary, index: int, around: float) -> Vector3:
	var axes := frame(curve, index)
	var size := size_at(curve, index)
	var center: Vector3 = (curve["points"] as Array[Vector3])[index]
	return center + (axes["side"] as Vector3) * cos(around) * size.x + (axes["up"] as Vector3) * sin(around) * size.y


## A point on the tube's surface at sample `index`, `around` radians round
## its cross-section (0 across to +X, PI/2 along "up"), and the outward
## normal there.
static func surface(curve: Dictionary, index: int, around: float) -> Dictionary:
	var points: Array[Vector3] = curve["points"]
	var point := _surface_point(curve, index, around)
	# Differentiate the actual swept surface in both directions. Unlike the
	# former ring-only normal, this includes the nose cap's changing radius,
	# which is essential for eyes fitted to its forward-facing surface.
	var before := _surface_point(curve, maxi(index - 1, 0), around)
	var after := _surface_point(curve, mini(index + 1, points.size() - 1), around)
	const AROUND_STEP := 0.025
	var around_before := _surface_point(curve, index, around - AROUND_STEP)
	var around_after := _surface_point(curve, index, around + AROUND_STEP)
	var normal := (around_after - around_before).cross(after - before).normalized()
	var away := point - (curve["head_center"] as Vector3)
	if normal.dot(away) < 0.0:
		normal = -normal
	return {"point": point, "normal": normal}


## Angle round this particular swept ring at the foremost point of the actual
## mesh. Selecting purely by normal direction can choose an upper shoulder of
## a strongly curving sweep whose differential happens to face forward; the
## visible result is an eye stalk on the crown. The maximum forward surface
## position is the stable semantic landmark the face actually needs.
static func front_surface_around(curve: Dictionary, index: int) -> float:
	const SAMPLE_COUNT := 64
	var best_around := 0.0
	var best_forward := -INF
	for sample in SAMPLE_COUNT:
		var around := TAU * float(sample) / float(SAMPLE_COUNT)
		var spot := surface(curve, index, around)
		var forward := (spot["point"] as Vector3).z
		if forward > best_forward:
			best_forward = forward
			best_around = around
	return best_around


## Where the blorb's two eyes sit on the crown's front band.
##
## Taken from the tube's OWN surface (surface(), the same function that
## generates the mesh rings), not from an analytic cap that approximates it:
## an approximation left them floating a centimetre clear of the shell on a
## head only 28 cm deep. Read this way they are flush by construction, and
## the normal that comes back with the point is the direction they face, so
## they cannot be mis-angled either.
##
## EYE_SAMPLE picks how far along the band they sit, which is how high on the
## brow they read; EYE_SPREAD is how far either side of the band's crest they
## sit, in radians round the tube's cross-section.
const EYE_SAMPLE := 5
const EYE_SPREAD := 0.62


static func front_eye_surface(curve: Dictionary, side_sign: float) -> Dictionary:
	var around := outward_around(curve, EYE_SAMPLE) + side_sign * EYE_SPREAD
	return surface(curve, EYE_SAMPLE, around)


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
