shader_type spatial;
render_mode diffuse_lambert, specular_disabled, fog_disabled, shadows_disabled;
// The rocky planet of stage 5 seen from above as the ship climbs away
// (Backdrop "globe"): grey-brown dust with darker plains and rust patches,
// craters at two sizes (dark floors, pale rims), lit by the sun, a faint
// pale rim at the limb so its edge reads against space. Dimmed and hazed
// like the ground (it is scenery under the sections and units).

uniform vec3 dust : source_color = vec3(0.29, 0.27, 0.25);
uniform vec3 dark : source_color = vec3(0.19, 0.18, 0.18);
uniform vec3 rust : source_color = vec3(0.33, 0.24, 0.19);
uniform vec3 rim_col : source_color = vec3(0.55, 0.5, 0.45);
uniform vec3 haze : source_color = vec3(0.03, 0.045, 0.07);
uniform float dim = 0.72;

varying vec3 lp;

vec3 hash3(vec3 p) {
	p = fract(p * vec3(0.1031, 0.1030, 0.0973));
	p += dot(p, p.yxz + 33.33);
	return fract((p.xxy + p.yxx) * p.zyx);
}

float noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	float a = hash3(i).x;
	float b = hash3(i + vec3(1, 0, 0)).x;
	float c = hash3(i + vec3(0, 1, 0)).x;
	float d = hash3(i + vec3(1, 1, 0)).x;
	float e = hash3(i + vec3(0, 0, 1)).x;
	float f2 = hash3(i + vec3(1, 0, 1)).x;
	float g = hash3(i + vec3(0, 1, 1)).x;
	float h = hash3(i + vec3(1, 1, 1)).x;
	return mix(mix(mix(a, b, u.x), mix(c, d, u.x), u.y), mix(mix(e, f2, u.x), mix(g, h, u.x), u.y), u.z);
}

float fbm(vec3 p) {
	return noise(p) * 0.55 + noise(p * 2.1) * 0.28 + noise(p * 4.3) * 0.17;
}

// Craters on cells of size 1 at p: x = how dark (the floor), y = how pale
// (the rim), z = the slope toward the light (fake relief).
vec3 craters(vec3 p) {
	vec3 ip = floor(p);
	vec3 res = vec3(0.0);
	for (int k = 0; k < 27; k++) {
		vec3 o = vec3(float(k % 3), float((k / 3) % 3), float(k / 9)) - 1.0;
		vec3 h = hash3(ip + o);
		if (h.z < 0.35) {
			continue;
		}
		vec3 c = ip + o + 0.2 + h * 0.6;
		float r = 0.18 + 0.3 * h.y;
		float d = length(p - c) / r;
		if (d < 1.25) {
			res.x = max(res.x, smoothstep(1.0, 0.55, d) * 0.8);
			res.y = max(res.y, smoothstep(0.82, 1.0, d) * smoothstep(1.25, 1.0, d));
			res.z += (p - c).y / r * step(d, 1.0);
		}
	}
	return res;
}

void vertex() {
	lp = normalize(VERTEX);
}

void fragment() {
	vec3 q = lp * 6.0;
	float m = fbm(q * 1.3);
	vec3 c = mix(dust, dark, smoothstep(0.45, 0.68, m));
	c = mix(c, rust, smoothstep(0.55, 0.8, fbm(q * 0.7 + 7.0)) * 0.6);
	c *= 0.9 + 0.2 * noise(lp * 140.0);
	vec3 big = craters(lp * 9.0);
	vec3 small = craters(lp * 27.0);
	c = mix(c, dark * 0.85, big.x * 0.7);
	c = mix(c, c * 1.35, big.y * 0.8);
	c = mix(c, dark, small.x * 0.5);
	c = mix(c, c * 1.25, small.y * 0.6);
	c *= 1.0 - 0.12 * clamp(big.z + small.z * 0.5, -1.0, 1.0);
	// the ground's soft look: dimmer, a little haze
	c = mix(c * dim, haze, 0.2);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = rim_col * fres * 0.25;
}
