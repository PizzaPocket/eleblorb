extends CanvasLayer

## Full-screen, pausing presentation for a gem merge and the chained starter-
## trio awakening. The whiteout is the mutation boundary: the portrait shown
## before it is the actual Normal look, and the portrait revealed afterward
## is captured from the newly transformed Blorb through BlorbPortrait's one
## shared three-quarter camera rig.

const INTRO_HOLD := 0.55
const GLOW_TIME := 0.58
const WHITEOUT_TIME := 0.14
const WHITE_HOLD := 0.12
const REVEAL_TIME := 0.38
const RESULT_HOLD := 1.15
const SURPRISE_HOLD := 1.05
const EXIT_TIME := 0.24
const CAPTION_MAX_WIDTH := 620.0

var _root: Control
var _portrait: TextureRect
var _portrait_material: ShaderMaterial
var _whiteout: ColorRect
var _caption_panel: PanelContainer
var _caption_label: Label
var _busy := false
var _queued_blorbus: Blorb = null
var _pause_owned := false


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)

	var backdrop := ColorRect.new()
	backdrop.color = UITheme.LOADING_BG
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(backdrop)

	_portrait = TextureRect.new()
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_portrait)

	var glow_shader := Shader.new()
	glow_shader.code = """
shader_type canvas_item;
uniform float glow_amount : hint_range(0.0, 1.0) = 0.0;
void fragment() {
	vec4 source = texture(TEXTURE, UV);
	COLOR = vec4(mix(source.rgb, vec3(1.0), glow_amount), source.a);
}
"""
	_portrait_material = ShaderMaterial.new()
	_portrait_material.shader = glow_shader
	_portrait.material = _portrait_material

	_caption_panel = UIKit.panel()
	_caption_panel.theme = UITheme.get_theme()
	_caption_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.anchor_to_edge(_caption_panel, 0.5, 1.0, 0.0, UITheme.SPACE_LG)
	_root.add_child(_caption_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITheme.SPACE_MD)
	margin.add_theme_constant_override("margin_right", UITheme.SPACE_MD)
	margin.add_theme_constant_override("margin_top", UITheme.SPACE_SM)
	margin.add_theme_constant_override("margin_bottom", UITheme.SPACE_SM)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_panel.add_child(margin)

	_caption_label = UIKit.caption_label("")
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_caption_label)
	if not get_viewport().size_changed.is_connected(_layout_caption):
		get_viewport().size_changed.connect(_layout_caption)
	_layout_caption()

	# Added last so the peak flash truly blows out the entire frame, including
	# its caption, then reveals the new result copy and portrait together.
	# A screen-filling light plane is deliberately rectangular: it represents
	# the frame being overexposed, not a bounded UI surface.
	_whiteout = ColorRect.new()
	_whiteout.color = Color.WHITE
	_whiteout.modulate.a = 0.0
	_whiteout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_whiteout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_whiteout)


func _layout_caption() -> void:
	if _caption_panel == null:
		return
	var viewport_width := get_viewport().get_visible_rect().size.x
	_caption_panel.custom_minimum_size.x = minf(
		CAPTION_MAX_WIDTH, maxf(280.0, viewport_width - UITheme.SPACE_MD * 2.0)
	)


## Begins immediately and owns the pause before the first awaited portrait
## frame, so combat cannot advance between impact and the overlay appearing.
func play_elemental_transformation(blorb: Blorb, element: String) -> void:
	if _busy or not is_instance_valid(blorb) or not blorb.can_merge(element):
		return
	_busy = true
	_queued_blorbus = null
	_run_elemental_transformation(blorb, element)


## Called by Blorb._check_blorbus_awakening() at the hidden mutation point of
## the second starter merge. Ordinarily this queues behind that active stage;
## the standalone path keeps direct/debug merges coherent too.
func queue_blorbus_transformation(blorb: Blorb) -> void:
	if not is_instance_valid(blorb) or blorb.is_blorbus:
		return
	_queued_blorbus = blorb
	if not _busy:
		_busy = true
		_run_standalone_blorbus_transformation()


