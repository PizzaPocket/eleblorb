class_name SuitRoster
extends Node

## Owns several suit sets (see SuitLoadout) and swaps between them on the
## hero. A set not yet reached waits, parked (Blorb.wait_here()) beside its
## checkpoint portal. A swap is physical: the worn blorbs hop off, then the new
## set joins the party and hops on. The party only ever grows: blorbs that
## hop off stay in it and keep following, so passing back through an earlier
## portal reassigns the suit to blorbs already travelling with the hero.

## Farther than this from the hero, a joining blorb is brought alongside him
## before hopping on, rather than flying the whole distance. Only happens if
## portals were skipped (flown over) and a set was left at another border.
const MAX_HOP_DISTANCE := 15.0

var _player: Player
## element -> {"blorbs": Array[Blorb], "slots": Array[String]}
var _sets: Dictionary = {}
var _current := ""
var _switching := false
var _pending := ""


func setup(player: Player) -> void:
	_player = player


## Registers a set under `key` (an element, or any label such as "normal").
func add_set(key: String, blorbs: Array[Blorb], slots: Array[String]) -> void:
	_sets[key] = {"blorbs": blorbs, "slots": slots}
	for blorb in blorbs:
		blorb.wait_here()


## Makes `key` the current set immediately: in the party and assigned, suit
## off. For the opening, before anything has been worn.
func start_with(key: String) -> void:
	_current = key
	var suit := _player.get_own_blorb_suit()
	var entry: Dictionary = _sets[key]
	var slots: Array[String] = entry["slots"]
	var blorbs: Array[Blorb] = entry["blorbs"]
	for index in blorbs.size():
		blorbs[index].rejoin_party()
		suit.equip_to_slot(blorbs[index], slots[index])


func current() -> String:
	return _current


## Swaps to set `key`. Crossing the portal of the set already worn does
## nothing; a request arriving mid-swap is applied once the swap finishes.
func switch_to(key: String) -> void:
	if not _sets.has(key):
		return
	if _switching:
		_pending = key
		return
	if key == _current:
		return
	_switching = true
	var suit := _player.get_own_blorb_suit()
	UISounds.play_foley(&"transform_reveal", 0.7, _player.get_instance_id())
	# The worn set hops off first; the suit controller allows one direction of
	# transition at a time.
	if suit.is_suit_on():
		suit.toggle()
	while suit.is_transitioning():
		await get_tree().process_frame
	if _sets.has(_current):
		for blorb in (_sets[_current]["blorbs"] as Array[Blorb]):
			if is_instance_valid(blorb):
				suit.remove_assignment_for_blorb(blorb)
	var entry: Dictionary = _sets[key]
	var slots: Array[String] = entry["slots"]
	var blorbs: Array[Blorb] = entry["blorbs"]
	for index in blorbs.size():
		var blorb := blorbs[index]
		if not is_instance_valid(blorb):
			continue
		if blorb.global_position.distance_to(_player.global_position) > MAX_HOP_DISTANCE:
			var angle := TAU * float(index) / float(blorbs.size())
			blorb.global_position = _player.global_position + Vector3(cos(angle), 0.0, sin(angle)) * 2.5
		blorb.rejoin_party()
		suit.equip_to_slot(blorb, slots[index])
	_current = key
	suit.toggle()
	while suit.is_transitioning():
		await get_tree().process_frame
	_switching = false
	if _pending != "":
		var next := _pending
		_pending = ""
		switch_to(next)
