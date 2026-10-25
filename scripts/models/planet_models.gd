class_name PlanetModels
extends Models
## Stage 4, the enemy planet: the cloud banks the stage comes down through
## (scenery, in their own hazed material, see shaders/cloud.gdshader) and
## the planet's forces: the KESTREL gunship (sand armour on a dark grey
## frame, warm and matte, after desert military craft), TEMPEST (cool
## slate steel, warm brown glazed insulators, a lilac storm glow) and
## BEHEMOTH (gunmetal machinery in the KESTREL's sand on its armour, a
## hazard-striped dozer blade, a pale gold reactor).

const NAMES := ["cloud_a", "cloud_b", "cloud_c", "kestrel", "kestrel_fan", "kestrel_gun", "kestrel_barrels", "tempest_hull", "tempest_core", "tempest_coil", "tempest_rotor", "behemoth_hull", "behemoth_tread", "behemoth_turret", "behemoth_barrels", "behemoth_sponson", "behemoth_core", "behemoth_louvre", "behemoth_shell"]

const CLOUD_HI := Color(0.53, 0.52, 0.59)
const CLOUD_MID := Color(0.39, 0.38, 0.46)
const CLOUD_LO := Color(0.24, 0.23, 0.3)
const SAND := Color(0.52, 0.46, 0.33)
const SAND_L := Color(0.62, 0.55, 0.41)
const SAND_D := Color(0.38, 0.33, 0.24)
const SLATE := Color(0.3, 0.335, 0.37)
const SLATE_L := Color(0.38, 0.42, 0.46)
const SLATE_D := Color(0.2, 0.225, 0.255)
const GLAZE := Color(0.44, 0.27, 0.17)  # glazed insulator porcelain
const GLAZE_L := Color(0.56, 0.37, 0.24)
const LILAC := Color(0.8, 0.74, 1.0)  # the storm's glow (lightning, the generator)

static var _cloud_mat: ShaderMaterial
static var _deep_mat: ShaderMaterial


static func make(name: String) -> ArrayMesh:
	match name:
		"cloud_a":
			return _cloud(11, 15.0, 12.0, 7)
		"cloud_b":
			return _cloud(23, 12.0, 11.0, 5)
		"cloud_c":
			return _cloud(37, 17.0, 13.0, 10)
		"kestrel":
			return _kestrel()
		"kestrel_fan":
			return _kestrel_fan()
		"kestrel_gun":
			return _kestrel_gun()
		"kestrel_barrels":
			return _kestrel_barrels()
		"tempest_hull":
			return _tempest_hull()
		"tempest_core":
			return _tempest_core()
		"tempest_coil":
			return _tempest_coil()
		"tempest_rotor":
			return _tempest_rotor()
		"behemoth_hull":
			return _behemoth_hull()
		"behemoth_tread":
			return _behemoth_tread()
		"behemoth_turret":
			return _behemoth_turret()
		"behemoth_barrels":
			return _behemoth_barrels()
		"behemoth_sponson":
			return _behemoth_sponson()
		"behemoth_core":
			return _behemoth_core()
		"behemoth_louvre":
			return _behemoth_louvre()
		"behemoth_shell":
			return _behemoth_shell()
	return null


## The cloud banks' material (Palette sets its colours).
static func cloud_material() -> ShaderMaterial:
	if _cloud_mat == null:
		_cloud_mat = ShaderMaterial.new()
		_cloud_mat.shader = load("res://shaders/cloud.gdshader")
	return _cloud_mat


## The same for the base's facade (TunnelModels._facade), which reaches far
## down into the air: lit near the top, melting into the haze below
## (the ground's material would go dark in the fog and read as a veil).
static func deep_material() -> ShaderMaterial:
	if _deep_mat == null:
		_deep_mat = ShaderMaterial.new()
		_deep_mat.shader = load("res://shaders/cloud.gdshader")
		_deep_mat.set_shader_parameter("near_y", -3.0)
		_deep_mat.set_shader_parameter("far_y", -44.0)
		_deep_mat.set_shader_parameter("haze_max", 0.8)
		_deep_mat.set_shader_parameter("dim", 0.7)
	return _deep_mat


# ------------------------------------------------------------ clouds

