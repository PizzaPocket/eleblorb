class_name PenguinHelm
extends RefCounted

## Shared geometry for the loose Penguin Helm and the living form an Ice blorb
## takes after binding it (BlorbSuit._build_penguin_helm()). A hood with a
## round dome over the crown, widening down past the jaw to a flared base, with
## a slender beak pointing forward from just below the eyes.
##
## Worn by an Ice head over a full Ice suit it can command the Penguin Suit
## (see BlorbSuit.FORM_HELMS). Until the suit is formed the blorb wears it
## raised: its ordinary hat with a rounded crown and the beak tipped up where
## a nose would be. Forming the suit brings the hood down over the face.

## Tilt of the raised beak above level.
const RAISED_BEAK_TILT := deg_to_rad(14.0)

const HOOD_COLOR := Color(0.10, 0.12, 0.17)
const BEAK_COLOR := Color(0.96, 0.56, 0.12)
## The hood is a lathed bell rather than a ball: a round dome over the crown
## that widens smoothly down past the jaw into a flared base, which sinks into
## the Penguin Suit's torso like a penguin's head running into its body.
## Half-widths relative to the measured head-and-hair bounds.
const HOOD_MARGIN := Vector2(1.10, 1.12)
## Width at the base relative to the head, the height (fraction from the
## base) where the flare has eased in to head width, and how far below the
## head's base the hood reaches, as a fraction of the head's height.
const HOOD_BASE_FLARE := 1.3
const HOOD_WAIST_T := 0.5
const HOOD_BASE_DROP := 0.45
## Clearance over the top of the head, as a fraction of the head's height.
const HOOD_TOP_MARGIN := 0.06
const HOOD_RINGS := 26
const HOOD_SEGMENTS := 28
## Beak root below the eye line (fraction of head height), length and root
## radius (fractions of the hood's front-to-back half-width), and droop. A
## fat root and short length give the cone a blunt, wide-based angle.
const BEAK_BELOW_EYES := 0.2
const BEAK_LENGTH := 0.62
const BEAK_ROOT_RADIUS := 0.3
const BEAK_DROOP := 0.12
## Narrower side to side than top to bottom, like a real penguin's bill.
const BEAK_FLATTEN := 0.78


## Half-widths (x across, y front to back) fitting head bounds of `contents_size`.
static func hood_half_widths(contents_size: Vector3) -> Vector2:
	return Vector2(contents_size.x * 0.5 * HOOD_MARGIN.x, contents_size.z * 0.5 * HOOD_MARGIN.y)


## Width relative to the head at height fraction `t` (0 base, 1 crown): the
## flare easing in to head width at HOOD_WAIST_T, then a round dome.
static func hood_width(t: float) -> float:
	if t <= HOOD_WAIST_T:
		return lerpf(HOOD_BASE_FLARE, 1.0, smoothstep(0.0, 1.0, t / HOOD_WAIST_T))
	var u := (t - HOOD_WAIST_T) / (1.0 - HOOD_WAIST_T)
	return sqrt(maxf(0.0, 1.0 - u * u))


## The hood's vertical extent for a head whose bounds run from `head_bottom`
## to `head_top`: from below the head's base up over the crown.
static func hood_span(head_bottom: float, head_top: float) -> Vector2:
	var head_height := head_top - head_bottom
	return Vector2(head_bottom - head_height * HOOD_BASE_DROP, head_top + head_height * HOOD_TOP_MARGIN)


static func build_hood_mesh(half: Vector2, span: Vector2) -> ArrayMesh:
	var rings: Array = []
	for ring_index in HOOD_RINGS + 1:
		var t := float(ring_index) / float(HOOD_RINGS)
		var width := hood_width(t)
		var y := lerpf(span.x, span.y, t)
		var ring: Array[Vector3] = []
		for segment in HOOD_SEGMENTS:
			var angle := TAU * float(segment) / float(HOOD_SEGMENTS)
			ring.append(Vector3(cos(angle) * half.x * width, y, sin(angle) * half.y * width))
		rings.append(ring)
	return BlorbBodyShape.build_mesh_from_rings(rings)


## The hood's surface at height `y`, `angle` round from the front (+Z).
static func hood_surface_point(half: Vector2, span: Vector2, y: float, angle: float) -> Vector3:
	var width := hood_width(clampf((y - span.x) / (span.y - span.x), 0.0, 1.0))
	return Vector3(sin(angle) * half.x * width, y, cos(angle) * half.y * width)


## The beak in hood space: rooted on the hood's front BEAK_BELOW_EYES under
## `eye_y`, pointing forward and drooping slightly.
static func build_beak_mesh(half: Vector2, span: Vector2, eye_y: float, head_height: float) -> ArrayMesh:
	var root_surface := hood_surface_point(half, span, eye_y - head_height * BEAK_BELOW_EYES, 0.0)
	var direction := Vector3(0.0, -BEAK_DROOP, 1.0).normalized()
	return build_beak_along(root_surface, direction, half.y * BEAK_LENGTH, half.y * BEAK_ROOT_RADIUS)


## A beak whose surface root is `root_surface`, pointing along `direction`:
## sunk a little behind the root and swelling to its widest there, then an
## evenly tapering cone to a point `length` ahead.
static func build_beak_along(root_surface: Vector3, direction: Vector3, length: float, radius: float) -> ArrayMesh:
	var inside := root_surface - direction * radius * 1.2
	var points: Array[Vector3] = [
		inside, root_surface, root_surface + direction * length / 3.0,
		root_surface + direction * length * 2.0 / 3.0, root_surface + direction * length,
	]
	var radii: Array[float] = [radius * 1.05, radius, radius * 0.66, radius * 0.33, radius * 0.06]
	return BlorbSuit.build_limb_tube(
		points, radii, 12, 5, 0.12, [] as Array[Color], true, Vector3.RIGHT, BEAK_FLATTEN
	)


## Standalone shop/inventory/throwable visual: no real head to fit, so it is
## sized off the figure's generic head (as the Lava Helm's icon is).
static func build_visual(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "PenguinHelm"
	var head_size := ProceduralFigure.HEAD_SIZE * 2.0 * item_scale
	var half := hood_half_widths(head_size)
	var span := hood_span(0.0, head_size.y)
	var hood_material := StandardMaterial3D.new()
	hood_material.albedo_color = HOOD_COLOR
	hood_material.roughness = 0.42
	var hood := MeshInstance3D.new()
	hood.name = "Hood"
	hood.mesh = build_hood_mesh(half, span)
	hood.material_override = hood_material
	hood.position.y = -span.x
	root.add_child(hood)
	var beak_material := StandardMaterial3D.new()
	beak_material.albedo_color = BEAK_COLOR
	beak_material.roughness = 0.5
	var beak := MeshInstance3D.new()
	beak.name = "Beak"
	beak.mesh = build_beak_mesh(half, span, head_size.y * 0.5, head_size.y)
	beak.material_override = beak_material
	hood.add_child(beak)
	return root
