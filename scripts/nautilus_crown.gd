class_name NautilusCrown
extends RefCounted

## The Nautilus Crown's shape, shared by the living helm a blorb becomes after
## binding it (BlorbSuit._build_nautilus_crown()) and the loose item. A shell
## helmet that starts just above the eyes, sweeps up over the crown and back,
## and coils into a nautilus spiral that sits against the back of the head.
## One tube following a logarithmic spiral in the head's side-on plane: its
## open end is the broad brow, and it narrows as it winds in. As in a real
## nautilus the whorls are one solid mass: each whorl is exactly as thick as
## the space down to the next one inside it, so they meet with no gaps, and
## the coil winds on until it closes at its centre, which sits on the back
## of the head so the whole back of the skull is covered.
##
## Worn, it gives the same air supply as the Diving Helmet; over two Water
## leg blorbs it commands the mermaid tail (see BlorbSuitController).

const SHELL_COLOR := Color(0.36, 0.88, 0.74)
## Where the brow edge starts (fractions of the head's half-height above its
## centre and half-depth forward of it).
const BROW_HEIGHT := 0.28
const BROW_FORWARD := 0.92
## The spiral's centre: sunk a little inside the back of the head (a
## negative fraction of half-depth beyond the back of the skull) and below
## its middle (fraction of half-height), so the coil's mass spreads over the
## whole back of the skull down to the nape.
const COIL_BEHIND := -0.2
const COIL_UP := -0.2
## Clearance over the crown (fraction of half-height), setting how quickly the
## spiral tightens between the brow and the top of the head.
const CROWN_CLEARANCE := 1.08
## The spiral winds in until its centreline is this close to the centre
## (metres), closing the coil solid, but never more than MAX_TURNS.
const CLOSING_RADIUS := 0.006
const MAX_TURNS := 8.0
const CENTRE_THICKNESS := 0.012
## Shell width at the brow (fraction of the head's half-width) and how slowly
## it narrows as the spiral tightens, so the coil stays broad over the back
## of the head. How much each whorl overlaps the one inside it.
const BROW_WIDTH := 1.15
const WIDTH_FALLOFF := 0.2
const WHORL_OVERLAP := 1.06
const SAMPLES := 220
const SEGMENTS := 20


## The spiral for a head whose bounds are `contents`: the coil centre, the
## start angle and radius at the brow, and the decay rate. Angles run in the
## Y-Z plane from +Z (forward) toward +Y (up).
static func spiral(contents: AABB) -> Dictionary:
	var center := contents.get_center()
	var half_y := contents.size.y * 0.5
	var half_z := contents.size.z * 0.5
	var coil := center + Vector3(0.0, COIL_UP * half_y, -half_z * (1.0 + COIL_BEHIND))
	var brow := center + Vector3(0.0, BROW_HEIGHT * half_y, BROW_FORWARD * half_z)
	var start_angle := atan2(brow.y - coil.y, brow.z - coil.z)
	var start_radius := Vector2(brow.z - coil.z, brow.y - coil.y).length()
	var crown_radius := (center.y + half_y * CROWN_CLEARANCE) - coil.y
	var decay := log(start_radius / maxf(crown_radius, 0.001)) / maxf(PI * 0.5 - start_angle, 0.1)
	var winding := minf(log(start_radius / CLOSING_RADIUS) / maxf(decay, 0.01), TAU * MAX_TURNS)
	return {
		"coil": coil, "start_angle": start_angle, "start_radius": start_radius, "decay": decay,
		"end_angle": start_angle + winding, "brow_width": contents.size.x * 0.5 * BROW_WIDTH,
	}


## The spiral's centreline point and its shell width at `angle`.
static func point_at(shape: Dictionary, angle: float) -> Vector3:
	var radius := float(shape["start_radius"]) * exp(-float(shape["decay"]) * (angle - float(shape["start_angle"])))
	return (shape["coil"] as Vector3) + Vector3(0.0, sin(angle), cos(angle)) * radius


static func width_at(shape: Dictionary, angle: float) -> float:
	var shrink := exp(-float(shape["decay"]) * (angle - float(shape["start_angle"])))
	return maxf(float(shape["brow_width"]) * pow(shrink, WIDTH_FALLOFF), 0.004)


## Half the shell's thickness across the curl at `angle`. A whorl at radius
## r and the next one in, at r * q (q = exp(-decay * TAU), the shrink per
## turn), meet when r - h(r) = r*q + h(r*q); with h proportional to r that
## gives h = r * (1 - q) / (1 + q), so the whorls close into one mass.
static func thickness_at(shape: Dictionary, angle: float) -> float:
	var radius := float(shape["start_radius"]) * exp(-float(shape["decay"]) * (angle - float(shape["start_angle"])))
	var shrink := exp(-float(shape["decay"]) * TAU)
	# The innermost turn keeps a little body so the centre closes solid.
	return maxf(radius * (1.0 - shrink) / (1.0 + shrink) * WHORL_OVERLAP, CENTRE_THICKNESS)


## Outward (away from the coil centre) at `angle`: the shell's outer face.
static func outward_at(shape: Dictionary, angle: float) -> Vector3:
	return Vector3(0.0, sin(angle), cos(angle))


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
		# The brow lip rounds in over the first few samples rather than
		# ending in a flat cut.
		var lip := smoothstep(0.0, 4.0, float(sample))
		var ring: Array[Vector3] = []
		for segment in SEGMENTS:
			var around := TAU * float(segment) / float(SEGMENTS)
			ring.append(center + side * cos(around) * width * lerpf(0.8, 1.0, lip) + up * sin(around) * thickness * lerpf(0.6, 1.0, lip))
		rings.append(ring)
	return BlorbBodyShape.build_mesh_from_rings(rings)


## Standalone shop/inventory visual: sized off the figure's generic head.
static func build_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "NautilusCrown"
	var head_size := ProceduralFigure.HEAD_SIZE * item_scale
	var shape := spiral(AABB(Vector3(-head_size.x, 0.0, -head_size.z), head_size * 2.0))
	var material := StandardMaterial3D.new()
	material.albedo_color = SHELL_COLOR
	material.roughness = 0.35
	var shell := MeshInstance3D.new()
	shell.name = "Shell"
	shell.mesh = build_shell_mesh(shape)
	shell.material_override = material
	root.add_child(shell)
	return root
