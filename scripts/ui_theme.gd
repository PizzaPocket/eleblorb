class_name UITheme
extends RefCounted

## Central design-system tokens for every UI surface in the game (Hud,
## DialogUI, ShopUI, InventoryUI) -- one shared Theme resource so visual
## language (colors, type scale, spacing, panel/button style) lives in one
## place instead of being re-decided ad hoc per script, the way hud.gd
## originally did with scattered per-node add_theme_*_override calls.
##
## Palette: dark neutral panels plus Blorbus brain-pink psychic goo for
## Inventory and actionable controls, chosen to read clearly over an outdoor
## 3D scene. All text/background pairs
## below are computed against the real WCAG relative-luminance formula
## (using BG_PANEL as an opaque color, i.e. the best case for a translucent
## panel -- see BG_PANEL's own alpha note) and clear the AA normal-text
## threshold (4.5:1) with real margin:
##   TEXT_PRIMARY on BG_PANEL     = 14.27:1
##   TEXT_SECONDARY on BG_PANEL   =  8.75:1
##   ACCENT_GREEN on BG_PANEL     =  8.67:1
##   ACCENT_RED on BG_PANEL       =  5.64:1
## Against a worst-case pure-white scene after real alpha compositing:
##   TEXT_PRIMARY on BLORBUS_PANEL = 8.21:1
##   TEXT_SECONDARY on BLORBUS_PANEL = 5.04:1
##   TEXT_PRIMARY on BUTTON_BG    = 8.66:1
##   TEXT_PRIMARY on BUTTON_BG_HOVER = 6.57:1
## Font size alone can't guarantee AA against an arbitrary, moving 3D
## background behind unbacked text -- every piece of UI text in this game
## must sit on one of these panel colors (see UIKit.backed_readout), not
## float bare over the viewport the way hud.gd's labels originally did.
##
## See DESIGN.md-in-code below (the "design language" section at the
## bottom of this file) for the broader conventions every UI surface in
## this project should follow, not just these color/spacing tokens.

# 0.55, down from 0.78 (itself already down from an original 0.92) -- per
# a further direct correction, modal backgrounds still read as too heavy.
# This trades away more of the contrast margin documented above against a
# worst-case bright background behind the panel (the ratios above assume
# an opaque panel), but TEXT_PRIMARY's own margin (14:1 against solid
# BG_PANEL) leaves real headroom even with real blend-through.
const BG_PANEL := Color(0.16, 0.11, 0.07, 0.55)
const BG_PANEL_LIGHT := Color(0.24, 0.17, 0.11)
## Selection belongs to Blorbus's psychic palette, not the brown passive
## panel family. Used by held item sockets and selected Blorb portraits.
const SELECTION_BG := Color(0.48, 0.25, 0.32, 0.94)
const TEXT_PRIMARY := Color(0.97, 0.93, 0.85)
const TEXT_SECONDARY := Color(0.80, 0.73, 0.62)
const ACCENT_GREEN := Color(0.55, 0.80, 0.45)
const ACCENT_RED := Color(0.92, 0.45, 0.40)
## Blorbus's canonical brain-pink skin and darker UI derivations. The 3D
## body uses BLORBUS_SKIN directly; UI surfaces keep the same hue but lower
## luminance so existing pale text retains strong contrast.
const BLORBUS_SKIN := Blorb.BLORBUS_BODY_COLOR
const BLORBUS_EYE := Color(0.615, 0.45, 0.465)
const BLORBUS_PANEL := Color(0.34, 0.18, 0.22, 0.94)
const BLORBUS_RIM := Color(0.95, 0.72, 0.76, 0.30)
# A white outline, not a colored one -- per direct correction, the previous
# BORDER_WOOD (a muddy brown border pairing with the old walnut BUTTON_BG
# below) read as an unwanted skeuomorphic carry-over the design language
# never actually called for. Kept as one shared token (still named for what
# it's used on, not what it looks like) since it's still the border every
# interactive control -- Button, tab_button_stylebox(), slot_highlight_
# stylebox(), UIKit.divider() -- reaches for by default. Also now what
# marks the "focused/active/selected" state on all of those (a heavier
# border width and/or a denser fill, not a color swap) -- ACCENT_GOLD used
# to be that separate signal layered on top of this border, but per direct
# instruction the UI drops yellow/gold entirely and stays strictly
# black-and-white; that constant is gone now, not just unused here.
const BUTTON_BORDER := Color(1, 1, 1, 0.85)
# CTA surfaces derive from Blorbus's skin hue. Hover lifts toward his true
# brain pink; press darkens and densifies like translucent goo compressed
# under a finger. All three remain dark enough for pale text to exceed AA.
const BUTTON_BG := Color(0.39, 0.20, 0.24, 0.88)
const BUTTON_BG_HOVER := Color(0.48, 0.27, 0.31, 0.94)
const BUTTON_BG_PRESSED := Color(0.29, 0.13, 0.17, 0.98)
const BUTTON_BG_DISABLED := Color(0.25, 0.15, 0.18, 0.78)
## Loading is the one UI surface that completely replaces the world rather
## than floating over it. Keeping its opaque backdrop here lets the native
## overlay and the web-export shell share the same Eleblorb palette.
const LOADING_BG := Color(0.035, 0.055, 0.075, 1.0)
const LOADING_TRACK := Color(0.80, 0.73, 0.62, 0.24)
const LOADING_FILL := BLORBUS_SKIN

