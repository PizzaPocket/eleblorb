class_name FireCalderaGround
extends RefCounted

## The caldera city's own ground (fire_caldera_layout.md, sections 1 and 1a):
## the reservoir basin and its bank, the terraces rising from the promenade to
## the service loop and toward the far wall, and the three gentler immersion
## shelves into the lava. One height function, in the plan's local frame, is
## the source for the ground mesh, its collision, the lava's extent and the
## plot survey, so they cannot disagree.
##
## Heights are world Y. In the live kingdom this replaces the coarse flat
## crater floor inside the city and blends back to the original crater wall.

## The lava surface, a little below the bank's lip.
const LAVA_Y := FireCalderaPlan.FLOOR_Y - 0.8
## The bank's lip, where the promenade meets it.
const LIP_Y := FireCalderaPlan.FLOOR_Y + 0.3
## The basin's bed under the deepest lower rooms (layout section 7: down to
## 18 m below the surface).
const BED_DEPTH := 22.0
## How fast the ordinary bank falls away below the lip (metres down per metre
## in): a steep, cooled-basalt bank, not a beach.
const BANK_FALL := 2.4
## The immersion shelves fall gently instead, a walkable descent.
const SHELF_FALL := 0.45
const SHELF_HALF_WIDTH := 3.5
## The terraces: a rise per metre outward from the bank, and a tilt up toward
## the far wall (local +Y), so the far bank's civic quarter stands highest.
const TERRACE_GRADE := 0.07
const FAR_TILT := 0.025
## Where the city's ground gives way to the crater wall.
const WALL_BLEND := Vector2(FireCalderaPlan.FLOOR_RADIUS, FireCalderaPlan.FLOOR_RADIUS + 8.0)

const EMBED := 1.5
## Foundation type by the ground's change across the reserved plot.
const SOCKET_MAX := 1.5
const PODIUM_MAX := 4.0
const EXPOSED_MAX := 3.0


## Ground height at a local plan point, before blending into the crater wall.
static func height(local: Vector2) -> float:
	var r := local.length()
	var angle := local.angle()
	var bank := FireCalderaPlan.reservoir_radius(angle)
	# The lip at this bearing: the terrace's own height there, so the bank
	# falls from the ground it belongs to with no step at the edge.
	var lip := LIP_Y + _tilt(local)
	if r < bank:
		var fall := lerpf(BANK_FALL, SHELF_FALL, _shelf_weight(local))
		return maxf(lip - (bank - r) * fall, LAVA_Y - BED_DEPTH)
	return lip + (r - bank) * TERRACE_GRADE


## The rise toward the far wall (local +Y), none on the arrival side.
static func _tilt(local: Vector2) -> float:
	return (maxf(local.y, -20.0) + 20.0) * FAR_TILT


## Ground height including the blend into the existing crater wall, given that
## wall's height (`wall`: a Callable taking local Vector2, returning world Y).
static func blended_height(local: Vector2, wall: Callable) -> float:
	return blend_height(local, float(wall.call(local)))


## The same blend when the caller already sampled its wall. The live kingdom
## uses this form so its outer edge can agree exactly with the coarse terrain
## mesh rather than evaluating a second approximation of that mesh.
static func blend_height(local: Vector2, wall_height: float) -> float:
	var own := height(local)
	var t := smoothstep(WALL_BLEND.x, WALL_BLEND.y, local.length())
	if t <= 0.0:
		return own
	return lerpf(own, maxf(wall_height, own), t)


## 1 on an immersion shelf's centre line, fading to 0 at its sides.
static func _shelf_weight(local: Vector2) -> float:
	var weight := 0.0
	for shelf in FireCalderaPlan.IMMERSION_SHELVES:
		var entry := FireCalderaPlan.plot(str(shelf["plot"]))
		var bearing := FireCalderaPlan.front_point(entry).angle()
		var direction := Vector2(cos(bearing), sin(bearing))
		var across := absf(local.cross(direction))
		if local.dot(direction) > 0.0 and across < SHELF_HALF_WIDTH * 1.6:
			weight = maxf(weight, 1.0 - smoothstep(SHELF_HALF_WIDTH, SHELF_HALF_WIDTH * 1.6, across))
	return weight


