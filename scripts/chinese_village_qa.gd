extends Node3D

## Isolated, playable construction review. Reuses the real terrain, player,
## settlement, collision and quest actors without staging other settlements.
const WORLD := preload("res://scenes/main.tscn")
const PLAN := preload("res://scripts/chinese_plan.gd")
const MOUNT := preload("res://scenes/manchego.tscn")


func _ready() -> void:
	WorldState.opening_wake_completed=true
	WorldState.game_time_hours=12.0
	LoadingScreen.begin_transition()
	var authored := WORLD.instantiate()
	var keep := ["WorldEnvironment","DirectionalLight3D","DayNightCycle","Terrain","ChineseVillage","Player","Blorb1","Blorb2","Blorb3"]
	var children: Array[Node]=[]
	for child in authored.get_children():
		if String(child.name) in keep:
			authored.remove_child(child)
			children.append(child)
	# Free all unwanted generators before any of them enters the SceneTree.
	authored.free()
	var start := Vector2.ZERO
	for item in PLAN.ITEMS:
		if item.key=="front_court": start=Vector2(item.centre[0],item.centre[1])
	for child in children:
		if child.name=="ChineseVillage": child.set("stream_detail",false)
		if child.name=="Player":
			(child as Node3D).position=Vector3(250+start.x,1,-650+start.y)
		add_child(child)
	var terrain := get_node("Terrain")
	var ground: float=terrain.get_chinese_village_island_surface_y()
	var player := get_node("Player") as Node3D
	player.position.y=ground+0.5
	for i in 3:
		get_node("Blorb%d" % (i+1)).position=player.position+Vector3((i-1)*2.0,0,3.0)
	_finish.call_deferred()


func _finish() -> void:
	await LoadingScreen.wait_for_world_builds()
	var player := get_node("Player") as Node3D
	var blorbus := preload("res://scenes/blorb.tscn").instantiate() as Blorb
	blorbus.in_party=true
	blorbus.position=player.position+Vector3(-5,0,3)
	add_child(blorbus)
	blorbus.become_blorbus()
	var mount := MOUNT.instantiate() as Manchego
	mount.position=player.position+Vector3(5,0,3)
	mount.available_to_player=true
	add_child(mount)
	LoadingScreen.complete()
