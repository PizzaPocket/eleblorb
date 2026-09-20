class_name EscapePod
extends Node3D

## The ASAN vehicle's escape pod (see demo_spaceship.gd), mounted outside the
## blorb-sized hatch at the aft end of the hull's flank. Its own shell is a
## small hollow superegg with a single superellipse opening facing that hatch,
## so only a blorb can reach it: nothing else on the course fits through.
##
## Once a blorb is aboard the pod seals and counts itself down, then drops
## away and flies to `landing_point` at speed, carrying its rider pinned in
## the seat. It arrives hard, and the rider climbs out where it lands.

signal impacted(at: Vector3)

const SHELL := Color(0.90, 0.92, 0.96)
const TRIM := Color(0.15, 0.16, 0.20)
const GLOW := Color(1.0, 0.62, 0.26)

## The pod's own body: shell radius, half-length and wall thickness.
const POD_RADIUS := 2.4
const POD_HALF_LENGTH := 3.6
const POD_WALL := 0.22
## Its opening, on the shell's +X side, facing the hull's hatch.
const POD_DOOR_CENTER := Vector2(0.0, 0.0)
const POD_DOOR_HALF := Vector2(1.5, 1.5)
## How long it counts down once someone is aboard, and how fast it flies.
const COUNTDOWN := 5.0
const FLIGHT_SPEED := 260.0
## How close to the seat's centre a body must be to count as aboard.
const SEAT_RADIUS := 2.0

## Where it flies to, set by whoever builds the world.
var landing_point := Vector3.ZERO

var _rider: Node3D = null
var _countdown := 0.0
var _announced := -1
var _flying := false
var _landed := false
var _seat: Node3D


func _ready() -> void:
	_build_pod()


func _build_pod() -> void:
	var shell := MeshInstance3D.new()
	shell.name = "PodShell"
	var apertures: Array[Dictionary] = [
		{"center": POD_DOOR_CENTER, "half": POD_DOOR_HALF, "exponent": 2.6},
	]
	shell.mesh = SuperEgg.build_hollow_shell_mesh(
		Vector3(POD_RADIUS, POD_HALF_LENGTH, POD_RADIUS), POD_WALL, apertures,
		SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT, SuperEgg.RINGS, SuperEgg.SEGMENTS
	)
	var material := StandardMaterial3D.new()
	material.albedo_color = SHELL
	material.roughness = 0.3
	material.metallic = 0.14
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	shell.material_override = material
	add_child(shell)
	CollisionPolicy.mark_decorative(shell)

	# The seat pad the rider rides on, and the floor under it.
	var floor_body := StaticBody3D.new()
	floor_body.name = "PodFloor"
	floor_body.collision_layer = 1
	floor_body.position = Vector3(0.0, -POD_HALF_LENGTH + 0.9, 0.0)
	add_child(floor_body)
	var pad := SuperEgg.build_part(
		Vector3(POD_RADIUS - 0.6, 0.18, POD_RADIUS - 0.6), TRIM,
		SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT
	)
	pad.name = "PodFloorPad"
	floor_body.add_child(pad)
	CollisionPolicy.add_box(floor_body, pad, Vector3(POD_RADIUS - 0.6, 0.18, POD_RADIUS - 0.6) * 2.0)

	_seat = Node3D.new()
	_seat.name = "PodSeat"
	_seat.position = Vector3(0.0, -POD_HALF_LENGTH + 1.6, 0.0)
	add_child(_seat)

	var retro := SuperEgg.build_part(Vector3(1.5, 0.7, 1.5), TRIM)
	retro.name = "PodRetro"
	retro.position = Vector3(0.0, POD_HALF_LENGTH - 0.3, 0.0)
	add_child(retro)
	CollisionPolicy.mark_decorative(retro)

	var beacon := OmniLight3D.new()
	beacon.name = "PodBeacon"
	beacon.light_color = GLOW
	beacon.light_energy = 1.4
	beacon.omni_range = 9.0
	beacon.shadow_enabled = false
	beacon.position = Vector3(0.0, -POD_HALF_LENGTH + 2.4, 0.0)
	add_child(beacon)


func _process(delta: float) -> void:
	if _landed:
		return
	if _flying:
		_advance_flight(delta)
		return
	var aboard := _blorb_aboard()
	if aboard == null:
		_rider = null
		_countdown = 0.0
		_announced = -1
		return
	if _rider != aboard:
		_rider = aboard
		_countdown = COUNTDOWN
		_announced = -1
	_countdown -= delta
	var remaining := int(ceil(maxf(_countdown, 0.0)))
	if remaining != _announced:
		_announced = remaining
		Hud.show_passive_message(str(remaining), 1.0)
	if _countdown <= 0.0:
		_launch()


## The blorb in the seat, if any: only Blorbus fits through the hatch, and
## only while they are the body being driven.
func _blorb_aboard() -> Node3D:
	var body := PartyControl.active_control_body()
	if not is_instance_valid(body) or not (body is Blorb):
		return null
	if not (body as Blorb).is_blorbus:
		return null
	if body.global_position.distance_to(_seat.global_position) > SEAT_RADIUS:
		return null
	return body


## Drops away from the hull and starts down. Keeping the pod's world
## transform through the reparent means it leaves from exactly where it hung.
func _launch() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	var here := global_transform
	get_parent().remove_child(self)
	world.add_child(self)
	global_transform = here
	_flying = true
	UISounds.play_foley(&"giant_step", 1.0, get_instance_id())


func _advance_flight(delta: float) -> void:
	var to_target := landing_point - global_position
	var step := FLIGHT_SPEED * delta
	if to_target.length() <= step:
		global_position = landing_point
		_land()
		return
	global_position += to_target.normalized() * step
	# Nose first, down the flight path.
	var heading := to_target.normalized()
	if absf(heading.dot(Vector3.UP)) < 0.999:
		look_at(global_position + heading, Vector3.UP)
		rotate_object_local(Vector3.RIGHT, -PI * 0.5)
	_carry_rider()


func _land() -> void:
	_flying = false
	_landed = true
	_carry_rider()
	impacted.emit(global_position)


## The rider rides in the seat: their own movement is overwritten each frame
## while the pod is under way, then handed straight back on landing.
func _carry_rider() -> void:
	if not is_instance_valid(_rider):
		return
	_rider.global_position = _seat.global_position
	if _rider is CharacterBody3D:
		(_rider as CharacterBody3D).velocity = Vector3.ZERO
