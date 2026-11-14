extends RefCounted
## Marked strikes: a boss marks a spot on the field, then sends something
## there for all to see, and it bursts where it lands (deadly inside the
## marked ring for a moment; a few slow shells may fly out of it). Shown
## as cause and effect, so it reads at a glance; a short step out of the
## ring dodges it, and nothing is left on the field to block shots. They
## replace the old weaving iron balls (big dodges, shots swallowed).
## Two styles:
##   LANCE  the eye of STAR CORTEX / OMEGA CORTEX, the tips of STAR SOUL:
##          a sight drops onto the ship and follows it a little slower than
##          it flies (a ship on the move leaves it trailing), a dotted line
##          of sight running to it from where the shot will come from
##          (dashes marching toward the ship); then the sight holds still,
##          the dashes stop and brighten; then a homing lance leaps out,
##          swings wide to one side and curls down onto the spot (drawn like
##          the ship's homing lasers, but thicker, slower and in the boss's
##          own colour)
##   LOB    the crucible of VULCAN PRESS, the core of TITAN DREDGE: the spot
##          is marked where it falls and stays put; then a glob of molten
##          metal (or a lump of ore: `mesh`) is lobbed high over the field
##          and drops onto it
## Each spot hangs on an anchor part with no hit zone, which carries the
## warning (reticle, fuse, the ring; the autopilot keeps out of the ring).
## Not a global class: the bosses preload it, so a fresh copy of the project
## runs without re-importing the class list.

enum { LANCE, LOB }

const SPEED := 9.0  # how fast a LANCE sight follows (the ship flies 17)
const SHELL_SPEED := 3.4
const TRAIL := 12  # trail points of a lance
const LANCE_W := 0.42  # (the ship's homing lasers: 0.24)

static var _mat: ShaderMaterial

var game: Game
var boss: BossBase
var style := LANCE
var col := Color(1.0, 0.35, 0.75)
var mesh_name := ""  # LOB: a model thrown instead of a glob of light
var track_t := 0.9  # LANCE: following the ship ...
var lock_t := 0.45  # ... then held still (LOB: marked) ...
var fly_t := 0.95  # ... then the shot on its way
var r := 1.9  # the burst's reach
var peak := 6.0  # LOB: how high it arcs
## {a: anchor, t, shells, off: aim offset from the ship, src: Node3D,
## src_off, from (fixed when fired), side, m: thrown model}
var sights: Array[Dictionary] = []
var lines: MeshInstance3D
var line_mesh: ImmediateMesh


func _init(g: Game, b: BossBase, kind: int, colour: Color, model := "") -> void:
	game = g
	boss = b
	style = kind
	col = colour
	mesh_name = model
	if style == LOB:
		track_t = 0.0
		lock_t = 0.5
		fly_t = 1.0
		r = 1.7
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/beam.gdshader")
		_mat.render_priority = 2
	line_mesh = ImmediateMesh.new()
	lines = MeshInstance3D.new()
	lines.mesh = line_mesh
	lines.material_override = _mat
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lines.extra_cull_margin = 16384.0
	b.add_child(lines)


## Marks a spot on the ship (or `off` from it) for a shot from `src` (plus
## `src_off`); a lance swings out to `side` (+1 right, -1 left) first.
func drop(src: Node3D, src_off := Vector3.ZERO, off := Vector3.ZERO, shells := 0, sound := true, side := 1.0) -> void:
	var a := game.spawn_part(boss, "", 0.6)
	a.intangible = true
	a.shootable = false
	a.lock = false
	a.ram = false
	a.position = _spot(off)
	a.hit_pos = a.position
	sights.append({"a": a, "t": 0.0, "shells": shells, "off": off, "src": src, "src_off": src_off, "side": side})
	game.warn(a, track_t + lock_t + fly_t, Game.Warn.MOVE, 1.2, {"r": r}, sound)
	if style == LANCE:
		game.fx.sprite(_source(sights[-1]) + Vector3(0, 0.6, 0), Vector3.ZERO, 2.4, 0.8, 0.25, col, 0.0)


func tick(dt: float) -> void:
	for s: Dictionary in sights.duplicate():
		var a: Enemy = s["a"]
		var was: float = s["t"]
		var t := was + dt
		s["t"] = t
		if t < track_t:
			a.position = a.position.move_toward(_spot(s["off"]), SPEED * dt)
		var go := track_t + lock_t
		if was < go and t >= go:
			_fire(s)
		if t >= go:
			_fly(s, clampf((t - go) / fly_t, 0.0, 1.0))
		if t >= go + fly_t:
			_burst(a.position, int(s["shells"]))
			_drop_anchor(a)
			if s.has("m"):
				(s["m"] as Node3D).queue_free()
			sights.erase(s)
	_draw()


