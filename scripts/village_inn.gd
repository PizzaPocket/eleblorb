class_name VillageInn
extends Node3D

const NPC_SCENE := preload("res://scenes/npc.tscn")

var world_id := "outskirts"
var point_id := "village_inn"
var fee := 10
var innkeeper_name := "Innkeeper"
## Overrides the keeper's default talk lines for a village that speaks its own
## language. Empty keeps the stock lines.
var keeper_lines: Array[String] = []
## The keeper's body follows the keeper's identity, not the default male build.
var keeper_is_female := false
## The washroom fixture, true to the inn's culture (see ToiletFixtures.KINDS).
var toilet_fixture := "porcelain"
var _stand_marker: Marker3D
var _wake_marker: Marker3D
var _half_width := 8.0
var _half_depth := 6.4
var _is_lodge := false
var _is_ohio_lodge := false
var _terrain_ref: Node
## Door in the rear (north) wall, off-centre so it opens into the bedroom aisle
## clear of the beds, between the last bed and the service rooms.
const LODGE_BACK_DOOR_X := 4.0
## A true double-height hearth hall. Its full superellipse is centred on the
## east gable; only the interior half intersects the floor, leaving a broad
## curved gallery edge and a straight wall-clipped side around the chimney.
const HEARTH_HALL_VOID := {
	"shape":"wall_superellipse",
	"center":Vector2(9.6,0.0),
	"half_size":Vector2(4.8,2.2),
	"exponent":4.0,
	"wall":"east",
	"rail_segments":18,
}
var _smoke_rng := RandomNumberGenerator.new()
var _smoke_puffs: Array[ChimneySmoke.Puff] = []


static func create(
	parent: Node3D, terrain: Node, world_position: Vector3,
	for_world: String, id: String, price: int, keeper: String,
	roof_color: Color, wall_color: Color,
	keeper_appearance: Dictionary = {}, keeper_is_lava_person: bool = false,
	keeper_scene: PackedScene = null, open_pavilion_style: bool = false,
	architecture_style: String = "panel", door_faces: Variant = null,
	lines: Array[String] = [], keeper_is_female: bool = false,
	fixture: String = "porcelain"
) -> VillageInn:
	var inn := VillageInn.new()
	inn.world_id = for_world
	inn.point_id = id
	inn.fee = price
	inn.innkeeper_name = keeper
	inn.keeper_lines = lines
	inn.keeper_is_female = keeper_is_female
	inn.toilet_fixture = fixture
	parent.add_child(inn)
	inn.global_position = world_position
	# Where a terrain exposes its village centre, turn the building's known
	# local -Z doorway toward the settlement instead of relying on callers to
	# guess its authored forward axis.
	if door_faces is Vector2:
		# An authored village plan names the point the door looks toward (the
		# yard or lane it serves) rather than leaving it to face the centre.
		var toward: Vector2 = (door_faces as Vector2) - Vector2(world_position.x,world_position.z)
		if toward.length_squared() > 0.01:
			inn.rotation.y = atan2(-toward.x,-toward.y)
	elif terrain.has_method("get_village_center"):
		var village_center: Vector2 = terrain.get_village_center()
		var from_center := Vector2(world_position.x,world_position.z)-village_center
		if from_center.length_squared() > 0.01:
			inn.rotation.y = atan2(from_center.x,from_center.y)
	inn._build(terrain,roof_color,wall_color,keeper_appearance,keeper_is_lava_person,keeper_scene,open_pavilion_style,architecture_style)
	return inn


