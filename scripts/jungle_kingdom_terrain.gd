extends StaticBody3D

## Real ground for the primate kingdom (see kingdom_bootstrap.gd) -- unlike
## flat_ground.gd's flat placeholder, this is an actual undulating heightfield
## mirroring terrain_generator.gd's own hill-noise style (same HILL_AMPLITUDE/
## frequency approach, own seed) per direct instruction that the ground here
## should undulate "just like in the crossroads kingdom." Implements the same
## minimal Terrain contract every kingdom scene's Terrain sibling must satisfy
## (get_mesh_height/is_lake_area/get_lake_water_level -- see player.gd's
## _update_lake_buoyancy()); no lake here, so those two are honest false/0.0
## stubs, same as flat_ground.gd's.

const HALF_SIZE := 900.0  # matches terrain_generator.gd's own FIELD_HALF_SIZE, staying just inside DistantMountains' 950 ring so ground never runs out before the backdrop does
const RESOLUTION := 101  # vertices per side (100 quads) -- matches terrain_generator.gd's own RESOLUTION at this same extent
const HILL_AMPLITUDE := 5.0
const HILL_FREQUENCY := 0.02

## A winding river carved into the ground, per direct feedback asking for
## "streams or rivers pushed down into the ground like the lake is pushed
## down in the crossroads area" -- same coverage-based depth-carve technique
## as terrain_generator.gd's own lake (a 0..1 "how far into the water" field
## driving both the height carve and is_lake_area()), just wandering in Z as
## a function of X via 1D noise instead of that lake's fixed-shore smoothstep
## gating, since a river (unlike a lake basin) needs to actually bend.
const RIVER_HALF_WIDTH := 8.0
## Widened from 3.0 -- per direct feedback the carve/bank transition read as
## mismatched against the independent hill noise; a softer taper leaves less
## room for a local hill bump to visibly poke above the water mid-transition.
const RIVER_SHORE_SOFTNESS := 5.0
## More than 2x HILL_AMPLITUDE (raised from 7.0, only 1.4x) -- per direct
## feedback that the ground sometimes rose above the water. At 7.0 a hill
## peak (+5) near full river coverage could still leave the floor only
## ~2 units under RIVER_WATER_LEVEL; at this depth the floor stays reliably
## submerged even where the independent hill noise peaks at the same spot.
const RIVER_DEPTH := 14.0
## Below the hill noise's own baseline (0, +-HILL_AMPLITUDE) rather than
## just barely under it -- per direct feedback wanting a real shoreline/bank
## drop along the river, the same way the crossroads lake's own waterline
## sits below the surrounding wasteland instead of flush with it.
const RIVER_WATER_LEVEL := -3.0
const RIVER_BASE_Z := 150.0  # offset well clear of JungleVillage's own trees around the origin
const RIVER_WANDER := 60.0
const RIVER_WANDER_FREQUENCY := 0.0035
const RIVER_WATER_COLOR := Color(0.16, 0.42, 0.5, 0.6)
const RIVER_SEGMENT_SPACING := 12.0
## The visual water ribbon reaches farther than the gameplay carve
## (_river_coverage/is_lake_area) on purpose -- same reasoning
## terrain_generator.gd's own lake surface uses (see its
## LAKE_SURFACE_GROUND_OVERLAP/_lake_surface_coverage): tucking the visible
## edge under the rising bank instead of trying to land it on an exact
## mathematical shoreline is what actually fixes "the water doesn't stretch
## enough to clip into the banks," per direct feedback. Collision/buoyancy
## still use the narrower _river_coverage() footprint, unaffected.
const RIVER_SURFACE_OVERLAP := 4.0
## How far out the independent hill noise gets damped near the river --
## see _river_hill_influence()'s own doc comment.
const RIVER_INFLUENCE_WIDTH := RIVER_HALF_WIDTH + 24.0
## Sand, not grass -- per direct feedback the riverbed shouldn't read as
## green ground pushed underwater.
const RIVER_SAND_COLOR := Color(0.76, 0.68, 0.5)

var _hill_noise := FastNoiseLite.new()
var _river_noise := FastNoiseLite.new()


