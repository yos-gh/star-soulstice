class_name BossModels
extends Models
## Mid-bosses and bosses: Lazaro's shell pieces and core, STAR CORTEX's
## hull, pods, eye and shutter, OUROBOROS's head and cars, VULCAN PRESS's
## parts.

const NAMES := ["lazaro_piece", "lazaro_core", "boss_hull", "boss_pod", "boss_eye", "boss_shutter", "ouro_head", "ouro_car", "press_hull", "press_core", "press_plate", "press_hammer", "press_tube0", "press_tube1", "press_tube2", "press_vent"]


static func make(name: String) -> ArrayMesh:
	match name:
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
		"ouro_head":
			return _ouro_head()
		"ouro_car":
			return _ouro_car()
		"press_hull":
			return _press_hull()
		"press_core":
			return _press_core()
		"press_plate":
			return _press_plate()
		"press_hammer":
			return _press_hammer()
		"press_tube0", "press_tube1", "press_tube2":
			return _press_tube(int(name.right(1)))
		"press_vent":
			return _press_vent()
	return null


## One quarter of Lazaro's shell: the +x/+z quadrant of a hollow sphere of
## violet and black armour plates with gold seams and a red equator,
## re-centred on its own centroid so the pieces can fly apart.
static func _lazaro_piece() -> ArrayMesh:
	var v := Vox.new(26, 16, 26)
	var r := 10.5
	for z in range(0, 12):
		for y in range(-8, 8):
			for x in range(0, 12):
				var p := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var d := p.length()
				if d > r or d < r - 3.0:
					continue
				var lat := asin(clampf(p.y / d, -1.0, 1.0)) / 0.55
				var lon := atan2(p.z, p.x) / 0.5
				var seam := absf(lat - round(lat)) < 0.1 or absf(lon - round(lon)) < 0.1
				var c := GUN_D
				var glow := false
				if d > r - 1.2:
					c = GOLD if seam else (VIOLET if int(floor(lat) + floor(lon)) % 2 == 0 else BLACK)
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

