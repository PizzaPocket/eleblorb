class_name ChimneySmoke
extends RefCounted

## Small drifting puffs rising and shrinking out of a chimney top -- the same
## unshaded SuperEgg-puff technique CloudScatter's own ambient clouds use,
## just grayish instead of white, non-collidable, and individually animated
## (not GPUParticles3D) so each puff can grow then dissipate to nothing as it
## rises, matching real chimney smoke rather than a generic particle burst.
## Per direct instruction: "gently floating up super eggs... modeled on
## something similar to the clouds except a little bit more grayish color...
## move up and shrink in size until disappearing... figure out some way to
## make it procedural so that it's just kind of a random pattern."

const SMOKE_COLOR := Color(0.58, 0.58, 0.62)
const RISE_HEIGHT := 1.5
const DRIFT_RANGE := 0.35
const LIFETIME_MIN := 2.4
const LIFETIME_MAX := 3.8
const RADIUS_MIN := 0.09
const RADIUS_MAX := 0.16


class Puff:
	var mesh: MeshInstance3D
	var origin: Vector3
	var age: float
	var lifetime: float
	var drift: Vector2


## Spawns `count` puffs as children of `parent`, each already mid-cycle at a
## random age so a freshly-built chimney doesn't visibly "start cold" with
## every puff popping in at the same instant.
static func spawn(parent: Node3D, local_pos: Vector3, rng: RandomNumberGenerator, count: int = 4) -> Array[Puff]:
	var puffs: Array[Puff] = []
	for i in count:
		var puff := Puff.new()
		puff.origin = local_pos
		puff.lifetime = rng.randf_range(LIFETIME_MIN, LIFETIME_MAX)
		puff.age = rng.randf_range(0.0, puff.lifetime)
		puff.drift = Vector2(rng.randf_range(-DRIFT_RANGE, DRIFT_RANGE), rng.randf_range(-DRIFT_RANGE, DRIFT_RANGE))
		var mesh := SuperEgg.build_part(Vector3.ONE, SMOKE_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		var material := mesh.get_surface_override_material(0) as StandardMaterial3D
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.75
		parent.add_child(mesh)
		puff.mesh = mesh
		_apply(puff)
		puffs.append(puff)
	return puffs


## Advances every puff by `delta`, recycling any that finish their cycle
## with a freshly randomized lifetime/drift -- an endless, never-identical
## plume rather than a fixed loop.
static func animate(puffs: Array[Puff], delta: float, rng: RandomNumberGenerator) -> void:
	for puff in puffs:
		puff.age += delta
		if puff.age >= puff.lifetime:
			puff.age -= puff.lifetime
			puff.lifetime = rng.randf_range(LIFETIME_MIN, LIFETIME_MAX)
			puff.drift = Vector2(rng.randf_range(-DRIFT_RANGE, DRIFT_RANGE), rng.randf_range(-DRIFT_RANGE, DRIFT_RANGE))
		_apply(puff)


static func _apply(puff: Puff) -> void:
	var t := puff.age / puff.lifetime
	# Billows slightly larger through the first third of its life, then
	# dissipates to nothing over the remainder -- real smoke expands before
	# it thins out, not a uniform shrink from the moment it leaves the flue.
	var grow_t := clampf(t / 0.3, 0.0, 1.0)
	var fade_t := clampf((t - 0.3) / 0.7, 0.0, 1.0)
	var radius: float = lerpf(RADIUS_MIN, RADIUS_MAX, grow_t) * lerpf(1.0, 0.0, fade_t)
	puff.mesh.scale = Vector3.ONE * maxf(radius, 0.001)
	puff.mesh.position = puff.origin + Vector3(puff.drift.x * t, RISE_HEIGHT * t, puff.drift.y * t)
