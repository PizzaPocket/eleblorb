class_name CalderaShell
extends RefCounted

## A Fire caldera building's shell from the kit of parts
## (fire_caldera_buildings.md, section 1): an exposed blackened-steel frame on
## a 2 m module, a glazed front of smoky glass between branching mullions (the
## city's signature motif), cast-basalt composite walls on the other sides, a
## stained clerestory band under a shallow walkable roof slab, and one door
## bay of 3 m with a 2 m clear opening and pivoting metal-and-glass leaves.
## It stands on its SocketPlinth, at the plinth's datum.
##
## Frame: the body sits at the plot's centre on the datum, local +Z toward
## the plot's front (its facing), local +X across.

const STEEL := Color(0.12, 0.13, 0.15)
const STEEL_BLUED := Color(0.16, 0.20, 0.28)
const BASALT_COMPOSITE := Color(0.20, 0.19, 0.19)
const SMOKY_GLASS := Color(0.30, 0.32, 0.34, 0.45)
const MODULE := 2.0
const WALL := 0.3
const COLUMN := 0.16
## Above this the clerestory band; the roof sits on the ring beam above it.
const STOREY := 3.5
const CLERESTORY := 0.6
const DOOR_BAY := 3.0
const DOOR_CLEAR := 2.0
const DOOR_HEIGHT := 2.6
const WORLD_DOOR := preload("res://scripts/world_door.gd")


## Builds the shell for a plot: `size` (across, deep) of the occupied mass,
## `door_at` the door bay's centre along the front (metres from the middle),
## `stained` the building's two stained colours.
static func build(parent: Node3D, entry: Dictionary, datum: float, size: Vector2, door_at: float, stained: Array[Color]) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "%sShell" % entry["id"]
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var centre: Vector2 = entry["centre"]
	var deep := FireCalderaPlan.facing(entry)
	body.position = Vector3(centre.x, datum, centre.y)
	body.rotation.y = atan2(deep.x, deep.y)
	var hx := size.x * 0.5
	var hz := size.y * 0.5
	var wall_top := STOREY
	# Columns on the module round the perimeter, a ring beam over them.
	var columns_x := maxi(int(round(size.x / MODULE)), 1)
	var columns_z := maxi(int(round(size.y / MODULE)), 1)
	for i in columns_x + 1:
		var x := -hx + size.x * float(i) / float(columns_x)
		for z: float in [-hz, hz]:
			_solid(body, Vector3(COLUMN, wall_top * 0.5, COLUMN), STEEL, Vector3(x, wall_top * 0.5, z))
	for i in range(1, columns_z):
		var z := -hz + size.y * float(i) / float(columns_z)
		for x: float in [-hx, hx]:
			_solid(body, Vector3(COLUMN, wall_top * 0.5, COLUMN), STEEL, Vector3(x, wall_top * 0.5, z))
	for z: float in [-hz, hz]:
		_solid(body, Vector3(hx + COLUMN, 0.14, COLUMN * 1.2), STEEL_BLUED, Vector3(0, wall_top + 0.14, z))
	for x: float in [-hx, hx]:
		_solid(body, Vector3(COLUMN * 1.2, 0.14, hz), STEEL_BLUED, Vector3(x, wall_top + 0.14, 0))
	# The back and sides: cast-basalt composite up to the clerestory.
	var solid_top := wall_top - CLERESTORY
	_solid(body, Vector3(hx, solid_top * 0.5, WALL * 0.5), BASALT_COMPOSITE, Vector3(0, solid_top * 0.5, -hz + WALL * 0.5))
	for x: float in [-hx + WALL * 0.5, hx - WALL * 0.5]:
		_solid(body, Vector3(WALL * 0.5, solid_top * 0.5, hz - WALL), BASALT_COMPOSITE, Vector3(x, solid_top * 0.5, 0))
	# The front: glass between branching mullions, one bay left as the door.
	var door_left := door_at - DOOR_BAY * 0.5
	var door_right := door_at + DOOR_BAY * 0.5
	var bays := maxi(int(round(size.x / MODULE)), 1)
	for i in bays:
		var x0 := -hx + size.x * float(i) / float(bays)
		var x1 := -hx + size.x * float(i + 1) / float(bays)
		var mid := (x0 + x1) * 0.5
		if mid > door_left and mid < door_right:
			continue
		var a := maxf(x0, door_right) if x0 < door_right and x1 > door_right else x0
		var b := minf(x1, door_left) if x0 < door_left and x1 > door_left else x1
		if b - a < 0.3:
			continue
		_pane(body, Vector3((a + b) * 0.5, solid_top * 0.5, hz), Vector2((b - a) * 0.5 - 0.05, solid_top * 0.5 - 0.05), SMOKY_GLASS)
		_branching_mullion(body, Vector3(b, 0.0, hz), solid_top)
	# The door bay: posts either side, a lintel, the leaves, a transom of
	# stained glass above.
	for x: float in [door_left, door_right]:
		_solid(body, Vector3(COLUMN, solid_top * 0.5, COLUMN), STEEL, Vector3(x, solid_top * 0.5, hz))
	_solid(body, Vector3(DOOR_BAY * 0.5, 0.1, COLUMN), STEEL_BLUED, Vector3(door_at, DOOR_HEIGHT + 0.1, hz))
	_pane(body, Vector3(door_at, (DOOR_HEIGHT + 0.2 + solid_top) * 0.5, hz), Vector2(DOOR_BAY * 0.5 - 0.1, (solid_top - DOOR_HEIGHT - 0.2) * 0.5), Color(stained[0], 0.7))
	var door: Node3D = WORLD_DOOR.new()
	door.position = Vector3(door_at, 0.0, hz)
	body.add_child(door)
	door.configure(DOOR_CLEAR * 0.5, DOOR_HEIGHT, 2, STEEL_BLUED.lightened(0.15))
	# The clerestory: a band of stained glass all round under the ring beam,
	# alternating the building's two colours by bay.
	var band_y := solid_top + CLERESTORY * 0.5
	for i in bays:
		var x := -hx + size.x * (float(i) + 0.5) / float(bays)
		_pane(body, Vector3(x, band_y, hz), Vector2(size.x / float(bays) * 0.5 - 0.05, CLERESTORY * 0.5 - 0.04), Color(stained[i % 2], 0.65))
		_pane(body, Vector3(x, band_y, -hz), Vector2(size.x / float(bays) * 0.5 - 0.05, CLERESTORY * 0.5 - 0.04), Color(stained[(i + 1) % 2], 0.65))
	for i in columns_z:
		var z := -hz + size.y * (float(i) + 0.5) / float(columns_z)
		for x: float in [-hx, hx]:
			_pane(body, Vector3(x, band_y, z), Vector2(size.y / float(columns_z) * 0.5 - 0.05, CLERESTORY * 0.5 - 0.04), Color(stained[i % 2], 0.65), Basis(Vector3.UP, PI * 0.5))
	# The roof: a shallow walkable shell, a true roof slab, falling gently
	# to the back for its ash gutter.
	var fall := deg_to_rad(3.0)
	var roof := TownProps.roof_slab(Vector3(hx + 0.6, TownProps.ROOF_THICKNESS * 0.5, hz + 0.6), STEEL.lightened(0.05))
	roof.name = "Roof"
	var roof_basis := Basis(Vector3.RIGHT, -fall)
	var roof_at := Vector3(0.0, wall_top + 0.28 + TownProps.ROOF_THICKNESS * 0.5, 0.0)
	roof.transform = Transform3D(roof_basis, roof_at)
	body.add_child(roof)
	CollisionPolicy.add_box(body, roof, Vector3((hx + 0.6) * 2.0, TownProps.ROOF_THICKNESS, (hz + 0.6) * 2.0), roof_at, roof_basis, true)
	return body


