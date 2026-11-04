// scenes/intro/trail.gdshader
// Light trail behind a flying car: bright at the car, fading to nothing.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 trail_color : source_color = vec3(0.6, 0.9, 1.0);
uniform float energy = 1.5;

void fragment() {
	float along = UV.x;  // 1 at the car
	float across = 1.0 - abs(UV.y - 0.5) * 2.0;
	ALBEDO = trail_color * energy * pow(along, 2.0) * across;
}
