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
	var body := make_body(parent, entry, datum)
	add_volume(body, spec)
	return body


## An empty building body at a plot's mass centre on its datum, +Z its front.
static func make_body(parent: Node3D, entry: Dictionary, datum: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "%sShell" % entry["id"]
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var centre := FireCalderaPlan.mass_centre(entry)
	var deep := FireCalderaPlan.facing(entry)
	body.position = Vector3(centre.x, datum, centre.y)
	body.rotation.y = atan2(deep.x, deep.y)
	return body


## One rectangular volume of the pavilion in an existing body, so a building
## can join several (a tall hall beside a lower wing). Beyond `build`'s spec:
##   offset: Vector2, the volume's centre in the body's plan (default zero);
##   storey: height to the ring beam (default STOREY);
##   clerestory: a band of clear glass above the ring beam to a second beam,
##     for a tall hall's daylight (default none);
##   rake: the roof's rise from the back wall to the front: the walls keep a
##     level ring beam and band, and clear glass fills the wedge between them
##     and the raked roof, rising to a tall clerestory at the front (default
##     none; the roof then keeps the kit's 2-degree pitch);
##   overhang: {"front"|"back"|"west"|"east": float} the roof's reach past
##     each wall (default 0.35; 0 where it meets a taller neighbour);
##   a bay of kind "open" leaves its wall to the building below the ring beam
##     (a shared wall), keeping the posts and any clerestory above.
## Every door bay gets its clear zones; a wall left out of `walls` is not built.
static func add_volume(body: StaticBody3D, spec: Dictionary) -> void:
	var offset: Vector2 = spec.get("offset", Vector2.ZERO)
	var storey := float(spec.get("storey", STOREY))
	var size: Vector2 = spec["size"]
	var hx := size.x * 0.5
	var hz := size.y * 0.5
	var rake := float(spec.get("rake", 0.0))
	var clerestory := float(spec.get("clerestory", 0.0))
	# The wall head's height at a plan point: level, raised by a clerestory,
	# or climbing with a raked roof from back to front.
	var head := func(point: Vector2) -> float:
		if rake > 0.0:
			return storey + rake * clampf((point.y - offset.y + hz) / (2.0 * hz), 0.0, 1.0)
		return storey + clerestory
	var stained: Array = spec["stained"]
	var walls: Dictionary = spec["walls"]
	# Each wall: its start and its direction.
	var runs := {
		"front": [Vector2(-hx, hz), Vector2(1, 0)],
		"back": [Vector2(-hx, -hz), Vector2(1, 0)],
		"west": [Vector2(-hx, -hz), Vector2(0, 1)],
		"east": [Vector2(hx, -hz), Vector2(0, 1)],
	}
	for wall: String in runs:
		if walls.has(wall):
			_build_wall(body, offset, offset + runs[wall][0], runs[wall][1], walls[wall], stained, storey, head)
	_build_corners(body, offset, hx, hz, head)
	_build_roof(body, offset, size, storey + clerestory, rake, spec.get("overhang", {}), spec.get("skylights", []))


static func _build_wall(body: StaticBody3D, centre: Vector2, start: Vector2, along: Vector2, bays: Array, stained: Array, storey: float, head: Callable) -> void:
	var yaw := 0.0 if along.x != 0.0 else PI * 0.5
	var outward := Vector2(-along.y, along.x)
	if outward.dot(start + along - centre) < 0.0:
		outward = -outward
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
				# A stone panel to the transom with the door cut as a superellipse
				# (square foot, rounded head), framed in stainless and hung with
				# leaves cut to the same outline: no glass rests on its frame.
				door_opening(body, Vector3(mid.x, 0.0, mid.y), yaw, width - POST * 0.5, TRANSOM, WALL, DOOR_CLEAR, DOOR_HEIGHT, 2)
				ClearZones.add(body, str(bay.get("label", "front door")), "door", mid, outward, 1.25, 1.25, DOOR_CLEAR * 0.5 + 0.15, 0.05, 1.95)
		if kind != "open":
			# The stained band above every bay, alternating as each bay asks.
			var colour: Color = stained[int(bay.get("band", 0)) % stained.size()]
			_pane(body, "StainedBand", Vector3(mid.x, (TRANSOM + storey) * 0.5, mid.y), Vector2(width * 0.5 - POST * 0.5, (storey - TRANSOM) * 0.5 - 0.05), yaw, Color(colour, 0.72))
		# Clear glass between the ring beam and the wall head, a wedge where the
		# roof is raked.
		var a := start + along * (from + POST * 0.5)
		var b := start + along * (to - POST * 0.5)
		var top_a := float(head.call(a)) - 0.08
		var top_b := float(head.call(b)) - 0.08
		if maxf(top_a, top_b) > storey + 0.1:
			_wedge_pane(body, a, b, storey + 0.04, top_a, top_b, CLEAR_GLASS)
		# The post at the bay's far edge, and its forged fork under the band.
		var edge := start + along * to
		var top := float(head.call(edge))
		_metal(body, Vector3(edge.x, top * 0.5, edge.y), Vector3(POST, top, POST), STEEL_BLUED, true)
		if kind != "open":
			_fork(body, Vector3(edge.x, TRANSOM, edge.y), along)
		from = to
	# The transom bar and ring beam along the whole wall; a tall hall's second
	# beam caps its clerestory.
	var length := from
	var middle := start + along * length * 0.5
	_metal(body, Vector3(middle.x, TRANSOM, middle.y), _oriented(Vector3(length, 0.12, 0.16), yaw), STEEL_BLUED, false)
	_metal(body, Vector3(middle.x, storey - 0.06, middle.y), _oriented(Vector3(length + POST, 0.16, 0.26), yaw), STAINLESS, false)
	var end := start + along * length
	var head_start := float(head.call(start))
	var head_end := float(head.call(end))
	if maxf(head_start, head_end) > storey + 0.1:
		# The wall head's beam, following the roof.
		_beam(body, Vector3(start.x, head_start - 0.06, start.y), Vector3(end.x, head_end - 0.06, end.y), Vector2(0.16, 0.26), STAINLESS)
	# The cove: an LED line on the inner shoulder of the transom bar, hidden
	# behind a stainless lip, washing up through the stained band and across
	# the ceiling. The building's light comes from its structure, not fittings.
	var inward := -outward
	var lip := middle + inward * 0.15
	_metal(body, Vector3(lip.x, TRANSOM + 0.07, lip.y), _oriented(Vector3(length - POST, 0.1, 0.02), yaw), STAINLESS, false)
	var cove := middle + inward * 0.11
	CalderaFurniture.led_line(body, Vector3(cove.x, TRANSOM + 0.065, cove.y), yaw, length - POST, CalderaFurniture.LED_WARM)


## Corner posts, wide enough to cap every wall end.
static func _build_corners(body: StaticBody3D, offset: Vector2, hx: float, hz: float, head: Callable) -> void:
	for x: float in [-hx, hx]:
		for z: float in [-hz, hz]:
			var corner := offset + Vector2(x, z)
			var top := float(head.call(corner))
			_metal(body, Vector3(corner.x, top * 0.5, corner.y), Vector3(POST * 2.0, top, POST * 2.0), STAINLESS, true)


## A straight steel member between two points, `section` (height, depth) its
## cross-section: a raked wall head or any sloping beam.
static func _beam(body: StaticBody3D, from: Vector3, to: Vector3, section: Vector2, colour: Color) -> void:
	var delta := to - from
	var part := SuperEgg.build_part(Vector3(delta.length() * 0.5 + section.y * 0.5, section.x * 0.5, section.y * 0.5), colour, 6.0, 6.0)
	part.material_override = SolidModel.material(colour, 0.20, 0.90)
	var x_axis := delta.normalized()
	var z_axis := x_axis.cross(Vector3.UP).normalized()
	part.transform = Transform3D(Basis(x_axis, z_axis.cross(x_axis), z_axis), (from + to) * 0.5)
	body.add_child(part)
	CollisionPolicy.mark_decorative(part)


## A sheet of glass in a wall's plane from plan point `a` to `b`, its foot at
## `bottom` and its head at `top_a`/`top_b`: a rectangle, or the wedge under a
## raked roof. Above reach, so it carries no collider.
static func _wedge_pane(body: StaticBody3D, a: Vector2, b: Vector2, bottom: float, top_a: float, top_b: float, colour: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector3(a.x, bottom, a.y), Vector3(b.x, bottom, b.y), Vector3(b.x, maxf(top_b, bottom), b.y), Vector3(a.x, maxf(top_a, bottom), a.y)]
	var normal := Vector3(b.x - a.x, 0.0, b.y - a.y).cross(Vector3.UP).normalized()
	for index: int in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.add_vertex(corners[index])
	var pane := MeshInstance3D.new()
	pane.name = "Clerestory"
	pane.mesh = st.commit()
	var material := SolidModel.material(colour, 0.06, 0.05)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pane.material_override = material
	body.add_child(pane)
	CollisionPolicy.mark_decorative(pane)


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


## A stone wall panel `length` wide and `height` tall at `origin` (its middle,
## on the floor), turned by `yaw`, with one superellipse doorway in its middle:
## the punched facade, its piped stainless frame and leaves of the same
## outline. Shared by outside door bays and inner partitions.
static func door_opening(body: StaticBody3D, origin: Vector3, yaw: float, length: float, height: float, thickness: float, clear: float, door_height: float, leaves: int, colour: Color = VOLCANIC_STONE, trim: Color = STAINLESS_SHADOW) -> void:
	var opening: Array[Dictionary] = [{
		"kind": "door", "center": 0.0, "width": clear, "bottom": 0.0, "top": door_height,
		"leaves": leaves, "exponent": TownProps.OPENING_EXPONENT,
	}]
	TownProps._build_panel_facade(body, length, origin, yaw, colour, opening, 0.0, height, thickness)
	TownProps._build_panel_opening_trim(body, origin, yaw, opening[0], 0.0, trim, thickness, STEEL_BLUED.lightened(0.12))


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


static func _build_roof(body: StaticBody3D, offset: Vector2, size: Vector2, top: float, rake: float, overhang: Dictionary, skylights: Array, colour: Color = STAINLESS_SHADOW.darkened(0.16)) -> CSGCombiner3D:
	var reach := func(side: String) -> float: return float(overhang.get(side, 0.35))
	var west: float = reach.call("west")
	var east: float = reach.call("east")
	var front: float = reach.call("front")
	var back: float = reach.call("back")
	var roof := CSGCombiner3D.new()
	roof.name = "LowPitchSkylightRoof"
	# A raked roof rests on its walls' heads, climbing from back to front.
	var pitch := atan2(rake, size.y) if rake > 0.0 else ROOF_PITCH
	var shift_z := (front - back) * 0.5
	var rise_at_centre := rake * 0.5 + tan(pitch) * shift_z if rake > 0.0 else 0.0
	roof.position = Vector3(offset.x + (east - west) * 0.5, top + rise_at_centre + 0.10, offset.y + shift_z)
	roof.rotation.x = -pitch
	roof.use_collision = true
	roof.collision_layer = 1
	roof.collision_mask = 0
	body.add_child(roof)
	var slab_material := SolidModel.material(colour, 0.38, 0.62 if colour.v < 0.5 else 0.05)
	SolidModel.add_box(
		roof, "RoofSlab", Vector3(size.x + west + east, ROOF_DEPTH, (size.y + front + back) / cos(pitch)),
		CSGShape3D.OPERATION_UNION, slab_material
	)
	var shift := Vector2((east - west) * 0.5, (front - back) * 0.5)
	for given: Dictionary in skylights:
		var skylight := given.duplicate()
		skylight["at"] = (given["at"] as Vector2) - shift
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
	return roof


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
