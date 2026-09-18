class_name CheckpointPortal
extends Node3D

## A checkpoint portal: an upright super-egg ring of noodle piping filled with
## a swirling membrane tinted in its element's blorb colour. Passing through
## it (most of the body, from either side, walking, jumping, flying or
## swimming) swaps the whole blorb party for a complete suit of that element
## (see SuitLoadout.assemble()).
##
## The ring is deliberately not solid, per direct instruction: it is a
## threshold to pass through, not an obstacle, so it is marked decorative
## under the world collision policy.
##
## Local frame: the opening lies in the XY plane with its base on local y=0,
## and the portal is crossed along local Z. Rotate the node to aim it.

## Element of the suit this portal assembles, e.g. "water"; its body colour
## tints the membrane and ring.
@export var element: String = ""
## Core item bound into the head blorb, e.g. "Diving Helmet". Empty for none.
@export var head_item: String = ""
## Half the opening's width and height. The default admits the human with room
## to spare above the head and at the shoulders.
@export var half_width: float = 1.35
@export var half_height: float = 1.75

const TUBE_RADIUS := 0.11
const RING_SAMPLES := 96
const TUBE_SIDES := 10
## A rounder crown over a flatter, boxier base: an egg standing on its broad
## end, which also keeps the bottom pipe low enough to step over.
const EPSILON_TOP := 2.6
const EPSILON_BOTTOM := 3.6
## How far outside the opening the body's centre may cross and still count,
## as a scale of the outline. Grazing the rim still passes through.
const PASS_FORGIVENESS := 1.2
## Crossings farther apart than this in one frame are teleports, not passes.
const MAX_STEP := 3.0

