class_name TunnelModels
extends Models
## The segments of the tunnels some stages fly down (scripts/terrain/tunnel.gd):
## a floor well below the ground sections and a wall up each side, LEN
## long, in ground voxels (they recede like the islands). The wall tops stay
## just below the play plane so they never hide a unit; the walls lean into
## the screen edges and the perspective draws them together toward the top.
## Each style comes in four variants that the tunnel strings together:
##   plain    the bare tunnel
##   rib      a bulkhead frame across it (every other segment: the beat of
##            the scroll, with the dashed light strips under the wall tops)
##   feature  the style's set piece
##   gate     a blast-door frame with hazard stripes: where a new area begins
## Styles:
##   duct     cold steel intake: plated floor, runway lights, pipes along the
##            walls, cyan light strips; feature: a fan pit (the fan turns)
##   line     assembly line: two conveyor belts, a chevron walkway, amber
##            lamps; feature: crates on the belts and assembly arms
##   furnace  dark plates, molten channels, glowing heat vents; feature: a
##            crucible pit
##   hangar   (stage 4, the enemy base) slate slabs with painted guide
##            lines, ribbed bay doors and a gantry walkway on the walls, pale
##            green lamps; feature: a lift pad
##   core     dark grating, a conduit trench down the middle, heavy pipes on
##            the walls; feature: a power coupling ring (its rotor turns)
##   arena    the floor raised to just under the ground sections (y -3): the
##            deck the stage 4 boss drives on; its gate steps the floor up
## A stage that flies in from open sky has an "open" stretch first (no
## segments, see Tunnel): where the base begins the style's gate comes with
## a facade, the armoured face of the base round the opening, deep enough
## to hide the sky below it (the "mouth" variant: the gate plus the facade
## prop).
## Props (the fan, the rotor, the facade) are separate meshes; Tunnel turns
## the ones that spin.

const STYLES := ["duct", "line", "furnace", "hangar", "core", "arena"]
const VARIANTS := ["plain", "rib", "feature", "gate"]
const NAMES := [
	"tunnel_duct_plain", "tunnel_duct_rib", "tunnel_duct_feature", "tunnel_duct_gate",
	"tunnel_line_plain", "tunnel_line_rib", "tunnel_line_feature", "tunnel_line_gate",
	"tunnel_furnace_plain", "tunnel_furnace_rib", "tunnel_furnace_feature", "tunnel_furnace_gate",
	"tunnel_hangar_plain", "tunnel_hangar_rib", "tunnel_hangar_feature", "tunnel_hangar_gate",
	"tunnel_core_plain", "tunnel_core_rib", "tunnel_core_feature", "tunnel_core_gate",
	"tunnel_arena_plain", "tunnel_arena_rib", "tunnel_arena_feature", "tunnel_arena_gate",
	"tunnel_fan", "tunnel_rotor", "tunnel_facade",
]
## the arena's deck: voxel rows 12-13 (top at y = -3)
const DECK_ROW := 13
const MARK := Color(0.44, 0.41, 0.3)  # painted floor lines (muted)

const HW := 14.5  # inner half width (the wall faces)
const FLOOR := -9.0  # floor top
const TOP := -1.0  # wall tops
const LEN := 12.0  # segment length
const R := 0.5  # voxel size
const IW := 29  # inner half width in voxels
const XW := 42  # half width of the model in voxels (the wall tops run off the screen)
const OY := 20  # voxel row at y = 0: rows 0-1 are the floor, row 17 the wall top
const NZ := 24  # voxels along the tunnel

const HAZ_A := Color(0.52, 0.46, 0.26)
const HAZ_B := Color(0.16, 0.15, 0.14)
const LAMP_RED := Color(1.0, 0.22, 0.18)

