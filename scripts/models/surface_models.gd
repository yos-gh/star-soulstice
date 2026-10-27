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
	"surface_basin_a", "surface_basin_b", "surface_basin_c", "surface_basin_gate",
	"gorgon_hull", "gorgon_crater", "gorgon_eye", "gorgon_lid", "gorgon_socket", "gorgon_maw", "gorgon_gun",
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
		"gorgon_crater":
			return _gorgon_crater()
		"gorgon_eye":
			return _gorgon_eye()
		"gorgon_lid":
			return _gorgon_lid()
		"gorgon_socket":
			return _gorgon_socket()
		"gorgon_maw":
			return _gorgon_maw()
		"gorgon_gun":
			return _gorgon_gun()
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
	if variant != "gate":
		for k in (2 if variant == "b" else 1):
			var r := rng.randf_range(2.0, 4.5)
			_crater(g, rng.randf_range(-XS + 8.0, XS - 8.0), rng.randf_range(-NZ / 2 + r * 1.4 + 0.5, NZ / 2 - r * 1.4 - 0.5), r)
	_boulders(g, 6)


# ------------------------------------------------------------ GORGON

## GORGON: oxblood armour and bone on bare dark machinery, eyes and
## conduits glowing pink.
const OX := Color(0.36, 0.15, 0.15)
const OX_L := Color(0.43, 0.19, 0.18)
const OX_D := Color(0.25, 0.11, 0.11)
const BONE := Color(0.56, 0.52, 0.45)
const BONE_D := Color(0.44, 0.41, 0.35)
const G_PINK := Color(1.0, 0.36, 0.66)
const G_PINK_D := Color(0.72, 0.22, 0.48)
const GU := 0.25  # the hull's voxel
const GO := 40  # its origin row: row r's top face at (r + 1 - GO) * GU (y -10 at the bottom)


static func _gy(y: float) -> int:
	return int(round(y / GU)) + GO - 1


