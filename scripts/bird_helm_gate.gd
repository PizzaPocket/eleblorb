class_name BirdHelmGate
extends Node3D

## Hides and un-collides everything under this node unless the player's
## own worn head blorb carries the Bird Helm -- the same "totally turned
## off" visibility rule sky_kingdom.gd's own islands use (see that file's
## own class doc), shared here by the cloud staircase that leads up to
## them: both the converted crate-and-grass steps (see town_generator.gd's
## own _build_sky_stairs()) and the existing cloud parkour course/Air Gem
## above them (cloud_scatter.gd's own build_sky_course(), which now builds
## its "SkyParkourCourse" node as one of these instead of a plain Node3D).
## Checked off the human player's own suit specifically, not whichever
## companion is currently piloted.

var _player: Player
## Matches the node's own real default (a freshly created Node3D is
## visible) rather than forcing a premature hidden state in _ready() --
## the gate is created at runtime, mid procedural-generation, well after
## the player's own suit state may already be known (the debug loadout
## equips the Bird Helm immediately), so hiding first and only correcting
## on the next _physics_process tick risked staying invisible if that tick
## were delayed (e.g. by the loading screen's own pause) -- reported as
## "erased the entire spiral staircase."
var _gate_visible := true


## Runs even while the loading screen has the tree paused (matches
## loading_screen.gd's own identical process_mode) -- otherwise a gate
## created mid-load could sit un-evaluated for an arbitrary number of
## paused frames before its first real _physics_process tick.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_tree().get_first_node_in_group("player") as Player
	var suit := _player.get_own_blorb_suit() if is_instance_valid(_player) else null
	_apply(is_instance_valid(suit) and suit.has_head_bird_helm())


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
		return
	var suit := _player.get_own_blorb_suit()
	var should_show := is_instance_valid(suit) and suit.has_head_bird_helm()
	if should_show == _gate_visible:
		return
	_apply(should_show)


func _apply(active: bool) -> void:
	_gate_visible = active
	visible = active
	for body in find_children("*", "StaticBody3D", true, false):
		var static_body := body as StaticBody3D
		if not static_body.has_meta("bird_helm_gate_layer"):
			static_body.set_meta("bird_helm_gate_layer", static_body.collision_layer)
		static_body.collision_layer = (static_body.get_meta("bird_helm_gate_layer") as int) if active else 0
