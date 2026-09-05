extends StaticBody3D

## First-pass ground for the Fire Kingdom (see kingdom_bootstrap.gd) -- a flat
## scorched basalt floor (same FlatGround-style PlaneMesh+BoxShape3D
## technique every kingdom's placeholder terrain starts from, see that
## script's own class doc comment) plus one large central lava lake, reusing
## NatureProps.build_lava_material() so it reads as the exact same molten
## substance as the outskirts volcano's own lava pool and a fire blorb's own
## body -- not a hand-picked similar color. Scattered rock outcroppings
## around the pool give the floor some texture, mirroring wilderness_scatter.
## gd's own _build_volcano_rocks(), at a much smaller first-pass scale.

const HALF_SIZE := 260.0
const FLOOR_Y := 0.0
const FLOOR_COLOR := Color(0.11, 0.10, 0.10)
const LAVA_RADIUS := 46.0
const LAVA_SURFACE_Y_OFFSET := 0.2
const LAVA_FAN_SEGMENTS := 40
const ROCK_COUNT := 22
const ROCK_MIN_RADIUS := 0.6
const ROCK_MAX_RADIUS := 2.2

var _rng := RandomNumberGenerator.new()


func get_mesh_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func is_lake_area(_world_pos: Vector2) -> bool:
	return false


func is_lava_area(world_pos: Vector2) -> bool:
	return world_pos.length() < LAVA_RADIUS


func get_lava_surface_height(_world_pos: Vector2) -> float:
	return FLOOR_Y + LAVA_SURFACE_Y_OFFSET


func get_lava_escape_position(world_pos: Vector2) -> Vector3:
	var outward := world_pos.normalized()
	if outward.length_squared() < 0.001:
		outward = Vector2.DOWN
	var edge := outward * (LAVA_RADIUS + 1.0)
	return Vector3(edge.x, get_mesh_height(edge.x, edge.y), edge.y)


func get_lake_water_level() -> float:
	return 0.0


func get_mesh_normal(_x: float, _z: float) -> Vector3:
	return Vector3.UP


func _ready() -> void:
	_rng.seed = 20260905
	collision_layer = 1
	collision_mask = 0
	_build_floor()
	_build_lava_lake()
	_scatter_rocks()


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


## Same triangle-fan-disc technique terrain_generator.gd's own
## _build_volcano_lava() uses -- a perfect circle here (no organic edge
## noise needed; this is a self-contained kingdom interior, not a landform
## blending into open wasteland). No collision -- the real floor sits right
## underneath, same reasoning every other lava/water sheet in this project
## gives.
func _build_lava_lake() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := FLOOR_Y + LAVA_SURFACE_Y_OFFSET
	var center := Vector3(0.0, y, 0.0)
	for i in LAVA_FAN_SEGMENTS:
		var angle0 := (float(i) / LAVA_FAN_SEGMENTS) * TAU
		var angle1 := (float(i + 1) / LAVA_FAN_SEGMENTS) * TAU
		var p0 := center + Vector3(cos(angle0) * LAVA_RADIUS, 0.0, sin(angle0) * LAVA_RADIUS)
		var p1 := center + Vector3(cos(angle1) * LAVA_RADIUS, 0.0, sin(angle1) * LAVA_RADIUS)
		st.set_normal(Vector3.UP)
		st.add_vertex(center)
		st.set_normal(Vector3.UP)
		st.add_vertex(p1)
		st.set_normal(Vector3.UP)
		st.add_vertex(p0)

	st.set_material(NatureProps.build_lava_material())
	var lava := MeshInstance3D.new()
	lava.name = "FireKingdomLava"
	lava.mesh = st.commit()
	add_child(lava)

	var glow := OmniLight3D.new()
	glow.name = "FireKingdomLavaGlow"
	glow.position = Vector3(0.0, y + 2.0, 0.0)
	glow.light_color = Color(1.0, 0.5, 0.15)
	glow.light_energy = 3.0
	glow.omni_range = LAVA_RADIUS * 2.2
	add_child(glow)


func _scatter_rocks() -> void:
	for i in ROCK_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(LAVA_RADIUS * 1.15, HALF_SIZE * 0.85)
		var pos := Vector2(cos(angle) * r, sin(angle) * r)
		var rock := NatureProps.build_rock(_rng.randf_range(ROCK_MIN_RADIUS, ROCK_MAX_RADIUS), true)
		rock.position = Vector3(pos.x, FLOOR_Y, pos.y)
		rock.rotation.y = _rng.randf_range(0.0, TAU)
		rock.scale.y = _rng.randf_range(0.6, 1.4)
		add_child(rock)
