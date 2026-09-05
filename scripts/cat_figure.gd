class_name CatFigure
extends RefCounted

## A domestic-cat-scale quadruped template. Unlike Manchego's current
## continuous leg noodles, every anatomical bone is a separately parented
## SuperEgg. The invisible pivot chain is therefore also the visible chain:
## shoulder/hip -> upper bone -> elbow/stifle -> lower bone -> carpus/hock ->
## metapodial -> paw. Measurements are in metres and target an ordinary
## 4-5 kg adult cat: ~24 cm at the shoulder, ~46 cm nose-to-rump, and a
## ~30 cm tail. The deliberately flexed standing angles follow a digitigrade
## cat silhouette rather than copying the horse's much longer distal limbs.

const COAT_COLORS := [
	Color(0.72, 0.49, 0.25), # ginger
	Color(0.16, 0.15, 0.15), # black/charcoal
	Color(0.70, 0.69, 0.66), # silver
	Color(0.86, 0.80, 0.69), # cream
	Color(0.38, 0.30, 0.24), # brown
]
const NOSE_COLOR := Color(0.38, 0.20, 0.21)

## Yogi -- the Primate Kingdom's canonical cat (see docs/world_bible.md's
## own Creatures/Cats entry), per direct instruction: white coat, an
## orangish-brown marking on one ear, both front paws, an uneven pair of
## hind legs (one with every segment marked, the other just its paw and the
## segment right above it), and a ringed tail tip capped in the same marking
## color. YOGI_MARKED_EAR_SIDE/YOGI_FULL_LEG_SIDE/YOGI_LOWER_SOCK_SIDE reuse
## this file's own side=-1.0/1.0 convention (see _build_leg()'s own `side`
## param) -- picked arbitrarily (left ear, left hind leg fully marked, right
## hind leg the shorter sock) since the direct instruction didn't specify
## which physical side, adjustable on report like any other unspecified
## left/right pick in this project.
const YOGI_COAT_COLOR := Color(0.96, 0.95, 0.92)
const YOGI_MARKING_COLOR := Color(0.72, 0.45, 0.22)
const YOGI_MARKED_EAR_SIDE := -1.0
## The hind leg with every segment marked -- root, middle, distal, and paw.
const YOGI_FULL_LEG_SIDE := -1.0
## The other hind leg: per direct correction ("the other just the paw and
## lower segment"), only its distal bone (the segment right above the paw)
## and the paw itself -- NOT the whole leg the way YOGI_FULL_LEG_SIDE's own
## side is.
const YOGI_LOWER_SOCK_SIDE := 1.0

## All three trunk segments share one deliberately slender cross-section.
## Only depth varies: the pelvis is especially short front-to-back, while
## abdomen and thorax provide most of the cat's trunk length.
const BODY_SCALE := 1.2
const BODY_HALF_WIDTH := 0.085 * BODY_SCALE
const BODY_HALF_HEIGHT := 0.095 * BODY_SCALE
const HIP_SIZE := Vector3(BODY_HALF_WIDTH, BODY_HALF_HEIGHT, 0.07 * BODY_SCALE)
## Redistribute trunk depth without changing its combined length: move
## 2 cm of half-depth from the overlong thorax into the abdomen.
const ABDOMEN_SIZE := Vector3(BODY_HALF_WIDTH, BODY_HALF_HEIGHT, 0.085 * BODY_SCALE)
const THORAX_SIZE := Vector3(BODY_HALF_WIDTH, BODY_HALF_HEIGHT, 0.095 * BODY_SCALE)
const HIP_TO_ABDOMEN_STEP := 0.115 * BODY_SCALE
const ABDOMEN_TO_THORAX_STEP := 0.145 * BODY_SCALE
const STANDING_BODY_Y := 0.24 * BODY_SCALE
const RESTING_BODY_Y := BODY_HALF_HEIGHT

