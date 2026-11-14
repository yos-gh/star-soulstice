shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// A ring of light round STAR SOUL (CoreModels soul_halo): a flat square,
// UV across it (0.5 = the middle), drawn as thin circles of light with a
// dashed band and tick marks turning inside it (`turn`, radians). It is
// depth-tested, so the crystal hides the far side of a ring that goes
// round it. `alpha` fades it, `heat` turns it from `col` to `fire`,
// `dashes` / `ticks` count the marks round it.

uniform vec3 col : source_color = vec3(0.62, 1.0, 0.84);
uniform vec3 fire : source_color = vec3(1.0, 0.86, 0.62);
uniform float alpha = 1.0;
uniform float heat = 0.0;
uniform float turn = 0.0;
uniform float dashes = 24.0;
uniform float ticks = 12.0;

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float w = fwidth(r) * 1.2;
	// the rim: a thin bright circle with a faint glow either side
	float rim = smoothstep(0.012 + w, 0.0, abs(r - 0.94));
	float glow = exp(-abs(r - 0.94) * 26.0) * 0.22;
	// a dashed circle inside it, turning one way
	float da = fract((a + turn) / 6.2831853 * dashes);
	float dash = smoothstep(0.01 + w, 0.0, abs(r - 0.84)) * step(da, 0.6);
	// tick marks between the two, turning the other way; every third longer
	float ta = fract((a - turn * 0.5) / 6.2831853 * ticks);
	float idx = floor((a - turn * 0.5) / 6.2831853 * ticks);
	float inner = mod(idx, 3.0) < 0.5 ? 0.76 : 0.87;
	float aw = fwidth(a) * ticks * 0.16 + 0.012;
	float tick = step(abs(ta - 0.5), aw) * step(inner, r) * step(r, 0.92);
	vec3 c = mix(col, fire, heat);
	ALBEDO = c * (rim * 2.2 + glow + dash * 1.1 + tick * 1.3) * alpha * step(r, 1.0);
}
