class_name BirdHelm
extends RefCounted

## Shared geometry for Blorbaka's own core-bound helm. The upper half of a
## SuperEgg superellipsoid -- the same rounded-shape family the head itself
## is built from, not an idealized mathematical sphere -- sized per-axis
## off the wearer's actual measured head+hair bounds so it naturally
## matches that shape, just offset a bit larger (see build_dome_rings()'s
## own comment). Its open rim ("the cut") isn't flat either: viewed from
## the side, it dips in a bell curve, lowest at the back, shallower at the
## front, with its own apex over the ears raised above the plain rim
## height so it clears them -- see _rim_offset()'s own comment for the
## complete, single source of truth for that shaping, shared by both the
## mesh builder and the eye/beak/ear surface samplers below (an earlier
## version computed those two independently and let them drift out of
## sync, which sank the eyes beneath the actual dipped surface). Its own
## eyes sit at exactly the same height as the real head's own eyes
## (FigureEyes.add_eyes() places those at the head mesh's own equator,
## eta=0 -- see that file's own comment) but are placed with custom code
## in blorb_suit.gd rather than through BlorbFace.add_eyes(): that helper
## assumes a locally circular cross-section (same radius left/right of
## dead-front), which doesn't hold here since this dome's own X and Z
## semi-axes differ and the horizontal pull-in/extend above varies by
## angle too -- using it anyway was why the eyes weren't actually sitting
## on the surface. A hooked hawk beak projects from the nose area just
## below the eye line, and two wing
## decorations stand vertically (perpendicular to the ground) at the
## sides, swept back along the helmet. No crest.
##
## First-pass design -- per direct instruction this is being prototyped
## live (Blorbus wears it in the debug startup loadout, see
## crossroads_test_setup.gd) specifically so the shape can be tuned by eye.

const DOME_RING_COUNT := 18
const DOME_RADIAL_SEGMENTS := 26
## Per direct correction ("less rounding on top", then "too boxy, split
## the difference", then "still too boxy, more rounded") -- landed between
## the head's own soft HEAD_EPSILON_TOP (2.5) and a flatter crown. A higher
## epsilon in SuperEgg's own superellipse exponent bows the profile out
## toward a more squared-off crown instead of a fully round bulb (see
## superegg.gd's own class doc for the general epsilon behavior).
const DOME_EPSILON := 2.85
## How much the open rim dips down at the back relative to the dome's own
## vertical size -- see _rim_offset()'s own comment.
const RIM_BELL_DEPTH_RATIO := 0.32
## The front dip stays but ends higher than the back's own -- the back
## keeps the full RIM_BELL_DEPTH_RATIO dip, the front only gets this
## fraction of it.
const RIM_BELL_FRONT_RATIO := 0.35
## The bell's own apex (the sides, where the dip is zero) is lifted above
## the plain rim height too, rather than just sitting at it -- enough to
## clear the tops of the ears.
const RIM_BELL_APEX_RAISE_RATIO := 0.22
## Per direct correction, a further real-world nudge on top of the bell
## shaping above: the front edge specifically comes down (0.5cm, then
## another 0.5cm = 1cm total), the whole horizontal footprint pulls in at
## the front and sides, and each side additionally pulls in half a
## centimeter more on top of that shared pull-in. These are fixed physical
## amounts (not scaled by head size) since they were given in real-world
## units.
const FRONT_EDGE_EXTRA_LOWER := 0.01
const HORIZONTAL_PULL_IN := 0.01
## 0.5cm, then another 0.5cm per direct correction = 1cm total.
const SIDE_EXTRA_PULL_IN := 0.01
## Per direct correction: earlier attempts to "extend the back" scaled
## with `fade`, which only pushed the RIM (bottom lip) backward while
## leaving the crown where it was -- the back ended up sloping backward
## from top to bottom instead of moving as one piece, and never actually
## cleared hair sitting near the back of the CROWN, which is what was
## really clipping. This is applied WITHOUT `fade` in _rim_offset() below
## (see that function's own comment), so the back wall shifts back by the
## same amount at every height, straight down from crown to rim.
const BACK_EXTEND := 0.015
## How far below the dome's own open rim (eta=0) the front-surface samples
## below are measured, expressed as the actual world/head_pivot Y each one
## targets -- computed relative to head_size.y (the real head's own eye
## height, see this file's own class doc) rather than a fixed profile
## fraction, since the dome's own enclosure size varies per wearer.
const NOSE_Y_FRACTION := 0.85
const EAR_Y_FRACTION := 0.92


