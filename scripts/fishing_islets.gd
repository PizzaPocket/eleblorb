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
## Beyond the shelf's edge the ground falls at this gradient to the bed.
const SHELF_FALL := 1.6
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
const WATERLINE_STAIN := Color(0.30, 0.31, 0.27)
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
	var streak := _grain_noise.get_noise_2d(vertex.x * 3.0, vertex.z * 3.0)
	var band := _rock_noise.get_noise_2d(vertex.x * 0.9 + 70.0, vertex.z * 0.9)
	if streak > 0.25:
		color = color.lerp(STREAK_DARK if band > 0.0 else STREAK_IRON, clampf((streak - 0.25) * 2.2, 0.0, 0.7) * steep)
	# The crowns and any level ledge carry moss and forest.
	if normal.y > 0.7 and height > 2.0:
		color = color.lerp(FOREST if height > 6.0 else MOSS, clampf((normal.y - 0.7) * 4.0, 0.0, 0.9))
	# The notch: a dark band where the lake has eaten into the foot.
	var notch := 1.0 - smoothstep(-0.6, 1.4, height)
	return color.lerp(WATERLINE_STAIN, clampf(notch, 0.0, 1.0))


## Trees on the domes and vines over their lips, as two MultiMeshes of SuperEgg
## foliage (decorative: the rock's own collision is the crown).
static func _vegetation(body: StaticBody3D, heights: PackedFloat32Array, columns: int, rows: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED + 7
	var crowns: Array[Transform3D] = []
	var crown_tones: Array[Color] = []
	var vines: Array[Transform3D] = []
	var stride := int(2.0 / CELL)
	for row in range(1, rows - 1, stride):
		for column in range(1, columns - 1, stride):
			var h := heights[row * columns + column]
			if h < 3.0:
				continue
			var p := BOUNDS.position + Vector2(column, row) * CELL
			var dx := heights[row * columns + column + 1] - heights[row * columns + column - 1]
			var dz := heights[(row + 1) * columns + column] - heights[(row - 1) * columns + column]
			var slope := Vector2(dx, dz).length() / (2.0 * CELL)
			var jitter := Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8))
			if slope < 0.9 and rng.randf() < 0.85:
				var size := rng.randf_range(1.1, 2.0)
				crowns.append(Transform3D(Basis().scaled(Vector3(size, size * rng.randf_range(0.7, 1.0), size)), Vector3(p.x + jitter.x, h + size * 0.45, p.y + jitter.y)))
				crown_tones.append(FOREST.lerp(MOSS, rng.randf_range(0.0, 0.7)).darkened(rng.randf_range(0.0, 0.15)))
			elif slope > 2.5 and h > 5.0 and rng.randf() < 0.35:
				var length := rng.randf_range(2.0, minf(6.0, h - 1.0))
				vines.append(Transform3D(Basis().scaled(Vector3(0.12, length, 0.12)), Vector3(p.x + jitter.x * 0.3, h - length * 0.5, p.y + jitter.y * 0.3)))
	_foliage(body, "Treetops", SuperEgg.build_mesh(Vector3(1.0, 1.0, 1.0), 2.2, 2.6), crowns, crown_tones)
	var vine_tones: Array[Color] = []
	for i in vines.size():
		vine_tones.append(MOSS.darkened(0.1 * float(i % 3)))
	_foliage(body, "Vines", SuperEgg.build_mesh(Vector3(1.0, 0.5, 1.0), 2.0, 2.0), vines, vine_tones)


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
