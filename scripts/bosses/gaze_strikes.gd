extends RefCounted
## The Cortex eye's gaze strike (STAR CORTEX, OMEGA CORTEX), in place of the
## old weaving iron balls (they took big dodges and swallowed your shots).
## Shown as cause and effect, so it reads at a glance:
##   - the eye looks at the ship: a sight drops onto it and a dotted line
##     of sight runs from the eye to it (dashes marching toward the ship); the sight follows the ship a
##     little slower than it flies, so a ship on the move leaves it trailing
##   - the eye takes aim: the sight holds still, the dashes stop and brighten
##   - the eye fires: a ball of light leaps from the eye, arcs high over the
##     field and drops onto the sight (harmless in flight)
##   - it lands: the spot bursts (deadly inside the marked ring for a moment);
##     OMEGA's bursts also throw out a few slow shells
## A short step out of the ring is enough, and nothing is left on the field
## to block shots. Each sight hangs on an anchor part with no hit zone, which
## carries the warning (the autopilot keeps out of the ring).
## Not a global class: the bosses preload it, so a fresh copy of the project
## runs without re-importing the class list.

const TRACK := 0.9  # following the ship ...
const LOCK := 0.45  # ... then held still ...
const FLY := 0.4  # ... then the ball of light on its way
const SPEED := 9.0  # how fast a sight follows (the ship flies 17)
const PEAK := 3.2  # how high the ball arcs over the field
const R := 1.9  # the burst's reach
const SHELL_SPEED := 3.4
const COL := Color(0.55, 0.92, 1.0)

static var _mat: ShaderMaterial

var game: Game
var boss: BossBase
var eye: Node3D
## {a: anchor, t, shells, off: aim offset from the ship}
var sights: Array[Dictionary] = []
var lines: MeshInstance3D
var line_mesh: ImmediateMesh


func _init(g: Game, b: BossBase, from: Node3D) -> void:
	game = g
	boss = b
	eye = from
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://shaders/lightning.gdshader")
		_mat.render_priority = 2
	line_mesh = ImmediateMesh.new()
	lines = MeshInstance3D.new()
	lines.mesh = line_mesh
	lines.material_override = _mat
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	lines.extra_cull_margin = 16384.0
	b.add_child(lines)


## A sight on the ship (or `off` from it: ahead of where it is heading).
func drop(shells := 0, off := Vector3.ZERO, sound := true) -> void:
	var a := game.spawn_part(boss, "", 0.6)
	a.intangible = true
	a.shootable = false
	a.lock = false
	a.ram = false
	a.position = _spot(off)
	a.hit_pos = a.position
	sights.append({"a": a, "t": 0.0, "shells": shells, "off": off})
	game.warn(a, TRACK + LOCK + FLY, Game.Warn.MOVE, 1.2, {"r": R}, sound)
	game.fx.sprite(eye.position + Vector3(0, 1.0, 0), Vector3.ZERO, 2.6, 1.0, 0.25, COL, 0.0)


func tick(dt: float) -> void:
	for s: Dictionary in sights.duplicate():
		var a: Enemy = s["a"]
		var was: float = s["t"]
		var t := was + dt
		s["t"] = t
		if t < TRACK:
			a.position = a.position.move_toward(_spot(s["off"]), SPEED * dt)
		if was < TRACK + LOCK and t >= TRACK + LOCK:
			# fired: a flash in the eye
			game.fx.sprite(eye.position + Vector3(0, 1.2, 0), Vector3.ZERO, 3.2, 0.8, 0.2, Color(1, 1, 1), 0.0)
			game.fx.flash(eye.position, 0.4)
			game.sfx.play("exp_s")
		if t >= TRACK + LOCK:
			# the ball of light in flight, a short trail behind it
			var f := clampf((t - TRACK - LOCK) / FLY, 0.0, 1.0)
			var p := _ball(a.position, f)
			game.fx.sprite(p, Vector3.ZERO, 1.5, 0.4, 0.14, COL, 0.0)
			game.fx.sprite(p, Vector3.ZERO, 0.7, 0.2, 0.08, Color(1, 1, 1), 0.0)
		if t >= TRACK + LOCK + FLY:
			_burst(a.position, int(s["shells"]))
			_drop_anchor(a)
			sights.erase(s)
	_draw()


