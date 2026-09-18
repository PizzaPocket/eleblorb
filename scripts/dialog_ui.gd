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
## Individual modal callers can additionally request a full simulation pause
## (the wild-blorb join decision does), without changing every action dialog.

# 6.0, not the original 3.5 -- per direct correction, villager lines were
# disappearing before there was time to actually read them.
const AUTO_DISMISS_TIME := 6.0
## Long enough to render several frames of the decline row's focused state,
## short enough to remain a crisp acknowledgement rather than menu latency.
const CANCEL_CONFIRM_TIME := 0.14

var _panel: PanelContainer
var _speaker_label: Label
var _line_label: Label
var _response_panel: PanelContainer
var _response_list: VBoxContainer
var _response_buttons: Array[Button] = []
var _is_modal: bool = false
var _auto_dismiss_timer: float = 0.0
## True whenever the current line is Chinese -- see ChineseLexicon.is_chinese()
## and this file's own show_line()/_process() for what changes: the ordinary
## speaker/line panel is swapped for _chinese_panel's own word-lookup
## presentation, the interaction always pauses and goes modal (never the
## plain timed auto-dismiss caption), and the auto-added dismiss response
## reads "Continue" instead of "Goodbye." when there are no other actions.
var _is_chinese_line: bool = false
var _chinese_panel: PanelContainer
var _chinese_speaker_label: Label
var _chinese_lookup_word: Label
var _chinese_lookup_pinyin: Label
var _chinese_lookup_english: Label
var _chinese_passage_flow: HFlowContainer
## The passage's own first selectable word button, tracked so a freshly
## opened Chinese line can focus straight into the interactive content
## instead of jumping to the response row first.
var _chinese_first_word_button: Button
## Lives inside _chinese_panel itself -- see that function's own comment on
## why Chinese lines never use the separate _response_panel/_response_list.
var _chinese_response_list: VBoxContainer
var _chinese_response_buttons: Array[Button] = []
## Fires once, from _on_dismiss_pressed(), whenever the modal's dismiss
## response is chosen -- by its own button or by ui_cancel -- but NOT when
## an ordinary action callback closes the dialog itself (e.g. the vendor
## flow's "Let me see your wares."). Lets a caller like a wild blorb's join
## prompt tell "accepted" apart from "declined/cancelled" without the two
## paths silently colliding. Cleared as soon as it fires so it never
## double-runs.
var _dismiss_callback: Callable = Callable()
var _cancel_confirmation_pending: bool = false
## True only when this dialog set SceneTree.paused itself. Tracking ownership
## prevents an ordinary dialog close from resuming a pause established by a
## different system.
var _game_pause_owned: bool = false
var _transaction_hud_owned: bool = false


func _ready() -> void:
	layer = 30
	# A join decision can pause the SceneTree, but its buttons, focus repair,
	# Back/B handling, and delayed decline acknowledgement must remain live.
	process_mode = Node.PROCESS_MODE_ALWAYS
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

	_build_chinese_ui(shared_theme)
	_build_response_ui(shared_theme)


