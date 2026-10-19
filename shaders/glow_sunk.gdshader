shader_type spatial;
render_mode unshaded, shadows_disabled;
// glow.gdshader for a defeated boss's wreck: sunk under the explosions like
// vox_sunk.gdshader.

uniform float energy = 3.0;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 d = w - cam;
	float ny = mix(-0.975, -0.85, clamp((w.y + 0.8) / 2.0, 0.0, 1.0));
	vec3 w2 = cam + d * ((ny - cam.y) / min(d.y, -0.0001));
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(w2, 1.0);
}

void fragment() {
	ALBEDO = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2)) * energy;
}
