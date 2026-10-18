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
## Props (the fan) are separate meshes; Tunnel turns them.

const STYLES := ["duct", "line", "furnace"]
const VARIANTS := ["plain", "rib", "feature", "gate"]
const NAMES := [
	"tunnel_duct_plain", "tunnel_duct_rib", "tunnel_duct_feature", "tunnel_duct_gate",
	"tunnel_line_plain", "tunnel_line_rib", "tunnel_line_feature", "tunnel_line_gate",
	"tunnel_furnace_plain", "tunnel_furnace_rib", "tunnel_furnace_feature", "tunnel_furnace_gate",
	"tunnel_fan",
]

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
}


static func make(name: String) -> ArrayMesh:
	if name == "tunnel_fan":
		return _fan()
	var parts := name.split("_")
	if parts.size() == 3 and STYLES.has(parts[1]) and VARIANTS.has(parts[2]):
		return _segment(parts[1], parts[2])
	return null


## [[mesh, offset, spin (rad/s)], ...] that ride on a segment.
static func props(style: String, variant: String) -> Array:
	if style == "duct" and variant == "feature":
		return [["tunnel_fan", Vector3(0, FLOOR - 0.45, 0), 2.4]]
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
	match variant:
		"rib":
			_rib(v, pal)
		"gate":
			_gate(v, pal)
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


## A bulkhead frame: a raised band across the floor, a pillar up each wall
## with a lamp, and a lintel over the wall tops.
static func _rib(v: Vox, pal: Dictionary) -> void:
	for z in [-1, 0]:
		for xi in IW:
			var lamp := xi == 10 or xi == 20
			_put2(v, xi, 2, z, pal["lamp"] if lamp else pal["frame"], lamp)
		for xi in range(IW - 3, IW):
			for y in range(2, 16):
				_put2(v, xi, y, z, pal["frame"] if y % 4 != 0 else pal["accent"])
		for xi in range(IW - 3, XW):
			_put2(v, xi, 17, z, pal["frame"])
		for y in [8]:
			_put2(v, IW - 4, y, z, pal["lamp"], true)


## A blast-door frame: a hazard-striped sill across the floor, heavy posts
## striped on their inner faces with red lamps, a lintel over the wall tops.
static func _gate(v: Vox, pal: Dictionary) -> void:
	for z in range(-3, 3):
		var zi := z + NZ / 2
		for xi in IW:
			_put2(v, xi, 2, z, HAZ_A if ((xi + zi) / 2) % 2 == 0 else HAZ_B)
		for xi in range(IW - 5, IW):
			for y in range(2, 18):
				var c: Color = pal["frame"]
				if xi == IW - 5:
					c = HAZ_A if ((y + zi) / 2) % 2 == 0 else HAZ_B
				_put2(v, xi, y, z, c)
		for xi in range(IW - 5, XW):
			_put2(v, xi, 16, z, pal["frame"])
			_put2(v, xi, 17, z, pal["accent"])
	for z in [-3, 2]:
		for y in [12, 13]:
			_put2(v, IW - 6, y, z, LAMP_RED, true)
		for xi in [6, 14, 22]:
			_put2(v, xi, 3, z, LAMP_RED, true)


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
