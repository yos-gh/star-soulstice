class_name SurfaceModels
extends Models
## Stage 5, the enemy planet's surface: the ground segments the Tunnel
## strings together for a surface style (open ground well below the
## sections, out past the screen's edges far down, no walls), and the
## mid-boss GORGON.
## A surface segment is LEN long like a tunnel's (in ground voxels: it
## recedes like the islands). Every segment of a style meets the next at
## the same cross profile (its features stay clear of the ends, the
## grain is only a voxel high), so the Tunnel strings them in any order and
## turns half of them round (Tunnel._add).
## Styles:
##   regolith  lunar plains: grey-brown dust, craters with raised rims and
##             pale ejecta, scattered boulders; variants with a landing pad
##             and a tank farm of the enemy's; gate: out of the base (the
##             tunnel's walls end at a portal, the base's embankment falls
##             away to the plain)
##   rift      a Martian canyon: rust-red floor with a dry channel down it,
##             stepped cliffs banded in strata up to plateaus just under
##             the play plane (the sections stay between them: SPAN);
##             gate: the plateaus rising out of the plain
##   basin     the floor of a great crater: dark basalt, cracked, low;
##             gate: the canyon walls falling back
## Rows: row r's top face is at y (r - 27) / 2: the plain at -9, the canyon
## and crater floors at -10, the plateaus at -1.5.

const STYLES := ["regolith", "rift", "basin"]
const VARIANTS := {"regolith": ["a", "b", "c", "d", "e"], "rift": ["a", "b", "c", "d"], "basin": ["a", "b", "c"]}
## where a style keeps the ground sections: between its canyon walls
## (half width), 0 = anywhere
const SPAN := {"rift": 12.0}
const NAMES := [
	"surface_regolith_a", "surface_regolith_b", "surface_regolith_c", "surface_regolith_d", "surface_regolith_e", "surface_regolith_gate",
	"surface_rift_a", "surface_rift_b", "surface_rift_c", "surface_rift_d", "surface_rift_gate",
	"surface_basin_a", "surface_basin_b", "surface_basin_c", "surface_basin_gate", "surface_basin_edge",
	"gorgon_hull", "gorgon_eye", "gorgon_lid", "gorgon_socket", "gorgon_cannon", "gorgon_gun",
	"halberd", "halberd_turret", "sat_gatling", "sat_lance", "sat_gun", "sat_barrels",
]

const R := 0.5
const XS := 56  # half width in voxels (28 units)
const NZ := 24  # voxels along (TunnelModels.LEN)
const ROWS := 26
const O := 28  # the origin row: row r's top face at (r + 1 - O) * R
const PLAIN := 9  # y -9
const FLOOR := 7  # y -10
const PLATEAU := 24  # y -1.5
const CANYON := 26  # the canyon floor's half width (voxels) where segments meet

const PALS := {
	"regolith": {
		"dust": Color(0.29, 0.27, 0.25), "dust_l": Color(0.325, 0.305, 0.28), "dust_d": Color(0.25, 0.235, 0.22),
		"basalt": Color(0.2, 0.19, 0.19), "pit": Color(0.22, 0.205, 0.195), "rock": Color(0.31, 0.29, 0.27), "rock_d": Color(0.19, 0.18, 0.17),
	},
	"rift": {
		"dust": Color(0.33, 0.25, 0.2), "dust_l": Color(0.365, 0.28, 0.22), "dust_d": Color(0.285, 0.215, 0.175),
		"basalt": Color(0.22, 0.17, 0.15), "pit": Color(0.25, 0.19, 0.16), "rock": Color(0.34, 0.26, 0.2), "rock_d": Color(0.21, 0.16, 0.14),
		"strata": [Color(0.37, 0.27, 0.21), Color(0.3, 0.22, 0.18), Color(0.4, 0.3, 0.23), Color(0.27, 0.2, 0.17)],
		"channel": Color(0.18, 0.15, 0.13),
	},
	"basin": {
		"dust": Color(0.23, 0.22, 0.22), "dust_l": Color(0.26, 0.25, 0.245), "dust_d": Color(0.195, 0.19, 0.195),
		"basalt": Color(0.15, 0.15, 0.165), "pit": Color(0.17, 0.165, 0.17), "rock": Color(0.26, 0.25, 0.245), "rock_d": Color(0.14, 0.14, 0.15),
		"crack": Color(0.1, 0.1, 0.115),
	},
}
## the enemy's works on the surface: muted greys, dim lime lamps (never red
## or orange on the ground: those are bullets)
const WORK := Color(0.36, 0.38, 0.38)
const WORK_L := Color(0.46, 0.48, 0.47)
const WORK_D := Color(0.22, 0.23, 0.24)
const WORK_LAMP := Color(0.5, 0.86, 0.32)


static func make(name: String) -> ArrayMesh:
	match name:
		"gorgon_hull":
			return _gorgon_hull()
		"gorgon_eye":
			return _gorgon_eye()
		"gorgon_lid":
			return _gorgon_lid()
		"gorgon_socket":
			return _gorgon_socket()
		"gorgon_cannon":
			return _gorgon_cannon()
		"gorgon_gun":
			return _gorgon_gun()
		"halberd":
			return _halberd()
		"halberd_turret":
			return _halberd_turret()
		"sat_gatling":
			return _sat_body(false)
		"sat_lance":
			return _sat_body(true)
		"sat_gun":
			return _sat_gun()
		"sat_barrels":
			return _sat_barrels()
	var parts := name.split("_")
	if parts.size() == 3 and parts[0] == "surface" and STYLES.has(parts[1]):
		return _segment(parts[1], parts[2])
	return null


## [[mesh, offset, spin], ...] riding on a segment (none yet).
static func props(_style: String, _variant: String) -> Array:
	return []


# ------------------------------------------------------------ the ground

## A segment: a height (top row) and colour per column, then filled down
## to where the neighbours' faces end.
static func _segment(style: String, variant: String) -> ArrayMesh:
	var pal: Dictionary = PALS[style]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(style + "/" + variant)
	var W := XS * 2
	var top := PackedInt32Array()
	top.resize(W * NZ)
	var cols: Array[Color] = []
	cols.resize(W * NZ)
	var glow := PackedByteArray()
	glow.resize(W * NZ)
	# the style's ground, column by column
	var g := {"top": top, "cols": cols, "glow": glow, "pal": pal, "rng": rng, "style": style, "variant": variant}
	for zi in NZ:
		for xi in W:
			var x := xi - XS
			var z := zi - NZ / 2
			var h := _ground(style, variant, x, z)
			top[zi * W + xi] = h
			cols[zi * W + xi] = _dust(pal, x, z)
	# what lies on it
	match style:
		"regolith":
			_regolith(g)
		"rift":
			_rift(g)
		"basin":
			_basin(g)
	var v := Vox.new(W, ROWS, NZ)
	v.ground = true
	v.jitter = 0.05
	v.cull_bottom = true
	var extra: Array = g.get("extra", [])
	var face: Array = g.get("face", [])
	for zi in NZ:
		for xi in W:
			var x := xi - XS
			var z := zi - NZ / 2
			var h := top[zi * W + xi]
			# down to the lowest neighbour, so cliff faces are whole
			var lo := h
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := xi + d.x
				var nz := zi + d.y
				if nx >= 0 and nx < W and nz >= 0 and nz < NZ:
					lo = mini(lo, top[nz * W + nx])
			var c: Color = cols[zi * W + xi]
			var fc = face[zi * W + xi] if not face.is_empty() else null
			for y in range(maxi(0, lo - 1), h + 1):
				var cc := c
				if y < h:
					cc = fc if fc != null else _face(pal, style, y, c)
				v.put(x, y, z, cc, glow[zi * W + xi] == 1 and y == h)
	# things standing on the ground (built as voxels after it)
	for e: Callable in extra:
		e.call(v)
	return v.mesh(R, Vector3(0, O, 0))


