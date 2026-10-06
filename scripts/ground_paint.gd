class_name GroundPaint
extends RefCounted

## Paths, yards and worn ground painted INTO the terrain rather than laid over
## it as geometry. The terrain's own vertex grid is ~8 m, far too coarse to
## carry a 3 m lane, so the paint is a single rasterised texture projected
## down onto the terrain mesh by a Decal. The decal only affects meshes that
## carry PAINT_LAYER (see mark_terrain), so houses, roofs and props standing in
## the box are never tinted, and the paint follows every terrain bump with no
## z-fighting and no collision of its own.
##
## Strokes and blobs are described in WORLD XZ coordinates:
##   stroke: {"points": Array[Vector2], "width": float}
##   blob:   {"center": Vector2, "radii": Vector2, "rotation": float (optional)}

## Visual-instance layer bit (layer 20) used only to opt the terrain in.
const PAINT_LAYER := 1 << 19
## Light, sun-baked earth. The terrain's metallic shading cools and darkens
## whatever sits on it, so the paint is authored brighter than it should read.
const DIRT := Color(0.80, 0.66, 0.44)
const DIRT_PALE := Color(0.92, 0.80, 0.58)
const PIXELS_PER_METER := 4.0
const EDGE_SOFTNESS := 0.55
const MARGIN := 4.0
## Vertical reach of the projection, centred on `ground_y`. Generous so hilly
## terrain stays inside the box; only PAINT_LAYER meshes are ever painted.
const PROJECTION_HEIGHT := 90.0


## Opts a terrain mesh in to receiving paint. Call on the ground MeshInstance3D.
static func mark_terrain(mesh: MeshInstance3D) -> void:
	mesh.layers |= PAINT_LAYER


## Smooths a hand-authored waypoint list into an evenly spaced, gently curving
## polyline (Catmull-Rom). Returned points are in the same space as the input.
static func smooth(points: Array[Vector2], spacing: float = 2.4) -> Array[Vector2]:
	var samples: Array[Vector2] = []
	var last := points.size() - 1
	for i in last:
		var before: Vector2 = points[maxi(i - 1, 0)]
		var from: Vector2 = points[i]
		var to: Vector2 = points[i + 1]
		var after: Vector2 = points[mini(i + 2, last)]
		var steps := maxi(int(from.distance_to(to) / spacing), 1)
		for step in steps:
			samples.append(from.cubic_interpolate(to, before, after, float(step) / float(steps)))
	samples.append(points[last])
	return samples


static func paint(
	parent: Node3D, strokes: Array, blobs: Array, ground_y: float,
	node_name: String = "GroundPaint", base: Color = DIRT, pale: Color = DIRT_PALE,
	opacity: float = 0.94, seed_value: int = 7, surface_filter: Callable = Callable()
) -> Decal:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for stroke in strokes:
		var half := float(stroke["width"]) * 0.5 + MARGIN
		for point: Vector2 in stroke["points"]:
			lo = lo.min(point - Vector2(half, half))
			hi = hi.max(point + Vector2(half, half))
	for blob in blobs:
		var reach := maxf((blob["radii"] as Vector2).x, (blob["radii"] as Vector2).y) * 1.3 + MARGIN
		var c: Vector2 = blob["center"]
		lo = lo.min(c - Vector2(reach, reach))
		hi = hi.max(c + Vector2(reach, reach))
	var size := hi - lo
	var width_px := ceili(size.x * PIXELS_PER_METER)
	var height_px := ceili(size.y * PIXELS_PER_METER)

	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.35
	var mottle := FastNoiseLite.new()
	mottle.seed = seed_value + 91
	mottle.frequency = 1.6

	var mask := PackedFloat32Array()
	mask.resize(width_px * height_px)
	for stroke in strokes:
		_rasterise_stroke(mask, width_px, height_px, lo, stroke["points"], float(stroke["width"]), noise)
	for blob in blobs:
		_rasterise_blob(mask, width_px, height_px, lo, blob, noise)

	var image := Image.create(width_px, height_px, false, Image.FORMAT_RGBA8)
	image.fill(Color(base.r, base.g, base.b, 0.0))
	for y in height_px:
		for x in width_px:
			var coverage := mask[y * width_px + x]
			if coverage <= 0.004:
				continue
			var world := lo + Vector2(float(x) + 0.5, float(y) + 0.5) / PIXELS_PER_METER
			# A projected decal otherwise also paints any cliff face that happens
			# to pass through its tall projection box. Callers near a precipice
			# can fade paint off non-walkable slopes while retaining one shared
			# raster texture and the terrain-following benefits of a decal.
			if surface_filter.is_valid():
				coverage *= clampf(float(surface_filter.call(world)), 0.0, 1.0)
				if coverage <= 0.004:
					continue
			var tone := clampf(0.5 + mottle.get_noise_2d(world.x, world.y) * 0.9, 0.0, 1.0)
			var color := base.lerp(pale, tone)
			image.set_pixel(x, y, Color(color.r, color.g, color.b, coverage * opacity))
	image.generate_mipmaps()

	var decal := Decal.new()
	decal.name = node_name
	decal.size = Vector3(size.x, PROJECTION_HEIGHT, size.y)
	decal.position = Vector3((lo.x + hi.x) * 0.5, ground_y, (lo.y + hi.y) * 0.5)
	decal.texture_albedo = ImageTexture.create_from_image(image)
	decal.cull_mask = PAINT_LAYER
	decal.upper_fade = 0.05
	decal.lower_fade = 0.05
	decal.distance_fade_enabled = false
	parent.add_child(decal)
	return decal


