class_name BlorbSuitController
extends RefCounted

## Drives the blorb suit's equip/unequip ANIMATION and, once worn, the
## live per-frame limb-tube rebuild (see blorb_suit.gd's own BlorbSuit for
## the stateless geometry toolkit this calls into -- that file is the
## "what it looks like," this one is the "what's happening right now").
## Owned and driven entirely by player.gd: construct once via setup(),
## call toggle() on the "transform" action press and update(delta) every
## _process frame.
##
## Per direct instruction, suiting up/down is no longer instantaneous --
## each involved blorb keeps its own ordinary round body/eyes/hop
## animation right up until it actually reaches its target, at which point
## (same frame) it's swapped for the flat suit-piece geometry; unequipping
## reverses that swap at the START of the blorb's own hop off instead. A
## small per-blorb stagger (JUMP_STAGGER) means the whole party doesn't
## leap in one indistinguishable instant, and unequipped blorbs scatter to
## land at different points around the player rather than piling on one
## spot.

## TRANSITIONING replaces the old separate EQUIPPING/UNEQUIPPING (see
## update()'s own comment) -- both used to gate on one shared phase that
## only advanced once EVERY entry _start_equip()/_start_unequip() created
## together had landed, which is fine for toggle()'s own all-or-nothing
## whole-party swap but can't represent "some slots worn, one slot
## individually equipping, the rest untouched" -- exactly what
## equip_to_slot()/unequip_slot() (InventoryUI's Blorbs-tab paper-doll)
## need. _transitions entries now resolve independently as each one lands,
## regardless of how many others are still in flight.
enum Phase { IDLE, TRANSITIONING, WORN }

const JUMP_DURATION := 0.45
const JUMP_STAGGER := 0.08
const HOP_ARC_HEIGHT := 1.3
const LAND_SCATTER_RADIUS_MIN := 1.4
const LAND_SCATTER_RADIUS_MAX := 2.4
const FLIGHT_REFERENCE_SPEED := 6.0

var _phase: int = Phase.IDLE
var _player: Node3D
var _root: Node3D
var _pivots: Dictionary
## Multiplies every ProceduralFigure-derived radius/offset in blorb_suit.gd's
## own geometry builders (see BlorbSuit.rebuild_arm()'s doc comment) so the
## suit fits whichever rig `root`'s pivots actually belong to -- 1.0 for the
## human rig those formulas are natively written in terms of, MonkeyFigure.
## BLORB_SUIT_RIG_SCALE for Xiao Hou Zi's much smaller frame (or 1.0 again
## while player.gd's oversized-suit cheat code is active). Set once by
## setup() and re-applied by re-calling setup() whenever the cheat toggles or
## the piloted body changes.
var _rig_scale: float = 1.0
## Active hop entries, "on" or "off" mode -- see _start_equip_all()/
## _start_unequip_all()/equip_to_slot()/_begin_unequip_slot() for the exact
## keys each mode fills in.
var _transitions: Array[Dictionary] = []
## {slot, blorb, pieces, eye_blink} once a blorb has actually landed and
## become part of the suit -- see _update_worn_limbs() for how the dynamic
## (limb) entries here get rebuilt every WORN frame. eye_blink is each
## entry's own independent EyeBlink clock (see _apply_eye_blink()), keyed
## per-entry rather than shared across the whole controller so different
## blorbs worn in different slots blink on their own separate schedules
## instead of in unison.
var _worn: Array[Dictionary] = []
## Explicit "was the suit's own bulk on/off toggle (T) last used to turn it
## on" flag -- purely toggle()'s own bookkeeping for which bulk action
## (_start_equip_all()/_start_unequip_all()) to run next, decoupled from
## _worn.is_empty(). That inference used to be good enough, but equip_to_
## slot()/unequip_slot() (the paper-doll's own per-slot clicks) now always
## take live effect immediately regardless of this flag (see those methods'
## own comments) -- so _worn can be legitimately non-empty (a few pieces
## individually assigned by hand) while the player has never actually
## pressed T at all, and _worn.is_empty() would no longer reliably answer
## "was the suit toggled on."
var _suit_on: bool = false
## {slot: Blorb} -- which blorb is ASSIGNED to each slot, kept for two
## things: auto_assign_new_members() seeds a default here before the
## player has touched anything, and _start_equip_all() (toggle()'s bulk
## on-action) reads it to know what to reproduce after a bulk unequip.
## Updated by equip_to_slot()/unequip_slot() without changing the live suit.
## Unlike _worn, this is never cleared by
## _start_unequip_all() (toggling the suit off doesn't forget what was
## assigned, it just stops rendering it live) -- and unlike _worn, it's
## always updated synchronously the moment equip_to_slot()/unequip_slot()
## is called. The two are still worth keeping distinct: this is what "Assigned:
## <slot>" reads in InventoryUI's blorb rows, and what survives a bulk
## unequip, neither of which _worn alone could answer on its own).
## assigned_blorb_in_slot()/slot_for_assigned_blorb() below are its read
## API. player_portrait.gd no longer reads either of these -- it renders a
## live camera pointed at the real player instead of a reconstructed copy,
## so it just shows whatever's actually worn, directly.
var _assignments: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _air_wing_flap_phase := 0.0
var _assignment_reconcile_requested := false
## Cached command state lets an already-worn torso and limbs immediately
## change between ordinary fit and sealed fit when the Lava Helm arrives or
## leaves. Torso geometry is otherwise static after equip, so merely changing
## the limb rebuild path would leave it enlarged until the next full suit cycle.
var _lava_helm_command_was_active := false


