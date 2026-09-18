class_name PlayableCharacterProfile
extends RefCounted

## Data-only description of a controllable party member. The motor and
## switching system consume this profile; character scripts retain only
## genuinely unique abilities and their own rig adapters.

var id: String
var display_name: String
var capabilities: Dictionary
var move_speed: float
var sprint_multiplier: float
var jump_speed: float
var gravity_scale: float
var walk_cadence_scale: float
var body_motion_scale: float
var standing_height: float
var camera_height: float
var camera_distance: float
var suit_rig_scale: float
var switch_order: int


static func human() -> PlayableCharacterProfile:
	var profile := PlayableCharacterProfile.new()
	# Keep profiles data-only. Autoload singletons are runtime services and are
	# deliberately not dependencies of this resource (headless tooling compiles
	# resources before autoload globals are available).
	profile.id = "player"
	profile.display_name = "Player"
	profile.capabilities = {
		"wear_blorb_suit": true,
		"ride_mount": true,
		"use_items": true,
	}
	profile.move_speed = 6.0
	profile.sprint_multiplier = 1.6
	profile.jump_speed = 11.3
	profile.gravity_scale = 4.8
	profile.walk_cadence_scale = 1.0
	profile.body_motion_scale = 1.0
	profile.standing_height = 1.896
	profile.camera_height = 1.6
	profile.camera_distance = 3.5
	profile.suit_rig_scale = 1.0
	profile.switch_order = 0
	return profile


static func xiao_hou_zi() -> PlayableCharacterProfile:
	var profile := PlayableCharacterProfile.new()
	profile.id = "xiao_hou_zi"
	profile.display_name = "Xiao Hou Zi"
	profile.capabilities = {
		"wear_blorb_suit": true,
		"ride_mount": true,
		"use_items": true,
		"summon_sun_wu_kong": true,
	}
	# Exact values from the previously tuned Player-hosted monkey mode.
	profile.move_speed = 2.5
	profile.sprint_multiplier = 1.6
	profile.jump_speed = 11.3 * 1.8
	profile.gravity_scale = 4.8
	profile.walk_cadence_scale = 2.16
	profile.body_motion_scale = 0.1
	profile.standing_height = 1.896 * 0.245
	profile.camera_height = 0.75
	profile.camera_distance = 2.0
	# Established MonkeyFigure.BLORB_SUIT_RIG_SCALE value. This copy is a saved
	# tuning datum, not a second runtime calculation.
	profile.suit_rig_scale = 0.245
	profile.switch_order = 20
	return profile