# All scaled 1.5x from an original 20/24/24/30/36, per direct instruction
# that the whole UI read as too small on a real screen -- since every UI
# surface in the game builds its text through these tokens rather than
# setting its own font sizes, this one change cascades everywhere without
# needing to touch each surface's own font-size calls.
const FONT_CAPTION := 30
const FONT_BODY := 36
const FONT_BUTTON := 36
const FONT_HEADING := 45
const FONT_DISPLAY := 54

# Also scaled 1.5x (from 4/8/16/24/32) alongside the fonts above -- padding/
# gaps sized for the old, smaller type would read as cramped once the text
# sharing that space got bigger, not just proportionally smaller-looking.
const SPACE_XS := 6
const SPACE_SM := 12
const SPACE_MD := 24
const SPACE_LG := 36
const SPACE_XL := 48

# Upper caps on proportional curvature. These are deliberately generous:
# the former 48/24 caps made large panels and 66px controls technically use
# SuperellipseStyleBox while still reading as ordinary rounded rectangles.
# The ratio remains the primary sizing rule; these only keep very large
# surfaces from becoming full capsules or blobs.
const PANEL_CORNER_RADIUS := 144
const BUTTON_CORNER_RADIUS := 48
const BUTTON_MIN_HEIGHT := 66  # touch/gamepad-friendly target
const CHIP_CORNER_RADIUS := 999  # fully rounded "pill" ends for compact stat badges

# Shared Lame-curve exponent for every SuperellipseStyleBox in the game (see
# that class for the geometry) -- one number so every background, from a
# tiny chip to the shop's near-fullscreen panel, reads as the same shape
# language. 3.0 retains the accelerating Lame curve that distinguishes a
# squircle from a circular rounded corner, while feeling softer and more
# organic than the former boxier 4.0 treatment.
const SUPERELLIPSE_EXPONENT := 3.0

# Corner radius as a fraction of a box's own shorter side (see
# SuperellipseStyleBox.corner_ratio) -- the other half of the fix above.
# This is what actually keeps the curve bold and clearly visible regardless
# of the element's absolute size: a button and a giant modal both read as
# "the same amount of corner," proportionally, up to the PANEL/BUTTON
# _CORNER_RADIUS cap. Not applied to chip_stylebox(), which wants a pill
# regardless of size, not a proportionally-rounded rect.
const SUPERELLIPSE_RATIO := 0.46
## Inventory is intentionally softer and more organic than the rest of the
## UI: these values pull both Blorbus's modal skin and its recessed sockets
## closer to rounded, living forms while retaining a superellipse silhouette.
const INVENTORY_SUPERELLIPSE_EXPONENT := 2.25
const INVENTORY_SUPERELLIPSE_RATIO := 0.44
const INVENTORY_SLOT_CORNER_RADIUS := 72
const FOCUS_RING_WIDTH := 4
const FOCUS_RING_OFFSET := 7.0

static var _cached: Theme = null