const MEMBRANE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform vec4 tint : source_color;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float swirl = sin(a * 3.0 + r * 9.0 - TIME * 2.2) * 0.5 + 0.5;
	float ripple = sin(r * 16.0 - TIME * 3.0) * 0.5 + 0.5;
	float glow = mix(0.45, 1.15, swirl * 0.6 + ripple * 0.4);
	ALBEDO = tint.rgb * glow + vec3(0.1) * ripple;
	ALPHA = clamp(tint.a * (0.5 + 0.35 * swirl), 0.0, 1.0);
}
"""

var _player: Player
var _last_local := Vector3.ZERO
var _has_last := false


func _ready() -> void:
	var tint := ElementPalette.body_color(element)
	var outline := _outline()
	_build_ring(outline, tint)
	_build_membrane(outline, tint)


## The opening's outline in local space, counter-clockwise from the base:
## the super-egg's vertical cross-section, traced with SuperEgg's own surface
## function so the ring is exactly the family of shape the rest of the world
## is built from.
func _outline() -> PackedVector2Array:
	var points := PackedVector2Array()
	var semi_axes := Vector3(half_width, half_height, half_width)
	for index in RING_SAMPLES:
		var t := float(index) / float(RING_SAMPLES)
		var eta: float
		var omega: float
		if t < 0.5:
			eta = lerpf(-PI * 0.5, PI * 0.5, t * 2.0)
			omega = PI * 0.5
		else:
			eta = lerpf(PI * 0.5, -PI * 0.5, (t - 0.5) * 2.0)
			omega = -PI * 0.5
		var point := SuperEgg.surface_point(semi_axes, eta, omega, EPSILON_TOP, EPSILON_BOTTOM)
		points.append(Vector2(point.x, point.y + half_height))
	return points


## One tube swept around the outline: at each sample, a circle of TUBE_SIDES
## vertices in the plane spanned by the outline's outward normal and the
## portal's crossing axis (local Z).
func _build_ring(outline: PackedVector2Array, tint: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := outline.size()
	var rings: Array[PackedVector3Array] = []
	var normals: Array[PackedVector3Array] = []
	for index in count:
		var previous := outline[(index - 1 + count) % count]
		var following := outline[(index + 1) % count]
		var tangent := (following - previous).normalized()
		var outward := Vector3(tangent.y, -tangent.x, 0.0)
		var center := Vector3(outline[index].x, outline[index].y, 0.0)
		var ring := PackedVector3Array()
		var ring_normals := PackedVector3Array()
		for side in TUBE_SIDES:
			var angle := TAU * float(side) / float(TUBE_SIDES)
			var direction := outward * cos(angle) + Vector3.BACK * sin(angle)
			ring.append(center + direction * TUBE_RADIUS)
			ring_normals.append(direction)
		rings.append(ring)
		normals.append(ring_normals)
	for index in count:
		var next := (index + 1) % count
		for side in TUBE_SIDES:
			var side_next := (side + 1) % TUBE_SIDES
			for pair in [[index, side], [next, side], [index, side_next], [index, side_next], [next, side], [next, side_next]]:
				tool.set_normal(normals[pair[0]][pair[1]])
				tool.add_vertex(rings[pair[0]][pair[1]])
	var material := StandardMaterial3D.new()
	material.albedo_color = tint.lightened(0.25)
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.6
	material.roughness = 0.35
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tool.set_material(material)
	var ring_mesh := MeshInstance3D.new()
	ring_mesh.name = "Ring"
	ring_mesh.mesh = tool.commit()
	add_child(ring_mesh)
	CollisionPolicy.mark_decorative(ring_mesh)


## A triangle fan filling the opening. UV spans the outline's bounding box so
## the shader's swirl is centred in the opening.
func _build_membrane(outline: PackedVector2Array, tint: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2(0.0, half_height)
	var count := outline.size()
	for index in count:
		for point in [center, outline[index], outline[(index + 1) % count]]:
			var p: Vector2 = point
			tool.set_normal(Vector3.BACK)
			tool.set_uv(Vector2(p.x / half_width * 0.5 + 0.5, 0.5 - (p.y - half_height) / half_height * 0.5))
			tool.add_vertex(Vector3(p.x, p.y, 0.0))
	var shader := Shader.new()
	shader.code = MEMBRANE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tint", Color(tint.r, tint.g, tint.b, 0.55))
	tool.set_material(material)
	var membrane := MeshInstance3D.new()
	membrane.name = "Membrane"
	membrane.mesh = tool.commit()
	membrane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(membrane)
	CollisionPolicy.mark_decorative(membrane)


## Watches the body's centre of mass cross the portal plane. A crossing
## counts when the point where it crossed lies inside the opening (with
## PASS_FORGIVENESS), whichever way the body is travelling.
func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Player
		if _player == null:
			return
	# Only the human wears these suits; ignore bodies he is not controlling
	# himself (possessing Blorbus, riding Manchego, piloting Xiao Hou Zi).
	if PartyControl.active_control_body() != _player:
		_has_last = false
		return
	var local := to_local(_player.body_center())
	if _has_last and _last_local.z != 0.0 and signf(local.z) != signf(_last_local.z) and local.distance_to(_last_local) < MAX_STEP:
		var fraction := _last_local.z / (_last_local.z - local.z)
		var crossing := _last_local.lerp(local, fraction)
		if _inside_opening(Vector2(crossing.x, crossing.y)):
			_activate()
	_last_local = local
	_has_last = true


func _inside_opening(point: Vector2) -> bool:
	var above := point.y >= half_height
	var epsilon := EPSILON_TOP if above else EPSILON_BOTTOM
	var reach := pow(absf(point.x / half_width), epsilon) + pow(absf((point.y - half_height) / half_height), epsilon)
	return reach <= pow(PASS_FORGIVENESS, epsilon)


func _activate() -> void:
	# Passing back and forth through the same portal keeps the suit it gave.
	if String(_player.get_meta(&"checkpoint_suit", "")) == element:
		return
	_player.set_meta(&"checkpoint_suit", element)
	UISounds.play_foley(&"transform_reveal", 0.7, _player.get_instance_id())
	SuitLoadout.assemble(_player, element, head_item)
