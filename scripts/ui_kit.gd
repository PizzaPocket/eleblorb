class_name UIKit
extends RefCounted

const MOBILE_BREAKPOINT_WIDTH := 700.0
const DESKTOP_REFERENCE_PIXEL_RATIO := 2.0
const MOBILE_REFERENCE_PIXEL_RATIO := 3.0
const TABLET_MIN_SHORT_SIDE_CSS := 600.0


static func is_mobile_viewport(node: Node) -> bool:
	if OS.has_feature("web"):
		var window := JavaScriptBridge.get_interface("window")
		if window != null:
			return (
				float(window.innerWidth) < MOBILE_BREAKPOINT_WIDTH
				or DisplayServer.is_touchscreen_available()
				or int(window.navigator.maxTouchPoints) > 0
			)
	return node.get_viewport().get_visible_rect().size.x < MOBILE_BREAKPOINT_WIDTH or DisplayServer.is_touchscreen_available()


static func is_tablet_touch_viewport() -> bool:
	if not OS.has_feature("web"):
		return false
	var window := JavaScriptBridge.get_interface("window")
	if window == null or int(window.navigator.maxTouchPoints) <= 0:
		return false
	return minf(float(window.innerWidth), float(window.innerHeight)) >= TABLET_MIN_SHORT_SIDE_CSS


static func ui_density_scale(node: Node) -> float:
	if not OS.has_feature("web"):
		return 1.0
	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return 1.0
	var ratio := float(window.devicePixelRatio)
	var touch := DisplayServer.is_touchscreen_available() or int(window.navigator.maxTouchPoints) > 0
	var reference := MOBILE_REFERENCE_PIXEL_RATIO if touch else DESKTOP_REFERENCE_PIXEL_RATIO
	return clampf(ratio / reference, 1.0 / 3.0, 2.0)


static func density_root(layer: CanvasLayer) -> Control:
	var root := Control.new()
	root.name = "UIDensityRoot"
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITheme.get_theme()
	layer.add_child(root)
	var update := func() -> void:
		var density := ui_density_scale(layer)
		root.scale = Vector2.ONE * density
		root.size = layer.get_viewport().get_visible_rect().size / density
	update.call()
	layer.get_viewport().size_changed.connect(update)
	return root


static func logical_viewport_size(node: Node) -> Vector2:
	return node.get_viewport().get_visible_rect().size / ui_density_scale(node)

## Reusable UI builder functions consuming UITheme's tokens -- every new UI
## surface (Hud, DialogUI, ShopUI, InventoryUI) should build through these
## rather than hand-rolling Control.new() + ad hoc theme overrides inline,
## so the visual language stays centralized and consistent.


static func panel() -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.panel_stylebox())
	return p


## Same panel background as panel()/backed_readout(), around an arbitrary
## pre-built child control instead of a fixed Label -- for a HUD readout
## that's already a composite control (e.g. stat_meter()) and just needs a
## backing panel to sit in, per ui_theme.gd's design language rule 20.
static func backed_control(child: Control) -> PanelContainer:
	var p := panel()
	p.add_child(child)
	return p


static func loading_progress_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, UITheme.SPACE_SM)
	bar.add_theme_stylebox_override("background", UITheme.loading_progress_stylebox(UITheme.LOADING_TRACK))
	bar.add_theme_stylebox_override("fill", UITheme.loading_progress_stylebox(UITheme.LOADING_FILL))
	return bar


static func heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UITheme.FONT_HEADING)
	# TEXT_PRIMARY (white), not ACCENT_GOLD -- per direct instruction, no
	# yellow/gold anywhere in the UI; a header stands out through size
	# (FONT_HEADING) alone, the same way it would in a strictly black-and-
	# white print layout.
	label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	return label


static func body_label(text: String, color: Color = UITheme.TEXT_PRIMARY) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


static func caption_label(text: String, color: Color = UITheme.TEXT_SECONDARY) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	label.add_theme_color_override("font_color", color)
	# Off by default on a bare Label, which means a caption's *unwrapped*
	# width becomes its minimum size -- fine for a short fixed string, but
	# an item description sitting inside a ScrollContainer forced that
	# container's content wider than the panel and opened up a horizontal
	# scrollbar instead of just wrapping the text down to a second line.
	# For a short caption meant to sit INLINE in a row next to other
	# controls instead (not a standalone block of unpredictable-length
	# text), use inline_caption() below instead -- this wrap behavior is
