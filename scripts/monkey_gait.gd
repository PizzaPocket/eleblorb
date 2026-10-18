class_name MonkeyGait
extends RefCounted

## One gait for the companion and procedural villagers. All offsets are
## relative to the resolved rig's rest pose, so a tall, stooping villager
## keeps its shoulder counter-rotation and a compact toy keeps its shape.
## Signs and phase relationships match the human's confirmed walk cycle.
static func pose(pivots: Dictionary, phase: float, moving: bool, delta: float, swing_amount: float, settle_speed: float) -> void:
	var rest: Dictionary = pivots["_rest_rotations"]
	var blend := minf(delta * settle_speed, 1.0)
	var swing := sin(phase) * swing_amount if moving else 0.0
	for side in ["left", "right"]:
		var left: bool = side == "left"
		var leg_swing := swing if left else -swing
		var knee := maxf(0.0, cos(phase + (PI if left else 0.0))) * ProceduralFigure.KNEE_BEND_AMOUNT if moving else 0.0
		# Forward-most arm gets the deepest bend, just like the human.
		var forward_fraction := (1.0 + sin(phase) * (1.0 if left else -1.0)) * 0.5
		var elbow := -forward_fraction * ProceduralFigure.ELBOW_BEND_AMOUNT if moving else 0.0
		var offsets := {
			"leg_" + side: Vector3(leg_swing, 0.0, 0.0),
			"knee_" + side: Vector3(knee, 0.0, 0.0),
			"ankle_" + side: Vector3(-knee * 0.45, 0.0, 0.0),
			"arm_" + side: Vector3(-leg_swing, 0.0, 0.0),
			"elbow_" + side: Vector3(elbow, 0.0, 0.0),
			"hand_" + side: Vector3.ZERO,
		}
		for name: String in offsets:
			var node := pivots[name] as Node3D
			var target: Vector3 = (rest[name] as Vector3) + (offsets[name] as Vector3)
			# Set the moving shoulder/hip swing exactly; idle and all secondary
			# joints ease out of whatever traversal pose owned the previous frame.
			if moving and (name.begins_with("arm_") or name.begins_with("leg_")):
				node.rotation = target
			else:
				node.rotation = node.rotation.lerp(target, blend)
	for name in ["spine", "thorax", "neck", "head"]:
		var node := pivots[name] as Node3D
		if name == "head":
			# Gaze owns yaw; locomotion restores only the inherited pitch.
			node.rotation.x = lerp_angle(node.rotation.x, (rest[name] as Vector3).x, blend)
		else:
			node.rotation = node.rotation.lerp(rest[name] as Vector3, blend)
