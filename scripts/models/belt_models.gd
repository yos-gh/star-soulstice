class_name BeltModels
extends Models
## Stage 3, the asteroid belt: the giant drifting rocks, the GRAPPLER mining
## tug and its claws, LODESTAR's frame, core and magnet pylons, TITAN
## DREDGE's hull (dug into a giant asteroid), core, cutter wheels, booms and
## mass driver, and the rocks of the belt below (scenery, in the ground's
## receding material). The rocks keep the drifting rocks' browns and greys;
## the machines are olive on dark grey (GRAPPLER), copper on steel
## (LODESTAR) and mining yellow on steel (TITAN DREDGE). The boulders that
## are carried, slung and fired are the drifting big rock (rock_l).

const NAMES := ["giant_rock_a", "giant_rock_b", "grappler", "grappler_claw", "lode_frame", "lode_core", "lode_pylon", "dredge_hull", "dredge_core", "dredge_wheel", "dredge_boom", "dredge_jib", "dredge_driver", "belt_rock_a", "belt_rock_b", "belt_rock_c", "deep_rock_a", "deep_rock_b"]

const STONE := Color(0.34, 0.31, 0.28)
const STONE_L := Color(0.45, 0.41, 0.36)
const STONE_D := Color(0.25, 0.23, 0.21)
const OLIVE := Color(0.33, 0.37, 0.2)
const OLIVE_L := Color(0.44, 0.48, 0.27)
const OLIVE_D := Color(0.24, 0.27, 0.15)
const COPPER := Color(0.7, 0.42, 0.24)
const COPPER_L := Color(0.84, 0.58, 0.36)
const COPPER_D := Color(0.44, 0.26, 0.15)
const ARC := Color(1.0, 0.88, 0.62)  # pale gold glow (LODESTAR's field, TITAN DREDGE's core)
const WHITE_HOT := Color(1.0, 0.96, 0.86)
const MINE := Color(0.84, 0.64, 0.14)  # mining-machine yellow (matte paint)
const MINE_D := Color(0.58, 0.44, 0.1)


static func make(name: String) -> ArrayMesh:
	match name:
		"giant_rock_a":
			return _lump(41, 14.5, 6.0, 13.0, 5).mesh(0.22, Vector3(0, _cy(6.0) + 2.0, 0))
		"giant_rock_b":
			return _lump(77, 18.5, 7.0, 16.5, 7).mesh(0.22, Vector3(0, _cy(7.0) + 2.5, 0))
		"grappler":
			return _grappler()
		"grappler_claw":
			return _grappler_claw()
		"lode_frame":
			return _lode_frame()
		"lode_core":
			return _lode_core()
		"lode_pylon":
			return _lode_pylon()
		"dredge_hull":
			return _dredge_hull()
		"dredge_core":
			return _dredge_core()
		"dredge_wheel":
			return _dredge_wheel()
		"dredge_boom":
			return _dredge_boom()
		"dredge_jib":
			return _dredge_jib()
		"dredge_driver":
			return _dredge_driver()
		"belt_rock_a":
			return _lump(5, 9.0, 5.0, 8.0, 2, true, 0.5).mesh(0.35, Vector3(0, _cy(5.0), 0))
		"belt_rock_b":
			return _lump(9, 6.0, 4.0, 6.5, 1, true, 0.5).mesh(0.35, Vector3(0, _cy(4.0), 0))
		"belt_rock_c":
			return _lump(13, 12.0, 6.0, 10.0, 3, true, 0.5).mesh(0.35, Vector3(0, _cy(6.0), 0))
		"deep_rock_a":
			return _lump(21, 24.0, 9.0, 20.0, 4, true, 0.4).mesh(1.0, Vector3(0, _cy(9.0), 0))
		"deep_rock_b":
			return _lump(27, 18.0, 8.0, 23.0, 3, true, 0.4).mesh(1.0, Vector3(0, _cy(8.0), 0))
	return null


# ------------------------------------------------------------ rocks

## Grid row of a lump's centre (see _lump).
static func _cy(ry: float) -> int:
	return int(ceil(ry * 1.25)) + 1


