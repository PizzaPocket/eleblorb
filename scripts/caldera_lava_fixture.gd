class_name CalderaLavaFixture
extends RefCounted

## One construction path for architectural lava.  Pools, immersion floors and
## beds all use NatureProps' canonical material and LavaSurfaceFX; only their
## containing refractory architecture and the scale of the living surface vary.


static func add_surface(parent: Node3D, name_text: String, half: Vector2, at: Vector3, exponent: float, seed_value: int) -> MeshInstance3D:
	var lava := MeshInstance3D.new()
	lava.name = name_text
	lava.mesh = SolidModel.extruded_profile_mesh(0.03, half, exponent, 72)
	lava.material_override = NatureProps.build_lava_material()
	lava.position = at
	lava.set_meta("caldera_lava_surface", true)
	lava.rotation.z = PI * 0.5
	parent.add_child(lava)
	CollisionPolicy.mark_decorative(lava)
	var scale_factor := clampf(minf(half.x, half.y) / 3.0, 0.16, 0.55)
	LavaSurfaceFX.attach(parent, [at + Vector3(0.0, 0.025, 0.0)], seed_value, scale_factor)
	return lava


static func add_bed(parent: StaticBody3D, name_text: String, centre: Vector2, half: Vector2, height: float, wall: float, lava_y: float, stone_colour: Color, seed_value: int) -> void:
	var solid := CSGCombiner3D.new()
	solid.name = name_text
	solid.use_collision = true
	solid.collision_layer = 1
	solid.collision_mask = 0
	solid.position = Vector3(centre.x, 0.0, centre.y)
	parent.add_child(solid)
	var stone := SolidModel.material(stone_colour, 0.7, 0.0)
	var shell := SolidModel.add_profile(solid, "Shell", height, half, 4.0, CSGShape3D.OPERATION_UNION, stone, Vector3(0, height * 0.5, 0), 72)
	shell.rotation.z = PI * 0.5
	var hollow_half := half - Vector2.ONE * wall
	var hollow := SolidModel.add_profile(solid, "Hollow", height, hollow_half, 4.0, CSGShape3D.OPERATION_SUBTRACTION, stone, Vector3(0, height * 0.5 + 0.18, 0), 72)
	hollow.rotation.z = PI * 0.5
	add_surface(parent, "%sLava" % name_text, hollow_half - Vector2.ONE * 0.005, Vector3(centre.x, lava_y, centre.y), 4.0, seed_value)
