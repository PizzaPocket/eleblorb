class_name SnowInteriors
extends RefCounted

## Rooms, partitions and furniture for the Snow Village's log houses, by
## programme. Called by the generator on each shell before it is placed. All
## coordinates are the building's local frame (x along the ridge, z from front
## wall -Z to rear wall +Z), floors at y = 0.04 and 3.29.
##
## Ceilings are flat plank at 3.12 m above each floor (insulation and warm air),
## with the roof space above unoccupied; only the inn's common room is open to
## the rafters. Partitions run floor to ceiling, or to the rafters in the vault.

const FL := 0.04
const CEIL := 3.12
const PLANK := Color(0.55, 0.42, 0.28)
const PLANK_DARK := Color(0.40, 0.30, 0.20)
const WOOL := Color(0.86, 0.82, 0.72)
const STORE_DARK := Color(0.34, 0.26, 0.19)


static func build(body: StaticBody3D, spec: Dictionary) -> void:
	var cells: Vector2 = spec["cells"]
	var ctx := {
		"spec": spec, "w": cells.x * LogHouse.CELL, "d": cells.y * LogHouse.CELL,
		"ix": cells.x * LogHouse.CELL * 0.5 - 0.34, "iz": cells.y * LogHouse.CELL * 0.5 - 0.34,
	}
	match str(spec["kind"]):
		"inn":
			_inn(body, ctx)
		"inn_wing":
			_inn_wing(body, ctx)
		"rescue":
			_rescue(body, ctx)
		"workshop":
			_workshop(body, ctx)
		"textile":
			_textile(body, ctx)
		"bathhouse":
			_bathhouse(body, ctx)
		"warden", "fisher", "forester":
			_cottage(body, ctx)
		"icehouse":
			_icehouse(body, ctx)
		"smokehouse":
			_smokehouse(body, ctx)
		"naust":
			_naust(body, ctx)
		"stabbur":
			_stabbur(body, ctx)


# ---------------------------------------------------------------------------
# Building blocks
# ---------------------------------------------------------------------------

static func _wall(
	body: StaticBody3D, a: Vector2, b: Vector2, doors: Array = [], arches: Array = [],
	base_y: float = FL, top_y: float = CEIL
) -> void:
	var door_list: Array[float] = []
	door_list.assign(doors)
	var arch_list: Array[float] = []
	arch_list.assign(arches)
	TownProps.build_interior_wall(body, a, b, base_y, door_list, PLANK, TownProps.TRIM_WOOD, top_y - base_y, true, arch_list)


static func _slab(body: StaticBody3D, center: Vector3, size: Vector3, color: Color, solid: bool = true) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = SolidModel.material(color, 0.86, 0.0)
	mesh.position = center
	body.add_child(mesh)
	if solid:
		CollisionPolicy.add_box(body, mesh, size, center, Basis(), false)
	else:
		CollisionPolicy.mark_decorative(mesh)


static func _ceiling(body: StaticBody3D, x0: float, x1: float, z0: float, z1: float, base_y: float = FL) -> void:
	_slab(body, Vector3((x0 + x1) * 0.5, base_y + CEIL - FL + 0.06, (z0 + z1) * 0.5), Vector3(x1 - x0, 0.12, z1 - z0), PLANK_DARK)


static func _bed(body: StaticBody3D, x: float, z: float, head: String, blanket: Color, y: float = FL) -> void:
	var bed := TownProps.build_bed(blanket)
	bed.position = Vector3(x, y, z)
	match head:
		"north":
			bed.rotation.y = PI
		"south":
			bed.rotation.y = 0.0
		"east":
			bed.rotation.y = -PI * 0.5
		_:
			bed.rotation.y = PI * 0.5
	body.add_child(bed)


static func _lamp(body: StaticBody3D, x: float, y: float, z: float, energy: float = 0.5, reach: float = 5.0) -> void:
	Furnishings.hanging_lamp(body, Vector3(x, y, z), energy, reach)


static func _piece(
	body: StaticBody3D, half: Vector3, color: Color, at: Vector3, yaw: float = 0.0, solid: bool = false,
	epsilon: float = SuperEgg.EPSILON_FLAT
) -> void:
	Furnishings.piece(body, half, color, at, yaw, solid, epsilon)


## A peg rail on a wall; `out` is the direction the room lies in ("+x", "-x", "+z", "-z").
static func _pegs(body: StaticBody3D, x: float, z: float, out: String, length: float, y: float = 1.7) -> void:
	var yaw := 0.0
	match out:
		"+x":
			yaw = -PI * 0.5
		"-x":
			yaw = PI * 0.5
		"+z":
			yaw = PI
		_:
			yaw = 0.0
	Furnishings.peg_rail(body, Vector3(x, FL, z), yaw, length, y)


static func _drying_rack(body: StaticBody3D, x0: float, x1: float, z: float, y: float = 1.9, hung: int = 7) -> void:
	for sx: float in [x0, x1]:
		_piece(body, Vector3(0.05, y * 0.5 + 0.1, 0.05), PLANK_DARK, Vector3(sx, y * 0.5, z), 0.0, true)
	_piece(body, Vector3((x1 - x0) * 0.5, 0.035, 0.035), PLANK, Vector3((x0 + x1) * 0.5, y, z))
	var tones: Array[Color] = [Furnishings.CLOTH_RED, Furnishings.CLOTH_BLUE, WOOL, Furnishings.CLOTH_GREEN, Color(0.7, 0.5, 0.2)]
	for i in hung:
		var x := lerpf(x0 + 0.3, x1 - 0.3, float(i) / float(maxi(hung - 1, 1)))
		_piece(body, Vector3(0.1, 0.2 + 0.04 * float(i % 3), 0.02), tones[i % tones.size()].darkened(0.1), Vector3(x, y - 0.24, z), 0.0, false, SuperEgg.EPSILON_SOFT)


