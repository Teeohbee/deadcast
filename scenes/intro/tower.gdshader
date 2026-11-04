// scenes/intro/tower.gdshader
// Tower body with procedural windows. Each tower picks its own window
// pattern from its origin, so one material serves the whole city.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 body_color : source_color = vec3(0.01, 0.016, 0.026);
// Street-level neon lighting the bottom of every tower from the water.
uniform vec3 street_glow_teal : source_color = vec3(0.04, 0.26, 0.3);
uniform vec3 street_glow_magenta : source_color = vec3(0.3, 0.05, 0.22);
uniform float lit_ratio = 0.09;
uniform float window_energy = 1.4;
uniform vec2 window_cell = vec2(1.7, 3.2);
// Below this height the floors are flooded and dark.
uniform float flood_line = 0.0;

varying vec3 world_position;
varying vec3 world_normal;
varying float tower_seed;

float hash_two(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 origin = MODEL_MATRIX[3].xyz;
	tower_seed = hash_two(origin.xz * 0.37);
}

void fragment() {
	bool is_wall = abs(world_normal.y) < 0.5;
	float height = abs(world_position.y);
	// Side faces darker than front faces so towers separate from each other.
	float face_shade = abs(world_normal.x) > 0.5 ? 0.55 : 1.0;
	vec3 colour = body_color * face_shade;
	vec3 street_glow = tower_seed > 0.35 ? street_glow_teal : street_glow_magenta;
	colour += street_glow * exp(-height / 28.0) * face_shade;
	if (is_wall) {
		float along_face = abs(world_normal.x) > 0.5 ? world_position.z : world_position.x;
		vec2 cell = vec2(along_face, height) / window_cell;
		vec2 cell_id = floor(cell);
		vec2 in_cell = fract(cell);
		float window_shape = step(0.18, in_cell.x) * step(in_cell.x, 0.82)
			* step(0.28, in_cell.y) * step(in_cell.y, 0.72);
		float roll = hash_two(cell_id + tower_seed * 91.0);
		// Whole floors go dark or light together now and then.
		float floor_roll = hash_two(vec2(cell_id.y, tower_seed * 53.0));
		float ratio = lit_ratio * (floor_roll > 0.85 ? 3.0 : (floor_roll < 0.3 ? 0.3 : 1.0));
		float lit = step(1.0 - ratio, roll);
		float tint_roll = hash_two(cell_id * 1.7 + tower_seed * 13.0);
		vec3 tint = vec3(1.0, 0.62, 0.28);              // sodium
		if (tint_roll > 0.55) tint = vec3(0.85, 0.9, 1.0);   // cold office white
		if (tint_roll > 0.82) tint = vec3(0.2, 0.8, 1.0);    // cyan
		if (tint_roll > 0.94) tint = vec3(1.0, 0.25, 0.6);   // magenta
		// Distant windows shrink below a pixel; fade them to an even glow.
		float blur = clamp(fwidth(cell.x) * 1.5, 0.0, 1.0);
		float window_amount = mix(window_shape * lit, ratio * 0.36, blur);
		colour += tint * window_amount * window_energy;
		// A thin neon trim band on some towers.
		float band_period = 18.0 + tower_seed * 30.0;
		float band = step(0.62, tower_seed) * smoothstep(0.35, 0.0, abs(mod(height, band_period) - band_period * 0.5));
		vec3 band_tint = tower_seed > 0.8 ? vec3(0.1, 0.9, 1.0) : vec3(1.0, 0.15, 0.55);
		colour += band_tint * band * 2.2;
	}
	ALBEDO = colour;
}
