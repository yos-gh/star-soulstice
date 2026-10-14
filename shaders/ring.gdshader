shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Planetary ring: banded, faint, additive so it never covers the stars.

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float band = smoothstep(0.52, 0.56, r) * (1.0 - smoothstep(0.94, 0.98, r));
	float stripes = 0.55 + 0.45 * sin(r * 140.0) * sin(r * 37.0 + 1.3);
	float gap = 1.0 - smoothstep(0.012, 0.0, abs(r - 0.78)) * 0.9;
	vec3 c = vec3(0.32, 0.36, 0.42) * band * stripes * gap * 0.14;
	ALBEDO = c;
}