## The bare ground's top row at column x, z (before craters and works).
static func _ground(style: String, variant: String, x: int, z: int) -> int:
	var grain := Vox._hash(x >> 2, 3, z >> 2)
	var g := (1 if grain > 0.86 else 0) - (1 if grain < 0.06 else 0)
	match style:
		"regolith":
			if variant == "gate":
				return _exit_ground(x, z, g)
			# a gentle swell across (the same for every segment, and either
			# way round)
			var ax := x if x >= 0 else -1 - x
			return PLAIN + g + int(round(0.8 * sin(ax * 0.09 + 0.7) + 0.5 * sin(ax * 0.23 + 1.3)))
		"rift":
			return _canyon(variant, x, z, g)
		"basin":
			if variant == "gate":
				return _canyon_out(x, z, g)
			if variant == "edge":
				# the crater floor breaks off in a ragged cliff halfway along
				# (open space beyond: -1, no ground)
				var ze := 1.5 * sin(x * 0.21) + 1.0 * sin(x * 0.07 + 1.0) + (Vox._hash(x >> 1, 71, 0) - 0.5) * 2.0
				if z < ze:
					return -1
			return FLOOR + (1 if grain > 0.86 else 0)
	return PLAIN


## Colour of the bare top: dust in blotches (4 x 4 voxel patches) with a
## voxel's speckle.
static func _dust(pal: Dictionary, x: int, z: int) -> Color:
	var b := Vox._hash(x >> 3, 11, z >> 3)
	var s := Vox._hash(x, 13, z)
	var c: Color = pal["dust"]
	if b > 0.8:
		c = pal["dust_l"]
	elif b < 0.16:
		c = pal["dust_d"]
	if s > 0.975:
		c = pal["rock"]
	elif s < 0.015:
		c = pal["basalt"]
	return c


## Colour down a cliff face at row y (the rift's strata, rock elsewhere).
static func _face(pal: Dictionary, style: String, y: int, top_col: Color) -> Color:
	if style == "rift" and y > FLOOR + 1:
		var bands: Array = pal["strata"]
		return bands[(y / 2) % bands.size()]
	return top_col.darkened(0.18)


# ------------------------------------------------------------ regolith

## Craters and boulders on the plain; the variants add the enemy's works.
static func _regolith(g: Dictionary) -> void:
	var rng: RandomNumberGenerator = g["rng"]
	var variant: String = g["variant"]
	if variant == "gate":
		_exit_works(g)
		return
	var n := {"a": 3, "b": 2, "c": 5, "d": 1, "e": 1}.get(variant, 2) as int
	var big := variant == "b"
	for k in n:
		var r := rng.randf_range(6.5, 8.0) if (big and k == 0) else rng.randf_range(2.0, 5.0)
		var cz := rng.randf_range(-NZ / 2 + r * 1.4 + 0.5, NZ / 2 - r * 1.4 - 0.5)
		var cx := rng.randf_range(-XS + 10.0, XS - 10.0)
		if variant in ["d", "e"]:
			cx = rng.randf_range(16.0, 40.0) * (-1.0 if k % 2 == 0 else 1.0)
		_crater(g, cx, cz, r)
	_boulders(g, 14 if variant == "c" else 9)
	match variant:
		"d":
			_landing_pad(g, rng.randf_range(-6.0, 6.0))
		"e":
			_tank_farm(g, rng.randf_range(-10.0, 10.0))


## A crater at (cx, cz), radius r voxels: a bowl, a raised rim, pale
## ejecta round it.
static func _crater(g: Dictionary, cx: float, cz: float, r: float) -> void:
	var top: PackedInt32Array = g["top"]
	var cols: Array[Color] = g["cols"]
	var pal: Dictionary = g["pal"]
	var W := XS * 2
	var depth := maxf(1.5, r * 0.45)
	var reach := r * 1.9
	for zi in NZ:
		for xi in W:
			var x := xi - XS
			var z := zi - NZ / 2
			var d := Vector2(x + 0.5 - cx, z + 0.5 - cz).length()
			if d > reach:
				continue
			var i := zi * W + xi
			var h := top[i]
			if h < 0:
				continue
			if d < r:
				var f := d / r
				h -= int(round(depth * (1.0 - f * f)))
				cols[i] = pal["pit"] if f < 0.75 else pal["dust_d"]
				if f < 0.35 and r > 4.0 and Vox._hash(x, 17, z) > 0.6:
					cols[i] = pal["basalt"]
			elif d < r * 1.35:
				h += 1 if (d < r * 1.2 or r > 5.0) else 0
				if r > 5.0 and d < r * 1.18:
					h += 1
				cols[i] = pal["dust_l"]
			elif Vox._hash(x, 19, z) < 0.55 * (1.0 - (d - r * 1.35) / (reach - r * 1.35)):
				cols[i] = pal["dust_l"]
			top[i] = h


## Boulders: a few small rough lumps, clear of the ends.
static func _boulders(g: Dictionary, n: int) -> void:
	var rng: RandomNumberGenerator = g["rng"]
	var top: PackedInt32Array = g["top"]
	var cols: Array[Color] = g["cols"]
	var pal: Dictionary = g["pal"]
	var W := XS * 2
	for k in n:
		var bx := rng.randi_range(-XS + 2, XS - 3)
		var bz := rng.randi_range(-NZ / 2 + 2, NZ / 2 - 3)
		var s := rng.randi_range(1, 3)
		for dz in range(-s, s + 1):
			for dx in range(-s, s + 1):
				if dx * dx + dz * dz > s * s + 1:
					continue
				var xi := bx + dx + XS
				var zi := bz + dz + NZ / 2
				if xi < 0 or xi >= W or zi < 1 or zi >= NZ - 1:
					continue
				var i := zi * W + xi
				if top[i] < 0:
					continue
				top[i] += 1 + (1 if s >= 2 and dx * dx + dz * dz <= 1 else 0)
				cols[i] = pal["rock"] if (dx + dz) % 2 == 0 else pal["rock_d"]


## A landing pad of the enemy's near x: a raised octagon with a painted
## ring, dim lamps on its corners, a control hut and a mast.
static func _landing_pad(g: Dictionary, cx: float) -> void:
	var top: PackedInt32Array = g["top"]
	var cols: Array[Color] = g["cols"]
	var glow: PackedByteArray = g["glow"]
	var W := XS * 2
	var lvl := PLAIN + 1
	for zi in range(2, NZ - 2):
		for xi in W:
			var x := xi - XS
			var z := zi - NZ / 2
			var px := absf(x + 0.5 - cx)
			var pz := absf(z + 0.5)
			var oct := maxf(maxf(px, pz), (px + pz) * 0.72)
			if oct > 9.0:
				continue
			var i := zi * W + xi
			top[i] = lvl
			var c := WORK
			if oct > 8.0:
				c = WORK_D
			elif absf(Vector2(px, pz).length() - 5.0) < 0.6:
				c = WORK_L
			elif px < 0.6 and pz < 3.0 or pz < 0.6 and px < 3.0:
				c = WORK_L
			cols[i] = c
			if oct > 8.0 and (absf(px - pz) < 0.8 or (px < 0.6 or pz < 0.6)) and Vox._hash(x, 23, z) > 0.4:
				cols[i] = WORK_LAMP
				glow[i] = 1
	# the hut and its mast, beside the pad
	var hx := int(cx) + (12 if cx < 0.0 else -16)
	g.get_or_add("extra", []).append(func(v: Vox) -> void:
		v.fill(hx, lvl, -4, hx + 4, lvl + 3, 1, WORK)
		v.fill(hx, lvl + 4, -4, hx + 4, lvl + 4, 1, WORK_D)
		v.fill(hx + 1, lvl + 2, 2, hx + 3, lvl + 2, 2, WORK_LAMP, true)
		v.fill(hx + 2, lvl + 5, -3, hx + 2, lvl + 9, -3, WORK_L)
		v.fill(hx + 1, lvl + 9, -4, hx + 3, lvl + 9, -2, WORK)
		v.put(hx + 2, lvl + 10, -3, WORK_LAMP, true))