## Snapped to the exact piecewise-planar surface _build_mesh_and_collision()
## actually renders/collides against, rather than the raw continuous
## _terrain_height() formula -- mirrors terrain_generator.gd's own
## get_mesh_height()/_grid_vertex() precedent (see that file's doc comment
## for the full story: at RESOLUTION's ~18m grid spacing here, the raw
## noise curve can bulge above or dip below the flat triangle connecting
## its neighbors by a visible amount, which is exactly what read as
## villagers "clipping into the ground" or "hovering over it" once this
## kingdom's terrain was scaled up from its original, much finer 4m
## spacing). _terrain_height() stays the raw analytic source of truth
## _grid_vertex() is built from, not a replacement for it.
func get_mesh_height(x: float, z: float) -> float:
	var spacing := (HALF_SIZE * 2.0) / float(RESOLUTION - 1)
	var span := HALF_SIZE * 2.0
	var local_x := clampf(x + HALF_SIZE, 0.0, span - 0.001)
	var local_z := clampf(z + HALF_SIZE, 0.0, span - 0.001)
	var fx := local_x / spacing
	var fz := local_z / spacing
	var ix := clampi(int(fx), 0, RESOLUTION - 2)
	var iz := clampi(int(fz), 0, RESOLUTION - 2)
	var tx := fx - float(ix)
	var tz := fz - float(iz)

	var v00 := _grid_vertex(ix, iz, spacing)
	var v10 := _grid_vertex(ix + 1, iz, spacing)
	var v01 := _grid_vertex(ix, iz + 1, spacing)
	var v11 := _grid_vertex(ix + 1, iz + 1, spacing)

	# Matches _build_mesh_and_collision()'s own triangle split for this quad
	# exactly -- its index order (i0,i2,i1 / i1,i2,i3) splits along the
	# v01-v10 diagonal, not v00-v11, so a plain bilinear lerp across all 4
	# corners would quietly disagree with the real mesh near that diagonal.
	if tx + tz <= 1.0:
		return _plane_height(v00, v01, v10, x, z)
	else:
		return _plane_height(v10, v01, v11, x, z)


func _grid_vertex(ix: int, iz: int, spacing: float) -> Vector3:
	var wx := -HALF_SIZE + ix * spacing
	var wz := -HALF_SIZE + iz * spacing
	return Vector3(wx, _terrain_height(wx, wz), wz)


func _plane_height(a: Vector3, b: Vector3, c: Vector3, x: float, z: float) -> float:
	var denom := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	var w_a := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / denom
	var w_b := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / denom
	var w_c := 1.0 - w_a - w_b
	return w_a * a.y + w_b * b.y + w_c * c.y


func is_lake_area(world_pos: Vector2) -> bool:
	return _river_coverage(world_pos.x, world_pos.y) > 0.01


func get_lake_water_level() -> float:
	return RIVER_WATER_LEVEL


## Public so jungle_kingdom_foliage.gd can steer trees/undergrowth clear of
## the riverbed without duplicating this math.
func river_coverage(x: float, z: float) -> float:
	return _river_coverage(x, z)


func _river_center_z(x: float) -> float:
	return RIVER_BASE_Z + _river_noise.get_noise_1d(x) * RIVER_WANDER


func _river_coverage(x: float, z: float) -> float:
	var dist := absf(z - _river_center_z(x))
	return clampf(1.0 - smoothstep(RIVER_HALF_WIDTH - RIVER_SHORE_SOFTNESS, RIVER_HALF_WIDTH, dist), 0.0, 1.0)


## Fades the INDEPENDENT hill noise out near the river, wider than the
## river's own coverage footprint -- per direct feedback that the ground
## sometimes rose above the water partway through the shore transition.
## _terrain_height() carves a predictable, smooth shore from _river_coverage
## alone; without damping this, a local hill peak riding on top of that
## carve at partial coverage could still poke the floor above
## RIVER_WATER_LEVEL, since the two fields are otherwise unrelated. Reaches
## a full 1.0 exactly at RIVER_HALF_WIDTH (hills fully suppressed right at
## the coverage edge) and relaxes back to 0.0 by RIVER_INFLUENCE_WIDTH, well
## outside the visible bank.
func _river_hill_influence(x: float, z: float) -> float:
	var dist := absf(z - _river_center_z(x))
	return clampf(1.0 - smoothstep(RIVER_HALF_WIDTH, RIVER_INFLUENCE_WIDTH, dist), 0.0, 1.0)


func _terrain_height(x: float, z: float) -> float:
	var hills := _hill_noise.get_noise_2d(x, z) * HILL_AMPLITUDE
	var damped_hills := hills * (1.0 - _river_hill_influence(x, z))
	return damped_hills - RIVER_DEPTH * _river_coverage(x, z)


## A central-difference gradient of get_mesh_height() (now itself snapped to
## the exact rendered triangle, see that function's own doc comment) rather
## than terrain_generator.gd's dedicated exact-triangle-normal function --
## see blorb.gd's _surface_normal_at(), which only falls back to this when
## its own raycast misses a real collider, so this approximation (D=0.5,
## much smaller than a single triangle) reads as flat and correct within
## whichever triangle it's sampled from.
func get_mesh_normal(x: float, z: float) -> Vector3:
	const D := 0.5
	var slope_x := (get_mesh_height(x + D, z) - get_mesh_height(x - D, z)) / (2.0 * D)
	var slope_z := (get_mesh_height(x, z + D) - get_mesh_height(x, z - D)) / (2.0 * D)
	return Vector3(-slope_x, 1.0, -slope_z).normalized()


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_hill_noise.seed = 20260817
	_hill_noise.frequency = HILL_FREQUENCY
	_hill_noise.fractal_octaves = 3
	_river_noise.seed = 20260824
	_river_noise.frequency = RIVER_WANDER_FREQUENCY
	_river_noise.fractal_octaves = 2
	_build_mesh_and_collision()
	_build_river_water()


