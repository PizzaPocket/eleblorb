class_name IceLakeFeatures
extends RefCounted

## Two things under and at the rim of the Ice Kingdom's frozen lake:
##   a sunken ice-fisher's skiff on the lake floor near the fishing hole, with a
##   carved penguin figurehead and a frost-sealed chest holding the Penguin Helm;
##   a great alpine cedar that fell from the bank and broke the ice at the rim,
##   leaving a gap of open water. The trunk runs from the root ball on the shore
##   down under the ice, so a swimmer who surfaces in the gap can climb out along
##   it. See docs/world_bible.md, Ice Kingdom.

const HELM_LOOT_ID := "ice_lake_penguin_helm"
const BARK := Color(0.30, 0.21, 0.15)
const BARK_WET := Color(0.20, 0.17, 0.15)
const PLANK := Color(0.40, 0.30, 0.22)
const ICE := Color(0.72, 0.88, 0.96)


static func build(terrain: Node) -> void:
	var parent: Node = terrain.get_parent()
	if parent == null:
		return
	_sunken_skiff(terrain, parent)
	_fallen_cedar(terrain, parent)


static func _ground(terrain: Node, at: Vector2) -> float:
	return terrain.get_mesh_height(at.x, at.y)


## The wreck lies near the fishing hole, out of the straight line below it, so a
## swimmer who dives through the hole sees the pale glow before the hull.
static func _sunken_skiff(terrain: Node, parent: Node) -> void:
	var hole: Vector2 = terrain.get_fishing_hole_center()
	var at: Vector2 = hole + Vector2(7.0, -3.0)
	var floor_y: float = _ground(terrain, at)
	var wreck := StaticBody3D.new()
	wreck.name = "SunkenSkiff"
	wreck.collision_layer = 1
	wreck.position = Vector3(at.x, floor_y, at.y)
	wreck.rotation = Vector3(0.12, 0.7, -0.1)
	parent.add_child(wreck)
	var hull := SuperEgg.build_part(Vector3(2.3, 0.5, 0.95), PLANK, 2.4, 2.2)
	hull.position.y = 0.32
	wreck.add_child(hull)
	CollisionPolicy.add_box(wreck, hull, Vector3(4.6, 1.0, 1.9), hull.position, Basis(), true)
	for side: float in [-1.0, 1.0]:
		var gunwale := SuperEgg.build_part(Vector3(2.1, 0.07, 0.07), PLANK.darkened(0.2), 4.0, 4.0)
		gunwale.position = Vector3(0.0, 0.82, side * 0.78)
		wreck.add_child(gunwale)
		CollisionPolicy.mark_decorative(gunwale)
	for i in 4:
		var rib := SuperEgg.build_part(Vector3(0.06, 0.34, 0.8), PLANK.darkened(0.3), 4.0, 4.0)
		rib.position = Vector3(-1.4 + float(i) * 0.95, 0.62, 0.0)
		wreck.add_child(rib)
		CollisionPolicy.mark_decorative(rib)
	var mast := SuperEgg.build_part(Vector3(0.06, 0.9, 0.06), PLANK.darkened(0.25), 4.0, 4.0)
	mast.position = Vector3(0.4, 1.5, 0.0)
	mast.rotation.z = 0.5
	wreck.add_child(mast)
	CollisionPolicy.mark_decorative(mast)
	# The carved penguin figurehead on the prow: the helm's own maker's mark.
	var prow := Vector3(2.45, 0.95, 0.0)
	var body := SuperEgg.build_part(Vector3(0.2, 0.34, 0.17), Color(0.08, 0.1, 0.14), 2.2, 2.2)
	body.position = prow + Vector3(0.0, 0.3, 0.0)
	wreck.add_child(body)
	CollisionPolicy.mark_decorative(body)
	var belly := SuperEgg.build_part(Vector3(0.12, 0.26, 0.1), Color(0.9, 0.92, 0.94), 2.2, 2.2)
	belly.position = prow + Vector3(0.1, 0.28, 0.0)
	wreck.add_child(belly)
	CollisionPolicy.mark_decorative(belly)
	var beak := SuperEgg.build_part(Vector3(0.12, 0.04, 0.05), Color(0.82, 0.5, 0.18), 2.4, 2.4)
	beak.position = prow + Vector3(0.28, 0.5, 0.0)
	wreck.add_child(beak)
	CollisionPolicy.mark_decorative(beak)
	# The sealed chest rests on the hull's floorboards, rimed with frost, with a
	# cold blue glow to guide a diver.
	var chest_holder := StaticBody3D.new()
	chest_holder.collision_layer = 1
	chest_holder.position = Vector3(-0.5, 0.78, 0.0)
	wreck.add_child(chest_holder)
	var loot: Array[Dictionary] = [{"name": "Penguin Helm"}]
	Furnishings.chest(chest_holder, Vector3.ZERO, 0.0, Furnishings.OAK_DARK.darkened(0.25), 1.0, HELM_LOOT_ID, loot)
	var frost := SuperEgg.build_part(Vector3(0.52, 0.04, 0.32), ICE, 4.0, 4.0)
	frost.position = Vector3(0.0, 0.47, 0.0)
	chest_holder.add_child(frost)
	CollisionPolicy.mark_decorative(frost)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.2, 0.0)
	glow.light_color = Color(0.55, 0.82, 1.0)
	glow.light_energy = 1.6
	glow.omni_range = 11.0
	glow.shadow_enabled = false
	wreck.add_child(glow)