func _init() -> void:
	_rng.randomize()


## `root` is player.gd's own Visuals node -- a stable reference frame (only
## ever yawed to face travel direction, never itself bent by a joint) that
## limb tubes are built in the local space of (see blorb_suit.gd's own
## rebuild_arm/rebuild_leg). `pivots` is the same shoulder/elbow/hip/knee/
## ankle/spine/head (+hand_left/hand_right) dictionary player.gd already
## assembles for BlorbSuit. `rig_scale` is forwarded verbatim to every
## BlorbSuit call this controller makes (see _rig_scale's own doc comment) --
## player.gd is expected to re-call setup() with an updated value any time
## the piloted body or the oversized-suit cheat toggle changes, so a
## currently-worn suit picks up the new proportions on its very next rebuild
## rather than waiting for a fresh equip.
func setup(player: Node3D, root: Node3D, pivots: Dictionary, rig_scale: float = 1.0) -> void:
	_player = player
	_root = root
	_pivots = pivots
	_rig_scale = rig_scale


func toggle() -> void:
	if not _transitions.is_empty():
		return
	_suit_on = not _suit_on
	if _suit_on:
		_start_equip_all()
	else:
		_start_unequip_all()


## Paper-doll assignment is data-only. The isolated menu preview renders
## these mappings as a fully worn suit, while the real player remains exactly
## as they were when the paused menu opened. The next world-space suit toggle
## consumes the updated mapping.
func equip_to_slot(blorb: Blorb, slot: String) -> void:
	if blorb == null or not blorb.in_party or blorb.is_melted or not (slot in BlorbSuit.SLOT_ORDER):
		return
	for existing_slot in _assignments.keys():
		if _assignments[existing_slot] == blorb:
			_assignments.erase(existing_slot)
	_assignments[slot] = blorb


## Removes only the persistent assignment; it never changes the live suit.
func unequip_slot(slot: String) -> void:
	_assignments.erase(slot)


## The blorb currently ASSIGNED to `slot` (see _assignments' own comment
## above) -- the paper-doll UI and player_portrait.gd's own render both
## read this, so they reflect the player's intent instantly and regardless
## of whether the suit is actually toggled on live right now.
func assigned_blorb_in_slot(slot: String) -> Blorb:
	return _assignments.get(slot) as Blorb


## Which slot `blorb` is currently ASSIGNED to, or "" if none.
func slot_for_assigned_blorb(blorb: Blorb) -> String:
	for slot in _assignments:
		if _assignments[slot] == blorb:
			return slot
	return ""


func assignment_snapshot() -> Dictionary:
	return _assignments.duplicate()


func worn_blorbs() -> Array[Blorb]:
	var result: Array[Blorb] = []
	for entry in _worn:
		var blorb := entry.get("blorb") as Blorb
		if is_instance_valid(blorb):
			result.append(blorb)
	return result


