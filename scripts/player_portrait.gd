class_name PlayerPortrait
extends RefCounted

## An isolated, always-suited paper doll for InventoryUI. It owns a second
## procedural figure and world, so previewing assignments never mutates the
## player, their pose, or the suit currently worn in the game world.

const RESOLUTION := 768
const PICK_LAYER := 1
const PICK_WIDTH := 0.16

var _viewport: SubViewport
var _camera: Camera3D
var _root: Node3D
var _pivots: Dictionary
var _preview_pieces_by_slot: Dictionary = {}
var _preview_blorbs_by_slot: Dictionary = {}
var _assignments: Dictionary = {}
var _highlighted_slot: String = "head"
var _body_focus_active: bool = false
var _selected_blorb: Blorb = null
var _focused_blorb: Blorb = null
var _dim_overlay: StandardMaterial3D
var _selected_overlay: StandardMaterial3D
var _reference_overlay: StandardMaterial3D


func setup(player: Node3D, _live_visuals: Node3D) -> void:
	_viewport = SubViewport.new()
	_viewport.name = "BlorbPaperDollViewport"
	_viewport.size = Vector2i(RESOLUTION, RESOLUTION)
	_viewport.transparent_bg = true
	# Give the portrait a concrete world resource immediately. Relying only on
	# own_world_3d can leave world_3d null during a viewport lifecycle boundary
	# (notably an early click just after opening the inventory).
	_viewport.world_3d = World3D.new()
	_viewport.msaa_3d = Viewport.MSAA_4X
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	player.add_child(_viewport)

	_root = Node3D.new()
	_root.name = "PaperDollFigure"
	_viewport.add_child(_root)
	_pivots = Player.build_portrait_body(_root)
	_build_dim_overlay()
	_build_selected_overlay()
	_build_reference_overlay()
	_apply_paper_doll_pose()
	_build_hit_areas()
	_build_lighting()
	_build_camera()
	_apply_highlight()


func _build_dim_overlay() -> void:
	_dim_overlay = StandardMaterial3D.new()
	_dim_overlay.albedo_color = Color(0.16, 0.09, 0.18, 0.86)
	_dim_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dim_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_dim_overlay.cull_mode = BaseMaterial3D.CULL_DISABLED


func _build_selected_overlay() -> void:
	_selected_overlay = StandardMaterial3D.new()
	_selected_overlay.albedo_color = Color(0.95, 0.43, 0.62, 0.34)
	_selected_overlay.emission_enabled = true
	_selected_overlay.emission = Color(0.85, 0.22, 0.48)
	_selected_overlay.emission_energy_multiplier = 0.7
	_selected_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_selected_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selected_overlay.cull_mode = BaseMaterial3D.CULL_DISABLED


func _build_reference_overlay() -> void:
	_reference_overlay = StandardMaterial3D.new()
	_reference_overlay.albedo_color = Color(0.95, 0.52, 0.68, 0.16)
	_reference_overlay.emission_enabled = true
	_reference_overlay.emission = Color(0.82, 0.30, 0.50)
	_reference_overlay.emission_energy_multiplier = 0.28
	_reference_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_reference_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_reference_overlay.cull_mode = BaseMaterial3D.CULL_DISABLED


func _apply_paper_doll_pose() -> void:
	(_pivots["arm_left"] as Node3D).rotation.z = ProceduralFigure.ARM_OUTWARD_ANGLE
	(_pivots["arm_right"] as Node3D).rotation.z = -ProceduralFigure.ARM_OUTWARD_ANGLE
	for key in ["elbow_left", "elbow_right", "leg_left", "leg_right", "knee_left", "knee_right"]:
		(_pivots[key] as Node3D).rotation = Vector3.ZERO


func _build_lighting() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -30, 0)
	key.light_energy = 1.25
	key.shadow_enabled = true
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 145, 0)
	fill.light_color = Color(0.72, 0.82, 1.0)
	fill.light_energy = 0.55
	_viewport.add_child(fill)


