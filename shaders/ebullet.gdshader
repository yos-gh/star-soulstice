shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
// Enemy bullet, a flat sprite just above the play plane. It
// is cut out with an alpha scissor so it renders in the opaque pass and writes
// depth; otherwise the background depth-of-field blurs it over empty space.
// INSTANCE_CUSTOM.x = style: 0 unbreakable (warm, white-hot core, dark rim)
//                            1 breakable   (cool, dark centre, bright outline)
// INSTANCE_CUSTOM.y = length / width (1 = round, > 1 = needle).
// A needle (UV.y = 1 is its head, the way it flies) is a teardrop: a round
// head in front tapering to a point behind, its colour running from hot at
// the head to dark at the tail so you can tell which way it goes.

varying vec4 cust;

void vertex() {
	cust = INSTANCE_CUSTOM;
}

void fragment() {
	float aspect = max(cust.y, 1.0);
	vec2 d = (UV - 0.5) * 2.0;
	float r;
	float head = 0.5;  // 0 at the tail, 1 at the head
	if (aspect > 1.01) {
		float t = d.y;
		// along the needle in half-widths: the head is a circle of radius 1
		// touching the front, the tail narrows from its middle to a point
		float y = t * aspect;
		float yc = aspect - 1.0;
		if (y >= yc) {
			r = length(vec2(d.x, y - yc));
		} else {
			float w = pow(clamp((y + aspect) / (yc + aspect), 0.0, 1.0), 0.8);
			r = abs(d.x) / max(w, 0.001);
		}
		head = smoothstep(-0.9, 0.8, t);
	} else {
		r = length(d);
	}
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	vec3 col;
	if (cust.x < 0.5) {
		float core = smoothstep(0.58, 0.3, r);
		float band = smoothstep(0.74, 0.88, r);
		if (aspect > 1.01) {
			// white-hot head, the colour deepening and darkening to the tail
			vec3 body = mix(c * vec3(0.55, 0.26, 0.26), c * 1.8, head);
			col = mix(body, vec3(1.8), core * mix(0.12, 1.0, head));
		} else {
			col = mix(c * 1.7, vec3(1.7), core);
		}
		col = mix(col, c * 0.12, band);
	} else {
		float rim = smoothstep(0.42, 0.62, r) * (1.0 - smoothstep(0.8, 0.88, r));
		float lit = aspect > 1.01 ? mix(0.55, 1.2, head) : 1.0;
		col = mix(c * 0.1 + vec3(0.01, 0.015, 0.03), (c * 1.1 + vec3(0.08)) * lit, rim);
		col = mix(col, vec3(0.01, 0.02, 0.04), smoothstep(0.86, 0.94, r));
	}
	ALBEDO = col;
	ALPHA = step(r, 0.97) * COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
