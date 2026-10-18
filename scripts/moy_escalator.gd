extends StaticBody3D
class_name MoyEscalator

## A collision ramp with a gentle, directional ride assist. The baked slab is
## the continuous walking surface; its paired lane supplies the moving-walkway
## motion to either playable CharacterBody3D when that lane is its floor.
@export var travel_direction := Vector3.FORWARD
@export var travel_speed := 0.9
@export var helix_center := Vector3.ZERO
@export var helix_rise_per_radian := 0.0
@export var helix_direction := 1.0
@export var belt_length := 0.0
@export var belt_width := 1.0
@export var belt_thickness := 0.32

func _process(delta: float) -> void:
	if belt_length > 0.1:
		var path_length := 2.0 * belt_length + PI * belt_thickness
		for tread in get_children():
			if not tread is MeshInstance3D:
				continue
			if tread.has_meta("handrail_distance"):
				var rail_distance := fposmod(float(tread.get_meta("handrail_distance")) + travel_speed * delta, belt_length)
				var rail_position: Vector3 = tread.position
				rail_position.x = rail_distance - belt_length * 0.5
				tread.position = rail_position
				continue
			if not tread.has_meta("belt_distance"):
				continue
			var distance := fposmod(float(tread.get_meta("belt_distance")) + travel_speed * delta, path_length)
			var point := _belt_point(distance)
			tread.position = Vector3(point.x, point.y, float(tread.get_meta("belt_z",0.0)))
	var helix_span := float(get_meta("helix_span", 0.0))
	if helix_span <= 0.001:
		return
	var base_radius := float(get_meta("helix_tread_radius", 2.7))
	var arc_length := helix_span * base_radius
	for tread in get_children():
		if not tread is MeshInstance3D or not tread.has_meta("helix_fraction"):
			continue
		var fraction := float(tread.get_meta("helix_fraction"))
		fraction = fposmod(fraction + delta * travel_speed * helix_direction / maxf(arc_length, 0.1), 1.0)
		tread.set_meta("helix_fraction", fraction)
		var angle := lerpf(float(get_meta("helix_a0")), float(get_meta("helix_a1")), fraction)
		var y := lerpf(float(get_meta("helix_y0")), float(get_meta("helix_y1")), fraction)
		var radius := float(tread.get_meta("helix_radius",base_radius))
		var height_offset:=float(tread.get_meta("helix_offset_y",0.05))
		tread.position = Vector3(cos(angle) * radius, y + height_offset, sin(angle) * radius)
		tread.rotation.y = -angle - PI * 0.5

func _belt_point(distance: float) -> Vector2:
	var radius := belt_thickness * 0.5
	var half := belt_length * 0.5
	var top_length := belt_length
	var arc_length := PI * radius
	if distance < top_length:
		return Vector2(-half + distance, radius)
	distance -= top_length
	if distance < arc_length:
		var angle := PI * 0.5 - distance / radius
		return Vector2(half + cos(angle) * radius, sin(angle) * radius)
	distance -= arc_length
	if distance < top_length:
		return Vector2(half - distance, -radius)
	distance -= top_length
	var angle := -PI * 0.5 - distance / radius
	return Vector2(-half + cos(angle) * radius, sin(angle) * radius)


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
	if absf(helix_rise_per_radian)>0.0001:
		var local_point:=to_local(character.global_position)
		var radial:=Vector2(local_point.x-helix_center.x,local_point.z-helix_center.z)
		if radial.length()>0.1:
			var bearing:=atan2(radial.y,radial.x)
			var tangent:=Vector3(-sin(bearing),helix_rise_per_radian/maxf(radial.length(),0.1),cos(bearing)).normalized()*helix_direction
			direction=global_basis*tangent
			direction.y=0.0
			direction=direction.normalized()
	if direction.length_squared()<0.5:
		return
	var along:=character.velocity.dot(direction)
	character.velocity+=direction*(travel_speed-along)