func _build_camera() -> void:
	var bounds := _world_aabb(_root)
	var center := bounds.get_center()
	var half_fov_tan := tan(deg_to_rad(32.5))
	var distance := maxf(bounds.size.y, bounds.size.x) * 0.58 / half_fov_tan
	_camera = Camera3D.new()
	_camera.fov = 65.0
	_camera.position = center + Vector3(0, 0.03, maxf(distance, 2.0))
	# look_at() hard-requires is_inside_tree() (it resolves the target via
	# get_global_transform()) -- _camera isn't parented yet at this point
	# (_viewport.add_child(_camera) is still below), so it fails with "Node
	# not inside tree" the moment this runs (confirmed in-engine). Same fix
	# as nature_props.gd's own durian spikes: look_at_from_position() sets
	# the transform directly instead of resolving through the tree.
	_camera.look_at_from_position(_camera.position, center + Vector3(0, 0.02, 0), Vector3.UP)
	_camera.current = true
	_viewport.add_child(_camera)


func _build_hit_areas() -> void:
	_add_box_area("head", _pivots["head"], Vector3(0, ProceduralFigure.HEAD_SIZE.y, 0), ProceduralFigure.HEAD_SIZE * 2.35)
	_add_box_area("torso", _pivots["spine"], Vector3(0, 0.25, 0), Vector3(0.48, 0.62, 0.34))
	_add_limb_area("arm_left", _pivots["arm_left"], _pivots["fingertip_left"])
	_add_limb_area("arm_right", _pivots["arm_right"], _pivots["fingertip_right"])
	_add_limb_area("leg_left", _pivots["leg_left"], _pivots["toe_left"], 0.20)
	_add_limb_area("leg_right", _pivots["leg_right"], _pivots["toe_right"], 0.20)


func _add_box_area(slot: String, parent: Node3D, local_position: Vector3, size: Vector3) -> void:
	var area := Area3D.new()
	area.name = "Pick_%s" % slot
	area.set_meta("slot", slot)
	area.collision_layer = PICK_LAYER
	area.collision_mask = 0
	parent.add_child(area)
	area.position = local_position
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)


func _add_limb_area(slot: String, start_node: Node3D, end_node: Node3D, width: float = PICK_WIDTH) -> void:
	var start := _root.to_local(start_node.global_position)
	var finish := _root.to_local(end_node.global_position)
	var direction := finish - start
	var area := Area3D.new()
	area.name = "Pick_%s" % slot
	area.set_meta("slot", slot)
	area.collision_layer = PICK_LAYER
	area.collision_mask = 0
	_root.add_child(area)
	area.position = (start + finish) * 0.5
	var forward := direction.normalized()
	var up := Vector3.FORWARD if absf(forward.dot(Vector3.UP)) > 0.95 else Vector3.UP
	area.basis = Basis.looking_at(forward, up)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, width, direction.length() + width * 0.5)
	collision.shape = shape
	area.add_child(collision)


## Rebuilds the preview from assignment data only. Actual Blorb nodes are
## safe visual profiles: generated pieces are parented to this figure.
func refresh(assignments: Dictionary) -> void:
	_assignments = assignments.duplicate()
	_rebuild_preview()


func _rebuild_preview() -> void:
	for old_slot in _preview_pieces_by_slot:
		for piece in (_preview_pieces_by_slot[old_slot] as Array):
			if is_instance_valid(piece):
				(piece as Node3D).free()
	_preview_pieces_by_slot.clear()
	_preview_blorbs_by_slot.clear()
	var selected_is_assigned := false
	if _selected_blorb != null and is_instance_valid(_selected_blorb):
		for assigned_slot in _assignments:
			if _assignments[assigned_slot] == _selected_blorb:
				selected_is_assigned = true
				break
	for slot in BlorbSuit.SLOT_ORDER:
		var blorb := _assignments.get(slot) as Blorb
		# An unassigned selected Blorb previews on the current target, replacing
		# that slot's existing preview only—not its real assignment—until X is
		# pressed. The psychic tint below distinguishes this preview from both
		# an assigned piece and the bright target limb.
		if not selected_is_assigned and slot == _highlighted_slot and _selected_blorb != null:
			blorb = _selected_blorb
		if blorb == null or not is_instance_valid(blorb):
			continue
		var pieces := BlorbSuit.equip_slot(slot, _preview_pivots(), _root, blorb)
		_preview_pieces_by_slot[slot] = pieces
		_preview_blorbs_by_slot[slot] = blorb
	_apply_highlight()


