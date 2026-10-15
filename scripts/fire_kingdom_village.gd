extends Node3D

const FireCalderaVara := preload("res://scripts/fire_caldera_vara.gd")
const FireCalderaCivic := preload("res://scripts/fire_caldera_civic.gd")
const FireCalderaIren := preload("res://scripts/fire_caldera_iren.gd")
const FireCalderaAro := preload("res://scripts/fire_caldera_aro.gd")

const NPC_SCENE:=preload("res://scenes/npc.tscn")
const LAVA_SLIDE_SCENE := preload("res://scenes/lava_slide.tscn")
const REST_WORLD := "fire_kingdom"
const REST_POINT := "caldera_village_inn"
const LAVA_PERSON_COLOR := Color(0.92, 0.24, 0.04)
## The molten material deliberately unifies surface color, but the complete
## human appearance profile still supplies distinct silhouettes underneath it.
## Eris uses the same molten-body palette as the Fire people while retaining
## the full human silhouette controls underneath it.
const FIRE_APPEARANCE := {
	"skin_colors": [LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR],
	"shirt_colors": [LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR],
	"pants_colors": [LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR],
	"shoe_colors": [LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR],
	"glove_colors": [LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR],
	"hair_colors": [LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR, LAVA_PERSON_COLOR],
	"female_body_scales": [0.87, 0.92, 0.97, 1.01],
	"male_body_scales": [1.0, 1.06, 1.12, 1.17],
	"female_chest_scales": [0.88, 0.93, 0.97, 1.0],
	"male_chest_scales": [1.03, 1.08, 1.13, 1.18],
	"female_hip_scales": [1.01, 1.07, 1.12, 1.17],
	"male_hip_scales": [0.94, 0.99, 1.03, 1.08],
	"abdomen_scales": [1.0, 1.16, 1.06, 1.3, 1.1, 1.24, 1.04, 1.2],
	"female_hair_styles": [FigureHair.STYLE_LONG, FigureHair.STYLE_BUN, FigureHair.STYLE_PONYTAIL, FigureHair.STYLE_PIGTAILS],
	"male_hair_styles": [FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_AFRO, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_BUZZCUT],
	"long_hair_lengths": [0.04, 0.1, 0.14, 0.07],
	"dress_indices": [0, 2, 6],
	"dress_has_covered_legs": false,
	"sleeve_style": ProceduralFigure.SLEEVE_STYLE_LONG,
}
var _terrain:Node

func _ready()->void:
	_terrain=get_node("../Terrain")
	# The surveyed caldera buildings are the Fire settlement. The former ring
	# of generic TownProps houses, placeholder residents, braziers and fountain
	# occupied the same ground and clipped through the authored city, so none of
	# that transitional settlement layer is spawned anymore.
	_spawn_lava_slide()
	_build_guest_house()
	_build_nahl()
	_build_oren()
	_build_renewal()
	_build_kel()
	_build_vara()
	_build_civic()
	_build_iren()
	_build_aro()


## Tovan, Miru and Kes's thermal control works and adjoining home.
func _build_aro()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("ARO")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live ARO socket is unavailable")
		return
	var body:=FireCalderaAro.build(frame,FireCalderaPlan.plot("ARO"),line)
	FireCalderaAro.register_lava(body,_terrain)


## Selka, Aru and Mena's residence and its glazed family bridge to Civic.
func _build_iren()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("IREN")
	var civic_line:Dictionary=_terrain.get_caldera_survey("CIVIC")
	if frame==null or line.is_empty() or civic_line.is_empty():
		push_error("FireKingdomVillage: live IREN or CIVIC socket is unavailable")
		return
	var body:=FireCalderaIren.build(frame,FireCalderaPlan.plot("IREN"),line,civic_line)
	FireCalderaIren.register_lava(body,_terrain)


## Aru and Selka's council, school, archive and upper observatory.
func _build_civic()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("CIVIC")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live CIVIC socket is unavailable")
		return
	FireCalderaCivic.build(frame,FireCalderaPlan.plot("CIVIC"),line)


## Omi and Talen's glass-and-metal studio, daylight court and home.
func _build_vara()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("VARA")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live VARA socket is unavailable")
		return
	var body:=FireCalderaVara.build(frame,FireCalderaPlan.plot("VARA"),line)
	FireCalderaVara.register_lava(body,_terrain)


