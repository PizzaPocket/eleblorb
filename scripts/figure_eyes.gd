class_name FigureEyes
extends RefCounted

## Oval "marks" for a procedurally-built superegg head (see
## procedural_figure.gd) -- a darker shade of the figure's own skin color,
## not fully black, so they read as a marking on the face rather than a
## painted-on cartoon eye. Placed via SuperEgg.surface_point() at a chosen
## latitude/longitude pair rather than a flat AABB-based offset, so they
## sit exactly on the true surface regardless of head size/proportions.
##
## omega=0 (dead-front) is genuinely the front here: the whole figure rig
## is built from scratch by procedural_figure.gd in this project's own
## consistent "+Z is forward" convention (matching visuals.rotation.y's
## atan2(x, z) elsewhere), with no imported-model asset in the chain to
## have its own conflicting native front. That's a real simplification
## over the previous imported-GLB rig, which needed a 180-degree ancestor
## correction (its front was baked in as local -Z) and, before that was
## understood, a matching omega=PI offset here just to compensate for it.


## semi_axes.x shrank when the head was narrowed, and this scaled directly
## off it -- reads as tiny dots now rather than ovals. Bumped the
## multiplier and the oblong ratio up to compensate and then some, then
## halved again per a later direct correction ("decrease the eye size by
## 50%"). Exposed as named consts (not inline literals in add_eyes()
## below) so other modules (figure_hair.gd's LONG hairstyle bangs cut,
## specifically) can compute real eye geometry instead of duplicating
## these numbers -- if eye size ever gets tuned again, anything computed
## from top_y() below stays in sync automatically.
const EYE_RADIUS_FACTOR := 0.26 * 0.5
const EYE_HEIGHT_RATIO := 1.4  # mesh's own Y semi-axis, as a multiple of eye_radius


## The eyes' own top edge, in the head's local Y (head center = 0). Eyes
## sit at eta=0 (the head's equator, y=0 in this frame) and add_eyes()'s
## own eye.position only ever adjusts the horizontal (X/Z) component, never
## Y -- so the top edge is simply the eye mesh's own vertical half-extent
## above that center.
static func top_y(semi_axes: Vector3) -> float:
	return semi_axes.x * EYE_RADIUS_FACTOR * EYE_HEIGHT_RATIO


## Returns the two created eye MeshInstance3D nodes (named "EyeL"/"EyeR") --
## callers that want to blink them (see eye_blink.gd) need a live reference
## to each eye's own local Y scale.
static func add_eyes(head: MeshInstance3D, semi_axes: Vector3, skin_color: Color) -> Array[MeshInstance3D]:
	var eye_radius := semi_axes.x * EYE_RADIUS_FACTOR
	var eta := 0.0  # exact center height (the head's own equator), not toward the top
	var eye_offset := deg_to_rad(18.0)  # each eye this far around from dead-front
	var eye_color := skin_color.darkened(0.25)
	var eyes: Array[MeshInstance3D] = []

	for side in [-1.0, 1.0]:
		var surface := SuperEgg.surface_point(semi_axes, eta, side * eye_offset)

		var eye := MeshInstance3D.new()
		eye.name = "EyeL" if side < 0.0 else "EyeR"
		# A superegg instead of a SphereMesh, per direct instruction -- same
		# oblong proportions as before (the y semi-axis is still taller than
		# x/z), just built from this project's own primitive instead of a
		# stock engine shape, so it reads consistently with the rest of the
		# rig once flattened by eye.scale below.
		eye.mesh = SuperEgg.build_mesh(
			Vector3(eye_radius, eye_radius * EYE_HEIGHT_RATIO, eye_radius),
			SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		var material := StandardMaterial3D.new()
		material.albedo_color = eye_color
		# Matte, not glossy -- see blorb_face.gd's identical change for why
		# (a bright capture rig's stacked lighting can blow a glossy,
		# tightly-curved eye surface out to solid white).
		material.roughness = 0.8
		eye.set_surface_override_material(0, material)

		# Flatten along the *horizontal* component of the outward surface
		# direction only, with the tall axis pinned to true world UP --
		# not the full 3D outward normal (an earlier version used
		# Basis.looking_at(-outward, UP), which lets the "up" hint tilt to
		# stay orthogonal to whatever the true 3D outward direction is at
		# that point; with eta above 0 that tilted each eye's tall axis in
		# toward the other, reading as "angled toward each other at the
		# top" instead of straight up and down -- eta=0 makes this a
		# non-issue for the eyes' own Y component today, but the fix
		# stays in place since it's also just more correct in general).
		var horizontal_outward := Vector3(surface.x, 0.0, surface.z).normalized()
		var up := Vector3.UP
		var right := up.cross(horizontal_outward).normalized()
		eye.basis = Basis(right, up, horizontal_outward)
		# Almost entirely flat (0.4 read as a distinct bump, not a mark) --
		# and nudged slightly inward along the same outward direction so
		# only a sliver actually clips through the face's surface instead
		# of sitting centered exactly on it (which would leave roughly
		# half of even this thin a sphere proud of the surface).
		eye.scale = Vector3(1.0, 1.0, 0.1)
		eye.position = surface - horizontal_outward * (eye_radius * 0.06)
		head.add_child(eye)
		eyes.append(eye)

	return eyes