## Per direct instruction: any NPC who already speaks Chinese (the Chinese
## village's cast, see ChineseLexicon's own class doc) gets a pausing,
## word-lookup presentation instead of the plain speaker/line panel above --
## "a blorb background, similar to how the inventory UI appears in blorb
## colors and with blorb eyes at the top... smaller, with the eyes
## proportionately scaled down." Mutually exclusive with _panel (see
## show_line()): exactly one of the two is visible at a time. Unlike _panel,
## this one never shares the separate _response_panel -- per direct
## correction, every response (including the plain "Continue" case) lives
## in this panel's own _chinese_response_list instead, so gamepad/keyboard
## focus never has to cross between two separate Control trees.
func _build_chinese_ui(shared_theme: Theme) -> void:
	_chinese_panel = UIKit.panel()
	_chinese_panel.theme = shared_theme
	_chinese_panel.add_theme_stylebox_override("panel", UITheme.blorbus_panel_stylebox())
	# Deliberately narrower than _panel's own 840 -- "this will be smaller."
	_chinese_panel.custom_minimum_size = Vector2(620, 0)
	UIKit.anchor_to_edge(_chinese_panel, 0.5, 0.75, 0.0, 0.0)
	_chinese_panel.visible = false
	add_child(_chinese_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_LG)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_MD)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_MD)
	_chinese_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITheme.SPACE_SM)
	margin.add_child(vbox)

	# inline_caption(), not caption_label() -- per direct correction, that
	# was the exact cause of the reported "extremely narrow column, wraps
	# down to one or two characters, stretches the panel very high": a plain
	# caption_label() wraps by default (right for a paragraph of unknown
	# length), which lets a cramped sibling in a row get squeezed down to
	# almost nothing and then wrap vertically instead. caption_label()'s own
	# doc comment already flags this exact failure mode and names
	# inline_caption() as the fix for text meant to sit in a row.
	_chinese_speaker_label = UIKit.inline_caption("")
	_chinese_speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chinese_speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(_chinese_speaker_label)

	var eyes_cell := CenterContainer.new()
	vbox.add_child(eyes_cell)
	# Proportionately scaled down from the Inventory header's own full size --
	# "the eyes will be proportionately scaled down."
	eyes_cell.add_child(UIKit.blorbus_eyes(0.55))

	# The lookup readout -- per direct correction, one single row: character,
	# then its pinyin, then its English gloss, left to right, rather than the
	# character on its own line stacked over a second row. Sits directly
	# under the eyes and directly above the passage itself, exactly where it
	# was before -- only the internal layout and the wrap bug changed. Empty
	# until a word is actually tapped/clicked. No divider above or below it
	# -- per direct correction ("I never like these thick white horizontal
	# dividers"), this panel uses plain spacing between sections instead of
	# UIKit.divider() lines.
	var lookup_row := HBoxContainer.new()
	lookup_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lookup_row.add_theme_constant_override("separation", UITheme.SPACE_SM)
	vbox.add_child(lookup_row)
	_chinese_lookup_word = UIKit.inline_caption("", UITheme.TEXT_PRIMARY)
	_chinese_lookup_word.add_theme_font_size_override("font_size", UITheme.FONT_HEADING)
	lookup_row.add_child(_chinese_lookup_word)
	_chinese_lookup_pinyin = UIKit.inline_caption("")
	lookup_row.add_child(_chinese_lookup_pinyin)
	_chinese_lookup_english = UIKit.inline_caption("")
	lookup_row.add_child(_chinese_lookup_english)

	# The passage itself: an ordered, wrapping flow of individually
	# selectable words/phrases (see _populate_chinese_passage()) -- "use the
	# joystick or the mouse to scroll over the Chinese phrases."
	_chinese_passage_flow = HFlowContainer.new()
	_chinese_passage_flow.add_theme_constant_override("h_separation", UITheme.SPACE_XS)
	_chinese_passage_flow.add_theme_constant_override("v_separation", UITheme.SPACE_XS)
	vbox.add_child(_chinese_passage_flow)

	# Per direct correction ("this continue is going to be an action button
	# on the bottom right of the same translation dialogue panel... otherwise
	# you wouldn't be able to jump from your player response UI panel to the
	# interactive Chinese translation panel") -- Chinese lines no longer use
	# the separate _response_panel at all (see show_line()'s own comment):
	# every response, including the plain "Continue" case, lives in this row
	# instead, so gamepad/keyboard focus never has to cross between two
	# separate Control trees to get from a word to the way out.
	_chinese_response_list = VBoxContainer.new()
	_chinese_response_list.add_theme_constant_override("separation", UITheme.SPACE_XS)
	vbox.add_child(_chinese_response_list)


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
	if _is_modal and _is_chinese_line and _chinese_panel.visible:
		UIKit.ensure_modal_focus(_chinese_panel, _chinese_response_buttons)
	elif _is_modal and _response_panel.visible:
		UIKit.ensure_modal_focus(_response_panel, _response_buttons)
	# Chinese lines never reach this branch at all: they always go modal
	# (see show_line()'s own comment), so there is no timed auto-dismiss to
	# race against for them -- the player always closes them deliberately.
	if not _is_modal and _panel.visible:
		_auto_dismiss_timer -= delta
		if _auto_dismiss_timer <= 0.0:
			hide_dialog()


