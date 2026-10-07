class_name FishingBoats
extends RefCounted

## The fishing village's working boats (design brief 4.18): each built for its
## owner's job and in its household's colours, at its berth's true size. The
## frame's origin is on the waterline amidships, +X the bow, +Z to port. One
## box collider from the waterline to the gunwale makes each boat solid and a
## landing for anyone who climbs aboard; everything else is decorative.
## Ivo's roofed launch is FishingBuildings.ferry_launch().

## Below the waterline (draft) and above it to the gunwale (freeboard).
const DRAFT := 0.25
const ROPE := Color(0.62, 0.52, 0.36)
const ENGINE := Color(0.20, 0.22, 0.24)
const NET := Color(0.36, 0.44, 0.40)
const BASKET := Color(0.66, 0.50, 0.28)
const FRESH_TIMBER := Color(0.86, 0.74, 0.54)
const BRASS := Color(0.76, 0.58, 0.28)


static func build(boat: Dictionary, length: float, beam: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = str(boat["name"])
	body.collision_layer = 1
	body.collision_mask = 0
	var colour: Color = FishingVillagePlan.HOUSEHOLD_COLORS[FishingVillagePlan.household_of(str(boat["owner"]))]
	var hl := length * 0.5
	var hb := beam * 0.5
	match str(boat["name"]):
		"DiveSkiff":
			var fb := _hull(body, hl, hb, 0.38, colour, colour.lightened(0.35))
			_outboard(body, hl, fb)
			# The ladder hooked over the port side, the shot line coiled with
			# its weight, two helmets on the thwart, the dive flag.
			for rung in 4:
				_part(body, Vector3(0.02, 0.02, 0.2), StiltKit.TIMBER_DARK, Vector3(0.3, fb + 0.1 - 0.22 * float(rung), hb + 0.08))
			for side: float in [-0.18, 0.18]:
				_part(body, Vector3(0.02, 0.45, 0.02), StiltKit.TIMBER_DARK, Vector3(0.3 + side, fb - 0.2, hb + 0.08))
			_part(body, Vector3(0.22, 0.06, 0.22), ROPE, Vector3(-0.6, fb + 0.06, -0.2), 2.0)
			_part(body, Vector3(0.09, 0.09, 0.09), ENGINE, Vector3(-0.25, fb + 0.09, -0.3), 2.0)
			_thwart(body, 0.6, hb, fb)
			for i in 2:
				_part(body, Vector3(0.17, 0.17, 0.17), BRASS.lightened(0.05 * float(i)), Vector3(0.45 + 0.4 * float(i), fb + 0.29, -0.15), 2.2)
			_part(body, Vector3(0.015, 0.55, 0.015), StiltKit.TIMBER_DARK, Vector3(hl - 0.35, fb + 0.55, 0.0))
			_part(body, Vector3(0.18, 0.12, 0.01), Color(0.78, 0.16, 0.14), Vector3(hl - 0.17, fb + 0.95, 0.0))
			# The flag's white bar, the sign of a diver below.
			_part(body, Vector3(0.17, 0.025, 0.012), Color(0.94, 0.92, 0.88), Vector3(hl - 0.17, fb + 0.95, 0.0), SuperEgg.EPSILON_FLAT, Basis(Vector3(0, 0, 1), 0.55))
		"RepairBoat":
			# Bare timber, the teal sheer strake only half repainted.
			var fb := _hull(body, hl, hb, 0.42, StiltKit.TIMBER.lightened(0.08), StiltKit.TIMBER_PALE)
			_part(body, Vector3(hl * 0.45, 0.05, 0.02), colour, Vector3(hl * 0.45, fb - 0.06, hb + 0.01))
			for i in 2:
				_part(body, Vector3(hl * 0.35, 0.05, 0.02), FRESH_TIMBER, Vector3(-hl * 0.2, fb - 0.2 - 0.1 * float(i), hb + 0.005))
			_thwart(body, -0.6, hb, fb)
			_thwart(body, 0.8, hb, fb)
			for i in 4:
				_part(body, Vector3(1.1, 0.025, 0.09), FRESH_TIMBER.darkened(0.05 * float(i % 2)), Vector3(0.1, fb + 0.2 + 0.05 * float(i), -0.25 + 0.17 * float(i % 3)))
			_part(body, Vector3(0.3, 0.16, 0.18), StiltKit.TIMBER_DARK, Vector3(-hl + 0.8, fb + 0.16, 0.25))
		"WorkPunt":
			# Square ended and flat: a working float for the pearl beds.
			var fb := _hull(body, hl, hb, 0.3, colour.darkened(0.1), colour.lightened(0.25), SuperEgg.EPSILON_FLAT)
			_part(body, Vector3(1.9, 0.025, 0.025), StiltKit.TIMBER_PALE, Vector3(0.1, fb + 0.05, hb - 0.12))
			for i in 3:
				_part(body, Vector3(0.22, 0.16, 0.22), BASKET.darkened(0.06 * float(i)), Vector3(-0.9 + 0.55 * float(i), fb + 0.16, -0.25), 2.4)
				for k in 3:
					_part(body, Vector3(0.05, 0.03, 0.05), Color(0.92, 0.88, 0.80), Vector3(-0.95 + 0.55 * float(i) + 0.05 * float(k), fb + 0.33, -0.27 + 0.04 * float(k)), 2.0)
			_part(body, Vector3(0.3, 0.04, 0.3), BASKET.lightened(0.15), Vector3(0.9, fb + 0.06, 0.15), 3.0)
		"WorkingBoat":
			var fb := _hull(body, hl, hb, 0.52, colour, colour.lightened(0.3))
			# The engine box aft, the net heaped amidships, the winch forward.
			_part(body, Vector3(0.45, 0.3, 0.5), ENGINE.lightened(0.15), Vector3(-hl + 0.75, fb + 0.3, 0.0))
			_part(body, Vector3(0.04, 0.3, 0.04), ENGINE, Vector3(-hl + 0.55, fb + 0.85, 0.3))
			_part(body, Vector3(0.9, 0.22, 0.7), NET, Vector3(0.1, fb + 0.2, 0.0), 2.4)
			_part(body, Vector3(0.6, 0.12, 0.45), NET.lightened(0.12), Vector3(0.3, fb + 0.36, 0.1), 2.4)
			for side: float in [-0.5, 0.5]:
				_part(body, Vector3(0.06, 0.28, 0.06), StiltKit.TIMBER_DARK, Vector3(hl - 0.8, fb + 0.28, side))
			_part(body, Vector3(0.14, 0.14, 0.5), ENGINE.lightened(0.25), Vector3(hl - 0.8, fb + 0.5, 0.0), 2.4)
			for i in 3:
				_part(body, Vector3(0.28, 0.13, 0.2), Color(0.86, 0.84, 0.78).darkened(0.06 * float(i)), Vector3(-0.9, fb + 0.13 + 0.26 * float(i / 2), -0.55 + 0.45 * float(i % 2)))
			# The night-fishing lamp on a short mast.
			_part(body, Vector3(0.04, 0.9, 0.04), StiltKit.TIMBER_DARK, Vector3(0.9, fb + 0.9, -0.6))
			_part(body, Vector3(0.12, 0.14, 0.12), Color(1.0, 0.82, 0.5), Vector3(0.9, fb + 1.7, -0.5), 2.2)
		"UtilityBoat":
			var fb := _hull(body, hl, hb, 0.45, colour, colour.lightened(0.25))
			_part(body, Vector3(hl - 0.15, 0.05, hb + 0.015), Color(0.24, 0.55, 0.52), Vector3(0.0, fb - 0.18, 0.0))
			_outboard(body, hl, fb)
			_thwart(body, -0.4, hb, fb)
			# The rescue float, the boat hook, the tow line.
			var float_ring := MeshInstance3D.new()
			var torus := TorusMesh.new()
			torus.inner_radius = 0.2
			torus.outer_radius = 0.34
			float_ring.mesh = torus
			var ring_material := StandardMaterial3D.new()
			ring_material.albedo_color = Color(0.92, 0.42, 0.18)
			float_ring.material_override = ring_material
			# Lying flat on the foredeck, ready to throw.
			float_ring.transform = Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.0)), Vector3(0.7, fb + 0.06, -0.25))
			body.add_child(float_ring)
			CollisionPolicy.mark_decorative(float_ring)
			_part(body, Vector3(1.6, 0.02, 0.02), StiltKit.TIMBER_PALE, Vector3(0.2, fb + 0.06, hb - 0.15))
			_part(body, Vector3(0.05, 0.05, 0.08), ENGINE, Vector3(1.8, fb + 0.06, hb - 0.15))
			_part(body, Vector3(0.28, 0.07, 0.28), ROPE, Vector3(hl - 0.6, fb + 0.07, 0.2), 2.0)
		"PaddleSkiff":
			var fb := _hull(body, hl, hb, 0.28, colour, Color(0.30, 0.50, 0.32))
			_thwart(body, 0.0, hb, fb)
			_part(body, Vector3(0.75, 0.02, 0.05), StiltKit.TIMBER_PALE, Vector3(0.0, fb + 0.1, 0.0), SuperEgg.EPSILON_FLAT, Basis(Vector3.UP, 0.25))
			_part(body, Vector3(0.12, 0.02, 0.09), StiltKit.TIMBER_PALE, Vector3(0.74, fb + 0.1, 0.19), 3.0, Basis(Vector3.UP, 0.25))
			_part(body, Vector3(0.3, 0.1, 0.2), NET, Vector3(-0.6, fb + 0.1, 0.0), 2.4)
			_part(body, Vector3(0.9, 0.012, 0.012), StiltKit.TIMBER_DARK, Vector3(0.2, fb + 0.06, -0.3), SuperEgg.EPSILON_FLAT, Basis(Vector3.UP, -0.08))
		_:
			_hull(body, hl, hb, 0.4, colour, colour.lightened(0.3))
	return body


