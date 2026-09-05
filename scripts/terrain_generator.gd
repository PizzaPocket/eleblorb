@tool
extends StaticBody3D

## Procedurally builds a heightmap terrain: gentle rolling hills in the
## playable area, mountains further out, then a plateau rim -- past an
## organic (noisy, non-circular) boundary defined by _edge_radius(). Most
## of the rim is a hard fall into the gorge, while the eastern lake sector
## transitions through a broad natural slope into its submerged basin.
## There is no collision wall at that boundary -- players can walk off the
## edge and fall. get_height() is
## public so scatter/town placement can query the same surface the mesh
## and collision were built from.
##
## @tool + "Rebuild Now" below mirrors town_generator.gd's pattern: this
## runs in the editor too so the ground is visible while placing town
## markers, but only actually rebuilds on scene load or when explicitly
## toggled (moving the mouse/editing an unrelated property doesn't
## re-trigger it).
##
## Generated children are deliberately left without an owner -- they still
## render in the editor viewport, but that keeps them out of the Scene dock
## tree and (more importantly) out of main.tscn if it gets saved while the
## editor's built them.
##
## Collision is a single ConcavePolygonShape3D built from literally the same
## vertex grid _build_mesh() renders (see _build_terrain_collision()) -- not
## an approximation, so there's no possible mismatch between what's drawn
## and what's solid. This corrects an earlier finding (project memory) that
## concave shapes "don't register at all" in this Godot install: the real
## cause was a missing backface_collision flag (see _build_terrain_collision
## for the confirmed repro), not a fundamental engine limitation.

# Extended to carry the entire western wasteland city (and its collision)
# beyond the plateau rim without a mesh boundary cutting through it, and
# further out again to reach the jungle plateau's own relocated footprint
# (see JUNGLE_PLATEAU_CENTER below) -- RESOLUTION is deliberately left
# unchanged, so this only makes each mesh quad bigger, not the vertex/
# collision-triangle count.
const FIELD_HALF_SIZE := 900.0
const RESOLUTION := 101  # vertices per side (100 quads), for both mesh and collision

const HILL_AMPLITUDE := 3.0
const MOUNTAIN_AMPLITUDE := 45.0
const MOUNTAIN_RING_START := 90.0
const MOUNTAIN_RING_FULL := 190.0

const SPAWN_CENTER := Vector2(0, 0)
const SPAWN_FLATTEN_RADIUS := 25.0

# The plateau rim is centered on the origin (like the mountain ring), not
# the town -- town_center (150, 70) sits ~165 units out, and the town's own
# built content (buildings/stalls/etc, see main.tscn's Town markers) reaches
# roughly another ~40 units beyond that in the worst direction, so the rim
# has to clear ~205 in every direction with real margin. PLATEAU_RADIUS -
# EDGE_VARIATION (225) clears that with room to spare.
const PLATEAU_RADIUS := 245.0
const EDGE_VARIATION := 20.0  # organic wobble in the rim's radius, per angle
const EDGE_NOISE_SAMPLE_RADIUS := 60.0  # noise-space radius sampled per angle
const GORGE_DEPTH := 60.0  # how far below sea level the gorge floor sits

# The jungle biome's own plateau, entirely separate from the main one above
# -- out in the southwest wasteland, clear of the canyon zone
# (CANYON_BIOME_CENTER (-215, 0) r=72, see wilderness_scatter.gd) and the
# main plateau's own rim (max reach 265) by a comfortable margin even at
# worst-case edge-noise alignment on both landforms. Pushed ~300m further
# out from the main plateau (per direct instruction) along the same bearing
# it already sat on -- old center (-280, 260) was 382 units from the origin,
# so the new center sits at 682 units out on that same unit vector. Its full
# outer reach (center distance 682 + JUNGLE_PLATEAU_RADIUS + JUNGLE_RISE_
# DISTANCE = 822) stays comfortably inside SKIRT_INNER_RADIUS (870) below,
# so the raised landform never clips into the hardcoded-flat skirt annulus.
const JUNGLE_PLATEAU_CENTER := Vector2(-500.0, 464.0)
# Enlarged along with the rest of the jungle biome (per direct instruction
# the whole area should be "larger and more densely populated") -- see
# wilderness_scatter.gd's _build_jungle_biome() for the matching density
# bump.
const JUNGLE_PLATEAU_RADIUS := 70.0
const JUNGLE_EDGE_VARIATION := 14.0
const JUNGLE_EDGE_NOISE_SAMPLE_RADIUS := 60.0
# How far past the plateau's own edge the slope down to the wasteland floor
# runs. 35m of rise (GORGE_DEPTH to JUNGLE_PLATEAU_HEIGHT) over this
# distance is a walkable grade, similar to the mountain ring's own slope,
# rather than a sheer cliff needing a climbing structure like the canyon's.
const JUNGLE_RISE_DISTANCE := 70.0
const JUNGLE_PLATEAU_HEIGHT := -25.0  # top height, well above the -60 gorge floor