func show_line(
	speaker: String, line: String, actions: Array[Dictionary] = [],
	dismiss_label: String = "Goodbye.", dismiss_callback: Callable = Callable(),
	pause_game: bool = false
) -> void:
	_cancel_confirmation_pending = false
	_dismiss_callback = dismiss_callback
	# Per direct instruction: any already-Chinese-speaking NPC (see
	# ChineseLexicon's own class doc for exactly which ones) gets the
	# blorb-panel word-lookup presentation instead of the plain caption, and
	# "it will be a pausing interaction" -- unconditionally, regardless of
	# whatever pause_game the caller happened to pass (none of
	# chinese_village.gd's own call sites do), and regardless of whether
	# `actions` is empty (ordinary chatter would otherwise take the
	# non-modal, auto-dismissing branch below).
	_is_chinese_line = ChineseLexicon.is_chinese(line)
	if _is_chinese_line:
		_chinese_speaker_label.text = speaker
		_populate_chinese_passage(line)
	else:
		_speaker_label.text = speaker
		_line_label.text = line

	for c in _response_list.get_children():
		c.queue_free()
	_response_buttons.clear()
	for c in _chinese_response_list.get_children():
		c.queue_free()
	_chinese_response_buttons.clear()

	var was_modal := _is_modal
	_is_modal = not actions.is_empty() or _is_chinese_line
	if _is_modal:
		var has_transaction: bool = false
		for action in actions:
			has_transaction = has_transaction or bool(action.get("transaction",false))
			_add_response(action["label"], action["callback"])
		_set_transaction_hud(has_transaction)
		# A Chinese line with no other actions (the common ambient-chatter/
		# greeting case) gets "Continue" instead of "Goodbye." -- per direct
		# instruction, "clicking continue will proceed or close the dialogue
		# if there's no next dialogue." A Chinese line WITH real actions (the
		# village's own quest branches) keeps whatever dismiss_label its own
		# call site passed, unchanged from today.
		var effective_dismiss_label := "Continue" if (_is_chinese_line and actions.is_empty()) else dismiss_label
		_add_response(effective_dismiss_label, _on_dismiss_pressed)
		# Per direct correction, Chinese lines never show the separate
		# _response_panel at all -- see _build_chinese_ui()'s own comment on
		# why "Continue"/every other response now lives inside _chinese_panel
		# itself instead.
		if _is_chinese_line:
			_chinese_response_buttons.back().set_meta("ui_sound_kind", "back")
			_response_panel.visible = false
		else:
			_response_buttons.back().set_meta("ui_sound_kind", "back")
			_response_panel.visible = true
		if not was_modal:
			UIState.push_modal()
		_set_game_pause(pause_game or _is_chinese_line)
	else:
		_set_transaction_hud(false)
		_response_panel.visible = false
		if was_modal:
			UIState.pop_modal()
		_set_game_pause(false)
		_auto_dismiss_timer = AUTO_DISMISS_TIME

	_panel.visible = not _is_chinese_line
	_chinese_panel.visible = _is_chinese_line
	if _is_modal:
		if _is_chinese_line:
			# The passage's own first selectable word is the natural place
			# to start (the main interactive content), not the response row
			# -- fall back to the response row only if the line has no
			# lexicon-covered words at all.
			if _chinese_first_word_button != null:
				_chinese_first_word_button.grab_focus.call_deferred()
			elif not _chinese_response_buttons.is_empty():
				_chinese_response_buttons[0].grab_focus.call_deferred()
		elif not _response_buttons.is_empty():
			_response_buttons[0].grab_focus.call_deferred()


## Breaks `line` into ChineseLexicon's own pre-segmented words/phrases and
## lays them out as a wrapping flow of individually selectable buttons (real
## words) and plain labels (punctuation) -- see UIKit.chinese_word_button()/
## chinese_punctuation_label(). Resets the lookup readout each time a new
## line is shown, since the previous line's selected word no longer applies.
func _populate_chinese_passage(line: String) -> void:
	for c in _chinese_passage_flow.get_children():
		c.queue_free()
	_chinese_lookup_word.text = ""
	_chinese_lookup_pinyin.text = ""
	_chinese_lookup_english.text = ""
	_chinese_first_word_button = null
	for token in ChineseLexicon.segments_for(line):
		var word: String = token
		var info := ChineseLexicon.word_info(word)
		if info.is_empty():
			_chinese_passage_flow.add_child(UIKit.chinese_punctuation_label(word))
		else:
			var word_button := UIKit.chinese_word_button(word, func(): _show_word_info(word, info))
			_chinese_passage_flow.add_child(word_button)
			if _chinese_first_word_button == null:
				_chinese_first_word_button = word_button


