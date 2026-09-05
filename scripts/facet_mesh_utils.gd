class_name FacetMeshUtils
extends RefCounted

## Shared triangle-building helper for hand-built faceted meshes (flat
## per-facet shading via a cross-product normal, one triangle at a time) --
## extracted out of gem.gd and debug_face_markers.gd, which each had their
## own identical copy; blorb_core.gd and antique_props.gd are further
## consumers.


static func add_tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3) -> void:
	var normal := (p1 - p0).cross(p2 - p0).normalized()
	st.set_normal(normal)
	st.add_vertex(p0)
	st.set_normal(normal)
	st.add_vertex(p1)
	st.set_normal(normal)
	st.add_vertex(p2)