## A tank farm near x: squat round tanks on a pad, pipes between them, a
## pump house.
static func _tank_farm(g: Dictionary, cx: float) -> void:
	var top: PackedInt32Array = g["top"]
	var cols: Array[Color] = g["cols"]
	var W := XS * 2
	var lvl := PLAIN
	for zi in range(3, NZ - 3):
		for xi in W:
			var x := xi - XS
			if absf(x + 0.5 - cx) > 13.0:
				continue
			var i := zi * W + xi
			top[i] = lvl
			cols[i] = WORK_D if (x + zi) % 7 == 0 else Color(0.28, 0.28, 0.28)
	var tanks := [Vector3(cx - 7.0, -4.0, 3.2), Vector3(cx, 3.0, 3.6), Vector3(cx + 7.0, -3.0, 3.0)]
	g.get_or_add("extra", []).append(func(v: Vox) -> void:
		for tk: Vector3 in tanks:
			var r: float = tk.z
			for z in range(int(tk.y - r) - 1, int(tk.y + r) + 2):
				for x in range(int(tk.x - r) - 1, int(tk.x + r) + 2):
					var d := Vector2(x + 0.5 - tk.x, z + 0.5 - tk.y).length()
					if d > r:
						continue
					var band := d > r - 1.0
					for y in range(lvl + 1, lvl + 6):
						v.put(x, y, z, WORK if not band or y % 2 == 0 else WORK_D)
					v.put(x, lvl + 6, z, WORK_L if d < r * 0.5 else WORK)
			v.put(int(tk.x), lvl + 7, int(tk.y), WORK_LAMP, true)
		# pipes from tank to tank along the ground
		for k in 2:
			var a: Vector3 = tanks[k]
			var b: Vector3 = tanks[k + 1]
			for s in 21:
				var q := Vector2(a.x, a.y).lerp(Vector2(b.x, b.y), s / 20.0)
				v.put(int(round(q.x)), lvl + 2, int(round(q.y)), WORK_L)
		# the pump house
		v.fill(int(cx) - 3, lvl + 1, 6, int(cx) + 2, lvl + 3, 9, WORK)
		v.fill(int(cx) - 3, lvl + 4, 6, int(cx) + 2, lvl + 4, 9, WORK_D))


# ------------------------------------------------------------ the way out of the base

## The exit (from the base's last tunnel onto the plain): in front (+z) the
## tunnel goes on, its walls and their tops at TunnelModels' sizes; a
## portal frame across it at z 0; beyond, the base's embankment falls away
## to the plain on either side, the floor carries on as a road.
static func _exit_ground(x: int, z: int, g: int) -> int:
	var ax := x if x >= 0 else -1 - x
	if z >= 0:
		if ax >= TunnelModels.IW and ax < TunnelModels.XW:
			return 25
		if ax >= TunnelModels.XW:
			return 25  # the embankment beyond the walls
		return PLAIN
	# beyond the portal the embankment falls away in steps
	if ax >= TunnelModels.IW - 2:
		var fall := -z * 2 + (ax - TunnelModels.IW) / 6
		return maxi(PLAIN + g, 25 - fall)
	return PLAIN + (g if z < -4 else 0)


static func _exit_works(g: Dictionary) -> void:
	var top: PackedInt32Array = g["top"]
	var cols: Array[Color] = g["cols"]
	var glow: PackedByteArray = g["glow"]
	var pal: Dictionary = g["pal"]
	var W := XS * 2
	var tp: Dictionary = TunnelModels.PALS["hangar"]
	for zi in NZ:
		for xi in W:
			var x := xi - XS
			var z := zi - NZ / 2
			var ax := x if x >= 0 else -1 - x
			var i := zi * W + xi
			if top[i] >= 24:
				# the wall tops and the embankment's armoured top near them
				cols[i] = tp["top"] if ax < TunnelModels.XW else (WORK_D if (x + z) % 5 != 0 else tp["beam"])
				if z >= 0 and z <= 1 and ax >= TunnelModels.IW:
					cols[i] = TunnelModels.HAZ_A if ((ax + z) / 2) % 2 == 0 else TunnelModels.HAZ_B
				continue
			if ax < TunnelModels.IW:
				# the road out: the base's floor plates, then worn into the dust
				if z >= -2 or Vox._hash(x, 29, z) > 0.35 + (-z) * 0.05:
					var seam := ax % 8 == 7 or (zi % 8) == 7
					cols[i] = tp["seam"] if seam else tp["floor_a"]
					if ax == 0 and zi % 6 < 3:
						cols[i] = TunnelModels.MARK
			if z == -1 and ax < TunnelModels.IW and ax % 6 == 2:
				cols[i] = tp["gate_lamp"]
				glow[i] = 1
	# the portal: a pillar up each wall, its lintel over the wall tops, a
	# hazard band across the floor; the walls' faces in the base's plating
	var face: Array = g.get_or_add("face", [])
	face.resize(W * NZ)
	for zi in range(NZ / 2, NZ):
		for xi in W:
			var ax := xi - XS if xi >= XS else XS - 1 - xi
			if ax == TunnelModels.IW:
				face[zi * W + xi] = tp["wall"] if zi % 4 != 0 else tp["wall_d"]
	g.get_or_add("extra", []).append(func(v: Vox) -> void:
		for z in range(0, 3):
			for ax in range(TunnelModels.IW - 4, TunnelModels.XW):
				var c: Color = tp["frame"]
				if ax == TunnelModels.IW - 4:
					c = TunnelModels.HAZ_A if ((ax + z) / 2) % 2 == 0 else TunnelModels.HAZ_B
				var y0 := PLAIN + 1 if ax < TunnelModels.IW else 24
				for y in range(y0, 27):
					v.put(ax, y, z, c)
					v.put(-1 - ax, y, z, c)
			for ax in TunnelModels.IW - 4:
				var hz := TunnelModels.HAZ_A if ((ax + z) / 2) % 2 == 0 else TunnelModels.HAZ_B
				v.put(ax, PLAIN, z, hz)
				v.put(-1 - ax, PLAIN, z, hz)
			for y in [18, 19]:
				v.put(TunnelModels.IW - 5, y, z, tp["gate_lamp"], true)
				v.put(-TunnelModels.IW + 4, y, z, tp["gate_lamp"], true))


# ------------------------------------------------------------ the rift

## The canyon: its floor's half width eases in and out along the segment
## (the same where segments meet), the cliffs step up in terraces to the
## plateaus. The gate is where the plateaus rise out of the plain.
static func _canyon(variant: String, x: int, z: int, g: int) -> int:
	var f := sin(PI * (z + NZ / 2 + 0.5) / NZ)  # 0 at the ends
	var amp := {"a": 3.0, "b": -3.0, "c": 2.0, "d": -2.0, "gate": 0.0}.get(variant, 0.0) as float
	var side := 1.0 if x >= 0 else -1.0
	var hw := CANYON + f * amp * (1.0 if side > 0.0 else -0.7)
	var ax := float(x if x >= 0 else -1 - x)
	var jag := (Vox._hash(z, 31, int(side)) - 0.5) * 1.6
	var d := ax - hw + jag
	var floor_h := FLOOR + (g if Vox._hash(x >> 1, 5, z >> 1) > 0.5 else 0)
	if variant == "gate":
		# the plateaus rise out of the plain toward the far end (-z)
		var t := clampf((NZ / 2 - z) / float(NZ), 0.0, 1.0)  # 0 near, 1 far
		var plain := PLAIN + g
		if d < 0.0:
			return int(round(lerpf(plain, floor_h, t)))
		var rise := int(round(lerpf(0.0, PLATEAU - PLAIN, smoothstep(0.15, 0.95, t))))
		return maxi(int(round(lerpf(plain, floor_h, t))), mini(PLAIN + rise, _terraces(d) + g))
	if d < 0.0:
		return floor_h
	return _terraces(d) + (g if d > 6.0 else 0)


