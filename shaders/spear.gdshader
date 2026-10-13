shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// The Spear lance: a short, wide energy blade on the play plane.
// UV.y = 0 at the tip (far), 1 at the ship.

uniform float power = 1.0;
uniform vec4 tint : source_color = vec4(0.35, 0.85, 1.0, 1.0);

void fragment() {
	float x = abs(UV.x - 0.5) * 2.0;
	float y = UV.y;
	float w = mix(0.15, 1.0, smoothstep(0.0, 0.55, y));
	float body = smoothstep(w, w * 0.25, x);
	float core = smoothstep(w * 0.4, 0.0, x);
	float flow = 0.75 + 0.25 * sin(y * 26.0 + TIME * 46.0) + 0.15 * sin(x * 14.0 - TIME * 31.0);
	float fade = smoothstep(0.0, 0.12, y) * smoothstep(1.0, 0.85, y);
	vec3 c = tint.rgb * body * flow * 2.4 + vec3(1.0) * core * 1.6;
	ALBEDO = c * fade * power;
}