## A cloud bank: a cluster of round billows (each grown off the edge of
## one before it, smaller), squashed and sitting on a flat base, their
## surfaces knobbly; the tops lit, the flanks mid, the base in shade.
## `rx`, `rz`: the first billow's radius (voxels), `puffs` how many more.
static func _cloud(seed: int, rx: float, rz: float, puffs: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var r0 := (rx + rz) * 0.5
	var blobs := [[Vector3(0, r0 * 0.3, 0), r0]]
	for i in puffs:
		var parent: Array = blobs[rng.randi_range(0, blobs.size() - 1)]
		var pr: float = parent[1]
		var r := maxf(pr * rng.randf_range(0.55, 0.9), r0 * 0.35)
		var a := rng.randf() * TAU
		var at: Vector3 = parent[0] + Vector3(cos(a) * pr * 0.85 * (rx / r0), 0, sin(a) * pr * 0.85 * (rz / r0))
		blobs.append([Vector3(at.x, r * 0.3, at.z), r])
	var X := 4
	var Z := 4
	var top := 0.0
	for b: Array in blobs:
		var c: Vector3 = b[0]
		var r: float = b[1]
		X = maxi(X, int(ceil(absf(c.x) + r * 1.15)) + 2)
		Z = maxi(Z, int(ceil(absf(c.z) + r)) + 2)
		top = maxf(top, c.y + r * 0.6)
	var H := int(ceil(top)) + 2
	var v := Vox.new(X * 2, H, Z * 2)
	v.jitter = 0.03
	for z in range(-Z, Z):
		for x in range(-X, X):
			for y in H:
				var p := Vector3(x + 0.5, y + 0.5, z + 0.5)
				var knob := 1.0 - 0.08 * Vox._hash(x >> 1, y >> 1, z >> 1)
				var inside := false
				for b: Array in blobs:
					var q: Vector3 = p - b[0]
					var r: float = b[1]
					if Vector3(q.x / (r * 1.1), q.y / (r * 0.6), q.z / r).length_squared() < knob * knob:
						inside = true
						break
				if not inside:
					continue
				var f := float(y) / maxf(top, 1.0)
				var col := CLOUD_MID
				if f < 0.25:
					col = CLOUD_LO
				elif f > 0.55:
					col = CLOUD_HI
				v.put(x, y, z, col)
	var m := v.mesh(0.45, Vector3(0, 0, 0))
	for i in m.get_surface_count():
		m.surface_set_material(i, cloud_material())
	return m


# ------------------------------------------------------------ KESTREL

## The gunship (faces down-screen, +z): a fuselage, its frame dark grey
## under sand armour plates with seams and a ridge down the back, a raised
## canopy with a red sensor at the nose; stub wings out to two ducted fan
## housings (sand rims banded dark, the duct open: the fans are separate
## and turn), a gun pod on the front of each housing; a tail boom with a V
## tail and a dim exhaust. The chin turret is separate.
static func _kestrel() -> ArrayMesh:
	var v := Vox.new(36, 10, 42)
	# the fuselage
	v.fill_sym(0, 1, -12, 3, 4, 9, DUSK)
	v.fill_sym(0, 0, -10, 1, 0, 8, DUSK_D)
	v.fill_sym(0, 5, -10, 3, 5, 8, SAND)
	v.fill_sym(0, 6, -9, 0, 6, 1, SAND_D)
	for z: int in [-6, -1, 4]:
		v.fill_sym(0, 5, z, 3, 5, z, SAND_D)
	v.fill_sym(4, 2, -9, 4, 4, 6, DUSK_L)
	v.fill_sym(4, 5, -7, 4, 5, 3, SAND_D)
	# the nose and the canopy
	v.fill_sym(0, 1, 10, 1, 4, 12, DUSK)
	v.fill_sym(0, 5, 10, 1, 5, 11, SAND_L)
	v.fill_sym(0, 6, 3, 1, 6, 7, DUSK_D)
	v.fill_sym(0, 6, 4, 0, 6, 6, GUN)
	v.fill_sym(0, 5, 12, 0, 5, 12, EYE, true)
	# stub wings out to the fans
	v.fill_sym(4, 2, -2, 7, 3, 2, DUSK_L)
	v.fill_sym(4, 4, -1, 7, 4, 1, SAND_D)
	# the fan housings (centred 11 voxels out) and their gun pods
	for z in range(-7, 7):
		for xi in range(4, 18):
			var d := Vector2(xi + 0.5 - 11.0, z + 0.5)
			var r := d.length()
			if r > 5.8:
				continue
			if r > 4.3:
				var seg := posmod(int(floor((atan2(d.y, d.x) + PI) * 8.0 / PI)), 2) == 0
				v.fill_sym(xi, 1, z, xi, 3, z, DUSK)
				v.fill_sym(xi, 4, z, xi, 4, z, SAND if seg else SAND_D)
			else:
				v.fill_sym(xi, 0, z, xi, 0, z, DUSK_D)
				if r < 1.0:
					v.fill_sym(xi, 1, z, xi, 1, z, GUN)
	v.fill_sym(10, 2, 5, 12, 3, 8, GUN)
	v.fill_sym(11, 4, 5, 11, 4, 7, SAND_D)
	v.fill_sym(11, 2, 9, 11, 2, 9, DUSK_L)
	# the tail boom, V tail and exhaust
	v.fill_sym(0, 2, -18, 1, 3, -13, DUSK)
	v.fill_sym(0, 4, -17, 0, 4, -13, SAND_D)
	for k in 4:
		v.fill_sym(1 + k, 4 + k / 2, -19 + k / 2, 1 + k, 4 + k / 2, -17 + k / 2, SAND if k < 3 else SAND_L)
	v.fill_sym(0, 2, -19, 0, 3, -19, AMBER, true)
	return v.mesh(U * 1.45, Vector3(0, 2.5, 0))


## A lift fan: five blades round a hub (it turns in its duct).
static func _kestrel_fan() -> ArrayMesh:
	var v := Vox.new(10, 1, 10)
	for z in range(-5, 5):
		for x in range(-5, 5):
			var p := Vector2(x + 0.5, z + 0.5)
			var r := p.length()
			if r > 4.2:
				continue
			if r < 1.2:
				v.put(x, 0, z, DUSK_L)
				continue
			if absf(wrapf(atan2(p.y, p.x) * 5.0 / TAU + r * 0.08, -0.5, 0.5)) < 0.17:
				v.put(x, 0, z, STEEL_M)
	return v.mesh(U * 1.45, Vector3(0, 0.5, 0))


## The chin turret's mount (turns to aim, barrels along +z): a squat dome
## on a yoke; the barrels are separate and spin.
static func _kestrel_gun() -> ArrayMesh:
	var v := Vox.new(8, 3, 8)
	v.blob(0, 0, 0, 2.6, 1.6, 2.6, DUSK_L)
	v.fill(-2, 1, 1, 1, 1, 3, GUN)
	v.put(-1, 2, 0, SAND_D)
	v.put(0, 2, 0, SAND_D)
	return v.mesh(U * 1.45, Vector3(0, 0.5, 0))


## The rotary cannon: a square cluster of barrels along +z with a band
## round the muzzle (it spins about its length).
static func _kestrel_barrels() -> ArrayMesh:
	var v := Vox.new(4, 4, 12)
	v.fill(-1, 1, 0, 0, 2, 5, GUN)
	v.fill(-2, 0, 1, 1, 3, 1, DUSK_L)
	v.fill(-2, 0, 4, 1, 3, 4, DUSK)
	v.put(-1, 1, 5, DUSK_D)
	v.put(0, 2, 5, DUSK_D)
	return v.mesh(U * 1.45, Vector3(0, 2.0, 0))


# ------------------------------------------------------------ TEMPEST

## TEMPEST's frame (faces down-screen, +z; the generator, the masts and the
## rotors are separate), machinery left open on a bare frame: the four
## ducted rotors (segmented duct rings with dim lilac lamps, stator vanes
## and a hub under the turning rotor, a hail nozzle on the front of each),
## each hung on a truss boom by a gearbox block with a tilt ram; bus-bar
## cables along the booms on brown insulator studs; the generator's ring
## round its well (bare windings in bands, insulators set round it); two
## transformer drums behind it, wound in bands, capacitor rows and cooling
## fins between; a truss spine with an insulated bus bar up its middle to
## the aft mast; bolted mast pads skirted with insulators.
static func _tempest_hull() -> ArrayMesh:
	var u := U * 1.2
	var v := Vox.new(226, 9, 112)
	var core := Vector2(0.0, 0.8)
	var rotors := [Vector2(9.5, -3.0), Vector2(7.0, 3.0)]  # (and their mirrors)
	var masts := [Vector2(0.0, -4.4), Vector2(3.9, 1.6)]
	var booms := [[Vector2(2.2, -1.2), rotors[0]], [Vector2(2.0, 2.0), rotors[1]]]
	var dim_lilac := Color(0.55, 0.5, 0.75)
	for z in range(-56, 56):
		for x in range(-113, 113):
			var q := Vector2((x + 0.5) * u, (z + 0.5) * u)
			var ax := absf(q.x)
			var sq := Vector2(ax, q.y)
			var h := -1
			var top := SLATE
			var glow := false
			# the booms: a truss (two chords, braces), a bus bar on studs
			for bm: Array in booms:
				var a: Vector2 = bm[0]
				var b: Vector2 = bm[1]
				var d := (b - a).normalized()
				var t := (sq - a).dot(d)
				var s := (sq - a).dot(Vector2(-d.y, d.x))
				var l := a.distance_to(b) - 2.4
				if t > 0.0 and t < l and absf(s) < 0.5:
					var chord := absf(s) > 0.34
					var brace := absf(fposmod(t + absf(s) * 1.6, 0.9) - 0.45) < 0.08
					if chord or brace:
						h = 4
						top = SLATE_D if chord else DUSK_L
					if absf(s - 0.12) < 0.07:
						h = 5
						top = GLAZE if fposmod(t, 0.6) < 0.14 else DUSK_L
				# the gearbox block where the boom meets the duct, its tilt ram
				var gb := a + d * (l + 0.1)
				var gq := sq - gb
				if absf(gq.dot(d)) < 0.45 and absf(gq.dot(Vector2(-d.y, d.x))) < 0.55:
					h = 5
					top = GUN if posmod(x + z, 3) != 0 else DUSK
				var ram := Geometry2D.get_closest_point_to_segment(sq, a + d * (l - 0.9) + Vector2(-d.y, d.x) * 0.45, gb + Vector2(-d.y, d.x) * 0.45)
				if sq.distance_to(ram) < 0.07:
					h = 5
					top = STEEL_L
			# the spine to the aft mast: a truss, the bus bar up the middle
			if ax < 0.6 and q.y < -1.2 and q.y > -4.4:
				if ax > 0.42:
					h = 4
					top = SLATE_D
				elif absf(fposmod(q.y + ax * 1.5, 0.7) - 0.35) < 0.07:
					h = 3
					top = DUSK_L
				if ax < 0.12:
					h = 5
					top = GLAZE if fposmod(q.y, 0.6) < 0.14 else DUSK_L
			# behind the generator: two transformer drums wound in bands,
			# capacitor rows and cooling fins between
			if ax < 2.1 and q.y < -0.9 and q.y > -3.6:
				h = 2
				top = DUSK_D
				var rd := Vector2(ax - 1.15, q.y + 2.35).length()
				if rd < 0.8:
					h = 5 if rd < 0.7 else 4
					top = (SLATE_L if posmod(int(floor((q.y + 10.0) / 0.22)), 2) == 0 else SLATE_D) if rd > 0.25 else GUN
				elif ax < 0.35:
					var fin := posmod(z, 2) == 0
					h = 4 if fin else 2
					top = STEEL_M if fin else DUSK_D
				elif q.y < -3.15 or q.y > -1.25:
					var cap := fposmod(ax, 0.42) < 0.26
					h = 4 if cap else 3
					top = STEEL_L if cap else GUN
			# the generator's ring: bare windings in bands, insulators round it
			var rc := q.distance_to(core)
			var ac := atan2(q.y - core.y, q.x)
			if rc < 2.6:
				if rc > 1.95:
					var ins := absf(wrapf(ac * 8.0 / TAU, -0.5, 0.5)) < 0.1 and rc > 2.15 and rc < 2.45
					h = 5 if ins else 4
					top = GLAZE_L if ins else (SLATE_L if posmod(int(floor((ac + PI) * 20.0 / PI)), 2) == 0 else SLATE)
				elif rc > 1.85:
					h = 2
					top = DUSK_D
				elif rc <= 1.85:
					h = 1
					top = DUSK_D
			# bus bars from the generator out to the front masts
			for bar: Array in [[Vector2(1.95, 1.2), Vector2(2.95, 1.45)], [Vector2(0.0, -1.2), Vector2(0.0, -1.0)]]:
				if sq.distance_to(Geometry2D.get_closest_point_to_segment(sq, bar[0], bar[1])) < 0.1:
					h = maxi(h, 5)
					top = DUSK_L
			# the mast pads: bolted, skirted with insulators
			for m: Vector2 in masts:
				var rm := sq.distance_to(m)
				if rm < 1.4:
					if rm > 1.12:
						h = 4
						top = GLAZE if absf(wrapf(atan2(sq.y - m.y, sq.x - m.x) * 10.0 / TAU, -0.5, 0.5)) < 0.22 else DUSK
					else:
						h = 3
						top = DUSK if posmod(x + z, 4) != 0 else DUSK_D
			# the ducted rotors: segmented rings with lamps, stator vanes and
			# a hub under the rotor, the hail nozzle in front
			for r: Vector2 in rotors:
				var rr := sq.distance_to(r)
				var ar := atan2(sq.y - r.y, sq.x - r.x)
				if rr < 2.45:
					if rr > 1.95:
						h = 6 if rr > 2.3 else 5
						var band := posmod(int(floor((ar + PI) * 8.0 / PI)), 2) == 0
						top = SLATE if band else SLATE_D
						if rr > 2.3 and posmod(int(floor((ar + PI) * 12.0 / PI)), 6) == 0:
							top = dim_lilac
							glow = true
					elif rr < 0.5:
						h = 2
						top = GUN if rr > 0.32 else DUSK_L
					elif absf(wrapf((ar - PI / 4.0) * 4.0 / TAU, -0.5, 0.5)) < 0.04 * (2.0 / rr):
						h = 1
						top = DUSK_L
					else:
						h = 0
						top = DUSK_D
				if sq.y > r.y + 1.9 and sq.y < r.y + 2.7 and absf(sq.x - r.x) < 0.35:
					h = 5
					top = GUN if sq.y < r.y + 2.55 else DUSK_D
			if h < 0:
				continue
			for y in range(0, h + 1):
				v.put(x, y, z, top if y == h else (SLATE_D if y > h - 2 else DUSK_D), glow and y == h)
	return v.mesh(u, Vector3(0, 3.0, 0))


## The storm generator: a squat drum in its well, slotted round the side,
## its heart a lilac-white glow seen through four turning vanes.
static func _tempest_core() -> ArrayMesh:
	var v := Vox.new(36, 6, 36)
	for z in range(-18, 18):
		for x in range(-18, 18):
			var r := Vector2(x + 0.5, z + 0.5).length()
			if r > 17.0:
				continue
			var a := atan2(z + 0.5, x + 0.5)
			if r > 12.5:
				v.fill(x, 0, z, x, 3, z, DUSK)
				var slot := posmod(int(floor((a + PI) * 12.0 / PI)), 3) == 0
				v.put(x, 4, z, LILAC if slot and r < 14.0 else SLATE_D, slot and r < 14.0)
				continue
			v.fill(x, 0, z, x, 1, z, WHITE if r < 4.5 else LILAC, true)
			var vane := absf(wrapf((a + r * 0.07) * 4.0 / TAU, -0.5, 0.5)) < 0.1 and r > 3.0
			if vane:
				v.fill(x, 2, z, x, 3, z, SLATE_L)
			elif r < 2.2:
				v.put(x, 2, z, SLATE)
	return v.mesh(U * 1.2, Vector3(0.5, 1.0, 0.5), true)


## A lightning mast: a dark base, a stack of glazed insulator discs (wide
## and narrow by turns, the glaze lighter on the wide ones), a steel toroid
## on top with the lilac glow inside its ring.
static func _tempest_coil() -> ArrayMesh:
	var v := Vox.new(24, 11, 24)
	for z in range(-12, 12):
		for x in range(-12, 12):
			var r := Vector2(x + 0.5, z + 0.5).length()
			if r < 11.0:
				v.fill(x, 0, z, x, 1, z, DUSK if r > 9.6 else DUSK_L)
			for y in range(2, 8):
				var wide := y % 2 == 0
				if r < (6.8 if wide else 4.8):
					v.put(x, y, z, GLAZE_L if wide and r > 5.2 else GLAZE)
			if r < 8.6 and r > 5.4:
				v.fill(x, 8, z, x, 9, z, STEEL_L if r > 6.4 else STEEL_M)
			elif r <= 5.4 and r > 3.6:
				v.put(x, 9, z, LILAC, true)
			elif r <= 3.6:
				v.put(x, 8, z, SLATE_D)
	return v.mesh(U * 1.2, Vector3(0.5, 2.0, 0.5))


## A lift rotor: four long blades round a hub (it turns in its duct).
static func _tempest_rotor() -> ArrayMesh:
	var v := Vox.new(36, 1, 36)
	for z in range(-18, 18):
		for x in range(-18, 18):
			var p := Vector2(x + 0.5, z + 0.5)
			var r := p.length()
			if r > 17.5:
				continue
			if r < 2.4:
				v.put(x, 0, z, SLATE_L if r < 1.4 else DUSK_L)
				continue
			if absf(wrapf(atan2(p.y, p.x) * 4.0 / TAU + r * 0.012, -0.5, 0.5)) < 0.085:
				v.put(x, 0, z, STEEL_M if r < 15.0 else SLATE_D)
	return v.mesh(U * 1.2, Vector3(0, 0.5, 0))


# ------------------------------------------------------------ BEHEMOTH

## BEHEMOTH's hull (faces down-screen, +z; the turret, sponsons, reactor,
## shutters and treads are separate), on the arena deck (y -3). The tracks:
## rails, segmented sand skirts with bolts over the front half, the tread
## bare behind, round sprocket housings at the ends. Between them a machine
## left open almost everywhere, plated only in places: the stepped glacis
## (headlamp clusters, the hull gun's ball mount); the geared turret ring
## round the turret basket (ammunition racks, spokes, a hub: it shows once
## the turret is gone); geared sponson rings with ammunition chutes in; the
## reactor's well behind, its rim bolted, shutter rails across it, coolant
## pipes out to banks of heat-sink fins either side; spare track links and
## tool bins along the flanks; the engine at the back (a row of cylinder
## heads, two radiator fans in their ducts, exhaust pipes to two stacks);
## the howitzer casemates on the back corners (armoured boxes, the short
## barrel between its recoil cylinders, an ammunition hoist behind); the
## dozer blade across the front on two arms a side with a hydraulic ram
## between them, push ribs on its back, hazard stripes on its edge.
static func _behemoth_hull() -> ArrayMesh:
	var u := U * 1.5
	var v := Vox.new(136, 23, 112)
	var oy := 3.0 / u  # row 0 sits on the deck (y -3)
	var row := func(y: float) -> int: return int(round(y / u + oy))
	var deck: int = row.call(-0.75)
	for z in range(-56, 56):
		for x in range(-68, 68):
			var q := Vector2((x + 0.5) * u, (z + 0.5) * u)
			var ax := absf(q.x)
			var sq := Vector2(ax, q.y)  # the right half (mirrored)
			var cols := []  # [from row, to row, top colour, glow]
			# ---- the tracks
			if ax >= 6.3 and ax <= 8.9 and q.y >= -6.5 and q.y <= 6.3:
				if q.y < -5.4 or q.y > 5.2:
					# sprocket housings, round, a hub in the middle
					var c := Vector2(7.6, -5.95 if q.y < 0.0 else 5.75)
					var r := Vector2((ax - c.x) / 1.3, (q.y - c.y) / 0.6).length()
					if r < 1.0:
						cols.append([0, row.call(-0.8), STEEL_M if r < 0.3 else (DUSK_L if r < 0.45 else GUN), false])
					else:
						cols.append([0, row.call(-1.2), DUSK, false])
				elif ax > 8.6 or ax < 6.55:
					var bolt := posmod(z, 4) == 0
					# return rollers on the rails behind the skirts
					var roller := q.y < -0.4 and absf(fposmod(q.y + 10.0, 1.6) - 0.8) < 0.3 and ax < 6.55
					cols.append([0, row.call(-1.0 if roller else -1.2), STEEL_M if roller else (DUSK_D if bolt else DUSK), false])
				else:
					cols.append([0, row.call(-1.35), DUSK_D, false])
				# segmented sand skirts over the front half, on the outer part:
				# the bogies' coil springs show inside them
				if q.y > -0.4 and q.y <= 5.2:
					if ax > 7.55:
						var seg := fposmod(q.y + 0.4, 1.4)
						var c := SAND if ax > 7.9 else SAND_D
						if seg < u * 1.1:
							c = DUSK
						elif (seg < u * 2.2 or seg > 1.4 - u * 1.2) and ax > 8.75:
							c = DUSK_D  # bolts at the corners
						cols.append([row.call(-1.1), row.call(-0.84), c, false])
					elif ax < 6.85 and absf(fposmod(q.y + 0.4, 1.4) - 0.7) < 0.45:
						cols.append([row.call(-1.3), row.call(-0.95), STEEL_M if posmod(z, 2) == 0 else DUSK, false])
			# ---- the hull (its back corners cut off past the casemates)
			if ax < 6.3 and q.y >= -6.2 and q.y <= 5.4 and not (ax > 5.3 and q.y < -4.6 and (ax - 5.3) + (-4.6 - q.y) > 0.9):
				var h: int = deck
				var top := GUN
				var glow := false
				# bare deck plates with seams
				var panel := posmod(int(floor((q.x + 10.0) / 1.6)) + int(floor((q.y + 10.0) / 1.6)), 2) == 0
				top = DUSK_L if panel else GUN
				if fposmod(q.x + 10.0, 1.6) < u or fposmod(q.y + 10.0, 1.6) < u:
					top = DUSK
				# the glacis, stepping down to the front, bolted along its top
				if q.y > 4.5:
					h = deck - (1 if q.y < 4.9 else (2 if q.y < 5.2 else 3))
					top = SAND_D if fposmod(q.x + 10.0, 1.2) > u else DUSK
					if q.y < 4.62 and posmod(x, 3) == 0:
						top = DUSK_D
					# headlamp clusters
					if ax > 2.55 and ax < 3.35 and q.y > 4.85:
						h = deck
						top = GUN
						if q.y > 5.05 and (absf(ax - 2.78) < 0.1 or absf(ax - 3.1) < 0.1):
							top = EYE
							glow = true
					# the hull gun's ball mount
					if Vector2(q.x, q.y - 5.05).length() < 0.35:
						h = deck
						top = DUSK_L
					# smoke dischargers on the front corners
					if ax > 5.55 and ax < 6.1 and q.y > 4.65:
						var tube := posmod(z, 2) == 0
						h = deck + 1 if tube else deck
						top = DUSK_L if tube else DUSK_D
				# the turret ring (geared) round the turret basket
				var rt := Vector2(q.x, q.y - 2.3).length()
				var at := atan2(q.y - 2.3, q.x)
				if rt < 2.95:
					if rt > 2.6:
						h = deck
						top = STEEL_M if posmod(int(floor((at + PI) * 24.0 / PI)), 2) == 0 else DUSK
					elif rt > 2.45:
						h = deck
						top = DUSK_D
					elif rt > 1.9:
						# ammunition racks round the basket's wall
						var rack := posmod(int(floor((at + PI) * 12.0 / PI)), 2) == 0
						h = deck - (2 if rack else 3)
						top = DUSK_L if rack else DUSK_D
					elif rt > 1.3 and rt < 1.5:
						h = deck - 2
						top = STEEL_M
					elif rt < 0.45:
						h = deck - 1
						top = DUSK_L
					elif rt <= 1.3 and minf(absf(q.x), absf(q.y - 2.3)) < 0.12:
						h = deck - 2
						top = GUN
					else:
						h = deck - 3
						top = DUSK_D
				# the sponson rings (geared) and the ammunition chutes into them
				var rs := Vector2(ax - 5.3, q.y - 4.0).length()
				if rs < 1.5:
					h = deck if rs > 1.25 else deck - 1
					top = (STEEL_M if posmod(int(floor((atan2(q.y - 4.0, ax - 5.3) + PI) * 12.0 / PI)), 2) == 0 else DUSK) if rs > 1.25 else DUSK_D
				var dc := sq.distance_to(Geometry2D.get_closest_point_to_segment(sq, Vector2(4.25, 3.5), Vector2(3.0, 3.05)))
				if dc < 0.18 and rt > 2.95:
					h = deck + 1
					top = DUSK if posmod(z, 3) == 0 else STEEL_M
				# the reactor's well: a bolted rim, shutter rails across
				var rr := Vector2(q.x, q.y + 1.9).length()
				if rr < 1.8:
					if rr < 1.45:
						h = deck - 4
						top = DUSK_D
					else:
						h = deck + 1
						top = DUSK_L if posmod(int(floor((atan2(q.y + 1.9, q.x) + PI) * 6.0 / PI)), 2) == 0 and rr > 1.62 else STEEL_M
				if absf(absf(q.y + 1.9) - 1.22) < u * 0.6 and ax < 2.4 and rr >= 1.45:
					h = deck + 1
					top = DUSK
				# heat-sink banks either side of the reactor, fins across
				if ax > 2.7 and ax < 4.3 and q.y > -3.3 and q.y < -0.6:
					var frame := ax < 2.85 or ax > 4.15 or q.y < -3.15 or q.y > -0.75
					var fin := posmod(z, 2) == 0
					h = deck + 2 if frame or fin else deck
					top = GUN if frame else (STEEL_M if fin else DUSK_D)
				# coolant pipes from the reactor's rim out to the heat sinks
				for pipe: Array in [[Vector2(1.75, -1.5), Vector2(2.75, -1.1)], [Vector2(1.75, -2.3), Vector2(2.75, -2.7)]]:
					if sq.distance_to(Geometry2D.get_closest_point_to_segment(sq, pipe[0], pipe[1])) < 0.14:
						h = deck + 2
						top = STEEL_L
				# the flanks: spare track links along the edge, tool bins
				if ax > 5.5 and ax < 6.05 and q.y > -3.2 and q.y < 2.4:
					var link := posmod(z, 4) < 3
					h = deck + 1 if link else deck
					top = DUSK_L if link else DUSK
				if ax > 4.45 and ax < 5.35 and ((q.y > -2.9 and q.y < -1.5) or (q.y > -0.6 and q.y < 1.1)):
					var lid := absf(ax - 4.9) < 0.35 and absf(fposmod(q.y + 10.0, 1.6) - 0.8) < 0.5
					h = deck + 2
					top = SAND_D if lid else DUSK
				# the engine at the back: cylinder heads, two radiator fans,
				# a manifold between them
				if q.y < -3.75 and ax < 2.9:
					if q.y > -4.15:
						var head := fposmod(ax, 0.6) < 0.38
						h = deck + 2 if head else deck + 1
						top = STEEL_L if head else GUN
					else:
						var rf := Vector2(ax - 1.45, q.y + 5.2).length()
						if rf < 1.05:
							var af := atan2(q.y + 5.2, ax - 1.45)
							if rf > 0.87:
								h = deck + 1
								top = GUN
							elif rf < 0.25:
								h = deck + 1
								top = DUSK_L
							elif absf(wrapf((af + rf * 1.2) * 3.0 / TAU, -0.5, 0.5)) < 0.12:
								h = deck
								top = STEEL_M
							else:
								h = deck - 2
								top = DUSK_D
						elif ax < 0.3:
							h = deck + 1
							top = STEEL_M
				# exhaust pipes to the two stacks at the back
				if sq.distance_to(Geometry2D.get_closest_point_to_segment(sq, Vector2(2.3, -5.0), Vector2(2.55, -5.95))) < 0.13:
					h = deck + 2
					top = DUSK_L
				var rx := Vector2(ax - 2.55, q.y + 6.0).length()
				if rx < 0.34:
					h = row.call(-0.1)
					top = DUSK_D if rx < 0.18 else GUN
				# the howitzer casemates: an armoured box, the barrel between
				# its recoil cylinders, an ammunition hoist behind
				var hx := absf(ax - 4.2)
				if hx < 1.05 and q.y > -5.9 and q.y < -3.9:
					h = deck + 3
					top = DUSK if hx > 0.9 or q.y < -5.75 or q.y > -4.05 else SAND_D
					if Vector2(hx, q.y + 5.2).length() < 0.3:
						top = DUSK_L
				if hx < 0.25 and q.y >= -3.9 and q.y < -3.0:
					h = deck + 4
					top = DUSK_D if q.y > -3.2 else GUN
				if hx > 0.3 and hx < 0.45 and q.y >= -3.9 and q.y < -3.4:
					h = deck + 3
					top = STEEL_L
				if hx < 0.6 and q.y >= -6.2 and q.y <= -5.9:
					h = deck + 2
					top = DUSK
				# the bevelled edge round it all
				if (ax > 6.05 or q.y < -6.0) and h <= deck:
					h = deck - 1
					top = DUSK_D if posmod(x + z, 4) == 0 else DUSK
				cols.append([row.call(-2.2), h, top, glow])
			# ---- the dozer blade, its arms and rams
			if q.y > 6.35 and q.y <= 7.2 and ax < 8.9:
				var stripe := posmod(int(floor((q.x + 20.0) / 0.8)), 2) == 0
				cols.append([row.call(-2.6), row.call(-1.2), HAZARD if stripe else DUSK_D, false])
				if q.y < 6.55:
					var rib := fposmod(ax, 1.8) < 0.3
					cols.append([row.call(-2.6), row.call(-1.3 if rib else -1.5), DUSK_L if rib else GUN, false])
			if q.y > 5.4 and q.y <= 6.35:
				if absf(ax - 7.0) < 0.3 or absf(ax - 5.4) < 0.3:
					cols.append([row.call(-2.0), row.call(-1.5), DUSK, false])
				elif absf(ax - 6.2) < 0.17:
					# the hydraulic ram: the cylinder, then the rod
					if q.y < 5.85:
						cols.append([row.call(-1.9), row.call(-1.45), STEEL_M, false])
					else:
						cols.append([row.call(-1.8), row.call(-1.6), STEEL_L, false])
			for c: Array in cols:
				var r0: int = c[0]
				var r1: int = c[1]
				for y in range(r0, r1 + 1):
					var top_row := y == r1
					v.put(x, y, z, c[2] if top_row else (DUSK if y > r1 - 3 else DUSK_D), c[3] and top_row)
	return v.mesh(u, Vector3(0, oy, 0))


## A track's top run (it slides along under the housings as the tank
## moves): dark links with a raised cleat every TREAD_PITCH.
static func _behemoth_tread() -> ArrayMesh:
	var v := Vox.new(14, 2, 78)
	for z in range(-39, 39):
		for x in range(-7, 7):
			v.put(x, 0, z, DUSK_D)
			if posmod(z, 4) == 0:
				v.put(x, 1, z, STEEL_M if absi(x) < 6 else DUSK_L)
			elif absi(x) <= 1 and posmod(z, 4) == 2:
				v.put(x, 1, z, GUN)
	return v.mesh(U * 1.5, Vector3(0, 0.5, 0))


## The main turret (turns; faces +z), built up in tiers: a lower skirt of
## armour round the ring, the roof set in from it in plates with seams,
## sand cheek armour bolted on the front quarters, a mantlet with its
## trunnions, recoil cylinders along the roof over the barrels' roots, a
## commander's cupola ringed with periscopes, vents on the rear roof, a
## sensor mast with a red lamp, smoke dischargers on the flanks, the
## autoloader's bustle at the back with its hatch. The barrels are separate
## (they recoil).
static func _behemoth_turret() -> ArrayMesh:
	var v := Vox.new(44, 7, 44)
	for z in range(-22, 22):
		for x in range(-22, 22):
			var p := Vector2(x + 0.5, z + 0.5)
			var ax := absf(p.x)
			var oct := maxf(maxf(ax, absf(p.y)), (ax + absf(p.y)) * 0.74)
			if oct > 19.0:
				continue
			v.fill(x, 0, z, x, 2, z, DUSK)
			# the lower tier, its lip
			var top := 3
			var c := DUSK_L if oct > 17.6 else GUN
			# the roof, set in from the edge, in plates
			if oct < 15.5:
				top = 5
				c = DUSK_L if posmod(int(floor(p.x / 7.0)) + int(floor(p.y / 7.0)), 2) == 0 else GUN
				if posmod(x, 7) == 0 or posmod(z, 7) == 0:
					c = DUSK
			# sand cheek armour on the front quarters, bolted
			if p.y > 4.0 and ax > 6.0 and oct > 12.5:
				top = 5 if oct < 17.6 else 4
				c = SAND if oct < 16.8 else SAND_D
				if posmod(z, 4) == 0 and oct > 15.8 and oct < 16.8:
					c = DUSK_D
			# vents on the rear roof
			if p.y < -6.0 and p.y > -12.0 and ax > 3.0 and ax < 11.0 and oct < 15.0:
				c = DUSK_D if posmod(z, 2) == 0 else STEEL_M
			# the autoloader's bustle
			if p.y < -13.0:
				top = 4
				c = STEEL_M if posmod(x, 3) != 0 else DUSK
			for y in range(3, top + 1):
				v.put(x, y, z, c if y == top else DUSK)
	# the mantlet and its trunnions
	v.fill(-9, 1, 14, 8, 5, 19, DUSK_L)
	v.fill(-9, 5, 14, 8, 5, 15, GUN)
	v.fill_sym(9, 2, 15, 10, 4, 17, STEEL_L)
	# recoil cylinders along the roof over the barrels' roots
	for s: int in [-1, 1]:
		var cx := s * 4 - (1 if s < 0 else 0)
		v.fill(cx, 6, 6, cx, 6, 13, STEEL_M)
		v.put(cx, 6, 6, DUSK_D)
	# the commander's cupola, periscopes round it
	v.blob(-8, 5, -4, 3.6, 1.4, 3.6, DUSK_L)
	for k in 6:
		var a := TAU * k / 6.0
		v.put(-8 + int(round(cos(a) * 3.0)), 6, -4 + int(round(sin(a) * 3.0)), DUSK_D)
	v.put(-8, 6, -4, GUN)
	# the sensor mast
	v.fill(8, 5, -9, 10, 5, -7, DUSK)
	v.fill(9, 6, -8, 9, 6, -8, STEEL_L)
	v.put(9, 6, -7, EYE, true)
	# smoke dischargers on the flanks
	for k in 3:
		v.fill_sym(16 - k, 3, 3 + k * 2, 16 - k, 4, 3 + k * 2, DUSK_D)
	# the autoloader hatch
	v.fill(-4, 5, -18, 3, 5, -15, DUSK_D)
	v.fill(-4, 5, -15, 3, 5, -15, STEEL_M)
	return v.mesh(U * 1.5, Vector3(0.5, 3.7, 0.5))


## The twin barrels (along +z from the turret's centre): fume extractors
## halfway, muzzle brakes at the ends.
static func _behemoth_barrels() -> ArrayMesh:
	var v := Vox.new(14, 3, 86)
	for s: int in [-1, 1]:
		var cx := s * 4 - (1 if s < 0 else 0)
		v.fill(cx, 0, 14, cx + 1, 1, 31, GUN)
		v.fill(cx - 1, 0, 22, cx + 2, 2, 24, DUSK_L)
		v.fill(cx - 1, 0, 29, cx + 2, 2, 32, DUSK)
		v.put(cx, 2, 32, DUSK_D)
	return v.mesh(U * 1.5, Vector3(0, 0.5, 0))


## A sponson: a squat dome, sand on top, twin short guns forward.
static func _behemoth_sponson() -> ArrayMesh:
	var v := Vox.new(20, 6, 26)
	v.blob(0, 1, 0, 8.0, 3.2, 8.0, DUSK)
	v.blob(0, 3, -1, 6.0, 2.0, 6.0, SAND)
	v.put(0, 5, -2, DUSK_D)
	for s: int in [-2, 1]:
		v.fill(s, 2, 6, s + 1, 3, 12, GUN)
		v.fill(s, 2, 12, s + 1, 3, 12, DUSK_L)
	return v.mesh(U * 1.5, Vector3(0.5, 2.5, 0.5))


## The reactor: a ring of dark segments round a white-hot heart glowing
## pale gold, under three turning vanes.
static func _behemoth_core() -> ArrayMesh:
	var v := Vox.new(24, 5, 24)
	for z in range(-12, 12):
		for x in range(-12, 12):
			var r := Vector2(x + 0.5, z + 0.5).length()
			if r > 11.0:
				continue
			var a := atan2(z + 0.5, x + 0.5)
			if r > 8.5:
				v.fill(x, 0, z, x, 2, z, DUSK)
				v.put(x, 3, z, STEEL_M if posmod(int(floor((a + PI) * 8.0 / PI)), 2) == 0 else DUSK_L)
				continue
			v.fill(x, 0, z, x, 1, z, Color(1.0, 0.96, 0.84) if r < 3.5 else Color(0.95, 0.82, 0.5), true)
			if absf(wrapf((a + r * 0.08) * 3.0 / TAU, -0.5, 0.5)) < 0.09 and r > 2.5:
				v.fill(x, 2, z, x, 3, z, STEEL_L)
	return v.mesh(U * 1.5, Vector3(0.5, 1.5, 0.5), true)


## A shutter over the reactor (the left one; the right is its mirror): a
## sand frame round steel slats; they slide aside when it is laid open.
static func _behemoth_louvre() -> ArrayMesh:
	var v := Vox.new(12, 3, 22)
	for z in range(-11, 11):
		for x in range(-6, 6):
			var edge := x <= -5 or z <= -10 or z >= 10
			v.put(x, 0, z, DUSK)
			v.put(x, 1, z, SAND_D if edge else (STEEL_M if posmod(z, 2) == 0 else DUSK_L))
	return v.mesh(U * 1.5, Vector3(0.5, 0.5, 0.5))


## A howitzer shell in flight (it is lobbed high: drawn large): a dark
## body, a red band, a pale nose.
static func _behemoth_shell() -> ArrayMesh:
	var v := Vox.new(4, 4, 10)
	v.fill(-2, 0, -4, 1, 3, 3, DUSK)
	v.fill(-2, 0, 0, 1, 3, 0, CRIM)
	v.fill(-1, 1, 4, 0, 2, 4, STEEL_L)
	return v.mesh(U * 2.2, Vector3(0.5, 2.0, 0.5))
