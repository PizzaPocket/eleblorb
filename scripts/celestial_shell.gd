extends Node3D
class_name CelestialShell

## Shared distant sky architecture for every world: stars and moon occupy one
## player-following celestial shell, so neither can be flown past. The moon's
## physical radius is scaled to preserve its authored apparent angular size.

const RADIUS := StarField.RADIUS
const OLD_MOON_DISTANCE := 900.0
const OLD_MOON_RADIUS := 32.0
const MOON_RADIUS := OLD_MOON_RADIUS * RADIUS / OLD_MOON_DISTANCE
const MOON_COLOR := Color(0.88, 0.9, 0.86)

var _stars: StarField
var _moon: MeshInstance3D
var _moon_material: StandardMaterial3D
var _player: Node3D
var _sun_direction := Vector3.DOWN
var _visibility := 0.0


func _ready() -> void:
	_build_stars()
	_build_moon()
	_apply_presentation()


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player != null:
		global_position = Vector3(_player.global_position.x, 0.0, _player.global_position.z)


func set_presentation(sun_direction: Vector3, visibility: float) -> void:
	_sun_direction = sun_direction
	_visibility = clampf(visibility, 0.0, 1.0)
	_apply_presentation()


func _build_stars() -> void:
	_stars = StarField.new()
	_stars.follow_player = false
	add_child(_stars)


func _build_moon() -> void:
	var sphere := SphereMesh.new()
	sphere.radius = MOON_RADIUS
	sphere.height = MOON_RADIUS * 2.0
	sphere.radial_segments = 32
	sphere.rings = 16
	_moon_material = StandardMaterial3D.new()
	_moon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_moon_material.albedo_color = MOON_COLOR
	_moon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_moon_material.emission_enabled = true
	_moon_material.emission = MOON_COLOR
	_moon_material.emission_energy_multiplier = 0.6
	_moon_material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)
	_moon = MeshInstance3D.new()
	_moon.name = "Moon"
	_moon.mesh = sphere
	_moon.material_override = _moon_material
	_moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_moon)


func _apply_presentation() -> void:
	if _stars != null:
		_stars.set_night_factor(_visibility)
	if _moon == null or _moon_material == null:
		return
	var moon_direction := -_sun_direction
	_moon.position = moon_direction * RADIUS
	_moon_material.albedo_color.a = smoothstep(-0.05, 0.05, moon_direction.y)