## STAR CORTEX hull (Star Brain homage, after the NES art: a huge machine
## structure still being built): grey machinery in stepped rings round the
## eye with a ragged rim, truss girders and pipes sticking out past it
## (open pipe ends, flanges, cyan lamps at the joints), an unfinished flank
## where only the frame is up, scaffold towers and a yellow crane at the
## back, grey flank gun decks, a ring of cool lamps and a channel in front
## of the eye, so shots from below reach it. Everything but the back stays
## at or under the bullets' height (surface y 9, 0.32 above the plane) so
## the hull never hides a bullet passing over it.
static func _boss_hull() -> ArrayMesh:
	var v := Vox.new(176, 16, 128)
	var top_max := 9  # surface height over the bullets' plane (voxels)
	for z in range(-44, 44):
		for x in range(-60, 60):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			var oct := maxf(maxf(ax / 57.0, az / 42.0), (ax + az) / 76.0)
			# a ragged rim: blocks of the outer ring left out or built on
			var rag := (Vox._hash(int(floor(x / 5.0)), 9, int(floor(z / 5.0))) - 0.5) * 0.22
			if oct < 0.36 or oct > 0.95 + rag:
				continue
			if ax < 11.0 and z > 0:
				continue
			var h := 4
			var top := GUN
			if oct < 0.5:
				h = 9
				top = STEEL_M.lerp(STEEL_L, 0.5)
			elif oct < 0.66:
				h = 7
				top = STEEL_M
			elif oct < 0.84:
				h = 6
				top = GUN
			if oct > 0.92:
				h = 3
				top = GUN_D
			var ring := absf(oct - 0.5) < 0.012 or absf(oct - 0.66) < 0.012 or absf(oct - 0.84) < 0.012
			if ring:
				top = BLACK
			elif oct >= 0.5 and oct < 0.92:
				if int(ax) % 10 == 0 or int(az) % 8 == 0:
					top = top.darkened(0.3)
				else:
					# machinery: blocks raised a step or two
					var n := Vox._hash(int(floor(x / 3.0)), 5, int(floor(z / 3.0)))
					if n > 0.78:
						h = mini(h + (2 if n > 0.93 else 1), top_max)
						top = top.lightened(0.12)
					elif n < 0.12:
						top = top.darkened(0.2)
			# the unfinished flank (front right): only the frame is up
			var frame := x > 26 and x < 56 and z > 4 and z < 34 and oct > 0.5
			if frame and posmod(x, 6) != 0 and posmod(z, 6) != 0:
				v.put(x, 0, z, BLACK)
				v.put(x, 1, z, GUN_D)
				continue
			for y in h:
				v.put(x, y, z, top if y == h - 1 else (GUN if y > 1 else GUN_D))
			if frame and h < top_max:
				v.put(x, h, z, STEEL_M)
	# machinery blocks built out over the rim, all round (jittered, not
	# mirrored: still being built)
	for i in 18:
		var a := TAU * (i + Vox._hash(i, 3, 7) * 0.6) / 18.0
		var d := Vector2(cos(a), sin(a))
		if absf(d.x) < 0.25 and d.y > 0.0:
			continue  # keep the eye channel clear
		var oct_d := maxf(maxf(absf(d.x) / 57.0, absf(d.y) / 42.0), (absf(d.x) + absf(d.y)) / 76.0)
		var c := d * (0.9 / oct_d + 2.0 + Vox._hash(i, 4, 1) * 4.0)
		var hw := 3 + int(Vox._hash(i, 5, 2) * 4.0)
		var hd := 3 + int(Vox._hash(i, 6, 3) * 3.0)
		var hh := 3 + int(Vox._hash(i, 7, 4) * 4.0)
		var cx := int(c.x)
		var cz := int(c.y)
		v.fill(cx - hw, 1, cz - hd, cx + hw, hh, cz + hd, GUN)
		v.fill(cx - hw, 0, cz - hd, cx + hw, 0, cz + hd, GUN_D)
		v.fill(cx - hw + 1, hh, cz - hd + 1, cx + hw - 1, hh, cz + hd - 1, STEEL_M)
		v.fill(cx - hw + 1, hh, cz, cx + hw - 1, hh, cz, BLACK)
		if i % 4 == 1:
			v.put(cx, hh + 1, cz - hd + 1, CYAN, true)
	# truss girders sticking out a little past the rim, each with a module
	# being hung on its end
	for g: Array in [[12.0, 1.1], [38.0, 1.06], [64.0, 1.12], [101.0, 1.08], [143.0, 1.14], [168.0, 1.06], [205.0, 1.1], [232.0, 1.05], [300.0, 1.1], [331.0, 1.12]]:
		var a := deg_to_rad(float(g[0]))
		var d := Vector2(cos(a), sin(a))
		var oct_d := maxf(maxf(absf(d.x) / 57.0, absf(d.y) / 42.0), (absf(d.x) + absf(d.y)) / 76.0)
		var r0 := 0.8 / oct_d
		var r1 := float(g[1]) / oct_d
		_truss(v, d * r0, d, r1 - r0, 5)
		var e := d * r1
		v.fill(int(e.x) - 3, 2, int(e.y) - 3, int(e.x) + 3, 5, int(e.y) + 3, STEEL_M)
		v.fill(int(e.x) - 2, 6, int(e.y) - 2, int(e.x) + 2, 6, int(e.y) + 2, GUN)
		v.fill(int(e.x) - 3, 5, int(e.y), int(e.x) + 3, 5, int(e.y), BLACK)
	# pipes along the deck, running a little out past the rim (mirrored pairs
	# and a few odd ones)
	for s in [-1, 1]:
		_pipe(v, Vector2i(s * 24, -52), Vector2i(s * 24, 52), top_max)
		_pipe(v, Vector2i(s * 34, -44), Vector2i(s * 34, 30), top_max)
		_pipe(v, Vector2i(s * 13, -36), Vector2i(s * 44, -36), top_max)
		_pipe(v, Vector2i(s * 14, 22), Vector2i(s * 58, 22), top_max)
	_pipe(v, Vector2i(-46, -14), Vector2i(-46, 32), top_max)
	_pipe(v, Vector2i(-62, 6), Vector2i(-20, 6), top_max)
	_pipe(v, Vector2i(52, -26), Vector2i(52, 12), top_max)
	# the eye channel's lamps
	for z in range(1, 34):
		if z % 4 == 0:
			v.put(-12, 5, z, CYAN, true)
			v.put(11, 5, z, CYAN, true)
	# flank gun decks
	for s in [-1, 1]:
		v.fill(s * 30, 5, -10, s * 44, 7, 8, GUN)
		v.fill(s * 31, 8, -8, s * 43, 8, 6, STEEL_L)
		for z in [-6, -1, 4]:
			v.fill(s * 34, 8, z, s * 40, 8, z, BLACK)
		v.fill(s * 45, 6, -3, s * 52, 6, 2, GUN_D)
		v.fill(s * 52, 6, -3, s * 52, 6, 2, AMBER, true)
	for a in 24:
		var ang := a * TAU / 24.0
		var x := int(round(cos(ang) * 23.0))
		var z := int(round(sin(ang) * 17.0))
		if absf(x) < 12 and z > 0:
			continue
		v.put(x, 8, z, LAMP, true)
	# at the back (only bullets leaving the screen pass over it): scaffold
	# towers, the spine mast and a crane swinging a girder out past the edge
	for t: Array in [[-40, -38, 8, 7, 13], [-17, -42, 6, 6, 11], [14, -40, 7, 6, 12], [40, -35, 6, 8, 10]]:
		_scaffold(v, t[0], t[1], t[2], t[3], 4, t[4])
	v.fill(-3, 3, -43, 2, 10, -30, GUN)
	v.fill(-1, 11, -43, 0, 11, -36, AMBER, true)
	_crane(v, Vector2i(28, -30), Vector2(0.86, -0.5), 46, 14)
	return v.mesh(U * 1.2, Vector3(0.5, 6.0, 0.5))


