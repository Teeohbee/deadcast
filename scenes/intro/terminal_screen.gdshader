// scenes/intro/terminal_screen.gdshader
// Stand-in for the deck terminal's screen: rows of green text, a blinking
// cursor and scanlines. The real title screen replaces it in a later PR.
shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec3 phosphor : source_color = vec3(0.13, 0.9, 0.4);
uniform float energy = 2.4;
const float ROWS = 14.0;

float hash_one(float value) {
	return fract(sin(value * 127.1) * 43758.5453);
}

void fragment() {
	vec2 point = vec2(UV.x, UV.y);
	float row = floor(point.y * ROWS);
	float in_row = fract(point.y * ROWS);
	// Lines scroll up slowly as if the log is printing.
	float scrolled_row = row + floor(TIME * 1.5);
	float line_length = 0.2 + 0.7 * hash_one(scrolled_row);
	float text = step(0.08, point.x) * step(point.x, line_length) * step(0.3, in_row) * step(in_row, 0.75);
	// Break each line into word-like chunks.
	text *= step(0.25, hash_one(floor(point.x * 40.0) + scrolled_row * 13.0));
	float cursor = step(row, ROWS - 1.0) * step(ROWS - 2.0, row) * step(0.08, point.x) * step(point.x, 0.12) * step(0.5, fract(TIME * 1.2));
	float scanline = 0.75 + 0.25 * step(0.5, fract(point.y * 120.0));
	vec3 background = phosphor * 0.06;
	ALBEDO = (background + phosphor * max(text * 0.8, cursor)) * scanline * energy;
}