## Story sequences may temporarily remove the party's blorbs from play.
## Tear down live suit geometry immediately while preserving assignments,
## so rescuing them restores the player's chosen layout on the next equip.
func suspend_for_story() -> void:
	for entry in _worn:
		var pieces := entry.get("pieces") as Array
		for piece in pieces:
			if is_instance_valid(piece):
				BlorbSuit.release_piece(piece as Node3D)
		var blorb := entry.get("blorb") as Blorb
		if is_instance_valid(blorb):
			blorb.is_worn = false
	for transition in _transitions:
		var transition_blorb := transition.get("blorb") as Blorb
		if is_instance_valid(transition_blorb):
			transition_blorb.is_worn = false
	_worn.clear()
	_transitions.clear()
	_suit_on = false


func worn_blorb_for_slot(slot: String) -> Blorb:
	for entry in _worn:
		if String(entry.get("slot", "")) == slot:
			return entry.get("blorb") as Blorb
	return null


## Rebinds a portal-carried slot map to the newly instantiated Blorb nodes in
## the destination world. Party owns serialization; this controller validates
## and consumes the live references.
func restore_assignments(assignments: Dictionary) -> void:
	_assignments.clear()
	for slot in assignments:
		var blorb := assignments[slot] as Blorb
		if slot in BlorbSuit.SLOT_ORDER and is_instance_valid(blorb) and blorb.in_party:
			_assignments[slot] = blorb


## Applies paper-doll edits to an already-worn suit without disturbing any
## blorb whose live slot still matches its assignment. Inventory calls this
## as it closes; if an older hop is still resolving, update() safely defers
## the reconciliation until that transition finishes.
func apply_assignment_changes() -> void:
	if not _suit_on:
		return
	_assignment_reconcile_requested = true
	if _transitions.is_empty():
		_reconcile_worn_assignments()


## True only once two blorbs have actually landed as the left and right leg
## coverings. Assigning them in the paper doll or having either one mid-hop
## is intentionally not enough: the traversal boost belongs to the visible,
## fully equipped pair of blorb skates.
func has_blorb_skates() -> bool:
	var has_left := false
	var has_right := false
	for entry in _worn:
		var slot: String = entry["slot"] as String
		match slot:
			"leg_left":
				has_left = true
			"leg_right":
				has_right = true
	return has_left and has_right


## Lava traversal requires a complete, visibly landed fire pair. Assignment
## alone is not protection, and losing either leg removes it immediately.
func has_lava_safe_legs() -> bool:
	return has_worn_element("leg_left", "fire") and has_worn_element("leg_right", "fire")


func has_full_lava_suit() -> bool:
	if not has_worn_element("arm_left", "fire") or not has_worn_element("arm_right", "fire"):
		return false
	if not has_worn_element("leg_left", "fire") or not has_worn_element("leg_right", "fire"):
		return false
	if not has_worn_element("torso", "fire"):
		return false
	var head := worn_blorb_in_slot("head")
	return is_instance_valid(head) and head.element_state == "fire" and head.has_core_item("Lava Helm")


func has_head_lava_helm() -> bool:
	var head := worn_blorb_in_slot("head")
	return is_instance_valid(head) and head.has_core_item("Lava Helm")


func has_rock_walking_legs() -> bool:
	return has_worn_element("leg_left", "rock") and has_worn_element("leg_right", "rock")


## A complete pair of visibly worn Air feet provides passive hover. Unlike
## Water/Fire leg powers, this does not consume either leg's active control;
## those buttons are deliberately inert for Air feet for now.
func has_air_hover_legs() -> bool:
	return has_worn_element("leg_left", "air") and has_worn_element("leg_right", "air")


## A head blorb is a real, landed suit piece, not merely an assignment in
## the paper doll. Player uses this to gate underwater movement, so a blorb
## still hopping into place cannot grant the diving ability early.
func has_head_blorb() -> bool:
	for entry in _worn:
		var slot := entry["slot"] as String
		if slot == "head":
			return true
	return false


func has_head_diving_helmet() -> bool:
	for entry in _worn:
		var slot := entry["slot"] as String
		var blorb := entry["blorb"] as Blorb
		if slot == "head" and is_instance_valid(blorb) and blorb.has_core_item("Diving Helmet"):
			return true
	return false


