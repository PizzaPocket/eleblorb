@tool
extends Node3D

## A dense far-west wasteland district: compact blocks, narrow walkable
## streets, and deliberately varied 6-20 floor towers. Unlike the village
## markers, this is a repeatable urban plan whose streets remain readable.

const NPC_SCENE := "res://scenes/npc.tscn"
# Far beyond the canyon and the giant's route, including the farthest edge
# of the street grid.
const CITY_CENTER := Vector2(-540, 0)
const BLOCK_X := [-48.0, -16.0, 16.0, 48.0]
const BLOCK_Z := [-34.0, 0.0, 34.0]
const HEIGHTS := [8, 14, 20, 11, 17, 7, 15, 19, 10, 13, 6, 16, 9, 18, 12, 5, 16, 8, 20, 11, 14, 7, 18, 10]
const CITY_NAMES := ["Juno Rell", "Kade Morrow", "Suri Vale", "Tomas Wren", "Nia Calder", "Orin Pike", "Mara Quill", "Venn Harlow", "Iris Dune", "Sol Brant", "Pia Rowe", "Dax Merrow"]
# One entry per CITY_NAMES, same index -- each resident gets their own two
# lines instead of every instance sharing one pool, matching
# town_generator.gd's VILLAGER_IDENTITIES pattern (see that const's own
# comment for why the sharing read as generic instead of individuated).
const CITY_RESIDENT_LINES := [
	[
		"Twenty floors and I still take the stairs some mornings. Keeps the knees honest, or so I tell myself.",
		"You crossed over through the gate? I've lived here my whole life and still don't fully understand how that works.",
	],
	[
		"The skybridges look flimsier than they are. I've crossed that one out there a thousand times without a wobble.",
		"Every tower's got its own creak at night. You learn which ones are normal and which ones mean call someone.",
	],
	[
		"I like this city best right after the lights come on. Every window looks like it's got a story going on inside.",
		"Nobody down at street level looks up much. Missing the best part of living here, if you ask me.",
	],
	[
		"I run deliveries floor to floor all day. Elevators are faster, stairs are more reliable. Guess which one I use.",
		"You get used to the height eventually. The first week here, though, I couldn't look out a window without my stomach turning.",
	],
	[
		"This whole district used to be one uninterrupted skyline, or so the old maps show. It's still going, far as anyone's walked.",
		"I keep meaning to count the towers from the block. Lost track somewhere past two hundred, gave up after that.",
	],
	[
		"Ask me about anything except the weather. Up here the sky just does what it wants and nobody argues.",
		"Some nights the wind between the towers howls loud enough you'd swear something was calling through it.",
	],
	[
		"I've never seen the town on the other side of the gate. Heard it's got a fountain. Can't imagine a city without one either.",
		"People say this place mirrors something. Never asked what. Didn't seem like a question with a comfortable answer.",
	],
	[
		"Same commute every day, different tower, same fifteen floors. I've stopped noticing the numbers, honestly.",
		"You get a different city depending which block you sleep in. Mine's quiet. I hear some of the others never sleep at all.",
	],
	[
		"I keep a plant on my windowsill on the eleventh floor. Don't ask me how it's still alive up here.",
		"Most people mind their own business in this city. I don't mind. Makes the ones who don't stand out.",
	],
	[
		"Been meaning to visit the Helmsmith's shop. Never quite make the walk. Tomorrow, maybe.",
		"The towers block the sunrise most mornings. By the time it clears the roofline, half the day's already moving.",
	],
	[
		"I like the noise down at street level better than the quiet up top. Some people say that backwards. I don't care.",
		"You get good at reading distances here. Everything's either two blocks or twenty floors, nothing in between.",
	],
	[
		"I've lived on six different floors of this same tower. Moved twice for the view, four times for the rent.",
		"Doesn't bother me that nobody remembers how the gate works. I just remember which floor is mine.",
	],
]
## Two city distance tiers: inexpensive tower shells keep the skyline visible
## from the plateau, while the detailed playable city wakes only nearby.
const ROOM_LIGHT_RADIUS := 20.0
const NPC_SIMULATION_RADIUS := 60.0
const LIGHT_LOD_UPDATE_INTERVAL := 0.25
const CITY_WAKE_RADIUS := 300.0
const CITY_SLEEP_RADIUS := 345.0
const CITY_SKYLINE_WAKE_RADIUS := 720.0
const CITY_SKYLINE_SLEEP_RADIUS := 770.0

var terrain: Node
var _rng := RandomNumberGenerator.new()
var _city_blocks: Array[Node3D] = []
var _light_lod_timer := 0.0
var _city_zone_active := true
var _city_skyline_visible := false

func _ready() -> void:
	terrain = get_node("../Terrain")
	_rebuild()

func _rebuild() -> void:
	var old := get_node_or_null("Generated")
	if old:
		old.free()
	var old_skyline := get_node_or_null("Skyline")
	if old_skyline:
		old_skyline.free()
	var generated := Node3D.new()
	generated.name = "Generated"
	add_child(generated)
	_rng.seed = 2095
	_city_blocks.clear()
	_build_grid(generated)
	_build_towers(generated)
	_build_city_skyline()
	for block in _city_blocks:
		_materialize_block(block)
	_build_skybridges(generated)
	_spawn_residents(generated)
	_spawn_city_helm_vendor(generated)
	_update_city_zone_from_player()
	# A hot reload can rebuild Generated while the zone is already asleep;
	# apply the current state explicitly so the replacement does not wake
	# until the player actually returns to the western travel range.
	_set_city_children_active(generated, _city_zone_active)
	_set_city_skyline_visible(_city_skyline_visible)

