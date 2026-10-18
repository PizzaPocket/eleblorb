extends CharacterBody3D

## A small story boss and, after the fight, a controllable shell. The rig is
## authored at the human reference height and enlarged as one coherent unit.
const MAX_HP := 400.0
const XP_REWARD := 300
const MOVE_SPEED := 2.4
const PROFILE_HEIGHT := 1.896 * 1.05
const PROFILE_SCRIPT := preload("res://scripts/playable_character_profile.gd")

var boss_mode := true
var current_hp := MAX_HP
var _fight_started := false
var _defeated := false
var _pilot: Blorb
var _suit_blorbs: Array[Blorb] = []
var _return_body: Node3D
var _attack_timer := 0.0
var _stream_timer := 0.0
var _host_controlled := false
var _xp_participants: Dictionary = {}
var _stream_visible_time := 0.0
var _city_stream: MeshInstance3D
var _leap_timer := 3.0
var _visors: MeshInstance3D
var _kneel := false
var _ctx: TraversalContext
var _profile: PlayableCharacterProfile
var _rig: RigAdapter
var _pivots: Dictionary = {}
var _spine_rest_y := 0.0
var _suit: BlorbSuitController
var _traversal := TraversalDirector.new()

func _ready() -> void:
	name = "BLOCK_Mech"
	add_to_group("skeletons")
	collision_layer = 1
	collision_mask = 1
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.28; capsule.height = 1.99
	var shape := CollisionShape3D.new(); shape.shape = capsule; shape.position.y = 0.98; add_child(shape)
	_build_body()
	_build_traversal_context()
	if boss_mode:
		_begin_boss()
	else:
		_defeated = true; current_hp = MAX_HP; _kneel = true; _set_pose_kneel()
		Interactable.attach(self, "Mech", 2.4, func() -> void: MechState._show_world_actions(self), Callable(), Callable(), true, 2.0)

func set_boss_mode(value: bool) -> void:
	boss_mode = value

func _build_body() -> void:
	var dark := _mat(Color("#101319"), 0.88, 0.55)
	var steel := _mat(Color("#b8c3cd"), 0.56, 0.72)
	var blue := _mat(Color(0.3,0.7,1.0), 0.25, 0.15, true)
	var visuals := Node3D.new(); visuals.name = "Visuals"; add_child(visuals)
	var terrain_stub := Node.new(); terrain_stub.name="Terrain"; visuals.add_child(terrain_stub)
	_pivots = ProceduralFigure.build(visuals, Color("#101319"), Color("#101319"), Color("#101319"), ProceduralFigure.SLEEVE_STYLE_NONE, 1.05, 0.82, 0.82, 0.9, Color(0,0,0,0), Color("#101319"), "none", 0.0, Color("#101319"))
	_spine_rest_y=float(_pivots["spine"].position.y)
	_add_box(visuals,"Abdomen_Upper",Vector3(0.27,0.22,0.18),Vector3(0,0.99,0),dark)
	_add_box(visuals,"Abdomen_Lower",Vector3(0.25,0.20,0.17),Vector3(0,0.75,0),dark)
	_add_box(visuals,"Chest_Plate",Vector3(0.38,0.34,0.20),Vector3(0,1.22,0.015),steel)
	_add_box(visuals,"Chest_Light",Vector3(0.035,0.23,0.025),Vector3(0,1.23,0.13),blue)
	_add_box(visuals,"Neck",Vector3(0.10,0.12,0.10),Vector3(0,1.48,0),dark)
	var head := _add_box(visuals,"Head_Shell",Vector3(0.30,0.34,0.28),Vector3(0,1.68,0),dark)
	_visors = _add_box(visuals,"Glass_Visor",Vector3(0.25,0.22,0.05),Vector3(0,1.69,0.15),blue)
	_visors.material_override.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_visors.material_override.albedo_color.a = 0.58
	_add_box(visuals,"Shoulder_L",Vector3(0.20,0.11,0.20),Vector3(-0.29,1.39,0),dark)
	_add_box(visuals,"Shoulder_R",Vector3(0.20,0.11,0.20),Vector3(0.29,1.39,0),dark)
	for side in [-1.0,1.0]:
		_add_box(visuals,"Arm_%s"%side,Vector3(0.08,0.43,0.08),Vector3(side*0.33,1.08,0),dark)
		_add_box(visuals,"Hand_%s"%side,Vector3(0.12,0.09,0.10),Vector3(side*0.33,0.83,0),dark)
		_add_box(visuals,"Thigh_%s"%side,Vector3(0.12,0.30,0.13),Vector3(side*0.105,0.50,0),dark)
		_add_box(visuals,"Shin_%s"%side,Vector3(0.095,0.30,0.10),Vector3(side*0.105,0.19,0),dark)
		_add_box(visuals,"Piston_%s"%side,Vector3(0.035,0.32,0.035),Vector3(side*0.16,0.20,-0.08),dark)
		_add_box(visuals,"Foot_%s"%side,Vector3(0.14,0.08,0.23),Vector3(side*0.105,0.045,0.04),dark)
		for y in [0.20,0.51,1.39,1.68]:
			var ring := _add_box(visuals,"Joint_Light_%s_%s"%[side,y],Vector3(0.12,0.025,0.12),Vector3(side*(0.11 if y<1 else 0.30),y,0),blue)
	_city_stream=MeshInstance3D.new(); _city_stream.name="City_Current_Stream"
	var stream_mesh:=CylinderMesh.new(); stream_mesh.top_radius=0.035; stream_mesh.bottom_radius=0.035
	_city_stream.mesh=stream_mesh; _city_stream.material_override=blue; _city_stream.visible=false; add_child(_city_stream)
	# Pilot and worn city blorbs are represented by real Blorb nodes during
	# the fight. Their rendered heads sit inside the shell and on suit stations.
	_pilot = _make_blorb("BLOCK Pilot", false)
	_pilot.scale = Vector3.ONE * 0.62
	_pilot.position = Vector3(0,1.68,0.01)
	_attach_pilot_visual(_pilot, visuals)
	for i in range(6):
		var blorb := _make_blorb("BLOCK Suit %d" % (i+1), false)
		blorb.scale = Vector3.ONE * 0.24
		var places := [Vector3(-0.30,1.39,0),Vector3(0.30,1.39,0),Vector3(-0.11,0.98,0.08),Vector3(0.11,0.75,0.08),Vector3(-0.12,0.42,0),Vector3(0.12,0.42,0)]
		blorb.position = places[i]; _attach_pilot_visual(blorb, visuals); _suit_blorbs.append(blorb)

