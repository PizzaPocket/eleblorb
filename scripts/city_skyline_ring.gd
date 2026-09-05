@tool
extends Node3D

## Perimeter backdrop for the city kingdom -- fills the same role as
## distant_mountains.gd (a cheap, non-collidable silhouette ringing the
## playable area well past its edge) but shaped like an endless skyscraper
## skyline instead of a mountain ridge, per direct instruction, to match the
## city kingdom's own architecture language. Discrete boxes rather than a
## continuous height-field ring, since a skyline silhouette actually reads as
## separate towers, not one unbroken ridge.

const RADIUS := 950.0  # matches distant_mountains.gd's own ring radius, so the skyline sits at the same playable-area boundary
const BUILDING_COUNT := 520
const MIN_HEIGHT := 45.0
const MAX_HEIGHT := 230.0
const MIN_FOOTPRINT := 10.0
const MAX_FOOTPRINT := 26.0
## Sinks every tower's base this far below y=0 so none show a gap under
## their footing when viewed from ground level closer to the grid's own
## flat 0.0 ground.
const BASE_SINK := 8.0

var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 20260823
	for c in get_children():
		c.free()
	_build()


func _build() -> void:
	for i in BUILDING_COUNT:
		var angle := (float(i) / BUILDING_COUNT) * TAU + _rng.randf_range(-0.02, 0.02)
		var height := _rng.randf_range(MIN_HEIGHT, MAX_HEIGHT)
		var width := _rng.randf_range(MIN_FOOTPRINT, MAX_FOOTPRINT)
		var depth := _rng.randf_range(MIN_FOOTPRINT, MAX_FOOTPRINT)
		var radius := RADIUS + _rng.randf_range(-80.0, 160.0)

		var mesh_instance := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(width, height, depth)
		mesh_instance.mesh = box
		var shade := _rng.randf_range(0.22, 0.5)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(shade * 0.82, shade * 0.86, shade * 0.98)
		material.roughness = 0.85
		mesh_instance.material_override = material
		# No collision -- nothing out here is reachable, same reasoning
		# distant_mountains.gd's own doc comment gives for its ring.
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mesh_instance.position = Vector3(
			cos(angle) * radius, height * 0.5 - BASE_SINK, sin(angle) * radius
		)
		add_child(mesh_instance)
