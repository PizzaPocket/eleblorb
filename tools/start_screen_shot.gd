extends Node

## Saves the title screen to wip/village_audit/start_screen.png.
func _ready() -> void:
	var screen := (load("res://scenes/start_screen.tscn") as PackedScene).instantiate()
	add_child(screen)
	for _i in 12:
		await get_tree().process_frame
	for _i in 6:
		await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://wip/village_audit/start_screen.png")
	print("Saved start screen")
	get_tree().quit()
