extends CanvasLayer

## Minecraft-style inventory: select a slot to hold that item (see
## held_item.gd) -- selecting doesn't remove it from
## Inventory, only actually throwing it does. A full modal like
## Dialog/Shop (blocks movement and camera-look, not just look) -- browsing
## while still walking around blind isn't worth the extra complexity of a
## partial-block mode.
##
## The grid always shows at least MIN_ROWS of slots, empty ones included
## (a real inset "socket" background, not a Button -- see UITheme.
## slot_stylebox()) -- a Minecraft-style inventory reads as a fixed grid of
## sockets some of which happen to be full, not a bare list that only
## exists when you own something. Extra items scroll rather than growing
## the grid past MIN_ROWS -- see the panel-sizing note below.
##
## A second Blorbs tab (see UITheme's design language item 9) sits alongside
## the item grid, showing the party row by row -- portrait, name/type,
## equipped core items, and stat meters (design language item 11; see
## blorb.gd's own stats fields).
##
## The panel itself is sized off the viewport with a fixed margin (design
## language item 10), matching ShopUI's own modal exactly, rather than
## shrink-wrapping around whichever tab happens to be showing -- per direct
## instruction, this needs to hold one consistent size regardless of which
## tab is active (with real room to grow into for future menu sections),
## not resize/jump on every tab switch. Each tab's own content sits in a
## ScrollContainer that fills the remaining fixed space, so a party or item
## collection that outgrows the panel scrolls in place instead of growing it.

# COLUMNS is no longer a fixed guess -- per direct feedback, a static 3
# left most of the panel's own real width empty (it was originally tuned
# for the small pre-type-scale panel, then just re-guessed smaller after
# the type scale rather than actually measured against the new, much wider
# fixed panel). _update_grid_columns() computes the real count from the
# scroll region's own measured width instead, so it always uses exactly as
# much of the panel as SLOT_SIZE actually allows. MIN_START_COLUMNS is only
# the very first frame's fallback, before any real layout has happened.
const MIN_START_COLUMNS := 3
const MIN_ROWS := 3
# Wide/tall enough for a real item icon plus a two-to-three-line item name
# (e.g. "Sealed Reliquary Locket") without cramming -- per direct
# instruction to give names as much room as ShopUI's rows get, not just
# enough for a one-word label. Scaled 1.5x (168x152 -> 252x228) alongside
# every other size in the whole-UI type-scale pass.
const SLOT_SIZE := Vector2(252, 228)
## ScrollContainer clips its children at its viewport edge. Reserve enough
## space for the slot focus ring's outward outset plus stroke on every side.
const SLOT_FOCUS_INSET := 12
## Large enough to read as a party portrait while still sharing the Blorbs
## tab's half-width column with identity at the default/mobile layout. The
## former 210px portrait alone consumed over half the card's usable width and
## forced every stat behind the neighboring paper doll.
const BLORB_PORTRAIT_SIZE := 144.0
const BOUND_ITEM_SLOT_SIZE := Vector2(168, 156)
## Per direct correction -- 120/210 clipped labels like "MP: 100/120" once a
## blorb's stats grew past a couple of digits each.
const BLORB_METER_LABEL_WIDTH := 170.0
const BLORB_METER_BAR_WIDTH := 260.0
const ITEM_HELD_FEEDBACK_DURATION := 1.6

var _panel: PanelContainer
var _coin_readout: PanelContainer
var _grid: GridContainer
var _items_scroll: ScrollContainer
var _items_tab: Control
var _blorbs_tab: Control
var _player_tab: Control
var _blorb_scroll: ScrollContainer
var _blorb_list: VBoxContainer
var _blorbs_layout: GridContainer
var _blorbs_info_panel: PanelContainer
var _blorbs_portrait_host: Control
var _player_layout: GridContainer
var _player_info_panel: PanelContainer
var _player_portrait_host: Control
var _paper_doll_shell: Control
var _portrait_container: Control
var _portrait_button: Button
var _portrait_remove_button: Button
var _release_button: Button
var _portrait_slot_label: Label
var _portrait_player_id: int = 0
var _focused_body_slot: String = "head"
var _portrait_stick_latched: bool = false
var _focus_restore_item_name: String = ""
var _focus_restore_blorb_id: int = 0
var _focus_restore_blorb_attempts: int = 0
var _last_blorb_focus_id: int = 0
var _items_tab_button: Button
var _blorbs_tab_button: Button
var _player_tab_button: Button
var _player_stats: VBoxContainer
var _item_held_feedback: PanelContainer
var _item_held_feedback_timer: float = 0.0
var _active_tab: String = "items"
var _open: bool = false
## The blorb currently selected in the left-hand party list -- clicking a
## slot region on the right-hand paper-doll equips this blorb there;
## clicking outside the body unequips it from wherever it's currently
## worn (a no-op if it isn't worn anywhere). Cleared whenever the tab
## refreshes and the selected blorb is no longer in the party (left, or
## the list was rebuilt) -- see _refresh_blorbs().
var _selected_blorb: Blorb = null

## Confirmation shown by "Release to the Wild" before actually removing a
## party member -- see _confirm_release_selected_blorb()/_on_release_
## confirmed(). Kept as a small in-place overlay (not routed through
## DialogUI) so it doesn't fight InventoryUI's own higher CanvasLayer for
## stacking order the way DialogUI's speech panel would.
var _release_confirm_panel: PanelContainer
var _release_confirm_label: Label
var _release_confirm_buttons: Array[Button] = []
var _release_confirm_target: Blorb = null


func _ready() -> void:
	# Inventory is the dominant in-game menu surface: it must occlude any
	# lingering NPC dialogue or shop UI, while Pause remains above it.
	layer = 35
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	TokoinWallet.changed.connect(_on_wallet_changed)
	Inventory.changed.connect(_refresh)
	# So the held-slot highlight (see _build_slot's is_held check) actually
	# updates the moment you click to hold/unhold something, not just on the
	# next Inventory.changed (add/remove) or the next time the panel opens --
	# clicking a slot only ever changes HeldItem, never Inventory itself.
	HeldItem.changed.connect(_refresh)


