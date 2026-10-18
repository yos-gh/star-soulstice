class_name EnemyModels
extends Models
## Small and mid-size enemies, ground guns and drifting rocks: polished gold
## and bronze armour over gunmetal, red eyes.

const NAMES := ["dart", "swirl", "rammer", "chaser", "flanker", "racer", "container", "turret_base", "turret_head", "bulwark", "railjack", "railjack_gun", "courier", "rock_s", "rock_l"]


static func make(name: String) -> ArrayMesh:
	match name:
		"dart":
			return _dart()
		"swirl":
			return _swirl()
		"rammer":
			return _rammer()
		"chaser":
			return _chaser()
		"flanker":
			return _flanker()
		"racer":
			return _racer()
		"container":
			return _container()
		"turret_base":
			return _turret_base()
		"turret_head":
			return _turret_head()
		"bulwark":
			return _bulwark()
		"railjack":
			return _railjack()
		"railjack_gun":
			return _railjack_gun()
		"courier":
			return _courier()
		"rock_s":
			return _rock(5, 0.16, 7)
		"rock_l":
			return _rock(9, 0.18, 13)
	return null


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
	return _saucer(10.5, GOLD, BRONZE)


## Lap racer: a smaller ring drone, gold and crimson.
static func _racer() -> ArrayMesh:
	return _saucer(8.5, GOLD_L, CRIM)


## A ring drone `rad` voxels across: an outer ring of alternating `a` / `b`
## segments, a gunmetal deck with gold spokes, a red eye in the middle.
static func _saucer(rad: float, a: Color, b: Color) -> ArrayMesh:
	var n := int(ceil(rad))
	var s := rad / 10.5
	var v := Vox.new(n * 2, 6, n * 2)
	for z in range(-n, n):
		for x in range(-n, n):
			var p := Vector2(x + 0.5, z + 0.5)
			var r := p.length() / s
			if r > 10.5:
				continue
			var ang := atan2(p.y, p.x)
			var seg := int(floor((ang + PI) / TAU * 8.0)) % 2 == 0
			if r > 7.5:
				v.fill(x, 1, z, x, 2, z, a if seg else b)
				if r > 9.5:
					v.put(x, 1, z, GUN_D)
			elif r > 5.0:
				v.put(x, 1, z, GUN)
				if absf(wrapf(ang * 4.0 / TAU, -0.5, 0.5)) < 0.12:
					v.fill(x, 1, z, x, 2, z, GOLD_L)
			elif r > 3.0:
				v.fill(x, 0, z, x, 3, z, GUN_D)
			else:
				v.fill(x, 0, z, x, 3, z, BRONZE)
				v.put(x, 4, z, EYE if r < 2.0 else CRIM, r < 2.0)
	return v.mesh(U, Vector3(0, 2.0, 0))


## Interceptor that strikes from behind: needle nose, swept delta wings,
## twin glowing engines and a red eye up front.
static func _chaser() -> ArrayMesh:
	var v := Vox.new(18, 6, 22)
	# spine and needle nose
	v.fill_sym(0, 1, -10, 0, 2, 7, GOLD)
	v.fill_sym(0, 3, -6, 0, 3, 5, GOLD_L)
	v.fill_sym(0, 0, -7, 1, 0, 6, GUN_D)
	v.fill_sym(0, 3, -9, 0, 3, -7, EYE, true)
	# delta wings, swept back
	for k in range(1, 9):
		v.fill_sym(k, 1, -4 + k, k, 1, 6 - k / 3, GOLD if k < 6 else BRONZE)
	v.fill_sym(8, 1, 3, 8, 2, 4, CRIM)
	# twin engines
	v.fill_sym(2, 1, 2, 3, 3, 8, GUN)
	v.fill_sym(2, 4, 3, 3, 4, 6, BRONZE)
	v.fill_sym(2, 2, 9, 3, 2, 9, AMBER, true)
	return v.mesh(U, Vector3(0, 2.0, 0))


## Side striker: a gold crescent blade opening backward around a bronze
## pod with a red eye.
static func _flanker() -> ArrayMesh:
	var v := Vox.new(24, 6, 16)
	for z in range(-8, 8):
		for x in range(-12, 12):
			var p := Vector2(x + 0.5, z + 0.5)
			var d := p.distance_to(Vector2(0, 7.0))
			if d > 7.5 and d < 11.2 and p.y < 5.5:
				var edge := d > 10.2
				v.fill(x, 1, z, x, 1 if edge else 2, z, GOLD_L if edge else GOLD)
				if d < 8.4:
					v.put(x, 1, z, BRONZE)
	v.blob(0, 2, -1, 2.6, 1.6, 4.2, BRONZE)
	v.blob(0, 3, -1, 1.6, 1.2, 2.8, GUN)
	v.fill_sym(0, 4, -4, 0, 4, -3, EYE, true)
	v.fill_sym(1, 1, 3, 1, 2, 4, GUN_D)
	v.fill_sym(1, 2, 5, 1, 2, 5, AMBER, true)
	v.fill_sym(9, 2, 4, 9, 2, 5, CRIM)
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
	# 1.5x the small-unit voxel so it stands out
	return v.mesh(U * 1.5, Vector3(0, 3.0, 0))


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


