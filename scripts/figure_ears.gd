class_name FigureEars
extends RefCounted

## Small superegg ears for a procedurally-built superegg head (see
## procedural_figure.gd), placed and oriented the same way figure_eyes.gd
## places eyes -- via SuperEgg.surface_point() at a chosen latitude/
## longitude, not a flat AABB offset -- so they sit correctly regardless of
## head size/proportions. Per direct instruction: positioned on the dead
## sides of the head (not toward the front or back), sized about like the
## eyes, but ANGLED back the way real ears lean rather than sticking out
## perfectly perpendicular to the head.
##
## The position (sides) and the orientation (angled back) are deliberately
## computed from two different angles -- anchoring the ear itself further
## back would move it toward the back of the head, not just tilt it, which
## isn't what "on the sides... but angled back" asked for.


## pad_color (default transparent, meaning "no pad" -- same opt-in-via-
## alpha convention ProceduralFigure.build()'s own shoe_color uses) adds a
## small inset "ear pad" on the front (outward-facing) side of each ear,
## per direct instruction: "inset on all sides except the side touching
## the head." Flush at the ear's own bottom edge (where it roots into the
## skull), inset everywhere else -- see the pad-building block below for
## the axis derivation.
static func add_ears(
	head: MeshInstance3D, semi_axes: Vector3, skin_color: Color,
	round_shape: bool = false, vertical_shift_fraction: float = 0.0,
	pad_color: Color = Color(0.0, 0.0, 0.0, 0.0)
) -> void:
	# Same scale as figure_eyes.gd's eye_radius -- "about the size of the
	# player's eyes," per direct instruction -- then scaled up 25% twice
	# over, per two further direct corrections (1.25 * 1.25 = 1.5625x
	# total). ear_radius alone drives all three of the mesh's own
	# semi_axes below, so this one multiplier grows the whole ear
	# uniformly rather than just one dimension.
	var ear_radius := semi_axes.x * 0.26 * 1.25 * 1.25
	var eta := 0.0  # same latitude as the eyes (the head's own equator)
	var side_angle := deg_to_rad(90.0)  # dead side -- straight out, not toward the face or the back
	var back_tilt := deg_to_rad(25.0)  # orientation-only sweep, see below
	var ear_color := skin_color.darkened(0.12)

	for side in [-1.0, 1.0]:
		# Explicit : float (not :=) -- side's own element type from the
		# untyped [-1.0, 1.0] array literal isn't statically known, so :=
		# can't infer a type for an expression built from it (the exact
		# error blorb_face.gd's own identical side-loop already sidesteps
		# the same way).
		var omega: float = side * side_angle
		var surface := SuperEgg.surface_point(semi_axes, eta, omega)
		# A direct fraction of the head's own half-height, not a further
		# eta angle -- "shift the ears up by 12%" reads as a plain
		# proportional offset, not "reposition them at a different
		# latitude on the head's own curve" (which is what changing eta
		# itself would do, and would also drag them toward the crown's
		# narrower cross-section, changing how far out they sit too).
		# Doesn't touch `outward`/the ear's own orientation below -- purely
		# a position nudge.
		surface.y += vertical_shift_fraction * semi_axes.y

		# The ear's outward/protrusion direction, computed at omega +
		# side*back_tilt rather than at the ear's own anchor omega. At
		# eta=0 SuperEgg.surface_point's outward direction reduces exactly
		# to (sin(omega), 0, cos(omega)) -- reusing that same formula here
		# (instead of a separately-derived rotation matrix) means this is
		# provably just a Y-axis rotation of the side's own outward vector
		# toward -Z (backward, since omega=0 is dead-front/+Z per
		# figure_eyes.gd's own established convention). Checked numerically
		# for both sides at back_tilt=25 deg: right (side=+1) resolves to
		# roughly (0.91, 0, -0.42) and left (side=-1) to (-0.91, 0, -0.42)
		# -- each still pointing out toward its own side, now also toward
		# -Z, i.e. backward.
		var tilt_omega: float = omega + side * back_tilt
		var outward := Vector3(sin(tilt_omega), 0.0, cos(tilt_omega))

		var ear := MeshInstance3D.new()
		# x = thickness (front-to-back as seen from outside, maps to
		# world "right" below), y = height (the ear's long axis, kept
		# vertical), z = protrusion depth (maps to world "outward" below).
		# round_shape's own thickness (x)/protrusion (z) factors, per direct
		# correction for Xiao Hou Zi's ears (currently round_shape's only
		# caller -- see monkey_figure.gd): thinned from 0.35 to read flatter
		# front-to-back, and grown from 0.32 to reach out further from the
		# head. ear.position stays centered right on the head's own surface
		# point (no separate nudge), so a bigger z half-extent alone pushes
		# more of the mesh past the surface without any other change.
		var ear_axes := (
			Vector3(ear_radius * 0.20, ear_radius * 0.70, ear_radius * 0.48)
			if round_shape else Vector3(ear_radius * 0.35, ear_radius * 0.9, ear_radius * 0.55)
		)
		var ear_epsilon := 2.1 if round_shape else SuperEgg.EPSILON_SOFT
		ear.mesh = SuperEgg.build_mesh(ear_axes, ear_epsilon, ear_epsilon)
		var material := StandardMaterial3D.new()
		material.albedo_color = ear_color
		material.metallic = 0.0
		material.roughness = 0.95 if round_shape else 0.6
		if round_shape:
			material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
			material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY
			material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
		ear.set_surface_override_material(0, material)

		var up := Vector3.UP
		var right := up.cross(outward).normalized()
		ear.basis = Basis(right, up, outward)
		# No extra inward/outward nudge -- centering right on the head's
		# own surface point lets the mesh's own half-depth straddle it,
		# roughly half sunk into the head and half protruding, the same
		# "overlap into the neighboring part" seam treatment used at the
		# rig's other joints instead of a filler piece.
		ear.position = surface
		head.add_child(ear)

		if pad_color.a > 0.0:
			# Front face = local X, NOT local Z -- per direct correction,
			# "front" means the side the primate's FACE is on (forward,
			# toward +Z in world/head terms), not the side facing outward
			# away from the skull (which is what local Z actually is, this
			# mesh's own protrusion-depth axis -- see the "z = protrusion
			# depth" comment above on ear_axes). X is this mesh's own
			# THINNEST axis ("front-to-back as seen from outside," same
			# comment), i.e. the axis its two broad flat pinna-like faces
			# point along -- confirmed by working through this ear's own
			# basis (right, computed as up.cross(outward)) algebraically:
			# right.z = -sin(tilt_omega) = -side*sin(side_angle+back_tilt),
			# so local +X's own world Z-component has the SAME sign as
			# -side. That means which local X sign actually faces +Z
			# (forward, i.e. "front") flips between the two ears -- build_
			# inset_pad_mesh() always builds on the +outward_axis side, so
			# for the ear where that's the WRONG (backward-facing) sign,
			# pad_flip below rotates the whole pad 180 around Y (swapping
			# +X/-X, leaving Y untouched, so the flush-at-the-bottom edge
			# stays flush) to land it on the correct side instead.
			#
			# Flush edge = local -Y (the ear's own bottom, where it roots
			# into the skull); inset everywhere else (the sides, now local
			# Z, and the tip, local +Y) -- per direct instruction. Sized as
			# fractions of the ear's OWN dimensions rather than ape_
			# template.gd's fixed hand/foot pad constants, which are tuned
			# for a much bigger absolute part and would read as wildly
			# oversized here. Deep insets (a small centered patch, not most
			# of the face), a shallow dome (a thin marking, not a raised
			# pad), and a rounder falloff exponent (1.0, not the flat-
			# plateau shape the hand/foot pads use) so what height it does
			# have tapers gently -- per earlier direct correction the first
			# pass read as bigger than the ear itself.
			var pad := MeshInstance3D.new()
			pad.name = "EarPad"
			pad.mesh = SuperEgg.build_inset_pad_mesh(
				ear_axes, ear_epsilon, 0, 1, -1.0,
				0.45, 0.5, ear_axes.x * 0.4, 1.0, ear_axes.x * 0.2
			)
			var pad_material := StandardMaterial3D.new()
			pad_material.albedo_color = pad_color
			pad_material.roughness = 0.6
			pad_material.cull_mode = BaseMaterial3D.CULL_DISABLED
			pad.material_override = pad_material
			if side > 0.0:
				pad.basis = Basis(Vector3(-1, 0, 0), Vector3.UP, Vector3(0, 0, -1))
			ear.add_child(pad)
