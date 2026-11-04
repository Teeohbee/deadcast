// scenes/intro/water.gdshader
// Black harbour water. Translucent so the mirrored city below shows as a
// reflection, broken up by moving swell lines.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_always;

uniform vec3 water_color : source_color = vec3(0.004, 0.006, 0.012);
uniform float base_alpha = 0.8;

varying vec3 world_position;

float hash_two(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 in_cell = fract(point);
	vec2 smooth_in_cell = in_cell * in_cell * (3.0 - 2.0 * in_cell);
	float a = hash_two(cell);
	float b = hash_two(cell + vec2(1.0, 0.0));
	float c = hash_two(cell + vec2(0.0, 1.0));
	float d = hash_two(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, smooth_in_cell.x), mix(c, d, smooth_in_cell.x), smooth_in_cell.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Swell stretched along x, so reflections break into horizontal slivers.
	vec2 swell_point = vec2(world_position.x * 0.08, world_position.z * 0.9 + TIME * 0.6);
	float swell = value_noise(swell_point) * 0.6 + value_noise(swell_point * 2.3 - TIME * 0.2) * 0.4;
	float gaps = smoothstep(0.35, 0.75, swell);
	ALBEDO = water_color;
	ALPHA = clamp(base_alpha + gaps * 0.26, 0.0, 0.98);
}