## The fortress (everything but its moving parts): the face over the
## crater's pit, its brows and crown, the sockets (geared rings round holes
## for the eyes), the nose of capacitor rings with conduits to the sockets,
## the maw's socket, armoured cheeks over a row of bone radiator fins (the
## teeth), bare machinery behind (two fans, a reactor dome, pipes), three
## armoured cables like snakes from each side down into the ground, and
## the silo towers round it (bores open for the guns).
static func _gorgon_hull() -> ArrayMesh:
	var gb = Bosses.KINDS["gorgon"]
	var eye_x: float = (gb.EYE_OFF[1] as Vector3).x
	var maw: Vector3 = gb.MAW_OFF
	var HX := 62
	var HZ := 44
	var W := HX * 2
	var D := HZ * 2
	var v := Vox.new(W, 37, D)
	v.jitter = 0.04
	var top := PackedInt32Array()
	top.resize(W * D)
	top.fill(-1)
	var cols: Array[Color] = []
	cols.resize(W * D)
	var glow := PackedByteArray()
	glow.resize(W * D)
	for zi in D:
		for xi in W:
			var q := Vector2((xi - HX + 0.5) * GU, (zi - HZ + 0.5) * GU)
			var ax := absf(q.x)
			var face := pow(ax / 10.2, 2.6) + pow(absf(q.y + 1.2) / 8.0, 2.6)
			if face >= 1.0:
				continue
			var h := -3.3
			var c: Color = GUN if posmod(int(floor(q.x / 1.2)) + int(floor(q.y / 1.2)), 2) == 0 else DUSK_L
			if fposmod(q.x, 1.2) < GU or fposmod(q.y, 1.2) < GU:
				c = DUSK
			var lit := false
			if face > 0.86:
				h = -3.8
				c = DUSK
			var de := Vector2(ax - eye_x, q.y).length()
			var dm := Vector2(q.x - maw.x, q.y - maw.z).length()
			# ---- bare machinery behind the brow
			if q.y < -4.6:
				var df := Vector2(ax - 4.3, q.y + 7.4).length()
				var dr := Vector2(q.x, q.y + 7.7).length()
				if df < 1.9:
					if df > 1.6:
						h = -2.5
						c = STEEL_M
					else:
						h = -3.4
						var a := fposmod(atan2(q.y + 7.4, ax - 4.3) / TAU * 7.0 + df * 0.25, 1.0)
						c = DUSK_L if a < 0.45 else DUSK_D
						if df < 0.4:
							h = -2.9
							c = STEEL_L
				elif dr < 1.6:
					h = -3.0 + 1.1 * sqrt(maxf(0.0, 1.0 - pow(dr / 1.6, 2.0)))
					c = STEEL_L if dr < 1.05 else STEEL_M
					if dr > 1.1 and dr < 1.32:
						c = G_PINK_D
						lit = true
				elif ax > 6.4 and ax < 9.2:
					var k := fposmod(ax - 6.4, 0.8)
					h = -2.8 if k < 0.5 else -3.4
					c = STEEL_M if k < 0.5 else DUSK_D
					if posmod(int(floor(q.y / 1.5)), 2) == 0 and k < 0.5 and fposmod(q.y, 1.5) < GU * 2.0:
						c = DUSK_L  # pipe clamps
			# ---- the brows (oxblood plates, bone along the inner edge)
			if de > 2.75 and de < 4.4 and q.y < -0.6 and ax > 1.2:
				h = -1.75
				var a := atan2(q.y, ax - eye_x)
				c = OX if posmod(int(floor(a * 8.0 / PI)), 2) == 0 else OX_L
				if fposmod(a * 8.0 / PI, 1.0) < 0.12:
					c = OX_D
				if de < 3.05:
					c = BONE
					h = -1.6
			# ---- the crown between them, a bone crest down the middle
			if ax < 2.8 and q.y > -5.4 and q.y < -2.4:
				h = -1.6
				c = OX if fposmod(q.y, 1.0) > GU else OX_D
				if ax < 0.3:
					h = -1.35
					c = BONE
			# ---- the nose: capacitor rings up a spine
			if ax < 1.25 and q.y >= -2.4 and q.y < 2.2:
				var band := fposmod(q.y + 2.4, 0.8)
				h = -2.0 if band > GU else -1.85
				c = STEEL_M if band > GU else BONE_D
				if band > GU * 1.5 and band < GU * 2.5 and ax < 0.3:
					c = G_PINK
					lit = true
			# ---- conduits from the nose to the sockets
			if absf(q.y - 0.2) < 0.22 and ax >= 1.25 and ax < 2.8:
				h = -2.9
				c = G_PINK_D
				lit = true
			# ---- the cheeks
			if ax > 2.2 and ax < 8.9 and q.y > 1.4 and q.y < 5.0 and de > 2.75 and dm > 1.95:
				h = -2.3 - floor((ax - 2.2) / 2.2) * 0.25
				c = OX if posmod(int(floor(ax / 1.2)) + int(floor(q.y / 1.2)), 2) == 0 else OX_L
				if fposmod(ax, 1.2) < GU or fposmod(q.y, 1.2) < GU:
					c = OX_D
				if ax > 8.4:
					c = BONE_D
			# ---- the teeth: bone radiator fins under the cheeks
			if q.y >= 5.0 and q.y < 6.4 and ax < 7.8 and dm > 1.95:
				if fposmod(ax, 0.5) < 0.25:
					h = -2.15 - ax * 0.06 - (0.25 if q.y > 6.0 else 0.0)
					c = BONE if q.y < 5.9 else BONE_D
				else:
					h = -3.5
					c = DUSK_D
			# ---- the sockets (holes for the eyes, geared rings round them)
			if de < 2.75:
				if de < 1.92:
					h = -4.4
					c = DUSK_D
				elif de < 2.5:
					h = -2.0
					var a := atan2(q.y, ax - eye_x)
					c = STEEL_M if posmod(int(floor(a * 14.0 / PI)), 2) == 0 else DUSK
				else:
					h = -2.5
					c = GUN
			# ---- the maw's socket
			if dm < 1.95:
				if dm < 1.3:
					h = -4.2
					c = DUSK_D
				else:
					h = -2.7
					var a := atan2(q.y - maw.z, q.x)
					c = STEEL_L if posmod(int(floor(a * 8.0 / PI)), 2) == 0 and dm > 1.6 else DUSK_L
			var i := zi * W + xi
			top[i] = _gy(h)
			cols[i] = c
			glow[i] = 1 if lit else 0
	# fill each column down to its lowest neighbour (open sides down into
	# the pit)
	var pit := _gy(-8.6)
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
				lo = mini(lo, nh if nh >= 0 else pit)
			var c: Color = cols[i]
			for y in range(maxi(0, lo - 1), h + 1):
				v.put(xi - HX, y, zi - HZ, c if y == h else (DUSK if y > h - 3 else DUSK_D), glow[i] == 1 and y == h)
	# the silo towers round the rim
	for o: Vector3 in gb.SILO_OFF:
		_silo_tower(v, Vector2(o.x, o.z))
	# the snake cables: from the temples and jaws down into the ground
	for s: float in [-1.0, 1.0]:
		for hose: Array in [[Vector3(7.0, -2.6, -4.4), Vector3(9.8, -3.0, -8.2), Vector3(12.8, -7.5, -9.2)],
				[Vector3(9.4, -3.0, -1.0), Vector3(12.0, -3.2, -1.8), Vector3(15.0, -8.0, -1.5)],
				[Vector3(8.8, -3.0, 3.6), Vector3(11.6, -3.4, 3.4), Vector3(13.8, -8.0, 5.0)]]:
			var a: Vector3 = hose[0]
			var b: Vector3 = hose[1]
			var c: Vector3 = hose[2]
			_hose(v, Vector3(s * a.x, a.y, a.z), Vector3(s * b.x, b.y, b.z), Vector3(s * c.x, c.y, c.z))
	return v.mesh(GU, Vector3(0, GO, 0))


