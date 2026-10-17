extends Node3D

## Two floating gloves; their reach implies arms without creating any limbs.
## The owning Blorb advances this alongside its combat/lifecycle checks.
const DURATION := 0.34
const IMPACT := 0.45
var _gloves: Array[Node3D] = []
var _elapsed := 0.0
var _active := false
var _hand := 1
var _hit := false


func _ready() -> void:
	for side in [-1, 1]:
		var glove := ShopCatalog.build_boxing_glove_visual(1.5, float(side))
		glove.name = "LeftGlove" if side > 0 else "RightGlove"
		glove.quaternion = Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP).get_rotation_quaternion()
		add_child(glove)
		CollisionPolicy.mark_decorative(glove)
		_gloves.append(glove)
	_pose(0.0)


func begin_punch() -> bool:
	if _active: return false
	_hand = 1 - _hand
	_elapsed = 0.0
	_hit = false
	_active = true
	return true


func advance(delta: float) -> bool:
	if not _active: return false
	_elapsed += delta
	var t := clampf(_elapsed / DURATION, 0.0, 1.0)
	_pose(sin(PI * minf(t / (IMPACT * 2.0), 1.0)))
	var impact := not _hit and t >= IMPACT
	if impact: _hit = true
	if t >= 1.0:
		_active = false
		_pose(0.0)
	return impact


func cancel() -> void:
	_active = false
	_hit = true
	_pose(0.0)


func _pose(extension: float) -> void:
	for i in _gloves.size():
		var reach := extension if i == _hand else 0.0
		var side := -1.0 if i == 0 else 1.0
		# No visible arms: the outward, drawn-back chamber and mirrored
		# thumb-up guard imply the same action as the worn suit's elbows.
		# Twist into the existing palm-down, inward-thumb extension.
		var strike := Basis(Vector3.LEFT, Vector3.BACK, Vector3.UP)
		var twist := -side * PI * 0.5 * (1.0 - reach)
		_gloves[i].quaternion = (strike * Basis(Vector3.UP, twist)).get_rotation_quaternion()
		_gloves[i].position = Vector3(side * lerpf(1.02, 0.26, reach), 0.28 + 0.05 * reach, lerpf(0.25, 1.15, reach))
