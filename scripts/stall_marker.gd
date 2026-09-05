extends Marker3D

## Authored vendor-stall spot -- town_generator.gd reads position/rotation.y
## directly and instances stall_scene there. Drag/rotate in the editor,
## toggle Town's "Rebuild Now" to see the change.

@export_enum("stall-red", "stall-green", "stall-bench") var stall_scene: String = "stall-red"
