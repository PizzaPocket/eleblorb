class_name FireCalderaHighline
extends RefCounted

## A level civic passage carried above the untouched caldera bowl.  The deck,
## its supports and the building docks are architecture; none of their heights
## are folded into FireCalderaGround's single-valued terrain function.

const SEGMENTS := 360
const DECK_THICKNESS := 0.22
const STEEL := Color(0.10, 0.16, 0.22)
const GLASS := Color(0.32, 0.66, 0.76, 0.34)
const GUARD_GLASS := Color(0.43, 0.73, 0.82, 0.24)
## Shared civic metal is a cool nickel/oxidized-glass alloy. Amber and cobalt
## remain the inn's own identity, not a settlement-wide default.
const JOINT := Color(0.34, 0.50, 0.52)
const PLATFORM_COMPOSITE := Color(0.13, 0.17, 0.19)
const REFRACTORY_EDGE := Color(0.21, 0.18, 0.17)
const GUARD_TOP := 1.09
const GUARD_HEIGHT := 1.04
const RENEWAL_DECK_HALF := Vector2(10.8, 8.8)
const RENEWAL_DECK_EXPONENT := 7.0
const RENEWAL_EDGE_HALF := Vector2(11.18, 9.18)


static func build(parent: Node3D) -> StaticBody3D:
	var planned := FireCalderaPlanWalks.build(parent, FireCalderaWalkwaysPlan.LEVELS, FireCalderaWalkwaysPlan.FLIGHTS, "CalderaWalkways")
	_build_plan_site(planned, FireCalderaWalkwaysPlan.SITE)
	return planned