# Eastern lake: the existing gorge floor is the waterline, which makes the
# lake feel like the eastern wasteland has been pressed down and flooded,
# rather than like a raised water prop dropped into the world. The basin
# begins at the east plateau's rim, opens broadly toward the mountains, and
# shallows again at their foot so the water has a natural, contained edge.
# Lower than the surrounding wasteland by roughly a person's height. This
# exposes the basin's natural upper slope as a narrow beach instead of
# letting the water meet the flat wasteland at an invisible seam.
const LAKE_WATER_LEVEL := -GORGE_DEPTH - 1.65
# A true basin, not a shallow flooded shelf: at its center the lake floor
# sits 135m below the wasteland waterline, making the east plateau's drop
# and the mountain-framed water read at a genuinely monumental scale.
const LAKE_MAX_DEPTH := 135.0
const LAKE_START_X := 220.0
const LAKE_OPEN_X := 400.0
const LAKE_MOUNTAIN_SHORE_X := 635.0
const LAKE_NARROW_HALF_WIDTH := 72.0
const LAKE_WIDE_HALF_WIDTH := 340.0
const LAKE_SHORE_SOFTNESS := 42.0
const LAKE_SHORE_VARIATION := 34.0
const LAKE_RIM_SLOPE_DISTANCE := 92.0
# The water mesh deliberately overhangs the calculated basin edge. Its last
# band is buried into the surrounding wasteland rather than ending exactly
# at the terrain seam, which prevents a dry hairline from appearing around
# the lake as the low-poly ground slopes into it.
const LAKE_SURFACE_GROUND_OVERLAP := 96.0
# A flat water surface does not need the terrain's 6.5m collision grid.
# Larger cells cut the lake to roughly one fifth as many triangles without
# changing its silhouette at normal exploration distance.
const LAKE_WATER_CELL_SIZE := 12.0

# Fills the visual gap between the gorge floor's outer rim and
# distant_mountains.gd's ring (RADIUS 950) so the mountains don't appear to
# float past a strip of empty void. SKIRT_INNER_RADIUS (870) is chosen to be
# both comfortably inside FIELD_HALF_SIZE's square mesh (900, so every angle
# is still covered by the real mesh there) and comfortably past the maximum
# possible edge radius (245 + 20 = 265) -- so get_height() is already flat
# at exactly -GORGE_DEPTH for every angle at this radius (a hard step past
# _edge_radius(), see get_height()), meaning the skirt (also flat at
# -GORGE_DEPTH) meets the real terrain mesh with no seam. Also has to clear
# the jungle plateau's own full outer reach (682 + 70 + 70 = 822, see
# JUNGLE_PLATEAU_CENTER above) with margin, since that landform is no longer
# anywhere near the origin -- 870 leaves 48 units of clearance past it.
const SKIRT_INNER_RADIUS := 870.0
const SKIRT_OUTER_RADIUS := 950.0  # matches distant_mountains.gd's RADIUS
const SKIRT_SEGMENTS := 96  # matches distant_mountains.gd's SEGMENTS

@export var town_center: Vector2 = Vector2(150, 70)
## The city lies far beyond the western canyon and the giant's wasteland
## route, deep in the gorge-floor wasteland. Its foundation stays flat and
## collision-safe.
const CITY_CENTER := Vector2(-540, 0)
const CITY_FLAT_RADIUS := 78.0
const CITY_FLATTEN_TRANSITION := 18.0
# A smoothstep starting at 0 was never actually flat except at the exact
# center point -- by the time you reached a building 20-30m out it had
# already picked up real hill noise, enough for the ground to clip through
# precisely-placed foundations/props. town_flat_radius is a hard flat zone
# comfortably covering the whole authored town layout, plus margin; natural
# terrain only resumes gradually past town_flat_radius + town_flatten_
# transition.
@export var town_flat_radius: float = 65.0
@export var town_flatten_transition: float = 25.0

## Same momentary-button pattern as town_generator.gd's rebuild_now.
@export var rebuild_now: bool = false:
	set(value):
		if value:
			_rebuild()
		rebuild_now = false