# exactly what let a cramped row squeeze a short inline status down to
	# one character per line.
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


## A short caption meant to sit inline in a row next to other controls (a
## button, another label) rather than wrap across multiple lines --
## distinct from caption_label() above, which wraps and is right for text
## of unpredictable length (item descriptions). Sized to its own content
## (SIZE_SHRINK_BEGIN) so a cramped row can't squeeze it down far enough for
## autowrap to matter.
##
## BEGIN, not CENTER -- per direct correction, CENTER was silently
## misaligning a vertical stack of these (InventoryUI's blorb row info
## column: name, type_chip(), two inline_caption() lines): a Container sizes
## its own cross-axis extent off its WIDEST child, and a narrower CENTER-
## shrunk sibling then centers itself within that leftover width instead of
## sitting flush with the others above/below it -- reading as each line
## randomly nudged sideways by a different amount depending on its own text
## length, not a deliberately centered block. BEGIN pins every line to the
## same left edge regardless of how its own text length compares to its
## siblings'.
static func inline_caption(text: String, color: Color = UITheme.TEXT_SECONDARY) -> Label:
	var label := caption_label(text, color)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return label


static func button(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = UITheme.BUTTON_MIN_HEIGHT
	b.pressed.connect(on_pressed)
	return b


## Enforces the modal focus invariant shared by Inventory, Shop, actionable
## Dialog, and Pause. A queued/hidden/disabled control is not a usable focus
## owner. preferred is ordered semantically by the caller; if none survive,
## the first focusable descendant becomes the recovery target. A visible
## control outside root is presumed to belong to a higher stacked modal.
static func ensure_modal_focus(root: Control, preferred: Array = []) -> Control:
	if root == null or not root.is_visible_in_tree():
		return null
	var current := root.get_viewport().gui_get_focus_owner()
	if current != null and not current.is_queued_for_deletion() and current.is_visible_in_tree():
		if current == root or root.is_ancestor_of(current):
			return current
		return current
	for candidate_value in preferred:
		var candidate := candidate_value as Control
		if _is_available_focus_target(candidate):
			candidate.grab_focus()
			return candidate
	for node in root.find_children("*", "Control", true, false):
		var candidate := node as Control
		if _is_available_focus_target(candidate):
			candidate.grab_focus()
			return candidate
	return null


static func _is_available_focus_target(control: Control) -> bool:
	if (
		control == null
		or control.is_queued_for_deletion()
		or not control.is_visible_in_tree()
		or control.focus_mode == Control.FOCUS_NONE
	):
		return false
	if control is BaseButton and (control as BaseButton).disabled:
		return false
	return true


## A dialog response is interactive but intentionally does not look like a
## CTA button: it reads as the player's spoken line. Focus is communicated by
## the separate margin arrow supplied by response_arrow(), so every Button
## state uses an empty surface and only the text color changes on focus/hover.
static func response_option(text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.flat = true
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.custom_minimum_size.y = UITheme.BUTTON_MIN_HEIGHT
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	b.add_theme_color_override("font_color", UITheme.TEXT_SECONDARY)
	b.add_theme_color_override("font_hover_color", UITheme.TEXT_PRIMARY)
	b.add_theme_color_override("font_pressed_color", UITheme.TEXT_PRIMARY)
	b.add_theme_color_override("font_focus_color", UITheme.TEXT_PRIMARY)
	for state in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		b.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	b.pressed.connect(on_pressed)
	return b


## Drawn rather than a Unicode glyph so the response cursor belongs to the
## same authored icon language as the rest of UIKit. It points left from the
## right margin toward the currently focused spoken response.
class ResponseArrow extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(UITheme.SPACE_MD, UITheme.BUTTON_MIN_HEIGHT)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var half_height := minf(size.y * 0.18, UITheme.SPACE_SM)
		var tip := Vector2(UITheme.SPACE_XS, center.y)
		var back_x := size.x - UITheme.SPACE_XS
		draw_colored_polygon(PackedVector2Array([
			tip,
			Vector2(back_x, center.y - half_height),
			Vector2(back_x, center.y + half_height),
		]), UITheme.TEXT_PRIMARY)


static func response_arrow() -> Control:
	return ResponseArrow.new()


## Blorbus's two embedded eye markings, translated into the shared 2D
## superellipse language and driven by the same randomized EyeBlink clock
## as every physical blorb. Used as the Inventory modal's living header.
class BlorbusEyes extends Control:
	var blink_state := EyeBlink.new_state()

	func _init() -> void:
		custom_minimum_size = Vector2(UITheme.FONT_DISPLAY * 6.0, UITheme.FONT_DISPLAY * 2.10)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		EyeBlink.advance(blink_state, delta)
		queue_redraw()

	func _draw() -> void:
		var openness := EyeBlink.openness(blink_state)
		# Keep the original eye dimensions; positional separation is now 50%
		# wider than the previous already-expanded spacing.
		var eye_size := Vector2(UITheme.FONT_DISPLAY * 1.16, UITheme.FONT_DISPLAY * 1.56 * openness)
		var center_y := size.y * 0.5
		var spacing := UITheme.FONT_DISPLAY * 1.35 * 1.875
		for side in [-1.0, 1.0]:
			var center := Vector2(size.x * 0.5 + side * spacing, center_y)
			var rect := Rect2(center - eye_size * 0.5, eye_size)
			var radius := SuperellipseStyleBox.clamped_radius(rect, eye_size.x * 0.42)
			var points := SuperellipseStyleBox.boundary_points(rect, radius, UITheme.SUPERELLIPSE_EXPONENT)
			draw_colored_polygon(points, UITheme.BLORBUS_EYE)


static func blorbus_eyes() -> Control:
	return BlorbusEyes.new()


## A tab-switch button (InventoryUI's Items/Blorbs row, or any future view
## switch inside one panel -- see UITheme's design language item 9) --
## same as button() but restyled via UITheme.tab_button_stylebox() so the
## active tab reads as selected through its gold border rather than
## needing a separate label or indicator control.
static func tab_button(text: String, active: bool, on_pressed: Callable) -> Button:
	var b := button(text, on_pressed)
	set_tab_button_active(b, active)
	return b


## Restyles an existing tab_button() in place -- the caller (InventoryUI)
## keeps a reference to each tab button and calls this on both whenever the
## active tab changes, rather than rebuilding them.
static func set_tab_button_active(b: Button, active: bool) -> void:
	var box := UITheme.tab_button_stylebox(active)
	b.add_theme_stylebox_override("normal", box)
	b.add_theme_stylebox_override("hover", box)
	b.add_theme_stylebox_override("pressed", box)
	b.add_theme_stylebox_override("focus", UITheme.focus_ring_stylebox())


## A single label with a guaranteed-contrast panel behind it -- the fix for
## text that would otherwise float bare over the live 3D scene (see
## UITheme's docstring: contrast against an arbitrary moving background
## can't be bounded by font choice alone). Use this for anything shown
## directly over gameplay (HUD readouts, the interaction prompt), not for
## text already inside a full modal panel.
static func backed_readout(text: String, color: Color = UITheme.TEXT_PRIMARY, font_size: int = UITheme.FONT_BODY) -> PanelContainer:
	var p := panel()
	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(label)
	return p


## Convenience for updating a backed_readout() or stat_badge() built via
## either function -- both name their inner Label the same way, so one
## updater covers both.
static func set_readout_text(readout: PanelContainer, text: String) -> void:
	var label := readout.get_node("Label") as Label
	if label != null:
		label.text = text


## A compact, never-wrapping "pill" badge for a short stat readout (a coin
## count, etc). backed_readout()'s Label defaults to word-wrap, which is
## right for a multi-word message line but wrong here: squeeze one into a
## narrow flex layout (e.g. next to a title and a close button in a header
## row) and it wraps one character per line instead of just... not fitting.
## Sized to its own content (SIZE_SHRINK_CENTER) rather than stretched by
## its parent container, so it can't be squeezed to near-zero width and
## can't be stretched to some other child's height either.
static func stat_badge(text: String, color: Color = UITheme.TEXT_PRIMARY) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.chip_stylebox())
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	label.add_theme_color_override("font_color", color)
	p.add_child(label)
	return p


## Compact count marker for a stacked inventory slot. Unlike stat_badge(),
## this uses caption type and tight padding so it can sit in a slot corner
## without competing with the item's icon or name.
static func quantity_badge(quantity: int) -> PanelContainer:
	var p := PanelContainer.new()
	var box := UITheme.chip_stylebox()
	box.content_margin_left = UITheme.SPACE_SM
	box.content_margin_right = UITheme.SPACE_SM
	box.content_margin_top = UITheme.SPACE_XS
	box.content_margin_bottom = UITheme.SPACE_XS
	p.add_theme_stylebox_override("panel", box)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label := Label.new()
	label.text = str(quantity)
	label.add_theme_font_size_override("font_size", UITheme.FONT_CAPTION)
	label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(label)
	return p


## Passive socket for the permanent gem that defines a Blorb's element.
## Empty communicates Normal type (and Blorbus's lore exception).
static func elemental_gem_socket(element: String, socket_size: float = 84.0) -> PanelContainer:
	var socket := PanelContainer.new()
	socket.custom_minimum_size = Vector2(socket_size, socket_size)
	socket.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	socket.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	socket.mouse_filter = Control.MOUSE_FILTER_IGNORE
	socket.add_theme_stylebox_override("panel", UITheme.elemental_gem_socket_stylebox())
	socket.tooltip_text = "%s elemental gem" % element.capitalize() if element != "" else "Empty elemental gem socket — Normal type"
	return socket


static func blorb_name_field(text: String) -> LineEdit:
	var field := LineEdit.new()
	field.text = text
	field.custom_minimum_size = Vector2(300, UITheme.BUTTON_MIN_HEIGHT)
	field.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	field.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	field.add_theme_color_override("caret_color", UITheme.TEXT_PRIMARY)
	field.add_theme_color_override("selection_color", UITheme.SELECTION_BG)
	field.add_theme_stylebox_override("normal", UITheme.name_field_stylebox())
	field.add_theme_stylebox_override("focus", UITheme.name_field_focus_stylebox())
	return field


## Tokoin: a standing gold coin viewed face-on -- a rim, a face, an inner
## ring detail, and a shine highlight, matching tokoin.gd's metallic gold
## (0.95, 0.78, 0.25) 3D material rather than an arbitrary UI accent color.
class CoinIcon extends Control:
	const GOLD := Color(0.95, 0.78, 0.25)

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		draw_circle(c, r, GOLD.darkened(0.28), true, -1.0, true)
		draw_circle(c, r * 0.86, GOLD, true, -1.0, true)
		draw_arc(c, r * 0.62, 0.0, TAU, 24, GOLD.darkened(0.4), 1.5, true)
		var highlight := PackedVector2Array([
			c + Vector2(-r * 0.35, -r * 0.45), c + Vector2(-r * 0.05, -r * 0.55), c + Vector2(-r * 0.15, -r * 0.15),
		])
		draw_colored_polygon(highlight, Color(1, 1, 1, 0.55))


## Fixed-size empty stage for an asynchronously cached 3D portrait. It never
## flashes a legacy illustrated stand-in while the real render is pending.
static func portrait_slot(portrait_size: float) -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(portrait_size, portrait_size)
	container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return container


## WCAG relative luminance -- same formula UITheme's own documented text/
## background contrast ratios (see that file's header comment) were
## computed with, applied here to an arbitrary caller-supplied color rather
## than one fixed palette entry (see type_chip() below).
static func _relative_luminance(c: Color) -> float:
	var r := _linearize(c.r)
	var g := _linearize(c.g)
	var b := _linearize(c.b)
	return 0.2126 * r + 0.7152 * g + 0.0722 * b


static func _linearize(v: float) -> float:
	return v / 12.92 if v <= 0.04045 else pow((v + 0.055) / 1.055, 2.4)


## A colored pill tag (design language item 11) for a short label with real
## semantic meaning to identify -- a blorb's element, currently -- rather
## than a passive badge. Same pill geometry as chip_stylebox(), just tinted
## by the caller's own color (a translucent fill plus a solid border in
## that color) instead of the neutral BG_PANEL every ordinary chip uses, so
## "Fire"/"Water"/"Normal" reads as a colored tag distinguishable at a
## glance rather than one more plain badge among the stat meters next to it.
static func type_chip(text: String, tint: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var box := SuperellipseStyleBox.new()
	box.bg_color = Color(tint.r, tint.g, tint.b, 0.32)
	box.border_color = tint
	box.border_width = 3
	box.corner_radius = UITheme.CHIP_CORNER_RADIUS
	box.exponent = UITheme.SUPERELLIPSE_EXPONENT
	box.set_content_margin_all(UITheme.SPACE_SM)
	p.add_theme_stylebox_override("panel", box)
	# SHRINK_BEGIN horizontally, not CENTER -- per direct correction, see
	# inline_caption()'s own comment on the same fix: a chip narrower than
	# whatever's setting its VBoxContainer column's width (e.g. a blorb's
	# name above it in InventoryUI's info column) would otherwise center
	# itself under that wider sibling instead of lining up flush with it.
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	# IGNORE, not the Control default STOP -- a chip sitting inside a
	# clickable row (InventoryUI's blorb rows) would otherwise swallow the
	# click before it reaches the Button underneath.
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Per direct correction: a light tint (the default near-white "Normal"
	# blorb color, for instance) paired with TEXT_PRIMARY's own light text
	# read as illegible -- no WCAG check against the chip's own background,
	# just an assumption that every chip is dark like the rest of the UI.
	# Picks dark or light text from the tint's own relative luminance
	# instead, reusing BG_PANEL_LIGHT (an existing dark-ish token) rather
	# than introducing flat black.
	var text_color := UITheme.BG_PANEL_LIGHT if _relative_luminance(tint) > 0.5 else UITheme.TEXT_PRIMARY
	p.add_child(inline_caption(text, text_color))
	return p


## The meter bar, drawn with the same superellipse corner math every shape
## in the game uses. Comparable fixed stats remain fill-only; depletable
## resources opt into a quiet capacity track. Both capacity and current fill
## use the same global comparison scale as the fixed stats, so neither falsely
## reads as full-width merely because the resource is currently full. No text
## of its own
## (see stat_meter() below, which pairs this with a real Label instead of
## hand-drawing text) -- keeping text in a real Label means it still goes
## through the shared theme's font size/color rather than needing its own
## font lookup inside _draw().
class StatMeterBar extends Control:
	var value: int
	var capacity_value: int
	var scale_max_value: int
	var fill_color: Color
	var show_track: bool

	func _init(val: int, capacity: int, scale_max: int, color: Color, with_track: bool) -> void:
		value = val
		capacity_value = capacity
		scale_max_value = scale_max
		fill_color = color
		show_track = with_track
		# A bare Control (unlike Label) defaults to MOUSE_FILTER_STOP -- would
		# otherwise swallow the click meant for the blorb-row Button this sits
		# inside of.
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		if show_track:
			var track_fraction := clampf(float(capacity_value) / float(scale_max_value), 0.0, 1.0) if scale_max_value > 0 else 0.0
			var track_width := maxf(size.y, size.x * track_fraction)
			var track_rect := Rect2(Vector2.ZERO, Vector2(track_width, size.y))
			var track_radius := SuperellipseStyleBox.clamped_radius(track_rect, size.y * 0.5)
			draw_colored_polygon(
				SuperellipseStyleBox.boundary_points(track_rect, track_radius, UITheme.SUPERELLIPSE_EXPONENT),
				Color(UITheme.TEXT_PRIMARY, 0.18)
			)
		var frac := clampf(float(value) / float(scale_max_value), 0.0, 1.0) if scale_max_value > 0 else 0.0
		if frac <= 0.0:
			return
		# Never narrower than it is tall, so the pill's own rounded cap
		# doesn't read as a clipped/broken shape at very low values.
		var fill_width := maxf(size.y, size.x * frac)
		var fill_rect := Rect2(Vector2.ZERO, Vector2(fill_width, size.y))
		var fill_radius := SuperellipseStyleBox.clamped_radius(fill_rect, size.y * 0.5)
		draw_colored_polygon(
			SuperellipseStyleBox.boundary_points(fill_rect, fill_radius, UITheme.SUPERELLIPSE_EXPONENT),
			fill_color
		)


## A thin five-pixel datum, separated generously from neighboring rows,
## reads more cleanly than the earlier heavy swatch treatment.
const STAT_METER_HEIGHT := 5.0
const STAT_METER_BAR_WIDTH := 360.0
## A true fixed data column, wide enough for current/max resource copy such
## as "MP: 20/30" without expanding based on any individual value.
const STAT_METER_LABEL_WIDTH := 210.0
## One uniform fill color for every stat meter, per direct correction --
## a per-stat rainbow (STR red, DEF gold, HP green, MP blue) read as noise
## rather than a legible signal; the bar's own length already carries the
## comparison, so the color doesn't need to carry a second one. TEXT_PRIMARY
## (white), not ACCENT_GOLD -- per a further direct instruction dropping
## yellow/gold from the UI entirely, including data-vis elements like this.
const STAT_METER_COLOR := UITheme.TEXT_PRIMARY


## A labeled, proportional stat meter (design language item 11) -- the
## label and its value combined into one "STR: 8"-style string (not split
## across separate label/value columns, per direct correction) sitting
## left of the bar itself (StatMeterBar above), so a blorb's stats show
## relative magnitude at a glance instead of needing every digit read and
## compared by hand. The label column is fixed-width so a whole stack of
## these (see InventoryUI's Blorbs tab) lines its bars up at the same x
## regardless of how wide any one value happens to print.
static func stat_meter(
	stat_label: String, value: int, max_value: int,
	show_track: bool = false, comparison_max: int = -1,
	label_width: float = STAT_METER_LABEL_WIDTH,
	bar_width: float = STAT_METER_BAR_WIDTH
) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SPACE_SM)
	# SHRINK_BEGIN, not SHRINK_CENTER -- per direct correction, CENTER was
	# the actual cause of the bars reading as "nudged right by the number to
	# their left": the meters VBoxContainer sizes its own column to its
	# WIDEST row (whichever stat's label needed the most horizontal room --
	# e.g. a longer number), and a CENTER-shrunk row narrower than that
	# column gets centered WITHIN it, sliding that row's whole label+bar
	# pair sideways by half the width difference. Every other row in the
	# same stack shifts by a different amount depending on its own label's
	# width, so bars land at different x's row to row even though the
	# label column itself is already a fixed STAT_METER_LABEL_WIDTH. BEGIN
	# pins every row to the column's left edge regardless of that width
	# difference, so the bars stay aligned no matter how many digits the
	# number to their left has.
	row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	# IGNORE, not the Control default STOP -- same reasoning as type_chip()
	# just above: a meter row sitting inside a clickable blorb row shouldn't
	# be able to steal the click from the Button underneath it.
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var value_text := "%d/%d" % [value, max_value] if show_track else str(value)
	var label_ctrl := inline_caption("%s: %s" % [stat_label, value_text], UITheme.TEXT_PRIMARY)
	# A fixed column aligns ordinary rows, but must not become a clipping
	# window when debug/high-level values gain digits. Measure the actual
	# rendered caption and widen only as much as it needs. The adjacent bar
	# deliberately retains its authored width: its length encodes magnitude
	# and must remain visually comparable regardless of digit count.
	label_ctrl.clip_text = false
	var natural_label_width: float = ceilf(label_ctrl.get_minimum_size().x)
	var resolved_label_width: float = maxf(label_width, natural_label_width)
	label_ctrl.custom_minimum_size.x = resolved_label_width
	label_ctrl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label_ctrl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(label_ctrl)

	var scale_max := comparison_max if comparison_max > 0 else max_value
	var bar := StatMeterBar.new(value, max_value, scale_max, STAT_METER_COLOR, show_track)
	bar.custom_minimum_size = Vector2(bar_width, STAT_METER_HEIGHT)
	row.add_child(bar)

	return row


## Small drawn triangular arrow, authored pointing straight up (tip at the
## top of its own bounding box) -- rotated externally frame-to-frame by
## whoever owns it (see hud.gd's wild-blorb direction hint) to point toward
## whatever it's currently tracking. Double-stroke outline (dark, then a
## light fill) for legibility over the live 3D scene behind it, the same
## technique the (currently unused) Crosshair class in hud.gd uses -- this
## one isn't sitting fully inside an opaque panel either, just the
## translucent chip direction_hint() wraps it in below.
class DirectionArrowIcon extends Control:
	var tint: Color

	func _init(color: Color) -> void:
		tint = color

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var tip := Vector2(w * 0.5, h * 0.06)
		var base_l := Vector2(w * 0.2, h * 0.88)
		var base_r := Vector2(w * 0.8, h * 0.88)
		var notch := Vector2(w * 0.5, h * 0.6)
		var arrow := PackedVector2Array([tip, base_r, notch, base_l])
		draw_colored_polygon(arrow, tint)
		draw_polyline(PackedVector2Array([tip, base_r, notch, base_l, tip]), Color(0, 0, 0, 0.55), 1.5, true)


## A small rotating arrow pointing toward whatever hud.gd currently has it
## tracking (the nearest not-yet-partied wild blorb) -- "the game tells you
## which way to go," per direct instruction. Distinct from a passive
## readout (UITheme design language item 5): this is an active guidance
## affordance that stays on screen for as long as there's somewhere it can
## point, not a value that flashes on change. Wrapped in the same
## translucent pill chip_stylebox() every other compact HUD badge uses, so
## the arrow itself stays legible over the moving 3D scene behind it.
## hud.gd owns showing/hiding it and calling set_direction_hint_angle() each
## frame; this only builds the static shell.
static func direction_hint(color: Color = UITheme.TEXT_PRIMARY) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.chip_stylebox())
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var icon := DirectionArrowIcon.new(color)
	icon.name = "Arrow"
	# 50% bigger than an ordinary compact HUD icon (UITheme.FONT_BODY,
	# matching coin_icon()'s own FONT_BODY-sized default), per
	# direct instruction -- this is the player's main tool for actually
	# finding wild blorbs now, not a minor decoration, so it should read
	# clearly at a glance. Tracks FONT_BODY directly (rather than its own
	# hardcoded pixel value) so the whole-UI 1.5x type-scale pass carried
	# this relationship forward automatically instead of needing its own
	# separate update.
	var icon_size := UITheme.FONT_BODY * 1.5
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.pivot_offset = Vector2(icon_size, icon_size) * 0.5
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(icon)

	return p


static func set_direction_hint_angle(hint: PanelContainer, angle: float) -> void:
	var icon := hint.get_node("Arrow") as Control
	if icon != null:
		icon.rotation = angle


static func coin_icon(icon_size: float) -> Control:
	var icon := CoinIcon.new()
	icon.custom_minimum_size = Vector2(icon_size, icon_size)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Compact "pill" badge pairing coin_icon() with a numeric readout -- the
## Tokoins HUD/header readout everywhere in the game, replacing a literal
## "Tokoins:" text label with the coin's own image per direct instruction.
## Structured the same shrink-to-content way as stat_badge() (never
## stretched, never wrapped).
static func tokoin_badge(amount: int, color: Color = UITheme.TEXT_PRIMARY) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UITheme.chip_stylebox())
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var row := HBoxContainer.new()
	row.name = "Row"
	row.add_theme_constant_override("separation", UITheme.SPACE_SM)
	p.add_child(row)

	row.add_child(coin_icon(UITheme.FONT_BODY))

	var label := Label.new()
	label.name = "Label"
	label.text = str(amount)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", UITheme.FONT_BODY)
	label.add_theme_color_override("font_color", color)
	row.add_child(label)

	return p