## Keep the established neck breadth but shorten its longitudinal Y axis
## by 40 percent, drawing the head much closer to the shoulders.
const NECK_SIZE := Vector3(0.052 * BODY_SCALE, 0.08 * BODY_SCALE * 0.6, 0.052 * BODY_SCALE)
## Preserve the head's established width/height while trimming only the
## face-to-tail depth by 15 percent. Muzzle follows the same depth-only
## reduction so it remains proportionate to the shallower skull.
const HEAD_SIZE := Vector3(0.105, 0.095, 0.095 * 0.85)
const MUZZLE_SIZE := Vector3(0.066, 0.047, 0.055 * 0.85) * 0.83

const FRONT_UPPER_LEN := 0.075 * BODY_SCALE
## Transfer 1.8 cm from front bone 2 into bone 3, preserving total reach.
const FRONT_LOWER_LEN := 0.075 * BODY_SCALE
const FRONT_METAPODIAL_LEN := 0.06 * BODY_SCALE
const HIND_UPPER_LEN := 0.095 * BODY_SCALE
## Transfer 2.4 cm from hind bone 2 into bone 3, likewise preserving reach.
const HIND_LOWER_LEN := 0.085 * BODY_SCALE
const HIND_METAPODIAL_LEN := 0.09 * BODY_SCALE
const PAW_LEN := 0.045 * BODY_SCALE
## Every visible long-bone segment has the same left-to-right breadth.
const BONE_RADIUS := 0.023 * BODY_SCALE

const STAND_FRONT_ANGLES := [deg_to_rad(22.0), deg_to_rad(-28.0), deg_to_rad(12.0)]
const STAND_HIND_ANGLES := [deg_to_rad(-42.0), deg_to_rad(58.0), deg_to_rad(-42.0)]
const REST_FRONT_ANGLES := [deg_to_rad(76.0), deg_to_rad(-118.0), deg_to_rad(54.0)]
const REST_HIND_ANGLES := [deg_to_rad(-88.0), deg_to_rad(126.0), deg_to_rad(-70.0)]


