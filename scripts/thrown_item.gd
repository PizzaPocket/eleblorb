class_name ThrownItem
extends Area3D

## A gem/antique flying through the air after being thrown from the
## player's hand. Manually-integrated gravity arc (matches this codebase's
## established "drive position by hand" convention -- see blorb.gd's/
## player.gd's terrain-snap) rather than a RigidBody3D. An Area3D, not a
## physics body, so hit detection is primarily body_entered against
## ordinary world/blorbs on collision layer 1, plus the giant blorb's
## throwable-only layer (it cannot use layer 1 because the player must pass
## through its goo). All blorbs add themselves to the "blorbs" group.
##
## Moves in _physics_process(), not _process() -- Area3D overlap detection
## is resolved by the physics server on its own fixed tick, and updating
## position there (rather than once per rendered frame, which can run at a
## different rate) keeps the collider's position in sync with when physics
## actually checks it. A small, fast-moving collider can also tunnel clean
## through a target within a single physics step if it only ever checks
## discrete positions before/after -- the swept raycast below catches that
## the way a bullet-physics system would, as a second, independent way to
## register the same hit.
##
## Per direct instruction, a throw that doesn't actually merge into a blorb
## (a clean miss, or a blorb hit that "doesn't react") isn't lost -- it
## lands where it comes down and stays there as an ordinary interaction-
## collect pickup (see _land()/_collect(), and InteractionManager), the same
## pattern gem.gd/fruit.gd/tokoin.gd use, rather than despawning. Only a
## successful merge actually consumes the item for good.

@export var item_name: String = ""

const GRAVITY := 9.8
const LIFETIME := 4.0
const SPIN_SPEED := 4.0
const HIT_RADIUS := 0.12
## Matches gem.gd's own PICKUP_RADIUS -- a landed item's collision shape is
## widened to this once it settles (see _land()), since HIT_RADIUS alone
## (sized for a fast-moving in-flight collider, not a pickup trigger) would
## read as an unreasonably fussy touch target for something just sitting
## still on the ground.
const PICKUP_RADIUS := 0.35

var velocity: Vector3 = Vector3.ZERO

var _age: float = 0.0
var _visual: Node3D = null
var _collision_shape: CollisionShape3D
var _resolved: bool = false
var _landed: bool = false

@onready var terrain: Node = get_node("../Terrain")


func _ready() -> void:
	collision_layer = 0
	# Ordinary world/blorbs use layer 1. The giant uses a dedicated layer so
	# gems can hit it without making its goo body solid to the player.
	collision_mask = 1 | Blorb.GIANT_THROWABLE_LAYER
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	_collision_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HIT_RADIUS
	_collision_shape.shape = sphere
	add_child(_collision_shape)

	var entry := ShopCatalog.find(item_name)
	if not entry.is_empty():
		_visual = entry["build_visual"].call(1.0)
		add_child(_visual)


func _physics_process(delta: float) -> void:
	if _landed:
		return

	var previous_position := global_position
	velocity.y -= GRAVITY * delta
	global_position += velocity * delta
	if _visual != null:
		_visual.rotate_x(SPIN_SPEED * delta)

	_age += delta
	if _age > LIFETIME:
		# A safety net for an arc that somehow never registers a hit within
		# LIFETIME (gravity should otherwise bring it down onto terrain well
		# before this) -- lands wherever it currently is rather than
		# vanishing, same as any other unresolved throw.
		_land()
		return

	if previous_position.distance_to(global_position) < 0.001:
		return
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(previous_position, global_position)
	query.collision_mask = collision_mask
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		_resolve_hit(result["collider"], result["position"], result["normal"])


## Routes the same Area3D's body_entered/body_exited signals to whichever
## behavior is currently active: in-flight hit detection before landing,
## InteractionManager registration (an ordinary collect prompt,
## see _land()/_collect()) after.
func _on_body_entered(body: Node3D) -> void:
	if _landed:
		if body is CharacterBody3D:
			InteractionManager.enter(self)
	else:
		_resolve_hit(body)


