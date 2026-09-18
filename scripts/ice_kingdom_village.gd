extends Node3D

const NPC_SCENE := preload("res://scenes/npc.tscn")
const ROOF_SNOW := ElementPalette.SNOW_BODY
const ROOF_STRUCTURE := Color(0.24, 0.18, 0.15)
const WALL_COLORS: Array[Color] = [Color(0.48,0.32,0.2), Color(0.58,0.42,0.28), Color(0.42,0.31,0.25)]
const WINTER_APPEARANCE := {
	"skin_colors": [
		Color(0.99, 0.89, 0.78), Color(0.47, 0.33, 0.23),
		Color(0.87, 0.68, 0.52), Color(0.25, 0.17, 0.12),
		Color(0.96, 0.82, 0.69), Color(0.62, 0.45, 0.32),
		Color(0.76, 0.58, 0.42), Color(0.33, 0.22, 0.16),
	],
	"shirt_colors": [
		Color(0.23, 0.4, 0.68), Color(0.62, 0.17, 0.22),
		Color(0.18, 0.5, 0.38), Color(0.48, 0.28, 0.62),
		Color(0.72, 0.43, 0.12), Color(0.16, 0.46, 0.56),
		Color(0.52, 0.24, 0.38), Color(0.28, 0.36, 0.52),
	],
	"pants_colors": [
		Color(0.16, 0.2, 0.3), Color(0.32, 0.22, 0.16),
		Color(0.22, 0.31, 0.25), Color(0.24, 0.18, 0.34),
		Color(0.38, 0.25, 0.12), Color(0.12, 0.3, 0.36),
		Color(0.34, 0.16, 0.22), Color(0.2, 0.25, 0.36),
	],
	"shoe_colors": [
		Color(0.12, 0.1, 0.09), Color(0.24, 0.13, 0.08),
		Color(0.1, 0.16, 0.18), Color(0.18, 0.1, 0.2),
		Color(0.3, 0.18, 0.08), Color(0.08, 0.18, 0.22),
		Color(0.22, 0.08, 0.1), Color(0.12, 0.14, 0.2),
	],
	"glove_colors": [
		Color(0.12, 0.15, 0.22), Color(0.38, 0.2, 0.12),
		Color(0.14, 0.28, 0.25), Color(0.28, 0.14, 0.34),
		Color(0.42, 0.27, 0.1), Color(0.12, 0.25, 0.32),
		Color(0.34, 0.12, 0.18), Color(0.18, 0.2, 0.28),
	],
	"hair_colors": [
		Color(0.08, 0.055, 0.04), Color(0.58, 0.36, 0.15),
		Color(0.28, 0.14, 0.065), Color(0.82, 0.74, 0.62),
		Color(0.55, 0.16, 0.08), Color(0.14, 0.09, 0.065),
		Color(0.68, 0.52, 0.28), Color(0.32, 0.3, 0.32),
	],
	"female_body_scales": [0.88, 0.93, 0.97, 1.0],
	"male_body_scales": [1.01, 1.06, 1.11, 1.15],
	"female_chest_scales": [0.9, 0.94, 0.97, 1.0],
	"male_chest_scales": [1.02, 1.07, 1.12, 1.17],
	"female_hip_scales": [1.02, 1.08, 1.13, 1.17],
	"male_hip_scales": [0.95, 0.99, 1.03, 1.07],
	"abdomen_scales": [1.0, 1.12, 1.04, 1.24, 1.08, 1.28, 1.16, 1.2],
	"female_hair_styles": [FigureHair.STYLE_PONYTAIL, FigureHair.STYLE_LONG, FigureHair.STYLE_BUN, FigureHair.STYLE_PIGTAILS],
	"male_hair_styles": [FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_AFRO, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_BUZZCUT],
	"long_hair_lengths": [0.04, 0.12, 0.08, 0.0],
	"dress_indices": [2, 6],
	"dress_has_covered_legs": true,
	"sleeve_style": ProceduralFigure.SLEEVE_STYLE_LONG,
}
const IDENTITIES := [
	{"name": "Elin", "female": true, "line": "The snow softens every sound in the village."},
	{"name": "Tomas", "female": false, "line": "The lake sings differently before a storm."},
	{"name": "Mara", "female": true, "line": "I mend gloves by the stove when the light fades."},
	{"name": "Soren", "female": false, "line": "Ice blorbs gather where the lake freezes clearest."},
	{"name": "Anja", "female": true, "line": "The mountain wind carries pine needles for miles."},
	{"name": "Niko", "female": false, "line": "Our roofs wear winter better than we do."},
	{"name": "Freya", "female": true, "line": "I saw something silver move beneath the fishing hole."},
]

