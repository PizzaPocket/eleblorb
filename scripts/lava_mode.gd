class_name LavaMode
extends TraversalMode

## Lava, shared by every character
## (docs/traversal_powers_architecture.md).
##
## A molten pool answers to the suit in three ways, and the rules are the
## same whoever walks up to it: two landed fire leg blorbs float a body on
## the surface, the complete Lava Helm formation lets it swim the volume
## outright, and anything less is turned back at the edge.
##
## That last rule only ever existed for the human, so every other character
## could stroll into the pool untouched. It lives here now, asked for by
## whoever is being driven.

## How far above the molten surface a body still counts as touching it.
const CONTACT_TOLERANCE := 0.45
const WARNING_COOLDOWN := 1.25

## What the suit makes of a molten surface right now.
enum Contact {
	## Turned back at the edge.
	BARRED,
	## Carried on top of it by two fire legs.
	SURFACE,
	## Swimming the volume in the full formation.
	IMMERSED,
}

var _warning_cooldown := 0.0


func id() -> StringName:
	return &"lava"


func is_available(ctx: TraversalContext) -> bool:
	return ctx.suit != null and contact(ctx.suit) != Contact.BARRED


## The suit's standing with lava, before any question of where the body is.
static func contact(suit: BlorbSuitController) -> Contact:
	if suit == null:
		return Contact.BARRED
	if suit.has_full_lava_suit():
		return Contact.IMMERSED
	if suit.has_lava_safe_legs():
		return Contact.SURFACE
	return Contact.BARRED


static func terrain_has_lava(terrain: Node) -> bool:
	return (
		terrain != null
		and terrain.has_method("is_lava_area")
		and terrain.has_method("get_lava_surface_height")
	)


## Lava is traversable terrain only for a suit that answers for it. A high
## jump or a flight may pass over the pool; contact without the protection
## returns the body to the nearest solid edge, and the same rule catches a
## leg blorb coming off while already standing out there.
##
## `underside_y` is where this body's lowest rendered point is, which each rig
## measures its own way: a level flier's origin can hang a metre below the
## body it is drawing. `origin_lift` is how far that body's origin sits above
## the ground it stands on, so the escape puts its feet down rather than its
## middle. Returns true if the body was moved.
func enforce_access(ctx: TraversalContext, underside_y: float, origin_lift: float) -> bool:
	_warning_cooldown = maxf(_warning_cooldown - ctx.delta, 0.0)
	var terrain: Node = ctx.terrain
	if not terrain_has_lava(terrain) or not terrain.has_method("get_lava_escape_position"):
		return false
	if contact(ctx.suit) != Contact.BARRED:
		return false
	var body := ctx.body
	var xz := Vector2(body.global_position.x, body.global_position.z)
	if not bool(terrain.is_lava_area(xz)):
		return false
	var surface: float = terrain.get_lava_surface_height(xz)
	if underside_y > surface + CONTACT_TOLERANCE:
		return false
	var safe_position: Vector3 = terrain.get_lava_escape_position(xz)
	body.global_position = safe_position + Vector3.UP * origin_lift
	body.velocity = Vector3.ZERO
	if _warning_cooldown <= 0.0:
		# Plain reaction, not an explanation of the requirement -- see
		# CLAUDE.md's "In-game text and player guidance" rule.
		Hud.show_message("The heat drives you back.")
		_warning_cooldown = WARNING_COOLDOWN
	return true
