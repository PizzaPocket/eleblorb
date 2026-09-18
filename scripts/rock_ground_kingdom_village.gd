extends Node3D

const NPC_SCENE := preload("res://scenes/npc.tscn")
const IDENTITIES := [
	{"name":"Petra","female":true,"line":"The canyon keeps yesterday's heat long after sunset."},
	{"name":"Cairn","female":false,"line":"Every terrace has its own color when the rain comes."},
	{"name":"Mica","female":true,"line":"The cliff swallows sound, then sends it back changed."},
	{"name":"Flint","female":false,"line":"We build low. The wind has less to argue with that way."},
	{"name":"Ochre","female":true,"line":"There are bones in the eastern basin larger than houses."},
	{"name":"Shale","female":false,"line":"Ground blorbs like the deep washes. Rock blorbs prefer the ledges."},
	{"name":"Terra","female":true,"line":"The old paths follow the stone, never the straight line."},
	{"name":"Rook","female":false,"line":"Mind your footing where the red shelf breaks away."},
]
const EARTH_PROFILE := {
	"skin_colors":[Color(0.30,0.20,0.14),Color(0.72,0.51,0.34),Color(0.91,0.72,0.55),Color(0.48,0.31,0.21),Color(0.82,0.61,0.43),Color(0.23,0.15,0.11),Color(0.62,0.42,0.29),Color(0.94,0.80,0.66)],
	"shirt_colors":[Color(0.56,0.22,0.12),Color(0.24,0.38,0.25),Color(0.69,0.48,0.16),Color(0.30,0.27,0.42),Color(0.15,0.39,0.42),Color(0.48,0.25,0.16),Color(0.35,0.42,0.17),Color(0.58,0.34,0.22)],
	"pants_colors":[Color(0.22,0.16,0.13),Color(0.31,0.24,0.18),Color(0.18,0.25,0.23),Color(0.27,0.21,0.31),Color(0.34,0.24,0.15),Color(0.16,0.19,0.22),Color(0.29,0.31,0.18),Color(0.25,0.18,0.14)],
	"shoe_colors":[Color(0.12,0.09,0.07),Color(0.18,0.12,0.08),Color(0.11,0.14,0.13),Color(0.15,0.11,0.17),Color(0.20,0.13,0.07),Color(0.09,0.10,0.11),Color(0.16,0.17,0.09),Color(0.14,0.09,0.07)],
	# Per direct correction ("this is a non-glove wearing population because
	# those gloves would really only be relevant in the cold climates") --
	# alpha 0 is this codebase's own established "don't render this optional
	# accessory" sentinel (see procedural_figure.gd's own build() -- a
	# transparent hand_color_override falls back to the villager's own skin
	# color instead of a distinct glove color), not a special-cased flag.
	"glove_colors":[Color(0,0,0,0)],
	"hair_colors":[Color(0.07,0.045,0.03),Color(0.30,0.15,0.07),Color(0.62,0.40,0.18),Color(0.15,0.09,0.055),Color(0.46,0.20,0.08),Color(0.74,0.62,0.43),Color(0.24,0.17,0.12),Color(0.09,0.06,0.04)],
	"female_body_scales":[0.89,0.94,0.98,1.02],"male_body_scales":[1.0,1.06,1.11,1.16],
	"female_chest_scales":[0.9,0.94,0.98,1.0],"male_chest_scales":[1.02,1.07,1.12,1.16],
	"female_hip_scales":[1.02,1.08,1.13,1.17],"male_hip_scales":[0.95,1.0,1.04,1.08],
	"abdomen_scales":[1.0,1.12,1.05,1.22,1.08,1.18,1.03,1.15],
	"female_hair_styles":[FigureHair.STYLE_PONYTAIL,FigureHair.STYLE_LONG,FigureHair.STYLE_BUN,FigureHair.STYLE_PIGTAILS],
	"male_hair_styles":[FigureHair.STYLE_FLAT_TOP,FigureHair.STYLE_AFRO,FigureHair.STYLE_BUZZCUT,FigureHair.STYLE_BUZZCUT],
	"long_hair_lengths":[0.05,0.12,0.08,0.02],"dress_indices":[2,6],"dress_has_covered_legs":true,
}
var _terrain: Node
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_terrain = get_node("../Terrain")
	_rng.seed = 20260916
	_build_town()

