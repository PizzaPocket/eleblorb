extends Node3D

const NPC_SCENE := preload("res://scenes/npc.tscn")
const ROOF_SNOW := Color(0.96, 0.98, 1.0)
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


func _ready() -> void:
	_terrain = get_node("../Terrain")
	_rng.seed = 20260911
	_build_village()
	_build_fishing_camp()


func _build_village() -> void:
	var center: Vector2 = _terrain.get_village_center()
	var offsets: Array[Vector2] = [Vector2(-28,-18),Vector2(0,-25),Vector2(28,-15),Vector2(-31,13),Vector2(2,18),Vector2(31,15),Vector2(-5,40)]
	for i in offsets.size():
		var p: Vector2 = center + offsets[i]
		var house := TownProps.build_building(2,2,1,ROOF_STRUCTURE,WALL_COLORS[i%WALL_COLORS.size()],WALL_COLORS[(i+1)%WALL_COLORS.size()])
		_add_roof_snow_cap(house, 2, 2, 1)
		house.position = Vector3(p.x,_terrain.get_mesh_height(p.x,p.y),p.y)
		# TownProps puts its doorway on local -Z. Rotate that axis toward the
		# village centre (not local +Z, which was the recurring inversion).
		house.rotation.y = atan2(offsets[i].x, offsets[i].y)
		add_child(house)
		_spawn_villager(center + offsets[i]*0.62, i)


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
	fisher.equip_fishing_rod(Vector3(hole.x, ice_y - 1.1, hole.y))


func _gender_index_through(population_index: int, female: bool) -> int:
	var gender_index := 0
	for i in population_index:
		if bool(IDENTITIES[i]["female"]) == female:
			gender_index += 1
	return gender_index


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
