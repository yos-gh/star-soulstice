extends RefCounted
## The Cortex eye's gaze strike (STAR CORTEX, OMEGA CORTEX), in place of the
## old weaving iron balls (they took big dodges and swallowed your shots): a
## sight drops onto the ship and follows it, a little slower than it flies,
## so a ship on the move leaves it trailing; then it holds still, and the
## spot under it bursts. The sight (a lock-on reticle with its fuse) and a
## ring round the spot are the warning; a short step out of the ring is
## enough, and nothing is left on the field to block shots. A burst may also
## throw out a few slow shells (OMEGA).
## Each sight hangs on an anchor part with no hit zone, which carries the
## warning (the autopilot keeps out of the ring).
## Not a global class: the bosses preload it, so a fresh copy of the project
## runs without re-importing the class list.

const TRACK := 0.9  # following the ship ...
const LOCK := 0.45  # ... then held still; then the burst
const SPEED := 9.0  # how fast a sight follows (the ship flies 17)
const R := 1.9  # the burst's reach
const SHELL_SPEED := 3.4
const COL := Color(0.55, 0.92, 1.0)

var game: Game
var boss: BossBase
## {a: anchor, t, shells, off: aim offset from the ship}
var sights: Array[Dictionary] = []


func _init(g: Game, b: BossBase) -> void:
	game = g
	boss = b


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
	game.warn(a, TRACK + LOCK, Game.Warn.MOVE, 1.2, {"r": R}, sound)


func tick(dt: float) -> void:
	for s: Dictionary in sights.duplicate():
		var a: Enemy = s["a"]
		s["t"] = float(s["t"]) + dt
		if float(s["t"]) < TRACK:
			a.position = a.position.move_toward(_spot(s["off"]), SPEED * dt)
		elif float(s["t"]) >= TRACK + LOCK:
			_burst(a.position, int(s["shells"]))
			_drop_anchor(a)
			sights.erase(s)


## All sights off (the boss is beaten).
func clear() -> void:
	for s: Dictionary in sights:
		_drop_anchor(s["a"])
	sights.clear()


func _spot(off: Vector3) -> Vector3:
	var p := game.player.position + off
	var z := clampf(p.z, game.field_top + 2.0, game.field_bottom - 0.5)
	var w := game.half_width_at(z) - 0.5
	return Vector3(clampf(p.x, -w, w), 0, z)


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


func _drop_anchor(a: Enemy) -> void:
	game.remove_enemy(a)
	a.queue_free()
