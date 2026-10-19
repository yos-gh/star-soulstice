shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Camera-facing additive sprite used for flames, sparks and glows.
// INSTANCE_CUSTOM.x = age 0..1, .y = style (0 soft glow, 1 fireball, 2 ring,
// 3 square ring), .z = random seed, .w = 1: part of an explosion, depth-tested
// as if it lay on the plane y = under_y, under the units and bullets (see
// puff.gdshader); 0: where it is (hit sparks stay on top of what they hit).

uniform float under_y = -0.8;

varying vec4 cust;

void vertex() {
	cust = INSTANCE_CUSTOM;
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float under_depth(vec3 v, mat4 inv_view, mat4 proj, bool under) {
	vec3 dir = normalize(v);
	vec3 wd = (inv_view * vec4(dir, 0.0)).xyz;
	vec3 p = v;
	if (under && wd.y < -0.0001) {
		float t = (under_y - inv_view[3].y) / wd.y;
		if (t > length(v)) {
			p = dir * t;
		}
	}
	vec4 c = proj * vec4(p, 1.0);
	return c.z / c.w;
}

void fragment() {
	vec2 d = UV - 0.5;
	float r = length(d) * 2.0;
	float age = cust.x;
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	vec3 col;
	if (cust.y > 2.5) {
		float q = max(abs(d.x), abs(d.y)) * 2.0;
		float ring = smoothstep(0.1, 0.0, abs(q - 0.85)) * (1.0 - age);
		col = c * ring * 2.5;
	} else if (cust.y > 1.5) {
		float ring = smoothstep(0.12, 0.0, abs(r - 0.85)) * (1.0 - age);
		col = c * ring * 2.0;
	} else if (cust.y > 0.5) {
		// blocky fireball: quantise the uv so flames read as voxels
		vec2 q = floor(d * 9.0) / 9.0;
		float n = hash(q * 17.0 + floor(cust.z * 50.0) + floor(age * 6.0)) * 0.45;
		float rq = length(q) * 2.0;
		float body = step(rq + n * 0.6, 0.95 - age * 0.25);
		vec3 hot = mix(vec3(1.7, 1.5, 1.1), c, smoothstep(0.0, 0.5, age + rq * 0.4));
		vec3 cool = mix(hot, vec3(0.07, 0.06, 0.06), smoothstep(0.45, 1.0, age));
		col = cool * body * (1.0 - smoothstep(0.75, 1.0, age)) * 1.5;
	} else {
		float g = pow(max(1.0 - r, 0.0), 2.2);
		col = c * g * 2.0 * (1.0 - age);
	}
	ALBEDO = col * COLOR.a;
	DEPTH = under_depth(VERTEX, INV_VIEW_MATRIX, PROJECTION_MATRIX, cust.w > 0.5);
}
