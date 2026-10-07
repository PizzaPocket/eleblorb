class_name FishingIslets
extends RefCounted

## Anvil Rock and Heron Rock, the two limestone islets the Crossroads Fishing
## Village stands against (docs/architecture/fishing_village_layout.md, section
## 2), built as one terrain-grade heightfield mesh on a 0.5 m grid with trimesh
## collision, and their submerged shoulder shelves, flat 3.2 m under the
## surface, from FishingVillagePlan (so the shelf here is the one the plan
## validator tests piles against).
##
## Revised 2026-10-07 after the walkthrough ("one big pillar... a giant column
## in the sky... not the Thai-inspired islands"). Each islet is now a cluster of
## tower-karst lobes after Phang Nga: steep, near-vertical faces that round over
## into domed, forested crowns of different heights, Anvil Rock to about 21 m
## and Heron Rock to about 13 m. The faces carry runnel streaks (orange iron and
## black algae, which run straight down, so they are coloured by plan position
## alone) and a dark notch band at the waterline; trees crown the domes and
## vines hang over their lips. Beyond the shelf the ground falls away as a slope
## rather than a one-cell cliff, so the edge does not read as stair steps.
##
## Natural landforms are meshes, not SuperEgg props; the trees and vines on
## them are SuperEgg foliage. A heightfield cannot overhang, so the undercut
## notch is carried by the colour band.

## Shelf top, below the lake surface W: inside the plan's 2.5 to 4.0 m band.
const SHELF_TOP_DEPTH := 3.2
## How far below the lake bed the mesh outside the shelves is sunk, so it hides.
const BED_SINK := 4.0
## Beyond the shelf's edge the ground falls at this gradient to the bed: a
## steep talus, as the submerged shoulders of tower karst drop away.
const SHELF_FALL := 3.5
## Over this band inside the mesh's outer edge the ground is drawn down to
## the bed, so the sheet's edge is buried and nothing can swim beneath it.
const EDGE_BAND := 8.0
const CELL := 0.5
const BOUNDS := Rect2(-50.0, -44.0, 100.0, 76.0)
const SEED := 20261006

## The towers: plan centre, plan radii and crown height above W. Each lobe's
## footprint lies inside its islet's outline in FishingVillagePlan, and every
## lobe keeps clear of the buildings at its foot (the cistern's tank, the catch
## deck, the portal spur), which the building proofs check.
const LOBES: Array[Dictionary] = [
	{"c": Vector2(-14.0, -31.0), "r": Vector2(6.5, 7.0), "top": 15.0},
	{"c": Vector2(-4.0, -31.0), "r": Vector2(8.5, 8.0), "top": 21.0},
	{"c": Vector2(7.0, -31.5), "r": Vector2(7.0, 6.5), "top": 17.0},
	{"c": Vector2(15.0, -30.0), "r": Vector2(4.0, 4.5), "top": 10.0},
	{"c": Vector2(-3.0, -24.8), "r": Vector2(5.5, 4.2), "top": 9.0},
	{"c": Vector2(30.5, 10.5), "r": Vector2(4.8, 4.2), "top": 13.0},
	{"c": Vector2(26.8, 8.2), "r": Vector2(2.8, 2.6), "top": 8.0},
]

const LIMESTONE := Color(0.80, 0.78, 0.71)
const LIMESTONE_WEATHERED := Color(0.66, 0.64, 0.58)
const STREAK_IRON := Color(0.72, 0.54, 0.36)
const STREAK_DARK := Color(0.30, 0.31, 0.29)
const WATERLINE_STAIN := Color(0.18, 0.19, 0.16)
const SHELF_ROCK := Color(0.45, 0.43, 0.37)
const MOSS := Color(0.30, 0.44, 0.22)
const FOREST := Color(0.20, 0.36, 0.16)

static var _edge_noise: FastNoiseLite
static var _rock_noise: FastNoiseLite
static var _grain_noise: FastNoiseLite


