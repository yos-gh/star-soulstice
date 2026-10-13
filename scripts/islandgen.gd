class_name IslandGen
extends RefCounted
## Builds the island layouts: the ground the stage scrolls over. Two kinds:
##   station  a plated deck segment: panelled plating, a lower hazard-striped
##            ledge with rail posts, lit windows in the side walls, vents,
##            antennas and domes on the bare cells
##   asteroid a basalt rock: uneven cratered top, strata on the cliffs, dim
##            ore veins; tiles sit in bolted metal frames
## Voxels are R = 0.25 units (a cell = 8 x 8 voxels; tiles are 2 x 2 units).
## Tiles sit in sockets one voxel deep, so a broken tile leaves a recess.
## Local y = 0 is the deck top.

const R := 0.25
const K := 8  # voxels per cell side
const MARGIN := 3  # ledge voxels around the cell area
const D := 10  # max thickness in voxels

# station
const DECK := Color(0.3, 0.33, 0.38, 0.6)
const DECK_B := Color(0.26, 0.29, 0.34, 0.6)
const SEAM := Color(0.17, 0.18, 0.22, 0.8)
const WALL := Color(0.25, 0.27, 0.32, 0.6)
const WALL_D := Color(0.14, 0.15, 0.19, 0.8)
const SOCKET := Color(0.1, 0.11, 0.13, 0.9)
const SOCKET_L := Color(0.2, 0.22, 0.26, 0.8)
const STRIPE := Color(0.64, 0.47, 0.1, 0.75)
const WINDOW := Color(1.0, 0.86, 0.6)
const RUNLIGHT := Color(0.4, 0.85, 1.0)
# asteroid
const ROCK := Color(0.25, 0.235, 0.225)
const ROCK_L := Color(0.31, 0.29, 0.27)
const ROCK_S := Color(0.18, 0.17, 0.165)
const ROCK_D := Color(0.11, 0.105, 0.1)
const FRAME := Color(0.26, 0.27, 0.3, 0.8)
const ORE := Color(0.25, 0.75, 0.85)


