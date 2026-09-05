extends Node

## Tracks non-currency collectibles (found/bought gems, shop curios).
## Autoloaded so pickups and purchases can reach it without a node
## reference, same pattern as TokoinWallet.

signal changed

## One entry per item name. `quantity` is the number owned, so repeated
## pickups/purchases grow a stack instead of consuming another UI slot.
var items: Array[Dictionary] = []


func add(item_name: String, color: Color) -> void:
	for item in items:
		if item["name"] == item_name:
			var quantity: int = int(item.get("quantity", 1))
			item["quantity"] = quantity + 1
			changed.emit()
			return
	items.append({"name": item_name, "color": color, "quantity": 1})
	changed.emit()


func has(item_name: String) -> bool:
	for item in items:
		if item["name"] == item_name:
			return true
	return false


func remove(item_name: String) -> bool:
	for i in items.size():
		if items[i]["name"] == item_name:
			var quantity: int = int(items[i].get("quantity", 1))
			if quantity > 1:
				items[i]["quantity"] = quantity - 1
			else:
				items.remove_at(i)
			changed.emit()
			return true
	return false


## Removes up to `count` units in one shot (one `changed` emission, not one
## per unit -- ShopUI's sell-quantity confirm uses this instead of calling
## remove() in a loop, which would re-trigger a full list rebuild per unit
## while the shop is open). Returns how many were actually removed, capped
## by how many are owned.
func remove_quantity(item_name: String, count: int) -> int:
	if count <= 0:
		return 0
	for i in items.size():
		if items[i]["name"] == item_name:
			var quantity: int = int(items[i].get("quantity", 1))
			var removed := mini(count, quantity)
			if removed >= quantity:
				items.remove_at(i)
			else:
				items[i]["quantity"] = quantity - removed
			changed.emit()
			return removed
	return 0


func quantity_of(item_name: String) -> int:
	for item in items:
		if item["name"] == item_name:
			return int(item.get("quantity", 1))
	return 0
