extends Node3D

## Reproducible, in-engine source for the title photograph.  Run with:
##   Godot --path . --resolution 1920x1080 scenes/start_screen_photoshoot.tscn -- --capture-start-background
## The baked PNG is what the lightweight title scene loads; the game world and
## all of its procedural systems therefore remain unloaded until Play Demo.

const OUTPUT_PATH := "res://assets/ui/start_background.png"
const MANCHEGO_SCENE := preload("res://scenes/manchego.tscn")
const PANDY_SCENE := preload("res://scenes/pandy.tscn")
const DA_HOU_ZI_SCENE := preload("res://scenes/ape_template_preview.tscn")
const DA_HOU_ZI_CONFIG := preload("res://scripts/primate_kingdom_gorilla.gd")
# Exact ordinary Crossroads grass used by TerrainGenerator._height_color().
# The photograph should inherit its identity, not approximate it with a
# darker cinematic green; the golden-hour lighting supplies the variation.
const CROSSROADS_GRASS := Color(0.07451, 0.63922, 0.40392)
const BLORB_ELEMENTS := [
	"water", "fire", "electric", "rock", "ground", "air", "plant",
	"psychic", "city", "ice", "snow", "wood", "space", "shiny", "normal",
]
const PARTY_BLORB_SCALE := 1.0
# Screen-left projected onto the ground plane for the final art-directed
# camera (after its requested rightward yaw). Keep all "camera left" staging
# notes in this shared direction rather than confusing them with world -X.
const PHOTO_CAMERA_LEFT_XZ := Vector2(-0.936, 0.352)
# Where the camera starts (see _ready()) before its move toward the hero; only
# its ground-plane position matters here, for "away from the camera" staging.
const PHOTO_CAMERA_START_XZ := Vector2(1.45, 11.80)
# How far Blorbus has been pushed further from the camera, in metres.
const BLORBUS_PULL_BACK := 1.2

var _rng := RandomNumberGenerator.new()
var _terrain_noise := FastNoiseLite.new()
var _terrain_detail_noise := FastNoiseLite.new()
var _flora_noise := FastNoiseLite.new()
var _grove_noise := FastNoiseLite.new()
## Approximate ground-plane footprints for every staged subject. Foliage is
## generated last and rejects these areas; Blorbs also reject one another and
## the named party instead of merely hoping seeded coordinates do not overlap.
var _occupied_footprints: Array[Dictionary] = []


class PhotoTerrain:
	extends Node
	var source: Node
	func get_mesh_height(x: float, z: float) -> float:
		return source._ground_height(x, z)


class PhotoPlayer:
	extends Node3D
	var move_speed := 5.5


func _ready() -> void:
	_rng.seed = 0xE1EB10B
	_configure_photo_noise()
	# A few companion scenes resolve these siblings as part of their ordinary
	# runtime setup. Lightweight stand-ins keep the photograph using the actual
	# character scenes without booting gameplay or emitting missing-node errors.
	var terrain := PhotoTerrain.new()
	terrain.name = "Terrain"
	terrain.source = self
	add_child(terrain)
	var player_reference := PhotoPlayer.new()
	player_reference.name = "Player"
	add_child(player_reference)
	_build_rolling_ground()
	_build_distant_titans()
	_build_hero()
	_build_named_party()
	# Establish the grove before the procedural Blorb crowd so the crowd flows
	# around it. Building it afterward caused footprint rejection to silently
	# reduce a seven-tree grove to a single surviving fruit tree.
	_build_visible_fruit_grove()
	_build_blorb_party()
	_build_foliage()
	_build_clouds()
	var camera := get_node("Camera3D") as Camera3D
	# Close, low hero framing; the party remains environmental context rather
	# than competing with the runner for the foreground focal plane.
	# Keep the entire literal run-cycle silhouette, but let the hero occupy the
	# dominant foreground scale expected of a title photograph.
	camera.position = Vector3(1.45, 0.68, 11.80)
	var player_focus := Vector3(-2.35, _ground_height(-2.35, 8.45) + 1.0, 8.45)
	var original_aim := Vector3(-0.95, player_focus.y, 8.45)
	var original_view_direction := (original_aim - camera.position).normalized()
	# Requested photographic adjustment, expressed as camera motion rather than
	# moving any subject: two metres toward the player, then 15 degrees right
	# yaw and 15 degrees upward pitch.
	camera.position += (player_focus - camera.position).normalized() * 2.0
	var adjusted_view_direction := original_view_direction.rotated(
		Vector3.UP, deg_to_rad(-15.0)
	)
	var camera_right := adjusted_view_direction.cross(Vector3.UP).normalized()
	adjusted_view_direction = adjusted_view_direction.rotated(
		camera_right, deg_to_rad(15.0)
	)
	camera.look_at(camera.position + adjusted_view_direction, Vector3.UP)
	if "--capture-start-background" in OS.get_cmdline_user_args():
		_capture_when_ready.call_deferred()