## The canyon biome's authored center/radius (see wilderness_scatter.gd's
## _build_canyon_biome()) -- Vector2.INF/0.0 until set_canyon_zone() is
## called, meaning "no canyon zone, ordinary height-only gradient
## everywhere." Not exported: WildernessScatter uses the authored western
## canyon location at runtime, then sets this programmatically.
var canyon_center: Vector2 = Vector2.INF
var canyon_radius: float = 0.0

var _hill_noise := FastNoiseLite.new()
var _mountain_noise := FastNoiseLite.new()
var _edge_noise := FastNoiseLite.new()
var _lake_noise := FastNoiseLite.new()
var _jungle_edge_noise := FastNoiseLite.new()
var _wasteland_noise := FastNoiseLite.new()


func _init() -> void:
	_hill_noise.seed = 20260815
	_hill_noise.frequency = 0.015
	_hill_noise.fractal_octaves = 3

	_mountain_noise.seed = 91820260815
	_mountain_noise.frequency = 0.006
	_mountain_noise.fractal_octaves = 4

	_edge_noise.seed = 620260815
	_edge_noise.frequency = 0.05
	_edge_noise.fractal_octaves = 2

	_lake_noise.seed = 8420260815
	_lake_noise.frequency = 0.012
	_lake_noise.fractal_octaves = 3

	_jungle_edge_noise.seed = 33720260815
	_jungle_edge_noise.frequency = 0.05
	_jungle_edge_noise.fractal_octaves = 2

	_wasteland_noise.seed = 1920260822
	_wasteland_noise.frequency = 0.009
	_wasteland_noise.fractal_octaves = 3


func get_height(x: float, z: float) -> float:
	var dist_origin := Vector2(x, z).length()
	var dist_town := Vector2(x, z).distance_to(town_center)
	var dist_city := Vector2(x, z).distance_to(CITY_CENTER)

	var hills := _hill_noise.get_noise_2d(x, z) * HILL_AMPLITUDE
	var mountain_raw := maxf(_mountain_noise.get_noise_2d(x, z), 0.0)
	var mountain_mask := smoothstep(MOUNTAIN_RING_START, MOUNTAIN_RING_FULL, dist_origin)
	var mountains := pow(mountain_raw, 1.5) * MOUNTAIN_AMPLITUDE * mountain_mask

	var height := hills + mountains

	var spawn_flatten := smoothstep(0.0, SPAWN_FLATTEN_RADIUS, dist_origin)
	var town_flatten := smoothstep(
		town_flat_radius, town_flat_radius + town_flatten_transition, dist_town
	)
	var city_flatten := smoothstep(CITY_FLAT_RADIUS, CITY_FLAT_RADIUS + CITY_FLATTEN_TRANSITION, dist_city)
	# Either settlement can flatten the terrain. `min` preserves a hard flat
	# district rather than multiplying both masks and accidentally reintroducing
	# hills between the two authored locations.
	height *= spawn_flatten * minf(town_flatten, city_flatten)

	# Plateau rim: outside the eastern lake it remains a hard gorge drop. In
	# the lake sector, though, the land falls through a broad natural slope
	# before reaching the submerged basin floor.
	var edge_radius := _edge_radius(atan2(z, x))
	if dist_origin > edge_radius:
		var lake_amount := lake_coverage(x, z)
		if lake_amount > 0.0:
			var rim_slope := smoothstep(edge_radius, edge_radius + LAKE_RIM_SLOPE_DISTANCE, dist_origin)
			height = lerpf(height, _lake_floor_height(x, z), rim_slope)
		else:
			var jungle_amount := jungle_coverage(x, z)
			if jungle_amount > 0.0:
				# Give the jungle the same gentle rolling topography as the main
				# plateau instead of blending toward a perfectly level cap. Keeping
				# the shared hill field makes both plateaus feel like parts of the
				# same landscape, while jungle_coverage() still eases the raised
				# ground cleanly into the surrounding wasteland.
				var jungle_height := JUNGLE_PLATEAU_HEIGHT + hills
				height = lerpf(_wasteland_height(x, z), jungle_height, jungle_amount)
			else:
				height = _wasteland_height(x, z)

	return height


## Broad, low-amplitude undulation keeps the desert floor from reading as a
## manufactured plane. Settlement foundations remain level, while the long
## wavelength and modest rise preserve easy traversal and cheap heightmap
## collision (no extra runtime bodies).
func _wasteland_height(x: float, z: float) -> float:
	var variation := _wasteland_noise.get_noise_2d(x, z) * 2.4
	var dist_city := Vector2(x, z).distance_to(CITY_CENTER)
	var city_mask := smoothstep(CITY_FLAT_RADIUS, CITY_FLAT_RADIUS + CITY_FLATTEN_TRANSITION, dist_city)
	return -GORGE_DEPTH + variation * city_mask