static func build_platform(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	# The authored tier contains every porch. Keep only the private building
	# floor inside its wall footprint; the public extension is already part of
	# the single generated tier surface.
	var floor_entry := entry.duplicate(true)
	var footprint: Vector2 = entry["footprint"]
	floor_entry["walk_footprint"] = Vector2(footprint.x - SocketPlinth.REVEAL * 2.0,
		footprint.y - SocketPlinth.REVEAL * 2.0)
	var platform_line := line.duplicate(true)
	platform_line["bottom"] = float(line["datum"]) - maxf(0.42, SocketPlinth.sink(entry) + 0.12)
	var body := SocketPlinth.build(parent, floor_entry, platform_line, "walk_footprint")
	var centre: Vector2 = entry["centre"]
	var half := (footprint * 0.5)
	var deep := FireCalderaPlan.facing(entry)
	var across := Vector2(-deep.y, deep.x)
	var pier_half := half
	var ground := FireCalderaGround.height(centre)
	_supertoroidal_pier(body, centre, across, deep, pier_half, ground - 2.4, float(line["datum"]) - 0.42, "%sSupertoroidalServicePier" % entry["id"])
	return body


static func build_ground_plot(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	# The public tier owns forecourts and yard landings; SocketPlinth owns the
	# private floor within the building wall footprint only.
	var floor_entry := entry.duplicate(true)
	var footprint: Vector2 = entry["footprint"]
	floor_entry["walk_footprint"] = Vector2(footprint.x - SocketPlinth.REVEAL * 2.0,
		footprint.y - SocketPlinth.REVEAL * 2.0)
	return SocketPlinth.build(parent, floor_entry, line, "walk_footprint")


static func build_ground_beds(parent: Node3D, site: Dictionary) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CalderaBedRetainingEdges"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for bed_id: String in site["beds"]:
		var bed: Dictionary = site["beds"][bed_id]
		if str(bed.get("kind", "")) != "ground":
			continue
		var cut_to := float(bed["cut_to"])
		for run: Array in bed.get("retaining", []):
			for i in range(1, run.size()):
				var p0: Array = run[i - 1]
				var p1: Array = run[i]
				var a := Vector3(float(p0[0]), float(p0[1]), float(p0[2]))
				var b := Vector3(float(p1[0]), float(p1[1]), float(p1[2]))
				var ab := Vector3(a.x, cut_to, a.z)
				var bb := Vector3(b.x, cut_to, b.z)
				var normal := (b - a).cross(ab - a).normalized()
				for tri: Array in [[a, ab, bb], [a, bb, b]]:
					st.set_normal(normal)
					for point: Vector3 in tri:
						st.add_vertex(point)
						faces.append(point)
				for tri: Array in [[a, bb, ab], [a, b, bb]]:
					st.set_normal(-normal)
					for point: Vector3 in tri:
						st.add_vertex(point)
						faces.append(point)
	var visual := MeshInstance3D.new()
	visual.name = "BasaltRetainingFaces"
	visual.mesh = st.commit()
	visual.material_override = SolidModel.material(REFRACTORY_EDGE, 0.9, 0.0)
	body.add_child(visual)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	body.add_child(collision)
	return body


static func _build_plan_site(body: StaticBody3D, site: Dictionary) -> void:
	var gate: Dictionary = site["tempering_gate"]
	var plinth: Dictionary = site["gate_plinth"]
	for bearing: float in site["frames"]:
		var angle := deg_to_rad(bearing)
		var radial := Vector2(cos(angle), sin(angle))
		var foot_plan := radial * FireCalderaPlan.HIGHLINE_RADIUS
		var terrain_y := FireCalderaGround.height(foot_plan)
		var deck_y := FireCalderaPlan.HIGHLINE_DATUM - DECK_THICKNESS
		_vertical_member(body, Vector3(foot_plan.x, terrain_y, foot_plan.y), Vector3(foot_plan.x, deck_y, foot_plan.y), 0.28, "HighlineFrameColumn")
		var tangent := Vector2(-radial.y, radial.x)
		for side: float in [-1.0, 1.0]:
			var head := Vector3(foot_plan.x, deck_y - 0.55, foot_plan.y)
			var tip := foot_plan + tangent * side * 1.35
			_beam(body, head, Vector3(tip.x, deck_y, tip.y), Vector2(0.18, 0.18), JOINT)
	var top := float(plinth["top"])
	var bottom := float(plinth["bottom"])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for region: Dictionary in FireCalderaWalkwaysPlan.LEVELS[0]["surface"]:
		for raw_loop: Array in [region["outer"]] + region.get("holes", []):
			var loop := PackedVector2Array()
			for raw: Array in raw_loop:
				loop.append(Vector2(float(raw[0]), float(raw[1])))
			if loop.size() > 2 and loop[0].is_equal_approx(loop[-1]):
				loop.remove_at(loop.size() - 1)
			for i in loop.size():
				var p0 := loop[i]
				var p1 := loop[(i + 1) % loop.size()]
				var a := Vector3(p0.x, top, p0.y)
				var b := Vector3(p1.x, top, p1.y)
				var ab := Vector3(p0.x, bottom, p0.y)
				var bb := Vector3(p1.x, bottom, p1.y)
				var normal := (b - a).cross(ab - a).normalized()
				for point: Vector3 in [a, ab, bb, a, bb, b]:
					st.set_normal(normal)
					st.add_vertex(point)
				faces.append_array([a, ab, bb, a, bb, b])
	var pier := MeshInstance3D.new()
	pier.name = "GateTerraceSocketedPlinth"
	pier.mesh = st.commit()
	pier.material_override = SolidModel.material(PLATFORM_COMPOSITE, 0.82, 0.04)
	pier.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	body.add_child(pier)
	var plinth_shape := ConcavePolygonShape3D.new()
	plinth_shape.backface_collision = true
	plinth_shape.set_faces(faces)
	var plinth_collision := CollisionShape3D.new()
	plinth_collision.shape = plinth_shape
	plinth_collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	body.add_child(plinth_collision)
	_build_tempering_gate(body, gate, top)
	var tongue: Dictionary = site["immersion_tongue"]
	var start: Array = tongue["start"]
	var renewal: Dictionary = FireCalderaPlan.plot("RENEWAL")
	var tongue_origin: Vector2 = FireCalderaPlan.shell_to_plan(renewal, Vector2(float(start[0]), float(start[1])))
	var tongue_end: Vector2 = FireCalderaPlan.shell_to_plan(renewal, Vector2(float(start[0]), float(start[1]) + float(tongue["length"])))
	var datum := 0.0
	for level: Dictionary in FireCalderaWalkwaysPlan.LEVELS:
		if str(level["id"]) == "promenade":
			datum = float(level["datum"])
			break
	var tongue_flight := {
		"id": "RenewalImmersionTongue",
		"width": float(tongue["width"]),
		"profile": [
			[tongue_origin.x, datum, tongue_origin.y],
			[tongue_end.x, datum - float(tongue["drop"]), tongue_end.y],
		],
		"guards": [],
		"material": "glass",
	}
	FireCalderaPlanWalks._build_flight(body, tongue_flight)
	_build_funicular(body, site["funicular"])


static func _build_tempering_gate(body: StaticBody3D, gate: Dictionary, floor_y: float) -> void:
	var at: Array = gate["at"]
	var span := float(gate["span"])
	var arch: Dictionary = gate["arch"]
	for depth: float in arch["layers"]:
		var points := PackedVector3Array()
		const SEGMENTS := 96
		for i in SEGMENTS + 1:
			var x := -span * 0.5 + span * float(i) / float(SEGMENTS)
			var ratio := clampf(absf(x) / (span * 0.5), 0.0, 1.0)
			var profile := pow(maxf(1.0 - pow(ratio, float(arch["exponent"])), 0.0), 1.0 / float(arch["exponent"]))
			var y := floor_y + 0.7 + (float(gate["height"]) - 0.7) * profile
			points.append(Vector3(float(at[0]) + x, y, float(at[1]) + depth))
		var tube := _tube(body, points, float(arch["tube"]), REFRACTORY_EDGE, "TemperingGateArchTube")
		var faces := PackedVector3Array()
		faces.append_array(tube.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(faces)
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
		body.add_child(collision)
	var feet: Dictionary = gate["feet"]
	for side: float in [-1.0, 1.0]:
		var foot_mesh := SolidModel.super_mesh(Vector3(float(feet["semi"][0]), float(feet["semi"][1]), float(feet["semi"][2])), float(feet["eps"]), 20, 20)
		var foot := MeshInstance3D.new()
		foot.name = "TemperingGateBasaltFoot"
		foot.mesh = foot_mesh
		foot.position = Vector3(float(at[0]) + side * span * 0.5, floor_y + 0.35, float(at[1]))
		foot.material_override = SolidModel.material(REFRACTORY_EDGE, 0.9, 0.0)
		body.add_child(foot)
		var foot_shape := ConvexPolygonShape3D.new()
		foot_shape.points = foot_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var foot_collision := CollisionShape3D.new()
		foot_collision.shape = foot_shape
		foot_collision.position = foot.position
		foot_collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
		body.add_child(foot_collision)
	var veil: Dictionary = gate["veil"]
	var colours := {"teal": Color(0.02, 0.75, 0.72), "magenta": Color(0.9, 0.12, 0.7), "lime": Color(0.56, 0.95, 0.08), "cobalt": Color(0.1, 0.3, 0.95)}
	for fin: Dictionary in veil["fins"]:
		var fin_height := float(fin["len"])
		var fin_mesh := SolidModel.super_mesh(Vector3(float(veil["semi_width"]), fin_height * 0.5, float(veil["semi_depth"])), float(veil["eps"]), 16, 16)
		var fin_node := MeshInstance3D.new()
		fin_node.name = "TemperingGateStainedFin"
		fin_node.mesh = fin_mesh
		fin_node.position = Vector3(float(at[0]) + float(fin["x"]), floor_y + float(gate["height"]) - fin_height * 0.5, float(at[1]))
		var tint: Color = colours[str(fin["colour"])]
		var glass := SolidModel.material(tint, 0.05, 0.0)
		glass.emission_enabled = true
		glass.emission = tint
		glass.emission_energy_multiplier = 0.7
		fin_node.material_override = glass
		body.add_child(fin_node)
		CollisionPolicy.mark_decorative(fin_node)


static func _build_funicular(body: StaticBody3D, plan: Dictionary) -> void:
	var profile: Array = plan["profile"]
	if profile.size() < 2:
		return
	var centreline := PackedVector3Array()
	for raw: Array in profile:
		centreline.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
	var first := centreline[0]
	var last := centreline[-1]
	var direction := Vector2(last.x - first.x, last.z - first.z).normalized()
	var across := Vector2(-direction.y, direction.x)
	# The generated profile is the rail datum. The basalt bed sits exactly
	# 0.15 m below it and follows each authored point.
	var bed_width := float(plan["bed"]["width"])
	var bed_depth := float(plan["bed"]["depth"])
	var bed_faces := PackedVector3Array()
	var bed_st := SurfaceTool.new()
	bed_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in centreline.size() - 1:
		var p0 := centreline[i] - Vector3.UP * 0.15
		var p1 := centreline[i + 1] - Vector3.UP * 0.15
		var tangent := Vector2(p1.x - p0.x, p1.z - p0.z).normalized()
		var lateral := Vector3(-tangent.y, 0.0, tangent.x) * bed_width * 0.5
		var a := p0 + lateral
		var b := p0 - lateral
		var c := p1 - lateral
		var d := p1 + lateral
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, a, b, c, Vector3.UP)
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, a, c, d, Vector3.UP)
		var down := Vector3.DOWN * bed_depth
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, a + down, c + down, b + down, Vector3.DOWN)
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, a + down, d + down, c + down, Vector3.DOWN)
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, a, d, d + down, lateral.normalized())
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, a, d + down, a + down, lateral.normalized())
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, b, b + down, c + down, -lateral.normalized())
		FireCalderaPlanWalks._add_face(bed_st, bed_faces, b, c + down, c, -lateral.normalized())
	var bed_node := MeshInstance3D.new()
	bed_node.name = "FunicularBasaltTrackBed"
	bed_node.mesh = bed_st.commit()
	bed_node.material_override = SolidModel.material(REFRACTORY_EDGE, 0.9, 0.0)
	body.add_child(bed_node)
	var bed_shape := ConcavePolygonShape3D.new()
	bed_shape.backface_collision = true
	bed_shape.set_faces(bed_faces)
	var bed_collider := CollisionShape3D.new()
	bed_collider.shape = bed_shape
	bed_collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(bed_collider)
	# Each of the two tracks carries its own one-metre gauge pair.
	var rail_offsets: Array[float] = []
	for track: float in [-float(plan["tracks"]) * 0.5, float(plan["tracks"]) * 0.5]:
		for gauge: float in [-float(plan["gauge"]) * 0.5, float(plan["gauge"]) * 0.5]:
			rail_offsets.append(track + gauge)
	for offset: float in rail_offsets:
		var rail_points := PackedVector3Array()
		for point in centreline:
			rail_points.append(point + Vector3(across.x * offset, 0.0, across.y * offset))
		var rail := _tube(body, rail_points, 0.09, STEEL, "FunicularTrackRail")
		CollisionPolicy.mark_decorative(rail)
	for pier: Dictionary in plan["piers"]:
		var at: Array = pier["at"]
		var pier_mesh := SolidModel.super_mesh(Vector3(0.9, maxf(0.6, (float(pier["top"]) - float(pier["foot"])) * 0.5), 0.9), 3.0, 24, 24)
		var support := MeshInstance3D.new()
		support.name = "FunicularSuperEggPier"
		support.mesh = pier_mesh
		support.position = Vector3(float(at[0]), (float(pier["top"]) + float(pier["foot"])) * 0.5, float(at[1]))
		support.material_override = SolidModel.material(REFRACTORY_EDGE, 0.8, 0.05)
		body.add_child(support)
		var points: PackedVector3Array = pier_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var support_shape := ConvexPolygonShape3D.new()
		support_shape.points = points
		var support_collider := CollisionShape3D.new()
		support_collider.shape = support_shape
		support_collider.position = support.position
		support_collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
		body.add_child(support_collider)
	# The generated levels are the station platforms. Only the two authored
	# platform gate lines are added here, leaving the car door width clear.
	for gate_index in plan["gates"].size():
		var datum := float(FireCalderaWalkwaysPlan.LEVELS[0]["datum"]) if gate_index == 0 else float(FireCalderaWalkwaysPlan.LEVELS[1]["datum"])
		var points := PackedVector3Array()
		for raw: Array in plan["gates"][gate_index]:
			points.append(Vector3(float(raw[0]), datum + 1.09, float(raw[1])))
		FireCalderaPlanWalks._build_guard(body, points, "FunicularPlatformGate%d" % gate_index)
	var stair: Dictionary = plan["stair"]
	_build_funicular_stair(body, stair)
	var lift := Node3D.new()
	lift.name = "CounterbalancedFunicular"
	lift.set_script(load("res://scripts/fire_caldera_funicular.gd"))
	lift.set("plan", plan)
	body.add_child(lift)


