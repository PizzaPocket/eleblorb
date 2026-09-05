extends CanvasLayer

## Buy/sell modal opened from the antique dealer's "Browse Wares" dialog
## action. Buy column reads ShopCatalog's purchasable entries; Sell column
## reads the player's current Inventory. Purchases/sales give feedback
## inline (a status line inside this panel), not via Hud.show_message --
## the modal itself is the feedback surface while it's open.

const DEFAULT_STOCK := 3
const ITEM_PORTRAIT_SIZE := 96.0

var _root_panel: PanelContainer
var _coin_readout: PanelContainer
var _buy_list: VBoxContainer
var _sell_list: VBoxContainer
var _status_label: Label
var _catalog: Array[Dictionary] = []
var _stock_by_name: Dictionary = {}
var _focus_restore_side: String = ""
var _focus_restore_item_name: String = ""

## Buy/sell confirmation overlay -- see _build_confirm_ui()/_confirm_buy()/
## _confirm_sell(). One shared panel for both flows; the quantity row only
## shows itself for a sell with more than one owned.
var _confirm_panel: PanelContainer
var _confirm_label: Label
var _confirm_qty_row: Control
var _confirm_qty_value_label: Label
var _confirm_qty_minus: Button
var _confirm_qty_plus: Button
var _confirm_qty_max: Button
var _confirm_action_button: Button
var _confirm_cancel_button: Button
var _confirm_buttons: Array[Button] = []
var _confirm_mode: String = ""  # "buy" or "sell"
var _confirm_item: Dictionary = {}
var _confirm_price: int = 0
var _confirm_quantity: int = 1
var _confirm_max_quantity: int = 1
## Whichever row button opened the confirm -- captured so Cancel can land
## focus straight back on it instead of wherever ensure_modal_focus's own
## fallback would otherwise pick.
var _confirm_return_focus: Button = null


func _ready() -> void:
	layer = 31
	_build_ui()
	TokoinWallet.changed.connect(_on_state_changed)
	Inventory.changed.connect(_on_state_changed)


func _build_ui() -> void:
	var shared_theme := UITheme.get_theme()

	_root_panel = UIKit.panel()
	_root_panel.theme = shared_theme
	# Viewport-relative (full rect inset by a fixed margin), not a small
	# fixed pixel size -- a browse-and-scroll list needs real vertical room
	# to actually show its contents, not just a token sliver above a
	# scrollbar. Scales with the window instead of a magic-number box that
	# happens to fit (or not) at one particular resolution.
	_root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root_panel.offset_left = 100
	_root_panel.offset_right = -100
	_root_panel.offset_top = 70
	_root_panel.offset_bottom = -70
	_root_panel.visible = false
	add_child(_root_panel)

	# Extra breathing room beyond the shared panel stylebox's own (fairly
	# tight, reused everywhere) content margin -- a modal this size reads
	# cramped without it.
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_LG)
	_root_panel.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", UITheme.SPACE_MD)
	margin.add_child(outer)

	# Header: title on the left, the tokoin count and dismiss control
	# grouped on the right -- a standard window-chrome layout, with the
	# stat badge (fixed to its own content size, never wrapped) instead of
	# a plain Label that a flexible header row could squeeze down to
	# nothing next to the close button.
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", UITheme.SPACE_MD)
	outer.add_child(header)
	var title := UIKit.heading("Antique Shop")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	_coin_readout = UIKit.tokoin_badge(0)
	header.add_child(_coin_readout)
	header.add_child(UIKit.close_button(close))

	_status_label = UIKit.caption_label("")
	outer.add_child(_status_label)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", UITheme.SPACE_XL)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)

	var buy_column := VBoxContainer.new()
	buy_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_column.add_theme_constant_override("separation", UITheme.SPACE_SM)
	columns.add_child(buy_column)
	buy_column.add_child(UIKit.section_header("Buy"))
	var buy_scroll := ScrollContainer.new()
	buy_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Vertical scroll only -- a row's content should wrap to fit the
	# column's width, never spill sideways into a horizontal scrollbar.
	buy_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	buy_column.add_child(buy_scroll)
	_buy_list = VBoxContainer.new()
	_buy_list.add_theme_constant_override("separation", UITheme.SPACE_SM)
	_buy_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_scroll.add_child(_buy_list)

	var sell_column := VBoxContainer.new()
	sell_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_column.add_theme_constant_override("separation", UITheme.SPACE_SM)
	columns.add_child(sell_column)
	sell_column.add_child(UIKit.section_header("Sell"))
	var sell_scroll := ScrollContainer.new()
	sell_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sell_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sell_column.add_child(sell_scroll)
	_sell_list = VBoxContainer.new()
	_sell_list.add_theme_constant_override("separation", UITheme.SPACE_SM)
	_sell_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_scroll.add_child(_sell_list)

	_build_confirm_ui(shared_theme)


