class_name CSGProofGallery
extends Node3D

## TEMPORARY constructive-solid-geometry proof beside the demo spaceship.
##
## Unlike SuperEgg.build_hollow_shell_mesh(), none of these openings knows
## anything about the surface grid it cuts.  Every specimen begins as one or
## more closed volumes and lets Godot evaluate union/difference between those
## solids.  This is deliberately isolated from production geometry until its
## silhouettes, cut faces, collision and stability have been judged in-game.

const SHELL := Color(0.78, 0.84, 0.94)
const SHELL_ALT := Color(0.48, 0.68, 0.88)
const CUT_FACE := Color(0.17, 0.25, 0.38)
const CORRIDOR := Color(0.78, 0.62, 0.32)
const GLASS := Color(0.34, 0.72, 0.96, 0.34)

const WALL := 0.42
const SPACING := 13.0
const BODY_AXES := Vector3(4.2, 4.8, 3.5)
const PROFILE_SEGMENTS := 144
## Across a real Boolean rim the exterior and cut wall must not share a normal.
## Everywhere gentler than this, adjacent result triangles belong to one
## continuous curved face and are averaged back together after CSG triangulates
## them.
const NORMAL_CREASE_DEGREES := 32.0
## The production body builder deliberately uses a modest 18x24 grid. That is
## enough for small characters, but its large triangles make any Boolean split
## look as though the cut has pulled the surrounding shell out of shape. This
## proof gives CSG a genuinely smooth source surface before judging its cut.
const BODY_RINGS := 56
const BODY_SEGMENTS := 72

var _specimens: Array[CSGCombiner3D] = []


func _ready() -> void:
	_add_inspection_lighting()
	# From left to right when approaching from the ship: the smallest possible
	# hollowing test, a partial recess, a through-door, nearby windows, and the
	# joined-body/hallway case the eventual ship tooling must support.
	_add_hollow_shell(Vector3(0.0, 0.0, -SPACING * 2.0))
	_add_recess(Vector3(0.0, 0.0, -SPACING))
	_add_doorway(Vector3.ZERO)
	_add_window_bank(Vector3(0.0, 0.0, SPACING))
	_add_joined_hulls(Vector3(0.0, 0.0, SPACING * 2.25))
	_add_inset_sphere_chamber(Vector3(0.0, 0.0, SPACING * 3.4))
	# CSG evaluates after entering the tree. Bake on the following frame so the
	# diagnostic visual can reconstruct normals from the finished Boolean mesh.
	call_deferred("_bake_inspection_visuals")


func _add_inspection_lighting() -> void:
	# Space has intentionally little ambient light. A neutral key reveals the
	# exterior silhouettes; small non-shadowed lamps within each specimen make
	# the inner wall and cut rim readable without turning the gallery into a
	# costly bank of shadow maps.
	var key := DirectionalLight3D.new()
	key.name = "InspectionKey"
	key.light_color = Color(0.92, 0.96, 1.0)
	key.light_energy = 1.15
	key.rotation_degrees = Vector3(-38.0, -42.0, 0.0)
	key.shadow_enabled = true
	add_child(key)
	for index in 6:
		var lamp := OmniLight3D.new()
		lamp.name = "InteriorLamp%d" % index
		var specimen_z := (
			(-2.0 + float(index)) * SPACING
			if index < 5 else SPACING * 3.4
		)
		lamp.position = Vector3(0.8, 0.3, specimen_z)
		lamp.light_color = Color(0.68, 0.84, 1.0)
		lamp.light_energy = 2.2
		lamp.omni_range = 8.5
		lamp.shadow_enabled = false
		add_child(lamp)


func _new_combiner(name_text: String, at: Vector3) -> CSGCombiner3D:
	var result := CSGCombiner3D.new()
	result.name = name_text
	result.position = at
	result.use_collision = true
	result.collision_layer = 1
	result.collision_mask = 1
	add_child(result)
	_specimens.append(result)
	return result


func _material(color: Color, metallic: float = 0.05) -> StandardMaterial3D:
	return SolidModel.material(color, 0.38, metallic)


func _glass_material() -> StandardMaterial3D:
	var result := _material(GLASS, 0.22)
	result.roughness = 0.06
	return result


func _super_solid(
	parent: Node, name_text: String, axes: Vector3, operation: CSGShape3D.Operation,
	color: Color = SHELL, at: Vector3 = Vector3.ZERO,
	epsilon: float = SuperEgg.EPSILON_SOFT
) -> CSGMesh3D:
	return SolidModel.add_super(
		parent, name_text, axes, operation, _material(color), at, epsilon,
		BODY_RINGS, BODY_SEGMENTS
	)


func _box_solid(
	parent: Node, name_text: String, size: Vector3, operation: CSGShape3D.Operation,
	color: Color, at: Vector3 = Vector3.ZERO
) -> CSGBox3D:
	return SolidModel.add_box(parent, name_text, size, operation, _material(color), at)


