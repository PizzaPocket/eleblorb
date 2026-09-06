class_name FigureHair
extends RefCounted

## Procedural hairstyles for the superegg head (see procedural_figure.gd).
## Every style shares the technique tuned for the original (and still
## default) BUZZCUT: one or more superegg pieces positioned via FOUR EDGES
## (front/back/top/bottom -- each a signed distance from the head's own
## center along that axis) rather than a center offset + half-extent, since
## tuning requests have consistently come in edge-at-a-time ("bring the
## front forward, leave the back alone"). _center()/_half_extent() convert
## an edge pair back to what SuperEgg.build_mesh() actually needs.
##
## Per direct instruction, every style keeps the SAME front edge (the
## hairline) as the buzzcut -- only the buzzcut's sides/back/top/bottom
## vary per style (_buzzcut_edges() is the shared starting point every
## other style builds from), so switching styles never moves the hairline
## relative to the face.
##
## Styles are picked by a plain String constant (STYLE_*), not a Godot
## enum -- this project doesn't use enums elsewhere (VILLAGER_IDENTITIES,
## SHOP_STALL_POSITIONS etc. are all String-keyed), and a String sidesteps
## any cross-file enum-type-annotation uncertainty for an @export field on
## npc.gd that a real enum would carry.


const STYLE_BUZZCUT := "buzzcut"
const STYLE_AFRO := "afro"
const STYLE_FLAT_TOP := "flat_top"
const STYLE_BUN := "bun"
## Per direct instruction, for the Chinese village's own child NPCs: two
## bun-like clusters positioned on either side of the head rather than
## STYLE_BUN's single back-top one -- see _build_pigtails()'s own comment.
const STYLE_PIGTAILS := "pigtails"
const STYLE_LONG := "long"
## The hero's own style, per direct instruction ("adjust the hero's hair
## into a NEW style") -- distinct from STYLE_BUZZCUT (which NPCs still use)
## rather than tuning the shared buzzcut constants themselves, since those
## are shared with the whole NPC population and this request was scoped
## to the hero specifically.
const STYLE_HERO := "hero"
## No hair mesh at all -- see fish_goblin_nme.gd's own use (a fish-skinned
## humanoid has no hair to begin with). Distinct from passing an
## unrecognized/empty string, which add_hair()'s own match falls back to
## STYLE_BUZZCUT for -- this is a real, explicit "skip hair entirely" case.
const STYLE_BALD := "bald"

const DEFAULT_HAIR_COLOR := Color(0.14, 0.1, 0.08)

## semi_axes.x is not edge-tuned per-side for the buzzcut baseline -- no
## direct instruction has touched hair width there, so it stays a single
## symmetric factor. Other styles widen it directly per their own look.
const WIDTH_FACTOR := 1.1

const FRONT_EDGE_FACTOR := 0.40
const FRONT_EDGE_FLAT := 0.06
const BACK_EDGE_FACTOR := -1.10
const BACK_EDGE_FLAT := -0.01
const TOP_EDGE_FACTOR := 1.2
const TOP_EDGE_FLAT := 0.0
const BOTTOM_EDGE_FACTOR := -0.2
const BOTTOM_EDGE_FLAT := -0.07

## Per direct correction: matching the head's own epsilon 1:1 (an earlier
## pass) still didn't read as round enough once the buzzcut's semi_axes
## were no longer close to spherical. Expressed as a RATIO applied to
## whatever epsilon the caller's head actually uses, not a hardcoded
## absolute hair epsilon -- so it keeps working the same way if NPCs ever
## get their own varying head epsilon, always landing the hair rounder
## than that particular head by the same proportion.
const HAIR_EPSILON_RATIO := 0.8
## SuperEgg's own hard floor (superegg.gd: "Don't go below 2 here" --
## anything lower pinches into a star shape instead of reading as rounder).
const MIN_EPSILON := 2.0
const BOTTOM_EPSILON_TARGET := SuperEgg.EPSILON_FLAT
## Per two direct corrections ("split the difference", then "a bit
## rounder, splitting the difference again to where it started"): 0.5
## (halfway to BOTTOM_EPSILON_TARGET) read too sharp, then 0.25 (half of
## THAT, back toward the fully-round starting point) is the buzzcut's
## current tuned value.
const BOTTOM_EPSILON_BLEND := 0.25

