shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Lit voxel surface. Vertex colours are authored in sRGB and carry baked
// ambient occlusion; hit flashes are drawn by an overlay (flash.gdshader).
// max() keeps pow() away from tiny negative colours: their NaN pixels
// bloomed into black-centred white blobs.
// The ground uses its own material (Vox.ground_mat, set by Palette) with
// tint, reduced contrast, desaturation and haze so it recedes behind units
// and bullets.

uniform float dim = 1.0;
uniform float desat = 0.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform float contrast = 1.0;
uniform vec3 haze : source_color = vec3(0.0);
uniform float haze_amt = 0.0;
uniform float specular = 0.25;

void fragment() {
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desat) * tint * dim;
	// squeeze the range toward a mid tone: less contrast, same brightness
	c = mix(vec3(0.045), c, contrast);
	ALBEDO = max(mix(c, haze, haze_amt), vec3(0.0));
	ROUGHNESS = 0.85;
	SPECULAR = specular;
}