## Flight is granted only by a fully landed air blorb covering the chest.
## Other air slots still visibly grow their own wings, but are cosmetic in
## this first flight prototype.
func has_chest_air_blorb() -> bool:
	for entry in _worn:
		var slot := entry["slot"] as String
		var blorb := entry["blorb"] as Blorb
		if slot == "torso" and is_instance_valid(blorb) and blorb.element_state == "air":
			return true
	return false


## Element abilities are granted only by a visibly landed piece, never by a
## merely assigned blorb that is still following the party.
func has_worn_element(slot: String, element: String) -> bool:
	for entry in _worn:
		var worn_slot := entry["slot"] as String
		var blorb := entry["blorb"] as Blorb
		if worn_slot == slot and is_instance_valid(blorb) and blorb.element_state == element:
			return true
	return false


func worn_blorb_in_slot(slot: String) -> Blorb:
	for entry in _worn:
		if (entry["slot"] as String) == slot:
			var blorb := entry["blorb"] as Blorb
			return blorb if is_instance_valid(blorb) else null
	return null


## Switches a worn head blorb between its ordinary hat and the inflated
## diving helmet. This is intentionally driven by Player's real buoyancy
## state, not merely by wearing the blorb, so the helmet never persists on
## dry ground or while standing at a shoreline.
func set_head_blorb_submerged(submerged: bool) -> void:
	for entry in _worn:
		var slot := entry["slot"] as String
		if slot != "head":
			continue
		var blorb := entry["blorb"] as Blorb
		# Ordinary head blorbs only have the hat form. Never hide it simply
		# because the wearer entered water/goo: the sealed form exists, and
		# may replace the hat, only for a blorb that absorbed Diving Helmet.
		var use_diving_form := submerged and is_instance_valid(blorb) and blorb.has_core_item("Diving Helmet")
		for piece in (entry["pieces"] as Array):
			if not is_instance_valid(piece):
				continue
			var form := piece as Node3D
			if form.name == "HeadBlorbHat":
				form.visible = not use_diving_form
			elif form.name == "HeadBlorbHelmet":
				form.visible = use_diving_form


## Seeds a default assignment for any in-party blorb that doesn't have one
## yet, filling only EMPTY slots (an existing assignment is never touched
## or reshuffled) -- per direct instruction, a blorb should already be
## assigned to a body part from the moment it's in the party, not just once
## the player has opened the paper-doll UI at least once. Called once at
## game start (see player.gd's _ready(), covering the starter trio) and
## again every time a wild blorb actually joins the party (see blorb.gd's
## own in_party = true transition), so a growing party keeps filling in
## open slots as it grows rather than only ever seeding once.
func auto_assign_new_members() -> void:
	var already_assigned := {}
	for slot in _assignments:
		var b: Blorb = _assignments[slot]
		if b != null:
			already_assigned[b] = true

	var unassigned: Array[Blorb] = []
	for b in _player.get_tree().get_nodes_in_group("blorbs"):
		if b.in_party and not b.is_melted and not already_assigned.has(b):
			unassigned.append(b as Blorb)
	if unassigned.is_empty():
		return

	var index := 0
	for slot in BlorbSuit.SLOT_ORDER:
		if index >= unassigned.size():
			return
		if _assignments.get(slot) != null:
			continue
		_assignments[slot] = unassigned[index]
		index += 1


func update(delta: float) -> void:
	# Both run every frame regardless of the other -- a slot can be
	# individually transitioning (equip_to_slot()/unequip_slot()) at the
	# same time others sit steady in _worn, so neither is gated behind a
	# single shared phase the way the old EQUIPPING/UNEQUIPPING split was.
	if not _transitions.is_empty():
		_update_transitions(delta)
	if _assignment_reconcile_requested and _transitions.is_empty():
		_reconcile_worn_assignments()
	var lava_helm_command := _lava_helm_command_active()
	if lava_helm_command != _lava_helm_command_was_active:
		_rebuild_worn_fire_pieces(lava_helm_command)
		_lava_helm_command_was_active = lava_helm_command
	if not _worn.is_empty():
		_update_worn_limbs(lava_helm_command)
		# The Lava Helm sizes only its own shell. Keep the covered head, hair,
		# and ears at their authored rig scale throughout wear and removal.
		for entry in _worn:
			if (entry["slot"] as String) != "head":
				continue
			for piece in (entry["pieces"] as Array):
				if is_instance_valid(piece):
					BlorbSuit.preserve_covered_head_scale(piece as Node3D)
		# After _update_worn_limbs(): the dynamic (limb) pieces just rebuilt
		# their eyes fresh this frame (_update_face() always resets scale.y
		# to 1.0 on every call -- see its own comment on why .scale must be
		# reapplied after .basis every time), so blink has to override that
		# AFTER the rebuild, not before, or it'd get silently clobbered.
		_apply_eye_blink(delta)
		_update_worn_air_wings(delta)
	_phase = Phase.WORN if not _worn.is_empty() else (Phase.TRANSITIONING if not _transitions.is_empty() else Phase.IDLE)


