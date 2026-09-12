class_name AquaticTail
extends RefCounted

## Shared articulated dark-blue tail used by peaceful merfolk and Fish
## Goblins. It replaces visible legs while leaving the hidden humanoid leg
## pivots available to existing combat code.

const DEFAULT_TAIL_COLOR := Color(0.08, 0.30, 0.48)


static func add_to_hips(
	hips: MeshInstance3D, _scale_factor: float = 1.0,
	tail_color: Color = DEFAULT_TAIL_COLOR
) -> Array[Node3D]:
	var pivots: Array[Node3D] = []
	# The humanoid pelvis is not part of an aquatic silhouette. Start the tail
	# at the pelvis's top seam (the abdomen's bottom) as a sibling, so hiding
	# the hip mesh does not also hide its replacement.
	var rig := hips.get_parent() as Node3D
	var hip_bounds := hips.get_aabb()
	var torso_join_y := hips.position.y + hip_bounds.position.y + hip_bounds.size.y
	hips.visible = false
	var parent: Node3D = rig
	var half_lengths: Array[float] = [0.18, 0.165, 0.14, 0.12]
	var hip_half_width := hip_bounds.size.x * 0.48
	var hip_half_depth := hip_bounds.size.z * 0.48
	for index in half_lengths.size():
		var pivot := Node3D.new()
		pivot.name = "MerTailPivot%02d" % index
		pivot.position = (
			Vector3(0.0, torso_join_y, hips.position.z)
			if index == 0
			else Vector3(0.0, -float(half_lengths[index - 1]) * 1.88, 0.0)
		)
		parent.add_child(pivot)
		var progress := float(index) / float(half_lengths.size() - 1)
		var width := lerpf(hip_half_width, 0.075, progress)
		var depth := lerpf(hip_half_depth, 0.052, progress)
		var top_epsilon := SuperEgg.EPSILON_FLAT if index == 0 else 2.7
		var segment := SuperEgg.build_part(Vector3(width, half_lengths[index], depth), tail_color, top_epsilon, 2.7)
		segment.position = Vector3(0.0, -float(half_lengths[index]), 0.0)
		pivot.add_child(segment)
		pivots.append(pivot)
		parent = pivot
	var fluke_pivot := Node3D.new()
	fluke_pivot.name = "TailFlukePivot"
	fluke_pivot.position = Vector3(0.0, -half_lengths[-1] * 1.88, 0.0)
	parent.add_child(fluke_pivot)
	for side: float in [-1.0, 1.0]:
		# The fin spreads sideways and downward in the body's X/Y plane. Its
		# thin dimension is front-to-back, rather than being flattened flat to
		# the ground like the previous X/Z-oriented paddles.
		var fluke := SuperEgg.build_part(Vector3(0.17, 0.10, 0.03), tail_color, 2.2, SuperEgg.EPSILON_FLAT)
		fluke.position = Vector3(side * 0.12, -0.10, 0.0)
		fluke.rotation.z = -side * deg_to_rad(26.0)
		fluke_pivot.add_child(fluke)
	pivots.append(fluke_pivot)
	return pivots


static func animate(pivots: Array[Node3D], phase: float, strength: float = 1.0) -> void:
	for index in pivots.size():
		var travel := phase - float(index) * 0.62
		pivots[index].rotation.x = sin(travel) * deg_to_rad(16.0) * strength
		pivots[index].rotation.z = sin(travel * 0.55) * deg_to_rad(4.0) * strength
