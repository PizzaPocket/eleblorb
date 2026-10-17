class_name FireCalderaHeartworks
extends RefCounted

## Builds the generated Heartworks levels, sampled walks and section. All plan
## coordinates remain local to FireCalderaPlan's shared frame.

const LAVA := Color(1.0, 0.19, 0.025)
const GLASS := Color(0.42, 0.72, 0.82, 0.26)
const STEEL := Color(0.10, 0.15, 0.17)
const BASALT := Color(0.14, 0.14, 0.15)


static func build(parent: Node3D) -> StaticBody3D:
	var body := FireCalderaPlanWalks.build(parent,
		FireCalderaHeartworksPlan.LEVELS,
		FireCalderaHeartworksPlan.FLIGHTS,
		"CalderaHeartworks")
	_build_rim_wall(body)
	_build_colonnades(body)
	_build_dome(body)
	_build_cascade(body)
	return body


static func _build_rim_wall(body: StaticBody3D) -> void:
	var section: Dictionary = FireCalderaHeartworksPlan.SECTION
	var chamber: Dictionary = section["chamber"]
	var radius := float(chamber["radius"])
	var top := float(section["lava_y"]) - float(chamber["springing"])
	var bottom := float(section["lava_y"]) - float(chamber["floor"])
	const SEGMENTS := 128
	for i in SEGMENTS:
		var a0 := TAU * float(i) / SEGMENTS
		var a1 := TAU * float(i + 1) / SEGMENTS
		var mid := (a0 + a1) * 0.5
		var width := radius * (a1 - a0) * 1.02
		var segment := BoxMesh.new()
		segment.size = Vector3(width, top - bottom, 2.8)
		var wall := MeshInstance3D.new()
		wall.name = "BasaltRimWall"
		wall.mesh = segment
		wall.position = Vector3(cos(mid) * radius, (top + bottom) * 0.5, sin(mid) * radius)
		wall.rotation.y = -mid
		wall.material_override = SolidModel.material(BASALT, 0.82, 0.03)
		body.add_child(wall)
		CollisionPolicy.add_box(body, wall, segment.size, wall.position, wall.basis, false)


static func _build_colonnades(body: StaticBody3D) -> void:
	var levels_by_id := {}
	for level: Dictionary in FireCalderaHeartworksPlan.SECTION["levels"]:
		levels_by_id[str(level["id"])] = level
	var section: Dictionary = FireCalderaHeartworksPlan.SECTION
	var tiers := [["R3", "R2"], ["R2", "R1"], ["R1", "F"]]
	for pair: Array in tiers:
		var upper: Dictionary = levels_by_id[pair[0]]
		var lower: Dictionary = levels_by_id[pair[1]]
		var radius := float(upper["edge"])
		var y_top := float(upper["datum"])
		var y_bottom := float(lower["datum"])
		# Leave the sampled ramp mouths and bridge chords unobstructed.
		for i in 64:
			var angle := TAU * float(i) / 64.0
			var point := Vector2(cos(angle) * radius, sin(angle) * radius)
			if _inside_any_flight_mouth(point, pair):
				continue
			var column := CylinderMesh.new()
			column.top_radius = 0.28
			column.bottom_radius = 0.42
			column.height = y_top - y_bottom
			column.radial_segments = 8
			var support := MeshInstance3D.new()
			support.name = "SteppedTerraceColonnade"
			support.mesh = column
			support.position = Vector3(point.x, (y_top + y_bottom) * 0.5, point.y)
			support.material_override = SolidModel.material(STEEL, 0.6, 0.28)
			body.add_child(support)
			CollisionPolicy.add_cylinder(body, support, 0.42, y_top - y_bottom, support.position, false)


static func _inside_any_flight_mouth(point: Vector2, pair: Array) -> bool:
	var upper_id := str(pair[0])
	var lower_id := str(pair[1])
	for flight: Dictionary in FireCalderaHeartworksPlan.FLIGHTS:
		if str(flight["upper"]) != upper_id or str(flight["lower"]) != lower_id:
			continue
		var profile: Array = flight["profile"]
		for i in [0, profile.size() - 1]:
			var p: Array = profile[i]
			if point.distance_to(Vector2(float(p[0]), float(p[2]))) < float(flight["width"]) * 0.5 + 0.7:
				return true
	return false


