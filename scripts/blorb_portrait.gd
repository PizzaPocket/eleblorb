class_name BlorbPortrait
extends RefCounted

## Renders an actual 3D blorb -- the same body-building code (blorb.gd's
## _build_visuals(), blorb_core.gd) gameplay blorbs use -- to a still
## ImageTexture for InventoryUI's Blorbs tab, per direct instruction: a real
## "photograph" of the blorb, not a hand-drawn icon standing in for one.
##
## A SubViewport render is inherently at least a couple of frames away (the
## GPU pass only actually happens starting the frame after the viewport/
## camera/light are set up), so this is async by nature -- apply_portrait()
## is fire-and-forget from a synchronous UI-building call site (InventoryUI
## never awaits it). The reserved stage stays empty until the real texture
## resolves, avoiding any flash of a mismatched illustrated icon. Cached per
## distinct look (element state, or body_color for a still-unmerged Normal
## blorb) in _cache, since every blorb sharing a look renders identically --
## there's no reason to re-shoot the same portrait per row per refresh.

const RESOLUTION := 256
## TransformationUI enlarges the same shot to the whole viewport. Keep that
## one-off presentation crisp without making every inventory row pay for a
## four-times-larger render target.
const FULLSCREEN_RESOLUTION := 1024

## Bumped whenever the capture rig itself changes (camera distance/angle,
## pose, lighting) OR the rendered subject's own look changes (e.g.
## blorb_face.gd's eye color/darkening) -- folded into the cache key below
## so a stale capture taken under the old numbers doesn't stay stuck in
## _cache for the rest of the running process. _cache is a static var,
## which survives a Godot script hot-reload (this project's own dev loop --
## the game stays open and running while scripts keep changing), so a
## tuning change to this file OR to blorb_face.gd doesn't retroactively fix
## anything already captured and cached under the old numbers unless the
## key changes too. This is exactly what made an Electric blorb's portrait
## look zoomed-out relative to freshly-captured Normal ones right after a
## camera-distance fix -- the Electric one had been sitting in the cache
## since before that fix landed. Bumped again here for the same reason
## after blorb_face.gd's eye darkening changed from 0.55 to 0.25 -- every
## portrait shot before that fix landed still had the old near-black eyes
## baked into its cached texture. Bumped again after that: the lighter eye
## albedo from that same fix turned out to blow out to solid white under
## this rig's own stacked key+fill+ambient lighting (reported as "the eyes
## in the menu are all white") -- fixed by making the eye material matte
## instead of glossy (roughness 0.35 -> 0.8, see blorb_face.gd), which
## needs its own cache-busting bump for the same reason as every other
## look change here. Bumped again after widening the key light's angle off
## the camera axis (was reading as flat, direct "flash" lighting) -- a pure
## rig change, same bump-on-any-rig-change rule as camera distance/angle.
## Bumped once more after cutting the key/fill energy hard and raising
## ambient to compensate -- widening the angle alone still read as "way,
## way too harsh." Bumped again after cutting it further still, same
## complaint repeated a second time. Bumped once more after enabling MSAA
## (fixes visibly jagged/pixelated silhouette edges).
const CAPTURE_VERSION := 10

static var _cache: Dictionary = {}
## Keys currently mid-capture -- a second/third request for the same
## not-yet-cached look (e.g. three Normal party members open at once) waits
## on the one in-flight shoot instead of spinning up a redundant one.
static var _pending: Dictionary = {}
## Distinct uncached looks queue behind one capture rig rather than creating
## several simultaneous 256px GPU viewports when the Blorbs tab first opens.
static var _capture_busy := false


## Fire-and-forget: applies a cached portrait next frame, or starts a
## capture and applies it once ready. container is a fixed-size empty
## UIKit.portrait_slot(), populated with a TextureRect once the real portrait
## exists. Safe to call from a
## synchronous context since nothing here is awaited at the call site;
## checks is_instance_valid(container) before touching it in case the row
## it belonged to was freed (a tab switch, a refresh) before the capture
## finished.
static func apply_portrait(
	container: Control, tree: SceneTree, element_state: String, body_color: Color,
	melted: bool = false
) -> void:
	_apply_async(container, tree, element_state, body_color, melted, false)


