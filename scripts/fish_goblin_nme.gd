extends "res://scripts/skeleton_nme.gd"

## Amphibious Kraken servant. Combat values and XP deliberately inherit the
## ape skeleton baseline; only body construction and locomotion differ.

const FISH_SKIN := Color(0.18, 0.62, 0.66)
const SEAWEED := Color(0.12, 0.34, 0.18)
var _swim_phase := 0.0
var _swim_depth := -3.4


func _ready() -> void:
	super()
	name = "FishGoblin"
	_swim_depth = -3.0 - randf() * 4.0


func _build_figure() -> void:
	var pivots := ProceduralFigure.build(
		visuals, FISH_SKIN, SEAWEED, SEAWEED, ProceduralFigure.SLEEVE_STYLE_SHORT,
		body_scale, 0.78, 0.72, 0.9, SEAWEED,
		FISH_SKIN, FigureHair.STYLE_BALD, 0.0, FISH_SKIN, false
	)
	_leg_left = pivots["leg_left"]
	_leg_right = pivots["leg_right"]
	_arm_left = pivots["arm_left"]
	_arm_right = pivots["arm_right"]
	_knee_left = pivots["knee_left"]
	_knee_right = pivots["knee_right"]
	_elbow_left = pivots["elbow_left"]
	_elbow_right = pivots["elbow_right"]
	_spine = pivots["spine"]
	_hips = pivots["hips"]
	var head := pivots.get("head") as Node3D
	if head != null:
		_add_head_fin(head, -1.0)
		_add_head_fin(head, 1.0)


func _add_head_fin(head: Node3D, side: float) -> void:
	var fin := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.12, 0.48, 0.52)
	fin.mesh = mesh
	fin.position = Vector3(side * 0.38, 0.0, 0.0)
	fin.rotation.z = side * deg_to_rad(18.0)
	var material := StandardMaterial3D.new()
	material.albedo_color = FISH_SKIN.lightened(0.12)
	fin.material_override = material
	head.add_child(fin)


func _process(delta: float) -> void:
	super(delta)
	if _state == State.RISING or _state == State.SINKING:
		return
	_swim_phase += delta * 3.2
	global_position.y = move_toward(global_position.y, _swim_depth + sin(_swim_phase) * 0.45, delta * 5.0)
	# Player-like prone swim silhouette: alternating limbs with the torso
	# pitched forward through the water rather than a seabed walk.
	visuals.rotation.x = lerp_angle(visuals.rotation.x, deg_to_rad(72.0), delta * 4.0)
	_arm_left.rotation.x += sin(_swim_phase) * 0.16
	_arm_right.rotation.x -= sin(_swim_phase) * 0.16
	_leg_left.rotation.x -= sin(_swim_phase) * 0.12
	_leg_right.rotation.x += sin(_swim_phase) * 0.12
