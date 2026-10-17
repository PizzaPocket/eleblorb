shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.18, 0.47, 0.47, 0.88);
uniform vec4 deep_color : source_color = vec4(0.035, 0.24, 0.32, 0.88);
uniform float ripple_scale = 0.42;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += sin(world_position.x * 0.38 + TIME * 0.9) * 0.035;
	VERTEX.y += cos(world_position.z * 0.51 - TIME * 0.72) * 0.028;
}

void fragment() {
	float ripple = sin(world_position.x * ripple_scale + TIME * 0.8)
		* cos(world_position.z * ripple_scale * 1.3 - TIME * 0.65);
	float light = clamp(0.52 + ripple * 0.12, 0.0, 1.0);
	ALBEDO = mix(deep_color.rgb, shallow_color.rgb, light);
	ROUGHNESS = 0.18;
	METALLIC = 0.08;
	SPECULAR = 0.8;
	ALPHA = shallow_color.a;
}
