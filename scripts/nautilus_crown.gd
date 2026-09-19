class_name NautilusCrown
extends RefCounted

## The Nautilus Crown's shape, shared by the living helm a blorb becomes after
## binding it (BlorbSuit._build_nautilus_crown()) and the loose item. A shell
## helmet that starts just above the eyes, sweeps up over the crown and back,
## and coils into a nautilus spiral that sits against the back of the head.
## One tube following a logarithmic spiral in the head's side-on plane: its
## open end is the broad brow, and it narrows as it winds in.
##
## Worn, it gives the same air supply as the Diving Helmet; over two Water
## leg blorbs it commands the mermaid tail (see BlorbSuitController).

const SHELL_COLOR := Color(0.36, 0.88, 0.74)
## Where the brow edge starts (fractions of the head's half-height above its
## centre and half-depth forward of it).
const BROW_HEIGHT := 0.28
const BROW_FORWARD := 0.92
## The spiral's centre, behind the head (fractions of half-depth beyond the
## back of the head) and slightly up (fraction of half-height).
const COIL_BEHIND := 0.45
const COIL_UP := 0.1
## Clearance over the crown (fraction of half-height), setting how quickly the
## spiral tightens between the brow and the top of the head.
const CROWN_CLEARANCE := 1.08
## How far round the spiral runs past the top of the head (turns).
const COIL_TURNS := 0.95
## Shell width at the brow (fraction of the head's half-width), how quickly
## it narrows as the spiral tightens, and its thickness across the curl.
const BROW_WIDTH := 1.12
const WIDTH_FALLOFF := 0.9
const THICKNESS := 0.45
const SAMPLES := 72
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
	return {
		"coil": coil, "start_angle": start_angle, "start_radius": start_radius, "decay": decay,
		"end_angle": PI * 0.5 + TAU * COIL_TURNS, "brow_width": contents.size.x * 0.5 * BROW_WIDTH,
	}


## The spiral's centreline point and its shell width at `angle`.
static func point_at(shape: Dictionary, angle: float) -> Vector3:
	var radius := float(shape["start_radius"]) * exp(-float(shape["decay"]) * (angle - float(shape["start_angle"])))
	return (shape["coil"] as Vector3) + Vector3(0.0, sin(angle), cos(angle)) * radius


static func width_at(shape: Dictionary, angle: float) -> float:
	var shrink := exp(-float(shape["decay"]) * (angle - float(shape["start_angle"])))
	return maxf(float(shape["brow_width"]) * pow(shrink, WIDTH_FALLOFF), 0.004)


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
		# The brow lip rounds in over the first few samples rather than
		# ending in a flat cut.
		var lip := smoothstep(0.0, 3.0, float(sample))
		var ring: Array[Vector3] = []
		for segment in SEGMENTS:
			var around := TAU * float(segment) / float(SEGMENTS)
			ring.append(center + side * cos(around) * width * lerpf(0.8, 1.0, lip) + up * sin(around) * width * THICKNESS * lerpf(0.7, 1.0, lip))
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
