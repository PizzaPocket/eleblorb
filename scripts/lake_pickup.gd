class_name LakePickup
extends Area3D

## A collectible found on the exposed shore or lake floor. Its appearance
## comes from ShopCatalog so the world pickup, held item, inventory portrait,
## and shop listing always describe the same object.

var item_name: String = "Lake Shell"
var item_color: Color = Color.WHITE
var visual_scale: float = 1.0
var _collected := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var entry := ShopCatalog.find(item_name)
	if not entry.is_empty():
		var visual: Node3D = (entry["build_visual"] as Callable).call(visual_scale)
		add_child(visual)
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.48
	collision.shape = sphere
	collision.position.y = 0.16
	add_child(collision)
	set_meta("prompt", "Pick up %s" % item_name.to_lower())
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
	Inventory.add(item_name, item_color)
	UISounds.play_foley(&"pickup", 0.44, get_instance_id())
	Hud.show_message("Picked up the %s." % item_name)
	queue_free()
