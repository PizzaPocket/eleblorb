class_name TobogganHelm
extends RefCounted

## Shared geometry for the freestanding winter hat and the living form a
## blorb takes after binding it. The folded band is part of the silhouette,
## not a torus floating around an unrelated cap: the profile widens into a
## thick cuff, draws inward above it, then tapers continuously to the crown.
## The cuff clears the brow at the front, then settles slightly lower around
## the back of the head instead of reading as a level tube angled upward.

const KNIT_COLOR := Color(0.34,0.30,0.62)
const RADIAL_SEGMENTS := 28
const BAND_BACK_DROP := 0.48
const CROWN_REAR_LEAN := 0.22
const POM_REAR_OFFSET := 0.18
const LIVING_EYE_T := 0.335
const LIVING_EYE_SCALE := 1.85
const PROFILE: Array[Vector2] = [
	Vector2(0.00,1.00),
	Vector2(0.07,1.07),
	Vector2(0.20,1.09),
	Vector2(0.25,0.91),
	Vector2(0.43,0.88),
	Vector2(0.62,0.80),
	Vector2(0.78,0.67),
	Vector2(0.90,0.48),
	Vector2(0.97,0.28),
	Vector2(1.00,0.15),
]


static func build_rings(radius: float,height: float) -> Array:
	var rings: Array=[]
	for profile_point in PROFILE:
		var ring: Array[Vector3]=[]
		for segment in RADIAL_SEGMENTS:
			var angle:=TAU*float(segment)/float(RADIAL_SEGMENTS)
			var width_radius:=radius*profile_point.y
			# Keep the crown broad from the front while pinching it shallow in
			# side profile. A uniform radial taper would look like a round cone.
			var depth_radius:=depth_radius_at(profile_point.x,width_radius)
			var z:=sin(angle)*depth_radius
			ring.append(Vector3(
				cos(angle)*width_radius,
				height*profile_point.x+pitched_y_at(profile_point.x,z,depth_radius),
				z+center_z_at(profile_point.x,radius)
			))
		rings.append(ring)
	return rings


static func center_z_at(t: float,radius: float) -> float:
	var crown_t:=smoothstep(0.20,1.0,clampf(t,0.0,1.0))
	return -radius*CROWN_REAR_LEAN*crown_t


static func depth_radius_at(t: float,width_radius: float) -> float:
	var pinch:=smoothstep(0.48,1.0,clampf(t,0.0,1.0))
	# Keep the front and rear halves equally rounded around the crown's own
	# moving centre. The gentler terminal depth retains a soft pinched-knit
	# profile without collapsing the face side into a narrow point.
	return width_radius*lerpf(1.0,0.48,pinch)


static func surface_point_at(t: float,angle: float,radius: float,height: float) -> Vector3:
	var width_radius:=radius_at(t,radius)
	var depth_radius:=depth_radius_at(t,width_radius)
	var local_z:=sin(angle)*depth_radius
	return Vector3(
		cos(angle)*width_radius,
		height*t+pitched_y_at(t,local_z,depth_radius),
		local_z+center_z_at(t,radius)
	)


## Numerical normal of the complete authored surface, including crown taper,
## rearward lean and the cuff's front-to-back pitch. This keeps face pieces
## flush to the actual mesh instead of using the circular-profile shortcut.
static func surface_normal_at(t: float,angle: float,radius: float,height: float) -> Vector3:
	const STEP:=0.002
	var tangent_t:=surface_point_at(clampf(t+STEP,0.0,1.0),angle,radius,height)-surface_point_at(clampf(t-STEP,0.0,1.0),angle,radius,height)
	var tangent_angle:=surface_point_at(t,angle+STEP,radius,height)-surface_point_at(t,angle-STEP,radius,height)
	var normal:=tangent_angle.cross(tangent_t).normalized()
	var radial_hint:=Vector3(cos(angle),0.0,sin(angle))
	if normal.dot(radial_hint)<0.0:
		normal=-normal
	return normal


static func pitched_y_at(t: float,local_z: float,depth_radius: float) -> float:
	# +Z is the face. Map the whole front-to-back span through a smoothstep:
	# zero displacement at the brow, a continuously increasing descent around
	# both sides, and the full drop at the rear. There is no centre seam where
	# the direction or derivative abruptly changes.
	var safe_depth:=maxf(depth_radius,0.0001)
	var front_to_back:=clampf((safe_depth-local_z)/(safe_depth*2.0),0.0,1.0)
	var rear_drop:=safe_depth*BAND_BACK_DROP*(1.0-clampf(t,0.0,1.0))
	return -rear_drop*smoothstep(0.0,1.0,front_to_back)


static func pom_z(radius: float) -> float:
	return center_z_at(1.0,radius)-radius*POM_REAR_OFFSET


static func radius_at(t: float,radius: float) -> float:
	var clamped:=clampf(t,0.0,1.0)
	for i in PROFILE.size()-1:
		var a:=PROFILE[i]
		var b:=PROFILE[i+1]
		if clamped<=b.x:
			return lerpf(a.y,b.y,inverse_lerp(a.x,b.x,clamped))*radius
	return PROFILE[-1].y*radius


static func slope_at(t: float,radius: float,height: float) -> float:
	const STEP:=0.01
	return (
		radius_at(t+STEP,radius)-radius_at(t-STEP,radius)
	)/maxf(STEP*2.0*height,0.001)


static func pom_radius(radius: float) -> float:
	return radius*0.38


static func build_visual(item_scale: float=1.0) -> Node3D:
	var root:=Node3D.new()
	root.name="Toboggan"
	var radius:=0.15*item_scale
	var height:=0.245*item_scale
	var material:=StandardMaterial3D.new()
	material.albedo_color=KNIT_COLOR
	material.roughness=0.88
	var shell:=MeshInstance3D.new()
	shell.name="TaperedKnitCrown"
	shell.mesh=BlorbBodyShape.build_mesh_from_rings(build_rings(radius,height))
	shell.material_override=material
	root.add_child(shell)
	var pom:=SuperEgg.build_part(
		Vector3.ONE*pom_radius(radius),KNIT_COLOR,2.35,2.35
	)
	pom.name="PomPom"
	pom.position.y=height+pom_radius(radius)*0.49
	pom.position.z=pom_z(radius)
	root.add_child(pom)
	var grip:=Node3D.new()
	grip.name="GripPoint"
	grip.position=Vector3(0.0,height*0.12,-radius)
	root.add_child(grip)
	return root
