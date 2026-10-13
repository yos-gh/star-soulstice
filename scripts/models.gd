class_name Models
extends RefCounted
## Every voxel model in the game, built in code with Vox. Model space:
## x right, y up, -z forward (nose). Player colours are white/blue, enemies
## crimson/violet, items glow, so the two sides never read alike.

const WHITE := Color(0.88, 0.9, 0.94)
const GREY := Color(0.56, 0.6, 0.66)
const DARK := Color(0.24, 0.26, 0.31)
const BLUE := Color(0.2, 0.42, 0.9)
const NAVY := Color(0.13, 0.19, 0.42)
const RED := Color(0.9, 0.2, 0.18)
const ORANGE := Color(1.0, 0.55, 0.15)
const CYAN := Color(0.35, 0.9, 1.0)
const YELLOW := Color(1.0, 0.85, 0.3)
const GREEN := Color(0.35, 1.0, 0.5)
const MAGENTA := Color(1.0, 0.28, 0.72)
const CRIMSON := Color(0.62, 0.12, 0.2)
const WINE := Color(0.36, 0.08, 0.16)
const VIOLET := Color(0.42, 0.26, 0.66)
const PLUM := Color(0.24, 0.14, 0.36)
const STEEL := Color(0.46, 0.44, 0.5)


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
		"shell":
			return _shell()
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


## The player ship in its three forms (Star Soldier style: it grows wings,
## pods and fins as it powers up).
static func _ship(lvl: int) -> ArrayMesh:
	var v := Vox.new(22, 6, 24)
	var span := 5 + lvl
	# fuselage
	v.fill_sym(0, 1, -9, 0, 2, 9, WHITE)
	v.fill_sym(1, 1, -6, 1, 2, 8, WHITE)
	v.fill_sym(0, 1, -11, 0, 1, -10, WHITE)
	v.fill_sym(0, 0, -7, 1, 0, 7, GREY)
	v.fill_sym(0, 3, -5, 0, 3, -2, CYAN, true)
	v.fill_sym(0, 3, -1, 0, 3, 4, BLUE)
	v.fill_sym(2, 1, -3, 2, 2, 7, BLUE)
	# swept wings
	for k in range(3, span + 1):
		v.fill_sym(k, 1, k - 4, k, 1, 6, BLUE)
	v.fill_sym(3, 1, 4, span, 1, 6, NAVY)
	v.fill_sym(span, 1, 1, span, 2, 6, RED)
	# engines
	v.fill_sym(0, 1, 10, 1, 2, 10, ORANGE, true)
	if lvl >= 1:
		# side cannons and a tail gun
		v.fill_sym(3, 1, -8, 3, 2, -2, GREY)
		v.fill_sym(3, 1, -9, 3, 1, -9, CYAN, true)
		v.fill_sym(0, 3, 5, 0, 3, 9, GREY)
		v.fill_sym(0, 3, 10, 0, 3, 10, CYAN, true)
	if lvl >= 2:
		# canards, twin fins and wing pods
		v.fill_sym(4, 1, -7, 5, 1, -5, BLUE)
		v.fill_sym(span - 2, 2, 4, span - 2, 4, 7, RED)
		v.fill_sym(span + 1, 1, -2, span + 1, 2, 5, WHITE)
		v.fill_sym(span + 1, 1, -3, span + 1, 1, -3, CYAN, true)
		v.fill_sym(span + 1, 1, 6, span + 1, 1, 6, ORANGE, true)
	return v.mesh(0.1, Vector3(0, 1.5, 0))


static func _dart() -> ArrayMesh:
	var v := Vox.new(12, 4, 14)
	v.fill_sym(0, 1, -6, 0, 2, 5, CRIMSON)
	v.fill_sym(1, 1, -3, 1, 1, 4, WINE)
	for k in range(1, 5):
		v.fill_sym(k, 1, k - 2, k, 1, 4, CRIMSON if k < 4 else WINE)
	v.fill_sym(4, 1, 1, 4, 2, 4, VIOLET)
	v.fill_sym(0, 3, -2, 0, 3, 1, MAGENTA, true)
	v.fill_sym(0, 1, 6, 0, 1, 6, ORANGE, true)
	return v.mesh(0.12, Vector3(0, 1.5, 0))