## marking_color (default null) plus marked_ear_side/full_leg_side/
## lower_sock_side/mark_front_paws (default 0.0/false == no marking on that
## feature) add optional cosmetic markings on top of the plain single-coat-
## color cat this file already built -- see YOGI_COAT_COLOR's own comment
## for the canonical values. full_leg_side marks that ENTIRE hind leg (root,
## middle, distal, and paw); lower_sock_side marks just that hind leg's paw
## and the distal segment right above it ("the other just the paw and lower
## segment," per direct correction) -- so the two hind legs read as an
## uneven pair, one fully marked, one a short sock. mark_front_paws marks
## BOTH front paws (no side -- per direct instruction, "give both the front
## paws color"), nothing else on the front legs. Every side param uses this
## file's own side=-1.0/1.0 convention. Every default reproduces the exact
## prior single-color behavior, so no existing caller needs to change.
static func build(
	parent: Node3D, coat_color: Color, resting: bool = false, curl_side: float = 1.0,
	marking_color: Variant = null, marked_ear_side: float = 0.0,
	full_leg_side: float = 0.0, lower_sock_side: float = 0.0, mark_front_paws: bool = false
) -> Dictionary:
	var rig := Node3D.new()
	rig.name = "CatFigure"
	rig.position.y = RESTING_BODY_Y if resting else STANDING_BODY_Y
	parent.add_child(rig)

	# Pelvis, abdomen and thorax remain truly separate horizontal segments.
	# In the resting pose their yaw is distributed across all three joints,
	# producing a soft whole-body curl instead of one sharp hinge.
	var hips := _body_segment(rig, "CatHips", HIP_SIZE, coat_color)
	if resting:
		hips.rotation.y = curl_side * deg_to_rad(16.0)
	var abdomen := _body_segment(hips, "CatAbdomen", ABDOMEN_SIZE, coat_color)
	abdomen.position.z = HIP_TO_ABDOMEN_STEP
	if resting:
		abdomen.rotation.y = curl_side * deg_to_rad(23.0)
	var thorax := _body_segment(abdomen, "CatThorax", THORAX_SIZE, coat_color)
	thorax.position.z = ABDOMEN_TO_THORAX_STEP
	if resting:
		thorax.rotation.y = curl_side * deg_to_rad(28.0)

	var head_parts := _build_neck_head(thorax, coat_color, resting, curl_side, marking_color, marked_ear_side)
	var leg_angles_front: Array = REST_FRONT_ANGLES if resting else STAND_FRONT_ANGLES
	var leg_angles_hind: Array = REST_HIND_ANGLES if resting else STAND_HIND_ANGLES
	# full_leg_side/lower_sock_side only ever apply to the HIND legs -- per
	# direct instruction, that uneven pair is specifically a hind thing, not
	# a front one -- so the front _build_leg() calls below use their own
	# separate mark_front_paws flag instead (paw only, both sides, no leg-
	# segment marking at all).
	var legs := {
		"front_left": _build_leg(
			thorax, 1.0, true, coat_color, leg_angles_front, resting, marking_color, mark_front_paws
		),
		"front_right": _build_leg(
			thorax, -1.0, true, coat_color, leg_angles_front, resting, marking_color, mark_front_paws
		),
		"hind_left": _build_leg(
			hips, 1.0, false, coat_color, leg_angles_hind, resting,
			marking_color, false, 1.0 == lower_sock_side, 1.0 == full_leg_side
		),
		"hind_right": _build_leg(
			hips, -1.0, false, coat_color, leg_angles_hind, resting,
			marking_color, false, -1.0 == lower_sock_side, -1.0 == full_leg_side
		),
	}

	# Reuse the primate tail builder/animation outright, but supply cat-scale
	# body dimensions, length and radius. It remains a flexible appendage;
	# the independent-SuperEgg requirement applies to the articulated bones.
	# marking_color also rides along as MonkeyFigure._build_tail()'s own
	# tip_marking_color -- see that param's own comment for the ringed-tip
	# treatment this puts on Yogi's tail specifically.
	var tail := MonkeyFigure._build_tail(hips, coat_color, 1.55, HIP_SIZE.y * 2.0, HIP_SIZE.z, 3.0, marking_color)
	if resting:
		var points: Array[Vector3] = tail["base_points"]
		var anchor := points[0]
		# Turn the outgoing tangent at the rump itself into the curl. The
		# former first point still reached mostly backward, so the tail looked
		# straight-mounted with a bend added only farther along its length.
		points[1] = anchor + Vector3(curl_side * 0.14, -0.035, -0.045)
		points[2] = anchor + Vector3(curl_side * 0.25, -0.055, -0.12)
		points[3] = anchor + Vector3(curl_side * 0.31, -0.055, -0.02)
		tail["base_points"] = points
		MonkeyFigure._rebuild_tail(tail, 0.0)

	return {
		"_rig": rig, "hips": hips, "abdomen": abdomen, "thorax": thorax,
		"neck": head_parts["neck"], "head": head_parts["head"],
		"eyes": head_parts["eyes"], "legs": legs, "_tail": tail,
	}


