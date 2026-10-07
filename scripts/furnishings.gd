class_name Furnishings
extends RefCounted

const LOOT_CHEST_SCRIPT := preload("res://scripts/loot_chest.gd")

## Reusable interior pieces, all SuperEgg parts with the epsilon chosen by role
## (squarish for tables, benches, chests and shelves; soft for cushions, sacks and
## bedding; round for pots, barrels and stools), built in a building's own frame
## onto its StaticBody3D. Substantial pieces carry collision; small clutter (mugs,
## crocks, loaves, books) is decorative. See the interior-design skill.

const OAK := Color(0.45, 0.30, 0.17)
const OAK_LIGHT := Color(0.56, 0.40, 0.24)
const OAK_DARK := Color(0.30, 0.19, 0.11)
const IRON := Color(0.22, 0.22, 0.24)
const CLOTH_RED := Color(0.62, 0.22, 0.20)
const CLOTH_GREEN := Color(0.24, 0.42, 0.28)
const CLOTH_BLUE := Color(0.26, 0.38, 0.58)
const CLAY := Color(0.66, 0.42, 0.28)
const PEWTER := Color(0.62, 0.62, 0.64)


static func piece(
	body: StaticBody3D, half: Vector3, color: Color, position: Vector3, yaw: float = 0.0,
	solid: bool = false, epsilon: float = SuperEgg.EPSILON_FLAT
) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half, color, epsilon, SuperEgg.EPSILON_FLAT)
	var basis := Basis(Vector3.UP, yaw)
	mesh.transform = Transform3D(basis, position)
	body.add_child(mesh)
	if solid:
		var collision := CollisionPolicy.add_box(body, mesh, half * 2.0, position, basis, false)
		ClearZones.mark_furniture(collision)
	else:
		CollisionPolicy.mark_decorative(mesh)
		mesh.set_meta(ClearZones.DECOR_META, true)
	return mesh


## A point in a piece's own frame, turned by `yaw` about its origin `at`.
static func _at(origin: Vector3, yaw: float, local: Vector3) -> Vector3:
	return origin + Basis(Vector3.UP, yaw) * local


static func table(
	body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.7, depth: float = 1.0,
	seats: String = "stools", wood: Color = OAK_LIGHT
) -> void:
	var hl := length * 0.5
	var hd := depth * 0.5
	piece(body, Vector3(hl, 0.04, hd), wood, _at(at, yaw, Vector3(0, 0.76, 0)), yaw, true)
	for lx: float in [-1.0, 1.0]:
		for lz: float in [-1.0, 1.0]:
			piece(body, Vector3(0.05, 0.37, 0.05), OAK_DARK, _at(at, yaw, Vector3(lx * (hl - 0.1), 0.37, lz * (hd - 0.1))), yaw, false)
	match seats:
		"stools":
			for sx: float in [-1.0, 1.0]:
				piece(body, Vector3(0.22, 0.23, 0.22), OAK, _at(at, yaw, Vector3(sx * (hl + 0.55), 0.23, 0.0)), yaw, true, 2.4)
		"benches":
			for sz: float in [-1.0, 1.0]:
				bench(body, _at(at, yaw, Vector3(0.0, 0.0, sz * (hd + 0.38))), yaw, length - 0.2)


static func bench(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.5) -> void:
	piece(body, Vector3(length * 0.5, 0.035, 0.19), OAK, _at(at, yaw, Vector3(0, 0.45, 0)), yaw, true)
	for lx: float in [-1.0, 1.0]:
		piece(body, Vector3(0.05, 0.22, 0.16), OAK_DARK, _at(at, yaw, Vector3(lx * (length * 0.5 - 0.12), 0.22, 0)), yaw, false)


static func stool(body: StaticBody3D, at: Vector3, yaw: float = 0.0) -> void:
	piece(body, Vector3(0.23, 0.045, 0.23), OAK, at + Vector3(0, 0.45, 0), yaw, true, 2.5)
	for lx: float in [-1.0, 1.0]:
		for lz: float in [-1.0, 1.0]:
			piece(body, Vector3(0.035, 0.21, 0.035), OAK_DARK, _at(at, yaw, Vector3(lx * 0.15, 0.21, lz * 0.15)), yaw, false)


