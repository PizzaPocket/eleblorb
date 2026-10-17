class_name FireCalderaGround
extends RefCounted

## The caldera city's own ground (fire_caldera_layout.md, sections 1 and 1a):
## two nested paraboloids: a shallow inhabited volcanic bowl from its central
## vertex to the true crater lip, and a second, deeper bowl inside the reservoir
## boundary. One height function, in the plan's local frame, is the source for
## the ground mesh, collision, lava extent and plot survey, so they cannot
## disagree.
##
## Heights are world Y. In the live kingdom this replaces the coarse flat
## crater floor inside the city and blends back to the original crater wall.

## The outer parabola reaches the existing volcanic lip exactly.
const BOWL_LIP_Y := 48.0
## The lava surface sits below even the shallowest point of its parabolic rim.
const LAVA_Y := 29.2
## Nominal bank height at the reservoir's mean radius; individual bearings
## vary slightly because the lava outline is intentionally organic.
const LIP_Y := 30.0
## The natural bed beneath the Heartworks collection pool. The public pool is
## at 58.8 m depth; leave geological clearance below its walkable gallery.
const BED_DEPTH := 92.0
## Where the city's ground gives way to the crater wall.
## The authored parabola owns almost the whole bowl; only its final apron
## reconciles to the coarse terrain samples at the same crater lip.
const WALL_BLEND := Vector2(92.0, 98.0)

const EMBED := 1.5
## Foundation type by the ground's change across the reserved plot.
const SOCKET_MAX := 1.5
const PODIUM_MAX := 4.0
const EXPOSED_MAX := 3.0


## The natural inhabited bowl is the outer half of a parabola whose vertex is
## the lava-mouth shoulder. The central lava basin supplies the second
## parabola inside that shoulder. This puts homes on the gentle beginning of
## the curve while the uninterrupted outer wall steepens toward the true lip.
static func outer_bowl_height(local: Vector2) -> float:
	var run := FireCalderaPlan.RIM_RADIUS - FireCalderaPlan.FLOOR_RADIUS
	var normalized_radius := clampf((local.length() - FireCalderaPlan.FLOOR_RADIUS) / run, 0.0, 1.0)
	return FireCalderaPlan.FLOOR_Y + (BOWL_LIP_Y - FireCalderaPlan.FLOOR_Y) * normalized_radius * normalized_radius


## Ground height at a local plan point, before blending into the crater wall.
## Inside the organic reservoir outline, a second parabola meets the outer
## bowl at the bank and falls to the common central bed. Outside it, the ground
## is the uninterrupted outer parabola—there are no flat terrace bands.
static func height(local: Vector2) -> float:
	var r := local.length()
	var angle := local.angle()
	var bank := FireCalderaPlan.reservoir_radius(angle)
	if r >= bank:
		return outer_bowl_height(local)
	var bank_point := Vector2(cos(angle), sin(angle)) * bank
	var edge_height := outer_bowl_height(bank_point)
	var t := r / bank
	return (LAVA_Y - BED_DEPTH) + (edge_height - (LAVA_Y - BED_DEPTH)) * t * t


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
	# At the outer edge the fine bowl must become the coarse volcano exactly.
	# Keeping the higher of the two left a visible/collidable shelf wherever
	# the new shallow bowl happened to sit above the old wall sample.
	return lerpf(own, wall_height, t)


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
	var datum: float = FireCalderaPlan.HIGHLINE_DATUM if str(entry.get("site", "ground")) == "highline" else samples["front landing"]
	if entry.has("datum"):
		datum = float(entry["datum"])
	# A terrace that stands out over the reservoir takes its floor from the
	# route that crosses it (a point in its own frame), not from the lava.
	if entry.has("datum_at"):
		datum = height(FireCalderaPlan.shell_to_plan(entry, entry["datum_at"]))
	var change := high - low
	var kind := "raised service platform" if FireCalderaPlan.is_elevated(entry) else ("socket plinth" if change <= SOCKET_MAX else ("stepped podium" if change <= PODIUM_MAX else "bedrock spine"))
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
## The fine bowl owns every raised foundation and its clearance socket.  Its
## visible seam therefore sits beyond the outermost Civic/inn platform, not
## through them; the hidden apron still overlaps more than one coarse cell.
const EXTENT := 120.0
## A hidden overlap apron wider than one coarse terrain cell. Coarse triangles
## are cut at EXTENT - 2, while this identical wall-blended skin continues far
## enough beneath them that no clipped corner can expose sky.
const MESH_EXTENT := 128.0
const CELL := 0.5
## One material and one albedo for the kingdom's terrain, including the coarse
## world mesh and the fine city ground. Fresh basalt reads charcoal-black;
## heat belongs to lava and lighting, not to a second brown ground palette.
const ROCK_COLOR := Color(0.072, 0.074, 0.080)
static var _shared_terrain_material: StandardMaterial3D


static func terrain_material() -> StandardMaterial3D:
	if _shared_terrain_material == null:
		_shared_terrain_material = StandardMaterial3D.new()
		_shared_terrain_material.albedo_color = ROCK_COLOR
		_shared_terrain_material.roughness = 0.96
		_shared_terrain_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Vertex colour is deliberately disabled: both terrain meshes receive
		# this exact material object, with no patch-specific tint underneath it.
		_shared_terrain_material.vertex_color_use_as_albedo = false
	return _shared_terrain_material


## The crater wall as the kingdom's terrain draws it (floor to rim), for the
## blend at the floor's edge when the proof scene has no terrain.
static func crater_wall(local: Vector2) -> float:
	var r := local.length()
	if r <= FireCalderaPlan.RIM_RADIUS:
		return outer_bowl_height(local)
	return BOWL_LIP_Y


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
					var elevated := bool(socket.get("elevated", false))
					y = minf(y, float(socket["datum"]) - (2.6 if elevated else float(socket.get("landing_clearance", 0.05))))
					if Geometry2D.is_point_in_polygon(p, socket["outline"]):
						socketed = 0 if elevated else 1
						# Under a plinth with a pit dug in it, the hidden skin
						# drops below the pit's floor.
						if not elevated:
							y = minf(y, float(socket["datum"]) - 0.1 - float(socket.get("sink", 0.0)))
					# A ground foundation has priority where a raised district
					# overlaps it in plan.  The elevated clearance may lower the
					# bowl, but may never prevent the ground socket from cutting its
					# actual floor and doorway landings.
					if not elevated:
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
	# Exactly the same resource used by the kingdom's coarse terrain mesh.
	instance.material_override = terrain_material()
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


# The former standalone arrival arch was superseded by the generated Gate Terrace.

static func _colour(vertex: Vector3, normal: Vector3) -> Color:
	# Kept as the vertex-array source for mesh compatibility and terrain tools;
	# the shared material intentionally ignores vertex tint.
	return ROCK_COLOR


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
