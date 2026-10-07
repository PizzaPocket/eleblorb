class_name CalderaShell
extends RefCounted

## A Fire caldera glass pavilion (fire_caldera_buildings.md, kit of parts).
##
## Every outside wall is a run of bays between blued-steel posts. A bay is a
## full-height glass panel (floor channel to transom, no sill, no punched
## window), a continuous volcanic-stone panel where a room needs privacy or
## thermal mass, or the door. Above the transom, all round, runs the
## building's two-tone stained clerestory band, and each post meets it with a
## forged fork bracket: the same steel-and-mineral-glass language as the entry
## fin, so the sculpture at the door belongs to the building. A low-pitch metal
## slab, Boolean-punched for fitted glass SuperEgg skylights, sits on the ring
## beam. Local +Z is the public front; the floor is y 0 at the plinth's datum.

const BASALT := Color(0.12, 0.105, 0.11)
const VOLCANIC_STONE := Color(0.31, 0.285, 0.28)
const STAINLESS := Color(0.70, 0.73, 0.75)
const STAINLESS_SHADOW := Color(0.40, 0.43, 0.46)
const STEEL := STAINLESS
const STEEL_BLUED := Color(0.15, 0.24, 0.42)
const CLEAR_GLASS := Color(0.42, 0.68, 0.78, 0.30)
const SMOKY_GLASS := Color(0.29, 0.48, 0.56, 0.34)
const WALL := 0.32
const POST := 0.22
const STOREY := 3.80
## The transom: glass panels and stone run to here, the stained band above.
const TRANSOM := 3.05
const DOOR_CLEAR := 2.30
const DOOR_HEIGHT := 2.75
const ROOF_PITCH := deg_to_rad(2.0)
const ROOF_DEPTH := 0.18


