shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, depth_test_disabled, shadows_disabled, fog_disabled;
// Camera-facing enemy bullet: white core, saturated body and a dark outer
// band so it reads against bright ground. Always drawn on top.

void vertex() {
	float s = length(MODEL_MATRIX[0].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * s, INV_VIEW_MATRIX[1] * s, INV_VIEW_MATRIX[2] * s, MODEL_MATRIX[3]);
}

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	vec3 c = pow(COLOR.rgb, vec3(2.2));
	float core = smoothstep(0.44, 0.3, r);
	float band = smoothstep(0.66, 0.8, r);
	vec3 col = mix(c * 1.5, vec3(1.5), core);
	col = mix(col, c * 0.22, band * 0.9);
	ALBEDO = col;
	ALPHA = smoothstep(1.0, 0.9, r) * COLOR.a;
}
