extends Node3D

## PROTOTYPE Sky Kingdom -- a small cluster of cloud islands among the
## world's own ordinary sky clouds, built from quartz-and-gold pavilions,
## home to the Tempestars (see docs/world_bible.md). Per direct instruction,
## this place is "otherwise totally turned off": normally invisible and
## non-collidable, revealed only while the player's own worn head blorb
## carries the Bird Helm (Blorbaka's own core item -- see
## BlorbSuitController.has_head_bird_helm()). Checked every frame off the
## human player's own suit specifically, not whichever companion the player
## currently controls, since this is about what the PLAYER is physically
## wearing, not who they're piloting.
##
## Per direct correction, the islands themselves are NOT a new cloud
## material or a separate higher altitude band -- they use the exact same
## unshaded white puff recipe and the exact same altitude range (see
## CloudScatter's own altitude_min/altitude_max) as the ordinary ambient
## clouds already scattered through the sky, so a revealed island reads as
## one of the world's own clouds turning out to be solid ground, not a
## distant new layer.

## Per direct instruction, the Sky Kingdom now starts right at the existing
## cloud-parkour landing (the same cloud that holds the Air Gem, at the top
## of the spiral staircase up from town -- see town_generator.gd's own
## _build_sky_stairs() and cloud_scatter.gd's own build_sky_course()) and
## extends outward from there, oriented away from the starting village --
## see _resolve_layout()'s own comment for how that position/direction is
## found at runtime rather than hand-guessed, since the actual landing
## position depends on a long chain of preceding procedural-generation RNG
## draws that isn't practical to reproduce by hand.
## Local offsets are (forward, right, height) relative to that away-from-
## village direction, not raw world XYZ -- see _to_world_offset().
## Per direct correction ("welcome to extend the sky kingdom to be larger
## and each little cloud kingdom to be larger among itself") -- these, the
## island radii below, and every offset here are scaled up together (~1.5x)
## from their original values, keeping the same relative layout/gaps
## between islands rather than just growing each island in place until they
## start overlapping their neighbors.
const CAPITAL_LOCAL_OFFSET := Vector3(45.0, 0.0, 22.0)
const SATELLITE_LOCAL_OFFSETS: Array[Vector3] = [
	Vector3(128.0, 72.0, 8.0),
	Vector3(93.0, -75.0, -15.0),
	Vector3(195.0, 0.0, 21.0),
]
const QUARTZ_COLOR := Color(0.86, 0.9, 0.98)
const GOLD_COLOR := Color(0.86, 0.68, 0.28)
## Matches CloudScatter.PUFF_HEIGHT_FACTOR/DAY_COLOR exactly -- see this
## file's own class doc on why the cloud material must not be new.
const PUFF_HEIGHT_FACTOR := 0.6
const CLOUD_DAY_COLOR := Color(1.0, 1.0, 1.0)
## Matches _build_cloud_pad()'s own collision box height (radius*0.55)
## halved -- the actual walkable top surface, in island-local Y.
const PAD_COLLISION_HALF_HEIGHT := 0.275
## Absolute clearance (not radius-scaled -- a Tempestar's own real-world
## size doesn't scale with the island) above that surface a Tempestar
## hovers, generous enough to clear TornadoTail's own funnel reaching below
## its root and still read as visibly floating rather than resting on it.
const TEMPESTAR_HOVER_HEIGHT := 2.2
## Fallback only -- see _pad_surface_height_at()'s own class doc for why
## every structure now grounds itself against the pad's own REAL local
## surface height instead of this single flat guess (which is what caused
## "the new structures... are just totally sunk down into the clouds so
## that only the roofs are visible" wherever the true puff surface nearby
## sat higher than this constant assumed).
const STRUCTURE_GROUND_Y_RATIO := 0.14
## How far below the real local pad surface a structure's own base plants,
## per direct correction ("sunk down pretty far into the clouds... not
## super far") -- a small, deliberate embed for a grounded look, not the
## much larger, position-dependent burial STRUCTURE_GROUND_Y_RATIO used to
## cause.
const STRUCTURE_EMBED_RATIO := 0.05

## Per direct correction ("looks a bit dark... can have more variety") --
## brighter overall and widened from 6 to 8 entries each, leaning into
## pastel sky/dawn/dusk hues (sky blue, cotton-candy pink, golden dawn,
## lavender, mint, peach) rather than the muted storm-grey tones the
## original palette leaned on too heavily.
const TEMPESTAR_SKIN_COLORS: Array[Color] = [
	Color(0.85, 0.9, 0.98), Color(0.96, 0.82, 0.88),
	Color(0.94, 0.8, 0.6), Color(0.84, 0.78, 0.95),
	Color(0.98, 0.78, 0.7), Color(0.78, 0.92, 0.88),
	Color(0.99, 0.92, 0.7), Color(0.72, 0.82, 0.96),
]
const TEMPESTAR_HAIR_COLORS: Array[Color] = [
	Color(0.96, 0.96, 0.99), Color(0.55, 0.62, 0.92),
	Color(0.95, 0.82, 0.4), Color(0.6, 0.85, 0.88),
	Color(0.92, 0.55, 0.62), Color(0.78, 0.82, 0.9),
	Color(0.98, 0.68, 0.42), Color(0.74, 0.6, 0.92),
]
const TEMPESTAR_HAIR_STYLES: Array[String] = [
	FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_FLAT_TOP,
	FigureHair.STYLE_PONYTAIL, FigureHair.STYLE_BUN,
	FigureHair.STYLE_AFRO, FigureHair.STYLE_LONG,
]
## Per direct correction ("they all look like quite muted dark earthen
## tones... they very much would be wearing much lighter tones closer to
## like a very light sky blue or a very light dusk purple or very light
## almost cloud color") -- explicitly those three named tones (light sky
## blue, light dusk purple, near-white cloud), doubled up with two subtler
## variants of each for a little variety without drifting toward anything
## muted or earthen. _ensure_clothing_contrast() below picks a DIFFERENT
## entry from this same light palette when needed, rather than darkening
## one of them -- darkening was the earlier (wrong) fix for skin/clothing
## contrast, and is exactly what was muddying these into "muted dark"
## tones whenever a pick landed too close to that Tempestar's own pale
## skin.
const TEMPESTAR_CLOTHING_COLORS: Array[Color] = [
	Color(0.72, 0.83, 0.97), Color(0.83, 0.75, 0.93),
	Color(0.94, 0.95, 0.98), Color(0.8, 0.89, 0.96),
	Color(0.87, 0.8, 0.95), Color(0.9, 0.92, 0.96),
]