func _build_ui() -> void:
	var shared_theme := UITheme.get_theme()

	_panel = UIKit.panel()
	_panel.theme = shared_theme
	_panel.add_theme_stylebox_override("panel", UITheme.blorbus_panel_stylebox())
	# Viewport-relative fixed size, matching ShopUI's own modal exactly
	# (same 100/100/70/70 margins) -- see design language item 10 for why
	# this replaced UIKit.anchor_to_edge()'s shrink-to-content sizing.
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = 100
	_panel.offset_right = -100
	_panel.offset_top = 70
	_panel.offset_bottom = -70
	_panel.visible = false
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_LG)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SPACE_MD)
	margin.add_child(vbox)

	# One reserved three-column header keeps the functional controls level
	# with Blorbus's eyes instead of making the eyes consume their own row.
	# Equal expanding cells keep the eyes truly centered while the left and
	# right groups align to their respective edges without overlapping them.
	var header_inset := MarginContainer.new()
	header_inset.add_theme_constant_override("margin_bottom", UITheme.SPACE_SM)
	vbox.add_child(header_inset)

	var header := GridContainer.new()
	header.columns = 3
	header.add_theme_constant_override("h_separation", UITheme.SPACE_MD)
	header_inset.add_child(header)

	var left_header := HBoxContainer.new()
	left_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_header.add_theme_constant_override("separation", UITheme.SPACE_MD)
	header.add_child(left_header)
	var title := UIKit.heading("Inventory")
	left_header.add_child(title)
	_items_tab_button = UIKit.tab_button("Items", true, func(): _switch_tab("items"))
	_blorbs_tab_button = UIKit.tab_button("Blorbs", false, func(): _switch_tab("blorbs"))
	_player_tab_button = UIKit.tab_button("Player", false, func(): _switch_tab("player"))
	left_header.add_child(_items_tab_button)
	left_header.add_child(_blorbs_tab_button)
	left_header.add_child(_player_tab_button)

	var eyes_cell := CenterContainer.new()
	eyes_cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(eyes_cell)
	eyes_cell.add_child(UIKit.blorbus_eyes())

	var right_header := HBoxContainer.new()
	right_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_header.alignment = BoxContainer.ALIGNMENT_END
	right_header.add_theme_constant_override("separation", UITheme.SPACE_MD)
	header.add_child(right_header)
	# Matches ShopUI's own header exactly -- a live tokoin readout embedded
	# directly in this panel (see _on_wallet_changed below), not a separate
	# HUD overlay this modal would otherwise have to coordinate with.
	_coin_readout = UIKit.tokoin_badge(TokoinWallet.value, UITheme.TEXT_PRIMARY)
	right_header.add_child(_coin_readout)
	right_header.add_child(UIKit.close_button(_close))

	# Both tabs' content sits in the same fixed remaining space (SIZE_
	# EXPAND_FILL) -- switching tabs only ever swaps which one is visible,
	# never the panel's own size.
	_items_tab = VBoxContainer.new()
	(_items_tab as VBoxContainer).add_theme_constant_override("separation", UITheme.SPACE_MD)
	_items_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_items_tab)

	_items_scroll = ScrollContainer.new()
	_items_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_items_scroll.resized.connect(_update_grid_columns)
	_items_tab.add_child(_items_scroll)
	var grid_inset := MarginContainer.new()
	grid_inset.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_inset.add_theme_constant_override("margin_left", SLOT_FOCUS_INSET)
	grid_inset.add_theme_constant_override("margin_right", SLOT_FOCUS_INSET)
	grid_inset.add_theme_constant_override("margin_top", SLOT_FOCUS_INSET)
	grid_inset.add_theme_constant_override("margin_bottom", SLOT_FOCUS_INSET)
	_items_scroll.add_child(grid_inset)
	_grid = GridContainer.new()
	_grid.columns = MIN_START_COLUMNS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", UITheme.SPACE_MD)
	_grid.add_theme_constant_override("v_separation", UITheme.SPACE_MD)
	grid_inset.add_child(_grid)

	_blorbs_tab = VBoxContainer.new()
	(_blorbs_tab as VBoxContainer).add_theme_constant_override("separation", UITheme.SPACE_MD)
	_blorbs_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_blorbs_tab.visible = false
	vbox.add_child(_blorbs_tab)

	# Left half: the party list (scrolls). Right half: the full-size player
	# paper-doll (see player_portrait.gd) -- per direct instruction, this
	# reserves the panel's whole right half rather than the earlier flat
	# spacer per row, and the two columns share the tab's remaining fixed
	# height equally via stretch ratio, not a fixed pixel split, so the
	# 50/50 layout holds regardless of the panel's own actual width.
	_blorbs_layout = GridContainer.new()
	_blorbs_layout.add_theme_constant_override("h_separation", UITheme.SPACE_MD)
	_blorbs_layout.add_theme_constant_override("v_separation", UITheme.SPACE_MD)
	_blorbs_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_blorbs_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_blorbs_tab.add_child(_blorbs_layout)

	_blorbs_info_panel = UIKit.scroll_panel()
	_blorbs_info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_blorbs_info_panel.size_flags_stretch_ratio = 1.0
	_blorbs_info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_blorbs_layout.add_child(_blorbs_info_panel)
	_blorb_scroll = ScrollContainer.new()
	_blorb_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_blorb_scroll.size_flags_stretch_ratio = 1.0
	_blorb_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_blorb_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_blorb_scroll.follow_focus = true
	_blorbs_info_panel.add_child(_blorb_scroll)
	# A ScrollContainer clips at its viewport edge. Give rows a real gutter
	# larger than the outside-offset focus ring so neither their squircle
	# sides nor highlight can be cut off while scrolling.
	var blorb_scroll_margin := MarginContainer.new()
	var focus_gutter := int(ceil(UITheme.FOCUS_RING_OFFSET + UITheme.FOCUS_RING_WIDTH + 3.0))
	blorb_scroll_margin.add_theme_constant_override("margin_left", focus_gutter)
	blorb_scroll_margin.add_theme_constant_override("margin_right", focus_gutter)
	blorb_scroll_margin.add_theme_constant_override("margin_top", focus_gutter)
	blorb_scroll_margin.add_theme_constant_override("margin_bottom", focus_gutter)
	blorb_scroll_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_blorb_scroll.add_child(blorb_scroll_margin)
	_blorb_list = VBoxContainer.new()
	_blorb_list.add_theme_constant_override("separation", UITheme.SPACE_MD)
	_blorb_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	blorb_scroll_margin.add_child(_blorb_list)

	_blorbs_portrait_host = _new_portrait_host()
	_blorbs_layout.add_child(_blorbs_portrait_host)
	_build_portrait_area()
	_build_player_tab(vbox)
	_apply_responsive_layout()
	_build_release_confirm_ui(shared_theme)
	_build_item_held_feedback(shared_theme)


## A single transient confirmation above the inventory panel. Reusing this
## one readout means changing items replaces the previous message and resets
## its lifetime instead of creating a queue or stacking multiple notices.
func _build_item_held_feedback(shared_theme: Theme) -> void:
	_item_held_feedback = UIKit.backed_readout(
		"", UITheme.TEXT_PRIMARY, UITheme.FONT_BODY
	)
	_item_held_feedback.theme = shared_theme
	_item_held_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.anchor_to_edge(
		_item_held_feedback, 0.5, 1.0, 0.0, UITheme.SPACE_XL * 2.0
	)
	_item_held_feedback.visible = false
	add_child(_item_held_feedback)


## Modal panels use a translucent background with no border stroke (a soft
## drop shadow carries the depth cue instead) -- see ui_theme.gd's design
## language. Added as a sibling of _panel, not a descendant, and built last
## so it draws on top of the whole Inventory panel regardless of which tab
## or selection state is showing underneath.
func _build_release_confirm_ui(shared_theme: Theme) -> void:
	_release_confirm_panel = UIKit.panel()
	_release_confirm_panel.theme = shared_theme
	_release_confirm_panel.custom_minimum_size = Vector2(480, 0)
	UIKit.anchor_to_edge(_release_confirm_panel, 0.5, 0.5, 0.0, 0.0)
	_release_confirm_panel.visible = false
	add_child(_release_confirm_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_LG)
	_release_confirm_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SPACE_MD)
	margin.add_child(vbox)

	_release_confirm_label = UIKit.body_label("")
	vbox.add_child(_release_confirm_label)
	vbox.add_child(UIKit.divider())

	var confirm_button := UIKit.button("Release to the Wild", _on_release_confirmed)
	vbox.add_child(confirm_button)
	var cancel_button := UIKit.button("Never mind.", _cancel_release_confirm)
	vbox.add_child(cancel_button)
	_release_confirm_buttons = [confirm_button, cancel_button]