func _attach_pilot_visual(blorb: Blorb, visuals: Node3D) -> void:
	visuals.add_child(blorb)

func _make_blorb(label: String, joinable: bool) -> Blorb:
	var scene := load("res://scenes/blorb.tscn") as PackedScene
	var blorb := scene.instantiate() as Blorb
	blorb.name = label; blorb.blorb_name = label; blorb.initial_element = "city"
	blorb.portrait_mode = true; blorb.in_party = false; blorb.can_join_party = joinable
	return blorb

func _begin_boss() -> void:
	current_hp = MAX_HP
	_fight_started = true
	add_to_group("skeletons")

func current_combat_element() -> String:
	return "city"

func take_damage(amount: float, attacker: Blorb = null) -> void:
	if not boss_mode or _defeated or not _fight_started or amount <= 0.0: return
	if attacker != null and attacker.in_party and not attacker.is_melted: _xp_participants[attacker.get_instance_id()] = attacker
	current_hp -= amount
	if current_hp <= 0.0: _win()

func _win() -> void:
	if _defeated: return
	_award_defeat_xp()
	_defeated = true; boss_mode = false; _fight_started = false
	WorldState.block_tower_mech_defeated = true; WorldState.block_tower_door_open = true
	remove_from_group("skeletons"); _kneel = true
	if is_instance_valid(_city_stream): _city_stream.visible=false
	if is_instance_valid(_visors):
		var visor_tween:=create_tween(); visor_tween.tween_property(_visors,"rotation:x",-1.15,0.55).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if is_instance_valid(_pilot): _pilot.queue_free()
	for b in _suit_blorbs:
		if is_instance_valid(b): b.queue_free()
	_suit_blorbs.clear()
	await get_tree().create_timer(0.45).timeout
	_drop_blorbs()
	if get_parent().has_method("play_defeat_lines"): get_parent().call("play_defeat_lines")
	Interactable.attach(self, "Mech", 2.4, func() -> void: MechState._show_world_actions(self), Callable(), Callable(), true, 2.0)
	if Hud != null: Hud.show_message("The mech kneels, empty.")