## Per direct instruction: unique names, personalities, and dialogue per
## NPC-generation convention (matching every other populated village in
## this project -- see docs/world_bible.md), each aware of their own world.
## The line each carries plants two things atmospherically rather than
## explaining them outright (per this project's own "no heavy-handed
## hints" rule): the world's own air blorbs having gone strangely missing
## up here, and the quiet friction of a "kingdom" that's really just many
## small, isolated rulers with no one else's cloud to answer to. See
## docs/world_bible.md's own Sky Kingdom entry for the fuller context.
const TEMPESTAR_ROSTER: Dictionary = {
	"Highcloud": {
		"ruler": {
			"name": "Cumulus Highvane", "is_female": false,
			"line": "Every cloud out here answers to somebody smaller than the last. Mine's simply the tallest of the small crowns. Though I'll admit the updrafts used to carry company besides the wind.",
		},
		"attendants": [
			{
				"name": "Squall Windrider", "is_female": true,
				"line": "I keep his ledgers straight and his robes from blowing clean off the edge. Someone has to. It's quieter work than it sounds, up here where there's nothing left to argue over but the weather.",
			},
			{
				"name": "Breeze Suncrest", "is_female": false,
				"line": "I used to chase little drifting blorbs through these clouds when I was small. Haven't seen one in longer than I can count. Just the clouds now, going about their business without them.",
			},
		],
	},
	"the Anvil Cloud": {
		"ruler": {
			"name": "Nimbus Greywisp", "is_female": true,
			"line": "This is my anvil, my own weather, my own say. Cumulus can keep his height. I don't need his cloud looking down on mine to know mine's worth keeping.",
		},
		"attendants": [],
	},
	"the Drift Cloud": {
		"ruler": {
			"name": "Gale Stormwick", "is_female": false,
			"line": "A kingdom of one cloud is still a kingdom, they tell me. Some days it feels more like a very well-appointed exile. I'd trade the crown for an actual neighbor.",
		},
		"attendants": [],
	},
	"the Hollow Cloud": {
		"ruler": {
			"name": "Cirro Ashveil", "is_female": true,
			"line": "They call it the Hollow Cloud because there's nothing in the middle of it. I used to think that meant something was missing. Now I just think it means nobody's filled it in yet.",
		},
		"attendants": [],
	},
}

var _player: Player
var _visible_now := false
var _islands: Array[Node3D] = []
var _cloud_material: StandardMaterial3D
var _tempestar_index := 0
## Per direct correction (performance): this whole prototype -- 4 islands,
## ~40 cloud puffs, ~28 pavilion pieces, and up to 9 full Tempestar NPC rigs
## -- used to be built unconditionally in _ready(), paying its full
## construction cost (including per-piece SurfaceTool/generate_normals()
## work) even on a run that never once puts on the Bird Helm, which is the
## overwhelmingly common case. It's now built lazily, the first time the
## suit actually reveals it, and never at all otherwise.
var _built := false


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Player


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	var suit := _player.get_own_blorb_suit()
	var should_show := is_instance_valid(suit) and suit.has_head_bird_helm()
	if should_show == _visible_now:
		return
	if should_show and not _built:
		_build_all_islands()
	_set_kingdom_active(should_show)


func _build_all_islands() -> void:
	_built = true
	_ensure_cloud_material()
	var landing := _resolve_landing()
	var away := _resolve_away_direction(landing)
	var capital_pos := landing + _to_world_offset(CAPITAL_LOCAL_OFFSET, away)
	_islands.append(_build_island(capital_pos, 46.0, true, "Highcloud"))
	var satellite_cloud_names := ["the Anvil Cloud", "the Drift Cloud", "the Hollow Cloud"]
	for i in SATELLITE_LOCAL_OFFSETS.size():
		var satellite_pos := landing + _to_world_offset(SATELLITE_LOCAL_OFFSETS[i], away)
		_islands.append(_build_island(satellite_pos, 30.0, false, satellite_cloud_names[i]))
	# Freshly built islands default to visible/collidable (see
	# _build_island()'s own pieces) -- _set_kingdom_active(true) runs
	# immediately after this returns (see _physics_process() above), so
	# there's no need to also force an initial inactive pass here.


## The actual cloud that holds the Air Gem, recorded by CloudScatter itself
## once build_sky_course() runs (see that function's own comment) -- this
## is only ever null/zero if the sky stairs somehow never got built at all,
## which shouldn't happen in practice, so the fallback is a rough guess
## rather than something worth engineering further.
func _resolve_landing() -> Vector3:
	var clouds := get_node_or_null("../Clouds") as CloudScatter
	if clouds != null and clouds.last_sky_course_landing != Vector3.ZERO:
		return clouds.last_sky_course_landing
	return Vector3(30.0, 110.0, -60.0)


