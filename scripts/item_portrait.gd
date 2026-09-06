class_name ItemPortrait
extends RefCounted

## Captures actual ShopCatalog build_visual geometry into reusable still
## textures. Requests are serialized: at most one temporary GPU viewport is
## alive while a shop or inventory populates, and every item is rendered only
## once per capture version before being shared across UI surfaces.

const RESOLUTION := 192
const CAPTURE_VERSION := 4
const HELMET_ITEMS := ["Diving Helmet", "Knight's Helm"]

static var _cache: Dictionary = {}
static var _pending: Dictionary = {}
static var _capture_busy := false


static func apply_portrait(container: Control, tree: SceneTree, item_name: String) -> void:
	_apply_async(container, tree, item_name)


static func _apply_async(container: Control, tree: SceneTree, item_name: String) -> void:
	var key := "%d:%s" % [CAPTURE_VERSION, item_name]
	if not _cache.has(key):
		await _capture(tree, key, item_name)
	if not is_instance_valid(container):
		return
	var texture := _cache.get(key) as Texture2D
	if texture == null:
		return
	for child in container.get_children():
		child.queue_free()
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(rect)


static func _capture(tree: SceneTree, key: String, item_name: String) -> void:
	if _pending.has(key):
		while _pending.has(key):
			await tree.process_frame
		return
	_pending[key] = true
	while _capture_busy:
		await tree.process_frame
	_capture_busy = true

	var entry := ShopCatalog.find(item_name)
	if entry.is_empty() or not entry.has("build_visual"):
		_finish_capture(key)
		return

	var viewport := SubViewport.new()
	viewport.size = Vector2i(RESOLUTION, RESOLUTION)
	viewport.transparent_bg = true
	viewport.world_3d = World3D.new()
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# InventoryUI is an autoload and asks for portraits while its own _ready()
	# is still assembling controls. The SceneTree root rejects children during
	# that phase, so cross one frame boundary before installing the viewport.
	await tree.process_frame
	tree.root.add_child(viewport)

	var visual := (entry["build_visual"] as Callable).call(1.0) as Node3D
	visual.rotation_degrees = Vector3(-8.0, 28.0, 0.0)
	viewport.add_child(visual)
	await tree.process_frame

	var bounds := _world_aabb(visual)
	var target := bounds.get_center()
	var extent := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
	if extent < 0.01:
		extent = 0.25
	var camera := Camera3D.new()
	camera.fov = 42.0
	# Frame the object as the subject of the portrait. The previous 1.55x
	# full-extent distance treated the extent like a half-extent, leaving the
	# model at roughly one third of the available image area.
	# Helmets have an open silhouette and thin mask details, so the generic
	# crop leaves them reading smaller than denser fruit/antique models even
	# at the same bounds. Give both wearable helmets a dedicated close crop.
	var framing_scale := 0.50 if item_name in HELMET_ITEMS else 0.68
	var distance := extent * framing_scale / tan(deg_to_rad(camera.fov * 0.5))
	camera.position = target + Vector3(0.0, extent * 0.12, distance)
	# look_at() hard-requires is_inside_tree(); camera isn't parented yet at
	# this point (viewport.add_child(camera) is still below) -- same fix as
	# nature_props.gd's own durian spikes (see that file's own comment for
	# the full explanation): look_at_from_position() sets the transform
	# directly instead of resolving through the tree.
	camera.look_at_from_position(camera.position, target, Vector3.UP)
	camera.current = true
	viewport.add_child(camera)

	var environment := Environment.new()
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.9
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	viewport.add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.light_energy = 0.65
	key_light.rotation_degrees = Vector3(-35.0, -35.0, 0.0)
	viewport.add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.light_energy = 0.25
	fill_light.rotation_degrees = Vector3(-20.0, 145.0, 0.0)
	viewport.add_child(fill_light)

	await tree.process_frame
	await tree.process_frame
	# The dummy renderer used by automated headless validation exposes a
	# viewport texture object without a backing renderer texture. There is no
	# portrait to capture in that environment; avoid asking it for an image.
	if DisplayServer.get_name() == "headless":
		viewport.queue_free()
		_finish_capture(key)
		return
	var viewport_texture: Texture2D = viewport.get_texture()
	if viewport_texture == null:
		viewport.queue_free()
		_finish_capture(key)
		return
	var image: Image = viewport_texture.get_image()
	if image == null or image.is_empty():
		viewport.queue_free()
		_finish_capture(key)
		return
	_cache[key] = ImageTexture.create_from_image(image)
	viewport.queue_free()
	_finish_capture(key)


static func _finish_capture(key: String) -> void:
	_capture_busy = false
	_pending.erase(key)


static func _world_aabb(node: Node) -> AABB:
	var result := AABB()
	var has_geometry := false
	for descendant in node.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := descendant as MeshInstance3D
		var world_box := mesh_instance.global_transform * mesh_instance.get_aabb()
		result = world_box if not has_geometry else result.merge(world_box)
		has_geometry = true
	return result
