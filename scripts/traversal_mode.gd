class_name TraversalMode
extends RefCounted

## One traversal power, for one body. Every suit power, accessory and
## traversal mode in the game is one of these: swimming, the mermaid tail,
## the penguin suit, the snowboard, both kinds of skates, the dirt bike,
## flight, the fire jets, lava walking and diving, zero-gravity propulsion.
##
## One instance per body, so a mode's own state lives in the instance rather
## than in a dictionary keyed by whoever is being driven. A mode never names a
## character: what it needs, it asks the context and the rig for. That is the
## whole point -- a power written once is then available to anybody whose suit
## satisfies it, on any rig.
##
## See docs/traversal_powers_architecture.md for how these fit together.


## A stable name, for the parity probe and for debugging.
func id() -> StringName:
	return &"traversal_mode"


## Whether this body could engage the power at all right now: the suit pieces
## and items it needs, plus any profile capability it requires. Cheap; called
## every frame before update().
func is_available(_ctx: TraversalContext) -> bool:
	return false


## Runs the power for this frame. Returns true if it took ownership of the
## body's movement, in which case the director stops here and no later mode
## runs. Returning false leaves the frame to the next mode.
func update(_ctx: TraversalContext) -> bool:
	return false


## Poses the rig, applied only for the mode that owned the frame. Written
## against rig-neutral joint names, and expected to ask the rig what it
## actually has before assuming an ankle or a neck exists.
func pose(_ctx: TraversalContext) -> void:
	pass
