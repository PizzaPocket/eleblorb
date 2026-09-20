class_name NaturalLake
extends RefCounted

## A natural lake punched into a heightfield, in the game's established way:
## the Ice Kingdom's organic shoreline, bank shelf and basin carve (see
## ice_kingdom_terrain.gd's _lake_coverage()/_lake_edge_radius()/
## _terrain_height()), with either an open water sheet (the Crossroads lake's
## opaque water colour) or the Ice Kingdom's frozen surface: a solid ice sheet
## with an ice edge wall, over water.
##
## `half_length` elongates the lake along world X (a long lake running down a
## valley) as a stadium: a straight channel of that half-length with a
## semicircular end at each tip. Every distance is measured from the nearest
## point on that centreline, so the bank and shore keep the same width all
## the way round, ends included.
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
## Grid cell of the surface sheets, and spacing of the ice edge wall's samples.
const SURFACE_CELL := 5.0
const EDGE_SAMPLE_SPACING := 6.0
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
var half_length := 0.0
## How far inside the shore the basin reaches its full depth. SHORE_FEATHER
## by default (a steep-sided lake); wider for a sea shelving gradually away
## from the beach.
var slope_width := SHORE_FEATHER
var _noise := FastNoiseLite.new()


func _init(
	lake_center: Vector2, lake_radius: float, lake_edge_variation: float,
	lake_depth: float, lake_shelf_level: float, noise_seed: int, lake_half_length: float = 0.0,
	lake_slope_width: float = SHORE_FEATHER
) -> void:
	half_length = lake_half_length
	slope_width = lake_slope_width
	center = lake_center
	radius = lake_radius
	edge_variation = lake_edge_variation
	depth = lake_depth
	shelf_level = lake_shelf_level
	_noise.seed = noise_seed
	_noise.frequency = 0.011
	_noise.fractal_octaves = 4


## The nearest point to `pos` on the lake's centreline segment.
func _spine_point(pos: Vector2) -> Vector2:
	return Vector2(clampf(pos.x, center.x - half_length, center.x + half_length), center.y)


## The shoreline's distance from the centreline, outward along `normal` from
## the centreline point `spine`: coherent noise plus two low harmonics sampled
## where that direction meets the nominal shore, so the edge wanders in and out
## along the sides and round the ends alike.
func _edge_at(spine: Vector2, normal: Vector2) -> float:
	var shore := spine + normal * radius
	var organic := _noise.get_noise_2d(shore.x, shore.y)
	organic += sin(shore.x * 0.019 + 0.7) * 0.34 + sin(shore.y * 0.07 - shore.x * 0.011 - 1.1) * 0.18
	return radius + organic * edge_variation


## Distance from the centreline, and the shoreline's distance along that same
## direction.
func _distance_and_edge(pos: Vector2) -> Vector2:
	var spine := _spine_point(pos)
	var offset := pos - spine
	var distance := offset.length()
	var normal := offset / distance if distance > 0.001 else Vector2(0.0, 1.0)
	return Vector2(distance, _edge_at(spine, normal))


## 0 outside the lake, rising to 1 across SHORE_FEATHER inside its edge.
func coverage(pos: Vector2) -> float:
	var measure := _distance_and_edge(pos)
	return 1.0 - smoothstep(measure.y - SHORE_FEATHER, measure.y, measure.x)


## Folds the lake into a terrain height: surrounding ground banks down to the
## shelf, then the basin deepens toward the middle.
func carve(ground_height: float, pos: Vector2) -> float:
	var bank := 1.0 - smoothstep(radius, radius + BANK_WIDTH, local_distance(pos))
	var banked := lerpf(ground_height, shelf_level, bank)
	var lake := coverage(pos)
	return lerpf(banked, shelf_level - depth * depth_weight(pos), lake)


## 0 at the shore, rising to 1 where the basin reaches full depth,
## slope_width inside the edge.
func depth_weight(pos: Vector2) -> float:
	var measure := _distance_and_edge(pos)
	return 1.0 - smoothstep(measure.y - slope_width, measure.y, measure.x)


## Distance from the lake's centreline: compare with radius, radius +
## BANK_WIDTH and so on for rings that follow the lake's outline.
func local_distance(pos: Vector2) -> float:
	return pos.distance_to(_spine_point(pos))


## The centreline point and outward normal at `fraction` (0..1) of the way
## round the outline: along the south side east, round the east end, along the
## north side west, round the west end.
func _outline_frame(fraction: float) -> Array:
	var arc := PI * radius
	var side := 2.0 * half_length
	var s := fposmod(fraction, 1.0) * (2.0 * side + 2.0 * arc)
	if s < side:
		return [center + Vector2(-half_length + s, 0.0), Vector2(0.0, -1.0)]
	s -= side
	if s < arc:
		return [center + Vector2(half_length, 0.0), Vector2.from_angle(-PI * 0.5 + s / radius)]
	s -= arc
	if s < side:
		return [center + Vector2(half_length - s, 0.0), Vector2(0.0, 1.0)]
	s -= side
	return [center + Vector2(-half_length, 0.0), Vector2.from_angle(PI * 0.5 + s / radius)]