func _award_defeat_xp() -> void:
	var party: Array[Blorb]=[]
	for value in _xp_participants.values():
		var b:=value as Blorb
		if is_instance_valid(b) and b.in_party and not b.is_melted: party.append(b)
	if party.is_empty(): return
	party.sort_custom(func(a:Blorb,b:Blorb) -> bool: return a.get_instance_id()<b.get_instance_id())
	var share:=floori(float(XP_REWARD)/party.size()); var remainder:=XP_REWARD-share*party.size()
	for i in party.size(): party[i].gain_experience(share+(1 if i<remainder else 0))

func _drop_blorbs() -> void:
	var names := ["BLOCK Pilot", "BLOCK Suit 1", "BLOCK Suit 2", "BLOCK Suit 3", "BLOCK Suit 4", "BLOCK Suit 5", "BLOCK Suit 6"]
	var world := get_parent().get_parent() if get_parent() != null and get_parent().get_parent() != null else get_parent()
	for i in names.size():
		var b := _make_blorb(names[i], true)
		world.add_child(b)
		b.global_position = global_position + Vector3(float(i%3)-1.0,0.4,float(i/3)*0.8+1.0)

func begin_host_control(return_body: Node3D) -> bool:
	if boss_mode or not _defeated: return false
	_return_body = return_body; _host_controlled = true
	if is_instance_valid(return_body): return_body.visible = false
	_visors.visible = false
	return true

func end_host_control(return_body: Node3D) -> void:
	_host_controlled = false; _kneel = true; velocity = Vector3.ZERO
	_visors.visible = true
	if is_instance_valid(return_body):
		return_body.visible = true
		return_body.global_position = global_position + global_transform.basis.z * 2.0
	MechState.mark_released(self)

func drive_from_player(direction: Vector3, delta: float, sprinting: bool, jump_pressed: bool) -> void:
	if not _host_controlled: return
	_kneel = false
	_set_pose_standing()
	if _ctx != null:
		_ctx.direction=direction; _ctx.delta=delta; _ctx.sprinting=sprinting; _ctx.jump_pressed=jump_pressed; _ctx.grounded=is_on_floor()
		if _traversal.run(_ctx):
			_traversal.pose(_ctx); move_and_slide(); return
	var speed := _ctx.scaled(MOVE_SPEED) if _ctx != null else MOVE_SPEED
	velocity.x = direction.x * (speed * (1.5 if sprinting else 1.0))
	velocity.z = direction.z * (speed * (1.5 if sprinting else 1.0))
	if jump_pressed and is_on_floor(): velocity.y = 9.0
	if not is_on_floor(): velocity.y -= 28.0 * delta
	move_and_slide()
	if direction.length() > 0.1:
		look_at(global_position + Vector3(direction.x,0,direction.z), Vector3.UP)

func _physics_process(delta: float) -> void:
	_stream_visible_time=maxf(_stream_visible_time-delta,0.0)
	if is_instance_valid(_city_stream): _city_stream.visible=_stream_visible_time>0.0 and boss_mode
	if not boss_mode or not _fight_started or _defeated: return
	var target := PartyControl.active_control_body() as Node3D
	if not is_instance_valid(target): return
	var flat := target.global_position - global_position; flat.y = 0
	var distance := flat.length()
	if distance > 1.7:
		var direction := flat.normalized(); velocity.x = direction.x * MOVE_SPEED; velocity.z = direction.z * MOVE_SPEED
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x,0,12*delta); velocity.z = move_toward(velocity.z,0,12*delta)
	if not is_on_floor(): velocity.y -= 28.0 * delta
	_attack_timer -= delta; _stream_timer -= delta
	if distance < 2.0 and _attack_timer <= 0.0:
		_attack_timer = 1.5
		if target.has_method("take_damage"): target.take_damage(18.0 * delta * 30.0)
	if distance > 2.2 and distance < 9.0 and _stream_timer <= 0.0:
		_stream_timer = 0.8
		_stream_visible_time=0.28
		if target.has_method("take_damage"): target.take_damage(9.0)
	if _stream_visible_time>0.0: _aim_city_stream(target)
	_leap_timer-=delta
	if _leap_timer<=0.0 and distance>3.0 and is_on_floor():
		_leap_timer=4.0; velocity.y=7.4
	move_and_slide()

func camera_focus_point() -> Vector3:
	return global_position + Vector3.UP * 1.1

func camera_follow_distance() -> float:
	return 3.5

