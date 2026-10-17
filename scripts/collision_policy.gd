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
			# A StaticMerge mesh stands for every physical piece folded into it.
			physical_visuals += int(node.get_meta("merged_physical", 1))
	if physical_visuals != policy_colliders:
		push_warning(
			"Collision policy mismatch on %s: %d physical visuals, %d colliders"
			% [body.name, physical_visuals, policy_colliders]
		)
		return false
	return true


## Godot primitive shapes cannot represent shear. Fitting a building with
## unequal X/Z scale makes its pitched boxes shear even though the mesh looks
## correct. Bake those eight actual transformed corners into an unscaled hull.
static func fit_sheared_static_boxes(root: Node3D) -> int:
	var bodies: Dictionary={}
	var count:=0
	for node in root.find_children("*","CollisionShape3D",true,false):
		var collision:=node as CollisionShape3D
		if not collision.shape is BoxShape3D or collision.disabled: continue
		var owner_body:=collision.get_parent() as StaticBody3D
		if owner_body==null: continue
		var moving:=false
		var ancestor: Node=owner_body
		while ancestor!=root and ancestor!=null:
			if ancestor.get_script()!=null: moving=true
			ancestor=ancestor.get_parent()
		if moving: continue
		var basis:=collision.global_basis
		if absf(basis.x.normalized().dot(basis.y.normalized()))<0.0001 and absf(basis.x.normalized().dot(basis.z.normalized()))<0.0001 and absf(basis.y.normalized().dot(basis.z.normalized()))<0.0001: continue
		var key:=str(owner_body.collision_layer)+":"+str(owner_body.collision_mask)
		if not bodies.has(key):
			var body:=StaticBody3D.new()
			body.name="FittedSlopeCollision"
			body.collision_layer=owner_body.collision_layer
			body.collision_mask=owner_body.collision_mask
			root.add_child(body,true)
			bodies[key]=body
		var target: StaticBody3D=bodies[key]
		var frame:=target.global_transform.affine_inverse()*collision.global_transform
		var half: Vector3=collision.shape.size*0.5
		var points:=PackedVector3Array()
		for x: float in [-1,1]:
			for y: float in [-1,1]:
				for z: float in [-1,1]: points.append(frame*(half*Vector3(x,y,z)))
		var fitted:=CollisionShape3D.new()
		var hull:=ConvexPolygonShape3D.new();hull.points=points
		fitted.shape=hull
		fitted.set_meta("fitted_from",str(collision.get_path()))
		for meta in collision.get_meta_list(): fitted.set_meta(meta,collision.get_meta(meta))
		target.add_child(fitted)
		collision.free()
		count+=1
	return count
