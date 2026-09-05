extends Node3D

## A single giant gorilla living out in the wider Primate Kingdom -- per
## direct instruction ("comparable size to [Humongous], but in the primate
## world, not in the village"), NOT part of jungle_kingdom_village.gd's own
## treehouse/ground-roamer population (see that file's own doc comment,
## specifically "the village"). Built on the same ApeTemplate rig every other
## ape/"primate template" monkey in this kingdom uses, just at a landmark-
## scale display_scale with movement_speed_multiplier slowed the same way
## blorb.gd's own wasteland giant, Humongous, is (that file's own
## movement_speed_multiplier doc comment: "the wasteland giant uses 0.1") --
## a creature this size lumbering instead of covering ground quickly just
## because its strides are long. GORILLA_NAME is a first-draft placeholder
## per direct instruction ("name TBD"), same as every other unspecified pick
## in this project -- adjustable on report.
##
## Also the destination for the placeholder "special banana" quest (see
## jungle_kingdom_village.gd's own quest-ape spawn): a Fruit pickup parented
## directly to this gorilla's own StaticBody3D root, at roughly the height of
## the top of his head, so it moves with him for free if he ever wanders.

const GORILLA_NAME := "Kova Kong"
const GORILLA_SCENE := "res://scenes/ape_template_preview.tscn"
## Per direct correction ("he should not be near the village, he should be
## in another part of the primate kingdom") -- the previous placement (140,
## -90, distance ~166 from the village clearing at the origin) was already
## well clear of it by ordinary XZ-distance standards, but at this creature's
## own landmark HEIGHT (see GORILLA_DISPLAY_SCALE below -- roughly 32m tall)
## he reads as visually dominant/"nearby" from much further away than that,
## poking up over the canopy from most of the kingdom. Pushed much further
## out instead of just a little, and onto a different bearing from the
## village-to-river line rather than merely further along the same one.
## Still well outside jungle_kingdom_village.gd's own CLEAR_RADIUS-24
## clearing around the origin and jungle_kingdom_terrain.gd's own river band
## (RIVER_BASE_Z 150, wandering +-60ish plus its own influence width) --
## first-draft placement, adjustable on report like every other unspecified
## position in this project.
const GORILLA_LOCAL_XZ := Vector2(400.0, -280.0)
## ApeTemplate's own scale=1.0 reads as roughly 2m tall (see this project's
## own established ProceduralFigure reference-height fact) -- 16x that is a
## true landmark scale, comparable in spirit to Humongous ("at least fifty
## times the size of a normal blorb," per docs/world_bible.md's own Blorbs
## section) without claiming an exact cross-species size equivalence that
## doesn't really exist between the two creatures' unrelated size units.
const GORILLA_DISPLAY_SCALE := 16.0
## Started matching blorb.gd's own movement_speed_multiplier value for
## Humongous exactly (0.1), per direct instruction ("his movements should be
## proportionally slowed down for his size just like [Humongous'] are").
## Doubled per a direct follow-up report ("the gorilla is moving too slow,
## speed should speed up by maybe 2X") -- ape_template_preview.gd's own
## _move_speed formula multiplies this straight in
## (ROAM_MOVE_SPEED * display_scale * movement_speed_multiplier), so doubling
## it here doubles his translation speed directly; the leg-swing cadence is
## deliberately NOT tied to this constant at all any more (see that file's
## own _ready() comment for the earlier "frozen legs" bug that came from
## doing exactly that), so this doesn't reintroduce that problem.
const GORILLA_MOVEMENT_SPEED_MULTIPLIER := 0.1
## Kova's enormous stride still needs to visibly cycle while his translation
## stays ponderous. This affects animation only; movement above remains slow.
const GORILLA_GAIT_SPEED_MULTIPLIER := 3.0
const GORILLA_ROAM_RADIUS := 42.0
const GORILLA_FUR_COLOR := Color(0.12, 0.11, 0.11)

## Special-quest banana reads as visually distinct from an ordinary
## NatureProps.FRUIT_COLORS["Banana"] pickup -- a warmer, more saturated gold
## instead of that const's plainer pale yellow -- and a bit larger, since it
## has to read clearly from the ground below a landmark-scale gorilla's head.
const SPECIAL_BANANA_COLOR := Color(1.0, 0.82, 0.05)
const SPECIAL_BANANA_RADIUS := 0.16
## How far above the head mesh's own true top (see get_head_top_global_
## position()) the banana sits -- just enough that it visibly rests ON the
## head rather than clipping into the scalp, not the old guessed-from-
## scratch total height. Small in absolute terms; the head-top position
## itself is already correct, this is only the "resting on the surface, not
## embedded in it" margin.
const BANANA_REST_HEIGHT := 0.3


