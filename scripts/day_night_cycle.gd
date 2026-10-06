extends Node

## Drives a full day/night cycle from a single game clock -- the sun's
## position (DirectionalLight3D rotation/color/energy) and the sky/fog
## colors that go with it -- per direct instruction. 1 real minute = 1
## game hour (a full 24-hour game day takes 24 real minutes); the game
## starts in the morning (WorldState.MORNING_HOUR), so a fresh session has a
## whole day of light ahead of it. Sunrise/sunset (6am/6pm) are authored directly
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

## Leave negative to inherit the persistent shared world clock. Purpose-built
## test/demo scenes may set an explicit starting hour without changing how
## ordinary kingdom travel preserves time of day.
@export_range(-1.0, 23.99, 0.01) var initial_time_override := -1.0
## Shared planetary backdrop configuration. Individual worlds only choose the
## sea altitude and planet centre; construction and rendering stay universal.
@export var planetary_ocean_enabled := true
@export var planetary_ocean_level := -25.0
@export var planetary_ocean_center := Vector2.ZERO

## Shared ambient floor. Direct sunlight still provides the strong daytime
## modelling, while this keeps shadowed faces and unlit terrain readable.
## At night it becomes brighter and distinctly blue, giving the world a
## cinematic moonlit exposure without pretending the sun is still up.
@export var day_ambient_color := Color(0.74, 0.82, 0.94)
@export_range(0.0, 2.0, 0.01) var day_ambient_energy := 0.42
@export var night_ambient_color := Color(0.32, 0.46, 0.78)
@export_range(0.0, 2.0, 0.01) var night_ambient_energy := 0.72

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

## Lantern light/glow energy at full night vs. full day (see LANTERN_GROUP
## below) -- lanterns still glow faintly by day rather than looking dead,
## per build_lantern()'s original always-on emissive material.
const LANTERN_LIGHT_ENERGY_NIGHT := 2.5
const LANTERN_LIGHT_ENERGY_DAY := 0.0
const LANTERN_EMISSION_NIGHT := 1.4
const LANTERN_EMISSION_DAY := 0.25
const LANTERN_GROUP := "lanterns"

var game_time_hours: float = WorldState.MORNING_HOUR

@onready var _light: DirectionalLight3D = get_node("../DirectionalLight3D")
@onready var _world_environment: WorldEnvironment = get_node("../WorldEnvironment")
var _environment: Environment
var _sky_material: ProceduralSkyMaterial
var _celestial_shell: CelestialShell
var _lanterns: Array[Node] = []
## How often the sky, fog, clouds and lanterns are re-tinted: about fifteen
## times a second, against a day that takes minutes to pass.
const PRESENTATION_INTERVAL := 1.0 / 15.0
var _presentation_timer := 0.0
var _cloud_scatters: Array[Node] = []
var _cloud_refresh_timer := 0.0
var _lantern_refresh_timer := 0.0
var _base_fog_enabled := false
var _base_fog_density := 0.0
var _base_fog_depth_begin := 0.0
var _base_fog_depth_end := 0.0


func _ready() -> void:
	# The clock is gameplay simulation, never UI. Keep this explicit rather
	# than inheriting a future scene-root process mode that might continue
	# during pause for menu or transition purposes.
	process_mode = Node.PROCESS_MODE_PAUSABLE
	if initial_time_override >= 0.0:
		WorldState.game_time_hours = fposmod(initial_time_override, 24.0)
	game_time_hours = WorldState.game_time_hours
	_environment = _world_environment.environment
	_base_fog_enabled = _environment.fog_enabled
	_base_fog_density = _environment.fog_density
	_base_fog_depth_begin = _environment.fog_depth_begin
	_base_fog_depth_end = _environment.fog_depth_end
	_sky_material = _environment.sky.sky_material as ProceduralSkyMaterial
	# Use one predictable shared ambient source in every kingdom. Depending on
	# the procedural sky radiance alone made the night exposure vary with each
	# world's authored sky palette and left the Crossroads nearly black.
	_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_environment.ambient_light_sky_contribution = 0.22
	# See this file's own docstring -- fog no longer touches the sky at all.
	_environment.fog_sky_affect = 0.0
	_celestial_shell = CelestialShell.new()
	_celestial_shell.name = "CelestialShell"
	# Deferred, not called directly -- this _ready() can run while the parent
	# (the main scene root) is still synchronously working through its own
	# children's _ready() calls, and add_child() on a node in that state fails.
	get_parent().add_child.call_deferred(_celestial_shell)
	call_deferred("_ensure_planetary_ocean")
	_apply_time()


func _ensure_planetary_ocean() -> void:
	if not planetary_ocean_enabled:
		return
	var world := get_parent()
	# A world may author a special exclusion (the demo's playable lake does).
	# Respect that configured shared instance rather than layering a duplicate.
	if world.find_child("SphericalWorldOcean", true, false) != null:
		return
	var ocean := PlanetaryOcean.new()
	ocean.surface_level = planetary_ocean_level
	ocean.planet_center = planetary_ocean_center
	world.add_child(ocean)


