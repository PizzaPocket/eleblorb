class_name StiltRoofs
extends RefCounted

## The fishing village's roofs (docs/style_charters.md, "Crossroads Fishing
## Village"): hips and gables at one pitch band, deep eaves, pent roofs on
## verandas. Every slope is the shared Ohio construction (TownProps.roof_slab):
## squarish shoulders, one flat cut at the ridge, mitred hips, no overlap.
## Heights are in the owning body's frame; the ridge runs along x.

const PITCH := deg_to_rad(32.0)
const PENT_PITCH := deg_to_rad(16.0)
const EAVE := 0.9
const GABLE_OVERHANG := 0.6
## Ohio's slab thickness: thick enough that the SuperEgg's squarish shoulder
## reads at the eave as a soft roll, not a cardboard edge.
const THICKNESS := TownProps.ROOF_THICKNESS
## The roof sits this far above the wall plate.
const PLATE := 0.12
const MARGIN := 0.8


## A hip roof over walls of half extents `half` (x the long side), whose plate is
## at `wall_top`. Four slopes, the hips mitred to the long slopes, a ridge cap.
static func hip(body: StaticBody3D, half: Vector2, wall_top: float, color: Color, cap_color: Color) -> void:
	var tan_p := tan(PITCH)
	var c := cos(PITCH)
	var s := sin(PITCH)
	var hx := half.x
	var hz := half.y
	var top0 := wall_top + PLATE
	var eave_y := top0 - EAVE * tan_p
	var ridge_y := top0 + hz * tan_p
	var ridge_half := maxf(hx - hz, 0.0)
	var outs: Array[Vector3] = [Vector3(0, 0, 1), Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(-1, 0, 0)]
	var normals: Array[Vector3] = []
	var bases: Array[Basis] = []
	var mids: Array[Vector3] = []
	var run := hz + EAVE
	var length := run / c
	for index in 4:
		var o: Vector3 = outs[index]
		var n := Vector3.UP * c + o * s
		var u := -o * c + Vector3.UP * s
		normals.append(n)
		bases.append(Basis(n.cross(u), n, u))
		var is_long := index < 2
		var d_out := (hz + EAVE) if is_long else (hx + EAVE)
		var d_ridge := 0.0 if is_long else ridge_half
		mids.append(o * ((d_out + d_ridge) * 0.5) + Vector3.UP * ((eave_y + ridge_y) * 0.5))
	for index in 4:
		var o: Vector3 = outs[index]
		var is_long := index < 2
		var across := (hx + EAVE if is_long else hz + EAVE) + MARGIN
		var extension := TownProps.ROOF_CUT_EXTENSION if is_long else 0.0
		var basis := bases[index]
		var origin := mids[index] - basis.y * THICKNESS * 0.5 + basis.z * (extension * 0.5)
		var to_local := Transform3D(basis, origin).affine_inverse()
		var planes: Array[Plane] = []
		if is_long:
			planes.append(to_local * Plane(-o, 0.0))
		# Mitre against the two neighbours (the east and west hips for a long slope,
		# the north and south slopes for a hip).
		var neighbours: Array[int] = []
		neighbours.assign([2, 3] if is_long else [0, 1])
		for other in neighbours:
			var long_index := index if is_long else other
			var hip_index := other if is_long else index
			var long_o: Vector3 = outs[long_index]
			var hip_o: Vector3 = outs[hip_index]
			var corner := Vector3(hip_o.x * (hx + EAVE), eave_y, long_o.z * (hz + EAVE))
			var ridge_end := Vector3(hip_o.x * ridge_half, ridge_y, 0.0)
			var plane_long := TownProps._mitre_plane(
				corner, ridge_end - corner, normals[long_index], normals[hip_index], mids[long_index]
			)
			var plane := plane_long if is_long else Plane(-plane_long.normal, -plane_long.d)
			planes.append(to_local * plane)
		var semi := Vector3(across, THICKNESS * 0.5, length * 0.5 + extension * 0.5)
		var slab := TownProps.roof_slab(semi, color, planes)
		slab.transform = Transform3D(basis, origin)
		body.add_child(slab)
		_slope_collider(body, slab, index, outs, normals[index], hx, hz, ridge_half, eave_y, ridge_y)
	_ridge_cap(body, ridge_half, ridge_y, cap_color)


