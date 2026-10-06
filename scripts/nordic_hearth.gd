class_name NordicHearth
extends RefCounted

## Scandinavian stoves for the Snow Village's log houses, each one mass built
## against a gable wall with one flue that clears the ridge:
##   peis    a broad open hearth under a corbelled, tapering masonry hood
##           (inn and rescue hall)
##   kakelugn  a tall tiled stove with an iron door and a dark cornice (homes)
##   kiuas   a sauna stove: an iron firebox under a cage of heated stones
##
## Frame: x runs along the gable wall, y is up and -z points into the room, the
## same convention as Hearth.build_chimney_wall. The frame origin is the OUTER
## face of the gable wall; the logs occupy z from 0 down to -2R.

const WALL_IN := 2.0 * LogHouse.R
const STONE := Color(0.62, 0.60, 0.57)
const STONE_DARK := Color(0.40, 0.39, 0.40)
const TILE := Color(0.93, 0.92, 0.88)
const TILE_BLUE := Color(0.36, 0.52, 0.76)
const IRON := Color(0.14, 0.14, 0.16)


static func build(
	house: StaticBody3D, spec: Dictionary, smoke_rng: RandomNumberGenerator, smoke_sink: Array
) -> void:
	var primary: Dictionary = spec.get("hearth", {})
	if primary.is_empty():
		return
	_build_one(house, spec, primary, smoke_rng, smoke_sink)
	# A building may have a second hearth on the opposite gable (a long hall's
	# kitchen range), each its own mass with its own flue.
	var secondary: Dictionary = spec.get("hearth2", {})
	if not secondary.is_empty():
		_build_one(house, spec, secondary, smoke_rng, smoke_sink)


static func _build_one(
	house: StaticBody3D, spec: Dictionary, hearth: Dictionary, smoke_rng: RandomNumberGenerator, smoke_sink: Array
) -> void:
	var cells: Vector2 = spec["cells"]
	var width := cells.x * LogHouse.CELL
	var depth := cells.y * LogHouse.CELL
	var floors := int(spec.get("floors", 1))
	var side := float(hearth.get("side", 1.0))
	var along := float(hearth.get("z", 0.0))
	var pitch := deg_to_rad(float(spec.get("pitch_deg", 46.0)))
	var frame := Transform3D(Basis(Vector3.UP, PI * 0.5 * side), Vector3(side * width * 0.5, 0.0, 0.0))
	var x_at := -side * along
	# Roof surface above the flue, for the shaft height.
	var surface := float(floors) * LogHouse.STOREY + 0.12 + (depth * 0.5 - absf(along)) * tan(pitch)
	var shaft_top := surface + 0.85
	var smoke_at := frame * Vector3(x_at, shaft_top + 0.3, -WALL_IN - 0.3)
	var fire_schedule := _schedule_for(spec)
	var fire: HearthFire = null
	match str(hearth.get("style", "kakelugn")):
		"peis":
			var range_x := -side * float(hearth["range_z"]) if hearth.has("range_z") else NAN
			fire = _peis(house, frame, x_at, shaft_top, range_x, fire_schedule)
		"kiuas":
			fire = _kiuas(house, frame, x_at, shaft_top, fire_schedule)
		_:
			fire = _kakelugn(house, frame, x_at, shaft_top, fire_schedule)
	if smoke_rng != null:
		var puffs := ChimneySmoke.spawn(house, smoke_at, smoke_rng, 4)
		smoke_sink.append_array(puffs)
		if fire != null:
			fire.smoke.append_array(puffs)
	if fire != null:
		fire.refresh()


static func _schedule_for(spec: Dictionary) -> Dictionary:
	var kind := str(spec.get("kind", ""))
	if kind in ["inn", "inn_wing"]:
		return {"mode":"always"}
	if kind == "workshop":
		return {"mode":"hours", "hours":[6.0, 19.0]}
	if kind == "bathhouse":
		return {"mode":"hours", "hours":[14.0, 23.0]}
	return {"mode":"evening"}


