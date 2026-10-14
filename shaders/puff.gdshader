shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Explosion sprite, camera-facing, alpha-blended (never additive, so it
// cannot white out the bullets). Modelled on what the reference games show:
//   fire  (DoDonPachi DaiFukkatsu-style dot work) turbulent billows with a
//         white-yellow heart, orange body and a dark red rim; it cools from
//         the outside in and tears apart. A fine pixel grain (about half a
//         voxel) keeps it in the voxel world.
//   smoke (Under Defeat / Ikaruga-style) soft translucent billows, lit from
//         the upper left (bright top, dark underside), warm-lit by the fire
//         at first, then grey; it thins as it spreads.
//   flash a short crisp four-point glint with a hot core.
//   ring  a thin shock ring that fades as it expands.
// INSTANCE_CUSTOM = (age 0..1, style, seed, palette 0 warm / 1 cool)

varying vec4 cust;
varying float world_size;

void vertex() {
	cust = INSTANCE_CUSTOM;
	float s = length(MODEL_MATRIX[0].xyz);
	world_size = s;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += noise(p) * a;
		p = p * 2.07 + vec2(3.1, 1.7);
		a *= 0.5;
	}
	return s;
}

vec3 fire_ramp(float h, float pal) {
	vec3 c0 = pal < 0.5 ? vec3(0.35, 0.05, 0.04) : vec3(0.06, 0.1, 0.35);
	vec3 c1 = pal < 0.5 ? vec3(0.78, 0.2, 0.06) : vec3(0.15, 0.35, 0.85);
	vec3 c2 = pal < 0.5 ? vec3(1.0, 0.52, 0.12) : vec3(0.35, 0.7, 1.0);
	vec3 c3 = pal < 0.5 ? vec3(1.0, 0.82, 0.35) : vec3(0.7, 0.92, 1.0);
	vec3 c4 = vec3(1.0, 0.97, 0.88);
	// stepped like hand-made dot work
	if (h > 0.82) return c4;
	if (h > 0.64) return c3;
	if (h > 0.44) return c2;
	if (h > 0.24) return c1;
	return c0;
}

void fragment() {
	float age = cust.x;
	float style = cust.y;
	float seed = cust.z;
	float pal = cust.w;
	// pixel grain: about 0.06 world units
	float px = max(6.0, floor(world_size / 0.06));
	vec2 d = UV - 0.5;
	vec2 q = (floor(d * px) + 0.5) / px;
	float r = length(q) * 2.0;
	vec2 so = vec2(seed * 31.7, seed * 17.3);
	vec3 col = vec3(1.0);
	float a = 0.0;
	if (style < 0.5) {
		// fire: billowing density, cooled from the rim inward
		float n = fbm(q * 4.2 + so + vec2(0.0, -age * 1.5));
		float dens = 1.0 - r * (0.95 + age * 0.35) + (n - 0.5) * 0.9;
		float tear = smoothstep(0.45, 1.0, age) * (0.55 + fbm(q * 7.0 + so * 1.3) * 0.6);
		dens -= tear;
		if (dens > 0.0) {
			float h = clamp(dens * 1.9 - age * 0.85 + 0.12, 0.0, 1.0);
			col = fire_ramp(h, pal);
			a = 1.0;
			// a dark rim around each billow
			if (dens < 0.07) {
				col *= 0.45;
			}
		}
	} else if (style < 1.5) {
		// smoke: lit translucent billows
		float n = fbm(q * 3.4 + so + vec2(age * 0.4, -age * 0.8));
		float dens = 1.0 - r * 1.05 + (n - 0.5) * 0.8;
		if (dens > 0.0) {
			vec3 nrm = normalize(vec3(q * 2.0, sqrt(max(0.0, 1.0 - min(r * r, 1.0))) + 0.25));
			float lit = clamp(dot(nrm, normalize(vec3(-0.55, 0.6, 0.6))), 0.0, 1.0);
			lit = floor(lit * 4.0) / 4.0;
			vec3 base = pal < 0.5 ? vec3(0.27, 0.25, 0.24) : vec3(0.22, 0.25, 0.3);
			vec3 hot = pal < 0.5 ? vec3(0.75, 0.35, 0.12) : vec3(0.25, 0.45, 0.85);
			col = mix(base * 0.4, base * 1.25, lit);
			col = mix(col, hot, (1.0 - smoothstep(0.0, 0.35, age)) * 0.6);
			a = smoothstep(0.0, 0.12, dens) * (1.0 - smoothstep(0.3, 1.0, age)) * 0.5;
		}
	} else if (style < 2.5) {
		vec2 ad = abs(q) * 2.0;
		float len = 1.0 - age * 0.7;
		float spike = max(step(ad.x, 0.06 + 0.06 * (1.0 - ad.y)) * step(ad.y, len), step(ad.y, 0.06 + 0.06 * (1.0 - ad.x)) * step(ad.x, len));
		float core = step(r, 0.38 * (1.0 - age));
		a = max(spike, core);
		col = mix(vec3(1.0, 0.97, 0.9), fire_ramp(0.7, pal), smoothstep(0.1, 0.6, r));
	} else {
		float w = mix(0.1, 0.03, age);
		float n = noise(vec2(atan(q.y, q.x) * 6.0, seed * 10.0));
		a = step(abs(r - 0.88), w) * step(n, 1.05 - age) * (1.0 - age * 0.6);
		col = fire_ramp(0.75 - age * 0.4, pal);
	}
	if (a < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = a;
}