const PALS := {
	"duct": {
		"floor_a": Color(0.25, 0.3, 0.34), "floor_b": Color(0.19, 0.23, 0.27), "seam": Color(0.08, 0.1, 0.12),
		"wall": Color(0.2, 0.24, 0.28), "wall_d": Color(0.13, 0.16, 0.19), "top": Color(0.1, 0.12, 0.14), "beam": Color(0.18, 0.21, 0.24),
		"frame": Color(0.27, 0.31, 0.34), "accent": Color(0.3, 0.33, 0.37), "light": Color(0.3, 0.9, 1.0), "lamp": Color(0.16, 0.48, 0.58),
	},
	"line": {
		"floor_a": Color(0.27, 0.27, 0.28), "floor_b": Color(0.21, 0.21, 0.22), "seam": Color(0.09, 0.09, 0.1),
		"wall": Color(0.22, 0.22, 0.23), "wall_d": Color(0.14, 0.14, 0.15), "top": Color(0.11, 0.11, 0.12), "beam": Color(0.2, 0.2, 0.21),
		"frame": Color(0.3, 0.29, 0.27), "accent": Color(0.34, 0.33, 0.31), "light": Color(0.46, 0.3, 0.1), "lamp": Color(0.36, 0.24, 0.08),
		"belt": Color(0.07, 0.075, 0.08), "roller": Color(0.17, 0.17, 0.18), "crate": Color(0.5, 0.4, 0.22), "arm": Color(0.62, 0.5, 0.2),
	},
	"furnace": {
		"floor_a": Color(0.22, 0.19, 0.17), "floor_b": Color(0.17, 0.15, 0.14), "seam": Color(0.07, 0.06, 0.06),
		"wall": Color(0.18, 0.16, 0.15), "wall_d": Color(0.11, 0.1, 0.09), "top": Color(0.09, 0.08, 0.08), "beam": Color(0.16, 0.14, 0.13),
		"frame": Color(0.25, 0.22, 0.2), "accent": Color(0.28, 0.25, 0.22), "light": Color(0.42, 0.12, 0.06), "lamp": Color(0.36, 0.1, 0.05),
		"molten": Color(0.36, 0.08, 0.035), "ember": Color(0.3, 0.07, 0.03),
	},
	# stage 4, the enemy base: cool slate and gunmetal under pale green lamps
	"hangar": {
		"floor_a": Color(0.24, 0.27, 0.26), "floor_b": Color(0.2, 0.225, 0.22), "seam": Color(0.08, 0.09, 0.09),
		"wall": Color(0.21, 0.235, 0.23), "wall_d": Color(0.13, 0.15, 0.145), "top": Color(0.1, 0.11, 0.11), "beam": Color(0.18, 0.2, 0.2),
		"frame": Color(0.28, 0.31, 0.3), "accent": Color(0.33, 0.36, 0.34), "light": Color(0.34, 0.6, 0.42), "lamp": Color(0.2, 0.36, 0.26), "gate_lamp": Color(0.38, 0.64, 0.46),
	},
	"core": {
		"floor_a": Color(0.2, 0.21, 0.23), "floor_b": Color(0.165, 0.175, 0.19), "seam": Color(0.07, 0.07, 0.08),
		"wall": Color(0.18, 0.19, 0.21), "wall_d": Color(0.11, 0.115, 0.13), "top": Color(0.09, 0.09, 0.1), "beam": Color(0.16, 0.17, 0.19),
		"frame": Color(0.26, 0.27, 0.29), "accent": Color(0.3, 0.31, 0.33), "light": Color(0.3, 0.54, 0.4), "lamp": Color(0.18, 0.32, 0.24), "gate_lamp": Color(0.38, 0.64, 0.46),
		"conduit": Color(0.17, 0.36, 0.26),
	},
	"arena": {
		"floor_a": Color(0.25, 0.265, 0.265), "floor_b": Color(0.215, 0.23, 0.23), "seam": Color(0.08, 0.085, 0.09),
		"wall": Color(0.2, 0.215, 0.22), "wall_d": Color(0.12, 0.13, 0.135), "top": Color(0.09, 0.095, 0.1), "beam": Color(0.17, 0.18, 0.19),
		"frame": Color(0.27, 0.29, 0.29), "accent": Color(0.32, 0.34, 0.34), "light": Color(0.3, 0.54, 0.4), "lamp": Color(0.18, 0.32, 0.24), "gate_lamp": Color(0.38, 0.64, 0.46),
	},
}


