class_name FigureDress
extends RefCounted

## Reusable knee-covering dress for the canonical ProceduralFigure rig.
## The hips remain the garment color, while both articulated leg chains are
## built separately in skin color by the caller. The skirt is one superegg:
## circularly rounded at the waist/crown and deliberately flat at the hem.

const SKIRT_HALF_WIDTH := 0.23
const SKIRT_HALF_DEPTH := 0.17
const SKIRT_HALF_HEIGHT := 0.35
const HIP_TOP_OVERLAP := 0.07
const ROUND_CROWN_EPSILON := 2.0

# Horizontal half-diagonal of a canonical bare upper leg, plus a small visual
# margin. The skirt yaws relative to the legs during a stride, so using only
# one axis' half-width does not contain the corners of their rounded-square
# cross-section. _envelope_for_points() scales this with each figure's actual
# garment/body size (see its own garment_scale derivation), which is what
# makes the same constant work across every hip_build_scale/body type rather
# than needing a hand-tuned flare amount per preset.
const STRIDE_LEG_CLEARANCE := 0.082
const STRIDE_WIDTH_UTILIZATION := 0.82
const STRIDE_MIN_WIDTH_SCALE := 0.78


static func add_to_figure(
	_rig: Node3D,
	hips: MeshInstance3D,
	dress_color: Color,
	hip_build_scale: float = 1.0
) -> Dictionary:
	_recolor_hips(hips, dress_color)
	var skirt := SuperEgg.build_part(
		Vector3(
			SKIRT_HALF_WIDTH * hip_build_scale,
			SKIRT_HALF_HEIGHT,
			SKIRT_HALF_DEPTH * hip_build_scale
		),
		dress_color,
		ROUND_CROWN_EPSILON,
		SuperEgg.EPSILON_FLAT
	)
	skirt.name = "SupereggDressSkirt"
	# The upper hip shell and lower skirt shell are each fitted to the live
	# leg pose independently every frame (see stride_envelope()/
	# upper_skirt_envelope() below), by writing rotation.y/scale.x/scale.z
	# directly on `hips` and on `skirt`. Parenting the skirt straight to
	# `hips` would compound its own solved rotation/scale with whatever
	# `hips` was just set to, since a child inherits its parent's full
	# transform. This pivot exists purely to cancel that inherited transform
	# back out each frame (the caller sets pivot.basis = hips.basis.inverse()
	# right after fitting both shells), so the skirt's own local rotation/
	# scale always means exactly what it says, independent of the hip
	# shell's own fit.
	var pivot := Node3D.new()
	pivot.name = "DressHemPivot"
	hips.add_child(pivot)
	# Hips' origin is their center. This places the rounded crown slightly
	# above the hip center and the hem below the knee pivots, while parenting
	# the garment to the pelvis so a contrapposto hip drop carries the skirt.
	skirt.position = Vector3(0, HIP_TOP_OVERLAP - SKIRT_HALF_HEIGHT, 0)
	pivot.add_child(skirt)
	return {"skirt": skirt, "pivot": pivot}


static func _recolor_hips(hips: MeshInstance3D, dress_color: Color) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = dress_color
	material.roughness = 0.6
	hips.set_surface_override_material(0, material)


## Solve the smallest rotated lower-skirt envelope that contains both animated
## hip-to-knee endpoints. The skirt's equatorial section is an ellipse
## (ROUND_CROWN_EPSILON == 2), so depth is solved from
## (x / a)^2 + (z / b)^2 <= 1 after choosing a restrained width scale.
## Reading the live knee transforms makes the same calculation valid for walk
## and run gaits without separate hand-tuned flare amounts.
static func stride_envelope(
	skirt: MeshInstance3D,
	hips: Node3D,
	knee_left: Node3D,
	knee_right: Node3D
) -> Dictionary:
	# Measure in the rig's unscaled frame so fitting the skirt does not feed
	# its own previous frame's transform back into this solve.
	var rig := hips.get_parent() as Node3D
	var left_3d := rig.to_local(knee_left.global_position) - hips.position
	var right_3d := rig.to_local(knee_right.global_position) - hips.position
	return _envelope_for_points(skirt, [Vector2(left_3d.x, left_3d.z), Vector2(right_3d.x, right_3d.z)])