## The portrait is one focusable control, but pointer selection is resolved
## in 3D by PlayerPortrait's Area3D hit volumes. While focused, directional
## input follows the anatomy spatially and the action button assigns the
## selected blorb; moving outward returns focus to adjacent menu controls.
func _new_portrait_host() -> Control:
	var host := Control.new()
	host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host.size_flags_stretch_ratio = 1.0
	host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return host


func _build_portrait_area() -> void:
	_paper_doll_shell = Control.new()
	_paper_doll_shell.name = "SharedPaperDoll"
	_paper_doll_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_blorbs_portrait_host.add_child(_paper_doll_shell)

	_portrait_button = Button.new()
	var area := _portrait_button as Control
	area.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	area.clip_contents = false
	_portrait_button.flat = true
	_portrait_button.add_theme_stylebox_override("focus", UITheme.portrait_focus_ring_stylebox())
	_portrait_button.gui_input.connect(_on_portrait_input)
	_portrait_button.focus_entered.connect(_on_portrait_focus_changed.bind(true))
	_portrait_button.focus_exited.connect(_on_portrait_focus_changed.bind(false))
	_paper_doll_shell.add_child(area)

	_portrait_container = Control.new()
	_portrait_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	area.add_child(_portrait_container)

	_portrait_slot_label = UIKit.inline_caption(BlorbSuit.slot_display_name(_focused_body_slot), UITheme.TEXT_PRIMARY)
	_portrait_slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_slot_label.visible = false
	UIKit.anchor_to_edge(_portrait_slot_label, 0.5, 1.0, 0.0, UITheme.SPACE_LG)
	area.add_child(_portrait_slot_label)

	_portrait_remove_button = UIKit.button("Remove", _remove_selected_assignment)
	_portrait_remove_button.gui_input.connect(_on_remove_input)
	UIKit.anchor_to_edge(
		_portrait_remove_button, 1.0, 0.5, UITheme.SPACE_MD, 0.0
	)
	_paper_doll_shell.add_child(_portrait_remove_button)
	_update_remove_action()

	# Stacked below Remove, sharing its anchor point (anchor_v 0.5 centers with
	# no independent vertical margin -- see anchor_to_edge's own comment) and
	# nudged down by one button height plus a full SPACE_LG gap instead --
	# per direct correction, SPACE_SM read as the two buttons crowding each
	# other rather than as two distinct, separately-considered actions.
	# Visible whenever a non-Blorbus blorb is selected, independent of
	# whether it's currently assigned to a body slot.
	_release_button = UIKit.button("Release to the Wild", _confirm_release_selected_blorb)
	_release_button.gui_input.connect(_on_release_input)
	UIKit.anchor_to_edge(_release_button, 1.0, 0.5, UITheme.SPACE_MD, 0.0)
	_release_button.offset_top += UITheme.BUTTON_MIN_HEIGHT + UITheme.SPACE_LG
	_release_button.offset_bottom += UITheme.BUTTON_MIN_HEIGHT + UITheme.SPACE_LG
	_paper_doll_shell.add_child(_release_button)
	_update_release_action()


func _build_player_tab(parent: Control) -> void:
	_player_tab = VBoxContainer.new()
	_player_tab.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_tab.visible = false
	parent.add_child(_player_tab)

	_player_layout = GridContainer.new()
	_player_layout.add_theme_constant_override("h_separation", UITheme.SPACE_LG)
	_player_layout.add_theme_constant_override("v_separation", UITheme.SPACE_MD)
	_player_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_tab.add_child(_player_layout)
	_player_info_panel = UIKit.scroll_panel()
	_player_info_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_player_info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_layout.add_child(_player_info_panel)
	var player_scroll := ScrollContainer.new()
	player_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	player_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	player_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	player_scroll.follow_focus = true
	_player_info_panel.add_child(player_scroll)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_LG)
	player_scroll.add_child(margin)
	_player_stats = VBoxContainer.new()
	_player_stats.add_theme_constant_override("separation", UITheme.SPACE_MD)
	margin.add_child(_player_stats)

	_player_portrait_host = _new_portrait_host()
	_player_layout.add_child(_player_portrait_host)


## Kueh Machine's character editor keeps one live preview and reparents it
## when its layout changes. Inventory follows that same rule both across
## breakpoints and across the Blorbs/Player contexts: there is only one doll,
## one ViewportTexture, and one set of sizing/focus behavior.
func _apply_responsive_layout() -> void:
	if _panel == null:
		return
	var logical_size := UIKit.logical_viewport_size(self)
	# Touch capability is part of the breakpoint. A high-DPI phone can expose
	# a wide backing viewport even though its usable CSS layout is still a
	# phone-sized, coarse-pointer surface.
	var stacked := UIKit.is_mobile_viewport(self) or logical_size.x < 900.0 or logical_size.y > logical_size.x * 1.15
	var edge_x: float = UITheme.SPACE_MD if stacked else 100.0
	var edge_y: float = UITheme.SPACE_MD if stacked else 70.0
	_panel.offset_left = edge_x
	_panel.offset_right = -edge_x
	_panel.offset_top = edge_y
	_panel.offset_bottom = -edge_y
	_blorbs_layout.columns = 1 if stacked else 2
	_player_layout.columns = 1 if stacked else 2
	var portrait_height := clampf(logical_size.y * 0.34, 250.0, 390.0)
	for host in [_blorbs_portrait_host, _player_portrait_host]:
		host.custom_minimum_size = Vector2(0.0, portrait_height if stacked else 0.0)
		host.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if stacked else Control.SIZE_EXPAND_FILL
	_blorbs_info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_player_info_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# On a stacked layout the doll is the first row; on desktop it is the
	# stable right-hand column. GridContainer lets us reorder the same nodes
	# without building a second mobile screen.
	_blorbs_layout.move_child(_blorbs_portrait_host, 0 if stacked else 1)
	_player_layout.move_child(_player_portrait_host, 0 if stacked else 1)
	_move_shared_paper_doll()


func _move_shared_paper_doll() -> void:
	if _paper_doll_shell == null:
		return
	var target := _player_portrait_host if _active_tab == "player" else _blorbs_portrait_host
	if _paper_doll_shell.get_parent() != target:
		_paper_doll_shell.reparent(target)
	_paper_doll_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var editing_suit := _active_tab == "blorbs"
	_portrait_button.disabled = not editing_suit
	_portrait_button.mouse_filter = Control.MOUSE_FILTER_STOP if editing_suit else Control.MOUSE_FILTER_IGNORE
	if not editing_suit:
		_portrait_slot_label.visible = false
	_update_remove_action()
	_update_release_action()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null and not editing_suit:
		# Player mode is inspection-only: show the committed suit, never the
		# Blorbs tab's temporary selection or anatomical target highlight.
		player.set_portrait_selected_blorb(null)
		player.set_portrait_focused_blorb(null)
		player.set_portrait_body_focus_active(false)
		player.refresh_portrait_assignments()