static func make(name: String) -> ArrayMesh:
	if name == "tunnel_fan":
		return _fan()
	if name == "tunnel_rotor":
		return _rotor()
	if name == "tunnel_facade":
		return _facade()
	var parts := name.split("_")
	if parts.size() == 3 and STYLES.has(parts[1]) and VARIANTS.has(parts[2]):
		return _segment(parts[1], parts[2])
	return null


## [[mesh, offset, spin (rad/s)], ...] that ride on a segment.
static func props(style: String, variant: String) -> Array:
	if style == "duct" and variant == "feature":
		return [["tunnel_fan", Vector3(0, FLOOR - 0.45, 0), 2.4]]
	if style == "core" and variant == "feature":
		return [["tunnel_rotor", Vector3(0, FLOOR - 0.45, 0), 0.9]]
	if variant == "mouth":
		return [["tunnel_facade", Vector3.ZERO, 0.0]]
	return []


static func _segment(style: String, variant: String) -> ArrayMesh:
	var pal: Dictionary = PALS[style]
	var v := Vox.new(XW * 2, 18, NZ)
	v.ground = true
	v.jitter = 0.05
	_shell(v, pal)
	match style:
		"duct":
			_duct(v, pal, variant == "feature")
		"line":
			_line(v, pal, variant == "feature")
		"furnace":
			_furnace(v, pal, variant == "feature")
		"hangar":
			_hangar(v, pal, variant == "feature")
		"core":
			_core(v, pal, variant == "feature")
		"arena":
			_arena(v, pal, variant)
	# the arena's frames stand on its raised deck
	var base := DECK_ROW + 1 if style == "arena" else 2
	match variant:
		"rib":
			_rib(v, pal, base)
		"gate":
			_gate(v, pal, base)
	return v.mesh(R, Vector3(0, OY, 0))


## Puts a voxel on the right (xi >= 0) and its mirror image on the left.
static func _put2(v: Vox, xi: int, y: int, z: int, c: Color, glow := false) -> void:
	v.put(xi, y, z, c, glow)
	v.put(-1 - xi, y, z, c, glow)


## Floor plates, panelled walls with a hazard-striped curb at the foot and a
## dashed light strip under the cornice, beamed wall tops.
static func _shell(v: Vox, pal: Dictionary) -> void:
	for z in range(-NZ / 2, NZ / 2):
		var zi := z + NZ / 2
		for xi in XW:
			if xi < IW:
				var seam := xi % 8 == 7 or zi % 8 == 7
				var plate := ((xi / 8) + (zi / 8)) % 2 == 0
				_put2(v, xi, 0, z, pal["seam"])
				_put2(v, xi, 1, z, pal["seam"] if seam else (pal["floor_a"] if plate else pal["floor_b"]))
			elif xi < IW + 2:
				for y in range(0, 16):
					_put2(v, xi, y, z, pal["wall_d"] if y % 5 == 4 or zi % 8 == 0 else pal["wall"])
			if xi >= IW:
				_put2(v, xi, 16, z, pal["top"])
				_put2(v, xi, 17, z, pal["beam"] if zi % 6 == 0 or xi == IW else pal["top"])
		for y in [2, 3]:
			_put2(v, IW - 1, y, z, HAZ_A if ((zi + y) / 2) % 2 == 0 else HAZ_B)
		_put2(v, IW - 1, 15, z, pal["frame"])
		var lit := zi % 4 < 2
		_put2(v, IW - 1, 14, z, pal["light"] if lit else pal["wall_d"], lit)


static func _duct(v: Vox, pal: Dictionary, feature: bool) -> void:
	for z in range(-NZ / 2, NZ / 2):
		var zi := z + NZ / 2
		# two pipes along each wall, with brackets
		for y in [6, 9]:
			_put2(v, IW - 1, y, z, pal["accent"])
		if zi % 8 == 4:
			for y in range(5, 11):
				_put2(v, IW - 2, y, z, pal["wall_d"])
		# runway lights down the middle and the lanes
		if zi % 6 < 2:
			_put2(v, 0, 1, z, pal["frame"].lightened(0.25))
		if zi % 6 == 3:
			_put2(v, 15, 1, z, pal["lamp"], true)
		# vent grates near the walls
		if zi % 2 == 0:
			for xi in range(20, 27):
				_put2(v, xi, 1, z, pal["seam"])
	if feature:
		# a fan pit in the middle (the fan itself is a prop)
		for z in range(-NZ / 2, NZ / 2):
			for x in range(-10, 10):
				var p := Vector2(x + 0.5, z + 0.5)
				var r := p.length()
				if r < 8.0:
					v.erase(x, 1, z)
					v.put(x, 0, z, Color(0.05, 0.06, 0.07))
				elif r < 9.4:
					var bolt := absf(wrapf(atan2(p.y, p.x) * 8.0 / TAU, -0.5, 0.5)) < 0.12
					v.put(x, 2, z, pal["light"] if bolt else pal["frame"], bolt)


