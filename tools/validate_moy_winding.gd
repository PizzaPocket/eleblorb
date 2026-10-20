extends Node

const BUILDER := preload("res://scripts/moy_city_bake_builder.gd")

var failures := 0

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var fixtures := {
		"rect_ccw": [[0.0, 0.0], [8.0, 0.0], [8.0, 6.0], [0.0, 6.0]],
		"rect_cw": [[0.0, 6.0], [8.0, 6.0], [8.0, 0.0], [0.0, 0.0]],
		"concave_ccw": [[0.0, 0.0], [8.0, 0.0], [8.0, 2.0], [3.0, 2.0], [3.0, 7.0], [0.0, 7.0]],
		"concave_cw": [[0.0, 7.0], [3.0, 7.0], [3.0, 2.0], [8.0, 2.0], [8.0, 0.0], [0.0, 0.0]],
	}
	for label in fixtures:
		_check_building(label, fixtures[label])
		_check_floor(label, fixtures[label])
	_check_baked_houses()
	print("MOY_WINDING failures=", failures)
	get_tree().quit(1 if failures > 0 else 0)

func _check_building(label: String, ring: Array) -> void:
	var body := BUILDER._polygon_building("WindingFixture_%s" % label, ring, 4.0, Color.WHITE)
	var mesh := body.get_node("PolygonBuildingMesh").mesh as ArrayMesh
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var expected_walls := 0
	var roof_count := 0
	var floor_count := 0
	for i in range(0, vertices.size(), 3):
		var a := vertices[i]
		var b := vertices[i + 1]
		var c := vertices[i + 2]
		var front := (c - a).cross(b - a).normalized()
		var avg_y := (a.y + b.y + c.y) / 3.0
		if absf(avg_y - 4.0) < 0.0001:
			roof_count += 1
			_expect(front.y > 0.999, "%s roof triangle %d faces %s" % [label, i / 3, front])
		elif absf(avg_y) < 0.0001:
			floor_count += 1
			_expect(front.y < -0.999, "%s bottom triangle %d faces %s" % [label, i / 3, front])
		else:
			expected_walls += 1
			var midpoint := (a + b + c) / 3.0
			var expected := _nearest_edge_outward(midpoint, ring)
			_expect(front.dot(expected) > 0.999, "%s wall triangle %d faces %s, expected %s" % [label, i / 3, front, expected])
	_expect(roof_count > 0, "%s has upward roof faces" % label)
	_expect(floor_count > 0, "%s has downward bottom faces" % label)
	_expect(expected_walls > 0, "%s has exterior wall faces" % label)
	_expect(body.get_node("PolygonBuildingCollision").shape is ConcavePolygonShape3D, "%s collision comes from corrected mesh" % label)
	print("MOY_WINDING fixture_building=", label, " roof=", roof_count, " bottom=", floor_count, " walls=", expected_walls)
	body.free()

func _check_floor(label: String, ring: Array) -> void:
	var body := BUILDER._poly_floor("WindingFloor_%s" % label, ring, 0.0, Color.WHITE)
	var mesh := body.get_node("PolygonFloorMesh").mesh as ArrayMesh
	var vertices: PackedVector3Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_expect(vertices.size() >= 3, "%s floor has triangles" % label)
	for i in range(0, vertices.size(), 3):
		var front := (vertices[i + 2] - vertices[i]).cross(vertices[i + 1] - vertices[i]).normalized()
		_expect(front.y > 0.999, "%s floor triangle %d faces %s" % [label, i / 3, front])
	_expect(body.get_node("PolygonFloorCollision").shape is ConcavePolygonShape3D, "%s floor collision comes from upward mesh" % label)
	print("MOY_WINDING fixture_floor=", label, " triangles=", vertices.size() / 3)
	body.free()

func _nearest_edge_outward(point: Vector3, ring: Array) -> Vector3:
	var points := PackedVector2Array()
	for vertex in ring: points.append(Vector2(float(vertex[0]), float(vertex[1])))
	var area_twice := 0.0
	for i in points.size(): area_twice += points[i].x * points[(i + 1) % points.size()].y - points[(i + 1) % points.size()].x * points[i].y
	if area_twice < 0.0: points.reverse()
	var best_distance := INF
	var best := Vector3.ZERO
	var centre := Vector2.ZERO
	for vertex in points: centre += vertex
	centre /= float(points.size())
	for i in points.size():
		var a := points[i] - centre
		var b := points[(i + 1) % points.size()] - centre
		var edge := b - a
		var t := clampf((Vector2(point.x, point.z) - a).dot(edge) / edge.length_squared(), 0.0, 1.0)
		var closest := a + edge * t
		var distance := Vector2(point.x, point.z).distance_to(closest)
		if distance < best_distance:
			best_distance = distance
			# _normalise_polygon_ring emits positive-area XZ rings.
			best = Vector3(edge.y, 0.0, -edge.x).normalized()
	return best

func _check_baked_houses() -> void:
	var packs := BUILDER.build_packs()
	var found := 0
	var kits := {"tower": 0, "infill": 0}
	for key in packs:
		var root := packs[key] as Node
		for body in _walk(root):
			if not (body is StaticBody3D) or not bool(body.get_meta("moy_p4_house", false)): continue
			var collision := body.get_node_or_null("PolygonBuildingCollision") as CollisionShape3D
			if collision == null or not (collision.shape is ConcavePolygonShape3D): continue
			var faces := (collision.shape as ConcavePolygonShape3D).get_faces()
			if faces.is_empty(): continue
			found += 1
			var kit := String(body.get_meta("moy_p4_kit", "tower"))
			kits[kit] = int(kits.get(kit, 0)) + 1
			_check_faces_outward(String(body.name), faces, body.get_meta("polygon_points", []), float(body.get_meta("polygon_height", 0.0)))
			if found >= 12: break
		if found >= 12: break
	print("MOY_WINDING baked_representatives=", found, " kinds=", kits)
	_expect(found >= 8, "at least eight representative final P4 collision meshes were audited")
	_expect(int(kits.get("tower", 0)) > 0 and int(kits.get("infill", 0)) > 0, "both tower and infill collision meshes were audited")
	for root in packs.values(): (root as Node).free()

func _check_faces_outward(label: String, vertices: PackedVector3Array, ring: Array, top_y: float) -> void:
	for i in range(0, vertices.size(), 3):
		var a := vertices[i]
		var b := vertices[i + 1]
		var c := vertices[i + 2]
		var front := (c - a).cross(b - a).normalized()
		if front.length_squared() < 0.5: continue
		var avg_y := (a.y + b.y + c.y) / 3.0
		if absf(avg_y - top_y) < 0.0001:
			_expect(front.y > 0.999, "%s roof triangle %d faces %s" % [label, i / 3, front])
		elif absf(avg_y) < 0.0001:
			_expect(front.y < -0.999, "%s bottom triangle %d faces %s" % [label, i / 3, front])
		else:
			var midpoint := (a + b + c) / 3.0
			var expected := _nearest_edge_outward(midpoint, ring)
			_expect(front.dot(expected) > 0.999, "%s wall triangle %d faces %s, expected %s" % [label, i / 3, front, expected])

func _walk(root: Node) -> Array[Node]:
	var result: Array[Node] = [root]
	for child in root.get_children(): result.append_array(_walk(child))
	return result

func _expect(ok: bool, message: String) -> void:
	if ok: return
	failures += 1
	push_error("MOY_WINDING: " + message)
