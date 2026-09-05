class_name SuperellipseStyleBox
extends StyleBox

## Draws every UI background as a superellipse (a "squircle") -- continuous,
## accelerating corner curvature that keeps straight edges between corners,
## rather than the constant-radius circular arc a plain rounded rectangle
## uses. This is the shape primitive behind UITheme's panel/button/chip/slot
## styleboxes; see ui_theme.gd's "Design language" section for the
## project-wide convention this exists to serve. Built as a custom StyleBox
## (not achievable with StyleBoxFlat, which only offers circular-arc
## corners) using low-level RenderingServer polygon calls, since StyleBox
## isn't itself a CanvasItem and has no draw_* convenience methods.
##
## Geometry: each corner is a quarter Lame curve
##   |x/r|^n + |y/r|^n = 1
## centered r in from both edges it joins, swept between the two points
## where it meets the straight edges. n (exponent) is shared by every
## instance via UITheme.SUPERELLIPSE_EXPONENT so the whole game reads as one
## consistent shape language rather than a mix of roundedness per surface;
## n=2 would be an ordinary circular-arc rounded rect, n>2 pulls the curve
## in closer to the sharp corner while staying flatter along the edges --
## higher n reads more like a rectangle with the corner point smoothed off,
## rather than a corner bitten out by a circle.
##
## Border and shadow both build on the same corner geometry: a border is
## drawn as a larger (border-colored) polygon with a smaller (fill-colored)
## one layered on top -- simpler and more robust than stroking a possibly
## non-convex outline. A shadow is faked (RenderingServer has no blur
## primitive to draw into) as several concentric, progressively larger and
## fainter copies of the same silhouette, drawn before the fill -- only the
## halo that peeks out past the fill's own edge ends up visible, which is
## what a soft drop shadow looks like at the small sizes (shadow_size ~6px)
## this project uses.

const CORNER_SEGMENTS := 12

@export var bg_color: Color = Color.WHITE
@export var border_color: Color = Color(0, 0, 0, 0)
@export var border_width: float = 0.0
@export var shadow_color: Color = Color(0, 0, 0, 0)
@export var shadow_size: float = 0.0
@export var corner_radius: float = 16.0
@export var exponent: float = 4.0
## Corner radius as a fraction of the box's shorter side (0 disables this
## and falls back to the fixed-pixel corner_radius alone, e.g. for
## chip_stylebox()'s deliberate always-a-pill look). corner_radius still
## applies as an upper cap when this is set -- without one, a huge
## near-fullscreen panel (ShopUI's root) would compute a corner radius
## hundreds of pixels deep and look like a blob, not a modal with rounded
## corners. Without this ratio, the reverse problem is what actually
## shipped first: a *fixed* 6-8px radius (sized for the original ~44px-tall
## buttons/chips) was still exactly 6-8px on a 168x152 inventory slot --
## far too small a fraction of the box to read as anything but a sharp
## rectangle. Proportional-with-a-cap is the only formula that stays a
## clearly-curved squircle at both scales at once.
@export var corner_ratio: float = 0.0
## How far OUTSIDE the control's own rect this shape draws, per axis
## uniformly (0 = flush with the control's own bounds, the default -- and
## what every OTHER stylebox in the game still uses). Only meaningful for a
## shape meant to sit as a ring outside something else, consistently
## offset from its edge rather than flush with it, the way a browser's own
## focus ring reads -- see UITheme's shared focus-ring stylebox, the one
## thing that actually sets this.
@export var outset: float = 0.0
## Optional inset edge light used by Blorbus-skinned surfaces. This mirrors
## the soft rim response of his translucent 3D body without substituting a
## generic gradient or bitmap texture for the project's squircle geometry.
@export var inner_rim_color: Color = Color.TRANSPARENT
@export var inner_rim_width: float = 0.0
@export var inner_rim_inset: float = 3.0

const SHADOW_LAYERS := 6


func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	if outset != 0.0:
		rect = rect.grow(outset)
	if shadow_size > 0.0 and shadow_color.a > 0.0:
		_draw_shadow(to_canvas_item, rect)

	if border_width > 0.0 and border_color.a > 0.0:
		var outer_radius := _effective_radius(rect, corner_radius)
		if bg_color.a <= 0.0:
			# A true ring (see-through center), not the solid-outer-plus-
			# solid-inner-overpaint technique in the else branch below --
			# that technique relies on the inner fill actually being OPAQUE
			# to visually punch the hole; a transparent inner polygon
			# doesn't erase what the outer polygon already painted
			# underneath it (canvas draws composite over each other, they
			# don't subtract), so it would render as a solid filled
			# squircle instead of an outline. Used specifically by
			# UITheme's shared focus-ring stylebox.
			_draw_ring(to_canvas_item, rect, outer_radius)
		else:
			var outer := boundary_points(rect, outer_radius, exponent)
			RenderingServer.canvas_item_add_polygon(to_canvas_item, outer, PackedColorArray([border_color]))
			var inner_rect := rect.grow(-border_width)
			var inner := boundary_points(inner_rect, clamped_radius(inner_rect, outer_radius - border_width), exponent)
			RenderingServer.canvas_item_add_polygon(to_canvas_item, inner, PackedColorArray([bg_color]))
	else:
		var points := boundary_points(rect, _effective_radius(rect, corner_radius), exponent)
		RenderingServer.canvas_item_add_polygon(to_canvas_item, points, PackedColorArray([bg_color]))

	if inner_rim_width > 0.0 and inner_rim_color.a > 0.0:
		_draw_inset_ring(to_canvas_item, rect)