## Highest filled voxel in a column (-1: none).
static func _top(v: Vox, x: int, z: int) -> int:
	for y in range(v.sy - 1, -1, -1):
		if v.filled(x, y, z):
			return y
	return -1


## A truss girder from `from` along `dir` (plan view, voxels): two chords
## at height y with cross members and posts every third step.
static func _truss(v: Vox, from: Vector2, dir: Vector2, length: float, y: int) -> void:
	var perp := Vector2(-dir.y, dir.x)
	var steps := int(length)
	for t in steps + 1:
		var p := from + dir * t
		for s: float in [-1.5, 1.5]:
			var q := p + perp * s
			v.put(int(round(q.x)), y, int(round(q.y)), STEEL_M)
		if t % 3 == 0:
			for k in range(-1, 2):
				var q := p + perp * k
				v.put(int(round(q.x)), y, int(round(q.y)), GUN_D)
			v.fill(int(round(p.x)), y - 2, int(round(p.y)), int(round(p.x)), y - 1, int(round(p.y)), GUN_D)


## A pipe (2 x 2) along x or z from a to b, lying on whatever is under it
## (over open space it runs on at deck height and ends open), with flanges
## and now and then a cyan lamp; it skips stretches where it would rise over
## `top_max`.
static func _pipe(v: Vox, a: Vector2i, b: Vector2i, top_max: int) -> void:
	var along_x := a.y == b.y
	var n := absi(b.x - a.x) if along_x else absi(b.y - a.y)
	var step := Vector2i(signi(b.x - a.x), 0) if along_x else Vector2i(0, signi(b.y - a.y))
	var side := Vector2i(0, 1) if along_x else Vector2i(1, 0)
	var y := 4
	for i in n + 1:
		var p := a + step * i
		var g := _top(v, p.x, p.y)
		if g >= 0:
			y = g + 1
		if y + 1 > top_max - 1:
			continue
		var flange := i % 7 == 0
		var col := GUN.lightened(0.06)
		for k in 2:
			var q := p + side * k
			v.put(q.x, y, q.y, col)
			v.put(q.x, y + 1, q.y, STEEL_L if flange else col.lightened(0.1))
		if flange:
			v.put(p.x - side.x, y, p.y - side.y, STEEL_M)
			v.put(p.x + side.x * 2, y, p.y + side.y * 2, STEEL_M)
			if i % 21 == 0:
				v.put(p.x, y + 1, p.y, CYAN, true)
		if i == n:
			v.put(p.x, y + 1, p.y, BLACK)


## An open scaffold tower: corner posts from y0 to y1, rings every third
## level, a part-plated top.
static func _scaffold(v: Vox, x: int, z: int, w: int, d: int, y0: int, y1: int) -> void:
	for c: Vector2i in [Vector2i(x, z), Vector2i(x + w, z), Vector2i(x, z + d), Vector2i(x + w, z + d)]:
		v.fill(c.x, y0, c.y, c.x, y1, c.y, STEEL_M)
	for y in range(y0 + 2, y1 + 1, 3):
		v.fill(x, y, z, x + w, y, z, GUN_D)
		v.fill(x, y, z + d, x + w, y, z + d, GUN_D)
		v.fill(x, y, z, x, y, z + d, GUN_D)
		v.fill(x + w, y, z, x + w, y, z + d, GUN_D)
	v.fill(x, y1, z, x + w / 2, y1, z + d, STEEL_L)


