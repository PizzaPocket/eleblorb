class_name TerrainWindow
extends RefCounted

## Shows a region of another world's terrain inside this one: the demo world's
## biomes are windows onto the real kingdoms, so their ground shape and colour
## are those kingdoms' own, not an imitation.
##
## `sampler` is a kingdom terrain instance that is never added to a tree (so
## it never builds its mesh); it answers sample_height()/sample_color() (see
## the kingdom terrains' _init()). A target point p maps to a source point
##     q = source_center + ((p - target_center) * scale).rotated(rotation)
## so `scale` > 1 shrinks a large landform into a smaller area (heights shrink
## by the same factor, keeping every slope the same) and `rotation` turns the
## source so a feature (a ski run) lines up with the target's layout.
##
## weight() is 1 inside the window and eases to 0 across `blend` at its edge
## (a rectangle of `half_size`, or a circle of `radius` when that is set), so
## callers blend the window into their own surrounding ground.

var sampler: Object
var source_center := Vector2.ZERO
var target_center := Vector2.ZERO
var scale := 1.0
var rotation := 0.0
var half_size := Vector2.ZERO
var radius := 0.0
var blend := 30.0
## Source height that maps to target height 0, so the window sits level with
## the ground around it.
var height_offset := 0.0


func _init(
	window_sampler: Object, window_source_center: Vector2, window_target_center: Vector2,
	window_half_size: Vector2, window_radius: float = 0.0, window_scale: float = 1.0,
	window_rotation: float = 0.0, window_blend: float = 30.0
) -> void:
	sampler = window_sampler
	source_center = window_source_center
	target_center = window_target_center
	half_size = window_half_size
	radius = window_radius
	scale = window_scale
	rotation = window_rotation
	blend = window_blend


## Sets height_offset to the mean source height around the window's edge, so
## the edge averages to target height 0 and blends into level surroundings
## rather than stepping up or down to meet them.
func level_to_edge() -> void:
	var total := 0.0
	const SAMPLES := 32
	for index in SAMPLES:
		var angle := TAU * float(index) / float(SAMPLES)
		var direction := Vector2(cos(angle), sin(angle))
		var edge: Vector2
		if radius > 0.0:
			edge = target_center + direction * radius
		else:
			# Where this direction leaves the rectangle.
			var reach := minf(
				half_size.x / maxf(absf(direction.x), 0.0001),
				half_size.y / maxf(absf(direction.y), 0.0001)
			)
			edge = target_center + direction * reach
		var q := to_source(edge)
		total += float(sampler.sample_height(q.x, q.y))
	height_offset = total / float(SAMPLES)


func to_source(target: Vector2) -> Vector2:
	return source_center + ((target - target_center) * scale).rotated(rotation)


func to_target(source: Vector2) -> Vector2:
	return target_center + (source - source_center).rotated(-rotation) / scale


func weight(target: Vector2) -> float:
	var local := target - target_center
	if radius > 0.0:
		return 1.0 - smoothstep(radius - blend, radius, local.length())
	var across_x := 1.0 - smoothstep(half_size.x - blend, half_size.x, absf(local.x))
	var across_z := 1.0 - smoothstep(half_size.y - blend, half_size.y, absf(local.y))
	return across_x * across_z


func contains(target: Vector2) -> bool:
	return weight(target) > 0.0


func height(target: Vector2) -> float:
	var q := to_source(target)
	return (float(sampler.sample_height(q.x, q.y)) - height_offset) / scale


func color(target: Vector2) -> Color:
	var q := to_source(target)
	return sampler.sample_color(q.x, q.y)