## A gable roof over walls of half extents `half` (ridge along x), the gable ends
## open to be filled by the walls.
static func gable(body: StaticBody3D, half: Vector2, wall_top: float, color: Color, cap_color: Color) -> void:
	var tan_p := tan(PITCH)
	var c := cos(PITCH)
	var s := sin(PITCH)
	var top0 := wall_top + PLATE
	var eave_y := top0 - EAVE * tan_p
	var ridge_y := top0 + half.y * tan_p
	var run := half.y + EAVE
	var length := run / c
	for sign_z: float in [1.0, -1.0]:
		var o := Vector3(0, 0, sign_z)
		var n := Vector3.UP * c + o * s
		var u := -o * c + Vector3.UP * s
		var basis := Basis(n.cross(u), n, u)
		var mid := o * (run * 0.5) + Vector3.UP * ((eave_y + ridge_y) * 0.5)
		var centre := mid - basis.y * THICKNESS * 0.5
		var across := half.x + GABLE_OVERHANG
		var slab := TownProps.build_ridge_slab(body, basis, centre, across, length, THICKNESS, color, 1.0, Plane(-o, 0.0))
		CollisionPolicy.add_box(body, slab, Vector3(across * 2.0, 0.3, length), centre, basis, true)
	_ridge_cap(body, half.x + GABLE_OVERHANG - 0.3, ridge_y, cap_color)


## A single sloping pent roof, falling toward the horizontal unit direction `fall`,
## over the rectangle `rect` (plan, in the body's frame). `high_y` is the height of
## its high edge's top surface. The slab runs past its high edge and is cut there
## by the vertical plane of the wall it leans on, so it meets the wall flush (the
## Ohio construction); the eave and sides keep the SuperEgg's soft shoulder.
static func pent(body: StaticBody3D, rect: Rect2, high_y: float, fall: Vector3, color: Color) -> void:
	var c := cos(PENT_PITCH)
	var s := sin(PENT_PITCH)
	var along_fall := absf(fall.x) * rect.size.x + absf(fall.z) * rect.size.y
	var across := absf(fall.z) * rect.size.x + absf(fall.x) * rect.size.y
	var length := along_fall / c
	var u := fall * c - Vector3.UP * s
	var n := Vector3.UP * c + fall * s
	var basis := Basis(n.cross(u), n, u)
	var centre_xz := rect.get_center()
	var drop := along_fall * tan(PENT_PITCH)
	var mid := Vector3(centre_xz.x, high_y - drop * 0.5, centre_xz.y)
	var centre := mid - n * THICKNESS * 0.5
	var extension := TownProps.ROOF_CUT_EXTENSION
	var origin := centre - u * (extension * 0.5)
	var wall_point := Vector3(centre_xz.x, high_y, centre_xz.y) - fall * (along_fall * 0.5)
	var wall_plane := Plane(-fall, (-fall).dot(wall_point))
	var planes: Array[Plane] = [Transform3D(basis, origin).affine_inverse() * wall_plane]
	var slab := TownProps.roof_slab(Vector3(across * 0.5 + 0.1, THICKNESS * 0.5, length * 0.5 + extension * 0.5), color, planes)
	slab.transform = Transform3D(basis, origin)
	body.add_child(slab)
	# The collider shares the slab's underside (a thicker box centred on it would
	# hang below the visible roof and steal headroom on the veranda beneath).
	var collider_thickness := THICKNESS + 0.1
	CollisionPolicy.add_box(body, slab, Vector3(across + 0.2, collider_thickness, length), centre + n * (collider_thickness - THICKNESS) * 0.5, basis, true)


static func _ridge_cap(body: StaticBody3D, ridge_half: float, ridge_y: float, cap_color: Color) -> void:
	var half_length := maxf(ridge_half + 0.3, 0.3)
	var cap := SuperEgg.build_part(Vector3(half_length, 0.1, 0.13), cap_color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	cap.position = Vector3(0.0, ridge_y + 0.04, 0.0)
	body.add_child(cap)
	CollisionPolicy.mark_decorative(cap)


## A convex collider matching one hip-roof slope's visible outline.
static func _slope_collider(
	body: StaticBody3D, visual: Node3D, index: int, outs: Array[Vector3], normal: Vector3,
	hx: float, hz: float, ridge_half: float, eave_y: float, ridge_y: float
) -> void:
	var o: Vector3 = outs[index]
	var top: Array[Vector3] = []
	if index < 2:
		for sx: float in [-1.0, 1.0]:
			top.append(Vector3(sx * (hx + EAVE), eave_y, o.z * (hz + EAVE)))
		for sx: float in [1.0, -1.0]:
			top.append(Vector3(sx * ridge_half, ridge_y, 0.0))
	else:
		for sz: float in [-1.0, 1.0]:
			top.append(Vector3(o.x * (hx + EAVE), eave_y, sz * (hz + EAVE)))
		top.append(Vector3(o.x * ridge_half, ridge_y, 0.0))
	var points := PackedVector3Array()
	for point in top:
		points.append(point)
		points.append(point - normal * 0.3)
	var shape := ConvexPolygonShape3D.new()
	shape.points = points
	var collision := CollisionShape3D.new()
	collision.shape = shape
	visual.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	collision.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.PARKOUR)
	body.add_child(collision)
