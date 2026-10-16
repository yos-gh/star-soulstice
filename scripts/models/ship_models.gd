class_name ShipModels
extends Models
## The player ship's three forms (ship0, ship1, ship2).

const NAMES := ["ship0", "ship1", "ship2"]


static func make(name: String) -> ArrayMesh:
	match name:
		"ship0":
			return _ship(0)
		"ship1":
			return _ship(1)
		"ship2":
			return _ship(2)
	return null


## After Star Soldier's Caesar. The ship is one set of parts - a central
## core and two rounded pods - that rearranges per form (it transforms, it
## does not bulk up):
## Form I   crown: the pods sit tight against the core, three tips forward
##          (the core's nose the tallest), joined into one compact body
## Form II  the pods slide outward on short struts with armour plates
##          between, a tail gun extends from the core (rear fire)
## Form III five-way: each pod splits at its red band; the front halves
##          move forward and out (front diagonal guns), the rear halves tuck
##          in beside the core's tail (rear diagonal guns)
const SHIP_PAL := {
	"w": [WHITE, 2], "W": [WHITE, 3], "H": [WHITE, 4],
	"g": [LGREY, 2], "G": [LGREY, 3],
	"d": [DGREY, 1], "D": [DGREY, 2],
	"b": [BLUE, 3], "B": [BLUE, 4], "n": [NAVY, 3],
	"R": [RED, 3], "r": [RED, 2],
	"c": [WHITE, 4, false, CANOPY],
	"L": [WHITE, 3, false, CYAN],
	"E": [THRUST, 1, true],
	"C": [CYAN, 1, true],
}
## Top views, front row first.
const SHIP_CORE := [
	"...ww...",
	"..wWWw..",
	"..wHHw..",
	".wWHHWw.",
	".wWccWw.",
	".wWccWw.",
	".wWccWw.",
	"wWWnnWWw",
	"wWGHHGWw",
	"wWGHHGWw",
	"wGGHHGGw",
	"wGGbbGGw",
	"wWGbbGWw",
	"dWGBBGWd",
	"dDWBBWDd",
	".dDBBDd.",
	"..dEEd..",
]
## A pod; Form III splits it after the red band (row POD_SPLIT).
const SHIP_POD := [
	"..LL..",
	".wWWw.",
	".wHHw.",
	"wWHHWw",
	"wWHHWw",
	"wWGGWw",
	"wWGGWw",
	"wrRRrw",
	"wWGGWw",
	"wWGGWw",
	"wWWWWw",
	"wWWWWw",
	"dWbbWd",
	"dDbbDd",
	".DDDD.",
	"..EE..",
]
const POD_SPLIT := 8
## Form III rear half: the pod's tail with a rear gun in place of the engine.
const SHIP_POD_TAIL := [
	"wWGGWw",
	"wWGGWw",
	"wWWWWw",
	"wWWWWw",
	"dWbbWd",
	"dDbbDd",
	".DDDD.",
	"..CC..",
]
## Pod placement per form: left pod x, front z.
const POD_AT := [[-11, -7], [-13, -8], [-13, -12]]
const TAIL_AT := [-10, -1]  # Form III rear halves
const CORE_Z := -9


static func _ship(lvl: int) -> ArrayMesh:
	var v := Vox.new(32, 8, 32)
	var px: int = POD_AT[lvl][0]
	var pz: int = POD_AT[lvl][1]
	match lvl:
		0:
			_stamp(v, SHIP_POD, SHIP_PAL, px, pz, 1, true)
			# pods joined to the core behind V notches, on one rear base
			v.fill_sym(4, 1, -2, 4, 2, 7, LGREY)
			v.fill_sym(4, 3, 0, 4, 3, 5, WHITE)
			v.fill_sym(0, 1, 7, 10, 1, 7, DGREY)
		1:
			_stamp(v, SHIP_POD, SHIP_PAL, px, pz, 1, true)
			# short struts and armour plates bridging core and pods
			v.fill_sym(4, 1, -3, 7, 1, 2, BLUE)
			v.fill_sym(5, 2, -2, 6, 2, 1, WHITE)
			v.fill_sym(4, 1, 4, 7, 2, 5, DGREY)
			v.fill_sym(4, 2, 4, 7, 2, 4, LGREY)
			_tail_gun(v)
		2:
			# front halves forward and out, rear halves beside the tail
			_stamp(v, SHIP_POD.slice(0, POD_SPLIT), SHIP_PAL, px, pz, 1, true)
			_stamp(v, SHIP_POD_TAIL, SHIP_PAL, TAIL_AT[0], TAIL_AT[1], 1, true)
			# armour plates between the core and the front halves
			v.fill_sym(4, 1, -9, 6, 2, -3, BLUE)
			v.fill_sym(5, 3, -8, 5, 3, -4, NAVY)
			# joints from the plates to the rear halves
			v.fill_sym(5, 1, -2, 7, 1, -2, DGREY)
	_stamp(v, SHIP_CORE, SHIP_PAL, -4, CORE_Z, 1, false)
	# belly keel
	v.fill_sym(0, 0, CORE_Z + 3, 2, 0, CORE_Z + 14, DGREY)
	return v.mesh(U, Vector3(0, 2.0, 0))


static func _tail_gun(v: Vox) -> void:
	v.fill_sym(0, 4, 6, 0, 4, 11, DGREY)
	v.fill_sym(0, 5, 7, 0, 5, 9, LGREY)
	v.fill_sym(0, 4, 12, 0, 4, 12, CYAN, true)


## Stamps a top-view part: each string is a row (first = front, -z), each
## character a column; spec = [colour, height, glow?, cap colour?] (the cap
## replaces the top voxel and glows). Columns start at x0 and rows at z0.
## `mirror` also stamps the mirror image (x -> -1 - x).
static func _stamp(v: Vox, rows: Array, pal: Dictionary, x0: int, z0: int, y0: int, mirror := false) -> void:
	for r in rows.size():
		var s: String = rows[r]
		for c in s.length():
			var ch := s[c]
			if not pal.has(ch):
				continue
			var spec: Array = pal[ch]
			var h: int = spec[1]
			for y in range(y0, y0 + h):
				var col: Color = spec[0]
				var glow: bool = spec[2] if spec.size() > 2 else false
				if y == y0 + h - 1 and spec.size() > 3:
					col = spec[3]
					glow = true
				v.put(x0 + c, y, z0 + r, col, glow)
				if mirror:
					v.put(-1 - (x0 + c), y, z0 + r, col, glow)

