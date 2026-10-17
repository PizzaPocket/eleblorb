extends StaticBody3D
class_name MoyEscalator

## A collision ramp with a gentle, directional ride assist. The baked slab is
## the continuous walking surface; its paired lane supplies the moving-walkway
## motion to either playable CharacterBody3D when that lane is its floor.
@export var travel_direction := Vector3.FORWARD
@export var travel_speed := 0.9


func assist_character(character: CharacterBody3D) -> void:
	if not character.is_on_floor():
		return
	# CharacterBody3D exposes floor contacts through its slide collisions,
	# not a get_floor_collider() method. Reject side contacts with this lane
	# when the character is actually supported by some other surface.
	var riding_lane := false
	var floor_dot := cos(character.floor_max_angle)
	for index in character.get_slide_collision_count():
		var contact := character.get_slide_collision(index)
		for contact_index in contact.get_collision_count():
			if contact.get_collider(contact_index) == self and contact.get_normal(contact_index).dot(character.up_direction) >= floor_dot:
				riding_lane = true
				break
		if riding_lane: break
	if not riding_lane:
		return
	var direction:=travel_direction.normalized()
	if direction.length_squared()<0.5:
		return
	var along:=character.velocity.dot(direction)
	character.velocity+=direction*(travel_speed-along)
