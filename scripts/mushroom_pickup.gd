class_name MushroomPickup
extends Area3D

## A wild mushroom growing in the world (see nature_props.gd's
## build_mushroom()) as a proximity-action pickup (see InteractionManager) --
## same collectible pattern as fruit.gd/flower_pickup.gd, just wrapping a
## cap-and-stem visual. This node IS the pickup Area3D itself, matching
## fruit.gd's own precedent for a scripted-only Area3D pickup (no dedicated
## .tscn).

@export var cap_color: Color = Color(0.75, 0.2, 0.15)
@export var mushroom_name: String = "Red Mushroom"

const PICKUP_RADIUS := 0.35

var _collected: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player only (see player.tscn)
	add_child(NatureProps.build_mushroom(cap_color))

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PICKUP_RADIUS
	shape.shape = sphere
	add_child(shape)

	set_meta("prompt", "Pick up %s" % mushroom_name.to_lower())
	set_meta("activate", _collect)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		InteractionManager.enter(self)


func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		InteractionManager.exit(self)


func _collect() -> void:
	if _collected:
		return
	_collected = true
	Inventory.add(mushroom_name, cap_color)
	Hud.show_message("Picked up the %s." % mushroom_name)
	queue_free()
