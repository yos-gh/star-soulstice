shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Player shot: a flat, stretched glow lying on the play plane. The instance
// colour tints it; the core always burns white.

void fragment() {
	vec2 d = (UV - 0.5) * 2.0;
	float r = length(d);
	float body = pow(max(1.0 - r, 0.0), 1.4);
	float core = smoothstep(0.5, 0.0, r);
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	ALBEDO = (c * body * 2.6 + vec3(core) * 1.4) * COLOR.a;
}