func _on_body_exited(body: Node3D) -> void:
	if _landed and body is CharacterBody3D:
		InteractionManager.exit(self)


func _resolve_hit(body: Node3D, hit_position: Variant = null, hit_normal: Variant = null) -> void:
	if _resolved:
		return

	if body.is_in_group("blorbs"):
		var entry := ShopCatalog.find(item_name)
		var element: String = entry.get("element", "") if not entry.is_empty() else ""
		var core_item: String = entry.get("core_item", "") if not entry.is_empty() else ""
		if element != "" and body.has_method("can_merge") and body.can_merge(element):
			_resolved = true
			body.merge_element(element)
			Hud.show_message("The %s merges into the blorb's core!" % item_name)
			queue_free()
			return
		if core_item != "" and body.has_method("add_core_item") and body.add_core_item(core_item):
			_resolved = true
			Hud.show_message("The %s settles into the blorb's core!" % item_name)
			Inventory.changed.emit()
			queue_free()
			return
		Hud.show_message("The blorb doesn't react.")

	_land(hit_position, hit_normal)


## Turns a resolved-but-unconsumed throw into an ordinary ground pickup --
## stops the flight physics, settles onto the struck or nearest solid
## support under its current XZ position, widens the same Area3D's collision shape from
## HIT_RADIUS to PICKUP_RADIUS (see that const's own comment) so standing
## near the resting item registers easily, and sets the "prompt"/"activate"
## meta InteractionManager reads (the same meta shape Interactable.attach()
## sets on its own created areas -- see tokoin.gd/fruit.gd's own doc
## comments for why a script that already IS the pickup Area3D sets these
## directly rather than going through that helper).
func _land(hit_position: Variant = null, hit_normal: Variant = null) -> void:
	if _resolved:
		return
	_resolved = true
	_landed = true
	velocity = Vector3.ZERO
	# `terrain` is intentionally typed as Node, so calls through it return a
	# Variant to the parser. Pin the scalar type before later ray-hit branches
	# assign their own numeric values.
	var landing_y: float = terrain.get_mesh_height(global_position.x, global_position.z)
	# A swept hit already gives the exact contact. Preserve upward-facing
	# surfaces such as canyon slabs instead of throwing that height away and
	# snapping through them to the terrain far below.
	if hit_position is Vector3 and hit_normal is Vector3 and (hit_normal as Vector3).y > 0.2:
		var contact := hit_position as Vector3
		global_position.x = contact.x
		global_position.z = contact.z
		landing_y = contact.y
	else:
		# body_entered has no contact point. Probe locally from just above the
		# projectile, catching the same layer-1 slabs/roofs/platforms the player
		# stands on without searching arbitrarily high overhead.
		var terrain_y: float = terrain.get_mesh_height(global_position.x, global_position.z)
		var from := global_position + Vector3.UP * 2.0
		var to := Vector3(global_position.x, terrain_y - 5.0, global_position.z)
		var query := PhysicsRayQueryParameters3D.create(from, to, 1)
		query.exclude = [get_rid()]
		var support := get_world_3d().direct_space_state.intersect_ray(query)
		if not support.is_empty():
			landing_y = support.position.y
	global_position.y = landing_y + HIT_RADIUS
	collision_mask = 2  # player only, matching gem.gd's own pickup area
	(_collision_shape.shape as SphereShape3D).radius = PICKUP_RADIUS
	set_meta("prompt", "Pick up %s" % item_name.to_lower())
	set_meta("activate", _collect)


func _collect() -> void:
	var entry := ShopCatalog.find(item_name)
	var color: Color = entry.get("color", Color.WHITE) if not entry.is_empty() else Color.WHITE
	Inventory.add(item_name, color)
	Hud.show_message("Picked up the %s." % item_name)
	queue_free()
