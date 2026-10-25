shader_type spatial;
render_mode diffuse_lambert, specular_disabled, fog_disabled;
// Stage 4's cloud banks (Backdrop "sky"): voxel lumps like the ground but
// fading into the haze of the air the deeper they lie (unlit: the same
// colour the sky plane shows behind them). Dim and desaturated: scenery.

uniform float dim = 0.68;
uniform float desat = 0.25;
uniform vec3 haze : source_color = vec3(0.07, 0.06, 0.11);
uniform float near_y = -14.0;  // no haze above this
uniform float far_y = -60.0;  // most haze at or below this
uniform float haze_max = 0.85;

varying float wy;

void vertex() {
	wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desat) * dim;
	// the air in front: the lit colour gives way to the unlit haze
	float k = clamp((near_y - wy) / (near_y - far_y), 0.0, 1.0) * haze_max;
	ALBEDO = max(c * (1.0 - k), vec3(0.0));
	EMISSION = haze * k;
	ROUGHNESS = 1.0;
}
