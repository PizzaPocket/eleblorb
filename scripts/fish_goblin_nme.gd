extends "res://scripts/skeleton_nme.gd"

## Amphibious Kraken servant. Combat values and XP deliberately inherit the
## ape skeleton baseline; only body construction and locomotion differ.

const FISH_SKIN := Color(0.92, 0.34, 0.32)
const SEAWEED := Color(0.56, 0.12, 0.16)
const SHALLOWEST_FLOOR := -1.5
var _swim_phase := 0.0
var _swim_depth := -3.4
var _tail_pivots: Array[Node3D] = []


func _ready() -> void:
	super()
	name = "FishGoblin"
	_swim_depth = -4.0 - randf() * 4.0
	# This aquatic body is already swimming when encountered. The inherited
	# terrestrial rise begins below the ground and drags its long tail through
	# the seabed before it reaches open water.
	_state = State.HUNTING
	var floor_y: float = terrain_ref.get_mesh_height(global_position.x, global_position.z)
	global_position.y = maxf(_swim_depth, floor_y + 5.0)


## Fish-skinned aquatic humanoid -- always water-coded, unlike False Hero's
## own phase-conditional version of this same method. This is what makes
## Wood's own type advantage against it (see combat_math.gd's own
## TYPE_ADVANTAGES comment) real -- it had no element at all before, so
## nothing could counter it.
func current_combat_element() -> String:
	return "water"


func _build_figure() -> void:
	var pivots := ProceduralFigure.build(
		visuals, FISH_SKIN, SEAWEED, SEAWEED, ProceduralFigure.SLEEVE_STYLE_SHORT,
		body_scale, 0.78, 0.72, 0.9, SEAWEED,
		FISH_SKIN, FigureHair.STYLE_BALD, 0.0, FISH_SKIN, false, false, 1.0, false
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
	_leg_left.visible = false
	_leg_right.visible = false
	_tail_pivots = AquaticTail.add_to_hips(_hips, 1.0, Color(0.08, 0.22, 0.48))
	var head_mesh := pivots.get("head_mesh") as MeshInstance3D
	if head_mesh != null:
		# Reuse the world's restrained anatomical ear form as a head fin,
		# enlarged modestly and swept back rather than adding a huge prism.
		FigureEars.add_ears(
			head_mesh, ProceduralFigure.HEAD_SIZE, FISH_SKIN.lightened(0.08),
			false, 0.0, Color(0.0, 0.0, 0.0, 0.0), 1.45, 38.0
		)


func _process(delta: float) -> void:
	var previous_xz := Vector2(global_position.x, global_position.z)
	super(delta)
	# Parent combat steering is ground-oriented and can chase a target onto an
	# island. Fish goblins may approach the shoreline, but never cross onto a
	# seabed point shallow enough to break the surface.
	if terrain_ref != null and terrain_ref.get_mesh_height(global_position.x, global_position.z) >= SHALLOWEST_FLOOR:
		global_position.x = previous_xz.x
		global_position.z = previous_xz.y
	if _state == State.RISING or _state == State.SINKING:
		return
	_swim_phase += delta * 3.2
	var local_floor: float = terrain_ref.get_mesh_height(global_position.x, global_position.z)
	var desired_depth := maxf(_swim_depth + sin(_swim_phase) * 0.45, local_floor + 5.0)
	global_position.y = move_toward(global_position.y, desired_depth, delta * 5.0)
	# Player-like prone swim silhouette: alternating limbs with the torso
	# pitched forward through the water rather than a seabed walk.
	visuals.rotation.x = lerp_angle(visuals.rotation.x, deg_to_rad(72.0), delta * 4.0)
	_arm_left.rotation.x += sin(_swim_phase) * 0.16
	_arm_right.rotation.x -= sin(_swim_phase) * 0.16
	_leg_left.rotation.x -= sin(_swim_phase) * 0.12
	_leg_right.rotation.x += sin(_swim_phase) * 0.12
	AquaticTail.animate(_tail_pivots, _swim_phase, 1.0)