func _on_portrait_focus_changed(active: bool) -> void:
	_portrait_slot_label.visible = active
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.set_portrait_body_focus_active(active)


func _on_portrait_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_portrait_button.grab_focus()
		_portrait_stick_latched = false
		var mouse_event := event as InputEventMouseButton
		var side: float = minf(_portrait_button.size.x, _portrait_button.size.y)
		var inset: Vector2 = (_portrait_button.size - Vector2.ONE * side) * 0.5
		var local: Vector2 = mouse_event.position - inset
		if local.x < 0 or local.y < 0 or local.x > side or local.y > side:
			_on_outside_clicked()
			return
		var player := get_tree().get_first_node_in_group("player") as Player
		if player != null:
			var slot := player.pick_portrait_slot(local / side * PlayerPortrait.RESOLUTION)
			if slot != "":
				_set_focused_body_slot(slot)
				_on_slot_clicked(slot)
			else:
				_on_outside_clicked()
	elif event is InputEventJoypadMotion:
		var joy_event := event as InputEventJoypadMotion
		if joy_event.axis == JOY_AXIS_LEFT_X or joy_event.axis == JOY_AXIS_LEFT_Y:
			var navigation: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			if navigation.length() <= 0.35:
				_portrait_stick_latched = false
			elif not _portrait_stick_latched:
				_portrait_stick_latched = true
				var horizontal_dominant: bool = absf(navigation.x) > absf(navigation.y)
				var direction := Vector2(signf(navigation.x), 0.0) if horizontal_dominant else Vector2(0.0, signf(navigation.y))
				_move_body_slot(direction)
			_portrait_button.accept_event()
	elif event.is_action_pressed("ui_left"):
		_move_body_slot(Vector2.LEFT)
		_portrait_button.accept_event()
	elif event.is_action_pressed("ui_right"):
		_move_body_slot(Vector2.RIGHT)
		_portrait_button.accept_event()
	elif event.is_action_pressed("ui_up"):
		_move_body_slot(Vector2.UP)
		_portrait_button.accept_event()
	elif event.is_action_pressed("ui_down"):
		_move_body_slot(Vector2.DOWN)
		_portrait_button.accept_event()
	elif event.is_action_pressed("ui_accept"):
		_on_slot_clicked(_focused_body_slot)
		_portrait_button.accept_event()


func _move_body_slot(direction: Vector2) -> void:
	var positions := {
		"head": Vector2(0.0, 0.0), "torso": Vector2(0.0, 1.0),
		# The figure faces the viewer, so anatomical right is on screen-left
		# and anatomical left is on screen-right. Navigation follows what the
		# player sees, while the slot names remain anatomically correct.
		"arm_right": Vector2(-1.0, 1.0), "arm_left": Vector2(1.0, 1.0),
		"leg_right": Vector2(-0.45, 2.0), "leg_left": Vector2(0.45, 2.0),
	}
	var origin: Vector2 = positions[_focused_body_slot]
	var best_slot := ""
	var best_score := INF
	for slot in BlorbSuit.SLOT_ORDER:
		if slot == _focused_body_slot:
			continue
		var delta: Vector2 = positions[slot] - origin
		var forward := delta.dot(direction)
		if forward <= 0.05:
			continue
		var perpendicular := absf(delta.cross(direction))
		var score := perpendicular * 2.0 + delta.length() * 0.25 - forward * 0.1
		if score < best_score:
			best_score = score
			best_slot = slot
	# Remove and Release participate in the same spatial search as the
	# anatomy instead of acting as special-cased escape destinations. Their
	# virtual positions match their stacked middle-right placement in the
	# portrait window (see _build_portrait_area) -- compared against every
	# slot AND each other before anything grabs focus, so whichever is
	# actually closest in the pressed direction wins regardless of which
	# button happens to get checked first.
	var best_button: Button = null
	if _portrait_remove_button.visible:
		var remove_delta := Vector2(1.55, 1.25) - origin
		var remove_forward := remove_delta.dot(direction)
		if remove_forward > 0.05:
			var remove_score := absf(remove_delta.cross(direction)) * 2.0 + remove_delta.length() * 0.25 - remove_forward * 0.1
			if remove_score < best_score:
				best_score = remove_score
				best_button = _portrait_remove_button
	if _release_button.visible:
		var release_delta := Vector2(1.55, 2.0) - origin
		var release_forward := release_delta.dot(direction)
		if release_forward > 0.05:
			var release_score := absf(release_delta.cross(direction)) * 2.0 + release_delta.length() * 0.25 - release_forward * 0.1
			if release_score < best_score:
				best_score = release_score
				best_button = _release_button
	if best_button != null:
		best_button.grab_focus()
	elif best_slot != "":
		_set_focused_body_slot(best_slot)
	else:
		_leave_portrait(direction)


func _leave_portrait(direction: Vector2) -> void:
	if direction == Vector2.UP:
		_blorbs_tab_button.grab_focus()
		return
	if direction != Vector2.LEFT:
		return
	var portrait_buttons := _blorb_list.find_children("*", "Button", true, false)
	if portrait_buttons.is_empty():
		_blorbs_tab_button.grab_focus()
		return
	var target: Button = portrait_buttons[0] as Button
	var return_id := _last_blorb_focus_id
	if _selected_blorb != null:
		return_id = _selected_blorb.get_instance_id()
	if return_id != 0:
		for node in portrait_buttons:
			if int(node.get_meta("blorb_instance_id", 0)) == return_id:
				target = node as Button
				break
	target.grab_focus()


func _set_focused_body_slot(slot: String) -> void:
	_focused_body_slot = slot
	_portrait_slot_label.text = BlorbSuit.slot_display_name(slot)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.set_portrait_highlighted_slot(slot)
	_update_remove_action()


func _update_remove_action() -> void:
	if _portrait_remove_button == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	var can_remove := false
	if player != null and _selected_blorb != null and is_instance_valid(_selected_blorb):
		can_remove = player.get_blorb_suit().slot_for_assigned_blorb(_selected_blorb) != ""
	_portrait_remove_button.visible = _active_tab == "blorbs" and can_remove
	_portrait_remove_button.disabled = not can_remove


func _on_remove_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		_portrait_button.grab_focus()
		_portrait_remove_button.accept_event()
	elif event.is_action_pressed("ui_down") and _release_button.visible:
		# Explicit, not left to Godot's default nearest-focusable-control
		# guess -- per direct report, that default wasn't reliably landing on
		# Release from here, the single most natural next press once a player
		# has already found Remove.
		_release_button.grab_focus()
		_portrait_remove_button.accept_event()


## Visible whenever a non-Blorbus blorb is selected -- unlike Remove, this
## doesn't depend on the currently focused body slot, so party membership
## can be released regardless of whether the blorb happens to be assigned
## to the suit right now.
func _update_release_action() -> void:
	if _release_button == null:
		return
	var can_release := (
		_active_tab == "blorbs"
		and _selected_blorb != null and is_instance_valid(_selected_blorb)
		and not _selected_blorb.is_blorbus
	)
	_release_button.visible = can_release
	_release_button.disabled = not can_release


func _on_release_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		_portrait_button.grab_focus()
		_release_button.accept_event()
	elif event.is_action_pressed("ui_up"):
		if _portrait_remove_button.visible:
			_portrait_remove_button.grab_focus()
		else:
			_portrait_button.grab_focus()
		_release_button.accept_event()


