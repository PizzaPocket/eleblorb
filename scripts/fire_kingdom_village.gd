extends Node3D

const NPC_SCENE:=preload("res://scenes/npc.tscn")
const LAVA_SLIDE_SCENE := preload("res://scenes/lava_slide.tscn")
const NAMES:=["Cindra","Basal","Ember","Scoria","Vesta","Pyra","Cinder","Magmus"]
const LINES:=["The caldera shelters us from the ash wind.","Every stone here remembers being liquid.","The small cones have been restless tonight.","Fire blorbs sleep closest to the warm cracks.","Our village floor is the oldest part of the crater.","The rim glows before an eruption.","Nothing stays cold for long down here.","I can hear the mountain shifting under us."]
const LAVA_PERSON_COLOR := Color(0.92, 0.24, 0.04)
## The molten material deliberately unifies surface color, but the complete
## human appearance profile still supplies distinct silhouettes underneath it.
## Four women and four men consume each gender pool once without repetition.
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
var _rng:=RandomNumberGenerator.new()

func _ready()->void:
	_terrain=get_node("../Terrain");_rng.seed=20260913
	var center:Vector2=_terrain.get_village_center()
	var offsets:Array[Vector2]=[Vector2(-32,-20),Vector2(0,-31),Vector2(31,-18),Vector2(-36,12),Vector2(2,22),Vector2(34,14),Vector2(-18,40),Vector2(21,40)]
	for i in offsets.size():
		var p:Vector2=center+offsets[i]
		var roof:Color=Color(0.17,0.08,0.055).lerp(Color(0.48,0.13,0.045),float(i%3)/2.0)
		var house:=TownProps.build_building(2,2,1,roof,Color(0.24,0.105,0.065),Color(0.34,0.12,0.055))
		# The door occupies the +X bay of the south wall. Mount the fixture on
		# the solid -X bay instead of floating it directly in front of the open
		# doorway. Rotate local -Z (the doorway's outward normal) toward the
		# village centre so every entrance faces the shared commons.
		_add_wall_fire_fixture(house,Vector3(-1.50,1.35,-TownProps.CELL_SIZE-0.06))
		house.position=Vector3(p.x,_terrain.get_mesh_height(p.x,p.y),p.y);house.rotation.y=atan2(offsets[i].x,offsets[i].y);add_child(house)
		_spawn_lava_person(center+offsets[i]*0.62,i)
	_build_village_braziers(center)
	_build_lava_fountain(center)
	_spawn_lava_slide()


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

func _spawn_lava_person(pos:Vector2,index:int)->void:
	var npc:Node3D=NPC_SCENE.instantiate();npc.set_terrain_reference(_terrain)
	npc.display_name=NAMES[index];var lines:Array[String]=[LINES[index]];npc.talk_lines=lines
	var is_female: bool = index % 2 == 0
	var gender_index: int = floori(float(index) * 0.5)
	VillagerAppearance.apply_profile(npc, index, gender_index, is_female, FIRE_APPEARANCE)
	npc.lava_body=true
	npc.wander_boundary_center=_terrain.get_village_center();npc.wander_boundary_radius=_terrain.get_village_radius()-6.0
	npc.position=Vector3(pos.x,_terrain.get_mesh_height(pos.x,pos.y),pos.y);add_child(npc)

func _build_village_braziers(center:Vector2)->void:
	for i in 8:
		var angle:=TAU*float(i)/8.0+0.18
		var p:=center+Vector2(cos(angle),sin(angle))*48.0
		var brazier:=_build_brazier()
		brazier.position=Vector3(p.x,_terrain.get_mesh_height(p.x,p.y),p.y)
		add_child(brazier)

func _build_brazier()->Node3D:
	var root:=Node3D.new()
	var iron:=Color(0.10,0.075,0.065)
	var post:=SuperEgg.build_part(Vector3(0.13,0.62,0.13),iron,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT);post.position.y=0.62;root.add_child(post)
	var bowl:=SuperEgg.build_part(Vector3(0.48,0.14,0.48),Color(0.075,0.055,0.05),2.0,SuperEgg.EPSILON_FLAT);bowl.position.y=1.25;root.add_child(bowl)
	for i in 4:
		var angle:=TAU*float(i)/4.0;var radial:=Vector3(cos(angle),0.0,sin(angle))
		var cage:=SuperEgg.build_part(Vector3(0.035,0.42,0.035),iron,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT);cage.position=radial*0.39+Vector3.UP*1.55;cage.rotation.z=radial.x*0.13;cage.rotation.x=-radial.z*0.13;root.add_child(cage)
		var foot:=SuperEgg.build_part(Vector3(0.045,0.34,0.045),iron,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT);foot.position=radial*0.23+Vector3.UP*0.25;foot.rotation.z=radial.x*0.48;foot.rotation.x=-radial.z*0.48;root.add_child(foot)
	var flame:=_make_lava_particles(18,0.52,1.4,3.0,4.7,-1.0);flame.position.y=1.42;root.add_child(flame)
	var light:=OmniLight3D.new();light.position.y=1.55;light.light_color=Color(1.0,0.28,0.055);light.light_energy=1.4;light.omni_range=12.0;light.shadow_enabled=false;root.add_child(light)
	return root