var _terrain: Node
var _rng := RandomNumberGenerator.new()
## Dedicated to ChimneySmoke's own ongoing per-frame recycling (see
## _process() below) -- kept separate from _rng so an unrelated future draw
## against _rng during setup can't shift the smoke plumes' random sequence,
## or vice versa.
var _smoke_rng := RandomNumberGenerator.new()
var _smoke_puffs: Array[ChimneySmoke.Puff] = []


func _ready() -> void:
	_terrain = get_node("../Terrain")
	_rng.seed = 20260911
	_smoke_rng.seed = 5591
	_build_village()
	_build_fishing_camp()


func _process(delta: float) -> void:
	ChimneySmoke.animate(_smoke_puffs, delta, _smoke_rng)


func _build_village() -> void:
	var center: Vector2 = _terrain.get_village_center()
	var offsets: Array[Vector2] = [Vector2(-28,-18),Vector2(0,-25),Vector2(28,-15),Vector2(-31,13),Vector2(2,18),Vector2(31,15),Vector2(-5,40)]
	for i in offsets.size():
		var p: Vector2 = center + offsets[i]
		# Per direct correction ("the walls of the houses to be made out of
		# what looks like logs so they're more like log cabins") and ("put a
		# bed in pretty much everyone's home").
		var house := TownProps.build_building(2,2,1,ROOF_STRUCTURE,WALL_COLORS[i%WALL_COLORS.size()],WALL_COLORS[(i+1)%WALL_COLORS.size()],TownProps.FLOOR_COLOR,Color(-1.0,-1.0,-1.0),"log",true)
		_add_roof_snow_cap(house, 2, 2, 1)
		_build_fireplace(house, 2, 2)
		house.position = Vector3(p.x,_terrain.get_mesh_height(p.x,p.y),p.y)
		# TownProps puts its doorway on local -Z. Rotate that axis toward the
		# village centre (not local +Z, which was the recurring inversion).
		house.rotation.y = atan2(offsets[i].x, offsets[i].y)
		add_child(house)
		_spawn_villager(center + offsets[i]*0.62, i)
	var inn_pos := center + Vector2(13.0, 39.0)
	VillageInn.create(self, _terrain, Vector3(inn_pos.x, _terrain.get_mesh_height(inn_pos.x, inn_pos.y), inn_pos.y), "ice_kingdom", "snow_village_inn", 20, "Astrid Snowrest", ROOF_STRUCTURE, WALL_COLORS[0], WINTER_APPEARANCE)
	_build_winter_merchant(center)


## A small winter-goods stall makes the Toboggan a normal piece of this
## village's economy rather than a debug-only object. Its displayed hat is
## built from the exact same catalog geometry used in hand and inventory.
func _build_winter_merchant(center: Vector2) -> void:
	var offset:=Vector2(42.0,-34.0)
	var position_2d:=center+offset
	var yaw:=atan2(offset.x,offset.y)
	var stall_data:=TownProps.build_stall(Color(0.31,0.38,0.58))
	var stall:=stall_data["body"] as StaticBody3D
	stall.name="WinterGoodsStall"
	stall.position=Vector3(position_2d.x,_terrain.get_mesh_height(position_2d.x,position_2d.y),position_2d.y)
	stall.rotation.y=yaw
	add_child(stall)
	# Catalog item scale is already authored as a handheld/wearable object.
	# The former 1.5 multiplier made the counter model substantially larger
	# than the same form after a blorb absorbed and wore it.
	var display:=TobogganHelm.build_visual(1.0)
	display.name="DisplayToboggan"
	display.position=Vector3(0.0,float(stall_data["counter_y"])+0.08,0.0)
	stall.add_child(display)
	var vendor: Node3D=NPC_SCENE.instantiate()
	vendor.set_terrain_reference(_terrain)
	vendor.stationary=true
	vendor.is_vendor=true
	vendor.display_name="Solveig Woolcap"
	vendor.shop_category="snow"
	var lines: Array[String]=[
		"A warm crown makes the mountain wind feel almost friendly.",
		"I knit the cuff thick. Winter always finds the thin places.",
	]
	vendor.vendor_lines=lines
	VillagerAppearance.apply_profile(vendor,IDENTITIES.size()+1,4,true,WINTER_APPEARANCE)
	var layout:=TownProps.vendor_layout(position_2d,yaw)
	var vendor_position:=layout["position"] as Vector2
	vendor.position=Vector3(vendor_position.x,_terrain.get_mesh_height(vendor_position.x,vendor_position.y),vendor_position.y)
	vendor.facing_degrees=layout["facing_degrees"] as float
	add_child(vendor)