static func _part(
	house: StaticBody3D, frame: Transform3D, at: Vector3, half: Vector3, color: Color,
	epsilon: float = SuperEgg.EPSILON_SOFT, solid: bool = false
) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half, color, epsilon, epsilon)
	var basis := frame.basis
	var position := frame * at
	mesh.transform = Transform3D(basis, position)
	house.add_child(mesh)
	if solid:
		# Boxes are axis-aligned in the frame; the frame is turned by +/-90 degrees.
		var size := Vector3(half.x * 2.0, half.y * 2.0, half.z * 2.0)
		CollisionPolicy.add_box(house, mesh, size, position, basis, false)
	else:
		CollisionPolicy.mark_decorative(mesh)
	return mesh


static func _fire(house: StaticBody3D, frame: Transform3D, at: Vector3, energy: float, reach: float) -> void:
	var flame := ParticleFX.build_flame_particles(11, 0.6, 0.85, 1.8, 2.8, -0.6)
	flame.position = frame * at
	house.add_child(flame)
	CollisionPolicy.mark_decorative(flame)
	var light := OmniLight3D.new()
	light.position = frame * (at + Vector3(0.0, 0.5, -0.4))
	light.light_color = Color(1.0, 0.45, 0.14)
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	house.add_child(light)


static func _scheduled_fire(
	house: StaticBody3D, frame: Transform3D, at: Vector3, energy: float, reach: float, schedule: Dictionary
) -> HearthFire:
	var fire := HearthFire.create(house, schedule)
	var flame := ParticleFX.build_flame_particles(11, 0.6, 0.85, 1.8, 2.8, -0.6)
	flame.position = frame * at
	fire.add_flame(flame)
	CollisionPolicy.mark_decorative(flame)
	var light := OmniLight3D.new()
	light.position = frame * (at + Vector3(0.0, 0.5, -0.4))
	light.light_color = Color(1.0, 0.45, 0.14)
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	fire.add_light(light)
	return fire


