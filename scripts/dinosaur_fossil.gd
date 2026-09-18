extends Node3D

## Titan-scale collapsed fossil of Dinosaur. Its target skeleton mirrors the
## living quadruped's spine, rib cage, skull, four planted legs, hind feet,
## pelvis and tapering tail. Blorb Slime first draws those collapsed bones
## into their anatomical positions, then visibly spreads over them before
## the living titan is revealed.
const BONE := Color(0.74,0.66,0.50)
const DARK_BONE := Color(0.57,0.49,0.36)
const ASSEMBLY_DURATION := 0.28
const ASSEMBLY_STAGGER := 0.004
const SLIME_SPREAD_DURATION := 0.22
const FLESH_REVEAL_DURATION := 0.16

var _fossil_body: StaticBody3D = null
var _bone_entries: Array[Dictionary] = []
var _resurrection_in_progress := false


func _ready() -> void:
	scale = Vector3.ONE*2.0
	if WorldState.dinosaur_resurrected:
		_build_living_dinosaur()
		return
	_build_quadruped_fossil()


func _build_quadruped_fossil() -> void:
	_fossil_body=StaticBody3D.new()
	_fossil_body.name="DinosaurFossilBody"
	_fossil_body.collision_layer=1 | TownProps.BLORB_CLIMBABLE_LAYER
	add_child(_fossil_body)

	for i in 12:
		var t:=float(i)/11.0
		_add_bone_target(
			Vector3(lerpf(-14.0,1.5,t),7.25+sin(t*PI)*0.45,0.0),
			Vector3(0.78,0.42,0.48),Vector3.ZERO,BONE
		)

	# Seven paired ribs sweep down and outward from the spine, reading as one
	# large rib cage rather than a row of unrelated limb-like bones.
	for i in 7:
		var x:=lerpf(-12.5,-2.0,float(i)/6.0)
		var rib_drop:=2.0+sin(float(i)/6.0*PI)*0.65
		for side in [-1.0,1.0]:
			_add_limb_target(Vector3(x,7.2,0.0),Vector3(0.0,-rib_drop,side*3.45),0.24,BONE)

	_add_bone_target(Vector3(-12.0,5.45,0.0),Vector3(1.4,0.55,3.45),Vector3.ZERO,DARK_BONE)
	_add_bone_target(Vector3(-1.0,5.65,0.0),Vector3(1.75,0.72,3.55),Vector3.ZERO,DARK_BONE)

	# Cranium plus long upper and lower jaws match the living animal's
	# distinctive -X-facing head proportions.
	_add_bone_target(Vector3(-14.6,9.35,0.0),Vector3(1.5,1.35,1.45),Vector3.ZERO,DARK_BONE)
	_add_bone_target(Vector3(-18.3,7.75,0.0),Vector3(4.45,0.72,2.25),Vector3(0.0,0.0,-0.08),BONE)
	_add_bone_target(Vector3(-18.1,6.55,0.0),Vector3(4.0,0.35,1.85),Vector3(0.0,0.0,0.04),DARK_BONE)
	for side in [-1.0,1.0]:
		_add_bone_target(Vector3(-15.2,9.5,side*1.12),Vector3(0.55,0.68,0.28),Vector3.ZERO,BONE)

	# Four weight-bearing limbs; the heavier hind pair terminates in the same
	# long feet that distinguish the finished living rig.
	for side in [-1.0,1.0]:
		_add_limb_target(Vector3(-12.0,5.2,side*3.2),Vector3(0.15,-2.55,0.0),0.43,BONE)
		_add_limb_target(Vector3(-11.85,2.65,side*3.2),Vector3(-0.1,-2.45,0.0),0.36,BONE)
		_add_limb_target(Vector3(-1.0,5.45,side*3.2),Vector3(0.2,-2.45,0.0),0.58,BONE)
		_add_limb_target(Vector3(-0.8,3.0,side*3.2),Vector3(-0.1,-2.35,0.0),0.48,BONE)
		_add_limb_target(Vector3(-0.9,0.62,side*3.2),Vector3(-1.65,0.0,0.0),0.38,DARK_BONE)

	# Tail vertebrae follow the living tail's 38-degree initial descent and
	# easing curve, tapering continuously toward its rounded end.
	var previous:=Vector3(-4.0,8.0,0.0)
	for i in 12:
		var t:=float(i+1)/12.0
		var x:=9.35*t
		var y:=-9.35*tan(deg_to_rad(38.0))*(t-0.5*t*t)
		var current:=Vector3(-4.0+x,8.0+y,0.0)
		_add_limb_target(previous,current-previous,lerpf(0.48,0.11,t),BONE)
		previous=current


func receive_thrown_item(item_name: String) -> bool:
	if item_name!="Blorb Slime" or WorldState.dinosaur_resurrected or _resurrection_in_progress:
		return false
	_resurrection_in_progress=true
	WorldState.dinosaur_resurrected=true
	Hud.show_message("The Blorb Slime courses through Dinosaur's bones!")
	_run_resurrection.call_deferred()
	return true