static func _build_funicular_stair(body: StaticBody3D, stair: Dictionary) -> void:
	var profile: Array = stair["profile"]
	var flight := {"id": "FunicularStair", "width": float(stair["width"]), "profile": profile, "deck": profile, "guards": [], "material": "basalt"}
	FireCalderaPlanWalks._build_flight(body, flight)
	var tread := float(stair["tread"])
	var width := float(stair["width"])
	var tread_st := SurfaceTool.new()
	tread_st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tread_faces := PackedVector3Array()
	var step_mesh := BoxMesh.new()
	step_mesh.size = Vector3(width, 0.08, tread)
	for i in range(1, profile.size()):
		var a: Array = profile[i - 1]
		var b: Array = profile[i]
		var horizontal := Vector2(float(b[0]) - float(a[0]), float(b[2]) - float(a[2]))
		var grade := absf(float(b[1]) - float(a[1])) / maxf(horizontal.length(), 0.001)
		if grade <= 0.18:
			continue
		var count := maxi(1, int(ceil(horizontal.length() / tread)))
		for step in count:
			var t := (float(step) + 0.5) / float(count)
			var p := Vector3(lerpf(float(a[0]), float(b[0]), t), lerpf(float(a[1]), float(b[1]), t), lerpf(float(a[2]), float(b[2]), t))
			var yaw := atan2(horizontal.x, horizontal.y)
			var st := Transform3D(Basis(Vector3.UP, yaw), p - Vector3.UP * 0.04)
			for tri: Array in _box_triangles(step_mesh.size, st):
				FireCalderaPlanWalks._add_face(tread_st, tread_faces, tri[0], tri[1], tri[2])
			var collision := CollisionShape3D.new()
			collision.shape = BoxShape3D.new()
			(collision.shape as BoxShape3D).size = step_mesh.size
			collision.transform = st
			collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
			body.add_child(collision)
	var treads := MeshInstance3D.new()
	treads.name = "FunicularStairTreads"
	treads.mesh = tread_st.commit()
	treads.material_override = SolidModel.material(REFRACTORY_EDGE, 0.9, 0.0)
	treads.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(treads)
	for raw_guard: Array in stair["guards"]:
		var points := PackedVector3Array()
		for raw: Array in raw_guard:
			points.append(Vector3(float(raw[0]), float(raw[1]), float(raw[2])))
		FireCalderaPlanWalks._build_guard(body, points, "FunicularStairGuard")


