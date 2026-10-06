extends Control

## Lightweight application entry. The game world is not requested until the
## player chooses New Game or Play Demo, so this screen can render immediately
## while both expensive procedural worlds remain completely unloaded.

const LOADING_SCENE := "res://scenes/loading.tscn"
const CAMPAIGN_SCENE := "res://scenes/main.tscn"
const DEMO_SCENE := "res://scenes/demo_world.tscn"
const LOGO := preload("res://assets/ui/eleblorbs_logo.svg")
const BACKGROUND := preload("res://assets/ui/start_background.png")

var _play_button: Button
var _new_game_button: Button
## TEMPORARY kingdom test starts (see DebugKingdomStart), kept with the other
## launch buttons so one pass disables them all.
var _debug_buttons: Array[Button] = []
var _button_column_height := 0.0
var _content: VBoxContainer
var _logo: TextureRect
var _title: Label
var _brand_row: HBoxContainer
var _modal: PanelContainer
var _brand_center: CenterContainer


func _ready() -> void:
	# The title is desktop UI, not gameplay. Always release a capture inherited
	# from a previous session before presenting its clickable controls.
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	theme = UITheme.get_theme()
	_build_ui()
	# The native LoadingScreen autoload now remains dormant at launch. On web,
	# this also dismisses the HTML bootstrap cover once this tiny scene has
	# actually presented, revealing the title screen instead of the game world.
	LoadingScreen.reveal_start_screen()
	_play_button.grab_focus.call_deferred()
	get_viewport().size_changed.connect(_layout)
	_layout()


func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	# A quiet photographic veil preserves the environment while keeping white
	# modal typography readable in every crop and display aspect ratio.
	var veil := ColorRect.new()
	veil.color = Color(0.035, 0.055, 0.075, 0.18)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_modal = PanelContainer.new()
	_modal.name = "StartModal"
	# Exact same Blorbus-derived panel surface as the Inventory UI.
	_modal.add_theme_stylebox_override("panel", UITheme.blorbus_panel_stylebox())
	_modal.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_modal)

	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", UITheme.SPACE_MD)
	_content.alignment = BoxContainer.ALIGNMENT_CENTER
	_content.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_modal.add_child(_content)

	# Exact same living component, hue and randomized blink convention as the
	# Inventory header, now properly contained inside the modal.
	var top_eyes := UIKit.blorbus_eyes(0.72)
	_content.add_child(top_eyes)

	# The title is environmental branding rather than modal content: float it
	# in the photograph's open sky and leave the Blorbus panel task-focused.
	_brand_center = CenterContainer.new()
	_brand_center.anchor_right = 1.0
	_brand_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_brand_center)

	_brand_row = HBoxContainer.new()
	_brand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_brand_row.add_theme_constant_override("separation", UITheme.SPACE_MD)
	_brand_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brand_center.add_child(_brand_row)

	_logo = TextureRect.new()
	_logo.texture = LOGO
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_brand_row.add_child(_logo)

	_title = Label.new()
	_title.text = "Eleblorbs"
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	_brand_row.add_child(_title)

	var button_center := CenterContainer.new()
	_content.add_child(button_center)
	var buttons := VBoxContainer.new()
	# These are distinct launch decisions, not compact controls within one
	# form. Give their full touch/gamepad surfaces a medium design-token gap so
	# their panel fills and focus treatments never visually merge.
	buttons.add_theme_constant_override("separation", UITheme.SPACE_MD)
	button_center.add_child(buttons)

	_play_button = UIKit.button("Play Demo", _play_demo)
	_play_button.custom_minimum_size = Vector2(280.0, UITheme.BUTTON_MIN_HEIGHT)
	buttons.add_child(_play_button)
	_new_game_button = UIKit.button("New Game", _play_new_game)
	_new_game_button.custom_minimum_size = Vector2(280.0, UITheme.BUTTON_MIN_HEIGHT)
	buttons.add_child(_new_game_button)
	var count := 2
	# TEMPORARY: straight into a kingdom with a ready-made suit, to speed up testing.
	for loadout_id: String in DebugKingdomStart.LOADOUTS.keys():
		var label: String = DebugKingdomStart.LOADOUTS[loadout_id]["label"]
		var debug_button := UIKit.button(label, _play_debug_kingdom.bind(loadout_id))
		debug_button.custom_minimum_size = Vector2(280.0, UITheme.BUTTON_MIN_HEIGHT)
		buttons.add_child(debug_button)
		_debug_buttons.append(debug_button)
		count += 1
	_button_column_height = float(count) * UITheme.BUTTON_MIN_HEIGHT + float(count - 1) * float(UITheme.SPACE_MD)
	button_center.custom_minimum_size.y = _button_column_height