## A lumpy rock: an ellipsoid (half sizes rx, ry, rz in voxels) with bumps
## built on and `craters` dug into its upper side; lit tops, darker flanks
## and underside, crater floors in shadow, speckles. Its centre is at grid
## row _cy(ry). `ground`: in the ground's receding material (scenery).
static func _lump(seed: int, rx: float, ry: float, rz: float, craters: int, ground := false, dark := 1.0) -> Vox:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var bumps := []
	for i in 11:
		var a := rng.randf() * TAU
		var e := rng.randf_range(0.35, 0.72)
		var s := rng.randf_range(0.24, 0.42)
		bumps.append([Vector3(cos(a) * rx * e, rng.randf_range(-0.4, 0.3) * ry, sin(a) * rz * e), Vector3(rx, ry * 1.1, rz) * s])
	var pits := []
	for i in craters:
		var a := rng.randf() * TAU
		var e := rng.randf_range(0.25, 0.7)
		var r := rng.randf_range(0.1, 0.17) * minf(rx, rz)
		pits.append([Vector3(cos(a) * rx * e, ry * sqrt(maxf(0.0, 1.0 - e * e)) + r * 0.25, sin(a) * rz * e), r])
	var X := int(ceil(rx * 1.25)) + 1
	var Z := int(ceil(rz * 1.25)) + 1
	var cy := _cy(ry)
	var v := Vox.new(X * 2, cy * 2, Z * 2)
	v.ground = ground
	v.jitter = 0.08
	for z in range(-Z, Z):
		for x in range(-X, X):
			var top := -1
			for y in range(cy * 2 - 1, -1, -1):
				var p := Vector3(x + 0.5, y + 0.5 - cy, z + 0.5)
				var inside := Vector3(p.x / rx, p.y / ry, p.z / rz).length_squared() < 1.0
				if not inside:
					for b: Array in bumps:
						var q: Vector3 = p - b[0]
						var sz: Vector3 = b[1]
						if Vector3(q.x / sz.x, q.y / sz.y, q.z / sz.z).length_squared() < 1.0:
							inside = true
							break
				if not inside:
					continue
				var pit := false
				for c: Array in pits:
					if p.distance_to(c[0]) < float(c[1]):
						pit = true
						break
				if pit:
					continue
				var crater := false
				for c: Array in pits:
					var q: Vector3 = c[0]
					if Vector2(p.x - q.x, p.z - q.z).length() < float(c[1]) * 1.1:
						crater = true
						break
				var n := Vox._hash(x >> 1, y >> 1, z >> 1)
				var col := STONE
				if top < 0:
					top = y
					col = STONE_D if crater else (STONE_L if n > 0.55 else STONE)
				elif p.y < -ry * 0.2:
					col = STONE_D
				elif n > 0.86:
					col = STONE_L
				v.put(x, y, z, Color(col.r * dark, col.g * dark, col.b * dark))
	return v


# ------------------------------------------------------------ GRAPPLER

## Mining tug (faces down-screen, +z, toward the ship): a dark grey chassis
## under olive armour plates with seams, a cargo bed at the back (its spare
## boulder rides there), a sensor slit in the front, the claw mounts at the
## front corners, gun pods on both flanks with barrels forward, thrusters
## at the back.
static func _grappler() -> ArrayMesh:
	var v := Vox.new(32, 10, 28)
	# chassis
	v.fill_sym(0, 1, -11, 11, 3, 8, DUSK)
	v.fill_sym(0, 0, -10, 10, 0, 7, DUSK_D)
	# olive armour over the front half and the flanks
	v.fill_sym(0, 4, -2, 10, 4, 7, OLIVE)
	v.fill_sym(0, 5, 0, 7, 5, 5, OLIVE_L)
	for z in [1, 4]:
		v.fill_sym(0, 4, z, 10, 5, z, OLIVE_D)
	v.fill_sym(8, 4, -10, 10, 4, -3, OLIVE)
	# the cargo bed at the back: low walls round a dark floor
	v.fill_sym(0, 4, -10, 7, 4, -3, DUSK_D)
	v.fill_sym(7, 5, -10, 7, 5, -3, DUSK_L)
	v.fill_sym(0, 5, -11, 7, 5, -11, DUSK_L)
	# the front: a sensor slit, lamps
	v.fill_sym(0, 4, 8, 4, 5, 9, DUSK_L)
	v.fill_sym(0, 4, 10, 2, 4, 10, EYE, true)
	v.fill_sym(5, 6, 6, 5, 6, 6, AMBER, true)
	# claw mounts at the front corners
	v.fill_sym(6, 1, 8, 10, 4, 11, GUN)
	v.fill_sym(7, 5, 9, 9, 5, 10, STEEL_L)
	# gun pods on the flanks, barrels forward
	v.fill_sym(12, 1, -5, 15, 4, 5, GUN)
	v.fill_sym(12, 5, -4, 15, 5, 4, OLIVE_L)
	v.fill_sym(13, 2, 6, 14, 3, 11, DUSK_L)
	v.fill_sym(13, 2, 12, 14, 3, 12, AMBER, true)
	# thrusters at the back
	v.fill_sym(9, 1, -14, 12, 3, -12, GUN)
	v.fill_sym(10, 2, -14, 11, 2, -14, AMBER, true)
	return v.mesh(U * 1.45, Vector3(0, 2.5, 0))


