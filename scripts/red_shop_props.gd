class_name RedShopProps
extends RefCounted

## Procedural builders for the armorer's stall wares -- same primitive-mesh
## approach as AntiqueProps (no asset kit has adventuring gear either).
## Each builder returns a fresh Node3D, used both as shop-counter scenery
## and as the player's held-item visual (see ShopCatalog's build_visual
## entries).


static func build_sword(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.75, 0.77, 0.8)
	steel_mat.metallic = 0.85
	steel_mat.roughness = 0.25

	# One continuous forged blade from guard to point. The former box plus a
	# separate diamond cone left a visible construction seam and made the tip
	# read as an attached ornament rather than the termination of the edge.
	var blade_mesh := MeshInstance3D.new()
	blade_mesh.name = "ContinuousBlade"
	blade_mesh.mesh = _build_continuous_sword_blade(steel_mat)
	root.add_child(blade_mesh)

	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.55, 0.45, 0.2)
	guard_mat.metallic = 0.7
	guard_mat.roughness = 0.4

	var guard_mesh := MeshInstance3D.new()
	var guard := BoxMesh.new()
	guard.size = Vector3(0.25, 0.035, 0.035)
	guard.material = guard_mat
	guard_mesh.mesh = guard
	guard_mesh.position.y = 0.06
	root.add_child(guard_mesh)

	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.3, 0.2, 0.12)
	grip_mat.metallic = 0.0
	grip_mat.roughness = 0.85

	var grip_mesh := MeshInstance3D.new()
	var grip := CylinderMesh.new()
	grip.top_radius = 0.025
	grip.bottom_radius = 0.025
	grip.height = 0.24
	grip.radial_segments = 10
	grip.material = grip_mat
	grip_mesh.mesh = grip
	grip_mesh.position.y = -0.08
	root.add_child(grip_mesh)

	var pommel_mesh := MeshInstance3D.new()
	var pommel := SphereMesh.new()
	pommel.radius = 0.035
	pommel.height = 0.07
	pommel.radial_segments = 10
	pommel.rings = 6
	pommel.material = guard_mat
	pommel_mesh.mesh = pommel
	pommel_mesh.position.y = -0.225
	root.add_child(pommel_mesh)

	# The palm alignment point is authored on the actual outer surface of the
	# cylindrical hilt, centered where the fingers wrap—not at the weapon's
	# origin or inside its blade.
	var grip_point := Node3D.new()
	grip_point.name = "GripPoint"
	grip_point.position = Vector3(0.0, -0.08, -0.025)
	root.add_child(grip_point)
	# The shop copy stands upright, but the same builder is reused in the
	# player's hand. PalmAttach already inherits the hand's ~90-degree inward
	# yaw, so another local-X rotation composes into a WORLD-space left yaw.
	# Rotating around local Z instead maps the sword's +Y blade axis through
	# that existing palm basis into the player's +Z/front direction: a genuine
	# forward 90-degree pitch as seen on the character.
	root.set_meta("held_rotation", Vector3(0.0, 0.0, PI * 0.5))

	return root


static func _build_continuous_sword_blade(material: Material) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_material(material)
	const BASE_Y := 0.075
	const SHOULDER_Y := 0.84
	const TIP_Y := 0.99
	const BASE_HALF_WIDTH := 0.047
	const SHOULDER_HALF_WIDTH := 0.038
	const HALF_DEPTH := 0.012
	var front_base_left := Vector3(-BASE_HALF_WIDTH, BASE_Y, HALF_DEPTH)
	var front_base_right := Vector3(BASE_HALF_WIDTH, BASE_Y, HALF_DEPTH)
	var front_shoulder_left := Vector3(-SHOULDER_HALF_WIDTH, SHOULDER_Y, HALF_DEPTH)
	var front_shoulder_right := Vector3(SHOULDER_HALF_WIDTH, SHOULDER_Y, HALF_DEPTH)
	var front_tip := Vector3(0.0, TIP_Y, HALF_DEPTH)
	var back_base_left := Vector3(-BASE_HALF_WIDTH, BASE_Y, -HALF_DEPTH)
	var back_base_right := Vector3(BASE_HALF_WIDTH, BASE_Y, -HALF_DEPTH)
	var back_shoulder_left := Vector3(-SHOULDER_HALF_WIDTH, SHOULDER_Y, -HALF_DEPTH)
	var back_shoulder_right := Vector3(SHOULDER_HALF_WIDTH, SHOULDER_Y, -HALF_DEPTH)
	var back_tip := Vector3(0.0, TIP_Y, -HALF_DEPTH)

	_add_blade_quad(st, front_base_left, front_base_right, front_shoulder_left, front_shoulder_right)
	_add_blade_triangle(st, front_shoulder_left, front_shoulder_right, front_tip)
	_add_blade_quad(st, back_base_right, back_base_left, back_shoulder_right, back_shoulder_left)
	_add_blade_triangle(st, back_shoulder_right, back_shoulder_left, back_tip)
	_add_blade_quad(st, back_base_left, front_base_left, back_shoulder_left, front_shoulder_left)
	_add_blade_quad(st, front_base_right, back_base_right, front_shoulder_right, back_shoulder_right)
	_add_blade_quad(st, front_shoulder_left, front_tip, back_shoulder_left, back_tip)
	_add_blade_quad(st, front_tip, front_shoulder_right, back_tip, back_shoulder_right)
	_add_blade_quad(st, back_base_left, back_base_right, front_base_left, front_base_right)
	st.generate_normals()
	return st.commit()


