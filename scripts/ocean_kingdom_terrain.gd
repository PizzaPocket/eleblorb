extends StaticBody3D

## Water terrain for the ocean kingdom (see kingdom_bootstrap.gd) -- "make the
## whole thing just water," per direct instruction. A submerged floor
## mesh+collision (mirroring flat_ground.gd's PlaneMesh+BoxShape3D technique)
## plus a separate non-collidable water-surface sheet at a constant level,
## mirroring terrain_generator.gd's own _build_eastern_lake() sheet.
## is_lake_area() is unconditionally true everywhere in the kingdom, so
## player.gd's _update_lake_buoyancy() treats the whole kingdom as swimmable
## lake -- its own exemption for global_position.y > water_level is what lets
## OceanKingdomDock's floating deck coexist with this, with zero
## special-casing needed (see ocean_kingdom_dock.gd).

const HALF_SIZE := 900.0  # matches terrain_generator.gd's own FIELD_HALF_SIZE, so open water reaches as far as the other kingdoms' ground before hitting the collision edge
const FLOOR_Y := -14.0
const WATER_LEVEL := 0.0
const FLOOR_COLOR := Color(0.14, 0.26, 0.28)
const WATER_COLOR := Color(0.16, 0.45, 0.52, 0.55)


func get_mesh_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func is_lake_area(_world_pos: Vector2) -> bool:
	return true


func get_lake_water_level() -> float:
	return WATER_LEVEL


## The submerged floor is a flat plane, so it has one normal everywhere --
## see blorb.gd's _surface_normal_at(), which falls back to this whenever
## its own raycast misses a real collider.
func get_mesh_normal(_x: float, _z: float) -> Vector3:
	return Vector3.UP


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_build_floor()
	_build_water_surface()


func _build_floor() -> void:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_SIZE * 2.0, HALF_SIZE * 2.0)
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0.0, FLOOR_Y, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = FLOOR_COLOR
	material.roughness = 0.9
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF_SIZE * 2.0, 1.0, HALF_SIZE * 2.0)
	collision.shape = shape
	collision.position = Vector3(0.0, FLOOR_Y - 0.5, 0.0)
	add_child(collision)


## Visual only -- no collision, matching terrain_generator.gd's own lake
## surface sheet, so the player swims through it rather than standing on it.
func _build_water_surface() -> void:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_SIZE * 2.0, HALF_SIZE * 2.0)
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0.0, WATER_LEVEL, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = WATER_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.05
	material.metallic = 0.2
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)
