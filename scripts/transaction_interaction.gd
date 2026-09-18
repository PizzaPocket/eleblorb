class_name TransactionInteraction
extends RefCounted

## Builds a dialogue action representing a paid service. The returned action
## uses DialogUI's ordinary focus/navigation contract while adding shared
## transaction metadata, price presentation, affordability checking, and
## payment. Inns are only the first consumer.
static func paid_action(
	label: String,
	price: int,
	on_paid: Callable,
	unavailable_message: String = "Your purse feels too light.",
	can_transact: Callable = Callable()
) -> Dictionary:
	var safe_price: int = maxi(price,0)
	return {
		"label": "%s (%d Tokoins)" % [label,safe_price],
		"transaction": true,
		"price": safe_price,
		"callback": func() -> void:
			if can_transact.is_valid() and not bool(can_transact.call()):
				return
			if not TokoinWallet.spend(safe_price):
				Hud.show_message(unavailable_message)
				return
			if on_paid.is_valid():
				on_paid.call()
	}
