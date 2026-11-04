// scenes/intro/sky.gdshader
// Smog sky: black overhead, bruised magenta where the city lights it.
shader_type sky;

uniform vec3 zenith_color : source_color = vec3(0.004, 0.004, 0.012);
uniform vec3 smog_color : source_color = vec3(0.3, 0.06, 0.22);
uniform vec3 cyan_haze : source_color = vec3(0.02, 0.07, 0.1);

void sky() {
	float up = clamp(EYEDIR.y, 0.0, 1.0);
	float horizon = pow(1.0 - up, 4.0);
	float side = smoothstep(-0.6, 0.6, EYEDIR.x);
	vec3 haze = mix(smog_color, cyan_haze, side * 0.6);
	COLOR = mix(zenith_color, haze, horizon);
}
