class_name IslandGen
extends RefCounted
## Builds the ground the stage flies over: sections of a vast orbital
## fortress (Star Soldier style) and the debris around it.
##   hull      armoured deck: raised rim with lights, panelled plating,
##             rows of armour hatches (tiles), vents, domes, pipes, antennas
##   trench    a hull deck split by a sunken channel with glowing conduits
##   solar     a light lattice frame carrying solar cells (tiles) and a spine
##   reactor   round platform with a glowing core and a ring of hatches
##   fragment  a broken-off hull plate (debris belt)
##   asteroid  a rock with hatches bolted on (debris belt)
## Voxels are R units; a cell (one 2 x 2 tile) is K x K voxels. Tiles sit
## in sockets half a voxel below the deck. Local y = 0 is the deck top.
## A stage picks kinds and sizes per area (StageDef.areas). A new kind
## needs a footprint (the first match in make), a tile rule (the second)
## and its surface (_structure, or a builder of its own like _asteroid);
## add it to KINDS so the viewer can show it.

const KINDS := ["hull", "trench", "solar", "reactor", "fragment", "asteroid"]

const R := 0.5
const K := 4
const MARGIN := 2
const D := 8

const HULL_A := Color(0.21, 0.26, 0.29)
const HULL_B := Color(0.18, 0.22, 0.25)
const HULL_C := Color(0.24, 0.28, 0.31)
const SEAM := Color(0.1, 0.12, 0.14)
const SIDE := Color(0.16, 0.19, 0.22)
const UNDER := Color(0.13, 0.15, 0.17)
const TRIM := Color(0.5, 0.46, 0.3)
const TRIM_D := Color(0.22, 0.2, 0.18)
const RIM := Color(0.23, 0.27, 0.3)
const PIPE := Color(0.29, 0.31, 0.34)
const SOCKET := Color(0.1, 0.11, 0.12)
const CHANNEL := Color(0.08, 0.1, 0.12)
const CYAN := Color(0.3, 0.9, 1.0)
const CONDUIT := Color(0.12, 0.42, 0.52)
const AMBER := Color(1.0, 0.62, 0.2)
const RED := Color(1.0, 0.22, 0.18)
const CORE := Color(0.22, 0.55, 0.66)
const ROCK := Color(0.22, 0.2, 0.19)
const ROCK_L := Color(0.28, 0.26, 0.23)
const ROCK_S := Color(0.16, 0.15, 0.14)
const ROCK_D := Color(0.14, 0.13, 0.12)
const ORE := Color(0.5, 0.35, 0.95)