## A buy or sell press opens this instead of acting immediately -- per direct
## instruction, both trades get a confirmation, and selling additionally gets
## a quantity picker when more than one is owned. Added as a sibling of
## _root_panel, built last so it draws on top of both columns regardless of
## which one is showing the row being confirmed. Modal panel styling matches
## the rest of the game: translucent background, no border stroke (see
## ui_theme.gd's design language) -- and critically, `theme = shared_theme`,
## the same explicit assignment _root_panel itself gets above, so its buttons
## and labels actually pick up the project's fonts/styleboxes instead of
## Godot's bare engine defaults.
func _build_confirm_ui(shared_theme: Theme) -> void:
	_confirm_panel = UIKit.panel()
	_confirm_panel.theme = shared_theme
	_confirm_panel.custom_minimum_size = Vector2(520, 0)
	UIKit.anchor_to_edge(_confirm_panel, 0.5, 0.5, 0.0, 0.0)
	_confirm_panel.visible = false
	add_child(_confirm_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_LG)
	_confirm_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SPACE_MD)
	margin.add_child(vbox)

	_confirm_label = UIKit.body_label("")
	vbox.add_child(_confirm_label)

	_confirm_qty_row = HBoxContainer.new()
	(_confirm_qty_row as HBoxContainer).add_theme_constant_override("separation", UITheme.SPACE_SM)
	(_confirm_qty_row as HBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(_confirm_qty_row)
	_confirm_qty_minus = UIKit.button("-", func(): _confirm_qty_change(-1))
	_confirm_qty_minus.custom_minimum_size.x = UITheme.BUTTON_MIN_HEIGHT
	_confirm_qty_row.add_child(_confirm_qty_minus)
	_confirm_qty_value_label = UIKit.heading("1")
	_confirm_qty_value_label.custom_minimum_size.x = UITheme.SPACE_XL
	_confirm_qty_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_qty_row.add_child(_confirm_qty_value_label)
	_confirm_qty_plus = UIKit.button("+", func(): _confirm_qty_change(1))
	_confirm_qty_plus.custom_minimum_size.x = UITheme.BUTTON_MIN_HEIGHT
	_confirm_qty_row.add_child(_confirm_qty_plus)
	_confirm_qty_max = UIKit.button("Sell All", _confirm_qty_set_max)
	_confirm_qty_row.add_child(_confirm_qty_max)

	vbox.add_child(UIKit.divider())

	_confirm_action_button = UIKit.button("", _on_confirm_action)
	vbox.add_child(_confirm_action_button)
	_confirm_cancel_button = UIKit.button("Never mind.", _cancel_confirm)
	vbox.add_child(_confirm_cancel_button)


func open(catalog: Array[Dictionary]) -> void:
	_catalog = catalog
	for item in _catalog:
		if item.get("purchasable", false):
			var item_name := str(item.get("name", ""))
			if not _stock_by_name.has(item_name):
				_stock_by_name[item_name] = int(item.get("stock", DEFAULT_STOCK))
	_status_label.text = ""
	UIState.push_modal()
	_root_panel.visible = true
	_refresh()
	var buttons := _root_panel.find_children("*", "Button", true, false)
	for node in buttons:
		var button := node as Button
		if button != null and button.get_meta("shop_side", "") == "buy" and not button.disabled:
			button.grab_focus()
			break


func _unhandled_input(event: InputEvent) -> void:
	if _confirm_panel.visible and event.is_action_pressed("ui_cancel"):
		_cancel_confirm()
		get_viewport().set_input_as_handled()
		return
	if _root_panel.visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# Same modal focus lock shape as DialogUI/InventoryUI's own overlays --
	# ui_cancel backs out of the confirm alone rather than falling through to
	# closing the whole shop.
	if _confirm_panel.visible:
		UIKit.ensure_modal_focus(_confirm_panel, _confirm_buttons)
		return
	if not _root_panel.visible or _focus_restore_side != "":
		return
	var preferred: Array[Control] = []
	for node in _root_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.has_meta("shop_side"):
			preferred.append(button)
	UIKit.ensure_modal_focus(_root_panel, preferred)


func close() -> void:
	if not _root_panel.visible:
		return
	_confirm_panel.visible = false
	_confirm_mode = ""
	_root_panel.visible = false
	UIState.pop_modal()


func _on_state_changed(_arg = null) -> void:
	if _root_panel.visible:
		_refresh()


func _refresh() -> void:
	_capture_focus_for_restore()
	UIKit.set_tokoin_amount(_coin_readout, TokoinWallet.value)

	for c in _buy_list.get_children():
		c.queue_free()
	var buy_count := 0
	for item in _catalog:
		if item.get("purchasable", false) and _stock_for(item["name"]) > 0:
			_buy_list.add_child(_build_buy_row(item))
			buy_count += 1
	if buy_count == 0:
		_buy_list.add_child(UIKit.caption_label("Nothing left in stock."))

	for c in _sell_list.get_children():
		c.queue_free()
	for item in Inventory.items:
		_sell_list.add_child(_build_sell_row(item))
	if Inventory.items.is_empty():
		_sell_list.add_child(UIKit.caption_label("Nothing to sell."))
	_restore_shop_focus.call_deferred()


func _capture_focus_for_restore() -> void:
	if _focus_restore_side != "":
		return
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null or not _root_panel.is_ancestor_of(focused):
		return
	if focused.has_meta("shop_side"):
		_focus_restore_side = str(focused.get_meta("shop_side"))
		_focus_restore_item_name = str(focused.get_meta("item_name", ""))


func _restore_shop_focus() -> void:
	if not _root_panel.visible or _focus_restore_side == "":
		return
	var fallback: Button = null
	var global_fallback: Button = null
	for node in _root_panel.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null or button.is_queued_for_deletion():
			continue
		if global_fallback == null and not button.disabled:
			global_fallback = button
		if str(button.get_meta("shop_side", "")) != _focus_restore_side:
			continue
		if fallback == null and not button.disabled:
			fallback = button
		if (
			str(button.get_meta("item_name", "")) == _focus_restore_item_name
			and not button.disabled
		):
			button.grab_focus()
			_focus_restore_side = ""
			_focus_restore_item_name = ""
			return
	if fallback != null:
		fallback.grab_focus()
	elif global_fallback != null:
		global_fallback.grab_focus()
	_focus_restore_side = ""
	_focus_restore_item_name = ""


func _stock_for(item_name: String) -> int:
	return int(_stock_by_name.get(item_name, 0))


func _build_buy_row(item: Dictionary) -> Control:
	var row := UIKit.panel()
	row.self_modulate = Color(1, 1, 1, 1)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", UITheme.SPACE_MD)
	row.add_child(hbox)

	var buy_portrait := UIKit.portrait_slot(ITEM_PORTRAIT_SIZE)
	hbox.add_child(buy_portrait)
	ItemPortrait.apply_portrait(buy_portrait, get_tree(), item["name"])

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_col)
	text_col.add_child(UIKit.body_label(item["name"]))
	var stock := _stock_for(item["name"])
	var owned := Inventory.quantity_of(item["name"])
	text_col.add_child(UIKit.inline_caption("In stock: %d   You own: %d" % [stock, owned]))
	text_col.add_child(UIKit.caption_label(item.get("description", "")))

	var price := item["price"] as int
	var afford := TokoinWallet.value >= price
	var buy_button := UIKit.button(
		"%d tokoins" % price, func(): _confirm_buy(item)
	)
	buy_button.set_meta("shop_side", "buy")
	buy_button.set_meta("item_name", str(item["name"]))
	buy_button.disabled = not afford
	hbox.add_child(buy_button)
	return row


