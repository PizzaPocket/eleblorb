class_name CollisionPolicy
extends RefCounted

## Shared construction policy for readable world objects in this platformer.
## Substantial geometry should be built through one of the solid helpers;
## visual-only pieces must be deliberately marked decorative. Collision uses
## inexpensive primitives unless exact platforming geometry is warranted.

const POLICY_META := &"collision_policy"
const SOLID := &"solid"
const PARKOUR := &"parkour"
const DECORATIVE := &"decorative"
const HAZARD := &"hazard"


static func add_box(
	body: StaticBody3D, visual: Node3D, size: Vector3,
	local_position: Vector3 = Vector3.ZERO, basis: Basis = Basis(),
	parkourable: bool = true
) -> CollisionShape3D:
	visual.set_meta(POLICY_META, PARKOUR if parkourable else SOLID)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = local_position
	collision.basis = basis
	collision.set_meta(POLICY_META, PARKOUR if parkourable else SOLID)
	body.add_child(collision)
	return collision


static func add_cylinder(
	body: StaticBody3D, visual: Node3D, radius: float, height: float,
	local_position: Vector3 = Vector3.ZERO, parkourable: bool = true
) -> CollisionShape3D:
	visual.set_meta(POLICY_META, PARKOUR if parkourable else SOLID)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position = local_position
	collision.set_meta(POLICY_META, PARKOUR if parkourable else SOLID)
	body.add_child(collision)
	return collision


static func mark_decorative(visual: Node) -> void:
	visual.set_meta(POLICY_META, DECORATIVE)


static func mark_hazard(visual: Node) -> void:
	visual.set_meta(POLICY_META, HAZARD)


static func validate_body(body: StaticBody3D) -> bool:
	# Development assertion for procedural builders using this policy. Each
	# solid/parkour visual added by the helpers must retain a paired tagged
	# collider; decorative and hazard visuals intentionally do not count.
	var physical_visuals := 0
	var policy_colliders := 0
	for node in body.find_children("*", "Node", true, false):
		var policy: StringName = node.get_meta(POLICY_META, &"") as StringName
		if node is CollisionShape3D and policy in [SOLID, PARKOUR]:
			policy_colliders += 1
		elif node is GeometryInstance3D and policy in [SOLID, PARKOUR]:
			physical_visuals += 1
	if physical_visuals != policy_colliders:
		push_warning(
			"Collision policy mismatch on %s: %d physical visuals, %d colliders"
			% [body.name, physical_visuals, policy_colliders]
		)
		return false
	return true