func _add_wall_fire_fixture(house:Node3D,local_position:Vector3)->void:
	var fixture:=Node3D.new();fixture.position=local_position;house.add_child(fixture)
	var iron:=Color(0.085,0.065,0.058)
	var plate:=SuperEgg.build_part(Vector3(0.20,0.34,0.055),iron,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT);fixture.add_child(plate)
	var arm:=SuperEgg.build_part(Vector3(0.045,0.045,0.28),iron,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT);arm.position=Vector3(0.0,-0.1,-0.27);fixture.add_child(arm)
	var cup:=SuperEgg.build_part(Vector3(0.30,0.12,0.30),iron,2.0,SuperEgg.EPSILON_FLAT);cup.position=Vector3(0.0,-0.05,-0.53);fixture.add_child(cup)
	for side in [-1.0,1.0]:
		var guard:=SuperEgg.build_part(Vector3(0.025,0.36,0.025),iron,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT);guard.position=Vector3(side*0.22,0.26,-0.53);guard.rotation.z=side*-0.12;fixture.add_child(guard)
	var flame:=_make_lava_particles(14,0.42,1.1,2.6,4.0,-0.8);flame.position=Vector3(0.0,0.08,-0.53);fixture.add_child(flame)
	var light:=OmniLight3D.new();light.position=Vector3(0.0,0.3,-0.62);light.light_color=Color(1.0,0.34,0.08);light.light_energy=1.1;light.omni_range=9.0;light.shadow_enabled=false;fixture.add_child(light)

func _build_lava_fountain(center:Vector2)->void:
	var fountain:=StaticBody3D.new();fountain.collision_layer=1;fountain.collision_mask=0
	var ground_height:float=_terrain.get_mesh_height(center.x,center.y)
	fountain.position=Vector3(center.x,ground_height,center.y)
	const RADIUS:=4.2
	const SEGMENTS:=18
	# Register the exposed liquid disk with the terrain's canonical lava API.
	# Its radius stops inside the solid rim and its height is expressed in world
	# space, matching rivers and volcano pools.
	if _terrain.has_method("register_lava_surface"):
		_terrain.register_lava_surface(center,RADIUS-0.32,ground_height+0.58)
	for i in SEGMENTS:
		var a0:=TAU*float(i)/float(SEGMENTS);var a1:=TAU*float(i+1)/float(SEGMENTS);var mid:=(a0+a1)*0.5
		var chord:=2.0*RADIUS*sin((a1-a0)*0.5);var tangent:=Vector3(-sin(mid),0.0,cos(mid));var radial:=Vector3(cos(mid),0.0,sin(mid));var pos:=radial*RADIUS+Vector3.UP*0.38
		var basis:=Basis(tangent,Vector3.UP,radial)
		var rim:=SuperEgg.build_part(Vector3(chord*0.55,0.38,0.30),Color(0.085,0.065,0.06),SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT);rim.position=pos;rim.basis=basis;fountain.add_child(rim)
		var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(chord*1.08,0.76,0.66);collision.shape=shape;collision.position=pos;collision.basis=basis;fountain.add_child(collision)
	var lava_mesh:=CylinderMesh.new();lava_mesh.top_radius=RADIUS-0.32;lava_mesh.bottom_radius=RADIUS-0.32;lava_mesh.height=0.08;lava_mesh.radial_segments=36;lava_mesh.material=NatureProps.build_lava_material()
	var lava:=MeshInstance3D.new();lava.mesh=lava_mesh;lava.position.y=0.58;fountain.add_child(lava)
	var pedestal:=SuperEgg.build_part(Vector3(0.72,1.0,0.72),Color(0.08,0.06,0.055),SuperEgg.EPSILON_SOFT,SuperEgg.EPSILON_FLAT);pedestal.position.y=1.0;fountain.add_child(pedestal)
	var plume:=_make_lava_particles(90,1.0,2.4,7.0,10.0,-9.5);plume.position.y=1.9;fountain.add_child(plume)
	var light:=OmniLight3D.new();light.position.y=2.3;light.light_color=Color(1.0,0.26,0.045);light.light_energy=2.5;light.omni_range=28.0;light.shadow_enabled=false;fountain.add_child(light)
	add_child(fountain)

func _make_lava_particles(amount:int,width:float,height:float,min_speed:float,max_speed:float,gravity_y:float)->GPUParticles3D:
	var particles:=GPUParticles3D.new();particles.amount=amount*3;particles.lifetime=0.58;particles.randomness=0.38;particles.emitting=true
	var process:=ParticleProcessMaterial.new();process.direction=Vector3.UP;process.spread=12.0;process.initial_velocity_min=min_speed;process.initial_velocity_max=max_speed;process.gravity=Vector3(0.0,gravity_y,0.0);process.scale_min=0.45;process.scale_max=1.15
	process.particle_flag_align_y=true;process.angle_min=-12.0;process.angle_max=12.0
	process.turbulence_enabled=true;process.turbulence_noise_strength=1.0;process.turbulence_noise_scale=2.0;process.turbulence_influence_min=0.04;process.turbulence_influence_max=0.15
	process.color_ramp=ParticleFX.build_color_ramp([{"offset":0.0,"color":Color(1.0,0.95,0.75,1.0)},{"offset":0.25,"color":Color(1.0,0.55,0.1,1.0)},{"offset":0.6,"color":Color(0.85,0.25,0.05,0.9)},{"offset":1.0,"color":Color(0.35,0.06,0.02,0.0)}]);process.scale_curve=ParticleFX.build_scale_curve(0.18,1.15,0.32,0.12);particles.process_material=process
	var flame_material:=ParticleFX.build_billboard_material(ParticleFX.build_soft_gradient_texture(32,1.7,0.2),Color.WHITE,true,0.0);flame_material.vertex_color_use_as_albedo=true
	var quad:=QuadMesh.new();quad.size=Vector2(width,height);quad.material=flame_material;particles.draw_pass_1=quad
	particles.visibility_aabb=AABB(Vector3(-12,-2,-12),Vector3(24,20,24));return particles
