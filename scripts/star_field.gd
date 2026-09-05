extends Node3D
class_name StarField

## A few hundred point stars scattered across a sphere shell overhead, one
## MultiMesh draw call for the lot. The shell follows the player in XZ so it
## covers the full, much wider play area rather than only the central plateau.
## Kept well inside distant_mountains.gd's RADIUS (950) and biased toward the
## upper sky (MIN_Y) rather than spread
## all the way to the horizon -- both because that reads more like a real
## night sky (stars concentrated overhead, mountains own the horizon band)
## and because it keeps each star's brightness from getting heavily muted
## by Environment's regular distance fog before it reaches the camera.
##
## Plain StandardMaterial3D (unshaded, alpha-blended, per-instance vertex
## color) rather than a custom shader -- a first attempt used a hand-written
## .gdshader with a fog_disabled render mode, which rendered nothing despite
## compiling with no console errors and never got diagnosed further; this is
## the same proven recipe cloud_scatter.gd's puffs and town_props.gd's
## lantern glow already use successfully in this project instead.
## day_night_cycle.gd drives the whole field's visibility through one
## material property (set_night_factor -> albedo alpha), the same way
## cloud_scatter.gd's set_night_factor() drives its shared puff material.

const STAR_COUNT := 350
const RADIUS := 900.0
const MIN_Y := 0.15  # roughly 8.6 degrees above the horizon, at minimum
const STAR_SIZE := 5.7  # scaled with RADIUS so each star's angular size on screen is unchanged
const RNG_SEED := 4242

var _material: StandardMaterial3D
var _player: Node3D


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = RNG_SEED

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = Color(1, 1, 1, 0)
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.vertex_color_use_as_albedo = true
	_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	var quad := QuadMesh.new()
	quad.size = Vector2(STAR_SIZE, STAR_SIZE)

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.mesh = quad
	multimesh.instance_count = STAR_COUNT

	for i in STAR_COUNT:
		var dir := _random_upper_dir(rng)
		var brightness := rng.randf_range(0.5, 1.0)
		multimesh.set_instance_transform(i, Transform3D(Basis(), dir * RADIUS))
		multimesh.set_instance_color(i, Color(1, 1, 1, brightness))

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = multimesh
	mmi.material_override = _material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)


func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player:
		# Preserve the dome's authored world height while keeping its horizontal
		# center on the player. Following Y would make stars bob when jumping.
		var player_position := _player.global_position
		global_position = Vector3(player_position.x, global_position.y, player_position.z)


func _random_upper_dir(rng: RandomNumberGenerator) -> Vector3:
	# Not a perfectly uniform distribution over the spherical cap above
	# MIN_Y (normalizing can nudge y back down a little when x/z happen to
	# be large) -- close enough for a decorative starfield; nothing here
	# needs to be statistically exact.
	return Vector3(
		rng.randf_range(-1.0, 1.0), rng.randf_range(MIN_Y, 1.0), rng.randf_range(-1.0, 1.0)
	).normalized()


## t: 0 (full day, invisible) .. 1 (full night, fully visible).
func set_night_factor(t: float) -> void:
	if _material:
		_material.albedo_color.a = t
