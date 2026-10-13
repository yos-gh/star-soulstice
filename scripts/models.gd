class_name Models
extends RefCounted
## Every voxel model in the game, built in code. Units are drawn as
## pixel-art sprites seen from above (Vox.paint / paint_sym) at one common
## voxel size (PX), then given height and a few 3D details, so the whole
## cast reads like hi-res pixel art. Model space: x right, y up, -z forward.
##
## Palette: the player is polished white/cobalt, enemies gunmetal with
## crimson armour and red emissive eyes, items glow. Colour alpha is the
## surface finish (1 matte .. 0 polished metal, see shaders/vox.gdshader).

const PX := 0.11

# player
const HULL := Color(0.88, 0.9, 0.94, 0.45)
const HULL_M := Color(0.66, 0.7, 0.77, 0.5)
const HULL_D := Color(0.4, 0.43, 0.5, 0.55)
const COBALT := Color(0.18, 0.38, 0.86, 0.4)
const COBALT_D := Color(0.1, 0.2, 0.48, 0.55)
const INK := Color(0.09, 0.1, 0.13, 0.8)
const CANOPY := Color(0.3, 0.8, 1.0)
const THRUST := Color(1.0, 0.62, 0.28)
const RED := Color(0.86, 0.15, 0.13, 0.5)
const LIGHT := Color(0.45, 0.95, 1.0)
# enemies
const GUN := Color(0.43, 0.44, 0.49, 0.45)
const GUN_M := Color(0.33, 0.34, 0.39, 0.45)
const GUN_D := Color(0.19, 0.19, 0.23, 0.6)
const CRIM := Color(0.68, 0.1, 0.14, 0.45)
const CRIM_L := Color(0.86, 0.22, 0.24, 0.45)
const CRIM_D := Color(0.36, 0.05, 0.09, 0.6)
const EYE := Color(1.0, 0.16, 0.26)
const AMBER := Color(1.0, 0.6, 0.16)
const HAZARD := Color(0.86, 0.68, 0.14, 0.7)
const VIOLET := Color(0.62, 0.3, 1.0)
# misc (kept for callers)
const WHITE := HULL
const STEEL := GUN
const CRIMSON := CRIM
const PLUM := GUN_M
const GREEN := Color(0.35, 1.0, 0.5)
const YELLOW := Color(1.0, 0.85, 0.3)

const P_PAL := {
	"W": [HULL, 2], "w": [HULL, 1], "M": [HULL_M, 2], "m": [HULL_M, 1], "D": [HULL_D, 2], "d": [HULL_D, 1],
	"B": [COBALT, 2], "b": [COBALT_D, 1], "K": [INK, 2], "k": [INK, 1], "R": [RED, 2], "r": [RED, 1],
	"E": [THRUST, 1, true], "C": [CANOPY, 1, true], "L": [LIGHT, 1, true], "S": [HULL_M, 1], "F": [COBALT, 3],
}
const E_PAL := {
	"G": [GUN, 2], "g": [GUN_M, 1], "H": [GUN_M, 2], "d": [GUN_D, 1], "D": [GUN_D, 2],
	"C": [CRIM, 2], "c": [CRIM_D, 1], "X": [CRIM_L, 2], "K": [INK, 2], "k": [INK, 1],
	"E": [EYE, 1, true], "A": [AMBER, 1, true], "Y": [HAZARD, 1], "T": [GUN, 3], "t": [GUN_M, 3],
}


static func build(name: String) -> ArrayMesh:
	match name:
		"ship0":
			return _ship(0)
		"ship1":
			return _ship(1)
		"ship2":
			return _ship(2)
		"dart":
			return _dart()
		"swirl":
			return _swirl()
		"rammer":
			return _rammer()
		"container":
			return _container()
		"turret_base":
			return _turret_base()
		"turret_head":
			return _turret_head()
		"bulwark":
			return _bulwark()
		"lazaro_piece":
			return _lazaro_piece()
		"lazaro_core":
			return _lazaro_core()
		"boss_hull":
			return _boss_hull()
		"boss_pod":
			return _boss_pod()
		"boss_eye":
			return _boss_eye()
		"boss_shutter":
			return _boss_shutter()
		"energy":
			return _energy()
		"power":
			return _power()
		"star":
			return _star()
		"tile0":
			return _tile(0)
		"tile1":
			return _tile(1)
		"tile2":
			return _tile(2)
		"rock_a":
			return _rock(11, 1.0)
		"rock_b":
			return _rock(23, 1.4)
	push_error("unknown model " + name)
	return ArrayMesh.new()