## A tower crane: a lattice mast at `at` up to height `h`, a yellow jib
## `reach` long along `dir` out past the edge with a girder hanging from it,
## a short counter-jib with its weight.
static func _crane(v: Vox, at: Vector2i, dir: Vector2, reach: int, h: int) -> void:
	for y in range(3, h + 1):
		v.put(at.x, y, at.y, HAZARD if y % 2 == 0 else GUN_D)
		v.put(at.x + 1, y, at.y + 1, GUN_D if y % 2 == 0 else HAZARD)
	for t in range(-8, reach + 1):
		var p := Vector2(at) + dir * t
		v.put(int(round(p.x)), h, int(round(p.y)), HAZARD if posmod(t, 4) != 0 else GUN_D)
	var w := Vector2(at) - dir * 8
	v.fill(int(w.x) - 1, h - 2, int(w.y) - 1, int(w.x) + 1, h - 1, int(w.y) + 1, GUN_D)
	var e := Vector2(at) + dir * (reach - 3)
	v.fill(int(e.x), 9, int(e.y), int(e.x), h - 1, int(e.y), BLACK)
	_truss(v, e + Vector2(-dir.y, dir.x) * -4.0, Vector2(-dir.y, dir.x), 8.0, 8)


## A corner gun pod: grey rings round a cyan lamp, a cyan muzzle (it fires
## the cool shell fans).
static func _boss_pod() -> ArrayMesh:
	var v := Vox.new(28, 9, 32)
	for z in range(-13, 14):
		for x in range(-13, 14):
			var r := Vector2(x, z).length()
			if r > 13.4:
				continue
			var h := 2 if r > 11.5 else (5 if r > 7.0 else 6)
			for y in h:
				var c := GUN
				if y == h - 1:
					c = GUN_D if r > 11.5 else (STEEL_M if r > 7.0 else STEEL_L)
					if absf(r - 9.2) < 0.6:
						c = BLACK
				v.put(x, y, z, c)
	v.fill_sym(1, 3, 6, 2, 4, 15, GUN_D)
	v.fill_sym(1, 4, 15, 2, 4, 15, CYAN, true)
	v.fill(-2, 6, -2, 2, 7, 2, GUN_D)
	v.fill(-1, 8, -1, 1, 8, 1, CYAN, true)
	return v.mesh(U * 1.2, Vector3(0.5, 3.0, 0.5))


## The great eye (after Star Brain): a ribbed steel dome round a black lens
## ring, a glowing iris of white and cyan crossed by four dark spokes, a
## white-hot core.
static func _boss_eye() -> ArrayMesh:
	var v := Vox.new(36, 15, 36)
	for z in range(-17, 18):
		for x in range(-17, 18):
			var r := Vector2(x, z).length()
			if r > 17.0:
				continue
			var h := int(round(sqrt(maxf(0.0, 17.5 * 17.5 - r * r)) * 0.55))
			var rib := absf(wrapf(atan2(z, x) * 16.0 / TAU, -0.5, 0.5)) < 0.12 and r > 8.0
			var spoke := (absf(x) < 1.2 or absf(z) < 1.2) and r > 2.6 and r < 8.0
			for y in h:
				var c := GUN if r > 12.0 else STEEL_M
				var glow := false
				if y == h - 1:
					if spoke:
						c = GUN_D
					elif r < 2.6:
						c = Color(1.0, 0.98, 0.94)
						glow = true
					elif r < 7.0:
						c = LAMP if int(r * 1.5) % 2 == 0 else CYAN
						glow = true
					elif r < 8.0:
						c = BLACK
					elif rib:
						c = GUN
				v.put(x, y, z, c, glow)
			if spoke:
				v.put(x, h, z, STEEL_M)
	return v.mesh(U * 1.2, Vector3(0.5, 5.0, 0.5))


