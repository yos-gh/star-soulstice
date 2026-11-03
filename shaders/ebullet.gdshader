shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
// Enemy bullet, a flat sprite just above the play plane. It
// is cut out with an alpha scissor so it renders in the opaque pass and writes
// depth; otherwise the background depth-of-field blurs it over empty space.
// INSTANCE_CUSTOM.x = style: 0 unbreakable (warm, white-hot core, dark rim)
//                            1 breakable   (cool, dark centre, bright outline)
//                            2 iron (shaded steel: a ball, or a long slug)
// INSTANCE_CUSTOM.y = length / width (1 = round, > 1 = needle/capsule).
// INSTANCE_CUSTOM.z = fuse (0 none; how far it has burned toward its burst):
//   hot seams in a cross and a ring that blink faster as it burns down.
// INSTANCE_CUSTOM.w = 1: tethered (it will come back): a hollow ring with a
//   bright bead in the middle.
// An unbreakable needle keeps the round bullet's coloured outline all
// along; inside, its head (UV.y = 1, the way it flies) glows white-hot like
// a round one and the glow fades through the bullet colour to dark at the
// tail. A breakable needle is only a little brighter at the head.

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
		col = mix(body, vec3(1.7), core);
		if (aspect > 1.01) {
			// outline all along, the inside white-hot at the head, dark at the tail
			float inner = smoothstep(0.62, 0.48, r);
			vec3 inside = mix(c * 0.14, c * 1.6, smoothstep(0.05, 0.55, head));
			inside = mix(inside, vec3(1.7), smoothstep(0.55, 0.92, head));
			col = mix(body, inside, inner);
		}
		col = mix(col, c * 0.12, band);
	} else if (cust.x > 1.5) {
		// IRON: shaded steel with a lit rim and a hot core; a slug is a
		// capsule, its hot core drawn out toward the head
		vec2 qq = vec2(q.x, sign(q.y) * max(abs(q.y) - (aspect - 1.0), 0.0));
		float z = sqrt(max(1.0 - r * r, 0.0));
		float lit = clamp(dot(normalize(vec3(qq.x, -qq.y, z)), normalize(vec3(-0.5, 0.6, 0.65))), 0.0, 1.0);
		col = mix(vec3(0.03, 0.025, 0.05), c * 0.55, lit);
		float rim = smoothstep(0.66, 0.74, r) * (1.0 - smoothstep(0.84, 0.9, r));
		col = mix(col, c * 1.6, rim);
		float core = smoothstep(0.3, 0.12, r);
		if (aspect > 1.01) {
			// a slug: a hot stripe down its middle, white at the nose
			core = smoothstep(0.32, 0.1, abs(q.x)) * smoothstep(-0.6, 0.7, d.y) * step(r, 0.7);
			col = mix(col, c * 0.8, smoothstep(0.2, -0.8, d.y) * 0.5);
		}
		col = mix(col, c * 2.2 + vec3(0.3), core);
		col = mix(col, vec3(0.02, 0.01, 0.04), smoothstep(0.9, 0.96, r));
	} else {
		float rim = smoothstep(0.42, 0.62, r) * (1.0 - smoothstep(0.8, 0.88, r));
		float lit = aspect > 1.01 ? mix(0.8, 1.15, head) : 1.0;
		col = mix(c * 0.1 + vec3(0.01, 0.015, 0.03), (c * 1.1 + vec3(0.08)) * lit, rim);
		col = mix(col, vec3(0.01, 0.02, 0.04), smoothstep(0.86, 0.94, r));
	}
	if (cust.z > 0.0) {
		// the fuse: blinking ever faster as it burns down to the burst
		float rate = mix(2.5, 11.0, cust.z * cust.z);
		float on = 0.35 + 0.65 * step(0.5, fract(TIME * rate));
		float seam = max(smoothstep(0.13, 0.06, abs(d.x - d.y) * 0.7071), smoothstep(0.13, 0.06, abs(d.x + d.y) * 0.7071));
		seam *= smoothstep(0.84, 0.7, r) * step(0.2, r);
		float band = smoothstep(0.08, 0.02, abs(r - 0.52));
		vec3 hot = vec3(2.0, 1.35, 0.55);
		// a dark casing (whatever the kind) so the hot seams stand out on it
		col = mix(col, c * 0.16 + vec3(0.02), 0.8 * smoothstep(0.9, 0.8, r));
		col = mix(col, hot, max(seam, band) * on);
		col = mix(col, hot * 1.2, smoothstep(0.2, 0.08, r) * on);
	}
	float hole = 1.0;
	if (cust.w > 0.5) {
		// tethered: a ring with a bead in it
		hole = max(step(0.46, r), step(r, 0.17));
		col = mix(col, c * 2.0 + vec3(0.35), smoothstep(0.17, 0.08, r));
	}
	ALBEDO = col;
	ALPHA = step(r, 0.97) * hole * COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