## The cliff's height `d` voxels out from its foot: steps of strata.
static func _terraces(d: float) -> int:
	if d < 1.0:
		return FLOOR + 4
	if d < 2.0:
		return FLOOR + 8
	if d < 3.5:
		return FLOOR + 12
	if d < 4.5:
		return FLOOR + 15
	return PLATEAU


static func _rift(g: Dictionary) -> void:
	var rng: RandomNumberGenerator = g["rng"]
	var top: PackedInt32Array = g["top"]
	var cols: Array[Color] = g["cols"]
	var pal: Dictionary = g["pal"]
	var variant: String = g["variant"]
	var W := XS * 2
	# the dry channel winding down the floor (straight where segments meet)
	var wob := rng.randf_range(-4.0, 4.0)
	for zi in NZ:
		var z := zi - NZ / 2
		var cxc := wob * sin(PI * (zi + 0.5) / NZ)
		for xi in W:
			var x := xi - XS
			var i := zi * W + xi
			if top[i] > FLOOR + 1:
				continue
			if absf(x + 0.5 - cxc) < 2.2:
				top[i] = FLOOR - 1
				cols[i] = pal["channel"]
	if variant == "gate":
		_boulders(g, 8)
		return
	# small craters on the plateaus, rubble on the floor
	for k in 3:
		var r := rng.randf_range(2.0, 4.0)
		var cz := rng.randf_range(-NZ / 2 + r * 1.4 + 0.5, NZ / 2 - r * 1.4 - 0.5)
		var cx := rng.randf_range(36.0, 50.0) * (-1.0 if k % 2 == 0 else 1.0)
		_crater(g, cx, cz, r)
	_boulders(g, 10)
	if variant == "c":
		# rock pillars standing on the floor
		for k in 2:
			var px := rng.randf_range(8.0, 18.0) * (-1.0 if k == 0 else 1.0)
			var pz := rng.randf_range(-6.0, 6.0)
			var ph := rng.randi_range(FLOOR + 9, FLOOR + 13)
			for zi in NZ:
				for xi in W:
					var d := Vector2(xi - XS + 0.5 - px, zi - NZ / 2 + 0.5 - pz).length()
					if d < 2.6:
						var i := zi * W + xi
						top[i] = ph - (1 if d > 2.0 else 0)
						cols[i] = pal["dust_l"]
	if variant == "d":
		# a rockslide off one wall
		var s := -1.0 if rng.randf() < 0.5 else 1.0
		for zi in range(3, NZ - 3):
			for xi in W:
				var x := xi - XS
				var ax := x * s
				if ax < CANYON - 9 or ax > CANYON + 1:
					continue
				var i := zi * W + xi
				var fall := (ax - (CANYON - 9)) / 2
				top[i] = maxi(top[i], FLOOR + fall + (1 if Vox._hash(x, 41, zi) > 0.6 else 0))
				cols[i] = pal["rock"] if Vox._hash(x, 43, zi) > 0.5 else pal["rock_d"]


# ------------------------------------------------------------ the basin

## Out of the canyon into the crater: the canyon walls fall back toward the
## far end (-z), the floor drops a row.
static func _canyon_out(x: int, z: int, g: int) -> int:
	var t := clampf((NZ / 2 - z) / float(NZ), 0.0, 1.0)  # 0 near, 1 far
	var ax := float(x if x >= 0 else -1 - x)
	var hw := CANYON + t * t * 40.0
	var d := ax - hw + (Vox._hash(z, 31, 1 if x >= 0 else -1) - 0.5) * 1.6
	if d < 0.0:
		return FLOOR + (1 if Vox._hash(x >> 1, 3, z >> 1) > 0.86 else 0)
	var h := _terraces(d)
	return int(round(lerpf(h, FLOOR + 2, smoothstep(0.4, 1.0, t))))


static func _basin(g: Dictionary) -> void:
	var rng: RandomNumberGenerator = g["rng"]
	var top: PackedInt32Array = g["top"]
	var cols: Array[Color] = g["cols"]
	var pal: Dictionary = g["pal"]
	var variant: String = g["variant"]
	var W := XS * 2
	# cracks across the basalt
	for k in 3:
		var a := Vector2(rng.randf_range(-XS + 4, XS - 4), rng.randf_range(-8.0, 8.0))
		var dir := Vector2.from_angle(rng.randf() * TAU)
		for s in 40:
			a += dir
			dir = dir.rotated(rng.randf_range(-0.5, 0.5))
			var xi := int(a.x) + XS
			var zi := int(a.y) + NZ / 2
			if xi < 0 or xi >= W or zi < 1 or zi >= NZ - 1:
				break
			cols[zi * W + xi] = pal["crack"]
			top[zi * W + xi] = mini(top[zi * W + xi], FLOOR)
	if variant != "gate" and variant != "edge":
		for k in (2 if variant == "b" else 1):
			var r := rng.randf_range(2.0, 4.5)
			_crater(g, rng.randf_range(-XS + 8.0, XS - 8.0), rng.randf_range(-NZ / 2 + r * 1.4 + 0.5, NZ / 2 - r * 1.4 - 0.5), r)
	_boulders(g, 6)


# ------------------------------------------------------------ GORGON

## GORGON: bare dark machinery in greys like the stage 1 boss, oxblood
## armour and bone only on the eye housings, the central gun and the
## bunkers' rims; the eyes and the conduits glow pink.
const OX := Color(0.36, 0.15, 0.15)
const OX_L := Color(0.43, 0.19, 0.18)
const OX_D := Color(0.25, 0.11, 0.11)
const BONE := Color(0.56, 0.52, 0.45)
const BONE_D := Color(0.44, 0.41, 0.35)
const G_PINK := Color(1.0, 0.36, 0.66)
const G_PINK_D := Color(0.72, 0.22, 0.48)
const CONCRETE := Color(0.3, 0.31, 0.31)
const CONCRETE_D := Color(0.25, 0.26, 0.26)
const GU := 0.25  # the hull's voxel
const GO := 40  # its origin row: row r spans y (r - GO) * GU .. (r + 1 - GO) * GU (y -10 at the bottom)
const DECK := -4.5  # the platform's top, and its lower terrace
const TERRACE := -6.75


## The last row whose top face is at or under height y.
static func _gy(y: float) -> int:
	return int(round(y / GU)) + GO - 1


## A box in units (x0..x1, y0..y1, z0..z1) filled with c.
static func _gbox(v: Vox, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, c: Color, glow := false) -> void:
	v.fill(int(round(x0 / GU)), int(round(y0 / GU)) + GO, int(round(z0 / GU)), int(round(x1 / GU)) - 1, _gy(y1), int(round(z1 / GU)) - 1, c, glow)


## The same box and its mirror image across x = 0.
static func _gbox2(v: Vox, x0: float, x1: float, y0: float, y1: float, z0: float, z1: float, c: Color, glow := false) -> void:
	_gbox(v, x0, x1, y0, y1, z0, z1, c, glow)
	_gbox(v, -x1, -x0, y0, y1, z0, z1, c, glow)


