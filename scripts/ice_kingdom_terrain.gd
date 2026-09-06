extends StaticBody3D

## First-pass ground for the Ice Kingdom (see kingdom_bootstrap.gd) -- one
## flat floor with two concentric zones, per direct instruction ("a snowy
## Arctic forest that leads to an ice spikes biome... they're the same
## plateau, one big kingdom of two elements"): a pale snowy-forest zone near
## the arrival point (SNOW_RADIUS), opening into an icy-blue ice-spikes zone
## beyond it out to the kingdom's own edge. Same flat FlatGround-style
## PlaneMesh+BoxShape3D technique every kingdom's placeholder terrain starts
## from (see fire_kingdom_terrain.gd's own identical class doc comment), with
## the snow zone laid on top as its own disc -- the same triangle-fan-disc
## technique fire_kingdom_terrain.gd's own _build_lava_lake() uses for a
## flat zone patch, just for a cosmetic color zone here rather than a hazard.

const HALF_SIZE := 260.0
const FLOOR_Y := 0.0
const ICE_ZONE_COLOR := Color(0.66, 0.8, 0.9)
const SNOW_RADIUS := 100.0
const SNOW_ZONE_COLOR := Color(0.92, 0.94, 0.96)
const SNOW_ZONE_Y_OFFSET := 0.05
const SNOW_ZONE_SEGMENTS := 40

const PINE_COUNT := 16
const PINE_MIN_HEIGHT := 6.0
const PINE_MAX_HEIGHT := 11.0
const SPIRE_COUNT := 10
const SPIRE_MIN_RADIUS := 1.4
const SPIRE_MAX_RADIUS := 2.4
const ICE_LEAF_COLOR := Color(0.85, 0.92, 0.96)
const ICE_ROCK_COLOR := Color(0.75, 0.86, 0.94)

var _rng := RandomNumberGenerator.new()


func get_mesh_height(_x: float, _z: float) -> float:
	return FLOOR_Y


func is_lake_area(_world_pos: Vector2) -> bool:
	return false


func get_lake_water_level() -> float:
	return 0.0


func get_mesh_normal(_x: float, _z: float) -> Vector3:
	return Vector3.UP


## True within the snowy-forest zone near the arrival point, false out in
## the ice-spikes zone -- public so ice_kingdom_blorbs.gd can place wild Ice
## blorbs nearer the forest and Snow blorbs across both zones without
## duplicating this radius check.
func is_snow_zone(world_pos: Vector2) -> bool:
	return world_pos.length() < SNOW_RADIUS


## Exposed as a function, not read directly off this dynamically-typed
## script's own const, matching how every other cross-script terrain query
## in this project (get_mesh_height(), is_lake_area(), etc.) goes through a
## function call rather than duck-typed const/property access.
func get_snow_radius() -> float:
	return SNOW_RADIUS


func _ready() -> void:
	_rng.seed = 20260908
	collision_layer = 1
	collision_mask = 0
	_build_floor()
	_build_snow_zone_patch()
	_scatter_pines()
	_scatter_ice_spires()
	# Set once per visit (this scene rebuilds from scratch every time the
	# player walks through the gate) -- gates the Wood Kingdom reveal back
	# in the Plant Kingdom (see jungle_kingdom_village.gd's own
	# _build_wood_kingdom_area()).
	WorldState.ice_kingdom_visited = true


func _build_floor() -> void:
	var mesh_instance := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(HALF_SIZE * 2.0, HALF_SIZE * 2.0)
	mesh_instance.mesh = plane
	mesh_instance.position = Vector3(0.0, FLOOR_Y, 0.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = ICE_ZONE_COLOR
	material.roughness = 0.15
	material.metallic = 0.1
	mesh_instance.set_surface_override_material(0, material)
	add_child(mesh_instance)

	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(HALF_SIZE * 2.0, 1.0, HALF_SIZE * 2.0)
	collision.shape = shape
	collision.position = Vector3(0.0, FLOOR_Y - 0.5, 0.0)
	add_child(collision)


## Same triangle-fan-disc technique fire_kingdom_terrain.gd's own
## _build_lava_lake() uses -- a flat cosmetic patch laid slightly above the
## main floor so it never z-fights with it.
func _build_snow_zone_patch() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y := FLOOR_Y + SNOW_ZONE_Y_OFFSET
	var center := Vector3(0.0, y, 0.0)
	for i in SNOW_ZONE_SEGMENTS:
		var angle0 := (float(i) / SNOW_ZONE_SEGMENTS) * TAU
		var angle1 := (float(i + 1) / SNOW_ZONE_SEGMENTS) * TAU
		var p0 := center + Vector3(cos(angle0) * SNOW_RADIUS, 0.0, sin(angle0) * SNOW_RADIUS)
		var p1 := center + Vector3(cos(angle1) * SNOW_RADIUS, 0.0, sin(angle1) * SNOW_RADIUS)
		st.set_normal(Vector3.UP)
		st.add_vertex(center)
		st.set_normal(Vector3.UP)
		st.add_vertex(p1)
		st.set_normal(Vector3.UP)
		st.add_vertex(p0)
	var material := StandardMaterial3D.new()
	material.albedo_color = SNOW_ZONE_COLOR
	material.roughness = 0.9
	st.set_material(material)
	var patch := MeshInstance3D.new()
	patch.name = "SnowZonePatch"
	patch.mesh = st.commit()
	add_child(patch)


func _scatter_pines() -> void:
	for i in PINE_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(14.0, SNOW_RADIUS * 0.92)
		var pos := Vector2(cos(angle) * r, sin(angle) * r)
		var pine := NatureProps.build_pine_tree(_rng.randf_range(PINE_MIN_HEIGHT, PINE_MAX_HEIGHT), ICE_LEAF_COLOR)
		pine.position = Vector3(pos.x, FLOOR_Y, pos.y)
		pine.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(pine)


func _scatter_ice_spires() -> void:
	var frost_material := StandardMaterial3D.new()
	frost_material.albedo_color = ICE_ROCK_COLOR
	frost_material.roughness = 0.1
	frost_material.metallic = 0.15
	for i in SPIRE_COUNT:
		var angle := _rng.randf_range(0.0, TAU)
		var r := _rng.randf_range(SNOW_RADIUS * 1.1, HALF_SIZE * 0.88)
		var pos := Vector2(cos(angle) * r, sin(angle) * r)
		var spire := NatureProps.build_rock_spire(_rng.randf_range(SPIRE_MIN_RADIUS, SPIRE_MAX_RADIUS), _rng.randi_range(3, 6), _rng)
		spire.position = Vector3(pos.x, FLOOR_Y, pos.y)
		# build_rock_spire()'s own direct children are each tier's build_rock()
		# wrapper Node3D (plus separate CollisionShape3D siblings), not
		# MeshInstance3D directly -- the actual mesh instances are one level
		# deeper, inside each tier's own wrapper. Recurse to reach them.
		_tint_meshes_recursive(spire, frost_material)
		add_child(spire)


func _tint_meshes_recursive(node: Node, material: StandardMaterial3D) -> void:
	if node is MeshInstance3D:
		(node as MeshInstance3D).set_surface_override_material(0, material)
	for child in node.get_children():
		_tint_meshes_recursive(child, material)