## Builds the islets under `parent`; returns the single body. `terrain` supplies
## the lake level and the bed.
static func build(parent: Node3D, terrain: Node) -> Array[StaticBody3D]:
	_make_noise()
	var water := float(terrain.get_lake_water_level())
	var columns := int(BOUNDS.size.x / CELL) + 1
	var rows := int(BOUNDS.size.y / CELL) + 1
	var heights := PackedFloat32Array()
	heights.resize(columns * rows)
	for row in rows:
		for column in columns:
			var local := BOUNDS.position + Vector2(column, row) * CELL
			heights[row * columns + column] = _height(local, terrain, water)
	var arrays := _mesh_arrays(heights, columns, rows)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var body := StaticBody3D.new()
	body.name = "FishingIslets"
	# Ground, not a ramp: on BLORB_CLIMBABLE_LAYER the player's swim code took
	# the shelf under every dock for a climbable ramp, stopped swimming and
	# walked the shelf with no breath. Blorbs treat any layer-1 body as ground.
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	body.global_position = Vector3(FishingVillagePlan.WORLD_CENTER.x, water, FishingVillagePlan.WORLD_CENTER.y)
	var instance := MeshInstance3D.new()
	instance.name = "IsletMesh"
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.92
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	body.add_child(instance)
	var shape := ConcavePolygonShape3D.new()
	# Collision in a trimesh needs the backface flag, or a character that tunnels
	# into a sheer face is not pushed back out.
	shape.backface_collision = true
	shape.set_faces(_faces(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array, arrays[Mesh.ARRAY_INDEX] as PackedInt32Array))
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	instance.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	_vegetation(body, heights, columns, rows)
	var out: Array[StaticBody3D] = [body]
	return out


static func _make_noise() -> void:
	_edge_noise = FastNoiseLite.new()
	_edge_noise.seed = SEED
	_edge_noise.frequency = 0.35
	_rock_noise = FastNoiseLite.new()
	_rock_noise.seed = SEED + 1
	_rock_noise.frequency = 0.1
	_rock_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_rock_noise.fractal_octaves = 4
	_grain_noise = FastNoiseLite.new()
	_grain_noise.seed = SEED + 2
	_grain_noise.frequency = 0.55


## Height of the islet ground at a plan point, relative to the lake surface W.
static func _height(p: Vector2, terrain: Node, water: float) -> float:
	# The shelf's edge wanders outward (never inward, so every pile the plan places
	# on the shelf stands on it), then the ground falls away as a slope.
	var edge := (_edge_noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5) * 1.5
	var height := -SHELF_TOP_DEPTH + _grain_noise.get_noise_2d(p.x, p.y) * 0.1
	var beyond := FishingVillagePlan.shelf_distance(p) - edge
	if beyond > 0.0:
		var at := FishingVillagePlan.WORLD_CENTER + p
		var bed := float(terrain.get_mesh_height(at.x, at.y)) - water - BED_SINK
		height = maxf(bed, -SHELF_TOP_DEPTH - beyond * SHELF_FALL)
		var to_edge := minf(minf(p.x - BOUNDS.position.x, BOUNDS.end.x - p.x), minf(p.y - BOUNDS.position.y, BOUNDS.end.y - p.y))
		if to_edge < EDGE_BAND:
			height = lerpf(bed, height, clampf(to_edge / EDGE_BAND, 0.0, 1.0))
	for lobe: Dictionary in LOBES:
		height = maxf(height, _lobe_height(p, lobe))
	return height


## One karst tower: a superellipse dome, near vertical at its foot and rounding
## over into a broad crown, its outline lobed by low-frequency noise and its
## face lightly fluted.
static func _lobe_height(p: Vector2, lobe: Dictionary) -> float:
	var q := (p - (lobe["c"] as Vector2)) / (lobe["r"] as Vector2)
	var d := q.length()
	d *= 1.0 + _rock_noise.get_noise_2d(p.x * 0.7, p.y * 0.7) * 0.12
	if d >= 1.0:
		return -INF
	var top := float(lobe["top"]) + _rock_noise.get_noise_2d(p.x * 1.6 + 30.0, p.y * 1.6) * 1.2
	# (1 - d^6)^(1/3): flat-ish crown, rounded shoulder, steep wall.
	var profile := pow(1.0 - pow(d, 6.0), 1.0 / 3.0)
	var height := -SHELF_TOP_DEPTH + (top + SHELF_TOP_DEPTH) * profile
	var face := clampf((1.0 - profile) * 3.0, 0.0, 1.0) * clampf(profile * 4.0, 0.0, 1.0)
	height += _grain_noise.get_noise_2d(p.x * 2.5, p.y * 2.5) * 0.45 * face
	# Ledges: soil steps in the face of the taller towers, where the karst's
	# dragon trees, cycads and ferns root. Heights near each ledge are pressed
	# together, so the face flattens into a narrow shelf there.
	if float(lobe["top"]) > 9.0:
		for fraction: float in [0.38, 0.68]:
			var ledge := float(lobe["top"]) * fraction + _rock_noise.get_noise_2d(p.x * 0.5 + 9.0, p.y * 0.5) * 0.8
			if absf(height - ledge) < 1.5:
				height = ledge + (height - ledge) * 0.3
	return height


