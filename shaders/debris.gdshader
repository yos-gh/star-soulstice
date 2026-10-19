shader_type spatial;
render_mode blend_mix, depth_draw_never, diffuse_lambert, specular_schlick_ggx;
// Explosion debris: lit like the voxel models (vox.gdshader), but drawn in
// the transparent pass and depth-tested as if it lay on the plane
// y = under_y when it flies above it, so a chunk never hides a unit or a
// bullet (see puff.gdshader). (Writing DEPTH from an opaque material came
// out black.) Its render priority puts it over the fire and smoke.

uniform float under_y = -0.8;

void fragment() {
	ALBEDO = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	ALPHA = 1.0;
	ROUGHNESS = 0.85;
	SPECULAR = 0.25;
	vec3 dir = normalize(VERTEX);
	vec3 wd = (INV_VIEW_MATRIX * vec4(dir, 0.0)).xyz;
	vec3 p = VERTEX;
	if (wd.y < -0.0001) {
		float t = (under_y - INV_VIEW_MATRIX[3].y) / wd.y;
		if (t > length(VERTEX)) {
			p = dir * t;
		}
	}
	vec4 c = PROJECTION_MATRIX * vec4(p, 1.0);
	DEPTH = c.z / c.w;
}
