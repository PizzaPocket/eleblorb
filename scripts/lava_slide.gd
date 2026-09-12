extends "res://scripts/npc.gd"

## Authored Fire Kingdom wanderer and keeper of the Lava Helm. His living head
## has its own compact cashew sweep; it is deliberately NOT the protective
## helm's oversized enclosing shell. The flame crest is the visual echo between
## him and the relic, while his armour follows the ordinary articulated rig.

const ARMOUR_COLOR := Color(0.075, 0.055, 0.048)
const METAL_EDGE := Color(0.32, 0.115, 0.045)
## A single bent pipe: fattest at the face, then narrowing gradually and
## smoothly toward each end, closing in a rounded dome (never a point) up
## and behind the left and right sides of the head. See
## _build_lava_slide_head_rings() and _head_pipe_center() below.
const HEAD_HALF_SPAN := 0.16
const HEAD_FACE_FORWARD := 0.17
const HEAD_TIP_BACK := 0.13
const HEAD_TIP_UP := 0.11
const HEAD_PIPE_RADIUS := 0.09
## Sizing reference for the burning-mohawk effect (see _build_cashew_head())
## -- roughly this head's own overall radius, not any one exact dimension.
const HEAD_VISUAL_RADIUS := 0.16
## How far left/right of center (in the same s units as _head_pipe_center(),
## [-1, 1]) each eye sits -- see _place_eye_on_head().
const HEAD_EYE_S_OFFSET := 0.18
## Signed offset from the exact surface point along the outward normal --
## positive stands the eye proud of the surface, negative embeds it.
## Started as a -0.01 inward embed (matching figure_eyes.gd's identical
## nudge for every other character), then -0.006 after that first number
## turned out to bury the whole thin eye mesh under the surface. Per direct
## report even that still wasn't enough -- the eyes were "about one cm away
## from being visible" -- so this is now a net +0.004 (the old -0.006 plus
## the full 1cm correction), standing them clearly proud of the surface.
const HEAD_EYE_SURFACE_OFFSET := 0.004


func _ready() -> void:
	display_name = "Lava Slide"
	talk_lines = [
		"Keep your balance near the bowls. The mountain never promises to hold still.",
		"Fire runs downhill, but it always remembers the summit.",
	]
	talk_override = _talk_to_lava_slide
	super._ready()


func _build_figure() -> void:
	super._build_figure()
	_add_taller_thorax()
	_build_cashew_head()
	_apply_lava_material(_arm_left)
	_apply_lava_material(_arm_right)
	_apply_lava_material(_elbow_left)
	_apply_lava_material(_elbow_right)
	_hand_left.material_override = NatureProps.build_lava_material()
	_hand_right.material_override = NatureProps.build_lava_material()
	_add_arm_flames(_arm_left, _elbow_left, _hand_left)
	_add_arm_flames(_arm_right, _elbow_right, _hand_right)
	_add_spaulder(_arm_left, -1.0)
	_add_spaulder(_arm_right, 1.0)
	_add_belt()
	_add_greave(_knee_left, _ankle_left)
	_add_greave(_knee_right, _ankle_right)
	_add_living_fire_cape()


## Recolors an upper-arm or forearm segment's own rendered mesh (the first
## MeshInstance3D _build_overlapping_segment() added directly under `pivot`
## -- see procedural_figure.gd's own _build_arm()) to the same molten-lava
## look as the head. Not used for the hands, which are already the
## MeshInstance3D themselves rather than a pivot with one as a child.
func _apply_lava_material(pivot: Node3D) -> void:
	for child in pivot.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).material_override = NatureProps.build_lava_material()
			return


## chest_build_scale (see lava_slide.tscn) only ever varies chest width/depth,
## never height -- per direct instruction in procedural_figure.gd, shared by
## every NPC. A taller thorax specifically for this character is done here
## instead, by growing the chest mesh itself around its own already-correct
## center rather than touching the shared rig builder.
func _add_taller_thorax() -> void:
	var thorax := _spine.get_node_or_null("ThoraxPivot")
	if thorax == null:
		return
	for child in thorax.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).scale.y *= 1.18
			return


