shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
// A crystal (stage 5's last boss, CoreModels): an abstract solid of flat
// dark facets with lines of light along its edges. Nothing of a cut gem:
// no sparkle, no fire; each facet is one flat tone (lit by a fixed key
// light, a cold fill from the other side), a soft sheen where it mirrors
// the key, the light inside showing faintly through the facets that face
// the camera, and its edges burning.
// The vertex colour holds the triangle's barycentric coordinates (a channel
// stuck at 1 hides the edge across from that corner: the diagonal of a
// quad), so the lines follow the solid's real edges.
// `light` scales the edge and inner light, `heat` (rage) turns it from
// `edge` to `fire`, `core` (0..1) makes the whole solid shine (the seed
// inside), `wash` adds white (a hit, a warning pulse), `grad` brightens it
// toward the ends of its long axis (local y, `span` long).

uniform vec3 body : source_color = vec3(0.12, 0.14, 0.32);
uniform vec3 deep : source_color = vec3(0.012, 0.014, 0.04);
uniform vec3 edge : source_color = vec3(0.62, 1.0, 0.84);
uniform vec3 fire : source_color = vec3(1.0, 0.86, 0.62);
uniform float light = 1.0;
uniform float heat = 0.0;
uniform float core = 0.0;
uniform float wash = 0.0;
uniform float edge_w = 0.035;
uniform float grad = 0.0;
uniform float span = 5.0;

varying vec3 wn;
varying vec3 wp;
varying float along;

void vertex() {
	wn = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	along = abs(VERTEX.y) / span;
}

void fragment() {
	vec3 n = normalize(wn);
	vec3 v = normalize(CAMERA_POSITION_WORLD - wp);
	float ndv = clamp(dot(n, v), 0.0, 1.0);
	vec3 key_dir = normalize(vec3(-0.5, 0.8, 0.35));
	float key = clamp(dot(n, key_dir), 0.0, 1.0);
	float fill = clamp(dot(n, normalize(vec3(0.7, 0.1, -0.6))), 0.0, 1.0);
	vec3 lc = mix(edge, fire, heat);
	// the facet: one flat tone
	vec3 c = mix(deep, body, 0.08 + 0.92 * key);
	c += body * vec3(0.55, 0.5, 1.0) * fill * 0.28;
	// a soft sheen where it mirrors the key light
	vec3 r = reflect(-v, n);
	c += mix(body, vec3(1.0), 0.5) * pow(max(dot(r, key_dir), 0.0), 14.0) * 0.22;
	// barycentric distance to the nearest drawn edge
	float d = min(COLOR.r, min(COLOR.g, COLOR.b));
	float w = fwidth(d) * 1.2;
	float line = 1.0 - smoothstep(edge_w - w, edge_w + w, d);
	float bleed = exp(-d * 12.0);
	// the light inside, faintly through the facets that face the camera
	float face = smoothstep(0.02, 0.3, d);
	c += lc * pow(ndv, 2.5) * face * 0.035 * light;
	c += lc * bleed * 0.1 * light;
	c += lc * pow(1.0 - ndv, 3.0) * 0.06 * light;
	// the seed: light all through, its facets only a shade apart
	vec3 lit = lc * (0.75 + 0.7 * key + 0.5 * pow(ndv, 2.0)) * (0.7 + 0.3 * light);
	c = mix(c, lit, core);
	c += mix(lc, vec3(1.0), 0.4) * line * (1.5 + 1.2 * grad * along * along) * max(light, 0.25);
	c += mix(lc, vec3(1.0), 0.5) * wash;
	ALBEDO = c;
}