# ------------------------------------------------------------ player

## The three forms (Star Soldier style): Form I a slim delta, Form II adds
## cannon pods and a tail gun, Form III spreads long wings with wingtip
## emitters and twin fins.
static func _ship(lvl: int) -> ArrayMesh:
	var v := Vox.new(30, 6, 26)
	v.paint_sym([
		"........W",
		".......mW",
		".......WW",
		"......mWW",
		"......WWW",
		"......BWW",
		".....mBWW",
		".....mBWW",
		"....bbBWW",
		"...bbbBWW",
		"..bbbbBWW",
		".bbbbbBWW",
		"RbbbbbBWW",
		"RbbbbBBKW",
		"r..kKKBKW",
		"....kKDKW",
		"......E.k",
	], P_PAL, 0)
	# canopy and spine
	v.paint_sym([
		".........",
		".........",
		".........",
		"........C",
		".......CC",
		".......CC",
		"........C",
		"........S",
		"........S",
		"........S",
		"........S",
		"........S",
		"........S",
		".......FS",
		".......F.",
		".........",
		".........",
	], P_PAL, 2)
	if lvl >= 1:
		# cannon pods, intakes and a tail gun
		v.fill_sym(4, 0, -4, 4, 1, 4, HULL_D)
		v.fill_sym(4, 2, -3, 4, 2, 3, HULL_M)
		v.fill_sym(4, 1, -5, 4, 1, -5, LIGHT, true)
		v.fill_sym(5, 0, -1, 5, 1, 3, COBALT)
		v.fill(0, 0, 8, 0, 1, 9, HULL_D)
		v.fill(0, 1, 10, 0, 1, 10, LIGHT, true)
	if lvl >= 2:
		# long swept wings, wingtip emitters, canards, twin fins
		v.paint_sym([
			"..............",
			"..............",
			"..............",
			"..............",
			"..........BB..",
			"..........bB..",
			"..............",
			"..............",
			"..............",
			"......bbb.....",
			".....bbbbb....",
			"...bbbbbbb....",
			"..BbbbbbBb....",
			".LBbbbbBb.....",
			"DDRRbbb.......",
			"Dd............",
			"..............",
		], P_PAL, 0)
		v.fill_sym(3, 2, 2, 3, 4, 5, COBALT)
		v.fill_sym(3, 4, 5, 3, 4, 5, RED)
	return v.mesh(PX, Vector3(0.5, 1.5, 0.5))


# ------------------------------------------------------------ enemies

static func _dart() -> ArrayMesh:
	var v := Vox.new(16, 5, 16)
	v.paint_sym([
		"......X",
		"......C",
		".....cC",
		".....gC",
		"....gGE",
		"...dgGE",
		"..ddgGG",
		".dcdgGG",
		"dCcdgGG",
		"dcd.gHG",
		"dd...KG",
		".....kA",
	], E_PAL, 0)
	v.fill(0, 2, -1, 0, 2, 2, GUN_M)
	return v.mesh(PX, Vector3(0.5, 1.0, 0.5))


## Saucer drone: armoured rim, a ring of red lights, crimson dome and eye.
static func _swirl() -> ArrayMesh:
	var v := Vox.new(18, 6, 18)
	for z in range(-8, 9):
		for x in range(-8, 9):
			var r := Vector2(x, z).length()
			if r > 8.3:
				continue
			var a := atan2(z, x)
			if r > 7.2:
				v.fill(x, 0, z, x, 0, z, GUN_D)
			elif r > 5.6:
				var lamp := absf(wrapf(a * 8.0 / TAU, -0.5, 0.5)) < 0.2 and r > 6.3 and r < 7.0
				v.fill(x, 0, z, x, 1, z, GUN if not lamp else EYE, lamp)
			elif r > 4.6:
				v.fill(x, 0, z, x, 1, z, GUN_D)
			elif r > 2.2:
				v.fill(x, 0, z, x, 2, z, CRIM if int(round(a * 6.0 / TAU)) % 2 == 0 else CRIM_D)
			else:
				v.fill(x, 0, z, x, 3, z, CRIM_L)
	v.fill(-1, 4, -1, 1, 4, 1, EYE, true)
	return v.mesh(PX, Vector3(0.5, 2.0, 0.5))


