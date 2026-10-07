class_name CalderaFurniture
extends RefCounted

## Furniture for the Fire caldera. A lava person would burn wood or ordinary
## cloth by touching it, so nothing here is either: cast basalt and volcanic
## stone, blued and stainless steel, glass, and cloths that real industry makes
## for heat:
##   - basalt fibre: spun from molten basalt, used for fire blankets; a warm
##     bronze-gold, soft enough for guests' bedding, cushions and mats;
##   - silica cloth: amorphous silica, good to about 1000 C; pale, used for
##     mattresses and anything a lava person sits on or handles;
##   - coated glass-fibre cloth: takes mineral coatings in colour (the amber and
##     cobalt upholstery);
##   - ceramic fibre (alumina-silica, about 1260 C) for the hottest work, and
##     stainless-steel mesh for drapery, where a building needs them.
## Never asbestos (toxic), and never aramid (it chars).
##
## Light here is architectural: concealed LED lines under counters, behind
## bed heads and along shelves (`led_line`), with a few real lights hidden in
## the coves (`concealed_light`). No visible light fittings. Open flame and lava
## light belong to the working buildings, not the guest house.
##
## Conventions as Furnishings: `at` is the piece's foot on the floor, `yaw`
## turns it; local +Z is its back (to a wall), -Z its front. A bed's head is
## toward -Z.

const BASALT := Color(0.13, 0.12, 0.12)
const STONE := Color(0.36, 0.34, 0.33)
const COOL_STONE := Color(0.46, 0.46, 0.48)
const STEEL := Color(0.15, 0.24, 0.42)
const STAINLESS := Color(0.70, 0.73, 0.75)
const FIBRE := Color(0.62, 0.50, 0.32)
const FIBRE_GREY := Color(0.48, 0.46, 0.45)
const SILICA := Color(0.80, 0.75, 0.64)
const LED_WARM := Color(1.0, 0.84, 0.64)
const LED_COOL := Color(0.86, 0.92, 1.0)
const GLASS := Color(0.80, 0.90, 0.95, 0.28)


static func _at(at: Vector3, yaw: float, local: Vector3) -> Vector3:
	return at + Basis(Vector3.UP, yaw) * local


static func piece(body: StaticBody3D, half: Vector3, colour: Color, at: Vector3, yaw: float = 0.0, solid: bool = false, epsilon: float = SuperEgg.EPSILON_FLAT) -> MeshInstance3D:
	return Furnishings.piece(body, half, colour, at, yaw, solid, epsilon)


static func _metal(body: StaticBody3D, half: Vector3, at: Vector3, yaw: float, colour: Color = STEEL) -> void:
	var part := piece(body, half, colour, at, yaw)
	part.material_override = SolidModel.material(colour, 0.25, 0.85)


## A bed for a cool guest: a cast-basalt base, a blued-steel head panel with a
## forged fork, a silica-cloth mattress, a blanket in `cloth` and a basalt-fibre
## bolster; an LED line hidden behind the head panel washes the wall.
static func bed(body: StaticBody3D, at: Vector3, yaw: float, cloth: Color) -> void:
	piece(body, Vector3(0.52, 0.18, 1.08), BASALT, _at(at, yaw, Vector3(0, 0.18, 0.05)), yaw, true)
	piece(body, Vector3(0.48, 0.09, 1.02), SILICA, _at(at, yaw, Vector3(0, 0.45, 0.05)), yaw, false, SuperEgg.EPSILON_SOFT)
	piece(body, Vector3(0.50, 0.05, 0.66), cloth, _at(at, yaw, Vector3(0, 0.55, 0.38)), yaw, false, SuperEgg.EPSILON_SOFT)
	piece(body, Vector3(0.40, 0.07, 0.15), FIBRE, _at(at, yaw, Vector3(0, 0.6, -0.78)), yaw, false, SuperEgg.EPSILON_SOFT)
	_metal(body, Vector3(0.55, 0.45, 0.04), _at(at, yaw, Vector3(0, 0.62, -1.1)), yaw)
	for side: float in [-1.0, 1.0]:
		_metal(body, Vector3(0.03, 0.22, 0.03), _at(at, yaw, Vector3(side * 0.18, 1.0, -1.1)), yaw + side * 0.5)
	led_line(body, _at(at, yaw, Vector3(0, 1.065, -1.16)), yaw, 1.0, LED_WARM)


