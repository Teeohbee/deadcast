// scenes/intro/sky.gdshader
// Storm sky over the Sump: low cloud lit teal and magenta from the city below.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.006, 0.012, 0.022);
uniform vec3 horizon_color : source_color = vec3(0.06, 0.15, 0.19);
uniform vec3 cloud_teal : source_color = vec3(0.06, 0.16, 0.2);
uniform vec3 cloud_magenta : source_color = vec3(0.2, 0.05, 0.15);

float hash_two(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 in_cell = fract(point);
	vec2 eased = in_cell * in_cell * (3.0 - 2.0 * in_cell);
	float a = hash_two(cell);
	float b = hash_two(cell + vec2(1.0, 0.0));
	float c = hash_two(cell + vec2(0.0, 1.0));
	float d = hash_two(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, eased.x), mix(c, d, eased.x), eased.y);
}

float cloud_layers(vec2 point) {
	float total = 0.0;
	float weight = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		total += value_noise(point) * weight;
		point *= 2.1;
		weight *= 0.5;
	}
	return total;
}

void sky() {
	float up = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 colour = mix(horizon_color, zenith_color, pow(up, 0.45));
	if (EYEDIR.y > 0.0) {
		// Project onto a cloud deck overhead.
		vec2 deck = EYEDIR.xz / (EYEDIR.y + 0.08) * 1.4 + vec2(TIME * 0.01, TIME * 0.004);
		float cloud = smoothstep(0.42, 0.75, cloud_layers(deck));
		float near_horizon = 1.0 - smoothstep(0.0, 0.6, up);
		vec3 lit = mix(cloud_teal, cloud_magenta, smoothstep(0.3, 0.7, value_noise(deck * 0.3)));
		colour = mix(colour, lit * (0.5 + near_horizon), cloud * 0.85);
	}
	COLOR = colour;
}