## The world point at `angle` (a fraction of a full turn round the outline)
## on the ring `local_radius` from the centreline.
func point_on_ring(angle: float, local_radius: float) -> Vector2:
	var frame := _outline_frame(angle / TAU)
	return (frame[0] as Vector2) + (frame[1] as Vector2) * local_radius


## True where the surface layers are drawn (the edge plus its overlap).
func is_within_surface(pos: Vector2, overlap: float = SURFACE_OVERLAP) -> bool:
	var measure := _distance_and_edge(pos)
	return measure.x <= measure.y + overlap


## How far past the shoreline a liquid sheet must be drawn so that its own
## edge is certainly buried in ground standing above the liquid.
##
## A sheet is built from whole SURFACE_CELL cells kept when their centre is
## inside, so its boundary is a stair-stepped grid line, not the smooth
## shoreline. Stop that line anywhere the bed still lies below the liquid and
## the steps show as a jagged edge running across the bed -- the single most
## repeated liquid-surface bug in this project. Drawing out past BANK_WIDTH
## puts the boundary in the bank, which by construction has climbed back to
## the surrounding ground, so the steps are inside the terrain where nothing
## can see them. Pass this to build_surface() for any pool whose liquid level
## sits at or below its own shelf.
func bank_covering_overlap() -> float:
	return BANK_WIDTH + SURFACE_OVERLAP


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
func build_surface(
	parent: Node3D, label: String, level: float, material: Material,
	overlap: float = SURFACE_OVERLAP
) -> void:
	parent.add_child(_surface_mesh(label, _disc_triangles(level, overlap), material))


## A frozen lake, as in the Ice Kingdom: a solid, walkable ice sheet at
## `ice_surface_level` with a visible edge wall `thickness` deep, and the
## water beneath it at `water_level`, unless `with_water` is false: a lake
## frozen solid, its ice lying straight on the ground beneath.
func build_frozen(parent: StaticBody3D, ice_surface_level: float, thickness: float, water_level: float, with_water: bool = true) -> void:
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
	if not with_water:
		return
	var water := StandardMaterial3D.new()
	water.albedo_color = UNDER_ICE_WATER_COLOR
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.12
	water.metallic = 0.12
	water.cull_mode = BaseMaterial3D.CULL_DISABLED
	parent.add_child(_surface_mesh("FrozenLakeWater", _disc_triangles(water_level), water))


## A grid of SURFACE_CELL squares covering the edge plus its overlap, as a
## flat triangle list at height `y`, clockwise from above (Godot's front face)
## so faces agree with their upward normals. The grid's ragged outer cells lie
## under the bank. Shared by the visible mesh and, for ice, its collider.
func _disc_triangles(y: float, overlap: float = SURFACE_OVERLAP) -> PackedVector3Array:
	var triangles := PackedVector3Array()
	var reach := radius + edge_variation * 1.6 + overlap
	var x0 := center.x - half_length - reach
	var z0 := center.y - reach
	var columns := int(ceil((half_length + reach) * 2.0 / SURFACE_CELL))
	var rows := int(ceil(reach * 2.0 / SURFACE_CELL))
	for row in rows:
		for column in columns:
			var a := Vector2(x0 + float(column) * SURFACE_CELL, z0 + float(row) * SURFACE_CELL)
			if not is_within_surface(a + Vector2.ONE * SURFACE_CELL * 0.5, overlap):
				continue
			var b := a + Vector2(SURFACE_CELL, 0.0)
			var c := a + Vector2(0.0, SURFACE_CELL)
			var d := a + Vector2(SURFACE_CELL, SURFACE_CELL)
			for corner in [a, b, c, b, d, c]:
				triangles.append(Vector3(corner.x, y, corner.y))
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
	var perimeter := 4.0 * half_length + TAU * radius
	var samples := maxi(int(perimeter / EDGE_SAMPLE_SPACING), 48)
	for index in samples:
		var frame0 := _outline_frame(float(index) / float(samples))
		var frame1 := _outline_frame(float(index + 1) / float(samples))
		var spine0: Vector2 = frame0[0]
		var spine1: Vector2 = frame1[0]
		var normal0: Vector2 = frame0[1]
		var normal1: Vector2 = frame1[1]
		var edge0 := spine0 + normal0 * (_edge_at(spine0, normal0) + SURFACE_OVERLAP)
		var edge1 := spine1 + normal1 * (_edge_at(spine1, normal1) + SURFACE_OVERLAP)
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
