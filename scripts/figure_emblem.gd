class_name FigureEmblem
extends RefCounted

## A small flat triangular emblem embedded on the chest's front -- per
## direct instruction, restoring a design element from before the player
## rig went fully procedural. Same "true surface normal + slight inward
## embed" treatment as figure_eyes.gd's eyes: chest is convex, so a
## perfectly flat decal tangent at one point would have its edges float
## visibly proud of the surface everywhere around that point -- sinking it
## in a little along the normal fixes that.

const EMBED_DEPTH_FRACTION := 0.35  # fraction of the emblem's own half-height sunk inward along the normal


static func add_chest_emblem(chest: MeshInstance3D, semi_axes: Vector3, color: Color) -> void:
	var eta := deg_to_rad(12.0)  # slightly above center, a typical chest-emblem placement
	var surface := SuperEgg.surface_point(semi_axes, eta, 0.0, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)

	var half_width := semi_axes.x * 0.3
	var half_height := semi_axes.y * 0.3

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Flat in the shape's own local Z=0 plane, apex up -- local +Z (not
	# Godot's Vector3.FORWARD, which is -Z) matches this project's own
	# "+Z is forward" convention used everywhere else in the rig.
	var normal := Vector3(0.0, 0.0, 1.0)
	st.set_normal(normal)
	st.add_vertex(Vector3(0.0, half_height, 0.0))
	st.set_normal(normal)
	st.add_vertex(Vector3(-half_width, -half_height, 0.0))
	st.set_normal(normal)
	st.add_vertex(Vector3(half_width, -half_height, 0.0))

	var emblem := MeshInstance3D.new()
	emblem.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.35
	# Winding here was never checked against camera-facing convention --
	# same low-risk fix as terrain_generator.gd/distant_mountains.gd's own
	# meshes: disable culling rather than guess.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	emblem.set_surface_override_material(0, material)

	# Align the shape's own local +Z (its flat face's normal) with the
	# true outward surface normal at this point -- same construction
	# figure_eyes.gd uses for the eyes, avoiding Basis.looking_at's
	# tilt-toward-center behavior, which isn't wanted for a flat decal
	# either.
	var horizontal_outward := Vector3(surface.x, 0.0, surface.z).normalized()
	var up := Vector3.UP
	var right := up.cross(horizontal_outward).normalized()
	emblem.basis = Basis(right, up, horizontal_outward)
	emblem.position = surface - horizontal_outward * (half_height * EMBED_DEPTH_FRACTION)
	chest.add_child(emblem)