## AFRO: "extend the sides, top and back" -- kept fully round (bottom
## epsilon = top epsilon, no boxy blend at all) since an afro doesn't have
## a trimmed/clipped edge anywhere, unlike the buzzcut. Per a further
## direct correction ("extend more to the back and also extend downwards
## a bit" -- width judged already good, left alone): AFRO_BACK_EXTRA
## raised 0.05 -> 0.09, and AFRO_BOTTOM_EXTRA added. Per a still further
## direct correction ("doesn't need to be quite so wide, just by a cm or
## 2"): AFRO_WIDTH_REDUCTION added, a flat cm-scale trim applied after the
## multiplier (not a change to AFRO_WIDTH_MULT itself, which was judged
## fine as the general shape, just slightly oversized).
const AFRO_WIDTH_MULT := 1.4
const AFRO_WIDTH_REDUCTION := 0.015
const AFRO_TOP_EXTRA := 0.05
const AFRO_BACK_EXTRA := 0.09
const AFRO_BOTTOM_EXTRA := 0.03

## FLAT_TOP: "extend the top upwards and make it less round" -- only the
## top changes (edge extended AND its own epsilon overridden boxy); sides/
## back/bottom stay at the buzzcut's own values, including the buzzcut's
## own mild boxy-bottom blend. Per a further direct correction ("shift the
## whole hair piece backwards 1cm, the hairline is too close to the
## face"): FRONT and BACK both shift back by the same amount -- a pure
## translation, not a resize, so the piece's own depth stays unchanged and
## only its position moves.
const FLAT_TOP_TOP_EXTRA := 0.06
const FLAT_TOP_EPSILON := SuperEgg.EPSILON_FLAT
const FLAT_TOP_BACK_SHIFT := 0.01

## BUN: "using the baseline buzzcut but adding a bun in the back top of
## it" -- the buzzcut is built unmodified, then this small extra round
## piece is added on top, positioned as a fraction of the buzzcut's own
## top/back edges so it nestles into the back-top of the existing mass
## rather than floating off on its own. Per a further direct correction
## ("a bit bigger and a bit farther back/down"): RADIUS_FACTOR up
## (0.35 -> 0.45), Z_FRACTION up (0.55 -> 0.7, farther back), Y_FRACTION
## down (0.8 -> 0.72, farther down -- "slightly", a smaller move than the
## other two).
const BUN_RADIUS_FACTOR := 0.45
const BUN_Y_FRACTION := 0.72
const BUN_Z_FRACTION := 0.7

## PIGTAILS: reuses STYLE_BUN's own "buzzcut base plus a small round piece"
## technique, just two of them mirrored left/right instead of one centered
## at the back. Radius shrunk a bit from BUN_RADIUS_FACTOR (two side buns
## read as too large side-by-side at the same size as one center bun), and
## pulled slightly less far back/down than the center bun so each one clears
## the ear rather than overlapping it.
const PIGTAIL_RADIUS_FACTOR := 0.36
const PIGTAIL_Y_FRACTION := 0.62
const PIGTAIL_Z_FRACTION := 0.45
const PIGTAIL_X_FRACTION := 0.95

