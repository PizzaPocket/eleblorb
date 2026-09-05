class_name BlorbCore
extends RefCounted

## An apple-sized, many-faceted orb suspended inside a blorb's body,
## visible through the translucent flesh -- reuses gem.gd's flat-per-facet
## SurfaceTool technique but with a different topology (a lat/long faceted
## near-sphere, not a 6-sided bipyramid) so it doesn't read as "just
## another gem." Default pale/opal material pre-merge; blorb.gd's
## merge_element() re-tints the material stored in "material" metadata
## without ever touching the mesh again.

const SEGMENTS := 8
const RINGS := 5


static func build(radius: float, color: Color, emissive: bool) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings: Array = []
	for ring_i in RINGS + 1:
		var v := float(ring_i) / RINGS  # 0 (bottom pole) .. 1 (top pole)
		var phi := v * PI
		var ring_radius := sin(phi) * radius
		var y := -cos(phi) * radius
		var points: Array[Vector3] = []
		for seg in SEGMENTS:
			var theta := (float(seg) / SEGMENTS) * TAU
			points.append(Vector3(cos(theta) * ring_radius, y, sin(theta) * ring_radius))
		rings.append(points)

	for ring_i in RINGS:
		var ring_a: Array = rings[ring_i]
		var ring_b: Array = rings[ring_i + 1]
		for seg in SEGMENTS:
			var seg_next := (seg + 1) % SEGMENTS
			var a0: Vector3 = ring_a[seg]
			var a1: Vector3 = ring_a[seg_next]
			var b0: Vector3 = ring_b[seg]
			var b1: Vector3 = ring_b[seg_next]
			FacetMeshUtils.add_tri(st, a0, b0, a1)
			FacetMeshUtils.add_tri(st, a1, b0, b1)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.2
	material.roughness = 0.1
	material.emission_enabled = emissive
	if emissive:
		material.emission = color
		material.emission_energy_multiplier = 1.2
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	mesh_instance.set_meta("material", material)
	return mesh_instance
