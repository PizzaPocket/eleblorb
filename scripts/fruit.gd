class_name Fruit
extends Area3D

## A piece of fruit lying on the ground beneath a fruit tree (see
## nature_props.gd's build_fruit_tree()) -- a proximity-action pickup (see
## InteractionManager), same collectible pattern as gem.gd/tokoin.gd, just a
## simple sphere-plus-stem instead of a cut-crystal facet mesh, since fruit
## isn't gem-cut. class_name + direct .new() instantiation (no dedicated
## .tscn), matching thrown_item.gd's own precedent for a scripted-only
## Area3D pickup. This node IS the pickup Area3D itself (like tokoin.gd,
## unlike gem.gd) -- registers directly with InteractionManager on
## body_entered/body_exited rather than going through Interactable.attach().

@export var fruit_color: Color = Color(0.78, 0.14, 0.14)
@export var fruit_name: String = "Apple"
@export var radius: float = 0.09

## Optional override for species whose fruit isn't a plain sphere-plus-stem
## (Banana's curved-segment shape, Durian's spiked husk -- see
## nature_props.gd's build_banana_fruit()/build_durian_fruit()). Set by the
## caller (see wilderness_scatter.gd's species dicts) before this node enters
## the tree; left as an invalid Callable() for every ordinary species, which
## falls back to the plain build_fruit_visual() below.
var visual_builder: Callable = Callable()

const PICKUP_RADIUS := 0.4

var _collected: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player only (see player.tscn)
	var visual: Node3D = visual_builder.call() if visual_builder.is_valid() else NatureProps.build_fruit_visual(fruit_color, radius)
	add_child(visual)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PICKUP_RADIUS
	shape.shape = sphere
	add_child(shape)

	set_meta("prompt", "Pick up %s" % fruit_name.to_lower())
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
	Inventory.add(fruit_name, fruit_color)
	UISounds.play_foley(&"pickup", 0.46, get_instance_id())
	Hud.show_message("Picked up the %s." % fruit_name)
	queue_free()
