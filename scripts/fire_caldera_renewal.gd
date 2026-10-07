class_name FireCalderaRenewal
extends RefCounted

## The Renewal terrace (fire_caldera_buildings.md, section 3; landmark): the
## city's ghat. As on a river ghat, a broad flight of steps runs from the
## street down into the lava, and the steps are the use: the dry upper steps
## are seats for resting, talking and watching; on the waterline step people
## sit half immersed together; the lower steps carry on under the lava as the
## immersion shelf, the gentlest way down to the renewal chamber. At the foot
## of the central flight a dark refractory threshold arch stands half sunk,
## the way down and the place of the coming-of-age descent.
##
## The promenade runs along a level landing at the top, flush with it: that is
## the arrival. Along the landing's back, the cast-basalt memory stones face
## the water, the backdrop to every gathering; at its east end, under a veiled
## glass windbreak, Eris's warm tempering slab, where she helps those too
## cracked or cooled to walk straight in. Two arms frame the flight and run out
## over the lava; the canopy's supports stand on them and on the landing.
##
## Its own idea above: a catenary canopy of slumped glass. The lava people
## hang molten glass over chains and let it settle into its own curve, so the
## roof is drawn by heat and gravity: forged iron ribs on the same catenary on
## branching supports, the panels shading from teal at the springing through
## garnet to amber at the crown, washing the steps in coloured light.
##
## Its foundation is its own, not a plinth: a U-shaped deck level with the
## promenade, cut to the plot's outline, open at the front to the steps, with
## a retaining wall only where the ground behind stands higher. Local +Z faces
## the reservoir.

const SPAN := 17.0
const CROWN := 6.2
const SPRING := 3.0
## The canopy covers the whole deck, the promenade's crossing included; every
## support's foot bears on the deck, back from its rounded corners.
const BACK_Z := -6.6
const FRONT_Z := 6.2
## Magnesia-chrome refractory, the near-black brick that lines furnaces
## against molten slag: whatever contains or stands in the lava (the pool,
## channel and basin's linings, the immersion stair) and the shoes that part
## iron from hot stone. Dark, so it reads as part of the basalt quay.
const REFRACTORY := Color(0.21, 0.18, 0.17)
const RIBS := 6
const SEGMENTS := 16
## The flight: its half width, each step's going and rise, how many.
const FLIGHT_HALF := 7.0
const GOING := 0.9
const RISE := 0.45
const FLIGHT := 7
const DEEP := 6.0
## The deck's front edge, where the flight begins.
const FLIGHT_START := 0.3
const TEAL := Color(0.18, 0.60, 0.58, 0.55)
const GARNET := Color(0.62, 0.14, 0.22, 0.55)
const AMBER := Color(0.95, 0.58, 0.16, 0.55)
const IRON := CalderaShell.STEEL_BLUED


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.make_body(parent, entry, float(line["datum"]))
	_threshold(body)
	_canopy(body)
	_supports(body)
	_memory_stones(body)
	_windbreaks(body)
	_tempering_slab(body)
	_light(body)
	return body


