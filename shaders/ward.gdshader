shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// A panel of STAR SOUL's barrier (CoreModels soul_ward): a hexagon of
// light lying on the play plane, UV across it (0.5 = the middle). Blue like
// every breakable cover: a bright rim, a faint fill with a fine grid
// running over it. `build` 0..1 draws it in (the rim first, out from
// its corners, then the fill: a panel coming back), `hit` flashes
// it white, `wear` (1 - its health) makes it flicker and dim.

uniform vec3 col : source_color = vec3(0.35, 0.72, 1.0);
uniform float build = 1.0;
uniform float hit = 0.0;
uniform float wear = 0.0;
uniform float seed = 0.0;

float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	// hexagon distance (corners on +-x): 1 at the rim
	vec2 q = abs(p);
	float hx = max(q.y, q.x * 0.5 + q.y * 0.8660254) / 0.8660254;
	float rim = smoothstep(0.78, 0.93, hx) * (1.0 - smoothstep(0.97, 1.0, hx));
	// the rim draws in along each edge, out from the corners
	float ang = atan(p.y, p.x);
	float along = abs(fract(ang / 1.0471976 + 0.5) - 0.5) * 2.0;
	float drawn = step(along, build * 1.4);
	float fill = smoothstep(0.55, 1.0, build);
	float grid = 0.5 + 0.5 * sin((p.y * 9.0 + TIME * 3.0 + seed * 7.0)) * sin(p.x * 9.0);
	float inside = (1.0 - smoothstep(0.88, 0.95, hx)) * (0.16 + 0.1 * grid);
	float flick = 1.0 - wear * 0.45 * step(0.6, hash(vec2(floor(TIME * 18.0), seed)));
	vec3 c = col * (rim * drawn * 1.9 + inside * fill) * flick;
	c += vec3(1.0, 1.0, 1.0) * hit * (rim * 1.2 + inside * 2.0);
	ALBEDO = c * step(hx, 1.0);
}
