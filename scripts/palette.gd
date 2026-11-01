class_name Palette
extends RefCounted
## Colour schemes for the whole scene: light, grading, backdrop and ground.
## Units, bullets and effects keep their own colours (they carry gameplay
## meaning); the schemes set the world around them. Switch with F2 in game
## or --palette=NAME. Each is modelled on a known look:
##   fortress  the current look: teal fortress steel under a violet nebula
##   apollo    after the Apollo pixel palette (Lospec), made for sci-fi:
##             space-dark navy, steel blues, cyan, muted greens
##   treasure  after Ikaruga / Under Defeat: near-monochrome cold steel and
##             grey sky, neutral light; only the units and shots carry colour
##   nova      after 80s-90s arcade space shooters: deep indigo night, warm
##             rust-and-brass ground, a magenta-orange nebula

const ORDER := ["fortress", "apollo", "treasure", "nova"]

const SETS := {
	"fortress": {
		"bg": Color(0.008, 0.008, 0.02), "ambient": Color(0.55, 0.58, 0.8), "ambient_e": 0.55,
		"sun": Color(1.0, 0.94, 0.86), "sun_e": 1.25, "fog": Color(0.03, 0.03, 0.07),
		"sat": 1.05, "con": 1.0, "shadow": Color(0.0, 0.0, 0.02), "mid": Color(0.5, 0.5, 0.52), "high": Color(1.0, 1.0, 0.98),
		"neb": [Color(0.008, 0.01, 0.025), Color(0.12, 0.05, 0.22), Color(0.03, 0.12, 0.22), Color(0.22, 0.06, 0.12)], "neb_b": 0.8,
		"planet": [Color(0.2, 0.3, 0.34), Color(0.1, 0.17, 0.22), Color(0.34, 0.29, 0.22), Color(0.3, 0.65, 0.9)], "ring": Color(0.32, 0.36, 0.42),
		"g_tint": Color(1.0, 1.0, 1.0), "g_dim": 0.72, "g_desat": 0.3, "g_con": 0.7, "t_desat": 0.08, "g_haze": Color(0.03, 0.045, 0.07), "g_haze_amt": 0.25,
		"sky": [Color(0.07, 0.06, 0.11), Color(0.3, 0.28, 0.36), Color(0.1, 0.09, 0.14), Color(0.045, 0.05, 0.06), Color(0.28, 0.5, 0.36)], "sky_desat": 0.25,
	},
	"apollo": {
		"bg": Color(0.035, 0.045, 0.09), "ambient": Color(0.45, 0.6, 0.8), "ambient_e": 0.6,
		"sun": Color(0.92, 0.97, 1.0), "sun_e": 1.2, "fog": Color(0.05, 0.08, 0.14),
		"sat": 1.0, "con": 0.97, "shadow": Color(0.02, 0.03, 0.07), "mid": Color(0.47, 0.51, 0.55), "high": Color(0.97, 1.0, 1.0),
		"neb": [Color(0.035, 0.05, 0.1), Color(0.07, 0.13, 0.25), Color(0.1, 0.25, 0.3), Color(0.08, 0.17, 0.12)], "neb_b": 0.75,
		"planet": [Color(0.27, 0.42, 0.2), Color(0.12, 0.2, 0.17), Color(0.55, 0.62, 0.36), Color(0.45, 0.75, 0.82)], "ring": Color(0.3, 0.45, 0.55),
		"g_tint": Color(0.82, 0.95, 1.08), "g_dim": 0.75, "g_desat": 0.2, "g_con": 0.68, "t_desat": 0.06, "g_haze": Color(0.05, 0.08, 0.14), "g_haze_amt": 0.28,
		"sky": [Color(0.06, 0.08, 0.13), Color(0.27, 0.33, 0.38), Color(0.08, 0.11, 0.15), Color(0.04, 0.06, 0.06), Color(0.3, 0.52, 0.4)], "sky_desat": 0.2,
	},
	"treasure": {
		"bg": Color(0.03, 0.032, 0.036), "ambient": Color(0.62, 0.64, 0.68), "ambient_e": 0.55,
		"sun": Color(1.0, 1.0, 1.0), "sun_e": 1.3, "fog": Color(0.07, 0.072, 0.08),
		"sat": 0.92, "con": 1.0, "shadow": Color(0.01, 0.012, 0.018), "mid": Color(0.5, 0.5, 0.5), "high": Color(1.0, 0.99, 0.96),
		"neb": [Color(0.03, 0.032, 0.036), Color(0.09, 0.09, 0.1), Color(0.06, 0.07, 0.08), Color(0.1, 0.09, 0.08)], "neb_b": 0.8,
		"planet": [Color(0.3, 0.3, 0.31), Color(0.16, 0.16, 0.18), Color(0.38, 0.36, 0.33), Color(0.7, 0.75, 0.8)], "ring": Color(0.35, 0.35, 0.36),
		"g_tint": Color(0.95, 0.97, 1.0), "g_dim": 0.8, "g_desat": 0.7, "g_con": 0.62, "t_desat": 0.35, "g_haze": Color(0.06, 0.062, 0.07), "g_haze_amt": 0.3,
		"sky": [Color(0.08, 0.08, 0.09), Color(0.32, 0.32, 0.33), Color(0.11, 0.11, 0.12), Color(0.05, 0.05, 0.055), Color(0.36, 0.4, 0.38)], "sky_desat": 0.6,
	},
	"nova": {
		"bg": Color(0.02, 0.008, 0.035), "ambient": Color(0.7, 0.55, 0.75), "ambient_e": 0.55,
		"sun": Color(1.0, 0.86, 0.72), "sun_e": 1.25, "fog": Color(0.06, 0.02, 0.08),
		"sat": 1.08, "con": 1.0, "shadow": Color(0.03, 0.0, 0.05), "mid": Color(0.52, 0.48, 0.5), "high": Color(1.0, 0.97, 0.9),
		"neb": [Color(0.02, 0.008, 0.035), Color(0.24, 0.05, 0.22), Color(0.3, 0.12, 0.04), Color(0.08, 0.05, 0.25)], "neb_b": 0.75,
		"planet": [Color(0.45, 0.25, 0.2), Color(0.22, 0.1, 0.16), Color(0.6, 0.45, 0.25), Color(1.0, 0.5, 0.6)], "ring": Color(0.5, 0.35, 0.3),
		"g_tint": Color(1.12, 0.92, 0.82), "g_dim": 0.72, "g_desat": 0.25, "g_con": 0.68, "t_desat": 0.08, "g_haze": Color(0.07, 0.03, 0.07), "g_haze_amt": 0.26,
		"sky": [Color(0.09, 0.05, 0.1), Color(0.34, 0.25, 0.33), Color(0.12, 0.07, 0.13), Color(0.06, 0.04, 0.05), Color(0.4, 0.45, 0.32)], "sky_desat": 0.2,
	},
}