func _lava_helm_command_active() -> bool:
	# The helm is the command key, but the sealed configuration only exists
	# while a complete five-piece Fire suit is physically worn. Because this is
	# recomputed every frame from _worn, losing any piece immediately returns
	# the survivors to normal and restoring it reforms the suit automatically.
	return has_full_lava_suit()


## Replaces only Fire torso/limb geometry. The Lava Helm itself has its own
## authored shape and does not change, while non-Fire suit pieces should never
## respond to the command. Releasing and recreating in the same frame makes
## removal visibly and physically immediate.
func _rebuild_worn_fire_pieces(lava_helm_command: bool) -> void:
	for entry in _worn:
		var slot := entry["slot"] as String
		var blorb := entry["blorb"] as Blorb
		if slot == "head" or not is_instance_valid(blorb) or blorb.element_state != "fire":
			continue
		for piece in (entry["pieces"] as Array):
			if is_instance_valid(piece):
				BlorbSuit.release_piece(piece as Node3D)
		var pieces := BlorbSuit.equip_slot(slot, _pivots, _root, blorb, _rig_scale, lava_helm_command)
		for piece in pieces:
			if piece is VisualInstance3D:
				PlayerPortrait.tag_for_portrait(piece as VisualInstance3D)
		entry["pieces"] = pieces


func _reconcile_worn_assignments() -> void:
	_assignment_reconcile_requested = false
	var already_worn: Dictionary = {}
	var retained: Array[Dictionary] = []
	var changed_index := 0

	for entry in _worn:
		var old_slot := entry["slot"] as String
		var blorb := entry["blorb"] as Blorb
		if not is_instance_valid(blorb):
			continue
		already_worn[blorb] = true
		var new_slot := slot_for_assigned_blorb(blorb)
		if new_slot == old_slot:
			retained.append(entry)
			continue
		var transition := {
			"mode": "move" if new_slot != "" else "off",
			"slot": new_slot if new_slot != "" else old_slot,
			"from_slot": old_slot,
			"blorb": blorb,
			"pieces": entry["pieces"] as Array,
			"started": false,
			"start_pos": Vector3.ZERO,
			"delay": changed_index * JUMP_STAGGER,
			"elapsed": 0.0,
			"landed": false,
		}
		if new_slot == "":
			transition["land_pos"] = _scatter_point(changed_index, maxi(_worn.size(), 1))
		_transitions.append(transition)
		changed_index += 1
	_worn = retained

	# Newly assigned party members were not represented by a live suit piece,
	# so they hop on after the changed worn occupants, using the same brief
	# stagger while retained pieces remain completely untouched.
	for slot in BlorbSuit.SLOT_ORDER:
		var blorb := _assignments.get(slot) as Blorb
		if not is_instance_valid(blorb) or not blorb.in_party or blorb.is_melted or already_worn.has(blorb):
			continue
		blorb.begin_worn()
		_transitions.append({
			"mode": "on",
			"slot": slot,
			"blorb": blorb,
			"start_pos": blorb.global_position,
			"delay": changed_index * JUMP_STAGGER,
			"elapsed": 0.0,
			"landed": false,
		})
		changed_index += 1


