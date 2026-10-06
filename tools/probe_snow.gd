extends Node

## Lists purchasable stock per shop category.
##   Godot --headless --path . tools/probe_snow.tscn
func _ready() -> void:
	for category in ["antique", "red", "green", "snow", "ocean", "chinese"]:
		var names: Array[String] = []
		for item in ShopCatalog.get_items_for_shop(category):
			if item.get("purchasable", false):
				names.append(str(item["name"]))
		print(category, ": ", names)
	get_tree().quit()