## The fortress (everything but its moving parts), after the Delilah of
## Star Soldier and built like the stage 1 boss: a stepped platform (its
## deck of plates and machinery blocks, a terrace of concrete round it,
## ribbed walls down to the crater floor); on it a lattice frame: a box
## girder spine down the middle (a conduit glowing pink inside it), a
## crossbar from it out to the eye housings, girders down the sides and
## across the back, a low walkway girder on down to the front edge; the eye
## housings (square: oxblood plates on top, bone corner rams, shutter rails
## along them, hydraulic rams out to the side girders, a square hole for
## the eye); the central gun's mount; the gun bunkers on the terrace (open
## hatches); at the back machinery blocks, pipes and two scaffold towers.
static func _gorgon_hull() -> ArrayMesh:
	var gb = Bosses.KINDS["gorgon"]
	var ex: float = (gb.EYE_OFF[1] as Vector3).x
	var cn: Vector3 = gb.CANNON_OFF
	var HX := 64
	var HZ := 52
	var W := HX * 2
	var D := HZ * 2
	var v := Vox.new(W, 37, D)
	v.jitter = 0.04
	# ---- the platform, column by column
	var top := PackedInt32Array()
	top.resize(W * D)
	top.fill(-1)
	var cols: Array[Color] = []
	cols.resize(W * D)
	var walls: Array[Color] = []
	walls.resize(W * D)
	for zi in D:
		for xi in W:
			var q := Vector2((xi - HX + 0.5) * GU, (zi - HZ + 0.5) * GU)
			var ax := absf(q.x)
			var deck := ax <= 12.0 and q.y >= -11.5 and q.y <= 6.0 and (ax - 12.0) + (q.y - 6.0) < -1.5 and (ax - 12.0) + (-11.5 - q.y) < -1.0
			var terrace := ax <= 15.5 and q.y >= -12.8 and q.y <= 9.6 and (ax - 15.5) + (q.y - 9.6) < -2.0
			if not terrace:
				continue
			var i := zi * W + xi
			var h := TERRACE
			var c := CONCRETE if posmod(int(floor(q.x / 2.0)) + int(floor(q.y / 2.0)), 2) == 0 else CONCRETE_D
			if fposmod(q.x, 2.0) < GU or fposmod(q.y, 2.0) < GU:
				c = DUSK
			var wall := DUSK if posmod(int(floor(q.x / GU)) + int(floor(q.y / GU)), 4) != 0 else DUSK_L
			if deck:
				h = DECK
				var n := Vox._hash(int(floor(q.x)), 21, int(floor(q.y)))
				c = GUN if posmod(int(floor(q.x / 1.5)) + int(floor(q.y / 1.5)), 2) == 0 else DUSK_L
				if fposmod(q.x, 1.5) < GU or fposmod(q.y, 1.5) < GU:
					c = DUSK
				elif n > 0.82:
					h += GU  # machinery blocks a step up
					c = STEEL_M
				elif n < 0.1:
					h -= GU  # vents
					c = DUSK_D
				wall = DUSK if fposmod(q.x + q.y, 1.0) > GU * 2.0 else DUSK_L
			elif ax > 14.6 or q.y > 8.7 or q.y < -12.0:
				# the terrace's edge, hazard-striped
				c = TunnelModels.HAZ_A if posmod(int(floor((q.x + q.y) / 0.5)), 2) == 0 else TunnelModels.HAZ_B
			top[i] = _gy(h)
			cols[i] = c
			walls[i] = wall
	var floor_r := _gy(-9.8)
	for zi in D:
		for xi in W:
			var i := zi * W + xi
			var h := top[i]
			if h < 0:
				continue
			var lo := h
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := xi + d.x
				var nz := zi + d.y
				var nh := top[nz * W + nx] if nx >= 0 and nx < W and nz >= 0 and nz < D else -1
				lo = mini(lo, nh if nh >= 0 else floor_r)
			for y in range(maxi(0, lo - 1), h + 1):
				v.put(xi - HX, y, zi - HZ, cols[i] if y == h else walls[i])
	# ---- the spine: a box girder down the middle, the conduit inside it
	_gbox(v, -0.25, 0.25, DECK - 0.25, DECK, -11.5, 2.0, G_PINK_D, true)
	for z in range(-11, 2):
		if posmod(z, 2) == 0:
			_gbox(v, -0.25, 0.25, DECK - 0.25, DECK, z, z + 0.5, G_PINK, true)
	_girder_z(v, 1.5, -12.0, 1.0, -1.8)
	# on past the central gun to the front edge: a low walkway girder
	_girder_z(v, 1.0, 4.4, 9.6, -3.9)
	# ---- the crossbar out to the housings, the back crossbar, the side girders
	_girder_x(v, 1.5, ex - 2.8, -3.0, -2.0)
	_girder_x(v, 1.5, 12.5, -9.0, -2.2)
	for s: float in [-1.0, 1.0]:
		_girder_z(v, 0.0, -9.6, 4.6, -2.3, s * 12.6)
	# a low girder across the front, just over the deck
	_gbox(v, -12.0, 12.0, DECK, DECK + 0.5, 5.25, 5.75, GUN_D)
	for x in range(-12, 13, 2):
		_gbox(v, x - 0.25, x + 0.25, DECK, DECK + 0.75, 5.25, 5.75, STEEL_M)
	# ---- the eye housings
	for s: float in [-1.0, 1.0]:
		var hx := s * ex
		# walls round a square hole, ribbed
		for z in range(-11, 11):
			for x in range(-11, 11):
				var ax := absf(x + 0.5)
				var az := absf(z + 0.5)
				var e := maxf(ax, az)  # in voxels from the centre
				if e > 11.0 or e < 7.8:
					continue
				var vx := int(round(hx / GU)) + x
				var plate := e > 8.4 and e < 10.6
				var corner := ax > 8.6 and az > 8.6
				var y_top := _gy(-1.75)
				for y in range(_gy(DECK) + 1, y_top + 1):
					var c := DUSK if posmod(x + z, 3) != 0 else DUSK_L
					if y == y_top:
						c = (OX if posmod(int(floor((x + 11) / 5.0)) + int(floor((z + 11) / 5.0)), 2) == 0 else OX_L) if plate else OX_D
						if corner:
							c = BONE
					v.put(vx, y, z, c)
				if corner:
					v.fill(vx, y_top + 1, z, vx, y_top + 1, z, BONE_D)
		# the hole's floor, dark, a bone ring at its lip
		_gbox(v, hx - 1.95, hx + 1.95, DECK - 0.25, DECK, -1.95, 1.95, DUSK_D)
		# shutter rails along the housing (the shutters slide on them)
		_gbox(v, hx - 2.4, hx - 2.1, -1.75, -1.5, -5.4, 5.4, STEEL_L)
		_gbox(v, hx + 2.1, hx + 2.4, -1.75, -1.5, -5.4, 5.4, STEEL_L)
		for z: float in [-5.4, 5.15]:
			_gbox(v, hx - 2.4, hx + 2.4, DECK, -1.75, z, z + 0.25, GUN_D)
		# hydraulic rams out to the side girder
		var r0 := minf(s * (ex + 2.8), s * 12.4)
		var r1 := maxf(s * (ex + 2.8), s * 12.4)
		for z: float in [-1.4, 1.15]:
			_gbox(v, r0, r1, -2.8, -2.5, z, z + 0.25, STEEL_L)
		_gbox(v, minf(s * (ex + 2.8), s * (ex + 4.6)), maxf(s * (ex + 2.8), s * (ex + 4.6)), -3.0, -2.3, -1.6, 1.6, DUSK)
		# conduits from the housing into the spine, under the crossbar
		_gbox(v, minf(s * 1.75, s * (ex - 2.8)), maxf(s * 1.75, s * (ex - 2.8)), DECK, DECK + 0.25, -3.25, -2.75, G_PINK_D, true)
	# ---- the central gun's mount
	_gbox(v, cn.x - 1.9, cn.x + 1.9, DECK, -3.25, cn.z - 1.9, cn.z + 1.9, GUN)
	_gbox(v, cn.x - 1.6, cn.x + 1.6, -3.25, -3.0, cn.z - 1.6, cn.z + 1.6, STEEL_M)
	for c: Vector2 in [Vector2(-1.65, -1.65), Vector2(1.4, -1.65), Vector2(-1.65, 1.4), Vector2(1.4, 1.4)]:
		_gbox(v, cn.x + c.x, cn.x + c.x + 0.25, -3.25, -2.75, cn.z + c.y, cn.z + c.y + 0.25, BONE)
	# ---- the gun bunkers on the terrace, hatches open
	for o: Vector3 in gb.SILO_OFF:
		_bunker(v, o.x, o.z)
	# ---- the back: machinery blocks, pipes, scaffold towers
	for b: Array in [[-10.5, -7.0, -11.2, -8.0, -3.4], [-5.8, -3.0, -11.4, -9.6, -3.0], [3.0, 6.4, -11.4, -9.8, -3.2], [7.2, 10.8, -11.0, -8.6, -3.6],
			[-11.0, -8.6, -7.6, -5.4, -3.8], [8.8, 11.2, -7.4, -5.6, -3.4], [-6.6, -3.4, -7.4, -5.6, -3.9], [3.4, 6.2, -7.6, -5.4, -3.6]]:
		_gbox(v, b[0], b[1], DECK, b[4], b[2], b[3], GUN)
		_gbox(v, b[0] + 0.25, b[1] - 0.25, b[4], b[4] + 0.25, b[2] + 0.25, b[3] - 0.25, STEEL_M)
		_gbox(v, b[0] + 0.25, b[1] - 0.25, b[4], b[4] + 0.25, (b[2] + b[3]) * 0.5 - 0.125, (b[2] + b[3]) * 0.5 + 0.125, DUSK_D)
	# pipes down either side of the spine, flanged
	for x: float in [2.6, 3.4]:
		_gbox2(v, x, x + 0.5, DECK, DECK + 0.5, -11.5, -4.4, GUN.lightened(0.06))
	for z in range(-11, -4, 2):
		_gbox2(v, 2.5, 4.0, DECK, DECK + 0.75, z, z + 0.25, STEEL_L)
	for t: Array in [[-9.6, -10.6], [8.4, -10.4]]:
		_scaffold_u(v, t[0], t[1], 1.6, 1.4, DECK, -1.5)
	return v.mesh(GU, Vector3(0, GO, 0))