## Ram pod: a drill-nosed armoured wedge.
static func _rammer() -> ArrayMesh:
	var v := Vox.new(16, 6, 18)
	v.paint_sym([
		"......d",
		"......D",
		".....dG",
		".....GG",
		"....HGG",
		"...CCGE",
		"..CXCGE",
		".CXccGG",
		"CXcc.GG",
		"Ccc..GG",
		"dc...HG",
		"d...kKK",
		".....AK",
	], E_PAL, 0)
	v.paint_sym([
		".......",
		".......",
		".......",
		".......",
		"......G",
		"......k",
		"......k",
		"......G",
		"......G",
		"......g",
		".......",
		".......",
		".......",
	], E_PAL, 2)
	return v.mesh(PX, Vector3(0.5, 1.5, 0.5))


## Cargo pod: chamfered armour box with hazard bands and amber beacons.
static func _container() -> ArrayMesh:
	var v := Vox.new(16, 10, 16)
	for z in range(-7, 7):
		for x in range(-7, 7):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			if ax + az > 11.0:
				continue
			var edge := ax > 5.5 or az > 5.5 or ax + az > 9.5
			var top := 7 if not edge else 6
			for y in range(0, top + 1):
				var c := GUN_M
				if edge and (y == 2 or y == 4):
					c = HAZARD if int(ax + az) % 2 == 0 else INK
				elif not edge and y == top:
					c = GUN if (int(ax) + int(az)) % 4 != 0 else GUN_D
				elif edge and y == top:
					c = GUN_D
				v.put(x, y, z, c)
	for s: Vector2i in [Vector2i(-4, -4), Vector2i(3, -4), Vector2i(-4, 3), Vector2i(3, 3)]:
		v.put(s.x, 8, s.y, AMBER, true)
	v.fill(-1, 8, -1, 0, 8, 0, HAZARD)
	return v.mesh(PX * 1.2, Vector3(0, 4.0, 0))


static func _turret_base() -> ArrayMesh:
	var v := Vox.new(16, 3, 16)
	for z in range(-8, 8):
		for x in range(-8, 8):
			var r := Vector2(x + 0.5, z + 0.5).length()
			if r < 7.6:
				v.put(x, 0, z, GUN_D)
			if r < 6.4:
				v.put(x, 1, z, GUN_M if r > 5.2 else (GUN_D if absf(r - 3.6) < 0.6 else GUN_M.lightened(0.05)))
			if r > 6.5 and r < 7.6 and (x + z) % 3 == 0:
				v.put(x, 1, z, HAZARD)
	return v.mesh(PX)


## Twin-barrelled gun head (turns as a separate mesh).
static func _turret_head() -> ArrayMesh:
	var v := Vox.new(12, 5, 18)
	v.paint_sym([
		".....",
		".....",
		".....",
		".....",
		"...dG",
		"..CXC",
		".CCXE",
		".CCCC",
		".cCCC",
		"..ccc",
	], E_PAL, 0, 2)
	v.fill_sym(1, 1, -7, 1, 1, -1, GUN)
	v.fill_sym(1, 1, -8, 1, 1, -8, AMBER, true)
	return v.mesh(PX, Vector3(0.5, 0, 0.5))


## Mid-size gunship (faces down-screen): armoured hull, wing gun decks,
## a glowing reactor slot and gun rows along the front.
static func _bulwark() -> ArrayMesh:
	var v := Vox.new(48, 8, 32)
	# central hull: tall armour with a reactor slot
	v.fill_sym(0, 0, -12, 4, 4, 11, GUN_M)
	v.fill_sym(0, 5, -9, 3, 5, 8, GUN)
	v.fill_sym(0, 5, -6, 0, 5, 5, EYE, true)
	v.fill_sym(1, 5, -6, 1, 5, 5, INK)
	v.fill_sym(2, 6, -7, 3, 6, -2, CRIM)
	v.fill_sym(2, 6, 1, 3, 6, 6, CRIM)
	v.fill_sym(0, 0, 12, 2, 3, 13, GUN_D)
	v.fill_sym(0, 2, 14, 1, 2, 14, EYE, true)
	# inner wings with armour plates
	for k in range(5, 13):
		v.fill_sym(k, 0, -9 + (k - 5), k, 2, 9, GUN_M)
	v.fill_sym(5, 3, -4, 11, 3, 7, CRIM)
	v.fill_sym(6, 3, -2, 10, 3, 5, CRIM_D)
	v.fill_sym(5, 3, 8, 11, 3, 8, INK)
	# outer gun decks
	v.fill_sym(13, 0, -2, 20, 2, 10, GUN)
	v.fill_sym(14, 3, 0, 19, 3, 8, GUN_M)
	v.fill_sym(21, 0, 1, 22, 1, 9, GUN_D)
	v.fill_sym(22, 2, 2, 22, 2, 2, AMBER, true)
	# gun rows along the front edge
	for x in [6, 9, 12, 15, 18]:
		v.fill_sym(x, 1, 10, x, 1, 13, GUN_D)
		v.fill_sym(x, 1, 14, x, 1, 14, EYE, true)
	# engine bank at the back
	v.fill_sym(1, 1, -13, 3, 2, -13, AMBER, true)
	v.fill_sym(7, 1, -8, 8, 1, -8, AMBER, true)
	v.fill_sym(15, 1, -3, 18, 1, -3, AMBER, true)
	return v.mesh(PX * 1.15, Vector3(0.5, 3.0, 0.5))


