class_name FishingIslets
extends RefCounted

## Anvil Rock and Heron Rock, the two limestone islets the Crossroads Fishing
## Village stands against (docs/architecture/fishing_village_layout.md, section
## 2), built as one terrain-grade mesh: a heightfield on a 1 m grid, the same
## method as the world terrain but sixteen times finer than its 18 m cells, with
## trimesh collision. It carries both rock stacks (karst: sheer fluted faces, a
## weathered waterline band, a broad crown) and their submerged shoulder shelves,
## flat 3.2 m under the surface, beyond which the ground drops to the lake bed.
## Every extent comes from FishingVillagePlan, so the shelf outline here is the
## one the plan validator tests piles against.
##
## These are natural landforms, so they are not SuperEgg props. A heightfield
## cannot overhang; the undercut karst notch at the waterline is carried by the
## waterline stain and the sheer face, not by geometry.

## Shelf top, below the lake surface W: inside the plan's 2.5 to 4.0 m band.
const SHELF_TOP_DEPTH := 3.2
## How far below the lake bed the mesh outside the shelves is sunk, so it hides.
const BED_SINK := 4.0
const CELL := 1.0
const BOUNDS := Rect2(-50.0, -44.0, 100.0, 76.0)
const SEED := 20261006

const LIMESTONE := Color(0.78, 0.75, 0.68)
const LIMESTONE_WEATHERED := Color(0.60, 0.58, 0.52)
const WATERLINE_STAIN := Color(0.46, 0.47, 0.40)
const SHELF_ROCK := Color(0.42, 0.40, 0.36)
const MOSS := Color(0.34, 0.45, 0.24)

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
	body.collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
	body.collision_mask = 0
	parent.add_child(body)
	body.global_position = Vector3(FishingVillagePlan.WORLD_CENTER.x, water, FishingVillagePlan.WORLD_CENTER.y)
	var instance := MeshInstance3D.new()
	instance.name = "IsletMesh"
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
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
	# on the shelf stands on it).
	var edge := (_edge_noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5) * 2.0
	if FishingVillagePlan.shelf_distance(p) > edge:
		var at := FishingVillagePlan.WORLD_CENTER + p
		return float(terrain.get_mesh_height(at.x, at.y)) - water - BED_SINK
	var height := -SHELF_TOP_DEPTH + _grain_noise.get_noise_2d(p.x, p.y) * 0.1
	height = maxf(height, _rock_height(p, FishingVillagePlan.ANVIL_ROCK))
	height = maxf(height, _rock_height(p, FishingVillagePlan.HERON_ROCK))
	return height


## One rock stack rising from its shelf: a sheer, fluted face between the waterline
## and a broad crown, its outline lobed by low-frequency noise.
static func _rock_height(p: Vector2, rock: Dictionary) -> float:
	var centre: Vector2 = rock["center"]
	var half: Vector2 = rock["half"]
	var crown: float = rock["crown"]
	var q := (p - centre) / half
	var d := q.length()
	d += _rock_noise.get_noise_2d(p.x, p.y) * 0.16
	d += _grain_noise.get_noise_2d(p.x * 1.4 + 40.0, p.y * 1.4) * 0.03
	var t := 1.0 - smoothstep(0.74, 1.02, d)
	if t <= 0.0:
		return -INF
	# A steeper face than the smoothstep alone gives.
	t = smoothstep(0.0, 1.0, clampf(t * 1.7, 0.0, 1.0))
	var top := crown + _rock_noise.get_noise_2d(p.x * 3.0, p.y * 3.0) * 0.5
	var height := -SHELF_TOP_DEPTH + (top + SHELF_TOP_DEPTH) * t
	# Strata ribs and vertical fluting on the face.
	var face := t * (1.0 - t) * 4.0
	height += sin(height * 1.3 + _rock_noise.get_noise_2d(p.x * 2.0, p.y * 2.0) * 4.0) * 0.35 * face
	height += _grain_noise.get_noise_2d(p.x * 2.2, p.y * 0.4) * 0.9 * face
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
		colors[index] = _color(vertices[index].y, normals[index])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays


static func _color(height: float, normal: Vector3) -> Color:
	if height < -SHELF_TOP_DEPTH - 0.2:
		return SHELF_ROCK.darkened(0.15)
	if height < -0.4:
		return SHELF_ROCK
	var steep := 1.0 - clampf(normal.y, 0.0, 1.0)
	var color := LIMESTONE.lerp(LIMESTONE_WEATHERED, clampf(steep * 1.4, 0.0, 1.0))
	# Moss and grass hold only on level ledges and the crown, never on the face.
	if normal.y > 0.88 and height > 2.0:
		color = color.lerp(MOSS, 0.6)
	# The lake stains the foot: a darker band from just under the surface to a
	# little above it.
	var band := 1.0 - smoothstep(-0.4, 1.8, height)
	return color.lerp(WATERLINE_STAIN, clampf(band, 0.0, 1.0))


static func _faces(vertices: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var faces := PackedVector3Array()
	faces.resize(indices.size())
	for i in indices.size():
		faces[i] = vertices[indices[i]]
	return faces
