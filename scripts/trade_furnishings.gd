class_name TradeFurnishings
extends RefCounted

## The working furniture of each Ohio trade: what makes a forge a forge and a
## bakehouse a bakehouse. Same conventions as Furnishings (local +Z is the back,
## toward the wall; local -Z is where the user stands; SuperEgg parts only;
## solid pieces carry collision and are tagged as furniture for the clear-zone
## audit, small clutter is decorative).

const IRON := Furnishings.IRON
const OAK := Furnishings.OAK
const OAK_DARK := Furnishings.OAK_DARK
const OAK_LIGHT := Furnishings.OAK_LIGHT
const STRAW := Color(0.78, 0.66, 0.38)
const COAL := Color(0.09, 0.09, 0.1)
const STEEL := Color(0.58, 0.6, 0.64)


static func _p(body: StaticBody3D, half: Vector3, color: Color, at: Vector3, yaw: float, local: Vector3, solid: bool = false, epsilon: float = SuperEgg.EPSILON_FLAT) -> MeshInstance3D:
	return Furnishings.piece(body, half, color, Furnishings._at(at, yaw, local), yaw, solid, epsilon)


## An anvil on its oak stump. Solid, roughly 0.5 m across.
static func anvil(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	_p(body, Vector3(0.22, 0.25, 0.22), OAK, at, yaw, Vector3(0, 0.25, 0), true, 2.2)
	_p(body, Vector3(0.14, 0.05, 0.12), IRON, at, yaw, Vector3(0, 0.53, 0), false)
	_p(body, Vector3(0.4, 0.09, 0.14), IRON.lightened(0.06), at, yaw, Vector3(0, 0.67, 0), false, SuperEgg.EPSILON_SOFT)
	_p(body, Vector3(0.2, 0.05, 0.09), IRON.lightened(0.04), at, yaw, Vector3(0.52, 0.66, 0), false, 2.4)
	_p(body, Vector3(0.38, 0.015, 0.12), STEEL, at, yaw, Vector3(0, 0.765, 0), false)


## A water trough for quenching, on legs, with a still surface.
static func quench_trough(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.0) -> void:
	_p(body, Vector3(length * 0.5, 0.17, 0.22), OAK_DARK, at, yaw, Vector3(0, 0.34, 0), true)
	_p(body, Vector3(length * 0.5 - 0.05, 0.01, 0.17), Color(0.22, 0.3, 0.36), at, yaw, Vector3(0, 0.515, 0), false)
	for lx: float in [-1.0, 1.0]:
		_p(body, Vector3(0.04, 0.09, 0.2), OAK_DARK, at, yaw, Vector3(lx * (length * 0.5 - 0.1), 0.09, 0), false)


## A wooden bin of charcoal against a wall.
static func coal_bin(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	_p(body, Vector3(0.5, 0.3, 0.34), OAK_DARK, at, yaw, Vector3(0, 0.3, 0), true)
	_p(body, Vector3(0.44, 0.1, 0.28), COAL, at, yaw, Vector3(0, 0.62, 0), false, SuperEgg.EPSILON_SOFT)


## Wall-mounted forge bellows: two boards, a leather gusset and an iron nozzle.
static func bellows(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	_p(body, Vector3(0.1, 0.04, 0.34), OAK, at, yaw, Vector3(0, 0.1, -0.04))
	_p(body, Vector3(0.1, 0.04, 0.34), OAK, at, yaw, Vector3(0, -0.1, -0.04))
	_p(body, Vector3(0.09, 0.08, 0.3), Color(0.38, 0.24, 0.14), at, yaw, Vector3(0, 0.0, -0.05), false, SuperEgg.EPSILON_SOFT)
	_p(body, Vector3(0.018, 0.018, 0.2), IRON, at, yaw, Vector3(0, 0.0, -0.46), false, 2.2)


## A foot-treadle grindstone in an oak frame: a stone wheel over a water trough.
## Back to the wall (+Z). Solid, roughly 0.6 m across.
static func grindstone(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	_p(body, Vector3(0.28, 0.34, 0.22), OAK_DARK, at, yaw, Vector3(0, 0.34, 0), true, 6.0)
	_p(body, Vector3(0.05, 0.3, 0.3), Color(0.5, 0.49, 0.47), at, yaw, Vector3(0, 0.72, -0.02), false, 2.2)
	_p(body, Vector3(0.26, 0.022, 0.03), IRON, at, yaw, Vector3(0, 0.72, -0.02), false)
	_p(body, Vector3(0.2, 0.025, 0.05), OAK, at, yaw, Vector3(0.0, 0.1, -0.3), false)
	_p(body, Vector3(0.2, 0.05, 0.12), Color(0.22, 0.3, 0.36), at, yaw, Vector3(0, 0.46, 0.0), false)


## Tools hung on a board: hammers and tongs. Mounted at 1.4 m.
static func tool_rack(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.4) -> void:
	_p(body, Vector3(length * 0.5, 0.18, 0.02), OAK, at, yaw, Vector3(0, 1.45, -0.02))
	var count := maxi(int(length / 0.32), 2)
	for i in count:
		var x := -length * 0.5 + 0.18 + float(i) * (length - 0.36) / float(count - 1)
		if i % 2 == 0:
			_p(body, Vector3(0.012, 0.2, 0.012), OAK_LIGHT, at, yaw, Vector3(x, 1.38, -0.06), false, 2.2)
			_p(body, Vector3(0.05, 0.03, 0.03), IRON, at, yaw, Vector3(x, 1.6, -0.06), false)
		else:
			_p(body, Vector3(0.008, 0.22, 0.008), IRON, at, yaw, Vector3(x - 0.015, 1.36, -0.06), false, 2.2)
			_p(body, Vector3(0.008, 0.22, 0.008), IRON, at, yaw, Vector3(x + 0.015, 1.36, -0.06), false, 2.2)


## A workbench with a vise and a few tools. Back to the wall (+Z).
static func workbench(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.8) -> void:
	_p(body, Vector3(length * 0.5, 0.045, 0.33), OAK_LIGHT.darkened(0.08), at, yaw, Vector3(0, 0.88, 0), true)
	for lx: float in [-1.0, 1.0]:
		for lz: float in [-1.0, 1.0]:
			_p(body, Vector3(0.05, 0.42, 0.05), OAK_DARK, at, yaw, Vector3(lx * (length * 0.5 - 0.1), 0.42, lz * 0.26), false)
	_p(body, Vector3(length * 0.5 - 0.1, 0.02, 0.26), OAK, at, yaw, Vector3(0, 0.3, 0), false)
	_p(body, Vector3(0.07, 0.07, 0.06), IRON, at, yaw, Vector3(-length * 0.5 + 0.2, 0.99, -0.26), false)
	_p(body, Vector3(0.012, 0.04, 0.1), IRON, at, yaw, Vector3(-length * 0.5 + 0.2, 1.03, -0.36), false, 2.2)
	_p(body, Vector3(0.25, 0.012, 0.05), STEEL, at, yaw, Vector3(0.1, 0.94, -0.05), false)


## A rack of finished weapons and a breastplate on a stand: the smith's stock.
static func weapon_rack(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.5) -> void:
	_p(body, Vector3(length * 0.5, 0.04, 0.12), OAK_DARK, at, yaw, Vector3(0, 0.5, 0.05), true)
	_p(body, Vector3(length * 0.5, 0.04, 0.1), OAK_DARK, at, yaw, Vector3(0, 1.3, 0.06), false)
	for i in 3:
		var x := -length * 0.5 + 0.3 + float(i) * (length - 0.6) / 2.0
		_p(body, Vector3(0.025, 0.4, 0.012), STEEL, at, yaw, Vector3(x, 0.9, 0.0), false)
		_p(body, Vector3(0.07, 0.015, 0.012), OAK_DARK, at, yaw, Vector3(x, 0.52, 0.0), false)
		_p(body, Vector3(0.012, 0.07, 0.012), OAK_DARK, at, yaw, Vector3(x, 0.44, 0.0), false, 2.2)
	for lx: float in [-1.0, 1.0]:
		_p(body, Vector3(0.04, 0.65, 0.06), OAK_DARK, at, yaw, Vector3(lx * (length * 0.5 - 0.04), 0.65, 0.06), false)


## A breastplate standing on a wooden form.
static func armor_stand(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	_p(body, Vector3(0.2, 0.03, 0.2), OAK_DARK, at, yaw, Vector3(0, 0.03, 0), true)
	_p(body, Vector3(0.025, 0.6, 0.025), OAK, at, yaw, Vector3(0, 0.65, 0), false, 2.2)
	_p(body, Vector3(0.21, 0.24, 0.12), STEEL.darkened(0.15), at, yaw, Vector3(0, 1.1, 0), true, SuperEgg.EPSILON_SOFT)
	_p(body, Vector3(0.1, 0.04, 0.08), STEEL.darkened(0.1), at, yaw, Vector3(0, 1.38, 0), false, SuperEgg.EPSILON_SOFT)


## A lidded grain or flour bin against a wall.
static func grain_bin(body: StaticBody3D, at: Vector3, yaw: float, dust: Color = Color(0.9, 0.86, 0.74)) -> void:
	_p(body, Vector3(0.52, 0.42, 0.4), OAK, at, yaw, Vector3(0, 0.42, 0), true)
	_p(body, Vector3(0.54, 0.04, 0.42), OAK_LIGHT, at, yaw, Vector3(0, 0.86, 0), false)
	_p(body, Vector3(0.4, 0.015, 0.3), dust, at, yaw, Vector3(0, 0.905, 0), false, SuperEgg.EPSILON_SOFT)


## A stack of seasoned boards on bearers against a wall.
static func timber_rack(body: StaticBody3D, at: Vector3, yaw: float, length: float = 2.0) -> void:
	for lx: float in [-1.0, 0.0, 1.0]:
		_p(body, Vector3(0.05, 0.12, 0.3), OAK_DARK, at, yaw, Vector3(lx * (length * 0.5 - 0.1), 0.12, 0.0), false)
	_p(body, Vector3(length * 0.5, 0.36, 0.3), OAK_LIGHT.darkened(0.04), at, yaw, Vector3(0, 0.5, 0.0), true)
	for i in 4:
		_p(body, Vector3(length * 0.5 + 0.01, 0.005, 0.305), OAK_DARK, at, yaw, Vector3(0, 0.3 + float(i) * 0.1, 0.0), false)


## A baker's wooden cooling rack with loaves, standing against a wall.
static func loaf_rack(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.2) -> void:
	for lx: float in [-1.0, 1.0]:
		_p(body, Vector3(0.03, 0.8, 0.22), OAK_DARK, at, yaw, Vector3(lx * length * 0.5, 0.8, 0.0), true)
	for tier in 4:
		var y := 0.5 + float(tier) * 0.38
		_p(body, Vector3(length * 0.5, 0.012, 0.22), OAK, at, yaw, Vector3(0, y, 0.0), false)
		var loaves := int(length / 0.3)
		for i in loaves:
			var x := -length * 0.5 + 0.2 + float(i) * (length - 0.4) / maxf(float(loaves - 1), 1.0)
			_p(body, Vector3(0.11, 0.065, 0.09), Color(0.72, 0.5, 0.26).darkened(0.05 * float((i + tier) % 3)), at, yaw, Vector3(x, y + 0.08, 0.0), false, SuperEgg.EPSILON_SOFT)


## A long floured kneading table with a dough trough at one end.
static func kneading_table(body: StaticBody3D, at: Vector3, yaw: float, length: float = 2.2) -> void:
	_p(body, Vector3(length * 0.5, 0.045, 0.45), OAK_LIGHT, at, yaw, Vector3(0, 0.84, 0), true)
	for lx: float in [-1.0, 1.0]:
		for lz: float in [-1.0, 1.0]:
			_p(body, Vector3(0.05, 0.4, 0.05), OAK_DARK, at, yaw, Vector3(lx * (length * 0.5 - 0.1), 0.4, lz * 0.36), false)
	_p(body, Vector3(length * 0.5 - 0.1, 0.012, 0.32), Color(0.93, 0.9, 0.82), at, yaw, Vector3(0.1, 0.895, 0), false, SuperEgg.EPSILON_SOFT)
	_p(body, Vector3(0.28, 0.07, 0.2), OAK, at, yaw, Vector3(-length * 0.5 + 0.35, 0.95, 0.0), false, SuperEgg.EPSILON_SOFT)
	_p(body, Vector3(0.22, 0.03, 0.15), Color(0.9, 0.82, 0.62), at, yaw, Vector3(-length * 0.5 + 0.35, 1.0, 0.0), false, SuperEgg.EPSILON_SOFT)


## A long-handled oven peel and rake leaning together by an oven.
static func peel_and_rake(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	var lean := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(8.0))
	var peel := SuperEgg.build_part(Vector3(0.013, 1.0, 0.013), OAK_LIGHT, 2.2, SuperEgg.EPSILON_FLAT)
	peel.transform = Transform3D(lean, at + lean * Vector3(0, 1.0, 0))
	body.add_child(peel)
	CollisionPolicy.mark_decorative(peel)
	var blade := SuperEgg.build_part(Vector3(0.14, 0.012, 0.18), OAK_LIGHT, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	blade.transform = Transform3D(lean, at + lean * Vector3(0, 0.1, -0.1))
	body.add_child(blade)
	CollisionPolicy.mark_decorative(blade)


## A glazed curio cabinet against a wall with labelled boxes and small objects.
static func cabinet(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.2) -> void:
	_p(body, Vector3(length * 0.5, 0.95, 0.24), OAK_DARK, at, yaw, Vector3(0, 0.95, 0.0), true)
	_p(body, Vector3(length * 0.5 - 0.06, 0.8, 0.012), Color(0.5, 0.62, 0.66), at, yaw, Vector3(0, 1.0, -0.245), false)
	var tones: Array[Color] = [Furnishings.CLAY, Furnishings.PEWTER, Color(0.5, 0.34, 0.62), Color(0.72, 0.64, 0.48)]
	for tier in 4:
		for i in int(length / 0.3):
			var x := -length * 0.5 + 0.22 + float(i) * 0.28
			_p(body, Vector3(0.08, 0.07 + 0.02 * float((i + tier) % 3), 0.08), tones[(i + tier) % tones.size()], at, yaw, Vector3(x, 0.45 + float(tier) * 0.4, -0.12), false, 2.4)


## A sloped drawing table for plans and carved-stone studies.
static func drawing_table(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	for lx: float in [-1.0, 1.0]:
		_p(body, Vector3(0.04, 0.4, 0.04), OAK_DARK, at, yaw, Vector3(lx * 0.6, 0.4, 0.2), false)
		_p(body, Vector3(0.04, 0.46, 0.04), OAK_DARK, at, yaw, Vector3(lx * 0.6, 0.46, -0.2), false)
	var tilt := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(-12.0))
	var top := SuperEgg.build_part(Vector3(0.7, 0.025, 0.4), OAK_LIGHT, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	top.transform = Transform3D(tilt, Furnishings._at(at, yaw, Vector3(0, 0.92, 0)))
	body.add_child(top)
	CollisionPolicy.add_box(body, top, Vector3(1.4, 0.05, 0.8), top.position, tilt, false)
	_p(body, Vector3(0.45, 0.008, 0.28), Color(0.9, 0.86, 0.74), at, yaw, Vector3(0, 0.97, -0.03), false)


## A few cut stone samples and a mallet on the floor by a mason's wall.
static func stone_samples(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	_p(body, Vector3(0.28, 0.2, 0.22), Color(0.6, 0.58, 0.54), at, yaw, Vector3(0, 0.2, 0), true, 3.4)
	_p(body, Vector3(0.2, 0.14, 0.2), Color(0.66, 0.62, 0.55), at, yaw, Vector3(0.45, 0.14, 0.05), true, 3.4)
	_p(body, Vector3(0.18, 0.1, 0.16), Color(0.5, 0.5, 0.52), at, yaw, Vector3(-0.42, 0.1, 0.05), false, 3.4)
	_p(body, Vector3(0.012, 0.16, 0.012), OAK_LIGHT, at, yaw, Vector3(0.12, 0.45, -0.04), false, 2.2)
	_p(body, Vector3(0.07, 0.04, 0.04), IRON, at, yaw, Vector3(0.12, 0.62, -0.04), false)


## A drying rail hung from the beams with bundles of herbs. Decorative: it
## hangs above head height.
static func herb_rail(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.8, y: float = 2.45) -> void:
	_p(body, Vector3(length * 0.5, 0.02, 0.02), OAK_DARK, at, yaw, Vector3(0, y, 0))
	var count := maxi(int(length / 0.28), 3)
	for i in count:
		var x := -length * 0.5 + 0.14 + float(i) * (length - 0.28) / float(count - 1)
		_p(body, Vector3(0.006, 0.08, 0.006), OAK_DARK, at, yaw, Vector3(x, y - 0.06, 0))
		_p(body, Vector3(0.06, 0.13, 0.05), Color(0.32 + 0.1 * float(i % 3), 0.46, 0.24), at, yaw, Vector3(x, y - 0.22, 0), false, SuperEgg.EPSILON_SOFT)


## A specimen shelf of jars, pressed-plant frames and a collecting basket.
static func specimen_shelf(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.6) -> void:
	Furnishings.shelf_at(body, at, yaw, length, 3, "crocks")
	for i in 3:
		var x := -length * 0.5 + 0.3 + float(i) * (length - 0.6) / 2.0
		_p(body, Vector3(0.12, 0.15, 0.012), Color(0.82, 0.78, 0.62), at, yaw, Vector3(x, 1.95, -0.03), false)
		_p(body, Vector3(0.09, 0.11, 0.008), Color(0.34, 0.52, 0.26), at, yaw, Vector3(x, 1.95, -0.045), false, SuperEgg.EPSILON_SOFT)


## A kitchen scale with two pans on a counter or table at height `y`.
static func scale(body: StaticBody3D, at: Vector3, yaw: float, y: float = 0.9) -> void:
	_p(body, Vector3(0.05, 0.02, 0.05), IRON, at, yaw, Vector3(0, y + 0.02, 0), false)
	_p(body, Vector3(0.01, 0.17, 0.01), IRON, at, yaw, Vector3(0, y + 0.19, 0), false, 2.2)
	_p(body, Vector3(0.2, 0.008, 0.008), IRON, at, yaw, Vector3(0, y + 0.36, 0), false)
	for sx: float in [-1.0, 1.0]:
		_p(body, Vector3(0.07, 0.01, 0.07), Furnishings.PEWTER, at, yaw, Vector3(sx * 0.2, y + 0.22, 0), false, 2.2)
