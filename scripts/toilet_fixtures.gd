class_name ToiletFixtures
extends RefCounted

## One toilet fixture per culture, so a rest point's washroom is true to the
## people who built it (settlement_backlog.md, item 11, and the architecture
## skill's rule that every resting place has a toilet). Every fixture follows
## the porcelain pedestal's contract: local +Z is the back against the wall,
## local -Z is the approach, and the body is a StaticBody3D with box collision.
##
## Kinds: porcelain (the Holt Inn's, kept as is), earth_closet (Pueblo adobe
## privy), matong (a lidded wooden commode), composting_seat (jungle rattan and
## clay vat), vacuum (sea folk), incinerating (lava people, insulated basalt),
## marine (the Mor houseboat's contained composting seat).

const KINDS := ["porcelain", "earth_closet", "matong", "composting_seat", "vacuum", "incinerating", "marine"]


static func build(kind: String) -> StaticBody3D:
	match kind:
		"earth_closet":
			return _earth_closet()
		"matong":
			return _matong()
		"composting_seat":
			return _composting_seat()
		"vacuum":
			return _vacuum()
		"incinerating":
			return _incinerating()
		"marine":
			return _marine()
	return TownProps.build_dry_toilet()


static func _body() -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	return body


static func _part(body: StaticBody3D, semi: Vector3, at: Vector3, color: Color, eps_top: float = SuperEgg.EPSILON_SOFT, eps_bottom: float = SuperEgg.EPSILON_SOFT) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(semi, color, eps_top, eps_bottom)
	mesh.position = at
	body.add_child(mesh)
	return mesh


## Solid collision for the whole fixture: one box matching its envelope,
## paired with the fixture's main part (its first mesh) so the collision policy
## sees one physical visual for its one collider. (It used to tag a throwaway
## node, which left every fixture failing CollisionPolicy.validate_body.)
static func _solid(body: StaticBody3D, size: Vector3, at: Vector3) -> void:
	for child in body.get_children():
		if child is MeshInstance3D:
			CollisionPolicy.add_box(body, child as MeshInstance3D, size, at, Basis(), false)
			return
	var holder := Node3D.new()
	CollisionPolicy.add_box(body, holder, size, at, Basis(), false)
	holder.free()