## The left claw (the right one is its mirror): an arm reaching forward
## from its root (the origin) with a hydraulic ram along it, and a steel jaw
## hooking inward (+x) at the tip.
static func _grappler_claw() -> ArrayMesh:
	var v := Vox.new(16, 7, 40)
	v.fill(-2, 1, 0, 0, 3, 12, GUN)
	v.fill(-2, 4, 1, 0, 4, 11, OLIVE)
	v.fill(-3, 2, 2, -3, 3, 9, STEEL_L)
	for k in 6:
		v.fill(-1 + k, 1, 12 + k, 1 + k, 3, 13 + k, STEEL_M)
	v.fill(5, 1, 17, 7, 3, 18, STEEL_L)
	v.fill(5, 4, 17, 6, 4, 17, OLIVE_D)
	return v.mesh(U * 1.45, Vector3(0.5, 2.0, 0.5))


# ------------------------------------------------------------ LODESTAR

## LODESTAR's frame: an octagonal drum round the core with a ring of cool
## lamps, spokes out to three pylon sockets, a ring of truss girders over
## the upper two thirds (the bottom third is left open: the way in to the
## core) and heavy armour plates on its flanks.
static func _lode_frame() -> ArrayMesh:
	var v := Vox.new(80, 8, 80)
	# the drum round the core, open in the middle
	for z in range(-15, 15):
		for x in range(-15, 15):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			var oct := maxf(maxf(ax, az), (ax + az) * 0.72)
			if oct > 14.0 or oct < 9.5:
				continue
			var h := 4 if oct > 12.5 else 5
			for y in h:
				v.put(x, y, z, STEEL_M if y == h - 1 else GUN)
			if absf(oct - 11.2) < 0.55:
				v.put(x, h - 1, z, DUSK_D)
	for k in 12:
		var a := (k + 0.5) * TAU / 12.0
		v.put(int(round(cos(a) * 13.0)), 4, int(round(sin(a) * 13.0)), LAMP, true)
	# the ring of trusses over the upper two thirds
	for z in range(-38, 38):
		for x in range(-38, 38):
			var r := Vector2(x + 0.5, z + 0.5).length()
			var a := atan2(z + 0.5, x + 0.5)
			if a > PI / 6.0 + 0.16 and a < PI * 5.0 / 6.0 - 0.16:
				continue
			if absf(r - 34.5) < 0.75 or absf(r - 28.5) < 0.75:
				v.fill(x, 1, z, x, 2, z, STEEL_M)
			elif r > 28.5 and r < 34.5 and posmod(int(round(a * 31.5)), 5) == 0:
				v.put(x, 1, z, GUN)
	# spokes to the pylon sockets, and the sockets
	for pa: float in [PI * 1.5, PI / 6.0, PI * 5.0 / 6.0]:
		var d := Vector2(cos(pa), sin(pa))
		var side := Vector2(-d.y, d.x)
		for s in range(13, 28):
			for w: int in [-1, 0, 1]:
				var q := d * s + side * w
				v.fill(int(round(q.x)), 1, int(round(q.y)), int(round(q.x)), 2, int(round(q.y)), GUN if w != 0 else STEEL_L)
		var c := d * 31.5
		for z in range(-6, 7):
			for x in range(-6, 7):
				var r := Vector2(x, z).length()
				if r > 5.5:
					continue
				v.fill(int(round(c.x)) + x, 0, int(round(c.y)) + z, int(round(c.x)) + x, 2, int(round(c.y)) + z, COPPER_D if r > 4.5 else DUSK_L)
	# armour on the flanks, left and right
	for s: int in [-1, 1]:
		v.fill(s * 27, 0, -6, s * 36, 4, 6, GUN)
		v.fill(s * 28, 5, -5, s * 35, 5, 5, DUSK_L)
		for z in [-3, 0, 3]:
			v.fill(s * 28, 5, z, s * 35, 5, z, GUN_D)
	return v.mesh(U * 1.2, Vector3(0.5, 2.0, 0.5))