## All spots off (the boss is beaten).
func clear() -> void:
	for s: Dictionary in sights:
		_drop_anchor(s["a"])
		if s.has("m"):
			(s["m"] as Node3D).queue_free()
	sights.clear()
	line_mesh.clear_surfaces()


func _spot(off: Vector3) -> Vector3:
	var p := game.player.position + off
	var z := clampf(p.z, game.field_top + 2.0, game.field_bottom - 0.5)
	var w := game.half_width_at(z) - 0.5
	return Vector3(clampf(p.x, -w, w), 0, z)


func _source(s: Dictionary) -> Vector3:
	var src: Node3D = s["src"]
	var p: Vector3 = (src.position if is_instance_valid(src) else Vector3.ZERO) + (s["src_off"] as Vector3)
	return Vector3(p.x, 0, p.z)


func _fire(s: Dictionary) -> void:
	var from := _source(s)
	s["from"] = from
	game.fx.sprite(from + Vector3(0, 1.0, 0), Vector3.ZERO, 3.0, 0.8, 0.2, col.lerp(Color(1, 1, 1), 0.5), 0.0)
	game.fx.flash(from, 0.4)
	game.sfx.play("exp_s")
	if style == LOB and mesh_name != "":
		var m := MeshInstance3D.new()
		m.mesh = Vox.get_mesh(mesh_name)
		m.scale = Vector3.ONE * 0.5
		game.units.add_child(m)
		m.position = from
		s["m"] = m


## Where the shot is, `f` of the way: a lance on its curve (out to the side,
## then down onto the spot, gathering speed), a lob on its high arc.
func _at(s: Dictionary, f: float) -> Vector3:
	var from: Vector3 = s["from"]
	var to: Vector3 = (s["a"] as Enemy).position
	if style == LOB:
		var p := from.lerp(to, f)
		p.y = 0.6 + (peak if mesh_name == "" else peak * 0.7) * 4.0 * f * (1.0 - f)
		return p
	var side: float = s["side"]
	var u := f * f * 0.45 + f * 0.55
	# a wide arc out to its side and back in: out past the ship's side of the
	# screen, then down and round onto the spot from that side
	var p1 := from + Vector3(side * 15.0, 0, -1.0)
	var p2 := to + Vector3(side * 10.0, 0, -6.0)
	var lim := game.field_hw - 1.0
	p1.x = clampf(p1.x, -lim, lim)
	p2.x = clampf(p2.x, -lim, lim)
	var v := 1.0 - u
	var p := from * v * v * v + p1 * 3.0 * v * v * u + p2 * 3.0 * v * u * u + to * u * u * u
	p.y = 0.6
	return p


func _fly(s: Dictionary, f: float) -> void:
	var p := _at(s, f)
	if style == LOB:
		if s.has("m"):
			var m: MeshInstance3D = s["m"]
			m.position = p
			m.rotation = Vector3(f * 7.0, f * 4.0, 0)
			if randf() < 0.5:
				game.fx.sprite(p, Vector3.ZERO, 0.9, 0.3, 0.25, Color(0.6, 0.55, 0.5), 0.0)
		else:
			game.fx.sprite(p, Vector3.ZERO, 1.6, 0.5, 0.18, col, 0.0)
			game.fx.sprite(p, Vector3.ZERO, 0.8, 0.3, 0.1, Color(1, 0.95, 0.8), 0.0)


func _burst(p: Vector3, shells: int) -> void:
	if game.combat_on():
		var d := game.player.position - p
		if Vector2(d.x, d.z).length() < r + Player.HIT_R:
			game.touch_player("marked strike")
		if shells > 0:
			var a0 := randf() * TAU
			for k in shells:
				game.bullets.fire(p, a0 + TAU * k / shells, SHELL_SPEED, Bullets.SHELL, boss, Bullets.ROUND, 0.0, 0.0, Bullets.SMALL)
	var at := p + Vector3(0, 0.5, 0)
	game.fx.sprite(at, Vector3.ZERO, r * 1.5, r * 0.3, 0.16, Color(1, 1, 1), 0.0)
	game.fx.sprite(at, Vector3.ZERO, 0.8, r * 2.6, 0.3, col, 2.0)
	game.fx.sprite(at, Vector3.ZERO, r * 2.2, 0.4, 0.25, col, 0.0)
	game.fx.spark(at, col, 6, 0.5)
	if style == LOB and mesh_name != "":
		game.fx.explode(at, 0.9, Vector3.ZERO, Color(0.45, 0.4, 0.35), col)
	game.fx.flash(p, 0.5)
	game.sfx.play("exp_m")


