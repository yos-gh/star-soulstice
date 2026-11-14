class_name CoreModels
extends Models
## Stage 5's last boss STAR SOUL: the core of every boss so far, grown into
## a crystal. Nothing mechanical and not voxels: an abstract solid of flat
## dark facets, lines of light along its edges (shaders/crystal.gdshader),
## rings of light round it (shaders/halo.gdshader).
##   soul_plate  one of the eight plates the crystal is made of: one face of
##               a long octahedron (tip at +y L, its base along the waist
##               from +x R to +z R) with some thickness inward. The four
##               upper plates are this one turned about y; the lower four
##               the same flipped over. The boss swings, slides and spreads
##               them to change its shape
##   soul_seed   the small bright octahedron inside the eight
##   soul_mote   a little octahedron: six of them circle the crystal's waist
##   soul_spire  a shard that grows out of the field (its foot at the origin,
##               growing along +y)
##   soul_halo   a flat square in the xz plane (2 x 2) for a ring of light
## Dark indigo glass with pale mint light: apart from every bullet colour
## (blue shells, orange energy, violet iron, red heavies), from the ship's
## white and blue, and bright against the violet and rose of warp space; in
## its rage the light heats toward a warm white.

const NAMES := ["soul_plate", "soul_seed", "soul_mote", "soul_spire", "soul_halo"]
## the crystal: half its length (centre to tip) and its waist (centre to a
## corner of the square round its middle)
const L := 5.0
const R := 2.5
## a plate's inner face: this share of the way out from the centre
const SHELL := 0.72
## the seed, a mote: waist, half length
const SEED := [1.0, 2.1]
const MOTE := [0.4, 0.8]
## a spire: waist, the height of its waist, its length
const SPIRE := [0.55, 0.9, 3.6]
const GLASS := Color(0.12, 0.14, 0.32)
const GLASS_D := Color(0.012, 0.014, 0.04)
const LIGHT := Color(0.62, 1.0, 0.84)
const FIRE := Color(1.0, 0.86, 0.62)

static var _mats := {}


static func make(name: String) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match name:
		"soul_plate":
			var t := Vector3(0, L, 0)
			var a := Vector3(R, 0, 0)
			var b := Vector3(0, 0, R)
			var t2 := t * SHELL
			var a2 := a * SHELL
			var b2 := b * SHELL
			var mid := (t + a + b + t2 + a2 + b2) / 6.0
			_tri(st, t, a, b, mid)
			_tri(st, t2, b2, a2, mid)
			_quad(st, t, a, a2, t2, mid)
			_quad(st, a, b, b2, a2, mid)
			_quad(st, b, t, t2, b2, mid)
			return _done(st, "plate")
		"soul_seed":
			_bipyramid(st, SEED[0], SEED[1], -SEED[1])
			return _done(st, "seed")
		"soul_mote":
			_bipyramid(st, MOTE[0], MOTE[1], -MOTE[1])
			return _done(st, "mote")
		"soul_spire":
			_bipyramid(st, SPIRE[0], SPIRE[2] - SPIRE[1], -SPIRE[1], Vector3(0, SPIRE[1], 0))
			return _done(st, "spire")
		"soul_halo":
			for q: Array in [[-1, -1], [1, -1], [1, 1], [-1, -1], [1, 1], [-1, 1]]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(q[0] * 0.5 + 0.5, q[1] * 0.5 + 0.5))
				st.add_vertex(Vector3(q[0], 0, q[1]))
			var m := st.commit()
			m.surface_set_material(0, halo_material())
			return m
	return ArrayMesh.new()


static func _done(st: SurfaceTool, which: String) -> ArrayMesh:
	var m := st.commit()
	m.surface_set_material(0, crystal_material(which))
	return m


## The crystal shader for a part ("plate", "seed", "mote", "spire"); a boss
## that changes a part's light takes a copy.
static func crystal_material(which: String) -> ShaderMaterial:
	if _mats.has(which):
		return _mats[which]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/crystal.gdshader")
	m.set_shader_parameter("GLASS", GLASS)
	m.set_shader_parameter("GLASS_D", GLASS_D)
	m.set_shader_parameter("edge", LIGHT)
	m.set_shader_parameter("fire", FIRE)
	match which:
		"plate":
			m.set_shader_parameter("grad", 0.9)
			m.set_shader_parameter("span", L)
		"seed":
			m.set_shader_parameter("core", 1.0)
			m.set_shader_parameter("edge_w", 0.06)
			m.set_shader_parameter("span", SEED[1])
		"mote":
			m.set_shader_parameter("core", 0.55)
			m.set_shader_parameter("edge_w", 0.09)
			m.set_shader_parameter("span", MOTE[1])
		"spire":
			m.set_shader_parameter("core", 0.25)
			m.set_shader_parameter("edge_w", 0.07)
			m.set_shader_parameter("grad", 1.2)
			m.set_shader_parameter("span", SPIRE[2])
	_mats[which] = m
	return m


static func halo_material() -> ShaderMaterial:
	if _mats.has("halo"):
		return _mats["halo"]
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/halo.gdshader")
	m.render_priority = 1
	m.set_shader_parameter("col", LIGHT)
	m.set_shader_parameter("fire", FIRE)
	_mats["halo"] = m
	return m


## A four-sided bipyramid about the y axis (plus `off`): its waist `r` out
## at y = 0, tips at y = `up` and y = `down`.
static func _bipyramid(st: SurfaceTool, r: float, up: float, down: float, off := Vector3.ZERO) -> void:
	var t := Vector3(0, up, 0) + off
	var b := Vector3(0, down, 0) + off
	for k in 4:
		var a0 := TAU * k / 4.0
		var a1 := TAU * (k + 1) / 4.0
		var e0 := Vector3(cos(a0) * r, 0, sin(a0) * r) + off
		var e1 := Vector3(cos(a1) * r, 0, sin(a1) * r) + off
		_tri(st, t, e0, e1, off)
		_tri(st, b, e1, e0, off)


## A flat quad a-b-c-d as two triangles, its diagonal a-c not drawn as an
## edge.
static func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3) -> void:
	_tri(st, a, b, c, inside, 1)
	_tri(st, a, c, d, inside, 2)


## One flat triangle, wound so its front faces away from `inside`, each
## corner carrying its barycentric coordinate in the vertex colour (the
## crystal shader draws the edges from it). `hide` >= 0: the edge across
## from that corner is not drawn (its channel stays at 1).
static func _tri(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, inside: Vector3, hide := -1) -> void:
	var n := (p1 - p0).cross(p2 - p0)
	var c := (p0 + p1 + p2) / 3.0
	var out := n.dot(c - inside) > 0.0
	n = n.normalized() * (1.0 if out else -1.0)
	var pts := [p0, p1, p2]
	# Godot's front faces wind clockwise seen from outside
	for i: int in ([0, 2, 1] if out else [0, 1, 2]):
		var col := Color(1.0 if i == 0 or hide == 0 else 0.0, 1.0 if i == 1 or hide == 1 else 0.0, 1.0 if i == 2 or hide == 2 else 0.0)
		st.set_normal(n)
		st.set_color(col)
		st.add_vertex(pts[i])