func _build_sell_row(item: Dictionary) -> Control:
	var row := UIKit.panel()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", UITheme.SPACE_MD)
	row.add_child(hbox)

	var catalog_entry := ShopCatalog.find(item["name"])
	var sell_portrait := UIKit.portrait_slot(ITEM_PORTRAIT_SIZE)
	hbox.add_child(sell_portrait)
	ItemPortrait.apply_portrait(sell_portrait, get_tree(), item["name"])

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(text_col)
	text_col.add_child(UIKit.body_label(item["name"]))
	text_col.add_child(UIKit.inline_caption("You own: %d" % int(item.get("quantity", 1))))

	var sell_price: int = catalog_entry.get("sell_price", 1) if not catalog_entry.is_empty() else 1
	var sell_button := UIKit.button(
		"Sell for %d" % sell_price, func(): _confirm_sell(item, sell_price)
	)
	sell_button.set_meta("shop_side", "sell")
	sell_button.set_meta("item_name", str(item["name"]))
	hbox.add_child(sell_button)
	return row


## Opens the shared confirm overlay for a purchase -- no quantity picker
## (each buy row only ever buys one unit at a time), just a plain yes/no.
func _confirm_buy(item: Dictionary) -> void:
	_confirm_mode = "buy"
	_confirm_item = item
	_confirm_price = item["price"] as int
	_confirm_qty_row.visible = false
	_confirm_label.text = "Buy the %s for %d tokoins?" % [item["name"], _confirm_price]
	_confirm_action_button.text = "Buy for %d tokoins" % _confirm_price
	_open_confirm()