func _build_cashew_head() -> void:
	var old_head_mesh: MeshInstance3D = null
	for child in _head.get_children():
		if child is MeshInstance3D:
			old_head_mesh = child as MeshInstance3D
			break
	if old_head_mesh == null:
		return

	var cashew := MeshInstance3D.new()
	cashew.name = "LivingCashewHead"
	cashew.mesh = BlorbBodyShape.build_mesh_from_rings(_build_lava_slide_head_rings())
	# The same molten-lava look shared by fire blorbs' own bodies and the
	# volcano's lava pool, per direct instruction, rather than dark rock.
	var lava := NatureProps.build_lava_material()
	cashew.material_override = lava
	# 15% larger per direct correction. Net position offset from the
	# original head placement: down 10cm then back up 4cm (-0.06), and back
	# 5cm then back 4cm more (-0.09) -- it was floating up off the neck and
	# sitting too far forward.
	cashew.scale = Vector3.ONE * 1.15
	cashew.position = old_head_mesh.position + Vector3(0.0, -0.06, -0.09)
	_head.add_child(cashew)
	_extend_neck_to_head()

	# Keep the established living-eye meshes and blink state, but turn their
	# normally vertical ovals into Lava Slide's characteristic broad eyes,
	# then place each explicitly on this head's own generated surface --
	# reparent()'s keep-global-transform argument otherwise leaves each eye
	# sitting wherever it was on the original humanoid head shape, which
	# bears no relation to this one.
	# Per direct request, the same eye-on-surface system the fire-kingdom
	# villagers already use for their own lava-colored skin (FigureEyes.
	# add_eyes(), called with their actual skin_color): darken the real
	# current surface color by the standard fraction. Not the fire blorb's
	# own eyes -- those are actually built against the pre-element default
	# body_color (blorb.gd's own _build_visuals() runs before merge_element()
	# ever touches the body's color), an accident of build order rather than
	# a deliberate lava-matched contrast rule, so not the one to copy here.
	var eye_material := StandardMaterial3D.new()
	eye_material.albedo_color = lava.albedo_color.darkened(0.25)
	eye_material.roughness = 0.8
	for i in _eyes.size():
		var eye := _eyes[i] as MeshInstance3D
		if eye == null:
			continue
		eye.reparent(cashew, true)
		# Captured before _place_eye_on_head() below replaces eye.basis
		# outright (a fresh orthonormal frame, which resets the decomposed
		# scale to 1,1,1) -- setting .scale is only safe to do AFTER basis
		# is in its final orientation, per figure_eyes.gd's own ordering.
		var flatten_z := eye.scale.z
		# More rounded per direct request. EPSILON_SOFT (what every other
		# figure's eyes use, via figure_eyes.gd) is boxier than a plain
		# ellipse; 2.0 is as round as a SuperEgg profile goes (see
		# superegg.gd's own "don't go below 2" note). Rebuilt at the same
		# semi-axes the original mesh already had, read back from its own
		# AABB, rather than a guessed size.
		var old_extents: Vector3 = (eye.mesh as ArrayMesh).get_aabb().size * 0.5
		eye.mesh = SuperEgg.build_mesh(old_extents, 2.0, 2.0)
		eye.set_surface_override_material(0, eye_material)
		_place_eye_on_head(eye, (-1.0 if i == 0 else 1.0) * HEAD_EYE_S_OFFSET)
		# Inner tips rolled down a few degrees per direct request, applied
		# here (basis still a clean rotation, no scale yet) rather than
		# after the anisotropic scale below, which would shear a roll
		# instead of cleanly tilting it. Derived, not yet visually
		# confirmed: local +X is this eye's own "right" and local Z its
		# outward surface normal, a right-handed frame (right = up x
		# outward), so a positive roll here takes +X toward +Y (up). The
		# left eye (i=0, s<0) has its inner (medial) tip at its own +X, so
		# a NEGATIVE roll takes that tip toward -Y (down); the right eye's
		# inner tip sits at its own -X instead, where the mirrored positive
		# roll does the same. Flag which eye specifically if this reads
		# backwards or lands as "outer tips" instead.
		var roll_sign := -1.0 if i == 0 else 1.0
		eye.rotate_object_local(Vector3(0.0, 0.0, 1.0), roll_sign * deg_to_rad(8.0))
		# Position/orientation confirmed correct per direct report -- shape
		# tuned further per direct correction ("even wider and even shorter
		# height"): X raised again (1.65 -> 1.9), Y cut again (0.3 -> 0.18).
		eye.scale = Vector3(1.9, 0.18, flatten_z)
	old_head_mesh.visible = false
	BlorbSuit._add_lava_mohawk(cashew, HEAD_VISUAL_RADIUS)
	# Sat floating above the head mass -- brought down to the mesh surface.
	var mohawk := cashew.get_node_or_null("BurningMohawk")
	if mohawk != null:
		(mohawk as Node3D).position.y -= 0.06


