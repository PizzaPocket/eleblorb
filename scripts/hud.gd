extends CanvasLayer

## Always-on HUD: tokoin count (top-right, a compact never-wrapping badge --
## see UIKit.stat_badge), an interaction prompt (bottom-center, padded well
## clear of the screen edge) driven by InteractionManager.current, and a
## transient message line above it for shop/dialogue feedback. Built
## entirely in code in _ready(), matching the rest of the project's
## runtime-constructed look, through UITheme/UIKit so it shares the same
## design system as DialogUI/ShopUI/InventoryUI.
##
## Tokoins sits top-right rather than top-left: it's a passive status
## readout, not something the player acts on directly (that's InventoryUI,
## opened separately), and keeping it out of the top-left corner leaves that
## corner free for anything more actionable that lands there later.
##
## It's also not permanently visible -- per the design language's "passive
## readout whose info is available elsewhere" rule (see UITheme), it fades
## in briefly whenever the tokoin count actually changes (picked up/spent
## some) and fades back out, rather than sitting on screen as permanent
## chrome. InventoryUI carries its own embedded tokoin readout in its own
## header (matching ShopUI's own header exactly, see design language item
## 10) rather than this one being forced visible while it's open -- one
## readout living in the surface that's actually relevant, not a HUD
## overlay this modal has to coordinate visibility with.
##
## Every readout here sits inside a UIKit.backed_readout() panel rather
## than floating bare over the 3D scene -- see UITheme's docstring for why
## that's structurally required for WCAG AA, not just a font-size fix.
##
## No crosshair and no inventory row here: the crosshair only ever landed on
## the character's own head/shoulder in third person (there's no fixed aim
## point to mark), and the inventory row duplicated what InventoryUI (opened
## with I) already shows properly. Left out rather than deleted outright --
## see git history / the retired Crosshair inner class this replaced if this
## ever moves to a first-person or aimed-throw view where a reticle would
## actually mean something.

## Small ring+dot reticle with its own dark-outline/light-fill pairing so it
## stays legible over any background, drawn directly rather than built from
## Controls since a circle isn't expressible as a stylebox. Kept, unused, for
## a future first-person/aimed view -- see the module docstring above.
class Crosshair extends Control:
	const RING_RADIUS := 15.0
	const RING_WIDTH := 4.5
	const DOT_RADIUS := 3.0

	func _draw() -> void:
		var center := size * 0.5
		draw_arc(center, RING_RADIUS, 0.0, TAU, 24, Color(0, 0, 0, 0.6), RING_WIDTH + 2.0)
		draw_arc(center, RING_RADIUS, 0.0, TAU, 24, Color(1, 1, 1, 0.9), RING_WIDTH)
		draw_circle(center, DOT_RADIUS + 1.5, Color(0, 0, 0, 0.6))
		draw_circle(center, DOT_RADIUS, Color(1, 1, 1, 0.9))


## Shared fade-in/hold/fade-out timing for every transient HUD readout
## (Tokoins, player HP) -- see _flash_readout()'s own docstring.
const FLASH_READOUT_HOLD_DURATION := 2.0
const FLASH_READOUT_FADE_DURATION := 0.35

var _coin_readout: PanelContainer
var _coin_readout_tween: Tween
var _prompt_readout: PanelContainer
var _message_readout: PanelContainer
var _message_timer: float = 0.0
## Level-up notices are passive and can arrive several at once when multiple
## participating blorbs share one NME reward. Queue them instead of letting
## the last level-up overwrite the others in the single message readout.
var _passive_message_queue: Array[Dictionary] = []

## Player HP readout -- fades in on damage/heal/regen, holds, fades out,
## same as the Tokoins readout (see design language rule 5/20 in
## ui_theme.gd). _hp_meter is the inner UIKit.stat_meter() control rebuilt
## in place each change (StatMeterBar has no public setter, so the meter
## row is discarded and rebuilt rather than mutated -- see inventory_ui.gd's
## own blorb-row rebuild for the same convention).
var _hp_readout: PanelContainer
var _hp_meter: Control
var _hp_readout_tween: Tween