func _spawn_villager(pos: Vector2, index: int) -> void:
	var npc: Node3D = NPC_SCENE.instantiate()
	npc.set_terrain_reference(_terrain)
	var identity: Dictionary = IDENTITIES[index]
	npc.display_name = identity["name"]
	var lines: Array[String] = [identity["line"]]
	npc.talk_lines = lines
	var gender_index: int = _gender_index_through(index, bool(identity["female"]))
	VillagerAppearance.apply_profile(npc, index, gender_index, bool(identity["female"]), WINTER_APPEARANCE)
	npc.wander_boundary_center = _terrain.get_village_center()
	npc.wander_boundary_radius = _terrain.get_village_radius() - 8.0
	npc.position = Vector3(pos.x,_terrain.get_mesh_height(pos.x,pos.y),pos.y)
	add_child(npc)


func _build_fishing_camp() -> void:
	var hole: Vector2 = _terrain.get_fishing_hole_center()
	var ice_y: float = _terrain.get_ice_level()
	var fisher_pos := hole + Vector2(3.8, 0.0)
	var hut_pos := hole + Vector2(7.0,1.5)
	var hut := TownProps.build_building(1,1,1,ROOF_STRUCTURE,Color(0.45,0.31,0.2))
	_add_roof_snow_cap(hut, 1, 1, 1)
	hut.position = Vector3(hut_pos.x,ice_y,hut_pos.y)
	var hut_to_fisher: Vector2 = fisher_pos - hut_pos
	# The hut door is local -Z, so its yaw is the negated target heading.
	hut.rotation.y = atan2(-hut_to_fisher.x, -hut_to_fisher.y)
	add_child(hut)
	var fisher: Node3D = NPC_SCENE.instantiate()
	fisher.set_terrain_reference(_terrain)
	fisher.fixed_ground_y = ice_y + 0.08
	fisher.display_name = "Ivar"
	fisher.stationary = true
	VillagerAppearance.apply_profile(fisher, IDENTITIES.size(), 3, false, WINTER_APPEARANCE)
	var fisher_to_hole: Vector2 = hole - fisher_pos
	fisher.facing_degrees = rad_to_deg(atan2(fisher_to_hole.x, fisher_to_hole.y))
	var lines: Array[String] = ["The hole stays open if I clear it before dawn.", "Some days the fish watch me more closely than I watch them."]
	fisher.talk_lines = lines
	fisher.position = Vector3(fisher_pos.x,ice_y+0.08,fisher_pos.y)
	add_child(fisher)
	# The target sits below the ice opening. NPC owns the articulated rod and
	# computes its line from the live rod tip every frame.
	# The rod/line are world-space geometry parented to current_scene. During
	# this village's _ready(), that root is still constructing its children;
	# defer the gear creation one frame so the three add_child calls are legal.
	fisher.call_deferred("equip_fishing_rod",Vector3(hole.x,ice_y-1.1,hole.y))


func _gender_index_through(population_index: int, female: bool) -> int:
	var gender_index := 0
	for i in population_index:
		if bool(IDENTITIES[i]["female"]) == female:
			gender_index += 1
	return gender_index


