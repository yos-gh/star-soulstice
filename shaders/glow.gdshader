shader_type spatial;
render_mode unshaded, shadows_disabled;
// Self-lit voxel faces (canopies, engines, windows); bright enough to bloom.

uniform float energy = 3.0;
instance uniform float flash = 0.0;
instance uniform vec4 tint = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	ALBEDO = pow(COLOR.rgb, vec3(2.2)) * energy * tint.rgb + vec3(flash);
}
