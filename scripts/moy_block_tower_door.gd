extends StaticBody3D

## The forecourt door is heavy and closed from outside. The interior raises
## WorldState.block_tower_door_open only after the fight, then this leaf swings
## clear of the threshold and remains open across scene streaming.

var _opened := false
var _tween: Tween


func _process(_delta: float) -> void:
	if _opened or not WorldState.block_tower_door_open:
		return
	_opened = true
	var collision := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.set_deferred("disabled", true)
	var visual := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if visual != null:
		_tween = create_tween()
		_tween.tween_property(visual, "rotation:y", -PI * 0.48, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