func _blorb_suit_pivot_map() -> Dictionary:
	if _pivots.is_empty(): return {}
	return {
		"arm_left_shoulder":_pivots["arm_left"], "arm_left_elbow":_pivots["elbow_left"],
		"arm_right_shoulder":_pivots["arm_right"], "arm_right_elbow":_pivots["elbow_right"],
		"leg_left_hip":_pivots["leg_left"], "leg_left_knee":_pivots["knee_left"], "leg_left_ankle":_pivots["ankle_left"],
		"leg_right_hip":_pivots["leg_right"], "leg_right_knee":_pivots["knee_right"], "leg_right_ankle":_pivots["ankle_right"],
		"spine":_pivots["spine"], "head":_pivots["head"], "back_left":_pivots["back_left"], "back_right":_pivots["back_right"],
		"wrist_left":_pivots["wrist_left"], "wrist_right":_pivots["wrist_right"],
		"fingertip_left":_pivots["fingertip_left"], "fingertip_right":_pivots["fingertip_right"],
		"toe_left":_pivots["toe_left"], "toe_right":_pivots["toe_right"], "sole_left":_pivots["sole_left"], "sole_right":_pivots["sole_right"],
	}

func _build_traversal_context() -> void:
	_profile = PlayableCharacterProfile.new(); _profile.id="block_mech"; _profile.display_name="BLOCK Mech"
	_profile.capabilities = {"wear_blorb_suit":true,"ride_mount":true,"use_items":true,"needs_breath":false,"zero_gravity_propulsion":true}
	_profile.move_speed=6.0; _profile.sprint_multiplier=1.6; _profile.jump_speed=11.3; _profile.gravity_scale=4.8
	_profile.walk_cadence_scale=1.0; _profile.body_motion_scale=1.0; _profile.standing_height=PROFILE_HEIGHT
	_profile.camera_height=1.6; _profile.camera_distance=3.5; _profile.suit_rig_scale=1.05; _profile.suit_limb_fit={}; _profile.switch_order=30
	var pivot_map := _blorb_suit_pivot_map()
	_rig = RigAdapter.new(pivot_map)
	_suit = BlorbSuitController.new(); _suit.setup(self,$Visuals,pivot_map,1.05,_profile.suit_limb_fit)
	_ctx = TraversalContext.new(self,_profile,_rig,_suit,null)
	# Register the same shared powers as every other playable driver. Their
	# usual equipment and environment requirements still determine use.
	for mode in [CrouchMode.new(),SwimMode.new(),FightingPunchMode.new(),FlightMode.new(),VineSwingMode.new(),DirtbikeMode.new(),IceSkateMode.new(),CrystalSkateMode.new(),SnowboardMode.new(),PenguinMode.new(),LavaMode.new()]:
		_traversal.add(mode)

func _set_pose_kneel() -> void:
	if _pivots.is_empty(): return
	_pivots["knee_left"].rotation.x=-1.0; _pivots["knee_right"].rotation.x=-1.0
	_pivots["leg_left"].rotation.x=0.48; _pivots["leg_right"].rotation.x=0.48
	_pivots["arm_left"].rotation.z=-0.34; _pivots["arm_right"].rotation.z=0.34
	_pivots["spine"].position.y=_spine_rest_y-0.13

func _set_pose_standing() -> void:
	if _pivots.is_empty(): return
	for key in ["knee_left","knee_right","leg_left","leg_right","arm_left","arm_right"]:
		_pivots[key].rotation=Vector3.ZERO
	_pivots["spine"].position.y=_spine_rest_y

func _aim_city_stream(target: Node3D) -> void:
	var from:=Vector3(0.34,1.08,0.1)
	var to:=to_local(target.global_position+Vector3(0,0.8,0))
	var axis:=to-from; var length:=axis.length()
	if length<0.1: return
	_city_stream.transform=Transform3D(Basis(Quaternion(Vector3.UP,axis.normalized())),(from+to)*0.5)
	_city_stream.scale=Vector3.ONE; _city_stream.scale.y=length

func _add_box(parent: Node3D, label: String, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new(); mesh.size=size
	var node := MeshInstance3D.new(); node.name=label; node.mesh=mesh; node.position=at; node.material_override=material
	parent.add_child(node); return node

func _mat(color: Color, roughness: float, metallic: float, glow := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new(); material.albedo_color=color; material.roughness=roughness; material.metallic=metallic
	if glow: material.emission_enabled=true; material.emission=color; material.emission_energy_multiplier=1.8
	return material
