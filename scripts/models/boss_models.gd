class_name BossModels
extends Models
## Mid-bosses and bosses: Lazaro's shell pieces and core, STAR CORTEX's
## hull, pods, eye and shutter.

const NAMES := ["lazaro_piece", "lazaro_core", "boss_hull", "boss_pod", "boss_eye", "boss_shutter"]


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
	return null


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