## A cedar fallen from the bank into the lake. Root ball on the shore, trunk
## sloping down through the gap and under the ice; side stubs for handholds.
static func _fallen_cedar(terrain: Node, parent: Node) -> void:
	var gap: Vector2 = terrain.ice_break_center()
	var lake_center: Vector2 = terrain.get_lake_center()
	var into: Vector2 = (lake_center - gap).normalized()
	# The root ball stands on the bank 8 m inland, raised on its own earth, so the
	# trunk leaves the bank high enough to break the surface for a few metres
	# inside the gap and then sinks gently under the ice. The bank below the gap
	# is nearly a cliff, so the crown hangs snagged over deep water.
	var root_ground: Vector2 = gap - into * 8.0
	var root_y: float = float(terrain.ICE_LEVEL) + 1.8
	var length := 24.0
	var slope := 0.28
	var crown_xz: Vector2 = root_ground + into * length
	var crown_y: float = root_y - length * slope
	var tree := StaticBody3D.new()
	tree.name = "FallenCedar"
	tree.collision_layer = 1
	parent.add_child(tree)
	var segments := 6
	var previous := Vector3(root_ground.x, root_y, root_ground.y)
	for i in segments:
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var a := Vector3(
			lerpf(root_ground.x, crown_xz.x, t0), lerpf(root_y, crown_y, t0), lerpf(root_ground.y, crown_xz.y, t0)
		)
		var b := Vector3(
			lerpf(root_ground.x, crown_xz.x, t1), lerpf(root_y, crown_y, t1), lerpf(root_ground.y, crown_xz.y, t1)
		)
		var radius := lerpf(0.78, 0.3, (t0 + t1) * 0.5)
		var run := a.distance_to(b)
		var direction := (b - a).normalized()
		var up := Vector3.UP.slide(direction).normalized()
		var basis := Basis(up.cross(direction).normalized(), up, direction)
		var piece := SuperEgg.build_part(Vector3(radius, radius, run * 0.5 + 0.04), BARK if t0 < 0.4 else BARK_WET, 2.3, 4.0)
		piece.transform = Transform3D(basis, (a + b) * 0.5)
		tree.add_child(piece)
		CollisionPolicy.add_box(tree, piece, Vector3(radius * 1.8, radius * 1.8, run), piece.position, basis, true)
		# Snow rides the top of the dry part of the trunk.
		if (a.y + b.y) * 0.5 > -3.3:
			var cap := SuperEgg.build_part(Vector3(radius * 0.8, 0.07, run * 0.5), ElementPalette.SNOW_BODY, 3.0, 3.0)
			cap.transform = Transform3D(basis, (a + b) * 0.5 + up * (radius * 0.9))
			tree.add_child(cap)
			CollisionPolicy.mark_decorative(cap)
		# Branch stubs: handholds for a swimmer, and the look of a felled tree.
		var stub_count := 2
		for k in stub_count:
			var angle := float(i * 3 + k) * 2.1
			var offset := Vector3(cos(angle), sin(angle), 0.0)
			var side := basis * Vector3(offset.x, offset.y, 0.0)
			var stub := SuperEgg.build_part(Vector3(0.11, 0.11, 0.55), BARK.darkened(0.1), 3.0, 3.0)
			var stub_basis := Basis(side.cross(direction).normalized(), side, direction.rotated(side, 0.5)).orthonormalized()
			stub.transform = Transform3D(stub_basis, (a + b) * 0.5 + side * (radius + 0.2))
			tree.add_child(stub)
			CollisionPolicy.mark_decorative(stub)
	# Root ball: a standing disc of earth and roots at the shore end.
	var ball_basis := Basis(Vector3.UP.cross(Vector3(into.x, 0.0, into.y)).normalized(), Vector3.UP, Vector3(into.x, 0.0, into.y)).orthonormalized()
	var ball := SuperEgg.build_part(Vector3(1.7, 1.5, 0.45), Color(0.28, 0.22, 0.17), 2.6, 3.0)
	ball.transform = Transform3D(ball_basis, Vector3(root_ground.x, root_y + 0.5, root_ground.y) - Vector3(into.x, 0.0, into.y) * 0.4)
	tree.add_child(ball)
	CollisionPolicy.add_box(tree, ball, Vector3(3.4, 3.0, 0.9), ball.position, ball_basis, false)
	# The crown: dark boughs under the ice, lodged on the slope.
	for i in 5:
		var spread := float(i) / 4.0 - 0.5
		var bough := SuperEgg.build_part(Vector3(1.4, 0.25, 0.9), Color(0.1, 0.22, 0.17), 2.6, 2.6)
		bough.position = Vector3(crown_xz.x + spread * 2.4, crown_y + 0.2, crown_xz.y) + Vector3(into.x, 0.0, into.y) * (0.6 * float(i % 2))
		bough.rotation.y = into.angle() + spread
		tree.add_child(bough)
		CollisionPolicy.mark_decorative(bough)
	# Broken ice: slabs tilted at the gap's lake-side rim.
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 8:
		var angle := into.angle() + rng.randf_range(-1.5, 1.5)
		var distance: float = float(terrain.ICE_BREAK_RADIUS) + rng.randf_range(-0.8, 1.2)
		var spot: Vector2 = gap + Vector2(cos(angle), sin(angle)) * distance
		var slab := SuperEgg.build_part(Vector3(rng.randf_range(0.9, 1.7), 0.19, rng.randf_range(0.7, 1.2)), ICE, 4.0, 4.0)
		slab.position = Vector3(spot.x, float(terrain.WATER_LEVEL) + 0.05, spot.y)
		slab.rotation = Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.0, TAU), rng.randf_range(-0.2, 0.2))
		tree.add_child(slab)
		CollisionPolicy.mark_decorative(slab)