func _build_town() -> void:
	var center: Vector2 = _terrain.get_village_center()
	var offsets: Array[Vector2] = [Vector2(-31,-18),Vector2(0,-29),Vector2(31,-17),Vector2(-35,15),Vector2(0,23),Vector2(35,14),Vector2(-22,43),Vector2(24,42)]
	for i in offsets.size():
		var point: Vector2 = center+offsets[i]
		# add_bed=true per direct instruction ("put a bed in pretty much
		# everyone's home").
		var house := TownProps.build_building(2,2,1,Color(0.36,0.22,0.14),Color(0.55,0.39,0.25),Color(0.42,0.29,0.18),TownProps.FLOOR_COLOR,Color(-1.0,-1.0,-1.0),"panel",true)
		house.position = Vector3(point.x,_terrain.get_mesh_height(point.x,point.y),point.y)
		house.rotation.y = atan2(offsets[i].x,offsets[i].y)
		add_child(house)
		# Per direct instruction ("construct some of the walls out of stone
		# masonry... take actual stone shapes... and fit them together into
		# a tight wall masonry structure... perhaps only for the front
		# facade, the side the door is on").
		_add_stone_facade(house, 2, 2)
		_spawn_villager(center+offsets[i]*0.62,i)
	var inn_point := center+Vector2(18.0,-48.0)
	VillageInn.create(self,_terrain,Vector3(inn_point.x,_terrain.get_mesh_height(inn_point.x,inn_point.y),inn_point.y),"rock_ground_kingdom","stone_rest_inn",20,"Dolma Hearthstone",Color(0.28,0.18,0.12),Color(0.52,0.36,0.22),EARTH_PROFILE)
	_build_well(center)

## Clads the south (door) wall's own two non-door columns in a tight grid of
## small overlapping boulders -- NatureProps.build_rock(), the exact same
## boxy-rounded canyon stone every rock/ground biome scatter already uses,
## not a lookalike shape built separately. Non-collidable: purely a facing
## layer in front of the house's own already-solid wall. Skips the door's
## own column entirely (its wood jambs/lintel already read as a distinct
## door frame, which is normal even against a real stone facade).
func _add_stone_facade(house: StaticBody3D, w: int, d: int) -> void:
	var door_ix := int(w / 2.0)
	var wall_z := -float(d) * TownProps.CELL_SIZE * 0.5
	var facade_z := wall_z - 0.32
	const ROWS := 4
	const COLS := 3
	for ix in w:
		if ix == door_ix:
			continue
		var cell_x := (float(ix) - (float(w) - 1.0) / 2.0) * TownProps.CELL_SIZE
		for row in ROWS:
			for col in COLS:
				var rock_radius: float = _rng.randf_range(0.32, 0.46)
				var rx: float = cell_x + (float(col) - (float(COLS) - 1.0) / 2.0) * (TownProps.CELL_SIZE / float(COLS)) + _rng.randf_range(-0.1, 0.1)
				var ry: float = (float(row) + 0.5) * (TownProps.FLOOR_HEIGHT / float(ROWS)) + _rng.randf_range(-0.05, 0.05)
				var tint: Color = NatureProps.ROCK_COLOR.darkened(_rng.randf_range(0.0, 0.15))
				var rock := NatureProps.build_rock(rock_radius, false, tint)
				rock.position = Vector3(rx, ry - rock_radius * 0.7, facade_z)
				rock.rotation.y = _rng.randf_range(0.0, TAU)
				house.add_child(rock)


func _spawn_villager(point: Vector2,index: int) -> void:
	var npc: Node3D = NPC_SCENE.instantiate()
	npc.set_terrain_reference(_terrain)
	var identity: Dictionary = IDENTITIES[index]
	npc.display_name = identity["name"]
	var lines: Array[String] = [identity["line"]]
	npc.talk_lines = lines
	var female: bool = bool(identity["female"])
	VillagerAppearance.apply_profile(npc,index,floori(float(index)*0.5),female,EARTH_PROFILE)
	npc.wander_boundary_center = _terrain.get_village_center()
	npc.wander_boundary_radius = _terrain.get_village_radius()-7.0
	npc.position = Vector3(point.x,_terrain.get_mesh_height(point.x,point.y),point.y)
	add_child(npc)

func _build_well(center: Vector2) -> void:
	var well := StaticBody3D.new()
	well.collision_layer = 1
	for i in 16:
		var angle: float = TAU*float(i)/16.0
		var position := Vector3(cos(angle)*3.2,0.48,sin(angle)*3.2)
		var stone := SuperEgg.build_part(Vector3(0.68,0.48,0.42),Color(0.38,0.31,0.25),SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT)
		stone.position = position
		stone.rotation.y = -angle
		well.add_child(stone)
		CollisionPolicy.add_box(well,stone,Vector3(1.3,0.96,0.78),position,Basis(Vector3.UP,-angle),true)
	well.position = Vector3(center.x,_terrain.get_mesh_height(center.x,center.y),center.y)
	add_child(well)