func set_highlighted_slot(slot: String) -> void:
	if not (slot in BlorbSuit.SLOT_ORDER):
		return
	_highlighted_slot = slot
	if _selected_blorb != null and not _assignments.values().has(_selected_blorb):
		_rebuild_preview()
	else:
		_apply_highlight()


func set_selected_blorb(blorb: Blorb) -> void:
	_selected_blorb = blorb if blorb == null or is_instance_valid(blorb) else null
	_rebuild_preview()


func set_focused_blorb(blorb: Blorb) -> void:
	_focused_blorb = blorb if blorb == null or is_instance_valid(blorb) else null
	_apply_highlight()


func set_body_focus_active(active: bool) -> void:
	_body_focus_active = active
	_apply_highlight()


## Darkens the entire alternate figure, then restores the selected body
## region and its assigned suit piece to full light. This is geometry-based
## feedback: the highlight follows the actual limb meshes and remains valid
## if framing, pose, or suit geometry changes.
func _apply_highlight() -> void:
	if _root == null or _dim_overlay == null:
		return
	for mesh in _mesh_descendants(_root):
		_dim_mesh(mesh)
	# Reset every generated suit light first. Enabling/disabling only while
	# visiting the currently rebuilt piece arrays allowed a previous target's
	# light to survive some focus transitions and keep that old piece bright.
	for light in _root.find_children("*", "Light3D", true, false):
		(light as Light3D).visible = false

	if _body_focus_active:
		for mesh in _base_meshes_for_slot(_highlighted_slot):
			_restore_mesh(mesh)

	for slot in _preview_pieces_by_slot:
		var target_slot := _body_focus_active and (slot as String) == _highlighted_slot
		var selected_piece: bool = _preview_blorbs_by_slot.get(slot) == _selected_blorb and _selected_blorb != null
		var referenced_piece: bool = _preview_blorbs_by_slot.get(slot) == _focused_blorb and _focused_blorb != null
		for piece in (_preview_pieces_by_slot[slot] as Array):
			var piece_node := piece as Node3D
			if not is_instance_valid(piece_node):
				continue
			if target_slot or selected_piece or referenced_piece:
				for mesh in _mesh_descendants(piece_node):
					var overlay: Material = _selected_overlay if selected_piece else (_reference_overlay if referenced_piece else null)
					_restore_mesh(mesh, overlay)
			if target_slot or selected_piece or referenced_piece:
				for light in piece_node.find_children("*", "Light3D", true, false):
					(light as Light3D).visible = true


func _dim_mesh(mesh: MeshInstance3D) -> void:
	# material_overlay is additive: an elemental material's own emission still
	# shines through a translucent dark overlay. Capture the authored override
	# once on the mesh itself, then temporarily REPLACE it for true dimming.
	if not mesh.has_meta("portrait_material_captured"):
		mesh.set_meta("portrait_material_captured", true)
		if mesh.material_override != null:
			mesh.set_meta("portrait_original_material", mesh.material_override)
		var source: Material = mesh.material_override
		if source == null and mesh.mesh != null and mesh.mesh.get_surface_count() > 0:
			source = mesh.get_active_material(0)
		if source is StandardMaterial3D:
			var dimmed := (source as StandardMaterial3D).duplicate() as StandardMaterial3D
			# Preserve the element's hue and surface identity, but lower value and
			# suppress self-emission so it reads as assigned—not currently active.
			# Keep enough hue to understand every assignment at a glance, while
			# creating a stronger separation from the currently referenced piece.
			dimmed.albedo_color = dimmed.albedo_color.darkened(0.62)
			dimmed.emission_enabled = false
			mesh.set_meta("portrait_dim_material", dimmed)
	var dim_material := mesh.get_meta("portrait_dim_material", _dim_overlay) as Material
	mesh.material_override = dim_material
	mesh.material_overlay = null


