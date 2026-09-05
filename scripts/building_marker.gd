extends Marker3D

## Authored building footprint -- town_generator.gd reads this marker's
## position (X/Z; Y is ignored, ground height is computed instead) and
## rotation.y directly, plus size/floors below, to assemble that building's
## walls/roof/collision. Drag or rotate this marker in the editor to move
## or turn the building; toggle Town's "Rebuild Now" to see the change.

## Footprint in 1m grid cells. x (door-wall width) must be >= 3 (room for 2
## corners + a door cell). y (depth) is locked to 2 elsewhere -- that's how
## the kit's roof pieces are meant to go together, see town_generator.gd's
## _build_roof -- so changing it here won't do anything useful.
@export var size: Vector2 = Vector2(4, 2)
@export_range(1, 3) var floors: int = 1
## "high" (roof-high*, steep classic-cottage pitch, the only style before
## this) or "low" (roof*, the kit's shorter/shallower pitch) -- same
## footprint either way (verified off both GLBs' own vertex data), so this
## is purely a look choice. Mixing both across the village's buildings
## matches the kit's own preview image, which doesn't use one pitch
## uniformly.
@export_enum("high", "low") var roof_style: String = "high"