static func get_theme() -> Theme:
	if _cached != null:
		return _cached
	var theme := Theme.new()

	theme.set_font_size("font_size", "Label", FONT_BODY)
	theme.set_color("font_color", "Label", TEXT_PRIMARY)

	theme.set_font_size("font_size", "Button", FONT_BUTTON)
	theme.set_color("font_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_hover_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_pressed_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_focus_color", "Button", TEXT_PRIMARY)
	theme.set_color("font_disabled_color", "Button", TEXT_SECONDARY)
	theme.set_stylebox("normal", "Button", _button_stylebox(BUTTON_BG, BUTTON_BORDER, 3))
	theme.set_stylebox("hover", "Button", _button_stylebox(BUTTON_BG_HOVER, BUTTON_BORDER, 3))
	theme.set_stylebox("pressed", "Button", _button_stylebox(BUTTON_BG_PRESSED, BUTTON_BORDER, 3))
	var disabled_box := _button_stylebox(BUTTON_BG_DISABLED, Color(1, 1, 1, 0.34), 2)
	disabled_box.inner_rim_color = Color(BLORBUS_RIM, 0.12)
	theme.set_stylebox("disabled", "Button", disabled_box)
	theme.set_stylebox("focus", "Button", focus_ring_stylebox())

	theme.set_stylebox("panel", "PanelContainer", _panel_stylebox())

	_cached = theme
	return theme


static func panel_stylebox() -> SuperellipseStyleBox:
	return _panel_stylebox()


static func blorbus_panel_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = BLORBUS_PANEL
	# Inventory is the curviest large surface in the system: a lower
	# exponent approaches an ellipse more closely, and the larger cap lets
	# that curvature remain visible at modal scale. Deliberately no border,
	# inset rim, or shadow -- Blorbus's color/silhouette carry the surface.
	box.corner_radius = 144
	box.corner_ratio = 0.48
	box.exponent = INVENTORY_SUPERELLIPSE_EXPONENT
	box.set_content_margin_all(SPACE_MD)
	return box


static func _panel_stylebox() -> SuperellipseStyleBox:
	# No border stroke, per direct instruction -- the drop shadow alone
	# carries the depth cue a modal background needs; a panel is a
	# passive container, not an interactive control, so it doesn't need
	# the edge definition a Button's border gives for click affordance.
	var box := SuperellipseStyleBox.new()
	box.bg_color = BG_PANEL
	box.corner_radius = PANEL_CORNER_RADIUS
	box.corner_ratio = SUPERELLIPSE_RATIO
	box.exponent = SUPERELLIPSE_EXPONENT
	box.shadow_size = 9
	box.shadow_color = Color(0, 0, 0, 0.35)
	box.set_content_margin_all(SPACE_MD)
	return box


static func _button_stylebox(bg: Color, border: Color, border_width: int) -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = bg
	box.border_color = border
	box.border_width = border_width
	box.corner_radius = BUTTON_CORNER_RADIUS
	box.corner_ratio = SUPERELLIPSE_RATIO
	box.exponent = SUPERELLIPSE_EXPONENT
	box.content_margin_left = SPACE_MD
	box.content_margin_right = SPACE_MD
	box.content_margin_top = SPACE_SM
	box.content_margin_bottom = SPACE_SM
	box.inner_rim_color = BLORBUS_RIM
	box.inner_rim_width = 2.0
	box.inner_rim_inset = 3.0
	return box


## Browser-like keyboard/controller focus: a white squircle drawn a fixed
## distance outside the control instead of replacing its normal surface.
## Keeping this separate from active/selected styling lets both states read
## at once (for example, a focused active tab or selected inventory slot).
static func focus_ring_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = Color.WHITE
	box.border_width = FOCUS_RING_WIDTH
	box.corner_radius = BUTTON_CORNER_RADIUS + FOCUS_RING_OFFSET
	box.corner_ratio = SUPERELLIPSE_RATIO
	box.exponent = SUPERELLIPSE_EXPONENT
	box.outset = FOCUS_RING_OFFSET
	return box


## Compact "pill" background for a short, never-wrapping stat readout (a
## coin count, etc) -- distinct from panel_stylebox() so it reads as a
## small badge sitting in a layout, not another full modal panel. Same
## background treatment as an ordinary panel now (BG_PANEL, no border) --
## per direct correction, this used to be an opaque BUTTON_BG with a wood
## border, which read as a separate, heavier "button-like" chip rather
## than matching the rest of the design language's borderless/translucent
## panels. Padding increased (SPACE_MD on every side, not just left/right)
## since the tight SPACE_XS vertical margin read as crowding the text.
static func chip_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = BG_PANEL
	box.corner_radius = CHIP_CORNER_RADIUS
	box.exponent = SUPERELLIPSE_EXPONENT
	# No corner_ratio -- CHIP_CORNER_RADIUS (999) already clamps to a full
	# pill at any size on its own; a proportional ratio would work against
	# that and make the pill only partially rounded instead.
	box.set_content_margin_all(SPACE_MD)
	return box