static func _rasterise_stroke(
	mask: PackedFloat32Array, width_px: int, height_px: int, lo: Vector2,
	points: Array, width: float, noise: FastNoiseLite
) -> void:
	var half := width * 0.5
	var reach := half * 1.3 + EDGE_SOFTNESS
	for i in points.size() - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var segment := b - a
		var length_squared := maxf(segment.length_squared(), 0.0001)
		var box_lo := ((a.min(b) - Vector2(reach, reach)) - lo) * PIXELS_PER_METER
		var box_hi := ((a.max(b) + Vector2(reach, reach)) - lo) * PIXELS_PER_METER
		for y in range(maxi(int(box_lo.y), 0), mini(int(box_hi.y) + 1, height_px)):
			for x in range(maxi(int(box_lo.x), 0), mini(int(box_hi.x) + 1, width_px)):
				var world := lo + Vector2(float(x) + 0.5, float(y) + 0.5) / PIXELS_PER_METER
				var along := clampf((world - a).dot(segment) / length_squared, 0.0, 1.0)
				var distance := world.distance_to(a + segment * along)
				# The edge wanders with the noise, so a lane reads as worn
				# ground rather than a ruled stripe.
				var edge := half * (1.0 + noise.get_noise_2d(world.x * 2.2, world.y * 2.2) * 0.34)
				var coverage := smoothstep(0.0, EDGE_SOFTNESS, edge - distance)
				var index := y * width_px + x
				if coverage > mask[index]:
					mask[index] = coverage


static func _rasterise_blob(
	mask: PackedFloat32Array, width_px: int, height_px: int, lo: Vector2,
	blob: Dictionary, noise: FastNoiseLite
) -> void:
	var center: Vector2 = blob["center"]
	var radii: Vector2 = blob["radii"]
	var rotation: float = blob.get("rotation", 0.0)
	var reach := maxf(radii.x, radii.y) * 1.4
	var box_lo := (center - Vector2(reach, reach) - lo) * PIXELS_PER_METER
	var box_hi := (center + Vector2(reach, reach) - lo) * PIXELS_PER_METER
	for y in range(maxi(int(box_lo.y), 0), mini(int(box_hi.y) + 1, height_px)):
		for x in range(maxi(int(box_lo.x), 0), mini(int(box_hi.x) + 1, width_px)):
			var world := lo + Vector2(float(x) + 0.5, float(y) + 0.5) / PIXELS_PER_METER
			var local := (world - center).rotated(-rotation)
			var radial := Vector2(local.x / radii.x, local.y / radii.y).length()
			radial *= 1.0 + noise.get_noise_2d(world.x * 0.5, world.y * 0.5) * 0.16
			var coverage := smoothstep(1.0, 0.82, radial)
			var index := y * width_px + x
			if coverage > mask[index]:
				mask[index] = coverage