static func _box_triangles(size: Vector3, transform: Transform3D) -> Array:
	var h := size * 0.5
	var p: Array[Vector3] = [Vector3(-h.x,-h.y,-h.z),Vector3(h.x,-h.y,-h.z),Vector3(h.x,-h.y,h.z),Vector3(-h.x,-h.y,h.z),Vector3(-h.x,h.y,-h.z),Vector3(h.x,h.y,-h.z),Vector3(h.x,h.y,h.z),Vector3(-h.x,h.y,h.z)]
	var tris: Array = []
	for face: Array in [[0,2,1],[0,3,2],[4,5,6],[4,6,7],[0,1,5],[0,5,4],[1,2,6],[1,6,5],[2,3,7],[2,7,6],[3,0,4],[3,4,7]]:
		tris.append([transform * p[face[0]], transform * p[face[1]], transform * p[face[2]]])
	return tris


# Retired independent route, junction and guard builders.
# Public walks now come only from FireCalderaWalkwaysPlan.

## Local interior paths in finished buildings still use this compact cassette
## helper. Public walks, flights and their guards are built only from the plan.
static func _build_glass_path(body: StaticBody3D, points: PackedVector3Array, width: float, label: String, guard_style: String = "glass", _branch: Dictionary = {}) -> void:
	if points.size() < 2:
		return
	var left := PackedVector3Array()
	var right := PackedVector3Array()
	for i in points.size():
		var before := points[maxi(i - 1, 0)]
		var after := points[mini(i + 1, points.size() - 1)]
		var tangent := Vector2(after.x - before.x, after.z - before.z).normalized()
		var normal := Vector2(-tangent.y, tangent.x) * width * 0.5
		left.append(points[i] + Vector3(normal.x, 0.0, normal.y))
		right.append(points[i] - Vector3(normal.x, 0.0, normal.y))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	for i in points.size() - 1:
		var a := left[i]
		var b := right[i]
		var c := right[i + 1]
		var d := left[i + 1]
		_quad(st, faces, a, b, c, d, Vector3.UP)
		_quad(st, faces, d - Vector3.UP * DECK_THICKNESS, c - Vector3.UP * DECK_THICKNESS,
			b - Vector3.UP * DECK_THICKNESS, a - Vector3.UP * DECK_THICKNESS, Vector3.DOWN)
		_quad(st, faces, a, a - Vector3.UP * DECK_THICKNESS, d - Vector3.UP * DECK_THICKNESS, d, Vector3(-1, 0, 0))
		_quad(st, faces, b, c, c - Vector3.UP * DECK_THICKNESS, b - Vector3.UP * DECK_THICKNESS, Vector3(1, 0, 0))
	var mesh := MeshInstance3D.new()
	mesh.name = "%sCassette" % label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(STEEL if guard_style == "metal" else GLASS, 0.24, 0.12)
	mesh.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(mesh)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collision := CollisionShape3D.new()
	collision.name = "%sCassetteCollision" % label
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)
	for side: float in [-1.0, 1.0]:
		var edge := PackedVector3Array()
		for i in points.size():
			edge.append((left[i] if side > 0.0 else right[i]) + Vector3.UP * GUARD_TOP)
		_tube(body, edge, 0.05, STEEL, "%sHandrail" % label)
		if guard_style == "glass":
			for i in edge.size() - 1:
				_path_guard(body, left[i] if side > 0.0 else right[i],
					left[i + 1] if side > 0.0 else right[i + 1], Vector3.UP)


