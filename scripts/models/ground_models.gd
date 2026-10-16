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


## Destructible armour hatch (one Island cell, 16 x 16 voxels).
## Ground material (recedes behind units). 0 teal service hatch (green
## LED), 1 steel-blue cross hatch (lime LED),
## 2 heavy blast door (violet LED).
static func _tile(kind: int) -> ArrayMesh:
	var v := Vox.new(16, 5, 16)
	v.ground = true
	var base: Color = [Color(0.3, 0.46, 0.48), Color(0.34, 0.38, 0.5), Color(0.3, 0.31, 0.35)][kind]
	var hi := base.lightened(0.22)
	var lo := base.darkened(0.45)
	var led: Color = [Color(0.3, 1.0, 0.5), Color(0.75, 1.0, 0.3), Color(0.7, 0.4, 1.0)][kind]
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