## Positions, vertex colours, normals and indices for the heightfield.
static func _mesh_arrays(heights: PackedFloat32Array, columns: int, rows: int) -> Array:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	vertices.resize(columns * rows)
	normals.resize(columns * rows)
	colors.resize(columns * rows)
	for row in rows:
		for column in columns:
			var index := row * columns + column
			vertices[index] = Vector3(
				BOUNDS.position.x + float(column) * CELL, heights[index], BOUNDS.position.y + float(row) * CELL
			)
	# The same triangle split as the world terrain (a, c, b / b, c, d).
	for row in rows - 1:
		for column in columns - 1:
			var a := row * columns + column
			var b := a + 1
			var c := a + columns
			var d := c + 1
			for tri: Array in [[a, c, b], [b, c, d]]:
				var i0: int = tri[0]
				var i1: int = tri[1]
				var i2: int = tri[2]
				indices.append(i0)
				indices.append(i1)
				indices.append(i2)
				var normal := (vertices[i1] - vertices[i0]).cross(vertices[i2] - vertices[i0])
				normals[i0] += normal
				normals[i1] += normal
				normals[i2] += normal
	for index in normals.size():
		normals[index] = normals[index].normalized() if normals[index].length() > 0.0 else Vector3.UP
		colors[index] = _color(vertices[index], normals[index])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


static func _color(vertex: Vector3, normal: Vector3) -> Color:
	var height := vertex.y
	if height < -SHELF_TOP_DEPTH - 0.2:
		return SHELF_ROCK.darkened(0.2)
	if height < -0.6:
		return SHELF_ROCK
	var steep := 1.0 - clampf(normal.y, 0.0, 1.0)
	var color := LIMESTONE.lerp(LIMESTONE_WEATHERED, clampf(steep * 0.8, 0.0, 1.0))
	# Runnels: streaks that run straight down the face, so plan position alone.
	# Wide, strong runnels: Phang Nga's towers are banded orange with iron and
	# black with algae down every face.
	var streak := _grain_noise.get_noise_2d(vertex.x * 1.3, vertex.z * 1.3)
	var band := _rock_noise.get_noise_2d(vertex.x * 0.6 + 70.0, vertex.z * 0.6)
	if streak > 0.05:
		color = color.lerp(STREAK_DARK if band > 0.05 else STREAK_IRON, clampf((streak - 0.05) * 2.6, 0.0, 0.85) * clampf(steep * 1.4, 0.0, 1.0))
	# The crowns and any level ledge carry moss and forest.
	if normal.y > 0.7 and height > 2.0:
		color = color.lerp(FOREST if height > 6.0 else MOSS, clampf((normal.y - 0.7) * 4.0, 0.0, 0.9))
	# The notch: a dark band where the lake has eaten into the foot.
	var notch := 1.0 - smoothstep(0.2, 2.2, height)
	return color.lerp(WATERLINE_STAIN, clampf(notch, 0.0, 1.0))


