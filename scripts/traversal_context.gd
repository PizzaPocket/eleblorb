class_name TraversalContext
extends RefCounted

## Everything a traversal power needs for one frame of one body, and nothing
## about which character that body is. Powers read this and write to
## body.velocity, body.global_position and the rig; none of them names a
## character or reaches for Player.

## The reference figure every authored length in this project was tuned
## against (PlayableCharacterProfile.human().standing_height). scaled() turns
## such a length into the equivalent for whatever body is actually being
## driven, so a power written for the human stays meaningful on a rig a
## quarter the size instead of quietly becoming enormous.
const REFERENCE_STANDING_HEIGHT := 1.896

var body: CharacterBody3D
var profile: PlayableCharacterProfile
var suit: BlorbSuitController
var rig: RigAdapter
var terrain: Node
## The rendered body root, which carries the character's facing. Poses that
## need "which way is this character's own right" read it from here rather
## than from the collision body, which this project never rotates.
var visuals: Node3D
var delta := 0.0
## The frame's intent, already resolved into world space by whoever is
## driving: a direction, whether sprint is held, and whether jump was pressed
## this frame.
var direction := Vector3.ZERO
var sprinting := false
var jump_pressed := false
var grounded := false


func _init(
	for_body: CharacterBody3D, for_profile: PlayableCharacterProfile,
	for_rig: RigAdapter, for_suit: BlorbSuitController = null, for_terrain: Node = null
) -> void:
	body = for_body
	profile = for_profile
	rig = for_rig
	suit = for_suit
	terrain = for_terrain


## A length authored against the human figure, in this body's own terms.
func scaled(metres: float) -> float:
	return metres * height_ratio()


func height_ratio() -> float:
	if profile == null or REFERENCE_STANDING_HEIGHT <= 0.0:
		return 1.0
	return profile.standing_height / REFERENCE_STANDING_HEIGHT


## A length expressed directly as a fraction of this body's standing height.
func height_fraction(fraction: float) -> float:
	return profile.standing_height * fraction if profile != null else fraction


func has_capability(capability: StringName) -> bool:
	return profile != null and bool(profile.capabilities.get(capability, false))