## Reads _assignments as its primary source now, per direct instruction --
## toggling the suit on should put on whatever's actually been assigned via
## the paper-doll UI, not an arbitrary grab of whichever party members
## happen to be unworn. Any slot with no (valid) assignment still falls
## back to auto-filling from the leftover party pool, same as the original
## behavior, so toggling on still works for a player who's never opened the
## Blorbs tab at all -- and that auto-fill is itself recorded into
## _assignments as it happens, so a subsequent toggle is stable/idempotent
## instead of re-rolling a different arbitrary assignment each time.
func _start_equip_all() -> void:
	var already_assigned := {}
	for slot in _assignments:
		var b: Blorb = _assignments[slot]
		if b != null:
			already_assigned[b] = true

	var leftover: Array[Blorb] = []
	for b in _player.get_tree().get_nodes_in_group("blorbs"):
		if b.in_party and not b.is_worn and not b.is_melted and not already_assigned.has(b):
			leftover.append(b as Blorb)

	var leftover_index := 0
	var placed := 0
	for slot in BlorbSuit.SLOT_ORDER:
		var blorb: Blorb = _assignments.get(slot) as Blorb
		if blorb != null and (not is_instance_valid(blorb) or not blorb.in_party or blorb.is_melted):
			blorb = null
			_assignments.erase(slot)
		if blorb != null and blorb.is_worn:
			# A bulk on request can race the tail of an earlier transition;
			# an already-worn blorb needs no second hop.
			placed += 1
			continue
		if blorb == null:
			if leftover_index >= leftover.size():
				continue
			blorb = leftover[leftover_index]
			leftover_index += 1
			_assignments[slot] = blorb
		blorb.begin_worn()
		_transitions.append({
			"mode": "on",
			"slot": slot,
			"blorb": blorb,
			"start_pos": blorb.global_position,
			"delay": placed * JUMP_STAGGER,
			"elapsed": 0.0,
			"landed": false,
		})
		placed += 1

	if placed == 0:
		Hud.show_message("No blorbs to suit up!")


## Per direct instruction, the actual shape-swap (freeing the suit piece,
## revealing the round body again) is deferred to the moment THIS blorb's
## own hop actually starts -- see _update_transitions()'s own "started"
## handling -- not done for the whole party here up front. An earlier
## version did it right here for every entry at once, which left every
## still-waiting (delay > 0) blorb sitting reverted to its round body and
## floating in place on the player's body until its own staggered turn
## came up, instead of still reading as its own worn suit piece right up
## until it actually jumps off.
func _start_unequip_all() -> void:
	var total := _worn.size()
	for i in total:
		var entry: Dictionary = _worn[i]
		var blorb: Blorb = entry["blorb"] as Blorb
		var slot: String = entry["slot"] as String
		var pieces: Array = entry["pieces"] as Array
		_transitions.append({
			"mode": "off",
			"slot": slot,
			"blorb": blorb,
			"pieces": pieces,
			"started": false,
			"start_pos": Vector3.ZERO,
			"land_pos": _scatter_point(i, total),
			"delay": i * JUMP_STAGGER,
			"elapsed": 0.0,
			"landed": false,
		})
	_worn.clear()


## Shared by unequip_slot() and equip_to_slot() (which calls this first to
## clear out any existing occupant before putting a new one in) -- a no-op
## if the slot is already empty. Same "defer the shape-swap" deferral as
## _start_unequip_all() above, for consistency (this path has no stagger
## of its own -- delay is always 0 -- so it starts on the very next
## _update_transitions() call regardless).
func _begin_unequip_slot(slot: String) -> void:
	for i in _worn.size():
		var entry: Dictionary = _worn[i]
		if (entry["slot"] as String) != slot:
			continue
		var blorb := entry["blorb"] as Blorb
		var pieces: Array = entry["pieces"] as Array
		_worn.remove_at(i)
		_transitions.append({
			"mode": "off",
			"slot": slot,
			"blorb": blorb,
			"pieces": pieces,
			"started": false,
			"start_pos": Vector3.ZERO,
			"land_pos": _scatter_point(0, 1),
			"delay": 0.0,
			"elapsed": 0.0,
			"landed": false,
		})
		return


