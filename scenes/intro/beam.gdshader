// scenes/intro/beam.gdshader
// Searchlight cone through smog: brightest at the lamp, fading up the beam.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec3 beam_color : source_color = vec3(0.7, 0.8, 1.0);
uniform float energy = 0.9;

void fragment() {
	float along = UV.y;  // 0 at the wide top, 1 at the lamp
	float fade = pow(along, 2.2);
	float rim = 1.0 - abs(dot(NORMAL, VIEW));
	ALBEDO = beam_color * energy * fade * (0.35 + rim);
}