## The plateau's boundary radius at a given angle around the origin --
## PLATEAU_RADIUS perturbed by noise sampled around a circle (via cos/sin,
## not by angle directly -- FastNoiseLite is 2D/3D, not 1D), so it wraps
## seamlessly at angle 0/TAU and reads as an irregular, organic coastline
## rather than a perfect circle. Shared by get_height() and _height_color()
## so they line up exactly.
func _edge_radius(angle: float) -> float:
	var sample := _edge_noise.get_noise_2d(
		cos(angle) * EDGE_NOISE_SAMPLE_RADIUS, sin(angle) * EDGE_NOISE_SAMPLE_RADIUS
	)
	return PLATEAU_RADIUS + sample * EDGE_VARIATION


## true past the plateau's edge, false on it -- a hard boundary, not a
## graded one, shared by get_height() (the height step) and _height_color()
## (the color step) so both land on exactly the same radius per angle.
func _past_edge(x: float, z: float, dist_origin: float) -> bool:
	return dist_origin > _edge_radius(atan2(z, x))


## A wide east-facing basin rather than an oval pond: it starts narrow where
## it meets the plateau, flares across the whole eastern wasteland, and runs
## to the mountain foot. The return value is 0 outside the lake and 1 well
## inside it; both terrain and water use this exact footprint.
func lake_coverage(x: float, z: float) -> float:
	var eastward := smoothstep(LAKE_START_X, LAKE_START_X + 48.0, x)
	var half_width := _lake_shore_half_width(x, z)
	var lateral := 1.0 - smoothstep(
		half_width - LAKE_SHORE_SOFTNESS, half_width, absf(z)
	)
	return clampf(minf(eastward, lateral), 0.0, 1.0)


## A coherent noise field bends the shore in and out over long distances,
## avoiding the straight, mechanically expanding edge an ellipse-like basin
## would have. Both visual water and gameplay terrain call this helper.
func _lake_shore_half_width(x: float, z: float) -> float:
	var opening := smoothstep(LAKE_START_X, LAKE_OPEN_X, x)
	var nominal_width := lerpf(LAKE_NARROW_HALF_WIDTH, LAKE_WIDE_HALF_WIDTH, opening)
	var shore_noise := _lake_noise.get_noise_2d(x, z) * LAKE_SHORE_VARIATION
	return maxf(nominal_width + shore_noise, LAKE_NARROW_HALF_WIDTH * 0.55)


## The visible water reaches farther than the gameplay basin on purpose:
## its perimeter is tucked under the ground instead of trying to land on an
## exact mathematical shoreline. This is render-only; collision/buoyancy
## still use lake_coverage() so the shallow shore remains walkable.
func _lake_surface_coverage(x: float, z: float) -> float:
	var eastward := smoothstep(
		LAKE_START_X - LAKE_SURFACE_GROUND_OVERLAP,
		LAKE_START_X + 48.0,
		x
	)
	var half_width := _lake_shore_half_width(x, z)
	var lateral := 1.0 - smoothstep(
		half_width - LAKE_SHORE_SOFTNESS,
		half_width + LAKE_SURFACE_GROUND_OVERLAP,
		absf(z)
	)
	return clampf(minf(eastward, lateral), 0.0, 1.0)


## Public so wilderness systems can reserve the water rather than placing
## ground props under it when their placement range is expanded later.
func is_lake_area(world_pos: Vector2) -> bool:
	return lake_coverage(world_pos.x, world_pos.y) > 0.01


## The jungle plateau's boundary radius at a given angle around its own
## center -- same organic-wobble technique as _edge_radius(), just centered
## on JUNGLE_PLATEAU_CENTER instead of the origin.
func _jungle_edge_radius(angle: float) -> float:
	var sample := _jungle_edge_noise.get_noise_2d(
		cos(angle) * JUNGLE_EDGE_NOISE_SAMPLE_RADIUS, sin(angle) * JUNGLE_EDGE_NOISE_SAMPLE_RADIUS
	)
	return JUNGLE_PLATEAU_RADIUS + sample * JUNGLE_EDGE_VARIATION


## 1.0 well inside the jungle plateau's own footprint, fading to 0.0 over
## JUNGLE_RISE_DISTANCE past its organic edge -- shared by get_height() (the
## rise) and _height_color() (the green ground tint) so both agree exactly.
func jungle_coverage(x: float, z: float) -> float:
	var rel := Vector2(x, z) - JUNGLE_PLATEAU_CENTER
	var edge_radius := _jungle_edge_radius(atan2(rel.y, rel.x))
	return 1.0 - smoothstep(edge_radius, edge_radius + JUNGLE_RISE_DISTANCE, rel.length())