## Open hearth: a breast block with a superellipse opening, hearth stones, a
## corbelled hood narrowing to one flue.
static func _peis(
	house: StaticBody3D, frame: Transform3D, x_at: float, shaft_top: float,
	range_x: float = NAN, schedule: Dictionary = {}
) -> HearthFire:
	var breast_depth := 0.95
	var breast_height := 2.05
	var half_width := 1.5
	var material := SolidModel.material(STONE, 0.9, 0.0)
	# One masonry mass: the hall breast and, when the plan gives one, a kitchen
	# range opening in the same block on the far side of the partition.
	var x_low := x_at - half_width
	var x_high := x_at + half_width
	if not is_nan(range_x):
		x_low = minf(x_low, range_x - 0.95)
		x_high = maxf(x_high, range_x + 0.95)
	var block_x := (x_low + x_high) * 0.5
	var mass := CSGCombiner3D.new()
	mass.name = "PeisBreast"
	mass.transform = Transform3D(frame.basis, frame * Vector3(block_x, 0.0, -WALL_IN - breast_depth * 0.5))
	mass.use_collision = true
	mass.collision_layer = 1
	mass.collision_mask = 0
	SolidModel.add_super(
		mass, "Breast", Vector3((x_high - x_low) * 0.5, breast_height * 0.5, breast_depth * 0.5),
		CSGShape3D.OPERATION_UNION, material, Vector3(0.0, breast_height * 0.5, 0.0), 5.0
	)
	var opening_half_height := 0.62
	var cutter := SolidModel.add_profile(
		mass, "Opening", breast_depth - 0.1, Vector2(opening_half_height, 0.95), 4.0, CSGShape3D.OPERATION_SUBTRACTION,
		SolidModel.material(STONE.darkened(0.5), 0.95, 0.0), Vector3(x_at - block_x, 0.08 + opening_half_height, -0.15), 96
	)
	cutter.rotation.y = PI * 0.5
	if not is_nan(range_x):
		var range_cutter := SolidModel.add_profile(
			mass, "RangeOpening", breast_depth - 0.1, Vector2(0.4, 0.5), 4.0, CSGShape3D.OPERATION_SUBTRACTION,
			SolidModel.material(STONE.darkened(0.5), 0.95, 0.0), Vector3(range_x - block_x, 0.78, -0.15), 96
		)
		range_cutter.rotation.y = PI * 0.5
	house.add_child(mass)
	if not is_nan(range_x):
		# An iron cooktop over the range's firebox and a low hearth stone for it.
		_part(house, frame, Vector3(range_x, 1.08, -WALL_IN - breast_depth - 0.18), Vector3(0.55, 0.03, 0.3), IRON, 4.0)
		_part(house, frame, Vector3(range_x, 0.05, -WALL_IN - breast_depth - 0.4), Vector3(0.7, 0.05, 0.4), STONE.lightened(0.08), SuperEgg.EPSILON_FLAT)
	# Hearth stones and a raised kerb.
	_part(house, frame, Vector3(x_at, 0.05, -WALL_IN - breast_depth - 0.45), Vector3(1.4, 0.05, 0.5), STONE.lightened(0.08), SuperEgg.EPSILON_FLAT)
	# Corbelled hood: each course steps in, so the funnel reads as one soft mass.
	var courses := [
		[Vector3(1.28, 0.27, 0.46), 2.05 + 0.27],
		[Vector3(1.02, 0.3, 0.40), 2.05 + 0.54 + 0.3],
		[Vector3(0.76, 0.32, 0.34), 2.05 + 0.54 + 0.6 + 0.32],
		[Vector3(0.56, 0.3, 0.30), 2.05 + 0.54 + 0.6 + 0.64 + 0.3],
	]
	var top_of_hood := 2.05 + 0.54 + 0.6 + 0.64 + 0.6
	for course: Array in courses:
		var half: Vector3 = course[0]
		_part(house, frame, Vector3(x_at, float(course[1]), -WALL_IN - half.z), half, STONE.lightened(0.03), SuperEgg.EPSILON_SOFT, false)
	var shaft_height := shaft_top - top_of_hood
	_part(
		house, frame, Vector3(x_at, top_of_hood + shaft_height * 0.5, -WALL_IN - 0.3),
		Vector3(0.42, shaft_height * 0.5, 0.3), STONE.darkened(0.04), SuperEgg.EPSILON_SOFT, true
	)
	_part(house, frame, Vector3(x_at, shaft_top + 0.07, -WALL_IN - 0.3), Vector3(0.52, 0.07, 0.4), STONE_DARK, 3.6)
	# Hearth beam: a log mantel across the opening's top.
	_part(house, frame, Vector3(x_at, 1.42, -WALL_IN - breast_depth - 0.04), Vector3(1.2, 0.09, 0.09), LogHouse.LOG_COLORS[2], 4.0)
	return _scheduled_fire(
		house, frame, Vector3(x_at, 0.16, -WALL_IN - breast_depth * 0.55), 1.5, 10.0, schedule
	)