func _build(
	terrain: Node, roof_color: Color, wall_color: Color,
	keeper_appearance: Dictionary, keeper_is_lava_person: bool,
	keeper_scene: PackedScene, open_pavilion_style: bool,architecture_style: String
) -> void:
	name = "VillageInn_%s" % point_id
	_terrain_ref = terrain
	# The two settled villages use a proper lodge: a generous six-by-five-cell
	# primary mass, an occupied upper floor, and the shared ramp/well system.
	# Other kingdoms retain their established compact footprint unless they opt
	# in with an architectural style.
	var is_lodge:=architecture_style in ["log","continuous_panel"] and not open_pavilion_style
	var cells_w:=6 if is_lodge else 5
	var cells_d:=5 if is_lodge else 4
	var floor_count:=2 if is_lodge else 1
	_half_width=float(cells_w)*TownProps.CELL_SIZE*0.5
	_half_depth=float(cells_d)*TownProps.CELL_SIZE*0.5
	_is_lodge = is_lodge
	_is_ohio_lodge = architecture_style == "continuous_panel" and is_lodge
	var back_door := LODGE_BACK_DOOR_X if is_lodge else TownProps.NO_BACK_DOOR
	var house := _build_open_inn_shell(roof_color,wall_color) if open_pavilion_style else TownProps.build_building(cells_w,cells_d,floor_count,roof_color,wall_color,wall_color.lightened(0.08),TownProps.FLOOR_COLOR,roof_color.lightened(0.12),architecture_style,false,"inn",back_door,"all",{},[HEARTH_HALL_VOID] if _is_ohio_lodge else [])
	house.name = "InnBuilding"
	add_child(house)
	if is_lodge:
		_smoke_rng.seed = hash(point_id)
		if _is_ohio_lodge:
			# One great common-room fireplace and one chimney mass. The kitchen uses
			# that same heat wall but does not present a second fireplace mouth.
			# The breast rises through the open bay and remains visible outside.
			Hearth.build_chimney_wall(
				house as StaticBody3D,cells_w,cells_d,floor_count,1.0,
				[{"z":0.0,"width":2.3,"height":1.8}],
				0.0,_smoke_rng,_smoke_puffs,true,TownProps.OHIO_BRICK,5.4,{"mode":"always"}
			)
		else:
			# The common room's masonry hearth stands against the centre of the east
			# gable wall, its flue rising with that wall and clearing the ridge.
			var inset := 0.38 if architecture_style == "continuous_panel" else Hearth.WALL_INSET
			Hearth.build_on_gable(
				house as StaticBody3D,cells_w,cells_d,floor_count,1.0,-3.4,
				_smoke_rng,_smoke_puffs,true,inset,
				TownProps.OHIO_BRICK if architecture_style=="continuous_panel" else Hearth.STONE,
				true
			)
	_build_inn_sign(roof_color, wall_color)

	_build_reception(wall_color)
	if _is_ohio_lodge:
		_build_ohio_ground_plan(wall_color.lightened(0.05))
		_build_ohio_interior()
	else:
		_build_bedroom_partition(wall_color.lightened(0.05))
	var bed_z:=_half_depth-2.0
	var bed_positions: Array[Vector3] = [
		Vector3(-6.8,0.0,bed_z),Vector3(-3.5,0.0,bed_z),
		Vector3(-0.2,0.0,bed_z),Vector3(3.1,0.0,bed_z),
	]
	if is_lodge:
		# Heads against the rear wall, spaced clear of the doorway at x~1.5 and
		# of the back door at x=4.
		bed_z=_half_depth-1.4
		if _is_ohio_lodge:
			# Two beds in each front room, head to the front wall, and one in the
			# spare room behind the gallery.
			bed_positions.assign([
				Vector3(-5.4,TownProps.FLOOR_HEIGHT,-6.69),Vector3(-2.0,TownProps.FLOOR_HEIGHT,-6.69),
				Vector3(0.3,TownProps.FLOOR_HEIGHT,-6.69),Vector3(3.5,TownProps.FLOOR_HEIGHT,-6.69),
				Vector3(-1.9,TownProps.FLOOR_HEIGHT,6.69),
			])
		else:
			bed_positions.assign([
				Vector3(-7.4,0.0,bed_z),Vector3(-4.4,0.0,bed_z),
				Vector3(-1.4,0.0,bed_z),Vector3(1.6,0.0,bed_z),
				Vector3(-6.5,TownProps.FLOOR_HEIGHT,bed_z),Vector3(-3.2,TownProps.FLOOR_HEIGHT,bed_z),
				Vector3(0.1,TownProps.FLOOR_HEIGHT,bed_z),Vector3(3.4,TownProps.FLOOR_HEIGHT,bed_z),
			])
		_build_common_room_tables()
		if _is_ohio_lodge:
			_build_upper_guest_rooms(wall_color.lightened(0.08))
	for i in bed_positions.size():
		_build_bed(bed_positions[i], i, 0.0 if _is_ohio_lodge else PI)
	_build_service_rooms(wall_color.lightened(0.04))

	_wake_marker = Marker3D.new()
	_wake_marker.position = bed_positions[0] + Vector3(0.0,0.88,0.0)
	add_child(_wake_marker)
	_stand_marker = Marker3D.new()
	_stand_marker.position = Vector3(-1.0,TownProps.FLOOR_HEIGHT+0.1,-2.2) if _is_ohio_lodge else (Vector3(-7.4,0.1,bed_z-2.8) if is_lodge else Vector3(-6.8,0.1,bed_z-2.4))
	add_child(_stand_marker)

	var keeper := (keeper_scene if keeper_scene != null else NPC_SCENE).instantiate() as Node3D
	keeper.display_name = innkeeper_name
	if keeper_scene == null:
		keeper.stationary = true
		keeper.fixed_ground_y = global_position.y
		keeper.facing_degrees = 180.0
		keeper.is_female = keeper_is_female
		if not keeper_appearance.is_empty():
			VillagerAppearance.apply_profile(keeper,0,0,keeper_is_female,keeper_appearance)
		keeper.lava_body = keeper_is_lava_person
	else:
		# Local-species keepers (currently the Plant Kingdom's stuffed-animal
		# primate) use their own rig contract rather than NPC's human exports.
		keeper.roams = false
		keeper.rotation.y = PI
	# NPC.talk_lines is Array[String]. An untyped array literal remains
	# Array[Variant] when assigned through this dynamically typed scene
	# instance, which Godot correctly rejects at runtime.
	var inn_lines: Array[String] = []
	if _is_ohio_lodge:
		inn_lines.assign([
			"If you need a room, ask before I bank the fire. I won't wake the whole house for late feet.",
			"Nell says visitors remember her bread. They remember the bed they ate it in.",
		])
	elif not keeper_lines.is_empty():
		inn_lines.assign(keeper_lines)
	else:
		inn_lines.assign(["The room is quiet, and the sheets are warm."])
	keeper.talk_lines = inn_lines
	keeper.dialog_actions_provider = _rest_actions
	keeper.position = Vector3(-3.4,0.0,1.95) if _is_ohio_lodge else (Vector3(5.0,0.0,-3.1) if is_lodge else Vector3(3.2,0.0,-_half_depth+3.0))
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
	# Right side of the five-cell-wide south facade, projected far enough past
	# the wall to read in profile as a hanging place-of-business sign.
	# Hung beside the door on the left, between it and the common-room window.
	var sign := build_bed_and_moon_sign(accent_color, wall_color)
	sign.position = Vector3(-2.7 if _is_lodge else _half_width - 1.7, 0.0, -_half_depth)
	add_child(sign)