static func _path_guard(body: StaticBody3D, a: Vector3, b: Vector3, normal: Vector3) -> void:
	var delta := b - a
	if delta.length_squared() < 0.001:
		return
	var x_axis := delta.normalized()
	var z_axis := x_axis.cross(normal).normalized()
	var basis := Basis(x_axis, normal, z_axis)
	var size := Vector3(delta.length(), 0.94, 0.035)
	var centre := (a + b) * 0.5 + normal * 0.53
	var visual := MeshInstance3D.new()
	visual.name = "BywayGuardGlass"
	var pane := BoxMesh.new()
	pane.size = size
	visual.mesh = pane
	visual.material_override = SolidModel.material(GUARD_GLASS, 0.12, 0.02)
	visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(visual)
	CollisionPolicy.add_box(body, visual, size, centre, basis, false)


static func _rail_cap(body: StaticBody3D, point: Vector3, radius: float, label: String) -> void:
	var cap := MeshInstance3D.new()
	cap.name = "%sRailTerminal" % label
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	cap.mesh = sphere
	cap.material_override = SolidModel.material(STEEL, 0.55, 0.72)
	cap.position = point
	body.add_child(cap)
	CollisionPolicy.mark_decorative(cap)

## A generalized supertoroidal pier: each horizontal course is a squarish
## SuperEllipse; the courses contract into a deep concave waist, then broaden
## into the buried foot.  The top course is derived from the exact foundation
## outline, so there is no floating edge or mismatched capital.
static func _supertoroidal_pier(body: StaticBody3D, centre: Vector2, across: Vector2, deep: Vector2, half: Vector2, bottom: float, top: float, label: String) -> MeshInstance3D:
	const COURSES := 14
	const SIDES := 64
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertices: Array[PackedVector3Array] = []
	for course in COURSES + 1:
		var t := float(course) / float(COURSES)
		var scale := lerpf(0.68, 0.34, smoothstep(0.0, 0.46, t)) if t <= 0.46 else lerpf(0.34, 1.0, smoothstep(0.46, 1.0, t))
		var loop := PackedVector3Array()
		for side in SIDES:
			var angle := TAU * float(side) / float(SIDES)
			var c := cos(angle)
			var s := sin(angle)
			var offset := across * signf(c) * pow(absf(c), 2.0 / 6.0) * half.x * scale + deep * signf(s) * pow(absf(s), 2.0 / 6.0) * half.y * scale
			loop.append(Vector3(centre.x + offset.x, lerpf(bottom, top, t), centre.y + offset.y))
		vertices.append(loop)
	for course in COURSES:
		for side in SIDES:
			var next := (side + 1) % SIDES
			# Outside-facing winding. The previous order generated inward normals,
			# making the support read hollow or disappear from common views.
			for point: Vector3 in [vertices[course][side], vertices[course + 1][next], vertices[course][next], vertices[course][side], vertices[course + 1][side], vertices[course + 1][next]]:
				st.add_vertex(point)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(PLATFORM_COMPOSITE, 0.46, 0.34)
	body.add_child(mesh)
	# Three overlapping collision courses follow the visible flare, waist and
	# crown. A single waist-only core left the model's broadened base walkable.
	for course: Array in [[0.14, 0.54], [0.50, 0.34], [0.78, 0.72]]:
		var t0 := float(course[0])
		var scale := float(course[1])
		var height := (top - bottom) * 0.42
		var shape := CylinderShape3D.new()
		shape.radius = minf(half.x, half.y) * scale
		shape.height = height
		var collider := CollisionShape3D.new()
		collider.shape = shape
		collider.position = Vector3(centre.x, lerpf(bottom, top, t0), centre.y)
		collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
		body.add_child(collider)
	return mesh