static func loading_progress_stylebox(color: Color) -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = color
	box.corner_radius = CHIP_CORNER_RADIUS
	box.exponent = SUPERELLIPSE_EXPONENT
	return box


## ---- Design language ----------------------------------------------
## Conventions every UI surface in this project (Hud, DialogUI, ShopUI,
## InventoryUI, and any future one) should follow. Build through UITheme/
## UIKit rather than hand-rolled Control.new() + ad hoc styling; if a
## genuinely new pattern is needed, add it here/to UIKit (not inline in
## the calling script) so it stays reusable and this list stays current.
##
## Every FONT_*/SPACE_* token, plus BUTTON_MIN_HEIGHT/PANEL_CORNER_RADIUS/
## BUTTON_CORNER_RADIUS and the border widths/shadow size hardcoded around
## this file, was scaled up 1.5x in one pass per direct instruction that the
## whole UI read as too small on a real screen. Any UI surface that reads
## its sizes through these tokens (which is the whole point of building
## through UITheme/UIKit rather than ad hoc styling -- see above) picked
## this up automatically; a handful of surfaces with their own hardcoded
## pixel constants (InventoryUI's SLOT_SIZE/BLORB_PORTRAIT_SIZE, DialogUI's
## panel width, Hud's readout widths) needed their own matching 1.5x update
## alongside this file's. Keep
## that relationship in mind for any *new* hardcoded pixel constant: prefer
## expressing it in terms of an existing token (see UIKit.direction_hint()'s
## icon_size := UITheme.FONT_BODY * 1.5 for the pattern) so a future
## whole-UI rescale doesn't need to go hunt it down by hand again.
##
## 1. Panels (and chips/badges/inventory slots -- anything that's a
##    passive background rather than an action the player takes) are
##    translucent, not heavily opaque, and carry no border stroke --
##    BG_PANEL's alpha and the shadow-only depth cue in _panel_stylebox()
##    are the reference; chip_stylebox()/slot_stylebox() reuse BG_PANEL
##    directly so every passive surface in the game matches. Buttons that
##    are genuinely actions the player clicks (dialogue/purchase choices,
##    not an inventory slot that happens to be a Button node for its own
##    reasons) keep a border: they need edge definition for click
##    affordance, which a passive background doesn't. That border is
##    BUTTON_BORDER (a white outline) over translucent Blorbus-pink goo,
##    not a painted-wood pairing. Keyboard/controller focus adds the separate
##    outside white ring from rule 13, while active/selected state uses fill
##    density and border weight so the signals remain distinguishable.
## 2. Never anchor a top-level, dynamically-sized Control with
##    set_anchors_and_offsets_preset(..., PRESET_MODE_KEEP_SIZE, ...) --
##    it snapshots the control's *current* size to compute offsets, and a
##    freshly-built control hasn't been through a layout pass yet (reads
##    as zero-size), which has silently mis-anchored several things this
##    way already. Use UIKit.anchor_to_edge() instead -- it's correct
##    regardless of when layout actually happens.
## 3. Any Label that must stay on one line inside a flexible row (next to
##    other controls in an HBoxContainer, not a standalone block of text)
##    needs explicit non-wrap protection: UIKit.inline_caption() or
##    UIKit.stat_badge(), not the default caption_label()/body_label().
##    caption_label()'s autowrap is correct for text of unpredictable
##    length (item descriptions) but a cramped row can squeeze a wrapping
##    label down to the point where it renders one character per line --
##    confirmed in both header readouts and short inline status copy.
## 4. Icon-style dismiss controls (closing a window-style modal) use a
##    small drawn icon (UIKit.close_button()), not a Unicode glyph
##    standing in for one. Text buttons (UIKit.button()) are for genuine
##    CTAs, not window chrome or dialogue responses (see rule 16).
## 5. A passive HUD readout whose info is also available on demand
##    elsewhere (the Tokoins count: also visible in ShopUI/InventoryUI)
##    fades in briefly on a relevant change and back out, rather than
##    staying permanently on screen as chrome.
## 6. Every UI shape in the game -- panel, button, chip, inventory slot,
##    dialog box, shop row, even a thin section divider -- is a superellipse
##    ("squircle"), never a plain rectangle or a circular-arc rounded
##    rectangle. This applies project-wide, not just to the four stylebox
##    functions below: SuperellipseStyleBox.boundary_points() is the one
##    corner-geometry function in the game (see that file), and anything
##    that isn't a StyleBox but still needs the shape -- UIKit.Divider is
##    the existing example -- calls it directly rather than falling back to
##    a ColorRect/Panel or hand-rolling its own rounding. StyleBoxFlat's
##    corner_radius never substitutes for this. SUPERELLIPSE_EXPONENT is
##    shared by every instance so the whole game reads as one consistent
##    shape language -- don't pass a bespoke exponent per surface. A new
##    background or bar needs a *radius* choice (how much of the corner
##    curves), not a decision about whether to use the shape at all. That
##    radius should default to corner_ratio (SUPERELLIPSE_RATIO), not a bare
##    fixed pixel corner_radius -- a fixed radius sized for one surface
##    reads as basically square on anything meaningfully bigger (confirmed:
##    the original 6-8px radius was invisible on a 168x152 inventory slot).
##    corner_radius still matters as the cap that keeps a huge panel from
##    rounding itself into a blob; chip_stylebox() is the one deliberate
##    exception (no ratio, always a full pill via corner_radius=999).
## 7. An item's on-screen representation (an inventory slot, shop row, or
##    elemental-gem socket) is a cached photograph of the same procedural 3D
##    geometry used in the world, never an icon or color swatch standing in
##    for it. Portrait stages reserve their final size but remain empty until
##    the real render resolves, so loading never flashes a false substitute.
## 8. An active guidance affordance (UIKit.direction_hint() -- the rotating
##    arrow pointing toward the nearest not-yet-partied wild blorb) is
##    distinct from a passive readout (rule 5 above): it stays on screen
##    for as long as there's somewhere it can usefully point, rather than
##    flashing briefly on a value change, since the player is meant to
##    actually orient by it while exploring, not just glance at a status
##    update. Still wrapped in the same translucent chip_stylebox() pill
##    every compact HUD badge uses, for the same legibility-over-the-3D-
##    scene reason.
## 9. A view switch inside one modal panel (InventoryUI's Items/Blorbs tabs)
##    is two ordinary UIKit.tab_button()s in a row, not Godot's built-in
##    TabContainer -- keeps the same hand-built superellipse/theme language
##    as everything else instead of pulling in that control's own separate
##    look. The active tab is marked by tab_button_stylebox()'s heavier border
##    (rule 1's border-for-interactive-affordance convention, reused rather
##    than inventing a new "selected" treatment), and switching swaps which
##    content container is visible rather than rebuilding the panel.
## 10. A full-panel modal (ShopUI, InventoryUI) is sized off the viewport
##     with a fixed pixel margin (set_anchors_preset(PRESET_FULL_RECT) plus
##     equal offset_left/right/top/bottom, ShopUI's own 100/100/70/70), not
##     UIKit.anchor_to_edge()'s shrink-to-content sizing -- that sizing is
##     right for a compact HUD readout or a chip, but a full task surface
##     needs a size that holds steady regardless of which internal view
##     (tab, list state) happens to be showing, with real room budgeted for
##     future sections rather than a box that re-fits itself every time
##     content changes. Content that can outgrow a fixed height (an item
##     grid, a party list, a buy/sell column) sits inside its own
##     ScrollContainer with size_flags_vertical = SIZE_EXPAND_FILL, so it's
##     the inner list that scrolls, never the panel that grows.
## 11. A game-data value the player should be able to compare at a glance
##     against its own max (a blorb's stat) is a proportional meter bar
##     (UIKit.stat_meter()), not a bare number in a stat_badge() pill --
##     rule 7's "resembles the real thing" logic extended to numbers: a
##     meter shows relative magnitude the way a badge's digits can't
##     without being read and compared one at a time. Depletable resources
##     add current/max copy and a quiet full-capacity track; fixed comparison
##     stats retain only their proportional foreground datum.
## 12. No explanatory prompt text in any UI surface -- per direct
##     instruction, a panel doesn't get an instructional sentence at its
##     top explaining how to use it (InventoryUI's Blorbs tab once had "Your
##     party. Click a blorb, then click a body part on the right to equip
##     it..."; removed, along with the Items tab's own equivalent). The UI
##     itself has to read clearly enough on its own -- affordance (a real
##     Button with hover/pressed states, per rule 1) instead of a caption
##     explaining what to click. This doesn't cover every caption_label() in
##     the game: a genuine empty-state message ("No blorbs in your party
##     yet.", ShopUI's "Nothing to sell.") is reporting actual current
##     state, not teaching operation, and stays. Keyboard/controller prompts
##     do not appear inside menus; focus, placement, and consistent controls
##     communicate operation without device-specific instructional copy. The
##     line to hold is "teaches how to use this screen" vs. "reports what's
##     actually going on right now" -- only the former is what this rule
##     removes.
## 13. Keyboard/controller focus is a white squircle ring consistently
##     offset outside the focused control. It never replaces the control's
##     selected/active surface, so focus and selection remain distinguishable.
##     An open modal must always retain a valid focus owner after selection,
##     deselection, list rebuilding, removal, or tab changes.
## 14. Blorbus is the diegetic owner of Inventory: its modal uses his
##     translucent brain-pink skin with an especially soft, curving
##     silhouette and no decorative stroke or shadow. Genuine CTA buttons
##     across every surface use the same psychic-goo material family, while
##     passive panels and inventory sockets retain their quieter roles.
## 15. World interaction prompts name the available action and object only
##     ("Talk", "Pick up orange"). They never repeat a keyboard/controller
##     binding; proximity and placement already communicate that they are
##     actionable, and bindings may differ by input device.
## 16. Dialog choices are the player's spoken lines, not CTA buttons. They
##     live in a separate bottom-right response panel, stack vertically with
##     right-aligned text, and use a drawn left-pointing arrow in a permanently
##     reserved right margin as their sole selection marker. Focus never
##     changes the text column's width or alignment. While present, they own
##     movement and action input through UIState like every other modal.
## 17. The Blorb paper doll navigates spatially, never by an arbitrary slot
##     cycle. White is focus; psychic pink exclusively means a Blorb selected
##     for assignment. Committing a portrait transfers focus to its assigned
##     limb (or Head when unassigned). A body part is bright only while the
##     doll owns focus; X on the same limb and pointer misses are non-destructive.
##     Dimmed pieces retain their element hue at reduced value with emission
##     suppressed. The limb label exists only while a body part owns focus.
##     Removal is a conditional middle-right node in the doll's spatial
##     navigation, targeting only the currently selected, assigned Blorb—never
##     an incidental consequence of selecting a piece or missing the figure.
## 18. Blorb identity uses a permanent, passive elemental-gem socket rather
##     than a type badge. An empty socket means Normal; Blorbus's empty socket
##     is his inherent Psychic exception. Blank names fall back to lowercase
##     elemental names and Blorbus's true name is fixed. Custom-name data
##     remains available, but names are passive labels until editing receives
##     a dedicated interaction flow.
## 19. Distinct information and controls use SPACE_SM as their minimum visual
##     separation. SPACE_XS is reserved for details that form one tight
##     composite, never as the default gap between independent elements.
## 20. A HUD readout that's just an existing composite control (e.g.
##     UIKit.stat_meter()) needing a background wraps it in
##     UIKit.backed_control() rather than a bespoke PanelContainer built
##     inline -- the player HP readout (Hud) is the reference: same panel
##     styling as backed_readout()/tokoin_badge(), arbitrary child instead
##     of a fixed Label/icon+Label layout.
## 21. Initial boot and in-world travel use one loading state model and one
##     visual language. On web, the browser overlay remains in charge until
##     the game explicitly reports world readiness; the Godot overlay does
##     not briefly replace it. Native boot and later portal travel use the
##     matching UIKit surface. Loading hints follow actual input capability
##     (touch, controller, or keyboard/mouse), never viewport width alone.
## 22. A modal Back/cancel action that semantically chooses a visible decline
##     response must briefly move focus to that response before dismissal.
##     The established response arrow and focused text provide confirmation;
##     the panel remains visible for a fraction of a second so cancel never
##     feels like an unacknowledged disappearance or an ambiguous selection.
## 23. A creature transformation is a full-screen, input-locked presentation,
##     not a transient HUD toast over live danger. It reuses the creature's
##     real three-quarter portrait, makes the whiteout the hidden state-change
##     boundary, and keeps status copy in the standard passive panel language.
##     The backdrop and light plane may fill the rectangular viewport because
##     they represent the replaced world/frame, not bounded interface shapes.
## 24. Character-facing menu tabs share one live paper-doll surface rather
##     than constructing parallel portraits. Wide layouts keep contextual
##     content at left and the doll at right; compact portrait layouts move
##     that same doll above the independently scrolling content. A tab changes
##     the doll's interaction layer (equipment editing versus inspection), not
##     its renderer, camera, visual language, or responsive implementation.


