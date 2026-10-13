shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// A flat circular energy field on the play plane (Spear aura, shield).

uniform float power = 1.0;
uniform float ripples = 1.0;
uniform vec4 tint : source_color = vec4(0.35, 0.85, 1.0, 1.0);

void fragment() {
	float r = length(UV - 0.5) * 2.0;
	float ring = smoothstep(0.1, 0.0, abs(r - 0.9));
	float fill = smoothstep(1.0, 0.2, r) * 0.18;
	float wave = (0.5 + 0.5 * sin(r * 34.0 - TIME * 26.0)) * smoothstep(0.95, 0.3, r) * 0.3 * ripples;
	float hex = 0.0;
	float a = atan(UV.y - 0.5, UV.x - 0.5);
	hex = smoothstep(0.92, 1.0, cos(a * 6.0 + TIME * 2.0)) * ring * 0.6;
	ALBEDO = tint.rgb * (ring * 1.7 + fill + wave + hex) * power * step(r, 1.0);
}
