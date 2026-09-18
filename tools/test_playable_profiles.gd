extends SceneTree


func _initialize() -> void:
	var human := PlayableCharacterProfile.human()
	assert(is_equal_approx(human.move_speed, 6.0))
	assert(is_equal_approx(human.sprint_multiplier, 1.6))
	assert(is_equal_approx(human.jump_speed, 11.3))
	assert(is_equal_approx(human.gravity_scale, 4.8))
	assert(is_equal_approx(human.suit_rig_scale, 1.0))

	var xiao := PlayableCharacterProfile.xiao_hou_zi()
	assert(is_equal_approx(xiao.move_speed, 2.5))
	assert(is_equal_approx(xiao.sprint_multiplier, 1.6))
	assert(is_equal_approx(xiao.jump_speed, 11.3 * 1.8))
	assert(is_equal_approx(xiao.walk_cadence_scale, 2.16))
	assert(is_equal_approx(xiao.body_motion_scale, 0.1))
	assert(is_equal_approx(xiao.suit_rig_scale, 0.245))

	assert(is_equal_approx(HumanoidLocomotion.ground_speed(human, false), 6.0))
	assert(is_equal_approx(HumanoidLocomotion.ground_speed(human, true), 9.6))
	assert(is_equal_approx(HumanoidLocomotion.ground_speed(xiao, false), 2.5))
	assert(is_equal_approx(HumanoidLocomotion.ground_speed(xiao, true), 4.0))
	quit(0)