static func _line(v: Vox, pal: Dictionary, feature: bool) -> void:
	for z in range(-NZ / 2, NZ / 2):
		var zi := z + NZ / 2
		# two conveyor belts with rollers, on rails
		for xi in range(4, 12):
			_put2(v, xi, 1, z, pal["belt"] if zi % 2 == 0 else pal["roller"])
		for xi in [3, 12]:
			_put2(v, xi, 2, z, pal["accent"])
		# the walkway between them: chevrons pointing up the tunnel
		for xi in range(0, 3):
			_put2(v, xi, 1, z, HAZ_A if ((zi + xi) / 2) % 2 == 0 else HAZ_B)
		# amber lamps on the walls
		if zi % 8 < 2:
			for y in [11]:
				_put2(v, IW - 1, y, z, pal["light"], true)
	if feature:
		# crates riding the belts
		for c: Vector2i in [Vector2i(6, -9), Vector2i(-10, -2), Vector2i(7, 4), Vector2i(-9, 8)]:
			v.fill(c.x, 2, c.y, c.x + 3, 4, c.y + 3, pal["crate"])
			v.fill(c.x, 5, c.y, c.x + 3, 5, c.y + 3, pal["crate"].darkened(0.25))
			v.fill(c.x + 1, 5, c.y + 1, c.x + 2, 5, c.y + 2, pal["crate"].lightened(0.15))
		# assembly arms reaching out from both walls
		_arm(v, pal, -1, -7)
		_arm(v, pal, 1, 5)


## An assembly arm on the wall on `side` (-1 left), its base at z0: a
## shoulder block, an upper arm rising inward, a forearm reaching down
## toward the belt, and a lit tool head.
static func _arm(v: Vox, pal: Dictionary, side: int, z0: int) -> void:
	var c: Color = pal["arm"]
	var dark: Color = pal["wall_d"]
	var sx := func(xi: int) -> int: return xi if side > 0 else -1 - xi
	for xi in range(IW - 3, IW):
		v.fill(sx.call(xi), 2, z0, sx.call(xi), 6, z0 + 3, dark)
	var pts := [Vector2(IW - 3, 6.0), Vector2(IW - 9, 12.0), Vector2(IW - 15, 8.0)]
	for k in 2:
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		for s in 13:
			var q := a.lerp(b, s / 12.0)
			for dz in range(1, 3):
				v.fill(sx.call(int(q.x)), int(q.y), z0 + dz, sx.call(int(q.x)), int(q.y) + 1, z0 + dz, c)
	for p: Vector2 in pts.slice(1):
		v.fill(sx.call(int(p.x)), int(p.y) - 1, z0, sx.call(int(p.x)), int(p.y) + 1, z0 + 3, dark)
	var tip := int(pts[2].x)
	v.fill(sx.call(tip), 5, z0 + 1, sx.call(tip), 7, z0 + 2, dark)
	v.put(sx.call(tip), 4, z0 + 1, pal["light"], true)


