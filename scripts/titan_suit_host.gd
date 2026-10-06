class_name TitanSuitHost
extends Node3D

## Builds one live CSG union around a Titan's animated body and subtracts a
## bounded face opening. The Titan remains the authoritative, visible body:
## Humongous is an outer garment, never a replacement model. The union's
## members follow the existing procedural pivots, so rigs do not need to be
## converted to Skeleton3D merely to wear Humongous.

const INTERACT_MARGIN := 9.0
const SUIT_CLEARANCE := 1.045
const FACE_FORWARD_MARGIN := 0.35
const EYE_COLOR_DARKEN := 0.62

var target: Node3D
var titan_name := "Titan"
var _interaction_area: Area3D
var _interaction_registered := false
var _source: Blorb
var _suit_root: CSGCombiner3D
var _bindings: Array[Dictionary] = []
var _face_cutter: CSGMesh3D
var _face_center_local := Vector3.ZERO
var _face_forward_local := Vector3.FORWARD
var _face_up_local := Vector3.UP
var _face_half := Vector3.ONE
var _humongous_eyes: Array[MeshInstance3D] = []
var _eye_blink := EyeBlink.new_state()


func setup(host: Node3D, host_name: String) -> void:
	target = host
	titan_name = host_name
	_interaction_area = Area3D.new()
	_interaction_area.name = "TitanSuitInteraction"
	_interaction_area.collision_layer = 0
	_interaction_area.collision_mask = 0
	_interaction_area.set_meta("prompt", "Talk to %s" % titan_name)
	_interaction_area.set_meta("activate", _show_actions)
	add_child(_interaction_area)


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		_set_registered(false)
		return
	var body := PartyControl.active_control_body()
	var eligible := (
		body is Blorb
		and (body as Blorb).blorb_type == "size"
		and HumongousState.mode == HumongousState.MODE_MERGED
		and target.has_method("can_accept_titan_suit")
		and bool(target.can_accept_titan_suit())
	)
	if eligible:
		eligible = body.global_position.distance_to(target.global_position) <= _interaction_radius(body)
		var toward_source := body.global_position - target.global_position
		if toward_source.length_squared() > 0.0001:
			_interaction_area.global_position = target.global_position + toward_source.normalized() * 0.35
	_set_registered(eligible)
	if is_instance_valid(_suit_root) and _suit_root.visible:
		_sync_live_union()
		EyeBlink.apply(_eye_blink, delta, _humongous_eyes)


func _interaction_radius(humongous: Blorb) -> float:
	var host_radius := 10.0
	if target.has_method("titan_interaction_radius"):
		host_radius = float(target.titan_interaction_radius())
	return Blorb.RADIUS * humongous.size_multiplier + host_radius + INTERACT_MARGIN


func _set_registered(enabled: bool) -> void:
	if enabled == _interaction_registered:
		return
	_interaction_registered = enabled
	if enabled:
		InteractionManager.enter(_interaction_area)
	else:
		InteractionManager.exit(_interaction_area)


func _show_actions() -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var actions: Array[Dictionary] = [{
		"label": "Suit up %s" % titan_name,
		"callback": _begin_suit.bind(player),
	}]
	DialogUI.show_line(
		titan_name, "Humongous's vast living form ripples in answer.",
		actions, "Cancel", Callable(), true
	)


func _begin_suit(player: Player) -> void:
	DialogUI.hide_dialog()
	var body := PartyControl.active_control_body()
	if body is Blorb and (body as Blorb).blorb_type == "size":
		player.begin_titan_host_control(target, body as Blorb, self)


func form(source: Blorb) -> void:
	_source = source
	if not is_instance_valid(_suit_root):
		_build_continuous_shell(source.body_color)
	else:
		var material := _suit_root.material_override as StandardMaterial3D
		if material != null:
			material.albedo_color = source.body_color
			material.emission = source.body_color.lightened(0.06)
	_suit_root.visible = true
	for eye in _humongous_eyes:
		eye.visible = true
	_sync_live_union()