func _restore_mesh(mesh: MeshInstance3D, overlay: Material = null) -> void:
	# get_meta()'s default-value param can't be null to mean "absent" -- Godot
	# treats an explicit null the same as no default at all and still errors
	# on a missing key (see object.cpp) -- so a mesh that was never dimmed
	# (never had material_override set, see _dim_mesh() above) needs an
	# explicit has_meta() check instead.
	mesh.material_override = mesh.get_meta("portrait_original_material") as Material if mesh.has_meta("portrait_original_material") else null
	mesh.material_overlay = overlay


func _base_meshes_for_slot(slot: String) -> Array[MeshInstance3D]:
	match slot:
		"head":
			return _mesh_descendants(_pivots["head"] as Node)
		"arm_left":
			return _mesh_descendants(_pivots["arm_left"] as Node)
		"arm_right":
			return _mesh_descendants(_pivots["arm_right"] as Node)
		"leg_left":
			return _mesh_descendants(_pivots["leg_left"] as Node)
		"leg_right":
			return _mesh_descendants(_pivots["leg_right"] as Node)
		"torso":
			var result: Array[MeshInstance3D] = []
			var excluded_roots: Array[Node] = [
				_pivots["head"] as Node,
				_pivots["arm_left"] as Node,
				_pivots["arm_right"] as Node,
				_pivots["leg_left"] as Node,
				_pivots["leg_right"] as Node,
			]
			for mesh in _mesh_descendants(_pivots["spine"] as Node):
				var excluded := false
				for excluded_root in excluded_roots:
					if excluded_root.is_ancestor_of(mesh):
						excluded = true
						break
				if not excluded:
					result.append(mesh)
			return result
	return []


static func _mesh_descendants(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		meshes.append(node as MeshInstance3D)
	for child in node.find_children("*", "MeshInstance3D", true, false):
		meshes.append(child as MeshInstance3D)
	return meshes


func _preview_pivots() -> Dictionary:
	return {
		"arm_left_shoulder": _pivots["arm_left"], "arm_left_elbow": _pivots["elbow_left"],
		"arm_right_shoulder": _pivots["arm_right"], "arm_right_elbow": _pivots["elbow_right"],
		"leg_left_hip": _pivots["leg_left"], "leg_left_knee": _pivots["knee_left"], "leg_left_ankle": _pivots["ankle_left"],
		"leg_right_hip": _pivots["leg_right"], "leg_right_knee": _pivots["knee_right"], "leg_right_ankle": _pivots["ankle_right"],
		"spine": _pivots["spine"], "head": _pivots["head"],
		"back_left": _pivots["back_left"], "back_right": _pivots["back_right"],
		"wrist_left": _pivots["wrist_left"], "wrist_right": _pivots["wrist_right"],
		"fingertip_left": _pivots["fingertip_left"], "fingertip_right": _pivots["fingertip_right"],
		"toe_left": _pivots["toe_left"], "toe_right": _pivots["toe_right"],
	}


func pick_slot(viewport_position: Vector2) -> String:
	if _camera == null or _viewport == null or not is_instance_valid(_viewport):
		return ""
	var portrait_world := _viewport.world_3d
	if portrait_world == null:
		return ""
	var origin := _camera.project_ray_origin(viewport_position)
	var direction := _camera.project_ray_normal(viewport_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 20.0, PICK_LAYER)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hit := portrait_world.direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	var collider := hit.get("collider") as Area3D
	return str(collider.get_meta("slot", "")) if collider != null else ""


func set_active(active: bool) -> void:
	if _viewport != null:
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED


## Kept for Player's existing per-frame call; the isolated doll is static.
func update() -> void:
	pass


## Legacy live-portrait callers may still tag world meshes. Isolation no
## longer uses render layers, so this intentionally does nothing.
static func tag_for_portrait(_visual: VisualInstance3D) -> void:
	pass


func get_texture() -> Texture2D:
	return _viewport.get_texture() if _viewport != null else null


static func _world_aabb(node: Node) -> AABB:
	var result := AABB()
	var has_any := false
	for descendant in node.find_children("*", "MeshInstance3D", true, false):
		var mesh := descendant as MeshInstance3D
		var box := mesh.global_transform * mesh.get_aabb()
		result = result.merge(box) if has_any else box
		has_any = true
	return result
