class_name Vox
extends RefCounted
## Voxel model builder. A bounded grid of palette indices is meshed into
## cube faces: hidden faces are culled, every corner gets baked ambient
## occlusion, and each voxel a slight colour jitter so flat areas read as
## blocks. Glow voxels go to a second, self-lit surface that blooms.
## Colour alpha is the surface finish: 1 = matte, lower = polished metal
## (sharper, brighter highlights; see shaders/vox.gdshader).
## Grid coordinates: x in [-w/2, w/2), y in [0, h), z in [-d/2, d/2).
## Model space: x right, y up, -z forward (nose).

const AO := [0.52, 0.7, 0.86, 1.0]
const DIRS := [
	[Vector3i(1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)],
	[Vector3i(-1, 0, 0), Vector3i(0, 1, 0), Vector3i(0, 0, 1)],
	[Vector3i(0, 1, 0), Vector3i(1, 0, 0), Vector3i(0, 0, 1)],
	[Vector3i(0, -1, 0), Vector3i(1, 0, 0), Vector3i(0, 0, 1)],
	[Vector3i(0, 0, 1), Vector3i(1, 0, 0), Vector3i(0, 1, 0)],
	[Vector3i(0, 0, -1), Vector3i(1, 0, 0), Vector3i(0, 1, 0)],
]

static var hull_mat: ShaderMaterial
static var glow_mat: ShaderMaterial
static var glow_soft_mat: ShaderMaterial
static var ground_mat: ShaderMaterial
static var ground_glow_mat: ShaderMaterial
static var _cache := {}

var sx: int
var sy: int
var sz: int
var ox: int
var oz: int
var cells := PackedInt32Array()
var colors: Array[Color] = [Color(0, 0, 0, 0)]
var glows: Array[bool] = [false]
var _ids := {}
var jitter := 0.06
var cull_bottom := false
var ground := false  # use the receding ground materials


func _init(w: int, h: int, d: int) -> void:
	sx = w
	sy = h
	sz = d
	ox = w / 2
	oz = d / 2
	cells.resize(w * h * d)


static func materials() -> void:
	if hull_mat != null:
		return
	hull_mat = ShaderMaterial.new()
	hull_mat.shader = load("res://shaders/vox.gdshader")
	glow_mat = ShaderMaterial.new()
	glow_mat.shader = load("res://shaders/glow.gdshader")
	glow_soft_mat = ShaderMaterial.new()
	glow_soft_mat.shader = glow_mat.shader
	glow_soft_mat.set_shader_parameter("energy", 1.6)
	ground_mat = ShaderMaterial.new()
	ground_mat.shader = hull_mat.shader
	ground_mat.set_shader_parameter("dim", 0.72)
	ground_mat.set_shader_parameter("desat", 0.5)
	ground_mat.set_shader_parameter("haze", Color(0.03, 0.045, 0.07))
	ground_mat.set_shader_parameter("haze_amt", 0.22)
	ground_mat.set_shader_parameter("specular", 0.1)
	ground_glow_mat = ShaderMaterial.new()
	ground_glow_mat.shader = glow_mat.shader
	ground_glow_mat.set_shader_parameter("energy", 0.9)


func _id(c: Color, glow: bool) -> int:
	var key := c.to_html() + ("g" if glow else "")
	if _ids.has(key):
		return _ids[key]
	colors.append(c)
	glows.append(glow)
	var i := colors.size() - 1
	_ids[key] = i
	return i


func _index(x: int, y: int, z: int) -> int:
	var gx := x + ox
	var gz := z + oz
	if gx < 0 or gx >= sx or y < 0 or y >= sy or gz < 0 or gz >= sz:
		return -1
	return (gz * sy + y) * sx + gx


func put(x: int, y: int, z: int, c: Color, glow := false) -> void:
	var i := _index(x, y, z)
	if i >= 0:
		cells[i] = _id(c, glow)


func erase(x: int, y: int, z: int) -> void:
	var i := _index(x, y, z)
	if i >= 0:
		cells[i] = 0


func get_id(x: int, y: int, z: int) -> int:
	var i := _index(x, y, z)
	return 0 if i < 0 else cells[i]


func filled(x: int, y: int, z: int) -> bool:
	return get_id(x, y, z) != 0