## LODESTAR's core: a squat ball of pale gold light inside a copper coil
## (horizontal windings round its lower half), open on top where four steel
## straps cross it, a white-hot heart.
static func _lode_core() -> ArrayMesh:
	var v := Vox.new(30, 16, 30)
	var cy := 7
	for z in range(-15, 15):
		for y in range(0, 16):
			for x in range(-15, 15):
				var p := Vector3(x + 0.5, y + 0.5 - cy, z + 0.5)
				var n := Vector3(p.x / 13.0, p.y / 7.5, p.z / 13.0).length()
				if n > 1.0:
					continue
				var strap := absf(p.x) < 1.0 or absf(p.z) < 1.0
				if n > 0.7:
					if p.y < 2.5:
						v.put(x, y, z, COPPER_L if posmod(y, 2) == 0 else COPPER_D)
					elif strap:
						v.put(x, y, z, STEEL_M)
				elif strap and n > 0.55 and p.y > 0.0:
					v.put(x, y, z, GUN)
				else:
					v.put(x, y, z, WHITE_HOT if n < 0.35 else ARC, true)
	return v.mesh(U * 1.2, Vector3(0.5, cy - 1.0, 0.5), true)


## A magnet pylon: an octagonal grey base, a drum wound in copper (bands of
## light and dark windings) under a steel cap, a pole piece glowing pale
## gold.
static func _lode_pylon() -> ArrayMesh:
	var v := Vox.new(24, 10, 24)
	for z in range(-12, 12):
		for x in range(-12, 12):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			var oct := maxf(maxf(ax, az), (ax + az) * 0.72)
			var r := Vector2(x + 0.5, z + 0.5).length()
			if oct < 10.5:
				v.fill(x, 0, z, x, 1, z, GUN_D if oct > 9.0 else DUSK_L)
			if r < 7.5:
				for y in range(2, 7):
					v.put(x, y, z, COPPER if posmod(y, 2) == 0 else COPPER_D)
			if r < 6.0:
				v.put(x, 7, z, STEEL_M)
			if r < 3.2:
				v.put(x, 8, z, STEEL_L if r > 1.6 else ARC, r <= 1.6)
	return v.mesh(U * 1.2, Vector3(0.5, 2.0, 0.5))


# ------------------------------------------------------------ TITAN DREDGE