static func _swirl() -> ArrayMesh:
	var v := Vox.new(14, 5, 14)
	v.blob(0, 2, 0, 6.2, 1.0, 6.2, PLUM)
	v.blob(0, 3, 0, 3.0, 1.2, 3.0, VIOLET)
	for a in 8:
		var x := int(round(cos(a * TAU / 8.0) * 5.0))
		var z := int(round(sin(a * TAU / 8.0) * 5.0))
		v.put(x, 2, z, MAGENTA, true)
	v.blob(0, 4, 0, 1.2, 0.6, 1.2, CYAN, true)
	return v.mesh(0.13, Vector3(0, 2.5, 0))


static func _rammer() -> ArrayMesh:
	var v := Vox.new(12, 6, 14)
	v.blob(0, 2, 0, 3.5, 2.2, 4.5, CRIMSON)
	v.fill(0, 2, -7, 0, 2, -5, STEEL)
	v.fill_sym(3, 2, -1, 5, 2, 0, STEEL)
	v.fill_sym(2, 2, 3, 3, 2, 5, STEEL)
	v.fill(0, 4, -2, 0, 4, 1, WINE)
	v.blob(0, 2, -2, 1.3, 1.0, 1.3, RED, true)
	v.fill(0, 2, 6, 0, 2, 6, ORANGE, true)
	return v.mesh(0.13, Vector3(0, 2.5, 0))


static func _container() -> ArrayMesh:
	var v := Vox.new(12, 10, 12)
	v.fill(-5, 0, -5, 4, 7, 4, STEEL)
	v.fill(-4, 1, -6, 3, 6, 5, DARK)
	v.fill(-6, 1, -4, 5, 6, 3, DARK)
	v.fill(-4, 8, -4, 3, 8, 3, GREY)
	for y in [2, 5]:
		v.fill(-5, y, -6, 4, y, -6, YELLOW, true)
		v.fill(-5, y, 5, 4, y, 5, YELLOW, true)
		v.fill(-6, y, -4, -6, y, 3, YELLOW, true)
		v.fill(5, y, -4, 5, y, 3, YELLOW, true)
	v.fill(-1, 9, -1, 0, 9, 0, ORANGE, true)
	return v.mesh(0.15, Vector3(0, 4.5, 0))


static func _turret_base() -> ArrayMesh:
	var v := Vox.new(10, 3, 10)
	v.blob(0, 0, 0, 4.6, 0.5, 4.6, DARK)
	v.blob(0, 1, 0, 3.6, 0.5, 3.6, STEEL)
	v.fill_sym(3, 1, -1, 3, 1, 0, ORANGE, true)
	v.fill(-1, 1, 3, 0, 1, 3, ORANGE, true)
	v.fill(-1, 1, -4, 0, 1, -4, ORANGE, true)
	return v.mesh(0.12)


static func _turret_head() -> ArrayMesh:
	var v := Vox.new(8, 5, 12)
	v.blob(0, 1, 0, 2.6, 1.6, 2.6, CRIMSON)
	v.fill_sym(0, 2, -6, 0, 2, -2, GREY)
	v.fill_sym(0, 2, -6, 0, 2, -6, MAGENTA, true)
	v.put(0, 3, 0, MAGENTA, true)
	return v.mesh(0.12)


## Mid-size fighter: a wide armoured wedge with gun rows and a glowing core.
static func _bulwark() -> ArrayMesh:
	var v := Vox.new(36, 7, 24)
	v.fill_sym(0, 1, -10, 4, 4, 8, WINE)
	v.fill_sym(5, 1, -7, 9, 3, 9, CRIMSON)
	v.fill_sym(10, 1, -4, 14, 2, 10, CRIMSON)
	v.fill_sym(15, 1, -1, 17, 2, 8, WINE)
	v.fill_sym(0, 5, -6, 3, 5, 4, STEEL)
	v.fill_sym(0, 0, -8, 8, 0, 6, PLUM)
	# gun rows
	for x in [4, 8, 12, 16]:
		v.fill_sym(x, 2, 10, x, 2, 11, GREY)
		v.fill_sym(x, 2, 11, x, 2, 11, MAGENTA, true)
	v.fill_sym(0, 5, 5, 1, 5, 6, MAGENTA, true)
	v.fill_sym(0, 6, -3, 1, 6, 1, VIOLET)
	v.fill_sym(0, 3, -11, 1, 3, -11, ORANGE, true)
	v.fill_sym(6, 2, -8, 9, 2, -8, ORANGE, true)
	return v.mesh(0.14, Vector3(0, 3.5, 0))