## Rail carriage (faces -z, into the tunnel; it runs along x on the wall
## rail behind it): a long gunmetal chassis on bronze wheel trucks gripping
## a rail beam at the back, gold armour on top, a red sensor slit in the
## front skirt, crimson ends with amber lamps. Its twin gun turns on top
## (railjack_gun).
static func _railjack() -> ArrayMesh:
	var v := Vox.new(42, 9, 28)
	# the rail beam at the back and the wheel trucks gripping it
	v.fill(-21, 1, 10, 20, 2, 12, GUN_D)
	for cx in [-16, -7, 5, 14]:
		v.fill(cx, 0, 7, cx + 2, 3, 11, BRONZE)
		v.fill(cx, 1, 6, cx + 2, 2, 6, BROWN)
		v.fill(cx + 1, 3, 8, cx + 1, 3, 10, GOLD_L)
	# chassis
	v.fill(-18, 1, -8, 17, 3, 6, GUN)
	v.fill(-17, 0, -7, 16, 0, 5, GUN_D)
	# armour deck with seams, a raised spine
	v.fill(-16, 4, -6, 15, 4, 5, GOLD)
	v.fill(-12, 5, -4, 11, 5, 3, GOLD_L)
	for x in [-11, -5, 4, 10]:
		v.fill(x, 4, -6, x, 5, 5, BROWN)
	# front skirt with the sensor slit
	v.fill(-17, 1, -9, 16, 3, -9, BRONZE)
	v.fill(-6, 2, -10, 5, 2, -10, EYE, true)
	# crimson ends, amber lamps
	v.fill(-19, 1, -7, -19, 3, 5, CRIM)
	v.fill(18, 1, -7, 18, 3, 5, CRIM)
	v.put(-19, 4, -7, AMBER, true)
	v.put(18, 4, -7, AMBER, true)
	# the turret ring
	v.blob(0, 6, 0, 4.4, 0.8, 4.4, GUN_D)
	return v.mesh(U * 1.2, Vector3(0, 2.5, 0))


## The rail carriage's twin gun (turns on its ring; barrels toward -z).
static func _railjack_gun() -> ArrayMesh:
	var v := Vox.new(16, 6, 28)
	v.blob(0, 1, 1, 4.2, 2.2, 4.2, BRONZE)
	v.blob(0, 2, 1, 3.0, 2.2, 3.0, GOLD)
	v.fill_sym(1, 2, -12, 2, 3, -3, GUN)
	v.fill_sym(1, 2, -13, 2, 3, -13, AMBER, true)
	v.fill_sym(0, 4, 1, 0, 4, 2, EYE, true)
	return v.mesh(U * 1.2, Vector3(0, 0, 0))


## Energy courier: a little gold-and-gunmetal frame (nose toward -z) round a
## big glowing energy canister, the colour of the energy gauge, so it reads
## as something to collect.
static func _courier() -> ArrayMesh:
	var v := Vox.new(18, 9, 20)
	var can := Color(0.55, 1.0, 0.45)
	for z in range(-9, 9):
		for x in range(-8, 8):
			var r := Vector2(x + 0.5, (z + 0.5) * 0.9).length()
			if r < 7.6 and r > 5.6:
				v.fill(x, 1, z, x, 2, z, GOLD if int(atan2(z + 0.5, x + 0.5) * 3.0) % 2 == 0 else GUN)
			elif r <= 5.6 and r > 3.6:
				v.put(x, 1, z, GUN_D)
			elif r <= 3.6:
				v.fill(x, 1, z, x, 6, z, can, true)
				if r > 2.8:
					for y in [2, 4]:
						v.put(x, y, z, GUN_D)
	v.fill(-1, 7, -1, 0, 7, 0, GOLD_L)
	v.fill_sym(0, 1, -10, 0, 2, -8, GOLD)
	v.fill_sym(6, 1, 7, 7, 2, 9, BRONZE)
	v.fill_sym(0, 2, -10, 0, 2, -10, EYE, true)
	return v.mesh(U, Vector3(0, 2.0, 0))


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