## Opens the shared confirm overlay for a sale. The quantity row (stepper +
## Sell All) only appears when more than one is owned -- per direct
## instruction, picking a quantity only matters if there's a quantity to
## pick from.
func _confirm_sell(item: Dictionary, sell_price: int) -> void:
	_confirm_mode = "sell"
	_confirm_item = item
	_confirm_price = sell_price
	_confirm_max_quantity = maxi(int(item.get("quantity", 1)), 1)
	_confirm_quantity = 1
	_confirm_qty_row.visible = _confirm_max_quantity > 1
	_update_confirm_sell_text()
	_open_confirm()


func _update_confirm_sell_text() -> void:
	_confirm_qty_value_label.text = str(_confirm_quantity)
	_confirm_qty_minus.disabled = _confirm_quantity <= 1
	_confirm_qty_plus.disabled = _confirm_quantity >= _confirm_max_quantity
	_confirm_qty_max.disabled = _confirm_quantity >= _confirm_max_quantity
	var total := _confirm_price * _confirm_quantity
	if _confirm_qty_row.visible:
		_confirm_label.text = "Sell how many %s? You own %d." % [_confirm_item["name"], _confirm_max_quantity]
		_confirm_action_button.text = "Sell %d for %d tokoins" % [_confirm_quantity, total]
	else:
		_confirm_label.text = "Sell the %s for %d tokoins?" % [_confirm_item["name"], total]
		_confirm_action_button.text = "Sell for %d tokoins" % total


