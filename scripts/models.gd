class_name Models
extends RefCounted
## Every voxel model in the game, built in code. Art direction: Star
## Soldier-style space opera. Model space: x right, y up, -z forward.
##   player   white hull, red stripes, blue canopy and fins (after Caesar)
##   enemies  polished gold and bronze armour over gunmetal, red eyes
##   ground   teal-grey fortress steel (see IslandGen)
## Ships are built from stacked, bevelled plates so the baked AO and the
## sun pick out panel edges; glow voxels mark engines, sensors and lights.

# player
const WHITE := Color(0.9, 0.91, 0.94)
const LGREY := Color(0.64, 0.67, 0.72)
const DGREY := Color(0.27, 0.29, 0.33)
const RED := Color(0.86, 0.13, 0.12)
const BLUE := Color(0.14, 0.32, 0.82)
const NAVY := Color(0.08, 0.12, 0.28)
const CANOPY := Color(0.3, 0.78, 1.0)
const THRUST := Color(1.0, 0.6, 0.25)
const CYAN := Color(0.4, 0.95, 1.0)
# enemies
const GOLD := Color(0.72, 0.56, 0.27)
const GOLD_L := Color(0.84, 0.72, 0.46)
const BRONZE := Color(0.46, 0.33, 0.17)
const BROWN := Color(0.28, 0.19, 0.11)
const GUN := Color(0.33, 0.34, 0.38)
const GUN_D := Color(0.16, 0.16, 0.19)
const CRIM := Color(0.66, 0.1, 0.1)
const EYE := Color(1.0, 0.2, 0.14)
const AMBER := Color(1.0, 0.6, 0.18)
const MAGENTA := Color(1.0, 0.3, 0.6)
# kept for callers
const STEEL := GUN
const CRIMSON := CRIM
const PLUM := BRONZE
const GREEN := Color(0.35, 1.0, 0.5)
const YELLOW := Color(1.0, 0.85, 0.3)

const U := 0.09  # voxel size of small units


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
		"rock_s":
			return _rock(5, 0.16, 7)
		"rock_l":
			return _rock(9, 0.18, 13)
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
		"deep_girder":
			return _deep_girder()
		"deep_block":
			return _deep_block()
	push_error("unknown model " + name)
	return ArrayMesh.new()


# ------------------------------------------------------------ player