## Public so wilderness_scatter.gd can reserve/scatter within the jungle
## plateau without needing its own duplicate copy of the landform's shape --
## unlike the canyon (a color-only zone whose position wilderness_scatter.gd
## itself authors and pushes in via set_canyon_zone()), the jungle plateau's
## position affects real height, so it has to live here as its own source
## of truth instead.
func is_jungle_area(world_pos: Vector2) -> bool:
	return jungle_coverage(world_pos.x, world_pos.y) > 0.01


func get_jungle_plateau_center() -> Vector2:
	return JUNGLE_PLATEAU_CENTER


func get_jungle_plateau_radius() -> float:
	return JUNGLE_PLATEAU_RADIUS


## Cliff dressing must follow the same noise-wobbled perimeter as the
## jungle heightfield rather than assuming its nominal radius is circular.
func get_jungle_plateau_edge_radius(angle: float) -> float:
	return _jungle_edge_radius(angle)


## Lets cliff dressing follow the exact same organic rim as the terrain.
func get_plateau_edge_radius(angle: float) -> float:
	return _edge_radius(angle)


func get_city_center() -> Vector2:
	return CITY_CENTER


## Shared with Player's swimming buoyancy so the gameplay waterline is the
## same surface the lake mesh renders, with no duplicated magic height.
func get_lake_water_level() -> float:
	return LAKE_WATER_LEVEL


func _lake_floor_height(x: float, z: float) -> float:
	var coverage := lake_coverage(x, z)
	if coverage <= 0.0:
		return _wasteland_height(x, z)
	# The floor slopes down from the cliff, reaches its deepest point in the
	# central open water, then rises into the mountain foot at the far east.
	var down_from_plateau := smoothstep(LAKE_START_X, LAKE_OPEN_X + 40.0, x)
	var up_to_mountains := 1.0 - smoothstep(535.0, LAKE_MOUNTAIN_SHORE_X, x)
	var lateral_bowl := 1.0 - smoothstep(0.42, 1.0, absf(z) / LAKE_WIDE_HALF_WIDTH)
	var depth := LAKE_MAX_DEPTH * coverage * down_from_plateau * up_to_mountains * lateral_bowl
	return _wasteland_height(x, z) - depth


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_rebuild()


func _rebuild() -> void:
	for c in get_children():
		c.free()
	_build_mesh()
	_build_eastern_lake()
	_build_far_skirt()
	_build_terrain_collision()


## Called once by WildernessScatter._build_canyon_biome() right after it
## randomly picks the canyon's own center, so the whole zone reads as bare
## canyon-floor dirt regardless of the ordinary height-based grass/dirt/
## rock/snow gradient underneath it (see _height_color()'s own canyon blend)
## -- ordinary rolling hills and the canyon's rock formations otherwise look
## like they're standing on two unrelated colors of ground. Triggers one
## full _rebuild(): only the per-vertex COLOR actually changes (get_height()
## itself is untouched), so re-running it after WildernessScatter has
## already placed props against the old colors is safe -- the heightfield
## those placements were measured against comes out bit-for-bit identical.
func set_canyon_zone(center: Vector2, radius: float) -> void:
	canyon_center = center
	canyon_radius = radius
	_rebuild()


