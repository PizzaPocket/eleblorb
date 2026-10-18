extends Node3D

## Streamed playable spaces for the three floors P17 enters. Local Y is the
## plan height above the plinth floor; the root is placed at the tower datum.
const MECH_SCENE := preload("res://scenes/block_mech.tscn")
const NPC_SCENE := preload("res://scenes/npc.tscn")
var _lift: Node3D
var _mech: Node3D
var _control_thread: MeshInstance3D
var _entered := false
var _exiting := false
var _last_arena_y := -INF
var _talk_counts := {"Kask":0,"Pinestein":0}

func _ready() -> void:
	name = "BLOCK_Tower_Inside"
	var terrain_stub := Node.new(); terrain_stub.name="Terrain"; add_child(terrain_stub)
	_build_floors()
	_build_lift()
	_build_arena()
	_build_people()
	if WorldState.block_tower_mech_defeated: _spawn_empty_mech()

func _physics_process(_delta: float) -> void:
	if _exiting: return
	var body := PartyControl.active_control_body() as Node3D
	if body == null: return
	var local := to_local(body.global_position)
	_update_control_thread()
	# Touching the open east louvre places the climber just inside the plant.
	if not _entered and local.y > 78.0 and local.y < 85.0 and local.x > 11.0 and absf(local.z) < 3.0:
		_entered = true
		body.global_position = to_global(Vector3(8.0,80.3,0.0))
	# Start the brief story beat as soon as the hero steps onto the arena floor.
	if local.y > 150.0 and local.y < 154.0 and absf(local.x) < 9.0 and absf(local.z) < 9.0:
		if not WorldState.block_tower_story_started:
			WorldState.block_tower_story_started = true
			_play_intro()
			_spawn_boss()
		elif not WorldState.block_tower_mech_defeated and _mech == null:
			_spawn_boss()
	# The one lobby door only opens after the fight.
	if WorldState.block_tower_door_open and local.y < 3.0 and local.z < -13.0 and absf(local.x) < 2.2:
		_exiting = true
		var mech_body := MechState._world_body if is_instance_valid(MechState._world_body) else null
		if mech_body != null and mech_body.get_parent() == self:
			remove_child(mech_body); get_parent().add_child(mech_body)
			mech_body.global_position = to_global(Vector3(-4.0,0.2,-17.0))
		body.global_position = to_global(Vector3(0.0,1.0,-18.0))
		get_parent().set("_moy_block_tower_inside",null)
		queue_free()

func _play_intro() -> void:
	DialogUI.show_line("Dr. Vera Kask", "All the way up the outside. How persistent.", [], "", func() -> void:
		DialogUI.show_line("Palbert Pinestein", "Shh, shh. They're listening to me now. Go on, my lovelies.", [], "", Callable(), true), true)

func _update_control_thread() -> void:
	var active := _mech != null and is_instance_valid(_mech) and bool(_mech.get("boss_mode"))
	if not active:
		if is_instance_valid(_control_thread): _control_thread.queue_free()
		_control_thread=null
		return
	if _control_thread == null:
		_control_thread=MeshInstance3D.new(); _control_thread.name="Pinestein_Control_Thread"
		var mesh:=CylinderMesh.new(); mesh.top_radius=0.025; mesh.bottom_radius=0.025; mesh.height=1.0
		_control_thread.mesh=mesh
		var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("#42c9ff"); mat.emission_enabled=true; mat.emission=Color("#42c9ff"); mat.emission_energy_multiplier=1.4
		_control_thread.material_override=mat; add_child(_control_thread)
	var pin:=get_node_or_null("Pinestein") as Node3D
	if pin==null: return
	var from:=pin.global_position+Vector3(0,1.65,0)
	var to:=_mech.global_position+Vector3(0,1.8,0)
	var axis:=to-from; var length:=axis.length()
	if length<0.01: return
	_control_thread.global_transform=Transform3D(Basis(Quaternion(Vector3.UP,axis/length)),(from+to)*0.5)
	_control_thread.scale=Vector3.ONE; _control_thread.scale.y=length