func _remove_selected_assignment() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or _selected_blorb == null or not is_instance_valid(_selected_blorb):
		return
	var suit := player.get_blorb_suit()
	var assigned_slot := suit.slot_for_assigned_blorb(_selected_blorb)
	if assigned_slot == "":
		return
	# Removal completes the selection mode. Remember the exact portrait before
	# clearing selection so the rebuilt list restores focus there—not on the
	# doll or the first Blorb in the list.
	_focus_restore_blorb_id = _selected_blorb.get_instance_id()
	_focus_restore_blorb_attempts = 0
	_selected_blorb = null
	suit.unequip_slot(assigned_slot)
	_refresh_blorbs()


## Permanent and irreversible (see Blorb.release_to_wild()), so this opens
## the confirmation overlay rather than acting immediately -- per direct
## instruction, to guard against an accidental permanent release.
func _confirm_release_selected_blorb() -> void:
	if _selected_blorb == null or not is_instance_valid(_selected_blorb) or _selected_blorb.is_blorbus:
		return
	_release_confirm_target = _selected_blorb
	_release_confirm_label.text = (
		"Release %s back into the wild? This can't be undone."
		% _selected_blorb.display_name()
	)
	_release_confirm_panel.visible = true
	_release_confirm_buttons[0].grab_focus.call_deferred()


func _cancel_release_confirm() -> void:
	_release_confirm_panel.visible = false
	_release_confirm_target = null
	if _release_button.visible:
		_release_button.grab_focus.call_deferred()


func _on_release_confirmed() -> void:
	var blorb := _release_confirm_target
	_release_confirm_panel.visible = false
	_release_confirm_target = null
	if blorb == null or not is_instance_valid(blorb):
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		var suit := player.get_blorb_suit()
		var assigned_slot := suit.slot_for_assigned_blorb(blorb)
		if assigned_slot != "":
			suit.unequip_slot(assigned_slot)
	blorb.release_to_wild()
	if _selected_blorb == blorb:
		_selected_blorb = null
	_refresh_blorbs()


## Lazily attaches the isolated preview texture after the player exists.
func _refresh_portrait() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var player_id := player.get_instance_id()
	if _portrait_player_id == player_id and _portrait_container.get_child_count() > 0:
		return
	# InventoryUI survives scene changes; Player and its SubViewport do not.
	# Replace the old world's dead ViewportTexture rather than retaining a
	# blank TextureRect in the doll area.
	for child in _portrait_container.get_children():
		child.free()
	_portrait_player_id = player_id
	var rect := TextureRect.new()
	rect.texture = player.get_portrait_texture()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_container.add_child(rect)
	player.refresh_portrait_assignments()


func _refresh_player() -> void:
	for child in _player_stats.get_children():
		child.free()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	_player_stats.add_child(UIKit.section_header("Stats"))
	_player_stats.add_child(UIKit.stat_meter(
		"HP", roundi(player.current_hp), Player.MAX_HP, true, Player.MAX_HP,
		BLORB_METER_LABEL_WIDTH, BLORB_METER_BAR_WIDTH
	))
	_player_stats.add_child(UIKit.inline_caption(
		"DEF  %d (base %d)" % [player.current_defense(), Player.BASE_DEFENSE],
		UITheme.TEXT_PRIMARY
	))
	_player_stats.add_child(UIKit.inline_caption(
		"Ground speed  %d%%" % roundi(player.worn_leg_speed_multiplier() * 100.0),
		UITheme.TEXT_PRIMARY
	))
	_player_stats.add_child(UIKit.inline_caption(
		"Flight speed  %d%%" % roundi(player.worn_flight_speed_multiplier() * 100.0),
		UITheme.TEXT_PRIMARY
	))
	_player_stats.add_child(UIKit.section_header("Attire"))
	for line in [
		"Hair  Buzz cut", "Top  Blue short-sleeve shirt",
		"Bottom  Dark trousers", "Shoes  Red shoes",
	]:
		_player_stats.add_child(UIKit.inline_caption(line, UITheme.TEXT_PRIMARY))

	_refresh_portrait()
	player.refresh_portrait_assignments()


func _on_slot_clicked(slot: String) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var suit: BlorbSuitController = player.get_blorb_suit()
	if _selected_blorb == null:
		# An occupied body part is itself a route into reassignment: select its
		# assigned Blorb and keep focus on the doll instead of destructively
		# unassigning it on the first click. Empty parts remain no-ops until a
		# portrait has been selected.
		var assigned_blorb := suit.assigned_blorb_in_slot(slot)
		if assigned_blorb != null:
			_selected_blorb = assigned_blorb
			_last_blorb_focus_id = assigned_blorb.get_instance_id()
			_refresh_blorbs()
		return
	# X on the selected Blorb's existing slot is deliberately a no-op. The
	# automatic focus transfer lands here, so making the obvious next press
	# destructive would be an easy accidental unassignment.
	if suit.assigned_blorb_in_slot(slot) == _selected_blorb:
		return
	suit.equip_to_slot(_selected_blorb, slot)
	# Assignment is a completed action, not a sticky mode. Keep controller
	# focus on this body part, but clear the portrait selection and its pink
	# doll preview so the placed Blorb cannot look perpetually active.
	_selected_blorb = null
	_refresh_blorbs()


func _on_outside_clicked() -> void:
	# Pointer misses are never destructive. B owns deselection; reassignment
	# only occurs through an explicit body-part target followed by X/click.
	pass


func _process(delta: float) -> void:
	if _item_held_feedback_timer > 0.0:
		_item_held_feedback_timer = maxf(_item_held_feedback_timer - delta, 0.0)
		if _item_held_feedback_timer <= 0.0:
			_item_held_feedback.visible = false
	# The confirmation overlay locks input to itself while up, same shape as
	# DialogUI's own modal focus lock -- ui_cancel backs out of the confirm
	# alone (Never mind.) rather than falling through to _back()'s ordinary
	# blorb-deselect/close-inventory handling.
	if _release_confirm_panel.visible:
		if Input.is_action_just_pressed("ui_cancel"):
			_cancel_release_confirm()
		UIKit.ensure_modal_focus(_release_confirm_panel, _release_confirm_buttons)
		return
	if Input.is_action_just_pressed("inventory"):
		# This autoload keeps processing while paused so its own open menu stays
		# usable. Explicitly reject an open request owned by PauseMenu/another
		# modal instead of stacking Inventory on top of it.
		if _open or (not get_tree().paused and not UIState.modal_open):
			_toggle()
	elif _open and Input.is_action_just_pressed("ui_cancel"):
		_back()
	elif _open and Input.is_action_just_pressed("menu_tab_previous"):
		_cycle_tab(-1)
	elif _open and Input.is_action_just_pressed("menu_tab_next"):
		_cycle_tab(1)
	if _open and _active_tab == "blorbs":
		var scroll_axis := Input.get_axis("look_up", "look_down")
		if absf(scroll_axis) > 0.18:
			_blorb_scroll.scroll_vertical += roundi(scroll_axis * 720.0 * delta)
	if _open:
		_ensure_inventory_focus()