## Three forms: I compact delta; II adds wing cannons and a tail gun;
## III spreads long wings with emitters, canards and bigger fins.
static func _ship(lvl: int) -> ArrayMesh:
	var v := Vox.new(28, 8, 32)
	# fuselage: a pointed white body, grey belly, red nose band
	v.fill_sym(0, 1, -15, 0, 2, -13, WHITE)
	v.fill_sym(0, 1, -12, 1, 3, 10, WHITE)
	v.fill_sym(1, 1, -12, 1, 2, -11, WHITE)
	v.fill_sym(0, 0, -11, 1, 0, 9, LGREY)
	v.fill_sym(0, 3, -12, 0, 3, -11, RED)
	v.fill_sym(1, 3, -10, 1, 3, -9, RED)
	# canopy with a dark frame, spine behind it
	v.fill_sym(0, 4, -8, 0, 4, -4, CANOPY, true)
	v.fill_sym(1, 4, -8, 1, 4, -4, NAVY)
	v.fill_sym(0, 4, -3, 0, 4, 7, WHITE)
	v.fill_sym(0, 5, -1, 0, 5, 4, LGREY)
	# intakes and side bodies
	v.fill_sym(2, 1, -6, 3, 2, 9, LGREY)
	v.fill_sym(2, 1, -7, 3, 1, -7, DGREY)
	v.fill_sym(2, 3, -3, 2, 3, 8, WHITE)
	# delta wings: white with a blue trailing band and red tips
	var span := 9
	for k in range(4, span + 1):
		v.fill_sym(k, 1, -3 + (k - 4), k, 1, 8, WHITE)
	v.fill_sym(4, 1, 7, span, 1, 8, BLUE)
	v.fill_sym(4, 2, 1, 6, 2, 6, LGREY)
	v.fill_sym(span, 1, 2, span, 2, 8, RED)
	# tail fins
	v.fill_sym(2, 3, 5, 2, 6, 10, BLUE)
	v.fill_sym(2, 6, 8, 2, 6, 10, RED)
	# engines
	v.fill_sym(0, 1, 11, 2, 3, 12, DGREY)
	v.fill_sym(0, 2, 13, 1, 2, 13, THRUST, true)
	v.fill_sym(2, 1, 13, 2, 1, 13, THRUST, true)
	if lvl >= 1:
		# wing cannons and a tail gun
		v.fill_sym(6, 0, -9, 7, 1, 5, LGREY)
		v.fill_sym(6, 2, -6, 7, 2, 3, WHITE)
		v.fill_sym(6, 1, -10, 7, 1, -10, CYAN, true)
		v.fill_sym(6, 2, 4, 7, 2, 5, RED)
		v.fill_sym(0, 6, 5, 0, 6, 12, DGREY)
		v.fill_sym(0, 6, 13, 0, 6, 13, CYAN, true)
	if lvl >= 2:
		# long wings with emitters, canards, bigger fins
		for k in range(span + 1, 14):
			v.fill_sym(k, 1, -1 + (k - span) * 2, k, 1, 8, WHITE if k < 13 else RED)
		v.fill_sym(span + 1, 1, 7, 13, 1, 8, BLUE)
		v.fill_sym(13, 1, 0, 13, 2, 2, CYAN, true)
		v.fill_sym(3, 2, -13, 5, 2, -11, WHITE)
		v.fill_sym(5, 2, -13, 5, 2, -13, RED)
		v.fill_sym(3, 3, 3, 3, 7, 10, BLUE)
		v.fill_sym(3, 7, 7, 3, 7, 10, RED)
	return v.mesh(U, Vector3(0, 2.0, 0))


# ------------------------------------------------------------ enemies

## Fighter: forward-swept gold wings, red sensor eye.
static func _dart() -> ArrayMesh:
	var v := Vox.new(18, 6, 20)
	v.fill_sym(0, 1, -9, 0, 3, 6, GOLD)
	v.fill_sym(1, 1, -6, 1, 2, 6, BRONZE)
	v.fill_sym(0, 0, -7, 1, 0, 5, GUN_D)
	v.fill_sym(0, 4, -5, 0, 4, -2, EYE, true)
	v.fill_sym(0, 4, -1, 0, 4, 4, GOLD_L)
	for k in range(2, 8):
		var c := GOLD if k < 6 else BRONZE
		v.fill_sym(k, 1, -k + 1, k, 1, -k + 5, c)
	v.fill_sym(2, 2, -1, 4, 2, 2, BRONZE)
	v.fill_sym(7, 1, -7, 7, 2, -6, CRIM)
	v.fill_sym(0, 1, 7, 1, 2, 7, GUN)
	v.fill_sym(0, 2, 8, 0, 2, 8, AMBER, true)
	return v.mesh(U, Vector3(0, 2.0, 0))


## Ring drone: a spinning gold-and-bronze wheel with a red core.
static func _swirl() -> ArrayMesh:
	var v := Vox.new(22, 6, 22)
	for z in range(-11, 11):
		for x in range(-11, 11):
			var p := Vector2(x + 0.5, z + 0.5)
			var r := p.length()
			if r > 10.5:
				continue
			var a := atan2(p.y, p.x)
			var seg := int(floor((a + PI) / TAU * 8.0)) % 2 == 0
			if r > 7.5:
				v.fill(x, 1, z, x, 2, z, GOLD if seg else BRONZE)
				if r > 9.5:
					v.put(x, 1, z, GUN_D)
			elif r > 5.0:
				v.put(x, 1, z, GUN)
				if absf(wrapf(a * 4.0 / TAU, -0.5, 0.5)) < 0.12:
					v.fill(x, 1, z, x, 2, z, GOLD_L)
			elif r > 3.0:
				v.fill(x, 0, z, x, 3, z, GUN_D)
			else:
				v.fill(x, 0, z, x, 3, z, BRONZE)
				v.put(x, 4, z, EYE if r < 2.0 else CRIM, r < 2.0)
	return v.mesh(U, Vector3(0, 2.0, 0))


