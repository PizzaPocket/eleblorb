class_name Interactable
extends RefCounted

## Static helper that gives any Node3D a proximity action prompt
## zone without each caller reimplementing proximity detection -- used by
## NPCs (talk) and shop items (buy). All the actual behavior lives in the
## on_activate callable the caller supplies; visible prompt copy names the
## action only ("Talk", "Pick up orange"), never the input gesture. This
## just wires up the Area3D
## and registers/unregisters it with InteractionManager while the player is
## inside its radius.


## on_enter/on_exit are optional and receive the player body -- used by
## npc.gd to track who to turn its head toward while the player's in range,
## independent of whether they've actually pressed E yet.
static func attach(
	parent: Node3D,
	prompt: String,
	radius: float,
	on_activate: Callable,
	on_enter: Callable = Callable(),
	on_exit: Callable = Callable(),
	allow_active_control_body: bool = false,
	max_vertical_distance: float = 1.5
) -> Area3D:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = (
		2 | 1 | Blorb.GIANT_THROWABLE_LAYER
		if allow_active_control_body
		else 2
	) # ordinary player, or the currently piloted physical body when opted in
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	shape.shape = sphere
	area.add_child(shape)
	area.set_meta("prompt", prompt)
	area.set_meta("activate", on_activate)
	area.set_meta("interaction_radius", radius)
	area.set_meta("max_vertical_distance", max_vertical_distance)
	area.body_entered.connect(
		func(body: Node3D) -> void:
			if body is CharacterBody3D or (
				allow_active_control_body and body == PartyControl.active_control_body()
			):
				InteractionManager.enter(area)
				if on_enter.is_valid():
					on_enter.call(body)
	)
	area.body_exited.connect(
		func(body: Node3D) -> void:
			if body is CharacterBody3D or (
				allow_active_control_body and body == PartyControl.active_control_body()
			):
				InteractionManager.exit(area)
				if on_exit.is_valid():
					on_exit.call(body)
	)
	parent.add_child(area)
	return area