## A modal must never strand controller navigation without a focus owner.
## Rebuilding a selected/deselected slot queues the old Button for deletion;
## treat that as already unavailable and choose the most relevant survivor.
func _ensure_inventory_focus() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null and not focused.is_queued_for_deletion() and focused.is_visible_in_tree():
		# Another modal layered above Inventory owns its own focus; do not steal
		# it merely because it isn't an Inventory descendant.
		return
	if _focus_restore_item_name != "" or _focus_restore_blorb_id != 0:
		return
	if _active_tab == "items":
		for child in _grid.get_children():
			if child is Button and not child.is_queued_for_deletion() and not child.disabled:
				(child as Button).grab_focus()
				return
		_items_tab_button.grab_focus()
		return
	if _selected_blorb != null:
		_portrait_button.grab_focus()
		return
	if _last_blorb_focus_id != 0:
		for node in _blorb_list.find_children("*", "Button", true, false):
			var remembered := node as Button
			if (
				remembered != null
				and not remembered.is_queued_for_deletion()
				and int(remembered.get_meta("blorb_instance_id", 0)) == _last_blorb_focus_id
			):
				remembered.grab_focus()
				return
	for node in _blorb_list.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and not button.is_queued_for_deletion() and not button.disabled:
			button.grab_focus()
			return
	if _active_tab == "player":
		_player_tab_button.grab_focus()
	else:
		_blorbs_tab_button.grab_focus()


func _back() -> void:
	if _active_tab == "items" and not HeldItem.current.is_empty():
		_focus_restore_item_name = str(HeldItem.current.get("name", ""))
		HeldItem.clear()
		return
	if _active_tab == "blorbs" and _selected_blorb != null:
		_focus_restore_blorb_id = _selected_blorb.get_instance_id()
		_focus_restore_blorb_attempts = 0
		_selected_blorb = null
		_refresh_blorbs()
		return
	_close()


func _toggle() -> void:
	if _open:
		_close()
	else:
		_open_inventory()


func _open_inventory() -> void:
	if get_tree().paused or UIState.modal_open:
		return
	_open = true
	_clear_item_held_feedback()
	# _items_scroll's real width is already known by the time the panel can
	# actually be opened (it went through its first layout pass back when
	# the (invisible) panel first entered the tree) -- recomputed here
	# defensively in case that first pass hadn't landed yet, since
	# _refresh() right below depends on _grid.columns already being
	# correct for MIN_ROWS * _grid.columns's own empty-slot count.
	_update_grid_columns()
	_refresh()
	_panel.visible = true
	UIState.push_modal()
	get_tree().paused = true
	# The active tab persists between openings, so its focus indicator must
	# reopen on that same tab instead of always implying Items is selected.
	if _active_tab == "blorbs":
		_blorbs_tab_button.grab_focus()
	elif _active_tab == "player":
		_player_tab_button.grab_focus()
	else:
		_items_tab_button.grab_focus()


func _close() -> void:
	if not _open:
		return
	_open = false
	_panel.visible = false
	_clear_item_held_feedback()
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.get_blorb_suit().apply_assignment_changes()
	get_tree().paused = false
	UIState.pop_modal()
	_set_portrait_active(false)


func _on_wallet_changed(new_value: int) -> void:
	UIKit.set_tokoin_amount(_coin_readout, new_value)


func _switch_tab(tab: String) -> void:
	_active_tab = tab
	_clear_item_held_feedback()
	_items_tab.visible = tab == "items"
	_blorbs_tab.visible = tab == "blorbs"
	_player_tab.visible = tab == "player"
	UIKit.set_tab_button_active(_items_tab_button, tab == "items")
	UIKit.set_tab_button_active(_blorbs_tab_button, tab == "blorbs")
	UIKit.set_tab_button_active(_player_tab_button, tab == "player")
	_move_shared_paper_doll()
	_refresh()


func _cycle_tab(direction: int) -> void:
	var tabs := ["items", "blorbs", "player"]
	var index := wrapi(tabs.find(_active_tab) + direction, 0, tabs.size())
	_switch_tab(tabs[index])
	var buttons := [_items_tab_button, _blorbs_tab_button, _player_tab_button]
	(buttons[index] as Button).grab_focus()


func _refresh() -> void:
	if not _open:
		return
	if _active_tab == "items":
		_refresh_items()
	elif _active_tab == "blorbs":
		_refresh_blorbs()
	else:
		_refresh_player()
	_set_portrait_active(_active_tab == "blorbs" or _active_tab == "player")