## w, h in cells; returns {w, h, style, types, hidden, mesh, turrets}.
static func make(seed: int, w: int, h: int, style: int, pattern: int, turret_count: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var cell_in := PackedByteArray()  # 1 = cell is part of the island
	cell_in.resize(w * h)
	var cell_e := PackedFloat32Array()  # normalised distance from the centre
	cell_e.resize(w * h)
	var W := w * K + MARGIN * 2
	var H := h * K + MARGIN * 2
	var vmask := PackedByteArray()  # voxel footprint: 0 out, 1 ledge/rim, 2 deck
	vmask.resize(W * H)
	var phase := r.randf() * TAU
	for j in h:
		for i in w:
			var dx := (i + 0.5 - w * 0.5) / (w * 0.5)
			var dz := (j + 0.5 - h * 0.5) / (h * 0.5)
			cell_e[j * w + i] = maxf(absf(dx), absf(dz)) if style == 1 else sqrt(dx * dx + dz * dz)
			var inside := true
			if style == 1:
				# chamfered corners and a few notches
				var ci := mini(i, w - 1 - i)
				var cj := mini(j, h - 1 - j)
				if ci + cj < 1 and w > 4 and h > 3:
					inside = false
				if (cj == 0) and w > 7 and (i % 5 == 2):
					inside = false
			else:
				var a := atan2(dz, dx)
				var wob := 0.1 * sin(a * 3.0 + phase) + 0.07 * sin(a * 5.0 + phase * 2.0)
				inside = sqrt(dx * dx + dz * dz) < 0.92 + wob
			cell_in[j * w + i] = 1 if inside else 0
	# voxel footprint
	for vz in H:
		for vx in W:
			var i := (vx - MARGIN) / K if vx >= MARGIN else -1
			var j := (vz - MARGIN) / K if vz >= MARGIN else -1
			var m := 0
			if i >= 0 and j >= 0 and i < w and j < h and cell_in[j * w + i] == 1:
				m = 2
			else:
				# ledge: within MARGIN of a deck cell
				for q in 9:
					var ox := (q % 3 - 1) * MARGIN
					var oz := (q / 3 - 1) * MARGIN
					var ii := (vx + ox - MARGIN) / K if vx + ox >= MARGIN else -1
					var jj := (vz + oz - MARGIN) / K if vz + oz >= MARGIN else -1
					if ii >= 0 and jj >= 0 and ii < w and jj < h and cell_in[jj * w + ii] == 1:
						m = 1
						break
			if style == 0 and m == 1:
				# ragged rock edge
				m = 1 if Vox._hash(vx / 3, 3, vz / 3) > 0.35 else 0
			vmask[vz * W + vx] = m
	# tiles
	var types := PackedInt32Array()
	types.resize(w * h)
	var hidden := PackedByteArray()
	hidden.resize(w * h)
	for j in h:
		for i in w:
			var idx := j * w + i
			types[idx] = -1
			if cell_in[idx] == 0:
				continue
			var e := cell_e[idx]
			var t := 0
			match pattern:
				0:
					t = 2 if e < 0.4 else (1 if e < 0.72 else 0)
				1:
					t = 1 if j % 2 == 0 else 0
					if i == w / 2 and e < 0.7:
						t = 2
				2:
					t = 0 if (i + j) % 2 == 0 else 1
					if r.randf() < 0.1:
						t = 2
				_:
					t = 1 if r.randf() < 0.25 else 0
					if r.randf() < 0.06:
						t = 2
			if r.randf() < (0.16 if pattern != 3 else 0.24):
				continue
			types[idx] = t
			var star_p := 0.06 if t == 2 else 0.02
			hidden[idx] = 1 if r.randf() < star_p else 0
	# turret cells: spread along x through the inner area
	var tcells: Array[Vector2i] = []
	for n in turret_count:
		for attempt in 30:
			var i := clampi(int(w * (n + 0.5) / turret_count) + r.randi_range(-1, 1), 1, w - 2)
			var j := r.randi_range(1, maxi(1, h - 2))
			if cell_in[j * w + i] == 1 and cell_e[j * w + i] < 0.85:
				var ok := true
				for c in tcells:
					if absi(c.x - i) + absi(c.y - j) < 3:
						ok = false
				if ok:
					tcells.append(Vector2i(i, j))
					types[j * w + i] = -1
					break
	var v := Vox.new(W, D + 4, H)
	if style == 1:
		_station(v, r, w, h, W, H, vmask, cell_in, types, tcells)
	else:
		_asteroid(v, r, w, h, W, H, vmask, cell_in, types, tcells)
	# grid x = vx - W/2 -> world x = (vx - W/2) * R; top of layer D-1 at y = 0
	var mesh := v.mesh(R, Vector3(0, D, 0))
	return {"w": w, "h": h, "style": style, "types": types, "hidden": hidden, "mesh": mesh, "turrets": tcells}


static func _cell_of(vx: int, vz: int, w: int, h: int) -> Vector2i:
	if vx < MARGIN or vz < MARGIN:
		return Vector2i(-1, -1)
	var i := (vx - MARGIN) / K
	var j := (vz - MARGIN) / K
	if i >= w or j >= h:
		return Vector2i(-1, -1)
	return Vector2i(i, j)


## Distance (in voxels, capped) from the footprint edge.
static func _edge_dist(vmask: PackedByteArray, W: int, H: int, vx: int, vz: int, cap: int) -> int:
	for d in range(1, cap + 1):
		for q: Vector2i in [Vector2i(d, 0), Vector2i(-d, 0), Vector2i(0, d), Vector2i(0, -d)]:
			var x := vx + q.x
			var z := vz + q.y
			if x < 0 or z < 0 or x >= W or z >= H or vmask[z * W + x] == 0:
				return d - 1
	return cap


static func _station(v: Vox, r: RandomNumberGenerator, w: int, h: int, W: int, H: int, vmask: PackedByteArray, cell_in: PackedByteArray, types: PackedInt32Array, tcells: Array[Vector2i]) -> void:
	var top := D - 1
	for vz in H:
		for vx in W:
			var m := vmask[vz * W + vx]
			if m == 0:
				continue
			var x := vx - W / 2
			var z := vz - H / 2
			var ed := _edge_dist(vmask, W, H, vx, vz, 6)
			var bottom := top - (2 if ed < 2 else (4 if ed < 5 else 7))
			var surf := top if m == 2 else top - 1
			for y in range(bottom, surf + 1):
				var c := WALL
				var glow := false
				if y == surf:
					c = DECK
				elif y < bottom + 1:
					c = WALL_D
				elif ed == 0 and (y == surf - 1) and (vx + vz) % 4 == 0:
					# lit windows / running lights in the outer wall
					c = WINDOW if (vx * 7 + vz) % 3 != 0 else RUNLIGHT
					glow = true
				v.put(x, y, z, c, glow)
			if m == 1:
				# ledge: hazard stripes along the rim, rail posts
				var stripe := ((vx + vz) / 2) % 2 == 0
				v.put(x, surf, z, STRIPE if (ed == 0 and stripe) else (SEAM if ed == 0 else DECK_B))
				if ed == 0 and (vx + vz) % 6 == 0:
					v.put(x, surf + 1, z, WALL)
				continue
			# deck plating: 4 x 4 panels in two shades, seams on cell lines
			var c2 := _cell_of(vx, vz, w, h)
			var lx := (vx - MARGIN) % K
			var lz := (vz - MARGIN) % K
			var panel := ((lx / 4) + (lz / 4)) % 2 == 0
			var col := DECK if panel else DECK_B
			if lx == 0 or lz == 0:
				col = SEAM
			v.put(x, surf, z, col)
			var idx := c2.y * w + c2.x
			if types[idx] >= 0:
				# tile socket: one voxel deep, a dark recess with a light grid
				if lx > 0 and lz > 0:
					v.erase(x, surf, z)
					v.put(x, surf - 1, z, SOCKET_L if (lx % 3 == 0 or lz % 3 == 0) else SOCKET)
			elif tcells.has(c2):
				# turret pad
				if lx >= 1 and lx <= 6 and lz >= 1 and lz <= 6:
					v.put(x, surf + 1, z, WALL if (lx == 1 or lx == 6 or lz == 1 or lz == 6) else DECK_B)
			else:
				_greeble(v, r, x, surf, z, lx, lz, (c2.x * 31 + c2.y * 17) % 5)


## Decoration on a bare deck cell (kind 0..4): vent, dome, antenna,
## light panel, pipes.
static func _greeble(v: Vox, _r: RandomNumberGenerator, x: int, surf: int, z: int, lx: int, lz: int, kind: int) -> void:
	match kind:
		0:
			if lx >= 2 and lx <= 5 and lz >= 2 and lz <= 5 and lz % 2 == 0:
				v.put(x, surf, z, SEAM)
		1:
			var d := Vector2(lx - 3.5, lz - 3.5).length()
			if d < 2.6:
				v.put(x, surf + 1, z, WALL if d > 1.6 else DECK)
				if d < 1.2:
					v.put(x, surf + 2, z, DECK)
		2:
			if lx == 4 and lz == 4:
				v.fill(x, surf + 1, z, x, surf + 3, z, WALL)
				v.put(x, surf + 4, z, Color(1.0, 0.25, 0.2), true)
			elif (lx == 3 or lx == 5) and (lz == 3 or lz == 5):
				v.put(x, surf + 1, z, WALL_D)
		3:
			if lx >= 2 and lx <= 5 and lz == 3:
				v.put(x, surf, z, RUNLIGHT, true)
		_:
			if lz == 2 or lz == 5:
				v.put(x, surf + 1, z, WALL)


static func _asteroid(v: Vox, r: RandomNumberGenerator, w: int, h: int, W: int, H: int, vmask: PackedByteArray, cell_in: PackedByteArray, types: PackedInt32Array, tcells: Array[Vector2i]) -> void:
	var top := D - 1
	var craters := []
	for k in maxi(1, (w * h) / 10):
		craters.append([r.randf_range(0, W), r.randf_range(0, H), r.randf_range(2.5, 5.0)])
	for vz in H:
		for vx in W:
			var m := vmask[vz * W + vx]
			if m == 0:
				continue
			var x := vx - W / 2
			var z := vz - H / 2
			var ed := _edge_dist(vmask, W, H, vx, vz, 8)
			var c2 := _cell_of(vx, vz, w, h)
			var on_tile := c2.x >= 0 and types[c2.y * w + c2.x] >= 0
			var on_turret := c2.x >= 0 and tcells.has(c2)
			# uneven top: low-frequency bumps, craters, lower at the rim
			var n := Vox._hash(vx / 4, 7, vz / 4) + Vox._hash(vx / 2, 9, vz / 2) * 0.5
			var surf := top - (1 if n < 0.55 else 0) - (1 if ed < 2 else 0) - (1 if ed < 1 else 0)
			var crater := false
			var rim := false
			for cr: Array in craters:
				var dd := Vector2(vx - float(cr[0]), vz - float(cr[1])).length()
				if dd < float(cr[2]):
					crater = true
				elif dd < float(cr[2]) + 1.2:
					rim = true
			if crater:
				surf -= 1
			elif rim:
				surf = mini(surf + 1, top + 1)
			if on_tile or on_turret:
				surf = top
			var bottom := top - clampi(2 + ed + int(Vox._hash(vx, 1, vz) * 2.0), 2, D - 1)
			for y in range(bottom, surf + 1):
				var c := ROCK_S
				var glow := false
				if y == surf:
					c = ROCK_L if (n > 1.15 or rim) else ROCK
					if crater:
						c = ROCK_S
				elif y < surf - 3:
					c = ROCK_D
				elif (y + vx / 5) % 3 == 0:
					c = ROCK_S.darkened(0.15)
				if ed <= 1 and y < surf and Vox._hash(vx, y, vz) > 0.96:
					c = ORE
					glow = true
				v.put(x, y, z, c, glow)
			if c2.x < 0:
				continue
			var lx := (vx - MARGIN) % K
			var lz := (vz - MARGIN) % K
			if on_tile:
				# bolted frame and a socket
				if lx == 0 or lz == 0 or lx == K - 1 or lz == K - 1:
					v.put(x, surf, z, FRAME)
				else:
					v.erase(x, surf, z)
					v.put(x, surf - 1, z, SOCKET)
			elif on_turret:
				if lx >= 1 and lx <= 6 and lz >= 1 and lz <= 6:
					v.put(x, surf + 1, z, FRAME if (lx == 1 or lx == 6 or lz == 1 or lz == 6) else SOCKET_L)