func _process(delta: float) -> void:
	_light_lod_timer -= delta
	if _light_lod_timer <= 0.0:
		_light_lod_timer = LIGHT_LOD_UPDATE_INTERVAL
		_update_city_zone_from_player()
		if _city_zone_active:
			_update_room_lights_from_player()


func _update_city_zone_from_player() -> void:
	var player := get_node_or_null("../Player") as Node3D
	if player == null:
		return
	var distance := Vector2(player.global_position.x, player.global_position.z).distance_to(CITY_CENTER)
	if _city_zone_active and distance >= CITY_SLEEP_RADIUS:
		_set_city_zone_active(false)
	elif not _city_zone_active and distance <= CITY_WAKE_RADIUS:
		_set_city_zone_active(true)
	if _city_zone_active:
		_set_city_skyline_visible(false)
	elif _city_skyline_visible and distance >= CITY_SKYLINE_SLEEP_RADIUS:
		_set_city_skyline_visible(false)
	elif not _city_skyline_visible and distance <= CITY_SKYLINE_WAKE_RADIUS:
		_set_city_skyline_visible(true)


## Frustum culling already avoids most off-camera draw calls, but it does
## not stop off-screen collision bodies, NPC scripts, or shadow casting.
## Hibernate the whole generated district beyond the western travel zone;
## the wide wake/sleep gap keeps this transition invisible to the player.
func _set_city_zone_active(active: bool) -> void:
	if _city_zone_active == active:
		return
	_city_zone_active = active
	var generated := get_node_or_null("Generated") as Node3D
	if generated == null:
		return
	_set_city_children_active(generated, active)
	if active:
		_update_room_lights_from_player()
		_set_city_skyline_visible(false)


## The far tier contains only the large tower volumes: 24 opaque boxes with
## no collision, lights, shadows, NPCs, windows, or interior geometry. It
## gives the player a stable far-west landmark without paying for the full
## city until they are travelling toward it.
func _build_city_skyline() -> void:
	var skyline := Node3D.new()
	skyline.name = "Skyline"
	add_child(skyline)
	for block in _city_blocks:
		var tower_specs: Array = block.get_meta("tower_specs")
		for raw_spec in tower_specs:
			var spec: Dictionary = raw_spec
			var width := float(int(spec["width"])) * TownProps.CELL_SIZE
			var depth := float(int(spec["depth"])) * TownProps.CELL_SIZE
			var height := float(int(spec["floors"])) * TownProps.FLOOR_HEIGHT
			var world: Vector2 = spec["world"]
			var shell_mesh := BoxMesh.new()
			shell_mesh.size = Vector3(width, height, depth)
			var shell := MeshInstance3D.new()
			shell.mesh = shell_mesh
			var material := StandardMaterial3D.new()
			material.albedo_color = TownProps.CITY_CONCRETE.lerp(spec["accent"], 0.12)
			material.roughness = 0.9
			shell.material_override = material
			shell.position = Vector3(world.x, _ground(world) + height * 0.5, world.y)
			shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			skyline.add_child(shell)


func _set_city_skyline_visible(visible: bool) -> void:
	var skyline := get_node_or_null("Skyline") as Node3D
	if skyline == null:
		return
	_city_skyline_visible = visible
	for child in skyline.get_children():
		if child is VisualInstance3D:
			(child as VisualInstance3D).visible = visible


func _set_city_children_active(node: Node, active: bool) -> void:
	for child in node.get_children():
		if child is VisualInstance3D:
			(child as VisualInstance3D).visible = active
		if child is CollisionObject3D:
			var body := child as CollisionObject3D
			if not body.has_meta("city_collision_layer"):
				body.set_meta("city_collision_layer", body.collision_layer)
			body.collision_layer = int(body.get_meta("city_collision_layer")) if active else 0
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			if not geometry.has_meta("city_shadow_mode"):
				geometry.set_meta("city_shadow_mode", geometry.cast_shadow)
			geometry.cast_shadow = int(geometry.get_meta("city_shadow_mode")) if active else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if child.is_in_group("city_npcs"):
			child.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		_set_city_children_active(child, active)

func _ground(pos: Vector2) -> float:
	return terrain.get_mesh_height(pos.x, pos.y)