static func _furnace(v: Vox, pal: Dictionary, feature: bool) -> void:
	for z in range(-NZ / 2, NZ / 2):
		var zi := z + NZ / 2
		# molten channels between raised lips
		for xi in [7, 8]:
			_put2(v, xi, 1, z, pal["molten"], true)
		for xi in [6, 9]:
			_put2(v, xi, 2, z, pal["frame"])
		# ember studs down the middle
		if zi % 6 == 0:
			_put2(v, 0, 1, z, pal["ember"], true)
		# glowing heat vents in the walls
		if zi % 6 == 2 or zi % 6 == 3:
			for y in range(4, 12):
				var hot := y % 2 == 0
				_put2(v, IW - 1, y, z, pal["ember"] if hot else pal["wall_d"], hot)
	if feature:
		# a crucible pit in the middle
		for z in range(-NZ / 2, NZ / 2):
			for x in range(-8, 8):
				var p := Vector2(x + 0.5, z + 0.5)
				var r := p.length()
				if r < 5.6:
					var crust := Vox._hash(x, 5, z) > 0.72 and r > 2.0
					v.put(x, 1, z, pal["frame"] if crust else (Color(0.55, 0.18, 0.07) if r < 2.0 else pal["molten"]), not crust)
				elif r < 7.2:
					v.fill(x, 2, z, x, 3 if r < 6.4 else 2, z, pal["frame"] if r < 6.4 else pal["accent"])


## Stage 4's base, the hangar shaft: slate slabs with painted guide lines
## (dashed down the middle, solid down the lanes), ribbed bay doors up the
## walls with a gantry walkway along them; feature: a lift pad in the middle
## (a hazard-striped square round a sunken plate with a ring marked on it
## and dim lamps at its corners).
static func _hangar(v: Vox, pal: Dictionary, feature: bool) -> void:
	for z in range(-NZ / 2, NZ / 2):
		var zi := z + NZ / 2
		# guide lines
		if zi % 6 < 3:
			_put2(v, 0, 1, z, MARK)
		_put2(v, 17, 1, z, MARK.darkened(0.15))
		# bay doors: vertical ribs up the inner wall face
		if zi % 4 == 0:
			for y in range(4, 13):
				_put2(v, IW - 1, y, z, pal["wall_d"])
		# the gantry walkway (a ledge with a railing)
		_put2(v, IW - 2, 11, z, pal["accent"])
		_put2(v, IW - 3, 11, z, pal["frame"])
		if zi % 3 == 0:
			_put2(v, IW - 3, 12, z, pal["frame"])
	if feature:
		for z in range(-10, 10):
			for x in range(-10, 10):
				var ax := absi(x if x >= 0 else -1 - x)
				var az := absi(z if z >= 0 else -1 - z)
				var e := maxi(ax, az)
				if e >= 8:
					v.put(x, 2, z, HAZ_A if ((x + z + 40) / 2) % 2 == 0 else HAZ_B)
				else:
					v.put(x, 1, z, pal["floor_b"].darkened(0.2))
					var r := Vector2(x + 0.5, z + 0.5).length()
					if absf(r - 5.0) < 0.7:
						v.put(x, 1, z, MARK.darkened(0.1))
		for c: Vector2i in [Vector2i(-10, -10), Vector2i(9, -10), Vector2i(-10, 9), Vector2i(9, 9)]:
			v.put(c.x, 3, c.y, pal["lamp"], true)


## Stage 4's base, the deep levels: dark grating (vent slats near the
## walls), a conduit trench down the middle with dim green light in it,
## two heavy pipes along each wall and conduit strips up it; feature: a
## power coupling ring in the floor round a pit (its rotor is a prop).
static func _core(v: Vox, pal: Dictionary, feature: bool) -> void:
	for z in range(-NZ / 2, NZ / 2):
		var zi := z + NZ / 2
		# vent slats near the walls
		if zi % 2 == 0:
			for xi in range(19, 27):
				_put2(v, xi, 1, z, pal["seam"])
		# the conduit trench
		for xi in range(0, 2):
			v.erase(xi, 1, z)
			v.erase(-1 - xi, 1, z)
			_put2(v, xi, 0, z, pal["conduit"] if zi % 4 != 0 else pal["seam"], zi % 4 != 0)
		_put2(v, 2, 2, z, pal["frame"])
		# pipes along the walls
		for y in [5, 6, 9]:
			_put2(v, IW - 1, y, z, pal["accent"])
		_put2(v, IW - 2, 5, z, pal["frame"])
		if zi % 8 == 2:
			for y in range(3, 13):
				_put2(v, IW - 1, y, z, pal["conduit"], y % 3 != 0)
	if feature:
		for z in range(-NZ / 2, NZ / 2):
			for x in range(-11, 11):
				var p := Vector2(x + 0.5, z + 0.5)
				var r := p.length()
				if r < 7.6:
					v.erase(x, 1, z)
					v.put(x, 0, z, Color(0.05, 0.055, 0.06))
				elif r < 10.0:
					var stud := absf(wrapf(atan2(p.y, p.x) * 12.0 / TAU, -0.5, 0.5)) < 0.14 and r > 8.6
					v.fill(x, 1, z, x, 2, z, pal["frame"] if r > 8.4 else pal["accent"])
					if stud:
						v.put(x, 2, z, pal["lamp"], true)


