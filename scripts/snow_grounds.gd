class_name SnowGrounds
extends RefCounted

## The Snow Village's grounds: fences and gates, raised beds under glass cold
## frames, a wood yard, snow banks, firewood. Everything is SuperEgg; solids carry
## collision, crops and snow are decorative. Positions are world coordinates (the
## caller samples the ground height).

const TIMBER := Color(0.34, 0.24, 0.16)
const BOARD := Color(0.46, 0.34, 0.22)
const SNOW := Color(0.95, 0.97, 1.0)
const SOIL := Color(0.30, 0.22, 0.17)


static func _holder(parent: Node3D, at: Vector3, yaw: float, label: String) -> StaticBody3D:
	var holder := StaticBody3D.new()
	holder.name = label
	holder.collision_layer = 1
	holder.collision_mask = 0
	holder.position = at
	holder.rotation.y = yaw
	parent.add_child(holder)
	return holder


static func _court_part(
	body: StaticBody3D, half: Vector3, color: Color, at: Vector3,
	basis: Basis = Basis(), solid: bool = true, parkour: bool = true,
	epsilon: float = SuperEgg.EPSILON_FLAT
) -> MeshInstance3D:
	var part := SuperEgg.build_part(half, color, epsilon, epsilon)
	part.transform = Transform3D(basis, at)
	body.add_child(part)
	if solid:
		CollisionPolicy.add_box(body, part, half * 2.0, at, basis, parkour)
	else:
		CollisionPolicy.mark_decorative(part)
	return part