## Updates a tokoin_badge()'s numeric readout in place.
static func set_tokoin_amount(badge: PanelContainer, amount: int) -> void:
	var row := badge.get_node("Row") as HBoxContainer
	if row == null:
		return
	var label := row.get_node("Label") as Label
	if label != null:
		label.text = str(amount)


## Thin capsule-shaped rule for separating a header from its body (dialogue
## speaker/line, a "Buy"/"Sell" section title) -- rounded-end superellipse
## drawn with the exact same corner math as SuperellipseStyleBox
## (SuperellipseStyleBox.boundary_points()), not a bare ColorRect. Per the
## design language's shape rule (UITheme item 6), nothing in the UI stays a
## plain rectangle just because it's thin.
class Divider extends Control:
	var bar_color: Color

	func _init(color: Color) -> void:
		bar_color = color

	func _draw() -> void:
		if size.x <= 0.0 or size.y <= 0.0:
			return
		var rect := Rect2(Vector2.ZERO, size)
		var radius := SuperellipseStyleBox.clamped_radius(rect, size.y * 0.5)
		var points := SuperellipseStyleBox.boundary_points(rect, radius, UITheme.SUPERELLIPSE_EXPONENT)
		draw_colored_polygon(points, bar_color)


static func divider(color: Color = UITheme.BUTTON_BORDER, thickness: float = 6.0) -> Control:
	var bar := Divider.new(color)
	bar.custom_minimum_size = Vector2(0, thickness)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return bar


