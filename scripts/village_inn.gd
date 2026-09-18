class_name VillageInn
extends Node3D

const NPC_SCENE := preload("res://scenes/npc.tscn")

var world_id := "outskirts"
var point_id := "village_inn"
var fee := 10
var innkeeper_name := "Innkeeper"
var _stand_marker: Marker3D
var _wake_marker: Marker3D


static func create(
	parent: Node3D, terrain: Node, world_position: Vector3,
	for_world: String, id: String, price: int, keeper: String,
	roof_color: Color, wall_color: Color,
	keeper_appearance: Dictionary = {}, keeper_is_lava_person: bool = false,
	keeper_scene: PackedScene = null, open_pavilion_style: bool = false
) -> VillageInn:
	var inn := VillageInn.new()
	inn.world_id = for_world
	inn.point_id = id
	inn.fee = price
	inn.innkeeper_name = keeper
	parent.add_child(inn)
	inn.global_position = world_position
	# Where a terrain exposes its village centre, turn the building's known
	# local -Z doorway toward the settlement instead of relying on callers to
	# guess its authored forward axis.
	if terrain.has_method("get_village_center"):
		var village_center: Vector2 = terrain.get_village_center()
		var from_center := Vector2(world_position.x,world_position.z)-village_center
		if from_center.length_squared() > 0.01:
			inn.rotation.y = atan2(from_center.x,from_center.y)
	inn._build(terrain,roof_color,wall_color,keeper_appearance,keeper_is_lava_person,keeper_scene,open_pavilion_style)
	return inn


func _build(
	terrain: Node, roof_color: Color, wall_color: Color,
	keeper_appearance: Dictionary, keeper_is_lava_person: bool,
	keeper_scene: PackedScene, open_pavilion_style: bool
) -> void:
	name = "VillageInn_%s" % point_id
	# Five-by-four cells gives the reception and sleeping room genuine party
	# scale. TownProps' only exterior doorway is centered on local -Z.
	var house := _build_open_inn_shell(roof_color,wall_color) if open_pavilion_style else TownProps.build_building(5,4,1,roof_color,wall_color,wall_color.lightened(0.08),TownProps.FLOOR_COLOR,roof_color.lightened(0.12))
	house.name = "InnBuilding"
	add_child(house)
	_build_inn_sign(roof_color, wall_color)

	_build_reception(wall_color)
	_build_bedroom_partition(wall_color.lightened(0.05))
	var bed_positions: Array[Vector3] = [
		Vector3(-5.6,0.0,3.7), Vector3(-1.9,0.0,3.7),
		Vector3(1.9,0.0,3.7), Vector3(5.6,0.0,3.7),
	]
	for i in bed_positions.size():
		_build_bed(bed_positions[i], i)

	_wake_marker = Marker3D.new()
	_wake_marker.position = bed_positions[0] + Vector3(0.0,0.88,0.0)
	add_child(_wake_marker)
	_stand_marker = Marker3D.new()
	_stand_marker.position = Vector3(-5.6,0.1,1.3)
	add_child(_stand_marker)

	var keeper := (keeper_scene if keeper_scene != null else NPC_SCENE).instantiate() as Node3D
	keeper.display_name = innkeeper_name
	if keeper_scene == null:
		keeper.stationary = true
		keeper.fixed_ground_y = global_position.y
		keeper.facing_degrees = 180.0
		if not keeper_appearance.is_empty():
			VillagerAppearance.apply_profile(keeper,0,0,false,keeper_appearance)
		keeper.lava_body = keeper_is_lava_person
	else:
		# Local-species keepers (currently the Plant Kingdom's stuffed-animal
		# primate) use their own rig contract rather than NPC's human exports.
		keeper.roams = false
		keeper.rotation.y = PI
	# NPC.talk_lines is Array[String]. An untyped array literal remains
	# Array[Variant] when assigned through this dynamically typed scene
	# instance, which Godot correctly rejects at runtime.
	var inn_lines: Array[String] = ["The room is quiet, and the sheets are warm."]
	keeper.talk_lines = inn_lines
	keeper.dialog_actions_provider = _rest_actions
	keeper.position = Vector3(3.2,0.0,-2.0)
	if keeper.has_method("set_terrain_reference"):
		keeper.set_terrain_reference(terrain)
	add_child(keeper)
	_register.call_deferred()


