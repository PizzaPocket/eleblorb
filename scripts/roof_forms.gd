class_name RoofForms
extends RefCounted

## Roof forms beyond the plain gable, built from convex pieces: a cross-gable
## (a projecting gable bay over the front of a range), prisms for the truncated
## gable wall of a half-hip, and a ridge belfry. They share TownProps' roof
## geometry exactly (pitch, eave overhang, floor heights), so each piece lies
## in the plane of the roof it joins; nothing is cut, the pieces simply meet.
##
## Building frame: front wall at -Z, ridge along X. A roof slope rises toward
## the ridge at TownProps.ROOF_PITCH from the eave line at y = floors *
## FLOOR_HEIGHT, which lies at z = -/+ (half_depth + ROOF_EAVE_OVERHANG).

const ROOF_SLAB := 0.1


static func _material(color: Color, rough: float = 0.84) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


static func _add_convex(body: StaticBody3D, points: PackedVector3Array) -> void:
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)


## A convex polygon given in local XY, extruded `thickness` along local Z and
## placed by `origin` and `basis`. Used for the flat walls under gables.
static func prism(
	body: StaticBody3D, polygon: Array[Vector2], origin: Vector3, basis: Basis,
	thickness: float, color: Color, solid: bool = true
) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := thickness * 0.5
	var count := polygon.size()
	var all_points := PackedVector3Array()
	for point in polygon:
		all_points.append(Vector3(point.x, point.y, half))
		all_points.append(Vector3(point.x, point.y, -half))
	for i in range(1, count - 1):
		for index: int in [0, i, i + 1]:
			tool.add_vertex(Vector3(polygon[index].x, polygon[index].y, half))
		for index: int in [0, i + 1, i]:
			tool.add_vertex(Vector3(polygon[index].x, polygon[index].y, -half))
	for i in count:
		var a := polygon[i]
		var b := polygon[(i + 1) % count]
		for vertex: Vector3 in [
			Vector3(a.x, a.y, half), Vector3(b.x, b.y, half), Vector3(a.x, a.y, -half),
			Vector3(a.x, a.y, -half), Vector3(b.x, b.y, half), Vector3(b.x, b.y, -half),
		]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _material(color, 0.86)
	visual.transform = Transform3D(basis, origin)
	body.add_child(visual)
	if solid:
		var world_points := PackedVector3Array()
		for point in all_points:
			world_points.append(origin + basis * point)
		_add_convex(body, world_points)
	else:
		CollisionPolicy.mark_decorative(visual)
	return visual


## One flat triangular roof slab through three points (building frame), with the
## roof's own thickness, landable like every roof.
static func slab_triangle(
	body: StaticBody3D, a: Vector3, b: Vector3, c: Vector3, color: Color, solid: bool = true,
	thickness: float = ROOF_SLAB
) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.y < 0.0:
		normal = -normal
	var up := normal * thickness * 0.5
	var corners: Array[Vector3] = [a, b, c]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for vertex in corners:
		tool.add_vertex(vertex + up)
	for index: int in [0, 2, 1]:
		tool.add_vertex(corners[index] - up)
	for i in 3:
		var p := corners[i]
		var q := corners[(i + 1) % 3]
		for vertex: Vector3 in [p + up, q + up, p - up, p - up, q + up, q - up]:
			tool.add_vertex(vertex)
	tool.generate_normals()
	var visual := MeshInstance3D.new()
	visual.mesh = tool.commit()
	visual.material_override = _material(color, 0.82)
	body.add_child(visual)
	if solid:
		var points := PackedVector3Array()
		for vertex in corners:
			points.append(vertex + up)
			points.append(vertex - up)
		_add_convex(body, points)
	else:
		CollisionPolicy.mark_decorative(visual)


static func _eave_run(d_cells: int) -> float:
	return float(d_cells) * TownProps.CELL_SIZE * 0.5 + TownProps.ROOF_EAVE_OVERHANG


