extends Node

## Tracks every Interactable-built Area3D (see interactable.gd) the player is
## currently standing inside -- there can be more than one at once, a
## village dense with talkable NPCs, say -- and picks the best one to fire
## on the "interact" action's "just pressed" edge (F on keyboard, X/Square on
## gamepad -- see input_map.gd).
##
## CORRECTED per direct instruction ("in kueh machine, we had the character
## have a preference for who they're going to talk to based on the direction
## which the body is aiming, can we bring in that bias") -- this used to
## track a single `current` area, just whichever one's body_entered/exited
## fired most recently. Besides having no facing preference at all, that had
## a real correctness bug of its own: with two overlapping areas, entering A
## then B set current to B; exiting B alone (even while still standing
## inside A) cleared current to null outright, since exit() only ever
## checked "does the exiting area match current" -- the player would lose
## the prompt entirely while still standing in A's own radius. Tracking the
## full overlapping set and re-picking the best one on every change (and
## every frame, so turning in place among several candidates re-prioritizes
## live, not just on enter/exit) fixes both at once.
##
## Scoring is the same idea (and the same formula) as kueh-machine's own
## hub_main.gd _update_nearby(): distance alone would let a crowd of nearby
## NPCs force picking whichever is a few centimeters closer regardless of
## where the player is actually looking, so alignment with the player's own
## BODY facing (player.visuals' own rotation, not the camera) discounts the
## effective distance of whatever's in front and inflates whatever's behind.
## Unlike that reference implementation, there's no line-of-sight raycast
## here -- eleblorb's own interact radii are small enough (see each
## Interactable.attach() call's own INTERACT_RADIUS) that a candidate being
## on the other side of a wall within that short a range hasn't come up as a
## problem; add one here the same way if it ever does.

## 0.0 = pure nearest-distance picking, 1.0 = strongly favors whatever the
## player's body is currently facing over something merely closer. Alignment
## itself runs -1 (directly behind) to 1 (directly ahead), so this is a
## first-draft magnitude, not derived from anything -- adjustable on report
## the same way kueh-machine's own identically-named constant was tuned by
## feel there.
const FACING_BIAS_STRENGTH := 0.6

var current: Area3D = null
var _candidates: Array[Area3D] = []


func enter(area: Area3D) -> void:
	if not _candidates.has(area):
		_candidates.append(area)
	_reselect()


func exit(area: Area3D) -> void:
	_candidates.erase(area)
	_reselect()


## Re-picks `current` from whatever's still in _candidates -- called
## whenever that set changes (enter/exit above) AND every frame from
## _process() below, so simply turning in place while standing still among
## several overlapping candidates re-prioritizes live, the same as
## kueh-machine's own per-frame _update_nearby() does, rather than only
## reacting to a NEW area being entered or left.
func _reselect() -> void:
	current = null
	if _candidates.is_empty():
		return
	# Prune anything freed without a matching body_exited (an interactable
	# whose own owner was queue_free()'d while the player stood inside its
	# radius) rather than letting a stale reference win by default. Array.
	# filter() returns a plain untyped Array, not another Array[Area3D], so
	# this goes through .assign() rather than a bare `=` -- same reasoning
	# every other Dictionary/Array-derived typed-array assignment in this
	# project already follows (see e.g. jungle_kingdom_village.gd's own
	# `lines.assign(identity["lines"])`).
	var valid_candidates: Array[Area3D] = []
	valid_candidates.assign(_candidates.filter(func(area: Area3D) -> bool: return is_instance_valid(area)))
	_candidates = valid_candidates
	if _candidates.is_empty():
		return
	if _candidates.size() == 1:
		current = _candidates[0]
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		current = _candidates[0]
		return
	# player.visuals (not the CharacterBody3D root, which never itself
	# rotates -- see player.gd's own _process_walk()/movement code, which
	# sets visuals.rotation.y directly) is where this project's own body-
	# facing convention actually lives, the same "atan2(x, z)" forward every
	# other creature/NPC rig in this project already uses for its own
	# rotation.y target.
	var body_forward := player.visuals.global_transform.basis.z
	var best: Area3D = null
	var best_score := INF
	for area in _candidates:
		var offset := area.global_position - player.global_position
		var distance := offset.length()
		var alignment := 0.0
		var horizontal := Vector2(offset.x, offset.z)
		if horizontal.length() > 0.01:
			alignment = body_forward.dot(Vector3(horizontal.x, 0.0, horizontal.y).normalized())
		var score := distance * (1.0 - FACING_BIAS_STRENGTH * alignment)
		if score < best_score:
			best_score = score
			best = area
	current = best


func _process(_delta: float) -> void:
	if not _candidates.is_empty():
		_reselect()
	if Input.is_action_just_pressed("interact") and current != null and not UIState.modal_open:
		var activate: Callable = current.get_meta("activate")
		activate.call()
