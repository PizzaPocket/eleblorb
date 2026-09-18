extends Node

## TEMPORARY test scaffold. Normal loading still enters the Crossroads, then
## this gives a fresh run a Blorbus already wearing the Bird Helm on his head
## (Blorbaka's own core item -- see blorb_suit.gd/false_hero_nme.gd) and an
## Air blorb on his chest, so the Sky Kingdom's visibility gate and the Bird
## Helm's own design can both be playtested immediately without first
## fighting through the false hero for real. WorldState prevents the payload
## duplicating after kingdom travel.
const BLORB_SCENE: PackedScene = preload("res://scenes/blorb.tscn")
const XIAO_HOU_ZI_SCENE: PackedScene = preload("res://scenes/xiao_hou_zi.tscn")
const MANCHEGO_SCENE: PackedScene = preload("res://scenes/manchego.tscn")
const TEST_LEVEL := 30
## TEMPORARY, for camera/movement playtesting: start the run on the lake
## shore with the party, a rideable Manchego, and throwable gems in hand.
const LAKESIDE_START := true
## A point in the open lake. The bank search walks outward from here in every
## direction and keeps the flattest clear dry spot beside shallow water.
const LAKE_PROBE := Vector2(420.0, 0.0)
const BANK_SEARCH_RAYS := 180
## Dry but low: above the waterline, below the wasteland's raised rim.
const BANK_MIN_HEIGHT_ABOVE_WATER := 0.3
const BANK_MAX_HEIGHT_ABOVE_WATER := 3.0
## Largest height difference allowed anywhere within BANK_LEVEL_RADIUS, which
## rejects the plateau cliff foot and steep rim slopes.
const BANK_LEVEL_RADIUS := 8.0
const BANK_MAX_HEIGHT_SPREAD := 1.5
## The lakebed this far out from the shoreline must not drop deeper than
## BANK_MAX_ENTRY_DEPTH, so the water can be waded into rather than a drop-off.
const BANK_ENTRY_PROBE := 6.0
const BANK_MAX_ENTRY_DEPTH := 2.5
const THROW_TEST_ITEM := "Fire Gem"
const THROW_TEST_COUNT := 5

func _ready() -> void:
	# The wake intro frames the face from the spawn camera; after the lakeside
	# teleport it would open on the back of the head. main.gd reads this flag
	# only after the world finishes building, well after this _ready().
	if LAKESIDE_START and not WorldState.debug_crossroads_loadout_applied:
		WorldState.opening_wake_completed = true
	call_deferred("_install_test_loadout")

func _install_test_loadout() -> void:
	if WorldState.debug_crossroads_loadout_applied:
		return
	await get_tree().create_timer(0.15).timeout
	var world := get_parent()
	var player := world.get_node("Player") as Player
	var origin := player.global_position

	var blorbus: Blorb = null
	for node_name in ["Blorb1", "Blorb2", "Blorb3"]:
		var starter := world.get_node_or_null(node_name) as Blorb
		if starter != null:
			blorbus = starter
			break
	if blorbus == null:
		blorbus = BLORB_SCENE.instantiate() as Blorb
		blorbus.in_party = true
		blorbus.position = origin + Vector3(-1.15, 0, -2.5)
		world.add_child(blorbus)
	blorbus.is_starter_trio = false
	blorbus.become_blorbus()
	blorbus.add_core_item("Bird Helm")
	_set_test_level(blorbus)

	var air_blorb := BLORB_SCENE.instantiate() as Blorb
	air_blorb.in_party = true
	air_blorb.initial_element = "air"
	air_blorb.position = origin + Vector3(1.15, 0, -2.5)
	world.add_child(air_blorb)
	_set_test_level(air_blorb)

	# Per direct request, so flight/swim can be A/B tested between the human
	# and Xiao Hou Zi without first fighting through the jungle to recruit
	# him for real. Only the "in_party" flag actually matters for
	# _try_start_xiao_hou_zi_control()'s own eligibility check (see
	# player.gd) -- everything else (groups, PartyControl registration) is
	# handled by his own _ready(), same as any real recruitment moment.
	if world.get_node_or_null("DebugXiaoHouZi") == null:
		var monkey := XIAO_HOU_ZI_SCENE.instantiate() as XiaoHouZi
		monkey.name = "DebugXiaoHouZi"
		monkey.in_party = true
		monkey.position = origin + Vector3(0.0, 0, -3.6)
		world.add_child(monkey)

	# Debug setup belongs to the human character regardless of which playable
	# PartyControl may have restored as the current perspective -- same
	# reasoning as ice_kingdom_test_setup.gd's own identical comment.
	var suit := player.get_own_blorb_suit()
	suit.equip_to_slot(blorbus, "head")
	suit.equip_to_slot(air_blorb, "torso")
	# Per direct correction, the suit starts OFF (not toggled on) -- the
	# wake-up/stand-up camera intro was getting cut short specifically when
	# the run began already wearing a suit. The assignments above are still
	# in place, so the player can toggle the suit on themselves once ready.
	WorldState.debug_crossroads_loadout_applied = true
	if LAKESIDE_START:
		await _start_at_lakeside(world, player)

func _set_test_level(blorb: Blorb) -> void:
	if blorb == null or blorb.level >= TEST_LEVEL:
		return
	var snapshot := blorb.progression_snapshot()
	for next_level in range(blorb.level+1,TEST_LEVEL+1):
		snapshot["strength"] = int(snapshot["strength"])+1+(1 if next_level%4 == 0 else 0)
		snapshot["defense"] = int(snapshot["defense"])+1+(1 if next_level%5 == 0 else 0)
		snapshot["speed"] = int(snapshot["speed"])+1+(1 if next_level%6 == 0 else 0)
		snapshot["max_hp"] = int(snapshot["max_hp"])+4+ceili(float(next_level)/5.0)
		snapshot["max_mp"] = int(snapshot["max_mp"])+2+ceili(float(next_level)/8.0)
	snapshot["level"] = TEST_LEVEL
	snapshot["experience"] = 0
	blorb.restore_progression(snapshot)