func _ready() -> void:
	# Deferred -- see jungle_kingdom_village.gd's own _ready() comment for the
	# full reasoning: get_parent().add_child() below crashes ("Parent node is
	# busy setting up children") if called straight from _ready(), since this
	# node's own parent (the kingdom root) is still mid-setup, iterating its
	# own children's _ready() calls (this one included) at that exact moment.
	_spawn_gorilla.call_deferred()


func _spawn_gorilla() -> void:
	var terrain: Node = get_node_or_null("../Terrain")
	var packed := load(GORILLA_SCENE) as PackedScene
	if packed == null:
		return
	var gorilla := packed.instantiate() as ApeTemplatePreview
	gorilla.fur_color = GORILLA_FUR_COLOR
	gorilla.has_tail = false
	gorilla.body_type = 1.0
	gorilla.display_scale = GORILLA_DISPLAY_SCALE
	gorilla.movement_speed_multiplier = GORILLA_MOVEMENT_SPEED_MULTIPLIER
	gorilla.gait_speed_multiplier = GORILLA_GAIT_SPEED_MULTIPLIER
	gorilla.roam_radius = GORILLA_ROAM_RADIUS
	gorilla.parkour_collision = true
	gorilla.display_name = GORILLA_NAME
	var talk_lines: Array[String] = [
		"%s doesn't seem to notice you -- or much of anything down here." % GORILLA_NAME,
		"Something bright glints at the top of %s's head." % GORILLA_NAME,
	]
	gorilla.talk_lines = talk_lines
	var spawn_pos := Vector3(GORILLA_LOCAL_XZ.x, 0, GORILLA_LOCAL_XZ.y)
	if terrain != null and terrain.has_method("get_mesh_height"):
		spawn_pos.y = terrain.get_mesh_height(spawn_pos.x, spawn_pos.z)
	# Added under the KINGDOM ROOT (this node's own parent), NOT under `self`
	# -- ApeTemplatePreview's own terrain lookup is a soft
	# get_node_or_null("../Terrain") (see that file's own _ready()), which
	# only resolves correctly one level under the kingdom root, alongside
	# Player/Terrain, same as every other spawned NPC in this kingdom.
	# Seed the position before _ready(): ApeTemplatePreview captures its roam
	# centre there. Adding first used to capture (0, 0), making Kova literally
	# choose destinations back toward the village after being teleported here.
	gorilla.position = spawn_pos
	get_parent().add_child(gorilla)

	var banana := Fruit.new()
	banana.fruit_name = "Special Banana"
	banana.fruit_color = SPECIAL_BANANA_COLOR
	banana.radius = SPECIAL_BANANA_RADIUS
	banana.visual_builder = func() -> Node3D:
		return NatureProps.build_banana_fruit(SPECIAL_BANANA_COLOR, SPECIAL_BANANA_RADIUS)
	# CORRECTED per direct report ("the banana is not sitting on the top of
	# his head mesh, it's floating quite a bit in the air above his head") --
	# the OLD position guessed a total standing height (BANANA_HEIGHT_AT_
	# SCALE_1 * GORILLA_DISPLAY_SCALE) from the same "~2m at scale 1.0"
	# reference fact main.gd's own now-removed debug comment used, but that
	# reference was for a roughly upright figure -- this rig's own default
	# forward lean (ApeTemplatePreview's own spine_forward_bend, unset here
	# so it keeps ApeTemplate's default) means the head's real vertical
	# reach above the ground is noticeably LESS than that upright reference,
	# which is exactly what put the banana floating above the actual head.
	# get_head_top_global_position() reads the head mesh's own real built
	# AABB through its live (lean-included) transform instead, so this now
	# tracks the true head position regardless of pose.
	var head_top := gorilla.get_head_top_global_position()
	var banana_world_pos := head_top + Vector3(0, BANANA_REST_HEIGHT, 0)
	# Parented to the gorilla itself (not this node, not the world root) --
	# see this file's own class doc comment for why: it then tracks his
	# position for free, no per-frame code needed here at all. Converted to
	# the gorilla's own local space (not a plain world-relative offset) so
	# it stays correctly attached to the head as he rotates while roaming.
	banana.position = gorilla.to_local(banana_world_pos)
	gorilla.add_child(banana)