## An inset, recessed-looking cell for an inventory grid slot -- darker
## than the surrounding panel (like a socket something sits in) rather than
## a raised button, so an *empty* slot doesn't read as an inviting,
## clickable control the way the shared Button stylebox would. No border,
## matching the panel's own stroke-free treatment -- the darker fill alone
## reads as recessed against the lighter panel behind it.
static func slot_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = Color(0, 0, 0, 0.28)
	box.corner_radius = INVENTORY_SLOT_CORNER_RADIUS
	box.corner_ratio = INVENTORY_SUPERELLIPSE_RATIO
	box.exponent = INVENTORY_SUPERELLIPSE_EXPONENT
	return box


## The bordered highlight a held inventory slot or selected Blorb portrait
## uses in place of slot_stylebox(). Its brain-pink fill belongs to Blorbus's
## psychic palette rather than the old brown panel family; the white edge
## still keeps selection distinct from controller/keyboard focus.
static func slot_highlight_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = SELECTION_BG
	box.border_color = BUTTON_BORDER
	box.border_width = 5
	box.corner_radius = INVENTORY_SLOT_CORNER_RADIUS
	box.corner_ratio = INVENTORY_SUPERELLIPSE_RATIO
	box.exponent = INVENTORY_SUPERELLIPSE_EXPONENT
	box.set_content_margin_all(SPACE_MD)
	return box