func _start_at_lakeside(world: Node, player: Player) -> void:
	# Lake-rim collision and the canyon slabs are built by deferred jobs;
	# teleporting before they exist would drop the party through the shore.
	await LoadingScreen.wait_for_world_builds()
	var terrain := world.get_node("Terrain")
	var bank := _find_clear_bank(terrain)
	if bank.is_empty():
		push_warning("Lakeside test start: no clear bank found; keeping the normal spawn.")
		return
	var stand: Vector3 = bank["stand"]
	var toward_water: Vector3 = bank["toward_water"]
	var landward := -toward_water
	var across := Vector3(-toward_water.z, 0.0, toward_water.x)
	player.global_position = stand + Vector3.UP * Player.FOOT_OFFSET
	# Face the water with the camera behind. Visuals faces its own +Z; the
	# camera views along the rig's -Z.
	player.visuals.rotation.y = atan2(toward_water.x, toward_water.z)
	player.camera_rig.rotation.y = atan2(-toward_water.x, -toward_water.z)
	player.velocity = Vector3.ZERO

	# Party members follow the player, but walking ~300 m from the spawn
	# would take a while. Place them in a loose arc on the landward side.
	var followers: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("blorbs"):
		var blorb := node as Blorb
		if blorb != null and blorb.in_party and not blorb.is_worn:
			followers.append(blorb)
	var monkey := world.get_node_or_null("DebugXiaoHouZi") as Node3D
	if monkey != null:
		followers.append(monkey)
	for index in followers.size():
		var offset := landward * 3.0 + across * (-3.0 + 2.0 * index)
		_place_on_ground(terrain, followers[index], stand + offset)

	var manchego := MANCHEGO_SCENE.instantiate() as Manchego
	manchego.follows_player = true
	manchego.available_to_player = true
	world.add_child(manchego)
	_place_on_ground(terrain, manchego, stand + across * 5.0 + landward * 1.5)

	for _count in THROW_TEST_COUNT:
		Inventory.add(THROW_TEST_ITEM, ShopCatalog.FIRE_COLOR)
	for item in Inventory.items:
		if item["name"] == THROW_TEST_ITEM:
			HeldItem.equip(item)
			break


func _place_on_ground(terrain: Node, body: Node3D, point: Vector3) -> void:
	point.y = terrain.get_mesh_height(point.x, point.z)
	body.global_position = point


## Returns {"stand": Vector3 on the ground, "toward_water": flat unit Vector3},
## or {} if no candidate passes every check.
func _find_clear_bank(terrain: Node) -> Dictionary:
	var water: float = terrain.get_lake_water_level()
	var space := get_viewport().find_world_3d().direct_space_state
	var best := {}
	var best_score := INF
	for ray in BANK_SEARCH_RAYS:
		var direction := Vector2.from_angle(TAU * float(ray) / float(BANK_SEARCH_RAYS))
		var edge := LAKE_PROBE
		while terrain.is_lake_area(edge) and edge.distance_to(LAKE_PROBE) < 900.0:
			edge += direction * 2.0
		if terrain.is_lake_area(edge):
			continue
		var wet := edge - direction * BANK_ENTRY_PROBE
		var wet_height: float = terrain.get_mesh_height(wet.x, wet.y)
		if wet_height < water - BANK_MAX_ENTRY_DEPTH:
			continue
		for extra in [3.0, 5.0, 8.0, 12.0]:
			var spot: Vector2 = edge + direction * float(extra)
			var height: float = terrain.get_mesh_height(spot.x, spot.y)
			if height < water + BANK_MIN_HEIGHT_ABOVE_WATER or height > water + BANK_MAX_HEIGHT_ABOVE_WATER:
				continue
			var spread := _height_spread(terrain, spot)
			if spread > BANK_MAX_HEIGHT_SPREAD:
				continue
			var stand := Vector3(spot.x, height, spot.y)
			if not _is_clear(space, terrain, stand):
				continue
			var score := spread + float(extra) * 0.05
			if score < best_score:
				best_score = score
				best = {"stand": stand, "toward_water": Vector3(-direction.x, 0.0, -direction.y)}
	return best


func _height_spread(terrain: Node, center: Vector2) -> float:
	var low := INF
	var high := -INF
	for index in 12:
		var sample := center + Vector2.from_angle(TAU * float(index) / 12.0) * BANK_LEVEL_RADIUS
		var height: float = terrain.get_mesh_height(sample.x, sample.y)
		low = minf(low, height)
		high = maxf(high, height)
	var middle: float = terrain.get_mesh_height(center.x, center.y)
	return maxf(high, middle) - minf(low, middle)


## True when nothing solid other than the ground occupies the space a
## standing character and the party beside them would need.
func _is_clear(space: PhysicsDirectSpaceState3D, terrain: Node, stand: Vector3) -> bool:
	var probe := SphereShape3D.new()
	probe.radius = 2.5
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = probe
	query.transform = Transform3D(Basis(), stand + Vector3.UP * 2.8)
	query.collision_mask = 1
	if terrain is CollisionObject3D:
		query.exclude = [(terrain as CollisionObject3D).get_rid()]
	return space.intersect_shape(query, 1).is_empty()
