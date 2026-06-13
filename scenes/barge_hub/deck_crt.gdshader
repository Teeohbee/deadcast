// scenes/barge_hub/deck_crt.gdshader
shader_type canvas_item;

uniform float scan_alpha : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	float line = step(0.5, fract(FRAGCOORD.y / 4.0));
	float flicker = 0.99 + 0.01 * sin(TIME * 12.0);
	COLOR = vec4(0.0, 0.0, 0.0, scan_alpha * line * flicker);
}