## "Away from the starting village" -- approximated as away from the
## world's own origin (where the player spawns, see main.tscn's own Player
## transform), since the landing cloud is already always well out from
## there by construction (the crate spiral alone starts 55-85m out from
## town center, then the cloud course itself drifts further) -- this reads
## as "keep going the way the staircase was already headed" without also
## needing to fetch town_center from a separate Terrain node reference.
func _resolve_away_direction(landing: Vector3) -> Vector2:
	var flat := Vector2(landing.x, landing.z)
	return flat.normalized() if flat.length() > 1.0 else Vector2(1.0, 0.0)


## `local_offset` is (forward-along-`away`, right-of-`away`, height) --
## letting every island's own placement stay meaningful regardless of
## which real compass direction the staircase actually happened to end up
## heading in.
func _to_world_offset(local_offset: Vector3, away: Vector2) -> Vector3:
	var right := Vector2(-away.y, away.x)
	var flat := away * local_offset.x + right * local_offset.y
	return Vector3(flat.x, local_offset.z, flat.y)


func _set_kingdom_active(active: bool) -> void:
	_visible_now = active
	for island in _islands:
		island.visible = active
		for body in island.find_children("*", "StaticBody3D", true, false):
			var static_body := body as StaticBody3D
			if not static_body.has_meta("sky_kingdom_layer"):
				static_body.set_meta("sky_kingdom_layer", static_body.collision_layer)
			static_body.collision_layer = (static_body.get_meta("sky_kingdom_layer") as int) if active else 0
		# Tempestars are always direct children of their own island (see
		# _spawn_tempestar()), so a plain child scan is enough here -- no
		# need to rely on find_children()'s type filter recognizing a
		# GDScript class_name rather than only native engine classes.
		for child in island.get_children():
			if child is Tempestar:
				child.set_process(active)


## Exact same recipe as CloudScatter._ensure_material() -- unshaded so
## lighting/day-night never darkens it, double-sided since a puff cluster is
## seen from underneath while flying up to it.
func _ensure_cloud_material() -> void:
	if _cloud_material != null:
		return
	_cloud_material = StandardMaterial3D.new()
	_cloud_material.albedo_color = CLOUD_DAY_COLOR
	_cloud_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_cloud_material.cull_mode = BaseMaterial3D.CULL_DISABLED


## One cloud island: a real walkable pad built from the same overlapping-
## puff cloud shape as the ordinary ambient sky, plus a quartz-and-gold
## pavilion at its center -- the capital's own is simply bigger and gets
## three residents (a ruler plus two attendants) instead of the single
## ruler every smaller cloud gets, matching "they just have their own cloud
## and they're the little ruler of their own tiny kingdom."
func _build_island(world_pos: Vector3, radius: float, is_capital: bool, cloud_name: String) -> Node3D:
	var island := Node3D.new()
	island.name = ("Capital_" if is_capital else "Satellite_") + cloud_name.replace(" ", "")
	island.position = world_pos
	add_child(island)

	_build_cloud_pad(island, radius)
	# Per direct correction ("not much variety... only one large pavilion --
	# each cloud kingdom can be larger and have multiple types of
	# interesting structures... an amalgamation of mythical heavenly
	# kingdoms") -- one main pavilion still anchors the island, but it's now
	# joined by a scattered mix of spires, standing obelisks, a gathering
	# court, and a proper cluster of resident dwellings instead of standing
	# alone. Seeded per-island (off its own radius) so the exact mix/
	# placement is deterministic but varies between islands.
	var rng := RandomNumberGenerator.new()
	rng.seed = int(radius * 7919.0)
	var pavilion_base := Vector3(
		0.0, _pad_surface_height_at(island, 0.0, 0.0, radius) - radius * STRUCTURE_EMBED_RATIO, 0.0
	)
	# Per direct correction ("structures shouldn't be clipping into the
	# columns of the big Palace structures") -- smaller relative to the
	# island than before (the island itself grew, see CAPITAL_LOCAL_OFFSET's
	# own comment, so the palace's own ABSOLUTE size barely changes), which
	# is what actually opens up real, guaranteed-clear room around it for
	# _scatter_landmarks() to use (see that function's own min_dist).
	var pavilion_radius := radius * (0.38 if is_capital else 0.28)
	_build_pavilion(island, pavilion_base, pavilion_radius, 6 if is_capital else 4)
	_scatter_landmarks(island, radius, is_capital, pavilion_radius, rng)

	# Per direct correction ("they seem to be really clipping into the
	# clouds... positioned hovering above the clouds, ideally") -- the pad's
	# own collision top sits at radius*PAD_COLLISION_HALF_HEIGHT (see
	# _build_cloud_pad()'s own box height), and TornadoTail's funnel
	# extends a good distance below a Tempestar's own root on top of that.
	# TEMPESTAR_HOVER_HEIGHT is an absolute (not radius-scaled) clearance,
	# since the funnel's own real-world size doesn't scale with the island.
	var tempestar_y := radius * PAD_COLLISION_HALF_HEIGHT + TEMPESTAR_HOVER_HEIGHT
	# Per direct correction ("wandering... just walking straight through
	# objects and pillars") -- there's no real obstacle avoidance in
	# TempestarS' own simple wander (see tempestar.gd), so residents now
	# stand and drift near the island's own open rim instead of among the
	# architecture clustered at its center, and wander a shorter distance
	# so they're less likely to drift back into it.
	var roster: Dictionary = TEMPESTAR_ROSTER[cloud_name]
	var ruler: Dictionary = roster["ruler"]
	_spawn_tempestar(island, Vector3(0.0, tempestar_y, radius * 0.82), ruler, cloud_name, true)
	var attendants: Array = roster["attendants"]
	var attendant_angles := [PI * 0.62, -PI * 0.62]
	for i in attendants.size():
		var attendant: Dictionary = attendants[i]
		var angle: float = attendant_angles[i % attendant_angles.size()]
		var attendant_pos := Vector3(sin(angle) * radius * 0.82, tempestar_y, cos(angle) * radius * 0.82)
		_spawn_tempestar(island, attendant_pos, attendant, cloud_name, false)
	return island