## The single source of truth for how the rim/surface departs from a plain
## SuperEgg at a given `omega` (see SuperEgg's own "0 = local +Z" longitude
## convention) and `fade` (1.0 at the open rim, 0.0 at the crown) -- both
## build_dome_rings() and the eye/beak/ear surface samplers below call this
## so they can never disagree about where the actual surface sits.
##
## Vertical: cos(omega)^2 ("bell") peaks at dead-front/dead-back and is
## zero at the sides. A side view looks straight down the X axis, so front
## and back land at opposite ends of what's visible and the two sides
## collapse to the same middle point -- this is what actually traces a
## front-low, middle-high, back-low bell shape in that view. At bell=0
## (the sides) the surface is lifted by RIM_BELL_APEX_RAISE_RATIO to clear
## the ears; at bell=1 it dips by `dip`, whose own depth is further scaled
## down at the front (front_to_back=0) versus the back (front_to_back=1)
## per RIM_BELL_FRONT_RATIO. FRONT_EDGE_EXTRA_LOWER then nudges the front
## specifically a bit lower still, as an absolute (not size-relative) amount.
##
## Horizontal: pulls the front and sides in by HORIZONTAL_PULL_IN
## (+ SIDE_EXTRA_PULL_IN at the sides specifically), fading out toward the
## crown same as the vertical shaping above -- a natural taper there is
## fine. The back's own BACK_EXTEND is deliberately NOT scaled by `fade`:
## it shifts the surface back by the same amount through almost the whole
## height, so the back reads as one flat wall moved backward rather than
## sloping (see BACK_EXTEND's own comment for why that distinction
## matters) -- EXCEPT it still must converge to exactly zero at the true
## pole (v=1), via `wall_fade`, or every point in that ring stops
## collapsing to the same coordinate and the crown's own cap triangulates
## into a visible seam (this is exactly what reintroduced a crown dent
## after BACK_EXTEND was first made height-independent). wall_fade only
## drops from 1 in the last ~1.5% of the climb -- invisible to the eye,
## but enough to keep the pole a genuine single point.
static func _rim_offset(omega: float, fade: float, v: float, semi_axes_y: float) -> Dictionary:
	var rim_dip := semi_axes_y * RIM_BELL_DEPTH_RATIO
	var apex_raise := semi_axes_y * RIM_BELL_APEX_RAISE_RATIO
	var raw := cos(omega)
	var bell := raw * raw
	var front_to_back := (1.0 - raw) * 0.5
	var depth_scale := lerpf(RIM_BELL_FRONT_RATIO, 1.0, front_to_back)
	var dip := rim_dip * depth_scale
	var front_bump := clampf(raw, 0.0, 1.0)
	var vertical := lerpf(apex_raise, -dip, bell) * fade - FRONT_EDGE_EXTRA_LOWER * front_bump * fade
	var back_bump := clampf(-raw, 0.0, 1.0)
	var side_bump := 1.0 - bell
	var fading_horizontal := (
		-HORIZONTAL_PULL_IN * (1.0 - back_bump) - SIDE_EXTRA_PULL_IN * side_bump
	) * fade
	var wall_fade := 1.0 - smoothstep(0.985, 1.0, v)
	var horizontal := fading_horizontal + BACK_EXTEND * back_bump * wall_fade
	return {"vertical": vertical, "horizontal": horizontal}


