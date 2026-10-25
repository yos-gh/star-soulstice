shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;
// A lightning bolt (TEMPEST): a ribbon lying just above the play plane,
// UV.y across it. A white-hot core inside a pale lilac glow; the vertex
// colour tints it and its alpha fades it out.

void fragment() {
	float d = abs(UV.y - 0.5) * 2.0;
	float glow = pow(max(1.0 - d, 0.0), 1.6);
	float core = smoothstep(0.32, 0.0, d);
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	ALBEDO = (c * glow * 2.2 + vec3(core) * 2.0) * COLOR.a;
}