## Built from the exact same clustered, overlapping, squashed-SuperEgg-puff
## shape CloudScatter uses for the ordinary ambient sky (see that file's own
## _place_cloud()) -- just enough puffs, sized and packed densely enough, to
## read as one continuous walkable cloud rather than the sparser ambient
## look. Real collision is one plain box sized to the cluster's own visual
## footprint (tagged on the biggest central puff so CollisionPolicy's own
## solid/parkour-visual-needs-a-collider bookkeeping still balances); every
## other puff is decorative.
func _build_cloud_pad(island: Node3D, radius: float) -> void:
	var pad := StaticBody3D.new()
	pad.name = "CloudPad"
	pad.collision_layer = 1
	pad.collision_mask = 0
	island.add_child(pad)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(radius * 1000.0)
	var puff_count := 10
	var center_puff: MeshInstance3D = null
	for i in puff_count:
		var angle := TAU * float(i) / float(puff_count - 1) if i > 0 else 0.0
		var offset_radius := 0.0 if i == 0 else radius * rng.randf_range(0.45, 0.85)
		# Center puff enlarged from 0.55 to 0.72 -- per direct correction
		# ("welcome to extend the sky kingdom... each little cloud kingdom
		# to be larger"), this is also what SAFE_STRUCTURE_RATIO's own
		# guaranteed-coverage derivation now assumes; raise them together.
		var puff_radius := radius * (0.72 if i == 0 else rng.randf_range(0.35, 0.55))
		var semi_axes := Vector3(puff_radius, puff_radius * PUFF_HEIGHT_FACTOR, puff_radius)
		var puff := MeshInstance3D.new()
		puff.mesh = SuperEgg.build_mesh(semi_axes, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		# Matches CloudScatter._place_cloud()'s own convention -- lets
		# _pad_surface_height_at() below query this puff's real surface
		# height instead of every structure guessing one flat constant.
		puff.set_meta("cloud_semi_axes", semi_axes)
		puff.material_override = _cloud_material
		puff.position = Vector3(
			cos(angle) * offset_radius, rng.randf_range(-radius * 0.05, radius * 0.05), sin(angle) * offset_radius
		)
		pad.add_child(puff)
		if i == 0:
			center_puff = puff
		else:
			CollisionPolicy.mark_decorative(puff)
	# Per direct correction ("some kind of solid bottom you can't fly
	# through... don't give anything a bottom, just assume the cloud itself
	# will serve as the bottom") -- the box's own bottom face now sits at
	# y=0 instead of extending symmetrically below the pad's own local
	# origin, so a player approaching from underneath passes through open
	# air right up to the walkable top surface instead of hitting an
	# invisible floor first. The top height is unchanged (still
	# radius*PAD_COLLISION_HALF_HEIGHT, which _build_island()'s own
	# Tempestar hover math and every structure below still assume).
	var pad_collision_height := radius * PAD_COLLISION_HALF_HEIGHT
	CollisionPolicy.add_box(
		pad, center_puff, Vector3(radius * 1.7, pad_collision_height, radius * 1.7),
		Vector3(0.0, pad_collision_height * 0.5, 0.0), Basis(), true
	)


## Real per-position surface height of this island's own cloud pad, in
## island-local space -- same superellipsoid surface formula
## CloudScatter.get_support_height_at() uses, just read directly off this
## pad's own puffs (tagged above) instead of a shared node elsewhere. The
## pad's puffs vary a lot in height by position (tallest near the always-
## present center puff, lower or higher elsewhere depending on where the
## randomly-placed satellite puffs landed) -- placing a structure at one
## flat guessed height buried several of them up past their own roofline
## wherever the real puff surface there happened to sit higher, reported as
## "the new structures... are just totally sunk down into the clouds so
## that only the roofs are visible." Falls back to the old flat estimate
## only if no puff actually covers this point (shouldn't happen inside
## SAFE_STRUCTURE_RATIO).
func _pad_surface_height_at(island: Node3D, x: float, z: float, radius: float) -> float:
	var pad := island.get_node_or_null("CloudPad")
	if pad == null:
		return radius * STRUCTURE_GROUND_Y_RATIO
	var best: Variant = null
	for puff_node in pad.get_children():
		if not puff_node is MeshInstance3D or not puff_node.has_meta("cloud_semi_axes"):
			continue
		var puff := puff_node as MeshInstance3D
		var axes: Vector3 = puff.get_meta("cloud_semi_axes")
		var center: Vector3 = puff.position
		var horizontal_profile := pow(absf((x - center.x) / axes.x), SuperEgg.EPSILON_SOFT) + pow(absf((z - center.z) / axes.z), SuperEgg.EPSILON_SOFT)
		if horizontal_profile > 1.0:
			continue
		var top: float = center.y + axes.y * pow(1.0 - horizontal_profile, 1.0 / SuperEgg.EPSILON_SOFT)
		if best == null or top > (best as float):
			best = top
	return (best as float) if best != null else radius * STRUCTURE_GROUND_Y_RATIO


func _quartz_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = QUARTZ_COLOR
	material.metallic = 0.15
	material.roughness = 0.08
	return material


func _gold_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = GOLD_COLOR
	material.metallic = 0.85
	material.roughness = 0.22
	return material


## A small quartz-and-gold structure: slender glassy columns supporting a
## faceted gold roof -- per direct instruction, "the material of the
## buildings and structures are going to be made out of quartz and gold."
## First-pass silhouette, deliberately simple pending real design. Its own
## columns start right at y=0, resting directly on the cloud pad's own
## surface with no separate floor slab of its own -- see _scatter_landmarks()'s
## own comment on why nothing here gets its own solid bottom.
func _build_pavilion(island: Node3D, center: Vector3, column_radius: float, column_count: int) -> void:
	var height := column_radius * 3.4
	var quartz_material := _quartz_material()
	var gold_material := _gold_material()

	var pavilion := StaticBody3D.new()
	pavilion.name = "Pavilion"
	pavilion.collision_layer = 1
	pavilion.collision_mask = 0
	pavilion.position = center
	island.add_child(pavilion)

	for i in column_count:
		var angle := TAU * float(i) / float(column_count)
		var column_pos := Vector3(cos(angle), 0.0, sin(angle)) * column_radius
		var column := MeshInstance3D.new()
		column.mesh = SuperEgg.build_mesh(
			Vector3(column_radius * 0.14, height * 0.5, column_radius * 0.14), 2.6, 2.6
		)
		column.material_override = quartz_material
		column.position = column_pos + Vector3(0.0, height * 0.5, 0.0)
		pavilion.add_child(column)
		CollisionPolicy.add_cylinder(
			pavilion, column, column_radius * 0.14, height, column.position, false
		)

	# Per direct correction ("look like weird mushrooms") -- a proper
	# pitched roof, not a wide, flat, overhanging cap on a thin trunk (the
	# exact silhouette that reads as a mushroom). Tall relative to its own
	# base width, flat on the bottom (flush with the columns) but genuinely
	# pointed at the top (epsilon below 2.0 pulls a superellipsoid's own
	## profile into a true cone/witch's-hat point rather than staying dome-
	# shaped -- see superegg.gd's own class doc on that specific behavior).
	var roof_radius := column_radius * 1.15
	var roof_height := column_radius * 1.3
	var roof := MeshInstance3D.new()
	roof.mesh = SuperEgg.build_mesh(
		Vector3(roof_radius, roof_height * 0.5, roof_radius), 1.35, SuperEgg.EPSILON_FLAT
	)
	roof.material_override = gold_material
	roof.position = Vector3(0.0, height + roof_height * 0.5, 0.0)
	pavilion.add_child(roof)
	CollisionPolicy.add_box(
		pavilion, roof, Vector3(roof_radius * 1.5, roof_height, roof_radius * 1.5),
		roof.position, Basis(), true
	)

	# Per direct correction ("the gold bits at the top... shouldn't just be
	# decorative. They should be platformable.") -- small but real
	# collision instead of mark_decorative(), so the peak itself is a
	# landable perch.
	var finial := MeshInstance3D.new()
	finial.mesh = SuperEgg.build_mesh(Vector3.ONE * column_radius * 0.16, 2.4, 2.4)
	finial.material_override = gold_material
	finial.position = Vector3(0.0, height + roof_height + column_radius * 0.16, 0.0)
	pavilion.add_child(finial)
	CollisionPolicy.add_box(
		pavilion, finial, Vector3.ONE * column_radius * 0.32, finial.position, Basis(), true
	)


## Scatters a varied mix of landmarks around the island's own pavilion --
## per direct correction, "not much variety... only one large pavilion,"
## this is what actually gives each cloud its own distinct silhouette
## instead of every island repeating the same single building. Every
## structure here plants at that exact (x,z)'s own REAL local pad surface
## height (see _pad_surface_height_at()) minus a small STRUCTURE_EMBED_RATIO
## sink for a grounded look, not a single flat offset from the island's own
## origin -- a flat guess buried several structures up past their own
## roofline wherever the real puff surface nearby happened to sit higher,
## reported as "the new structures... are just totally sunk down into the
## clouds so that only the roofs are visible." Nothing here builds a
## separate floor/base slab of its own -- every
## structure simply rests directly on the cloud pad's own already-
## established walkable surface, per direct correction ("don't give
## anything a bottom, just assume the cloud itself will serve as the
## bottom of their structure").
## Per direct correction ("be careful not to build out over the edge of
## clouds or even close to the edge of clouds since they curve down at the
## rounded side of the superegg cloud shape") -- max placement distance is a
## fraction of this, not of `radius` directly. Derived, not guessed:
## _build_cloud_pad()'s ALWAYS-present center puff (radius*0.72, epsilon
## 3.0) mathematically covers at LEAST out to its own full puff radius in
## every direction (the worst case sits exactly on the X/Z axes; an epsilon
## above 2 actually bulges further out than that at the diagonals, never
## less) -- so capping every scatter distance at 0.65, a bit under that 0.72
## guarantee, means _pad_surface_height_at() always finds a real puff under
## a structure and never falls back to its own flat guess, regardless of
## where the random satellite puffs happened to land.
const SAFE_STRUCTURE_RATIO := 0.65
## Per direct correction ("a lot of these structures seem to just be
## overlapping each other. So please make sure that nothing overlaps of any
## of the structures in these sky villages") -- every placement below now
## goes through _find_clear_position(), which rejects candidates too close
## to anything already placed (min_dist alone only ever protected the
## pavilion, not structures from each other).
const STRUCTURE_OVERLAP_MARGIN := 0.6
func _scatter_landmarks(
	island: Node3D, radius: float, is_capital: bool, pavilion_radius: float, rng: RandomNumberGenerator
) -> void:
	var embed := radius * STRUCTURE_EMBED_RATIO
	# Per direct correction ("structures shouldn't be clipping into the
	# columns of the big Palace structures") -- min_dist is the pavilion's
	# own real column radius plus a real physical gap, not a guessed
	# fraction, so nothing placed below can ever land inside its colonnade.
	# max_dist is the guaranteed-safe radius derived above. Every structure
	# below picks its own distance from within this one shared band instead
	# of an independent (and sometimes overlapping-the-pavilion) range.
	var min_dist := pavilion_radius + radius * 0.11
	var max_dist := radius * SAFE_STRUCTURE_RATIO
	var placed: Array[Dictionary] = []

	var spire_count := 2 if is_capital else 1
	for i in spire_count:
		var spire_scale := radius * rng.randf_range(0.22, 0.3)
		var offset := _find_clear_position(placed, min_dist, max_dist, spire_scale * 0.55, rng, 0.55, 0.85)
		var pos := Vector3(offset.x, _pad_surface_height_at(island, offset.x, offset.y, radius) - embed, offset.y)
		_build_spire(island, pos, spire_scale)

	var obelisk_count := rng.randi_range(3, 5) if is_capital else rng.randi_range(2, 3)
	for i in obelisk_count:
		var obelisk_scale := radius * rng.randf_range(0.1, 0.16)
		var offset := _find_clear_position(placed, min_dist, max_dist, obelisk_scale * 0.3, rng, 0.05, 0.95)
		var pos := Vector3(offset.x, _pad_surface_height_at(island, offset.x, offset.y, radius) - embed, offset.y)
		_build_obelisk(island, pos, obelisk_scale)

	# Per direct correction ("these kingdoms are supposed to not only be
	# simply the single palace structures, but also their kingdoms...
	# shouldn't each cloud also make space for a few basic cloud structures.
	# Some equivalent of a cloud person's home"). Count trimmed down a
	# further direct correction ("entirely too many columns") -- fewer,
	# less crowded dwellings, plus the overlap check above now genuinely
	# limits how many can fit anyway.
	var dwelling_count := rng.randi_range(5, 7) if is_capital else rng.randi_range(3, 4)
	for i in dwelling_count:
		var dwelling_scale := radius * rng.randf_range(0.09, 0.13)
		var offset := _find_clear_position(placed, min_dist, max_dist, dwelling_scale * 1.3, rng, 0.25, 1.0)
		var pos := Vector3(offset.x, _pad_surface_height_at(island, offset.x, offset.y, radius) - embed, offset.y)
		_build_dwelling(island, pos, dwelling_scale, rng.randf_range(0.0, TAU))


## Picks a random (x,z) offset within [min_dist, max_dist] of the island's
## own center that doesn't overlap anything already in `placed` (each entry
## a {"pos": Vector2, "radius": float} footprint circle), retrying a few
## times before giving up and placing anyway rather than looping forever or
## leaving a gap in the scatter. Appends its own footprint to `placed` on
## return, so later calls this same island also avoid it.
func _find_clear_position(
	placed: Array[Dictionary], min_dist: float, max_dist: float, footprint: float,
	rng: RandomNumberGenerator, dist_min_frac: float, dist_max_frac: float
) -> Vector2:
	var band := max_dist - min_dist
	var candidate := Vector2.ZERO
	for attempt in 12:
		var angle := rng.randf_range(0.0, TAU)
		var dist := min_dist + band * rng.randf_range(dist_min_frac, dist_max_frac)
		candidate = Vector2(cos(angle), sin(angle)) * dist
		var clear := true
		for other in placed:
			var other_pos: Vector2 = other["pos"]
			var other_radius: float = other["radius"]
			if candidate.distance_to(other_pos) < footprint + other_radius + STRUCTURE_OVERLAP_MARGIN:
				clear = false
				break
		if clear:
			break
	placed.append({"pos": candidate, "radius": footprint})
	return candidate


## A tiered pagoda-like watchtower -- a quartz trunk threaded through
## several shrinking gold-rimmed tiers, echoing the stepped-pagoda roofs of
## the Chinese village's own palace but reimagined in cloud-kingdom quartz
## and gold. `scale` is a rough overall size reference, not a literal
## Node3D scale.
func _build_spire(island: Node3D, position: Vector3, scale: float) -> void:
	var quartz_material := _quartz_material()
	var gold_material := _gold_material()
	var spire := StaticBody3D.new()
	spire.name = "Spire"
	spire.collision_layer = 1
	spire.collision_mask = 0
	spire.position = position
	island.add_child(spire)

	const TIER_COUNT := 4
	var trunk_radius := scale * 0.1
	var tier_spacing := scale * 0.5
	var total_height := tier_spacing * TIER_COUNT
	var trunk := MeshInstance3D.new()
	trunk.mesh = SuperEgg.build_mesh(Vector3(trunk_radius, total_height * 0.5, trunk_radius), 2.6, 2.6)
	trunk.material_override = quartz_material
	trunk.position = Vector3(0.0, total_height * 0.5, 0.0)
	spire.add_child(trunk)
	CollisionPolicy.add_cylinder(spire, trunk, trunk_radius, total_height, trunk.position, false)

	for tier_index in TIER_COUNT:
		var tier_t := float(tier_index) / float(TIER_COUNT - 1)
		var tier_radius := lerpf(scale * 0.55, scale * 0.22, tier_t)
		var tier_y := tier_spacing * float(tier_index + 1)
		var tier := MeshInstance3D.new()
		tier.mesh = SuperEgg.build_mesh(
			Vector3(tier_radius, scale * 0.05, tier_radius), 2.2, SuperEgg.EPSILON_FLAT
		)
		tier.material_override = gold_material
		tier.position = Vector3(0.0, tier_y, 0.0)
		spire.add_child(tier)
		CollisionPolicy.add_box(
			spire, tier, Vector3(tier_radius * 2.0, scale * 0.14, tier_radius * 2.0),
			tier.position, Basis(), true
		)

	# Platformable, not decorative -- per direct correction ("the gold bits
	# at the top... should be platformable").
	var finial := MeshInstance3D.new()
	finial.mesh = SuperEgg.build_mesh(Vector3.ONE * scale * 0.1, 2.4, 2.4)
	finial.material_override = gold_material
	finial.position = Vector3(0.0, total_height + scale * 0.15, 0.0)
	spire.add_child(finial)
	CollisionPolicy.add_box(spire, finial, Vector3.ONE * scale * 0.2, finial.position, Basis(), true)


## A genuinely purposeful communal space -- per direct correction, the old
## "shrine" (a ring of gold-capped posts around a monument) was "just a
## bunch of pillars with round things on top, not really adding anything to
## the architecture." This is an open gathering spot instead: a low gold
## ring marker sitting directly on the cloud (no floor slab of its own --
## A small standing quartz needle capped in gold -- filler detail scattered
## around an island, purely decorative (no collision -- small enough that
## solid ground beneath it, or a bigger neighboring landmark, already
## covers anyone walking near it).
func _build_obelisk(island: Node3D, position: Vector3, scale: float) -> void:
	var quartz_material := _quartz_material()
	var gold_material := _gold_material()
	var obelisk := Node3D.new()
	obelisk.name = "Obelisk"
	obelisk.position = position
	island.add_child(obelisk)

	var height := scale * 1.6
	var base_radius := scale * 0.16
	var body := MeshInstance3D.new()
	body.mesh = SuperEgg.build_mesh(
		Vector3(base_radius, height * 0.5, base_radius), 2.4, SuperEgg.EPSILON_FLAT
	)
	body.material_override = quartz_material
	body.position = Vector3(0.0, height * 0.5, 0.0)
	obelisk.add_child(body)
	CollisionPolicy.mark_decorative(body)

	var cap := MeshInstance3D.new()
	cap.mesh = SuperEgg.build_mesh(Vector3.ONE * base_radius * 0.7, 2.6, 2.6)
	cap.material_override = gold_material
	cap.position = Vector3(0.0, height + base_radius * 0.5, 0.0)
	obelisk.add_child(cap)
	CollisionPolicy.mark_decorative(cap)


## A small dwelling -- rebuilt per direct correction ("we want them to be
## enterable interiors... you keep breaking the rule that none of these sky
## kingdom structures should have floors... they can be open air, they
## don't need walls the way regular village structures do... make any of
## these abodes taller"). No solid walls and no floor at all: an open-air
## colonnade (posts holding up a roof, exactly the pavilion's own
## construction just smaller/humbler) is trivially enterable -- there's
## nothing blocking the way in -- and has nothing that could ever read as a
## "bottom." Two offset post clusters (a main room plus a smaller alcove,
## at `alcove_angle` around the main one) keep the irregular, not-simple-
## square footprint from the previous version without needing solid walls
## to get there. Taller than the old walled version throughout: per direct
## instruction, a structure's own base sinking a bit into the cloud is a
## known, accepted physical feature of building here, not a bug to hide --
## so it's built tall enough to clear that and still read as a real,
## substantial structure above it.
func _build_dwelling(island: Node3D, position: Vector3, scale: float, alcove_angle: float) -> void:
	var quartz_material := _quartz_material()
	var gold_material := _gold_material()
	var dwelling := StaticBody3D.new()
	dwelling.name = "Dwelling"
	dwelling.collision_layer = 1
	dwelling.collision_mask = 0
	dwelling.position = position
	island.add_child(dwelling)

	# Per direct correction ("entirely too many columns. Got to have less
	# columns") -- 4 posts for the main room, 3 for the smaller alcove
	# (still enough to visibly hold up a roof, not a dense colonnade).
	var main_radius := scale * 0.75
	_build_dwelling_cluster(dwelling, Vector3.ZERO, main_radius, scale * 1.9, 4, quartz_material, gold_material)

	var alcove_radius := main_radius * 0.6
	var alcove_offset := Vector3(cos(alcove_angle), 0.0, sin(alcove_angle)) * (main_radius * 0.95)
	_build_dwelling_cluster(
		dwelling, alcove_offset, alcove_radius, scale * 1.9 * 0.75, 3, quartz_material, gold_material
	)


## An open-air colonnade -- `post_count` slender quartz posts spaced evenly
## around a circle of `radius`, holding up one pitched gold roof. No walls,
## no floor: walking between the posts IS the entrance, so there's nothing
## further to build to make this "enterable." Shared by both of
## _build_dwelling()'s own offset clusters -- see that function's own class
## doc.
func _build_dwelling_cluster(
	dwelling: StaticBody3D, local_offset: Vector3, radius: float, height: float, post_count: int,
	quartz_material: StandardMaterial3D, gold_material: StandardMaterial3D
) -> void:
	var post_radius := radius * 0.12
	# Per direct correction ("the columns should go all the way up to touch
	# the roof that they're supporting") -- the roof's own underside (a
	# SuperEgg pole) narrows as it approaches its exact bottom point, so a
	# post ending flush at the roof's own nominal base height could still
	# read as falling short of the roof's actual visible surface there.
	# Extending each post's own top a bit further up, into the roof's
	# lower volume, guarantees real contact regardless of that taper.
	var post_height := height + radius * 0.15
	for i in post_count:
		var angle := TAU * float(i) / float(post_count)
		var post_pos := local_offset + Vector3(cos(angle), 0.0, sin(angle)) * radius
		var post := MeshInstance3D.new()
		post.mesh = SuperEgg.build_mesh(Vector3(post_radius, post_height * 0.5, post_radius), 2.6, 2.6)
		post.material_override = quartz_material
		post.position = post_pos + Vector3(0.0, post_height * 0.5, 0.0)
		dwelling.add_child(post)
		CollisionPolicy.add_cylinder(dwelling, post, post_radius, post_height, post.position, false)

	var roof_height := height * 0.5
	var roof := MeshInstance3D.new()
	roof.mesh = SuperEgg.build_mesh(
		Vector3(radius * 1.15, roof_height * 0.5, radius * 1.15), 1.3, SuperEgg.EPSILON_FLAT
	)
	roof.material_override = gold_material
	roof.position = local_offset + Vector3(0.0, height + roof_height * 0.5, 0.0)
	dwelling.add_child(roof)
	# Platformable, same reasoning as every other roof/gold peak here.
	CollisionPolicy.add_box(
		dwelling, roof, Vector3(radius * 1.5, roof_height, radius * 1.5), roof.position, Basis(), true
	)


## Steps through TEMPESTAR_SKIN_COLORS/HAIR_COLORS/FUNNEL_COLORS/HAIR_STYLES
## at different intervals (same trick ocean_kingdom_city.gd's own
## _spawn_merfolk() uses for its palette arrays) so residents don't end up
## as monochrome matching sets -- per direct instruction, "a palette of
## sky-related skins and hairs, in the way that the sea people have their
## sea-related palette."
func _spawn_tempestar(island: Node3D, local_pos: Vector3, identity: Dictionary, cloud_name: String, is_ruler: bool) -> void:
	var index := _tempestar_index
	_tempestar_index += 1
	var tempestar := Tempestar.new()
	tempestar.display_name = identity["name"] as String
	tempestar.dialogue_text = identity["line"] as String
	tempestar.is_ruler = is_ruler
	tempestar.is_female = identity["is_female"] as bool
	# Shorter than before ("wandering... just walking straight through
	# objects and pillars") -- keeps residents nearer the open rim they're
	# placed at rather than drifting back toward the architecture at the
	# island's own center.
	tempestar.wander_radius = 3.0
	tempestar.skin_color = TEMPESTAR_SKIN_COLORS[index % TEMPESTAR_SKIN_COLORS.size()]
	tempestar.hair_color = TEMPESTAR_HAIR_COLORS[(index * 2 + 1) % TEMPESTAR_HAIR_COLORS.size()]
	tempestar.hair_style = TEMPESTAR_HAIR_STYLES[index % TEMPESTAR_HAIR_STYLES.size()]
	var clothing_index := (index * 3 + 2) % TEMPESTAR_CLOTHING_COLORS.size()
	tempestar.clothing_color = _ensure_clothing_contrast(
		tempestar.skin_color, clothing_index, TEMPESTAR_CLOTHING_COLORS
	)
	# Per direct correction ("the sky people seem to all be wearing t-shirt
	# upper body clothing... they should have a range") -- sleeve_style was
	# never actually set here at all, so every Tempestar fell back to its
	# own single hardcoded default. Per a further direct correction ("the
	# sky folk should have the same shirt options as the mer folk"), this
	# is now the exact same 2-way split ocean_kingdom_city.gd's own
	# _spawn_merfolk() uses, not a separate 3-way scheme.
	tempestar.sleeve_style = (
		ProceduralFigure.SLEEVE_STYLE_NONE if index % 3 == 0 else ProceduralFigure.SLEEVE_STYLE_SHORT
	)
	# Per direct correction ("a little bit too blindingly white... give it a
	# slight bit of tone... in the direction of the palette of the sky
	# people") -- still the same real unshaded material technique as before
	# (so it keeps reading as genuine cloud material, not a lookalike shaded
	# one), just a separate, slightly tinted copy instead of the exact pure-
	# white ambient cloud material.
	_ensure_tornado_material()
	tempestar.funnel_color = _tornado_material.albedo_color
	tempestar.funnel_material = _tornado_material
	tempestar.position = local_pos
	island.add_child(tempestar)


## Both TEMPESTAR_SKIN_COLORS and TEMPESTAR_CLOTHING_COLORS independently
## lean pale/pastel (the "sky-themed" look), so some index combinations
## landed on a skin/clothing pair too close to tell apart. Per direct
## correction ("make sure there's differentiation between... the sky
## people's clothing and their bodies"), picks a DIFFERENT entry from the
## same light clothing palette when the first pick is too close to that
## Tempestar's own skin -- an EARLIER version of this darkened the clothing
## color instead, which (given how uniformly pale both palettes already
## are) was quietly muddying most Tempestars' clothes toward exactly the
## "muted dark earthen tones" reported as wrong; staying inside the curated
## light palette can't reproduce that.
const CLOTHING_CONTRAST_MIN_DISTANCE := 0.22
func _ensure_clothing_contrast(skin: Color, clothing_index: int, palette: Array[Color]) -> Color:
	var clothing := palette[clothing_index]
	var diff := Vector3(clothing.r - skin.r, clothing.g - skin.g, clothing.b - skin.b)
	if diff.length() >= CLOTHING_CONTRAST_MIN_DISTANCE:
		return clothing
	return palette[(clothing_index + palette.size() / 2) % palette.size()]


## A separate, slightly-toned copy of the shared cloud material (same
## unshaded/double-sided recipe -- see _ensure_cloud_material()'s own class
## doc for why unshaded specifically matters here) rather than reusing the
## ambient sky's own pure-white one directly.
var _tornado_material: StandardMaterial3D
func _ensure_tornado_material() -> void:
	if _tornado_material != null:
		return
	_tornado_material = StandardMaterial3D.new()
	_tornado_material.albedo_color = CLOUD_DAY_COLOR.lerp(Color(0.8, 0.84, 0.94), 0.14)
	_tornado_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_tornado_material.cull_mode = BaseMaterial3D.CULL_DISABLED