func _draw_inset_ring(to_canvas_item: RID, rect: Rect2) -> void:
	var outer_rect := rect.grow(-inner_rim_inset)
	var inner_rect := outer_rect.grow(-inner_rim_width)
	if inner_rect.size.x <= 0.0 or inner_rect.size.y <= 0.0:
		return
	var base_radius := _effective_radius(rect, corner_radius)
	var outer_radius := clamped_radius(outer_rect, base_radius - inner_rim_inset)
	var inner_radius := clamped_radius(inner_rect, outer_radius - inner_rim_width)
	var outer := boundary_points(outer_rect, outer_radius, exponent)
	var inner := boundary_points(inner_rect, inner_radius, exponent)
	var count := mini(outer.size(), inner.size())
	var color := PackedColorArray([inner_rim_color])
	for i in count:
		var j := (i + 1) % count
		RenderingServer.canvas_item_add_polygon(
			to_canvas_item,
			PackedVector2Array([outer[i], outer[j], inner[j], inner[i]]),
			color
		)


## A closed ring (outer boundary minus inner boundary), drawn as a loop of
## quads connecting corresponding points on each -- canvas_item_add_polygon
## triangulates a single simple contour with no "polygon with a hole"
## mode, so a true see-through-centered ring has to be built this way
## rather than as one call.
func _draw_ring(to_canvas_item: RID, rect: Rect2, outer_radius: float) -> void:
	var inner_rect := rect.grow(-border_width)
	var inner_radius := clamped_radius(inner_rect, outer_radius - border_width)
	var outer := boundary_points(rect, outer_radius, exponent)
	var inner := boundary_points(inner_rect, inner_radius, exponent)
	var count := mini(outer.size(), inner.size())
	var color := PackedColorArray([border_color])
	for i in count:
		var j := (i + 1) % count
		var quad := PackedVector2Array([outer[i], outer[j], inner[j], inner[i]])
		RenderingServer.canvas_item_add_polygon(to_canvas_item, quad, color)


func _draw_shadow(to_canvas_item: RID, rect: Rect2) -> void:
	var base_radius := _effective_radius(rect, corner_radius)
	for i in range(SHADOW_LAYERS, 0, -1):
		var t := float(i) / float(SHADOW_LAYERS)
		var grow := shadow_size * t
		var layer_rect := rect.grow(grow)
		var layer_radius := clamped_radius(layer_rect, base_radius + grow)
		var alpha := shadow_color.a * pow(1.0 - t, 2.0) / float(SHADOW_LAYERS) * 2.5
		var color := Color(shadow_color.r, shadow_color.g, shadow_color.b, alpha)
		var points := boundary_points(layer_rect, layer_radius, exponent)
		RenderingServer.canvas_item_add_polygon(to_canvas_item, points, PackedColorArray([color]))


## Resolves corner_ratio (a fraction of the box's own shorter side) against
## the fixed-pixel radius cap, then safety-clamps to half the box so
## opposite corners can never overlap.
func _effective_radius(rect: Rect2, radius: float) -> float:
	var r := radius
	if corner_ratio > 0.0:
		r = minf(radius, minf(rect.size.x, rect.size.y) * corner_ratio)
	return clamped_radius(rect, r)


static func clamped_radius(rect: Rect2, radius: float) -> float:
	return clampf(radius, 0.0, minf(rect.size.x, rect.size.y) * 0.5)


## The full closed boundary: four quarter-superellipse corner arcs, each
## followed implicitly by a straight edge to the next corner's first point
## (a polygon fill just connects consecutive points, so the edges never
## need their own explicit points). Static (and public) so any other
## superellipse-shaped drawing in the game -- not just this StyleBox's own
## _draw() -- can build the exact same silhouette; see UIKit.Divider for
## the other caller. This is the one geometry function in the game: no UI
## shape should hand-roll its own corner math instead of calling this.
static func boundary_points(rect: Rect2, radius: float, curve_exponent: float) -> PackedVector2Array:
	if radius <= 0.01:
		return PackedVector2Array([
			rect.position,
			Vector2(rect.position.x + rect.size.x, rect.position.y),
			rect.position + rect.size,
			Vector2(rect.position.x, rect.position.y + rect.size.y),
		])

	var left := rect.position.x
	var top := rect.position.y
	var right := rect.position.x + rect.size.x
	var bottom := rect.position.y + rect.size.y

	var points := PackedVector2Array()
	points.append_array(_corner_arc(Vector2(left + radius, top + radius), radius, PI, 1.5 * PI, curve_exponent))
	points.append_array(_corner_arc(Vector2(right - radius, top + radius), radius, 1.5 * PI, 2.0 * PI, curve_exponent))
	points.append_array(_corner_arc(Vector2(right - radius, bottom - radius), radius, 0.0, 0.5 * PI, curve_exponent))
	points.append_array(_corner_arc(Vector2(left + radius, bottom - radius), radius, 0.5 * PI, PI, curve_exponent))
	return points


## One quarter-arc of a Lame curve of the given exponent, from start_angle
## to end_angle (a PI/2 sweep), centered at `center`.
static func _corner_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, curve_exponent: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in range(CORNER_SEGMENTS + 1):
		var t := lerpf(start_angle, end_angle, float(i) / float(CORNER_SEGMENTS))
		var c := cos(t)
		var s := sin(t)
		var ox := signf(c) * pow(absf(c), 2.0 / curve_exponent) * radius
		var oy := signf(s) * pow(absf(s), 2.0 / curve_exponent) * radius
		pts.append(center + Vector2(ox, oy))
	return pts


func _get_minimum_size() -> Vector2:
	return Vector2(border_width, border_width) * 2.0