func _run_elemental_transformation(blorb: Blorb, element: String) -> void:
	_begin_sequence()
	var subject := _sentence_subject(blorb.display_name())
	_caption_label.text = "%s is transforming!" % subject
	_portrait.texture = await BlorbPortrait.get_portrait_texture(
		get_tree(), blorb.element_state, blorb.body_color, false, blorb.is_blorbus
	)
	await _wait(INTRO_HOLD)
	await _glow_and_whiteout()

	# State changes only while the frame is fully white. merge_element() may
	# queue the remaining starter for Blorbus, but does not interrupt this stage.
	blorb.merge_element(element)
	_portrait.texture = await BlorbPortrait.get_portrait_texture(
		get_tree(), blorb.element_state, blorb.body_color, false, false
	)
	_portrait_material.set_shader_parameter("glow_amount", 0.0)
	var type_name := element.capitalize()
	_caption_label.text = "%s transformed into %s %s blorb!" % [
		subject, _indefinite_article(type_name), type_name
	]
	await _reveal_from_white()
	await _wait(RESULT_HOLD)

	if is_instance_valid(_queued_blorbus):
		var awakening := _queued_blorbus
		_queued_blorbus = null
		_portrait.texture = await BlorbPortrait.get_portrait_texture(
			get_tree(), awakening.element_state, awakening.body_color, false, false
		)
		_caption_label.text = "What's this? The third blorb is also transforming?"
		await _wait(SURPRISE_HOLD)
		await _run_blorbus_stage(awakening)

	await _end_sequence()
	_busy = false


func _run_standalone_blorbus_transformation() -> void:
	_begin_sequence()
	var awakening := _queued_blorbus
	_queued_blorbus = null
	if is_instance_valid(awakening):
		_portrait.texture = await BlorbPortrait.get_portrait_texture(
			get_tree(), awakening.element_state, awakening.body_color, false, false
		)
		_caption_label.text = "What's this? The third blorb is also transforming?"
		await _wait(SURPRISE_HOLD)
		await _run_blorbus_stage(awakening)
	await _end_sequence()
	_busy = false


func _run_blorbus_stage(blorb: Blorb) -> void:
	var former_name := blorb.display_name()
	var result_subject := (
		_sentence_subject(former_name)
		if blorb.blorb_name.strip_edges() != ""
		else "The third blorb"
	)
	_portrait.texture = await BlorbPortrait.get_portrait_texture(
		get_tree(), blorb.element_state, blorb.body_color, false, false
	)
	_portrait_material.set_shader_parameter("glow_amount", 0.0)
	_caption_label.text = "%s is transforming!" % _sentence_subject(former_name)
	await _wait(INTRO_HOLD)
	await _glow_and_whiteout()

	blorb.become_blorbus()
	_portrait.texture = await BlorbPortrait.get_portrait_texture(
		get_tree(), "", blorb.body_color, false, true
	)
	_portrait_material.set_shader_parameter("glow_amount", 0.0)
	_caption_label.text = "%s transformed into Blorbus!" % result_subject
	await _reveal_from_white()
	await _wait(RESULT_HOLD)


func _begin_sequence() -> void:
	_root.modulate.a = 1.0
	_root.visible = true
	_whiteout.modulate.a = 0.0
	_portrait_material.set_shader_parameter("glow_amount", 0.0)
	UIState.push_modal()
	# This is a non-interactive cut sequence; retain a captured pointer instead
	# of showing a stray cursor simply because UIState is blocking gameplay.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if not get_tree().paused:
		get_tree().paused = true
		_pause_owned = true


func _glow_and_whiteout() -> void:
	var glow := create_tween()
	glow.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	glow.tween_method(
		func(value: float): _portrait_material.set_shader_parameter("glow_amount", value),
		0.0, 1.0, GLOW_TIME
	)
	await glow.finished
	var flash := create_tween()
	flash.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	flash.tween_property(_whiteout, "modulate:a", 1.0, WHITEOUT_TIME)
	await flash.finished
	await _wait(WHITE_HOLD)


func _reveal_from_white() -> void:
	var reveal := create_tween()
	reveal.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	reveal.tween_property(_whiteout, "modulate:a", 0.0, REVEAL_TIME)
	await reveal.finished


func _end_sequence() -> void:
	var exit := create_tween()
	exit.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	exit.tween_property(_root, "modulate:a", 0.0, EXIT_TIME)
	await exit.finished
	_root.visible = false
	_root.modulate.a = 1.0
	_portrait.texture = null
	if _pause_owned:
		get_tree().paused = false
		_pause_owned = false
	UIState.pop_modal()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true, false, true).timeout


func _sentence_subject(raw_name: String) -> String:
	if raw_name.is_empty():
		return "The blorb"
	return raw_name.left(1).to_upper() + raw_name.substr(1)


func _indefinite_article(noun: String) -> String:
	return "an" if noun.left(1).to_lower() in ["a", "e", "i", "o", "u"] else "a"