## The isolated paper-doll camera (see player_portrait.gd) only actually
## renders while its own portrait is genuinely visible on screen -- an
## always-on second camera would otherwise cost real render time for a
## texture nobody's looking at (the Items tab showing, or the whole panel
## closed).
func _set_portrait_active(active: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		player.set_portrait_active(active)


## Recomputes how many columns actually fit _items_scroll's own real
## measured width -- fires on every resize (window resizes are rare
## in-session, but this also covers the first real layout pass after the
## panel enters the tree, which is when a freshly-built Control's size
## goes from "not yet known" to "real"). Only rebuilds the grid when the
## count actually changes, so an unrelated resize eventually settling
## doesn't fire an extra rebuild for nothing.
func _update_grid_columns() -> void:
	var available_width := _items_scroll.size.x - SLOT_FOCUS_INSET * 2
	if available_width <= 0.0:
		return
	var col_span := SLOT_SIZE.x + UITheme.SPACE_MD
	var columns := maxi(1, int((available_width + UITheme.SPACE_MD) / col_span))
	if columns == _grid.columns:
		return
	_grid.columns = columns
	_refresh_items()


func _refresh_items() -> void:
	for c in _grid.get_children():
		c.queue_free()

	for item in Inventory.items:
		_grid.add_child(_build_slot(item))

	var slot_count: int = maxi(MIN_ROWS * _grid.columns, Inventory.items.size())
	for i in range(Inventory.items.size(), slot_count):
		_grid.add_child(_build_empty_slot())
	if _focus_restore_item_name != "":
		_restore_item_focus.call_deferred()
	else:
		_ensure_inventory_focus.call_deferred()


func _restore_item_focus() -> void:
	var target_name := _focus_restore_item_name
	_focus_restore_item_name = ""
	for child in _grid.get_children():
		if (
			child is Button
			and not child.is_queued_for_deletion()
			and str(child.get_meta("item_name", "")) == target_name
		):
			(child as Button).grab_focus()
			return
	_ensure_inventory_focus()


## Lists every in_party blorb (get_tree() works here despite InventoryUI
## being an autoload -- it's still a real node in the scene tree, same as
## how hud.gd's own _update_wild_hint() looks up the player by group).
func _refresh_blorbs() -> void:
	for c in _blorb_list.get_children():
		c.queue_free()

	var party: Array = []
	for blorb in get_tree().get_nodes_in_group("blorbs"):
		if blorb.in_party:
			party.append(blorb)

	# A selected blorb that left the party (or was never in it -- shouldn't
	# happen, but cheap to guard) can't stay selected.
	if _selected_blorb != null and not party.has(_selected_blorb):
		_selected_blorb = null
	if party.is_empty():
		_blorb_list.add_child(UIKit.caption_label("No blorbs in your party yet."))
	else:
		for blorb in party:
			_blorb_list.add_child(_build_blorb_row(blorb))

	_refresh_portrait()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.refresh_portrait_assignments()
		player.set_portrait_highlighted_slot(_focused_body_slot)
		player.set_portrait_selected_blorb(_selected_blorb)
		player.set_portrait_body_focus_active(get_viewport().gui_get_focus_owner() == _portrait_button)
	_update_remove_action()
	_update_release_action()
	if _focus_restore_blorb_id != 0:
		_restore_blorb_focus()
	else:
		_ensure_inventory_focus.call_deferred()


func _restore_blorb_focus() -> void:
	var target_id := _focus_restore_blorb_id
	if target_id == 0:
		return
	for child in _blorb_list.find_children("*", "Button", true, false):
		if not child.is_queued_for_deletion() and int(child.get_meta("blorb_instance_id", 0)) == target_id:
			(child as Button).grab_focus()
			_last_blorb_focus_id = target_id
			_focus_restore_blorb_id = 0
			_focus_restore_blorb_attempts = 0
			return
	# The portrait may not have entered the tree yet during an unusual rebuild
	# ordering. Keep the ID intact and retry next frame instead of discarding
	# the user's location and falling back to the first row.
	_focus_restore_blorb_attempts += 1
	if _focus_restore_blorb_attempts <= 1:
		_restore_blorb_focus.call_deferred()
	else:
		_focus_restore_blorb_id = 0
		_focus_restore_blorb_attempts = 0
		_ensure_inventory_focus()


## One party member's row: a large portrait on the left (a real rendered
## photo of the blorb -- see BlorbPortrait -- not an icon the size of an
## inventory item's), editable name and permanent gem next to it, and stat
## meters (design language item 11) anchored to the right. Only the portrait
## is interactive and receives focus/selection treatment; the information
## row remains a passive socket so selection never floods the whole row.
##
## The name/type/equipped column is deliberately NOT SIZE_EXPAND_FILL --
## per direct correction, that let it stretch across whatever leftover
## width the row happened to have, stranding its own (much narrower)
## content on the left with a wide, unbalanced dead gap before the meters.
## A dedicated flexible spacer between the two absorbs that extra width
## instead, so the text column stays a normal, tightly-wrapped block next
## to the portrait and the meters stay anchored to the row's right edge
## regardless of how wide the panel actually is.
func _build_blorb_row(blorb: Blorb) -> Control:
	var is_selected := blorb == _selected_blorb
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 0)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.add_theme_stylebox_override("panel", UITheme.slot_stylebox())

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_MD)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_MD)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_MD)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_MD)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row_panel.add_child(margin)

	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SPACE_MD)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	# Portrait, identity, and the stat meters all share this one row -- per
	# direct correction, an earlier version put the meters on their own row
	# underneath instead, which stretched every card downward for no reason
	# and left the meters unaligned with the portrait sitting above them.
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", UITheme.SPACE_MD)
	identity_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(identity_row)

	var portrait_button := Button.new()
	portrait_button.custom_minimum_size = Vector2(BLORB_PORTRAIT_SIZE, BLORB_PORTRAIT_SIZE)
	portrait_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait_button.set_meta("blorb_instance_id", blorb.get_instance_id())
	portrait_button.pressed.connect(func(): _on_blorb_row_pressed(blorb))
	portrait_button.focus_entered.connect(_on_blorb_portrait_focus_entered.bind(blorb))
	portrait_button.focus_exited.connect(_on_blorb_portrait_focus_exited.bind(blorb))
	portrait_button.gui_input.connect(func(event: InputEvent):
		if event.is_action_pressed("ui_right"):
			_portrait_button.grab_focus()
			portrait_button.accept_event()
	)
	var portrait_box := UITheme.slot_highlight_stylebox() if is_selected else UITheme.slot_stylebox()
	portrait_button.add_theme_stylebox_override("normal", portrait_box)
	portrait_button.add_theme_stylebox_override("hover", portrait_box)
	portrait_button.add_theme_stylebox_override("pressed", portrait_box)
	portrait_button.add_theme_stylebox_override("focus", UITheme.slot_focus_ring_stylebox())
	identity_row.add_child(portrait_button)

	var portrait := UIKit.portrait_slot(BLORB_PORTRAIT_SIZE)
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_button.add_child(portrait)
	BlorbPortrait.apply_portrait(
		portrait, get_tree(), blorb.element_state, blorb.body_color, blorb.is_melted
	)

	var info := VBoxContainer.new()
	# Names and identity gems are separate information groups, so use a full
	# content spacing step rather than the minimum sibling gap.
	info.add_theme_constant_override("separation", UITheme.SPACE_MD)
	info.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_child(info)

	# Naming remains in the data model, but editing is intentionally dormant
	# until that interaction has a dedicated flow.
	var name_label := UIKit.body_label(blorb.display_name())
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	info.add_child(name_label)
	# Level sits with identity rather than among the resource meters: it is a
	# durable state of this party member, while the XP row at right answers the
	# separate moment-to-moment question of progress toward the next level.
	info.add_child(UIKit.inline_caption("Level %d" % blorb.level, UITheme.TEXT_SECONDARY))

	# A melted blorb (skeleton_nme.gd combat -- see blorb.gd's melt()) shows
	# core-only above (the portrait call already passed is_melted through)
	# plus this caption, so it's clear at a glance why the party member looks
	# incomplete rather than reading as a rendering bug.
	if blorb.is_melted:
		info.add_child(UIKit.inline_caption("Melted -- regenerating", UITheme.TEXT_SECONDARY))

	# Empty means Normal. Blorbus has no socket at all (not just an empty
	# one) -- his Psychic identity is inherent and he can never accept an
	# elemental gem, so there's nothing here for him to fill. Gem and
	# bound-item sockets form one horizontal equipment row.
	var equipment_row := HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", UITheme.SPACE_SM)
	equipment_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	equipment_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(equipment_row)
	if not blorb.is_blorbus:
		var gem_socket := UIKit.elemental_gem_socket(blorb.element_state)
		equipment_row.add_child(gem_socket)
		if blorb.element_state != "":
			ItemPortrait.apply_portrait(
				gem_socket, get_tree(), "%s Gem" % blorb.element_state.capitalize()
			)
	for item_name in blorb.core_items:
		equipment_row.add_child(_build_bound_item_slot(item_name))

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_child(spacer)

	var meters := VBoxContainer.new()
	# SPACE_SM, not SPACE_XS -- per direct instruction, more vertical
	# breathing room between meters now that each bar itself is shorter.
	meters.add_theme_constant_override("separation", UITheme.SPACE_SM)
	meters.size_flags_horizontal = Control.SIZE_SHRINK_END
	# SHRINK_BEGIN, not SHRINK_CENTER -- per direct correction, this stack
	# was a sibling of identity_row (a whole separate row underneath it,
	# with nothing above it there to explain the gap) rather than living
	# INSIDE identity_row beside the portrait, which both pushed every row
	# downward and stretched the card for no reason. Now that it's a real
	# identity_row child (added below), SHRINK_BEGIN top-aligns it flush
	# with the portrait's own top instead of centering it against the
	# row's full height.
	meters.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	meters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity_row.add_child(meters)
	var next_level_xp := blorb.xp_to_next_level()
	if next_level_xp > 0:
		meters.add_child(UIKit.stat_meter(
			"XP", blorb.experience, next_level_xp, true, -1,
			BLORB_METER_LABEL_WIDTH, BLORB_METER_BAR_WIDTH
		))
	else:
		var max_level_label := UIKit.inline_caption("XP: MAX", UITheme.TEXT_PRIMARY)
		max_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		meters.add_child(max_level_label)
	var stat_values := UIKit.inline_caption(
		"STR  %d    DEF  %d    SPD  %d" % [blorb.strength, blorb.defense, blorb.speed],
		UITheme.TEXT_PRIMARY
	)
	stat_values.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meters.add_child(stat_values)
	meters.add_child(UIKit.stat_meter(
		"HP", roundi(blorb.current_hp), blorb.max_hp, true, maxi(Blorb.STAT_MAX * 4, blorb.max_hp),
		BLORB_METER_LABEL_WIDTH, BLORB_METER_BAR_WIDTH
	))
	meters.add_child(UIKit.stat_meter(
		"MP", roundi(blorb.current_mp), blorb.max_mp, true, maxi(Blorb.STAT_MAX * 2, blorb.max_mp),
		BLORB_METER_LABEL_WIDTH, BLORB_METER_BAR_WIDTH
	))

	return row_panel


