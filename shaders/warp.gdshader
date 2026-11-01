shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Warp space (stage 5's last boss, Backdrop warp): a plane far below the
// field, over the nebula. Space bent into a funnel toward a point past the
// top of the screen (`vp`, world x/z at the plane's height): streaks of
// light run out of it down the screen, twisting, through slow coloured
// clouds; colours from the palette's nebula, brightened. It fades in with
// `amount` (0 = normal space, 1 = full warp) over the nebula; `flow` runs
// it (added up by Backdrop, so changes of speed don't jump). Dark down the
// middle where the fight is, more vivid toward the sides.

uniform float amount = 0.0;
uniform float flow = 0.0;
uniform vec2 vp = vec2(0.0, -400.0);
uniform float span = 320.0;
uniform float brightness = 1.0;
uniform vec3 base : source_color = vec3(0.01, 0.008, 0.03);
uniform vec3 col_a : source_color = vec3(0.3, 0.12, 0.5);
uniform vec3 col_b : source_color = vec3(0.08, 0.3, 0.5);
uniform vec3 col_c : source_color = vec3(0.5, 0.14, 0.3);

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
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
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

void fragment() {
	vec2 d = vec2(wpos.x - vp.x, wpos.z - vp.y);
	float r = max(length(d) / span, 0.02);
	float a = atan(d.x, d.y);
	float lr = log(r);
	// the funnel: around (u) and out of it (v), twisting and rippling
	float u = a * 7.0 + 0.9 * sin(lr * 2.3 - flow * 0.35) + 0.25 * sin(lr * 7.0 + TIME * 0.7);
	float v = lr * 3.2 - flow;
	// slow clouds of colour, drifting out with the flow
	float cl = fbm(vec2(u * 0.55, v * 0.5));
	float hue = fbm(vec2(u * 0.18 + 3.0, v * 0.12 + flow * 0.04));
	vec3 cc = mix(col_a, col_b, smoothstep(0.3, 0.7, hue));
	cc = mix(cc, col_c, smoothstep(0.55, 0.8, fbm(vec2(u * 0.3 - 5.0, v * 0.2))));
	// streaks of light out along the funnel: fine bright threads and
	// broader dim bands
	float s1 = smoothstep(0.78, 0.98, noise(vec2(u * 16.0, v * 0.22)));
	float s2 = smoothstep(0.66, 0.95, noise(vec2(u * 6.0 + 11.0, v * 0.4 - flow * 0.5)));
	float side = smoothstep(0.03, 0.45, abs(a));
	float glow = exp(-r * 2.4);
	vec3 c = base;
	c += cc * smoothstep(0.35, 0.9, cl) * 0.85;
	c += mix(cc, vec3(1.0), 0.3) * s1 * 0.4;
	c += cc * s2 * 0.4;
	c += mix(col_c, vec3(1.0), 0.2) * glow * 0.4;
	// dark down the middle, where the fight is
	c = base + (c - base) * (0.3 + 0.7 * side);
	ALBEDO = max(c, vec3(0.0)) * brightness;
	ALPHA = clamp(amount, 0.0, 1.0);
}
