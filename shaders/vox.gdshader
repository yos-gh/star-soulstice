shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Lit voxel surface. Vertex colours are authored in sRGB and carry baked
// ambient occlusion; hit flashes are drawn by an overlay (flash.gdshader).
// max() keeps pow() away from tiny negative colours: their NaN pixels
// bloomed into black-centred white blobs.

void fragment() {
	ALBEDO = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
}
