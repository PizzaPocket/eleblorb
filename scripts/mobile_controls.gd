extends CanvasLayer

## Installs the actual in-game touch surface. The web loader's mobile hints
## are only instructional; this layer supplies movement, camera and actions.


func _ready() -> void:
	if not _touch_capable():
		return
	layer = 80
	var surface := MobileControlsSurface.new()
	add_child(surface)


func _touch_capable() -> bool:
	if DisplayServer.is_touchscreen_available():
		return true
	if OS.has_feature("web"):
		return bool(JavaScriptBridge.eval(
			"Boolean(navigator.maxTouchPoints || matchMedia('(pointer: coarse)').matches)", true
		))
	return false