## The head just moved down 10cm (see _build_cashew_head()) to stop it
## floating above the body -- stretch the neck mesh itself up to close the
## gap, rather than moving NeckPivot (which would also drag the shared rig's
## head_pivot/HEAD_RAISE math along with it).
func _extend_neck_to_head() -> void:
	var neck_pivot := _head.get_parent()
	if neck_pivot == null:
		return
	for child in neck_pivot.get_children():
		if child is MeshInstance3D:
			var neck := child as MeshInstance3D
			neck.scale.y *= 1.6
			neck.material_override = NatureProps.build_lava_material()
			return


## A single bent pipe, fattest at the face and narrowing gradually and
## smoothly toward each end, exactly the way every other rounded part in
## this game (SuperEgg's own ellipsoid poles) closes off: parametrized by an
## angle phi swept uniformly from -PI/2 to PI/2, position-along-the-pipe
## from sin(phi) and radius from cos(phi) -- the same matched sin/cos pair
## that makes a sphere's pole read as a smooth dome rather than a cone,
## applied here along a bent centerline instead of a straight vertical axis.
## Each ring is a real circular cross section built from an actual tangent
## frame -- what made earlier attempts at this shape read as a lumpy
## revolved blob instead of a bent tube. Retune via the HEAD_* constants
## above; this loop itself shouldn't need to change.
func _build_lava_slide_head_rings() -> Array:
	const RING_COUNT := 32
	const RADIAL_SEGMENTS := 16
	var rings: Array = []
	for ring_index in RING_COUNT + 1:
		var phi: float = -PI * 0.5 + PI * float(ring_index) / float(RING_COUNT)
		var s := sin(phi)
		var radius := HEAD_PIPE_RADIUS * cos(phi)
		var center := _head_pipe_center(s)
		var tangent := _head_pipe_tangent(s)
		var right := tangent.cross(Vector3.UP)
		right = right.normalized() if right.length() > 0.001 else Vector3.RIGHT
		var up := right.cross(tangent).normalized()
		var ring: Array[Vector3] = []
		for segment in RADIAL_SEGMENTS:
			var angle: float = TAU * float(segment) / float(RADIAL_SEGMENTS)
			# Negated sin term -- build_mesh_from_rings()'s winding read this
			# loop's original direction as facing inward, showing the
			# inside of the mesh instead of the outside.
			ring.append(center + (right * cos(angle) - up * sin(angle)) * radius)
		rings.append(ring)
	return rings


## The pipe's own centerline, keyed directly by s in [-1, 1] (s=-1 the left
## tip's own position, s=0 the face, s=1 the right tip): X sweeps
## left-to-right straight across, while Z (forward at the face, back out
## toward either tip) and Y (lowest at the face, highest at both tips) are
## even functions of s -- the same backward/upward sweep at both ends,
## mirrored.
func _head_pipe_center(s: float) -> Vector3:
	var x := s * HEAD_HALF_SPAN
	var z := HEAD_FACE_FORWARD * (1.0 - s * s) - HEAD_TIP_BACK * s * s
	var y := HEAD_TIP_UP * s * s
	return Vector3(x, y, z)


