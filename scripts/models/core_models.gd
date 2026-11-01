class_name CoreModels
extends Models
## Stage 5's last boss STAR SOUL: the core of the Cortex fortresses on its
## own, cut like a gem. Not voxels: flat facets lit from inside
## (shaders/gem.gdshader: each facet its own shade, glints running over
## them as it turns), and its barrier's panels of light
## (shaders/ward.gdshader).
##   soul_shard  one of the eight wedges the gem is cut into: an eighth of
##               an octagonal brilliant (table, crown facets, pavilion),
##               from the axis out to the girdle, pointing along +x, its
##               origin at MID (so it turns about its own middle when it
##               flies off on its own)
##   soul_heart  the small gem inside the eight (a whole brilliant)
##   soul_ward   a hexagonal barrier panel lying on the plane (radius 1,
##               corners on +-x)
## Emerald: the gem stands apart from every bullet colour (blue shells,
## orange energy, violet iron, red heavies), from the ship's white and blue
## and from the barrier's blue (breakable cover), and it burns against the
## violet and rose of warp space.

const NAMES := ["soul_shard", "soul_heart", "soul_ward"]
## the cut of the whole gem: girdle radius (at the octagon's corners),
## table radius, heights of the table, the girdle and the culet
const R := 3.0
const TABLE := 1.7
const TABLE_Y := 1.25
const GIRDLE_Y := 0.3
const CULET_Y := -1.6
## a wedge's middle (along its own +x): where it sits off the gem's axis
const MID := 1.55
## the heart, smaller and a little flatter
const HEART := [1.35, 0.78, 0.7, 0.18, -0.85]
const EMERALD := Color(0.05, 0.66, 0.36)
const EMERALD_D := Color(0.0, 0.12, 0.07)
const FIRE := Color(1.0, 0.9, 0.6)
const HEART_BODY := Color(0.3, 0.95, 0.6)
const HEART_DEEP := Color(0.03, 0.34, 0.2)

static var _mats := {}


static func make(name: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match name:
		"soul_shard":
			_wedge(st, 0, R, TABLE, TABLE_Y, GIRDLE_Y, CULET_Y, Vector3(MID, 0, 0))
			var m := st.commit()
			m.surface_set_material(0, gem_material("shard"))
			return m
		"soul_heart":
			for k in 8:
				_wedge(st, k, HEART[0], HEART[1], HEART[2], HEART[3], HEART[4], Vector3.ZERO)
			var m := st.commit()
			m.surface_set_material(0, gem_material("heart"))
			return m
		"soul_ward":
			for i in 6:
				var a0 := TAU * i / 6.0
				var a1 := TAU * (i + 1) / 6.0
				for p: Vector3 in [Vector3.ZERO, Vector3(cos(a1), 0, sin(a1)), Vector3(cos(a0), 0, sin(a0))]:
					st.set_normal(Vector3.UP)
					st.set_uv(Vector2(p.x * 0.5 + 0.5, p.z * 0.5 + 0.5))
					st.add_vertex(p + Vector3(0, 0.25, 0))
			var m := st.commit()
			var mat := ShaderMaterial.new()
			mat.shader = load("res://shaders/ward.gdshader")
			mat.render_priority = 1
			m.surface_set_material(0, mat)
			return m
	return ArrayMesh.new()


## The gem shader for a shard (emerald) or the heart (paler, brighter);
## each part that changes its own light gets a copy.
static func gem_material(which: String) -> ShaderMaterial:
	if _mats.has(which):
		return _mats[which]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/gem.gdshader")
	if which == "heart":
		m.set_shader_parameter("body", HEART_BODY)
		m.set_shader_parameter("deep", HEART_DEEP)
		m.set_shader_parameter("light", 1.3)
	else:
		m.set_shader_parameter("body", EMERALD)
		m.set_shader_parameter("deep", EMERALD_D)
	m.set_shader_parameter("fire", FIRE)
	_mats[which] = m
	return m


## Wedge k (centred on the direction k * 45 degrees from +x, toward +z)
## of an octagonal brilliant: the table, four crown facets (a star point
## raised in the middle), three pavilion facets and its two cut faces.
## Every face is flat with its own normal; `off` is taken off every vertex.
static func _wedge(st: SurfaceTool, k: int, r: float, table: float, ty: float, gy: float, cy: float, off: Vector3) -> void:
	var th := TAU * k / 8.0
	var h := TAU / 16.0
	var dir := func(a: float, rad: float, y: float) -> Vector3: return Vector3(cos(a) * rad, y, sin(a) * rad)
	var a: Vector3 = Vector3(0, ty, 0)
	var b: Vector3 = Vector3(0, cy, 0)
	var t0: Vector3 = dir.call(th - h, table, ty)
	var t1: Vector3 = dir.call(th + h, table, ty)
	var g0: Vector3 = dir.call(th - h, r, gy)
	var g1: Vector3 = dir.call(th + h, r, gy)
	var m: Vector3 = dir.call(th, (table + r) * 0.5, (ty + gy) * 0.5 + 0.1)
	var p: Vector3 = dir.call(th, r * 0.52, (gy + cy) * 0.5 - 0.05)
	var mid: Vector3 = dir.call(th, r * 0.5, (ty + cy) * 0.5)
	for f: Array in [[a, t0, t1], [t0, g0, m], [g0, g1, m], [g1, t1, m], [t1, t0, m],
			[g0, g1, p], [g0, p, b], [p, g1, b], [a, t0, g0], [a, g0, b], [a, g1, t1], [a, b, g1]]:
		_tri(st, f[0], f[1], f[2], mid, off)


## One flat triangle, wound so its front faces away from `inside`.
static func _tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, inside: Vector3, off: Vector3) -> void:
	var n := (p1 - p0).cross(p2 - p0)
	var c := (p0 + p1 + p2) / 3.0
	var out := n.dot(c - inside) > 0.0
	n = n.normalized() * (1.0 if out else -1.0)
	# Godot's front faces wind clockwise seen from outside
	var order := [p0, p2, p1] if out else [p0, p1, p2]
	for q: Vector3 in order:
		st.set_normal(n)
		st.add_vertex(q - off)