func _cylinder_solid(
	parent: Node, name_text: String, radius: float, depth: float,
	operation: CSGShape3D.Operation, at: Vector3
) -> CSGMesh3D:
	# Use the same authored cutter path as every other curved profile. The
	# built-in CSG cylinder can either smooth its cap into its wall (melted rim)
	# or make the whole wall faceted; this mesh carries smooth wall normals and
	# a separate hard cap seam simultaneously.
	return SolidModel.add_profile(
		parent, name_text, depth, Vector2(radius, radius), 2.0, operation,
		_material(CUT_FACE), at, PROFILE_SEGMENTS
	)


func _profile_solid(
	parent: Node, name_text: String, depth: float, half: Vector2, exponent: float,
	operation: CSGShape3D.Operation, at: Vector3, material: Material = null
) -> CSGMesh3D:
	return SolidModel.add_profile(
		parent, name_text, depth, half, exponent, operation,
		material if material != null else _material(CUT_FACE), at, PROFILE_SEGMENTS
	)


func _add_hollow_shell(at: Vector3) -> void:
	var root := _new_combiner("Proof01_HollowShell", at)
	_super_solid(root, "Outer", BODY_AXES, CSGShape3D.OPERATION_UNION)
	_super_solid(
		root, "InnerNegative", BODY_AXES - Vector3.ONE * WALL,
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE
	)
	# A plain cylindrical inspection hole makes the inner wall visible without
	# conflating the basic hollowing test with the custom doorway profile.
	_cylinder_solid(
		root, "InspectionCut", 1.45, BODY_AXES.x * 3.0,
		CSGShape3D.OPERATION_SUBTRACTION, Vector3.ZERO
	)


func _add_recess(at: Vector3) -> void:
	var root := _new_combiner("Proof02_CylindricalRecess", at)
	_super_solid(root, "SolidBody", BODY_AXES, CSGShape3D.OPERATION_UNION, SHELL_ALT)
	# Its inner end stops inside the body: this is a recess, not a hole.
	_cylinder_solid(
		root, "RecessNegative", 1.65, 2.8,
		CSGShape3D.OPERATION_SUBTRACTION, Vector3(BODY_AXES.x - 0.75, 0.0, 0.0)
	)


func _add_doorway(at: Vector3) -> void:
	var root := _new_combiner("Proof03_ExtrudedDoorway", at)
	_super_solid(root, "Outer", BODY_AXES, CSGShape3D.OPERATION_UNION)
	_super_solid(
		root, "InnerNegative", BODY_AXES - Vector3.ONE * WALL,
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE
	)
	_profile_solid(
		root, "DoorNegative", BODY_AXES.x * 3.0, Vector2(2.25, 1.45), 3.4,
		CSGShape3D.OPERATION_SUBTRACTION, Vector3(0.0, -0.55, 0.0)
	)


func _add_window_bank(at: Vector3) -> void:
	var root := _new_combiner("Proof04_NearbyWindows", at)
	var axes := Vector3(4.2, 3.5, 6.0)
	_super_solid(root, "Outer", axes, CSGShape3D.OPERATION_UNION, SHELL_ALT)
	_super_solid(
		root, "InnerNegative", axes - Vector3.ONE * WALL,
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE
	)
	for index in 3:
		_profile_solid(
			root, "WindowNegative%d" % index, axes.x * 3.0, Vector2(0.72, 0.95), 3.2,
			CSGShape3D.OPERATION_SUBTRACTION, Vector3(0.0, 0.65, -2.35 + index * 2.35)
		)
	# Left: the exact piece of wall the cutter removed, reconstructed in glass.
	# Middle: a thin convex bubble inset just behind the hull's outside apex.
	# Right: deliberately left open, so all three treatments can be compared.
	_add_exact_window_glass(at, axes, Vector3(0.0, 0.65, -2.35))
	_add_bubble_window_glass(at, axes, Vector3(0.0, 0.65, 0.0))


func _add_exact_window_glass(at: Vector3, axes: Vector3, centre: Vector3) -> void:
	var root := _new_combiner("Proof04A_ExactWallGlass", at)
	var glass := _glass_material()
	# (Cutter intersect outer hull) minus inner hull is precisely the wall-thick
	# volume removed from this opening—no separately guessed pane curvature.
	_profile_solid(
		root, "WindowVolume", axes.x * 3.0, Vector2(0.72, 0.95), 3.2,
		CSGShape3D.OPERATION_UNION, centre, glass
	)
	var outer := _super_solid(
		root, "OuterBoundary", axes, CSGShape3D.OPERATION_INTERSECTION, GLASS
	)
	outer.material = glass
	var inner := _super_solid(
		root, "CabinNegative", axes - Vector3.ONE * WALL,
		CSGShape3D.OPERATION_SUBTRACTION, GLASS
	)
	inner.material = glass


