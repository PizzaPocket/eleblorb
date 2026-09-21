class_name AtmosphereLayer
extends Node

## Reusable altitude model for worlds that extend into space. Visuals sample
## the camera; gameplay samples the controlled body. A pressurized volume can
## override vacuum locally without changing altitude or gravity.

# The upper atmosphere begins well above all ordinary flight gameplay. The
# rescue portal remains roughly one Air-suit breath window above this point.
@export var thin_air_y := 500.0
@export var space_y := 810.0


func _ready() -> void:
	add_to_group("atmosphere_layer")


func altitude_factor(y: float) -> float:
	return smoothstep(thin_air_y, space_y, y)


func gravity_factor_at(point: Vector3) -> float:
	if is_pressurized_at(point):
		return 1.0
	return 1.0 - altitude_factor(point.y)


func sky_darkening_at(point: Vector3) -> float:
	return altitude_factor(point.y)


func is_vacuum_at(point: Vector3) -> bool:
	return point.y >= thin_air_y and not is_pressurized_at(point)


func airlessness_at(point: Vector3) -> float:
	if is_pressurized_at(point):
		return 0.0
	return altitude_factor(point.y)


func is_pressurized_at(point: Vector3) -> bool:
	for candidate in get_tree().get_nodes_in_group("pressurized_volumes"):
		if is_instance_valid(candidate) and candidate.has_method("contains_breathable_point"):
			if bool(candidate.contains_breathable_point(point)):
				return true
	return false


static func active(tree: SceneTree) -> AtmosphereLayer:
	return tree.get_first_node_in_group("atmosphere_layer") as AtmosphereLayer