## The arena: the stage 4 boss's deck, raised to rows 12-13 (top at y -3)
## from wall to wall: broad plates with seams, painted lane lines and
## tie-down studs; the gate steps the floor up halfway along (the old floor
## in front, the deck beyond).
static func _arena(v: Vox, pal: Dictionary, variant: String) -> void:
	for z in range(-NZ / 2, NZ / 2):
		if variant == "gate" and z >= 0:
			continue
		var zi := z + NZ / 2
		for xi in IW:
			var seam := xi % 10 == 9 or zi % 12 == 11
			var plate := ((xi / 10) + (zi / 12)) % 2 == 0
			_put2(v, xi, DECK_ROW - 1, z, pal["seam"])
			var c: Color = pal["seam"] if seam else (pal["floor_a"] if plate else pal["floor_b"])
			if xi == 12 or xi == 13:
				c = MARK.darkened(0.2)
			_put2(v, xi, DECK_ROW, z, c)
			if xi % 10 == 4 and zi % 12 == 5:
				_put2(v, xi, DECK_ROW + 1, z, pal["frame"])
		if variant == "gate" and z == -1:
			# the step's lit edge
			for xi in IW:
				if xi % 6 == 2:
					_put2(v, xi, DECK_ROW, z, pal["lamp"], true)


## The core's power coupling rotor: three arms round a hub.
static func _rotor() -> ArrayMesh:
	var v := Vox.new(16, 2, 16)
	v.ground = true
	for z in range(-8, 8):
		for x in range(-8, 8):
			var p := Vector2(x + 0.5, z + 0.5)
			var r := p.length()
			if r > 7.4:
				continue
			if r < 1.8:
				v.fill(x, 0, z, x, 1, z, Color(0.13, 0.14, 0.15))
				continue
			var a := absf(wrapf(atan2(p.y, p.x) * 3.0 / TAU, -0.5, 0.5))
			if a < 0.09 + 0.3 / r:
				v.put(x, 0, z, Color(0.26, 0.28, 0.3) if r < 6.6 else Color(0.2, 0.36, 0.27))
	return v.mesh(R, Vector3(0, 0, 0))


## The face of the enemy base where the tunnel begins (a prop on the first
## segment, which is the style's gate): a slab of armour across the whole
## view at the segment's near (+z) end, from just under the play plane down
## to y -36, open where the tunnel goes in, with an apron over the top
## beyond the tunnel's wall tops. Armour bands, vertical ribs, a
## hazard-striped surround and dim lamps round the opening. It hides the
## open sky below and behind it.
static func _facade() -> ArrayMesh:
	const HX := 96  # half width in voxels (48 units)
	const ROWS := 70  # y -36 .. -1
	const OYF := 72
	var v := Vox.new(HX * 2, ROWS, NZ + 2)
	v.ground = true
	v.jitter = 0.05
	var face := Color(0.26, 0.28, 0.28)
	var band := Color(0.17, 0.185, 0.185)
	var rib := Color(0.32, 0.34, 0.34)
	var top := Color(0.15, 0.16, 0.165)
	var floor_row := OYF - OY  # the tunnel floor's row 0 here (y -10)
	for z in range(-NZ / 2 - 1, NZ / 2 + 1):
		var thick := z >= NZ / 2 - 3
		for x in range(-HX, HX):
			var xi := x if x >= 0 else -1 - x
			var opening := xi < IW
			# one voxel in front of the segment where its walls are (no faces
			# on top of each other), thicker out beyond them
			var front := z == NZ / 2 or (thick and xi >= XW)
			for y in ROWS:
				var wy := (y - OYF) * R
				if front:
					if opening and y >= floor_row:
						continue
					var c := face
					if y % 10 == 0 or y % 10 == 1:
						c = band
					if xi % 14 == 7 and y < ROWS - 2:
						c = rib
					# the surround of the opening, striped
					if (xi >= IW and xi < IW + 3 and y >= floor_row) or (opening and y >= floor_row - 3):
						c = HAZ_A if ((y + xi) / 2) % 2 == 0 else HAZ_B
					if y >= ROWS - 2:
						c = top
					v.put(x, y, z, c)
					if z == NZ / 2 and xi % 14 == 3 and y % 10 == 5 and wy < -4.0:
						v.put(x, y, z, Color(0.22, 0.38, 0.28), true)
				elif xi >= XW and y >= ROWS - 3:
					# the apron over the top beyond the tunnel
					v.put(x, y, z, top if y == ROWS - 1 else band)
	var m := v.mesh(R, Vector3(0, OYF, 0))
	# lit near the top, melting into the haze far down (not into the fog)
	m.surface_set_material(0, PlanetModels.deep_material())
	return m