## Star mine: four long spikes and four short ones around a red core.
static func _rammer() -> ArrayMesh:
	var v := Vox.new(22, 6, 22)
	for k in 4:
		var d := Vector2i(1, 0) if k == 0 else (Vector2i(-1, 0) if k == 1 else (Vector2i(0, 1) if k == 2 else Vector2i(0, -1)))
		for s in range(3, 11):
			var w := 1 if s > 7 else 2
			for t in range(-w + 1, w):
				var x := d.x * s + d.y * t
				var z := d.y * s + d.x * t
				v.fill(x, 2, z, x, 3 if s < 9 else 2, z, GOLD if s < 9 else GOLD_L)
	for k in 4:
		var dx := 1 if k % 2 == 0 else -1
		var dz := 1 if k < 2 else -1
		for s in range(2, 6):
			v.fill(dx * s, 2, dz * s, dx * s, 2, dz * s, BRONZE)
	v.blob(0, 3, 0, 3.2, 2.6, 3.2, GUN)
	v.blob(0, 4, 0, 1.8, 1.4, 1.8, EYE, true)
	return v.mesh(U, Vector3(0, 3.0, 0))


## Cargo capsule: armoured gunmetal pod with gold bands and beacons.
static func _container() -> ArrayMesh:
	var v := Vox.new(20, 10, 14)
	for z in range(-6, 6):
		for x in range(-9, 9):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			if ax / 9.0 + az / 6.0 > 1.25 or az > 5.5:
				continue
			var top := 6 if az < 3.5 else 5
			if ax > 7.5:
				top -= 1
			for y in range(0, top + 1):
				var c := GUN
				if int(ax) == 3 or int(ax) == 6:
					c = GOLD
				if y == top and c == GUN:
					c = GUN.lightened(0.12)
				if y == 0:
					c = GUN_D
				v.put(x, y, z, c)
	for s: Vector2i in [Vector2i(-8, 0), Vector2i(7, 0), Vector2i(-1, -5), Vector2i(0, 4)]:
		v.put(s.x, 5, s.y, AMBER, true)
	v.fill(-1, 7, -2, 0, 7, 1, AMBER, true)
	return v.mesh(U * 1.3, Vector3(0, 3.5, 0))


static func _turret_base() -> ArrayMesh:
	var v := Vox.new(18, 3, 18)
	for z in range(-9, 9):
		for x in range(-9, 9):
			var p := Vector2(x + 0.5, z + 0.5)
			var hexd := maxf(absf(p.x) * 0.866 + absf(p.y) * 0.5, absf(p.y))
			if hexd < 8.4:
				v.put(x, 0, z, GUN_D)
			if hexd < 7.0:
				v.put(x, 1, z, GUN if hexd > 5.5 else BRONZE)
			if hexd > 7.0 and hexd < 8.4 and (x + z) % 4 == 0:
				v.put(x, 1, z, AMBER, true)
	return v.mesh(U)


## Domed gun head with twin barrels (turns as a separate mesh).
static func _turret_head() -> ArrayMesh:
	var v := Vox.new(14, 6, 22)
	v.blob(0, 1, 2, 4.4, 2.6, 4.4, GOLD)
	v.blob(0, 2, 2, 3.0, 2.4, 3.0, BRONZE)
	v.fill_sym(1, 2, -9, 1, 2, -1, GUN)
	v.fill_sym(1, 2, -10, 1, 2, -10, AMBER, true)
	v.fill_sym(1, 1, -4, 2, 3, -2, GUN_D)
	v.fill(-1, 4, 0, 0, 4, 1, EYE, true)
	return v.mesh(U, Vector3(0, 0, 0))