## A cross-gable over the front of the range. Its two roof slopes are SuperEgg
## slabs of the main roof's pitch and thickness, each cut along the cross ridge by
## the vertical plane through it and along its valley by the mitre plane it shares
## with the main slope (which is cut away beneath the gable by TownProps; see
## _build_front_slope), so the gable's roof is the roof there. A gable wall stands
## on the front wall under them, flush with the slabs' undersides, with carved
## bargeboards along the rakes, a finial and a louvre vent.
static func cross_gable(
	body: StaticBody3D, d_cells: int, floors: int, center_x: float, width: float,
	roof: Color, wall: Color, trim: Color
) -> void:
	var tan_pitch := tan(TownProps.ROOF_PITCH)
	var floor_top := float(floors) * TownProps.FLOOR_HEIGHT
	var half_wall := float(d_cells) * TownProps.CELL_SIZE * 0.5
	var half := width * 0.5
	var main_ridge_y := TownProps.roof_center_y(floor_top, half_wall, 0.0)
	var front_run := half_wall + TownProps.ROOF_EAVE_OVERHANG
	var front_z := -front_run
	var eave_y := main_ridge_y - front_run * tan_pitch
	var ridge_y := eave_y + half * tan_pitch
	var planes := TownProps.cross_gable_planes(main_ridge_y, center_x, half, half_wall)
	var depth := half + 0.4
	var slope_len := half / cos(TownProps.ROOF_PITCH)
	var thickness := TownProps.ROOF_THICKNESS
	var material := _material(roof, 0.82)
	for side: float in [-1.0, 1.0]:
		var direction := Vector3(-side * cos(TownProps.ROOF_PITCH), sin(TownProps.ROOF_PITCH), 0.0)
		var normal := Vector3(side * sin(TownProps.ROOF_PITCH), cos(TownProps.ROOF_PITCH), 0.0)
		var y_axis := normal
		var z_axis := direction
		var x_axis := y_axis.cross(z_axis).normalized()
		var basis := Basis(x_axis, y_axis, z_axis)
		var eave_point := Vector3(center_x + side * half, eave_y, front_z + depth * 0.5)
		var extension := 0.4
		var centre := eave_point + direction * ((slope_len + extension) * 0.5)
		var to_local := Transform3D(basis, centre).affine_inverse()
		var clip: Array[Plane] = [
			to_local * Plane(Vector3(-side, 0.0, 0.0), -side * center_x),
			to_local * (planes["cross_left" if side < 0.0 else "cross_right"] as Plane),
		]
		var slab := MeshInstance3D.new()
		TownProps.mark_roof_slab(slab)
		slab.mesh = SuperEgg.build_clipped_mesh(
			Vector3(depth * 0.5, thickness * 0.5, (slope_len + extension) * 0.5), clip,
			TownProps.ROOF_EDGE_EPSILON, TownProps.ROOF_EDGE_EPSILON,
			TownProps.ROOF_SEGMENTS, TownProps.ROOF_RINGS
		)
		slab.material_override = material
		slab.transform = Transform3D(basis, centre)
		body.add_child(slab)
		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(depth, TownProps.ROOF_COLLISION_THICKNESS, slope_len)
		collider.shape = box
		collider.transform = Transform3D(basis, eave_point + direction * (slope_len * 0.5))
		collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
		body.add_child(collider)
	# The gable wall: its slopes follow the slabs' undersides, so it fills exactly to
	# them, standing on the wall top.
	var wall_z := -half_wall
	var underside_apex := ridge_y - TownProps.roof_vertical_half()
	var wall_half := (underside_apex - floor_top) / tan_pitch
	var gable: Array[Vector2] = [Vector2(-wall_half, 0.0), Vector2(wall_half, 0.0), Vector2(0.0, underside_apex - floor_top)]
	prism(body, gable, Vector3(center_x, floor_top, wall_z), Basis(), 0.2, wall, true)
	var rake := half / cos(TownProps.ROOF_PITCH)
	for side: float in [-1.0, 1.0]:
		var board := SuperEgg.build_part(Vector3(rake * 0.5 + 0.04, 0.075, 0.04), trim, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		board.position = Vector3(center_x + side * half * 0.5, eave_y + half * tan_pitch * 0.5 - TownProps.roof_vertical_half() - 0.04, front_z + 0.03)
		board.basis = Basis(Vector3.BACK, -side * TownProps.ROOF_PITCH)
		body.add_child(board)
		CollisionPolicy.mark_decorative(board)
	var finial := SuperEgg.build_part(Vector3(0.08, 0.2, 0.08), trim, 2.0, 2.0)
	finial.position = Vector3(center_x, ridge_y + TownProps.roof_vertical_half() + 0.12, front_z + 0.03)
	body.add_child(finial)
	CollisionPolicy.mark_decorative(finial)
	var vent_y := floor_top + (underside_apex - floor_top) * 0.38
	var vent := SuperEgg.build_part(Vector3(0.3, 0.22, 0.03), trim.darkened(0.15), 2.4, 2.4)
	vent.position = Vector3(center_x, vent_y, wall_z - 0.12)
	body.add_child(vent)
	CollisionPolicy.mark_decorative(vent)
	for i in 3:
		var slat := SuperEgg.build_part(Vector3(0.24, 0.018, 0.02), trim.lightened(0.2), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
		slat.position = Vector3(center_x, vent_y - 0.1 + float(i) * 0.1, wall_z - 0.145)
		body.add_child(slat)
		CollisionPolicy.mark_decorative(slat)


## A belfry on the ridge: a square open timber frame on four posts with cross
## braces, a headstock and a hanging bell with its clapper, a pyramidal tile cap
## and a finial. The ridge beam runs under its sill, so it sits on the roof.
static func belfry(
	body: StaticBody3D, d_cells: int, floors: int, center_x: float, roof: Color, timber: Color
) -> void:
	var ridge_y := TownProps.roof_top_y(float(floors) * TownProps.FLOOR_HEIGHT, float(d_cells) * TownProps.CELL_SIZE * 0.5, 0.0)
	var y0 := ridge_y - 0.32
	var half := 0.56
	var height := 1.5
	var tone := timber.lightened(0.05)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var post := SuperEgg.build_part(Vector3(0.075, height * 0.5, 0.075), tone, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			post.position = Vector3(center_x + sx * half, y0 + height * 0.5, sz * half)
			body.add_child(post)
			CollisionPolicy.mark_decorative(post)
	for level: float in [0.0, height]:
		for axis in 2:
			var beam := SuperEgg.build_part(
				Vector3(half + 0.1 if axis == 0 else 0.07, 0.07, 0.07 if axis == 0 else half + 0.1), tone,
				SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
			)
			for sign_value: float in [-1.0, 1.0]:
				var copy := beam.duplicate() as MeshInstance3D
				copy.position = Vector3(
					center_x + (0.0 if axis == 0 else sign_value * half), y0 + level,
					sign_value * half if axis == 0 else 0.0
				)
				body.add_child(copy)
				CollisionPolicy.mark_decorative(copy)
			beam.free()
	for sz: float in [-1.0, 1.0]:
		for lean: float in [-1.0, 1.0]:
			var brace := SuperEgg.build_part(Vector3(0.04, 0.55, 0.04), tone, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
			brace.position = Vector3(center_x + lean * half * 0.5, y0 + height * 0.5, sz * half)
			brace.basis = Basis(Vector3.BACK, lean * deg_to_rad(52.0))
			body.add_child(brace)
			CollisionPolicy.mark_decorative(brace)
	var headstock := SuperEgg.build_part(Vector3(half + 0.05, 0.06, 0.06), timber.darkened(0.15), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	headstock.position = Vector3(center_x, y0 + height - 0.2, 0.0)
	body.add_child(headstock)
	CollisionPolicy.mark_decorative(headstock)
	# The bell hangs from a pivot at the headstock so it can swing when rung; the
	# building keeps a reference for whatever rope rings it (see the meeting
	# hall's bell rope). The bell mouth is open below, with the clapper inside.
	var pivot := Node3D.new()
	pivot.name = "VillageBellPivot"
	pivot.position = Vector3(center_x, y0 + height - 0.2, 0.0)
	body.add_child(pivot)
	body.set_meta("bell_pivot", pivot)
	body.set_meta("bell_hang_y", y0 + height - 0.62)
	var bell := SuperEgg.build_part(Vector3(0.3, 0.34, 0.3), VillageWorks.BRASS, 2.0, 2.0)
	bell.position = Vector3(0.0, -0.42, 0.0)
	pivot.add_child(bell)
	CollisionPolicy.mark_decorative(bell)
	var clapper := SuperEgg.build_part(Vector3(0.05, 0.05, 0.05), timber.darkened(0.3), 2.0, 2.0)
	clapper.position = Vector3(0.0, -0.75, 0.0)
	pivot.add_child(clapper)
	CollisionPolicy.mark_decorative(clapper)
	var cap_y := y0 + height + 0.07
	var cap_half := half + 0.2
	var apex := Vector3(center_x, cap_y + 0.85, 0.0)
	var corners: Array[Vector3] = [
		Vector3(center_x - cap_half, cap_y, -cap_half), Vector3(center_x + cap_half, cap_y, -cap_half),
		Vector3(center_x + cap_half, cap_y, cap_half), Vector3(center_x - cap_half, cap_y, cap_half),
	]
	for i in 4:
		slab_triangle(body, corners[i], corners[(i + 1) % 4], apex, roof, false, 0.06)
	var finial := SuperEgg.build_part(Vector3(0.04, 0.3, 0.04), VillageWorks.BRASS, 2.2, 2.2)
	finial.position = Vector3(center_x, apex.y + 0.22, 0.0)
	body.add_child(finial)
	CollisionPolicy.mark_decorative(finial)
