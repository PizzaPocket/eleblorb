extends CanvasLayer

## ESC ("pause" action) pause menu. Quit is intentionally "return to title"
## rather than terminating the host application, and is protected by a clear
## unsaved-progress confirmation.
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
var _quit_confirm_panel: PanelContainer
var _quit_confirm_buttons: Array[Button] = []


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
	vbox.add_child(UIKit.button("Quit", _show_quit_confirmation))
	_build_quit_confirmation(shared_theme)


func _build_quit_confirmation(shared_theme: Theme) -> void:
	_quit_confirm_panel = UIKit.panel()
	_quit_confirm_panel.theme = shared_theme
	_quit_confirm_panel.custom_minimum_size = Vector2(560, 0)
	UIKit.anchor_to_edge(_quit_confirm_panel, 0.5, 0.5, 0.0, 0.0)
	_quit_confirm_panel.visible = false
	add_child(_quit_confirm_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_LG)
	_quit_confirm_panel.add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", UITheme.SPACE_MD)
	margin.add_child(content)
	content.add_child(UIKit.heading("Return to the start screen?"))
	content.add_child(UIKit.body_label("Your progress in this run will not be saved."))
	var return_button := UIKit.button("Return to Start", _return_to_start)
	var cancel_button := UIKit.button("Keep Playing", _cancel_quit_confirmation)
	content.add_child(return_button)
	content.add_child(cancel_button)
	_quit_confirm_buttons = [return_button, cancel_button]


func _unhandled_input(event: InputEvent) -> void:
	if _open and _quit_confirm_panel.visible and event.is_action_pressed("ui_cancel"):
		_cancel_quit_confirmation()
		get_viewport().set_input_as_handled()
		return
	if _open and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("pause"):
		return
	# Title/loading scenes own their own navigation and are not simulations that
	# can be paused. The shared autoload must stay dormant there.
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.is_in_group("pause_disabled"):
		get_viewport().set_input_as_handled()
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
		if _quit_confirm_panel.visible:
			UIKit.ensure_modal_focus(_quit_confirm_panel, _quit_confirm_buttons)
		else:
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
	_quit_confirm_panel.visible = false
	_panel.visible = false
	get_tree().paused = false
	UIState.pop_modal()


func is_open() -> bool:
	return _open


func _show_quit_confirmation() -> void:
	_quit_confirm_panel.visible = true
	_quit_confirm_buttons[1].grab_focus.call_deferred()


func _cancel_quit_confirmation() -> void:
	_quit_confirm_panel.visible = false
	_resume_button.grab_focus.call_deferred()


func _return_to_start() -> void:
	# Restore the global modal/pause state before replacing the gameplay scene;
	# this autoload survives the scene change and must not strand the title UI.
	_open = false
	_quit_confirm_panel.visible = false
	_panel.visible = false
	get_tree().paused = false
	UIState.pop_modal()
	UISounds.play_crt_on()
	get_tree().change_scene_to_file("res://scenes/start_screen.tscn")
