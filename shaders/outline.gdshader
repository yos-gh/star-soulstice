shader_type spatial;
render_mode unshaded, blend_mul, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled, shadows_disabled;
// Full-screen edge pass that gives the voxels a crisp, pixel-art finish.
// Drawn first among transparent things (render_priority -128), so glows and
// effects added later stay clean. From the depth and normal buffers:
//   silhouette (a much farther neighbour)  -> dark outline on the near side
//   convex crease (normals turn away)      -> bright edge highlight
//   concave crease                         -> soft dark line
// Output multiplies the frame (blend_mul), so 1.0 = unchanged.

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D nr_tex : hint_normal_roughness_texture, filter_nearest, repeat_disable;
uniform float outline = 0.3;
uniform float highlight = 1.35;
uniform float crease = 0.72;
uniform float far_fade = 70.0;

void vertex() {
	POSITION = vec4(VERTEX.xy * 2.0, 1.0, 1.0);
}

float lin(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_tex, uv).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return -v.z / v.w;
}

void fragment() {
	vec2 px = 1.0 / VIEWPORT_SIZE;
	float d0 = lin(SCREEN_UV, INV_PROJECTION_MATRIX);
	vec3 n0 = texture(nr_tex, SCREEN_UV).xyz * 2.0 - 1.0;
	float k = 1.0;
	if (d0 < far_fade) {
		float sil = 0.0;
		float hi = 0.0;
		float lo = 0.0;
		vec2 offs[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
		for (int i = 0; i < 4; i++) {
			vec2 uv = SCREEN_UV + offs[i];
			float dn = lin(uv, INV_PROJECTION_MATRIX);
			if (dn - d0 > 0.06 * d0) {
				sil = 1.0;
				continue;
			}
			if (abs(dn - d0) > 0.02 * d0) {
				continue;
			}
			vec3 nn = texture(nr_tex, uv).xyz * 2.0 - 1.0;
			if (dot(n0, nn) < 0.75) {
				vec2 dir = normalize(vec2(offs[i].x, -offs[i].y));
				if (dot(nn.xy - n0.xy, dir) > 0.0) {
					hi = 1.0;
				} else {
					lo = 1.0;
				}
			}
		}
		if (sil > 0.0) {
			k = outline;
		} else if (lo > 0.0) {
			k = crease;
		} else if (hi > 0.0) {
			k = highlight;
		}
	}
	ALBEDO = vec3(k);
}
