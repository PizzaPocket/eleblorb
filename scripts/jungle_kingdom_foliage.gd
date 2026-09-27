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
## Window mode is a self-contained biome, not a statistical sample of the
## kingdom's much larger disk. Populate this many successful tree positions
## inside the demo slice itself; filtering TREE_COUNT disk samples previously
## left only a small fraction and made the "jungle" read as a clearing.
## Dense enough to retain a closed jungle canopy, but with enough separation
## between trunks for a player, mount, or swinging body to steer through it.
const DEMO_WINDOW_TREE_COUNT := 250
const DEMO_TALL_TREE_CHANCE := 0.28

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

## Window mode (used by the demo world's plant biome): scatter this kingdom's
## jungle exactly as usual, with the same density, species mix, clearings and
## rocky zones in the kingdom's own coordinates, but build only the props that
## fall inside the rectangle of `window_half_size` around
## `window_source_center`, and place each at the matching point around
## `window_target_center` in the host world. Matches TerrainWindow at scale 1.
@export var window_enabled := false
@export var window_source_center := Vector2.ZERO
@export var window_half_size := Vector2.ZERO
@export var window_target_center := Vector2.ZERO
## Host-world discs (x, z, radius) that window mode keeps free of trees and
## rocks: room for something large to roam, such as the demo's Da Hou Zi.
@export var window_keep_clear: Array[Vector3] = []
## A keep-clear disc can still carry a deliberately spaced ring of emergent
## vine anchors. Their trunks stay outside the protected roaming core; only
## their high canopies reach across it.
@export var window_keep_clear_jumbo_trees := false
## Boxes nothing at all may stand in, vine anchors included: a portal gate is
## the case this exists for. Each is (centre x, centre z, half depth in x, half
## width in z). A box rather than a disc because a gate is a doorway: the demo's
## portals are 60 m wide (PORTAL_HALF_WIDTH), so a disc big enough to clear one
## would carve a bald 72 m circle out of the forest at every border, while a
## shallow wide box clears the opening and nothing else. A keep-clear disc above
## is the titan kind, which anchors may enter beyond its roaming core; these are
## absolute.
@export var window_gate_clear: Array[Vector4] = []

## Trees had no separation rule of any kind, so the scatter could and did put
## two trunks 0.4 m apart, and 135 pairs in the demo window stood closer than
## one of their own crowns. A crown is wide, so the room a tree needs scales
## with how big it is: measured on the built window, ordinary canopy species
## reach 4 to 9 m and an emergent's crown reaches past 17 m.
const TREE_MIN_SEPARATION := 9.0
const TALL_MIN_SEPARATION := 15.0
const GIANT_MIN_SEPARATION := 30.0

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
## Every trunk already standing, as (x, z, the room it claimed).
var _claimed: Array[Vector3] = []
var _canopy_blobs: Array[Dictionary] = []
## The box enclosing every canopy blob, grown as they register.
var _canopy_bounds := AABB()