func _run_resurrection() -> void:
	if not is_instance_valid(_fossil_body):
		_build_living_dinosaur()
		return
	_fossil_body.collision_layer=0
	var assembly:=create_tween().set_parallel(true)
	for i in _bone_entries.size():
		var entry:=_bone_entries[i]
		var bone:=entry["bone"] as MeshInstance3D
		var target:=entry["target"] as Transform3D
		assembly.tween_property(bone,"transform",target,ASSEMBLY_DURATION).set_delay(float(i)*ASSEMBLY_STAGGER).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await assembly.finished
	if not is_inside_tree():
		return

	var slime_root:=_build_slime_spread()
	add_child(slime_root)
	var blobs:=slime_root.get_children()
	var spread:=create_tween().set_parallel(true)
	for i in blobs.size():
		var blob:=blobs[i] as MeshInstance3D
		spread.tween_property(blob,"scale",Vector3.ONE,SLIME_SPREAD_DURATION).set_delay(float(i)*0.025).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await spread.finished
	if not is_inside_tree():
		return

	_fossil_body.visible=false
	_fossil_body.queue_free()
	_fossil_body=null
	var titan:=_build_living_dinosaur()
	titan.process_mode=Node.PROCESS_MODE_DISABLED
	titan.collision_layer=0
	titan.scale=Vector3.ONE*0.94

	var reveal:=create_tween().set_parallel(true)
	reveal.tween_property(titan,"scale",Vector3.ONE,FLESH_REVEAL_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for child in blobs:
		var blob:=child as MeshInstance3D
		reveal.tween_property(blob,"transparency",1.0,FLESH_REVEAL_DURATION)
	await reveal.finished
	if is_instance_valid(slime_root):
		slime_root.queue_free()
	if is_instance_valid(titan):
		titan.collision_layer=1 | TownProps.BLORB_CLIMBABLE_LAYER
		titan.process_mode=Node.PROCESS_MODE_INHERIT


func _build_slime_spread() -> Node3D:
	var root:=Node3D.new()
	root.name="ResurrectionSlime"
	var specs:Array[Dictionary]=[
		{"half":Vector3(8.7,4.5,4.2),"pos":Vector3(-7.0,6.8,0.0)},
		{"half":Vector3(5.1,3.3,2.7),"pos":Vector3(-18.0,7.0,0.0)},
		{"half":Vector3(1.75,2.8,1.75),"pos":Vector3(-1.0,2.8,-3.2)},
		{"half":Vector3(1.75,2.8,1.75),"pos":Vector3(-1.0,2.8,3.2)},
		{"half":Vector3(1.35,2.65,1.35),"pos":Vector3(-12.0,2.65,-3.2)},
		{"half":Vector3(1.35,2.65,1.35),"pos":Vector3(-12.0,2.65,3.2)},
		{"half":Vector3(5.0,1.2,1.2),"pos":Vector3(0.5,5.7,0.0)},
	]
	for spec in specs:
		var half:=spec["half"] as Vector3
		var pos:=spec["pos"] as Vector3
		var blob:=SuperEgg.build_part(half,ShopCatalog.BLORB_SLIME_COLOR,2.4,2.8)
		blob.position=pos
		blob.scale=Vector3.ONE*0.02
		root.add_child(blob)
		CollisionPolicy.mark_decorative(blob)
	return root


func _build_living_dinosaur() -> DinosaurTitan:
	var titan:=DinosaurTitan.new()
	titan.name="Dinosaur"
	add_child(titan)
	return titan


func _add_limb_target(start: Vector3,delta: Vector3,radius: float,color: Color) -> void:
	var midpoint:=start+delta*0.5
	var basis:=Basis(Quaternion(Vector3.UP,delta.normalized()))
	_add_target_part(midpoint,Vector3(radius,delta.length()*0.5,radius),basis,color)


func _add_bone_target(pos: Vector3,half_size: Vector3,rotation: Vector3,color: Color) -> void:
	_add_target_part(pos,half_size,Basis.from_euler(rotation),color)


func _add_target_part(pos: Vector3,half_size: Vector3,target_basis: Basis,color: Color) -> void:
	var bone:=SuperEgg.build_part(half_size,color,2.8,2.8)
	var target:=Transform3D(target_basis,pos)
	var index:=_bone_entries.size()
	var collapsed_basis:=Basis(Vector3.RIGHT,deg_to_rad(82.0))*target_basis
	var collapsed_pos:=Vector3(
		pos.x+sin(float(index)*1.73)*0.55,
		0.48+float(index%3)*0.12,
		pos.z+pos.y*0.42+cos(float(index)*1.21)*0.35
	)
	bone.transform=Transform3D(collapsed_basis,collapsed_pos)
	_fossil_body.add_child(bone)
	var collider:=CollisionPolicy.add_box(
		_fossil_body,bone,half_size*2.0,collapsed_pos,collapsed_basis,true
	)
	_bone_entries.append({"bone":bone,"collider":collider,"target":target})