## Handles every entry in _transitions regardless of mode ("on"/"off") --
## each one resolves (lands in _worn, or finishes scattering off) entirely
## on its own elapsed/delay timing, independent of how many others are
## still in flight, which is what lets toggle()'s whole-party swap and
## equip_to_slot()/unequip_slot()'s individual-slot control share the exact
## same hop animation without needing to know about each other.
func _update_transitions(delta: float) -> void:
	var i := 0
	while i < _transitions.size():
		var entry: Dictionary = _transitions[i]
		var delay := entry["delay"] as float
		if delay > 0.0:
			entry["delay"] = delay - delta
			i += 1
			continue
		var mode := entry["mode"] as String
		# The moment an "off" entry's own delay expires -- not before, and
		# not for the whole party at once -- is when THIS blorb actually
		# starts hopping off, per direct instruction. The shape-swap (free
		# the suit piece, reveal the round body, anchor the hop's own start
		# position) is deliberately deferred all the way to here rather
		# than done up front in _start_unequip_all()/_begin_unequip_slot(),
		# so a still-waiting blorb keeps reading as its own worn suit piece
		# for the whole time it's waiting its turn.
		if mode in ["off", "move"] and not (entry["started"] as bool):
			var pieces := entry["pieces"] as Array
			for piece in pieces:
				if is_instance_valid(piece):
					BlorbSuit.release_piece(piece as Node3D)
			var starting_blorb := entry["blorb"] as Blorb
			var starting_slot := entry.get("from_slot", entry["slot"]) as String
			var fresh_start_pos := _slot_anchor_position(starting_slot)
			starting_blorb.begin_unworn()
			starting_blorb.global_position = fresh_start_pos
			entry["start_pos"] = fresh_start_pos
			entry["started"] = true
			if mode == "off":
				# Removing a suit releases the blorb at the player's current height.
				# Its own gravity now carries it to the surface below, so taking the
				# suit off in flight produces a real fall rather than a ground snap
				# disguised as a fixed-duration hop arc.
				var scatter := entry["land_pos"] as Vector3
				starting_blorb.finish_unworn(Vector3(scatter.x, fresh_start_pos.y, scatter.z))
				_transitions.remove_at(i)
				continue
		var elapsed: float = (entry["elapsed"] as float) + delta
		entry["elapsed"] = elapsed
		var t := clampf(elapsed / JUMP_DURATION, 0.0, 1.0)
		var blorb := entry["blorb"] as Blorb
		var slot := entry["slot"] as String
		var start_pos := entry["start_pos"] as Vector3
		var target: Vector3 = (entry["land_pos"] as Vector3) if mode == "off" else _slot_anchor_position(slot)
		var pos := start_pos.lerp(target, t)
		pos.y += sin(t * PI) * HOP_ARC_HEIGHT
		blorb.global_position = pos
		_face_hop_direction(blorb, start_pos, target)
		# Shrinks down to roughly the mass of the part it's about to become
		# on the way on, grows back on the way off -- eased (not linear
		# with the hop's own position lerp) so it reads as settling into
		# size rather than a mechanical resize.
		var shrink_from := BlorbSuit.slot_shrink_scale(slot, _rig_scale) if mode == "off" else 1.0
		var shrink_to := 1.0 if mode == "off" else BlorbSuit.slot_shrink_scale(slot, _rig_scale)
		blorb.set_visual_scale(lerpf(shrink_from, shrink_to, _smooth(t)))
		if t >= 1.0:
			if mode in ["on", "move"]:
				blorb.finish_worn()
				var pieces := BlorbSuit.equip_slot(slot, _pivots, _root, blorb, _rig_scale, _lava_helm_command_active())
				# Tags each piece as visible to the paper-doll's own
				# isolated portrait camera (see player_portrait.gd's own
				# module docstring on render layers) -- done once here at
				# creation, not on every subsequent per-frame rebuild
				# (_update_worn_limbs() below, for dynamic arm/leg slots):
				# rebuild_slot() only ever replaces the MESH RESOURCE on
				# this same node, never the node itself, and .layers is a
				# property of the node, not the resource, so it survives
				# every later rebuild untouched.
				for piece in pieces:
					if piece is VisualInstance3D:
						PlayerPortrait.tag_for_portrait(piece as VisualInstance3D)
					# Air wings are a Node3D container with visual children, unlike
					# the ordinary mesh-root suit pieces.
					for visual in (piece as Node).find_children("*", "VisualInstance3D", true, false):
						PlayerPortrait.tag_for_portrait(visual as VisualInstance3D)
				# Its own independent EyeBlink clock, not the controller's --
				# each worn piece is a DIFFERENT blorb from the party, so
				# sharing one clock had every piece blinking in unison, which
				# reads as one puppeted face rather than several individual
				# creatures.
				_worn.append({"slot": slot, "blorb": blorb, "pieces": pieces, "eye_blink": EyeBlink.new_state()})
			else:
				blorb.finish_unworn(target)
			_transitions.remove_at(i)
			continue
		i += 1


