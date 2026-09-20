extends SceneTree

## Rig parity, measured rather than asserted. Run it headless:
##
##   Godot --headless --path . -s tools/probe_parity.gd
##
## For every playable rig it reports which joints actually articulate, and
## which ones one rig has that another does not. A joint that exists but
## moves nothing counts as missing, because that is what it is worth to a
## pose (see RigAdapter.articulates(), and the comment above
## MonkeyFigure.build() for how this rig came to have several of those).
##
## As powers move onto the shared system
## (docs/traversal_powers_architecture.md) this grows a second half: each
## power, and which characters can engage it. Until then the rig half is the
## half that decides what is even possible.

const JOINTS := [
	"arm_left_shoulder", "arm_right_shoulder", "arm_left_elbow", "arm_right_elbow",
	"wrist_left", "wrist_right", "hand_left", "hand_right",
	"leg_left_hip", "leg_right_hip", "leg_left_knee", "leg_right_knee",
	"leg_left_ankle", "leg_right_ankle", "toe_left", "toe_right",
	"spine", "thorax", "neck", "head",
]

var _frame := 0
var _rigs: Array = []


func _map(pivots: Dictionary) -> Dictionary:
	var map := {}
	var pairs := {
		"arm_left_shoulder": "arm_left", "arm_right_shoulder": "arm_right",
		"arm_left_elbow": "elbow_left", "arm_right_elbow": "elbow_right",
		"leg_left_hip": "leg_left", "leg_right_hip": "leg_right",
		"leg_left_knee": "knee_left", "leg_right_knee": "knee_right",
		"leg_left_ankle": "ankle_left", "leg_right_ankle": "ankle_right",
	}
	for name in pairs:
		if pivots.has(pairs[name]):
			map[name] = pivots[pairs[name]]
	for name in ["wrist_left", "wrist_right", "hand_left", "hand_right", "toe_left", "toe_right", "spine", "thorax", "neck", "head"]:
		if pivots.has(name):
			map[name] = pivots[name]
	return map


func _process(_d: float) -> bool:
	_frame += 1
	if _frame == 1:
		var PF = load("res://scripts/procedural_figure.gd")
		var MF = load("res://scripts/monkey_figure.gd")
		var human_host := Node3D.new()
		root.add_child(human_host)
		_rigs.append(["Player (ProceduralFigure)", PF.build(human_host)])
		var monkey_host := Node3D.new()
		monkey_host.position = Vector3(4, 0, 0)
		root.add_child(monkey_host)
		_rigs.append(["Xiao Hou Zi (MonkeyFigure)", MF.build(monkey_host)])
		return false
	if _frame < 4:
		return false
	var adapters := []
	for entry in _rigs:
		adapters.append(RigAdapter.new(_map(entry[1] as Dictionary)))
	print("\n=== RIG PARITY ===")
	var header := "%-20s" % "joint"
	for entry in _rigs:
		header += "  %-28s" % entry[0]
	print(header)
	var totals := []
	for adapter in adapters:
		totals.append(0)
	for joint in JOINTS:
		var line := "%-20s" % joint
		for index in adapters.size():
			var adapter: RigAdapter = adapters[index]
			var word := "-- absent"
			if adapter.articulates(joint):
				word = "yes"
				totals[index] = int(totals[index]) + 1
			elif adapter.state(joint) == RigAdapter.Joint.ALIASED:
				word = "no (shares %s)" % adapter.alias_of(joint)
			elif adapter.has_real(joint):
				word = "no (moves nothing)"
			line += "  %-28s" % word
		print(line)
	var footer := "%-20s" % "articulating"
	for total in totals:
		footer += "  %-28s" % str(total)
	print(footer)
	# What the second rig lacks relative to the first.
	if adapters.size() > 1:
		# A joint counts as covered when the node it shares moves: on the
		# monkey rig the hand IS the wrist, which is a difference in naming
		# rather than in what the character can do.
		var other := adapters[1] as RigAdapter
		var missing: Array[String] = []
		for joint in JOINTS:
			if not (adapters[0] as RigAdapter).articulates(joint):
				continue
			if other.articulates(joint):
				continue
			var alias := other.alias_of(joint)
			if alias != "" and other.articulates(alias):
				continue
			missing.append(joint)
		print("\n%s lacks, relative to the player: %s" % [
			_rigs[1][0], ", ".join(missing) if missing.size() > 0 else "nothing"])
	return true
