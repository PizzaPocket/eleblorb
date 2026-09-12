shader_type spatial;

// Deliberately avoids screen/depth texture reads: this surface must remain
// inexpensive and predictable in the WebGL/mobile compatibility renderer.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 surface_color : source_color = vec4(0.11, 0.48, 0.58, 0.76);
uniform vec4 underside_color : source_color = vec4(0.19, 0.66, 0.72, 0.88);
uniform vec4 underside_glow : source_color = vec4(0.10, 0.40, 0.46, 1.0);
varying vec2 world_xz;

void vertex() {
	world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	// World-space wavelengths stay stable even though the visual ocean plane
	// extends far beyond the playable terrain to hide its horizon boundary.
	float broad_wave = sin(world_xz.x * 0.024 + TIME * 0.48)
		* cos(world_xz.y * 0.019 - TIME * 0.39);
	float fine_wave = sin((world_xz.x + world_xz.y) * 0.061 + TIME * 0.72) * 0.5;
	float ripple = broad_wave * 0.65 + fine_wave * 0.35;
	float grazing = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.2);

	if (FRONT_FACING) {
		ALBEDO = surface_color.rgb + ripple * 0.018;
		EMISSION = surface_color.rgb * (0.10 + ripple * 0.018);
		ALPHA = clamp(surface_color.a + grazing * 0.10, 0.0, 0.92);
		ROUGHNESS = 0.16;
		METALLIC = 0.14;
	} else {
		// From below, the surface reads as a bright rippling ceiling: clearer
		// overhead, increasingly reflective/opaque toward the horizon.
		vec3 ceiling = underside_color.rgb + ripple * vec3(0.035, 0.055, 0.060);
		ALBEDO = ceiling;
		EMISSION = underside_glow.rgb * (0.22 + grazing * 0.24 + ripple * 0.035);
		ALPHA = clamp(0.48 + grazing * 0.42 + ripple * 0.025, 0.40, 0.94);
		ROUGHNESS = mix(0.24, 0.10, grazing);
		METALLIC = 0.08;
	}
}