func _build_floors() -> void:
	# Lobby (0–8), way-in plant (79–83), and arena (150+); the intervening
	# storeys remain solid mass in the baked exterior, per the locked plan.
	_box("Lobby_Floor",Vector3(26,0.6,24),Vector3(0,0,0),Color("#292d35"),true)
	_box("Lobby_Ceiling",Vector3(26,0.5,24),Vector3(0,8,0),Color("#181a20"),true)
	_box("Plant_Floor",Vector3(24,0.5,22),Vector3(0,79,0),Color("#39403e"),true)
	_box("Plant_Ceiling",Vector3(24,0.5,22),Vector3(0,83,0),Color("#202329"),true)
	_box("Arena_Floor",Vector3(24,0.7,22),Vector3(0,150,0),Color("#242833"),true)
	# Lobby has one exit in the north wall. Keep a clear doorway for the return.
	_box("Lobby_West",Vector3(0.6,8,24),Vector3(-13,4,0),Color("#20242b"),true)
	_box("Lobby_East",Vector3(0.6,8,24),Vector3(13,4,0),Color("#20242b"),true)
	_box("Lobby_South",Vector3(26,8,0.6),Vector3(0,4,12),Color("#20242b"),true)
	_box("Lobby_North_L",Vector3(10.5,8,0.6),Vector3(-7.75,4,-12),Color("#20242b"),true)
	_box("Lobby_North_R",Vector3(10.5,8,0.6),Vector3(7.75,4,-12),Color("#20242b"),true)
	# A compact way-in room behind the east louvre.
	_box("Plant_West",Vector3(0.5,4,22),Vector3(-12,81,0),Color("#242a2e"),true)
	_box("Plant_North",Vector3(24,4,0.5),Vector3(0,81,-11),Color("#242a2e"),true)
	_box("Plant_South",Vector3(24,4,0.5),Vector3(0,81,11),Color("#242a2e"),true)
	# Fans and ducts also make a small parkour route across the floor.
	for i in 4:
		_box("Plant_Duct_%d"%i,Vector3(2.2,1.0,3.0),Vector3(-7.0+i*4.0,80.0+(i%2)*1.2,-4.0),Color("#69716d"),true)
	_box("Lift_Door_Plant",Vector3(3.4,3.2,0.16),Vector3(3.5,81,-10.4),Color("#11151b"),false)
	# Arena perimeter walls are deliberately low and complete; no route beyond
	# the crown panels is reachable from this contained floor.
	for side in [-1.0,1.0]:
		_box("Arena_Side_%s"%side,Vector3(0.6,10,22),Vector3(side*12,155,0),Color("#141820"),true)
		_box("Arena_End_%s"%side,Vector3(24,10,0.6),Vector3(0,155,side*11),Color("#141820"),true)
	# Gallery glass and stair are solid; the ledge is a separate reachable bay.
	_box("Gallery_Floor",Vector3(8,0.4,6),Vector3(0,164,8.5),Color("#303b46"),true)
	_box("Gallery_Glass",Vector3(8,2.5,0.12),Vector3(0,165.3,11.35),Color("#659cb2"),true,0.32)
	for i in 8: _box("Gallery_Stair_%02d"%i,Vector3(2.5,0.25,0.75),Vector3(-8.0+i*0.85,150.3+i*1.6,4.0),Color("#39404b"),true)

func _build_lift() -> void:
	var script = load("res://scripts/block_tower_lift.gd")
	_lift = AnimatableBody3D.new(); _lift.name="Lift"; _lift.set_script(script)
	_lift.position=Vector3(3.5,79,1.5); _lift.call("initialize_stop",1); add_child(_lift)
	_lift.set("stop_levels",PackedFloat32Array([0.0,79.0,150.0]))
	_box("Lift_Shaft_West",Vector3(0.3,152,3.8),Vector3(1.4,76,1.5),Color("#12151b"),true)
	_box("Lift_Shaft_East",Vector3(0.3,152,3.8),Vector3(5.6,76,1.5),Color("#12151b"),true)

func _build_arena() -> void:
	# Eye light and ribs echo the folded crown interior.
	var eye := OmniLight3D.new(); eye.name="Crown_Eye_Light"; eye.light_color=Color("#57bfff"); eye.light_energy=2.8; eye.omni_range=18
	eye.position=Vector3(0,169,-10); add_child(eye)
	for i in 5:
		_box("Crown_Rib_%d"%i,Vector3(0.3,18,0.35),Vector3(-9+i*4.5,159,0),Color("#202936"),true)