func _confirm_qty_change(delta: int) -> void:
	_confirm_quantity = clampi(_confirm_quantity + delta, 1, _confirm_max_quantity)
	_update_confirm_sell_text()


func _confirm_qty_set_max() -> void:
	_confirm_quantity = _confirm_max_quantity
	_update_confirm_sell_text()


func _open_confirm() -> void:
	_confirm_return_focus = get_viewport().gui_get_focus_owner() as Button
	_confirm_panel.visible = true
	# A ternary combining two array literals infers as plain Array, not
	# Array[Button] -- unlike a direct literal assignment, that inferred type
	# doesn't get silently coerced to match _confirm_buttons's own declared
	# type, so the two branches are assigned separately instead.
	if _confirm_qty_row.visible:
		_confirm_buttons = [_confirm_qty_minus, _confirm_qty_plus, _confirm_qty_max, _confirm_action_button, _confirm_cancel_button]
	else:
		_confirm_buttons = [_confirm_action_button, _confirm_cancel_button]
	_confirm_action_button.grab_focus.call_deferred()


func _cancel_confirm() -> void:
	_confirm_panel.visible = false
	_confirm_mode = ""
	if (
		_confirm_return_focus != null
		and is_instance_valid(_confirm_return_focus)
		and _confirm_return_focus.is_visible_in_tree()
	):
		_confirm_return_focus.grab_focus.call_deferred()


func _on_confirm_action() -> void:
	var mode := _confirm_mode
	var item := _confirm_item
	var price := _confirm_price
	var quantity := _confirm_quantity
	_confirm_panel.visible = false
	_confirm_mode = ""
	if mode == "buy":
		_try_buy(item)
	elif mode == "sell":
		_sell(str(item["name"]), price, quantity)


func _try_buy(item: Dictionary) -> void:
	var item_name := str(item["name"])
	var stock := _stock_for(item_name)
	if stock <= 0:
		return
	_focus_restore_side = "buy"
	_focus_restore_item_name = item_name
	var price := item["price"] as int
	_stock_by_name[item_name] = stock - 1
	if not TokoinWallet.spend(price):
		_stock_by_name[item_name] = stock
		_status_label.text = "Need %d more tokoins for the %s." % [price - TokoinWallet.value, item["name"]]
		_status_label.add_theme_color_override("font_color", UITheme.ACCENT_RED)
		_refresh()
		return
	Inventory.add(item["name"], item["color"])
	_status_label.text = "Bought the %s." % item["name"]
	_status_label.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)


## quantity defaults to 1 (an ordinary single sale keeps the exact same
## outcome/wording as before the confirm flow existed); the sell-confirm's
## quantity stepper is what drives it above 1. _focus_restore_item_name is
## set to the item's name (a string, not row identity) before Inventory.
## remove_quantity() -- matched back up in _restore_shop_focus() by the same
## name string on the row rebuilt after _refresh(), so a partial sell (stock
## remaining) keeps focus on that same item's row instead of jumping
## elsewhere, per direct instruction.
func _sell(item_name: String, sell_price: int, quantity: int = 1) -> void:
	_focus_restore_side = "sell"
	_focus_restore_item_name = item_name
	var removed := Inventory.remove_quantity(item_name, quantity)
	if removed <= 0:
		return
	for catalog_item in _catalog:
		if catalog_item.get("name", "") == item_name and catalog_item.get("purchasable", false):
			_stock_by_name[item_name] = _stock_for(item_name) + removed
			break
	if (
		not HeldItem.current.is_empty()
		and HeldItem.current.get("name", "") == item_name
		and not Inventory.has(item_name)
	):
		HeldItem.clear()
	var total := sell_price * removed
	TokoinWallet.add(total)
	if removed == 1:
		_status_label.text = "Sold the %s for %d tokoins." % [item_name, total]
	else:
		_status_label.text = "Sold %d %s for %d tokoins." % [removed, item_name, total]
	_status_label.add_theme_color_override("font_color", UITheme.ACCENT_GREEN)