## world_pos defaults to Vector2.INF ("no position available") for the far
## skirt/gorge-floor callers below, which only ever pass a single fixed
## height/past_edge pair for their whole mesh and have no per-vertex position
## to give anyway -- the canyon blend only ever applies to _build_mesh()'s
## own real per-vertex call, which does have one.
func _height_color(h: float, past_edge: bool, world_pos: Vector2 = Vector2.INF) -> Color:
	# Exact hex #13A367, per direct instruction (a more vibrant green than
	# the earlier #4ACE97).
	var grass := Color(0.07451, 0.63922, 0.40392)
	var dirt := Color(0.55, 0.42, 0.24)
	var rock := Color(0.58, 0.57, 0.56)
	var snow := Color(0.96, 0.97, 1.0)
	# A deep, rich canopy-floor green -- distinct from the ordinary grass
	# color above so the jungle plateau reads as its own lush biome.
	var jungle_green := Color(0.05098, 0.36078, 0.14902)
	# HILL_AMPLITUDE is only 3.0, so grass held pure well past that (to 10.0)
	# covers the entire hill/spawn/town range with zero dirt blend -- dirt,
	# rock, and snow are pushed out to only appear well up into the
	# mountains (MOUNTAIN_AMPLITUDE 45.0), not on ordinary rolling ground.
	var natural: Color
	if h < 15.0:
		natural = grass.lerp(dirt, smoothstep(10.0, 15.0, h))
	elif h < 30.0:
		natural = dirt.lerp(rock, smoothstep(15.0, 30.0, h))
	else:
		natural = rock.lerp(snow, smoothstep(30.0, 45.0, h))

	# The plunge and gorge floor read as bare cliff/rock instead of
	# whatever the height-only gradient above would say on its own -- an
	# immediate swap right at the edge (not a gradual blend).
	if past_edge:
		var wasteland := dirt.lerp(rock, 0.5)
		# The jungle plateau is a raised, lushly-vegetated landform sitting
		# out in the wasteland -- checked here, BEFORE the plain bare-dirt/
		# rock return above takes over, or the whole biome would render as
		# bare ground despite standing above real jungle canopy.
		if world_pos != Vector2.INF:
			var jungle_amount := jungle_coverage(world_pos.x, world_pos.y)
			if jungle_amount > 0.0:
				return wasteland.lerp(jungle_green, jungle_amount)
		return wasteland

	# The canyon biome's own ground color: a second blend, by horizontal
	# distance from canyon_center rather than by height, layered on top of
	# (not replacing) the gradient above -- so canyon-floor dirt still reads
	# whether that particular patch of ground happens to sit low or high.
	# Full dirt well inside the zone (canyon_radius*0.8), smoothly easing back
	# to the ordinary natural color by canyon_radius*1.25 -- generous enough
	# that the transition itself never reads as a hard, visible ring right at
	# the biome's nominal edge.
	if canyon_radius > 0.0 and world_pos != Vector2.INF:
		var dist := world_pos.distance_to(canyon_center)
		var canyon_blend := 1.0 - smoothstep(canyon_radius * 0.8, canyon_radius * 1.25, dist)
		if canyon_blend > 0.0:
			natural = natural.lerp(dirt, canyon_blend)

	return natural


func _sample_normal(x: float, z: float) -> Vector3:
	var e := 1.0
	var h_l := get_height(x - e, z)
	var h_r := get_height(x + e, z)
	var h_d := get_height(x, z - e)
	var h_u := get_height(x, z + e)
	# Y flipped as a direct experiment: swap which face (top vs. the
	# underside you saw when the camera clipped below ground) gets which
	# lighting treatment.
	return Vector3(h_l - h_r, -2.0 * e, h_d - h_u).normalized()


func _build_mesh() -> void:
	var spacing := (FIELD_HALF_SIZE * 2.0) / float(RESOLUTION - 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for iz in RESOLUTION:
		for ix in RESOLUTION:
			var wx := -FIELD_HALF_SIZE + ix * spacing
			var wz := -FIELD_HALF_SIZE + iz * spacing
			var h := get_height(wx, wz)
			var past_edge := _past_edge(wx, wz, Vector2(wx, wz).length())
			st.set_color(_height_color(h, past_edge, Vector2(wx, wz)))
			st.set_normal(_sample_normal(wx, wz))
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
	# Matching the tree leaf material's own values exactly (measured off
	# tree_oak.glb's "leafsGreen": metallic=1.0, roughness=1.0) as a quick
	# test of shading the ground the same way as the trees, rather than the
	# usual diffuse (metallic=0) ground material.
	material.metallic = 1.0
	material.roughness = 1.0
	# Winding order here renders correctly with CULL_BACK, since normals
	# (used for lighting) and winding (used for culling) are independent --
	# an earlier check only verified the former. Disabling culling is the
	# simple, low-risk fix rather than guessing the reversed index order,
	# and now that the camera is clamped above ground (see player.gd,
	# _clamp_camera_above_ground) the underside can never be seen anyway.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	add_child(mesh_instance)


## A low-density water sheet follows the same lake footprint as the basin.
## Its independent, much coarser grid is sufficient for a perfectly flat
## surface and avoids spending terrain-level geometry on open water.
## It has no collision: the lake is currently scenic world geometry, with
## the actual sloping floor still providing the normal terrain collision.
func _build_eastern_lake() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var min_x := LAKE_START_X - LAKE_SURFACE_GROUND_OVERLAP - LAKE_WATER_CELL_SIZE
	var max_x := FIELD_HALF_SIZE
	var max_abs_z := LAKE_WIDE_HALF_WIDTH + LAKE_SURFACE_GROUND_OVERLAP + LAKE_WATER_CELL_SIZE
	var columns := int(ceilf((max_x - min_x) / LAKE_WATER_CELL_SIZE))
	var rows := int(ceilf((max_abs_z * 2.0) / LAKE_WATER_CELL_SIZE))

	for iz in rows:
		for ix in columns:
			var x0 := min_x + ix * LAKE_WATER_CELL_SIZE
			var z0 := -max_abs_z + iz * LAKE_WATER_CELL_SIZE
			var x1 := minf(x0 + LAKE_WATER_CELL_SIZE, max_x)
			var z1 := minf(z0 + LAKE_WATER_CELL_SIZE, max_abs_z)
			var c00 := _lake_surface_coverage(x0, z0)
			var c10 := _lake_surface_coverage(x1, z0)
			var c01 := _lake_surface_coverage(x0, z1)
			var c11 := _lake_surface_coverage(x1, z1)
			# Keep every triangle entirely inside the deliberately oversized
			# water footprint. Its perimeter is already buried under the ground.
			if minf(minf(c00, c10), minf(c01, c11)) <= 0.01:
				continue
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x0, LAKE_WATER_LEVEL, z0))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x0, LAKE_WATER_LEVEL, z1))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x1, LAKE_WATER_LEVEL, z0))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x1, LAKE_WATER_LEVEL, z0))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x0, LAKE_WATER_LEVEL, z1))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x1, LAKE_WATER_LEVEL, z1))

	var material := StandardMaterial3D.new()
	# Render the large lake in the opaque pass. Unlike the small fountain,
	# transparent blending across a full vista is expensive; the water-blorb
	# blue stays intact and the deep floor is not needed for gameplay reading.
	material.albedo_color = Color(
		TownProps.WATER_COLOR.r, TownProps.WATER_COLOR.g, TownProps.WATER_COLOR.b, 1.0
	)
	material.roughness = 0.05
	material.metallic = 0.15
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var lake := MeshInstance3D.new()
	lake.name = "EasternLake"
	lake.mesh = st.commit()
	lake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lake)