## A box girder along z at x (two chords `hw` either side of it, from z0 to
## z1, their tops at y), braced across and diagonally every bay, posts down
## to the deck. hw 0 = a single heavy girder.
static func _girder_z(v: Vox, hw: float, z0: float, z1: float, y: float, x := 0.0) -> void:
	if hw <= 0.0:
		_gbox(v, x - 0.4, x + 0.4, y - 0.75, y, z0, z1, STEEL_M)
		_gbox(v, x - 0.4, x + 0.4, y - 1.0, y - 0.75, z0, z1, GUN_D)
		var z := z0
		while z < z1:
			_gbox(v, x - 0.25, x + 0.25, DECK, y - 1.0, z, z + 0.5, GUN_D)
			z += 3.0
		return
	for s: float in [-1.0, 1.0]:
		_gbox(v, x + s * hw - 0.25, x + s * hw + 0.25, y - 0.75, y, z0, z1, STEEL_M)
	var bay := 1.5
	var z := z0
	var k := 0
	while z < z1 - 0.1:
		_gbox(v, x - hw, x + hw, y - 0.5, y - 0.25, z, z + 0.25, GUN)
		# the diagonal across the bay
		var n := int(round(bay / GU))
		for t in n:
			var f := float(t) / n
			var px := lerpf(-hw, hw, f if k % 2 == 0 else 1.0 - f)
			_gbox(v, x + px - 0.125, x + px + 0.125, y - 0.5, y - 0.25, z + f * bay, z + f * bay + GU, GUN_D)
		if k % 2 == 0:
			for s: float in [-1.0, 1.0]:
				_gbox(v, x + s * hw - 0.25, x + s * hw + 0.25, DECK, y - 0.75, z, z + 0.25, GUN_D)
		z += bay
		k += 1


## A box girder along x (mirrored either side of the middle) from x0 to x1,
## its chords 0.5 either side of z, tops at y.
static func _girder_x(v: Vox, x0: float, x1: float, z: float, y: float) -> void:
	for s: float in [-1.0, 1.0]:
		_gbox2(v, x0, x1, y - 0.75, y, z + s * 0.75 - 0.25, z + s * 0.75 + 0.25, STEEL_M)
	var x := x0
	var k := 0
	while x < x1 - 0.1:
		_gbox2(v, x, x + 0.25, y - 0.5, y - 0.25, z - 0.75, z + 0.75, GUN)
		var n := 6
		for t in n:
			var f := float(t) / n
			var pz := lerpf(-0.75, 0.75, f if k % 2 == 0 else 1.0 - f)
			_gbox2(v, x + f * 1.5, x + f * 1.5 + GU, y - 0.5, y - 0.25, z + pz - 0.125, z + pz + 0.125, GUN_D)
		x += 1.5
		k += 1


## A gun bunker standing on the terrace at (x, z): a square block, an
## oxblood band under a steel rim with bone corners, its hatch open (a
## square hole down into it, the gun waits there), the hatch's two leaves
## folded back along the sides.
static func _bunker(v: Vox, x: float, z: float) -> void:
	var t := -2.75
	for s: Array in [[-1.4, -0.9, -1.4, 1.4], [0.9, 1.4, -1.4, 1.4], [-0.9, 0.9, -1.4, -0.9], [-0.9, 0.9, 0.9, 1.4]]:
		_gbox(v, x + s[0], x + s[1], TERRACE, t - 0.75, z + s[2], z + s[3], GUN)
		_gbox(v, x + s[0], x + s[1], t - 0.75, t - 0.25, z + s[2], z + s[3], OX)
		_gbox(v, x + s[0], x + s[1], t - 0.25, t, z + s[2], z + s[3], STEEL_M)
	_gbox(v, x - 0.9, x + 0.9, TERRACE, -6.25, z - 0.9, z + 0.9, DUSK_D)
	for c: Vector2 in [Vector2(-1.4, -1.4), Vector2(1.15, -1.4), Vector2(-1.4, 1.15), Vector2(1.15, 1.15)]:
		_gbox(v, x + c.x, x + c.x + 0.25, t - 0.25, t, z + c.y, z + c.y + 0.25, BONE)
	# the hatch leaves, folded back
	_gbox(v, x - 1.9, x - 1.4, t - 1.4, t - 0.25, z - 1.2, z + 1.2, DUSK_L)
	_gbox(v, x + 1.4, x + 1.9, t - 1.4, t - 0.25, z - 1.2, z + 1.2, DUSK_L)


## An open scaffold tower (corner posts, rings, a part-plated top) in units.
static func _scaffold_u(v: Vox, x: float, z: float, w: float, d: float, y0: float, y1: float) -> void:
	for c: Vector2 in [Vector2(x, z), Vector2(x + w, z), Vector2(x, z + d), Vector2(x + w, z + d)]:
		_gbox(v, c.x, c.x + 0.25, y0, y1, c.y, c.y + 0.25, STEEL_M)
	var y := y0 + 0.75
	while y < y1:
		_gbox(v, x, x + w + 0.25, y - 0.25, y, z, z + 0.25, GUN_D)
		_gbox(v, x, x + w + 0.25, y - 0.25, y, z + d, z + d + 0.25, GUN_D)
		_gbox(v, x, x + 0.25, y - 0.25, y, z, z + d + 0.25, GUN_D)
		_gbox(v, x + w, x + w + 0.25, y - 0.25, y, z, z + d + 0.25, GUN_D)
		y += 0.75
	_gbox(v, x, x + w * 0.5, y1 - 0.25, y1, z, z + d + 0.25, STEEL_L)