func _head_pipe_tangent(s: float) -> Vector3:
	const STEP := 0.01
	return (
		_head_pipe_center(minf(s + STEP, 1.0)) - _head_pipe_center(maxf(s - STEP, -1.0))
	).normalized()


## The exact point (and outward normal) on the real generated mesh surface
## at lateral position `s` and the frontmost angle around that cross
## section -- theta=0 in _build_lava_slide_head_rings()'s own ring loop,
## i.e. `center + tube_right * radius` there. Built from the identical
## center/tangent/radius math that loop uses, so this is guaranteed to land
## exactly on the mesh rather than some independently-eyeballed offset.
func _head_pipe_surface_sample(s: float) -> Dictionary:
	var phi := asin(clampf(s, -1.0, 1.0))
	var radius := HEAD_PIPE_RADIUS * cos(phi)
	var center := _head_pipe_center(s)
	var tangent := _head_pipe_tangent(s)
	var tube_right := tangent.cross(Vector3.UP)
	tube_right = tube_right.normalized() if tube_right.length() > 0.001 else Vector3.RIGHT
	return {"point": center + tube_right * radius, "outward": tube_right}


## Places `eye` exactly on this head's own generated surface at lateral
## position `s`, oriented the same way figure_eyes.gd orients every other
## character's eyes: flattened along the horizontal component of the
## surface's outward normal, tall axis pinned to true world UP.
func _place_eye_on_head(eye: MeshInstance3D, s: float) -> void:
	var sample := _head_pipe_surface_sample(s)
	var outward: Vector3 = sample["outward"]
	var horizontal_outward := Vector3(outward.x, 0.0, outward.z).normalized()
	var right := Vector3.UP.cross(horizontal_outward).normalized()
	eye.basis = Basis(right, Vector3.UP, horizontal_outward)
	eye.position = (sample["point"] as Vector3) + horizontal_outward * HEAD_EYE_SURFACE_OFFSET


func _add_arm_flames(upper: Node3D, lower: Node3D, hand: MeshInstance3D) -> void:
	# Separate local emitters follow the articulated upper arm, forearm, and
	# hand instead of estimating the whole arm from the shoulder alone.
	var upper_fire := _build_fire_sheath(Vector3(0.085, 0.30, 0.085), Vector2(0.13, 0.34), 32)
	upper_fire.position.y = -0.27
	upper.add_child(upper_fire)
	var lower_fire := _build_fire_sheath(Vector3(0.08, 0.25, 0.08), Vector2(0.12, 0.30), 27)
	lower_fire.position.y = -0.22
	lower.add_child(lower_fire)
	var hand_fire := _build_fire_sheath(Vector3(0.11, 0.11, 0.11), Vector2(0.14, 0.23), 20)
	hand_fire.position = Vector3(0.0, -0.03, 0.0)
	hand.add_child(hand_fire)


func _build_fire_sheath(extents: Vector3, quad_size: Vector2, amount: int) -> GPUParticles3D:
	var fire := GPUParticles3D.new()
	fire.local_coords = true
	fire.amount = amount
	fire.lifetime = 0.42
	fire.randomness = 0.52
	fire.visibility_aabb = AABB(Vector3(-1.2, -1.2, -1.2), Vector3(2.4, 2.4, 2.4))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = extents
	process.direction = Vector3(0.0, 0.75, -0.28).normalized()
	process.spread = 36.0
	process.initial_velocity_min = 0.35
	process.initial_velocity_max = 0.85
	process.gravity = Vector3(0.0, 0.32, 0.0)
	process.color_ramp = _flame_ramp()
	process.scale_curve = ParticleFX.build_scale_curve(0.35, 1.0, 0.34, 0.08)
	fire.process_material = process
	var quad := QuadMesh.new()
	quad.size = quad_size
	var material := ParticleFX.build_billboard_material(ParticleFX.build_soft_gradient_texture(32, 1.45, 0.2), Color.WHITE, true, 0.0)
	material.vertex_color_use_as_albedo = true
	quad.material = material
	fire.draw_pass_1 = quad
	return fire


