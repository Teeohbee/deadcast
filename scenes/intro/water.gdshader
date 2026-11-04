// scenes/intro/water.gdshader
// Choppy harbour water. The waves come from the script (wave_settings) so the
// boat can ride the same swell. City light shows as coloured glints where a
// wave tilts towards the skyline; the Meridian's green windows smear across
// the water towards the camera.
shader_type spatial;
render_mode unshaded, cull_disabled;

const int WAVE_COUNT = 4;
const float GRAVITY = 9.8;

// Each wave: x, y = direction (normalised), z = wavelength, w = height.
uniform vec4 wave_settings[WAVE_COUNT];
uniform float wave_time = 0.0;
// Waves die away with distance from here, so the far water stays flat.
uniform vec2 calm_centre = vec2(0.0, 0.0);
uniform float calm_start = 180.0;
uniform float calm_end = 420.0;

uniform vec3 deep_color : source_color = vec3(0.006, 0.014, 0.02);
uniform vec3 sky_color : source_color = vec3(0.05, 0.12, 0.15);
uniform vec3 foam_color : source_color = vec3(0.32, 0.4, 0.44);
uniform vec3 boat_glow_position = vec3(0.0);
uniform vec3 boat_glow_color : source_color = vec3(0.13, 0.9, 0.4);

varying vec3 world_position;
varying float crest;
varying float wave_fade;

float hash_one(float value) {
	return fract(sin(value * 127.1) * 43758.5453);
}

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

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wave_fade = 1.0 - smoothstep(calm_start, calm_end, distance(world_position.xz, calm_centre));
	float height = 0.0;
	vec2 slope = vec2(0.0);
	float tallest = 0.0;
	for (int index = 0; index < WAVE_COUNT; index++) {
		vec4 wave = wave_settings[index];
		float wave_number = 6.28318 / wave.z;
		float speed = sqrt(GRAVITY / wave_number);
		float phase = wave_number * (dot(wave.xy, world_position.xz) - speed * wave_time);
		height += wave.w * sin(phase);
		slope += wave.w * wave_number * cos(phase) * wave.xy;
		tallest += wave.w;
	}
	height *= wave_fade;
	slope *= wave_fade;
	crest = tallest > 0.0 ? height / tallest : 0.0;
	VERTEX.y += height;
	world_position.y += height;
	NORMAL = normalize(vec3(-slope.x, 1.0, -slope.y));
}

void fragment() {
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 world_view = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	float facing = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - facing, 4.0);
	vec3 colour = mix(deep_color, sky_color, fresnel);

	// Glints: where the reflected ray skims the horizon towards the city,
	// pick a neon colour from a column of the skyline.
	vec3 reflected = reflect(-world_view, world_normal);
	float towards_city = smoothstep(0.0, 0.4, -reflected.z);
	float skims_horizon = smoothstep(0.12, 0.0, abs(reflected.y - 0.05));
	// Glints belong to the far water; up close the waves stay dark.
	float far_away = smoothstep(40.0, 260.0, distance(world_position, CAMERA_POSITION_WORLD));
	float column = floor((reflected.x / max(-reflected.z, 0.1)) * 60.0);
	float column_roll = hash_one(column);
	vec3 neon = vec3(0.1, 0.85, 1.0);
	if (column_roll > 0.45) neon = vec3(1.0, 0.2, 0.55);
	if (column_roll > 0.7) neon = vec3(1.0, 0.65, 0.2);
	if (column_roll > 0.88) neon = vec3(0.3, 1.0, 0.5);
	float lit_column = step(0.6, hash_one(column + 17.0));
	colour += neon * towards_city * skims_horizon * lit_column * (0.08 + 0.3 * far_away);

	// Whitecaps on the crests, broken up by noise.
	vec2 foam_point = vec2(world_position.x * 1.4, world_position.z * 0.7) + wave_time * 0.3;
	float foam_noise = value_noise(foam_point) * 0.6 + value_noise(foam_point * 2.7) * 0.4;
	float foam = smoothstep(0.62, 0.9, crest * 0.7 + foam_noise * 0.45) * wave_fade;
	colour = mix(colour, foam_color, foam * 0.55);

	// The green windows' reflection, stretched towards the camera.
	vec2 from_boat = world_position.xz - boat_glow_position.xz;
	float across = exp(-abs(from_boat.x) / 2.2);
	float along = smoothstep(-4.0, 2.0, from_boat.y) * exp(-max(from_boat.y, 0.0) / 22.0);
	float shimmer = 0.4 + 0.6 * value_noise(vec2(world_position.x * 0.8, world_position.z * 3.0 - wave_time * 2.0));
	colour += boat_glow_color * across * along * shimmer * (0.4 + fresnel) * 1.4;

	ALBEDO = colour;
}
