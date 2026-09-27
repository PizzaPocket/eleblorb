class_name VineCord
extends RefCounted

## The vine a Leaf Hat throws, as a drawn thing: one cord growing from a hand to
## its anchor, plus however many spent cords are still retracting back into the
## hands that threw them.
##
## Split out of VineSwingMode, which had grown to four jobs in one class. This is
## the presentation one, and it owns nothing about how a swing works: it is told
## where a hand is and where its anchor is, and it draws the line between them.
##
## The cords are parented to the scene rather than to the body, because a cord
## connects two points in the world and must not inherit the swinging body's own
## motion.

## How fast a thrown cord reaches its anchor.
const CAST_SPEED := 46.0
## A spent cord snaps back in this long whatever its length, rather than at a
## fixed speed. At a speed a long cord took most of a second to come in, and for
## that whole time a line still ran from the swinger's wrist back to a tree he had
## already left, which read as still being attached to it.
const RETRACT_TIME := 0.11
const TOP_RADIUS := 0.016
const BOTTOM_RADIUS := 0.022
## The throwing hand's height above the feet on the human figure, used only when
## a rig publishes no hand joint at all. This one length is the body's, so it
## follows the rig through ctx.scaled().
const REFERENCE_HAND_HEIGHT := 1.6

## The cord in hand, and the ones on their way back.
var _mesh: MeshInstance3D
## How much of the cord in hand has reached its anchor, 0 to 1.
var _grown := 0.0
var _retiring: Array[Dictionary] = []


## Where a vine meets its hand: the wrist, which is where a hand grips a line
## rather than the fingertips it curls past. The fingertip is asked for only if a
## rig has no wrist marker, and the body itself last, rather than assuming a joint
## every rig happens not to have.
static func hand_point(ctx: TraversalContext, use_left: bool) -> Vector3:
	var rig := ctx.rig
	if rig != null:
		var names := (
			["wrist_left", "fingertip_left"] if use_left
			else ["wrist_right", "fingertip_right"]
		)
		for joint_name: String in names:
			var hand := rig.joint(joint_name)
			if hand != null:
				return hand.global_position
	return ctx.body.global_position + Vector3.UP * ctx.scaled(REFERENCE_HAND_HEIGHT)


## Draws this frame's cord, growing it toward `anchor` from the named hand. The
## mesh is made on the first call and reused after.
func grow(ctx: TraversalContext, anchor: Vector3, from_left: bool) -> void:
	var scene := ctx.body.get_tree().current_scene
	if scene == null:
		return
	if not is_instance_valid(_mesh):
		_mesh = MeshInstance3D.new()
		_mesh.name = "SwingVine"
		var material := StandardMaterial3D.new()
		material.albedo_color = LeafHat.VINE_COLOR
		material.roughness = 0.9
		_mesh.material_override = material
		scene.add_child(_mesh)
	var start := hand_point(ctx, from_left)
	var full := start.distance_to(anchor)
	_grown = move_toward(_grown, 1.0, CAST_SPEED * ctx.delta / maxf(full, 0.001))
	_draw(_mesh, start, start.lerp(anchor, _grown))


## Hands the cord over to the retracting set, its tip travelling back to the hand
## that threw it while the other hand's own throw is already on its way out.
func retire(from_anchor: Vector3, from_left: bool) -> void:
	if not is_instance_valid(_mesh):
		return
	_retiring.append({
		"mesh": _mesh, "anchor": from_anchor,
		"left_hand": from_left, "fraction": _grown,
	})
	_mesh = null
	_grown = 0.0


## Lets go on purpose: the cord is gone at once rather than retracting on its own
## time, which left a line trailing back to a tree already left behind.
func release() -> void:
	if is_instance_valid(_mesh):
		_mesh.queue_free()
	_mesh = null
	_grown = 0.0


## Everything at once, for a power shutting down.
func clear() -> void:
	release()
	for entry in _retiring:
		var mesh := entry["mesh"] as MeshInstance3D
		if is_instance_valid(mesh):
			mesh.queue_free()
	_retiring.clear()


## Draws down every retracting cord, freeing each as it reaches its hand.
func advance(ctx: TraversalContext) -> void:
	for index in range(_retiring.size() - 1, -1, -1):
		var entry: Dictionary = _retiring[index]
		var mesh := entry["mesh"] as MeshInstance3D
		if not is_instance_valid(mesh):
			_retiring.remove_at(index)
			continue
		# Read the wrist fresh every frame, so the cord stays in the hand while it
		# comes in rather than trailing from wherever that hand used to be.
		var hand := hand_point(ctx, bool(entry["left_hand"]))
		var from_anchor: Vector3 = entry["anchor"]
		var fraction := float(entry["fraction"]) - ctx.delta / RETRACT_TIME
		if fraction <= 0.0:
			mesh.queue_free()
			_retiring.remove_at(index)
			continue
		entry["fraction"] = fraction
		_retiring[index] = entry
		_draw(mesh, hand, hand.lerp(from_anchor, fraction))


## One cord, as a tapered cylinder laid between two points. The mesh is reused
## across frames and only its height changes, so a swing allocates nothing.
static func _draw(mesh_instance: MeshInstance3D, start: Vector3, finish: Vector3) -> void:
	var length := start.distance_to(finish)
	mesh_instance.visible = length > 0.002
	if not mesh_instance.visible:
		return
	var cylinder := mesh_instance.mesh as CylinderMesh
	if cylinder == null:
		cylinder = CylinderMesh.new()
		cylinder.top_radius = TOP_RADIUS
		cylinder.bottom_radius = BOTTOM_RADIUS
		cylinder.radial_segments = 7
		mesh_instance.mesh = cylinder
	cylinder.height = length
	mesh_instance.global_position = (start + finish) * 0.5
	mesh_instance.global_basis = Basis(Quaternion(Vector3.UP, (finish - start).normalized()))