static func _add_blade_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _add_blade_quad(
	st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3
) -> void:
	_add_blade_triangle(st, a, b, c)
	_add_blade_triangle(st, c, b, d)


static func build_armor(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.5, 0.52, 0.56)
	iron_mat.metallic = 0.75
	iron_mat.roughness = 0.4

	# A rounded front plate, not a flat panel -- a cylinder segment reads
	# as a chest curving away from the viewer better than a box would.
	var plate_csg := CSGCombiner3D.new()
	plate_csg.name = "DentedBreastplateCSG"
	root.add_child(plate_csg)
	var plate_mesh := CSGMesh3D.new()
	var plate := CylinderMesh.new()
	# Approximately human-torso scale. The earlier 28cm-wide, 22cm-high plate
	# read as a toy beside the vendor instead of something a person could wear.
	plate.top_radius = 0.31
	plate.bottom_radius = 0.245
	plate.height = 0.58
	plate.radial_segments = 16
	plate.material = iron_mat
	plate_mesh.mesh = plate
	plate_mesh.material = iron_mat
	plate_mesh.scale = Vector3(1.0, 1.0, 0.52)
	plate_csg.add_child(plate_mesh)

	# A real concavity, not a darker ball placed on the surface. The sphere
	# overlaps only the front skin of the flattened cylinder, so subtraction
	# leaves a shallow rounded impact depression without boring through it.
	var dent_mesh := CSGMesh3D.new()
	var dent := SphereMesh.new()
	dent.radius = 0.09
	dent.height = 0.18
	dent.radial_segments = 14
	dent.rings = 8
	dent_mesh.mesh = dent
	dent_mesh.material = iron_mat
	dent_mesh.operation = CSGShape3D.OPERATION_SUBTRACTION
	dent_mesh.position = Vector3(0.075, 0.055, 0.19)
	dent_mesh.scale = Vector3(1.0, 0.82, 0.62)
	plate_csg.add_child(dent_mesh)

	for x in [-0.285, 0.285]:
		var pauldron_mesh := MeshInstance3D.new()
		var pauldron := SphereMesh.new()
		pauldron.radius = 0.115
		pauldron.height = 0.23
		pauldron.radial_segments = 12
		pauldron.rings = 8
		pauldron.material = iron_mat
		pauldron_mesh.mesh = pauldron
		pauldron_mesh.position = Vector3(x, 0.255, 0.0)
		pauldron_mesh.scale = Vector3(1.0, 0.7, 1.0)
		root.add_child(pauldron_mesh)

	return root


const TORCH_FLAME_COLOR := Color(1.0, 0.5, 0.1)
const TORCH_LIGHT_RANGE := 3.0


static func build_torch(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.35, 0.22, 0.12)
	wood_mat.metallic = 0.0
	wood_mat.roughness = 0.8

	var handle_mesh := MeshInstance3D.new()
	var handle := CylinderMesh.new()
	handle.top_radius = 0.018
	handle.bottom_radius = 0.022
	handle.height = 0.32
	handle.radial_segments = 10
	handle.material = wood_mat
	handle_mesh.mesh = handle
	root.add_child(handle_mesh)

	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = TORCH_FLAME_COLOR
	flame_mat.emission_enabled = true
	flame_mat.emission = TORCH_FLAME_COLOR
	flame_mat.emission_energy_multiplier = 1.6

	var flame_position := Vector3(0, 0.2, 0)
	var flame_mesh := MeshInstance3D.new()
	var flame := SphereMesh.new()
	flame.radius = 0.045
	flame.height = 0.1
	flame.radial_segments = 12
	flame.rings = 8
	flame.material = flame_mat
	flame_mesh.mesh = flame
	flame_mesh.position = flame_position
	flame_mesh.scale = Vector3(0.7, 1.3, 0.7)
	root.add_child(flame_mesh)

	# Real light, not just an emissive mesh -- per direct instruction that
	# the torch should actually light up its surroundings, held or not.
	# Same convention as town_props.gd's build_lantern(): shadow disabled,
	# no explicit light_energy (defaults to 1.0, always on -- unlike the
	# lantern this isn't tied to day_night_cycle.gd, a torch stays lit
	# regardless of time of day).
	var light := OmniLight3D.new()
	light.name = "Light"
	light.position = flame_position
	light.light_color = TORCH_FLAME_COLOR
	light.omni_range = TORCH_LIGHT_RANGE
	light.shadow_enabled = false
	root.add_child(light)

	return root