func release() -> void:
	if is_instance_valid(_suit_root):
		_suit_root.visible = false
	for eye in _humongous_eyes:
		if is_instance_valid(eye):
			eye.visible = false
	_source = null


func _build_continuous_shell(color: Color) -> void:
	_suit_root = CSGCombiner3D.new()
	_suit_root.name = "HumongousContinuousOnesie"
	_suit_root.use_collision = false
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = 0.26
	material.emission_enabled = true
	material.emission = color.lightened(0.06)
	material.emission_energy_multiplier = 0.08
	_suit_root.material_override = material
	target.add_child(_suit_root)

	var candidates: Array[MeshInstance3D] = []
	for child in target.find_children("*", "MeshInstance3D", true, false):
		var source_mesh := child as MeshInstance3D
		if (
			source_mesh.mesh == null or not source_mesh.visible
			or _is_face_detail(source_mesh) or _is_profile_excluded(source_mesh)
		):
			continue
		candidates.append(source_mesh)
	for source_mesh in candidates:
		var member := CSGMesh3D.new()
		member.name = "SuitUnion_%s" % source_mesh.name
		member.mesh = source_mesh.mesh
		member.operation = CSGShape3D.OPERATION_UNION
		_suit_root.add_child(member)
		_bindings.append({"source": source_mesh, "member": member, "transform": Transform3D()})

	_calculate_face_profile()
	_add_face_aperture()
	_build_humongous_eyes(color)


func _is_profile_excluded(mesh: MeshInstance3D) -> bool:
	if target.has_method("titan_suit_excludes_mesh") and bool(target.titan_suit_excludes_mesh(mesh)):
		return true
	var node: Node = mesh
	while node != null and node != target:
		# Visual-only markings and trim describe the rendered surface, not the
		# wearer's anatomy. Folding them into the CSG union would turn paint,
		# freckles, splotches, etc. into raised bumps on the onesie.
		if node.get_meta(CollisionPolicy.POLICY_META, &"") == CollisionPolicy.DECORATIVE:
			return true
		if "tentacle" in node.name.to_lower():
			return true
		node = node.get_parent()
	return false


func _is_face_detail(mesh: MeshInstance3D) -> bool:
	var node: Node = mesh
	while node != null and node != target:
		var lower := node.name.to_lower()
		if (
			"eye" in lower or "lid" in lower or "face" in lower
			or "mouth" in lower or "tooth" in lower or "opening" in lower
		):
			return true
		node = node.get_parent()
	return false


func _calculate_face_profile() -> void:
	if target.has_method("titan_suit_face_profile"):
		var custom: Dictionary = target.titan_suit_face_profile()
		_face_center_local = _suit_root.to_local(custom["center"] as Vector3)
		_face_forward_local = (_suit_root.global_basis.inverse() * (custom["forward"] as Vector3)).normalized()
		_face_up_local = (_suit_root.global_basis.inverse() * (custom.get("up", Vector3.UP) as Vector3)).normalized()
		_face_half = custom["half"] as Vector3
		return
	var face_meshes: Array[MeshInstance3D] = []
	for child in target.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if _is_face_detail(mesh):
			face_meshes.append(mesh)
	var center_local := Vector3.FORWARD
	var width := 1.0
	var height := 1.2
	if not face_meshes.is_empty():
		center_local = Vector3.ZERO
		for mesh in face_meshes:
			var relative := _suit_root.global_transform.affine_inverse() * mesh.global_transform
			center_local += relative.origin
			var scaled := mesh.mesh.get_aabb().size * relative.basis.get_scale()
			width = maxf(width, maxf(scaled.x, scaled.z))
			height = maxf(height, scaled.y)
		center_local /= float(face_meshes.size())
		if face_meshes.size() > 1:
			var spread := 0.0
			for mesh in face_meshes:
				spread = maxf(spread, _suit_root.to_local(mesh.global_position).distance_to(center_local))
			width = maxf(width, spread * 2.2)
	var forward_local := center_local
	forward_local.y *= 0.2
	if forward_local.length_squared() < 0.001:
		forward_local = Vector3.FORWARD
	_face_center_local = center_local
	_face_forward_local = forward_local.normalized()
	_face_up_local = (_suit_root.global_basis.inverse() * Vector3.UP).normalized()
	_face_half = Vector3(width * 0.85, height * 1.45, maxf(width, height) * 0.72)


