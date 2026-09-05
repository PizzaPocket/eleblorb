extends Node

## What the player currently has in hand -- separate from Inventory itself
## since selecting an item to hold shouldn't remove it from the inventory;
## only actually throwing it does that (see player.gd's throw handling and
## thrown_item.gd).

signal changed

var current: Dictionary = {}  # {} means empty-handed


func equip(item: Dictionary) -> void:
	current = item
	changed.emit()


func clear() -> void:
	if current.is_empty():
		return
	current = {}
	changed.emit()