func _build_people() -> void:
	var kask := _make_npc("Kask")
	kask.display_name="Dr. Vera Kask"; kask.is_female=true; kask.body_scale=1.08; kask.hair_style=FigureHair.STYLE_BUN
	kask.hair_color=Color("#72777d"); kask.shirt_color=Color("#101a2c"); kask.pants_color=Color("#101a2c"); kask.wears_dress=true
	kask.dress_color=Color("#101a2c"); kask.glove_color=Color("#08090c"); kask.collar_pin_color=Color("#45aaff")
	kask.position=Vector3(-2,164.2,8); kask.facing_degrees=0; kask.stationary=true
	kask.talk_override=Callable(self,"_talk_kask"); add_child(kask)
	var pin := _make_npc("Pinestein")
	pin.display_name="Palbert Pinestein"; pin.is_female=false; pin.body_scale=0.88; pin.hair_style=FigureHair.STYLE_WILD
	pin.hair_color=Color("#e7e4d7"); pin.shirt_color=Color("#b39a43"); pin.pants_color=Color("#4d4840"); pin.wears_lab_coat=true
	pin.has_glasses=true; pin.position=Vector3(2,164.2,8); pin.stationary=true; pin.talk_override=Callable(self,"_talk_pin"); add_child(pin)

func _make_npc(label:String) -> Node3D:
	var node := NPC_SCENE.instantiate() as Node3D; node.name=label
	node.set("fixed_ground_y",104.2); node.set("talk_lines",["..."])
	node.call("set_terrain_reference",get_node("Terrain"))
	return node

func play_defeat_lines() -> void:
	if is_instance_valid(_control_thread): _control_thread.queue_free()
	_control_thread=null
	DialogUI.show_line("Palbert Pinestein", "No, no, come back... They've gone quiet. All of them.", [], "", func() -> void:
		DialogUI.show_line("Dr. Vera Kask", "He promised me so much more than this.", [], "", Callable(), true), true)

func _talk_kask() -> bool:
	if not WorldState.block_tower_mech_defeated: return true
	var lines=["Take it, then. Take all of it.","Don't expect me to clap."]
	var line:String=lines[int(_talk_counts.Kask)%lines.size()]; _talk_counts.Kask+=1
	DialogUI.show_line("Dr. Vera Kask",line,[],"",Callable(),true)
	return true

func _talk_pin() -> bool:
	if not WorldState.block_tower_mech_defeated: return true
	var lines=["Years of tuning, and you walk in through a vent.","They don't hum for me any more."]
	var line:String=lines[int(_talk_counts.Pinestein)%lines.size()]; _talk_counts.Pinestein+=1
	DialogUI.show_line("Palbert Pinestein",line,[],"",Callable(),true)
	return true

func _spawn_boss() -> void:
	if _mech != null or WorldState.block_tower_mech_defeated: return
	_mech=MECH_SCENE.instantiate(); _mech.set("boss_mode",true); _mech.position=Vector3(0,151.35,-2); add_child(_mech)

func _spawn_empty_mech() -> void:
	if _mech != null: return
	_mech=MECH_SCENE.instantiate(); _mech.set("boss_mode",false); _mech.position=Vector3(0,151.35,-2); add_child(_mech)

func _box(label:String,size:Vector3,at:Vector3,color:Color,solid:bool,alpha:float=1.0) -> void:
	var body:Node3D
	if solid: body=StaticBody3D.new(); body.name=label
	else: body=Node3D.new(); body.name=label
	body.position=at; add_child(body)
	var mesh:=BoxMesh.new(); mesh.size=size
	var vis:=MeshInstance3D.new(); vis.mesh=mesh; vis.position=Vector3.ZERO
	var mat:=StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=0.75; mat.metallic=0.4
	if alpha<1.0: mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.albedo_color.a=alpha
	vis.material_override=mat; body.add_child(vis)
	if solid:
		var shape:=BoxShape3D.new(); shape.size=size
		var col:=CollisionShape3D.new(); col.shape=shape; body.add_child(col)