## A chest for a guest's things: a stone box with a steel lid band; its back
## (and hinge) toward +Z.
static func chest(body: StaticBody3D, at: Vector3, yaw: float, length: float = 0.8) -> void:
	piece(body, Vector3(length * 0.5, 0.24, 0.26), STONE, _at(at, yaw, Vector3(0, 0.24, 0)), yaw, true)
	_metal(body, Vector3(length * 0.5 + 0.02, 0.03, 0.28), _at(at, yaw, Vector3(0, 0.5, 0)), yaw)


## A chair on a blued-steel frame with a basalt-fibre seat and back; it faces
## local -Z. `arms` makes it an armchair.
static func chair(body: StaticBody3D, at: Vector3, yaw: float, cloth: Color, arms: bool = false) -> void:
	for x: float in [-0.22, 0.22]:
		for z: float in [-0.2, 0.2]:
			_metal(body, Vector3(0.025, 0.22, 0.025), _at(at, yaw, Vector3(x, 0.22, z)), yaw)
	piece(body, Vector3(0.27, 0.06, 0.25), cloth, _at(at, yaw, Vector3(0, 0.48, 0)), yaw, true, SuperEgg.EPSILON_SOFT)
	piece(body, Vector3(0.26, 0.28, 0.05), cloth.darkened(0.08), _at(at, yaw, Vector3(0, 0.82, 0.23)), yaw, false, SuperEgg.EPSILON_SOFT)
	if arms:
		for x: float in [-0.3, 0.3]:
			_metal(body, Vector3(0.03, 0.02, 0.24), _at(at, yaw, Vector3(x, 0.68, 0)), yaw)


## A stone table top on two blued-steel trestles.
static func table(body: StaticBody3D, at: Vector3, yaw: float, length: float, depth: float) -> void:
	piece(body, Vector3(length * 0.5, 0.04, depth * 0.5), COOL_STONE, _at(at, yaw, Vector3(0, 0.76, 0)), yaw, true)
	for x: float in [-1.0, 1.0]:
		_metal(body, Vector3(0.04, 0.36, depth * 0.38), _at(at, yaw, Vector3(x * (length * 0.5 - 0.25), 0.36, 0)), yaw)


## A low table for the rest corner.
static func low_table(body: StaticBody3D, at: Vector3, yaw: float) -> void:
	piece(body, Vector3(0.45, 0.03, 0.35), BASALT.lightened(0.1), _at(at, yaw, Vector3(0, 0.42, 0)), yaw, true)
	_metal(body, Vector3(0.2, 0.2, 0.2), _at(at, yaw, Vector3(0, 0.2, 0)), yaw)


## The keeper's counter: a stone body, a cool stone top, a steel kick; the
## customer's face toward local -Z, lit by a line under the top's overhang and
## another washing the floor under the kick.
static func counter(body: StaticBody3D, at: Vector3, yaw: float, length: float) -> void:
	piece(body, Vector3(length * 0.5, 0.48, 0.24), STONE, _at(at, yaw, Vector3(0, 0.48, 0.05)), yaw, true)
	piece(body, Vector3(length * 0.5 + 0.06, 0.04, 0.36), COOL_STONE, _at(at, yaw, Vector3(0, 0.99, 0)), yaw, true)
	_metal(body, Vector3(length * 0.5, 0.04, 0.02), _at(at, yaw, Vector3(0, 0.06, -0.2)), yaw)
	led_line(body, _at(at, yaw, Vector3(0, 0.94, -0.26)), yaw, length - 0.1, LED_WARM)
	led_line(body, _at(at, yaw, Vector3(0, 0.012, -0.17)), yaw, length - 0.1, LED_WARM)


## A long stone sideboard against a wall, back to +Z, a line under its top.
static func sideboard(body: StaticBody3D, at: Vector3, yaw: float, length: float) -> void:
	piece(body, Vector3(length * 0.5, 0.42, 0.24), STONE, _at(at, yaw, Vector3(0, 0.42, 0)), yaw, true)
	piece(body, Vector3(length * 0.5 + 0.04, 0.03, 0.27), COOL_STONE, _at(at, yaw, Vector3(0, 0.87, 0)), yaw, false)
	led_line(body, _at(at, yaw, Vector3(0, 0.83, -0.255)), yaw, length - 0.1, LED_WARM)


