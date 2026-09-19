class_name NaturalLake
extends RefCounted

## A natural lake punched into a heightfield, in the game's established way:
## the Ice Kingdom's organic shoreline, bank shelf and basin carve (see
## ice_kingdom_terrain.gd's _lake_coverage()/_lake_edge_radius()/
## _terrain_height()), with either an open water sheet (the Crossroads lake's
## opaque water colour) or the Ice Kingdom's frozen surface: a solid ice sheet
## with an ice edge wall, over water.
##
## `stretch` elongates the lake along world X (a long lake running down a
## valley): its shape is computed in a space where X is divided by stretch.
##
## A terrain owns one of these per lake, folds carve() into its height
## function, and calls build_water()/build_frozen() once its own mesh exists.
## Both surfaces extend SURFACE_OVERLAP beneath the bank, so interpolated
## terrain can never expose a dry crescent between the shore and the surface.

## Width of the shore's feathered descent inside the organic edge.
const SHORE_FEATHER := 18.0
## Width of the bank that slopes surrounding ground down to the shelf.
const BANK_WIDTH := 24.0
const SURFACE_OVERLAP := 16.0
const SURFACE_SEGMENTS := 72
const SURFACE_RINGS := 20
const ICE_COLOR := Color(0.68, 0.87, 0.96, 0.84)
const ICE_EDGE_COLOR := Color(0.56, 0.78, 0.9, 0.9)
const UNDER_ICE_WATER_COLOR := Color(0.16, 0.42, 0.62, 0.68)

var center: Vector2
var radius: float
var edge_variation: float
var depth: float
## Height the bank descends to at the waterline: the ice level for a frozen
## lake, just above the water for an open one (a narrow beach).
var shelf_level: float
var stretch := 1.0
var _noise := FastNoiseLite.new()


func _init(
	lake_center: Vector2, lake_radius: float, lake_edge_variation: float,
	lake_depth: float, lake_shelf_level: float, noise_seed: int, lake_stretch: float = 1.0
) -> void:
	stretch = lake_stretch
	center = lake_center
	radius = lake_radius
	edge_variation = lake_edge_variation
	depth = lake_depth
	shelf_level = lake_shelf_level
	_noise.seed = noise_seed
	_noise.frequency = 0.011
	_noise.fractal_octaves = 4


## The shoreline's distance from the centre in the direction of `relative`:
## coherent noise plus two low harmonics bend it in and out, so the edge never
## reads as a circle.
func edge_radius(relative: Vector2) -> float:
	if relative.length_squared() < 0.001:
		return radius
	var angle := atan2(relative.y, relative.x)
	var organic := _noise.get_noise_2d(cos(angle) * 93.0 + 410.0, sin(angle) * 93.0 - 280.0)
	organic += sin(angle * 3.0 + 0.7) * 0.34 + sin(angle * 5.0 - 1.1) * 0.18
	return radius + organic * edge_variation


## `pos` relative to the centre, in the unstretched space the shape lives in.
func _local(pos: Vector2) -> Vector2:
	return Vector2((pos.x - center.x) / stretch, pos.y - center.y)


## Back from the unstretched shape space to world XZ.
func _world(local: Vector2) -> Vector2:
	return center + Vector2(local.x * stretch, local.y)


## 0 outside the lake, rising to 1 across SHORE_FEATHER inside its edge.
func coverage(pos: Vector2) -> float:
	var local := _local(pos)
	var edge := edge_radius(local)
	return 1.0 - smoothstep(edge - SHORE_FEATHER, edge, local.length())


## Folds the lake into a terrain height: surrounding ground banks down to the
## shelf, then the basin deepens toward the middle.
func carve(ground_height: float, pos: Vector2) -> float:
	var bank := 1.0 - smoothstep(radius, radius + BANK_WIDTH, _local(pos).length())
	var banked := lerpf(ground_height, shelf_level, bank)
	var lake := coverage(pos)
	return lerpf(banked, shelf_level - depth * lake, lake)


## Distance from the centre in the lake's own (unstretched) shape space:
## compare with radius, radius + BANK_WIDTH and so on for rings that follow a
## stretched lake's outline.
func local_distance(pos: Vector2) -> float:
	return _local(pos).length()


## The world point at `angle` on the ring `local_radius` from the centre, in
## shape space: a stretched lake's rings are ellipses along X.
func point_on_ring(angle: float, local_radius: float) -> Vector2:
	return _world(Vector2(cos(angle), sin(angle)) * local_radius)


## True where the surface layers are drawn (the edge plus its overlap).
func is_within_surface(pos: Vector2) -> bool:
	var local := _local(pos)
	return local.length() <= edge_radius(local) + SURFACE_OVERLAP