## TITAN DREDGE's hull (faces down-screen, +z), a strip-mining machine
## dug into a giant asteroid: the asteroid behind (dulled: it is scenery)
## with terraces cut where the cutters bite; a steel deck of plates with
## engine blocks cased in yellow at the back and a hazard-striped front
## edge; two turntables where the booms pivot; a round bay in the middle
## of the front where the core turns, rimmed with lamps; across the front
## the ore belt (rails and a dark belt with seams) from a chute on the left
## to a yellow hopper on the right, where the mass driver stands; gravel
## vents at both ends.
static func _dredge_hull() -> ArrayMesh:
	var u := U * 1.5
	var v := Vox.new(216, 14, 160)
	for z in range(-78, 48):
		for x in range(-108, 108):
			var ux := (x + 0.5) * u
			var uz := (z + 0.5) * u
			var ax := absf(ux)
			var h := 0
			var top := GUN
			var glow := false
			# the giant asteroid behind
			if uz < -2.8:
				var edge := 15.8 - (-2.8 - uz) * 0.3 + (Vox._hash(int(floor(x / 7.0)), 2, int(floor(z / 7.0))) - 0.5) * 2.6
				if ax < edge:
					var n := Vox._hash(int(floor(x / 3.0)), 5, int(floor(z / 3.0)))
					h = 5 + int(n * 3.0) + (1 if uz < -6.5 else 0)
					top = STONE.darkened(0.12) if n < 0.6 else STONE_L.darkened(0.18)
					if absf(ax - 8.5) < 3.2 and uz > -7.0:
						# cut away in terraces where the cutters dig
						h = 4 if uz > -5.0 else 5
						top = STONE_D
			# the deck: a body round the core and an outrigger round each
			# turntable, trusses between them and struts out to the belt (open
			# space shows between the parts); a frame of dark beams, plated
			# over in places, open in others down to the machinery (rams
			# stand in the open bays)
			var jag := Vox._hash(int(floor(x / 6.0)), 8, int(floor(z / 6.0))) - 0.5
			var tp := Vector2(ax - 8.5, uz + 1.0).length()
			var body := uz >= -3.6 - absf(jag) * 1.6 and uz < 3.0 and ax < 4.7 + jag * 0.8
			var rigger := tp < 2.9 + jag * 0.6 and uz < 2.0
			var truss := ax >= 4.4 and ax < 6.2 and uz > -2.45 and uz < 0.45 and (absf(uz + 2.2) < 0.25 or absf(uz - 0.2) < 0.25 or posmod(int(floor((ax + uz) / 0.6)), 3) == 0)
			var strut := (absf(ax - 7.6) < 0.3 or absf(ax - 10.6) < 0.3) and uz >= 1.6 and uz < 3.0
			if (truss or strut) and not rigger:
				h = 4
				top = GUN_D.lightened(0.1)
			if body or rigger:
				var ci := int(floor((ux + 20.0) / 2.0))
				var cj := int(floor((uz + 20.0) / 2.0))
				var beam := absf(fmod(ux + 20.0, 2.0)) < u * 1.5 or absf(fmod(uz + 20.0, 2.0)) < u * 1.5
				var plated := posmod(ci * 3 + cj * 5, 7) < 4
				h = 5
				top = GUN
				if beam:
					h = 5
					top = GUN_D.lightened(0.1)
				elif plated:
					h = 5
					top = STEEL_M if posmod(x + z * 3, 9) != 0 else GUN.lightened(0.1)
				else:
					h = 3
					top = DUSK_D
				if uz > 2.4:
					# the front edge, hazard-striped
					h = 5
					top = MINE_D if posmod(x + z, 10) < 5 else GUN_D
				if uz < -1.6 and ax > 2.0 and ax < 4.4:
					# engine blocks, cased in yellow over half, the rest bare
					var cased := (ux < 0.0) == (posmod(int(floor(uz / 0.8)), 2) == 0)
					h = 6 if cased else 5
					top = MINE_D if cased else (STEEL_L if posmod(x, 3) == 0 else GUN)
			# the boom turntables
			if tp < 2.5:
				h = 6
				top = STEEL_L if tp > 2.0 else (MINE_D if tp > 1.45 and tp < 1.85 else (GUN if tp > 0.8 else GUN_D))
			# the core's bay
			var bay := Vector2(ux, uz - 1.4).length()
			if bay < 2.9:
				if bay > 2.45:
					h = 6
					var seg := int(floor((atan2(uz - 1.4, ux) + PI) * 12.0 / PI))
					top = MINE_D if seg % 2 == 0 else GUN
					if seg % 4 == 1:
						top = LAMP
						glow = true
				else:
					h = 2
					top = GUN_D
			# the ore belt across the front
			if uz >= 3.0 and uz < 5.6 and ax < 12.2:
				if uz < 3.4 or uz >= 5.2:
					h = 4
					top = STEEL_L if posmod(x, 6) != 0 else GUN
				else:
					h = 3
					top = GUN_D if posmod(x, 4) == 0 else DUSK_D
			# the chute down from the asteroid on the left
			if ux < -11.0 and ux > -14.6 and uz > -3.0 and uz < 5.6:
				var wall := ux < -14.0 or ux > -11.6
				h = (7 if uz < 1.0 else 6) if wall else 4
				top = (MINE_D if posmod(z, 8) < 3 else GUN) if wall else DUSK_D
			# the hopper and the mass driver's deck on the right
			if ux > 11.0 and ux < 14.8 and uz > 2.2 and uz < 7.6:
				var mouth := uz > 2.7 and uz < 5.0 and ux > 11.6 and ux < 14.2
				h = 3 if mouth else 6
				top = DUSK_D if mouth else (MINE_D if uz < 5.4 and posmod(x, 5) != 0 else GUN)
				if Vector2(ux - 11.8, uz - 6.2).length() < 1.9:
					h = 4
					top = GUN
			# gravel vents at both ends of the deck
			if absf(ax - 12.9) < 0.7 and absf(uz - 1.0) < 0.9:
				h = 6
				top = GUN_D if absf(uz - 1.3) < 0.4 else GUN
			if h == 0:
				continue
			for y in h:
				v.put(x, y, z, top if y == h - 1 else (GUN if y > 0 else GUN_D), glow and y == h - 1)
	# rams standing in the open bays of the deck
	for ci in range(3, 17):
		for cj in range(8, 12):
			var cx := ci * 2.0 - 19.0
			var cz := cj * 2.0 - 19.0
			if posmod(ci * 3 + cj * 5, 7) < 4 or cz < -3.0 or cz > 2.0 or absf(cx) > 4.0:
				continue
			if Vector2(absf(cx) - 8.5, cz + 1.0).length() < 3.2 or Vector2(cx, cz - 1.4).length() < 3.6:
				continue
			if cz < -1.4 and absf(cx) > 1.8 and absf(cx) < 4.6:
				continue
			BossModels._ram_post(v, int(cx / u), int(cz / u), 3.4, 3, 6)
	# pipes across the deck
	for s: int in [-1, 1]:
		BossModels._pipe(v, Vector2i(s * 90, -14), Vector2i(s * 24, -14), 9)
		BossModels._pipe(v, Vector2i(s * 30, -26), Vector2i(s * 30, 10), 9)
	return v.mesh(u, Vector3(0, 3.0, 0))


