shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
// A star streaking past in warp space (Backdrop warp): a flat quad lying in
// the layer's plane, stretched down the screen along its flight (UV.y
// along it, 1 = the head, at the bottom), the head bright and the trail
// fading out behind it. The instance colour tints it.
// (Clamped before every pow(): a negative base gives NaN, and NaN pixels
// bloom into black-centred white blobs.)

void fragment() {
	float across = clamp(1.0 - abs(UV.x - 0.5) * 2.0, 0.0, 1.0);
	float along = clamp(UV.y, 0.0, 1.0);
	float trail = pow(along, 2.2) * (1.0 - smoothstep(0.94, 1.0, along));
	float head = smoothstep(0.86, 0.97, along) * (1.0 - smoothstep(0.97, 1.0, along));
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	ALBEDO = (c * trail + c * head * 0.8) * across * across * 1.1 * COLOR.a;
}