## Quadratic rather than linear falloff -- per direct correction (a visible
## indent right at the crown's own center), a linear (1-v) fade still left
## a small but nonzero residual of the omega-dependent rim shaping bleeding
## into the rings closest to the pole; since every point in the true pole
## ring collapses to the exact same coordinate regardless of that
## residual, an uneven near-pole ring meeting a perfectly flat pole point
## triangulates into a visible pinch/dimple, worse the flatter (boxier)
## the crown is. Squaring the falloff makes that residual negligible well
## before reaching the pole instead of only exactly at it.
static func _fade_at(v: float) -> float:
	return pow(clampf(1.0 - v, 0.0, 1.0), 2.0)


## The upper half (eta 0..PI/2) of a SuperEgg superellipsoid -- see this
## file's own class doc for why this replaced an idealized sphere/dome.
## `semi_axes` is independent per axis (X/Z horizontal spread, Y vertical
## rise from the rim to the crown), so it can match a non-spherical head
## and clear tall hair without needing to widen the sides to match.
##
## Per SuperEgg.surface_point()'s own point order matching SuperEgg.
## build_mesh()'s (not BlorbBodyShape's) winding, omega is walked in the
## opposite direction from a plain increasing loop -- see
## BlorbBodyShape.build_mesh_from_rings()'s own comment ("these rings
## advance in the opposite parametric direction from SuperEgg's sin/cos
## rings"); without the negation these rings feed it inverted normals.
static func build_dome_rings(semi_axes: Vector3, epsilon: float) -> Array:
	var rings: Array = []
	for ring_i in DOME_RING_COUNT + 1:
		var v := float(ring_i) / DOME_RING_COUNT
		var eta := v * PI * 0.5
		var fade := _fade_at(v)
		var points: Array[Vector3] = []
		for seg in DOME_RADIAL_SEGMENTS:
			var omega := -(float(seg) / DOME_RADIAL_SEGMENTS) * TAU
			var point := SuperEgg.surface_point(semi_axes, eta, omega, epsilon, epsilon)
			var adj := _rim_offset(omega, fade, v, semi_axes.y)
			point.y += adj["vertical"] as float
			var horizontal: float = adj["horizontal"]
			var planar := Vector2(point.x, point.z)
			var planar_len := planar.length()
			if planar_len > 0.0001:
				var shifted := planar + planar.normalized() * horizontal
				point.x = shifted.x
				point.z = shifted.y
			points.append(point)
		rings.append(points)
	return rings


## Inverts build_dome_rings()'s own undisturbed y(eta) =
## semi_axes.y * sin(eta)^(2/epsilon) so a caller can ask "what eta gives
## me this actual local height" -- used to land the eyes/beak at specific
## real head-relative heights. The small _rim_offset() adjustment on top of
## that is applied afterward by front_surface()/side_surface() themselves,
## not inverted here.
static func eta_for_local_y(local_y: float, semi_axes_y: float, epsilon: float) -> float:
	var ratio := clampf(local_y / maxf(semi_axes_y, 0.0001), 0.0, 1.0)
	var sin_eta := pow(ratio, epsilon * 0.5)
	return asin(clampf(sin_eta, 0.0, 1.0))


## The dome's own actual surface at ANY (eta, omega), including the same
## _rim_offset() adjustment build_dome_rings() bakes into the real mesh --
## the general form front_surface()/side_surface()/the eyes below all
## build on, so nothing sampling this dome's surface can drift out of sync
## with the real mesh (an earlier version skipped the adjustment for the
## front specifically, which placed the eyes at the UNDIPPED surface
## height while the actual mesh had already dipped down there, sinking
## them out of view).
static func surface_point(eta: float, omega: float, semi_axes: Vector3, epsilon: float) -> Vector3:
	var point := SuperEgg.surface_point(semi_axes, eta, omega, epsilon, epsilon)
	var v := eta / (PI * 0.5)
	var fade := _fade_at(v)
	var adj := _rim_offset(omega, fade, v, semi_axes.y)
	point.y += adj["vertical"] as float
	var horizontal: float = adj["horizontal"]
	var planar := Vector2(point.x, point.z)
	var planar_len := planar.length()
	if planar_len > 0.0001:
		var shifted := planar + planar.normalized() * horizontal
		point.x = shifted.x
		point.z = shifted.y
	return point


