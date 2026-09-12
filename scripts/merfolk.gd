class_name Merfolk
extends StaticBody3D

## Peaceful Ocean Kingdom resident: the shared humanoid upper rig transitions
## into AquaticTail's articulated mer-tail instead of two legs.

const TRAVERSAL_LEAN := deg_to_rad(13.0)
const LEAN_RESPONSE := 3.2

@export var display_name := "Merfolk"
@export_multiline var dialogue_text := "The upper water is restless today."
@export var is_vendor := false
@export var is_king := false
@export var is_female := false
@export var wander_radius := 9.0
@export var skin_color := Color(0.16, 0.69, 0.68)
@export var scale_clothing_color := Color(0.62, 0.76, 0.78)
@export var tail_color := AquaticTail.DEFAULT_TAIL_COLOR
@export var sleeve_style := ProceduralFigure.SLEEVE_STYLE_SHORT
@export var hair_style := FigureHair.STYLE_BUZZCUT
@export var hair_color := Color(0.04, 0.22, 0.27)
@export var hair_length_variance := 0.0
@export var has_midriff := false
@export_enum("none", "shell", "sea_flower") var hair_ornament := "none"
@export var hair_ornament_color := Color(0.92, 0.73, 0.52)

var _tail_pivots: Array[Node3D] = []
var _phase := 0.0
var _tail_rate := 1.0
var _home := Vector2.ZERO
var _destination := Vector2.ZERO
var _moving := false
var _state_timer := 0.0
var _swim_speed := 0.0
var _terrain: Node
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()
var _visuals: Node3D
var _head: Node3D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id() * 7919
	_phase = rng.randf_range(0.0, TAU)
	_tail_rate = rng.randf_range(0.78, 1.22)
	_swim_speed = rng.randf_range(0.42, 0.68)
	_state_timer = rng.randf_range(1.0, 4.5)
	_home = Vector2(position.x, position.z)
	_destination = _home
	_terrain = get_node_or_null("../../Terrain")
	collision_layer = 1
	collision_mask = 0
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 2.25
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.8, 0.0)
	add_child(collision)
	_visuals = Node3D.new()
	_visuals.name = "Visuals"
	add_child(_visuals)
	var pivots := ProceduralFigure.build(
		_visuals, skin_color, scale_clothing_color, skin_color,
		sleeve_style, 1.08, 0.90 if is_female else 1.02, 1.06 if is_female else 0.92, 0.94,
		Color(0.0, 0.0, 0.0, 0.0), hair_color,
		hair_style, hair_length_variance, tail_color, false, false, 0.78, false
	)
	var left_leg := pivots["leg_left"] as Node3D
	var right_leg := pivots["leg_right"] as Node3D
	left_leg.visible = false
	right_leg.visible = false
	var hips := pivots["hips"] as MeshInstance3D
	_tail_pivots = AquaticTail.add_to_hips(hips, 1.08, tail_color)
	_eyes = pivots["eyes"]
	_head = pivots["head"] as Node3D
	var head_mesh := pivots["head_mesh"] as MeshInstance3D
	FigureEars.add_ears(head_mesh, ProceduralFigure.HEAD_SIZE, skin_color.lightened(0.08), false, 0.0, Color(0, 0, 0, 0), 1.35, 34.0)
	if is_female and hair_ornament != "none":
		_add_hair_ornament(head_mesh)
	var spine := pivots["spine"] as Node3D
	if has_midriff:
		_apply_midriff(spine)
	_add_scale_clothing(spine, has_midriff)
	if is_king:
		_add_nautilus_crown(pivots["head"] as Node3D)
	Interactable.attach(self, "Talk", 2.2, _on_talk)


func _process(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		if _moving:
			_moving = false
			_state_timer = randf_range(2.0, 6.5)
		else:
			_moving = true
			_state_timer = randf_range(4.0, 9.0)
			var angle := randf_range(0.0, TAU)
			var distance := sqrt(randf()) * wander_radius
			_destination = _home + Vector2(cos(angle), sin(angle)) * distance
	var motion_strength := 0.34
	if _moving:
		var here := Vector2(position.x, position.z)
		var offset := _destination - here
		if offset.length() < 0.25:
			_moving = false
			_state_timer = randf_range(2.0, 6.5)
		else:
			var direction := offset.normalized()
			var step := direction * minf(_swim_speed * delta, offset.length())
			position.x += step.x
			position.z += step.y
			rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.y), delta * 2.2)
			motion_strength = 0.78
			if _terrain != null:
				position.y = move_toward(position.y, _terrain.get_mesh_height(position.x, position.z) + 2.1, delta * 1.2)
	_phase += delta * (2.0 if _moving else 0.82) * _tail_rate
	# Travel has the gentle crown-forward attitude of a swimmer, but the
	# neck counters that body pitch so the face remains upright and aimed
	# along the horizontal route. Both ease back to neutral during an idle.
	var lean_target := TRAVERSAL_LEAN if _moving else 0.0
	var lean_weight := 1.0 - exp(-LEAN_RESPONSE * delta)
	_visuals.rotation.x = lerp_angle(_visuals.rotation.x, lean_target, lean_weight)
	_head.rotation.x = lerp_angle(_head.rotation.x, -lean_target, lean_weight)
	AquaticTail.animate(_tail_pivots, _phase, motion_strength)
	EyeBlink.apply(_eye_blink, delta, _eyes)


