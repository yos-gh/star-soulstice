shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
// Enemy bullet, a flat sprite just above the play plane. It
// is cut out with an alpha scissor so it renders in the opaque pass and writes
// depth; otherwise the background depth-of-field blurs it over empty space.
// INSTANCE_CUSTOM.x = style: 0 unbreakable (warm, white-hot core, dark rim)
//                            1 breakable   (cool, dark centre, bright outline)
// INSTANCE_CUSTOM.y = length / width (1 = round, > 1 = needle/capsule).

varying vec4 cust;

void vertex() {
	cust = INSTANCE_CUSTOM;
}

void fragment() {
	float aspect = max(cust.y, 1.0);
	vec2 d = (UV - 0.5) * 2.0;
	vec2 q = vec2(d.x, d.y * aspect);
	float r = length(vec2(q.x, max(abs(q.y) - (aspect - 1.0), 0.0)));
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	vec3 col;
	if (cust.x < 0.5) {
		float core = smoothstep(0.58, 0.3, r);
		float band = smoothstep(0.74, 0.88, r);
		col = mix(c * 1.7, vec3(1.7), core);
		col = mix(col, c * 0.12, band);
	} else {
		float rim = smoothstep(0.42, 0.62, r) * (1.0 - smoothstep(0.8, 0.88, r));
		col = mix(c * 0.1 + vec3(0.01, 0.015, 0.03), c * 1.1 + vec3(0.08), rim);
		col = mix(col, vec3(0.01, 0.02, 0.04), smoothstep(0.86, 0.94, r));
	}
	ALBEDO = col;
	ALPHA = step(r, 0.97) * COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
