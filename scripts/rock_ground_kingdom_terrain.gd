extends StaticBody3D

## First-pass ground for the Rock and Ground Kingdom (see kingdom_bootstrap.gd)
## -- a flat sandstone-badlands floor (same FlatGround-style PlaneMesh+
## BoxShape3D technique every kingdom's placeholder terrain starts from --
## see fire_kingdom_terrain.gd's own identical class doc comment) with
## scattered rock outcroppings for texture, mirroring fire_kingdom_terrain.
## gd's own _scatter_rocks() at a similar first-pass scale. No lava lake
## here -- this kingdom's own centerpiece is its wild Rock/Ground blorb
## population (see rock_ground_kingdom_blorbs.gd), not a landmark hazard.

const HALF_SIZE := 220.0
const FLOOR_Y := 0.0
const FLOOR_COLOR := Color(0.42, 0.32, 0.2)
const ROCK_COUNT := 30
const ROCK_MIN_RADIUS := 0.7
const ROCK_MAX_RADIUS := 2.6
## A handful of taller spires for visual variety, same technique
## wilderness_scatter.gd's own canyon-biome hoodoos use.
const SPIRE_COUNT := 5
const SPIRE_MIN_RADIUS := 1.6
const SPIRE_MAX_RADIUS := 2.6

var _rng := RandomNumberGenerator.new()


func get_mesh_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func is_lake_area(_world_pos: Vector2) -> bool:
	return false


func get_lake_water_level() -> float:
	return 0.0


func get_mesh_normal(_x: float, _z: float) -> Vector3:
	return Vector3.UP


func _ready() -> void:
	_rng.seed = 20260907
	collision_layer = 1
	collision_mask = 0
	_build_floor()
	_scatter_rocks()
	_scatter_spires()


func _build_floor() -> void:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_SIZE * 2.0, HALF_SIZE * 2.0)
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0.0, FLOOR_Y, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = FLOOR_COLOR
	material.roughness = 0.95
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF_SIZE * 2.0, 1.0, HALF_SIZE * 2.0)
	collision.shape = shape
	collision.position = Vector3(0.0, FLOOR_Y - 0.5, 0.0)
	add_child(collision)


func _scatter_rocks() -> void:
	for i in ROCK_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(20.0, HALF_SIZE * 0.9)
		var pos := Vector2(cos(angle) * r, sin(angle) * r)
		var rock := NatureProps.build_rock(_rng.randf_range(ROCK_MIN_RADIUS, ROCK_MAX_RADIUS), true)
		rock.position = Vector3(pos.x, FLOOR_Y, pos.y)
		rock.rotation.y = _rng.randf_range(0.0, TAU)
		rock.scale.y = _rng.randf_range(0.6, 1.4)
		add_child(rock)


func _scatter_spires() -> void:
	for i in SPIRE_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(60.0, HALF_SIZE * 0.85)
		var pos := Vector2(cos(angle) * r, sin(angle) * r)
		var spire := NatureProps.build_rock_spire(_rng.randf_range(SPIRE_MIN_RADIUS, SPIRE_MAX_RADIUS), _rng.randi_range(3, 5), _rng)
		spire.position = Vector3(pos.x, FLOOR_Y, pos.y)
		add_child(spire)