func _on_talk() -> void:
	if is_vendor:
		var actions: Array[Dictionary] = [{
			"label": "Browse wares.",
			"callback": func() -> void:
				DialogUI.hide_dialog()
				ShopUI.open(ShopCatalog.get_items_for_shop("ocean_merfolk")),
		}]
		DialogUI.show_line(display_name, dialogue_text, actions)
	elif is_king:
		DialogUI.show_line(display_name, dialogue_text)
	else:
		DialogUI.show_line(display_name, dialogue_text)


func _apply_midriff(spine: Node3D) -> void:
	if spine.get_child_count() == 0:
		return
	var abdomen := spine.get_child(0) as MeshInstance3D
	if abdomen == null:
		return
	var material := StandardMaterial3D.new()
	material.albedo_color = skin_color
	material.roughness = 0.6
	abdomen.set_surface_override_material(0, material)


func _add_scale_clothing(spine: Node3D, cropped: bool) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = scale_clothing_color
	material.metallic = 0.72
	material.roughness = 0.28
	var row_count := 2 if cropped else 3
	var base_y := 0.52 if cropped else 0.19
	for row in row_count:
		for column in 4:
			var scale_plate := MeshInstance3D.new()
			scale_plate.mesh = SuperEgg.build_mesh(Vector3(0.043, 0.035, 0.012), 2.3, 2.3)
			scale_plate.material_override = material
			scale_plate.position = Vector3((float(column) - 1.5) * 0.075, base_y + float(row) * 0.065, 0.125)
			spine.add_child(scale_plate)


func _add_nautilus_crown(head: Node3D) -> void:
	var shell_color := Color(0.42, 0.92, 0.78)
	for index in 9:
		var angle := float(index) * 0.62
		var radius := 0.018 + float(index) * 0.011
		var shell := SuperEgg.build_part(Vector3(radius, radius * 0.72, 0.018), shell_color, 2.3, 2.3)
		shell.position = Vector3(cos(angle) * radius * 1.6, 0.26 + sin(angle) * radius * 1.6, 0.02)
		head.add_child(shell)


func _add_hair_ornament(head: MeshInstance3D) -> void:
	# The anchor is slightly inside the upper-front side of the shared hair
	# volume. Ornament pieces project only through its outward face, keeping
	# them nestled into the hairstyle instead of floating beside the head.
	var side := -1.0 if get_instance_id() % 2 == 0 else 1.0
	var ornament := Node3D.new()
	ornament.name = "HairOrnament"
	ornament.position = Vector3(side * 0.125, 0.125, 0.075)
	ornament.rotation.y = side * deg_to_rad(18.0)
	head.add_child(ornament)
	if hair_ornament == "shell":
		for index in 3:
			var scale_factor := 1.0 - float(index) * 0.22
			var shell := SuperEgg.build_part(
				Vector3(0.023, 0.018, 0.009) * scale_factor,
				hair_ornament_color.lightened(float(index) * 0.08), 2.2, 2.2
			)
			shell.position = Vector3(side * float(index) * 0.012, float(index) * 0.008, 0.006 + float(index) * 0.002)
			shell.rotation.z = side * float(index) * 0.42
			ornament.add_child(shell)
	else:
		var center := SuperEgg.build_part(Vector3(0.012, 0.012, 0.009), hair_ornament_color.lightened(0.18), 2.0, 2.0)
		center.position.z = 0.008
		ornament.add_child(center)
		for petal_index in 5:
			var angle := TAU * float(petal_index) / 5.0
			var petal := SuperEgg.build_part(Vector3(0.010, 0.022, 0.007), hair_ornament_color, 2.2, 2.2)
			petal.position = Vector3(cos(angle) * 0.022, sin(angle) * 0.022, 0.006)
			petal.rotation.z = angle - PI * 0.5
			ornament.add_child(petal)
