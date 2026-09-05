extends Node3D

## Small faceted "cut gem" prop, built procedurally since neither asset kit
## has one. A hexagonal bipyramid (two 6-sided pyramids joined base-to-base)
## with flat per-facet shading, apple-sized by default. Optionally a free
## touch-to-collect pickup (collectible) and/or a slow bob/spin (floats) --
## independent of each other; a plain, non-collectible gem is also used as
## ShopCatalog's Fire/Water Gem build_visual (see _build_gem_visual there),
## for shop-counter scenery and the player's held-item visual alike.
##
## Automatic on contact, like tokoin.gd -- per direct instruction, not a
## press-F prompt (unlike fruit.gd/a landed thrown item). A find out in the
## world reads better as a clean "walk up and it's yours" moment than
## needing a confirmation press.

@export var gem_color: Color = Color(0.25, 0.55, 1.0)
@export var radius: float = 0.06
@export var height: float = 0.16
@export var display_name: String = ""
@export var collectible: bool = false
@export var floats: bool = false
## Non-empty for a one-of-a-kind world find (the Rock Gem, the Ground Gem,
## ...): checked against/recorded into WorldState so it stays gone across a
## portal round trip's scene reload instead of respawning with the rest of
## the outskirts. "" (the default) opts a gem out entirely -- it behaves
## exactly as before, tracked only by this instance's own _collected below.
@export var unique_id: String = ""

const PICKUP_RADIUS := 0.35
const FLOAT_SPEED := 1.2
const FLOAT_AMPLITUDE := 0.08
const SPIN_SPEED := 0.9

var _collected: bool = false
var _base_y: float
var _time: float = 0.0


func _ready() -> void:
	if collectible and WorldState.is_collected(unique_id):
		queue_free()
		return
	_build_mesh()
	_base_y = position.y
	if collectible:
		_build_pickup_area()


func _process(delta: float) -> void:
	if not floats:
		return
	_time += delta
	position.y = _base_y + sin(_time * FLOAT_SPEED) * FLOAT_AMPLITUDE
	rotate_y(SPIN_SPEED * delta)


func _build_pickup_area() -> void:
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 2  # player only (see player.tscn)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PICKUP_RADIUS
	shape.shape = sphere
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_pickup_body_entered)


func _on_pickup_body_entered(body: Node3D) -> void:
	if _collected or not (body is CharacterBody3D):
		return
	_collected = true
	WorldState.mark_collected(unique_id)
	var found_name := display_name if display_name != "" else "gem"
	Inventory.add(found_name, gem_color)
	Hud.show_message("Found the %s!" % found_name)
	queue_free()


func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var sides := 6
	var top := Vector3(0, height * 0.5, 0)
	var bottom := Vector3(0, -height * 0.5, 0)
	var ring: Array[Vector3] = []
	for i in sides:
		var angle := (float(i) / sides) * TAU
		ring.append(Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))

	for i in sides:
		var a := ring[i]
		var b := ring[(i + 1) % sides]
		FacetMeshUtils.add_tri(st, top, b, a)
		FacetMeshUtils.add_tri(st, bottom, a, b)

	var material := StandardMaterial3D.new()
	material.albedo_color = gem_color
	material.metallic = 0.3
	material.roughness = 0.12
	material.emission_enabled = true
	material.emission = gem_color
	material.emission_energy_multiplier = 1.4
	# Winding-vs-culling convention wasn't reliably verifiable last time
	# this came up (see project memory) -- disabling culling on this tiny
	# 12-triangle mesh costs nothing and guarantees no invisible facets
	# regardless of which way the winding actually resolves.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	st.set_material(material)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = st.commit()
	add_child(mesh_instance)