func _build_open_inn_shell(roof_color: Color,wood_color: Color) -> StaticBody3D:
	var shell := StaticBody3D.new()
	shell.collision_layer = 1
	var floor := SuperEgg.build_part(Vector3(8.0,0.10,6.4),TownProps.FLOOR_COLOR,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	floor.position.y = 0.10
	shell.add_child(floor)
	CollisionPolicy.add_box(shell,floor,Vector3(16.0,0.20,12.8),floor.position,Basis(),true)
	var pillar := SuperEgg.build_part(Vector3(0.34,1.75,0.34),wood_color.darkened(0.15),SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
	pillar.position.y = 1.75
	shell.add_child(pillar)
	CollisionPolicy.add_box(shell,pillar,Vector3(0.68,3.5,0.68),pillar.position,Basis(),false)
	var roof := SuperEgg.build_part(Vector3(8.5,0.18,6.9),roof_color,3.6,3.6)
	roof.position.y = 3.52
	shell.add_child(roof)
	CollisionPolicy.add_box(shell,roof,Vector3(17.0,0.36,13.8),roof.position,Basis(),true)
	return shell


## A consistent diegetic inn mark: a bed beneath a crescent moon. It carries
## no writing, so it remains readable in every kingdom and language. The sign
## hangs beside the known local -Z entrance rather than covering the doorway.
func _build_inn_sign(accent_color: Color, wall_color: Color) -> void:
	var sign := StaticBody3D.new()
	sign.name = "InnBedAndMoonSign"
	sign.collision_layer = 1
	# Right side of the five-cell-wide south facade, projected far enough past
	# the wall to read in profile as a hanging place-of-business sign.
	var bracket_position := Vector3(5.8,2.42,-6.55)
	var bracket := SuperEgg.build_part(Vector3(0.62,0.055,0.055),wall_color.darkened(0.35),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	bracket.position = bracket_position+Vector3(0.0,0.0,-0.52)
	bracket.rotation.y = PI*0.5
	sign.add_child(bracket)
	CollisionPolicy.add_box(sign,bracket,Vector3(0.11,0.11,1.24),bracket.position,Basis(),false)
	for side in [-1.0,1.0]:
		var chain := SuperEgg.build_part(Vector3(0.025,0.33,0.025),wall_color.darkened(0.42),2.0,2.0)
		chain.position = Vector3(5.8+side*0.42,1.98,-7.08)
		sign.add_child(chain)
		CollisionPolicy.mark_decorative(chain)
	var plaque_position := Vector3(5.8,1.34,-7.08)
	var plaque := SuperEgg.build_part(Vector3(0.92,0.58,0.11),accent_color.darkened(0.16),3.4,3.4)
	plaque.position = plaque_position
	sign.add_child(plaque)
	CollisionPolicy.add_box(sign,plaque,Vector3(1.84,1.16,0.22),plaque_position,Basis(),false)
	var emblem_color := Color(0.92,0.78,0.42).lerp(accent_color.lightened(0.35),0.35)
	# Bed silhouette: mattress, headboard, and two short feet.
	var mattress := SuperEgg.build_part(Vector3(0.48,0.09,0.035),emblem_color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	mattress.position = plaque_position+Vector3(0.08,-0.20,-0.13)
	sign.add_child(mattress)
	CollisionPolicy.mark_decorative(mattress)
	var headboard := SuperEgg.build_part(Vector3(0.07,0.22,0.035),emblem_color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	headboard.position = plaque_position+Vector3(-0.45,-0.08,-0.13)
	sign.add_child(headboard)
	CollisionPolicy.mark_decorative(headboard)
	for x in [-0.34,0.48]:
		var foot := SuperEgg.build_part(Vector3(0.045,0.10,0.035),emblem_color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		foot.position = plaque_position+Vector3(x,-0.35,-0.13)
		sign.add_child(foot)
		CollisionPolicy.mark_decorative(foot)
	# A true crescent silhouette -- per direct correction, the old two-disk
	# approach (a round moon with a second, plaque-coloured disk placed in
	# front to fake an occluded sliver) never actually blended into the
	# plaque behind it: that "cutout" disk is real 3D geometry with its own
	# lit surface and edge profile, so it always shows as a visible circle
	# of its own rather than disappearing. This bakes an actual crescent
	# shape into a small transparent-background texture instead (the same
	# procedural-texture technique ParticleFX already uses for its own
	# particle textures) and paints it on a flat quad -- the "cut" pixels
	# are genuinely transparent, not color-matched, so the plaque shows
	# through them exactly as it should from any angle or lighting.
	var moon_texture := _build_crescent_texture(64, emblem_color)
	var moon_material := StandardMaterial3D.new()
	moon_material.albedo_texture = moon_texture
	moon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	moon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var moon_mesh := QuadMesh.new()
	moon_mesh.size = Vector2(0.56, 0.56)
	moon_mesh.material = moon_material
	var moon := MeshInstance3D.new()
	moon.mesh = moon_mesh
	moon.position = plaque_position + Vector3(0.0, 0.25, -0.13)
	sign.add_child(moon)
	CollisionPolicy.mark_decorative(moon)
	add_child(sign)


## A round moon with a smaller offset circle actually subtracted from its
## alpha channel -- everywhere inside the cut is fully transparent (not a
## color-matched disk pretending to be background), so the plaque behind it
## always shows through correctly.
static func _build_crescent_texture(size: int, moon_color: Color) -> ImageTexture:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var moon_radius := float(size) * 0.46
	var cut_radius := float(size) * 0.4
	var center := Vector2(float(size) * 0.5, float(size) * 0.5)
	var cut_center := center + Vector2(float(size) * 0.22, -float(size) * 0.06)
	for y in size:
		for x in size:
			var point := Vector2(float(x) + 0.5, float(y) + 0.5)
			var inside_moon := point.distance_to(center) <= moon_radius
			var inside_cut := point.distance_to(cut_center) <= cut_radius
			var color := moon_color if (inside_moon and not inside_cut) else Color(0.0, 0.0, 0.0, 0.0)
			image.set_pixel(x, y, color)
	return ImageTexture.create_from_image(image)


func _build_reception(color: Color) -> void:
	var counter := StaticBody3D.new()
	counter.name = "ReceptionCounter"
	counter.collision_layer = 1
	var visual := SuperEgg.build_part(Vector3(3.0,0.62,0.55),color.darkened(0.18),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	visual.position = Vector3(3.2,0.62,-3.05)
	counter.add_child(visual)
	CollisionPolicy.add_box(counter,visual,Vector3(6.0,1.24,1.1),visual.position,Basis(),true)
	add_child(counter)


func _build_bedroom_partition(color: Color) -> void:
	var partition := StaticBody3D.new()
	partition.name = "BedroomPartition"
	partition.collision_layer = 1
	# A broad opening at the right connects reception to the private room;
	# the remaining wall blocks the beds from the public entrance sightline.
	for data in [
		{"position":Vector3(-4.4,1.55,0.65),"size":Vector3(7.2,3.1,0.18)},
		{"position":Vector3(4.6,1.55,0.65),"size":Vector3(4.0,3.1,0.18)},
		{"position":Vector3(1.0,2.78,0.65),"size":Vector3(3.2,0.64,0.18)},
	]:
		var size: Vector3 = data["size"]
		var position: Vector3 = data["position"]
		var panel := SuperEgg.build_part(size*0.5,color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		panel.position = position
		partition.add_child(panel)
		CollisionPolicy.add_box(partition,panel,size,position,Basis(),false)
	add_child(partition)


func _build_bed(position: Vector3, index: int) -> void:
	var bed := StaticBody3D.new()
	bed.name = "PartyBed%d" % (index+1)
	bed.collision_layer = 1
	var frame := SuperEgg.build_part(Vector3(0.78,0.23,1.32),Color(0.33,0.18,0.09),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	frame.position = position+Vector3(0.0,0.35,0.0)
	bed.add_child(frame)
	var mattress := SuperEgg.build_part(Vector3(0.7,0.16,1.19),Color(0.88,0.82,0.68),SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
	mattress.position = position+Vector3(0.0,0.62,0.0)
	bed.add_child(mattress)
	CollisionPolicy.add_box(bed,frame,Vector3(1.56,0.48,2.64),frame.position,Basis(),true)
	add_child(bed)


func _register() -> void:
	RecoveryManager.register_rest_point(
		world_id, point_id, _wake_marker.global_transform,
		_stand_marker.global_transform, _stand_marker.global_position + Vector3(0, 0, 2.5)
	)


func _rest_actions() -> Array[Dictionary]:
	return [TransactionInteraction.paid_action(
		"Rest for the night",
		fee,
		func() -> void:
			if RecoveryManager.begin_paid_rest(world_id,point_id):
				DialogUI.hide_dialog(),
		"Your purse feels too light.",
		func() -> bool: return RecoveryManager.can_rest()
	)]
