shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Pixel-art explosion sprite, camera-facing. Drawn in chunky pixels of a
// fixed world size (about one unit voxel) so it matches the voxel art.
// INSTANCE_CUSTOM = (age 0..1, style, seed, palette)
//   style 0 fire puff: white-hot core, then yellow -> orange -> red, darker
//           bands encroach from the edge and it breaks up into holes
//   style 1 smoke: grey, ragged, dissolves
//   style 2 flash: a short four-point star
//   style 3 ring: a thin ragged ring that thins as it expands
// palette 0 warm (enemies), 1 cool (the player's ship)

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

vec3 ramp(float heat, float pal) {
	// five-step pixel-art ramp, hottest first
	vec3 w0 = vec3(1.0, 0.97, 0.86);
	vec3 w1 = pal < 0.5 ? vec3(1.0, 0.84, 0.32) : vec3(0.72, 0.92, 1.0);
	vec3 w2 = pal < 0.5 ? vec3(0.96, 0.5, 0.13) : vec3(0.32, 0.62, 1.0);
	vec3 w3 = pal < 0.5 ? vec3(0.6, 0.15, 0.07) : vec3(0.16, 0.26, 0.62);
	vec3 w4 = pal < 0.5 ? vec3(0.2, 0.16, 0.15) : vec3(0.13, 0.15, 0.22);
	if (heat > 0.8) return w0;
	if (heat > 0.6) return w1;
	if (heat > 0.38) return w2;
	if (heat > 0.18) return w3;
	return w4;
}

void fragment() {
	float age = cust.x;
	float style = cust.y;
	float seed = cust.z;
	float pal = cust.w;
	float px = max(4.0, floor(world_size / 0.1));
	vec2 d = UV - 0.5;
	vec2 cell = floor(d * px);
	vec2 q = (cell + 0.5) / px;
	float r = length(q) * 2.0;
	float n = hash(cell + floor(seed * 97.0));
	float n2 = hash(cell * 1.7 + floor(seed * 53.0) + floor(age * 6.0));
	vec3 col = vec3(1.0);
	float a = 0.0;
	if (style < 0.5) {
		float edge = 0.95 - n * 0.28;
		float inside = step(r, edge);
		float heat = (1.0 - r) * 1.25 + 0.15 - age * 1.3 + (n2 - 0.5) * 0.2;
		heat = clamp(heat, 0.0, 1.0);
		float holes = step(n * 0.85 + 0.15, smoothstep(0.5, 1.0, age));
		col = ramp(heat, pal);
		a = inside * (1.0 - holes);
	} else if (style < 1.5) {
		float edge = 0.88 - n * 0.32;
		a = step(r, edge) * (1.0 - step(n, age)) * 0.5;
		col = ramp(0.0, pal) * 1.35;
	} else if (style < 2.5) {
		vec2 ad = abs(q) * 2.0;
		float len = 1.0 - age * 0.6;
		float spike = max(step(ad.x, 0.1) * step(ad.y, len), step(ad.y, 0.1) * step(ad.x, len));
		float core = step(r, 0.42 * (1.0 - age));
		a = max(spike, core);
		col = ramp(1.0, pal);
	} else {
		float w = mix(0.16, 0.05, age);
		a = step(abs(r - 0.86), w) * step(n, 1.0 - age * 0.9);
		col = ramp(0.7 - age * 0.4, pal);
	}
	if (a < 0.01) {
		discard;
	}
	ALBEDO = col;
	ALPHA = a;
}