## An eye: a ball (radius 1.75) looking up (+y) out of its housing: a pale
## mauve-grey ball veined in oxblood, a dark limbal ring, a glowing pink
## iris with aperture blades and a white-hot pupil.
static func _gorgon_eye() -> ArrayMesh:
	var rr := 17
	var v := Vox.new(rr * 2 + 2, rr * 2 + 2, rr * 2 + 2)
	v.jitter = 0.03
	for z in range(-rr - 1, rr + 1):
		for y in range(-rr - 1, rr + 1):
			for x in range(-rr - 1, rr + 1):
				var p := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var l := p.length()
				if l > rr or l < rr - 2.5:
					continue
				var nrm := p / l
				var c := Color(0.6, 0.53, 0.52)
				var lit := false
				if nrm.y > 0.965:
					c = Color(1.0, 0.92, 0.96)
					lit = true
				elif nrm.y > 0.9:
					var a := atan2(nrm.z, nrm.x)
					c = G_PINK if fposmod(a * 6.0 / PI + nrm.y * 20.0, 1.0) > 0.25 else G_PINK_D
					lit = true
				elif nrm.y > 0.84:
					c = Color(0.18, 0.08, 0.1)
				elif absf(sin(atan2(nrm.z, nrm.x) * 5.0 + nrm.y * 7.0)) < 0.09 and nrm.y > 0.0:
					c = OX
				v.put(x, y + rr + 1, z, c, lit)
	return v.mesh(0.103, Vector3(0, rr + 1, 0), true)


## An eye's shutter (the -z one; the other is the same turned round): a flat
## armoured plate over half the hole, oxblood with a bone edge where the two
## meet, bolted, with a lip down its far side; it slides along the rails.
static func _gorgon_lid() -> ArrayMesh:
	var v := Vox.new(34, 10, 34)
	v.jitter = 0.04
	# (units of 0.125: the plate 4.25 wide, 2.1 deep, at y 1.8 over the eye's centre)
	for z in range(-17, 0):
		for x in range(-17, 17):
			var c := OX if posmod(int(floor((x + 17) / 6.0)), 2) == 0 else OX_L
			if z >= -2:
				c = BONE
			elif posmod(x, 6) == 0 and posmod(z, 6) == 3:
				c = BONE_D
			v.put(x, 7, z, c)
			v.put(x, 6, z, OX_D)
			if z <= -15:
				v.fill(x, 3, z, x, 5, z, OX_D)
	return v.mesh(0.125, Vector3(0.5, -8.4, 0.5))


## A burnt-out eye: a cracked dark shell, a few pink sparks still in it.
static func _gorgon_socket() -> ArrayMesh:
	var rr := 16
	var v := Vox.new(rr * 2 + 2, rr + 2, rr * 2 + 2)
	v.jitter = 0.08
	for z in range(-rr - 1, rr + 1):
		for y in range(0, rr + 1):
			for x in range(-rr - 1, rr + 1):
				var p := Vector3(x + 0.5, y + 0.5 - rr * 0.35, z + 0.5)
				var l := p.length()
				if l > rr or l < rr - 2.0:
					continue
				var h := Vox._hash(x >> 1, y >> 1, z >> 1)
				if h < 0.22 and p.y > 0.0:
					continue  # broken open
				var c := DUSK_D if h < 0.7 else DUSK
				var lit := false
				if Vox._hash(x, y, z) > 0.985:
					c = G_PINK_D
					lit = true
				v.put(x, y, z, c, lit)
	return v.mesh(0.1, Vector3(0, rr * 0.35 + 2.0, 0))


## The central gun: a squat block turret (forward = -z, it turns to the
## ship) on a turntable: an oxblood mantlet, three heavy barrels with
## muzzle collars, recoil cylinders along its roof, the breech glowing pink
## through vents at the back.
static func _gorgon_cannon() -> ArrayMesh:
	var v := Vox.new(28, 12, 40)
	v.jitter = 0.04
	v.fill(-12, 0, -10, 11, 1, 11, DUSK)  # the turntable
	v.fill(-10, 2, -8, 9, 6, 10, GUN)  # the block
	v.fill(-10, 7, -8, 9, 7, 10, DUSK_L)
	v.fill(-11, 2, -11, 10, 7, -8, OX)  # the mantlet
	v.fill(-11, 8, -11, 10, 8, -9, OX_L)
	v.fill(-11, 2, -11, 10, 2, -11, BONE_D)
	for x: int in [-7, -1, 5]:
		v.fill(x, 3, -20, x + 1, 5, -12, STEEL_M)  # barrels
		v.fill(x - 1, 2, -20, x + 2, 6, -19, DUSK_L)  # muzzle collars
		v.fill(x, 4, -20, x + 1, 4, -20, DUSK_D)
	for x: int in [-5, 3]:
		v.fill(x, 8, -6, x, 8, 6, STEEL_L)  # recoil cylinders
	for z: int in [5, 7, 9]:
		v.fill(-7, 5, z, 6, 6, z, G_PINK_D, true)  # breech vents
	v.fill(-3, 8, 2, 2, 8, 6, DUSK)
	return v.mesh(0.12, Vector3(0.5, 0.0, 0.5), true)


## A bunker gun: a box turret (forward = -z) with an oxblood top plate and
## twin barrels, on a square steel column that runs down into its bunker.
static func _gorgon_gun() -> ArrayMesh:
	var v := Vox.new(18, 36, 24)
	v.jitter = 0.04
	# the column
	for y in range(0, 26):
		v.fill(-3, y, -3, 2, y, 2, STEEL_M if posmod(y, 4) != 0 else DUSK)
	# the turret box
	v.fill(-6, 25, -6, 5, 29, 6, GUN)
	v.fill(-6, 30, -6, 5, 30, 6, OX)
	v.fill(-6, 30, -6, 5, 30, -6, BONE_D)
	v.fill(-4, 31, -1, 3, 31, 4, OX_D)
	v.fill(-6, 25, 6, 5, 27, 7, DUSK_L)
	# twin barrels forward, a sight between them
	for s: int in [-4, 2]:
		v.fill(s, 27, -11, s + 1, 28, -7, STEEL_M)
		v.fill(s, 27, -11, s + 1, 28, -11, DUSK_D)
	v.fill(-1, 31, -6, 0, 32, -5, BONE)
	return v.mesh(0.1, Vector3(0.5, 27.0, 0.5))


# ------------------------------------------------------------ HALBERD