## Points toward the nearest not-yet-partied wild blorb -- "the game tells
## you which way to go," per direct instruction. Player is looked up lazily
## by group (Hud is an autoload with no scene-tree relation to Player, and
## the player instance doesn't exist yet on Hud's own _ready()).
var _wild_hint: PanelContainer
var _player: Node3D


func _ready() -> void:
	layer = 10
	_build_ui()
	TokoinWallet.changed.connect(_on_wallet_changed)
	# Sets the initial amount without the fade-in flash below -- starting
	# the game isn't "picking up coins," so there's nothing to announce yet.
	UIKit.set_tokoin_amount(_coin_readout, TokoinWallet.value)


func _build_ui() -> void:
	# CanvasLayer (unlike Control) has no theme property of its own --
	# applied per top-level Control child instead, so it still propagates
	# to every descendant.
	var shared_theme := UITheme.get_theme()

	# White (TEXT_PRIMARY) text, per direct instruction -- was ACCENT_GOLD.
	# The coin icon replaces a literal "Tokoins:" label per direct
	# instruction -- see UIKit.tokoin_badge().
	_coin_readout = UIKit.tokoin_badge(0, UITheme.TEXT_PRIMARY)
	_coin_readout.theme = shared_theme
	_coin_readout.modulate.a = 0.0
	UIKit.anchor_to_edge(_coin_readout, 1.0, 0.0, UITheme.SPACE_LG, UITheme.SPACE_LG)
	add_child(_coin_readout)

	# Bottom-center readouts: pinned to the bottom with a real fixed margin,
	# growing upward as their own content requires -- see UIKit.
	# anchor_to_edge's own docstring for why this (not set_anchors_and_
	# offsets_preset + PRESET_MODE_KEEP_SIZE) is the correct way to do that.
	const BOTTOM_MARGIN := UITheme.SPACE_XL * 2

	_message_readout = UIKit.backed_readout("", UITheme.TEXT_PRIMARY, UITheme.FONT_BODY)
	_message_readout.theme = shared_theme
	_message_readout.custom_minimum_size = Vector2(900, 0)
	UIKit.anchor_to_edge(_message_readout, 0.5, 1.0, 0.0, BOTTOM_MARGIN + UITheme.BUTTON_MIN_HEIGHT + UITheme.SPACE_MD)
	_message_readout.visible = false
	add_child(_message_readout)

	_prompt_readout = UIKit.backed_readout("", UITheme.TEXT_PRIMARY, UITheme.FONT_BUTTON)
	_prompt_readout.theme = shared_theme
	_prompt_readout.custom_minimum_size = Vector2(900, 0)
	UIKit.anchor_to_edge(_prompt_readout, 0.5, 1.0, 0.0, BOTTOM_MARGIN)
	_prompt_readout.visible = false
	add_child(_prompt_readout)

	# Bottom-right per direct correction (was top-center) -- clear of the
	# Tokoins badge (top-right) and the bottom-center prompt/message stack.
	# Only visible while there's actually a not-yet-partied wild blorb
	# somewhere to point at (see _process()).
	_wild_hint = UIKit.direction_hint()
	_wild_hint.theme = shared_theme
	UIKit.anchor_to_edge(_wild_hint, 1.0, 1.0, UITheme.SPACE_LG, UITheme.SPACE_LG)
	_wild_hint.visible = false
	add_child(_wild_hint)

	# Top-left (the corner the module docstring notes Tokoins deliberately
	# leaves free for something more actionable) -- fades in on damage/heal/
	# regen same as the Tokoins badge, per design language rule 5/20.
	_hp_meter = UIKit.stat_meter("HP", int(Player.MAX_HP), int(Player.MAX_HP), true)
	_hp_readout = UIKit.backed_control(_hp_meter)
	_hp_readout.theme = shared_theme
	_hp_readout.modulate.a = 0.0
	UIKit.anchor_to_edge(_hp_readout, 0.0, 0.0, UITheme.SPACE_LG, UITheme.SPACE_LG)
	add_child(_hp_readout)


