class_name EntryDressing
extends RefCounted

## Entrance dressing for panel-walled buildings, chosen by what the building is
## for: a pent canopy for a house, a gabled columned portico for the civic hall,
## a deep awning over a forge, a hooded cart bay for a mill or sawmill, a shop
## awning for a bakery. All of it hangs off the front (local -Z) wall of a
## TownProps.build_building() body.
##
## Every roof here falls away from the wall (it sheds rain, so it has a grade),
## and every post runs from below the ground up to the underside of the beam it
## carries, so nothing stands short of its load.

const POST_HALF := 0.1
const SINK := 0.25
const SLAB_HALF := 0.045


static func dress(
	building: StaticBody3D, d_cells: int, floors: int, style: String, w_cells: int,
	roof: Color, timber: Color, stone: Color, facade_material: Color = Color(-1.0,-1.0,-1.0),
	opening_style: String = ""
) -> void:
	var half_depth := float(d_cells) * TownProps.CELL_SIZE * 0.5
	var width := float(w_cells) * TownProps.CELL_SIZE
	var openings := TownProps.panel_south_openings(width, 0, opening_style if opening_style != "" else style)
	match style:
		"porch", "herb_porch":
			var door_x := float(_opening_of(openings, "door")["center"])
			gabled_portico(building, door_x, 3.6, 2.0, -half_depth, 2.95, 30.0, roof, timber, stone, 2, Color(-1.0,-1.0,-1.0), true)
			if style == "herb_porch":
				_herb_racks(building, door_x, 3.6, -half_depth - 2.0 + 0.2)
		"door_case":
			FacadeFeatures.door_case(
				building, float(_opening_of(openings, "door")["center"]), -half_depth,
				TownProps.DOOR_WIDTH, TownProps.DOOR_HEIGHT, stone, timber
			)
		"corbel_hood":
			var door_x := float(_opening_of(openings, "door")["center"])
			corbel_hood(building, door_x, 2.6, 1.0, -half_depth, 3.0, 22.0, roof, timber, stone)
		"doorstep":
			var door_x := float(_opening_of(openings, "door")["center"])
			_stoop(building, door_x, 1.9, 0.9, -half_depth, stone, 1)
			_box(building, Vector3(0.9, 0.06, 0.07), timber, Vector3(door_x, TownProps.DOOR_HEIGHT + 0.12, -half_depth - 0.05), Basis(), false)
		"civic":
			# An open timber porch (carved bargeboards, posts and brackets), the
			# English market-hall way; the Greek pediment belongs to no one here.
			# Two outer posts make one clear central entrance bay. Three would put
			# the middle post directly in front of the centered double doors.
			gabled_portico(building, 0.0, 5.6, 2.4, -half_depth, 3.1, 32.0, roof, timber, stone, 2, Color(-1.0,-1.0,-1.0), true)
		"forge":
			var span := _span_of(openings, ["door", "bay"])
			lean_to(building, span.x, span.y, 1.7, -half_depth, 3.05, 10.0, roof, timber, stone, 3)
			_anvil(building, _bay_center(openings, "bay") + 2.0, -half_depth - 1.0)
		"cart":
			var bay := _opening_of(openings, "bay")
			lean_to(building, float(bay["center"]), 4.6, 1.6, -half_depth, 3.35, 12.0, roof, timber, stone, 2)
			# A hoist beam belongs to a loft door above it. A one-storey mill has its
			# own gable hoist (FacadeFeatures.gable_hoist); a beam and pulley block
			# hung inside the cart bay's own canopy only dangled in the doorway.
			if floors > 1:
				_hoist_beam(building, float(bay["center"]), -half_depth, float(floors) * TownProps.FLOOR_HEIGHT - 0.5, timber)
		"bakery":
			lean_to(building, 0.0, 7.0, 1.3, -half_depth, 3.0, 14.0, roof, timber, stone, 3)
		_:
			var door := _opening_of(openings, "door")
			lean_to(building, float(door["center"]), 3.0, 1.2, -half_depth, 2.95, 14.0, roof, timber, stone, 2)


static func _opening_of(openings: Array[Dictionary], kind: String) -> Dictionary:
	for opening in openings:
		if str(opening["kind"]) == kind:
			return opening
	return {"center": 0.0, "width": TownProps.DOOR_WIDTH}