## The plot survey (layout section 1a, "Required plot survey"), computed from
## this ground: samples at the corners, edge midpoints, centre, both doors and
## both route landings; change, grade and uphill vector; the floor datum from
## the public threshold; foundation type, bottom, embed and exposed height;
## the retaining face on the uphill side.
static func survey(entry: Dictionary) -> Dictionary:
	var polygon := FireCalderaPlan.plot_polygon(entry)
	var centre: Vector2 = entry["centre"]
	var front := FireCalderaPlan.front_point(entry)
	var back := FireCalderaPlan.back_point(entry)
	var points := {"centre": centre, "front door": front, "back door": back,
		"front landing": front + FireCalderaPlan.facing(entry) * 2.0, "back landing": back - FireCalderaPlan.facing(entry) * 2.0}
	for i in polygon.size():
		points["corner %d" % i] = polygon[i]
		points["edge %d" % i] = polygon[i].lerp(polygon[(i + 1) % polygon.size()], 0.5)
	var samples := {}
	var low := INF
	var high := -INF
	for key: String in points:
		var y := height(points[key])
		samples[key] = y
		if not key.ends_with("landing"):
			low = minf(low, y)
			high = maxf(high, y)
	var gradient := Vector2(height(centre + Vector2(0.5, 0)) - height(centre - Vector2(0.5, 0)), height(centre + Vector2(0, 0.5)) - height(centre - Vector2(0, 0.5)))
	var max_grade := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		max_grade = maxf(max_grade, absf(height(a) - height(b)) / a.distance_to(b))
	max_grade = maxf(max_grade, gradient.length())
	# The floor meets its public threshold flush: the datum is the ground at
	# the front landing (where the promenade arrives), not the plot's average.
	var datum: float = samples["front landing"]
	var change := high - low
	var kind := "socket plinth" if change <= SOCKET_MAX else ("stepped podium" if change <= PODIUM_MAX else "bedrock spine")
	return {
		"id": entry["id"], "samples": samples, "low": low, "high": high, "change": change,
		"uphill": gradient.normalized(), "max_grade": max_grade, "datum": datum,
		"foundation": kind, "bottom": low - EMBED, "embed": EMBED,
		# Below the datum, the foundation shows on the downhill side; above it,
		# the uphill side cuts into a retaining socket.
		"exposed": maxf(datum - low, 0.0), "retaining": maxf(high - datum, 0.0),
		"service_landing": samples["back landing"], "public_landing": samples["front landing"],
		"terrain_exclusion": polygon,
	}


# ---------------------------------------------------------------------------
# Building it
# ---------------------------------------------------------------------------

## The ground mesh extends this far from the centre (into the wall blend).
const EXTENT := 84.0
## A hidden overlap apron wider than one coarse terrain cell. Coarse triangles
## are cut at EXTENT - 2, while this identical wall-blended skin continues far
## enough beneath them that no clipped corner can expose sky.
const MESH_EXTENT := 90.0
const CELL := 0.5
const BASALT := Color(0.13, 0.12, 0.12)
const TERRACE := Color(0.20, 0.18, 0.17)
const BANK := Color(0.09, 0.08, 0.08)
const HEAT := Color(0.45, 0.16, 0.06)


## The crater wall as the kingdom's terrain draws it (floor to rim), for the
## blend at the floor's edge when the proof scene has no terrain.
static func crater_wall(local: Vector2) -> float:
	var r := local.length()
	if r < FireCalderaPlan.FLOOR_RADIUS:
		return FireCalderaPlan.FLOOR_Y
	return lerpf(FireCalderaPlan.FLOOR_Y, 48.0, smoothstep(FireCalderaPlan.FLOOR_RADIUS, FireCalderaPlan.RIM_RADIUS, r))