func _flame_ramp() -> GradientTexture1D:
	return ParticleFX.build_color_ramp([
		{"offset": 0.0, "color": Color(1.0, 0.94, 0.42, 0.96)},
		{"offset": 0.4, "color": Color(1.0, 0.29, 0.025, 0.84)},
		{"offset": 1.0, "color": Color(0.45, 0.018, 0.004, 0.0)},
	])


func _armour_material(color: Color = ARMOUR_COLOR) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.42
	material.metallic = 0.26
	return material


func _add_spaulder(arm: Node3D, side: float) -> void:
	var root := Node3D.new()
	root.name = "HornedSpaulder"
	# Raised 10cm per direct correction. Lateral offset confirmed backwards
	# by direct report -- side * positive moves this pivot's own local X
	# toward the neck, not away from it, on this specific arm pivot (not to
	# be assumed for any other pivot -- see the figure-rig skill) -- so
	# side * -1 is the outward direction. Per a further direct correction,
	# the plate itself (not the spike, see horn.position below) then moved
	# 3cm back inward: -0.10 + 0.03 (inward) = -0.07.
	root.position = Vector3(side * -0.07, 0.055, 0.0)
	arm.add_child(root)
	# Per direct correction (twice now), the plate was still too large after
	# an initial 0.8 cut -- scaled down further to a little over half its
	# original (0.23, 0.13, 0.24) size.
	var shell_size := Vector3(0.23, 0.13, 0.24) * 0.55
	var shell := SuperEgg.build_part(shell_size, ARMOUR_COLOR, 2.1, SuperEgg.EPSILON_FLAT)
	shell.material_override = _armour_material()
	root.add_child(shell)
	var horn := MeshInstance3D.new()
	horn.name = "SpaulderSpike"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.05
	cone.height = 0.22
	cone.radial_segments = 10
	horn.mesh = cone
	horn.material_override = _armour_material(METAL_EDGE)
	# Kept deliberately large relative to the now-smaller shell, planted
	# near the top-center of its dome (not the outer rim, where the surface
	# slopes away and the previous attempt's spike ended up mostly buried),
	# and stood close to vertical so most of its length rises clearly above
	# the shell's own top surface instead of leaning back along its curve.
	var surface_y := shell_size.y * 0.85
	var embed := cone.height * 0.15
	# Per direct correction (four times now), moved further outward from
	# the shell's own root, away from the figure's meridian -- side * -1 is
	# outward, the same confirmed convention as root.position.x above.
	# 0.35 -> -0.02 -> -0.06 -> -0.09 -> -0.10 (this one, moving in the
	# confirmed correct direction each time, just needing more distance).
	horn.position = Vector3(
		side * (shell_size.x * 0.35 - 0.10), surface_y + cone.height * 0.5 - embed, -shell_size.z * 0.05
	)
	# Was leaning inward toward the head by 12 degrees (a sign error) --
	# flipped to lean outward instead, plus the requested additional 20
	# degrees of outward roll on top (12 + 20 = 32).
	horn.rotation.z = side * deg_to_rad(32.0)
	root.add_child(horn)