## One quarter of Lazaro's shell: the +x/+z quadrant of a hollow sphere,
## re-centred on its own centroid so pieces can fly apart.
static func _lazaro_piece() -> ArrayMesh:
	var v := Vox.new(18, 12, 18)
	var r := 7.5
	for z in range(0, 9):
		for y in range(-6, 6):
			for x in range(0, 9):
				var d := Vector3(x + 0.5, y + 0.5, z + 0.5).length()
				if d <= r and d > r - 2.6:
					var c := CRIMSON
					if y == -1 or y == 0:
						c = MAGENTA
					elif (x + z) % 5 == 0:
						c = WINE
					v.put(x, y + 6, z, c, c == MAGENTA)
	return v.mesh(0.24, Vector3(3.0, 6.0, 3.0))


static func _lazaro_core() -> ArrayMesh:
	var v := Vox.new(10, 10, 10)
	v.blob(0, 5, 0, 4.0, 4.0, 4.0, ORANGE, true)
	v.blob(0, 5, 0, 2.2, 2.2, 4.6, YELLOW, true)
	return v.mesh(0.24, Vector3(0, 5.5, 0), true)


## STAR CORTEX hull: an octagonal fortress ring around the eye, with spines
## and gun decks; the four pods dock at the corners.
static func _boss_hull() -> ArrayMesh:
	var v := Vox.new(72, 9, 56)
	for z in range(-28, 28):
		for x in range(-36, 36):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			var oct := maxf(maxf(ax / 34.0, az / 26.0), (ax + az) / 46.0)
			if oct > 1.0:
				continue
			var inner := oct < 0.38
			if inner:
				continue
			var h := 3
			if oct < 0.5:
				h = 6
			elif oct < 0.7:
				h = 5
			elif oct < 0.86:
				h = 4
			var c := PLUM
			if oct >= 0.95:
				c = WINE
			elif (int(ax) % 8 == 0) or (int(az) % 8 == 0):
				c = STEEL
			elif oct < 0.5:
				c = VIOLET
			for y in h:
				v.put(x, y, z, c if y == h - 1 else DARK)
	# rim lights and spines
	for a in 16:
		var ang := a * TAU / 16.0
		var x := int(round(cos(ang) * 14.0))
		var z := int(round(sin(ang) * 11.0))
		v.put(x, 6, z, MAGENTA, true)
	for s in [-1, 1]:
		v.fill(s * 20, 5, -2, s * 30, 5, 1, STEEL)
		v.fill(s * 30, 5, -2, s * 30, 5, 1, ORANGE, true)
	v.fill(-2, 4, -27, 1, 6, -20, WINE)
	v.fill(-1, 6, -27, 0, 6, -24, ORANGE, true)
	v.fill(-2, 4, 20, 1, 5, 27, WINE)
	return v.mesh(0.2, Vector3(0, 4.0, 0))


static func _boss_pod() -> ArrayMesh:
	var v := Vox.new(14, 7, 14)
	v.blob(0, 2, 0, 5.5, 2.2, 5.5, CRIMSON)
	v.blob(0, 4, 0, 3.0, 1.4, 3.0, WINE)
	v.fill_sym(0, 2, 5, 1, 3, 7, GREY)
	v.fill_sym(0, 2, 7, 1, 2, 7, MAGENTA, true)
	v.blob(0, 5, 0, 1.2, 0.8, 1.2, ORANGE, true)
	return v.mesh(0.18, Vector3(0, 3.0, 0))


static func _boss_eye() -> ArrayMesh:
	var v := Vox.new(18, 12, 18)
	v.blob(0, 5, 0, 8.0, 5.5, 8.0, Color(0.9, 0.86, 0.82))
	v.blob(0, 7, 0, 4.2, 4.0, 4.2, MAGENTA, true)
	v.blob(0, 9, 0, 2.0, 2.0, 2.0, Color(0.2, 0.02, 0.1))
	return v.mesh(0.2, Vector3(0, 6.0, 0), true)