func _build_grid(parent: Node3D) -> void:
	# Three avenues and four cross streets. Roads are created after sidewalks
	# below so the darker carriageway stays visibly on top at every crossing.
	for x in [-32.0, 0.0, 32.0]:
		for side in [-1.0, 1.0]:
			_add_sidewalk(parent, Vector2(x + side * 5.4, 0), Vector2(2.6, 112.0))
	for z in [-17.0, 17.0]:
		for side in [-1.0, 1.0]:
			_add_sidewalk(parent, Vector2(0, z + side * 5.4), Vector2(112.0, 2.6))
	for x in [-32.0, 0.0, 32.0]:
		_add_road(parent, Vector2(x, 0), Vector2(8.0, 112.0))
	for z in [-17.0, 17.0]:
		_add_road(parent, Vector2(0, z), Vector2(112.0, 8.0))
	for x in [-32.0, 0.0, 32.0]:
		for z in [-17.0, 17.0]:
			# Each arm points from its sidewalk corner into the road beside it.
			_add_streetlight(parent, Vector2(x - 5.7, z - 5.7), Vector2(1, 0))
			_add_streetlight(parent, Vector2(x + 5.7, z + 5.7), Vector2(-1, 0))
			_add_streetlight(parent, Vector2(x - 5.7, z + 5.7), Vector2(0, -1))
			_add_streetlight(parent, Vector2(x + 5.7, z - 5.7), Vector2(0, 1))
	# Repeated but varied street furniture gives the sidewalks scale and
	# creates low cover / first-jump platforms along the city routes.
	for x in [-46.0, -14.0, 18.0, 46.0]:
		for z in [-27.0, 27.0]:
			_add_street_objects(parent, Vector2(x, z))

func _add_road(parent: Node3D, local_pos: Vector2, size: Vector2) -> void:
	var world := CITY_CENTER + local_pos
	var slab := TownProps.build_city_pavement(size, Color(0.16, 0.18, 0.2), 0.08)
	# Keep the road's visible surface above the sidewalk slab. This prevents sidewalk
	# strips from visually cutting across intersections.
	slab.position = Vector3(world.x, _ground(world) + 0.12, world.y)
	parent.add_child(slab)

func _add_sidewalk(parent: Node3D, local_pos: Vector2, size: Vector2) -> void:
	var world := CITY_CENTER + local_pos
	var slab := TownProps.build_city_pavement(size, Color(0.44, 0.42, 0.38), 0.14)
	slab.position = Vector3(world.x, _ground(world) + 0.08, world.y)
	parent.add_child(slab)

func _add_streetlight(parent: Node3D, local_pos: Vector2, overhang_direction: Vector2) -> void:
	var world := CITY_CENTER + local_pos
	var lamp := TownProps.build_city_streetlight()
	lamp.position = Vector3(world.x, _ground(world), world.y)
	# The city lamp's arm is authored along local -Z; rotate it toward the
	# adjacent street instead of leaving every mast facing the same way.
	lamp.rotation.y = atan2(-overhang_direction.x, -overhang_direction.y)
	parent.add_child(lamp)

func _add_street_objects(parent: Node3D, local_pos: Vector2) -> void:
	var world := CITY_CENTER + local_pos
	var bin := TownProps.build_crate(Vector3(0.8, 0.9, 0.8), TownProps.CITY_DARK_CONCRETE)
	bin.position = Vector3(world.x, _ground(world), world.y)
	parent.add_child(bin)
	var rail := TownProps.build_fence_segment(TownProps.CITY_CONCRETE)
	rail.position = Vector3(world.x + 1.4, _ground(world + Vector2(1.4, 0)), world.y)
	rail.rotation.y = PI * 0.5
	parent.add_child(rail)

func _build_towers(parent: Node3D) -> void:
	var index := 0
	for z in BLOCK_Z:
		for x in BLOCK_X:
			var block := Node3D.new()
			block.name = "CityBlock_%d" % _city_blocks.size()
			block.set_meta("center", CITY_CENTER + Vector2(x, z))
			block.set_meta("built", false)
			parent.add_child(block)
			_city_blocks.append(block)
			var tower_specs: Array[Dictionary] = []
			# Each city block holds a compact pair rather than one isolated tower.
			# Their offset, footprint, height, and façade accent all vary, creating
			# the dense stacked skyline in the reference images.
			for offset: Vector2 in [Vector2(-5.5, -5.0), Vector2(5.5, 5.0)]:
				var local: Vector2 = Vector2(x, z) + offset
				var world := CITY_CENTER + local
				var width_cells := 2 + (index % 3)
				var depth_cells := 2 + (int(index / 3) % 2)
				tower_specs.append({
					"world": world,
					"width": width_cells,
					"depth": depth_cells,
					"floors": HEIGHTS[index],
					"accent": TownProps.CITY_ACCENTS[index % TownProps.CITY_ACCENTS.size()],
					"light_seed": index,
					"rotation": PI if index % 2 == 0 else 0.0,
				})
				index += 1
			block.set_meta("tower_specs", tower_specs)


## Six enclosed routes span the avenues between paired towers. They connect
## through the person-sized side openings already present in every storey,
## creating elevated shortcuts without adding more ground-level clutter.
func _build_skybridges(parent: Node3D) -> void:
	var bridges := Node3D.new()
	bridges.name = "Skybridges"
	parent.add_child(bridges)
	for row in 3:
		var left_block := _city_blocks[row * 4]
		var middle_block := _city_blocks[row * 4 + 1]
		var right_block := _city_blocks[row * 4 + 2]
		var far_block := _city_blocks[row * 4 + 3]
		var left_specs: Array = left_block.get_meta("tower_specs")
		var middle_specs: Array = middle_block.get_meta("tower_specs")
		var right_specs: Array = right_block.get_meta("tower_specs")
		var far_specs: Array = far_block.get_meta("tower_specs")
		var left_tower: Dictionary = left_specs[0]
		var middle_tower: Dictionary = middle_specs[0]
		var right_tower: Dictionary = right_specs[1]
		var far_tower: Dictionary = far_specs[1]
		_add_skybridge_between(bridges, left_tower, middle_tower)
		_add_skybridge_between(bridges, right_tower, far_tower)


