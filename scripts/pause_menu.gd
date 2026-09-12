extends CanvasLayer

## ESC ("pause" action) pause menu -- Resume/Quit, kept intentionally
## minimal per direct instruction (no save system or options/settings menu
## yet to put here, and no title screen to "quit to" -- Quit closes the
## whole application).
##
## Unlike Dialog/Shop/Inventory (which only free the mouse and block
## gameplay input while open), this one actually pauses simulation
## (get_tree().paused = true) -- per direct instruction, ESC specifically
## is expected to freeze the world (blorbs, day/night cycle, everything),
## not just overlay a panel on top of a still-running game. Still
## registers as an ordinary UIState modal alongside that, so it composes
## correctly if something else (an NPC's dialogue) already has the mouse
## freed.
##
## Superseded what used to be a raw mouse-mode toggle on the "pause" action
## in player.gd -- that's now just this menu's own open/close, with
## UIState.push_modal()/pop_modal() already handling the mouse mode
## transition the same way every other modal in the game does.
##
## process_mode = PROCESS_MODE_ALWAYS is required, not optional -- without
## it, get_tree().paused = true would freeze this menu's own input
## handling and buttons right along with everything else, and there'd be
## no way to ever close it again.

var _panel: PanelContainer
var _open: bool = false
var _resume_button: Button


func _ready() -> void:
	layer = 40  # above every other UI surface (Hud 10, DialogUI 30, ShopUI 31, InventoryUI 35)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	var shared_theme := UITheme.get_theme()

	_panel = UIKit.panel()
	_panel.theme = shared_theme
	_panel.custom_minimum_size = Vector2(480, 0)
	UIKit.anchor_to_edge(_panel, 0.5, 0.5, 0.0, 0.0)
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

	vbox.add_child(UIKit.heading("Paused"))
	_resume_button = UIKit.button("Resume", _close)
	_resume_button.set_meta("ui_sound_kind", "menu_close")
	vbox.add_child(_resume_button)
	vbox.add_child(UIKit.button("Quit", _quit))


func _unhandled_input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("pause"):
		return
	if _open:
		_close()
	# Same guard every other modal-opening input in the game already uses
	# (see player.gd's own former handler here) -- don't open on top of
	# Dialog/Shop/Inventory, which should be dismissed on their own terms
	# first.
	elif not UIState.modal_open:
		_open_menu()


func _process(_delta: float) -> void:
	if _open:
		UIKit.ensure_modal_focus(_panel, [_resume_button])


func _open_menu() -> void:
	# A pause press is also an unambiguous request to leave a prepared throw;
	# clear that gameplay state before freezing the player process so its
	# reticle/camera cannot remain stuck over the pause surface.
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("cancel_throw_preparation"):
		player.cancel_throw_preparation()
	_open = true
	UISounds.play_crt_off()
	_panel.visible = true
	UIState.push_modal()
	get_tree().paused = true
	_resume_button.grab_focus()


func _close() -> void:
	if not _open:
		return
	_open = false
	UISounds.play_crt_on()
	_panel.visible = false
	get_tree().paused = false
	UIState.pop_modal()


func is_open() -> bool:
	return _open


func _quit() -> void:
	get_tree().quit()