func _height_color(h: float, coverage: float) -> Color:
	var low := Color(0.14, 0.42, 0.16)
	var high := Color(0.22, 0.5, 0.2)
	var grass := low.lerp(high, smoothstep(-HILL_AMPLITUDE, HILL_AMPLITUDE, h))
	return grass.lerp(RIVER_SAND_COLOR, coverage)


## Mesh and collision are built from the exact same vertex grid (see
## terrain_generator.gd's own _build_mesh()/_build_terrain_collision() for
## the precedent this mirrors) so there's no possibility of a visual/collision
## mismatch. backface_collision = true is required for this winding order --
## see terrain_generator.gd's doc comment on _build_terrain_collision() for
## the confirmed repro behind that requirement.
func _build_mesh_and_collision() -> void:
	var spacing := (HALF_SIZE * 2.0) / float(RESOLUTION - 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var heights := []
	heights.resize(RESOLUTION * RESOLUTION)
	for iz in RESOLUTION:
		for ix in RESOLUTION:
			var wx := -HALF_SIZE + ix * spacing
			var wz := -HALF_SIZE + iz * spacing
			heights[iz * RESOLUTION + ix] = _terrain_height(wx, wz)

	for iz in RESOLUTION:
		for ix in RESOLUTION:
			var wx := -HALF_SIZE + ix * spacing
			var wz := -HALF_SIZE + iz * spacing
			var h: float = heights[iz * RESOLUTION + ix]
			st.set_color(_height_color(h, _river_coverage(wx, wz)))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(wx, h, wz))

	for iz in RESOLUTION - 1:
		for ix in RESOLUTION - 1:
			var i0 := iz * RESOLUTION + ix
			var i1 := i0 + 1
			var i2 := i0 + RESOLUTION
			var i3 := i2 + 1
			st.add_index(i0)
			st.add_index(i2)
			st.add_index(i1)
			st.add_index(i1)
			st.add_index(i2)
			st.add_index(i3)

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = 1.0
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	add_child(mesh_instance)

	var faces := PackedVector3Array()
	for iz in RESOLUTION - 1:
		for ix in RESOLUTION - 1:
			var wx0 := -HALF_SIZE + ix * spacing
			var wz0 := -HALF_SIZE + iz * spacing
			var wx1 := -HALF_SIZE + (ix + 1) * spacing
			var wz1 := -HALF_SIZE + (iz + 1) * spacing
			var h00: float = heights[iz * RESOLUTION + ix]
			var h10: float = heights[iz * RESOLUTION + ix + 1]
			var h01: float = heights[(iz + 1) * RESOLUTION + ix]
			var h11: float = heights[(iz + 1) * RESOLUTION + ix + 1]
			var v00 := Vector3(wx0, h00, wz0)
			var v10 := Vector3(wx1, h10, wz0)
			var v01 := Vector3(wx0, h01, wz1)
			var v11 := Vector3(wx1, h11, wz1)
			faces.append(v00)
			faces.append(v01)
			faces.append(v10)
			faces.append(v10)
			faces.append(v01)
			faces.append(v11)

	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(faces)
	shape.backface_collision = true

	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = shape
	add_child(collision_shape)


## Visual-only ribbon (no collision, matching ocean_kingdom_terrain.gd's own
## lake surface sheet) following the river's own wandering centerline at a
## constant RIVER_WATER_LEVEL, so the player swims through it rather than
## standing on it -- the riverbed collision comes from the carved heightfield
## above.
func _build_river_water() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var steps := int((HALF_SIZE * 2.0) / RIVER_SEGMENT_SPACING)
	var prev_left := Vector3.ZERO
	var prev_right := Vector3.ZERO
	var has_prev := false
	for i in steps + 1:
		var x := -HALF_SIZE + float(i) * RIVER_SEGMENT_SPACING
		var cz := _river_center_z(x)
		var surface_half_width := RIVER_HALF_WIDTH + RIVER_SURFACE_OVERLAP
		var left := Vector3(x, RIVER_WATER_LEVEL, cz - surface_half_width)
		var right := Vector3(x, RIVER_WATER_LEVEL, cz + surface_half_width)
		if has_prev:
			st.set_normal(Vector3.UP)
			st.add_vertex(prev_left)
			st.add_vertex(left)
			st.add_vertex(prev_right)
			st.add_vertex(prev_right)
			st.add_vertex(left)
			st.add_vertex(right)
		prev_left = left
		prev_right = right
		has_prev = true

	var material := StandardMaterial3D.new()
	material.albedo_color = RIVER_WATER_COLOR
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.05
	material.metallic = 0.2
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	add_child(mesh_instance)