func _add_belt() -> void:
	# Fit the belt to the authored hip geometry rather than guessing against
	# SpinePivot coordinates. It is parented to the hip mesh itself, so these
	# bounds are already in exactly the local space the belt will inhabit and
	# remain correct for this character's lean hip_build_scale.
	var hip_bounds: AABB = _hips.get_aabb()
	var half_width: float = hip_bounds.size.x * 0.5
	var half_depth: float = hip_bounds.size.z * 0.5
	var half_height: float = minf(hip_bounds.size.y * 0.16, 0.034)
	var belt_center_y: float = hip_bounds.end.y - half_height * 1.05
	var belt := SuperEgg.build_part(
		Vector3(half_width + 0.012, half_height, half_depth + 0.010),
		Color(0.12, 0.055, 0.025), SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	belt.name = "Belt"
	belt.position = Vector3(0.0, belt_center_y, 0.0)
	_hips.add_child(belt)
	var buckle := MeshInstance3D.new()
	buckle.name = "HexagonBuckle"
	var hex := CylinderMesh.new()
	var buckle_radius: float = minf(half_width * 0.34, half_height * 1.8)
	hex.top_radius = buckle_radius
	hex.bottom_radius = buckle_radius
	hex.height = 0.026
	hex.radial_segments = 6
	hex.material = _armour_material(Color(0.78, 0.36, 0.075))
	buckle.mesh = hex
	buckle.position = Vector3(0.0, belt_center_y, hip_bounds.end.z + 0.024)
	buckle.rotation.x = PI * 0.5
	_hips.add_child(buckle)


func _add_greave(knee: Node3D, ankle: Node3D) -> void:
	var greave := MeshInstance3D.new()
	greave.name = "FlaredGreave"
	var flare := CylinderMesh.new()
	flare.top_radius = 0.085
	flare.bottom_radius = 0.15
	flare.height = 0.42
	flare.radial_segments = 12
	flare.material = _armour_material()
	greave.mesh = flare
	greave.position.y = -0.22
	knee.add_child(greave)
	var sabaton := SuperEgg.build_part(Vector3(0.15, 0.085, 0.25), ARMOUR_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT)
	sabaton.name = "FlaredSabaton"
	sabaton.material_override = _armour_material()
	sabaton.position = Vector3(0.0, -0.055, 0.115)
	ankle.add_child(sabaton)


func _add_living_fire_cape() -> void:
	var cape := GPUParticles3D.new()
	cape.name = "LivingFireCape"
	cape.local_coords = true
	cape.amount = 115
	cape.lifetime = 0.82
	cape.randomness = 0.48
	cape.position = Vector3(0.0, 0.13, -0.24)
	cape.visibility_aabb = AABB(Vector3(-1.5, -2.2, -1.2), Vector3(3.0, 3.4, 2.4))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(0.31, 0.045, 0.025)
	process.direction = Vector3(0.0, -0.96, -0.28).normalized()
	process.spread = 13.0
	process.initial_velocity_min = 0.95
	process.initial_velocity_max = 1.7
	process.gravity = Vector3(0.0, -0.25, -0.1)
	process.particle_flag_align_y = true
	process.color_ramp = _flame_ramp()
	process.scale_curve = ParticleFX.build_scale_curve(0.5, 1.15, 0.45, 0.08)
	cape.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.58)
	var material := ParticleFX.build_billboard_material(ParticleFX.build_soft_gradient_texture(32, 1.55, 0.2), Color.WHITE, true, 0.0)
	material.vertex_color_use_as_albedo = true
	quad.material = material
	cape.draw_pass_1 = quad
	_spine.add_child(cape)


func _talk_to_lava_slide() -> bool:
	if WorldState.lava_slide_helm_gifted:
		return false
	# Per direct instruction, an item transaction through dialogue is a real
	# player decision, not an unconditional grant the instant the line
	# appears: a single response ("Receive Lava Helm"), the whole
	# interaction paused while it's up (pause_game=true), and only the
	# feedback alert -- not the line itself -- confirms the item actually
	# landed in the inventory. Declining (the dialog's own always-present
	# dismiss response) leaves lava_slide_helm_gifted false, so the offer
	# comes back next time he's talked to.
	var actions: Array[Dictionary] = [
		{"label": "Receive Lava Helm", "callback": _on_receive_lava_helm},
	]
	DialogUI.show_line(
		display_name,
		"The mountain made this for a traveller willing to meet fire face-first. Take the Lava Helm.",
		actions, "Not yet.", Callable(), true
	)
	return true


func _on_receive_lava_helm() -> void:
	WorldState.lava_slide_helm_gifted = true
	if not Inventory.has("Lava Helm"):
		Inventory.add("Lava Helm", Color(0.035, 0.03, 0.028))
	# Closes (and un-pauses, per DialogUI.hide_dialog()'s own pause
	# bookkeeping) before the feedback alert, matching the established
	# "action callback closes its own dialog" convention (see npc.gd's
	# vendor "Let me see your wares." action).
	DialogUI.hide_dialog()
	Hud.show_passive_message("Lava Helm was added to your inventory!", 2.8)
