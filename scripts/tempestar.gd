class_name Tempestar
extends StaticBody3D

## Sky Kingdom resident: the shared humanoid upper rig continues into
## TornadoTail's swirling funnel instead of two legs -- the Sky Kingdom's
## own counterpart to Ocean Kingdom's Merfolk (see that file's own class
## doc; this script follows the same shape deliberately). Only ever visible
## while SkyKingdom itself is visible -- see that script's own class doc for
## the Bird Helm visibility gate.

const HOVER_LEAN := deg_to_rad(9.0)
const LEAN_RESPONSE := 3.0
## Per direct instruction ("for the jewelry, for the sky people... can we
## make it gold").
const GOLD_COLOR := Color(0.86, 0.68, 0.28)

@export var display_name := "Tempestar"
@export_multiline var dialogue_text := "The wind's been restless above this cloud all morning."
@export var is_ruler := false
@export var is_female := false
@export var wander_radius := 7.0
@export var skin_color := Color(0.72, 0.76, 0.86)
@export var funnel_color := TornadoTail.DEFAULT_COLOR
## Set by sky_kingdom.gd before add_child() -- when present, the tornado's
## segments use this exact shared material (unshaded, matching the sky's
## real clouds) instead of funnel_color's own ordinary shaded material.
var funnel_material: Material = null
@export var sleeve_style := ProceduralFigure.SLEEVE_STYLE_SHORT
@export var hair_style := FigureHair.STYLE_BUZZCUT
@export var hair_color := Color(0.22, 0.24, 0.34)
@export var hair_length_variance := 0.0
@export var clothing_color := Color(0.46, 0.5, 0.66)

var _tail_pivots: Array[Node3D] = []
var _phase := 0.0
var _spin_rate := 1.0
var _home := Vector2.ZERO
var _destination := Vector2.ZERO
var _moving := false
var _state_timer := 0.0
var _drift_speed := 0.0
var _home_y := 0.0
var _eyes: Array = []
var _eye_blink := EyeBlink.new_state()
var _visuals: Node3D
var _head: Node3D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = get_instance_id() * 7919
	_phase = rng.randf_range(0.0, TAU)
	_spin_rate = rng.randf_range(0.75, 1.3)
	_drift_speed = rng.randf_range(0.36, 0.58)
	_state_timer = rng.randf_range(1.0, 4.5)
	_home = Vector2(position.x, position.z)
	_destination = _home
	# Unlike Merfolk (which follows real ground/water terrain height), a
	# Tempestar hovers at a fixed height above its own cloud island -- there
	# is no terrain height field way up here to sample.
	_home_y = position.y
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
	# Per direct correction ("supposed to be gender presenting, but you're
	# not using the soft body type for the females") -- chest/hip build were
	# already gendered, but overall scale/leg thickness were the same flat
	# number for both, which is what left female Tempestars reading as just
	# a smaller-chested, wider-hipped copy of the male frame rather than a
	# genuinely softer/smaller build overall, the way Merfolk's own females
	# read. Matches Merfolk's own scale/build numbers exactly now.
	var pivots := ProceduralFigure.build(
		_visuals, skin_color, clothing_color, skin_color,
		sleeve_style, 1.02 if is_female else 1.1, 0.88 if is_female else 1.02, 1.08 if is_female else 0.92, 0.9,
		Color(0.0, 0.0, 0.0, 0.0), hair_color,
		hair_style, hair_length_variance, clothing_color, false, false, 0.7 if is_female else 0.82, false
	)
	var left_leg := pivots["leg_left"] as Node3D
	var right_leg := pivots["leg_right"] as Node3D
	left_leg.visible = false
	right_leg.visible = false
	var hips := pivots["hips"] as MeshInstance3D
	_tail_pivots = TornadoTail.add_to_hips(hips, 1.08, funnel_color, funnel_material)
	_eyes = pivots["eyes"]
	_head = pivots["head"] as Node3D
	if is_ruler:
		var head_mesh := pivots["head_mesh"] as MeshInstance3D
		HairOrnaments.build_laurel_wreath(head_mesh, ProceduralFigure.HEAD_SIZE, hair_style, GOLD_COLOR)
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
	var motion_strength := 0.4
	if _moving:
		var here := Vector2(position.x, position.z)
		var offset := _destination - here
		if offset.length() < 0.25:
			_moving = false
			_state_timer = randf_range(2.0, 6.5)
		else:
			var direction := offset.normalized()
			var step := direction * minf(_drift_speed * delta, offset.length())
			position.x += step.x
			position.z += step.y
			rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.y), delta * 2.0)
			motion_strength = 0.85
	# A little vertical bob rather than a dead-flat hover height.
	position.y = _home_y + sin(_phase * 0.4) * 0.18
	_phase += delta * (1.5 if _moving else 1.0) * _spin_rate
	var lean_target := HOVER_LEAN if _moving else 0.0
	var lean_weight := 1.0 - exp(-LEAN_RESPONSE * delta)
	_visuals.rotation.x = lerp_angle(_visuals.rotation.x, lean_target, lean_weight)
	_head.rotation.x = lerp_angle(_head.rotation.x, -lean_target, lean_weight)
	TornadoTail.animate(_tail_pivots, _phase, motion_strength)
	EyeBlink.apply(_eye_blink, delta, _eyes)


func _on_talk() -> void:
	DialogUI.show_line(display_name, dialogue_text)