## Focus ring matching the more deeply curved inventory sockets. Keeping the
## same geometry plus the standard fixed outset prevents focus from snapping
## back to the sharper global button silhouette.
static func slot_focus_ring_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = Color.WHITE
	box.border_width = FOCUS_RING_WIDTH
	box.corner_radius = INVENTORY_SLOT_CORNER_RADIUS + FOCUS_RING_OFFSET
	box.corner_ratio = INVENTORY_SUPERELLIPSE_RATIO
	box.exponent = INVENTORY_SUPERELLIPSE_EXPONENT
	box.outset = FOCUS_RING_OFFSET
	return box


## The paper doll is a large visual field, so its focus outline uses the
## inventory modal's broad organic curvature rather than a button-scale
## squircle stretched across the viewport.
static func portrait_focus_ring_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = Color.WHITE
	box.border_width = FOCUS_RING_WIDTH
	box.corner_radius = 151
	box.corner_ratio = 0.48
	box.exponent = 2.1
	box.outset = FOCUS_RING_OFFSET
	return box


## Passive elemental identity socket: nearly circular, while retaining a
## subtly organic superellipse silhouette.
static func elemental_gem_socket_stylebox() -> SuperellipseStyleBox:
	var box := SuperellipseStyleBox.new()
	box.bg_color = Color(0, 0, 0, 0.34)
	box.corner_radius = 999
	box.corner_ratio = 0.49
	box.exponent = 2.1
	box.set_content_margin_all(SPACE_XS)
	return box


