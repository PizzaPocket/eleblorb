extends Node

## Shared modal guard so gameplay systems don't need a direct reference to
## every UI autoload to know whether one currently has focus. A counter,
## not a bool -- DialogUI (with actions) can open ShopUI on top of it, so
## popping one modal shouldn't resume gameplay input while another is
## still open underneath.

var _modal_count: int = 0

var modal_open: bool:
	get: return _modal_count > 0


func push_modal() -> void:
	_modal_count += 1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func pop_modal() -> void:
	_modal_count = maxi(_modal_count - 1, 0)
	if _modal_count == 0:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