## w, h in cells. Returns {w, h, kind, types, hidden, mesh, turrets}.
static func make(seed: int, kind: String, w: int, h: int, turret_count: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var cell_in := PackedByteArray()
	cell_in.resize(w * h)
	var cell_e := PackedFloat32Array()
	cell_e.resize(w * h)
	var phase := r.randf() * TAU
	var mid := w / 2
	for j in h:
		for i in w:
			var dx := (i + 0.5 - w * 0.5) / (w * 0.5)
			var dz := (j + 0.5 - h * 0.5) / (h * 0.5)
			var inside := true
			var e := maxf(absf(dx), absf(dz))
			match kind:
				"hull", "trench":
					var ci := mini(i, w - 1 - i)
					var cj := mini(j, h - 1 - j)
					inside = ci + cj >= 1
				"reactor":
					var s := float(maxi(w, h)) * 0.5
					var d := Vector2((i + 0.5 - w * 0.5) / s, (j + 0.5 - h * 0.5) / s).length()
					inside = d < 0.98
					e = d
				"fragment", "asteroid":
					var a := atan2(dz, dx)
					var wob := 0.13 * sin(a * 3.0 + phase) + 0.09 * sin(a * 5.0 + phase * 2.0)
					var d := sqrt(dx * dx + dz * dz)
					inside = d < 0.95 + wob and (kind == "asteroid" or r.randf() > 0.08)
					e = d
			cell_in[j * w + i] = 1 if inside else 0
			cell_e[j * w + i] = e
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
			var t := -1
			match kind:
				"hull":
					if j % 3 != 1:
						t = 2 if e < 0.35 else (1 if e < 0.7 else 0)
						if r.randf() < 0.15:
							t = -1
				"trench":
					if absi(i - mid) > 1 and absi(i - mid + 1) > 1 and j % 2 == 0:
						t = 1 if (i + j / 2) % 3 == 0 else 0
					if absi(i - mid) <= 0 or i == mid - 1:
						t = -1
				"solar":
					if i != mid and j % 4 != 0:
						t = 0 if r.randf() < 0.8 else 1
				"reactor":
					if e > 0.36 and e < 0.86:
						t = 2 if int(round(atan2(j + 0.5 - h * 0.5, i + 0.5 - w * 0.5) * 4.0 / PI)) % 2 == 0 else 1
				"fragment":
					if r.randf() < 0.65:
						t = 0 if r.randf() < 0.7 else 1
				"asteroid":
					if r.randf() < 0.45:
						t = 1 if r.randf() < 0.6 else 2
			types[idx] = t
			if t >= 0:
				hidden[idx] = 1 if r.randf() < (0.06 if t == 2 else 0.02) else 0
	# turret cells
	var tcells: Array[Vector2i] = []
	for n in turret_count:
		for attempt in 40:
			var i := clampi(int(w * (n + 0.5) / turret_count) + r.randi_range(-1, 1), 1, w - 2)
			var j := r.randi_range(1, maxi(1, h - 2))
			var idx := j * w + i
			if cell_in[idx] == 0 or cell_e[idx] > 0.85:
				continue
			if kind == "trench" and (i == mid or i == mid - 1):
				continue
			if kind == "reactor" and cell_e[idx] < 0.36:
				continue
			var ok := true
			for c in tcells:
				if absi(c.x - i) + absi(c.y - j) < 3:
					ok = false
			if ok:
				tcells.append(Vector2i(i, j))
				types[idx] = -1
				break
	var W := w * K + MARGIN * 2
	var H := h * K + MARGIN * 2
	var vmask := _footprint(kind, w, h, W, H, cell_in)
	var v := Vox.new(W, D + 4, H)
	v.jitter = 0.04
	v.ground = true
	var info := {"kind": kind, "w": w, "h": h, "W": W, "H": H, "mid": mid, "vmask": vmask, "types": types, "tcells": tcells, "cell_e": cell_e, "r": r}
	if kind == "asteroid":
		_asteroid(v, info)
	else:
		_structure(v, info)
	var mesh := v.mesh(R, Vector3(0, D, 0), true)
	return {"w": w, "h": h, "kind": kind, "types": types, "hidden": hidden, "mesh": mesh, "turrets": tcells}


## 0 = empty, 1 = rim/margin, 2 = deck cell.
static func _footprint(kind: String, w: int, h: int, W: int, H: int, cell_in: PackedByteArray) -> PackedByteArray:
	var vmask := PackedByteArray()
	vmask.resize(W * H)
	for vz in H:
		for vx in W:
			var c := _cell_of(vx, vz, w, h)
			var m := 0
			if c.x >= 0 and cell_in[c.y * w + c.x] == 1:
				m = 2
			else:
				for q in 9:
					var c2 := _cell_of(vx + (q % 3 - 1) * MARGIN, vz + (q / 3 - 1) * MARGIN, w, h)
					if c2.x >= 0 and cell_in[c2.y * w + c2.x] == 1:
						m = 1
						break
			if m == 1 and (kind == "asteroid" or kind == "fragment"):
				m = 1 if Vox._hash(vx / 2, 3, vz / 2) > 0.4 else 0
			vmask[vz * W + vx] = m
	return vmask


static func _cell_of(vx: int, vz: int, w: int, h: int) -> Vector2i:
	if vx < MARGIN or vz < MARGIN:
		return Vector2i(-1, -1)
	var i := (vx - MARGIN) / K
	var j := (vz - MARGIN) / K
	if i >= w or j >= h:
		return Vector2i(-1, -1)
	return Vector2i(i, j)


static func _edge_dist(vmask: PackedByteArray, W: int, H: int, vx: int, vz: int, cap: int) -> int:
	for d in range(1, cap + 1):
		for q: Vector2i in [Vector2i(d, 0), Vector2i(-d, 0), Vector2i(0, d), Vector2i(0, -d)]:
			var x := vx + q.x
			var z := vz + q.y
			if x < 0 or z < 0 or x >= W or z >= H or vmask[z * W + x] == 0:
				return d - 1
	return cap


static func _structure(v: Vox, info: Dictionary) -> void:
	var kind: String = info["kind"]
	var w: int = info["w"]
	var h: int = info["h"]
	var W: int = info["W"]
	var H: int = info["H"]
	var mid: int = info["mid"]
	var vmask: PackedByteArray = info["vmask"]
	var types: PackedInt32Array = info["types"]
	var tcells: Array[Vector2i] = info["tcells"]
	var cell_e: PackedFloat32Array = info["cell_e"]
	var top := D - 1
	for vz in H:
		for vx in W:
			var m := vmask[vz * W + vx]
			if m == 0:
				continue
			var x := vx - W / 2
			var z := vz - H / 2
			var ed := _edge_dist(vmask, W, H, vx, vz, 6)
			var c2 := _cell_of(vx, vz, w, h)
			var lx := (vx - MARGIN) % K
			var lz := (vz - MARGIN) % K
			var idx := c2.y * w + c2.x if c2.x >= 0 else -1
			var surf := top
			var bottom := top - (2 + mini(ed, 4))
			if kind == "solar":
				bottom = top - 1
			elif kind == "fragment":
				bottom = top - (1 + mini(ed, 2))
			# --- rim
			if m == 1:
				var raised := kind != "solar" and kind != "fragment"
				surf = top + (1 if raised else 0)
				for y in range(bottom, surf + 1):
					var hazard := posmod(vx + vz, 24) < 4 and (vx + vz) / 2 % 2 == 0
					var c := SIDE if y < surf else (TRIM if hazard else RIM)
					var glow := false
					if y == surf - 1 and ed == 0 and (vx * 3 + vz) % 5 == 0:
						c = CONDUIT
						glow = true
					if y < top - 2:
						c = UNDER
					v.put(x, y, z, c, glow)
				continue
			# --- deck body
			var channel := kind == "trench" and (c2.x == mid or c2.x == mid - 1)
			if channel:
				surf = top - 2
			var core_e := cell_e[idx]
			var core := kind == "reactor" and core_e < 0.36
			if core:
				surf = top - 1
			var panel := ((c2.x / 2) + (c2.y / 2)) % 2 == 0
			var deck := HULL_A if panel else HULL_B
			if kind == "solar":
				deck = SIDE
			for y in range(bottom, surf):
				v.put(x, y, z, UNDER if y < top - 2 else SIDE)
			var col := deck
			if lx == 0 or lz == 0:
				col = SEAM
			var glow := false
			if channel:
				col = CHANNEL
				var cx := (vx - MARGIN) - (mid - 1) * K
				if cx == 3 or cx == 4:
					col = CONDUIT
					glow = posmod(vz, 4) != 0
				elif lz == 0:
					col = SEAM
			if core:
				var cc := Vector2(vx - W * 0.5, vz - H * 0.5).length()
				var core_r := 0.36 * maxf(w, h) * 0.5 * K
				if cc < core_r * 0.45:
					col = CORE
					glow = true
				elif cc < core_r * 0.62:
					col = SEAM
				elif cc < core_r * 0.8:
					col = PIPE
					glow = false
					v.put(x, surf + 1, z, PIPE if int(atan2(vz - H * 0.5, vx - W * 0.5) * 6.0) % 2 == 0 else CYAN, int(atan2(vz - H * 0.5, vx - W * 0.5) * 6.0) % 2 != 0)
				else:
					col = HULL_C
			v.put(x, surf, z, col, glow)
			# trench walls: pipes along the channel edges
			if kind == "trench" and not channel:
				var cx := (vx - MARGIN) - (mid - 1) * K
				if cx == -1 or cx == 8:
					v.put(x, surf + 1, z, PIPE)
					if vz % 6 == 0:
						v.put(x, surf + 1, z, CONDUIT, true)
			if channel or core:
				continue
			if types[idx] >= 0:
				# socket: a dark recess under the hatch
				if lx > 0 and lz > 0:
					v.erase(x, surf, z)
					v.put(x, surf - 1, z, SEAM if (lx == 2 or lz == 2) else SOCKET)
			elif tcells.has(c2):
				if lx >= 1 and lz >= 1:
					v.put(x, surf + 1, z, SIDE if (lx == 1 or lz == 1) else HULL_C)
			elif kind == "solar":
				# lattice spine and cross girders
				if c2.x == mid:
					v.put(x, surf + 1, z, PIPE if lx == 2 else SIDE)
					if lx == 2 and vz % 5 == 0:
						v.put(x, surf + 2, z, CONDUIT, true)
				elif c2.y % 4 == 0 and lz == 2:
					v.put(x, surf + 1, z, SIDE)
			else:
				_greeble(v, x, surf, z, lx, lz, (c2.x * 31 + c2.y * 17 + w) % 7)


## Machinery on a bare deck cell (4 x 4 voxels).
static func _greeble(v: Vox, x: int, surf: int, z: int, lx: int, lz: int, kind: int) -> void:
	match kind:
		0, 1:
			# vent slats
			if lx >= 1 and lz >= 1 and lz % 2 == 1:
				v.put(x, surf, z, SEAM)
		2:
			# dome with a light
			if lx >= 1 and lz >= 1:
				v.put(x, surf + 1, z, HULL_C)
				if lx == 2 and lz == 2:
					v.put(x, surf + 2, z, HULL_C)
		3:
			# pipe pair across
			if lz == 1 or lz == 3:
				v.put(x, surf + 1, z, PIPE)
		4:
			# antenna mast
			if lx == 2 and lz == 2:
				v.fill(x, surf + 1, z, x, surf + 3, z, SIDE)
				v.put(x, surf + 4, z, SIDE)
		5:
			# hatch outline
			if (lx == 1 or lx == 3) and lz >= 1 or (lz == 1 or lz == 3) and lx >= 1:
				v.put(x, surf, z, SEAM)
			elif lx == 2 and lz == 2:
				v.put(x, surf, z, SEAM)
		_:
			pass


static func _asteroid(v: Vox, info: Dictionary) -> void:
	var w: int = info["w"]
	var h: int = info["h"]
	var W: int = info["W"]
	var H: int = info["H"]
	var vmask: PackedByteArray = info["vmask"]
	var types: PackedInt32Array = info["types"]
	var tcells: Array[Vector2i] = info["tcells"]
	var top := D - 1
	for vz in H:
		for vx in W:
			if vmask[vz * W + vx] == 0:
				continue
			var x := vx - W / 2
			var z := vz - H / 2
			var ed := _edge_dist(vmask, W, H, vx, vz, 6)
			var c2 := _cell_of(vx, vz, w, h)
			var on_tile := c2.x >= 0 and types[c2.y * w + c2.x] >= 0
			var on_turret := c2.x >= 0 and tcells.has(c2)
			var n := Vox._hash(vx / 2, 7, vz / 2)
			var surf := top - (1 if n < 0.4 else 0) - (1 if ed < 1 else 0)
			if on_tile or on_turret:
				surf = top
			var bottom := top - clampi(2 + ed, 2, D - 1)
			for y in range(bottom, surf + 1):
				var c := ROCK_S
				var glow := false
				if y == surf:
					c = ROCK_L if n > 0.75 else ROCK
				elif y < surf - 2:
					c = ROCK_D
				if ed <= 1 and y < surf and Vox._hash(vx, y, vz) > 0.95:
					c = ORE
					glow = true
				v.put(x, y, z, c, glow)
			if c2.x < 0:
				continue
			var lx := (vx - MARGIN) % K
			var lz := (vz - MARGIN) % K
			if on_tile:
				if lx == 0 or lz == 0:
					v.put(x, surf, z, SIDE)
				else:
					v.erase(x, surf, z)
					v.put(x, surf - 1, z, SOCKET)
			elif on_turret and lx >= 1 and lz >= 1:
				v.put(x, surf + 1, z, SIDE)
