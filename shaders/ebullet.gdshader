shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
// Enemy bullet, a flat sprite just above the play plane. It
// is cut out with an alpha scissor so it renders in the opaque pass and writes
// depth; otherwise the background depth-of-field blurs it over empty space.
// INSTANCE_CUSTOM.x = style: 0 unbreakable (warm, white-hot core, dark rim)
//                            1 breakable   (cool, dark centre, bright outline)
//                            2 iron (shaded steel ball, lit rim, hot core)
// INSTANCE_CUSTOM.y = length / width (1 = round, > 1 = needle/capsule).
// A needle's colour shifts a little from head (UV.y = 1, the way it flies)
// to tail: brighter and hotter in front, a little deeper behind.

varying vec4 cust;

void vertex() {
	cust = INSTANCE_CUSTOM;
}

void fragment() {
	float aspect = max(cust.y, 1.0);
	vec2 d = (UV - 0.5) * 2.0;
	vec2 q = vec2(d.x, d.y * aspect);
	float r = length(vec2(q.x, max(abs(q.y) - (aspect - 1.0), 0.0)));
	// 0 at the tail, 1 at the head (0.5 all over a round bullet)
	float head = aspect > 1.01 ? smoothstep(-0.9, 0.9, d.y) : 0.5;
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	vec3 col;
	if (cust.x < 0.5) {
		float core = smoothstep(0.58, 0.3, r);
		float band = smoothstep(0.74, 0.88, r);
		vec3 body = c * 1.7;
		if (aspect > 1.01) {
			body = mix(c * vec3(1.35, 0.95, 0.9), c * 1.9, head);
			core *= mix(0.8, 1.0, head);
		}
		col = mix(body, vec3(1.7), core);
		col = mix(col, c * 0.12, band);
	} else if (cust.x > 1.5) {
		// IRON: a shaded steel ball with a lit rim and a hot core
		float z = sqrt(max(1.0 - r * r, 0.0));
		float lit = clamp(dot(normalize(vec3(d.x, -d.y, z)), normalize(vec3(-0.5, 0.6, 0.65))), 0.0, 1.0);
		col = mix(vec3(0.03, 0.025, 0.05), c * 0.55, lit);
		float rim = smoothstep(0.66, 0.74, r) * (1.0 - smoothstep(0.84, 0.9, r));
		col = mix(col, c * 1.6, rim);
		float core = smoothstep(0.3, 0.12, r);
		col = mix(col, c * 2.2 + vec3(0.3), core);
		col = mix(col, vec3(0.02, 0.01, 0.04), smoothstep(0.9, 0.96, r));
	} else {
		float rim = smoothstep(0.42, 0.62, r) * (1.0 - smoothstep(0.8, 0.88, r));
		float lit = aspect > 1.01 ? mix(0.8, 1.15, head) : 1.0;
		col = mix(c * 0.1 + vec3(0.01, 0.015, 0.03), (c * 1.1 + vec3(0.08)) * lit, rim);
		col = mix(col, vec3(0.01, 0.02, 0.04), smoothstep(0.86, 0.94, r));
	}
	ALBEDO = col;
	ALPHA = step(r, 0.97) * COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
