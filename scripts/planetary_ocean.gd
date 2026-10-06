extends MeshInstance3D
class_name PlanetaryOcean

## Shared, purely visual planetary sea beneath every world. One low-detail
## sphere produces the curved horizon from ordinary play and the blue planet
## silhouette from high-altitude flight, for one draw call and no physics.

const DEFAULT_RADIUS := 120000.0
const DEFAULT_SEGMENTS := 128
const DEFAULT_RINGS := 64

@export var surface_level := -25.0
@export var planet_center := Vector2.ZERO
@export var planet_radius := DEFAULT_RADIUS
@export var radial_segments := DEFAULT_SEGMENTS
@export var rings := DEFAULT_RINGS
@export var hole_enabled := false
@export var hole_from := Vector2.ZERO
@export var hole_to := Vector2.ZERO
@export var hole_radius := 0.0


func _ready() -> void:
	name = "SphericalWorldOcean"
	var sphere := SphereMesh.new()
	sphere.radius = planet_radius
	sphere.height = planet_radius * 2.0
	sphere.radial_segments = radial_segments
	sphere.rings = rings
	mesh = sphere
	material_override = _build_material()
	position = Vector3(planet_center.x, surface_level - planet_radius, planet_center.y)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	extra_cull_margin = planet_radius * 2.0
	CollisionPolicy.mark_decorative(self)


func configure_hole(from: Vector2, to: Vector2, radius: float) -> void:
	hole_enabled = true
	hole_from = from
	hole_to = to
	hole_radius = radius


func _build_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_back, depth_draw_opaque, fog_disabled;
uniform bool hole_enabled = false;
uniform vec2 hole_from;
uniform vec2 hole_to;
uniform float hole_radius;
void fragment() {
	vec3 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 here = vec2(world.x, world.z);
	vec2 span = hole_to - hole_from;
	float along = clamp(dot(here - hole_from, span) / max(dot(span, span), 0.0001), 0.0, 1.0);
	if (hole_enabled && distance(here, hole_from + span * along) < hole_radius) {
		discard;
	}
	vec3 deep_blue = vec3(0.055, 0.31, 0.53);
	vec3 sky_blue = vec3(0.16, 0.52, 0.72);
	float fresnel = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.0);
	ALBEDO = mix(deep_blue, sky_blue, 0.28 + fresnel * 0.45);
	ROUGHNESS = 0.28;
	METALLIC = 0.05;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("hole_enabled", hole_enabled)
	material.set_shader_parameter("hole_from", hole_from)
	material.set_shader_parameter("hole_to", hole_to)
	material.set_shader_parameter("hole_radius", hole_radius)
	return material