func _show_word_info(word: String, info: Dictionary) -> void:
	_chinese_lookup_word.text = word
	_chinese_lookup_pinyin.text = info.get("pinyin", "")
	_chinese_lookup_english.text = info.get("english", "")


## Chinese lines route into _chinese_response_list/_chinese_response_buttons
## instead of the shared _response_list/_response_buttons -- per direct
## correction, keeping every response (including "Continue") inside
## _chinese_panel itself so gamepad/keyboard focus can move freely between
## the word-lookup flow and the response row without crossing between two
## separate, distantly-positioned Control trees.
func _add_response(text: String, callback: Callable) -> void:
	var target_list := _chinese_response_list if _is_chinese_line else _response_list
	var target_buttons := _chinese_response_buttons if _is_chinese_line else _response_buttons

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITheme.SPACE_SM)
	target_list.add_child(row)

	var option := UIKit.response_option(text, callback)
	row.add_child(option)
	target_buttons.append(option)

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
	if (_panel.visible or _chinese_panel.visible) and event.is_action_pressed("ui_cancel"):
		_confirm_dismiss_from_cancel()
		get_viewport().set_input_as_handled()


## Back/B means the visible dismiss response, not an invisible generic close.
## Move focus to that final response and leave it rendered briefly before
## committing the callback, so the existing white text + response arrow
## clearly acknowledge which choice was made.
func _confirm_dismiss_from_cancel() -> void:
	if _cancel_confirmation_pending:
		return
	var active_buttons := _chinese_response_buttons if _is_chinese_line else _response_buttons
	if not _is_modal or active_buttons.is_empty():
		_on_dismiss_pressed()
		return
	_cancel_confirmation_pending = true
	var dismiss_button: Button = active_buttons.back()
	for button: Button in active_buttons:
		button.disabled = button != dismiss_button
	dismiss_button.grab_focus()
	# Guarantee at least one rendered frame of the changed focus before the
	# short confirmation hold begins.
	await get_tree().process_frame
	await get_tree().create_timer(CANCEL_CONFIRM_TIME).timeout
	if _cancel_confirmation_pending and (_panel.visible or _chinese_panel.visible):
		_commit_dismiss()


## Direct button presses commit here immediately; Back/B first passes through
## _confirm_dismiss_from_cancel() and invokes _commit_dismiss() after its
## visible acknowledgement. Either route fires dismiss_callback exactly once.
func _on_dismiss_pressed() -> void:
	if _cancel_confirmation_pending:
		return
	_commit_dismiss()


func _commit_dismiss() -> void:
	var callback := _dismiss_callback
	_dismiss_callback = Callable()
	hide_dialog()
	if callback.is_valid():
		callback.call()


func hide_dialog() -> void:
	if not _panel.visible and not _chinese_panel.visible:
		return
	_cancel_confirmation_pending = false
	_panel.visible = false
	_chinese_panel.visible = false
	_response_panel.visible = false
	if _is_modal:
		UIState.pop_modal()
		_is_modal = false
	_set_game_pause(false)
	_set_transaction_hud(false)


func _set_transaction_hud(should_show: bool) -> void:
	if should_show and not _transaction_hud_owned:
		Hud.push_tokoin_visibility()
		_transaction_hud_owned = true
	elif not should_show and _transaction_hud_owned:
		Hud.pop_tokoin_visibility()
		_transaction_hud_owned = false


func _set_game_pause(should_pause: bool) -> void:
	if should_pause and not _game_pause_owned:
		# Only claim a pause we actually establish. If another system already
		# paused the tree, closing this dialog must not resume it accidentally.
		if not get_tree().paused:
			get_tree().paused = true
			_game_pause_owned = true
	elif not should_pause and _game_pause_owned:
		get_tree().paused = false
		_game_pause_owned = false