## Builds the ground as one body in `parent`'s frame (local plan coordinates,
## world heights). `sockets` are [{"outline": the plinth's plan, "band": the
## plan grown by its retaining wall, "datum": its floor, "sink": optional,
## the depth of the deepest pit dug into its plinth}]: within the band the
## ground lies no higher than just under the floor (inside the plinth or the
## wall, out of sight; on the downhill side it is untouched), and the
## collider leaves out every cell touching the plinth itself, so the
## foundation is the only floor there.
static func build(parent: Node3D, sockets: Array, wall: Callable = Callable(FireCalderaGround, "crater_wall")) -> StaticBody3D:
	var columns := int(MESH_EXTENT * 2.0 / CELL) + 1
	var vertices := PackedVector3Array()
	var inside := PackedByteArray()
	vertices.resize(columns * columns)
	inside.resize(columns * columns)
	for row in columns:
		for column in columns:
			var p := Vector2(-MESH_EXTENT + float(column) * CELL, -MESH_EXTENT + float(row) * CELL)
			var y := blended_height(p, wall)
			var socketed := 0
			for socket: Dictionary in sockets:
				if Geometry2D.is_point_in_polygon(p, socket["band"]):
					y = minf(y, float(socket["datum"]) - 0.05)
					if Geometry2D.is_point_in_polygon(p, socket["outline"]):
						socketed = 1
						# Under a plinth with a pit dug in it, the hidden skin
						# drops below the pit's floor.
						y = minf(y, float(socket["datum"]) - 0.1 - float(socket.get("sink", 0.0)))
					break
			vertices[row * columns + column] = Vector3(p.x, y, p.y)
			inside[row * columns + column] = socketed
	var indices := PackedInt32Array()
	var faces := PackedVector3Array()
	for row in columns - 1:
		for column in columns - 1:
			var a := row * columns + column
			var b := a + 1
			var c := a + columns
			var d := c + 1
			# Clockwise seen from above: Godot's front face.
			for tri: Array in [[a, b, c], [b, d, c]]:
				indices.append_array(PackedInt32Array(tri))
				if inside[tri[0]] + inside[tri[1]] + inside[tri[2]] == 0:
					for k in tri:
						faces.append(vertices[k])
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	for i in range(0, indices.size(), 3):
		var n := (vertices[indices[i + 1]] - vertices[indices[i]]).cross(vertices[indices[i + 2]] - vertices[indices[i]])
		for k in 3:
			normals[indices[i + k]] += n
	var colors := PackedColorArray()
	colors.resize(vertices.size())
	for i in vertices.size():
		# A heightfield's normals all point up, whichever way its triangles wind.
		var n := normals[i] if normals[i].y >= 0.0 else -normals[i]
		normals[i] = n.normalized() if n.length() > 0.0 else Vector3.UP
		colors[i] = _colour(vertices[i], normals[i])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var body := StaticBody3D.new()
	body.name = "CalderaGround"
	body.collision_layer = 1
	body.collision_mask = 0
	parent.add_child(body)
	var instance := MeshInstance3D.new()
	instance.name = "GroundMesh"
	instance.mesh = mesh
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.95
	# Seen from above and from inside the basin's banks alike.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	instance.material_override = material
	# The coarse triangles that straddle the patch boundary remain underneath
	# so there can be no hole. Lift only the visible fine skin by one centimetre
	# to prevent coplanar depth flicker; collision and height queries stay exact.
	instance.position.y = 0.01
	body.add_child(instance)
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	instance.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	collider.set_meta(CollisionPolicy.POLICY_META, CollisionPolicy.SOLID)
	return body


static func _colour(vertex: Vector3, normal: Vector3) -> Color:
	if vertex.y < LAVA_Y + 1.2:
		# The bank near the lava: dark, then heat-stained at the surface.
		return BANK.lerp(HEAT, clampf(1.0 - absf(vertex.y - LAVA_Y) / 1.2, 0.0, 1.0) * 0.7)
	var steep := 1.0 - clampf(normal.y, 0.0, 1.0)
	return TERRACE.lerp(BASALT, clampf(steep * 3.0, 0.0, 1.0))


## The reservoir's lava: one surface over the bank's outline grown a little,
## so its edge runs under the bank rather than meeting it at a seam.
static func build_lava(parent: Node3D) -> MeshInstance3D:
	var outline := FireCalderaPlan.reservoir_polygon(128)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var middle := Vector3(0.0, LAVA_Y, 0.0)
	for i in outline.size():
		var a := outline[i] * (1.0 + 1.5 / outline[i].length())
		var b := outline[(i + 1) % outline.size()] * (1.0 + 1.5 / outline[(i + 1) % outline.size()].length())
		for v in [middle, Vector3(b.x, LAVA_Y, b.y), Vector3(a.x, LAVA_Y, a.y)]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	st.set_material(NatureProps.build_lava_material())
	var lava := MeshInstance3D.new()
	lava.name = "ReservoirLava"
	lava.mesh = st.commit()
	parent.add_child(lava)
	CollisionPolicy.mark_decorative(lava)
	var light := OmniLight3D.new()
	light.position = Vector3(0.0, LAVA_Y + 3.0, 0.0)
	light.light_color = Color(1.0, 0.42, 0.12)
	light.light_energy = 2.0
	light.omni_range = 60.0
	lava.add_child(light)
	return lava