## The karst's planting, by zone (see the landscaping skill's
## southeast_asian_karst_flora.md): low forest on the crowns with dragon trees
## standing above it; clumps of dragon trees, cycads and ferns on the ledges;
## fig roots and lianas hanging down the faces from ledge and crown lips;
## ferns in the waterline notch; moss and ferns at the cistern's seep. Every
## part is a shared SuperEgg mesh drawn through one MultiMesh, decorative
## (the rock's own collision is what anyone stands on).
static func _vegetation(body: StaticBody3D, heights: PackedFloat32Array, columns: int, rows: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 7
	var parts := {}
	var stride := int(1.0 / CELL)
	for row in range(6, rows - 6, stride):
		for column in range(6, columns - 6, stride):
			var h := heights[row * columns + column]
			if h < 0.3:
				continue
			var p := BOUNDS.position + Vector2(column, row) * CELL
			var dx := heights[row * columns + column + 1] - heights[row * columns + column - 1]
			var dz := heights[(row + 1) * columns + column] - heights[(row - 1) * columns + column]
			var gradient := Vector2(dx, dz) / (2.0 * CELL)
			var slope := gradient.length()
			# The highest ground within three metres: is this a crown or a step?
			var above := h
			for oy in range(-6, 7, 3):
				for ox in range(-6, 7, 3):
					above = maxf(above, heights[(row + oy) * columns + column + ox])
			var downhill := -gradient.normalized() if slope > 0.01 else Vector2.ZERO
			var at := Vector3(p.x, h, p.y)
			if slope < 0.9 and h > 3.0 and above < h + 1.5:
				# Crown.
				if rng.randf() < 0.55:
					var size := rng.randf_range(1.0, 1.9)
					var crown := Vector2(p.x + rng.randf_range(-0.5, 0.5), p.y + rng.randf_range(-0.5, 0.5))
					var crown_y := _ground(heights, columns, rows, crown)
					_add(parts, "canopy", Transform3D(Basis().scaled(Vector3(size, size * rng.randf_range(0.65, 0.9), size)), Vector3(crown.x, crown_y + size * 0.4, crown.y)), FOREST.lerp(MOSS, rng.randf_range(0.0, 0.6)).darkened(rng.randf_range(0.0, 0.15)))
				elif rng.randf() < 0.18:
					_dragon_tree(parts, at, rng.randf_range(3.0, 4.5), rng)
			elif slope < 1.6 and h > 2.0 and above > h + 2.0:
				# Ledge: a clump of three to five.
				if rng.randf() < 0.3:
					var count := rng.randi_range(3, 5)
					for i in count:
						# Each plant stands on the ground where it is, and only
						# where that ground is the ledge's step, not the face.
						var plan := Vector2(p.x + rng.randf_range(-0.9, 0.9), p.y + rng.randf_range(-0.9, 0.9))
						if _slope(heights, columns, rows, plan) > 1.6:
							continue
						var spot := Vector3(plan.x, _ground(heights, columns, rows, plan) - 0.05, plan.y)
						var pick := rng.randf()
						if pick < 0.4:
							_dragon_tree(parts, spot, rng.randf_range(1.6, 3.0), rng)
						elif pick < 0.75:
							_cycad(parts, spot, rng)
						else:
							_fern(parts, spot, 1.0, rng)
			elif slope > 2.5 and h > 3.0:
				# Faces: fig roots and lianas hanging down the rock.
				if rng.randf() < 0.07:
					var length := rng.randf_range(2.5, minf(9.0, h))
					# They lie down the face, not hanging plumb in front of it: a
					# plumb strand floats at its top and cuts into the rock below.
					var down := Vector3(downhill.x, -slope, downhill.y).normalized()
					var normal := Vector3(downhill.x * slope, 1.0, downhill.y * slope).normalized()
					var across := Vector3(-downhill.y, 0.0, downhill.x)
					if rng.randf() < 0.5:
						for strand in 3:
							var strand_length := length * (0.8 + 0.1 * float(strand))
							var start := at + across * (float(strand) - 1.0) * 0.18 + normal * 0.05
							_add(parts, "root", Transform3D(_basis_along(down).scaled(Vector3(0.09, strand_length, 0.05)), start + down * strand_length * 0.5), Color(0.55, 0.47, 0.38).darkened(0.05 * float(strand)))
					else:
						_add(parts, "liana", Transform3D(_basis_along(down).scaled(Vector3(0.16, length, 0.16)), at + normal * 0.09 + down * length * 0.5), MOSS.darkened(rng.randf_range(0.0, 0.25)))
			elif h < 1.6 and slope > 2.0 and rng.randf() < 0.05:
				# The notch: a fern tucked into the wet overhang.
				_fern(parts, at + Vector3(downhill.x, 0.0, downhill.y) * 0.2, 0.7, rng)
	# The seep behind the cistern: wet moss and ferns at the rock's foot.
	# Each is set into the face: walk north from the cistern toward the rock
	# until the ground reaches the fern's height.
	for i in 9:
		var x := -1.5 + rng.randf_range(-2.2, 2.2)
		var y := 0.3 + rng.randf_range(0.0, 1.6)
		var z := -18.0
		while z > -26.0 and _ground(heights, columns, rows, Vector2(x, z)) < y:
			z -= 0.1
		_fern(parts, Vector3(x, y, z + 0.08), rng.randf_range(0.6, 1.0), rng)
	# Sampled for what each part is: a strap leaf or fern blade is a thin
	# sliver drawn thousands of times, so a handful of rings and segments; at
	# full SuperEgg detail the leaves alone were three million triangles.
	var meshes := {
		"canopy": SuperEgg.build_mesh(Vector3(1.0, 1.0, 1.0), 2.2, 2.6, 10, 14),
		"trunk": SuperEgg.build_mesh(Vector3(1.0, 0.5, 1.0), 3.0, 3.0, 6, 8),
		"blade": SuperEgg.build_mesh(Vector3(0.05, 0.5, 0.012), 2.4, 2.4, 6, 4),
		"frond": SuperEgg.build_mesh(Vector3(0.12, 0.5, 0.015), 2.4, 2.4, 6, 4),
		"fern": SuperEgg.build_mesh(Vector3(0.11, 0.5, 0.02), 2.2, 2.2, 6, 4),
		"root": SuperEgg.build_mesh(Vector3(1.0, 0.5, 1.0), 2.0, 2.0, 6, 6),
		"liana": SuperEgg.build_mesh(Vector3(1.0, 0.5, 1.0), 2.0, 2.0, 6, 6),
	}
	for key: String in parts:
		var entries: Array = parts[key]
		var transforms: Array[Transform3D] = []
		var tones: Array[Color] = []
		for entry: Array in entries:
			transforms.append(entry[0])
			tones.append(entry[1])
		_foliage(body, key.capitalize(), meshes[key], transforms, tones)


## The ground height at plan point `p`, interpolated from the heightfield.
static func _ground(heights: PackedFloat32Array, columns: int, rows: int, p: Vector2) -> float:
	var g := (p - BOUNDS.position) / CELL
	var c := clampi(int(floor(g.x)), 0, columns - 2)
	var r := clampi(int(floor(g.y)), 0, rows - 2)
	var fx := clampf(g.x - float(c), 0.0, 1.0)
	var fz := clampf(g.y - float(r), 0.0, 1.0)
	var top := lerpf(heights[r * columns + c], heights[r * columns + c + 1], fx)
	var bottom := lerpf(heights[(r + 1) * columns + c], heights[(r + 1) * columns + c + 1], fx)
	return lerpf(top, bottom, fz)


## The ground's gradient magnitude at `p` (rise per metre).
static func _slope(heights: PackedFloat32Array, columns: int, rows: int, p: Vector2) -> float:
	var dx := _ground(heights, columns, rows, p + Vector2(CELL, 0)) - _ground(heights, columns, rows, p - Vector2(CELL, 0))
	var dz := _ground(heights, columns, rows, p + Vector2(0, CELL)) - _ground(heights, columns, rows, p - Vector2(0, CELL))
	return Vector2(dx, dz).length() / (2.0 * CELL)


static func _add(parts: Dictionary, key: String, xform: Transform3D, tone: Color) -> void:
	if not parts.has(key):
		parts[key] = []
	(parts[key] as Array).append([xform, tone])


## A dragon tree: a grey trunk forking into two or three candelabra branches,
## each tipped with a tuft of stiff strap leaves.
static func _dragon_tree(parts: Dictionary, at: Vector3, height: float, rng: RandomNumberGenerator) -> void:
	var trunk_h := height * 0.55
	var bark := Color(0.58, 0.56, 0.52).darkened(rng.randf_range(0.0, 0.12))
	_add(parts, "trunk", Transform3D(Basis().scaled(Vector3(0.14, trunk_h, 0.14)), at + Vector3(0.0, trunk_h * 0.5, 0.0)), bark)
	var fork := at + Vector3(0.0, trunk_h, 0.0)
	var branches := rng.randi_range(2, 3)
	for b in branches:
		var angle := TAU * float(b) / float(branches) + rng.randf_range(-0.4, 0.4)
		var lean := rng.randf_range(0.35, 0.6)
		var length := height * rng.randf_range(0.35, 0.5)
		var axis := Vector3(cos(angle) * sin(lean), cos(lean), sin(angle) * sin(lean))
		var basis := _basis_along(axis).scaled(Vector3(0.09, length, 0.09))
		_add(parts, "trunk", Transform3D(basis, fork + axis * length * 0.5), bark.lightened(0.05))
		var tip := fork + axis * length
		var leaf := Color(0.36, 0.50, 0.30).lerp(Color(0.48, 0.56, 0.36), rng.randf())
		for blade in 9:
			var blade_angle := TAU * float(blade) / 9.0 + rng.randf_range(-0.2, 0.2)
			var spread := rng.randf_range(0.25, 0.9)
			var dir := Vector3(cos(blade_angle) * sin(spread), cos(spread), sin(blade_angle) * sin(spread))
			_add(parts, "blade", Transform3D(_basis_along(dir).scaled(Vector3(1.0, 0.75, 1.0)), tip + dir * 0.36), leaf)


## A cycad: a short stout trunk under a crown of arching fronds.
static func _cycad(parts: Dictionary, at: Vector3, rng: RandomNumberGenerator) -> void:
	var trunk_h := rng.randf_range(0.4, 1.1)
	_add(parts, "trunk", Transform3D(Basis().scaled(Vector3(0.18, trunk_h, 0.18)), at + Vector3(0.0, trunk_h * 0.5, 0.0)), Color(0.40, 0.33, 0.25))
	var top := at + Vector3(0.0, trunk_h, 0.0)
	for frond in 10:
		var angle := TAU * float(frond) / 10.0 + rng.randf_range(-0.15, 0.15)
		var spread := rng.randf_range(0.9, 1.25)
		var dir := Vector3(cos(angle) * sin(spread), cos(spread), sin(angle) * sin(spread))
		_add(parts, "frond", Transform3D(_basis_along(dir).scaled(Vector3(1.0, 1.3, 1.0)), top + dir * 0.62), Color(0.24, 0.42, 0.20).lightened(rng.randf_range(0.0, 0.1)))


## A bird's-nest fern: a vase of broad bright leaves.
static func _fern(parts: Dictionary, at: Vector3, size: float, rng: RandomNumberGenerator) -> void:
	for leaf in 8:
		var angle := TAU * float(leaf) / 8.0 + rng.randf_range(-0.2, 0.2)
		var spread := rng.randf_range(0.45, 0.75)
		var dir := Vector3(cos(angle) * sin(spread), cos(spread), sin(angle) * sin(spread))
		_add(parts, "fern", Transform3D(_basis_along(dir).scaled(Vector3(size, size * 0.9, size)), at + dir * 0.4 * size), Color(0.42, 0.62, 0.24).darkened(rng.randf_range(0.0, 0.12)))


## A basis whose local y runs along `axis`.
static func _basis_along(axis: Vector3) -> Basis:
	var y := axis.normalized()
	var helper := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := helper.cross(y).normalized()
	return Basis(x, y, x.cross(y))


static func _foliage(body: StaticBody3D, name_text: String, mesh: Mesh, transforms: Array[Transform3D], tones: Array[Color]) -> void:
	if transforms.is_empty():
		return
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	multi.mesh = mesh
	multi.instance_count = transforms.size()
	for i in transforms.size():
		multi.set_instance_transform(i, transforms[i])
		multi.set_instance_color(i, tones[i])
	var instance := MultiMeshInstance3D.new()
	instance.name = name_text
	instance.multimesh = multi
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	instance.material_override = material
	body.add_child(instance)
	CollisionPolicy.mark_decorative(instance)


static func _faces(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var faces := PackedVector3Array()
	faces.resize(indices.size())
	for i in indices.size():
		faces[i] = vertices[indices[i]]
	return faces