## One half of the eye's armoured shutter (the left half; mirrored): grey
## steel slats, a cyan seam glowing where the halves meet.
static func _boss_shutter() -> ArrayMesh:
	var v := Vox.new(40, 4, 40)
	for z in range(-19, 20):
		for x in range(-20, 0):
			var d := Vector2(x + 0.5, z).length()
			if d >= 19.5:
				continue
			var c := STEEL_L if (z + 20) % 6 > 1 else STEEL_M
			var glow := false
			if x == -1:
				c = CYAN
				glow = true
			elif d > 17.5:
				c = GUN_D
			v.put(x, 0, z, c, glow)
			if d < 15.0 and x < -2:
				v.put(x, 1, z, STEEL_M if (z + 20) % 6 > 1 else BLACK)
	return v.mesh(U * 1.2, Vector3(0, 0, 0.5))



# ------------------------------------------------------------ stage 2

## OUROBOROS's locomotive (faces -z): a brass wedge plough, a furnace
## grille glowing behind it with two red eyes, a jade body in dark jade
## side armour, a domed cab with a stack, gold stripes, a coupler at the
## back.
static func _ouro_head() -> ArrayMesh:
	var v := Vox.new(32, 11, 38)
	for z in range(-18, 19):
		for x in range(-15, 15):
			var ax := absf(x + 0.5)
			# the plough narrows to a point at the nose
			var half := 14.0 if z > -8 else 14.0 - (-8 - z) * 1.35
			if ax > half:
				continue
			var h := 4
			var c := GUN
			if z < -8:
				h = 2 + int((half - ax) * 0.35)
				c = GOLD if int(ax + z) % 4 != 0 else BRONZE
			elif ax > 11.0:
				h = 5
				c = JADE_D if (z + 18) % 6 > 0 else GUN_D
			else:
				h = 6
				c = JADE if ax > 4.0 else JADE_L
			for y in h:
				v.put(x, y, z, c if y == h - 1 else (GUN if y > 0 else GUN_D))
	# furnace grille behind the plough, eyes either side
	for x in range(-7, 7):
		v.fill(x, 4, -8, x, 6, -8, AMBER if x % 2 == 0 else GUN_D, x % 2 == 0)
	v.fill_sym(8, 5, -8, 9, 6, -7, EYE, true)
	# cab dome and stack
	v.blob(0, 7, 4, 4.5, 2.5, 5.0, BLACK)
	v.blob(0, 8, 4, 3.0, 2.2, 3.5, JADE)
	v.fill(-1, 8, -2, 0, 10, -1, GUN_D)
	v.fill(-1, 10, -2, 0, 10, -1, EYE, true)
	# gold-striped flanks and the rear coupler
	v.fill_sym(14, 2, -6, 14, 3, 16, GOLD)
	v.fill_sym(0, 1, 17, 2, 3, 18, GUN_D)
	return v.mesh(U * 1.2, Vector3(0.5, 3.0, 0.5))


## OUROBOROS's car (faces -z): an armoured hopper, jade and black
## plates over gunmetal, gold stripes, a little turret dome with a red eye
## on top, couplers fore and aft, amber lamps at the corners.
static func _ouro_car() -> ArrayMesh:
	var v := Vox.new(26, 9, 26)
	for z in range(-11, 11):
		for x in range(-11, 11):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			if ax + az > 18.0:
				continue
			var h := 5 if ax < 8.0 and az < 8.0 else 3
			var top := JADE if ((x + 11) / 4 + (z + 11) / 4) % 2 == 0 else BLACK
			if h == 3:
				top = JADE_D
			for y in h:
				v.put(x, y, z, top if y == h - 1 else (GUN if y > 0 else GUN_D))
	v.fill_sym(10, 1, -6, 10, 2, 5, GOLD)
	v.blob(0, 6, 0, 3.0, 1.6, 3.0, GUN)
	v.fill_sym(0, 7, -3, 0, 7, -2, EYE, true)
	v.fill_sym(0, 1, -13, 1, 2, -11, GUN_D)
	v.fill_sym(0, 1, 11, 1, 2, 12, GUN_D)
	for c: Vector2i in [Vector2i(-8, -7), Vector2i(7, -7), Vector2i(-8, 6), Vector2i(7, 6)]:
		v.put(c.x, 3, c.y, AMBER, true)
	return v.mesh(U * 1.2, Vector3(0.5, 2.5, 0.5))


