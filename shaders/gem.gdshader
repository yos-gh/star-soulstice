shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// A cut gem (stage 5's last boss, CoreModels): flat facets lit from inside.
// Each facet takes its own shade of the body colour (a hash of its normal)
// and shimmers; the facets facing the camera let the heart's light through;
// the reflection catches a few bright directions (one of them turning), so
// glints run over the facets as the gem turns, split into a little rainbow
// fire; the rim glows. `light` = how much light the heart gives, `heat`
// (rage) heats the inner light toward `fire`, `glint` scales the sparkle.
// The hit flash and the warning pulse come over it as an overlay
// (Enemy._shade, flash.gdshader).

uniform vec3 body : source_color = vec3(0.08, 0.62, 0.36);
uniform vec3 deep : source_color = vec3(0.01, 0.1, 0.07);
uniform vec3 fire : source_color = vec3(1.0, 0.9, 0.6);
uniform float light = 1.0;
uniform float heat = 0.0;
uniform float glint = 1.0;

varying vec3 mnormal;

void vertex() {
	mnormal = NORMAL;
}

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

vec3 hue(float h) {
	return clamp(abs(fract(h + vec3(0.0, 2.0 / 3.0, 1.0 / 3.0)) * 6.0 - 3.0) - 1.0, 0.0, 1.0);
}

void fragment() {
	vec3 n = normalize(NORMAL);
	vec3 v = normalize(VIEW);
	float ndv = clamp(dot(n, v), 0.0, 1.0);
	float h = hash3(floor(mnormal * 6.0 + 0.5));
	vec3 wn = (INV_VIEW_MATRIX * vec4(n, 0.0)).xyz;
	vec3 wv = (INV_VIEW_MATRIX * vec4(v, 0.0)).xyz;
	vec3 r = reflect(-wv, wn);
	vec3 b = body;
	vec3 dk = deep;
	vec3 fi = fire;
	// the facet's own shade, shimmering
	float sh = 0.5 + 0.5 * sin(TIME * 1.7 + h * 6.283);
	vec3 inside = mix(dk, b, 0.2 + 0.65 * h + 0.15 * sh);
	// the heart's light through the facets that face the camera
	inside += b * pow(ndv, 4.0) * 0.6 * light;
	// heat: the facets flicker hot, each at its own beat
	float fl = 0.5 + 0.5 * sin(TIME * 13.0 + h * 40.0);
	inside += fi * heat * 0.16 * fl;
	// glints: bright directions in the reflection
	float g = pow(max(dot(r, normalize(vec3(0.35, 1.0, 0.45))), 0.0), 60.0);
	g += pow(max(dot(r, normalize(vec3(-0.7, 0.75, -0.25))), 0.0), 80.0) * 0.8;
	g += pow(max(dot(r, normalize(vec3(sin(TIME * 0.8), 0.55, cos(TIME * 0.8)))), 0.0), 36.0) * 0.7;
	vec3 disp = mix(vec3(1.0), hue(h * 0.6 + dot(r, vec3(0.6, 0.3, 0.5))), 0.45);
	float fres = pow(1.0 - ndv, 3.0);
	ALBEDO = inside * 0.1;
	EMISSION = inside * (0.55 + 0.2 * heat) + mix(b, fi, 0.15 + 0.45 * heat) * fres * 0.55 * light + disp * g * 1.8 * glint;
	ROUGHNESS = 0.06;
	SPECULAR = 0.6;
	METALLIC = 0.0;
}