## The lines of sight (LANCE), dotted so they never read as a beam: dashes
## marching toward the sight while it follows the ship, still and brighter
## once it holds, fading as the lance flies; and the lances themselves, a
## tapering ribbon with a bright diamond head.
func _draw() -> void:
	line_mesh.clear_surfaces()
	if sights.is_empty() or style != LANCE:
		return
	line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var go := track_t + lock_t
	var k := 0
	for s: Dictionary in sights:
		k += 1
		var t: float = s["t"]
		var from := (s["from"] as Vector3) if s.has("from") else _source(s)
		from.y = 0.6
		var to := (s["a"] as Enemy).position + Vector3(0, 0.36, 0)
		if t < track_t:
			_dashes(from, to, 0.06, 0.55, fmod(game.time * 6.0 + k * 0.37, 1.0))
		elif t < go:
			_dashes(from, to, 0.1, 1.0, 0.0)
		else:
			var f := clampf((t - go) / fly_t, 0.0, 1.0)
			_dashes(from, to, 0.06, 0.5 * (1.0 - f), 0.0)
			_lance(s, f)
	line_mesh.surface_end()


func _lance(s: Dictionary, f: float) -> void:
	var pts := PackedVector3Array()
	for j in TRAIL:
		pts.append(_at(s, maxf(f - (TRAIL - 1 - j) * 0.035, 0.0)))
	for j in TRAIL - 1:
		var a := pts[j]
		var b := pts[j + 1]
		var d := b - a
		if d.length_squared() < 0.000001:
			continue
		var side := Vector3(-d.z, 0, d.x).normalized()
		var ta := float(j) / (TRAIL - 1)
		var tb := float(j + 1) / (TRAIL - 1)
		var ca := Color(col.r, col.g, col.b, ta)
		var cb := Color(col.r, col.g, col.b, tb)
		_v(ca, Vector2(ta, 0), a - side * LANCE_W * ta)
		_v(ca, Vector2(ta, 1), a + side * LANCE_W * ta)
		_v(cb, Vector2(tb, 0), b - side * LANCE_W * tb)
		_v(ca, Vector2(ta, 1), a + side * LANCE_W * ta)
		_v(cb, Vector2(tb, 1), b + side * LANCE_W * tb)
		_v(cb, Vector2(tb, 0), b - side * LANCE_W * tb)
	# the head: a diamond pointing along the flight
	var hp := pts[TRAIL - 1]
	var dir := (hp - pts[TRAIL - 2])
	dir = dir.normalized() if dir.length_squared() > 0.000001 else Vector3(0, 0, 1)
	var sd := Vector3(-dir.z, 0, dir.x) * 0.32
	var c := col.lerp(Color(1, 1, 1), 0.6)
	var tip := hp + dir * 1.2
	var tail := hp - dir * 0.7
	_v(c, Vector2(1, 0.5), tip)
	_v(c, Vector2(0.5, 0), hp - sd)
	_v(c, Vector2(0.5, 1), hp + sd)
	_v(c, Vector2(0, 0.5), tail)
	_v(c, Vector2(0.5, 1), hp + sd)
	_v(c, Vector2(0.5, 0), hp - sd)


## Dashes 0.5 long, 0.6 apart, from p0 to p1, shifted `phase` of a step on.
func _dashes(p0: Vector3, p1: Vector3, w: float, alpha: float, phase: float) -> void:
	var len := p0.distance_to(p1)
	var d := (p1 - p0) / maxf(len, 0.01)
	var k := (phase - 1.0) * 1.1
	var c := Color(col.r, col.g, col.b, clampf(alpha, 0.0, 1.0))
	while k < len:
		var a := maxf(k, 0.0)
		var b := minf(k + 0.5, len)
		if b > a:
			var q0 := p0 + d * a
			var q1 := p0 + d * b
			var s := Vector3(-d.z, 0, d.x).normalized() * w
			_v(c, Vector2(0, 0), q0 - s)
			_v(c, Vector2(0, 1), q0 + s)
			_v(c, Vector2(0, 1), q1 + s)
			_v(c, Vector2(0, 0), q0 - s)
			_v(c, Vector2(0, 1), q1 + s)
			_v(c, Vector2(0, 0), q1 - s)
		k += 1.1


func _v(c: Color, uv: Vector2, p: Vector3) -> void:
	line_mesh.surface_set_color(c)
	line_mesh.surface_set_uv(uv)
	line_mesh.surface_add_vertex(p)


func _drop_anchor(a: Enemy) -> void:
	game.remove_enemy(a)
	a.queue_free()