func _add_bubble_window_glass(at: Vector3, axes: Vector3, centre: Vector3) -> void:
	var root := _new_combiner("Proof04B_InsetBubbleGlass", at)
	var glass := _glass_material()
	var bubble_radius := 2.5
	var outer_apex := axes.x - 0.12
	var sphere_centre_x := outer_apex - bubble_radius
	var sphere_centre := Vector3(sphere_centre_x, centre.y, centre.z)
	var outer := _super_solid(
		root, "BubbleOuter", Vector3.ONE * bubble_radius,
		CSGShape3D.OPERATION_UNION, GLASS, sphere_centre
	)
	outer.material = glass
	var inner := _super_solid(
		root, "BubbleInner", Vector3.ONE * (bubble_radius - 0.16),
		CSGShape3D.OPERATION_SUBTRACTION, GLASS, sphere_centre
	)
	inner.material = glass
	_profile_solid(
		root, "WindowBoundary", axes.x * 3.0, Vector2(0.72, 0.95), 3.2,
		CSGShape3D.OPERATION_INTERSECTION, centre, glass
	)
	var front_clip := _box_solid(
		root, "FrontHalfOnly", Vector3(axes.x, 3.0, 3.4),
		CSGShape3D.OPERATION_INTERSECTION, GLASS,
		Vector3(axes.x * 0.5, centre.y, centre.z)
	)
	front_clip.material = glass


func _add_joined_hulls(at: Vector3) -> void:
	var root := _new_combiner("Proof05_JoinedHullPassage", at)
	var axes := Vector3(3.55, 3.8, 3.25)
	var separation := 6.1
	_super_solid(
		root, "OuterA", axes, CSGShape3D.OPERATION_UNION, SHELL,
		Vector3(0.0, 0.0, -separation * 0.5)
	)
	_super_solid(
		root, "OuterB", axes, CSGShape3D.OPERATION_UNION, SHELL_ALT,
		Vector3(0.0, 0.0, separation * 0.5)
	)
	_box_solid(
		root, "CorridorOuter", Vector3(3.6, 3.4, separation),
		CSGShape3D.OPERATION_UNION, CORRIDOR
	)
	# Subtract the two cabins only after all exterior volumes have been united.
	_super_solid(
		root, "CabinA", axes - Vector3.ONE * WALL,
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE,
		Vector3(0.0, 0.0, -separation * 0.5)
	)
	_super_solid(
		root, "CabinB", axes - Vector3.ONE * WALL,
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE,
		Vector3(0.0, 0.0, separation * 0.5)
	)
	_box_solid(
		root, "PassageNegative", Vector3(2.75, 2.55, separation + 2.0),
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE
	)
	# An entrance on the exposed +X flank lets the entire joined interior be
	# inspected rather than leaving a sealed mathematical success.
	_profile_solid(
		root, "EntryNegative", axes.x * 3.0, Vector2(1.9, 1.15), 3.2,
		CSGShape3D.OPERATION_SUBTRACTION,
		Vector3(0.0, -0.45, -separation * 0.5)
	)


func _add_inset_sphere_chamber(at: Vector3) -> void:
	var root := _new_combiner("Proof06_InsetSphereChamber", at)
	var hull_axes := Vector3(4.35, 5.2, 3.65)
	var pod_radius := 3.15
	var overlap := 1.35
	var pod_centre := Vector3(hull_axes.x + pod_radius - overlap, 0.1, 0.0)
	_super_solid(root, "HullOuter", hull_axes, CSGShape3D.OPERATION_UNION, SHELL)
	_super_solid(
		root, "PodOuter", Vector3.ONE * pod_radius,
		CSGShape3D.OPERATION_UNION, CORRIDOR, pod_centre, 2.0
	)
	# Hollow after unioning: the two negative interiors overlap slightly, so
	# their common volume becomes an open neck between chambers with no guessed
	# doorway ring or stitched seam.
	_super_solid(
		root, "HullCabin", hull_axes - Vector3.ONE * WALL,
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE
	)
	_super_solid(
		root, "PodCabin", Vector3.ONE * (pod_radius - WALL),
		CSGShape3D.OPERATION_SUBTRACTION, CUT_FACE, pod_centre, 2.0
	)
	# A large, deliberately one-sided entrance on the main hull's -X flank.
	# Enter here, cross its cabin, then inspect the naturally opened overlap
	# into the true spherical chamber attached on +X.
	_profile_solid(
		root, "InspectionDoor", WALL * 5.0, Vector2(2.25, 1.55), 3.2,
		CSGShape3D.OPERATION_SUBTRACTION,
		Vector3(-hull_axes.x + WALL * 0.25, -0.45, -0.65)
	)


## Replaces each live CSG visual with a static inspection copy after the
## Boolean has evaluated. The invisible CSG remains solely for its generated
## collision. Godot's Boolean output carries triangulation normals that can
## make a mathematically unchanged face look dented; rebuilding them by a
## crease angle smooths continuous curved regions while retaining actual rims.
func _bake_inspection_visuals() -> void:
	for specimen in _specimens:
		SolidModel.bake_when_ready(specimen, self, NORMAL_CREASE_DEGREES)