func _add_skybridge_between(parent: Node3D, left_spec: Dictionary, right_spec: Dictionary) -> void:
	var left_world: Vector2 = left_spec["world"]
	var right_world: Vector2 = right_spec["world"]
	var left_width := float(int(left_spec["width"])) * TownProps.CELL_SIZE
	var right_width := float(int(right_spec["width"])) * TownProps.CELL_SIZE
	var span := absf(right_world.x - left_world.x) - (left_width + right_width) * 0.5 + 0.22
	if span <= 1.0:
		return
	# Leave at least two complete floors above the passage, but vary the link
	# level between rows to make the skyline read as a network rather than a
	# uniform sky rail.
	var shared_floors: int = mini(int(left_spec["floors"]), int(right_spec["floors"]))
	var level: int = maxi(2, shared_floors - 3 - (int(left_spec["light_seed"]) % 3))
	var midpoint: Vector2 = (left_world + right_world) * 0.5
	var bridge := TownProps.build_city_skybridge(span, 1.62, TownProps.CITY_ACCENTS[int(left_spec["light_seed"]) % TownProps.CITY_ACCENTS.size()])
	bridge.position = Vector3(midpoint.x, (_ground(left_world) + _ground(right_world)) * 0.5 + float(level) * TownProps.FLOOR_HEIGHT, midpoint.y)
	parent.add_child(bridge)

func _spawn_residents(parent: Node3D) -> void:
	# NPC scenes are runtime scripts and become placeholder instances while
	# this @tool generator previews the city in the editor.
	if Engine.is_editor_hint():
		return
	var packed := load(NPC_SCENE) as PackedScene
	if packed == null:
		return
	for i in CITY_NAMES.size():
		var local := Vector2(-43.0 + float(i % 4) * 29.0, -42.0 + float(i / 4) * 38.0)
		var world := CITY_CENTER + local
		var npc := packed.instantiate()
		npc.set_terrain_reference(terrain)
		npc.display_name = CITY_NAMES[i]
		npc.is_female = i % 2 == 0
		npc.skin_color = Color(0.35 + 0.05 * float(i % 6), 0.23 + 0.06 * float((i + 2) % 6), 0.16 + 0.05 * float(i % 5))
		npc.shirt_color = TownProps.CITY_ACCENTS[i % TownProps.CITY_ACCENTS.size()]
		npc.pants_color = Color(0.12, 0.16 + 0.03 * float(i % 3), 0.2)
		npc.shoe_color = TownProps.CITY_ACCENTS[(i + 2) % TownProps.CITY_ACCENTS.size()].darkened(0.2)
		npc.hair_color = Color(0.08 + 0.08 * float(i % 4), 0.06, 0.04)
		npc.hair_style = FigureHair.STYLE_LONG if npc.is_female else FigureHair.STYLE_FLAT_TOP
		npc.body_scale = 0.9 + 0.04 * float(i % 5)
		npc.chest_build_scale = 0.9 + 0.07 * float((i + 1) % 4)
		npc.hip_build_scale = 0.94 + 0.05 * float(i % 4)
		npc.abdomen_width_scale = 1.0 + 0.06 * float(i % 4)
		npc.sleeve_style = ProceduralFigure.SLEEVE_STYLE_SHORT if i % 3 == 0 else ProceduralFigure.SLEEVE_STYLE_LONG
		# npc.gd declares talk_lines as Array[String], so copy the literal into
		# a typed array exactly as town_generator.gd does for village dialogue.
		var lines: Array[String] = []
		lines.assign(CITY_RESIDENT_LINES[i])
		npc.talk_lines = lines
		npc.position = Vector3(world.x, _ground(world), world.y)
		npc.add_to_group("city_npcs")
		_nearest_block(world).add_child(npc)


## Street-level vendor placed at the entrance side of a ground-floor tower.
## The tower still owns the surrounding façade/interior volume; the vendor
## occupies its open street-facing threshold so players can interact.
func _spawn_city_helm_vendor(parent: Node3D) -> void:
	var block := _city_blocks[5]
	var specs: Array = block.get_meta("tower_specs")
	var shop_spec: Dictionary = specs[1]
	var tower := block.get_node_or_null("Tower_%s" % shop_spec["light_seed"]) as StaticBody3D
	if tower == null:
		return
	_build_helmsmith_storefront(tower, shop_spec)
	if Engine.is_editor_hint():
		return
	var packed := load(NPC_SCENE) as PackedScene
	if packed == null:
		return
	var vendor = packed.instantiate()
	vendor.set_terrain_reference(terrain)
	vendor.stationary = true
	vendor.is_vendor = true
	vendor.display_name = "Helmsmith"
	vendor.shop_category = "city"
	var vendor_lines: Array[String] = [
		"A good helm does not ask who is inside it. This one will fit a blorb just fine.",
		"A core takes one head-shape at a time. Choose a sealed diver's hood or a knight's steel.",
	]
	vendor.vendor_lines = vendor_lines
	vendor.skin_color = Color(0.38, 0.24, 0.16)
	vendor.shirt_color = Color(0.23, 0.25, 0.29)
	vendor.pants_color = Color(0.12, 0.14, 0.17)
	vendor.hair_color = Color(0.12, 0.1, 0.08)
	vendor.hair_style = FigureHair.STYLE_FLAT_TOP
	var depth := float(int(shop_spec["depth"])) * TownProps.CELL_SIZE
	var width := float(int(shop_spec["width"])) * TownProps.CELL_SIZE
	# Stand behind the interior counter with a clear view of the main front
	# entrance, rather than occupying either doorway's circulation path.
	vendor.position = Vector3(width * 0.18, 0.0, depth * 0.5 - 0.82)
	vendor.facing_degrees = 180.0
	vendor.add_to_group("city_npcs")
	tower.add_child(vendor)


