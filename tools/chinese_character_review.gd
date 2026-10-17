extends Node3D

const APPEARANCE = preload("res://scripts/chinese_appearance.gd")
const NPC = preload("res://scenes/npc.tscn")
const FEMALE := ["Mei Lian","Hua Chen","Jin Wei","Shu Mei","姥姥","Ting Ting","Xiu Xiu","Pei Pei"]

func _ready() -> void:
	var environment:=WorldEnvironment.new()
	var settings:=Environment.new()
	settings.background_mode=Environment.BG_COLOR
	settings.background_color=Color(0.12,0.16,0.20)
	settings.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color=Color(0.82,0.88,1.0)
	settings.ambient_light_energy=0.6
	environment.environment=settings;add_child(environment)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-42,-28,0);key.light_energy=1.4;add_child(key)
	var camera:=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.0;add_child(camera);camera.make_current()
	var rows: Array=[
		["Mei Lian","Jin Wei","Xiu Xiu","Yun Tao","Bao Bao"],
		["Hua Chen","Ting Ting","Bo Xiang","Rong Rong","Lian Fu"],
		["姥姥","姥爷","陆浩","Chen","Shu Mei"],
		["皇帝","御厨","田伯","Wen Zhao","Pei Pei"],
		["梁臻","Mei Lian","Hua Chen","Chen","姥姥"],
	]
	var output:="res://wip/character_review"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for row_index in rows.size():
		var group:=Node3D.new();add_child(group)
		for i in rows[row_index].size():
			var identity: String=rows[row_index][i]
			var npc:=NPC.instantiate()
			npc.set_terrain_reference(self)
			npc.display_name=identity;npc.is_female=identity in FEMALE;npc.stationary=true;npc.fixed_ground_y=0.0
			npc.skin_color=Color(0.76,0.58,0.42)
			APPEARANCE.apply(npc,identity)
			if identity=="御厨":
				npc.wears_chef_hat=true;npc.chef_hat_band_color=Color(0.58,0.10,0.07)
			npc.position=Vector3((float(i)-2.0)*1.8,0,0)
			group.add_child(npc)
			check_beard_clearance(npc)
			var label:=Label3D.new();label.text=identity;label.font_size=32;label.pixel_size=0.004;label.position=Vector3(npc.position.x,-0.18,0.1);label.no_depth_test=true;group.add_child(label)
		camera.position=Vector3(0,2.6,11);camera.look_at(Vector3(0,1.05,0))
		for frame in 15: await get_tree().process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(output+"/roster_%d.png"%row_index)
		# Sweep a full gait interval and capture the articulated garment fit.
		for frame in 40:
			for npc in group.get_children():
				if npc is StaticBody3D:
					npc.set("_target",Vector2(npc.position.x,20.0))
					npc.call("_process_walk",0.016)
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(output+"/walk_%d.png"%row_index)

		group.queue_free();await get_tree().process_frame
	print("PASS China character review: all 20 named residents and advisor wardrobe build")
	get_tree().quit()


func check_beard_clearance(actor: Node3D) -> void:
	var beards:=actor.find_children("FullBeard","MeshInstance3D",true,false)
	if beards.is_empty(): return
	var beard:=beards[0] as MeshInstance3D
	var head: Node3D=actor.get("_head")
	for yaw in [-30.0,0.0,30.0]:
		head.rotation.y=deg_to_rad(yaw)
		var vertices: PackedVector3Array=beard.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for garment in actor.find_children("*","MeshInstance3D",true,false):
			if head.is_ancestor_of(garment) or garment.mesh==null: continue
			# Check actual beard vertices against conservatively bounded clothing;
			# eye/head/hair overlap is deliberately excluded from this audit.
			var material: Material=garment.material_override
			if material is StandardMaterial3D and material.albedo_color.is_equal_approx(actor.skin_color): continue
			var to_garment: Transform3D=garment.global_transform.affine_inverse()*beard.global_transform
			var box: AABB=garment.mesh.get_aabb()
			for vertex in vertices:
				if box.has_point(to_garment*vertex):
					push_error("Beard intersects garment: "+str(actor.display_name)+" / "+str(garment.name)+" color="+str(material.albedo_color if material is StandardMaterial3D else material)+" at yaw "+str(yaw))
					get_tree().quit(1)
					return
	head.rotation.y=0.0