func _process(delta: float) -> void:
	# PROCESS_MODE_PAUSABLE normally prevents this callback altogether while
	# paused. The guard is also an authoritative safety net: no menu, full-pause
	# story dialog, or future process-mode change may advance the shared clock.
	if get_tree().paused:
		return
	var previous_hour := game_time_hours
	game_time_hours = fmod(game_time_hours + delta * GAME_HOURS_PER_REAL_SECOND, 24.0)
	if game_time_hours < previous_hour:
		WorldState.calendar_day += 1
	WorldState.game_time_hours = game_time_hours
	# The clock advances every frame; the PRESENTATION of it does not need to.
	# Re-tinting the sky, the fog, every cloud field and every lantern sixty
	# times a second buys nothing the eye can see over a day lasting minutes,
	# and dirtying the sky material each frame forces its radiance to be
	# rebuilt continuously.
	_presentation_timer -= delta
	if _presentation_timer > 0.0:
		return
	_presentation_timer = PRESENTATION_INTERVAL
	_lantern_refresh_timer -= delta
	if _lantern_refresh_timer <= 0.0:
		# City blocks can stream in/out after this node is ready. Cache the
		# group rather than allocating/scanning it every rendered frame.
		_lanterns.assign(get_tree().get_nodes_in_group(LANTERN_GROUP))
		_lantern_refresh_timer = 1.0
	_apply_time()


func _apply_time() -> void:
	var kf := _blend_keyframes(game_time_hours)
	var space_factor := 0.0
	var atmosphere := AtmosphereLayer.active(get_tree())
	var active_camera := get_viewport().get_camera_3d()
	if atmosphere != null and active_camera != null:
		space_factor = atmosphere.sky_darkening_at(active_camera.global_position)
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

	var space_black := Color(0.002, 0.001, 0.008)
	var planet_limb_glow := Color(0.055, 0.022, 0.10)
	var planet_nightside := Color(0.010, 0.006, 0.025)
	_sky_material.sky_top_color = (kf["sky_top"] as Color).lerp(space_black, space_factor)
	_sky_material.sky_horizon_color = (kf["sky_horizon"] as Color).lerp(space_black, space_factor)
	# The lower hemisphere is empty sky behind the separately rendered ocean
	# planet. In space it becomes a restrained violet atmospheric limb rather
	# than retaining a flat ocean-blue background or blacking out the planet.
	_sky_material.ground_horizon_color = (kf["sky_horizon"] as Color).lerp(planet_limb_glow, space_factor)
	_sky_material.ground_bottom_color = (kf["sky_top"] as Color).darkened(0.35).lerp(planet_nightside, space_factor)

	_environment.fog_light_color = (kf["fog_color"] as Color).lerp(space_black, space_factor)
	_environment.fog_density = lerpf(_base_fog_density, 0.0, space_factor)
	# Depth fog gives the long demo course controlled atmospheric perspective
	# without reducing nearby visibility. As the camera leaves the atmosphere,
	# move that distance band smoothly beyond the visible world as well as
	# fading its maximum intensity; at full vacuum disable it altogether.
	if _environment.fog_mode == Environment.FOG_MODE_DEPTH:
		var depth_clearance_scale := 1.0 / maxf(1.0 - space_factor, 0.01)
		_environment.fog_depth_begin = _base_fog_depth_begin * depth_clearance_scale
		_environment.fog_depth_end = _base_fog_depth_end * depth_clearance_scale
	_environment.fog_enabled = _base_fog_enabled and space_factor < 0.999

	var night_factor: float = kf["night"]
	# Preserve enough fill light to read silhouettes, terrain contours and
	# character colors after sunset. Fade it away with the atmosphere in space;
	# vacuum should not inherit a terrestrial blue ambient wash.
	_environment.ambient_light_color = day_ambient_color.lerp(night_ambient_color, night_factor)
	_environment.ambient_light_energy = lerpf(
		day_ambient_energy, night_ambient_energy, night_factor
	) * lerpf(1.0, 0.06, space_factor)
	# DemoWorld has both ordinary valley clouds and a separate Air-zone layer.
	# Both are CloudScatter instances and must share the same lighting state.
	# Cached like the lanterns already are: this allocated a fresh array of
	# the whole group every single frame.
	if _cloud_refresh_timer <= 0.0:
		_cloud_scatters.assign(get_tree().get_nodes_in_group("cloud_scatters"))
		_cloud_refresh_timer = 1.0
	_cloud_refresh_timer -= PRESENTATION_INTERVAL
	for cloud_scatter in _cloud_scatters:
		if cloud_scatter is CloudScatter:
			(cloud_scatter as CloudScatter).set_night_factor(night_factor)
	_celestial_shell.set_presentation(sun_dir, maxf(night_factor, space_factor))
	_apply_lanterns(night_factor)


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