## Small drawn "x" mark for close_button() below -- a real icon (two
## crossing lines drawn directly), not a Unicode glyph standing in for
## one. mouse_filter = IGNORE so clicks pass through to the parent Button.
class CloseIcon extends Control:
	const ICON_SIZE := 24.0
	const LINE_WIDTH := 3.0

	func _draw() -> void:
		var half := ICON_SIZE * 0.5
		var center := size * 0.5
		draw_line(center + Vector2(-half, -half), center + Vector2(half, half), UITheme.TEXT_PRIMARY, LINE_WIDTH, true)
		draw_line(center + Vector2(-half, half), center + Vector2(half, -half), UITheme.TEXT_PRIMARY, LINE_WIDTH, true)


## Small square icon-style dismiss control ("x") for a modal's corner --
## a full-width "Close" text button reads oversized for that role; a
## compact icon button is the more typical modern convention for
## dismissing a window-style panel. (Dialogue choices, in contrast, stay
## as ordinary text buttons via button() above -- "Close" there is a
## conversational option, not a window chrome control.)
static func close_button(on_pressed: Callable) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(UITheme.BUTTON_MIN_HEIGHT, UITheme.BUTTON_MIN_HEIGHT)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(on_pressed)
	b.set_meta("ui_sound_kind", "back")

	var icon := CloseIcon.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(icon)

	return b