## The core: a turbine in a ring housing, its glow white-hot at the hub and
## pale gold out to the ring, under five curved steel blades (it turns).
static func _dredge_core() -> ArrayMesh:
	var v := Vox.new(32, 6, 32)
	for z in range(-16, 16):
		for x in range(-16, 16):
			var r := Vector2(x + 0.5, z + 0.5).length()
			if r > 15.5:
				continue
			var a := atan2(z + 0.5, x + 0.5)
			if r > 11.0:
				v.fill(x, 0, z, x, 3, z, GUN_D)
				v.put(x, 4, z, DUSK_L if posmod(int(floor((a + PI) * 16.0 / PI)), 2) == 0 else GUN)
				continue
			v.fill(x, 0, z, x, 1, z, WHITE_HOT if r < 4.0 else ARC, true)
			var blade := absf(wrapf((a + r * 0.09) * 5.0 / TAU, -0.5, 0.5)) < 0.13 and r > 3.0
			if blade:
				v.fill(x, 2, z, x, 3, z, STEEL_M)
			elif r < 2.0:
				v.put(x, 2, z, STEEL_L)
	return v.mesh(U * 1.2, Vector3(0.5, 1.0, 0.5), true)


## A cutter wheel (turns flat on the end of its boom): a steel hub, six
## yellow spokes over a dark web, a grey rim banded yellow, ten buckets
## round it with steel teeth.
static func _dredge_wheel() -> ArrayMesh:
	var v := Vox.new(40, 7, 40)
	for z in range(-20, 20):
		for x in range(-20, 20):
			var r := Vector2(x + 0.5, z + 0.5).length()
			if r > 18.5:
				continue
			var a := atan2(z + 0.5, x + 0.5)
			if r < 3.6:
				v.fill(x, 0, z, x, 4, z, STEEL_L)
				if r < 1.6:
					v.put(x, 5, z, GUN_D)
			elif r < 12.5:
				if absf(wrapf(a * 6.0 / TAU, -0.5, 0.5)) < 0.12:
					v.fill(x, 1, z, x, 3, z, MINE)
				else:
					v.put(x, 1, z, DUSK_D)
			elif r < 15.0:
				v.fill(x, 0, z, x, 2, z, GUN)
				v.put(x, 3, z, MINE if posmod(int(floor((a + PI) * 10.0 / PI)), 2) == 0 else MINE_D)
			else:
				var seg := wrapf(a * 10.0 / TAU, -0.5, 0.5)
				if absf(seg) > 0.3:
					continue
				var inner := r < 17.3 and absf(seg) < 0.18
				v.fill(x, 0, z, x, 1 if inner else 3, z, DUSK_D if inner else DUSK_L)
				if r > 17.4:
					v.put(x, 1, z, STEEL_L)
	return v.mesh(U * 1.2, Vector3(0.5, 2.0, 0.5))


