// scenes/intro/neon_sign.gdshader
// Sign backing panel: dark glass with a glowing tube border and a flicker.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 neon_color : source_color = vec3(1.0, 0.2, 0.55);
uniform float energy = 3.0;
uniform float border = 0.06;
uniform float flicker_seed = 0.0;
uniform float flicker_amount = 0.0;

void fragment() {
	vec2 from_edge = min(UV, 1.0 - UV);
	float edge = min(from_edge.x, from_edge.y);
	float tube = smoothstep(border, border * 0.4, edge) * smoothstep(0.0, border * 0.25, edge);
	float buzz = step(0.92, fract(sin(floor(TIME * 9.0 + flicker_seed * 40.0) * 12.9898) * 43758.5453));
	float alive = 1.0 - buzz * flicker_amount;
	vec3 glass = neon_color * 0.07;
	ALBEDO = glass + neon_color * tube * energy * alive;
}
