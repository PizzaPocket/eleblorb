extends Node3D
class_name CloudScatter

## Scatters simple low-poly cloud puffs (clusters of overlapping SuperEggs,
## unshaded so lighting doesn't darken them) high above the field. No cloud
## assets exist in either Kenney kit, so these are built procedurally.
## Puffs use the same SuperEgg primitive the character rig is built from
## (per direct instruction), squashed wider than they are tall (PUFF_
## HEIGHT_FACTOR) rather than the plain spheres used before -- a real
## cumulus puff reads as a flattened, horizontally-spread blob, not a ball.
##
## Puffs are unshaded, so day_night_cycle.gd's sun/sky changes never touch
## them on their own -- they'd stay pure white at midnight otherwise.
## set_night_factor() below is how day_night_cycle.gd tints the single
## shared puff material toward a dim moonlit grey-blue instead.

## Dense enough to form a real aerial platforming field rather than a few
## distant sky decorations; seeded generation keeps the route repeatable.
@export var cloud_count: int = 52
@export var altitude_min: float = 70.0
@export var altitude_max: float = 110.0
@export var spread: float = 260.0
@export var rng_seed: int = 77

## How tall a puff is relative to its own horizontal radius -- below 1.0,
## since puffs should read as wider than they are tall.
const PUFF_HEIGHT_FACTOR := 0.6

const DAY_COLOR := Color(1, 1, 1)
const NIGHT_COLOR := Color(0.22, 0.25, 0.38)

var _rng := RandomNumberGenerator.new()
var _material: StandardMaterial3D


func _ready() -> void:
	_rng.seed = rng_seed
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(1, 1, 1)
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	for i in cloud_count:
		_place_cloud()


func _place_cloud() -> void:
	var cloud := Node3D.new()
	cloud.position = Vector3(
		_rng.randf_range(-spread, spread),
		_rng.randf_range(altitude_min, altitude_max),
		_rng.randf_range(-spread, spread)
	)
	add_child(cloud)

	var puff_count := int(_rng.randf_range(4, 8))
	for i in puff_count:
		var puff_radius := _rng.randf_range(3.0, 7.0)
		var semi_axes := Vector3(puff_radius, puff_radius * PUFF_HEIGHT_FACTOR, puff_radius)
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = SuperEgg.build_mesh(semi_axes, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		mesh_instance.material_override = _material
		mesh_instance.set_meta("cloud_semi_axes", semi_axes)
		mesh_instance.position = Vector3(
			_rng.randf_range(-8.0, 8.0),
			_rng.randf_range(-1.5, 1.5),
			_rng.randf_range(-8.0, 8.0)
		)
		cloud.add_child(mesh_instance)


## Returns the highest visible puff top at this XZ position, provided that
## top is not above `max_surface_y`. Callers use that ceiling to make cloud
## support one-way: rising bodies pass through undersides, falling bodies
## approaching from above can settle on the top.
func get_support_height_at(world_x: float, world_z: float, max_surface_y: float = INF) -> Variant:
	var best: Variant = null
	for cloud in get_children():
		for puff_node in cloud.get_children():
			if not puff_node is MeshInstance3D or not puff_node.has_meta("cloud_semi_axes"):
				continue
			var puff := puff_node as MeshInstance3D
			var axes := puff.get_meta("cloud_semi_axes") as Vector3
			var center := puff.global_position
			# Match SuperEgg.EPSILON_SOFT's rounded-square horizontal profile.
			# The old ellipse approximation excluded the puff's real side/corner
			# volume, which made a character fall through visibly rendered cloud.
			var horizontal_profile := pow(absf((world_x - center.x) / axes.x), SuperEgg.EPSILON_SOFT) + pow(absf((world_z - center.z) / axes.z), SuperEgg.EPSILON_SOFT)
			if horizontal_profile > 1.0:
				continue
			var top := center.y + axes.y * pow(1.0 - horizontal_profile, 1.0 / SuperEgg.EPSILON_SOFT)
			if top <= max_surface_y and (best == null or top > best):
				best = top
	return best


## t: 0 (full day, white) .. 1 (full night, dim moonlit grey-blue).
func set_night_factor(t: float) -> void:
	if _material:
		_material.albedo_color = DAY_COLOR.lerp(NIGHT_COLOR, t)