## The Kel foundry with its residence on the back row's roof.
func _build_kel()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("KEL")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live KEL socket is unavailable")
		return
	var body:=FireCalderaKel.build(frame,FireCalderaPlan.plot("KEL"),line)
	FireCalderaKel.register_lava(body,_terrain)


## The Renewal terrace and its slumped-glass canopy, on its surveyed plinth.
func _build_renewal()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("RENEWAL")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live RENEWAL socket is unavailable")
		return
	FireCalderaRenewal.build(frame,FireCalderaPlan.plot("RENEWAL"),line)


## The Oren mineral house, split level, on its surveyed plinth.
func _build_oren()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("OREN")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live OREN socket is unavailable")
		return
	var body:=FireCalderaOren.build(frame,FireCalderaPlan.plot("OREN"),line)
	FireCalderaOren.register_lava(body,_terrain)


## The Nahl tempering hall and Eris's house, on its surveyed plinth; its
## molten floor and lava bed join the terrain's lava queries.
func _build_nahl()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("NAHL")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live NAHL socket is unavailable")
		return
	var body:=FireCalderaNahl.build(frame,FireCalderaPlan.plot("NAHL"),line)
	FireCalderaNahl.register_lava(body,_terrain)


## First finished building of the replacement city. It is placed in the same
## local frame as its surveyed plinth, and the old generic inn is not built.
func _build_guest_house()->void:
	var frame:Node3D=_terrain.get_caldera_frame()
	var line:Dictionary=_terrain.get_caldera_survey("GUEST")
	if frame==null or line.is_empty():
		push_error("FireKingdomVillage: live GUEST socket is unavailable")
		return
	var body:=FireCalderaBuildings.guest_house(frame,FireCalderaPlan.plot("GUEST"),line)
	var wake:=body.get_node("WakeMarker") as Marker3D
	var stand:=body.get_node("StandMarker") as Marker3D
	var gather:=body.get_node("GatherMarker") as Marker3D
	var keeper_at:Vector3=(body.get_node("KeeperStand") as Marker3D).position
	var keeper:=NPC_SCENE.instantiate()
	keeper.name="ErisNahl"
	keeper.display_name="Eris Nahl"
	keeper.stationary=true
	keeper.facing_degrees=0.0
	keeper.fixed_ground_y=body.global_position.y+keeper_at.y
	VillagerAppearance.apply_profile(keeper,6,3,true,FIRE_APPEARANCE)
	keeper.lava_body=true
	var eris_lines:Array[String]=[
		"The guest rooms stay cool. I check the wall cavities whenever someone arrives.",
		"If the mountain keeps its temper, so can we.",
		"Leave the ash on the terrace. It has enough stories already.",
	]
	keeper.talk_lines=eris_lines
	keeper.dialog_actions_provider=func()->Array[Dictionary]:
		return [TransactionInteraction.paid_action(
			"Rest for the night",int(FireCalderaPlan.REST_POINT["fee"]),
			func()->void:
				if RecoveryManager.begin_paid_rest(REST_WORLD,REST_POINT):
					DialogUI.hide_dialog(),
			"Your purse feels too light.",
			func()->bool:return RecoveryManager.can_rest()
		)]
	keeper.set_terrain_reference(_terrain)
	keeper.position=keeper_at
	body.add_child(keeper)
	RecoveryManager.register_rest_point.call_deferred(REST_WORLD,REST_POINT,wake.global_transform,stand.global_transform,gather.global_position)


func _spawn_lava_slide() -> void:
	# A compact rocky roaming patch between the western and northern volcanic
	# bowls keeps him visibly amid the volcanoes without sending an ordinary
	# ground-bound NPC through a lava river or into the protected village.
	var roam_center := Vector2(-62.0, -224.0)
	var lava_slide := LAVA_SLIDE_SCENE.instantiate() as Node3D
	lava_slide.set_terrain_reference(_terrain)
	lava_slide.wander_boundary_center = roam_center
	lava_slide.wander_boundary_radius = 22.0
	lava_slide.position = Vector3(
		roam_center.x,
		_terrain.get_mesh_height(roam_center.x, roam_center.y),
		roam_center.y
	)
	add_child(lava_slide)
