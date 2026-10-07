class_name CalderaShell
extends RefCounted

## The Fire guest house envelope: continuous punched stone planes held by a
## bright metal frame, with a genuine superellipse barrel shell and a smoky
## glass crown. Local +Z is the public front.

const BASALT := Color(0.12, 0.105, 0.11)
const VOLCANIC_STONE := Color(0.29, 0.255, 0.25)
const STAINLESS := Color(0.64, 0.67, 0.69)
const STAINLESS_SHADOW := Color(0.36, 0.39, 0.42)
const STEEL := STAINLESS
const STEEL_BLUED := Color(0.16, 0.25, 0.43)
const SMOKY_GLASS := Color(0.26, 0.38, 0.43, 0.42)
const SKYLIGHT_GLASS := Color(0.36, 0.58, 0.68, 0.34)

const WALL := 0.30
const COLUMN := 0.13
const STOREY := 3.50
const DOOR_CLEAR := 2.20
const DOOR_HEIGHT := 2.65
const OPENING_EXPONENT := 4.0
const ROOF_EXPONENT := 3.0
const ROOF_RISE := 1.65
const BARREL_THICKNESS := 0.16
const ROOF_ARC_STEPS := 28


static func build(
	parent: Node3D, entry: Dictionary, datum: float, requested_size: Vector2,
	door_at: float, _stained: Array[Color]
) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "%sShell" % entry["id"]
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var centre := FireCalderaPlan.mass_centre(entry)
	var deep := FireCalderaPlan.facing(entry)
	body.position = Vector3(centre.x, datum, centre.y)
	body.rotation.y = atan2(deep.x, deep.y)
	var size := Vector3(requested_size.x, 0.0, requested_size.y)

	_build_continuous_walls(body, size, door_at)
	_build_visible_structure(body, size)
	_build_barrel_roof(body, size)
	return body


static func _build_continuous_walls(body: StaticBody3D, size: Vector3, door_at: float) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	var rear: Array[Dictionary] = []
	for x in [-5.0, -1.75, 1.625, 4.875]:
		rear.append(_window(x, 1.55, 1.05, 2.72))
	_wall(body, size.x, Vector3(0.0, 0.0, -hz), 0.0, rear)

	var side: Array[Dictionary] = [
		_window(-2.55, 2.45, 0.92, 2.76),
		_window(2.55, 2.45, 0.92, 2.76),
	]
	_wall(body, size.z, Vector3(-hx, 0.0, 0.0), PI * 0.5, side)
	_wall(body, size.z, Vector3(hx, 0.0, 0.0), PI * 0.5, side)

	var front: Array[Dictionary] = [{
		"kind": "door", "center": door_at, "width": DOOR_CLEAR,
		"bottom": 0.0, "top": DOOR_HEIGHT, "leaves": 2,
		"exponent": OPENING_EXPONENT,
	}]
	for opening in [
		_window(-5.65, 1.05, 0.72, 3.12),
		_window(-1.52, 1.65, 0.72, 3.12),
		_window(0.62, 1.65, 0.72, 3.12),
		_window(2.76, 1.65, 0.72, 3.12),
		_window(5.12, 1.45, 0.72, 3.12),
	]:
		front.append(opening)
	_wall(body, size.x, Vector3(0.0, 0.0, hz), 0.0, front)
	ClearZones.add(
		body, "guest house front door", "door", Vector2(door_at, hz), Vector2(0.0, 1.0),
		1.25, 1.25, DOOR_CLEAR * 0.5 + 0.15, 0.05, 1.95
	)


static func _window(centre: float, width: float, bottom: float, top: float) -> Dictionary:
	return {
		"kind": "window", "center": centre, "width": width,
		"bottom": bottom, "top": top, "leaves": 0,
		"exponent": OPENING_EXPONENT,
	}


static func _wall(
	body: StaticBody3D, length: float, origin: Vector3, yaw: float,
	openings: Array[Dictionary]
) -> void:
	TownProps._build_panel_facade(
		body, length, origin, yaw, VOLCANIC_STONE, openings, 0.0, STOREY, WALL
	)
	for opening in openings:
		TownProps._build_panel_opening_trim(
			body, origin, yaw, opening, 0.0, STAINLESS_SHADOW, WALL,
			STEEL_BLUED if opening["kind"] == "door" else STAINLESS_SHADOW
		)