## LONG: "extending a bit to the sides and back then making the bottom
## much less round and extending downwards a variable length" -- bottom
## epsilon goes straight to BOTTOM_EPSILON_TARGET (no partial blend at
## all), noticeably boxier than even the buzzcut's own partial blend,
## reading as a blunt-cut end rather than a trimmed taper. length_variance
## (passed in per-call, e.g. from town_generator.gd's own per-NPC random
## pool) adds on top of LONG_BASE_DROP so every long-haired NPC isn't the
## same length.
const LONG_WIDTH_MULT := 1.15
const LONG_BACK_EXTRA := 0.03
const LONG_BASE_DROP := 0.05
## Per direct correction ("extend the front forward considerably so we get
## to actually see bangs in front of the face"): pushes the main piece's
## own front edge well past the head's own front surface -- large enough
## that once the cut below removes everything below eye height, what's
## left above the cut genuinely drapes forward over the forehead like a
## fringe, not just a subtle bulge.
const LONG_FRONT_EXTRA := 0.06
## Per direct correction ("visibly showing in the front below the chin...
## a subtraction superegg offset to the front and bottom, with a smaller
## radius"): a single superegg extended far enough down to read as long
## hair is, at every latitude including the lower ones, still as wide
## front-to-back as it is at the equator -- there's no way to taper just
## the lower-front region of ONE superegg (the same longitude-vs-latitude
## limit documented on BOTTOM_EPSILON_TARGET above: SuperEgg's own
## epsilon_top/epsilon_bottom split only varies roundness by latitude
## band, never by front-vs-back). A second, smaller superegg carved out
## via real CSG subtraction (CSGCombiner3D + CSGMesh3D, OPERATION_
## SUBTRACTION) is what genuinely removes geometry from just that one
## region instead.
##
## Per a further direct correction ("move the clipping shape upwards so
## its top is just above the top of the eyes"): the cut's own Y position
## is solved directly from FigureEyes.top_y() -- this project's actual eye
## geometry, not a guessed fraction -- plus a small margin, rather than a
## fraction below the main piece's own center. Everything ABOVE the cut
## (crown down to just above the eyes) stays the full, considerably-
## forward-extended main piece -- the visible bangs -- and everything at
## or below eye height gets the front carved away instead.
const LONG_CUT_XZ_MULT := 0.9  # smaller than the main piece's own width/depth, per direct instruction
# Raised another 5 cm (0.02 -> 0.07). Raising the cut's top raises where
# the bangs get clipped, so less of the forward-extended main piece stays
# visible above it.
const LONG_CUT_TOP_MARGIN := 0.07  # cut's own top sits this far above FigureEyes.top_y()
## The negative egg extends a full matching half-height below the positive
## hair's bottom. In other words, the positive bottom crosses the cut at
## the cut egg's equator, where its X/Z footprint is widest; all of the
## cut egg's narrowing lower curve remains below the visible hair. This is
## derived from the length-variance-inclusive bottom rather than a fixed
## margin, so longer hair automatically receives a proportionally deeper
## subtractor.
const LONG_CUT_Z_FRACTION := 0.55  # how far in front of the main piece's own center

## HERO: started as the same shape/roundness/epsilon treatment as the
## buzzcut, just repositioned -- "raise it up one cm" is a pure
## translation (both top AND bottom edges shift together, same technique
## FLAT_TOP_BACK_SHIFT uses for its own translate-not-resize move), while
## "extend the front forward one cm" only touches the front edge (a
## resize, growing the piece forward without dragging the back along),
## matching how every earlier single-edge cm correction on the base
## buzzcut worked. Per two further direct corrections: raised again
## (0.01 -> 0.02 total), and made "slightly less round" than the shared
## buzzcut via HERO_EPSILON_BOOST, added to top_epsilon before it's used
## both directly (crown) and as the lerp base for the bottom blend, so the
## whole piece goes uniformly a bit boxier rather than just one region.
const HERO_UP_SHIFT := 0.02
const HERO_FRONT_EXTRA := 0.01
const HERO_EPSILON_BOOST := 0.3


static func add_hair(
	head: MeshInstance3D, semi_axes: Vector3, head_epsilon: float,
	hair_color: Color = DEFAULT_HAIR_COLOR, style: String = STYLE_BUZZCUT,
	length_variance: float = 0.0
) -> void:
	var top_epsilon := maxf(head_epsilon * HAIR_EPSILON_RATIO, MIN_EPSILON)

	match style:
		STYLE_BALD:
			pass
		STYLE_AFRO:
			_build_afro(head, semi_axes, top_epsilon, hair_color)
		STYLE_FLAT_TOP:
			_build_flat_top(head, semi_axes, top_epsilon, hair_color)
		STYLE_BUN:
			_build_buzzcut(head, semi_axes, top_epsilon, hair_color)
			_build_bun(head, semi_axes, hair_color)
		STYLE_PIGTAILS:
			_build_buzzcut(head, semi_axes, top_epsilon, hair_color)
			_build_pigtails(head, semi_axes, hair_color)
		STYLE_LONG:
			_build_long(head, semi_axes, top_epsilon, hair_color, length_variance)
		STYLE_HERO:
			_build_hero(head, semi_axes, top_epsilon, hair_color)
		_:
			_build_buzzcut(head, semi_axes, top_epsilon, hair_color)


static func _buzzcut_edges(semi_axes: Vector3) -> Dictionary:
	return {
		"front": FRONT_EDGE_FACTOR * semi_axes.z + FRONT_EDGE_FLAT,
		"back": BACK_EDGE_FACTOR * semi_axes.z + BACK_EDGE_FLAT,
		"top": TOP_EDGE_FACTOR * semi_axes.y + TOP_EDGE_FLAT,
		"bottom": BOTTOM_EDGE_FACTOR * semi_axes.y + BOTTOM_EDGE_FLAT,
		"width": semi_axes.x * WIDTH_FACTOR,
	}