## Each species' own ordinary height, multiplied per individual by the shared
## jungle height distribution (NatureProps.jungle_height_stretch()), so a stand
## of one species is layered rather than level. The fruiting understorey
## species keep their own scale: a banana tree is not a canopy tree.
var _tree_builders: Array = [
	func(): return NatureProps.build_palm_tree(
		15.0 * NatureProps.species_height_stretch(NatureProps.SLENDER_STRETCH, _rng),
		_rng.randf_range(0.12, 0.28), _rng
	),
	func(): return NatureProps.build_banyan_tree(
		_rng.randf_range(14.0, 26.0)
		* NatureProps.species_height_stretch(NatureProps.BROAD_STRETCH, _rng), _rng
	),
	# The baobab's trunk is the fattest here and scaling it up reads as a
	# scaled-up model, not a taller tree. Its own band varies it instead.
	func(): return NatureProps.build_baobab_tree(_rng.randf_range(13.0, 22.0), _rng),
	func(): return NatureProps.build_durian_tree(
		_rng.randf_range(10.0, 18.0)
		* NatureProps.species_height_stretch(NatureProps.BROAD_STRETCH, _rng), _rng
	),
	func(): return NatureProps.build_banana_tree(_rng.randf_range(5.0, 8.0), _rng),
	func(): return NatureProps.build_flowering_tree(
		_rng.randf_range(12.0, 22.0)
		* NatureProps.species_height_stretch(NatureProps.BROAD_STRETCH, _rng),
		NatureProps.JUNGLE_LEAF_COLORS[0], Color(0.95, 0.6, 0.8), _rng
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
	# The route's own anchors and the titan ring are laid first: they have a
	# job to do, so they claim their room before the random fill takes it.
	_scatter_vine_swing_trees()
	_scatter_keep_clear_jumbo_trees()
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
	if window_enabled:
		_scatter_window_trees()
		return
	for i in TREE_COUNT:
		var picked: Variant = _pick_position()
		if picked == null:
			continue
		var pos: Vector2 = picked
		if not _in_window(pos):
			continue
		if _zone_of(pos) != "" or _kept_clear(pos):
			continue  # clearings and rocky zones stay tree-free
		if not _gate_clear(pos):
			continue
		if NatureProps.rolls_jungle_emergent(_rng):
			if not _claim_room(pos, GIANT_MIN_SEPARATION):
				continue
			_place(NatureProps.build_wild_emergent_tree(_rng), pos, 380.0)
			continue
		if not _claim_room(pos, TREE_MIN_SEPARATION):
			continue
		var builder: Callable = _tree_builders[_rng.randi() % _tree_builders.size()]
		_place(builder.call(), pos, TREE_VISIBILITY_RANGE)


## The window's emergents, laid before the ordinary canopy rather than rolled
## inside it. Rolled inside it they competed for ground the smaller trees had
## already taken, and a jungle meant to be full of giants had a dozen.
func _scatter_window_emergents() -> void:
	var target := int(round(float(DEMO_WINDOW_TREE_COUNT) * NatureProps.JUNGLE_EMERGENT_CHANCE))
	var attempts := 0
	var placed := 0
	while placed < target and attempts < target * 24:
		attempts += 1
		var pos := window_source_center + Vector2(
			_rng.randf_range(-window_half_size.x, window_half_size.x),
			_rng.randf_range(-window_half_size.y, window_half_size.y)
		)
		if _zone_of(pos) != "" or _kept_clear(pos) or not _gate_clear(pos):
			continue
		if absf(pos.y - window_source_center.y) < 4.5:
			continue
		if not _claim_room(pos, GIANT_MIN_SEPARATION):
			continue
		_place(NatureProps.build_wild_emergent_tree(_rng), pos, 380.0)
		placed += 1


func _scatter_window_trees() -> void:
	_scatter_window_emergents()
	var placed := 0
	var attempts := 0
	while placed < DEMO_WINDOW_TREE_COUNT and attempts < DEMO_WINDOW_TREE_COUNT * 12:
		attempts += 1
		var pos := window_source_center + Vector2(
			_rng.randf_range(-window_half_size.x, window_half_size.x),
			_rng.randf_range(-window_half_size.y, window_half_size.y)
		)
		if _zone_of(pos) != "" or _kept_clear(pos):
			continue
		# Preserve only a narrow readable thread through the forest. The former
		# sparse generator effectively cleared the entire biome, not merely a path.
		if absf(pos.y - window_source_center.y) < 4.5 and _rng.randf() < 0.82:
			continue
		if not _gate_clear(pos):
			continue
		var tree: Node3D
		if _rng.randf() < DEMO_TALL_TREE_CHANCE:
			if not _claim_room(pos, TALL_MIN_SEPARATION):
				continue
			match _rng.randi() % 3:
				0:
					tree = NatureProps.build_palm_tree(
						_rng.randf_range(24.0, 34.0), _rng.randf_range(0.08, 0.24), _rng
					)
				1:
					tree = NatureProps.build_banyan_tree(_rng.randf_range(26.0, 36.0), _rng)
				_:
					# This branch exists to make TALL trees, so it asks a species
					# that reads well tall. It used to ask for a 25 to 34 m
					# baobab, whose trunk at that size is a wall.
					tree = NatureProps.build_flowering_tree(
						_rng.randf_range(25.0, 33.0),
						NatureProps.JUNGLE_LEAF_COLORS[0], Color(0.95, 0.6, 0.8), _rng
					)
		else:
			if not _claim_room(pos, TREE_MIN_SEPARATION):
				continue
			var builder: Callable = _tree_builders[_rng.randi() % _tree_builders.size()]
			tree = builder.call() as Node3D
		_place(tree, pos, TREE_VISIBILITY_RANGE)
		placed += 1


## A chain of true emergent trees along the demo route gives the Leaf Hat real,
## readable overhead anchors. These are not invisible traversal markers: their
## collidable trunks and limbs are the exact geometry the vine's ray fan must
## strike, and the ordinary random canopy remains between them.
##
## The spacing is derived from the vine's own reach rather than chosen as a
## round number, because the requirement is precisely that the next anchor is
## catchable from the last. Ten trees spread over the whole window averaged
## nearly forty metres apart and wandered a hundred more across it, so a swing
## begun at the portal ran out of anywhere to go almost immediately.
##
## They alternate sides of the route's own clear thread, which both keeps their
## trunks out of the walking line and gives the swing its left-right rhythm.
## Spacing and offset together have to keep CONSECUTIVE anchors inside one
## rope's length, which is the diagonal between them and not the spacing alone.
## Fixed stations along the route could not do it: most of them landed in a
## clearing or a rocky patch and were dropped, leaving four anchors and a gap of
## 266 metres. So the chain is grown instead of laid out. Each anchor looks
## ahead for the nearest valid ground within one rope of the last one, trying
## the route's own thread first and reaching further out only as it must.
## Stepped out for the longer rope and, more to the point, for the crowns: at
## 22 m apart, emergents whose crowns reach past 17 m grew straight through one
## another and walled the route in.
const VINE_ROUTE_STEPS := [33.0, 28.0, 38.0, 44.0]
const VINE_ROUTE_LATERALS := [9.0, 13.0, 17.0]
## The rope's own length less a margin, since the thrower is never exactly
## under the anchor it is reaching from.
const VINE_ROUTE_MAX_GAP := VineSwingMode.MAX_ROPE * 0.85
## Nothing usable ahead: step past it and pick the chain up on the far side.
## The titan clearing is the one place this happens by design, and it carries
## its own ring of anchors.
const VINE_ROUTE_SKIP := 26.0
const VINE_ROUTE_MAX_ANCHORS := 40
## A keep-clear disc excludes ordinary trunks out to its full radius, which
## protects the terrain flattening and the titan's own sightlines. His route is
## a fraction of that: the existing anchor ring already stands at 62 to 70 m
## inside the same disc for exactly this reason. Excluding vine anchors out to
## the full 145 m rejected 346 of 424 candidate spots along the demo route,
## which is the dead end that appeared right after the portal. So the chain
## keeps out of his roaming core and is free beyond it.
## Measured against his own stride rather than guessed: GORILLA_ROAM_RADIUS is
## 42 m, so a trunk 46 m from the middle of his clearing stands just outside
## where he actually walks. It was 66, which sounds cautious until you notice the
## route's own thread passes about 51 m from that middle: the chain was therefore
## barred from the whole stretch his clearing crosses, and a swing coming east ran
## out of anywhere to go right there. Ordinary trees still keep their full
## distance (TITAN_ROAM_KEEP_CLEAR); this is only for the anchors the route needs.
const VINE_ROUTE_TITAN_CORE := 46.0
## The ring of anchors around a titan's clearing. Ten rather than six, at uneven
## angles so it reads as a treeline and not as a fence, standing just outside his
## roaming room: the clearing was noticeably bare around its edges with six.
const TITAN_RING_MARGIN := 9.0
const TITAN_RING_ANGLES := [
	-2.95, -2.41, -1.88, -1.31, -0.74, -0.16, 0.42, 1.06, 1.74, 2.44,
]
## Route anchors are deliberately at the top of the emergent range: everything
## else in the biome varies in height, but these have to be reliably throwable.
const VINE_ROUTE_HEIGHT_MIN := 44.0
const VINE_ROUTE_HEIGHT_MAX := 54.0


func _scatter_vine_swing_trees() -> void:
	if not window_enabled or _terrain == null:
		return
	var span := window_half_size.x * 0.9
	var thread := window_source_center.y
	var finish := window_source_center.x + span
	var cursor := window_source_center.x - span
	var previous := Vector2.ZERO
	var chained := false
	var placed := 0
	while cursor <= finish and placed < VINE_ROUTE_MAX_ANCHORS:
		var chosen := Vector2.ZERO
		var found := false
		for step: float in VINE_ROUTE_STEPS:
			for lateral: float in VINE_ROUTE_LATERALS:
				for side: float in [1.0, -1.0]:
					var candidate := Vector2(
						cursor + step + _rng.randf_range(-2.0, 2.0), thread + side * lateral
					)
					if not _in_window(candidate) or not _clear_of_titan_core(candidate):
						continue
					if not _gate_clear(candidate):
						continue
					if _zone_of(candidate) != "":
						continue
					if chained and previous.distance_to(candidate) > VINE_ROUTE_MAX_GAP:
						continue
					chosen = candidate
					found = true
					break
				if found:
					break
			if found:
				break
		if not found:
			cursor += VINE_ROUTE_SKIP
			chained = false
			continue
		# The chain is laid before the random scatter, so it claims its room
		# first and the ordinary trees fill in around it.
		_claim_room(chosen, GIANT_MIN_SEPARATION)
		var built: Dictionary = NatureProps.build_emergent_tree(
			_rng.randf_range(VINE_ROUTE_HEIGHT_MIN, VINE_ROUTE_HEIGHT_MAX), _rng, false
		)
		var tree := built["body"] as StaticBody3D
		tree.name = "VineSwingEmergent%d" % placed
		tree.set_meta("vine_swing_anchor", true)
		_place(tree, chosen, 380.0)
		previous = chosen
		chained = true
		cursor = chosen.x
		placed += 1


## Whether an anchor may stand here: outside every keep-clear disc's roaming
## core, rather than outside the whole disc. See VINE_ROUTE_TITAN_CORE.
func _clear_of_titan_core(pos: Vector2) -> bool:
	if not window_enabled:
		return true
	var host := window_target_center + (pos - window_source_center)
	for disc in window_keep_clear:
		var core: float = minf(VINE_ROUTE_TITAN_CORE, float(disc.z))
		if host.distance_to(Vector2(disc.x, disc.y)) < core:
			return false
	return true


## The demo titan clearing cannot be an empty dead zone: place a handful of
## true jumbo trees around its roaming core. Fixed angular spacing keeps the
## result organic but guarantees Da Hou Zi never meets a trunk on his route.
func _scatter_keep_clear_jumbo_trees() -> void:
	if not window_enabled or not window_keep_clear_jumbo_trees or _terrain == null:
		return
	for disc in window_keep_clear:
		var host_center := Vector2(disc.x, disc.y)
		var protected_radius := float(disc.z)
		# His 30 m route plus his titan-scale body has generous clearance at 66 m.
		# Do not follow the full 145 m terrain-flattening radius: the demo window is
		# narrower than that, and the canopy should remain visible from the route.
		# Just outside his roaming room, so his route stays clear while the ring
		# still reads as the edge of the clearing rather than a distant treeline.
		var ring_radius := protected_radius + TITAN_RING_MARGIN
		var angles := TITAN_RING_ANGLES
		for index in angles.size():
			var angle: float = angles[index]
			var host_pos := host_center + Vector2(cos(angle), sin(angle)) * ring_radius
			var source_pos := window_source_center + (host_pos - window_target_center)
			if not _in_window(source_pos):
				continue
			if not _claim_room(source_pos, GIANT_MIN_SEPARATION):
				continue
			var built: Dictionary = NatureProps.build_emergent_tree(
				_rng.randf_range(44.0, 54.0), _rng, false
			)
			var tree := built["body"] as StaticBody3D
			tree.name = "TitanClearingEmergent%d" % index
			tree.set_meta("vine_swing_anchor", true)
			_place(tree, source_pos, 380.0)


func _scatter_decor() -> void:
	if _terrain == null or not _terrain.has_method("get_mesh_height"):
		return
	for i in DECOR_COUNT:
		var picked: Variant = _pick_position()
		if picked == null:
			continue
		var pos: Vector2 = picked
		if not _in_window(pos):
			continue
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
			if not _in_window(pos) or _kept_clear(pos):
				continue
			var prop: Node3D = NatureProps.build_rock_spire(
				_rng.randf_range(1.4, 3.2), _rng.randi_range(2, 4), _rng
			) if _rng.randf() < 0.35 else NatureProps.build_rock(_rng.randf_range(0.8, 2.4))
			_place(prop, pos, ROCK_VISIBILITY_RANGE)


## Whether a trunk of this size has room here, and claiming it if so. Called
## once per placement: a tree that cannot claim its room is not placed.
##
## A pair needs the MEAN of the two claims between them, not the larger. Taking
## the larger meant a giant had to stand its own full 30 m clear of every sapling
## as well as of every other giant, so once the ordinary scatter had filled in,
## emergents were crowded out almost entirely: raising their rate fivefold moved
## the count from 14 to 15. It also matched nothing real, since undergrowth grows
## right up to a big trunk. The mean keeps giant from giant at the full 30 m,
## lets a small tree come within about 20 m of one, and leaves ordinary trees at
## their own 9 m.
func _claim_room(pos: Vector2, separation: float) -> bool:
	for taken in _claimed:
		var apart: float = pos.distance_to(Vector2(taken.x, taken.y))
		if apart < (separation + taken.z) * 0.5:
			return false
	_claimed.append(Vector3(pos.x, pos.y, separation))
	return true


## Whether anything at all may stand here. A portal gate has to stay open: the
## scatter was putting three trunks inside the plant gate and eight inside the
## water gate, measured on the built window.
func _gate_clear(pos: Vector2) -> bool:
	if not window_enabled:
		return true
	var host := window_target_center + (pos - window_source_center)
	for gate in window_gate_clear:
		if absf(host.x - gate.x) < gate.z and absf(host.y - gate.y) < gate.w:
			return false
	return true


func _in_window(pos: Vector2) -> bool:
	if not window_enabled:
		return true
	var local := pos - window_source_center
	return absf(local.x) <= window_half_size.x and absf(local.y) <= window_half_size.y


## True when window mode maps `pos` (kingdom coordinates) into one of the
## host's window_keep_clear discs.
func _kept_clear(pos: Vector2) -> bool:
	if not window_enabled:
		return false
	var host := window_target_center + (pos - window_source_center)
	for disc in window_keep_clear:
		if host.distance_to(Vector2(disc.x, disc.y)) < disc.z:
			return true
	return false


func _place(prop: Node3D, source_pos: Vector2, visibility_range: float) -> void:
	var pos := source_pos
	if window_enabled:
		pos = window_target_center + (source_pos - window_source_center)
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
		# Writing a collision layer costs a physics-server round trip even
		# when the value is unchanged, which for a static forest is almost
		# always. Only write on an actual change.
		var wanted: int = int(collider.get_meta("lod_collision_layer")) if active else 0
		if collider.collision_layer != wanted:
			collider.collision_layer = wanted


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
		var blob_center: Vector3 = instance.to_global(blob["local_pos"])
		var blob_axes: Vector3 = (blob["semi_axes"] as Vector3) * uniform_scale
		_canopy_blobs.append({"center": blob_center, "axes": blob_axes})
		var blob_bounds := AABB(blob_center - blob_axes, blob_axes * 2.0)
		_canopy_bounds = blob_bounds if _canopy_blobs.size() == 1 else _canopy_bounds.merge(blob_bounds)


## Highest walkable tree-canopy top at this XZ position, no higher than
## max_surface_y -- verbatim copy of wilderness_scatter.gd's own
## get_support_height_at() (see that function's own doc comment for the
## one-way support math): the exact contract player.gd's
## _tree_canopy_stand_height_at() and blorb.gd's _ground_height_at() query
## on a "../Scatter" sibling.
## As with the clouds: every character and every free blorb asks this every
## frame, wherever they are, and the canopy occupies one stretch of a course
## kilometres long. One box test rejects the overwhelmingly common case
## before any per-blob maths runs.
func get_support_height_at(world_x: float, world_z: float, max_surface_y: float = INF) -> Variant:
	if _canopy_blobs.is_empty():
		return null
	if (
		world_x < _canopy_bounds.position.x or world_x > _canopy_bounds.end.x
		or world_z < _canopy_bounds.position.z or world_z > _canopy_bounds.end.z
		or max_surface_y < _canopy_bounds.position.y
	):
		return null
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