## The dome's own actual front surface (omega=0, dead-front -- the same
## convention every figure/blorb rig in this project already uses) at a
## given eta. Also returns the derivative FigureEyes/BlorbFace's eye
## placement needs to sink eyes into the surface instead of floating on it
## -- see this function's own note on why the eyes now use their own
## custom placement instead, though (surface_point() below).
static func front_surface(eta: float, semi_axes: Vector3, epsilon: float) -> Dictionary:
	const DELTA := 0.004
	var this_point := surface_point(eta, 0.0, semi_axes, epsilon)
	var before := surface_point(maxf(eta - DELTA, 0.0), 0.0, semi_axes, epsilon)
	var after := surface_point(minf(eta + DELTA, PI * 0.5), 0.0, semi_axes, epsilon)
	var dr_dy := (after.z - before.z) / maxf(after.y - before.y, 0.0001)
	return {"y": this_point.y, "radius": this_point.z, "dr_dy": dr_dy}


## The dome's own actual side surface (omega=PI/2) at a given eta, for the
## wing decorations' own attachment point.
static func side_surface(eta: float, semi_axes: Vector3, epsilon: float) -> Vector3:
	return surface_point(eta, PI * 0.5, semi_axes, epsilon)


## How far below `base` the tip (p3) sits, as a fraction of `radius` --
## exposed so a caller (blorb_suit.gd) can compute exactly how much extra
## drop a larger `radius` will introduce and raise `base` to compensate,
## keeping the tip's own absolute position fixed while the beak grows.
const TIP_DROP_RATIO := 0.36


## A hooked hawk beak, not a simple cone: a cubic-Bezier hook that travels
## forward first, then curves increasingly downward and pulls back toward
## the face at the tip -- the same silhouette a real hawk's beak reads as
## from the side. Laterally compressed (thin side-to-side, taller
## top-to-bottom) rather than round, and genuinely comes to a point.
static func build_beak_rings(base: Vector3, radius: float) -> Array:
	# p3 doesn't pull back nearly as far behind p2 -- an earlier, larger
	# pullback read as an overly extreme hook curling back around toward
	# the face. It still dips down and in a little (a real hook, not a
	# straight cone), just far more subtly.
	var p0 := base
	var p1 := base + Vector3(0.0, -radius * 0.06, radius * 0.46)
	var p2 := base + Vector3(0.0, -radius * 0.20, radius * 0.68)
	var p3 := base + Vector3(0.0, -radius * TIP_DROP_RATIO, radius * 0.56)
	const SEGMENTS := 16
	const RADIAL := 10
	var rings: Array = []
	for i in SEGMENTS + 1:
		var s := float(i) / float(SEGMENTS)
		var center := _bezier(p0, p1, p2, p3, s)
		var ahead := _bezier(p0, p1, p2, p3, minf(s + 0.02, 1.0))
		var behind := _bezier(p0, p1, p2, p3, maxf(s - 0.02, 0.0))
		var tangent := (ahead - behind).normalized()
		var right := Vector3.RIGHT
		var up := right.cross(tangent).normalized()
		# Tapers smoothly across the whole length down to a genuine point
		# at the tip (no thickness floor added on).
		var taper := 1.0 - smoothstep(0.0, 1.0, s)
		var half_width := radius * 0.19 * taper
		var half_height := radius * 0.27 * taper
		var ring: Array[Vector3] = []
		for seg in RADIAL:
			var angle := TAU * float(seg) / float(RADIAL)
			# Negated sin term to match BlorbBodyShape.build_mesh_from_rings()'s
			# own expected winding for a right/up tangent-basis ring -- see
			# blorb_suit.gd's _build_lava_helm_rings()'s identical fix/comment.
			# Without this the beak's normals face inward instead of outward.
			ring.append(center + right * cos(angle) * half_width - up * sin(angle) * half_height)
		rings.append(ring)
	return rings


static func _bezier(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, s: float) -> Vector3:
	var inv := 1.0 - s
	return (
		p0 * (inv * inv * inv)
		+ p1 * (3.0 * inv * inv * s)
		+ p2 * (3.0 * inv * s * s)
		+ p3 * (s * s * s)
	)