## One quarter of Lazaro's shell: the +x/+z quadrant of a hollow sphere
## in armour plates with glowing seams, re-centred on its own centroid so
## the pieces can fly apart.
static func _lazaro_piece() -> ArrayMesh:
	var v := Vox.new(26, 16, 26)
	var r := 10.5
	for z in range(0, 12):
		for y in range(-8, 8):
			for x in range(0, 12):
				var p := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var d := p.length()
				if d > r or d < r - 3.2:
					continue
				var c := GUN_D
				var glow := false
				var lat := asin(clampf(p.y / d, -1.0, 1.0)) / 0.62
				var lon := atan2(p.z, p.x) / 0.52
				var seam := absf(lat - round(lat)) < 0.09 or absf(lon - round(lon)) < 0.1
				if d > r - 1.3:
					c = INK if seam else (CRIM if int(floor(lat) + floor(lon)) % 3 != 0 else CRIM_L)
				if y == -1 or y == 0:
					c = EYE
					glow = true
				if x == 0 or z == 0:
					c = GUN_D
					glow = false
				v.put(x, y + 8, z, c, glow)
	return v.mesh(0.18, Vector3(4.0, 8.0, 4.0))


static func _lazaro_core() -> ArrayMesh:
	var v := Vox.new(12, 12, 12)
	v.blob(0, 6, 0, 4.6, 4.6, 4.6, AMBER, true)
	v.blob(0, 6, 0, 2.6, 2.6, 5.2, Color(1.0, 0.95, 0.7), true)
	for a in 8:
		var x := int(round(cos(a * TAU / 8.0) * 5.0))
		var z := int(round(sin(a * TAU / 8.0) * 5.0))
		v.fill(x, 2, z, x, 9, z, GUN_D)
	return v.mesh(0.18, Vector3(0, 6.5, 0), true)


# ------------------------------------------------------------ boss

## STAR CORTEX hull: an octagonal fortress (faces down-screen) with plated
## armour, gun decks on the flanks and a channel in front of the eye, so
## shots fired from below can reach it.
static func _boss_hull() -> ArrayMesh:
	var v := Vox.new(120, 11, 88)
	for z in range(-44, 44):
		for x in range(-60, 60):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			var oct := maxf(maxf(ax / 57.0, az / 42.0), (ax + az) / 76.0)
			if oct > 1.0 or oct < 0.36:
				continue
			# front channel to the eye
			if ax < 11.0 and z > 0:
				continue
			var h := 4
			if oct < 0.5:
				h = 8
			elif oct < 0.66:
				h = 7
			elif oct < 0.84:
				h = 6
			if oct > 0.94:
				h = 3
			var top := GUN_M
			var plate := (int(ax) / 9 + int(az) / 7) % 2 == 0
			if not plate:
				top = GUN_M.lightened(0.07)
			if int(ax) % 9 == 0 or int(az) % 7 == 0:
				top = GUN_D
			if oct < 0.42:
				top = CRIM_D
			elif oct > 0.94:
				top = GUN_D
			elif absf(oct - 0.66) < 0.012 or absf(oct - 0.84) < 0.012:
				top = INK
			for y in h:
				v.put(x, y, z, top if y == h - 1 else (GUN_M if y > 1 else GUN_D))
	# channel edges, gun decks, rim lights, spine
	for z in range(1, 34):
		if z % 4 == 0:
			v.put(-12, 5, z, EYE, true)
			v.put(11, 5, z, EYE, true)
	for s in [-1, 1]:
		v.fill(s * 30, 7, -10, s * 44, 8, 8, GUN)
		v.fill(s * 31, 9, -8, s * 43, 9, 6, CRIM)
		for z in [-6, -1, 4]:
			v.fill(s * 34, 9, z, s * 40, 9, z, INK)
		v.fill(s * 45, 6, -3, s * 50, 6, 2, GUN_D)
		v.fill(s * 50, 6, -3, s * 50, 6, 2, AMBER, true)
	for a in 24:
		var ang := a * TAU / 24.0
		var x := int(round(cos(ang) * 23.0))
		var z := int(round(sin(ang) * 17.0))
		if absf(x) < 12 and z > 0:
			continue
		v.put(x, 8, z, EYE, true)
	v.fill(-3, 7, -43, 2, 9, -30, GUN)
	v.fill(-1, 9, -43, 0, 9, -36, AMBER, true)
	return v.mesh(PX, Vector3(0.5, 6.0, 0.5))