## A sled lying on its runners: a long flat bed with a curled prow.
static func _sled(
	body: StaticBody3D, at: Vector3, yaw: float,
	color: Color = Color(0.7, 0.28, 0.2), solid: bool = true
) -> void:
	for side: float in [-1.0, 1.0]:
		var runner := _local(at, yaw, Vector3(0.0, 0.07, side * 0.28))
		_piece(body, Vector3(1.0, 0.04, 0.04), PLANK_DARK, runner, yaw, false)
		_piece(body, Vector3(0.1, 0.1, 0.04), PLANK_DARK, _local(at, yaw, Vector3(1.0, 0.16, side * 0.28)), yaw + 0.0, false)
	_piece(body, Vector3(0.95, 0.04, 0.32), color, _local(at, yaw, Vector3(0.0, 0.2, 0.0)), yaw, solid)


static func _local(origin: Vector3, yaw: float, v: Vector3) -> Vector3:
	return origin + Basis(Vector3.UP, yaw) * v


static func _barrel(body: StaticBody3D, x: float, z: float, h: float = 0.5, y: float = FL) -> void:
	Furnishings.barrel(body, Vector3(x, y, z), h)


static func _rope_coil(body: StaticBody3D, at: Vector3) -> void:
	for i in 3:
		_piece(body, Vector3(0.3 - 0.04 * float(i), 0.035, 0.3 - 0.04 * float(i)), Color(0.72, 0.62, 0.42).darkened(0.05 * float(i)), at + Vector3(0, 0.04 + 0.07 * float(i), 0), 0.0, false, 2.4)


static func _loaves(body: StaticBody3D, at: Vector3, count: int) -> void:
	for i in count:
		_piece(
			body, Vector3(0.13, 0.07, 0.08), Color(0.52, 0.34, 0.16).lightened(0.05 * float(i % 3)),
			at + Vector3((float(i % 4) - 1.5) * 0.3, 0.0, float(i / 4) * 0.2), 0.2 * float(i % 3 - 1), false, 2.6
		)


# ---------------------------------------------------------------------------
# The inn: a long hall (vaulted common room, a service block) and its sleeping wing
# ---------------------------------------------------------------------------