## A silo tower at plane point o: a steel drum up from the pit to just
## under the guns' height, an oxblood band and bone bolts round its top,
## its bore open (the gun waits down in it).
static func _silo_tower(v: Vox, o: Vector2) -> void:
	var cx := int(round(o.x / GU))
	var cz := int(round(o.y / GU))
	var top_r := _gy(-2.7)
	var foot := _gy(-8.2)
	var floor_r := _gy(-6.2)
	for dz in range(-8, 9):
		for dx in range(-8, 9):
			var r := Vector2(dx, dz).length() * GU
			if r > 1.95:
				continue
			var a := atan2(float(dz), float(dx))
			var y1 := top_r if r <= 1.4 else foot  # the flared foot
			for y in range(_gy(-9.2), y1 + 1):
				var c: Color = GUN if posmod(y, 6) != 0 else DUSK_L
				if r < 0.9:
					if y > floor_r:
						continue
					c = DUSK_D
				elif y == top_r:
					c = BONE_D if fposmod(a * 6.0 / PI, 1.0) < 0.22 else STEEL_M
				elif y >= top_r - 3:
					c = OX_D if y == top_r - 3 else OX
				elif r < 1.1 and y > top_r - 6:
					c = DUSK
				v.put(cx + dx, y, cz + dz, c)


