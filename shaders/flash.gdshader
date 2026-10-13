shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, shadows_disabled, fog_disabled;
// Overlay drawn over a unit's own surfaces: hit flash and warning tints.

uniform vec4 col : source_color = vec4(1.0, 0.9, 0.8, 1.0);

void fragment() {
	ALBEDO = col.rgb;
}