## A dedicated, painted ground-floor frontage makes the helm vendor legible
## from the sidewalk even amid the city's muted tower facades. It is built
## from the same visible superegg panels as the rest of the world.
func _build_helmsmith_storefront(tower: StaticBody3D, spec: Dictionary) -> void:
	var shop := Node3D.new()
	shop.name = "HelmsmithStorefront"
	tower.add_child(shop)
	var width := float(int(spec["width"])) * TownProps.CELL_SIZE
	var depth := float(int(spec["depth"])) * TownProps.CELL_SIZE
	var half_width := width * 0.5
	var half_depth := depth * 0.5
	var teal := Color(0.08, 0.46, 0.52)
	var coral := Color(0.82, 0.24, 0.22)
	var gold := Color(0.94, 0.68, 0.15)
	var navy := Color(0.06, 0.1, 0.17)
	_build_helmsmith_room(tower, shop, width, depth, teal, coral)
	# The raised tower's fire-escape landing occupies the old awning zone, so
	# the main entrance stays fully open. Its compact sign sits below that
	# landing but above comfortable head clearance instead of crossing either.
	var front_sign_y := 2.86
	_add_store_part(shop, Vector3(2.05, 0.38, 0.08), Vector3(0, front_sign_y, -half_depth - 0.2), coral, SuperEgg.EPSILON_SOFT)
	_add_store_part(shop, Vector3(0.4, 0.46, 0.07), Vector3(0, front_sign_y, -half_depth - 0.3), Color(0.54, 0.58, 0.62), SuperEgg.EPSILON_SOFT)
	_add_store_part(shop, Vector3(0.3, 0.05, 0.025), Vector3(0, front_sign_y - 0.06, -half_depth - 0.39), navy, SuperEgg.EPSILON_FLAT)
	_build_helmsmith_side_front(shop, half_width, depth, teal, coral, gold, navy)
	_build_helmsmith_lighting(shop, width, half_width, half_depth, teal, coral)
	# Actual wares sit on a back-wall display behind the service counter,
	# visible from the entrance without narrowing either doorway.
	_add_store_part(shop, Vector3(width * 0.27, 0.08, 0.34), Vector3(0, 1.3, half_depth - 0.3), Color(0.28, 0.18, 0.1), SuperEgg.EPSILON_FLAT)
	var item_index := 0
	for raw_item in ShopCatalog.get_items_for_shop("city"):
		var item: Dictionary = raw_item
		if not item.get("purchasable", false):
			continue
		var visual: Node3D = (item["build_visual"] as Callable).call(1.0) as Node3D
		visual.position = Vector3((float(item_index) - 0.5) * 0.82, 1.56, half_depth - 0.3)
		# ShopCatalog models face local +Z. This shelf backs onto the +Z wall,
		# so turn display copies toward the room rather than into the plaster.
		visual.rotation.y = PI
		shop.add_child(visual)
		item_index += 1