static func _body_segment(parent: Node3D, part_name: String, size: Vector3, color: Color) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name + "Pivot"
	parent.add_child(pivot)
	var mesh := SuperEgg.build_part(size, color, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	mesh.name = part_name
	pivot.add_child(mesh)
	return pivot


static func _build_neck_head(
	thorax: Node3D, color: Color, resting: bool, curl_side: float,
	marking_color: Variant = null, marked_ear_side: float = 0.0
) -> Dictionary:
	var neck := Node3D.new()
	neck.name = "CatNeckPivot"
	# Pull the resting neck's base down the front of the chest. Combined with
	# the poll angle below, this puts the muzzle/chin tangent at ground level
	# while the thorax itself is also tangent to the ground.
	neck.position = Vector3(0, -0.005 if resting else 0.01, THORAX_SIZE.z * 0.86)
	neck.rotation.x = deg_to_rad(68.0) if resting else deg_to_rad(65.0)
	if resting:
		neck.rotation.y = curl_side * deg_to_rad(18.0)
	thorax.add_child(neck)
	var neck_mesh := SuperEgg.build_part(NECK_SIZE, color)
	neck_mesh.name = "CatNeck"
	neck_mesh.position.y = NECK_SIZE.y * 0.72
	neck.add_child(neck_mesh)

	var head := Node3D.new()
	head.name = "CatHeadPivot"
	head.position.y = NECK_SIZE.y * 1.45
	head.rotation.x = deg_to_rad(-43.0) if resting else deg_to_rad(-45.0)
	neck.add_child(head)
	var skull := SuperEgg.build_part(HEAD_SIZE, color, 2.65, 3.2)
	skull.name = "CatSkull"
	skull.position.z = HEAD_SIZE.z * 0.45
	head.add_child(skull)

	var muzzle := SuperEgg.build_part(MUZZLE_SIZE, color.lightened(0.10), 3.4, 3.8)
	muzzle.name = "CatMuzzle"
	muzzle.position = Vector3(0, -0.027, HEAD_SIZE.z + 0.025)
	head.add_child(muzzle)
	var nose := MeshInstance3D.new()
	nose.name = "CatNose"
	nose.mesh = _build_rounded_prism(_nose_outline(), 0.0025)
	var nose_material := StandardMaterial3D.new()
	nose_material.albedo_color = NOSE_COLOR
	nose_material.roughness = 0.8
	nose.set_surface_override_material(0, nose_material)
	# A shallow rounded triangular plate, broad across the bridge and
	# pointing down like a cat nose, seated directly against the muzzle.
	nose.position = Vector3(0, 0.006, MUZZLE_SIZE.z - 0.001)
	muzzle.add_child(nose)

	for side in [-1.0, 1.0]:
		var ear := MeshInstance3D.new()
		ear.name = "CatEar"
		ear.mesh = _build_cat_ear_mesh()
		var ear_material := StandardMaterial3D.new()
		# One ear, not both, per direct instruction ("an orangish brown
		# marking on one ear") -- marking_color only wins for the one side
		# matching marked_ear_side; the other ear stays plain coat color.
		ear_material.albedo_color = marking_color if (marking_color != null and side == marked_ear_side) else color
		ear_material.roughness = 0.8
		ear.set_surface_override_material(0, ear_material)
		ear.position = Vector3(side * 0.065, 0.05, 0.035)
		# Feline ears splay in all three axes: yaw and roll away from the
		# centerline, with their triangular tips pitched slightly backward.
		ear.rotation.x = deg_to_rad(9.0)
		ear.rotation.y = side * deg_to_rad(14.0)
		ear.rotation.z = -side * deg_to_rad(13.0)
		head.add_child(ear)

	var eyes: Array[MeshInstance3D] = []
	for side in [-1.0, 1.0]:
		# Twenty percent smaller than the first cat pass, colored as the same
		# darkened-coat surface marks used by the other procedural NPCs.
		var eye_radius := 0.024 * 0.8
		var eye := SuperEgg.build_part(
			Vector3(eye_radius, 0.029 * 0.8, eye_radius), color.darkened(0.25), 2.0, 2.0
		)
		eye.name = "CatEye"
		var eye_surface := SuperEgg.surface_point(
			HEAD_SIZE, deg_to_rad(8.0), side * deg_to_rad(27.0), 2.65, 3.2
		)
		eye_surface += skull.position
		var outward := Vector3(eye_surface.x, 0.0, eye_surface.z).normalized()
		var right := Vector3.UP.cross(outward).normalized()
		eye.basis = Basis(right, Vector3.UP, outward)
		eye.scale.z = 0.1
		eye.position = eye_surface + Vector3(0, 0.006, 0) - outward * (eye_radius * 0.06)
		head.add_child(eye)
		eyes.append(eye)
	return {"neck": neck, "head": head, "eyes": eyes}


## A tapered, lightly cupped triangular prism rather than a stretched
## superegg. The broad base meets the skull; the narrow rear layer gives
## the ear real thickness while preserving a pointed cat-ear silhouette.
static func _build_cat_ear_mesh() -> ArrayMesh:
	# Extra outline samples soften both base corners and the tip while
	# retaining the unmistakable upright triangular cat-ear silhouette.
	var outline: Array[Vector2] = [
		Vector2(-0.038, 0.004), Vector2(-0.037, 0.012),
		Vector2(-0.017, 0.061), Vector2(-0.007, 0.075),
		Vector2(0, 0.079), Vector2(0.007, 0.075),
		Vector2(0.017, 0.061), Vector2(0.037, 0.012),
		Vector2(0.038, 0.004), Vector2(0.032, 0), Vector2(-0.032, 0),
	]
	return _build_rounded_prism(outline, 0.006)


static func _nose_outline() -> Array[Vector2]:
	return [
		Vector2(-0.025, 0.009), Vector2(-0.020, 0.014),
		Vector2(0, 0.016), Vector2(0.020, 0.014),
		Vector2(0.025, 0.009), Vector2(0.021, 0.002),
		Vector2(0.008, -0.014), Vector2(0, -0.018),
		Vector2(-0.008, -0.014), Vector2(-0.021, 0.002),
	]


## Extrudes a smooth sampled outline into a closed shallow solid. Ear and
## nose use the same construction at different depths, so neither is a
## zero-thickness card and both keep rounded silhouette corners.
static func _build_rounded_prism(outline: Array[Vector2], half_depth: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := outline.size()
	var center_2d := Vector2.ZERO
	for point in outline:
		center_2d += point
	center_2d /= float(count)
	var front_center := Vector3(center_2d.x, center_2d.y, half_depth)
	var back_center := Vector3(center_2d.x, center_2d.y, -half_depth)
	for i in count:
		var next := (i + 1) % count
		var a2 := outline[i]
		var b2 := outline[next]
		var front_a := Vector3(a2.x, a2.y, half_depth)
		var front_b := Vector3(b2.x, b2.y, half_depth)
		var back_a := Vector3(a2.x, a2.y, -half_depth)
		var back_b := Vector3(b2.x, b2.y, -half_depth)
		_add_triangle(st, front_center, front_a, front_b)
		_add_triangle(st, back_center, back_b, back_a)
		_add_triangle(st, front_a, back_a, front_b)
		_add_triangle(st, front_b, back_a, back_b)
	st.generate_normals()
	return st.commit()


static func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


## mark_paw/mark_distal/mark_full (all default false, reproducing the prior
## single-color leg exactly) apply marking_color in three cascading levels:
## mark_paw colors just the paw; mark_distal ALSO colors the distal bone
## above it (Metacarpals/Metatarsals, down to the hock/carpus); mark_full
## ALSO colors the middle (RadiusUlna/TibiaFibula) and root (Humerus/Femur)
## bones, the entire limb. Each level is a strict superset of the one below
## it -- a caller only ever needs to set the HIGHEST level it wants (see
## build()'s own call sites), not every level individually.
static func _build_leg(
	body: Node3D, side: float, front: bool, color: Color, angles: Array, resting: bool,
	marking_color: Variant = null, mark_paw: bool = false, mark_distal: bool = false,
	mark_full: bool = false
) -> Dictionary:
	# Cascade: mark_full implies mark_distal implies mark_paw, so a caller
	# asking for "the whole leg" doesn't also have to separately ask for
	# "and its paw too."
	mark_distal = mark_distal or mark_full
	mark_paw = mark_paw or mark_distal
	var has_marking_color := marking_color != null
	var upper_len := FRONT_UPPER_LEN if front else HIND_UPPER_LEN
	var lower_len := FRONT_LOWER_LEN if front else HIND_LOWER_LEN
	var distal_len := FRONT_METAPODIAL_LEN if front else HIND_METAPODIAL_LEN
	var root := Node3D.new()
	root.name = "CatShoulderPivot" if front else "CatHipPivot"
	# The pelvic socket is 3.5 cm higher than the shoulder socket. That
	# compensates for the cat's longer folded hind chain while keeping both
	# sets of paws on the same ground plane.
	var body_half_width := THORAX_SIZE.x if front else HIP_SIZE.x
	root.position = Vector3(
		# Exact AABB-side tangency: socket center plus the bone radius equals
		# the body's half-width, so the outer leg surface is flush, not proud.
		side * (body_half_width - BONE_RADIUS),
		-0.015 * BODY_SCALE if front else 0.02 * BODY_SCALE,
		0.072 * BODY_SCALE if front else -0.045 * BODY_SCALE
	)
	root.rotation.x = angles[0]
	if resting:
		root.rotation.z = side * deg_to_rad(-38.0)
	body.add_child(root)
	var root_color: Color = marking_color if (mark_full and has_marking_color) else color
	_add_bone(root, "Humerus" if front else "Femur", upper_len, BONE_RADIUS, root_color)

	var middle := Node3D.new()
	middle.name = "CatElbowPivot" if front else "CatStiflePivot"
	middle.position.y = -upper_len
	middle.rotation.x = angles[1]
	root.add_child(middle)
	var middle_color: Color = marking_color if (mark_full and has_marking_color) else color
	_add_bone(middle, "RadiusUlna" if front else "TibiaFibula", lower_len, BONE_RADIUS, middle_color)

	var distal := Node3D.new()
	distal.name = "CatCarpusPivot" if front else "CatHockPivot"
	distal.position.y = -lower_len
	distal.rotation.x = angles[2]
	middle.add_child(distal)
	var distal_color: Color = marking_color if (mark_distal and has_marking_color) else color
	_add_bone(distal, "Metacarpals" if front else "Metatarsals", distal_len, BONE_RADIUS, distal_color)

	var paw_pivot := Node3D.new()
	paw_pivot.name = "CatPawPivot"
	paw_pivot.position.y = -distal_len
	# Cancel the accumulated long-bone pitch so the paw lies plantigrade on
	# the floor even though the limb above it is strongly digitigrade.
	paw_pivot.rotation.x = -(angles[0] as float) - (angles[1] as float) - (angles[2] as float)
	distal.add_child(paw_pivot)
	# Halve the established front and hind paw depths independently; the
	# hind paw keeps its existing 1 cm shorter half-depth before halving.
	var paw_depth := (PAW_LEN if front else PAW_LEN - 0.01) * 0.5
	var paw_color: Color = marking_color if (mark_paw and has_marking_color) else color
	var paw := SuperEgg.build_part(
		Vector3(BONE_RADIUS, 0.022 * BODY_SCALE, paw_depth), paw_color, 3.4, 3.4
	)
	paw.name = "CatPaw"
	# Both front paws move 2 cm toward the head. Hind paws retain their own
	# previously requested 2 cm forward correction too.
	paw.position.z = paw_depth * 0.55 + 0.02
	paw_pivot.add_child(paw)
	return {
		"root": root, "middle": middle, "distal": distal,
		"paw": paw_pivot, "paw_mesh": paw,
	}


static func _add_bone(parent: Node3D, bone_name: String, length: float, radius: float, color: Color) -> void:
	var bone := SuperEgg.build_part(Vector3(radius, length * 0.5, radius), color, 2.65, 2.65)
	bone.name = bone_name
	bone.position.y = -length * 0.5
	parent.add_child(bone)
