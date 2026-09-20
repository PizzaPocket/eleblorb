class_name TraversalDirector
extends RefCounted

## Runs one body's traversal powers in priority order: the first mode that
## takes the frame owns both the movement and the pose, and no later mode
## runs. This replaces the long if/elif chains that grew inside
## player.gd::_physics_process and xiao_hou_zi.gd, and it is deliberately the
## single body-pose owner that tools/check_body_pose_owner.py enforces.
##
## Order matters and is the caller's to choose: the list is ordered most
## specific first, so that (for example) the mermaid tail wins over ordinary
## swimming and the crystal track wins over ordinary skating.

var modes: Array[TraversalMode] = []
## The mode that owned the most recent frame, or null when ordinary movement
## did.
var active: TraversalMode = null


func add(mode: TraversalMode) -> void:
	modes.append(mode)


## Gives each mode its chance in order. Returns true when one took the frame.
func run(ctx: TraversalContext) -> bool:
	active = null
	for mode in modes:
		if not mode.is_available(ctx):
			continue
		if mode.update(ctx):
			active = mode
			return true
	return false


## Poses whichever mode owned the frame. Ordinary movement poses itself, so
## this does nothing when no mode took the frame.
func pose(ctx: TraversalContext) -> void:
	if active != null:
		active.pose(ctx)


func active_id() -> StringName:
	return active.id() if active != null else &""


## Every power this body could engage right now, for the parity probe.
func available_ids(ctx: TraversalContext) -> Array[StringName]:
	var ids: Array[StringName] = []
	for mode in modes:
		if mode.is_available(ctx):
			ids.append(mode.id())
	return ids