func _process(delta: float) -> void:
	var current: Area3D = InteractionManager.current
	if current != null:
		UIKit.set_readout_text(_prompt_readout, String(current.get_meta("prompt")))
		_prompt_readout.visible = true
	else:
		_prompt_readout.visible = false

	if _message_timer > 0.0:
		_message_timer -= delta
		if _message_timer <= 0.0:
			if _passive_message_queue.is_empty():
				_message_readout.visible = false
			else:
				_show_next_passive_message()

	_ensure_player_hp_connected()
	_update_wild_hint()


func _on_wallet_changed(new_value: int) -> void:
	UIKit.set_tokoin_amount(_coin_readout, new_value)
	_flash_coin_readout()


## Player is resolved lazily by group (Hud is an autoload with no scene-tree
## relation to Player, same reasoning as _wild_hint's own lookup) and its
## hp_changed signal connected exactly once, the first frame a Player
## instance actually exists.
var _hp_connected: bool = false


func _ensure_player_hp_connected() -> void:
	if _hp_connected:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return
	_player.hp_changed.connect(_on_player_hp_changed)
	_hp_connected = true


## Rebuilds the meter row in place -- StatMeterBar has no public setter for
## its drawn value (see ui_kit.gd), so the row is discarded and rebuilt each
## change rather than mutated, same as inventory_ui.gd's own blorb rows.
func _on_player_hp_changed(current: float, max_value: float) -> void:
	_hp_meter.queue_free()
	_hp_meter = UIKit.stat_meter("HP", roundi(current), int(max_value), true)
	_hp_readout.add_child(_hp_meter)
	_flash_hp_readout()


## Fades a readout in, holds it, then fades it back out -- one authored
## moment (per the design language's motion guidance), not a permanent
## fixture. Killing and restarting the tween on every call means a rapid
## run of changes just keeps the readout visible/re-holds rather than
## stacking overlapping fades.
func _flash_readout(readout: Control, tween: Tween) -> Tween:
	if tween != null:
		tween.kill()
	readout.modulate.a = 1.0
	var new_tween := create_tween()
	new_tween.tween_interval(FLASH_READOUT_HOLD_DURATION)
	new_tween.tween_property(readout, "modulate:a", 0.0, FLASH_READOUT_FADE_DURATION)
	return new_tween


func _flash_coin_readout() -> void:
	_coin_readout_tween = _flash_readout(_coin_readout, _coin_readout_tween)


func _flash_hp_readout() -> void:
	_hp_readout_tween = _flash_readout(_hp_readout, _hp_readout_tween)


func show_message(text: String, duration: float = 2.5) -> void:
	UIKit.set_readout_text(_message_readout, text)
	_message_readout.visible = true
	_message_timer = duration


func show_passive_message(text: String, duration: float = 2.5) -> void:
	_passive_message_queue.append({"text": text, "duration": duration})
	if not _message_readout.visible or _message_timer <= 0.0:
		_show_next_passive_message()


func _show_next_passive_message() -> void:
	if _passive_message_queue.is_empty():
		return
	var message: Dictionary = _passive_message_queue.pop_front()
	show_message(message["text"] as String, message["duration"] as float)


## Ties the hint to actually owning the Corroded Pocket Compass, per direct
## instruction -- fits the compass's own established lore too ("built to
## point toward elemental energy rather than north," world_bible.md), so
## the hint reads as that compass doing its job rather than an
## unconditional HUD feature the player never had to earn.
const COMPASS_ITEM_NAME := "Corroded Pocket Compass"


