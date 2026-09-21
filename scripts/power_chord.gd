class_name PowerChord
extends RefCounted

## A two-button hold that toggles something on and off, for any character
## (docs/traversal_powers_architecture.md).
##
## Both leg buttons together call up the snowboard; both arm buttons together
## pop the dirt bike's wheelie. Each of those was written out twice, once per
## character, as the same five lines around the same pair of flags, and a
## fifth copy would have followed the next vehicle.
##
## Having something in hand does not merely fail to fire the toggle: it stops
## the chord registering at all, so putting an item away and taking it out
## again cannot flip the state behind the player's back. The same goes for a
## menu being open.

## The chords this game uses.
const LEGS: Array[String] = ["left_leg_power", "right_leg_power"]
const ARMS: Array[String] = ["left_arm_power", "right_arm_power"]

## Whether the thing this chord calls up is currently on.
var toggled := false

var _was_pressed := false


## One frame of the latch. `available` is whether the suit can do this at all
## right now; losing it puts the toggle away rather than leaving it armed for
## whenever the suit comes back.
##
## Availability gates the toggle but not the chord itself, so gaining the
## legs or arms while already holding both buttons does not call the thing up
## unasked. The two copies of this disagreed about that; the snowboard's
## folded availability into the press and so did fire unasked, and it follows
## the dirt bike's safer reading now. Returns the new state.
func update(available: bool, actions: Array[String] = LEGS) -> bool:
	var pressed := _held(actions)
	var just_formed := pressed and not _was_pressed
	_was_pressed = pressed
	if not available:
		toggled = false
	elif just_formed:
		toggled = not toggled
	return toggled


static func _held(actions: Array[String]) -> bool:
	if UIState.modal_open or not HeldItem.current.is_empty():
		return false
	for action in actions:
		if not Input.is_action_pressed(action):
			return false
	return true