static func _inn(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	var spec: Dictionary = ctx["spec"]
	var split := 2.6
	# The service block (mudroom, drying room, kitchen) at the +X end sits under a
	# flat ceiling; the common room beyond it stays open to the rafters.
	_ceiling(body, split, ix, -iz, iz)
	_gable_wall(body, split, -iz, iz, [3.0], [-3.2], spec)
	_wall(body, Vector2(split, -1.8), Vector2(ix, -1.8), [6.0 - split])
	_wall(body, Vector2(split, 1.6), Vector2(ix, 1.6))
	# Tie beams carry the vault and the lamps.
	for beam_x: float in [-5.4, -2.0]:
		_piece(body, Vector3(0.14, 0.14, iz), LogHouse.LOG_COLORS[2], Vector3(beam_x, 3.55, 0.0), 0.0, false, 4.0)
	# Common room.
	Furnishings.settle(body, Vector3(-7.15, FL, 2.7), -PI * 0.5, 1.8, Furnishings.CLOTH_RED)
	Furnishings.settle(body, Vector3(-7.15, FL, -2.7), -PI * 0.5, 1.8, Furnishings.CLOTH_BLUE)
	Furnishings.rug(body, Vector3(-5.2, FL, 0.0), 0.0, Vector2(2.4, 3.2), Furnishings.CLOTH_GREEN.darkened(0.25))
	Furnishings.table(body, Vector3(-3.3, FL, -2.6), 0.0, 2.2, 1.0, "benches")
	Furnishings.table(body, Vector3(-3.3, FL, 2.0), 0.0, 2.2, 1.0, "benches")
	Furnishings.table(body, Vector3(-0.6, FL, -2.6), 0.0, 1.8, 0.9, "stools")
	# Astrid's counter on the rear wall, clear of the wing passage.
	Furnishings.counter(body, Vector3(-1.4, FL, 3.0), 0.0, 2.4)
	Furnishings.shelf(body, Vector3(-1.6, FL, iz - 0.3), 0.0, 2.0, 3, "crocks")
	_lamp(body, -3.3, 2.7, -0.2, 0.9, 7.0)
	_lamp(body, -0.2, 2.7, -0.6, 0.6, 5.0)
	# Mudroom: pegs, a bench, boots.
	_pegs(body, ix - 0.08, -3.3, "-x", 2.0)
	Furnishings.bench(body, Vector3(6.2, FL, -4.0), 0.0, 2.0)
	Furnishings.shelf(body, Vector3(ix - 0.3, FL, -2.55), PI * 0.5, 1.2, 2, "boxes")
	_lamp(body, 5.0, 2.45, -3.0, 0.5, 4.0)
	# Drying room: poles for mittens and scarves, snowboards on the rear partition, a warm stone bench on the kitchen wall.
	_drying_rack(body, 3.3, 7.0, -0.3, 1.9, 8)
	_drying_rack(body, 3.3, 7.0, 0.9, 1.5, 6)
	_piece(body, Vector3(1.8, 0.2, 0.25), Color(0.56, 0.54, 0.5), Vector3(5.2, 0.24, 1.25), 0.0, true, 4.0)
	_lamp(body, 5.2, 2.45, 0.2, 0.45, 4.0)
	# Kitchen: a prep table, hanging pots, the range, loaves cooling for the stall.
	Furnishings.table(body, Vector3(4.6, FL, 2.6), 0.0, 1.5, 0.8, "none")
	Furnishings.pot_rack(body, Vector3(4.8, FL, 3.4), 0.0, 1.6, 2.3)
	Furnishings.shelf(body, Vector3(4.2, FL, 1.95), PI, 1.5, 3, "crocks")
	_loaves(body, Vector3(6.0, 0.92, 3.9), 8)
	_barrel(body, 3.2, 4.0, 0.4)
	_lamp(body, 5.0, 2.4, 2.8, 0.55, 4.5)
	# The wing passage door is on the back wall at x = 1.0; keep it clear.
	body.set_meta("keeper_local", Vector3(-1.4, 0.0, 3.85))


static func _inn_wing(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	_ceiling(body, -ix, ix, -iz, iz)
	# Corridor along the inn side; the dry toilet at its far end; rooms behind.
	_wall(body, Vector2(-ix, -1.4), Vector2(ix, -1.4), [2.26, 5.26, 9.16, 13.26])
	_wall(body, Vector2(-5.9, -iz), Vector2(-5.9, -1.4), [0.71])
	for divider: float in [-4.4, -1.2, 4.0]:
		_wall(body, Vector2(divider, -1.4), Vector2(divider, iz))
	var toilet := TownProps.build_dry_toilet()
	toilet.name = "DryToilet"
	toilet.position = Vector3(-7.3, FL, -2.1)
	toilet.rotation.y = -PI * 0.5
	body.add_child(toilet)
	_lamp(body, -6.8, 2.3, -2.0, 0.35, 2.5)
	# Guest rooms A and B.
	var blankets: Array[Color] = [Color(0.32, 0.46, 0.66), Color(0.62, 0.34, 0.30), Color(0.3, 0.5, 0.4), Color(0.7, 0.55, 0.28)]
	for room in 2:
		var cx: float = [-6.0, -2.8][room]
		_bed(body, cx, iz - 1.22, "north", blankets[room])
		Furnishings.chest(body, Vector3(cx + 0.9, FL, 0.3), 0.0, Furnishings.OAK_DARK, 0.8)
		Furnishings.washstand(body, Vector3(cx - 0.9, FL, 0.2), PI * 0.5)
		Furnishings.rug(body, Vector3(cx, FL, 0.2), 0.0, Vector2(1.4, 1.0), Furnishings.CLOTH_RED.darkened(0.3))
		_lamp(body, cx, 2.4, 0.5, 0.4, 3.5)
	# The party dormitory: three beds along the rear wall and a long table.
	for i in 3:
		_bed(body, -0.2 + 1.62 * float(i), iz - 1.22, "north", blankets[(i + 1) % blankets.size()])
	# Keep the dormitory table behind the door's approach instead of making the
	# first metre of the room an obstacle course.
	Furnishings.table(body, Vector3(1.4, FL, 0.85), 0.0, 1.8, 0.8, "stools")
	Furnishings.chest(body, Vector3(-0.7, FL, 0.2), PI * 0.5, Furnishings.OAK_DARK, 0.9)
	_lamp(body, 1.4, 2.4, 0.5, 0.5, 4.5)
	# Astrid's room beside her stove.
	_bed(body, 5.1, iz - 1.22, "north", Color(0.58, 0.3, 0.28))
	Furnishings.chest(body, Vector3(4.6, FL, 0.2), 0.0, Furnishings.OAK_DARK.lightened(0.05), 0.9)
	Furnishings.rug(body, Vector3(5.4, FL, 0.4), 0.0, Vector2(1.6, 1.2), Furnishings.CLOTH_GREEN.darkened(0.25))
	Furnishings.desk(body, Vector3(6.4, FL, 1.9), -PI * 0.5)
	_lamp(body, 5.2, 2.4, 0.6, 0.5, 4.0)
	# Corridor lamp and a bench by the passage.
	_lamp(body, 2.0, 2.4, -2.1, 0.4, 4.0)
	# Markers for rest, read by the generator.
	body.set_meta("wake_local", Vector3(-6.0, 0.88, iz - 1.22))
	body.set_meta("stand_local", Vector3(-3.0, 0.1, -2.15))


## A partition under the common room's pitched roof: a cross wall that follows
## both slopes up to the rafters, with doors and archways.
static func _gable_wall(
	body: StaticBody3D, x: float, z0: float, z1: float, doors: Array, arches: Array, spec: Dictionary
) -> void:
	var cells: Vector2 = spec["cells"]
	var depth := cells.y * LogHouse.CELL
	var pitch := deg_to_rad(float(spec.get("pitch_deg", 46.0)))
	var rise := tan(pitch)
	var length := z1 - z0
	var middle_z := (z0 + z1) * 0.5
	var peak := float(spec.get("floors", 1)) * LogHouse.STOREY + 0.12 + depth * 0.5 * rise - LogHouse.ROOF_T - 0.08
	var yaw := atan2(-length, 0.0)
	var origin := Vector3(x, FL, middle_z)
	var openings: Array[Dictionary] = []
	for z_door: float in doors:
		openings.append({
			"kind": "door", "center": z_door - middle_z, "width": TownProps.INTERIOR_DOOR_WIDTH,
			"bottom": FL, "top": FL + TownProps.INTERIOR_DOOR_HEIGHT, "leaves": 1, "interior": true,
		})
	for z_arch: float in arches:
		openings.append({
			"kind": "door", "center": z_arch - middle_z, "width": TownProps.ARCHWAY_WIDTH,
			"bottom": FL, "top": FL + TownProps.ARCHWAY_HEIGHT, "leaves": 0, "interior": true,
		})
	var cuts := [
		{"a": peak + middle_z * rise - FL, "b": rise},
		{"a": peak - middle_z * rise - FL, "b": -rise},
	]
	TownProps._build_panel_facade(body, length, origin, yaw, PLANK, openings, FL, peak - FL, TownProps.WALL_THICKNESS, cuts)
	for opening in openings:
		TownProps._build_panel_opening_trim(body, origin, yaw, opening, FL, TownProps.TRIM_WOOD, TownProps.WALL_THICKNESS)


# ---------------------------------------------------------------------------
# Rescue hall
# ---------------------------------------------------------------------------

static func _rescue(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	var upper := LogHouse.STOREY + FL
	# Ground floor: an airlock lobby, the meeting hall, a rescue store.
	_wall(body, Vector2(-1.35, -iz), Vector2(-1.35, -2.7))
	_wall(body, Vector2(1.35, -iz), Vector2(1.35, -2.7))
	_wall(body, Vector2(-1.35, -2.7), Vector2(1.35, -2.7), [1.35])
	_pegs(body, -1.27, -3.6, "+x", 1.4)
	_pegs(body, 1.27, -3.6, "-x", 1.4)
	# Store: sleds, rope, a stretcher, lamps.
	_wall(body, Vector2(-4.0, 1.9), Vector2(0.2, 1.9), [2.2])
	_wall(body, Vector2(0.2, 1.9), Vector2(0.2, iz))
	_wall(body, Vector2(-4.0, 1.9), Vector2(-4.0, iz))
	# These are lashed into the store rack rather than left as collidable sleds
	# across its only doorway.
	_sled(body, Vector3(-2.7, 0.62, 3.75), 0.0, Color(0.7, 0.28, 0.2), false)
	_sled(body, Vector3(-2.7, 1.25, 3.75), 0.0, Color(0.2, 0.42, 0.6), false)
	_rope_coil(body, Vector3(-3.45, FL, 2.55))
	Furnishings.shelf(body, Vector3(-0.2, FL, 3.6), PI * 0.5 * -1.0, 1.8, 3, "boxes")
	_lamp(body, -1.8, 2.3, 3.0, 0.45, 3.5)
	# Meeting hall.
	Furnishings.table(body, Vector3(1.9, FL, 0.25), 0.0, 3.0, 1.1, "benches")
	Furnishings.bench(body, Vector3(1.9, FL, iz - 0.4), 0.0, 3.0)
	Furnishings.settle(body, Vector3(ix - 0.35, FL, -2.4), PI * 0.5, 1.6, Furnishings.CLOTH_BLUE)
	# The weather board: carved marks only, never words.
	_piece(body, Vector3(1.1, 0.7, 0.04), PLANK_DARK, Vector3(3.2, 1.6, iz - 0.08), 0.0, false)
	for i in 4:
		_piece(body, Vector3(0.12, 0.12, 0.02), Color(0.86, 0.8, 0.62), Vector3(2.5 + float(i) * 0.5, 1.7, iz - 0.13), 0.78 * float(i % 2), false)
	_sled(body, Vector3(5.0, FL, -3.9), 0.0, Color(0.7, 0.28, 0.2))
	_lamp(body, 1.6, 2.3, -0.4, 0.8, 6.0)
	_lamp(body, -1.0, 2.3, -3.2, 0.5, 4.0)
	# Upper floor: a landing strip by the ramp head, a map and radio room, Elin's room.
	_ceiling(body, -ix, ix, -iz, iz, upper)
	_wall(body, Vector2(-3.4, -iz), Vector2(-3.4, iz), [iz - 2.3, iz + 2.3], [], upper, upper + CEIL - FL)
	_wall(body, Vector2(-3.4, 0.0), Vector2(ix, 0.0), [], [], upper, upper + CEIL - FL)
	Furnishings.table(body, Vector3(1.4, upper, -2.4), 0.0, 2.6, 1.3, "stools")
	_piece(body, Vector3(1.1, 0.012, 0.55), Color(0.88, 0.84, 0.7), Vector3(1.4, upper + 0.82, -2.4), 0.05, false)
	Furnishings.desk(body, Vector3(5.0, upper, -iz + 0.5), PI)
	_piece(body, Vector3(0.22, 0.14, 0.12), Color(0.22, 0.24, 0.26), Vector3(5.3, upper + 0.97, -iz + 0.5), 0.0, false, 3.0)
	_piece(body, Vector3(0.012, 0.35, 0.012), Color(0.2, 0.2, 0.22), Vector3(5.4, upper + 1.2, -iz + 0.5), 0.0, false)
	_lamp(body, 1.4, upper + 2.3, -2.4, 0.55, 5.0)
	_bed(body, ix - 1.22, 3.0, "east", Color(0.52, 0.3, 0.28), upper)
	Furnishings.chest(body, Vector3(ix - 1.0, upper, 1.0), -PI * 0.5, Furnishings.OAK_DARK, 0.9)
	Furnishings.desk(body, Vector3(0.0, upper, iz - 0.5), 0.0)
	Furnishings.rug(body, Vector3(1.0, upper, 2.4), 0.0, Vector2(1.8, 1.2), Furnishings.CLOTH_GREEN.darkened(0.2))
	_lamp(body, 1.8, upper + 2.3, 2.4, 0.5, 4.5)
	_lamp(body, -4.6, upper + 2.3, 0.0, 0.4, 4.0)


# ---------------------------------------------------------------------------
# Workshop and homes
# ---------------------------------------------------------------------------

static func _workshop(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	_ceiling(body, -ix, ix, -iz, iz)
	# Niko's compact living room at the sheltered rear east corner.
	_wall(body, Vector2(1.5, 0.2), Vector2(1.5, iz))
	_wall(body, Vector2(1.5, 0.2), Vector2(ix, 0.2), [0.7])
	_bed(body, 4.0, iz - 1.22, "north", Color(0.3, 0.46, 0.62))
	# The living-room table belongs at the rear of the room, not in the inner
	# door's landing zone.
	Furnishings.table(body, Vector3(3.8, FL, 2.15), 0.0, 1.0, 0.7, "stools")
	Furnishings.chest(body, Vector3(5.5, FL, 0.8), -PI * 0.5, Furnishings.OAK_DARK, 0.8)
	Furnishings.rug(body, Vector3(3.6, FL, 0.9), 0.0, Vector2(1.6, 1.0), Furnishings.CLOTH_RED.darkened(0.3))
	_lamp(body, 3.4, 2.4, 1.4, 0.5, 4.0)
	# The bay: a workbench, a timber rack, chair frames, the cable drum.
	Furnishings.table(body, Vector3(-3.8, FL, iz - 0.8), 0.0, 3.4, 0.9, "none")
	Furnishings.peg_rail(body, Vector3(-3.8, FL, iz - 0.12), PI, 3.0, 1.75)
	Furnishings.shelf(body, Vector3(-ix + 0.3, FL, 1.2), -PI * 0.5, 2.2, 3, "boxes")
	for i in 3:
		_piece(body, Vector3(0.28, 0.45, 0.02), Color(0.5, 0.2, 0.18), Vector3(-5.3 + 0.7 * float(i), 0.55, -iz + 0.5), 0.1 * float(i), false)
		_piece(body, Vector3(0.28, 0.02, 0.28), Color(0.5, 0.2, 0.18), Vector3(-5.3 + 0.7 * float(i), 0.5, -iz + 0.72), 0.1 * float(i), false)
	_piece(body, Vector3(0.55, 0.12, 0.55), Color(0.2, 0.2, 0.22), Vector3(-1.0, 0.18, 1.6), 0.0, true, 3.2)
	_piece(body, Vector3(0.28, 0.28, 0.28), Color(0.1, 0.1, 0.12), Vector3(-1.0, 0.34, 1.6), 0.0, false, 2.4)
	_lamp(body, -3.0, 2.5, -0.4, 0.8, 7.0)


## Homes with an arctic entry: warden, fisher, forester.
static func _cottage(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	var spec: Dictionary = ctx["spec"]
	var door_x := float(spec.get("door_x", 0.0))
	var hearth: Dictionary = spec.get("hearth", {})
	var hearth_side := float(hearth.get("side", -1.0))
	var kind := str(spec["kind"])
	_ceiling(body, -ix, ix, -iz, iz)
	# Arctic entry: two side walls, a cross wall with the inner door.
	var sleep_x := door_x - hearth_side * 1.05
	var hearth_wall_x := door_x + hearth_side * 1.05
	if kind == "warden":
		sleep_x = 1.7
	_wall(body, Vector2(hearth_wall_x, -iz), Vector2(hearth_wall_x, -0.4))
	if kind == "warden":
		_wall(body, Vector2(door_x - hearth_side * 1.05, -iz), Vector2(door_x - hearth_side * 1.05, -0.4))
	_wall(body, Vector2(minf(hearth_wall_x, door_x - hearth_side * 1.05), -0.4), Vector2(maxf(hearth_wall_x, door_x - hearth_side * 1.05), -0.4), [1.05])
	# Sleeping room behind a full-depth wall with a door.
	var sleep_from := Vector2(sleep_x, -iz)
	var sleep_to := Vector2(sleep_x, iz)
	var door_dist := iz + 1.6
	_wall(body, sleep_from, sleep_to, [door_dist])
	var bed_x := ix - 1.26
	var head := "east"
	if hearth_side > 0.0:
		bed_x = -ix + 1.26
		head = "west"
	var palette: Array[Color] = [Color(0.32, 0.46, 0.66), Color(0.6, 0.32, 0.3), Color(0.3, 0.5, 0.4)]
	_bed(body, bed_x, -1.5, head, palette[0])
	_bed(body, bed_x, 0.2, head, palette[1])
	var inward := -1.0 if bed_x > 0.0 else 1.0
	Furnishings.chest(body, Vector3(sleep_x + inward * -0.8, FL, -2.3), PI * 0.5, Furnishings.OAK_DARK, 0.8)
	_lamp(body, bed_x + inward * 1.6, 2.35, -0.4, 0.4, 3.5)
	# The lobby: pegs for coats and boots, a bench on the sleeping-room side.
	if hearth_side < 0.0:
		_pegs(body, hearth_wall_x + 0.09, -1.6, "+x", 1.3)
	else:
		_pegs(body, hearth_wall_x - 0.09, -1.6, "-x", 1.3)
	# The living room, by trade.
	match kind:
		"warden":
			Furnishings.table(body, Vector3(0.4, FL, -1.6), 0.0, 1.8, 0.9, "benches")
			Furnishings.shelf(body, Vector3(-0.6, FL, iz - 0.3), 0.0, 2.4, 3, "boxes")
			Furnishings.desk(body, Vector3(-4.9, FL, iz - 0.45), 0.0)
			for i in 2:
				_piece(body, Vector3(0.025, 1.0, 0.025), PLANK, Vector3(-3.6 + 0.15 * float(i), 1.0, iz - 0.5), 0.12, false)
			_lamp(body, 0.4, 2.35, -0.6, 0.6, 5.0)
			Furnishings.rug(body, Vector3(0.4, FL, -0.2), 0.0, Vector2(2.2, 1.4), Furnishings.CLOTH_RED.darkened(0.3))
		"fisher":
			Furnishings.table(body, Vector3(-2.4, FL, 1.4), 0.0, 1.7, 0.9, "stools")
			Furnishings.shelf(body, Vector3(-2.6, FL, iz - 0.3), 0.0, 2.2, 3, "crocks")
			for z_net: float in [-2.3]:
				_piece(body, Vector3(0.03, 1.0, 0.03), PLANK_DARK, Vector3(-4.3, 1.0, z_net - 0.6), 0.0, true)
				_piece(body, Vector3(0.03, 1.0, 0.03), PLANK_DARK, Vector3(-4.3, 1.0, z_net + 0.6), 0.0, true)
				_piece(body, Vector3(0.03, 0.03, 0.6), PLANK, Vector3(-4.3, 1.85, z_net))
				for i in 3:
					_piece(body, Vector3(0.015, 0.45, 0.2), Color(0.3, 0.42, 0.34), Vector3(-4.3, 1.35, z_net - 0.4 + 0.4 * float(i)), 0.0, false, SuperEgg.EPSILON_SOFT)
			_lamp(body, -2.4, 2.35, 0.4, 0.5, 4.5)
			Furnishings.rug(body, Vector3(-2.4, FL, 0.2), 0.0, Vector2(1.8, 1.2), Furnishings.CLOTH_BLUE.darkened(0.3))
		_:
			Furnishings.table(body, Vector3(2.4, FL, 1.4), 0.0, 1.7, 0.9, "stools")
			Furnishings.shelf(body, Vector3(2.6, FL, iz - 0.3), 0.0, 2.2, 4, "crocks")
			Furnishings.peg_rail(body, Vector3(2.6, FL, -iz + 0.12), 0.0, 2.2, 1.8)
			# Berries dried for the stall: a frame of slender poles hung with bundles.
			for sx: float in [3.3, 4.1]:
				_piece(body, Vector3(0.03, 0.85, 0.03), PLANK_DARK, Vector3(sx, 0.85, -0.6), 0.0, true)
			_piece(body, Vector3(0.45, 0.025, 0.025), PLANK, Vector3(3.7, 1.65, -0.6))
			for i in 4:
				_piece(body, Vector3(0.05, 0.09, 0.05), Color(0.5, 0.1, 0.2), Vector3(3.45 + 0.17 * float(i), 1.5, -0.6), 0.0, false, 2.4)
			_lamp(body, 2.4, 2.35, 0.2, 0.5, 4.5)
			Furnishings.rug(body, Vector3(2.4, FL, 0.2), 0.0, Vector2(1.8, 1.2), Furnishings.CLOTH_GREEN.darkened(0.3))


static func _textile(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	var upper := LogHouse.STOREY + FL
	var door_x := float(ctx["spec"].get("door_x", 3.2))
	# Ground floor: arctic entry, shop and fitting space, wool store, workroom, stove.
	_wall(body, Vector2(door_x - 1.05, -iz), Vector2(door_x - 1.05, -2.6))
	_wall(body, Vector2(door_x + 1.05, -iz), Vector2(door_x + 1.05, -2.6))
	_wall(body, Vector2(door_x - 1.05, -2.6), Vector2(door_x + 1.05, -2.6), [1.05])
	_pegs(body, door_x - 0.97, -3.7, "+x", 1.3)
	# Mara's cutting and leather table, the fitting stand, Solveig's loom, wool bales.
	Furnishings.table(body, Vector3(-1.4, FL, -1.6), 0.0, 2.2, 1.1, "none")
	_piece(body, Vector3(0.12, 0.6, 0.12), PLANK_DARK, Vector3(-1.4, 0.68, 0.7), 0.0, true, 3.0)
	_piece(body, Vector3(0.28, 0.42, 0.2), WOOL.darkened(0.1), Vector3(-1.4, 1.5, 0.7), 0.0, false, 2.4)
	for sx: float in [-2.6, -1.2]:
		_piece(body, Vector3(0.06, 0.85, 0.06), PLANK_DARK, Vector3(sx, 0.85, 3.3), 0.0, true)
	_piece(body, Vector3(0.78, 0.05, 0.06), PLANK, Vector3(-1.9, 1.62, 3.3))
	for i in 7:
		_piece(body, Vector3(0.006, 0.45, 0.006), WOOL, Vector3(-2.5 + 0.18 * float(i), 1.1, 3.3), 0.0, false)
	for i in 5:
		_piece(body, Vector3(0.28, 0.2, 0.2), WOOL.darkened(0.04 * float(i % 3)), Vector3(0.9 + 0.5 * float(i % 3), 0.2 + 0.36 * float(i / 3), iz - 0.55), 0.1 * float(i % 3), true, 2.6)
	# Finished goods on pegs: the toboggans Solveig sells.
	Furnishings.peg_rail(body, Vector3(4.2, FL, iz - 0.12), PI, 2.4, 1.7)
	for i in 3:
		var hat := TobogganHelm.build_visual(0.8)
		hat.position = Vector3(3.6 + 0.6 * float(i), 1.5, iz - 0.3)
		body.add_child(hat)
		CollisionPolicy.mark_decorative(hat)
	Furnishings.shelf(body, Vector3(ix - 0.3, FL, -2.6), PI * 0.5, 1.8, 3, "boxes")
	Furnishings.table(body, Vector3(1.6, FL, 1.0), 0.0, 1.7, 0.9, "stools")
	Furnishings.rug(body, Vector3(-1.4, FL, -0.2), 0.0, Vector2(2.4, 1.4), Furnishings.CLOTH_BLUE.darkened(0.3))
	_lamp(body, -1.4, 2.4, -0.4, 0.8, 6.0)
	_lamp(body, 2.8, 2.4, 0.8, 0.5, 4.5)
	# Upper floor: hall strip by the ramp head, Solveig's room (front), Mara's (rear).
	_ceiling(body, -ix, ix, -iz, iz, upper)
	_wall(body, Vector2(-3.4, -iz), Vector2(-3.4, iz), [iz - 2.3, iz + 2.3], [], upper, upper + CEIL - FL)
	_wall(body, Vector2(-3.4, 0.0), Vector2(ix, 0.0), [], [], upper, upper + CEIL - FL)
	_bed(body, ix - 1.26, -2.3, "east", Color(0.5, 0.36, 0.55), upper)
	Furnishings.chest(body, Vector3(-2.2, upper, -3.9), 0.0, Furnishings.OAK_DARK, 0.9)
	Furnishings.washstand(body, Vector3(1.2, upper, -3.9), 0.0)
	Furnishings.rug(body, Vector3(1.2, upper, -2.0), 0.0, Vector2(2.0, 1.4), Furnishings.CLOTH_RED.darkened(0.3))
	_piece(body, Vector3(0.28, 0.26, 0.02), Color(0.45, 0.32, 0.2), Vector3(-1.0, upper + 0.5, -2.2), 0.0, false)
	_lamp(body, 1.4, upper + 2.35, -2.0, 0.5, 4.5)
	_bed(body, ix - 1.26, 3.0, "east", Color(0.3, 0.5, 0.52), upper)
	Furnishings.desk(body, Vector3(1.0, upper, iz - 0.45), 0.0)
	Furnishings.chest(body, Vector3(-2.2, upper, 1.0), 0.0, Furnishings.OAK_DARK, 0.9)
	_lamp(body, 1.4, upper + 2.35, 2.2, 0.5, 4.5)
	_lamp(body, -4.7, upper + 2.35, 0.0, 0.4, 4.0)


static func _bathhouse(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	_ceiling(body, -ix, ix, -iz, iz)
	# Changing vestibule (east), washing room (middle), hot room (west).
	_wall(body, Vector2(1.2, -iz), Vector2(1.2, iz), [iz + 0.5])
	_wall(body, Vector2(-1.4, -iz), Vector2(-1.4, iz), [iz + 0.5])
	# Hot room: two tiers of benches along the rear wall, a barrel and ladle.
	_slab(body, Vector3(-2.9, 0.5, iz - 0.4), Vector3(2.6, 0.08, 0.8), PLANK, true)
	_slab(body, Vector3(-2.9, 1.0, iz - 1.15), Vector3(2.6, 0.08, 0.7), PLANK, true)
	for sx: float in [-4.0, -2.9, -1.8]:
		_slab(body, Vector3(sx, 0.25, iz - 0.4), Vector3(0.1, 0.5, 0.7), PLANK_DARK, true)
	_barrel(body, -1.9, -2.2, 0.4)
	_piece(body, Vector3(0.025, 0.2, 0.025), PLANK, Vector3(-1.9, 0.95, -2.2), 0.3, false)
	_lamp(body, -2.9, 2.2, 0.0, 0.35, 3.2)
	# Washing room: a stone floor, a drain, buckets and a wash bench.
	_slab(body, Vector3(-0.1, FL + 0.01, 0.0), Vector3(2.4, 0.02, 5.6), Color(0.52, 0.52, 0.54), false)
	_piece(body, Vector3(0.2, 0.01, 0.2), Color(0.12, 0.12, 0.14), Vector3(-0.1, FL + 0.03, 0.2), 0.0, false, 2.2)
	Furnishings.bench(body, Vector3(-0.1, FL, iz - 0.4), 0.0, 2.0)
	for sx: float in [-0.8, 0.7]:
		_piece(body, Vector3(0.18, 0.15, 0.18), PLANK, Vector3(sx, 0.18, -1.9), 0.0, false, 2.4)
	_lamp(body, -0.1, 2.3, 0.0, 0.4, 3.0)
	# Vestibule: a bench, towels and coats on pegs.
	Furnishings.bench(body, Vector3(3.2, FL, iz - 0.35), 0.0, 2.2)
	_pegs(body, 1.29, 0.0, "+x", 1.6)
	_lamp(body, 3.2, 2.4, 0.2, 0.4, 3.5)


# ---------------------------------------------------------------------------
# Outbuildings
# ---------------------------------------------------------------------------

static func _icehouse(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	# Cut blocks of clear lake ice banked in sawdust, crates of food and medicine.
	_slab(body, Vector3(0.0, FL + 0.01, 0.0), Vector3(ix * 2.0 - 0.2, 0.02, iz * 2.0 - 0.2), Color(0.66, 0.56, 0.4), false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3131
	for row in 3:
		for column in 4:
			for level in 2 + (column + row) % 2:
				_piece(
					body, Vector3(0.36, 0.22, 0.36), Color(0.74, 0.88, 0.96).darkened(0.03 * float(level)),
					Vector3(-ix + 0.7 + float(column) * 0.78, FL + 0.22 + float(level) * 0.44, iz - 0.7 - float(row) * 0.78),
					rng.randf_range(-0.05, 0.05), true, 4.0
				)
	Furnishings.shelf(body, Vector3(ix - 0.3, FL, -1.0), PI * 0.5, 2.2, 3, "boxes")
	Furnishings.chest(body, Vector3(ix - 0.8, FL, -2.4), PI * 0.5, Furnishings.OAK_DARK, 0.9)


static func _smokehouse(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	# Fish on racks above a low fire: poles at two heights, silver and brown fish.
	for level: float in [1.7, 2.3]:
		for sx: float in [-ix + 0.4, ix - 0.4]:
			_piece(body, Vector3(0.04, level * 0.5, 0.04), PLANK_DARK, Vector3(sx, level * 0.5, -iz + 0.5), 0.0, true)
			_piece(body, Vector3(0.04, level * 0.5, 0.04), PLANK_DARK, Vector3(sx, level * 0.5, iz - 0.5), 0.0, true)
		_piece(body, Vector3(ix - 0.4, 0.03, 0.03), PLANK, Vector3(0.0, level, -iz + 0.5))
		_piece(body, Vector3(ix - 0.4, 0.03, 0.03), PLANK, Vector3(0.0, level, iz - 0.5))
		for i in 8:
			for z_pole: float in [-iz + 0.5, iz - 0.5]:
				_piece(body, Vector3(0.05, 0.2, 0.025), Color(0.5, 0.4, 0.28) if i % 2 == 0 else Color(0.62, 0.62, 0.6), Vector3(-ix + 0.7 + 0.36 * float(i), level - 0.24, z_pole), 0.0, false, 2.4)
	_piece(body, Vector3(0.7, 0.1, 0.7), Color(0.4, 0.38, 0.36), Vector3(0.0, 0.1, 0.0), 0.0, true, 3.0)
	var embers := ParticleFX.build_flame_particles(7, 0.35, 0.5, 1.0, 1.6, -0.4)
	embers.position = Vector3(0.0, 0.22, 0.0)
	body.add_child(embers)
	CollisionPolicy.mark_decorative(embers)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 0.6, 0.0)
	glow.light_color = Color(1.0, 0.4, 0.15)
	glow.light_energy = 0.6
	glow.omni_range = 4.0
	glow.shadow_enabled = false
	body.add_child(glow)


static func _naust(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	# A small boat on skids, oars, nets, floats and barrels: the net shed and boat house.
	_piece(body, Vector3(1.9, 0.38, 0.75), Color(0.46, 0.34, 0.24), Vector3(-0.8, 0.52, 0.5), 0.0, true, 2.4)
	for side: float in [-1.0, 1.0]:
		_piece(body, Vector3(2.0, 0.05, 0.05), PLANK_DARK, Vector3(-0.8, 0.1, 0.5 + side * 0.45), 0.0, false)
	_piece(body, Vector3(0.05, 0.05, 0.6), PLANK_DARK, Vector3(-0.8, 0.9, 0.5))
	for i in 3:
		_piece(body, Vector3(0.025, 0.025, 1.0), Color(0.6, 0.48, 0.3), Vector3(ix - 0.25, 1.1 + 0.15 * float(i), -0.6 + 0.4 * float(i)), PI * 0.5, false)
	for i in 4:
		_piece(body, Vector3(0.45, 0.04, 0.22), Color(0.3, 0.42, 0.34).darkened(0.05 * float(i)), Vector3(-ix + 0.5, 1.9 - 0.3 * float(i), iz - 0.4), 0.0, false, SuperEgg.EPSILON_SOFT)
	for i in 6:
		_piece(body, Vector3(0.09, 0.09, 0.09), Color(0.92, 0.5, 0.15), Vector3(ix - 0.8 + 0.2 * float(i % 3), 0.12 + 0.15 * float(i / 3), iz - 0.6), 0.0, false, 2.2)
	_barrel(body, ix - 0.7, iz - 1.7, 0.45)
	_rope_coil(body, Vector3(-ix + 1.0, FL, 1.9))
	_lamp(body, 0.0, 2.45, 0.0, 0.5, 5.0)


static func _stabbur(body: StaticBody3D, ctx: Dictionary) -> void:
	var ix: float = ctx["ix"]
	var iz: float = ctx["iz"]
	# The village's winter provisions: crocks, sacks, smoked fish, a cheese rack.
	Furnishings.shelf(body, Vector3(-ix + 0.3, FL, 0.0), -PI * 0.5, 2.6, 4, "crocks")
	Furnishings.shelf(body, Vector3(ix - 0.3, FL, 0.0), PI * 0.5, 2.6, 4, "boxes")
	Furnishings.sacks(body, Vector3(-1.0, FL, iz - 0.6), 6)
	_barrel(body, 1.0, iz - 0.7, 0.45)
	_barrel(body, 1.8, iz - 0.7, 0.45)
	_piece(body, Vector3(0.9, 0.03, 0.03), PLANK, Vector3(0.0, 2.2, 0.0))
	for i in 6:
		_piece(body, Vector3(0.05, 0.2, 0.025), Color(0.5, 0.4, 0.28), Vector3(-0.7 + 0.28 * float(i), 1.98, 0.0), 0.0, false, 2.4)
