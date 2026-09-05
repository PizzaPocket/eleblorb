extends Node3D

## Jungle vegetation for the primate kingdom (see kingdom_bootstrap.gd) --
## a random-disk scatter of NatureProps' jungle tree species plus ground
## decor, dense enough to read as "a thick tree canopy equal to the jungle
## biome in the crossroads kingdom" per direct feedback (see
## wilderness_scatter.gd's own _build_jungle_biome(), the density this
## matches). CLEAR_RADIUS keeps the scatter out of JungleVillage's own
## footprint near the spawn point; RIVER/CLEARING/ROCKY zones (queried from
## jungle_kingdom_terrain.gd and the local zone lists below) break up the
## canopy with open ground, rocky outcrops, and the carved river, also per
## direct feedback, instead of one uniform wall of trees.
##
## At this density a flat, always-simulated scatter would chug: thousands
## of multi-mesh procedural trees is a real render/physics cost even with
## the mountain-ring-scale terrain mostly empty around them. Two
## complementary techniques keep it cheap regardless of total prop count,
## both applied once at build time (no per-frame cost beyond the one
## lightweight distance scan below):
## - Every prop's meshes get a GeometryInstance3D.visibility_range_end, so
##   the GPU itself skips drawing anything far from the camera -- this is
##   the primary lever, since it bounds render cost by what's actually
##   nearby, not by total scene population.
## - Collision layers sleep beyond LOD_COLLISION_RADIUS of the player (same
##   distance-scan technique as wilderness_scatter.gd's own
##   _update_wilderness_lod(), just scoped to this node instead of the
##   whole outskirts world), so far-away physics bodies stop costing
##   broadphase time.

const RADIUS := 420.0
const CLEAR_CENTER := Vector2.ZERO
const CLEAR_RADIUS := 24.0
## Cut roughly in half (was 1200/3000) -- per direct report ("the primate
## kingdom is extremely laggy and takes forever to load"). This is the
## actual dominant cost of that: every one of these 4200 (now ~2000) props
## is a real SurfaceTool-built mesh constructed synchronously at scene load,
## well before the LOD system below (visibility_range_end/collision sleep)
## can do anything -- that system only ever helps steady-state RENDER cost
## once the props already exist, not how long building them all takes in
## the first place. Reducing the villager/ape population elsewhere in this
## kingdom (see jungle_kingdom_village.gd's own recent cuts) addressed a
## real but much smaller cost next to this; this is the one actually worth
## cutting hard. Still a meaningfully dense canopy at these counts, just not
## "equal to the crossroads jungle biome" dense any more -- see this file's
## own class doc comment for that original density target.
const TREE_COUNT := 600
const DECOR_COUNT := 1200

## Circular clearings -- open ground (grass/flowers only, no trees) breaking
## up the canopy, per direct feedback. Fixed hand-placed spots rather than
## noise-driven, so they read as distinct destinations worth walking to.
const CLEARINGS := [
	{"center": Vector2(210.0, -170.0), "radius": 45.0},
	{"center": Vector2(-250.0, 90.0), "radius": 50.0},
	{"center": Vector2(110.0, 300.0), "radius": 40.0},
	{"center": Vector2(-160.0, -280.0), "radius": 55.0},
]
## Rocky outcrops -- NatureProps' rock/spire props instead of trees.
const ROCKY_ZONES := [
	{"center": Vector2(280.0, 40.0), "radius": 38.0},
	{"center": Vector2(-90.0, 220.0), "radius": 32.0},
	{"center": Vector2(60.0, -260.0), "radius": 42.0},
]
const ROCKS_PER_ZONE := 14

const TREE_VISIBILITY_RANGE := 260.0
const DECOR_VISIBILITY_RANGE := 110.0
const ROCK_VISIBILITY_RANGE := 200.0
const LOD_COLLISION_RADIUS := 130.0
const LOD_UPDATE_INTERVAL := 0.4

var _rng := RandomNumberGenerator.new()
var _terrain: Node = null
var _lod_colliders: Array[CollisionObject3D] = []
var _lod_timer := 0.0
## One-way walkable tree-canopy support -- same technique/contract as
## wilderness_scatter.gd's own _canopy_blobs/get_support_height_at(), which
## player.gd/blorb.gd already call on a "../Scatter" sibling (see this
## node's own name in primate_kingdom.tscn, matching that sibling lookup).
## Per direct feedback, treetop platforming is "the key fun" of this
## kingdom, so it needs the same working support the outskirts jungle
## biome's canopy already has, not a copy that silently never gets queried.
var _canopy_blobs: Array[Dictionary] = []