## HALBERD (nose +z), bare machinery in the colours of GORGON: a box-girder
## keel that is the rail gun (two bright rails on top, the channel between
## them glowing pink in segments, a muzzle block at the nose), oxblood
## armour plates stepped beside its front, two engine blocks on truss arms
## (oxblood plates over their fronts, slatted intakes, pink exhausts, a
## ring mount for each turret), a radiator block and a mast at the back.
static func _halberd() -> ArrayMesh:
	var v := Vox.new(48, 11, 62)
	# the keel
	v.fill_sym(0, 0, -26, 5, 2, 26, GUN_D)
	v.fill_sym(0, 3, -24, 5, 5, 25, GUN)
	v.fill_sym(2, 6, -22, 3, 6, 28, STEEL_L)  # the rails
	v.fill_sym(0, 5, -22, 1, 5, 25, DUSK_D)  # the channel between them
	for z in range(-20, 24, 4):
		v.fill_sym(0, 5, z, 0, 5, z + 1, G_PINK_D, true)
	for z in range(-24, 24, 6):
		v.fill_sym(4, 3, z, 5, 6, z + 1, DUSK_L)  # rail clamps
	v.fill_sym(0, 2, 26, 4, 5, 29, DUSK_L)  # the muzzle block
	v.fill_sym(0, 3, 29, 1, 4, 30, DUSK_D)
	# oxblood plates stepped beside the front of the keel
	v.fill_sym(6, 2, 10, 11, 4, 22, OX)
	v.fill_sym(6, 5, 12, 9, 5, 20, OX_L)
	v.fill_sym(6, 2, 22, 9, 3, 24, OX_D)
	v.fill_sym(11, 4, 10, 11, 4, 22, BONE_D)
	# truss arms out to the engines
	for z0: int in [-12, 2]:
		v.fill_sym(6, 3, z0, 13, 3, z0, STEEL_M)
		v.fill_sym(6, 3, z0 + 3, 13, 3, z0 + 3, STEEL_M)
		for x in range(6, 14, 2):
			v.fill_sym(x, 3, z0, x, 3, z0 + 3, GUN_D)
	# the engines
	v.fill_sym(14, 0, -26, 23, 5, 12, GUN)
	v.fill_sym(14, 6, -10, 23, 6, 12, DUSK_L)
	v.fill_sym(14, 6, 2, 23, 7, 12, OX)
	v.fill_sym(15, 8, 4, 22, 8, 11, OX_L)
	v.fill_sym(14, 6, 12, 23, 7, 13, BONE_D)
	for z in range(-24, -11, 2):
		v.fill_sym(15, 6, z, 22, 6, z, DUSK_D)  # slatted intakes
		v.fill_sym(15, 6, z + 1, 22, 6, z + 1, STEEL_M)
	for x: int in [16, 19]:
		v.fill_sym(x, 2, -28, x + 2, 4, -27, G_PINK, true)  # exhausts
		v.fill_sym(x - 1, 1, -27, x + 3, 5, -27, DUSK)
	# the radiator and the mast at the back
	v.fill_sym(0, 6, -26, 4, 7, -20, STEEL_M)
	for z in range(-26, -19, 2):
		v.fill_sym(0, 8, z, 4, 8, z, DUSK_L)
	v.fill(-1, 8, -16, 0, 10, -15, DUSK_L)
	v.put(0, 10, -16, BONE)
	return v.mesh(U * 1.55, Vector3(0.5, 2.5, 0.5), true)


## A HALBERD engine turret (forward = -z): a box on a ring with twin
## barrels and an oxblood roof.
static func _halberd_turret() -> ArrayMesh:
	var v := Vox.new(14, 6, 20)
	v.fill(-5, 0, -5, 4, 1, 4, DUSK)
	v.fill(-4, 2, -4, 3, 3, 4, GUN)
	v.fill(-4, 4, -4, 3, 4, 3, OX)
	v.fill(-4, 4, 4, 3, 4, 4, BONE_D)
	for x: int in [-3, 1]:
		v.fill(x, 2, -10, x + 1, 3, -5, STEEL_M)
		v.fill(x, 2, -10, x + 1, 3, -10, DUSK_D)
	return v.mesh(U * 1.55, Vector3(0.5, 0.5, 0.5))


# ------------------------------------------------------------ satellites

const PANEL := Color(0.2, 0.22, 0.27)  # solar cells (dark slate: not the shells' or the ship's blue)
const PANEL_L := Color(0.3, 0.32, 0.37)


## An orbital weapon's bus (the gun or the emitter is its own part): a box
## with an oxblood top plate and bone bolts, truss arms out to a solar panel
## each side (slate cells in a frame), a radiator stack behind. The lance's
## bus is long down the screen (+z) round its emitter: square focusing
## frames along a barrel with a glowing pink tip, bone capacitor fins.
static func _sat_body(lance: bool) -> ArrayMesh:
	var v := Vox.new(42, 8, 30)
	var z0 := -6 if not lance else -8
	var z1 := 5 if not lance else 3
	v.fill(-5, 0, z0, 4, 4, z1, GUN)
	v.fill(-5, 5, z0, 4, 5, z1, OX)
	v.fill(-4, 5, z0 + 1, 3, 5, z0 + 2, OX_L)
	for c: Vector2i in [Vector2i(-5, z0), Vector2i(4, z0), Vector2i(-5, z1), Vector2i(4, z1)]:
		v.put(c.x, 6, c.y, BONE)
	# the radiator stack behind
	for z in range(z0 - 4, z0):
		v.fill(-3, 1, z, 2, 3, z, STEEL_M if posmod(z, 2) == 0 else DUSK)
	# truss arms and the panels
	for s: int in [-1, 1]:
		var a0 := 5 if s > 0 else -6
		var a1 := 9 if s > 0 else -10
		v.fill(a0, 2, -2, a1, 2, -2, STEEL_M)
		v.fill(a0, 2, 1, a1, 2, 1, STEEL_M)
		for x in range(mini(a0, a1), maxi(a0, a1) + 1, 2):
			v.fill(x, 2, -1, x, 2, 0, GUN_D)
		var p0 := 10 if s > 0 else -21
		var p1 := 20 if s > 0 else -11
		for z in range(-6, 6):
			for x in range(p0, p1 + 1):
				var frame := x == p0 or x == p1 or z == -6 or z == 5
				var grid := posmod(x, 3) == 0 or posmod(z, 3) == 0
				v.put(x, 2, z, STEEL_M if frame else (PANEL_L if grid else PANEL))
	if lance:
		# the emitter: a barrel down the screen through focusing frames
		v.fill(-2, 1, z1, 1, 3, 13, STEEL_M)
		for fz: int in [5, 8, 11]:
			for x in range(-4, 4):
				for y in range(0, 5):
					if x == -4 or x == 3 or y == 0 or y == 4:
						v.put(x, y, fz, DUSK_L)
		v.fill(-1, 2, 14, 0, 2, 14, G_PINK, true)
		v.fill(-2, 1, 13, 1, 3, 13, G_PINK_D, true)
		for z in range(z0 + 1, z1, 2):
			v.put(-6, 3, z, BONE)
			v.put(5, 3, z, BONE)
	return v.mesh(U * 1.4, Vector3(0.5, 2.5, 0.5), true)


## The rotary gun's housing (forward = -z): an oxblood shield over a steel
## box, the drum of barrels is its own part (it spins).
static func _sat_gun() -> ArrayMesh:
	var v := Vox.new(12, 7, 14)
	v.fill(-3, 0, -3, 2, 3, 4, GUN)
	v.fill(-4, 1, -4, 3, 4, -3, OX)
	v.fill(-3, 4, -3, 2, 4, 3, OX_L)
	v.fill(-1, 4, 3, 0, 5, 4, BONE)
	return v.mesh(U * 1.4, Vector3(0.5, 1.5, 0.5))


## The rotary gun's drum: six barrels round a spindle, pointing -z (it
## spins about z).
static func _sat_barrels() -> ArrayMesh:
	var v := Vox.new(8, 8, 12)
	v.fill(0, 3, -6, 0, 3, 0, DUSK_D)
	for k in 6:
		var a := TAU * k / 6.0
		var x := int(round(cos(a) * 2.2))
		var y := int(round(sin(a) * 2.2)) + 3
		v.fill(x, y, -6, x, y, 0, STEEL_L if k % 2 == 0 else STEEL_M)
	v.fill(-3, 0, 0, 3, 6, 0, DUSK)
	return v.mesh(U * 1.4, Vector3(0.5, 3.5, 0.5))