## All sights off (the boss is beaten).
func clear() -> void:
	for s: Dictionary in sights:
		_drop_anchor(s["a"])
	sights.clear()
	line_mesh.clear_surfaces()


func _spot(off: Vector3) -> Vector3:
	var p := game.player.position + off
	var z := clampf(p.z, game.field_top + 2.0, game.field_bottom - 0.5)
	var w := game.half_width_at(z) - 0.5
	return Vector3(clampf(p.x, -w, w), 0, z)


## The ball's place `f` of the way from the eye to the spot, arcing high.
func _ball(to: Vector3, f: float) -> Vector3:
	var p := (eye.position + Vector3(0, 1.0, 0)).lerp(to + Vector3(0, 0.5, 0), f)
	p.y += PEAK * 4.0 * f * (1.0 - f)
	return p


func _burst(p: Vector3, shells: int) -> void:
	if game.combat_on():
		var d := game.player.position - p
		if Vector2(d.x, d.z).length() < R + Player.HIT_R:
			game.touch_player("cortex gaze")
		if shells > 0:
			var a0 := randf() * TAU
			for k in shells:
				game.bullets.fire(p, a0 + TAU * k / shells, SHELL_SPEED, Bullets.SHELL, boss, Bullets.ROUND, 0.0, 0.0, Bullets.SMALL)
	var at := p + Vector3(0, 0.5, 0)
	game.fx.sprite(at, Vector3.ZERO, R * 1.5, R * 0.3, 0.16, Color(1, 1, 1), 0.0)
	game.fx.sprite(at, Vector3.ZERO, 0.8, R * 2.6, 0.3, COL, 2.0)
	game.fx.sprite(at, Vector3.ZERO, R * 2.2, 0.4, 0.25, COL, 0.0)
	game.fx.spark(at, COL, 6, 0.5)
	game.fx.flash(p, 0.5)
	game.sfx.play("exp_m")


## The eye's lines of sight, dotted so they never read as a beam: dashes
## marching toward the sight while it follows the ship, still and brighter
## once it holds, fading as the ball flies.
func _draw() -> void:
	line_mesh.clear_surfaces()
	if sights.is_empty():
		return
	line_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var from := eye.position + Vector3(0, 1.0, 0)
	var k := 0
	for s: Dictionary in sights:
		k += 1
		var t: float = s["t"]
		var to := (s["a"] as Enemy).position + Vector3(0, 0.36, 0)
		if t < TRACK:
			_dashes(from, to, 0.06, 0.55, fmod(game.time * 6.0 + k * 0.37, 1.0))
		elif t < TRACK + LOCK:
			_dashes(from, to, 0.1, 1.0, 0.0)
		else:
			_dashes(from, to, 0.06, 0.6 * (1.0 - (t - TRACK - LOCK) / FLY), 0.0)
	line_mesh.surface_end()


## Dashes 0.5 long, 0.6 apart, from p0 to p1, shifted `phase` of a step on.
func _dashes(p0: Vector3, p1: Vector3, w: float, alpha: float, phase: float) -> void:
	var len := p0.distance_to(p1)
	var d := (p1 - p0) / maxf(len, 0.01)
	var k := (phase - 1.0) * 1.1
	while k < len:
		var a := maxf(k, 0.0)
		var b := minf(k + 0.5, len)
		if b > a:
			_seg(p0 + d * a, p0 + d * b, w, alpha)
		k += 1.1


func _seg(p0: Vector3, p1: Vector3, w: float, alpha: float) -> void:
	var col := Color(COL.r, COL.g, COL.b, clampf(alpha, 0.0, 1.0))
	var d := p1 - p0
	var s := Vector3(-d.z, 0, d.x).normalized() * w
	for q: Array in [[p0 - s, 0.0], [p0 + s, 1.0], [p1 + s, 1.0], [p0 - s, 0.0], [p1 + s, 1.0], [p1 - s, 0.0]]:
		line_mesh.surface_set_color(col)
		line_mesh.surface_set_uv(Vector2(0, q[1]))
		line_mesh.surface_add_vertex(q[0])


func _drop_anchor(a: Enemy) -> void:
	game.remove_enemy(a)
	a.queue_free()
