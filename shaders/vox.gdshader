shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
// Lit voxel surface. Vertex colours are authored in sRGB and carry baked
// ambient occlusion; alpha is the finish (1 matte .. 0 polished metal).
// Hit flashes are drawn by an overlay (flash.gdshader).
// max() keeps pow() away from tiny negative colours: their NaN pixels
// bloomed into black-centred white blobs.

void fragment() {
	ALBEDO = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	float shine = 1.0 - clamp(COLOR.a, 0.0, 1.0);
	ROUGHNESS = mix(0.82, 0.3, shine);
	SPECULAR = mix(0.35, 0.8, shine);
	METALLIC = shine * 0.3;
}
