class_name FireCalderaRenewal
extends RefCounted

## The Renewal terrace (fire_caldera_buildings.md, section 3; landmark): the
## open surface of the communal renewal chamber, where the city gathers above
## the lava, Eris tempers, and the immersion shelf leads down. Its own idea:
## a catenary canopy of slumped glass. The lava people hang molten glass over
## chains and let it settle into its own curve, so the roof is drawn by heat
## and gravity: forged iron ribs follow the same catenary, carried on
## branching supports, and the panels shade through the landmark's three
## colours (teal at the springing, garnet, amber at the crown), washing the
## seats below in coloured light. Under it, basalt tiers climb the uphill
## slope like a small amphitheatre facing the reservoir; an arc of cast-basalt
## memory stones, each with a glowing seam, records people and decisions;
## glass windbreaks of veiled fused glass shelter the landward side. Open to
## the water. Local +Z faces the reservoir.

const SPAN := 16.0
const CROWN := 6.2
const SPRING := 3.0
const BACK_Z := -5.8
const FRONT_Z := 2.6
const RIBS := 4
const SEGMENTS := 16
const TEAL := Color(0.18, 0.60, 0.58, 0.55)
const GARNET := Color(0.62, 0.14, 0.22, 0.55)
const AMBER := Color(0.95, 0.58, 0.16, 0.55)
const IRON := CalderaShell.STEEL_BLUED
const TIER := Color(0.30, 0.27, 0.26)


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.make_body(parent, entry, float(line["datum"]))
	_tiers(body)
	_canopy(body)
	_supports(body)
	_memory_stones(body)
	_windbreaks(body)
	_light(body)
	return body


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


## Basalt tiers climbing toward the back, each a seat's height above the
## last, warm seams along their fronts; a level floor before them toward the
## water.
static func _tiers(body: StaticBody3D) -> void:
	for i in 3:
		var depth := 1.1
		var z := -1.6 - depth * float(i)
		var h := 0.45 * float(i + 1)
		var block := CalderaFurniture.piece(body, Vector3(SPAN * 0.5 - 0.6, h * 0.5, depth * 0.5), TIER.lightened(0.04 * float(i)), Vector3(0, h * 0.5, z - depth * 0.5 + 0.05), 0.0, true, 7.0)
		block.name = "Tier%d" % i
		FireCalderaBuildings._glow(body, "TierSeam", Vector3(SPAN * 0.5 - 0.9, 0.01, 0.01), Vector3(0, h - 0.06, z + 0.06), Color(1.0, 0.5, 0.15))


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
			var foot := Vector3(x + side * 0.4, 0.0, z)
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


## An arc of cast-basalt memory stones at the terrace's west front: each a
## different height and lean, each with a seam of the glow it was cast with.
static func _memory_stones(body: StaticBody3D) -> void:
	var centre := Vector2(-5.0, 4.6)
	var heights := [1.4, 1.9, 1.1, 2.3, 1.6, 1.2, 2.0]
	for i in heights.size():
		var angle := lerpf(PI * 0.15, PI * 0.85, float(i) / float(heights.size() - 1))
		var p := centre + Vector2(cos(angle) * 3.0, -sin(angle) * 1.4)
		var h: float = heights[i]
		var stone := CalderaFurniture.piece(body, Vector3(0.22, h * 0.5, 0.16), CalderaShell.BASALT.lightened(0.05 * float(i % 3)), Vector3(p.x, h * 0.5, p.y), angle, true, 3.4)
		stone.name = "MemoryStone"
		stone.rotation.z = (float(i % 3) - 1.0) * 0.05
		FireCalderaBuildings._glow(body, "MemorySeam", Vector3(0.012, h * 0.3, 0.012), Vector3(p.x, h * 0.55, p.y) + Vector3(cos(angle), 0, -sin(angle)) * 0.0 + Vector3(0, 0, 0.17), Color(1.0, 0.5, 0.15))


## On the landward side, behind the top tier, windbreaks of fused glass with
## basalt veils drawn through it, on iron posts.
static func _windbreaks(body: StaticBody3D) -> void:
	var z := BACK_Z - 0.4
	var panels := 6
	for i in panels:
		var x := lerpf(-SPAN * 0.5 + 1.4, SPAN * 0.5 - 1.4, float(i) / float(panels - 1))
		var pane := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(2.3, 2.2, 0.05)
		pane.mesh = box
		var veiled := SolidModel.material(Color(0.80, 0.78, 0.74, 0.35), 0.3, 0.0)
		veiled.cull_mode = BaseMaterial3D.CULL_DISABLED
		pane.material_override = veiled
		pane.position = Vector3(x, 1.35 + 1.1 + 0.1, z)
		body.add_child(pane)
		CollisionPolicy.add_box(body, pane, box.size, pane.position, Basis(), false)
		for v in 3:
			var vx := x - 0.7 + 0.7 * float(v)
			CalderaShell._beam(body, Vector3(vx - 0.15, 1.6, z - 0.03), Vector3(vx + 0.2, 3.4, z - 0.03), Vector2(0.03, 0.02), CalderaShell.BASALT)
		CalderaShell._metal(body, Vector3(x + 1.18, 1.85, z), Vector3(0.08, 3.7, 0.08), IRON, true)


## Coloured light under the canopy, as the glass would throw it; flames in
## glass at the front corners for the evening.
static func _light(body: StaticBody3D) -> void:
	var tints: Array[Color] = [Color(0.4, 0.9, 0.85), Color(0.95, 0.35, 0.4), Color(1.0, 0.7, 0.3), Color(0.95, 0.35, 0.4), Color(0.4, 0.9, 0.85)]
	for i in tints.size():
		CalderaFurniture.concealed_light(body, Vector3(lerpf(-6.5, 6.5, float(i) / 4.0), 4.0, -2.0), tints[i], 0.7, 6.0)
	for x: float in [-7.4, 7.4]:
		CalderaFurniture.flame_capsule(body, Vector3(x, 0.0, 5.6))
	FireCalderaBuildings._marker(body, "ErisRenewalMarker", Vector3(0.0, 0.0, 1.0), 0.0)