static func _bay_center(openings: Array[Dictionary], kind: String) -> float:
	return float(_opening_of(openings, kind)["center"])


## Returns Vector2(center, width) covering every opening of the given kinds.
static func _span_of(openings: Array[Dictionary], kinds: Array) -> Vector2:
	var low := INF
	var high := -INF
	for opening in openings:
		if str(opening["kind"]) in kinds:
			low = minf(low, float(opening["center"]) - float(opening["width"]) * 0.5 - 0.5)
			high = maxf(high, float(opening["center"]) + float(opening["width"]) * 0.5 + 0.5)
	return Vector2((low + high) * 0.5, high - low)


static func _box(
	body: StaticBody3D, half: Vector3, color: Color, position: Vector3, basis: Basis = Basis(),
	solid: bool = true, parkour: bool = false
) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	mesh.transform = Transform3D(basis, position)
	body.add_child(mesh)
	if solid:
		CollisionPolicy.add_box(body, mesh, half * 2.0, position, basis, parkour)
	else:
		CollisionPolicy.mark_decorative(mesh)
	return mesh


## One structural knee brace between two authored bearing points. Building it
## from its endpoints avoids the easy sign mistake where a nominal 45-degree
## rotation makes the member descend toward the doorway instead of rising from
## its post to the beam it supports.
static func _brace_between(
	body: StaticBody3D, from: Vector3, to: Vector3, color: Color, thickness: float = 0.05
) -> void:
	var direction := to - from
	var length := direction.length()
	if length < 0.05:
		return
	var brace := SuperEgg.build_part(
		Vector3(thickness, length * 0.5, thickness), color,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	brace.position = (from + to) * 0.5
	brace.quaternion = Quaternion(Vector3.UP, direction / length)
	body.add_child(brace)
	CollisionPolicy.mark_decorative(brace)


## Pent canopy: a sloped slab falling away from the wall, carried by a front
## beam on square posts, with a stone stoop beneath.
static func lean_to(
	building: StaticBody3D, center_x: float, width: float, run: float, wall_z: float,
	attach_y: float, pitch_degrees: float, roof: Color, timber: Color, stone: Color, post_count: int
) -> void:
	var pitch := deg_to_rad(pitch_degrees)
	var drop := run * tan(pitch)
	var front_z := wall_z - run
	var front_y := attach_y - drop
	var slab_length := run / cos(pitch)
	var basis := Basis(Vector3.RIGHT, -pitch)
	_box(
		building, Vector3(width * 0.5 + 0.15, SLAB_HALF, slab_length * 0.5 + 0.05), roof,
		Vector3(center_x, attach_y - drop * 0.5, wall_z - run * 0.5), basis, true, true
	)
	# Ledger fixing the high edge to the wall.
	_box(building, Vector3(width * 0.5, 0.09, 0.06), timber, Vector3(center_x, attach_y - 0.1, wall_z - 0.05), Basis(), false)
	# Front beam directly under the low edge.
	var beam_half := 0.1
	var beam_y := front_y - SLAB_HALF - beam_half
	_box(building, Vector3(width * 0.5, beam_half, beam_half), timber, Vector3(center_x, beam_y, front_z + 0.12), Basis(), true)
	var post_top := beam_y - beam_half
	for i in post_count:
		var t := 0.0 if post_count == 1 else float(i) / float(post_count - 1)
		var x := center_x + lerpf(-(width * 0.5 - 0.15), width * 0.5 - 0.15, t)
		var height := post_top + SINK
		_box(
			building, Vector3(POST_HALF, height * 0.5, POST_HALF), timber,
			Vector3(x, post_top - height * 0.5, front_z + 0.12)
		)
	_stoop(building, center_x, width, run, wall_z, stone)


## Gabled portico: ridge running out from the wall, a triangular pediment on the
## front, an entablature beam, and columns that reach it.
static func gabled_portico(
	building: StaticBody3D, center_x: float, width: float, run: float, wall_z: float,
	eave_y: float, pitch_degrees: float, roof: Color, timber: Color, stone: Color, column_count: int,
	pediment_color: Color = Color(-1.0,-1.0,-1.0), open_gable: bool = false
) -> void:
	var pitch := deg_to_rad(pitch_degrees)
	var half_roof := width * 0.5 + 0.25
	var ridge_y := eave_y + half_roof * tan(pitch)
	var length := run + 0.22
	var centre_z := wall_z + 0.02 - length * 0.5
	var panel_length := half_roof / cos(pitch)
	for side: float in [-1.0, 1.0]:
		var basis := Basis(Vector3.BACK, -pitch * side)
		_box(
			building, Vector3(panel_length * 0.5 + 0.03, SLAB_HALF, length * 0.5), roof,
			Vector3(center_x + side * half_roof * 0.5, eave_y + half_roof * tan(pitch) * 0.5, centre_z),
			basis, true, true
		)
	# Ridge cap.
	# Seat the ridge cap into the two converging planes.
	_box(building,Vector3(0.14,0.12,length*0.5),roof.darkened(0.08),Vector3(center_x,ridge_y-0.09,centre_z),Basis(),false)
	var front_z := wall_z - run
	# Entablature beam under the pediment, then the pediment itself.
	var beam_half := 0.15
	var beam_y := eave_y - beam_half
	_box(building, Vector3(width * 0.5 + 0.1, beam_half, 0.14), timber, Vector3(center_x, beam_y, front_z + 0.14), Basis(), true)
	if open_gable:
		# Open to the sky above the tie beam: carved bargeboards along the rakes, a
		# collar and king post under the ridge, so the porch reads as timber.
		var rake := half_roof / cos(pitch)
		for side: float in [-1.0, 1.0]:
			_box(
				building, Vector3(rake * 0.5, 0.07, 0.05), timber.lightened(0.06),
				Vector3(center_x + side * half_roof * 0.5, eave_y + half_roof * tan(pitch) * 0.5 - 0.06, front_z + 0.1),
				Basis(Vector3.BACK, -pitch * side), false
			)
		_box(building, Vector3(half_roof * 0.4, 0.05, 0.05), timber, Vector3(center_x, eave_y + half_roof * tan(pitch) * 0.55, front_z + 0.12), Basis(), false)
		_box(building, Vector3(0.05, half_roof * tan(pitch) * 0.5, 0.05), timber, Vector3(center_x, eave_y + half_roof * tan(pitch) * 0.5, front_z + 0.12), Basis(), false)
	else:
		var pediment := MeshInstance3D.new()
		pediment.mesh = _prism(
			[Vector2(-half_roof, 0.0), Vector2(half_roof, 0.0), Vector2(0.0, half_roof * tan(pitch))], 0.16
		)
		var material := StandardMaterial3D.new()
		material.albedo_color = pediment_color if pediment_color.r>=0.0 else stone
		material.roughness = 0.85
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		pediment.material_override = material
		pediment.position = Vector3(center_x, eave_y, front_z + 0.14)
		building.add_child(pediment)
		CollisionPolicy.mark_decorative(pediment)

	var column_top := beam_y - beam_half
	for i in column_count:
		var t := float(i) / float(column_count - 1)
		var x := center_x + lerpf(-(width * 0.5 - 0.3), width * 0.5 - 0.3, t)
		var height := column_top + SINK
		_box(
			building, Vector3(0.15, height * 0.5, 0.15), timber.lightened(0.1),
			Vector3(x, column_top - height * 0.5, front_z + 0.2)
		)
		# Base block, so the column stands on something.
		_box(building, Vector3(0.24, 0.1, 0.24), stone, Vector3(x, 0.1, front_z + 0.2))
		if open_gable:
			# Knee brace rises from the post toward the inner span of the beam. The
			# previous angle was reversed, so it descended toward the doorway and
			# visually pulled on the corner rather than propping it up.
			if i != 0 and i != column_count - 1:
				continue
			var inward := 1.0 if i == 0 else -1.0
			_brace_between(
				building,
				Vector3(x, column_top - 0.68, front_z + 0.2),
				Vector3(x + inward * 0.58, column_top - 0.08, front_z + 0.2),
				timber.lightened(0.05)
			)
	_stoop(building, center_x, width, run, wall_z, stone, 2)


## Pent hood carried on stone corbels at the wall instead of posts, with a
## timber brace under the front edge: for the oldest, low stone houses.
static func corbel_hood(
	building: StaticBody3D, center_x: float, width: float, run: float, wall_z: float,
	attach_y: float, pitch_degrees: float, roof: Color, timber: Color, stone: Color
) -> void:
	lean_to(building, center_x, width, run, wall_z, attach_y, pitch_degrees, roof, timber, stone, 0)
	var drop := run * tan(deg_to_rad(pitch_degrees))
	for side: float in [-1.0, 1.0]:
		var x := center_x + side * (width * 0.5 - 0.3)
		_box(building, Vector3(0.16, 0.14, 0.28), stone.lightened(0.04), Vector3(x, attach_y - 0.3, wall_z - 0.28), Basis(), false)
		_box(building, Vector3(0.12, 0.12, 0.2), stone, Vector3(x, attach_y - 0.58, wall_z - 0.2), Basis(), false)
		_brace_between(
			building,
			Vector3(x, attach_y - 0.88, wall_z - 0.08),
			Vector3(x, attach_y - drop - 0.10, wall_z - run + 0.12),
			timber, 0.055
		)


## Bundles of herbs drying from a rail under a porch roof.
static func _herb_racks(building: StaticBody3D, center_x: float, width: float, z: float) -> void:
	var rail_y := 2.55
	_box(building, Vector3(width * 0.5 - 0.3, 0.035, 0.035), TownProps.TRIM_WOOD, Vector3(center_x, rail_y, z), Basis(), false)
	var tones: Array[Color] = [Color(0.40, 0.52, 0.28), Color(0.62, 0.55, 0.30), Color(0.46, 0.36, 0.52)]
	for i in 7:
		var x := center_x + lerpf(-(width * 0.5 - 0.5), width * 0.5 - 0.5, float(i) / 6.0)
		_box(building, Vector3(0.05, 0.19, 0.05), tones[i % 3], Vector3(x, rail_y - 0.22, z), Basis(), false)


static func _stoop(
	building: StaticBody3D, center_x: float, width: float, run: float, wall_z: float,
	stone: Color, steps: int = 1
) -> void:
	for step in steps:
		var depth := run + 0.2 - float(step) * 0.55
		var top := 0.07 * float(step + 1)
		_box(
			building, Vector3(width * 0.5 + 0.1 - float(step) * 0.2, top * 0.5, depth * 0.5),
			stone.darkened(0.08), Vector3(center_x, top * 0.5, wall_z - depth * 0.5 - 0.02),
			Basis(), true, true
		)


## Projecting hoist beam with a pulley block above a cart bay.
static func _hoist_beam(building: StaticBody3D, center_x: float, wall_z: float, y: float, timber: Color) -> void:
	_box(building, Vector3(0.13, 0.13, 1.1), timber, Vector3(center_x, y, wall_z - 1.0), Basis(), true)
	_box(building, Vector3(0.09, 0.3, 0.09), timber, Vector3(center_x, y - 0.4, wall_z - 1.6), Basis(), false)
	var wheel := SuperEgg.build_part(Vector3(0.18, 0.18, 0.04), Color(0.25, 0.22, 0.2), 2.0, 2.0)
	wheel.position = Vector3(center_x, y - 0.18, wall_z - 1.6)
	building.add_child(wheel)
	CollisionPolicy.mark_decorative(wheel)


## Anvil on a stump outside the forge bay.
static func _anvil(building: StaticBody3D, x: float, z: float) -> void:
	_box(building, Vector3(0.28, 0.3, 0.28), Color(0.38, 0.26, 0.15), Vector3(x, 0.3, z), Basis(), true)
	_box(building, Vector3(0.4, 0.1, 0.16), Color(0.18, 0.18, 0.2), Vector3(x, 0.7, z), Basis(), true)


static func _prism(points: Array[Vector2], thickness: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front := thickness * 0.5
	var back := -front
	var count := points.size()
	var centroid := Vector2.ZERO
	for point in points:
		centroid += point / float(count)
	for index in count:
		var a := points[index]
		var b := points[(index + 1) % count]
		for v: Vector2 in [centroid, a, b]:
			tool.set_normal(Vector3.BACK)
			tool.add_vertex(Vector3(v.x, v.y, front))
		for v: Vector2 in [centroid, b, a]:
			tool.set_normal(Vector3.FORWARD)
			tool.add_vertex(Vector3(v.x, v.y, back))
		var edge := (b - a).normalized()
		var normal := Vector3(edge.y, -edge.x, 0.0)
		for pair: Array in [[a, front], [a, back], [b, front], [b, front], [a, back], [b, back]]:
			var p: Vector2 = pair[0]
			tool.set_normal(normal)
			tool.add_vertex(Vector3(p.x, p.y, pair[1]))
	return tool.commit()
