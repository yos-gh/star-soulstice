shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// Player shot: a crisp, thin laser dart on the play plane. Hard-edged
// white core inside a narrow coloured sheath (instance colour), with a
// tapered tail (UV.y = 1 at the tail).

void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float y = UV.y;
	float w = mix(1.0, 0.25, smoothstep(0.35, 1.0, y));
	w *= smoothstep(0.0, 0.12, y) * 0.6 + 0.4;
	float sheath = 1.0 - smoothstep(w * 0.8, w, x);
	float core = 1.0 - smoothstep(w * 0.25, w * 0.35, x);
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	float fade = 1.0 - smoothstep(0.6, 1.0, y) * 0.7;
	ALBEDO = (c * sheath * 1.05 + vec3(core) * 0.95) * fade * COLOR.a;
}
