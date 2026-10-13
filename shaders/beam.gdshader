shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Ribbon for homing lasers. UV.y runs across the ribbon; vertex colour
// alpha fades the tail.

void fragment() {
	float x = abs(UV.y - 0.5) * 2.0;
	float body = pow(max(1.0 - x, 0.0), 1.6);
	float core = smoothstep(0.45, 0.0, x);
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = (c * body * 2.4 + vec3(core) * 1.1) * COLOR.a;
}
