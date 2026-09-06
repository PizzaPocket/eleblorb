extends CanvasLayer

## Installs the actual in-game touch surface. The web loader's mobile hints
## are only instructional; this layer supplies movement, camera and actions.


var _density_root: Control
var _surface: MobileControlsSurface


func _ready() -> void:
	if not _touch_capable():
		return
	layer = 80
	# Autoload children cannot safely be added while the root is still
	# assembling its own child list.
	_install_surface.call_deferred()


func _install_surface() -> void:
	if is_instance_valid(_surface):
		return
	_density_root = UIKit.density_root(self)
	_surface = MobileControlsSurface.new()
	_density_root.add_child(_surface)


func _touch_capable() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval(
			"Boolean(navigator.maxTouchPoints || matchMedia('(pointer: coarse)').matches)", true
		))
	return false
