extends Node

## Tracks the player's tokoin currency (spent later on elemental gems).
## Autoloaded so any pickup or shop can reach it as TokoinWallet.add()/
## TokoinWallet.value without needing a node reference.

signal changed(new_value: int)

var value: int = 0


func add(amount: int) -> void:
	value += amount
	changed.emit(value)
	print("Tokoin: ", value)


func spend(amount: int) -> bool:
	if value < amount:
		return false
	value -= amount
	changed.emit(value)
	return true