## An open lake: a non-solid water sheet in the Crossroads lake's opaque water
## colour. Swimming is a gameplay query, not a collider.
func build_water(parent: Node3D, level: float) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(TownProps.WATER_COLOR.r, TownProps.WATER_COLOR.g, TownProps.WATER_COLOR.b, 1.0)
	material.roughness = 0.05
	material.metallic = 0.15
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	build_surface(parent, "LakeWater", level, material)


## Any non-solid liquid sheet over the basin (water, or a lava pool's lava),
## following the organic edge and tucked under the bank like the water.
func build_surface(parent: Node3D, label: String, level: float, material: Material) -> void:
	parent.add_child(_surface_mesh(label, _disc_triangles(level), material))


## A frozen lake, as in the Ice Kingdom: a solid, walkable ice sheet at
## `ice_surface_level` with a visible edge wall `thickness` deep, and the
## water beneath it at `water_level`.
func build_frozen(parent: StaticBody3D, ice_surface_level: float, thickness: float, water_level: float) -> void:
	var ice := StandardMaterial3D.new()
	ice.albedo_color = ICE_COLOR
	ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ice.roughness = 0.12
	ice.metallic = 0.12
	ice.cull_mode = BaseMaterial3D.CULL_DISABLED
	var ice_triangles := _disc_triangles(ice_surface_level)
	parent.add_child(_surface_mesh("FrozenLakeIce", ice_triangles, ice))
	_add_collider(parent, ice_triangles)
	_build_ice_edge_wall(parent, ice_surface_level, thickness)
	var water := StandardMaterial3D.new()
	water.albedo_color = UNDER_ICE_WATER_COLOR
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.12
	water.metallic = 0.12
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	parent.add_child(_surface_mesh("FrozenLakeWater", _disc_triangles(water_level), water))


## Concentric rings following the organic edge (plus overlap), as a flat
## triangle list at height `y`, clockwise from above (Godot's front face) so
## faces agree with their upward normals. Shared by the visible mesh and, for ice, its collider.
func _disc_triangles(y: float) -> PackedVector3Array:
	var triangles := PackedVector3Array()
	for ring in SURFACE_RINGS:
		var inner := float(ring) / float(SURFACE_RINGS)
		var outer := float(ring + 1) / float(SURFACE_RINGS)
		for index in SURFACE_SEGMENTS:
			var a0 := TAU * float(index) / float(SURFACE_SEGMENTS)
			var a1 := TAU * float(index + 1) / float(SURFACE_SEGMENTS)
			var d0 := Vector2(cos(a0), sin(a0))
			var d1 := Vector2(cos(a1), sin(a1))
			var edge0 := edge_radius(d0) + SURFACE_OVERLAP
			var edge1 := edge_radius(d1) + SURFACE_OVERLAP
			var quad: Array[Vector2] = [d0 * edge0 * inner, d1 * edge1 * inner, d0 * edge0 * outer, d1 * edge1 * outer]
			for corner in [0, 2, 1, 1, 2, 3]:
				var world := _world(quad[corner])
				triangles.append(Vector3(world.x, y, world.y))
	return triangles


func _surface_mesh(label: String, triangles: PackedVector3Array, material: Material) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in triangles:
		tool.set_normal(Vector3.UP)
		tool.add_vertex(vertex)
	tool.set_material(material)
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = tool.commit()
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mesh


func _build_ice_edge_wall(parent: StaticBody3D, top_level: float, thickness: float) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for index in SURFACE_SEGMENTS:
		var a0 := TAU * float(index) / float(SURFACE_SEGMENTS)
		var a1 := TAU * float(index + 1) / float(SURFACE_SEGMENTS)
		var d0 := Vector2(cos(a0), sin(a0))
		var d1 := Vector2(cos(a1), sin(a1))
		var r0 := edge_radius(d0) + SURFACE_OVERLAP
		var r1 := edge_radius(d1) + SURFACE_OVERLAP
		var edge0 := _world(d0 * r0)
		var edge1 := _world(d1 * r1)
		var top0 := Vector3(edge0.x, top_level, edge0.y)
		var top1 := Vector3(edge1.x, top_level, edge1.y)
		var low0 := top0 - Vector3.UP * thickness
		var low1 := top1 - Vector3.UP * thickness
		for vertex in [top0, low0, top1, top1, low0, low1]:
			tool.add_vertex(vertex)
			faces.append(vertex)
	# Normals that agree with each face's winding, so both sides light
	# correctly with culling disabled.
	tool.generate_normals()
	var material := StandardMaterial3D.new()
	material.albedo_color = ICE_EDGE_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.12
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tool.set_material(material)
	var mesh := MeshInstance3D.new()
	mesh.name = "FrozenLakeEdge"
	mesh.mesh = tool.commit()
	parent.add_child(mesh)
	_add_collider(parent, faces)


func _add_collider(parent: StaticBody3D, faces: PackedVector3Array) -> void:
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true
	var collider := CollisionShape3D.new()
	collider.shape = shape
	parent.add_child(collider)
