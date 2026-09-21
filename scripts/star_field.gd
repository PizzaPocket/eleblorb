extends Node3D
class_name StarField

## A few hundred point stars scattered across a sphere shell overhead, one
## MultiMesh draw call for the lot. The shell follows the player in XZ so it
## covers the full, much wider play area rather than only the central plateau.
## The shell is deliberately far beyond any reachable flying route. Its
## sprites grow in direct proportion to the radius, preserving their apparent
## size while preventing the player from ever flying above the night sky.
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
const RADIUS := 9000.0
const MIN_Y := 0.15  # roughly 8.6 degrees above the horizon, at minimum
const STAR_SIZE := 57.0  # 10x radius and size preserves the old angular size.
const STAR_TEXTURE_SIZE := 32
const REQUIRED_CAMERA_FAR := RADIUS * 1.2
const RNG_SEED := 4242

var _material: StandardMaterial3D
var _player: Node3D
var _configured_camera: Camera3D


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
	_material.albedo_texture = _build_round_star_texture()
	_material.set_flag(BaseMaterial3D.FLAG_DISABLE_FOG, true)

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
	mmi.extra_cull_margin = RADIUS * 2.0
	add_child(mmi)


func _process(_delta: float) -> void:
	# A 9 km sky shell needs a matching far plane. Reapply when character or
	# camera switching promotes a different gameplay camera.
	var active_camera := get_viewport().get_camera_3d()
	if active_camera and active_camera != _configured_camera:
		active_camera.far = maxf(active_camera.far, REQUIRED_CAMERA_FAR)
		_configured_camera = active_camera
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player:
		# Preserve the dome's authored world height while keeping its horizontal
		# center on the player. Following Y would make stars bob when jumping.
		var player_position := _player.global_position
		global_position = Vector3(player_position.x, global_position.y, player_position.z)


func _build_round_star_texture() -> ImageTexture:
	# A tiny procedural radial mask keeps the shared MultiMesh to one draw call,
	# but makes every billboard a soft circular point instead of a white square.
	var image := Image.create(STAR_TEXTURE_SIZE, STAR_TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for y in STAR_TEXTURE_SIZE:
		for x in STAR_TEXTURE_SIZE:
			var uv := (Vector2(x, y) + Vector2(0.5, 0.5)) / float(STAR_TEXTURE_SIZE)
			var radial_distance := (uv - Vector2(0.5, 0.5)).length() * 2.0
			var alpha := 1.0 - smoothstep(0.72, 1.0, radial_distance)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(image)


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
