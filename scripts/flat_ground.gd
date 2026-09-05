class_name FlatGround
extends StaticBody3D

## Minimal placeholder "Terrain" for a kingdom scene (see
## kingdom_bootstrap.gd). Kingdoms don't need terrain_generator.gd's
## biome-specific heightmap logic -- that's scoped to the outskirts hub's
## own canyon/jungle/lake/wasteland layout -- but blorb.gd, player.gd, and
## xiao_hou_zi.gd all hard-require a "../Terrain" sibling exposing
## get_mesh_height(x, z), so this satisfies that same contract with an
## honest flat plane until each kingdom gets real ground of its own.

@export var half_size: float = 120.0
@export var ground_color: Color = Color(0.5, 0.5, 0.55)


func get_mesh_height(_x: float, _z: float) -> float:
	return 0.0


## No lake on a flat placeholder ground -- stubbed so Player's buoyancy
## check (which hard-requires this contract on every Terrain sibling, see
## terrain_generator.gd's own is_lake_area/get_lake_water_level) doesn't
## crash in a kingdom scene that hasn't got real water of its own.
func is_lake_area(_world_pos: Vector2) -> bool:
	return false


func get_lake_water_level() -> float:
	return 0.0


## Flat placeholder ground has one normal everywhere -- see blorb.gd's
## _surface_normal_at(), which falls back to this whenever its own raycast
## misses a real collider.
func get_mesh_normal(_x: float, _z: float) -> Vector3:
	return Vector3.UP


func _ready() -> void:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(half_size * 2.0, half_size * 2.0)
	mesh_instance.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = ground_color
	material.roughness = 0.85
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(half_size * 2.0, 1.0, half_size * 2.0)
	collision.shape = shape
	collision.position = Vector3(0.0, -0.5, 0.0)
	add_child(collision)
