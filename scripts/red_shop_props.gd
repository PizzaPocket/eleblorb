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

	var blade_mesh := MeshInstance3D.new()
	var blade := BoxMesh.new()
	blade.size = Vector3(0.05, 0.36, 0.012)
	blade.material = steel_mat
	blade_mesh.mesh = blade
	blade_mesh.position.y = 0.21
	root.add_child(blade_mesh)

	# Pointed tip -- a flattened cone, same top_radius=0 CylinderMesh trick
	# AntiqueProps.build_hourglass() uses for its glass bulbs.
	var tip_mesh := MeshInstance3D.new()
	var tip := CylinderMesh.new()
	tip.top_radius = 0.0
	tip.bottom_radius = 0.025
	tip.height = 0.06
	tip.radial_segments = 4
	tip.material = steel_mat
	tip_mesh.mesh = tip
	tip_mesh.position.y = 0.42
	tip_mesh.scale = Vector3(2.0, 1.0, 0.5)
	root.add_child(tip_mesh)

	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.55, 0.45, 0.2)
	guard_mat.metallic = 0.7
	guard_mat.roughness = 0.4

	var guard_mesh := MeshInstance3D.new()
	var guard := BoxMesh.new()
	guard.size = Vector3(0.14, 0.02, 0.02)
	guard.material = guard_mat
	guard_mesh.mesh = guard
	guard_mesh.position.y = 0.03
	root.add_child(guard_mesh)

	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.3, 0.2, 0.12)
	grip_mat.metallic = 0.0
	grip_mat.roughness = 0.85

	var grip_mesh := MeshInstance3D.new()
	var grip := CylinderMesh.new()
	grip.top_radius = 0.015
	grip.bottom_radius = 0.015
	grip.height = 0.1
	grip.radial_segments = 10
	grip.material = grip_mat
	grip_mesh.mesh = grip
	grip_mesh.position.y = -0.02
	root.add_child(grip_mesh)

	var pommel_mesh := MeshInstance3D.new()
	var pommel := SphereMesh.new()
	pommel.radius = 0.02
	pommel.height = 0.04
	pommel.radial_segments = 10
	pommel.rings = 6
	pommel.material = guard_mat
	pommel_mesh.mesh = pommel
	pommel_mesh.position.y = -0.075
	root.add_child(pommel_mesh)

	return root


static func build_armor(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var iron_mat := StandardMaterial3D.new()
	iron_mat.albedo_color = Color(0.5, 0.52, 0.56)
	iron_mat.metallic = 0.75
	iron_mat.roughness = 0.4

	# A rounded front plate, not a flat panel -- a cylinder segment reads
	# as a chest curving away from the viewer better than a box would.
	var plate_mesh := MeshInstance3D.new()
	var plate := CylinderMesh.new()
	plate.top_radius = 0.14
	plate.bottom_radius = 0.11
	plate.height = 0.22
	plate.radial_segments = 16
	plate.material = iron_mat
	plate_mesh.mesh = plate
	plate_mesh.scale = Vector3(1.0, 1.0, 0.55)
	root.add_child(plate_mesh)

	var dent_mat := StandardMaterial3D.new()
	dent_mat.albedo_color = Color(0.4, 0.42, 0.46)
	dent_mat.metallic = 0.7
	dent_mat.roughness = 0.55

	# The dent the item's name promises -- a small inward-pressed sphere
	# sunk halfway into the plate's front face.
	var dent_mesh := MeshInstance3D.new()
	var dent := SphereMesh.new()
	dent.radius = 0.035
	dent.height = 0.07
	dent.radial_segments = 10
	dent.rings = 6
	dent.material = dent_mat
	dent_mesh.mesh = dent
	dent_mesh.position = Vector3(0.03, 0.02, 0.05)
	root.add_child(dent_mesh)

	for x in [-0.1, 0.1]:
		var pauldron_mesh := MeshInstance3D.new()
		var pauldron := SphereMesh.new()
		pauldron.radius = 0.055
		pauldron.height = 0.11
		pauldron.radial_segments = 12
		pauldron.rings = 8
		pauldron.material = iron_mat
		pauldron_mesh.mesh = pauldron
		pauldron_mesh.position = Vector3(x, 0.12, 0.0)
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