func _layout() -> void:
	if _content == null or _modal == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var short_side := minf(viewport_size.x, viewport_size.y)
	var logo_height := clampf(short_side * 0.095, 68.0, 112.0)
	# The SVG's canonical Blorb projection is wider than it is tall. Preserve
	# that real proportion in the lockup instead of forcing it into a square.
	_logo.custom_minimum_size = Vector2(logo_height * 1.48, logo_height)
	_title.add_theme_font_size_override(
		"font_size", int(clampf(logo_height * 1.16, 92.0, 156.0))
	)
	var modal_width := clampf(viewport_size.x * 0.39, 520.0, 720.0)
	if viewport_size.x < 700.0:
		modal_width = maxf(300.0, viewport_size.x - UITheme.SPACE_MD * 2.0)
	_content.custom_minimum_size.x = modal_width
	_content.custom_minimum_size.y = maxf(clampf(viewport_size.y * 0.24, 250.0, 330.0), _button_column_height + 110.0)
	_modal.custom_minimum_size = Vector2(
		modal_width + UITheme.SPACE_XL,
		_content.custom_minimum_size.y + UITheme.SPACE_LG
	)
	# Reserve the upper quarter of the photograph for the lockup. This stays
	# visibly separate from the centered interaction panel at every desktop size.
	_brand_center.offset_top = maxf(UITheme.SPACE_MD, viewport_size.y * 0.035)
	_brand_center.offset_bottom = viewport_size.y * 0.29


func _play_demo() -> void:
	_launch(DEMO_SCENE)


func _play_new_game() -> void:
	_launch(CAMPAIGN_SCENE)


## TEMPORARY: a fresh run that begins inside a kingdom (see DebugKingdomStart).
func _play_debug_kingdom(loadout_id: String) -> void:
	_launch(DebugKingdomStart.LOADOUTS[loadout_id]["scene"], loadout_id)


func _launch(world_scene: String, debug_loadout: String = "") -> void:
	if _play_button.disabled or _new_game_button.disabled:
		return
	_play_button.disabled = true
	_new_game_button.disabled = true
	for debug_button in _debug_buttons:
		debug_button.disabled = true
	get_tree().paused = false
	# Starting from the title is a fresh run, not a portal transition.  Reset
	# every autoload-owned part of the previous run before either world can
	# register actors. This keeps Demo and Campaign selectable side-by-side
	# without either leaking party, story, inventory, recovery, or control state
	# into the other.
	PartyControl.reset_for_new_session()
	Party.reset_for_new_session()
	WorldState.reset_for_new_game()
	HumongousState.reset_for_new_session()
	RecoveryManager.reset_for_new_session()
	KingdomTravel.pending_gate_id = ""
	KingdomTravel.debug_loadout = debug_loadout
	KingdomTravel.debug_loadout_in_use = false
	TokoinWallet.set_value(0)
	Inventory.reset_for_new_session()
	HeldItem.clear()
	UIState.reset_for_new_session()
	LoadingScreen.set_launch_scene(world_scene)
	LoadingScreen.begin_transition()
	# Loading is the boundary into direct-control gameplay. Capture here rather
	# than at application launch so the title never traps the desktop pointer.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(LOADING_SCENE)
