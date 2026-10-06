class_name PlayableArmPose
extends RefCounted

## Shared final animation layer for the ordinary one-arm power gesture.
##
## The human and MonkeyFigure rigs deliberately use the same shoulder/elbow
## axis convention, but they used to apply this target with different kinds of
## interpolation.  The monkey's partial per-frame lerp fought its locomotion
## layer and could never reach the requested horizontal arm.  Keeping the
## chain target here makes "raise the arm" mean the same thing for every
## compatible playable rig while leaving each rig free to solve its own hand
## orientation afterward.
static func apply_forward_raise(
	shoulder: Node3D, elbow: Node3D, side: float, blend: float,
	outward_angle: float, forward_angle: float
) -> void:
	if shoulder == null or elbow == null:
		return
	var weight := clampf(blend, 0.0, 1.0)
	shoulder.rotation.x = lerp_angle(shoulder.rotation.x, -forward_angle, weight)
	shoulder.rotation.y = lerp_angle(shoulder.rotation.y, 0.0, weight)
	shoulder.rotation.z = lerp_angle(shoulder.rotation.z, side * outward_angle, weight)
	elbow.rotation.x = lerp_angle(elbow.rotation.x, 0.0, weight)
	elbow.rotation.y = lerp_angle(elbow.rotation.y, 0.0, weight)
	elbow.rotation.z = lerp_angle(elbow.rotation.z, 0.0, weight)