static func _build_visible_structure(body: StaticBody3D, size: Vector3) -> void:
	var hx := size.x * 0.5
	var hz := size.z * 0.5
	for side in [-1.0, 1.0]:
		for z in [-hz, -hz * 0.5, 0.0, hz * 0.5, hz]:
			_metal(body, Vector3(side * hx, STOREY * 0.5, z), Vector3(0.18, STOREY, 0.18), STAINLESS, true)
		_metal(body, Vector3(side * hx, STOREY, 0.0), Vector3(0.20, 0.20, size.z), STAINLESS_SHADOW, true)
	_metal(body, Vector3(0.0, STOREY, hz), Vector3(size.x, 0.20, 0.20), STAINLESS_SHADOW, true)
	_metal(body, Vector3(0.0, STOREY, -hz), Vector3(size.x, 0.20, 0.20), STAINLESS_SHADOW, true)


static func _build_barrel_roof(body: StaticBody3D, size: Vector3) -> void:
	var roof := Node3D.new()
	roof.name = "SuperellipseBarrelRoof"
	body.add_child(roof)
	var skylight_half := 2.0
	_roof_panel(roof, "WestStoneShell", size, -size.x * 0.5, -skylight_half, VOLCANIC_STONE)
	_roof_panel(roof, "EastStoneShell", size, skylight_half, size.x * 0.5, VOLCANIC_STONE)
	_roof_panel(roof, "SmokyGlassSkylight", size, -skylight_half, skylight_half, SKYLIGHT_GLASS)
	_barrel_gable(roof, "FrontGlassGable", size, size.z * 0.5)
	_barrel_gable(roof, "RearGlassGable", size, -size.z * 0.5)

	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(_barrel_outer_faces(size))
	var collision := CollisionShape3D.new()
	collision.name = "BarrelRoofCollision"
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)

	# Five complete stainless ribs visibly carry both stone and glass.
	for i in 5:
		_arch_rib(roof, size, lerpf(-size.z * 0.5, size.z * 0.5, float(i) / 4.0))
	for z in [-size.z * 0.5, size.z * 0.5]:
		for x in [-4.0, -2.0, 0.0, 2.0, 4.0]:
			var crown := _barrel_point(size, x, z, -0.05).y
			_decorative_metal(roof, Vector3(x, (STOREY + crown) * 0.5, z), Vector3(0.10, crown - STOREY, 0.10), STAINLESS_SHADOW)
	for x in [-skylight_half, skylight_half]:
		var p := _barrel_point(size, x, 0.0, 0.035)
		_metal(body, Vector3(x, p.y, 0.0), Vector3(0.14, 0.14, size.z + 0.18), STEEL_BLUED, false)


static func _roof_panel(parent: Node3D, name: String, size: Vector3, x0: float, x1: float, colour: Color) -> void:
	var panel := MeshInstance3D.new()
	panel.name = name
	panel.mesh = _barrel_panel_mesh(size, x0, x1)
	var material := SolidModel.material(colour, 0.72 if colour.a >= 0.99 else 0.18, 0.08)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	panel.material_override = material
	parent.add_child(panel)
	CollisionPolicy.mark_decorative(panel)


static func _barrel_gable(parent: Node3D, name: String, size: Vector3, z: float) -> void:
	var vertices := PackedVector3Array()
	for i in ROOF_ARC_STEPS:
		var xa := lerpf(-size.x * 0.5, size.x * 0.5, float(i) / float(ROOF_ARC_STEPS))
		var xb := lerpf(-size.x * 0.5, size.x * 0.5, float(i + 1) / float(ROOF_ARC_STEPS))
		_quad(vertices, Vector3(xa, STOREY, z), Vector3(xb, STOREY, z), _barrel_point(size, xb, z, -0.08), _barrel_point(size, xa, z, -0.08))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var gable := MeshInstance3D.new()
	gable.name = name
	gable.mesh = array_mesh
	var material := SolidModel.material(SMOKY_GLASS, 0.10, 0.08)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	gable.material_override = material
	parent.add_child(gable)
	CollisionPolicy.mark_decorative(gable)