func _add_face_aperture() -> void:
	_face_cutter = CSGMesh3D.new()
	_face_cutter.name = "FaceOpeningNegative"
	_face_cutter.mesh = SuperEgg.build_mesh(_face_half, 3.2, 3.2)
	_face_cutter.operation = CSGShape3D.OPERATION_SUBTRACTION
	_suit_root.add_child(_face_cutter)
	_position_face_features()


func _build_humongous_eyes(color: Color) -> void:
	var right := _face_up_local.cross(_face_forward_local).normalized()
	var up := _face_forward_local.cross(right).normalized()
	var eye_half := Vector3(_face_half.x * 0.19, _face_half.y * 0.24, _face_half.x * 0.08)
	var base := (
		_face_center_local + up * _face_half.y * 1.08
		+ _face_forward_local * (_face_half.z * 0.56 + FACE_FORWARD_MARGIN)
	)
	for side in [-1.0, 1.0]:
		var eye := SuperEgg.build_part(eye_half, color.darkened(EYE_COLOR_DARKEN), 2.4, 2.4)
		eye.name = "HumongousSuitEyeL" if side < 0.0 else "HumongousSuitEyeR"
		eye.position = base + right * side * _face_half.x * 0.34
		eye.basis = Basis(right, up, _face_forward_local)
		_suit_root.add_child(eye)
		_humongous_eyes.append(eye)
	_position_face_features()


func _position_face_features() -> void:
	var right := _face_up_local.cross(_face_forward_local).normalized()
	var up := _face_forward_local.cross(right).normalized()
	if is_instance_valid(_face_cutter):
		_face_cutter.basis = Basis(right, up, _face_forward_local)
		# Reaches through the front and centre, but stops before the rear crown.
		_face_cutter.position = _face_center_local - _face_forward_local * _face_half.z * 0.42
	var base := (
		_face_center_local + up * _face_half.y * 1.08
		+ _face_forward_local * (_face_half.z * 0.56 + FACE_FORWARD_MARGIN)
	)
	for index in _humongous_eyes.size():
		var side := -1.0 if index == 0 else 1.0
		var eye := _humongous_eyes[index]
		eye.position = base + right * side * _face_half.x * 0.34
		eye.basis = Basis(right, up, _face_forward_local)


func _sync_live_union() -> void:
	var inverse := _suit_root.global_transform.affine_inverse()
	var clearance := SUIT_CLEARANCE
	if target.has_method("titan_suit_clearance_scale"):
		clearance = maxf(float(target.titan_suit_clearance_scale()), 1.0)
	for binding in _bindings:
		var source_mesh := binding["source"] as MeshInstance3D
		var member := binding["member"] as CSGMesh3D
		if not is_instance_valid(source_mesh) or not is_instance_valid(member):
			continue
		var source_transform := inverse * source_mesh.global_transform
		# Clearance about each part's own origin keeps the original Titan inside.
		source_transform.basis = source_transform.basis.scaled(Vector3.ONE * clearance)
		# Assigning an identical transform still dirties a CSG tree. On a large
		# articulated Titan that meant rebuilding dozens of Boolean operands on
		# every idle frame; a pending rebuild could leave the whole suit without
		# a render mesh after a second formation. Only changed pieces invalidate it.
		var previous: Transform3D = binding["transform"] as Transform3D
		if not previous.is_equal_approx(source_transform):
			member.transform = source_transform
			binding["transform"] = source_transform
	# The face can turn independently of the torso (especially Da Hou Zi), so
	# its aperture and Humongous's eyes are projected again from the live rig.
	_calculate_face_profile()
	_position_face_features()