static func _boss_pod() -> ArrayMesh:
	var v := Vox.new(26, 8, 30)
	for z in range(-12, 13):
		for x in range(-12, 13):
			var r := Vector2(x, z).length()
			if r > 12.4:
				continue
			var h := 2 if r > 10.5 else (4 if r > 7.0 else 5)
			for y in h:
				var c := GUN_M
				if y == h - 1:
					c = GUN if r > 10.5 else (CRIM if r > 7.0 else GUN)
					if absf(r - 8.8) < 0.6:
						c = INK
				v.put(x, y, z, c)
	v.fill_sym(1, 3, 6, 2, 4, 13, GUN_D)
	v.fill_sym(1, 4, 14, 2, 4, 14, EYE, true)
	v.fill(-2, 5, -2, 2, 6, 2, GUN_D)
	v.fill(-1, 7, -1, 1, 7, 1, EYE, true)
	return v.mesh(PX, Vector3(0.5, 3.0, 0.5))


static func _boss_eye() -> ArrayMesh:
	var v := Vox.new(36, 14, 36)
	for z in range(-17, 18):
		for x in range(-17, 18):
			var r := Vector2(x, z).length()
			if r > 17.0:
				continue
			var h := int(round(sqrt(maxf(0.0, 17.5 * 17.5 - r * r)) * 0.55))
			for y in h:
				var c := Color(0.82, 0.8, 0.78, 0.4)
				var glow := false
				if y == h - 1:
					if r < 4.0:
						c = Color(0.05, 0.0, 0.03)
					elif r < 9.0:
						c = Color(1.0, 0.22, 0.5) if int(r * 1.5) % 2 == 0 else Color(0.85, 0.1, 0.35)
						glow = true
					elif r < 10.5:
						c = INK
				v.put(x, y, z, c, glow)
	return v.mesh(PX, Vector3(0.5, 5.0, 0.5))


## One half of the eye's armoured shutter (the left half; mirrored by scale).
static func _boss_shutter() -> ArrayMesh:
	var v := Vox.new(40, 4, 40)
	for z in range(-19, 20):
		for x in range(-20, 0):
			var d := Vector2(x + 0.5, z).length()
			if d >= 19.5:
				continue
			var c := GUN if (z + 20) % 6 > 1 else GUN_M
			var glow := false
			if x == -1:
				c = AMBER
				glow = true
			elif d > 17.5:
				c = GUN_D
			v.put(x, 0, z, c, glow)
			if d < 15.0 and x < -2:
				v.put(x, 1, z, CRIM_D if (z + 20) % 6 > 1 else INK)
	return v.mesh(PX, Vector3(0, 0, 0.5))


# ------------------------------------------------------------ items

static func _energy() -> ArrayMesh:
	var v := Vox.new(4, 6, 4)
	v.jitter = 0.0
	# a lit crystal with a dim self-lit band: readable, but no bloom
	var body := Color(0.34, 0.66, 0.5, 0.3)
	var band := Color(0.3, 0.72, 0.46)
	v.fill(-1, 1, -1, 0, 4, 0, body)
	v.fill(-2, 2, -1, 1, 3, 0, band, true)
	v.fill(-1, 2, -2, 0, 3, 1, band, true)
	v.fill(-1, 0, -1, 0, 0, 0, body.darkened(0.2))
	v.fill(-1, 5, -1, 0, 5, 0, body.lightened(0.2))
	return v.mesh(0.09, Vector3(0, 3.0, 0), true)


