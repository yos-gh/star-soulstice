shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Ribbon for homing lasers: a thin white-hot core inside a narrow cyan
// sheath. UV.y runs across the ribbon; vertex colour alpha fades the tail.

void fragment() {
	float x = abs(UV.y - 0.5) * 2.0;
	float body = pow(max(1.0 - x, 0.0), 2.6);
	float core = smoothstep(0.32, 0.0, x);
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	ALBEDO = (c * body * 2.6 + vec3(core) * 1.6) * COLOR.a;
}
