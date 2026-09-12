class_name IceCrag
extends StaticBody3D

const RISE_DURATION:=0.25
const HOLD_DURATION:=0.9
const SINK_DURATION:=0.3
const BURIAL_DEPTH:=1.1
var _phase:=0
var _elapsed:=0.0
var _rest_y:=0.0
var _hold:=HOLD_DURATION

static func spawn(parent:Node,world_position:Vector3,rng:RandomNumberGenerator,level:int=1,platform_scale:float=1.0)->IceCrag:
	var crag:=IceCrag.new();crag.collision_layer=1;crag.collision_mask=0;crag._rest_y=world_position.y;crag._hold=HOLD_DURATION+minf(float(level-1)*0.12,3.0)
	parent.add_child(crag);crag.global_position=world_position-Vector3.UP*BURIAL_DEPTH
	UISounds.play_foley(&"rock_erupt",0.52,crag.get_instance_id())
	var radius:float=rng.randf_range(0.55,0.75)*(1.0+minf(float(level-1)*0.055,1.2))*platform_scale
	var ice:=NatureProps.build_rock(radius,false);var mat:=StandardMaterial3D.new();mat.albedo_color=Color(0.55,0.84,0.98,0.9);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;mat.roughness=0.1;mat.metallic=0.16
	IceCrag._tint(ice,mat);crag.add_child(ice)
	var collider:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=radius*0.82;shape.height=radius*1.55;collider.shape=shape;collider.position.y=radius*0.55;crag.add_child(collider)
	return crag

static func _tint(node:Node,mat:Material)->void:
	if node is MeshInstance3D:(node as MeshInstance3D).set_surface_override_material(0,mat)
	for child in node.get_children():_tint(child,mat)

func _process(delta:float)->void:
	_elapsed+=delta
	if _phase==0:
		var t:float=clampf(_elapsed/RISE_DURATION,0.0,1.0);global_position.y=lerpf(_rest_y-BURIAL_DEPTH,_rest_y,ease(t,0.4))
		if t>=1.0:_phase=1;_elapsed=0.0
	elif _phase==1 and _elapsed>=_hold:
		_phase=2;_elapsed=0.0;UISounds.play_foley(&"rock_retract",0.3,get_instance_id())
	elif _phase==2:
		var t:float=clampf(_elapsed/SINK_DURATION,0.0,1.0);global_position.y=lerpf(_rest_y,_rest_y-BURIAL_DEPTH,ease(t,1.8))
		if t>=1.0:queue_free()