## The outer section of a boom, from its pivot (the origin) along +z: a
## truss of two dark chords with posts and braces, yellow bands now and
## then, collars at both ends.
static func _dredge_boom() -> ArrayMesh:
	var v := Vox.new(16, 5, 196)
	for z in range(0, 93):
		var band := posmod(z, 24) < 3
		v.fill_sym(4, 1, z, 5, 2, z, MINE_D if band else DUSK_L)
		if z % 6 == 0:
			v.fill(-5, 1, z, 4, 1, z, GUN)
		var bx := -4 + int(posmod(z, 12) * 8 / 12)
		v.put(bx, 1, z, GUN_D)
	v.fill(-7, 0, 0, 6, 3, 5, GUN)
	v.fill(-6, 3, 1, 5, 3, 4, STEEL_M)
	v.fill(-7, 0, 86, 6, 3, 92, GUN)
	v.fill(-6, 3, 87, 5, 3, 91, MINE_D)
	return v.mesh(U * 1.2, Vector3(0, 0.0, 0))


## The inner section that slides out of the boom (origin at its inner end):
## a narrower truss, the wheel's axle housing at the far end.
static func _dredge_jib() -> ArrayMesh:
	var v := Vox.new(12, 6, 204)
	for z in range(0, 97):
		v.fill_sym(2, 1, z, 2, 2, z, STEEL_M)
		if z % 5 == 0:
			v.fill(-2, 1, z, 1, 1, z, GUN_D)
	v.blob(0, 2, 97, 3.4, 2.0, 3.4, GUN)
	v.fill(-1, 4, 96, 0, 4, 97, STEEL_L)
	return v.mesh(U * 1.2, Vector3(0, 0.0, 0))


## The mass driver (faces -z, it turns to aim): a turntable, a yellow
## housing, twin rails forward ringed by dark coils, a cool lamp at the
## muzzle.
static func _dredge_driver() -> ArrayMesh:
	var v := Vox.new(24, 7, 64)
	for z in range(-10, 10):
		for x in range(-10, 10):
			var r := Vector2(x + 0.5, z + 0.5).length()
			if r < 9.5:
				v.fill(x, 0, z, x, 1, z, GUN)
				v.put(x, 2, z, MINE_D if r > 8.0 else STEEL_M)
	v.fill_sym(0, 3, -4, 5, 4, 6, MINE)
	v.fill_sym(0, 5, -3, 3, 5, 5, MINE_D)
	v.fill_sym(0, 5, 1, 1, 5, 1, GUN_D)
	v.fill_sym(2, 3, -30, 3, 4, -5, STEEL_L)
	v.fill_sym(0, 2, -30, 1, 2, -5, DUSK_D)
	for z in range(-28, -6, 5):
		v.fill_sym(0, 2, z, 4, 5, z, GUN_D)
	v.fill_sym(0, 3, -31, 1, 3, -31, LAMP, true)
	return v.mesh(U * 1.2, Vector3(0.5, 2.0, 0.5))
