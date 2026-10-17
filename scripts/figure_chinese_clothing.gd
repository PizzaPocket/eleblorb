extends RefCounted

## Shared fitted garment kit. All dimensions come from the built rig's meshes;
## cuffs follow their articulated limbs and hems leave separate leg openings.
static func add_to_figure(rig: Dictionary, outfit: Dictionary, shirt: Color, hair_style: String) -> void:
	var chest: MeshInstance3D = rig.chest
	var hips: MeshInstance3D = rig.hips
	var c := chest.mesh.get_aabb().size * 0.5
	var h := hips.mesh.get_aabb().size * 0.5
	var trim: Color = outfit.get("trim", Color(0.16,0.23,0.24))
	var sash: Color = outfit.get("sash", trim)
	var coat: Color = outfit.get("vest", shirt)
	# A collar band surrounds the actual neck, with a front opening.
	var neck: MeshInstance3D = rig.neck_mesh
	var n := neck.mesh.get_aabb().size * 0.5
	var collar_y := -n.y+0.008 if outfit.get("emperor",false) else 0.012
	for side: float in [-1.0,1.0]:
		part(neck,"CollarSide",Vector3(0.012,0.012 if outfit.get("emperor",false) else 0.025,n.z+0.009),Vector3(side*(n.x+0.006),collar_y,0),trim)
	part(neck,"CollarBack",Vector3(n.x+0.012,0.012 if outfit.get("emperor",false) else 0.025,0.009),Vector3(0,collar_y,-n.z),trim)
	part(neck,"CollarFront",Vector3(n.x+0.012,0.012 if outfit.get("emperor",false) else 0.023,0.009),Vector3(0,collar_y,n.z),trim)
	# Dress the canonical pieces separately. Never bridge the waist or hide
	# the thorax/abdomen distinction with a second enclosing torso.
	var abdomen: MeshInstance3D = rig.abdomen
	var abdomen_half := abdomen.mesh.get_aabb().size * 0.5
	var coat_material := StandardMaterial3D.new()
	coat_material.albedo_color = coat
	coat_material.roughness = 0.9
	chest.material_override = coat_material
	abdomen.material_override = coat_material
	if outfit.has("vest"):
		part(chest,"VestOpening",Vector3(0.030,c.y*0.85,0.008),Vector3(0,0,c.z+0.006),shirt)
	var closure_x := c.x*0.50 if outfit.get("side_close",false) else 0.0
	part(chest,"ThoraxClosure",Vector3(0.007,c.y*0.86,0.006),Vector3(closure_x,0,c.z+0.013),trim)
	part(abdomen,"AbdomenClosure",Vector3(0.007,abdomen_half.y*0.82,0.006),Vector3(closure_x,0,abdomen_half.z+0.013),trim)
	for i in 3:
		var y := c.y*0.54-float(i)*c.y*0.53
		part(chest,"FrogLoop",Vector3(0.022,0.005,0.006),Vector3(closure_x,y,c.z+0.022),trim)
		part(chest,"FrogKnot",Vector3(0.007,0.007,0.007),Vector3(closure_x+0.022,y,c.z+0.024),trim)
	if not outfit.get("gown",false) and not outfit.get("emperor",false):
		# The hip segment is the jacket's all-around lower section, rather
		# than two detached front/back plates that read as an apron.
		hips.material_override = coat_material
		var hem := MeshInstance3D.new()
		hem.name = "WraparoundJacketHem"
		hem.mesh = OpeningTrim.piped_mesh(OpeningTrim.window_loop(h.x+0.004,h.z+0.004,4.5,48),0.008,true)
		hem.rotation.x = PI*0.5
		hem.position.y = -h.y+0.009
		var hem_material := StandardMaterial3D.new()
		hem_material.albedo_color = trim
		hem.material_override = hem_material
		CollisionPolicy.mark_decorative(hem)
		hips.add_child(hem)
	part(hips,"WaistSash",Vector3(h.x+0.009,0.018,h.z+0.010),Vector3(0,h.y*0.55,0),sash)
	part(hips,"SashKnot",Vector3(0.023,0.018,0.019),Vector3(h.x*0.66,h.y*0.55,h.z+0.023),sash)
	# Broaden only clothed segments; never scale a joint or hand.
	var sleeve: String = outfit.get("sleeve","long")
	if sleeve != "none":
		for key in ["arm_left","arm_right","elbow_left","elbow_right"]:
			if sleeve == "short" and str(key).begins_with("elbow"): continue
			for child in rig[key].get_children():
				if child is MeshInstance3D:
					var mesh: MeshInstance3D = child
					# Short-sleeve arms include a skin segment; only the sleeve overlays widen.
					if sleeve == "short" and mesh.position.y < -0.18: continue
					var a := mesh.mesh.get_aabb().size*0.5
					if sleeve == "short" and a.y > 0.12: continue
					mesh.scale.x=1.22; mesh.scale.z=1.22
					if str(key).begins_with("elbow") or sleeve == "short":
						part(mesh,"BoundCuff",Vector3(a.x+0.004,0.018,a.z+0.004),Vector3(0,-a.y+0.016,0),trim)
	if outfit.has("apron"):
		var apron: Color = outfit.apron
		# An actual cook's apron follows each body segment independently.
		part(chest,"ApronBib",Vector3(c.x*0.50,c.y*0.77,0.009),Vector3(0,-c.y*0.04,c.z+0.012),apron)
		part(abdomen,"ApronWaist",Vector3(abdomen_half.x*0.55,abdomen_half.y*0.85,0.009),Vector3(0,0,abdomen_half.z+0.012),apron)
		part(hips,"ApronSkirt",Vector3(h.x*0.72,0.17,0.009),Vector3(0,-0.045,h.z+0.025),apron)
		for side: float in [-1.0,1.0]:
			part(chest,"ApronStrap",Vector3(0.009,c.y,0.007),Vector3(side*c.x*0.40,0,c.z+0.012),apron)
		part(hips,"ApronPocket",Vector3(h.x*0.34,0.030,0.006),Vector3(h.x*0.18,-0.045,h.z+0.040),apron.darkened(0.08))
	if outfit.get("cloth",false):
		part(hips,"ServingCloth",Vector3(0.044,0.105,0.016),Vector3(-h.x*0.7,0,h.z+0.068),Color(0.86,0.85,0.75))
	# Cloth shoes keep the rig's existing articulated sole, adding a pale welt.
	if not outfit.get("emperor",false):
		for key in ["sole_left","sole_right"]:
			var foot: MeshInstance3D=rig[key].get_parent()
			var foot_half:=foot.mesh.get_aabb().size*0.5
			part(foot,"ClothShoeWelt",Vector3(foot_half.x+0.002,0.009,foot_half.z+0.002),Vector3(0,-foot_half.y+0.009,0),Color(0.76,0.77,0.70))
	if outfit.has("pack"):
		part(chest,"TravelPack",Vector3(c.x*0.85,0.26,0.09),Vector3(0,-0.05,-c.z-0.09),Color(0.36,0.27,0.16))
		for side: float in [-1.0,1.0]:
			part(chest,"PackFrame",Vector3(0.012,0.30,0.012),Vector3(side*c.x*0.8,-0.04,-c.z-0.17),Color(0.57,0.43,0.25))
	HairOrnaments.build_village_headwear(rig.head_mesh,ProceduralFigure.HEAD_SIZE,hair_style,str(outfit.get("headwear","")),trim)

static func part(parent: Node3D, label: String, half: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half,color,SuperEgg.EPSILON_FLAT,SuperEgg.EPSILON_FLAT)
	mesh.name=label
	mesh.position=at
	CollisionPolicy.mark_decorative(mesh)
	parent.add_child(mesh)
	return mesh