static func _center(pos_edge: float, neg_edge: float) -> float:
	return (pos_edge + neg_edge) * 0.5


static func _half_extent(pos_edge: float, neg_edge: float) -> float:
	return (pos_edge - neg_edge) * 0.5


## Builds one superegg piece from an edges Dictionary (front/back/top/
## bottom/width, see _buzzcut_edges()'s own shape) and adds it to head.
static func _add_edge_piece(
	head: MeshInstance3D, edges: Dictionary, epsilon_top: float, epsilon_bottom: float, color: Color
) -> void:
	var z_offset := _center(edges["front"], edges["back"])
	var y_offset := _center(edges["top"], edges["bottom"])
	var piece_semi_axes := Vector3(
		edges["width"],
		_half_extent(edges["top"], edges["bottom"]),
		_half_extent(edges["front"], edges["back"])
	)
	_add_piece(head, piece_semi_axes, Vector3(0, y_offset, z_offset), epsilon_top, epsilon_bottom, color)


static func _add_piece(
	head: MeshInstance3D, piece_semi_axes: Vector3, offset: Vector3,
	epsilon_top: float, epsilon_bottom: float, color: Color
) -> void:
	var piece := MeshInstance3D.new()
	piece.mesh = SuperEgg.build_mesh(piece_semi_axes, epsilon_top, epsilon_bottom)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	piece.set_surface_override_material(0, material)
	piece.position = offset
	head.add_child(piece)


static func _build_buzzcut(head: MeshInstance3D, semi_axes: Vector3, top_epsilon: float, color: Color) -> void:
	var edges := _buzzcut_edges(semi_axes)
	var bottom_epsilon := lerpf(top_epsilon, BOTTOM_EPSILON_TARGET, BOTTOM_EPSILON_BLEND)
	_add_edge_piece(head, edges, top_epsilon, bottom_epsilon, color)


static func _build_hero(head: MeshInstance3D, semi_axes: Vector3, top_epsilon: float, color: Color) -> void:
	var edges := _buzzcut_edges(semi_axes)
	edges["top"] += HERO_UP_SHIFT
	edges["bottom"] += HERO_UP_SHIFT
	edges["front"] += HERO_FRONT_EXTRA
	var hero_top_epsilon := top_epsilon + HERO_EPSILON_BOOST
	var bottom_epsilon := lerpf(hero_top_epsilon, BOTTOM_EPSILON_TARGET, BOTTOM_EPSILON_BLEND)
	_add_edge_piece(head, edges, hero_top_epsilon, bottom_epsilon, color)


static func _build_afro(head: MeshInstance3D, semi_axes: Vector3, top_epsilon: float, color: Color) -> void:
	var edges := _buzzcut_edges(semi_axes)
	edges["width"] = edges["width"] * AFRO_WIDTH_MULT - AFRO_WIDTH_REDUCTION
	edges["top"] += AFRO_TOP_EXTRA
	edges["back"] -= AFRO_BACK_EXTRA
	edges["bottom"] -= AFRO_BOTTOM_EXTRA
	# Fully round -- same epsilon top and bottom, no boxy blend.
	_add_edge_piece(head, edges, top_epsilon, top_epsilon, color)


static func _build_flat_top(head: MeshInstance3D, semi_axes: Vector3, top_epsilon: float, color: Color) -> void:
	var edges := _buzzcut_edges(semi_axes)
	edges["top"] += FLAT_TOP_TOP_EXTRA
	edges["front"] -= FLAT_TOP_BACK_SHIFT
	edges["back"] -= FLAT_TOP_BACK_SHIFT
	# Only the crown goes boxy (FLAT_TOP_EPSILON) -- the bottom keeps the
	# buzzcut's own normal round-top-derived blend, not this style's own
	# flat override, so the sides/bottom still read as an ordinary short
	# trim and only the top plateaus flat.
	var bottom_epsilon := lerpf(top_epsilon, BOTTOM_EPSILON_TARGET, BOTTOM_EPSILON_BLEND)
	_add_edge_piece(head, edges, FLAT_TOP_EPSILON, bottom_epsilon, color)


static func _build_bun(head: MeshInstance3D, semi_axes: Vector3, color: Color) -> void:
	var edges := _buzzcut_edges(semi_axes)
	var bun_radius := semi_axes.y * BUN_RADIUS_FACTOR
	var bun_offset := Vector3(0, edges["top"] * BUN_Y_FRACTION, edges["back"] * BUN_Z_FRACTION)
	_add_piece(
		head, Vector3(bun_radius, bun_radius, bun_radius), bun_offset, MIN_EPSILON, MIN_EPSILON, color
	)