## Awaitable access to the same cached three-quarter portrait used by the
## Blorbs tab. The transformation cut sequence uses this to preserve exact
## visual continuity before and after the whiteout instead of maintaining a
## second capture rig with subtly different framing or lighting.
static func get_portrait_texture(
	tree: SceneTree, element_state: String, body_color: Color,
	melted: bool = false, blorbus: bool = false
) -> Texture2D:
	var key := _cache_key(
		element_state, body_color, melted, blorbus, FULLSCREEN_RESOLUTION
	)
	if not _cache.has(key):
		await _capture(
			tree, key, element_state, body_color, melted, blorbus, FULLSCREEN_RESOLUTION
		)
	return _cache.get(key) as Texture2D


static func _apply_async(
	container: Control, tree: SceneTree, element_state: String, body_color: Color,
	melted: bool = false, blorbus: bool = false
) -> void:
	var key := _cache_key(element_state, body_color, melted, blorbus, RESOLUTION)
	if not _cache.has(key):
		await _capture(tree, key, element_state, body_color, melted, blorbus, RESOLUTION)

	if not is_instance_valid(container):
		return
	var texture: Texture2D = _cache.get(key)
	if texture == null:
		return

	for c in container.get_children():
		c.queue_free()
	var rect := TextureRect.new()
	rect.texture = texture
	# EXPAND_IGNORE_SIZE, not the TextureRect default (EXPAND_KEEP_SIZE) --
	# without it, the control's own reported minimum size tracks the
	# texture's native 256x256 regardless of the anchors below, which can
	# read as a wrong-scale crop rather than the full portrait scaled down
	# to fit container's actual (smaller) size.
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(rect)


static func _cache_key(
	element_state: String, body_color: Color, melted: bool = false,
	blorbus: bool = false, resolution: int = RESOLUTION
) -> String:
	# An elemental blorb's look is fully determined by its element (see
	# blorb.gd's _apply_element_visuals()) -- body_color only matters for
	# the still-unmerged "Normal" case, where it's the one thing that
	# actually varies blorb to blorb. CAPTURE_VERSION prefix per that
	# const's own comment -- keeps a stale capture from a previous rig
	# tuning pass from ever matching a current-version request. melted is
	# folded in the same way -- a core-only capture is a visually distinct
	# look from the same blorb's normal one, not a re-skin of it.
	var look_key := element_state if element_state != "" else "normal:%s" % body_color
	if blorbus:
		look_key = "blorbus"
	if melted:
		look_key = "melted:%s" % look_key
	return "%d:%d:%s" % [CAPTURE_VERSION, resolution, look_key]


