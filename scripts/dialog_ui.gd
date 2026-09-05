extends CanvasLayer

## NPC speech, always routed through here rather than Hud.show_message --
## Hud's message line is reserved for system/transient feedback (bought an
## item, can't afford it), not character speech.
##
## Two modes: no actions (ordinary villager chatter) auto-dismisses after a
## few seconds and doesn't touch UIState, so movement/camera-look stay live
## for a caption that's meant to be glanced at, not a pause. With actions
## (the antique dealer's "Browse Wares") it becomes a real modal with a
## separate player-response window. UIState then owns gameplay input so the
## same stick/D-pad and X action used elsewhere can navigate and answer.

# 6.0, not the original 3.5 -- per direct correction, villager lines were
# disappearing before there was time to actually read them.
const AUTO_DISMISS_TIME := 6.0

var _panel: PanelContainer
var _speaker_label: Label
var _line_label: Label
var _response_panel: PanelContainer
var _response_list: VBoxContainer
var _response_buttons: Array[Button] = []
var _is_modal: bool = false
var _auto_dismiss_timer: float = 0.0
## Fires once, from _on_dismiss_pressed(), whenever the modal's dismiss
## response is chosen -- by its own button or by ui_cancel -- but NOT when
## an ordinary action callback closes the dialog itself (e.g. the vendor
## flow's "Let me see your wares."). Lets a caller like a wild blorb's join
## prompt tell "accepted" apart from "declined/cancelled" without the two
## paths silently colliding. Cleared as soon as it fires so it never
## double-runs.
var _dismiss_callback: Callable = Callable()


func _ready() -> void:
	layer = 30
	_build_ui()


func _build_ui() -> void:
	var shared_theme := UITheme.get_theme()

	_panel = UIKit.panel()
	_panel.theme = shared_theme
	_panel.custom_minimum_size = Vector2(840, 0)
	# NPC speech remains horizontally centered in the lower half of the screen.
	# A dialog box sitting at
	# true screen-center covers up the main 3D view/gameplay behind it. The
	# earlier flush-against-the-bottom-edge layout (no margin at all) was
	# also wrong, just in the other direction -- anchoring at 75% down (not
	# 100%) with BEGIN growth (see UIKit.anchor_to_edge) keeps it low and
	# clear of the center while still growing upward, safely, as its own
	# content requires.
	UIKit.anchor_to_edge(_panel, 0.5, 0.75, 0.0, 0.0)
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

	_speaker_label = UIKit.heading("")
	vbox.add_child(_speaker_label)

	vbox.add_child(UIKit.divider())

	_line_label = UIKit.body_label("")
	vbox.add_child(_line_label)

	_build_response_ui(shared_theme)


func _build_response_ui(shared_theme: Theme) -> void:
	_response_panel = UIKit.panel()
	_response_panel.theme = shared_theme
	_response_panel.custom_minimum_size = Vector2(600, 0)
	UIKit.anchor_to_edge(
		_response_panel, 1.0, 1.0, UITheme.SPACE_XL, UITheme.SPACE_XL
	)
	_response_panel.visible = false
	add_child(_response_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_LG)
	_response_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	margin.add_child(vbox)

	_response_list = VBoxContainer.new()
	_response_list.add_theme_constant_override("separation", UITheme.SPACE_XS)
	vbox.add_child(_response_list)


func _process(delta: float) -> void:
	if _is_modal and _response_panel.visible:
		UIKit.ensure_modal_focus(_response_panel, _response_buttons)
	if not _is_modal and _panel.visible:
		_auto_dismiss_timer -= delta
		if _auto_dismiss_timer <= 0.0:
			hide_dialog()


func show_line(
	speaker: String, line: String, actions: Array[Dictionary] = [],
	dismiss_label: String = "Goodbye.", dismiss_callback: Callable = Callable()
) -> void:
	_speaker_label.text = speaker
	_line_label.text = line
	_dismiss_callback = dismiss_callback

	for c in _response_list.get_children():
		c.queue_free()
	_response_buttons.clear()

	var was_modal := _is_modal
	_is_modal = not actions.is_empty()
	if _is_modal:
		for action in actions:
			_add_response(action["label"], action["callback"])
		_add_response(dismiss_label, _on_dismiss_pressed)
		_response_panel.visible = true
		if not was_modal:
			UIState.push_modal()
	else:
		_response_panel.visible = false
		if was_modal:
			UIState.pop_modal()
		_auto_dismiss_timer = AUTO_DISMISS_TIME

	_panel.visible = true
	if _is_modal and not _response_buttons.is_empty():
		_response_buttons[0].grab_focus.call_deferred()


func _add_response(text: String, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SPACE_SM)
	_response_list.add_child(row)

	var option := UIKit.response_option(text, callback)
	row.add_child(option)
	_response_buttons.append(option)

	var arrow := UIKit.response_arrow()
	# Keep the arrow control present even while unfocused: Containers exclude
	# hidden children from layout, which made the option text expand into this
	# margin and jump left/right whenever selection changed.
	arrow.modulate.a = 0.0
	row.add_child(arrow)
	option.focus_entered.connect(func(): arrow.modulate.a = 1.0)
	option.focus_exited.connect(func(): arrow.modulate.a = 0.0)
	option.mouse_entered.connect(option.grab_focus)


func _unhandled_input(event: InputEvent) -> void:
	if _panel.visible and event.is_action_pressed("ui_cancel"):
		_on_dismiss_pressed()
		get_viewport().set_input_as_handled()


## The one path that both the dismiss response button and ui_cancel route
## through, so a dismiss_callback fires exactly once regardless of which one
## the player used -- an action button's own callback (which may itself call
## hide_dialog()) never runs through here and so never triggers it.
func _on_dismiss_pressed() -> void:
	var callback := _dismiss_callback
	_dismiss_callback = Callable()
	hide_dialog()
	if callback.is_valid():
		callback.call()


func hide_dialog() -> void:
	if not _panel.visible:
		return
	_panel.visible = false
	_response_panel.visible = false
	if _is_modal:
		UIState.pop_modal()
		_is_modal = false
