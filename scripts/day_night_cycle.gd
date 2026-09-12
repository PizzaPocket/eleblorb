extends Node

## Drives a full day/night cycle from a single game clock -- the sun's
## position (DirectionalLight3D rotation/color/energy) and the sky/fog
## colors that go with it -- per direct instruction. 1 real minute = 1
## game hour (a full 24-hour game day takes 24 real minutes); the game
## starts at 15:00 (3pm). Sunrise/sunset (6am/6pm) are authored directly
## as keyframes below, not derived from real solar geometry -- this is a
## stylized game clock, not a simulation.
##
## Also folds in the fix for the sky reading as washed-out/pale rather
## than a vibrant blue: fog_sky_affect (previously reduced to 0.15, still
## visibly muting it) is now 0.0 -- fog no longer blends over the sky at
## all, only fading distant geometry the way it's meant to -- and the
## DAY keyframe's own sky colors are pushed more saturated than the old
## static values were.

const GAME_HOURS_PER_REAL_SECOND := 1.0 / 60.0
const START_HOUR := 15.0

## Each entry: game hour, sky top/horizon color, sun color/energy, fog
## color, the sun's elevation angle (radians above the horizon, negative =
## below it), and "night" (0..1, how deep into night we are -- drives
## everything that should only read as active after dark: cloud tinting,
## the starfield, and lantern glow). Interpolated (smoothstep-eased)
## between whichever two keyframes bracket the current game hour, cycling
## continuously -- the list wraps from the last entry back to the first,
## 24 hours later. Azimuth (which way the sun currently is, compass-wise)
## isn't a keyframe value -- it sweeps continuously at a constant rate
## across the whole cycle, independent of these.
## Per direct report, night both lasted too long and read as far too dark.
## Two independent fixes: sunset/sunrise moved from 18:00/6:00 to 20:00/5:00
## -- since elevation only ever dips below the horizon between those two
## keyframes, shifting them closer together shrinks true night (sun below
## the horizon) from a full 12 hours down to 9, with day correspondingly
## longer (15 hours). Separately, the deepest-night keyframe's own
## brightness values (sun_energy, sky/fog colors) are all raised well off
## their old near-black values -- still clearly darker than day, but no
## longer reading as pitch black. The environment's ambient light is sky-
## sourced (see main.tscn's WorldEnvironment, which sets no explicit
## ambient_light_* override), so brightening the night sky colors here also
## raises the scene's overall ambient floor, not just the direct sun light.
const KEYFRAMES := [
	{
		"hour": 0.5,  # deepest point of the night (halfway between sunset and sunrise)
		"sky_top": Color(0.06, 0.08, 0.17),
		"sky_horizon": Color(0.1, 0.12, 0.22),
		"sun_color": Color(0.45, 0.5, 0.66),
		"sun_energy": 0.18,
		"fog_color": Color(0.08, 0.09, 0.18),
		"elevation": deg_to_rad(-35.0),
		"night": 1.0,
	},
	{
		"hour": 5.0,  # sunrise in the east (+X)
		"sky_top": Color(0.35, 0.45, 0.75),
		"sky_horizon": Color(0.95, 0.62, 0.42),
		"sun_color": Color(1.0, 0.75, 0.5),
		"sun_energy": 0.6,
		"fog_color": Color(0.9, 0.7, 0.55),
		"elevation": 0.0,
		"night": 0.0,
	},
	{
		"hour": 12.0,  # solar noon, with the sun due south (+Z)
		"sky_top": Color(0.12, 0.52, 0.96),
		"sky_horizon": Color(0.48, 0.76, 0.98),
		"sun_color": Color(1.0, 0.98, 0.93),
		"sun_energy": 1.15,
		"fog_color": Color(0.72, 0.87, 0.98),
		"elevation": deg_to_rad(75.0),
		"night": 0.0,
	},
	{
		"hour": 20.0,  # sunset in the west (-X)
		"sky_top": Color(0.3, 0.25, 0.55),
		"sky_horizon": Color(0.95, 0.45, 0.26),
		"sun_color": Color(1.0, 0.55, 0.3),
		"sun_energy": 0.55,
		"fog_color": Color(0.85, 0.55, 0.4),
		"elevation": 0.0,
		"night": 0.0,
	},
]

## How far away the moon disc sits, and how big it is at that distance.
## Kept inside distant_mountains.gd's RADIUS (950) rather than pushed
## beyond it -- see star_field.gd's docstring: this project's regular
## distance fog would otherwise mute a pale, far-away disc down to almost
## nothing by the time it reaches the camera.
const MOON_DISTANCE := 900.0
const MOON_RADIUS := 32.0
const MOON_COLOR := Color(0.88, 0.9, 0.86)

