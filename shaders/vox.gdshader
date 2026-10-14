shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// Lit voxel surface. Vertex colours are authored in sRGB and carry baked
// ambient occlusion; hit flashes are drawn by an overlay (flash.gdshader).
// max() keeps pow() away from tiny negative colours: their NaN pixels
// bloomed into black-centred white blobs.
// The ground uses its own material with dim/desat/haze so it recedes
// behind units and bullets.

uniform float dim = 1.0;
uniform float desat = 0.0;
uniform vec3 haze : source_color = vec3(0.0);
uniform float haze_amt = 0.0;
uniform float specular = 0.25;

void fragment() {
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desat) * dim;
	ALBEDO = mix(c, haze, haze_amt);
	ROUGHNESS = 0.85;
	SPECULAR = specular;
}
