extends Node3D

## Isolated traversal start for the authored Moy prototype. This grants a
## debug-only Leaf Hat and Xiao Hou Zi; production progression is untouched.
const WORLD := preload("res://scenes/main.tscn")
const BLORB_SCENE := preload("res://scenes/blorb.tscn")
const MONKEY_SCENE := preload("res://scenes/xiao_hou_zi.tscn")
const CITY_START := Vector2(-600.0, 0.0)


func _ready() -> void:
	WorldState.opening_wake_completed = true
	WorldState.game_time_hours = 12.0
	LoadingScreen.begin_transition()
	var authored := WORLD.instantiate()
	var keep := ["WorldEnvironment", "DirectionalLight3D", "DayNightCycle", "Terrain", "WesternCity", "Player", "Blorb1", "Blorb2", "Blorb3"]
	var selected: Array[Node] = []
	for child in authored.get_children():
		if String(child.name) in keep:
			authored.remove_child(child)
			selected.append(child)
	authored.free()
	for child in selected:
		if child.name == "Blorb1":
			(child as Blorb).initial_element = "plant"
		add_child(child)
	var terrain := get_node("Terrain")
	var ground: float = terrain.get_mesh_height(CITY_START.x, CITY_START.y)
	var player := get_node("Player") as Player
	player.global_position = Vector3(CITY_START.x, ground + 0.5, CITY_START.y)
	for i in 3:
		var blorb := get_node("Blorb%d" % (i + 1)) as Blorb
		blorb.in_party = true
		blorb.global_position = player.global_position + Vector3(float(i - 1) * 2.0, 0.0, 3.0)
	# Two genuine Fighting companions exercise the current free-blorb combat
	# behavior in the city. merge_element("fighting") supplies each one's
	# Boxing Gloves through the same path used by normal progression.
	for i in 2:
		var fighter := BLORB_SCENE.instantiate() as Blorb
		fighter.name = "QA_FightingBlorb%d" % (i + 1)
		fighter.in_party = true
		fighter.initial_element = "fighting"
		fighter.position = player.position + Vector3(-3.0 + float(i) * 6.0, 0.0, 5.0)
		add_child(fighter)
	var air_companion := BLORB_SCENE.instantiate() as Blorb
	air_companion.name = "QA_AirBlorb"
	air_companion.in_party = true
	air_companion.initial_element = "air"
	air_companion.position = player.position + Vector3(0.0, 0.5, 7.0)
	add_child(air_companion)
	var human_members: Array[Blorb] = []
	for slot in ["head", "torso", "arm_left", "arm_right", "leg_left", "leg_right"]:
		if slot == "head":
			human_members.append(get_node("Blorb1") as Blorb)
		else:
			human_members.append(_make_plant_member("QA_Human_%s" % slot, Vector3(8.0 + human_members.size() * 1.5, 0.0, 6.0)))
	human_members[0].add_core_item("Leaf Hat")
	set_meta("qa_human_plant_suit", human_members)
	var monkey := MONKEY_SCENE.instantiate() as XiaoHouZi
	monkey.name = "DebugXiaoHouZi"
	monkey.in_party = true
	monkey.position = player.position + Vector3(4.0, 0.0, 2.0)
	add_child(monkey)
	_finish.call_deferred()


func _finish() -> void:
	await LoadingScreen.wait_for_world_builds()
	await get_tree().process_frame
	var player := get_node("Player") as Player
	var suit := player.get_own_blorb_suit()
	var human_members: Array = get_meta("qa_human_plant_suit")
	_apply_full_plant_suit(suit, human_members)
	suit.toggle()
	while suit.is_transitioning(): await get_tree().process_frame
	var city := get_node("WesternCity")
	city.set_meta("moy_force_hotel_pack", true)
	var waited := 0
	while not bool(city.call("moy_packs_ready")) and waited < 1800:
		waited += 1
		await get_tree().process_frame
	if not bool(city.call("moy_packs_ready")):
		push_error("Moy QA startup timed out waiting for static city packs")
		LoadingScreen.complete()
		return
	while not bool(city.call("moy_actors_ready")) and waited < 2000:
		waited += 1
		await get_tree().process_frame
	print("MOY_QA packs_ready_frames=", waited, " bodies=", city.call("_count_physics_bodies", city), " full_plant_suit=6 handover=PartyControl")
	LoadingScreen.complete()
	Hud.show_message("MOY QA: WASD move, mouse look, Space jump/throw/release Leaf Hat vine, Q/E arm steering, N switch party control. Party: one Air blorb and two Fighting blorbs with Boxing Gloves.")
	set_meta("qa_ready", true)


func _make_plant_member(member_name: String, offset: Vector3) -> Blorb:
	var member := BLORB_SCENE.instantiate() as Blorb
	member.name = member_name
	member.in_party = true
	member.initial_element = "plant"
	member.position = (get_node("Player") as Player).position + offset
	add_child(member)
	return member


func _apply_full_plant_suit(suit: BlorbSuitController, members: Array) -> void:
	var slots := ["head", "torso", "arm_left", "arm_right", "leg_left", "leg_right"]
	for i in slots.size():
		suit.equip_to_slot(members[i] as Blorb, slots[i])