## VULCAN PRESS's hull (faces down-screen, +z): as wide as the tunnel. A
## gunmetal base, a deck of grey steel plates lined in black in the middle,
## heavy furnace housings in construction-machine orange at the sides with
## glowing grilles, a back ridge with smoke stacks, the hammers' rail along the
## front edge (hazard-striped, amber lamps), and in the middle of the front
## a round bay where the crucible core burns on a molten bed inside a lit
## rim.
static func _press_hull() -> ArrayMesh:
	var u := U * 1.5
	var v := Vox.new(188, 15, 56)
	for z in range(-28, 28):
		for x in range(-94, 94):
			var ux := (x + 0.5) * u
			var uz := (z + 0.5) * u
			var ax := absf(ux)
			if uz < -3.8 or uz > 3.2:
				continue
			var lim := 12.5
			if uz > 1.0:
				lim -= (uz - 1.0) * 1.2
			if uz < -2.6:
				lim -= (-2.6 - uz) * 2.0
			if ax > lim:
				continue
			var bay := Vector2(ux, uz - 1.4).length()
			var h := 4
			var top := GUN.lightened(0.08)
			var glow := false
			if bay < 3.7:
				if bay > 3.25:
					h = 6
					var seg := int(floor((atan2(uz - 1.4, ux) + PI) * 12.0 / PI))
					top = BLACK if seg % 2 == 0 else GUN
					if seg % 4 == 1 and bay > 3.45:
						top = AMBER
						glow = true
				elif bay < 2.2:
					h = 2
					top = Color(0.6, 0.2, 0.07) if Vox._hash(x, 1, z) > 0.55 else BROWN
					glow = top != BROWN
				else:
					h = 2
					top = GUN_D
			elif uz < -2.4:
				h = 10
				top = GUN_D if int(ax / 0.8) % 2 == 0 else GUN
			elif ax > 8.8 and uz < 1.0:
				h = 9
				top = ORANGE
				# furnace grilles, dark, one lit slit in each
				if int((uz + 4.0) / 0.4) % 2 == 0 and ax > 9.4 and ax < 11.6:
					top = GUN_D
					if absf(ax - 10.5) < u:
						top = Color(0.7, 0.25, 0.08)
						glow = true
			elif ax < 8.8 and uz < 0.6:
				# grey steel plates lined in black
				h = 8
				top = STEEL_L if (int((ux + 12.0) / 1.6) + int((uz + 4.0) / 1.6)) % 2 == 0 else STEEL_M
				if absf(fmod(ux + 12.0, 1.6)) < u or absf(fmod(uz + 4.0, 1.6)) < u:
					top = BLACK
			elif uz > 2.6:
				# the hammers' rail, hazard-striped, with amber lamps
				h = 6
				top = HAZARD if int((x + z) / 3) % 2 == 0 else BLACK
				if x % 10 == 0 and uz > 2.95:
					top = AMBER
					glow = true
			for y in h:
				v.put(x, y, z, top if y == h - 1 else (GUN if y > 0 else GUN_D), glow and y == h - 1)
	# smoke stacks on the back ridge
	for sx: float in [-6.5, -3.0, 3.0, 6.5]:
		var cx := int(sx / u)
		v.fill(cx - 2, 10, -25, cx + 1, 13, -22, GUN_D)
		v.fill(cx - 1, 14, -24, cx, 14, -23, Color(1.0, 0.4, 0.12), true)
	# bolts round the deck
	for k in 12:
		var bx := int(lerpf(-60.0, 60.0, k / 11.0))
		v.put(bx, 8, -16, AMBER, true)
	return v.mesh(u, Vector3(0, 3.0, 0))


## The crucible core: a ball of molten metal, white-hot inside, in an iron
## cage (four hoops and an equator band).
static func _press_core() -> ArrayMesh:
	var v := Vox.new(28, 28, 28)
	for z in range(-14, 14):
		for y in range(0, 28):
			for x in range(-14, 14):
				var p := Vector3(x + 0.5, y + 0.5 - 14.0, z + 0.5)
				var r := p.length()
				if r > 12.5:
					continue
				var hoop := absf(p.x) < 1.2 or absf(p.z) < 1.2 or absf(p.y) < 1.0
				if r > 11.3 and hoop:
					v.put(x, y, z, GUN_D)
				elif r > 11.3:
					continue
				elif r > 10.0:
					v.put(x, y, z, AMBER if Vox._hash(x, y, z) > 0.25 else Color(1.0, 0.3, 0.1), true)
				else:
					v.put(x, y, z, Color(1.0, 0.78, 0.45), true)
	return v.mesh(U * 1.2, Vector3(0, 10.0, 0), true)