## The hull: one SuperEgg from the keel to the gunwale, the sheer strake on
## its lip and a planked sole on top; returns the gunwale's height (freeboard).
static func _hull(body: StaticBody3D, hl: float, hb: float, freeboard: float, colour: Color, strake: Color, epsilon: float = SuperEgg.EPSILON_SOFT) -> float:
	var half_depth := (freeboard + DRAFT) * 0.5
	var centre_y := (freeboard - DRAFT) * 0.5
	var hull := _part(body, Vector3(hl, half_depth, hb), colour.darkened(0.12), Vector3(0, centre_y, 0), epsilon)
	_part(body, Vector3(hl - 0.04, 0.04, hb + 0.02), strake, Vector3(0, freeboard - 0.03, 0))
	_part(body, Vector3(hl * 0.82, 0.015, hb * 0.78), StiltKit.DECK, Vector3(0, freeboard + 0.005, 0))
	var collider := CollisionPolicy.add_box(body, hull, Vector3(hl * 1.9, freeboard + DRAFT, hb * 1.85), Vector3(0, centre_y, 0), Basis(), true)
	collider.name = "HullShape"
	return freeboard


## A seat across the boat at `x`.
static func _thwart(body: StaticBody3D, x: float, hb: float, freeboard: float) -> void:
	_part(body, Vector3(0.11, 0.025, hb * 0.8), StiltKit.TIMBER_PALE, Vector3(x, freeboard + 0.2, 0))
	for side: float in [-1.0, 1.0]:
		_part(body, Vector3(0.04, 0.09, 0.04), StiltKit.TIMBER_DARK, Vector3(x, freeboard + 0.09, side * hb * 0.6))


## An outboard engine on the transom, its leg down into the water.
static func _outboard(body: StaticBody3D, hl: float, freeboard: float) -> void:
	_part(body, Vector3(0.14, 0.2, 0.12), ENGINE, Vector3(-hl - 0.08, freeboard + 0.16, 0))
	_part(body, Vector3(0.035, 0.32, 0.035), ENGINE.lightened(0.1), Vector3(-hl - 0.1, freeboard - 0.3, 0))
	_part(body, Vector3(0.1, 0.04, 0.06), ENGINE.lightened(0.2), Vector3(-hl - 0.08, freeboard + 0.38, 0))


static func _part(body: StaticBody3D, half: Vector3, colour: Color, at: Vector3, epsilon: float = SuperEgg.EPSILON_FLAT, basis: Basis = Basis()) -> MeshInstance3D:
	var mesh := StiltKit.egg(half, colour, epsilon, epsilon)
	mesh.transform = Transform3D(basis, at)
	body.add_child(mesh)
	CollisionPolicy.mark_decorative(mesh)
	return mesh