func _capture_when_ready() -> void:
	# Let materials, the environment and viewport finish at least two complete
	# draw cycles before reading the back buffer.
	for _frame in 6:
		await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Start-screen photo shoot produced no viewport image")
		get_tree().quit(1)
		return
	image.resize(1920, 1080, Image.INTERPOLATE_LANCZOS)
	var error := image.save_png(OUTPUT_PATH)
	if error != OK:
		push_error("Could not save start-screen photograph: %s" % error_string(error))
		get_tree().quit(1)
		return
	print("Saved start-screen photograph to %s" % OUTPUT_PATH)
	get_tree().quit()


func _ground_height(x: float, z: float) -> float:
	var rolling := (
		_terrain_noise.get_noise_2d(x, z) * 1.9
		+ _terrain_detail_noise.get_noise_2d(x, z) * 0.42
	)
	# A deliberately low camera can otherwise land inside a positive noise
	# crest. Blend a shallow swale immediately around the lens, then hand the
	# surface smoothly back to the untouched rolling field before the hero.
	var camera_distance := Vector2(x, z).distance_to(Vector2(1.45, 11.80))
	var camera_clearance := 1.0 - smoothstep(0.0, 4.2, camera_distance)
	rolling = lerpf(rolling, -0.62, camera_clearance)
	return rolling + clampf((4.0 - z) * 0.07, -0.28, 2.35)


func _configure_photo_noise() -> void:
	_terrain_noise.seed = 0x71E221
	_terrain_noise.frequency = 0.045
	_terrain_noise.fractal_octaves = 3
	_terrain_noise.fractal_gain = 0.46
	_terrain_detail_noise.seed = 0xD37A11
	_terrain_detail_noise.frequency = 0.14
	_terrain_detail_noise.fractal_octaves = 2
	_flora_noise.seed = 0xF10A42
	_flora_noise.frequency = 0.075
	_flora_noise.fractal_octaves = 3
	_grove_noise.seed = 0xF8A177
	_grove_noise.frequency = 0.038
	_grove_noise.fractal_octaves = 2


