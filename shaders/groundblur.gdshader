shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;
// Full-screen pass that softly blurs only what lies below the play plane:
// the ground lightly, the deep background more. Units, bullets and items
// (all near y = 0) stay sharp. Selection is by world height reconstructed
// from the depth buffer, not by distance, so the tilted camera can't blur a
// unit at the top of the screen. Drawn first among transparent objects.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap, repeat_disable;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform float y_start = -1.4;  // above this: untouched
uniform float y_full = -30.0;  // at or below this: full blur
uniform float ground_px = 1.6;  // blur radius just under y_start (pixels)
uniform float deep_px = 3.2;  // blur radius at y_full

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

float world_y(vec2 uv, mat4 inv_proj, mat4 inv_view) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	v /= v.w;
	return (inv_view * vec4(v.xyz, 1.0)).y;
}

void fragment() {
	float y = world_y(SCREEN_UV, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX);
	if (y > y_start) {
		discard;
	}
	float k = clamp((y_start - y) / (y_start - y_full), 0.0, 1.0);
	float r = mix(ground_px, deep_px, k);
	vec2 px = r / VIEWPORT_SIZE;
	vec3 sum = texture(screen_tex, SCREEN_UV).rgb * 2.0;
	float wsum = 2.0;
	for (int i = 0; i < 8; i++) {
		float a = float(i) * 0.785398 + 0.39;
		vec2 uv = SCREEN_UV + vec2(cos(a), sin(a)) * px;
		// skip taps that land on something sharp (a unit or bullet)
		if (world_y(uv, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) > y_start) {
			continue;
		}
		sum += texture(screen_tex, uv).rgb;
		wsum += 1.0;
	}
	ALBEDO = sum / wsum;
}