static func _build_dome(body: StaticBody3D) -> void:
	var section: Dictionary = FireCalderaHeartworksPlan.SECTION
	var dome: Dictionary = section["dome"]
	var lava_y := float(section["lava_y"])
	var centre_y := lava_y - float(dome["centre_depth"])
	var sphere_radius := float(dome["radius"])
	var top_depth := float(section["chamber"]["oculus_depth"])
	var bottom_depth := float(section["chamber"]["springing"])
	const Y_STEPS := 48
	const A_STEPS := 128
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for yi in Y_STEPS:
		var d0 := lerpf(top_depth, bottom_depth, float(yi) / Y_STEPS)
		var d1 := lerpf(top_depth, bottom_depth, float(yi + 1) / Y_STEPS)
		var y0 := lava_y - d0
		var y1 := lava_y - d1
		var r0 := sqrt(maxf(sphere_radius * sphere_radius - pow(y0 - centre_y, 2.0), 0.01))
		var r1 := sqrt(maxf(sphere_radius * sphere_radius - pow(y1 - centre_y, 2.0), 0.01))
		for ai in A_STEPS:
			var a0 := TAU * float(ai) / A_STEPS
			var a1 := TAU * float(ai + 1) / A_STEPS
			var p00 := Vector3(cos(a0) * r0, y0, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0, y0, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1, y1, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, y1, sin(a1) * r1)
			_add_dome_face(st, faces, p00, p10, p11)
			_add_dome_face(st, faces, p00, p11, p01)
	var visual := MeshInstance3D.new()
	visual.name = "ReservoirGlassDome"
	visual.mesh = st.commit()
	var glass := SolidModel.material(GLASS, 0.12, 0.02)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	visual.material_override = glass
	visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(visual)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = "ReservoirGlassDomeCollision"
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)
	# Blackened-steel diagrid carries the refractory glass. The central oculus
	# is left clear so the cascade is the only passage into the chamber.
	for ring in range(1, 9):
		var depth := lerpf(top_depth + 0.2, bottom_depth, float(ring) / 8.0)
		var y := lava_y - depth
		var radius := sqrt(maxf(sphere_radius * sphere_radius - pow(y - centre_y, 2.0), 0.01))
		var points := PackedVector3Array()
		for i in A_STEPS + 1:
			var angle := TAU * float(i) / A_STEPS
			points.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
		var rib := FireCalderaHighline._tube(body, points, 0.07, STEEL, "DomeDiagridRing")
		CollisionPolicy.mark_decorative(rib)


static func _build_cascade(body: StaticBody3D) -> void:
	var section: Dictionary = FireCalderaHeartworksPlan.SECTION
	var cascade: Dictionary = section["cascade"]
	var lava_y := float(section["lava_y"])
	var y_top := lava_y - float(cascade["top_depth"])
	var y_bottom := lava_y - float(cascade["bottom_depth"])
	var flow := CylinderMesh.new()
	flow.top_radius = float(cascade["top_radius"])
	flow.bottom_radius = float(cascade["bottom_radius"])
	flow.height = y_top - y_bottom
	flow.radial_segments = 64
	flow.rings = 24
	var visual := MeshInstance3D.new()
	visual.name = "ContinuousLavaCascade"
	visual.mesh = flow
	visual.position.y = (y_top + y_bottom) * 0.5
	visual.material_override = SolidModel.material(LAVA, 0.18, 0.0)
	visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.HAZARD)
	body.add_child(visual)
	var pool := CylinderMesh.new()
	pool.top_radius = float(section["chamber"]["pool_radius"])
	pool.bottom_radius = float(section["chamber"]["pool_radius"])
	pool.height = 0.9
	pool.radial_segments = 96
	var pool_visual := MeshInstance3D.new()
	pool_visual.name = "CollectionPoolLava"
	pool_visual.mesh = pool
	pool_visual.position.y = y_bottom - 0.45
	pool_visual.material_override = SolidModel.material(LAVA, 0.2, 0.0)
	pool_visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.HAZARD)
	body.add_child(pool_visual)


static func _add_dome_face(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)
	faces.append_array([a, b, c])