static func _capture(
	tree: SceneTree, key: String, element_state: String, body_color: Color,
	melted: bool = false, blorbus: bool = false, resolution: int = RESOLUTION
) -> void:
	if _pending.has(key):
		while _pending.has(key):
			await tree.process_frame
		return
	_pending[key] = true
	while _capture_busy:
		await tree.process_frame
	_capture_busy = true

	# Everything -- the stand-in Terrain, the blorb itself, the camera, the
	# lights -- has to actually be INSIDE the SubViewport's own subtree (not
	# just some other node added alongside it) since a SubViewport only ever
	# renders its own descendants, never siblings elsewhere in the outer
	# scene. own_world_3d isolates that subtree's World3D from whatever
	# actually shares tree.root -- without it, this SubViewport would
	# default to the same World3D the running game's own main viewport
	# uses, meaning the capture would show the entire live 3D scene (town,
	# terrain, everything) behind the blorb instead of an isolated shot.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(resolution, resolution)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	# MSAA, not left off (Godot's own default) -- per direct correction,
	# without it the rendered silhouette's edge against the transparent
	# background came out visibly jagged/pixelated once scaled up into the
	# UI.
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# blorb.gd's @onready var terrain resolves "../Terrain" unconditionally
	# on entering the tree (before _ready() runs, so portrait_mode's own
	# early-return can't guard it) -- a bare stand-in Node satisfies that
	# without needing a real Terrain. Never actually queried in portrait
	# mode (see blorb.gd's _ready()), so it doesn't need get_mesh_height()
	# or anything else real Terrain provides. Both this and the blorb below
	# are direct children of the viewport itself (see the comment above),
	# not some other wrapper node, so "../Terrain" resolves correctly.
	var terrain_stub := Node.new()
	terrain_stub.name = "Terrain"
	viewport.add_child(terrain_stub)

	var packed: PackedScene = load("res://scenes/blorb.tscn")
	var blorb = packed.instantiate()
	blorb.body_color = body_color
	blorb.portrait_mode = true
	blorb.portrait_blorbus = blorbus
	blorb.initial_element = element_state
	# Set before add_child() below, same as body_color/initial_element above --
	# _build_visuals() (called from _ready(), which fires once this enters the
	# tree) only skips building the body-mesh-and-eyes block when is_melted is
	# already true at that point, producing a genuinely core-only mesh set for
	# _world_aabb() to measure below (see blorb.gd's own is_melted guard).
	blorb.is_melted = melted
	# The three-quarter pose turns the BLORB, not the camera, per direct
	# correction -- the camera stays fixed at the dead-on position already
	# confirmed centered (see the CAMERA_YAW=0 comment further down), so
	# this can't reintroduce that same unexplained yaw-dependent framing
	# bug; rotating the object around its own fixed pivot has no way to
	# move its own AABB center off of wherever the (already-working)
	# camera is aimed. Sign: Godot's Y-rotation (x'=cos(th)x+sin(th)z,
	# z'=-sin(th)x+cos(th)z, per the figure-rig skill's own documented
	# convention) sends the blorb's face direction (local +Z, confirmed
	# via blorb_face.gd's eye placement) to world (sin(th), 0, cos(th)) --
	# and separately, the fixed camera's own "right" resolves to world +X
	# (derived from look_at()'s actual basis construction: right =
	# normalize(cross(up, local_Z)), not assumed). Positive th is what
	# puts the face toward positive world X, i.e. the viewer's right.
	const BLORB_POSE_YAW := 25.0  # degrees (35 - 10, per direct correction)
	blorb.rotation.y = deg_to_rad(BLORB_POSE_YAW)
	viewport.add_child(blorb)

	# viewport (and everything under it, including blorb) has to actually
	# be INSIDE the live scene tree before measuring anything below --
	# Godot only calls _ready() (which is what runs blorb.gd's
	# _build_visuals(), building its actual meshes) once a node enters a
	# tree that's already active, not just when it's add_child()'d onto
	# some other node that isn't in the tree yet itself. The first version
	# of this measured the AABB right after viewport.add_child(blorb) above
	# but before this line -- at that point _ready() genuinely hadn't run
	# yet, blorb had no meshes at all, _world_aabb() came back as an empty
	# zero-size box, and the "half its extent" distance math below computed
	# out to essentially zero -- which is exactly "the camera ends up
	# sitting inside the mesh," matching the reported "full window of
	# blorb skin" result.
	tree.root.add_child(viewport)

	# Now that _ready() has actually run, measure the blorb's own real
	# rendered AABB and frame off THAT (see _world_aabb() below) instead of
	# assumed BODY_HEIGHT/RADIUS/EMBED_DEPTH constants -- earlier passes
	# using those assumptions still put the blob small and cropped in a
	# corner, so trusting the measured geometry directly removes that
	# whole class of guess.
	var bounds := _world_aabb(blorb)
	# Sanity fallback: camera.look_at(look_target, ...) mathematically
	# guarantees look_target lands at the exact center of frame regardless
	# of distance, so an off-center subject can only mean look_target
	# itself was wrong -- most plausibly bounds coming back empty/near-zero
	# again in some other way than the already-fixed "measured before
	# _ready() ran" bug. Falls back to a known-reasonable framing (the
	# real, gameplay-verified BODY_HEIGHT/RADIUS constants) rather than
	# trusting a suspiciously tiny measurement blindly.
	var look_target: Vector3
	var camera_distance: float
	if bounds.size.length() < 0.1:
		look_target = Vector3(0, Blorb.BODY_HEIGHT * 0.42, 0)
		camera_distance = Blorb.RADIUS * 6.0
	else:
		look_target = bounds.get_center()
		# The sagging body carries more visual mass below its geometric center.
		# Aim below the AABB midpoint so the photographed Blorb sits optically
		# centered instead of reading low in its square stage. The earlier 3.5%
		# correction was present but too subtle to resolve the visible bias.
		look_target.y -= bounds.size.y * 0.08
		# Half the AABB's largest extent, at Camera3D's default vertical
		# FOV (75 deg -- half-angle ~37.5 deg). Margin factor history: 1.6x
		# originally, widened to 2.4x (too far back), brought down to 1.07x,
		# now another 25% closer on top of that per direct correction
		# (1.07 * 0.75 = 0.8025) -- under 1.0x means the camera sits closer
		# than the distance that exactly fits the AABB's own diagonal, which
		# is fine: half_extent itself already has slack built in (a
		# diagonal is longer than any single axis actually needs).
		var half_extent := bounds.size.length() * 0.5
		camera_distance = (half_extent / tan(deg_to_rad(37.5))) * 0.8025

	# CAMERA_YAW stays fixed at 0 (dead-on) -- per direct correction, the
	# three-quarter angle now comes from rotating the blorb itself (see
	# BLORB_POSE_YAW above), not from moving the camera. An earlier pass
	# that swung the camera's own yaw to get the three-quarter view (+35
	# framed the blorb left of center, -35 framed it right of center)
	# turned out to have an unexplained yaw-dependent framing bug baked
	# into it somewhere; keeping the camera at the one angle already
	# confirmed centered sidesteps that entirely rather than needing to
	# actually root-cause it.
	const CAMERA_YAW := 0.0  # degrees
	const CAMERA_PITCH := 12.0  # degrees, positive = camera above, angled down
	var yaw := deg_to_rad(CAMERA_YAW)
	var pitch := deg_to_rad(CAMERA_PITCH)
	var camera_offset := Vector3(
		cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw)
	) * camera_distance
	var camera := Camera3D.new()
	camera.position = look_target + camera_offset
	# look_at() hard-requires is_inside_tree(); camera isn't parented yet at
	# this point (viewport.add_child(camera) is still below) -- same fix as
	# nature_props.gd's own durian spikes (see that file's own comment for
	# the full explanation): look_at_from_position() sets the transform
	# directly instead of resolving through the tree.
	camera.look_at_from_position(camera.position, look_target, Vector3.UP)
	camera.current = true
	viewport.add_child(camera)

	# A flat, always-on ambient floor -- so a light aimed wrong still leaves
	# the body visibly lit rather than reading as invisible against the
	# transparent background, the specific failure mode the switch to
	# look_at()-derived lights above is guarding against.
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	# Raised again (0.7 -> 1.0 -> 1.15) alongside the directional lights'
	# own energy dropping even further below -- per a further direct
	# correction, still too harsh. Most of the illumination now comes from
	# this soft, shadowless ambient floor, not the directional key/fill.
	env.ambient_light_energy = 1.15
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	viewport.add_child(world_env)

	# Key light at a real 3/4 angle off the camera's own forward axis, fill
	# from the opposite side so the shadowed half isn't pure black.
	# Positioned anywhere convenient and aimed via look_at(), same as the
	# camera above -- a DirectionalLight3D is direction-only (its position
	# doesn't affect the light itself), so this is just a reliable way to
	# derive that direction instead of hand-composing rotation_degrees.
	#
	# X offset widened (was sin(yaw)*2.0 -- with yaw fixed at 0, that's a
	# ~0 horizontal offset, putting the key light almost exactly where the
	# camera itself is) per direct correction: sitting the key light right
	# on the camera's own axis read as flat, harsh "flash photography"
	# lighting, not a modeled photo -- there's no angle between the light
	# and the lens for a shadow to actually fall away from the camera's
	# view, so nothing reads as three-dimensional. A genuine side angle
	# (KEY_LIGHT_OFFSET.x well past the fill/subject's own visible width)
	# gives the surface real shading instead.
	# Energy cut hard, twice now (0.95 -> 0.4 -> 0.2, fill 0.55 -> 0.25 ->
	# 0.12) per further direct correction -- still read as too harsh at
	# 0.4/0.25. Ambient above picked up the slack so the subject doesn't go
	# dim overall, just softer/less contrasty.
	const KEY_LIGHT_OFFSET := Vector3(1.7, 2.0, 1.1)
	const FILL_LIGHT_OFFSET := Vector3(-1.9, 1.0, -0.6)
	var key_light := DirectionalLight3D.new()
	key_light.light_energy = 0.2
	key_light.position = look_target + KEY_LIGHT_OFFSET
	# Same not-inside-tree fix as the camera above -- neither light is
	# parented yet at this point.
	key_light.look_at_from_position(key_light.position, look_target, Vector3.UP)
	viewport.add_child(key_light)

	var fill_light := DirectionalLight3D.new()
	fill_light.light_energy = 0.12
	fill_light.position = look_target + FILL_LIGHT_OFFSET
	fill_light.look_at_from_position(fill_light.position, look_target, Vector3.UP)
	viewport.add_child(fill_light)

	# viewport already entered the tree earlier (see the comment above,
	# right before the AABB measurement) -- camera/lights added after that
	# point still get their own _ready() immediately since their parent is
	# already live, so nothing further needs to happen here besides waiting
	# for the actual GPU render.
	#
	# A SubViewport's own render only actually happens starting the frame
	# after it (and anything newly added to it) enters the tree -- two
	# frames of margin so the readback below isn't grabbing a still-blank
	# first pass.
	await tree.process_frame
	await tree.process_frame

	var image := viewport.get_texture().get_image()
	_cache[key] = ImageTexture.create_from_image(image)

	viewport.queue_free()
	_capture_busy = false
	_pending.erase(key)