## Power capsule: cobalt shell, glowing core band and a "P" on top.
static func _power() -> ArrayMesh:
	var v := Vox.new(16, 6, 10)
	v.paint([
		"...DDDDDDDD...",
		"..DBBBBBBBBD..",
		".DBBBBBBBBBBD.",
		"DLLLLLLLLLLLLD",
		"DLLLLLLLLLLLLD",
		".DBBBBBBBBBBD.",
		"..DBBBBBBBBD..",
		"...DDDDDDDD...",
	], {"D": [HULL_D, 2], "B": [COBALT, 3], "L": [LIGHT, 2, true]}, 0)
	v.paint([
		"..............",
		".....WWW......",
		".....W..W.....",
		".....WWW......",
		".....W........",
		".....W........",
		"..............",
		"..............",
	], {"W": [HULL, 1]}, 3)
	return v.mesh(0.13, Vector3(0, 2.0, 0.5))


static func _star() -> ArrayMesh:
	var v := Vox.new(12, 3, 12)
	for z in range(-6, 6):
		for x in range(-6, 6):
			var p := Vector2(x + 0.5, z + 0.5)
			var a := atan2(p.y, p.x) + PI / 2.0
			var lobe := 0.5 + 0.5 * cos(5.0 * a)
			if p.length() < 2.4 + 3.4 * pow(lobe, 2.0):
				v.put(x, 1, z, YELLOW, true)
				if p.length() < 2.0:
					v.put(x, 2, z, Color(1.0, 0.97, 0.8), true)
	return v.mesh(0.1, Vector3(0, 1.5, 0), true)


# ------------------------------------------------------------ ground

## Destructible armour tile (one Island cell, 16 x 16 voxels) seated in a
## deck socket. Shaded like pixel art: light top-left bevel, dark
## bottom-right bevel. 0 thin hatch (green LED), 1 plated hatch (amber),
## 2 heavy armour (red LED).
static func _tile(kind: int) -> ArrayMesh:
	var v := Vox.new(16, 5, 16)
	var base: Color = [Color(0.25, 0.3, 0.33, 0.8), Color(0.33, 0.28, 0.21, 0.75), Color(0.2, 0.2, 0.23, 0.6)][kind]
	var hi := base.lightened(0.2)
	var lo := base.darkened(0.42)
	var led: Color = [Color(0.3, 1.0, 0.5), AMBER, EYE][kind]
	var h := 2 + kind
	v.fill(-8, 0, -8, 7, h - 2, 7, lo)
	v.fill(-7, h - 1, -7, 6, h - 1, 6, base)
	v.fill(-7, h - 1, -7, 6, h - 1, -7, hi)
	v.fill(-7, h - 1, -7, -7, h - 1, 6, hi)
	v.fill(-7, h - 1, 6, 6, h - 1, 6, lo)
	v.fill(6, h - 1, -7, 6, h - 1, 6, lo)
	match kind:
		0:
			for z in [-4, -2, 0, 2]:
				v.fill(-4, h - 1, z, 3, h - 1, z, lo)
			v.put(4, h - 1, 4, led, true)
		1:
			v.fill(-7, h - 1, -1, 6, h - 1, 0, lo)
			v.fill(-1, h - 1, -7, 0, h - 1, 6, lo)
			for c: Vector2i in [Vector2i(-4, -4), Vector2i(3, -4), Vector2i(-4, 3), Vector2i(3, 3)]:
				v.fill(c.x, h, c.y, c.x, h, c.y, hi)
			v.put(4, h - 1, 4, led, true)
		2:
			v.fill(-5, h, -5, 4, h, 4, base.lightened(0.08))
			v.fill(-5, h, -5, 4, h, -5, hi)
			v.fill(-5, h, -5, -5, h, 4, hi)
			v.fill(-1, h, -5, 0, h, 4, lo)
			v.fill(-5, h, -1, 4, h, 0, lo)
			v.fill(-1, h, -1, 0, h, 0, led, true)
	return v.mesh(0.125)


## Background asteroid chunk (drawn far below, blurred).
static func _rock(seed: int, s: float) -> ArrayMesh:
	var v := Vox.new(16, 12, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	v.blob(0, 6, 0, 6.5 * s / 1.4, 5.0, 6.0, Color(0.17, 0.16, 0.18))
	for i in 7:
		v.blob(rng.randi_range(-5, 5), rng.randi_range(3, 9), rng.randi_range(-5, 5), rng.randf_range(1.5, 3.0), rng.randf_range(1.5, 2.5), rng.randf_range(1.5, 3.0), Color(0.21, 0.2, 0.22))
	return v.mesh(0.8, Vector3(0, 6, 0))