## Fills the inclusive box between two corners.
func fill(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: Color, glow := false) -> Vox:
	var id := _id(c, glow)
	for z in range(mini(z0, z1), maxi(z0, z1) + 1):
		for y in range(mini(y0, y1), maxi(y0, y1) + 1):
			for x in range(mini(x0, x1), maxi(x0, x1) + 1):
				var i := _index(x, y, z)
				if i >= 0:
					cells[i] = id
	return self


## Fills [x0, x1] on the right and its mirror image (-1 - x) on the left.
func fill_sym(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int, c: Color, glow := false) -> Vox:
	fill(x0, y0, z0, x1, y1, z1, c, glow)
	fill(-1 - x0, y0, z0, -1 - x1, y1, z1, c, glow)
	return self


func clear_box(x0: int, y0: int, z0: int, x1: int, y1: int, z1: int) -> Vox:
	for z in range(mini(z0, z1), maxi(z0, z1) + 1):
		for y in range(mini(y0, y1), maxi(y0, y1) + 1):
			for x in range(mini(x0, x1), maxi(x0, x1) + 1):
				erase(x, y, z)
	return self


## A filled ellipsoid-ish blob (trees, domes).
func blob(cx: int, cy: int, cz: int, rx: float, ry: float, rz: float, c: Color, glow := false) -> Vox:
	for z in range(int(floor(cz - rz)), int(ceil(cz + rz)) + 1):
		for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
			for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
				var d := Vector3((x - cx) / maxf(rx, 0.01), (y - cy) / maxf(ry, 0.01), (z - cz) / maxf(rz, 0.01))
				if d.length_squared() <= 1.0:
					put(x, y, z, c, glow)
	return self


## Paints one pixel-art layer seen from above. Each string is one row of
## the sprite (the first row is the nose, -z), each character one column;
## `pal` maps a character to [Color, height, glow := false]. Columns are
## filled upward from y0. Unknown characters ('.', ' ') are empty. Rows are
## centred on x = 0 and z = 0 (column w/2 sits on x = 0).
func paint(rows: Array, pal: Dictionary, y0 := 0, dz := 0) -> Vox:
	var w := (rows[0] as String).length()
	var n := rows.size()
	for r in n:
		var s: String = rows[r]
		if s.length() != w:
			push_error("Vox.paint: row %d is %d wide, expected %d: %s" % [r, s.length(), w, s])
		for c in s.length():
			var ch := s[c]
			if not pal.has(ch):
				continue
			var spec: Array = pal[ch]
			var glow: bool = spec[2] if spec.size() > 2 else false
			for y in range(y0, y0 + int(spec[1])):
				put(c - w / 2, y, r - n / 2 + dz, spec[0], glow)
	return self


## Like paint, but each row holds only the left half up to and including
## the centre column; the right half is mirrored from it.
func paint_sym(rows: Array, pal: Dictionary, y0 := 0, dz := 0) -> Vox:
	var full := []
	for s: String in rows:
		full.append(s + s.substr(0, s.length() - 1).reverse())
	return paint(full, pal, y0, dz)