## The combined AABB, in the capture rig's own world space, of every
## MeshInstance3D under node (recursive) -- used to frame the camera off
## the blorb's own actual measured bounds instead of assumed constants
## (see _capture()'s own comment on why). find_children()'s owned=false is
## required here, not just a default left alone -- every mesh blorb.gd
## builds is created purely in code with no scene `owner` set, so the
## default owned=true would silently match nothing at all.
##
## MeshInstance3D specifically, NOT the broader VisualInstance3D -- per
## direct correction, that's what Light3D (so OmniLight3D) is ALSO a
## subclass of in Godot 4, and fire/electric blorbs carry a real
## OmniLight3D (see blorb.gd's _add_core_light(), omni_range=2.2) parented
## right onto the same mesh this walks. Its own get_aabb() is sized to that
## light's whole influence radius, not the ~0.3m blorb body -- merging it
## in inflated the measured bounds roughly 10x, computing a camera distance
## far past what the actual mesh needed and rendering exactly the
## "consistently smaller/farther away" symptom reported for the Electric
## blorb (independent of, and not fixed by, the separate stale-cache bug
## CAPTURE_VERSION addresses). Every actual renderable in this project is a
## MeshInstance3D (confirmed by grep, nothing else in blorb.gd/blorb_core.
## gd/blorb_suit.gd builds any other VisualInstance3D subclass), so
## narrowing the filter to it directly excludes lights (and any other
## non-geometry VisualInstance3D) rather than needing a special Light3D
## exclusion check.
static func _world_aabb(node: Node) -> AABB:
	var result := AABB()
	var has_any := false
	for descendant in node.find_children("*", "MeshInstance3D", true, false):
		var vi := descendant as MeshInstance3D
		var world_box: AABB = vi.global_transform * vi.get_aabb()
		if has_any:
			result = result.merge(world_box)
		else:
			result = world_box
			has_any = true
	return result