## Heavy cruiser (faces down-screen, +z): a hammerhead with gun ports,
## gold armour, a red reactor slit and engine nacelles at the back.
static func _bulwark() -> ArrayMesh:
	var v := Vox.new(50, 9, 34)
	# spine hull
	v.fill_sym(0, 1, -15, 3, 4, 9, GUN)
	v.fill_sym(0, 5, -12, 2, 5, 6, GOLD)
	v.fill_sym(0, 6, -9, 1, 6, 3, GOLD_L)
	v.fill_sym(0, 5, -4, 0, 6, 1, EYE, true)
	v.fill_sym(0, 0, -13, 3, 0, 8, GUN_D)
	# hammer head
	v.fill_sym(0, 1, 9, 14, 4, 14, GUN)
	v.fill_sym(0, 5, 10, 12, 5, 13, GOLD)
	v.fill_sym(13, 5, 10, 14, 5, 13, BRONZE)
	for x in [2, 5, 8, 11, 14]:
		v.fill_sym(x, 2, 15, x, 3, 16, GUN_D)
		v.fill_sym(x, 2, 16, x, 2, 16, EYE, true)
	v.fill_sym(0, 0, 10, 13, 0, 14, GUN_D)
	# swept wings and nacelles
	for k in range(4, 18):
		v.fill_sym(k, 1, -6 + (k - 4) / 2, k, 2, 6 - (k - 4) / 3, GUN if k % 4 != 0 else GUN_D)
	v.fill_sym(5, 3, -3, 14, 3, 3, BRONZE)
	v.fill_sym(6, 4, -1, 12, 4, 2, GOLD)
	v.fill_sym(18, 1, -10, 21, 4, 4, GUN)
	v.fill_sym(18, 5, -8, 21, 5, 2, GOLD)
	v.fill_sym(19, 2, 5, 20, 3, 5, EYE, true)
	v.fill_sym(18, 2, -11, 21, 3, -11, AMBER, true)
	v.fill_sym(1, 2, -16, 3, 3, -16, AMBER, true)
	return v.mesh(U * 1.2, Vector3(0, 3.0, 0))


## One quarter of Lazaro's shell: the +x/+z quadrant of a hollow sphere of
## gold armour plates with dark seams and a red equator, re-centred on its
## own centroid so the pieces can fly apart.
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
					c = BROWN if seam else (GOLD if int(floor(lat) + floor(lon)) % 2 == 0 else BRONZE)
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

## STAR CORTEX hull (Star Brain homage): an octagonal gold-and-gunmetal
## fortress (faces down-screen) with stepped armour rings, flank gun decks
## and a channel in front of the brain, so shots from below reach it.
static func _boss_hull() -> ArrayMesh:
	var v := Vox.new(120, 12, 88)
	for z in range(-44, 44):
		for x in range(-60, 60):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			var oct := maxf(maxf(ax / 57.0, az / 42.0), (ax + az) / 76.0)
			if oct > 1.0 or oct < 0.36:
				continue
			if ax < 11.0 and z > 0:
				continue
			var h := 4
			var top := GUN
			if oct < 0.5:
				h = 9
				top = GOLD
			elif oct < 0.66:
				h = 7
				top = GUN.lightened(0.1)
			elif oct < 0.84:
				h = 6
				top = BRONZE
			if oct > 0.94:
				h = 3
				top = GUN_D
			if absf(oct - 0.5) < 0.012 or absf(oct - 0.66) < 0.012 or absf(oct - 0.84) < 0.012:
				top = BROWN
			if (int(ax) % 10 == 0 or int(az) % 8 == 0) and oct >= 0.5 and oct < 0.94:
				top = top.darkened(0.25)
			for y in h:
				v.put(x, y, z, top if y == h - 1 else (GUN if y > 1 else GUN_D))
	for z in range(1, 34):
		if z % 4 == 0:
			v.put(-12, 5, z, EYE, true)
			v.put(11, 5, z, EYE, true)
	for s in [-1, 1]:
		v.fill(s * 30, 7, -10, s * 44, 8, 8, GUN)
		v.fill(s * 31, 9, -8, s * 43, 9, 6, GOLD)
		for z in [-6, -1, 4]:
			v.fill(s * 34, 9, z, s * 40, 9, z, BROWN)
		v.fill(s * 45, 6, -3, s * 52, 6, 2, GUN_D)
		v.fill(s * 52, 6, -3, s * 52, 6, 2, AMBER, true)
	for a in 24:
		var ang := a * TAU / 24.0
		var x := int(round(cos(ang) * 23.0))
		var z := int(round(sin(ang) * 17.0))
		if absf(x) < 12 and z > 0:
			continue
		v.put(x, 9, z, EYE, true)
	v.fill(-3, 9, -43, 2, 10, -30, GUN)
	v.fill(-1, 11, -43, 0, 11, -36, AMBER, true)
	return v.mesh(U * 1.2, Vector3(0.5, 6.0, 0.5))


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
					c = GUN_D if r > 11.5 else (GOLD if r > 7.0 else BRONZE)
					if absf(r - 9.2) < 0.6:
						c = BROWN
				v.put(x, y, z, c)
	v.fill_sym(1, 3, 6, 2, 4, 15, GUN_D)
	v.fill_sym(1, 4, 15, 2, 4, 15, EYE, true)
	v.fill(-2, 6, -2, 2, 7, 2, GUN_D)
	v.fill(-1, 8, -1, 1, 8, 1, EYE, true)
	return v.mesh(U * 1.2, Vector3(0.5, 3.0, 0.5))