## Fit the dress-coloured hip shell at its lower edge. Each animated upper leg
## is treated as the line from its hip socket to its knee; intersecting that
## line with the shell's hem plane gives the exact two-point stride box at the
## height this segment actually has to cover.
static func upper_skirt_envelope(
	hips: MeshInstance3D,
	leg_left: Node3D,
	leg_right: Node3D,
	knee_left: Node3D,
	knee_right: Node3D
) -> Dictionary:
	var rig := hips.get_parent() as Node3D
	var hem_y := hips.position.y + hips.mesh.get_aabb().position.y
	var points: Array[Vector2] = []
	for pair in [[leg_left, knee_left], [leg_right, knee_right]]:
		var top := rig.to_local((pair[0] as Node3D).global_position)
		var knee := rig.to_local((pair[1] as Node3D).global_position)
		var denominator := knee.y - top.y
		var fraction := clampf((hem_y - top.y) / denominator, 0.0, 1.0) if absf(denominator) > 0.0001 else 0.0
		var sample := top.lerp(knee, fraction) - hips.position
		points.append(Vector2(sample.x, sample.z))
	return _envelope_for_points(hips, points)


static func _envelope_for_points(part: MeshInstance3D, points: Array[Vector2]) -> Dictionary:
	var left := points[0]
	var right := points[1]
	var leading := left if left.y >= right.y else right
	# Local +Z is the garment front. Aim it directly at the leading corner of
	# the two-leg stride box rather than approximating that diagonal by phase.
	# If neither leg actually leads, there is no diagonal: choosing the left or
	# right point merely because of a tie rolls the skirt sideways during the
	# figure's initial settling drop before it has moved.
	var yaw := 0.0 if absf(left.y - right.y) < 0.01 else atan2(leading.x, leading.y)
	var inverse_yaw := -yaw
	var rotated_points: Array[Vector2] = []
	for point in [left, right]:
		var rotated := Vector3(point.x, 0.0, point.y).rotated(Vector3.UP, inverse_yaw)
		rotated_points.append(Vector2(rotated.x, rotated.z))

	var bounds := part.mesh.get_aabb()
	var half_width := maxf(bounds.size.x * 0.5, 0.001)
	var half_depth := maxf(bounds.size.z * 0.5, 0.001)
	# Dress geometry and bare-leg thickness both follow hip build scale. Infer
	# that per-figure scale from the actual mesh rather than accepting another
	# appearance parameter that could drift out of sync. Taking the larger axis
	# also remains conservative if a future body preset varies X and Z apart.
	var garment_scale := maxf(half_width / SKIRT_HALF_WIDTH, half_depth / SKIRT_HALF_DEPTH)
	var leg_clearance := STRIDE_LEG_CLEARANCE * garment_scale
	var required_x := 0.0
	for point in rotated_points:
		required_x = maxf(required_x, absf(point.x) + leg_clearance)
	# Leave some width headroom so the elliptical corner still has depth
	# available; fitting X exactly to its axis would mathematically force Z
	# toward infinity at that point.
	var width_scale := maxf(STRIDE_MIN_WIDTH_SCALE, required_x / (half_width * STRIDE_WIDTH_UTILIZATION))
	var depth_scale := 1.0
	for point in rotated_points:
		var x_ratio := clampf((absf(point.x) + leg_clearance) / (half_width * width_scale), 0.0, 0.98)
		var available_z_fraction := sqrt(maxf(1.0 - x_ratio * x_ratio, 0.04))
		var required_depth := (absf(point.y) + leg_clearance) / (half_depth * available_z_fraction)
		depth_scale = maxf(depth_scale, required_depth)
	return {"yaw": yaw, "scale_x": width_scale, "scale_z": depth_scale}