## A timber seat over a lined composting vault in an adobe plinth, with the
## bread oven's ash in a bin as cover, a water jar and a basin beside it.
static func _earth_closet() -> StaticBody3D:
	var body := _body()
	var adobe := Color(0.62, 0.45, 0.30)
	var timber := Color(0.38, 0.25, 0.14)
	_part(body, Vector3(0.50, 0.30, 0.42), Vector3(0, 0.30, 0.1), adobe, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	_part(body, Vector3(0.44, 0.04, 0.36), Vector3(0, 0.62, 0.08), timber, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	var hole := _part(body, Vector3(0.14, 0.02, 0.17), Vector3(0, 0.665, 0.0), Color(0.08, 0.06, 0.05))
	hole.scale = Vector3(1.0, 1.0, 1.0)
	_part(body, Vector3(0.14, 0.18, 0.14), Vector3(0.62, 0.18, 0.2), Color(0.55, 0.3, 0.2))
	_part(body, Vector3(0.16, 0.12, 0.16), Vector3(-0.64, 0.12, 0.2), Color(0.42, 0.40, 0.38))
	_part(body, Vector3(0.14, 0.05, 0.14), Vector3(-0.64, 0.30, -0.25), Color(0.5, 0.35, 0.22))
	_solid(body, Vector3(1.5, 0.7, 0.9), Vector3(0, 0.35, 0.1))
	return body


## A lidded wooden mǎtǒng: a lacquered barrel on a low stand, brass-banded, with
## a hinged lid, to be set behind a screen in a guest room.
static func _matong() -> StaticBody3D:
	var body := _body()
	var lacquer := Color(0.42, 0.10, 0.07)
	_part(body, Vector3(0.27, 0.24, 0.27), Vector3(0, 0.26, 0.05), lacquer, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	_part(body, Vector3(0.30, 0.025, 0.30), Vector3(0, 0.50, 0.05), Color(0.36, 0.08, 0.06), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	_part(body, Vector3(0.285, 0.02, 0.285), Vector3(0, 0.34, 0.05), Color(0.72, 0.56, 0.2))
	_part(body, Vector3(0.285, 0.02, 0.285), Vector3(0, 0.16, 0.05), Color(0.72, 0.56, 0.2))
	_part(body, Vector3(0.20, 0.03, 0.12), Vector3(0, 0.54, 0.22), Color(0.6, 0.45, 0.2))
	_solid(body, Vector3(0.7, 0.58, 0.7), Vector3(0, 0.29, 0.05))
	return body


## A rattan-screened bench seat over a sealed clay vat with leaf litter beside it.
static func _composting_seat() -> StaticBody3D:
	var body := _body()
	var rattan := Color(0.70, 0.55, 0.30)
	_part(body, Vector3(0.34, 0.28, 0.32), Vector3(0, 0.28, 0.12), Color(0.55, 0.33, 0.22))
	_part(body, Vector3(0.46, 0.04, 0.40), Vector3(0, 0.58, 0.1), rattan, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	_part(body, Vector3(0.12, 0.02, 0.15), Vector3(0, 0.625, 0.0), Color(0.10, 0.08, 0.05))
	_part(body, Vector3(0.20, 0.14, 0.16), Vector3(0.60, 0.14, 0.2), Color(0.30, 0.42, 0.18))
	_part(body, Vector3(0.03, 0.45, 0.03), Vector3(-0.5, 0.45, 0.42), rattan)
	_part(body, Vector3(0.03, 0.45, 0.03), Vector3(0.5, 0.45, 0.42), rattan)
	_solid(body, Vector3(1.4, 0.65, 0.8), Vector3(0, 0.32, 0.1))
	return body


## A sleek pale vacuum-flush fixture on a wall plate, with a glass basin at its side.
static func _vacuum() -> StaticBody3D:
	var body := _body()
	var shell := Color(0.84, 0.92, 0.94)
	_part(body, Vector3(0.20, 0.26, 0.20), Vector3(0, 0.36, 0.28), shell.darkened(0.05))
	_part(body, Vector3(0.30, 0.15, 0.40), Vector3(0, 0.50, 0.0), shell, 2.5, 2.7)
	_part(body, Vector3(0.18, 0.012, 0.28), Vector3(0, 0.655, -0.02), Color(0.12, 0.30, 0.34))
	_part(body, Vector3(0.28, 0.05, 0.40), Vector3(0, 0.68, 0.0), shell.lightened(0.05), 2.2, 2.2)
	_part(body, Vector3(0.20, 0.07, 0.20), Vector3(0.75, 0.82, 0.30), Color(0.55, 0.85, 0.92, 1.0))
	_part(body, Vector3(0.03, 0.40, 0.03), Vector3(0.75, 0.40, 0.38), Color(0.78, 0.55, 0.22))
	_solid(body, Vector3(1.4, 0.88, 0.9), Vector3(0.1, 0.44, 0.15))
	return body


## An incinerating seat in insulated basalt, heated by the city's thermal line:
## a dark shell with a faint ember band, and a cool-water basin for guests.
static func _incinerating() -> StaticBody3D:
	var body := _body()
	var basalt := Color(0.14, 0.13, 0.15)
	_part(body, Vector3(0.34, 0.32, 0.36), Vector3(0, 0.32, 0.12), basalt, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	_part(body, Vector3(0.355, 0.02, 0.375), Vector3(0, 0.34, 0.12), Color(0.85, 0.36, 0.1))
	_part(body, Vector3(0.36, 0.05, 0.38), Vector3(0, 0.66, 0.08), basalt.lightened(0.08), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	_part(body, Vector3(0.13, 0.015, 0.16), Vector3(0, 0.715, 0.04), Color(0.05, 0.04, 0.04))
	_part(body, Vector3(0.22, 0.06, 0.20), Vector3(0.75, 0.80, 0.3), basalt.lightened(0.12))
	_part(body, Vector3(0.17, 0.02, 0.15), Vector3(0.75, 0.865, 0.3), Color(0.35, 0.65, 0.75))
	_part(body, Vector3(0.08, 0.40, 0.08), Vector3(0.75, 0.40, 0.4), basalt)
	_solid(body, Vector3(1.4, 0.74, 0.9), Vector3(0.1, 0.37, 0.15))
	return body


## The houseboat's contained marine composting seat: a moulded box with a hinged
## lid and a small vent stack, set beside a wash space.
static func _marine() -> StaticBody3D:
	var body := _body()
	var hull := Color(0.52, 0.55, 0.50)
	_part(body, Vector3(0.30, 0.28, 0.34), Vector3(0, 0.28, 0.12), hull, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	_part(body, Vector3(0.32, 0.03, 0.36), Vector3(0, 0.58, 0.1), Color(0.62, 0.45, 0.25), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	_part(body, Vector3(0.11, 0.015, 0.14), Vector3(0, 0.615, 0.04), Color(0.1, 0.08, 0.06))
	_part(body, Vector3(0.05, 0.50, 0.05), Vector3(0.24, 0.85, 0.40), hull.darkened(0.2))
	_solid(body, Vector3(0.7, 0.62, 0.8), Vector3(0, 0.31, 0.12))
	return body
