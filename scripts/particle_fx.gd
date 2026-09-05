class_name ParticleFX
extends RefCounted

## Shared soft-particle billboard sprite + color-ramp/scale-curve helpers
## for this project's GPUParticles3D elemental streams (player.gd's water/
## fire hand and foot jets, blorb.gd's own combat stream). Per direct
## report ("the flamethrowers... look like orange bubbles... make the
## flames better quality... also make the water gun look more like
## water"): the previous streams drew each particle as a literal SphereMesh
## with one flat, uniform albedo/emission color -- a small solid-colored
## ball, which is exactly why it read as a "bubble" rather than a flame or
## a droplet of water. Standard real-time VFX practice instead renders each
## particle as a camera-facing billboarded quad carrying a soft radial-
## falloff sprite (bright/opaque center fading smoothly to fully
## transparent at the edge, built here since this project has no external
## texture assets to load), combined with a color gradient across each
## particle's own lifetime (fire cools from hot pale-yellow through orange
## to a dying red as it ages) and, for fire specifically, additive
## blending so overlapping flame particles build up glowing brightness
## instead of just occluding each other like solid objects would.


## A small radial-gradient sprite: opaque/bright at the center, smoothly
## fading to fully transparent at the edge. `softness` controls how
## gradual that falloff is (higher = a softer, rounder glow; lower = a
## harder-edged disc). `wobble` (0.0-1.0) optionally perturbs the edge
## with a couple of overlapping sine lobes so the silhouette reads as an
## irregular blob/flame lick rather than a perfect circle -- combined with
## per-particle random rotation (each caller's own ParticleProcessMaterial.
## angle_min/angle_max), reusing this one texture across many particles
## still reads as organic rather than visibly repeating the same shape.
static func build_soft_gradient_texture(size: int = 32, softness: float = 1.6, wobble: float = 0.0) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := float(size) * 0.5
	for y in size:
		for x in size:
			var dx := (float(x) + 0.5 - center) / center
			var dy := (float(y) + 0.5 - center) / center
			var radius_scale := 1.0
			if wobble > 0.0:
				var angle := atan2(dy, dx)
				radius_scale = 1.0 + wobble * (sin(angle * 3.0) * 0.5 + sin(angle * 5.0 + 1.7) * 0.3)
			var dist := sqrt(dx * dx + dy * dy) / radius_scale
			var alpha := clampf(1.0 - dist, 0.0, 1.0)
			alpha = pow(alpha, softness)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


## A GradientTexture1D suitable for ParticleProcessMaterial.color_ramp --
## `stops` is an Array of {"offset": float 0-1, "color": Color} in
## ascending offset order. Deliberately untyped (not Array[Dictionary]) so
## every call site can just pass an array literal directly rather than
## needing an intermediate typed variable first.
static func build_color_ramp(stops: Array) -> GradientTexture1D:
	var gradient := Gradient.new()
	# Gradient.new() ships with two default points (offsets 0.0/1.0) that
	# would otherwise blend in ahead of/behind the real stops.
	gradient.offsets = PackedFloat32Array()
	gradient.colors = PackedColorArray()
	for stop in stops:
		gradient.add_point(stop["offset"] as float, stop["color"] as Color)
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture


## A CurveTexture suitable for ParticleProcessMaterial.scale_curve -- rises
## from `start` to `peak` over `peak_fraction` of the lifetime (a flame/
## droplet visibly forming), then eases back down to `finish` (dissipating)
## over the remainder. All three are multipliers on top of the process
## material's own scale_min/scale_max range, matching Godot's own
## convention for this curve.
static func build_scale_curve(start: float, peak: float, peak_fraction: float, finish: float) -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, start))
	curve.add_point(Vector2(peak_fraction, peak))
	curve.add_point(Vector2(1.0, finish))
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


## Builds the shared StandardMaterial3D every soft-particle billboard here
## uses -- a PrimitiveMesh's own `.material`, not a per-MeshInstance3D
## override, since GPUParticles3D draws every particle from one shared mesh
## resource. `additive`: fire wants overlapping particles to build up
## bright glow (BLEND_MODE_ADD); water stays ordinary alpha blending so it
## reads as translucent rather than glowing.
static func build_billboard_material(texture: ImageTexture, tint: Color, additive: bool, emission_energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MIX
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = emission_energy
	return material