## A civic lectern with a sloped reading face and a broad, stable foot.
static func lectern(body: StaticBody3D, at: Vector3, yaw: float = 0.0) -> void:
	piece(body, Vector3(0.38, 0.055, 0.27), OAK_DARK, _at(at, yaw, Vector3(0, 0.08, 0)), yaw, true)
	piece(body, Vector3(0.08, 0.58, 0.08), OAK, _at(at, yaw, Vector3(0, 0.64, 0)), yaw, true)
	var pitch := deg_to_rad(-14.0)
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	var top := SuperEgg.build_part(Vector3(0.42, 0.045, 0.31), OAK_LIGHT, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	top.transform = Transform3D(basis, _at(at, yaw, Vector3(0, 1.22, -0.03)))
	body.add_child(top)
	CollisionPolicy.add_box(body, top, Vector3(0.84, 0.09, 0.62), top.position, basis, false)
	piece(body, Vector3(0.25, 0.018, 0.18), Color(0.86, 0.80, 0.66), _at(at, yaw, Vector3(0, 1.29, -0.05)), yaw, false)


## Warm, low-cost civic/interior lighting: one emissive SuperEgg shade and one
## real light per activity group rather than one light per prop.
static func hanging_lamp(body: StaticBody3D, at: Vector3, energy: float = 0.7, radius: float = 5.0) -> void:
	var chain := piece(body, Vector3(0.018, 0.24, 0.018), IRON, at + Vector3(0, 0.24, 0), 0.0, false)
	# A kit that knows its ceilings (StiltKit.reach_hangers) stretches the
	# chain up to whatever the lamp hangs from.
	chain.set_meta("hanger", true)
	var shade := piece(body, Vector3(0.15, 0.11, 0.15), Color(1.0, 0.72, 0.28), at, 0.0, false, 2.2)
	var material := shade.get_surface_override_material(0) as StandardMaterial3D
	if material != null:
		material.emission_enabled = true
		material.emission = Color(1.0, 0.58, 0.2)
		material.emission_energy_multiplier = 1.2
	var light := OmniLight3D.new()
	light.position = at - Vector3(0, 0.08, 0)
	light.light_color = Color(1.0, 0.72, 0.43)
	light.light_energy = energy
	light.omni_range = radius
	light.shadow_enabled = false
	body.add_child(light)


## A high-backed settle: a bench with a tall panel behind it (local +Z is the
## back), standing against a wall or beside a hearth.
static func settle(body: StaticBody3D, at: Vector3, yaw: float, length: float = 1.7, cushion: Color = CLOTH_RED) -> void:
	piece(body, Vector3(length * 0.5, 0.045, 0.27), OAK, _at(at, yaw, Vector3(0, 0.44, 0)), yaw, true)
	piece(body, Vector3(length * 0.5, 0.58, 0.04), OAK_DARK, _at(at, yaw, Vector3(0, 0.95, 0.27)), yaw, true)
	for lx: float in [-1.0, 1.0]:
		piece(body, Vector3(0.05, 0.3, 0.27), OAK_DARK, _at(at, yaw, Vector3(lx * (length * 0.5 - 0.04), 0.78, 0.0)), yaw, false)
		piece(body, Vector3(0.05, 0.22, 0.25), OAK_DARK, _at(at, yaw, Vector3(lx * (length * 0.5 - 0.1), 0.22, 0)), yaw, false)
	piece(body, Vector3(length * 0.5 - 0.1, 0.06, 0.22), cushion, _at(at, yaw, Vector3(0, 0.53, -0.02)), yaw, false, SuperEgg.EPSILON_SOFT)


static func barrel(body: StaticBody3D, at: Vector3, height: float = 0.5) -> void:
	piece(body, Vector3(0.32, height, 0.32), OAK, at + Vector3(0, height, 0), 0.0, true, 2.2)
	for level: float in [0.35, 1.65]:
		piece(body, Vector3(0.335, 0.025, 0.335), IRON, at + Vector3(0, height * level, 0), 0.0, false, 2.2)


static func chest(
	body: StaticBody3D, at: Vector3, yaw: float, wood: Color = OAK_DARK, length: float = 0.9,
	loot_id: String = "", loot: Array[Dictionary] = []
) -> Node3D:
	var chest_node := LOOT_CHEST_SCRIPT.new()
	chest_node.position = at
	chest_node.rotation.y = yaw
	body.add_child(chest_node)
	chest_node.configure(loot_id, loot, wood, length)
	return chest_node


## Wall shelving: `tiers` boards on end panels with crocks and jars along them.
## Local +Z is toward the wall.
static func shelf(body: StaticBody3D, at: Vector3, yaw: float, length: float, tiers: int = 3, stock: String = "crocks") -> void:
	var height := 0.5 + 0.5 * float(tiers)
	for lx: float in [-1.0, 1.0]:
		piece(body, Vector3(0.03, height * 0.5, 0.17), OAK_DARK, _at(at, yaw, Vector3(lx * length * 0.5, height * 0.5, 0)), yaw, false)
	var tones: Array[Color] = [CLAY, PEWTER, Color(0.72, 0.64, 0.48), CLOTH_GREEN.lightened(0.2)]
	for tier in tiers:
		var y := 0.55 + 0.5 * float(tier)
		piece(body, Vector3(length * 0.5, 0.025, 0.16), OAK, _at(at, yaw, Vector3(0, y, 0)), yaw, tier == 0)
		var count := int(length / 0.34)
		for i in count:
			var x := -length * 0.5 + 0.2 + float(i) * (length - 0.4) / maxf(float(count - 1), 1.0)
			match stock:
				"crocks":
					piece(body, Vector3(0.09, 0.1 + 0.03 * float((i + tier) % 3), 0.09), tones[(i + tier) % tones.size()], _at(at, yaw, Vector3(x, y + 0.13, 0)), yaw, false, 2.2)
				"boxes":
					piece(body, Vector3(0.12, 0.09, 0.1), tones[(i + tier) % tones.size()].darkened(0.1), _at(at, yaw, Vector3(x, y + 0.12, 0)), yaw, false)
				"mugs":
					piece(body, Vector3(0.05, 0.06, 0.05), PEWTER, _at(at, yaw, Vector3(x, y + 0.09, 0)), yaw, false, 2.2)


## The long public counter: a plank front, a heavy top, a back shelf of mugs, a
## cask at each end and a keeper's ledger. Local +Z is the keeper's side.
static func counter(body: StaticBody3D, at: Vector3, yaw: float, length: float, lamp: bool = true, casks: bool = false) -> void:
	var hl := length * 0.5
	piece(body, Vector3(hl, 0.5, 0.2), OAK_DARK.lightened(0.04), _at(at, yaw, Vector3(0, 0.5, -0.2)), yaw, true)
	piece(body, Vector3(hl + 0.06, 0.05, 0.36), OAK_LIGHT, _at(at, yaw, Vector3(0, 1.03, 0.0)), yaw, true)
	for i in int(length / 0.55):
		piece(body, Vector3(0.012, 0.44, 0.012), OAK, _at(at, yaw, Vector3(-hl + 0.3 + float(i) * 0.55, 0.5, -0.4)), yaw, false)
	piece(body, Vector3(hl, 0.04, 0.2), OAK, _at(at, yaw, Vector3(0, 0.78, 0.38)), yaw, false)
	for i in int(length / 0.3):
		piece(body, Vector3(0.045, 0.06, 0.045), PEWTER, _at(at, yaw, Vector3(-hl + 0.25 + float(i) * 0.3, 0.88, 0.38)), yaw, false, 2.2)
	piece(body, Vector3(0.2, 0.025, 0.14), CLOTH_RED.darkened(0.3), _at(at, yaw, Vector3(hl * 0.35, 1.1, 0.1)), yaw, false)
	piece(body, Vector3(0.17, 0.02, 0.12), Color(0.86, 0.80, 0.66), _at(at, yaw, Vector3(hl * 0.35, 1.13, 0.1)), yaw, false)
	if casks:
		for sx: float in [-1.0, 1.0]:
			barrel(body, _at(at, yaw, Vector3(sx * (hl + 0.45), 0.0, 0.1)), 0.45)
	if lamp:
		piece(body, Vector3(0.07, 0.1, 0.07), Color(1.0, 0.82, 0.45), _at(at, yaw, Vector3(-hl * 0.5, 1.2, 0.0)), yaw, false, 2.2)


static func desk(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	piece(body, Vector3(0.85, 0.04, 0.42), OAK_LIGHT, _at(at, yaw, Vector3(0, 0.76, 0)), yaw, true)
	for lx: float in [-1.0, 1.0]:
		piece(body, Vector3(0.4, 0.36, 0.38), OAK_DARK, _at(at, yaw, Vector3(lx * 0.44, 0.38, 0)), yaw, true)
	piece(body, Vector3(0.28, 0.03, 0.2), CLOTH_RED.darkened(0.35), _at(at, yaw, Vector3(-0.3, 0.83, 0.0)), yaw, false)
	piece(body, Vector3(0.24, 0.02, 0.17), Color(0.86, 0.80, 0.66), _at(at, yaw, Vector3(-0.3, 0.86, 0.0)), yaw, false)
	piece(body, Vector3(0.06, 0.08, 0.06), Color(1.0, 0.82, 0.45), _at(at, yaw, Vector3(0.45, 0.88, 0.1)), yaw, false, 2.2)
	piece(body, Vector3(0.24, 0.025, 0.24), OAK, _at(at, yaw, Vector3(0, 0.46, -0.85)), yaw, true, 2.6)
	piece(body, Vector3(0.22, 0.2, 0.025), OAK, _at(at, yaw, Vector3(0, 0.7, -1.06)), yaw, false)


static func strongbox(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	piece(body, Vector3(0.3, 0.2, 0.22), IRON.lightened(0.06), _at(at, yaw, Vector3(0, 0.2, 0)), yaw, true)
	piece(body, Vector3(0.32, 0.04, 0.23), IRON, _at(at, yaw, Vector3(0, 0.42, 0)), yaw, false, SuperEgg.EPSILON_SOFT)
	piece(body, Vector3(0.05, 0.06, 0.02), Color(0.8, 0.62, 0.22), _at(at, yaw, Vector3(0, 0.26, -0.23)), yaw, false, 2.4)


## A row of pegs on a rail with coats and hats hung on them. The rail runs along
## local X at height `y`; local -Z is out from the wall.
static func peg_rail(body: StaticBody3D, at: Vector3, yaw: float, length: float, y: float = 1.7) -> void:
	piece(body, Vector3(length * 0.5, 0.04, 0.025), OAK_DARK, _at(at, yaw, Vector3(0, y, 0)), yaw, false)
	var tones: Array[Color] = [CLOTH_BLUE.darkened(0.2), Color(0.5, 0.4, 0.28), CLOTH_GREEN.darkened(0.2), CLOTH_RED.darkened(0.2)]
	var count := maxi(int(length / 0.4), 2)
	for i in count:
		var x := -length * 0.5 + 0.2 + float(i) * (length - 0.4) / float(count - 1)
		piece(body, Vector3(0.015, 0.015, 0.06), OAK_DARK, _at(at, yaw, Vector3(x, y - 0.02, -0.06)), yaw, false)
		if i % 2 == 0:
			piece(body, Vector3(0.1, 0.28 + 0.05 * float(i % 3), 0.04), tones[i % tones.size()], _at(at, yaw, Vector3(x, y - 0.3, -0.07)), yaw, false, SuperEgg.EPSILON_SOFT)
		else:
			piece(body, Vector3(0.1, 0.05, 0.1), tones[(i + 1) % tones.size()].lightened(0.1), _at(at, yaw, Vector3(x, y - 0.1, -0.11)), yaw, false, 2.4)


static func rug(body: StaticBody3D, at: Vector3, yaw: float, size: Vector2, color: Color) -> void:
	piece(body, Vector3(size.x * 0.5, 0.012, size.y * 0.5), color, at + Vector3(0, 0.014, 0), yaw, false, SuperEgg.EPSILON_SOFT)
	piece(body, Vector3(size.x * 0.5 - 0.12, 0.016, size.y * 0.5 - 0.12), color.lightened(0.18), at + Vector3(0, 0.016, 0), yaw, false, SuperEgg.EPSILON_SOFT)


static func washstand(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	piece(body, Vector3(0.4, 0.04, 0.28), OAK_LIGHT, _at(at, yaw, Vector3(0, 0.82, 0)), yaw, true)
	for lx: float in [-1.0, 1.0]:
		piece(body, Vector3(0.04, 0.4, 0.04), OAK_DARK, _at(at, yaw, Vector3(lx * 0.34, 0.4, 0)), yaw, false)
	piece(body, Vector3(0.18, 0.04, 0.18), Color(0.86, 0.86, 0.82), _at(at, yaw, Vector3(-0.1, 0.89, 0)), yaw, false, 2.2)
	piece(body, Vector3(0.07, 0.11, 0.07), Color(0.82, 0.82, 0.78), _at(at, yaw, Vector3(0.18, 0.96, 0.02)), yaw, false, 2.2)


## A hanging pot rack: a rail slung from the beams with pans and a ladle.
static func pot_rack(body: StaticBody3D, at: Vector3, yaw: float, length: float, y: float = 2.3) -> void:
	piece(body, Vector3(length * 0.5, 0.025, 0.025), IRON, _at(at, yaw, Vector3(0, y, 0)), yaw, false)
	for sx: float in [-1.0, 1.0]:
		piece(body, Vector3(0.012, 0.3, 0.012), IRON, _at(at, yaw, Vector3(sx * length * 0.5, y + 0.3, 0)), yaw, false)
	var count := maxi(int(length / 0.35), 2)
	for i in count:
		var x := -length * 0.5 + 0.18 + float(i) * (length - 0.36) / float(count - 1)
		piece(body, Vector3(0.1, 0.035, 0.1), IRON.lightened(0.05 * float(i % 3)), _at(at, yaw, Vector3(x, y - 0.22, 0)), yaw, false, 2.2)
		piece(body, Vector3(0.012, 0.1, 0.012), IRON, _at(at, yaw, Vector3(x, y - 0.1, 0)), yaw, false)


static func sacks(body: StaticBody3D, at: Vector3, count: int) -> void:
	for i in count:
		piece(
			body, Vector3(0.24, 0.17, 0.17), Color(0.80, 0.72, 0.52).darkened(0.05 * float(i % 3)),
			at + Vector3(0.45 * float(i % 3), 0.17 + 0.3 * float(i / 3), 0.04 * float(i % 2)), 0.2 * float(i % 3 - 1), true, 2.6
		)


## A fireside armchair. Local -Z is the front (the way the sitter faces), +Z the
## back. Yaw -PI/2 faces +X, so an armchair at that yaw looks along +X.
static func armchair(body: StaticBody3D, at: Vector3, yaw: float, cushion: Color = CLOTH_RED) -> void:
	piece(body, Vector3(0.3, 0.05, 0.28), OAK, _at(at, yaw, Vector3(0, 0.44, 0)), yaw, true)
	piece(body, Vector3(0.3, 0.32, 0.045), OAK_DARK, _at(at, yaw, Vector3(0, 0.78, 0.26)), yaw, true)
	for lx: float in [-1.0, 1.0]:
		piece(body, Vector3(0.045, 0.14, 0.26), OAK_DARK, _at(at, yaw, Vector3(lx * 0.33, 0.62, 0.0)), yaw, true)
		for lz: float in [-1.0, 1.0]:
			piece(body, Vector3(0.035, 0.22, 0.035), OAK_DARK, _at(at, yaw, Vector3(lx * 0.27, 0.22, lz * 0.22)), yaw, false)
	piece(body, Vector3(0.26, 0.06, 0.24), cushion, _at(at, yaw, Vector3(0, 0.52, -0.01)), yaw, false, SuperEgg.EPSILON_SOFT)
	piece(body, Vector3(0.24, 0.2, 0.04), cushion.darkened(0.1), _at(at, yaw, Vector3(0, 0.76, 0.2)), yaw, false, SuperEgg.EPSILON_SOFT)


## A broom leaning on a wall. Local +Z is toward the wall. Decorative: it is
## thin enough to lean in a corner and is not a thing to walk into.
static func broom(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	var lean := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, deg_to_rad(7.0))
	var handle := SuperEgg.build_part(Vector3(0.014, 0.72, 0.014), OAK_LIGHT, 2.2, SuperEgg.EPSILON_FLAT)
	handle.transform = Transform3D(lean, at + lean * Vector3(0, 0.72, 0))
	body.add_child(handle)
	CollisionPolicy.mark_decorative(handle)
	var head := SuperEgg.build_part(Vector3(0.11, 0.14, 0.05), Color(0.74, 0.62, 0.34), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	head.transform = Transform3D(lean, at + lean * Vector3(0, 0.13, 0))
	body.add_child(head)
	CollisionPolicy.mark_decorative(head)
	var binding := SuperEgg.build_part(Vector3(0.05, 0.02, 0.05), OAK_DARK, 2.2, 2.2)
	binding.transform = Transform3D(lean, at + lean * Vector3(0, 0.3, 0))
	body.add_child(binding)
	CollisionPolicy.mark_decorative(binding)


## A stave tub of split logs for the fire. Solid but small, and allowed inside a
## hearth's clear zone since it belongs to the fire.
static func log_basket(body: StaticBody3D, at: Vector3) -> void:
	piece(body, Vector3(0.3, 0.2, 0.3), OAK, at + Vector3(0, 0.2, 0), 0.0, true, 2.2)
	_allow_at_fire(body)
	piece(body, Vector3(0.315, 0.02, 0.315), IRON, at + Vector3(0, 0.12, 0), 0.0, false, 2.2)
	piece(body, Vector3(0.315, 0.02, 0.315), IRON, at + Vector3(0, 0.34, 0), 0.0, false, 2.2)
	var offsets: Array[Vector2] = [Vector2(-0.12, -0.08), Vector2(0.1, -0.1), Vector2(0.0, 0.1), Vector2(-0.14, 0.12), Vector2(0.14, 0.08)]
	for i in offsets.size():
		piece(body, Vector3(0.06, 0.18 + 0.03 * float(i % 3), 0.06), LOG_COLOR_FURNISH.lightened(0.05 * float(i % 2)), at + Vector3(offsets[i].x, 0.46 + 0.04 * float(i % 3), offsets[i].y), 0.0, false, 2.2)


## Poker, tongs and brush on a small stand beside a hearth.
static func fire_irons(body: StaticBody3D, at: Vector3) -> void:
	piece(body, Vector3(0.13, 0.02, 0.13), IRON, at + Vector3(0, 0.02, 0), 0.0, true, 2.2)
	_allow_at_fire(body)
	piece(body, Vector3(0.012, 0.36, 0.012), IRON, at + Vector3(0, 0.38, 0), 0.0, false, 2.2)
	piece(body, Vector3(0.05, 0.015, 0.05), IRON, at + Vector3(0, 0.74, 0), 0.0, false, 2.2)
	for i in 3:
		var angle := TAU * float(i) / 3.0
		piece(body, Vector3(0.01, 0.3 - 0.02 * float(i), 0.01), IRON.lightened(0.04 * float(i)), at + Vector3(cos(angle) * 0.07, 0.34, sin(angle) * 0.07), 0.0, false, 2.2)


const LOG_COLOR_FURNISH := Color(0.36, 0.23, 0.12)


## Exempts the collision just added to `body` from a hearth's clear zone.
static func _allow_at_fire(body: StaticBody3D) -> void:
	for i in range(body.get_child_count() - 1, -1, -1):
		var child := body.get_child(i)
		if child is CollisionShape3D:
			ClearZones.mark_furniture(child as CollisionShape3D, true)
			return


## Same as shelf(); an alias kept so trade code can read like prose.
static func shelf_at(body: StaticBody3D, at: Vector3, yaw: float, length: float, tiers: int = 3, stock: String = "crocks") -> void:
	shelf(body, at, yaw, length, tiers, stock)


## Sacks stacked along a wall: `count` sacks in rows of three, laid out along the
## wall's own direction (local X) and turned with `yaw`, so they follow any wall.
static func sacks_along(body: StaticBody3D, at: Vector3, yaw: float, count: int) -> void:
	for i in count:
		piece(
			body, Vector3(0.24, 0.17, 0.17), Color(0.80, 0.72, 0.52).darkened(0.05 * float(i % 3)),
			_at(at, yaw, Vector3(0.45 * float(i % 3 - 1), 0.17 + 0.3 * float(i / 3), 0.04 * float(i % 2))),
			yaw + 0.2 * float(i % 3 - 1), true, 2.6
		)
