class_name CloudPlatform
extends StaticBody3D

## A temporary, silent cloud summoned by an Air blorb. This is atmospheric
## cloud matter, not a reshaped piece of the blorb's body, so it deliberately
## uses the world's soft cloud color rather than ElementPalette.AIR_BODY.
const BASE_HOLD_DURATION := 3.8
const FADE_DURATION := 0.55

var _elapsed := 0.0
var _hold_duration := BASE_HOLD_DURATION
var _materials: Array[StandardMaterial3D] = []


static func spawn(parent: Node, world_center: Vector3, rng: RandomNumberGenerator, level: int = 1, platform_scale: float = 1.0) -> CloudPlatform:
	var cloud := CloudPlatform.new()
	cloud.collision_layer = 1
	cloud.collision_mask = 0
	cloud._hold_duration = BASE_HOLD_DURATION+minf(float(level-1)*0.12,3.0)
	parent.add_child(cloud)
	cloud.global_position = world_center
	var width := (1.45+minf(float(level-1)*0.035,0.75))*platform_scale
	for lobe_index in 5:
		var lobe := SuperEgg.build_part(
			Vector3(width*(0.44+rng.randf_range(-0.04,0.06)),0.24+rng.randf_range(-0.025,0.035),width*(0.31+rng.randf_range(-0.035,0.04))),
			Color(0.86,0.92,0.98,0.76),SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_SOFT
		)
		var angle := TAU*float(lobe_index)/5.0+rng.randf_range(-0.2,0.2)
		lobe.position = Vector3(cos(angle)*width*0.32,rng.randf_range(-0.035,0.055),sin(angle)*width*0.2)
		var material := lobe.get_surface_override_material(0) as StandardMaterial3D
		if material != null:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.roughness = 0.86
			cloud._materials.append(material)
		cloud.add_child(lobe)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width*1.65,0.28,width*1.12)
	collider.shape = shape
	collider.position.y = -0.02
	cloud.add_child(collider)
	cloud.add_to_group("power_platforms")
	cloud.set_meta("support_radius",width*0.72)
	cloud.set_meta("support_top_y",world_center.y+0.12)
	return cloud


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed <= _hold_duration:
		return
	var fade := clampf((_elapsed-_hold_duration)/FADE_DURATION,0.0,1.0)
	for material in _materials:
		material.albedo_color.a = lerpf(0.76,0.0,fade)
	if fade >= 0.45:
		collision_layer = 0
	if fade >= 1.0:
		queue_free()
