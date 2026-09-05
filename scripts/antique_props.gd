class_name AntiqueProps
extends RefCounted

## Procedural builders for the antique shop's wares -- built from primitive
## Godot meshes (CylinderMesh/SphereMesh/TorusMesh) rather than an asset
## kit, since none of this project's kits has curio-style props (confirmed:
## only architectural/nature pieces). Each builder returns a fresh Node3D,
## used both as shop-counter scenery and as the player's held-item visual
## (see ShopCatalog's build_visual entries).


static func build_compass(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var case_mesh := MeshInstance3D.new()
	var case_cyl := CylinderMesh.new()
	case_cyl.top_radius = 0.09
	case_cyl.bottom_radius = 0.09
	case_cyl.height = 0.03
	case_cyl.radial_segments = 20
	var case_mat := StandardMaterial3D.new()
	case_mat.albedo_color = Color(0.55, 0.42, 0.18)
	case_mat.metallic = 0.7
	case_mat.roughness = 0.45
	case_cyl.material = case_mat
	case_mesh.mesh = case_cyl
	root.add_child(case_mesh)

	var dome_mesh := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = 0.08
	dome.height = 0.08
	dome.radial_segments = 16
	dome.rings = 8
	var dome_mat := StandardMaterial3D.new()
	dome_mat.albedo_color = Color(0.8, 0.9, 0.95, 0.35)
	dome_mat.metallic = 0.1
	dome_mat.roughness = 0.05
	dome_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dome.material = dome_mat
	dome_mesh.mesh = dome
	dome_mesh.position.y = 0.02
	dome_mesh.scale = Vector3(1.0, 0.5, 1.0)
	root.add_child(dome_mesh)

	# Needle held at a fixed, slightly off angle rather than pointing any
	# particular way -- it never settles on a heading, so there's no
	# "correct" rest position to model.
	var needle_mesh := MeshInstance3D.new()
	var needle := BoxMesh.new()
	needle.size = Vector3(0.012, 0.006, 0.12)
	var needle_mat := StandardMaterial3D.new()
	needle_mat.albedo_color = Color(0.15, 0.15, 0.18)
	needle_mat.metallic = 0.5
	needle_mat.roughness = 0.3
	needle.material = needle_mat
	needle_mesh.mesh = needle
	needle_mesh.position.y = 0.03
	needle_mesh.rotation.y = deg_to_rad(35.0)
	root.add_child(needle_mesh)

	return root


static func build_locket(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var metal_mat := StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.62, 0.5, 0.28)
	metal_mat.metallic = 0.75
	metal_mat.roughness = 0.3

	var body_mesh := MeshInstance3D.new()
	var body := SphereMesh.new()
	body.radius = 0.07
	body.height = 0.14
	body.radial_segments = 18
	body.rings = 10
	body.material = metal_mat
	body_mesh.mesh = body
	# Oval capsule silhouette, not a plain sphere -- flattened and stretched
	# vertically.
	body_mesh.scale = Vector3(1.0, 1.25, 0.5)
	root.add_child(body_mesh)

	var hoop_mesh := MeshInstance3D.new()
	var hoop := TorusMesh.new()
	hoop.inner_radius = 0.012
	hoop.outer_radius = 0.028
	hoop.rings = 12
	hoop.ring_segments = 10
	hoop.material = metal_mat
	hoop_mesh.mesh = hoop
	hoop_mesh.position.y = 0.095
	hoop_mesh.rotation.x = deg_to_rad(90.0)
	root.add_child(hoop_mesh)

	return root


static func build_hourglass(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var glass_mat := StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.85, 0.92, 0.95, 0.25)
	glass_mat.metallic = 0.0
	glass_mat.roughness = 0.05
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.4, 0.26, 0.15)
	wood_mat.metallic = 0.0
	wood_mat.roughness = 0.7

	# Two cones meeting point-to-point at the pinch (y=0) -- CylinderMesh
	# with top_radius=0 puts its apex at local +Y by default, which is
	# already correct for the lower bulb (apex points up toward the pinch);
	# the upper bulb is just that same cone flipped 180 so its apex points
	# down instead.
	for side in [-1.0, 1.0]:
		var bulb_mesh := MeshInstance3D.new()
		var bulb := CylinderMesh.new()
		bulb.top_radius = 0.0
		bulb.bottom_radius = 0.06
		bulb.height = 0.09
		bulb.radial_segments = 14
		bulb.material = glass_mat
		bulb_mesh.mesh = bulb
		bulb_mesh.position.y = side * 0.045
		if side > 0:
			bulb_mesh.rotation.x = deg_to_rad(180.0)
		root.add_child(bulb_mesh)

		var cap_mesh := MeshInstance3D.new()
		var cap := CylinderMesh.new()
		cap.top_radius = 0.065
		cap.bottom_radius = 0.065
		cap.height = 0.012
		cap.radial_segments = 14
		cap.material = wood_mat
		cap_mesh.mesh = cap
		cap_mesh.position.y = side * 0.096
		root.add_child(cap_mesh)

	# Frozen sand: a small motionless clump right at the pinch, not a pile
	# that's fallen or flowing.
	var sand_mesh := MeshInstance3D.new()
	var sand := SphereMesh.new()
	sand.radius = 0.02
	sand.height = 0.018
	sand.radial_segments = 8
	sand.rings = 4
	var sand_mat := StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.78, 0.65, 0.4)
	sand_mat.roughness = 0.9
	sand.material = sand_mat
	sand_mesh.mesh = sand
	sand_mesh.position.y = -0.005
	sand_mesh.scale = Vector3(1.4, 0.5, 1.4)
	root.add_child(sand_mesh)

	return root
