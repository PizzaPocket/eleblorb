extends Node

## Keeps the UI the same proportion of the window on every desktop display.
##
## The UI tokens (ui_theme.gd: 66 px buttons, 24-48 px spacing) were tuned on a
## Retina Mac, where Godot hands the game a ~3420x1902 pixel viewport. A
## 1080p Windows monitor has a 1920 px-wide viewport, so the same pixel sizes
## filled ~1.8x more of the window and the UI looked scaled up. Treating that
## Mac viewport as the design size makes every window scale to the same look.
##
## Only Windows and Linux opt in: macOS already gives the tuned viewport, and
## web has its own devicePixelRatio-based density scaling (UIKit.
## ui_density_scale()) that this would otherwise double up with.

const DESIGN_SIZE := Vector2i(3420, 1902)


func _ready() -> void:
	if OS.has_feature("windows") or OS.has_feature("linuxbsd"):
		apply_desktop_scaling(get_window())


static func apply_desktop_scaling(window: Window) -> void:
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	window.content_scale_size = DESIGN_SIZE
