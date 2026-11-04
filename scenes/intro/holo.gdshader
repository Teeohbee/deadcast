// scenes/intro/holo.gdshader
// Holographic billboard: scrolling colour bands, scanlines, a soft edge.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 colour_a : source_color = vec3(0.1, 0.8, 1.0);
uniform vec3 colour_b : source_color = vec3(1.0, 0.2, 0.6);
uniform float energy = 1.2;
uniform float scroll_speed = 0.15;

void fragment() {
	float bands = 0.5 + 0.5 * sin((UV.y + TIME * scroll_speed) * 18.0);
	vec3 colour = mix(colour_a, colour_b, smoothstep(0.2, 0.8, UV.x + 0.2 * sin(TIME * 0.7 + UV.y * 4.0)));
	float scan = 0.7 + 0.3 * step(0.5, fract(UV.y * 90.0));
	vec2 from_edge = min(UV, 1.0 - UV);
	float soft = smoothstep(0.0, 0.08, min(from_edge.x, from_edge.y));
	float glitch = step(0.97, fract(sin(floor(TIME * 6.0) * 78.233) * 43758.5453));
	ALBEDO = colour * (0.35 + 0.65 * bands) * scan * soft * energy * (1.0 - glitch * 0.6);
}