## The brain: a ridged pink dome (grooves from a noise field) around a red
## iris.
static func _boss_eye() -> ArrayMesh:
	var v := Vox.new(36, 14, 36)
	for z in range(-17, 18):
		for x in range(-17, 18):
			var r := Vector2(x, z).length()
			if r > 17.0:
				continue
			var h := int(round(sqrt(maxf(0.0, 17.5 * 17.5 - r * r)) * 0.55))
			var groove := absf(sin(x * 0.55 + sin(z * 0.4) * 1.8)) < 0.22 and r > 8.0
			for y in h:
				var c := Color(0.86, 0.6, 0.66)
				var glow := false
				if y == h - 1:
					if r < 3.5:
						c = Color(0.06, 0.0, 0.02)
					elif r < 7.0:
						c = EYE if int(r * 1.5) % 2 == 0 else MAGENTA
						glow = true
					elif r < 8.0:
						c = Color(0.25, 0.05, 0.08)
					elif groove:
						c = Color(0.5, 0.22, 0.3)
				v.put(x, y, z, c, glow)
	return v.mesh(U * 1.2, Vector3(0.5, 5.0, 0.5))


## One half of the brain's armoured shutter (the left half; mirrored).
static func _boss_shutter() -> ArrayMesh:
	var v := Vox.new(40, 4, 40)
	for z in range(-19, 20):
		for x in range(-20, 0):
			var d := Vector2(x + 0.5, z).length()
			if d >= 19.5:
				continue
			var c := GOLD if (z + 20) % 6 > 1 else BRONZE
			var glow := false
			if x == -1:
				c = AMBER
				glow = true
			elif d > 17.5:
				c = GUN_D
			v.put(x, 0, z, c, glow)
			if d < 15.0 and x < -2:
				v.put(x, 1, z, GUN if (z + 20) % 6 > 1 else BROWN)
	return v.mesh(U * 1.2, Vector3(0, 0, 0.5))