static func _vertical_member(body: StaticBody3D, foot: Vector3, head: Vector3, radius: float, label: String) -> void:
	var height := maxf(head.y - foot.y, 0.12)
	var at := Vector3(foot.x, foot.y + height * 0.5, foot.z)
	var part := SuperEgg.build_part(Vector3(radius, height * 0.5, radius), STEEL, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	part.name = label
	part.position = at
	body.add_child(part)
	CollisionPolicy.add_box(body, part, Vector3(radius * 1.7, height, radius * 1.7), at, Basis(), false)


static func _beam(body: StaticBody3D, from: Vector3, to: Vector3, section: Vector2, colour: Color) -> void:
	var delta := to - from
	if delta.length() < 0.05:
		return
	var part := SuperEgg.build_part(Vector3(delta.length() * 0.5 + section.y * 0.5, section.x * 0.5, section.y * 0.5), colour, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	var x_axis := delta.normalized()
	var helper := Vector3.UP if absf(x_axis.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	var z_axis := x_axis.cross(helper).normalized()
	part.transform = Transform3D(Basis(x_axis, z_axis.cross(x_axis), z_axis), (from + to) * 0.5)
	body.add_child(part)
	CollisionPolicy.mark_decorative(part)


## One smooth pipe mesh following a polyline. Adjacent curve samples share
## vertex rings, so the rail is visually continuous even where its tangent
## changes; this replaces the former chain of overlapping SuperEgg stubs.
static func _tube(body: StaticBody3D, points: PackedVector3Array, radius: float, colour: Color, label: String) -> MeshInstance3D:
	const SIDES := 10
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[PackedVector3Array] = []
	for i in points.size():
		var tangent := (points[1] - points[0]).normalized() if i == 0 else ((points[-1] - points[-2]).normalized() if i == points.size() - 1 else (points[i + 1] - points[i - 1]).normalized())
		var side_axis := tangent.cross(Vector3.UP)
		if side_axis.length_squared() < 0.001:
			side_axis = tangent.cross(Vector3.FORWARD)
		side_axis = side_axis.normalized()
		var up_axis := side_axis.cross(tangent).normalized()
		var ring := PackedVector3Array()
		for side in SIDES:
			var angle := TAU * float(side) / float(SIDES)
			ring.append(points[i] + side_axis * cos(angle) * radius + up_axis * sin(angle) * radius)
		rings.append(ring)
	for i in rings.size() - 1:
		for side in SIDES:
			var next := (side + 1) % SIDES
			for point: Vector3 in [rings[i][side], rings[i][next], rings[i + 1][next], rings[i][side], rings[i + 1][next], rings[i + 1][side]]:
				st.add_vertex(point)
	st.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.name = label
	mesh.mesh = st.commit()
	mesh.material_override = SolidModel.material(colour, 0.55, 0.72)
	body.add_child(mesh)
	CollisionPolicy.mark_decorative(mesh)
	return mesh


static func _quad(st: SurfaceTool, faces: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for point: Vector3 in [a, b, c, a, c, d]:
		st.set_normal(normal)
		st.add_vertex(point)
	faces.append_array([a, b, c, a, c, d])
