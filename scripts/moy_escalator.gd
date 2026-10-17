extends StaticBody3D
class_name MoyEscalator

## A collision ramp with a gentle, directional ride assist. The baked slab is
## the continuous walking surface; its paired lane supplies the moving-walkway
## motion to either playable CharacterBody3D when that lane is its floor.
@export var travel_direction := Vector3.FORWARD
@export var travel_speed := 0.9


func assist_character(character: CharacterBody3D) -> void:
	if not character.is_on_floor() or character.get_floor_collider()!=self:
		return
	var direction:=travel_direction.normalized()
	if direction.length_squared()<0.5:
		return
	var along:=character.velocity.dot(direction)
	character.velocity+=direction*(travel_speed-along)