## Only the dynamic (limb) slots need rebuilding every frame -- torso/head
## are single-pivot pieces that already move for free via parenting (see
## BlorbSuit.equip_slot()'s own comment).
func _update_worn_limbs(lava_helm_command: bool) -> void:
	for entry in _worn:
		var slot := entry["slot"] as String
		if not BlorbSuit.is_dynamic_slot(slot):
			continue
		var pieces := entry["pieces"] as Array
		if pieces.is_empty():
			continue
		var mesh_instance := pieces[0] as MeshInstance3D
		var blorb := entry["blorb"] as Blorb
		BlorbSuit.rebuild_slot(mesh_instance, slot, _pivots, _root, blorb, _rig_scale, lava_helm_command)


## Stamps each worn entry's OWN blink clock's current openness onto that
## entry's EyeL/EyeR children -- covers all three eye-bearing slot kinds
## uniformly (limb noodles and the torso build them via blorb_suit.gd's
## _update_face, the head/hat via BlorbFace.add_eyes), since all three now
## name their eye nodes the same way. Per-entry (not one shared clock)
## deliberately, so the different blorbs worn across the suit's slots
## blink independently rather than all in visible unison.
func _apply_eye_blink(delta: float) -> void:
	for entry in _worn:
		var eye_blink := entry["eye_blink"] as Dictionary
		EyeBlink.advance(eye_blink, delta)
		var o := EyeBlink.openness(eye_blink)
		for piece in (entry["pieces"] as Array):
			if not is_instance_valid(piece):
				continue
			var p := piece as Node3D
			for eye_name in ["EyeL", "EyeR"]:
				var eye := p.get_node_or_null(eye_name)
				if eye != null:
					(eye as Node3D).scale.y = o


## Equipped air wings use a slow continuous beat. It accelerates mildly
## with real flight speed, but remains smoother than a bird-like flap.
func _update_worn_air_wings(delta: float) -> void:
	var flying := _player is Player and (_player as Player).is_air_flight_active()
	var speed_scale := 1.0
	if flying:
		speed_scale += clampf((_player as Player).velocity.length() / FLIGHT_REFERENCE_SPEED, 0.0, 1.0) * 0.55
	_air_wing_flap_phase += delta * 1.5 * speed_scale
	var flap := sin(_air_wing_flap_phase) * deg_to_rad(7.0)
	for entry in _worn:
		var blorb := entry["blorb"] as Blorb
		if blorb.element_state != "air":
			continue
		for piece in (entry["pieces"] as Array):
			if piece is Node3D and (piece as Node3D).name == "AirBlorbWings":
				BlorbSuit.animate_air_wings(piece as Node3D, flap)


## Where a given slot's attachment point currently is, in world space --
## sampled fresh every call (not cached at hop-start) so a hop still tracks
## correctly even if the player moves/animates mid-flight.
func _slot_anchor_position(slot: String) -> Vector3:
	match slot:
		"torso":
			return (_pivots["spine"] as Node3D).global_position
		"head":
			return (_pivots["head"] as Node3D).global_position
		"arm_left":
			return (_pivots["arm_left_shoulder"] as Node3D).global_position
		"arm_right":
			return (_pivots["arm_right_shoulder"] as Node3D).global_position
		"leg_left":
			return (_pivots["leg_left_hip"] as Node3D).global_position
		"leg_right":
			return (_pivots["leg_right_hip"] as Node3D).global_position
	return _player.global_position


func _scatter_point(index: int, total: int) -> Vector3:
	var angle := (float(index) / maxf(float(total), 1.0)) * TAU + _rng.randf_range(-0.3, 0.3)
	var radius := _rng.randf_range(LAND_SCATTER_RADIUS_MIN, LAND_SCATTER_RADIUS_MAX)
	var offset := Vector3(cos(angle), 0.0, sin(angle)) * radius
	return _player.global_position + offset


func _face_hop_direction(blorb: Blorb, from: Vector3, to: Vector3) -> void:
	var dir := Vector2(to.x - from.x, to.z - from.z)
	if dir.length() > 0.01:
		blorb.rotation.y = atan2(dir.x, dir.y)


## Smoothstep -- zero slope at both ends, used to ease the hop's own
## shrink/grow scale independently of the hop arc's own linear position
## lerp (see _update_transitions()).
func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)