## One of the three armour plates that turn round the core: a curved slab
## on a circle of radius PLATE_R (its centre is +z of the plate), light
## grey steel outside with seams, gunmetal inside, a lit line along the outer
## face.
static func _press_plate() -> ArrayMesh:
	var v := Vox.new(24, 9, 14)
	var rc := 24.0
	for z in range(-4, 8):
		for x in range(-12, 12):
			var r := Vector2(x + 0.5, z + 0.5 - rc).length()
			if r < 20.8 or r > 27.0 or absf(x + 0.5) > 11.0:
				continue
			for y in 8:
				var c := GUN
				var glow := false
				if r > 25.8:
					c = STEEL_L if (x + 12) % 4 != 0 else GUN_D
					if y == 3:
						c = LAMP
						glow = true
				elif r < 22.0:
					c = GUN_D
				if y == 7:
					c = STEEL_M if r > 22.0 else GUN_D
				v.put(x, y, z, c, glow)
	return v.mesh(U * 1.2, Vector3(0, 1.5, 0))


## A hammer head (strikes toward +z): an orange block with a steel top,
## grey sides, a row of teeth on the striking face, a red eye on top,
## amber lamps, and the ram's socket at the back.
static func _press_hammer() -> ArrayMesh:
	var v := Vox.new(24, 12, 24)
	v.fill(-11, 0, -9, 10, 7, 8, ORANGE.darkened(0.15))
	v.fill(-11, 0, -9, 10, 0, 8, GUN_D)
	v.fill(-10, 8, -8, 9, 8, 7, ORANGE)
	v.fill(-7, 9, -6, 6, 9, 5, STEEL_L)
	v.fill(-12, 1, -8, -12, 6, 7, STEEL_M)
	v.fill(11, 1, -8, 11, 6, 7, STEEL_M)
	for x in range(-10, 10, 4):
		v.fill(x, 2, 9, x + 1, 5, 10, GUN_D)
		v.fill(x, 3, 11, x + 1, 4, 11, GUN_D.lightened(0.15))
	v.fill(-1, 10, -2, 0, 10, 1, EYE, true)
	for c: Vector2i in [Vector2i(-11, -9), Vector2i(10, -9), Vector2i(-11, 8), Vector2i(10, 8)]:
		v.put(c.x, 8, c.y, AMBER, true)
	v.fill(-3, 2, -11, 2, 5, -10, GUN_D)
	return v.mesh(U * 1.5, Vector3(0.5, 3.0, 0.5))


## One stage of a hammer's telescoping ram (0 = the thinnest, behind the
## head): a polished tube along z, TUBE_LEN long, ringed every so often.
static func _press_tube(k: int) -> ArrayMesh:
	var rad := 3.0 + k
	var n := int(ceil(rad)) + 1
	var v := Vox.new(n * 2, n * 2, 46)
	for z in range(-22, 22):
		for y in range(0, n * 2):
			for x in range(-n, n):
				var r := Vector2(x + 0.5, y + 0.5 - n).length()
				if r > rad:
					continue
				var ring := posmod(z, 8) == 0
				v.put(x, y, z, GUN_D if ring else (GUN.lightened(0.25) if r > rad - 1.2 else GUN))
	return v.mesh(U * 1.5, Vector3(0, n, 0))


## A corner vent gun (fires toward +z): an orange housing, a steel
## dome, three barrels with glowing muzzles, a lit grille on top.
static func _press_vent() -> ArrayMesh:
	var v := Vox.new(20, 10, 22)
	v.fill(-8, 0, -8, 7, 3, 7, ORANGE)
	v.fill(-8, 0, -8, 7, 0, 7, GUN_D)
	v.blob(0, 4, -1, 6.0, 3.0, 6.0, STEEL_L)
	for x in [-4, 0, 4]:
		v.fill(x - 1, 3, 4, x, 4, 10, GUN)
		v.fill(x - 1, 3, 11, x, 4, 11, AMBER, true)
	for x in range(-3, 3):
		if x % 2 == 0:
			v.fill(x, 7, -4, x, 7, 1, AMBER, true)
	return v.mesh(U * 1.5, Vector3(0.5, 2.0, 0.5))