## Lantern light/glow energy at full night vs. full day (see LANTERN_GROUP
## below) -- lanterns still glow faintly by day rather than looking dead,
## per build_lantern()'s original always-on emissive material.
const LANTERN_LIGHT_ENERGY_NIGHT := 2.5
const LANTERN_LIGHT_ENERGY_DAY := 0.0
const LANTERN_EMISSION_NIGHT := 1.4
const LANTERN_EMISSION_DAY := 0.25
const LANTERN_GROUP := "lanterns"

var game_time_hours: float = START_HOUR

@onready var _light: DirectionalLight3D = get_node("../DirectionalLight3D")
@onready var _world_environment: WorldEnvironment = get_node("../WorldEnvironment")
@onready var _clouds: CloudScatter = get_node("../Clouds")
var _environment: Environment
var _sky_material: ProceduralSkyMaterial
var _moon: MeshInstance3D
var _moon_material: StandardMaterial3D
var _star_field: StarField
var _lanterns: Array[Node] = []
var _lantern_refresh_timer := 0.0


func _ready() -> void:
	# The clock is gameplay simulation, never UI. Keep this explicit rather
	# than inheriting a future scene-root process mode that might continue
	# during pause for menu or transition purposes.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	game_time_hours = WorldState.game_time_hours
	_environment = _world_environment.environment
	_sky_material = _environment.sky.sky_material as ProceduralSkyMaterial
	# See this file's own docstring -- fog no longer touches the sky at all.
	_environment.fog_sky_affect = 0.0
	_build_moon()
	_star_field = StarField.new()
	# Deferred, not called directly -- this _ready() can run while the parent
	# (the main scene root) is still synchronously working through its own
	# children's _ready() calls, and add_child() on a node in that state
	# fails outright (see the identical fix just below in _build_moon()).
	get_parent().add_child.call_deferred(_star_field)
	_apply_time()


func _build_moon() -> void:
	var mesh := SphereMesh.new()
	mesh.radius = MOON_RADIUS
	mesh.height = MOON_RADIUS * 2.0
	mesh.radial_segments = 24
	mesh.rings = 12

	# Plain unshaded StandardMaterial3D, not a custom shader -- see
	# star_field.gd's own docstring for why: a first attempt at both the
	# moon and the starfield used hand-written .gdshader files and neither
	# rendered anything, with no console errors to diagnose from. This is
	# the same recipe cloud_scatter.gd/town_props.gd's lantern glow use.
	_moon_material = StandardMaterial3D.new()
	_moon_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_moon_material.albedo_color = MOON_COLOR
	_moon_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_moon_material.emission_enabled = true
	_moon_material.emission = MOON_COLOR
	_moon_material.emission_energy_multiplier = 0.6

	_moon = MeshInstance3D.new()
	_moon.mesh = mesh
	_moon.material_override = _moon_material
	_moon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Deferred -- see _ready()'s own identical comment on _star_field.
	get_parent().add_child.call_deferred(_moon)


func _process(delta: float) -> void:
	# PROCESS_MODE_PAUSABLE normally prevents this callback altogether while
	# paused. The guard is also an authoritative safety net: no menu, full-pause
	# story dialog, or future process-mode change may advance the shared clock.
	if get_tree().paused:
		return
	game_time_hours = fmod(game_time_hours + delta * GAME_HOURS_PER_REAL_SECOND, 24.0)
	WorldState.game_time_hours = game_time_hours
	_lantern_refresh_timer -= delta
	if _lantern_refresh_timer <= 0.0:
		# City blocks can stream in/out after this node is ready. Cache the
		# group rather than allocating/scanning it every rendered frame.
		_lanterns.assign(get_tree().get_nodes_in_group(LANTERN_GROUP))
		_lantern_refresh_timer = 1.0
	_apply_time()