var _tree_builders: Array = [
	func(): return NatureProps.build_palm_tree(15.0, _rng.randf_range(0.12, 0.28), _rng),
	func(): return NatureProps.build_banyan_tree(_rng.randf_range(14.0, 26.0), _rng),
	func(): return NatureProps.build_baobab_tree(_rng.randf_range(13.0, 22.0), _rng),
	func(): return NatureProps.build_durian_tree(_rng.randf_range(10.0, 18.0), _rng),
	func(): return NatureProps.build_banana_tree(_rng.randf_range(5.0, 8.0), _rng),
	func(): return NatureProps.build_flowering_tree(
		_rng.randf_range(12.0, 22.0), NatureProps.JUNGLE_LEAF_COLORS[0], Color(0.95, 0.6, 0.8), _rng
	),
]
var _decor_builders: Array = [
	func(): return NatureProps.build_bush(NatureProps.JUNGLE_LEAF_COLORS[1]),
	func(): return NatureProps.build_grass_tuft(NatureProps.JUNGLE_LEAF_COLORS[2]),
	func(): return NatureProps.build_flower(NatureProps.FLOWER_COLORS["Orchid"]),
	func(): return NatureProps.build_mushroom(NatureProps.MUSHROOM_COLORS["Jungle Mushroom"]),
]
## Clearings only get the light ground layer -- no bushes/mushrooms -- so
## they read as open meadow rather than just a thinner patch of jungle.
var _clearing_decor_builders: Array = [
	func(): return NatureProps.build_grass_tuft(NatureProps.JUNGLE_LEAF_COLORS[2]),
	func(): return NatureProps.build_flower(NatureProps.FLOWER_COLORS["Orchid"]),
]


func _ready() -> void:
	_rng.seed = 20260818
	_terrain = get_node_or_null("../Terrain")
	_scatter_trees()
	_scatter_decor()
	_scatter_rocks()
	_register_lod_colliders(self)


func _process(delta: float) -> void:
	_lod_timer -= delta
	if _lod_timer <= 0.0:
		_lod_timer = LOD_UPDATE_INTERVAL
		_update_lod()


func _scatter_trees() -> void:
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	for i in TREE_COUNT:
		var picked: Variant = _pick_position()
		if picked == null:
			continue
		var pos: Vector2 = picked
		if _zone_of(pos) != "":
			continue  # clearings and rocky zones stay tree-free
		var builder: Callable = _tree_builders[_rng.randi() % _tree_builders.size()]
		_place(builder.call(), pos, TREE_VISIBILITY_RANGE)


func _scatter_decor() -> void:
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	for i in DECOR_COUNT:
		var picked: Variant = _pick_position()
		if picked == null:
			continue
		var pos: Vector2 = picked
		var zone := _zone_of(pos)
		if zone == "rocky" or zone == "river":
			continue
		var builders := _clearing_decor_builders if zone == "clearing" else _decor_builders
		var builder: Callable = builders[_rng.randi() % builders.size()]
		_place(builder.call(), pos, DECOR_VISIBILITY_RANGE)


func _scatter_rocks() -> void:
	for zone in ROCKY_ZONES:
		var center: Vector2 = zone["center"]
		var radius: float = zone["radius"]
		for i in ROCKS_PER_ZONE:
			var r := sqrt(_rng.randf_range(0.0, 1.0)) * radius
			var a := _rng.randf_range(0.0, TAU)
			var pos := center + Vector2(cos(a) * r, sin(a) * r)
			var prop: Node3D = NatureProps.build_rock_spire(
				_rng.randf_range(1.4, 3.2), _rng.randi_range(2, 4), _rng
			) if _rng.randf() < 0.35 else NatureProps.build_rock(_rng.randf_range(0.8, 2.4))
			_place(prop, pos, ROCK_VISIBILITY_RANGE)


func _place(prop: Node3D, pos: Vector2, visibility_range: float) -> void:
	var y: float = _terrain.get_mesh_height(pos.x, pos.y)
	prop.position = Vector3(pos.x, y, pos.y)
	prop.rotation.y = _rng.randf_range(0.0, TAU)
	add_child(prop)
	_apply_visibility_range(prop, visibility_range)
	_register_canopy_blobs(prop)