## Flat annulus from SKIRT_INNER_RADIUS out to SKIRT_OUTER_RADIUS, at a
## constant y = -GORGE_DEPTH -- closes the visual gap between the gorge
## floor's outer rim and distant_mountains.gd's ring so the terrain reads as
## running continuously underneath the mountains rather than stopping short
## of them. No collision: nothing out here is reachable (it's well past the
## edge barrier), same reasoning distant_mountains.gd uses for having none.
func _build_far_skirt() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var color := _height_color(-GORGE_DEPTH, true)
	st.set_color(color)
	st.set_normal(Vector3.UP)

	for i in SKIRT_SEGMENTS:
		var a0 := (float(i) / SKIRT_SEGMENTS) * TAU
		var a1 := (float(i + 1) / SKIRT_SEGMENTS) * TAU
		var inner0 := Vector3(cos(a0) * SKIRT_INNER_RADIUS, -GORGE_DEPTH, sin(a0) * SKIRT_INNER_RADIUS)
		var inner1 := Vector3(cos(a1) * SKIRT_INNER_RADIUS, -GORGE_DEPTH, sin(a1) * SKIRT_INNER_RADIUS)
		var outer0 := Vector3(cos(a0) * SKIRT_OUTER_RADIUS, -GORGE_DEPTH, sin(a0) * SKIRT_OUTER_RADIUS)
		var outer1 := Vector3(cos(a1) * SKIRT_OUTER_RADIUS, -GORGE_DEPTH, sin(a1) * SKIRT_OUTER_RADIUS)

		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.add_vertex(inner0)
		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.add_vertex(outer0)
		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.add_vertex(outer1)

		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.add_vertex(inner0)
		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.add_vertex(outer1)
		st.set_color(color)
		st.set_normal(Vector3.UP)
		st.add_vertex(inner1)

	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.metallic = 1.0
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	add_child(mesh_instance)


func _grid_vertex(ix: int, iz: int, spacing: float) -> Vector3:
	var wx := -FIELD_HALF_SIZE + ix * spacing
	var wz := -FIELD_HALF_SIZE + iz * spacing
	return Vector3(wx, get_height(wx, wz), wz)


