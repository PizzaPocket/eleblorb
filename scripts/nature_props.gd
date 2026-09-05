class_name NatureProps
extends RefCounted

## Procedural wilderness prop library -- trees, rocks, stumps, and small
## ground decor (flowers, grass, mushrooms, bushes) built entirely from
## SuperEgg primitives, replacing the borrowed Kenney Nature Kit GLB
## assets wilderness_scatter.gd used to prototype with, per direct
## instruction (same process as town_props.gd's TownProps did for the
## town). Every solid prop (trees, rocks, stumps) returns a fully-formed
## StaticBody3D with its own collision already baked in, matching
## TownProps' convention -- callers just position/rotate/scale-vary the
## returned root and add it to the scene.

const TRUNK_COLOR := Color(0.42, 0.28, 0.16)
## Pushed brighter and toward teal, per direct correction -- the original
## greens read as a bit muted next to the rest of this project's colorful
## palette (villager clothes, roofs).
const TREE_LEAF_COLORS := [
	Color(0.16, 0.72, 0.4),
	Color(0.08, 0.62, 0.58),
	Color(0.24, 0.78, 0.46),
	Color(0.05, 0.55, 0.52),
]
## Fruit color palette for build_fruit_tree()'s decorative canopy fruit --
## fruit.gd (the actual ground pickup wilderness_scatter.gd scatters beneath
## a fruit tree) reuses the same color per species, so the tree and what it
## dropped visibly match.
const FRUIT_COLORS := {
	"Apple": Color(0.78, 0.14, 0.14),
	"Orange": Color(0.92, 0.5, 0.08),
	"Lemon": Color(0.92, 0.82, 0.15),
	"Plum": Color(0.42, 0.16, 0.42),
	"Banana": Color(0.95, 0.85, 0.25),
	"Durian": Color(0.62, 0.58, 0.22),
}
## Named flower colors -- shared between wilderness_scatter.gd's decorative
## placement and ShopCatalog's own item entries, so "Red Flower" always
## means the same Color wherever either references it.
const FLOWER_COLORS := {
	"Red Flower": Color(0.85, 0.2, 0.2),
	"Yellow Flower": Color(0.9, 0.75, 0.15),
	"Purple Flower": Color(0.55, 0.3, 0.7),
	"Orchid": Color(0.85, 0.35, 0.68),
}
## Named mushroom colors, same reasoning as FLOWER_COLORS above.
const MUSHROOM_COLORS := {
	"Red Mushroom": Color(0.75, 0.2, 0.15),
	"Tan Mushroom": Color(0.8, 0.68, 0.45),
	"Jungle Mushroom": Color(0.25, 0.5, 0.85),
}
const ROCK_COLOR := Color(0.55, 0.54, 0.5)
## Banded sandstone palette for the canyon biome (see wilderness_scatter.gd's
## _build_canyon_biome()) -- cycling through these across paving slabs and
## a slab tower's own tiers is what gives them a striped, sedimentary look
## instead of every rock reading as one flat ROCK_COLOR. Referenced against
## real slot-canyon/hoodoo photos: burnt orange, sandy orange, deep rust,
## pale cream, and a dusty rose -- not this project's usual bright/
## saturated palette on purpose, since real banded sandstone reads as
## earthy rather than vivid.
const CANYON_BAND_COLORS := [
	Color(0.72, 0.32, 0.16),
	Color(0.85, 0.5, 0.24),
	Color(0.55, 0.22, 0.28),
	Color(0.88, 0.78, 0.6),
	Color(0.65, 0.38, 0.42),
]
## Jungle canopy palette -- deeper, more saturated greens than
## TREE_LEAF_COLORS above, so the jungle plateau reads as a visibly denser,
## lusher landscape than the ordinary round/pine trees found elsewhere.
const JUNGLE_LEAF_COLORS := [
	Color(0.05, 0.55, 0.16),
	Color(0.1, 0.62, 0.28),
	Color(0.02, 0.48, 0.32),
	Color(0.14, 0.58, 0.1),
]


