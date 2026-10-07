class_name DesignAudit
extends RefCounted

## Mechanical checks of the design language (architecture skill, section 1a),
## for the problems prose alone let through. The first fishing village pass
## shipped rounded-rectangle roofs, from a placeholder builder and then a kit
## with its own slab code, because nothing checked form.

const ROOF_SLAB_META := "roof_slab"
## A covering lying on a roof slab (snow, thatch, moss): not itself a roof.
const ROOF_COVER_META := "roof_cover"
## A slab this broad in two directions and this thin, above head height, is a
## roof, a canopy or a ceiling.
const SLAB_MIN_SPAN := 1.5
const SLAB_MAX_THICKNESS := 0.5
## A slab pitched between these (degrees from level) is a roof.
const MIN_PITCH := 8.0
const MAX_PITCH := 70.0


## One message per broad, thin generated slab above `head_y` (in `root`'s
## frame) that is not a TownProps roof slab. Plain boxes are left out: floors
## and ceilings are flat box slabs by design, so they meet the walls flush.
static func untagged_roofs(root: Node3D, head_y: float) -> Array[String]:
	var problems: Array[String] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		if mesh_node.mesh == null or mesh_node.mesh is PrimitiveMesh or mesh_node.has_meta(ROOF_SLAB_META) or mesh_node.has_meta(ROOF_COVER_META):
			continue
		var xform := Transform3D.IDENTITY
		var current: Node = mesh_node
		while current != null and current != root:
			if current is Node3D:
				xform = (current as Node3D).transform * xform
			current = current.get_parent()
		# Measure in the mesh's own frame (a sloped roof is thin across its
		# own normal, not in world height), scaled by its transform.
		var size := mesh_node.mesh.get_aabb().size * xform.basis.get_scale()
		var dims := [size.x, size.y, size.z]
		dims.sort()
		var bounds := xform * mesh_node.mesh.get_aabb()
		# Only pitched slabs: a wall is thin but vertical, a floor or landing
		# thin but level, and neither is a roof.
		var thin_axis := 0 if size.x == dims[0] else (1 if size.y == dims[0] else 2)
		var normal := xform.basis[thin_axis].normalized()
		var tilt := rad_to_deg(acos(clampf(absf(normal.y), 0.0, 1.0)))
		if tilt < MIN_PITCH or tilt > MAX_PITCH:
			continue
		if dims[0] <= SLAB_MAX_THICKNESS and dims[1] >= SLAB_MIN_SPAN and bounds.position.y > head_y:
			problems.append("%s: a %.1f x %.1f m slab at %s is not a TownProps.roof_slab (build roofs and canopies with it)" % [
				root.name, dims[2], dims[1], str(bounds.get_center()),
			])
	return problems