## One half of the eye's shutter (the left half; mirrored by scale).
static func _boss_shutter() -> ArrayMesh:
	var v := Vox.new(22, 4, 22)
	for z in range(-10, 10):
		for x in range(-10, 0):
			var d := Vector2(x + 0.5, z + 0.5).length()
			if d < 10.5:
				var c := STEEL if (z % 4 != 0) else GREY
				if x == -1:
					c = ORANGE
				v.put(x, 0, z, c, x == -1)
				if d < 8.0:
					v.put(x, 1, z, DARK)
	return v.mesh(0.2, Vector3(0, 0, 0))


static func _shell() -> ArrayMesh:
	var v := Vox.new(4, 4, 4)
	v.jitter = 0.0
	v.fill(-2, 0, -2, 1, 3, 1, Color(0.7, 0.62, 0.5))
	v.fill(-1, 1, -2, 0, 2, 1, ORANGE, true)
	v.fill(-2, 1, -1, 1, 2, 0, ORANGE, true)
	return v.mesh(0.12, Vector3(0, 2.0, 0))


static func _energy() -> ArrayMesh:
	var v := Vox.new(4, 6, 4)
	v.jitter = 0.0
	v.fill(-1, 1, -1, 0, 4, 0, GREEN, true)
	v.fill(-2, 2, -1, 1, 3, 0, Color(0.6, 1.0, 0.7), true)
	v.fill(-1, 2, -2, 0, 3, 1, Color(0.6, 1.0, 0.7), true)
	v.fill(-1, 0, -1, 0, 0, 0, GREEN, true)
	v.fill(-1, 5, -1, 0, 5, 0, GREEN, true)
	return v.mesh(0.09, Vector3(0, 3.0, 0), true)


static func _power() -> ArrayMesh:
	var v := Vox.new(10, 6, 8)
	v.blob(0, 2, 0, 4.6, 2.2, 3.0, BLUE)
	v.fill(-5, 2, -1, 4, 2, 0, CYAN, true)
	# a "P" on top
	v.fill(-1, 5, -2, -1, 5, 2, WHITE, true)
	v.fill(0, 5, -2, 1, 5, -2, WHITE, true)
	v.fill(0, 5, 0, 1, 5, 0, WHITE, true)
	v.put(1, 5, -1, WHITE, true)
	return v.mesh(0.13, Vector3(0, 2.5, 0))


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


## Destructible ground tile (1 x 1 cell). 0 soft panel, 1 armoured, 2 hard.
static func _tile(kind: int) -> ArrayMesh:
	var v := Vox.new(8, 3, 8)
	var top: Color = [Color(0.2, 0.42, 0.45), Color(0.34, 0.32, 0.58), Color(0.46, 0.48, 0.54)][kind]
	var edge: Color = top.darkened(0.35)
	var h := 1 + kind
	v.fill(-4, 0, -4, 3, h - 1, 3, edge)
	v.fill(-3, h - 1, -3, 2, h - 1, 2, top)
	match kind:
		0:
			v.fill(-1, h - 1, -1, 0, h - 1, 0, Color(0.32, 0.62, 0.6))
		1:
			v.fill(-3, h - 1, -1, 2, h - 1, 0, top.darkened(0.2))
			v.fill(-1, h - 1, -3, 0, h - 1, 2, top.darkened(0.2))
		2:
			for c in [Vector2i(-3, -3), Vector2i(2, -3), Vector2i(-3, 2), Vector2i(2, 2)]:
				v.put(c.x, h - 1, c.y, Color(0.75, 0.76, 0.8))
			v.fill(-1, h - 1, -1, 0, h - 1, 0, Color(0.55, 0.3, 0.9), true)
	return v.mesh(0.125)


## Background asteroid chunk (drawn far below, blurred).
static func _rock(seed: int, s: float) -> ArrayMesh:
	var v := Vox.new(16, 12, 16)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	v.blob(0, 6, 0, 6.5 * s / 1.4, 5.0, 6.0, Color(0.3, 0.28, 0.33))
	for i in 7:
		v.blob(rng.randi_range(-5, 5), rng.randi_range(3, 9), rng.randi_range(-5, 5), rng.randf_range(1.5, 3.0), rng.randf_range(1.5, 2.5), rng.randf_range(1.5, 3.0), Color(0.36, 0.33, 0.38))
	for i in 5:
		v.put(rng.randi_range(-5, 5), rng.randi_range(6, 10), rng.randi_range(-5, 5), VIOLET, true)
	return v.mesh(0.8, Vector3(0, 6, 0))
