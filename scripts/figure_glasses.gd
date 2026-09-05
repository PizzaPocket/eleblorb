class_name FigureGlasses
extends RefCounted

## Lensless glasses for ProceduralFigure heads. Each eye rim is an extruded
## superellipse ring with a genuinely empty center; only the bridge joins the
## two rims for now (temples/stems intentionally come later).

const FRAME_COLOR := Color(0.12, 0.09, 0.07)
const EYE_OFFSET := deg_to_rad(18.0)
const FRONT_CLEARANCE := 0.01
const RIM_WIDTH_FACTOR := 2.25  # 25% larger than the previous 1.8
const RIM_HEIGHT_FACTOR := 1.1875  # 25% larger than the previous 0.95
const FRAME_THICKNESS := 0.01
const FRAME_DEPTH := 0.012
const SHAPE_EPSILON := 3.5
const SEGMENTS := 32
const BRIDGE_SEGMENTS := 10
const BRIDGE_ARCH_HEIGHT := 0.008


static func add_glasses(head: MeshInstance3D, semi_axes: Vector3, color: Color = FRAME_COLOR) -> void:
	var eye_radius := semi_axes.x * FigureEyes.EYE_RADIUS_FACTOR
	var left_eye := SuperEgg.surface_point(semi_axes, 0.0, -EYE_OFFSET)
	var right_eye := SuperEgg.surface_point(semi_axes, 0.0, EYE_OFFSET)
	var rim_half_width := eye_radius * RIM_WIDTH_FACTOR
	var rim_half_height := eye_radius * FigureEyes.EYE_HEIGHT_RATIO * RIM_HEIGHT_FACTOR
	# Both eyes share a Z coordinate by symmetry. Put the back face of the
	# frame one centimetre beyond the eye's surface, not its center.
	var frame_z := (left_eye.z + right_eye.z) * 0.5 + FRONT_CLEARANCE + FRAME_DEPTH * 0.5

	var glasses := Node3D.new()
	glasses.name = "Glasses"
	head.add_child(glasses)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var eye_centers: Array[float] = [left_eye.x, right_eye.x]
	for eye_x in eye_centers:
		var rim := MeshInstance3D.new()
		rim.mesh = _build_rim_mesh(rim_half_width, rim_half_height, FRAME_THICKNESS, FRAME_DEPTH)
		rim.position = Vector3(eye_x, 0.0, frame_z)
		rim.set_surface_override_material(0, material)
		glasses.add_child(rim)

	var left_inner_x := left_eye.x + rim_half_width - FRAME_THICKNESS * 0.35
	var right_inner_x := right_eye.x - rim_half_width + FRAME_THICKNESS * 0.35
	var bridge := MeshInstance3D.new()
	bridge.name = "GlassesBridge"
	bridge.mesh = _build_bridge_mesh(
		left_inner_x, right_inner_x, rim_half_height * 0.12,
		BRIDGE_ARCH_HEIGHT, FRAME_THICKNESS, FRAME_DEPTH
	)
	bridge.position = Vector3(0.0, 0.0, frame_z)
	bridge.set_surface_override_material(0, material)
	glasses.add_child(bridge)


static func _superellipse_point(half_width: float, half_height: float, angle: float) -> Vector2:
	var cosine := cos(angle)
	var sine := sin(angle)
	return Vector2(
		half_width * signf(cosine) * pow(absf(cosine), 2.0 / SHAPE_EPSILON),
		half_height * signf(sine) * pow(absf(sine), 2.0 / SHAPE_EPSILON)
	)


static func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(d)