## Rotates _wild_hint to point at the nearest wild blorb (in_party == false
## -- see blorb.gd) anywhere in the world, hiding it once none are left to
## find (or the player doesn't own the compass yet). Hidden (not shown
## pointing nowhere) whenever the player instance isn't resolvable yet,
## same as at every not-yet-discovered wild blorb -- there's nothing wrong
## with that state, just nothing to point at yet.
func _update_wild_hint() -> void:
	if not Inventory.has(COMPASS_ITEM_NAME):
		_wild_hint.visible = false
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		_wild_hint.visible = false
		return

	var nearest: Node3D = null
	var nearest_dist := INF
	for blorb in get_tree().get_nodes_in_group("blorbs"):
		# The wasteland giant is a fixed Size-type resident, not a collectible
		# wild blorb. The pocket compass therefore ignores it completely.
		if blorb.in_party or (blorb is Blorb and (blorb as Blorb).blorb_type == "size"):
			continue
		var dist := _player.global_position.distance_to(blorb.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = blorb

	if nearest == null:
		# Per direct instruction, finding every wild blorb shouldn't just
		# make the compass vanish -- a fresh batch should appear elsewhere
		# instead, so the hunt keeps going. Self-limiting without any extra
		# flag: once WildernessScatter's spawn succeeds, next frame's scan
		# above finds a non-in_party blorb and this branch stops firing on
		# its own -- the cooldown below only guards the rare case where
		# placement itself keeps failing (see _random_field_pos()).
		_maybe_replenish_wild_blorbs()
		_wild_hint.visible = false
		return

	var angle: Variant = _direction_hint_angle_to(nearest)
	if angle == null:
		_wild_hint.visible = false
		return
	UIKit.set_direction_hint_angle(_wild_hint, angle as float)
	_wild_hint.visible = true


## Shared camera-relative arrow math for the regular compass and the
## direction hint. Returns null when a valid screen direction
## cannot be formed (for example, before the player's camera is ready).
func _direction_hint_angle_to(target: Node3D) -> Variant:
	var camera: Camera3D = _player.camera
	var cam_forward := -camera.global_transform.basis.z
	cam_forward.y = 0.0
	if cam_forward.length() < 0.001:
		return null
	cam_forward = cam_forward.normalized()

	var to_target := target.global_position - _player.global_position
	to_target.y = 0.0
	if to_target.length() < 0.001:
		return null
	to_target = to_target.normalized()

	# Vector3.signed_angle_to(to, UP) is positive counter-clockwise viewed
	# from above (right-hand rule around +Y) -- e.g. cam_forward=(0,0,-1)
	# (facing world -Z) and to_target=(1,0,0) (target to the player's world
	# +X, i.e. their screen-right) comes out -PI/2, not +PI/2. Control.
	# rotation is a standard 2D rotation of an icon authored pointing "up"
	# (screen -Y); solving that rotation for the same "should point right"
	# case gives +PI/2. The two conventions are negatives of each other
	# (worked through directly via the cross-product formula, not guessed;
	# confirmed at a second sample point too, target-to-the-left), hence
	# the negation below.
	var angle := -cam_forward.signed_angle_to(to_target, Vector3.UP)
	return angle


## Real-time cooldown (not a per-frame flag) between replenishment attempts,
## so a run of failed WildernessScatter placement rolls (see
## _random_field_pos()) can't retry 60 times a second -- an ordinary
## successful spawn already self-limits without needing this (see
## _update_wild_hint()'s own comment above).
const REPLENISH_COOLDOWN_MS := 3000
var _next_replenish_attempt_ms: int = 0


func _maybe_replenish_wild_blorbs() -> void:
	var now := Time.get_ticks_msec()
	if now < _next_replenish_attempt_ms:
		return
	_next_replenish_attempt_ms = now + REPLENISH_COOLDOWN_MS
	var scatter: Node = get_tree().get_first_node_in_group("wilderness_scatter")
	if scatter != null:
		scatter.spawn_replenishment_wave()