## Builds the pavilion. `spec`:
##   size: Vector2 (across, deep)
##   walls: {"front"|"back"|"west"|"east": [bay, ...]}, each bay
##     {"to": float (the bay's far edge along the wall, from the wall's start),
##      "kind": "glass"|"stone"|"door", "tint": Color (glass, optional),
##      "band": int (0 or 1: which stained colour above it)}
##     Walls run west to east (front, back) and back to front (west, east).
##   stained: [Color, Color]
##   skylights: [{"name", "at": Vector2, "half": Vector2, "rise", "tint"}]
##   door_at: the front door's centre (x)
static func build(parent: Node3D, entry: Dictionary, datum: float, spec: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "%sShell" % entry["id"]
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var centre := FireCalderaPlan.mass_centre(entry)
	var deep := FireCalderaPlan.facing(entry)
	body.position = Vector3(centre.x, datum, centre.y)
	body.rotation.y = atan2(deep.x, deep.y)
	var size: Vector2 = spec["size"]
	var hx := size.x * 0.5
	var hz := size.y * 0.5
	var stained: Array = spec["stained"]
	var walls: Dictionary = spec["walls"]
	# Each wall: its start, its direction, its outward normal.
	var runs := {
		"front": [Vector2(-hx, hz), Vector2(1, 0)],
		"back": [Vector2(-hx, -hz), Vector2(1, 0)],
		"west": [Vector2(-hx, -hz), Vector2(0, 1)],
		"east": [Vector2(hx, -hz), Vector2(0, 1)],
	}
	for wall: String in runs:
		if walls.has(wall):
			_build_wall(body, runs[wall][0], runs[wall][1], walls[wall], stained)
	_build_corners(body, hx, hz)
	_build_roof(body, size, spec.get("skylights", []))
	ClearZones.add(
		body, "front door", "door", Vector2(float(spec["door_at"]), hz), Vector2(0.0, 1.0),
		1.25, 1.25, DOOR_CLEAR * 0.5 + 0.15, 0.05, 1.95
	)
	return body


static func _build_wall(body: StaticBody3D, start: Vector2, along: Vector2, bays: Array, stained: Array) -> void:
	var yaw := 0.0 if along.x != 0.0 else PI * 0.5
	var from := 0.0
	for bay: Dictionary in bays:
		var to := float(bay["to"])
		var width := to - from
		var mid := start + along * (from + width * 0.5)
		var kind := str(bay["kind"])
		match kind:
			"glass":
				_pane(body, "GlassPanel", Vector3(mid.x, TRANSOM * 0.5, mid.y), Vector2(width * 0.5 - POST * 0.5, TRANSOM * 0.5 - 0.06), yaw, bay.get("tint", CLEAR_GLASS))
				# Floor channel: a thin stainless shoe, the panel's only sill.
				_metal(body, Vector3(mid.x, 0.04, mid.y), _oriented(Vector3(width, 0.08, 0.14), yaw), STAINLESS_SHADOW, false)
			"stone":
				_stone(body, Vector3(mid.x, TRANSOM * 0.5, mid.y), _oriented(Vector3(width - POST * 0.5, TRANSOM, WALL), yaw))
			"door":
				# Stone above the door head to the transom: a real lintel, never a
				# sliver of glass resting on the frame.
				var lintel := TRANSOM - DOOR_HEIGHT
				_stone(body, Vector3(mid.x, DOOR_HEIGHT + lintel * 0.5, mid.y), _oriented(Vector3(width - POST * 0.5, lintel, WALL), yaw))
				var door: Node3D = load("res://scripts/world_door.gd").new()
				door.position = Vector3(mid.x, 0.0, mid.y)
				door.rotation.y = yaw
				body.add_child(door)
				door.configure(DOOR_CLEAR * 0.5, DOOR_HEIGHT, 2, STEEL_BLUED.lightened(0.12))
		# The stained band above every bay, alternating as each bay asks.
		var colour: Color = stained[int(bay.get("band", 0)) % stained.size()]
		_pane(body, "StainedBand", Vector3(mid.x, (TRANSOM + STOREY) * 0.5, mid.y), Vector2(width * 0.5 - POST * 0.5, (STOREY - TRANSOM) * 0.5 - 0.05), yaw, Color(colour, 0.72))
		# The post at the bay's far edge, and its forged fork under the band.
		var edge := start + along * to
		_metal(body, Vector3(edge.x, STOREY * 0.5, edge.y), Vector3(POST, STOREY, POST), STEEL_BLUED, true)
		_fork(body, Vector3(edge.x, TRANSOM, edge.y), along)
		from = to
	# The transom bar and ring beam along the whole wall.
	var length := from
	var middle := start + along * length * 0.5
	_metal(body, Vector3(middle.x, TRANSOM, middle.y), _oriented(Vector3(length, 0.12, 0.16), yaw), STEEL_BLUED, false)
	_metal(body, Vector3(middle.x, STOREY - 0.06, middle.y), _oriented(Vector3(length + POST, 0.16, 0.26), yaw), STAINLESS, false)


## Corner posts, wide enough to cap every wall end.
static func _build_corners(body: StaticBody3D, hx: float, hz: float) -> void:
	for x: float in [-hx, hx]:
		for z: float in [-hz, hz]:
			_metal(body, Vector3(x, STOREY * 0.5, z), Vector3(POST * 2.0, STOREY, POST * 2.0), STAINLESS, true)


## A forged fork where a post meets the transom: two short branches leaning
## out along the wall, like a vein of cooled lava splitting, holding the band.
static func _fork(body: StaticBody3D, at: Vector3, along: Vector2) -> void:
	var dir := Vector3(along.x, 0.0, along.y)
	for side: float in [-1.0, 1.0]:
		var tip := at + dir * side * 0.42 + Vector3.UP * 0.02
		var root := at + Vector3.DOWN * 0.48
		var delta := tip - root
		var branch := SuperEgg.build_part(Vector3(0.035, delta.length() * 0.5, 0.045), STEEL_BLUED, 6.0, 6.0)
		branch.material_override = SolidModel.material(STEEL_BLUED, 0.30, 0.85)
		var up := delta.normalized()
		var x_axis := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		branch.transform = Transform3D(Basis(x_axis, up, x_axis.cross(up)), (tip + root) * 0.5)
		body.add_child(branch)
		CollisionPolicy.mark_decorative(branch)


static func _oriented(size: Vector3, yaw: float) -> Vector3:
	return size if is_zero_approx(yaw) else Vector3(size.z, size.y, size.x)


static func _stone(body: StaticBody3D, at: Vector3, size: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "StonePanel"
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = SolidModel.material(VOLCANIC_STONE, 0.88, 0.0)
	mesh.position = at
	body.add_child(mesh)
	CollisionPolicy.add_box(body, mesh, size, at, Basis(), false)


## A full panel of glass: clean rectangle edge to edge of its bay.
static func _pane(body: StaticBody3D, name_text: String, at: Vector3, half: Vector2, yaw: float, colour: Color) -> MeshInstance3D:
	var pane := MeshInstance3D.new()
	pane.name = name_text
	var box := BoxMesh.new()
	box.size = Vector3(half.x * 2.0, half.y * 2.0, 0.05)
	pane.mesh = box
	var material := SolidModel.material(colour, 0.06, 0.05)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.material_override = material
	pane.transform = Transform3D(Basis(Vector3.UP, yaw), at)
	body.add_child(pane)
	CollisionPolicy.add_box(body, pane, box.size, at, Basis(Vector3.UP, yaw), false)
	return pane


static func _build_roof(body: StaticBody3D, size: Vector2, skylights: Array) -> void:
	var roof := CSGCombiner3D.new()
	roof.name = "LowPitchSkylightRoof"
	roof.position = Vector3(0.0, STOREY + 0.10, 0.0)
	roof.rotation.x = -ROOF_PITCH
	roof.use_collision = true
	roof.collision_layer = 1
	roof.collision_mask = 0
	body.add_child(roof)
	var slab_material := SolidModel.material(STAINLESS_SHADOW.darkened(0.16), 0.38, 0.62)
	SolidModel.add_box(
		roof, "RoofSlab", Vector3(size.x + 0.70, ROOF_DEPTH, size.y + 0.70),
		CSGShape3D.OPERATION_UNION, slab_material
	)
	for skylight: Dictionary in skylights:
		var centre: Vector2 = skylight["at"]
		var half: Vector2 = skylight["half"]
		var cutter := SolidModel.add_profile(
			roof, "%sSkylightCut" % skylight["name"], ROOF_DEPTH * 4.0,
			Vector2(half.x * 0.91, half.y * 0.91), 6.5,
			CSGShape3D.OPERATION_SUBTRACTION, slab_material,
			Vector3(centre.x, 0.0, centre.y), 96
		)
		cutter.rotation.z = PI * 0.5
		_skylight_dome(roof, skylight)


static func _skylight_dome(roof: Node3D, skylight: Dictionary) -> void:
	var centre: Vector2 = skylight["at"]
	var half: Vector2 = skylight["half"]
	var rise: float = skylight["rise"]
	var dome := MeshInstance3D.new()
	dome.name = "%sGlassSuperEgg" % skylight["name"]
	dome.mesh = SuperEgg.build_clipped_mesh(
		Vector3(half.x, rise, half.y), [Plane(Vector3.DOWN, 0.0)], 6.5, 6.5, 72, 24
	)
	var material := SolidModel.material(skylight.get("tint", CLEAR_GLASS), 0.06, 0.04)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	dome.material_override = material
	dome.position = Vector3(centre.x, ROOF_DEPTH * 0.5 - 0.01, centre.y)
	roof.add_child(dome)
	CollisionPolicy.mark_decorative(dome)
	# The glass base is a walkable roof surface: one thin collider.
	var glass_body := StaticBody3D.new()
	glass_body.name = "%sSkylightGlass" % skylight["name"]
	glass_body.collision_layer = 1
	glass_body.collision_mask = 0
	glass_body.position = Vector3(centre.x, ROOF_DEPTH * 0.5, centre.y)
	roof.add_child(glass_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(half.x * 1.80, 0.05, half.y * 1.80)
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	glass_body.add_child(collision)


static func _metal(body: StaticBody3D, at: Vector3, size: Vector3, colour: Color, solid: bool) -> MeshInstance3D:
	var part := SuperEgg.build_part(size * 0.5, colour, 6.0, 6.0)
	part.position = at
	part.material_override = SolidModel.material(colour, 0.20, 0.90)
	body.add_child(part)
	if solid:
		CollisionPolicy.add_box(body, part, size, at, Basis(), false)
	else:
		CollisionPolicy.mark_decorative(part)
	return part
