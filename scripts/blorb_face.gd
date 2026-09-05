class_name BlorbFace
extends RefCounted

## Simple flat oval eyes, matching figure_eyes.gd's style rather than a
## two-part sclera+pupil design (which read as "big crazy floating bug
## eyes" in practice, not cute). Colored as a darker shade of the blorb's
## own body color -- per direct instruction, not flat black -- so it reads
## as a marking on the body rather than a separate hard material, the same
## darkened(0.25) treatment figure_eyes.gd already uses for the player/NPC
## rig (an earlier darkened(0.55) here read as near-black against the
## light default spawn colors despite the comment already claiming parity
## with figure_eyes.gd).
##
## Two things beyond just "place them on the surface" turned out to matter
## for reading as embedded rather than perched-on-top buttons:
##
## 1. The true surface normal at the eye line isn't purely horizontal.
## blorb.gd's body is a surface of revolution whose radius changes with
## height (dr_dy, passed in) -- past the bulge peak the radius is
## shrinking as height increases, so the real outward normal tilts
## upward. Flattening the eye against a purely-horizontal approximation
## of "outward" (an earlier version did exactly that) leaves its flat
## face misaligned against the actual curve at that point.
##
## 2. Even with the correct normal, a perfectly flat disc tangent to a
## curved surface at one point still has its *edges* lift away from the
## surface in every direction (the surface curves away from a flat
## tangent plane) -- the classic "sticker on a ball" problem. Nudging the
## eye slightly inward along the normal (EMBED_DEPTH) sinks it enough that
## the edges read as pressed into the mesh instead of floating just
## proud of it.


const EMBED_DEPTH_FRACTION := 0.35  # fraction of eye_radius sunk inward along the normal


## Returns the two created eye MeshInstance3D nodes (named "EyeL"/"EyeR") --
## callers that want to blink them (see eye_blink.gd) need a live reference
## to each eye's own local Y scale.
static func add_eyes(
	body: Node3D, radius_at_eye_height: float, eye_y: float, dr_dy: float, body_color: Color,
	eye_size_multiplier: float = 1.0
) -> Array[MeshInstance3D]:
	# Halved per direct correction ("decrease the eye size by 50%, on
	# everyone" -- figure_eyes.gd's identical player/NPC eyes got the same
	# treatment).
	var eye_radius := radius_at_eye_height * 0.16 * 0.5 * eye_size_multiplier
	var eye_angle := deg_to_rad(28.0)  # each eye this far around from dead-front
	var eye_color := body_color.darkened(0.25)
	var eyes: Array[MeshInstance3D] = []

	for side in [-1.0, 1.0]:
		var angle: float = side * eye_angle
		var x := radius_at_eye_height * sin(angle)
		var z := radius_at_eye_height * cos(angle)
		var surface := Vector3(x, eye_y, z)

		var eye := MeshInstance3D.new()
		eye.name = "EyeL" if side < 0.0 else "EyeR"
		# A superegg instead of a SphereMesh, per direct instruction --
		# matches figure_eyes.gd's identical switch, keeping the same
		# slightly-oblong proportions (y taller than x/z) that the
		# subsequent eye.scale flattening below still relies on.
		eye.mesh = SuperEgg.build_mesh(
			Vector3(eye_radius, eye_radius * 1.15, eye_radius), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT
		)
		var material := StandardMaterial3D.new()
		material.albedo_color = eye_color
		# Matte, not glossy (0.35 read as a hard, shiny "button" under the
		# Blorbs-tab portrait's stacked key+fill+ambient lighting -- the
		# eyes' own tight, convex curvature concentrated the specular
		# highlight enough to blow out to solid white and cover almost the
		# whole eye, reported as "the eyes in the menu are all white."
		# Matches the design intent anyway -- a "marking on the body," not a
		# separate hard material, per this file's own doc comment).
		material.roughness = 0.8
		eye.set_surface_override_material(0, material)

		# True outward surface normal in the meridian plane at this point:
		# for a surface of revolution, the normal perpendicular to the
		# profile curve's tangent (dr_dy, 1) is (1, -dr_dy) in
		# (radial, vertical) terms -- verified against the two limiting
		# cases (dr_dy=0 at a sphere's equator gives a purely horizontal
		# normal; dr_dy -> -inf approaching a pole from below gives an
		# increasingly vertical one, both correct).
		var radial_dir := Vector3(sin(angle), 0.0, cos(angle))
		var outward := (radial_dir - Vector3.UP * dr_dy).normalized()

		eye.basis = Basis.looking_at(-outward, Vector3.UP)
		eye.scale = Vector3(1.0, 1.0, 0.4)
		eye.position = surface - outward * (eye_radius * EMBED_DEPTH_FRACTION)
		body.add_child(eye)
		eyes.append(eye)

	return eyes