func _build_rolling_ground() -> void:
	const X_SEGMENTS := 180
	const Z_SEGMENTS := 300
	const X_MIN := -130.0
	const X_MAX := 130.0
	const Z_MIN := -390.0
	const Z_MAX := 17.0
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for z_index in Z_SEGMENTS + 1:
		var z := lerpf(Z_MIN, Z_MAX, float(z_index) / Z_SEGMENTS)
		for x_index in X_SEGMENTS + 1:
			var x := lerpf(X_MIN, X_MAX, float(x_index) / X_SEGMENTS)
			var y := _ground_height(x, z)
			var dx := (
				_ground_height(x + 0.08, z) - _ground_height(x - 0.08, z)
			) / 0.16
			var dz := (
				_ground_height(x, z + 0.08) - _ground_height(x, z - 0.08)
			) / 0.16
			vertices.append(Vector3(x, y, z))
			normals.append(Vector3(-dx, 1.0, -dz).normalized())
			colors.append(CROSSROADS_GRASS)
	for z_index in Z_SEGMENTS:
		for x_index in X_SEGMENTS:
			var a := z_index * (X_SEGMENTS + 1) + x_index
			var b := a + 1
			var c := a + X_SEGMENTS + 1
			var d := c + 1
			# Godot treats clockwise winding as the visible front face.  The old
			# a-c-b order had an upward geometric cross product but was therefore
			# culled when viewed from above: hills appeared transparent and exposed
			# party members behind/under them. Keep the authored upward normals, but
			# wind the rendered top face according to Godot's convention.
			indices.append_array(PackedInt32Array([a, b, c, b, d, c]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	# The vertex normals are analytically derived from the height field and the
	# triangle winding below faces upward. Do not self-illuminate this surface:
	# even a modest emission term filled the sun's occluded side and made every
	# character appear to cast no ground shadow.
	material.metallic = 0.0
	material.roughness = 1.0
	material.emission_enabled = false
	material.cull_mode = BaseMaterial3D.CULL_BACK
	var ground := MeshInstance3D.new()
	ground.name = "CrossroadsRollingGround"
	ground.mesh = mesh
	ground.material_override = material
	add_child(ground)


func _build_hero() -> void:
	var hero := Node3D.new()
	hero.name = "RunningHero"
	hero.position = Vector3(-2.35, _ground_height(-2.35, 8.45), 8.45)
	# Aim the actual run toward the lens. The prior -13 degree yaw faced past
	# the camera and made this read chiefly as a side-on running profile.
	var camera_position := Vector3(1.45, 0.68, 11.80)
	var toward_camera := Vector2(
		camera_position.x - hero.position.x,
		camera_position.z - hero.position.z
	)
	# Three-quarter rather than dead-on: close enough to engage the camera,
	# angled enough that the frozen running stride retains depth and direction.
	hero.rotation.y = atan2(toward_camera.x, toward_camera.y) - deg_to_rad(12.0)
	_reserve_footprint(Vector2(hero.position.x, hero.position.z), 1.15)
	add_child(hero)
	var pivots := ProceduralFigure.build(
		hero,
		ProceduralFigure.SKIN_COLOR,
		Player.SHIRT_COLOR,
		Player.PANTS_COLOR,
		ProceduralFigure.SLEEVE_STYLE_SHORT,
		Player.HEIGHT_SCALE,
		1.0,
		1.0,
		Player.ABDOMEN_WIDTH_SCALE,
		Player.CHEST_EMBLEM_COLOR,
		Player.HAIR_COLOR,
		FigureHair.STYLE_HERO,
		0.0,
		Player.SHOE_COLOR
	)
	# Freeze a literal frame of Player's current sprint cycle, near the fully
	# extended stride where its silhouette reads most clearly in a still.
	Player.apply_run_cycle_snapshot(pivots, 0.95, 1.0)
	(pivots["thorax"] as Node3D).rotation.y = deg_to_rad(5.0)
	(pivots["head"] as Node3D).rotation.y = deg_to_rad(-3.0)


func _build_blorb_party() -> void:
	# One continuous following crowd. The modal may cover some central figures,
	# but the photograph itself must never read as two unrelated processions.
	# Reserve the Lava Blorb's visible right-shoulder position first. Building
	# it after the general crowd without this reservation let collision solving
	# push this required representative back beneath the modal.
	# Guaranteed unobscured Fire/Lava representative. The cyclic crowd still
	# contains every element, but this one cannot land behind the centre modal.
	var lava_position := Vector2(-7.25, 2.35)
	_reserve_footprint(lava_position, Blorb.RADIUS * PARTY_BLORB_SCALE)
	# Blorbus replaces the follower position nearest the hero. Reserving it
	# before the crowd makes that nearby slot unequivocally his; the ordinary
	# Blorb that would have occupied it is retained and collision-resolved into
	# the surrounding army, so population never decreases.
	var blorbus_near_position := Vector2(-3.85, 5.65)
	var player_xz := Vector2(-2.35, 8.45)
	var blorbus_desired := (
		blorbus_near_position
		+ (blorbus_near_position - player_xz).normalized() * 1.0
	)
	# Art direction: Blorbus sits BLORBUS_PULL_BACK further from the camera,
	# along the camera-to-Blorbus line on the ground plane.
	blorbus_desired += (blorbus_desired - PHOTO_CAMERA_START_XZ).normalized() * BLORBUS_PULL_BACK
	var blorbus_position := _find_clear_party_position(blorbus_desired, Blorb.RADIUS)
	_reserve_footprint(blorbus_position, Blorb.RADIUS)
	# Element colors identify types, not named duplicates. Give every element
	# exactly one representative; the remainder of the army are ordinary
	# Blorbs. The sole Psychic representative can read as Blorbaka, while the
	# sole pink named-color representative below is Blorbus.
	var representatives: Array = BLORB_ELEMENTS.duplicate()
	representatives.erase("fire") # The staged Lava/Fire representative is below.
	representatives.erase("normal")
	var repeatable_elements: Array = BLORB_ELEMENTS.duplicate()
	# Blorbaka is the only Psychic representative. Every other ordinary or
	# elemental type may repeat to preserve the full fifty-member crowd.
	repeatable_elements.erase("psychic")
	for index in 50:
		var row := int(index / 10)
		var across_row := index % 10
		var x := -9.0 + float(across_row) * 2.0
		x += _rng.randf_range(-0.2, 0.2)
		var z := 2.0 - float(row) * 2.35 + _rng.randf_range(-0.14, 0.14)
		var element := (
			String(representatives[index])
			if index < representatives.size()
			else String(repeatable_elements[(index - representatives.size()) % repeatable_elements.size()])
		)
		var color := _photo_blorb_color(element)
		var clear := _find_clear_party_position(Vector2(x, z), Blorb.RADIUS * PARTY_BLORB_SCALE)
		_build_blorb(
			Vector3(clear.x, _ground_height(clear.x, clear.y), clear.y),
			color, PARTY_BLORB_SCALE
		)
	# The Lava Blorb sits on the visible right shoulder of the composition,
	# clear of the menu's central exclusion zone and of the named companions.
	_build_blorb(
		Vector3(
			lava_position.x, _ground_height(lava_position.x, lava_position.y),
			lava_position.y
		),
		ElementPalette.body_color("fire"), PARTY_BLORB_SCALE
	)
	_build_blorb(
		Vector3(
			blorbus_position.x,
			_ground_height(blorbus_position.x, blorbus_position.y),
			blorbus_position.y
		),
		Blorb.BLORBUS_BODY_COLOR, PARTY_BLORB_SCALE
	)


static func _photo_blorb_color(element: String) -> Color:
	if element == "normal":
		return Color(0.94, 0.96, 0.93)
	if element == "shiny":
		return Blorb.SHINY_BODY_COLOR
	return ElementPalette.body_color(element)


func _build_named_party() -> void:
	# The three recognizable companions occupy the front of the crowd, close
	# enough to read clearly without competing with the hero's silhouette.
	var xiao_hou_zi := Node3D.new()
	xiao_hou_zi.name = "PhotoXiaoHouZi"
	var xiao_xz := Vector2(3.1, 0.55) + PHOTO_CAMERA_LEFT_XZ * 0.3
	xiao_hou_zi.position = Vector3(
		xiao_xz.x, _ground_height(xiao_xz.x, xiao_xz.y), xiao_xz.y
	)
	_reserve_footprint(Vector2(xiao_hou_zi.position.x, xiao_hou_zi.position.z), 0.75)
	var xiao_to_hero := Vector2(-2.35 - xiao_hou_zi.position.x, 8.45 - xiao_hou_zi.position.z)
	xiao_hou_zi.rotation.y = atan2(xiao_to_hero.x, xiao_to_hero.y)
	add_child(xiao_hou_zi)
	var monkey_pivots := MonkeyFigure.build(
		xiao_hou_zi, MonkeyFigure.MONKEY_FUR_COLOR, XiaoHouZi.DISPLAY_SCALE
	)
	# Xiao's limbs are continuous tubes rebuilt from his live joint pivots.
	# Applying the human snapshot without re-lofting those tubes left the old
	# meshes behind while the joints moved, visibly detaching both legs.
	var monkey_phase := 1.12
	var monkey_swing := sin(monkey_phase) * XiaoHouZi.WALK_SWING_AMOUNT
	(monkey_pivots["leg_left"] as Node3D).rotation.x = monkey_swing
	(monkey_pivots["leg_right"] as Node3D).rotation.x = -monkey_swing
	(monkey_pivots["arm_left"] as Node3D).rotation.x = -monkey_swing
	(monkey_pivots["arm_right"] as Node3D).rotation.x = monkey_swing
	MonkeyFigure.rebuild_limbs(
		monkey_pivots, monkey_pivots["_rig"] as Node3D, 0.0
	)

	var manchego := MANCHEGO_SCENE.instantiate() as Node3D
	manchego.name = "PhotoManchego"
	var manchego_requested := Vector2(5.2, -0.85) + PHOTO_CAMERA_LEFT_XZ * 4.0
	var manchego_xz := _find_clear_party_position(manchego_requested, 1.25)
	manchego.position = Vector3(
		manchego_xz.x, _ground_height(manchego_xz.x, manchego_xz.y), manchego_xz.y
	)
	_reserve_footprint(Vector2(manchego.position.x, manchego.position.z), 1.25)
	# HorseFigure shares the humanoid +Z forward convention.
	var horse_to_hero := Vector2(-2.35 - manchego.position.x, 8.45 - manchego.position.z)
	manchego.rotation.y = atan2(horse_to_hero.x, horse_to_hero.y)
	manchego.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(manchego)
	manchego.call("_animate_gait", 0.10, true, true)

	var pandy := PANDY_SCENE.instantiate() as Node3D
	pandy.name = "PhotoPandy"
	pandy.position = Vector3(3.2, _ground_height(3.2, -2.4), -2.4)
	_reserve_footprint(Vector2(pandy.position.x, pandy.position.z), 1.0)
	# Pandy is authored facing local -Z, unlike the humanoid rigs.
	var pandy_to_hero := Vector2(-2.35 - pandy.position.x, 8.45 - pandy.position.z)
	pandy.rotation.y = atan2(pandy_to_hero.x, pandy_to_hero.y) + PI
	pandy.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(pandy)
	pandy.set("_motion_time", 0.23)
	pandy.call("_update_idle_animation", 0.2, true)


func _build_distant_titans() -> void:
	# Landmark silhouettes bookend the horizon, deliberately separated so the
	# distance reads as a populated world rather than a paired character pose.
	var humongous_xz := Vector2(-92.0, -205.0) + PHOTO_CAMERA_LEFT_XZ * 83.0
	var humongous_x := humongous_xz.x
	var humongous_z := humongous_xz.y
	_reserve_footprint(Vector2(humongous_x, humongous_z), Blorb.RADIUS * HumongousState.SIZE_MULTIPLIER)
	_build_blorb(
		Vector3(humongous_x, _ground_height(humongous_x, humongous_z), humongous_z),
		Color(0.7, 0.78, 0.72, 0.9), HumongousState.SIZE_MULTIPLIER,
		deg_to_rad(-48.0), 0.72
	)

	var da_hou_zi := DA_HOU_ZI_SCENE.instantiate() as ApeTemplatePreview
	da_hou_zi.name = "PhotoDaHouZi"
	da_hou_zi.fur_color = DA_HOU_ZI_CONFIG.GORILLA_FUR_COLOR
	da_hou_zi.eye_color_override = DA_HOU_ZI_CONFIG.MIND_CONTROL_EYE_COLOR
	da_hou_zi.has_tail = false
	da_hou_zi.body_type = 1.0
	# Actual Da Hou Zi rig and proportions, art-directed at forced-perspective
	# scale for this much smaller photographic set.
	da_hou_zi.display_scale = DA_HOU_ZI_CONFIG.GORILLA_DISPLAY_SCALE
	da_hou_zi.movement_speed_multiplier = 0.0
	da_hou_zi.gait_speed_multiplier = DA_HOU_ZI_CONFIG.GORILLA_GAIT_SPEED_MULTIPLIER
	da_hou_zi.roam_radius = 0.0
	da_hou_zi.parkour_collision = false
	var da_hou_zi_xz := Vector2(72.0, -260.0) + PHOTO_CAMERA_LEFT_XZ * 90.0
	da_hou_zi.position = Vector3(
		da_hou_zi_xz.x,
		_ground_height(da_hou_zi_xz.x, da_hou_zi_xz.y),
		da_hou_zi_xz.y
	)
	da_hou_zi.rotation.y = deg_to_rad(38.0)
	_reserve_footprint(Vector2(da_hou_zi.position.x, da_hou_zi.position.z), 18.0)
	add_child(da_hou_zi)
	da_hou_zi.process_mode = Node.PROCESS_MODE_DISABLED


func _build_blorb(
	position: Vector3, color: Color, scale_factor: float, facing_yaw: Variant = null,
	vertical_scale: float = 1.0
) -> void:
	var root := Node3D.new()
	root.name = "PartyBlorb"
	# Match Blorb._ground_embed_offset() plus its body's local -EMBED_DEPTH.
	# Ordinary live Blorbs expose half the authored embed; the former photo
	# formula buried the full amount and visibly sank nearby Blorbus. Humongous
	# uses the live giant rule: only ten percent of his flattened body height.
	var visible_sink := (
		Blorb.BODY_HEIGHT * scale_factor * vertical_scale * 0.10
		if not is_equal_approx(vertical_scale, 1.0)
		else Blorb.EMBED_DEPTH * 0.5
	)
	root.position = position - Vector3.UP * visible_sink
	_reserve_footprint(Vector2(position.x, position.z), Blorb.RADIUS * scale_factor)
	var toward_hero := Vector2(-2.35 - position.x, 8.45 - position.z)
	root.rotation.y = (
		float(facing_yaw)
		if facing_yaw != null
		else atan2(toward_hero.x, toward_hero.y) + _rng.randf_range(-0.06, 0.06)
	)
	root.scale = Vector3(scale_factor, scale_factor * vertical_scale, scale_factor)
	add_child(root)
	var body := MeshInstance3D.new()
	body.mesh = BlorbBodyShape.build_mesh(Blorb.RADIUS, Blorb.BODY_HEIGHT)
	body.material_override = BlorbBodyShape.build_body_material(
		color, 0.15, 0.05, false, Color.BLACK, 0.0
	)
	root.add_child(body)
	const EYE_T := 0.42
	var eye_data := BlorbBodyShape.eye_surface(EYE_T, Blorb.RADIUS, Blorb.BODY_HEIGHT)
	BlorbFace.add_eyes(
		body,
		eye_data["radius"] as float,
		eye_data["y"] as float,
		eye_data["dr_dy"] as float,
		color
	)
	var core := BlorbCore.build(Blorb.CORE_RADIUS, Color(0.85, 0.9, 0.95), false)
	core.position.y = Blorb.BULGE_T * Blorb.BODY_HEIGHT
	root.add_child(core)


func _build_foliage() -> void:
	_build_readable_ground_clusters()
	var tree_specs := [
		[-12.5, -3.5, 6.5], [-16.0, -9.0, 7.2], [12.8, -4.5, 5.6],
		[16.3, -9.5, 6.9], [-18.0, -18.0, 7.6], [18.4, -18.5, 6.8],
		[-8.8, -12.0, 6.5], [8.7, -13.5, 7.2], [-20.0, 1.0, 5.6],
		[20.5, -2.0, 6.9], [-5.5, -21.0, 7.6], [6.0, -23.0, 6.8],
	]
	for i in tree_specs.size():
		var spec: Array = tree_specs[i]
		var x: float = spec[0]
		var z: float = spec[1]
		var tree_footprint := float(spec[2]) * 0.43
		if not _is_footprint_clear(Vector2(x, z), tree_footprint):
			continue
		var tree: Node3D
		var leaf_color: Color = NatureProps.TREE_LEAF_COLORS[i % NatureProps.TREE_LEAF_COLORS.size()]
		if i % 5 == 1:
			tree = NatureProps.build_fruit_tree(
				spec[2], leaf_color, NatureProps.FRUIT_COLORS["Apple"]
			)
		elif i % 5 == 2:
			tree = NatureProps.build_pine_tree(spec[2] * 1.08, leaf_color)
		elif i % 5 == 3:
			tree = NatureProps.build_alpine_cedar_tree(spec[2], leaf_color)
		elif i % 5 == 4:
			tree = NatureProps.build_flowering_tree(
				spec[2], leaf_color, Color(0.96, 0.47, 0.69), _rng
			)
		else:
			tree = NatureProps.build_round_tree(spec[2], leaf_color)
		tree.position = Vector3(x, _ground_height(x, z), z)
		tree.rotation.y = _rng.randf_range(0.0, TAU)
		add_child(tree)
		_reserve_footprint(Vector2(x, z), tree_footprint)
	_scatter_background_groves()
	_scatter_midground_understory()
	# Layered understory gives the plateau more than the previous trees/grass/
	# rocks trio while keeping the foreground lane around the runner clear.
	for i in 34:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * _rng.randf_range(7.0, 20.5)
		var z := _rng.randf_range(-22.0, 6.0)
		if _flora_noise.get_noise_2d(x, z) < -0.12:
			continue
		if not _is_footprint_clear(Vector2(x, z), 0.9):
			continue
		var plant: Node3D
		match i % 3:
			0:
				plant = NatureProps.build_bush(NatureProps.TREE_LEAF_COLORS[i % NatureProps.TREE_LEAF_COLORS.size()])
			1:
				plant = NatureProps.build_flower([Color(0.96, 0.46, 0.62), Color(0.94, 0.77, 0.22), Color(0.58, 0.46, 0.93)][i % 3])
			_:
				plant = NatureProps.build_mushroom([Color(0.84, 0.21, 0.16), Color(0.76, 0.55, 0.31)][i % 2])
		plant.position = Vector3(x, _ground_height(x, z), z)
		plant.rotation.y = _rng.randf_range(0.0, TAU)
		plant.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
		add_child(plant)
	for i in 18:
		var side := -1.0 if i % 2 == 0 else 1.0
		var x := side * _rng.randf_range(7.5, 18.5)
		var z := _rng.randf_range(-20.0, 8.0)
		if _terrain_detail_noise.get_noise_2d(x, z) < 0.02:
			continue
		if not _is_footprint_clear(Vector2(x, z), 0.8):
			continue
		var rock := NatureProps.build_rock(_rng.randf_range(0.3, 0.8), false)
		rock.position = Vector3(x, _ground_height(x, z), z)
		rock.rotation.y = _rng.randf_range(0.0, TAU)
		rock.scale = Vector3.ONE * _rng.randf_range(0.85, 1.2)
		add_child(rock)
	for i in 90:
		var x := _rng.randf_range(-20.0, 20.0)
		var z := _rng.randf_range(-22.0, 10.0)
		if _flora_noise.get_noise_2d(x, z) < -0.2:
			continue
		if absf(x) < 6.2 and z > -3.0:
			continue
		if not _is_footprint_clear(Vector2(x, z), 0.3):
			continue
		var grass := NatureProps.build_grass_tuft()
		grass.position = Vector3(x, _ground_height(x, z), z)
		grass.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
		add_child(grass)


## A guaranteed grove in the camera-visible background. Its arc, spacing,
## heights and fruit species are noise-jittered, so it reads as a naturally
## established colony rather than an orchard row, while never disappearing
## entirely because a random threshold happened to reject every candidate.
func _build_visible_fruit_grove() -> void:
	# Exact Crossroads orchard recipe from WildernessScatter._fruit_orchard():
	# a single real species in a 3x3 grid, 5 m spacing, 0.6 m jitter, and the
	# same uniform 0.9-1.1 scale range. No photograph-only fruit is added.
	const HEIGHT := 6.0
	const ROWS := 3
	const COLS := 3
	const SPACING := 5.0
	var center := Vector2(-14.0, -8.0)
	var origin := center - Vector2(SPACING, SPACING) * (Vector2(COLS, ROWS) - Vector2.ONE) * 0.5
	for row in ROWS:
		for column in COLS:
			var at := origin + Vector2(column, row) * SPACING + Vector2(
				_rng.randf_range(-0.6, 0.6), _rng.randf_range(-0.6, 0.6)
			)
			var footprint := HEIGHT * 0.43
			if not _is_footprint_clear(at, footprint, 0.65):
				continue
			var tree := NatureProps.build_fruit_tree(
				HEIGHT, NatureProps.TREE_LEAF_COLORS[0], NatureProps.FRUIT_COLORS["Apple"]
			)
			tree.position = Vector3(at.x, _ground_height(at.x, at.y), at.y)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			add_child(tree)
			_reserve_footprint(at, footprint)


## Deliberate photographic clusters supplement the broad procedural scatter.
## They use the same shared NatureProps geometry, but are large/near enough to
## read as grass, bushes, mushrooms and rocks instead of sub-pixel specks.
func _build_readable_ground_clusters() -> void:
	var cluster_centers := [Vector2(-12.5, 8.3), Vector2(9.8, 8.0), Vector2(13.4, 6.6)]
	for cluster_index in cluster_centers.size():
		var center: Vector2 = cluster_centers[cluster_index]
		for item_index in 9:
			var angle := float(item_index) * TAU / 9.0 + float(cluster_index) * 0.7
			var distance := 0.45 + float(item_index % 3) * 0.48
			var at := center + Vector2(cos(angle), sin(angle)) * distance
			if not _is_footprint_clear(at, 0.28, 0.08):
				continue
			var prop: Node3D
			match item_index % 4:
				0:
					prop = NatureProps.build_bush(NatureProps.TREE_LEAF_COLORS[(cluster_index + item_index) % NatureProps.TREE_LEAF_COLORS.size()])
					prop.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
				1:
					prop = NatureProps.build_grass_tuft(Color(0.16, 0.48 + 0.08 * cluster_index, 0.2))
					prop.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
				2:
					prop = NatureProps.build_mushroom([Color(0.86, 0.18, 0.12), Color(0.94, 0.72, 0.18), Color(0.58, 0.32, 0.78)][cluster_index])
					prop.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
				_:
					prop = NatureProps.build_rock(0.28 + 0.07 * cluster_index, false)
					prop.scale = Vector3.ONE * _rng.randf_range(0.85, 1.2)
			prop.position = Vector3(at.x, _ground_height(at.x, at.y), at.y)
			prop.rotation.y = _rng.randf_range(0.0, TAU)
			add_child(prop)
			_reserve_footprint(at, 0.28)


func _scatter_midground_understory() -> void:
	for index in 80:
		var x := _rng.randf_range(-20.0, 20.0)
		var z := _rng.randf_range(-15.0, 4.0)
		if _flora_noise.get_noise_2d(x + 9.0, z - 18.0) < -0.06:
			continue
		var radius := _rng.randf_range(0.3, 0.7)
		if not _is_footprint_clear(Vector2(x, z), radius, 0.2):
			continue
		var prop: Node3D
		if index % 4 == 0:
			prop = NatureProps.build_mushroom([Color(0.8, 0.22, 0.16), Color(0.82, 0.63, 0.34)][index % 2])
		else:
			prop = NatureProps.build_bush(NatureProps.TREE_LEAF_COLORS[index % NatureProps.TREE_LEAF_COLORS.size()])
		prop.position = Vector3(x, _ground_height(x, z), z)
		prop.rotation.y = _rng.randf_range(0.0, TAU)
		prop.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
		add_child(prop)
		_reserve_footprint(Vector2(x, z), radius)


## Layered noise produces groves and open meadow rather than a uniform point
## cloud. A lower-frequency field chooses fruit-grove regions; a separate
## density field breaks their edges and interleaves flowers naturally.
func _scatter_background_groves() -> void:
	const COLUMNS := 13
	const ROWS := 11
	for row in ROWS:
		for column in COLUMNS:
			var x := lerpf(-22.0, 22.0, float(column) / float(COLUMNS - 1)) + _rng.randf_range(-1.15, 1.15)
			var z := lerpf(-29.0, 3.5, float(row) / float(ROWS - 1)) + _rng.randf_range(-1.0, 1.0)
			if _flora_noise.get_noise_2d(x, z) < 0.07:
				continue
			var height := _rng.randf_range(4.0, 7.4)
			var tree_footprint := height * 0.43
			if not _is_footprint_clear(Vector2(x, z), tree_footprint, 0.75):
				continue
			var leaf_color: Color = NatureProps.TREE_LEAF_COLORS[_rng.randi() % NatureProps.TREE_LEAF_COLORS.size()]
			var tree: Node3D
			if _grove_noise.get_noise_2d(x, z) > 0.05:
				var fruit_names := NatureProps.FRUIT_COLORS.keys()
				var fruit_name: String = fruit_names[_rng.randi() % fruit_names.size()]
				tree = NatureProps.build_fruit_tree(height, leaf_color, NatureProps.FRUIT_COLORS[fruit_name])
			elif _flora_noise.get_noise_2d(x + 17.0, z - 9.0) > 0.38:
				tree = NatureProps.build_flowering_tree(height, leaf_color, Color(0.95, 0.48, 0.7), _rng)
			else:
				tree = NatureProps.build_round_tree(height, leaf_color)
			tree.position = Vector3(x, _ground_height(x, z), z)
			tree.rotation.y = _rng.randf_range(0.0, TAU)
			add_child(tree)
			_reserve_footprint(Vector2(x, z), tree_footprint)

	for index in 240:
		var x := _rng.randf_range(-22.0, 22.0)
		var z := _rng.randf_range(-28.0, 8.0)
		# Offset sampling makes flower colonies related to, but not identical
		# with, the tree groves. The threshold leaves generous quiet grass.
		if _flora_noise.get_noise_2d(x + 31.0, z + 13.0) < 0.08:
			continue
		if not _is_footprint_clear(Vector2(x, z), 0.1, 0.12):
			continue
		var flower_colors := [Color(0.93, 0.28, 0.38), Color(0.97, 0.76, 0.2), Color(0.65, 0.38, 0.88), Color(0.96, 0.55, 0.72)]
		var flower := NatureProps.build_flower(flower_colors[index % flower_colors.size()])
		flower.position = Vector3(x, _ground_height(x, z), z)
		flower.rotation.y = _rng.randf_range(0.0, TAU)
		flower.scale = Vector3.ONE * _rng.randf_range(0.9, 1.5)
		add_child(flower)


## The live directional shadow remains enabled, but the title image also gets
## a soft analytical contact shadow. This avoids distant cascade pixelation
## (especially beneath Humongous) and guarantees that feet read as grounded in
## the baked photograph even on renderers with reduced headless shadow support.
func _add_contact_shadow(at: Vector3, size: Vector2, opacity: float) -> void:
	var dx := (_ground_height(at.x + 0.06, at.z) - _ground_height(at.x - 0.06, at.z)) / 0.12
	var dz := (_ground_height(at.x, at.z + 0.06) - _ground_height(at.x, at.z - 0.06)) / 0.12
	var normal := Vector3(-dx, 1.0, -dz).normalized()
	var axis_x := (Vector3.RIGHT - normal * normal.dot(Vector3.RIGHT)).normalized()
	var axis_y := normal.cross(axis_x).normalized()
	var quad := QuadMesh.new()
	quad.size = size
	var shadow := MeshInstance3D.new()
	shadow.name = "SoftContactShadow"
	shadow.mesh = quad
	shadow.transform = Transform3D(Basis(axis_x, axis_y, normal), at + normal * 0.012)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float opacity = 0.3;
void fragment() {
	vec2 p = (UV - vec2(0.5)) * 2.0;
	float falloff = 1.0 - smoothstep(0.18, 1.0, dot(p, p));
	ALBEDO = vec3(0.025, 0.035, 0.045);
	ALPHA = falloff * opacity;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("opacity", opacity)
	shadow.material_override = material
	add_child(shadow)


func _reserve_footprint(point: Vector2, radius: float) -> void:
	_occupied_footprints.append({"point": point, "radius": radius})


func _is_footprint_clear(point: Vector2, radius: float, margin: float = 0.28) -> bool:
	for footprint in _occupied_footprints:
		var other: Vector2 = footprint["point"]
		var required := radius + (footprint["radius"] as float) + margin
		if point.distance_squared_to(other) < required * required:
			return false
	return true


func _find_clear_party_position(desired: Vector2, radius: float) -> Vector2:
	if _is_footprint_clear(desired, radius):
		return desired
	# Deterministic sunflower search keeps a displaced follower close to its
	# intended bank while avoiding regimented rows or object intersections.
	for attempt in range(1, 400):
		var distance := 0.48 * sqrt(float(attempt))
		var angle := float(attempt) * 2.399963
		var candidate := desired + Vector2(cos(angle), sin(angle)) * distance
		if _is_footprint_clear(candidate, radius):
			return candidate
	# The photographic field is much larger than the crowd, so exhausting this
	# search indicates a construction error. Keep the failure visible in logs
	# and put the figure well outside the composition rather than intersecting
	# another subject.
	push_warning("No collision-free start-photo position near %s" % desired)
	return Vector2(30.0, -30.0)


func _build_clouds() -> void:
	# The actual Crossroads ambient-cloud generator: every cloud receives a
	# seeded but different lobe count, radius and layout. These are not the
	# repeated five-lobe CloudPlatform power objects used in the earlier draft.
	var clouds := CloudScatter.new()
	clouds.name = "CrossroadsClouds"
	clouds.cloud_count = 14
	clouds.altitude_min = 45.0
	clouds.altitude_max = 80.0
	clouds.spread = 80.0
	clouds.rng_seed = 0xC10D5
	add_child(clouds)
	# Preserve the generator's unique cloud construction, then art-direct six
	# resulting clusters into this camera's sky at their authored scale.
	var photo_cloud_positions: Array[Vector3] = [
		Vector3(-42, 48, -55), Vector3(-12, 56, -72),
		Vector3(22, 51, -66), Vector3(48, 54, -52),
	]
	for index in clouds.get_child_count():
		var cloud := clouds.get_child(index) as Node3D
		if cloud == null:
			continue
		cloud.visible = index < photo_cloud_positions.size()
		if cloud.visible:
			cloud.position = photo_cloud_positions[index]
	clouds.set_night_factor(0.08)