## An interior hearth (a real recessed firebox opening -- back panel + two
## side cheeks + a hearth floor, not a solid block -- topped by a mantel and
## a stone chimney breast) whose flue climbs up through the actual sloped
## roof, per direct instruction: "put a fireplace... with a chimney going up
## and out through the roof... in the bottom of the fireplace, there should
## be some actual fire burning." Placed against the north (rear) wall,
## centered in X so it stays clear of both the south-wall doorway and
## _build_house_bed()'s own north-WEST corner placement. Height math mirrors
## _add_roof_snow_cap()'s own peak_y formula so the flue's top lands just
## above the real roof surface at this same Z, not a guessed constant.
## Per direct correction ("the fireplace seems a bit too small and the
## chimney too skinny... the fire element... is not like in an opening like
## a normal fireplace would have. It's sort of like being smushed") -- the
## old version was one solid stone block with the flame overlapping it; this
## builds an actual open recess (like a real fireplace) with the flame
## genuinely sitting inside it, and every dimension is bigger throughout.
const FIREPLACE_STONE := Color(0.34, 0.34, 0.36)
const HEARTH_OPENING_WIDTH := 0.95
const HEARTH_OPENING_HEIGHT := 0.95
const HEARTH_DEPTH := 0.55
const HEARTH_WALL_THICKNESS := 0.13
func _build_fireplace(house: StaticBody3D, w: int, d: int) -> void:
	var hearth_z := float(d) * TownProps.CELL_SIZE * 0.5 - 0.5
	var half_footprint_w := HEARTH_OPENING_WIDTH * 0.5 + HEARTH_WALL_THICKNESS
	var half_depth_local := HEARTH_DEPTH * 0.5

	var hearth_floor := SuperEgg.build_part(
		Vector3(half_footprint_w, 0.06, half_depth_local), FIREPLACE_STONE,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	hearth_floor.position = Vector3(0.0, 0.06, hearth_z)
	house.add_child(hearth_floor)
	CollisionPolicy.add_box(
		house, hearth_floor, Vector3(half_footprint_w * 2.0, 0.12, half_depth_local * 2.0),
		hearth_floor.position, Basis(), true
	)
	var hearth_top := 0.12

	# Back panel closes the recess at the far (wall) side -- the near side,
	# toward the room, stays open: that opening is the whole point.
	var back := SuperEgg.build_part(
		Vector3(half_footprint_w, HEARTH_OPENING_HEIGHT * 0.5, HEARTH_WALL_THICKNESS * 0.5),
		FIREPLACE_STONE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	var back_z := hearth_z + half_depth_local - HEARTH_WALL_THICKNESS * 0.5
	back.position = Vector3(0.0, hearth_top + HEARTH_OPENING_HEIGHT * 0.5, back_z)
	house.add_child(back)
	CollisionPolicy.add_box(
		house, back, Vector3(half_footprint_w * 2.0, HEARTH_OPENING_HEIGHT, HEARTH_WALL_THICKNESS),
		back.position, Basis(), true
	)

	var sides: Array[float] = [-1.0, 1.0]
	for side in sides:
		var cheek := SuperEgg.build_part(
			Vector3(HEARTH_WALL_THICKNESS * 0.5, HEARTH_OPENING_HEIGHT * 0.5, half_depth_local),
			FIREPLACE_STONE, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
		)
		var cheek_x := side * (HEARTH_OPENING_WIDTH * 0.5 + HEARTH_WALL_THICKNESS * 0.5)
		cheek.position = Vector3(cheek_x, hearth_top + HEARTH_OPENING_HEIGHT * 0.5, hearth_z)
		house.add_child(cheek)
		CollisionPolicy.add_box(
			house, cheek, Vector3(HEARTH_WALL_THICKNESS, HEARTH_OPENING_HEIGHT, half_depth_local * 2.0),
			cheek.position, Basis(), true
		)

	var mantel_thickness := 0.18
	var mantel := SuperEgg.build_part(
		Vector3(half_footprint_w + 0.06, mantel_thickness * 0.5, half_depth_local + 0.06),
		FIREPLACE_STONE.darkened(0.05), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
	)
	var mantel_y := hearth_top + HEARTH_OPENING_HEIGHT + mantel_thickness * 0.5
	mantel.position = Vector3(0.0, mantel_y, hearth_z)
	house.add_child(mantel)
	CollisionPolicy.add_box(
		house, mantel, Vector3((half_footprint_w + 0.06) * 2.0, mantel_thickness, (half_depth_local + 0.06) * 2.0),
		mantel.position, Basis(), true
	)

	var breast_height := 1.85
	var breast := SuperEgg.build_part(
		Vector3(half_footprint_w * 0.85, breast_height * 0.5, half_depth_local * 0.8),
		FIREPLACE_STONE.darkened(0.05), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	var breast_y := mantel_y + mantel_thickness * 0.5 + breast_height * 0.5
	breast.position = Vector3(0.0, breast_y, hearth_z)
	house.add_child(breast)
	CollisionPolicy.add_box(
		house, breast, Vector3(half_footprint_w * 1.7, breast_height, half_depth_local * 1.6),
		breast.position, Basis(), true
	)

	# Same peak_y derivation _add_roof_snow_cap() uses (this house is always
	# floors=1), so the flue's own top sits just above the true roof surface
	# at this exact Z rather than a hand-guessed height.
	var half_depth := float(d) * TownProps.CELL_SIZE * 0.5 + TownProps.ROOF_OVERHANG
	var slope_len := half_depth / cos(TownProps.ROOF_PITCH)
	var peak_y := TownProps.FLOOR_HEIGHT + slope_len * sin(TownProps.ROOF_PITCH)
	var roof_underside_y := peak_y - tan(TownProps.ROOF_PITCH) * absf(hearth_z)
	var shaft_base_y := breast_y + breast_height * 0.5
	var shaft_top_y := roof_underside_y + 0.7
	var shaft_height := maxf(shaft_top_y - shaft_base_y, 0.3)
	var shaft_radius := 0.24
	var shaft := SuperEgg.build_part(
		Vector3(shaft_radius, shaft_height * 0.5, shaft_radius), FIREPLACE_STONE,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	shaft.position = Vector3(0.0, shaft_base_y + shaft_height * 0.5, hearth_z)
	house.add_child(shaft)
	CollisionPolicy.add_box(
		house, shaft, Vector3(shaft_radius * 2.0, shaft_height, shaft_radius * 2.0), shaft.position, Basis(), true
	)

	var cap := SuperEgg.build_part(
		Vector3(shaft_radius * 1.35, 0.07, shaft_radius * 1.35), FIREPLACE_STONE.darkened(0.1),
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	cap.position = Vector3(0.0, shaft_base_y + shaft_height + 0.07, hearth_z)
	house.add_child(cap)

	# The real fire model (see ParticleFX.build_flame_particles() -- the
	# exact same recipe fire_kingdom_village.gd's own braziers use, just
	# tuned for an indoor hearth), now genuinely sitting inside the open
	# recess above, not overlapping solid stone.
	var flame := ParticleFX.build_flame_particles(11, 0.6, 0.85, 1.8, 2.8, -0.6)
	flame.position = Vector3(0.0, hearth_top + 0.05, hearth_z)
	house.add_child(flame)
	CollisionPolicy.mark_decorative(flame)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, hearth_top + 0.35, hearth_z)
	light.light_color = Color(1.0, 0.42, 0.12)
	light.light_energy = 1.1
	light.omni_range = 8.0
	light.shadow_enabled = false
	house.add_child(light)

	_smoke_puffs.append_array(
		ChimneySmoke.spawn(house, Vector3(0.0, shaft_base_y + shaft_height + 0.12, hearth_z), _smoke_rng, 4)
	)


## The structural roof stays dark on its underside. These two very thin
## panels sit only on the outward/upward faces, like settled snow rather than
## recolouring the whole solid roof (which made its underside look snowy).
func _add_roof_snow_cap(building: Node3D, width_cells: int, depth_cells: int, floors: int) -> void:
	var width: float = float(width_cells) * TownProps.CELL_SIZE + TownProps.ROOF_OVERHANG * 2.0
	var half_depth: float = float(depth_cells) * TownProps.CELL_SIZE * 0.5 + TownProps.ROOF_OVERHANG
	var slope_length: float = half_depth / cos(TownProps.ROOF_PITCH)
	var peak_y: float = float(floors) * TownProps.FLOOR_HEIGHT + slope_length * sin(TownProps.ROOF_PITCH)
	var ridge := Vector3(0.0, peak_y, 0.0)
	for north_side in [true, false]:
		var z_sign := 1.0 if north_side else -1.0
		var length_direction := Vector3(0.0, -sin(TownProps.ROOF_PITCH), z_sign * cos(TownProps.ROOF_PITCH)).normalized()
		var width_direction := Vector3.RIGHT
		var outward_normal := width_direction.cross(length_direction).normalized()
		if outward_normal.y < 0.0:
			outward_normal = -outward_normal
		var snow := SuperEgg.build_part(
			Vector3(width * 0.5, 0.025, slope_length * 0.5),
			ROOF_SNOW,
			SuperEgg.EPSILON_FLAT,
			SuperEgg.EPSILON_FLAT
		)
		snow.name = "RoofSnowCap"
		snow.basis = Basis(width_direction, outward_normal, length_direction)
		snow.position = ridge + length_direction * slope_length * 0.5 + outward_normal * 0.035
		building.add_child(snow)
