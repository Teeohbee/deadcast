// scenes/intro/lamp_halo.gdshader
// Soft round glow that faces the camera, so a small lamp still reads from far off.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec3 halo_color : source_color = vec3(1.0, 0.62, 0.3);
uniform float energy = 1.4;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float distance_from_centre = length(UV - 0.5) * 2.0;
	float falloff = pow(clamp(1.0 - distance_from_centre, 0.0, 1.0), 2.5);
	ALBEDO = halo_color * falloff * energy;
}
