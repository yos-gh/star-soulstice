shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled;
// Deep-space backdrop far below the play field: dim nebula clouds that
// drift with the scroll. Kept dark and low-contrast so units read on top.

uniform float scroll = 0.0;
uniform float brightness = 1.0;
uniform vec3 base : source_color = vec3(0.01, 0.012, 0.03);
uniform vec3 neb_a : source_color = vec3(0.16, 0.07, 0.3);
uniform vec3 neb_b : source_color = vec3(0.04, 0.16, 0.3);
uniform vec3 neb_c : source_color = vec3(0.32, 0.08, 0.16);

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
	for (int i = 0; i < 5; i++) {
		s += noise(p) * a;
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return s;
}

void fragment() {
	vec2 p = UV * vec2(5.0, 5.0) - vec2(0.0, scroll);
	float n = fbm(p);
	float m = fbm(p * 1.7 + vec2(4.0, 1.0));
	float k = fbm(p * 0.6 + vec2(-3.0, 2.0));
	vec3 c = base;
	c += neb_a * smoothstep(0.42, 0.85, n);
	c += neb_b * smoothstep(0.5, 0.9, m) * 0.8;
	c += neb_c * smoothstep(0.55, 0.85, k) * smoothstep(0.4, 0.7, n) * 0.9;
	float dust = smoothstep(0.6, 0.75, fbm(p * 3.0 + 11.0)) * 0.05;
	c -= dust;
	ALBEDO = max(c, vec3(0.0)) * brightness;
}
