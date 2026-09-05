extends Node

## Tracks whichever Interactable-built Area3D (see interactable.gd) the
## player is currently standing inside, and fires it on the "interact"
## action's "just pressed" edge (F on keyboard, X/Square on gamepad -- see
## input_map.gd), matching the common convention of a dedicated button for
## a context "use/interact" prompt.

var current: Area3D = null


func enter(area: Area3D) -> void:
	current = area


func exit(area: Area3D) -> void:
	if current == area:
		current = null


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interact") and current != null and not UIState.modal_open:
		var activate: Callable = current.get_meta("activate")
		activate.call()