static var current := "fortress"


static func apply(game: Game, name: String) -> void:
	if not SETS.has(name):
		push_warning("unknown palette " + name)
		return
	current = name
	var p: Dictionary = SETS[name]
	var env := game.env
	env.background_color = p["bg"]
	env.ambient_light_color = p["ambient"]
	env.ambient_light_energy = p["ambient_e"]
	env.fog_light_color = p["fog"]
	env.adjustment_enabled = true
	env.adjustment_saturation = p["sat"]
	env.adjustment_contrast = p["con"]
	# split toning through a per-channel grading curve
	var g := Gradient.new()
	g.set_color(0, p["shadow"])
	g.set_color(1, p["high"])
	g.add_point(0.5, p["mid"])
	var gt := GradientTexture1D.new()
	gt.gradient = g
	gt.width = 256
	env.adjustment_color_correction = gt
	game.sun.light_color = p["sun"]
	game.sun.light_energy = p["sun_e"]
	var t := game.backdrop
	var neb: Array = p["neb"]
	if t.nebula_mat != null:
		t.nebula_mat.set_shader_parameter("base", neb[0])
		t.nebula_mat.set_shader_parameter("neb_a", neb[1])
		t.nebula_mat.set_shader_parameter("neb_b", neb[2])
		t.nebula_mat.set_shader_parameter("neb_c", neb[3])
		t.nebula_mat.set_shader_parameter("brightness", p["neb_b"])
	# warp space (stage 5's last boss): the nebula's colours, brightened
	if t.warp_mat != null:
		const WB := 2.0
		t.warp_mat.set_shader_parameter("base", neb[0])
		t.warp_mat.set_shader_parameter("col_a", (neb[1] as Color) * WB)
		t.warp_mat.set_shader_parameter("col_b", (neb[2] as Color) * WB)
		t.warp_mat.set_shader_parameter("col_c", (neb[3] as Color) * WB)
		t.warp_mat.set_shader_parameter("brightness", p["neb_b"])
	var pl: Array = p["planet"]
	# the planet is scenery: keep it dim so it never competes with the field
	const PB := 0.5
	if t.planet_mat != null:
		t.planet_mat.set_shader_parameter("band_a", (pl[0] as Color) * PB)
		t.planet_mat.set_shader_parameter("band_b", (pl[1] as Color) * PB)
		t.planet_mat.set_shader_parameter("band_c", (pl[2] as Color) * PB)
		t.planet_mat.set_shader_parameter("rim_col", (pl[3] as Color) * 0.6)
	if t.ring_mat != null:
		t.ring_mat.set_shader_parameter("ring_col", p["ring"])
	# stage 4's planet below and its cloud banks (the haze is shared, so the
	# deep banks melt into the sky behind them)
	var sk: Array = p["sky"]
	if t.sky_mat != null:
		t.sky_mat.set_shader_parameter("haze", sk[0])
		t.sky_mat.set_shader_parameter("cloud_hi", sk[1])
		t.sky_mat.set_shader_parameter("cloud_lo", sk[2])
		t.sky_mat.set_shader_parameter("ground", sk[3])
		t.sky_mat.set_shader_parameter("lights", sk[4])
	for cm: ShaderMaterial in [PlanetModels.cloud_material(), PlanetModels.deep_material()]:
		cm.set_shader_parameter("haze", sk[0])
		cm.set_shader_parameter("desat", p["sky_desat"])
	# the ground and its tiles share the recession; the tiles keep more colour
	for gm: ShaderMaterial in [Vox.ground_mat, Vox.tile_mat]:
		gm.set_shader_parameter("tint", p["g_tint"])
		gm.set_shader_parameter("dim", p["g_dim"])
		gm.set_shader_parameter("desat", p["t_desat"] if gm == Vox.tile_mat else p["g_desat"])
		gm.set_shader_parameter("contrast", p["g_con"])
		gm.set_shader_parameter("haze", p["g_haze"])
		gm.set_shader_parameter("haze_amt", p["g_haze_amt"])


static func next(game: Game) -> String:
	var i := ORDER.find(current)
	var n: String = ORDER[(i + 1) % ORDER.size()]
	apply(game, n)
	return n
