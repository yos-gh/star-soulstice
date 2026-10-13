shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Lit voxel surface. Vertex colours are authored in sRGB and carry baked
// ambient occlusion. flash = hit flash, tint = per-instance colour (wrecks).

instance uniform float flash = 0.0;
instance uniform vec4 tint = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec3 c = pow(COLOR.rgb, vec3(2.2)) * tint.rgb;
	ALBEDO = mix(c, vec3(1.0, 0.92, 0.85), flash);
	EMISSION = vec3(1.0, 0.55, 0.3) * flash * 0.9;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
}
