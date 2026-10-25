shader_type spatial;
render_mode unshaded, fog_disabled, shadows_disabled, cull_disabled, depth_draw_never;
// The enemy planet below as stage 4 dives into it (Backdrop "sky"), on a
// plane far under the ground. `level` is how far down it is: 0 still in
// space (the plane is see-through), then the haze of the upper atmosphere
// over a sea of cloud tops far below; from about 0.7 the cloud deck breaks
// up over the dark surface (a grid of roads with dim lights), at 1.4 low
// over it. The features grow as it comes down (`zoom`, the scroll offset
// `off` is summed on the CPU so a change of zoom never jumps). Kept dim and
// low in contrast: it is scenery under the bullets.

uniform float level = 0.0;
uniform float zoom = 1.0;
uniform vec2 off = vec2(0.0);
uniform float size = 900.0;  // the plane's size (world units)
uniform float cell = 26.0;  // world units per noise cell at zoom 1
uniform vec3 haze : source_color = vec3(0.07, 0.06, 0.11);
uniform vec3 cloud_hi : source_color = vec3(0.3, 0.28, 0.36);
uniform vec3 cloud_lo : source_color = vec3(0.1, 0.09, 0.14);
uniform vec3 ground : source_color = vec3(0.04, 0.05, 0.06);
uniform vec3 lights : source_color = vec3(0.3, 0.55, 0.4);
uniform float brightness = 1.0;

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
	vec2 w = (UV - 0.5) * size;
	vec2 q = w / (cell * zoom) + off;
	// the surface: dark land, a grid of roads in the built-up parts, dim
	// lights at the crossings
	vec2 g = q * 0.9;
	float land = fbm(g * 0.35 + vec2(7.0, 3.0));
	vec3 surf = ground * (0.55 + 0.9 * land);
	float town = smoothstep(0.48, 0.6, fbm(g * 0.18 + vec2(-4.0, 2.0)));
	vec2 gc = fract(g * 1.4);
	float road = max(1.0 - smoothstep(0.0, 0.07, gc.x), 1.0 - smoothstep(0.0, 0.07, gc.y));
	surf = mix(surf, surf * 1.7 + ground * 0.3, road * town * 0.8);
	vec2 cr = floor(g * 1.4);
	float lamp = step(0.72, hash(cr)) * (1.0 - smoothstep(0.0, 0.12, length(gc - vec2(0.04))));
	surf += lights * lamp * town * 0.8;
	// the cloud deck: full cover high up, breaking up below level 0.7
	float n = fbm(q);
	float th = mix(0.0, 0.6, smoothstep(0.62, 1.25, level));
	float cl = smoothstep(th - 0.05, th + 0.07, n);
	// cloud tops lit from the sun's side (right, toward the bottom)
	float lit = clamp(0.5 + (fbm(q + vec2(0.06, 0.06)) - fbm(q - vec2(0.06, 0.06))) * 5.0, 0.0, 1.0);
	vec3 cc = mix(cloud_lo, cloud_hi, lit) * (0.75 + 0.35 * smoothstep(th, th + 0.35, n));
	// cloud shadows on the ground
	surf *= 1.0 - 0.45 * smoothstep(th - 0.2, th, fbm(q + vec2(0.3, -0.2)));
	vec3 c = mix(surf, cc, cl);
	// the air between: thick high up, and more toward the top of the screen
	// (looking further through it)
	float dist = length(VERTEX);
	float h = mix(0.62, 0.1, smoothstep(0.0, 1.1, level)) + smoothstep(90.0, 200.0, dist) * 0.25;
	c = mix(c, haze, clamp(h, 0.0, 0.92));
	ALBEDO = max(c, vec3(0.0)) * brightness;
	ALPHA = smoothstep(0.0, 0.3, level);
}