## "" outside every special zone, "river"/"clearing"/"rocky" otherwise --
## clearings/rocky zones can't overlap in this hand-placed list, so first
## match wins.
func _zone_of(pos: Vector2) -> String:
	if _terrain.has_method("river_coverage") and _terrain.river_coverage(pos.x, pos.y) > 0.05:
		return "river"
	for clearing in CLEARINGS:
		if pos.distance_to(clearing["center"]) < float(clearing["radius"]):
			return "clearing"
	for zone in ROCKY_ZONES:
		if pos.distance_to(zone["center"]) < float(zone["radius"]):
			return "rocky"
	return ""


## Uniform placement across the disk (sqrt of a uniform radius fraction, per
## the standard equal-area sampling technique), redrawn up to a few times if
## it lands inside the village's clear zone rather than pushed outward --
## simpler, and the loss of a few points to a retry is invisible at this
## density.
func _pick_position() -> Variant:
	for attempt in 5:
		var r := sqrt(_rng.randf_range(0.0, 1.0)) * RADIUS
		var a := _rng.randf_range(0.0, TAU)
		var pos := Vector2(cos(a) * r, sin(a) * r)
		if pos.distance_to(CLEAR_CENTER) >= CLEAR_RADIUS:
			return pos
	return null


## Recursively caps how far each mesh renders -- the actual "never chugs"
## lever, since it bounds GPU draw cost by what's near the camera rather
## than by how many thousand props exist in the scene. Fade mode softens
## the cutoff into a dither fade instead of a hard pop.
func _apply_visibility_range(node: Node, range_end: float) -> void:
	if node is GeometryInstance3D:
		var geometry := node as GeometryInstance3D
		geometry.visibility_range_end = range_end
		geometry.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for child in node.get_children():
		_apply_visibility_range(child, range_end)


## Same collision-sleep technique as wilderness_scatter.gd's own
## _register_wilderness_lod_nodes()/_update_wilderness_lod() (see that
## file), scoped to this node's own props instead of the whole outskirts
## world. Meshes stay rendered (visibility_range_end above already handles
## draw cost); only broadphase collision sleeps far from the player.
func _register_lod_colliders(node: Node) -> void:
	for child in node.get_children():
		if child is CollisionObject3D and not _lod_colliders.has(child):
			var collider := child as CollisionObject3D
			collider.set_meta("lod_collision_layer", collider.collision_layer)
			_lod_colliders.append(collider)
		_register_lod_colliders(child)


func _update_lod() -> void:
	var player := get_node_or_null("../Player") as Node3D
	if player == null:
		return
	for collider in _lod_colliders:
		if not is_instance_valid(collider):
			continue
		var active: bool = collider.global_position.distance_to(player.global_position) <= LOD_COLLISION_RADIUS
		collider.collision_layer = int(collider.get_meta("lod_collision_layer")) if active else 0


## Resolves `instance`'s own NatureProps-authored canopy blobs (see that
## file's _add_canopy_blob()) to world space, once, right after it's placed
## -- verbatim copy of wilderness_scatter.gd's own _register_canopy_blobs(),
## since trees never move again afterward. A no-op for decor/rock props,
## which carry no "canopy_blobs" meta.
func _register_canopy_blobs(instance: Node3D) -> void:
	if not instance.has_meta("canopy_blobs"):
		return
	var uniform_scale: float = instance.scale.x
	for blob in (instance.get_meta("canopy_blobs") as Array):
		_canopy_blobs.append({
			"center": instance.to_global(blob["local_pos"]),
			"axes": (blob["semi_axes"] as Vector3) * uniform_scale,
		})


## Highest walkable tree-canopy top at this XZ position, no higher than
## max_surface_y -- verbatim copy of wilderness_scatter.gd's own
## get_support_height_at() (see that function's own doc comment for the
## one-way support math): the exact contract player.gd's
## _tree_canopy_stand_height_at() and blorb.gd's _ground_height_at() query
## on a "../Scatter" sibling.
func get_support_height_at(world_x: float, world_z: float, max_surface_y: float = INF) -> Variant:
	var best: Variant = null
	for blob in _canopy_blobs:
		var center: Vector3 = blob["center"]
		var axes: Vector3 = blob["axes"]
		var horizontal_profile := (
			pow(absf((world_x - center.x) / axes.x), SuperEgg.EPSILON_SOFT)
			+ pow(absf((world_z - center.z) / axes.z), SuperEgg.EPSILON_SOFT)
		)
		if horizontal_profile > 1.0:
			continue
		var top := center.y + axes.y * pow(1.0 - horizontal_profile, 1.0 / SuperEgg.EPSILON_SOFT)
		if top <= max_surface_y and (best == null or top > best):
			best = top
	return best