## Purpose-built ground floor beneath the raised generic tower. Wide main
## and side entrances have no threshold collision; the counter, back display,
## and vendor zone sit in the far half so arrival and browsing form a clear
## front-to-back path through the room.
func _build_helmsmith_room(
	tower: StaticBody3D, shop: Node3D,
	width: float, depth: float, wall_color: Color, interior_accent: Color
) -> void:
	const MAIN_DOOR_WIDTH := 3.0
	const SIDE_DOOR_WIDTH := 2.4
	const WALL_DEPTH := 0.18
	var height := TownProps.FLOOR_HEIGHT
	var half_w := width * 0.5
	var half_d := depth * 0.5

	_add_shop_architecture_box(tower, "ShopFloor", Vector3(width, 0.16, depth), Vector3(0, 0.08, 0), Color(0.22, 0.18, 0.15))
	# Front wall splits around a generous primary entrance.
	var front_bay := (width - MAIN_DOOR_WIDTH) * 0.5
	for side in [-1.0, 1.0]:
		_add_shop_architecture_box(
			tower, "FrontWall", Vector3(front_bay, height, WALL_DEPTH),
			Vector3(side * (MAIN_DOOR_WIDTH + front_bay) * 0.5, height * 0.5, -half_d), wall_color
		)
	# Back and left walls are calm display surfaces.
	_add_shop_architecture_box(tower, "BackWall", Vector3(width, height, WALL_DEPTH), Vector3(0, height * 0.5, half_d), wall_color)
	_add_shop_architecture_box(tower, "LeftWall", Vector3(WALL_DEPTH, height, depth), Vector3(-half_w, height * 0.5, 0), wall_color)
	# The right wall retains a broad secondary street entrance, but it is no
	# longer the only usable access or the vendor's standing position.
	var side_bay := (depth - SIDE_DOOR_WIDTH) * 0.5
	for z_side in [-1.0, 1.0]:
		_add_shop_architecture_box(
			tower, "RightWall", Vector3(WALL_DEPTH, height, side_bay),
			Vector3(half_w, height * 0.5, z_side * (SIDE_DOOR_WIDTH + side_bay) * 0.5), wall_color
		)

	# Interior accent panels and counter establish a warmer room within the
	# single-color exterior shell. The counter stays away from both doors.
	_add_store_part(shop, Vector3(width * 0.46, height * 0.18, 0.035), Vector3(0, height * 0.22, half_d - 0.11), interior_accent.darkened(0.18), SuperEgg.EPSILON_FLAT)
	_add_store_part(shop, Vector3(0.035, height * 0.18, depth * 0.42), Vector3(-half_w + 0.11, height * 0.22, 0), interior_accent.darkened(0.24), SuperEgg.EPSILON_FLAT)
	_add_shop_architecture_box(
		tower, "ServiceCounter", Vector3(width * 0.58, 0.82, 0.78),
		Vector3(width * 0.08, 0.41, half_d - 1.55), Color(0.28, 0.18, 0.1)
	)
	# A low side display encourages a loop through the room without becoming
	# another waist-high obstacle directly in the entry axis.
	_add_shop_architecture_box(
		tower, "SideDisplay", Vector3(0.72, 0.62, depth * 0.34),
		Vector3(-half_w + 0.62, 0.31, 0.45), Color(0.31, 0.2, 0.11)
	)


