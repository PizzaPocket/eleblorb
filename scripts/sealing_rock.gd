class_name SealingRock
extends Node3D

## The rock the courts sealed Sun Wu Kong under, on the north rim of Lantern
## Row (docs/architecture/chinese_village.md, section 4.6): a weathered grey
## boulder about 5 x 3.5 m and 3 m high, half sunk in the turf, moss on its top,
## a thin gold band bound round it with six small emblems for the six courts, and
## the red cord Mei Lian ties each New Year. When Sun Wu Kong is freed it splits
## in two and the band falls; the halves stay where they fell and are built that
## way on every later visit. The state is read from WorldState when the village
## is built, never swapped in front of the player except for the one split.

const RADIUS := 2.5
const SQUASH := Vector3(1.0, 0.8, 0.78)
const BAND_COLOR := Color(0.86, 0.68, 0.2)
const CORD_COLOR := Color(0.7, 0.1, 0.08)
const MOSS_COLOR := Color(0.28, 0.42, 0.2)
const ROCK_COLOR := Color(0.5, 0.5, 0.48)
const SPLIT_SECONDS := 1.1

var _whole: StaticBody3D
var _halves: Array[StaticBody3D] = []
var _fallen_band: Node3D


func _ready() -> void:
	add_to_group("sealing_rock")
	if WorldState.sun_wu_kong_freed:
		_build_split()
	else:
		_build_whole()


func _build_whole() -> void:
	_whole = StaticBody3D.new()
	_whole.name = "SealingRockWhole"
	_whole.collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
	_whole.collision_mask = 0
	add_child(_whole)
	var rock := NatureProps.build_rock(RADIUS, false, ROCK_COLOR)
	rock.scale = SQUASH
	# Half sunk in the turf.
	rock.position.y = -0.55
	_whole.add_child(rock)
	var body_height := RADIUS * 1.45 * SQUASH.y - 0.55
	CollisionPolicy.add_cylinder(_whole, rock, RADIUS * 0.85, body_height, Vector3(0.0, body_height * 0.5, 0.0), true)
	# Moss and grass on the crown.
	var moss := SuperEgg.build_part(Vector3(RADIUS * 0.6, 0.12, RADIUS * 0.45), MOSS_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	moss.position = Vector3(0.1, body_height + 0.02, 0.0)
	CollisionPolicy.mark_decorative(moss)
	_whole.add_child(moss)
	# The courts' seal: a gold band round the waist, with six emblems, and Mei
	# Lian's red cord a hand's width above it.
	var band := SuperEgg.build_part(Vector3(RADIUS * 0.98, 0.07, RADIUS * 0.8), BAND_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	band.position.y = 1.35
	CollisionPolicy.mark_decorative(band)
	_whole.add_child(band)
	var cord := SuperEgg.build_part(Vector3(RADIUS * 0.97, 0.03, RADIUS * 0.79), CORD_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	cord.position.y = 1.55
	CollisionPolicy.mark_decorative(cord)
	_whole.add_child(cord)
	for i in 6:
		var angle := TAU * float(i) / 6.0 + 0.3
		var emblem := SuperEgg.build_part(Vector3(0.14, 0.14, 0.05), BAND_COLOR.lightened(0.1), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
		emblem.position = Vector3(sin(angle) * RADIUS * 0.98, 1.35, cos(angle) * RADIUS * 0.8)
		emblem.rotation.y = angle
		CollisionPolicy.mark_decorative(emblem)
		_whole.add_child(emblem)


## The two halves where they fell, and the band lying flat on the turf.
func _build_split() -> void:
	for side: float in [-1.0, 1.0]:
		var half := StaticBody3D.new()
		half.name = "SealingRockHalf"
		half.collision_layer = 1 | TownProps.BLORB_CLIMBABLE_LAYER
		half.collision_mask = 0
		add_child(half)
		var radius := RADIUS * 0.62
		var rock := NatureProps.build_rock(radius, false, ROCK_COLOR)
		rock.scale = Vector3(1.0, 1.15, 1.0)
		rock.position.y = -0.3
		half.add_child(rock)
		var height := radius * 1.45 * 1.15 - 0.3
		CollisionPolicy.add_cylinder(half, rock, radius * 0.85, height, Vector3(0.0, height * 0.5, 0.0), true)
		half.position = Vector3(side * 1.9, 0.0, 0.1 * side)
		half.rotation = Vector3(0.0, side * 0.4, -side * 0.2)
		_halves.append(half)
	_fallen_band = Node3D.new()
	_fallen_band.name = "FallenBand"
	var band := SuperEgg.build_part(Vector3(1.5, 0.05, 1.2), BAND_COLOR, SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_SOFT)
	band.position = Vector3(0.0, 0.05, 1.7)
	CollisionPolicy.mark_decorative(band)
	_fallen_band.add_child(band)
	add_child(_fallen_band)


## Called once, when the player frees him: the rock opens, the band drops, and
## the halves are then left where they are.
func split() -> void:
	if _whole == null:
		return
	var whole := _whole
	_whole = null
	_build_split()
	var tween := create_tween().set_parallel(true)
	for half in _halves:
		var rest_position := half.position
		var rest_rotation := half.rotation
		half.position = Vector3(rest_position.x * 0.2, 0.0, 0.0)
		half.rotation = Vector3.ZERO
		tween.tween_property(half, "position", rest_position, SPLIT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(half, "rotation", rest_rotation, SPLIT_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(whole.queue_free)