## The sign itself, shared by every rest point (inns, guest houses, the fishing
## village's houseboat). Its frame: the wall face it hangs from is local z = 0,
## the bracket projects toward -Z at 2.42 m, the plaque hangs below its end.
static func build_bed_and_moon_sign(accent_color: Color, wall_color: Color) -> StaticBody3D:
	var sign := StaticBody3D.new()
	sign.name = "InnBedAndMoonSign"
	sign.collision_layer = 1
	var sign_x := 0.0
	var sign_z := -0.68
	var bracket_position := Vector3(sign_x,2.42,-0.15)
	var bracket := SuperEgg.build_part(Vector3(0.62,0.055,0.055),wall_color.darkened(0.35),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	bracket.position = bracket_position+Vector3(0.0,0.0,-0.52)
	bracket.rotation.y = PI*0.5
	sign.add_child(bracket)
	CollisionPolicy.add_box(sign,bracket,Vector3(0.11,0.11,1.24),bracket.position,Basis(),false)
	# The bracket projects out from the wall, but the plaque hangs parallel to the
	# wall, so its two chains must each meet something that crosses the bracket.
	# A short crossbar under the bracket's end carries them (the walkthrough found
	# the chains rising to nothing, off the bracket's line).
	var crossbar := SuperEgg.build_part(Vector3(0.5,0.04,0.04),wall_color.darkened(0.35),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	crossbar.position = Vector3(sign_x,2.33,sign_z)
	sign.add_child(crossbar)
	CollisionPolicy.mark_decorative(crossbar)
	for side in [-1.0,1.0]:
		var chain := SuperEgg.build_part(Vector3(0.025,0.33,0.025),wall_color.darkened(0.42),2.0,2.0)
		chain.position = Vector3(sign_x+side*0.42,1.98,sign_z)
		sign.add_child(chain)
		CollisionPolicy.mark_decorative(chain)
	var plaque_position := Vector3(sign_x,1.34,sign_z)
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
	return sign


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
	if _is_ohio_lodge:
		return
	var counter := StaticBody3D.new()
	counter.name = "ReceptionCounter"
	counter.collision_layer = 1
	# The lodge's counter stands well east of the door (which keeps a clear
	# corridor straight into the room) with the keeper behind it and the hearth
	# beyond; the compact inns keep their original frontage counter.
	var half := Vector3(2.2,0.62,0.5) if _is_lodge else Vector3(3.0,0.62,0.55)
	var visual := SuperEgg.build_part(half,color.darkened(0.12),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	visual.position = Vector3(-3.0,0.62,-4.25) if _is_ohio_lodge else (Vector3(5.0,0.62,-4.4) if _is_lodge else Vector3(3.2,0.62,-_half_depth+2.0))
	counter.add_child(visual)
	CollisionPolicy.add_box(counter,visual,half*2.0,visual.position,Basis(),true)
	add_child(counter)


## Two tables with stools in the west half of the common room, between the
## ramp up the west gable and the corridor in from the door.
func _build_common_room_tables() -> void:
	if _is_ohio_lodge:
		return
	var table_positions: Array[Vector3] = []
	if _is_ohio_lodge:
		table_positions.assign([Vector3(4.1,0.0,-3.0),Vector3(4.1,0.0,3.0)])
	else:
		table_positions.assign([Vector3(-4.4,0.0,-5.4),Vector3(-4.4,0.0,-2.2)])
	for table_position in table_positions:
		var table := StaticBody3D.new()
		table.name = "CommonTable"
		table.collision_layer = 1
		table.position = table_position
		add_child(table)
		var top := SuperEgg.build_part(Vector3(0.85,0.04,0.5),TownProps.TRIM_WOOD.lightened(0.1),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		top.position = Vector3(0.0,0.76,0.0)
		table.add_child(top)
		CollisionPolicy.add_box(table,top,Vector3(1.7,0.08,1.0),top.position,Basis(),true)
		for leg_x in [-0.7,0.7]:
			for leg_z in [-0.35,0.35]:
				var leg := SuperEgg.build_part(Vector3(0.05,0.37,0.05),TownProps.TRIM_WOOD,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
				leg.position = Vector3(leg_x,0.37,leg_z)
				table.add_child(leg)
				CollisionPolicy.add_box(table,leg,Vector3(0.1,0.74,0.1),leg.position,Basis(),false)
		for stool_x in [-1.25,1.25]:
			var stool := SuperEgg.build_part(Vector3(0.22,0.23,0.22),TownProps.TRIM_WOOD.darkened(0.05),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
			stool.position = Vector3(stool_x,0.23,0.0)
			table.add_child(stool)
			CollisionPolicy.add_box(table,stool,Vector3(0.44,0.46,0.44),stool.position,Basis(),false)


## Ohio's ground floor is a public inn laid out the way an inn works. Its open
## timber porch shelters a broad double doorway that enters a generous arrival
## zone directly within the common room. In Ohio's mild climate, adding a tiny
## sealed vestibule behind an already sheltered door only creates a bottleneck.
## The common room fills the front and runs round the gable hearth; behind it,
## across one rear partition, stand the keeper's
## office (directly behind the counter), the kitchen (with its own hearth and the
## yard door) and the larder and washroom. Every doorway is a framed door in a
## full-height wall (see TownProps.build_interior_wall). Building frame: the front
## wall is at z = -8, the entrance at x = 0, the hearth wall at x = +9.6.
## The line both floors share. The ground rear partition and the upper floor's
## two corridor walls stand on z = +/- GALLERY_Z, so every upper wall on the north
## side bears on a wall below it, and the south side's carry a summer beam. The
## 2026-10-04 walkthrough found a plan where they did not agree: a ground wall ran
## up into the hearth hall's opening, and eleven upper walls had nothing under
## them. ClearZones.audit_stacking now checks the first; partitions on joists are
## allowed.
const GALLERY_Z := 3.6
## North-south bearing lines shared by the ground rear rooms and the upper rear rooms.
const OFFICE_WALL_X := -3.4
const KITCHEN_WALL_X := 2.6
## The upper front rooms' dividers, carried by the ground frame (see _build_ground_frame).
const FRONT_DIVIDER_XS: Array[float] = [-6.5, -0.9, 4.7]


func _build_ohio_ground_plan(color: Color) -> void:
	var walls:=StaticBody3D.new()
	walls.name="OhioInnGroundPartitions"
	walls.collision_layer=1
	# The rear partition: a door to the larder passage, one to the office behind
	# the counter, one to the kitchen (in line with the yard door).
	# A wall's doors swing toward its local -Z, which is the left of the way it is
	# drawn. Drawn east to west, this partition's doors open into the larder,
	# office and kitchen they serve, never into the common room.
	TownProps.build_interior_wall(walls,Vector2(9.52,GALLERY_Z),Vector2(-9.52,GALLERY_Z),0.0,[5.52,10.52,15.52],color)
	# Larder passage and washroom (west), office (middle), kitchen (east).
	# Drawn east to west so the washroom door swings into the washroom, hinged on
	# its east jamb, folding away from the toilet. It used to swing out into the
	# 2.3 m larder passage against the larder door's leaf, a zigzag to get past.
	TownProps.build_interior_wall(walls,Vector2(OFFICE_WALL_X,5.9),Vector2(-9.52,5.9),0.0,[OFFICE_WALL_X+4.6],color)
	TownProps.build_interior_wall(walls,Vector2(OFFICE_WALL_X,GALLERY_Z),Vector2(OFFICE_WALL_X,7.92),0.0,[],color)
	TownProps.build_interior_wall(walls,Vector2(KITCHEN_WALL_X,GALLERY_Z),Vector2(KITCHEN_WALL_X,7.92),0.0,[1.8],color)
	add_child(walls)
	_build_ground_frame()


## The common room is one open space, so the upper front rooms above it are carried
## on an exposed timber frame: a summer beam along z = -GALLERY_Z under the
## corridor wall, three posts under the room dividers, and a cross beam under each
## divider back to the front wall. Posts are real obstacles (the furniture keeps
## clear of them) and are registered as supports for the stacking audit.
func _build_ground_frame() -> void:
	var frame:=StaticBody3D.new()
	frame.name="OhioInnFrame"
	frame.collision_layer=1
	var timber:=TownProps.TRIM_WOOD.darkened(0.08)
	var beam_depth:=0.3
	var deck_underside:=TownProps.FLOOR_HEIGHT-0.13
	var beam_y:=deck_underside-beam_depth*0.5
	var summer_from:=Vector2(FRONT_DIVIDER_XS[0],-GALLERY_Z)
	var summer_to:=Vector2(9.5,-GALLERY_Z)
	var summer:=SuperEgg.build_part(Vector3((summer_to.x-summer_from.x)*0.5,beam_depth*0.5,0.15),timber,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	summer.position=Vector3((summer_from.x+summer_to.x)*0.5,beam_y,-GALLERY_Z)
	frame.add_child(summer)
	CollisionPolicy.mark_decorative(summer)
	ClearZones.add_support(frame,"summer beam","beam",summer_from,summer_to,TownProps.FLOOR_HEIGHT)
	for x in FRONT_DIVIDER_XS:
		var cross_from:=Vector2(x,-7.92)
		var cross_to:=Vector2(x,-GALLERY_Z)
		var cross:=SuperEgg.build_part(Vector3(0.15,beam_depth*0.5,(cross_to.y-cross_from.y)*0.5),timber,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		cross.position=Vector3(x,beam_y,(cross_from.y+cross_to.y)*0.5)
		frame.add_child(cross)
		CollisionPolicy.mark_decorative(cross)
		ClearZones.add_support(frame,"divider beam","beam",cross_from,cross_to,TownProps.FLOOR_HEIGHT)
		var post_height:=beam_y-beam_depth*0.5
		var post:=SuperEgg.build_part(Vector3(0.16,post_height*0.5,0.16),timber.lightened(0.04),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		post.position=Vector3(x,post_height*0.5,-GALLERY_Z)
		frame.add_child(post)
		CollisionPolicy.add_box(frame,post,Vector3(0.32,post_height,0.32),post.position,Basis(),false)
		ClearZones.add_support(frame,"post","post",Vector2(x,-GALLERY_Z),Vector2(x,-GALLERY_Z),TownProps.FLOOR_HEIGHT)
		ClearZones.add(frame,"post","post",Vector2(x,-GALLERY_Z),Vector2(0,1),0.4,0.4,0.4,0.05,2.6)
	add_child(frame)


## The upper floor. The ramp arrives in the stair hall at the west; a gallery
## runs east along the ridge and opens around the double-height hearth hall.
## Two ordinary guest rooms occupy the deeper front range, with a locked cache
## beside the chimney. Mira's room and one spare room occupy the quieter rear
## range, with a second locked chamber on the other side of the chimney.
## Partitions under the roof run up to the rafters: those along the ridge rise
## to the roof's underside where they stand, the cross walls are gable-shaped.
## Windows fall inside rooms (never on a partition) and no door is blocked.
func _build_upper_guest_rooms(color: Color) -> void:
	var walls:=StaticBody3D.new()
	walls.name="OhioInnGuestRooms"
	walls.collision_layer=1
	var base:=TownProps.FLOOR_HEIGHT
	var roof:={"floor_top":2.0*TownProps.FLOOR_HEIGHT,"run":_half_depth+TownProps.ROOF_EAVE_OVERHANG}
	var trim:=TownProps.TRIM_WOOD
	var no_archways: Array[float]=[]
	var tall:=TownProps.FLOOR_HEIGHT
	# Every wall below stands over a wall or the summer beam of the ground floor.
	# The south corridor wall carries the guest rooms' doors, the north one stands
	# on the ground rear partition. The key cache is the east end of the south
	# range, its east end open for the parkour entry; Hollis's room is the east end
	# of the north range, one locked door.
	var key_room_door: Array[Dictionary] = [{
		"initially_open":false,"locked":true,
		"required_key":"Holt Inn Key","lock_id":"ohio_inn_key_room",
	}]
	var hollis_room_door: Array[Dictionary] = [{
		"initially_open":false,"locked":true,
		"required_key":"Holt Inn Key","lock_id":"ohio_inn_hollis_room",
	}]
	# South corridor wall: doors at x = -3.7 (party room) and 1.9 (guest room).
	TownProps.build_interior_wall(walls,Vector2(FRONT_DIVIDER_XS[0],-GALLERY_Z),Vector2(FRONT_DIVIDER_XS[2],-GALLERY_Z),base,[2.8,8.4],color,trim,tall,true,no_archways,roof)
	# The key cache: from its west divider to a post at x = 8.0, with the east end
	# open to the hall's gallery (the parkour way in).
	TownProps.build_interior_wall(walls,Vector2(FRONT_DIVIDER_XS[2],-GALLERY_Z),Vector2(8.0,-GALLERY_Z),base,[1.6],color,trim,tall,true,no_archways,roof,key_room_door)
	# North corridor wall, over the ground rear partition: Mira's door at x = -6.0,
	# the spare room's at x = -0.4, then Hollis's locked door at x = 4.5.
	# Drawn east to west so the doors swing into the rooms, not into the gallery.
	TownProps.build_interior_wall(walls,Vector2(KITCHEN_WALL_X,GALLERY_Z),Vector2(-9.52,GALLERY_Z),base,[8.6,3.0],color,trim,tall,true,no_archways,roof)
	TownProps.build_interior_wall(walls,Vector2(9.52,GALLERY_Z),Vector2(KITCHEN_WALL_X,GALLERY_Z),base,[5.02],color,trim,tall,true,no_archways,roof,hollis_room_door)
	# Dividers between the rooms: the front three over the summer frame, the rear
	# two over the ground office and kitchen walls.
	for x in FRONT_DIVIDER_XS:
		TownProps.build_interior_wall(walls,Vector2(x,-7.92),Vector2(x,-GALLERY_Z),base,[],color,trim,tall,true,no_archways,roof)
	for x in [OFFICE_WALL_X,KITCHEN_WALL_X]:
		TownProps.build_interior_wall(walls,Vector2(x,GALLERY_Z),Vector2(x,7.92),base,[],color,trim,tall,true,no_archways,roof)
	add_child(walls)
	_register_upper_routes()


## The walking routes that must stay open at a person's width: the stair head to
## the gallery, along it to each door, and through each open door. Corridors and
## the gallery by the hall opening are checked at 1.1 m (two people passing),
## doorways at a person's width. Closed locked doors end their lane at the sill.
func _register_upper_routes() -> void:
	var y:=TownProps.FLOOR_HEIGHT
	var wide:=0.55
	var door:=0.22
	ClearZones.add_lane(self,"gallery from the stair head",[Vector3(-8.65,y,-1.2),Vector3(-6.0,y,0.0),Vector3(1.5,y,0.0)],wide)
	for door_x: float in [-3.7,1.9]:
		ClearZones.add_lane(self,"to the front room at x=%.1f" % door_x,[Vector3(door_x,y,-1.0),Vector3(door_x,y,-2.75)],wide)
		ClearZones.add_lane(self,"into the front room at x=%.1f" % door_x,[Vector3(door_x,y,-2.9),Vector3(door_x,y,-5.0)],door)
	for door_x: float in [-6.0,-0.4]:
		ClearZones.add_lane(self,"to the rear room at x=%.1f" % door_x,[Vector3(door_x,y,1.0),Vector3(door_x,y,2.75)],wide)
		ClearZones.add_lane(self,"into the rear room at x=%.1f" % door_x,[Vector3(door_x,y,2.9),Vector3(door_x,y,5.0)],door)
	ClearZones.add_lane(self,"gallery south of the hall opening",[Vector3(1.5,y,0.0),Vector3(2.2,y,-2.85),Vector3(6.3,y,-2.85)],wide)
	ClearZones.add_lane(self,"gallery north of the hall opening",[Vector3(1.5,y,0.0),Vector3(2.2,y,2.85),Vector3(4.5,y,2.85)],wide)


func _warm_light(at: Vector3, energy: float, reach: float) -> void:
	var light := OmniLight3D.new()
	light.position = at
	light.light_color = Color(1.0, 0.72, 0.4)
	light.light_energy = energy
	light.omni_range = reach
	light.shadow_enabled = false
	add_child(light)


## Furnishes the Ohio inn for the people who use it: Mira Holt keeps the room
## herself, early, frank and tidy (a broom by the door, a tally of bread, a good
## lamp). Large pieces stand against walls, tables form groups, routes stay 1.2 m
## wide, and each group has its own small light.
func _build_ohio_interior() -> void:
	var body:=StaticBody3D.new()
	body.name="InnFurnishings"
	body.collision_layer=1
	add_child(body)
	var floor_up:=TownProps.FLOOR_HEIGHT
	# ---- Ground floor: the common room ------------------------------------
	# Open arrival zone: pegs and a bench sit against the front wall on either
	# side of the broad doors, never floating where the removed vestibule walls
	# used to stand. The centre remains clear for guests and luggage.
	Furnishings.peg_rail(body,Vector3(-2.45,0.0,-7.76),0.0,1.6,1.75)
	Furnishings.bench(body,Vector3(2.65,0.0,-7.18),0.0,1.4)
	Furnishings.rug(body,Vector3(0.0,0.0,-7.0),0.0,Vector2(1.5,0.9),Furnishings.CLOTH_BLUE.darkened(0.35))
	# The hearth stands on the gable's centre line (z = 0), so the fireside is one
	# formal group about that axis: a rug, a high-backed settle either side facing
	# its twin, two armchairs facing the fire, fire irons and a basket of logs by
	# the breast. Everything stays back from the fire (ClearZones, kind "fire").
	Furnishings.rug(body,Vector3(5.9,0.0,0.0),0.0,Vector2(3.6,3.0),Furnishings.CLOTH_RED.darkened(0.15))
	Furnishings.settle(body,Vector3(5.9,0.0,-1.9),PI,1.6,Furnishings.CLOTH_GREEN)
	Furnishings.settle(body,Vector3(5.9,0.0,1.9),0.0,1.6,Furnishings.CLOTH_GREEN)
	Furnishings.armchair(body,Vector3(4.95,0.0,-0.85),-PI*0.5,Furnishings.CLOTH_BLUE)
	Furnishings.armchair(body,Vector3(4.95,0.0,0.85),-PI*0.5,Furnishings.CLOTH_BLUE)
	Furnishings.log_basket(body,Vector3(9.0,0.0,2.05))
	Furnishings.fire_irons(body,Vector3(9.05,0.0,-2.05))
	# Tables for travellers: one by the window, one by the stair, two between,
	# kept clear of the frame's posts at z = -3.6 and of every door's approach.
	Furnishings.table(body,Vector3(5.4,0.0,-5.4),0.0,1.7,1.0,"stools")
	Furnishings.table(body,Vector3(-4.4,0.0,-5.2),0.0,1.7,1.0,"stools")
	Furnishings.table(body,Vector3(-3.0,0.0,-1.5),0.0,1.3,0.8,"stools")
	Furnishings.table(body,Vector3(-6.1,0.0,-0.4),PI*0.5,1.2,0.8,"stools")
	# The counter sits between the larder door and the office door, with the
	# keeper's space behind it up to the rear partition.
	Furnishings.counter(body,Vector3(-3.5,0.0,1.2),0.0,3.4)
	Furnishings.shelf(body,Vector3(-3.2,0.0,GALLERY_Z-0.28),0.0,1.6,2,"mugs")
	Furnishings.broom(body,Vector3(-3.2,0.0,-7.84),0.0)
	Furnishings.piece(body,Vector3(0.22,0.23,0.22),Furnishings.OAK,Vector3(-0.8,0.23,-0.35),0.0,true,2.4)
	_warm_light(Vector3(1.0,2.6,-3.4),0.8,8.0)
	_warm_light(Vector3(-3.4,2.4,1.3),0.7,6.0)
	# ---- Ground floor: the rooms behind the partition ----------------------
	# Keeper's office behind the counter: desk at the window, ledgers, a
	# strongbox, a rug.
	Furnishings.desk(body,Vector3(0.0,0.0,7.05),0.0)
	Furnishings.shelf(body,Vector3(OFFICE_WALL_X+0.28,0.0,5.7),-PI*0.5,2.2,3,"boxes")
	Furnishings.strongbox(body,Vector3(-2.7,0.0,7.55),0.0)
	Furnishings.rug(body,Vector3(-0.2,0.0,5.2),0.0,Vector2(2.2,1.7),Furnishings.CLOTH_GREEN.darkened(0.3))
	# Kitchen: a pot rack, a long prep table in the middle of the work floor, a
	# dresser of crocks, casks; the route from the yard door (x = 4.0) to the
	# common room door in line with it stays clear.
	Furnishings.pot_rack(body,Vector3(8.45,0.0,4.9),PI*0.5,1.8,2.3)
	Furnishings.table(body,Vector3(6.4,0.0,5.7),0.0,1.9,0.9,"none")
	Furnishings.piece(body,Vector3(0.3,0.04,0.18),Color(0.82,0.62,0.34),Vector3(5.9,0.84,5.7),0.2,false,SuperEgg.EPSILON_SOFT)
	Furnishings.piece(body,Vector3(0.18,0.07,0.18),Furnishings.CLAY,Vector3(6.9,0.86,5.8),0.0,false,2.2)
	Furnishings.shelf(body,Vector3(KITCHEN_WALL_X+0.28,0.0,7.0),-PI*0.5,1.6,3,"crocks")
	Furnishings.piece(body,Vector3(0.8,0.45,0.28),Furnishings.OAK,Vector3(7.7,0.45,7.55),0.0,true)
	Furnishings.piece(body,Vector3(0.22,0.05,0.2),Color(0.78,0.78,0.74),Vector3(7.5,0.93,7.55),0.0,false,2.2)
	Furnishings.barrel(body,Vector3(9.05,0.0,6.9),0.42)
	Furnishings.barrel(body,Vector3(9.05,0.0,7.55),0.42)
	_warm_light(Vector3(6.0,2.5,5.7),0.6,6.0)
	# Larder: shelves, casks and sacks along the west wall, clear of the two doors
	# and of the way between them; and the washroom beyond it.
	Furnishings.shelf(body,Vector3(-9.33,0.0,4.85),-PI*0.5,1.9,3,"boxes")
	Furnishings.barrel(body,Vector3(-8.35,0.0,4.3),0.42)
	Furnishings.barrel(body,Vector3(-7.7,0.0,4.3),0.42)
	Furnishings.sacks(body,Vector3(-8.7,0.0,5.3),4)
	Furnishings.washstand(body,Vector3(-4.4,0.0,7.6),0.0)
	# ---- Upper floor ------------------------------------------------------
	# The party room (front, west): two beds head to the front wall, a chest at the
	# foot of each with its hinge toward the bed (yaw PI: a chest's back, local +Z,
	# carries the hinge), a washstand between them. Its door is at x = -3.7.
	Furnishings.rug(body,Vector3(-3.7,floor_up,-5.0),0.0,Vector2(3.0,1.6),Furnishings.CLOTH_BLUE.darkened(0.2))
	Furnishings.chest(body,Vector3(-5.4,floor_up,-5.15),PI)
	Furnishings.chest(body,Vector3(-2.0,floor_up,-5.15),PI)
	Furnishings.washstand(body,Vector3(-3.7,floor_up,-7.6),0.0)
	Furnishings.peg_rail(body,Vector3(-6.4,floor_up,-4.6),-PI*0.5,1.2,1.7)
	# The middle guest room, door at x = 1.9.
	Furnishings.rug(body,Vector3(1.9,floor_up,-5.0),0.0,Vector2(2.6,1.6),Furnishings.CLOTH_RED.darkened(0.25))
	Furnishings.chest(body,Vector3(0.3,floor_up,-5.15),PI)
	Furnishings.chest(body,Vector3(3.5,floor_up,-5.15),PI)
	Furnishings.washstand(body,Vector3(1.9,floor_up,-7.6),0.0)
	Furnishings.peg_rail(body,Vector3(-0.8,floor_up,-4.6),-PI*0.5,1.2,1.7)
	# South cache room, east end of the front range. Its east end is the sole
	# parkour entry; furniture stays against the outer wall, leaving a clean route
	# from the gap to the chest.
	Furnishings.rug(body,Vector3(7.1,floor_up,-5.0),0.0,Vector2(2.5,1.8),Furnishings.CLOTH_GREEN.darkened(0.25))
	Furnishings.chest(body,Vector3(7.1,floor_up,-6.15),0.0,Furnishings.OAK_DARK,1.05,"ohio_inn_key_cache",[
		{"name":"Holt Inn Key"},{"name":"Fire Gem","quantity":2},{"name":"Blorb Slime"},
	])
	# Mira's room (rear, west): her own narrow bed head to the north wall, a chest of
	# keepsakes from the road, a lamp, a rug.
	var mira_bed := TownProps.build_bed(Color(0.56, 0.38, 0.30))
	mira_bed.name = "MiraBed"
	mira_bed.position = Vector3(-8.0, floor_up, 6.7)
	mira_bed.rotation.y = PI
	add_child(mira_bed)
	Furnishings.chest(body,Vector3(-8.0,floor_up,5.15),0.0,Furnishings.OAK_DARK.lightened(0.05),1.1)
	Furnishings.table(body,Vector3(-4.7,floor_up,6.7),0.0,0.9,0.6,"none")
	Furnishings.piece(body,Vector3(0.06,0.09,0.06),Color(1.0,0.82,0.45),Vector3(-4.7,floor_up+0.86,6.7),0.0,false,2.2)
	Furnishings.rug(body,Vector3(-6.0,floor_up,5.0),0.0,Vector2(2.6,1.6),Furnishings.CLOTH_GREEN.darkened(0.2))
	# The spare room (rear, middle): one bed (placed with the others) and its chest.
	Furnishings.chest(body,Vector3(-1.9,floor_up,5.15),0.0)
	Furnishings.table(body,Vector3(0.9,floor_up,6.9),0.0,1.1,0.6,"none")
	Furnishings.rug(body,Vector3(-0.4,floor_up,4.9),0.0,Vector2(2.2,1.5),Furnishings.CLOTH_RED.darkened(0.3))
	# Gallery seating about the hall opening's axis, west of the curved rail.
	Furnishings.rug(body,Vector3(3.6,floor_up,0.0),0.0,Vector2(1.6,2.4),Furnishings.CLOTH_GREEN.darkened(0.3))
	Furnishings.settle(body,Vector3(3.65,floor_up,0.0),-PI*0.5,1.5,Furnishings.CLOTH_BLUE)
	# Hollis's room (rear, east) is truly enclosed: one locked door. The settle and
	# chest sit along the exterior walls, away from the door's approach.
	Furnishings.settle(body,Vector3(7.5,floor_up,7.18),0.0,1.4,Furnishings.CLOTH_BLUE)
	Furnishings.chest(body,Vector3(8.75,floor_up,6.55),PI*0.5,Furnishings.OAK_DARK,1.0,"ohio_inn_guest_cache",[
		{"name":"Boxing Gloves"},{"name":"Fire Gem"},{"name":"Blorb Slime"},
	])
	_build_trapped_inn_guest()
	# The gallery: a bench and a shelf of boxes against the corridor walls, between
	# the doors, so the middle stays a clear walking way.
	Furnishings.bench(body,Vector3(-0.9,floor_up,-GALLERY_Z+0.3),0.0,1.35)
	Furnishings.shelf(body,Vector3(-3.2,floor_up,GALLERY_Z-0.28),0.0,1.6,3,"boxes")
	_warm_light(Vector3(-4.0,floor_up+3.0,-5.5),0.5,7.0)
	_warm_light(Vector3(1.9,floor_up+3.0,-5.5),0.5,7.0)
	_warm_light(Vector3(-1.0,floor_up+3.0,0.0),0.6,8.0)
	_warm_light(Vector3(0.0,floor_up+3.0,5.5),0.5,7.0)


func _build_trapped_inn_guest() -> void:
	var guest := NPC_SCENE.instantiate()
	guest.name = "TrappedInnGuest"
	guest.display_name = "Hollis"
	# Authored one-off NPCs must never fall back to skin-coloured garments.
	# These are assigned before add_child(), because NPC._ready() builds the
	# figure immediately on entering the tree.
	guest.skin_color = Color(0.68,0.46,0.31)
	guest.shirt_color = Color(0.18,0.34,0.48)
	guest.pants_color = Color(0.19,0.16,0.14)
	guest.shoe_color = Color(0.25,0.12,0.055)
	guest.hair_color = Color(0.16,0.075,0.035)
	guest.hair_style = FigureHair.STYLE_BUZZCUT
	guest.sleeve_style = ProceduralFigure.SLEEVE_STYLE_LONG
	guest.stationary = true
	guest.fixed_ground_y = global_position.y + TownProps.FLOOR_HEIGHT
	guest.facing_degrees = 180.0
	guest.position = Vector3(6.55,TownProps.FLOOR_HEIGHT,6.25)
	guest.talk_override = _talk_to_trapped_guest
	if _terrain_ref != null and guest.has_method("set_terrain_reference"):
		guest.set_terrain_reference(_terrain_ref)
	add_child(guest)


func _talk_to_trapped_guest() -> bool:
	if not WorldState.is_door_unlocked("ohio_inn_hollis_room"):
		DialogUI.show_line("Hollis","Please help me. I've been locked in here so long I nearly starved.")
		return true
	if not WorldState.ohio_inn_guest_rewarded:
		WorldState.ohio_inn_guest_rewarded = true
		TokoinWallet.add(10)
		DialogUI.show_line("Hollis","You opened the door. I thought I was going to starve in here. Please take these 10 Tokoins, and thank you.")
		return true
	DialogUI.show_line("Hollis","I won't forget that you let me out.")
	return true


func _add_rect_wall(body: StaticBody3D,position: Vector3,size: Vector3,color: Color) -> void:
	var box:=BoxMesh.new()
	box.size=size
	box.material=SolidModel.material(color,0.86,0.0)
	var panel:=MeshInstance3D.new()
	panel.mesh=box
	panel.position=position
	body.add_child(panel)
	CollisionPolicy.add_box(body,panel,size,position,Basis(),false)


func _build_bedroom_partition(color: Color) -> void:
	var partition := StaticBody3D.new()
	partition.name = "BedroomPartition"
	partition.collision_layer = 1
	# A doorway connects the common room to the private room; the remaining
	# wall keeps the beds out of the public entrance's sightline. The lodge's
	# doorway (x 0.3..2.7) sits beside the counter's west end, off the straight
	# line from the front door to the common room's middle.
	var panels: Array[Dictionary] = [
		{"position":Vector3(-5.0,1.55,1.15),"size":Vector3(9.2,3.1,0.18)},
		{"position":Vector3(5.2,1.55,1.15),"size":Vector3(4.2,3.1,0.18)},
		{"position":Vector3(1.0,2.78,1.15),"size":Vector3(3.0,0.64,0.18)},
	]
	if _is_lodge:
		panels = [
			{"position":Vector3(-4.65,1.55,1.15),"size":Vector3(9.9,3.1,0.18)},
			{"position":Vector3(6.15,1.55,1.15),"size":Vector3(6.9,3.1,0.18)},
			{"position":Vector3(1.5,2.78,1.15),"size":Vector3(2.4,0.64,0.18)},
		]
	for data in panels:
		var size: Vector3 = data["size"]
		var position: Vector3 = data["position"]
		var panel := SuperEgg.build_part(size*0.5,color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		panel.position = position
		partition.add_child(panel)
		CollisionPolicy.add_box(partition,panel,size,position,Basis(),false)
	add_child(partition)


func _build_bed(position: Vector3, index: int, lodge_yaw: float = PI) -> void:
	var bed := TownProps.build_bed(Color(0.28,0.42,0.62).lerp(Color(0.58,0.24,0.22),float(index%3)*0.22))
	bed.name = "PartyBed%d" % (index+1)
	bed.position=position
	if _is_lodge:
		# Modelled head toward -Z; the lodge beds put the head to the rear wall.
		bed.rotation.y=lodge_yaw
	add_child(bed)


func _build_service_rooms(color: Color) -> void:
	if _is_ohio_lodge:
		# The room itself is already part of the purpose-built ground plan.  Only
		# furnish it here; do not wrap it in a second set of walls and create the
		# former inexplicable sliver of inaccessible space.
		var ohio_toilet:=TownProps.build_dry_toilet()
		ohio_toilet.name="DryToilet"
		ohio_toilet.position=Vector3(-7.6,0.0,7.2)
		ohio_toilet.rotation.y=0.0
		add_child(ohio_toilet)
		return
	# The bedroom partition doubles as the bathroom's south wall, while the
	# building shell supplies its north and east walls. Only the west partition
	# is added here, eliminating the former unexplained nook between two walls.
	var wall:=StaticBody3D.new()
	wall.name="InnServiceRooms"
	wall.collision_layer=1
	var service_panels: Array[Dictionary] = [
		{"p":Vector3(_half_width-3.0,1.55,_half_depth-3.25),"s":Vector3(0.18,3.1,5.2)},
		{"p":Vector3(_half_width-1.5,1.55,_half_depth-5.85),"s":Vector3(3.0,3.1,0.18)},
	]
	if _is_lodge:
		# A real doorway in the west partition opens from the bedroom aisle.
		service_panels = [
			{"p":Vector3(_half_width-3.0,1.55,2.55),"s":Vector3(0.18,3.1,2.8)},
			{"p":Vector3(_half_width-3.0,1.55,6.75),"s":Vector3(0.18,3.1,2.5)},
			{"p":Vector3(_half_width-3.0,2.8,4.65),"s":Vector3(0.18,0.6,1.4)},
		]
	for data in service_panels:
		var size:Vector3=data["s"]
		var panel:=SuperEgg.build_part(size*0.5,color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
		panel.position=data["p"]
		wall.add_child(panel)
		CollisionPolicy.add_box(wall,panel,size,panel.position,Basis(),false)
	add_child(wall)
	var toilet:=ToiletFixtures.build(toilet_fixture)
	toilet.name="DryToilet"
	# Its tank/back is against the north wall; the user faces into the room.
	toilet.position=Vector3(_half_width-1.55,0.0,_half_depth-0.75)
	toilet.rotation.y=0.0
	add_child(toilet)


func _process(delta: float) -> void:
	if not _smoke_puffs.is_empty():
		ChimneySmoke.animate(_smoke_puffs,delta,_smoke_rng)


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