## A bulkhead frame: a raised band across the floor (row `base`), a pillar
## up each wall with a lamp, and a lintel over the wall tops.
static func _rib(v: Vox, pal: Dictionary, base := 2) -> void:
	for z in [-1, 0]:
		for xi in IW:
			var lamp := xi == 10 or xi == 20
			_put2(v, xi, base, z, pal["lamp"] if lamp else pal["frame"], lamp)
		for xi in range(IW - 3, IW):
			for y in range(base, 16):
				_put2(v, xi, y, z, pal["frame"] if y % 4 != 0 else pal["accent"])
		for xi in range(IW - 3, XW):
			_put2(v, xi, 17, z, pal["frame"])
		for y in [8]:
			if y > base:
				_put2(v, IW - 4, y, z, pal["lamp"], true)


## A blast-door frame: a hazard-striped sill across the floor (row `base`),
## heavy posts striped on their inner faces with lamps (red, or the style's
## `gate_lamp`), a lintel over the wall tops.
static func _gate(v: Vox, pal: Dictionary, base := 2) -> void:
	var lamp: Color = pal.get("gate_lamp", LAMP_RED)
	for z in range(-3, 3):
		var zi := z + NZ / 2
		for xi in IW:
			_put2(v, xi, base, z, HAZ_A if ((xi + zi) / 2) % 2 == 0 else HAZ_B)
		for xi in range(IW - 5, IW):
			for y in range(base, 18):
				var c: Color = pal["frame"]
				if xi == IW - 5:
					c = HAZ_A if ((y + zi) / 2) % 2 == 0 else HAZ_B
				_put2(v, xi, y, z, c)
		for xi in range(IW - 5, XW):
			_put2(v, xi, 16, z, pal["frame"])
			_put2(v, xi, 17, z, pal["accent"])
	for z in [-3, 2]:
		for y in [12, 13]:
			if y > base:
				_put2(v, IW - 6, y, z, lamp, true)
		for xi in [6, 14, 22]:
			_put2(v, xi, base + 1, z, lamp, true)


## The intake fan: five swept blades round a lit hub.
static func _fan() -> ArrayMesh:
	var v := Vox.new(18, 2, 18)
	v.ground = true
	for z in range(-9, 9):
		for x in range(-9, 9):
			var p := Vector2(x + 0.5, z + 0.5)
			var r := p.length()
			if r > 7.6:
				continue
			if r < 1.6:
				v.fill(x, 0, z, x, 1, z, Color(0.12, 0.14, 0.16))
				if r < 0.8:
					v.put(x, 1, z, Color(0.3, 0.9, 1.0), true)
				continue
			var a := fposmod(atan2(p.y, p.x) / TAU * 5.0 + r * 0.06, 1.0)
			if a < 0.42:
				v.put(x, 0, z, Color(0.3, 0.34, 0.37) if a > 0.06 else Color(0.2, 0.23, 0.26))
	return v.mesh(R, Vector3(0, 0, 0))