static func name_field_stylebox() -> SuperellipseStyleBox:
	return _button_stylebox(BUTTON_BG, BUTTON_BORDER, 3)


static func name_field_focus_stylebox() -> SuperellipseStyleBox:
	var box := _button_stylebox(BUTTON_BG, Color.WHITE, FOCUS_RING_WIDTH)
	box.outset = FOCUS_RING_OFFSET
	return box


## A tab-switch button's own stylebox variant (InventoryUI's Items/Blorbs
## switch -- see design language item 9 below) -- same shape/size as an
## ordinary button, just with the active tab getting a heavier white border
## (5px vs. an ordinary button's 3px) and denser fill (BUTTON_BG_PRESSED,
## not BUTTON_BG) than an ordinary button otherwise reserves for keyboard
## focus, so which tab is showing reads at a glance without a separate
## indicator. Both branches use the same BUTTON_BORDER white now (was
## ACCENT_GOLD for the active branch) -- per direct instruction, no yellow/
## gold anywhere in the UI; weight and fill density carry the "active"
## signal instead of a color swap.
static func tab_button_stylebox(active: bool) -> SuperellipseStyleBox:
	return _button_stylebox(
		BUTTON_BG_PRESSED if active else BUTTON_BG,
		BUTTON_BORDER,
		5 if active else 3
	)
