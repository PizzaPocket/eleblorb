class_name EyeBlink
extends RefCounted

## Shared "how open is this eye right now" clock for every eye style in the
## project -- blorb creatures (blorb_face.gd), player/NPC figures
## (figure_eyes.gd), and the blorb suit's own eyes (blorb_suit.gd). A
## natural, randomized-interval closed/open cycle rather than a fixed
## metronome tick, so a crowd of blorbs/figures doesn't all blink in visible
## unison.
##
## Pure timing/state: this class never touches a Node directly except via
## apply()'s convenience wrapper below. Every eye mesh in this project is
## authored with its own local Y as the tall/vertical axis and otherwise
## leaves eye.scale.y sitting at 1.0 (whatever gets flattened for a
## particular eye style is always X or Z instead -- see blorb_face.gd's
## eye.scale, figure_eyes.gd's eye.scale, blorb_suit.gd's _update_face) --
## so scaling that one axis toward CLOSED_OPENNESS reads as an eyelid
## closing regardless of the eye's own basis/rotation or which other axis
## it's flattened along.

const MIN_INTERVAL := 2.5
const MAX_INTERVAL := 6.5
const BLINK_DURATION := 0.12
## Not fully 0 -- a perfectly flat, zero-height mesh reads as a rendering
## glitch (a vanishing sliver), not a closed eyelid.
const CLOSED_OPENNESS := 0.05


static func new_state() -> Dictionary:
	return {"timer": randf_range(MIN_INTERVAL, MAX_INTERVAL), "blink_t": -1.0}


## Advances the clock by delta -- negative blink_t means "not currently
## blinking, counting down to the next one"; 0..BLINK_DURATION means
## "mid-blink."
static func advance(state: Dictionary, delta: float) -> void:
	if (state["blink_t"] as float) >= 0.0:
		state["blink_t"] = (state["blink_t"] as float) + delta
		if (state["blink_t"] as float) >= BLINK_DURATION:
			state["blink_t"] = -1.0
			state["timer"] = randf_range(MIN_INTERVAL, MAX_INTERVAL)
		return
	state["timer"] = (state["timer"] as float) - delta
	if (state["timer"] as float) <= 0.0:
		state["blink_t"] = 0.0


## 1.0 = fully open, CLOSED_OPENNESS = fully closed -- a triangle wave over
## BLINK_DURATION (closes over the first half, reopens over the second).
static func openness(state: Dictionary) -> float:
	var t: float = state["blink_t"]
	if t < 0.0:
		return 1.0
	var phase := t / BLINK_DURATION
	var closed_amount := 1.0 - absf(phase * 2.0 - 1.0)
	return lerpf(1.0, CLOSED_OPENNESS, closed_amount)


## Convenience for the common case (blorb.gd, procedural_figure.gd's
## player/NPC rig): advance the clock and stamp the resulting openness onto
## each given eye node's local Y scale in one call.
static func apply(state: Dictionary, delta: float, eyes: Array) -> void:
	advance(state, delta)
	var o := openness(state)
	for eye in eyes:
		if is_instance_valid(eye):
			(eye as Node3D).scale.y = o