func _apply_time() -> void:
	var kf := _blend_keyframes(game_time_hours)
	var elevation: float = kf["elevation"]
	# World-space compass convention, verified in the playable scene: +X is
	# east and -Z is north. This puts the sun due east at 06:00, due south
	# (+Z) at noon, and due west at 18:00.
	var azimuth := ((12.0 - game_time_hours) / 24.0) * TAU

	# The sun's direction as seen from the scene (unit vector pointing UP
	# toward wherever the sun currently is) -- standard elevation/azimuth
	# spherical coordinates, elevation=0 at the horizon, positive up.
	var sun_dir := Vector3(
		cos(elevation) * sin(azimuth), sin(elevation), cos(elevation) * cos(azimuth)
	)
	# DirectionalLight3D shines along its own local -Z (a documented Godot
	# fact, not something guessed) -- look_at() points -Z at the given
	# target, so aiming it at (position - sun_dir) makes -Z point in the
	# -sun_dir direction: light rays traveling down and away from the
	# sun's own position, which is exactly a light source AT sun_dir
	# shining toward the scene.
	_light.look_at(_light.global_position - sun_dir, Vector3.UP)
	_light.light_color = kf["sun_color"]
	_light.light_energy = kf["sun_energy"]

	_sky_material.sky_top_color = kf["sky_top"]
	_sky_material.sky_horizon_color = kf["sky_horizon"]
	_sky_material.ground_horizon_color = kf["sky_horizon"]

	_environment.fog_light_color = kf["fog_color"]

	var night_factor: float = kf["night"]
	_clouds.set_night_factor(night_factor)
	_star_field.set_night_factor(night_factor)
	_apply_moon(sun_dir)
	_apply_lanterns(night_factor)


func _apply_moon(sun_dir: Vector3) -> void:
	# The moon rides directly opposite the sun -- as the sun sets in one
	# direction, the moon rises in the other, sweeping the same continuous
	# azimuth the sun does. Not real astronomy, just a stylized game clock
	# (see this file's own docstring).
	var moon_dir := -sun_dir
	_moon.position = moon_dir * MOON_DISTANCE
	# Fades in/out right as it crosses the horizon instead of popping, and
	# means it doesn't need to rely on terrain geometry to hide it below
	# ground -- terrain doesn't necessarily extend out to MOON_DISTANCE.
	var visibility := smoothstep(-0.05, 0.05, moon_dir.y)
	_moon_material.albedo_color.a = visibility


func _apply_lanterns(night_factor: float) -> void:
	var light_energy := lerpf(LANTERN_LIGHT_ENERGY_DAY, LANTERN_LIGHT_ENERGY_NIGHT, night_factor)
	var emission_energy := lerpf(LANTERN_EMISSION_DAY, LANTERN_EMISSION_NIGHT, night_factor)
	for lantern in _lanterns:
		if not is_instance_valid(lantern) or not lantern.is_visible_in_tree():
			continue
		# City apartment fixtures join this group for their emissive night
		# treatment, but only gain a real OmniLight3D when CityGenerator's
		# nearby-room LOD activates them. Village lanterns have one from the
		# start. Treat that physical light as optional so a distant fixture
		# never becomes a null-instance assignment.
		var light := lantern.get_node_or_null("Light") as OmniLight3D
		if light != null:
			light.light_energy = light_energy
		var head := lantern.get_node_or_null("Head") as MeshInstance3D
		if head == null:
			continue
		var head_material := head.get_surface_override_material(0) as StandardMaterial3D
		if head_material != null:
			head_material.emission_energy_multiplier = emission_energy


func _blend_keyframes(hour: float) -> Dictionary:
	var base_hour: float = KEYFRAMES[0]["hour"]
	var h := fposmod(hour - base_hour, 24.0) + base_hour
	var count := KEYFRAMES.size()
	for i in count:
		var a: Dictionary = KEYFRAMES[i]
		var is_last := i == count - 1
		var b: Dictionary = KEYFRAMES[0] if is_last else KEYFRAMES[i + 1]
		var a_hour: float = a["hour"]
		var b_hour: float = (float(b["hour"]) + 24.0) if is_last else float(b["hour"])
		if h < b_hour:
			var t := clampf((h - a_hour) / (b_hour - a_hour), 0.0, 1.0)
			return _lerp_keyframe(a, b, smoothstep(0.0, 1.0, t))
	return KEYFRAMES[0]


func _lerp_keyframe(a: Dictionary, b: Dictionary, t: float) -> Dictionary:
	return {
		"sky_top": (a["sky_top"] as Color).lerp(b["sky_top"], t),
		"sky_horizon": (a["sky_horizon"] as Color).lerp(b["sky_horizon"], t),
		"sun_color": (a["sun_color"] as Color).lerp(b["sun_color"], t),
		"sun_energy": lerpf(a["sun_energy"], b["sun_energy"], t),
		"fog_color": (a["fog_color"] as Color).lerp(b["fog_color"], t),
		"elevation": lerpf(a["elevation"], b["elevation"], t),
		"night": lerpf(a["night"], b["night"], t),
	}