## Tiled stove: stone footing, cream tile body with two blue bands, a dark
## cornice, an iron door and a narrow iron flue.
static func _kakelugn(
	house: StaticBody3D, frame: Transform3D, x_at: float, shaft_top: float, schedule: Dictionary = {}
) -> HearthFire:
	var fire := HearthFire.create(house, schedule)
	var z_front := -WALL_IN - 0.46
	_part(house, frame, Vector3(x_at, 0.2, z_front), Vector3(0.5, 0.2, 0.46), STONE_DARK, SuperEgg.EPSILON_FLAT, true)
	_part(house, frame, Vector3(x_at, 0.4 + 0.62, z_front), Vector3(0.44, 0.62, 0.41), TILE, 3.4, true)
	_part(house, frame, Vector3(x_at, 0.98, z_front), Vector3(0.455, 0.05, 0.425), TILE_BLUE, 4.0)
	_part(house, frame, Vector3(x_at, 1.62, z_front), Vector3(0.38, 0.4, 0.35), TILE, 3.4, true)
	_part(house, frame, Vector3(x_at, 1.52, z_front), Vector3(0.395, 0.045, 0.365), TILE_BLUE, 4.0)
	_part(house, frame, Vector3(x_at, 2.06, z_front), Vector3(0.5, 0.06, 0.45), STONE_DARK, SuperEgg.EPSILON_FLAT)
	# Iron door with a thin line of firelight.
	_part(house, frame, Vector3(x_at, 0.62, z_front - 0.42), Vector3(0.17, 0.18, 0.02), IRON, 4.0)
	var glow := _part(house, frame, Vector3(x_at, 0.62, z_front - 0.445), Vector3(0.12, 0.012, 0.006), Color(1.0, 0.6, 0.2), 3.0)
	var glow_material := glow.get_surface_override_material(0) as StandardMaterial3D
	if glow_material != null:
		glow_material.emission_enabled = true
		glow_material.emission = Color(1.0, 0.5, 0.15)
		glow_material.emission_energy_multiplier = 2.2
		fire.add_ember(glow_material)
	var pipe_height := shaft_top - 2.1
	_part(house, frame, Vector3(x_at, 2.1 + pipe_height * 0.5, -WALL_IN - 0.28), Vector3(0.16, pipe_height * 0.5, 0.16), IRON, SuperEgg.EPSILON_FLAT)
	_part(house, frame, Vector3(x_at, shaft_top + 0.05, -WALL_IN - 0.28), Vector3(0.24, 0.05, 0.24), IRON, 3.6)
	var light := OmniLight3D.new()
	light.position = frame * Vector3(x_at, 0.9, z_front - 0.9)
	light.light_color = Color(1.0, 0.55, 0.22)
	light.light_energy = 0.8
	light.omni_range = 6.0
	light.shadow_enabled = false
	fire.add_light(light)
	return fire


## Sauna stove: iron firebox on a stone kerb with a cage of heated stones above.
static func _kiuas(
	house: StaticBody3D, frame: Transform3D, x_at: float, shaft_top: float, schedule: Dictionary = {}
) -> HearthFire:
	var fire := HearthFire.create(house, schedule)
	var z_front := -WALL_IN - 0.5
	_part(house, frame, Vector3(x_at, 0.1, z_front), Vector3(0.78, 0.1, 0.62), STONE_DARK, SuperEgg.EPSILON_FLAT, true)
	_part(house, frame, Vector3(x_at, 0.2 + 0.4, z_front), Vector3(0.42, 0.4, 0.36), IRON, 4.0, true)
	_part(house, frame, Vector3(x_at, 0.5, z_front - 0.38), Vector3(0.17, 0.14, 0.02), IRON.lightened(0.1), 4.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4401
	for i in 16:
		var local := Vector3(rng.randf_range(-0.34, 0.34), 0.62 + 0.1 + rng.randf_range(0.0, 0.14) + 0.14 * float(i / 8), rng.randf_range(-0.28, 0.28))
		_part(
			house, frame, Vector3(x_at, 0.0, z_front) + local, Vector3(0.1, 0.07, 0.09),
			STONE.darkened(0.12 + 0.08 * rng.randf()), 2.6
		)
	var pipe_height := shaft_top - 1.1
	_part(house, frame, Vector3(x_at, 1.1 + pipe_height * 0.5, -WALL_IN - 0.3), Vector3(0.12, pipe_height * 0.5, 0.12), IRON, SuperEgg.EPSILON_FLAT)
	_part(house, frame, Vector3(x_at, shaft_top + 0.05, -WALL_IN - 0.3), Vector3(0.2, 0.05, 0.2), IRON, 3.6)
	var light := OmniLight3D.new()
	light.position = frame * Vector3(x_at, 0.9, z_front - 0.7)
	light.light_color = Color(1.0, 0.5, 0.2)
	light.light_energy = 0.9
	light.omni_range = 5.0
	light.shadow_enabled = false
	fire.add_light(light)
	return fire