static func _hash(x: int, y: int, z: int) -> float:
	var h := (x * 73856093) ^ (y * 19349663) ^ (z * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return float((h >> 8) & 0xffff) / 65535.0


## Builds the mesh. `unit` = voxel edge length; `origin` (in voxel units) is
## placed at the model's local origin.
func mesh(unit: float, origin := Vector3.ZERO, soft_glow := false) -> ArrayMesh:
	materials()
	var hv := PackedVector3Array()
	var hn := PackedVector3Array()
	var hc := PackedColorArray()
	var hi := PackedInt32Array()
	var gv := PackedVector3Array()
	var gn := PackedVector3Array()
	var gc := PackedColorArray()
	var gi := PackedInt32Array()
	var half := Vector3(0.5, 0.5, 0.5)
	for gz in sz:
		for y in sy:
			for gx in sx:
				var id := cells[(gz * sy + y) * sx + gx]
				if id == 0:
					continue
				# fast skip for buried voxels
				if gx > 0 and gx < sx - 1 and y > 0 and y < sy - 1 and gz > 0 and gz < sz - 1:
					var i0 := (gz * sy + y) * sx + gx
					if cells[i0 - 1] != 0 and cells[i0 + 1] != 0 and cells[i0 - sx] != 0 and cells[i0 + sx] != 0 and cells[i0 - sx * sy] != 0 and cells[i0 + sx * sy] != 0:
						continue
				var x := gx - ox
				var z := gz - oz
				var glow := glows[id]
				var base := colors[id]
				var j := 1.0 + (_hash(x, y, z) - 0.5) * 2.0 * jitter
				base = Color(base.r * j, base.g * j, base.b * j, base.a)
				var cell := Vector3i(x, y, z)
				for d in 6:
					var nd: Vector3i = DIRS[d][0]
					if d == 3 and cull_bottom:
						continue
					var nid := get_id(x + nd.x, y + nd.y, z + nd.z)
					if nid != 0:
						continue
					var u: Vector3i = DIRS[d][1]
					var v: Vector3i = DIRS[d][2]
					var n := Vector3(nd)
					var fc := Vector3(cell) + half + n * 0.5
					var ao: Array[int] = [3, 3, 3, 3]
					var pos4 := PackedVector3Array()
					var col4 := PackedColorArray()
					var k := 0
					for s: Vector2i in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1)]:
						var p := fc + (Vector3(u) * s.x + Vector3(v) * s.y) * 0.5
						pos4.push_back((p - origin) * unit)
						if not glow:
							var o := cell + nd
							var s1 := filled(o.x + u.x * s.x, o.y + u.y * s.x, o.z + u.z * s.x)
							var s2 := filled(o.x + v.x * s.y, o.y + v.y * s.y, o.z + v.z * s.y)
							var cc := filled(o.x + u.x * s.x + v.x * s.y, o.y + u.y * s.x + v.y * s.y, o.z + u.z * s.x + v.z * s.y)
							var a := 0 if (s1 and s2) else 3 - int(s1) - int(s2) - int(cc)
							ao[k] = a
							var f: float = AO[a]
							col4.push_back(Color(base.r * f, base.g * f, base.b * f, base.a))
						else:
							col4.push_back(base)
						k += 1
					# corners a b c d go counter-clockwise seen from outside when
					# u x v points along n; Godot wants clockwise front faces.
					var ccw := Vector3(u).cross(Vector3(v)).dot(n) > 0.0
					var flip := ao[0] + ao[2] < ao[1] + ao[3]
					var order: Array
					if ccw:
						order = [1, 3, 2, 1, 0, 3] if flip else [0, 2, 1, 0, 3, 2]
					else:
						order = [1, 2, 3, 1, 3, 0] if flip else [0, 1, 2, 0, 2, 3]
					if glow:
						var st := gv.size()
						gv.append_array(pos4)
						gc.append_array(col4)
						for q in 4:
							gn.push_back(n)
						for o: int in order:
							gi.push_back(st + o)
					else:
						var st := hv.size()
						hv.append_array(pos4)
						hc.append_array(col4)
						for q in 4:
							hn.push_back(n)
						for o: int in order:
							hi.push_back(st + o)
	var m := ArrayMesh.new()
	if not hv.is_empty():
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = hv
		arr[Mesh.ARRAY_NORMAL] = hn
		arr[Mesh.ARRAY_COLOR] = hc
		arr[Mesh.ARRAY_INDEX] = hi
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		m.surface_set_material(m.get_surface_count() - 1, ground_mat if ground else hull_mat)
	if not gv.is_empty():
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = gv
		arr[Mesh.ARRAY_NORMAL] = gn
		arr[Mesh.ARRAY_COLOR] = gc
		arr[Mesh.ARRAY_INDEX] = gi
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		m.surface_set_material(m.get_surface_count() - 1, ground_glow_mat if ground else (glow_soft_mat if soft_glow else glow_mat))
	return m


## A single unit cube (centered), lit or self-lit; used by MultiMeshes.
static func cube(glow := false) -> ArrayMesh:
	var key := "_cube_g" if glow else "_cube"
	if _cache.has(key):
		return _cache[key]
	var v := Vox.new(2, 1, 2)
	v.jitter = 0.0
	v.put(0, 0, 0, Color(1, 1, 1), glow)
	var m := v.mesh(1.0, Vector3(0.5, 0.5, 0.5))
	_cache[key] = m
	return m


## Cached model by name (built by Models).
static func get_mesh(name: String) -> ArrayMesh:
	if _cache.has(name):
		return _cache[name]
	var m := Models.build(name)
	_cache[name] = m
	return m


static func release() -> void:
	_cache.clear()
	hull_mat = null
	glow_mat = null
	glow_soft_mat = null
	ground_mat = null
	ground_glow_mat = null