## A bound core item uses the same socket, centered 3D portrait, and item-name
## treatment as the Items tab. It is passive for now: the slot communicates
## what the Blorb contains without implying that it can be selected/removed.
func _build_bound_item_slot(item_name: String) -> PanelContainer:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = BOUND_ITEM_SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_theme_stylebox_override("panel", UITheme.slot_stylebox())

	var contents := VBoxContainer.new()
	contents.alignment = BoxContainer.ALIGNMENT_CENTER
	contents.add_theme_constant_override("separation", UITheme.SPACE_XS)
	contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(contents)

	var portrait := UIKit.portrait_slot(84.0)
	contents.add_child(portrait)
	ItemPortrait.apply_portrait(portrait, get_tree(), item_name)

	var label := UIKit.caption_label(item_name)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	contents.add_child(label)
	return slot


func _on_blorb_portrait_focus_entered(blorb: Blorb) -> void:
	_last_blorb_focus_id = blorb.get_instance_id()
	# ScrollContainer doesn't follow focus on its own -- moving the D-pad/
	# stick cursor onto a row outside the current scroll window previously
	# left it selected but off-screen, with no way to see which row a
	# controller was even on. gui_get_focus_owner() is the row's own
	# portrait_button, the control that just received focus_entered.
	var focused := get_viewport().gui_get_focus_owner()
	if focused != null:
		_blorb_scroll.ensure_control_visible(focused)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.set_portrait_focused_blorb(blorb)


func _on_blorb_portrait_focus_exited(blorb: Blorb) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		player.set_portrait_focused_blorb(null)


## Highlighting a portrait previews its Blorb on the doll. Committing it with
## X/click selects that Blorb for assignment and transfers focus straight to
## its existing body slot, or to Head as the consistent unassigned default.
func _on_blorb_row_pressed(blorb: Blorb) -> void:
	_selected_blorb = blorb
	_last_blorb_focus_id = blorb.get_instance_id()
	var target_slot := "head"
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		var assigned_slot := player.get_blorb_suit().slot_for_assigned_blorb(blorb)
		if assigned_slot != "":
			target_slot = assigned_slot
	_set_focused_body_slot(target_slot)
	_refresh_blorbs()
	_portrait_button.grab_focus.call_deferred()


## The slot IS a Button (not a panel with an invisible button overlaid on
## top of other children) -- that overlay approach turned out to be fragile
## (PanelContainer gives every direct child the same full rect, so the
## button's actual click area/z-order relative to its siblings wasn't
## guaranteed) and gave zero visual affordance that the slot was
## clickable at all, which is exactly the "how am I supposed to select
## something" problem this fixes. A real Button gets hover/pressed states
## from the shared theme for free, and every decorative child below is set
## to MOUSE_FILTER_IGNORE so nothing can ever steal the click from it.
func _build_slot(item: Dictionary) -> Control:
	var button := Button.new()
	button.custom_minimum_size = SLOT_SIZE
	button.set_meta("item_name", str(item.get("name", "")))
	var is_held: bool = not HeldItem.current.is_empty() and HeldItem.current["name"] == item["name"]
	# Clicking an already-held slot a second time puts it away (HeldItem.
	# clear()) instead of re-equipping it -- per direct instruction, holding
	# should be a toggle, not a one-way action you can only replace by
	# picking something else.
	button.pressed.connect(_on_item_slot_pressed.bind(item, is_held))

	# Borderless "socket" look (UITheme.slot_stylebox()), matching the empty
	# slots below -- per direct correction, an occupied slot is still a
	# Button (see this function's own docstring for why), but without this
	# override it fell back to the shared theme's ordinary Button stylebox,
	# which carries a border (BUTTON_BORDER). That read as an unwanted outline (and an
	# inconsistency against the borderless empty slots right next to it),
	# not the click affordance a real action button needs.
	#
	# Held state is deliberately kept simple, per direct instruction: the
	# highlight is applied to every button state (not just "normal"), so a
	# held slot reads as held consistently and doesn't flicker back to the
	# ordinary socket look on hover/press -- click toggles held on/off, full
	# stop, with no separate hover-vs-held state to reconcile.
	var box := UITheme.slot_highlight_stylebox() if is_held else UITheme.slot_stylebox()
	button.add_theme_stylebox_override("normal", box)
	button.add_theme_stylebox_override("hover", box)
	button.add_theme_stylebox_override("pressed", box)
	button.add_theme_stylebox_override("focus", UITheme.slot_focus_ring_stylebox())

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", UITheme.SPACE_XS)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(vbox)

	var item_portrait := UIKit.portrait_slot(84.0)
	vbox.add_child(item_portrait)
	ItemPortrait.apply_portrait(item_portrait, get_tree(), item["name"])

	var label := UIKit.caption_label(item["name"])
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(label)

	var quantity: int = int(item.get("quantity", 1))
	if quantity > 1:
		var badge := UIKit.quantity_badge(quantity)
		UIKit.anchor_to_edge(badge, 1.0, 0.0, UITheme.SPACE_SM, UITheme.SPACE_SM)
		button.add_child(badge)

	return button


func _on_item_slot_pressed(item: Dictionary, is_held: bool) -> void:
	_focus_restore_item_name = str(item.get("name", ""))
	if is_held:
		HeldItem.clear()
		_clear_item_held_feedback()
	else:
		HeldItem.equip(item)
		_show_item_held_feedback(str(item.get("name", "Item")))


func _show_item_held_feedback(item_name: String) -> void:
	UIKit.set_readout_text(_item_held_feedback, "%s held in hand." % item_name)
	_item_held_feedback.visible = true
	_item_held_feedback_timer = ITEM_HELD_FEEDBACK_DURATION


func _clear_item_held_feedback() -> void:
	_item_held_feedback_timer = 0.0
	if _item_held_feedback != null:
		_item_held_feedback.visible = false


## An inert placeholder cell -- same footprint as a real slot, an inset
## "socket" background (UITheme.slot_stylebox()) rather than a Button, so
## it never reads as clickable.
func _build_empty_slot() -> Control:
	var slot := PanelContainer.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.add_theme_stylebox_override("panel", UITheme.slot_stylebox())
	return slot