static func _build_rim_mesh(
	half_width: float, half_height: float, thickness: float, depth: float
) -> ArrayMesh:
	var inner_half_width := maxf(half_width - thickness, thickness)
	var inner_half_height := maxf(half_height - thickness, thickness)
	var front_z := depth * 0.5
	var back_z := -depth * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in SEGMENTS:
		var angle_a := TAU * float(i) / float(SEGMENTS)
		var angle_b := TAU * float(i + 1) / float(SEGMENTS)
		var outer_a := _superellipse_point(half_width, half_height, angle_a)
		var outer_b := _superellipse_point(half_width, half_height, angle_b)
		var inner_a := _superellipse_point(inner_half_width, inner_half_height, angle_a)
		var inner_b := _superellipse_point(inner_half_width, inner_half_height, angle_b)
		var outer_a_front := Vector3(outer_a.x, outer_a.y, front_z)
		var outer_b_front := Vector3(outer_b.x, outer_b.y, front_z)
		var inner_a_front := Vector3(inner_a.x, inner_a.y, front_z)
		var inner_b_front := Vector3(inner_b.x, inner_b.y, front_z)
		var outer_a_back := Vector3(outer_a.x, outer_a.y, back_z)
		var outer_b_back := Vector3(outer_b.x, outer_b.y, back_z)
		var inner_a_back := Vector3(inner_a.x, inner_a.y, back_z)
		var inner_b_back := Vector3(inner_b.x, inner_b.y, back_z)

		# Front/back annuli plus the outer and inner walls make a closed frame,
		# while the center remains genuinely empty (there is no lens surface).
		_add_quad(st, outer_a_front, outer_b_front, inner_b_front, inner_a_front)
		_add_quad(st, outer_b_back, outer_a_back, inner_a_back, inner_b_back)
		_add_quad(st, outer_b_front, outer_a_front, outer_a_back, outer_b_back)
		_add_quad(st, inner_a_front, inner_b_front, inner_b_back, inner_a_back)

	st.generate_normals()
	return st.commit()


## Builds a shallow upward arch between the rims. The bridge is a closed,
## extruded ribbon rather than a scaled straight primitive, so its one-
## centimetre face-on stroke remains consistent all the way around the bend.
static func _build_bridge_mesh(
	left_x: float, right_x: float, endpoint_y: float, arch_height: float,
	thickness: float, depth: float
) -> ArrayMesh:
	var center_x := (left_x + right_x) * 0.5
	var half_span := (right_x - left_x) * 0.5
	var upper: Array[Vector2] = []
	var lower: Array[Vector2] = []
	for i in range(BRIDGE_SEGMENTS + 1):
		var u := float(i) / float(BRIDGE_SEGMENTS) * 2.0 - 1.0
		var center := Vector2(
			center_x + half_span * u,
			endpoint_y + arch_height * (1.0 - u * u)
		)
		var slope := -2.0 * arch_height * u / half_span
		var tangent := Vector2(1.0, slope).normalized()
		var normal := Vector2(-tangent.y, tangent.x)
		upper.append(center + normal * thickness * 0.5)
		lower.append(center - normal * thickness * 0.5)

	var front_z := depth * 0.5
	var back_z := -depth * 0.5
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in BRIDGE_SEGMENTS:
		var upper_a_front := Vector3(upper[i].x, upper[i].y, front_z)
		var upper_b_front := Vector3(upper[i + 1].x, upper[i + 1].y, front_z)
		var lower_a_front := Vector3(lower[i].x, lower[i].y, front_z)
		var lower_b_front := Vector3(lower[i + 1].x, lower[i + 1].y, front_z)
		var upper_a_back := Vector3(upper[i].x, upper[i].y, back_z)
		var upper_b_back := Vector3(upper[i + 1].x, upper[i + 1].y, back_z)
		var lower_a_back := Vector3(lower[i].x, lower[i].y, back_z)
		var lower_b_back := Vector3(lower[i + 1].x, lower[i + 1].y, back_z)
		_add_quad(st, upper_a_front, upper_b_front, lower_b_front, lower_a_front)
		_add_quad(st, upper_b_back, upper_a_back, lower_a_back, lower_b_back)
		_add_quad(st, upper_a_back, upper_b_back, upper_b_front, upper_a_front)
		_add_quad(st, lower_a_front, lower_b_front, lower_b_back, lower_a_back)

	# Close the two exposed ends where the bridge overlaps the rims.
	var last := BRIDGE_SEGMENTS
	_add_quad(
		st,
		Vector3(upper[0].x, upper[0].y, front_z), Vector3(lower[0].x, lower[0].y, front_z),
		Vector3(lower[0].x, lower[0].y, back_z), Vector3(upper[0].x, upper[0].y, back_z)
	)
	_add_quad(
		st,
		Vector3(lower[last].x, lower[last].y, front_z), Vector3(upper[last].x, upper[last].y, front_z),
		Vector3(upper[last].x, upper[last].y, back_z), Vector3(lower[last].x, lower[last].y, back_z)
	)
	st.generate_normals()
	return st.commit()
