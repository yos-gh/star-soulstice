shader_type spatial;
render_mode diffuse_lambert, specular_disabled, fog_disabled, shadows_disabled;
// Distant gas giant: soft latitude bands with turbulence, lit by the sun,
// with a thin blue atmospheric rim. Dim on purpose: it is scenery.

uniform vec3 band_a : source_color = vec3(0.16, 0.18, 0.22);
uniform vec3 band_b : source_color = vec3(0.09, 0.11, 0.16);
uniform vec3 band_c : source_color = vec3(0.22, 0.18, 0.15);
uniform vec3 rim_col : source_color = vec3(0.35, 0.6, 1.0);

varying vec3 lp;

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

void vertex() {
	lp = normalize(VERTEX);
}

void fragment() {
	float lat = lp.y;
	float lon = atan(lp.z, lp.x);
	float turb = noise(vec2(lon * 3.0, lat * 8.0)) * 0.6 + noise(vec2(lon * 9.0, lat * 22.0)) * 0.25;
	float b = sin(lat * 18.0 + turb * 2.5);
	vec3 c = mix(band_b, band_a, smoothstep(-0.6, 0.6, b));
	c = mix(c, band_c, smoothstep(0.55, 0.9, noise(vec2(lon * 2.0, lat * 5.0))) * 0.5);
	ALBEDO = c;
	ROUGHNESS = 1.0;
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	EMISSION = rim_col * fres * 0.1;
}