## Same underlying height field as get_height(), but snapped to the exact
## piecewise-planar surface _build_mesh()/_build_terrain_collision() are
## actually built from, rather than the raw continuous noise formula.
## RESOLUTION's ~8m grid spacing means the two can disagree by a visible
## amount between grid vertices -- the true noise curve can bulge above or
## dip below the flat triangle connecting its neighbors there -- which is
## exactly what made the player visibly float over (or clip into) ground
## that blorbs glided along cleanly at the same spot: blorb.gd's own
## -EMBED_DEPTH offset happened to absorb an error of about this size,
## masking it there, but it was never actually smaller for blorbs than for
## the player. Anything that needs to visually sit flush with the
## rendered/collision surface every frame (player/NPC/blorb ground-follow,
## the camera's ground clamp) should call this, not get_height() directly.
## get_height() stays the raw analytic source of truth _grid_vertex()
## itself is built from -- this function is derived from it, not a
## replacement for it.
func get_mesh_height(x: float, z: float) -> float:
	var spacing := (FIELD_HALF_SIZE * 2.0) / float(RESOLUTION - 1)
	var span := FIELD_HALF_SIZE * 2.0
	# Clamped defensively so a query past the mesh's own covered range
	# can't index out of bounds -- nothing reachable actually queries out
	# here (see SKIRT_INNER_RADIUS's own comment: get_height() is already
	# flat well inside this range), so the clamp never changes the answer
	# for any legitimate caller.
	var local_x := clampf(x + FIELD_HALF_SIZE, 0.0, span - 0.001)
	var local_z := clampf(z + FIELD_HALF_SIZE, 0.0, span - 0.001)
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

	# Matches _build_mesh()'s own triangle split for this quad exactly --
	# its index order (i0,i2,i1 / i1,i2,i3) splits along the v01-v10
	# diagonal, not v00-v11, so a plain bilinear lerp across all 4 corners
	# would quietly disagree with the real mesh near that diagonal.
	if tx + tz <= 1.0:
		return _plane_height(v00, v01, v10, x, z)
	else:
		return _plane_height(v10, v01, v11, x, z)


## Upward normal of the exact rendered/collision triangle containing XZ.
## This is the orientation companion to get_mesh_height(): sampling the raw
## noise gradient would disagree with the broad piecewise-planar mesh that a
## sliding creature is visibly resting on.
func get_mesh_normal(x: float, z: float) -> Vector3:
	var spacing := (FIELD_HALF_SIZE * 2.0) / float(RESOLUTION - 1)
	var span := FIELD_HALF_SIZE * 2.0
	var local_x := clampf(x + FIELD_HALF_SIZE, 0.0, span - 0.001)
	var local_z := clampf(z + FIELD_HALF_SIZE, 0.0, span - 0.001)
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
	var normal: Vector3
	if tx + tz <= 1.0:
		normal = (v01 - v00).cross(v10 - v00).normalized()
	else:
		normal = (v01 - v10).cross(v11 - v10).normalized()
	return normal if normal.y >= 0.0 else -normal


## Height of the plane through 3 (generally non-axis-aligned) points at a
## given (x, z), via barycentric weights projected onto the XZ plane --
## exact for the planar triangles the mesh/collision are built from, unlike
## a bilinear lerp.
func _plane_height(a: Vector3, b: Vector3, c: Vector3, x: float, z: float) -> float:
	var denom := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	var w_a := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / denom
	var w_b := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / denom
	var w_c := 1.0 - w_a - w_b
	return w_a * a.y + w_b * b.y + w_c * c.y


## Real mesh collision: a single ConcavePolygonShape3D built from exactly
## the same vertex grid _build_mesh() renders (same _grid_vertex() calls, so
## the two surfaces are identical by construction, not just visually close)
## -- eliminating any possibility of the collision/visual mismatch that
## previously caused floating/clipping near uneven ground and, worse, at the
## cliff.
##
## backface_collision = true is required and easy to miss: this grid's
## winding (i0,i2,i1 / i1,i2,i3, matching _build_mesh()) is the same
## "reversed" one that needed CULL_DISABLED to render at all, and
## ConcavePolygonShape3D silently ignores hits against backfaces by default.
## Confirmed via a minimal, dependency-free repro (tools/test_concave_
## collision.gd): a downward raycast against this winding MISSES every time
## without the flag and HITs at the exact expected height with it. This is
## the real explanation for the earlier finding (project memory) that
## concave/heightmap shapes "don't register any collision at all" here --
## that repro never tried backface_collision, so it looked like a hard
## engine limitation rather than one missing property.
func _build_terrain_collision() -> void:
	var spacing := (FIELD_HALF_SIZE * 2.0) / float(RESOLUTION - 1)
	var faces := PackedVector3Array()
	for iz in RESOLUTION - 1:
		for ix in RESOLUTION - 1:
			var v00 := _grid_vertex(ix, iz, spacing)
			var v10 := _grid_vertex(ix + 1, iz, spacing)
			var v01 := _grid_vertex(ix, iz + 1, spacing)
			var v11 := _grid_vertex(ix + 1, iz + 1, spacing)
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
