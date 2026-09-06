class_name SeedPellet
extends Area3D

## A single plant-power seed pellet: straight-line flight (no gravity,
## unlike thrown_item.gd's gem/antique arc -- this is a "pea-shooter" bolt,
## not a lobbed throw), hit-detected the same dual-layered way thrown_item.gd
## detects a fast-moving small collider (an Area3D body_entered signal, plus
## a swept raycast between the previous and current position each physics
## step to catch tunneling), and despawning outright on a hit or on a
## lifetime timeout rather than lingering as a pickup the way a missed
## ThrownItem does -- a stray pellet is a spent attack, not a collectible.
##
## Whoever fires a pellet (player.gd's own plant arm power, or a
## free-roaming plant blorb's autonomous attack) sets `damage`/
## `attacker_element` plus either `credit_blorbs` (the player-power case,
## which can credit XP to more than one currently-powered worn blorb -- see
## player.gd's _active_powered_blorbs()) or `attacker_blorb` (the
## autonomous-blorb case, a single attacker, matching every other blorb.gd
## attack's take_damage(amount, attacker) convention) before add_child()ing
## it into the scene.

const SPEED_DEFAULT := 14.0
const LIFETIME := 1.2
const HIT_RADIUS := 0.1
const PELLET_COLOR := Color(0.42, 0.62, 0.18)

var velocity: Vector3 = Vector3.ZERO
var damage: float = 0.0
var attacker_element: String = "plant"
var credit_blorbs: Array[Blorb] = []
var attacker_blorb: Blorb = null

var _age: float = 0.0
var _resolved: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_resolve_hit)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = HIT_RADIUS
	shape.shape = sphere
	add_child(shape)

	var visual := SuperEgg.build_part(Vector3(0.07, 0.09, 0.07), PELLET_COLOR, 3.0, 3.0)
	add_child(visual)


func _physics_process(delta: float) -> void:
	var previous_position := global_position
	global_position += velocity * delta

	_age += delta
	if _age > LIFETIME:
		queue_free()
		return

	if previous_position.distance_to(global_position) < 0.001:
		return
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(previous_position, global_position)
	query.collision_mask = collision_mask
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		_resolve_hit(result["collider"])


func _resolve_hit(target: Node3D) -> void:
	if _resolved or target == null:
		return
	if not target.is_in_group("skeletons") or not target.has_method("take_damage"):
		return
	_resolved = true
	# Explicit : String, not := -- target is a loosely-typed Node3D, so the
	# dynamic current_combat_element() call has no static return type for :=
	# to infer from (see player.gd's own identical comment/fix on this).
	var defender_element: String = (
		target.current_combat_element() if target.has_method("current_combat_element") else ""
	)
	var final_damage := damage * CombatMath.type_multiplier(attacker_element, defender_element)
	if attacker_blorb != null:
		target.take_damage(final_damage, attacker_blorb)
	else:
		if target.has_method("register_xp_participant"):
			for blorb in credit_blorbs:
				target.register_xp_participant(blorb)
		target.take_damage(final_damage)
	queue_free()
