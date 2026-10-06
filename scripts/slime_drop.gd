class_name SlimeDrop
extends Node3D

## A small glossy puddle of Blorb Slime, left behind by a wild blorb. Slime is
## blorb excretion; the only places anyone gets it are foraging these drops in the
## wild and the Tree of Life (which shares the blorbs' nature). Drops are
## transient: they dry out and sink away if nobody gathers them.

const LIFETIME := 540.0
const MAX_ACTIVE := 6
const SLIME_COLOR := Color(0.42, 0.92, 0.68)

var _age := 0.0
var _area: Area3D


## Leaves a drop at `world_position` unless too many already lie about.
static func leave(parent: Node, world_position: Vector3) -> void:
	var scene_tree := parent.get_tree()
	if scene_tree == null or scene_tree.get_nodes_in_group(&"slime_drops").size() >= MAX_ACTIVE:
		return
	var drop := SlimeDrop.new()
	drop.name = "BlorbSlimeDrop"
	parent.add_child(drop)
	drop.global_position = world_position


func _ready() -> void:
	add_to_group(&"slime_drops")
	var pool := SuperEgg.build_part(Vector3(0.34, 0.05, 0.28), SLIME_COLOR, 2.4, 2.4)
	pool.position.y = 0.04
	pool.rotation.y = randf() * TAU
	add_child(pool)
	var material := pool.get_surface_override_material(0) as StandardMaterial3D
	if material != null:
		material.roughness = 0.18
		material.emission_enabled = true
		material.emission = SLIME_COLOR
		material.emission_energy_multiplier = 0.35
	var bead := SuperEgg.build_part(Vector3(0.1, 0.09, 0.1), SLIME_COLOR.lightened(0.15), 2.2, 2.2)
	bead.position = Vector3(0.05, 0.12, -0.04)
	add_child(bead)
	CollisionPolicy.mark_decorative(pool)
	CollisionPolicy.mark_decorative(bead)
	_area = Interactable.attach(self, "Gather blorb slime", 1.6, _gather)


func _process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME - 20.0:
		# It dries and sinks into the ground before it goes.
		scale = Vector3.ONE * maxf((LIFETIME - _age) / 20.0, 0.01)
	if _age >= LIFETIME:
		queue_free()


func _gather() -> void:
	Inventory.add("Blorb Slime", ShopCatalog.BLORB_SLIME_COLOR)
	UISounds.play_foley(&"pickup", 0.5, get_instance_id())
	Hud.show_message("Gathered Blorb Slime.")
	queue_free()