func _add_shop_architecture_box(
	parent: StaticBody3D, part_name: String,
	size: Vector3, local_pos: Vector3, color: Color
) -> void:
	var visual := SuperEgg.build_part(size * 0.5, color, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	visual.name = part_name
	visual.position = local_pos
	parent.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.name = "%sCollision" % part_name
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = local_pos
	parent.add_child(collision)


## Converts the tower's existing ground-floor +X window opening into a second
## unmistakable shop entrance. The opening and its collision were already
## authored by TownProps._city_side_facade(); this adds storefront language
## without placing a fake door panel back across the traversable gap.
func _build_helmsmith_side_front(
	shop: Node3D, half_width: float, depth: float,
	teal: Color, coral: Color, gold: Color, navy: Color
) -> void:
	const OPENING_WIDTH := 2.4
	# A compact awning projects out over the side approach, well away from
	# the front-face fire escape that compromised the original entrance.
	_add_store_part(
		shop, Vector3(1.28, 0.14, OPENING_WIDTH * 0.72),
		Vector3(half_width + 1.18, 2.9, 0), coral, SuperEgg.EPSILON_FLAT,
		0.0, deg_to_rad(8.0)
	)
	# The awning is real traversal architecture, not a visual-only sheet.
	# Give its sloped top world-layer collision so both Player and the shared
	# blorb support probe can land and remain on it.
	var awning_body := StaticBody3D.new()
	awning_body.name = "HelmsmithAwningBody"
	awning_body.collision_layer = 1
	awning_body.collision_mask = 0
	awning_body.position = Vector3(half_width + 1.18, 2.9, 0)
	awning_body.rotation.z = deg_to_rad(8.0)
	var awning_collision := CollisionShape3D.new()
	var awning_shape := BoxShape3D.new()
	awning_shape.size = Vector3(2.56, 0.28, OPENING_WIDTH * 1.44)
	awning_collision.shape = awning_shape
	awning_body.add_child(awning_collision)
	shop.add_child(awning_body)
	for z in [-0.55, 0.0, 0.55]:
		_add_store_part(
			shop, Vector3(1.3, 0.06, 0.07),
			Vector3(half_width + 1.2, 3.06, z), gold, SuperEgg.EPSILON_FLAT,
			0.0, deg_to_rad(8.0)
		)
	# Side-mounted board and steel helmet mark make this entrance identifiable
	# from its own street rather than relying on the obscured front signage.
	_add_store_part(
		shop, Vector3(0.1, 0.42, 1.35),
		Vector3(half_width + 0.25, 3.72, 0), coral, SuperEgg.EPSILON_SOFT
	)
	_add_store_part(
		shop, Vector3(0.1, 0.5, 0.45),
		Vector3(half_width + 0.39, 3.72, 0), Color(0.54, 0.58, 0.62), SuperEgg.EPSILON_SOFT
	)
	_add_store_part(
		shop, Vector3(0.035, 0.06, 0.34),
		Vector3(half_width + 0.5, 3.65, 0), navy, SuperEgg.EPSILON_FLAT
	)


## A warm ceiling fixture makes the actual room inviting instead of leaving
## a bright facade wrapped around a dark interior. Per direct report the room
## read as too dark with only the single central fixture the earlier version
## hung here -- four fixtures now spread across the ceiling instead of one,
## with a dedicated fixture directly over the service counter so the vendor's
## own spot is never the dimmest part of the room. The compact neon helmet
## outline is mounted on the new side entrance, where the fire escape cannot
## obscure it from the street.
func _build_helmsmith_lighting(
	shop: Node3D, width: float, half_width: float, half_depth: float,
	teal: Color, coral: Color
) -> void:
	var warm := Color(1.0, 0.68, 0.34)
	# The purpose-built shop occupies y=0..FLOOR_HEIGHT. The previous 3.18m
	# literal placed every fixture more than half a metre through its 2.6m
	# ceiling and into the raised tower's first floor. Hang every fixture just
	# below the shop ceiling, matching the city rooms' clearance.
	var fixture_y := TownProps.FLOOR_HEIGHT - 0.16
	# Four positions spread front-to-back and side-to-side across the room's
	# footprint -- "Counter" sits directly above _build_helmsmith_room()'s own
	# ServiceCounter position (width * 0.08, half_d - 1.55), the other three
	# fan out toward the entrance and the two side displays so no corner of
	# the room is left unlit.
	var fixture_positions := {
		"Entrance": Vector3(0.0, fixture_y, -half_depth * 0.55),
		"Counter": Vector3(width * 0.08, fixture_y, half_depth - 1.55),
		"SideDisplay": Vector3(-half_width * 0.5, fixture_y, half_depth * 0.15),
		"Rear": Vector3(half_width * 0.35, fixture_y, half_depth * 0.6),
	}
	for fixture_name in fixture_positions:
		var fixture_position: Vector3 = fixture_positions[fixture_name]
		_add_emissive_store_part(
			shop, "InteriorShopLight%s" % fixture_name, Vector3(0.42, 0.055, 0.22),
			fixture_position, warm, 1.8
		)
		var interior_light := OmniLight3D.new()
		interior_light.name = "InteriorLight%s" % fixture_name
		interior_light.position = fixture_position - Vector3(0, 0.14, 0)
		interior_light.light_color = warm
		interior_light.light_energy = 0.95
		interior_light.omni_range = 4.4
		interior_light.shadow_enabled = false
		shop.add_child(interior_light)

	var sign_x := half_width + 0.54
	var sign_y := 3.72
	# Five restrained tubes describe a masked helmet: two crown slopes, two
	# cheek sides, and one visor slit. Alternating teal/coral keeps it tied to
	# the painted frontage rather than introducing an unrelated neon palette.
	_add_emissive_store_part(shop, "NeonCrownL", Vector3(0.025, 0.028, 0.31), Vector3(sign_x, sign_y + 0.22, -0.25), teal, 2.4, deg_to_rad(-42.0))
	_add_emissive_store_part(shop, "NeonCrownR", Vector3(0.025, 0.028, 0.31), Vector3(sign_x, sign_y + 0.22, 0.25), teal, 2.4, deg_to_rad(42.0))
	_add_emissive_store_part(shop, "NeonCheekL", Vector3(0.025, 0.22, 0.028), Vector3(sign_x, sign_y - 0.18, -0.49), coral, 2.2)
	_add_emissive_store_part(shop, "NeonCheekR", Vector3(0.025, 0.22, 0.028), Vector3(sign_x, sign_y - 0.18, 0.49), coral, 2.2)
	_add_emissive_store_part(shop, "NeonVisor", Vector3(0.025, 0.03, 0.42), Vector3(sign_x + 0.015, sign_y - 0.03, 0), teal, 2.7)
	var neon_light := OmniLight3D.new()
	neon_light.name = "NeonGlow"
	neon_light.position = Vector3(sign_x + 0.35, sign_y, 0)
	neon_light.light_color = teal.lightened(0.2)
	neon_light.light_energy = 0.55
	neon_light.omni_range = 3.2
	neon_light.shadow_enabled = false
	shop.add_child(neon_light)


## Wraps the entire helmsmith ground floor in its own palette, outside and
## inside. Each overlay follows the tower's existing wall bays so no real
## doorway or side/rear opening gets painted shut.
func _color_helmsmith_floor(
	shop: Node3D, width: float, depth: float,
	half_width: float, half_depth: float,
	teal: Color, coral: Color
) -> void:
	const FRONT_OPENING := 1.55
	const SIDE_OPENING := 1.7
	const SKIN := 0.035
	var floor_height := TownProps.FLOOR_HEIGHT
	var front_span := (width - FRONT_OPENING) * 0.5
	var front_x := (FRONT_OPENING + front_span) * 0.5
	var side_span := (depth - SIDE_OPENING) * 0.5
	var side_z := (SIDE_OPENING + side_span) * 0.5
	var inside_teal := teal.darkened(0.16)
	var inside_coral := coral.darkened(0.18)

	# Front and rear bays, each mirrored onto the room-facing surface.
	for z_side in [-1.0, 1.0]:
		var wall_z: float = -half_depth if z_side < 0.0 else half_depth
		for inside in [false, true]:
			var surface_z: float = wall_z + (-z_side if inside else z_side) * 0.075
			var left_color := inside_teal if inside else teal
			var right_color := inside_coral if inside else teal
			_add_store_part(shop, Vector3(front_span * 0.5, floor_height * 0.5, SKIN), Vector3(-front_x, floor_height * 0.5, surface_z), left_color, SuperEgg.EPSILON_FLAT)
			_add_store_part(shop, Vector3(front_span * 0.5, floor_height * 0.5, SKIN), Vector3(front_x, floor_height * 0.5, surface_z), right_color, SuperEgg.EPSILON_FLAT)

	# Both side walls retain their centered person-sized openings. Low and high
	# bands color the wall above/below those apertures without covering them.
	for x_side in [-1.0, 1.0]:
		var wall_x: float = x_side * half_width
		for inside in [false, true]:
			var surface_x: float = wall_x + (-x_side if inside else x_side) * 0.075
			var near_color := inside_teal if inside else teal
			var far_color := inside_coral if inside else teal
			_add_store_part(shop, Vector3(SKIN, floor_height * 0.5, side_span * 0.5), Vector3(surface_x, floor_height * 0.5, -side_z), near_color, SuperEgg.EPSILON_FLAT)
			_add_store_part(shop, Vector3(SKIN, floor_height * 0.5, side_span * 0.5), Vector3(surface_x, floor_height * 0.5, side_z), far_color, SuperEgg.EPSILON_FLAT)
			_add_store_part(shop, Vector3(SKIN, 0.18, SIDE_OPENING * 0.5), Vector3(surface_x, 0.18, 0), near_color, SuperEgg.EPSILON_FLAT)
			_add_store_part(shop, Vector3(SKIN, 0.17, SIDE_OPENING * 0.5), Vector3(surface_x, floor_height - 0.17, 0), far_color, SuperEgg.EPSILON_FLAT)


func _add_emissive_store_part(
	parent: Node3D, part_name: String, semi_axes: Vector3,
	local_pos: Vector3, color: Color, emission_energy: float,
	pitch: float = 0.0
) -> MeshInstance3D:
	var part := SuperEgg.build_part(semi_axes, color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	part.name = part_name
	part.position = local_pos
	part.rotation.x = pitch
	var material := part.get_surface_override_material(0) as StandardMaterial3D
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = emission_energy
	parent.add_child(part)
	return part


func _add_store_part(
	parent: Node3D, semi_axes: Vector3, local_pos: Vector3,
	color: Color, epsilon: float, pitch: float = 0.0, roll: float = 0.0
) -> void:
	var part := SuperEgg.build_part(semi_axes, color, epsilon, epsilon)
	part.position = local_pos
	part.rotation.x = pitch
	part.rotation.z = roll
	parent.add_child(part)

func _nearest_block(world: Vector2) -> Node3D:
	var nearest: Node3D = _city_blocks[0]
	var nearest_distance := INF
	for block in _city_blocks:
		var center: Vector2 = block.get_meta("center")
		var distance := center.distance_squared_to(world)
		if distance < nearest_distance:
			nearest = block
			nearest_distance = distance
	return nearest

func _update_room_lights_from_player() -> void:
	var player := get_node_or_null("../Player") as Node3D
	if player == null:
		return
	_update_room_light_lod(player.global_position)
	_update_npc_simulation(player.global_position)

func _materialize_block(block: Node3D) -> void:
	var tower_specs: Array = block.get_meta("tower_specs")
	for raw_spec in tower_specs:
		var spec: Dictionary = raw_spec
		var world: Vector2 = spec["world"]
		var tower: StaticBody3D
		if int(spec["light_seed"]) == HELMSMITH_LIGHT_SEED:
			# The shop owns a purpose-built ground floor. Raise the ordinary city
			# tower one full storey above it instead of trying to carve a usable
			# room and doors back out of the tower's merged collision mesh.
			tower = StaticBody3D.new()
			tower.collision_layer = 1
			var upper_floors := maxi(int(spec["floors"]) - 1, 1)
			var upper := TownProps.build_city_building(
				spec["width"], spec["depth"], upper_floors, spec["accent"], spec["light_seed"]
			)
			upper.name = "RaisedTower"
			upper.position.y = TownProps.FLOOR_HEIGHT
			tower.add_child(upper)
		else:
			tower = TownProps.build_city_building(
				spec["width"], spec["depth"], spec["floors"], spec["accent"], spec["light_seed"]
			)
		tower.position = Vector3(world.x, _ground(world), world.y)
		tower.rotation.y = spec["rotation"]
		tower.name = "Tower_%s" % spec["light_seed"]
		block.add_child(tower)
	block.set_meta("built", true)

func _update_room_light_lod(player_position: Vector3) -> void:
	for lamp in get_tree().get_nodes_in_group("city_room_lights"):
		if not (lamp is Node3D):
			continue
		var lamp_3d := lamp as Node3D
		var active := bool(lamp_3d.get_meta("room_lit")) and lamp_3d.global_position.distance_to(player_position) <= ROOM_LIGHT_RADIUS
		if active:
			TownProps.ensure_city_room_light(lamp_3d)
		lamp_3d.visible = active

func _update_npc_simulation(player_position: Vector3) -> void:
	for npc in get_tree().get_nodes_in_group("city_npcs"):
		if not (npc is Node3D):
			continue
		var npc_3d := npc as Node3D
		var active := npc_3d.global_position.distance_to(player_position) <= NPC_SIMULATION_RADIUS
		if bool(npc_3d.get_meta("simulation_active", true)) == active:
			continue
		npc_3d.set_meta("simulation_active", active)
		npc_3d.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
const HELMSMITH_LIGHT_SEED := 11