static func _build_pigtails(head: MeshInstance3D, semi_axes: Vector3, color: Color) -> void:
	var edges := _buzzcut_edges(semi_axes)
	var pigtail_radius := semi_axes.y * PIGTAIL_RADIUS_FACTOR
	var y_offset: float = edges["top"] * PIGTAIL_Y_FRACTION
	var z_offset: float = edges["back"] * PIGTAIL_Z_FRACTION
	var x_offset: float = edges["width"] * PIGTAIL_X_FRACTION
	for side in [-1.0, 1.0]:
		_add_piece(
			head, Vector3(pigtail_radius, pigtail_radius, pigtail_radius),
			Vector3(side * x_offset, y_offset, z_offset), MIN_EPSILON, MIN_EPSILON, color
		)


static func _build_long(
	head: MeshInstance3D, semi_axes: Vector3, top_epsilon: float, color: Color, length_variance: float
) -> void:
	var edges := _buzzcut_edges(semi_axes)
	edges["width"] *= LONG_WIDTH_MULT
	edges["front"] += LONG_FRONT_EXTRA
	edges["back"] -= LONG_BACK_EXTRA
	edges["bottom"] -= (LONG_BASE_DROP + length_variance)
	var z_offset := _center(edges["front"], edges["back"])
	var y_offset := _center(edges["top"], edges["bottom"])
	var main_semi_axes := Vector3(
		edges["width"],
		_half_extent(edges["top"], edges["bottom"]),
		_half_extent(edges["front"], edges["back"])
	)

	var combiner := CSGCombiner3D.new()

	var main_piece := CSGMesh3D.new()
	# Straight to the full boxy target, not a partial blend -- "much less
	# round" than even the buzzcut's own already-partial bottom blend.
	main_piece.mesh = SuperEgg.build_mesh(main_semi_axes, top_epsilon, BOTTOM_EPSILON_TARGET)
	main_piece.position = Vector3(0, y_offset, z_offset)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	main_piece.material = material
	combiner.add_child(main_piece)

	# See LONG_CUT_* consts' own comment -- carves out the lower-front
	# region that otherwise shows in front of the chin, something no
	# single superegg's own epsilon_top/epsilon_bottom split can do. The
	# cut's own top is pinned to just above real eye height (not a
	# fraction of the main piece), so everything above it -- the bangs --
	# is untouched regardless of how far LONG_FRONT_EXTRA pushes the main
	# piece's own bounds around. The main bottom crosses the cut at its
	# equator, so the cut's entire curved lower half stays below the visible
	# silhouette.
	var cut_top := FigureEyes.top_y(semi_axes) + LONG_CUT_TOP_MARGIN
	# Explicit : float, not := -- edges is a plain (untyped-value)
	# Dictionary (see _buzzcut_edges()'s own -> Dictionary return type), so
	# edges["bottom"] reads as Variant to the static type checker even
	# though it's always a float at runtime, so normalize it before using it
	# in the mirrored-bottom calculation.
	var main_bottom: float = edges["bottom"]
	var cut_bottom := main_bottom - (cut_top - main_bottom)
	var cut_y_offset := _center(cut_top, cut_bottom)
	var cut_semi_axes := Vector3(
		main_semi_axes.x * LONG_CUT_XZ_MULT,
		_half_extent(cut_top, cut_bottom),
		main_semi_axes.z * LONG_CUT_XZ_MULT
	)
	var cut_piece := CSGMesh3D.new()
	cut_piece.mesh = SuperEgg.build_mesh(cut_semi_axes, MIN_EPSILON, MIN_EPSILON)
	cut_piece.operation = CSGShape3D.OPERATION_SUBTRACTION
	cut_piece.position = Vector3(
		0,
		cut_y_offset,
		z_offset + main_semi_axes.z * LONG_CUT_Z_FRACTION
	)
	# Per direct instruction: the surface a CSG subtraction newly exposes
	# needs its own material set explicitly -- Godot renders a boolean
	# subtraction's cut face using the SUBTRACTING shape's own material,
	# and cut_piece previously had none, so the inside of the bangs cut
	# fell back to the engine default (flat grey/white) instead of
	# matching the hair.
	var cut_material := StandardMaterial3D.new()
	cut_material.albedo_color = color
	cut_material.roughness = 0.55
	cut_piece.material = cut_material
	combiner.add_child(cut_piece)

	head.add_child(combiner)
