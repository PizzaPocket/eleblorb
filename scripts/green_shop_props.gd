class_name GreenShopProps
extends RefCounted

## Procedural builders for the provisioner's stall wares -- same primitive-
## mesh approach as AntiqueProps/RedShopProps. Each builder returns a
## fresh Node3D, used both as shop-counter scenery and as the player's
## held-item visual (see ShopCatalog's build_visual entries).


static func build_bread(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var crust_mat := StandardMaterial3D.new()
	crust_mat.albedo_color = Color(0.62, 0.42, 0.2)
	crust_mat.metallic = 0.0
	crust_mat.roughness = 0.85

	var loaf_mesh := MeshInstance3D.new()
	var loaf := CapsuleMesh.new()
	loaf.radius = 0.06
	loaf.height = 0.2
	loaf.radial_segments = 14
	loaf.rings = 6
	loaf.material = crust_mat
	loaf_mesh.mesh = loaf
	# Lying on its side, flattened on the bottom half so it reads as a
	# loaf resting on a counter, not a floating pill.
	loaf_mesh.rotation.z = deg_to_rad(90.0)
	loaf_mesh.scale = Vector3(1.0, 1.0, 0.8)
	root.add_child(loaf_mesh)

	var slash_mat := StandardMaterial3D.new()
	slash_mat.albedo_color = Color(0.78, 0.6, 0.32)
	slash_mat.metallic = 0.0
	slash_mat.roughness = 0.9

	for offset in [-0.045, 0.0, 0.045]:
		var slash_mesh := MeshInstance3D.new()
		var slash := BoxMesh.new()
		slash.size = Vector3(0.01, 0.08, 0.05)
		slash.material = slash_mat
		slash_mesh.mesh = slash
		slash_mesh.position = Vector3(offset, 0.055, 0.0)
		slash_mesh.rotation.y = deg_to_rad(30.0)
		root.add_child(slash_mesh)

	return root


static func build_cheese(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var cheese_mat := StandardMaterial3D.new()
	cheese_mat.albedo_color = Color(0.92, 0.78, 0.25)
	cheese_mat.metallic = 0.0
	cheese_mat.roughness = 0.55

	var wedge_mesh := MeshInstance3D.new()
	var wedge := PrismMesh.new()
	wedge.size = Vector3(0.12, 0.08, 0.12)
	wedge.material = cheese_mat
	wedge_mesh.mesh = wedge
	root.add_child(wedge_mesh)

	var hole_mat := StandardMaterial3D.new()
	hole_mat.albedo_color = Color(0.75, 0.6, 0.16)
	hole_mat.metallic = 0.0
	hole_mat.roughness = 0.6

	for pos in [Vector3(-0.02, -0.01, 0.03), Vector3(0.01, 0.01, -0.02), Vector3(0.02, -0.02, 0.01)]:
		var hole_mesh := MeshInstance3D.new()
		var hole := SphereMesh.new()
		hole.radius = 0.012
		hole.height = 0.024
		hole.radial_segments = 8
		hole.rings = 4
		hole.material = hole_mat
		hole_mesh.mesh = hole
		hole_mesh.position = pos
		root.add_child(hole_mesh)

	return root


static func build_berries(item_scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * item_scale

	var berry_mat := StandardMaterial3D.new()
	berry_mat.albedo_color = Color(0.55, 0.12, 0.22)
	berry_mat.metallic = 0.0
	berry_mat.roughness = 0.4

	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.35, 0.28, 0.12)
	stem_mat.metallic = 0.0
	stem_mat.roughness = 0.9

	var stem_mesh := MeshInstance3D.new()
	var stem := CylinderMesh.new()
	stem.top_radius = 0.004
	stem.bottom_radius = 0.006
	stem.height = 0.09
	stem.radial_segments = 6
	stem.material = stem_mat
	stem_mesh.mesh = stem
	root.add_child(stem_mesh)

	# A small cluster, not a single berry -- offsets loosely radiate out
	# and down from the stem so it reads as a dried sprig, not a pile.
	var berry_offsets := [
		Vector3(0.0, 0.03, 0.0),
		Vector3(0.025, 0.01, 0.015),
		Vector3(-0.02, -0.005, 0.02),
		Vector3(0.01, -0.03, -0.02),
		Vector3(-0.025, -0.015, -0.015),
	]
	for offset in berry_offsets:
		var berry_mesh := MeshInstance3D.new()
		var berry := SphereMesh.new()
		berry.radius = 0.016
		berry.height = 0.032
		berry.radial_segments = 8
		berry.rings = 5
		berry.material = berry_mat
		berry_mesh.mesh = berry
		berry_mesh.position = offset
		root.add_child(berry_mesh)

	return root
