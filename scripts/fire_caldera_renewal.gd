class_name FireCalderaRenewal
extends RefCounted

## The Renewal terrace (fire_caldera_buildings.md, section 3; landmark) is a
## public extension of the Highline rather than a rock ghat. Two communal glass
## byways arrive at opposite landward sides of a broad transparent deck. From
## its reservoir face, one gently sloped SuperEgg tongue enters the lava and
## reaches the half-sunk refractory threshold to the renewal chamber. The
## multiple approaches let gatherings circulate without turning the ritual
## descent into a dead end.
##
## Cast-basalt memory stones face the water along the landward edge; beneath a
## veiled glass windbreak, Eris's warm tempering slab assists residents who are
## too cracked or cooled to enter directly. The same glass-and-dark-metal
## language continues from byway to deck, guard and immersion tongue.
##
## Its own idea above: a catenary canopy of slumped glass. The lava people
## hang molten glass over chains and let it settle into its own curve, so the
## roof is drawn by heat and gravity: forged iron ribs on the same catenary on
## branching supports, the panels shading from teal at the springing through
## garnet to amber at the crown, washing the steps in coloured light.
##
## Its foundation is its own civic structure: a squarish glass SuperEgg deck
## carried by a concave supertoroidal service pier. Local +Z faces the
## reservoir.

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
	_tempering_slab(body)
	_light(body)
	return body


## The public renewal deck uses the Highline's glass-and-dark-metal language.
## It is a light civic platform over one supertoroidal service pier, with two
## landward access points and one broad SuperEgg immersion tongue.  There is no
## rock tray, retaining lip, or monumental stair between people and the lava.
static func build_foundation(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var datum := float(line["datum"])
	var body := CalderaShell.make_body(parent, entry, datum)
	body.name = "%sPlinth" % entry["id"]
	var glass := Color(0.32, 0.66, 0.76, 0.38)
	CalderaShell.soft_slab(body, "RenewalGlassDeck", Vector3(0.0, -0.14, 0.0), Vector3(11.3, 0.14, 9.3), Vector2(10.8, 8.8), glass)
	var edge := PackedVector3Array()
	for i in 48:
		var angle := TAU * float(i) / 48.0
		var c := cos(angle)
		var s := sin(angle)
		edge.append(Vector3(signf(c) * pow(absf(c), 2.0 / 7.0) * 11.18, -0.03, signf(s) * pow(absf(s), 2.0 / 7.0) * 9.18))
	for i in edge.size():
		CalderaShell._beam(body, edge[i], edge[(i + 1) % edge.size()], Vector2(0.13, 0.13), IRON)
	FireCalderaHighline._supertoroidal_pier(body, Vector2.ZERO, Vector2.RIGHT, Vector2.DOWN, Vector2(10.95, 8.95), float(line["low"]) - datum - 2.2, -0.30, "RenewalSupertoroidalServicePier")
	_immersion_tongue(body, datum)
	return body


static func _immersion_tongue(body: StaticBody3D, datum: float) -> void:
	# Begin at the lava-facing deck edge. The former tongue began near the
	# pavilion centre and pitched down through the glass foundation itself.
	var start := Vector3(0.0, 0.02, 8.15)
	var finish := Vector3(0.0, FireCalderaGround.LAVA_Y - datum - 1.2, 15.0)
	var delta := finish - start
	var run := Vector2(delta.x, delta.z).length()
	var pitch := -atan2(delta.y, run)
	var basis := Basis(Vector3.RIGHT, pitch)
	var middle := start.lerp(finish, 0.5)
	CalderaShell.soft_slab(body, "ImmersionTongue", middle - basis.y * 0.11, Vector3(3.2, 0.11, delta.length() * 0.5), Vector2(3.0, delta.length() * 0.5 - 0.18), Color(0.30, 0.62, 0.72, 0.44), basis)
	for side: float in [-1.0, 1.0]:
		var offset := basis.x * side * 3.05
		CalderaShell._beam(body, start + offset + basis.y * 1.12, finish + offset + basis.y * 1.12, Vector2(0.09, 0.09), IRON)
		var pane := BoxMesh.new()
		pane.size = Vector3(0.04, 1.0, delta.length())
		var visual := MeshInstance3D.new()
		visual.name = "ImmersionGuard"
		visual.mesh = pane
		visual.material_override = SolidModel.material(Color(0.42, 0.72, 0.80, 0.22), 0.12, 0.02)
		visual.transform = Transform3D(basis, middle + offset + basis.y * 0.56)
		body.add_child(visual)
		CollisionPolicy.add_box(body, visual, pane.size, visual.position, visual.basis, false)


## At the foot of the immersion tongue, half sunk at the lava, a refractory
## arch marks the way down to the renewal chamber.
static func _threshold(body: StaticBody3D) -> void:
	var z := 14.2
	var arch := CSGCombiner3D.new()
	arch.name = "ThresholdArch"
	arch.use_collision = true
	arch.collision_layer = 1
	arch.collision_mask = 0
	arch.position = Vector3(0.0, FireCalderaGround.LAVA_Y - body.position.y - 1.05, z)
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