## The signature: a forged mullion that rises straight and forks twice near
## the head, like a vein of cooled lava.
static func _branching_mullion(body: StaticBody3D, foot: Vector3, height: float) -> void:
	var fork := height * 0.62
	_solid(body, Vector3(0.05, fork * 0.5, 0.06), STEEL, foot + Vector3(0, fork * 0.5, 0))
	for side: float in [-1.0, 1.0]:
		var length := (height - fork) / cos(0.32)
		var branch := SuperEgg.build_part(Vector3(0.04, length * 0.5, 0.05), STEEL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		branch.transform = Transform3D(Basis(Vector3.BACK, side * 0.32), foot + Vector3(-side * sin(0.32) * length * 0.5, fork + (height - fork) * 0.5, 0))
		body.add_child(branch)
		CollisionPolicy.mark_decorative(branch)


static func _solid(body: StaticBody3D, half: Vector3, colour: Color, at: Vector3) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half, colour, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	mesh.position = at
	body.add_child(mesh)
	CollisionPolicy.add_box(body, mesh, half * 2.0, at, Basis(), false)
	return mesh


## A glass pane, thin, solid (it is a wall), translucent.
static func _pane(body: StaticBody3D, at: Vector3, half: Vector2, colour: Color, basis: Basis = Basis()) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(half.x * 2.0, half.y * 2.0, 0.04)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.08
	material.metallic = 0.2
	mesh.material_override = material
	mesh.transform = Transform3D(basis, at)
	body.add_child(mesh)
	CollisionPolicy.add_box(body, mesh, box.size, at, basis, false)
	return mesh
