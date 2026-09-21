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
## Dimensionless adjustments applied after suit_rig_scale. A single height
## ratio cannot describe differently-proportioned rigs: compact figures may
## have short limbs but comparatively broad wrists, knees and feet. Keeping
## these measurements on the character profile lets every future suit wearer
## describe its fit without character-name branches in BlorbSuit.
var suit_limb_fit: Dictionary
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
		"needs_breath": true,
		# The motor still requires a complete Space suit; this declares that the
		# rig knows how to pose and steer one.
		"zero_gravity_propulsion": true,
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
	profile.suit_limb_fit = {}
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
		"zero_gravity_propulsion": true,
		# No "needs_breath": a living stuffed animal never runs out of air.
	}
	# Exact values from the previously tuned Player-hosted monkey mode.
	profile.move_speed = 2.5
	profile.sprint_multiplier = 1.6
	# The same jump as the human, which for a rig a quarter his size is an
	# enormous leap: per direct instruction, a monkey should clear what a
	# person clears. The blorb trampoline launches off this same number, so
	# he bounces to the human's height too.
	profile.jump_speed = 11.3
	profile.gravity_scale = 4.8
	profile.walk_cadence_scale = 2.16
	profile.body_motion_scale = 0.1
	profile.standing_height = 1.896 * 0.245
	profile.camera_height = 0.75
	profile.camera_distance = 2.0
	# Established MonkeyFigure.BLORB_SUIT_RIG_SCALE value. This copy is a saved
	# tuning datum, not a second runtime calculation.
	profile.suit_rig_scale = 0.245
	# Xiao's MonkeyFigure is much broader at its distal limbs than a uniformly
	# scaled-down ProceduralFigure. These station multipliers preserve the live
	# joint path while ensuring the goo shell encloses the authored limb tube.
	profile.suit_limb_fit = {
		# Deliberately overlap both anatomical seams. Suit pieces are shells:
		# stopping exactly at a mathematical joint exposes the wearer as the
		# animation bends, while this small profile-relative overlap remains
		# correct for any future rig built to Xiao's compact pear-body family.
		"torso_bottom": MonkeyFigure.BODY_HEIGHT * 0.17,
		"torso_top": MonkeyFigure.BODY_HEIGHT - MonkeyFigure.HEAD_EMBED + 0.010,
		"arm_shoulder": 1.25,
		"arm_elbow": 1.40,
		"arm_wrist": 1.65,
		"arm_tip": 1.55,
		"round_arm_tip": true,
		"monkey_foot_curve": true,
		"leg_hip": 1.40,
		"leg_knee": 1.70,
		"leg_ankle": 1.65,
		"leg_toe": 1.55,
		"leg_hip_overlap": 0.010 * MonkeyFigure.REFERENCE_BUILD_SCALE,
	}
	profile.switch_order = 20
	return profile
