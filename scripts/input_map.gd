extends Node

## Builds the project's whole control scheme in code rather than through the
## editor's Input Map tab (project.godot has no [input] section) -- keeping
## it in one script matches this project's existing pattern of centralizing
## a whole system in a script rather than editor-authored resources (see
## ui_theme.gd/ui_kit.gd for the same idea applied to UI). Every gameplay
## script reads these actions via Input.is_action_*()/get_vector() instead
## of raw KEY_*/JOY_* checks, so a keyboard+mouse press and the equivalent
## gamepad input both drive the exact same action and therefore the exact
## same gameplay code path.
##
## Must be the FIRST autoload listed in project.godot's [autoload] section --
## every other autoload and the player scene assume these actions already
## exist by the time their own _ready() runs.
##
## Mouse look is the one input this can't cover: Godot's Input Map only
## binds discrete events (keys/buttons/axes) to actions, not continuous
## relative pointer motion, so mouse-look stays as raw InputEventMouseMotion
## handling in player.gd's _unhandled_input(), same as before. Gamepad
## look (the right stick) IS routed through here (look_left/right/up/down)
## so it still ends up calling the exact same _rotate_camera() the mouse
## path calls -- one underlying action either way, just not literally the
## same InputMap entry for the mouse half.
##
## Run uses Option/Alt (KEY_ALT) on every platform, including Mac, rather
## than Command as originally spec'd there. Command can't work as a HELD
## gameplay modifier on macOS: Cmd+Space is the system Spotlight shortcut
## and fires at the OS level before Godot ever sees the event, so holding
## Run and pressing Jump (Space) opened Spotlight instead of jumping
## (confirmed by direct testing). The same problem would recur with Cmd+Tab
## (the OS app switcher) colliding with the "inventory" action below. Alt
## combos aren't reserved by macOS the same way, so unifying onto Alt/Option
## sidesteps the whole class of collision instead of chasing each one.
##
## Throw's controller binding (JOY_BUTTON_B) isn't specified by name in the
## design doc ("Appropriate controller action") -- picked as the one
## remaining unused face button once Jump/Interact/Transform claim A/X/Y.
## (That was the original layout -- see the direct instruction below for
## how Jump/Run/Transform's buttons were reshuffled from it.)
##
## Per direct instruction: Jump moved off A onto Y, which freed up A for
## Run (off its original L3-click binding -- holding the stick down while
## also trying to steer with it was the reason L3 was picked in the first
## place, but a face button reads as more comfortable to hold through a
## run than clicking the stick). Transform, which used to share Y with
## Jump, drops back to just its D-pad Up binding now that Y is Jump's
## alone -- still on top of the keyboard's T, not instead of it.
const ACTIONS := {
	"move_left": {"keys": [KEY_A], "joy_axis": JOY_AXIS_LEFT_X, "joy_sign": -1.0},
	"move_right": {"keys": [KEY_D], "joy_axis": JOY_AXIS_LEFT_X, "joy_sign": 1.0},
	"move_forward": {"keys": [KEY_W], "joy_axis": JOY_AXIS_LEFT_Y, "joy_sign": -1.0},
	"move_back": {"keys": [KEY_S], "joy_axis": JOY_AXIS_LEFT_Y, "joy_sign": 1.0},
	"look_left": {"joy_axis": JOY_AXIS_RIGHT_X, "joy_sign": -1.0},
	"look_right": {"joy_axis": JOY_AXIS_RIGHT_X, "joy_sign": 1.0},
	"look_up": {"joy_axis": JOY_AXIS_RIGHT_Y, "joy_sign": -1.0},
	"look_down": {"joy_axis": JOY_AXIS_RIGHT_Y, "joy_sign": 1.0},
	"jump": {"keys": [KEY_SPACE], "joy_buttons": [JOY_BUTTON_Y]},
	"run": {"keys": [KEY_ALT], "joy_buttons": [JOY_BUTTON_A]},
	"interact": {"keys": [KEY_F], "joy_buttons": [JOY_BUTTON_X]},
	"transform": {"keys": [KEY_T], "joy_buttons": [JOY_BUTTON_DPAD_UP]},
	"switch_blorbus": {"keys": [KEY_B], "joy_buttons": [JOY_BUTTON_DPAD_LEFT]},
	"left_arm_power": {"keys": [KEY_Q], "joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"left_leg_power": {"keys": [KEY_SHIFT], "joy_axis": JOY_AXIS_TRIGGER_LEFT, "joy_sign": 1.0},
	"right_arm_power": {"keys": [KEY_E], "joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	"right_leg_power": {"keys": [KEY_C], "joy_axis": JOY_AXIS_TRIGGER_RIGHT, "joy_sign": 1.0},
	"throw": {"mouse_button": MOUSE_BUTTON_LEFT, "joy_buttons": [JOY_BUTTON_B]},
	"inventory": {"keys": [KEY_TAB], "joy_buttons": [JOY_BUTTON_BACK]},
	"pause": {"keys": [KEY_ESCAPE], "joy_buttons": [JOY_BUTTON_START]},
	# Godot's own Control/Viewport focus-navigation system checks for these
	# four exact action names internally (not configurable to a different
	# name) to move focus between focusable Controls and to fire a focused
	# Button's own `pressed` -- defining them explicitly here, like every
	# other action in this file, rather than relying on Godot's own
	# built-in project-default bindings existing/matching what this
	# project's own bindings already use elsewhere. Reuses the SAME
	# physical buttons "interact" (X) and "throw" (B) already use -- safe to
	# double up, since ui_accept/ui_cancel only have any effect once some
	# Control actually has focus, which only happens while a menu is open
	# (gameplay itself is paused whenever that's true, so "run" can't also
	# be firing at the same moment).
	"ui_up": {"keys": [KEY_UP], "joy_axis": JOY_AXIS_LEFT_Y, "joy_sign": -1.0},
	"ui_down": {"keys": [KEY_DOWN], "joy_axis": JOY_AXIS_LEFT_Y, "joy_sign": 1.0},
	"ui_left": {"keys": [KEY_LEFT], "joy_axis": JOY_AXIS_LEFT_X, "joy_sign": -1.0},
	"ui_right": {"keys": [KEY_RIGHT], "joy_axis": JOY_AXIS_LEFT_X, "joy_sign": 1.0},
	"ui_accept": {"keys": [KEY_ENTER, KEY_KP_ENTER], "joy_buttons": [JOY_BUTTON_X]},
	# Shoulder buttons keep their world arm-power actions, but while a modal
	# owns input they also provide the conventional previous/next tab pair.
	"menu_tab_previous": {"joy_buttons": [JOY_BUTTON_LEFT_SHOULDER]},
	"menu_tab_next": {"joy_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
	# B specifically -- contextual menu "back": first clears a selection at
	# the current level, then closes from the top level. Not bound to Escape
	# /KEY_ESCAPE here, deliberately: Escape
	# already drives the separate "pause" action (pause_menu.gd), and firing
	# both from the same keypress risks a same-frame ordering race between
	# whichever menu is open closing itself and pause_menu.gd's own
	# modal_open check, which could pop the pause menu open right as this
	# one closes. Keyboard users close a menu via the same key that opened
	# it (Tab/"inventory" is already a toggle) instead.
	"ui_cancel": {"joy_buttons": [JOY_BUTTON_B]},
}


func _ready() -> void:
	for action_name: String in ACTIONS:
		_register(action_name, ACTIONS[action_name])


func _register(action_name: String, spec: Dictionary) -> void:
	# Re-running this (e.g. a scene reload re-entering the autoload) would
	# otherwise pile up duplicate events on top of whatever's already there.
	if InputMap.has_action(action_name):
		InputMap.action_erase_events(action_name)
	else:
		InputMap.add_action(action_name, 0.2)

	for keycode in spec.get("keys", []):
		var key_event := InputEventKey.new()
		key_event.physical_keycode = keycode
		InputMap.action_add_event(action_name, key_event)

	if spec.has("mouse_button"):
		var mouse_event := InputEventMouseButton.new()
		mouse_event.button_index = spec["mouse_button"]
		InputMap.action_add_event(action_name, mouse_event)

	for button_index in spec.get("joy_buttons", []):
		var joy_button_event := InputEventJoypadButton.new()
		joy_button_event.button_index = button_index
		InputMap.action_add_event(action_name, joy_button_event)

	if spec.has("joy_axis"):
		var joy_axis_event := InputEventJoypadMotion.new()
		joy_axis_event.axis = spec["joy_axis"]
		joy_axis_event.axis_value = spec["joy_sign"]
		InputMap.action_add_event(action_name, joy_axis_event)
