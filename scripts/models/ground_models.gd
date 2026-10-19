class_name GroundModels
extends Models
## Ground pieces: the destructible tiles on the sections (IslandGen builds
## the sections themselves) and the colossal blocks of the deep backdrop.

const NAMES := ["tile0", "tile1", "tile2", "deep_girder", "deep_block"]


static func make(name: String) -> ArrayMesh:
	match name:
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
	return null


## Tile colours: body of the soft cargo container, the tank, and the
## warehouse roof (game.gd's tile_break_fx uses them for the shards).
## (The tank's blue is greyed so the cyan shells still stand out over it.)
const TILE_COL := [Color(0.24, 0.5, 0.42), Color(0.34, 0.42, 0.56), Color(0.44, 0.34, 0.64)]
const TILE_FOOT := Color(0.16, 0.17, 0.19)
const TILE_PALE := Color(0.68, 0.7, 0.72)
const TILE_WALL := Color(0.5, 0.51, 0.53)
const TILE_LED := Color(0.5, 0.86, 0.32)  # energy inside: dim lime, never red or orange (bullets)


## A destructible storehouse on one Island cell (16 x 16 voxels, a little
## raised so it reads as a box, not a painted hatch), drawn in the tile
## material (Vox.tile: the ground's soft contrast, more of its colour).
## By hardness:
##   0 cargo container (soft): green, ribbed sides, a lid with ribs and an
##     energy lamp
##   1 energy tank: a blue tank with bevelled corners on a pad, a white
##     band, a domed top and a lit gauge on the near side
##   2 warehouse (hard, hides stars more often): pale walls under a violet
##     gabled roof, lit skylights on the ridge, a door with a lamp
static func _tile(kind: int) -> ArrayMesh:
	var v := Vox.new(16, 8, 16)
	v.ground = true
	v.tile = true
	var c: Color = TILE_COL[kind]
	v.fill(-8, 0, -8, 7, 1, 7, TILE_FOOT)
	match kind:
		0:
			v.fill(-7, 2, -7, 6, 3, 6, c)
			# ribbed sides
			for k in range(-7, 7, 2):
				v.fill(k, 2, -7, k, 3, -7, c.darkened(0.3))
				v.fill(k, 2, 6, k, 3, 6, c.darkened(0.3))
				v.fill(-7, 2, k, -7, 3, k, c.darkened(0.3))
				v.fill(6, 2, k, 6, 3, k, c.darkened(0.3))
			# lid: a light frame, ribs across, an energy lamp
			v.fill(-7, 4, -7, 6, 4, 6, c.lightened(0.18))
			v.fill(-6, 4, -6, 5, 4, 5, c)
			for z in [-4, -1, 2]:
				v.fill(-6, 4, z, 5, 4, z, c.darkened(0.18))
			v.fill(-6, 4, 4, -3, 4, 4, TILE_PALE)
			v.put(4, 4, 4, TILE_LED, true)
		1:
			# a pad with bolts at the corners
			for b: Vector2i in [Vector2i(-7, -7), Vector2i(6, -7), Vector2i(-7, 6), Vector2i(6, 6)]:
				v.put(b.x, 2, b.y, TILE_PALE.darkened(0.25))
			for z in range(-6, 6):
				for x in range(-6, 6):
					var ax := absf(x + 0.5)
					var az := absf(z + 0.5)
					if ax + az > 9.0:
						continue
					v.fill(x, 2, z, x, 5, z, c)
					v.put(x, 4, z, TILE_PALE)
					if ax < 4.5 and az < 4.5 and ax + az < 7.0:
						v.put(x, 6, z, c.lightened(0.14))
			v.fill(-1, 7, -1, 0, 7, 0, TILE_PALE)
			# the gauge on the side toward the camera
			v.fill(-1, 2, 5, 0, 4, 5, TILE_LED, true)
		2:
			v.fill(-7, 2, -7, 6, 4, 6, TILE_WALL)
			v.fill(-7, 2, -7, 6, 2, 6, TILE_WALL.darkened(0.2))
			# the door and its lamp, on the side toward the camera
			v.fill(-2, 2, 6, 1, 3, 6, TILE_FOOT)
			v.fill(-1, 4, 6, 0, 4, 6, TILE_LED, true)
			# gabled roof along x: eaves, slope, ridge
			v.fill(-7, 5, -7, 6, 5, 6, c.darkened(0.12))
			v.fill(-7, 6, -5, 6, 6, 4, c)
			v.fill(-7, 7, -2, 6, 7, 1, c.lightened(0.16))
			for x in [-4, 3]:
				v.fill(x, 7, -1, x, 7, 0, TILE_LED, true)
	return v.mesh(0.125)


## Far-below truss girder: two chords with diagonal braces (unit 1.0).
static func _deep_girder() -> ArrayMesh:
	var v := Vox.new(90, 6, 8)
	v.ground = true
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
	v.ground = true
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
