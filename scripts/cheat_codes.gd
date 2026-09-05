extends Node

## Hidden global cheat-code system, per direct instruction: entering the
## classic Konami Code (Up, Up, Down, Down, Left, Right, Left, Right, B, A,
## Start) TOGGLES every cheat this game currently has on, or back off again
## if entered a second time (per direct correction: "doing it again will
## toggle it off"). Currently that's just one cheat -- see `enabled`'s own
## doc comment on what it unlocks -- but this is deliberately built as a
## single shared on/off switch other systems can check going forward,
## rather than a one-off flag wired directly into player.gd, so a future
## second cheat only needs to read `enabled`/listen to `toggled`, not
## reimplement its own code-entry detector.
##
## Uses raw InputEventKey (physical_keycode), not one of input_map.gd's own
## registered actions, for the same reason mouse-look stays raw too (see
## that file's own class doc comment) -- B/A/Start here are meant to be the
## classic NES controller buttons the Konami Code has always used, not
## whatever this project's own "switch_blorbus"/"move_left"/"pause" actions
## happen to already bind those same physical keys to. Piggybacking on
## those actions would make the code impossible to type without ALSO
## triggering ordinary gameplay (switch_blorbus toggling on the B press,
## move_left nudging the player on the A press, the pause menu opening on
## Enter) -- which is fine and simply an accepted side effect of typing on
## the same keyboard everything else reads from, not something this file
## tries to suppress or work around.

## True once the code's been entered an odd number of times this session.
## player.gd's own blorb-suit scaling reads this directly (see its
## _current_blorb_suit_rig_scale()) rather than mirroring a local copy of
## it, and connects to `toggled` below to react the instant it changes (see
## player.gd's own _apply_blorb_suit_rig_scale()).
var enabled := false

## Also emitted with the new value of `enabled` every time the code lands,
## so listeners don't need to poll every frame.
signal toggled(is_enabled: bool)

const _SEQUENCE: Array[Key] = [
	KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A, KEY_ENTER,
]

var _progress := 0


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key_event := event as InputEventKey
	if key_event.physical_keycode == _SEQUENCE[_progress]:
		_progress += 1
		if _progress == _SEQUENCE.size():
			_progress = 0
			enabled = not enabled
			toggled.emit(enabled)
			Hud.show_message("Cheats enabled." if enabled else "Cheats disabled.")
	else:
		# A wrong key still counts as a fresh attempt's own first key rather
		# than a hard reset to zero -- needed because the sequence repeats
		# Up/Down and Left/Right back to back; without this, mistiming the
		# THIRD key press as another Up (instead of the expected Down) would
		# strand progress at 0 even though that Up is exactly what a brand
		# new attempt needs as its own first key.
		_progress = 1 if key_event.physical_keycode == _SEQUENCE[0] else 0