## Anchors a top-level Control (a direct CanvasLayer child, not inside
## another Container) to a screen edge/corner with a fixed pixel margin,
## sized by its own content rather than a pre-computed box -- growing
## safely inward as content changes size, never toward the screen edge
## it's anchored to.
##
## Deliberately NOT built on set_anchors_and_offsets_preset() +
## PRESET_MODE_KEEP_SIZE: that mode snapshots the control's *current* size
## to compute offsets, but a freshly-built control hasn't been through a
## layout pass yet and reads as zero-size at that point -- silently
## mis-anchoring anything whose real size is determined later by its
## content (a Label's text, a container's children). Confirmed as the
## cause of the Tokoins badge landing off the right edge of the screen
## (grow_horizontal defaults to BOTH; growing from a captured zero width
## at a point just inside the right edge pushes half the growth past that
## edge) and the dialog panel/HUD prompt reading as off-center for the
## same reason. This anchors + sizes without ever needing to know the
## control's size in advance, so it's correct regardless of when layout
## actually happens.
##
## anchor_h/anchor_v are the horizontal/vertical anchor point as a 0..1
## fraction (0=left/top, 0.5=center, 1=right/bottom) -- pass Control.
## ANCHOR_BEGIN/ANCHOR_CENTER/ANCHOR_END-style values (0.0/0.5/1.0) rather
## than a PRESET_* constant, since this covers arbitrary combinations, not
## just the 9 preset corners/edges.
static func anchor_to_edge(
	control: Control, anchor_h: float, anchor_v: float, margin_h: float, margin_v: float
) -> void:
	control.anchor_left = anchor_h
	control.anchor_right = anchor_h
	control.anchor_top = anchor_v
	control.anchor_bottom = anchor_v
	# At anchor 0 (left/top), a positive margin pushes inward (+margin); at
	# anchor 1 (right/bottom), inward is negative (-margin); at 0.5
	# (centered), there's no edge to hold clear of -- margin is 0 either
	# way and grow direction alone (BOTH) keeps it centered as it grows.
	var h_sign := 1.0 if anchor_h < 0.5 else (-1.0 if anchor_h > 0.5 else 0.0)
	var v_sign := 1.0 if anchor_v < 0.5 else (-1.0 if anchor_v > 0.5 else 0.0)
	control.offset_left = h_sign * margin_h
	control.offset_right = h_sign * margin_h
	control.offset_top = v_sign * margin_v
	control.offset_bottom = v_sign * margin_v
	control.grow_horizontal = (
		Control.GROW_DIRECTION_END if anchor_h < 0.5
		else (Control.GROW_DIRECTION_BEGIN if anchor_h > 0.5 else Control.GROW_DIRECTION_BOTH)
	)
	control.grow_vertical = (
		Control.GROW_DIRECTION_END if anchor_v < 0.5
		else (Control.GROW_DIRECTION_BEGIN if anchor_v > 0.5 else Control.GROW_DIRECTION_BOTH)
	)


## A title plus a divider line filling the rest of the row, so a column
## heading (e.g. "Buy"/"Sell") reads unmistakably as a section header
## rather than blending in as one more muted caption among the rows below.
static func section_header(text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SPACE_SM)

	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", UITheme.FONT_HEADING)
	# TEXT_PRIMARY (white), not ACCENT_GOLD -- see heading()'s own comment
	# above for the same reasoning (no yellow/gold anywhere in the UI).
	label.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	row.add_child(label)
	row.add_child(divider())

	return row


## Recessed content well for scrolling collections inside a larger modal.
static func scroll_panel() -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", UITheme.slot_stylebox())
	return result