## The ghat's foundation, in place of a plinth: the U-shaped deck (the plot's
## outline less the flight), its walls running down into the ground and the
## lava; the flight of refractory steps; a retaining wall where the ground
## behind stands above the deck. One body, named as a plinth is.
static func build_foundation(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var datum := float(line["datum"])
	var body := CalderaShell.make_body(parent, entry, datum)
	body.name = "%sPlinth" % entry["id"]
	var outline := PackedVector2Array()
	var plan_outline := SocketPlinth.exclusion(entry, line)
	for point in plan_outline:
		outline.append(FireCalderaPlan.plan_to_shell(entry, point))
	var flight := PackedVector2Array([Vector2(-FLIGHT_HALF, FLIGHT_START), Vector2(FLIGHT_HALF, FLIGHT_START), Vector2(FLIGHT_HALF, 20.0), Vector2(-FLIGHT_HALF, 20.0)])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var deck := CalderaShell.BASALT.lightened(0.1)
	for piece in Geometry2D.clip_polygons(outline, flight):
		var triangles := Geometry2D.triangulate_polygon(piece)
		for t in range(0, triangles.size(), 3):
			var tri := [piece[triangles[t]], piece[triangles[t + 1]], piece[triangles[t + 2]]]
			_tri(st, faces, Vector3(tri[0].x, 0, tri[0].y), Vector3(tri[1].x, 0, tri[1].y), Vector3(tri[2].x, 0, tri[2].y), Vector3.UP, deck)
		for i in piece.size():
			var a: Vector2 = piece[i]
			var b: Vector2 = piece[(i + 1) % piece.size()]
			var mid := (a + b) * 0.5
			var out := Vector2(b.y - a.y, a.x - b.x).normalized()
			if Geometry2D.is_point_in_polygon(mid + out * 0.05, piece):
				out = -out
			var n := Vector3(out.x, 0, out.y)
			var colour := REFRACTORY if absf(a.x) < FLIGHT_HALF + 0.01 and absf(b.x) < FLIGHT_HALF + 0.01 and a.y > FLIGHT_START - 0.01 and b.y > FLIGHT_START - 0.01 else CalderaShell.BASALT
			_tri(st, faces, Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(b.x, -DEEP, b.y), n, colour)
			_tri(st, faces, Vector3(a.x, 0, a.y), Vector3(b.x, -DEEP, b.y), Vector3(a.x, -DEEP, a.y), n, colour)
	var mesh := MeshInstance3D.new()
	mesh.name = "PlinthMesh"
	mesh.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.9
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = material
	body.add_child(mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collider)
	# The flight: refractory steps, each solid down into the lava.
	for k in FLIGHT:
		var top := -RISE * float(k + 1)
		var z0 := FLIGHT_START + GOING * float(k)
		var step := CalderaFurniture.piece(body, Vector3(FLIGHT_HALF, (DEEP + top) * 0.5, GOING * 0.5 + 0.02), REFRACTORY.lightened(0.03 * float(k % 2)), Vector3(0.0, (top - DEEP) * 0.5, z0 + GOING * 0.5), 0.0, true, 9.0)
		step.name = "GhatStep"
	# Where the ground behind stands above the deck, a retaining wall.
	var retaining := StaticBody3D.new()
	retaining.name = "%sRetaining" % entry["id"]
	retaining.collision_layer = 1
	retaining.collision_mask = 0
	parent.add_child(retaining)
	var cap := PackedVector3Array()
	for point in plan_outline:
		cap.append(Vector3(point.x, datum, point.y))
	SocketPlinth._retaining(retaining, cap, FireCalderaPlan.mass_centre(entry), datum)
	return body


static func _tri(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, normal: Vector3, colour: Color) -> void:
	SocketPlinth._triangle(st, a, b, c, normal, colour)
	faces.append_array([a, b, c])


## At the foot of the central flight, half sunk where the waterline step meets
## the lava, a refractory arch: the way down to the renewal chamber.
static func _threshold(body: StaticBody3D) -> void:
	var z := FLIGHT_START + GOING * 4.6
	var arch := CSGCombiner3D.new()
	arch.name = "ThresholdArch"
	arch.use_collision = true
	arch.collision_layer = 1
	arch.collision_mask = 0
	arch.position = Vector3(0.0, -RISE * 5.0, z)
	body.add_child(arch)
	var stone := SolidModel.material(REFRACTORY, 0.7, 0.0)
	var outer := SolidModel.add_profile(arch, "Outer", 0.45, Vector2(2.1, 1.9), 3.2, CSGShape3D.OPERATION_UNION, stone, Vector3(0, 1.0, 0), 72)
	outer.rotation.y = PI * 0.5
	var inner := SolidModel.add_profile(arch, "Inner", 1.2, Vector2(1.7, 1.45), 3.2, CSGShape3D.OPERATION_SUBTRACTION, stone, Vector3(0, 0.85, 0), 72)
	inner.rotation.y = PI * 0.5


## Eris's tempering slab at the landing's east end, under the windbreak: warm
## basalt to lie on, a glowing seam beneath its lip.
static func _tempering_slab(body: StaticBody3D) -> void:
	CalderaFurniture.piece(body, Vector3(1.0, 0.24, 0.5), CalderaShell.BASALT, Vector3(5.4, 0.24, -5.5), 0.0, true, 6.0)
	FireCalderaBuildings._glow(body, "TemperingSeam", Vector3(0.95, 0.012, 0.01), Vector3(5.4, 0.16, -4.99), Color(1.0, 0.5, 0.15))
	FireCalderaBuildings._marker(body, "ErisRenewalMarker", Vector3(5.4, 0.0, -4.4), PI)


## The catenary's height at x across the span.
static func arch(x: float) -> float:
	var a := _catenary_a()
	return CROWN - a * (cosh(x / a) - 1.0)


static func _catenary_a() -> float:
	# Solve a (cosh(S/2a) - 1) = CROWN - SPRING by bisection.
	var lo := 2.0
	var hi := 60.0
	for _i in 40:
		var mid := (lo + hi) * 0.5
		if mid * (cosh(SPAN * 0.5 / mid) - 1.0) > CROWN - SPRING:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## The canopy: iron ribs on the catenary across the span, and between each
## pair of ribs a sheet of slumped glass following the same curve, its colour
## shading from teal at the springing through garnet to amber at the crown.
static func _canopy(body: StaticBody3D) -> void:
	var zs: Array[float] = []
	for i in RIBS:
		zs.append(lerpf(BACK_Z, FRONT_Z, float(i) / float(RIBS - 1)))
	for z in zs:
		for s in SEGMENTS:
			var x0 := -SPAN * 0.5 + SPAN * float(s) / float(SEGMENTS)
			var x1 := -SPAN * 0.5 + SPAN * float(s + 1) / float(SEGMENTS)
			CalderaShell._beam(body, Vector3(x0, arch(x0), z), Vector3(x1, arch(x1), z), Vector2(0.12, 0.1), IRON)
	for side: float in [-1.0, 1.0]:
		CalderaShell._beam(body, Vector3(side * SPAN * 0.5, SPRING, BACK_Z), Vector3(side * SPAN * 0.5, SPRING, FRONT_Z), Vector2(0.14, 0.14), IRON)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in SEGMENTS:
		var x0 := -SPAN * 0.5 + SPAN * float(s) / float(SEGMENTS)
		var x1 := -SPAN * 0.5 + SPAN * float(s + 1) / float(SEGMENTS)
		var t := absf((x0 + x1) * 0.5) / (SPAN * 0.5)
		var colour := AMBER.lerp(GARNET, smoothstep(0.15, 0.6, t)).lerp(TEAL, smoothstep(0.55, 0.95, t))
		var normal := Vector3(-(arch(x1) - arch(x0)), x1 - x0, 0.0).normalized()
		var quad := [Vector3(x0, arch(x0) + 0.02, BACK_Z), Vector3(x1, arch(x1) + 0.02, BACK_Z), Vector3(x1, arch(x1) + 0.02, FRONT_Z), Vector3(x0, arch(x0) + 0.02, FRONT_Z)]
		for k: int in [0, 1, 2, 0, 2, 3]:
			st.set_color(colour)
			st.set_normal(normal)
			st.add_vertex(quad[k])
	var glass := MeshInstance3D.new()
	glass.name = "SlumpedGlassCanopy"
	glass.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.1
	material.emission_enabled = true
	material.emission = Color(0.25, 0.14, 0.08)
	glass.material_override = material
	body.add_child(glass)
	CollisionPolicy.mark_decorative(glass)
	# A roof a body can stand on: boxes along the curve.
	for s in SEGMENTS:
		var x0 := -SPAN * 0.5 + SPAN * float(s) / float(SEGMENTS)
		var x1 := -SPAN * 0.5 + SPAN * float(s + 1) / float(SEGMENTS)
		var a := Vector3(x0, arch(x0), 0)
		var b := Vector3(x1, arch(x1), 0)
		var holder := MeshInstance3D.new()
		body.add_child(holder)
		var angle := atan2(b.y - a.y, b.x - a.x)
		CollisionPolicy.add_box(body, holder, Vector3(a.distance_to(b), 0.06, FRONT_Z - BACK_Z), Vector3((x0 + x1) * 0.5, (a.y + b.y) * 0.5 + 0.03, (BACK_Z + FRONT_Z) * 0.5), Basis(Vector3.BACK, angle), true)


## The branching supports: at each end of every rib a forged trunk rising to
## the springing and forking into the rib and the edge beam.
static func _supports(body: StaticBody3D) -> void:
	for side: float in [-1.0, 1.0]:
		for i in RIBS:
			var z := lerpf(BACK_Z, FRONT_Z, float(i) / float(RIBS - 1))
			var x := side * SPAN * 0.5
			var foot := Vector3(x + side * 0.4, 0.42, z)
			# A refractory shoe under the iron: the forged supports never touch
			# lava, and stand off the hot deck on refractory.
			CalderaFurniture.piece(body, Vector3(0.26, 0.21, 0.26), REFRACTORY, Vector3(foot.x, 0.21, z), 0.0, true, 5.0)
			var fork := Vector3(x + side * 0.15, SPRING - 1.0, z)
			FireCalderaNahl._branch(body, foot, fork, 0.08)
			FireCalderaNahl._branch(body, fork, Vector3(x, SPRING, z), 0.06)
			FireCalderaNahl._branch(body, fork, Vector3(x - side * 0.9, arch(x - side * 0.9), z), 0.05)
			for dz: float in [-0.9, 0.9]:
				if (z + dz) > BACK_Z - 0.01 and (z + dz) < FRONT_Z + 0.01:
					FireCalderaNahl._branch(body, fork, Vector3(x, SPRING, z + dz), 0.04)
			var holder := MeshInstance3D.new()
			body.add_child(holder)
			CollisionPolicy.add_box(body, holder, Vector3(0.2, SPRING, 0.2), Vector3(x + side * 0.3, SPRING * 0.5, z), Basis(), false)


## The cast-basalt memory stones along the landing's back, facing the water: each a
## different height and lean, each with a seam of the glow it was cast with.
static func _memory_stones(body: StaticBody3D) -> void:
	var heights := [1.4, 1.9, 1.1, 2.3, 1.6, 1.2, 2.0]
	for i in heights.size():
		var x := lerpf(-7.0, -0.6, float(i) / float(heights.size() - 1))
		var z := -6.2 + 0.25 * sin(float(i) * 1.7)
		var h: float = heights[i]
		var stone := CalderaFurniture.piece(body, Vector3(0.24, h * 0.5, 0.16), CalderaShell.BASALT.lightened(0.05 * float(i % 3)), Vector3(x, h * 0.5, z), 0.1 * (float(i % 3) - 1.0), true, 3.4)
		stone.name = "MemoryStone"
		FireCalderaBuildings._glow(body, "MemorySeam", Vector3(0.012, h * 0.3, 0.012), Vector3(x, h * 0.55, z + 0.17), Color(1.0, 0.5, 0.15))


## On the landward side, behind the top tier, windbreaks of fused glass with
## basalt veils drawn through it, on iron posts.
static func _windbreaks(body: StaticBody3D) -> void:
	var z := -6.6
	var panels := 2
	for i in panels:
		var x := lerpf(4.2, 7.6, float(i) / float(panels - 1))
		var pane := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.3, 2.2, 0.05)
		pane.mesh = box
		var veiled := SolidModel.material(Color(0.80, 0.78, 0.74, 0.35), 0.3, 0.0)
		veiled.cull_mode = BaseMaterial3D.CULL_DISABLED
		pane.material_override = veiled
		pane.position = Vector3(x, 1.2, z)
		body.add_child(pane)
		CollisionPolicy.add_box(body, pane, box.size, pane.position, Basis(), false)
		for v in 3:
			var vx := x - 0.7 + 0.7 * float(v)
			CalderaShell._beam(body, Vector3(vx - 0.15, 0.25, z - 0.03), Vector3(vx + 0.2, 2.1, z - 0.03), Vector2(0.03, 0.02), CalderaShell.BASALT)
		CalderaShell._metal(body, Vector3(x + 1.18, 1.15, z), Vector3(0.08, 2.3, 0.08), IRON, true)


## Coloured light under the canopy, as the glass would throw it; flames in
## glass at the front corners for the evening.
static func _light(body: StaticBody3D) -> void:
	var tints: Array[Color] = [Color(0.4, 0.9, 0.85), Color(0.95, 0.35, 0.4), Color(1.0, 0.7, 0.3), Color(0.95, 0.35, 0.4), Color(0.4, 0.9, 0.85)]
	for i in tints.size():
		CalderaFurniture.concealed_light(body, Vector3(lerpf(-6.5, 6.5, float(i) / 4.0), 4.0, 0.0), tints[i], 0.7, 6.0)
	# The lava's own glow up the flight.
	for x: float in [-4.0, 0.0, 4.0]:
		CalderaFurniture.concealed_light(body, Vector3(x, -1.4, 4.6), Color(1.0, 0.45, 0.12), 1.2, 5.0)
	for x: float in [-8.0, 8.0]:
		CalderaFurniture.flame_capsule(body, Vector3(x, 0.0, 3.0))