## Drifting asteroid chunk (debris belt), lumpy and dark.
static func _rock(seed: int, unit: float, size: int) -> ArrayMesh:
	var v := Vox.new(size * 2 + 2, size * 2, size * 2 + 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	v.blob(0, size, 0, size * 0.8, size * 0.6, size * 0.75, Color(0.33, 0.3, 0.27))
	for i in 6:
		v.blob(rng.randi_range(-size / 2, size / 2), size + rng.randi_range(-size / 3, size / 3), rng.randi_range(-size / 2, size / 2), size * rng.randf_range(0.3, 0.5), size * rng.randf_range(0.3, 0.45), size * rng.randf_range(0.3, 0.5), Color(0.4, 0.36, 0.31) if i % 2 == 0 else Color(0.26, 0.24, 0.22))
	for i in 4:
		v.put(rng.randi_range(-size / 2, size / 2), size + size / 2, rng.randi_range(-size / 2, size / 2), Color(0.5, 0.35, 0.95), true)
	return v.mesh(unit, Vector3(0, size, 0))


# ------------------------------------------------------------ items

static func _energy() -> ArrayMesh:
	var v := Vox.new(4, 6, 4)
	v.jitter = 0.0
	# a lit crystal with a dim self-lit band: readable, but no bloom
	var body := Color(0.34, 0.66, 0.5)
	var band := Color(0.3, 0.72, 0.46)
	v.fill(-1, 1, -1, 0, 4, 0, body)
	v.fill(-2, 2, -1, 1, 3, 0, band, true)
	v.fill(-1, 2, -2, 0, 3, 1, band, true)
	v.fill(-1, 0, -1, 0, 0, 0, body.darkened(0.2))
	v.fill(-1, 5, -1, 0, 5, 0, body.lightened(0.2))
	return v.mesh(0.09, Vector3(0, 3.0, 0), true)


## Power capsule: blue shell with white caps, a glowing band and a "P".
static func _power() -> ArrayMesh:
	var v := Vox.new(16, 7, 10)
	v.blob(0, 3, 0, 6.5, 2.6, 3.2, BLUE)
	v.fill(-7, 2, -1, -6, 4, 0, WHITE)
	v.fill(5, 2, -1, 6, 4, 0, WHITE)
	v.fill(-5, 3, -3, 4, 3, 2, CYAN, true)
	v.fill(-1, 5, -2, -1, 6, 2, WHITE)
	v.fill(0, 6, -2, 1, 6, -2, WHITE)
	v.fill(0, 6, 0, 1, 6, 0, WHITE)
	v.put(1, 6, -1, WHITE)
	return v.mesh(0.12, Vector3(0, 3.0, 0))


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

## Destructible armour hatch (one Island cell, 16 x 16 voxels).
## 0 teal service hatch (green LED), 1 steel-blue cross hatch (amber LED),
## 2 heavy blast door (red LED).
static func _tile(kind: int) -> ArrayMesh:
	var v := Vox.new(16, 5, 16)
	var base: Color = [Color(0.3, 0.46, 0.48), Color(0.34, 0.38, 0.5), Color(0.3, 0.31, 0.35)][kind]
	var hi := base.lightened(0.22)
	var lo := base.darkened(0.45)
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


## Far-below truss girder: two chords with diagonal braces (unit 1.0).
static func _deep_girder() -> ArrayMesh:
	var v := Vox.new(90, 6, 8)
	var c := Color(0.1, 0.12, 0.14)
	for x in range(-45, 45):
		v.fill(x, 0, -3, x, 1, -3, c)
		v.fill(x, 0, 3, x, 1, 3, c)
		v.put(x, 4, 0, c)
		var t := posmod(x, 8)
		var zz := -3 + int(t * 6 / 8)
		v.put(x, 1 + t / 3, zz, c.darkened(0.2))
		if t == 0:
			v.fill(x, 0, -3, x, 4, 3, c.darkened(0.1))
			v.put(x, 5, 0, Color(0.3, 0.08, 0.07))
	return v.mesh(1.0, Vector3(0, 3, 0))


## Far-below hull block with window lights (unit 1.0).
static func _deep_block() -> ArrayMesh:
	var v := Vox.new(40, 8, 24)
	var c := Color(0.1, 0.12, 0.14)
	for z in range(-12, 12):
		for x in range(-20, 20):
			var ax := absf(x + 0.5)
			var az := absf(z + 0.5)
			if ax + az > 26.0:
				continue
			var h := 4 if ax > 14 or az > 8 else 6
			for y in h:
				var col := c if y == h - 1 else c.darkened(0.3)
				if y == h - 2 and (ax > 13.5 and ax < 14.5 or az > 7.5 and az < 8.5) and (x + z) % 3 == 0:
					v.put(x, y + 1, z, Color(0.3, 0.25, 0.16))
				v.put(x, y, z, col)
	return v.mesh(1.0, Vector3(0, 4, 0))
