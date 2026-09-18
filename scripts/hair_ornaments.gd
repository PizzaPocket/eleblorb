class_name HairOrnaments
extends RefCounted

## Shared hair/head ornament placement for humanoid NPC variants (Tempestar,
## Merfolk) -- queries FigureHair.hair_edges() for the REAL per-hairstyle
## envelope (the exact front/back/top/width numbers add_hair() itself builds
## the hair mesh from) instead of one hardcoded offset that only happened to
## clear a single style. Per direct correction: "make sure to account for
## the literal surface mesh of the hair... other jewelry and ornaments on
## the hair... a lot of them are like clipping into the head or definitely
## being clipped by some of the hairstyles." Every function here takes the
## head MESH (not the head pivot) -- the same local frame FigureHair/
## FigureEyes already build in -- matching how callers already fetch
## `pivots["head_mesh"]` from ProceduralFigure.build().

const LAUREL_LEAF_COUNT := 9
## Leaves span this much of the full circle, centered on the BACK -- per
## direct instruction, "a ring coming around the back of the head." Real
## laurel wreaths cluster leaves at the sides/back and leave the face
## itself bare, rather than a leaf sitting directly across the forehead.
const LAUREL_ARC_DEGREES := 300.0
const LAUREL_LEAF_SIZE := Vector3(0.014, 0.005, 0.028)
const LAUREL_FAN_ANGLE := deg_to_rad(35.0)
## A small clearance added past the hair's own real edge so leaves rest
## just outside the hair surface instead of exactly tangent to it (which
## can still visibly poke through at a mesh's own rounded corners).
const LAUREL_CLEARANCE := 0.006


## The real outward radius of `style`'s own hair envelope at horizontal
## angle `angle` (0 = straight back/-Z, +-PI/2 = the ears/+-X, PI = straight
## front/+Z) -- an ellipse-quadrant interpolation between the REAL width/
## front/back edges FigureHair.hair_edges() returns, not a single guessed
## number. Every hairstyle's own real envelope is rectangular-ish (an edges
## Dictionary), not literally elliptical, so this is an approximation --
## but one grounded in that style's own actual numbers, which is what
## actually varies from style to style, rather than a single constant that
## can only ever be right for one of them.
static func _envelope_radius_at(edges: Dictionary, angle: float) -> float:
	var z_edge: float = absf(edges["front"]) if cos(angle) < 0.0 else absf(edges["back"])
	var width: float = maxf(edges["width"], 0.001)
	z_edge = maxf(z_edge, 0.001)
	var x_term := sin(angle) / width
	var z_term := cos(angle) / z_edge
	var denom := sqrt(x_term * x_term + z_term * z_term)
	return 1.0 / maxf(denom, 0.001)


## A gold laurel wreath -- per direct instruction ("for the rulers to have
## something resembling a Greek crown. Like, gold Greek laurels. Which
## start as a ring coming around the back of the head"). `head_mesh` is the
## same MeshInstance3D FigureHair.add_hair() was called on for this same
## character; `style`/`semi_axes` must match that same call so the wreath
## always sits against whatever hairstyle is actually built, not a guess.
## Per direct correction against a real reference photo: the band is NOT a
## level ring -- it rises from low at the back/nape up to high near the
## front hairline (back_y/front_y below), each leaf stands roughly upright
## along that band rather than lying flat pointing straight outward, and it
## uses a real metallic gold material (see _gold_material()), not a flat
## diffuse color.
static func build_laurel_wreath(head_mesh: MeshInstance3D, semi_axes: Vector3, style: String, color: Color) -> Node3D:
	var edges := FigureHair.hair_edges(style, semi_axes)
	var gold_material := _gold_material(color)
	var half_arc := deg_to_rad(LAUREL_ARC_DEGREES) * 0.5
	var back_y: float = FigureEyes.top_y(semi_axes) * 0.35
	var front_y: float = edges["top"] * 0.85
	var wreath := Node3D.new()
	wreath.name = "LaurelWreath"
	head_mesh.add_child(wreath)
	for i in LAUREL_LEAF_COUNT:
		var t := float(i) / float(LAUREL_LEAF_COUNT - 1)
		var angle := lerpf(-half_arc, half_arc, t)
		var height_t := absf(angle) / half_arc
		var ring_y := lerpf(back_y, front_y, height_t)
		var radius := _envelope_radius_at(edges, angle) + LAUREL_CLEARANCE
		var outward := Vector3(sin(angle), 0.0, -cos(angle))
		var tangent := Vector3(cos(angle), 0.0, sin(angle))
		var pos := Vector3(0.0, ring_y, 0.0) + outward * radius
		# The leaf's own long axis (LAUREL_LEAF_SIZE.z) points mostly UP with
		# a slight outward lean, standing it up along the band instead of
		# flat/radial (per direct correction, "oriented vertically, not
		# horizontally"); tangent has zero Y and outward has zero Y, so this
		# stays a genuine orthonormal basis, not an approximate/skewed one.
		var z_axis := (outward * 0.5 + Vector3.UP).normalized()
		var y_axis := z_axis.cross(tangent).normalized()
		var sides: Array[float] = [-1.0, 1.0]
		for side in sides:
			var leaf := MeshInstance3D.new()
			leaf.mesh = SuperEgg.build_mesh(LAUREL_LEAF_SIZE, 2.2, 2.2)
			leaf.material_override = gold_material
			leaf.basis = Basis(tangent, y_axis, z_axis).rotated(outward, side * LAUREL_FAN_ANGLE)
			leaf.position = pos + tangent * side * 0.012
			wreath.add_child(leaf)
	return wreath


## The shared metallic gold recipe (matches sky_kingdom.gd's own
## _gold_material() -- same numbers, kept as its own copy since that one is
## a private instance method scoped to Sky Kingdom's own StandardMaterial3D
## caching, not a shared utility this file can call into).
static func _gold_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.85
	material.roughness = 0.22
	return material


## A small ornament (shell or sea-flower, see merfolk.gd's own
## hair_ornament export) nestled against the real outward hair surface on
## one side of the head, at brow height -- replacing a single fixed local
## offset that clipped into bulkier hairstyles and floated away from
## slimmer ones. `side`: -1.0 or 1.0.
static func side_hair_anchor(semi_axes: Vector3, style: String, side: float) -> Dictionary:
	var edges := FigureHair.hair_edges(style, semi_axes)
	var angle := side * deg_to_rad(60.0)  # 0 = back, so 60 degrees puts this just behind the ear
	var radius := _envelope_radius_at(edges, angle) + LAUREL_CLEARANCE
	var outward := Vector3(sin(angle), 0.0, -cos(angle))
	var y := FigureEyes.top_y(semi_axes) * 0.55
	return {
		"position": Vector3(0.0, y, 0.0) + outward * radius,
		"outward": outward,
	}
