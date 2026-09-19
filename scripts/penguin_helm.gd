class_name PenguinHelm
extends RefCounted

## Shared geometry for the loose Penguin Helm and the living form an Ice blorb
## takes after binding it (BlorbSuit._build_penguin_helm()). A smooth rounded
## hood, a little rounder than the head's own soft-cube SuperEgg, closing over
## the crown and down past the jaw, with a slender beak pointing forward from
## just below the eyes.
##
## Worn by an Ice head over a full Ice suit it commands the Penguin Suit (see
## BlorbSuit.FORM_HELMS), just as the Lava Helm commands the sealed Lava Suit.

const HOOD_COLOR := Color(0.10, 0.12, 0.17)
const BEAK_COLOR := Color(0.96, 0.56, 0.12)
## Between a plain ellipsoid (2) and the head's EPSILON_SOFT (3): smooth like
## a penguin's head rather than boxy.
const HOOD_EPSILON := 2.4
## Hood size relative to the measured head-and-hair bounds.
const HOOD_MARGIN := Vector3(1.10, 1.10, 1.12)
## How far below the head's own centre the hood's centre sits, as a fraction
## of its vertical semi-axis, so it reaches down past the jaw.
const HOOD_DROP := 0.08
## Beak root below the eye line (latitude, radians), length and root radius
## (as fractions of the hood's front-to-back semi-axis), and droop.
const BEAK_BELOW_EYES := 0.24
const BEAK_LENGTH := 0.72
const BEAK_ROOT_RADIUS := 0.2
const BEAK_DROOP := 0.12
## Narrower side to side than top to bottom, like a real penguin's bill.
const BEAK_FLATTEN := 0.78


static func hood_semi_axes(contents_size: Vector3) -> Vector3:
	return contents_size * 0.5 * HOOD_MARGIN


## Latitude on the hood whose surface sits `local_y` above the hood's centre
## (inverts SuperEgg.surface_point()'s y = b * sin(eta)^(2/epsilon)).
static func eta_for_local_y(local_y: float, semi_axis_y: float) -> float:
	var ratio := clampf(local_y / semi_axis_y, -0.98, 0.98)
	return asin(signf(ratio) * pow(absf(ratio), HOOD_EPSILON * 0.5))


## The beak in hood-local space: rooted a little inside the hood's front,
## tapering to a point ahead of it and drooping slightly.
static func build_beak_mesh(semi_axes: Vector3, eye_eta: float) -> ArrayMesh:
	var root_surface := SuperEgg.surface_point(semi_axes, eye_eta - BEAK_BELOW_EYES, 0.0, HOOD_EPSILON, HOOD_EPSILON)
	var length := semi_axes.z * BEAK_LENGTH
	var radius := semi_axes.z * BEAK_ROOT_RADIUS
	var inside := root_surface - Vector3(0.0, 0.0, radius * 1.4)
	var middle := root_surface + Vector3(0.0, -length * BEAK_DROOP * 0.3, length * 0.5)
	var tip := root_surface + Vector3(0.0, -length * BEAK_DROOP, length)
	var points: Array[Vector3] = [inside, root_surface, middle, tip]
	var radii: Array[float] = [radius, radius, radius * 0.55, radius * 0.12]
	return BlorbSuit.build_limb_tube(
		points, radii, 12, 5, 0.12, [] as Array[Color], true, Vector3.RIGHT, BEAK_FLATTEN
	)


## Standalone shop/inventory/throwable visual: no real head to fit, so it is
## sized off the figure's generic head (as the Lava Helm's icon is).
static func build_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "PenguinHelm"
	var semi_axes := hood_semi_axes(ProceduralFigure.HEAD_SIZE * 2.0 * item_scale)
	var hood_material := StandardMaterial3D.new()
	hood_material.albedo_color = HOOD_COLOR
	hood_material.roughness = 0.42
	var hood := MeshInstance3D.new()
	hood.name = "Hood"
	hood.mesh = SuperEgg.build_mesh(semi_axes, HOOD_EPSILON, HOOD_EPSILON)
	hood.material_override = hood_material
	hood.position.y = semi_axes.y
	root.add_child(hood)
	var beak_material := StandardMaterial3D.new()
	beak_material.albedo_color = BEAK_COLOR
	beak_material.roughness = 0.5
	var beak := MeshInstance3D.new()
	beak.name = "Beak"
	beak.mesh = build_beak_mesh(semi_axes, 0.15)
	beak.material_override = beak_material
	hood.add_child(beak)
	return root