static func _barrel_panel_mesh(size: Vector3, x0: float, x1: float) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var steps := maxi(2, ceili(absf(x1 - x0) / size.x * float(ROOF_ARC_STEPS)))
	for i in steps:
		var xa := lerpf(x0, x1, float(i) / float(steps))
		var xb := lerpf(x0, x1, float(i + 1) / float(steps))
		_quad(vertices,
			_barrel_point(size, xa, -size.z * 0.5), _barrel_point(size, xb, -size.z * 0.5),
			_barrel_point(size, xb, size.z * 0.5), _barrel_point(size, xa, size.z * 0.5))
		_quad(vertices,
			_barrel_point(size, xa, -size.z * 0.5, -BARREL_THICKNESS), _barrel_point(size, xa, size.z * 0.5, -BARREL_THICKNESS),
			_barrel_point(size, xb, size.z * 0.5, -BARREL_THICKNESS), _barrel_point(size, xb, -size.z * 0.5, -BARREL_THICKNESS))
	for x in [x0, x1]:
		_quad(vertices,
			_barrel_point(size, x, -size.z * 0.5), _barrel_point(size, x, size.z * 0.5),
			_barrel_point(size, x, size.z * 0.5, -BARREL_THICKNESS), _barrel_point(size, x, -size.z * 0.5, -BARREL_THICKNESS))
	for z in [-size.z * 0.5, size.z * 0.5]:
		for i in steps:
			var xa := lerpf(x0, x1, float(i) / float(steps))
			var xb := lerpf(x0, x1, float(i + 1) / float(steps))
			_quad(vertices,
				_barrel_point(size, xa, z), _barrel_point(size, xa, z, -BARREL_THICKNESS),
				_barrel_point(size, xb, z, -BARREL_THICKNESS), _barrel_point(size, xb, z))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _barrel_outer_faces(size: Vector3) -> PackedVector3Array:
	var faces := PackedVector3Array()
	for i in ROOF_ARC_STEPS:
		var xa := lerpf(-size.x * 0.5, size.x * 0.5, float(i) / float(ROOF_ARC_STEPS))
		var xb := lerpf(-size.x * 0.5, size.x * 0.5, float(i + 1) / float(ROOF_ARC_STEPS))
		_quad(faces,
			_barrel_point(size, xa, -size.z * 0.5), _barrel_point(size, xb, -size.z * 0.5),
			_barrel_point(size, xb, size.z * 0.5), _barrel_point(size, xa, size.z * 0.5))
	return faces


static func _barrel_point(size: Vector3, x: float, z: float, inset: float = 0.0) -> Vector3:
	var normalised := clampf(absf(x) / (size.x * 0.5), 0.0, 1.0)
	var crown := pow(maxf(0.0, 1.0 - pow(normalised, ROOF_EXPONENT)), 1.0 / ROOF_EXPONENT)
	return Vector3(x, STOREY + ROOF_RISE * crown + inset, z)


static func _arch_rib(parent: Node3D, size: Vector3, z: float) -> void:
	var previous := _barrel_point(size, -size.x * 0.5, z, 0.035)
	for i in 16:
		var current := _barrel_point(size, lerpf(-size.x * 0.5, size.x * 0.5, float(i + 1) / 16.0), z, 0.035)
		var delta := current - previous
		var beam := SuperEgg.build_part(Vector3(delta.length() * 0.5, 0.08, 0.08), STAINLESS, 3.2, 3.2)
		beam.position = (previous + current) * 0.5
		beam.rotation.z = atan2(delta.y, delta.x)
		parent.add_child(beam)
		CollisionPolicy.mark_decorative(beam)
		previous = current


static func _metal(body: StaticBody3D, at: Vector3, size: Vector3, colour: Color, solid: bool) -> MeshInstance3D:
	var part := SuperEgg.build_part(size * 0.5, colour, 3.25, 3.25)
	part.position = at
	part.material_override = SolidModel.material(colour, 0.24, 0.88)
	body.add_child(part)
	if solid:
		CollisionPolicy.add_box(body, part, size, at, Basis(), false)
	else:
		CollisionPolicy.mark_decorative(part)
	return part


static func _decorative_metal(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> void:
	var part := SuperEgg.build_part(size * 0.5, colour, 3.25, 3.25)
	part.position = at
	part.material_override = SolidModel.material(colour, 0.24, 0.86)
	parent.add_child(part)
	CollisionPolicy.mark_decorative(part)


static func _quad(vertices: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	vertices.append_array(PackedVector3Array([a, b, c, a, c, d]))