## Steel shelving with glass shelves, back to +Z, each shelf lit by a line
## under its front edge; `stock` fills it.
static func shelves(body: StaticBody3D, at: Vector3, yaw: float, length: float, tiers: int, stock: Callable) -> void:
	for x: float in [-1.0, 1.0]:
		_metal(body, Vector3(0.025, 0.95, 0.15), _at(at, yaw, Vector3(x * length * 0.5, 0.95, 0)), yaw)
	CollisionPolicy.add_box(body, piece(body, Vector3(length * 0.5, 0.02, 0.16), STAINLESS, _at(at, yaw, Vector3(0, 0.1, 0)), yaw), Vector3(length, 1.9, 0.32), _at(at, yaw, Vector3(0, 0.95, 0)), Basis(Vector3.UP, yaw), false)
	for t in tiers:
		var y := 0.45 + 0.42 * float(t)
		var shelf := piece(body, Vector3(length * 0.5, 0.012, 0.16), GLASS, _at(at, yaw, Vector3(0, y, 0)), yaw)
		var glass := SolidModel.material(GLASS, 0.06, 0.05)
		glass.cull_mode = BaseMaterial3D.CULL_DISABLED
		shelf.material_override = glass
		led_line(body, _at(at, yaw, Vector3(0, y - 0.02, -0.13)), yaw, length - 0.06, LED_WARM)
		var count := int(length / 0.28)
		for i in count:
			stock.call(body, _at(at, yaw, Vector3(-length * 0.5 + 0.18 + 0.28 * float(i), y + 0.012, 0)), t * count + i)


## A stone bench.
static func bench(body: StaticBody3D, at: Vector3, yaw: float, length: float) -> void:
	piece(body, Vector3(length * 0.5, 0.22, 0.26), COOL_STONE, _at(at, yaw, Vector3(0, 0.22, 0)), yaw, true)


## A blued-steel rail of hooks on a wall, back to +Z.
static func hooks(body: StaticBody3D, at: Vector3, yaw: float, length: float, y: float = 1.7) -> void:
	_metal(body, Vector3(length * 0.5, 0.03, 0.02), _at(at, yaw, Vector3(0, y, 0)), yaw)
	for i in maxi(int(length / 0.35), 2):
		_metal(body, Vector3(0.015, 0.06, 0.05), _at(at, yaw, Vector3(-length * 0.5 + 0.2 + 0.35 * float(i), y - 0.06, -0.04)), yaw)


## A mat of woven basalt fibre.
static func mat(body: StaticBody3D, at: Vector3, yaw: float, size: Vector2, cloth: Color) -> void:
	piece(body, Vector3(size.x * 0.5, 0.01, size.y * 0.5), cloth, at + Vector3(0, 0.012, 0), yaw, false, SuperEgg.EPSILON_SOFT)
	piece(body, Vector3(size.x * 0.5 - 0.15, 0.012, size.y * 0.5 - 0.15), cloth.lightened(0.12), at + Vector3(0, 0.016, 0), yaw, false, SuperEgg.EPSILON_SOFT)


## A concealed LED line along local X: a thin emissive strip, set where a lip
## or a top hides it from standing eye height. It lights by glow alone; pair a
## few with `concealed_light` for real light in a room.
static func led_line(body: Node3D, at: Vector3, yaw: float, length: float, colour: Color = LED_WARM, energy: float = 2.6) -> MeshInstance3D:
	var strip := MeshInstance3D.new()
	strip.name = "LedLine"
	var box := BoxMesh.new()
	box.size = Vector3(length, 0.012, 0.025)
	strip.mesh = box
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = energy
	strip.material_override = material
	strip.position = at
	strip.rotation.y = yaw
	body.add_child(strip)
	CollisionPolicy.mark_decorative(strip)
	return strip


## A real light with no fitting: it stands for the cove and recessed lines
## around it. A handful per room, never one per strip.
static func concealed_light(body: Node3D, at: Vector3, colour: Color = LED_WARM, energy: float = 0.7, reach: float = 5.0) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.name = "ConcealedLight"
	light.position = at
	light.light_color = colour
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	body.add_child(light)
	return light


## A glass vessel or jar: `colour` its contents.
static func jar(body: StaticBody3D, at: Vector3, colour: Color, size: float = 0.07) -> void:
	var shell := piece(body, Vector3(size, size * 1.5, size), GLASS, at + Vector3(0, size * 1.5, 0), 0.0, false, 4.0)
	var material := SolidModel.material(GLASS, 0.05, 0.05)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = material
	piece(body, Vector3(size * 0.82, size, size * 0.82), colour, at + Vector3(0, size * 1.1, 0), 0.0, false, 4.0)