## The common yard's winter social anchor. A permanent raised iron bålpanne
## replaces the former loose campfire: a shallow pan on three stout legs, a
## snow-cleared flagstone court and three high-backed settles with clear gaps
## between them for circulation. The underlying terrain remains the walking
## collider, so the thin fitted paving cannot create a second snagging floor.
static func communal_hearth_court(parent: Node3D, at: Vector3, radius: float) -> StaticBody3D:
	var body := _holder(parent, at, 0.0, "CommunalHearthStructure")
	var iron := Color(0.12, 0.14, 0.16)
	var iron_highlight := Color(0.24, 0.27, 0.29)
	var paving := Color(0.52, 0.54, 0.56)

	# Two broken rings of broad pavers make a maintained, snow-cleared court,
	# never a raised platform. Alternating gaps prevent a tiled-pizza pattern.
	for ring in 2:
		var count := 12 + ring * 6
		var ring_radius := 1.65 + float(ring) * 1.22
		for index in count:
			var angle := TAU * (float(index) + 0.5 * float(ring % 2)) / float(count)
			var radial := Vector3(cos(angle), 0.0, sin(angle))
			var chord := TAU * ring_radius / float(count) * 0.43
			_court_part(
				body, Vector3(chord, 0.035, 0.48),
				paving.lightened(0.018 * float((index + ring) % 4)),
				radial * ring_radius + Vector3(0.0, 0.025, 0.0),
				Basis(Vector3.UP, PI * 0.5 - angle), false, false
			)

	# Three splayed legs carry the pan above the snow. Three is structurally
	# stable here and belongs to the fire-pan object, not to a building facade.
	for leg_index in 3:
		var angle := TAU * float(leg_index) / 3.0 + PI / 6.0
		var lower := Vector3(cos(angle) * 0.72, 0.08, sin(angle) * 0.72)
		var upper := Vector3(cos(angle) * 0.94, 0.78, sin(angle) * 0.94)
		var delta := upper - lower
		var leg := SuperEgg.build_part(
			Vector3(0.09, delta.length() * 0.5, 0.09), iron_highlight,
			SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		leg.position = (lower + upper) * 0.5
		leg.basis = Basis(Quaternion(Vector3.UP, delta.normalized()))
		body.add_child(leg)
		CollisionPolicy.mark_decorative(leg)

	# A smaller underside and wider upper pan give the silhouette a real taper.
	var underside := SuperEgg.build_part(Vector3(0.78, 0.15, 0.78), iron, 2.2, 2.2)
	underside.position.y = 0.76
	body.add_child(underside)
	CollisionPolicy.mark_decorative(underside)
	var pan := SuperEgg.build_part(Vector3(1.25, 0.16, 1.25), iron, 2.2, 2.2)
	pan.position.y = 0.91
	body.add_child(pan)
	CollisionPolicy.add_cylinder(body, pan, 1.25, 1.06, Vector3(0.0, 0.53, 0.0), false)
	var ember_bed := SuperEgg.build_part(Vector3(0.92, 0.055, 0.92), Color(0.25, 0.09, 0.045), 2.3, 2.3)
	ember_bed.position.y = 1.07
	body.add_child(ember_bed)
	CollisionPolicy.mark_decorative(ember_bed)
	for rim_index in 16:
		var angle := TAU * (float(rim_index) + 0.5) / 16.0
		var radial := Vector3(cos(angle), 0.0, sin(angle))
		_court_part(
			body, Vector3(0.22, 0.065, 0.085), iron_highlight,
			radial * 1.14 + Vector3(0.0, 1.12, 0.0),
			Basis(Vector3.UP, PI * 0.5 - angle), false, false, SuperEgg.EPSILON_SOFT
		)
	for log_index in 4:
		var log := SuperEgg.build_part(Vector3(0.65, 0.075, 0.075), TIMBER, 3.8, 3.8)
		log.position = Vector3(0.0, 1.14 + 0.035 * float(log_index % 2), 0.0)
		log.rotation.y = PI * 0.25 + PI * 0.5 * float(log_index % 2)
		body.add_child(log)
		CollisionPolicy.mark_decorative(log)

	var fire := ParticleFX.build_flame_particles(18, 0.95, 1.5, 1.7, 3.0, -0.45)
	fire.position.y = 1.18
	body.add_child(fire)
	CollisionPolicy.mark_decorative(fire)
	var glow := OmniLight3D.new()
	glow.position.y = 1.75
	glow.light_color = Color(1.0, 0.56, 0.24)
	glow.light_energy = 1.55
	glow.omni_range = 13.0
	glow.shadow_enabled = false
	body.add_child(glow)

	# Substantial backed settles replace the six loose ground logs. The opening
	# between each pair remains wider than a mount, keeping the court permeable.
	for bench_angle in [0.2, 2.3, 4.35]:
		var radial := Vector3(cos(bench_angle), 0.0, sin(bench_angle))
		var centre := radial * (radius - 0.35)
		var basis := Basis(Vector3.UP, PI * 0.5 - bench_angle)
		_court_part(body, Vector3(1.05, 0.07, 0.31), BOARD, centre + Vector3(0.0, 0.52, 0.0), basis)
		_court_part(body, Vector3(1.05, 0.43, 0.055), TIMBER, centre + radial * 0.31 + Vector3(0.0, 0.96, 0.0), basis)
		for end in [-0.82, 0.82]:
			var support := centre + basis * Vector3(float(end), 0.25, 0.0)
			_court_part(body, Vector3(0.07, 0.25, 0.27), TIMBER, support, basis, true, false)
			var strap := centre + radial * 0.375 + basis * Vector3(float(end), 0.92, 0.0)
			_court_part(body, Vector3(0.025, 0.31, 0.018), iron_highlight, strap, basis, false, false)
	return body


## A run of fence between two world points: posts every ~2 m and either two rails
## (1.1 m) or solid boards (1.8 m, the windbreak).
static func fence_run(parent: Node3D, a: Vector3, b: Vector3, windbreak: bool) -> void:
	var length := Vector2(b.x - a.x, b.z - a.z).length()
	if length < 0.3:
		return
	var yaw := atan2(-(b.z - a.z), b.x - a.x)
	var height := 1.8 if windbreak else 1.1
	var mid := (a + b) * 0.5
	var holder := _holder(parent, mid, yaw, "WindbreakFence" if windbreak else "RailFence")
	var posts := maxi(int(ceil(length / 2.0)), 1) + 1
	for i in posts:
		var x := lerpf(-length * 0.5, length * 0.5, float(i) / float(posts - 1))
		var post := SuperEgg.build_part(Vector3(0.1, height * 0.5 + 0.1, 0.1), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		post.position = Vector3(x, height * 0.5, 0.0)
		holder.add_child(post)
		CollisionPolicy.mark_decorative(post)
	if windbreak:
		var boards := SuperEgg.build_part(Vector3(length * 0.5, height * 0.5 - 0.1, 0.045), BOARD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		boards.position = Vector3(0.0, height * 0.5 + 0.05, 0.1)
		holder.add_child(boards)
		CollisionPolicy.add_box(holder, boards, Vector3(length, height - 0.2, 0.2), boards.position, Basis(), true)
		for i in 5:
			var seam := SuperEgg.build_part(Vector3(length * 0.5, 0.012, 0.01), TIMBER.darkened(0.2), 4.0, 4.0)
			seam.position = Vector3(0.0, 0.4 + float(i) * 0.32, 0.15)
			holder.add_child(seam)
			CollisionPolicy.mark_decorative(seam)
	else:
		for rail_y: float in [0.5, 0.95]:
			var rail := SuperEgg.build_part(Vector3(length * 0.5, 0.045, 0.04), BOARD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			rail.position = Vector3(0.0, rail_y, 0.0)
			holder.add_child(rail)
			CollisionPolicy.mark_decorative(rail)
		CollisionPolicy.add_box(holder, holder, Vector3(length, height, 0.2), Vector3(0.0, height * 0.5, 0.0), Basis(), false)


## A wicket gate: hinge and latch posts and a half-open leaf, 1.2 m clear.
static func gate(parent: Node3D, at: Vector3, yaw: float) -> void:
	var holder := _holder(parent, at, yaw, "Gate")
	for side: float in [-1.0, 1.0]:
		var post := SuperEgg.build_part(Vector3(0.1, 0.65, 0.1), TIMBER, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		post.position = Vector3(side * 0.7, 0.65, 0.0)
		holder.add_child(post)
		CollisionPolicy.add_box(holder, post, Vector3(0.2, 1.3, 0.2), post.position, Basis(), false)
	var leaf := SuperEgg.build_part(Vector3(0.5, 0.4, 0.04), BOARD, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	leaf.position = Vector3(-0.62, 0.62, 0.45)
	leaf.rotation.y = PI * 0.5 - 0.15
	holder.add_child(leaf)
	CollisionPolicy.mark_decorative(leaf)


## A raised bed with a timber edge. `kind`: frame (a glass cold frame over soil),
## leeks, kale. Long side along local X.
static func bed(parent: Node3D, at: Vector3, size: Vector2, kind: String, seed_value: int) -> void:
	var holder := _holder(parent, at, 0.0, "Bed_" + kind)
	var edge_color := TIMBER.lightened(0.05)
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	var soil := SuperEgg.build_part(Vector3(half_x - 0.05, 0.13, half_z - 0.05), SOIL, 3.0, 3.0)
	soil.position.y = 0.2
	holder.add_child(soil)
	CollisionPolicy.mark_decorative(soil)
	for sz: float in [-1.0, 1.0]:
		var side := SuperEgg.build_part(Vector3(half_x, 0.17, 0.05), edge_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		side.position = Vector3(0.0, 0.17, sz * half_z)
		holder.add_child(side)
		CollisionPolicy.mark_decorative(side)
	for sx: float in [-1.0, 1.0]:
		var end := SuperEgg.build_part(Vector3(0.05, 0.17, half_z), edge_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		end.position = Vector3(sx * half_x, 0.17, 0.0)
		holder.add_child(end)
		CollisionPolicy.mark_decorative(end)
	CollisionPolicy.add_box(holder, holder, Vector3(size.x, 0.4, size.y), Vector3(0.0, 0.2, 0.0), Basis(), true)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	match kind:
		"frame":
			# A sloped glass lid on a low timber frame, snow resting on its upper half.
			var tilt := Basis(Vector3.BACK, 0.0) * Basis(Vector3.RIGHT, deg_to_rad(-14.0))
			var glass := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(size.x - 0.2, 0.04, size.y - 0.1)
			glass.mesh = box
			glass.material_override = SolidModel.material(Color(0.62, 0.82, 0.9, 0.42), 0.12, 0.0)
			glass.transform = Transform3D(tilt, Vector3(0.0, 0.62, 0.0))
			holder.add_child(glass)
			CollisionPolicy.mark_decorative(glass)
			for i in 4:
				var bar := SuperEgg.build_part(Vector3(0.025, 0.03, half_z - 0.05), edge_color, 4.0, 4.0)
				bar.transform = Transform3D(tilt, Vector3(-half_x + 0.3 + float(i) * (size.x - 0.6) / 3.0, 0.63, 0.0))
				holder.add_child(bar)
				CollisionPolicy.mark_decorative(bar)
			var cap := SuperEgg.build_part(Vector3(half_x - 0.4, 0.04, half_z * 0.45), SNOW, 3.6, 3.6)
			cap.transform = Transform3D(tilt, Vector3(0.0, 0.67, half_z * 0.35))
			holder.add_child(cap)
			CollisionPolicy.mark_decorative(cap)
			for sx: float in [-1.0, 1.0]:
				var prop := SuperEgg.build_part(Vector3(0.03, 0.28, 0.03), edge_color, 4.0, 4.0)
				prop.position = Vector3(sx * (half_x - 0.1), 0.56, -half_z + 0.1)
				holder.add_child(prop)
				CollisionPolicy.mark_decorative(prop)
		"leeks":
			# Dense rows of upright leeks, white at the foot and blue-green above.
			for row in 3:
				for i in int(size.x / 0.22):
					var x := -half_x + 0.2 + float(i) * 0.22
					var z := (float(row) - 1.0) * 0.32
					var leek := SuperEgg.build_part(Vector3(0.05, 0.2 + rng.randf_range(0.0, 0.06), 0.05), Color(0.26, 0.5, 0.42), 2.6, 2.6)
					leek.position = Vector3(x, 0.52, z)
					holder.add_child(leek)
					CollisionPolicy.mark_decorative(leek)
		_:
			# Kale: close drifts of dark, frilled heads.
			for row in 2:
				for i in int(size.x / 0.5):
					var x := -half_x + 0.35 + float(i) * 0.5 + rng.randf_range(-0.04, 0.04)
					var z := (float(row) - 0.5) * 0.55
					var head := SuperEgg.build_part(Vector3(0.2, 0.17, 0.2), Color(0.18, 0.34, 0.26).lerp(Color(0.34, 0.2, 0.4), rng.randf() * 0.5), 2.4, 2.2)
					head.position = Vector3(x, 0.42, z)
					holder.add_child(head)
					CollisionPolicy.mark_decorative(head)


static func water_barrel(parent: Node3D, at: Vector3) -> void:
	var holder := _holder(parent, at, 0.0, "WaterBarrel")
	var barrel := SuperEgg.build_part(Vector3(0.36, 0.5, 0.36), Furnishings.OAK, 2.2, 2.4)
	barrel.position.y = 0.5
	holder.add_child(barrel)
	CollisionPolicy.add_cylinder(holder, barrel, 0.36, 1.0, barrel.position, false)
	var ice := SuperEgg.build_part(Vector3(0.3, 0.03, 0.3), Color(0.74, 0.88, 0.96), 2.4, 2.4)
	ice.position.y = 0.98
	holder.add_child(ice)
	CollisionPolicy.mark_decorative(ice)
	for level: float in [0.3, 0.7]:
		var hoop := SuperEgg.build_part(Vector3(0.375, 0.03, 0.375), Furnishings.IRON, 2.2, 2.2)
		hoop.position.y = level
		holder.add_child(hoop)
		CollisionPolicy.mark_decorative(hoop)


## A compost heap under snow: a low brown mound with a white cap and straw.
static func compost(parent: Node3D, at: Vector3) -> void:
	var holder := _holder(parent, at, 0.0, "CompostHeap")
	var heap := SuperEgg.build_part(Vector3(0.9, 0.38, 0.75), Color(0.32, 0.25, 0.18), 2.4, 2.2)
	heap.position.y = 0.25
	holder.add_child(heap)
	CollisionPolicy.add_box(holder, heap, Vector3(1.6, 0.7, 1.4), heap.position, Basis(), true)
	var cap := SuperEgg.build_part(Vector3(0.7, 0.1, 0.55), SNOW, 3.0, 3.0)
	cap.position = Vector3(0.1, 0.56, 0.0)
	holder.add_child(cap)
	CollisionPolicy.mark_decorative(cap)


static func chopping_block(parent: Node3D, at: Vector3) -> void:
	var holder := _holder(parent, at, 0.0, "ChoppingBlock")
	var block := SuperEgg.build_part(Vector3(0.28, 0.24, 0.28), Color(0.5, 0.36, 0.22), 2.4, 3.2)
	block.position.y = 0.24
	holder.add_child(block)
	CollisionPolicy.add_cylinder(holder, block, 0.28, 0.48, block.position, true)
	var axe := SuperEgg.build_part(Vector3(0.02, 0.28, 0.02), TIMBER, 3.0, 3.0)
	axe.position = Vector3(0.1, 0.62, 0.0)
	axe.rotation.z = 0.25
	holder.add_child(axe)
	CollisionPolicy.mark_decorative(axe)
	var head := SuperEgg.build_part(Vector3(0.1, 0.07, 0.025), Furnishings.IRON, 3.0, 3.0)
	head.position = Vector3(0.0, 0.85, 0.0)
	head.rotation.z = 0.25
	holder.add_child(head)
	CollisionPolicy.mark_decorative(head)


static func sawhorse(parent: Node3D, at: Vector3, yaw: float) -> void:
	var holder := _holder(parent, at, yaw, "Sawhorse")
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var leg := SuperEgg.build_part(Vector3(0.04, 0.4, 0.04), TIMBER, 4.0, 4.0)
			leg.position = Vector3(sx * 0.5, 0.4, sz * 0.22)
			leg.rotation.z = -sx * 0.18
			holder.add_child(leg)
			CollisionPolicy.mark_decorative(leg)
	var beam := SuperEgg.build_part(Vector3(0.65, 0.05, 0.05), BOARD, 4.0, 4.0)
	beam.position.y = 0.78
	holder.add_child(beam)
	CollisionPolicy.add_box(holder, beam, Vector3(1.3, 0.1, 0.1), beam.position, Basis(), false)
	var log := SuperEgg.build_part(Vector3(0.55, 0.11, 0.11), LogHouse.LOG_COLORS[1], 3.4, 3.4)
	log.position = Vector3(0.1, 0.94, 0.0)
	holder.add_child(log)
	CollisionPolicy.mark_decorative(log)


## A soft drift of snow banked against a wall, below the window sills. Long side
## along local X; `yaw` turns it parallel to the wall.
static func snow_bank(parent: Node3D, at: Vector3, length: float, yaw: float, height: float, seed_value: int) -> void:
	var holder := _holder(parent, at, yaw, "SnowBank")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var pieces := maxi(int(length / 1.4), 1)
	for i in pieces:
		var x := lerpf(-length * 0.5 + 0.7, length * 0.5 - 0.7, float(i) / float(maxi(pieces - 1, 1))) if pieces > 1 else 0.0
		var h := height * rng.randf_range(0.75, 1.0)
		var drift := SuperEgg.build_part(Vector3(rng.randf_range(0.85, 1.15), h * 0.5, rng.randf_range(0.5, 0.65)), SNOW, 2.2, 2.0)
		drift.position = Vector3(x, h * 0.35, rng.randf_range(-0.08, 0.08))
		holder.add_child(drift)
		CollisionPolicy.mark_decorative(drift)
