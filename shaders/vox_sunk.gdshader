shader_type spatial;
render_mode diffuse_lambert, specular_schlick_ggx;
// A defeated boss's wreck (Vox.sunk): vox.gdshader, but every vertex slides
// back along its view ray into a thin layer just under the fire (it tests
// as if on y = -0.8, see puff.gdshader) and above the smoke (-0.995),
// keeping its order along the ray. It looks exactly the same, but the fire
// of its death is drawn over it while live units and bullets stay on top.
// (glow_sunk.gdshader does the same for the glowing faces.)

uniform float dim = 1.0;
uniform float desat = 0.0;
uniform vec3 tint : source_color = vec3(1.0);
uniform float contrast = 1.0;
uniform vec3 haze : source_color = vec3(0.0);
uniform float haze_amt = 0.0;
uniform float specular = 0.25;

void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 d = w - cam;
	float ny = mix(-0.975, -0.85, clamp((w.y + 0.8) / 2.0, 0.0, 1.0));
	vec3 w2 = cam + d * ((ny - cam.y) / min(d.y, -0.0001));
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(w2, 1.0);
}

void fragment() {
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desat) * tint * dim;
	c = mix(vec3(0.045), c, contrast);
	ALBEDO = max(mix(c, haze, haze_amt), vec3(0.0));
	ROUGHNESS = 0.85;
	SPECULAR = specular;
}
