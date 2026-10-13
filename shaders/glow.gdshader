shader_type spatial;
render_mode unshaded, shadows_disabled;
// Self-lit voxel faces (canopies, engines, windows); bright enough to bloom.

uniform float energy = 3.0;

void fragment() {
	ALBEDO = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2)) * energy;
}
