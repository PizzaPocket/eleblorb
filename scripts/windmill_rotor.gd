class_name WindmillRotor
extends Node3D

## Slow, continuous working rotation for the village grain mill. Kept on the
## rotor assembly itself so TownProps can reuse the complete mill anywhere.
@export var turns_per_minute:=8.0

## Parts downstream of the windshaft are kept outside this node because they
## stand on the mill floors rather than rotating with the sails.  Registering
## them here keeps the entire power train on one clock: stopping the sails also
## stops the wallower, upright shaft and runner stone.
var _driven_parts: Array[Dictionary] = []


func add_driven_part(part: Node3D, axis: Vector3, ratio: float) -> void:
	_driven_parts.append({"part": part, "axis": axis.normalized(), "ratio": ratio})


func _process(delta: float) -> void:
	var step := TAU * (turns_per_minute / 60.0) * delta
	rotation.z += step
	for record in _driven_parts:
		var part: Node3D = record["part"]
		var axis: Vector3 = record["axis"]
		if is_instance_valid(part):
			part.rotate_object_local(axis, step * float(record["ratio"]))