## A round-canopy tree (oak-like) -- a trunk plus an off-center cluster of
## overlapping rounded lobes for the canopy, so it doesn't read as one
## perfectly spherical blob.
static func build_round_tree(height: float, leaf_color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var trunk_height := height * 0.4
	var trunk := SuperEgg.build_part(
		Vector3(0.22, trunk_height * 0.5, 0.22), TRUNK_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	trunk.position = Vector3(0, trunk_height * 0.5, 0)
	body.add_child(trunk)

	var canopy_radius := height * 0.4
	var canopy_y := trunk_height + canopy_radius * 0.75
	var lobes := [
		{"offset": Vector3.ZERO, "scale": 1.0},
		{"offset": Vector3(canopy_radius * 0.55, canopy_radius * 0.25, canopy_radius * 0.1), "scale": 0.68},
		{"offset": Vector3(-canopy_radius * 0.45, canopy_radius * 0.15, -canopy_radius * 0.35), "scale": 0.6},
	]
	for lobe in lobes:
		var r: float = canopy_radius * lobe["scale"]
		var lobe_mesh := SuperEgg.build_part(
			Vector3(r, r * 0.88, r), leaf_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		var lobe_pos: Vector3 = Vector3(0, canopy_y, 0) + lobe["offset"]
		lobe_mesh.position = lobe_pos
		body.add_child(lobe_mesh)
		_add_canopy_blob(body, lobe_pos, Vector3(r, r * 0.88, r))

	# Trunk-only collision -- the canopy above it is one-way walkable support
	# instead (see _add_canopy_blob()/get_support_height_at() in
	# wilderness_scatter.gd), not a solid full-height block, per direct
	# instruction that tree foliage should be walkable underneath/through but
	# landable on top.
	_add_cylinder_collision(body, Vector3(0, trunk_height * 0.5, 0), 0.28, trunk_height)
	return body


## A tiered conical tree (pine-like) -- several progressively smaller flat
## lobes stacked up a trunk, tapering toward the top.
static func build_pine_tree(height: float, leaf_color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var trunk_height := height * 0.22
	var trunk := SuperEgg.build_part(
		Vector3(0.18, trunk_height * 0.5, 0.18), TRUNK_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	trunk.position = Vector3(0, trunk_height * 0.5, 0)
	body.add_child(trunk)

	const TIERS := 4
	var foliage_height := height - trunk_height
	var tier_span := foliage_height / TIERS
	for i in TIERS:
		var t := float(i) / float(TIERS - 1)
		var tier_radius := lerpf(height * 0.3, height * 0.08, t)
		var tier_y := trunk_height + tier_span * (float(i) + 0.5)
		var tier := SuperEgg.build_part(
			Vector3(tier_radius, tier_span * 0.6, tier_radius), leaf_color,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
		)
		var tier_pos := Vector3(0, tier_y, 0)
		tier.position = tier_pos
		body.add_child(tier)
		_add_canopy_blob(body, tier_pos, Vector3(tier_radius, tier_span * 0.6, tier_radius))

	# Trunk-only collision -- see build_round_tree()'s own comment on why.
	_add_cylinder_collision(body, Vector3(0, trunk_height * 0.5, 0), 0.24, trunk_height)
	return body


## A round-canopy tree studded with small fruit -- built on top of
## build_round_tree()'s own trunk/canopy (same lobed-canopy construction,
## just with FRUIT_COLORS spheres scattered across the canopy's surface for
## the "fruit hanging in the tree" look). These canopy fruit are decoration
## only, not themselves collectible -- the actual pickup (fruit.gd) is
## scattered separately on the ground nearby, already fallen, matching this
## project's existing pattern for found collectibles (Rock Gem/Ground Gem
## lying out in the world rather than picked directly off a tree/tower).
##
## canopy_radius/canopy_y duplicate build_round_tree()'s own internal math
## (height*0.4 trunk, canopy_radius*0.75 above it) rather than that function
## exposing them -- kept in sync by using literally the same formula, same
## as how build_pine_tree()'s own foliage math stays self-contained.
static func build_fruit_tree(height: float, leaf_color: Color, fruit_color: Color) -> StaticBody3D:
	var body := build_round_tree(height, leaf_color)

	var trunk_height := height * 0.4
	var canopy_radius := height * 0.4
	var canopy_y := trunk_height + canopy_radius * 0.75
	const FRUIT_COUNT := 6
	const FRUIT_RADIUS_FRACTION := 0.09

	# Seeded off the tree's own height/color rather than a shared stream, so
	# fruit placement is deterministic per species/size (matters since
	# wilderness_scatter.gd rebuilds the whole field fresh every run) without
	# needing an rng threaded in from the caller.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(height * 1000.0) + int(fruit_color.r * 255.0)
	for i in FRUIT_COUNT:
		var a := rng.randf_range(0.0, TAU)
		var r := canopy_radius * rng.randf_range(0.55, 0.95)
		var y_jitter := rng.randf_range(-0.2, 0.3) * canopy_radius
		var fruit := SuperEgg.build_part(
			Vector3.ONE * canopy_radius * FRUIT_RADIUS_FRACTION, fruit_color,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		fruit.position = Vector3(cos(a) * r, canopy_y + y_jitter, sin(a) * r)
		body.add_child(fruit)

	return body


## Just the fruit's own visual mesh (a sphere plus a small stem) -- shared
## by fruit.gd's own ground pickup and ShopCatalog's fruit entries (see
## ShopCatalog._build_fruit_visual()), so a fruit sitting on the ground,
## held in the player's hand, and mid-throw are all literally the same
## geometry rather than three independently-maintained copies of it.
static func build_fruit_visual(fruit_color: Color, radius: float, item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fruit_color
	mat.metallic = 0.0
	mat.roughness = 0.35
	sphere.material = mat
	mesh_instance.mesh = sphere
	root.add_child(mesh_instance)

	var stem_height := radius * 0.6
	var stem_mesh := MeshInstance3D.new()
	var stem := CylinderMesh.new()
	stem.top_radius = 0.006
	stem.bottom_radius = 0.01
	stem.height = stem_height
	stem.radial_segments = 6
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.35, 0.26, 0.12)
	stem_mat.metallic = 0.0
	stem_mat.roughness = 0.9
	stem.material = stem_mat
	stem_mesh.mesh = stem
	stem_mesh.position = Vector3(0, radius + stem_height * 0.5, 0)
	root.add_child(stem_mesh)

	# GripPoint: the round side opposite the stem is the natural resting
	# surface against a palm (held stem-up/away, same as how anyone actually
	# holds a piece of fruit) -- see player.gd's own _on_held_item_changed
	# for how this gets used. First pass, not visually verified in-engine.
	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3(0, -radius, 0)
	root.add_child(grip)

	return root


## A boulder -- two overlapping boxy-ish lobes so it doesn't read as one
## perfectly round rock. collidable=false for small decorative pebbles
## that shouldn't block movement.
static func build_rock(radius: float, collidable: bool = true) -> Node3D:
	var root: Node3D
	if collidable:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		root = body
	else:
		root = Node3D.new()

	var main_rock := SuperEgg.build_part(
		Vector3(radius, radius * 0.75, radius * 0.9), ROCK_COLOR, 3.5, 4.0
	)
	main_rock.position = Vector3(0, radius * 0.7, 0)
	root.add_child(main_rock)

	var lump_radius := radius * 0.55
	var lump := SuperEgg.build_part(
		Vector3(lump_radius, lump_radius * 0.85, lump_radius * 0.9), ROCK_COLOR.darkened(0.1), 3.5, 4.0
	)
	lump.position = Vector3(radius * 0.5, radius * 0.4, radius * 0.2)
	root.add_child(lump)

	if collidable:
		_add_cylinder_collision(root as StaticBody3D, Vector3(0, radius * 0.6, 0), radius * 0.95, radius * 1.3)
	return root


## A tall leaning stack of boulders -- 2-4 tapering tiers, each narrower
## than the one below and jittered sideways slightly for a natural
## precarious-cairn look, not a perfectly straight totem pole. A single
## build_rock() only reaches about 1.5x its own radius (barely a step-up);
## this is meant to be a genuine platforming target -- a 3-tier spire at
## base_radius 1.4 reaches roughly 3.7m, each tier a real jump up from the
## last, not just a hop.
static func build_rock_spire(base_radius: float, tiers: int, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var radius := base_radius
	var y := 0.0
	for i in tiers:
		var jitter := Vector3.ZERO
		if i > 0:
			jitter = Vector3(rng.randf_range(-0.35, 0.35), 0, rng.randf_range(-0.35, 0.35)) * radius
		var tier_pos := Vector3(0, y, 0) + jitter

		# build_rock(radius, false) -- visuals only, non-collidable variant --
		# since collision for the whole spire is added below as one cylinder
		# per tier directly on this shared body, not one nested StaticBody3D
		# per tier.
		var visuals := build_rock(radius, false)
		visuals.position = tier_pos
		body.add_child(visuals)
		_add_cylinder_collision(body, tier_pos + Vector3(0, radius * 0.6, 0), radius * 0.95, radius * 1.3)

		y += radius * 1.15
		radius *= rng.randf_range(0.62, 0.78)

	return body


## A tilted boulder slab acting as a natural ramp up onto rockier ground --
## the same tilted-SuperEgg-slab technique TownProps.build_ramp() uses for
## its built town ramps, but with a rock's own boxy-but-rounded epsilon
## (3.5/4.0, matching build_rock()'s own lobes) instead of the sharp-edged
## EPSILON_FLAT a constructed ramp uses, and ROCK_COLOR instead of a built
## material, so it reads as a natural formation rather than a built
## structure. Carries TownProps.BLORB_CLIMBABLE_LAYER too, same as a town
## ramp -- blorbs following the player out into the wilderness should be
## able to climb one exactly the same way (see blorb.gd's
## _ground_height_at()).
static func build_rock_ramp(width: float, run: float, rise: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
	body.collision_mask = 0

	var angle := atan2(rise, run)
	var slope_length := Vector2(run, rise).length()
	# Chunkier than a built ramp's own 0.4 -- a rock slab reads as thicker/
	# heavier, not a thin built plank.
	const THICKNESS := 0.9
	# Offset along the slope's own true normal direction, not just straight
	# down -- see TownProps.build_ramp()'s own doc comment for why the
	# naive version of this left a few-cm dip right at the bottom edge,
	# reported as trouble smoothly stepping onto a ramp.
	var center := Vector3(
		0, rise * 0.5 - THICKNESS * 0.5 * cos(angle), run * 0.5 + THICKNESS * 0.5 * sin(angle)
	)
	var basis := Basis(Vector3.RIGHT, -angle)

	var slab := SuperEgg.build_part(
		Vector3(width * 0.5, THICKNESS * 0.5, slope_length * 0.5), ROCK_COLOR, 3.5, 4.0
	)
	slab.transform = Transform3D(basis, center)
	body.add_child(slab)

	_add_box_collision(body, center, Vector3(width, THICKNESS, slope_length), basis)
	return body


# ---------------------------------------------------------------------------
# Canyon biome (wilderness_scatter.gd's _build_canyon_biome())
# ---------------------------------------------------------------------------


## A flat landable rock slab -- the ground-paving building block for the
## canyon biome (build_slab_tower()'s own tiers build their own boxes
## directly rather than calling this). Same boxy-but-rounded rock epsilon
## as build_rock()/build_rock_ramp() (3.5/4.0), just squashed flat and
## wide instead of chunky.
##
## Carries TownProps.BLORB_CLIMBABLE_LAYER -- unlike build_slab_tower()'s
## tiers or build_rock_arch()'s pillars/bridge, which stay player-only on
## purpose (the canyon biome's tallest hoodoo is meant to be real jump-to-
## jump parkour, see docs/world_bible.md). This is only ever used for the
## canyon's floor paving (_pave_canyon_floor()), which functions as
## ordinary ground once placed -- blorbs need to recognize it the same way
## they recognize a ramp, or they glide along the raw terrain height
## underneath an entire biome's worth of slabs sitting above it, clipping
## through them the whole way (see blorb.gd's _ground_height_at()).
static func build_rock_slab(size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
	body.collision_mask = 0

	var slab := SuperEgg.build_part(size * 0.5, color, 3.5, 4.0)
	slab.position = Vector3(0, size.y * 0.5, 0)
	body.add_child(slab)

	_add_box_collision(body, Vector3(0, size.y * 0.5, 0), size)
	return body


## A precarious-looking stack of flat rock slabs -- a natural hoodoo, and
## (the actual point) a real jump-to-jump climbable tower: each tier is
## its own landable platform, banded through CANYON_BAND_COLORS so it
## reads as a striped sedimentary formation rather than one flat rock
## color repeated. Tapers and jitters slightly tier to tier, the same
## leaning-stack technique build_rock_spire() uses for its own boulder
## stacks. Returns {"body": StaticBody3D, "top_height": float} rather than
## just the body -- build_rock_arch() needs to know exactly where the last
## tier's own top surface ends up, to place a bridging slab flush on it.
static func build_slab_tower(base_width: float, tiers: int, rng: RandomNumberGenerator) -> Dictionary:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var width := base_width
	var y := 0.0
	var top_height := 0.0
	for i in tiers:
		var depth := width * rng.randf_range(0.75, 1.0)
		var height := rng.randf_range(0.6, 1.0)
		var color: Color = CANYON_BAND_COLORS[i % CANYON_BAND_COLORS.size()]

		var jitter := Vector3.ZERO
		if i > 0:
			jitter = Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25)) * width

		var tier_yaw := rng.randf_range(-0.12, 0.12)
		var tier_pos := Vector3(0, y + height * 0.5, 0) + jitter
		var tier := SuperEgg.build_part(
			Vector3(width * 0.5, height * 0.5, depth * 0.5), color, 3.5, 4.0
		)
		tier.position = tier_pos
		tier.rotation.y = tier_yaw
		body.add_child(tier)

		_add_box_collision(
			body, tier_pos, Vector3(width, height, depth), Basis(Vector3.UP, tier_yaw)
		)

		y += height
		top_height = y
		width *= rng.randf_range(0.72, 0.9)

	return {"body": body, "top_height": top_height}


## Two build_slab_tower() pillars joined by a single tilted slab bridging
## their tops -- a simplified, SuperEgg-only stand-in for a natural stone
## arch (a true curved arch isn't achievable out of flat boxes), landable
## across the bridge itself. Returns a plain Node3D wrapping both pillars'
## own StaticBody3D plus the bridge's -- each contributes its own
## collision independently regardless of the Node3D nesting.
static func build_rock_arch(span: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()

	var pillar_tiers := rng.randi_range(4, 6)
	var pillar_a := build_slab_tower(2.0, pillar_tiers, rng)
	var body_a: StaticBody3D = pillar_a["body"]
	body_a.position = Vector3(-span * 0.5, 0, 0)
	root.add_child(body_a)

	var pillar_b := build_slab_tower(2.0, pillar_tiers, rng)
	var body_b: StaticBody3D = pillar_b["body"]
	body_b.position = Vector3(span * 0.5, 0, 0)
	root.add_child(body_b)

	var bridge_body := StaticBody3D.new()
	bridge_body.collision_layer = 1
	bridge_body.collision_mask = 0
	const BRIDGE_HEIGHT := 1.0
	const BRIDGE_DEPTH := 3.2
	var bridge_y: float = maxf(pillar_a["top_height"], pillar_b["top_height"]) + BRIDGE_HEIGHT * 0.5
	var bridge_length := span + 3.0
	var bridge := SuperEgg.build_part(
		Vector3(bridge_length * 0.5, BRIDGE_HEIGHT * 0.5, BRIDGE_DEPTH * 0.5), CANYON_BAND_COLORS[0], 3.5, 4.0
	)
	bridge.position = Vector3(0, bridge_y, 0)
	bridge_body.add_child(bridge)
	_add_box_collision(bridge_body, Vector3(0, bridge_y, 0), Vector3(bridge_length, BRIDGE_HEIGHT, BRIDGE_DEPTH))
	root.add_child(bridge_body)

	return root


static func build_stump(radius: float, height: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var stump := SuperEgg.build_part(
		Vector3(radius, height * 0.5, radius), TRUNK_COLOR, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT
	)
	stump.position = Vector3(0, height * 0.5, 0)
	body.add_child(stump)
	_add_cylinder_collision(body, Vector3(0, height * 0.5, 0), radius, height)
	return body


static func build_flower(petal_color: Color) -> Node3D:
	var flower := Node3D.new()
	var stem := SuperEgg.build_part(
		Vector3(0.014, 0.09, 0.014), Color(0.22, 0.5, 0.22), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	stem.position = Vector3(0, 0.09, 0)
	flower.add_child(stem)
	var bloom := SuperEgg.build_part(
		Vector3(0.045, 0.03, 0.045), petal_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	bloom.position = Vector3(0, 0.2, 0)
	flower.add_child(bloom)
	return flower


static func build_grass_tuft(color: Color = Color(0.2, 0.75, 0.42)) -> Node3D:
	var tuft := Node3D.new()
	const BLADE_HEIGHT := 0.16
	for i in 3:
		# A dedicated pivot per blade, positioned at the blade's own BASE
		# (not its center) -- per direct correction, an earlier version
		# rotated the blade mesh itself around its own center, which
		# swings the BASE outward and the TIP inward (confirmed by direct
		# observation: it read as a tepee, converging at the top, the
		# opposite of a real tuft). Rotating a pivot placed at the base
		# instead keeps the base fixed and swings only the tip, which is
		# what actually diverges the blades.
		#
		# Sign worked out directly (not guessed): with the pivot's own
		# local Z-rotation matrix (x' = cos*x - sin*y, y' = sin*x + cos*y)
		# applied to a blade tip at local (0, BLADE_HEIGHT), the LEFT
		# blade (i=0, base already offset toward -X) needs a POSITIVE
		# rotation to push its tip further toward -X (diverging away from
		# center); the RIGHT blade (i=2) needs the opposite sign. Hence
		# the negation below (i=0 gives -(i-1)=+1, i=2 gives -(i-1)=-1).
		var pivot := Node3D.new()
		pivot.position = Vector3(float(i - 1) * 0.012, 0, 0)
		pivot.rotation.z = deg_to_rad(-float(i - 1) * 18.0)
		tuft.add_child(pivot)

		var blade := SuperEgg.build_part(
			Vector3(0.014, BLADE_HEIGHT * 0.5, 0.014), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		blade.position = Vector3(0, BLADE_HEIGHT * 0.5, 0)
		pivot.add_child(blade)
	return tuft


static func build_mushroom(cap_color: Color) -> Node3D:
	var mushroom := Node3D.new()
	var stalk := SuperEgg.build_part(
		Vector3(0.025, 0.05, 0.025), Color(0.9, 0.88, 0.8), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	stalk.position = Vector3(0, 0.05, 0)
	mushroom.add_child(stalk)
	var cap := SuperEgg.build_part(
		Vector3(0.06, 0.035, 0.06), cap_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	cap.position = Vector3(0, 0.105, 0)
	mushroom.add_child(cap)
	return mushroom


static func build_bush(color: Color = Color(0.16, 0.68, 0.4)) -> Node3D:
	var bush := Node3D.new()
	var main_lobe := SuperEgg.build_part(
		Vector3(0.2, 0.16, 0.2), color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	main_lobe.position = Vector3(0, 0.16, 0)
	bush.add_child(main_lobe)
	var lump := SuperEgg.build_part(
		Vector3(0.12, 0.1, 0.12), color.darkened(0.08), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	lump.position = Vector3(0.12, 0.12, 0.08)
	bush.add_child(lump)
	return bush


## ---- Jungle biome props -----------------------------------------------
## Larger, more varied vegetation for the jungle plateau (see
## TerrainGenerator.get_jungle_plateau_center()) -- taller and denser than
## the trees scattered through the rest of the wilderness, per direct
## instruction that the jungle should read as "a lush thick varied
## landscape" distinct from every other biome.


const PALM_TRUNK_SEGMENTS := 6
const PALM_FROND_COUNT := 7

## A leaning, curved-trunk palm -- a handful of stacked, progressively
## sideways-drifting trunk segments (an ease-in t*t curve, so the lean
## barely shows near the base and is most pronounced near the crown) topped
## with a fan of drooping frond pivots. lean_amount is the crown's own
## horizontal drift as a fraction of the trunk's own height; the caller
## varies it per instance for "a range of natural lean," rather than every
## palm leaning the same amount. The lean itself is only ever authored
## along local X here -- the whole tree also gets an ordinary random Y
## rotation wherever it's placed (see wilderness_scatter.gd's
## _place_solid()), so the lean's real-world compass direction still varies
## instance to instance despite that.
static func build_palm_tree(height: float, lean_amount: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var trunk_height := height * 0.72
	var trunk_radius := height * rng.randf_range(0.028, 0.038)
	var seg_height := trunk_height / PALM_TRUNK_SEGMENTS
	var crown_pos := Vector3.ZERO

	for i in PALM_TRUNK_SEGMENTS:
		var t0 := float(i) / float(PALM_TRUNK_SEGMENTS)
		var t1 := float(i + 1) / float(PALM_TRUNK_SEGMENTS)
		var drift0 := lean_amount * t0 * t0 * trunk_height
		var drift1 := lean_amount * t1 * t1 * trunk_height
		var seg_bottom := Vector3(drift0, t0 * trunk_height, 0)
		var seg_top := Vector3(drift1, t1 * trunk_height, 0)
		var seg_radius := lerpf(trunk_radius * 1.25, trunk_radius * 0.65, t0)
		var seg := SuperEgg.build_part(
			Vector3(seg_radius, seg_height * 0.65, seg_radius), TRUNK_COLOR.lightened(0.08),
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		var seg_center := (seg_bottom + seg_top) * 0.5
		# Tilts the segment to visually follow the local slope between its
		# own bottom/top rather than standing perfectly upright -- see
		# build_grass_tuft()'s own comment for the same local Z-rotation
		# matrix this angle is derived from (x'=cos*x-sin*y, y'=sin*x+cos*y
		# applied to a point at local (0, h)).
		var seg_angle := -atan2(drift1 - drift0, seg_height)
		seg.position = seg_center
		seg.rotation.z = seg_angle
		body.add_child(seg)
		crown_pos = seg_top

		# One collider PER segment, following that segment's own angled
		# position/rotation -- a single cylinder spanning the whole trunk at
		# an averaged "center of mass" position (the previous approach) does
		# not track a leaning/curved trunk's actual geometry, most visibly
		# wrong on a sharply-leaning palm.
		_add_cylinder_collision(
			body, seg_center, seg_radius * 1.3, seg_height * 1.15, Basis(Vector3.BACK, seg_angle)
		)

	for i in PALM_FROND_COUNT:
		var frond_parent := Node3D.new()
		frond_parent.position = crown_pos
		body.add_child(frond_parent)

		var azimuth := (float(i) / PALM_FROND_COUNT) * TAU + rng.randf_range(-0.15, 0.15)
		var frond_length := height * rng.randf_range(0.34, 0.44)
		# Per direct instruction, fronds should angle down toward the ground
		# much more steeply right from their point of attachment, not just
		# accumulate droop toward the tip -- base_droop is now a real downward
		# pitch on its own, with the tip's own accumulated arc (see
		# _build_arching_frond()) still curling further past that.
		_build_arching_frond(
			frond_parent, azimuth, frond_length,
			height * 0.05, height * 0.012, height * 0.012,
			JUNGLE_LEAF_COLORS[i % JUNGLE_LEAF_COLORS.size()],
			rng.randf_range(30.0, 48.0), rng.randf_range(55.0, 75.0), 3
		)

	_add_canopy_blob(body, crown_pos + Vector3(0, height * 0.04, 0), Vector3(height * 0.22, height * 0.09, height * 0.22))
	return body


const BANANA_LEAF_COUNT := 6
const BANANA_BUNCH_COUNT := 5
const BANANA_STALK_SEGMENTS := 3
## A banana "trunk" is botanically a pseudostem -- tightly wrapped, fibrous
## leaf sheaths, not solid wood -- so it reads as smooth green-banded stalk
## segments rather than a single brown TRUNK_COLOR post. Bright, saturated
## green rather than an olive/muted tone, per direct instruction.
const BANANA_STALK_COLOR := Color(0.34, 0.64, 0.2)

## A short banana "tree" (botanically a giant herb, not a true woody tree --
## see BANANA_STALK_SEGMENTS above) plus a single hanging bunch of curved
## fruit for decoration -- the actual pickup is a separate ground Fruit (see
## wilderness_scatter.gd's _fruit_tree_species), matching every other fruit
## tree's existing decorative-canopy-fruit-vs-ground-pickup split.
static func build_banana_tree(height: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var trunk_height := height * 0.4
	# Thinner than a real tree trunk, per direct instruction -- a banana
	# pseudostem reads as a slender fibrous stalk, not a stout woody post.
	var trunk_radius := height * 0.045
	var seg_height := trunk_height / BANANA_STALK_SEGMENTS
	for i in BANANA_STALK_SEGMENTS:
		var t0 := float(i) / BANANA_STALK_SEGMENTS
		var seg_radius := lerpf(trunk_radius * 1.15, trunk_radius * 0.72, t0)
		var seg := SuperEgg.build_part(
			Vector3(seg_radius, seg_height * 0.5, seg_radius), BANANA_STALK_COLOR.lightened(0.05 * i),
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		seg.position = Vector3(0, seg_height * (float(i) + 0.5), 0)
		body.add_child(seg)

	var leaf_color: Color = JUNGLE_LEAF_COLORS[rng.randi() % JUNGLE_LEAF_COLORS.size()]
	var leaf_length := height * 0.5
	for i in BANANA_LEAF_COUNT:
		var leaf_parent := Node3D.new()
		leaf_parent.position = Vector3(0, trunk_height * 0.92, 0)
		body.add_child(leaf_parent)

		var azimuth := (float(i) / BANANA_LEAF_COUNT) * TAU
		# Per direct instruction, banana leaves angle down toward the ground
		# much more steeply right from the crown, not just droop toward the
		# tip -- same chained-segment arc build_palm_tree()'s fronds use,
		# just a wider paddle-shaped blade.
		_build_arching_frond(
			leaf_parent, azimuth, leaf_length, height * 0.13, height * 0.04, height * 0.02, leaf_color,
			rng.randf_range(22.0, 36.0), rng.randf_range(60.0, 85.0), 3
		)

	var bunch_pivot := Node3D.new()
	bunch_pivot.position = Vector3(0, trunk_height * 0.85, trunk_radius * 0.8)
	bunch_pivot.rotation.x = deg_to_rad(70.0)
	body.add_child(bunch_pivot)
	for i in BANANA_BUNCH_COUNT:
		var banana := build_banana_fruit(FRUIT_COLORS["Banana"], 0.09)
		var a := (float(i) / BANANA_BUNCH_COUNT - 0.5) * 0.9
		banana.position = Vector3(sin(a) * 0.1, -0.12, cos(a) * 0.02)
		banana.rotation.z = a
		bunch_pivot.add_child(banana)

	_add_cylinder_collision(body, Vector3(0, trunk_height * 0.5, 0), trunk_radius * 1.1, trunk_height)
	_add_canopy_blob(
		body, Vector3(0, trunk_height * 0.92 + leaf_length * 0.12, 0),
		Vector3(leaf_length * 0.55, leaf_length * 0.22, leaf_length * 0.55)
	)
	return body


const BANANA_FRUIT_RINGS := 10
const BANANA_FRUIT_SIDES := 8
const BANANA_FRUIT_BEND_DEG := 75.0

## A single curved banana, built as a genuine banana-shaped tube mesh (a
## SurfaceTool-lofted ring chain along a curved spine, tapered to a blunt
## stem end and a point at the tip) rather than chained SuperEgg segments --
## per direct instruction, a banana doesn't read as "many multiple superegg
## segments" no matter how finely chained. Same CULL_DISABLED-until-verified
## pragmatic fix distant_mountains.gd's own ring mesh uses for its own
## unconfirmed winding direction. Shared by the canopy bunch below, fruit.
## gd's own ground pickup, and ShopCatalog's Banana entry, same sharing
## pattern as build_fruit_visual() above.
static func build_banana_fruit(fruit_color: Color, radius: float, item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var total_length := radius * 7.0
	var bend := deg_to_rad(BANANA_FRUIT_BEND_DEG)
	var arc_radius := total_length / bend

	# Ring centers walk along a circular arc of the above radius (so the
	# spine's own curvature is exact, not approximated), and each ring's own
	# cross-section radius tapers from a blunt stem end down to a near-point
	# tip, fullest a little past the midpoint -- a real banana's silhouette,
	# not a uniform tube.
	var centers: Array[Vector3] = []
	var cross_radii: Array[float] = []
	for i in BANANA_FRUIT_RINGS:
		var t := float(i) / float(BANANA_FRUIT_RINGS - 1)
		var a := bend * t
		centers.append(Vector3(arc_radius * (1.0 - cos(a)), arc_radius * sin(a), 0))
		var taper := sin(PI * pow(t, 0.8))
		cross_radii.append(radius * (0.16 + 0.82 * taper))

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = fruit_color
	mat.metallic = 0.0
	mat.roughness = 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(mat)

	# Each ring's cross-section sits in the plane spanned by the spine's own
	# local sideways direction and a fixed "out of the bend" axis, oriented
	# by the spine's tangent at that ring -- keeps every ring's own rim
	# perpendicular to the curve it's threaded on.
	var out_axis := Vector3(0, 0, 1)
	var ring_points: Array = []
	for i in BANANA_FRUIT_RINGS:
		var tangent: Vector3
		if i == 0:
			tangent = (centers[1] - centers[0]).normalized()
		elif i == BANANA_FRUIT_RINGS - 1:
			tangent = (centers[i] - centers[i - 1]).normalized()
		else:
			tangent = (centers[i + 1] - centers[i - 1]).normalized()
		var side := tangent.cross(out_axis).normalized()
		var points: Array[Vector3] = []
		for j in BANANA_FRUIT_SIDES:
			var ang := (float(j) / BANANA_FRUIT_SIDES) * TAU
			points.append(centers[i] + (side * cos(ang) + out_axis * sin(ang)) * cross_radii[i])
		ring_points.append(points)

	for i in BANANA_FRUIT_RINGS - 1:
		var ring0: Array = ring_points[i]
		var ring1: Array = ring_points[i + 1]
		for j in BANANA_FRUIT_SIDES:
			var j1 := (j + 1) % BANANA_FRUIT_SIDES
			st.add_vertex(ring0[j])
			st.add_vertex(ring1[j])
			st.add_vertex(ring1[j1])
			st.add_vertex(ring0[j])
			st.add_vertex(ring1[j1])
			st.add_vertex(ring0[j1])

	# Caps both ends -- the stem end (a small flat disc, since it's blunt
	# where it meets the stem below) and the tip (already tapered to a
	# near-point, so its cap fan is tiny and barely visible).
	var start_points: Array = ring_points[0]
	for j in BANANA_FRUIT_SIDES:
		var j1 := (j + 1) % BANANA_FRUIT_SIDES
		st.add_vertex(centers[0])
		st.add_vertex(start_points[j1])
		st.add_vertex(start_points[j])
	var end_points: Array = ring_points[BANANA_FRUIT_RINGS - 1]
	for j in BANANA_FRUIT_SIDES:
		var j1 := (j + 1) % BANANA_FRUIT_SIDES
		st.add_vertex(centers[BANANA_FRUIT_RINGS - 1])
		st.add_vertex(end_points[j])
		st.add_vertex(end_points[j1])

	st.index()
	st.generate_normals()
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	root.add_child(mesh_instance)

	# A short stem nub at the blunt end, connecting it visually to the bunch
	# pivot/hand it's attached to.
	var stem_height := radius * 0.6
	var stem_mesh := MeshInstance3D.new()
	var stem := CylinderMesh.new()
	stem.top_radius = radius * 0.05
	stem.bottom_radius = radius * 0.09
	stem.height = stem_height
	stem.radial_segments = 6
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.35, 0.5, 0.18)
	stem_mat.roughness = 0.9
	stem.material = stem_mat
	stem_mesh.mesh = stem
	stem_mesh.position = centers[0] - Vector3(0, stem_height * 0.5, 0)
	root.add_child(stem_mesh)

	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = centers[0]
	root.add_child(grip)
	return root


## A round-canopy tree (reusing build_round_tree()'s own lobed silhouette)
## hung with a few large spiky durian for decoration -- same decorative-
## canopy-fruit/separate-ground-pickup split every other fruit tree here
## already uses.
const DURIAN_COUNT := 3

static func build_durian_tree(height: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var leaf_color: Color = JUNGLE_LEAF_COLORS[rng.randi() % JUNGLE_LEAF_COLORS.size()]
	var body := build_round_tree(height, leaf_color)

	var trunk_height := height * 0.4
	var canopy_radius := height * 0.4
	var canopy_y := trunk_height + canopy_radius * 0.75
	for i in DURIAN_COUNT:
		var a := rng.randf_range(0.0, TAU)
		var r := canopy_radius * rng.randf_range(0.5, 0.85)
		var durian := build_durian_fruit(FRUIT_COLORS["Durian"], 0.16)
		durian.position = Vector3(cos(a) * r, canopy_y - canopy_radius * 0.3, sin(a) * r)
		body.add_child(durian)

	return body


const DURIAN_SPIKE_COUNT := 20
const DURIAN_GOLDEN_ANGLE := 2.399963  # radians; even point distribution on a sphere

## A durian: a central husk plus spikes radiating evenly across its surface
## (a golden-angle spiral, the standard even-sphere-coverage trick, rather
## than a plain latitude/longitude grid which would visibly bunch spikes at
## the poles). Each spike is built along its own natural Y axis (see
## superegg.gd -- SuperEgg's epsilon shaping is tied to that axis and can't
## itself point off-axis) then aimed outward via a per-spike look_at()
## pivot, rather than trying to bake an off-axis direction into the spike
## mesh directly. First pass, not visually verified in-engine.
static func build_durian_fruit(fruit_color: Color, radius: float, item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var husk := SuperEgg.build_part(
		Vector3.ONE * radius, fruit_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	husk.position = Vector3(0, radius, 0)
	root.add_child(husk)

	var spike_length := radius * 0.4
	for i in DURIAN_SPIKE_COUNT:
		var t := (float(i) + 0.5) / DURIAN_SPIKE_COUNT
		var lat := acos(1.0 - 2.0 * t) - PI * 0.5
		var lon := DURIAN_GOLDEN_ANGLE * i
		var dir := Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))

		var pivot := Node3D.new()
		pivot.position = Vector3(0, radius, 0) + dir * radius * 0.94
		if absf(dir.dot(Vector3.UP)) < 0.9999:
			# look_at() hard-requires is_inside_tree() (it resolves the target
			# via get_global_transform()) -- pivot isn't parented yet at this
			# point in construction (root.add_child(pivot) is still below),
			# and root itself isn't in the tree either. look_at_from_position()
			# sets the transform directly instead of resolving through the
			# tree, so it works during this kind of off-tree building.
			pivot.look_at_from_position(pivot.position, pivot.position + dir, Vector3.UP)
		root.add_child(pivot)

		var spike := SuperEgg.build_part(
			Vector3(radius * 0.09, spike_length * 0.5, radius * 0.09), fruit_color.darkened(0.1),
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT
		)
		# look_at() points the pivot's own local -Z at the target -- rotate
		# the spike a further 90 degrees so its SuperEgg long axis (always
		# local Y, see superegg.gd) points down the pivot's aimed -Z instead
		# of standing straight up.
		spike.rotation.x = deg_to_rad(-90.0)
		spike.position = Vector3(0, 0, -spike_length * 0.5)
		pivot.add_child(spike)

	var grip := Node3D.new()
	grip.name = "GripPoint"
	grip.position = Vector3.ZERO
	root.add_child(grip)
	return root


## A wide, sprawling banyan -- a broad, flattened canopy plus a handful of
## thin drooping "aerial root" tendrils hanging down from it, the banyan's
## own distinguishing feature versus every other round-canopy tree here.
const BANYAN_LOBE_COUNT := 5

static func build_banyan_tree(height: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	# Taller and a bit less bulky than before, so the trunk's own top reaches
	# well up into the canopy's vertical span instead of stopping short of it
	# (canopy_y below is deliberately kept close to trunk_height so the
	# lobes -- and the guaranteed centered one just below -- always overlap
	# the trunk top rather than floating above a visible gap).
	var trunk_height := height * 0.42
	var trunk_radius := height * 0.075
	var trunk := SuperEgg.build_part(
		Vector3(trunk_radius, trunk_height * 0.5, trunk_radius), TRUNK_COLOR,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_SOFT
	)
	trunk.position = Vector3(0, trunk_height * 0.5, 0)
	body.add_child(trunk)

	var canopy_radius := height * 0.6
	var canopy_y := trunk_height + canopy_radius * 0.15
	var leaf_color: Color = JUNGLE_LEAF_COLORS[rng.randi() % JUNGLE_LEAF_COLORS.size()]

	# A canopy mass centered directly on the trunk axis -- every lobe in the
	# loop below is deliberately offset away from center for silhouette
	# variety, so without this nothing ever sits right above the trunk
	# itself. canopy_y's margin above guarantees this always overlaps the
	# trunk top regardless of the random radius drawn.
	var center_radius: float = canopy_radius * rng.randf_range(0.5, 0.62)
	var center_lobe := SuperEgg.build_part(
		Vector3(center_radius, center_radius * 0.6, center_radius), leaf_color,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	center_lobe.position = Vector3(0, canopy_y, 0)
	body.add_child(center_lobe)
	_add_canopy_blob(body, center_lobe.position, Vector3(center_radius, center_radius * 0.6, center_radius))

	for i in BANYAN_LOBE_COUNT:
		var a := (float(i) / BANYAN_LOBE_COUNT) * TAU
		var r: float = canopy_radius * rng.randf_range(0.32, 0.55)
		var lobe_radius: float = canopy_radius * rng.randf_range(0.45, 0.62)
		var lobe := SuperEgg.build_part(
			Vector3(lobe_radius, lobe_radius * 0.6, lobe_radius), leaf_color,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		lobe.position = Vector3(cos(a) * r, canopy_y, sin(a) * r)
		body.add_child(lobe)
		_add_canopy_blob(body, lobe.position, Vector3(lobe_radius, lobe_radius * 0.6, lobe_radius))

		var root_count := rng.randi_range(1, 2)
		for j in root_count:
			var root_len: float = canopy_y * rng.randf_range(0.6, 0.95)
			var tendril := SuperEgg.build_part(
				Vector3(0.02, root_len * 0.5, 0.02), TRUNK_COLOR.lightened(0.1),
				SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
			)
			var tendril_offset := Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)) * lobe_radius
			tendril.position = Vector3(
				cos(a) * r + tendril_offset.x, canopy_y - root_len * 0.5 - lobe_radius * 0.3, sin(a) * r + tendril_offset.y
			)
			body.add_child(tendril)

	_add_cylinder_collision(body, Vector3(0, trunk_height * 0.5, 0), trunk_radius * 1.2, trunk_height)
	return body


## A very thick, tapering, sparse-crowned baobab -- the swollen trunk (far
## fatter relative to its own height than any other tree here) is the
## point; the crown on top is deliberately small and sparse by comparison.
const BAOBAB_TRUNK_TIERS := 4
const BAOBAB_CROWN_LOBES := 3

static func build_baobab_tree(height: float, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var trunk_height := height * 0.7
	var base_radius := height * 0.24
	var top_radius := height * 0.14
	var tier_height := trunk_height / BAOBAB_TRUNK_TIERS
	for i in BAOBAB_TRUNK_TIERS:
		var t := float(i) / float(BAOBAB_TRUNK_TIERS - 1)
		var tier_radius := lerpf(base_radius, top_radius, t * t)
		var tier := SuperEgg.build_part(
			Vector3(tier_radius, tier_height * 0.65, tier_radius), TRUNK_COLOR.lightened(0.15),
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		tier.position = Vector3(0, tier_height * (float(i) + 0.5), 0)
		body.add_child(tier)

	var leaf_color: Color = JUNGLE_LEAF_COLORS[rng.randi() % JUNGLE_LEAF_COLORS.size()]
	for i in BAOBAB_CROWN_LOBES:
		var a := rng.randf_range(0.0, TAU)
		var r := top_radius * rng.randf_range(0.3, 0.7)
		var lobe_radius := top_radius * rng.randf_range(0.5, 0.7)
		var lobe := SuperEgg.build_part(
			Vector3(lobe_radius, lobe_radius * 0.75, lobe_radius), leaf_color,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		lobe.position = Vector3(cos(a) * r, trunk_height + lobe_radius * 0.6, sin(a) * r)
		body.add_child(lobe)
		_add_canopy_blob(body, lobe.position, Vector3(lobe_radius, lobe_radius * 0.75, lobe_radius))

	_add_cylinder_collision(body, Vector3(0, trunk_height * 0.5, 0), base_radius * 0.95, trunk_height)
	return body


## A hanging chain of small overlapping leaf blobs, meant to dangle from a
## tree's canopy or a fixed anchor point -- non-collidable decoration only,
## same category as build_grass_tuft()/build_bush(). A slight per-segment
## sine offset keeps the strand from reading as a perfectly straight rod.
static func build_hanging_vine(length: float, rng: RandomNumberGenerator) -> Node3D:
	var vine := Node3D.new()
	var segment_count := maxi(4, int(length / 0.18))
	var seg_spacing := length / segment_count
	var sway_phase := rng.randf_range(0.0, TAU)
	for i in segment_count:
		var y := -seg_spacing * i
		var sway := sin(float(i) * 0.9 + sway_phase) * 0.03
		var leaf := SuperEgg.build_part(
			Vector3(0.035, 0.05, 0.02), JUNGLE_LEAF_COLORS[i % JUNGLE_LEAF_COLORS.size()],
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		leaf.position = Vector3(sway, y, 0)
		leaf.rotation.z = sway * 2.0
		vine.add_child(leaf)
	return vine


## A round-canopy tree (build_round_tree()'s own silhouette) speckled with
## small blossom-colored dots across the foliage -- the same scatter
## technique build_fruit_tree() already uses for its own canopy fruit, just
## smaller, denser, and purely decorative (no ground pickup of its own).
const FLOWERING_TREE_BLOSSOM_COUNT := 14

static func build_flowering_tree(height: float, leaf_color: Color, blossom_color: Color, rng: RandomNumberGenerator) -> StaticBody3D:
	var body := build_round_tree(height, leaf_color)

	var trunk_height := height * 0.4
	var canopy_radius := height * 0.4
	var canopy_y := trunk_height + canopy_radius * 0.75
	for i in FLOWERING_TREE_BLOSSOM_COUNT:
		var a := rng.randf_range(0.0, TAU)
		var r := canopy_radius * rng.randf_range(0.5, 1.0)
		var y_jitter := rng.randf_range(-0.3, 0.4) * canopy_radius
		var blossom := SuperEgg.build_part(
			Vector3.ONE * canopy_radius * 0.05, blossom_color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		blossom.position = Vector3(cos(a) * r, canopy_y + y_jitter, sin(a) * r)
		body.add_child(blossom)

	return body


## A giant emergent-canopy tree, towering well above every other jungle
## species here (see build_banyan_tree()'s own 30.0 top height for
## comparison) -- the "especially tall" species the primate kingdom's
## village is built into, per direct instruction. Its trunk carries a
## spiral of climbable branch-ramps, each ending in a landable platform,
## winding up around the exterior from near the ground to just under the
## canopy. Returns a Dictionary ({"body": StaticBody3D, "platform_positions":
## Array[Vector3]}) rather than a bare StaticBody3D like the other tree
## builders -- callers (jungle_kingdom_village.gd) need those platform
## positions (in body-local space) to mount treehouses on them.
##
## Branch ramps/landings are each other builders' own fully self-contained
## StaticBody3D (TownProps.build_ramp()/build_crate()) nested as children of
## this tree's root body, rather than hand-authoring per-ramp collision boxes
## at arbitrary azimuths here -- reuses those builders' own proven collision
## (and, for the ramps, their baked-in TownProps.BLORB_CLIMBABLE_LAYER bit)
## instead of re-deriving it. Godot's physics doesn't care that a StaticBody3D
## is nested under another one; only the transform hierarchy is shared.
const EMERGENT_TRUNK_TIERS := 7
const EMERGENT_CANOPY_TOP_FRACTION := 0.86
const EMERGENT_BRANCH_RISE := 3.8
const EMERGENT_BRANCH_RUN := 3.6
const EMERGENT_BRANCH_WIDTH := 1.5
const EMERGENT_LOBE_COUNT := 6
## The golden angle (~137.5 deg) instead of a fixed ~100 deg step -- per
## direct feedback that successive ramps all read as landing "on one side"
## of the trunk. A fixed step re-aligns every few branches (100 deg * 18/5
## is close to a whole number of turns), so landings cluster into a few
## repeating azimuths; the golden angle is the standard phyllotaxis trick
## (how real plants space leaves/branches around a stem) specifically
## because it never re-aligns, so every landing lands somewhere new.
const EMERGENT_GOLDEN_ANGLE := TAU * 0.6180339887498949
## Small leaf-tipped twigs sprouting off the trunk between ramp landings,
## purely decorative (no collision) -- per direct feedback that the tree
## should read as having "more branches with clusters of leaves branching
## out in all directions" instead of a bare trunk with the canopy only at
## the very top.
const EMERGENT_TWIGS_PER_TIER := 3
const EMERGENT_TWIG_LENGTH_MIN := 1.4
const EMERGENT_TWIG_LENGTH_MAX := 2.6
const EMERGENT_TWIG_LEAF_MIN := 0.7
const EMERGENT_TWIG_LEAF_MAX := 1.5

static func build_emergent_tree(height: float, rng: RandomNumberGenerator) -> Dictionary:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0

	var base_radius := height * 0.045
	var top_radius := height * 0.02
	var trunk_top := height * EMERGENT_CANOPY_TOP_FRACTION
	var tier_height := trunk_top / EMERGENT_TRUNK_TIERS
	for i in EMERGENT_TRUNK_TIERS:
		var t0 := float(i) / EMERGENT_TRUNK_TIERS
		var t1 := float(i + 1) / EMERGENT_TRUNK_TIERS
		var tier_radius := lerpf(base_radius, top_radius, (t0 + t1) * 0.5)
		var tier := SuperEgg.build_part(
			Vector3(tier_radius, tier_height * 0.5, tier_radius), TRUNK_COLOR,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		tier.position = Vector3(0, tier_height * (float(i) + 0.5), 0)
		body.add_child(tier)
	_add_cylinder_collision(body, Vector3(0, trunk_top * 0.5, 0), base_radius, trunk_top)

	var canopy_radius := height * 0.34
	var canopy_y := trunk_top + canopy_radius * 0.2
	var leaf_color: Color = JUNGLE_LEAF_COLORS[rng.randi() % JUNGLE_LEAF_COLORS.size()]
	var center_lobe := SuperEgg.build_part(
		Vector3(canopy_radius * 0.6, canopy_radius * 0.4, canopy_radius * 0.6), leaf_color,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
	)
	center_lobe.position = Vector3(0, canopy_y, 0)
	body.add_child(center_lobe)
	_add_canopy_blob(body, center_lobe.position, Vector3(canopy_radius * 0.6, canopy_radius * 0.4, canopy_radius * 0.6))
	for i in EMERGENT_LOBE_COUNT:
		var lobe_a := (float(i) / EMERGENT_LOBE_COUNT) * TAU
		var lobe_r: float = canopy_radius * rng.randf_range(0.45, 0.7)
		var lobe_radius: float = canopy_radius * rng.randf_range(0.5, 0.68)
		var lobe := SuperEgg.build_part(
			Vector3(lobe_radius, lobe_radius * 0.55, lobe_radius), leaf_color,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		lobe.position = Vector3(cos(lobe_a) * lobe_r, canopy_y, sin(lobe_a) * lobe_r)
		body.add_child(lobe)
		_add_canopy_blob(body, lobe.position, Vector3(lobe_radius, lobe_radius * 0.55, lobe_radius))

	var platform_positions: Array[Vector3] = []
	var angle := rng.randf_range(0.0, TAU)
	var current_y := 0.0
	var current_pos := Vector3.ZERO
	var first := true
	while current_y + EMERGENT_BRANCH_RISE <= trunk_top * 0.95:
		var t := clampf(current_y / trunk_top, 0.0, 1.0)
		var start: Vector3
		if first:
			var trunk_r := lerpf(base_radius, top_radius, t)
			start = Vector3(cos(angle) * (trunk_r + 0.3), current_y, sin(angle) * (trunk_r + 0.3))
			first = false
		else:
			start = current_pos

		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var yaw := atan2(dir.x, dir.z)
		var ramp := TownProps.build_ramp(
			EMERGENT_BRANCH_WIDTH, EMERGENT_BRANCH_RUN, EMERGENT_BRANCH_RISE, TRUNK_COLOR.lightened(0.1)
		)
		ramp.rotation.y = yaw
		ramp.position = start
		body.add_child(ramp)

		var ramp_basis := Basis(Vector3.UP, yaw)
		var top_world: Vector3 = start + ramp_basis * Vector3(0, EMERGENT_BRANCH_RISE, EMERGENT_BRANCH_RUN)

		var landing_size := Vector3(EMERGENT_BRANCH_WIDTH + 0.8, 0.3, EMERGENT_BRANCH_WIDTH + 0.8)
		var landing_center := top_world + dir * (landing_size.z * 0.7)
		var landing := TownProps.build_crate(landing_size, TRUNK_COLOR.darkened(0.1), true)
		landing.position = Vector3(landing_center.x, top_world.y - landing_size.y, landing_center.z)
		body.add_child(landing)

		current_pos = Vector3(landing_center.x, top_world.y, landing_center.z)
		current_y = top_world.y
		platform_positions.append(current_pos)
		_add_emergent_twigs(body, lerpf(base_radius, top_radius, t), current_y, angle, leaf_color, rng)
		angle += EMERGENT_GOLDEN_ANGLE

	return {"body": body, "platform_positions": platform_positions}


## Small leaf-tipped twigs sprouting off the trunk at a ramp landing's own
## height, spread across the angles the golden-angle spiral skips over at
## that level -- see EMERGENT_TWIGS_PER_TIER's own doc comment above. Pure
## visual dressing (a thin branch stub plus a small canopy blob), no
## collision, so it doesn't compete with the climbable ramp geometry.
static func _add_emergent_twigs(
	body: StaticBody3D, trunk_r: float, y: float, ramp_angle: float, leaf_color: Color, rng: RandomNumberGenerator
) -> void:
	for i in EMERGENT_TWIGS_PER_TIER:
		var spread := TAU / float(EMERGENT_TWIGS_PER_TIER + 1)
		var twig_angle := ramp_angle + spread * float(i + 1) + rng.randf_range(-0.3, 0.3)
		var length := rng.randf_range(EMERGENT_TWIG_LENGTH_MIN, EMERGENT_TWIG_LENGTH_MAX)
		var dir := Vector3(cos(twig_angle), 0.0, sin(twig_angle))
		var pitch := rng.randf_range(0.1, 0.35)  # slight upward tilt, a real branch's own droop-then-reach angle
		var tip := dir * length * cos(pitch) + Vector3.UP * length * sin(pitch)

		# The stub's own long axis is local Y (see the tree trunk tiers above,
		# which use the same Vector3(radius, half_height, radius) convention),
		# so it needs a hand-built basis with Y aligned to the twig's own
		# direction -- look_at() aims local -Z at a target instead, the wrong
		# axis for a box whose length runs along Y.
		var twig_up := tip.normalized()
		var side := Vector3.RIGHT if absf(twig_up.dot(Vector3.RIGHT)) < 0.9 else Vector3.FORWARD
		var twig_x := side.cross(twig_up).normalized()
		var twig_z := twig_up.cross(twig_x).normalized()
		var stub := SuperEgg.build_part(
			Vector3(0.08, length * 0.5, 0.08), TRUNK_COLOR.lightened(0.05),
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		stub.transform = Transform3D(
			Basis(twig_x, twig_up, twig_z), Vector3(trunk_r * dir.x, y, trunk_r * dir.z) + tip * 0.5
		)
		body.add_child(stub)

		var leaf_radius := rng.randf_range(EMERGENT_TWIG_LEAF_MIN, EMERGENT_TWIG_LEAF_MAX)
		var leaf := SuperEgg.build_part(
			Vector3(leaf_radius, leaf_radius * 0.7, leaf_radius), leaf_color,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		leaf.position = Vector3(trunk_r * dir.x, y, trunk_r * dir.z) + tip
		body.add_child(leaf)


static func _add_cylinder_collision(body: StaticBody3D, pos: Vector3, radius: float, height: float, basis: Basis = Basis()) -> void:
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = height
	var shape := CollisionShape3D.new()
	shape.shape = cyl
	shape.transform = Transform3D(basis, pos)
	body.add_child(shape)


## Registers an unrotated, axis-aligned "top surface" blob (local-space
## center + semi_axes) for the one-way canopy-support system -- same
## approximation CloudScatter's own cloud puffs use for their tops, just
## stored as body-level metadata here rather than a dedicated puff node,
## since wilderness_scatter.gd only resolves these to world space once,
## right after each tree is placed/rotated/scaled into the scene (trees
## never move again afterward -- see that file's _register_canopy_blobs()
## and get_support_height_at()). Deliberately NOT a real CollisionShape3D:
## per direct instruction, tree foliage should be walkable underneath/
## through the sides but landable on top, which Godot's 3D physics has no
## built-in one-way collision for (unlike PhysicsBody2D).
static func _add_canopy_blob(body: StaticBody3D, local_pos: Vector3, semi_axes: Vector3) -> void:
	var blobs: Array = body.get_meta("canopy_blobs", [])
	blobs.append({"local_pos": local_pos, "semi_axes": semi_axes})
	body.set_meta("canopy_blobs", blobs)


## Builds one droop-arching frond/leaf as a short chain of tapering segments
## whose downward pitch accumulates segment to segment (steepest near the
## tip, eased in via t*t -- the same ease-in-drift shape build_palm_tree()'s
## own leaning trunk segments already use for a smooth curve) -- so the
## whole frond reads as a continuous arc instead of one rigid straight
## blade. Used by both build_palm_tree()'s fronds and build_banana_tree()'s
## leaves.
static func _build_arching_frond(
	parent: Node3D, azimuth: float, length: float, base_half_width: float, tip_half_width: float,
	half_depth: float, color: Color, base_droop_deg: float, tip_extra_droop_deg: float, segments: int = 3
) -> void:
	var azimuth_pivot := Node3D.new()
	azimuth_pivot.rotation.y = azimuth
	azimuth_pivot.rotation.x = deg_to_rad(-base_droop_deg)
	parent.add_child(azimuth_pivot)

	var seg_length := length / segments
	var pivot: Node3D = azimuth_pivot
	for i in segments:
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var seg_pivot := Node3D.new()
		seg_pivot.rotation.x = deg_to_rad(-tip_extra_droop_deg * (t1 * t1 - t0 * t0))
		pivot.add_child(seg_pivot)

		var half_width := lerpf(base_half_width, tip_half_width, t0)
		var seg := SuperEgg.build_part(
			Vector3(half_width, seg_length * 0.5, half_depth), color,
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
		)
		seg.position = Vector3(0, seg_length * 0.5, 0)
		seg_pivot.add_child(seg)

		var next_pivot := Node3D.new()
		next_pivot.position = Vector3(0, seg_length, 0)
		seg_pivot.add_child(next_pivot)
		pivot = next_pivot


static func _add_box_collision(body: StaticBody3D, pos: Vector3, size: Vector3, basis: Basis = Basis()) -> void:
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.transform = Transform3D(basis, pos)
	body.add_child(shape)