## A cable from a to c (curving toward b): armoured rings along it.
static func _hose(v: Vox, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := 60
	for k in n + 1:
		var t := float(k) / n
		var p := a.lerp(b, t).lerp(b.lerp(c, t), t)
		var ring := k % 4 == 0
		var r := (0.48 if ring else 0.4) / GU
		var col: Color = DUSK_L if ring else (OX_D if k % 8 < 4 else DUSK)
		v.blob(int(round(p.x / GU)), _gy(p.y), int(round(p.z / GU)), r, r, r, col)


## The crater round the fortress, in the ground's material: a raised rim
## (an ellipse round it), falling inward to the pit and outward to an
## apron that sinks just under the basin's floor (so their meeting is
## hidden), strewn with rocks.
static func _gorgon_crater() -> ArrayMesh:
	var pal: Dictionary = PALS["basin"]
	var HX := 44
	var HZ := 34
	var W := HX * 2
	var D := HZ * 2
	var v := Vox.new(W, 14, D)
	v.ground = true
	v.jitter = 0.05
	v.cull_bottom = true
	# row r's top face at (r + 1 - 22) * 0.5: row 0 at -10.5, row 13 at -4
	var top := PackedInt32Array()
	top.resize(W * D)
	var cols: Array[Color] = []
	cols.resize(W * D)
	for zi in D:
		for xi in W:
			var q := Vector2((xi - HX + 0.5) * R, (zi - HZ + 0.5) * R)
			var e := Vector2(q.x / 16.5, (q.y + 1.5) / 13.5).length()
			var y := -10.5
			if e < 0.78:
				y = -9.0
			elif e < 1.0:
				y = lerpf(-9.0, -6.0, (e - 0.78) / 0.22)
			elif e < 1.35:
				y = lerpf(-6.0, -9.5, (e - 1.0) / 0.35)
			elif e < 1.6:
				y = lerpf(-9.5, -10.6, (e - 1.35) / 0.25)
			var n := Vox._hash(xi >> 1, 61, zi >> 1)
			y += (0.5 if n > 0.8 else 0.0) - (0.5 if n < 0.12 else 0.0)
			var i := zi * W + xi
			top[i] = clampi(int(round(y / R)) + 21, 0, 13)
			var c: Color = pal["dust"]
			if e > 0.92 and e < 1.08:
				c = pal["dust_l"]
			elif e < 0.78:
				c = pal["basalt"]
			elif Vox._hash(xi, 63, zi) > 0.9:
				c = pal["rock"]
			cols[i] = c
	for zi in D:
		for xi in W:
			var i := zi * W + xi
			var h := top[i]
			var lo := h
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := xi + d.x
				var nz := zi + d.y
				if nx >= 0 and nx < W and nz >= 0 and nz < D:
					lo = mini(lo, top[nz * W + nx])
			var c: Color = cols[i]
			for y in range(maxi(0, lo - 1), h + 1):
				v.put(xi - HX, y, zi - HZ, c if y == h else c.darkened(0.2))
	return v.mesh(R, Vector3(0, 22, 0))


## An eye: a ball (radius 1.7) looking up (+y) out of its socket: a pale
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
	return v.mesh(0.1, Vector3(0, rr + 1, 0), true)


## An eyelid: an armoured shell over the -z half of the eye (the other lid
## is the same turned round), oxblood plates, a bone edge where they meet.
static func _gorgon_lid() -> ArrayMesh:
	var rr := 17  # x 0.12: 2.04
	var v := Vox.new(rr * 2 + 2, rr + 4, rr * 2 + 2)
	v.jitter = 0.04
	for z in range(-rr - 1, 1):
		for y in range(0, rr + 2):
			for x in range(-rr - 1, rr + 1):
				var p := Vector3(x + 0.5, y + 0.5 - 1.0, z + 0.5)
				var l := Vector3(p.x, p.y * 1.05, p.z).length()
				if l > rr or l < rr - 2.2:
					continue
				var c: Color = OX if posmod(int(floor(atan2(p.y, p.x) * 5.0 / PI)), 2) == 0 else OX_L
				if z >= -2:
					c = BONE
				elif posmod(int(floor(-p.z / 4.0)), 2) == 1 and absf(p.x) < 2.0:
					c = OX_D
				v.put(x, y, z, c)
	return v.mesh(0.12, Vector3(0, 1, 0))


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


## The maw: a squat mortar in its socket, a breech ring with four lugs
## (it turns) round a wide bore glowing pink inside.
static func _gorgon_maw() -> ArrayMesh:
	var v := Vox.new(30, 14, 30)
	v.jitter = 0.04
	for z in range(-15, 15):
		for x in range(-15, 15):
			var r := Vector2(x + 0.5, z + 0.5).length()
			var a := atan2(z + 0.5, x + 0.5)
			if r > 13.5:
				continue
			if r > 11.0:
				var lug := absf(wrapf(a * 4.0 / TAU, -0.5, 0.5)) < 0.14
				v.fill(x, 0, z, x, 8 if lug else 5, z, BONE_D if lug else OX)
			elif r > 7.5:
				v.fill(x, 0, z, x, 9, z, DUSK_L if posmod(int(floor(a * 12.0 / PI)), 2) == 0 else GUN)
			elif r > 5.5:
				v.fill(x, 0, z, x, 11, z, STEEL_M)
				v.put(x, 12, z, STEEL_L)
			else:
				v.fill(x, 0, z, x, 2, z, G_PINK if r < 3.5 else G_PINK_D, true)
	return v.mesh(0.12, Vector3(0.5, 4.0, 0.5), true)


## A silo gun: an oxblood dome with twin barrels forward (-z), on a steel
## piston column that runs down into the silo.
static func _gorgon_gun() -> ArrayMesh:
	var v := Vox.new(18, 36, 24)
	v.jitter = 0.04
	# the column
	for y in range(0, 26):
		for z in range(-3, 3):
			for x in range(-3, 3):
				v.put(x, y, z, STEEL_M if posmod(y, 4) != 0 else DUSK)
	# the dome on a dark ring
	v.fill(-8, 25, -8, 7, 26, 7, DUSK)
	for x in range(-8, 8):
		for z in range(-8, 8):
			if Vector2(x + 0.5, z + 0.5).length() > 8.0:
				v.erase(x, 25, z)
				v.erase(x, 26, z)
	v.blob(0, 28, 0, 7.5, 4.5, 7.5, OX_D)
	v.blob(0, 30, 1, 5.5, 3.0, 5.5, OX)
	v.blob(0, 32, 2, 2.5, 1.0, 2.5, DUSK_L)
	# twin barrels forward, a sight between them
	for s: int in [-3, 2]:
		v.fill(s, 28, -11, s + 1, 29, -5, GUN)
		v.fill(s, 28, -11, s + 1, 29, -11, DUSK_D)
	v.put(0, 32, -4, BONE)
	v.put(-1, 32, -4, BONE)
	return v.mesh(0.1, Vector3(0.5, 27.0, 0.5))
