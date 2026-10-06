extends Node3D

## Reusable physical door leaf (single or paired). The wall owns the opening;
## this node owns the moving leaves, their collision, interaction, lock state,
## and animation. It is used by panel, interior and log construction so a door
## is never just a decorative slab permanently frozen open.

var _hinges: Array[StaticBody3D] = []
var _open_rotations: Array[float] = []
var _is_open := true
var _locked := false
var _required_key := ""
var _lock_id := ""
var _area: Area3D
var _moving := false


func configure(
	half_width: float, height: float, leaves: int, color: Color,
	initially_open: bool = true, locked: bool = false,
	required_key: String = "", lock_id: String = ""
) -> void:
	_is_open = initially_open
	_locked = locked and not (lock_id != "" and WorldState.is_door_unlocked(lock_id))
	_required_key = required_key
	_lock_id = lock_id
	var leaf_color := color.darkened(0.1)
	var material := StandardMaterial3D.new()
	material.albedo_color = leaf_color
	material.roughness = 0.8
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var half_leaf := half_width if leaves == 1 else half_width * 0.5
	var open_angle := deg_to_rad(78.0 if leaves == 1 else 96.0)
	for index in leaves:
		var side := -1.0 if index == 0 else 1.0
		var hinge := StaticBody3D.new()
		hinge.collision_layer = 1
		hinge.collision_mask = 0
		hinge.position = Vector3(side * half_width, 0.0, 0.0)
		add_child(hinge)
		# Build the moving leaf from the same complete SuperEgg silhouette as its
		# partner, then make true planar cuts at the meeting edge and floor. This
		# leaves a soft outer shoulder and arch while the two shut leaves meet on
		# one exact line instead of overlapping two separately rounded slabs.
		var door_half_width := half_width - 0.015
		var bottom_extension := 0.44
		var door_height := height - 0.02
		var vertical_half := (door_height + bottom_extension) * 0.5
		var vertical_centre := door_height - vertical_half
		var planes: Array[Plane] = [Plane(Vector3.DOWN, vertical_centre)]
		if leaves > 1:
			planes.append(Plane(Vector3.RIGHT if side < 0.0 else Vector3.LEFT, 0.0))
		var leaf := MeshInstance3D.new()
		leaf.mesh = SuperEgg.build_clipped_mesh(
			Vector3(door_half_width, vertical_half, 0.025), planes,
			SuperEgg.EPSILON_FLAT, 4.0
		)
		leaf.material_override = material
		leaf.position = Vector3(-side * half_width, vertical_centre, 0.0)
		hinge.add_child(leaf)
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(half_leaf * 2.0 - 0.04, height - 0.08, 0.08)
		collision.shape = shape
		collision.position = Vector3(-side * half_leaf, height * 0.5, 0.0)
		hinge.add_child(collision)
		_hinges.append(hinge)
		_open_rotations.append(open_angle * (1.0 if side < 0.0 else -1.0))
	_apply_pose(false)
	# A spherical trigger can overlap someone through the floor above or below.
	# The tighter vertical allowance makes this a door on THIS storey, while the
	# horizontal radius still leaves comfortable room in front of either leaf.
	_area = Interactable.attach(self, _prompt(), 2.25, _activate, Callable(), Callable(), true, 1.25)


func _prompt() -> String:
	if _locked:
		return "Unlock door" if _required_key != "" and Inventory.has(_required_key) else "Locked door"
	return "Close door" if _is_open else "Open door"


func _activate() -> void:
	if _lock_id != "" and WorldState.is_door_unlocked(_lock_id):
		_locked = false
	if _locked:
		if _required_key == "" or not Inventory.has(_required_key):
			Hud.show_message("The door is locked.")
			_update_prompt()
			return
		_locked = false
		if _lock_id != "":
			WorldState.unlock_door(_lock_id)
		Hud.show_message("Unlocked with the %s." % _required_key)
		_is_open = true
		_apply_pose(true)
		_update_prompt()
		return
	if _moving:
		return
	_is_open = not _is_open
	_apply_pose(true)
	_update_prompt()


func _apply_pose(animated: bool) -> void:
	_moving = animated
	if animated:
		# A creak as it starts to swing open; the shut sound lands as it meets the frame.
		if _is_open:
			UISounds.play_foley(&"door_open", 0.5, get_instance_id())
		else:
			get_tree().create_timer(0.28).timeout.connect(func() -> void:
				if is_instance_valid(self) and is_inside_tree():
					UISounds.play_foley(&"door_close", 0.62, get_instance_id())
			)
	var longest := 0.0
	for index in _hinges.size():
		var target := _open_rotations[index] if _is_open else 0.0
		if animated:
			var tween := create_tween()
			tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(_hinges[index], "rotation:y", target, 0.34)
			longest = 0.34
		else:
			_hinges[index].rotation.y = target
	if longest > 0.0:
		get_tree().create_timer(longest).timeout.connect(func() -> void: _moving = false)
	else:
		_moving = false


func _update_prompt() -> void:
	if is_instance_valid(_area):
		_area.set_meta("prompt", _prompt())
