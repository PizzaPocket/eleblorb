extends Area3D

## A tokoin lying out in the world: a dinner-plate-sized coin standing up
## on its edge (not lying flat), slowly spinning about that edge like a
## classic collectible. Vanishes and pays into the wallet automatically on
## contact -- per direct instruction, currency specifically stays a plain
## walk-through pickup (unlike gem.gd/fruit.gd/a landed thrown item, which
## need a deliberate press-F per direct instruction) since stopping to
## confirm every single coin picked up along the way would be tedious for
## something this frequent and inconsequential. One physical tokoin is
## worth 10 wallet value.

const RADIUS := 0.14
const THICKNESS := 0.07
const SPIN_SPEED := 0.7
const VALUE := 10

@onready var terrain: Node = get_node("../Terrain")
@onready var visual: Node3D = $Visual

var _collected: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2  # player only (see player.tscn: collision_layer = 2)
	global_position.y = terrain.get_mesh_height(global_position.x, global_position.z) + RADIUS
	_build()
	body_entered.connect(_on_body_entered)


func _build() -> void:
	# Visual's own rotation_degrees = (0, 0, 90) (set in tokoin.tscn) tips
	# the disc onto its edge; spinning the root around Y here then rotates
	# that standing coin about the vertical axis, like it's being flipped
	# in place rather than lying flat and spinning like a wheel.
	var mesh_instance := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = RADIUS
	cylinder.bottom_radius = RADIUS
	cylinder.height = THICKNESS
	cylinder.radial_segments = 24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.78, 0.25)
	mat.metallic = 0.85
	mat.roughness = 0.25
	cylinder.material = mat
	mesh_instance.mesh = cylinder
	visual.add_child(mesh_instance)

	var collision_shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = RADIUS + 0.08
	collision_shape.shape = sphere
	add_child(collision_shape)


func _process(delta: float) -> void:
	rotate_y(SPIN_SPEED * delta)


func _on_body_entered(_body: Node3D) -> void:
	if _collected:
		return
	_collected = true
	TokoinWallet.add(VALUE)
	UISounds.play_foley(&"tokoin_pickup", 0.48, get_instance_id())
	queue_free()
